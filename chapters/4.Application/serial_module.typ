=== 从协议契约到驱动模块

前一章讨论了怎样把识别、跟踪、弹道和规划结果组织成云台指令。根据上下位机的职责划分，线上消息可以是规划好的 yaw／pitch 位置、速度、加速度与开火标志，也可以是交给下位机继续处理的整车状态。接下来要把这些数据从视觉进程可靠地送到电控，并把电控返回的姿态和控制状态交给视觉系统。本章讨论这段双向链路的软件实现。

「实战技术篇」的通信协议设定一章已经定义了帧头、CRC、字段布局、语义和量纲；基础篇「计算机系统基础」与「C++ 语言基础」则介绍了 Linux 字符设备、termios raw 模式和逐字节解析状态机。本章沿用这些定义，不再重复协议和 CRC 推导。

实现层还要回答协议之外的问题：同步读取会占用执行线程；USB 断开或电控重启后需要重新打开设备；多个同类设备的 `ttyUSB0`、`ttyUSB1` 编号可能变化；收到的姿态、敌方颜色和复位请求还要接入 TF、参数与服务。本章以一个 ROS 2 驱动为主线，再与另一套把主要模块组织在同一 C++ 进程内的实现对照，说明这些选择及其尚未处理好的边界。

本章重点是接收线程与发送回调、ROS 2 接口、断线恢复、稳定设备路径和验证方法。文中的参考实现固定为 `rm_serial_driver` 提交 `794f4ec`。该快照的顶层 LICENSE 与源码头标注 Apache-2.0，`package.xml` 却标注 MIT，许可证元数据并不一致；本章无法据此判定哪一项适用于复用或分发，实际使用前应检查上游历史并向维护者确认适用条款。

=== 收发骨架：接收线程与发送回调

参考实现把串口封装为 ROS 2 节点。接收方向使用一条专用线程；发送方向由 `/tracker/target` 订阅回调触发，运行在哪个 executor 线程取决于启动和执行器配置，并不是另一条固定的“发送线程”。节点还发布调试信息并调用参数与服务，因此下图只画出与主控制链直接相关的接口。

#figure(
  image("images/app-serial-node-dataflow.png", width: 100%),
  caption: [串口节点的执行路径与数据流（脚本 `app_serial_node_dataflow.py`）。接收线程同步寻找帧头 `0x5A`，读取剩余字节并校验 CRC，再更新姿态 TF、识别颜色和跟踪器复位；发送回调由目标话题触发，将跟踪结果写入 `0xA5` 数据包。接收线程和 executor 回调都可能在异常时直接调用 `reopenPort()`；当前实现没有用互斥保护该操作，两次重连调用可能重叠，后文会说明其并发与退出边界。],
)

==== 独立接收线程：为什么不能在回调里读串口

同步 `read` 在没有数据时会等待，是持续等待还是超时返回，取决于 termios 的 `VMIN`/`VTIME` 和驱动配置。若把长期等待直接放入 ROS 定时器或订阅回调，它会占住一个 executor 工作线程；在单线程执行器中，同一节点的其他回调也无法继续。常见处理方式有两种：使用专用接收线程，或使用异步 I/O 并让完成事件回到执行器。参考实现选择前者：

```cpp
// 构造函数里：打开串口，起一条专职接收线程
serial_driver_->init_port(device_name_, *device_config_);
if (!serial_driver_->port()->is_open()) {
  serial_driver_->port()->open();
  receive_thread_ = std::thread(&RMSerialDriver::receiveData, this);
}
```

接收线程执行“寻找帧头、请求剩余字节、校验 CRC、分发”的循环：

```cpp
void RMSerialDriver::receiveData() {
  std::vector<uint8_t> header(1);
  std::vector<uint8_t> data;
  while (rclcpp::ok()) {
    try {
      serial_driver_->port()->receive(header);   // 阻塞读 1 字节
      if (header[0] != 0x5A) continue;            // 没同步上，丢弃重来

      data.resize(sizeof(ReceivePacket) - 1);
      // Humble serial_driver 的 receive() 调用 read_some，可能短读。
      serial_driver_->port()->receive(data);      // 一次请求剩余字节
      data.insert(data.begin(), header[0]);
      ReceivePacket packet = fromVector(data);

      if (crc16::Verify_CRC16_Check_Sum(              // 验 CRC，机制见基础篇
            reinterpret_cast<const uint8_t *>(&packet), sizeof(packet))) {
        // …… 合法帧：执行三类 ROS 2 操作（下一节）
      } else {
        RCLCPP_ERROR(get_logger(), "CRC error!");   // 坏帧：记录日志后丢弃
      }
    } catch (const std::exception & ex) {
      reopenPort();                                 // I/O 出错：尝试重开端口
    }
  }
}
```

