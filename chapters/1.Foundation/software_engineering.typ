//== 软件工程基础

#show raw.where(block: true): set block(inset: (left: 4em))
=== 为什么需要软件工程
// 引言：从"能跑"到"能维护"
// - 个人项目 vs 团队项目的差异
// - 代码的生命周期：编写只是开始
// - 技术债务的概念
// - RoboMaster 赛季迭代的教训
// - 本章内容概览
// 
你写了一个程序，它能跑。在你的电脑上，用你准备的测试数据，它完美地完成了任务。你很满意，提交代码，转身去做下一件事。三个月后，队友问你这段代码是做什么的，你盯着屏幕，发现自己也看不懂了。半年后，新赛季开始，需要在这个基础上开发新功能，却发现代码像一团乱麻，牵一发而动全身，没人敢改。一年后，你毕业了，后辈们面对这份"遗产"，选择了重写。

这个场景在学生团队中反复上演。代码"能跑"只是最低标准，而"能维护"才是真正的挑战。软件工程就是关于如何写出能维护的代码、如何让团队高效协作、如何让项目可持续发展的学问。它不是象牙塔里的理论，而是无数程序员踩过无数坑后总结出的实践智慧。

==== 从个人项目到团队协作

一个人写代码和一群人写代码是完全不同的事情。

个人项目中，所有的上下文都在你的脑子里。你知道每个变量的含义，知道为什么要这样设计，知道哪些地方是临时凑合的。你不需要写注释，因为你自己能看懂；你不需要规范命名，因为你知道 `tmp2` 是什么意思；你不需要考虑接口设计，因为所有代码都是你写的。这种方式在小项目、短周期内是可行的，甚至是高效的。

但当项目变成团队协作时，一切都变了。你的队友不知道你脑子里的上下文。当他看到 `process()` 函数时，他不知道它处理什么、输入输出是什么、有什么前置条件、会不会抛异常。当他需要修改你的代码时，他不知道哪些地方可以安全地改，哪些地方有隐含的依赖。当他想复用你的模块时，他不知道该调用哪个函数、参数该怎么传。

团队协作要求代码是"自解释"的——通过清晰的命名、合理的结构、必要的注释，让任何一个新来的人都能理解代码在做什么。它要求代码是"可预测"的——遵循统一的规范，让人能根据约定推断代码的行为。它要求代码是"可演进"的——通过良好的模块化和接口设计，让修改一个地方不会意外地破坏另一个地方。

这些要求听起来很抽象，但它们会体现在具体的实践中：命名规范让变量名一目了然，代码格式让风格统一易读，设计模式让结构清晰可扩展，单元测试让修改有信心，文档让知识得以传承。这就是软件工程的内容。

==== 代码的生命周期

一段代码从诞生到退役，会经历漫长的生命周期。编写代码只是开始，之后的阅读、调试、修改、扩展、维护才是主旋律。据统计，程序员花在阅读代码上的时间是编写代码的十倍以上。这意味着，让代码易于阅读比让代码易于编写更重要。

在 RoboMaster 的语境下，这个生命周期与赛季节奏紧密相连。备赛期间写的代码，会在比赛中经受考验；比赛中发现的问题，会在赛后修复和改进；这个赛季的代码，会成为下个赛季的基础；老队员的代码，会交接给新队员维护。一段视觉识别的代码，可能会被五六届学生接力修改，持续服役好几年。

当你写代码时，想象一下半年后的自己、一年后的队友、两年后的后辈会如何看待这段代码。他们能理解它吗？能安全地修改它吗？能在它基础上扩展新功能吗？如果答案是否定的，那么你正在给未来的人挖坑——而那个人很可能就是你自己。

==== 技术债务

技术债务是软件工程中的一个重要概念。就像金融债务一样，技术债务是为了短期利益而做出的妥协，这些妥协会在未来产生"利息"——以更多的维护成本、更高的 bug 率、更慢的开发速度的形式体现。

技术债务有很多形式：为了赶进度而写的临时代码（"先这样，之后再改"），没有测试覆盖的功能（"能跑就行"），缺失的文档（"代码就是文档"），过时的依赖（"能用就不要升级"），绕过问题而不是解决问题的 workaround（"不知道为什么，但加上这行就好了"）。每一个这样的决定都在积累债务。

适度的技术债务有时是合理的。比赛前夜紧急修复 bug，你没有时间写完美的代码，先让它能工作是正确的选择。但关键是要意识到这是债务，要记录下来，要在之后偿还。问题在于，大多数技术债务是无意识积累的，没有人记得，直到债务多到压垮项目。

RoboMaster 团队特别容易积累技术债务。赛季紧张，时间永远不够；队员流动，知识容易丢失；成果导向，能跑的代码比好的代码更受认可。但技术债务的利息是残酷的：赛季中期，代码已经乱到没人敢改，只能不断打补丁；新赛季开始，想加新功能却发现无从下手，不得不大规模重构甚至重写；新队员接手，看不懂代码，只能猜测和试错。

软件工程的实践——代码规范、设计模式、测试、文档——本质上都是在控制技术债务。它们需要前期投入，但会在后期节省大量时间。这就像定期清洁房间：每天花十分钟整理，比每月花一整天大扫除要轻松得多。

==== RoboMaster 赛季的教训

在 RoboMaster 的实际开发中，缺乏软件工程意识会导致一系列典型问题。

备赛初期，大家各自为战，快速产出代码。每个人有自己的编码风格，有人用驼峰命名，有人用下划线，有人混用；有人喜欢大函数，有人喜欢小函数；有人写注释，有人不写。代码看起来像是几种语言的混合体。

赛季中期，需要整合各个模块。这时发现接口对不上，A 模块输出的数据格式和 B 模块期望的不一样；发现依赖冲突，两个模块用了同一个库的不同版本；发现功能重复，三个人写了三套坐标变换的代码。整合工作变成了痛苦的调试和修补。

比赛前夕，压力最大的时候。bug 层出不穷，但没人敢大改，因为不知道会不会引入新问题。代码里到处是注释掉的旧代码和临时的调试输出，没人记得哪些是有用的。参数硬编码在代码里，调一个参数要重新编译。

赛季结束，需要总结和交接。发现没有文档，只有一堆代码；代码里的魔法数字没人记得含义；一些关键的设计决策没有记录，只有当事人知道为什么。新队员接手后，只能靠读代码和猜测来理解系统。

这些问题不是命中注定的。好的软件工程实践可以避免大部分问题：统一的代码规范让代码风格一致，清晰的接口设计让模块整合顺畅，完善的测试让修改有信心，充分的文档让知识得以传承。代价是前期多花一些时间，但回报是全赛季的顺畅和多年的可持续发展。

==== 本章内容概览

本章将介绍软件工程的核心实践，帮助你从"能跑的代码"进化到"能维护的代码"。

我们从代码规范与风格开始。统一的代码风格是团队协作的基础。我们会介绍业界广泛采用的 Google C++ Style Guide 的核心要点，包括命名、格式、注释等方面的规范，以及如何使用 clang-format 等工具自动化地保持代码风格一致。

接下来是设计模式。设计模式是前人解决常见问题的经验总结。我们会探讨设计模式的起源和基本原则，然后详细介绍机器人开发中最实用的几种模式：单例模式管理全局资源、工厂模式创建对象、观察者模式实现事件通知、策略模式切换算法、状态模式管理行为状态。理解这些模式，你会发现很多设计问题都有现成的优雅解法。

然后是单元测试。测试是保障代码质量的关键手段。我们会介绍为什么要写测试、测试金字塔的概念、Google Test 框架的使用方法，以及如何写出易于测试的代码。在 RoboMaster 开发中，对算法模块进行单元测试可以大大提高代码的可靠性。

调试技巧是每个开发者必备的技能。我们会介绍 GDB 调试器的使用、日志系统的设计、内存调试工具的使用，帮助你高效地定位和解决问题。好的调试技能可以把"不知道为什么不工作"变成"知道问题在哪里以及如何修复"。

性能分析与优化讲的是如何让程序跑得更快。我们会介绍性能分析的工作流、时间测量的方法、perf 和火焰图等分析工具的使用，以及常见的优化方向。在 RoboMaster 的实时系统中，性能优化往往是决定胜负的关键。

文档编写是经常被忽视但极其重要的工程产出。我们会讨论文档的价值、README 的写法、Doxygen 生成 API 文档的方法，以及如何做好赛季交接文档。好的文档是团队知识的载体，是项目可持续发展的保障。

最后，我们会回顾版本控制与协作的最佳实践，包括分支策略、提交规范、代码审查和持续集成。这部分与后续的 Git 章节相呼应，从软件工程的角度讨论团队协作的工作流。

软件工程不是一堆枯燥的规则，而是让开发变得更轻松、更可控、更有成就感的方法论。当你的代码清晰易读、你的测试给你信心、你的文档让交接顺畅、你的团队高效协作时，你会感谢当初在软件工程上的投入。让我们开始这段旅程。


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

