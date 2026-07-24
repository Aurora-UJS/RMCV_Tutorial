#import "/template/template.typ": *

前五篇主要讨论如何搭建和验证视觉系统；最后一篇换成代码阅读。这里选择三套公开项目，不按 API 逐项罗列功能，而是回答三个更适合学习的问题：作者为什么这样划分模块，这些选择解决了什么问题，又引入了哪些限制；其中哪些做法可以在条件相近的项目中复用。

阅读陌生工程也需要顺序。先看仓库、软件包和构建配置，确定边界；再沿消息或函数调用找到主数据流；随后选择模型定义、状态更新和协议接口等关键位置精读；最后用当前源码、配置和测试反查 README 中的描述。这三章会对三个项目各走一遍这套流程。README 仍然适合了解设计意图和寻找入口，但涉及版本、参数、状态下标或接口签名时，需要回到同一版本的原始文件核对。


读源码和复制源码是两件事。跟着本篇学设计和实现时，先沿主线往下读；真正准备把代码带进自己的项目时，再按目标仓库、文件和厂商 SDK 核对许可条款。后面只在需要处顺手标出这条边界，不让它打断代码主线。

=== 项目定位与版本范围

rm_vision 发布在 chenjunnn（Chen Jun）的个人账户下，README 将它定位为面向 RM 队伍的“规范、易用、鲁棒、高性能的视觉框架方案”。同一份 README 的“包含项目”还链接了自动瞄准、两套相机驱动、云台描述、串口驱动和仿真器。本章把 `rm_vision` 这个聚合仓库（umbrella repository，主要负责汇总入口并链接多个独立仓库）连同这六个链接都纳入范围，不根据宣传性形容词推断项目能力，而是检查各仓库实际提供了什么、哪些进入默认部署，以及它们怎样连接。

把它作为第一个阅读样本，理由很实际：模型集中定义，QoS、TF 和串口路径都能一路追到具体文件，正好适合练习从仓库入口走到运行链与关键算法。下面先固定版本和边界，后面再沿着这条路线往里读。

先固定本章依据的版本。截至 2026 年 7 月核对时，七个仓库的 `main` 分支分别是：`rm_vision` 的 `2ead8d0`（2024 年 11 月 8 日），`rm_auto_aim` 的 `f244d0e`（2023 年 5 月 19 日），MindVision 与 HikVision 驱动的 `7c0aab2`、`ebe1f1a`（均为 2023 年 5 月 17 日），`rm_gimbal_description` 与 `rm_serial_driver` 的 `0ccd8ce`、`794f4ec`（均为 2023 年 5 月 20 日），以及仿真器的 `e937f21`（2023 年 3 月 18 日）。这些短哈希不用背，它们只是保证后面的行号和结论都指向同一份代码。在本章固定的七个版本中，只有聚合仓库延续到 2024 年（当年删除了 README 中的推广信息）；其余六个仓库都停在 2023 年。长期未变化只说明阅读路径中的文件位置相对固定，不等于它们已经在近年的规则、硬件和依赖上得到验证。

`rm_auto_aim` 的 C++ 源文件和头文件合计 1948 行（不含测试）：识别部分 1067 行，跟踪部分 881 行。这个统计只描述所核对提交中的物理行数，不代表功能复杂度或代码质量；它说明的是主干规模可控，适合完整阅读，而不是只截取几个函数。

=== 仓库与软件包边界

#block(breakable: false)[
读陌生工程时，先区分仓库、ROS 软件包和可执行节点。`rm_vision` 自身主要包含 `rm_vision_bringup` 包及其 launch、参数文件，算法、硬件接口和仿真环境位于 README 链接的独立仓库。七个仓库的边界如下：

#show table: set text(size: 9pt)
#figure(
  table(
    columns: (1.4fr, auto, 2.6fr),
    align: (left, center, left),
    stroke: (x, y) => (
      top: if y == 0 or y == 1 { 1pt } else { 0pt },
      bottom: if y == 7 { 1pt } else { 0pt },
    ),
    inset: 5.5pt,
    table.header([*仓库*], [包数], [职责]),
    [`rm_vision`], [1], [`rm_vision_bringup`：launch、参数与默认硬件装配],
    [`rm_auto_aim`], [4], [识别、跟踪、消息接口，以及只汇总这些依赖的同名元包],
    [`ros2_mindvision_camera`], [1], [MindVision 取帧，发布 Image 与 CameraInfo],
    [`ros2_hik_camera`], [1], [HikVision 取帧，发布 Image 与 CameraInfo],
    [`rm_gimbal_description`], [1], [云台 URDF 与相机固定坐标链],
    [`rm_serial_driver`], [1], [串口收发、动态 TF、参数回写与复位请求],
    [`rm_vision_simulator`], [0], [独立 Unity 工程，发布合成图像、相机信息与关节状态],
  ),
  caption: [rm_vision README 所列项目的仓库-包映射。前六个 ROS 仓库合计包含 9 个 ament 包；仿真器是 Unity 项目，不是 ament 包。仓库名也不一定等于包名，例如 `rm_auto_aim` 一个仓库含四个包。],
)
]

README、Dockerfile 与 launch 回答的是三个不同问题：README 说明项目作者提供了哪些入口；Dockerfile 说明默认镜像实际取回哪些仓库；launch 才说明一次启动会装配哪些节点。所核对版本的 Dockerfile 克隆了聚合仓库、自动瞄准、两套相机驱动、云台描述和串口驱动，却没有克隆 Unity 仿真器。`vision_bringup.launch.py` 同时写出了 HikVision 和 MindVision 组件，但按 `launch_params.yaml` 的 `camera` 值二选一，默认值是 `hik`；选中的相机与识别器进入同一个组件容器。`no_hardware.launch.py` 只启动 `robot_state_publisher`、识别器和跟踪器，本身也不启动仿真器或其他图像源。因此，“README 提供了链接”不能直接改写成“默认部署已经接入”。

全景边界确定后，源码精读仍应有所取舍。相机驱动和仿真器先读到足以判断数据、时间戳、部署和故障边界；识别、跟踪与串口则沿主控制流深入。可以先认数据结构和识别流程，再进入滤波模型，最后查看与下位机的协议边界：

