//== 软件工程基础

=== 为什么需要软件工程
// 引言：从“能跑”到“能维护”
// - 个人项目 vs 团队项目的差异
// - 代码的生命周期：编写只是开始
// - 技术债务的概念
// - RoboMaster 赛季迭代的教训
// - 本章内容概览
// 
你写了一个程序，它能在自己的电脑上处理准备好的测试数据，于是继续开发下一项功能。几个月后，队友询问某段代码的用途，你已经记不清当时的假设；新赛季要在原有模块上增加功能时，修改一处又影响了几个看似无关的部分。等到原作者毕业，接手者可能只能从代码、配置和零散消息中还原设计，最后选择重写。

这个场景在成员流动频繁的学生团队中并不少见。代码在一次演示中“能运行”只是起点，它还要在新的输入、设备和需求下被阅读、测试、修改与交接。软件工程研究并实践的正是这些问题：怎样组织代码，怎样协调多人改动，怎样验证行为，以及怎样保存对后续维护有用的知识。

==== 从个人项目到团队协作

个人开发与团队开发面对的主要约束不同。

个人项目中，许多上下文暂时保存在作者记忆里：变量的含义、设计取舍、临时实现和输入假设都不必立刻向别人说明。对于规模很小、生命周期很短的试验代码，较少的流程有时确实更高效。但只要项目需要长期维护，即使唯一读者是未来的自己，这些隐含信息也会逐渐丢失。

团队成员无法直接获得作者记忆中的上下文。看到 `process()` 函数时，读者可能不知道它处理什么数据、输入输出使用什么单位、有哪些前置条件、失败时如何报告。修改代码时，还要判断哪些行为属于稳定接口，哪些只是当前实现。缺少这些信息会增加沟通与试错成本，也容易让不同模块对同一数据作出不一致的假设。

因此，团队代码应尽量让意图可读：用准确命名、清楚结构和必要注释说明行为；用一致约定和明确接口减少猜测；用模块边界、测试和兼容策略控制修改的影响。这里的目标不是让任何人不读文档就立即理解所有实现，而是让具备相关背景的维护者能够找到可靠信息，并有办法验证自己的修改。

这些要求会落实到具体实践中：命名和格式规范降低阅读成本，接口与设计方法明确职责，测试检查已声明的行为，文档记录代码本身难以表达的背景和操作方法，版本控制与代码审查帮助团队协调变更。它们不能保证项目不出问题，但能让问题更容易被发现、定位和修正。

==== 代码的生命周期

一段代码从编写到退役，通常还会经历阅读、评审、调试、部署、修改、扩展与交接。开发者经常需要理解既有代码后才能完成改动，因此不能只考虑第一次写完是否方便，也要考虑以后能否准确读懂和验证。

在 RoboMaster 项目中，代码生命周期与赛季节奏紧密相连。备赛期间实现的模块会在联调和比赛中暴露新的边界情况，修正后的版本又可能成为下一赛季的基础。视觉识别、设备驱动或通信协议如果连续沿用，可能由多届成员接力维护，原作者当时没有写下的约束会直接影响后续开发。

写代码时可以用几个问题检查维护成本：半年后还能否说明这段实现的目的？队友能否找到输入、输出和失败条件？修改后有哪些测试可以检查兼容性？新成员能否在文档中找到构建、运行和调参方法？这些问题比追求某种形式上的“漂亮代码”更具体。

==== 技术债务

技术债务描述为了短期目标接受某项实现妥协，并把相应的整理或重构成本留到以后。把它类比为金融债务的原因在于：妥协本身未必错误，但如果长期不处理，后续修改往往需要额外理解、绕过或修补，形成持续的维护成本。

技术债务有多种形式：为赶进度保留的临时代码、缺少关键路径测试的功能、没有记录的接口假设、无法及时升级的依赖，以及只规避现象却未弄清适用条件的临时处理。并非每项未完成工作都同样重要；需要记录它影响的范围、触发条件和后续处理优先级。

在时间受限时，有意识地接受技术债务可能是合理决策。例如比赛前需要先恢复一项关键功能，可以采用范围明确、可回退的临时修复，把完整重构留到赛后。关键是记录原因和风险、验证当前用途、指定后续任务；否则临时方案很容易被当作长期设计继续扩展。

RoboMaster 团队的赛程紧、成员流动和硬件联调都会增加技术债务积累的机会。常见结果包括：模块之间形成没有记录的依赖，修改时只能继续增加条件分支；新功能需要先进行大范围重构；新成员只能通过反复运行和询问原作者理解系统。重写也不一定自动解决这些问题，如果需求、接口和测试仍未明确，新实现可能重复原来的缺陷。

代码规范、设计方法、测试、文档和持续集成都可以帮助控制技术债务。它们同样有维护成本，因此应优先覆盖多人共享、经常修改或故障代价较高的部分，并根据项目规模逐步增加流程，而不是一次加入所有工具。

==== RoboMaster 赛季的教训

在 RoboMaster 的实际开发中，下列问题经常同时出现。

备赛初期，成员分别实现功能，如果没有共同约定，命名、格式、错误处理和配置方式可能各不相同。风格差异本身通常不影响程序运行，却会增加合并与审查成本；接口语义的差异则可能直接产生错误。

赛季中期整合模块时，可能发现 A 模块输出的数据格式与 B 模块的假设不同，两个组件要求同一依赖的不同版本，或者多人分别实现了坐标变换却采用不同坐标系约定。此时需要补充接口定义、统一依赖并用测试数据核对变换关系，整合时间往往超过最初预期。

临近比赛时，缺少回归测试会使修改风险难以判断；注释掉的旧实现、临时调试输出和硬编码参数也会妨碍定位当前配置。把参数移入有版本记录的配置文件、删除可由版本控制找回的旧代码，并保留最小的自动测试，可以缩短这类调整的反馈周期。

赛季结束进行总结和交接时，如果缺少构建步骤、硬件连接、参数单位和设计决策记录，新成员就只能从代码与运行现象推断。尤其是没有命名的数值常量，仅看数值很难判断它来自规则限制、标定结果还是一次临时试验。

这些问题可以通过适量、持续的工程实践降低发生概率和影响：格式工具减少无关差异，接口定义明确数据格式与单位，测试检查关键行为，文档保存构建方法和决策背景。它们不能代替联调或证明系统没有缺陷，但能让团队更早发现不一致，并为修改提供依据。

==== 本章内容概览

本章介绍几项与学生机器人项目直接相关的软件工程实践，目标是让已经能够运行的代码更容易协作和维护。

我们从代码规范与风格开始。统一的代码风格是团队协作的基础。我们会介绍业界广泛采用的 Google C++ Style Guide 的核心要点，包括命名、格式、注释等方面的规范，以及如何使用 clang-format 等工具自动化地保持代码风格一致。

接下来是设计模式。我们会介绍其来源和基本原则，并用单例、工厂、观察者、策略和状态模式说明对象之间可以怎样分配职责。每种模式都有适用条件和代价，例如单例会引入全局状态与测试困难，不能把模式名称当作必须采用的答案。

然后是单元测试。我们会介绍测试层次、Google Test 的基本用法，以及怎样通过依赖注入等方式让代码更容易测试。单元测试能验证明确列出的输入与行为，系统联调、硬件时序和未覆盖输入仍需要其他层次的检查。

后面的简短章节还会概括调试与性能分析的基本顺序，并与前文已经介绍的 GDB、内存检查和 perf 等工具衔接。工具给出的是调用栈、错误报告和样本等观察结果，定位原因还需要结合复现条件与对照修改。

性能分析关注的不只是“更快”，还包括延迟分布、资源占用和是否满足规定的截止时间。文档部分则讨论 README、API 文档和赛季交接材料分别应记录什么，以及怎样让文档随代码一起维护。

最后会简要回顾分支策略、提交说明、代码审查和持续集成。这部分与 Git 章节相呼应，重点说明团队需要根据人数、发布节奏和风险选择协作方式。

软件工程并不是固定流程的集合。对短期实验和长期维护的公共模块，合适的投入不同；判断标准应是这些做法是否减少了沟通成本、提高了变更的可验证性，并留下足够的交接信息。下面先从最容易统一的代码规范开始。


=== 代码规范与风格
// 让代码成为团队的共同语言
// - 为什么需要统一的代码规范
// - Google C++ Style Guide 核心要点：
//   命名规范（变量、函数、类、常量、文件）
//   格式规范（缩进、空格、换行、大括号）
//   注释规范（文件头、函数注释、行内注释）
//   头文件规范（#pragma once、include 顺序）
// - 现代 C++ 的额外建议
// - 工具辅助：clang-format、clang-tidy
// - .clang-format 配置示例
// - 代码审查（Code Review）的价值
// - RoboMaster 团队代码规范建议
// === 代码规范与风格

打开一个陌生代码库时，命名、缩进、大括号位置和注释方式会直接影响阅读是否连贯。代码规范就是团队对这些细节以及部分语言用法的共同约定。它不决定算法是否正确，却能减少无关差异，让读者把注意力放在数据流、接口和行为上。

==== 为什么需要统一的代码规范

开发者的编码习惯各不相同：变量可能采用 `camelCase` 或 `snake_case`，缩进和换行也有多种常见方案。个人试验中，这些差异影响不大；多人在同一代码库协作时，频繁切换风格会增加阅读和合并成本。

例如，同一文件前半部分使用 `imageWidth`，后半部分改成 `image_height`，缩进又混用空格与制表符。读者需要先判断这些差异是否表达了不同语义；修改者也难以确定新代码应遵循哪种约定。若一次功能修改顺带重排了大量格式，版本控制差异中真正的逻辑变化还会更难辨认。

统一规范后，新成员只需学习一套主要约定，格式问题可交由工具检查，代码审查便能更多关注正确性和设计。规范还应说明何时格式化旧文件：通常避免把全文件重排与功能修改混在同一次变更中，以保持差异清晰。

多数格式选择没有唯一正确答案，一致且能由工具执行通常比争论具体风格更重要。团队也不必逐条照搬外部规范，可以从 Google C++ Style Guide、LLVM Coding Standards 或既有 ROS 项目中选择基线，再记录本项目的差异。下文以 Google 风格为主要参考，同时明确给出适合本教程示例的团队约定；Google 指南会更新，实际项目应以采用时固定的版本和仓库配置为准。

==== 命名规范

命名应帮助读者判断对象表示什么、函数执行什么动作以及单位或坐标系等关键约束。名称不能代替类型、接口文档和实现，但含糊的名称会迫使读者在多处代码中反推含义。

Google C++ Style Guide 对不同类型的标识符规定了不同的命名风格，这种差异化的命名让读者能够从名字本身判断标识符的类型。

文件名使用小写字母，单词之间用下划线连接，并应反映主要内容。Google 指南常用 `.cc` 作为 C++ 源文件扩展名；许多 ROS 和学生项目使用 `.cpp`。两者都能正常构建，团队选择一种并保持一致即可。本教程以下采用 `.h` 和 `.cpp`，例如 `ImageProcessor` 的文件命名为 `image_processor.h` 与 `image_processor.cpp`。

```cpp
// 文件命名示例
image_processor.h      // 头文件
image_processor.cpp    // 源文件
robot_controller.h
camera_driver.cpp
```

类型名称使用大驼峰命名法（PascalCase），即每个单词首字母大写，不使用下划线。这包括类、结构体、类型别名、枚举类型和模板参数。这种命名风格让类型名称一眼就能与变量名区分开来。

```cpp
// 类型命名示例
class ImageProcessor;
struct SensorData;
enum class RobotState;
using TargetList = std::vector<Target>;

template <typename DataType>  // 模板参数也用大驼峰
class CircularBuffer;
```

变量名使用小写字母加下划线（snake_case），包括局部变量、函数参数和本例中的公有数据成员。类的私有和保护数据成员在名称末尾加下划线，因此 `image_width_` 可以与局部变量 `image_width` 区分。结构体等纯数据类型也可以统一使用普通变量命名，具体以团队规则为准。

```cpp
// 变量命名示例
int image_width;              // 局部变量
double detection_threshold;   // 函数参数

class Camera {
public:
    int frame_count;          // 公有成员（如果有的话）
    
private:
    int image_width_;         // 私有成员，末尾加下划线
    double exposure_time_;
    std::string device_path_;
};
```

函数名使用大驼峰命名法，与类型名相同。函数名应该是动词或动词短语，描述函数执行的动作。访问器（getter）和修改器（setter）可以使用与变量类似的命名，如 `image_width()` 和 `set_image_width()`。

```cpp
// 函数命名示例
void ProcessImage();
bool DetectTarget();
int CalculateDistance();

// 访问器和修改器
int image_width() const { return image_width_; }
void set_image_width(int width) { image_width_ = width; }
```

需要作为常量命名的对象和枚举值可使用 `k` 前缀加大驼峰命名。宏定义通常使用全大写字母加下划线；如果 `constexpr`、内联函数、模板或语言特性能够表达同一需求，应优先使用这些具有类型和作用域的机制。并非所有 `const` 局部变量都必须机械地改成 `k` 前缀，团队应在规范中说明范围。

```cpp
// 常量命名示例
const int kMaxBufferSize = 1024;
constexpr double kPi = 3.14159265358979;

enum class Color {
    kRed,
    kGreen,
    kBlue
};

// 宏命名（尽量避免使用宏）
#define DEPRECATED_FUNCTION __attribute__((deprecated))
```

命名空间使用小写字母，通常是项目名或模块名的缩写。命名空间用于避免全局命名冲突，尤其在大型项目中非常重要。

```cpp
// 命名空间示例
namespace rm {           // RoboMaster 项目
namespace vision {       // 视觉模块
    class Detector { /* ... */ };
}  // namespace vision
}  // namespace rm

// 使用
rm::vision::Detector detector;
```

除了格式规则，名称还要准确表达当前作用域中的含义。`temp`、`data`、`info` 或 `process()` 在缺少上下文时通常过于含糊，`the_current_image_frame_from_camera` 又可能重复类型和作用域已经提供的信息。短循环中的 `i`、`j` 是常见索引约定；作用域扩大或存在多个索引时，使用 `row`、`column`、`target_index` 等名称更清楚。

```cpp
// 不好的命名
int n;                          // 什么的数量？
void Process();                 // 处理什么？怎么处理？
std::vector<int> data;          // 什么数据？

// 好的命名
int target_count;
void ProcessImage();
std::vector<int> detection_scores;
```

==== 格式规范

格式规范约定缩进、空格、换行和大括号位置，使相同结构呈现为相近的形式。大多数规则都可以交给 clang-format 自动执行。

团队可以统一使用空格缩进，并选择每级 2 个或 4 个空格（Google 风格是 2 个，本章末尾的示例配置选择 4 个）。制表符的显示宽度取决于编辑器设置，混用空格和制表符尤其容易造成对齐差异。若项目明确采用制表符，也应由格式化工具统一处理。

```cpp
// 缩进示例（2 空格）
class Robot {
  void Move() {
    if (is_enabled_) {
      for (int i = 0; i < 10; ++i) {
        Step();
      }
    }
  }
};
```

行宽通常设置为 80、100 或其他团队选定的上限，以便并排查看代码和差异。函数参数较多时可以分行对齐，长表达式则由格式化工具按规则断开。URL、生成代码或无法自然拆分的字符串可作为例外，不必为了满足数字而降低可读性。