基础篇的状态机逐字节处理输入，可以在任意边界重新寻找帧头。这里利用固定帧长简化为“先读到 `0x5A`，再请求剩余字节”。若流已经错位，而载荷中恰好出现 `0x5A`，该字节可能被误当成帧头；CRC 会过滤绝大多数错误组合，但恢复时间仍取决于后续字节内容。更明确的实现可以维护持久接收缓冲区，逐字节滑动寻找候选帧，并在 CRC 失败后只丢弃必要字节。

这里还有一个可以直接从依赖源码确认的问题。ROS 2 Humble 的 `transport_drivers` 1.2.0 中，`SerialPort::receive()` 返回 `read_some()` 实际读到的字节数；它不保证填满传入的 `vector`。参考实现忽略这个返回值，仍按完整 `ReceivePacket` 解码。发生短读时，缓冲区未覆盖部分可能保留旧数据，CRC 通常会失败，也存在错误组合偶然通过校验的可能。正确做法是循环累计返回长度，直到收满 `sizeof(ReceivePacket)-1`，或改用能保证读取指定长度的组合操作；测试时还应主动把一帧拆成多个写入，不能只发送整帧验证。

发送方向存在对称问题：`SerialPort::send()` 调用 `write_some()` 并返回实际写出长度，`sendData()` 同样忽略了这个返回值。数据包只有 48 B 并不构成“每次一定完整写出”的接口保证；部分写入会让下位机收到截断帧。发送端也应循环推进尚未写出的区间，或使用会持续执行到缓冲区写完（或报错）的 `asio::write`，并在可控制返回长度的模拟 I/O 层主动制造部分写入。

==== 双包序列化：直接传输对象表示的条件

参考实现用两个 `__attribute__((packed))` 结构体描述收发包，并为两个方向设置不同帧头（接收 `0x5A`、发送 `0xA5`）：

```cpp
struct ReceivePacket {            // 电控 -> 视觉；本地所核对 ABI 为 28 B
  uint8_t  header = 0x5A;
  uint8_t  detect_color : 1;      // ……标志位域
  bool     reset_tracker : 1;
  uint8_t  reserved : 6;
  float    roll, pitch, yaw;      // ……姿态与调试瞄准点载荷
  float    aim_x, aim_y, aim_z;
  uint16_t checksum;
} __attribute__((packed));

struct SendPacket {               // 视觉 -> 电控；本地所核对 ABI 为 48 B
  uint8_t  header = 0xA5;
  bool     tracking : 1;          // ……标志位域
  uint8_t  id : 3;
  uint8_t  armors_num : 3;
  uint8_t  reserved : 1;
  float    x, y, z, yaw, vx, vy, vz, v_yaw, r1, r2, dz;   // ……整车状态载荷
  uint16_t checksum;
} __attribute__((packed));
```

字段语义已在通信协议设定一章说明。本章需要补充的是：下面的 `std::copy` 不是与平台无关的序列化，而是直接复制 C++ 对象表示。

```cpp
inline std::vector<uint8_t> toVector(const SendPacket & d) {
  std::vector<uint8_t> v(sizeof(SendPacket));
  std::copy(reinterpret_cast<const uint8_t *>(&d),
            reinterpret_cast<const uint8_t *>(&d) + sizeof(SendPacket), v.begin());
  return v;   // 复制当前编译器给出的对象表示
}
```

`packed` 通常会去掉成员间填充，但不能统一 C++ 位域分配顺序、`bool` 表示、浮点格式和字节序。常见 x86 主机与 STM32 均使用小端并不足以证明两端布局相同，尤其这里混用了 `bool` 与 `uint8_t` 位域。用本机 g++ 编译所核对头文件得到 28 B 和 48 B，只能证明当前 ABI（应用二进制接口）下的布局。部署时应在两端分别使用 `sizeof`/`offsetof` 或等价静态检查，并用一组固定字段生成已知正确的逐字节样例（常称“黄金字节”），让两端互相解码；需要跨编译器和平台稳定时，应逐字段编码，而不是直接复制对象表示。