#figure(
  table(
    columns: (auto, 1fr, auto, 1.5fr),
    align: (center, left, center, left),
    stroke: (x, y) => (
      top: if y == 0 or y == 1 { 1pt } else { 0pt },
      bottom: if y == 7 { 1pt } else { 0pt },
    ),
    inset: 7pt,
    table.header([], [*文件*], [行数], [读它是为了]),
    [1], [`armor.hpp`], [73], [先认数据结构：`Light` 与 `Armor` 长什么样],
    [2], [`detector.cpp`], [245], [识别主干：二值化 $arrow.r$ 找灯条 $arrow.r$ 配对 $arrow.r$ 分类],
    [3], [`pnp_solver.cpp`], [58], [四点 PnP，项目中较短的一条完整计算链],
    [4], [EKF 头文件与实现], [74 + 51], [滤波引擎，*完全不含业务*],
    [5], [*`tracker_node.cpp` 第 26 至 113 行*], [*88*], [*状态、观测、雅可比与噪声模型集中定义处*],
    [6], [`tracker.cpp`], [239], [状态机、跳变处理、半径限幅],
    [7], [`packet.hpp`], [67], [从收发包字段检查上下位机的职责边界],
  ),
  caption: [rm_vision 主干阅读顺序。表中所列文件合计不到 900 行，覆盖识别、跟踪和通信的主要控制流；依赖配置、消息定义和异常路径仍需按问题补读。第 5 行集中定义了整车跟踪模型，后文会逐项核对。],
)

=== 数据流：默认硬件链与三条反向通道

#block(breakable: false)[
明确软件包边界后，接着检查默认硬件 launch 怎样连接节点。ROS 2 系统的主要运行关系可以归结为“谁发布什么、谁订阅什么、使用哪种 QoS”；下图汇总的是 `vision_bringup.launch.py` 装配的识别、跟踪和串口主流程，不包含需要另行启动的 Unity 仿真器。

#figure(
  image("images/proj-rmvision-dataflow.png", width: 100%),
  caption: [rm_vision 默认硬件链的节点接线图（脚本 `proj_rmvision_dataflow.py`）。绿色部分表示 launch 选中的相机组件与识别节点处于同一容器，并启用 ROS 2 进程内通信；这会绕开 DDS 序列化，但实际复制次数仍取决于发布方式和消息所有权。STM32 回传的 `ReceivePacket` 是姿态、敌方颜色、复位位和瞄准点的来源，串口节点再据此发布 TF、回写参数、调用服务并显示 marker。],
)
]

主要前向数据链包含四个传递阶段：被选中的 HikVision 或 MindVision 相机节点 $arrow.r$ `/image_raw` $arrow.r$ 识别节点 $arrow.r$ `/detector/armors` $arrow.r$ 跟踪节点 $arrow.r$ `/tracker/target` $arrow.r$ 串口节点 $arrow.r$ 下位机。调试信息、marker 和 TF 等辅助话题不属于这条目标数据链，但仍会影响观测与排障。

识别节点对图像的订阅，以及识别结果和跟踪目标的相应端点使用 `SensorDataQoS`（例如 `detector_node.cpp:39,90`、`tracker_node.cpp:152`）：best-effort（尽力传输）、keep-last（只保留最近若干条），默认深度为 5。相机发布端却不能一概而论：在聚合仓库的组件路径中，HikVision 驱动默认采用传感器数据配置，MindVision 驱动默认采用普通的 reliable（可靠传输）配置，因为聚合仓库没有覆盖各自的 `use_sensor_data_qos`。后者仍可向请求 best-effort 的订阅端提供数据，但丢包与重传行为不再相同。`/tracker/info` 与 marker 等调试发布器按深度 10 创建，也采用默认 reliable 配置。这里展示的是逐端点核对 QoS，而不是从一个订阅者反推整条链路。

绿色连接在 `vision_bringup.launch.py:24-45` 中装配：选中的相机组件与识别组件都设置 `use_intra_process_comms: True`。单独用 `ros2 run` 启动时，它们不再共享这个组件容器，通信路径也会变化。两套相机还共用 `/camera_node` 参数段，其中 `exposure_time` 对两者都有效，但现有 `gain: 8.0` 只匹配 HikVision 的 `gain`；MindVision 声明的是整数参数 `analog_gain`，不会自动把前者翻译过去。能在 launch 中替换组件，不代表参数模式和运行行为也已经统一。

三条反向通道：

- *`/tf` 广播*：串口节点依据下位机回传的 roll、pitch、yaw，广播 `odom` 到 `gimbal_link` 的动态变换（`rm_serial_driver.cpp:124-130`）；固定的 `gimbal_link` $arrow.r$ `camera_link` $arrow.r$ `camera_optical_frame` 来自 URDF。跟踪节点通过 `tf2::MessageFilter` 等待识别结果所带时间戳对应的变换可查询后再回调。这个机制能协调消息与 TF 缓存，却不能自动修正不同设备时钟、采样延迟或错误时间戳。
- *参数回写*：下位机在包里告诉视觉现在该打红还是打蓝，串口节点通过异步参数客户端尝试把 `detect_color` 写进识别节点（`rm_serial_driver.cpp:44,290-312`）。服务未就绪或前一个请求仍在进行时，这次更新可能被跳过，因此这条通道不是“每个数据包都完成一次参数写入”。
- *服务调用*：每收到一个通过校验的数据包，只要 `reset_tracker` 位为 1，串口节点就进入 `resetTracker()`（`rm_serial_driver.cpp:47,118-120,315-324`）；服务可用时异步请求 `/tracker/reset`，不可用时记录警告并跳过。服务端收到请求后把跟踪器强制切回 `LOST`。代码没有检测 0 到 1 的边沿，因此该位连续保持为 1 时会重复发送服务请求；上下位机需要约定单包脉冲或自行增加边沿检测。

图像与 `/tf` 的时间戳都需单独检查。两套相机驱动都是在 SDK 取帧并完成像素转换后调用 `this->now()`，没有使用 SDK 帧结构中已有的设备或采集时间字段；这个戳接近主机发布前的处理时刻，不是曝光时刻。`rm_serial_driver.cpp:124` 则使用“ROS 当前时刻 + 常数偏移”，部署参数为 `timestamp_offset: 0.006`；这里的当前时刻接近串口包通过校验并被处理的时刻，也不是下位机 IMU 的原始采样时刻。`tf2::MessageFilter` 能按消息中已有的戳等待变换，却不能把两个处理时刻还原成真实采样时刻。常数只能补偿相对稳定的平均偏移，不能描述排队抖动或时钟漂移。「时间戳对齐」一章给出了带源时间戳、统一时钟和缓冲插值等进一步方案，第三个项目也会展示四元数历史缓冲的做法。