```cpp
// 长行换行示例
void ProcessTarget(const Target& target,
                   const CameraParams& camera_params,
                   const GimbalState& gimbal_state,
                   std::vector<Result>* results);

// 长表达式换行
double distance = std::sqrt(
    (target.x - origin.x) * (target.x - origin.x) +
    (target.y - origin.y) * (target.y - origin.y) +
    (target.z - origin.z) * (target.z - origin.z));
```

大括号位置有多种常见约定。Google C++ Style Guide 将函数、类和控制语句的左大括号放在当前行末；Allman 风格则将左大括号另起一行。选择由 `.clang-format` 固定后，团队成员通常不需要手动调整。

```cpp
// Google 风格：左大括号放在当前行末
class Robot {
  void Move() {
    if (is_enabled_) {
      // ...
    }
  }
};

// Allman 风格：所有大括号都另起一行
class Robot
{
  void Move()
  {
    if (is_enabled_)
    {
      // ...
    }
  }
};
```

空格的使用应该一致且有助于可读性。二元运算符两边加空格，一元运算符不加；逗号和分号后面加空格，前面不加；控制语句的关键字与括号之间加空格，函数名与括号之间不加。

```cpp
// 空格使用示例
int sum = a + b * c;              // 二元运算符两边加空格
int neg = -value;                 // 一元运算符不加
Call(arg1, arg2, arg3);           // 逗号后加空格
for (int i = 0; i < n; ++i)       // for 后加空格，分号后加空格
if (condition) {                  // if 后加空格
    DoSomething();                // 函数名与括号之间不加
}
```

空行用于分隔逻辑上独立的代码块。函数之间用一个空行分隔；函数内部，不同逻辑步骤之间可以用空行分隔；但不要过度使用空行，导致代码过于稀疏。头文件的 `#include` 部分，通常按组分隔：系统头文件、第三方库头文件、项目头文件，每组之间用空行分隔。

```cpp
#include <vector>
#include <string>

#include <opencv2/opencv.hpp>
#include <Eigen/Dense>

#include "robot/vision/detector.h"
#include "robot/common/types.h"
```

==== 注释规范

注释应补充代码难以直接表达的信息，例如为什么选择某种方案、适用条件是什么，以及某个含义不明的数值常量（常称“魔法数字”）来自规则、标定还是测试。只重复语句表面动作的注释会增加维护负担，因为代码修改后它也可能过期。“解释为什么”是有用的原则，但复杂接口仍可能需要说明它做什么、参数单位和失败方式。

文件头通常放置项目要求的版权与许可证声明，也可以简要说明文件用途。项目若采用 SPDX 标识符，应先确认许可证和仓库政策允许这种写法。作者和创建日期一般可从版本控制历史中查询，手写名单容易过期；是否保留应由项目的许可证和维护政策决定。

```cpp
// Copyright 2024 RoboMaster Team.
// SPDX-License-Identifier: MIT
//
// This file implements the armor detector for RoboMaster robots.
// The detector uses color and shape features to identify enemy armor plates.
```

类注释放在类定义之前，说明类的用途、使用方法和注意事项。对于复杂的类，还应该说明其线程安全性、生命周期管理等。

```cpp
// ArmorDetector detects enemy armor plates from camera images.
//
// Usage:
//   ArmorDetector detector(config);
//   detector.Init();
//   auto armors = detector.Detect(image, timestamp);
//
// Thread safety: This class is NOT thread-safe. Each thread should
// create its own instance.
class ArmorDetector {
    // ...
};
```

函数注释放在函数声明之前，说明函数的功能、参数含义、返回值和可能抛出的异常。对于简单的函数，如果函数名已经足够清晰，可以省略注释。

```cpp
// Detects armor plates in the given image.
//
// Args:
//   image: The input BGR image from camera.
//   timestamp: The timestamp when the image was captured.
//
// Returns:
//   A vector of detected armor plates, sorted by confidence.
//   Returns an empty vector if no armor is detected.
//
// Throws:
//   std::invalid_argument if image is empty.
std::vector<Armor> Detect(const cv::Mat& image, double timestamp);
```

行内注释用于解释单行或几行代码。它们应该放在代码的上方或右侧，解释代码的意图或需要注意的地方。避免写没有信息量的注释，如 `i++; // increment i`。

```cpp
// Preserve strong edges while reducing noise for the following contour step.
// The parameters were selected on the recorded validation set.
cv::bilateralFilter(image, filtered, 9, 75, 75);

int retry_count = 0;
const int kMaxRetries = 3;  // Determined by network latency tests
while (retry_count < kMaxRetries) {
    // ...
}
```

TODO 注释用于标记尚未完成且确实需要回到代码位置处理的事项。它应写清具体任务，并按团队约定附负责人、议题编号或其他可追踪信息。不能仅凭存在时间决定删除：仍然有效且有计划的事项可以保留，范围较大或需要排期的工作更适合放入正式任务系统，并在代码中引用编号。

```cpp
// TODO(#184, zhangsan): Evaluate SIMD for this loop. On target A with
// replay set B, its P95 latency is 6.2 ms versus the 4 ms budget.
for (int i = 0; i < n; ++i) {
    // ...
}
```

==== 头文件规范

头文件的组织对大型项目的编译效率和模块化至关重要。良好的头文件实践可以减少编译依赖、加快编译速度、避免重复包含等问题。

防止头文件重复包含常用两种方式：`#pragma once` 和宏包含守卫。`#pragma once` 简洁并受常见 GCC、Clang、MSVC 工具链支持，但它不是 C++ 标准的一部分；宏守卫可移植且是 Google 风格采用的方案。团队可根据目标工具链选择一种，本项目若采用 `#pragma once`，应在支持的编译器范围内统一使用。

```cpp
// 方案一：项目约定使用 #pragma once
#pragma once

class MyClass {
    // ...
};

// 传统方式：#ifndef 守卫
#ifndef PROJECT_MODULE_MY_CLASS_H_
#define PROJECT_MODULE_MY_CLASS_H_

class MyClass {
    // ...
};

#endif  // PROJECT_MODULE_MY_CLASS_H_
```

头文件应包含自身声明所需的直接依赖，不能依赖其他文件碰巧提前包含某个类型。前向声明（forward declaration）可以在仅保存某类型的指针或引用时减少部分编译依赖，但也会隐藏类型来源，并可能在上游改变类型定义方式时失效。先保证头文件可独立编译，再针对确有影响的依赖决定使用前向声明还是 `#include`。

```cpp
// my_class.h
#pragma once

class OtherClass;  // 前向声明，不需要 #include "other_class.h"

class MyClass {
public:
    void Process(OtherClass* obj);  // 只用指针，不需要完整定义
    
private:
    OtherClass* other_;  // 只用指针，不需要完整定义
};

// my_class.cpp
#include "my_class.h"
#include "other_class.h"  // 实现时才需要完整定义

void MyClass::Process(OtherClass* obj) {
    obj->DoSomething();  // 调用成员函数需要完整定义
}
```

`#include` 的顺序有助于发现遗漏的依赖。推荐的顺序是：首先包含当前文件对应的头文件（如 `foo.cpp` 首先包含 `foo.h`），然后是系统头文件，接着是第三方库头文件，最后是项目内部头文件。每组之间用空行分隔，每组内部按字母顺序排列。

```cpp
// image_processor.cpp
#include "vision/image_processor.h"  // 对应的头文件放第一个

#include <algorithm>
#include <vector>

#include <opencv2/opencv.hpp>
#include <Eigen/Dense>

#include "common/config.h"
#include "vision/detector.h"
```

将对应头文件放在第一个，可以让该源文件更早暴露头文件缺少直接依赖的问题，而不是依靠后续包含偶然补齐。单独编译头文件测试或 include-what-you-use 等工具还能进一步检查自包含性。

==== 现代 C++ 的额外建议

Google C++ Style Guide 会随语言版本更新。项目还需要明确采用的 C++ 标准，并根据编译器与依赖支持情况选择语言特性。下面列出几项现代 C++ 中常用的约定。

当类型很长、由表达式直接可见，或必须随模板结果变化时，`auto` 可以减少重复；当具体类型会影响单位、精度、所有权或隐式转换时，显式类型通常更清楚。重点是让读者无需跳转很远就能理解变量语义，而不是统一要求使用或禁用 `auto`。

```cpp
// 好：类型很长或很明显
auto iter = container.begin();
auto result = std::make_unique<MyClass>();
auto lambda = [](int x) { return x * 2; };

// 好：显式类型让意图更清晰
double ratio = GetRatio();  // 而不是 auto ratio = GetRatio();
```

花括号初始化可以拒绝许多窄化转换，但带有 `std::initializer_list` 构造函数的类型可能因此选择不同重载，`std::vector` 就是常见例子。选择 `()` 或 `{}` 时应确认希望调用的构造函数，而不是只按形式替换。

```cpp
int value{42};
std::string name{"robot"};
std::vector<int> sizes{1, 2, 3};  // 包含三个元素

// 注意区分
std::vector<int> v1(5);     // 5 个元素，值为 0
std::vector<int> v2{5};     // 1 个元素，值为 5
std::vector<int> v3(5, 1);  // 5 个元素，值为 1
```

使用 `nullptr` 而不是 `NULL` 或 `0` 表示空指针。`nullptr` 有明确的类型，可以避免函数重载时的歧义。

```cpp
void Process(int value);
void Process(int* ptr);

Process(NULL);     // 歧义：可能调用 Process(int)
Process(nullptr);  // 明确：调用 Process(int*)
```

使用范围 for 循环遍历容器，更简洁也更不容易出错。

```cpp
std::vector<Target> targets = GetTargets();

// 传统方式
for (size_t i = 0; i < targets.size(); ++i) {
    Process(targets[i]);
}

// 现代方式
for (const auto& target : targets) {
    Process(target);
}
```

使用 `enum class` 而不是普通 `enum`，避免枚举值污染外层命名空间，也更类型安全。

```cpp
// 不好：枚举值泄漏到外层
enum Color { Red, Green, Blue };
int Red = 5;  // 错误：重定义

// 好：枚举值限定在枚举类内
enum class Color { kRed, kGreen, kBlue };
int Red = 5;  // OK
Color c = Color::kRed;
```

对象能直接作为局部变量或成员保存时，通常不需要动态分配。确需表达动态所有权时，使用智能指针可以把释放操作与对象生命周期绑定：默认选择 `std::unique_ptr` 表达单一所有者，只有多个对象确实共同拥有生命周期时才使用 `std::shared_ptr`。观察但不拥有对象的指针或引用还要有明确的生命周期约束。

```cpp
// 不好：手动管理内存
MyClass* obj = new MyClass();
// ... 如果中间抛出异常，内存泄漏
delete obj;

// 好：使用智能指针
auto obj = std::make_unique<MyClass>();
// 离开作用域自动释放，异常安全
```

==== 工具辅助

格式规则适合由工具自动执行，这样人工审查可以集中在工具无法判断的命名、接口和行为上。

clang-format 是 LLVM 项目提供的代码格式化工具，支持多种预设风格（Google、LLVM、Chromium 等），也可以通过配置文件自定义。它可以集成到编辑器中，在保存文件时自动格式化，或者作为 CI 检查的一部分。

```bash
# 使用 Google 风格格式化文件
clang-format -style=Google -i my_file.cpp

# 使用配置文件格式化
clang-format -style=file -i my_file.cpp

# 检查是否符合格式（用于 CI）
clang-format -style=file --dry-run --Werror my_file.cpp
```

clang-format 的配置文件名为 `.clang-format`，放在项目根目录下。以下是一个基于 Google 风格的配置示例，适合 RoboMaster 项目使用：

```yaml
# .clang-format
BasedOnStyle: Google

# 缩进设置
IndentWidth: 4
TabWidth: 4
UseTab: Never
AccessModifierOffset: -4

# 行宽限制
ColumnLimit: 100

# 大括号风格
BreakBeforeBraces: Attach

# 指针和引用的对齐
PointerAlignment: Left
ReferenceAlignment: Left

# 头文件排序
SortIncludes: true
IncludeBlocks: Regroup
IncludeCategories:
  - Regex: '^<.*>'
    Priority: 1
  - Regex: '^".*"'
    Priority: 2

# 其他
AllowShortFunctionsOnASingleLine: Empty
AllowShortIfStatementsOnASingleLine: Never
AllowShortLoopsOnASingleLine: false
```

clang-tidy 是 LLVM 提供的静态分析工具，可以按配置检查部分易错写法、可移植性、性能和现代化建议，并自动修复其中一些问题。检查是基于规则的，报告需要结合项目语义确认；没有报告也不能证明代码不存在缺陷。复杂项目通常让它读取 CMake 导出的 `compile_commands.json`，以获得与真实构建一致的包含路径和编译选项。

```bash
# 简单文件可在 -- 后提供编译选项
clang-tidy my_file.cpp -- -std=c++17

# 自动修复可修复的问题
clang-tidy --fix my_file.cpp -- -std=c++17
```

VS Code、CLion 等编辑器都可以调用 clang-format，也可以在提交前钩子或 CI 中检查格式。自动格式化的工具版本应尽量固定，因为不同版本可能生成不同换行结果；编辑器中的自动修复还应让开发者在提交前查看差异。

==== 代码审查

代码审查（Code Review）通常指代码合并前，由其他成员阅读变更、测试说明和相关背景并给出反馈。它可以发现部分缺陷、传播模块知识并检查团队约定，但效果取决于变更规模、审查时间和审查者掌握的信息，不能替代运行测试。

审查除了检查缺陷，还能让更多成员了解关键模块。熟悉该模块的人可以补充历史约束，不熟悉的人则可能指出接口难以理解之处。讨论中形成的稳定结论应写回代码、测试或文档，否则相同背景仍需在下一次审查中重复说明。

审查应先核对需求与行为：变更是否解决声明的问题，失败路径和边界条件怎样处理，测试是否覆盖关键差异。随后检查接口兼容性、可维护性以及与现有代码的一致性。性能和安全结论需要相应证据；仅阅读代码可以提出风险或要求测试，通常不能确认目标设备上的性能数字或证明没有漏洞。

审查者应把必须修改的问题、建议和疑问区分开，并说明依据或可能受影响的路径。可以由工具判断的格式问题不必反复人工讨论。涉及替代设计时，给出约束和取舍通常比只给出结论更便于作者处理。

作者应补充复现方法、测试结果和设计背景，并逐项回应反馈。意见不一致时，双方可以回到需求、代码行为或小范围实验；证据仍不足时，明确记录未决问题，而不是把资历或个人偏好当作结论。

```
代码审查清单：
□ 代码是否实现了需求描述的功能？
□ 逻辑是否正确？边界条件是否处理？
□ 命名是否清晰、一致？
□ 代码结构是否清晰？函数是否过长？
□ 注释是否充分？是否解释了"为什么"？
□ 是否有重复代码可以提取？
□ 错误处理是否完善？
□ 是否有明显的性能问题？
□ 是否符合团队代码规范？
□ 测试是否充分？
```

==== RoboMaster 团队代码规范建议

基于以上讨论，这里为 RoboMaster 团队提供一些具体的代码规范建议。这些建议可以作为起点，团队可以根据自己的情况调整。

关于命名，建议使用 Google 风格：类型用 `PascalCase`，变量和函数参数用 `snake_case`，成员变量末尾加下划线，常量用 `kPascalCase`。对于 RoboMaster 项目中的特定概念，建议统一术语：敌方装甲板用 `Armor`，云台用 `Gimbal`，底盘用 `Chassis`，自瞄用 `AutoAim` 等。