打开一个陌生的代码库，你最先注意到的是什么？不是算法的精妙，也不是架构的优雅，而是代码的"样子"——变量是怎么命名的、缩进用的是空格还是制表符、大括号放在行尾还是另起一行、注释写了什么。这些看似琐碎的细节，构成了代码的第一印象，也在很大程度上决定了你理解这段代码的难易程度。代码规范就是关于这些细节的约定，它让代码成为团队的共同语言。

==== 为什么需要统一的代码规范

每个程序员都有自己的编码习惯。有人喜欢用 `camelCase` 命名变量，有人偏爱 `snake_case`；有人习惯在运算符两边加空格，有人觉得紧凑一些更好；有人写详尽的注释，有人信奉"好代码不需要注释"。当一个人独自开发时，这些差异无关紧要。但当多人协作时，如果每个人都按照自己的风格编写代码，代码库很快就会变成一锅大杂烩。

想象一下这样的场景：你打开一个文件，前半部分变量名是 `imageWidth`，后半部分变成了 `image_height`；有的函数用四个空格缩进，有的用制表符；有的大括号跟在函数声明后面，有的另起一行。这种风格的不一致会给阅读者带来额外的认知负担——你的大脑需要不断地适应不同的风格，而不能专注于理解代码的逻辑。更糟糕的是，当你需要修改这样的代码时，你不知道应该遵循哪种风格，于是又增加了一种新的风格，混乱进一步加剧。

统一的代码规范解决的正是这个问题。当团队所有成员遵循相同的规范时，代码库呈现出一致的外观，仿佛出自同一人之手。新成员加入时，只需要学习一套规范，就能阅读和编写符合团队标准的代码。代码审查时，审查者可以专注于逻辑和设计，而不是争论风格问题。版本控制中的差异也会更加清晰——如果没有规范，一次简单的修改可能因为格式调整而产生大量无关的改动，淹没真正的变化。

选择哪种规范并不是最重要的，重要的是团队有一个规范并且严格遵守。业界已经有许多成熟的代码规范可供参考，其中 Google C++ Style Guide 是最广泛使用的 C++ 规范之一。它不仅规定了格式和命名，还包含了许多关于 C++ 语言使用的建议，是学习现代 C++ 最佳实践的好材料。接下来，我们以 Google C++ Style Guide 为基础，介绍 C++ 代码规范的核心要点。

==== 命名规范

命名是编程中最重要也最困难的事情之一。好的命名能让代码自解释，读者一眼就能明白变量的含义、函数的功能；糟糕的命名则让代码变成谜语，需要仔细阅读实现才能理解意图。

Google C++ Style Guide 对不同类型的标识符规定了不同的命名风格，这种差异化的命名让读者能够从名字本身判断标识符的类型。

文件名使用小写字母，单词之间用下划线连接。头文件使用 `.h` 扩展名，源文件使用 `.cpp` 扩展名。文件名应该反映其内容，通常与其中定义的主要类同名。例如，定义 `ImageProcessor` 类的文件应该命名为 `image_processor.h` 和 `image_processor.cpp`。

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

变量名使用小写字母加下划线（snake_case）。这包括局部变量、函数参数和公有成员变量。对于类的私有和保护成员变量，在名称末尾加一个下划线，以便与局部变量区分。这个小小的约定非常有用——当你看到 `image_width_` 时，立即知道它是成员变量而非局部变量。

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

常量和枚举值使用 `k` 前缀加大驼峰命名。这种命名让常量一眼就能被识别出来，避免与变量混淆。宏定义则使用全大写字母加下划线，但现代 C++ 中应尽量避免使用宏。

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

除了遵循格式规则，命名还有更本质的要求：名称应该准确、完整地描述其代表的含义。避免使用过于简短或含糊的名称，如 `temp`、`data`、`info`、`process()`；也避免使用过于冗长的名称，如 `the_current_image_frame_from_camera`。好的名称应该在准确和简洁之间取得平衡。在循环中使用 `i`、`j` 作为索引变量是可以接受的约定，但在其他场景下，应该使用更有意义的名称。

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

格式规范涉及代码的视觉呈现：缩进、空格、换行、大括号位置等。良好的格式让代码结构一目了然，就像排版精美的书籍比手写稿更易阅读。

缩进使用空格而非制表符，每级缩进 2 个或 4 个空格（Google 风格是 2 个，许多团队选择 4 个）。制表符在不同编辑器中可能显示为不同宽度，导致代码在你的屏幕上对齐完美，在别人的屏幕上却参差不齐。使用空格可以避免这个问题。

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

每行代码的长度应该限制在一定范围内，通常是 80 或 100 个字符。过长的行需要水平滚动才能看完，降低了可读性。当一行太长时，应该合理地换行。函数调用参数过多时，可以每个参数一行；长表达式可以在运算符处断开。

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

大括号的位置是一个经典的"圣战"话题。Google C++ Style Guide 规定：函数的左大括号另起一行，其他情况（类定义、控制语句等）左大括号放在行尾。但实际上，许多团队选择统一将左大括号放在行尾（K&R 风格），或者统一另起一行（Allman 风格）。无论选择哪种，团队内部保持一致即可。

```cpp
// Google 风格：函数大括号另起一行，其他在行尾
class Robot {
  void Move() {
    if (is_enabled_) {
      // ...
    }
  }
};

// K&R 风格：所有大括号都在行尾
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

注释是代码与人之间的对话。好的注释解释"为什么"而不是"是什么"——代码本身已经说明了它在做什么，注释应该补充代码无法表达的信息：为什么选择这种方案、这里有什么需要注意的陷阱、这个魔法数字的来源是什么。

文件头注释出现在每个文件的开头，说明文件的用途、作者、创建日期、版权信息等。不同团队对文件头的要求不同，有的要求详尽，有的比较简略。

```cpp
// Copyright 2024 RoboMaster Team. All rights reserved.
//
// Licensed under the MIT License.
//
// Author: Zhang San <zhangsan@example.com>
// Date: 2024-01-15
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
//   auto armors = detector.Detect(image);
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
// Apply bilateral filter to reduce noise while preserving edges.
// Bilateral filter is slower than Gaussian but better for armor detection.
cv::bilateralFilter(image, filtered, 9, 75, 75);

int retry_count = 0;
const int kMaxRetries = 3;  // Determined by network latency tests
while (retry_count < kMaxRetries) {
    // ...
}
```

TODO 注释用于标记需要后续处理的地方。它们应该包含具体的任务描述，最好还有负责人和预计完成时间。TODO 不应该长期存在——如果一个 TODO 超过一个月还没有处理，要么应该立即处理，要么应该删除或转为正式的任务跟踪。

```cpp
// TODO(zhangsan): Optimize this loop using SIMD. Current implementation
// is too slow for 60fps processing. Expected completion: 2024-02.
for (int i = 0; i < n; ++i) {
    // ...
}
```

==== 头文件规范

头文件的组织对大型项目的编译效率和模块化至关重要。良好的头文件实践可以减少编译依赖、加快编译速度、避免重复包含等问题。

防止头文件重复包含有两种方式：`#pragma once` 和传统的 `#ifndef` 守卫。`#pragma once` 更简洁，被所有主流编译器支持，是现代 C++ 推荐的方式。

```cpp
// 推荐：使用 #pragma once
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

头文件中应该只包含必要的声明，实现放在源文件中。尽量使用前向声明（forward declaration）代替包含头文件，减少编译依赖。如果只需要使用指针或引用，就不需要包含完整的类定义。

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

将对应的头文件放在第一个是一个聪明的技巧：如果这个头文件缺少某些必要的 `#include`，编译这个源文件时会立即报错，而不是等到其他文件包含它时才发现问题。

==== 现代 C++ 的额外建议

Google C++ Style Guide 最初制定时，C++11 还未发布。随着现代 C++ 的发展，一些额外的建议值得补充。

优先使用 `auto` 进行类型推导，特别是当类型很长或很明显时。但不要滥用——当类型对理解代码很重要时，显式写出类型更好。

```cpp
// 好：类型很长或很明显
auto iter = container.begin();
auto result = std::make_unique<MyClass>();
auto lambda = [](int x) { return x * 2; };

// 好：显式类型让意图更清晰
double ratio = GetRatio();  // 而不是 auto ratio = GetRatio();
```

使用初始化列表语法（`{}`）初始化变量，它可以防止窄化转换，更加安全。但要注意 `std::vector` 等容器的特殊情况。

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

使用智能指针管理动态内存，避免手动 `new` 和 `delete`。优先使用 `std::unique_ptr`，只在需要共享所有权时使用 `std::shared_ptr`。

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

手动维护代码格式既繁琐又容易遗漏。幸运的是，有成熟的工具可以自动化这项工作。

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

clang-tidy 是另一个 LLVM 工具，用于静态代码分析。它不仅检查格式，还能发现潜在的 bug、性能问题和不符合最佳实践的代码。clang-tidy 可以配置启用哪些检查，并能自动修复某些问题。

```bash
# 运行 clang-tidy 检查
clang-tidy my_file.cpp -- -std=c++17

# 自动修复可修复的问题
clang-tidy -fix my_file.cpp -- -std=c++17
```

