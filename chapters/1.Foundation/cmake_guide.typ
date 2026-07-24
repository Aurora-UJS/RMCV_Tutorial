
=== 为什么需要构建系统
// 引言：从手动编译到自动化构建
// - 一个文件时：g++ main.cpp -o main
// - 十个文件时：命令变得冗长
// - 一百个文件时：手动管理不可能
// - 依赖关系：哪些文件需要重新编译？
// - 跨平台问题：不同系统的编译器和路径
// - 构建系统的职责：依赖分析、增量编译、跨平台抽象
// - Make 的历史地位与局限
// - CMake：C++ 项目中的主流选择
// === 为什么需要构建系统

学习 C++ 的第一天，你可能写下了这样一行命令：`g++ main.cpp -o main`。编译器读取源文件，生成可执行文件，程序运行，输出 "Hello, World!"。一个文件时，这种方式简单直接；当源文件从一个增加到十个、一百个，项目开始依赖外部库，团队成员又使用不同环境时，手动维护编译命令就会越来越困难。构建系统用于管理编译步骤、文件依赖和平台差异，因此也是 C++ 工程开发中的基础工具。

==== 从一个文件到一百个文件

让我们从最简单的情况开始。一个只有 `main.cpp` 的项目，编译命令是：

```bash
g++ main.cpp -o main
```

当你把代码拆分成两个文件——`main.cpp` 和 `utils.cpp`——命令变成：

```bash
g++ main.cpp utils.cpp -o main
```

当 RoboMaster 视觉系统包含检测器、跟踪器、预测器、通信模块和工具函数等几十个源文件后，命令可能变成这样：

```bash
g++ main.cpp detector.cpp tracker.cpp predictor.cpp protocol.cpp serial.cpp \
    config.cpp logger.cpp math_utils.cpp image_utils.cpp coordinate.cpp \
    kalman_filter.cpp armor.cpp rune.cpp ... -o rm_vision \
    -I/usr/include/opencv4 -I/usr/include/eigen3 \
    -lopencv_core -lopencv_imgproc -lopencv_highgui -lceres -lglog \
    -std=c++17 -O2 -Wall
```

这行命令难以阅读和维护。把它保存成 shell 脚本可以避免重复输入，却还没有处理增量构建和头文件依赖。

接着要考虑编译效率。假设项目有 100 个源文件，完整构建需要数分钟；现在只修改 `tracker.cpp` 中的一行，在普通的分离编译模型下，只需重新生成对应目标文件，再重新链接受影响的目标。上面的单条命令会让编译器驱动重新处理列出的全部源文件，无法复用先前目标文件。

要实现“只编译修改过的文件”，你需要分开编译和链接两个步骤。先把每个源文件编译成目标文件（.o），再把目标文件链接成可执行文件：

```bash
g++ -c main.cpp -o main.o
g++ -c detector.cpp -o detector.o
g++ -c tracker.cpp -o tracker.o
# ... 对每个源文件重复 ...
g++ main.o detector.o tracker.o ... -o rm_vision -lopencv_core ...
```

这样，当你修改了 `tracker.cpp`，只需要重新编译 `tracker.o`，然后重新链接。但现在你需要判断哪些文件被修改了、哪些目标文件需要更新。如果 `tracker.cpp` 包含了 `config.h`，而你修改了 `config.h`，那 `tracker.o` 也需要重新编译。如果 `detector.cpp` 和 `predictor.cpp` 也包含了 `config.h`，它们都需要重新编译。

一个头文件可能被许多源文件直接或间接包含，修改后相应编译单元都可能需要重建。手工维护这组关系容易遗漏，构建系统会利用编译器生成的依赖信息自动更新它。

==== 依赖分析与增量编译

构建系统的一项主要职责是依赖分析：源文件包含哪些头文件，目标文件由哪条编译命令生成，可执行文件又依赖哪些目标文件和库。有效的构建关系通常表示为有向无环图（DAG），后端据此安排顺序；不允许的循环依赖应在配置阶段被发现或重新设计。

修改文件后，Make、Ninja 等后端会根据依赖、时间戳以及各自记录的构建命令等信息判断哪些输出需要更新。编译器生成的 depfile 可列出某个编译单元实际包含的头文件。如果 `tracker.o` 重建，而可执行文件依赖它，链接步骤也会重新运行。不同后端的判定细节并不完全相同，不能只概括为比较两个文件时间。

这种只重建受影响部分的方式称为增量构建（incremental build；其中编译步骤常称增量编译）。实际能节省多少时间取决于头文件扇出、链接方式和生成器；修改广泛包含的头文件时，仍可能接近完整重建。

依赖图也用于安排并行任务。互不依赖的编译命令可以同时执行，但加速比例受串行链接、磁盘、内存容量和单个编译单元耗时限制。并行度过高还可能耗尽内存，因此应根据目标机器测量和设置。

==== 跨平台的挑战

单一平台的短脚本可以满足简单项目；团队还可能需要在不同 Linux 版本、macOS、Windows、Jetson 等目标以及 CI 环境中构建。编译器、路径约定、库格式和可用依赖都会变化。

在 Linux 上，C++ 编译器通常是 `g++`，库文件以 `.so` 结尾，头文件可能在 `/usr/include` 或 `/usr/local/include`。在 macOS 上，默认编译器是 `clang++`，动态库以 `.dylib` 结尾，路径规则也不同。在 Windows 上，编译器可能是 MSVC 的 `cl.exe`，库文件是 `.dll` 和 `.lib`，路径使用反斜杠，还有很多 Windows 特有的编译选项。

为每个平台复制一套脚本会形成重复配置，修改后也需要分别验证。条件分支仍无法取代真实平台测试，因为源代码和第三方依赖本身也可能不具备可移植性。

CMake 允许用一套主要配置描述目标、依赖和特性，再由生成器与工具链文件映射到具体平台。配置仍需显式处理平台差异，并在声明支持的环境中验证；“同一份 CMakeLists.txt”本身不能保证跨平台构建成功。

==== Make：直接描述构建规则

Make 诞生于 1976 年，是延续至今的常用构建工具。它通过 `Makefile` 描述目标、依赖和生成命令。

一个简单的 Makefile 看起来像这样：

```makefile
CXX = g++
CXXFLAGS = -std=c++17 -Wall -O2

main: main.o utils.o
	$(CXX) main.o utils.o -o main

main.o: main.cpp utils.h
	$(CXX) $(CXXFLAGS) -c main.cpp -o main.o

utils.o: utils.cpp utils.h
	$(CXX) $(CXXFLAGS) -c utils.cpp -o utils.o

clean:
	rm -f *.o main
```

每条规则包含三部分：目标（target）、依赖（dependencies）和命令（commands）。`main.o: main.cpp utils.h` 表示 `main.o` 依赖于 `main.cpp` 和 `utils.h`，如果这两个文件中的任何一个比 `main.o` 新，就执行下面的命令重新编译。

Make 可以有效完成依赖驱动和增量构建。不过，直接用 Makefile 维护跨平台 C++ 项目时，团队需要自行处理不少工具链与依赖细节。

Make 配方默认使用制表符开头，变量展开、隐式规则和 shell 执行时机也有各自语义。不了解这些规则时，错误信息可能难以对应到原始意图；成熟项目可以通过约定和自动生成依赖文件控制复杂度。

Make 配方通常调用当前环境的 shell 与工具，跨平台差异需要项目自行抽象或通过其他工具生成 Makefile。条件越多，维护成本通常越高。

外部库的发现也需要额外机制，例如 `pkg-config`、项目脚本或用户传入路径；Make 本身不规定 C++ 包发现与导出接口。

大型项目并非不能直接使用 Make，但项目需要自行建立目录组织、自动依赖、平台检测和安装规则。CMake 等更高层工具把这些常见需求放入统一模型，并可继续生成 Makefile 作为后端。

==== CMake：C++ 项目中的主流选择

CMake 在 2000 年前后开始开发，最初服务于跨平台的 Insight Segmentation and Registration Toolkit（ITK）等项目。它提供跨平台的配置、生成、构建和安装接口。

CMake 的配置与生成阶段会为选定生成器产生构建文件，例如 Unix Makefiles、Ninja、Visual Studio 或 Xcode 项目。随后 `cmake --build` 调用相应后端执行命令。默认生成器取决于平台、环境和 CMake 版本，也可以用 `-G` 明确选择。

CMake 使用名为 `CMakeLists.txt` 的文件来描述项目。与 Makefile 相比，CMake 的语法更加直观：

```cmake
cmake_minimum_required(VERSION 3.16)
project(rm_vision)

find_package(OpenCV REQUIRED COMPONENTS core imgproc dnn)
find_package(Eigen3 REQUIRED)

add_executable(rm_vision
    src/main.cpp
    src/detector.cpp
    src/tracker.cpp
)

target_include_directories(rm_vision PRIVATE include)
target_include_directories(rm_vision SYSTEM PRIVATE ${OpenCV_INCLUDE_DIRS})
target_compile_features(rm_vision PRIVATE cxx_std_17)
target_link_libraries(rm_vision PRIVATE ${OpenCV_LIBS} Eigen3::Eigen)
```

这段代码描述项目名称、源文件、C++ 特性、头文件路径和外部依赖。`find_package` 按包提供的 Config 文件或 Find 模块查找依赖，找不到时仍可能需要设置安装前缀或工具链路径。Eigen 提供 `Eigen3::Eigen` 导入目标，其使用要求会随链接关系传播；常见 OpenCV 包则提供 `${OpenCV_INCLUDE_DIRS}` 与 `${OpenCV_LIBS}`，具体接口应以本机安装版本的包配置为准。只有链接带有正确使用要求的导入目标时，头文件路径、定义和其他依赖才会自动传播。

CMake 广泛用于 C++ 生态，OpenCV、Eigen、Ceres、PCL 和 GoogleTest 等项目都提供某种 CMake 集成。ROS 2 的 `ament_cmake` 也在 CMake 之上增加了包索引和惯用接口。掌握 CMake 能覆盖许多常见项目，但 Meson、Bazel、直接 Makefile 和各平台工程文件同样存在，遇到具体仓库仍应先阅读其构建说明。

后文从基本语法开始，依次介绍多文件组织、外部库、安装导出和 ROS 2 包构建。示例侧重目标式 CMake：把头文件路径、编译特性和依赖附着在实际使用它们的目标上，以便构建关系保持清楚。


=== 编译原理回顾
// 理解构建系统在做什么
// - 从源码到可执行文件的四个阶段（呼应前面章节）
// - 编译单元（Translation Unit）的概念
// - 头文件与源文件的角色
// - 目标文件（.o）与符号表
// - 链接：符号解析与重定位
// - 静态库（.a）与共享库（.so）
// - 为什么修改头文件需要重新编译多个源文件
// - 依赖图与增量编译
// === 编译原理回顾

前面的“程序的执行：从源码到运行”已经介绍编译流程。本节从构建系统角度说明各阶段的输入、输出与依赖，后面遇到编译或链接错误时便能判断问题发生在哪一层。

==== 四个阶段的再认识

C++ 工具链通常按预处理、编译、汇编和链接四个概念阶段说明。编译器驱动可能把其中几步合并执行，但这些边界有助于理解中间文件和错误类型。

预处理阶段处理以 `#` 开头的预处理指令。初学时可以把 `#include` 理解为在当前位置展开所指头文件；实际处理还会继续执行头文件中的宏和条件编译指令。`#define` 进行宏替换，`#ifdef` 等指令决定哪些代码被保留。预处理的输入是源文件（.cpp）和它直接、间接包含的头文件（.h/.hpp），输出是展开后的预处理文本。这个结果通常直接交给后续编译阶段，但你可以用 `g++ -E` 把它保存下来观察。

```bash
# 查看预处理结果
g++ -E main.cpp -o main.ii

# main.ii 可能有数万行，包含了所有展开的头文件
wc -l main.ii
# 输出可能是 50000 行甚至更多
```

编译阶段解析预处理后的 C++，完成语法与语义检查，并可执行优化和代码生成。使用 `-S` 时，编译器驱动把结果保存为汇编文件（`.s`）；普通 `-c` 构建通常不会把这一步单独落盘。

```bash
# 查看编译生成的汇编代码
g++ -S main.cpp -o main.s
```

汇编阶段把汇编指令与伪指令编码为目标文件（object file，Linux 上常为 `.o`），并生成符号和重定位信息。许多本地地址已经可以确定，跨编译单元或需要由加载器处理的引用则保留为待解析项。汇编并不总是简单的一一映射，指令选择、伪指令和目标格式都会影响输出。

```bash
# 生成目标文件
g++ -c main.cpp -o main.o
```

链接阶段将多个目标文件和库文件合并成最终的可执行文件或库。链接器的核心工作是符号解析（找到每个符号引用的定义）和重定位（计算并填入最终地址）。链接的输出是可执行文件或库文件。

```bash
# 链接生成可执行文件
g++ main.o utils.o -o main
```

在传统头文件模型中，预处理依赖源文件及其直接、间接包含的头文件，目标文件依赖相应编译命令及这些输入，链接输出又依赖目标文件和库。构建后端据此决定需要重跑哪些命令。

==== 编译单元

翻译单元（translation unit，也常称编译单元）是传统 C++ 编译的基本输入。它可近似理解为一个源文件经过头文件包含、宏展开和条件编译后的结果。C++20 模块引入了其他翻译单元类型，本章先讨论常见的头文件项目。

在普通分离编译中，每个翻译单元独立生成目标文件。当前单元可通过声明检查外部函数的调用，却看不到另一个源文件中的定义；链接时再解析引用。链接时优化（LTO）可以让工具链在后续阶段跨单元分析，但不改变源文件仍需提供正确声明这一要求。分离编译也使多个单元能够并行和增量构建。

```cpp
// math_utils.cpp - 编译单元 1
#include "math_utils.h"

double Add(double a, double b) {
    return a + b;
}

// main.cpp - 编译单元 2
#include "math_utils.h"

int main() {
    double result = Add(1.0, 2.0);  // 调用在另一个编译单元中定义的函数
    return 0;
}
```

当编译 `main.cpp` 时，编译器看到 `Add(1.0, 2.0)` 这个调用。它从 `math_utils.h` 中知道 `Add` 函数的声明（参数类型和返回类型），可以检查调用是否正确，但它不知道 `Add` 函数的实现在哪里。编译器生成的目标文件中，对 `Add` 的调用被标记为“未解析的外部符号”，等待链接器来填入实际地址。

这种独立性解释了几个现象。只修改一个未被其他单元包含的 `.cpp` 时，通常只需重编它并重链接；头文件变化则可能影响所有包含者。具有外部链接的普通非 `inline` 函数若在头文件中定义并被多个翻译单元包含，可能违反单一定义规则（ODR）并产生多重定义；模板、类内定义、`inline` 函数和内部链接对象有不同规则。链接器负责把跨单元引用与定义组合起来。

==== 头文件与源文件的分工

C++ 头文件（`.h`/`.hpp`）通常提供需要被多个翻译单元看到的声明与定义，源文件（`.cpp`）则保存可以单独编译的实现。具体分工还受模板、`inline`、可见性和 ABI 要求影响。

头文件可包含类定义、函数声明、类型别名、枚举、外部常量声明，以及需要在使用点可见的模板和 `inline` 定义。公开头文件应尽量只暴露使用接口所需的依赖；私有头文件则可服务于库内部多个源文件。

```cpp
// robot.h - 头文件
#pragma once

#include <string>

// 类定义（包含成员声明）
class Robot {
public:
    Robot(const std::string& name);
    void Move(double x, double y);
    std::string GetName() const;
    
private:
    std::string name_;
    double x_, y_;
};

// 函数声明
void InitializeSystem();

// 常量声明
extern const double kMaxSpeed;

// 内联函数（可以在头文件中定义）
inline double Square(double x) {
    return x * x;
}
```

源文件通常定义非模板成员函数、普通函数和具有单一定义要求的变量，并包含只在实现中使用的依赖。这样修改实现时，不必让所有使用公开头文件的翻译单元都重编。

```cpp
// robot.cpp - 源文件
#include "robot.h"
#include <iostream>

// 常量定义
const double kMaxSpeed = 10.0;

// 构造函数实现
Robot::Robot(const std::string& name)
    : name_(name), x_(0), y_(0) {}

// 成员函数实现
void Robot::Move(double x, double y) {
    x_ += x;
    y_ += y;
    std::cout << name_ << " moved to (" << x_ << ", " << y_ << ")" << std::endl;
}

std::string Robot::GetName() const {
    return name_;
}

// 普通函数实现
void InitializeSystem() {
    std::cout << "System initialized" << std::endl;
}
```

这种分离使公开接口与部分实现依赖保持边界，也能缩小某些修改的重编范围。使用者仍可能需要 API 文档了解单位、所有权和错误语义；头文件本身并不保证接口易用。头文件改动是否触发所有使用者重编取决于实际依赖图，而把大量实现放入广泛包含的头文件通常会增加解析和实例化成本。

模板在隐式实例化时需要看到完整定义，因此通常定义在头文件或被头文件包含的实现文件中，也可通过显式实例化采用其他组织方式。`inline` 在 C++ 中主要涉及单一定义规则：其定义需在每个使用它的翻译单元中可达，并允许多个相同定义。编译器是否真的把调用展开属于优化决定；即使没有 `inline` 关键字，编译器也可能内联可见函数或借助 LTO 跨单元优化。

```cpp
// 常见的隐式实例化写法：让模板定义在使用处可见
#include <stdexcept>
#include <utility>
#include <vector>

template <typename T>
class Stack {
public:
    void Push(const T& value) {
        data_.push_back(value);
    }
    
    T Pop() {
        if (data_.empty()) {
            throw std::out_of_range("Stack::Pop on empty stack");
        }
        T value = std::move(data_.back());
        data_.pop_back();
        return value;
    }
    
private:
    std::vector<T> data_;
};
```

==== 目标文件与符号表

目标文件是编译的直接产物，理解它的结构有助于理解链接过程和常见的链接错误。

以常见 ELF 目标文件为例，`.text` 通常存放机器指令，`.data` 存放需要占据文件内容的可写静态存储对象，`.bss` 表示零初始化对象所需空间而不逐字节存入文件。符号表描述链接可见及部分本地符号，重定位记录则指出链接时需要修正的位置。实际节名和布局会随平台、编译选项和目标格式变化。

符号（symbol）用于标识函数、具有链接属性的变量及其他链接实体。目标文件可以提供某个符号的定义，也可以保留待其他目标或库解析的未定义引用；文件内部对象还可能使用不导出的本地符号。

```bash
# 查看目标文件的符号表
nm main.o

# 输出示例：
#                  U _Z3Adddd        # U 表示未定义（引用）
# 0000000000000000 T main           # T 表示在代码段定义
#                  U printf          # 引用了 printf
```

符号表中的常见标记：

- `T`：在代码段中定义（函数）
- `D`：在数据段中定义（已初始化的全局变量）
- `B`：在 BSS 段中定义（未初始化的全局变量）
- `U`：未定义（引用了但未定义，需要链接器解析）
- `W`：弱符号（可以被其他定义覆盖）

你可能注意到 `_Z3Adddd` 这类符号名。C++ 支持函数重载，编译器会通过名称修饰（name mangling）把名称、参数类型等信息编码到链接符号中。名称修饰只是 C++ ABI 的一部分；异常、标准库、对象布局和调用约定也要兼容。因此，不同编译器或不兼容选项生成的 C++ 目标文件不能仅凭符号名相似就假定可以混用。

```bash
# 查看解码后的符号名
nm -C main.o

# 输出：
#                  U Add(double, double)
# 0000000000000000 T main
```

==== 链接：符号解析与重定位

链接器的工作是将多个目标文件和库文件合并成一个可执行文件（或库）。这个过程包含两个核心任务：符号解析和重定位。

符号解析（symbol resolution）把引用与可用定义匹配。普通强外部符号找不到定义时通常产生 `undefined reference`，出现不允许的多个强定义时通常产生 `multiple definition`。弱符号、COMDAT、模板和 `inline` 定义还有专门的合并规则，所以“唯一”应结合链接属性和单一定义规则理解。

```bash
# 未定义符号错误
g++ main.o -o main
# error: undefined reference to `Add(double, double)'

# 需要链接包含 Add 定义的目标文件
g++ main.o math_utils.o -o main
```

"undefined reference" 是最常见的链接错误之一。它意味着你使用了某个函数或变量，但链接器在所有提供的目标文件和库中都找不到它的定义。常见原因包括：忘记链接某个库、忘记编译某个源文件、函数声明与定义不匹配（特别是参数类型）、C 和 C++ 混合编程时忘记 `extern "C"`。

`multiple definition` 表示链接器看到了不能同时保留的重复定义。常见原因是在头文件中定义了非 `inline` 的外部函数，或在多个源文件中分别定义同一个外部变量；也可能是同一源文件被重复加入输入。

重定位（relocation）是计算并填入符号最终地址的过程。在编译时，编译器不知道函数和变量的最终地址，只能在调用处留下占位符，并在重定位表中记录这些位置。链接器确定了每个符号的最终地址后，遍历重定位表，把占位符替换为实际地址。

传统 Unix 链接器处理静态归档时，输入顺序可能影响哪些成员被取出：使用某个符号的对象通常放在提供该符号的静态库之前。若 A 依赖 B、B 依赖 C，常见顺序是 `A B C`。共享库、`--as-needed`、循环静态库和不同链接后端还有其他规则；在 CMake 中应通过目标依赖表达关系，让生成器按平台组织命令，而不是手写一串全局 `-l` 参数。

```bash
# 链接顺序可能影响结果
g++ main.o -lmath -lbase    # 如果 math 依赖 base 中的符号，这个顺序是对的
g++ main.o -lbase -lmath    # 可能会出问题
```

==== 静态库与共享库

库可以作为静态归档参与链接，也可以作为共享对象在装载时解析。一个程序还可能同时采用两种方式。

静态库（static library）通常是目标文件的归档集合，Linux 上常用 `.a`，Windows 工具链常用 `.lib`。链接器按符号需求从归档中提取成员，并把相关代码和数据纳入最终链接输出；链接时垃圾回收等选项还可能移除未使用的节。

```bash
# 创建静态库
ar rcs libmath.a add.o subtract.o multiply.o divide.o

# 链接静态库
g++ main.o -L. -lmath -o main
# 或者直接指定库文件
g++ main.o libmath.a -o main
```

静态链接可以减少对所选共享库文件的运行时依赖，并便于把特定库版本固定进产物，但不代表可执行文件完全自包含。它仍受 CPU 架构、操作系统 ABI、动态链接的其他库、数据文件和驱动等条件限制，不能假定复制到任意机器都能运行。纳入的库代码会增加产物体积；库修复后，程序必须重新链接并重新发布，必要时还要重新编译受头文件变化影响的部分。

共享库（shared library，也称动态库）在 Linux 上常为 `.so`，Windows 上运行时文件常为 `.dll` 并可能配套导入 `.lib`。可执行文件记录所需库及符号，由动态加载器在启动或显式加载时映射。多个进程可能共享只读代码页，实际磁盘和内存收益取决于库版本、页面修改和装载方式。

```bash
# 创建共享库
g++ -shared -fPIC -o libmath.so add.cpp subtract.cpp multiply.cpp divide.cpp

# 链接共享库
g++ main.cpp -L. -lmath -o main

# 仅在本次演示命令中把当前构建目录加入查找路径
LD_LIBRARY_PATH="$PWD" ./main
```

`-fPIC` 让编译器生成位置无关代码（Position Independent Code）。许多 64 位 ELF 平台构建共享库时需要或推荐这样做；具体要求由目标架构和工具链决定。CMake 可通过共享库默认属性或 `POSITION_INDEPENDENT_CODE` 管理它，不必把参数写入所有目标。

共享库可由多个程序复用，并允许兼容更新在不重新链接应用的情况下部署。更新若破坏 ABI 或改变行为，也可能让现有程序失败，因此需要 SONAME、包依赖和兼容策略。启动时符号解析、间接调用和位置无关代码可能带来开销，其大小与平台、绑定方式和工作负载有关，应在确有性能要求时测量。

```bash
# 只对可信的可执行文件使用 ldd 查看解析结果
ldd ./main

# 输出示例：
# linux-vdso.so.1
# libmath.so => ./libmath.so
# libstdc++.so.6 => /usr/lib/x86_64-linux-gnu/libstdc++.so.6
# libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6
```

不要对来源不可信的二进制直接运行 `ldd`；需要静态查看动态节时，可使用 `readelf -d ./main` 等工具。生产部署通常通过安装规则、RPATH/RUNPATH 或系统包管理配置库路径，长期设置包含当前目录的 `LD_LIBRARY_PATH` 容易加载到非预期文件。

在 CMake 中，使用 `add_library` 创建库时可以指定类型：

```cmake
# 静态库
add_library(mylib STATIC src1.cpp src2.cpp)

# 共享库
add_library(mylib SHARED src1.cpp src2.cpp)

# 让 CMake 根据 BUILD_SHARED_LIBS 变量决定
add_library(mylib src1.cpp src2.cpp)
```

==== 头文件修改的连锁反应

现在可以解释为什么一次头文件修改会让多个源文件重新编译。

回顾编译单元的概念：每个 .cpp 文件经过预处理后形成一个编译单元，预处理会在各个 `#include` 位置处理相应头文件。因此，同一个头文件可能参与形成多个编译单元。

假设 `config.h` 被 `detector.cpp`、`tracker.cpp` 和 `predictor.cpp` 包含。从依赖关系看：

- `detector.o` 依赖于 `detector.cpp` 和 `config.h`
- `tracker.o` 依赖于 `tracker.cpp` 和 `config.h`
- `predictor.o` 依赖于 `predictor.cpp` 和 `config.h`

当你修改 `config.h` 时，这三个目标文件都变得“过时”了，都需要重新编译。这是正确的行为——头文件中可能定义了类的布局、常量的值、宏的内容，这些都可能影响编译结果。

广泛包含的头文件变化可能触发大量重编。优化之前应先用构建日志或分析工具确认影响，常见的控制方式包括：

前向声明（forward declaration）可以在只保存某类型的指针或引用时减少部分包含依赖，但使用值成员、继承关系或需要完整类型的模板时仍必须包含定义。前向声明还可能隐藏类型来源，并在上游把类改成类型别名时失效，是否采用要同时考虑可读性和编译收益。

```cpp
// 方案一：直接包含，依赖清楚但会引入完整头文件
#include "robot.h"

class Controller {
    Robot* robot_;  // 只用了指针
};

// 方案二：接口只保存非拥有指针时可考虑前向声明
class Robot;  // 前向声明

class Controller {
    Robot* robot_;  // 只用了指针，不需要完整定义
};
```

Pimpl（Pointer to Implementation）把实现对象定义放在源文件中，公开类只保存指向它的指针。这样可减少实现变化造成的重编，并有助于保持二进制接口；代价可能包括一次间接访问、动态分配以及更复杂的复制、析构和所有权代码。是否值得使用应看 ABI 与构建时间需求。

还可以把职责不同的接口拆成较小头文件，避免公共汇总头被无关模块包含。所谓“稳定底层、易变上层”只有在依赖方向确实由上层指向底层时才成立，应以实际 include 图为准。

==== 依赖图与构建优化

构建后端把文件、生成命令和目标之间的依赖组织成图。下图用文件节点简化表示：

```
                    ┌─────────────┐
                    │   main.exe   │
                    └──────┬──────┘
                           │ 链接
           ┌───────────────┼───────────────┐
           ▼               ▼               ▼
      ┌─────────┐    ┌─────────┐    ┌─────────┐
      │ main.o  │    │detector.o│    │tracker.o │
      └────┬────┘    └────┬────┘    └────┬────┘
           │ 编译         │ 编译         │ 编译
           ▼              ▼              ▼
      ┌─────────┐    ┌─────────┐    ┌─────────┐
      │main.cpp │    │detector.│    │tracker. │
      └────┬────┘    │  cpp    │    │  cpp    │
           │         └────┬────┘    └────┬────┘
           │              │              │
           ▼              ▼              ▼
      ┌─────────────────────────────────────┐
      │              config.h               │
      └─────────────────────────────────────┘
```

文件变化后，后端根据图和自身的过期判定标记输出，再按满足依赖的顺序运行生成命令。

图也显示可并行的命令。在上图中，三个目标文件的编译在依赖输入准备好后可以并行；可用内存、磁盘与显式并发池仍会限制实际调度。

```bash
# Make 并行编译
make -j8  # 最多 8 个并行任务

# Ninja 默认会根据本机资源选择并行任务数，也可用 -j 调整
ninja

# CMake 构建时指定并行度
cmake --build . --parallel 8
```

生成器会以各自方式把编译命令和配置文件纳入过期判定。编译选项从 Debug 变为 Release 时应重建相关目标，但直接编写的 Makefile 若没有把选项变化建模为依赖，未必会自动发现。遇到可疑的陈旧结果时，应查看实际命令或使用新的构建目录验证。

ccache 等编译器缓存会根据预处理输入、编译选项、编译器和相关环境生成键；命中时复用先前结果。能否命中及节省多少时间取决于项目和配置。

```bash
# 让 CMake 通过 launcher 调用 ccache
sudo apt install ccache
cmake -S . -B build -DCMAKE_CXX_COMPILER_LAUNCHER=ccache
cmake --build build
```

理解翻译单元、链接和依赖图后，就能区分“某个头文件扇出过大”“链接阶段串行”或“缓存没有命中”等不同问题，再选择相应改进，而不是仅靠提高 `-j` 数值。


=== CMake 基础语法
// CMake 语言入门
// - CMakeLists.txt：项目的构建描述
// - 最小的 CMakeLists.txt
// - cmake_minimum_required：版本要求
// - project：项目名称与语言
// - add_executable：定义可执行文件
// - add_library：定义库（STATIC/SHARED）
// - 变量：set、${VAR}、缓存变量
// - 列表操作：list(APPEND ...)
// - 条件语句：if/elseif/else/endif
// - 循环语句：foreach/while
// - 函数与宏：function/macro
// - 注释：# 单行注释
// - 常用变量：
//   CMAKE_SOURCE_DIR, CMAKE_BINARY_DIR
//   CMAKE_CURRENT_SOURCE_DIR
//   CMAKE_CXX_STANDARD, CMAKE_CXX_FLAGS
//   CMAKE_BUILD_TYPE
// === CMake 基础语法

理解构建步骤后，下面从最小项目开始介绍 CMake 的命令、变量、列表和控制结构。示例先说明语法，随后再把设置逐步转移到具体目标上。

==== CMakeLists.txt：项目的构建描述

CMake 的主要目录配置文件名为 `CMakeLists.txt`。在大小写敏感的文件系统上，`cmakelists.txt` 不会被当作该文件。子目录可以有自己的 `CMakeLists.txt`，但顶层不会自动遍历所有目录；只有通过 `add_subdirectory()` 等命令加入的目录才会参与配置。

`CMakeLists.txt` 是一个文本文件，包含一系列 CMake 命令。命令的基本格式是：

```cmake
command_name(arg1 arg2 arg3 ...)
```

命令名不区分大小写，`add_executable`、`ADD_EXECUTABLE` 和 `Add_Executable` 都是合法的，但惯例是使用小写。参数之间用空格或换行分隔，不需要逗号。如果参数包含空格，需要用双引号括起来。

```cmake
# 这是注释，以 # 开头

# 命令名小写是惯例
add_executable(my_program main.cpp)

# 多个参数可以换行
add_executable(my_program
    main.cpp
    utils.cpp
    helper.cpp
)

# 包含空格的参数需要引号
message("Hello, World!")
set(MY_PATH "/path/with spaces/file.txt")
```

==== 最小的 CMakeLists.txt

假设项目只有 `main.cpp`，顶层 `CMakeLists.txt` 可以从三行开始：

```cmake
cmake_minimum_required(VERSION 3.16)
project(hello)
add_executable(hello main.cpp)
```

这三行分别做了什么？

`cmake_minimum_required` 指定项目支持的最低 CMake 版本，并设置策略版本。它应出现在顶层文件靠前位置、通常在 `project()` 之前；子目录的每个 `CMakeLists.txt` 不需要重复。版本过低时，CMake 会在配置阶段给出明确错误。

`project` 声明项目名称。这个名称会被用于生成的项目文件（如 Visual Studio 解决方案），也可以在配置中通过变量 `PROJECT_NAME` 引用。

`add_executable` 定义一个可执行文件目标，第一个参数是目标名称，后面是组成这个目标的源文件列表。

有了这三行，你就可以构建项目了：

```bash
# 配置项目：-S 指源目录，-B 指构建目录
cmake -S . -B build

# 构建（编译和链接）
cmake --build build

# 运行程序
./build/hello
```

==== cmake_minimum_required：版本要求

`cmake_minimum_required` 还会设置 CMake 策略（policy）的兼容版本。策略用于在行为变化时区分旧项目与新项目，不能简单理解为模拟某个旧版可执行文件的全部行为。

```cmake
cmake_minimum_required(VERSION 3.16)
```

最低版本应由项目实际使用的最早特性、目标平台可提供的 CMake 和持续集成结果共同决定。不要只为扩大版本数字范围而填写一个未测试的旧版本。本章示例采用 3.16；若复制到 ROS 2 或其他项目，应检查对应发行版、依赖包和项目模板的要求。

你也可以指定版本范围：

```cmake
# 至少需要 3.16，并声明项目已按不晚于 3.25 的策略行为更新
cmake_minimum_required(VERSION 3.16...3.25)
```

==== project：项目声明

`project` 命令声明项目的基本信息：

```cmake
project(rm_vision)
```

最简单的形式只需要项目名称。但 `project` 还支持更多参数：

```cmake
project(rm_vision
    VERSION 2.0.0
    DESCRIPTION "RoboMaster 视觉系统"
    LANGUAGES CXX
)
```

`VERSION` 指定项目版本，会设置 `PROJECT_VERSION`、`PROJECT_VERSION_MAJOR`、`PROJECT_VERSION_MINOR`、`PROJECT_VERSION_PATCH` 等变量。

`DESCRIPTION` 提供项目描述，存储在 `PROJECT_DESCRIPTION` 变量中。

`LANGUAGES` 指定项目使用的编程语言。常见值有 `C`、`CXX`（C++）、`Fortran`、`CUDA` 等。如果不指定，默认是 `C` 和 `CXX`。只指定需要的语言可以略微加快配置速度。

```cmake
# 纯 C++ 项目
project(my_project LANGUAGES CXX)

# C 和 C++ 混合项目
project(my_project LANGUAGES C CXX)

# 包含 CUDA 的项目
project(my_project LANGUAGES CXX CUDA)
```

`project` 命令还会设置一些重要的变量：

- `PROJECT_NAME`：项目名称
- `PROJECT_SOURCE_DIR`：项目源代码目录（包含 `project` 命令的 CMakeLists.txt 所在目录）
- `PROJECT_BINARY_DIR`：项目构建目录