最后看启动与故障顺序。`vision_bringup.launch.py:67-75` 让串口节点延迟 1.5 秒、跟踪节点延迟 2.0 秒启动。源码只给出定时值，没有记录选择依据；结合依赖关系，可以推测它是在给设备枚举和首批 TF 留时间。固定延时无法确认服务或数据已经就绪，较稳妥的方案是等待串口握手、参数服务和首个可查询 TF。

两套相机都在连续第 6 次取帧失败后调用全局 `rclcpp::shutdown()`。HikVision 会先在原句柄上停止并重新开始取流，MindVision 没有重连动作；两者都没有重新枚举并重建已经断开的设备。HikVision 在构造阶段找不到相机时会每秒重新枚举，MindVision 则直接从构造函数返回。由于相机和识别器共享组件进程，全局 shutdown 并不只影响相机节点；而构造函数早退也未必让容器立即退出。组件容器和串口节点设置了 `on_exit=Shutdown()`，跟踪节点与 `robot_state_publisher` 没有；README 的 Docker 命令虽带 `--restart always`，也只有在容器主进程确实退出后才会触发重启。因此，当前代码体现的是几条不同的失败路径，不能概括成“断线自动重连”或“任一节点退出都会整体自愈”。

=== 相机入口：接口相同，不等于实现等价

两套相机节点都以 `rgb8` 发布 Image，并各自发布 CameraInfo，所以识别节点可以共用同一组话题。不过，两个消息的 header 并不完全一致：两套驱动都把 Image 的 `frame_id` 设为 `camera_optical_frame`；HikVision 会把完整 Image header 复制给 CameraInfo，MindVision 却只复制时间戳，固定 YAML 也没有填写 header，因此它发布的 CameraInfo `frame_id` 仍为空。依赖 CameraInfo 坐标系的标定与 TF 消费者需要先补齐并检查这一字段。

接口对上了还不够，这里有个值得停下来看的缓冲区问题：两个驱动都只对 `image_msg_.data` 调用 `reserve()`，没有先 `resize()`。MindVision 随后让 SDK 写入尚不属于 vector 元素范围的 `data()`；HikVision 还把当时为 0 的 `size()` 当作输出缓冲区长度。两边都不检查转换结果，之后才 `resize()` 并发布。这个调用顺序违反了 C++ 容器的使用约定，应先修正再上机验证；至于现有 SDK 会把它表现成黑帧、旧帧还是其他故障，不能只靠读代码猜。

标定信息也不是“有 YAML 就完成了”。HikVision 自带配置写 640×480，聚合仓库的覆盖配置写 1440×1080；驱动读取相机当前宽高，却不设置分辨率，也不检查 Image 与 CameraInfo 的尺寸是否一致。两份配置可以分别对应不同相机模式，但部署时必须以实际模式重新核对。MindVision 同样没有用实际帧尺寸验证所加载的内参。颜色通道、分辨率与内参至少应使用已知色块和标定板做端到端检查。

现有自动化也覆盖不到这些问题：HikVision 仓库没有功能或硬件测试，MindVision 的持续集成流程（workflow）只构建并明确设置 `skip-tests: true`；后者的安装规则还没有把仓库内的 `libMVSDK.so` 装进安装目录（install tree）。两仓虽然都带了 x86-64 与 AArch64 版本的 SDK，也不能据此认定 ARM 实机已经跑通。接手这部分时，最小检查不是再读一遍 README，而是在干净安装目录启动节点，再用真实相机核对色块、分辨率、内参、时间戳和拔插后的行为。

=== 仿真器：提供合成输入，但不在默认运行链

进入算法前，再把仿真器放回运行链中看一眼。`rm_vision_simulator` 是 Unity 2021.3.11f1c1 工程，不是 ROS 2 ament 包。固定版本只有六个项目 C\# 脚本：它通过 Ros2ForUnity 发布 `/image_raw`、`/camera_info` 和 `/joint_states`；底盘由键盘直接改变刚体速度，云台由鼠标直接旋转 Transform，能量机关按固定转速和定时序列改变灯光。换句话说，它首先是一个合成图像源和可动场景，不是完整的车辆与下位机模拟器；代码没有订阅跟踪目标或云台命令，也没有串口、CAN、电机闭环和延迟模型。

它发布的 CameraInfo 也不能直接当作定量 PnP 的可靠内参。脚本用竖直视场角和图像宽度计算 `fx`，公式还额外乘了一次视场角，并简单令 `fy=fx`；消息没有填写 `width`、`height`、`R` 和 `P`。识别节点收到第一条 CameraInfo 后就固定使用其中的 `K`、`D` 创建 PnP 求解器，因此在把内参与 Unity 投影矩阵逐项对齐之前，仿真中的位姿尺度和轨迹只能用于流程调试，不能当作几何精度结果。

这里最容易产生的误解，是看到能量机关的 `BeenHit()` 就以为仿真器做了射击闭环。实际上，它只是定时协程调用的材质变色函数，不是命中检测；工程里也没有弹丸、弹道积分或解算、装甲板选择、开火判据与碰撞伤害。`RobotSpin.cs` 虽然定义了固定旋转，却没有被当前场景或预制体（Prefab）引用。因此，可以用它观察算法面对合成图像和人工运动时的输出，却不能拿它验证弹道、云台闭环或命中率。

仿真器 README 要求用户另行安装 Windows ROS 2 Humble 与 Ros2ForUnity 1.2.0，插件目录又没有进入仓库。聚合仓库的 Dockerfile 不克隆它，两份 launch 也不启动 Unity；`no_hardware.launch.py` 虽会启动 `robot_state_publisher`、识别器和跟踪器，却没有串口节点提供 `odom` 到云台的动态 TF。Unity 发布的 `yaw_joint`、`pitch_joint` 也对不上 URDF 中唯一的 floating `gimbal_joint`。所以，手工接上图像话题还不足以跑通跟踪：还要补齐 `odom` 到相机的 TF，或实现关节名与坐标系适配，否则跟踪器的 TF 消息过滤器不会放行识别结果。固定仓库没有给出这套一键编排，本章也没有在目标 Windows/Unity 环境中验证构建与联通。即使联通，结果仍只覆盖固定场景、材质和渲染相机，不能外推到真实相机噪声、曝光、畸变、USB 抖动或实车机构。