在 VS Code 中，可以安装 C/C++ 扩展和 Clang-Format 扩展，配置保存时自动格式化。在 CLion 中，clang-format 支持是内置的。将格式化工具集成到开发流程中，可以让团队成员无需刻意关注格式问题，工具会自动处理。

==== 代码审查

代码审查（Code Review）是指在代码合并到主分支之前，由其他团队成员检查代码的过程。它是保障代码质量、传播知识、统一风格的重要实践。

代码审查的价值远不止于发现 bug。通过审查，团队成员可以相互学习——资深成员可以指导新成员，新成员的新鲜视角有时也能发现资深成员忽视的问题。审查过程中的讨论可以统一团队对技术问题的认识，形成共同的最佳实践。知道代码会被审查，编写者也会更加用心，不会轻易提交敷衍的代码。

代码审查应该关注什么？首先是正确性——代码是否实现了预期的功能，是否有逻辑错误，边界条件是否处理正确。其次是可维护性——代码是否清晰易懂，命名是否恰当，结构是否合理，是否有足够的注释。然后是一致性——代码是否符合团队规范，是否与代码库中其他部分风格一致。最后是性能和安全——是否有明显的性能问题，是否存在安全隐患。

作为审查者，应该提供建设性的反馈，而不是简单地批评。指出问题的同时，最好给出改进建议。对于风格问题，如果有工具可以自动检查，就不需要在审查中花费过多精力。尊重被审查者的工作，认可做得好的地方。

作为被审查者，应该以开放的心态接受反馈。审查的目的是改进代码，而不是评价人。对于不同意的反馈，可以讨论，但要用事实和理由说服对方，而不是固执己见。将审查意见视为学习机会，而不是对自己的否定。

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

关于格式，建议使用 4 空格缩进、100 字符行宽、K&R 大括号风格。这与 ROS 社区的习惯相近，也是许多团队的偏好。使用 clang-format 自动化格式检查，将配置文件纳入版本控制。

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

关于注释，建议所有公开的类和函数都有文档注释，说明功能、参数和返回值。对于复杂的算法，添加解释原理的注释或引用相关论文。对于临时的解决方案或已知的限制，使用 TODO 或 FIXME 标记。

关于代码审查，建议所有代码在合并前至少经过一人审查。对于核心模块的修改，建议有两人审查。审查时使用检查清单，确保不遗漏重要方面。将代码审查作为团队文化的一部分，而不是可选的流程。

代码规范不是一成不变的教条，而是团队协作的工具。最重要的是团队达成共识，并且一致地执行。工具可以帮助自动化格式检查，但对命名、设计、文档的关注需要每个成员的自觉。当遵循规范成为习惯，代码质量自然会提升，团队协作也会更加顺畅。



=== 设计模式的起源
*设计模式*(Design pattern)是软件开发者在长期实践中提炼出的、可复用的代码设计经验，它们经过大量项目验证，被系统化分类，并形成了完整的知识体系。设计模式是软件工程的基石脉络，如同大厦的结构一样。

设计模式使代码编制真正工程化，是软件工程的基石。在项目中合理地运用设计模式可以完美地解决很多问题，每种模式在现实中都有相应的原理来与之对应，且都描述了一个在我们周围不断重复发生的问题，以及该问题的核心解决方案，这也是设计模式能被广泛应用的原因。

1994 年，Erich Gamma、Richard Helm、Ralph Johnson 与 John Vlissides 四人共同出版了划时代的著作 #text(weight: "bold", style: "italic")[Design Patterns: Elements of Reusable Object-Oriented Software]（中文译名：《设计模式——可复用面向对象软件的基础》）。该书首次系统化地阐述了软件开发中"设计模式"这一核心概念，为面向对象软件设计奠定了理论基石。

在这本书中，GoF 将设计模式系统地归纳为三大类，共提出了 *"23 种经典设计模式"*，这些模式奠定了面向对象软件设计的基础框架。

然而需要指出的是，书中讨论的许多模式主要基于 *Java* 等当时主流的面向对象语言。在 *C++* ——尤其是 *现代 C++*（Modern C++）的发展背景下，由于语言本身拥有更强大的表达能力（如 RAII、模板、智能指针、`constexpr` 等特性），其中部分设计模式已不再必要，甚至被语言机制自然替代。

尽管如此，现代软件工程仍将设计模式分为三大类：

1. *创建型模式（Creational Patterns）*\
   关注对象的创建方式，以提升灵活性与可扩展性。

2. *结构型模式（Structural Patterns）*\
   关注类与对象的组织结构，使系统模块更清晰、更易复用。

3. *行为型模式（Behavioral Patterns）*\
   关注对象间的协作方式与职责划分，提升系统行为的稳定性与扩展性。

这些模式依然构成理解现代架构思想的重要基础，只是在 C++ 语境下，其实现方式随着语言进化而更为简洁与自然。

=== 设计模式的基本原则

设计模式的*核心目标*是实现*高内聚、低耦合*的软件架构。所谓"高内聚"，是指一个模块内部的各个元素紧密相关、职责明确；而"低耦合"则强调模块之间的依赖关系应尽可能松散，以便于系统的维护、扩展与升级。

为了达成这一目标，软件工程界总结出了以下*七大设计原则*，它们共同构成了设计模式的理论基石：

1. *开闭原则 (Open-Closed Principle, OCP)*

*对扩展开放，对修改关闭。*

软件实体（类、模块、函数等）应当在不修改现有代码的前提下进行功能扩展。这一原则是实现系统良好扩展性与可维护性的关键。想要达到这样的效果，需要充分利用接口、抽象类等机制，将易变部分与稳定部分分离。

开闭原则是设计模式的总纲，其他原则都是实现开闭原则的具体手段。

2. *单一职责原则 (Single Responsibility Principle, SRP)*

*一个类应该只有一个引起它变化的原因。*

类的职责应当单一明确，对外只提供一种功能。当一个类承担的职责过多时，这些职责之间可能会相互耦合，一个职责的变化可能会削弱或抑制这个类完成其他职责的能力。遵循单一职责原则可以提高类的可读性、可维护性，降低变更引起的风险。

3. *里氏替换原则 (Liskov Substitution Principle, LSP)*

*任何基类可以出现的地方，子类一定可以出现。*

里氏替换原则是面向对象设计的基本原则之一，是继承复用的基石。它要求子类在继承父类时，除了添加新的方法完成新增功能外，尽量不要重写父类的方法。只有当派生类可以替换掉基类，且软件单位的功能不受影响时，基类才能真正被复用。

里氏替换原则是对开闭原则的补充，它通过规范继承关系来实现抽象化，从而支撑开闭原则的实现。这一原则在 C++ 中通过虚函数机制在语言层面得到了实现。

4. *依赖倒置原则 (Dependence Inversion Principle, DIP)*

*依赖于抽象，不要依赖于具体实现。*

高层模块不应该依赖低层模块，两者都应该依赖其抽象（接口或抽象类）。抽象不应该依赖细节，细节应该依赖抽象。这一原则是开闭原则的基础，强调"面向接口编程"而非"面向实现编程"，从而降低模块间的耦合度。

5. *接口隔离原则 (Interface Segregation Principle, ISP)*

*使用多个专门的接口，而不使用单一的总接口。*

客户端不应该被迫依赖它不使用的接口方法。一个接口应该只提供一种对外功能，不应该把所有操作都封装到一个接口中。接口隔离原则要求将臃肿的接口拆分为多个细粒度的接口，降低类之间的耦合度，提高系统的灵活性。

6. *合成复用原则 (Composite Reuse Principle, CRP)*

*优先使用对象组合，而不是继承来达到复用的目的。*

在复用代码时，应优先选择对象组合（一个对象包含另一个对象）的方式，而不是使用类继承。继承会导致父类的任何变化都可能影响到子类的行为，增加了系统的脆弱性；而对象组合则降低了这种依赖关系，使系统更加灵活。这一原则是对里氏替换原则的补充，提示我们思考功能组合实现的正确方式。

7. *迪米特法则 (Law of Demeter, LoD)*

*一个对象应当对其他对象有尽可能少的了解。*

也称为*最少知识原则*，要求一个实体应当尽量少地与其他实体发生相互作用，使得系统功能模块相对独立，从而降低各个对象之间的耦合，提高系统的可维护性。

例如在程序设计中，各个模块之间相互调用时，通常会提供一个统一的接口来实现功能。这样其他模块不需要了解模块内部的实现细节（黑盒原理），当一个模块内部的实现发生改变时，不会影响其他模块的使用。


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

"它在我的机器上能跑啊！"——这可能是程序员最常说的一句话，也是最让人无奈的一句话。代码能运行并不意味着代码是正确的。你今天写的代码明天还能正常工作吗？修改了一个函数，会不会破坏其他地方的功能？重构了一个模块，原来的行为还保持不变吗？如果没有测试，你只能祈祷和手动验证。而有了测试，你可以在几秒钟内得到确切的答案。单元测试是程序员给自己买的保险——平时花一点时间编写，关键时刻能省下无数调试的痛苦。

==== 为什么要写测试