`PROJECT_SOURCE_DIR` 和 `PROJECT_BINARY_DIR` 对应最近一次 `project()` 调用；嵌套项目中它们可能与顶层目录不同。`CMAKE_SOURCE_DIR`、`CMAKE_BINARY_DIR` 始终指向当前整棵配置树的顶层，`CMAKE_PROJECT_NAME` 则保存最顶层 `project()` 的名称。编写可被其他项目通过 `add_subdirectory` 引入的库时，应优先使用当前目录或当前项目变量，避免误指宿主顶层。

==== add_executable：定义可执行文件

`add_executable` 是最常用的命令之一，它定义一个可执行文件目标：

```cmake
add_executable(rm_vision
    src/main.cpp
    src/detector.cpp
    src/tracker.cpp
    src/predictor.cpp
)
```

第一个参数是 CMake 目标名称，后面是源文件列表。默认输出文件名通常取自目标名并带平台后缀，也可以通过 `OUTPUT_NAME` 等目标属性修改。

源文件可使用相对于当前源目录的路径，也可使用绝对路径。应避免写死 `/home/alice/...` 这类机器路径；由 `${CMAKE_CURRENT_SOURCE_DIR}` 等变量计算出的绝对路径会随项目位置变化，本身并不破坏可移植性。

```cmake
# 相对当前源目录
add_executable(my_app src/main.cpp)

# 由 CMake 目录变量构造的绝对路径
add_executable(my_app ${CMAKE_CURRENT_SOURCE_DIR}/src/main.cpp)
```

头文件不必作为编译输入逐一列出，编译器会通过 `#include` 依赖文件追踪它们。把头文件加入目标源列表可改善部分 IDE 的项目视图；需要安装和导出公开头文件时，较新 CMake 还可使用 `FILE_SET HEADERS` 明确管理，后文会介绍安装规则。

```cmake
add_executable(rm_vision
    src/main.cpp
    src/detector.cpp
    include/detector.h  # 可选，便于 IDE 显示
    include/config.h
)
```

==== add_library：定义库

`add_library` 用于创建库目标。库可以被其他目标链接使用，是组织代码的重要方式。

```cmake
# 创建静态库
add_library(rm_core STATIC
    src/math_utils.cpp
    src/config.cpp
    src/logger.cpp
)

# 创建共享库
add_library(rm_core SHARED
    src/math_utils.cpp
    src/config.cpp
    src/logger.cpp
)
```

`STATIC` 创建静态库（Linux 上是 `.a` 文件），`SHARED` 创建共享库（Linux 上是 `.so` 文件）。

如果不指定库类型，CMake 会根据 `BUILD_SHARED_LIBS` 变量决定：

```cmake
# 类型由 BUILD_SHARED_LIBS 决定
add_library(rm_core
    src/math_utils.cpp
    src/config.cpp
)
```

若项目有意支持两种库形式，用户可在配置时选择；默认值和两种模式都应由项目测试：

```bash
# 构建共享库到 build-shared
cmake -S . -B build-shared -DBUILD_SHARED_LIBS=ON

# 构建静态库到 build-static
cmake -S . -B build-static -DBUILD_SHARED_LIBS=OFF
```

`INTERFACE` 库不编译源文件，主要封装头文件库或一组使用要求，例如包含路径、编译特性和依赖：

```cmake
# 接口库，只有头文件
add_library(my_header_lib INTERFACE)
target_include_directories(my_header_lib INTERFACE include)
```

`OBJECT` 库编译源文件生成一组目标文件，但不自行归档或链接。多个最终目标需要复用同一批已编译对象时可以使用；通过 `$<TARGET_OBJECTS:...>` 取对象不会自动等同于链接一个普通库，传播使用要求时还要检查目标关系。

```cmake
# 对象库
add_library(my_objects OBJECT src1.cpp src2.cpp)

# 在其他目标中使用
add_executable(app1 main1.cpp $<TARGET_OBJECTS:my_objects>)
add_executable(app2 main2.cpp $<TARGET_OBJECTS:my_objects>)
```

创建了库之后，可以用 `target_link_libraries` 将其链接到其他目标：

```cmake
add_library(rm_core STATIC src/core.cpp)
add_executable(rm_vision src/main.cpp)

# 链接库到可执行文件
target_link_libraries(rm_vision PRIVATE rm_core)
```

==== 变量：set 与 \${VAR}

变量是 CMake 中存储和传递信息的基本方式。使用 `set` 命令定义变量，使用 `${VAR}` 语法引用变量的值：

```cmake
# 定义变量
set(MY_VARIABLE "hello")

# 使用变量
message(STATUS "MY_VARIABLE = ${MY_VARIABLE}")

# 变量可以用在任何需要字符串的地方
set(SRC_DIR "src")
add_executable(app ${SRC_DIR}/main.cpp)
```

变量名区分大小写，`MY_VAR`、`my_var` 和 `My_Var` 是三个不同变量。项目可为配置变量采用大写加下划线，并避免与 CMake 自带的 `CMAKE_` 命名空间冲突；局部辅助变量也常使用小写，关键是作用域清楚。

变量可以包含列表（多个值），值之间用分号分隔：

```cmake
# 定义列表变量
set(SOURCES main.cpp utils.cpp helper.cpp)

# 上面等价于
set(SOURCES "main.cpp;utils.cpp;helper.cpp")

# 使用列表
add_executable(app ${SOURCES})
```

`set` 接收多个值时，变量内部以分号表示列表。未加引号的 `${SOURCES}` 会在命令参数位置展开为多个元素；带分号的原始字符串、空元素和引号会影响结果，处理路径或生成表达式时应注意。

如果变量未定义，`${VAR}` 会展开为空字符串。可以用 `if(DEFINED VAR)` 检查变量是否定义：

```cmake
if(DEFINED MY_VAR)
    message(STATUS "MY_VAR is defined: ${MY_VAR}")
else()
    message(STATUS "MY_VAR is not defined")
endif()
```

CMake 预定义了许多有用的变量：

```cmake
# 源代码目录（顶层 CMakeLists.txt 所在目录）
message(STATUS "Source dir: ${CMAKE_SOURCE_DIR}")

# 构建目录
message(STATUS "Binary dir: ${CMAKE_BINARY_DIR}")

# 当前处理的 CMakeLists.txt 所在目录
message(STATUS "Current source dir: ${CMAKE_CURRENT_SOURCE_DIR}")

# 当前处理的 CMakeLists.txt 对应的构建目录
message(STATUS "Current binary dir: ${CMAKE_CURRENT_BINARY_DIR}")

# C++ 编译器路径
message(STATUS "CXX compiler: ${CMAKE_CXX_COMPILER}")

# 构建类型（Debug/Release/...）
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
```

==== 缓存变量

普通变量属于目录、函数或 `block()` 等作用域：子目录通常继承加入它时可见的目录变量，函数创建自己的作用域，宏则在调用者作用域展开。缓存变量保存在构建目录的 `CMakeCache.txt` 中，可跨多次配置保留，并可由命令行或配置界面设置。普通变量可能遮蔽同名缓存项，因此不应随意复用名称。

使用 `set` 的 `CACHE` 选项定义缓存变量：

```cmake
# 定义缓存变量
set(ENABLE_DEBUG ON CACHE BOOL "Enable debug mode")
set(MAX_THREADS 4 CACHE STRING "Maximum number of threads")
set(MY_DATA_ROOT "/usr/local/share/my_project" CACHE PATH "Runtime data root")
```

缓存变量的类型有：

- `BOOL`：布尔值，ON/OFF
- `STRING`：字符串
- `PATH`：目录路径
- `FILEPATH`：文件路径
- `INTERNAL`：内部使用，不在 GUI 中显示

最后一个参数是描述字符串，会在 `ccmake` 或 `cmake-gui` 中显示。

用户可以在配置时通过 `-D` 选项设置缓存变量：

```bash
cmake -S . -B build -DENABLE_DEBUG=OFF -DMAX_THREADS=8
```

设置后，值保存在当前构建目录的 `CMakeCache.txt` 中。普通 `set(... CACHE ...)` 默认不会覆盖已经存在的同名缓存值，这能保留用户选择；脚本只有在确有理由时才应使用 `FORCE`，并明确它会覆盖用户输入。

`option` 命令是定义布尔缓存变量的快捷方式：

```cmake
# 两种定义布尔缓存项的常见写法；option 更直接
option(ENABLE_TESTS "Build unit tests" ON)
set(ENABLE_TESTS ON CACHE BOOL "Build unit tests")
```

两者在常见新构建目录中效果相近，但现有普通变量、缓存值和相关 policy 可能影响细节。开关类配置通常使用 `option` 更清楚。

==== 列表操作

CMake 的列表是分号分隔的字符串。`list` 命令提供了丰富的列表操作功能：

```cmake
# 创建列表
set(MY_LIST a b c)  # MY_LIST = "a;b;c"

# 追加元素
list(APPEND MY_LIST d e)  # MY_LIST = "a;b;c;d;e"

# 获取长度
list(LENGTH MY_LIST len)  # len = 5

# 获取元素（索引从 0 开始）
list(GET MY_LIST 0 first)   # first = "a"
list(GET MY_LIST -1 last)   # last = "e"（负数从末尾数）

# 查找元素
list(FIND MY_LIST "c" index)  # index = 2，找不到则为 -1

# 插入元素
list(INSERT MY_LIST 1 x)  # MY_LIST = "a;x;b;c;d;e"

# 移除元素
list(REMOVE_ITEM MY_LIST x)  # 按值移除
list(REMOVE_AT MY_LIST 0)    # 移除 a，剩下 b;c;d;e

# 排序
list(SORT MY_LIST)

# 去重
list(REMOVE_DUPLICATES MY_LIST)

# 反转
list(REVERSE MY_LIST)  # MY_LIST = "e;d;c;b"

# 连接成字符串
list(JOIN MY_LIST ", " result)  # result = "e, d, c, b"
```

列表操作在组织源文件时特别有用：

```cmake
# 分别定义各模块的源文件
set(DETECTOR_SOURCES
    src/detector/armor_detector.cpp
    src/detector/rune_detector.cpp
)

set(TRACKER_SOURCES
    src/tracker/armor_tracker.cpp
    src/tracker/kalman_filter.cpp
)

set(COMMON_SOURCES
    src/common/config.cpp
    src/common/logger.cpp
)

# 合并所有源文件
set(ALL_SOURCES)
list(APPEND ALL_SOURCES ${DETECTOR_SOURCES})
list(APPEND ALL_SOURCES ${TRACKER_SOURCES})
list(APPEND ALL_SOURCES ${COMMON_SOURCES})

# 使用合并后的列表
add_library(rm_vision ${ALL_SOURCES})
```

按模块组织变量可以帮助阅读同一目录中的长列表。项目进一步拆成子目录后，更常见的做法是让各目录用 `target_sources()` 或 `add_library()` 管理自己的文件，避免一个顶层变量汇集所有路径。

关于自动收集源文件的 `file(GLOB ...)`，这里需要提醒一下：

```cmake
# 自动收集所有 .cpp 文件
file(GLOB SOURCES "src/*.cpp")
file(GLOB_RECURSE SOURCES "src/*.cpp")  # 递归搜索子目录

add_executable(app ${SOURCES})
```

CMake 文档不建议用普通 `file(GLOB)` 收集源文件，因为新增文件不会改变 `CMakeLists.txt`，构建系统也就没有必然触发重新配置的输入。新文件可能长期不进入目标，删除文件则可能造成陈旧配置或构建错误。显式列出文件会让新增和删除出现在代码审查差异中。

```cmake
# 推荐：手动列出源文件
add_executable(app
    src/main.cpp
    src/utils.cpp
    src/helper.cpp
)
```

如果项目接受这项取舍，可以配合 CMake 3.12 引入的 `CONFIGURE_DEPENDS`，让生成的主构建系统在构建时检查 glob 结果是否变化：

```cmake
file(GLOB SOURCES CONFIGURE_DEPENDS "src/*.cpp")
```

这会增加每次构建的检查工作，而且 CMake 文档提醒它不能保证适用于所有当前和未来生成器。库目标和需要审查文件增删的项目通常仍宜显式列出源文件。

==== 条件语句

CMake 的条件语句使用 `if`/`elseif`/`else`/`endif` 结构，整组条件以一个 `endif()` 结束。

```cmake
if(ENABLE_DEBUG)
    message(STATUS "Debug mode enabled")
    add_compile_definitions(DEBUG_MODE)
elseif(ENABLE_RELEASE)
    message(STATUS "Release mode enabled")
    add_compile_definitions(RELEASE_MODE)
else()
    message(STATUS "Default mode")
endif()
```

条件求值包含历史兼容规则。常见真常量包括 `ON`、`YES`、`TRUE`、`Y` 和非零数字；常见假常量包括 `OFF`、`NO`、`FALSE`、`N`、`IGNORE`、`NOTFOUND`、空值以及以 `-NOTFOUND` 结尾的值。变量解引用和引号还受 policy 影响，处理任意字符串时应使用明确的 `STREQUAL` 等比较，而不是依赖其布尔解释。

变量在条件中可以直接使用名称，不需要 `${}`：

```cmake
set(ENABLE_FEATURE ON)

# 直接传变量名
if(ENABLE_FEATURE)
    message("Feature enabled")
endif()
```

`if(ENABLE_FEATURE)` 会按变量或常量规则求值，未定义时为假。把它写成 `if(${ENABLE_FEATURE})` 会先做文本展开；空值、包含分号的值或恰好与另一个变量同名的值都可能改变参数结构和含义，因此不推荐这种写法。

CMake 提供了丰富的条件操作符：

```cmake
# 逻辑操作符
if(A AND B)           # 与
if(A OR B)            # 或
if(NOT A)             # 非

# 比较操作符（数值）
if(A EQUAL B)         # 等于
if(A LESS B)          # 小于
if(A GREATER B)       # 大于
if(A LESS_EQUAL B)    # 小于等于（CMake 3.7+）
if(A GREATER_EQUAL B) # 大于等于（CMake 3.7+）

# 比较操作符（字符串）
if(A STREQUAL B)      # 字符串相等
if(A STRLESS B)       # 字符串小于（字典序）
if(A STRGREATER B)    # 字符串大于

# 版本比较
if(A VERSION_EQUAL B)
if(A VERSION_LESS B)
if(A VERSION_GREATER B)

# 正则表达式匹配
if(A MATCHES "regex")

# 存在性检查
if(DEFINED VAR)       # 变量是否定义
if(EXISTS path)       # 文件或目录是否存在
if(IS_DIRECTORY path) # 是否是目录
if(IS_ABSOLUTE path)  # 是否是绝对路径

# 目标检查
if(TARGET target_name) # 目标是否存在
```

一个实际的例子，根据操作系统设置不同的编译选项：

```cmake
if(WIN32)
    message(STATUS "Building on Windows")
    target_compile_definitions(my_app PRIVATE PLATFORM_WINDOWS)
elseif(APPLE)
    message(STATUS "Building on macOS")
    target_compile_definitions(my_app PRIVATE PLATFORM_MACOS)
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    message(STATUS "Building on Linux")
    target_compile_definitions(my_app PRIVATE PLATFORM_LINUX)
elseif(UNIX)
    message(STATUS "Building on another Unix-like system")
    target_compile_definitions(my_app PRIVATE PLATFORM_UNIX)
endif()
```

`CMAKE_BUILD_TYPE` 只适用于 Makefiles、Ninja 等单配置生成器，并且可能为空；Visual Studio、Xcode 和 Ninja Multi-Config 在同一构建树中支持多个配置。下面只演示单配置检查，目标编译选项通常更适合使用 `$<CONFIG:Debug>` 等生成表达式：

```cmake
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    message(STATUS "Debug build")
elseif(CMAKE_BUILD_TYPE STREQUAL "Release")
    message(STATUS "Release build")
endif()
```

条件语句在处理可选依赖时也很有用：

```cmake
find_package(OpenCV QUIET)  # QUIET 表示找不到时不报错

if(OpenCV_FOUND)
    message(STATUS "OpenCV found: ${OpenCV_VERSION}")
    target_include_directories(my_app SYSTEM PRIVATE ${OpenCV_INCLUDE_DIRS})
    target_link_libraries(my_app PRIVATE ${OpenCV_LIBS})
    target_compile_definitions(my_app PRIVATE HAS_OPENCV=1)
else()
    message(WARNING "OpenCV not found, some features will be disabled")
endif()
```

==== 循环语句

CMake 提供了 `foreach` 和 `while` 两种循环结构。`foreach` 更常用，适合遍历列表；`while` 适合条件循环。

`foreach` 的基本形式是遍历列表中的每个元素：

```cmake
set(MODULES detector tracker predictor)

foreach(module IN LISTS MODULES)
    message(STATUS "Processing module: ${module}")
    add_subdirectory(${module})
endforeach()
```

遍历范围：

```cmake
# 从 0 到 9
foreach(i RANGE 9)
    message(STATUS "i = ${i}")
endforeach()

# 从 1 到 10
foreach(i RANGE 1 10)
    message(STATUS "i = ${i}")
endforeach()

# 从 0 到 100，步长 10
foreach(i RANGE 0 100 10)
    message(STATUS "i = ${i}")
endforeach()
```

同时遍历多个列表可使用 CMake 3.17 引入的 `ZIP_LISTS`：

```cmake
set(NAMES alice bob charlie)
set(AGES 25 30 35)

foreach(name age IN ZIP_LISTS NAMES AGES)
    message(STATUS "${name} is ${age} years old")
endforeach()
```

遍历列表并获取索引（需要一些技巧）：

```cmake
set(ITEMS a b c d e)
list(LENGTH ITEMS count)
if(count GREATER 0)
    math(EXPR last "${count} - 1")
    foreach(i RANGE ${last})
        list(GET ITEMS ${i} item)
        message(STATUS "Item ${i}: ${item}")
    endforeach()
endif()
```

`while` 循环用于条件循环：

```cmake
set(counter 0)

while(counter LESS 5)
    message(STATUS "Counter: ${counter}")
    math(EXPR counter "${counter} + 1")
endwhile()
```

循环中可以使用 `break()` 和 `continue()`：

```cmake
foreach(i RANGE 10)
    if(i EQUAL 3)
        continue()  # 跳过 3
    endif()
    if(i EQUAL 7)
        break()     # 到 7 时退出循环
    endif()
    message(STATUS "i = ${i}")
endforeach()
# 输出：0, 1, 2, 4, 5, 6
```

一个实际的例子，为每个源文件创建对应的测试：

```cmake
set(TEST_SOURCES
    test_detector.cpp
    test_tracker.cpp
    test_predictor.cpp
)

include(CTest)  # 定义 BUILD_TESTING 并在启用时调用 enable_testing()

if(BUILD_TESTING)
    find_package(GTest REQUIRED)
    foreach(test_src IN LISTS TEST_SOURCES)
        # 从文件名提取测试名（去掉 .cpp 后缀）
        get_filename_component(test_name ${test_src} NAME_WE)

        # 创建测试可执行文件并注册到 CTest
        add_executable(${test_name} ${test_src})
        target_link_libraries(${test_name} PRIVATE rm_core GTest::gtest_main)
        add_test(NAME ${test_name} COMMAND ${test_name})
    endforeach()
endif()
```

实际项目还应保证不同目录的文件名不会生成重复目标。GoogleTest 项目也可使用 `gtest_discover_tests()` 自动发现单个测试用例。

==== 函数与宏

当你发现自己在重复编写类似的 CMake 代码时，可以将其封装成函数或宏。两者语法类似，但作用域行为不同。

函数使用 `function`/`endfunction` 定义：

```cmake
function(print_variables)
    message(STATUS "CMAKE_SOURCE_DIR: ${CMAKE_SOURCE_DIR}")
    message(STATUS "CMAKE_BINARY_DIR: ${CMAKE_BINARY_DIR}")
    message(STATUS "PROJECT_NAME: ${PROJECT_NAME}")
endfunction()

# 调用函数
print_variables()
```

带参数的函数：

```cmake
function(add_my_library lib_name)
    # ARGN 包含除命名参数外的所有参数
    add_library(${lib_name} ${ARGN})
    target_include_directories(${lib_name} PUBLIC include)
    target_compile_features(${lib_name} PUBLIC cxx_std_17)
endfunction()

# 使用
add_my_library(utils src/utils.cpp src/helper.cpp)
```

函数参数通过以下变量访问：

- `ARGC`：参数总数
- `ARGV`：所有参数的列表
- `ARGN`：除命名参数外的剩余参数
- `ARGV0`、`ARGV1`、...：按位置访问参数

函数有自己的作用域，在函数内部定义或修改的变量不会影响外部。如果需要向外部返回值，使用 `PARENT_SCOPE`：

```cmake
function(get_git_version result_var)
    execute_process(
        COMMAND git describe --tags --always
        OUTPUT_VARIABLE git_version
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
        RESULT_VARIABLE git_result
    )
    if(git_result EQUAL 0)
        set(${result_var} "${git_version}" PARENT_SCOPE)
    else()
        set(${result_var} "unknown" PARENT_SCOPE)
    endif()
endfunction()

# 使用
get_git_version(VERSION)
message(STATUS "Git version: ${VERSION}")
```

宏使用 `macro`/`endmacro` 定义，语法与函数几乎相同：

```cmake
macro(print_info msg)
    message(STATUS "[INFO] ${msg}")
endmacro()

print_info("Hello from macro")
```

函数和宏的关键区别在于作用域：

- 函数有自己的作用域，变量修改不影响调用者
- 宏没有自己的变量作用域，参数也按宏展开规则在调用者上下文中替换

```cmake
set(MY_VAR "original")

function(modify_in_function)
    set(MY_VAR "modified in function")
endfunction()

macro(modify_in_macro)
    set(MY_VAR "modified in macro")
endmacro()

modify_in_function()
message(STATUS "After function: ${MY_VAR}")  # original（未改变）

modify_in_macro()
message(STATUS "After macro: ${MY_VAR}")     # modified in macro（改变了）
```

通常优先使用函数，因为作用域和参数行为更容易局部推理。确实需要在调用者作用域定义控制结构或变量时才考虑宏，并为副作用写清约定。

CMake 还提供了 `cmake_parse_arguments` 用于解析复杂的函数参数，支持选项、单值参数和多值参数：

```cmake
function(add_rm_module)
    # 解析参数
    cmake_parse_arguments(
        ARG                           # 前缀
        "SHARED;STATIC"               # 选项（布尔）
        "NAME;OUTPUT_DIR"             # 单值参数
        "SOURCES;DEPENDS"             # 多值参数
        ${ARGN}
    )
    
    if(NOT ARG_NAME)
        message(FATAL_ERROR "add_rm_module requires NAME")
    endif()
    if(ARG_SHARED AND ARG_STATIC)
        message(FATAL_ERROR "choose only one of SHARED or STATIC")
    elseif(ARG_SHARED)
        set(library_type SHARED)
    elseif(ARG_STATIC)
        set(library_type STATIC)
    else()
        set(library_type)
    endif()

    add_library(${ARG_NAME} ${library_type} ${ARG_SOURCES})
    
    if(ARG_DEPENDS)
        target_link_libraries(${ARG_NAME} PRIVATE ${ARG_DEPENDS})
    endif()
    
    if(ARG_OUTPUT_DIR)
        set_target_properties(${ARG_NAME} PROPERTIES
            LIBRARY_OUTPUT_DIRECTORY ${ARG_OUTPUT_DIR}
        )
    endif()
endfunction()

# 使用
add_rm_module(
    NAME detector
    SOURCES src/detector.cpp src/armor.cpp
    DEPENDS rm_image_backend Eigen3::Eigen
    SHARED
)
```

`cmake_parse_arguments` 还会提供 `ARG_UNPARSED_ARGUMENTS` 等变量。用于公共辅助函数时，应检查未知参数和缺少的关键字，避免拼写错误被静默忽略。

==== 注释

CMake 使用 `#` 作为单行注释的开始，从 `#` 到行尾的内容都会被忽略：

```cmake
# 这是一个完整的注释行

set(MY_VAR "value")  # 这是行尾注释

# 多行注释需要每行都加 #
# 这是第一行
# 这是第二行
# 这是第三行
```

CMake 3.0 引入了括号注释，可用于说明多行背景。用它长期“禁用”配置代码会隐藏无人维护的分支，临时代码验证后应删除或交给版本控制保存：

```cmake
#[[
这是一个块注释。
可以跨越多行。
不需要每行都加 #。

适合临时禁用一段代码：
add_executable(old_app old_main.cpp)
]]

# 括号注释也可以嵌套使用 #[=[  ]=]
#[=[
外层注释
#[[内层注释]]
外层继续
]=]
```

良好的注释习惯可以让 CMakeLists.txt 更易维护：

```cmake
#=============================================================================
# RoboMaster Vision System
# CMake 构建配置
#=============================================================================

cmake_minimum_required(VERSION 3.16)
project(rm_vision VERSION 2.0.0)

#-----------------------------------------------------------------------------
# 编译选项
#-----------------------------------------------------------------------------
option(ENABLE_CUDA "Enable CUDA acceleration" OFF)
option(BUILD_TESTS "Build unit tests" ON)

#-----------------------------------------------------------------------------
# 依赖查找
#-----------------------------------------------------------------------------
find_package(OpenCV REQUIRED)
find_package(Eigen3 REQUIRED)

# Ceres 是可选依赖，用于高级优化功能
find_package(Ceres QUIET)

#-----------------------------------------------------------------------------
# 目标定义
#-----------------------------------------------------------------------------
add_library(rm_core
    src/detector.cpp
    src/tracker.cpp
)
```

==== 常用变量

CMake 预定义了大量变量，了解常用的变量可以让你更高效地编写配置。

路径相关变量是最常用的一组：

```cmake
# 顶层 CMakeLists.txt 所在的源代码目录
message(STATUS "CMAKE_SOURCE_DIR: ${CMAKE_SOURCE_DIR}")

# 顶层构建目录
message(STATUS "CMAKE_BINARY_DIR: ${CMAKE_BINARY_DIR}")

# 当前正在处理的 CMakeLists.txt 所在目录
message(STATUS "CMAKE_CURRENT_SOURCE_DIR: ${CMAKE_CURRENT_SOURCE_DIR}")

# 当前 CMakeLists.txt 对应的构建目录
message(STATUS "CMAKE_CURRENT_BINARY_DIR: ${CMAKE_CURRENT_BINARY_DIR}")

# 项目的源代码目录（project() 命令所在目录）
message(STATUS "PROJECT_SOURCE_DIR: ${PROJECT_SOURCE_DIR}")

# 项目的构建目录
message(STATUS "PROJECT_BINARY_DIR: ${PROJECT_BINARY_DIR}")
```

`CMAKE_SOURCE_DIR` 指向本次 CMake 配置树的顶层，`CMAKE_CURRENT_SOURCE_DIR` 随当前目录变化。项目被别人通过 `add_subdirectory()` 引入时，`CMAKE_SOURCE_DIR` 指向宿主；只有子项目自己调用了 `project()`，`PROJECT_SOURCE_DIR` 才会指向该子项目。可复用库通常更适合使用 `CMAKE_CURRENT_SOURCE_DIR`、`PROJECT_IS_TOP_LEVEL` 等上下文明确的变量。

C++ 标准和编译器相关变量：

```cmake
# 设置 C++ 标准版本
set(CMAKE_CXX_STANDARD 17)

# 要求使用指定的标准，而不是降级
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 不使用编译器扩展（更好的可移植性）
set(CMAKE_CXX_EXTENSIONS OFF)

# 编译器标识
message(STATUS "Compiler: ${CMAKE_CXX_COMPILER_ID}")  # GNU, Clang, MSVC 等
message(STATUS "Compiler version: ${CMAKE_CXX_COMPILER_VERSION}")
```

`CMAKE_CXX_FLAGS` 及各配置变体是全局字符串，工具链和用户可能已经在其中提供选项，直接拼接容易影响第三方子项目或重复默认标志。项目自身要求优先附着到目标：

```cmake
# 现代方式：针对特定目标设置
add_executable(my_app main.cpp)
target_compile_features(my_app PRIVATE cxx_std_17)
if(MSVC)
    target_compile_options(my_app PRIVATE /W4)
else()
    target_compile_options(my_app PRIVATE -Wall -Wextra)
endif()
```

构建类型变量：

```cmake
# CMAKE_BUILD_TYPE 控制构建类型
# 常见值：Debug, Release, RelWithDebInfo, MinSizeRel

# 仅为单配置生成器提供项目默认值，不覆盖用户选择
if(NOT CMAKE_CONFIGURATION_TYPES AND NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Debug" CACHE STRING "Build type")
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
        Debug Release RelWithDebInfo MinSizeRel)
endif()

message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
```

构建类型会选择工具链为各配置定义的标志，通常影响优化、调试信息和 `NDEBUG` 等宏，但精确参数并非跨平台固定：

- `Debug`：通常偏向调试能力和较少优化
- `Release`：通常启用较强优化，并可能定义 `NDEBUG`
- `RelWithDebInfo`：通常同时启用优化与调试信息
- `MinSizeRel`：通常偏向减小产物体积

具体标志可查看构建详细命令或工具链变量。多配置生成器在构建时用 `--config Debug` 等参数选择配置，不使用单一 `CMAKE_BUILD_TYPE`。

输出目录变量：

```cmake
# 可执行文件输出目录
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# 静态库输出目录
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# 共享库输出目录
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# 单配置生成器通常会把相应产物放入 build/bin 和 build/lib
```

这些全局输出变量也会影响子目录目标，多配置生成器还可能增加配置子目录。库项目通常让生成器保持默认布局，只有确有运行或打包需求时才设置目标的 `RUNTIME_OUTPUT_DIRECTORY` 等属性。

安装相关变量：

```cmake
# 安装前缀；常见 Linux 默认值为 /usr/local，实际取决于平台和工具链
message(STATUS "Install prefix: ${CMAKE_INSTALL_PREFIX}")

# 可以在配置时修改
# cmake -S . -B build -DCMAKE_INSTALL_PREFIX=/opt/rm_vision

# GNUInstallDirs 提供相对于安装前缀的标准目录变量
include(GNUInstallDirs)
# CMAKE_INSTALL_BINDIR     -> bin
# CMAKE_INSTALL_LIBDIR     -> lib 或 lib64
# CMAKE_INSTALL_INCLUDEDIR -> include
```

平台检测变量：

```cmake
# 操作系统检测
if(WIN32)
    # Windows（包括 64 位）
endif()

if(APPLE)
    # macOS 或 iOS
endif()

if(UNIX AND NOT APPLE)
    # Linux 或其他 Unix
endif()

# 更精确的检测
message(STATUS "System: ${CMAKE_SYSTEM_NAME}")      # Linux, Windows, Darwin
message(STATUS "Processor: ${CMAKE_SYSTEM_PROCESSOR}")  # x86_64, arm 等

# 32 位 vs 64 位
if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    message(STATUS "Target uses 64-bit pointers")
elseif(CMAKE_SIZEOF_VOID_P EQUAL 4)
    message(STATUS "Target uses 32-bit pointers")
else()
    message(STATUS
        "Target pointer size: ${CMAKE_SIZEOF_VOID_P} bytes")
endif()
```

find_package 相关变量：

```cmake
find_package(OpenCV REQUIRED)

# 常见 OpenCV 包配置会设置以下变量；以安装版本为准
# OpenCV_FOUND        - 是否找到
# OpenCV_VERSION      - 版本号
# OpenCV_INCLUDE_DIRS - 头文件目录（旧式）
# OpenCV_LIBS         - 库列表

message(STATUS "OpenCV version: ${OpenCV_VERSION}")
message(STATUS "OpenCV libraries: ${OpenCV_LIBS}")
```

`find_package` 没有规定所有包必须提供同一组变量或统一命名的导入目标，应查阅具体包配置。`message` 可以确认当前观察到的值，若结果异常，还需结合查找模式、缓存、工具链和详细日志继续判断。


=== 构建流程实践
// 从配置到编译的完整流程
// - 外部构建（out-of-source build）
// - mkdir build && cd build && cmake ..
// - cmake --build . 与 make 的关系
// - 生成器：Makefile、Ninja、Visual Studio
// - 构建类型：Debug、Release、RelWithDebInfo
// - -DCMAKE_BUILD_TYPE=Release
// - 并行编译：make -j$(nproc)
// - 清理构建：重新 cmake 或删除 build 目录
// - CMake 缓存：CMakeCache.txt
// - ccmake / cmake-gui：交互式配置
// === 构建流程实践

下面把配置、生成、构建、测试和安装串成完整流程，并说明生成器、构建类型、并行度与缓存分别在何时生效。

==== 外部构建

CMake 支持两种构建方式：源内构建（in-source build）和源外构建（out-of-source build）。源内构建是在源代码目录中直接运行 CMake，生成的文件与源代码混在一起；源外构建是在单独的目录中运行 CMake，保持源代码目录的整洁。

```bash
# 源内构建（不推荐）
cd my_project
cmake .
make

# 源外构建（推荐）
cmake -S my_project -B my_project/build
cmake --build my_project/build
```

源外构建把目标文件、生成文件和缓存集中在指定目录，版本控制差异更清楚。若团队使用 `build-debug`、`out/` 等多个命名，应在 `.gitignore` 中准确列出这些构建目录，而不是忽略可能包含源码的宽泛路径。

不同配置、生成器和工具链可以使用各自构建目录。例如 Debug 与 Release、主机编译与 ARM 交叉编译的缓存不应混用：

```bash
# 多个构建目录
cmake -S . -B build-debug -DCMAKE_BUILD_TYPE=Debug
cmake -S . -B build-release -DCMAKE_BUILD_TYPE=Release
```

需要验证缓存是否影响结果时，可以新建另一个构建目录重新配置。删除旧目录前仍应确认它确实是生成目录且没有手工放入的数据，不能仅凭名称假定删除一定安全。

源外构建是常见项目约定。项目若确实不支持源内构建，可在顶层尽早检查并给出说明：

```cmake
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR)
    message(FATAL_ERROR "In-source builds are not allowed. Please use a separate build directory.")
endif()
```

==== 配置与构建的两个阶段

CMake 工作流可区分配置/生成与构建。前者执行 CMake 语言并生成后端文件，后者运行编译、链接和自定义命令。

配置阶段是运行 `cmake` 命令的过程。CMake 读取 CMakeLists.txt，执行其中的命令，检查系统环境，查找依赖库，最终生成原生构建系统的配置文件（如 Makefile）。配置阶段的输出保存在构建目录中，包括 `CMakeCache.txt`（缓存）和 `CMakeFiles/` 目录（中间文件）。