发送端还把目标类别字符串通过 `std::map::at()` 映射为 `id`。未收录的字符串会抛出 `std::out_of_range`，但外层 `catch` 把所有 `std::exception` 都当成串口发送错误并调用 `reopenPort()`。因此，一个输入校验错误会触发无关的设备重连。更清晰的做法是在写串口前验证类别并单独报告协议数据错误，只让设备 I/O 异常进入重连路径。

=== 把串口接进系统：三类控制输出

在这套参考工程中，串口节点除了收发字节，还把电控数据转换成三类 ROS 2 操作：广播姿态 TF、修改识别颜色、调用跟踪器复位服务。其他系统可能通过 CAN、共享内存或独立 IMU 节点提供同类信息，因此这是项目边界，不是串口节点的固定职责。

==== 姿态 TF：发布 `odom → gimbal_link`

接收线程每收到一帧合法姿态，就把它广播成一条 TF——从惯性系 `odom` 到云台系 `gimbal_link` 的旋转：

```cpp
geometry_msgs::msg::TransformStamped t;
timestamp_offset_ = this->get_parameter("timestamp_offset").as_double();
t.header.stamp = this->now() + rclcpp::Duration::from_seconds(timestamp_offset_);
t.header.frame_id = "odom";
t.child_frame_id  = "gimbal_link";
tf2::Quaternion q;
q.setRPY(packet.roll, packet.pitch, packet.yaw);   // 欧拉角 -> 四元数
t.transform.rotation = tf2::toMsg(q);
tf_broadcaster_->sendTransform(t);
```

参考工程的 IMU 姿态随接收包进入，因此由串口节点广播 `odom → gimbal_link`。代码只赋值旋转，平移保持默认零值；这条 `odom` 表达的是姿态参考，并不包含底盘在场地中的平移。跟踪节点将识别器发布的相机系观测转换到该参考系时依赖这条动态 TF，缺失、坐标约定错误或时间不匹配都会使后续变换不可用或产生偏差。

该数据包没有 IMU 的源采样时间戳。代码只能用包通过校验并被处理时的 `now()`，再加上 `timestamp_offset` 生成 TF 时间戳。这个时间不是原始采样时刻，常数偏移只能近似补偿稳定的相对偏差，无法描述 USB 排队、线程调度抖动、设备时钟漂移或逐包变化的延迟。

本章核对的 `rm_vision` bringup 快照（提交 `2ead8d0`）将 `timestamp_offset` 配置为 `+0.006 s`，而驱动源码的参数默认值是 `0`。这个符号和数值不能由“相机通常更慢”推出：它还取决于相机时间戳写在曝光、驱动还是回调阶段，以及 TF 查询希望对齐的事件。若链路确为 115200 bit/s、8N1 UART，28 B 在线路上的名义传输时间约为 2.43 ms；USB CDC 则不一定按这个波特率限制物理传输。应使用共同事件或可控运动标定相对偏移，并记录延迟分布；更完整的方案是在电控包中携带源时间戳并完成时钟映射，详见「时间戳对齐」一章。

==== 回写识别器、复位跟踪器

另外两类输出把接收包中的状态转换为识别器参数和跟踪器服务。`detect_color` 可以让电控把裁判系统或操作端选定的敌方颜色转交给识别器；驱动本身只负责转交该字段，不判断颜色来源。它通过异步参数客户端写给识别器，代码在首次成功设置前持续尝试，之后只在接收值变化时请求更新：

```cpp
if (!initial_set_param_ || packet.detect_color != previous_receive_color_) {
  setParam(rclcpp::Parameter("detect_color", packet.detect_color));
  previous_receive_color_ = packet.detect_color;
}
if (packet.reset_tracker) resetTracker();          // 位为 1 的每一帧都会请求复位
```