=== 识别链：基础篇那套四级级联，在这里长什么样

基础篇「C++ 语言基础」一章已经用*四级级联*介绍传统识别：预处理、找灯条、配对成板和数字分类。本节把那套教学流程对应到实际项目源码。基础篇使用的分类器模型就是 `rm_auto_aim/armor_detector/model/mlp.onnx`；它随 `rm_auto_aim` 仓库一同分发，仓库作者标为 Chen Jun，配套类别表是同目录下的 `label.txt`。模型文件本身没有单独记录训练者或训练过程，不能只凭仓库归属补出这些信息。

四级级联在这个仓库里的落点，逐级对上：

#[
#show table: set par(justify: false)
#figure(
  table(
    columns: (auto, auto, 1.6fr),
    align: (left, left, left),
    stroke: (x, y) => (
      top: if y == 0 or y == 1 { 1pt } else { 0pt },
      bottom: if y == 4 { 1pt } else { 0pt },
    ),
    inset: 7pt,
    table.header([*级*], [*位置*], [这个实现的特点]),
    [① 预处理], [`detector.cpp:42-51`], [转灰度加固定阈值 `binary_thres=80`，*不做颜色分离*],
    [② 找灯条], [`detector.cpp:53-115`], [`minAreaRect` 后按长宽比与倾角筛，颜色靠*轮廓内逐像素累加*],
    [③ 配对], [`detector.cpp:117-203`], [双重循环全配对，加 `containLight` 剔夹心],
    [④ 分类], [`number_classifier.cpp:41-145`], [透视拉正、大津法、$20 times 28$ 输入的 MLP，阈值 0.8],
  ),
  caption: [基础篇四级级联在 rm_vision 中的对应位置。`Detector::detect()` 按预处理、找灯条、配对、分类依次调用，主控制流集中在 `detector.cpp`（245 行）与 `number_classifier.cpp`（147 行）。参数、调试消息和分类器对象仍由节点及类成员提供，不能据此理解为没有外部状态。],
)
]

第①级在灰度图上使用固定阈值，不先做红蓝分离。项目 README 给出的理由是（`armor_detector/README.md:52`）：为了看清数字而设置曝光后，发光灯条中心可能饱和，R 与 B 通道在该区域接近，颜色二值化效果变差。因此，代码先按亮度找候选，再对轮廓内的 R、B 通道求和判色。这是该项目在其相机和曝光条件下采用的方案；换相机、曝光或灯条后，仍需用本队数据比较灰度与颜色预处理。

这个投票就在 `detector.cpp:74-87`：

```cpp
int sum_r = 0, sum_b = 0;
auto roi = rbg_img(rect);
// Iterate through the ROI
for (int i = 0; i < roi.rows; i++) {
  for (int j = 0; j < roi.cols; j++) {
    if (cv::pointPolygonTest(contour, cv::Point2f(j + rect.x, i + rect.y), false) >= 0) {
      // if point is inside contour
      sum_r += roi.at<cv::Vec3b>(i, j)[0];
      sum_b += roi.at<cv::Vec3b>(i, j)[2];
    }
  }
}
// Sum of red pixels > sum of blue pixels ?
light.color = sum_r > sum_b ? RED : BLUE;
```

#align(center)[#text(size: 9pt)[（摘自 rm_auto_aim `armor_detector/src/detector.cpp`，Copyright (c) 2022 ChenJun，MIT 许可证。）]]

这段实现遍历包围盒中的每个像素，并对每个点调用 `cv::pointPolygonTest`。若轮廓有 $N$ 个顶点、包围盒含 $A$ 个像素，判色部分的上界可写成 $O(A N)$；候选多或轮廓大时，它可能成为热点，但是否主导整帧耗时必须通过性能分析确认。可以比较两种替代实现：先用 `cv::drawContours` 生成掩膜再做通道求和，或在验证误判率后使用矩形近似。前者减少重复的点内判定，后者更快但可能混入背景和相邻灯条。应同时测耗时与判色准确率，而不是只凭复杂度决定替换。

这里 `[0]` 表示 R、`[2]` 表示 B，因为节点入口使用 `cv_bridge::toCvShare(img_msg, "rgb8")`（`detector_node.cpp:205`），而不是 OpenCV 常见的 BGR 排列。通道语义由消息编码和转换请求共同决定；修改相机驱动或 `cv_bridge` 调用后，应使用已知颜色图像做端到端检查，不能只看 `cv::Mat` 的类型。

第③级的 `containLight`（`detector.cpp:144-161`）用两根候选灯条的端点建立轴对齐包围盒；若第三根候选灯条的顶部、底部或中心落入盒内，就拒绝这一对。它主要抑制同一车辆多根灯条之间的跨越配对，代价是每个候选对再扫描一次灯条集合。该规则也可能因邻车灯条、反光或包围盒重叠而拒绝真装甲板，因此属于需要用场景数据验证的几何启发式，不是必然成立的物理约束。

第④级在分类后进行*类型一致性检查*（`number_classifier.cpp:135-142`）：几何判为大板时拒绝前哨站、2 号和哨兵类别；判为小板时拒绝英雄与基地类别。灯条间距和数字分类使用同一幅图像，误差并非统计独立，但两条路径利用了不同特征。规则能排除一部分明显矛盾，也会在几何类型或分类任一方出错时丢弃候选；收益与召回损失应通过混淆统计评估。

`detector.cpp:71` 在截取 ROI 前检查包围盒是否完全位于图像内，避免 `cv::Mat` 因越界触发断言。当前处理是直接跳过越界候选，而不是把矩形裁剪到图像范围；它提高了运行稳定性，但会降低画面边缘的召回。若需要保留部分可见灯条，应裁剪 ROI，并明确轮廓点与 ROI 像素分别使用全局还是局部坐标，再单独测试边界样本。

=== 模型集中处：`tracker_node.cpp` 第 26 至 113 行

这 88 行集中定义了状态转移、观测函数、两个雅可比以及 $bold(Q)$、$bold(R)$ 的更新方式。`ExtendedKalmanFilter` 类本身由 74 行头文件和 51 行实现组成，不引用 `Armor` 等业务类型；构造函数通过六个 `std::function` 接收运行中需要调用的模型函数，再直接接收只用于初始化的协方差 $bold(P)_0$。实现以 `P0.rows()` 确定状态维数，之后按注入的函数执行预测和更新。