```bash
# 配置与生成阶段
cmake -S . -B build

# 输出类似：
# -- The CXX compiler identification is GNU 11.4.0
# -- Detecting CXX compiler ABI info
# -- Detecting CXX compiler ABI info - done
# -- Check for working CXX compiler: /usr/bin/c++ - skipped
# -- Detecting CXX compile features
# -- Detecting CXX compile features - done
# -- Found OpenCV: /usr/local (found version "4.5.4")
# -- Configuring done
# -- Generating done
# -- Build files have been written to: /path/to/build
```

构建阶段是实际编译代码的过程。你可以使用生成的原生构建工具（如 `make`），也可以使用 CMake 的统一接口 `cmake --build`：

```bash
# 构建阶段 - 方式一：在 Unix Makefiles 构建目录中使用原生工具
make -C build

# 构建阶段 - 方式二：使用 CMake 统一接口（推荐）
cmake --build build
```

`cmake --build` 的优势是跨平台通用。无论底层使用的是 Make、Ninja 还是 Visual Studio，命令都是相同的。它还支持一些通用选项：

```bash
# 并行构建
cmake --build build --parallel 8
cmake --build build -j 8  # 简写形式

# 只构建特定目标
cmake --build build --target my_app

# 清理构建产物
cmake --build build --target clean

# 显示详细构建命令
cmake --build build --verbose
```

首次创建构建目录时必须配置。普通源文件变化只需构建；CMake 输入变化时，常见生成器会在构建过程中自动重新运行 CMake。更换生成器、编译器或交叉工具链通常应使用新的构建目录，不能依赖一次普通重配置完成切换。

```bash
# 首次构建：配置 + 构建
cmake -S . -B build
cmake --build build

# 修改源代码后：只需构建
cmake --build build

# 修改 CMakeLists.txt 后：需要重新配置
cmake -S . -B build  # 也可以让构建系统按依赖自动重新运行 CMake
cmake --build build
```

==== 生成器

CMake 通过生成器（generator）为具体构建后端产生文件。默认生成器随平台、安装方式和环境变化，不应在脚本中假定 Linux 必然是 Makefiles 或 Windows 必然是某个 Visual Studio 版本。

你可以用 `-G` 选项指定生成器：

```bash
# 查看可用的生成器
cmake --help

# 使用 Ninja 生成器（推荐）
cmake -S . -B build-ninja -G Ninja

# 使用 Unix Makefiles
cmake -S . -B build-make -G "Unix Makefiles"

# 使用 Visual Studio（Windows）
cmake -S . -B build-vs -G "Visual Studio 17 2022"
```

一个现有构建目录的生成器记录在缓存中，不能在同一目录直接改用另一个 `-G`；上面的示例因此使用不同目录。

Ninja 是低开销的构建后端，常与 CMake 配合用于较大的生成图。它在许多项目的增量调度中开销较低，但总构建时间仍可能主要由编译器、链接器和 I/O 决定，应按项目环境选择：

```bash
# 安装 Ninja
sudo apt install ninja-build

# 使用 Ninja 构建
cmake -S . -B build -G Ninja
cmake --build build  # 也可在该目录运行 ninja
```

Ninja 默认采用并行调度策略并减少构建语言本身的工作，但不会保证占满所有 CPU，也不保证比 Make 快固定倍数。内存不足时同样需要降低并行度。

不同生成器生成的文件不同：

```bash
# Unix Makefiles 生成 Makefile
ls build/
# CMakeCache.txt  CMakeFiles/  Makefile  cmake_install.cmake

# Ninja 生成 build.ninja
ls build/
# CMakeCache.txt  CMakeFiles/  build.ninja  cmake_install.cmake
```

`cmake --build` 统一了常用调用形式，生成器差异仍会体现在多配置选择、可用目标、并行策略和详细日志中。

==== 构建类型

常见 CMake 工具链为四种配置名称提供默认标志：

- `Debug`：偏向调试
- `Release`：偏向运行性能
- `RelWithDebInfo`：兼顾优化与调试信息
- `MinSizeRel`：偏向减小产物体积

使用 `-DCMAKE_BUILD_TYPE` 指定构建类型：

```bash
# Debug 构建
cmake -S . -B build-debug -DCMAKE_BUILD_TYPE=Debug

# Release 构建
cmake -S . -B build-release -DCMAKE_BUILD_TYPE=Release
```

某些 CMake GCC/Clang 工具链初始化值常见如下，但发行版、工具链文件和用户缓存都可修改它们：

```
Debug:         -g -O0
Release:       -O3 -DNDEBUG
RelWithDebInfo: -O2 -g -DNDEBUG
MinSizeRel:    -Os -DNDEBUG
```

`-g` 请求生成调试信息；优化即使关闭，机器指令也不保证与源码逐行一一对应。`-O2`、`-O3` 启用不同优化集合，`-DNDEBUG` 会让标准 `assert()` 宏不再执行表达式。不要把必须的输入验证或安全检查只写在 `assert()` 中。

选择构建类型时需要权衡：

```bash
# 日常开发调试用 Debug
cmake -S . -B build-debug -DCMAKE_BUILD_TYPE=Debug

# 性能测试和发布候选可测量 Release
cmake -S . -B build-release -DCMAKE_BUILD_TYPE=Release

# 需要优化与调试信息时可选 RelWithDebInfo
cmake -S . -B build-relwithdebinfo -DCMAKE_BUILD_TYPE=RelWithDebInfo
```

开发时可使用 Debug 辅助观察变量，也应定期运行与部署一致的优化构建，因为未定义行为、时序和性能可能不同。Release 并不自动代表“最佳”或满足实时要求，仍要在目标硬件和输入下测量延迟，并保留与发布二进制匹配的符号或构建信息。

在 CMakeLists.txt 中，可以设置默认构建类型：

```cmake
# 顶层项目可为单配置生成器提供不覆盖用户值的默认配置
if(CMAKE_SOURCE_DIR STREQUAL PROJECT_SOURCE_DIR AND
   NOT CMAKE_CONFIGURATION_TYPES AND
   NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug CACHE STRING "Choose the build type")
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
        "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
endif()
```

注意：构建类型对于单配置生成器（如 Makefile、Ninja）在配置时指定，而对于多配置生成器（如 Visual Studio、Xcode）在构建时指定：

```bash
# 单配置生成器：配置时指定
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build

# 多配置生成器：构建时指定
cmake -S . -B build
cmake --build build --config Release
```

==== 并行编译

互不依赖的编译命令可以并行运行。收益取决于 CPU、内存、磁盘和构建图，下面分别展示常用入口。

对于 Make，使用 `-j` 选项指定并行任务数：

```bash
# 使用 8 个并行任务
make -j8

# 使用 nproc 报告的当前进程可用处理单元数
make -j$(nproc)

# nproc 命令返回 CPU 核心数
```

Ninja 默认选择并行度，也可以显式限制：

```bash
# 使用 Ninja 的默认并行度
ninja

# 限制并行任务数
ninja -j4
```

使用 `cmake --build` 时：

```bash
# 指定并行任务数
cmake --build . --parallel 8
cmake --build . -j 8

# 不指定数字时采用底层构建工具的默认并行度
cmake --build . --parallel
cmake --build . -j
```

合适并行度没有固定公式。大型 C++ 翻译单元可能占用较多内存，在小型设备或虚拟机中，任务过多会触发交换甚至因内存不足失败；应根据峰值内存和构建时间调整：

```bash
# 内存受限时，使用较少的并行任务
cmake --build . -j 2
```

`CMAKE_BUILD_PARALLEL_LEVEL` 是 CMake 构建工具读取的环境变量，不是在 `CMakeLists.txt` 中用 `set()` 配置的项目变量。它适合由开发环境或 CI 按机器设置：

```bash
# 为这次统一构建调用设置并行上限
CMAKE_BUILD_PARALLEL_LEVEL=8 cmake --build build
```

==== 清理构建

更换编译器、生成器或工具链，以及怀疑缓存状态时，可以在新的构建目录中做一次干净配置作为对照。

最安全的诊断方式是先使用一个新目录，不需要立即删除现有产物：

```bash
# 在新的目录中重新配置和构建
cmake -S . -B build-clean
cmake --build build-clean
```

确认新构建可用且旧目录确实只含生成文件后，再按团队的清理方式移除旧目录。源外构建降低误删源码的风险，但目录中仍可能有人手工放入日志、数据或产物，不能宣称递归删除无条件安全。CMake 3.24 及以后还提供 `cmake --fresh -S . -B build`，可重新创建 CMake 缓存与 `CMakeFiles/`，但不会等同于删除目录内所有其他文件。

如果只想清理编译产物而保留 CMake 配置，可以使用 `clean` 目标：

```bash
# 清理编译产物
make clean
# 或
cmake --build . --target clean
# 或（Ninja）
ninja clean
```

`clean` 目标通常删除由主要构建规则登记的编译产物，并保留缓存和生成器文件；自定义命令、下载内容或项目外部产物是否被清理取决于项目规则。

手工只删除 `CMakeCache.txt` 或部分 `CMakeFiles/` 可能留下与新配置不一致的生成文件。优先使用新构建目录或支持版本中的 `--fresh`；这样也便于比较问题是否确实来自缓存。

==== CMake 缓存

CMake 缓存位于构建目录的 `CMakeCache.txt`，保存用户选项、部分工具链检测结果和依赖路径等缓存项。该文件包含绝对路径，不应复制到另一台机器或另一个源码位置，也通常不纳入版本控制。

```bash
# 只查看现有 build 缓存，不重新配置（-N 为 view-only）
cmake -N -L build      # 列出非高级缓存变量
cmake -N -LA build     # 包含高级缓存变量
cmake -N -LAH build    # 同时显示帮助文本
```

缓存项会跨当前构建目录的多次配置保留。项目可以显式重新计算某些检测值，包查找也可能因输入变化而更新，所以不能把所有缓存项概括为“一经设置永不检测”。排查时应先确认值来自命令行、项目默认、工具链还是上次配置。

```bash
# 首次配置，设置选项
cmake -S . -B build -DENABLE_CUDA=ON

# 再次配置，即使不指定，ENABLE_CUDA 仍然是 ON
cmake -S . -B build

# 要修改缓存的值，需要显式指定
cmake -S . -B build -DENABLE_CUDA=OFF
```

如果怀疑某个缓存项，应先查看其当前值。`-U` 可以在重新配置前删除匹配的缓存项；模式应加引号，避免被 shell 展开：

```bash
# 删除特定缓存变量
cmake -S . -B build -U 'ENABLE_CUDA'

# 删除匹配模式的缓存变量
cmake -S . -B build -U 'ENABLE_*'
```

大范围清理仍优先新建构建目录，以保留可比较的旧状态。

缓存变量的类型（BOOL、STRING、PATH 等）会影响 GUI 工具的显示方式。标记为 `INTERNAL` 的缓存变量不会在 GUI 中显示，用于存储 CMake 内部使用的信息。

==== 交互式配置：ccmake 和 cmake-gui

对于有很多配置选项的项目，在命令行上一个个指定 `-D` 选项很不方便。CMake 提供了两个交互式配置工具：`ccmake`（终端界面）和 `cmake-gui`（图形界面）。

`ccmake` 是一个基于 ncurses 的终端界面工具：

```bash
# 安装 ccmake
sudo apt install cmake-curses-gui

# 为指定源目录与构建目录运行 ccmake
ccmake -S . -B build
```

在 ccmake 中：

- 使用方向键上下移动，选择要修改的变量
- 按 Enter 编辑变量值
- 按 `t` 切换显示高级变量
- 按 `c` 配置（configure）
- 按 `g` 生成（generate）并退出
- 按 `q` 退出

`cmake-gui` 提供图形界面：

```bash
# 安装 cmake-gui
sudo apt install cmake-qt-gui

# 打开指定源目录与构建目录
cmake-gui -S . -B build
```

在 cmake-gui 中：

1. 设置源代码目录和构建目录
2. 点击 "Configure" 按钮，选择生成器
3. 修改需要的选项（变量会以红色高亮显示新变化的项）
4. 再次点击 "Configure" 直到没有红色项
5. 点击 "Generate" 生成构建文件

这两个工具适合：

- 初次配置一个陌生的项目，浏览有哪些可用选项
- 需要修改多个选项时，比逐个 `-D` 更方便
- 想要了解某个选项的含义（工具会显示描述信息）

交互界面修改的仍是构建目录缓存。团队需要可重复配置时，应把关键选项写入 CMake Presets、CI 参数或文档，而不是只保存在某位开发者的 GUI 缓存中。

==== 完整的构建示例

让我们用一个完整的例子串联上述内容。假设你克隆了一个 RoboMaster 视觉项目：

```bash
# 克隆项目
git clone https://github.com/example/rm_vision.git
cd rm_vision

# 首次配置：使用 Ninja，Release 模式，启用 CUDA
cmake -S . -B build -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DENABLE_CUDA=ON \
      -DCMAKE_INSTALL_PREFIX=/opt/rm_vision

# 排查包查找时，用相同配置增加 --debug-find；输出通常很多
cmake -S . -B build -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DENABLE_CUDA=ON \
      -DCMAKE_INSTALL_PREFIX=/opt/rm_vision \
      --debug-find

# 构建（并行）
cmake --build build -j

# 运行测试
ctest --test-dir build --output-on-failure

# 安装
sudo cmake --install build
```

日常开发流程：

```bash
# 修改代码后，只需构建
cmake --build build -j

# 如果修改了 CMakeLists.txt，会自动重新配置
cmake --build build -j

# 切换到 Debug 模式调试问题
cmake -S . -B build-debug -G Ninja -DCMAKE_BUILD_TYPE=Debug
cmake --build build-debug -j

# 使用 GDB 调试
gdb ./build-debug/rm_vision
```

遇到问题时的排查：

```bash
# 查看详细的编译命令
cmake --build build --verbose

# 查看缓存变量
cmake -N -LAH build

# 在新目录做一次独立配置，判断旧缓存是否参与问题
cmake -S . -B build-check -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build-check -j
```

这些命令把配置条件、构建目录和生成器写得较清楚。团队还应记录实际支持的 preset、依赖版本、测试范围和安装权限；统一命令可以提高可重复性，但不能单独保证代码质量。


=== 目标与属性
// 现代 CMake 的核心概念
// - 什么是目标（Target）
// - 目标属性（Target Properties）
// - target_include_directories：头文件路径
// - target_compile_definitions：预处理宏
// - target_compile_options：编译选项
// - target_compile_features：C++ 标准特性
// - target_link_libraries：链接库
// - PUBLIC/PRIVATE/INTERFACE 的含义
//   PRIVATE：只影响当前目标
//   PUBLIC：影响当前目标和依赖它的目标
//   INTERFACE：只影响依赖它的目标
// - 传递性依赖：为什么现代 CMake 更简洁
// === 目标与属性

前面已经介绍了 CMake 的基本命令，接下来要把这些命令组织到具体的构建对象上。现代 CMake 通常以“目标”（Target）为中心：将编译选项、头文件搜索路径和链接依赖附加到各自的目标，而不是统一塞进全局变量。这样可以看清每个模块需要什么，也便于 CMake 把公开的使用要求传给下游目标。

==== 什么是目标

在 CMake 中，目标是构建系统要生成的东西。最常见的目标类型是可执行文件和库：

```cmake
# 创建可执行文件目标
add_executable(rm_vision src/main.cpp)

# 创建库目标
add_library(rm_core src/core.cpp)
```

执行这些命令后，`rm_vision` 和 `rm_core` 就成为 CMake 中可引用的目标。每个目标都有自己的源文件、属性和使用要求；后续的 `target_*` 命令都通过目标名修改这些信息。

目标的类型包括：

- *可执行文件*：`add_executable` 创建，最终生成可运行的程序
- *静态库*：`add_library(name STATIC ...)` 创建，生成 `.a` 文件
- *共享库*：`add_library(name SHARED ...)` 创建，生成 `.so` 文件
- *接口库*：`add_library(name INTERFACE)` 创建，不生成实际文件，只用于传递属性
- *对象库*：`add_library(name OBJECT ...)` 创建，生成目标文件但不打包
- *导入目标*：表示项目外部已有的可执行文件或库，通常由包配置文件创建，也可以用带 `IMPORTED` 的命令显式声明

还有一种常见形式是用 `add_custom_target` 创建自定义目标。它本身没有像可执行文件或库那样的主输出文件，常用于把生成文档、运行检查等命令接入构建入口：

```cmake
# 自定义目标，用于生成文档
add_custom_target(docs
    COMMAND doxygen ${CMAKE_SOURCE_DIR}/Doxyfile
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Generating documentation..."
)
```

目标之间可以建立依赖关系。例如，目标 A 链接项目内的目标 B 时，CMake 会为二者建立必要的构建顺序；B 通过 `PUBLIC` 或 `INTERFACE` 声明的“使用要求”还可能传给 A。需要注意，传递的是特定的接口属性，并不是 B 的所有属性都会自动复制给 A。

==== 目标属性

每个目标都有一组属性（properties），用于描述它的构建方式和对使用者的要求。常见属性包括：

- `INCLUDE_DIRECTORIES`：头文件搜索路径
- `COMPILE_DEFINITIONS`：预处理器宏定义
- `COMPILE_OPTIONS`：编译器选项
- `COMPILE_FEATURES`：需要的 C++ 特性
- `LINK_LIBRARIES`：链接的库
- `CXX_STANDARD`：C++ 标准版本
- `OUTPUT_NAME`：输出文件名
- `POSITION_INDEPENDENT_CODE`：是否生成位置无关代码

可以用 `set_target_properties` 直接设置属性：

```cmake
add_executable(my_app main.cpp)

set_target_properties(my_app PROPERTIES
    CXX_STANDARD 17
    CXX_STANDARD_REQUIRED ON
    OUTPUT_NAME "my_application"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
)
```

也可以用 `get_target_property` 获取属性值：

```cmake
get_target_property(std_version my_app CXX_STANDARD)
message(STATUS "C++ standard: ${std_version}")
```

直接读写属性适合处理没有专用命令的配置。对于头文件路径、宏定义、编译选项和链接依赖，通常优先使用 `target_*` 系列命令：它们能同时区分“构建当前目标需要的内容”和“使用当前目标需要的内容”。后文会结合 `PUBLIC`、`PRIVATE` 和 `INTERFACE` 说明这种区别。

==== target_include_directories：头文件路径

`target_include_directories` 为目标添加头文件搜索路径，相当于编译器的 `-I` 选项：

```cmake
add_library(rm_core src/core.cpp)

target_include_directories(rm_core PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)
```

这里的 `PUBLIC` 同时完成两件事：编译 `rm_core` 时在 `include` 目录中搜索头文件；其他目标链接 `rm_core` 后，也获得相应的头文件搜索路径。

可以指定多个路径：

```cmake
target_include_directories(rm_core PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/third_party/json/include
)
```

普通参数可以写绝对路径或相对路径；相对路径会以当前源码目录为基准处理。显式使用 `CMAKE_CURRENT_SOURCE_DIR` 能让路径的基准更直观，也不会受到构建目录位置的影响。

对于需要区分构建时和安装后路径的情况，可以使用生成器表达式：

```cmake
target_include_directories(rm_core PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)
```

这表示：在当前项目的构建树中使用源码目录下的 `include`；目标安装并被其他项目导入后，则使用相对于安装前缀的 `include`。这样导出的包不会把开发机器上的源码绝对路径写进安装接口。安装与导出一节还会完整介绍这两个表达式。

==== target_compile_definitions：预处理宏

`target_compile_definitions` 为目标添加预处理器宏定义，相当于编译器的 `-D` 选项：

```cmake
add_executable(rm_vision src/main.cpp)

# 定义宏
target_compile_definitions(rm_vision PRIVATE
    DEBUG_MODE
    MAX_THREADS=8
    PROJECT_VERSION="${PROJECT_VERSION}"
)
```

上面的代码相当于在编译时添加 `-DDEBUG_MODE -DMAX_THREADS=8 -DPROJECT_VERSION="1.0.0"`。

在代码中可以使用这些宏：

```cpp
#ifdef DEBUG_MODE
    std::cout << "Debug mode enabled" << std::endl;
#endif

for (int i = 0; i < MAX_THREADS; ++i) {
    // ...
}

std::cout << "Version: " << PROJECT_VERSION << std::endl;
```

条件编译是宏定义的常见用途：

```cmake
option(ENABLE_CUDA "Enable CUDA support" OFF)

add_library(rm_core src/core.cpp)

if(ENABLE_CUDA)
    target_compile_definitions(rm_core PUBLIC WITH_CUDA)
endif()
```

代码中：

```cpp
void process(const Image& image) {
#ifdef WITH_CUDA
    cuda_process(image);  // 使用 CUDA 加速
#else
    cpu_process(image);   // CPU 回退
#endif
}
```

`target_compile_definitions` 接收的是宏定义，而不是一段手写的编译器命令。因此通常省略 `-D` 前缀；若 C++ 代码需要一个字符串字面量，则必须让引号成为宏值的一部分：

```cmake
# 正确
target_compile_definitions(app PRIVATE MY_MACRO=42)

# 不推荐：不同 CMake 版本对前导 -D 的兼容处理并不完全相同
target_compile_definitions(app PRIVATE -DMY_MACRO=42)

# 把引号写进宏值，使 C++ 端得到字符串字面量
target_compile_definitions(app PRIVATE MY_STRING="hello")
```

==== target_compile_options：编译选项

`target_compile_options` 为目标添加编译器选项：

```cmake
add_executable(rm_vision src/main.cpp)

target_compile_options(rm_vision PRIVATE
    -Wall           # 开启常见警告
    -Wextra         # 开启额外警告
    -Wpedantic      # 严格标准检查
    -Werror         # 将警告视为错误；是否启用取决于项目策略
)
```

这些选项属于 GCC 和 Clang，不能原样用于所有编译器。可以使用条件判断或生成器表达式分别配置：

```cmake
# 方式一：条件判断
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    target_compile_options(rm_vision PRIVATE -Wall -Wextra)
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    target_compile_options(rm_vision PRIVATE /W4)
endif()

# 方式二：生成器表达式
target_compile_options(rm_vision PRIVATE
    $<$<CXX_COMPILER_ID:GNU,Clang>:-Wall>
    $<$<CXX_COMPILER_ID:GNU,Clang>:-Wextra>
    $<$<CXX_COMPILER_ID:MSVC>:/W4>
)
```

生成器表达式 `$<condition:value>` 会在生成构建系统时按具体配置求值：条件成立时产生 `value`，否则产生空值。这里把两个警告选项写成两个表达式，避免将 `-Wall -Wextra` 误当成一个带空格的参数。

常见的编译选项包括：

```cmake
target_compile_options(my_target PRIVATE
    # 警告控制
    -Wall -Wextra -Wpedantic
    
    # 优化（通常由 CMAKE_BUILD_TYPE 控制，这里仅作演示）
    $<$<CONFIG:Release>:-O3>
    $<$<CONFIG:Debug>:-O0>
    $<$<CONFIG:Debug>:-g>
    
    # 特定架构优化；只适合明确在构建机本机运行的产物
    -march=native
    
    # 安全性
    -fstack-protector-strong
    
    # 调试信息
    $<$<CONFIG:Debug>:-fsanitize=address,undefined>
)

# 如果使用 sanitizer，链接时也需要添加
target_link_options(my_target PRIVATE
    $<$<CONFIG:Debug>:-fsanitize=address,undefined>
)
```

上例主要演示选项如何附加到目标，并不是一套可以跨工具链照搬的默认配置。优化级别、Sanitizer 和安全加固选项都要先确认编译器与链接器支持；只有在构建机就是目标运行机、且生成物不会分发到其他机器时，才适合考虑 `-march=native`。Sanitizer 既需要编译选项也需要链接选项，否则可能在链接阶段找不到运行库符号。

==== target_compile_features：C++ 标准特性

`target_compile_features` 声明目标需要的 C++ 特性，CMake 会自动选择合适的编译器选项来启用这些特性：

```cmake
add_library(rm_core src/core.cpp)

# 要求 C++17 标准
target_compile_features(rm_core PUBLIC cxx_std_17)
```

`cxx_std_17` 是一个元特性，表示目标至少需要 C++17 模式。类似的还有 `cxx_std_11`、`cxx_std_14`、`cxx_std_20`、`cxx_std_23` 等；较新的元特性是否可用，还取决于项目声明的 CMake 最低版本和实际编译器。

你也可以指定具体的特性：

```cmake
target_compile_features(rm_core PUBLIC
    cxx_auto_type           # auto 关键字
    cxx_range_for           # 范围 for 循环
    cxx_nullptr             # nullptr
    cxx_lambdas             # lambda 表达式
    cxx_variadic_templates  # 变参模板
)
```

但通常直接使用 `cxx_std_XX` 更简单，不需要逐一列出特性。

与直接设置全局的 `CMAKE_CXX_STANDARD` 相比，`target_compile_features` 更适合表达单个目标的要求：

1. 它是目标级别的，不是全局的
2. 它支持 PUBLIC/PRIVATE/INTERFACE，可以传递给依赖者
3. CMake 会根据已知的编译器特性选择标准选项，并在无法满足要求时报告配置错误

```cmake
# 旧方式：全局设置
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 新方式：目标级别设置（推荐）
add_library(rm_core src/core.cpp)
target_compile_features(rm_core PUBLIC cxx_std_17)
```

可见性要由代码接口决定。如果 `rm_core` 的公共头文件使用了 C++17 语法，应写 `PUBLIC`，使编译这些头文件的下游目标也采用相应标准；如果只有 `.cpp` 实现需要 C++17，则应写 `PRIVATE`，避免无意抬高使用者的编译要求。

==== target_link_libraries：链接库

`target_link_libraries` 声明目标的链接实现和链接接口：

```cmake
add_library(rm_core src/core.cpp)
add_executable(rm_vision src/main.cpp)

# rm_vision 链接 rm_core
target_link_libraries(rm_vision PRIVATE rm_core)
```

这里引用的是同一项目中的 CMake 目标，因此 CMake 可以同时处理两类信息：

1. 为 `rm_vision` 的最终链接加入 `rm_core` 所需的库文件和构建顺序
2. 根据可见性（`PUBLIC`、`PRIVATE` 或 `INTERFACE`），处理 `rm_core` 的接口使用要求

可以链接多个库：

```cmake
target_link_libraries(rm_vision PRIVATE
    rm_core
    rm_detector
    rm_tracker
)
```

链接外部库也使用同样的命令：

```cmake
find_package(OpenCV REQUIRED)
find_package(Eigen3 REQUIRED)

add_executable(rm_vision src/main.cpp)

# Eigen3 的包配置通常提供 Eigen3::Eigen 导入目标
target_link_libraries(rm_vision PRIVATE Eigen3::Eigen)

# 常见 OpenCV 包提供变量；也有安装包提供 opencv_core 等具体目标
target_link_libraries(rm_vision PRIVATE
    ${OpenCV_LIBS}
)
target_include_directories(rm_vision PRIVATE
    ${OpenCV_INCLUDE_DIRS}
)
```

如果依赖包提供导入目标，优先使用它，因为目标可以携带头文件路径、编译定义和传递依赖等使用要求。但导入目标的名字由该包决定，不能根据包名自行拼接。例如 `Eigen3::Eigen` 很常见，而许多 OpenCV 安装并不提供 `OpenCV::OpenCV`。应查看对应版本的包文档，或检查 `find_package` 后实际存在的目标和变量。

链接系统库：

```cmake
# 链接 pthread
find_package(Threads REQUIRED)
target_link_libraries(my_app PRIVATE Threads::Threads)

# 某些 Unix 工具链需要显式链接数学库
target_link_libraries(my_app PRIVATE m)

# CMake 用 CMAKE_DL_LIBS 表示当前平台的动态加载库；不需要时可能为空
target_link_libraries(my_app PRIVATE ${CMAKE_DL_LIBS})
```

`m` 不是跨平台目标；C++ 工具链是否需要它也与平台有关。跨平台项目应先用针对该平台的检查确认需求，不要把 Unix 库名无条件写进所有工具链的配置。

==== PUBLIC、PRIVATE 和 INTERFACE

`PUBLIC`、`PRIVATE` 和 `INTERFACE` 用来回答两个问题：当前目标构建时是否需要这项内容？使用当前目标的下游目标是否也需要它？它们可以用于头文件路径、编译定义、编译特性和链接依赖，但具体传递的是相应命令维护的“使用要求”。

让我们用一个具体的例子来解释。假设有三个目标：

- `json_parser`：一个 JSON 解析库
- `config_loader`：使用 `json_parser` 的配置加载库
- `app`：使用 `config_loader` 的应用程序

```cmake
add_library(json_parser src/json_parser.cpp)
add_library(config_loader src/config_loader.cpp)
add_executable(app src/main.cpp)

target_link_libraries(config_loader ??? json_parser)
target_link_libraries(app PRIVATE config_loader)
```

问题是：`config_loader` 链接 `json_parser` 时，应该用 PRIVATE、PUBLIC 还是 INTERFACE？

*PRIVATE* 表示：当前目标自身需要这项内容，但不把它作为接口使用要求提供给下游目标。

如果 `config_loader` 的头文件中没有使用 `json_parser` 的任何类型，只在 `.cpp` 文件中使用：

```cpp
// config_loader.h - 头文件中不暴露 json_parser
#pragma once
#include <string>
#include <map>

class ConfigLoader {
public:
    std::map<std::string, std::string> Load(const std::string& path);
};

// config_loader.cpp - 实现中使用 json_parser
#include "config_loader.h"
#include <json_parser/json.h>  // 只在实现中使用

std::map<std::string, std::string> ConfigLoader::Load(const std::string& path) {
    JsonDocument doc = JsonParser::Parse(path);
    // ...
}
```

这种情况下应该用 `PRIVATE`：

```cmake
target_link_libraries(config_loader PRIVATE json_parser)
```

此时，编译 `app` 时不会因为 `config_loader` 而获得 `json_parser` 的头文件路径或编译定义。不过，不能把 `PRIVATE` 简单理解成“最终链接命令里一定没有 `json_parser`”：如果 `config_loader` 是静态库，它的目标文件仍可能有待解析的 `json_parser` 符号，CMake 会按链接实现的需要把相应库放入最终链接过程。`PRIVATE` 控制的是公开接口，不会改变链接器必须解析符号这一事实。

*PUBLIC* 表示：当前目标自身需要这项内容，下游目标在使用其接口时也需要。

如果 `config_loader` 的头文件中使用了 `json_parser` 的类型：

```cpp
// config_loader.h - 头文件中暴露了 json_parser 的类型
#pragma once
#include <json_parser/json.h>  // 头文件中包含

class ConfigLoader {
public:
    JsonDocument LoadRaw(const std::string& path);  // 返回 json_parser 的类型
};
```

这种情况下应该用 `PUBLIC`：

```cmake
target_link_libraries(config_loader PUBLIC json_parser)
```

`app` 链接 `config_loader` 后，会获得 `json_parser` 声明的接口使用要求。这里最直接的需求是：`app` 编译包含 `config_loader.h` 的代码时，必须能找到 `json_parser/json.h`，并采用该库要求的编译定义或语言特性。最终链接时是否需要库文件，则取决于接口中涉及的符号和库的类型。

*INTERFACE* 表示：当前目标自身不使用这项内容，只要求下游目标使用。

这听起来有点奇怪，什么时候会用到？最常见的场景是 header-only 库：

```cmake
# header-only 库，没有源文件需要编译
add_library(my_header_lib INTERFACE)

target_include_directories(my_header_lib INTERFACE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_compile_features(my_header_lib INTERFACE cxx_std_17)
```

因为 `my_header_lib` 没有要单独编译的源文件，这些要求只对包含其头文件的下游目标有意义。

`INTERFACE` 也可用于只负责组合依赖的“聚合目标”。例如，把项目约定的一组警告选项集中为一个接口目标：

```cmake
add_library(project_warnings INTERFACE)

target_compile_options(project_warnings INTERFACE
    $<$<CXX_COMPILER_ID:GNU,Clang>:-Wall>
    $<$<CXX_COMPILER_ID:GNU,Clang>:-Wextra>
    $<$<CXX_COMPILER_ID:MSVC>:/W4>
)

target_link_libraries(rm_core PRIVATE project_warnings)
```

`project_warnings` 本身不编译代码；`rm_core` 链接它以后获得这些编译选项。这里使用 `PRIVATE`，避免项目内部的警告策略随着 `rm_core` 一起传给外部使用者。

让我们用表格总结：

```
                  │ 当前目标使用 │ 传给下游目标
─────────────────┼─────────────┼─────────────
    PRIVATE      │     ✓       │      ✗
    PUBLIC       │     ✓       │      ✓
    INTERFACE    │     ✗       │      ✓
```

选择时可以直接检查代码边界：只在 `.cpp` 实现中使用，通常是 `PRIVATE`；公共头文件或其他公开接口也要求下游看到，通常是 `PUBLIC`；当前目标没有实现代码，或只负责把一组要求交给使用者，使用 `INTERFACE`。这是一条判断方法，不是按库名套用的固定规则；同一个第三方库在不同目标中可能具有不同可见性。

==== 传递性依赖

以目标为中心的配置可以沿依赖关系传递“使用要求”。当一个目标链接另一个 CMake 目标时，它会获得后者通过 `PUBLIC` 和 `INTERFACE` 暴露的头文件路径、编译定义、编译特性和链接接口等内容。`PRIVATE` 内容以及与接口无关的普通属性不会因此全部传递。

考虑这个例子：

```cmake
# 底层库
add_library(math_utils src/math.cpp)
target_include_directories(math_utils PUBLIC include)
target_compile_features(math_utils PUBLIC cxx_std_17)

# 中层库，依赖 math_utils
add_library(geometry src/geometry.cpp)
target_link_libraries(geometry PUBLIC math_utils)
target_include_directories(geometry PUBLIC include)

# 上层库，依赖 geometry
add_library(renderer src/renderer.cpp)
target_link_libraries(renderer PUBLIC geometry)
target_include_directories(renderer PUBLIC include)

# 应用程序，只需要链接 renderer
add_executable(app src/main.cpp)
target_link_libraries(app PRIVATE renderer)
```

虽然 `app` 只显式声明对 `renderer` 的直接依赖，但按照上面的 `PUBLIC` 关系，它会获得：

- `renderer`、`geometry`、`math_utils` 的头文件路径
- `renderer`、`geometry`、`math_utils` 的链接
- C++17 标准要求（来自 `math_utils`）

这使 `app` 不必重复记录每一层间接依赖。前提是各个库准确声明自己的直接依赖和公共接口；如果可见性写错，传递结果也会不完整或范围过大。

对比旧式的 CMake 写法：

```cmake
# 手动展开整个依赖链：信息重复，依赖变化时容易漏改
add_executable(app src/main.cpp)

target_include_directories(app PRIVATE
    ${CMAKE_SOURCE_DIR}/math_utils/include
    ${CMAKE_SOURCE_DIR}/geometry/include
    ${CMAKE_SOURCE_DIR}/renderer/include
)

target_link_libraries(app PRIVATE
    math_utils
    geometry
    renderer
)

set_target_properties(app PROPERTIES CXX_STANDARD 17)
```

