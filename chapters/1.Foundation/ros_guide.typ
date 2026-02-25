#show raw.where(block: true): set block(inset: (left: 4em))

=== ROS/ROS2 架构与概念
// 机器人软件为什么需要中间件
// - ROS 的定位与价值
// - ROS1 与 ROS2 的关系
// - 节点、话题、服务、动作、参数
// - 包、工作空间、构建系统
// - RoboMaster 开发中的典型模块划分
// === ROS/ROS2 架构与概念

机器人软件的本质是“多模块并发系统”。相机在持续产生日志和图像，检测器在做视觉推理，跟踪器在融合时序信息，决策模块在生成控制指令，串口节点在和下位机通信。把这些逻辑全部塞进一个进程看似简单，但很快会陷入耦合失控：难调试、难复用、难并行开发。

ROS（Robot Operating System）提供的不是“操作系统内核”，而是一套机器人中间件框架。它把系统拆成多个节点（node），节点之间通过标准化通信机制交互。这样每个模块都可以独立开发、独立测试、独立替换。

==== ROS1 与 ROS2：该如何理解

如果你在网上搜教程，会同时看到 ROS1 和 ROS2。可以把它们理解为同一生态的两代架构：

- ROS1：成熟、资料多，但通信和实时能力先天受限。
- ROS2：基于 DDS 通信中间件，支持 QoS、多机通信、更好的工程化能力。

对于新项目，建议优先采用 ROS2。前面 CMake 章节已经覆盖 `ament_cmake` 和 `colcon build`，这套流程就是 ROS2 的工程基础。

==== ROS2 的核心对象

理解下面几个概念，基本就能读懂大部分 ROS2 工程：

- `node`：进程中的功能单元，如 `detector_node`、`tracker_node`。
- `topic`：发布/订阅通道，适合持续数据流，如图像、目标列表。
- `service`：请求/响应模式，适合短操作，如“重置跟踪器”。
- `action`：可反馈、可取消的长任务，适合“导航到目标点”这类过程。
- `parameter`：节点运行参数，如阈值、模型路径、串口端口号。

把它映射到 RoboMaster 会更直观：

- 相机节点发布 `Image` 话题。
- 识别节点订阅图像，发布装甲板候选。
- 决策节点订阅目标，输出云台控制命令。
- 维护节点提供服务用于在线重置状态。

==== 包与工作空间

ROS2 项目组织有两层：

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

很多新手把 ROS2 的通信方式当成“三个都差不多”，这是系统设计混乱的开端。正确做法是按语义选模型。

==== Topic：高频、持续、弱耦合

话题是发布/订阅模型，发布者不关心谁在订阅，订阅者也不关心发布者是谁。它最适合持续流数据：

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

`hz` 在实战里很关键。你可以快速判断某个节点是否掉帧或阻塞。

==== QoS：ROS2 通信稳定性的关键旋钮

ROS2 的 QoS（Quality of Service）决定消息传输策略。最常见的几项：

- `reliability`: `reliable` / `best_effort`
- `history`: `keep_last` / `keep_all`
- `depth`: 队列深度
- `durability`: 是否给后加入订阅者保留历史

视觉高频流常用 `best_effort + keep_last`，控制关键数据更倾向 `reliable`。如果发布者和订阅者 QoS 不兼容，表面现象通常是“节点都在跑但收不到数据”。

==== Service：短时的一次性操作

服务是同步请求/响应，更像函数调用。典型场景：

- 重置滤波器状态
- 切换工作模式
- 请求一次标定结果

常用命令：

```bash
ros2 service list
ros2 service type /tracker/reset
ros2 service call /tracker/reset std_srvs/srv/Trigger "{}"
```

服务不适合高频周期调用。把 60Hz 数据链路做成 service，会把系统拖慢并放大阻塞风险。

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

判断规则可以很实用：

- 只要一问一答，用 `service`。
- 连续数据流，用 `topic`。
- 需要进度和取消控制，用 `action`。


=== 创建节点与发布订阅
// 从 0 到 1 跑通一个 ROS2 包
// - 工作空间初始化
// - 创建 ament_cmake 包
// - 编写 publisher/subscriber 节点
// - colcon 构建与运行
// === 创建节点与发布订阅

下面按步骤搭一个最小示例，先把发布-订阅链路跑通。

==== 创建工作空间与包

```bash
# 1) 准备工作空间
mkdir -p ~/ros2_ws/src
cd ~/ros2_ws/src

# 2) 创建示例包
ros2 pkg create rm_vision_demo --build-type ament_cmake --dependencies rclcpp std_msgs geometry_msgs

# 3) 回到工作空间根目录并构建
cd ~/ros2_ws
colcon build --symlink-install

# 4) 加载环境
source install/setup.bash
```

建议在 `~/.bashrc` 中加入 ROS2 与工作空间环境加载（注意按你实际发行版调整路径）：

```bash
source /opt/ros/<your_ros2_distro>/setup.bash
source ~/ros2_ws/install/setup.bash
```

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
    pub_ = create_publisher<geometry_msgs::msg::Point>("/detector/target", 10);
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

`decision_subscriber.cpp`：接收目标点并输出简单决策日志。

