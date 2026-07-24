
=== ROS 与 ROS 2：架构与基本概念
// 机器人软件为什么需要中间件
// - ROS 的定位与价值
// - ROS 1 与 ROS 2 的关系
// - 节点、话题、服务、动作、参数
// - 包、工作空间、构建系统
// - RoboMaster 开发中的典型模块划分
// === ROS 与 ROS 2：架构与基本概念

机器人软件通常由多个需要并行工作的模块组成：相机持续产生图像，检测器进行视觉推理，跟踪器融合时序信息，决策模块生成控制指令，通信模块与下位机交换数据。如果这些职责没有清晰接口，修改一个模块就可能影响其他模块，测试、复用和多人协作都会变得困难。是否放在同一个进程则是另一项设计选择，还要考虑通信开销、故障隔离和部署方式。

ROS（Robot Operating System）并不是操作系统内核，而是一套机器人中间件与开发工具。它用节点（node）表示具有明确职责的逻辑单元，并提供通信、构建、启动和诊断机制。清晰的节点接口有助于模块独立开发和测试；ROS 2 也允许多个节点通过组件机制运行在同一进程中，以减少通信开销。

==== ROS 1 与 ROS 2：该如何理解

如果你在网上搜索教程，会同时看到 ROS 1 和 ROS 2。可以把它们理解为同一生态的两代架构：

- ROS 1：资料和既有软件包较多，常见通信依赖 ROS Master 与 TCPROS/UDPROS；其核心接口没有 ROS 2 提供的统一 QoS、安全配置和基于 DDS 的分布式发现能力。
- ROS 2：通常基于 DDS 实现节点发现与通信，并在接口中提供 QoS、安全扩展和生命周期节点等能力。

对于新项目，通常优先考虑 ROS 2，并根据目标操作系统、支持周期和所需软件包选择仍受维护的发行版。前面的 CMake 章节已经介绍 `ament_cmake` 和 `colcon build`，这套流程是 ROS 2 工程的基础。

==== ROS 2 的基本对象

理解下面几个概念，就能识别大多数 ROS 2 工程的主要结构：

- `node`：参与 ROS 图的逻辑功能单元，如 `detector_node`、`tracker_node`；一个进程可以包含一个或多个节点。
- `topic`：发布/订阅通道，适合持续数据流，如图像、目标列表。
- `service`：请求/响应模式，适合能较快返回的操作，如“重置跟踪器”；客户端既可以同步等待，也可以异步处理结果。
- `action`：可反馈、可取消的长任务，适合“导航到目标点”这类过程。
- `parameter`：节点运行参数，如阈值、模型路径、串口端口号。

把它映射到 RoboMaster 会更直观：

- 相机节点发布 `Image` 话题。
- 识别节点订阅图像，发布装甲板候选。
- 决策节点订阅目标，输出云台控制命令。
- 维护节点提供服务用于在线重置状态。

==== 节点、进程与执行器

节点并不等同于进程或线程。一个进程可以包含多个节点，一个节点也可以拥有订阅、定时器、服务等多种回调。执行器（executor）负责等待这些回调就绪并安排它们执行；如果回调中长时间阻塞，同一执行器中的其他回调就可能延迟。

后面的 `rclcpp::spin(node)` 是便捷写法，默认使用单线程执行器。需要让多个回调并行时，可以显式使用 `MultiThreadedExecutor`，但仅更换执行器并不保证吞吐量提高：回调组会限制哪些回调可以同时运行，共享状态也必须正确同步。设计节点边界时，应把“通信接口怎样划分”与“回调在哪些线程执行”分开考虑，并在目标负载下测量延迟。

==== 包与工作空间

ROS 2 项目组织有两层：

- 包（package）：最小构建和发布单元。
- 工作空间（workspace）：多个包的集合。

常见工作空间结构：

```text
ros2_ws/
  src/
    rm_interfaces/
    rm_detector/
    rm_tracker/
    rm_decision/
  build/
  install/
  log/
```

开发时你主要操作 `src/`，其余目录是构建产物。


=== 话题、服务、动作
// 三种通信模型的分工
// - Topic：持续流数据
// - Service：同步请求响应
// - Action：可反馈的长任务
// - QoS 基础
// - 常用命令行排查
// === 话题、服务、动作