测试最直接的价值是验证代码的正确性。当你写完一个函数，如何确认它真的按预期工作？你可能会写一个 `main` 函数，手动调用几次，看看输出对不对。这种方法能解决眼前的问题，但一旦代码发生变化，你又得重新手动验证。如果有十个函数需要验证，每次修改都要手动测试一遍，这个负担会越来越重，最终你会放弃验证，只能"希望"代码是对的。

自动化测试解决了这个问题。测试代码被保存下来，可以反复执行。每次修改代码后，只需运行一下测试，几秒钟就能知道是否破坏了什么。这种即时反馈让你可以放心地修改代码，而不是战战兢兢地担心引入 bug。在 RoboMaster 开发中，算法经常需要调优参数、改进逻辑，如果没有测试保障，每次修改都是在冒险。

测试的另一个重要价值是支撑重构。随着项目演进，最初的设计可能不再适用，代码需要重构以保持健康。但重构是危险的——你要在不改变外部行为的前提下改变内部结构，如何确保"外部行为不变"？答案就是测试。如果有充分的测试覆盖，重构后运行测试全部通过，你就可以确信重构没有引入问题。没有测试的代码几乎不可能安全地重构，最终只能任其腐烂，直到不得不重写。

测试还能作为可执行的文档。好的测试用例清晰地展示了代码的使用方式和预期行为，比文字描述更加精确。当你不确定一个函数该怎么用时，看看它的测试用例往往能得到答案。测试用例也不会过时——如果测试与代码行为不符，测试就会失败，迫使你更新。

有些团队会说"我们没时间写测试"，但这是一个短视的观点。不写测试确实能节省一些时间，但这些时间迟早会以调试 bug 的形式还回来，而且往往是加倍偿还。一个隐蔽的 bug 可能在比赛现场暴露，导致整场比赛的失利；一个没有测试保护的修改可能引发连锁反应，花费数小时才能定位。测试不是额外的负担，而是提高开发效率的投资。

==== 测试金字塔

软件测试有多种类型，它们在测试范围、执行速度和维护成本上有所不同。测试金字塔是一个经典的模型，它描述了不同类型测试应有的比例。

单元测试位于金字塔的底层，数量最多。单元测试针对代码的最小可测试单元——通常是一个函数或一个类——验证其行为是否正确。单元测试应该快速（毫秒级）、独立（不依赖外部资源）、可重复（每次运行结果相同）。一个典型的项目可能有成百上千个单元测试，它们在每次代码提交时运行，提供快速反馈。

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

集成测试位于金字塔的中层。它测试多个模块组合在一起是否能正确协作。例如，测试视觉检测模块与跟踪模块的接口是否匹配，测试通信模块能否正确解析实际的数据包。集成测试比单元测试慢，因为涉及更多的代码和可能的外部资源，但它能发现单元测试无法发现的集成问题。

端到端测试（也叫系统测试）位于金字塔的顶层，数量最少。它测试整个系统作为一个整体是否能完成用户场景。对于 RoboMaster 机器人，端到端测试可能是在仿真环境中运行完整的自瞄流程，从图像输入到云台控制输出。端到端测试最接近真实使用场景，但也最慢、最难维护。

金字塔形状表示了推荐的测试比例：大量的单元测试、适量的集成测试、少量的端到端测试。这样的比例既能保证测试覆盖，又能保持测试的执行效率。如果你的测试金字塔是倒过来的（大量端到端测试、少量单元测试），测试运行会很慢，问题定位会很困难，测试也会很脆弱。

本节主要关注单元测试。单元测试是最基础也是最重要的测试类型，它是测试金字塔的基石。

==== Google Test 框架入门

Google Test（简称 gtest）是 C++ 社区最流行的单元测试框架。它由 Google 开发并开源，提供了丰富的断言、测试组织和运行功能。许多知名项目都使用 gtest，包括 Chromium、LLVM、OpenCV 等。

安装 gtest 在 Ubuntu 上非常简单：

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
    test/test_main.cpp
    test/test_math_utils.cpp
    test/test_detector.cpp
)

# 链接 GTest
target_link_libraries(my_tests
    GTest::gtest
    GTest::gtest_main
    my_library  # 被测试的库
)

# 注册测试
include(GoogleTest)
gtest_discover_tests(my_tests)
```

如果使用 `GTest::gtest_main`，gtest 会提供 `main` 函数，你不需要自己写。否则，需要在测试文件中添加：

```cpp
#include <gtest/gtest.h>

int main(int argc, char* argv) {
    testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
```

编写第一个测试非常简单。使用 `TEST` 宏定义一个测试用例，第一个参数是测试套件名，第二个参数是测试名：

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
# 构建
mkdir build && cd build
cmake ..
make

# 运行所有测试
./my_tests

# 运行特定测试套件
./my_tests --gtest_filter=MathUtils.*

# 运行特定测试
./my_tests --gtest_filter=MathUtils.AddPositiveNumbers
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

对于浮点数比较，永远不要使用 `EXPECT_EQ`，因为浮点数计算存在精度误差。使用 `EXPECT_FLOAT_EQ`、`EXPECT_DOUBLE_EQ` 或 `EXPECT_NEAR`：

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
        detector_->Init();
        
        // 加载测试图像
        test_image_ = cv::imread("test_data/armor_image.jpg");
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
    auto results = detector_->Detect(test_image_);
    EXPECT_FALSE(results.empty());
}

TEST_F(DetectorTest, ReturnsEmptyForBlankImage) {
    cv::Mat blank(480, 640, CV_8UC3, cv::Scalar(0, 0, 0));
    auto results = detector_->Detect(blank);
    EXPECT_TRUE(results.empty());
}

TEST_F(DetectorTest, ConfidenceAboveThreshold) {
    auto results = detector_->Detect(test_image_);
    for (const auto& armor : results) {
        EXPECT_GE(armor.confidence, config_.confidence_threshold);
    }
}
```

测试夹具的执行顺序是：构造函数 → `SetUp()` → 测试体 → `TearDown()` → 析构函数。每个测试都会创建一个新的夹具实例，所以测试之间是隔离的。

如果多个测试套件需要共享更昂贵的初始化（比如加载大型模型），可以使用 `SetUpTestSuite()` 和 `TearDownTestSuite()` 静态方法，它们只在整个测试套件前后各执行一次：

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
        AngleTestParam{90, M_PI / 2},
        AngleTestParam{180, M_PI},
        AngleTestParam{360, 2 * M_PI},
        AngleTestParam{-90, -M_PI / 2}
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
// 范围
testing::Range(start, end, step);

// 布尔值
testing::Bool();  // true, false

// 组合
testing::Combine(testing::Values(1, 2), testing::Values("a", "b"));
// 生成 (1, "a"), (1, "b"), (2, "a"), (2, "b")
```

==== 测试驱动开发

测试驱动开发（Test-Driven Development，TDD）是一种先写测试、后写实现的开发方法。它遵循"红-绿-重构"的循环：

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

TDD 的好处是：

首先，它确保代码总是可测试的。因为测试先于实现编写，你不会写出难以测试的代码。

其次，它迫使你在编码前思考接口设计。写测试时你就在思考：这个函数应该接收什么参数？返回什么结果？这种思考往往能产生更好的设计。

第三，它提供了即时反馈。每次实现一小块功能，马上就能验证是否正确，而不是写完一大堆代码再调试。

TDD 并不适合所有场景。对于探索性的代码、需求不明确的原型、或者 GUI 相关的代码，TDD 可能不太合适。但对于逻辑明确的算法、工具函数、数据处理模块，TDD 是非常有效的方法。

==== 什么样的代码容易测试

有些代码很容易测试，有些代码测试起来非常痛苦。理解什么样的代码容易测试，可以指导你写出更好的代码设计。

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

小函数比大函数容易测试。一个做很多事情的大函数，需要准备很多前置条件，验证很多结果，测试用例会很复杂。把大函数拆成多个小函数，每个小函数单独测试，会简单得多。

避免全局状态。依赖全局变量或单例的代码难以测试，因为测试之间会相互影响。如果必须使用，至少提供重置状态的方法。

==== Mock 与依赖注入

当被测代码依赖外部资源（数据库、网络、硬件）时，直接使用真实依赖会让测试变慢、变脆弱、变得不可重复。Mock（模拟对象）是解决这个问题的标准方法。

Google Mock（现在是 gtest 的一部分）提供了创建 Mock 对象的便捷方式：

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

GMock 提供了丰富的匹配器和动作：

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

依赖注入是使 Mock 成为可能的设计模式。核心思想是：类不应该自己创建依赖，而应该从外部接收依赖。这有几种实现方式：

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

Setter 注入适合可选依赖：

```cpp
class Logger {
public:
    void SetOutput(std::shared_ptr<IOutput> output) {
        output_ = output;
    }
    
    // ...
};
```

==== 测试覆盖率

测试覆盖率衡量测试执行了多少代码。常见的覆盖率指标包括：

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

CMake 配置：

```cmake
option(ENABLE_COVERAGE "Enable coverage reporting" OFF)

if(ENABLE_COVERAGE)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fprofile-arcs -ftest-coverage")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fprofile-arcs -ftest-coverage")
endif()
```

覆盖率是有用的指标，但不要过度追求。100% 覆盖率并不意味着代码没有 bug——测试可能覆盖了代码但没有检查正确的条件。更重要的是测试的质量而非数量。一般来说，核心逻辑应该有较高的覆盖率（80% 以上），而 UI、胶水代码等可以低一些。

==== RoboMaster 中的测试实践

在 RoboMaster 项目中，测试应该聚焦于核心算法和关键逻辑。以下是一些具体的建议。

算法模块是最应该测试的部分。检测算法、跟踪算法、预测算法、弹道解算——这些模块逻辑复杂、容易出错，而且相对独立，很适合单元测试。

```cpp
// 弹道解算测试
class BallisticSolverTest : public testing::Test {
protected:
    void SetUp() override {
        solver_ = std::make_unique<BallisticSolver>(28.0);  // 28 m/s 弹速
    }
    
