=== 从协议契约到驱动模块

上一章把整条链算到了"发出云台指令"为止：规划器吐出一组 yaw／pitch 的位置、速度、加速度，外加一个开火与否的布尔量。现在这些数要真的离开进程、抵达电控——这是数据流的最后一站，也是本篇的收口。

「实战技术篇」的通信协议设定一章，做完了一件事：把视觉与电控之间要传什么、按什么字节布局传、坏了怎么办，写成一份双方都签字的*契约*——帧头、CRC、每个字段的语义和量纲，全部钉死。基础篇「计算机系统基础」与「C++ 语言基础」两章，则把契约底下的*机制*讲透了：串口在 Linux 里是字符设备，用 termios 配成 raw 模式，用逐字节状态机在字节流里找帧、验 CRC、丢坏帧。

那两件事都做完了，为什么还需要单独一章？因为一份协议加一段 `read`/`write`，离"能上场"还差得远。真正要在车上跑一整场的通信模块，得回答一串协议之外的工程问题：读串口会阻塞，它该占哪个线程，不能把整个视觉主循环卡死；比赛里线一定会松、电控一定会重启，断了怎么自己接回来；插拔一次设备名就在 `ttyUSB0` 和 `ttyUSB1` 之间跳，程序怎么才能每次都找到那根线；一台车上不止一个串口设备，怎么区分；串口收到的姿态和颜色，怎么喂给识别器和跟踪器。本章就把协议契约落成这样一个模块——一个独立线程收发、断线自愈、设备名固定、能接进整个自瞄系统的软件件。

先划清边界，免得和别的章打架：协议*字段怎么设计*是「实战技术篇」的事，本章只把它当既定契约来消费；termios 配置、CRC *怎么算*是基础篇的事，本章只调用、不重讲。本章的主场是*实现层与集成层*——线程模型、节点接口、断线重连，以及本章的重头戏：从零把 udev 规则写对。

=== 收发骨架：一根线，两个线程

先看这个模块长什么样。下面的骨架取自社区广泛使用的一套 ROS2 串口驱动（Apache-2.0 协议），它把一根串口线包成一个 ROS 节点，对外只暴露"订阅目标、广播姿态"两个接口，对内跑着两条并行的数据流。

#figure(
  image("images/app-serial-node-dataflow.png", width: 100%),
  caption: [串口节点的线程与数据流模型（脚本 `app_serial_node_dataflow.py`）。读图规则：整个节点由*两条独立线程*驱动——左侧粗箭头是一条专职的接收线程（阻塞式 `read` 循环，同步帧头 `0x5A` 后整帧验 CRC），把每一帧合法数据*扇出*成右侧三条控制面（姿态 TF、识别器改色、跟踪器复位）；下方是发送回调，被"目标"话题触发时才运行，把跟踪结果打包写回串口。任何一侧的 I/O 抛异常，都落到 `reopenPort()` 自愈（红色虚线）。记住这张图的一句话：*串口节点不是一个收发字节的管道，而是电控与视觉之间那张双向控制面*。],
)

==== 独立接收线程：为什么不能在回调里读串口

串口的 `read` 是阻塞的——线上没有字节，它就一直等。基础篇讲 `VMIN`/`VTIME` 时已经点破过：对端彻底沉默（线断了、电控死机，车上最常见的故障），`read` 会无限期挂住。如果把读串口写进 ROS 的定时器或某个消息回调里，这一挂就把整个执行器（executor）的线程占死，同一线程上排队的所有回调——图像处理、参数服务、TF——全部停摆。所以健壮的做法只有一个：*给接收开一条自己的线程*。

```cpp
// 构造函数里：打开串口，起一条专职接收线程
serial_driver_->init_port(device_name_, *device_config_);
if (!serial_driver_->port()->is_open()) {
  serial_driver_->port()->open();
  receive_thread_ = std::thread(&RMSerialDriver::receiveData, this);
}
```