Topic、service 和 action 都用于节点通信，但交互方式不同。选择时应先判断数据是连续产生、一次请求即可完成，还是需要持续反馈和取消能力。

==== Topic：持续数据的发布与订阅

话题采用发布/订阅模型，通信双方通过话题名称、消息类型和 QoS 匹配，而不必直接指定某个对端。它适合持续产生的数据：

- 相机帧
- IMU 数据
- 目标检测结果
- 控制状态广播

常用排查命令：

```bash
ros2 topic list
ros2 topic info /detector/targets
ros2 topic echo /detector/targets
ros2 topic hz /detector/targets
```

`ros2 topic hz` 会统计当前订阅端实际收到消息的频率，可以用来发现频率异常。它不能单独判断消息是在发布前、传输中还是订阅端丢失，也会受到 QoS、网络和执行该命令的机器负载影响，需要结合节点日志与时间戳继续定位。

==== QoS：消息传输策略

ROS 2 的 QoS（Quality of Service）决定消息传输策略。最常见的几项包括：

- `reliability`: `reliable` / `best_effort`
- `history`: `keep_last` / `keep_all`
- `depth`: 使用 `keep_last` 时保留的样本数
- `durability`: `volatile` / `transient_local`，决定是否由发布端为后加入的订阅者保留历史

高频传感器数据常根据“允许丢失旧消息、优先处理最新数据”的需求选择 `best_effort + keep_last`；要求尽量送达的数据可考虑 `reliable`，但还要评估重传、队列堆积和延迟。发布者提供的 QoS 与订阅者请求的 QoS 不兼容时，双方端点都可能存在，却无法传递消息。

==== Service：短时的一次性操作

服务采用一次请求对应一次响应的模型，调用方式与函数相似，但请求会经过 ROS 通信，客户端也可以异步等待。典型场景包括：

- 重置滤波器状态
- 切换工作模式
- 读取一次当前标定结果

常用命令：

```bash
ros2 service list
ros2 service type /tracker/reset
ros2 service call /tracker/reset std_srvs/srv/Trigger "{}"
```

服务通常不用于持续的高频数据流。若用 60 Hz service 传输周期数据，客户端必须管理大量请求和响应，超时或处理变慢时也更容易积压；这类数据一般更适合 topic。

==== Action：有进度反馈、可取消的长任务

动作用于持续执行且需要反馈的任务，例如：

- 导航到某目标点
- 云台执行扫描策略
- 自动标定流程

常用命令：

```bash
ros2 action list
ros2 action info /auto_aim_task
```

可以先用以下规则判断：

- 请求能较快完成并返回一次结果，用 `service`。
- 连续数据流，用 `topic`。
- 执行时间较长且需要进度或取消控制，用 `action`。


=== 创建节点与发布订阅
// 从 0 到 1 跑通一个 ROS 2 包
// - 工作空间初始化
// - 创建 ament_cmake 包
// - 编写 publisher/subscriber 节点
// - colcon 构建与运行
// === 创建节点与发布订阅

下面按步骤搭建一个最小示例，验证从发布节点到订阅节点的通信过程。

==== 创建工作空间与包

以下命令以 Ubuntu 22.04 常用的 ROS 2 Humble 为例。其他发行版应把路径中的 `humble` 改为实际名称；如果没有先加载基础环境，`ros2` 和 `colcon` 可能无法找到：

```bash
source /opt/ros/humble/setup.bash
```

```bash
# 1) 准备工作空间
mkdir -p ~/ros2_ws/src
cd ~/ros2_ws/src

# 2) 创建示例包
ros2 pkg create rm_vision_demo --build-type ament_cmake --dependencies rclcpp geometry_msgs

# 3) 回到工作空间根目录并构建
cd ~/ros2_ws
colcon build --symlink-install

# 4) 加载环境
source install/setup.bash
```

确认工作空间能够正常构建后，可以在 `~/.bashrc` 中加载 ROS 2 环境；是否自动加载具体工作空间，应根据日常使用方式决定，并按实际发行版调整路径：

```bash
source /opt/ros/humble/setup.bash
source ~/ros2_ws/install/setup.bash
```