关于格式，本章示例采用 4 空格缩进、100 字符行宽和行末左大括号，并由前面的 `.clang-format` 固定。实际项目可以采用 2 空格或其他一致约定；应以仓库中的格式配置为准，不要把某组参数笼统称为“ROS 社区风格”。将配置文件纳入版本控制后，编辑器与 CI 才能执行同一套规则。

关于项目结构，建议按功能模块组织代码：`vision/`（视觉）、`control/`（控制）、`communication/`（通信）、`common/`（公共）等。每个模块有自己的头文件目录和源文件目录。使用命名空间与目录结构对应，如 `rm::vision`、`rm::control`。

```
robomaster_project/
├── CMakeLists.txt
├── .clang-format
├── README.md
├── include/
│   └── rm/
│       ├── vision/
│       │   ├── detector.h
│       │   └── tracker.h
│       ├── control/
│       │   ├── gimbal_controller.h
│       │   └── chassis_controller.h
│       └── common/
│           ├── types.h
│           └── config.h
├── src/
│   ├── vision/
│   ├── control/
│   └── common/
└── test/
    ├── vision/
    └── control/
```

关于注释，建议为具有稳定使用者、行为不直观的公开接口提供文档，说明功能、参数单位、所有权、返回值和错误方式。简单且语义清楚的访问器不必重复代码。复杂算法可记录关键假设并引用可长期访问的论文或设计文档；临时方案和已知限制则应通过 TODO、FIXME 或任务编号保持可追踪。

关于代码审查，可将“一名其他成员审查后再合并”作为共享分支的起点。安全、通信协议或核心控制模块是否需要更多审查者，应按影响范围和团队人数决定；紧急修复若先合并，也要记录原因并安排事后复核。检查清单有助于提醒常见项目，但不能替代针对本次变更的判断。

代码规范服务于协作，可以随工具链和项目需求调整。修改规范时应同步更新格式配置和示例，并避免无计划地重排整个仓库。格式工具在实际运行且覆盖相关文件时能执行形式规则，命名、设计和文档是否准确仍需开发者与审查者结合上下文判断。



=== 设计模式的起源
*设计模式*（Design Pattern）是软件开发者在长期实践中提炼出的、可复用的设计经验。它们针对反复出现的问题，描述参与对象、协作关系和常见取舍；经过整理和分类后，逐渐形成了一套便于学习与讨论的知识体系。

设计模式不是可以直接复制的成品代码，也不能保证问题被一次解决。它提供的是解题框架：先识别重复出现的设计问题，再根据约束选择经过实践检验的组织方式。团队还可以借助“工厂”“观察者”“策略”等名称，简洁地交流一组结构和职责。

1994 年，Erich Gamma、Richard Helm、Ralph Johnson 与 John Vlissides 四人共同出版了影响深远的著作 #text(weight: "bold", style: "italic")[Design Patterns: Elements of Reusable Object-Oriented Software]（中文译名：《设计模式——可复用面向对象软件的基础》）。四位作者后来常被合称为 GoF（Gang of Four）。这本书系统整理并推广了面向对象软件中的设计模式概念。

GoF 在书中收录了 *23 种经典设计模式*，并按关注的问题分为创建型、结构型和行为型三类。这套目录后来成为讨论面向对象设计时常用的参考框架。

原书的示例主要使用 *C++* 和 *Smalltalk*。在现代 C++（Modern C++）中，RAII、模板、智能指针、lambda、`constexpr` 等语言特性可以直接承担部分传统模式的职责，因此有些模式的实现会更简洁，有些经典写法则不再必要。

下面仍沿用 GoF 的三类划分，因为它能清楚说明各类模式主要处理哪一部分问题：

1. *创建型模式（Creational Patterns）*\
   关注对象的创建方式，以提升灵活性与可扩展性。

2. *结构型模式（Structural Patterns）*\
   关注类与对象的组织结构，使系统模块更清晰、更易复用。

3. *行为型模式（Behavioral Patterns）*\
   关注对象间的协作方式与职责划分，提升系统行为的稳定性与扩展性。

这些模式仍可用于理解和讨论软件架构，只是在 C++ 语境下要结合当前语言能力选择实现方式。后文介绍具体模式时，也会同时说明适用场景、代价和可替代方案。

=== 设计模式的基本原则

设计模式经常用来管理变化与依赖。评价设计时常提到*高内聚、低耦合*：高内聚表示一个模块中的数据和操作围绕清楚的职责组织；低耦合表示模块通过范围明确、相对稳定的接口协作，而不是了解彼此大量实现细节。耦合不可能消失，抽象本身也有成本，目标是让必要依赖清楚且可控制。

下面列出教材中常见的七项设计原则。其中前五项通常合称 SOLID，后两项补充了复用和对象协作方面的考虑。它们是帮助分析取舍的启发式原则，不是可以脱离需求机械套用的定律。

1. *开闭原则 (Open-Closed Principle, OCP)*

*对扩展开放，对修改关闭。*

如果某类变化经常发生，可以预先设置稳定的扩展点，使新增行为主要通过增加实现或配置完成，而不必反复改动已经验证的核心逻辑。例如检测器通过统一接口选择不同算法，新增实现时就不必修改调用者。这里的“关闭”不是禁止修改任何现有代码；需求变化、错误修复和不合适的抽象仍然需要修改。为从未出现的变化提前建立大量接口，反而会增加复杂度。

2. *单一职责原则 (Single Responsibility Principle, SRP)*

*一个模块应有一个主要的变化原因。*

单一职责不等于“一个类只能有一个函数”，而是把由不同需求或维护者驱动的职责分开。例如，相机参数解析与图像检测的变化原因不同，放在同一类中会让配置格式变化影响算法代码。职责划分也不能无限细化；一组围绕同一目标、共同维护不变量的操作可以保留在一个模块中。

3. *里氏替换原则 (Liskov Substitution Principle, LSP)*

*派生类型应能在不破坏约定的前提下替换基类型。*

替换原则关注行为契约，而不是禁止重写虚函数。派生类不应要求比基类更苛刻的前置条件，不应削弱承诺的结果，也应维持基类公开的不变量和错误语义。例如，若 `ICamera::Capture()` 约定成功时返回具有有效时间戳的图像，某个派生驱动就不能悄悄返回未初始化时间戳而仍声称成功。C++ 虚函数只提供动态分派机制，编译器不会自动验证这些行为契约；需要通过接口设计、文档和针对各实现的契约测试检查。

4. *依赖倒置原则 (Dependency Inversion Principle, DIP)*

*依赖于抽象，不要依赖于具体实现。*

包含业务策略的高层模块不应把某个具体设备或库的细节写死；高层策略与底层实现可以共同依赖由需求定义的稳定抽象。例如自动瞄准流程依赖 `ISerial` 的发送语义，真实串口和回放实现分别适配它。依赖倒置并不要求为每个类增加接口：不会替换、没有边界意义的实现直接依赖通常更简单。

5. *接口隔离原则 (Interface Segregation Principle, ISP)*

*客户端不应被迫依赖自己不用的能力。*

如果一个设备接口同时包含采图、曝光控制、固件升级和标定存储，仅读取图像的模块也会受到其他方法变化影响。可以按调用者需要拆成若干职责连贯的接口。拆分目标不是让每个接口只剩一个方法；接口过碎会增加对象组合与生命周期管理成本。

6. *合成复用原则 (Composite Reuse Principle, CRP)*

*优先使用对象组合，而不是继承来达到复用的目的。*

当需求是“使用某项能力”或运行时更换行为时，对象组合通常比为复用实现而继承更清楚，例如 `Tracker` 持有一个预测策略。继承适合表达稳定的“是一个”关系，并且派生类必须满足替换原则。组合也会产生接口和生命周期依赖，因此应根据关系语义选择，而不是把继承一律视为错误。

7. *迪米特法则 (Law of Demeter, LoD)*

*对象应只依赖完成职责所需的直接协作者。*

迪米特法则也称最少知识原则。它提醒调用者不要沿着很长的对象关系取得内部状态，例如 `robot.controller().serial().port().write(...)` 会把多层结构暴露给上层。由合适的模块提供意图明确的操作，可以减少内部结构变化向外传播。它并非按“认识的对象数量”机械计数；数据转换、诊断和性能关键路径有时需要更直接的访问，此时应把依赖和稳定性要求写清楚。


=== 常用设计模式详解
// 机器人开发中最实用的模式
// - 单例模式（Singleton）
//   经典实现与问题
//   现代 C++ 的线程安全实现（Meyers' Singleton）
//   应用场景：配置管理、日志系统、硬件抽象
//   滥用警告与替代方案
// - 工厂模式（Factory）
//   简单工厂 vs 工厂方法 vs 抽象工厂
//   应用场景：传感器驱动创建、算法策略选择
// - 观察者模式（Observer）
//   发布-订阅机制
//   与 ROS 话题机制的对比
//   应用场景：事件系统、状态通知
// - 策略模式（Strategy）
//   算法族的封装与切换
//   应用场景：不同的瞄准算法、路径规划策略
// - 状态模式（State）
//   有限状态机的面向对象实现
//   应用场景：机器人行为状态管理
// - 模板方法模式（Template Method）
//   定义算法骨架，子类实现细节
//   应用场景：图像处理流水线

下面选取六种在机器人项目中容易遇到的模式。重点不是记住类图，而是识别它们分别把哪种变化隔离开，又引入了什么代价。

==== 单例：限制实例数量

单例模式（Singleton）让某个类型只提供一个共享实例，并给调用者统一的访问入口。C++11 起，函数内 `static` 对象的初始化由语言保证不会被多个线程重复执行，因此常见实现可以写成：

```cpp
class Logger {
public:
    static Logger& Instance() {
        static Logger logger;
        return logger;
    }

    Logger(const Logger&) = delete;
    Logger& operator=(const Logger&) = delete;

private:
    Logger() = default;
};
```

这项保证只覆盖 `logger` 的初始化，不表示 `Logger` 的其他成员函数自动具备线程安全性。单例还会形成隐式全局依赖，使测试难以替换实例、初始化顺序和状态重置更复杂。对日志后端、配置和硬件连接，通常先考虑由程序入口创建对象并显式传给需要的模块；只有“进程内确实只能有一个实例”属于明确约束时，再采用单例并记录生命周期与并发规则。

==== 工厂：集中对象创建与选择

工厂模式（Factory）把“选择并创建哪种具体对象”从使用者中移出。例如程序根据配置创建工业相机或录像回放源，后续检测流程只依赖统一的 `IFrameSource` 接口：

```cpp
std::unique_ptr<IFrameSource> CreateFrameSource(const SourceConfig& config) {
    if (config.type == "camera") {
        return std::make_unique<IndustrialCamera>(config.camera);
    }
    if (config.type == "replay") {
        return std::make_unique<ReplaySource>(config.path);
    }
    throw std::invalid_argument("unknown frame source: " + config.type);
}
```

简单函数已经可以承担许多创建任务，不必为了使用“工厂”名称建立多层类继承。只有产品族需要共同变化、创建步骤复杂，或插件需要独立注册时，才值得进一步采用工厂方法、抽象工厂或注册表。工厂集中创建逻辑，也意味着配置校验和错误报告应在这一边界上设计清楚。

==== 观察者：一项变化通知多个接收者

观察者模式（Observer）让发布者在状态或事件变化时通知已注册的接收者，而不把每个接收者的具体类型写入发布者。它适合参数更新、状态通知和进程内事件分发。实现时最容易遗漏的是订阅生命周期：接收者销毁后必须解除注册，回调期间增删订阅者、回调重入以及跨线程调用也要有明确规则。可以用连接对象配合 RAII 自动取消订阅，或用 `weak_ptr` 避免发布者延长接收者生命周期。

ROS 2 话题同样具有发布与订阅关系，但它还涉及进程边界、序列化、执行器和 QoS，不能直接等同于一个进程内观察者列表。选择 ROS 话题还是普通回调，应看组件边界和通信需求，而不是只看结构名称相似。

==== 策略：替换一组算法

策略模式（Strategy）把完成同一职责的算法放在统一接口之后，使调用者可按配置或运行状态选择实现。例如跟踪器可以接收不同的数据关联策略，主流程只调用 `Associate()`。现代 C++ 中，策略既可以是虚接口，也可以是函数对象、lambda 或模板参数：运行时需要切换时使用动态多态，编译期固定且性能敏感时可考虑模板。若只有两个简单分支且不会独立演化，直接的条件语句可能比额外抽象更清楚。

==== 状态：把状态相关行为显式组织起来

状态模式（State）把不同状态下的行为与转换规则分别组织，适合状态较多、每个状态都有明显独立逻辑的机器人行为管理。例如搜索、跟踪、丢失恢复和安全停机可以各自处理事件，再返回下一状态。转换条件、超时和进入/退出动作应能从代码或状态图中查到，不能分散在多个回调的布尔变量中。

状态数量较少时，`enum class` 加集中式 `switch` 或数据驱动的转换表通常更直观；状态对象并非有限状态机的必需实现。无论采用哪种形式，都应测试非法事件、超时以及连续转换，而不只测试正常路径。

==== 模板方法：固定流程，开放局部步骤

模板方法（Template Method）由基类定义流程顺序，并把部分步骤留给派生类重写。例如图像处理基类可以固定“校验输入—预处理—检测—整理输出”的顺序，让不同检测器实现中间步骤。它适合流程骨架稳定、派生类型确实满足替换原则的情况。

这种模式把扩展点绑定在继承层次中，基类流程变化会影响所有派生类。若处理步骤需要自由组合或运行时调整，把每一步设计成可组合对象或函数流水线通常更灵活。选择模板方法之前，应先确认需要复用的是稳定流程，而不只是几行相同代码。

=== 单元测试
// 用测试保障代码质量
// - 为什么要写测试：信心与重构
// - 测试金字塔：单元测试、集成测试、端到端测试
// - Google Test 框架入门：
//   安装与 CMake 配置
//   TEST 宏与断言（EXPECT_* vs ASSERT_*）
//   测试夹具（Test Fixtures）
//   参数化测试
// - 测试驱动开发（TDD）简介
// - 什么样的代码容易测试
// - Mock 与依赖注入
// - 测试覆盖率
// - RoboMaster 中的测试实践：
//   算法模块的单元测试
//   通信协议的测试
//   仿真环境的价值
// === 单元测试

程序在一台机器和一组样例上运行成功，只能说明这些条件下没有观察到失败。修改函数、升级依赖或重构模块后，还需要检查原有行为是否保持。自动化测试把选定的输入、操作和预期结果保存为可重复执行的检查，使团队能更快发现测试覆盖范围内的回归；它不能证明代码对所有输入都正确，也不能取代实机联调和探索性测试。

==== 为什么要写测试

测试最直接的价值是检查具体需求。写完函数后，可以用临时 `main` 手动调用几次，但这些输入、操作和判断标准往往不会随代码保存。需求变化后，开发者还要依靠记忆重复操作。把稳定且重要的检查写成测试，就能在相同条件下反复执行，并把失败位置记录下来。

自动化测试的运行时间从毫秒到数小时不等。较快的测试可以在本地频繁运行，完整的硬件或仿真测试则适合按合并、定时任务或发布节点执行。测试失败表明某项检查不再满足；测试通过只支持已执行用例及断言，不代表其他模块或未覆盖输入没有受到影响。在 RoboMaster 算法调参中，还要固定数据集、配置和评价指标，才能判断结果变化来自代码还是输入条件。