手动展开依赖链会让上层目标知道过多实现细节，依赖变化时还要同步修改多处。目标式写法仍然需要每个模块声明准确的直接依赖，但间接的接口要求可以由 CMake 逐层传播。

==== 实际项目中的应用

让我们看一个 RoboMaster 项目的完整示例：

```cmake
cmake_minimum_required(VERSION 3.16)
project(rm_vision VERSION 2.0.0 LANGUAGES CXX)

# 查找依赖
find_package(OpenCV REQUIRED)
find_package(Eigen3 REQUIRED)
find_package(Ceres REQUIRED)

# 常见 OpenCV 包通过变量提供使用信息。用项目内接口目标封装后，
# 其余模块仍可统一采用目标式写法。
add_library(rm_opencv INTERFACE)
target_include_directories(rm_opencv SYSTEM INTERFACE
    ${OpenCV_INCLUDE_DIRS}
)
target_link_libraries(rm_opencv INTERFACE
    ${OpenCV_LIBS}
)

#=============================================================================
# 核心库：公共工具和类型定义
#=============================================================================
add_library(rm_common
    src/common/config.cpp
    src/common/logger.cpp
    src/common/timer.cpp
)

target_include_directories(rm_common PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

target_compile_features(rm_common PUBLIC cxx_std_17)

target_link_libraries(rm_common PUBLIC
    Eigen3::Eigen  # PUBLIC: 头文件暴露 Eigen 类型
)

#=============================================================================
# 检测模块
#=============================================================================
add_library(rm_detector
    src/detector/armor_detector.cpp
    src/detector/rune_detector.cpp
    src/detector/nn_detector.cpp
)

target_include_directories(rm_detector PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

target_link_libraries(rm_detector
    PUBLIC rm_common        # PUBLIC: 接口暴露 rm_common 的类型
    PRIVATE rm_opencv       # PRIVATE: 只在实现中使用 OpenCV
)

#=============================================================================
# 跟踪模块
#=============================================================================
add_library(rm_tracker
    src/tracker/armor_tracker.cpp
    src/tracker/kalman_filter.cpp
    src/tracker/extended_kalman.cpp
)

target_include_directories(rm_tracker PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

target_link_libraries(rm_tracker
    PUBLIC rm_common
    PUBLIC Eigen3::Eigen    # PUBLIC: 滤波器接口暴露 Eigen
    PRIVATE Ceres::ceres    # PRIVATE: 只在优化实现中使用
)

#=============================================================================
# 预测模块
#=============================================================================
add_library(rm_predictor
    src/predictor/motion_predictor.cpp
    src/predictor/ballistic_solver.cpp
)

target_include_directories(rm_predictor PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

target_link_libraries(rm_predictor
    PUBLIC rm_common
    PUBLIC rm_tracker  # PUBLIC: 预测器接口使用跟踪器的类型
)

#=============================================================================
# 主程序
#=============================================================================
add_executable(rm_vision src/main.cpp)

# 只需要链接直接依赖，其他自动传递
target_link_libraries(rm_vision PRIVATE
    rm_detector
    rm_predictor
    rm_opencv  # 主程序也需要 OpenCV 进行图像采集
)
```

在这个例子中：

- `rm_common` 是基础模块，暴露 Eigen 类型，所以 `Eigen3::Eigen` 是 PUBLIC
- `rm_opencv` 把当前 OpenCV 安装提供的变量封装为项目内接口目标；若所用安装包提供可靠的具体导入目标，也可以直接使用那些目标
- `rm_detector` 内部使用 OpenCV 处理图像，但接口不暴露 OpenCV 类型，所以是 PRIVATE
- `rm_tracker` 的接口返回 Eigen 矩阵表示的状态，所以 `Eigen3::Eigen` 是 PUBLIC
- `rm_predictor` 依赖 `rm_tracker`，接口使用跟踪器的类型，所以是 PUBLIC
- `rm_vision` 主程序是最终产物，不会被其他目标依赖，所以全部是 PRIVATE

这样组织后，大多数实现依赖的变化只需在所属模块的 `CMakeLists.txt` 中调整；只有公共接口或其使用要求发生变化时，下游代码和配置才可能需要跟着修改。目标式写法减少了重复配置，但仍要通过实际头文件边界、链接结果和导出场景检查可见性是否正确。

==== 诊断依赖关系

当依赖关系变得复杂时，可以先查看目标直接记录的属性：

```cmake
# 查看目标的属性
get_target_property(includes rm_vision INCLUDE_DIRECTORIES)
message(STATUS "rm_vision includes: ${includes}")

get_target_property(libs rm_vision LINK_LIBRARIES)
message(STATUS "rm_vision links: ${libs}")

get_target_property(interface_libs rm_core INTERFACE_LINK_LIBRARIES)
message(STATUS "rm_core link interface: ${interface_libs}")
```

这些值可能包含生成器表达式，而且 `LINK_LIBRARIES` 主要反映直接链接项，不能把它当成某个配置下最终命令行的完整展开结果。若要观察目标间的关系，可以让 CMake 生成 Graphviz 文件：

```bash
# 配置项目并生成目标依赖图
cmake -S . -B build --graphviz=build/deps.dot

# 使用 Graphviz 渲染
dot -Tpng build/deps.dot -o build/deps.png
```

依赖图适合查看目标关系，却不会完整展示每个源文件最终采用的编译参数。排查具体命令时，可以使用 `cmake --build build --verbose`；Ninja 和 Makefile 等生成器还可以通过 `CMAKE_EXPORT_COMPILE_COMMANDS=ON` 生成 `compile_commands.json`。`cmake --trace-expand` 能显示 CMake 脚本的调用及变量展开过程，但输出量很大，通常配合 `--trace-source=<file>` 缩小范围。

这一节的重点不是记住所有属性名，而是把要求放到真正需要它的目标上，并根据公共接口选择可见性。如果项目仍用 `CMAKE_CXX_FLAGS`、`include_directories()` 等全局设置，可以逐项确认影响范围，再迁移到 `target_compile_options`、`target_include_directories` 等目标级命令。这样更容易从配置中判断某个选项为何出现在一条编译或链接命令里。


=== 多文件项目组织
// 真实项目的结构
// - 典型的项目目录结构
// - add_subdirectory：包含子目录
// - 子目录的 CMakeLists.txt
// - 库与可执行文件的分离
// - 头文件组织：include/ 与 src/
// - 公开头文件与私有头文件
// - file(GLOB ...) 的使用与争议
// - 手动列出源文件 vs 自动搜索
// - 示例：RoboMaster 项目结构
//   rm_vision/
//   ├── CMakeLists.txt
//   ├── include/rm_vision/
//   ├── src/
//   ├── detector/
//   ├── tracker/
//   └── test/
// === 多文件项目组织

到目前为止，示例大多只有一个目录。项目增加到几十个源文件后，通常需要按库、应用和测试划分目录，并让 CMake 配置与这些边界对应。本节通过两种常见结构说明如何拆分 `CMakeLists.txt`、组织公开与私有头文件，以及管理源文件列表。目录形式没有唯一答案，判断标准是模块职责和依赖关系能否从代码与构建配置中看清。

==== 典型的项目目录结构

在深入 CMake 配置之前，让我们先看看 C++ 项目的常见目录结构。虽然没有强制的标准，但社区已经形成了一些广泛接受的约定。

一个典型的 C++ 项目结构如下：

```
my_project/
├── CMakeLists.txt          # 顶层 CMake 配置
├── README.md               # 项目说明
├── LICENSE                 # 许可证
├── .gitignore              # Git 忽略规则
│
├── include/                # 公开头文件
│   └── my_project/
│       ├── core.h
│       ├── utils.h
│       └── config.h
│
├── src/                    # 源文件和私有头文件
│   ├── CMakeLists.txt      # 可选：子目录的 CMake 配置
│   ├── core.cpp
│   ├── utils.cpp
│   ├── config.cpp
│   └── internal/           # 私有实现细节
│       ├── impl.h
│       └── impl.cpp
│
├── apps/                   # 可执行程序
│   ├── CMakeLists.txt
│   └── main.cpp
│
├── tests/                  # 测试代码
│   ├── CMakeLists.txt
│   ├── test_core.cpp
│   └── test_utils.cpp
│
├── examples/               # 示例代码
│   ├── CMakeLists.txt
│   └── example_basic.cpp
│
├── docs/                   # 文档
│   └── Doxyfile
│
├── cmake/                  # CMake 模块和脚本
│   ├── FindSomeLib.cmake
│   └── CompilerWarnings.cmake
│
├── third_party/            # 第三方依赖（如果不使用包管理器）
│   └── json/
│
└── scripts/                # 辅助脚本
    ├── build.sh
    └── format.sh
```

这个结构有几个关键的设计决策。首先是头文件和源文件的分离：公开头文件放在 `include/` 目录，源文件放在 `src/` 目录。其次是库代码和应用代码的分离：核心功能编译成库，可执行程序单独放在 `apps/` 目录。第三是测试代码独立：测试文件放在 `tests/` 目录，与主代码分开。

这种布局把公开接口、实现、程序入口和测试分开。开发者可以先从 `include/` 了解库对外提供什么，再到 `src/` 查看实现；应用入口和测试也不会混在库源码列表中。它是一种常见约定，不要求每个项目都建立所有这些目录。

注意 `include/` 下还有一层以项目名命名的目录（`include/my_project/`）。这样做是为了避免头文件名冲突。用户包含头文件时会写 `#include <my_project/core.h>` 而不是 `#include <core.h>`，即使他们的项目中也有一个 `core.h` 也不会冲突。

实际项目中，还有一种常见的“模块化”结构，以 RoboMaster 视觉项目 RMCV 为例：

```
RMCV/
├── CMakeLists.txt              # 顶层 CMake 配置
├── main.cpp                    # 主程序入口
│
├── aimer/                      # 自动瞄准模块
│   ├── CMakeLists.txt          # 模块配置（仅包含子目录）
│   ├── common/                 # 公共子模块
│   │   ├── CMakeLists.txt
│   │   ├── transformer/        # 坐标变换
│   │   ├── filter/             # 滤波器
│   │   └── math/               # 数学工具
│   └── auto_aim/               # 自瞄核心
│       ├── CMakeLists.txt
│       ├── detector/           # 目标检测
│       │   ├── CMakeLists.txt
│       │   ├── detector_node.cpp
│       │   └── detector_rv/    # 传统视觉检测器
│       ├── predictor/          # 运动预测
│       │   ├── CMakeLists.txt
│       │   ├── enemy_state/    # 状态估计
│       │   └── enemy_model/    # 运动模型
│       └── fire_control/       # 火控系统
│
├── hardware/                   # 硬件抽象层
│   ├── CMakeLists.txt
│   ├── hardware_node.cpp
│   ├── hik_cam/                # 海康相机驱动
│   └── serial/                 # 串口通信
│
├── plugin/                     # 插件系统
│   ├── CMakeLists.txt
│   ├── debug/                  # 日志模块
│   ├── param/                  # 参数管理
│   └── rmcv_bag/               # 数据录制
│
├── umt/                        # 线程通信框架（header-only）
│   ├── Message.hpp
│   └── ObjManager.hpp
│
├── config/                     # 配置文件
│   ├── camera.yaml
│   └── aimer.toml
│
└── test/                       # 测试程序
    ├── test_param.cpp
    ├── test_camera.cpp
    └── time_sync/
```

这个示例没有统一的顶层 `include/`，而由各模块组织自己的头文件，再通过 `target_include_directories` 声明哪些目录供其他目标使用。这种布局适合主要在同一仓库内组合的模块；若某个库还要安装给外部项目使用，仍应明确区分可安装的公共头文件和仓库内部头文件，避免把整个源码目录都暴露出去。

==== add_subdirectory：包含子目录

当项目变大时，把所有 CMake 配置都写在一个文件里会变得难以维护。CMake 支持将配置分散到多个 CMakeLists.txt 文件中，每个子目录可以有自己的配置文件。`add_subdirectory` 命令用于包含子目录。

```cmake
# 顶层 CMakeLists.txt
cmake_minimum_required(VERSION 3.16)
project(RMCV)

# 查找依赖
find_package(OpenCV REQUIRED)
find_package(fmt REQUIRED)
find_package(Eigen3 REQUIRED)

# 将当前 OpenCV 包提供的变量封装为项目内目标
add_library(rm_opencv INTERFACE)
target_include_directories(rm_opencv SYSTEM INTERFACE ${OpenCV_INCLUDE_DIRS})
target_link_libraries(rm_opencv INTERFACE ${OpenCV_LIBS})

# 仓库内的 header-only 通信库
add_library(umt INTERFACE)
target_include_directories(umt INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}/umt)
target_compile_features(umt INTERFACE cxx_std_17)

# 按依赖顺序添加子目录
add_subdirectory(plugin)      # 基础设施，无依赖
add_subdirectory(hardware)    # 依赖 plugin
add_subdirectory(aimer)       # 依赖 plugin, hardware

# 主程序
add_executable(RMCV2026 main.cpp)
target_compile_features(RMCV2026 PRIVATE cxx_std_17)
target_link_libraries(RMCV2026 PRIVATE
    plugin
    hardware
    detector
    predictor
    rm_opencv
    fmt::fmt
    umt
)
```

当 CMake 执行 `add_subdirectory(plugin)` 时，会立即处理 `plugin/CMakeLists.txt`，完成后再继续当前文件。子目录创建的普通构建目标可以被项目其他目录引用；普通变量则遵循目录作用域：子目录会继承父目录当时的变量，但在子目录中修改普通变量不会自动改写父目录。确实需要返回数据时，可以重新考虑是否应建模为目标属性，或显式使用函数返回值、`PARENT_SCOPE` 等机制。

`add_subdirectory` 还可以指定一个二进制目录，作为该子目录对应的构建树位置：

```cmake
# 在当前构建树的 lib 子目录处理 src
add_subdirectory(src ${CMAKE_BINARY_DIR}/lib)
```

如果你想包含项目外部的目录，需要指定二进制目录：

```cmake
# 包含源码树外的目录时，必须显式给出它的二进制目录
add_subdirectory("/path/to/external/lib" "${CMAKE_BINARY_DIR}/external_lib_build")
```

源码树外的目录会作为当前构建的一部分执行，可能定义选项、安装规则和目标；引入前应确认它本来就支持这种用法。`add_subdirectory` 按出现顺序立即处理脚本，并不是先扫描完所有目录再统一解析。别名目标、读取目标属性以及部分跨目录命令都要求相关目标已经存在，因此通常先加入底层模块，再加入使用它的上层模块。这样也便于阅读配置时沿依赖顺序理解项目。

==== 子目录的 CMakeLists.txt

同一项目内部的子目录通常只定义本模块的目标，不重复调用 `cmake_minimum_required` 和 `project`，因为顶层已经建立了项目与策略范围。若该目录本身也是可独立配置的子项目，它可以有自己的顶层入口；那属于有意设计的嵌套项目，需要同时验证独立构建和被父项目引入两种路径。

```cmake
# plugin/CMakeLists.txt - 基础插件库

# 这个模块直接使用的依赖；也可由顶层统一查找后提供目标
find_package(OpenCV REQUIRED)
find_package(tomlplusplus CONFIG REQUIRED)
find_package(fmt REQUIRED)

# 显式列出属于该目标的实现文件
add_library(plugin STATIC
    debug/logger.cpp
    param/runtime_parameter.cpp
    plotter/plotter.cpp
)

# 设置头文件路径
target_include_directories(plugin PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
)

# 假设公共参数接口出现 toml++ 类型，其余库只用于实现
target_link_libraries(plugin
    PUBLIC tomlplusplus::tomlplusplus
    PRIVATE rm_opencv fmt::fmt
)

# 包含子模块
add_subdirectory(rmcv_bag)
```

这里延续了前述“仓库内模块”的布局，因此把整个 `plugin` 目录作为构建接口公开。若其中混有不希望下游包含的实现头文件，应改成单独的公共目录；要安装和导出该库时，还要加入 `BUILD_INTERFACE`/`INSTALL_INTERFACE`，不能把源码绝对路径写进安装接口。

注意这里使用了 `CMAKE_CURRENT_SOURCE_DIR`：它始终指向当前正在处理的 `CMakeLists.txt` 所在源码目录。`PROJECT_SOURCE_DIR` 指向最近一次 `project()` 调用对应的源码目录；若项目通过 `add_subdirectory` 引入另一个带有 `project()` 的子项目，它不一定等于最外层源码目录。最外层源码目录由 `CMAKE_SOURCE_DIR` 表示。选择变量时应先明确路径是相对当前模块、当前项目，还是整个构建入口。

硬件层的 CMakeLists.txt 展示了如何组织多个子模块：

```cmake
# hardware/CMakeLists.txt

# 添加子模块
add_subdirectory(hik_cam)
add_subdirectory(serial)

# 创建硬件节点库（聚合库）
add_library(hardware STATIC
    hardware_node.cpp
)

target_include_directories(hardware PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
)

# 假设 hardware 的公共接口暴露两个子模块的类型
target_link_libraries(hardware PUBLIC
    hardware_camera
    hardware_serial
)

# 只在 hardware_node.cpp 中使用的依赖
target_link_libraries(hardware PRIVATE
    rm_opencv
    fmt::fmt
    plugin
)
```

测试的 CMakeLists.txt：

```cmake
# tests/CMakeLists.txt

# 查找 GTest
find_package(GTest REQUIRED)

# 创建测试可执行文件
add_executable(test_core test_core.cpp)
target_link_libraries(test_core PRIVATE
    my_project_core
    GTest::gtest_main
)

add_executable(test_utils test_utils.cpp)
target_link_libraries(test_utils PRIVATE
    my_project_core
    GTest::gtest_main
)

# 注册测试
include(GoogleTest)
gtest_discover_tests(test_core)
gtest_discover_tests(test_utils)
```

测试目录可以自己调用 `find_package(GTest REQUIRED)`，也可以使用顶层已经查找到的导入目标。前一种写法能让该目录的直接依赖更明显，但重复调用仍会重新执行相应的查找逻辑，不能笼统地说没有成本或行为一定相同；组件、版本要求和包脚本的实现都会影响结果。`enable_testing()` 则应在顶层启用，确保从顶层构建目录运行 `ctest` 时能发现子目录注册的测试。

==== 纯转发的 CMakeLists.txt

有时候一个目录只是用来组织子目录，本身不产生任何目标。这时候 CMakeLists.txt 可以非常简洁：

```cmake
# aimer/CMakeLists.txt - 纯转发

add_subdirectory(common)
add_subdirectory(auto_aim)
```

```cmake
# aimer/auto_aim/CMakeLists.txt - 纯转发

add_subdirectory(detector)
add_subdirectory(predictor)
add_subdirectory(fire_control)
```

这种“纯转发”的 CMakeLists.txt 让目录结构更清晰，每个功能模块都在自己的子目录中定义目标。

==== 条件包含子目录

测试、示例或特定后端不一定要在每次构建中启用，可以用选项控制对应子目录：

```cmake
# 顶层 CMakeLists.txt
cmake_minimum_required(VERSION 3.16)
project(my_project VERSION 1.0.0 LANGUAGES CXX)

# CTest 提供标准的 BUILD_TESTING 选项，并在启用时调用 enable_testing()
include(CTest)
option(BUILD_EXAMPLES "Build examples" OFF)

# 核心库（始终构建）
add_subdirectory(src)
add_subdirectory(apps)

# 可选子目录
if(BUILD_TESTING)
    add_subdirectory(tests)
endif()

if(BUILD_EXAMPLES)
    add_subdirectory(examples)
endif()
```

用户可以在配置时选择是否构建测试：

```bash
# 不构建测试
cmake -S . -B build -DBUILD_TESTING=OFF

# 构建测试（默认）
cmake -S . -B build
```

以 RMCV 为例，检测器模块有可选的 YOLO 支持：

```cmake
# aimer/auto_aim/detector/CMakeLists.txt

# 检测器选项
option(ENABLE_YOLO_DETECTOR "Enable YOLO detector (requires OpenVINO)" OFF)

# 传统检测器（始终编译）
add_subdirectory(detector_rv)

# 可选：YOLO 检测器
if(ENABLE_YOLO_DETECTOR)
    add_subdirectory(detector_yolo)
    message(STATUS "YOLO detector: ENABLED")
else()
    message(STATUS "YOLO detector: DISABLED")
endif()

# 创建 detector_node 库
add_library(detector_node STATIC detector_node.cpp)

# 这里假设 detector_node 的公共接口出现这些模块的类型；
# 若只在 detector_node.cpp 中使用，应改为 PRIVATE。
target_link_libraries(detector_node PUBLIC
    detector_traditional
    plugin hardware aimer_common
)

# 条件链接和编译宏
if(ENABLE_YOLO_DETECTOR)
    # 若宏只控制 detector_node.cpp 的实现，应使用 PRIVATE；
    # 只有公共头文件也依赖该宏时才改为 PUBLIC。
    target_compile_definitions(detector_node PRIVATE ENABLE_YOLO_DETECTOR)
    target_link_libraries(detector_node PRIVATE detector_yolo)
endif()

# 创建统一接口库
add_library(detector INTERFACE)
target_link_libraries(detector INTERFACE detector_traditional detector_node)
```

选项会进入 CMake 缓存。修改默认值不会覆盖构建目录中已有的缓存值；需要时可在配置命令中显式传入 `-DENABLE_YOLO_DETECTOR=ON`，或使用新的构建目录。可选模块还要考虑代码接口：如果关闭 YOLO 后公共头文件仍引用其类型，仅仅跳过 `add_subdirectory` 并不能让项目正常编译。

==== 头文件组织：公开与私有

头文件的组织是项目结构中的重要决策。一个核心问题是：哪些头文件是公开的（库的用户需要使用），哪些是私有的（只在库内部使用）。

公开头文件定义了库的接口，包括使用者需要的类、函数和常量等。一种常见布局是把它们放在 `include/<project>/` 下，使下游通过 `#include <my_project/xxx.h>` 引用。公共头文件应自行包含其声明所需的标准库和第三方头文件，不能依赖某个 `.cpp` 恰好先包含了它们。

```cpp
// include/my_project/detector.h - 公开头文件
#pragma once

#include <memory>
#include <string>
#include <vector>
#include <opencv2/core.hpp>

namespace my_project {

struct Armor {
    cv::Point2f center;
    float confidence;
    int id;
};

class ArmorDetector {
public:
    explicit ArmorDetector(const std::string& config_path);
    // Impl 在此处仍是不完整类型，因此析构函数在 .cpp 中定义。
    ~ArmorDetector();

    std::vector<Armor> Detect(const cv::Mat& image);

private:
    class Impl;  // Pimpl 模式，隐藏实现
    std::unique_ptr<Impl> impl_;
};

}  // namespace my_project
```

私有头文件是库内部使用的，用户不需要也不应该包含它们。它们可以放在 `src/` 目录下，与实现文件放在一起。私有头文件可以包含实现细节、内部数据结构、辅助函数等。

```cpp
// src/internal/nn_backend.h - 私有头文件
#pragma once

#include <string>
#include <vector>
#include <onnxruntime/core/session/onnxruntime_cxx_api.h>

namespace my_project::internal {

class NNBackend {
public:
    explicit NNBackend(const std::string& model_path);
    std::vector<float> Infer(const std::vector<float>& input);

private:
    Ort::Env env_;
    Ort::Session session_;
    // 更多实现细节...
};

}  // namespace my_project::internal
```

在 CMake 中体现这种区分：

```cmake
add_library(my_project_detector
    src/detector/armor_detector.cpp
    src/detector/nn_backend.cpp
)

target_include_directories(my_project_detector
    PUBLIC
        # 公开头文件：用户可见
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
    PRIVATE
        # 私有头文件：只在库内部可见
        ${CMAKE_CURRENT_SOURCE_DIR}/src
)

# 公共头文件出现 OpenCV 类型，因此向下游传递其使用要求
target_link_libraries(my_project_detector PUBLIC rm_opencv)
```

这样配置后，库自身的编译命令可以用 `#include "internal/nn_backend.h"`（相对于 `src/` 搜索目录）；下游目标通过 CMake 接口只获得 `include/` 搜索路径，因此正常情况下使用 `#include <my_project/detector.h>`。这不是文件系统访问控制：如果使用者自行添加源码路径，仍可能包含私有头文件，只是这种依赖不受库的兼容性承诺保护。

区分二者首先是为了说明兼容性边界：公共头文件属于使用接口，私有头文件可以随实现调整。其次，如果私有头文件没有被公共头文件间接包含，它的变化通常只触发库自身相关源文件重编译，不会让所有下游源文件都重编译。公开目录也为安装规则提供了明确范围。

上例虽然用 Pimpl 隐藏了检测器的内部数据，但公共函数仍直接使用 `cv::Mat`、`cv::Point2f`，所以 OpenCV 依然是这个接口的公开依赖。相应目标应把 OpenCV 的头文件使用要求设为 `PUBLIC`；只有把这些类型也隔离出公共签名后，才可能将 OpenCV 降为纯实现依赖。

==== 库与可执行文件的分离

如果核心功能能形成清楚的 API，可以将其编译为库，让可执行文件主要负责组合这些模块。这不是必须遵守的目录规则，但通常带来几个实际好处：

首先，测试程序可以直接调用库的接口，不必经过主程序的命令行入口。能否方便地测试仍取决于接口设计和外部依赖是否可控，并不是拆成库后自动获得。

其次，代码更容易复用。如果将来有另一个程序需要相同的功能，直接链接库即可，不需要复制代码。

第三，构建系统可以按依赖增量工作。只修改主程序源文件时，未变化的库通常不必重编译；修改库实现后，则要重编译受影响的库源文件，并重新链接依赖它的产物。公共头文件变化仍可能触发较多下游源文件重编译。

以 RMCV 为例，核心功能在各个库中实现：

```cmake
# 主程序
add_executable(RMCV2026 main.cpp)
target_link_libraries(RMCV2026 PRIVATE
    plugin hardware detector predictor rmcv_bag
    ${OpenCV_LIBS} fmt::fmt
)

# 测试程序 - 每个测试针对特定模块
add_executable(test_param test/test_param.cpp)
target_link_libraries(test_param PRIVATE rm_opencv fmt::fmt plugin)

add_executable(test_serial test/test_serial.cpp)
target_link_libraries(test_serial PRIVATE rm_opencv fmt::fmt plugin hardware)

add_executable(test_camera test/test_camera.cpp)
target_link_libraries(test_camera PRIVATE rm_opencv fmt::fmt plugin hardware)

add_executable(test_transformer test/test_transformer.cpp)
target_link_libraries(test_transformer PRIVATE rm_opencv fmt::fmt aimer_common)

add_executable(test_ballistic test/test_ballistic.cpp)
target_link_libraries(test_ballistic PRIVATE rm_opencv fmt::fmt plugin hardware aimer_common)

# 回放测试 - 需要完整的检测和预测模块
add_executable(test_playback test/test_playback.cpp)
target_link_libraries(test_playback
    PRIVATE
    plugin hardware detector predictor rmcv_bag
    rm_opencv fmt::fmt
)
```

每个测试应声明自己直接使用的目标。上例中的测试源码若并不直接使用 OpenCV 或 fmt，而这些要求已经由被测库正确传递，还可以删掉相应的直接链接项。依赖越精确，配置越容易解释；对构建时间的实际影响则与目标规模、头文件依赖和缓存命中情况有关。

主程序的代码应该尽量精简，主要负责：解析命令行参数、初始化配置、创建对象、运行主循环。核心逻辑都应该在库中实现。

```cpp
// main.cpp
#include <chrono>
#include <csignal>
#include <thread>
#include "plugin/debug/debug.hpp"
#include "plugin/param/runtime_parameter.hpp"
#include "hardware/hardware_node.hpp"
#include "aimer/auto_aim/detector/detector_node.hpp"
#include "aimer/auto_aim/predictor/predictor_node.hpp"

volatile std::sig_atomic_t running = 1;

void signal_handler(int) { running = 0; }

int main() {
    // 信号处理
    std::signal(SIGINT, signal_handler);

    // 初始化
    debug::init_session();
    runtime_param::parameter_run("aimer.toml");
    tf::init();

    // 启动各模块线程
    hardware::start();
    detector::start();
    predictor::start();

    // 主循环
    while (running != 0) {
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }

    // 通知模块停止并等待工作线程结束；具体 API 由项目定义
    predictor::stop();
    detector::stop();
    hardware::stop();

    debug::print("info", "main", "Shutting down...");
    return 0;
}
```

这个入口只是结构示例，省略了启动失败、异常、线程停止超时等处理。信号处理函数中只修改 `volatile std::sig_atomic_t`，避免在异步信号上下文调用日志、分配内存或加锁等非信号安全操作；真正的清理仍在主流程中完成。各模块还应提供可重复调用且能等待线程退出的停止接口。

==== file(GLOB) 的使用与争议

源文件较多时，逐项维护列表会增加一些工作。CMake 的 `file(GLOB)` 可以在配置阶段收集匹配模式的文件：

```cmake
# 收集所有 .cpp 文件
file(GLOB SOURCES "src/*.cpp")

# 递归收集（包括子目录）
file(GLOB_RECURSE SOURCES "src/*.cpp")

# 使用收集到的文件列表
add_library(my_lib ${SOURCES})
```

默认的 `GLOB` 结果只在 CMake 配置时计算。添加一个恰好匹配的新文件并不会修改 `CMakeLists.txt`，现有构建系统因而可能没有触发重新配置，新文件也就不会进入目标。删除已记录的源文件通常会导致构建报错，而不是可靠地“继续使用旧目标文件”。正因为文件集合的变化不总能被构建系统观察到，CMake 文档不建议用无额外机制的 `GLOB` 收集源码树中的源文件。

```bash
# 初始配置与构建
cmake -S . -B build
cmake --build build

# 添加新文件 src/new_feature.cpp
# 原来的构建规则中还没有这个文件
cmake --build build

# 需要重新配置
cmake -S . -B build
cmake --build build  # 重新生成后，文件才进入目标
```

显式列出源文件能让增删文件与 `CMakeLists.txt` 的改动出现在同一次代码审查中，而且构建工具会观察到配置文件变化并重新运行 CMake：

```cmake
# 对需要明确审核成员的库，通常显式列出
add_library(my_lib
    src/core.cpp
    src/utils.cpp
    src/config.cpp
    src/feature_a.cpp
    src/feature_b.cpp
)
```

如果文件集合本来就由约定的目录模式决定，CMake 3.12 引入的 `CONFIGURE_DEPENDS` 可以让生成的构建系统在主构建开始时检查匹配结果，并在结果变化后重新配置：

```cmake
file(GLOB_RECURSE SOURCES CONFIGURE_DEPENDS "src/*.cpp")
add_library(my_lib ${SOURCES})
```

这种方式比普通 `GLOB` 更能跟踪增删文件，但不是无条件替代显式列表。CMake 文档提醒它未必适用于未来加入的所有生成器；每次构建还要执行额外检查，其开销取决于文件数量、生成器和文件系统。宽泛的模式也可能把临时文件或本不属于目标的 `.cpp` 收进来。因此应限制匹配目录和扩展名，并在所支持的生成器上验证重新配置行为。

旧项目中还常见 `aux_source_directory`：

```cmake
# plugin/CMakeLists.txt
aux_source_directory(./debug debug_src)
aux_source_directory(./param param_src)
aux_source_directory(./plotter plotter_src)

add_library(plugin STATIC ${debug_src} ${param_src} ${plotter_src})
```

它收集指定目录中 CMake 识别的源文件扩展名，最初主要面向生成源码的场景。它没有 `CONFIGURE_DEPENDS`，添加新文件仍需要重新配置，因此并不比 `file(GLOB)` 更可靠。对于普通项目，显式列表最容易审查；选择 `GLOB CONFIGURE_DEPENDS` 时，应把自动发现文件视为有意的项目规则，而不是“一劳永逸”的省事写法。尤其要谨慎使用 `GLOB_RECURSE`，因为子目录边界和目标归属很容易被一起抹平。

==== 处理第三方 SDK

有些第三方 SDK 不提供可直接使用的 CMake 包配置。与其把全局链接目录和裸库名传播给其他目标，更稳妥的做法是为已知的库文件创建一个导入目标。下面以一种可能的海康相机 SDK 安装布局为例；实际目录和依赖必须以所安装版本的厂商文档为准：

```cmake
# hardware/hik_cam/CMakeLists.txt

# 允许工具链文件或命令行覆盖安装位置
set(HIKROBOT_ROOT "/opt/MVS" CACHE PATH "Hikrobot MVS SDK root")

# 创建相机库
add_library(hardware_camera STATIC hik_camera.cpp)

# 根据目标平台选择厂商库文件
if(CMAKE_SYSTEM_PROCESSOR MATCHES "^(x86_64|AMD64)$")
    set(_hikrobot_lib_dir "${HIKROBOT_ROOT}/lib/64")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(aarch64|arm64)$")
    set(_hikrobot_lib_dir "${HIKROBOT_ROOT}/lib/aarch64")
else()
    message(FATAL_ERROR
        "Unsupported Hikrobot SDK architecture: ${CMAKE_SYSTEM_PROCESSOR}")
endif()

set(_hikrobot_library "${_hikrobot_lib_dir}/libMvCameraControl.so")
if(NOT IS_DIRECTORY "${HIKROBOT_ROOT}/include")
    message(FATAL_ERROR "Hikrobot SDK headers not found: ${HIKROBOT_ROOT}/include")
endif()
if(NOT EXISTS "${_hikrobot_library}")
    message(FATAL_ERROR "Hikrobot SDK library not found: ${_hikrobot_library}")
endif()

add_library(Hikrobot::MvCameraControl SHARED IMPORTED GLOBAL)
set_target_properties(Hikrobot::MvCameraControl PROPERTIES
    IMPORTED_LOCATION "${_hikrobot_library}"
    INTERFACE_INCLUDE_DIRECTORIES "${HIKROBOT_ROOT}/include"
)

# 若公共头文件不出现厂商类型，SDK 和 OpenCV 都可保持为实现依赖
target_link_libraries(hardware_camera PRIVATE
    Hikrobot::MvCameraControl
    rm_opencv
)
```

`CMAKE_SYSTEM_PROCESSOR` 描述 CMake 当前配置的目标系统处理器；交叉编译时它应来自工具链配置，而不是简单等同于构建主机。处理更多操作系统时，还要选择 `.dll`/导入库、`.dylib` 或 `.so` 等不同产物。导入目标只封装了示例中明确列出的头文件和主库；如果 SDK 还要求其他运行库、链接选项、RPATH 或设备权限，必须按厂商说明补充并在目标环境验证。配置阶段的 `EXISTS` 检查只能确认路径存在，不能证明架构和 ABI 兼容。