    std::unique_ptr<BallisticSolver> solver_;
};

TEST_F(BallisticSolverTest, HorizontalTarget) {
    // 水平目标，不需要补偿
    double pitch = solver_->Solve(5.0, 0.0);  // 5米远，高度差为0
    EXPECT_NEAR(pitch, 0.0, 0.01);  // 接近水平
}

TEST_F(BallisticSolverTest, ElevatedTarget) {
    // 高处目标，需要向上补偿
    double pitch = solver_->Solve(5.0, 2.0);  // 5米远，高2米
    EXPECT_GT(pitch, 0.0);  // 仰角应该为正
}

TEST_F(BallisticSolverTest, DistanceAffectsDrop) {
    // 距离越远，下坠补偿越大
    double pitch_near = solver_->Solve(3.0, 0.0);
    double pitch_far = solver_->Solve(8.0, 0.0);
    EXPECT_GT(pitch_far, pitch_near);
}
```

通信协议测试确保数据包的打包和解析正确：

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
    std::vector<uint8_t> packet = {0xA5, 0x01, /* ... */};
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

坐标变换测试验证几何计算的正确性：

```cpp
TEST(CoordinateTransform, CameraToWorld) {
    Transform tf;
    tf.SetCameraToGimbal(/* ... */);
    tf.SetGimbalToWorld(/* ... */);
    
    Point3D point_camera{1.0, 0.0, 5.0};
    Point3D point_world = tf.CameraToWorld(point_camera);
    
    // 验证变换结果
    EXPECT_NEAR(point_world.x, expected_x, 0.001);
    EXPECT_NEAR(point_world.y, expected_y, 0.001);
    EXPECT_NEAR(point_world.z, expected_z, 0.001);
}

TEST(CoordinateTransform, RoundTrip) {
    // 变换后再逆变换应该得到原点
    Transform tf;
    Point3D original{1.0, 2.0, 3.0};
    Point3D transformed = tf.CameraToWorld(original);
    Point3D back = tf.WorldToCamera(transformed);
    
    EXPECT_NEAR(back.x, original.x, 0.001);
    EXPECT_NEAR(back.y, original.y, 0.001);
    EXPECT_NEAR(back.z, original.z, 0.001);
}
```

仿真环境对于端到端测试非常有价值。Gazebo、Unity 等仿真器可以模拟机器人的物理行为和传感器输入，让你在不需要真实硬件的情况下测试完整的系统。仿真测试可以自动化运行，在每次代码提交时验证系统的整体行为。虽然仿真与现实存在差距（sim-to-real gap），但它能发现大量问题，节省宝贵的实机调试时间。

测试不是写完就结束的任务，而是需要持续维护的资产。当代码变化时，测试也要相应更新。当发现 bug 时，先写一个复现 bug 的测试，再修复 bug——这样可以防止 bug 复发。将测试作为持续集成的一部分，每次代码推送都自动运行，及早发现问题。

编写测试需要时间，但这是值得的投资。测试给你信心去修改和改进代码，让你能够快速迭代而不是小心翼翼。在 RoboMaster 紧张的赛季中，这种信心尤为重要。


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

=== 性能分析与优化
// 让程序跑得更快
// - 过早优化是万恶之源
// - 性能分析工作流：测量 → 分析 → 优化 → 验证
// - 时间测量：
//   std::chrono 精确计时
//   基准测试框架（Google Benchmark）
// - 性能分析工具：
//   perf 基础使用
//   火焰图（Flame Graph）
//   Valgrind callgrind
//   Intel VTune（简介）
// - 常见优化方向：
//   算法复杂度
//   内存访问模式（缓存友好）
//   避免不必要的拷贝（移动语义）
//   减少内存分配
//   多线程并行
// - 编译器优化选项（-O2, -O3, -march）
// - RoboMaster 性能优化案例：
//   图像处理流水线优化
//   控制循环的实时性保障

=== 文档编写
// 代码之外的工程产出
// - 文档的价值：写给未来的自己和队友
// - 代码即文档：自解释的命名与结构
// - 注释的艺术：何时写、写什么
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

代码是程序员与机器的对话，而文档是程序员与人的对话——可能是与队友、与未来的维护者，也可能是与几个月后已经忘记实现细节的自己。许多程序员不喜欢写文档，觉得这是编码之外的"杂事"，浪费时间。但当你在凌晨三点调试一个陌生的模块，翻遍代码却找不到任何解释时；当新队员接手项目，花了一周时间还没搞清楚系统架构时；当你试图使用去年写的库，却想不起那些参数是什么含义时——你会深刻体会到文档的价值。好的文档是项目的第二生命，它让知识得以传承，让协作成为可能。

==== 文档的价值

文档最直接的价值是降低沟通成本。在一个团队中，如果每个问题都需要口头解释，那么回答问题的人会被频繁打断，提问的人也要等待对方有空。而一份好的文档可以回答大多数常见问题，让团队成员能够自助式地获取信息。当有人问"这个函数怎么用"或"这个模块是做什么的"时，你可以说"看文档"，而不是每次都从头解释一遍。

文档的另一个重要价值是保存知识。人的记忆是不可靠的，今天清清楚楚的设计决策，三个月后可能就想不起来了。更何况团队成员会毕业、会换项目，如果知识只存在于人的脑子里，人走了知识也就丢了。文档将知识外化，使其独立于任何个人而存在。一份记录了设计思路、架构决策、踩过的坑的文档，是团队最宝贵的资产之一。

文档还能帮助作者理清思路。写文档的过程迫使你用清晰的语言解释自己的设计，这个过程往往会暴露出之前没有意识到的问题。如果你发现某个部分很难解释清楚，很可能是因为设计本身就不够清晰。有经验的工程师常常在写代码之前先写设计文档，通过写作来思考和验证方案。

对于 RoboMaster 团队来说，文档还有一层特殊的意义：赛季传承。每年都有老队员毕业、新队员加入，如果没有文档，新人只能从零开始摸索，前人的经验无法积累。而有了好的文档，新队员可以快速了解系统全貌，在前人的基础上继续前进，而不是每年都在重复发明轮子。

==== 代码即文档

在讨论如何写文档之前，我们首先要认识到：最好的文档是代码本身。如果代码写得足够清晰，很多时候不需要额外的解释。这就是"代码即文档"（Code as Documentation）的理念。

清晰的命名是代码自解释的基础。一个名为 `CalculateProjectileDropCompensation` 的函数，不需要注释也能让人明白它是计算弹道下坠补偿的。而一个名为 `Calc` 的函数，即使有注释也需要读者花费额外的精力去理解。变量名也是如此：`remainingAmmo` 比 `n` 有意义得多。好的命名就像好的路标，让读者不需要地图也能找到方向。

合理的代码结构也是一种文档。当一个函数只做一件事、一个类只有一个职责时，代码的意图就很明显。当相关的功能被组织在一起、模块之间有清晰的边界时，系统的架构就呼之欲出。相反，如果一个函数做了十件不同的事，即使每一行都有注释，也很难理解它的整体逻辑。

类型系统也是文档的一部分。在 C++ 中，使用强类型而不是原始类型可以传达更多信息。例如，`Angle` 类型比 `double` 更能说明参数的含义；`std::optional<Target>` 比返回空指针更能表达"可能没有结果"的语义；`enum class RobotState` 比一堆整数常量更能说明状态的含义和取值范围。

```cpp
// 不好：类型没有传达信息
double Calculate(double a, double b, int mode);

// 好：类型本身就是文档
Velocity CalculateVelocity(Distance distance, Duration time);
std::optional<Target> DetectTarget(const Image& image);
```

常量和配置也应该自解释。不要在代码中使用魔法数字，而是定义有意义的常量。当读者看到 `kMaxDetectionDistance` 时，他立刻知道这是最大检测距离；而看到 `5.0` 时，他只能猜测这个数字的含义。

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

然而，代码即文档有其局限性。代码能够说明"是什么"（what）和"怎么做"（how），但很难表达"为什么"（why）。为什么选择这个算法而不是那个？为什么这个参数是 5.0 而不是 3.0？为什么要加这个看起来多余的检查？这些问题需要注释和文档来回答。

==== 注释的艺术

注释是代码中嵌入的文档，用于解释代码本身无法表达的信息。好的注释能够显著提高代码的可读性，而糟糕的注释则可能误导读者、浪费时间。掌握何时写注释、写什么注释，是一门需要练习的艺术。

首先要明确的是，注释不是用来解释代码"做了什么"的。如果代码需要注释来解释它在做什么，这通常意味着代码本身不够清晰，应该重构而不是添加注释。那些像 `i++; // 将 i 加 1` 这样的注释毫无价值，只会增加阅读负担。

