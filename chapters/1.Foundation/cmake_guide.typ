
=== 为什么需要构建系统
// 引言：从手动编译到自动化构建
// - 一个文件时：g++ main.cpp -o main
// - 十个文件时：命令变得冗长
// - 一百个文件时：手动管理不可能
// - 依赖关系：哪些文件需要重新编译？
// - 跨平台问题：不同系统的编译器和路径
// - 构建系统的职责：依赖分析、增量编译、跨平台抽象
// - Make 的历史地位与局限
// - CMake：现代 C++ 项目的事实标准
// === 为什么需要构建系统

学习 C++ 的第一天，你可能写下了这样一行命令：`g++ main.cpp -o main`。编译器读取源文件，生成可执行文件，程序运行，输出 "Hello, World!"。一切都很简单直接。但随着项目规模的增长，这种简单会迅速消失。当源文件从一个变成十个、一百个，当项目开始依赖外部库，当团队成员使用不同的操作系统，手动编译就变成了一场噩梦。构建系统正是为了解决这些问题而诞生的工具，它是每个 C++ 开发者必须掌握的技能。

==== 从一个文件到一百个文件

让我们从最简单的情况开始。一个只有 `main.cpp` 的项目，编译命令是：

```bash
g++ main.cpp -o main
```

当你把代码拆分成两个文件——`main.cpp` 和 `utils.cpp`——命令变成：

```bash
g++ main.cpp utils.cpp -o main
```

这还能接受。但 RoboMaster 的视觉系统可能有几十个源文件：检测器、跟踪器、预测器、通信模块、工具函数……命令会变成这样：

```bash
g++ main.cpp detector.cpp tracker.cpp predictor.cpp protocol.cpp serial.cpp \
    config.cpp logger.cpp math_utils.cpp image_utils.cpp coordinate.cpp \
    kalman_filter.cpp armor.cpp rune.cpp ... -o rm_vision \
    -I/usr/include/opencv4 -I/usr/include/eigen3 \
    -lopencv_core -lopencv_imgproc -lopencv_highgui -lceres -lglog \
    -std=c++17 -O2 -Wall
```

这行命令已经长得难以阅读，而且每次编译都要输入一遍。你可能会想到把它保存成一个 shell 脚本，这确实是一个进步，但问题远不止于此。

更大的问题是编译效率。假设你的项目有 100 个源文件，完整编译需要 5 分钟。现在你只修改了 `tracker.cpp` 中的一行代码，难道需要重新编译全部 100 个文件吗？显然不需要——只有 `tracker.cpp` 需要重新编译，然后重新链接即可。但上面那行命令无法做到这一点，它会把所有文件从头编译一遍。在大型项目中，这种浪费是不可接受的。

要实现"只编译修改过的文件"，你需要分开编译和链接两个步骤。先把每个源文件编译成目标文件（.o），再把目标文件链接成可执行文件：

```bash
g++ -c main.cpp -o main.o
g++ -c detector.cpp -o detector.o
g++ -c tracker.cpp -o tracker.o
# ... 对每个源文件重复 ...
g++ main.o detector.o tracker.o ... -o rm_vision -lopencv_core ...
```

这样，当你修改了 `tracker.cpp`，只需要重新编译 `tracker.o`，然后重新链接。但现在你需要判断哪些文件被修改了、哪些目标文件需要更新。如果 `tracker.cpp` 包含了 `config.h`，而你修改了 `config.h`，那 `tracker.o` 也需要重新编译。如果 `detector.cpp` 和 `predictor.cpp` 也包含了 `config.h`，它们都需要重新编译。

这种依赖关系会变得非常复杂。一个头文件可能被几十个源文件包含，修改它会触发大量重新编译。手动追踪这些依赖关系是不现实的——这正是构建系统要解决的核心问题之一。

==== 依赖分析与增量编译

构建系统的首要职责是依赖分析。它会分析源文件之间的依赖关系：哪个源文件包含了哪些头文件，哪个目标文件依赖于哪些源文件，最终的可执行文件依赖于哪些目标文件和库。这些依赖关系形成一个有向无环图（DAG），构建系统根据这个图来决定构建顺序和需要更新的目标。

当你修改一个文件并请求构建时，构建系统会检查依赖图中哪些目标受到影响。它比较源文件和目标文件的修改时间：如果源文件比目标文件新，说明目标文件需要更新。这个过程会沿着依赖图传播——如果 `tracker.o` 需要更新，而可执行文件依赖于 `tracker.o`，那么可执行文件也需要重新链接。

这种"只重新构建必要部分"的策略叫做增量编译（incremental build）。在大型项目中，增量编译可以把构建时间从几分钟缩短到几秒钟，极大地提高了开发效率。每次修改代码后，你几乎可以立即看到结果，这对于快速迭代至关重要。

依赖分析还有另一个好处：并行编译。当构建系统知道了完整的依赖图，它就知道哪些目标之间没有依赖关系，可以同时编译。在多核 CPU 上，并行编译可以成倍地缩短构建时间。一个单线程需要 10 分钟的构建，在 8 核机器上可能只需要不到 2 分钟。

==== 跨平台的挑战

如果你的代码只在自己的 Ubuntu 笔记本上运行，单一平台的构建脚本或许够用。但现实往往更复杂：团队中有人用 macOS，有人用 Windows；代码可能需要部署到 Jetson 等嵌入式平台；CI 服务器可能运行着不同版本的 Linux。每个平台都有自己的编译器、路径约定、库命名规则。

在 Linux 上，C++ 编译器通常是 `g++`，库文件以 `.so` 结尾，头文件可能在 `/usr/include` 或 `/usr/local/include`。在 macOS 上，默认编译器是 `clang++`，动态库以 `.dylib` 结尾，路径规则也不同。在 Windows 上，编译器可能是 MSVC 的 `cl.exe`，库文件是 `.dll` 和 `.lib`，路径使用反斜杠，还有很多 Windows 特有的编译选项。

手动维护每个平台的构建脚本是一项繁重的工作，而且容易出错。你需要在不同平台上测试，确保脚本正确处理了所有差异。任何改动都可能在某个平台上引入问题。

好的构建系统提供跨平台抽象。你用统一的方式描述项目结构、依赖关系和编译选项，构建系统负责翻译成每个平台上的具体命令。你写一份构建配置，它在所有支持的平台上都能工作。这不仅节省了维护成本，还减少了"在我机器上能编译"这类问题。

==== Make：元老级构建工具

Make 是最早的构建工具之一，诞生于 1976 年。在接近半个世纪后的今天，它仍然被广泛使用，足见其设计的生命力。Make 使用名为 `Makefile` 的文件来描述构建规则。

一个简单的 Makefile 看起来像这样：

```makefile
CC = g++
CFLAGS = -std=c++17 -Wall -O2

main: main.o utils.o
	$(CC) main.o utils.o -o main

main.o: main.cpp utils.h
	$(CC) $(CFLAGS) -c main.cpp -o main.o

utils.o: utils.cpp utils.h
	$(CC) $(CFLAGS) -c utils.cpp -o utils.o

clean:
	rm -f *.o main
```

每条规则包含三部分：目标（target）、依赖（dependencies）和命令（commands）。`main.o: main.cpp utils.h` 表示 `main.o` 依赖于 `main.cpp` 和 `utils.h`，如果这两个文件中的任何一个比 `main.o` 新，就执行下面的命令重新编译。

Make 解决了依赖分析和增量编译的问题，在当时是巨大的进步。但随着项目规模增长，Makefile 的局限性逐渐显现。

首先，Makefile 的语法相当晦涩。制表符和空格的区别、变量展开的规则、隐式规则的行为——这些细节让很多人望而却步。一个语法错误可能导致难以理解的构建失败。

其次，跨平台支持有限。Makefile 本质上是在调用 shell 命令，而不同平台的 shell 和工具链差异很大。虽然可以用条件语句处理这些差异，但 Makefile 会变得越来越复杂。

第三，发现和链接外部库需要手动处理。你需要知道每个库的头文件路径、库文件路径、链接选项，并正确地写入 Makefile。当依赖的库更新或安装位置变化时，Makefile 也需要相应修改。

最后，大型项目的 Makefile 难以维护。当项目有数百个源文件、多个子目录、复杂的依赖关系时，Makefile 会变得庞大且难以理解。任何修改都要小心翼翼，担心破坏其他部分。

==== CMake：现代 C++ 的事实标准

CMake 诞生于 2000 年，最初是为了解决一个跨平台医学图像处理软件的构建问题。它的名字是 "Cross-platform Make" 的缩写，顾名思义，它的目标是提供跨平台的构建解决方案。

CMake 不直接构建项目，而是生成原生构建系统的配置文件。在 Linux 上，它默认生成 Makefile；在 Windows 上，可以生成 Visual Studio 项目文件或 Ninja 构建文件；在 macOS 上，可以生成 Xcode 项目或 Makefile。这种"元构建系统"的设计让 CMake 可以利用每个平台上最成熟的原生工具，同时为用户提供统一的接口。

CMake 使用名为 `CMakeLists.txt` 的文件来描述项目。与 Makefile 相比，CMake 的语法更加直观：

```cmake
cmake_minimum_required(VERSION 3.16)
project(rm_vision)

set(CMAKE_CXX_STANDARD 17)

find_package(OpenCV REQUIRED)
find_package(Eigen3 REQUIRED)

add_executable(rm_vision
    src/main.cpp
    src/detector.cpp
    src/tracker.cpp
)

target_include_directories(rm_vision PRIVATE include)
target_link_libraries(rm_vision OpenCV::OpenCV Eigen3::Eigen)
```

这段代码清晰地表达了：项目名称、C++ 标准版本、需要的外部库、源文件列表、头文件路径、链接依赖。`find_package` 会自动查找已安装的库，无需手动指定路径。`target_link_libraries` 不仅链接库文件，还会自动添加库的头文件路径和编译选项。

如今，CMake 已经成为 C++ 项目的事实标准。几乎所有主流的 C++ 库都提供 CMake 支持：OpenCV、Eigen、Ceres、PCL、gtest……ROS 2 的构建系统 ament 也是基于 CMake 的。学会 CMake，你就能构建几乎任何 C++ 项目，也能让你的项目被其他人轻松使用。

在接下来的章节中，我们将深入学习 CMake 的语法和用法。从最基本的项目配置开始，逐步涵盖多文件组织、外部库链接、安装导出，直到 ROS 2 包的构建。掌握这些知识后，你将能够为任何规模的 C++ 项目设计清晰、可维护的构建系统。


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

在前面的"程序的执行：从源码到运行"章节中，我们已经介绍过编译的基本流程。现在我们从构建系统的角度重新审视这个过程，深入理解编译的每个阶段产生什么、依赖什么，以及构建系统如何利用这些知识来优化构建过程。理解这些原理，你才能真正明白 CMake 配置背后的含义，也能在遇到编译错误时快速定位问题。

==== 四个阶段的再认识

C++ 程序的构建分为四个阶段：预处理、编译、汇编和链接。虽然我们通常用一条命令完成整个过程，但理解每个阶段的输入输出对于理解构建系统至关重要。

预处理阶段处理所有以 `#` 开头的指令。`#include` 将头文件的内容逐字插入到源文件中，`#define` 进行文本替换，`#ifdef` 等条件编译指令决定哪些代码被保留。预处理的输入是源文件（.cpp）和它包含的所有头文件（.h/.hpp），输出是一个展开后的纯 C++ 代码文件。这个输出通常不保存为文件，而是直接传递给编译器，但你可以用 `g++ -E` 查看预处理结果。

```bash
# 查看预处理结果
g++ -E main.cpp -o main.i

# main.i 可能有数万行，包含了所有展开的头文件
wc -l main.i
# 输出可能是 50000 行甚至更多
```

编译阶段将预处理后的 C++ 代码转换为汇编代码。这是最复杂的阶段，编译器要进行词法分析、语法分析、语义检查、优化等工作。编译器在这个阶段检查语法错误和类型错误，这就是为什么我们把这类错误称为"编译错误"。编译的输出是汇编代码文件（.s）。

```bash
# 查看编译生成的汇编代码
g++ -S main.cpp -o main.s
```

汇编阶段将汇编代码转换为机器码，生成目标文件（object file，.o）。汇编器的工作相对简单，基本上是汇编指令到机器指令的一一对应。目标文件包含了机器码，但还不能直接执行——函数调用和全局变量引用的地址还没有确定。

```bash
# 生成目标文件
g++ -c main.cpp -o main.o
```

链接阶段将多个目标文件和库文件合并成最终的可执行文件或库。链接器的核心工作是符号解析（找到每个符号引用的定义）和重定位（计算并填入最终地址）。链接的输出是可执行文件或库文件。

```bash
# 链接生成可执行文件
g++ main.o utils.o -o main
```

对于构建系统来说，最重要的是理解这四个阶段的依赖关系。预处理依赖于源文件和所有直接或间接包含的头文件；编译依赖于预处理的结果；汇编依赖于编译的结果；链接依赖于所有目标文件和库文件。构建系统通过追踪这些依赖，判断哪些步骤需要重新执行。

==== 编译单元

编译单元（Translation Unit）是 C++ 编译的基本单位。简单来说，一个编译单元就是一个源文件（.cpp）经过预处理后的结果——包括源文件本身的代码，加上所有被 `#include` 进来的头文件内容。

每个编译单元独立编译，生成一个目标文件。编译器在编译一个编译单元时，对其他编译单元一无所知。它只能看到当前编译单元中的代码，无法访问其他源文件中定义的函数或变量。这种隔离是有意为之的——它使得编译可以并行进行，也使得增量编译成为可能。

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

当编译 `main.cpp` 时，编译器看到 `Add(1.0, 2.0)` 这个调用。它从 `math_utils.h` 中知道 `Add` 函数的声明（参数类型和返回类型），可以检查调用是否正确，但它不知道 `Add` 函数的实现在哪里。编译器生成的目标文件中，对 `Add` 的调用被标记为"未解析的外部符号"，等待链接器来填入实际地址。

理解编译单元的独立性有几个重要意义。首先，它解释了为什么修改一个 .cpp 文件只需要重新编译这一个文件——其他编译单元不受影响。其次，它解释了为什么头文件中通常只放声明而不放定义——如果把函数定义放在头文件中，每个包含这个头文件的编译单元都会有一份定义，链接时就会出现"多重定义"错误。最后，它解释了为什么链接器是必要的——编译器无法跨编译单元解析符号引用。

==== 头文件与源文件的分工

C++ 中头文件（.h/.hpp）和源文件（.cpp）有着明确的分工，理解这种分工对于组织项目结构非常重要。

头文件的职责是提供接口声明。它告诉其他编译单元"有什么可以用"，但不提供实现细节。头文件通常包含：类的定义（成员函数的声明，不是实现）、函数声明、类型定义（typedef、using、enum）、常量声明（extern const）、模板的定义（模板比较特殊，稍后讨论）、宏定义和内联函数。

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

源文件的职责是提供实现。它定义了头文件中声明的函数和变量，包含了具体的逻辑代码。源文件通常包含：成员函数的实现、普通函数的实现、全局变量的定义、静态成员变量的定义。

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

这种分离有几个重要的好处。首先，它实现了接口与实现的分离。使用者只需要看头文件就知道如何使用，不需要关心实现细节。其次，它支持增量编译。修改实现（.cpp）只需要重新编译这一个文件；只有修改接口（.h）才需要重新编译所有使用者。第三，它减少了编译时间。如果把实现放在头文件中，每个包含它的编译单元都要编译这些实现代码。

然而，有些情况下代码必须放在头文件中。模板是最典型的例子——模板在实例化时需要看到完整的定义，而实例化发生在每个使用模板的编译单元中，因此模板的定义通常放在头文件里。内联函数也类似，因为编译器需要在调用点展开内联函数，必须能看到函数体。

```cpp
// 模板必须在头文件中定义
template <typename T>
class Stack {
public:
    void Push(const T& value) {
        data_.push_back(value);
    }
    
    T Pop() {
        T value = data_.back();
        data_.pop_back();
        return value;
    }
    
private:
    std::vector<T> data_;
};
```

==== 目标文件与符号表

目标文件是编译的直接产物，理解它的结构有助于理解链接过程和常见的链接错误。

目标文件包含几个主要部分。代码段（.text）存储编译后的机器指令。数据段（.data）存储已初始化的全局变量和静态变量。BSS 段（.bss）存储未初始化的全局变量和静态变量（只记录大小，不占用文件空间）。符号表记录了这个编译单元定义和引用的所有符号。重定位表记录了需要在链接时修正的位置。

符号（symbol）是链接器的核心概念。函数名、全局变量名、静态变量名都是符号。符号分为两类：定义的符号（这个编译单元提供了实现）和引用的符号（这个编译单元使用了，但实现在别处）。

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

你可能注意到符号名看起来很奇怪，如 `_Z3Adddd` 而不是简单的 `Add`。这是因为 C++ 支持函数重载，同名但参数不同的函数需要不同的符号名来区分。编译器通过名称修饰（name mangling）将函数名、参数类型等信息编码到符号名中。不同编译器的修饰规则可能不同，这就是为什么混用不同编译器编译的目标文件可能出问题。

```bash
# 查看解码后的符号名
nm -C main.o

# 输出：
#                  U Add(double, double)
# 0000000000000000 T main
```

==== 链接：符号解析与重定位

链接器的工作是将多个目标文件和库文件合并成一个可执行文件（或库）。这个过程包含两个核心任务：符号解析和重定位。

符号解析（symbol resolution）是将符号引用与符号定义匹配的过程。链接器扫描所有输入的目标文件，收集它们定义的符号和引用的符号。对于每个引用的符号，链接器需要找到唯一的定义。如果找不到定义，就会报"undefined reference"错误；如果找到多个定义，就会报"multiple definition"错误。

```bash
# 未定义符号错误
g++ main.o -o main
# error: undefined reference to `Add(double, double)'

# 需要链接包含 Add 定义的目标文件
g++ main.o math_utils.o -o main
```

"undefined reference" 是最常见的链接错误之一。它意味着你使用了某个函数或变量，但链接器在所有提供的目标文件和库中都找不到它的定义。常见原因包括：忘记链接某个库、忘记编译某个源文件、函数声明与定义不匹配（特别是参数类型）、C 和 C++ 混合编程时忘记 `extern "C"`。

"multiple definition" 错误意味着同一个符号在多个地方被定义。常见原因是把函数定义放在了头文件中（而这个头文件被多个源文件包含），或者同一个全局变量在多个源文件中定义。

重定位（relocation）是计算并填入符号最终地址的过程。在编译时，编译器不知道函数和变量的最终地址，只能在调用处留下占位符，并在重定位表中记录这些位置。链接器确定了每个符号的最终地址后，遍历重定位表，把占位符替换为实际地址。

链接顺序有时候很重要。链接器通常从左到右处理输入文件，当处理一个库时，只会取出能解析当前未定义符号的目标文件。如果 A 依赖 B，B 依赖 C，链接顺序应该是 `A B C`。顺序错误可能导致符号找不到。虽然现代链接器越来越智能，但在某些情况下顺序仍然重要。

```bash
# 链接顺序可能影响结果
g++ main.o -lmath -lbase    # 如果 math 依赖 base 中的符号，这个顺序是对的
g++ main.o -lbase -lmath    # 可能会出问题
```

==== 静态库与共享库

当你的项目使用外部代码时，有两种链接方式：静态链接和动态链接。理解它们的区别对于配置构建系统很重要。

静态库（static library）是目标文件的打包集合。在 Linux 上扩展名是 `.a`（archive），在 Windows 上是 `.lib`。静态库本质上就是把多个 .o 文件打包到一起，方便分发和链接。链接静态库时，链接器会从中提取需要的目标文件，把它们的代码复制到最终的可执行文件中。

```bash
# 创建静态库
ar rcs libmath.a add.o subtract.o multiply.o divide.o