==== 条件编译可选功能

可选功能可以根据包是否提供可用目标来决定是否构建。下面让时间同步测试只在 Ceres 可用时出现，同时让外参标定在没有 Ceres 时选择显式实现的备用路径：

```cmake
# 顶层 CMakeLists.txt

# 相机-IMU 时间戳标定（需要 Ceres）
find_package(Ceres QUIET)
if(TARGET Ceres::ceres)
    add_executable(test_time_sync test/time_sync/test_time_sync.cpp)
    target_include_directories(test_time_sync PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/test
    )
    target_link_libraries(test_time_sync PRIVATE
        rm_opencv fmt::fmt
        plugin hardware detector aimer_common
        Ceres::ceres
    )
    message(STATUS "test_time_sync will be built (Ceres found)")
endif()

# 外参标定始终构建，但明确选择优化后端
add_executable(test_extrinsic_calib
    test/extrinsic_calib/test_extrinsic_calib.cpp
)
target_link_libraries(test_extrinsic_calib PRIVATE
    rm_opencv fmt::fmt plugin hardware aimer_common
)

if(TARGET Ceres::ceres)
    target_compile_definitions(test_extrinsic_calib PRIVATE USE_CERES=1)
    target_link_libraries(test_extrinsic_calib PRIVATE Ceres::ceres)
    message(STATUS "test_extrinsic_calib backend: Ceres")
else()
    target_compile_definitions(test_extrinsic_calib PRIVATE USE_CERES=0)
    message(STATUS "test_extrinsic_calib backend: built-in grid search")
endif()

# 假设项目自己的包配置提供 RMCVSimulator::simulator 目标
find_package(RMCVSimulator QUIET CONFIG)
if(TARGET RMCVSimulator::simulator)
    add_executable(test_simulator test/test_simulator.cpp)
    target_link_libraries(test_simulator PRIVATE
        plugin hardware detector predictor
        RMCVSimulator::simulator
        rm_opencv fmt::fmt
    )
    message(STATUS "test_simulator will be built")
endif()
```

`QUIET` 会抑制包未找到时通常产生的提示，但不会把语法错误、包配置内部错误等全部吞掉。检查目标比只检查一个变量更贴近后续需求：有些旧包只定义 `${CERES_LIBRARIES}` 等变量，这时应按该版本的文档适配，而不是假定 `Ceres_FOUND` 为真就一定存在 `Ceres::ceres`。源码应使用 `#if USE_CERES` 区分这里的 `1` 和 `0`，而不是使用只判断宏是否定义的 `#ifdef USE_CERES`。备用分支也必须确实有对应实现并经过测试；预处理宏本身不会自动生成“网格搜索”算法。

==== 模块化的目录结构

对于更大的项目，可以采用模块化的目录结构，每个功能模块是一个独立的目录，有自己完整的 include、src 和 CMakeLists.txt：

```
rm_vision/
├── CMakeLists.txt
│
├── common/                 # 公共模块
│   ├── CMakeLists.txt
│   ├── include/common/
│   │   ├── types.h
│   │   ├── config.h
│   │   └── logger.h
│   └── src/
│       ├── config.cpp
│       └── logger.cpp
│
├── detector/               # 检测模块
│   ├── CMakeLists.txt
│   ├── include/detector/
│   │   ├── armor_detector.h
│   │   └── rune_detector.h
│   └── src/
│       ├── armor_detector.cpp
│       ├── rune_detector.cpp
│       └── internal/
│           └── nn_backend.cpp
│
├── tracker/                # 跟踪模块
│   ├── CMakeLists.txt
│   ├── include/tracker/
│   │   ├── armor_tracker.h
│   │   └── kalman_filter.h
│   └── src/
│       ├── armor_tracker.cpp
│       └── kalman_filter.cpp
│
├── predictor/              # 预测模块
│   ├── CMakeLists.txt
│   ├── include/predictor/
│   │   └── motion_predictor.h
│   └── src/
│       └── motion_predictor.cpp
│
├── apps/                   # 应用程序
│   ├── CMakeLists.txt
│   └── rm_vision_node.cpp
│
└── tests/                  # 测试
    ├── CMakeLists.txt
    ├── test_detector.cpp
    └── test_tracker.cpp
```

顶层 CMakeLists.txt：

```cmake
cmake_minimum_required(VERSION 3.16)
project(rm_vision VERSION 2.0.0 LANGUAGES CXX)

# Ninja/Makefile 等部分生成器可据此导出实际编译命令
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# 标准测试选项
include(CTest)

# 依赖
find_package(OpenCV REQUIRED)
find_package(Eigen3 REQUIRED)

add_library(rm_opencv INTERFACE)
target_include_directories(rm_opencv SYSTEM INTERFACE ${OpenCV_INCLUDE_DIRS})
target_link_libraries(rm_opencv INTERFACE ${OpenCV_LIBS})

# 子模块（按依赖顺序）
add_subdirectory(common)
add_subdirectory(detector)
add_subdirectory(tracker)
add_subdirectory(predictor)

# 应用程序
add_subdirectory(apps)

# 测试
if(BUILD_TESTING)
    add_subdirectory(tests)
endif()
```

common 模块的 CMakeLists.txt：

```cmake
# common/CMakeLists.txt

add_library(rm_common
    src/config.cpp
    src/logger.cpp
)

target_include_directories(rm_common PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

target_compile_features(rm_common PUBLIC cxx_std_17)

# common 模块通常依赖较少
target_link_libraries(rm_common PUBLIC
    Eigen3::Eigen
)
```

detector 模块的 CMakeLists.txt：

```cmake
# detector/CMakeLists.txt

add_library(rm_detector
    src/armor_detector.cpp
    src/rune_detector.cpp
    src/internal/nn_backend.cpp
)

target_include_directories(rm_detector
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
)

target_link_libraries(rm_detector
    PUBLIC rm_common
    PUBLIC rm_opencv  # 公共检测接口使用 cv::Mat 等 OpenCV 类型
)
```

apps 目录的 CMakeLists.txt：

```cmake
# apps/CMakeLists.txt

add_executable(rm_vision_node rm_vision_node.cpp)

target_link_libraries(rm_vision_node PRIVATE
    rm_detector
    rm_tracker
    rm_predictor
    rm_opencv  # 主程序需要 OpenCV 进行图像采集
)
```

这种结构让各模块在自己的目录中声明源文件、公共接口和直接依赖。目录拆开并不等于模块已经独立：仍要检查公共头文件是否越过边界包含内部文件，以及目标是否依赖未声明的全局设置。示例中的 `rm_common` 是基础库，其他模块应根据实际 API 声明对它或相邻模块的依赖，而不是仅凭目录层级推断。

==== 全局编译选项

`add_compile_options` 和 `add_compile_definitions` 会影响当前目录以及随后处理的子目录，范围容易随着目录顺序变化。即使团队希望多数自有目标采用同一组警告或分析选项，也可以先放进一个 `INTERFACE` 目标，再让需要它的目标显式链接：

```cmake
# 顶层 CMakeLists.txt
add_library(rm_build_options INTERFACE)

target_compile_options(rm_build_options INTERFACE
    $<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:-Wall>
    $<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:-Wextra>
    $<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:-Werror=return-type>
    $<$<CXX_COMPILER_ID:MSVC>:/W4>
)

# 保留栈帧有助于 perf 等工具回溯；先确认所用编译器支持这些选项
option(ENABLE_PROFILING "Enable profiling support for VTune/perf" OFF)
if(ENABLE_PROFILING)
    target_compile_options(rm_build_options INTERFACE
        $<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:-fno-omit-frame-pointer>
        $<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:-g>
    )
endif()

# 仅对明确采用项目策略的自有目标生效
target_link_libraries(rm_common PRIVATE rm_build_options)
target_link_libraries(rm_detector PRIVATE rm_build_options)
target_link_libraries(rm_vision_node PRIVATE rm_build_options)
```

这里没有手动覆盖 Debug、Release 等配置的优化级别；工具链和 CMake 已为标准配置提供默认标志。若项目确实要启用 LTO，可用 `CheckIPOSupported` 检查后设置目标的 `INTERPROCEDURAL_OPTIMIZATION` 属性。`-march=native` 会按构建机器生成指令，部署机器的 CPU 较旧或不同就可能无法运行，因此应作为明确的本机构建选项，而不是默认全局设置。多配置生成器还可能同时构建 Debug 和 Release，不能只用配置阶段的 `CMAKE_BUILD_TYPE` 分支描述它们。

源码目录、配置目录和日志目录也不宜无条件编译进所有库。若应用确实需要一个可由构建者覆盖的开发路径，可以把定义限制在应用目标：

```cmake
set(RMCV_CONFIG_DIR "${CMAKE_SOURCE_DIR}/config" CACHE PATH
    "Default RMCV configuration directory")

target_compile_definitions(rm_vision_node PRIVATE
    RMCV_CONFIG_DIR="${RMCV_CONFIG_DIR}"
)
```

代码中再把它转换为路径：

```cpp
#include <filesystem>

std::filesystem::path config_path =
    std::filesystem::path{RMCV_CONFIG_DIR} / "aimer.toml";
```

这种定义包含配置机器上的绝对路径，适合受控的开发运行，不适合直接作为可重定位安装包的默认方案。面向安装后的程序，通常根据命令行参数、环境、平台约定的数据目录或安装时生成的配置确定路径；日志目录还要在运行时检查权限和创建结果。

==== ccache 加速编译

ccache 可以复用此前产生且缓存键匹配的编译结果。CMake 提供编译器启动器变量，无需通过较旧的全局规则属性接入：

```cmake
# 顶层 CMakeLists.txt

find_program(CCACHE_PROGRAM ccache)
if(CCACHE_PROGRAM)
    set(_rm_ccache_assigned FALSE)
    if(NOT CMAKE_C_COMPILER_LAUNCHER)
        set(CMAKE_C_COMPILER_LAUNCHER "${CCACHE_PROGRAM}")
        set(_rm_ccache_assigned TRUE)
    endif()
    if(NOT CMAKE_CXX_COMPILER_LAUNCHER)
        set(CMAKE_CXX_COMPILER_LAUNCHER "${CCACHE_PROGRAM}")
        set(_rm_ccache_assigned TRUE)
    endif()
    if(_rm_ccache_assigned)
        message(STATUS "Using ccache launcher: ${CCACHE_PROGRAM}")
    endif()
endif()
```

这些变量会初始化随后创建目标的启动器属性。是否命中缓存还取决于预处理结果、编译器、选项、环境及 ccache 配置；首次构建通常不能从本地空缓存获益，缓存读写也有成本。可以用 `ccache -s` 观察命中率和容量，再判断它在当前项目与 CI 环境中的实际效果。

==== 使用 INTERFACE 库

接口库本身不产生库文件，可以用来聚合若干使用要求或实现目标：

```cmake
# aimer/auto_aim/detector/CMakeLists.txt

# 创建统一接口库
add_library(detector INTERFACE)

target_include_directories(detector INTERFACE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/common
)

# 链接实际的检测器实现
target_link_libraries(detector INTERFACE
    detector_traditional
    detector_node
)
```

下游目标链接 `detector` 后，会沿它的接口获得 `detector_traditional` 和 `detector_node` 各自声明的链接项与使用要求。接口库不会把两个实现合并成一个新的二进制库，也不会自动修正底层目标缺失的头文件路径或依赖声明。

==== CMake 辅助模块

随着项目增长，你可能会发现一些 CMake 代码在多处重复。可以将这些代码提取到单独的 CMake 模块中，放在 `cmake/` 目录下：

```cmake
# cmake/CompilerWarnings.cmake

# 定义一个函数，为目标启用警告
function(enable_warnings target)
    if(NOT TARGET "${target}")
        message(FATAL_ERROR "enable_warnings: unknown target '${target}'")
    endif()

    if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR
       CMAKE_CXX_COMPILER_ID MATCHES "^(AppleClang|Clang)$")
        target_compile_options(${target} PRIVATE
            -Wall
            -Wextra
            -Wpedantic
            -Wcast-align
            -Wunused
            -Woverloaded-virtual
            -Wnon-virtual-dtor
        )
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
        target_compile_options(${target} PRIVATE
            /W4
            /permissive-
        )
    endif()
endfunction()
```

在顶层 CMakeLists.txt 中包含这个模块：

```cmake
# 添加 cmake/ 目录到模块搜索路径
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

# 包含自定义模块
include(CompilerWarnings)

# 在子目录中使用
# enable_warnings(my_target)
```

子目录中就可以简单地调用：

```cmake
add_library(rm_detector ...)
enable_warnings(rm_detector)
```

这样可以减少重复的配置片段，并把工具链差异集中在一处。共享模块时仍要声明它支持的 CMake 版本和编译器；某个编译器未进入分支只表示没有添加这些警告选项，不表示该工具链已经验证兼容。

==== 打印依赖信息

包查找结果与预期不一致时，可以打印包公开变量和目标接口，先确认当前配置实际得到了什么：

```cmake
# 顶层 CMakeLists.txt 末尾

message(STATUS "-------- Dependency Debug Information --------")

# OpenCV
if(OpenCV_FOUND)
    message(STATUS "OpenCV Version: ${OpenCV_VERSION}")
    message(STATUS "OpenCV Libraries: ${OpenCV_LIBS}")
    message(STATUS "OpenCV Include Dirs: ${OpenCV_INCLUDE_DIRS}")
endif()

# fmt
if(TARGET fmt::fmt)
    get_target_property(FMT_TYPE fmt::fmt TYPE)
    get_target_property(FMT_INCLUDE_DIR fmt::fmt INTERFACE_INCLUDE_DIRECTORIES)
    get_target_property(FMT_LINK_INTERFACE fmt::fmt INTERFACE_LINK_LIBRARIES)
    message(STATUS "fmt Target Type: ${FMT_TYPE}")
    message(STATUS "fmt Include Dirs: ${FMT_INCLUDE_DIR}")
    message(STATUS "fmt Link Interface: ${FMT_LINK_INTERFACE}")
endif()

# Eigen3
if(TARGET Eigen3::Eigen)
    get_target_property(EIGEN_INCLUDE_DIRS Eigen3::Eigen
        INTERFACE_INCLUDE_DIRECTORIES)
    message(STATUS "Eigen3 Include Dirs: ${EIGEN_INCLUDE_DIRS}")
endif()

# tomlplusplus
if(TARGET tomlplusplus::tomlplusplus)
    get_target_property(TOMLPP_INCLUDE_DIR tomlplusplus::tomlplusplus INTERFACE_INCLUDE_DIRECTORIES)
    message(STATUS "tomlplusplus Include Dirs: ${TOMLPP_INCLUDE_DIR}")
endif()

message(STATUS "-----------------------------------------------")
```

属性值可能包含生成器表达式，也可能以 `<name>-NOTFOUND` 结尾；多配置导入库的位置还可能分别存放在 `IMPORTED_LOCATION_DEBUG`、`IMPORTED_LOCATION_RELEASE` 等属性中。因此这些输出用于确认线索，不等于最终编译或链接命令。继续排查时应结合 verbose 构建输出、`compile_commands.json`、实际链接器报错以及包配置文件。

==== 使用命名空间组织代码

配合目录结构，代码中也应该使用命名空间来组织：

```cpp
// common/include/common/types.h
#pragma once

namespace rm {

struct Armor {
    // ...
};

struct Pose {
    // ...
};

}  // namespace rm
```

```cpp
// detector/include/detector/armor_detector.h
#pragma once

#include <vector>
#include <opencv2/core/mat.hpp>

#include <common/types.h>

namespace rm::detector {

class ArmorDetector {
public:
    std::vector<Armor> Detect(const cv::Mat& image);
};

}  // namespace rm::detector
```

```cpp
// tracker/include/tracker/armor_tracker.h
#pragma once

#include <vector>

#include <common/types.h>
#include <detector/armor_detector.h>

namespace rm::tracker {

class ArmorTracker {
public:
    void Update(const std::vector<Armor>& detections);
    Pose GetPrediction() const;
};

}  // namespace rm::tracker
```

用户代码使用时：

```cpp
#include <detector/armor_detector.h>
#include <tracker/armor_tracker.h>

int main() {
    rm::detector::ArmorDetector armor_detector;
    rm::tracker::ArmorTracker tracker;

    // 较长的命名空间可以使用局部别名
    namespace detector_api = rm::detector;
    detector_api::ArmorDetector second_detector;

    // ...
}
```

命名空间可以按模块分层，也可以保持单层，取决于公开 API 的规模和命名冲突风险。目录层级与 C++ 命名空间不必机械地一一对应，但同一模块应保持一致。公共头文件中通常避免 `using namespace`，因为它会把名字注入所有包含者的作用域；局部命名空间别名能缩短名称而不扩大导入范围。

多文件组织的目标是让源码边界、CMake 目标和依赖方向彼此对应。常见目录约定可以降低理解成本，但不能代替接口设计；把文件移动到不同目录也不会自动消除循环依赖或泄漏的实现细节。确定结构后，应通过目标级使用要求、可独立构建的测试以及安装或集成场景检查这些边界是否真的成立。


=== 查找与链接外部库
// 使用第三方库
// - find_package：查找已安装的库
// - Config 模式与 Module 模式
// - <Package>_FOUND, <Package>_INCLUDE_DIRS, <Package>_LIBRARIES
// - 现代方式：导入目标（Imported Targets）
// - 常用库的查找：
//   OpenCV：find_package(OpenCV REQUIRED)
//   Eigen：find_package(Eigen3 REQUIRED)
//   Ceres：find_package(Ceres REQUIRED)
//   Threads：find_package(Threads REQUIRED)
//   GTest：find_package(GTest REQUIRED)
// - pkg-config：查找没有 CMake 支持的库
// - FetchContent：下载并构建依赖
// - ExternalProject：更复杂的外部项目
// - 系统库 vs 本地库
// === 查找与链接外部库

视觉项目通常会使用 OpenCV、Eigen、Ceres 等外部库。CMake 不只要找到一个库文件，还要确定与当前工具链匹配的头文件、编译定义、传递依赖和 Debug/Release 产物。本节依次介绍已安装包、pkg-config、`FetchContent` 和 `ExternalProject`；这些方法解决的阶段不同，不能只按“哪种更新”来选择。

==== find_package：查找已安装的库

`find_package` 用于发现已经可供当前配置使用的包。成功后，查找脚本可能创建导入目标，也可能只设置变量，具体接口由包配置或 Find 模块决定。

```cmake
# 基本用法
find_package(OpenCV REQUIRED)
```

`REQUIRED` 表示配置必须满足该包请求；找不到合适版本或组件时，CMake 会以错误结束。可选包可以省略 `REQUIRED` 并使用 `QUIET` 减少正常的“未找到”提示，但其他配置错误仍可能显示：

```cmake
# 这里只查找已安装的 CUDA Toolkit 库，不启用 CUDA 源语言
find_package(CUDAToolkit QUIET)

if(TARGET CUDA::cudart)
    message(STATUS "CUDA Toolkit found; enabling the optional runtime backend")
    target_link_libraries(rm_backend PRIVATE CUDA::cudart)
else()
    message(STATUS "CUDA Toolkit not found; building the CPU backend")
endif()
```

`FindCUDAToolkit` 从 CMake 3.17 起提供，采用这段写法的项目要相应提高最低版本。如果目标包含 `.cu` 源文件，还要用 `check_language(CUDA)`/`enable_language(CUDA)` 或在 `project(... LANGUAGES CUDA)` 中启用 CUDA 编译器；找到 Toolkit 库不等于 CUDA 编译语言已经可用。

可以指定版本要求：

```cmake
# 请求与 4.5.0 兼容的版本；具体兼容规则由包的版本文件决定
find_package(OpenCV 4.5.0 REQUIRED)

# 要求精确版本
find_package(OpenCV 4.5.4 EXACT REQUIRED)
```

可以指定需要的组件：

```cmake
# 只请求当前目标需要的组件
find_package(OpenCV REQUIRED COMPONENTS core imgproc highgui)

# 同一次查找中也可以区分必需与可选组件
find_package(Boost REQUIRED
    COMPONENTS filesystem system
    OPTIONAL_COMPONENTS python
)
```

不少包会提供“是否找到、版本、头文件目录、库列表”等变量，但并没有一套覆盖所有包的完整命名规则。以常见 OpenCV 配置为例：

```cmake
find_package(OpenCV REQUIRED)

# 常见的变量
message(STATUS "OpenCV found: ${OpenCV_FOUND}")
message(STATUS "OpenCV version: ${OpenCV_VERSION}")
message(STATUS "OpenCV include dirs: ${OpenCV_INCLUDE_DIRS}")
message(STATUS "OpenCV libraries: ${OpenCV_LIBS}")
```

变量名并不是 CMake 根据包名统一生成的公共 API。例如常见 OpenCV 配置使用 `OpenCV_INCLUDE_DIRS` 和 `OpenCV_LIBS`，其他包可能采用完全不同的大小写与命名。应以对应版本的包文档和配置输出为准，不能把某个包的变量约定套到另一个包上。

==== Config 模式与 Module 模式

`find_package` 有两种工作模式：Config 模式和 Module 模式。理解它们的区别有助于排查找不到库的问题。

*Module 模式*使用 CMake 自带或项目放入 `CMAKE_MODULE_PATH` 的 `Find<Package>.cmake`。CMake 随附了 `FindThreads.cmake`、`FindOpenGL.cmake` 等模块；第三方项目也可以提供自己的 Find 模块。

```cmake
# CMake 自带的 Find 模块
find_package(Threads REQUIRED)   # 使用 FindThreads.cmake
find_package(OpenGL REQUIRED)    # 使用 FindOpenGL.cmake
```

Module 模式的查找逻辑由该模块的作者决定，可能调用 `find_path`、`find_library` 或 pkg-config，并按约定设置结果变量和导入目标。

*Config 模式*查找包安装时提供的 `<Package>Config.cmake` 或 `<package>-config.cmake`。这类文件通常由库项目生成并随开发文件安装：

```cmake
# 使用库提供的 Config 文件
find_package(OpenCV CONFIG REQUIRED)  # 使用 OpenCVConfig.cmake
find_package(Eigen3 CONFIG REQUIRED)  # 使用 Eigen3Config.cmake
find_package(Ceres CONFIG REQUIRED)   # 使用 CeresConfig.cmake
```

Config 文件更接近包自身的构建与安装信息，并且常常提供导入目标。不过，它仍可能因打包错误、绝对路径、缺少传递依赖或工具链不匹配而失效，不能仅凭“由作者提供”就认定可靠。

对 `find_package(Name ...)` 的基础签名，CMake 默认先尝试 Module 模式，找不到 Find 模块后再进入 Config 模式；设置 `CMAKE_FIND_PACKAGE_PREFER_CONFIG=TRUE` 可以把两者顺序反过来。`CONFIG`（或 `NO_MODULE`）与 `MODULE` 关键字可明确限定模式：

```cmake
# 强制使用 Config 模式
find_package(OpenCV CONFIG REQUIRED)

# 强制使用 Module 模式
find_package(OpenGL MODULE REQUIRED)
```

包安装在非默认前缀时，可以从命令行、preset 或工具链文件补充 `CMAKE_PREFIX_PATH`：

```bash
# 命令行指定额外的搜索路径
cmake -S . -B build \
      -DCMAKE_PREFIX_PATH="/opt/opencv;/opt/eigen"
```

```cmake
# 项目确有固定私有前缀时也能追加，但不要覆盖调用者已有的值
list(PREPEND CMAKE_PREFIX_PATH "${CMAKE_CURRENT_SOURCE_DIR}/third_party/prefix")
find_package(MyPrivatePackage CONFIG REQUIRED)
```

对于 Config 模式，也可以设置 `XXX_DIR` 变量指向 Config 文件所在目录：

```bash
cmake -S . -B build \
      -DOpenCV_DIR=/opt/opencv/lib/cmake/opencv4
```

`CMAKE_PREFIX_PATH` 接收安装前缀，CMake 会在其下组合 `lib/cmake`、`share` 等候选位置；`OpenCV_DIR` 则应直接指向包含 OpenCV 配置文件的目录。若路径来自交叉编译 SDK，还要配合工具链中的 sysroot 和 `CMAKE_FIND_ROOT_PATH_MODE_*`，避免误找到构建主机的库。

==== 导入目标：现代方式

一些查找脚本通过变量返回头文件与库列表，使用者需要分别接入目标：

```cmake
# 变量接口：这是常见 OpenCV 包配置提供的方式
find_package(OpenCV REQUIRED COMPONENTS core imgproc)

add_executable(my_app main.cpp)
target_include_directories(my_app PRIVATE ${OpenCV_INCLUDE_DIRS})
target_link_libraries(my_app PRIVATE ${OpenCV_LIBS})
```

许多包则创建导入目标（imported target）。导入目标不由当前项目编译，而是描述已存在的库或 header-only 接口及其使用要求：

```cmake
# Eigen 的常见 Config 包提供 Eigen3::Eigen
find_package(Eigen3 REQUIRED)

add_executable(my_app main.cpp)
target_link_libraries(my_app PRIVATE Eigen3::Eigen)
```

只要包正确声明了接口，链接导入目标就能同时获得其头文件路径、编译定义、编译特性和传递链接项。这里的“链接”也适用于 header-only 目标，并不表示一定会向链接器传入库文件。

`Package::Target` 是常见命名习惯，却不是 CMake 根据包名自动生成的规则。目标名必须查阅包文档或配置文件。例如 `Eigen3::Eigen`、`Ceres::ceres` 和 `Threads::Threads` 很常见，而许多 OpenCV 安装提供的是 `OpenCV_LIBS` 变量以及 `opencv_core`、`opencv_imgproc` 等具体项，并不提供 `OpenCV::OpenCV` 或 `OpenCV::core`。

若希望项目内部统一使用一个目标，可以在查找 OpenCV 后封装其公开变量：

```cmake
find_package(OpenCV REQUIRED COMPONENTS core imgproc highgui calib3d dnn)

add_library(rm_opencv INTERFACE)
target_include_directories(rm_opencv SYSTEM INTERFACE
    ${OpenCV_INCLUDE_DIRS}
)
target_link_libraries(rm_opencv INTERFACE ${OpenCV_LIBS})

target_link_libraries(my_app PRIVATE rm_opencv)
```

`rm_opencv` 是当前项目创建的接口目标，不是 OpenCV 官方导入目标；它只是把这个 OpenCV 包实际提供的变量集中到一处。真正的包导入目标还能区分平台、构建配置和传递依赖，但准确程度仍取决于包的元数据。目标名写错时，含 `::` 的名字通常会在生成阶段触发明确错误；未定义变量往往只展开为空，因此变量接口更需要主动检查查找结果。

可以用 `if(TARGET ...)` 检查导入目标是否存在：

```cmake
find_package(Eigen3 QUIET)

if(TARGET Eigen3::Eigen)
    message(STATUS "Eigen3 imported target available")
    target_link_libraries(my_app PRIVATE Eigen3::Eigen)
else()
    message(STATUS "A usable Eigen3::Eigen target was not found")
endif()
```

==== 常用库的查找

让我们看看 RoboMaster 开发中常用库的查找方式。

*OpenCV* 可以按组件请求，以减少不必要的依赖；实际返回的 `OpenCV_LIBS` 应以安装包为准：

```cmake
find_package(OpenCV REQUIRED COMPONENTS core imgproc)

# 查看版本
message(STATUS "OpenCV version: ${OpenCV_VERSION}")

# 封装变量接口，供项目内目标复用
add_library(rm_opencv INTERFACE)
target_include_directories(rm_opencv SYSTEM INTERFACE
    ${OpenCV_INCLUDE_DIRS}
)
target_link_libraries(rm_opencv INTERFACE ${OpenCV_LIBS})

target_link_libraries(my_app PRIVATE rm_opencv)
```

*Eigen* 是 header-only 的线性代数库：

```cmake
find_package(Eigen3 REQUIRED)

# Eigen 是 header-only，只需要 include 路径
target_link_libraries(my_app PRIVATE Eigen3::Eigen)
```

注意包名是 `Eigen3` 不是 `Eigen`。由于 Eigen 是 header-only 的，“链接”它实际上只是添加 include 路径和编译选项，不会有实际的库文件被链接。

*Ceres Solver* 是非线性优化库：

```cmake
find_package(Ceres REQUIRED)

target_link_libraries(my_app PRIVATE Ceres::ceres)
```

常见的 Ceres Config 包通过该目标声明 Eigen 等使用要求。若所安装的旧版本只提供变量，应按其文档适配；不能在 `Ceres_FOUND` 为真时假定任何目标名都存在。

*Threads* 表示当前平台的线程支持要求：

```cmake
find_package(Threads REQUIRED)

target_link_libraries(my_app PRIVATE Threads::Threads)
```

`Threads::Threads` 可能携带线程库、编译/链接标志，也可能在无需额外参数的平台上为空。它避免把 `-pthread` 或 `pthread` 这样的工具链细节硬编码到项目中；它并不封装 `std::thread` 之外的一套 Windows API。

*Google Test* 是单元测试框架：

```cmake
find_package(GTest REQUIRED)

add_executable(my_tests test_main.cpp)
target_link_libraries(my_tests PRIVATE GTest::gtest_main)

# 使用 gMock，并采用它提供的 main 函数
add_executable(my_mock_tests mock_test.cpp)
target_link_libraries(my_mock_tests PRIVATE GTest::gmock_main)
```

`GTest::gtest_main` 通常已经通过接口依赖 `GTest::gtest`，`GTest::gmock_main` 也会带上所需的 gMock/GTest 目标。若测试源码自己定义 `main`，则改为链接 `GTest::gtest` 或 `GTest::gmock`。

*Boost* 是一个大型的 C++ 库集合：

```cmake
find_package(Boost REQUIRED COMPONENTS filesystem system)

target_link_libraries(my_app PRIVATE
    Boost::filesystem
    Boost::system
)

# header-only 部分没有库文件，但仍通过目标获得头文件要求
target_link_libraries(my_app PRIVATE Boost::headers)
```

较旧的 FindBoost 版本可能只提供 `Boost::boost` 作为 header-only 目标名；应让项目的 CMake 最低版本与所采用的接口一致。

*fmt* 是现代的格式化库：

```cmake
find_package(fmt REQUIRED)

target_link_libraries(my_app PRIVATE fmt::fmt)

# 包提供的 header-only 接口
target_link_libraries(my_app PRIVATE fmt::fmt-header-only)
```

*spdlog* 是高性能日志库：

```cmake
find_package(spdlog REQUIRED)

target_link_libraries(my_app PRIVATE spdlog::spdlog)
```

fmt 和 spdlog 也可能提供 header-only 目标或采用外部 fmt 的构建选项。目标名和二进制兼容条件随包版本与打包方式变化，混用系统包和自行构建版本前应检查它们是否采用一致的 fmt 配置。

==== pkg-config：查找没有 CMake 支持的库

有些库没有 CMake 包配置，但安装了 pkg-config 的 `.pc` 元数据。CMake 的 `FindPkgConfig` 模块可以读取这些信息：

```cmake
find_package(PkgConfig REQUIRED)

# CMake 3.6+ 可直接创建导入目标
pkg_check_modules(LIBUSB REQUIRED IMPORTED_TARGET libusb-1.0)
target_link_libraries(my_app PRIVATE PkgConfig::LIBUSB)
```

`pkg_check_modules` 会设置以下变量：

- `<PREFIX>_FOUND`：是否找到
- `<PREFIX>_INCLUDE_DIRS`：头文件目录
- `<PREFIX>_LIBRARIES`：库名列表
- `<PREFIX>_LINK_LIBRARIES`：尽可能解析后的链接项（CMake 3.12+）
- `<PREFIX>_LIBRARY_DIRS`：库文件目录
- `<PREFIX>_CFLAGS_OTHER`：未归入头文件路径的编译标志
- `<PREFIX>_LDFLAGS_OTHER`：未归入库与库目录的链接标志

使用 `IMPORTED_TARGET` 时，`PkgConfig::<PREFIX>` 会集中携带 pkg-config 返回的使用要求，通常比手工挑选若干变量完整。它的准确性仍受 `.pc` 文件约束：静态链接可能需要 `Libs.private`/`Requires.private`，交叉编译还必须配置目标 sysroot 对应的 `PKG_CONFIG_LIBDIR`，否则可能误用构建主机的库。可以用 `pkg-config --cflags --libs libusb-1.0` 辅助核对当前环境的原始结果。

==== FetchContent：下载并构建依赖

`FetchContent` 可以在配置阶段取得依赖源码，并通常把它作为子目录加入同一个构建。它适合项目愿意连同依赖一起配置的场景，但也会把网络、依赖选项和依赖自身的 CMake 逻辑带入主项目配置。

```cmake
include(FetchContent)

# 声明依赖
FetchContent_Declare(
    json
    GIT_REPOSITORY https://github.com/nlohmann/json.git
    GIT_TAG v3.11.2  # 示例使用发布标签
)

# 下载并添加到构建
FetchContent_MakeAvailable(json)

# 使用
target_link_libraries(my_app PRIVATE nlohmann_json::nlohmann_json)
```

`FetchContent_Declare` 可以描述 Git 仓库、压缩包 URL 或本地源码目录：

```cmake
# 从 Git 仓库
FetchContent_Declare(
    fmt
    GIT_REPOSITORY https://github.com/fmtlib/fmt.git
    GIT_TAG 10.1.1
)

# 从 URL 下载压缩包
# 下面的摘要是占位符，使用前必须替换为可信来源公布或自行核验的值
FetchContent_Declare(
    googletest
    URL https://github.com/google/googletest/archive/release-1.12.1.tar.gz
    URL_HASH SHA256=<replace-with-verified-digest>
)

# 从本地目录（用于开发）
FetchContent_Declare(
    mylib
    SOURCE_DIR "/path/to/local/mylib"  # 替换为实际检出目录
)
```

在常见的 CMake 依赖中，`FetchContent_MakeAvailable` 会先填充源码，再通过 `add_subdirectory` 处理依赖，使它定义的目标可供当前构建使用。较新 CMake 还支持依赖提供者和先尝试 `find_package` 等路径，因此具体行为与 CMake 版本及声明选项有关。无论哪种路径，都应在调用后检查需要的目标是否存在。

可以一次处理多个依赖：

```cmake
include(FetchContent)

FetchContent_Declare(
    fmt
    GIT_REPOSITORY https://github.com/fmtlib/fmt.git
    GIT_TAG 10.1.1
)

FetchContent_Declare(
    spdlog
    GIT_REPOSITORY https://github.com/gabime/spdlog.git
    GIT_TAG v1.12.0
)

FetchContent_Declare(
    json
    GIT_REPOSITORY https://github.com/nlohmann/json.git
    GIT_TAG v3.11.2
)

# 让 spdlog 使用已经声明的外部 fmt，避免同时引入另一份 bundled fmt
set(SPDLOG_FMT_EXTERNAL ON CACHE BOOL "Use external fmt in spdlog")

# 依次确保这些依赖可用
FetchContent_MakeAvailable(fmt spdlog json)

# 使用
target_link_libraries(my_app PRIVATE
    fmt::fmt
    spdlog::spdlog
    nlohmann_json::nlohmann_json
)
```