这种结构将滤波递推与业务模型分开，便于替换模型和单独测试。不过，接口解耦不等于实现已经具备完整数值保护：该类仍显式求逆，并使用简化协方差更新，后文的复用建议会补充这些边界。

==== 过程函数与它的雅可比

```cpp
// xa = x_armor, xc = x_robot_center
// state: xc, v_xc, yc, v_yc, za, v_za, yaw, v_yaw, r
// measurement: xa, ya, za, yaw
// f - Process function
auto f = [this](const Eigen::VectorXd & x) {
  Eigen::VectorXd x_new = x;
  x_new(0) += x(1) * dt_;
  x_new(2) += x(3) * dt_;
  x_new(4) += x(5) * dt_;
  x_new(6) += x(7) * dt_;
  return x_new;
};
```

开头三行注释给出状态、观测和命名约定：`xa` 表示装甲板位置，`xc` 表示车体中心位置；九维状态按“位置、速度”成对交错排列，观测为四维。这也是应用篇九维整车模型所参照的具体实现。

函数体对四组状态执行“位置加上速度乘 $Delta t$”：车体中心的 $x$、$y$，当前装甲板高度 $z$，以及装甲板朝向 yaw。最后一组对应相邻预测间隔内角速度不变的假设。半径 $r$ 的预测均值保持不变；$bold(Q)$ 只增加这一维的不确定性，状态估计值要到后续观测更新时才可能改变。

雅可比矩阵（`:39-53`）是手写的 $9 times 9$ 常数矩阵，对角线全 1，四个 $dif t$ 分别落在 $(0,1)$、$(2,3)$、$(4,5)$、$(6,7)$ 这四个位置。它其实就是线性系统的 $bold(F)$——过程函数本身是线性的，这里用 EKF 只是为了复用同一套接口。理论篇「卡尔曼滤波」里那个 $mat(1, Delta t; 0, 1)$ 在这里沿对角线排了四份。

交错排列使 $bold(F)$ 呈现清晰的 $2 times 2$ 分块结构。README 中的状态顺序则把若干位置和速度分开排列；只要矩阵同步置换，两种顺序都能表示同一模型，但 README 与当前代码没有使用同一排列，后文会具体比较下标。

==== 观测函数与它的雅可比：逐项验一遍

```cpp
// h - Observation function
auto h = [](const Eigen::VectorXd & x) {
  Eigen::VectorXd z(4);
  double xc = x(0), yc = x(2), yaw = x(6), r = x(8);
  z(0) = xc - r * cos(yaw);  // xa
  z(1) = yc - r * sin(yaw);  // ya
  z(2) = x(4);               // za
  z(3) = x(6);               // yaw
  return z;
};
```

这四行把整车状态映射到当前装甲板观测。前两行为非线性几何关系：

$ x_a = x_c - r cos theta, quad y_a = y_c - r sin theta $

后两行直接取装甲板高度和朝向。车体中心、线速度和角速度不在单帧观测向量中，只能借助时间序列与模型耦合间接估计。是否可观以及估计精度如何，还取决于目标运动、可见装甲板切换、噪声和初值；写出状态并不自动保证每一维都能稳定辨识。

雅可比适合逐项核对（`:65-76`）：

```cpp
Eigen::MatrixXd h(4, 9);
double yaw = x(6), r = x(8);
//    xc   v_xc yc   v_yc za   v_za yaw         v_yaw r
h <<  1,   0,   0,   0,   0,   0,   r*sin(yaw), 0,   -cos(yaw),
      0,   0,   1,   0,   0,   0,   -r*cos(yaw),0,   -sin(yaw),
      0,   0,   0,   0,   1,   0,   0,          0,   0,
      0,   0,   0,   0,   0,   0,   1,          0,   0;
```

第一行满足 $partial x_a \/ partial x_c = 1$、$partial x_a \/ partial theta = r sin theta$、$partial x_a \/ partial r = -cos theta$，分别位于第 0、6、8 列。第二行对应 $partial y_a \/ partial y_c = 1$、$partial y_a \/ partial theta = -r cos theta$、$partial y_a \/ partial r = -sin theta$；后两行是恒等映射。当前矩阵与上述函数一致。

矩阵上方的列注释把每一列与状态分量对齐，能降低手写错位的概率。更进一步，可以用有限差分或自动微分在随机状态上比较解析雅可比；角度归一化和半径限幅位于这段观测函数之外，应另做接缝与边界测试。代码能通过编译并不能发现列语义错误。

==== 过程噪声：交叉项使用了另一组参数

$bold(Q)$ 在 `:81-100` 构造。对于一步内近似为同一随机加速度的“位置-速度”对，常见离散块为

$ sigma^2 mat(t^4\/4, t^3\/2; t^3\/2, t^2) $

三个参数 `sigma2_q_xyz`、`sigma2_q_yaw`、`sigma2_q_r` 分别控制平移、角度与半径方向的过程噪声量级。

`:85` 这一行：

```cpp
double q_y_y = pow(t, 4) / 4 * y, q_y_vy = pow(t, 3) / 2 * x, q_vy_vy = pow(t, 2) * y;
```

这里的局部变量 `x` 是 `s2qxyz_`，`y` 是 `s2qyaw_`；代码正在构造 yaw 块，却让交叉项 `q_y_vy` 乘了 `x`。若按同一角加速度样本推导，三项都应乘 `y`。当前块的行列式为

$ frac(t^6, 4) (y^2 - x^2) $

因此它不再是预期的秩一块，也并非对任意参数都保持半正定。仓库默认值 $(x,y)=(20,100)$ 和部署值 $(0.05,5)$ 都满足 $y > x$，对应块仍为正定；若用户把平移噪声调到大于角度噪声，则可能得到负行列式。这个结论只说明矩阵结构与参数约束，不足以判断它对某段实车数据造成了多大误差。修复时应把交叉项改用 `y`，并为 $bold(Q)$ 增加对称性与特征值检查。语义化命名如 `s2_xyz`、`s2_yaw` 也能降低这类混用风险。

==== 量测噪声：按坐标分量缩放