# 链接静态库
g++ main.o -L. -lmath -o main
# 或者直接指定库文件
g++ main.o libmath.a -o main
```

静态链接的优点是生成的可执行文件是自包含的，不依赖外部库文件，可以直接复制到其他机器上运行。缺点是可执行文件体积较大（包含了库代码的副本），如果多个程序使用同一个库，每个程序都有一份副本，浪费磁盘空间。更重要的是，当库需要更新（如修复安全漏洞）时，所有静态链接的程序都需要重新编译。

共享库（shared library，也叫动态库）在 Linux 上扩展名是 `.so`（shared object），在 Windows 上是 `.dll`。共享库的代码不会被复制到可执行文件中，而是在程序运行时由操作系统加载。多个程序可以共享同一个库文件，节省磁盘和内存空间。

```bash
# 创建共享库
g++ -shared -fPIC -o libmath.so add.cpp subtract.cpp multiply.cpp divide.cpp

# 链接共享库
g++ main.cpp -L. -lmath -o main

# 运行时需要能找到共享库
export LD_LIBRARY_PATH=.:$LD_LIBRARY_PATH
./main
```

`-fPIC` 选项生成位置无关代码（Position Independent Code），这是共享库必需的，因为共享库会被加载到不同进程的不同地址。

共享库的优点是节省空间、便于更新（更新库文件后所有使用它的程序都会受益）。缺点是程序运行时依赖库文件的存在，如果库文件缺失或版本不兼容，程序无法运行。运行时加载库也会有一些性能开销（虽然通常很小）。

```bash
# 查看可执行文件依赖的共享库
ldd ./main

# 输出示例：
# linux-vdso.so.1
# libmath.so => ./libmath.so
# libstdc++.so.6 => /usr/lib/x86_64-linux-gnu/libstdc++.so.6
# libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6
```

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

现在我们可以解释一个重要的问题：为什么修改头文件会导致多个源文件重新编译？

回顾编译单元的概念：每个 .cpp 文件经过预处理后形成一个编译单元，预处理会把所有 `#include` 的头文件内容插入进来。因此，一个头文件实际上是多个编译单元的一部分。

假设 `config.h` 被 `detector.cpp`、`tracker.cpp` 和 `predictor.cpp` 包含。从依赖关系看：

- `detector.o` 依赖于 `detector.cpp` 和 `config.h`
- `tracker.o` 依赖于 `tracker.cpp` 和 `config.h`
- `predictor.o` 依赖于 `predictor.cpp` 和 `config.h`

当你修改 `config.h` 时，这三个目标文件都变得"过时"了，都需要重新编译。这是正确的行为——头文件中可能定义了类的布局、常量的值、宏的内容，这些都可能影响编译结果。

这种连锁反应解释了为什么应该谨慎设计头文件的包含关系。如果一个被广泛包含的头文件发生变化，可能触发大量重新编译。有几个策略可以减轻这个问题：

前向声明（forward declaration）可以减少头文件依赖。如果你只需要使用指针或引用，不需要知道类的完整定义，可以用前向声明代替包含头文件。

```cpp
// 不好：包含了完整的头文件
#include "robot.h"

class Controller {
    Robot* robot_;  // 只用了指针
};

// 好：使用前向声明
class Robot;  // 前向声明

class Controller {
    Robot* robot_;  // 只用了指针，不需要完整定义
};
```

Pimpl（Pointer to Implementation）模式将实现细节隐藏在源文件中，头文件只暴露一个指向实现的指针。这样修改实现不会影响头文件，减少了重新编译的范围。

分层的头文件结构也很重要。将稳定的、基础的定义放在底层头文件中，将易变的、高层的定义放在上层头文件中。修改上层头文件不会影响底层代码。

==== 依赖图与构建优化

构建系统通过分析依赖关系构建一个有向无环图（DAG），图中的节点是文件（源文件、头文件、目标文件、库、可执行文件），边表示依赖关系。

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

当你修改一个文件时，构建系统从这个文件出发，沿着依赖边向上遍历，标记所有受影响的目标为"需要重建"。然后按照拓扑顺序（依赖在前，被依赖在后）重建这些目标。

这个依赖图还揭示了并行构建的机会。如果两个目标之间没有依赖关系（在图中没有路径相连），它们可以同时构建。在上图中，`main.o`、`detector.o` 和 `tracker.o` 的编译是独立的，可以并行进行。现代构建系统（如 Ninja）特别擅长发现和利用这种并行性。

```bash
# Make 并行编译
make -j8  # 最多 8 个并行任务

# Ninja 默认就会利用所有 CPU 核心
ninja

# CMake 构建时指定并行度
cmake --build . --parallel 8
```

构建系统还会缓存编译命令的哈希值。如果源文件没变，但编译选项变了（比如从 Debug 改为 Release），目标文件也需要重建。有些高级构建系统（如 ccache）还会缓存编译结果，当相同的源文件和编译选项再次出现时，直接复用之前的编译结果，进一步加速构建。

```bash
# 使用 ccache 加速编译
sudo apt install ccache
export CXX="ccache g++"
cmake ..
make
```

理解了这些编译原理，你就能更好地理解 CMake 的配置选项，知道为什么某些修改会触发大量重新编译，以及如何组织项目结构来优化构建时间。这些知识在大型项目中尤为重要——当编译时间从几分钟变成几十分钟时，优化构建过程就成了提高开发效率的关键。


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

理解了构建系统的必要性和编译原理之后，我们正式开始学习 CMake。CMake 有自己的一套语法，虽然看起来不像传统的编程语言，但学习曲线并不陡峭。本节将介绍 CMake 的核心语法元素，让你能够编写基本的构建配置。我们从最简单的例子开始，逐步引入更多概念。

==== CMakeLists.txt：项目的构建描述

CMake 的配置文件名为 `CMakeLists.txt`，注意大小写——在 Linux 等大小写敏感的系统上，`cmakelists.txt` 或 `CMAKELISTS.TXT` 是无法识别的。每个需要构建的目录下都可以有一个 `CMakeLists.txt` 文件，CMake 会按照目录结构递归处理它们。

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

让我们从最简单的例子开始。假设你有一个只有 `main.cpp` 的项目，最小的 `CMakeLists.txt` 只需要三行：

```cmake
cmake_minimum_required(VERSION 3.16)
project(hello)
add_executable(hello main.cpp)
```

这三行分别做了什么？

`cmake_minimum_required` 指定了项目需要的 CMake 最低版本。这是每个 CMakeLists.txt 必须有的第一条命令。它确保使用旧版本 CMake 的用户在构建项目前得到明确的错误提示，而不是遇到莫名其妙的问题。

`project` 声明项目名称。这个名称会被用于生成的项目文件（如 Visual Studio 解决方案），也可以在配置中通过变量 `PROJECT_NAME` 引用。

`add_executable` 定义一个可执行文件目标，第一个参数是目标名称，后面是组成这个目标的源文件列表。

有了这三行，你就可以构建项目了：

```bash
# 创建并进入构建目录
mkdir build && cd build

# 配置项目（生成构建文件）
cmake ..

# 构建（编译和链接）
cmake --build .

# 运行程序
./hello
```

==== cmake_minimum_required：版本要求

`cmake_minimum_required` 不仅指定最低版本，还会影响 CMake 的行为。CMake 随着版本演进引入了许多新特性，同时也改变了一些默认行为。通过指定版本，你告诉 CMake 使用那个版本的策略（policy）。

```cmake
cmake_minimum_required(VERSION 3.16)
```

选择版本时需要权衡。版本太低会错过新特性和最佳实践；版本太高会让使用旧系统的用户无法构建你的项目。一般建议：

- 如果是新项目，使用较新但不是最新的版本，如 3.16 或 3.20
- 如果需要广泛兼容，可以用 3.10 或 3.12
- ROS 2 Humble 要求至少 3.16

你也可以指定版本范围：

```cmake
# 最低 3.16，最高按 3.25 的行为
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

如果是顶层项目（不是被其他项目包含），这些变量也会被复制到不带 `PROJECT_` 前缀的版本，如 `CMAKE_PROJECT_NAME`。

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

第一个参数是目标名称，后面是源文件列表。目标名称会成为生成的可执行文件名（在 Windows 上会自动加 `.exe` 后缀）。

源文件路径可以是相对路径（相对于当前 CMakeLists.txt 所在目录）或绝对路径。推荐使用相对路径，因为绝对路径会破坏项目的可移植性。

```cmake
# 相对路径（推荐）
add_executable(my_app src/main.cpp)

# 绝对路径（不推荐，但有时需要）
add_executable(my_app ${CMAKE_CURRENT_SOURCE_DIR}/src/main.cpp)
```

注意，`add_executable` 中只需要列出 `.cpp` 源文件，不需要列出头文件。编译器会通过源文件中的 `#include` 自动找到头文件。不过，如果你使用 IDE（如 Visual Studio、CLion），在 `add_executable` 中列出头文件可以让它们出现在项目视图中，便于浏览：

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

用户可以在配置时选择：

```bash
# 构建共享库
cmake -DBUILD_SHARED_LIBS=ON ..

# 构建静态库（默认）
cmake -DBUILD_SHARED_LIBS=OFF ..
```

还有一种特殊的库类型：`INTERFACE` 库。它不包含实际的代码，只用于传递编译选项、包含路径等。Header-only 库（如 Eigen）通常使用这种方式：

```cmake
# 接口库，只有头文件
add_library(my_header_lib INTERFACE)
target_include_directories(my_header_lib INTERFACE include)
```

另一种是 `OBJECT` 库，它编译源文件生成目标文件，但不打包成库文件。这在某些高级场景中有用：

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
target_link_libraries(rm_vision rm_core)
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

变量名区分大小写，`MY_VAR`、`my_var` 和 `My_Var` 是三个不同的变量。惯例是使用大写字母和下划线。

变量可以包含列表（多个值），值之间用分号分隔：

```cmake
# 定义列表变量
set(SOURCES main.cpp utils.cpp helper.cpp)

# 上面等价于
set(SOURCES "main.cpp;utils.cpp;helper.cpp")

# 使用列表
add_executable(app ${SOURCES})
```

当你在 `set` 中提供多个值时，它们会自动合并成分号分隔的列表。这就是为什么 `add_executable` 的参数可以是多个文件名或一个包含多个文件的变量。

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

普通变量只在当前作用域内有效。缓存变量（cache variable）则保存在构建目录的 `CMakeCache.txt` 文件中，在多次配置之间持久存在，并且可以被用户在命令行修改。

使用 `set` 的 `CACHE` 选项定义缓存变量：

```cmake
# 定义缓存变量
set(ENABLE_DEBUG ON CACHE BOOL "Enable debug mode")
set(MAX_THREADS 4 CACHE STRING "Maximum number of threads")
set(INSTALL_PREFIX "/usr/local" CACHE PATH "Installation prefix")
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
cmake -DENABLE_DEBUG=OFF -DMAX_THREADS=8 ..
```

设置后，值会保存在 `CMakeCache.txt` 中，下次配置时不需要再次指定。

`option` 命令是定义布尔缓存变量的快捷方式：

```cmake
# 这两行等价
option(ENABLE_TESTS "Build unit tests" ON)
set(ENABLE_TESTS ON CACHE BOOL "Build unit tests")
```

`option` 更简洁，适合开关类的配置。

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
list(REMOVE_AT MY_LIST 0)    # 按索引移除

# 排序
list(SORT MY_LIST)

# 去重
list(REMOVE_DUPLICATES MY_LIST)

# 反转
list(REVERSE MY_LIST)

# 连接成字符串
list(JOIN MY_LIST ", " result)  # result = "a, b, c, d, e"
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

这种方式比直接在 `add_library` 中列出所有文件更清晰，特别是当源文件很多、分布在多个目录时。

关于自动收集源文件的 `file(GLOB ...)`，这里需要提醒一下：

```cmake
# 自动收集所有 .cpp 文件
file(GLOB SOURCES "src/*.cpp")
file(GLOB_RECURSE SOURCES "src/*.cpp")  # 递归搜索子目录

add_executable(app ${SOURCES})
```

虽然 `file(GLOB)` 看起来很方便，但 CMake 官方不推荐用它来收集源文件。原因是：当你添加或删除源文件时，CMake 不会自动重新配置，因为 CMakeLists.txt 本身没有变化。这可能导致新文件没有被编译，或者删除的文件还在使用旧的目标文件。手动列出源文件虽然繁琐，但更加可靠。

```cmake
# 推荐：手动列出源文件
add_executable(app
    src/main.cpp
    src/utils.cpp
    src/helper.cpp
)
```

如果确实想用 `file(GLOB)`，可以配合 `CONFIGURE_DEPENDS` 选项（CMake 3.12+），让 CMake 在每次构建时检查文件变化：

```cmake
file(GLOB SOURCES CONFIGURE_DEPENDS "src/*.cpp")
```

但这会略微增加构建时间，而且不是所有生成器都支持。

==== 条件语句

CMake 的条件语句使用 `if`/`elseif`/`else`/`endif` 结构。注意每个分支都需要对应的结束标记。

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

条件表达式的求值规则值得仔细了解。对于布尔值，以下情况被视为真：`ON`、`YES`、`TRUE`、`Y` 或非零数字。以下情况被视为假：`OFF`、`NO`、`FALSE`、`N`、`IGNORE`、`NOTFOUND`、空字符串或以 `-NOTFOUND` 结尾的字符串。

变量在条件中可以直接使用名称，不需要 `${}`：

```cmake
set(ENABLE_FEATURE ON)

# 这两种写法都可以，但推荐第一种
if(ENABLE_FEATURE)
    message("Feature enabled")
endif()

if(${ENABLE_FEATURE})  # 也可以，但不推荐
    message("Feature enabled")
endif()
```

直接使用变量名时，CMake 会自动解引用。但如果变量未定义，行为会不同：`if(VAR)` 在 VAR 未定义时为假，而 `if(${VAR})` 会展开为 `if()` 并产生错误。

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
    add_compile_definitions(PLATFORM_WINDOWS)
elseif(APPLE)
    message(STATUS "Building on macOS")
    add_compile_definitions(PLATFORM_MACOS)
elseif(UNIX)
    message(STATUS "Building on Linux/Unix")
    add_compile_definitions(PLATFORM_LINUX)
endif()
```

另一个常见用法是根据构建类型设置选项：

```cmake
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    message(STATUS "Debug build")
    set(ENABLE_LOGGING ON)
elseif(CMAKE_BUILD_TYPE STREQUAL "Release")
    message(STATUS "Release build")
    set(ENABLE_LOGGING OFF)
endif()
```

条件语句在处理可选依赖时也很有用：

```cmake
find_package(OpenCV QUIET)  # QUIET 表示找不到时不报错

if(OpenCV_FOUND)
    message(STATUS "OpenCV found: ${OpenCV_VERSION}")
    target_link_libraries(my_app OpenCV::OpenCV)
    target_compile_definitions(my_app PRIVATE HAS_OPENCV)
else()
    message(WARNING "OpenCV not found, some features will be disabled")
endif()
```

==== 循环语句

CMake 提供了 `foreach` 和 `while` 两种循环结构。`foreach` 更常用，适合遍历列表；`while` 适合条件循环。

`foreach` 的基本形式是遍历列表中的每个元素：

```cmake
set(MODULES detector tracker predictor)

foreach(module ${MODULES})
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

遍历多个列表（同时迭代）：

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
math(EXPR last "${count} - 1")

foreach(i RANGE ${last})
    list(GET ITEMS ${i} item)
    message(STATUS "Item ${i}: ${item}")
endforeach()
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

foreach(test_src ${TEST_SOURCES})
    # 从文件名提取测试名（去掉 .cpp 后缀）
    get_filename_component(test_name ${test_src} NAME_WE)
    
    # 创建测试可执行文件
    add_executable(${test_name} ${test_src})
    target_link_libraries(${test_name} rm_core GTest::gtest_main)
    
    # 注册测试
    add_test(NAME ${test_name} COMMAND ${test_name})
endforeach()
```

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
    )
    set(${result_var} ${git_version} PARENT_SCOPE)
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
- 宏没有自己的作用域，直接在调用者的作用域执行（类似文本替换）

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

一般推荐使用函数，因为作用域隔离可以避免意外的副作用。宏主要用于需要直接影响调用者作用域的场景。

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
    
    # 使用解析后的参数
    if(ARG_SHARED)
        add_library(${ARG_NAME} SHARED ${ARG_SOURCES})
    else()
        add_library(${ARG_NAME} STATIC ${ARG_SOURCES})
    endif()
    
    if(ARG_DEPENDS)
        target_link_libraries(${ARG_NAME} ${ARG_DEPENDS})
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
    DEPENDS OpenCV::OpenCV Eigen3::Eigen
    SHARED
)
```

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

CMake 3.0 引入了括号注释，适合注释大段内容：

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

当项目有多层目录结构时，`CMAKE_SOURCE_DIR` 始终指向顶层，而 `CMAKE_CURRENT_SOURCE_DIR` 会随着处理的 CMakeLists.txt 变化。如果你的项目被另一个项目作为子项目包含，`CMAKE_SOURCE_DIR` 会指向外层项目，而 `PROJECT_SOURCE_DIR` 指向你自己的项目。

C++ 标准和编译器相关变量：

```cmake
# 设置 C++ 标准版本
set(CMAKE_CXX_STANDARD 17)

# 要求使用指定的标准，而不是降级
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 不使用编译器扩展（更好的可移植性）
set(CMAKE_CXX_EXTENSIONS OFF)

# 添加编译选项
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra")

# 只在 Debug 模式添加的选项
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -g -O0")

# 只在 Release 模式添加的选项
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3 -DNDEBUG")

# 编译器标识
message(STATUS "Compiler: ${CMAKE_CXX_COMPILER_ID}")  # GNU, Clang, MSVC 等
message(STATUS "Compiler version: ${CMAKE_CXX_COMPILER_VERSION}")
```

注意：现代 CMake 推荐使用 `target_compile_features` 和 `target_compile_options` 代替全局设置：

```cmake
# 现代方式：针对特定目标设置
add_executable(my_app main.cpp)
target_compile_features(my_app PRIVATE cxx_std_17)
target_compile_options(my_app PRIVATE -Wall -Wextra)
```

构建类型变量：

```cmake
# CMAKE_BUILD_TYPE 控制构建类型
# 常见值：Debug, Release, RelWithDebInfo, MinSizeRel

# 设置默认构建类型
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Build type" FORCE)
endif()

message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")

# 根据构建类型设置选项
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(ENABLE_ASSERTIONS ON)
else()
    set(ENABLE_ASSERTIONS OFF)
endif()
```