测试也能支撑重构。重构的目标是在保持约定行为的前提下改变内部结构，因此应先明确哪些行为需要保持，并用单元、集成或端到端测试覆盖关键路径。重构后全部测试通过，可以说明这些检查没有发现差异，不能据此断言所有外部行为完全不变。对于原本没有测试的代码，可以先用特征测试记录当前可观察行为，再逐步调整结构。

测试还可以作为接口使用示例：它展示如何构造输入、调用函数以及检查输出。不过测试本身也可能遗漏断言、复制实现错误，或在需求改变后被错误地一起修改，因此同样需要审查和维护。行为背景、单位和设计理由仍适合写在接口文档中。

测试同样需要编写、维护和运行成本，应优先覆盖规则明确、经常修改、人工检查昂贵或失败影响大的部分。例如协议编解码、坐标变换和弹道计算通常适合自动化；相机线缆接触不良等物理问题则需要硬件检查。团队可以从曾经发生的缺陷和关键接口开始建立测试，而不必先追求数量。

==== 测试金字塔

软件测试可按覆盖范围、外部依赖和执行环境分类。测试金字塔是一个常见模型，用来提醒团队保留较多快速、范围较小的测试，同时用较少但必要的系统级测试检查模块协作。它是经验性结构，不规定所有项目都必须采用同一比例。

单元测试位于图的底层，通常针对一个函数、类或小型协作单元。它们尽量减少网络、硬件和真实时钟等外部依赖，以获得快速、可重复且容易定位失败的反馈。“单元”的边界取决于设计，不必为了形式把每个私有函数单独测试。

```
          /\
         /  \         端到端测试
        /----\        （少量，慢，昂贵）
       /      \
      /--------\      集成测试
     /          \     （适量，中等速度）
    /------------\
   /              \   单元测试
  /----------------\  （大量，快速，便宜）
```

集成测试位于中层，检查多个模块组合后的接口与数据约定。例如，把检测结果交给跟踪器，或让通信模块解析固定的协议数据包。它可能涉及数据库、文件、进程或设备模拟，因此通常比纯单元测试准备更复杂，却能发现单个模块测试看不到的坐标系、序列化和生命周期问题。

端到端测试（或系统测试）位于顶层，沿接近实际使用的路径检查完整场景。RoboMaster 项目可以在仿真或回放环境中运行从图像输入到云台指令输出的自瞄流程。它覆盖的组件多，失败时需要进一步定位，也更容易受到环境和时序变化影响；少量关键场景仍能提供其他层次无法替代的信息。

金字塔形状表达的是相对数量与反馈速度，而不是固定百分比。若大多数检查都只能通过完整机器人运行，反馈通常较慢且失败原因难以隔离；可以把可独立验证的协议、几何和算法行为下移到较小范围的测试。反过来，只有单元测试也无法检查部署、驱动和模块连接。团队应按系统风险配置各层测试。

本节主要介绍单元测试工具，并在后文补充集成、回放和仿真测试的使用边界。

==== Google Test 框架入门

Google Test（简称 gtest）是常用的开源 C++ 测试框架，提供断言、测试组织、参数化测试和过滤运行等功能。下面以系统已提供可被 CMake 查找的 GTest 包为前提。

Ubuntu 仓库可通过下列软件包安装，具体版本由发行版决定：

```bash
sudo apt install libgtest-dev
```

在 CMake 项目中使用 gtest，需要在 CMakeLists.txt 中添加相应配置：

```cmake
cmake_minimum_required(VERSION 3.14)
project(my_project)

# 启用测试
enable_testing()

# 查找 GTest
find_package(GTest REQUIRED)

# 添加可执行文件
add_executable(my_tests
    test/test_math_utils.cpp
    test/test_detector.cpp
)

# 链接被测库和带 main 函数的 GTest 目标
target_link_libraries(my_tests PRIVATE
    my_library
    GTest::gtest_main
)

# 注册测试
include(GoogleTest)
gtest_discover_tests(my_tests)
```

如果使用 `GTest::gtest_main`，gtest 会提供 `main` 函数，测试目标中不要再加入自定义 `test_main.cpp`。若改为链接 `GTest::gtest`，则需要在测试文件中添加：

```cpp
#include <gtest/gtest.h>

int main(int argc, char* argv) {
    testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
```

使用 `TEST` 宏定义测试，第一个参数是测试套件名，第二个参数是测试名：

```cpp
#include <gtest/gtest.h>
#include "math_utils.h"

// 测试套件：MathUtils，测试名：AddPositiveNumbers
TEST(MathUtils, AddPositiveNumbers) {
    EXPECT_EQ(Add(1, 2), 3);
    EXPECT_EQ(Add(10, 20), 30);
}

TEST(MathUtils, AddNegativeNumbers) {
    EXPECT_EQ(Add(-1, -2), -3);
    EXPECT_EQ(Add(-10, 20), 10);
}

TEST(MathUtils, AddZero) {
    EXPECT_EQ(Add(0, 0), 0);
    EXPECT_EQ(Add(5, 0), 5);
    EXPECT_EQ(Add(0, 5), 5);
}
```

运行测试：

```bash
# 配置与构建
cmake -S . -B build
cmake --build build

# 通过 CTest 运行 CMake 注册的全部测试
ctest --test-dir build --output-on-failure

# 也可直接运行测试程序并使用 GTest 过滤器
./build/my_tests --gtest_filter=MathUtils.*

# 运行特定测试
./build/my_tests --gtest_filter=MathUtils.AddPositiveNumbers
```

测试输出会显示每个测试的结果：

```
[==========] Running 3 tests from 1 test suite.
[----------] Global test environment set-up.
[----------] 3 tests from MathUtils
[ RUN      ] MathUtils.AddPositiveNumbers
[       OK ] MathUtils.AddPositiveNumbers (0 ms)
[ RUN      ] MathUtils.AddNegativeNumbers
[       OK ] MathUtils.AddNegativeNumbers (0 ms)
[ RUN      ] MathUtils.AddZero
[       OK ] MathUtils.AddZero (0 ms)
[----------] 3 tests from MathUtils (0 ms total)

[----------] Global test environment tear-down
[==========] 3 tests from 1 test suite ran. (0 ms total)
[  PASSED  ] 3 tests.
```

==== 断言：EXPECT 与 ASSERT

gtest 提供了丰富的断言宏来验证条件。断言分为两类：`EXPECT_*` 和 `ASSERT_*`。两者的区别在于失败后的行为：`EXPECT_*` 失败后会继续执行后续的断言，而 `ASSERT_*` 失败后会立即终止当前测试。

一般情况下优先使用 `EXPECT_*`，这样一次运行可以发现多个问题。当后续断言依赖于前面的条件成立时（比如指针非空），使用 `ASSERT_*` 避免后续代码崩溃。

```cpp
TEST(VectorTest, AccessElements) {
    std::vector<int> v;
    v.push_back(1);
    v.push_back(2);
    
    // 使用 ASSERT 检查前提条件
    ASSERT_FALSE(v.empty());  // 如果失败，后续代码不安全
    ASSERT_EQ(v.size(), 2);
    
    // 使用 EXPECT 检查具体值
    EXPECT_EQ(v[0], 1);
    EXPECT_EQ(v[1], 2);
}
```

常用的断言宏包括：

```cpp
// 布尔断言
EXPECT_TRUE(condition);
EXPECT_FALSE(condition);

// 相等性断言
EXPECT_EQ(expected, actual);  // expected == actual
EXPECT_NE(val1, val2);        // val1 != val2

// 比较断言
EXPECT_LT(val1, val2);        // val1 < val2
EXPECT_LE(val1, val2);        // val1 <= val2
EXPECT_GT(val1, val2);        // val1 > val2
EXPECT_GE(val1, val2);        // val1 >= val2

// 浮点数断言（考虑精度误差）
EXPECT_FLOAT_EQ(expected, actual);   // float 相等
EXPECT_DOUBLE_EQ(expected, actual);  // double 相等
EXPECT_NEAR(val1, val2, tolerance);  // 差值在容差内

// 字符串断言
EXPECT_STREQ(str1, str2);     // C 字符串相等
EXPECT_STRNE(str1, str2);     // C 字符串不等

// 异常断言
EXPECT_THROW(statement, exception_type);  // 抛出指定异常
EXPECT_ANY_THROW(statement);              // 抛出任何异常
EXPECT_NO_THROW(statement);               // 不抛出异常

// 自定义失败消息
EXPECT_EQ(result, expected) << "计算结果不正确，输入为: " << input;
```

浮点计算结果通常不应直接用 `EXPECT_EQ` 与十进制期望值比较。`EXPECT_FLOAT_EQ` 和 `EXPECT_DOUBLE_EQ` 使用 GTest 规定的近似规则；当业务允许的误差有明确单位和范围时，`EXPECT_NEAR` 往往更容易表达需求。对于本应产生精确值、无穷大或 NaN 的接口，则应按接口语义选择专门检查。

```cpp
TEST(FloatTest, Precision) {
    double result = 0.1 + 0.2;
    
    // 不好：可能因精度问题失败
    // EXPECT_EQ(result, 0.3);
    
    // 好：考虑浮点精度
    EXPECT_DOUBLE_EQ(result, 0.3);
    EXPECT_NEAR(result, 0.3, 1e-10);
}
```

==== 测试夹具

当多个测试需要相同的初始化代码时，可以使用测试夹具（Test Fixture）来避免重复。测试夹具是一个继承自 `testing::Test` 的类，在 `SetUp()` 方法中进行初始化，在 `TearDown()` 方法中进行清理。

```cpp
#include <gtest/gtest.h>
#include "detector.h"

class DetectorTest : public testing::Test {
protected:
    void SetUp() override {
        // 每个测试前执行
        config_.model_path = "test_model.onnx";
        config_.confidence_threshold = 0.5;
        detector_ = std::make_unique<ArmorDetector>(config_);
        ASSERT_TRUE(detector_->Init());
        
        // 加载测试图像
        test_image_ = cv::imread("test_data/armor_image.jpg");
        ASSERT_FALSE(test_image_.empty());
    }
    
    void TearDown() override {
        // 每个测试后执行（可选）
        detector_.reset();
    }
    
    // 测试中可以使用的成员
    DetectorConfig config_;
    std::unique_ptr<ArmorDetector> detector_;
    cv::Mat test_image_;
};

// 使用 TEST_F 而不是 TEST
TEST_F(DetectorTest, DetectsArmorInTestImage) {
    auto results = detector_->Detect(test_image_, 0.0);
    EXPECT_FALSE(results.empty());
}

TEST_F(DetectorTest, ReturnsEmptyForBlankImage) {
    cv::Mat blank(480, 640, CV_8UC3, cv::Scalar(0, 0, 0));
    auto results = detector_->Detect(blank, 0.0);
    EXPECT_TRUE(results.empty());
}

TEST_F(DetectorTest, ConfidenceAboveThreshold) {
    auto results = detector_->Detect(test_image_, 0.0);
    for (const auto& armor : results) {
        EXPECT_GE(armor.confidence, config_.confidence_threshold);
    }
}
```

测试夹具的常规执行顺序是：构造函数 → `SetUp()` → 测试体 → `TearDown()` → 析构函数。每个测试会创建新的夹具实例，因此夹具的非静态成员不会直接共享；文件、全局变量、单例和外部设备等状态仍可能造成测试间影响，需要另行清理。

如果同一测试套件需要复用耗时较高且可安全共享的资源，例如只读模型，可以使用 `SetUpTestSuite()` 和 `TearDownTestSuite()` 静态方法，它们在该测试套件前后各执行一次。共享可变状态会让测试依赖执行顺序，应尽量避免或在每个测试前恢复：

```cpp
class ExpensiveTest : public testing::Test {
protected:
    static void SetUpTestSuite() {
        // 整个测试套件只执行一次
        shared_model_ = LoadLargeModel();
    }
    
    static void TearDownTestSuite() {
        shared_model_.reset();
    }
    
    static std::shared_ptr<Model> shared_model_;
};

std::shared_ptr<Model> ExpensiveTest::shared_model_;
```

==== 参数化测试

当你需要用不同的输入测试同一个逻辑时，参数化测试可以避免编写大量重复的测试代码。

```cpp
#include <gtest/gtest.h>

// 定义参数类型
struct AngleTestParam {
    double input_degrees;
    double expected_radians;
};

constexpr double kPi = 3.14159265358979323846;

// 参数化测试夹具
class AngleConversionTest : public testing::TestWithParam<AngleTestParam> {};

// 参数化测试
TEST_P(AngleConversionTest, DegreesToRadians) {
    AngleTestParam param = GetParam();
    double result = DegreesToRadians(param.input_degrees);
    EXPECT_NEAR(result, param.expected_radians, 1e-6);
}

// 提供测试参数
INSTANTIATE_TEST_SUITE_P(
    CommonAngles,
    AngleConversionTest,
    testing::Values(
        AngleTestParam{0, 0},
        AngleTestParam{90, kPi / 2},
        AngleTestParam{180, kPi},
        AngleTestParam{360, 2 * kPi},
        AngleTestParam{-90, -kPi / 2}
    )
);
```

对于简单类型，可以使用更简洁的写法：

```cpp
class PrimeTest : public testing::TestWithParam<int> {};

TEST_P(PrimeTest, IsPrime) {
    int n = GetParam();
    EXPECT_TRUE(IsPrime(n));
}

INSTANTIATE_TEST_SUITE_P(
    Primes,
    PrimeTest,
    testing::Values(2, 3, 5, 7, 11, 13, 17, 19)
);
```

`testing::Values` 之外还有其他参数生成器：

```cpp
// 半开区间 [start, end)，end 不会成为测试参数
testing::Range(start, end, step);

// 布尔值
testing::Bool();  // true, false

// 组合
testing::Combine(testing::Values(1, 2), testing::Values("a", "b"));
// 生成 (1, "a"), (1, "b"), (2, "a"), (2, "b")
```

==== 测试驱动开发

测试驱动开发（Test-Driven Development，TDD）是一种先用测试描述下一小步行为、再编写实现的方法。常见过程称为“红—绿—重构”：

1. *红*：先写一个会失败的测试，明确你要实现什么功能
2. *绿*：写最少的代码让测试通过
3. *重构*：在测试保护下改进代码结构

```cpp
// 第一步：写一个失败的测试
TEST(Calculator, Add) {
    Calculator calc;
    EXPECT_EQ(calc.Add(2, 3), 5);
}

// 此时编译失败，因为 Calculator 类不存在

// 第二步：写最少的代码让测试通过
class Calculator {
public:
    int Add(int a, int b) {
        return a + b;  // 最简单的实现
    }
};

// 测试通过

// 第三步：重构（如果需要）
// 当前实现已经足够简单，无需重构

// 继续循环：添加更多测试
TEST(Calculator, Subtract) {
    Calculator calc;
    EXPECT_EQ(calc.Subtract(5, 3), 2);
}

// 然后实现 Subtract...
```

先写调用示例会促使开发者尽早考虑接口、输入与可观察结果；小步运行测试也能缩短部分缺陷的反馈时间。不过，TDD 不会自动保证设计良好或测试充分：测试可能只重复实现思路，也可能遗漏系统集成与非功能需求。