同时使用多个工作空间时，自动加载固定工作空间可能掩盖当前终端的环境来源。遇到软件包版本或覆盖顺序问题，应新开终端并只按需要执行相应的 `source` 命令。

==== 示例：目标发布节点（publisher）

`target_publisher.cpp`：周期发布一个简化目标点。

```cpp
#include <chrono>
#include <memory>

#include <geometry_msgs/msg/point.hpp>
#include <rclcpp/rclcpp.hpp>

using namespace std::chrono_literals;

class TargetPublisher final : public rclcpp::Node {
public:
  TargetPublisher() : Node("target_publisher"), x_(0.0) {
    pub_ = create_publisher<geometry_msgs::msg::Point>("detector/target", 10);
    timer_ = create_wall_timer(50ms, [this]() { Publish(); });
  }

private:
  void Publish() {
    geometry_msgs::msg::Point msg;
    msg.x = x_;
    msg.y = 0.2;
    msg.z = 5.0;
    x_ += 0.01;

    pub_->publish(msg);
    RCLCPP_INFO_THROTTLE(get_logger(), *get_clock(), 1000,
                         "publish target x=%.3f", msg.x);
  }

  double x_;
  rclcpp::Publisher<geometry_msgs::msg::Point>::SharedPtr pub_;
  rclcpp::TimerBase::SharedPtr timer_;
};

int main(int argc, char* argv[]) {
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<TargetPublisher>());
  rclcpp::shutdown();
  return 0;
}
```

==== 示例：决策订阅节点（subscriber）

`decision_subscriber.cpp`：接收目标点并输出示例范围判断。

```cpp
#include <memory>

#include <geometry_msgs/msg/point.hpp>
#include <rclcpp/rclcpp.hpp>

class DecisionSubscriber final : public rclcpp::Node {
public:
  DecisionSubscriber() : Node("decision_subscriber") {
    sub_ = create_subscription<geometry_msgs::msg::Point>(
        "detector/target", 10,
        [this](const geometry_msgs::msg::Point::SharedPtr msg) {
          const bool inside_demo_range = msg->z < 8.0;
          RCLCPP_INFO(get_logger(),
                      "recv target x=%.3f y=%.3f z=%.3f => %s",
                      msg->x, msg->y, msg->z,
                      inside_demo_range ? "inside_demo_range"
                                        : "outside_demo_range");
        });
  }

private:
  rclcpp::Subscription<geometry_msgs::msg::Point>::SharedPtr sub_;
};

int main(int argc, char* argv[]) {
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<DecisionSubscriber>());
  rclcpp::shutdown();
  return 0;
}
```

在 `CMakeLists.txt` 中注册两个可执行文件并安装：

```cmake
add_executable(target_publisher src/target_publisher.cpp)
ament_target_dependencies(target_publisher rclcpp geometry_msgs)

add_executable(decision_subscriber src/decision_subscriber.cpp)
ament_target_dependencies(decision_subscriber rclcpp geometry_msgs)

install(TARGETS
  target_publisher
  decision_subscriber
  DESTINATION lib/${PROJECT_NAME}
)

# launch/ 和 config/ 目录创建后，将其安装到软件包共享目录。
install(DIRECTORY launch config
  DESTINATION share/${PROJECT_NAME}
  OPTIONAL
)
```

构建与运行：

```bash
# 构建当前包
cd ~/ros2_ws
colcon build --packages-select rm_vision_demo --symlink-install
source install/setup.bash

# 终端 1：发布目标
ros2 run rm_vision_demo target_publisher

# 终端 2：订阅并输出决策
ros2 run rm_vision_demo decision_subscriber
```

发布节点持续输出发送日志、订阅节点同时输出收到的坐标，说明这个最小示例已经完成消息传递。接下来再用命令检查节点名称和接收频率，然后进入 launch 与参数管理。

==== 最小示例检查

运行上面的命令后，至少确认这三项：

1. `ros2 node list` 能看到 `target_publisher` 和 `decision_subscriber`。
2. `ros2 topic hz /detector/target` 频率基本稳定（与定时器设置接近）。
3. 重开一个新终端后重新 `source`，节点还能正常启动。