这条线程里跑的是一个"同步帧头、整帧读取、验 CRC、分发"的循环：

```cpp
void RMSerialDriver::receiveData() {
  std::vector<uint8_t> header(1);
  std::vector<uint8_t> data;
  while (rclcpp::ok()) {
    try {
      serial_driver_->port()->receive(header);   // 阻塞读 1 字节
      if (header[0] != 0x5A) continue;            // 没同步上，丢弃重来

      data.resize(sizeof(ReceivePacket) - 1);
      // 注意：上游是 read_some，可能短读
      serial_driver_->port()->receive(data);      // 帧长固定，一次取剩余
      data.insert(data.begin(), header[0]);
      ReceivePacket packet = fromVector(data);

      if (crc16::Verify_CRC16_Check_Sum(              // 验 CRC，机制见基础篇
            reinterpret_cast<const uint8_t *>(&packet), sizeof(packet))) {
        // …… 合法帧：扇出到三条控制面（下一节）
      } else {
        RCLCPP_ERROR(get_logger(), "CRC error!");   // 坏帧：丢弃计数
      }
    } catch (const std::exception & ex) {
      reopenPort();                                 // I/O 出错：自愈
    }
  }
}
```

这里有个和基础篇不一样的取舍值得点一句。基础篇的状态机是*逐字节*喂的，因为它要处理任意长度、任意粘包的流；这里因为帧长*固定*，就简化成"读到帧头 `0x5A`，再一口气读满剩下的字节"。简单，但代价也在：万一载荷里凑巧出现一个 `0x5A` 且此时真发生了错位，它要靠后续字节自然重新对齐才能恢复——这正是基础篇串口一节留的那道"假帧头"思考题，在实现层的真实回响。有线串口误码本底极低，这个简化在实战里几乎不出问题，但你得知道它的边界在哪。

比"假帧头"更常触发的其实是另一条：`receive()` 底下是一次 `read_some`——它只保证阻塞到*至少一个字节*可读就返回，并不保证读满你要的长度。真短读一次，缓冲区尾部就留着上一帧的残字节，`fromVector` 照样拼出一个结构体，CRC 必然失败、整帧被丢。健壮的做法是*循环读直到凑满* `sizeof(ReceivePacket) - 1`，否则短读会表现成一种很难查的症状：周期性、看不出规律的 `CRC error`，而物理层其实一点毛病没有。*把"读 N 字节"当成一次调用就能完成的事，是流式 I/O 上最经典的误解。*

==== 双包序列化：结构体就是字节流的模具

协议契约在 C++ 里的落地，就是两个 `__attribute__((packed))` 的结构体——一个收、一个发，两个方向各用一个固定且不同的帧头（`0x5A` 收、`0xA5` 发），一眼就能分清方向：

```cpp
struct ReceivePacket {            // 电控 -> 视觉，28 字节
  uint8_t  header = 0x5A;
  uint8_t  detect_color : 1;      // ……标志位域
  bool     reset_tracker : 1;
  uint8_t  reserved : 6;
  float    roll, pitch, yaw;      // ……姿态与调试瞄准点载荷
  float    aim_x, aim_y, aim_z;
  uint16_t checksum;
} __attribute__((packed));

struct SendPacket {               // 视觉 -> 电控，48 字节
  uint8_t  header = 0xA5;
  bool     tracking : 1;          // ……标志位域
  uint8_t  id : 3;
  uint8_t  armors_num : 3;
  uint8_t  reserved : 1;
  float    x, y, z, yaw, vx, vy, vz, v_yaw, r1, r2, dz;   // ……整车状态载荷
  uint16_t checksum;
} __attribute__((packed));
```

每个字段各是什么语义、位域为什么这么编、`packed` 为什么必须加——「实战技术篇」通信协议设定一章已经把这对结构体逐字段解剖过了，本章不重复，只把它当模具用。序列化本身朴素到只是一次 `memcpy`：