对规则明确的算法、协议和数据处理模块，TDD 往往容易实施。探索性原型、GUI 交互或必须依赖真实硬件的行为，可能更适合先探索需求，再补充可稳定复现的测试。是否采用 TDD 与是否需要测试是两个问题，团队可以只在合适的模块使用这套开发节奏。

==== 什么样的代码容易测试

测试难度通常受依赖、状态和可观察接口影响。理解这些因素有助于在不扭曲业务设计的前提下提高可测试性。

纯函数最容易测试。纯函数的输出只依赖于输入，没有副作用，不依赖外部状态。给定相同的输入，总是产生相同的输出。这样的函数测试起来非常简单：准备输入，调用函数，检查输出。

```cpp
// 容易测试：纯函数
double CalculateDistance(const Point& a, const Point& b) {
    return std::sqrt(std::pow(a.x - b.x, 2) + std::pow(a.y - b.y, 2));
}

TEST(Geometry, CalculateDistance) {
    Point a{0, 0};
    Point b{3, 4};
    EXPECT_DOUBLE_EQ(CalculateDistance(a, b), 5.0);
}
```

依赖注入让代码更容易测试。如果一个类在内部创建它的依赖，测试时就很难替换这些依赖。但如果依赖是从外部传入的，测试时就可以传入模拟的依赖。

```cpp
// 难以测试：内部创建依赖
class Tracker {
public:
    void Update() {
        Camera camera;  // 内部创建，无法替换
        auto image = camera.Capture();
        // ...
    }
};

// 容易测试：依赖注入
class Tracker {
public:
    explicit Tracker(std::shared_ptr<ICamera> camera) 
        : camera_(camera) {}
    
    void Update() {
        auto image = camera_->Capture();  // 可以注入模拟相机
        // ...
    }

private:
    std::shared_ptr<ICamera> camera_;
};

// 测试时使用模拟相机
class MockCamera : public ICamera {
public:
    cv::Mat Capture() override {
        return test_image_;  // 返回预设的测试图像
    }
    cv::Mat test_image_;
};

TEST(Tracker, UpdateWithMockCamera) {
    auto mock_camera = std::make_shared<MockCamera>();
    mock_camera->test_image_ = cv::imread("test_image.jpg");
    
    Tracker tracker(mock_camera);
    tracker.Update();
    // 验证结果...
}
```

职责集中、输入输出清楚的函数通常更容易测试。较长函数如果混合了 I/O、状态修改和计算，可以按职责提取独立计算或边界适配；但把连续逻辑机械拆成大量只有一两行的函数，不一定提高可读性，也不需要直接测试每个实现细节。

尽量避免隐藏的全局状态。全局变量或单例可能让测试相互影响，并使输入条件不完整。无法立即移除时，可以集中访问入口、明确生命周期并在夹具中恢复状态；长期方案通常是把依赖显式传入。

==== Mock 与依赖注入

当被测代码依赖数据库、网络或硬件时，始终使用真实依赖可能让小范围测试变慢，并受设备状态影响。测试替身（test double）可以在这类测试中提供可控行为：stub 返回预设结果，fake 提供简化但可运行的实现，mock 则重点验证调用参数、次数或顺序。真实依赖仍需要集成测试覆盖，否则替身与实际行为可能逐渐不一致。

Google Mock 与 Google Test 一起发布，提供声明 mock 方法、匹配参数和设置动作的工具：

```cpp
#include <gmock/gmock.h>

// 定义接口
class ISerial {
public:
    virtual ~ISerial() = default;
    virtual bool Open(const std::string& port) = 0;
    virtual bool Write(const std::vector<uint8_t>& data) = 0;
    virtual std::vector<uint8_t> Read(size_t size) = 0;
};

// 创建 Mock 类
class MockSerial : public ISerial {
public:
    MOCK_METHOD(bool, Open, (const std::string& port), (override));
    MOCK_METHOD(bool, Write, (const std::vector<uint8_t>& data), (override));
    MOCK_METHOD(std::vector<uint8_t>, Read, (size_t size), (override));
};

// 使用 Mock 测试
TEST(Communication, SendCommand) {
    MockSerial mock_serial;
    
    // 设置期望：Open 被调用一次，返回 true
    EXPECT_CALL(mock_serial, Open("/dev/ttyUSB0"))
        .Times(1)
        .WillOnce(testing::Return(true));
    
    // 设置期望：Write 被调用，参数匹配，返回 true
    EXPECT_CALL(mock_serial, Write(testing::_))
        .Times(1)
        .WillOnce(testing::Return(true));
    
    // 被测对象使用 Mock
    Commander commander(&mock_serial);
    bool result = commander.SendAimCommand(1.5, 2.0);
    
    EXPECT_TRUE(result);
    // Mock 会自动验证期望是否被满足
}
```

GMock 提供多种匹配器和动作：

```cpp
using namespace testing;

// 匹配器
EXPECT_CALL(mock, Method(Eq(5)));        // 参数等于 5
EXPECT_CALL(mock, Method(Gt(0)));        // 参数大于 0
EXPECT_CALL(mock, Method(_));            // 任意参数
EXPECT_CALL(mock, Method(StartsWith("prefix")));  // 字符串前缀

// 调用次数
EXPECT_CALL(mock, Method(_)).Times(3);           // 恰好 3 次
EXPECT_CALL(mock, Method(_)).Times(AtLeast(1));  // 至少 1 次
EXPECT_CALL(mock, Method(_)).Times(AtMost(5));   // 至多 5 次

// 返回值
EXPECT_CALL(mock, Method(_)).WillOnce(Return(42));
EXPECT_CALL(mock, Method(_)).WillRepeatedly(Return(0));

// 按顺序
{
    InSequence seq;
    EXPECT_CALL(mock, First());
    EXPECT_CALL(mock, Second());
    EXPECT_CALL(mock, Third());
}
```

依赖注入是让依赖可替换的一种设计方法：类从外部接收协作者，而不是在业务方法中写死具体设备。除了便于测试，它也能明确模块边界。并非所有对象都需要抽象接口，所有权也应通过值、引用、`unique_ptr` 或 `shared_ptr` 准确表达。

构造函数注入是最常用的方式：

```cpp
class AutoAim {
public:
    AutoAim(std::shared_ptr<IDetector> detector,
            std::shared_ptr<ITracker> tracker,
            std::shared_ptr<IPredictor> predictor)
        : detector_(detector), tracker_(tracker), predictor_(predictor) {}
    
    // ...

private:
    std::shared_ptr<IDetector> detector_;
    std::shared_ptr<ITracker> tracker_;
    std::shared_ptr<IPredictor> predictor_;
};
```

Setter 注入可用于运行期间确实允许更换的依赖，但对象在设置前可能处于无效状态。对于构造后必须可用的依赖，优先使用构造函数；可选依赖也可以通过带默认实现的构造参数或 `std::optional` 明确表达。下面的写法只有在“尚未设置输出端”也具有明确定义的行为时才安全：

```cpp
class Logger {
public:
    void SetOutput(std::shared_ptr<IOutput> output) {
        output_ = output;
    }
private:
    std::shared_ptr<IOutput> output_;  // nullptr 表示关闭输出；Write() 需处理。
};
```

==== 测试覆盖率

测试覆盖率记录一次测试运行执行了哪些代码结构。它描述执行范围，不衡量断言是否正确，也不表示输入空间覆盖程度。常见指标包括：

- *行覆盖率*：执行了多少行代码
- *分支覆盖率*：执行了多少分支（if/else 的每个分支）
- *函数覆盖率*：调用了多少函数

使用 gcov/lcov 可以生成覆盖率报告：

```bash
# 编译时启用覆盖率
g++ -fprofile-arcs -ftest-coverage -o my_tests my_tests.cpp my_code.cpp

# 运行测试
./my_tests

# 生成报告
lcov --capture --directory . --output-file coverage.info
genhtml coverage.info --output-directory coverage_report

# 在浏览器中查看
xdg-open coverage_report/index.html
```

CMake 项目应尽量把覆盖率选项限制在相关目标，而不是改写全局编译标志。下面以 GCC/Clang 的 `--coverage` 为例；被测库需要插桩，最终测试程序也需要链接覆盖率运行库：

```cmake
option(ENABLE_COVERAGE "Enable coverage reporting" OFF)

if(ENABLE_COVERAGE)
    target_compile_options(my_library PRIVATE --coverage -O0 -g)
    target_compile_options(my_tests PRIVATE --coverage -O0 -g)
    target_link_options(my_tests PRIVATE --coverage)
endif()
```

覆盖率适合用来发现从未执行的关键分支。100% 行覆盖率仍可能遗漏边界值、线程交错和错误断言，因此不能解释为“没有缺陷”。覆盖率阈值应根据模块风险和现有基线确定；核心协议与算法通常需要更仔细地检查分支，生成代码或薄适配层则可采用不同要求。比单一百分比更重要的是了解哪些重要行为尚未测试。

==== RoboMaster 中的测试实践

在 RoboMaster 项目中，可以按失败影响、修改频率和复现成本安排测试。下面给出算法、协议、坐标变换和系统仿真的例子。

检测、跟踪、预测和弹道解算包含大量可由固定输入检查的计算，适合把数学约定、边界条件和曾经出现的缺陷写成单元或数据驱动测试。期望值应来自独立公式、标注数据或明确性质，不能直接复制被测实现。

```cpp
#include <cmath>

// 弹道解算测试
class BallisticSolverTest : public testing::Test {
protected:
    void SetUp() override {
        solver_ = std::make_unique<BallisticSolver>(24.0);  // 24 m/s 弹速
    }
    
    std::unique_ptr<BallisticSolver> solver_;
};

TEST_F(BallisticSolverTest, SameHeightTarget) {
    // 假设求解器采用无空气阻力、低弹道、弧度制模型。
    // 同高度目标仍需用正仰角补偿重力下坠。
    double pitch = solver_->Solve(5.0, 0.0);  // 5 米远，高度差为 0
    constexpr double kGravity = 9.80665;
    double expected = 0.5 * std::asin(kGravity * 5.0 / (24.0 * 24.0));
    EXPECT_NEAR(pitch, expected, 1e-6);
}

TEST_F(BallisticSolverTest, ElevatedTarget) {
    double level_pitch = solver_->Solve(5.0, 0.0);
    double elevated_pitch = solver_->Solve(5.0, 2.0);
    EXPECT_GT(elevated_pitch, level_pitch);
}

TEST_F(BallisticSolverTest, DistanceAffectsDrop) {
    // 距离越远，下坠补偿越大
    double pitch_near = solver_->Solve(3.0, 0.0);
    double pitch_far = solver_->Solve(8.0, 0.0);
    EXPECT_GT(pitch_far, pitch_near);
}
```

通信协议测试可以检查数据包的打包和解析行为：

```cpp
class ProtocolTest : public testing::Test {
protected:
    Protocol protocol_;
};

TEST_F(ProtocolTest, PackAimCommand) {
    AimCommand cmd{1.5f, -0.3f, true};
    auto packet = protocol_.Pack(cmd);
    
    EXPECT_EQ(packet.size(), Protocol::kAimCommandSize);
    EXPECT_EQ(packet[0], Protocol::kHeader);
    EXPECT_EQ(packet[1], Protocol::kAimCommandId);
}

TEST_F(ProtocolTest, UnpackAimCommand) {
    AimCommand expected{1.5f, -0.3f, true};
    std::vector<uint8_t> packet = protocol_.Pack(expected);
    auto cmd = protocol_.Unpack<AimCommand>(packet);
    
    ASSERT_TRUE(cmd.has_value());
    EXPECT_NEAR(cmd->yaw, 1.5f, 0.001f);
    EXPECT_NEAR(cmd->pitch, -0.3f, 0.001f);
    EXPECT_TRUE(cmd->fire);
}

TEST_F(ProtocolTest, RejectInvalidPacket) {
    std::vector<uint8_t> invalid = {0x00, 0x01, 0x02};  // 错误的帧头
    auto cmd = protocol_.Unpack<AimCommand>(invalid);
    EXPECT_FALSE(cmd.has_value());
}
```

往返测试能检查 `Pack` 与 `Unpack` 是否彼此兼容，但两边若以相同方式写错字节序，它仍可能通过。因此协议还应准备独立的固定字节序列，逐字段检查长度、端序、校验和及异常包处理，并与电控端使用同一份协议版本核对。

坐标变换测试应选择结果能独立计算的简单场景，例如单位变换、单轴 90° 旋转和已知平移。下面假设测试夹具的 `BuildKnownTransform()` 构造“绕世界 z 轴旋转 90°，再平移 (1, 2, 3)”的变换；期望值由这一定义手工计算，而不是调用被测代码生成：

```cpp
TEST(CoordinateTransform, CameraToWorld) {
    Transform tf = BuildKnownTransform();
    
    Point3D point_camera{1.0, 0.0, 5.0};
    Point3D point_world = tf.CameraToWorld(point_camera);
    
    EXPECT_NEAR(point_world.x, 1.0, 0.001);
    EXPECT_NEAR(point_world.y, 3.0, 0.001);
    EXPECT_NEAR(point_world.z, 8.0, 0.001);
}

TEST(CoordinateTransform, RoundTrip) {
    // 变换后再逆变换应该得到原始点
    Transform tf = BuildKnownTransform();
    Point3D original{1.0, 2.0, 3.0};
    Point3D transformed = tf.CameraToWorld(original);
    Point3D back = tf.WorldToCamera(transformed);
    
    EXPECT_NEAR(back.x, original.x, 0.001);
    EXPECT_NEAR(back.y, original.y, 0.001);
    EXPECT_NEAR(back.z, original.z, 0.001);
}
```

往返测试可以检查正逆接口的一致性，但如果两个方向共享同一个坐标系错误，也可能相互抵消。因此还需要使用手工可验证的基准点检查轴方向、旋转顺序、单位和左右手系。

Gazebo、Unity 等仿真器可以提供可控的机器人运动和传感器输入，用于检查完整流程、故障处理及消息连接。较快且稳定的场景可以在每次合并时运行，耗时或含随机性的场景则可定时运行并保存种子和环境版本。仿真模型与真实相机噪声、延迟、碰撞和执行器响应存在差异，常称仿真到现实差距（sim-to-real gap）；仿真结果只能验证模型覆盖的范围，发布前仍需实机测试。

测试需要随接口和需求维护。发现缺陷后，如果能够稳定构造触发条件，可以先增加会失败的回归测试，再修复实现；该测试以后能检查同一已知路径是否再次出现。适合自动运行的测试可接入持续集成，并明确哪些硬件或长时间场景没有在普通流水线中执行。

一套有效的测试策略不是追求最多用例，而是在可接受的维护成本下覆盖关键行为，并准确解释每次通过或失败能说明什么。这样，后续修改才有可比较的基线。


=== 调试技巧
// 高效定位问题
// - 调试的心态：科学方法论
// - printf/cout 调试法的局限
// - GDB 调试器：
//   基本命令（run, break, next, step, continue, print）
//   查看调用栈（backtrace）
//   条件断点与观察点
//   调试多线程程序
//   调试 core dump
//   GDB TUI 模式
// - VS Code + GDB 图形化调试
// - 日志系统设计：
//   日志级别（DEBUG, INFO, WARN, ERROR, FATAL）
//   结构化日志
//   日志轮转
//   spdlog 库简介
// - 内存调试：
//   Valgrind 检测内存泄漏
//   AddressSanitizer (ASan)
//   常见内存问题模式
// - 常见 bug 类型与排查思路