构建类型主要影响编译优化级别和调试信息：

- `Debug`：无优化（-O0），包含调试信息（-g），适合开发调试
- `Release`：高优化（-O3），无调试信息，适合发布
- `RelWithDebInfo`：优化（-O2）+ 调试信息，适合需要调试的生产环境
- `MinSizeRel`：优化体积（-Os），适合嵌入式等空间受限场景

输出目录变量：

```cmake
# 可执行文件输出目录
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# 静态库输出目录
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# 共享库输出目录
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# 这样所有生成的文件会被整理到 build/bin 和 build/lib 目录
```

安装相关变量：

```cmake
# 安装前缀，默认是 /usr/local（Linux）
message(STATUS "Install prefix: ${CMAKE_INSTALL_PREFIX}")

# 可以在配置时修改
# cmake -DCMAKE_INSTALL_PREFIX=/opt/rm_vision ..

# 标准安装目录（相对于 CMAKE_INSTALL_PREFIX）
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
    message(STATUS "64-bit system")
else()
    message(STATUS "32-bit system")
endif()
```

find_package 相关变量：

```cmake
find_package(OpenCV REQUIRED)

# find_package 成功后会设置以下变量（以 OpenCV 为例）
# OpenCV_FOUND        - 是否找到
# OpenCV_VERSION      - 版本号
# OpenCV_INCLUDE_DIRS - 头文件目录（旧式）
# OpenCV_LIBRARIES    - 库文件（旧式）
# OpenCV::OpenCV      - 导入目标（现代方式）

message(STATUS "OpenCV version: ${OpenCV_VERSION}")
message(STATUS "OpenCV libraries: ${OpenCV_LIBRARIES}")
```

了解这些变量可以帮助你编写更灵活、更可移植的 CMake 配置。当你遇到问题时，用 `message` 打印这些变量的值，往往能帮助你快速定位问题所在。


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

了解了 CMake 的基础语法之后，让我们完整地走一遍从配置到编译的流程。虽然前面已经简单演示过，但这里我们将深入讨论每个步骤的细节，包括不同的构建方式、生成器选择、构建类型、并行编译等实用技巧。掌握这些内容可以让你的日常开发更加高效。

==== 外部构建

CMake 支持两种构建方式：源内构建（in-source build）和源外构建（out-of-source build）。源内构建是在源代码目录中直接运行 CMake，生成的文件与源代码混在一起；源外构建是在单独的目录中运行 CMake，保持源代码目录的整洁。

```bash
# 源内构建（不推荐）
cd my_project
cmake .
make

# 源外构建（推荐）
cd my_project
mkdir build
cd build
cmake ..
make
```

源外构建有几个明显的优势。首先，源代码目录保持干净，生成的文件（目标文件、可执行文件、CMake 缓存等）都在构建目录中，不会污染源代码。这使得版本控制更简单——只需要在 `.gitignore` 中添加 `build/` 即可忽略所有构建产物。

其次，你可以同时拥有多个构建目录。比如一个用于 Debug 构建，一个用于 Release 构建；或者一个用于本地开发，一个用于交叉编译到 ARM 平台。每个构建目录都是独立的，互不干扰。

```bash
# 多个构建目录
mkdir build-debug build-release

cd build-debug
cmake -DCMAKE_BUILD_TYPE=Debug ..

cd ../build-release
cmake -DCMAKE_BUILD_TYPE=Release ..
```

最后，清理构建变得非常简单——直接删除构建目录即可，不需要担心误删源文件。

由于源外构建的诸多优势，现代 CMake 项目几乎都采用这种方式。有些项目甚至会在 CMakeLists.txt 中禁止源内构建：

```cmake
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR)
    message(FATAL_ERROR "In-source builds are not allowed. Please use a separate build directory.")
endif()
```

==== 配置与构建的两个阶段

使用 CMake 构建项目分为两个阶段：配置（configure）和构建（build）。理解这两个阶段的区别很重要。

配置阶段是运行 `cmake` 命令的过程。CMake 读取 CMakeLists.txt，执行其中的命令，检查系统环境，查找依赖库，最终生成原生构建系统的配置文件（如 Makefile）。配置阶段的输出保存在构建目录中，包括 `CMakeCache.txt`（缓存）和 `CMakeFiles/` 目录（中间文件）。

```bash
# 配置阶段
cd build
cmake ..

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
# 构建阶段 - 方式一：使用原生工具
make

# 构建阶段 - 方式二：使用 CMake 统一接口（推荐）
cmake --build .
```

`cmake --build` 的优势是跨平台通用。无论底层使用的是 Make、Ninja 还是 Visual Studio，命令都是相同的。它还支持一些通用选项：

```bash
# 并行构建
cmake --build . --parallel 8
cmake --build . -j 8  # 简写形式

# 只构建特定目标
cmake --build . --target my_app

# 清理构建产物
cmake --build . --target clean

# 显示详细构建命令
cmake --build . --verbose
```

配置只需要在首次构建或修改 CMakeLists.txt 后执行。如果只是修改了源代码，直接运行构建命令即可——构建系统会自动检测哪些文件需要重新编译。

```bash
# 首次构建：配置 + 构建
cmake ..
cmake --build .

# 修改源代码后：只需构建
cmake --build .

# 修改 CMakeLists.txt 后：需要重新配置
cmake ..  # 或者构建系统会自动触发重新配置
cmake --build .
```

==== 生成器

CMake 是一个元构建系统，它不直接编译代码，而是生成原生构建系统的配置文件。这些原生构建系统被称为"生成器"（generator）。不同平台有不同的默认生成器：

- Linux：Unix Makefiles（默认）
- macOS：Unix Makefiles 或 Xcode
- Windows：Visual Studio 或 NMake Makefiles

你可以用 `-G` 选项指定生成器：

```bash
# 查看可用的生成器
cmake --help

# 使用 Ninja 生成器（推荐）
cmake -G Ninja ..

# 使用 Unix Makefiles
cmake -G "Unix Makefiles" ..

# 使用 Visual Studio（Windows）
cmake -G "Visual Studio 17 2022" ..
```

Ninja 是一个专注于速度的构建系统，由 Google 开发。它比 Make 更快，特别是在增量构建和并行构建方面。如果你的系统上安装了 Ninja（`sudo apt install ninja-build`），强烈推荐使用它：

```bash
# 安装 Ninja
sudo apt install ninja-build

# 使用 Ninja 构建
cmake -G Ninja ..
ninja  # 或 cmake --build .
```

Ninja 的速度优势来自几个方面：它的依赖分析更高效，启动开销更小，默认就会利用所有 CPU 核心进行并行构建。在大型项目中，Ninja 可以比 Make 快数倍。

不同生成器生成的文件不同：

```bash
# Unix Makefiles 生成 Makefile
ls build/
# CMakeCache.txt  CMakeFiles/  Makefile  cmake_install.cmake

# Ninja 生成 build.ninja
ls build/
# CMakeCache.txt  CMakeFiles/  build.ninja  cmake_install.cmake
```

生成器的选择会影响后续的构建命令，但如果你使用 `cmake --build`，就不需要关心这个差异。

==== 构建类型

构建类型（build type）决定了编译器的优化级别和调试信息。CMake 预定义了四种构建类型：

- `Debug`：不优化，包含调试信息，适合开发调试
- `Release`：高度优化，不包含调试信息，适合发布
- `RelWithDebInfo`：优化 + 调试信息，适合需要调试的生产环境
- `MinSizeRel`：优化代码体积，适合嵌入式等空间受限场景

使用 `-DCMAKE_BUILD_TYPE` 指定构建类型：

```bash
# Debug 构建
cmake -DCMAKE_BUILD_TYPE=Debug ..

# Release 构建
cmake -DCMAKE_BUILD_TYPE=Release ..
```

不同构建类型对应不同的编译选项。对于 GCC/Clang：

```
Debug:         -g -O0
Release:       -O3 -DNDEBUG
RelWithDebInfo: -O2 -g -DNDEBUG
MinSizeRel:    -Os -DNDEBUG
```

`-g` 生成调试信息，使得可以用 GDB 调试程序、查看变量值、设置断点等。`-O0` 表示不优化，代码执行顺序与源代码一致，便于调试。`-O2` 和 `-O3` 是不同级别的优化，`-O3` 最激进。`-DNDEBUG` 定义 `NDEBUG` 宏，会禁用 `assert()` 断言。

选择构建类型时需要权衡：

```bash
# 日常开发调试用 Debug
cmake -DCMAKE_BUILD_TYPE=Debug ..

# 性能测试和发布用 Release
cmake -DCMAKE_BUILD_TYPE=Release ..

# 需要调试但也需要接近真实性能时用 RelWithDebInfo
cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo ..
```

对于 RoboMaster 开发，一个常见的实践是：在开发和调试阶段使用 Debug 构建，方便定位问题；在比赛或性能测试时使用 Release 构建，获得最佳性能。优化后的代码可能比未优化的快几倍甚至十几倍，这对实时性要求高的机器人系统至关重要。

在 CMakeLists.txt 中，可以设置默认构建类型：

```cmake
# 如果用户没有指定构建类型，默认使用 Release
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    message(STATUS "Setting build type to 'Release' as none was specified.")
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Choose the type of build." FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
        "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
endif()
```

注意：构建类型对于单配置生成器（如 Makefile、Ninja）在配置时指定，而对于多配置生成器（如 Visual Studio、Xcode）在构建时指定：

```bash
# 单配置生成器：配置时指定
cmake -DCMAKE_BUILD_TYPE=Release ..
cmake --build .

# 多配置生成器：构建时指定
cmake ..
cmake --build . --config Release
```

==== 并行编译

现代计算机都有多个 CPU 核心，利用并行编译可以显著缩短构建时间。

对于 Make，使用 `-j` 选项指定并行任务数：

```bash
# 使用 8 个并行任务
make -j8

# 使用所有可用核心
make -j$(nproc)

# nproc 命令返回 CPU 核心数
```

对于 Ninja，默认就会使用所有可用核心，无需额外指定。如果需要限制，可以用 `-j`：

```bash
# Ninja 默认并行
ninja

# 限制并行任务数
ninja -j4
```

使用 `cmake --build` 时：

```bash
# 指定并行任务数
cmake --build . --parallel 8
cmake --build . -j 8

# 使用所有核心
cmake --build . --parallel
cmake --build . -j
```

并行编译的最佳任务数通常等于或略大于 CPU 核心数。但如果内存有限（比如在小型设备或虚拟机上），过多的并行任务可能导致内存不足，反而降低效率甚至导致构建失败。这时可以减少并行任务数：

```bash
# 内存受限时，使用较少的并行任务
cmake --build . -j 2
```

你也可以在 CMakeLists.txt 中设置默认的并行数，但这不太常见，因为不同机器的配置不同：

```cmake
# 设置 Make 的并行任务数（不推荐硬编码）
set(CMAKE_BUILD_PARALLEL_LEVEL 8)
```

==== 清理构建

有时候你需要从头开始重新构建，比如修改了编译器选项、遇到了奇怪的构建错误、或者想确保没有残留的旧文件。

最简单的方法是删除整个构建目录：

```bash
# 完全清理：删除构建目录
rm -rf build
mkdir build
cd build
cmake ..
cmake --build .
```

这是最彻底的方式，保证所有东西都是全新生成的。由于我们使用源外构建，这个操作完全安全，不会影响源代码。

如果只想清理编译产物而保留 CMake 配置，可以使用 `clean` 目标：

```bash
# 清理编译产物
make clean
# 或
cmake --build . --target clean
# 或（Ninja）
ninja clean
```

这会删除目标文件、可执行文件等编译产物，但保留 CMake 生成的文件（如 Makefile、CMakeCache.txt）。下次构建时不需要重新配置。

有些情况下，你可能需要清理 CMake 缓存但保留编译产物。可以手动删除缓存文件：

```bash
# 删除 CMake 缓存，强制重新配置
rm CMakeCache.txt
rm -rf CMakeFiles/
cmake ..
```

一个实用的技巧是创建一个清理脚本：

```bash
#!/bin/bash
# clean.sh

cd "$(dirname "$0")"

if [ -d "build" ]; then
    rm -rf build
    echo "Build directory removed."
else
    echo "Build directory does not exist."
fi
```

==== CMake 缓存

CMake 缓存是保存在构建目录中的 `CMakeCache.txt` 文件。它存储了配置过程中的所有缓存变量，包括用户设置的选项、检测到的系统信息、找到的库路径等。

```bash
# 查看缓存内容
cat CMakeCache.txt

# 或者用 cmake 命令查看
cmake -L ..      # 列出非高级缓存变量
cmake -LA ..     # 列出所有缓存变量
cmake -LAH ..    # 列出所有缓存变量及其帮助信息
```

缓存的一个重要特性是持久性。一旦某个变量被设置到缓存中，后续的配置运行会使用缓存的值，而不会重新检测或使用默认值。这既是优点（不需要每次都指定选项），也可能是陷阱（修改了选项但没有生效）。

```bash
# 首次配置，设置选项
cmake -DENABLE_CUDA=ON ..

# 再次配置，即使不指定，ENABLE_CUDA 仍然是 ON
cmake ..

# 要修改缓存的值，需要显式指定
cmake -DENABLE_CUDA=OFF ..
```

如果发现选项修改没有生效，检查缓存是一个好习惯。你可以用 `-U` 选项删除特定的缓存变量：

```bash
# 删除特定缓存变量
cmake -UENABLE_CUDA ..

# 删除匹配模式的缓存变量
cmake -UENABLE_* ..
```

或者直接删除 `CMakeCache.txt` 强制重新配置。

缓存变量的类型（BOOL、STRING、PATH 等）会影响 GUI 工具的显示方式。标记为 `INTERNAL` 的缓存变量不会在 GUI 中显示，用于存储 CMake 内部使用的信息。

==== 交互式配置：ccmake 和 cmake-gui

对于有很多配置选项的项目，在命令行上一个个指定 `-D` 选项很不方便。CMake 提供了两个交互式配置工具：`ccmake`（终端界面）和 `cmake-gui`（图形界面）。

`ccmake` 是一个基于 ncurses 的终端界面工具：

```bash
# 安装 ccmake
sudo apt install cmake-curses-gui

# 运行 ccmake
cd build
ccmake ..
```

在 ccmake 中：

- 使用方向键上下移动，选择要修改的变量
- 按 Enter 编辑变量值
- 按 `t` 切换显示高级变量
- 按 `c` 配置（configure）
- 按 `g` 生成（generate）并退出
- 按 `q` 退出

`cmake-gui` 是一个图形界面工具，更加直观：

```bash
# 安装 cmake-gui
sudo apt install cmake-qt-gui

# 运行 cmake-gui
cmake-gui
```

在 cmake-gui 中：

1. 设置源代码目录和构建目录
2. 点击 "Configure" 按钮，选择生成器
3. 修改需要的选项（变量会以红色高亮显示新变化的项）
4. 再次点击 "Configure" 直到没有红色项
5. 点击 "Generate" 生成构建文件

这两个工具特别适合：

- 初次配置一个陌生的项目，浏览有哪些可用选项
- 需要修改多个选项时，比逐个 `-D` 更方便
- 想要了解某个选项的含义（工具会显示描述信息）

一个典型的工作流程是：首次使用交互式工具浏览和设置选项，之后在命令行进行日常构建，需要修改配置时再回到交互式工具。

==== 完整的构建示例

让我们用一个完整的例子串联上述内容。假设你克隆了一个 RoboMaster 视觉项目：

```bash
# 克隆项目
git clone https://github.com/example/rm_vision.git
cd rm_vision

# 创建构建目录
mkdir build && cd build

# 首次配置：使用 Ninja，Release 模式，启用 CUDA
cmake -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DENABLE_CUDA=ON \
      -DCMAKE_INSTALL_PREFIX=/opt/rm_vision \
      ..

# 如果配置失败，查看详细信息
cmake -G Ninja -DCMAKE_BUILD_TYPE=Release .. --debug-find

# 构建（并行）
cmake --build . -j

# 运行测试
ctest --output-on-failure

# 安装
sudo cmake --install .
```

日常开发流程：

```bash
# 修改代码后，只需构建
cmake --build . -j

# 如果修改了 CMakeLists.txt，会自动重新配置
cmake --build . -j

# 切换到 Debug 模式调试问题
cd ..
mkdir build-debug && cd build-debug
cmake -G Ninja -DCMAKE_BUILD_TYPE=Debug ..
cmake --build . -j

# 使用 GDB 调试
gdb ./rm_vision
```

遇到问题时的排查：

```bash
# 查看详细的编译命令
cmake --build . --verbose

# 查看缓存变量
cmake -LA ..

# 完全重新开始
cd ..
rm -rf build
mkdir build && cd build
cmake -G Ninja -DCMAKE_BUILD_TYPE=Release ..
cmake --build . -j
```

掌握了这些构建流程，你就能够高效地管理 CMake 项目的构建过程。无论是个人开发还是团队协作，统一的构建流程都是代码质量的重要保障。


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

如果说 CMake 的语法是它的词汇和语法，那么"目标"（Target）就是它的核心思想。现代 CMake（通常指 CMake 3.0 以后的最佳实践）围绕目标组织一切：编译选项、包含路径、链接依赖都附加在目标上，而不是设置全局变量。这种以目标为中心的方式让构建配置更加清晰、模块化，也让依赖管理变得优雅。理解目标和属性是掌握现代 CMake 的关键。

==== 什么是目标

在 CMake 中，目标是构建系统要生成的东西。最常见的目标类型是可执行文件和库：

```cmake
# 创建可执行文件目标
add_executable(rm_vision src/main.cpp)

# 创建库目标
add_library(rm_core src/core.cpp)
```

执行这些命令后，`rm_vision` 和 `rm_core` 就成为了 CMake 中的目标。你可以把目标想象成一个对象，它有自己的属性（编译选项、包含路径、链接的库等），这些属性决定了如何构建这个目标。

目标的类型包括：

- *可执行文件*：`add_executable` 创建，最终生成可运行的程序
- *静态库*：`add_library(name STATIC ...)` 创建，生成 `.a` 文件
- *共享库*：`add_library(name SHARED ...)` 创建，生成 `.so` 文件
- *接口库*：`add_library(name INTERFACE)` 创建，不生成实际文件，只用于传递属性
- *对象库*：`add_library(name OBJECT ...)` 创建，生成目标文件但不打包
- *导入目标*：表示外部已存在的库，由 `find_package` 创建

还有一种特殊的"目标"是自定义目标，用 `add_custom_target` 创建，它不对应任何文件，而是执行自定义命令：

```cmake
# 自定义目标，用于生成文档
add_custom_target(docs
    COMMAND doxygen ${CMAKE_SOURCE_DIR}/Doxyfile
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Generating documentation..."
)
```

目标之间可以建立依赖关系。当目标 A 链接目标 B 时，CMake 会确保 B 在 A 之前构建，并且 B 的某些属性会传递给 A。这种依赖关系形成了一个有向无环图，CMake 根据这个图来决定构建顺序和属性传递。

==== 目标属性