```cpp
#include <memory>

#include <geometry_msgs/msg/point.hpp>
#include <rclcpp/rclcpp.hpp>

class DecisionSubscriber final : public rclcpp::Node {
public:
  DecisionSubscriber() : Node("decision_subscriber") {
    sub_ = create_subscription<geometry_msgs::msg::Point>(
        "/detector/target", 10,
        [this](const geometry_msgs::msg::Point::SharedPtr msg) {
          const bool in_range = msg->z < 8.0;
          RCLCPP_INFO(get_logger(),
                      "recv target x=%.3f y=%.3f z=%.3f => %s",
                      msg->x, msg->y, msg->z,
                      in_range ? "fire_allowed" : "hold_fire");
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

如果这两条节点都能稳定输出日志，说明最小链路已经打通，可以继续做 launch 和参数管理。

==== 最小链路验收（建议按此检查）

跑完上面的命令后，至少确认这三项：

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

当节点数量超过两个后，手动开多个终端会迅速失控。`launch` 的价值在于把“如何启动系统”变成可版本化的代码。

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
        parameters=[{"publish_rate_hz": 20.0}],
    )

    decision = Node(
        package="rm_vision_demo",
        executable="decision_subscriber",
        name="decision_node",
        output="screen",
        remappings=[("/detector/target", "/detector/target")],
    )

    return LaunchDescription([detector, decision])
```

启动命令：

```bash
ros2 launch rm_vision_demo vision_decision.launch.py
```

==== 参数文件与多场景配置

比赛中常见两套配置：

- 调试配置（日志详细、阈值保守）。
- 比赛配置（性能优先、日志收敛）。

建议把参数放进 YAML：

```yaml
# config/detector.yaml
detector_node:
  ros__parameters:
    threshold: 0.65
    max_lost_frames: 8
```

然后在 launch 中加载：

```python
parameters=["config/detector.yaml"]
```

这样调参不需要改 C++ 并重新编译。

==== 命名空间与重映射

多车协同或多相机场景中，命名空间非常重要。比如同一算法复用两路相机：

- `/front/detector/target`
- `/rear/detector/target`

通过 launch 设置 `namespace` 与 remap，可以在不改核心代码的前提下复用节点。


=== ROS 工具（rqt、rviz2）
// 观察系统、验证数据、定位问题
// - rqt_graph
// - rqt_plot / rqt_console
// - rviz2 常用显示项
// - 典型排查流程
// === ROS 工具（rqt、rviz2）

工具的作用很直接：先确认系统有没有连上，再看数据是否合理。

==== rqt：先看拓扑，再看细节

启动图形工具集：

```bash
rqt
```

最常用插件：

- `rqt_graph`：查看节点和话题拓扑，先确认链路是否连通。
- `rqt_plot`：查看数值随时间变化，适合调滤波器和控制量。
- `rqt_console`：集中看日志，快速定位异常节点。

如果你预期有消息但 `rqt_graph` 没连接，先检查话题名和 QoS 是否一致。

==== rviz2：把抽象数据变成可验证画面

启动：

```bash
rviz2
```

视觉与目标跟踪常用显示项：

- `Image`：相机图像。
- `PointCloud2`：点云。
- `Marker/MarkerArray`：检测框、轨迹、预测点。
- `TF`：坐标系关系。

`Fixed Frame` 设置错误是最常见问题之一。如果你所有显示都“看不见”，先检查 TF 树是否完整。

==== 一套实用排查顺序

当系统“看起来在跑但结果不对”时，按顺序排查：

1. `ros2 node list`：节点是否都在。
2. `ros2 topic list`：关键话题是否存在。
3. `ros2 topic hz/echo`：频率和内容是否合理。
4. `rqt_graph`：链路是否断开。
5. `rviz2`：坐标系和可视化数据是否一致。

不要一上来就改算法，先确认链路和数据面是正确的。


=== 实战：简单的视觉/决策节点
// 把前面的概念串成最小工程
// - 模块拆分建议
// - 数据流定义
// - 运行脚本与录包回放
// - 从 Demo 到正式项目的演进路径
// === 实战：简单的视觉/决策节点

下面给一个可扩展的起步架构，先求能联调，再逐步替换成真实算法。

==== 建议的最小模块划分

- `camera_node`：采集图像并发布。
- `detector_node`：识别装甲板并发布目标。
- `tracker_node`：做时序关联、状态估计。
- `decision_node`：根据目标状态输出云台/射击控制指令。
- `serial_node`：和下位机通信。

先把接口打通，再迭代算法细节。不要反过来。

==== 先定义消息，再写逻辑

如果团队暂时不想维护自定义消息包，也可以用标准消息快速推进；但进入正式阶段建议抽出 `rm_interfaces` 包，统一定义：

- `ArmorTarget.msg`
- `TargetArray.msg`
- `GimbalCommand.msg`

接口稳定后，模块才能真正并行开发，避免“每次改字段全链路改代码”。

==== 录包与回放是算法迭代加速器

现场调试时间稀缺，建议建立数据闭环：

```bash
# 录制关键话题
ros2 bag record /camera/image_raw /detector/target /tracker/state

# 回放数据（可加速或减速）
ros2 bag play <bag_path>
```

这样你可以在实验室复现赛场问题，不依赖实时硬件环境反复试错。

==== 从 Demo 走向工程化

从最小示例到可比赛系统，通常按这个顺序演进：

1. 单机跑通消息链路。
2. 引入参数文件和 launch 管理。
3. 增加日志、监控、异常保护。
4. 引入单元测试和回放测试。
5. 做性能压测与瓶颈优化。

前四步做完后，ROS2 基本就能支撑你们的日常联调和回归测试。


=== 小结：先把系统边界建立清楚，再追求算法上限

ROS/ROS2 的核心价值是把复杂机器人系统拆成可协作的模块。你掌握的重点不该只是命令，而是三件事：

- 正确选择通信模型（topic/service/action）。
- 用包、参数、launch 管理系统复杂度。
- 用 rqt、rviz2、bag 建立可观测、可复现的调试闭环。

先把这三件事做扎实，再上复杂算法，会少很多返工。