```cpp
// update_R - measurement noise covariance matrix
r_xyz_factor = declare_parameter("ekf.r_xyz_factor", 0.05);
r_yaw = declare_parameter("ekf.r_yaw", 0.02);
auto u_r = [this](const Eigen::VectorXd & z) {
  Eigen::DiagonalMatrix<double, 4> r;
  double x = r_xyz_factor;
  r.diagonal() << abs(x * z[0]), abs(x * z[1]), abs(x * z[2]), r_yaw;
  return r;
};
```

这四行让前三个对角元素随观测变化：$sigma_x^2 = f |x_a|$、$sigma_y^2 = f |y_a|$、$sigma_z^2 = f |z_a|$。注意写入 $bold(R)$ 的是*方差*；若坐标使用米，参数 $f$ 还必须带有使结果成为平方米的单位。代码没有记录这项量纲。

这个模型既不是按目标距离统一缩放，也不是从 PnP 雅可比传播得到的观测协方差。它把 odom 三个坐标分量分别当作噪声尺度，因此协方差主轴固定在 odom 轴上，并会在任一坐标分量为零时把对应方差降为零。单目位姿误差通常随距离、姿态、像素几何和标定共同变化，深度方向往往比横向更不确定；较完整的做法是在相机系中估计各向异性协方差，再按相机到 odom 的旋转传播。若暂时只用 $f ||bold(z)||$ 给三个位置轴统一缩放，虽然可以消除零方差和开机朝向依赖，却仍是各向同性近似，不能称为完整的 PnP 噪声模型。

#figure(
  image("images/proj-rmvision-r-scaling.png", width: 100%),
  caption: [按坐标分量缩放的结果（脚本 `proj_rmvision_r_scaling.py`）。目标沿三维距离恒定为 4 m、且高度固定的圆弧移动；左图把实现中的 $x$-$y$ 协方差椭圆放大 20 倍，品红线仅用于标出视线方向，并不代表一份已经标定的“正确协方差”。椭圆主轴始终与 odom 轴平行，且在 $y_a=0$ 处退化。右图给出同一现象：距离不变时，$sigma_x$ 约从 32.5 mm 变到 40.0 mm，$sigma_y$ 从 34.6 mm 降到 0。数值使用部署参数 `r_xyz_factor = 4e-4`；图只复现代码公式，不测量真实 PnP 误差。],
)

$x_a,y_a,z_a$ 是 `target_frame_` 中的分量；部署配置把该坐标系设为 odom。项目 README 将 odom 描述为以云台中心为原点、以 IMU 上电时 yaw 朝向为 $x$ 轴的惯性系。串口节点根据下位机姿态广播 `odom` $arrow.r$ `gimbal_link`，所以 $y_a approx 0$ 表示目标接近这条固定的 odom $x$ 轴，不等于目标正对当前枪口。改变上电朝向会改变同一物理目标在 odom 中的分量，也会改变这套 $bold(R)$。

$R_(y y)=0$ 并不会单独令卡尔曼增益无穷大，因为新息协方差还含 $bold(H) bold(P) bold(H)^top$；但它表示模型没有给该方向保留测量噪声下限，会让更新权重依赖预测协方差和其他耦合项。其实际影响需要用记录数据重放、NIS 等统计量或对照实验判断，不能从公式形状直接断言“没有造成问题”。最低限度应设置正方差下限；更好的方案是标定相机系观测协方差并旋转到 odom 系。

源码默认值与本仓库 launch 加载的配置差别很大：`r_xyz_factor` 是 0.05 对 `4e-4`，`sigma2_q_xyz` 是 20.0 对 0.05，`max_match_distance` 是 0.15 对 0.5，`lost_time_thres` 是 0.3 s 对 1.0 s。`declare_parameter` 的默认值在没有参数覆盖时会生效，并非无用占位；只是按本仓库的 `vision_bringup.launch.py` 启动时，`node_params.yaml` 会覆盖它们。复现实验时应记录启动命令与最终参数转储，不能只摘源码默认值或只摘 YAML。

#align(center)[#text(size: 9pt)[（本节五段代码摘自 rm_auto_aim `armor_tracker/src/tracker_node.cpp`，Copyright (c) 2022 ChenJun，MIT 许可证；为排版做过换行调整。）]]

=== 装甲板切换与半径限幅

应用篇已经解释过自旋目标的换板与半径限幅，本节只对照当前实现补充状态如何保存和复位。

`handleArmorJump` 位于 `tracker.cpp:184-214`。代码先记录高度差 `dz`，再把当前高度替换为新装甲板高度，并执行 `std::swap(target_state(8), another_r)`。九维状态只保存当前一组半径，另一组存放在滤波器外的 `another_r` 中；换板时两者交换。这样不增加滤波状态维数，但非当前半径在暂存期间不会获得新的滤波更新。后文的 sp_vision 则把两组几何差异放入更高维状态。两种选择分别强调模型简洁和统一估计，优劣取决于可观测性、切换频率和数据质量。

该交换只在 `tracked_armors_num == NORMAL_4` 时执行；平衡步兵和前哨站走其他分支。车型假设因而体现在明确条件中，但车型识别错误仍会把目标送入错误模型，需要结合类别稳定性检查。

换板后，若状态推算的装甲板位置与当前测量相差超过 `max_match_distance`，`:197-211` 会重新计算中心位置，并把三个线速度置零。源码日志把它称为 `Reset State!`，注释将条件解释为 EKF 发散；但同样的残差也可能来自错误关联、外参、姿态或车型假设，因此复位是保护动作，不是根因诊断。在线系统需要明确复位路径，同时记录触发前后的观测与状态，才能区分这些原因。

半径在 `tracker.cpp:114-121` 被限制到 $0.12 tilde.op 0.4$ m，初始值为 0.26 m，恰好位于区间中点。这个限幅阻止状态离开预设物理范围，却也会在边界处截断估计分布；若半径频繁触边，应先检查车型、关联和噪声，而不是把夹紧后的值当作可信估计。另一个文档细节是：`:162` 的注释写“初始位置在目标后方 0.2 m”，实际代码使用 0.26 m。

=== 接口边界：向下位机发送整车状态

发送包结构（`packet.hpp:28-47`）直接显示了上位机与下位机的职责划分：

```cpp
struct SendPacket
{
  uint8_t header = 0xA5;
  bool tracking : 1;
  uint8_t id : 3;          // 0-outpost 6-guard 7-base
  uint8_t armors_num : 3;  // 2-balance 3-outpost 4-normal
  uint8_t reserved : 1;
  float x; float y; float z; float yaw;
  float vx; float vy; float vz; float v_yaw;
  float r1; float r2; float dz;
  uint16_t checksum = 0;
} __attribute__((packed));
```