```cpp
inline std::vector<uint8_t> toVector(const SendPacket & d) {
  std::vector<uint8_t> v(sizeof(SendPacket));
  std::copy(reinterpret_cast<const uint8_t *>(&d),
            reinterpret_cast<const uint8_t *>(&d) + sizeof(SendPacket), v.begin());
  return v;   // 结构体 -> 字节流，直接送进 port()->send()
}
```

这套 `memcpy` 收发隐含着"两端字节序相同"的假设——x86 的 NUC 和 STM32 都是小端，成立；跨大端设备就得逐字段序列化，这个坑基础篇交代过。

顺带一个真实代码里的小勘误，当作读码练习：发送端把兵种字符串映射成 `id` 时用了一个 `std::map`，`at()` 查表——如果哪天上游送来一个映射表里没有的字符串，`at()` 会抛 `std::out_of_range`，而这个异常被外层 `catch` 接住后会去*重开串口*。一个查表失误触发一次无谓的重连，不致命，但属于"异常路径设计得不够精确"的典型：*异常的捕获范围要和它真正该处理的错误对齐*，别让一类错误借另一类错误的通道逃逸。

=== 把串口接进系统：三条控制面

如果串口节点只是收发字节，它就配不上"模块"这个词。它真正的价值在于：串口是视觉进程里*唯一*能实时拿到电控与 IMU 状态的入口，于是整个系统的三条控制面都从这里生根。回头看数据流图右侧那三个出口，逐条说清。

==== 姿态 TF：坐标链的根在这里

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

为什么是*串口节点*来发这条 TF？因为「坐标变换」一章论证过：预测必须在惯性系里做，而云台此刻的朝向只有 IMU 知道，IMU 的数据只从这根串口进来。识别器解算出装甲板在相机系的位置后，要沿相机→云台→惯性系的链一路变换，这条链的*根节点*就是这里广播的 `odom → gimbal_link`。串口节点一旦不发或发错这条 TF，下游整条坐标链就断了。

`timestamp_offset` 这个细节则牵回时间戳。姿态是在电控那端某个更早的时刻*采样*的，等字节跨过 USB、经过线程调度、到你这里调用 `now()`，已经晚了几毫秒。所以给到达时刻加一个标定出来的常数偏移，把这段固定时延补偿掉。

要点在于*这个常数补的不是串口那一路的绝对时延*，而是姿态流与图像流之间的*相对*时延——识别器是拿*图像*的时间戳去 `lookupTransform` 查姿态的，两条链路谁更慢，符号就往哪边偏。别想当然认为它一定取负：相机取图链路（曝光、传输、驱动、回调）通常比一帧 28 字节串口数据（115200 波特下约 2.4 ms）慢得多，所以净偏移取*正*才是常态——参考实现的配置里它就是 `+0.006`，即 +6 ms 量级。具体值怎么测、为什么不补就会"甩枪"，是「实战技术篇」时间戳对齐一章的内容，这里只负责把它用对。

==== 回写识别器、复位跟踪器

另外两条控制面是电控*反向*控制视觉的开关。其一是敌方颜色：你这一场是红是蓝、该打哪种颜色的灯条，编译期并不知道，是裁判系统告诉电控、电控通过 `detect_color` 这一位告诉视觉的。收到后，节点用一个异步参数客户端去改识别器的运行参数——而且只在颜色*变化*时才改，避免每帧都刷一次参数：

```cpp
if (!initial_set_param_ || packet.detect_color != previous_receive_color_) {
  setParam(rclcpp::Parameter("detect_color", packet.detect_color));
  previous_receive_color_ = packet.detect_color;
}
if (packet.reset_tracker) resetTracker();          // 一位触发跟踪器复位
```