每个目标都有一组属性（properties），这些属性控制目标的构建方式。你可以把属性想象成目标的配置项。常见的属性包括：

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

但在日常使用中，我们更多地使用 `target_*` 系列命令来设置属性，因为它们更加直观，而且支持属性的传递性（稍后详细讨论）。

==== target_include_directories：头文件路径

`target_include_directories` 为目标添加头文件搜索路径，相当于编译器的 `-I` 选项：

```cmake
add_library(rm_core src/core.cpp)

target_include_directories(rm_core PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)
```

这告诉编译器在编译 `rm_core` 时，到 `include` 目录下搜索头文件。

可以指定多个路径：

```cmake
target_include_directories(rm_core PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/third_party/json/include
)
```

路径可以是绝对路径或相对路径。使用 `CMAKE_CURRENT_SOURCE_DIR` 构造的路径可以确保在任何构建目录下都能正确找到头文件。

对于需要区分构建时和安装后路径的情况，可以使用生成器表达式：

```cmake
target_include_directories(rm_core PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)
```

这表示：在构建时使用源码目录下的 `include`，安装后使用安装目录下的 `include`。这在编写可供他人使用的库时非常重要。

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

注意不要在宏名中使用 `-D` 前缀，CMake 会自动添加。也不要在值周围加引号，除非你确实需要引号成为值的一部分：

```cmake
# 正确
target_compile_definitions(app PRIVATE MY_MACRO=42)

# 错误：会定义为 -D-DMY_MACRO=42
target_compile_definitions(app PRIVATE -DMY_MACRO=42)

# 定义字符串值时需要转义引号
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
    -Werror         # 警告视为错误
)
```

不同编译器的选项可能不同，可以使用条件判断或生成器表达式处理：

```cmake
# 方式一：条件判断
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    target_compile_options(rm_vision PRIVATE -Wall -Wextra)
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    target_compile_options(rm_vision PRIVATE /W4)
endif()

# 方式二：生成器表达式（更简洁）
target_compile_options(rm_vision PRIVATE
    $<$<CXX_COMPILER_ID:GNU,Clang>:-Wall -Wextra>
    $<$<CXX_COMPILER_ID:MSVC>:/W4>
)
```

生成器表达式 `$<condition:value>` 的含义是：如果 `condition` 为真，则展开为 `value`，否则展开为空。

常见的编译选项包括：

```cmake
target_compile_options(my_target PRIVATE
    # 警告控制
    -Wall -Wextra -Wpedantic
    
    # 优化（通常由 CMAKE_BUILD_TYPE 控制，这里仅作演示）
    $<$<CONFIG:Release>:-O3>
    $<$<CONFIG:Debug>:-O0 -g>
    
    # 特定架构优化
    -march=native  # 针对当前 CPU 优化（注意可移植性）
    
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

==== target_compile_features：C++ 标准特性

`target_compile_features` 声明目标需要的 C++ 特性，CMake 会自动选择合适的编译器选项来启用这些特性：

```cmake
add_library(rm_core src/core.cpp)

# 要求 C++17 标准
target_compile_features(rm_core PUBLIC cxx_std_17)
```

`cxx_std_17` 是一个元特性，表示需要完整的 C++17 支持。类似的还有 `cxx_std_11`、`cxx_std_14`、`cxx_std_20`、`cxx_std_23` 等。

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

与直接设置 `CMAKE_CXX_STANDARD` 相比，`target_compile_features` 的优势是：

1. 它是目标级别的，不是全局的
2. 它支持 PUBLIC/PRIVATE/INTERFACE，可以传递给依赖者
3. CMake 会检查编译器是否支持所需特性

```cmake
# 旧方式：全局设置
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 新方式：目标级别设置（推荐）
add_library(rm_core src/core.cpp)
target_compile_features(rm_core PUBLIC cxx_std_17)
```

当你使用 `PUBLIC` 时，所有链接 `rm_core` 的目标也会自动要求 C++17，这正是我们通常想要的行为。

==== target_link_libraries：链接库

`target_link_libraries` 是最重要的命令之一，它声明目标的链接依赖：

```cmake
add_library(rm_core src/core.cpp)
add_executable(rm_vision src/main.cpp)

# rm_vision 链接 rm_core
target_link_libraries(rm_vision PRIVATE rm_core)
```

链接一个目标会做两件事：

1. 在链接阶段，将被链接的库链接到目标中
2. 根据可见性（PUBLIC/PRIVATE/INTERFACE），传递被链接库的属性

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

# 现代方式：使用导入目标
target_link_libraries(rm_vision PRIVATE
    OpenCV::OpenCV
    Eigen3::Eigen
)

# 旧方式：使用变量（不推荐）
target_link_libraries(rm_vision PRIVATE
    ${OpenCV_LIBRARIES}
)
target_include_directories(rm_vision PRIVATE
    ${OpenCV_INCLUDE_DIRS}
)
```

现代方式（使用导入目标如 `OpenCV::OpenCV`）更简洁，因为导入目标携带了所有必要的信息（头文件路径、编译选项、依赖库等），只需一行 `target_link_libraries` 就够了。

链接系统库：

```cmake
# 链接 pthread
find_package(Threads REQUIRED)
target_link_libraries(my_app PRIVATE Threads::Threads)

# 链接数学库
target_link_libraries(my_app PRIVATE m)

# 链接动态加载库
target_link_libraries(my_app PRIVATE dl)
```

==== PUBLIC、PRIVATE 和 INTERFACE

理解 PUBLIC、PRIVATE 和 INTERFACE 是掌握现代 CMake 的关键。它们控制属性的可见性和传递性。

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

*PRIVATE* 表示：这个依赖只在当前目标内部使用，不暴露给依赖当前目标的其他目标。

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

`app` 链接 `config_loader` 时，不会自动链接 `json_parser`，因为它被隐藏了。

*PUBLIC* 表示：这个依赖既在当前目标内部使用，也暴露给依赖当前目标的其他目标。

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

`app` 链接 `config_loader` 时，会自动链接 `json_parser`，因为 `app` 要编译包含 `config_loader.h` 的代码，而 `config_loader.h` 包含了 `json_parser/json.h`。

*INTERFACE* 表示：这个依赖只暴露给依赖当前目标的其他目标，当前目标本身不使用。

这听起来有点奇怪，什么时候会用到？最常见的场景是 header-only 库：

```cmake
# header-only 库，没有源文件需要编译
add_library(my_header_lib INTERFACE)

target_include_directories(my_header_lib INTERFACE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_compile_features(my_header_lib INTERFACE cxx_std_17)
```

因为 `my_header_lib` 是纯接口库，没有实现代码，所以所有属性都是 `INTERFACE`——它们只对使用这个库的目标有意义。

另一个场景是，当你想给依赖者添加额外的要求，但自己不需要：

```cmake
add_library(wrapper src/wrapper.cpp)

# wrapper 自己不需要 C++17，但使用 wrapper 的代码需要
target_compile_features(wrapper INTERFACE cxx_std_17)
```

让我们用表格总结：

```
                  │ 当前目标使用 │ 传递给依赖者
─────────────────┼─────────────┼─────────────
    PRIVATE      │     ✓       │      ✗
    PUBLIC       │     ✓       │      ✓
    INTERFACE    │     ✗       │      ✓
```

再用一个更直观的图示：

```
              PRIVATE        PUBLIC        INTERFACE
              ┌─────┐       ┌─────┐       ┌─────┐
              │  A  │       │  A  │       │  A  │
              └──┬──┘       └──┬──┘       └──┬──┘
                 │             │             │
                 ▼             ▼             ▼
              ┌─────┐       ┌─────┐       ┌─────┐
    使用 →    │  B  │       │  B  │       │  B  │    ← 不使用
              └─────┘       └──┬──┘       └──┬──┘
                               │             │
                               ▼             ▼
                            ┌─────┐       ┌─────┐
          不传递            │  C  │       │  C  │    ← 传递
                            └─────┘       └─────┘
```

==== 传递性依赖

现代 CMake 的强大之处在于传递性依赖（transitive dependencies）。当你链接一个目标时，不仅仅是链接那个库，还会自动获得它的 PUBLIC 和 INTERFACE 属性。

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

虽然 `app` 只显式链接了 `renderer`，但它自动获得了：

- `renderer`、`geometry`、`math_utils` 的头文件路径
- `renderer`、`geometry`、`math_utils` 的链接
- C++17 标准要求（来自 `math_utils`）

这就是传递性依赖的威力。你不需要手动追踪依赖链，CMake 会自动处理。

对比旧式的 CMake 写法：

```cmake
# 旧方式：手动设置所有依赖（繁琐且容易出错）
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

旧方式需要知道整个依赖链的细节，而且当依赖变化时，需要修改所有使用者。现代方式只需要声明直接依赖，其他的自动传递。

==== 实际项目中的应用

让我们看一个 RoboMaster 项目的完整示例：

```cmake
cmake_minimum_required(VERSION 3.16)
project(rm_vision VERSION 2.0.0 LANGUAGES CXX)

# 查找依赖
find_package(OpenCV REQUIRED)
find_package(Eigen3 REQUIRED)
find_package(Ceres REQUIRED)

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
    PRIVATE OpenCV::OpenCV  # PRIVATE: 只在实现中使用 OpenCV
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
    OpenCV::OpenCV  # 主程序也需要 OpenCV 进行图像采集
)
```

在这个例子中：

- `rm_common` 是基础模块，暴露 Eigen 类型，所以 `Eigen3::Eigen` 是 PUBLIC
- `rm_detector` 内部使用 OpenCV 处理图像，但接口不暴露 OpenCV 类型，所以是 PRIVATE
- `rm_tracker` 的接口返回 Eigen 矩阵表示的状态，所以 `Eigen3::Eigen` 是 PUBLIC
- `rm_predictor` 依赖 `rm_tracker`，接口使用跟踪器的类型，所以是 PUBLIC
- `rm_vision` 主程序是最终产物，不会被其他目标依赖，所以全部是 PRIVATE

遵循这些原则可以让你的 CMake 配置更加清晰、正确，也让依赖管理变得简单。当某个库的依赖发生变化时，只需要修改那个库的 CMakeLists.txt，而不需要修改所有使用者。

==== 诊断依赖关系

当依赖关系变得复杂时，你可能想知道某个目标实际链接了哪些库、使用了哪些头文件路径。CMake 提供了一些方法来诊断：

```cmake
# 查看目标的属性
get_target_property(includes rm_vision INCLUDE_DIRECTORIES)
message(STATUS "rm_vision includes: ${includes}")

get_target_property(libs rm_vision LINK_LIBRARIES)
message(STATUS "rm_vision links: ${libs}")
```

更详细的方式是使用 `cmake --graphviz` 生成依赖图：

```bash
# 生成依赖图
cmake --graphviz=deps.dot ..

# 使用 Graphviz 渲染
dot -Tpng deps.dot -o deps.png
```

或者使用 `cmake --trace` 查看 CMake 的执行过程。

理解并正确使用目标和属性，是编写高质量 CMake 配置的基础。它让构建系统更加模块化、可维护，也让依赖管理变得优雅。如果你发现自己在使用全局变量（如 `CMAKE_CXX_FLAGS`、`include_directories()`）来设置编译选项，考虑改用目标级别的命令（`target_compile_options`、`target_include_directories`）——这是现代 CMake 的推荐做法。


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

到目前为止，我们的例子大多是简单的单目录项目。但真实的项目往往有几十甚至上百个源文件，分布在多个目录中，划分为若干个模块。如何组织这些文件，如何编写对应的 CMake 配置，是每个开发者都要面对的问题。好的项目结构可以让代码更容易理解、更容易维护，也让构建配置更加清晰。本节将介绍多文件项目的组织方式和相应的 CMake 技巧。

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

这种结构的好处是职责清晰。当你想找某个类的接口定义，去 `include/` 目录；想看实现细节，去 `src/` 目录；想运行程序，去 `apps/` 目录；想写测试，去 `tests/` 目录。新加入项目的人可以快速了解代码的组织方式。

注意 `include/` 下还有一层以项目名命名的目录（`include/my_project/`）。这样做是为了避免头文件名冲突。用户包含头文件时会写 `#include <my_project/core.h>` 而不是 `#include <core.h>`，即使他们的项目中也有一个 `core.h` 也不会冲突。

实际项目中，还有一种常见的"模块化"结构，以 RoboMaster 视觉项目 RMCV 为例：

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

这种结构没有单独的 `include/` 目录，而是每个模块内部组织自己的头文件。头文件和源文件放在一起，通过 `target_include_directories` 暴露给其他模块。这种方式在嵌入式和机器人项目中很常见，因为模块通常不会被外部项目复用。

==== add_subdirectory：包含子目录

当项目变大时，把所有 CMake 配置都写在一个文件里会变得难以维护。CMake 支持将配置分散到多个 CMakeLists.txt 文件中，每个子目录可以有自己的配置文件。`add_subdirectory` 命令用于包含子目录。

```cmake
# 顶层 CMakeLists.txt
cmake_minimum_required(VERSION 3.16)
project(RMCV)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 查找依赖
find_package(OpenCV REQUIRED)
find_package(fmt REQUIRED)
find_package(Eigen3 REQUIRED)

# 全局 include 路径
include_directories(${PROJECT_SOURCE_DIR})
include_directories(umt)  # header-only 库

# 按依赖顺序添加子目录
add_subdirectory(plugin)      # 基础设施，无依赖
add_subdirectory(hardware)    # 依赖 plugin
add_subdirectory(aimer)       # 依赖 plugin, hardware

# 主程序
add_executable(RMCV2026 main.cpp)
target_link_libraries(RMCV2026
    plugin hardware detector predictor
    ${OpenCV_LIBS} fmt::fmt
)
```

当 CMake 执行 `add_subdirectory(plugin)` 时，它会进入 `plugin` 目录，读取并处理那里的 `CMakeLists.txt`，然后返回继续处理当前文件。子目录的 CMakeLists.txt 可以定义目标、设置变量，这些目标在整个项目中都是可见的。

`add_subdirectory` 还可以指定一个可选的二进制目录，用于存放该子目录的构建产物：

```cmake
# 将 src 目录的构建产物放到 build/lib 下
add_subdirectory(src ${CMAKE_BINARY_DIR}/lib)
```

如果你想包含项目外部的目录，需要指定二进制目录：

```cmake
# 包含外部目录
add_subdirectory(/path/to/external/lib external_lib_build)
```

`add_subdirectory` 的处理顺序很重要。如果目录 B 的目标依赖于目录 A 的目标，那么 A 应该在 B 之前被包含。不过，由于 CMake 会先完整解析所有配置文件，再进行构建，所以只要最终依赖关系是正确的，即使顺序不对通常也能工作。但为了清晰，推荐按照依赖顺序排列。

==== 子目录的 CMakeLists.txt

子目录的 CMakeLists.txt 文件通常比较简洁，只关注该目录的目标定义。它不需要再次调用 `cmake_minimum_required` 和 `project`，因为这些已经在顶层设置过了。

```cmake
# plugin/CMakeLists.txt - 基础插件库

# 查找依赖（可以在子目录中重复声明，CMake会缓存）
find_package(OpenCV REQUIRED)
find_package(tomlplusplus CONFIG REQUIRED)
find_package(fmt REQUIRED)

# 收集源文件
aux_source_directory(./debug debug_src)
aux_source_directory(./param param_src)
aux_source_directory(./plotter plotter_src)

# 创建库
add_library(plugin STATIC ${debug_src} ${param_src} ${plotter_src})

# 设置头文件路径
target_include_directories(plugin PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${OpenCV_INCLUDE_DIRS}
)

# 链接依赖
target_link_libraries(plugin PUBLIC
    ${OpenCV_LIBS}
    Eigen3::Eigen
    tomlplusplus::tomlplusplus
    fmt::fmt
)

# 包含子模块
add_subdirectory(rmcv_bag)
```

注意这里使用了 `CMAKE_CURRENT_SOURCE_DIR` 而不是 `PROJECT_SOURCE_DIR`。`PROJECT_SOURCE_DIR` 始终指向顶层项目目录（包含 `project()` 命令的那个），而 `CMAKE_CURRENT_SOURCE_DIR` 指向当前正在处理的 CMakeLists.txt 所在目录。在子目录中，它们是不同的。

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

# 链接所有硬件子库
target_link_libraries(hardware PUBLIC
    hardware_camera    # 来自 hik_cam/
    hardware_serial    # 来自 serial/
    ${OpenCV_LIBS}
    fmt::fmt
    plugin             # 依赖基础设施
)
```

测试的 CMakeLists.txt：

```cmake
# tests/CMakeLists.txt

# 查找 GTest
find_package(GTest REQUIRED)

# 启用测试
enable_testing()

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

你可能注意到测试目录的 CMakeLists.txt 有自己的 `find_package` 调用。这完全没问题——CMake 会缓存查找结果，多次调用不会有性能问题。这样做的好处是每个子目录都是相对自包含的，可以独立理解。

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

这种"纯转发"的 CMakeLists.txt 让目录结构更清晰，每个功能模块都在自己的子目录中定义目标。

==== 条件包含子目录

有时候你希望某些子目录是可选的，比如测试代码。可以使用选项来控制：

```cmake
# 顶层 CMakeLists.txt
cmake_minimum_required(VERSION 3.16)
project(my_project VERSION 1.0.0 LANGUAGES CXX)

# 选项
option(BUILD_TESTS "Build unit tests" ON)
option(BUILD_EXAMPLES "Build examples" OFF)

# 核心库（始终构建）
add_subdirectory(src)
add_subdirectory(apps)

# 可选子目录
if(BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()

if(BUILD_EXAMPLES)
    add_subdirectory(examples)
endif()
```

用户可以在配置时选择是否构建测试：

```bash
# 不构建测试
cmake -DBUILD_TESTS=OFF ..

# 构建测试（默认）
cmake ..
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

target_link_libraries(detector_node PUBLIC
    detector_traditional
    plugin hardware aimer_common
)

# 条件链接和编译宏
if(ENABLE_YOLO_DETECTOR)
    target_compile_definitions(detector_node PUBLIC ENABLE_YOLO_DETECTOR)
    target_link_libraries(detector_node PUBLIC detector_yolo)
endif()

# 创建统一接口库
add_library(detector INTERFACE)
target_link_libraries(detector INTERFACE detector_traditional detector_node)
```

==== 头文件组织：公开与私有

头文件的组织是项目结构中的重要决策。一个核心问题是：哪些头文件是公开的（库的用户需要使用），哪些是私有的（只在库内部使用）。

公开头文件定义了库的接口，包括用户需要使用的类、函数、常量等。它们应该放在 `include/` 目录下，用户可以通过 `#include <my_project/xxx.h>` 来包含。公开头文件应该尽量简洁，只暴露必要的接口，隐藏实现细节。

```cpp
// include/my_project/detector.h - 公开头文件
#pragma once

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
        $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
    PRIVATE
        # 私有头文件：只在库内部可见
        ${CMAKE_CURRENT_SOURCE_DIR}/src
)
```

这样配置后，库自己可以 `#include "internal/nn_backend.h"`（相对于 `src/` 目录），而链接这个库的用户只能 `#include <my_project/detector.h>`（相对于 `include/` 目录）。