有时候需要在 `MakeAvailable` 之前设置一些选项来控制依赖的构建：

```cmake
FetchContent_Declare(
    googletest
    GIT_REPOSITORY https://github.com/google/googletest.git
    GIT_TAG v1.14.0
)

# 依赖项目读取同一个 CMake 缓存；不要无条件覆盖调用者已有选择
set(BUILD_GMOCK OFF CACHE BOOL "Build GoogleMock")
set(INSTALL_GTEST OFF CACHE BOOL "Install GoogleTest")

FetchContent_MakeAvailable(googletest)
```

第一次填充通常需要网络，后续配置是否访问远端取决于下载方法、更新策略和已有源码状态。发布标签便于阅读，但 Git 标签可能被上游移动；要求严格复现时应记录核验过的完整提交哈希，或使用带可信 `URL_HASH` 的归档，并考虑内部镜像或预填充源码。离线构建不能只寄希望于本机恰好留有 `_deps` 缓存，应把依赖来源、锁定版本和离线供应方式纳入项目流程。

依赖通过 `add_subdirectory` 进入同一个缓存与目标命名空间，选项重名和全局设置也可能相互影响。上例去掉了 `FORCE`，以免静默覆盖用户或父项目已有的缓存值；但这也意味着旧构建目录中的值会继续保留，需要在配置输出或 preset 中明确记录。大型依赖、特殊工具链或需要与主项目隔离的构建更适合预安装包、包管理器或下一节的 superbuild 方式。

==== ExternalProject：更复杂的外部项目

`ExternalProject` 把另一个项目的下载、配置、构建和安装组织成当前构建中的步骤。外部项目可以使用 CMake，也可以通过自定义命令接入其他构建系统：

```cmake
include(ExternalProject)

ExternalProject_Add(
    external_opencv
    GIT_REPOSITORY https://github.com/opencv/opencv.git
    GIT_TAG 4.8.0
    INSTALL_DIR "${CMAKE_BINARY_DIR}/opencv_install"
    CMAKE_ARGS
        "-DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>"
        -DBUILD_EXAMPLES=OFF
        -DBUILD_TESTS=OFF
        -DBUILD_DOCS=OFF
)
```

与常见的 `FetchContent_MakeAvailable` 不同，`ExternalProject_Add` 在当前配置阶段只创建驱动外部步骤的目标；OpenCV 自己的 CMake 目标不会出现在主项目中。主项目若在同一次配置时直接创建一个接口目标并填写未来才会产生的头文件、库目录和裸库名，很容易遗漏多配置文件名、传递库和运行时路径。

一种边界更清楚的做法是使用单独的 superbuild：外层先构建并安装依赖，再配置真正的应用项目。下面的 `superbuild/CMakeLists.txt` 假设应用源码位于相邻的 `rm_vision/`：

```cmake
cmake_minimum_required(VERSION 3.20)
project(rm_vision_superbuild LANGUAGES NONE)
include(ExternalProject)

ExternalProject_Add(
    external_opencv
    GIT_REPOSITORY https://github.com/opencv/opencv.git
    GIT_TAG 4.8.0
    CMAKE_ARGS
        "-DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>"
        -DBUILD_EXAMPLES=OFF
        -DBUILD_TESTS=OFF
    INSTALL_DIR "${CMAKE_BINARY_DIR}/opencv_install"
)

# 取得将来安装 OpenCV 的已知前缀
ExternalProject_Get_Property(external_opencv INSTALL_DIR)
set(opencv_install_prefix "${INSTALL_DIR}")

# OpenCV 安装完成后，再配置应用；应用内部照常 find_package(OpenCV)
ExternalProject_Add(
    rm_vision_external
    SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}/../rm_vision"
    BINARY_DIR "${CMAKE_BINARY_DIR}/rm_vision-build"
    DEPENDS external_opencv
    CMAKE_ARGS
        "-DCMAKE_PREFIX_PATH=${opencv_install_prefix}"
    INSTALL_COMMAND ""
)
```

应用项目仍通过 OpenCV 安装的 Config 文件获取准确目标或变量，而不是在 superbuild 中猜测库清单。实际项目还要把生成器、工具链文件、目标架构和必要的配置选项一致地传给两个外部项目；`DEPENDS` 只建立步骤顺序，不会自动保证 ABI 一致。

`ExternalProject` 常用于以下场景：

- 需要从源码编译大型依赖（如 OpenCV、PCL）
- 依赖使用非 CMake 构建系统
- 需要对依赖进行补丁或自定义配置
- 超级构建（superbuild）模式

若依赖已经由系统包、包管理器或预构建前缀提供，`find_package` 通常更直接；若依赖需要与主项目共享一次配置，`FetchContent` 可能更合适；需要构建隔离或不同构建系统时，再考虑 `ExternalProject`/superbuild。选择依据是生命周期与隔离需求，不是固定的优先级口诀。

==== 系统库 vs 本地库

项目可能从操作系统包、团队维护的前缀或随源码取得的依赖中选择。它们在更新节奏、编译选项、补丁和 ABI 上都可能不同，不能简单把“系统库”视为更稳定，也不能把“源码获取”视为必然更新或兼容。

```cmake
# 先按当前搜索前缀查找，找不到时使用 FetchContent
find_package(spdlog QUIET CONFIG)

if(NOT TARGET spdlog::spdlog)
    message(STATUS "spdlog not found, fetching from GitHub")
    include(FetchContent)
    FetchContent_Declare(
        spdlog
        GIT_REPOSITORY https://github.com/gabime/spdlog.git
        GIT_TAG v1.12.0
    )
    FetchContent_MakeAvailable(spdlog)
endif()

if(NOT TARGET spdlog::spdlog)
    message(FATAL_ERROR "No usable spdlog::spdlog target was provided")
endif()
target_link_libraries(my_app PRIVATE spdlog::spdlog)
```

可以用选项让用户选择：

```cmake
option(RM_USE_SYSTEM_SPDLOG "Require an installed spdlog package" ON)

if(RM_USE_SYSTEM_SPDLOG)
    find_package(spdlog CONFIG REQUIRED)
else()
    include(FetchContent)
    FetchContent_Declare(
        spdlog
        GIT_REPOSITORY https://github.com/gabime/spdlog.git
        GIT_TAG v1.12.0
    )
    FetchContent_MakeAvailable(spdlog)
endif()

if(NOT TARGET spdlog::spdlog)
    message(FATAL_ERROR "The selected spdlog source did not provide spdlog::spdlog")
endif()
target_link_libraries(my_app PRIVATE spdlog::spdlog)
```

对于安装在非标准位置的库，通过 `CMAKE_PREFIX_PATH` 指定：

```bash
# 使用本地编译的 OpenCV
cmake -S . -B build \
      -DCMAKE_PREFIX_PATH=/home/user/opencv_build/install
```

无论采用自动回退还是显式选项，都应记录最终解析到的版本和来源。自动回退使用方便，却可能让两台机器在同一配置命令下选择不同实现；要求可复现时，preset、锁定文件、容器或包管理器配置应明确这一决策。

==== 编写 Find 模块

若库没有可用的 Config 文件或 pkg-config 元数据，可以编写 Find 模块。下面的最小示例让 CMake 先遵循自身的前缀、sysroot 和工具链搜索规则，同时把 `MYLIB_ROOT` 环境变量作为额外提示：

```cmake
# cmake/FindMyLib.cmake

# 搜索头文件
find_path(MYLIB_INCLUDE_DIR
    NAMES mylib.h
    HINTS "$ENV{MYLIB_ROOT}"
    PATH_SUFFIXES include
)

# 搜索库文件
find_library(MYLIB_LIBRARY
    NAMES mylib
    HINTS "$ENV{MYLIB_ROOT}"
    PATH_SUFFIXES lib lib64
)

# 标准处理
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(MyLib
    REQUIRED_VARS MYLIB_LIBRARY MYLIB_INCLUDE_DIR
)

# 创建导入目标
if(MyLib_FOUND AND NOT TARGET MyLib::MyLib)
    add_library(MyLib::MyLib UNKNOWN IMPORTED)
    set_target_properties(MyLib::MyLib PROPERTIES
        IMPORTED_LOCATION "${MYLIB_LIBRARY}"
        INTERFACE_INCLUDE_DIRECTORIES "${MYLIB_INCLUDE_DIR}"
    )
endif()

# 在常规 GUI 视图中隐藏底层缓存项，高级排查时仍可查看和覆盖
mark_as_advanced(MYLIB_INCLUDE_DIR MYLIB_LIBRARY)
```

使用这个 Find 模块：

```cmake
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
find_package(MyLib REQUIRED)
target_link_libraries(my_app PRIVATE MyLib::MyLib)
```

不要在 Find 模块中无条件写死 `/usr/lib` 等主机路径；交叉编译时这可能绕过目标 sysroot。真实库还可能分别提供 Debug/Release 文件、额外系统库、编译定义和版本头文件，这些都要进入导入目标接口。这个示例只能确认一个头文件和一个库文件被找到，不能据此确认二者版本一致或 ABI 与当前工具链兼容；需要时应增加版本提取、试编译或供应商规定的检查。

==== 完整示例

下面把前述方法组合成一个项目入口。示例选择“系统或指定前缀中的 OpenCV/Eigen/Threads 必须存在，小型库可由用户明确允许后获取，Ceres 与 CUDA 后端可选”的策略。项目应根据自己的部署方式调整，而不是直接照搬依赖清单。

```cmake
cmake_minimum_required(VERSION 3.20)
project(rm_vision VERSION 2.0.0 LANGUAGES CXX)

# 添加自定义 Find 模块路径
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
include(CTest)
include(FetchContent)

option(RM_FETCH_MISSING_DEPS
    "Fetch selected small dependencies when no installed package is found" OFF)
option(RM_ENABLE_CUDA_RUNTIME "Enable the CUDA runtime backend" OFF)

#=============================================================================
# 必需依赖
#=============================================================================

# OpenCV：图像处理
find_package(OpenCV 4.5 REQUIRED COMPONENTS
    core imgproc imgcodecs videoio calib3d
)

# 常见 OpenCV 包公开变量而非 OpenCV::OpenCV，先封装为项目内目标
add_library(rm_opencv INTERFACE)
target_include_directories(rm_opencv SYSTEM INTERFACE
    ${OpenCV_INCLUDE_DIRS}
)
target_link_libraries(rm_opencv INTERFACE ${OpenCV_LIBS})

# Eigen：线性代数
find_package(Eigen3 3.3 REQUIRED)

# Threads：多线程
find_package(Threads REQUIRED)

#=============================================================================
# 可选依赖
#=============================================================================

# Ceres：非线性优化后端（可选）
find_package(Ceres QUIET CONFIG)
if(TARGET Ceres::ceres)
    set(RM_HAS_CERES 1)
    message(STATUS "Ceres backend: enabled")
else()
    set(RM_HAS_CERES 0)
    message(STATUS "Ceres backend: disabled")
endif()

# CUDA Toolkit：只有显式启用时才成为必需依赖
if(RM_ENABLE_CUDA_RUNTIME)
    find_package(CUDAToolkit REQUIRED)
endif()

#=============================================================================
# 小型依赖：先查已安装包，按选项决定是否获取源码
#=============================================================================

# fmt：格式化库
find_package(fmt QUIET CONFIG)
if(NOT TARGET fmt::fmt AND RM_FETCH_MISSING_DEPS)
    FetchContent_Declare(
        fmt
        GIT_REPOSITORY https://github.com/fmtlib/fmt.git
        GIT_TAG 10.1.1
    )
    FetchContent_MakeAvailable(fmt)
endif()
if(NOT TARGET fmt::fmt)
    message(FATAL_ERROR
        "fmt::fmt not found; install fmt or set RM_FETCH_MISSING_DEPS=ON")
endif()

# spdlog：日志库
find_package(spdlog QUIET CONFIG)
if(NOT TARGET spdlog::spdlog AND RM_FETCH_MISSING_DEPS)
    # 让源码获取的 spdlog 复用上面已经确定的 fmt 目标。
    set(SPDLOG_FMT_EXTERNAL ON CACHE BOOL "Use external fmt in spdlog")
    if(NOT SPDLOG_FMT_EXTERNAL)
        message(FATAL_ERROR
            "Fetched spdlog must use external fmt in this dependency setup")
    endif()
    FetchContent_Declare(
        spdlog
        GIT_REPOSITORY https://github.com/gabime/spdlog.git
        GIT_TAG v1.12.0
    )
    FetchContent_MakeAvailable(spdlog)
endif()
if(NOT TARGET spdlog::spdlog)
    message(FATAL_ERROR
        "spdlog::spdlog not found; install spdlog or enable dependency fetching")
endif()

# nlohmann/json：JSON 解析
find_package(nlohmann_json QUIET CONFIG)
if(NOT TARGET nlohmann_json::nlohmann_json AND RM_FETCH_MISSING_DEPS)
    FetchContent_Declare(
        json
        GIT_REPOSITORY https://github.com/nlohmann/json.git
        GIT_TAG v3.11.2
    )
    FetchContent_MakeAvailable(json)
endif()
if(NOT TARGET nlohmann_json::nlohmann_json)
    message(FATAL_ERROR
        "nlohmann_json target not found; install it or enable dependency fetching")
endif()

#=============================================================================
# 测试依赖
#=============================================================================

if(BUILD_TESTING)
    find_package(GTest QUIET)
    if(NOT TARGET GTest::gtest_main AND RM_FETCH_MISSING_DEPS)
        FetchContent_Declare(
            googletest
            GIT_REPOSITORY https://github.com/google/googletest.git
            GIT_TAG v1.14.0
        )
        FetchContent_MakeAvailable(googletest)
    endif()
    if(NOT TARGET GTest::gtest_main)
        message(FATAL_ERROR
            "GTest is required when BUILD_TESTING=ON")
    endif()
endif()

#=============================================================================
# 定义目标
#=============================================================================

add_library(rm_core
    src/config.cpp
    src/logger.cpp
)

target_include_directories(rm_core PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

target_compile_features(rm_core PUBLIC cxx_std_17)

target_link_libraries(rm_core
    PUBLIC
        Eigen3::Eigen
        nlohmann_json::nlohmann_json
    PRIVATE
        rm_opencv
        fmt::fmt
        spdlog::spdlog
        Threads::Threads
)

# 可选后端只影响实现，因此宏和依赖保持 PRIVATE
target_compile_definitions(rm_core PRIVATE RM_HAS_CERES=${RM_HAS_CERES})
if(TARGET Ceres::ceres)
    target_link_libraries(rm_core PRIVATE Ceres::ceres)
endif()

if(RM_ENABLE_CUDA_RUNTIME)
    target_compile_definitions(rm_core PRIVATE RM_HAS_CUDA_RUNTIME=1)
    target_link_libraries(rm_core PRIVATE CUDA::cudart)
else()
    target_compile_definitions(rm_core PRIVATE RM_HAS_CUDA_RUNTIME=0)
endif()

add_subdirectory(apps)

if(BUILD_TESTING)
    add_subdirectory(tests)
endif()
```

这个入口明确区分了三种情况：OpenCV 等基础依赖缺失时立即停止；Ceres 没有可用目标时关闭对应实现；fmt 等小型依赖只有在用户允许后才于配置阶段获取。`PUBLIC` 列表假设 `rm_core` 的公共头文件确实出现 Eigen 和 nlohmann/json 类型，fmt、spdlog、OpenCV 和线程只在 `.cpp` 中使用；如果实际 API 不同，可见性也要随之调整。

示例中的发布标签便于阅读，但严格复现仍应换成核验过的完整提交哈希或带摘要的归档。它也没有证明这些版本彼此 ABI 兼容，更没有覆盖代理、离线镜像、交叉编译和许可证要求。依赖管理的可观察结果应包括：配置最终选择了哪个来源与版本、生成目标携带了哪些使用要求，以及支持环境中能否完成实际编译、链接和测试。


=== 安装与导出
// 让别人能使用你的库
// - install 命令：安装文件到系统
// - 安装目标：TARGETS
// - 安装头文件：FILES/DIRECTORY
// - 安装位置：CMAKE_INSTALL_PREFIX
// - 导出目标：让其他项目能 find_package
// - 生成 Config.cmake 文件
// - 版本兼容性
// - CPack：打包与分发
// === 安装与导出

前面的目标都在当前构建树中使用。若一个库还要放入独立前缀、交给其他项目通过 `find_package` 查找，或进一步制作系统安装包，就要同时定义产物、公共头文件和 CMake 包元数据的安装规则。本节从普通安装讲到目标导出、版本文件与 CPack，并说明这些步骤各自能保证什么。

==== 为什么需要安装

开发阶段可以直接运行构建树中的程序，也可以通过 `add_subdirectory` 或显式的构建树包配置复用库。不过，构建树往往包含生成器细节、临时文件和开发机器路径，不适合作为长期分发接口。

安装规则把选定的可执行文件、库、头文件和元数据放入一个前缀下，并明确哪些文件属于运行时、开发或数据资源。安装前缀可以供其他项目查找，也可以作为打包的暂存树。能成功复制文件并不等于包已经可重定位或运行时依赖完整，后文还会分别检查这些条件。

标准的 Unix 安装目录结构通常是：

```
/usr/local/                    # 或其他 CMAKE_INSTALL_PREFIX
├── bin/                       # 可执行文件
├── lib/                       # 库文件
│   └── cmake/                 # CMake 配置文件
│       └── MyLib/
│           ├── MyLibConfig.cmake
│           └── MyLibTargets.cmake
├── include/                   # 头文件
│   └── mylib/
│       └── mylib.h
└── share/                     # 其他资源
    └── mylib/
        └── data/
```

==== install 命令基础

CMake 的 `install` 命令用于指定安装规则。最基本的用法是安装目标（可执行文件和库）：

```cmake
add_library(mylib src/mylib.cpp)
add_executable(myapp src/main.cpp)

# 安装库
install(TARGETS mylib
    LIBRARY DESTINATION lib        # 共享库 (.so)
    ARCHIVE DESTINATION lib        # 静态库 (.a)
    RUNTIME DESTINATION bin        # 可执行文件和 DLL
)

# 安装可执行文件
install(TARGETS myapp
    RUNTIME DESTINATION bin
)
```

相对的 `DESTINATION` 会拼到 `CMAKE_INSTALL_PREFIX` 下，也更适合 `cmake --install --prefix` 和打包工具调整前缀。默认前缀由平台与 CMake 配置决定；Unix 主机上常见 `/usr/local`，但项目不应依赖某个写死的默认值。

运行安装：

```bash
# 单配置生成器：配置并构建 Release
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build

# 安装到用户可写的独立前缀
cmake --install build --prefix "$PWD/stage"

# 多配置生成器还要选择本次安装的配置
cmake --install build --config Release --prefix "$PWD/stage"
```

也可以在配置时指定安装前缀：

```bash
cmake -S . -B build -DCMAKE_INSTALL_PREFIX=/opt/myproject
cmake --build build
cmake --install build
```

安装到 `/usr`、`/opt` 等受保护前缀可能需要管理员权限，但应先在用户可写的暂存前缀检查文件清单，不要把 `sudo` 作为日常构建命令的一部分。`--prefix` 能在安装时改写相对目的地；写成绝对路径的安装规则不随它移动，因此可安装项目通常保持 `DESTINATION` 为相对路径。打包流程还常用 `DESTDIR` 额外加一层暂存根目录。

==== 使用 GNUInstallDirs

不同平台、发行版和工具链对 `lib`、`lib64`、数据与配置目录的约定可能不同。`GNUInstallDirs` 提供一组可由调用者覆盖的相对目录变量：

```cmake
include(GNUInstallDirs)

install(TARGETS mylib
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

install(DIRECTORY include/
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)
```

`GNUInstallDirs` 定义了以下变量：

- `CMAKE_INSTALL_BINDIR`：可执行文件（通常是 `bin`）
- `CMAKE_INSTALL_LIBDIR`：库文件（`lib` 或 `lib64`）
- `CMAKE_INSTALL_INCLUDEDIR`：头文件（`include`）
- `CMAKE_INSTALL_DATADIR`：数据文件（`share`）
- `CMAKE_INSTALL_SYSCONFDIR`：主机配置文件（通常是 `etc`）
- `CMAKE_INSTALL_DOCDIR`：文档（`share/doc/${PROJECT_NAME}`）

使用这些变量能减少硬编码，并让发行版打包者通过缓存覆盖目录。它不会自动判断每个文件应归入哪个组件，也不会让依赖路径自动可重定位；这些仍由项目的安装和导出规则决定。

==== 安装头文件

头文件可以按目录、按文件或按目标的头文件集安装。目录方式适合已经把公共头文件与内部文件分开的项目：

```cmake
# 安装 include 目录下的所有文件
install(DIRECTORY include/
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)
```

`include/` 末尾的斜杠表示复制该目录的内容；写成 `include` 则连目录名一起放到目的地下。实际安装前可用暂存前缀检查层级，避免意外得到 `include/include/...`。

可以用模式过滤：

```cmake
# 只安装 .h 和 .hpp 文件
install(DIRECTORY include/
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    FILES_MATCHING
        PATTERN "*.h"
        PATTERN "*.hpp"
)

# 排除某些文件
install(DIRECTORY include/
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    PATTERN "internal" EXCLUDE    # 排除 internal 目录
    PATTERN "*.in" EXCLUDE        # 排除 .in 文件
)
```

安装单个文件：

```cmake
# 安装特定文件
install(FILES
    include/mylib/core.h
    include/mylib/utils.h
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/mylib
)
```

对于生成的头文件（如配置头文件），需要从构建目录安装：

```cmake
# 从模板生成配置头文件
configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/include/mylib/config.h.in"
    "${CMAKE_CURRENT_BINARY_DIR}/include/mylib/config.h"
    @ONLY
)

# 安装生成的头文件
install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/include/mylib/config.h"
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/mylib
)
```

CMake 3.23 及以后还可以用 `target_sources(... FILE_SET HEADERS ...)` 记录公共头文件，并在 `install(TARGETS ... FILE_SET HEADERS ...)` 中安装。它能把头文件归属与目标放在一起，但采用前要相应提高 `cmake_minimum_required`；目录过滤和头文件集二选一即可，不必重复安装同一文件。

==== 安装其他文件

除了目标和头文件，你可能还需要安装其他文件：

```cmake
# 安装数据文件
install(DIRECTORY data/
    DESTINATION ${CMAKE_INSTALL_DATADIR}/${PROJECT_NAME}
)

# 安装项目提供的默认配置；运行时可写配置通常不应直接覆盖
install(FILES config/default.yaml
    DESTINATION ${CMAKE_INSTALL_SYSCONFDIR}/${PROJECT_NAME}
)

# 安装文档
install(FILES README.md LICENSE
    DESTINATION ${CMAKE_INSTALL_DOCDIR}
)

# 安装脚本（保留执行权限）
install(PROGRAMS scripts/run.sh
    DESTINATION ${CMAKE_INSTALL_BINDIR}
)
```

==== 导出目标

库文件与头文件到位后，使用者仍需要知道目标名、每种配置对应的产物位置以及公共使用要求。导出集用于把这些 CMake 目标信息写成可加载的导入目标定义。

首先，在安装目标时添加 `EXPORT` 选项：

```cmake
install(TARGETS mylib
    EXPORT MyLibTargets           # 导出到 MyLibTargets
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)
```

`EXPORT MyLibTargets` 把目标加入名为 `MyLibTargets` 的导出集。`INCLUDES DESTINATION` 会把安装后的公共头文件目录加入导出接口；若目标已经使用 `$<INSTALL_INTERFACE:...>` 声明了同一路径，应避免重复或不一致。目的地应保持为相对安装前缀的路径，不能把开发机的源码目录写进安装接口。

然后，安装导出集：

```cmake
install(EXPORT MyLibTargets
    FILE MyLibTargets.cmake
    NAMESPACE MyLib::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/MyLib
)
```

安装时会生成 `MyLibTargets.cmake` 及按配置拆分的辅助文件。`NAMESPACE MyLib::` 为导入目标加前缀，因此使用者写 `MyLib::mylib`。导出只序列化目标与接口，不会自动查找 Eigen、Threads 等外部目标；包入口还要在加载导出文件前恢复这些依赖。

==== 生成 Config 文件

`find_package(MyLib CONFIG)` 通常先加载 `MyLibConfig.cmake`，再由它查找依赖并包含 `MyLibTargets.cmake`。因此还需要一个包入口模板：

最小模板如下：

```cmake
# MyLibConfig.cmake.in
@PACKAGE_INIT@

include("${CMAKE_CURRENT_LIST_DIR}/MyLibTargets.cmake")

check_required_components(MyLib)
```

然后用 `configure_package_config_file` 生成：

```cmake
include(CMakePackageConfigHelpers)

configure_package_config_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake/MyLibConfig.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/MyLibConfig.cmake
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/MyLib
)

install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/MyLibConfig.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/MyLib
)
```

`@PACKAGE_INIT@` 会展开为用于计算包前缀和辅助宏的代码。`check_required_components(MyLib)` 会检查调用者请求的组件是否有对应的 `MyLib_<component>_FOUND` 值；没有组件的简单包可以保留它，但多组件包仍要在 Config 文件中正确设置各组件状态。

若 Config 模板还要引用安装后的数据目录，可通过 `PATH_VARS` 生成相对于包位置计算的变量，避免嵌入配置机器的绝对前缀：

```cmake
set(MYLIB_INSTALL_DATADIR "${CMAKE_INSTALL_DATADIR}/MyLib")

configure_package_config_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/MyLibConfig.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/MyLibConfig.cmake"
    INSTALL_DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/MyLib"
    PATH_VARS MYLIB_INSTALL_DATADIR
)
```

模板中使用 `@PACKAGE_MYLIB_INSTALL_DATADIR@`。可重定位性还取决于导出目标及依赖是否也没有泄漏构建机路径，不能只靠 `@PACKAGE_INIT@` 判断。

如果你的库依赖其他库，需要在 Config 文件中查找它们：

```cmake
# MyLibConfig.cmake.in
@PACKAGE_INIT@

# 查找依赖
include(CMakeFindDependencyMacro)
find_dependency(Eigen3 CONFIG)
find_dependency(Threads)

include("${CMAKE_CURRENT_LIST_DIR}/MyLibTargets.cmake")

check_required_components(MyLib)
```

`find_dependency` 会继承外层包查找的 `REQUIRED`/`QUIET` 语义，并在依赖未满足时结束当前 Config 文件。凡是导出接口中引用的外部目标，都必须在包含 `MyLibTargets.cmake` 前创建。对于静态库，即使某项依赖在构建目标上写成 `PRIVATE`，它也可能以仅链接用途进入导出接口，以便最终可执行文件解析符号；是否需要 `find_dependency` 不能只看 `PUBLIC`/`PRIVATE` 关键字，还要结合库类型和生成的接口。

==== 版本文件

为了支持版本检查（如 `find_package(MyLib 1.2.0 REQUIRED)`），需要生成一个版本文件：

```cmake
include(CMakePackageConfigHelpers)

write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/MyLibConfigVersion.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)

install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/MyLibConfigVersion.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/MyLib
)
```

`COMPATIBILITY` 决定一个已安装版本是否可以满足调用者请求的版本：

- `ExactVersion`：必须精确匹配
- `SameMajorVersion`：已安装版本不低于请求版本，且主版本相同；例如已安装 1.2.0 可以满足请求 1.0.0
- `SameMinorVersion`：已安装版本不低于请求版本，且主、次版本相同；例如已安装 1.2.3 可以满足请求 1.2.0
- `AnyNewerVersion`：已安装版本不低于请求版本，不限制主版本

`SameMajorVersion` 常用于承诺同一主版本保持兼容的库，但“采用语义化版本号”本身并不能证明源码或 ABI 兼容。维护者应根据真实兼容策略选择并用跨版本消费测试验证；header-only 库还可以在合适时使用 `ARCH_INDEPENDENT`，二进制库则不应忽略架构检查。

==== 完整的安装配置示例

下面给出一个完整的共享库示例。这里假设公共头文件使用 Eigen 类型，但不暴露 OpenCV 类型；这个假设决定了依赖可见性和 Config 文件内容。

```cmake
cmake_minimum_required(VERSION 3.16)
project(RMCore VERSION 2.0.0 LANGUAGES CXX)

# 包含必要的模块
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)
set(RMCore_INSTALL_CMAKEDIR
    "${CMAKE_INSTALL_LIBDIR}/cmake/RMCore")

# 依赖
find_package(Eigen3 CONFIG REQUIRED)
find_package(OpenCV REQUIRED COMPONENTS core imgproc)

add_library(rm_opencv INTERFACE)
target_include_directories(rm_opencv SYSTEM INTERFACE ${OpenCV_INCLUDE_DIRS})
target_link_libraries(rm_opencv INTERFACE ${OpenCV_LIBS})

#=============================================================================
# 定义库
#=============================================================================

add_library(rm_core SHARED
    src/config.cpp
    src/logger.cpp
    src/math_utils.cpp
)

add_library(RMCore::rm_core ALIAS rm_core)  # 创建别名，便于项目内使用

target_include_directories(rm_core
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)

target_compile_features(rm_core PUBLIC cxx_std_17)

target_link_libraries(rm_core
    PUBLIC Eigen3::Eigen
    PRIVATE rm_opencv
)

set_target_properties(rm_core PROPERTIES
    VERSION ${PROJECT_VERSION}
    SOVERSION ${PROJECT_VERSION_MAJOR}
)

#=============================================================================
# 安装
#=============================================================================

# 安装库目标
install(TARGETS rm_core
    EXPORT RMCoreTargets
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

# 安装头文件
install(DIRECTORY include/
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    FILES_MATCHING PATTERN "*.h" PATTERN "*.hpp"
)

# 安装导出目标
install(EXPORT RMCoreTargets
    FILE RMCoreTargets.cmake
    NAMESPACE RMCore::
    DESTINATION ${RMCore_INSTALL_CMAKEDIR}
)

# 生成并安装 Config 文件
configure_package_config_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake/RMCoreConfig.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/RMCoreConfig.cmake
    INSTALL_DESTINATION ${RMCore_INSTALL_CMAKEDIR}
)

# 生成并安装版本文件
write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/RMCoreConfigVersion.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)

install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/RMCoreConfig.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/RMCoreConfigVersion.cmake
    DESTINATION ${RMCore_INSTALL_CMAKEDIR}
)
```

对应的 Config 模板文件：

```cmake
# cmake/RMCoreConfig.cmake.in
@PACKAGE_INIT@

include(CMakeFindDependencyMacro)

# 公共接口引用 Eigen3::Eigen，必须先恢复该目标
find_dependency(Eigen3 CONFIG)

# rm_core 是共享库且公共接口不引用 OpenCV；OpenCV 不进入导出的 CMake
# 使用接口。部署时还要检查 librm_core.so 实际记录了哪些动态库依赖。

# 包含导出的目标
include("${CMAKE_CURRENT_LIST_DIR}/RMCoreTargets.cmake")

check_required_components(RMCore)
```

安装后的目录结构：

```
/usr/local/
├── include/
│   └── rm_core/
│       ├── config.h
│       ├── logger.h
│       └── math_utils.h
├── lib/
│   ├── librm_core.so
│   └── cmake/
│       └── RMCore/
│           ├── RMCoreConfig.cmake
│           ├── RMCoreConfigVersion.cmake
│           ├── RMCoreTargets.cmake
│           └── RMCoreTargets-release.cmake
```

其他项目使用这个库：

```cmake
find_package(RMCore 2.0 REQUIRED)

add_executable(my_app main.cpp)
target_link_libraries(my_app PRIVATE RMCore::rm_core)
```

如果把 `rm_core` 改成静态库，或让公共头文件出现 `cv::Mat`，OpenCV 就可能成为消费者在链接或编译阶段必须恢复的依赖，Config 模板也要相应调用 `find_dependency(OpenCV ...)`。`SOVERSION` 只表达维护者承诺的共享库 ABI 世代；设置为主版本号不会自动使 ABI 稳定，仍需要符号与跨版本消费测试。

==== 支持构建目录导出

同一工作空间内，有时需要在不安装的情况下消费构建树。可以生成构建树目标文件，并让构建树中的 `RMCoreConfig.cmake` 引用它：

```cmake
# 导出到构建目录
export(EXPORT RMCoreTargets
    FILE ${CMAKE_CURRENT_BINARY_DIR}/RMCoreTargets.cmake
    NAMESPACE RMCore::
)

# 消费项目可显式传入：-DRMCore_DIR=/path/to/RMCore-build
```

还存在 `export(PACKAGE RMCore)` 的用户包注册表机制；在较新策略下通常要显式启用 `CMAKE_EXPORT_PACKAGE_REGISTRY` 才会写入。它会在用户环境中留下不易从项目命令看见的状态，可能让本机找到包而 CI 找不到，因此工作空间更适合显式设置 `<Package>_DIR`、`CMAKE_PREFIX_PATH`，或由工作空间工具管理前缀。构建树导出也应单独做消费测试，不能用安装树测试代替。

==== 安装多个组件

对于大型项目，可能希望让用户选择安装哪些组件：

```cmake
# 运行时组件
install(TARGETS rm_vision
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    COMPONENT Runtime
)

# 库的运行文件与开发文件可以按产物类型分组
install(TARGETS rm_core
    EXPORT RMCoreTargets
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
            COMPONENT Runtime
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
            COMPONENT Runtime
            NAMELINK_COMPONENT Development
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
            COMPONENT Development
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

install(DIRECTORY include/
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    COMPONENT Development
)

install(EXPORT RMCoreTargets
    FILE RMCoreTargets.cmake
    NAMESPACE RMCore::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/RMCore
    COMPONENT Development
)

# 文档组件
install(DIRECTORY docs/
    DESTINATION ${CMAKE_INSTALL_DOCDIR}
    COMPONENT Documentation
)
```

用户可以选择性安装：

```bash
# 只安装运行时组件
cmake --install build --component Runtime

# 只安装开发组件
cmake --install build --component Development
```

这里把共享库的运行文件归入 `Runtime`，把静态/导入库、开发用名称链接、头文件和 CMake 目标文件归入 `Development`。不同平台的产物种类不同，应检查实际安装清单。`cmake --install --component Development` 只执行该组件标记的规则，不会依据后面的 CPack 组件依赖自动补装所有运行文件。

==== CPack：打包与分发