这段代码还有三个边界。第一，`setParam()` 可能因参数服务未就绪而返回，因旧请求仍在进行而跳过新请求，异步请求也可能稍后失败；调用者却会立即更新 `previous_receive_color_`。只要首次设置曾经成功，一次未真正应用的颜色变化就可能被当成“已经处理”，下一帧不再重试。应分别维护期望值与已确认值，只在成功响应后推进已确认值。第二，`initial_set_param_` 是普通 `bool`：接收线程读取它，异步参数响应回调写它。当响应由 executor 与接收线程并发处理时，源码没有使用原子变量或互斥，便会产生 C++ 数据竞争；可以用原子变量或互斥保护，也可以把状态判断和响应更新放到同一个执行上下文。第三，`reset_tracker` 是电平触发，不是边沿触发：只要该位连续为 1，每个合法接收包都会尝试调用 `/tracker/reset`；服务暂时不可用时则直接跳过。协议双方应明确该位是单帧脉冲还是保持状态，并对重复调用和失败重试作出约定。

=== 断线恢复及其边界

接插件松动、电控重启、供电波动或 USB 重新枚举都可能中断链路。参考实现让收发路径在捕获异常后调用 `reopenPort()`：先关闭并重新打开端口，失败后等待一秒再试。

```cpp
void RMSerialDriver::reopenPort() {
  RCLCPP_WARN(get_logger(), "Attempting to reopen port");
  try {
    if (serial_driver_->port()->is_open()) serial_driver_->port()->close();
    serial_driver_->port()->open();
    RCLCPP_INFO(get_logger(), "Successfully reopened port");
  } catch (const std::exception & ex) {
    if (rclcpp::ok()) {
      rclcpp::sleep_for(std::chrono::seconds(1));
      reopenPort();                                 // 当前实现递归重试
    }
  }
}
```

这段代码表达了基本恢复意图，但不能直接当作完整的重连模板。首先，递归调用没有总次数上限；设备长期不在位时，调用栈会持续增长。其次，接收线程与发送回调都可能进入 `reopenPort()`，代码没有互斥或单一所有者来防止两条路径同时关闭、打开同一端口。最后，析构函数先 `join()` 接收线程、之后才关闭端口；若同步读取没有因 ROS 关闭而返回，退出过程可能一直等待。上述风险需要通过长期断开、并发收发和退出测试确认，不能由一次拔插成功排除。

更稳妥的实现可以把端口状态交给单一 I/O 线程，用迭代状态机执行有限或可取消的重试，并在连续失败时逐步延长等待间隔；其他线程只提交发送队列和“请求重连”事件。停止时先设置退出标志并取消或关闭阻塞 I/O，再等待线程结束。还要在下位机设置接收超时或指令序号：上位机断线时，下位机应进入事先定义的安全状态，而不是无限保持最后一条目标指令。

作为对照，本章核对的 `sp_vision_25` 快照（提交 `58c6278`，MIT）中，普通兵种程序使用的 `Gimbal` 串口路径不依赖 ROS，也使用专用读取线程。仓库另有按 ROS 2 环境可选编译的导航接口，哨兵程序会使用该接口；因此下述比较只针对 `Gimbal` 路径，不代表整个仓库没有 ROS 代码。该路径累计“没有一次读满请求字节”的次数，超过 5000 次后进入重连函数；每轮最多尝试打开 10 次，成功后清空姿态队列，未成功则回到读取循环，之后可能再次触发一轮。固定快照没有为 `Gimbal` 显式设置读取超时，内嵌 serial 库的默认超时为 `0`，即非阻塞模式；读取循环也没有显式等待。因此“5000 次”是循环次数，不是固定时长，实际恢复时机还受线程调度和数据到达方式影响。其发送包不包含整车状态，而是 yaw/pitch 的位置、速度和加速度：

```cpp
struct __attribute__((packed)) VisionToGimbal {   // Gimbal 路径的发送包（MIT）
  uint8_t  head[2] = {'S', 'P'};                   // 两字节帧头，另一种同步策略
  uint8_t  mode;                                   // 0 不控；1 控云台，不开火
                                                  // 2 控云台，并开火
  float    yaw, yaw_vel, yaw_acc;                  // 前馈三元组
  float    pitch, pitch_vel, pitch_acc;
  uint16_t crc16;
};
static_assert(sizeof(VisionToGimbal) <= 64);       // 只限制本地 ABI 下的大小上限
```