为什么要区分公开和私有头文件？几个原因。首先是封装性：隐藏实现细节可以防止用户依赖内部结构，让你可以自由修改实现而不破坏用户代码。其次是编译隔离：私有头文件的变化只影响库本身的重新编译，不会波及用户代码。第三是清晰的接口：公开头文件就是库的"说明书"，用户只需要看这些文件就知道如何使用库。

==== 库与可执行文件的分离

一个好的实践是将核心功能编译成库，可执行文件只是库的一个"使用者"。这种分离有几个好处：

首先，代码更容易测试。库的每个功能都可以被测试代码独立调用和验证，而不需要通过主程序的入口。

其次，代码更容易复用。如果将来有另一个程序需要相同的功能，直接链接库即可，不需要复制代码。

第三，编译更高效。修改主程序的代码时，不需要重新编译库；修改库的内部实现时，只需要重新编译库和链接。

以 RMCV 为例，核心功能在各个库中实现：

```cmake
# 主程序
add_executable(RMCV2026 main.cpp)
target_link_libraries(RMCV2026
    plugin hardware detector predictor rmcv_bag
    ${OpenCV_LIBS} fmt::fmt
)

# 测试程序 - 每个测试针对特定模块
add_executable(test_param test/test_param.cpp)
target_link_libraries(test_param ${OpenCV_LIBS} fmt::fmt plugin)

add_executable(test_serial test/test_serial.cpp)
target_link_libraries(test_serial ${OpenCV_LIBS} fmt::fmt plugin hardware)

add_executable(test_camera test/test_camera.cpp)
target_link_libraries(test_camera ${OpenCV_LIBS} fmt::fmt plugin hardware)

add_executable(test_transformer test/test_transformer.cpp)
target_link_libraries(test_transformer ${OpenCV_LIBS} fmt::fmt aimer_common)

add_executable(test_ballistic test/test_ballistic.cpp)
target_link_libraries(test_ballistic ${OpenCV_LIBS} fmt::fmt plugin hardware aimer_common)

# 回放测试 - 需要完整的检测和预测模块
add_executable(test_playback test/test_playback.cpp)
target_link_libraries(test_playback
    plugin hardware detector predictor rmcv_bag
    ${OpenCV_LIBS} fmt::fmt
)
```

注意每个测试程序只链接它需要的库。`test_param` 只测试参数系统，所以只链接 `plugin`；`test_transformer` 测试坐标变换，所以链接 `aimer_common`。这样可以加快编译速度，也让依赖关系更清晰。

主程序的代码应该尽量精简，主要负责：解析命令行参数、初始化配置、创建对象、运行主循环。核心逻辑都应该在库中实现。

```cpp
// main.cpp
#include <csignal>
#include "plugin/debug/debug.hpp"
#include "plugin/param/runtime_parameter.hpp"
#include "hardware/hardware_node.hpp"
#include "aimer/auto_aim/detector/detector_node.hpp"
#include "aimer/auto_aim/predictor/predictor_node.hpp"

volatile bool running = true;

void signal_handler(int) { running = false; }

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
    while (running) {
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }

    // 清理
    debug::print("info", "main", "Shutting down...");
    return 0;
}
```

==== file(GLOB) 的使用与争议

当源文件很多时，手动在 CMakeLists.txt 中列出每个文件很繁琐。CMake 的 `file(GLOB)` 命令可以自动收集匹配特定模式的文件：

```cmake
# 收集所有 .cpp 文件
file(GLOB SOURCES "src/*.cpp")

# 递归收集（包括子目录）
file(GLOB_RECURSE SOURCES "src/*.cpp")

# 使用收集到的文件列表
add_library(my_lib ${SOURCES})
```

这看起来很方便，但 CMake 官方文档明确不推荐用 `file(GLOB)` 来收集源文件。原因是：CMake 的配置阶段和构建阶段是分开的。`file(GLOB)` 在配置阶段执行，收集当时存在的文件。如果你之后添加或删除了源文件，但没有重新运行 CMake 配置，构建系统不会知道文件列表变化了。这可能导致新文件没有被编译，或者删除的文件还在使用旧的目标文件。

```bash
# 初始配置
cmake ..
cmake --build .

# 添加新文件 src/new_feature.cpp
# 如果直接构建，新文件不会被编译！
cmake --build .  # new_feature.cpp 被忽略

# 需要重新配置
cmake ..
cmake --build .  # 现在才会编译 new_feature.cpp
```

手动列出源文件虽然繁琐，但更可靠。每次添加或删除文件时，你必须修改 CMakeLists.txt，这会自动触发重新配置：

```cmake
# 推荐：手动列出源文件
add_library(my_lib
    src/core.cpp
    src/utils.cpp
    src/config.cpp
    src/feature_a.cpp
    src/feature_b.cpp
)
```

如果你确实想用 `file(GLOB)`，CMake 3.12 引入了 `CONFIGURE_DEPENDS` 选项，让 CMake 在每次构建时检查文件是否变化：

```cmake
file(GLOB_RECURSE SOURCES CONFIGURE_DEPENDS "src/*.cpp")
add_library(my_lib ${SOURCES})
```

但这有几个问题。首先，不是所有生成器都支持这个特性。其次，每次构建都要扫描文件系统，会有一些性能开销。第三，即使支持，在某些边缘情况下仍可能出问题。

一个折中的方案是用 `aux_source_directory`，它比 `file(GLOB)` 稍微安全一些：

```cmake
# plugin/CMakeLists.txt
aux_source_directory(./debug debug_src)
aux_source_directory(./param param_src)
aux_source_directory(./plotter plotter_src)

add_library(plugin STATIC ${debug_src} ${param_src} ${plotter_src})
```

`aux_source_directory` 只收集 CMake 认为是源文件的扩展名（.c, .cpp, .cc 等），不会意外包含头文件。但它同样有"添加新文件需要重新配置"的问题。

对于大多数项目，使用 `aux_source_directory` 是可以接受的折中方案。但如果你使用 `file(GLOB_RECURSE)` 递归收集源文件，要格外小心。

==== 处理第三方 SDK

有些第三方库（如海康相机 SDK）不提供 CMake 配置，需要手动处理：

```cmake
# hardware/hik_cam/CMakeLists.txt

# SDK 安装路径
set(hikrobot "/opt/MVS")

# 收集源文件
aux_source_directory(. hik_camera_src)

# 创建相机库
add_library(hardware_camera STATIC ${hik_camera_src})

# 设置头文件路径
target_include_directories(hardware_camera PUBLIC ${hikrobot}/include/)

# 根据架构选择库目录
if(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64")
    target_link_directories(hardware_camera PUBLIC ${hikrobot}/lib/64/)
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64")
    target_link_directories(hardware_camera PUBLIC ${hikrobot}/lib/aarch64/)
else()
    message(FATAL_ERROR "Unsupported architecture: ${CMAKE_SYSTEM_PROCESSOR}!")
endif()

# 链接 SDK 库
target_link_libraries(hardware_camera PUBLIC
    MvCameraControl    # HIK SDK 库
    ${OpenCV_LIBS}
)
```

这个例子展示了几个重要技巧：

1. 使用 `CMAKE_SYSTEM_PROCESSOR` 检测 CPU 架构
2. 使用 `target_link_directories` 指定库搜索路径
3. 使用 `message(FATAL_ERROR ...)` 在不支持的情况下终止配置

==== 条件编译可选功能

有些功能可能依赖于可选的第三方库。可以使用 `find_package` 的结果来决定是否编译：

```cmake
# 顶层 CMakeLists.txt

# 相机-IMU 时间戳标定（需要 Ceres）
find_package(Ceres QUIET)
if(Ceres_FOUND)
    add_executable(test_time_sync test/time_sync/test_time_sync.cpp)
    target_include_directories(test_time_sync PRIVATE
        ${PROJECT_SOURCE_DIR}/test
        ${CERES_INCLUDE_DIRS}
    )
    target_link_libraries(test_time_sync
        ${OpenCV_LIBS} fmt::fmt
        plugin hardware detector aimer_common
        ${CERES_LIBRARIES}
    )
    message(STATUS "test_time_sync will be built (Ceres found)")

    # 相机外参自动标定（也需要 Ceres）
    add_executable(test_extrinsic_calib test/extrinsic_calib/test_extrinsic_calib.cpp)
    target_link_libraries(test_extrinsic_calib
        ${OpenCV_LIBS} fmt::fmt
        plugin hardware aimer_common
        ${CERES_LIBRARIES}
    )
else()
    message(STATUS "test_time_sync will NOT be built (Ceres not found)")

    # 外参标定可以用网格搜索替代
    add_executable(test_extrinsic_calib test/extrinsic_calib/test_extrinsic_calib.cpp)
    target_link_libraries(test_extrinsic_calib
        ${OpenCV_LIBS} fmt::fmt
        plugin hardware aimer_common
    )
    message(STATUS "test_extrinsic_calib will be built (without Ceres, grid search only)")
endif()

# 模拟器测试（需要 ROS2 环境）
if(SIMULATOR_FOUND)
    add_executable(test_simulator test/test_simulator.cpp)
    target_link_libraries(test_simulator
        plugin hardware simulator detector predictor
        ${OpenCV_LIBS} fmt::fmt
    )
    message(STATUS "test_simulator will be built (ROS2 found)")
endif()
```

`find_package(Ceres QUIET)` 中的 `QUIET` 选项表示如果找不到包，不要打印警告信息。这对于可选依赖很有用——找到了就编译，找不到就跳过。

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

# 全局设置
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# 选项
option(BUILD_TESTS "Build unit tests" ON)

# 依赖
find_package(OpenCV REQUIRED)
find_package(Eigen3 REQUIRED)

# 子模块（按依赖顺序）
add_subdirectory(common)
add_subdirectory(detector)
add_subdirectory(tracker)
add_subdirectory(predictor)

# 应用程序
add_subdirectory(apps)

# 测试
if(BUILD_TESTS)
    enable_testing()
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
    PRIVATE ${OpenCV_LIBS}
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
    ${OpenCV_LIBS}  # 主程序需要 OpenCV 进行图像采集
)
```

这种模块化结构的优点是每个模块相对独立，可以单独理解和测试。模块之间的依赖关系也很清晰：common 是基础，detector 依赖 common，tracker 依赖 detector 和 common，predictor 依赖 tracker。

==== 全局编译选项

对于需要在所有目标中生效的编译选项，可以使用全局设置：

```cmake
# 顶层 CMakeLists.txt

# 编译器警告
add_compile_options(-Wall -Werror=return-type -Wno-unused-variable)

# 性能分析选项
option(ENABLE_PROFILING "Enable profiling support for VTune/perf" OFF)

if(ENABLE_PROFILING)
    message(STATUS "Profiling mode enabled")
    add_compile_options(-O3 -g -fno-omit-frame-pointer -march=native)
    # 不使用 LTO，便于符号解析
elseif(CMAKE_BUILD_TYPE STREQUAL Release)
    add_compile_options(-O3 -flto -march=native)
elseif(CMAKE_BUILD_TYPE STREQUAL RelWithDebInfo)
    add_compile_options(-O3 -flto -march=native -g)
elseif(CMAKE_BUILD_TYPE STREQUAL MinSizeRel)
    add_compile_options(-Os -flto -march=native)
else()
    add_compile_options(-O0 -g)
endif()

# 全局编译定义 - 所有目标都会继承
set(ASSET_DIR "${CMAKE_SOURCE_DIR}/asset")
set(CONFIG_DIR "${CMAKE_SOURCE_DIR}/config")
set(LOG_DIR "${CMAKE_SOURCE_DIR}/log")

add_compile_definitions(
    ASSET_DIR="${ASSET_DIR}"
    CONFIG_DIR="${CONFIG_DIR}"
    LOG_DIR="${LOG_DIR}"
)
```

这样，代码中可以直接使用这些宏来获取目录路径：

```cpp
// 代码中使用
std::string config_path = std::string(CONFIG_DIR) + "/aimer.toml";
```

==== ccache 加速编译

对于大型项目，使用 ccache 可以显著加速重复编译：

```cmake
# 顶层 CMakeLists.txt

find_program(CCACHE_PROGRAM ccache)
if(CCACHE_PROGRAM)
    set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE "${CCACHE_PROGRAM}")
    message(STATUS "ccache found, compilation will be cached")
endif()
```

ccache 会缓存编译结果，当源文件没有变化时，直接使用缓存的目标文件，可以将编译时间从几分钟缩短到几秒钟。

==== 使用 INTERFACE 库

有时候你想创建一个"虚拟"库，它本身不产生任何编译产物，只是用来聚合其他库或传递编译选项：

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

用户只需要链接 `detector`，就自动获得了所有检测器相关的库。

==== CMake 辅助模块

随着项目增长，你可能会发现一些 CMake 代码在多处重复。可以将这些代码提取到单独的 CMake 模块中，放在 `cmake/` 目录下：

```cmake
# cmake/CompilerWarnings.cmake

# 定义一个函数，为目标启用警告
function(enable_warnings target)
    target_compile_options(${target} PRIVATE
        $<$<CXX_COMPILER_ID:GNU,Clang>:
            -Wall
            -Wextra
            -Wpedantic
            -Wcast-align
            -Wunused
            -Woverloaded-virtual
            -Wnon-virtual-dtor
        >
        $<$<CXX_COMPILER_ID:MSVC>:
            /W4
            /permissive-
        >
    )
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

这种方式可以让构建配置更加DRY（Don't Repeat Yourself），也便于在多个项目之间共享 CMake 代码。

==== 打印依赖信息

调试 CMake 配置时，打印依赖库的详细信息很有帮助：

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
    get_target_property(FMT_INCLUDE_DIR fmt::fmt INTERFACE_INCLUDE_DIRECTORIES)
    get_target_property(FMT_LIBRARY_LOCATION fmt::fmt IMPORTED_LOCATION)
    message(STATUS "fmt Library: ${FMT_LIBRARY_LOCATION}")
    message(STATUS "fmt Include Dirs: ${FMT_INCLUDE_DIR}")
endif()

# Eigen3
if(Eigen3_FOUND)
    message(STATUS "Eigen3 Include Dir: ${EIGEN3_INCLUDE_DIR}")
endif()

# tomlplusplus
if(TARGET tomlplusplus::tomlplusplus)
    get_target_property(TOMLPP_INCLUDE_DIR tomlplusplus::tomlplusplus INTERFACE_INCLUDE_DIRECTORIES)
    message(STATUS "tomlplusplus Include Dirs: ${TOMLPP_INCLUDE_DIR}")
endif()

message(STATUS "-----------------------------------------------")
```

这些信息在排查"找不到头文件"或"链接失败"等问题时非常有用。

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
    rm::detector::ArmorDetector detector;
    rm::tracker::ArmorTracker tracker;

    // 或者使用 using
    using namespace rm;
    detector::ArmorDetector detector2;

    // ...
}
```

命名空间可以层级化，也可以扁平化，取决于项目的复杂度和团队偏好。对于较小的项目，单层命名空间（如 `rm::ArmorDetector`）就够了；对于大型项目，模块级命名空间（如 `rm::detector::ArmorDetector`）可以避免名字冲突。

好的项目结构是代码质量的基础。它让新人能够快速理解项目，让日常开发更加高效，也让构建配置更加清晰可维护。虽然没有放之四海而皆准的"最佳"结构，但遵循社区的常见约定、保持一致性、根据项目需求做出合理的选择，就能建立起一个健康的代码库。


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

几乎每个 C++ 项目都会使用外部库。对于 RoboMaster 视觉项目，OpenCV 处理图像、Eigen 进行矩阵运算、Ceres 解决优化问题——这些第三方库是开发的基石。如何在 CMake 中正确地找到这些库、链接它们，是每个开发者必须掌握的技能。本节将详细介绍 CMake 的依赖管理机制，从基础的 `find_package` 到现代的 FetchContent，让你能够灵活地处理各种依赖场景。

==== find_package：查找已安装的库

`find_package` 是 CMake 中查找外部库的标准方法。它会在系统中搜索指定的库，如果找到，就设置一系列变量供后续使用。

```cmake
# 基本用法
find_package(OpenCV REQUIRED)
```

`REQUIRED` 表示这个库是必需的，如果找不到，CMake 会报错并终止配置。如果库是可选的，可以省略 `REQUIRED`：

```cmake
# 可选依赖
find_package(CUDA QUIET)  # QUIET 表示找不到时不输出警告

if(CUDA_FOUND)
    message(STATUS "CUDA found, enabling GPU acceleration")
    # 使用 CUDA...
else()
    message(STATUS "CUDA not found, using CPU only")
endif()
```

可以指定版本要求：

```cmake
# 要求至少 4.5.0 版本
find_package(OpenCV 4.5.0 REQUIRED)

# 要求精确版本
find_package(OpenCV 4.5.4 EXACT REQUIRED)
```

可以指定需要的组件：

```cmake
# 只需要特定组件
find_package(OpenCV REQUIRED COMPONENTS core imgproc highgui)

# 有些组件是可选的
find_package(Boost REQUIRED COMPONENTS filesystem system)
find_package(Boost OPTIONAL_COMPONENTS python)
```

当 `find_package` 成功时，它会设置一系列变量。传统方式下，这些变量遵循一定的命名约定：

```cmake
find_package(OpenCV REQUIRED)

# 常见的变量
message(STATUS "OpenCV found: ${OpenCV_FOUND}")
message(STATUS "OpenCV version: ${OpenCV_VERSION}")
message(STATUS "OpenCV include dirs: ${OpenCV_INCLUDE_DIRS}")
message(STATUS "OpenCV libraries: ${OpenCV_LIBRARIES}")
```

但不同的库设置的变量可能略有不同，有的用 `OpenCV_LIBS`，有的用 `OPENCV_LIBRARIES`。这种不一致性是传统方式的一个问题。

==== Config 模式与 Module 模式

`find_package` 有两种工作模式：Config 模式和 Module 模式。理解它们的区别有助于排查找不到库的问题。

*Module 模式*使用 CMake 自带的或项目提供的 `FindXXX.cmake` 文件来查找库。这些文件通常位于 CMake 的模块目录或项目的 `cmake/` 目录中。CMake 自带了许多常用库的 Find 模块，如 `FindThreads.cmake`、`FindOpenGL.cmake` 等。

```cmake
# CMake 自带的 Find 模块
find_package(Threads REQUIRED)   # 使用 FindThreads.cmake
find_package(OpenGL REQUIRED)    # 使用 FindOpenGL.cmake
```

Module 模式的查找逻辑由 Find 模块的作者编写，通常会搜索常见的安装位置、检查环境变量、调用 pkg-config 等。

*Config 模式*使用库自己提供的 `XXXConfig.cmake` 或 `xxx-config.cmake` 文件。这些文件由库的作者编写，与库一起安装。现代的 C++ 库大多提供 Config 文件。

```cmake
# 使用库提供的 Config 文件
find_package(OpenCV REQUIRED)    # 使用 OpenCVConfig.cmake
find_package(Eigen3 REQUIRED)    # 使用 Eigen3Config.cmake
find_package(Ceres REQUIRED)     # 使用 CeresConfig.cmake
```