CPack 根据安装规则生成归档或平台包。它复用安装树，但不会自动推导所有第三方运行时依赖、许可证或发行版包名：

```cmake
# 在 CMakeLists.txt 末尾添加
set(CPACK_PACKAGE_NAME "RMCore")
set(CPACK_PACKAGE_VERSION ${PROJECT_VERSION})
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "RoboMaster Core Library")
set(CPACK_PACKAGE_VENDOR "RoboMaster Team")
set(CPACK_PACKAGE_CONTACT "team@example.com")

# 以下发行版依赖名只是示例，发布前要在目标发行版核对并区分运行/开发包
set(CPACK_DEBIAN_PACKAGE_DEPENDS "libeigen3-dev, libopencv-dev")

# RPM 包配置
set(CPACK_RPM_PACKAGE_REQUIRES "eigen3-devel, opencv-devel")

# 包含 CPack
include(CPack)
```

生成包：

```bash
# 配置、构建后使用该构建树生成的 CPack 配置
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
cpack --config build/CPackConfig.cmake

# 生成特定格式的包
cpack --config build/CPackConfig.cmake -G DEB
cpack --config build/CPackConfig.cmake -G RPM
cpack --config build/CPackConfig.cmake -G TGZ
cpack --config build/CPackConfig.cmake -G ZIP
```

更细致的控制：

```cmake
# 组件打包
set(CPACK_COMPONENTS_ALL Runtime Development Documentation)
set(CPACK_COMPONENT_RUNTIME_DISPLAY_NAME "Runtime Files")
set(CPACK_COMPONENT_DEVELOPMENT_DISPLAY_NAME "Development Files")
set(CPACK_COMPONENT_DOCUMENTATION_DISPLAY_NAME "Documentation")

# 组件依赖
set(CPACK_COMPONENT_DEVELOPMENT_DEPENDS Runtime)

# 支持组件的生成器可按组件分别打包
set(CPACK_COMPONENTS_GROUPING IGNORE)
set(CPACK_DEB_COMPONENT_INSTALL ON)
set(CPACK_RPM_COMPONENT_INSTALL ON)
set(CPACK_ARCHIVE_COMPONENT_INSTALL ON)
```

DEB/RPM 生成还依赖宿主机上的相应打包工具，并受生成器版本影响。生成成功只说明 CPack 产出了文件；发布前仍要在干净环境检查文件所有权、安装/升级/卸载脚本、动态库依赖、许可证和实际启动行为。组件依赖在不同生成器中的表达方式也不完全相同，应检查最终包的元数据，而不是只看 CMake 变量。

==== 安装脚本

`install(CODE)` 和 `install(SCRIPT)` 可以在安装阶段执行 CMake 代码。例如，输出与本次前缀相关的提示，或处理无法由普通文件安装规则表达的项目内步骤：

```cmake
# 安装时执行内嵌 CMake 代码
install(CODE [[
    message(STATUS "RMCore installed under: ${CMAKE_INSTALL_PREFIX}")
]] COMPONENT Runtime)

# 或者从文件执行
install(SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/cmake/post_install.cmake"
    COMPONENT Runtime)
```

脚本在安装者的权限和环境中运行，也会参与 `DESTDIR` 暂存及 CPack 流程。不要在通用项目中无条件调用 `ldconfig`、重启服务或修改系统配置；这些动作具有平台和权限要求，通常应由发行版包管理器的脚本或管理员显式完成。能用声明式文件安装表达的步骤，优先不用任意安装代码。

==== 卸载支持

CMake 会生成 `install_manifest.txt`，但默认不提供卸载目标。若项目确实需要基于清单删除文件，至少先提供只预览不删除的目标：

```cmake
# 生成基于本构建树安装清单的脚本
if(NOT TARGET uninstall)
    configure_file(
        "${CMAKE_CURRENT_SOURCE_DIR}/cmake/cmake_uninstall.cmake.in"
        "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
        @ONLY
    )

    add_custom_target(uninstall-preview
        COMMAND "${CMAKE_COMMAND}"
            -DRM_UNINSTALL_DRY_RUN=ON
            -P "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
        VERBATIM
    )

    add_custom_target(uninstall
        COMMAND "${CMAKE_COMMAND}"
            -DRM_UNINSTALL_DRY_RUN=OFF
            -P "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
        VERBATIM
    )
endif()
```

卸载脚本模板：

```cmake
# cmake/cmake_uninstall.cmake.in
set(_manifest "@CMAKE_BINARY_DIR@/install_manifest.txt")
if(NOT EXISTS "${_manifest}")
    message(FATAL_ERROR "Cannot find install manifest: ${_manifest}")
endif()

if(NOT DEFINED RM_UNINSTALL_DRY_RUN)
    set(RM_UNINSTALL_DRY_RUN ON)
endif()

file(STRINGS "${_manifest}" _installed_files ENCODING UTF-8)
foreach(_installed_file IN LISTS _installed_files)
    if(_installed_file STREQUAL "")
        continue()
    endif()
    if(NOT IS_ABSOLUTE "${_installed_file}")
        message(FATAL_ERROR "Refusing non-absolute manifest entry: ${_installed_file}")
    endif()

    set(_path "$ENV{DESTDIR}${_installed_file}")
    if(_path STREQUAL "" OR _path STREQUAL "/")
        message(FATAL_ERROR "Refusing unsafe uninstall path: '${_path}'")
    endif()
    if(IS_DIRECTORY "${_path}" AND NOT IS_SYMLINK "${_path}")
        message(FATAL_ERROR "Refusing to remove directory from manifest: ${_path}")
    endif()

    if(IS_SYMLINK "${_path}" OR EXISTS "${_path}")
        if(RM_UNINSTALL_DRY_RUN)
            message(STATUS "Would remove: ${_path}")
        else()
            message(STATUS "Removing: ${_path}")
            file(REMOVE "${_path}")
            if(IS_SYMLINK "${_path}" OR EXISTS "${_path}")
                message(FATAL_ERROR "Failed to remove: ${_path}")
            endif()
        endif()
    else()
        message(STATUS "Already absent: ${_path}")
    endif()
endforeach()
```

使用：

```bash
# 先核对将删除的每个路径
cmake --build build --target uninstall-preview

# 确认清单和前缀无误后再执行删除
cmake --build build --target uninstall
```

这种脚本只删除清单中的精确文件和符号链接，不递归删除目录，但仍不能恢复安装时被覆盖的旧文件，也无法判断同一路径是否已被其他包接管。安装到系统前缀后，优先使用生成该安装的包管理器卸载；手写目标更适合受控的独立前缀，并应在执行前核对 `install_manifest.txt`、`DESTDIR` 和权限。

==== 安装与导出检查清单

完成可安装库的配置后，可以按以下项目复核：

1. *目录可覆盖*：使用 `GNUInstallDirs` 的相对目录，检查自定义前缀、`DESTDIR` 和多配置安装

2. *使用生成器表达式区分构建和安装路径*：
   ```cmake
   target_include_directories(mylib PUBLIC
       $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
       $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
   )
   ```

3. *稳定的目标名*：导出时使用命名空间前缀（如 `MyLib::`），避免和消费项目的普通目标重名

4. *构建树与安装树一致*：按需创建别名目标，使项目内部也使用相同的命名空间形式
   ```cmake
   add_library(MyLib::mylib ALIAS mylib)
   ```

5. *恢复接口依赖*：在 Config 文件中用 `find_dependency` 创建导出接口引用的外部目标，并额外检查静态库的链接依赖

6. *声明真实版本策略*：生成版本文件，但只选择项目确实承诺并测试过的兼容范围

7. *按需划分组件*：只有当运行、开发或文档文件确实需要独立安装和打包时才增加组件，并核对各生成器行为

8. *测试消费流程*：把库安装到干净暂存前缀，再用一个独立小项目执行 `find_package`、编译、链接和测试；需要支持静态/共享或多配置时分别覆盖

安装成功、包配置可加载和程序可运行是三个不同检查。目标导出可以减少使用者手工填写路径，但不会自动解决 ABI、运行库、许可证和系统包元数据。最终应以受支持环境中的独立消费测试与安装包测试为准。


=== ROS 2 包的构建
// ament_cmake 构建系统
// - ROS 2 的包结构
// - package.xml：包元信息
// - ament_cmake vs ament_python
// - find_package(ament_cmake REQUIRED)
// - ament_target_dependencies：简化依赖声明
// - ROS 2 常用包的查找：
//   rclcpp, std_msgs, sensor_msgs, geometry_msgs
//   cv_bridge, image_transport
//   tf2, tf2_ros
// - 消息和服务的生成：rosidl_generate_interfaces
// - launch 文件的安装
// - 配置文件的安装
// - colcon build：ROS 2 的构建工具
// - --symlink-install：开发时的便利选项
// - 完整示例：视觉节点的 CMakeLists.txt
// === ROS 2 包的构建

ROS 2（Robot Operating System 2）是机器人项目中广泛使用的一套中间件与工具。C++ 包通常采用 `ament_cmake`：它在 CMake 之上增加包索引、依赖导出、接口生成和测试等集成。节点发现属于 ROS 2 运行时机制，不是 `ament_cmake` 自动完成的构建功能。本节以常见的现代 ROS 2 发行版为背景；宏和推荐写法可能随发行版变化，实际项目应同时查看目标发行版文档。

==== ROS 2 的包结构

ROS 2 的包（package）是代码组织的基本单位。一个典型的 C++ 包结构如下：

```
my_package/
├── CMakeLists.txt          # 构建配置
├── package.xml             # 包元信息
├── include/                # 公开头文件
│   └── my_package/
│       └── my_node.hpp
├── src/                    # 源文件
│   ├── my_node.cpp
│   └── main.cpp
├── launch/                 # 启动文件
│   └── my_launch.py
├── config/                 # 配置文件
│   └── params.yaml
├── msg/                    # 自定义消息（可选）
│   └── MyMessage.msg
├── srv/                    # 自定义服务（可选）
│   └── MyService.srv
└── test/                   # 测试文件
    └── test_my_node.cpp
```

与普通 CMake 项目相比，ROS 2 包还需要 `package.xml` 描述名称、版本、构建类型和依赖。colcon 及其包识别扩展会读取这些元数据，按工作空间内已声明的依赖建立构建顺序；声明遗漏或名称写错时，偶然从系统环境找到头文件并不能补全依赖图。

==== package.xml：包元信息

`package.xml` 是每个 ROS 2 包必需的文件，它使用 XML 格式描述包的信息：

```xml
<?xml version="1.0"?>
<?xml-model href="http://download.ros.org/schema/package_format3.xsd" schematypens="http://www.w3.org/2001/XMLSchema"?>
<package format="3">
  <name>rm_vision</name>
  <version>2.0.0</version>
  <description>RoboMaster Vision System</description>
  <maintainer email="developer@example.com">Developer Name</maintainer>
  <license>MIT</license>

  <!-- 构建工具依赖 -->
  <buildtool_depend>ament_cmake</buildtool_depend>

  <!-- 构建、导出和运行时都需要 -->
  <depend>rclcpp</depend>
  <depend>std_msgs</depend>
  <depend>sensor_msgs</depend>
  <depend>cv_bridge</depend>
  <depend>geometry_msgs</depend>
  <depend>tf2_ros</depend>

  <!-- 系统依赖使用 rosdep 键，不一定等于 find_package 的名称 -->
  <depend>libopencv-dev</depend>
  <depend>eigen</depend>

  <!-- 测试依赖 -->
  <test_depend>ament_lint_auto</test_depend>
  <test_depend>ament_lint_common</test_depend>
  <test_depend>ament_cmake_gtest</test_depend>

  <export>
    <build_type>ament_cmake</build_type>
  </export>
</package>
```

依赖类型说明：

- `buildtool_depend`：构建工具依赖，如 `ament_cmake`
- `build_depend`：构建当前包时需要
- `build_export_depend`：下游构建使用本包公开接口时需要
- `exec_depend`：运行已安装产物时需要
- `depend`：同时覆盖 `build_depend`、`build_export_depend` 和 `exec_depend`
- `test_depend`：只在测试时需要的依赖

`<export>` 中的 `<build_type>` 告诉包识别工具采用哪种构建扩展，C++ 包常用 `ament_cmake`。依赖标签填写的是 ROS 包名或 rosdep 键，CMake 中的 `find_package(OpenCV)` 名称不一定可直接照搬。上例的 `libopencv-dev` 与 `eigen` 可在本机 ROS 2 Jazzy 包清单中找到；其他发行版与平台应通过已初始化的 `rosdep resolve` 和目标发行版索引核对。

==== ament_cmake vs ament_python

ROS 2 常见的两种构建类型是：

- `ament_cmake`：用于 C/C++ 包，基于 CMake
- `ament_python`：用于纯 Python 包，使用 setuptools

选择取决于源码语言和构建需求，而不是只按“性能高低”判断。C++ 目标采用 `ament_cmake`，纯 Python 包采用 `ament_python`；以 CMake 为主且需要安装 Python 模块时，可以引入 `ament_cmake_python`。

```xml
<!-- C++ 包 -->
<buildtool_depend>ament_cmake</buildtool_depend>
<export>
  <build_type>ament_cmake</build_type>
</export>

<!-- Python 包 -->
<buildtool_depend>ament_python</buildtool_depend>
<export>
  <build_type>ament_python</build_type>
</export>

<!-- 混合包（C++ 为主，包含 Python 模块） -->
<buildtool_depend>ament_cmake</buildtool_depend>
<buildtool_depend>ament_cmake_python</buildtool_depend>
<export>
  <build_type>ament_cmake</build_type>
</export>
```

混合包需要同时处理 Python 安装路径和依赖，不能只增加一个 `buildtool_depend` 就完成。特别是自定义 ROS 接口生成与 `ament_cmake_python` 的组合在部分发行版存在限制；接口会被多个包复用时，拆成独立接口包通常更容易维护和发布。

==== 基本的 CMakeLists.txt 结构

一个最小的 `ament_cmake` C++ 包通常包含以下步骤：

```cmake
cmake_minimum_required(VERSION 3.8)
project(my_package LANGUAGES CXX)

# 查找依赖
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)

# 定义可执行文件
add_executable(my_node src/my_node.cpp)
target_compile_features(my_node PRIVATE cxx_std_17)
if(CMAKE_CXX_COMPILER_ID MATCHES "^(GNU|AppleClang|Clang)$")
  target_compile_options(my_node PRIVATE -Wall -Wextra -Wpedantic)
endif()
ament_target_dependencies(my_node rclcpp std_msgs)

# 安装目标
install(TARGETS my_node
  DESTINATION lib/${PROJECT_NAME}
)

# 在安装与导出规则之后调用一次
ament_package()
```

几个关键点：

1. 先 `find_package(ament_cmake REQUIRED)`，使 ament 宏可用
2. ROS 2 依赖通过 `find_package` 查找
3. 使用 `ament_target_dependencies` 简化依赖声明
4. 供 `ros2 run <package> <executable>` 查找的包内可执行文件通常安装到 `lib/${PROJECT_NAME}`
5. `ament_package()` 在注册完安装、导出和额外配置后调用一次，通常放在文件末尾

==== ament_target_dependencies：简化依赖声明

`ament_target_dependencies` 接收已经 `find_package` 成功的包名，并把这些包导出的目标或传统变量接到指定目标上：

```cmake
# 传入包名，而不是猜测库文件名
ament_target_dependencies(my_node
  rclcpp
  std_msgs
  sensor_msgs
  cv_bridge
)

```

这不能机械地改写成一组 `${package_LIBRARIES}` 与 `${package_INCLUDE_DIRS}`：有的包导出 CMake 目标，有的保留传统变量，ament 还会处理工作空间覆盖层中的头文件顺序。本机 ROS 2 Jazzy 的宏会优先使用包导出的目标，否则读取约定变量；包必须事先以相同名称完成 `find_package`。

传播范围对库尤其重要。Jazzy 的 `ament_target_dependencies` 默认按公开要求处理，并支持开头的 `PUBLIC` 或 `INTERFACE`，没有 `PRIVATE` 关键字。公共头文件确实引用 ROS 类型时可以显式写 `PUBLIC`；只在 `.cpp` 使用的依赖则应查看该包是否提供可用于 `target_link_libraries(... PRIVATE ...)` 的导入目标，或按目标发行版提供的接口处理，不能为了省事一律公开。

但有时候你需要混合使用：

```cmake
# ROS 2 依赖用 ament_target_dependencies
ament_target_dependencies(my_node
  rclcpp
  sensor_msgs
)

# 非 ROS 包按它实际提供的 CMake 接口连接
find_package(Eigen3 CONFIG REQUIRED)
find_package(OpenCV REQUIRED COMPONENTS core imgproc)
target_include_directories(my_node PRIVATE ${OpenCV_INCLUDE_DIRS})
target_link_libraries(my_node PRIVATE
  Eigen3::Eigen
  ${OpenCV_LIBS}
)
```

==== ROS 2 常用包

RoboMaster 开发中常用的 ROS 2 包：

*核心包*：

```cmake
# ROS 2 C++ 客户端库
find_package(rclcpp REQUIRED)

# 组件化节点支持
find_package(rclcpp_components REQUIRED)

# 生命周期节点
find_package(rclcpp_lifecycle REQUIRED)
```

*消息包*：

```cmake
# 标准消息类型
find_package(std_msgs REQUIRED)          # String, Int32, Float64, Bool 等

# 传感器消息
find_package(sensor_msgs REQUIRED)       # Image, CameraInfo, Imu, LaserScan 等

# 几何消息
find_package(geometry_msgs REQUIRED)     # Pose, Transform, Twist, Point 等

# 可视化消息
find_package(visualization_msgs REQUIRED) # Marker, MarkerArray
```

*图像处理*：

```cmake
# OpenCV 与 ROS 的桥接
find_package(cv_bridge REQUIRED)

# 图像传输抽象；压缩等传输方式还需对应插件
find_package(image_transport REQUIRED)

# 相机信息
find_package(camera_info_manager REQUIRED)
```

*坐标变换*：

```cmake
# TF2 核心库
find_package(tf2 REQUIRED)

# TF2 ROS 接口
find_package(tf2_ros REQUIRED)

# TF2 几何消息支持
find_package(tf2_geometry_msgs REQUIRED)

# TF2 Eigen 支持
find_package(tf2_eigen REQUIRED)
```

一个典型的视觉节点可能需要这些依赖：

```cmake
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(sensor_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(cv_bridge REQUIRED)
find_package(image_transport REQUIRED)
find_package(ament_index_cpp REQUIRED)
find_package(tf2_ros REQUIRED)
find_package(tf2_geometry_msgs REQUIRED)

# 非 ROS 依赖
find_package(OpenCV REQUIRED COMPONENTS core imgproc dnn)
find_package(Eigen3 CONFIG REQUIRED)
```

只列出源码和公共头文件直接使用的包。`find_package` 成功说明当前环境提供了相应构建接口，不证明运行时所需的图像传输插件、相机驱动或 TF 数据一定存在；这些要在部署与运行测试中另行确认。

==== 创建库

包内库若只被同一包的节点使用，安装目标即可；若其他 ROS 2 包也要链接它，还需要导出公共头文件、目标和公共依赖。较早项目常见基于库名与目录变量的导出方式：

```cmake
# 创建库
add_library(${PROJECT_NAME}_lib
  src/detector.cpp
  src/tracker.cpp
)

# 设置头文件路径
target_include_directories(${PROJECT_NAME}_lib PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:include>
)

# 添加依赖
ament_target_dependencies(${PROJECT_NAME}_lib PUBLIC
  rclcpp
  sensor_msgs
  cv_bridge
)

# 公共头文件引用这些包的类型，因此向下游导出
ament_export_dependencies(
  rclcpp
  sensor_msgs
  cv_bridge
)

# 导出 include 路径
ament_export_include_directories(include)

# 导出库
ament_export_libraries(${PROJECT_NAME}_lib)

# 安装头文件
install(DIRECTORY include/
  DESTINATION include
)

# 安装库
install(TARGETS ${PROJECT_NAME}_lib
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
)
```

这种方式能兼容依赖传统 ament 变量的消费者，但库名、目录和配置之间的关系较弱。支持目标导出的发行版中，更适合把真实 CMake 目标放入导出集：

```cmake
# 创建库
add_library(${PROJECT_NAME}_lib
  src/detector.cpp
  src/tracker.cpp
)

target_include_directories(${PROJECT_NAME}_lib PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:include>
)

ament_target_dependencies(${PROJECT_NAME}_lib PUBLIC
  rclcpp
  sensor_msgs
)

# 安装头文件
install(DIRECTORY include/
  DESTINATION include
)

# 安装并导出目标
install(TARGETS ${PROJECT_NAME}_lib
  EXPORT ${PROJECT_NAME}Targets
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
  INCLUDES DESTINATION include
)

# 导出目标
ament_export_targets(${PROJECT_NAME}Targets HAS_LIBRARY_TARGET)

# 导出依赖
ament_export_dependencies(rclcpp sensor_msgs)
```

`ament_export_targets` 会安排导出集的安装；默认命名空间通常是 `${PROJECT_NAME}::`，`HAS_LIBRARY_TARGET` 还会注册库路径相关的环境钩子。它不替代 `ament_export_dependencies`：导出目标若引用 `rclcpp` 或 `sensor_msgs` 提供的接口，消费包加载目标前仍要找到这些依赖。实现中使用、但不出现在公共头文件和静态链接接口中的依赖不应无条件导出。

==== 消息和服务的生成

ROS 2 允许定义自定义的消息（msg）、服务（srv）和动作（action）类型。这些定义会被编译成 C++ 和 Python 代码。

消息文件示例 `msg/AimTarget.msg`：

```
# 目标信息
uint8 id                    # 目标 ID
geometry_msgs/Point position # 3D 位置
float64 confidence          # 置信度
float64 yaw                 # 偏航角
float64 pitch               # 俯仰角
builtin_interfaces/Time stamp # 时间戳
```

服务文件示例 `srv/SetMode.srv`：

```
# 请求
uint8 mode
---
# 响应
bool success
string message
```

CMakeLists.txt 配置：

```cmake
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(rosidl_default_generators REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(builtin_interfaces REQUIRED)

# 生成消息和服务
rosidl_generate_interfaces(${PROJECT_NAME}
  "msg/AimTarget.msg"
  "msg/ArmorArray.msg"
  "srv/SetMode.srv"
  DEPENDENCIES geometry_msgs builtin_interfaces
)

# 如果本包的可执行文件需要使用这些消息
add_executable(my_node src/my_node.cpp)
ament_target_dependencies(my_node rclcpp)

# 链接生成的消息库
rosidl_get_typesupport_target(cpp_typesupport_target
  ${PROJECT_NAME} rosidl_typesupport_cpp)
target_link_libraries(my_node PRIVATE "${cpp_typesupport_target}")

# 让消费本包接口的下游找到生成类型的运行时支持
ament_export_dependencies(rosidl_default_runtime)
```

package.xml 需要添加相应依赖：

```xml
<buildtool_depend>rosidl_default_generators</buildtool_depend>
<exec_depend>rosidl_default_runtime</exec_depend>
<depend>geometry_msgs</depend>
<depend>builtin_interfaces</depend>

<member_of_group>rosidl_interface_packages</member_of_group>
```

在代码中使用自定义消息：

```cpp
#include <rclcpp/rclcpp.hpp>
#include "my_package/msg/aim_target.hpp"

class TargetLogger : public rclcpp::Node {
public:
    TargetLogger() : Node("target_logger") {}

private:
    void callback(const my_package::msg::AimTarget::SharedPtr msg) {
        RCLCPP_INFO(get_logger(), "Target %u at (%.2f, %.2f, %.2f)",
            static_cast<unsigned int>(msg->id),
            msg->position.x, msg->position.y, msg->position.z);
    }
};
```

`rosidl_get_typesupport_target` 是当前常见发行版用于同一包内目标链接类型支持的方式；较旧发行版可能使用不同宏，应按目标发行版文档选择。定义接口的包还要导出 `rosidl_default_runtime`。当消息会被多个功能包复用时，单独建立接口包可以减少生成器依赖与业务代码耦合；是否拆分取决于复用和发布边界。

==== 组件化节点

组件化节点把 `rclcpp::Node` 实现编译为可由组件容器加载的共享库。它允许多个节点放在同一进程，也能由注册宏生成单独启动的包装可执行文件。进程数减少不等于消息一定零拷贝；是否走进程内通信还取决于节点选项、发布/订阅类型、QoS 和具体 RMW/发行版实现。

```cmake
# 创建组件库
add_library(detector_component SHARED
  src/detector_node.cpp
)
target_compile_features(detector_component PRIVATE cxx_std_17)

target_include_directories(detector_component PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}/include
)

ament_target_dependencies(detector_component
  rclcpp
  rclcpp_components
  sensor_msgs
  cv_bridge
)

# 注册组件
rclcpp_components_register_node(detector_component
  PLUGIN "rm_vision::DetectorNode"
  EXECUTABLE detector_node
)

# 安装组件库
install(TARGETS detector_component
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
)
```

`rclcpp_components_register_node` 记录插件类名和库位置；在当前 Jazzy 宏中，`EXECUTABLE detector_node` 还会生成并安装一个加载该组件的包装可执行文件。插件类名必须与注册宏中的完全限定类型一致，共享库本身也必须按后面的安装规则进入包前缀。跨平台发布时还要处理组件类符号可见性。

组件节点的代码：

```cpp
#include <rclcpp/rclcpp.hpp>
#include <sensor_msgs/msg/image.hpp>

namespace rm_vision {

class DetectorNode : public rclcpp::Node {
public:
    explicit DetectorNode(const rclcpp::NodeOptions& options)
        : Node("detector_node", options) {
        // 初始化订阅、发布和参数
    }

private:
    // 成员声明
};

}  // namespace rm_vision

#include "rclcpp_components/register_node_macro.hpp"
RCLCPP_COMPONENTS_REGISTER_NODE(rm_vision::DetectorNode)
```

==== 安装 launch 文件

Python launch 文件通常安装到包的 share 目录，使 `ros2 launch` 能通过 ament 索引定位：

```cmake
# 安装 launch 文件
install(DIRECTORY launch/
  DESTINATION share/${PROJECT_NAME}/launch
)
```

launch 文件示例 `launch/vision_launch.py`：

```python
import os

from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from ament_index_python.packages import get_package_share_directory
from launch_ros.actions import Node


def generate_launch_description():
    pkg_share = get_package_share_directory('rm_vision')

    config_file = os.path.join(pkg_share, 'config', 'params.yaml')

    return LaunchDescription([
        DeclareLaunchArgument(
            'use_sim_time',
            default_value='false',
            description='Use simulation time'
        ),
        
        Node(
            package='rm_vision',
            executable='detector_node',
            name='detector',
            parameters=[
                config_file,
                {'use_sim_time': LaunchConfiguration('use_sim_time')},
            ],
            output='screen'
        ),
        
        Node(
            package='rm_vision',
            executable='tracker_node',
            name='tracker',
            parameters=[config_file],
            output='screen'
        ),
    ])
```

安装 launch 文件还不够：`package.xml` 需要为运行时直接导入的 `launch`、`launch_ros` 和 `ament_index_python` 声明相应依赖。`get_package_share_directory` 查找的是已建立并加载环境的安装前缀；若工作空间尚未构建或当前 shell 未 source 对应 setup 文件，它会报告包未找到。

==== 安装配置文件

运行时资源通常放在包的 share 目录；只为源码树存在的目录添加安装规则，避免可选目录缺失时安装阶段报错：

```cmake
# 安装配置文件
install(DIRECTORY config/
  DESTINATION share/${PROJECT_NAME}/config
)

# 安装模型文件
install(DIRECTORY models/
  DESTINATION share/${PROJECT_NAME}/models
)

# 安装 URDF/Xacro 文件
install(DIRECTORY urdf/
  DESTINATION share/${PROJECT_NAME}/urdf
)

# 安装 RViz 配置
install(DIRECTORY rviz/
  DESTINATION share/${PROJECT_NAME}/rviz
)
```

配置文件示例 `config/params.yaml`：

```yaml
detector_node:
  ros__parameters:
    camera_topic: /camera/image_raw
    detection_threshold: 0.7
    max_targets: 5
    debug_mode: false
    model_path: ""  # 如果为空，使用默认路径

tracker_node:
  ros__parameters:
    process_noise: 0.1
    measurement_noise: 0.05
    max_lost_frames: 10
```

在代码中获取包的资源路径：

```cpp
#include <filesystem>

#include <ament_index_cpp/get_package_share_directory.hpp>

const auto package_share = std::filesystem::path{
    ament_index_cpp::get_package_share_directory("rm_vision")};
const auto model_path = package_share / "models" / "detector.onnx";
```

使用这段代码的目标要先 `find_package(ament_index_cpp REQUIRED)` 并声明相应的 `package.xml` 依赖。包索引只能返回 share 目录；模型文件是否存在、是否可读以及版本是否匹配仍要在打开时检查。需要用户修改的参数通常放在外部覆盖文件中，不要让运行程序直接改写安装前缀里的默认配置。

==== colcon build：ROS 2 的构建工具

colcon 负责发现工作空间中的包、按已声明依赖调度各包的构建，并生成统一的安装环境。开始前先加载目标 ROS 2 发行版的 underlay：

```bash
# 示例使用 Jazzy；其他发行版替换目录名
source /opt/ros/jazzy/setup.bash

# 创建工作空间目录
mkdir -p ~/ros2_ws/src

# 将包源码检出或复制到 ~/ros2_ws/src/rm_vision

# 返回工作空间根目录
cd ~/ros2_ws

# 根据 package.xml 检查并安装缺失依赖；执行前核对包管理器计划
rosdep install --from-paths src --ignore-src --rosdistro "$ROS_DISTRO"

# 构建所有包
colcon build

# 只构建特定包
colcon build --packages-select rm_vision

# 构建包及其依赖
colcon build --packages-up-to rm_vision

# 使用 Release 模式
colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release

# 限制同时处理的包数量
colcon build --executor parallel --parallel-workers 4
```

`--parallel-workers` 控制同时构建多少个包，不等同于单个 CMake 包内部编译多少个源文件；底层构建工具还有自己的并行策略。colcon 的默认执行器和可用参数由已安装扩展决定，可以用 `colcon build --help` 核对。`package.xml` 只提供依赖声明，系统依赖能否由 rosdep 解析还取决于 rosdep 初始化、索引和目标平台规则。

构建后的目录结构：

```
ros2_ws/
├── src/                    # 源代码
│   └── rm_vision/
├── build/                  # 构建中间文件
│   └── rm_vision/
├── install/                # 安装目录
│   ├── rm_vision/
│   │   ├── lib/
│   │   ├── share/
│   │   └── include/
│   ├── setup.bash
│   └── local_setup.bash
└── log/                    # 构建日志
```

使用工作空间：

```bash
# 在新的 shell 中加载工作空间环境
source ~/ros2_ws/install/setup.bash

# 运行节点
ros2 run rm_vision detector_node

# 使用 launch 文件
ros2 launch rm_vision vision_launch.py
```

上面的目录树是默认的隔离安装布局；使用 `--merge-install` 时会不同。构建成功只表明各构建步骤返回成功，运行节点前还要确认 underlay/overlay 的 source 顺序、运行时库、资源文件和中间件配置。

==== `--symlink-install`：开发便利选项

`--symlink-install` 会让 colcon/ament 在可行时用符号链接连接构建或源码中的文件与安装空间，而不是一律复制：

```bash
colcon build --symlink-install
```

在常见开发布局中，它可能带来这些效果：

1. 以普通文件安装的 Python、launch 或配置资源若被符号链接，源码修改可以直接反映到安装空间
2. C++ 头文件和生成物仍需按依赖重新编译，但重复复制的步骤可能减少
3. 某些文件少一份副本，具体节省量取决于安装规则

```bash
# 开发工作流
colcon build --symlink-install

# 若该 launch 文件被符号链接，保存后可直接重新运行验证
vim src/rm_vision/launch/vision_launch.py
ros2 launch rm_vision vision_launch.py

# 配置文件是否直接生效同样要检查 install 空间中的实际文件类型
vim src/rm_vision/config/params.yaml
ros2 run rm_vision detector_node

# 修改 C++ 代码 - 需要重新编译
vim src/rm_vision/src/detector_node.cpp
colcon build --symlink-install --packages-select rm_vision
```

该选项只在“可以符号链接”的安装项上生效；自定义安装脚本、生成文件和部分平台可能仍然复制。可执行文件与库的源码变化始终需要重新编译，符号链接不能替代构建。发布或打包前还应测试普通安装，因为符号链接工作空间可能掩盖遗漏的资源安装规则，也不适合作为独立分发目录。

==== 测试

ROS 2 使用 ament 的测试框架：

```cmake
if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  ament_lint_auto_find_test_dependencies()

  # 单元测试
  find_package(ament_cmake_gtest REQUIRED)
  ament_add_gtest(test_detector test/test_detector.cpp)
  target_link_libraries(test_detector PRIVATE ${PROJECT_NAME}_lib)

  # 集成测试
  find_package(launch_testing_ament_cmake REQUIRED)
  add_launch_test(test/test_integration.py)
endif()
```

运行测试：

```bash
# 构建并运行测试
colcon build
colcon test

# 查看测试结果
colcon test-result --verbose

# 只测试特定包
colcon test --packages-select rm_vision
```

相应的 `package.xml` 要声明 `ament_lint_auto`、实际启用的 lint 集合、`ament_cmake_gtest` 和 `launch_testing_ament_cmake` 等 `test_depend`。`colcon test` 运行已构建测试并记录结果；命令成功覆盖的是本次发现并执行的测试集合，不能证明未注册、被条件关闭或依赖外部硬件的路径已经验证。

==== 完整示例：视觉节点的 CMakeLists.txt

下面用一个较完整的视觉包配置串联前面的接口生成、组件、安装、测试和导出规则：