其二是 `reset_tracker`：电控（或操作手）用一个 bit 就能触发跟踪器丢弃当前状态、从头再来——比如目标切换、跟丢后想强制重置。节点把它翻译成一次 ROS 服务调用（`/tracker/reset`）。这两条一起说明了那句话：*串口是双向控制面*——视觉往下发目标，电控往上发指令，一根线上跑着两个方向的控制流。

=== 掉线一定会发生：断线重连

车上的串口连接会断，这不是意外而是常态：接插件在剧烈对抗中松动、电控主动重启、USB 供电抖动导致重新枚举。所以模块必须能*自己接回来*。上面每一处 `catch` 里调用的 `reopenPort()`，逻辑很直白——关掉再打开，失败就等一秒重试，直到成功：

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
      reopenPort();                                 // 递归重试，直到接回来
    }
  }
}
```

这套"读写出错就重开、开不成功就退避重试"的模式，是所有上场级串口模块的标配，只是各家实现的火候不同。作为对照，一支强队在 25 赛季开源的完整框架（MIT 协议，*不依赖 ROS*）把自愈做得更重：它不靠 ROS 节点，而是用一条自己的 `std::thread` 守护读循环，累计错误计数超过阈值才触发重连，重连时反复 `close`/`open` 并清空数据队列。两种实现殊途同归，但它们的架构哲学恰好形成一组好对照——

一边是 ROS2 生态：节点、话题、TF、参数服务，模块之间靠消息解耦，串口只是众多节点之一。另一边是无 ROS 的自研栈：普通 C++ 类加内部线程，线程安全队列在模块间传数据，一个进程装下相机、识别、通信所有功能组。后者的收发结构体也透着不同的设计取向：它的发送包不是整车状态，而是 `yaw / yaw_vel / yaw_acc` 加 `pitch / pitch_vel / pitch_acc` 这样的*位置-速度-加速度前馈三元组*——

```cpp
struct __attribute__((packed)) VisionToGimbal {   // 无 ROS 框架的发送包（MIT）
  uint8_t  head[2] = {'S', 'P'};                   // 两字节帧头，另一种同步策略
  uint8_t  mode;                                   // 0 不控 / 1 控云台不开火 / 2 控且开火
  float    yaw, yaw_vel, yaw_acc;                  // 前馈三元组
  float    pitch, pitch_vel, pitch_acc;
  uint16_t crc16;
};
static_assert(sizeof(VisionToGimbal) <= 64);       // 编译期钉死帧长上限
```

发整车状态、把火控留给下位机算，还是发算好的云台轨迹（位置/速度/加速度）、下位机只管跟随——这是两种真实存在的分工路线，*火控到底放在上位机还是下位机*的抉择就藏在这个结构体里。它牵扯到轨迹规划与开火决策，是「自瞄算法设计」一章的主场，这里只提醒你：看串口发什么，就能反推出一支队伍把智能放在了哪一端。至于两字节帧头 `'S''P'` 对单字节 `0x5A` 的取舍、`static_assert` 钉死帧长的习惯，都是同一套"结构体即模具"思想的不同手法。

=== 兑现债：用 udev 把设备名钉死

到这里模块的软件骨架齐了，但有一件部署琐事，基础篇的「计算机系统基础」与「C++ 语言基础」两章，加上实战技术篇的通信协议设定，一共欠了三次账、每次都说"留到串口模块章讲"——现在还上：*比赛现场每插拔一次 USB，设备名就在 `/dev/ttyUSB0` 和 `/dev/ttyUSB1` 之间漂移，配置文件里写死的设备名就失效了，怎么办？* 答案是 udev 规则。这一节从零把它讲全。

#figure(
  image("images/app-serial-udev-chain.png", width: 100%),
  caption: [设备名为什么会跳、udev 又怎么把它钉死（脚本 `app_serial_udev_chain.py`）。读图规则：从左往右看两件事。左半是 sysfs 里的*设备父子链*——你的串口 `ttyUSB0` 只是叶子（`SUBSYSTEM=="tty"`），而识别这根线的 `idVendor`/`idProduct` 长在它的*祖先*（USB 设备）上；所以规则里必须用 `ATTRS{}`（沿链*上溯*查找），用 `ATTR{}`（只看叶子自己）永远查不到 `idVendor`——这是写 udev 规则最常栽的坑。右半是事件流：内核插入事件 → `udevd` 匹配规则文件 → 命中规则创建符号链接。最终 `/dev/rm_serial` 这个固定名字，*不管底层这次被编号成 ttyUSB0 还是 ttyUSB1*，都稳稳指向那根线。],
)

==== 名字为什么会跳

根因在内核。USB 转串口设备接入时，`usb-serial`（或 CDC-ACM 设备的 `cdc_acm`）驱动会给它分配 `ttyUSB`/`ttyACM` 名字空间里*下一个空闲编号*。而"哪个设备先被枚举"取决于开机时序、USB 集线器拓扑、你先插哪根线——全是非确定性的。于是同一根线，这次开机是 `ttyUSB0`，下次可能就是 `ttyUSB1`；一台车上两个串口设备，谁抢到 `0` 谁抢到 `1` 全看运气。把设备名写死在配置里，等于赌每次枚举顺序都一样——这个赌注在赛场上必输。

udev 是 Linux 的用户态设备管理器。内核每检测到一个设备，就通过 netlink 发一个 uevent 给 `systemd-udevd`；`udevd` 拿这个设备去和一堆规则文件比对，命中了就能给它设权限、改属主，以及——*创建一个固定名字的符号链接*。我们要做的，就是写一条规则：认出"那根线"，给它一个雷打不动的别名。

==== 查设备：先读出它的稳定属性

要认出一根线，得先知道它有哪些*稳定*属性可认。最快的一步是 `lsusb`，拿到厂商号和产品号：

```bash
$ lsusb
Bus 001 Device 007: ID 1a86:7523 QinHeng Electronics CH340 serial converter
```

`1a86:7523` 就是这块 CH340 芯片的 `idVendor:idProduct`（FTDI 的 FT232 是 `0403:6001`、CP2102 是 `10c4:ea60`、STM32 的虚拟串口 CDC 是 `0483:5740`——*你的芯片是什么就填什么，别照抄*）。更完整的属性用 `udevadm` 沿设备链查：

```bash
# 沿父子链上溯，逐层打印可用的匹配属性
udevadm info --attribute-walk --name=/dev/ttyUSB0
# 或看已解析好的属性键值
udevadm info --query=property --name=/dev/ttyUSB0   # ID_VENDOR_ID / ID_MODEL_ID / ID_SERIAL
```

`--attribute-walk` 的输出分成若干块：第一块是设备*自己*（那个 `ttyUSB0`，`SUBSYSTEM=="tty"`），往下每一块是它的一层*父设备*——`usb-serial` 接口、再往上才是 USB 设备本体。关键的一课就在这里：`idVendor`、`idProduct`、`serial` 这些属性，*不在 `ttyUSB0` 自己身上，而在它上溯两三层的 USB 设备本体上*。这决定了下一步规则该怎么写。

==== 写规则文件：是 ATTRS，不是 ATTR

规则文件放在 `/etc/udev/rules.d/`，文件名习惯以数字开头（数字决定处理顺序，越大越晚），比如 `99-rm-serial.rules`。一条把 CH340 钉成 `/dev/rm_serial` 的规则长这样：

```text
# /etc/udev/rules.d/99-rm-serial.rules
SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", \
    MODE="0660", GROUP="dialout", SYMLINK+="rm_serial"