注释真正的价值在于解释"为什么"。为什么选择这种实现方式？有什么约束或权衡？这里有什么需要注意的陷阱？这些是代码本身无法表达的信息，是注释的用武之地。

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

// 好：解释"为什么"
// 优先处理近距离目标，因为它们对比赛结果影响更大。
// 远距离目标的检测置信度较低，容易产生误判。
for (const auto& target : targets) {
    if (target.distance < max_distance) {
        results.push_back(target);
    }
}
```

注释还应该解释非显而易见的代码。有时候，为了性能、兼容性或规避某个 bug，代码不得不写得比较晦涩。这时候，注释可以解释这样写的原因，避免后人"好心"地重构掉这些看起来奇怪的代码。

```cpp
// 使用位运算代替除法，在 ARM 平台上快约 10 倍。
// 仅当 divisor 是 2 的幂时有效。
int FastDivide(int value, int divisor) {
    int shift = __builtin_ctz(divisor);  // 计算尾随零的个数
    return value >> shift;
}

// OpenCV 4.2 之前的版本在这里有内存泄漏，需要手动释放。
// 参见：https://github.com/opencv/opencv/issues/12345
cv::Mat temp;
// ... 使用 temp ...
temp.release();  // 必要的手动释放
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

TODO 和 FIXME 注释用于标记待办事项和已知问题。它们是对未来的承诺，提醒自己或他人这里还有工作要做。好的 TODO 注释应该包含具体的任务描述、负责人和预期时间。定期清理 TODO 是良好的习惯——如果一个 TODO 存在超过一个月还没处理，要么立即处理，要么承认它不重要并删除。

```cpp
// TODO(zhangsan): 实现多目标跟踪。当前只支持单目标。
//                 预计下周完成。

// FIXME: 在光线变化剧烈时会产生误检。
//        需要添加时域滤波来改善稳定性。

// HACK: 临时解决方案，等待上游库修复后移除。
//       跟踪 issue: https://github.com/xxx/xxx/issues/123
```

==== README：项目的门面

README 是项目的门面，通常是用户接触项目的第一份文档。一份好的 README 能让人在几分钟内了解项目是什么、能做什么、怎么开始使用。它应该简洁但完整，回答读者最关心的问题。

一份标准的 README 通常包含以下部分：

项目标题和简介放在最开头，用一两句话说明项目是什么、解决什么问题。如果有项目 logo 或徽章（构建状态、版本号等），可以放在这里。

```markdown
# RoboMaster Vision System

基于深度学习的 RoboMaster 自瞄视觉系统，支持装甲板检测、跟踪和预测。

![Build Status](https://img.shields.io/badge/build-passing-green)
![Version](https://img.shields.io/badge/version-2.0.0-blue)
```

功能特性列出项目的主要功能，让读者快速了解项目能做什么。可以用列表形式简洁地呈现。

```markdown
## 功能特性

- 🎯 实时装甲板检测（60+ FPS @ 1080p）
- 🔄 多目标跟踪与 ID 关联
- 📈 基于卡尔曼滤波的运动预测
- 🎮 支持 ROS 2 Humble 集成
- ⚡ CUDA 加速推理
```

快速开始是最重要的部分之一，它应该让读者能够在最短时间内运行项目。包括环境要求、安装步骤和基本使用示例。命令应该可以直接复制执行，不要让读者猜测。

````markdown
## 快速开始

### 环境要求

- Ubuntu 22.04
- ROS 2 Humble
- CUDA 11.8+
- OpenCV 4.5+

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

对于库或框架，API 文档是不可或缺的。它详细描述每个类、函数、参数的用法，是开发者使用库时的参考手册。手写 API 文档工作量大且容易过时，因此通常使用工具从代码中的注释自动生成。Doxygen 是 C++ 社区最流行的文档生成工具。

Doxygen 通过解析代码中特定格式的注释来生成文档。最常用的注释风格是 Javadoc 风格（以 `/*` 开头）和 Qt 风格（以 `/*!` 开头）。以下是一些常用的 Doxygen 命令：

```cpp
/*
 * @file armor_detector.h
 * @brief 装甲板检测器的头文件
 * @author Zhang San
 * @date 2024-01-15
 */

/*
 * @brief 装甲板检测器类
 * 
 * ArmorDetector 使用深度学习模型检测图像中的装甲板。
 * 它支持红色和蓝色装甲板的检测，并能处理不同光照条件。
 * 
 * @note 此类不是线程安全的。每个线程应创建独立的实例。
 * 
 * 使用示例：
 * @code
 * ArmorDetector detector(config);
 * detector.Init();
 * auto armors = detector.Detect(image);
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
    /*
     * @brief 构造函数
     * @param config 检测器配置参数
     * @throws std::invalid_argument 如果配置无效
     */
    explicit ArmorDetector(const DetectorConfig& config);
    
    /*
     * @brief 初始化检测器
     * 
     * 加载模型并准备推理引擎。此方法必须在 Detect() 之前调用。
     * 
     * @return true 如果初始化成功
     * @return false 如果初始化失败（如模型文件不存在）
     */
    bool Init();
    
    /*
     * @brief 检测图像中的装甲板
     * 
     * @param image 输入图像，必须是 BGR 格式
     * @param timestamp 图像时间戳，用于时间同步
     * @return 检测到的装甲板列表，按置信度降序排列
     * 
     * @pre Init() 已成功调用
     * @pre image 不为空
     * 
     * @warning 此方法会修改内部状态，不要在多线程中共享实例
     */
    std::vector<Armor> Detect(const cv::Mat& image, double timestamp);
    
    /*
     * @brief 设置目标颜色
     * @param color 目标颜色
     * @see TargetColor
     */
    void SetTargetColor(TargetColor color);
    
    /*
     * @brief 获取当前检测统计信息
     * @return 包含检测帧数、平均耗时等的统计信息
     */
    DetectorStats GetStats() const;

private:
    DetectorConfig config_;  ///< 检测器配置
    bool initialized_;       ///< 是否已初始化
    // ...
};

/*
 * @brief 目标颜色枚举
 */
enum class TargetColor {
    kRed,   ///< 红色方
    kBlue   ///< 蓝色方
};

/*
 * @struct Armor
 * @brief 装甲板检测结果
 */
struct Armor {
    cv::Point2f center;     ///< 装甲板中心点（像素坐标）
    cv::Size2f size;        ///< 装甲板尺寸（像素）
    double confidence;      ///< 检测置信度，范围 [0, 1]
    int id;                 ///< 装甲板编号（1-5 对应英雄到哨兵）
    TargetColor color;      ///< 装甲板颜色
};
```

配置和运行 Doxygen 非常简单。首先安装 Doxygen：

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

除了代码中的注释和 API 文档，一个完整的项目还需要其他类型的文档。不同文档面向不同的读者、服务于不同的目的。

需求文档描述系统应该做什么。它定义功能需求（系统应该具备什么功能）和非功能需求（性能、可靠性、可维护性等要求）。需求文档是开发的起点，所有后续工作都是为了满足需求。在 RoboMaster 中，需求可能包括：检测精度要达到多少、延迟不能超过多少毫秒、要支持哪些目标类型等。

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

设计文档描述系统如何实现需求。它包括系统架构、模块划分、接口定义、数据流、关键算法等。设计文档是开发者的蓝图，帮助团队成员理解系统的整体结构和设计决策。好的设计文档不仅说明"怎么做"，还要解释"为什么这么做"。

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

采用 YOLOv8 进行装甲板检测，原因：
1. 速度快，满足实时性要求
2. 准确率高，尤其对小目标
3. 社区支持好，便于优化

### 跟踪模块

采用 EKF 进行状态估计，状态向量：
- 位置 (x, y, z)
- 速度 (vx, vy, vz)
- 装甲板朝向 θ

## 接口定义

...
```

用户手册面向最终用户，说明如何安装、配置和使用系统。它应该假设读者不了解内部实现，用清晰的语言和步骤指导用户完成任务。对于 RoboMaster 项目，用户可能是操作手或调试人员。

变更日志（CHANGELOG）记录项目的版本历史和每个版本的变化。它帮助用户了解版本之间的差异，决定是否升级，以及升级时需要注意什么。一个常见的格式是 Keep a Changelog：

```markdown
# 变更日志