```cmake
cmake_minimum_required(VERSION 3.8)
project(rm_vision LANGUAGES CXX)

function(rm_enable_warnings target)
  if(CMAKE_CXX_COMPILER_ID MATCHES "^(GNU|AppleClang|Clang)$")
    target_compile_options(${target} PRIVATE -Wall -Wextra -Wpedantic)
  endif()
endfunction()

#=============================================================================
# 依赖
#=============================================================================

# ROS 2 核心
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(rclcpp_components REQUIRED)

# 消息类型
find_package(std_msgs REQUIRED)
find_package(sensor_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(visualization_msgs REQUIRED)

# 图像处理
find_package(cv_bridge REQUIRED)
find_package(image_transport REQUIRED)
find_package(ament_index_cpp REQUIRED)

# 坐标变换
find_package(tf2 REQUIRED)
find_package(tf2_ros REQUIRED)
find_package(tf2_geometry_msgs REQUIRED)

# 非 ROS 依赖
find_package(OpenCV REQUIRED COMPONENTS core imgproc dnn)
find_package(Eigen3 CONFIG REQUIRED)

# 这个示例使用常见 OpenCV Config 包提供的具体目标。
# 若目标发行版只提供变量，需要按该包接口另行适配。
foreach(opencv_target IN ITEMS opencv_core opencv_imgproc opencv_dnn)
  if(NOT TARGET ${opencv_target})
    message(FATAL_ERROR "Required OpenCV target is missing: ${opencv_target}")
  endif()
endforeach()

#=============================================================================
# 自定义消息
#=============================================================================

find_package(rosidl_default_generators REQUIRED)

rosidl_generate_interfaces(${PROJECT_NAME}
  "msg/Armor.msg"
  "msg/ArmorArray.msg"
  "msg/AimInfo.msg"
  DEPENDENCIES std_msgs geometry_msgs
)

# 获取类型支持目标
rosidl_get_typesupport_target(cpp_typesupport_target
  ${PROJECT_NAME} rosidl_typesupport_cpp)

#=============================================================================
# 核心库
#=============================================================================

add_library(${PROJECT_NAME}_core SHARED
  src/detector/armor_detector.cpp
  src/detector/number_classifier.cpp
  src/tracker/armor_tracker.cpp
  src/tracker/kalman_filter.cpp
  src/solver/ballistic_solver.cpp
)
target_compile_features(${PROJECT_NAME}_core PUBLIC cxx_std_17)
rm_enable_warnings(${PROJECT_NAME}_core)

target_include_directories(${PROJECT_NAME}_core PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:include>
)

target_link_libraries(${PROJECT_NAME}_core
  PUBLIC
    Eigen3::Eigen
    opencv_core
    opencv_imgproc
  PRIVATE
    opencv_dnn
)

#=============================================================================
# 节点组件
#=============================================================================

# 检测节点
add_library(detector_component SHARED
  src/nodes/detector_node.cpp
)
target_compile_features(detector_component PRIVATE cxx_std_17)
rm_enable_warnings(detector_component)

target_include_directories(detector_component PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_link_libraries(detector_component
  PRIVATE
  ${PROJECT_NAME}_core
  "${cpp_typesupport_target}"
)

ament_target_dependencies(detector_component
  rclcpp
  rclcpp_components
  sensor_msgs
  cv_bridge
  image_transport
  ament_index_cpp
)

rclcpp_components_register_node(detector_component
  PLUGIN "rm_vision::DetectorNode"
  EXECUTABLE detector_node
)

# 跟踪节点
add_library(tracker_component SHARED
  src/nodes/tracker_node.cpp
)
target_compile_features(tracker_component PRIVATE cxx_std_17)
rm_enable_warnings(tracker_component)

target_include_directories(tracker_component PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_link_libraries(tracker_component
  PRIVATE
  ${PROJECT_NAME}_core
  "${cpp_typesupport_target}"
)

ament_target_dependencies(tracker_component
  rclcpp
  rclcpp_components
  tf2_ros
  tf2_geometry_msgs
  visualization_msgs
)

rclcpp_components_register_node(tracker_component
  PLUGIN "rm_vision::TrackerNode"
  EXECUTABLE tracker_node
)

# 瞄准控制节点
add_library(aim_component SHARED
  src/nodes/aim_node.cpp
)
target_compile_features(aim_component PRIVATE cxx_std_17)
rm_enable_warnings(aim_component)

target_include_directories(aim_component PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_link_libraries(aim_component
  PRIVATE
  ${PROJECT_NAME}_core
  "${cpp_typesupport_target}"
)

ament_target_dependencies(aim_component
  rclcpp
  rclcpp_components
  geometry_msgs
  tf2_ros
)

rclcpp_components_register_node(aim_component
  PLUGIN "rm_vision::AimNode"
  EXECUTABLE aim_node
)

#=============================================================================
# 安装
#=============================================================================

# 安装头文件
install(DIRECTORY include/
  DESTINATION include
)

# 安装并导出供其他包使用的核心库
install(TARGETS ${PROJECT_NAME}_core
  EXPORT export_${PROJECT_NAME}
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
  INCLUDES DESTINATION include
)

# 组件库由插件索引加载，不作为本示例的公共开发接口导出
install(TARGETS
  detector_component
  tracker_component
  aim_component
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
)

# 安装 launch 文件
install(DIRECTORY launch/
  DESTINATION share/${PROJECT_NAME}/launch
)

# 安装配置文件
install(DIRECTORY config/
  DESTINATION share/${PROJECT_NAME}/config
)

# 安装模型文件
install(DIRECTORY models/
  DESTINATION share/${PROJECT_NAME}/models
)

#=============================================================================
# 测试
#=============================================================================

if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  ament_lint_auto_find_test_dependencies()

  find_package(ament_cmake_gtest REQUIRED)

  ament_add_gtest(test_detector test/test_detector.cpp)
  target_compile_features(test_detector PRIVATE cxx_std_17)
  target_link_libraries(test_detector PRIVATE ${PROJECT_NAME}_core)
  rm_enable_warnings(test_detector)

  ament_add_gtest(test_tracker test/test_tracker.cpp)
  target_compile_features(test_tracker PRIVATE cxx_std_17)
  target_link_libraries(test_tracker PRIVATE ${PROJECT_NAME}_core)
  rm_enable_warnings(test_tracker)
endif()

#=============================================================================
# 导出
#=============================================================================

ament_export_targets(export_${PROJECT_NAME} HAS_LIBRARY_TARGET)
ament_export_dependencies(
  OpenCV
  Eigen3
  rosidl_default_runtime
)

# 注册前面的安装与导出信息，并生成包配置
ament_package()
```

对应的 package.xml：

```xml
<?xml version="1.0"?>
<?xml-model href="http://download.ros.org/schema/package_format3.xsd" schematypens="http://www.w3.org/2001/XMLSchema"?>
<package format="3">
  <name>rm_vision</name>
  <version>2.0.0</version>
  <description>RoboMaster Vision System for ROS 2</description>
  <maintainer email="rm_team@example.com">RM Team</maintainer>
  <license>MIT</license>

  <buildtool_depend>ament_cmake</buildtool_depend>
  <buildtool_depend>rosidl_default_generators</buildtool_depend>

  <depend>rclcpp</depend>
  <depend>rclcpp_components</depend>
  <depend>std_msgs</depend>
  <depend>sensor_msgs</depend>
  <depend>geometry_msgs</depend>
  <depend>visualization_msgs</depend>
  <depend>cv_bridge</depend>
  <depend>image_transport</depend>
  <depend>tf2</depend>
  <depend>tf2_ros</depend>
  <depend>tf2_geometry_msgs</depend>
  <depend>ament_index_cpp</depend>

  <depend>libopencv-dev</depend>
  <depend>eigen</depend>

  <exec_depend>rosidl_default_runtime</exec_depend>
  <exec_depend>launch</exec_depend>
  <exec_depend>launch_ros</exec_depend>
  <exec_depend>ament_index_python</exec_depend>

  <test_depend>ament_lint_auto</test_depend>
  <test_depend>ament_lint_common</test_depend>
  <test_depend>ament_cmake_gtest</test_depend>

  <member_of_group>rosidl_interface_packages</member_of_group>

  <export>
    <build_type>ament_cmake</build_type>
  </export>
</package>
```

这个综合示例把以下内容放在同一个包中：

- 自定义消息类型
- 核心算法库
- 多个组件化节点
- 目标级依赖与类型支持链接
- 资源、组件库和公共核心库的安装
- 测试支持
- 目标式库导出

示例假设公共核心头文件暴露 Eigen、`opencv_core` 和 `opencv_imgproc` 类型，因此导出这些依赖，而 DNN 只用于实现；实际头文件边界不同就要调整可见性。它还假设目标 ROS 2/OpenCV 安装提供文中使用的宏和具体 OpenCV 目标。本段没有配套源码可供完整构建，因而是配置结构示例，不是已经通过编译的包。实际采用这份结构时，至少要在目标发行版中运行 `rosdep`、colcon 构建与测试，并从另一个包实际链接导出的核心目标。


=== 常见问题与调试
// CMake 疑难解答
// - “找不到包”：CMAKE_PREFIX_PATH
// - “未定义的引用”：链接顺序问题
// - “头文件找不到”：include 路径
// - “ABI 不兼容”：编译器版本不匹配
// - 查看详细信息：cmake --debug-find
// - 打印变量：message(STATUS ${VAR})
// - 检查实际编译与链接命令：cmake --build --verbose
// - CMake 最低版本的选择
// - 常见的 CMake 反模式
// - 目标式 CMake 检查清单与综合模板
// === 常见问题与调试

构建问题通常跨越配置、生成、编译、链接、加载和运行几个阶段。先记录失败命令与原始错误，再判断它属于哪个阶段；不要仅凭一条相似报错直接套用结论。本节用几个常见现象说明如何缩小范围，并在末尾给出一份目标式 CMake 检查清单。

==== “找不到包”问题

Config 模式没有找到合适包时，常见错误如下：

```
CMake Error at CMakeLists.txt:10 (find_package):
  Could not find a package configuration file provided by "OpenCV" with any
  of the following names:

    OpenCVConfig.cmake
    opencv-config.cmake

  Add the installation prefix of "OpenCV" to CMAKE_PREFIX_PATH or set
  "OpenCV_DIR" to a directory containing one of the above files.
```

这条消息只说明本次搜索没有选中可满足请求的 Config 文件。包可能尚未安装，也可能只安装了运行库而没有开发文件；还可能是版本/组件不满足、前缀或 sysroot 错误、包名大小写不符，或者旧构建目录缓存了另一条路径。

可以按以下顺序核对：

1. 确认当前工具看到的元数据。pkg-config 与 CMake Config 是两套接口，因此 pkg-config 成功只能说明一个线索：
```bash
# 查看 pkg-config 元数据（若该安装提供）
pkg-config --modversion opencv4

# Debian/Ubuntu 上查看开发包安装清单
dpkg -L libopencv-dev | rg 'OpenCVConfig\.cmake$'
```

2. 设置 `CMAKE_PREFIX_PATH`：
```bash
cmake -S . -B build \
      -DCMAKE_PREFIX_PATH="/opt/opencv;/opt/eigen"
```

3. 设置库特定的 `_DIR` 变量：
```bash
cmake -S . -B build \
      -DOpenCV_DIR=/opt/opencv/lib/cmake/opencv4
```

4. 对于 ROS 2，在新 shell 中先加载发行版 underlay；若当前工作空间依赖另一个已经构建的 overlay，再加载那个 overlay，然后由 colcon 构建：
```bash
source /opt/ros/jazzy/setup.bash
cd ~/ros2_ws
colcon build --packages-select rm_vision

# 构建完成后，运行前加载当前工作空间
source install/setup.bash
```

5. 使用 `--debug-find` 查看详细搜索过程：
```bash
cmake -S . -B build --debug-find
```

输出较多时，可在所用 CMake 版本支持的情况下改用 `--debug-find-pkg=OpenCV`，或用 `--debug-find-var=OpenCV_DIR` 聚焦变量。交叉编译还应同时检查工具链文件的 sysroot、`CMAKE_FIND_ROOT_PATH` 和相应模式变量，避免修复主机搜索却破坏目标平台搜索。

*常见陷阱*：

- 包名大小写敏感：`find_package(OpenCV)` 不同于 `find_package(opencv)`
- 有些包名与库名不同：Eigen 的包名是 `Eigen3` 而不是 `Eigen`
- 多版本共存时可能选中不符合预期的版本：查看 `OpenCV_DIR` 缓存值和 debug-find 路径，再决定是调整前缀、版本请求还是使用新的构建目录

==== “未定义的引用”问题

链接错误通常表现为：

```
/usr/bin/ld: main.cpp:(.text+0x15): undefined reference to `MyClass::DoSomething()'
collect2: error: ld returned 1 exit status
```

这个观察表示最终链接步骤有一个未解析符号。定义可能没有进入任何输入文件，也可能因签名、语言链接、可见性、条件编译、静态库扫描顺序或 ABI 名称不同而无法匹配。

*常见原因和解决方案*：

1. 忘记链接库：
```cmake
# 错误：没有链接库
add_executable(app main.cpp)

# 正确：链接库
add_executable(app main.cpp)
target_link_libraries(app PRIVATE mylib)
```

2. 静态库依赖没有由各目标声明。与其在应用处手排所有库，优先让每个库表达直接关系：
```cmake
target_link_libraries(libB PRIVATE libC)
target_link_libraries(libA PRIVATE libB)
target_link_libraries(app PRIVATE libA)
```

传统 Unix 链接器通常从左到右扫描 archive，循环静态依赖可能因此暴露顺序问题。长期修复是拆开循环；CMake 3.24 及以后、且工具链支持时，可以显式请求重新扫描组：

```cmake
target_link_libraries(app PRIVATE "$<LINK_GROUP:RESCAN,libA,libB>")
```

3. 忘记编译某个源文件：
```cmake
# 错误：漏掉了 myclass.cpp
add_library(mylib utils.cpp)

# 正确：包含所有源文件
add_library(mylib utils.cpp myclass.cpp)
```

4. 声明和定义的签名不一致：
```cpp
// header.h
void DoSomething(int x);

// source.cpp - 参数类型不匹配！
void DoSomething(double x) { ... }
```

5. C API 头文件没有为 C++ 调用者声明 C 语言链接。通常在头文件自身处理：
```cpp
#ifdef __cplusplus
extern "C" {
#endif

void c_library_run(int mode);

#ifdef __cplusplus
}
#endif
```

6. 模板实例化问题：
```cpp
// 常见做法是在头文件中提供模板定义；若放在 .cpp 中，
// 必须为实际使用的类型提供显式实例化定义。
template class Buffer<float>;
```

*调试技巧*：

```bash
# 先查看 CMake 实际传给链接器的目标和顺序
cmake --build build --verbose

# 查看库是否定义目标符号
nm -C --defined-only build/libmylib.a | rg 'DoSomething'

# 查看可执行文件需要的符号
nm -C -u build/app | rg 'DoSomething'

# 使用 c++filt 解码符号名
echo "_ZN7MyClass11DoSomethingEv" | c++filt
```

看到同名的解码符号仍不一定足够：共享库中的符号还可能被隐藏、带有不同版本，或来自错误架构。可以继续用 `readelf -Ws`/`objdump -T` 检查动态符号表，并把报错中的原始修饰名与库中定义逐字比较。只有确认正确文件进入链接命令、目标符号存在且名称/可见性匹配后，才能排除这些分支。

==== “头文件找不到”问题

编译错误通常表现为：

```
fatal error: opencv2/core.hpp: No such file or directory
    #include <opencv2/core.hpp>
             ^~~~~~~~~~~~~~~~~~
compilation terminated.
```

这说明当前源文件的编译命令没有在有效搜索目录中找到该拼写的头文件。可能是开发包未安装、包含路径没有进入目标、可见性写错、路径大小写不符，也可能选中了另一套 sysroot 或包版本。

*解决方案*：

1. 检查 `target_include_directories`：
```cmake
target_include_directories(myapp PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

find_package(OpenCV REQUIRED COMPONENTS core)
target_include_directories(myapp SYSTEM PRIVATE
    ${OpenCV_INCLUDE_DIRS}
)
target_link_libraries(myapp PRIVATE ${OpenCV_LIBS})
```

2. 包提供导入目标时，使用其真实目标名取得使用要求。例如 Eigen3 的常见 Config 包提供：
```cmake
find_package(Eigen3 CONFIG REQUIRED)
target_link_libraries(myapp PRIVATE Eigen3::Eigen)
```

不要根据包名自行拼接 `OpenCV::OpenCV`；许多 OpenCV 安装并没有这个目标。应使用该 OpenCV 包实际提供的变量或具体目标。

3. 检查头文件实际位置：
```bash
# Debian/Ubuntu：查看开发包把头文件安装到哪里
dpkg -L libopencv-dev | rg '/opencv2/core\.hpp$'

# 查看包的 include 路径
pkg-config --cflags opencv4
```

4. 检查 PUBLIC/PRIVATE 是否正确：
```cmake
# 如果 mylib 的公共头文件由 myapp 包含，就向下游传递构建/安装路径
target_include_directories(mylib PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)
```

*调试技巧*：

```bash
# 查看实际编译命令，确认失败源文件对应的 -I/-isystem 参数
cmake --build build --verbose

# Ninja/Makefile 等生成器可导出逐源文件命令
cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
```

目录出现在某个 CMake 变量中不等于它已经进入失败源文件的编译命令；生成器表达式、配置和传递接口都可能改变最终结果。以 verbose 输出或 `compile_commands.json` 中该源文件的实际命令为准。

==== “ABI 不兼容”问题

共享库加载失败有时会直接报告缺失符号：

```
symbol lookup error: ./app: undefined symbol: _ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1Ev

```

普通的 `Segmentation fault` 本身不能诊断为 ABI 问题；越界、悬空指针、数据竞争等都能产生同样现象。即使错误包含 `undefined symbol`，也要区分“加载了错误库版本”“符号不可见/不存在”和“调用方与库采用不兼容 ABI”等情况。

可能影响二进制接口的因素包括：

- C++ 标准库及其 ABI 模式不同，例如 libstdc++ 与 libc++，或 `_GLIBCXX_USE_CXX11_ABI` 不一致
- 目标架构、位数、编译器运行库、结构体对齐/打包、异常或 RTTI 选项不一致
- Windows 上混用不兼容的 MSVC 运行库或 Debug/Release 迭代器 ABI
- 头文件版本与运行时实际加载的共享库版本不一致

编译器版本不同只是线索：不少 GCC 版本之间保持了既定 ABI，不能看到版本号不同就确认根因。可以先收集以下证据：

1. 确认产物架构以及运行时实际加载的库：
```bash
file build/app /path/to/libmylib.so
ldd build/app
readelf -d build/app | rg 'NEEDED|RPATH|RUNPATH'
```

2. 比较调用方需要的符号和库实际导出的符号/版本：
```bash
readelf -Ws build/app | rg 'UND|MyClass'
readelf -Ws /path/to/libmylib.so | rg 'MyClass'
objdump -T /path/to/libmylib.so | rg 'GLIBCXX|MyClass'
```

3. 若要比较另一套编译器或 ABI 选项，使用新的构建目录，不在已有缓存中切换编译器：
```bash
cmake -S . -B build-gcc11 \
      -DCMAKE_C_COMPILER=/usr/bin/gcc-11 \
      -DCMAKE_CXX_COMPILER=/usr/bin/g++-11
cmake --build build-gcc11 --verbose
```

4. 用目标接口表达确实属于公共 ABI 的编译要求：
```cmake
target_compile_features(mylib PUBLIC cxx_std_17)
target_compile_definitions(mylib PUBLIC MYLIB_ABI_LEVEL=2)
```

语言标准一致并不能保证 ABI 一致，反过来，编译器小版本不同也不必然不兼容。只有在确认运行时加载路径正确、符号版本/架构等主要替代解释不成立，并通过使用同一工具链重建或切换单一 ABI 选项使问题可重复消失后，才有证据把故障归因到相应 ABI 差异。

==== 查看详细调试信息

CMake 提供了多种方式来获取调试信息：

*`cmake --debug-find`*：

```bash
# 显示 find_package 的详细搜索过程
cmake -S . -B build --debug-find

# 输出类似：
# find_package considered the following locations for OpenCV's Config module:
#   /usr/lib/cmake/opencv4/OpenCVConfig.cmake
#   ...
```

*`cmake --trace`*：

```bash
# 显示每条 CMake 命令的执行
cmake -S . -B build --trace-expand

# 只追踪特定文件
cmake -S . -B build --trace-expand --trace-source=CMakeLists.txt
```

*message 打印变量*：

```cmake
# 打印变量值
message(STATUS "OpenCV_VERSION: ${OpenCV_VERSION}")
message(STATUS "OpenCV_INCLUDE_DIRS: ${OpenCV_INCLUDE_DIRS}")
message(STATUS "OpenCV_LIBS: ${OpenCV_LIBS}")

# 按变量中保存的列表逐项打印
foreach(lib IN LISTS OpenCV_LIBS)
    message(STATUS "  - ${lib}")
endforeach()

# 打印目标属性
get_target_property(inc mylib INCLUDE_DIRECTORIES)
message(STATUS "mylib includes: ${inc}")

# 项目自定义开关要先声明，不能假定存在名为 CMAKE_DEBUG 的内置变量
option(RM_CMAKE_DEBUG "Print project CMake diagnostics" OFF)
if(RM_CMAKE_DEBUG)
    message(STATUS "Debug: ${SOME_VAR}")
endif()
```

`INCLUDE_DIRECTORIES` 和 `LINK_LIBRARIES` 主要显示目标直接记录的属性，可能仍包含生成器表达式，也不等于某个配置下完全展开的传递结果。需要最终命令时继续查看构建后端输出。

*查看编译命令*：

```bash
# CMake 通用方式
cmake --build build --verbose

# 为支持该功能的生成器生成 compile_commands.json
cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
# 由 clangd、IDE 或分析工具读取 build/compile_commands.json
```

*查看缓存*：

```bash
# 只查看已有构建目录，不重新执行配置
cmake -N -LAH build

# 查看特定变量
rg '^OpenCV' build/CMakeCache.txt
```

`--trace-expand` 和 `--debug-find` 可能产生大量输出，并暴露本机绝对路径。先限制包、变量或源文件范围，保存原始失败命令，再比较修改前后的搜索与生成结果；日志变多本身不会提高诊断可信度。

==== CMake 最低版本的选择

最低版本应由两项可核对的事实决定：项目实际使用的最晚 CMake 功能/策略，以及承诺支持的最旧环境中能提供的 CMake 版本。

*声明低于代码实际需求*：

- 无法使用新特性
- 新版 CMake 会为较新的未设置策略给出警告，脚本行为也可能落在旧策略分支
- 使用者直到执行到某个未知命令或参数时才失败，错误位置远离版本声明

*无依据地提高声明*：

- 老系统的用户无法构建
- 缩小了项目声称支持的环境范围，却未必换来任何实际功能或修复

例如，一个确实使用 CMake 3.20 功能、并在 3.20 与当前 CI 版本测试的项目，可以从下面开始：

```cmake
cmake_minimum_required(VERSION 3.20)
```

可选的版本范围（CMake 3.12+）把最低可运行版本和已审查的策略上限分开：

```cmake
cmake_minimum_required(VERSION 3.20...3.28)
```

这里的 `3.28` 不是“最高允许版本”；它表示脚本按截至 3.28 引入的策略采用 `NEW` 行为，更晚策略仍保持未设置并可能警告。只有在相应版本上审查过策略与构建结果时才写这个上限。ROS 2 项目也应以目标发行版的模板、安装环境和所用宏为准，不能从发行版名称推导一个统一最低值。

*各版本引入的重要特性*：

- *3.0*：目标 INTERFACE 属性、生成器表达式
- *3.1*：`target_compile_features`
- *3.8*：C++17 支持
- *3.11*：`FetchContent` 模块
- *3.12*：`CONFIGURE_DEPENDS` for GLOB
- *3.13*：`target_link_options`
- *3.14*：`FetchContent_MakeAvailable`
- *3.16*：`target_precompile_headers`、Unity Build 属性
- *3.19*：CMake Presets
- *3.20*：`cxx_std_23` 元特性
- *3.23*：目标头文件集（`FILE_SET HEADERS`）
- *3.24*：`cmake --fresh`、`LINK_GROUP` 生成器表达式

这份列表只用于定位本章示例，不是完整变更日志；最终应以目标 CMake 版本的命令帮助和官方文档核对参数。

==== 常见的高风险写法

以下写法并非在所有场景都非法，但容易扩大作用域、隐藏依赖或制造环境差异。修改前先确认项目是否有明确的工具链或兼容性理由。

*风险 1：无意使用目录级全局命令*

```cmake
# 影响当前目录以及随后处理的子目录
include_directories(${SOME_INCLUDE_DIR})
link_libraries(somelib)
add_definitions(-DSOME_MACRO)

# 目标级写法明确作用范围
target_include_directories(myapp PRIVATE ${SOME_INCLUDE_DIR})
target_link_libraries(myapp PRIVATE somelib)
target_compile_definitions(myapp PRIVATE SOME_MACRO)
```

工具链文件或项目统一策略有时确实需要较宽范围，但普通库不应把自身警告和宏静默施加给无关目标或第三方源码。

*风险 2：拼接 `CMAKE_CXX_FLAGS`*

```cmake
# 全局字符串容易与用户、配置和工具链标志纠缠
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra")

# 同时按编译器限制选项
target_compile_options(myapp PRIVATE
    $<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:-Wall>
    $<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:-Wextra>
    $<$<CXX_COMPILER_ID:MSVC>:/W4>
)
```

*风险 3：用普通 `file(GLOB)` 隐式决定目标源文件*

```cmake
# 没有 CONFIGURE_DEPENDS 时，新匹配文件通常不会触发重新配置
file(GLOB SOURCES "src/*.cpp")
add_library(mylib ${SOURCES})

# 显式列表便于审查目标成员
add_library(mylib
    src/file1.cpp
    src/file2.cpp
    src/file3.cpp
)
```

如果文件集合本来就由目录模式定义，可以审慎使用 `GLOB CONFIGURE_DEPENDS`，并在支持的生成器和文件系统上验证扫描行为；`aux_source_directory` 也没有自动变化跟踪优势。

*风险 4：省略链接接口关键字或混用两种签名*

```cmake
# 纯签名的传递语义不直观，也不能与关键字签名混用于同一目标
target_link_libraries(mylib otherlib)

# 根据头文件边界明确选择
target_link_libraries(mylib PRIVATE otherlib)
```

*风险 5：把生成文件写进源码树*

```bash
# 源外构建让源码与生成物边界明确
cmake -S my_project -B my_project/build
cmake --build my_project/build
```

已经在源码树执行过配置时，应先识别 CMake 实际生成了哪些文件再清理，不要把一条宽泛删除命令当成通用修复。CI 和 preset 也应给每个工具链或配置使用独立构建目录。

*风险 6：把开发机绝对路径写入项目接口*

```cmake
# 只在一台机器的特定目录成立
target_include_directories(myapp PRIVATE /home/user/libs/include)

# 让调用者通过前缀、工具链或包管理器提供位置
find_package(SomeLib REQUIRED)
target_link_libraries(myapp PRIVATE SomeLib::SomeLib)
```

受控 SDK 的固定布局有时不可避免，也应把根目录做成缓存变量或工具链输入，并在配置时检查架构与文件，而不是把个人主目录嵌入源码或导出包。

*风险 7：假定所有包都提供同一种目标命名*

```cmake
# 许多 OpenCV 包提供变量，但不提供 OpenCV::OpenCV
find_package(OpenCV REQUIRED COMPONENTS core imgproc)
target_include_directories(myapp SYSTEM PRIVATE ${OpenCV_INCLUDE_DIRS})
target_link_libraries(myapp PRIVATE ${OpenCV_LIBS})

# Eigen3 的常见 Config 包则提供真实导入目标
find_package(Eigen3 CONFIG REQUIRED)
target_link_libraries(myapp PRIVATE Eigen3::Eigen)
```

导入目标通常比手工变量更完整，但前提是包确实提供并正确填充它。判断依据是该版本包文档和 `if(TARGET ...)`，不是目标名看起来是否“现代”。

*风险 8：把可选查找结果当成必然存在*

```cmake
# 未找到时变量可能展开为空，错误会推迟到后续阶段
find_package(SomeLib)
target_link_libraries(myapp PRIVATE ${SomeLib_LIBRARIES})

# 必需依赖直接声明 REQUIRED
find_package(SomeLib REQUIRED)

# 可选依赖检查后续真正需要的目标
find_package(OptionalLib QUIET CONFIG)
if(TARGET OptionalLib::OptionalLib)
    target_link_libraries(myapp PRIVATE OptionalLib::OptionalLib)
    target_compile_definitions(myapp PRIVATE HAS_OPTIONAL_LIB=1)
else()
    target_compile_definitions(myapp PRIVATE HAS_OPTIONAL_LIB=0)
endif()
```

==== 一份可审查的目标式模板

不存在适合所有项目的固定模板。下面假设项目使用 CMake 3.20、构建一个共享库、公共头文件暴露 Eigen 类型，而 OpenCV 与 fmt 只用于实现。每一项可见性和依赖导出都由这些假设推出，实际 API 不同就要修改。

*项目设置*：

```cmake
# 最低版本与本模板使用的功能一致
cmake_minimum_required(VERSION 3.20)

# 声明项目信息
project(MyProject
    VERSION 1.0.0
    DESCRIPTION "Example target-based CMake project"
    LANGUAGES CXX
)

# 本项目选择不支持源内构建
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR)
    message(FATAL_ERROR "In-source builds are not allowed")
endif()

# Ninja/Makefile 等支持的生成器可导出编译命令
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
```

模板不强制把空的 `CMAKE_BUILD_TYPE` 改成 Release，也不覆盖用户缓存；单配置/多配置选择可以放在文档和 preset 中显式表达。

*目标定义*：

```cmake
# 创建库
add_library(mylib SHARED
    src/file1.cpp
    src/file2.cpp
)

# 创建别名（便于内部使用一致的命名）
add_library(MyProject::mylib ALIAS mylib)

# 设置目标属性
target_include_directories(mylib
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
)

target_compile_features(mylib PUBLIC cxx_std_17)

target_compile_options(mylib PRIVATE
    $<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:-Wall>
    $<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:-Wextra>
    $<$<CXX_COMPILER_ID:MSVC>:/W4>
)
```

*依赖管理*：

```cmake
# 公共头文件使用 Eigen；实现使用 OpenCV
find_package(Eigen3 CONFIG REQUIRED)
find_package(OpenCV REQUIRED COMPONENTS core imgproc)

target_include_directories(mylib SYSTEM PRIVATE ${OpenCV_INCLUDE_DIRS})
target_link_libraries(mylib
    PUBLIC Eigen3::Eigen
    PRIVATE ${OpenCV_LIBS}
)

# 只有用户显式启用时才要求 CUDA Toolkit，避免不同机器静默选择不同后端
option(MYPROJECT_ENABLE_CUDA "Build the CUDA runtime backend" OFF)
if(MYPROJECT_ENABLE_CUDA)
    find_package(CUDAToolkit REQUIRED)
    target_compile_definitions(mylib PRIVATE MYPROJECT_HAS_CUDA=1)
    target_link_libraries(mylib PRIVATE CUDA::cudart)
else()
    target_compile_definitions(mylib PRIVATE MYPROJECT_HAS_CUDA=0)
endif()

# fmt 是必需依赖，但是否允许配置期联网由调用者决定
option(MYPROJECT_FETCH_FMT "Fetch fmt when no installed package is found" OFF)
find_package(fmt QUIET CONFIG)
if(NOT TARGET fmt::fmt AND MYPROJECT_FETCH_FMT)
    include(FetchContent)
    FetchContent_Declare(fmt
        GIT_REPOSITORY https://github.com/fmtlib/fmt.git
        GIT_TAG 10.1.1
    )
    FetchContent_MakeAvailable(fmt)
endif()
if(NOT TARGET fmt::fmt)
    message(FATAL_ERROR "Install fmt or configure with MYPROJECT_FETCH_FMT=ON")
endif()
target_link_libraries(mylib PRIVATE fmt::fmt)
```

严格复现时应把示例发布标签替换为核验过的完整提交或带摘要归档，并为离线环境准备来源。若 `mylib` 改为静态库，或公共头文件暴露 OpenCV/fmt 类型，安装包需要恢复的接口依赖也会变化。

*安装和导出*：

```cmake
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)
set(MyProject_INSTALL_CMAKEDIR
    "${CMAKE_INSTALL_LIBDIR}/cmake/MyProject")

# 安装目标
install(TARGETS mylib
    EXPORT MyProjectTargets
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

# 安装头文件
install(DIRECTORY include/
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

# 导出目标
install(EXPORT MyProjectTargets
    FILE MyProjectTargets.cmake
    NAMESPACE MyProject::
    DESTINATION "${MyProject_INSTALL_CMAKEDIR}"
)

# 生成配置文件
configure_package_config_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/MyProjectConfig.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/MyProjectConfig.cmake"
    INSTALL_DESTINATION "${MyProject_INSTALL_CMAKEDIR}"
)

write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/MyProjectConfigVersion.cmake"
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)

install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/MyProjectConfig.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/MyProjectConfigVersion.cmake"
    DESTINATION "${MyProject_INSTALL_CMAKEDIR}"
)
```

对应的 `cmake/MyProjectConfig.cmake.in` 至少恢复公开的 Eigen 目标再加载导出集：

```cmake
@PACKAGE_INIT@

include(CMakeFindDependencyMacro)
find_dependency(Eigen3 CONFIG)

include("${CMAKE_CURRENT_LIST_DIR}/MyProjectTargets.cmake")
check_required_components(MyProject)
```

这里把 OpenCV、fmt，以及启用 `MYPROJECT_ENABLE_CUDA` 时的 CUDA 都声明为 `PRIVATE` 实现依赖，因此它们没有进入 `mylib` 导出的 CMake 使用接口。不过，`PRIVATE` 只说明依赖不向下游目标公开，不能据此断定最终一定动态链接：实际结果还取决于这些包提供的目标、库类型和当前构建配置。部署前应检查生成库记录的动态依赖；确实被动态链接的 `.so`，才需要由运行环境或系统包一并提供。`SameMajorVersion` 与 `SOVERSION` 代表兼容承诺，不应在没有跨版本测试时机械照搬。

#block(breakable: false)[
*测试*：

```cmake
# 使用 BUILD_TESTING 控制测试构建
include(CTest)

if(BUILD_TESTING)
    find_package(GTest REQUIRED)

    add_executable(mylib_test test/test_mylib.cpp)
    target_link_libraries(mylib_test PRIVATE
        mylib
        GTest::gtest_main
    )

    include(GoogleTest)
    gtest_discover_tests(mylib_test)
endif()
```
]

配置完成后还要实际运行 `ctest --test-dir build --output-on-failure`；测试目标存在或成功编译不等于测试已经执行。

*一种对应的项目结构*：

```
my_project/
├── CMakeLists.txt              # 顶层配置
├── cmake/                      # CMake 模块
│   ├── MyProjectConfig.cmake.in
│   └── CompilerWarnings.cmake
├── include/my_project/         # 公开头文件
├── src/                        # 源文件和私有头文件
├── apps/                       # 可执行文件
├── tests/                      # 测试
└── docs/                       # 文档
```

这份模板的重点是让每项要求有明确归属：目标自身需要什么，公共头文件把什么传给下游，安装包又必须恢复哪些目标。它不能单独证明跨平台、ABI 或依赖版本兼容。完成项目配置后，应在声明支持的生成器和工具链上依次验证配置、构建、测试、暂存安装，以及由独立消费项目执行的 `find_package` 和链接流程。