调试的第一步是把现象写成可重复的观察：使用什么输入和配置，期望结果是什么，实际结果是什么，从哪个版本开始出现。日志或一次崩溃栈可以提供线索，但“最后出现的消息”不一定就是原因。每提出一个解释，都应寻找能区分它与其他主要可能性的检查，例如固定回放输入、禁用单个模块或比较修改前后的同一路径。

`std::cout`、`printf` 和日志适合观察程序经过哪些阶段及关键数据，但高频同步输出会改变时序，并可能成为新的 I/O 开销。长期日志应区分 DEBUG、INFO、WARN 和 ERROR 等级，记录时间戳、线程或节点、帧序号和必要上下文，并设置轮转与容量上限。不要把令牌、个人信息或完整敏感报文写入日志；时间测量还要说明使用的时钟域。

需要暂停程序检查控制流时，可以使用 gdb。下面是一组最基本的交互命令：

```text
gdb ./build/armor_detector
(gdb) break Detector::Detect  # 在函数入口设置断点
(gdb) run --replay test.avi   # 带参数启动程序
(gdb) next                    # 执行下一行，不进入普通函数调用
(gdb) step                    # 执行下一行，并尝试进入函数调用
(gdb) print frame_id          # 查看当前可用变量
(gdb) backtrace               # 查看当前线程调用栈
(gdb) continue                # 继续到下一个断点或程序结束
```

条件断点可写成 `break detector.cpp:87 if frame_id == 120`，观察点 `watch variable` 会在内存值变化时暂停；硬件观察点数量有限，软件实现可能很慢。多线程程序可用 `info threads` 和 `thread apply all backtrace` 查看各线程，但单次栈快照只能说明暂停时的位置。附加调试器和断点都会改变线程调度，竞态问题还需要 ThreadSanitizer、重复运行或更有针对性的同步检查。

程序崩溃时，带调试符号且与运行版本匹配的 core dump 有助于恢复信号、线程与调用栈；core 是否生成及保存哪些页面受系统配置限制。“计算机系统基础”一章已经介绍 gdb、Valgrind、ASan 与 core dump 的边界。遇到越界、释放后使用或泄漏时，应在能覆盖故障路径的输入上运行相应工具，并记住一次无报告的执行不能排除其他路径的问题。

调试结束前，应保存最小复现条件，增加能覆盖该已知问题的回归测试，并在原始环境复测。只有能通过干预把观察到的故障与主要替代解释区分开时，才适合把某项机制称为已确认原因。

=== 性能分析与优化

性能优化首先需要明确目标：提高吞吐量、降低端到端延迟、减少截止时间违约，还是控制 CPU 与内存占用。不同目标可能要求不同方案。一个实用顺序是：测量现状 $arrow.r$ 定位主要开销 $arrow.r$ 提出并实施单项改动 $arrow.r$ 在相同条件下复测，同时检查输出正确性。否则，局部函数变快可能只是把等待、分配或复制移到了其他阶段。

对比前后版本时，应尽量使用同一组输入、目标机器、构建类型、线程配置和预热方式，并进行多次重复。无法固定的温度、频率调节和后台负载也应记录。只有在这些测试条件内，测得的差异才能支持本次优化效果；还不能直接推广到其他板卡或比赛负载。

测量的起点是计时。C++ 里用 `std::chrono`，注意选对时钟：

```cpp
#include <chrono>

auto t0 = std::chrono::steady_clock::now();
detector.Detect(frame, frame_timestamp);
auto t1 = std::chrono::steady_clock::now();

auto ms = std::chrono::duration<double, std::milli>(t1 - t0).count();
```

测量持续时间应使用 `steady_clock`。它保证时间点不会倒退，适合计算经过时长。`system_clock` 表示可转换为日历时间的系统时钟，可能受到手动设置或系统校时影响，更适合记录事件发生的日期与时间，而不是性能区间。计时代码本身、日志和同步也会产生开销，测量很短的操作时应批量迭代并估计这部分影响。

单次计时不足以描述性能。同一段代码的耗时会受到缓存状态、调度抢占、CPU 频率和输入内容影响，应把结果视为分布。平均值可用于估计长期吞吐量；有截止时间的任务还应报告中位数、较高分位数、观测到的最大值和超预算比例。例如 100 fps 对应 10 ms 的输入周期，如果串行检测偶尔耗时 25 ms，就可能形成积压或触发丢帧，实际结果取决于队列容量和丢弃策略。样本中的最大值也不是理论最坏情况，只是当前测量窗口内的观察值。

Google Benchmark 适合对小段代码做重复微基准，并可自动选择迭代次数、组织多组参数。端到端帧延迟仍应在实际流水线中记录，因为微基准通常不包含线程调度、设备 I/O 和队列等待。

`perf`、火焰图、Valgrind 和系统调用跟踪的基本用法已在“计算机系统基础”一章介绍，其中的自瞄掉帧内容是展示证据顺序的教学案例。本节不重复命令，重点放在优化决策。

优化顺序由测量结果决定，但可以依次检查几类常见机会。首先确认算法复杂度是否随目标数或像素数快速增长，例如在满足相同语义时，用排序后的扫描替代全量两两配对。随后检查数据布局与访问顺序、重复计算、不必要的数据转换以及频繁分配。预分配和对象复用能否改善性能，需要结合对象生命周期与内存上限验证。

传递大型对象时要区分对象头和其拥有的数据。`cv::Mat` 的普通复制通常只复制矩阵头并增加共享数据的引用计数，`clone()` 才会复制像素；但浅复制仍有引用计数、共享生命周期和并发访问语义，不能概括为“按值传递没有代价”。是否改用引用、移动或深复制，应先满足所有权和可修改性要求。

多线程可能提高可并行阶段的吞吐量，也会增加同步、调度、队列和调试成本；应先确认热点可并行，并测量端到端效果。比赛使用的构建通常会启用优化，但仍要在与部署一致的二进制上分析。`Release` 与调试构建的行为和性能可能不同，优化也不会修复数据竞争、越界等未定义行为。

进阶篇的性能优化章节会把这些方法用于 RoboMaster 图像流水线，讨论阶段延迟、板卡与推理引擎、CPU 亲和性、调度策略和端到端延迟预算。相关数字只有在注明硬件、软件版本和负载后才具有可比性。

=== 文档编写
// 代码之外的工程产出
// - 文档的价值：写给未来的自己和队友
// - 代码即文档：自解释的命名与结构
// - 有效注释：何时写、写什么
// - README 的标准结构
// - API 文档：
//   Doxygen 入门
//   文档注释规范
//   生成 HTML/PDF 文档
// - 项目文档类型：
//   需求文档
//   设计文档
//   用户手册
//   变更日志（CHANGELOG）
// - Markdown 写作技巧
// - 文档即代码：版本控制与持续更新
// - RoboMaster 文档实践：
//   赛季交接文档的重要性
//   硬件接口文档
//   调试手册
// === 文档编写

代码精确描述计算机要执行的实现，文档则面向使用者和维护者补充目标、操作步骤、接口约定与设计背景。调试陌生模块、交接赛季项目或重新使用旧库时，构建命令、参数单位和已知限制往往无法仅从源码快速获得。文档的重点不是篇幅，而是让目标读者能找到完成任务所需且与当前版本对应的信息。

==== 文档的价值

文档可以降低重复沟通成本。若构建方法、模块职责和常见故障只能由某个人口头说明，提问者必须等待，对方也会反复回答。把稳定答案写在容易找到的位置后，讨论就可以集中在新问题上。文档未覆盖或表述不清时，仍应回答并据此补充，而不是只让读者自行寻找。

文档还能保存容易随人员变化而丢失的信息，例如为何选择当前坐标系、某项参数由哪次标定得到、哪些替代方案已经验证过。写下信息并不等于永久保存：链接会失效，规则会变化，结论也可能被新证据推翻，所以还要标注适用版本、日期、负责人或验证条件。

写设计说明也能帮助作者检查方案是否完整：需求、数据流、失败处理和取舍若无法明确写出，可能提示仍有问题需要讨论。不过，难以解释也可能来自读者背景或写作方式，不能单凭文档难写就断定设计有错。对影响多个模块的改动，先写简短设计提案并让相关成员审阅，通常比实现后再补背景更容易调整。

RoboMaster 团队每年都有成员加入和离开，交接文档应让新成员先了解系统范围、运行入口和当前未解决问题，再结合代码、测试与实机操作逐步验证。文档可以减少重复探索，但不能替代带教和实际操作。

==== 代码即文档

“代码即文档”（Code as Documentation）强调源码本身也应便于阅读。源码是当前实现行为的重要依据，但不是所有问题的最佳说明形式：用户不应为查找安装命令而阅读构建脚本，设计取舍也很少能由控制流完整表达。

清晰命名可以减少最基本的猜测。`CalculateProjectileDropCompensation` 比 `Calc` 更明确，`remaining_ammo` 也比脱离上下文的 `n` 提供更多信息。但名称仍无法说明采用的弹道模型、输入单位和无解时的行为，这些内容需要类型、接口约定或文档共同表达。

代码结构也会传递职责关系。把共同维护一组不变量的操作放在一起，让模块通过范围明确的接口协作，读者更容易跟踪数据流。函数长度或数量不是唯一标准：过多跳转同样会妨碍理解，应根据职责和抽象层次拆分。

类型系统也是文档的一部分。在 C++ 中，使用强类型而不是原始类型可以传达更多信息。例如，`Angle` 类型比 `double` 更能说明参数的含义；`std::optional<Target>` 比返回空指针更能表达“可能没有结果”的语义；`enum class RobotState` 比一堆整数常量更能说明状态的含义和取值范围。

```cpp
// 不好：类型没有传达信息
double Calculate(double a, double b, int mode);

// 好：类型本身就是文档
Velocity CalculateVelocity(Distance distance, Duration time);
std::optional<Target> DetectTarget(const Image& image);
```

含义不明的数值常量应改为有名称、单位和来源的常量或配置。`kMaxFiringDistanceMeters` 比孤立的 `5.0` 提供更多语义；若该值来自规则或标定，还应在配置说明或注释中记录依据。

```cpp
// 不好：魔法数字
if (distance < 5.0 && confidence > 0.8) {
    Fire();
}

// 好：有意义的常量
constexpr double kMaxFiringDistance = 5.0;  // meters
constexpr double kMinConfidenceThreshold = 0.8;

if (distance < kMaxFiringDistance && confidence > kMinConfidenceThreshold) {
    Fire();
}
```

源码能够展示当前实现“做什么”和“怎样做”，却不一定保留“为什么这样做”。算法选择、参数依据、兼容性限制和看似多余的检查，都适合用临近注释或设计文档说明，并尽可能关联可核查的规则、测量或议题记录。

==== 怎样写有效注释

注释与代码放在一起，适合说明局部约束、意图和来源。准确注释能减少反推背景的时间，过时或未经验证的注释则会误导读者，因此注释也属于需要审查的代码内容。

像 `i++; // 将 i 加 1` 这样重复语句表面的注释没有增加信息。如果一段普通业务代码必须逐行解释才能读懂，可以先考虑改进命名和结构；但数学推导、协议布局、硬件寄存器和生成代码即使结构合理，也可能需要说明其操作含义。

注释尤其适合解释实现理由、约束和取舍。说明应尽量具体，避免只写“性能更好”或“防止出错”而不给出适用条件。

```cpp
// 不好：解释"是什么"
// 遍历所有目标
for (const auto& target : targets) {
    // 如果目标在范围内
    if (target.distance < max_distance) {
        // 添加到结果中
        results.push_back(target);
    }
}

// 项目策略 V3.2：只把有效射程内的目标交给发射决策；
// 更远目标仍由上游跟踪器维护，不在这里加入 results。
for (const auto& target : targets) {
    if (target.distance < max_distance) {
        results.push_back(target);
    }
}
```

非直观代码若受性能、缓冲区生命周期或协议兼容性限制，应在附近记录限制和验证来源，避免维护者在不了解条件时改变语义。例如：

```cpp
// 相机回调返回后，驱动会立即复用 frame 的底层缓冲区。
// 后台线程需要继续读取 ROI，因此这里必须复制像素而不能只保留浅引用。
cv::Mat owned_roi = frame(roi).clone();

// 协议 v2 规定线上的 16 位字段为小端序；不要直接发送主机内存布局。
WriteUint16LittleEndian(packet, sequence_number);
```

注释应该解释假设和约束。函数对输入有什么要求？调用时需要满足什么前置条件？有什么副作用？这些信息可以帮助调用者正确使用代码。

```cpp
// 计算两点之间的角度。
// 假设：两点不重合（distance > 0）。
// 返回值：弧度，范围 [-π, π]。
// 注意：此函数不是线程安全的，因为它使用了全局缓存。
double CalculateAngle(const Point& from, const Point& to);
```

注释要保持与代码同步。过时的注释比没有注释更糟糕，因为它会误导读者。当修改代码时，一定要检查相关注释是否需要更新。如果一段注释描述的行为与代码不符，读者会困惑：是代码错了还是注释错了？为了降低注释过时的风险，注释应该描述意图和原因，而不是复述代码的实现细节——意图通常比实现稳定。

TODO 和 FIXME 可分别标记计划中的工作与已知缺陷。注释应包含可执行的描述，并按团队约定关联负责人、议题编号或复现条件。团队可定期核对这些标记：已经解决的删除，仍有效但需要排期的转入任务系统，不能仅按存在时间判断重要性。

```cpp
// TODO(#231, zhangsan): 支持多目标关联；当前接口只返回单一目标。

// FIXME(#245): 回放集 glare_v2 中的强光片段误检率升高；
//              原因和修复方案尚未确认。

// TODO(upstream #123): 当前绕过上游 2.1 的初始化错误；
//                      升级到含修复的版本后删除并运行回归测试。
```

==== README：项目入口说明

README 通常是仓库首页首先展示的文档，应让目标读者了解项目用途、支持范围、环境要求和下一步入口。它不必容纳所有细节，可以链接到配置、架构和贡献文档。

下面给出一种常见结构，实际内容应按项目读者调整。

项目标题和简介放在开头，用一两句话说明项目解决什么问题以及当前范围。构建状态或版本徽章只有连接到真实自动化结果时才有意义，不应手工标成“passing”。

```markdown
# RoboMaster Vision System

基于深度学习的 RoboMaster 自瞄视觉系统，支持装甲板检测、跟踪和预测。
```

功能列表说明仓库当前提供的能力。帧率、精度等性能数字应另附测试硬件、输入分辨率、数据集、构建版本和统计方法，不能只写一个脱离条件的数值。

```markdown
## 功能特性

- 装甲板检测与编号识别
- 多目标跟踪与 ID 关联
- 基于卡尔曼滤波的运动预测
- ROS 2 Humble 节点与启动文件
- 可选的 CUDA 推理后端
```

快速开始应列出已验证的环境、依赖安装、构建和最小运行示例。发布前应在干净环境中实际执行这些命令，并明确示例路径、所需模型与硬件；占位符不能让读者误以为可以原样运行。

````markdown
## 快速开始

### 环境要求

- Ubuntu 22.04
- ROS 2 Humble
- CUDA 11.8（仅 CUDA 后端需要）
- OpenCV 4.5

### 安装