两种接口对应不同职责划分：在本章核对的 `rm_serial_driver` 固定提交中，发送包把目标整车状态交给下位机；同时核对的 `rm_vision` bringup 快照（提交 `2ead8d0`）只编排相机、识别、跟踪和串口等节点，没有呈现弹道、选板与开火模块。这只能说明所查公开快照的接口边界，不能推断其他版本或完整整车系统的职责。`sp_vision` 固定提交则在上位机生成云台轨迹与开火模式。前一种工程把识别、跟踪和串口组织成 ROS 2 节点，通过话题、TF、参数与服务连接；后一种的普通兵种程序把相机、视觉与 I/O 组织在同一 C++ 进程内，以类、线程和队列连接。选择哪一种取决于控制器能力、反馈信息、时间同步和团队维护边界。

两字节帧头可以降低随机载荷恰好匹配完整帧头的概率，但固定 `Gimbal` 解析器每次读取两个帧头字节，匹配失败后整块丢弃，并不会逐字节滑动。若字节流插入或丢失一个字节，某个真正的 `SP` 可能恰好跨在相邻两次读取之间而被漏掉，恢复时机取决于后续帧长和读取边界；更稳妥的做法是维护持久缓冲区，匹配失败后只滑动一个字节，并测试分片与错位输入。其发送函数也忽略 `serial_.write()` 的返回长度；在默认写超时为 `0` 时，内嵌 serial 库可能在首次底层写入后返回部分长度，因此这条路径同样需要处理部分写入。`static_assert(sizeof(...) <= 64)` 只限制当前编译器下的上限，也不能替代两端黄金字节测试。

=== 用稳定设备路径避免枚举编号变化

基础篇和通信协议设定章都提到过：多个 USB 串口的枚举顺序变化后，配置中的 `/dev/ttyUSB0` 可能指向另一台设备。Linux 通常已经在 `/dev/serial/by-id/` 和 `/dev/serial/by-path/` 提供按设备身份或物理路径生成的链接，应先检查这些链接是否存在并满足部署需求；需要自定义名称、权限或更精确的匹配条件时，再编写 udev 规则。

#figure(
  image("images/app-serial-udev-chain.png", width: 100%),
  caption: [udev 匹配链与符号链接生成过程（脚本 `app_serial_udev_chain.py`）。`ttyUSB0` 是 `SUBSYSTEM=="tty"` 的叶子设备，而 `idVendor`、`idProduct` 通常位于 USB 祖先设备；本节示例因此使用 `ATTRS{}` 沿父链匹配。内核发出设备事件后，`systemd-udevd` 按规则创建 `/dev/rm_serial`。若同一条规则同时匹配多个设备，别名仍可能冲突，需要加入可区分个体或物理位置的条件，例如序列号或物理端口。],
)

==== 名字为什么会跳

USB 转串口设备接入后，`usb-serial` 驱动通常分配 `ttyUSB*`，CDC ACM 设备常由 `cdc_acm` 分配 `ttyACM*`。编号取决于当时已有设备和枚举顺序；更换端口、重启、重新插拔或另一设备先出现，都可能改变编号。因此，编号适合临时检查，不适合表示“云台”或“独立 IMU”这样的长期角色。

udev 是 Linux 的用户态设备管理机制。内核通过 uevent 报告设备变化，`systemd-udevd` 匹配规则后可以设置权限、属组和符号链接。自定义规则的目标是按可核对的设备属性识别目标，并创建表达逻辑角色的别名。

==== 查设备：先读出它的稳定属性

先检查系统已经生成的链接，并确认它们在重插和重启后是否保持所需含义：

```bash
ls -l /dev/serial/by-id/ /dev/serial/by-path/
```

`by-id` 通常依赖设备报告的厂商、型号和序列号，适合有可靠唯一序列号的设备；`by-path` 依赖 USB 拓扑，适合固定接线。并非所有设备都会生成两类链接。若需要自定义 `/dev/rm_serial`，再用 `lsusb` 查看厂商号和产品号：

```bash
$ lsusb
Bus 001 Device 007: ID 1a86:7523 QinHeng Electronics CH340 serial converter
```

这里的 `1a86:7523` 是该示例 CH340 的 `idVendor:idProduct`。FT232 常见 `0403:6001`，CP210x 常见 `10c4:ea60`，部分 STM32 CDC 固件使用 `0483:5740`；这些数字只标识示例型号，实际规则必须读取目标设备。更完整的属性可用 `udevadm` 沿设备链查看：