本项目遵循 [语义化版本](https://semver.org/)。

## [2.1.0] - 2024-03-15

### 新增
- 支持能量机关检测
- 添加录像回放功能

### 变更
- 升级 YOLOv8 模型，检测速度提升 20%
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

Markdown 是最流行的文档格式之一，几乎所有的代码托管平台都支持它。掌握 Markdown 的写作技巧可以让你的文档更清晰、更易读。

结构化是好文档的基础。使用标题建立层次结构，让读者能够快速把握文档的脉络。但不要过度嵌套——三级标题通常就足够了，更深的层次可能意味着文档需要拆分。

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

代码块是技术文档的重要组成部分。始终指定语言以获得语法高亮，使用行内代码标记命令、函数名、文件名等。

```markdown
运行 `ros2 launch` 启动节点：

```bash
ros2 launch rm_vision detector.launch.py
```

函数 `Detect()` 返回检测结果。
```

表格适合展示结构化的对比信息。保持表格简洁，复杂的内容应该用其他方式呈现。

```markdown
| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| confidence_threshold | float | 0.7 | 置信度阈值 |
| nms_threshold | float | 0.4 | NMS 阈值 |
| target_color | string | "red" | 目标颜色 |
```

图片和图表可以大大提高文档的可理解性。系统架构图、流程图、效果截图都是有价值的。使用 Mermaid 可以在 Markdown 中直接编写图表：

````markdown
```mermaid
graph LR
    A[相机] --> B[检测器]
    B --> C[跟踪器]
    C --> D[预测器]
    D --> E[云台控制]
```
````

链接让文档形成网络。使用相对链接引用项目内的其他文档，使用外部链接引用参考资料。但不要过度链接——每个链接都是一个潜在的离开当前上下文的机会。

```markdown
详细配置说明请参阅 [配置文档](./config.md)。

算法原理基于这篇 [论文](https://arxiv.org/abs/xxx)。
```

==== 文档即代码

"文档即代码"（Docs as Code）是一种现代的文档管理理念：将文档视为代码一样对待，使用相同的工具和流程来管理。

首先，文档应该纳入版本控制。将文档与代码放在同一个仓库中，使用 Git 追踪变更历史。这样可以保证文档与代码的版本对应，也可以回溯历史版本。代码审查流程也应该包括文档——修改代码时，检查相关文档是否需要更新。

其次，文档应该使用纯文本格式。Markdown、reStructuredText、AsciiDoc 等格式易于编辑、易于比较差异、易于自动处理。避免使用 Word 等二进制格式，它们难以进行版本控制和协作编辑。

第三，可以利用 CI/CD 自动化文档流程。代码推送时自动构建文档、检查链接、部署到网站。这样可以保证文档始终是最新的，也可以在问题出现时及早发现。

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
      - uses: actions/checkout@v3
      
      - name: Build Doxygen
        run: doxygen Doxyfile
        
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./docs/api/html
```

最后，鼓励团队成员贡献文档。降低贡献门槛——使用简单的格式、提供模板、及时审查 PR。将文档贡献视为与代码贡献同等重要的工作。

==== RoboMaster 文档实践

结合 RoboMaster 的实际情况，以下是一些具体的文档实践建议。

赛季交接文档是 RoboMaster 团队最重要的文档之一。每年赛季结束后，核心队员应该编写详细的交接文档，包括：系统整体架构和设计思路、各模块的功能和接口、调试经验和已知问题、本赛季的改进和遗留问题、对下赛季的建议。这份文档将成为新队员的入门指南，也是团队知识积累的载体。

```markdown
# 2024 赛季自瞄系统交接文档

## 系统概述

本赛季自瞄系统采用 YOLOv8 + EKF 架构...

## 取得的成果

- 检测帧率从 30 FPS 提升到 60 FPS
- 命中率从 60% 提升到 80%
- 支持了能量机关检测

## 遗留问题

1. 强光下仍有误检（建议添加时域滤波）
2. 远距离检测精度不足（建议尝试更大的模型）
3. 代码耦合度高（建议重构跟踪模块）

## 下赛季建议

- 考虑使用 Transformer 架构
- 完善单元测试覆盖
- 整理代码规范
```

硬件接口文档对于软硬件协作至关重要。它应该详细描述通信协议、数据格式、引脚定义、时序要求等。当软件组和电控组需要对接时，这份文档可以避免大量的沟通成本。

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
````

调试手册记录常见问题的诊断和解决方法。比赛现场时间紧迫，一份好的调试手册可以帮助快速定位和解决问题。

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

文档不是写完就结束的一次性工作，而是需要持续维护的活文档。每次代码修改、问题解决、经验总结，都应该反映到文档中。将文档更新作为开发流程的一部分，而不是事后的补充工作。团队可以建立这样的规范：每个 PR 如果涉及接口变更，必须同时更新相关文档；每次调试解决的问题，都要记录到调试手册中；每个赛季结束，必须完成交接文档。

文档是软件工程中经常被忽视但极其重要的一环。它是代码与人之间的桥梁，是知识传承的载体，是团队协作的基础。花在文档上的时间不是浪费，而是对未来的投资。当你写文档时，想象一下几个月后的自己、刚加入团队的新人、或者在比赛现场焦急调试的队友——你写下的每一个字，都可能在某个时刻帮助到他们。


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

版本控制是现代软件工程的基石。无论是一个人的小项目还是数百人协作的大型系统，版本控制都是不可或缺的工具。Git 作为当今最流行的版本控制系统，已经成为每个开发者必须掌握的技能。本节不会详细讲解 Git 的具体命令——那些内容会在后续的 Git 专题章节中介绍。这里我们从软件工程的角度，讨论版本控制在团队协作中的作用、分支策略的选择、代码审查的实践，以及持续集成的概念。理解这些工程实践，你才能真正发挥版本控制的价值。

==== 版本控制的工程意义

在没有版本控制的年代，开发者们用各种原始的方法管理代码变化：手动复制文件夹并命名为 `project_v1`、`project_v2`、`project_final`、`project_final_final`；通过邮件或 U 盘传递代码；遇到问题时绝望地试图回忆"昨天的代码是什么样的"。这种方式在个人小项目中勉强可行，但在团队协作中会迅速崩溃。

版本控制系统从根本上解决了这些问题。它记录了代码的完整历史——每一次修改是谁做的、什么时候做的、改了什么、为什么改。你可以随时回到过去的任何版本，比较两个版本之间的差异，追踪某个 bug 是何时引入的。这种时间旅行的能力给了开发者巨大的安全感：任何修改都可以撤销，任何错误都可以恢复。

对于团队协作，版本控制提供了一个协调多人同时工作的机制。每个人可以在自己的分支上独立开发，完成后合并到主线。系统会自动检测冲突，帮助你解决不同人修改同一文件的情况。没有版本控制，多人协作几乎是不可能的——你无法知道别人改了什么，也无法安全地整合各自的工作。

Git 还带来了分布式的优势。每个开发者的本地仓库都包含完整的历史，可以离线工作、本地提交，之后再与远程仓库同步。这与早期的集中式版本控制系统（如 SVN）形成对比——那些系统需要持续的网络连接，服务器宕机时所有人都无法工作。

对于 RoboMaster 开发来说，版本控制还有特殊的意义。比赛是有时间节点的，你可能需要回滚到某个稳定版本参加比赛，同时继续开发新功能。不同的机器人类型可能需要不同的代码配置，分支可以帮助管理这些变体。赛后复盘时，你可以追溯每一个改动，分析问题的根源。这些都是版本控制带来的工程能力。

==== 分支策略：组织协作的艺术

分支是 Git 最强大的特性之一，但如何使用分支却是一个需要团队约定的问题。没有统一的分支策略，团队成员各自为政，分支混乱，合并困难，最终陷入"合并地狱"。好的分支策略既要支持并行开发，又要保持代码库的整洁和稳定。

Git Flow 是最经典的分支模型，由 Vincent Driessen 在 2010 年提出。它定义了严格的分支结构：`main`（或 `master`）分支始终是生产就绪的代码；`develop` 分支是开发主线，包含最新的开发成果；每个新功能在独立的 `feature` 分支上开发；发布前创建 `release` 分支进行最后的测试和修复；生产环境的紧急修复在 `hotfix` 分支上进行。

这种模型的优点是结构清晰、角色分明。`main` 分支的稳定性有保障，可以随时发布；`develop` 分支允许激进的开发；功能分支隔离了不同功能的开发，避免相互干扰。对于有固定发布周期的产品，Git Flow 工作得很好。

但 Git Flow 也有其复杂性。多个长期分支需要频繁同步，维护成本较高。对于持续部署的项目来说，`release` 分支可能是多余的。RoboMaster 项目通常没有传统软件那样的发布周期，使用完整的 Git Flow 可能过于繁琐。

GitHub Flow 是一个更简单的替代方案。它只有一个长期分支 `main`，所有开发都在功能分支上进行。功能完成后，通过 Pull Request 合并回 `main`，合并后立即可以部署。这种模型简单、灵活，适合持续部署和快速迭代的项目。

对于 RoboMaster 团队，一个实用的策略可能介于两者之间。`main` 分支保持稳定，是比赛时使用的版本；开发在功能分支上进行；合并前通过 Pull Request 进行代码审查；在重要比赛前，可能需要创建一个 `stable` 分支进行最后的测试。具体的策略应该根据团队规模、开发节奏和项目特点来调整，没有放之四海而皆准的答案。

无论采用什么策略，有几个原则是通用的。分支应该短命——长期存在的功能分支会积累大量冲突，合并时痛苦不堪。定期从主线同步更新到功能分支，保持与主线的差距可控。合并前确保分支是可工作的，至少能通过编译和基本测试。

==== 提交信息：代码历史的叙事

提交信息（commit message）看似是小事，但它对代码库的可维护性有着深远的影响。好的提交信息让人一眼就能理解这次修改做了什么、为什么做；差的提交信息让人一头雾水，不得不去看代码差异才能理解变化。

我们都见过这样的提交信息：`fix bug`、`update`、`修改`、`test`、`asdf`。这些信息毫无意义——每个提交都是在"修改"什么，问题是修改了什么？几个月后当你需要追溯某个问题时，这样的提交历史毫无帮助。

Conventional Commits 是一种被广泛采用的提交信息规范。它定义了结构化的格式，让提交信息既人类可读又机器可解析。基本格式是：

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

`type` 表示提交的类型：`feat` 是新功能，`fix` 是 bug 修复，`docs` 是文档更新，`refactor` 是重构，`test` 是测试相关，`chore` 是构建或工具相关的杂务。`scope` 是可选的，表示影响的范围，如模块名或组件名。`description` 是简短的描述，使用祈使语气（"add feature" 而不是 "added feature"）。

一些具体的例子可以说明什么是好的提交信息：

```
feat(detector): add armor number classification

Implement CNN-based number classification for detected armors.
The model achieves 98% accuracy on the test set.

Closes #42
```

```
fix(tracker): correct Kalman filter initialization

The previous initialization caused divergence when target
first appears at the edge of the frame. Now uses measurement
as initial state estimate.
```

```
refactor(solver): extract ballistic calculation to separate class

No functional changes. Improves testability and separation
of concerns.
```

这些提交信息清晰地传达了改动的类型、范围和内容。将来查看历史时，不需要看代码就能理解每次提交做了什么。

好的提交习惯还包括原子性提交——每个提交应该是一个逻辑单元，只做一件事。不要把多个不相关的修改塞进一个提交，也不要把一个功能拆成太多琐碎的提交。如果提交信息需要用"和"字连接多件事，那可能应该是多个提交。

团队应该就提交信息规范达成一致。可以使用 commitlint 等工具自动检查提交信息格式，确保每个人都遵守约定。这个小小的纪律投资会在代码维护时带来巨大的回报。

==== Pull Request 与代码审查

代码审查（Code Review）是软件工程中提高代码质量的关键实践。其核心思想很简单：在代码合并到主线之前，让其他团队成员检查和评论。这个过程可以发现 bug、改进设计、传播知识、维护代码风格一致性。

在 GitHub 和 GitLab 等平台上，代码审查通过 Pull Request（或 Merge Request）进行。开发者完成功能分支后，创建一个 Pull Request，请求将分支合并到主线。其他团队成员会收到通知，可以查看改动、添加评论、提出修改建议。只有在审查通过后，代码才能合并。

好的代码审查关注几个方面。首先是正确性：代码是否实现了预期的功能？有没有明显的 bug？边界情况是否处理了？其次是设计：代码结构是否合理？是否符合项目的架构模式？有没有更好的实现方式？第三是可读性：代码是否易于理解？命名是否清晰？是否有足够的注释？第四是测试：是否有相应的测试覆盖？测试是否充分？

作为审查者，态度和措辞很重要。审查的目的是改进代码，而不是批评人。使用"我们可以考虑..."而不是"你应该..."，提出建议而不是命令。解释为什么某个改动更好，而不仅仅是说"这样不对"。记住，每个人都是来学习和进步的。

作为被审查者，要以开放的心态接受反馈。审查者花时间看你的代码是在帮助你。不要把批评当作对个人的攻击。如果不同意某个建议，可以讨论，但要尊重团队的决定。及时响应审查意见，不要让 Pull Request 长时间挂起。

对于 RoboMaster 团队，代码审查可能需要适应比赛节奏。在紧张的开发期，可能需要简化审查流程；但在重要比赛前，应该加强审查，确保合并的代码是稳定的。可以指定特定的模块维护者负责审查该模块的代码，利用专业知识进行更有效的审查。

==== 持续集成与自动化

持续集成（Continuous Integration，CI）是一种软件工程实践，核心思想是频繁地将代码集成到主线，每次集成都通过自动化构建和测试来验证。这样可以尽早发现问题，避免"集成地狱"——在项目后期才发现各个组件无法一起工作。

现代的 CI 系统（如 GitHub Actions、GitLab CI、Jenkins）可以在每次代码推送时自动执行一系列任务：编译代码、运行单元测试、进行代码风格检查、生成文档、构建 Docker 镜像等。如果任何步骤失败，开发者会立即收到通知，可以及时修复问题。

CI 对代码质量的保障是全方位的。每次提交都经过编译检查，保证代码至少能构建成功。每次提交都运行测试，保证没有引入回归问题。代码风格检查确保团队遵循统一的编码规范。这些检查是自动化的、一致的、不会疲劳的，比人工检查更可靠。

持续部署（Continuous Deployment，CD）更进一步，将通过 CI 验证的代码自动部署到生产环境。对于 RoboMaster 来说，"生产环境"可能是机器人上的软件系统。虽然完全自动化的部署可能不适合比赛场景（你不希望比赛前自动更新代码），但 CI 的理念——频繁集成、自动验证——是完全适用的。

一个典型的 RoboMaster 项目 CI 配置可能包括：在 Ubuntu 环境中编译整个项目；运行所有单元测试；检查代码风格是否符合规范；对于视觉算法，可能还会在测试数据集上运行评估。这些检查在每次 Pull Request 时自动运行，只有通过所有检查的代码才能合并。

设置 CI 需要一些前期投入，但回报是巨大的。它让团队对代码库的健康状况有持续的可见性，问题在引入时就被发现而不是积累到后期。它也解放了人力——不需要手动运行测试、手动检查编译、手动验证风格。机器做它擅长的重复性工作，人专注于创造性的工作。

==== 冲突解决：协作的代价

当多个人同时修改同一个文件的同一部分时，Git 无法自动判断该采用谁的修改，这时就会产生冲突。冲突是分布式协作的必然产物，不是错误，而是需要人类决策的情况。

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

解决冲突需要理解两边的改动意图，然后决定最终应该保留什么。有时候选择一边即可，有时候需要手动融合两边的修改。解决后，删除冲突标记，完成合并提交。

预防胜于解决。几个实践可以减少冲突的频率和复杂度。首先，保持分支短命，频繁合并。分支存在的时间越长，积累的差异越多，冲突的可能性越大。其次，频繁从主线同步更新。定期将主线的新改动合并到你的分支，保持与主线的差距可控。第三，合理划分模块。如果团队成员负责不同的模块，他们修改同一文件的机会就少。第四，避免大规模重构与功能开发同时进行。重构会改动很多文件，与其他人的修改冲突的概率很高。

当冲突确实发生时，保持冷静。大多数冲突是简单的，几分钟就能解决。如果遇到复杂的冲突，找相关的开发者一起解决，确保正确理解双方的意图。解决后仔细测试，确保合并后的代码是正确的。

==== RoboMaster 团队的 Git 实践

最后，让我们讨论一些适合 RoboMaster 团队的 Git 实践。这些建议基于机器人开发的特点和学生团队的现实情况。

仓库组织方面，可以采用单一仓库（monorepo）或多仓库策略。单一仓库把所有代码放在一起，便于跨模块修改和原子性提交，但仓库可能变得庞大。多仓库将不同模块（如视觉、导航、控制）分开，每个仓库独立演化，但跨仓库协调更复杂。RoboMaster 项目的规模通常适合单一仓库，或者核心功能一个仓库、机器人配置一个仓库的简单划分。

分支保护是必要的。`main` 分支应该设置保护规则：禁止直接推送，必须通过 Pull Request 合并；要求至少一人审查通过；要求 CI 检查通过。这些规则确保了主分支的稳定性，防止意外的破坏性提交。

比赛前的版本管理需要特别注意。比赛前一周左右，可以从 `main` 创建一个 `competition` 分支，冻结大的功能开发，只进行 bug 修复和参数调整。比赛时使用这个分支的代码。比赛后，将 `competition` 分支的有价值修改合并回 `main`。

文档和配置也应该纳入版本控制。机器人的参数配置、标定数据、启动脚本都是代码的一部分，应该和代码一起版本化。这样你可以追溯某个配置是什么时候改的，也可以轻松回滚到之前的配置。

培养团队的版本控制文化需要时间。新成员可能不熟悉 Git，需要耐心指导。可以指定经验丰富的成员作为"Git 导师"，帮助新人解决问题。定期进行代码审查，不仅是为了审查代码，也是传播好的版本控制实践。

版本控制是软件工程的基础设施。像电力和自来水一样，当它正常工作时你不会注意到它，但没有它一切都会崩溃。投入时间建立好的版本控制实践，是对团队长期生产力的投资。这些实践会随着团队一起成长，成为团队工程文化的一部分。