```

逐个键拆开，每一个都藏着一个能让规则静默失效的坑：

- `SUBSYSTEM=="tty"`：匹配这是个 tty 字符设备。注意*两个等号*——`==` 是"匹配"，`=` 是"赋值"。`SUBSYSTEM` 属于*只读的匹配专用键*，写成 `SUBSYSTEM="tty"` 并不会变成一条恒真的赋值，而是被 udev 判为 `Invalid operator`，*整行规则直接被丢弃*——后果是规则彻底不生效，一个 `SYMLINK` 都不建。这个失效是静默的：`udevadm control --reload` 不会冲你喊。好在有一条命令能当场看到：

```bash
$ udevadm verify 99-rm-serial.rules
99-rm-serial.rules:1 Invalid operator for SUBSYSTEM.
99-rm-serial.rules: udev rules check failed.
```

  *写完规则先 `udevadm verify` 过一遍*，比事后对着不存在的符号链接干瞪眼便宜得多。（`udevadm verify` 需要较新的 systemd；版本太老没有这个子命令时，退而用下一节的 `udevadm test` 干跑，看规则有没有被命中。）
- `ATTRS{idVendor}=="1a86"`、`ATTRS{idProduct}=="7523"`：认出是哪块芯片。*这里必须是 `ATTRS`（带 S）而不是 `ATTR`*。`ATTR{}` 只查设备叶子自己，而上一节已经看到，`idVendor` 根本不在叶子上；`ATTRS{}`（复数、带 S）会沿父子链*一路上溯*去找，才能在 USB 设备本体那层命中。写成 `ATTR{idVendor}` 的规则永远匹配不上——这是 udev 头号疑难。（同一条规则里连续的多个 `ATTRS` 会被要求匹配在*同一个*父设备上，而 `idVendor` 和 `idProduct` 恰好同住 USB 设备那层，所以这么写正好。）
- `MODE="0660"`、`GROUP="dialout"`：顺手把权限设对，让 `dialout` 组的成员能读写。为什么是 `dialout` 组、为什么别用 `sudo` 跑整个程序，基础篇「计算机系统基础」讲过，这里只是把那条结论在规则里落一次地。
- `SYMLINK+="rm_serial"`：创建 `/dev/rm_serial` 指向这根线。用 `+=`（追加）而不是 `=`（覆盖），因为一个设备可以有多个符号链接，`=` 会把系统默认加的那些链接一并抹掉。

行尾的 `\` 是续行，规则太长时可以折行。

==== 让规则生效：reload 与 trigger

写完文件，规则*不会自动生效*——`udevd` 只在下次收到设备事件时才读新规则，而你的设备此刻已经插着、不会再触发事件。两条命令解决：

```bash
sudo udevadm control --reload     # 让 udevd 重新加载规则文件
sudo udevadm trigger              # 对已在位的设备重发事件，套用新规则
```

`--reload` 让守护进程吞下新规则，`trigger` 则给已经插着的设备补发一次事件，逼着新规则对它重新跑一遍——这样不用拔插就能生效。当然，真拔下来再插回去，效果一样。

这里有个容易踩的默认值：`udevadm trigger` 补发的事件动作默认是 `change`，*不是* `add`。上面那条规则没写 `ACTION` 键，对任何动作都匹配，所以无所谓；但网上的教程里常见 `ACTION=="add"` 这样的写法，那类规则用裸 `trigger` 就*不会*被触发，你会以为规则写错了，其实只是事件动作对不上。要模拟插入，得显式指定：

```bash
sudo udevadm trigger -c add      # 补发 add 事件（-c 即 --action）
```

==== 验证：SYMLINK 真的生成了

改完必须*确认*，不能想当然。最直接的一步——符号链接在不在、指向对不对：

```bash
$ ls -l /dev/rm_serial
lrwxrwxrwx 1 root root 7 ... /dev/rm_serial -> ttyUSB0
```

有这条链接，且它是个指向 `ttyUSB0` 的 `l`（符号链接），就成了。想在拔插前就*预演*规则会不会命中，用 `udevadm test` 干跑一遍，它会打印每条规则的匹配过程和最终赋予的 `SYMLINK`：

```bash
udevadm test $(udevadm info -q path -n /dev/ttyUSB0) 2>&1 | grep -i symlink
```

最后一步，把配置里写死的设备名换成这个固定别名，`ttyUSB0`/`ttyUSB1` 怎么跳都不再关它的事：

```yaml
/rm_serial_driver:
  ros__parameters:
    device_name: /dev/rm_serial      # 从 /dev/ttyACM0 改成 udev 别名
    baud_rate: 115200                # 波特率随链路而定，见下