```bash
# 沿父子链上溯，逐层打印可用的匹配属性
udevadm info --attribute-walk --name=/dev/ttyUSB0
# 或看已解析好的属性键值
udevadm info --query=property --name=/dev/ttyUSB0   # ID_VENDOR_ID / ID_MODEL_ID / ID_SERIAL
```

`--attribute-walk` 先列设备自身，再逐层列出父设备。对常见 USB 串口，`SUBSYSTEM=="tty"` 位于叶子，`idVendor`、`idProduct` 和可能存在的 `serial` 则位于某个 USB 祖先。规则中的 `ATTR{}` 只看当前设备，`ATTRS{}` 会在父链中寻找匹配属性；也可以使用 `ENV{ID_VENDOR_ID}` 等已经导出的 udev 属性，但必须用 `udevadm info` 确认本机实际提供了什么。

==== 按父链属性写规则：使用 ATTRS

本机自定义规则通常放在 `/etc/udev/rules.d/`，文件按名称的词典序处理，因此常用数字前缀控制相对顺序，例如 `99-rm-serial.rules`。下面的示例按 VID/PID 匹配一个 CH340，并创建 `/dev/rm_serial`：

```text
# /etc/udev/rules.d/99-rm-serial.rules
SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", \
    MODE="0660", GROUP="dialout", SYMLINK+="rm_serial"
```

逐项看这条规则：

- `SUBSYSTEM=="tty"`：`==` 表示匹配。`SUBSYSTEM` 是匹配键，误写成赋值运算符会使规则解析失败或被忽略。较新的 systemd 可直接验证规则文件。下面先验证前文的正确规则；在本机 systemd 255 中，成功摘要如下：

```bash
$ udevadm verify /etc/udev/rules.d/99-rm-serial.rules
1 udev rules files have been checked.
  Success: 1
  Fail:    0
```

  如果故意把第一项误写为 `SUBSYSTEM="tty"`，同一工具会报告 `Invalid operator for SUBSYSTEM` 并以失败状态退出。这样才能确认验证器确实检查到了运算符，而不是把“命令没有输出”误当成通过。不同 systemd 版本的输出格式可能不同；Ubuntu 22.04 所用的较旧 systemd 还可能没有 `udevadm verify`，此时使用下一节的 `udevadm test` 检查解析和匹配过程。
- `ATTRS{idVendor}=="1a86"`、`ATTRS{idProduct}=="7523"`：在本例中，这两个属性位于同一个 USB 祖先，因此使用 `ATTRS`。同一条规则中的多个 `ATTRS` 条件必须能在同一个父设备上同时成立；若属性分属不同层，应改用导出的 `ENV{}` 属性或拆分匹配思路，而不是盲目叠加条件。
- `MODE="0660"`、`GROUP="dialout"`：让所有者和指定组可读写。组名与权限策略随发行版和设备规则变化，先用 `ls -l`、`getent group dialout` 和队内安全策略确认；不要为了方便长期用 `sudo` 启动整套视觉程序。
- `SYMLINK+="rm_serial"`：追加一个符号链接。`+=` 保留此前规则已经加入的其他链接；`=` 会重置当前规则处理过程中累积的 `SYMLINK` 值，但不会把内核设备节点 `/dev/ttyUSB0` 本身改名或删除。

行尾的 `\` 是续行，规则太长时可以折行。

==== 让规则生效：reload 与 trigger

重新加载规则并不会自动对已存在设备重放事件。最直观的做法是重新插拔目标设备；若要在不拔线的情况下测试，可以只对目标 sysfs 路径触发事件，避免让全机设备都重新执行规则：

```bash
sudo udevadm control --reload
device_path=$(udevadm info --query=path --name=/dev/ttyUSB0)
sudo udevadm trigger --action=add --settle "$device_path"
```

`udevadm trigger` 的默认动作是 `change`，而不少规则带有 `ACTION=="add"` 条件；显式写 `--action=add` 可以模拟插入事件。上面的示例规则没有 `ACTION` 条件，两种动作都能匹配。触发后仍应检查实际链接和权限，不能把命令正常退出当作规则已经命中的证明。

==== 验证：SYMLINK 真的生成了

先检查符号链接是否存在、最终指向哪个设备，并核对目标设备属性：

```bash
$ ls -l /dev/rm_serial
lrwxrwxrwx 1 root root 7 ... /dev/rm_serial -> ttyUSB0
readlink -f /dev/rm_serial
udevadm info --query=property --name=/dev/rm_serial
```

链接存在只说明某条规则创建了名称，还要确认 VID/PID、序列号或物理路径确实对应目标设备。`udevadm test` 可以打印规则解析与匹配过程；它使用 sysfs 路径，因此先单独取得路径并加引号：

```bash
device_path=$(udevadm info --query=path --name=/dev/ttyUSB0)
sudo udevadm test "$device_path" 2>&1 | grep -iE 'rm_serial|symlink'
```

确认重插后别名仍指向同一逻辑设备，再把配置改为稳定路径：

```yaml
/rm_serial_driver:
  ros__parameters:
    device_name: /dev/rm_serial      # 从 /dev/ttyACM0 改成 udev 别名
    baud_rate: 115200                # 波特率随链路而定，见下