=== launch 文件
// 用一条命令拉起整套系统
// - 为什么 launch 必须学
// - Python launch 文件结构
// - 参数、重映射、命名空间
// - 比赛场景中的启动配置管理
// === launch 文件

节点增多后，逐个打开终端、输入命令容易漏掉参数或启动顺序。`launch` 文件把节点、参数、重映射和命名空间写成可纳入版本控制的启动配置。

==== 最小 launch 示例

`launch/vision_decision.launch.py`：

```python
from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description():
    detector = Node(
        package="rm_vision_demo",
        executable="target_publisher",
        name="detector_node",
        output="screen",
    )

    decision = Node(
        package="rm_vision_demo",
        executable="decision_subscriber",
        name="decision_node",
        output="screen",
    )

    return LaunchDescription([detector, decision])
```

启动命令：

```bash
ros2 launch rm_vision_demo vision_decision.launch.py
```

`launch` 和 `launch_ros` 还应作为运行依赖写入 `package.xml`：

```xml
<exec_depend>launch</exec_depend>
<exec_depend>launch_ros</exec_depend>
```

重新执行 `colcon build --packages-select rm_vision_demo --symlink-install` 并加载工作空间后，ROS 2 才能从安装目录找到新增的 launch 文件。

==== 参数文件与多场景配置

开发与比赛通常需要不同配置，例如：

- 调试配置（日志详细、阈值保守）。
- 比赛配置（控制日志量，并使用已验证的性能参数）。

建议把参数放进 YAML：

```yaml
# config/detector.yaml
detector_node:
  ros__parameters:
    threshold: 0.65
    max_lost_frames: 8
```

安装 `config/` 目录后，可以从软件包共享目录定位并加载配置，避免依赖启动命令所在的当前目录：

```python
from launch.substitutions import PathJoinSubstitution
from launch_ros.substitutions import FindPackageShare

detector_config = PathJoinSubstitution([
    FindPackageShare("rm_vision_demo"),
    "config",
    "detector.yaml",
])

# 作为 detector = Node(...) 的一个参数
parameters=[detector_config]
```

节点还必须在 C++ 中使用 `declare_parameter` 声明并读取 `threshold`、`max_lost_frames` 等参数，否则 YAML 中的数值不会改变算法行为。完成这部分接入后，修改参数文件通常不需要重新编译 C++，但需要重新启动节点才能重新读取启动参数。如果希望 `ros2 param set` 在运行期间改变行为，还要验证新值并让算法读取更新后的参数：可以注册参数更新回调并同步受影响的状态，也可以在使用时重新读取。只在构造函数中缓存一次参数不会自动更新。

==== 命名空间与重映射

同一套算法复用两路相机时，两份节点需要各自的话题前缀，否则发布者和订阅者很容易接错数据。命名空间可以把它们整理成：

- `/front/detector/target`
- `/rear/detector/target`

通过 launch 设置 `namespace` 与 remapping，可以在不改节点实现的前提下复用节点。为使命名空间生效，节点代码应像前面的示例一样使用 `detector/target` 这类相对名称，避免把话题写成以 `/` 开头的全局名称。


=== ROS 工具（rqt、rviz2）
// 观察系统、验证数据、定位问题
// - rqt_graph
// - rqt_plot / rqt_console
// - rviz2 常用显示项
// - 典型排查流程
// === ROS 工具（rqt、rviz2）

这些工具分别显示 ROS 图、数值、日志和空间数据。排查时可以先确认节点与话题是否存在，再检查消息频率、内容和坐标关系。

==== rqt：先看拓扑，再看细节

启动图形工具集：

```bash
rqt
```

最常用插件：

- `rqt_graph`：查看节点、发布者和订阅者之间的话题拓扑。
- `rqt_plot`：查看数值随时间变化，适合调滤波器和控制量。
- `rqt_console`：集中筛选日志，查看哪些节点报告了异常。

如果预期的连接没有出现，先检查节点和话题名称。若图中存在相同话题的发布者与订阅者，却没有实际消息，再用 `ros2 topic info -v /detector/target` 检查双方类型与 QoS，并结合日志确认节点是否正在发布。

==== rviz2：检查空间数据与坐标关系

启动：

```bash
rviz2
```