#align(center)[#text(size: 9pt)[（摘自 rm_serial_driver，Copyright (c) 2022 ChenJun，Apache-2.0 许可证；原文每个 `float` 单独一行，此处为排版合并。）]]

包内没有瞄准角，而是发送位置、朝向、四个速度、两组半径和高度差。在本章固定的七个仓库中，没有找到弹道解算、装甲板选择或开火判据与动作：两套相机只发布图像和内参，`rm_auto_aim` 输出整车状态，仿真器也只提供合成传感数据。因而，可以确认这些职责不在这七个公开仓库内；源码没有进一步说明它们究竟全部位于下位机，还是还有未公开、未链接的模块，不能替项目补出一个确定答案。

这条边界并不等于视觉侧完全没有反馈。接收包包含下位机 roll、pitch、yaw 和 `aim_x/aim_y/aim_z`，串口节点会广播姿态并发布瞄准点 marker；这与下位机回传某个瞄准位置的解释相符，却仍看不出该位置怎样计算，也不能证明弹道和开火全部由同一端完成。当前协议没有明确的发射事件、弹丸编号、命中结果或各字段的源时间戳，瞄准点也不等同于枪管实际跟随误差。若要区分状态估计、弹道、控制和发射机构问题，需要在协议中增加可关联的时间与事件信息，并联合记录上下位机日志。

在本章核对的 x86-64、GCC 13.3、C++14 编译环境中，`sizeof(SendPacket)` 为 48 B，`sizeof(ReceivePacket)` 为 28 B，两者对齐均为 1 B。发送包的 48 B 可分解为包头与位域各 1 B、11 个 `float` 共 44 B、CRC 2 B。不过，C++ 位域布局、字节序和 `float` 表示具有实现相关性；这次结果只验证了所述环境，部署前仍应在通信两端用静态断言和预先确认的标准字节序列检查布局，不能把一次 `sizeof` 结果外推到所有编译器与 MCU。

配置写的是 115200 bit/s、8N1。若设备后端确实按这一速率走异步串行线路，每个字节在线路上占 10 bit；再假设两个方向都以 200 Hz 传输，发送方向需要 $48 times 10 times 200 = 96000$ bit/s，占 83.3%，接收方向需要 $28 times 10 times 200 = 56000$ bit/s，占 48.6%。标准全双工 UART 的 TX 与 RX 是两条独立线路，所以不能把两项相加成 132%；每个方向应分别与 115200 bit/s 比较。200 Hz 只是用于估算的条件，不是仓库中测得或固定的频率；而配置中的 `/dev/ttyACM0` 通常对应 USB CDC ACM，名义波特率也未必限定 USB 链路的实际吞吐。部署时应先确认设备后端和实际发包频率，再判断 83.3% 是否是有效预算。即使两个方向不争用同一根 UART 数据线，它们仍可能共享 USB 传输、串口设备与处理线程等资源。

后两章的项目把边界放在其他位置：rm.cv.fans 在视觉侧完成更多弹道与角度计算，sp_vision 还下发角速度、角加速度和开火位。比较这些方案时，应关注可观测反馈、时延口径、协议带宽和团队维护接口，而不是把某一种分工视为固定答案。

=== 文档与当前实现不一致时怎么核对

`armor_tracker/README.md` 保留了不同阶段的设计描述，可以用来练习如何识别文档漂移。下面比较的是 README 与提交 `f244d0e` 的源码；换版本后，行号和结论都要重新核对。

先看事实。三个来源对同一个滤波器的描述：

#figure(
  table(
    columns: (auto, auto, auto, 1fr),
    align: (left, center, center, left),
    stroke: (x, y) => (
      top: if y == 0 or y == 1 { 1pt } else { 0pt },
      bottom: if y == 3 { 1pt } else { 0pt },
    ),
    inset: 7pt,
    table.header([*来源*], [状态维数], [观测维数], [运动模型]),
    [README 散文段（`:60-62`）], [*6*], [*3*（仅位置）], [惯性系中的匀速直线运动],
    [README 公式（`:30`）], [*9*], [未提], [未描述，只给了状态向量],
    [*代码（`tracker_node.cpp:27-28`）*], [*9*], [*4*（含 yaw）], [中心平动 + 整车绕中心匀速自转],
  ),
  caption: [同一滤波器在 README 与当前源码中的三种描述。README 的散文段仍是六维匀速模型，公式虽写九维，分量顺序也与源码不同。表格说明具体不一致，不推断这些段落各自对应哪个未保留的历史提交。],
)

第一处差异是维数。README 散文段描述六维匀速状态和三维位置观测，而当前代码使用九维整车状态和包含 yaw 的四维观测。若调用接口同时检查向量尺寸，这类不一致较容易暴露；若仅在其他位置按旧语义读取一个仍然合法的下标，则不一定立即报错。

第二处差异是九维状态的分量顺序。文档把若干位置、yaw、速度和半径依次排列；代码则让位置与速度交错成对。把两者按下标对齐如下：

#block(breakable: false)[
```text
index     0      1      2      3      4      5      6      7      8
README    x_c    y_c    z      yaw    v_xc   v_yc   v_z    v_yaw  r
code      xc     v_xc   yc     v_yc   za     v_za   yaw    v_yaw  r
same?     yes    NO     NO     NO     NO     NO     NO     yes    yes
```
]

九个位置中只有 0、7、8 的语义一致，其余六个不同。例如 README 中 `x(1)` 是 $y_c$，代码中却是 $v_(x c)$；两者维数相同，因此访问不会越界。只抽查碰巧一致的 `x(0)` 或 `x(8)` 也无法发现问题。状态向量应有唯一的类型或索引定义，日志和消息转换最好引用同一组常量，并用已知状态测试每个分量，而不是在多个文件中重复手写顺序。

第三处差异是参数名称和单位。README `:22-23` 写 `tracking_threshold`、`lost_threshold`；代码声明的是 `tracker.tracking_thres` 与 `tracker.lost_time_thres`。后者单位为秒，运行时再以 `lost_time_thres / dt_` 得到帧数门限（`tracker_node.cpp:223`）。README 还没有列出 `max_match_yaw_diff`。把旧名称写入参数文件不会配置当前成员；具体是忽略、警告还是拒绝，取决于 ROS 2 版本、NodeOptions 和启动方式，因此部署检查应读取节点最终声明与实际取值。