```bash
# 克隆仓库
git clone https://github.com/your-team/rm_vision.git
cd rm_vision

# 安装依赖
./scripts/install_dependencies.sh

# 编译
colcon build --symlink-install
```

### 运行

```bash
# 启动检测节点
ros2 launch rm_vision detector.launch.py

# 使用录制的数据测试
ros2 launch rm_vision detector.launch.py use_bag:=true bag_path:=/path/to/bag
```
````

配置说明解释主要的配置选项，让用户知道如何根据自己的需求调整系统。可以提供配置文件的示例和各选项的含义。

````markdown
## 配置

配置文件位于 `config/detector_params.yaml`：

```yaml
detector:
  model_path: "models/armor_yolov8.onnx"  # 模型路径
  confidence_threshold: 0.7               # 置信度阈值
  nms_threshold: 0.4                      # NMS 阈值
  target_color: "red"                     # 目标颜色
```
````

项目结构帮助读者理解代码的组织方式，特别是对于想要深入了解或贡献代码的人。

````markdown
## 项目结构

```
rm_vision/
├── rm_vision/           # 主功能包
│   ├── detector/        # 装甲板检测
│   ├── tracker/         # 目标跟踪
│   └── predictor/       # 运动预测
├── rm_interfaces/       # 消息和服务定义
├── rm_bringup/          # 启动文件
├── config/              # 配置文件
├── models/              # 预训练模型
└── docs/                # 详细文档
```
````

其他可选部分包括：详细文档的链接、贡献指南、许可证信息、致谢、联系方式等。对于开源项目，这些信息尤其重要。

```markdown
## 文档

详细文档请参阅 [Wiki](https://github.com/your-team/rm_vision/wiki)。

## 贡献

欢迎贡献！请阅读 [贡献指南](CONTRIBUTING.md) 了解如何参与。

## 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE)。

## 致谢

- 感谢 [YOLO](https://github.com/ultralytics/yolov5) 提供的目标检测框架
- 感谢历届队员的贡献

## 联系我们

- 邮箱：robomaster@example.com
- QQ 群：123456789
```

==== API 文档与 Doxygen

供其他模块或团队使用的库通常需要 API 文档，说明公开类型、参数单位、所有权、错误方式和线程安全性。Doxygen 是常用的 C++ 文档生成工具，可以从源代码声明及特定格式的注释生成索引和页面。自动生成能减少重复排版，但不会检查描述是否符合真实行为。

Doxygen 可识别 Javadoc 风格的 `/** ... */`、Qt 风格的 `/*! ... */` 以及 `///` 行注释。普通的 `/* ... */` 默认不是文档注释。下面展示常用命令；项目也可选用 `\brief` 等反斜杠写法：

```cpp
/**
 * @file armor_detector.h
 * @brief 装甲板检测器的头文件
 * @author Zhang San
 * @date 2024-01-15
 */

/**
 * @brief 装甲板检测器类
 * 
 * ArmorDetector 使用深度学习模型检测图像中的装甲板。
 * 它根据配置检测红色或蓝色装甲板；适用光照范围见模型说明。
 * 
 * @note 此类不是线程安全的。每个线程应创建独立的实例。
 * 
 * 使用示例：
 * @code
 * ArmorDetector detector(config);
 * if (!detector.Init()) {
 *     throw std::runtime_error("failed to initialize detector");
 * }
 * auto armors = detector.Detect(image, timestamp);
 * for (const auto& armor : armors) {
 *     std::cout << "检测到装甲板，置信度: " << armor.confidence << std::endl;
 * }
 * @endcode
 * 
 * @see Tracker 用于目标跟踪
 * @see Predictor 用于运动预测
 */
class ArmorDetector {
public:
    /**
     * @brief 构造函数
     * @param config 检测器配置参数
     * @throws std::invalid_argument 如果配置无效
     */
    explicit ArmorDetector(const DetectorConfig& config);
    
    /**
     * @brief 初始化检测器
     * 
     * 加载模型并准备推理引擎。此方法必须在 Detect() 之前调用。
     * 
     * @return true 如果初始化成功
     * @return false 如果初始化失败（如模型文件不存在）
     */
    bool Init();
    
    /**
     * @brief 检测图像中的装甲板
     * 
     * @param image 输入图像，必须是 BGR 格式
     * @param timestamp 图像采集时间，单位为秒，时钟域见 DetectorConfig
     * @return 检测到的装甲板列表，按置信度降序排列
     * 
     * @pre Init() 已成功调用
     * @pre image 不为空
     * 
     * @warning 此方法会修改内部状态，不要在多线程中共享实例
     */
    std::vector<Armor> Detect(const cv::Mat& image, double timestamp);
    
    /**
     * @brief 设置目标颜色
     * @param color 目标颜色
     * @see TargetColor
     */
    void SetTargetColor(TargetColor color);
    
    /**
     * @brief 获取当前检测统计信息
     * @return 包含检测帧数、平均耗时等的统计信息
     */
    DetectorStats GetStats() const;

private:
    DetectorConfig config_;  ///< 检测器配置
    bool initialized_;       ///< 是否已初始化
    // ...
};

/**
 * @brief 目标颜色枚举
 */
enum class TargetColor {
    kRed,   ///< 红色方
    kBlue   ///< 蓝色方
};

/**
 * @struct Armor
 * @brief 装甲板检测结果
 */
struct Armor {
    cv::Point2f center;     ///< 装甲板中心点（像素坐标）
    cv::Size2f size;        ///< 装甲板尺寸（像素）
    double confidence;      ///< 检测置信度，范围 [0, 1]
    int id;                 ///< 模型标签编号；映射关系由当前规则与模型版本定义
    TargetColor color;      ///< 装甲板颜色
};
```

下面是在 Ubuntu 中安装并运行 Doxygen 的基本步骤：

```bash
sudo apt install doxygen graphviz
```

然后在项目根目录生成配置文件：

```bash
doxygen -g Doxyfile
```

编辑 `Doxyfile` 配置主要选项：

```
# 项目信息
PROJECT_NAME           = "RoboMaster Vision"
PROJECT_NUMBER         = 2.0.0
PROJECT_BRIEF          = "自瞄视觉系统"

# 输入设置
INPUT                  = include src
RECURSIVE              = YES
FILE_PATTERNS          = *.h *.hpp *.cpp

# 输出设置
OUTPUT_DIRECTORY       = docs/api
GENERATE_HTML          = YES
GENERATE_LATEX         = NO

# 提取设置
EXTRACT_ALL            = NO
EXTRACT_PRIVATE        = NO
EXTRACT_STATIC         = YES

# 图表
HAVE_DOT               = YES
CALL_GRAPH             = YES
CALLER_GRAPH           = YES
```

运行 Doxygen 生成文档：

```bash
doxygen Doxyfile
```

生成的 HTML 文档在 `docs/api/html/` 目录下，用浏览器打开 `index.html` 即可查看。

==== 项目文档类型

除代码注释和 API 说明外，项目还可以按读者与生命周期维护需求、设计、用户操作和变更记录等文档。小型项目不必为每种类型创建独立文件，但相关信息仍应有明确位置。

需求文档描述系统应提供的功能，以及性能、可靠性和可维护性等约束。要求应尽量可验证：精度要注明数据集和指标，延迟要说明起止点与分位数，连续运行则要说明硬件、负载和通过条件。下面的数值仅用于演示格式，不是 RoboMaster 项目的通用指标。

```markdown
# 自瞄系统需求文档

## 功能需求

### FR-001: 装甲板检测
- 系统应能检测红色和蓝色装甲板
- 支持识别装甲板编号（1-5）
- 检测距离范围：1-8 米

### FR-002: 目标跟踪
- 系统应能跟踪多个目标
- 支持目标遮挡后重新识别
- 跟踪 ID 应保持稳定

## 非功能需求

### NFR-001: 性能
- 端到端延迟 < 20ms
- 检测帧率 >= 60 FPS

### NFR-002: 可靠性
- 误检率 < 1%
- 连续运行 8 小时无崩溃
```

设计文档描述计划如何满足需求，包括系统边界、模块划分、接口、数据流、关键算法和替代方案。除了“怎样实现”，还应记录选择依据、尚未验证的假设和回退方案。

```markdown
# 自瞄系统设计文档

## 系统架构

系统采用三层架构：感知层、决策层、执行层。

```
┌─────────────┐
│   感知层    │  ← 图像采集、目标检测、状态估计
├─────────────┤
│   决策层    │  ← 目标选择、弹道解算、预测补偿
├─────────────┤
│   执行层    │  ← 云台控制、发射控制
└─────────────┘
```

## 模块设计

### 检测模块

采用 YOLOv8 进行装甲板检测，选择依据：
1. 在目标板与固定回放集上的延迟满足 NFR-001，详见基准报告
2. 在已标注验证集上的小目标指标优于本次比较的候选模型
3. 当前推理后端已支持所需算子；模型版本与转换参数已固定

### 跟踪模块

采用 EKF 进行状态估计，状态向量：
- 位置 (x, y, z)
- 速度 (vx, vy, vz)
- 装甲板朝向 θ

## 接口定义

...
```

用户手册面向最终用户，说明如何安装、配置和使用系统。它应该假设读者不了解内部实现，用清晰的语言和步骤指导用户完成任务。对于 RoboMaster 项目，用户可能是操作手或调试人员。

变更日志（CHANGELOG）按发布版本记录面向使用者的变化，帮助读者判断兼容性和升级步骤。下面采用 Keep a Changelog 的栏目形式；只有项目明确采用语义化版本时，才应声明遵循 Semantic Versioning。示例中的日期和性能变化均为格式占位内容。

```markdown
# 变更日志

本项目采用 [语义化版本](https://semver.org/)。

## [2.1.0] - 2024-03-15

### 新增
- 支持能量机关检测
- 添加录像回放功能

### 变更
- 升级 YOLOv8 模型；目标板与回放集上的基准见 `reports/model-2.1.md`
- 调整默认参数，适配新赛季规则

### 修复
- 修复在强光下的误检问题 (#42)
- 修复内存泄漏 (#45)

### 废弃
- `DetectArmor()` 已废弃，请使用 `Detect()`

## [2.0.0] - 2024-01-10

### 破坏性变更
- 重构检测接口，不兼容 1.x 版本
- 配置文件格式改为 YAML

...
```

==== Markdown 写作技巧

Markdown 是代码托管平台常见的纯文本格式，适合与源码一起查看差异。不同平台支持的扩展语法并不完全相同，发布前应在目标渲染器中检查。

标题用于建立可导航的层次。层级过深时，可以检查内容是否应拆成独立页面；“三级通常足够”是经验建议，不是语法限制。

```markdown
# 一级标题（文档标题）
## 二级标题（主要章节）
### 三级标题（子章节）
```

列表用于并列的内容。有序列表用于有顺序的步骤，无序列表用于没有顺序的项目。列表项应该结构一致——要么都是完整的句子，要么都是短语。

```markdown
## 安装步骤

1. 克隆仓库
2. 安装依赖
3. 编译项目
4. 运行测试

## 支持的功能

- 装甲板检测
- 能量机关检测
- 目标跟踪
```

代码块是技术文档的重要组成部分。目标渲染器支持语法高亮时，可以为代码块标明语言；命令、函数名、文件名等短内容则适合使用行内代码。

````markdown
运行 `ros2 launch` 启动节点：

```bash
ros2 launch rm_vision detector.launch.py
```

函数 `Detect()` 返回检测结果。
````

表格适合展示结构化的对比信息。保持表格简洁，复杂的内容应该用其他方式呈现。

```markdown
| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| confidence_threshold | float | 0.7 | 置信度阈值 |
| nms_threshold | float | 0.4 | NMS 阈值 |
| target_color | string | "red" | 目标颜色 |
```

系统架构、事件顺序或数据流难以用短段落说明时，图表会更直观。Mermaid 可以在支持它的平台中随 Markdown 保存图表源码；其他平台可能需要预先生成图片。

````markdown
```mermaid
graph LR
    A[相机] --> B[检测器]
    B --> C[跟踪器]
    C --> D[预测器]
    D --> E[云台控制]
```
````

项目内文档优先使用相对链接，使分支和离线副本仍能对应当前版本；外部资料应使用稳定来源，并在链接文字中说明内容。关键结论不能只依赖一个可能失效的链接，必要时还应记录版本、标题或摘要。

```markdown
详细配置说明请参阅 [配置文档](./config.md)。

算法原理基于这篇 [论文](https://arxiv.org/abs/xxx)。
```

==== 文档即代码

“文档即代码”（Docs as Code）表示用版本控制、审查和自动构建等软件开发流程管理文档源文件。

文档源文件应纳入版本控制。与代码放在同一仓库通常便于保持版本对应；大型产品也可能使用独立文档仓库，此时需要明确版本映射。Git 能记录已提交的变化，但不会自动保证文档内容已经随代码更新，因此审查清单仍要检查相关说明。

Markdown、reStructuredText、AsciiDoc 等纯文本格式便于比较差异和自动处理，适合作为技术文档源文件。必须使用办公文档格式交付时，可以同时保存可审查的源材料或规定协作平台和导出流程，而不是假设 Git 能清楚合并二进制差异。

CI 可以在代码推送时构建文档、检查语法和链接，并在权限允许时发布站点。这能发现构建失败和部分失效链接，不能判断文字是否准确或完整。下面示例只构建 Doxygen；部署需要另行配置目标环境、最小权限和发布规则。

```yaml
# .github/workflows/docs.yml
name: Build Documentation

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install documentation tools
        run: sudo apt-get update && sudo apt-get install -y doxygen graphviz
      
      - name: Build Doxygen
        run: doxygen Doxyfile
```

使用简单格式、提供模板并及时审查，可以降低成员补充文档的成本。文档变更也应像代码一样核对事实、版本和受影响读者。

==== RoboMaster 文档实践

结合 RoboMaster 的实际情况，以下是一些具体的文档实践建议。

赛季交接文档应记录新成员无法从仓库首页直接得知的信息：当前系统架构、模块负责人和接口、可复现的故障、未完成事项、目标硬件以及比赛使用的版本。编写责任不应只落在少数“核心队员”身上，各模块维护者应共同核对。下面示例中的数字仅展示记录格式，真实文档必须附测试条件和原始报告。

```markdown
# 2024 赛季自瞄系统交接文档

## 系统概述

本赛季自瞄系统采用 YOLOv8 + EKF 架构...

## 取得的成果

- 目标板 A、回放集 B 上的检测帧率由 30 FPS 提升到 60 FPS（见基准报告）
- 测试流程 C 中的命中率由 60% 提升到 80%（样本量与区间见结果报告）
- 支持了能量机关检测

## 遗留问题

1. 强光下仍有误检（建议添加时域滤波）
2. 远距离检测精度不足（建议尝试更大的模型）
3. 代码耦合度高（建议重构跟踪模块）

## 下赛季建议

- 在固定数据集和目标板上比较现有模型与候选架构
- 完善单元测试覆盖
- 整理代码规范
```

硬件接口文档应明确物理接口、数据格式、单位、字节序、校验、超时、版本兼容和异常处理。软件组与电控组可以用同一组固定报文测试各自实现，减少只靠口头约定产生的差异。

````markdown
# 视觉-电控通信协议

## 物理接口

- 接口类型：UART
- 波特率：115200
- 数据位：8
- 停止位：1
- 校验：无

## 数据帧格式