```

==== 多个同型号设备：serial 与物理端口

一台机器人可能同时连接云台控制器、裁判系统接口和独立 IMU。若两个设备具有相同 VID/PID，只按型号写规则会同时匹配，两者可能争用同一个别名。此时需要加入能区分个体或物理位置的条件。

若设备报告了可靠且唯一的序列号，可以加入 `ATTRS{serial}`。不要根据芯片型号假定序列号一定存在或唯一，应从两台实物的 `udevadm info --attribute-walk` 输出核对：

```text
SUBSYSTEM=="tty", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="5740", \
    ATTRS{serial}=="3576346C3138", SYMLINK+="rm_gimbal"
SUBSYSTEM=="tty", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="5740", \
    ATTRS{serial}=="207D35843047", SYMLINK+="rm_imu"
```

若没有可靠序列号，可以按固定 USB 拓扑命名。`KERNELS` 能匹配父链中的端口路径，具体字符串仍从本机 `udevadm` 输出读取：

```text
SUBSYSTEM=="tty", KERNELS=="1-1.2", SYMLINK+="rm_top"
SUBSYSTEM=="tty", KERNELS=="1-1.3", SYMLINK+="rm_bottom"
```

按物理口命名便于更换同型号设备，但移动集线器、改变拓扑或插错端口都会改变角色；按序列号命名不依赖插口，却要求固件稳定报告唯一值。无论采用哪种方式，都要同时插上全部设备，反复重插并验证每个逻辑名称，而不是逐个设备单独测试。

波特率也属于具体链路配置，不应由设备节点名称推断。USB-UART 桥后的真实 UART 需要两端采用一致速率，并按 8N1 等格式计算带宽；USB CDC ACM 中用于设置串口参数的 line coding 可能只是一项主机请求，实际吞吐取决于固件与 USB 端点。协议版本、字段和速率都应从当季官方手册、设备固件与实测配置共同确认。

=== 验证：通信模块稳定性确认

模块能够收发一帧，只覆盖了正常路径。上线前还应验证短读、部分写入、错位、CRC 错误、断开重连、并发发送、进程退出和下位机失联保护。下面把这些检查组织成可重复的动作。

==== 断开、恢复与退出

在可控测试环境中运行模块，断开 USB 或停止下位机发送，观察检测故障所需时间、重试节奏以及下位机进入安全状态的时间；恢复连接后，确认收发计数、TF 和控制状态都恢复，而不只是出现 `Successfully reopened port` 日志。断开期间同时触发发送回调，可以暴露两条线程并发重开端口的问题。最后在设备保持沉默时正常关闭 ROS 2，确认进程能在规定时间内退出；这项检查针对“先 join、后 close”的潜在阻塞边界。

==== CRC 失败率与长跑

长跑时，两端都应统计发送帧、接收帧、短读、部分写入、无效帧头、CRC 失败、重连次数和最大连续丢失时间，并给出测试时长、速率、线缆、供电和负载。CRC 失败并不能单独诊断物理误码：短读未累计、帧长或字节序不一致、缓冲区溢出、DMA 边界和接地问题都可能产生相同现象。先用受控注入验证计数器和恢复逻辑，再逐层排查；“接近零”或某个百分比只有在团队预先定义了样本量和验收条件后才有意义。

接收测试应把一帧拆成多个小块，并在帧前插入随机字节、载荷内放入 `0x5A`、翻转一个数据位；发送测试则用模拟串口限制每次接受的字节数。这样可以分别验证短读累计、部分写入处理、错位重同步和 CRC 拒绝，而不是用连续完整帧替代这些测试。

==== 多设备与命名空间

如果同一进程或 ROS 图中运行多个串口节点，udev 只解决设备身份，ROS 层还要区分节点、话题、服务和坐标系。节点命名空间会作用于相对名称，不会自动改写代码中的绝对服务名 `/tracker/reset`，frame ID 字符串也不会随命名空间变化。`robot_state_publisher` 等个别节点提供 `frame_prefix` 参数，但本章参考串口节点把 `odom` 与 `gimbal_link` 写在源码中。

因此，多实例部署应为每个节点设置独立 `device_name`，逐项检查绝对和相对名称是否可 remap，并让每条 TF 使用唯一且连通的 frame ID。仅改变节点 namespace 不能防止两个实例同时广播同名 `odom → gimbal_link`；需要修改可配置 frame 参数或源码，并在合并后的 TF 树中检查父节点、时间戳和唯一发布者。

==== 一份上车前的通信自检清单

下表把正文中的条件转成可执行检查。项目应在测试记录中填写实际结果、样本量和版本，而不是只保留空白清单。

#figure(
  table(
    columns: (auto, auto, auto),
    align: (left, left, left),
    stroke: (x, y) => (
      top: if y == 1 or y == 0 { 1pt } else { 0pt },
      bottom: if y == 9 { 1pt } else { 0pt },
    ),
    inset: 7pt,
    table.header([*检查项*], [怎么确认], [不过关的表现]),
    [设备身份], [`readlink -f` 与 `udevadm info` 对应目标实物], [重插后别名指向另一设备或消失],
    [权限], [目标账户可读写，组与 ACL 符合安全策略], [`Permission denied` 或权限过宽],
    [分片收发与重同步], [限制单次读写长度，并插入杂字节和载荷帧头], [返回长度未累计、截断发送或长时间错位],
    [断开与退出], [断线、并发发送、重插及静默退出均在时限内完成], [并发 reopen、递归增长或 join 卡住],
    [错误计数], [记录分母、CRC、无效帧头、部分读写和重连次数], [只有日志，无法区分错误来源],
    [包布局], [两端 `sizeof`/字段偏移与黄金字节互解一致], [编译器或固件更换后字段错位],
    [失联保护], [停止上位机数据后，下位机按约定超时进入安全状态], [持续执行过期目标指令],
    [多实例], [设备名、话题、服务和 frame ID 均唯一且 TF 连通], [绝对名或同名 TF 互相覆盖],
    [时间戳], [用共同事件测量偏移与抖动，并记录配置], [只能调出单个常数，无法解释误差],
  ),
  caption: [串口模块部署前检查。中列给出可观察动作，右列说明该检查能暴露的现象；任何一项通过都只覆盖相应条件。帧格式、故障注入和统计口径的详细方法见「通信协议设定」一章。],
)

==== 本章小结

本章把既定协议接入一个 ROS 2 驱动：专用线程处理同步接收，目标订阅回调负责发送，合法接收包进一步更新姿态 TF、识别颜色和跟踪器状态。直接复制 packed 结构体只在两端 ABI 已验证时可用；Humble `serial_driver` 的 `read_some` 与 `write_some` 还要求调用者处理部分读写。当前递归重连、并发开关端口和析构顺序都有待补强，不能因为一次重插恢复就视为完整容错。

udev 部分说明了怎样先利用 `/dev/serial/by-id`、`by-path`，再按实际父链属性创建自定义链接；同型号多设备还需要序列号或物理端口条件。部署验证必须覆盖设备身份、权限、部分读写与重同步、包布局、断线恢复、正常退出、失联安全状态、多实例命名和时间对齐。日志出现“reopened”或 CRC 为零，都不能单独证明整条通信链可靠。

应用篇至此形成从相机、识别、跟踪和预测到电控接口的完整主线。下一篇扩展到雷达站和哨兵：传感器位置、坐标参考、运动主体和决策职责都会变化；随后再讨论性能测量与赛场故障复盘。通信模块中的时间、命名、恢复和证据边界，也会在这些更复杂系统中继续出现。