Config 模式更可靠，因为配置文件由库的作者维护，与库的版本完全匹配。它也通常提供导入目标（稍后讨论），使用起来更方便。

CMake 默认先尝试 Config 模式，如果找不到再尝试 Module 模式。可以用 `CONFIG` 或 `MODULE` 关键字强制使用某种模式：

```cmake
# 强制使用 Config 模式
find_package(OpenCV CONFIG REQUIRED)

# 强制使用 Module 模式
find_package(OpenGL MODULE REQUIRED)
```

如果 `find_package` 找不到库，可以通过设置 `CMAKE_PREFIX_PATH` 告诉 CMake 去哪里找：

```bash
# 命令行指定额外的搜索路径
cmake -DCMAKE_PREFIX_PATH="/opt/opencv;/opt/eigen" ..
```

```cmake
# 或者在 CMakeLists.txt 中
list(APPEND CMAKE_PREFIX_PATH "/opt/opencv")
find_package(OpenCV REQUIRED)
```

对于 Config 模式，也可以设置 `XXX_DIR` 变量指向 Config 文件所在目录：

```bash
cmake -DOpenCV_DIR=/opt/opencv/lib/cmake/opencv4 ..
```

==== 导入目标：现代方式

传统的 `find_package` 使用变量来传递库的信息，使用时需要手动设置 include 路径和链接库：

```cmake
# 旧方式：使用变量
find_package(OpenCV REQUIRED)

add_executable(my_app main.cpp)
target_include_directories(my_app PRIVATE ${OpenCV_INCLUDE_DIRS})
target_link_libraries(my_app PRIVATE ${OpenCV_LIBRARIES})
```

现代的 `find_package` 会创建导入目标（imported target），这是一个"虚拟"的 CMake 目标，封装了库的所有使用要求：

```cmake
# 现代方式：使用导入目标
find_package(OpenCV REQUIRED)

add_executable(my_app main.cpp)
target_link_libraries(my_app PRIVATE OpenCV::OpenCV)
```

只需要一行 `target_link_libraries`，include 路径、编译选项、依赖的其他库都会自动传递。这就是为什么现代 CMake 更加简洁。

导入目标的命名通常遵循 `PackageName::TargetName` 的格式。一个包可能提供多个导入目标：

```cmake
find_package(OpenCV REQUIRED)

# OpenCV 提供的导入目标
target_link_libraries(my_app PRIVATE
    OpenCV::core       # 核心功能
    OpenCV::imgproc    # 图像处理
    OpenCV::highgui    # GUI
    OpenCV::calib3d    # 相机标定
    OpenCV::dnn        # 深度学习
)

# 或者使用便利目标链接所有组件
target_link_libraries(my_app PRIVATE OpenCV::OpenCV)
```

导入目标有几个显著优势。首先是自动传递依赖：如果 A 依赖 B，链接 A 时 B 会自动链接。其次是正确的属性传播：目标携带了所有必要的编译选项、include 路径、宏定义。第三是更好的错误检查：如果使用了不存在的目标名，CMake 会报错；而使用未定义的变量只会得到空值。

可以用 `if(TARGET ...)` 检查导入目标是否存在：

```cmake
find_package(OpenCV QUIET)

if(TARGET OpenCV::OpenCV)
    message(STATUS "OpenCV imported target available")
    target_link_libraries(my_app PRIVATE OpenCV::OpenCV)
else()
    message(WARNING "OpenCV not found or no imported targets")
endif()
```

==== 常用库的查找

让我们看看 RoboMaster 开发中常用库的查找方式。

*OpenCV* 是计算机视觉的基础库：

```cmake
find_package(OpenCV REQUIRED)

# 查看版本
message(STATUS "OpenCV version: ${OpenCV_VERSION}")

# 链接（现代方式）
target_link_libraries(my_app PRIVATE OpenCV::OpenCV)

# 或者只链接需要的模块
target_link_libraries(my_app PRIVATE
    OpenCV::core
    OpenCV::imgproc
    OpenCV::imgcodecs
    OpenCV::videoio
)
```

*Eigen* 是 header-only 的线性代数库：

```cmake
find_package(Eigen3 REQUIRED)

# Eigen 是 header-only，只需要 include 路径
target_link_libraries(my_app PRIVATE Eigen3::Eigen)
```

注意包名是 `Eigen3` 不是 `Eigen`。由于 Eigen 是 header-only 的，"链接"它实际上只是添加 include 路径和编译选项，不会有实际的库文件被链接。

*Ceres Solver* 是非线性优化库：

```cmake
find_package(Ceres REQUIRED)

target_link_libraries(my_app PRIVATE Ceres::ceres)
```

Ceres 依赖 Eigen 和其他库，但通过导入目标，这些依赖会自动处理。

*Threads* 是 POSIX 线程库（pthread）：

```cmake
find_package(Threads REQUIRED)

target_link_libraries(my_app PRIVATE Threads::Threads)
```

`Threads::Threads` 是跨平台的，在 Linux 上链接 pthread，在 Windows 上使用 Windows 线程 API。

*Google Test* 是单元测试框架：

```cmake
find_package(GTest REQUIRED)

add_executable(my_tests test_main.cpp)
target_link_libraries(my_tests PRIVATE
    GTest::gtest
    GTest::gtest_main  # 提供 main 函数
)

# 或者使用 gmock
target_link_libraries(my_tests PRIVATE
    GTest::gmock
    GTest::gmock_main
)
```

*Boost* 是一个大型的 C++ 库集合：

```cmake
find_package(Boost REQUIRED COMPONENTS filesystem system)

target_link_libraries(my_app PRIVATE
    Boost::filesystem
    Boost::system
)

# header-only 部分不需要链接
find_package(Boost REQUIRED)
target_link_libraries(my_app PRIVATE Boost::boost)  # 只有 headers
```

*fmt* 是现代的格式化库：

```cmake
find_package(fmt REQUIRED)

target_link_libraries(my_app PRIVATE fmt::fmt)

# header-only 模式（如果这样编译的话）
target_link_libraries(my_app PRIVATE fmt::fmt-header-only)
```

*spdlog* 是高性能日志库：

```cmake
find_package(spdlog REQUIRED)

target_link_libraries(my_app PRIVATE spdlog::spdlog)
```

==== pkg-config：查找没有 CMake 支持的库

有些库没有提供 CMake 配置文件，但提供了 pkg-config 支持（`.pc` 文件）。CMake 可以通过 `PkgConfig` 模块来使用它们：

```cmake
find_package(PkgConfig REQUIRED)

# 查找库
pkg_check_modules(LIBUSB REQUIRED libusb-1.0)

# 使用（传统方式）
target_include_directories(my_app PRIVATE ${LIBUSB_INCLUDE_DIRS})
target_link_libraries(my_app PRIVATE ${LIBUSB_LIBRARIES})

# 或者创建导入目标（CMake 3.6+）
pkg_check_modules(LIBUSB REQUIRED IMPORTED_TARGET libusb-1.0)
target_link_libraries(my_app PRIVATE PkgConfig::LIBUSB)
```

`pkg_check_modules` 会设置以下变量：

- `<PREFIX>_FOUND`：是否找到
- `<PREFIX>_INCLUDE_DIRS`：头文件目录
- `<PREFIX>_LIBRARIES`：库文件
- `<PREFIX>_LIBRARY_DIRS`：库文件目录
- `<PREFIX>_CFLAGS`：编译标志
- `<PREFIX>_LDFLAGS`：链接标志

使用 `IMPORTED_TARGET` 时会创建 `PkgConfig::<PREFIX>` 导入目标，这是推荐的方式。

==== FetchContent：下载并构建依赖

当依赖没有安装在系统中时，`FetchContent` 模块可以自动下载源代码并构建。这是管理依赖的现代方式，特别适合 header-only 库和小型依赖。

```cmake
include(FetchContent)

# 声明依赖
FetchContent_Declare(
    json
    GIT_REPOSITORY https://github.com/nlohmann/json.git
    GIT_TAG v3.11.2
)

# 下载并添加到构建
FetchContent_MakeAvailable(json)

# 使用
target_link_libraries(my_app PRIVATE nlohmann_json::nlohmann_json)
```

`FetchContent_Declare` 声明依赖的来源，可以是 Git 仓库、压缩包 URL 等：

```cmake
# 从 Git 仓库
FetchContent_Declare(
    fmt
    GIT_REPOSITORY https://github.com/fmtlib/fmt.git
    GIT_TAG 10.1.1
)

# 从 URL 下载压缩包
FetchContent_Declare(
    googletest
    URL https://github.com/google/googletest/archive/release-1.12.1.tar.gz
    URL_HASH SHA256=...
)

# 从本地目录（用于开发）
FetchContent_Declare(
    mylib
    SOURCE_DIR /path/to/local/mylib
)
```

`FetchContent_MakeAvailable` 会下载源代码（如果还没下载），然后调用 `add_subdirectory` 将其添加到构建中。这意味着依赖项目的 CMakeLists.txt 会被执行，其定义的目标可以直接使用。

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

# 一次性获取所有依赖
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

# 在 MakeAvailable 之前设置选项
set(BUILD_GMOCK OFF CACHE BOOL "" FORCE)
set(INSTALL_GTEST OFF CACHE BOOL "" FORCE)

FetchContent_MakeAvailable(googletest)
```

FetchContent 的优点是简单、自动化，适合管理少量依赖。缺点是每次配置都可能触发下载（虽然会缓存），而且会增加配置时间。对于大型依赖或需要特殊编译选项的库，可能不太合适。

==== ExternalProject：更复杂的外部项目

`ExternalProject` 是比 FetchContent 更强大但也更复杂的模块。它可以下载、配置、构建、安装外部项目，支持任何构建系统（不限于 CMake）。

```cmake
include(ExternalProject)

ExternalProject_Add(
    external_opencv
    GIT_REPOSITORY https://github.com/opencv/opencv.git
    GIT_TAG 4.8.0
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/opencv_install
        -DBUILD_EXAMPLES=OFF
        -DBUILD_TESTS=OFF
        -DBUILD_DOCS=OFF
)
```

与 FetchContent 不同，ExternalProject 在构建阶段（而非配置阶段）执行，外部项目的目标不会直接暴露给主项目。这意味着你需要手动处理链接：

```cmake
ExternalProject_Add(
    external_opencv
    GIT_REPOSITORY https://github.com/opencv/opencv.git
    GIT_TAG 4.8.0
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/opencv_install
        -DBUILD_EXAMPLES=OFF
    INSTALL_DIR ${CMAKE_BINARY_DIR}/opencv_install
)

# 获取安装目录
ExternalProject_Get_Property(external_opencv INSTALL_DIR)

# 创建导入目标
add_library(opencv_imported INTERFACE)
add_dependencies(opencv_imported external_opencv)
target_include_directories(opencv_imported INTERFACE ${INSTALL_DIR}/include/opencv4)
target_link_directories(opencv_imported INTERFACE ${INSTALL_DIR}/lib)
target_link_libraries(opencv_imported INTERFACE opencv_core opencv_imgproc)

# 使用
target_link_libraries(my_app PRIVATE opencv_imported)
```

ExternalProject 的复杂性使得它主要用于以下场景：

- 需要从源码编译大型依赖（如 OpenCV、PCL）
- 依赖使用非 CMake 构建系统
- 需要对依赖进行补丁或自定义配置
- 超级构建（superbuild）模式

对于大多数情况，推荐优先使用 `find_package`（依赖已安装）或 `FetchContent`（需要自动下载）。

==== 系统库 vs 本地库

在开发中，你经常需要在系统安装的库和本地编译的库之间切换。系统库通常通过包管理器安装，稳定但可能版本较旧；本地库可以使用最新版本或自定义配置。

```cmake
# 优先使用系统库，找不到时用 FetchContent
find_package(spdlog QUIET)

if(NOT spdlog_FOUND)
    message(STATUS "spdlog not found, fetching from GitHub")
    include(FetchContent)
    FetchContent_Declare(
        spdlog
        GIT_REPOSITORY https://github.com/gabime/spdlog.git
        GIT_TAG v1.12.0
    )
    FetchContent_MakeAvailable(spdlog)
endif()

target_link_libraries(my_app PRIVATE spdlog::spdlog)
```

可以用选项让用户选择：

```cmake
option(USE_SYSTEM_SPDLOG "Use system spdlog instead of fetching" ON)

if(USE_SYSTEM_SPDLOG)
    find_package(spdlog REQUIRED)
else()
    include(FetchContent)
    FetchContent_Declare(
        spdlog
        GIT_REPOSITORY https://github.com/gabime/spdlog.git
        GIT_TAG v1.12.0
    )
    FetchContent_MakeAvailable(spdlog)
endif()

target_link_libraries(my_app PRIVATE spdlog::spdlog)
```

对于安装在非标准位置的库，通过 `CMAKE_PREFIX_PATH` 指定：

```bash
# 使用本地编译的 OpenCV
cmake -DCMAKE_PREFIX_PATH=/home/user/opencv_build/install ..
```

==== 编写 Find 模块

如果某个库既没有 Config 文件也没有 pkg-config 支持，你可能需要自己编写 Find 模块。以下是一个简单的例子：

```cmake
# cmake/FindMyLib.cmake

# 搜索头文件
find_path(MYLIB_INCLUDE_DIR
    NAMES mylib.h
    PATHS
        /usr/include
        /usr/local/include
        $ENV{MYLIB_ROOT}/include
)

# 搜索库文件
find_library(MYLIB_LIBRARY
    NAMES mylib
    PATHS
        /usr/lib
        /usr/local/lib
        $ENV{MYLIB_ROOT}/lib
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

# 隐藏内部变量
mark_as_advanced(MYLIB_INCLUDE_DIR MYLIB_LIBRARY)
```

使用这个 Find 模块：

```cmake
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
find_package(MyLib REQUIRED)
target_link_libraries(my_app PRIVATE MyLib::MyLib)
```

==== 完整示例

让我们看一个 RoboMaster 项目的完整依赖配置：

```cmake
cmake_minimum_required(VERSION 3.16)
project(rm_vision VERSION 2.0.0 LANGUAGES CXX)

# 添加自定义 Find 模块路径
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

#=============================================================================
# 必需依赖
#=============================================================================

# OpenCV：图像处理
find_package(OpenCV 4.5 REQUIRED COMPONENTS
    core imgproc imgcodecs videoio highgui calib3d dnn
)
message(STATUS "Found OpenCV ${OpenCV_VERSION}")

# Eigen：线性代数
find_package(Eigen3 3.3 REQUIRED)
message(STATUS "Found Eigen ${Eigen3_VERSION}")

# Threads：多线程
find_package(Threads REQUIRED)

#=============================================================================
# 可选依赖
#=============================================================================

# Ceres：非线性优化（可选）
find_package(Ceres QUIET)
if(Ceres_FOUND)
    message(STATUS "Found Ceres ${Ceres_VERSION}, enabling advanced optimization")
    set(HAVE_CERES ON)
else()
    message(STATUS "Ceres not found, some optimization features disabled")
    set(HAVE_CERES OFF)
endif()

# CUDA：GPU 加速（可选）
find_package(CUDA QUIET)
if(CUDA_FOUND)
    message(STATUS "Found CUDA ${CUDA_VERSION}, enabling GPU acceleration")
    set(HAVE_CUDA ON)
else()
    message(STATUS "CUDA not found, using CPU only")
    set(HAVE_CUDA OFF)
endif()

#=============================================================================
# 使用 FetchContent 获取的依赖
#=============================================================================

include(FetchContent)

# fmt：格式化库
find_package(fmt QUIET)
if(NOT fmt_FOUND)
    message(STATUS "Fetching fmt...")
    FetchContent_Declare(
        fmt
        GIT_REPOSITORY https://github.com/fmtlib/fmt.git
        GIT_TAG 10.1.1
    )
    FetchContent_MakeAvailable(fmt)
endif()

# spdlog：日志库
find_package(spdlog QUIET)
if(NOT spdlog_FOUND)
    message(STATUS "Fetching spdlog...")
    FetchContent_Declare(
        spdlog
        GIT_REPOSITORY https://github.com/gabime/spdlog.git
        GIT_TAG v1.12.0
    )
    set(SPDLOG_FMT_EXTERNAL ON CACHE BOOL "" FORCE)
    FetchContent_MakeAvailable(spdlog)
endif()

# nlohmann/json：JSON 解析
FetchContent_Declare(
    json
    GIT_REPOSITORY https://github.com/nlohmann/json.git
    GIT_TAG v3.11.2
)
FetchContent_MakeAvailable(json)

#=============================================================================
# 测试依赖
#=============================================================================

option(BUILD_TESTS "Build unit tests" ON)

if(BUILD_TESTS)
    find_package(GTest QUIET)
    if(NOT GTest_FOUND)
        message(STATUS "Fetching GoogleTest...")
        FetchContent_Declare(
            googletest
            GIT_REPOSITORY https://github.com/google/googletest.git
            GIT_TAG v1.14.0
        )
        set(BUILD_GMOCK ON CACHE BOOL "" FORCE)
        set(INSTALL_GTEST OFF CACHE BOOL "" FORCE)
        FetchContent_MakeAvailable(googletest)
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
        fmt::fmt
        spdlog::spdlog
        nlohmann_json::nlohmann_json
    PRIVATE
        Threads::Threads
)

# 条件链接可选依赖
if(HAVE_CERES)
    target_link_libraries(rm_core PUBLIC Ceres::ceres)
    target_compile_definitions(rm_core PUBLIC HAVE_CERES)
endif()

# 添加更多目标...
add_subdirectory(src)
add_subdirectory(apps)