| 字节 | 内容 | 说明 |
|------|------|------|
| 0 | 0xA5 | 帧头 |
| 1 | len | 数据长度 |
| 2 | seq | 帧序号 |
| 3 | crc8 | 头部校验 |
| 4-N | data | 数据内容 |
| N+1,N+2 | crc16 | 整帧校验 |

## 命令定义

### 0x01: 自瞄数据

```c
struct AimData {
    float yaw;      // 目标 yaw 角度，单位：度
    float pitch;    // 目标 pitch 角度，单位：度
    uint8_t fire;   // 是否开火：0-否，1-是
};
```

此结构只表达逻辑字段，不能直接用 `memcpy` 发送对象内存。线上格式还需规定
浮点编码、字节序、字段偏移和填充方式，并用固定字节序列验证两端实现。
````

调试手册按现象列出检查顺序、每项结果如何解释、可逆操作和升级联系人。它应把“可能原因”与已经确认的原因分开，避免读者不做检查就直接应用某个处理。

```markdown
# 自瞄系统调试手册

## 问题：检测不到目标

### 可能原因

1. 相机未正确连接
2. 曝光参数不合适
3. 目标颜色设置错误

### 诊断步骤

1. 检查相机是否被识别：`ls /dev/video*`
2. 查看原始图像：`ros2 run rqt_image_view rqt_image_view`
3. 检查配置文件中的 `target_color` 设置

### 解决方案

1. 重新插拔相机，检查 USB 连接
2. 使用 `scripts/auto_exposure.py` 自动调整曝光
3. 修改 `config/detector.yaml` 中的颜色设置

## 问题：云台抖动

...
```

文档需要持续维护。接口、配置、构建步骤和操作流程发生变化时，应在同一变更中检查相关说明；调试中形成了可复现且可能再次出现的问题，再整理进调试手册。赛季结束时则核对比赛版本、标定文件、未决事项和负责人。并非每次代码修改都需要改文档，判断标准是读者依赖的信息是否变化。

文档的价值最终体现在具体任务上：新成员能否完成构建，调试者能否按步骤缩小范围，接口使用者能否判断单位和错误方式，维护者能否了解决策依据。围绕这些读者任务编写并定期验证，比追求文档数量更有效。


=== 版本控制与协作（可选/扩展）
// Git 工作流与团队协作
// - Git 基础回顾
// - 分支策略：Git Flow vs GitHub Flow
// - 提交信息规范（Conventional Commits）
// - Pull Request 与 Code Review
// - CI/CD 简介
// - 冲突解决
// - RoboMaster 团队 Git 实践
// === 版本控制与协作

版本控制记录已提交文件的变化，并为多人并行开发提供合并与审查基础。Git 是当前常用的分布式版本控制系统之一。本节不重复 Git 专题章节的命令，而从工程角度讨论历史记录、分支策略、代码审查和持续集成分别解决什么问题，以及它们不能自动保证什么。

==== 版本控制的工程意义

手动复制 `project_v1`、`project_final`、`project_final_final` 等目录也能保留少量快照，却难以清楚比较差异、合并两人的修改或说明每个版本的用途。文件经邮件或移动存储传递时，还容易出现多个互不对应的副本。

Git 可以记录提交中的作者信息、时间、文件差异和提交说明，并比较可访问的历史版本。“为什么改”只有在提交信息或关联议题写清楚时才会留下。未提交文件、被清理的不可达对象、未纳入仓库的大文件和外部设备状态不在这份历史中；强制改写历史也可能让旧提交难以取得。因此，版本控制便于恢复许多已提交变化，却不能保证任何修改都可撤销，更不能代替备份和发布归档。

团队成员可以在各自分支或提交上开发，再通过合并、变基或挑选提交整合。Git 能检测部分文本冲突，但无法发现两个修改在不同文件中形成的语义冲突；自动合并成功后仍要构建和测试。分支也不会自动协调接口设计，相关成员仍需提前沟通共享协议和大范围重构。

Git 的本地仓库通常保存当前克隆取得的对象与历史，可离线查看、创建提交和分支，再与远程仓库同步。集中式系统也允许离线编辑，部分工具还支持本地差异操作，但提交与取得服务器上的新历史通常依赖中央服务。两类系统的具体能力取决于工具和工作副本配置，不能简单概括为集中式系统必须持续联网。

RoboMaster 项目可以为经过验证的比赛版本创建标签并保存对应构建产物、配置和标定数据，同时在其他分支继续开发。不同机器人之间若主要差异是参数，优先使用受版本控制的配置而不是长期复制代码分支。历史差异可以定位某项行为从哪个变更开始出现，再通过复现或回退对照判断影响；提交时间本身不能确认故障原因。

==== 分支策略：根据发布方式选择

团队需要约定长期分支的含义、合并条件和发布来源。策略过于复杂会增加同步成本，过于随意则难以判断哪个版本可部署。选择应基于发布频率、同时维护的版本数量和审查能力。

Git Flow 由 Vincent Driessen 在 2010 年提出。它定义 `main`（或 `master`）、`develop`、`feature`、`release` 和 `hotfix` 等分支角色，适合需要同时准备下一版本、维护已发布版本并经过明确发布阶段的项目。`main` 是否真的可发布仍取决于测试和发布流程，分支名称本身不提供保证。

这种模型能清楚区分开发、发布准备和紧急修复，并支持维护多个版本；代价是长期分支之间需要持续合并修复，团队还要明确同一改动应进入哪些分支。

只维护一个活动版本、频繁合并的项目未必需要完整 Git Flow。RoboMaster 团队如果没有独立发布阶段，可以采用更少的长期分支，并通过标签标记实机验证版本。

GitHub Flow 常保留一个长期 `main` 分支，开发在短期分支进行，通过 Pull Request 审查后合并，并要求 `main` 始终接近可部署状态。它减少了分支角色，适合只维护一个主要版本的团队；机器人部署仍可以增加人工批准和实机验证，不必在合并后立即更新设备。

一种可行的团队约定是：`main` 接受已审查并通过规定自动检查的变更，开发使用功能分支；重要测试或比赛版本用标签和发布记录固定。若确需并行维护比赛版本，可创建 `stable` 或 `competition` 分支，并规定修复如何回合到 `main`，避免两个分支持续分叉。

功能分支通常应保持较小范围并尽快集成，以减少同时变化的上下文。较长任务可通过功能开关或分阶段兼容提交缩小差异；无法缩短时，要约定从主线同步的方式，避免随意变基已共享历史。合并前运行哪些构建和测试，应由仓库规则明确，并说明未覆盖的硬件路径。

==== 提交信息：说明改动与原因

提交信息（commit message）为代码差异补充目的、约束和验证方法。标题便于浏览历史，正文则可解释单看差异无法得知的原因；最终判断行为仍要阅读代码和相关证据。

`fix bug`、`update`、`修改` 或 `test` 没有指出影响范围和预期行为。数月后检索历史时，读者仍需逐个打开差异。更具体的标题应说明改了哪个模块以及产生什么可观察变化。

Conventional Commits 是一种结构化提交格式，便于生成变更日志或按类型触发工具。团队可以采用它，也可以使用自己的模板；格式一致不能代替正文中的事实。基本形式为：

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

`type` 表示提交类型：`feat` 为新功能，`fix` 为缺陷修复，`docs` 为文档更新，`refactor` 为不以改变外部行为为目标的重构，`test` 为测试相关，`chore` 可按团队约定表示工具或维护任务。`scope` 可填写模块名，`description` 简要说明改动。英文项目常约定使用祈使语气，中文项目也可制定一致写法。

一些具体的例子可以说明什么是好的提交信息：

```
feat(detector): add armor number classification

Implement CNN-based number classification for detected armors.
Evaluation dataset, metric, hardware, and results are recorded in
reports/armor-number-v3.md.

Closes #42
```

```
fix(tracker): correct Kalman filter initialization

The previous initialization caused divergence when target
first appeared in the edge-entry replay. Initialize position from
the first accepted measurement; the new regression test covers it.
```

```
refactor(solver): extract ballistic calculation to separate class

External behavior is intended to remain unchanged. Existing solver
unit and replay tests pass in the environment listed in the PR.
```

这些信息给出了类型、范围、意图和证据入口，适合用于筛选历史。若要确认实现细节或结论范围，仍应查看差异、测试和关联报告。

提交尽量形成可理解的逻辑单元：不要混入无关格式调整，也不要把一个无法单独构建的机械步骤拆得过碎。大型迁移可由若干保持兼容或至少便于审查的提交组成。“一个提交只做一件事”指一个清楚目的，不是限制只能修改一个文件。

团队可以用 commitlint 等工具检查约定格式。它只能判断结构与部分文本规则，无法确认描述是否真实；审查者仍需核对提交内容。

==== Pull Request 与代码审查

代码审查（Code Review）让其他成员在合并前检查变更目标、实现、测试和文档。它可能发现缺陷并传播模块知识，但不能保证审查者注意到所有问题，尤其不能代替目标环境验证。

GitHub 使用 Pull Request，GitLab 常称 Merge Request。作者提交合并请求时应说明问题、方案、测试条件、风险和回退方式；审查者可以逐行评论或讨论整体设计。仓库若配置分支保护，可以要求指定审查和检查通过后才允许合并。

审查先核对变更是否对应需求，失败和边界条件怎样处理，再检查接口兼容、结构、命名和必要文档。测试部分不只看“有没有”，还要看输入是否能区分正确与错误实现、运行环境是否与结论匹配，以及哪些路径没有执行。性能或根因声明应链接相应测量或复现证据。

审查反馈应针对代码和需求，并区分阻塞问题、建议和疑问。明确指出违反的约束及可能后果，比固定使用某种委婉句式更重要；涉及事实争议时给出文档、测试或反例。

作者应及时说明已修改、暂不修改或需要讨论的原因。意见不一致时回到已知约束和可运行检查；团队规则没有覆盖的新决策应记录下来，避免以后重复争论。

RoboMaster 团队可按变更风险调整审查：文字修正与控制协议变更不必采用同一门槛。临近比赛并不会让高风险变更更安全；若紧急修复无法完成常规流程，应缩小改动、保留可回退版本、记录跳过的检查并安排事后复核。模块维护者可以提供领域背景，但关键模块最好避免只有唯一知情人。

==== 持续集成与自动化

持续集成（Continuous Integration，CI）鼓励频繁整合小批量变更，并在受控环境中自动执行构建、测试和静态检查。这样能较早发现该环境中的接口不兼容，而不是把大量整合工作集中到赛季后期。

GitHub Actions、GitLab CI、Jenkins 等系统可在推送或合并请求时编译代码、运行测试、检查格式、生成文档或构建容器镜像。任务失败后应保留日志和产物，方便区分代码失败、环境故障与偶发测试。

CI 结果的范围由任务配置决定：一次 Ubuntu 构建成功只证明该提交在对应镜像、编译器和依赖下完成构建；测试通过只说明已执行断言没有失败；格式检查也只覆盖配置中选取的文件。自动化的优势是重复执行相同规则，而需求理解、设计与实机状态仍需人工判断。

持续交付（Continuous Delivery）通常表示代码始终准备好经人工批准发布；持续部署（Continuous Deployment）则把通过门槛的版本自动部署到目标环境。机器人软件涉及物理运动、设备差异和比赛版本冻结，通常需要人工批准、设备身份检查和回退方案，不应仅因 CI 通过就自动更新所有机器人。

RoboMaster 项目的普通合并请求可以运行 Ubuntu 构建、快速单元测试和格式检查；视觉评估、仿真及硬件在环测试可按耗时安排为合并门槛或定时任务。分支保护只应要求稳定且有维护者的检查，并在合并说明中列出未运行的目标板测试。

CI 需要维护运行镜像、缓存、密钥、测试数据和失败处理。把稳定、重复的检查自动化后，团队可以更快得到一致反馈；暂时无法自动化的实机步骤仍应保留清单和结果记录。

==== 冲突解决：合并不同意图

当两个历史以不兼容方式修改同一文本区域，或出现删除/修改、重命名等情况时，Git 可能无法自动合并并报告冲突。冲突标记的是文本整合需要人工决定，不表示任一方必然写错；反过来，没有文本冲突也不表示行为兼容。

Git 会在冲突的文件中标记出冲突的位置，用特殊的标记分隔不同的版本：

```cpp
<<<<<<< HEAD
// 你的修改
void process(const Image& img) {
    detector_.detect(img);
}
=======
// 别人的修改
void process(const cv::Mat& img) {
    detector_.process(img);
}
>>>>>>> feature/new-detector
```

解决时先查看共同基线和两边提交，理解各自需求，再选择一侧或组合成新的实现。删除标记并把文件加入当前操作的已解决集合后，还要继续相应的 merge、rebase 或 cherry-pick；具体命令见 Git 章节。不要只以“能够编译”作为完成标准，接口语义和测试也可能需要一起调整。

较小、较短期的变更通常更容易理解和合并。进行跨文件重构或接口迁移前，通知受影响成员并约定顺序；纯格式重排与功能改动分开提交；长分支则按团队规定定期同步主线。清楚的模块边界能减少无关修改落在同一文件，但不应以此阻止必要的跨模块审查。

复杂冲突应邀请熟悉两边需求的开发者共同处理。解决后查看完整差异，并运行与两项改动相关的测试；测试通过只能说明这些检查未发现问题，必要时还要进行实机或协议联调。

==== RoboMaster 团队的 Git 实践

下面根据机器人代码、配置和比赛版本并存的特点，给出可供团队调整的做法。

仓库可以采用单一仓库（monorepo）或多仓库。单一仓库便于在一次提交中同步修改接口与调用者，统一运行工具；仓库增大后则要管理构建范围和大文件。多仓库允许模块独立发布和授权，但跨仓库协议升级需要版本兼容与发布协调。选择应看模块是否共同发布、权限边界和工具能力，不能只根据团队属于 RoboMaster 就确定。

共享远程仓库可为 `main` 设置分支保护，例如限制直接推送、要求一名其他成员审查并通过稳定的 CI 检查。小团队或断网现场也要预先设计紧急流程和管理员权限。保护规则能防止部分误操作，不能保证主分支在未测试硬件上稳定。

比赛版本应由团队明确冻结点，而不是固定为“赛前一周”。为通过实机验证的提交创建标签，保存构建产物校验值、依赖锁定、机器人配置和标定版本。若使用 `competition` 分支接收少量修复，要记录每项修复的测试与回退方式，并及时把仍适用于开发主线的改动回合，避免只存在于比赛分支。

参数配置、适合存入仓库的标定数据、启动脚本和协议文档应与代码建立版本对应关系。密码、令牌和设备私钥不能提交到仓库；体积很大的模型或数据集可使用制品仓库、Git LFS 或下载清单，并记录校验值。恢复旧版本时还要确认硬件和固件是否兼容。

新成员可以先在练习仓库中完成分支、冲突、撤销和恢复操作，再接触共享主线。指定熟悉 Git 的成员提供支持，并把常见操作和紧急恢复步骤写入团队文档，可以减少只靠口头记忆造成的误操作。

版本控制为可追踪变更、协作与发布记录提供基础。它只有与清楚的提交说明、审查、测试、备份和制品管理配合，才能支持可靠的维护。团队应从当前规模需要的最小流程开始，并根据实际失败和发布需求调整。

下一章会把这里的协作原则落实到 Git 的工作区、暂存区、提交和远程分支操作中，重点说明每条撤销或同步命令实际影响哪一层数据。