视觉与目标跟踪常用显示项：

- `Image`：相机图像。
- `PointCloud2`：点云。
- `Marker/MarkerArray`：检测框、轨迹、预测点。
- `TF`：坐标系关系。

`Fixed Frame` 设置错误是常见问题之一。如果显示项没有内容，先检查所选固定坐标系是否存在、TF 树是否连通，再核对消息的 `frame_id` 和时间戳。

==== 一套实用排查顺序

当节点进程存在但没有得到预期结果时，可以按顺序排查：

1. `ros2 node list`：节点是否都在。
2. `ros2 topic list`：关键话题是否存在。
3. `ros2 topic hz /detector/target` 与 `ros2 topic echo /detector/target`：接收频率和内容是否合理。
4. `rqt_graph`：发布与订阅关系是否符合设计。
5. `rviz2`：坐标系和可视化数据是否一致。

在修改算法前，先确认节点启动、话题连接、消息内容与坐标变换分别符合预期，避免把配置或通信问题误判成算法问题。


=== 实战：简单的视觉/决策节点
// 把前面的概念串成最小工程
// - 模块拆分建议
// - 数据流定义
// - 运行脚本与录包回放
// - 从 Demo 到正式项目的演进路径
// === 实战：简单的视觉/决策节点

下面给出一个便于扩展的初始架构。先用简单实现验证模块接口，再逐步替换为真实算法。

==== 建议的最小模块划分

- `camera_node`：采集图像并发布。
- `detector_node`：识别装甲板并发布目标。
- `tracker_node`：做时序关联、状态估计。
- `decision_node`：根据目标状态输出云台/射击控制指令。
- `serial_node`：和下位机通信。

先验证消息定义、发布频率和模块间的数据传递，再迭代算法细节。这样可以把接口问题与算法问题分开定位。

==== 先定义消息，再写逻辑

原型阶段可以使用合适的标准消息验证流程；当目标信息包含类别、置信度、姿态、时间戳等明确业务字段时，建议建立 `rm_interfaces` 包并统一定义：

- `ArmorTarget.msg`
- `TargetArray.msg`
- `GimbalCommand.msg`

消息定义经过评审并相对稳定后，各模块可以围绕同一接口并行开发。字段确需变更时，应同步更新发布者、订阅者、回放数据和接口测试。

==== 用录包与回放重复测试

现场采集到的数据可以用 rosbag 记录，并在实验室回放：

```bash
# 录制关键话题
ros2 bag record /camera/image_raw /detector/target /tracker/state

# 以原速回放；用 --rate 0.5 可按半速回放
ros2 bag play path/to/bag_directory
ros2 bag play path/to/bag_directory --rate 0.5
```

回放能够重复提供已记录的话题，适合检查相同输入下的算法结果。它不会自动复现实车的设备故障、网络状态、调度时序或记录时遗漏的数据，因此应把可由回放验证的范围与仍需实车验证的部分分开记录。

==== 从示例扩展为可维护项目

从最小示例到可比赛系统，通常按这个顺序演进：

1. 在单机上验证消息传递。
2. 引入参数文件和 launch 管理。
3. 增加日志、监控、异常保护。
4. 引入单元测试和回放测试。
5. 做性能压测与瓶颈优化。

完成这些步骤后，团队就有了可重复启动、观察和测试 ROS 2 系统的基本条件。是否满足比赛需求，还要通过目标硬件上的性能、时序和故障测试判断。


=== 小结：先建立清楚的系统边界

ROS 与 ROS 2 的主要作用之一，是把复杂机器人系统组织成接口清楚、可以协作开发的模块。除了记住命令，还需要掌握三件事：

- 正确选择通信模型（topic/service/action）。
- 用包、参数、launch 管理系统复杂度。
- 用 rqt、rviz2 和 rosbag 观察系统，并重复验证已经记录的数据。

先建立这些基础，再加入复杂算法，可以减少接口和运行配置反复变化带来的返工。

至此，基础篇已经把开发环境、C++ 构建、协作流程和 ROS 2 运行框架连在一起。后续数学与视觉章节中的坐标变换、滤波和检测算法，可以放回这里的消息接口、参数配置和回放测试中逐步验证。