if(BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()
```

这个例子展示了依赖管理的最佳实践：

1. 必需依赖使用 `REQUIRED`，确保找不到时报错
2. 可选依赖使用 `QUIET`，找不到时优雅降级
3. 小型依赖优先使用系统版本，找不到时用 FetchContent
4. 通过编译定义（`HAVE_CERES`）让代码知道哪些功能可用
5. 清晰的日志输出，让用户了解配置情况

正确管理依赖是 CMake 配置中最重要的部分之一。掌握了 `find_package` 和 FetchContent，你就能够处理大多数依赖场景，让项目在不同环境中都能顺利构建。


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

到目前为止，我们学习的都是如何构建项目。但如果你写了一个有用的库，想让团队的其他成员或者更广泛的社区使用，该怎么办？他们需要能够在自己的项目中 `find_package` 你的库，然后像使用 OpenCV 或 Eigen 一样使用它。这就需要正确地安装和导出你的库。本节将介绍如何让你的库成为一个"好公民"——可以被正确安装到系统中，并被其他 CMake 项目方便地使用。

==== 为什么需要安装

在开发阶段，你可以直接在构建目录中运行程序，链接构建目录中的库。但这种方式有几个问题：构建目录的结构可能很乱，不适合分发；其他项目无法通过 `find_package` 找到你的库；每次重新构建都可能改变文件位置。

安装（install）解决了这些问题。它将构建产物（可执行文件、库、头文件等）复制到一个标准的、组织良好的目录结构中。安装后的文件可以被系统中的其他程序使用，也可以打包分发给其他人。

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

`DESTINATION` 指定安装位置，是相对于 `CMAKE_INSTALL_PREFIX` 的路径。默认的 `CMAKE_INSTALL_PREFIX` 在 Unix 系统上是 `/usr/local`，在 Windows 上是 `C:/Program Files/${PROJECT_NAME}`。

运行安装：

```bash
# 构建
cmake -DCMAKE_BUILD_TYPE=Release ..
cmake --build .

# 安装（可能需要 sudo）
sudo cmake --install .

# 或者安装到自定义位置
cmake --install . --prefix /opt/myproject
```

也可以在配置时指定安装前缀：

```bash
cmake -DCMAKE_INSTALL_PREFIX=/opt/myproject ..
cmake --build .
cmake --install .
```

==== 使用 GNUInstallDirs

不同平台的安装目录约定可能不同（比如 64 位库可能放在 `lib64` 而不是 `lib`）。CMake 提供了 `GNUInstallDirs` 模块来处理这些差异：

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
- `CMAKE_INSTALL_DOCDIR`：文档（`share/doc/${PROJECT_NAME}`）

使用这些变量可以让你的安装更加规范和可移植。

==== 安装头文件

头文件的安装有几种方式。最常用的是安装整个目录：

```cmake
# 安装 include 目录下的所有文件
install(DIRECTORY include/
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)
```

注意 `include/` 后面的斜杠——它表示安装目录的内容而不是目录本身。如果写 `include`（没有斜杠），会安装为 `${CMAKE_INSTALL_INCLUDEDIR}/include/...`。

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
    ${CMAKE_CURRENT_SOURCE_DIR}/include/mylib/config.h.in
    ${CMAKE_CURRENT_BINARY_DIR}/include/mylib/config.h
)

# 安装生成的头文件
install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/include/mylib/config.h
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/mylib
)
```

==== 安装其他文件

除了目标和头文件，你可能还需要安装其他文件：

```cmake
# 安装数据文件
install(DIRECTORY data/
    DESTINATION ${CMAKE_INSTALL_DATADIR}/${PROJECT_NAME}
)

# 安装配置文件
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

安装库文件和头文件只是第一步。为了让其他项目能够通过 `find_package` 使用你的库，还需要导出目标信息——包括库的位置、include 路径、编译选项、依赖等。

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

`EXPORT MyLibTargets` 表示将这个目标添加到名为 `MyLibTargets` 的导出集中。`INCLUDES DESTINATION` 指定安装后的 include 路径，它会被记录到导出的目标信息中。

然后，安装导出集：

```cmake
install(EXPORT MyLibTargets
    FILE MyLibTargets.cmake
    NAMESPACE MyLib::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/MyLib
)
```

这会生成一个 `MyLibTargets.cmake` 文件，包含导入目标的定义。`NAMESPACE MyLib::` 会给导出的目标添加前缀，所以其他项目使用时是 `MyLib::mylib` 而不是 `mylib`。

==== 生成 Config 文件

只有 `MyLibTargets.cmake` 还不够，你还需要一个 `MyLibConfig.cmake` 文件作为入口点。这个文件会被 `find_package(MyLib)` 找到并执行。

最简单的方式是手写一个：

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

`@PACKAGE_INIT@` 是一个占位符，会被替换为一些辅助宏。`check_required_components` 用于检查用户请求的组件是否都存在。

如果你的库依赖其他库，需要在 Config 文件中查找它们：

```cmake
# MyLibConfig.cmake.in
@PACKAGE_INIT@

# 查找依赖
include(CMakeFindDependencyMacro)
find_dependency(Eigen3)
find_dependency(OpenCV)

include("${CMAKE_CURRENT_LIST_DIR}/MyLibTargets.cmake")

check_required_components(MyLib)
```

`find_dependency` 和 `find_package` 类似，但它会正确传播 `REQUIRED` 和 `QUIET` 选项。

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

`COMPATIBILITY` 指定版本兼容性策略：

- `ExactVersion`：必须精确匹配
- `SameMajorVersion`：主版本号相同即可（如 1.2.0 兼容 1.0.0）
- `SameMinorVersion`：主版本和次版本号相同（如 1.2.3 兼容 1.2.0）
- `AnyNewerVersion`：任何更新的版本都可以

对于遵循语义化版本的库，`SameMajorVersion` 是最常用的选择。

==== 完整的安装配置示例

让我们看一个完整的例子，展示如何正确配置一个库的安装和导出：

```cmake
cmake_minimum_required(VERSION 3.16)
project(RMCore VERSION 2.0.0 LANGUAGES CXX)

# 包含必要的模块
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

# 依赖
find_package(Eigen3 REQUIRED)
find_package(OpenCV REQUIRED)

#=============================================================================
# 定义库
#=============================================================================

add_library(rm_core
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
    PRIVATE OpenCV::OpenCV
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
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/RMCore
)

# 生成并安装 Config 文件
configure_package_config_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake/RMCoreConfig.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/RMCoreConfig.cmake
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/RMCore
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
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/RMCore
)
```

对应的 Config 模板文件：

```cmake
# cmake/RMCoreConfig.cmake.in
@PACKAGE_INIT@

include(CMakeFindDependencyMacro)

# 查找依赖
find_dependency(Eigen3)
# 注意：OpenCV 是 PRIVATE 依赖，不需要在这里查找

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

==== 支持构建目录导出

有时候，你希望在不安装的情况下，其他项目也能 `find_package` 你的库（比如在同一个工作空间的多个项目）。可以导出到构建目录：

```cmake
# 导出到构建目录
export(EXPORT RMCoreTargets
    FILE ${CMAKE_CURRENT_BINARY_DIR}/RMCoreTargets.cmake
    NAMESPACE RMCore::
)

# 将构建目录注册到用户包注册表
export(PACKAGE RMCore)
```

`export(PACKAGE ...)` 会在用户的 CMake 包注册表中注册这个包，其他项目就可以找到它了。这在开发阶段很方便，但正式发布时应该使用完整的安装流程。

==== 安装多个组件

对于大型项目，可能希望让用户选择安装哪些组件：

```cmake
# 运行时组件
install(TARGETS rm_vision
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    COMPONENT Runtime
)

# 开发组件
install(TARGETS rm_core
    EXPORT RMCoreTargets
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    COMPONENT Development
)

install(DIRECTORY include/
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
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
cmake --install . --component Runtime

# 只安装开发组件
cmake --install . --component Development
```

==== CPack：打包与分发

CMake 的 CPack 模块可以将项目打包成各种格式，便于分发。

```cmake
# 在 CMakeLists.txt 末尾添加
set(CPACK_PACKAGE_NAME "RMCore")
set(CPACK_PACKAGE_VERSION ${PROJECT_VERSION})
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "RoboMaster Core Library")
set(CPACK_PACKAGE_VENDOR "RoboMaster Team")
set(CPACK_PACKAGE_CONTACT "team@example.com")

# Debian 包配置
set(CPACK_DEBIAN_PACKAGE_DEPENDS "libeigen3-dev, libopencv-dev")

# RPM 包配置
set(CPACK_RPM_PACKAGE_REQUIRES "eigen3-devel, opencv-devel")

# 包含 CPack
include(CPack)
```

生成包：

```bash
# 构建后生成包
cmake --build .
cpack

# 生成特定格式的包
cpack -G DEB   # Debian 包
cpack -G RPM   # RPM 包
cpack -G TGZ   # tar.gz 压缩包
cpack -G ZIP   # ZIP 压缩包
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

# 每个组件单独打包
set(CPACK_COMPONENTS_GROUPING ONE_PER_GROUP)
```

==== 安装脚本

有时候安装过程需要执行一些脚本，比如更新库缓存：

```cmake
# 安装后执行的脚本
install(CODE "
    execute_process(COMMAND ldconfig)
    message(STATUS \"Library cache updated\")
")

# 或者从文件执行
install(SCRIPT ${CMAKE_CURRENT_SOURCE_DIR}/cmake/post_install.cmake)
```

==== 卸载支持

CMake 默认不提供卸载目标，但可以手动添加：

```cmake
# 创建卸载目标
if(NOT TARGET uninstall)
    configure_file(
        ${CMAKE_CURRENT_SOURCE_DIR}/cmake/cmake_uninstall.cmake.in
        ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake
        IMMEDIATE @ONLY
    )

    add_custom_target(uninstall
        COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake
    )
endif()
```

卸载脚本模板：

```cmake
# cmake/cmake_uninstall.cmake.in
if(NOT EXISTS "@CMAKE_BINARY_DIR@/install_manifest.txt")
    message(FATAL_ERROR "Cannot find install manifest: @CMAKE_BINARY_DIR@/install_manifest.txt")
endif()

file(READ "@CMAKE_BINARY_DIR@/install_manifest.txt" files)
string(REGEX REPLACE "\n" ";" files "${files}")
foreach(file ${files})
    message(STATUS "Uninstalling $ENV{DESTDIR}${file}")
    if(IS_SYMLINK "$ENV{DESTDIR}${file}" OR EXISTS "$ENV{DESTDIR}${file}")
        exec_program(
            "@CMAKE_COMMAND@" ARGS "-E remove \"$ENV{DESTDIR}${file}\""
            OUTPUT_VARIABLE rm_out
            RETURN_VALUE rm_retval
        )
        if(NOT "${rm_retval}" STREQUAL 0)
            message(FATAL_ERROR "Problem when removing $ENV{DESTDIR}${file}")
        endif()
    else()
        message(STATUS "File $ENV{DESTDIR}${file} does not exist.")
    endif()
endforeach()
```

使用：

```bash
sudo cmake --build . --target uninstall
```

==== 最佳实践总结

编写可安装的库时，遵循以下最佳实践：

1. *使用 GNUInstallDirs*：确保安装路径符合平台约定

2. *使用生成器表达式区分构建和安装路径*：
   ```cmake
   target_include_directories(mylib PUBLIC
       $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
       $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
   )
   ```

3. *使用命名空间*：导出目标时添加命名空间前缀（如 `MyLib::`）

4. *创建别名目标*：便于在项目内部使用相同的目标名称
   ```cmake
   add_library(MyLib::mylib ALIAS mylib)
   ```

5. *处理依赖*：在 Config 文件中使用 `find_dependency` 查找 PUBLIC 依赖

6. *提供版本文件*：支持版本检查

7. *考虑组件*：大型项目应该分组件安装

8. *测试安装*：在 CI 中测试完整的安装和使用流程

正确的安装和导出配置让你的库成为 CMake 生态的一等公民。用户可以像使用任何标准库一样使用你的库，无需了解内部结构，只需要简单的 `find_package` 和 `target_link_libraries`。这种良好的封装是高质量库的标志。


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

ROS 2（Robot Operating System 2）是机器人软件开发的标准框架，RoboMaster 的许多视觉和控制系统都基于 ROS 2 构建。ROS 2 使用 `ament_cmake` 作为 C++ 包的构建系统，它是对 CMake 的封装和扩展，提供了处理 ROS 2 特有需求（如消息类型、服务、节点发现等）的便利功能。理解 ament_cmake 是开发 ROS 2 应用的基础。

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

与普通的 CMake 项目相比，ROS 2 包多了 `package.xml` 文件，它描述了包的元信息和依赖关系。ROS 2 的构建工具（colcon）会读取这个文件来确定构建顺序和依赖。

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

  <!-- 构建时依赖 -->
  <build_depend>rclcpp</build_depend>
  <build_depend>std_msgs</build_depend>
  <build_depend>sensor_msgs</build_depend>
  <build_depend>cv_bridge</build_depend>
  <build_depend>OpenCV</build_depend>

  <!-- 运行时依赖 -->
  <exec_depend>rclcpp</exec_depend>
  <exec_depend>std_msgs</exec_depend>
  <exec_depend>sensor_msgs</exec_depend>
  <exec_depend>cv_bridge</exec_depend>

  <!-- 构建和运行时都需要（简写） -->
  <depend>geometry_msgs</depend>
  <depend>tf2_ros</depend>

  <!-- 测试依赖 -->
  <test_depend>ament_lint_auto</test_depend>
  <test_depend>ament_cmake_gtest</test_depend>

  <export>
    <build_type>ament_cmake</build_type>
  </export>
</package>
```

依赖类型说明：

- `buildtool_depend`：构建工具依赖，如 `ament_cmake`
- `build_depend`：只在编译时需要的依赖
- `exec_depend`：只在运行时需要的依赖
- `depend`：编译和运行时都需要（等价于 `build_depend` + `exec_depend`）
- `test_depend`：只在测试时需要的依赖

`<export>` 标签中的 `<build_type>` 告诉 colcon 使用哪种构建系统。对于 C++ 包，通常是 `ament_cmake`。

==== ament_cmake vs ament_python

ROS 2 支持两种主要的包类型：

- `ament_cmake`：用于 C/C++ 包，基于 CMake
- `ament_python`：用于纯 Python 包，使用 setuptools

对于 RoboMaster 视觉系统这类需要高性能的应用，通常使用 `ament_cmake`。但你也可以创建混合包，用 C++ 实现核心功能，用 Python 编写高层逻辑或工具脚本。

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

==== 基本的 CMakeLists.txt 结构

ROS 2 包的 CMakeLists.txt 有一些固定的模式：

```cmake
cmake_minimum_required(VERSION 3.8)
project(my_package)

# 设置编译选项
if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# 查找依赖
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)

# 定义可执行文件
add_executable(my_node src/my_node.cpp)
ament_target_dependencies(my_node rclcpp std_msgs)

# 安装目标
install(TARGETS my_node
  DESTINATION lib/${PROJECT_NAME}
)

# 必须：调用 ament_package
ament_package()
```

几个关键点：

1. 必须 `find_package(ament_cmake REQUIRED)`
2. ROS 2 依赖通过 `find_package` 查找
3. 使用 `ament_target_dependencies` 简化依赖声明
4. 可执行文件安装到 `lib/${PROJECT_NAME}` 而不是 `bin`
5. 必须在最后调用 `ament_package()`

==== ament_target_dependencies：简化依赖声明

`ament_target_dependencies` 是 ament_cmake 提供的宏，它比原生的 `target_link_libraries` 更方便：

```cmake
# ament_cmake 方式（推荐）
ament_target_dependencies(my_node
  rclcpp
  std_msgs
  sensor_msgs
  cv_bridge
)

# 等价的原生 CMake 方式（更繁琐）
target_link_libraries(my_node
  ${rclcpp_LIBRARIES}
  ${std_msgs_LIBRARIES}
  ${sensor_msgs_LIBRARIES}
  ${cv_bridge_LIBRARIES}
)
target_include_directories(my_node PUBLIC
  ${rclcpp_INCLUDE_DIRS}
  ${std_msgs_INCLUDE_DIRS}
  ${sensor_msgs_INCLUDE_DIRS}
  ${cv_bridge_INCLUDE_DIRS}
)
```

`ament_target_dependencies` 会自动处理 include 路径、库链接和编译定义。对于 ROS 2 包，推荐使用这个宏。

但有时候你需要混合使用：

```cmake
# ROS 2 依赖用 ament_target_dependencies
ament_target_dependencies(my_node
  rclcpp
  sensor_msgs
)