`rm_auto_aim` 根 README 的构建和测试命令使用 `--packages-up-to auto_aim_bringup`，包列表也写了这个名称；当前仓库实际包含 `armor_detector`、`armor_tracker`、`auto_aim_interfaces` 和 `rm_auto_aim`，没有 `auto_aim_bringup`。在所核对版本中，照抄该选择器无法得到目标包。

README `:27-28` 的几何式 $x_c = x_a + r cos theta$、$y_c = y_a + r sin theta$ 与当前观测函数仍然一致。也就是说，这份文档不是整体失效，而是不同段落与当前代码的一致程度不同。只凭发现一处错误而放弃全部文档，会丢失仍有用的设计意图；只凭一处正确而信任所有数值，同样不可靠。

可以把核对规则归纳为：

#definition[
文档用于理解设计意图和寻找入口；实现行为则要由*同一提交*中的源码、配置、构建选项和运行记录共同确认。涉及数值、维数、下标、参数名和接口签名时，至少追到实际定义与调用处；代码与配置也可能有缺陷，运行测试只能证明所覆盖的路径。
]

README 与代码位于不同文件，编译器不会自动检查两者一致。降低漂移的方法不只是提醒维护者“记得更新”：可以从唯一的状态定义生成接口文档，在持续集成（CI）中为 README 命令加入只检查关键命令能否启动并完成最基本操作的测试，对配置模式做校验，并让示例引用可执行测试。这类测试常称为“冒烟测试”；它只能及时暴露命令已经无法走通，不会自动验证算法结果。源码附近的状态列注释在当前版本仍然准确，说明贴近定义的信息更容易随修改一起被看到；但它仍应由测试验证，而不是因为位置近就自动可信。

=== 接手这个项目，先查哪些地方

如果准备把 rm_vision 当作新项目起点，先别急着换检测器或调滤波参数。下面四项会更早决定它能不能稳定跑起来：

- *先锁定版本，再补构建说明*。除聚合仓库后来只改过 README 外，自动瞄准、两套相机、云台描述、串口和仿真器的固定 HEAD 都停在 2023 年 3 月至 5 月；主 README 的 Docker 部署与源码编译两节又以 `TBD` 结束。相关说明主要面向 Ubuntu 22.04、ROS 2 Humble，仿真器则要求 Windows ROS 2 Humble 与指定 Unity 版本。接手后应先固定一组已知提交，再在目标系统上重跑构建和硬件检查。
- *把 Dockerfile 与包依赖对齐*。Dockerfile 对六个 ROS 仓库执行 `git clone --depth=1`，没有锁定提交；`rm_vision_bringup/package.xml` 又只声明 `rm_auto_aim` 与 `rm_serial_driver`，漏掉两套相机和云台描述，`rm_auto_aim` README 还引用了不存在的包名。当前镜像能找到这些组件，依赖的是 Dockerfile 手工克隆，而不是完整的包元数据。
- *逐仓库看测试到底覆盖什么*。`rm_auto_aim` 的 workflow 会构建并运行 `colcon test`，但分类器基准测试没有断言，节点测试只检查构造不崩溃，跟踪包只有 lint；MindVision workflow 明确跳过测试，HikVision 与仿真器也没有当前版本中的功能或硬件 CI。先把这些边界分清，再补相机取流、TF、跟踪和 Unity 联通测试。
- *沿 TF 发布者核对频率*。launch 虽为 `robot_state_publisher` 设置 `publish_frequency: 1000.0`，当前相机关节却是 fixed，`odom` $arrow.r$ `gimbal_link` 则是 floating，并由串口节点另行广播。这个参数不会把动态云台 TF 变成 1 kHz；要看真实更新率，仍得找到对应变换的发布者和数据源。

作为阅读样本，rm_vision 的优点依然很鲜明：算法主干不大，模型集中定义，QoS、TF 和串口路径都能追到具体文件；README、Docker、launch 和包元数据之间的差异，也正好让我们练习怎样交叉核对真实工程。若要直接拿来上车，就按前面的顺序先修相机缓冲与 CameraInfo、补齐依赖和 TF，再做硬件、时间同步与故障恢复测试。

可以分三类处理。*值得学习的结构*包括：用函数注入模型、在一处列出状态和雅可比、按数据用途配置 QoS，以及把车型条件写成显式分支。*需要测量后再采用的启发式*包括 `containLight`、颜色投票、半径限幅、类型一致性检查、处理时刻打戳和仿真场景。*不宜原样复制的实现*包括显式矩阵求逆、简化协方差更新、过程噪声交叉项、按 odom 分量设置 $bold(R)$、相机缓冲区与 CameraInfo 的当前处理、固定延时启动、未锁定版本的 Docker 构建和实现相关的打包位域。README 应先读以了解入口，再逐项回源码、配置、构建和测试核对，而不是完全跳过。

==== 本章小结

本章从 README 所列的七个仓库开始，区分了 9 个 ament 包与一个独立 Unity 工程，又分别核对 README 入口、Docker 克隆范围和 launch 实际装配。默认硬件链仍是一条前向链与三类反向连接；两套相机由 launch 二选一，仿真器需要用户在外部另行启动。算法主干阅读路线不到 900 行，但完整复现还要补读消息、驱动、launch、参数、SDK 和协议。

`tracker_node.cpp:26-113` 展示了模型与滤波递推分离的结构，也暴露了必须由交叉检查发现的细节：过程噪声交叉项混用了参数，测量噪声按 odom 坐标分量缩放，README 的状态顺序和参数名又与当前源码不同。两套相机的接口相似，QoS、增益参数、故障路径和 SDK 部署却不同；仿真器能提供合成图像，也没有进入默认部署，更不包含弹道与开火。发送包同样不含瞄准角，所以本章只能确认弹道、选板和开火不在固定的七个公开仓库内，不能凭空指定它们位于哪一端。这个例子给出的阅读方法不是“代码永远正确”，而是把同一版本的文档、源码、配置、构建、测试和运行接口互相校对。

下一章分析 rm.cv.fans。它同样处理 PnP、预测和弹道，但在姿态优化、延迟拆分和发射反馈上采用了不同边界；对照这些差异，可以继续练习如何从项目目标和证据范围理解设计选择。