```

==== 多个同型号设备：serial 与物理端口

一台车常不止一个串口设备。举个真实的例子：云台电控走一根串口，某些队伍还挂一颗独立 IMU（比如某款达妙 IMU 走 `/dev/ttyACM0`、波特率 `921600`）——两个都是 tty，都可能抢 `ttyACM0`。如果它们*厂商号产品号还相同*（两块一样的 STM32、两根一样的 CH340），`idVendor`/`idProduct` 区分不开，怎么办？两条路：

其一，若设备有*唯一序列号*（多数 STM32 的 CDC 串口有，很多廉价 CH340 没有或全都一样），加一条 `ATTRS{serial}`：

```text
SUBSYSTEM=="tty", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="5740", \
    ATTRS{serial}=="3576346C3138", SYMLINK+="rm_gimbal"
SUBSYSTEM=="tty", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="5740", \
    ATTRS{serial}=="207D35843047", SYMLINK+="rm_imu"
```

其二，若连序列号都没有（廉价芯片的常态），就退而认*物理 USB 端口*——用 `KERNELS` 匹配设备接在哪个口上，插在哪个口就叫什么名。端口路径同样从 `udevadm info --attribute-walk` 里读：

```text
SUBSYSTEM=="tty", KERNELS=="1-1.2", SYMLINK+="rm_top"
SUBSYSTEM=="tty", KERNELS=="1-1.3", SYMLINK+="rm_bottom"
```

按物理口命名有个好处：换了同型号的坏芯片也不用改规则，插回原来的口就行；代价是从此这根线*绑死了那个 USB 口*，接线时别插错。选序列号还是选物理口，就看你的设备有没有可靠的唯一序列号——这是多设备命名的核心权衡。

顺带一句关于波特率：它不是永远 `115200`。同一套裁判系统链路，普通图传是 `115200`，换上新款图传就要调到 `921600`；而且协议本身也随赛季变——社区维护的裁判系统 ROS2 驱动就记录了近年"串口协议"更名为"通信协议"、并用带 `legacy-` 前缀的版本标记改名前后的分界。*一切协议参数都随赛季变动，以当季官方手册为准*，别把某一年的数字焊死在脑子里。

=== 验证：通信模块稳定性确认

模块写完不等于做对了。通信是自瞄链条上最沉默的一环——它平时不出声，一出声就是赛场上突然断连、云台失控。所以上车前必须主动把它*往死里测*一遍。这一节给出四个"怎么确认做对了"的动作，前三个专治三种真实故障，最后收成一张清单。

==== 拔插不掉

这是最该做、也最容易被跳过的一测。让模块跑起来，然后*直接拔掉 USB 线*，看日志里有没有 `Attempting to reopen port`；再插回去，看它是否自己打印 `Successfully reopened port` 并恢复收发。断得干净、接得回来，`reopenPort` 才算真的在工作。别只在代码里"看着像能重连"就放心——比赛里那根线一定会松，这一关不过，等于把整场比赛押在接插件的运气上。

==== CRC 失败率与长跑

「实战技术篇」通信协议设定一章已经定过验收标准，这里复用它的结论：有线串口的物理误码本底极低，连续长跑（半小时起）时，两端各自统计发帧数、收帧数、CRC 失败数，*CRC 失败应当是罕见事件*。失败率要是到了百分之几的量级，别归咎运气——那是波特率偏差、接地不良或下位机 DMA 配置在报警，逐项排查物理层。顺带把接收线程里那句 `CRC error!` 的日志接上一个计数器，长跑结束一眼就能看出本底。

==== 多设备与命名空间

如果一台车上跑多个串口节点（云台一个、裁判系统一个），除了用 udev 把设备名分开，ROS 层面还要把节点分开。但*命名空间能隔离什么、不能隔离什么，要分清*，否则会以为配了 `namespace` 就万事大吉：命名空间只重映射*节点名、相对话题和参数*。而 TF 走的 `/tf` 是硬编码的绝对话题，`frame_id` 只是一个普通字符串（ROS 2 已经取消了 ROS 1 的 `tf_prefix`）；代码里写死的 `/tracker/reset` 同样是绝对名。这两样*不会*被命名空间分开——两个节点仍会往同一棵 TF 树上广播同名的 `odom → gimbal_link`，互相覆盖。

要真正分家，得靠 remap，或者直接改 `frame_id`（比如第二个云台发 `gimbal_link_2`）。启动时给每个节点配好独立的 `namespace`、各自的 `device_name`，再把绝对名逐个 remap 掉，才是多设备集成的基本卫生。

==== 一份上车前的通信自检清单

把上面的检查收成一张可勾选的表，每一项都对应一种真实的翻车方式：

#figure(
  table(
    columns: (auto, auto, auto),
    align: (left, left, left),
    stroke: (x, y) => (
      top: if y == 1 or y == 0 { 1pt } else { 0pt },
      bottom: if y == 6 { 1pt } else { 0pt },
    ),
    inset: 7pt,
    table.header([*检查项*], [*怎么确认*], [*不过关的表现*]),
    [设备名固定], [`ls -l /dev/rm_serial` 指向正确 tty], [插拔后程序找不到串口、打不开],
    [权限], [普通用户能打开，无需 `sudo`（`dialout` 组）], [`Permission denied`],
    [拔插重连], [拔线见 reopen 日志、插回自恢复], [断连后彻底沉默，云台失控],
    [CRC 失败率], [长跑半小时，失败计数近零], [百分级失败＝物理层报警],
    [帧对齐], [已知字段手工解码核对（`xxd` 抽查）], [满屏乱码、帧头间距漂移],
    [时间戳补偿], [`timestamp_offset` 已标定], [跟踪滞后、"甩枪"],
  ),
  caption: [串口模块上车前自检清单。读表规则：左列是必查项、中列是*可执行*的确认动作、右列是这项没做对时会在赛场上如何暴露——照着中列逐条勾一遍，把这些失败模式在上车之前就消灭掉，而不是留到比赛里现场调试。帧对齐与破坏性演习（注入坏帧、中途复位）的完整做法在「实战技术篇」通信协议设定一章，本表只做上车前的最终复核。],
)

==== 本章小结

这一章把「实战技术篇」冻结的协议契约，落成了一个真能上车的通信模块：一条专职接收线程避免阻塞卡死主循环，`__attribute__((packed))` 结构体让内存布局与线上字节流一字节不差，三条控制面（姿态 TF、识别器改色、跟踪器复位）把串口从"收发字节的管道"升格成"电控与视觉之间的双向控制面"，`reopenPort` 递归重连扛住赛场上必然发生的断线，最后用 udev 规则把跳来跳去的设备名钉死——一并兑清了基础篇与实战技术篇一共三次前指的债。

串口是数据流的最后一站，也是控制流的第一站：视觉算出的目标从这里离开进程、送进电控，电控与 IMU 的状态又从这里回到进程、生根成坐标链。相机、识别、跟踪、能量机关、自瞄集成、串口——六章走到这里，一套能上场、还能在断连与误识别里活下来的完整自瞄系统，才算真正闭合。前三篇积累的算法与设施，到这一篇终于长成了赛场上那台会自己找目标、算提前量、扣扳机的机器。