# 非 ROS 依赖用 target_link_libraries
find_package(Eigen3 REQUIRED)
find_package(OpenCV REQUIRED)
target_link_libraries(my_node
  Eigen3::Eigen
  OpenCV::OpenCV
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

# 图像传输（支持压缩）
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
find_package(tf2_ros REQUIRED)
find_package(tf2_geometry_msgs REQUIRED)

# 非 ROS 依赖
find_package(OpenCV REQUIRED)
find_package(Eigen3 REQUIRED)
```

==== 创建库

如果你的包提供库给其他包使用，需要正确配置导出：

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
ament_target_dependencies(${PROJECT_NAME}_lib
  rclcpp
  sensor_msgs
  cv_bridge
)

# 导出依赖（让其他包知道需要哪些依赖）
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

使用现代 CMake 目标导出的方式（推荐）：

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

ament_target_dependencies(${PROJECT_NAME}_lib
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
)

# 导出目标
ament_export_targets(${PROJECT_NAME}Targets HAS_LIBRARY_TARGET)

# 导出依赖
ament_export_dependencies(rclcpp sensor_msgs)
```

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
target_link_libraries(my_node "${cpp_typesupport_target}")
```

package.xml 需要添加相应依赖：

```xml
<buildtool_depend>rosidl_default_generators</buildtool_depend>
<depend>geometry_msgs</depend>
<depend>builtin_interfaces</depend>

<member_of_group>rosidl_interface_packages</member_of_group>
```

在代码中使用自定义消息：

```cpp
#include "my_package/msg/aim_target.hpp"

void callback(const my_package::msg::AimTarget::SharedPtr msg) {
    RCLCPP_INFO(this->get_logger(), "Target %d at (%.2f, %.2f, %.2f)",
        msg->id, msg->position.x, msg->position.y, msg->position.z);
}
```

==== 组件化节点

ROS 2 推荐使用组件化节点，它们可以在同一进程中加载多个节点，减少通信开销：

```cmake
# 创建组件库
add_library(detector_component SHARED
  src/detector_node.cpp
)

target_include_directories(detector_component PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:include>
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

组件节点的代码：

```cpp
#include <rclcpp/rclcpp.hpp>
#include <sensor_msgs/msg/image.hpp>

namespace rm_vision {

class DetectorNode : public rclcpp::Node {
public:
    explicit DetectorNode(const rclcpp::NodeOptions& options)
        : Node("detector_node", options) {
        // 初始化...
    }
    
private:
    // 成员...
};

}  // namespace rm_vision

#include "rclcpp_components/register_node_macro.hpp"
RCLCPP_COMPONENTS_REGISTER_NODE(rm_vision::DetectorNode)
```

==== 安装 launch 文件

ROS 2 的 launch 文件通常用 Python 编写，需要安装到正确位置：

```cmake
# 安装 launch 文件
install(DIRECTORY launch/
  DESTINATION share/${PROJECT_NAME}/launch
)
```

launch 文件示例 `launch/vision_launch.py`：

```python
from launch import LaunchDescription
from launch_ros.actions import Node
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from ament_index_python.packages import get_package_share_directory
import os

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
            parameters=[config_file, {'use_sim_time': LaunchConfiguration('use_sim_time')}],
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

==== 安装配置文件

配置文件（YAML 参数文件、模型文件等）需要安装到 share 目录：

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
#include <ament_index_cpp/get_package_share_directory.hpp>

std::string pkg_share = ament_index_cpp::get_package_share_directory("rm_vision");
std::string model_path = pkg_share + "/models/detector.onnx";
```

==== colcon build：ROS 2 的构建工具

ROS 2 使用 colcon 作为构建工具，它会处理工作空间中所有包的构建：

```bash
# 创建工作空间
mkdir -p ~/ros2_ws/src
cd ~/ros2_ws/src

# 克隆包
git clone https://github.com/example/rm_vision.git

# 返回工作空间根目录
cd ~/ros2_ws

# 构建所有包
colcon build

# 只构建特定包
colcon build --packages-select rm_vision

# 构建包及其依赖
colcon build --packages-up-to rm_vision

# 使用 Release 模式
colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release

# 并行构建（默认已启用）
colcon build --parallel-workers 4
```

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
# 加载工作空间环境
source ~/ros2_ws/install/setup.bash

# 运行节点
ros2 run rm_vision detector_node

# 使用 launch 文件
ros2 launch rm_vision vision_launch.py
```

==== --symlink-install：开发便利选项

`--symlink-install` 选项在安装时创建符号链接而不是复制文件，这对开发非常有用：

```bash
colcon build --symlink-install
```

好处：

1. 修改 Python 代码、launch 文件、配置文件后无需重新构建
2. 修改 C++ 头文件后，只需重新编译，无需重新安装
3. 节省磁盘空间

```bash
# 开发工作流
colcon build --symlink-install

# 修改 launch 文件 - 直接生效，无需重新构建
vim src/rm_vision/launch/vision_launch.py
ros2 launch rm_vision vision_launch.py  # 使用新的 launch 文件

# 修改配置文件 - 直接生效
vim src/rm_vision/config/params.yaml
ros2 run rm_vision detector_node  # 使用新的配置

# 修改 C++ 代码 - 需要重新编译
vim src/rm_vision/src/detector_node.cpp
colcon build --packages-select rm_vision  # 重新编译
```

注意：`--symlink-install` 对可执行文件和库不起作用，它们仍然需要重新构建。

==== 测试

ROS 2 使用 ament 的测试框架：

```cmake
if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  ament_lint_auto_find_test_dependencies()
  
  # 单元测试
  find_package(ament_cmake_gtest REQUIRED)
  ament_add_gtest(test_detector test/test_detector.cpp)
  target_link_libraries(test_detector ${PROJECT_NAME}_lib)
  
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

==== 完整示例：视觉节点的 CMakeLists.txt

让我们看一个完整的 RoboMaster 视觉包配置：

```cmake
cmake_minimum_required(VERSION 3.8)
project(rm_vision)

# 编译选项
if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# C++ 标准
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

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

# 坐标变换
find_package(tf2 REQUIRED)
find_package(tf2_ros REQUIRED)
find_package(tf2_geometry_msgs REQUIRED)

# 非 ROS 依赖
find_package(OpenCV REQUIRED)
find_package(Eigen3 REQUIRED)

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

target_include_directories(${PROJECT_NAME}_core PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:include>
)

target_link_libraries(${PROJECT_NAME}_core
  Eigen3::Eigen
  opencv_core
  opencv_imgproc
  opencv_dnn
)

#=============================================================================
# 节点组件
#=============================================================================

# 检测节点
add_library(detector_component SHARED
  src/nodes/detector_node.cpp
)

target_include_directories(detector_component PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:include>
)

target_link_libraries(detector_component
  ${PROJECT_NAME}_core
  "${cpp_typesupport_target}"
)

ament_target_dependencies(detector_component
  rclcpp
  rclcpp_components
  sensor_msgs
  cv_bridge
  image_transport
)

rclcpp_components_register_node(detector_component
  PLUGIN "rm_vision::DetectorNode"
  EXECUTABLE detector_node
)

# 跟踪节点
add_library(tracker_component SHARED
  src/nodes/tracker_node.cpp
)

target_include_directories(tracker_component PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:include>
)

target_link_libraries(tracker_component
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

target_include_directories(aim_component PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<INSTALL_INTERFACE:include>
)

target_link_libraries(aim_component
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

# 安装库
install(TARGETS
    ${PROJECT_NAME}_core
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
  target_link_libraries(test_detector ${PROJECT_NAME}_core)
  
  ament_add_gtest(test_tracker test/test_tracker.cpp)
  target_link_libraries(test_tracker ${PROJECT_NAME}_core)
endif()

#=============================================================================
# 导出
#=============================================================================

ament_export_include_directories(include)
ament_export_libraries(${PROJECT_NAME}_core)
ament_export_dependencies(
  rclcpp
  sensor_msgs
  geometry_msgs
  cv_bridge
  tf2_ros
  OpenCV
  Eigen3
)

# 必须在最后调用
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

  <build_depend>OpenCV</build_depend>
  <build_depend>eigen</build_depend>

  <test_depend>ament_lint_auto</test_depend>
  <test_depend>ament_cmake_gtest</test_depend>

  <member_of_group>rosidl_interface_packages</member_of_group>

  <export>
    <build_type>ament_cmake</build_type>
  </export>
</package>
```

这个完整示例展示了一个典型 RoboMaster ROS 2 视觉包的结构，包括：

- 自定义消息类型
- 核心算法库
- 多个组件化节点
- 正确的依赖处理
- 完整的安装配置
- 测试支持
- 库导出

掌握了 ROS 2 包的构建配置，你就可以开发功能完整、结构清晰的机器人软件，并与 ROS 2 生态系统无缝集成。


=== 常见问题与调试
// CMake 疑难解答
// - "找不到包"：CMAKE_PREFIX_PATH
// - "未定义的引用"：链接顺序问题
// - "头文件找不到"：include 路径
// - "ABI 不兼容"：编译器版本不匹配
// - 查看详细信息：cmake --debug-find
// - 打印变量：message(STATUS ${VAR})
// - 检查编译命令：make VERBOSE=1
// - CMake 最低版本的选择
// - 常见的 CMake 反模式
// - 现代 CMake 最佳实践总结
// === 常见问题与调试

学习 CMake 的过程中，你一定会遇到各种各样的错误和问题。有些错误信息晦涩难懂，有些问题看似简单却难以定位。本节汇总了使用 CMake 时最常见的问题及其解决方案，介绍调试 CMake 配置的技巧，并总结现代 CMake 的最佳实践。掌握这些内容可以帮助你更快地排查问题，写出更高质量的构建配置。

==== "找不到包"问题

这是最常见的 CMake 错误之一，通常表现为：

```
CMake Error at CMakeLists.txt:10 (find_package):
  Could not find a package configuration file provided by "OpenCV" with any
  of the following names:

    OpenCVConfig.cmake
    opencv-config.cmake

  Add the installation prefix of "OpenCV" to CMAKE_PREFIX_PATH or set
  "OpenCV_DIR" to a directory containing one of the above files.
```

*原因*：CMake 无法在默认搜索路径中找到库的配置文件。

*解决方案*：

1. 确认库已正确安装：
```bash
# 检查 OpenCV 是否安装
pkg-config --modversion opencv4
# 或
dpkg -l | grep opencv
```

2. 设置 `CMAKE_PREFIX_PATH`：
```bash
# 方式一：命令行
cmake -DCMAKE_PREFIX_PATH="/opt/opencv;/opt/eigen" ..

# 方式二：环境变量
export CMAKE_PREFIX_PATH="/opt/opencv:$CMAKE_PREFIX_PATH"
cmake ..
```

3. 设置库特定的 `_DIR` 变量：
```bash
cmake -DOpenCV_DIR=/opt/opencv/lib/cmake/opencv4 ..
```

4. 对于 ROS 2，确保已 source 工作空间：
```bash
source /opt/ros/humble/setup.bash
source ~/ros2_ws/install/setup.bash
cmake ..
```

5. 使用 `--debug-find` 查看详细搜索过程：
```bash
cmake --debug-find ..
```

*常见陷阱*：

- 包名大小写敏感：`find_package(OpenCV)` 不同于 `find_package(opencv)`
- 有些包名与库名不同：Eigen 的包名是 `Eigen3` 而不是 `Eigen`
- 多版本共存时可能找到错误版本：明确指定路径

==== "未定义的引用"问题

链接错误通常表现为：

```
/usr/bin/ld: main.cpp:(.text+0x15): undefined reference to `MyClass::DoSomething()'
collect2: error: ld returned 1 exit status
```

*原因*：链接器找不到某个符号的定义。

*常见原因和解决方案*：

1. 忘记链接库：
```cmake
# 错误：没有链接库
add_executable(app main.cpp)

# 正确：链接库
add_executable(app main.cpp)
target_link_libraries(app PRIVATE mylib)
```

2. 链接顺序问题（静态库）：
```cmake
# 如果 A 依赖 B，B 依赖 C，顺序应该是 A B C
target_link_libraries(app PRIVATE libA libB libC)

# 如果有循环依赖，可能需要重复
target_link_libraries(app PRIVATE libA libB libA)
```

3. 忘记编译某个源文件：
```cmake
# 错误：漏掉了 myclass.cpp
add_library(mylib utils.cpp)

# 正确：包含所有源文件
add_library(mylib utils.cpp myclass.cpp)
```

4. 声明和定义不匹配：
```cpp
// header.h
void DoSomething(int x);

// source.cpp - 参数类型不匹配！
void DoSomething(double x) { ... }
```

5. C 和 C++ 混合编程忘记 `extern "C"`：
```cpp
// 在 C++ 代码中调用 C 函数
extern "C" {
    #include "c_library.h"
}
```

6. 模板实例化问题：
```cmake
# 模板定义应该在头文件中
# 或者显式实例化
```

*调试技巧*：

```bash
# 查看目标文件的符号
nm -C mylib.a | grep DoSomething

# 查看可执行文件需要的符号
nm -u app | grep DoSomething

# 使用 c++filt 解码符号名
echo "_ZN7MyClass11DoSomethingEv" | c++filt
```

==== "头文件找不到"问题

编译错误通常表现为：

```
fatal error: opencv2/core.hpp: No such file or directory
    #include <opencv2/core.hpp>
             ^~~~~~~~~~~~~~~~~~
compilation terminated.
```

*原因*：编译器找不到头文件。

*解决方案*：

1. 检查 `target_include_directories`：
```cmake
target_include_directories(myapp PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${OpenCV_INCLUDE_DIRS}
)
```

2. 使用导入目标自动处理：
```cmake
# 现代方式：自动添加 include 路径
target_link_libraries(myapp PRIVATE OpenCV::OpenCV)
```

3. 检查头文件实际位置：
```bash
# 查找头文件
find /usr -name "core.hpp" 2>/dev/null

# 查看包的 include 路径
pkg-config --cflags opencv4
```

4. 检查 PUBLIC/PRIVATE 是否正确：
```cmake
# 如果 mylib 的头文件被 myapp 包含
# mylib 的 include 路径应该是 PUBLIC
target_include_directories(mylib PUBLIC include)
```

*调试技巧*：

```bash
# 查看实际的编译命令
make VERBOSE=1
# 或
cmake --build . --verbose

# 检查 -I 选项是否包含正确路径
```

==== "ABI 不兼容"问题

运行时错误或奇怪的崩溃，可能表现为：

```
symbol lookup error: ./app: undefined symbol: _ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1Ev

# 或者
Segmentation fault (core dumped)
```

*原因*：不同编译器版本或编译选项编译的代码混合使用。

*常见场景*：

- 用 GCC 7 编译的库与 GCC 11 编译的程序链接
- Debug 模式编译的库与 Release 模式编译的程序链接
- 使用了不同的 C++ 标准库（libstdc++ vs libc++）

*解决方案*：

1. 统一编译器版本：
```bash
# 明确指定编译器
cmake -DCMAKE_CXX_COMPILER=/usr/bin/g++-11 ..
```

2. 重新编译所有依赖：
```bash
# 清理并重新构建
rm -rf build
mkdir build && cd build
cmake ..
cmake --build .
```

3. 检查 C++ ABI 标签：
```bash
# 查看库使用的符号
nm -C libmylib.so | grep "std::__cxx11"
```

4. 统一编译选项：
```cmake
# 确保整个项目使用相同的设置
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
```

==== 查看详细调试信息

CMake 提供了多种方式来获取调试信息：

*cmake --debug-find*：

```bash
# 显示 find_package 的详细搜索过程
cmake --debug-find ..

# 输出类似：
# find_package considered the following locations for OpenCV's Config module:
#   /usr/lib/cmake/opencv4/OpenCVConfig.cmake
#   ...
```

*cmake --trace*：

```bash
# 显示每条 CMake 命令的执行
cmake --trace ..

# 只追踪特定文件
cmake --trace-source=CMakeLists.txt ..
```

*message 打印变量*：

```cmake
# 打印变量值
message(STATUS "OpenCV_VERSION: ${OpenCV_VERSION}")
message(STATUS "OpenCV_INCLUDE_DIRS: ${OpenCV_INCLUDE_DIRS}")
message(STATUS "OpenCV_LIBRARIES: ${OpenCV_LIBRARIES}")

# 打印列表（更清晰）
foreach(lib ${OpenCV_LIBRARIES})
    message(STATUS "  - ${lib}")
endforeach()

# 打印目标属性
get_target_property(inc mylib INCLUDE_DIRECTORIES)
message(STATUS "mylib includes: ${inc}")

# 调试信息（只在特定条件下显示）
if(CMAKE_DEBUG)
    message(STATUS "Debug: ${SOME_VAR}")
endif()
```

*查看编译命令*：

```bash
# Make
make VERBOSE=1

# Ninja
ninja -v

# CMake 通用方式
cmake --build . --verbose

# 生成 compile_commands.json
cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ..
cat compile_commands.json
```

*查看缓存*：

```bash
# 列出所有缓存变量
cmake -LA ..

# 列出所有变量（包括高级）及帮助信息
cmake -LAH ..

# 查看特定变量
grep "OpenCV" CMakeCache.txt
```

==== CMake 最低版本的选择

选择合适的 `cmake_minimum_required` 版本需要权衡：

*版本太低的问题*：

- 无法使用新特性
- 可能触发过时的行为
- 错过 bug 修复

*版本太高的问题*：

- 老系统的用户无法构建
- 限制了项目的兼容性

*推荐的版本选择*：

```cmake
# 2024-2025 年的新项目推荐
cmake_minimum_required(VERSION 3.16)

# 需要更新特性时
cmake_minimum_required(VERSION 3.20)

# ROS 2 Humble 要求
cmake_minimum_required(VERSION 3.16)

# 广泛兼容性
cmake_minimum_required(VERSION 3.10)

# 使用版本范围（推荐）
cmake_minimum_required(VERSION 3.16...3.28)
```

*各版本引入的重要特性*：

- *3.0*：目标 INTERFACE 属性、生成器表达式
- *3.1*：`target_compile_features`
- *3.8*：C++17 支持
- *3.11*：`FetchContent` 模块
- *3.12*：`CONFIGURE_DEPENDS` for GLOB
- *3.14*：`FetchContent_MakeAvailable`
- *3.16*：预编译头文件支持、统一构建
- *3.19*：预设（presets）支持
- *3.20*：C++23 支持
- *3.21*：改进的消息颜色和格式

==== 常见的 CMake 反模式

以下是应该避免的做法：

*反模式 1：使用全局命令*

```cmake
# 不好：影响所有目标
include_directories(${SOME_INCLUDE_DIR})
link_libraries(somelib)
add_definitions(-DSOME_MACRO)

# 好：只影响特定目标
target_include_directories(myapp PRIVATE ${SOME_INCLUDE_DIR})
target_link_libraries(myapp PRIVATE somelib)
target_compile_definitions(myapp PRIVATE SOME_MACRO)
```

*反模式 2：修改 CMAKE_CXX_FLAGS*

```cmake
# 不好：全局修改
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra")

# 好：目标级别设置
target_compile_options(myapp PRIVATE -Wall -Wextra)
```

*反模式 3：使用 file(GLOB) 收集源文件*

```cmake
# 不好：新文件不会自动触发重新配置
file(GLOB SOURCES "src/*.cpp")
add_library(mylib ${SOURCES})

# 好：手动列出源文件
add_library(mylib
    src/file1.cpp
    src/file2.cpp
    src/file3.cpp
)
```

*反模式 4：不使用目标的 PUBLIC/PRIVATE*

```cmake
# 不好：没有指定可见性
target_link_libraries(mylib otherlib)

# 好：明确指定
target_link_libraries(mylib PRIVATE otherlib)
```

*反模式 5：源内构建*

```bash
# 不好：污染源代码目录
cd my_project
cmake .

# 好：源外构建
cd my_project
mkdir build && cd build
cmake ..
```

*反模式 6：硬编码路径*

```cmake
# 不好：不可移植
target_include_directories(myapp PRIVATE /home/user/libs/include)

# 好：使用变量和 find_package
find_package(SomeLib REQUIRED)
target_link_libraries(myapp PRIVATE SomeLib::SomeLib)
```

*反模式 7：不使用导入目标*

```cmake
# 不好：使用变量
target_include_directories(myapp PRIVATE ${OpenCV_INCLUDE_DIRS})
target_link_libraries(myapp PRIVATE ${OpenCV_LIBRARIES})

# 好：使用导入目标
target_link_libraries(myapp PRIVATE OpenCV::OpenCV)
```

*反模式 8：在 find_package 后不检查结果*

```cmake
# 不好：如果找不到会静默失败
find_package(SomeLib)
target_link_libraries(myapp PRIVATE ${SomeLib_LIBRARIES})

# 好：使用 REQUIRED 或检查结果
find_package(SomeLib REQUIRED)
# 或
find_package(SomeLib)
if(NOT SomeLib_FOUND)
    message(FATAL_ERROR "SomeLib not found")
endif()
```

==== 现代 CMake 最佳实践总结

最后，让我们总结现代 CMake 的最佳实践：

*项目设置*：

```cmake
# 要求合理的 CMake 版本
cmake_minimum_required(VERSION 3.16)

# 声明项目信息
project(MyProject
    VERSION 1.0.0
    DESCRIPTION "My awesome project"
    LANGUAGES CXX
)

# 禁止源内构建
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR)
    message(FATAL_ERROR "In-source builds are not allowed")
endif()

# 设置默认构建类型
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()

# 导出编译命令（便于 IDE 和工具使用）
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
```

*目标定义*：

```cmake
# 创建库
add_library(mylib
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
    $<$<CXX_COMPILER_ID:GNU,Clang>:-Wall -Wextra>
    $<$<CXX_COMPILER_ID:MSVC>:/W4>
)
```

*依赖管理*：

```cmake
# 使用 find_package 查找已安装的库
find_package(OpenCV REQUIRED)

# 使用导入目标
target_link_libraries(mylib
    PUBLIC Eigen3::Eigen
    PRIVATE OpenCV::OpenCV
)

# 可选依赖的处理
find_package(CUDA QUIET)
if(CUDA_FOUND)
    target_compile_definitions(mylib PUBLIC HAS_CUDA)
    target_link_libraries(mylib PRIVATE CUDA::cudart)
endif()

# 使用 FetchContent 获取缺失的依赖
include(FetchContent)
FetchContent_Declare(fmt
    GIT_REPOSITORY https://github.com/fmtlib/fmt.git
    GIT_TAG 10.1.1
)
FetchContent_MakeAvailable(fmt)
```

*安装和导出*：

```cmake
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

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
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/MyProject
)

# 生成配置文件
configure_package_config_file(
    cmake/MyProjectConfig.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/MyProjectConfig.cmake
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/MyProject
)

write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/MyProjectConfigVersion.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)

install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/MyProjectConfig.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/MyProjectConfigVersion.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/MyProject
)
```

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

*项目结构建议*：

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

掌握这些最佳实践，你就能写出清晰、可维护、跨平台的 CMake 配置。现代 CMake 的核心理念是"以目标为中心"——一切配置都围绕目标进行，通过 PUBLIC/PRIVATE/INTERFACE 控制属性的传播。这种方式让构建配置更加模块化，依赖管理更加自动化，是当前 C++ 项目构建的最佳实践。
