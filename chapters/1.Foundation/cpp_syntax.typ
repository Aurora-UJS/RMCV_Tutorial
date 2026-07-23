#import "/template/template.typ": *

=== C++ 基本程序结构
// 添加编译相关：g++、CMake 简介
// Hello World、编译流程
这一节先回答两个最基础的问题：一个 C++ 程序由哪些部分组成，写好的源代码又怎样变成可以运行的文件。我们会从最小程序出发，认识 `main`、头文件和标准输出，再用 `g++` 走一遍预处理、编译、汇编与链接流程。CMake 的完整用法会在后面的专章展开，这里先把编译器这条主线理清。

一个小型 C++ 程序可以只有一个 `.cpp` 源文件；项目变大后，通常还会用 `.h` 或 `.hpp` 头文件保存需要在多个源文件间共享的声明。可执行程序以 `main` 函数作为标准规定的入口。进入 `main` 函数体之前，运行时和具有静态存储期的对象可能已经完成了一些初始化，因此不宜把它简单理解为进程中执行的第一条代码。

下面是一个简单的 C++ 程序示例：
```cpp
#include <iostream>                         // 声明标准输入输出对象

int main() {
    std::cout << "Hello, RoboMaster!\n";    // 输出文本并换行
    return 0;                               // 返回状态码
}
```
如果你此前学过 C，会发现两种语言共享不少语法。C++ 最初从 C 的语法和实现经验发展而来，现代 C 与现代 C++ 则由不同标准分别演进：两者有很大的公共子集，却不能把任意 C 程序都当作合法 C++ 程序，也不能把 C++ 简单看成“多了类的 C”。下面这段 C 程序与上面的 `C++` 程序输出相同，输入输出接口却已经不同：

```c
#include <stdio.h>                          // 引入标准输入输出库
int main() {
    printf("Hello, RoboMaster!\n");         // 输出文本
    return 0;                               // 返回状态码
}
```
下面逐项拆开 C++ 版本：
- *`#include <iostream>`：*

C++ 标准库通过一组头文件（header）提供常用类型、函数和对象。`<iostream>` 声明了基于“流”（stream）的输入输出接口：程序把数据按顺序写入输出流，或按顺序从输入流读取数据。


本例需要把文本写到标准输出，因此包含 `<iostream>`，从而获得 `std::cout` 等对象的声明。预处理器处理 `#include` 时，会读取并处理所指定的头文件，使其中的预处理记号参与当前源文件；预处理结果随后成为一个翻译单元，交给编译器继续处理。

- *`using namespace std;`：*
C++ 使用命名空间（namespace）组织名称，减少不同库之间的命名冲突。标准库中的大部分名称，包括 `cout`、`endl` 和 `vector`，都位于 `std` 命名空间中。

`using namespace std;` 会让当前作用域在名称查找时考虑整个 `std` 命名空间，代码因此可以省略 `std::` 前缀。短小示例中偶尔能看到这种写法，但在头文件中尤其容易把大量名称带进包含者的作用域；工程代码通常显式写出 `std::`，或者只引入确实需要的单个名称：
```cpp
#include <iostream>

int main() {
    std::cout << "Hello World\n";
    return 0;
}
```
这样一眼就能看出名称来自标准库，也减少了意外冲突。


- *`int main()`：*
普通的宿主环境 C++ 可执行程序需要定义 `main` 函数。标准形式的返回类型是 `int`，返回值会成为程序的退出状态：`0` 或 `EXIT_SUCCESS` 表示成功，非零状态通常用于向调用者区分错误。裸机固件等独立实现可以采用不同的启动约定，本节讨论的是 Linux 上的普通用户程序。

函数体由一对大括号 `{}` 包围，内部是*语句块*（statement block），包含程序逻辑。

- *注释：`//` 与 `/* ... */`*
注释用于向阅读代码的人说明意图，编译器会忽略注释内容。C++ 支持两种注释形式：
    -- `//` 单行注释：`//` 之后至行尾为注释。
    -- `/* */` 多行注释：可跨行书写。

良好的注释能提高代码可读性，但注释内容应简洁、相关，避免重复说明代码本身能表达的事实。

- *`std::cout << "Hello World\n";`* —— 输出与“流”的概念
这一行展示了 C++ 标准库 I/O 的核心风格：*流*（stream）操作。`std::cout` 是与标准输出关联的流对象，标准输出在终端启动程序时通常连接到终端，也可能被重定向到文件或管道。`<<` 是插入运算符，表示把右侧的值写入左侧的流；多个插入操作可以连接起来：

```cpp
std::cout << "Hello" << ' ' << "World\n";
```

右侧各项按顺序写入同一个流。这个接口还可以通过重载 `operator<<` 支持自定义类型。换行通常写成 `'\n'`；`std::endl` 除了写入换行符，还会立即刷新缓冲区，只有确实需要立刻提交输出时才有必要使用，频繁刷新可能降低输出性能。

- *`return 0;`*

`return 0;` 表示 `main` 正常结束，并向宿主环境返回成功状态。从 `main` 函数末尾自然返回与显式返回 0 等价；初学阶段写出来更容易看清退出状态的含义。

=== 编译一个 C++ 程序
在理解了程序结构之后，下一步需要了解：如何将源代码转换为计算机能够执行的程序。C++ 属于编译型语言，源代码必须经过编译器处理才能运行。本节就用一个文件把工具链的四个阶段串起来；多文件组织与 CMake 会在后面的专章继续展开。
下面假设我们有一个最基本的程序 `main.cpp`：
```cpp
#include <iostream>

int main() {
    std::cout << "Hello, RoboMaster!\n";
    return 0;
}
```

要将这个源文件编译成可执行文件，可以使用 GNU 编译器集合（GCC）中的 `g++` 命令行工具。假设读者已经在系统中安装了 g++，可以通过以下命令进行编译：
```bash
g++ main.cpp -o main
```
这里，`g++` 是 GCC 工具链的 C++ 驱动程序，`main.cpp` 是源文件，`-o main` 把输出文件命名为 `main`。这条命令不仅做语法检查，还会完成后面的汇编与链接；只有所有阶段都成功，才会得到可执行文件。在常见 Windows 工具链中，可执行文件通常带 `.exe` 后缀。
要运行生成的程序，可以在终端中输入：
```bash
./main        # 在类 Unix 系统（Linux、macOS）上
```

至此，我们完成了一次最基础的 C++ 编译。

尽管我们只敲了一条命令，但编译器内部实际经历了四个阶段：

1. *预处理 Preprocessing*
预处理器会处理 `#include`、`#define` 和条件编译等预处理指令。工具链不一定把中间结果永久保存到磁盘；为了观察它，可以让 `g++` 在预处理后停止，并把 C++ 结果写到惯用的 `.ii` 文件中：
```bash
g++ -E main.cpp -o main.ii
```
这时，`main.ii` 中可以看到头文件展开和宏替换后的代码，内容通常会比原文件长很多。

2. *编译 Compilation*
编译器会解析预处理后的 C++，完成语法与语义检查，并按所选优化级别生成汇编代码。可以用以下命令让工具链在这个阶段之后停止：
```bash
g++ -S main.ii -o main.s
```
输出文件 `main.s` 是面向当前目标架构的汇编文本。它展示的是这次编译器版本、选项和目标平台下的结果，并不是一段 C++ 源码唯一对应的固定汇编。
3. *汇编 Assembly*
汇编器将汇编代码转换为机器码，生成目标文件（object file），通常以 `.o` 结尾。目标文件包含了机器指令，但还不能独立运行。
可以用以下命令仅执行汇编阶段：
```bash
g++ -c main.s -o main.o
```
这时，`main.o` 文件中包含了机器码，但还不能执行，因为它可能还依赖其他目标文件或库。
4. *链接 Linking*
链接器将一个或多个目标文件和所需的库文件合并，生成最终的可执行文件。在这个阶段，链接器会解析符号引用，确保所有函数和变量都能正确连接。
可以用以下命令仅执行链接阶段：
```bash
g++ main.o -o main
```
最终生成的 `main` 文件就是可执行程序，可以直接运行。

工具链回答了“源码怎样变成程序”，接下来回到源码内部：一个程序首先要用类型和变量把数据表达清楚。

=== 变量与基本数据类型
// int, float, double, bool, char
// auto 关键字
// 类型转换
//=== 变量与基本数据类型

程序的本质是处理数据。无论是计算电机转速、追踪目标位置，还是判断装甲板颜色，都需要在内存中存储和操作各种数据。C++ 通过变量来管理这些数据，而数据类型则决定了变量能够存储什么样的值、占用多少内存空间，以及可以进行哪些运算。

==== 变量的声明与初始化

变量为程序中的对象提供了一个可引用的名称。声明会告诉编译器这个名称的类型和作用域；对象需要多少存储、是否真的单独占据内存，则还会受存储期、优化和具体类型影响。对初学者来说，可以先把普通局部变量理解为“带类型、带名字的一份数据”。

最基本的变量声明形式是“类型名 变量名”：

```cpp
int score;          // 声明一个整数变量
double temperature; // 声明一个双精度浮点数变量
```

普通局部基本类型只声明而不初始化时，其值不确定；在需要读取之前没有先赋值，可能产生错误，某些读取还会触发未定义行为。最简单的习惯是在声明时给出有意义的初值：

```cpp
int score = 0;
double temperature = 36.5;
```

C++11 扩展了花括号初始化的统一用法。它适用于基本类型和许多类类型，并会拒绝列表初始化中规定的窄化转换：

```cpp
int count{10};
double pi{3.14159};
int dangerous{3.14};  // 错误：列表初始化拒绝这种窄化转换
```

当初始值的类型与变量类型不完全匹配时，花括号初始化会进行更严格的检查，这有助于在编译阶段发现潜在的错误。

==== 整数类型

整数是最常用的数据类型之一。C++ 提供了多种整数类型，它们的区别在于能够表示的数值范围和占用的内存大小。

`int` 是最常用的整数类型。在常见桌面和嵌入式工具链中它通常为 32 位，可表示约 -21 亿到 +21 亿；C++ 标准只保证它至少有 16 位，跨平台协议不能依赖这个常见值。普通循环计数和范围明确的整数运算通常可以从 `int` 开始：

```cpp
int motorSpeed = 3000;      // 电机转速 RPM
int bulletCount = 42;       // 弹丸数量
int targetDistance = 5000;  // 目标距离 mm
```

当数值范围有不同需求时，还可以使用 `short`、`long` 和 `long long`。标准保证它们的最小宽度依次不低于 16、32 和 64 位，但 `long` 在 64 位 Windows 上常为 32 位，在许多 64 位 Linux 系统上则为 64 位。选类型应先看所需范围和接口约定；单个较窄变量也未必能节省对象总大小，因为结构体填充和运算时的整数提升仍会影响结果。

```cpp
short sensorReading = 1024;           // 传感器读数
long long timestamp = 1703491200000;  // 毫秒级时间戳
```

整数类型还分为有符号（signed）和无符号（unsigned）。无符号类型按模 $2^N$ 运算，不能表示负数，因此在相同位数下能覆盖更大的非负范围。标准容器的大小和下标类型通常是无符号的 `std::size_t`，与这些接口交互时会遇到它；但“值不会为负”并不自动意味着所有计算都适合无符号类型，尤其是需要做差或倒序循环时。

```cpp
#include <cstddef>
#include <cstdint>

std::uint32_t frameCount = 0; // 协议规定 32 位回绕计数时可明确使用定宽类型
std::size_t arraySize = 100;  // 与标准容器的大小类型一致
```

例如，`0u - 1` 会按模运算回绕到该无符号类型的最大值，而不是得到 -1。只要中间结果可能为负，通常先选能覆盖范围的有符号类型；若协议明确规定了无符号字段，则应在解析边界处检查范围，再进行需要的转换。

==== 浮点类型

浮点类型用于表示带有小数部分的数值，在机器人控制中随处可见：角度、速度、PID 参数、坐标位置等都需要用浮点数表示。

C++ 提供三种浮点类型：`float`（单精度）、`double`（双精度）和 `long double`（扩展精度）。它们的区别在于精度和范围：

```cpp
float angle = 45.0f;           // 单精度，约 7 位有效数字
double position = 1234.56789;  // 双精度，约 15 位有效数字
```

在采用 IEEE 754 的常见平台上，`float` 通常占 4 字节并提供约 6～9 位十进制有效数字，`double` 通常占 8 字节并提供约 15～17 位；标准允许实现有所不同。`float` 能减少数组和图像数据的带宽，某些 GPU、SIMD 或嵌入式硬件也更擅长处理它；`double` 则能降低许多累计计算中的舍入影响。应根据误差预算、数据规模和目标硬件测量选择，而不是只凭“精度更高”或“占用更小”一条理由。

浮点数字面量默认是 `double` 类型。如果要表示 `float` 类型的字面量，需要在数字后加上 `f` 或 `F` 后缀：

```cpp
float f1 = 3.14;   // 3.14 是 double，隐式转换为 float，可能有精度损失
float f2 = 3.14f;  // 3.14f 是 float，无需转换
```

二进制浮点数无法精确表示所有十进制小数。例如，0.1 的二进制展开无限循环，存储时必须舍入。对经过不同计算路径得到的近似量，直接比较是否完全相等往往不符合问题意图；但计数转换结果、哨兵值或同一对象复制出来的值，也可能有合理的精确比较场景。

```cpp
double a = 0.1 + 0.2;
double b = 0.3;
if (a == b) {  // 危险！可能不相等
    // ...
}
```

比较测量或数值计算结果时，容差应来自量纲和误差要求。常见做法同时考虑绝对误差与相对误差，避免固定的 `1e-9` 在很大或很小的数值尺度上失去意义：

```cpp
#include <algorithm>
#include <cmath>

const double absTol = 1e-12;
const double relTol = 1e-9;
const double scale = std::max(std::abs(a), std::abs(b));
if (std::abs(a - b) <= std::max(absTol, relTol * scale)) {
    // 认为相等
}
```

==== 字符类型

`char` 占用一个 C++ 字节，适合保存窄字符编码单元或原始小整数。单引号包围的普通字符字面量通常产生 `char` 值：

```cpp
char grade = 'A';
char newline = '\n';
char tab = '\t';
```

`char` 属于整数类型，因而可以参与整数提升和算术运算。执行字符到数字的转换时，不必依赖 ASCII 的具体数值；C++ 保证基本执行字符集中的十个数字字符连续排列，所以 `'7' - '0'` 可以得到 7：

```cpp
char c = '3';
c = static_cast<char>(c + 1);  // C++ 保证结果是 '4'

int digit = '7' - '0';  // 将字符 '7' 转换为整数 7
```

反斜杠 `\` 开头的是转义字符，用于表示一些特殊字符：`\n` 表示换行，`\t` 表示制表符，`\\` 表示反斜杠本身，`\'` 表示单引号。

一个 `char` 通常不足以表示完整的中文字符。使用 UTF-8 时，`std::string` 保存的是字节序列，一个用户眼中的字符可能占多个字节，因此 `size()` 和按下标访问都不是“字符数”和“第几个汉字”。C++ 还提供 `char8_t`（C++20）、`char16_t` 与 `char32_t` 等编码单元类型，但标准库并未自动完成所有 Unicode 分词、规范化和显示宽度处理；实际项目常明确采用 UTF-8，并借助专门的 Unicode 库处理字符级操作。

==== 布尔类型

`bool` 类型用于表示逻辑值，只有两个可能的取值：`true`（真）和 `false`（假）。布尔类型在条件判断和逻辑运算中广泛使用：

```cpp
bool isTargetDetected = true;
bool isAutoAimEnabled = false;
bool shouldShoot = isTargetDetected && isAutoAimEnabled;
```

虽然逻辑上只需区分两个值，`bool` 仍是可独立寻址的对象类型；在常见实现中 `sizeof(bool)` 为 1，但具体对象布局和容器中的压缩方式由实现与类型决定。

在 C++ 中，布尔值可以隐式转换为整数（`false` 转为 0，`true` 转为 1），整数也可以隐式转换为布尔值（0 转为 `false`，非零值转为 `true`）。这种转换在条件语句中很常见：

```cpp
int errorCode = someFunction();
if (errorCode) {  // 非零值被视为 true
    std::cout << "发生错误" << std::endl;
}
```

尽管这种隐式转换很方便，但过度依赖它会降低代码的可读性。在表达逻辑意图时，显式使用布尔表达式更为清晰。

==== auto 关键字

C++11 引入的 `auto` 关键字允许编译器根据初始值自动推断变量的类型。这在类型名称冗长或复杂时特别有用：

```cpp
auto count = 10;        // 推断为 int
auto pi = 3.14159;      // 推断为 double
auto message = "Hello"; // 推断为 const char*
```

`auto` 的价值在复杂类型中体现得更为明显。例如，在使用标准库容器时，迭代器的类型往往非常冗长：

```cpp
std::vector<int> numbers = {1, 2, 3, 4, 5};

// 不使用 auto
std::vector<int>::iterator it1 = numbers.begin();

// 使用 auto，简洁得多
auto it2 = numbers.begin();
```

使用 `auto` 时需要注意几点。首先，`auto` 声明的变量必须在声明时初始化，否则编译器无法推断类型。其次，`auto` 推断的类型可能与预期不同，特别是涉及引用和常量时。例如：

```cpp
const int& ref = someValue;
auto a = ref;  // a 的类型是 int，不是 const int&
```

如果需要保留引用或常量属性，应当显式声明：

```cpp
const auto& b = ref;  // b 的类型是 const int&
```

在 RoboMaster 开发中，`auto` 常用于 lambda 表达式、迭代器和复杂模板类型的声明，能够显著提高代码的简洁性。但对于基本类型，显式声明往往更清晰——`int count = 10` 比 `auto count = 10` 更直观地表达了变量的用途。

==== 类型转换

不同类型的数据在运算时可能需要相互转换。C++ 支持隐式转换和显式转换两种方式。

隐式转换由语言规则自动完成，常出现在混合类型运算、赋值和函数调用中。它并不总是简单地“向更宽类型转换”：整数提升、有符号与无符号混合以及浮点转换各有规则，其中一些仍会改变数值。

```cpp
int a = 10;
double b = 3.14;
double c = a + b;  // a 被隐式转换为 double，结果为 13.14
```

然而，隐式转换也可能导致意外的结果。例如，将浮点数赋值给整数变量时，小数部分会被截断：

```cpp
int x = 3.99;  // x 的值是 3，不是 4
```

当需要明确进行类型转换时，应当使用显式转换。C++ 提供了四种转换运算符，其中最常用的是 `static_cast`：

```cpp
double pi = 3.14159;
int truncated = static_cast<int>(pi);  // 显式截断为 3

int dividend = 7;
int divisor = 2;
double result = static_cast<double>(dividend) / divisor;  // 结果为 3.5
```

`static_cast` 用于表达语言允许、且程序员有意进行的转换，例如数值转换和继承层次中的某些转换。它比 C 风格转换更明确，但不保证转换不会窄化、溢出或产生错误语义，范围检查仍由程序负责。其他三种转换运算符——`dynamic_cast`、`const_cast` 和 `reinterpret_cast`——用途和风险不同，将在相关章节结合场景介绍。

C 语言风格的强制转换（如 `(int)3.14`）在 C++ 中仍然有效，但不推荐使用。C++ 的转换运算符更加明确，也更容易在代码中搜索和审查。

==== 类型大小与 sizeof 运算符

不同平台上基本类型的大小可能不同。C++ 标准规定了类型间的最小范围关系，而不是统一要求 `int` 必须为 32 位。使用 `sizeof` 可以查询当前实现中某个类型或对象占用多少个字节；这里的“字节”是 `sizeof(char)` 定义的存储单位，至少包含 8 位：

```cpp
#include <iostream>

int main() {
    std::cout << "char: " << sizeof(char) << " 字节\n";
    std::cout << "short: " << sizeof(short) << " 字节\n";
    std::cout << "int: " << sizeof(int) << " 字节\n";
    std::cout << "long: " << sizeof(long) << " 字节\n";
    std::cout << "long long: " << sizeof(long long) << " 字节\n";
    std::cout << "float: " << sizeof(float) << " 字节\n";
    std::cout << "double: " << sizeof(double) << " 字节\n";
    std::cout << "bool: " << sizeof(bool) << " 字节\n";
    return 0;
}
```

在典型的 64 位 Linux 系统上，输出通常为：

```
char: 1 字节
short: 2 字节
int: 4 字节
long: 8 字节
long long: 8 字节
float: 4 字节
double: 8 字节
bool: 1 字节
```

如果协议或文件格式要求确切位数，可以优先使用 `<cstdint>` 中的定宽类型。只有实现能够提供恰好对应位数、且没有填充位的整数类型时，`std::int8_t` 等名称才会存在；主流 RoboMaster 工具链通常都提供它们：

```cpp
#include <cstdint>

std::int8_t  a;   // 若实现提供，则恰好 8 位
std::int16_t b;
std::int32_t c;
std::int64_t d;

std::uint8_t  e;
std::uint16_t f;
std::uint32_t g;
std::uint64_t h;
```

在 RoboMaster 开发中，与下位机通信时经常需要使用定宽类型来确保数据格式的一致性。例如，串口协议中的帧头、数据长度、校验码等字段通常会明确规定使用多少字节，此时定宽类型就显得尤为重要。

==== 常量与 const 关键字

在程序中，有些对象一旦得到初值就不应再被修改，例如数学常数和运行期间保持不变的配置。C++ 用 `const` 表达这种约束：

```cpp
const double PI = 3.14159265358979;
const int MAX_BULLET_SPEED = 25;  // 单位 m/s
```

`const` 对象需要完成初始化，随后不能再通过这个对象直接修改它。对这里的基本类型来说，初始值就写在声明处；编译器会拒绝后续赋值，从而让“只读”意图成为可检查的约束。

C++11 引入了 `constexpr`，用来表达“可以参与常量表达式求值”。用于变量时，它要求初始化器能在编译期求值，并且变量本身也是 `const`：

```cpp
constexpr double PI = 3.14159265358979;
constexpr int ARRAY_SIZE = 100;

int arr[ARRAY_SIZE];  // 合法，ARRAY_SIZE 在编译期已知
```

两者都能阻止普通赋值，但侧重点不同：`const` 只承诺初始化后不再修改，初值仍可能到运行时才知道；`constexpr` 还承诺这里的值可供编译期计算，因此能用于模板实参、`case` 标签等需要常量表达式的场合。

相比于使用宏定义常量（`#define PI 3.14159`），`const` 和 `constexpr` 具有类型安全性，也遵循作用域规则，是现代 C++ 推荐的做法。


=== 运算符与表达式
// 算术、关系、逻辑运算符
// 运算符优先级
//=== 运算符与表达式

有了变量，还要把它们组合成计算。运算符规定“做什么”，操作数提供参与计算的值，二者组成表达式并产生结果。本节先从熟悉的四则运算讲起，再逐步加入比较、逻辑和位运算；最后集中处理优先级，避免一开始就被一整张规则表淹没。

==== 算术运算符

算术运算符用于执行数学计算，是最直观的一类运算符。C++ 支持加（`+`）、减（`-`）、乘（`*`）、除（`/`）和取模（`%`）五种基本算术运算：

```cpp
int a = 17, b = 5;

int sum = a + b;      // 22
int diff = a - b;     // 12
int prod = a * b;     // 85
int quot = a / b;     // 3（整数除法，截断小数）
int rem = a % b;      // 2（取模，即余数）
```

整数除法是初学者常遇到的陷阱。当两个整数相除时，结果仍然是整数，小数部分被直接截断而非四舍五入。如果需要保留小数，至少要将其中一个操作数转换为浮点类型：

```cpp
int dividend = 7;
int divisor = 2;

int result1 = dividend / divisor;                      // 结果为 3
double result2 = dividend / divisor;                   // 结果仍为 3.0，因为除法在赋值前已完成
double result3 = static_cast<double>(dividend) / divisor;  // 结果为 3.5
double result4 = dividend / 2.0;                       // 结果为 3.5，2.0 是 double
```

余数运算符 `%` 只能用于整数类型。它常用于判断奇偶性、实现循环计数，或让非负计数在固定区间内回绕：

```cpp
bool isEven = (number % 2 == 0);           // 判断偶数
int arrayIndex = counter % arraySize;      // 循环索引
int angleInRange = angle % 360;            // angle 非负时，结果位于 0 到 359
```

若左操作数为负，余数也可能为负，因此 `angle % 360` 并不能把任意角度都归一化到 `[0, 360)`。需要覆盖负角度时，可以写成 `(angle % 360 + 360) % 360`；若除数为 0，除法和余数运算都没有定义。

C++ 还提供了自增（`++`）和自减（`--`）运算符，用于将变量的值加 1 或减 1。这两个运算符有前置和后置两种形式，区别在于返回值的时机：

```cpp
int x = 5;
int y = ++x;  // 前置：先加 1，再取值。x = 6, y = 6
int z = x++;  // 后置：先取值，再加 1。x = 7, z = 6
```

前置形式产生修改后的值，后置形式产生修改前的值。对内置整数来说，返回值未被使用时，优化后的 `++i` 与 `i++` 通常没有差别；对某些自定义迭代器，后置形式可能需要保留旧对象。没有理由使用旧值时写 `++i`，既直接表达意图，也适用于两类对象。

==== 关系运算符

关系运算符用于比较两个值的大小关系，返回布尔值 `true` 或 `false`。C++ 提供六种关系运算符：

```cpp
int a = 10, b = 20;

bool eq = (a == b);   // 等于，false
bool ne = (a != b);   // 不等于，true
bool lt = (a < b);    // 小于，true
bool le = (a <= b);   // 小于等于，true
bool gt = (a > b);    // 大于，false
bool ge = (a >= b);   // 大于等于，false
```

初学时很容易把相等判断 `==` 误写成赋值 `=`。赋值表达式本身也有值，所以这种代码有时仍能通过编译，却会做完全不同的事：

```cpp
int status = 0;

if (status = 1) {     // 错误！这是赋值，status 变为 1，条件恒为 true
    // 总是执行
}

if (status == 1) {    // 正确，判断 status 是否等于 1
    // 当 status 为 1 时执行
}
```

有些代码把常量放在左侧（`1 == status`），借此让误写的赋值无法编译；这种“尤达条件”并不是必须采用的风格。更重要的是启用编译器警告并认真处理它们，例如 GCC 和 Clang 的 `-Wall -Wextra` 通常会指出可疑的条件赋值。确实需要在条件中赋值时，再用括号把意图写明。

前面已经区分过“精确值”和“近似量”。这里的角度来自计算，且量级范围明确，因此可以用符合控制精度要求的绝对容差判断它是否到位：

```cpp
double targetAngle = 45.0;
double currentAngle = computeAngle();  // 可能有浮点误差
double tolerance = 0.001;

if (std::abs(currentAngle - targetAngle) < tolerance) {
    // 认为角度已到达目标
}
```

==== 逻辑运算符

逻辑运算符用于组合多个布尔表达式，构建复杂的条件判断。C++ 提供三种逻辑运算符：逻辑与（`&&`）、逻辑或（`||`）和逻辑非（`!`）。

逻辑与要求两个条件都为真，结果才为真：

```cpp
bool canShoot = isTargetLocked && hasBullets && !isOverheated;
```

逻辑或只要有一个条件为真，结果就为真：

```cpp
bool needWarning = isBatteryLow || isTemperatureHigh || hasError;
```

逻辑非将布尔值取反：

```cpp
bool isInvalid = !isValid;
```

逻辑运算符具有短路求值（short-circuit evaluation）的特性。对于 `&&`，左侧为假时不会计算右侧；对于 `||`，左侧为真时也不会计算右侧。判断顺序因此不仅影响效率，有时还是安全访问的前提：

```cpp
// 安全的指针检查：先判断指针非空，再访问其成员
if (ptr != nullptr && ptr->isValid()) {
    // 如果 ptr 为空，ptr->isValid() 不会被调用，避免空指针解引用
}

```

在复杂的条件表达式中，适当使用括号可以提高可读性，即使在运算符优先级正确的情况下：

```cpp
// 不够清晰
if (a > 0 && b > 0 || c > 0 && d > 0) { }

// 更清晰
if ((a > 0 && b > 0) || (c > 0 && d > 0)) { }
```

==== 赋值运算符

最基本的赋值运算符是 `=`，它将右侧的值赋给左侧的变量。C++ 还提供了一系列复合赋值运算符，将算术运算和赋值合并为一步：

```cpp
int x = 10;

x += 5;   // 等价于 x = x + 5，x 变为 15
x -= 3;   // 等价于 x = x - 3，x 变为 12
x *= 2;   // 等价于 x = x * 2，x 变为 24
x /= 4;   // 等价于 x = x / 4，x 变为 6
x %= 4;   // 等价于 x = x % 4，x 变为 2
```

复合赋值运算符不仅使代码更简洁，在某些情况下还能避免重复计算左侧表达式。例如，`array[computeIndex()] += 1` 只调用一次 `computeIndex()`，而 `array[computeIndex()] = array[computeIndex()] + 1` 会调用两次。

赋值表达式本身也有值，其值为赋值后左侧变量的值。这使得链式赋值成为可能：

```cpp
int a, b, c;
a = b = c = 0;  // 从右向左执行，三个变量都被赋值为 0
```

然而，滥用赋值表达式的值会降低代码可读性，应当谨慎使用。

==== 位运算符

位运算符直接操作整数的二进制表示，常见于状态标志、寄存器和通信字段。C++ 提供按位与、或、异或、取反以及左右移位：

```cpp
int a = 0b1100;  // 二进制 1100，即十进制 12
int b = 0b1010;  // 二进制 1010，即十进制 10

int andResult = a & b;   // 按位与：0b1000，即 8
int orResult = a | b;    // 按位或：0b1110，即 14
int xorResult = a ^ b;   // 按位异或：0b0110，即 6
int notResult = ~a;      // 按位取反：所有位翻转

int leftShift = a << 2;  // 左移 2 位：0b110000，即 48
int rightShift = a >> 2; // 右移 2 位：0b0011，即 3
```

在 RoboMaster 开发中，位运算常用于以下场景。

状态标志的管理是位运算的典型应用。使用单个整数的不同位表示不同的状态，可以高效地存储和检查多个布尔标志：

```cpp
#include <cstdint>

constexpr std::uint8_t FLAG_MOTOR_READY = 0b00000001;  // 第 0 位
constexpr std::uint8_t FLAG_SENSOR_OK   = 0b00000010;  // 第 1 位
constexpr std::uint8_t FLAG_COMM_ACTIVE = 0b00000100;  // 第 2 位
constexpr std::uint8_t FLAG_AUTO_AIM    = 0b00001000;  // 第 3 位

std::uint8_t robotStatus = 0;

// 设置标志
robotStatus |= FLAG_MOTOR_READY;   // 将第 0 位置 1
robotStatus |= FLAG_SENSOR_OK;     // 将第 1 位置 1

// 清除标志
robotStatus &= ~FLAG_AUTO_AIM;     // 将第 3 位置 0

// 检查标志
if (robotStatus & FLAG_MOTOR_READY) {
    // 电机已就绪
}

// 切换标志
robotStatus ^= FLAG_COMM_ACTIVE;   // 翻转第 2 位
```

位移运算在处理通信协议时也很常见。例如，将多个字节组合成一个整数，或者从整数中提取特定字节：

```cpp
// 将两个字节组合成 16 位整数（大端序）
std::uint8_t highByte = 0x12;
std::uint8_t lowByte = 0x34;
std::uint16_t combined =
    (static_cast<std::uint16_t>(highByte) << 8) | lowByte;  // 0x1234

// 从 32 位整数中提取各字节
std::uint32_t value = 0x12345678;
std::uint8_t byte0 = value & 0xFFu;          // 0x78
std::uint8_t byte1 = (value >> 8) & 0xFFu;   // 0x56
std::uint8_t byte2 = (value >> 16) & 0xFFu;  // 0x34
std::uint8_t byte3 = (value >> 24) & 0xFFu;  // 0x12
```

对无符号整数，在结果仍可表示时左移一位与乘以 2 的数值效果相同，右移一位则相当于向下除以 2；移位位数越界以及有符号数移位还涉及额外规则。位移最适合表达“处理比特”的意图，不必为了猜测性能而用它替代普通乘除，编译器通常能完成这种优化。

==== 条件运算符

条件运算符（`?:`）是 C++ 中唯一的三元运算符，它根据条件选择两个值中的一个：

```cpp
int max = (a > b) ? a : b;  // 如果 a > b，取 a；否则取 b
```

条件运算符适合“根据条件选择一个值”的场景，往往比先声明、再分别赋值更紧凑：

```cpp
// 使用 if-else
std::string status;
if (isOnline) {
    status = "在线";
} else {
    status = "离线";
}

// 使用条件运算符
std::string status = isOnline ? "在线" : "离线";
```

条件运算符也可以嵌套，但过度嵌套会严重损害可读性：

```cpp
// 能读懂，但加上括号能让分组更直观
int sign = (x > 0) ? 1 : (x < 0) ? -1 : 0;

// 嵌套过深，难以理解
int result = a ? b ? c : d : e ? f : g;  // 不要这样写
```

当逻辑变得复杂时，应当使用普通的 if-else 语句。条件运算符最适合用于简单的二选一场景。

==== 运算符优先级

当一个表达式包含多个运算符时，运算符优先级决定了计算的顺序。C++ 定义了详细的优先级规则，以下是常用运算符按优先级从高到低的大致排列：

1. 后缀运算符：`()` `[]` `->` `.` `++`(后置) `--`(后置)
2. 一元运算符：`++`(前置) `--`(前置) `!` `~` `+`(正号) `-`(负号) `*`(解引用) `&`(取地址)
3. 乘除模：`*` `/` `%`
4. 加减：`+` `-`
5. 位移：`<<` `>>`
6. 关系：`<` `<=` `>` `>=`
7. 相等：`==` `!=`
8. 按位与：`&`
9. 按位异或：`^`
10. 按位或：`|`
11. 逻辑与：`&&`
12. 逻辑或：`||`
13. 条件：`?:`
14. 赋值：`=` `+=` `-=` 等
15. 逗号：`,`

无需死记整张优先级表，但应熟悉算术、比较、逻辑和赋值这几组常用关系。遇到位运算与比较混合、或读者需要停下来推算的表达式，就用括号直接写出分组；括号不能替代对求值顺序和副作用的理解，却能让这里的结合方式一目了然：

```cpp
// 不确定优先级，读者需要自行推算
int implicitGrouping = a + b * c >> d & e;

// 同一计算显式写出分组
int explicitGrouping = ((a + (b * c)) >> d) & e;
```

特别需要注意的是，位运算符的优先级低于关系运算符，这常常导致意外：

```cpp
// 错误：实际执行的是 flags & (FLAG_A == FLAG_A)，结果恒为 flags & 1
if (flags & FLAG_A == FLAG_A) { }

// 正确
if ((flags & FLAG_A) == FLAG_A) { }
```

==== 表达式与语句

表达式可以被求值，并可能产生结果或副作用；语句则构成程序执行的基本单位。表达式语句以分号结尾，声明、复合语句和控制语句也属于语句，但并非每一种语句都以分号结束：

```cpp
a + b           // 表达式，值为 a 和 b 的和
x = a + b       // 也是表达式，值为赋值后 x 的值
x = a + b;      // 语句，执行赋值操作

int y = 10;     // 声明语句
if (x > 0) {}   // 控制语句
```

任何表达式加上分号都成为表达式语句。有些表达式语句是有意义的（如赋值、函数调用），有些则毫无作用：

```cpp
x = 5;          // 有意义，修改了 x 的值
calculate();    // 有意义，调用了函数
a + b;          // 无意义，计算结果被丢弃（编译器可能警告）
```

在 C++ 中，某些看似语句的结构实际上是表达式。例如，赋值操作返回被赋的值，这使得 `a = b = c = 0` 这样的链式赋值成为可能。再如，逗号运算符连接多个表达式，从左到右依次求值，整个表达式的值为最右侧表达式的值：

```cpp
int x = (a = 1, b = 2, a + b);  // x = 3
```

逗号运算符在 for 循环中偶尔有用（如同时更新多个变量），但在其他地方使用会降低代码可读性，应当避免。

到这里，单个表达式已经能完成计算和判断。下一步是让判断真正改变执行路径：哪些语句执行一次，哪些跳过，哪些重复。控制语句正好接过这个任务。


=== 控制语句
// if/else, switch
// for, while, do-while
// break, continue
//=== 控制语句

程序默认按语句顺序向前执行，但真实任务很少只有一条直线：温度过高时要停机，通信失败时要重试，一组目标还要逐个处理。条件语句负责选择分支，循环语句负责重复工作，`break`、`continue` 和 `return` 则让程序在合适的位置提前改变路径。

==== if 语句

`if` 语句是最基本的条件语句，它根据条件表达式的真假决定是否执行某段代码：

```cpp
if (temperature > 60.0) {
    std::cout << "警告：电机温度过高！" << std::endl;
    disableMotor();
}
```

当条件为真时，花括号内的代码块被执行；当条件为假时，代码块被跳过。花括号定义了 `if` 语句的作用范围，即使只有一条语句，也建议使用花括号，这样可以避免后续添加代码时遗漏花括号导致的逻辑错误：

```cpp
// 危险的写法
if (error)
    logError();
    shutdown();  // 这行总是执行，不属于 if 语句！

// 安全的写法
if (error) {
    logError();
    shutdown();  // 现在正确地属于 if 语句
}
```

当需要在条件为假时执行另一段代码，可以使用 `else` 子句：

```cpp
if (batteryLevel > 20) {
    status = "正常";
} else {
    status = "电量不足";
    enablePowerSaving();
}
```

多个条件可以用 `else if` 串联起来，形成多路分支：

```cpp
if (distance < 1000) {
    range = "近距离";
    adjustStrategy(CLOSE_RANGE);
} else if (distance < 3000) {
    range = "中距离";
    adjustStrategy(MID_RANGE);
} else if (distance < 5000) {
    range = "远距离";
    adjustStrategy(LONG_RANGE);
} else {
    range = "超出范围";
    adjustStrategy(OUT_OF_RANGE);
}
```

`else if` 链按顺序检查条件，一旦命中一个分支，后续分支便不再检查。因此，排列顺序首先要符合业务语义。上例必须先判断较小的距离阈值；若先写 `distance < 5000`，近距离目标也会提前落入“远距离”分支。

`if` 可以嵌套，但层层缩进会逐渐遮住主线。当正常流程已经难以一眼找到时，可以把失败条件提前返回，或把独立步骤提取成函数：

```cpp
// 嵌套过深，难以阅读
if (conditionA) {
    if (conditionB) {
        if (conditionC) {
            doSomething();
        }
    }
}

// 使用提前返回，更清晰
if (!conditionA) return;
if (!conditionB) return;
if (!conditionC) return;
doSomething();
```

C++17 引入了带初始化的 `if` 语句，允许在条件判断前声明变量，该变量的作用域限于 `if` 语句内部：

```cpp
if (auto result = computeSomething(); result > threshold) {
    process(result);
} else {
    handleFailure(result);
}
// result 在这里不可见
```

这种写法在需要检查函数返回值时特别有用，它将变量声明和条件检查合并，同时限制了变量的作用域。

==== switch 语句

当需要根据一个变量的不同取值执行不同的代码时，`switch` 语句比一连串的 `if-else if` 更加清晰：

```cpp
enum class RobotState { Idle, Patrol, Attack, Retreat };

RobotState state = getCurrentState();

switch (state) {
    case RobotState::Idle:
        standby();
        break;
    case RobotState::Patrol:
        moveAlongPath();
        scanForTargets();
        break;
    case RobotState::Attack:
        aimAtTarget();
        fire();
        break;
    case RobotState::Retreat:
        moveToSafeZone();
        break;
    default:
        handleUnknownState();
        break;
}
```

`switch` 语句的工作方式是：计算括号内表达式的值，然后跳转到匹配的 `case` 标签处开始执行。每个 `case` 后的 `break` 语句用于跳出 `switch` 结构；如果省略 `break`，程序会继续执行下一个 `case` 的代码，这称为“贯穿”（fall-through）。

贯穿行为有时是有意为之的，例如多个 `case` 共享同一段代码：

```cpp
char grade = getGrade();

switch (grade) {
    case 'A':
    case 'B':
    case 'C':
        std::cout << "通过" << std::endl;
        break;
    case 'D':
    case 'F':
        std::cout << "未通过" << std::endl;
        break;
    default:
        std::cout << "无效成绩" << std::endl;
        break;
}
```

然而，无意的贯穿是常见的 bug 来源。C++17 引入了 `[[fallthrough]]` 属性，用于明确表示贯穿是有意的，同时让编译器在其他地方对遗漏的 `break` 发出警告：

```cpp
switch (command) {
    case CMD_INIT:
        initialize();
        [[fallthrough]];  // 明确表示继续执行下一个 case
    case CMD_START:
        start();
        break;
    // ...
}
```

`switch` 的条件最终需要是整数或枚举类型，不能直接使用浮点数或 `std::string`；每个 `case` 标签还必须是互不重复的常量表达式。`default` 用于处理未匹配值，但是否添加要看意图：解析外部整数时通常应兜底；穷举枚举时有意省略它，编译器反而可能在新增枚举项却未补分支时给出警告。

在 `case` 内部声明变量需要特别注意。由于 `switch` 的跳转特性，直接在 `case` 中声明变量可能导致跳过初始化，编译器会报错。解决方法是用花括号创建局部作用域：

```cpp
switch (type) {
    case TYPE_A: {
        int localVar = 10;  // 在局部作用域内声明
        process(localVar);
        break;
    }
    case TYPE_B: {
        std::string msg = "hello";
        display(msg);
        break;
    }
}
```

==== while 循环

`while` 循环在条件为真时重复执行代码块。它首先检查条件，如果为真则执行循环体，然后再次检查条件，如此反复直到条件为假：

```cpp
int attempts = 0;
const int maxAttempts = 5;
bool connected = connectionEstablished();

while (attempts < maxAttempts && !connected) {
    std::cout << "尝试连接... (" << attempts + 1 << "/" << maxAttempts << ")" << std::endl;
    tryConnect();
    ++attempts;
    connected = connectionEstablished();
    if (!connected && attempts < maxAttempts) {
        waitBeforeRetry();
    }
}

if (connected) {
    std::cout << "连接成功" << std::endl;
} else {
    std::cout << "连接失败" << std::endl;
}
```

`while` 适合事先不知道要循环多少次、但继续条件很清楚的场景，例如读取流数据或实现重试。上例中的 `waitBeforeRetry()` 是项目层面的等待函数；实际控制循环应使用合适的时钟与调度接口，不能靠忙等占满 CPU。

编写 `while` 循环时必须确保循环条件最终会变为假，否则会产生无限循环。无限循环有时是有意为之的（如主事件循环），但意外的无限循环会导致程序挂起：

```cpp
// 意外的无限循环：忘记更新 i
int i = 0;
while (i < 10) {
    process(i);
    // 忘记 i++，循环永不结束
}

// 有意的无限循环：主控制循环
while (true) {
    readSensors();
    updateState();
    sendCommands();
    
    if (shutdownRequested()) {
        break;  // 使用 break 退出
    }
}
```

==== do-while 循环

`do-while` 循环与 `while` 循环类似，但它先执行循环体，再检查条件。这保证了循环体至少执行一次：

```cpp
int input = 0;
do {
    std::cout << "请输入一个正整数：";
    std::cin >> input;
    
    if (input <= 0) {
        std::cout << "输入无效，请重试。" << std::endl;
    }
} while (input <= 0);

std::cout << "你输入的是：" << input << std::endl;
```

`do-while` 适合“先做一次，再决定是否继续”的流程，如上面的数值范围检查和菜单交互。这个简例假设 `std::cin` 成功读到了整数；若要处理字母、文件结束等输入失败，还需要检查流状态。由于循环体至少执行一次，使用前应确认这正是所需语义。

注意 `do-while` 语句以分号结尾，这与其他循环不同，容易遗漏。

==== for 循环

`for` 循环是最常用的循环结构，它将初始化、条件检查和迭代更新集中在一行，特别适合已知循环次数的场景：

```cpp
// 遍历数组
int scores[] = {85, 92, 78, 96, 88};
int sum = 0;

for (int i = 0; i < 5; i++) {
    sum += scores[i];
}

double average = static_cast<double>(sum) / 5;
```

`for` 语句的三个部分——初始化、条件、迭代——都是可选的。省略条件表达式等同于条件恒为真，这是创建无限循环的常见方式：

```cpp
for (;;) {
    // 无限循环
    if (shouldExit()) break;
}
```

`for` 循环的初始化部分可以声明多个同类型的变量，迭代部分也可以包含多个表达式，用逗号分隔：

```cpp
// 双指针技术：从两端向中间遍历
if (size > 0) {
    for (int left = 0, right = size - 1; left < right; ++left, --right) {
        if (array[left] > array[right]) {
            std::swap(array[left], array[right]);
        }
    }
}
```

C++11 引入了范围 `for` 循环（range-based for loop），它提供了一种更简洁的方式遍历容器或数组中的元素：

```cpp
std::vector<int> numbers = {1, 2, 3, 4, 5};

// 传统 for 循环
for (std::size_t i = 0; i < numbers.size(); ++i) {
    std::cout << numbers[i] << " ";
}

// 范围 for 循环
for (int num : numbers) {
    std::cout << num << " ";
}
```

范围 `for` 循环自动处理迭代细节，代码更加简洁，也不容易出现索引越界等错误。如果需要修改元素，应当使用引用；如果元素较大且不需要修改，应当使用常量引用以避免复制开销：

```cpp
std::vector<std::string> names = {"Alice", "Bob", "Charlie"};

// 修改元素：使用引用
for (std::string& name : names) {
    name = "Mr./Ms. " + name;
}

// 只读访问：使用常量引用，避免复制
for (const std::string& name : names) {
    std::cout << name << std::endl;
}

// 使用 auto 简化类型声明
for (const auto& name : names) {
    std::cout << name << std::endl;
}
```

在 RoboMaster 开发中，范围 `for` 循环常用于遍历检测到的目标列表、处理传感器数据数组等场景。

==== break 与 continue

`break` 语句用于立即退出最内层的循环或 `switch` 语句。当在循环中遇到某个条件需要提前结束时，`break` 非常有用：

```cpp
// 在数组中查找目标值
int target = 42;
int foundIndex = -1;

for (int i = 0; i < arraySize; i++) {
    if (array[i] == target) {
        foundIndex = i;
        break;  // 找到后立即退出，无需继续搜索
    }
}
```

`continue` 语句用于跳过当前迭代的剩余部分，直接进入下一次迭代。它适合用于在满足某些条件时跳过处理：

```cpp
// 处理有效数据，跳过无效数据
for (const auto& reading : sensorReadings) {
    if (!reading.isValid()) {
        continue;  // 跳过无效读数
    }
    
    processReading(reading);
    updateStatistics(reading);
}
```

`break` 和 `continue` 只影响最内层循环。在嵌套循环中，如果找到结果后要结束整个搜索，可以让外层条件读取一个标志；当搜索本身是一项独立任务时，封装成函数并直接返回通常更自然：

```cpp
// 使用标志变量
bool found = false;
for (int i = 0; i < rows && !found; i++) {
    for (int j = 0; j < cols; j++) {
        if (matrix[i][j] == target) {
            found = true;
            break;  // 只跳出内层循环
        }
    }
}

// 搜索是一项独立任务时，封装成函数
std::pair<int, int> findInMatrix(int target) {
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            if (matrix[i][j] == target) {
                return {i, j};  // 直接返回，退出所有循环
            }
        }
    }
    return {-1, -1};  // 未找到
}
```

==== 循环的选择

三种循环通常可以相互改写，区别主要在于哪一种最直接地呈现循环意图：

`for` 循环适合循环次数已知或有明确迭代模式的场景。它将循环的三个要素集中在一处，便于理解循环的行为。遍历数组、计数循环、有规律的迭代都适合用 `for`。

`while` 循环适合循环次数未知、依赖于运行时条件的场景。等待事件、处理流数据、重试机制等都适合用 `while`。

`do-while` 循环适合需要先执行再判断的场景，如用户输入验证。由于循环体必定执行一次，使用场景相对较少。

```cpp
// 计数循环：for 最清晰
for (int i = 0; i < 10; i++) { }

// 等待条件：while 最清晰
while (!isReady()) {
    wait();
}

// 输入验证：do-while 最清晰
do {
    input = getInput();
} while (!isValid(input));
```

==== 控制语句的嵌套与组合

实际程序中，控制语句往往需要组合使用。条件语句可以嵌套在循环中，循环也可以嵌套在条件语句中。合理的嵌套能够表达复杂的逻辑，但过度嵌套会使代码难以理解和维护。

```cpp
// RoboMaster 自动瞄准逻辑示例
void autoAimLoop() {
    while (isAutoAimEnabled()) {
        auto targets = detectTargets();
        
        if (targets.empty()) {
            waitForNextFrame();
            continue;  // 无目标，进入下一帧
        }
        
        // 选择最优目标
        const Target* bestTarget = nullptr;
        double bestScore = 0.0;
        
        for (const auto& target : targets) {
            if (!target.isValid()) {
                continue;
            }
            
            double score = evaluateTarget(target);
            if (bestTarget == nullptr || score > bestScore) {
                bestScore = score;
                bestTarget = &target;
            }
        }
        
        if (bestTarget != nullptr) {
            aimAt(*bestTarget);
            
            if (isAimStable() && canFire()) {
                fire();
            }
        }
        
        waitForNextFrame();
    }
}
```

这里没有一条适用于所有代码的“最多嵌套几层”硬规则。更实用的判断是：读者能否顺着缩进找到主流程。命名复杂条件、用提前返回或 `continue` 处理例外情况，并把可独立描述的步骤提取为函数，往往都能让主线重新显现。

变量保存状态，表达式完成计算，控制语句组织执行路径；这些已经足以把逻辑写出来。接下来的问题是怎样把逻辑分成读得懂、能复用的单元，而不是让 `main` 一直向下增长。函数就是第一层代码组织工具。

=== 函数基础
// ⚠️ 提前到这里！
// 函数定义、参数、返回值
// 函数重载
// 内联函数
//=== 函数基础

函数把一段任务命名，并明确它需要什么输入、会给出什么结果。这样，调用处可以先关注“计算距离”或“发送指令”这件事，而不必每次展开所有细节；重复逻辑也有了统一的修改位置。本节先学会定义、声明和传参，再讨论重载、递归与 `constexpr`，最后回到一个更重要的问题：怎样划分函数才真正有助于阅读。

==== 函数的定义与调用

一个完整的函数定义包含返回类型、函数名、参数列表和函数体四个部分：

```cpp
// 返回类型  函数名   参数列表
   double   average(int a, int b) {
       // 函数体
       return (static_cast<double>(a) + b) / 2.0;
   }
```

返回类型指定函数返回值的类型。如果函数不返回任何值，使用 `void` 作为返回类型。函数名应当清晰地描述函数的功能，通常使用动词或动词短语。参数列表定义了函数接受的输入，多个参数用逗号分隔；如果函数不需要参数，参数列表为空。函数体是实际执行的代码，用花括号包围。

定义好函数后，通过函数名加括号的方式调用它：

```cpp
int x = 10, y = 20;
double avg = average(x, y);  // 调用函数，传入参数 x 和 y
std::cout << "平均值：" << avg << std::endl;
```

调用时提供的表达式称为实参（argument），函数声明中接收它的位置称为形参（parameter）。两者怎样关联取决于形参类型：按值参数会得到自己的对象，引用参数则会绑定到已有对象。下一小节会把这一区别具体展开。

`return` 语句用于从函数返回一个值并结束函数执行。对于返回 `void` 的函数，可以使用不带值的 `return;` 提前退出，也可以让函数自然执行到末尾结束：

```cpp
void printPositive(int value) {
    if (value <= 0) {
        return;  // 提前退出，不打印非正数
    }
    std::cout << value << std::endl;
}
```

==== 函数声明与定义分离

编译器处理到调用点时，需要已经见过相应的函数声明。声明给出接口（返回类型、名称和参数类型），定义则补上函数体。同一声明可以重复出现；普通的非 `inline` 函数在整个程序中应只有一个定义，后面介绍的 `inline` 和模板会涉及更细的跨文件规则。

```cpp
// 函数声明（也称为函数原型）
double calculateDistance(double x1, double y1, double x2, double y2);

int main() {
    // 可以调用，因为前面已经声明
    double dist = calculateDistance(0, 0, 3, 4);
    std::cout << "距离：" << dist << std::endl;
    return 0;
}

// 函数定义
double calculateDistance(double x1, double y1, double x2, double y2) {
    double dx = x2 - x1;
    double dy = y2 - y1;
    return std::sqrt(dx * dx + dy * dy);
}
```

将声明放在文件开头或头文件中，定义放在源文件中，是 C++ 项目组织代码的常见方式。这种分离使得多个源文件可以共享同一个函数，也使得编译器能够独立编译各个源文件。

声明中的参数名是可选的，只需要类型信息即可。但为了可读性，通常会保留有意义的参数名：

```cpp
// 合法但可读性差
double calculateDistance(double, double, double, double);

// 更好的写法
double calculateDistance(double x1, double y1, double x2, double y2);
```

==== 参数传递

C++ 中参数传递有三种主要方式：值传递、引用传递和指针传递。理解它们的区别对于写出正确且高效的代码至关重要。

值传递是默认方式。调用函数时，实参的值被复制给形参，函数内部对形参的修改不会影响实参：

```cpp
void increment(int n) {
    n++;  // 只修改了副本
    std::cout << "函数内：" << n << std::endl;
}

int main() {
    int value = 10;
    increment(value);
    std::cout << "函数外：" << value << std::endl;  // 仍然是 10
    return 0;
}
```

按值传递很适合 `int` 这类小对象：函数修改的是自己的参数，不会直接改掉调用者的那个整数。对大型对象，构造这份参数可能带来不必要的复制；而带有指针或共享状态的类即使按值传递，其副本仍可能间接访问同一资源，所以“按值”也不等于隔离一切副作用。

引用传递通过在参数类型后加 `&` 实现。此时形参是实参的别名，函数内部对形参的修改会直接反映到实参上：

```cpp
void increment(int& n) {
    n++;  // 直接修改原变量
}

int main() {
    int value = 10;
    increment(value);
    std::cout << value << std::endl;  // 输出 11
    return 0;
}
```

引用传递有两个主要用途。一是允许函数修改调用者的变量，如上例所示。二是避免复制大型对象的开销——即使不需要修改，也可以使用常量引用传递：

```cpp
// 按值：调用者传入左值时会复制 vector
void processData(std::vector<double> data);

// 常量引用：不复制 vector，也不能通过 data 修改其元素
void processData(const std::vector<double>& data);
```

只读访问较大的对象时，常量引用是常见选择；若函数本来就要取得并保存一份对象，按值接收再移动也可能更合适。对 `int`、`double` 这类小型标量，直接按值传递通常最清楚。选择方式既要看大小，也要看函数是否修改、保存或接管参数。

指针传递将在后续章节详细介绍。简单来说，它通过传递变量的地址来实现类似引用的效果，但语法更显式，且允许传递空指针表示“无值”。

==== 返回值

函数可以通过 `return` 语句返回一个值给调用者。返回值的类型必须与函数声明的返回类型兼容：

```cpp
int findMax(int a, int b, int c) {
    int max = a;
    if (b > max) max = b;
    if (c > max) max = c;
    return max;
}
```

返回类型可以是基本类型、类对象、引用或指针。按值返回局部对象是正常用法：返回结果拥有独立的生命周期，编译器还可能通过返回值优化直接构造它。相反，指向普通局部变量的引用或指针会在函数结束后失效：

```cpp
// 安全：按值返回结果
int getValue() {
    int local = 42;
    return local;  // 返回 local 的副本
}

// 危险：返回局部变量的引用
int& getReference() {
    int local = 42;
    return local;  // 错误！local 在函数返回后销毁
}
```

C++11 的花括号初始化让返回 `std::pair` 或自定义结构体更简洁；C++17 的结构化绑定则能在调用处接收其中的多个成员：

```cpp
std::pair<double, double> getPosition() {
    return {3.14, 2.71};
}

auto [x, y] = getPosition();  // C++17 结构化绑定
```

对于需要返回多个值的场景，除了返回 `std::pair` 或 `std::tuple`，也可以使用输出参数（通过引用或指针传递）：

```cpp
// 方式一：返回结构体或 pair
struct Result {
    bool success;
    double value;
};

Result compute(double input);

// 方式二：输出参数
bool compute(double input, double& output);
```

返回结构体通常能把字段含义和成功状态放在一起，调用处也容易看出数据从哪里来。输出参数仍常见于既有接口、需要复用缓冲区或一次写入多个对象的场景，但它会把结果藏进参数列表。没有这些约束时，先考虑返回一个命名清楚的结果类型。

==== 默认参数

函数参数可以指定默认值。调用时如果不提供该参数，就使用默认值：

```cpp
void connect(const std::string& host, int port = 8080, int timeout = 5000) {
    std::cout << "连接到 " << host << ":" << port 
              << "，超时 " << timeout << "ms" << std::endl;
}

int main() {
    connect("192.168.1.1");              // 使用默认端口和超时
    connect("192.168.1.1", 9000);        // 自定义端口，默认超时
    connect("192.168.1.1", 9000, 3000);  // 全部自定义
    return 0;
}
```

默认参数必须从右向左连续指定，不能跳过中间的参数：

```cpp
void func(int a, int b = 2, int c = 3);  // 合法
void func(int a = 1, int b, int c = 3);  // 非法，b 没有默认值但在有默认值的参数之后
```

如果函数声明和定义分离，默认参数应当只在声明中指定，不要在定义中重复：

```cpp
// 头文件中的声明
void log(const std::string& message, int level = 1);

// 源文件中的定义
void log(const std::string& message, int level) {  // 不重复默认值
    // ...
}
```

默认实参会在调用点补入，并不要求是编译期常量；它可以调用函数，也可以读取当时可见的对象。正因为默认值属于接口，应把它放在调用者能看到的声明中，并避免依赖难以察觉的可变状态。

==== 函数重载

C++ 允许定义多个同名但参数列表不同的函数，这称为函数重载。编译器根据调用时提供的参数类型和数量选择合适的版本：

```cpp
// 计算两个整数的平均值
double average(int a, int b) {
    return (static_cast<double>(a) + b) / 2.0;
}

// 计算三个整数的平均值
double average(int a, int b, int c) {
    return (static_cast<double>(a) + b + c) / 3.0;
}

// 计算浮点数数组的平均值
double average(const std::vector<double>& values) {
    // 本示例约定 values 非空；正式接口应明确处理空输入。
    double sum = 0;
    for (double v : values) sum += v;
    return sum / values.size();
}

int main() {
    std::cout << average(10, 20) << std::endl;         // 调用第一个版本
    std::cout << average(10, 20, 30) << std::endl;     // 调用第二个版本
    std::cout << average({1.5, 2.5, 3.5}) << std::endl; // 调用第三个版本
    return 0;
}
```

重载函数必须在参数的数量或类型上有所不同。仅返回类型不同不构成有效的重载，因为编译器无法仅根据返回类型确定调用哪个版本：

```cpp
int process(int x);
double process(int x);  // 错误！仅返回类型不同
```

重载解析会比较候选函数所需的转换，并选择规则上更好的匹配；它不是简单统计“转换次数”。如果没有唯一的最佳候选，调用就是歧义：

```cpp
void print(long x);
void print(double x);

print(3);  // int 转 long 与 int 转 double 均无更优者：调用有歧义
```

函数重载使得同一操作可以作用于不同类型的数据，提高了接口的一致性。在 RoboMaster 开发中，重载常见于各种初始化函数、数据转换函数等。

==== 内联函数

这里要区分两个容易混淆的概念。编译器的“内联优化”会把某次调用替换为函数体，是否这样做由优化器决定；源码中的 `inline` 关键字则主要改变定义规则，让同一个函数定义可以出现在多个翻译单元中，只要这些定义满足一致性要求：

```cpp
inline int max(int a, int b) {
    return (a > b) ? a : b;
}
```

因此，写了 `inline` 不保证展开，没写也不妨碍优化器展开。性能是否改善要看实际生成代码和测量结果，不能从这个关键字直接推断。

`inline` 函数的定义通常放在头文件中，因为每个使用它的翻译单元都需要能看到定义，而且头文件中的各份定义必须一致。普通非模板函数则通常只在一个 `.cpp` 文件中定义，并在头文件中留下声明。

```cpp
// math_utils.h
#ifndef MATH_UTILS_H
#define MATH_UTILS_H

inline int square(int x) {
    return x * x;
}

#endif
```

日常代码不必靠堆叠 `inline` 猜测性能。若性能分析指出某条调用路径确实是瓶颈，再结合优化选项、链接时优化和生成代码判断，证据会比关键字更可靠。

==== 递归函数

函数可以调用自身，这称为递归。递归是一种强大的问题解决技术，适合处理具有自相似结构的问题：

```cpp
// 计算阶乘：n! = n × (n-1)!
int factorial(int n) {
    // 约定 n >= 0，且结果能由 int 表示。
    if (n <= 1) {
        return 1;  // 基本情况：0! = 1! = 1
    }
    return n * factorial(n - 1);  // 递归情况
}
```

递归函数需要基本情况（base case），并让每次递归都朝它推进。否则调用会不断加深，通常最终耗尽可用栈空间并异常终止。阶乘示例还明确约定输入非负且结果能由 `int` 表示；基本情况并不能代替对输入范围的说明。

递归的经典例子包括树的遍历、快速排序、归并排序等。以下是一个在 RoboMaster 中可能用到的例子——路径搜索的简化版本：

```cpp
bool findPath(int x, int y, int targetX, int targetY, 
              std::vector<std::pair<int,int>>& path) {
    // 基本情况：越界或遇到障碍
    if (!isValid(x, y) || isObstacle(x, y) || isVisited(x, y)) {
        return false;
    }

    // 只有有效且可通行的位置才能成为终点
    if (x == targetX && y == targetY) {
        path.push_back({x, y});
        return true;
    }
    
    markVisited(x, y);
    path.push_back({x, y});
    
    // 递归情况：尝试四个方向
    if (findPath(x + 1, y, targetX, targetY, path) ||
        findPath(x - 1, y, targetX, targetY, path) ||
        findPath(x, y + 1, targetX, targetY, path) ||
        findPath(x, y - 1, targetX, targetY, path)) {
        return true;
    }
    
    // 回溯
    path.pop_back();
    return false;
}
```

递归能直接映射树和回溯问题的结构，但调用深度受可用栈空间限制，函数调用也可能带来成本。是否改写成显式栈或循环，要看最大深度、实时性要求和测量结果；“递归更简洁”与“迭代更快”都不是脱离场景的定律。

==== constexpr 函数

C++11 引入了 `constexpr` 函数，使同一个函数既能参与编译期求值，也能在运行时调用。当调用出现在常量表达式必须成立的位置时，参数和函数执行都需要满足相应规则；仅仅传入常量，并不保证普通变量的初始化一定发生在编译期：

```cpp
constexpr int square(int x) {
    return x * x;
}

int main() {
    constexpr int size = square(10);  // 编译期计算，size = 100
    int array[size];  // 合法，size 是编译期常量
    
    int runtime = getUserInput();
    int result = square(runtime);  // 运行时计算，仍然有效
    return 0;
}
```

`constexpr` 函数有一些限制：在 C++11 中，函数体只能包含一条 `return` 语句；C++14 放宽了这一限制，允许使用局部变量、循环和条件语句。

```cpp
// C++14 及以后
constexpr int factorial(int n) {
    int result = 1;
    for (int i = 2; i <= n; i++) {
        result *= i;
    }
    return result;
}

constexpr int fact5 = factorial(5);  // 编译期计算，fact5 = 120
```

`constexpr` 适合表达固定配置、维度和查找表生成等编译期已知关系。它首先提供的是“可用于常量表达式”的能力；是否带来可测量的启动或运行收益，还取决于计算规模、优化器和最终使用方式。

==== 函数设计原则

函数没有放之四海而皆准的理想行数或参数个数，但可以用几个问题判断划分是否合理：它是否只表达一个清楚的任务，调用者是否容易理解输入与结果，修改一个需求时是否会牵动无关逻辑？

函数应聚焦于一个能够命名的任务。篇幅很长、同时跨越传感器读取、状态决策和通信等不同层次，是值得拆分的信号；但为了追求短小而把连续逻辑切成许多没有意义的包装函数，同样会妨碍阅读。

函数名应当清晰描述其功能。好的命名使代码自文档化，减少注释的需要。动词开头的名称（如 `calculateDistance`、`isValid`、`sendCommand`）通常比名词更能表达函数的行为。

参数很多时，先看它们是否天然组成一个概念，例如相机内参或连接配置。用命名结构体组织相关参数，往往比记住一串位置更可靠；若参数属于几项互不相干的任务，则可能说明函数职责本身需要拆分。

没有接口兼容或缓冲区复用等约束时，优先考虑返回值，因为数据流向更显眼。返回值优化和移动语义经常能避免深拷贝，但“大对象返回一定没有成本”仍需结合对象结构和实际路径判断。

能把计算写成纯函数时，相同输入对应相同输出，也不修改外部状态，通常更容易测试和推理。I/O、设备控制等函数的目的本来就是产生副作用，重点不是消灭它们，而是让名称、接口和调用位置清楚地暴露这些影响。

```cpp
// 不好的设计：函数过长，职责不清
void processRobot() {
    // 200 行代码，混合了传感器读取、状态更新、通信、日志...
}

// 好的设计：职责分离，函数短小
void updateRobotState() {
    auto sensorData = readSensors();
    auto newState = computeState(sensorData);
    applyState(newState);
    logStateChange(newState);
}
```

函数解决了“把一段操作命名”的问题，接下来要处理的是“一组同类数据”。数组提供固定数量的连续元素，字符串类型则在连续字符存储之上提供了文本操作接口；下一节会同时比较底层数组与标准库封装，帮助你看清它们各自负责什么。

=== 数组与字符串
// C 风格数组
// std::array
// std::string 基础操作
//=== 数组与字符串

传感器的一帧读数、检测到的一组目标、最近若干时刻的轨迹，都需要按统一方式保存和遍历。数组把固定数量的同类型元素连续排列，并用索引定位；`std::array` 在保留这种布局的同时补上标准容器接口。文本这一边，C 风格字符串用字符数组和结尾的空字符表示，`std::string` 则是负责管理字符序列的类。把这几种形式放在一起比较，比笼统地说“字符串就是字符数组”更不容易混淆。

==== C 风格数组

C 风格数组是语言内建的数组类型，元素在内存中连续排列。下面这些局部数组具有自动存储期，常见实现通常把相应存储放在调用栈中，但“数组一定在栈上”并不是语言规则；数组也可以是静态对象或其他对象的成员。

```cpp
int scores[5];                    // 声明一个包含 5 个整数的数组
double sensorReadings[100];       // 声明一个包含 100 个双精度浮点数的数组
```

内建数组的元素个数必须在编译期确定并且大于 0，不能使用运行时才得到的长度。部分编译器把变长数组作为扩展接受，但标准 C++ 不支持这种写法。元素下标从 0 开始：

```cpp
int values[5] = {10, 20, 30, 40, 50};

int first = values[0];   // 10，第一个元素
int third = values[2];   // 30，第三个元素
int last = values[4];    // 50，最后一个元素

values[1] = 25;          // 修改第二个元素
```

数组可以在声明时初始化。如果初始值的数量少于数组大小，剩余元素被初始化为零；如果提供了初始值但省略数组大小，编译器会根据初始值数量自动确定大小：

```cpp
int a[5] = {1, 2, 3};        // a = {1, 2, 3, 0, 0}
int b[5] = {};               // b = {0, 0, 0, 0, 0}，全部初始化为 0
int c[] = {1, 2, 3, 4, 5};   // 编译器推断大小为 5
```

内建数组的下标访问不会在运行时自动检查边界。编译器有时能警告明显的常量越界，但一般的越界访问会产生未定义行为：程序可能终止、读到错误结果，也可能暂时没有明显症状却已经破坏了别处的数据。

```cpp
int arr[5] = {1, 2, 3, 4, 5};
int x = arr[10];   // 未定义行为！访问越界
arr[-1] = 0;       // 未定义行为！负索引
```

越界是 C/C++ 中一类常见且难排查的错误。机器人程序还会把错误结果传给后续控制模块，因此边界应和数据来源一起检查，不能把“这次运行没崩溃”当作访问合法的证据。

数组的元素个数属于数组类型的一部分，在当前作用域中编译器知道它；问题出在数组传给许多接口时会转换为指针，长度信息随之丢失。固定数组可以直接使用范围 `for`，用下标遍历时则应让循环上界与声明保持一致：

```cpp
const int SIZE = 5;
int values[SIZE] = {10, 20, 30, 40, 50};

// 传统 for 循环
for (int i = 0; i < SIZE; i++) {
    std::cout << values[i] << " ";
}

// 范围 for 循环（C++11）
for (int v : values) {
    std::cout << v << " ";
}
```

多维数组用于表示表格、矩阵等结构。声明时指定每个维度的大小，访问时提供每个维度的索引：

```cpp
// 3x4 的二维数组（3 行 4 列）
int matrix[3][4] = {
    {1, 2, 3, 4},
    {5, 6, 7, 8},
    {9, 10, 11, 12}
};

int element = matrix[1][2];  // 第 2 行第 3 列，值为 7

// 遍历二维数组
for (int i = 0; i < 3; i++) {
    for (int j = 0; j < 4; j++) {
        std::cout << matrix[i][j] << " ";
    }
    std::cout << std::endl;
}
```

C++ 的这种二维数组其实是“元素为数组的数组”，每一行连续存放，随后紧接下一行，通常称为行优先（row-major）布局。按这个顺序遍历更符合常见缓存的局部性，但具体性能仍取决于数组规模、访问模式和目标硬件。

==== 数组与函数

数组表达式在大多数函数调用中会发生数组到指针转换，形参里的 `int arr[]` 也会被调整为 `int*`。函数因此只收到首元素地址，不能从这个指针恢复原数组长度，接口必须另行携带元素个数：

```cpp
// 数组参数实际上是指针
void printArray(int arr[], int size) {
    for (int i = 0; i < size; i++) {
        std::cout << arr[i] << " ";
    }
    std::cout << std::endl;
}

// 等价写法
void printArray(int* arr, int size);

int main() {
    int values[] = {1, 2, 3, 4, 5};
    printArray(values, 5);
    return 0;
}
```

由于传递的是指针，函数内部对数组元素的修改会影响原数组。如果不希望函数修改数组内容，可以使用 `const` 修饰：

```cpp
#include <stdexcept>

double average(const int arr[], int size) {
    if (size <= 0) {
        throw std::invalid_argument("array must not be empty");
    }

    double sum = 0.0;
    for (int i = 0; i < size; i++) {
        sum += arr[i];
    }
    return sum / size;
}
```

这个接口还约定：`size > 0` 时，`arr` 指向至少 `size` 个有效元素。裸指针本身无法验证这项约定，这正是后续更倾向使用容器或带长度视图的原因。

对于多维数组，除第一维外的其他维度大小必须在函数参数中明确指定：

```cpp
void processMatrix(int matrix[][4], int rows) {
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < 4; j++) {
            // 处理 matrix[i][j]
        }
    }
}
```

这一限制源于编译器需要知道每行的大小才能正确计算元素地址。

==== std::array

C++11 的 `std::array<T, N>` 把固定长度数组包装成标准容器。它仍然连续存放 `N` 个 `T`，但能像普通对象一样复制、返回，并提供 `size()`、迭代器和可选的边界检查接口：

```cpp
#include <array>

std::array<int, 5> values = {10, 20, 30, 40, 50};

int first = values[0];       // 下标访问，不检查边界
int second = values.at(1);   // at() 访问，检查边界，越界抛出异常

std::cout << "大小：" << values.size() << std::endl;  // 5
std::cout << "是否为空：" << values.empty() << std::endl;  // false
```

`std::array` 相比内建数组的主要优势体现在接口上：

大小 `N` 是类型的一部分，`size()` 可以直接返回它，无需再维护一份可能失配的长度变量。

它提供边界检查选项。`at()` 方法在越界时抛出 `std::out_of_range` 异常，便于调试。

它可以像普通对象一样复制和赋值。C 风格数组不能直接赋值，`std::array` 可以：

```cpp
std::array<int, 3> a = {1, 2, 3};
std::array<int, 3> b = a;  // 复制整个数组
b = {4, 5, 6};             // 赋值
```

它可以作为函数返回值。C 风格数组不能从函数返回，`std::array` 可以：

```cpp
std::array<double, 3> getPosition() {
    return {1.0, 2.0, 3.0};
}
```

它与标准库算法和容器兼容。`std::array` 提供迭代器，可以与 `std::sort`、`std::find` 等算法配合使用：

```cpp
#include <algorithm>
#include <array>

std::array<int, 5> arr = {5, 2, 8, 1, 9};
std::sort(arr.begin(), arr.end());  // 排序

auto it = std::find(arr.begin(), arr.end(), 8);
if (it != arr.end()) {
    std::cout << "找到了 8" << std::endl;
}
```

`std::array` 的大小必须是编译期常量，这与 C 风格数组相同。如果需要运行时确定大小的数组，应当使用 `std::vector`（将在后续章节介绍）。

在 RoboMaster 开发中，`std::array` 适合存储固定大小的数据，如三维坐标、四元数、固定数量的电机参数等：

```cpp
std::array<double, 3> position = {0.0, 0.0, 0.0};
std::array<double, 4> quaternion = {1.0, 0.0, 0.0, 0.0};
std::array<int, 4> motorIDs = {1, 2, 3, 4};
```

==== C 风格字符串

在 C 语言中，字符串是以空字符（`'\0'`）结尾的字符数组。C++ 继承了这种表示方式，称为 C 风格字符串：

```cpp
char greeting[] = "Hello";  // 编译器自动添加 '\0'，实际大小为 6
char manual[] = {'H', 'e', 'l', 'l', 'o', '\0'};  // 等价写法
```

字符串字面量 `"Hello"` 的类型是 `const char[6]`，最后一个元素是 `\0`。现代 C++ 不允许把它直接赋给 `char*`；通过去除 `const` 强行修改字面量会产生未定义行为：

```cpp
const char* text = "Hello";  // 只读访问
// text[0] = 'h';             // 编译错误：不能通过 const char* 修改

char* forced = const_cast<char*>(text);
forced[0] = 'h';              // 未定义行为：字面量不能被修改
```

C 风格字符串的操作函数定义在 `<cstring>` 头文件中：

```cpp
#include <cstring>

char str1[20] = "Hello";
char str2[] = "World";

std::size_t len = std::strlen(str1);            // 长度不含 '\0'，返回 5
std::strcpy(str1, str2);                        // 复制 str2 到 str1
std::strcat(str1, "!");                         // 连接字符串
int cmp = std::strcmp(str1, str2);              // 相等时返回 0
const char* pos = std::strstr(str1, "or");      // 查找子串
```

`std::strcpy` 和 `std::strcat` 的接口不知道目标数组有多大；一旦调用者算错所需空间，就会越界写入。上例的 20 字节缓冲区足够容纳当前内容，但换一段输入便需要重新证明容量。处理普通文本时，`std::string` 通常能把这项易错的容量管理交给类型本身。

==== std::string

`std::string` 是标准库管理字符序列的类，能自动调整存储并提供查找、插入、替换等接口。它减少了手工维护结尾空字符和缓冲区容量的负担，但 `operator[]` 仍不检查边界，迭代器和 `c_str()` 指针也可能在修改后失效，因此不是“用了就不会错”的保险箱。

```cpp
#include <string>

std::string greeting = "Hello";
std::string name = "RoboMaster";
std::string message = greeting + ", " + name + "!";  // 字符串连接

std::cout << message << std::endl;  // 输出：Hello, RoboMaster!
std::cout << "长度：" << message.length() << std::endl;  // 长度：18
```

`std::string` 支持多种初始化方式：

```cpp
std::string s1;                    // 空字符串
std::string s2 = "Hello";          // 从字符串字面量初始化
std::string s3("Hello");           // 等价写法
std::string s4(5, 'x');            // "xxxxx"，5 个 'x'
std::string s5 = s2;               // 复制构造
std::string s6 = s2.substr(0, 3);  // "Hel"，子串
```

访问单个字符可以使用下标运算符或 `at()` 方法：

```cpp
std::string str = "Hello";

char c1 = str[0];      // 'H'，不检查边界
char c2 = str.at(1);   // 'e'，检查边界

str[0] = 'h';          // 修改第一个字符
```

`std::string` 提供了丰富的操作方法：

```cpp
std::string str = "Hello, World!";

// 查找
std::size_t pos = str.find("World");        // 返回 7
std::size_t pos2 = str.find("xyz");         // 返回 std::string::npos（未找到）

if (pos != std::string::npos) {
    std::cout << "找到了，位置：" << pos << std::endl;
}

// 子串
std::string sub = str.substr(7, 5);    // "World"，从位置 7 开始取 5 个字符

// 替换
str.replace(7, 5, "C++");              // "Hello, C++!"

// 插入和删除
str.insert(7, "Dear ");                // "Hello, Dear C++!"
str.erase(7, 5);                       // "Hello, C++!"

// 追加
str.append(" is great");               // "Hello, C++! is great"
str += "!";                            // 等价于 append

// 清空和判空
str.clear();                           // 清空字符串
bool isEmpty = str.empty();            // true
```

字符串比较可以直接使用关系运算符，按字典序比较：

```cpp
std::string a = "apple";
std::string b = "banana";

if (a < b) {
    std::cout << a << " 在 " << b << " 之前" << std::endl;
}

if (a == "apple") {
    std::cout << "是苹果" << std::endl;
}
```

这些位置和长度都以 `char` 元素为单位。字符串采用 UTF-8 时，它们对应字节偏移，而不是“第几个汉字”或屏幕上的字符宽度；需要字符级 Unicode 操作时仍要使用相应的文本库。

与 C 风格字符串的转换有时是必要的，特别是与 C 语言库或系统 API 交互时：

```cpp
std::string cppStr = "Hello";

// std::string 转 C 风格字符串
const char* cStr = cppStr.c_str();

// C 风格字符串转 std::string
const char* source = "World";
std::string newStr = source;  // 自动转换
```

`c_str()` 返回的指针借用 `cppStr` 管理的存储。不要在原字符串销毁后继续使用它；会改变字符串内容或容量的非 `const` 操作也可能使先前取得的指针失效。跨 C 接口传递时，应根据该接口是否保存指针来安排对象生命周期。

==== 字符串与数值转换

在处理配置文件、用户输入或通信协议时，经常需要在字符串和数值之间转换。C++11 提供了一组便捷的转换函数：

```cpp
#include <string>
#include <stdexcept>

// 数值转字符串
int num = 42;
double pi = 3.14159;
std::string s1 = std::to_string(num);   // "42"
std::string s2 = std::to_string(pi);    // "3.141590"

// 字符串转数值
std::string str1 = "123";
std::string str2 = "3.14";
std::string str3 = "42abc";

int i = std::stoi(str1);       // 123
double d = std::stod(str2);    // 3.14
std::size_t parsed = 0;
int partial = std::stoi(str3, &parsed); // 42，parsed 为 2

// 其他转换函数
long l = std::stol("1234567890");
float f = std::stof("2.718");
```

这些函数会跳过开头的空白，并允许在已解析数字后留下其他字符。若业务要求整个字符串都是一个整数，应再检查 `parsed == str3.size()`。完全无法解析时会抛出 `std::invalid_argument`，结果超出目标类型范围时会抛出 `std::out_of_range`：

```cpp
std::string input = "not a number";

try {
    int value = std::stoi(input);
} catch (const std::invalid_argument& e) {
    std::cerr << "无效输入：" << e.what() << std::endl;
} catch (const std::out_of_range& e) {
    std::cerr << "数值超出范围：" << e.what() << std::endl;
}
```

==== 字符串流

`<sstream>` 头文件提供的字符串流允许像使用 `cin`/`cout` 一样操作字符串，这在格式化输出和解析输入时非常有用：

```cpp
#include <sstream>

// 格式化输出到字符串
std::ostringstream oss;
oss << "Position: (" << 1.5 << ", " << 2.5 << ", " << 3.5 << ")";
std::string result = oss.str();  // "Position: (1.5, 2.5, 3.5)"

// 从字符串解析数据
std::string data = "100 200 300";
std::istringstream iss(data);
int x = 0, y = 0, z = 0;
if (iss >> x >> y >> z) {
    // 解析成功：x=100, y=200, z=300
}
```

字符串流在 RoboMaster 开发中常用于构建日志消息、解析配置文件或处理串口通信数据：

```cpp
// 构建日志消息
std::ostringstream log;
log << "[" << timestamp << "] Motor " << motorId 
    << ": speed=" << speed << " rpm, temp=" << temperature << "°C";
logger.write(log.str());

// 解析串口数据
std::string response = "OK 1234 5678";
std::istringstream parser(response);
std::string status;
int value1 = 0, value2 = 0;
if (parser >> status >> value1 >> value2) {
    // 三个字段都已读出，再继续校验其含义和范围。
}
```

流提取同样可能失败，协议解析还要检查字段数量、取值范围和是否允许尾随内容。字符串流适合演示和处理简单的文本格式；二进制串口帧则应按协议规定处理字节序、长度与校验，不能直接套用这段空格分隔示例。

==== 实践建议

固定长度数据通常先考虑 `std::array`，普通文本通常先考虑 `std::string`：它们把大小或容量纳入接口，更容易与算法配合。`std::array` 一般不需要额外动态存储；`std::string` 则可能分配内存，其成本是否重要要由数据规模、实时性要求和测量决定。

内建数组和以 `\0` 结尾的字符串仍会出现在 C 接口、硬件寄存器描述和既有协议边界。内存受限并不自动排除 `std::array`，因为它同样是固定容量；选择应依据 ABI、布局和工具链约束。把裸指针与长度的处理限制在边界层，并在进入程序内部时转换成含大小信息的视图或容器，通常更容易审查。

对于大小在运行时确定或需要动态增长的数组，应当使用 `std::vector`。它提供了动态数组的功能，是 C++ 中最常用的容器之一，将在后续章节详细介绍。

这一节已经多次碰到“数组转成首元素地址”和 `c_str()` 返回借用指针。下一节就沿着这条线认识指针：地址怎样表示，解引用意味着什么，以及为什么地址之外还必须同时考虑对象生命周期和有效范围。

=== 指针基础
// 指针概念、解引用
// 指针与数组
// 指针与函数参数
//=== 指针基础

指针保存一种“指向关系”：它可以指向某个对象、指向数组中的位置，也可以明确表示当前不指向对象。C 接口、迭代连续数据和动态多态都会用到它。真正的难点不在星号写哪边，而在每次使用前回答三个问题：它是否指向有效对象，可访问的范围有多大，这个对象还能存活多久？

==== 内存地址与指针的概念

入门时，可以把进程可访问的内存想成一排带编号的字节格子，对象占据其中一段，地址标出它的位置。这个模型有助于理解取地址和数组遍历；实际程序还隔着虚拟内存、对齐和编译器优化，指针也不应被当成可以任意计算的普通整数。

```cpp
int x = 42;
```

在一种常见实现中，`x` 可能占 4 字节，运行时地址看起来像 `0x7ffd5e8c`。这个数字每次运行都可能改变，优化器甚至可能让某些对象无需固定存储位置；一旦代码对 `x` 取地址，C++ 抽象机就会提供一个能指向该对象的指针值。

取地址运算符 `&` 用于获取变量的内存地址：

```cpp
int x = 42;
std::cout << "x 的值：" << x << std::endl;
std::cout << "x 的地址：" << &x << std::endl;  // 输出类似 0x7ffd5e8c
```

指针也是一种有类型的值。`int*` 表示它可以指向 `int` 对象；在常见机器上其内部表现为地址，但语言层面还规定了它所指对象的类型、允许的运算以及空指针状态：

```cpp
int x = 42;
int* ptr = &x;  // ptr 是指向 int 的指针，存储 x 的地址

std::cout << "ptr 的值：" << ptr << std::endl;   // x 的地址
std::cout << "ptr 指向的值：" << *ptr << std::endl;  // 42
```

这里 `int*` 表示“指向 int 的指针”类型。`ptr` 存储的是 `x` 的地址，通过解引用运算符 `*` 可以访问 `ptr` 所指向的内存中的值。

指针声明的语法有几种等价写法，选择哪种主要是风格问题：

```cpp
int* ptr1 = nullptr;   // 星号靠近类型，强调 ptr1 的类型是 int*
int *ptr2 = nullptr;   // 星号靠近变量名，C 语言传统风格
int * ptr3 = nullptr;  // 两边都有空格，较少使用
```

需要注意的是，星号只与紧跟其后的变量名结合。在同一行声明多个变量时容易出错：

```cpp
int* p1, p2;   // 注意：p1 是指针，p2 是普通 int！
int *p3, *p4;  // p3 和 p4 都是指针
```

为避免混淆，建议每行只声明一个指针变量。

==== 解引用与指针运算

解引用运算符 `*` 用于访问指针所指向的内存。它既可以读取值，也可以修改值：

```cpp
int x = 10;
int* ptr = &x;

std::cout << *ptr << std::endl;  // 读取：输出 10

*ptr = 20;  // 写入：修改 ptr 指向的内存
std::cout << x << std::endl;  // x 现在是 20
```

只要指针指向的是可修改且仍然存活的对象，解引用就能读写那个对象。多个指针也可能指向同一对象，这为函数参数和数据结构提供了灵活性，同时引出了别名和生命周期问题。

指针支持算术运算，但其行为与普通整数不同。指针加 1 不是地址值加 1，而是移动到下一个元素的位置：

```cpp
int arr[] = {10, 20, 30, 40, 50};
int* ptr = arr;  // 指向数组首元素

std::cout << *ptr << std::endl;       // 10
std::cout << *(ptr + 1) << std::endl; // 20
std::cout << *(ptr + 2) << std::endl; // 30

ptr++;  // ptr 现在指向 arr[1]
std::cout << *ptr << std::endl;  // 20
```

从效果上看，`ptr + 1` 跨过一个完整的 `int` 元素，不需要手工乘以 `sizeof(int)`。这种算术只在同一数组的元素范围内以及“末尾后一位”有效；可以生成末尾后一位指针用于比较，却不能解引用它。把任意对象地址不断加减并不受语言规则保护。

两个指向同一数组的指针可以相减，结果是它们之间的元素个数：

```cpp
int arr[] = {10, 20, 30, 40, 50};
int* p1 = &arr[1];
int* p2 = &arr[4];

std::ptrdiff_t diff = p2 - p1;  // 3，相差 3 个元素
```

==== 指针与数组

数组和指针的关系非常密切。在大多数表达式中，数组名会自动转换为指向首元素的指针：

```cpp
int arr[] = {10, 20, 30, 40, 50};

int* ptr = arr;        // arr 退化为 &arr[0]
std::cout << *ptr << std::endl;      // 10
std::cout << ptr[2] << std::endl;    // 30，等价于 *(ptr + 2)
std::cout << arr[2] << std::endl;    // 30，等价于 *(arr + 2)
```

下标运算符 `[]` 实际上是指针算术的语法糖：`arr[i]` 完全等价于 `*(arr + i)`。这也解释了为什么数组下标从 0 开始——`arr[0]` 就是 `*(arr + 0)`，即首元素本身。

数组与指针是不同类型。数组表达式会在许多场景转换为首元素指针，但数组本身不是“常量指针”，只是不能作为赋值左操作数。在尚未发生转换时，`sizeof` 能看到完整数组类型，而对指针使用 `sizeof` 只会得到指针对象本身的大小：

```cpp
int arr[5] = {1, 2, 3, 4, 5};
int* ptr = arr;

// arr = ptr;  // 错误！数组名不能被赋值

std::cout << sizeof(arr) << std::endl;  // 若 int 为 4 字节，则为 20
std::cout << sizeof(ptr) << std::endl;  // 常见 64 位平台上为 8
```

遍历数组可以使用下标，也可以使用指针：

```cpp
int arr[] = {10, 20, 30, 40, 50};
int size = sizeof(arr) / sizeof(arr[0]);

// 下标方式
for (int i = 0; i < size; i++) {
    std::cout << arr[i] << " ";
}

// 指针方式
for (int* p = arr; p < arr + size; ++p) {
    std::cout << *p << " ";
}

// 指针 + 下标混合
int* ptr = arr;
for (int i = 0; i < size; i++) {
    std::cout << ptr[i] << " ";
}
```

对这个数组，三段循环会按相同顺序访问相同元素。范围 `for` 或标准算法通常更直接；需要同时使用位置或与 C 接口交互时，下标和指针形式仍然有用。选择重点是边界是否清晰，而不是哪种写法看起来更“底层”。

==== 指针与函数参数

在前面的章节中，我们已经了解到 C++ 默认使用值传递——函数接收的是参数的副本，对副本的修改不影响原变量。通过指针传递，函数可以修改调用者的数据：

```cpp
// 值传递：无法修改原变量
void incrementByValue(int n) {
    n++;  // 只修改了副本
}

// 指针传递：可以修改原变量
void incrementByPointer(int* ptr) {
    if (ptr != nullptr) {
        ++(*ptr);  // 修改指针指向的内存
    }
}

int main() {
    int x = 10;
    
    incrementByValue(x);
    std::cout << x << std::endl;  // 仍然是 10
    
    incrementByPointer(&x);
    std::cout << x << std::endl;  // 变成 11
    
    return 0;
}
```

指针参数常见于下面几类接口。是否允许传入 `nullptr` 应由接口明确说明；如果参数必须存在，后面的引用通常表达得更直接。

需要修改调用者的变量时，如交换两个变量的值：

```cpp
void swap(int* a, int* b) {
    // 约定 a 和 b 都指向有效的 int。
    int temp = *a;
    *a = *b;
    *b = temp;
}

int x = 10, y = 20;
swap(&x, &y);  // x = 20, y = 10
```

需要返回多个值时，可以通过指针参数“返回”额外的结果：

```cpp
#include <limits>

// 通过返回值报告是否成功，通过指针写出商和余数。
bool divide(int dividend, int divisor, int* quotient, int* remainder) {
    const bool signedOverflow =
        dividend == std::numeric_limits<int>::min() && divisor == -1;
    if (divisor == 0 || signedOverflow || quotient == nullptr ||
        remainder == nullptr || quotient == remainder) {
        return false;
    }
    *quotient = dividend / divisor;
    *remainder = dividend % divisor;
    return true;
}

int q = 0, r = 0;
if (divide(17, 5, &q, &r)) {
    // q = 3, r = 2
}
```

传递大型数据结构时，避免复制开销：

```cpp
// 按值：调用者传入左值时复制结构体
void processData(LargeStruct data);

// 指针：借用已有对象，并允许 nullptr 表示没有数据
void processData(const LargeStruct* data);
```

函数不通过指针修改对象时，应把指向类型写成 `const`，让编译器检查这项约束。若数据不可缺少，`const LargeStruct&` 往往比指针更合适；若函数要保存数据供调用结束后使用，还要另行设计所有权和生命周期，不能只比较传参字节数。

==== 空指针与野指针

指针可以明确表示当前不指向任何对象，这个特殊值称为空指针（null pointer）。C++11 之前的代码常用 `NULL` 或 `0`；它们也可能作为整数参与重载解析。`nullptr` 具有专门的 `std::nullptr_t` 类型，能转换为相应指针而不会被误当成普通整数，因此现代代码优先使用它：

```cpp
int* ptr1 = nullptr;  // C++11 推荐写法
int* ptr2 = NULL;     // C 风格，仍然有效
int* ptr3 = 0;        // 也有效，但不推荐

if (ptr1 == nullptr) {
    std::cout << "ptr1 是空指针" << std::endl;
}
```

解引用空指针是未定义行为，常见表现是段错误，但语言不保证一定以可见的崩溃结束。对于可空指针，应在解引用前处理空值：

```cpp
void processTarget(Target* target) {
    if (target == nullptr) {
        std::cerr << "错误：目标指针为空" << std::endl;
        return;
    }
    
    // 安全地使用 target
    target->track();
}
```

还要区分两类无效指针：未初始化指针的值不确定，常被称为“野指针”；曾经指向有效对象、但对象已经销毁的指针称为悬空指针（dangling pointer）。下面返回的地址在函数结束后立刻悬空，解引用会产生未定义行为：

```cpp
int* createDanglingPointer() {
    int local = 42;
    return &local;  // 危险！返回局部变量的地址
}

int main() {
    int* ptr = createDanglingPointer();
    // ptr 现在是悬空指针，local 已经被销毁
    std::cout << *ptr << std::endl;  // 未定义行为！
    return 0;
}
```

避免这类问题的关键是让被指对象活得足够久，并明确谁负责销毁它。不要返回普通局部变量的地址；尽量用容器和 RAII 类型表达所有权；借用指针则要短于所有者的生命周期。把某一个指针变量置空只能保护这一个副本，无法修复仍指向旧地址的其他别名。

==== const 与指针

`const` 关键字与指针结合使用时，可以限制指针本身或指针所指向的数据。根据 `const` 的位置不同，有三种情况：

指向常量的指针（pointer to const）：不能通过指针修改所指向的数据，但指针本身可以改变指向：

```cpp
int x = 10, y = 20;
const int* ptr = &x;  // ptr 指向 const int

// *ptr = 30;  // 错误！不能通过 ptr 修改数据
ptr = &y;     // 允许，ptr 可以指向其他地址
```

常量指针（const pointer）：指针本身不能改变指向，但可以通过指针修改数据：

```cpp
int x = 10, y = 20;
int* const ptr = &x;  // ptr 是 const，指向 int

*ptr = 30;    // 允许，可以修改数据
// ptr = &y;  // 错误！ptr 不能指向其他地址
```

指向常量的常量指针：两者都不能改变：

```cpp
int x = 10;
const int* const ptr = &x;

// *ptr = 30;  // 错误！
// ptr = &y;   // 错误！
```

记忆技巧是从右向左读：`const int* ptr` 读作“ptr 是指针，指向 const int”；`int* const ptr` 读作“ptr 是 const，是指针，指向 int”。

在函数参数中，`const` 指针用于表明函数不会修改传入的数据：

```cpp
// 承诺不修改数组内容
double calculateAverage(const int* arr, int size) {
    // 约定 size > 0，且 arr 指向至少 size 个有效元素。
    double sum = 0;
    for (int i = 0; i < size; i++) {
        sum += arr[i];
        // arr[i] = 0;  // 错误！不能修改
    }
    return sum / size;
}
```

==== 指针与动态内存

前面的局部对象大多具有自动存储期，离开作用域便自动销毁。运行时长度的容器和跨作用域共享的数据通常会在内部申请动态存储，但现代 C++ 并不要求业务代码亲自写 `new`：`std::vector`、`std::string` 和智能指针会把申请与释放绑定到对象生命周期。本小节仍介绍裸 `new` / `delete`，目的是读懂既有代码和理解它们必须成对出现的原因。

`new` 表达式从动态存储区申请空间并构造对象，`delete` 表达式销毁对象并释放对应空间；常见实现把这片存储称为堆（heap）或自由存储区（free store）：

```cpp
// 分配单个对象
int* ptr = new int{42};   // 分配并初始化一个 int
delete ptr;               // 释放内存

// 分配并初始化
int* ptr2 = new int(100); // 分配并初始化为 100
delete ptr2;

// 分配数组
int* arr = new int[10];   // 分配 10 个 int 的数组
for (int i = 0; i < 10; i++) {
    arr[i] = i * 10;
}
delete[] arr;             // 注意：数组用 delete[]
```

手工管理动态内存时，分配路径与每一条退出路径都必须匹配。下面几类错误尤其常见：

内存泄漏：分配了内存但忘记释放，导致内存被持续占用：

```cpp
void memoryLeak() {
    int* ptr = new int[1000];
    // 忘记 delete[]，函数返回后内存泄漏
}
```

重复释放：对同一块内存调用多次 `delete`，导致未定义行为：

```cpp
int* ptr = new int;
delete ptr;
delete ptr;  // 错误！重复释放
```

使用已释放的内存：释放后继续使用指针：

```cpp
int* ptr = new int(42);
delete ptr;
std::cout << *ptr << std::endl;  // 未定义行为！
```

数组与单对象混淆：用 `delete` 释放 `new[]` 分配的内存，或反过来：

```cpp
int* arr = new int[10];
delete arr;    // 错误！应该用 delete[]
```

普通动态数组优先交给 `std::vector`，独占动态对象可由 `std::unique_ptr` 管理；只有多个所有者确实需要共同延长对象生命时，才考虑 `std::shared_ptr`。这些类型在析构时完成释放，让异常和提前返回也不容易漏掉清理。智能指针将在后续章节详细介绍。

运行时缓冲区和目标列表可能需要动态容量。若某条控制路径有明确的延迟上界要求，分配器延迟和内存碎片是否可接受需要在目标平台上验证；可根据最大规模预留容量、在初始化阶段建好对象池，或使用项目选定的实时分配策略。没有实时约束的路径则不必仅凭印象拒绝动态分配。

==== 指针的常见用途

指针在 C++ 中有多种重要用途，以下是一些典型场景：

实现数据结构。链表、树、图等结构需要节点之间相互引用，指针是实现这种引用的自然方式：

```cpp
struct ListNode {
    int data;
    ListNode* next = nullptr;
};
```

多态与动态绑定。通过基类指针调用派生类的方法，是面向对象编程的核心技术（后续章节介绍）：

```cpp
class Robot {
public:
    virtual ~Robot() = default;
    virtual void move() = 0;
};

void controlRobot(Robot* robot) {
    if (robot != nullptr) {
        robot->move();  // 根据实际类型调用对应的实现
    }
}
```

可选参数。指针可以为 `nullptr` 表示“无值”，这在引用无法做到的场景很有用：

```cpp
void processData(const Config* optionalConfig = nullptr) {
    if (optionalConfig != nullptr) {
        // 使用配置
    } else {
        // 使用默认配置
    }
}
```

与 C 语言库交互。许多系统 API 和第三方库使用 C 风格接口，需要通过指针传递数据。

==== 实践建议

把指针用好，核心是把“是否可空、是否拥有对象、能访问多大范围、能使用多久”写进接口，而不是只在解引用处保持小心：

始终初始化指针。自动存储期的未初始化指针具有不确定值，读取或解引用可能导致未定义行为；暂时没有指向目标时用 `nullptr` 明确表达。

只有接口允许为空时，检查 `nullptr` 才是对应的处理方式。若空值本身违反前置条件，可以改用引用、断言或显式报错，避免检查后悄悄忽略本应暴露的问题。

不得再使用已经释放的对象。把唯一的裸指针变量置为 `nullptr` 能防止它被误用，也让再次 `delete` 这个变量无害；但其他指针副本仍会悬空，所以这不能代替清楚的所有权设计。

```cpp
delete ptr;
ptr = nullptr;
```

不需要“可空”语义、也不表达所有权时，引用通常更直接；引用同样可能因被引用对象过早销毁而悬空，生命周期约束依然存在。

需要拥有单个动态对象时优先考虑 `std::unique_ptr`。`std::shared_ptr` 表达的是共享所有权，会增加计数和生命周期复杂度，不应只因为“更智能”就默认采用。

指针把地址、范围、生命周期和所有权几个问题集中摆到了台面上。引用并不会消除这些问题，但它能直接表达“这里必须绑定到一个对象，而且调用时不需要写取地址与解引用”。下一节将把两种间接访问方式放在同一组场景中比较。

=== 引用
// 引用 vs 指针
// 引用作为函数参数
// 常量引用
// === 引用

引用（reference）为已有对象提供另一个名字。它没有独立的“空”状态，也不能在绑定后改指向，因此很适合表达“这个参数必须是某个现有对象”。不过，引用仍可能在原对象销毁后悬空，也不会自动解决并发或别名问题。本节把它与指针并列比较，重点不是选出永远更好的那个，而是让接口语义与工具相匹配。

==== 引用的基本概念

引用是已存在变量的另一个名字。声明引用时，在类型名后加上 `&` 符号，并且必须在声明时初始化：

```cpp
int x = 42;
int& ref = x;  // ref 是 x 的引用，即 x 的别名

std::cout << x << std::endl;    // 42
std::cout << ref << std::endl;  // 42

ref = 100;  // 通过引用修改
std::cout << x << std::endl;    // 100，x 也变了
```

在这个例子中，`ref` 绑定到 `x`。表达式中使用 `ref`，操作的就是 `x`；语言层面也不把引用视为一个可以独立复制、赋值的对象。至于编译器是否真的为引用保存一个地址，要看具体上下文和优化结果。

与指针不同，引用一旦绑定到某个变量，就不能再绑定到其他变量。引用在声明时必须初始化，之后对引用的任何赋值都是在修改被引用对象的值，而非改变引用本身的绑定：

```cpp
int a = 10;
int b = 20;
int& ref = a;  // ref 绑定到 a

ref = b;  // 这不是让 ref 绑定到 b，而是把 b 的值赋给 a
std::cout << a << std::endl;  // 20，a 的值变成了 b 的值
std::cout << &a << std::endl; // a 的地址
std::cout << &ref << std::endl; // 相同的地址，ref 仍然绑定到 a
```

固定绑定让引用的局部含义比较稳定：代码不必追踪它后来又指向了谁。访问时也不写 `*`，调用引用参数时不写 `&`；简洁的同时，函数是否会修改实参就要依靠参数类型和命名来表达。

==== 引用与指针的对比

引用和指针都能间接访问对象，但接口语义不同：引用表达必须存在且固定绑定，裸指针还可以表达空值和重新指向。

引用声明时必须初始化，不能正常构造出一个“空引用”；指针则可以用 `nullptr` 表示没有对象。函数收到引用时无需检查空值，但仍依赖调用者保证对象在整个使用期内存活。可空指针只有在解引用前才需要走非空分支：

```cpp
void processWithPointer(int* ptr) {
    if (ptr == nullptr) {  // 该接口允许为空，因此先处理空值
        return;
    }
    *ptr = 100;
}

void processWithReference(int& ref) {
    // 没有空值分支；调用期间对象仍须有效
    ref = 100;
}
```

引用一旦绑定便不能改绑，指针变量却可以在一组对象之间移动。前者适合稳定的参数关系，后者适合遍历、搜索结果和显式的可选状态。

再者，语法上的差异也很明显。指针需要 `*` 来解引用、`&` 来取地址，而引用的使用与普通变量无异：

```cpp
int x = 42;

// 使用指针
int* ptr = &x;
*ptr = 100;
std::cout << *ptr << std::endl;

// 使用引用
int& ref = x;
ref = 100;
std::cout << ref << std::endl;
```

引用省去了显式解引用，成员访问和普通对象一致；指针的 `*` 与 `->` 则会提醒读者这里存在一次间接访问。哪一种更清楚取决于这次间接关系是否需要被强调。

语言没有数组元素为引用的类型，也没有最终保留下来的“引用的引用”类型；模板与类型别名中出现多层引用时，会按引用折叠规则化简。指针则可以组成 `int**` 这样的多级指针和指针数组，适合需要重新连接节点或操作 C 风格句柄的结构。

一个实用起点是：必需且不转移所有权的单个对象用引用，可选对象或需要改指向时用裸指针，连续区间则用容器或带长度的视图。智能指针解决的是所有权，不是裸指针的通用替代品；非拥有的借用关系仍然可以用引用或裸指针表达。

==== 引用作为函数参数

引用最常见的用途是作为函数参数。在前面的章节中，我们已经见过这种用法，现在来更深入地理解它的工作原理和优势。

当使用值传递时，函数接收的是实参的副本，对形参的修改不会影响实参。而使用引用传递时，形参是实参的别名，对形参的修改直接作用于实参：

```cpp
void swapByValue(int a, int b) {
    int temp = a;
    a = b;
    b = temp;
    // 交换的只是副本，对原变量没有影响
}

void swapByReference(int& a, int& b) {
    int temp = a;
    a = b;
    b = temp;
    // 直接操作原变量，交换成功
}

int main() {
    int x = 10, y = 20;
    
    swapByValue(x, y);
    std::cout << x << ", " << y << std::endl;  // 10, 20，没有交换
    
    swapByReference(x, y);
    std::cout << x << ", " << y << std::endl;  // 20, 10，交换成功
    
    return 0;
}
```

非常量引用允许函数修改调用者的对象。它可以承载输出参数，不过多个结果通常也值得考虑返回一个命名结构体，让数据流向在调用处更明显：

```cpp
#include <limits>

// 计算同时返回商和余数
bool divideWithRemainder(int dividend, int divisor,
                         int& quotient, int& remainder) {
    const bool signedOverflow =
        dividend == std::numeric_limits<int>::min() && divisor == -1;
    if (divisor == 0 || signedOverflow || &quotient == &remainder) {
        return false;
    }
    quotient = dividend / divisor;
    remainder = dividend % divisor;
    return true;
}

int main() {
    int q = 0, r = 0;
    if (divideWithRemainder(17, 5, q, r)) {
        std::cout << "商: " << q << ", 余数: " << r << std::endl;
    }
    return 0;
}
```

引用参数还可以避免为了只读一次而复制整个容器。下面先预览 `const` 引用：它没有构造 `vector` 副本，但函数调用本身以及访问数据当然仍有成本。

```cpp
// 值传递：每次调用都会复制整个 vector
double calculateAverageByValue(std::vector<double> data) {
    // 约定 data 非空。
    double sum = 0;
    for (double v : data) sum += v;
    return sum / data.size();
}

// 常量引用：不复制 vector，也不通过参数修改它
double calculateAverageByReference(const std::vector<double>& data) {
    // 约定 data 非空。
    double sum = 0;
    for (double v : data) sum += v;
    return sum / data.size();
}
```

对包含大量元素的左值 `vector`，按值版本需要复制元素，常量引用版本不需要。差异有多大仍取决于调用频率、元素类型和优化结果；传感器批量数据、图像帧等只读参数通常从常量引用或专用视图开始考虑。

引用参数与指针参数相比，调用时的语法更加自然。使用指针参数时，调用者需要显式取地址；使用引用参数时，直接传入变量名即可：

```cpp
void updateWithPointer(int* ptr) { *ptr = 100; }  // 约定 ptr 非空且有效
void updateWithReference(int& ref) { ref = 100; }

int x = 0;
updateWithPointer(&x);   // 需要 &
updateWithReference(x);  // 直接传变量名
```

然而，这种简洁性也带来一个潜在的问题：从调用代码来看，无法直接判断函数是否会修改参数。`updateWithReference(x)` 看起来像是值传递，但实际上 `x` 可能被修改。为了解决这个问题，当函数不需要修改参数时，应当使用常量引用。

==== 常量引用

常量引用（const reference）是指向常量的引用，通过它不能修改被引用的对象。声明常量引用时，在类型前加上 `const`：

```cpp
int x = 42;
const int& cref = x;

std::cout << cref << std::endl;  // 42，可以读取
// cref = 100;  // 错误！不能通过常量引用修改
```

常量引用常用于只读参数：函数不能通过这个参数修改对象，并且不会仅为传参复制整个对象。它既是编译器可检查的局部约束，也是接口文档的一部分：

```cpp
// 常量引用参数：承诺不修改 data
double calculateAverage(const std::vector<double>& data) {
    // 约定 data 非空。
    double sum = 0;
    for (double v : data) sum += v;
    // data.push_back(0);  // 错误！不能通过 data 修改
    return sum / data.size();
}
```

这项承诺只约束通过 `data` 进行的操作。如果函数还持有同一对象的非常量指针、访问全局状态或调用能修改它的其他接口，原对象仍可能变化；`const&` 不是整个程序范围的不可变性保证。

`const` 左值引用还可以绑定到临时对象。局部引用直接绑定临时时，临时对象的生命周期通常延长到该引用的生命周期；函数参数绑定临时时，临时只存活到包含这次调用的完整表达式结束：

```cpp
// int& ref = 42;  // 错误！普通引用不能绑定到字面量
const int& cref = 42;  // 正确，常量引用可以绑定到临时值

// 这使得以下调用成为可能
void printValue(const int& value) {
    std::cout << value << std::endl;
}

printValue(100);  // 可以传入字面量
printValue(x + y);  // 可以传入表达式的结果
```

如果函数参数是非常量引用，就不能传入临时值：

```cpp
void modify(int& value) {
    value = 100;
}

// modify(42);  // 错误！不能将临时值绑定到非常量引用
```

这个规则让 `int&` 明确表示“可修改的左值”。C++11 另有 `int&&` 这样的右值引用专门绑定临时对象；修改临时对象在移动语义等场景并非没有意义，只是不能通过普通左值引用完成。

小型标量通常直接按值传递；只读的大型容器和类对象常用常量引用。不过类型是“类”并不自动意味着复制昂贵，小型值类型可能更适合按值，字符串切片等需求也可用专门视图。下面展示几种常见意图：

```cpp
#include <cmath>

// 基本类型：值传递
int square(int x) {
    // 约定乘积能由 int 表示。
    return x * x;
}

// 类类型：常量引用传递
void logMessage(const std::string& message) {
    std::cout << "[LOG] " << message << std::endl;
}

// 容器：常量引用传递
void processReadings(const std::vector<double>& readings) {
    // 处理传感器读数
}

// 需要修改时：非常量引用传递
bool normalizeWeights(std::vector<double>& weights) {
    double sum = 0;
    for (double weight : weights) {
        if (!std::isfinite(weight) || weight < 0.0) {
            return false;
        }
        sum += weight;
    }
    if (!(sum > 0.0) || !std::isfinite(sum)) {
        return false;
    }
    for (double& weight : weights) {
        weight /= sum;
    }
    return true;
}
```

==== 引用作为返回值

函数不仅可以接受引用作为参数，还可以返回引用。返回引用允许调用者直接访问和修改函数返回的对象，而无需复制。这在操作容器元素时特别有用：

```cpp
class Warehouse {
private:
    std::vector<int> inventory;
    
public:
    Warehouse() : inventory(10, 0) {}
    
    // 返回引用，允许外部修改库存
    int& itemAt(std::size_t index) {
        return inventory.at(index);
    }
    
    // 返回常量引用，只允许读取
    const int& itemAt(std::size_t index) const {
        return inventory.at(index);
    }
};

int main() {
    Warehouse warehouse;
    warehouse.itemAt(3) = 100;  // 直接修改库存
    std::cout << warehouse.itemAt(3) << std::endl;  // 100
    return 0;
}
```

标准库中的 `std::vector::operator[]` 和 `std::map::operator[]` 都返回引用，这就是为什么我们可以写 `vec[0] = 10` 这样的代码。

然而，返回引用时必须格外小心：绝不能返回局部变量的引用。局部变量在函数返回后被销毁，返回它的引用会导致未定义行为：

```cpp
// 危险！返回局部变量的引用
int& badFunction() {
    int local = 42;
    return local;  // local 即将被销毁，返回的引用是悬空的
}

int main() {
    int& ref = badFunction();  // ref 是悬空引用
    std::cout << ref << std::endl;  // 未定义行为！
    return 0;
}
```

能否安全返回引用，取决于被引用对象是否比所有使用者活得更久。成员引用会随所属对象销毁，并可能在容器重分配后失效；参数引用受调用者对象的生命周期约束；动态对象还必须有清楚的所有者。静态存储期对象通常存活到程序结束，但也可能引入共享状态。与其背一张“可返回类型”清单，不如在接口处明确引用的来源和失效条件。

==== 引用的底层实现

从语言语义看，引用就是别名，并未规定必须占多少字节。需要把引用跨函数传递或存进对象布局时，常见 ABI 可能用地址实现；在局部优化后，它也可能完全不占独立存储。下面的指针代码只能作为理解固定绑定的一种类比，不是编译器必须生成的代码：

```cpp
int x = 42;
int& ref = x;
ref = 100;

// 固定绑定的一种概念类比（不是规定的转换结果）：
// int* const ref_impl = &x;
// *ref_impl = 100;
```

这段类比不能直接推出二者生成相同指令，更不能单凭源码判断性能；优化器可能消除两种形式的间接访问。引用真正提供的是语言层面的固定绑定和非空语法，指针则保留空值与改指向能力。

需要注意，`int* const p = nullptr;` 完全合法，所以“常量指针”并不能解释引用为何没有空状态；这些是引用类型本身的语言规则。对引用取地址会得到被引用对象的地址，程序也无法用普通赋值改变其绑定。

==== 实践中的选择

掌握了引用和指针的区别后，在实际编程中应当根据具体需求选择合适的工具。以下是一些指导原则：

当需要表示“可能不存在”的语义时，使用指针。引用必须绑定到有效对象，无法表示空值；而指针可以为 `nullptr`，明确表示“当前没有指向任何对象”：

```cpp
// 指针：可能找不到目标
const Target* findTarget(const std::vector<Target>& targets) {
    for (const auto& t : targets) {
        if (t.isValid()) return &t;
    }
    return nullptr;  // 没有找到
}
```

返回的指针只是在借用 `targets` 中的元素：容器销毁或某些修改导致元素地址失效后，调用者不能继续使用它。若需要让结果独立存活，应返回值、索引或具有明确所有权的对象。

当参数必须存在且函数要修改调用者对象时，非常量引用能直接表达这一点：

```cpp
void updatePosition(double& x, double& y, double dx, double dy) {
    x += dx;
    y += dy;
}
```

只读借用大型对象时，常量引用通常能避免不需要的复制，并约束通过该参数的修改：

```cpp
void analyze(const SensorData& data) {
    // 分析数据，不修改
}
```

当需要重新指向不同对象时，使用指针。引用一旦绑定就不能改变，而指针可以：

```cpp
void processTargets(std::vector<Target>& targets) {
    Target* current = nullptr;
    for (auto& t : targets) {
        current = &t;  // 指针可以改变指向
        process(*current);
    }
}
```

当与 C 语言库或需要指针语义的 API 交互时，使用指针。许多系统调用和第三方库采用 C 风格接口，必须使用指针。

在机器人代码里，配置和批量数据常以引用借用，硬件 API、节点链接和可选搜索结果则常出现指针。具体选择仍由接口含义决定，不能只看“上层”还是“底层”。

到这里，指针与引用的边界已经清楚：它们都能借用现有对象，但对空值、改绑和所有权表达不同。下一节把视角从“怎样访问一个对象”移到“怎样把相关字段组成一个对象”，从结构体开始建立自己的数据类型。


=== 结构体
// struct 定义与使用
// 为“类”做铺垫
// === 结构体

数组擅长保存一组同类型元素，但一个“目标”同时有位置、颜色、置信度和时间戳，不能靠下标含糊地塞进同一个数组。结构体（`struct`）把这些相关字段组成一个有名字的新类型，让函数接收的是“一个目标”，而不是一串容易传错顺序的独立参数。

==== 结构体的定义

结构体使用 `struct` 关键字定义，在花括号内列出各个成员变量（也称为字段）：

```cpp
struct Target {
    double x;
    double y;
    double z;
    int color;
    double confidence;
    long long timestamp;
};
```

这段代码定义了一个名为 `Target` 的新类型。`Target` 类型的变量将包含六个成员：三个表示空间坐标的 `double`、一个表示颜色的 `int`、一个表示置信度的 `double`、以及一个表示时间戳的 `long long`。注意结构体定义末尾的分号是必需的，遗漏它是常见的语法错误。

定义好结构体类型后，就可以像使用内置类型一样声明该类型的变量：

```cpp
Target enemy{};               // 声明并值初始化一个 Target
Target detectedTargets[10]{}; // 十个 Target，均完成值初始化
```

结构体将相关数据封装在一起，使代码的意图更加清晰。与使用六个独立变量相比，一个 `Target` 变量明确表达了“这些数据属于同一个目标”的语义关系。

==== 成员访问与初始化

访问结构体的成员使用点运算符（`.`）。通过点运算符，可以读取或修改结构体变量的各个字段：

```cpp
Target enemy{};
enemy.x = 1000.0;
enemy.y = 500.0;
enemy.z = 200.0;
enemy.color = 1;  // 假设 1 表示红色
enemy.confidence = 0.95;
enemy.timestamp = 1703491200000;

std::cout << "目标位置: (" << enemy.x << ", " << enemy.y << ", " << enemy.z << ")" << std::endl;
std::cout << "置信度: " << enemy.confidence << std::endl;
```

逐个赋值的方式有些繁琐，C++ 提供了多种更简洁的初始化语法。最直接的是使用花括号初始化列表，按照成员声明的顺序提供初始值：

```cpp
Target enemy = {1000.0, 500.0, 200.0, 1, 0.95, 1703491200000};
```

C++11 的列表初始化可以省略等号；C++20 又为聚合类型加入指定初始化器，允许写出成员名。指定项仍须遵循成员声明顺序，并不是任意顺序的“键值表”：

```cpp
// C++11 风格
Target enemy1{1000.0, 500.0, 200.0, 1, 0.95, 1703491200000};

// C++20 指定初始化器，更加清晰
Target enemy2{.x = 1000.0, .y = 500.0, .z = 200.0, 
              .color = 1, .confidence = 0.95, .timestamp = 1703491200000};
```

对这里这个没有默认成员初始化器的聚合，列表中的值不足时，剩余标量成员会被值初始化为 0；空花括号因此把所有字段置为 0。若成员自身有默认初始化器，则缺省项优先使用那个默认值：

```cpp
Target partial = {100.0, 200.0};  // x=100, y=200, 其余为 0
Target zeroed = {};                // 所有成员为 0
```

结构体也可以在定义时为成员指定默认值，这是 C++11 引入的特性：

```cpp
struct Target {
    double x = 0.0;
    double y = 0.0;
    double z = 0.0;
    int color = 0;
    double confidence = 0.0;
    long long timestamp = 0;
};

Target t;  // 所有成员都使用默认值
```

默认值使得创建结构体变量时无需显式初始化每个成员，特别适合那些有合理默认状态的类型。

==== 结构体与函数

结构体可以作为函数的参数和返回值，这使得函数能够处理复合数据而无需传递大量独立参数。

将结构体作为参数传递时，默认是值传递——函数接收的是结构体的副本：

```cpp
void printTarget(Target t) {
    std::cout << "位置: (" << t.x << ", " << t.y << ", " << t.z << ")" << std::endl;
    std::cout << "置信度: " << t.confidence << std::endl;
}

Target enemy = {1000.0, 500.0, 200.0, 1, 0.95, 1703491200000};
printTarget(enemy);  // 传递副本
```

值传递会构造一份参数对象。像 `Target` 这样的结构体是否值得改用引用，要看大小、调用频率和函数是否需要自己的副本；只读借用较大对象时，常量引用通常是清晰的起点：

```cpp
// 常量引用：避免复制，且不会修改原数据
void printTarget(const Target& t) {
    std::cout << "位置: (" << t.x << ", " << t.y << ", " << t.z << ")" << std::endl;
}

// 引用：允许修改原数据
void updatePosition(Target& t, double dx, double dy, double dz) {
    t.x += dx;
    t.y += dy;
    t.z += dz;
}
```

函数也可以返回结构体。这是从函数返回多个相关值的自然方式：

```cpp
Target createTarget(double x, double y, double z, int color) {
    Target t;
    t.x = x;
    t.y = y;
    t.z = z;
    t.color = color;
    t.confidence = 1.0;
    t.timestamp = getCurrentTime();
    return t;
}

Target newTarget = createTarget(500.0, 300.0, 100.0, 1);
```

按值返回结构体是正常用法。对 `return t;` 这样的命名局部变量，编译器通常可以做命名返回值优化（NRVO）；未做时还可能使用移动或复制。是否有可测成本取决于类型与构建选项，但不应为了猜测优化而改成返回局部对象的指针或引用。

比较一下使用结构体前后的函数签名，可以明显感受到结构体带来的清晰度提升：

```cpp
// 不使用结构体：参数众多，容易混淆顺序
void processTarget(double x, double y, double z, int color, 
                   double confidence, long long timestamp);

// 使用结构体：意图清晰，不易出错
void processTarget(const Target& target);
```

==== 结构体与指针

当通过指针访问结构体成员时，需要先解引用指针，再使用点运算符。由于运算符优先级的关系，必须使用括号：

```cpp
Target enemy = {1000.0, 500.0, 200.0, 1, 0.95, 0};
Target* ptr = &enemy;

// 方式一：先解引用，再访问成员
(*ptr).x = 1500.0;

// 方式二：使用箭头运算符（更常用）
ptr->y = 600.0;
```

箭头运算符 `->` 是 `(*ptr).` 的简写形式，在实际代码中更为常见。它使得通过指针访问成员的语法更加简洁：

```cpp
void updateTarget(Target* t) {
    if (t == nullptr) return;
    
    t->x += 10.0;
    t->y += 10.0;
    t->confidence *= 0.99;  // 置信度衰减
}
```

在 RoboMaster 开发中，指向结构体的指针常用于动态分配的对象、链表节点、以及需要可选参数的场景。

==== 结构体的嵌套与组合

结构体的成员可以是另一个结构体，这使得我们能够构建层次化的数据结构。例如，可以先定义一个表示三维坐标的结构体，再在目标结构体中使用它：

```cpp
struct Point3D {
    double x;
    double y;
    double z;
};

struct Target {
    Point3D position;
    Point3D velocity;
    int color;
    double confidence;
    long long timestamp;
};
```

访问嵌套成员时，连续使用点运算符：

```cpp
Target enemy{};
enemy.position.x = 1000.0;
enemy.position.y = 500.0;
enemy.position.z = 200.0;
enemy.velocity.x = 10.0;
enemy.velocity.y = -5.0;
enemy.velocity.z = 0.0;

std::cout << "位置: (" << enemy.position.x << ", " 
          << enemy.position.y << ", " << enemy.position.z << ")" << std::endl;
```

初始化嵌套结构体时，使用嵌套的花括号：

```cpp
Target enemy = {
    {1000.0, 500.0, 200.0},   // position
    {10.0, -5.0, 0.0},        // velocity
    1,                         // color
    0.95,                      // confidence
    1703491200000              // timestamp
};
```

这种组合方式使得数据结构更加模块化。`Point3D` 可以在多处复用，而不必在每个需要三维坐标的地方重复定义三个浮点数。

结构体还可以包含数组作为成员，这在表示固定大小的数据集合时很有用：

```cpp
struct RobotState {
    double jointAngles[6]{};     // 六个关节的角度
    double motorCurrents[4]{};   // 四个电机的电流
    bool sensorStatus[8]{};      // 八个传感器的状态
    long long timestamp = 0;
};
```

==== 结构体的比较与赋值

结构体支持整体赋值——将一个结构体变量的所有成员复制到另一个同类型的变量：

```cpp
Target t1 = {1000.0, 500.0, 200.0, 1, 0.95, 0};
Target t2;

t2 = t1;  // 复制所有成员

t2.x = 2000.0;  // 修改 t2 不影响 t1
std::cout << t1.x << std::endl;  // 仍然是 1000.0
```

这种赋值是成员逐一复制（memberwise copy），对于包含指针的结构体需要特别注意——复制的是指针值而非指针指向的数据，这可能导致两个结构体共享同一块动态内存（浅拷贝问题，将在后续章节详细讨论）。

在 C++20 之前，自定义结构体不会自动得到 `==`；需要写出比较语义，或在后面的运算符重载章节定义它。下面比较的是每个字段当前保存的值是否完全一致：

```cpp
// 不能直接比较
// if (t1 == t2) { }  // 错误！

// 需要逐个成员比较
bool haveSameStoredValues(const Target& a, const Target& b) {
    return a.x == b.x && a.y == b.y && a.z == b.z &&
           a.color == b.color && a.confidence == b.confidence &&
           a.timestamp == b.timestamp;
}
```

C++20 可以在类型内将相等运算符写成 `bool operator==(const Target&) const = default;`，让编译器按成员生成比较。无论手写还是默认生成，浮点成员的 `==` 都是精确比较；判断两个测量目标是否“足够接近”需要另写带单位和容差的领域函数，不能把两种语义混在一起。

==== 结构体的内存布局

结构体对象不仅包含成员，还可能包含为了满足 ABI 对齐规则而加入的填充字节（padding）。对普通同访问级别的非零大小数据成员，地址顺序跟随声明顺序，但相邻成员不保证紧贴，结构体末尾也可能有填充，从而让结构体数组中的下一个元素正确对齐。

具体对齐由目标平台 ABI 和类型决定。例如，一种常见 ABI 让 4 字节 `int` 按 4 字节边界对齐。为了满足成员与整个对象的对齐，编译器可能采用如下布局：

```cpp
struct Example1 {
    char a;     // 1 字节
    int b;      // 4 字节，但需要 4 字节对齐
    char c;     // 1 字节
};

// 内存布局可能是：
// a (1) + padding (3) + b (4) + c (1) + padding (3) = 12 字节
std::cout << sizeof(Example1) << std::endl;  // 可能输出 12，而非 6
```

在这套假设下，把相同对齐需求的成员放在一起可以减少填充：

```cpp
struct Example2 {
    int b;      // 4 字节
    char a;     // 1 字节
    char c;     // 1 字节
};

// 一种可能布局：b (4) + a (1) + c (1) + padding (2) = 8 字节
std::cout << sizeof(Example2) << std::endl;  // 可能输出 8
```

调整成员顺序是否值得做，要结合对象数量、缓存行为和可读性测量，不能只看单个 `sizeof`。更重要的是，不要把内存中的结构体字节直接当作通信协议：双方还可能在填充、字节序、浮点表示、编译器 ABI 和版本上不同。协议层应按字段显式序列化，使用 `std::uint32_t` 等定宽类型表达位数，并分别规定字节序与有效范围。`#pragma pack` 是编译器相关工具，可能带来未对齐访问，也不能单独解决这些差异。

==== 从公开数据到受控类型

`struct` 的成员默认公开，这很适合没有复杂不变量的简单数据记录。但若字段之间必须始终满足约束，任意调用者直接写成员就容易绕过检查：

```cpp
Target t;
t.confidence = 2.0;  // 置信度应该在 0-1 之间，但没有任何检查
t.x = -99999.0;      // 可能是无效坐标，但无法阻止
```

操作既可以写成普通函数，也可以直接写成 `struct` 的成员函数。普通函数适合对称处理多个类型或不需要访问内部表示的算法；成员函数则能把维护不变量的操作放到类型接口里。下面这种数据与自由函数分离的设计是合法选择，并非 `struct` 的语言限制：

```cpp
// 数据
struct Target {
    double x, y, z;
    double confidence;
};

// 操作数据的函数（与结构体分离）
double distanceToTarget(const Target& t) {
    return std::hypot(t.x, t.y, t.z);
}

void updateConfidence(Target& t, double factor) {
    t.confidence *= factor;
}
```

当类型需要阻止 `confidence = 2.0` 之类的状态时，可以把表示细节设为 `private`，只开放经过校验的构造与更新操作。`struct` 也能声明 `private`、成员函数、构造函数、析构函数和继承；`class` 同样能公开全部成员。两者的语言差异主要是成员和基类的默认访问权限：`struct` 默认为 `public`，`class` 默认为 `private`。项目通常用 `struct` 表达透明数据，用 `class` 强调封装，这是一项约定而非能力边界。

下一节采用 `class` 来讲访问控制、成员函数和 `this`。重点不是从“过程式”切换到唯一正确的“面向对象”风格，而是学会在需要维护状态约束时，把数据与负责维护它的操作放进一个清楚的接口。


=== 类与对象
// class 定义
// 成员变量与成员函数
// 访问控制（public/private/protected）
// this 指针
// === 类与对象

上一节已经说明，`struct` 与 `class` 都能拥有数据、成员函数和访问控制。这里改用 `class`，是为了突出一种常见设计：把表示细节藏在私有区，只让外部通过少量操作维护对象的不变量。封装不是给字段机械地套上 getter 和 setter，而是先决定哪些状态必须受保护，再设计不容易把对象带入无效状态的接口。

==== 从结构体到类

让我们从一个具体的例子开始。假设要表示 RoboMaster 比赛中的电机，使用结构体可能是这样：

```cpp
struct Motor {
    int id;
    double speed;        // 当前转速 RPM
    double targetSpeed;  // 目标转速
    double temperature;  // 温度
};

// 操作电机的函数
void setTargetSpeed(Motor& m, double speed) {
    m.targetSpeed = speed;
}

double getSpeedError(const Motor& m) {
    return m.targetSpeed - m.speed;
}

bool isOverheated(const Motor& m) {
    return m.temperature > 80.0;
}
```

自由函数本身没有问题，把它们放进同一命名空间也能形成清楚的接口。这个 `Motor` 真正缺少的是写入约束：任何调用者都能改掉硬件反馈字段。若项目希望只让指定操作更新状态，就可以把这些字段设为私有，并把紧密依赖内部表示的操作设为成员函数。

使用类可以将数据和操作封装在一起：

```cpp
class Motor {
public:
    void setTargetSpeed(double speed) {
        targetSpeed = speed;
    }
    
    double getSpeedError() const {
        return targetSpeed - speed;
    }
    
    bool isOverheated() const {
        return temperature > 80.0;
    }

private:
    int id = 0;
    double speed = 0.0;
    double targetSpeed = 0.0;
    double temperature = 0.0;
};
```

现在三个操作都能直接访问 `Motor` 的表示，而外部不能绕过接口写入 `speed` 和 `temperature`。这提供了维护约束的入口；不过当前 `setTargetSpeed` 仍未校验范围，说明“字段私有”只是封装的手段，接口本身是否可靠仍要单独设计。

==== 类的定义

类使用 `class` 关键字定义，基本结构如下：

```cpp
class ClassName {
public:
    // 公开成员：外部可以访问
    
private:
    // 私有成员：只有类内部可以访问
    
protected:
    // 受保护成员：类内部和派生类可以访问
};
```

与结构体类似，类定义末尾需要分号。`public`、`private`、`protected` 是访问说明符（access specifier），用于控制成员的可见性。一个类定义中可以有多个访问说明符，它们的作用范围从当前位置延续到下一个访问说明符或类定义结束。

类的成员包括成员变量（也称为数据成员或属性）和成员函数（也称为方法）。成员变量存储对象的状态，成员函数定义对象的行为：

```cpp
class Target {
public:
    // 成员函数
    void setPosition(double newX, double newY, double newZ) {
        x = newX;
        y = newY;
        z = newZ;
    }
    
    double distanceFromOrigin() const {
        return std::hypot(x, y, z);
    }
    
    void print() const {
        std::cout << "Target at (" << x << ", " << y << ", " << z << ")" << std::endl;
    }

private:
    // 成员变量
    double x = 0.0;
    double y = 0.0;
    double z = 0.0;
    double confidence = 0.0;
};
```

类定义了一种类型及其可用操作；按这个类型创建出来的实体称为对象（有时也称实例）：

```cpp
Target t1;              // 创建一个 Target 对象
Target t2;              // 创建另一个 Target 对象
Target targets[10];     // Target 对象数组

t1.setPosition(100.0, 200.0, 50.0);
t2.setPosition(300.0, 400.0, 100.0);

std::cout << "t1 距原点: " << t1.distanceFromOrigin() << std::endl;
std::cout << "t2 距原点: " << t2.distanceFromOrigin() << std::endl;
```

每个对象都有各自的非静态数据成员，因此 `t1` 与 `t2` 的位置彼此独立。`static` 数据成员由类的对象共享，后续遇到时要与这里的普通成员区分。

==== 成员函数

成员函数是定义在类内部的函数，它可以直接访问类的所有成员（包括私有成员），无需通过参数传递。调用成员函数时使用点运算符，语法与访问成员变量相同：

```cpp
Target t;
t.setPosition(100.0, 200.0, 50.0);  // 调用成员函数
double dist = t.distanceFromOrigin();
t.print();
```

成员函数既可在类定义中给出函数体，也可只在类中声明，再到类外定义。把较长实现放进 `.cpp` 能减少头文件细节和部分重编译影响；短小函数、模板和需要内联定义的接口则常留在头文件。下面展示前一种分离方式：

```cpp
// Target.h - 头文件
class Target {
public:
    void setPosition(double newX, double newY, double newZ);
    double distanceFromOrigin() const;
    void print() const;

private:
    double x = 0.0;
    double y = 0.0;
    double z = 0.0;
};

// Target.cpp - 源文件
#include "Target.h"
#include <cmath>
#include <iostream>

void Target::setPosition(double newX, double newY, double newZ) {
    x = newX;
    y = newY;
    z = newZ;
}

double Target::distanceFromOrigin() const {
    return std::hypot(x, y, z);
}

void Target::print() const {
    std::cout << "Target at (" << x << ", " << y << ", " << z << ")" << std::endl;
}
```

在类外部定义成员函数时，需要使用作用域解析运算符 `::` 指明函数属于哪个类。`Target::setPosition` 表示“Target 类的 setPosition 函数”。

成员函数参数列表后的 `const` 会把其中的 `this` 视为指向常量对象，因此函数不能直接修改普通数据成员，也不能调用该对象的非常量成员函数。它仍可能修改外部状态或 `mutable` 成员，所以更准确的含义是“对这个对象提供 const 访问”：

```cpp
void analyzeTarget(const Target& t) {
    t.print();              // 正确，print() 是 const 成员函数
    double d = t.distanceFromOrigin();  // 正确，也是 const
    // t.setPosition(0, 0, 0);  // 错误！setPosition() 不是 const，不能通过 const 引用调用
}
```

只读查询应尽量声明为 `const`，这样常量对象和常量引用也能调用，编译器还会检查通过 `this` 发生的普通成员修改。

==== 访问控制

类和结构体都支持三种访问级别，只是默认值不同：

`public`（公开）成员可以在任何地方访问。类的公开成员构成了它的接口——外部代码通过公开成员与对象交互。通常，成员函数是公开的，它们定义了对象能够执行的操作。

`private`（私有）成员可由该类的成员和友元访问，普通外部代码不能直接访问。把需要维护约束的数据放在私有区，能阻止调用者绕过接口；对象是否始终有效，还取决于构造与每个公开操作是否守住约束。

`protected`（受保护）成员介于两者之间：类内部和派生类（子类）可以访问，但其他代码不能。这在继承体系中有用，将在后续章节详细讨论。

```cpp
#include <cstdint>

class BankAccount {
public:
    // 公开接口
    bool deposit(std::int64_t amountCents) {
        if (amountCents <= 0 || amountCents > maxBalanceCents - balanceCents) {
            return false;
        }
        balanceCents += amountCents;
        return true;
    }
    
    bool withdraw(std::int64_t amountCents) {
        if (amountCents > 0 && amountCents <= balanceCents) {
            balanceCents -= amountCents;
            return true;
        }
        return false;
    }
    
    std::int64_t getBalanceCents() const {
        return balanceCents;
    }

private:
    // 私有数据
    static constexpr std::int64_t maxBalanceCents = 1'000'000'000'000;
    std::int64_t balanceCents = 0;
    std::string accountNumber;
};
```

示例用整数分保存金额，避免把二进制浮点舍入混入账户规则。`balanceCents` 不能由外部直接写入，存取操作会检查正数、余额和上限；只要对象从这里给出的初始状态出发，并且没有其他修改路径，这些公开操作会保持余额范围。

```cpp
BankAccount account;
account.deposit(100000);      // 存入 1000.00
account.withdraw(50000);      // 取出 500.00
std::cout << account.getBalanceCents() << std::endl;  // 50000

// account.balanceCents = 1000000; // 错误！成员是私有的
```

公开接口与私有表示之间形成了一条边界。只要接口语义保持不变，内部存储就有调整空间；如果返回类型、单位或错误约定也改变，调用者当然仍需修改。因此“私有化”减少的是对表示细节的耦合，并不保证任何重构都对外无感。

当调用者确实需要查询状态或提交新目标时，可以提供与业务含义对应的查询和命令：

```cpp
#include <algorithm>
#include <cmath>

class Motor {
public:
    // Getter：获取私有成员的值
    double getSpeed() const { return speed; }
    double getTemperature() const { return temperature; }
    int getId() const { return id; }
    
    // Setter：设置私有成员的值（可以包含验证逻辑）
    bool setId(int newId) {
        if (newId > 0) {
            id = newId;
            return true;
        }
        return false;
    }
    
    void setTargetSpeed(double target) {
        // 限制目标转速在合理范围内
        if (std::isfinite(target)) {
            targetSpeed = std::clamp(target, -maxSpeed, maxSpeed);
        }
    }

private:
    int id = 0;
    double speed = 0.0;
    double targetSpeed = 0.0;
    double temperature = 0.0;
    static constexpr double maxSpeed = 10000.0;
};
```

这并不意味着每个私有字段都要配一对机械的 getter/setter。若公开写接口与直接赋值完全等价，封装并未增加多少价值。优先公开诸如“设置目标转速”这样的领域操作，并明确无效输入是拒绝、截断还是报错；上例选择忽略非有限值并截断超出范围的有限值，真实接口最好再把处理结果返回给调用者。

==== struct 与 class 的区别

在 C++ 中，`struct` 和 `class` 具备相同的主要能力。区别在于默认访问：`struct` 的成员和基类默认 `public`，`class` 则默认 `private`：

```cpp
struct Point {
    double x;  // 默认 public
    double y;
};

class Vector {
    double x;  // 默认 private
    double y;
};
```

因此，以下两个定义是等价的：

```cpp
struct A {
private:
    int data;
public:
    void func();
};

class B {
    int data;  // 默认 private
public:
    void func();
};
```

项目常用 `struct` 表示公开、透明的值类型，用 `class` 强调私有表示与受控接口。这种约定不限制成员函数数量：一个公开数据类型也可以提供便利操作。保持团队内含义一致，比把约定误说成语言能力差异更重要。

```cpp
// 使用 struct：简单数据聚合，全部公开
struct Point3D {
    double x, y, z;
};

// 使用 class：有封装需求，私有数据 + 公开接口
class Robot {
public:
    void move(double dx, double dy);
    void rotate(double angle);
    Point3D getPosition() const;
    
private:
    Point3D position{};
    double heading = 0.0;
    // ...
};
```

==== this 指针

在非静态成员函数中，`this` 指向本次调用所对应的对象。普通成员函数里的 `this` 可用于修改对象，`const` 成员函数里的 `this` 则指向 `const` 对象。

可以把 `t.print()` 概念性地理解为函数同时知道了 `&t`，但具体调用约定由 ABI 与优化器决定。在 `print` 内，未被局部名称遮蔽的成员 `x` 等价于 `this->x`。多数时候不必显式写 `this`，下面几种场景则会用到它。

第一种情况是当成员变量与参数同名时。如果不使用 `this`，参数名会遮蔽成员变量名：

```cpp
class Rectangle {
public:
    void setDimensions(double width, double height) {
        // 参数 width 遮蔽了成员变量 width
        // 直接写 width = width 没有意义
        this->width = width;
        this->height = height;
    }

private:
    double width;
    double height;
};
```

一种避免命名冲突的做法是给成员变量加前缀（如 `m_width`）或后缀（如 `width_`），这样就不需要 `this`：

```cpp
class Rectangle {
public:
    void setDimensions(double width, double height) {
        m_width = width;
        m_height = height;
    }

private:
    double m_width;
    double m_height;
};
```

第二种情况是需要返回对象自身的引用，这在实现链式调用时很常见：

```cpp
class QueryBuilder {
public:
    QueryBuilder& select(const std::string& columns) {
        query += "SELECT " + columns + " ";
        return *this;  // 返回对象自身的引用
    }
    
    QueryBuilder& from(const std::string& table) {
        query += "FROM " + table + " ";
        return *this;
    }
    
    QueryBuilder& where(const std::string& condition) {
        query += "WHERE " + condition + " ";
        return *this;
    }
    
    std::string build() const {
        return query;
    }

private:
    std::string query;
};

// 链式调用
QueryBuilder builder;
std::string sql = builder.select("*")
                         .from("targets")
                         .where("confidence > 0.9")
                         .build();
```

每个成员函数返回 `*this` 的引用，所以下一次调用仍作用于同一个构建器。流表达式 `cout << a << b` 也依赖插入运算返回流引用，虽然具体重载既可能是成员函数，也可能是非成员函数。

第三种情况是需要将对象自身传递给其他函数：

```cpp
class Observer;

class Subject {
public:
    void registerObserver(Observer& obs) {
        observers.push_back(&obs);
    }
    
    void notifyObservers();

private:
    std::vector<Observer*> observers;
};

class Observer {
public:
    virtual ~Observer() = default;

    void observe(Subject& subject) {
        subject.registerObserver(*this);  // 将自身注册到被观察对象
    }
    
    virtual void onNotify() = 0;
};
```

这里的裸指针是非拥有观察者列表，示例还省略了取消注册：`Subject` 使用这些指针时，相应 `Observer` 必须仍然存活。正式实现需要用注册句柄、显式注销或其他所有权设计保证这项生命周期约束。

`obj.func(arg)` 与 `func(&obj, arg)` 的类比有助于理解成员访问，却不是完整等价转换：成员函数还受访问控制、虚派发、cv/ref 限定等语言规则影响。把它当作心智模型即可，不要由此推断具体机器参数或性能。

==== 一个完整的例子

让我们用一个完整的例子来综合运用本节学习的概念。以下是一个简化的 PID 控制器类，它在 RoboMaster 开发中非常常见：

```cpp
#include <algorithm>
#include <cmath>
#include <stdexcept>

class PIDController {
public:
    // 设置 PID 参数
    bool setGains(double kp, double ki, double kd) {
        if (!std::isfinite(kp) || !std::isfinite(ki) || !std::isfinite(kd)) {
            return false;
        }
        this->kp = kp;
        this->ki = ki;
        this->kd = kd;
        return true;
    }
    
    // 设置输出限幅
    bool setOutputLimits(double minOutput, double maxOutput) {
        if (!std::isfinite(minOutput) || !std::isfinite(maxOutput) ||
            minOutput > maxOutput) {
            return false;
        }
        this->minOutput = minOutput;
        this->maxOutput = maxOutput;
        return true;
    }
    
    // 设置积分限幅（防止积分饱和）
    bool setIntegralLimits(double minIntegral, double maxIntegral) {
        if (!std::isfinite(minIntegral) || !std::isfinite(maxIntegral) ||
            minIntegral > maxIntegral) {
            return false;
        }
        this->minIntegral = minIntegral;
        this->maxIntegral = maxIntegral;
        return true;
    }
    
    // 计算控制输出
    double compute(double setpoint, double measurement, double dt) {
        if (!std::isfinite(setpoint) || !std::isfinite(measurement) ||
            !std::isfinite(dt) || dt <= 0.0) {
            throw std::invalid_argument("PID inputs must be finite and dt must be positive");
        }

        const double error = setpoint - measurement;
        if (!std::isfinite(error)) {
            throw std::overflow_error("PID error is not finite");
        }
        
        // 比例项
        const double pTerm = kp * error;
        
        // 先计算候选状态，确认输出有效后再提交。
        const double nextIntegral =
            std::clamp(integral + error * dt, minIntegral, maxIntegral);
        const double iTerm = ki * nextIntegral;
        
        // 微分项
        const double derivative = hasLastError ? (error - lastError) / dt : 0.0;
        const double dTerm = kd * derivative;
        
        // 计算总输出并限幅
        const double output = pTerm + iTerm + dTerm;
        if (!std::isfinite(output)) {
            throw std::overflow_error("PID output is not finite");
        }

        integral = nextIntegral;
        lastError = error;
        hasLastError = true;
        return std::clamp(output, minOutput, maxOutput);
    }
    
    // 重置控制器状态
    void reset() {
        integral = 0.0;
        lastError = 0.0;
        hasLastError = false;
    }
    
    // Getter 函数
    double getKp() const { return kp; }
    double getKi() const { return ki; }
    double getKd() const { return kd; }
    double getIntegral() const { return integral; }

private:
    // PID 增益
    double kp = 0.0;
    double ki = 0.0;
    double kd = 0.0;
    
    // 输出限幅
    double minOutput = -1e9;
    double maxOutput = 1e9;
    
    // 积分限幅
    double minIntegral = -1e9;
    double maxIntegral = 1e9;
    
    // 状态变量
    double integral = 0.0;
    double lastError = 0.0;
    bool hasLastError = false;
};
```

这个类把 `integral`、`lastError` 和“是否已有上一帧”放在内部，并让限幅设置先验证上下界，因而不会把反向区间交给 `std::clamp`。`compute` 也明确拒绝非有限输入和非正 `dt`。这里用异常展示失败路径；有硬实时约束的项目可能改用状态返回，但不能省略这项接口约定。

使用这个类：

```cpp
int main() {
    PIDController speedController;
    if (!speedController.setGains(1.5, 0.1, 0.05) ||
        !speedController.setOutputLimits(-1000.0, 1000.0) ||
        !speedController.setIntegralLimits(-500.0, 500.0)) {
        return 1;
    }
    
    double targetSpeed = 3000.0;  // 目标转速
    double currentSpeed = 0.0;    // 当前转速
    double dt = 0.001;            // 控制周期 1ms
    
    for (int i = 0; i < 1000; i++) {
        double output = speedController.compute(targetSpeed, currentSpeed, dt);
        
        // 简化的电机模型：输出直接影响速度变化
        currentSpeed += output * 0.01;
        
        if (i % 100 == 0) {
            std::cout << "Step " << i << ": speed = " << currentSpeed << std::endl;
        }
    }
    
    return 0;
}
```

循环中的“电机模型”只是为了演示对象如何被调用，并未建立真实电机、采样延迟或离散控制器的验证模型。这段运行结果不能证明这些增益适用于机器人；实际参数需要基于目标系统建模、测试，并处理输出饱和与积分抗饱和等细节。

==== 类设计的基本原则

类的划分首先看内聚性：一组状态和操作是否共同维护同一套约束。如果设备通信、控制算法和日志策略各自独立变化，把它们全塞进一个类会形成不必要的耦合；反过来，为了追求“小类”而拆出许多没有独立含义的包装也不会更清楚。

私有成员适合隐藏可能变化的表示和必须受控的状态，公开接口则应给出调用者真正需要的能力。接口需要说明单位、有效范围、失败方式和生命周期，而不是只追求函数数量少。相似操作在命名、参数顺序和错误约定上保持一致，调用者才不必每次重新猜测。

目前示例依靠默认成员初始化器得到初始状态，但很多类型需要在创建时验证参数、取得资源，并在离开作用域时释放资源。下一节通过构造函数、析构函数和 RAII 把这段完整生命周期连起来。


=== 构造函数与析构函数
// 对象的生命周期
// 构造函数重载
// 初始化列表
// 析构函数
// RAII 思想
// === 构造函数与析构函数

如果一个对象必须先连续调用三个 setter 才能使用，那么这三个调用中的任何遗漏都会留下半初始化状态。构造函数（constructor）把必要输入集中到创建过程；初始化成功后，调用者拿到的才是完整对象。析构函数（destructor）则参与对象销毁，让成员和所拥有的资源按确定顺序清理。本节从存储期讲到 RAII，同时也会说明构造失败、异常展开和进程异常终止这些边界。

==== 对象的生命周期

每个对象都有生命周期，但决定规则的是存储期和创建方式，不宜简单等同为物理上的“栈”或“堆”。

具有自动存储期的局部对象通常在程序执行到声明处时初始化，控制流离开作用域时按规则销毁；常见实现会使用调用栈保存它们：

```cpp
void processTarget() {
    Target t;  // t 在这里被创建
    t.setPosition(100, 200, 50);
    // 使用 t...
}  // t 在这里被销毁，离开作用域

int main() {
    processTarget();
    // 此时 t 已经不存在了
    return 0;
}
```

`new` 表达式创建的动态对象持续存在，直到相匹配的 `delete` 销毁。下面是需要手工配对的裸指针写法，现代代码通常把这项所有权交给智能指针：

```cpp
void dynamicExample() {
    Target* ptr = new Target();  // 创建动态对象
    ptr->setPosition(100, 200, 50);
    // 使用 ptr...
    delete ptr;  // 手动销毁对象
}
```

命名空间作用域对象通常在进入 `main` 前完成初始化，函数局部 `static` 则在控制流第一次经过声明时初始化；线程局部对象还有自己的线程存储期。它们的初始化与销毁顺序涉及跨翻译单元规则，不能统一简化成一句“启动时创建”。

当构造成功完成后，对象才正式进入可用生命周期，正常销毁时会执行相应析构过程。如果构造函数抛出异常，这个对象本身的析构函数不会运行，但已经构造完成的基类和成员会按相反顺序销毁。这条规则正是后面设计资源成员时必须考虑的边界。

==== 默认构造函数

构造函数是一种特殊的成员函数，它的名称与类名相同，没有返回类型（连 `void` 都没有）。最简单的构造函数是默认构造函数，它不接受任何参数：

```cpp
class Motor {
public:
    Motor() : id(0), speed(0.0), temperature(25.0) {
        std::cout << "Motor 对象被创建" << std::endl;
    }

private:
    int id;
    double speed;
    double temperature;
};

int main() {
    Motor m;  // 自动调用默认构造函数
    return 0;
}
```

`Motor m;` 会选择 `Motor()`。冒号后的成员初始化先执行，随后才进入构造函数体。构造函数提供了建立有效状态的机会；它是否真的守住约束，仍取决于实现是否初始化了所有成员并正确处理失败。

如果类没有声明构造函数，编译器可以隐式声明默认构造函数。它会调用基类和成员对象的默认构造，并采用默认成员初始化器；没有初始化器的标量成员在 `Point p;` 这类默认初始化中可能保持不确定值。声明了其他构造函数后，编译器不会再自动补一个无参版本：

```cpp
class Point {
public:
    Point(double x, double y) {  // 只定义了带参数的构造函数
        this->x = x;
        this->y = y;
    }

private:
    double x, y;
};

int main() {
    Point p1(1.0, 2.0);  // 正确，调用 Point(double, double)
    // Point p2;         // 错误！没有默认构造函数
    return 0;
}
```

如果希望在定义了其他构造函数的同时保留默认构造函数，可以显式声明它：

```cpp
class Point {
public:
    Point() = default;  // 显式要求编译器生成默认构造函数
    Point(double x, double y) : x(x), y(y) {}

private:
    double x = 0.0;
    double y = 0.0;
};
```

`= default` 是 C++11 引入的语法，它告诉编译器生成该函数的默认版本。

==== 带参数的构造函数

更常见的情况是构造函数需要接受参数，以便根据不同的输入创建不同状态的对象：

```cpp
class Target {
public:
    Target(double x, double y, double z, int color) {
        this->x = x;
        this->y = y;
        this->z = z;
        this->color = color;
        this->confidence = 1.0;
        this->timestamp = getCurrentTime();
    }
    
    void print() const {
        std::cout << "Target at (" << x << ", " << y << ", " << z << ")" << std::endl;
    }

private:
    double x, y, z;
    int color;
    double confidence;
    long long timestamp;
    
    long long getCurrentTime() {
        // 返回当前时间戳
        return 0;  // 简化示例
    }
};

int main() {
    Target t1(100.0, 200.0, 50.0, 1);  // 直接初始化
    Target t2 = Target(300.0, 400.0, 100.0, 2);  // 显式调用构造函数
    Target t3{500.0, 600.0, 150.0, 1};  // C++11 花括号初始化
    
    t1.print();
    t2.print();
    t3.print();
    
    return 0;
}
```

带参数的构造函数使得创建对象和初始化可以在一步完成，避免了“创建后再设置”的繁琐模式。构造函数还可以包含验证逻辑，确保对象以合法状态创建：

```cpp
#include <cmath>
#include <stdexcept>

class Motor {
public:
    Motor(int id, double maxSpeed) {
        if (id <= 0) {
            throw std::invalid_argument("电机 ID 必须为正数");
        }
        if (!std::isfinite(maxSpeed) || maxSpeed <= 0.0) {
            throw std::invalid_argument("最大转速必须是有限正数");
        }
        
        this->id = id;
        this->maxSpeed = maxSpeed;
        this->currentSpeed = 0.0;
    }

private:
    int id;
    double maxSpeed;
    double currentSpeed;
};
```

==== 构造函数重载

与普通函数一样，构造函数也可以重载——定义多个同名但参数列表不同的构造函数，为对象创建提供多种方式：

```cpp
class PIDController {
public:
    // 默认构造函数：使用默认参数
    PIDController() {
        kp = 1.0;
        ki = 0.0;
        kd = 0.0;
        reset();
    }
    
    // 只设置 P 参数
    PIDController(double kp) {
        this->kp = kp;
        this->ki = 0.0;
        this->kd = 0.0;
        reset();
    }
    
    // 设置 PID 三个参数
    PIDController(double kp, double ki, double kd) {
        this->kp = kp;
        this->ki = ki;
        this->kd = kd;
        reset();
    }
    
    void reset() {
        integral = 0.0;
        lastError = 0.0;
    }

private:
    double kp, ki, kd;
    double integral;
    double lastError;
};

int main() {
    PIDController pid1;                    // 调用默认构造函数
    PIDController pid2(2.0);               // 调用 PIDController(double)
    PIDController pid3(1.5, 0.1, 0.05);    // 调用 PIDController(double, double, double)
    
    return 0;
}
```

编译器根据调用时提供的参数自动选择匹配的构造函数版本。

这个简例只展示重载选择，暂未规定增益的有效范围。若类型不接受 NaN、无穷大或某些符号组合，每个可用构造入口都必须执行同一套验证，不能只在其中一个版本检查。

另一种实现类似效果的方法是使用默认参数：

```cpp
class PIDController {
public:
    PIDController(double kp = 1.0, double ki = 0.0, double kd = 0.0) {
        this->kp = kp;
        this->ki = ki;
        this->kd = kd;
        integral = 0.0;
        lastError = 0.0;
    }

private:
    double kp, ki, kd;
    double integral, lastError;
};

int main() {
    PIDController pid1;                 // kp=1.0, ki=0.0, kd=0.0
    PIDController pid2(2.0);            // kp=2.0, ki=0.0, kd=0.0
    PIDController pid3(1.5, 0.1);       // kp=1.5, ki=0.1, kd=0.0
    PIDController pid4(1.5, 0.1, 0.05); // kp=1.5, ki=0.1, kd=0.05
    
    return 0;
}
```

默认参数能让一个构造函数覆盖多种调用方式；重载则适合不同输入形式需要不同验证或语义的情况。两种方式混用时还要避免候选调用产生歧义，并不是默认参数越多越省事。

==== 成员初始化列表

前面有些构造函数在函数体里赋值，但成员在进入函数体前就已经完成了一轮初始化。成员初始化列表（member initializer list）直接规定那一轮初始化做什么，语义比“先默认初始化、再赋值”更准确。它位于参数列表之后、函数体之前，以冒号开头：

```cpp
class Target {
public:
    Target(double x, double y, double z, int color)
        : x(x), y(y), z(z), color(color), confidence(1.0), timestamp(0)
    {
        // 构造函数体，可以为空
    }

private:
    double x, y, z;
    int color;
    double confidence;
    long long timestamp;
};
```

初始化列表中，每个成员的初始化形式为 `成员名(初始值)`，多个成员之间用逗号分隔。这种语法与函数体内赋值有本质区别：初始化列表是真正的初始化，而函数体内是赋值。

对于基本类型，两者的效果通常相同。但对于某些情况，必须使用初始化列表：

没有默认成员初始化器的常量成员必须由构造函数初始化列表提供初值，因为进入函数体后已经只能读取：

```cpp
class Config {
public:
    Config(int maxConnections)
        : MAX_CONNECTIONS(maxConnections)  // 必须在初始化列表中
    {
        // MAX_CONNECTIONS = maxConnections;  // 错误！不能给 const 成员赋值
    }

private:
    const int MAX_CONNECTIONS;
};
```

同理，没有默认成员初始化器的引用成员必须在初始化列表中绑定：

```cpp
class Observer {
public:
    Observer(Subject& subject)
        : subject(subject)  // 引用必须在初始化列表中绑定
    {
    }

private:
    Subject& subject;
};
```

没有默认构造函数的成员对象必须在初始化列表中初始化：

```cpp
class Engine {
public:
    Engine(int power) : power(power) {}  // 没有默认构造函数
private:
    int power;
};

class Car {
public:
    Car(int enginePower)
        : engine(enginePower)  // 必须在初始化列表中初始化 engine
    {
    }

private:
    Engine engine;
};
```

即使不是必须使用初始化列表的情况，使用它也是推荐的做法。对于类类型的成员，初始化列表直接调用构造函数进行初始化，而函数体内赋值会先调用默认构造函数，再调用赋值运算符——多了一步不必要的操作：

```cpp
class ExampleAssigned {
public:
    // 两步完成：先默认构造 name，再赋值
    ExampleAssigned(const std::string& n) {
        name = n;  // 调用 string 的赋值运算符
    }

private:
    std::string name;
};

class ExampleInitialized {
public:
    // 直接用 n 构造 name
    ExampleInitialized(const std::string& n)
        : name(n)  // 调用 string 的拷贝构造函数
    {
    }

private:
    std::string name;
};
```

初始化顺序由成员在类中的声明顺序决定，而不是初始化列表的书写顺序。让两处顺序一致可以避免误读；若后一个成员的初值依赖前一个成员，这一点尤其重要：

```cpp
class Example {
public:
    Example(int val)
        : a(val), b(a + 1)  // 正确：a 先于 b 声明，所以 a 先初始化
    {
    }

private:
    int a;  // 先声明
    int b;  // 后声明
};
```

==== 委托构造函数

C++11 引入了委托构造函数（delegating constructor），允许一个构造函数调用同一类的另一个构造函数，减少代码重复：

```cpp
#include <cmath>
#include <stdexcept>

class Motor {
public:
    // 主构造函数
    Motor(int id, double maxSpeed, double gearRatio)
        : id(id), maxSpeed(maxSpeed), gearRatio(gearRatio), 
          currentSpeed(0.0), temperature(25.0)
    {
        validateParameters();
    }
    
    // 委托构造函数：使用默认齿轮比
    Motor(int id, double maxSpeed)
        : Motor(id, maxSpeed, 1.0)  // 委托给主构造函数
    {
    }
    
    // 委托构造函数：使用默认参数
    Motor(int id)
        : Motor(id, 10000.0, 1.0)  // 委托给主构造函数
    {
    }

private:
    void validateParameters() {
        if (id <= 0 || !std::isfinite(maxSpeed) || maxSpeed <= 0.0 ||
            !std::isfinite(gearRatio) || gearRatio <= 0.0) {
            throw std::invalid_argument("无效参数");
        }
    }
    
    int id;
    double maxSpeed;
    double gearRatio;
    double currentSpeed;
    double temperature;
};
```

委托构造函数在初始化列表中调用目标构造函数，调用形式与普通成员初始化类似。使用委托构造函数后，初始化逻辑集中在一个主构造函数中，其他构造函数只需要提供不同的参数组合，代码更加简洁且易于维护。

==== 析构函数

析构函数是与构造函数对应的特殊成员函数，它在对象销毁时自动调用。析构函数的名称是类名前加波浪号 `~`，没有返回类型，也不接受任何参数：

```cpp
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <string>

class Logger {
public:
    Logger(const std::string& filename) : file(filename, std::ios::app) {
        if (!file) {
            throw std::runtime_error("无法打开日志文件");
        }
        std::cout << "Logger 创建，打开文件: " << filename << std::endl;
    }
    
    ~Logger() {
        std::cout << "Logger 即将销毁" << std::endl;
    }
    
    void log(const std::string& message) {
        file << message << std::endl;
    }

private:
    std::ofstream file;
};

void processData() {
    Logger logger("app.log");  // 构造函数被调用
    logger.log("开始处理");
    logger.log("处理完成");
}  // logger 离开作用域，析构函数被调用

int main() {
    std::cout << "程序开始" << std::endl;
    processData();
    std::cout << "程序结束" << std::endl;
    return 0;
}
```

输出将是：

```
程序开始
Logger 创建，打开文件: app.log
Logger 即将销毁
程序结束
```

`Logger` 的析构函数体结束后，成员 `file` 才析构，并由 `std::ofstream` 自己关闭文件，所以这里不需要手写 `close()`。如果程序必须确认刷新或关闭是否成功，应提供可报告错误的显式操作；析构阶段通常已经没有合适方式把失败返回给调用者。

示例检查了打开是否成功，却没有逐次检查日志写入。需要可靠落盘时，还应检查流状态，并明确刷新、同步和错误报告策略；RAII 管理的是关闭时机，不等于 I/O 必然成功。

析构函数的主要职责是释放对象持有的资源。这些资源可能包括：

动态分配的内存（通过 `new` 分配的）需要在析构函数中 `delete`：

```cpp
#include <cstddef>

class DynamicArray {
public:
    DynamicArray(std::size_t size)
        : size(size), data(new int[size]{}) {}
    
    ~DynamicArray() {
        delete[] data;  // 释放动态分配的内存
    }
    
    int& operator[](std::size_t index) {
        return data[index];
    }

private:
    std::size_t size;
    int* data;
};
```

这个简化类的 `operator[]` 不检查边界，而且默认复制会复制裸指针，暂时还不是一个完整可用的容器；下方预览会展示复制问题，下一章再补齐对象语义。

文件、套接字和锁都需要成对清理，优先把它们交给已经实现 RAII 的成员类型。析构函数适合执行不抛异常的最终清理；若关闭操作本身的错误必须反馈，类还需要一个显式的 `close()` / `finish()` 接口，析构函数只能作为兜底。

析构函数不接受参数，因此不能重载。隐式生成的析构函数会依次销毁成员与基类，却不会猜测一个裸指针是否拥有资源。若类直接拥有裸资源，至少要定义相应清理；更稳妥的做法是让 `std::vector`、`std::unique_ptr`、文件流等 RAII 成员承担所有权，使外层类可以使用编译器生成的析构函数。

==== RAII 思想

RAII（Resource Acquisition Is Initialization，资源获取即初始化）把资源所有权放进对象：成功构造表示资源已经可用，对象销毁时由析构过程释放。资源不只包括内存，也包括文件描述符、锁和需要配对归还的句柄。

当控制流正常离开作用域，或异常触发栈展开时，已经构造完成的自动对象会析构，因此清理不必复制到每个返回分支。RAII 不能保证在 `_Exit`、进程被强制终止、断电等不执行正常栈展开的情况下仍运行析构函数；持久化和硬件安全还需要额外机制。

考虑一个不使用 RAII 的例子：

```cpp
#include <cstdio>

void processFile(const std::string& filename) {
    std::FILE* file = std::fopen(filename.c_str(), "r");
    if (!file) return;
    
    // 处理文件...
    if (someError) {
        std::fclose(file);  // 必须记得关闭
        return;
    }
    
    // 更多处理...
    if (anotherError) {
        std::fclose(file);  // 每个退出点都要关闭
        return;
    }
    
    std::fclose(file);  // 正常退出也要关闭
}
```

每个可能的退出点都需要记得关闭文件，容易遗漏。如果中间的代码抛出异常，文件更是无法被关闭。

使用 RAII 重写：

```cpp
#include <cstdio>
#include <stdexcept>
#include <string>

class FileHandle {
public:
    FileHandle(const std::string& filename, const char* mode)
        : file(std::fopen(filename.c_str(), mode))
    {
        if (!file) {
            throw std::runtime_error("无法打开文件");
        }
    }
    
    ~FileHandle() {
        if (file) {
            std::fclose(file);
        }
    }

    FileHandle(const FileHandle&) = delete;
    FileHandle& operator=(const FileHandle&) = delete;
    
    std::FILE* get() const { return file; }

private:
    std::FILE* file;
};

void processFile(const std::string& filename) {
    FileHandle handle(filename, "r");  // 构造函数打开文件
    
    // 处理文件...
    if (someError) {
        return;  // 不需要手动关闭，析构函数会处理
    }
    
    // 更多处理...
    if (anotherError) {
        return;  // 同样，析构函数会处理
    }
    
    // 正常退出，析构函数自动关闭文件
}
```

正常返回、提前返回以及发生栈展开的异常路径都会销毁 `handle`。类还删除了复制操作，避免两个对象同时对同一个 `FILE*` 调用 `fclose`。这段示例没有实现移动，也忽略了 `fclose` 的错误返回；生产接口是否需要显式报告关闭失败，要根据数据可靠性要求决定。

RAII 的应用无处不在：

```cpp
#include <fstream>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

// 标准库中的 RAII 示例
void examples() {
    // std::string 管理字符存储（实现可能使用小字符串优化）
    std::string text = "Hello";
    
    // std::vector 管理动态数组
    std::vector<int> numbers(100);  // 构造时分配
    // 离开作用域时自动释放
    
    // std::fstream 管理文件
    std::ofstream file("output.txt");  // 构造时打开
    file << "Hello";
    // 离开作用域时自动关闭
    
    // std::lock_guard 管理互斥锁
    std::mutex mtx;
    {
        std::lock_guard<std::mutex> lock(mtx);  // 构造时加锁
        // 临界区代码
    }  // 离开作用域时自动解锁
    
    // std::unique_ptr 管理动态分配的对象
    auto motor = std::make_unique<Motor>(1, 10000.0);
    // 离开作用域时自动 delete
}
```

在 RoboMaster 开发中，RAII 思想应用于串口连接、相机资源、线程管理等各个方面：

```cpp
#include <cstddef>
#include <cstdint>
#include <fcntl.h>
#include <stdexcept>
#include <string>
#include <unistd.h>

class SerialPort {
public:
    SerialPort(const std::string& device, int baudrate)
        : fd(::open(device.c_str(), O_RDWR | O_NOCTTY))
    {
        if (fd < 0) {
            throw std::runtime_error("无法打开串口");
        }
        try {
            configure(baudrate);
        } catch (...) {
            ::close(fd);  // 构造尚未完成，析构函数不会运行。
            fd = -1;
            throw;
        }
    }
    
    ~SerialPort() {
        if (fd >= 0) {
            ::close(fd);
        }
    }

    SerialPort(const SerialPort&) = delete;
    SerialPort& operator=(const SerialPort&) = delete;
    
    ssize_t write(const void* data, std::size_t len) {
        return ::write(fd, data, len);
    }
    
    ssize_t read(void* buffer, std::size_t len) {
        return ::read(fd, buffer, len);
    }

private:
    void configure(int baudrate);
    int fd;
};

void communicate() {
    SerialPort port("/dev/ttyUSB0", 115200);
    
    std::uint8_t command[] = {0xA5, 0x01, 0x02, 0x03};
    port.write(command, sizeof(command));
    
    std::uint8_t response[256]{};
    port.read(response, sizeof(response));
    
    // 不需要手动关闭串口
}
```

这个 POSIX 风格示例突出所有权，而不是给出完整串口库：`read` / `write` 可能只处理部分字节，也可能被信号中断；波特率映射、超时、线程并发和 `close` 错误都还未处理。`configure` 失败时显式关闭描述符，是因为对象尚未构造完成，`SerialPort` 的析构函数不会替它运行。

==== 拷贝控制预览

当我们定义了管理资源的类时，还需要考虑对象被拷贝时会发生什么。默认情况下，C++ 会逐成员复制对象，这对于持有指针的类可能导致问题：

```cpp
#include <cstddef>

class DynamicArray {
public:
    DynamicArray(std::size_t size)
        : size(size), data(new int[size]) {}
    
    ~DynamicArray() {
        delete[] data;
    }

private:
    std::size_t size;
    int* data;
};

void problematic() {
    DynamicArray a(10);
    DynamicArray b = a;  // 默认拷贝：b.data 指向与 a.data 相同的内存
    
}  // 问题！a 和 b 的析构函数都会 delete 同一块内存
```

默认逐成员复制让两个对象都误以为自己拥有同一个数组；作用域结束时第二次 `delete[]` 会产生未定义行为。这里的问题不是“共享”本身，而是独占资源却被复制出了两个所有者。

解决方案是定义拷贝构造函数和拷贝赋值运算符来实现深拷贝，或者禁止拷贝。这些内容将在下一节“拷贝控制”中详细讨论。

==== 构造与析构的顺序

理解构造和析构的调用顺序对于正确使用类层次结构很重要。

对于包含成员对象的类，成员按照声明顺序构造，按相反顺序析构：

```cpp
class Component {
public:
    Component(int id) : id(id) {
        std::cout << "Component " << id << " 构造" << std::endl;
    }
    ~Component() {
        std::cout << "Component " << id << " 析构" << std::endl;
    }
private:
    int id;
};

class System {
public:
    System() : c1(1), c2(2), c3(3) {
        std::cout << "System 构造" << std::endl;
    }
    ~System() {
        std::cout << "System 析构" << std::endl;
    }
private:
    Component c1;
    Component c2;
    Component c3;
};

int main() {
    System sys;
    return 0;
}
```

输出：

```
Component 1 构造
Component 2 构造
Component 3 构造
System 构造
System 析构
Component 3 析构
Component 2 析构
Component 1 析构
```

成员对象先于包含它们的对象完成构造；析构时先执行 `System` 的析构函数体，再按声明的相反顺序销毁成员。因此在 `System` 的构造函数体和析构函数体中，这三个成员都仍处于生命周期内。若构造中途抛出异常，只有已经构造完成的成员会逆序销毁。

对于数组中的对象，按索引顺序构造，按相反顺序析构：

```cpp
void arrayExample() {
    Motor motors[3] = {Motor(1), Motor(2), Motor(3)};
    // Motor(1) 先构造，Motor(3) 最后构造
}  // Motor(3) 先析构，Motor(1) 最后析构
```

==== 实践建议

编写构造函数和析构函数时，以下原则值得遵循：

优先用成员初始化列表表达初值，并让书写顺序跟随声明顺序。它首先保证语义准确，对类成员还可避免无意义的“默认构造后再赋值”。

构造成功就应建立类型承诺的有效状态。初始化失败可以抛出异常；禁用异常的环境也可以采用返回结果的工厂函数，但不要留下一个需要调用者猜测是否可用的半成品。

优先用现成 RAII 成员管理资源，这样外层类往往无需自定义析构、复制和移动。若类不得不直接拥有裸资源，就必须一起设计析构、复制和移动语义，不能只补一个 `delete`。

让资源所有权跟随对象，在正常离开作用域和栈展开路径上自动清理。析构函数通常不应抛出异常；需要报告的提交、刷新和关闭错误应由显式接口处理。

避免在构造函数和析构函数中调用虚函数。这是一个微妙的陷阱，将在多态相关章节中解释。

构造与析构把资源边界接到了对象生命周期上，但一旦对象可以复制，“谁拥有资源”就会出现新的分支。下一节从默认逐成员复制出发，判断一个类型应当深拷贝、共享、移动，还是明确禁止复制。


=== 拷贝控制
// 拷贝构造函数
// 拷贝赋值运算符
// 深拷贝 vs 浅拷贝
// === 拷贝控制

默认复制按成员各自的复制语义工作。对数值、字符串和容器，这往往正是所需行为；对一个表示独占所有权的裸指针，仅复制地址却会制造两个“所有者”。拷贝控制（copy control）的核心因此不是一律做深拷贝，而是先回答：复制这个类型应该得到独立值、共享状态，还是根本不允许？随后再让构造、赋值与析构保持一致。

==== 拷贝的发生时机

先区分几种会请求复制的语法，以及优化器可能省略复制的情况。

最直观的是用一个对象初始化另一个对象：

```cpp
Motor m1(1, 10000.0);
Motor m2 = m1;       // 拷贝初始化
Motor m3(m1);        // 直接初始化，也是拷贝
Motor m4{m1};        // 列表初始化，也是拷贝
```

函数参数按值传递时会发生拷贝：

```cpp
void process(Motor m) {  // m 是实参的拷贝
    // ...
}

Motor motor(1, 10000.0);
process(motor);  // 拷贝 motor 到参数 m
```

函数按值返回会构造返回结果，但不一定真正调用拷贝构造：命名局部变量可能触发 NRVO，未省略时还可能移动；C++17 对部分临时值场景规定了保证复制消除：

```cpp
Motor createMotor() {
    Motor m(1, 10000.0);
    return m;  // 可能 NRVO；未省略时优先考虑移动
}

Motor result = createMotor();
```

把左值插入容器通常会复制；从容器按值取出也可能复制。扩容搬迁元素时，容器会根据类型能力和异常保证选择移动或复制。若只是取得引用或迭代器，则没有因此复制元素。

因此，类型的复制语义会影响函数调用和容器使用，但不能仅从一行源码断言运行时一定发生了几次复制；需要结合标准规则、类型特殊成员和具体构建结果判断。

==== 拷贝构造函数

拷贝构造函数用同类型对象初始化新对象。它的第一个参数必须是本类类型的引用，通常写成 `const T&`；若还有其他参数，那些参数必须有默认值，调用时才能只靠一个源对象完成复制：

```cpp
class Motor {
public:
    // 普通构造函数
    Motor(int id, double maxSpeed)
        : id(id), maxSpeed(maxSpeed), currentSpeed(0.0)
    {
        std::cout << "构造 Motor " << id << std::endl;
    }
    
    // 拷贝构造函数
    Motor(const Motor& other)
        : id(other.id), maxSpeed(other.maxSpeed), currentSpeed(other.currentSpeed)
    {
        std::cout << "拷贝构造 Motor " << id << std::endl;
    }

private:
    int id;
    double maxSpeed;
    double currentSpeed;
};

int main() {
    Motor m1(1, 10000.0);  // 调用普通构造函数
    Motor m2 = m1;         // 调用拷贝构造函数
    Motor m3(m1);          // 调用拷贝构造函数
    return 0;
}
```

按值写成 `Motor(Motor other)` 不会成为一个合法的拷贝构造函数，语言直接要求第一个参数是引用。直观原因也很清楚：若为了进入“拷贝函数”先要按值复制实参，复制过程便无从启动。

在没有被其他特殊成员规则抑制或删除时，编译器会隐式声明拷贝构造函数。它依次复制基类和成员；若某个成员不可复制，外层类型的相应拷贝也可能被定义为删除。由可正确复制的值成员组成的类，通常无需手写：

```cpp
class Point {
public:
    Point(double x, double y) : x(x), y(y) {}
    // 编译器自动生成的拷贝构造函数足以正确工作

private:
    double x, y;
};

class Target {
public:
    Target(const std::string& name, Point pos)
        : name(name), position(pos) {}
    // 编译器生成的版本会正确拷贝 string 和 Point

private:
    std::string name;
    Point position;
};
```

这里 `std::string` 和 `Point` 都具有值复制语义，所以生成的 `Target` 拷贝也符合“得到独立目标值”的意图。

==== 浅拷贝的问题

裸指针逐成员复制只会复制指针值。这对非拥有观察指针可能完全正确；但下面的 `data` 表示独占动态数组，浅拷贝（shallow copy）便与所有权语义冲突：

```cpp
class DynamicArray {
public:
    DynamicArray(std::size_t size)
        : size(size), data(new int[size]{}) {
        std::cout << "构造，分配内存: " << data << std::endl;
    }
    
    ~DynamicArray() {
        std::cout << "析构，释放内存: " << data << std::endl;
        delete[] data;
    }
    
    int& operator[](std::size_t index) { return data[index]; }
    std::size_t getSize() const { return size; }

private:
    std::size_t size;
    int* data;  // 指向动态分配的内存
};

int main() {
    DynamicArray a(5);
    a[0] = 100;
    
    DynamicArray b = a;  // 浅拷贝：b.data 与 a.data 指向同一块内存
    
    std::cout << "a[0] = " << a[0] << std::endl;  // 100
    std::cout << "b[0] = " << b[0] << std::endl;  // 100
    
    b[0] = 200;  // 修改 b 也会影响 a
    std::cout << "a[0] = " << a[0] << std::endl;  // 200！
    
    return 0;
}  // 未定义行为：a 和 b 都会 delete[] 同一个地址
```

运行到作用域结束后会发生未定义行为，常见表现包括分配器报错或进程终止，但也可能没有立刻暴露。原因依次是：

1. `b = a` 时，`b.data` 被赋值为 `a.data` 的值，两个指针指向同一块内存
2. 修改 `b[0]` 实际上修改的是 `a` 和 `b` 共享的那块内存
3. 当 `b` 被销毁时，它的析构函数释放了那块内存
4. 当 `a` 被销毁时，它的析构函数试图释放已经被释放的内存——这是未定义行为

浅拷贝的问题本质上是所有权的混乱：两个对象都认为自己拥有同一块内存，都试图管理它的生命周期。

==== 深拷贝

若这个类型要表现为可复制的值，深拷贝（deep copy）是一种方案：为目标对象申请新数组，再复制元素，让两边各自拥有资源。

```cpp
class DynamicArray {
public:
    DynamicArray(std::size_t size)
        : size(size), data(new int[size]{})
    {
        std::cout << "构造，分配内存: " << data << std::endl;
    }
    
    // 深拷贝的拷贝构造函数
    DynamicArray(const DynamicArray& other)
        : size(other.size), data(new int[other.size])  // 分配新内存
    {
        std::copy_n(other.data, size, data);  // 复制数据
        std::cout << "拷贝构造，分配新内存: " << data << std::endl;
    }
    
    ~DynamicArray() {
        std::cout << "析构，释放内存: " << data << std::endl;
        delete[] data;
    }
    
    int& operator[](std::size_t index) { return data[index]; }
    std::size_t getSize() const { return size; }

private:
    std::size_t size;
    int* data;
};

int main() {
    DynamicArray a(5);
    a[0] = 100;
    
    DynamicArray b = a;  // 深拷贝：b 拥有自己的内存
    
    std::cout << "a[0] = " << a[0] << std::endl;  // 100
    std::cout << "b[0] = " << b[0] << std::endl;  // 100
    
    b[0] = 200;  // 修改 b 不影响 a
    std::cout << "a[0] = " << a[0] << std::endl;  // 100，不变
    std::cout << "b[0] = " << b[0] << std::endl;  // 200
    
    return 0;
}  // 正常：a 和 b 各自释放自己的内存
```

现在每个 `DynamicArray` 对象都拥有自己独立的内存块，修改一个不会影响另一个，销毁时也各自释放自己的资源，不会产生冲突。

==== 拷贝赋值运算符

拷贝构造函数处理的是用已有对象初始化新对象的情况。但还有另一种拷贝场景：将一个已存在的对象赋值给另一个已存在的对象。这由拷贝赋值运算符（copy assignment operator）处理：

```cpp
DynamicArray a(5);
DynamicArray b(10);

b = a;  // 赋值，不是初始化！b 已经存在
```

拷贝赋值运算符是 `operator=` 的重载，它接受同类型的常量引用作为参数，返回对象自身的引用（以支持链式赋值）：

```cpp
class DynamicArray {
public:
    // ... 构造函数和拷贝构造函数 ...
    
    // 拷贝赋值运算符
    DynamicArray& operator=(const DynamicArray& other) {
        std::cout << "拷贝赋值" << std::endl;
        
        if (this == &other) {  // 自赋值检查
            return *this;
        }
        
        // 释放当前资源
        delete[] data;
        
        // 分配新资源并复制
        size = other.size;
        data = new int[size];
        std::copy(other.data, other.data + size, data);
        
        return *this;
    }
    
    // ... 其他成员 ...
};
```

拷贝赋值面对的是已经存在、可能持有资源的目标对象。它需要最终替换旧状态，但“必须先释放再获取”恰恰会削弱异常安全；更好的顺序是先准备好新状态，成功后再提交替换。

自赋值检查（`if (this == &other)`）看似多余，但在某些情况下是必要的。考虑 `a = a` 这种情况：如果没有检查，我们会先 `delete[] data`，然后试图从已释放的 `other.data`（实际上就是刚释放的 `data`）复制数据——这显然是错误的。

上面的初版若在 `new int[size]` 处抛出，`data` 仍保存已释放地址，后续析构还会再次释放它；对象不仅“不一致”，继续销毁也会产生未定义行为。对这个 `int` 数组，可以先完成分配和复制，再提交：

```cpp
DynamicArray& operator=(const DynamicArray& other) {
    if (this == &other) {
        return *this;
    }
    
    // 先分配新资源
    int* newData = new int[other.size];
    std::copy_n(other.data, other.size, newData);
    
    // 成功后再释放旧资源
    delete[] data;
    data = newData;
    size = other.size;
    
    return *this;
}
```

若分配失败，旧资源仍完好，对象状态不变。这里是“准备后提交”，还没有真正使用交换；下一小节才是 copy-and-swap。

==== copy-and-swap 惯用法

copy-and-swap 是实现拷贝赋值运算符的一种常见方法，可以在相应前提下提供异常安全保证。它结合使用拷贝构造函数和 `swap` 函数：

```cpp
class DynamicArray {
public:
    DynamicArray(std::size_t size)
        : size(size), data(new int[size]{}) {}
    
    DynamicArray(const DynamicArray& other)
        : size(other.size), data(new int[other.size])
    {
        std::copy_n(other.data, size, data);
    }
    
    ~DynamicArray() {
        delete[] data;
    }
    
    // swap 函数：交换两个对象的内部状态
    friend void swap(DynamicArray& first, DynamicArray& second) noexcept {
        using std::swap;
        swap(first.size, second.size);
        swap(first.data, second.data);
    }
    
    // copy-and-swap 实现的赋值运算符
    DynamicArray& operator=(DynamicArray other) {  // 注意：按值传递
        swap(*this, other);
        return *this;
    }
    
    int& operator[](std::size_t index) { return data[index]; }
    std::size_t getSize() const { return size; }

private:
    std::size_t size;
    int* data;
};
```

这个实现分为三步：

对左值实参，按值参数 `other` 会先通过拷贝构造得到独立副本；如果这一步失败，函数体尚未执行，原目标不受影响。传入右值时，是否复制还会受移动构造与复制消除规则影响。

然后，我们将当前对象与这个副本交换内部状态。交换之后，`*this` 拥有了副本的资源（即新值），而 `other` 拥有了原来的资源（即旧值）。

当函数返回时，`other` 被销毁，它的析构函数释放旧资源。

在本例中，构造副本成功后 `swap` 标记为 `noexcept`，所以赋值提供强异常保证并自然处理自赋值。若成员交换可能抛出，便不能不加条件地推广这项保证。

==== 三五法则

C++ 有一条著名的经验法则，用于指导何时需要自定义拷贝控制成员。

三法则（Rule of Three）提醒我们：如果类直接管理资源，因而需要自定义析构函数、拷贝构造函数或拷贝赋值中的一个，就应审查另外两个是实现、默认还是删除，而不能任由它们碰巧生成。

这是因为需要自定义这些函数的情况通常意味着类管理着某种资源。如果析构函数需要释放资源，那么拷贝时就需要决定如何处理资源（深拷贝还是共享）；如果拷贝构造函数需要复制资源，那么赋值运算符同样需要。

C++11 加入移动构造和移动赋值后，这组审查扩展为五个特殊成员，称为五法则（Rule of Five）。这不等于每个函数都要手写；正确决定可能是 `= default`、`= delete` 或自定义实现。移动语义将在后续章节回到这里。

还有一条相关的零法则（Rule of Zero）：如果可能，设计类时应该不需要自定义任何拷贝控制成员。通过使用智能指针和标准库容器等自动管理资源的类型，可以让编译器生成的默认版本正确工作：

```cpp
// 遵循零法则的设计
class ModernArray {
public:
    ModernArray(std::size_t size)
        : data(size, 0)  // vector 自动管理内存
    {
    }
    
    // 不需要自定义析构函数、拷贝构造函数、拷贝赋值运算符
    // 编译器生成的版本会正确调用 vector 的相应函数
    
    int& operator[](std::size_t index) { return data[index]; }
    std::size_t getSize() const { return data.size(); }

private:
    std::vector<int> data;  // 让 vector 管理内存
};
```

`std::vector` 已经定义了值复制、移动和析构语义，因此生成的 `ModernArray` 特殊成员会组合这些行为。这里的 `operator[]` 仍不做边界检查；零法则减少的是资源所有权错误，并不自动验证所有接口。

==== 禁止拷贝

有些类不应被复制，例如互斥锁、独占文件句柄或其他唯一所有者。是否删除复制应由语义决定；“复制成本高”本身也可以通过显式克隆接口或调用方式解决，不必假装一次复制就是普通赋值。

C++11 之前，禁止拷贝的方法是将拷贝构造函数和拷贝赋值运算符声明为私有且不实现：

```cpp
// C++11 之前的做法
class NonCopyable {
private:
    NonCopyable(const NonCopyable&);             // 只声明，不实现
    NonCopyable& operator=(const NonCopyable&);  // 只声明，不实现
public:
    NonCopyable() {}
};
```

C++11 引入了更清晰的语法——使用 `= delete` 显式禁止函数：

```cpp
class UniqueResource {
public:
    UniqueResource() : handle(acquireResource()) {}
    ~UniqueResource() { releaseResource(handle); }
    
    // 禁止拷贝
    UniqueResource(const UniqueResource&) = delete;
    UniqueResource& operator=(const UniqueResource&) = delete;
    
    void use() { /* 使用资源 */ }

private:
    ResourceHandle handle;
};

int main() {
    UniqueResource r1;
    // UniqueResource r2 = r1;  // 编译错误：拷贝构造函数被删除
    // UniqueResource r3;
    // r3 = r1;                 // 编译错误：拷贝赋值运算符被删除
    return 0;
}
```

`= delete` 不仅适用于拷贝控制成员，还可以用于禁止任何不希望被调用的函数重载。编译器在尝试调用被删除的函数时会产生清晰的错误信息。

==== 显式默认

与 `= delete` 相对的是 `= default`，它显式要求编译器生成默认版本的特殊成员函数：

```cpp
class Example {
public:
    Example() = default;  // 显式使用默认构造函数
    Example(int value) : value(value) {}
    
    Example(const Example&) = default;             // 显式使用默认拷贝构造
    Example& operator=(const Example&) = default;  // 显式使用默认拷贝赋值
    ~Example() = default;                          // 显式使用默认析构

private:
    int value = 0;
};
```

使用 `= default` 的好处包括：

明确表达意图——告诉读者“这里使用默认行为是有意的，不是遗忘”。

即使定义了其他构造函数，也可以保留默认构造函数。

默认生成还可能保留平凡性等有用的类型性质，而手写一个行为相同的函数未必能做到。

==== 一个完整的例子

让我们用一个完整的例子来综合运用本节的知识。以下是一个简化的字符串类实现：

```cpp
#include <algorithm>
#include <cstddef>
#include <cstring>
#include <iostream>
#include <limits>
#include <stdexcept>

class MyString {
private:
    struct BufferSizeTag {};

    static std::size_t checkedLength(const char* str) {
        if (str == nullptr) {
            throw std::invalid_argument("MyString cannot be built from nullptr");
        }
        return std::strlen(str);
    }

public:
    // 默认构造函数
    MyString() : MyString(0, BufferSizeTag{}) {}
    
    // 从 C 字符串构造
    MyString(const char* str)
        : len(checkedLength(str)), data(new char[len + 1]) {
        std::copy_n(str, len + 1, data);
    }
    
    // 拷贝构造函数（深拷贝）
    MyString(const MyString& other)
        : len(other.len), data(new char[other.len + 1]) {
        std::copy_n(other.data, len + 1, data);
        std::cout << "拷贝构造: \"" << data << "\"" << std::endl;
    }
    
    // 析构函数
    ~MyString() {
        delete[] data;
    }
    
    // swap 函数
    friend void swap(MyString& first, MyString& second) noexcept {
        using std::swap;
        swap(first.len, second.len);
        swap(first.data, second.data);
    }
    
    // 拷贝赋值运算符（copy-and-swap）
    MyString& operator=(MyString other) {
        std::cout << "拷贝赋值: \"" << other.data << "\"" << std::endl;
        swap(*this, other);
        return *this;
    }
    
    // 访问接口
    std::size_t length() const { return len; }
    const char* c_str() const { return data; }
    
    char& operator[](std::size_t index) { return data[index]; }
    char operator[](std::size_t index) const { return data[index]; }
    
    // 字符串连接
    MyString operator+(const MyString& other) const {
        const std::size_t max = std::numeric_limits<std::size_t>::max();
        if (other.len >= max - len) {
            throw std::length_error("MyString concatenation is too long");
        }

        MyString result(len + other.len, BufferSizeTag{});
        std::copy_n(data, len, result.data);
        std::copy_n(other.data, other.len + 1, result.data + len);
        
        return result;
    }
    
    // 输出运算符
    friend std::ostream& operator<<(std::ostream& os, const MyString& str) {
        return os << str.data;
    }

private:
    MyString(std::size_t size, BufferSizeTag)
        : len(size), data(new char[size + 1]) {
        data[0] = '\0';
    }

    std::size_t len;
    char* data;
};

int main() {
    MyString s1("Hello");
    MyString s2(" World");
    
    std::cout << "s1: " << s1 << std::endl;
    std::cout << "s2: " << s2 << std::endl;
    
    MyString s3 = s1;  // 拷贝构造
    std::cout << "s3: " << s3 << std::endl;
    
    MyString s4;
    s4 = s1 + s2;  // 赋值
    std::cout << "s4: " << s4 << std::endl;
    
    s1[0] = 'h';
    std::cout << "修改后 s1: " << s1 << std::endl;
    std::cout << "s3 不变: " << s3 << std::endl;  // 深拷贝，s1 的修改不影响 s3
    
    return 0;
}
```

这个教学实现展示了：

深拷贝的拷贝构造函数，确保每个对象拥有独立的数据副本。

使用 copy-and-swap 惯用法的拷贝赋值运算符，既简洁又异常安全。

析构函数与被删除的缓冲区所有权相匹配。

三法则中的三个函数共同维持独占缓冲区语义。构造函数还拒绝空 C 指针，连接操作先检查长度溢出，再一次性构造结果缓冲区，避免“先删除默认缓冲区、分配失败后再次释放”的异常路径。

它仍不是 `std::string` 的替代品：`operator[]` 不检查边界，没有迭代器、编码语义、分配器或移动操作，最大可分配长度也可能远小于 `size_t` 上限。这个范围内的代码用于解释复制所有权，正式项目应直接使用标准字符串。

==== 实践建议

编写拷贝控制成员时，以下原则值得遵循：

优先使用零法则。如果可能，使用 `std::string`、`std::vector`、智能指针等标准库类型来管理资源，让编译器生成的默认函数正确工作。这是最简单也最不容易出错的方式。

如果必须管理资源，遵循三/五法则。自定义析构函数、拷贝构造函数和拷贝赋值运算符（C++11 后还包括移动操作），确保它们协调一致。

copy-and-swap 适合能无异常交换、且可接受临时副本成本的值类型；在这些条件下它能自然处理自赋值并提供强异常保证。其他类型也可以用更直接的复用缓冲区或成员赋值实现，不能把惯用法机械套用到所有类。

对于不应拷贝的类，显式删除拷贝操作。使用 `= delete` 明确表达意图，让编译器帮助捕获错误使用。

测试拷贝行为。编写测试用例验证拷贝后的对象与原对象独立、修改一个不影响另一个、两个对象都能正确析构。

拷贝控制确定“复制一个值”究竟意味着什么。移动语义会进一步表达所有权转移，但在本章编排中，我们先完成继承与多态这条类型关系主线，随后在智能指针之后回到移动构造和移动赋值；届时会把这里的五法则补完整。


=== 类的继承
// 继承语法
// 访问控制
// 构造与析构顺序
// === 类的继承

公开继承（public inheritance）建立一种类型关系：派生对象可以在要求基类的接口中使用，并且仍应满足基类对调用者作出的承诺。它也能复用实现，但“代码看起来相似”并不足以证明继承合理；若替换后会破坏语义，组合往往更合适。本节先讲基类子对象、访问和构造顺序，再用对象切片与替换原则划清边界，为下一节运行时多态做准备。

==== 继承的基本概念

假设我们正在开发 RoboMaster 机器人的控制系统，需要处理不同类型的机器人：步兵、英雄、工程、哨兵等。这些机器人有很多共同的特性——都有底盘、都能移动、都有血量——但也有各自独特的能力。如果为每种机器人都从头编写一个类，会有大量重复代码。

如果这些机器人确实共享同一组外部承诺，可以把共同接口放进基类（base class），再由具体类型派生（derive）。下面先用血量操作演示语法；生产模型还要根据赛事规则决定不同兵种是否真的能由同一接口完整替换。

```cpp
// 基类：通用机器人
class Robot {
public:
    Robot(int id, int maxHealth)
        : id(id), health(maxHealth), maxHealth(maxHealth)
    {
        if (id <= 0 || maxHealth <= 0) {
            throw std::invalid_argument("robot id and max health must be positive");
        }
    }

    virtual ~Robot() = default;
    
    void takeDamage(int damage) {
        if (damage > 0) {
            health = damage >= health ? 0 : health - damage;
        }
    }
    
    void heal(int amount) {
        if (amount > 0) {
            const int missing = maxHealth - health;
            health += amount >= missing ? missing : amount;
        }
    }
    
    bool isAlive() const {
        return health > 0;
    }
    
    int getHealth() const { return health; }
    int getId() const { return id; }

private:
    int id;
    int health;
    int maxHealth;
};

// 派生类：步兵机器人
class Infantry : public Robot {
public:
    Infantry(int id)
        : Robot(id, 500)  // 调用基类构造函数，步兵血量 500
    {
    }
    
    void shoot() {
        std::cout << "步兵 " << getId() << " 发射弹丸" << std::endl;
    }
};

// 派生类：英雄机器人
class Hero : public Robot {
public:
    Hero(int id)
        : Robot(id, 600)  // 英雄血量 600
    {
    }
    
    void shootLarge() {
        std::cout << "英雄 " << getId() << " 发射大弹丸" << std::endl;
    }
};
```

每个 `Infantry` 和 `Hero` 对象都包含一个 `Robot` 基类子对象，并增加自己的接口。基类的私有数据仍存在，但派生类不能直接访问，所以 `shoot()` 通过公开的 `getId()` 查询。`Robot` 提前声明虚析构函数，是为了让后面通过 `std::unique_ptr<Robot>` 销毁派生对象时行为正确；虚函数机制会在下一节展开。

使用这些类：

```cpp
int main() {
    Infantry infantry(1);
    Hero hero(2);
    
    // 派生类对象可以使用基类的成员函数
    infantry.takeDamage(100);
    hero.takeDamage(150);
    
    std::cout << "步兵血量: " << infantry.getHealth() << std::endl;  // 400
    std::cout << "英雄血量: " << hero.getHealth() << std::endl;      // 450
    
    // 派生类对象可以使用自己的成员函数
    infantry.shoot();
    hero.shootLarge();
    
    return 0;
}
```

公开继承让这两个派生对象可以隐式转换为 `Robot` 引用或指针。能转换只是类型系统提供的能力；设计上是否合理，还要看所有基类操作对派生对象是否保持相同含义。

==== 继承的语法

派生类的定义语法如下：

```cpp
class 派生类名 : 访问说明符 基类名 {
    // 派生类成员
};
```

访问说明符可以是 `public`、`protected` 或 `private`，它决定了基类成员在派生类中的访问权限。最常用的是 `public` 继承，它保持基类成员的原有访问级别：

```cpp
class Infantry : public Robot {
    // Robot 的 public 成员在 Infantry 中仍是 public
    // Robot 的 protected 成员在 Infantry 中仍是 protected
    // Robot 的 private 成员在 Infantry 中不可直接访问
};
```

`protected` 继承会把基类的 `public` 接口降为 `protected`，`private` 继承则把基类的 `public` 与 `protected` 成员都作为派生类的私有实现使用。它们不向普通调用者表达可替换关系，实际设计中常可用组合获得更直观的所有权与接口。

C++ 支持多重继承——一个类可以从多个基类派生：

```cpp
class FlyingRobot : public Robot, public Flyable {
    // 同时继承 Robot 和 Flyable 的特性
};
```

多重继承可以组合多个接口，也会带来名称冲突、重复基类与菱形结构等额外规则。本节只讨论单继承；是否采用多重继承应由清楚的接口关系决定，而不是笼统地按“强大”或“危险”分类。

==== 访问控制与继承

理解继承中的访问控制对于正确设计类层次结构至关重要。C++ 的三个访问级别在继承中有不同的表现：

`public` 成员对所有代码可见。基类的公开成员在派生类中仍然是公开的，外部代码可以通过派生类对象访问这些成员。

`private` 成员可由定义它的类及友元访问。派生类不能直接访问基类私有成员，只能通过基类提供的公开或受保护接口操作它们。

`protected` 成员介于两者之间。它对外部代码不可见（像 `private`），但对派生类可见（不像 `private`）。`protected` 专为继承设计，用于那些需要在派生类中访问但不想暴露给外部的成员。

```cpp
class Base {
public:
    int publicData;
    void publicFunc() {}
    
protected:
    int protectedData;
    void protectedFunc() {}
    
private:
    int privateData;
    void privateFunc() {}
};

class Derived : public Base {
public:
    void accessBaseMembers() {
        publicData = 1;       // 正确，public 成员可访问
        publicFunc();         // 正确
        
        protectedData = 2;    // 正确，protected 成员对派生类可访问
        protectedFunc();      // 正确
        
        // privateData = 3;   // 错误！private 成员不可访问
        // privateFunc();     // 错误！
    }
};

int main() {
    Derived d;
    d.publicData = 1;     // 正确，public 成员
    d.publicFunc();       // 正确
    
    // d.protectedData = 2;  // 错误！protected 对外部不可见
    // d.privateData = 3;    // 错误！private 对外部不可见
    
    return 0;
}
```

在设计类层次时，需要仔细考虑每个成员的访问级别。一般原则是：

数据成员通常先设为 `private`，让基类自己维护不变量。派生类确实需要扩展点时，优先提供语义明确的 `protected` 函数；直接暴露 `protected` 数据会让所有派生类依赖表示并绕过检查。

对外接口设为 `public`。这些是类的使用者（包括派生类对象的使用者）可以调用的方法。

供派生类扩展或修改的方法设为 `protected` 或 `public`。这取决于是否也想让外部代码调用。

前面的 `Robot` 因此把三个数据成员保持为 `private`，派生类通过 `getId()` 和公开的血量操作使用基类能力。这样将来改变血量表示或加入检查时，不必逐个修补派生类的直接写入。

==== 派生类的构造函数

派生类对象包含从基类继承的成员和派生类自己定义的成员。构造派生类对象时，这些成员都需要被初始化。C++ 的规则是：先构造基类部分，再构造派生类部分。

派生类构造函数通过成员初始化列表调用基类构造函数：

```cpp
class Robot {
public:
    Robot(int id, int maxHealth)
        : id(id), health(maxHealth), maxHealth(maxHealth)
    {
        std::cout << "Robot 构造: id=" << id << std::endl;
    }

protected:
    int id;
    int health;
    int maxHealth;
};

class Infantry : public Robot {
public:
    Infantry(int id, int ammo)
        : Robot(id, 500),  // 先调用基类构造函数
          ammoCount(ammo)  // 再初始化派生类成员
    {
        std::cout << "Infantry 构造: ammo=" << ammoCount << std::endl;
    }

private:
    int ammoCount;
};

int main() {
    Infantry infantry(1, 100);
    return 0;
}
```

输出：

```
Robot 构造: id=1
Infantry 构造: ammo=100
```

基类子对象必须在进入派生类构造函数体前完成初始化。派生类初始化列表若未指定基类，编译器会尝试默认初始化它；没有可用默认构造函数时，派生构造函数就是错误的。在函数体里写 `Base(x);` 只会创建一个短命的临时对象，不能回头初始化已经错过的基类子对象：

```cpp
class Base {
public:
    Base(int x) : value(x) {}  // 只有带参数的构造函数，没有默认构造函数
private:
    int value;
};

class Derived : public Base {
public:
    // Derived() {}  // 错误：Base 没有默认构造函数
    
    Derived(int x) : Base(x) {}  // 正确，显式调用 Base(int)
};
```

派生类构造函数可以接受额外的参数，用于初始化派生类特有的成员，同时将必要的参数传递给基类构造函数：

```cpp
class Engineer : public Robot {
public:
    Engineer(int id, int maxHealth, int repairRate)
        : Robot(id, maxHealth),    // 传递给基类
          repairRate(repairRate)   // 初始化派生类成员
    {
    }
    
    void repairAlly(Robot& ally) {
        ally.heal(repairRate);
        std::cout << "工程机器人修理了友军" << std::endl;
    }

private:
    int repairRate;
};
```

==== 析构函数与继承

与构造顺序相反，析构时先执行派生类析构函数，再执行基类析构函数。这个顺序确保了在派生类析构函数执行期间，基类部分仍然有效：

```cpp
class Robot {
public:
    Robot(int id) : id(id) {
        std::cout << "Robot 构造: " << id << std::endl;
    }
    
    ~Robot() {
        std::cout << "Robot 析构: " << id << std::endl;
    }

protected:
    int id;
};

class Infantry : public Robot {
public:
    Infantry(int id) : Robot(id) {
        std::cout << "Infantry 构造" << std::endl;
    }
    
    ~Infantry() {
        std::cout << "Infantry 析构" << std::endl;
    }
};

int main() {
    Infantry infantry(1);
    return 0;
}
```

输出：

```
Robot 构造: 1
Infantry 构造
Infantry 析构
Robot 析构: 1
```

可以把它记成嵌套所有权的逆序清理：只有基类先建立好，派生部分才能构造；销毁时先撤掉最外层派生部分，最后才销毁它依赖的基类部分。

派生类的析构函数会自动调用基类的析构函数，不需要（也不应该）显式调用。如果派生类管理了资源，只需在派生类析构函数中释放派生类自己的资源，基类的资源由基类析构函数负责：

```cpp
#include <vector>

class ResourceHolder : public Robot {
public:
    ResourceHolder(int id) : Robot(id), buffer(1024) {
        std::cout << "分配缓冲区" << std::endl;
    }
    
    ~ResourceHolder() {
        std::cout << "ResourceHolder 析构函数体" << std::endl;
        // 随后 buffer 自动析构，再调用 Robot 析构函数。
    }

private:
    std::vector<char> buffer;
};
```

如果对象会通过基类指针被 `delete`，基类需要虚析构函数；另一种设计是使用受保护的非虚析构，明确禁止这种删除方式。并非“只要能被继承就一律 virtual”，关键在预期的销毁接口。下一节会完整说明。

==== 在派生类中访问基类成员

派生类可以直接访问基类的 `public` 和 `protected` 成员，就像它们是派生类自己的成员一样。但有时需要明确指定访问的是基类的成员，特别是当派生类定义了同名成员时。

使用作用域解析运算符 `::` 可以明确指定访问基类成员：

```cpp
class Base {
public:
    void print() {
        std::cout << "Base::print()" << std::endl;
    }
    
protected:
    int value = 10;
};

class Derived : public Base {
public:
    void print() {  // 隐藏了基类的 print()
        std::cout << "Derived::print()" << std::endl;
    }
    
    void printBoth() {
        print();        // 调用 Derived::print()
        Base::print();  // 明确调用 Base::print()
    }
    
    void showValues() {
        int value = 20;  // 局部变量，隐藏了成员
        std::cout << "局部 value: " << value << std::endl;         // 20
        std::cout << "成员 value: " << this->value << std::endl;   // 10（继承自 Base）
        std::cout << "Base::value: " << Base::value << std::endl;  // 10
    }
};
```

当派生类定义了与基类同名的成员（函数或变量）时，基类成员被“隐藏”（hidden）。这与后面要介绍的“覆盖”（override）不同——隐藏是名称查找层面的概念，覆盖是多态行为层面的概念。

==== 派生类与基类的类型关系

继承建立的“是一种”关系在类型系统中有重要体现：派生类对象可以被当作基类对象使用。具体来说，可以将派生类对象绑定到基类引用，或将派生类对象的地址赋给基类指针：

```cpp
void displayHealth(const Robot& robot) {
    std::cout << "血量: " << robot.getHealth() << std::endl;
}

int main() {
    Infantry infantry(1);
    Hero hero(2);
    
    displayHealth(infantry);  // 正确，Infantry 是 Robot
    displayHealth(hero);      // 正确，Hero 是 Robot
    
    Robot* robotPtr = &infantry;  // 基类指针指向派生类对象
    robotPtr->takeDamage(50);     // 通过基类指针调用基类成员
    
    Robot& robotRef = hero;       // 基类引用绑定到派生类对象
    robotRef.heal(100);           // 通过基类引用调用基类成员
    
    return 0;
}
```

这种向上转型（upcasting）由语言在公开、无歧义且可访问的基类关系下提供，结果指向或绑定到派生对象中的 `Robot` 基类子对象。通过该表达式能查找到哪些成员，由它的静态基类类型决定：

```cpp
Robot* ptr = &infantry;
ptr->takeDamage(50);   // 正确，takeDamage 是 Robot 的成员
// ptr->shoot();       // 错误！Robot 没有 shoot() 方法
```

反向的转换——将基类对象当作派生类对象——称为向下转型（downcasting），这通常是不安全的，需要使用特殊的转型操作符，将在后续章节讨论。

==== 对象切片

用派生对象初始化一个独立基类对象时，只复制其中的基类子对象，这称为对象切片（object slicing）。源派生对象没有被修改，但新对象不再包含派生部分：

```cpp
Infantry infantry(1);
infantry.takeDamage(100);

Robot robot = infantry;  // 对象切片！
// robot 只有 Robot 的成员，Infantry 特有的成员丢失了
```

需要保留动态类型时，应借用原对象的基类引用/指针，或用拥有型智能指针管理它；按值基类对象只适合确实想得到一个独立基类值的场景：

```cpp
Infantry infantry(1);

Robot& ref = infantry;  // 引用，无切片
Robot* ptr = &infantry; // 指针，无切片

// ref 和 ptr 仍然指向完整的 Infantry 对象
```

在 RoboMaster 开发中，经常需要将不同类型的机器人统一管理。应该使用指针或引用的容器，而非对象容器：

```cpp
// 若目标是保留兵种信息，这个容器会切片。
std::vector<Robot> slicedRobots;
slicedRobots.push_back(Infantry(1));

// 非拥有借用：对象必须比容器中的指针活得久。
Infantry infantry(1);
Hero hero(2);
std::vector<Robot*> borrowedRobots{&infantry, &hero};

// 异构对象由容器拥有。
std::vector<std::unique_ptr<Robot>> ownedRobots;
ownedRobots.push_back(std::make_unique<Infantry>(1));
ownedRobots.push_back(std::make_unique<Hero>(2));
```

==== 继承层次的设计

设计良好的继承层次应该反映真实的“是一种”关系。如果 B 继承自 A，那么 B 应该在概念上是 A 的一种特殊情况，B 的对象可以在任何需要 A 的地方使用。这称为里氏替换原则（Liskov Substitution Principle）。

```cpp
// 良好的继承设计
class Shape {
public:
    virtual ~Shape() = default;
    virtual double area() const = 0;
};

class Rectangle : public Shape {
public:
    Rectangle(double w, double h) : width(w), height(h) {}
    double area() const override { return width * height; }
private:
    double width, height;
};

class Circle : public Shape {
public:
    Circle(double r) : radius(r) {}
    double area() const override { return 3.14159 * radius * radius; }
private:
    double radius;
};

// Rectangle 是一种 Shape，Circle 也是一种 Shape
// 可以统一处理各种形状
void printArea(const Shape& shape) {
    std::cout << "面积: " << shape.area() << std::endl;
}
```

不应该仅仅为了复用代码而使用继承。如果两个类之间的关系是“有一个”（has-a）而非“是一种”（is-a），应该使用组合而非继承：

```cpp
// 错误：Engine 不是 Robot 的一种
class Engine : public Robot { };  // 不合理

// 正确：Robot 有一个 Engine
class Robot {
private:
    Engine engine;  // 组合关系
};
```

层次深度没有统一的“三四层”硬上限，但每增加一层都会叠加可见接口、构造顺序和覆盖关系。当理解一次调用需要来回跳过多层，或派生类频繁绕开基类约束时，就应重新评估组合、策略对象或更小接口是否更清楚。

==== 一个完整的例子

让我们用一个更完整的例子来综合运用继承的各个方面：

```cpp
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>
#include <memory>

// 基类：机器人
class Robot {
public:
    Robot(int id, const std::string& name, int maxHealth)
        : id(id), name(name), health(maxHealth), maxHealth(maxHealth)
    {
        if (id <= 0 || maxHealth <= 0) {
            throw std::invalid_argument("robot id and max health must be positive");
        }
        std::cout << "创建机器人: " << name << " (ID: " << id << ")" << std::endl;
    }
    
    virtual ~Robot() {
        std::cout << "销毁机器人: " << name << std::endl;
    }
    
    void takeDamage(int damage) {
        if (damage <= 0) {
            return;
        }
        health = damage >= health ? 0 : health - damage;
        std::cout << name << " 受到 " << damage << " 点伤害，剩余血量: " << health << std::endl;
    }
    
    void heal(int amount) {
        if (amount > 0) {
            const int missing = maxHealth - health;
            health += amount >= missing ? missing : amount;
        }
    }
    
    bool isAlive() const { return health > 0; }
    int getHealth() const { return health; }
    const std::string& getName() const { return name; }
    
    virtual void performAction() {
        std::cout << name << " 待机中..." << std::endl;
    }

private:
    int id;
    std::string name;
    int health;
    int maxHealth;
};

// 派生类：步兵机器人
class Infantry : public Robot {
public:
    Infantry(int id)
        : Robot(id, "步兵-" + std::to_string(id), 500),
          ammo(300)
    {
    }
    
    void shoot() {
        if (ammo > 0) {
            --ammo;
            std::cout << getName() << " 发射弹丸 (剩余: " << ammo << ")" << std::endl;
        } else {
            std::cout << getName() << " 弹药耗尽！" << std::endl;
        }
    }
    
    bool reload(int amount) {
        if (amount <= 0 || amount > maxAmmo - ammo) {
            return false;
        }
        ammo += amount;
        std::cout << getName() << " 装填弹药，当前: " << ammo << std::endl;
        return true;
    }
    
    void performAction() override {
        shoot();
    }

private:
    static constexpr int maxAmmo = 1000;
    int ammo;
};

// 派生类：工程机器人
class Engineer : public Robot {
public:
    Engineer(int id)
        : Robot(id, "工程-" + std::to_string(id), 600),
          repairRate(50)
    {
    }
    
    void repair(Robot& target) {
        if (&target == this) {
            std::cout << getName() << " 无法修理自己" << std::endl;
            return;
        }
        const int healthBeforeRepair = target.getHealth();
        target.heal(repairRate);
        const int restoredHealth = target.getHealth() - healthBeforeRepair;
        std::cout << getName() << " 修理了 " << target.getName() 
                  << "，恢复 " << restoredHealth << " 点血量" << std::endl;
    }
    
    void performAction() override {
        std::cout << getName() << " 准备进行工程作业" << std::endl;
    }

private:
    int repairRate;
};

int main() {
    // 使用智能指针管理机器人
    std::vector<std::unique_ptr<Robot>> team;
    
    team.push_back(std::make_unique<Infantry>(1));
    team.push_back(std::make_unique<Infantry>(2));
    team.push_back(std::make_unique<Engineer>(3));
    
    std::cout << "\n--- 战斗开始 ---\n";
    
    // 通过基类指针统一操作
    for (auto& robot : team) {
        robot->performAction();
    }
    
    std::cout << "\n--- 受到攻击 ---\n";
    
    team[0]->takeDamage(200);
    team[1]->takeDamage(150);
    
    std::cout << "\n--- 工程机器人修理 ---\n";
    
    // 需要向下转型才能调用派生类特有方法
    Engineer* engineer = dynamic_cast<Engineer*>(team[2].get());
    if (engineer != nullptr) {
        engineer->repair(*team[0]);
        engineer->repair(*team[1]);
    }
    
    std::cout << "\n--- 程序结束 ---\n";
    
    return 0;
}
```

这个例子把基类接口、构造链、拥有型基类指针和虚函数放在一起。`dynamic_cast` 在这里用于演示取得工程机器人专用接口，代码先检查转换结果；若业务逻辑经常需要猜测具体派生类型，通常说明共同虚接口或对象分组还可重新设计。伤害、弹药和修理规则也只是本例明确写出的约束，并非赛事规则的完整模型。

继承建立基类与派生类的静态关系；非虚成员通过基类引用调用时按静态类型选择，而虚成员才会根据对象的动态类型派发。下一节集中解释这项机制、抽象类以及为什么通过基类所有权销毁对象需要虚析构函数。


=== 多态与虚函数
// 虚函数
// 纯虚函数与抽象类
// 虚析构函数
// 动态绑定
// === 多态与虚函数

基类引用调用非虚成员时，函数由表达式的静态类型决定；把该成员声明为 `virtual` 后，调用才会选择对象动态类型对应的最终覆盖函数。这就是本节讨论的运行时多态。它让调用者依赖一个稳定接口，同时把某项行为交给具体派生类型实现，但也引入了析构、覆盖签名、对象生命周期和间接调用成本等必须明确的规则。

==== 从问题出发

让我们先看一个没有使用虚函数的例子，理解为什么需要多态：

```cpp
class Robot {
public:
    Robot(const std::string& name) : name(name) {}
    
    void performAction() {
        std::cout << name << " 执行默认动作" << std::endl;
    }
    
protected:
    std::string name;
};

class Infantry : public Robot {
public:
    Infantry(const std::string& name) : Robot(name) {}
    
    void performAction() {  // 重新定义了 performAction
        std::cout << name << " 发射弹丸" << std::endl;
    }
};

class Engineer : public Robot {
public:
    Engineer(const std::string& name) : Robot(name) {}
    
    void performAction() {  // 重新定义了 performAction
        std::cout << name << " 进行修理" << std::endl;
    }
};

void commandRobot(Robot& robot) {
    robot.performAction();  // 调用哪个版本？
}

int main() {
    Infantry infantry("步兵1号");
    Engineer engineer("工程1号");
    
    commandRobot(infantry);  // 输出：步兵1号 执行默认动作
    commandRobot(engineer);  // 输出：工程1号 执行默认动作
    
    return 0;
}
```

尽管 `Infantry` 和 `Engineer` 都重新定义了 `performAction()`，但通过基类引用调用时，执行的始终是基类 `Robot` 的版本。这是因为编译器在编译时根据引用的静态类型（`Robot&`）决定调用哪个函数，而非根据实际对象的类型。这种绑定方式称为静态绑定或早绑定（static/early binding）。

我们真正需要的是：让 `commandRobot` 函数根据传入对象的实际类型调用相应的 `performAction()` 版本。这就是动态绑定或晚绑定（dynamic/late binding），需要通过虚函数来实现。

==== 虚函数

将基类中的成员函数声明为虚函数，只需在函数声明前加上 `virtual` 关键字：

```cpp
class Robot {
public:
    Robot(const std::string& name) : name(name) {}
    virtual ~Robot() = default;
    
    virtual void performAction() {  // 声明为虚函数
        std::cout << name << " 执行默认动作" << std::endl;
    }
    
protected:
    std::string name;
};

class Infantry : public Robot {
public:
    Infantry(const std::string& name) : Robot(name) {}
    
    void performAction() override {  // 覆盖基类虚函数
        std::cout << name << " 发射弹丸" << std::endl;
    }
};

class Engineer : public Robot {
public:
    Engineer(const std::string& name) : Robot(name) {}
    
    void performAction() override {  // 覆盖基类虚函数
        std::cout << name << " 进行修理" << std::endl;
    }
};

void commandRobot(Robot& robot) {
    robot.performAction();  // 现在会根据实际类型调用
}

int main() {
    Infantry infantry("步兵1号");
    Engineer engineer("工程1号");
    
    commandRobot(infantry);  // 输出：步兵1号 发射弹丸
    commandRobot(engineer);  // 输出：工程1号 进行修理
    
    return 0;
}
```

现在，`commandRobot` 仍只依赖 `Robot&` 接口，虚调用却会选择对象动态类型中的最终覆盖函数。同一调用点因动态类型不同而执行不同实现，这就是运行时多态。

派生类中重新定义虚函数称为覆盖（override）。`override` 关键字是 C++11 引入的，它告诉编译器这个函数意图覆盖基类的虚函数。如果基类中没有匹配的虚函数（比如函数名拼写错误或参数列表不匹配），编译器会报错，帮助我们捕获潜在的 bug：

```cpp
class Infantry : public Robot {
public:
    // 错误示例：函数名拼写错误
    void preformAction() override {  // 编译错误！基类没有 preformAction
        std::cout << "发射" << std::endl;
    }
    
    // 错误示例：参数列表不匹配
    void performAction(int times) override {  // 编译错误！签名不匹配
        std::cout << "发射 " << times << " 次" << std::endl;
    }
};
```

语言不要求写 `override`，但在覆盖点统一使用它能让编译器核对签名，避免本想覆盖却意外新增重载。

==== 动态绑定的工作原理

标准规定虚调用的可观察行为，却没有规定具体对象布局。主流 C++ ABI 通常用虚函数表（vtable）和对象中的表指针（常称 vptr）实现，因此下面可以作为理解间接派发的常见模型，而不是语言保证。

在这种实现里，多态类相关的表保存虚函数入口，对象携带能找到相应表的信息。多重继承、虚继承和优化后的布局可能比“一对象一表指针”更复杂。

概念上，通过基类指针或引用进行虚调用时会：
1. 通过对象的 vptr 找到虚函数表
2. 在虚函数表中查找要调用的函数地址
3. 调用该地址处的函数

由于不同类型的对象有不同的虚函数表，即使通过相同的基类指针访问，也会调用到各自类型对应的函数版本。

```cpp
// 概念性地展示 vtable（实际实现由编译器处理）

// Robot 的 vtable:
// [0] -> Robot::performAction()

// Infantry 的 vtable:
// [0] -> Infantry::performAction()  // 覆盖了基类版本

// Engineer 的 vtable:
// [0] -> Engineer::performAction()  // 覆盖了基类版本
```

常见实现可能增加对象布局和一次间接调用，也可能由编译器在已知动态类型时去虚拟化。指针大小、表布局、分支预测和最终成本都取决于 ABI、优化选项和调用上下文，不能固定宣称“每个对象多 8 字节”或“开销可忽略”。热点路径应以目标构建的测量为准。

虚调用需要对象具有派生动态类型且调用没有被显式限定。对一个局部 `Infantry` 对象直接调用时，语义上仍调用最终覆盖函数，只是编译器很容易知道目标并消除间接派发。对象切片后的独立 `Robot` 动态类型就是 `Robot`。构造与析构期间则有专门规则，虚派发不会越过当前正在构造或析构的类：

```cpp
Infantry infantry("步兵");

infantry.performAction();  // 动态类型已知为 Infantry，调用 Infantry 版本

Robot robot = infantry;    // 对象切片！
robot.performAction();     // 新对象的动态类型就是 Robot

Robot& ref = infantry;
ref.performAction();       // 动态绑定，调用 Infantry::performAction
```

==== 纯虚函数与抽象类

当基类只规定某项能力、却不提供可直接实例化的完整行为时，可以把虚函数声明为纯虚函数（pure virtual function），在声明末尾写 `= 0`：

```cpp
class Robot {
public:
    Robot(const std::string& name) : name(name) {}
    virtual ~Robot() = default;
    
    // 纯虚函数：具体非抽象派生类需要提供最终覆盖函数
    virtual void performAction() = 0;
    
    // 普通虚函数：有默认实现，派生类可以选择覆盖
    virtual void reportStatus() {
        std::cout << name << " 状态正常" << std::endl;
    }
    
protected:
    std::string name;
};
```

只要类仍有纯虚函数没有最终覆盖，它就是抽象类，不能直接实例化。纯虚函数在语言中甚至可以另行提供函数体，但类仍保持抽象；普通调用最终仍需要由具体派生类提供覆盖：

```cpp
int main() {
    // Robot robot("测试");  // 编译错误！Robot 是抽象类，不能实例化
    
    Infantry infantry("步兵");  // 正确，Infantry 实现了所有纯虚函数
    Robot* ptr = &infantry;     // 可以使用抽象类的指针
    ptr->performAction();       // 调用 Infantry::performAction
    
    return 0;
}
```

如果派生类没有实现基类的所有纯虚函数，那么派生类也是抽象类：

```cpp
class SpecialRobot : public Robot {
public:
    SpecialRobot(const std::string& name) : Robot(name) {}
    // 没有实现 performAction()，所以 SpecialRobot 也是抽象类
};

// SpecialRobot sr("特殊");  // 编译错误！
```

抽象类的典型用途是定义接口。在 RoboMaster 开发中，可以定义各种抽象接口：

```cpp
// 可射击接口
class Shootable {
public:
    virtual ~Shootable() = default;
    virtual void shoot() = 0;
    virtual int getAmmo() const = 0;
    virtual void reload(int amount) = 0;
};

// 可移动接口
class Movable {
public:
    virtual ~Movable() = default;
    virtual void move(double x, double y) = 0;
    virtual void stop() = 0;
    virtual double getSpeed() const = 0;
};

// 步兵机器人实现多个接口
class Infantry : public Robot, public Shootable, public Movable {
public:
    Infantry(const std::string& name) : Robot(name), ammo(300), speed(0) {}
    
    // 实现 Shootable 接口
    void shoot() override {
        if (ammo > 0) {
            --ammo;
            std::cout << name << " 开火！" << std::endl;
        }
    }
    int getAmmo() const override { return ammo; }
    void reload(int amount) override {
        if (amount > 0 && amount <= maxAmmo - ammo) {
            ammo += amount;
        }
    }
    
    // 实现 Movable 接口
    void move(double x, double y) override {
        speed = 5.0;
        std::cout << name << " 移动到 (" << x << ", " << y << ")" << std::endl;
    }
    void stop() override { speed = 0; }
    double getSpeed() const override { return speed; }
    
    // 实现 Robot 的纯虚函数
    void performAction() override { shoot(); }

private:
    static constexpr int maxAmmo = 1000;
    int ammo;
    double speed;
};
```

通过纯虚函数定义接口，可以编写不依赖具体实现的通用代码：

```cpp
void fireAll(const std::vector<Shootable*>& shooters) {
    for (auto* shooter : shooters) {
        if (shooter != nullptr) {
            shooter->shoot();
        }
    }
}

void moveSquad(const std::vector<Movable*>& units, double x, double y) {
    for (auto* unit : units) {
        if (unit != nullptr) {
            unit->move(x, y);
        }
    }
}
```

这些容器保存的是非拥有指针，函数检查了空值，却仍要求被指对象在调用期间存活。若函数或容器要延长对象寿命，就需要改用明确的拥有型接口。

==== 虚析构函数

如果通过基类指针 `delete` 一个派生对象，而基类析构函数不是虚函数，行为是未定义的。常见实现可能只表现为派生清理没有执行，但标准并不保证调用序列或仅仅发生一次资源泄漏：

```cpp
class Base {
public:
    Base() { std::cout << "Base 构造" << std::endl; }
    ~Base() { std::cout << "Base 析构" << std::endl; }  // 非虚析构函数
};

class Derived : public Base {
public:
    Derived() {
        data = new int[100];
        std::cout << "Derived 构造，分配内存" << std::endl;
    }
    ~Derived() {
        delete[] data;
        std::cout << "Derived 析构，释放内存" << std::endl;
    }
private:
    int* data;
};

int main() {
    Base* ptr = new Derived();
    delete ptr;  // 未定义行为：不要运行这种删除路径
    return 0;
}
```

不能为这段未定义行为列出“确定输出”。观察到只打印 `Base 析构` 也不能把它提升为语言规则；程序从错误的 `delete` 开始就已经失去保证。

解决方案是将基类析构函数声明为虚函数：

```cpp
class Base {
public:
    Base() { std::cout << "Base 构造" << std::endl; }
    virtual ~Base() { std::cout << "Base 析构" << std::endl; }  // 虚析构函数
};
```

现在输出变为：

```
Base 构造
Derived 构造，分配内存
Derived 析构，释放内存
Base 析构
```

此时通过 `Base*` 删除派生对象会先执行派生析构，再执行基类析构。

若基类支持通过公开基类接口销毁动态派生对象，就应提供公开虚析构函数。若它不允许这种所有权，则可以使用受保护的非虚析构来阻止外部 `delete Base*`。多态接口通常选择前者；关键是把销毁策略写进接口，而不是只看“类能否被继承”。

C++11 的 `override` 关键字也可以用于析构函数，尽管析构函数的覆盖是隐式的：

```cpp
class Base {
public:
    virtual ~Base() = default;
};

class Derived : public Base {
public:
    ~Derived() override = default;  // 显式标记覆盖
};
```

==== final 关键字

C++11 引入的 `final` 关键字可以阻止类被继承或虚函数被覆盖。

将类标记为 `final` 表示该类不能被继承：

```cpp
class ProductionRobot final : public Robot {
public:
    ProductionRobot() : Robot("量产机器人") {}
    void performAction() override {
        std::cout << "执行预设动作" << std::endl;
    }
};

// 编译错误：ProductionRobot 是 final 类，不能被继承。
// class ModifiedRobot : public ProductionRobot { };
```

将虚函数标记为 `final` 表示该函数不能在派生类中被覆盖：

```cpp
class Infantry : public Robot {
public:
    Infantry(const std::string& name) : Robot(name) {}
    
    void performAction() override final {  // 这个实现是最终的
        std::cout << name << " 发射弹丸" << std::endl;
    }
};

class EliteInfantry : public Infantry {
public:
    EliteInfantry(const std::string& name) : Infantry(name) {}
    
    // 编译错误：Infantry::performAction 已标记为 final。
    // void performAction() override { }
};
```

`final` 首先表达并检查设计边界。在某些调用点，它也可能给优化器提供去虚拟化信息；是否真的改变生成代码仍要看完整类型信息和优化结果。

==== 多态的实际应用

多态在实际开发中有广泛的应用。让我们看几个 RoboMaster 相关的例子。

第一个例子是统一的目标处理系统。不同类型的目标（装甲板、能量机关、基地）需要不同的处理方式，但可以通过统一的接口进行管理：

```cpp
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <memory>
#include <vector>

class Target {
public:
    virtual ~Target() = default;
    
    virtual void track() = 0;              // 追踪目标
    virtual double getPriority() const = 0; // 获取优先级
    virtual bool isValid() const = 0;       // 检查是否有效
    
    virtual void render(cv::Mat& frame) const = 0;  // 在图像上绘制
};

class ArmorPlate : public Target {
public:
    ArmorPlate(const cv::Rect& bbox, int color)
        : boundingBox(bbox), armorColor(color), lastSeen(0) {}
    
    void track() override {
        // 装甲板追踪算法
        std::cout << "追踪装甲板" << std::endl;
    }
    
    double getPriority() const override {
        // 根据距离、角度等计算优先级
        return 1.0 / (boundingBox.area() + 1);
    }
    
    bool isValid() const override {
        return boundingBox.area() > 100;
    }
    
    void render(cv::Mat& frame) const override {
        cv::rectangle(frame, boundingBox, cv::Scalar(0, 255, 0), 2);
    }

private:
    cv::Rect boundingBox;
    int armorColor;
    std::int64_t lastSeen;
};

class EnergyMechanism : public Target {
public:
    void track() override {
        // 能量机关追踪算法，与装甲板不同
        std::cout << "追踪能量机关" << std::endl;
    }
    
    double getPriority() const override {
        return 2.0;  // 能量机关优先级更高
    }
    
    bool isValid() const override {
        return activated;
    }
    
    void render(cv::Mat& frame) const override {
        // 绘制能量机关的特殊标记
    }

private:
    bool activated = false;
};

// 统一处理所有目标
void processTargets(std::vector<std::unique_ptr<Target>>& targets) {
    // 先移除空指针、无效目标和非有限优先级，保证后续比较有效。
    targets.erase(
        std::remove_if(targets.begin(), targets.end(),
            [](const auto& t) {
                return t == nullptr || !t->isValid() ||
                       !std::isfinite(t->getPriority());
            }),
        targets.end()
    );
    
    // 按优先级排序
    std::sort(targets.begin(), targets.end(),
        [](const auto& a, const auto& b) {
            return a->getPriority() > b->getPriority();
        });
    
    // 追踪最高优先级目标
    if (!targets.empty()) {
        targets[0]->track();
    }
}
```

这里假设 `cv::Rect` 已经过尺寸与范围校验，优先级公式也只用于演示虚接口与排序，不能由 `1 / (area + 1)` 推出真实战术优先级。实际评分还要定义单位、范围、并列规则和数据时效；排序比较器要求稳定的严格弱序，因此示例先排除了 NaN 与无穷值。

第二个例子是控制器系统。不同的控制算法（PID、模糊控制、模型预测控制）可以通过统一接口使用：

```cpp
#include <cmath>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <string>
#include <utility>

class Controller {
public:
    virtual ~Controller() = default;
    
    virtual double compute(double setpoint, double measurement, double dt) = 0;
    virtual void reset() = 0;
    virtual std::string getName() const = 0;
};

class PIDController : public Controller {
public:
    PIDController(double kp, double ki, double kd)
        : kp(kp), ki(ki), kd(kd), integral(0), lastError(0) {
        if (!std::isfinite(kp) || !std::isfinite(ki) || !std::isfinite(kd)) {
            throw std::invalid_argument("PID gains must be finite");
        }
    }
    
    double compute(double setpoint, double measurement, double dt) override {
        if (!std::isfinite(setpoint) || !std::isfinite(measurement) ||
            !std::isfinite(dt) || dt <= 0.0) {
            throw std::invalid_argument("controller inputs must be finite and dt positive");
        }
        const double error = setpoint - measurement;
        if (!std::isfinite(error)) {
            throw std::overflow_error("controller error is not finite");
        }

        const double nextIntegral = integral + error * dt;
        const double derivative = hasLastError ? (error - lastError) / dt : 0.0;
        const double output = kp * error + ki * nextIntegral + kd * derivative;
        if (!std::isfinite(nextIntegral) || !std::isfinite(output)) {
            throw std::overflow_error("controller state or output is not finite");
        }

        integral = nextIntegral;
        lastError = error;
        hasLastError = true;
        return output;
    }
    
    void reset() override {
        integral = 0;
        lastError = 0;
        hasLastError = false;
    }
    
    std::string getName() const override {
        return "PID Controller";
    }

private:
    double kp, ki, kd;
    double integral, lastError;
    bool hasLastError = false;
};

class FuzzyController : public Controller {
public:
    double compute(double setpoint, double measurement, double dt) override {
        // 模糊控制算法
        return 0;  // 简化
    }
    
    void reset() override { }
    
    std::string getName() const override {
        return "Fuzzy Controller";
    }
};

// 使用控制器的代码不需要知道具体类型
class MotorDriver {
public:
    MotorDriver(std::unique_ptr<Controller> ctrl)
        : controller(std::move(ctrl)) {
        if (controller == nullptr) {
            throw std::invalid_argument("MotorDriver requires a controller");
        }
        controller->reset();
    }
    
    void setController(std::unique_ptr<Controller> ctrl) {
        if (ctrl == nullptr) {
            throw std::invalid_argument("controller must not be null");
        }
        ctrl->reset();
        const std::string name = ctrl->getName();
        controller = std::move(ctrl);
        std::cout << "切换到 " << name << std::endl;
    }
    
    void update(double targetSpeed, double currentSpeed, double dt) {
        double output = controller->compute(targetSpeed, currentSpeed, dt);
        applyOutput(output);
    }

private:
    void applyOutput(double output) {
        // 应用控制输出到电机
    }
    
    std::unique_ptr<Controller> controller;
};
```

`MotorDriver` 只依赖 `Controller` 接口，并明确拒绝空所有权，因此可以在运行时替换实现。新增控制器通常不要求修改驱动类，但仍可能需要更新配置、工厂注册、部署和测试；“对扩展开放”不是现有系统绝对零改动的保证。这里的 PID 仍是未包含限幅与抗饱和的教学公式，模糊控制器更只是占位实现，二者都未验证为实际电机控制算法。

==== 避免常见陷阱

使用多态时需要注意一些常见的陷阱。

第一个陷阱是在构造函数或析构函数里期待派发到更外层派生类。语言有意把动态类型限制为当前正在构造或析构的类，因此下面调用 `Base::initialize()`，不会进入尚未开始构造的 `Derived` 部分：

```cpp
class Base {
public:
    Base() {
        initialize();  // 危险！总是调用 Base::initialize()
    }
    virtual void initialize() {
        std::cout << "Base 初始化" << std::endl;
    }
};

class Derived : public Base {
public:
    Derived() : Base() {}
    void initialize() override {
        std::cout << "Derived 初始化" << std::endl;
    }
};

int main() {
    Derived d;  // 输出 "Base 初始化"，而非 "Derived 初始化"
    return 0;
}
```

不要从基类构造函数依赖派生覆盖来建立对象不变量。可以让每层构造函数调用自己的非虚辅助函数，或用工厂在完整对象构造后执行确有必要且能报告失败的启动步骤；“两阶段初始化”也需要防止半初始化对象提前泄露。

第二个陷阱是销毁接口与析构函数设计不匹配。如前所述，通过非虚基类析构 `delete` 动态派生对象是未定义行为，不应只描述成一次资源泄漏。

第三个陷阱是参数类型不匹配导致隐藏而非覆盖：

```cpp
class Base {
public:
    virtual void process(int x) {
        std::cout << "Base::process(int)" << std::endl;
    }
};

class Derived : public Base {
public:
    void process(double x) {  // 注意：参数类型不同，这是隐藏，不是覆盖！
        std::cout << "Derived::process(double)" << std::endl;
    }
};

int main() {
    Derived d;
    Base* ptr = &d;
    ptr->process(42);  // 调用 Base::process(int)，不是 Derived::process(double)
    return 0;
}
```

若本意是覆盖，在函数后写 `override` 会让签名不匹配直接报错；若本意是增加重载，可以用 `using Base::process;` 把基类重载重新引入派生类作用域。

==== 性能考虑

未被去虚拟化的调用通常需要间接跳转，可能影响内联和分支预测；多态对象布局也可能增大。实际差异并不是固定的“略慢”，可从可测量的热点开始判断：

`final` 可以提供额外的类型信息，但优化器也可能通过其他全程序信息去虚拟化；是否生效要检查目标构建。

模板可以在类型编译期已知时表达静态多态，代价是代码生成、编译时间和接口暴露方式不同，并非无条件替代方案。

在热点代码中避免不必要的虚函数调用，可以将结果缓存或使用其他设计。

在改设计前先用目标平台、目标编译选项做性能分析，确认间接派发在总成本中是否重要；图像处理函数内部的计算和内存访问往往也可能占据主要时间。

运行时多态适合稳定接口下需要在运行时选择实现的场景。它能减少调用者对具体类型的分支，却不会自动保证接口稳定、扩展无需集成工作或性能足够。下一节转回值类型：通过运算符重载，让向量、坐标等自定义值在不违背运算直觉的前提下参与表达式。


=== 运算符重载
// 单独成节，内容较多
// 常用运算符重载
// 友元函数
// === 运算符重载

值类型除了有成员函数，也常参与数学表达式、比较、流输入输出和下标访问。运算符重载能把这些操作接入 C++ 语法，但只值得用于读者已经能预期含义的关系；如果一个符号需要长篇解释才能懂，命名函数往往更诚实。

考虑一个表示三维向量的类。我们当然可以定义 `add`、`subtract`、`multiply` 等成员函数来实现向量运算，但这样的代码读起来并不自然：

```cpp
Vector3D result = v1.add(v2.multiply(scalar));  // 不够直观
```

如果能像使用内置类型那样使用运算符，代码会清晰得多：

```cpp
Vector3D result = v1 + v2 * scalar;  // 直观、自然
```

C++ 的运算符重载（operator overloading）为已有运算符定义自定义类型行为，使向量等类型能参与熟悉的表达式，也让依赖 `==`、`<` 或迭代操作的泛型算法复用同一接口。它不能发明新符号，也不能改变运算符的优先级、结合方向或操作数个数。

==== 运算符重载的基本语法

运算符重载本质上是定义一个特殊名称的函数，函数名由 `operator` 关键字后跟要重载的运算符组成。例如，重载加法运算符的函数名是 `operator+`，重载等于运算符的函数名是 `operator==`。

至少一个操作数必须是类或枚举类型，不能重定义两个内置类型之间的 `int + int`。运算符可按规则写成成员或非成员函数：成员版本把左操作数作为 `*this`，非成员版本则显式接收所有操作数。

让我们从一个简单的例子开始——为三维向量类重载加法运算符：

```cpp
#include <iostream>

class Vector3D {
public:
    Vector3D(double x = 0, double y = 0, double z = 0)
        : x(x), y(y), z(z) {}
    
    // 作为成员函数重载 +
    Vector3D operator+(const Vector3D& other) const {
        return Vector3D(x + other.x, y + other.y, z + other.z);
    }
    
    double getX() const { return x; }
    double getY() const { return y; }
    double getZ() const { return z; }

private:
    double x, y, z;
};

int main() {
    Vector3D v1(1.0, 2.0, 3.0);
    Vector3D v2(4.0, 5.0, 6.0);
    
    Vector3D v3 = v1 + v2;  // 调用 v1.operator+(v2)
    
    std::cout << "v3 = (" << v3.getX() << ", " << v3.getY() << ", " << v3.getZ() << ")" << std::endl;
    // 输出：v3 = (5, 7, 9)
    
    return 0;
}
```

当编译器遇到 `v1 + v2` 时，它会将其转换为 `v1.operator+(v2)` 的函数调用。成员函数版本的 `operator+` 接受一个参数（右操作数），左操作数就是调用该函数的对象（`*this`）。

注意 `operator+` 被声明为 `const` 成员函数，因为加法运算不应该修改任何一个操作数。它返回一个新的 `Vector3D` 对象，包含运算结果。这与内置类型的加法行为一致——`a + b` 不会修改 `a` 或 `b`。

==== 算术运算符

算术运算符是最常重载的一类运算符。除了加法，我们还可以重载减法、乘法、除法等。以下是 `Vector3D` 类的完整算术运算符实现：

```cpp
#include <stdexcept>

class Vector3D {
public:
    Vector3D(double x = 0, double y = 0, double z = 0)
        : x(x), y(y), z(z) {}
    
    // 向量加法
    Vector3D operator+(const Vector3D& other) const {
        return Vector3D(x + other.x, y + other.y, z + other.z);
    }
    
    // 向量减法
    Vector3D operator-(const Vector3D& other) const {
        return Vector3D(x - other.x, y - other.y, z - other.z);
    }
    
    // 标量乘法（向量 * 标量）
    Vector3D operator*(double scalar) const {
        return Vector3D(x * scalar, y * scalar, z * scalar);
    }
    
    // 标量除法
    Vector3D operator/(double scalar) const {
        if (scalar == 0.0) {
            throw std::domain_error("cannot divide a vector by zero");
        }
        return Vector3D(x / scalar, y / scalar, z / scalar);
    }
    
    // 点积（使用 * 运算符，两个向量相乘）
    double operator*(const Vector3D& other) const {
        return x * other.x + y * other.y + z * other.z;
    }
    
    // 一元负号（取反）
    Vector3D operator-() const {
        return Vector3D(-x, -y, -z);
    }

private:
    double x, y, z;
};

int main() {
    Vector3D v1(1.0, 2.0, 3.0);
    Vector3D v2(4.0, 5.0, 6.0);
    
    Vector3D sum = v1 + v2;         // (5, 7, 9)
    Vector3D diff = v1 - v2;        // (-3, -3, -3)
    Vector3D scaled = v1 * 2.0;     // (2, 4, 6)
    Vector3D divided = v2 / 2.0;    // (2, 2.5, 3)
    double dot = v1 * v2;           // 1*4 + 2*5 + 3*6 = 32
    Vector3D negated = -v1;         // (-1, -2, -3)
    
    return 0;
}
```

注意一元负号运算符 `operator-()` 不接受参数，它作用于单个操作数（调用对象本身）。这与二元减法运算符 `operator-(const Vector3D&)` 是不同的重载。

上面的标量乘法 `v1 * 2.0` 可以工作，但 `2.0 * v1` 不会反过来查找 `Vector3D` 的成员函数。要支持交换后的写法，需要非成员运算符。示例还把向量点积也写成 `*`；有些数学库会改用 `dot(v1, v2)` 避免“缩放”和“点积”共享一个符号，选择应与项目约定一致。

==== 友元函数

非成员函数不能直接访问类的私有成员。如果运算符函数需要访问私有成员，有两种选择：通过公开的 getter 函数访问，或者将运算符函数声明为类的友元（friend）。

友元函数不是类的成员，但被授予了访问类私有成员的权限。在类定义内部使用 `friend` 关键字声明友元：

```cpp
class Vector3D {
public:
    Vector3D(double x = 0, double y = 0, double z = 0)
        : x(x), y(y), z(z) {}
    
    // 成员函数版本：向量 * 标量
    Vector3D operator*(double scalar) const {
        return Vector3D(x * scalar, y * scalar, z * scalar);
    }
    
    // 友元函数声明：标量 * 向量
    friend Vector3D operator*(double scalar, const Vector3D& v);
    
private:
    double x, y, z;
};

// 友元函数定义（在类外部）
Vector3D operator*(double scalar, const Vector3D& v) {
    return Vector3D(v.x * scalar, v.y * scalar, v.z * scalar);  // 可以访问私有成员
}

int main() {
    Vector3D v(1.0, 2.0, 3.0);
    
    Vector3D r1 = v * 2.0;    // 调用成员函数 v.operator*(2.0)
    Vector3D r2 = 2.0 * v;    // 调用友元函数 operator*(2.0, v)
    
    return 0;
}
```

友元声明可以放在类的任何访问区域（`public`、`private` 或 `protected`），访问说明符对友元声明没有影响——友元总是可以访问所有成员。

一种常见的做法是在类内部直接定义友元函数，这样可以将声明和定义放在一起：

```cpp
class Vector3D {
public:
    Vector3D(double x = 0.0, double y = 0.0, double z = 0.0)
        : x(x), y(y), z(z) {}

    // 在类内部定义友元函数
    friend Vector3D operator*(double scalar, const Vector3D& v) {
        return Vector3D(v.x * scalar, v.y * scalar, v.z * scalar);
    }

private:
    double x, y, z;
};
```

虽然这个函数定义在类的花括号内，但它仍然是非成员函数。`friend` 关键字既声明了友元关系，又允许在此处定义函数。

==== 比较运算符

加减法的含义通常比较直观，“两个对象相等”却需要先回答一个问题：这里比较的是保存下来的值，还是测量结果在某个误差范围内足够接近？这两种关系不能混为一谈。

例如，近似相等通常不具备传递性：`a` 可能接近 `b`，`b` 也接近 `c`，但 `a` 未必接近 `c`。若直接把这种关系塞进 `operator==`，依赖等价关系的容器和算法就很难推理。下面让 `==` 遵循 `double` 自身的精确比较规则，把带容差的测量语义留给名称更明确的函数：

```cpp
#include <algorithm>
#include <cmath>
#include <stdexcept>

class Vector3D {
public:
    Vector3D(double x = 0.0, double y = 0.0, double z = 0.0)
        : x(x), y(y), z(z) {}

    bool operator==(const Vector3D& other) const {
        return x == other.x && y == other.y && z == other.z;
    }

    bool operator!=(const Vector3D& other) const {
        return !(*this == other);
    }

    bool approximatelyEquals(const Vector3D& other,
                             double absTol, double relTol) const {
        if (!std::isfinite(absTol) || !std::isfinite(relTol) ||
            absTol < 0.0 || relTol < 0.0) {
            throw std::invalid_argument(
                "tolerances must be finite and nonnegative");
        }

        return close(x, other.x, absTol, relTol) &&
               close(y, other.y, absTol, relTol) &&
               close(z, other.z, absTol, relTol);
    }

private:
    static bool close(double a, double b, double absTol, double relTol) {
        if (a == b) {
            return true;  // 也处理同号无穷大和正负零
        }
        if (!std::isfinite(a) || !std::isfinite(b)) {
            return false;
        }

        const double scale = std::max(std::abs(a), std::abs(b));
        return std::abs(a - b) <= std::max(absTol, relTol * scale);
    }

    double x = 0.0, y = 0.0, z = 0.0;
};
```

绝对容差照顾接近零的数，相对容差照顾不同量级的数；具体阈值必须来自数据单位和误差预算，而不是从示例里抄一个“万能 epsilon”。是否把 `+0.0` 与 `-0.0`、NaN 或不同编码状态视为相等，也仍然是类型语义的一部分。上面的 `operator==` 只是明确选择了内置 `double` 的规则。

若对象还需要排序，`<` 等关系同样要保持自洽。下面用分数说明一种写法。为了把重点放在比较关系上，这个教学类型只接收 32 位分子和正分母；交叉相乘前提升到 64 位，因此这段代码覆盖的输入范围内不会发生有符号乘法溢出：

```cpp
#include <cstdint>
#include <stdexcept>

class Fraction {
public:
    Fraction(std::int32_t num = 0, std::int32_t den = 1)
        : numerator(num), denominator(den) {
        if (den <= 0) {
            throw std::invalid_argument("fraction denominator must be positive");
        }
    }

    bool operator==(const Fraction& other) const {
        return cross(numerator, other.denominator) ==
               cross(other.numerator, denominator);
    }

    bool operator!=(const Fraction& other) const {
        return !(*this == other);
    }

    bool operator<(const Fraction& other) const {
        return cross(numerator, other.denominator) <
               cross(other.numerator, denominator);
    }

    bool operator>(const Fraction& other) const {
        return other < *this;
    }

    bool operator<=(const Fraction& other) const {
        return !(other < *this);
    }

    bool operator>=(const Fraction& other) const {
        return !(*this < other);
    }

private:
    static std::int64_t cross(std::int32_t a, std::int32_t b) {
        return static_cast<std::int64_t>(a) *
               static_cast<std::int64_t>(b);
    }

    std::int32_t numerator;
    std::int32_t denominator;
};
```

若成员本身改成 64 位，两个交叉乘积就未必还能放进 64 位结果中。真实的有理数类型还要考虑约分、算术运算和更大的数值范围，不能仅靠“换成更宽的整数”假定溢出已经消失。

C++20 引入了三路比较运算符 `<=>`（常被称为“太空船运算符”）。对于成员都具有合适比较语义的类型，可以默认生成比较；手写 `<=>` 时，`==` 是否也要单独提供则取决于具体声明方式。若项目仍以 C++17 为基线，像上面一样从 `==` 和 `<` 推导其他关系最容易看清约束。

==== 复合赋值运算符

刚才的 `+` 会产生新值；`+=`、`-=`、`*=` 等复合赋值则明确表示“在原对象上修改”。它们通常返回左操作数的引用，这既符合内置类型的习惯，也允许 `v1 += v2 += v3` 这样从右向左执行的链式表达式：

```cpp
#include <stdexcept>

class Vector3D {
public:
    Vector3D(double x = 0.0, double y = 0.0, double z = 0.0)
        : x(x), y(y), z(z) {}

    Vector3D& operator+=(const Vector3D& other) {
        x += other.x;
        y += other.y;
        z += other.z;
        return *this;
    }

    Vector3D& operator-=(const Vector3D& other) {
        x -= other.x;
        y -= other.y;
        z -= other.z;
        return *this;
    }

    Vector3D& operator*=(double scalar) {
        x *= scalar;
        y *= scalar;
        z *= scalar;
        return *this;
    }

    Vector3D& operator/=(double scalar) {
        if (scalar == 0.0) {
            throw std::domain_error("cannot divide a vector by zero");
        }
        x /= scalar;
        y /= scalar;
        z /= scalar;
        return *this;
    }

private:
    double x, y, z;
};
```

这里主动把浮点零除定义为错误并抛出异常；内置 `double` 本身在支持 IEC 60559 浮点的常见平台上可能产生无穷大或 NaN，但自定义向量不必照搬这套策略。重要的是让 `/` 与 `/=` 采用同一个约定。

一种常见写法是让普通算术运算复用复合赋值。把左操作数按值接收，等于先得到一个结果副本，再在副本上修改：

```cpp
class Vector3D {
public:
    Vector3D(double x = 0.0, double y = 0.0, double z = 0.0)
        : x(x), y(y), z(z) {}

    Vector3D& operator+=(const Vector3D& other) {
        x += other.x;
        y += other.y;
        z += other.z;
        return *this;
    }

    Vector3D& operator-=(const Vector3D& other) {
        x -= other.x;
        y -= other.y;
        z -= other.z;
        return *this;
    }

    friend Vector3D operator+(Vector3D left, const Vector3D& right) {
        left += right;
        return left;
    }

    friend Vector3D operator-(Vector3D left, const Vector3D& right) {
        left -= right;
        return left;
    }

private:
    double x, y, z;
};
```

这样 `+` 与 `+=` 共用一份逐分量逻辑，而且非成员版本允许左右操作数按正常的重载规则参与转换。它不是所有类型的强制模板：若复制昂贵、两种操作的数值策略不同，仍应先保证语义正确，再依据测量决定实现。

==== 下标运算符

当一个类型表示一组元素，问题就从“怎样计算一个新值”转向“怎样定位其中一个值”。`operator[]` 和 `operator()` 都必须定义为成员函数；若访问结果既要可写又要支持只读对象，通常各提供一个非 `const` 与 `const` 版本。

矩阵需要行、列两个坐标。`operator()` 在各个常用 C++ 标准中都能自然接收多个实参，因此常被用来表达矩阵访问：

```cpp
#include <cstddef>
#include <limits>
#include <stdexcept>
#include <vector>

class Matrix {
public:
    Matrix(std::size_t rows, std::size_t cols)
        : rows_(rows), cols_(cols), data_(elementCount(rows, cols), 0.0) {}

    double& operator()(std::size_t row, std::size_t col) {
        return data_[offset(row, col)];
    }

    const double& operator()(std::size_t row, std::size_t col) const {
        return data_[offset(row, col)];
    }

    std::size_t rows() const noexcept { return rows_; }
    std::size_t cols() const noexcept { return cols_; }

private:
    static std::size_t elementCount(std::size_t rows, std::size_t cols) {
        if (cols != 0 && rows > std::numeric_limits<std::size_t>::max() / cols) {
            throw std::length_error("matrix dimensions are too large");
        }
        return rows * cols;
    }

    std::size_t offset(std::size_t row, std::size_t col) const {
        if (row >= rows_ || col >= cols_) {
            throw std::out_of_range("matrix index out of range");
        }
        return row * cols_ + col;
    }

    std::size_t rows_;
    std::size_t cols_;
    std::vector<double> data_;
};

int main() {
    Matrix m(3, 3);
    
    m(0, 0) = 1.0;  // 使用非 const 版本
    m(1, 1) = 1.0;
    m(2, 2) = 1.0;
    
    const Matrix& cm = m;
    double val = cm(0, 0);  // 使用 const 版本
    // cm(0, 0) = 2.0;      // 错误：const 版本返回 const 引用

    return 0;
}
```

构造函数先检查 `rows * cols` 是否能由 `std::size_t` 表示，访问时再检查两个坐标；通过检查之后，扁平索引的乘加才落在已分配范围内。这里只是演示一种异常策略，性能敏感的数值库也可能同时提供“调用者保证索引有效”的快速接口和单独的检查接口。

C++20 及更早标准的 `operator[]` 每次只接收一个实参；C++23 才加入多参数下标。因此即使新标准可以写 `matrix[row, col]`，`operator()` 仍是跨常见标准版本更稳定的写法。

一维容器则很适合沿用数组的下标习惯。下面明确区分不检查的 `operator[]` 和会检查的 `at()`：

```cpp
#include <cstddef>
#include <vector>

class DynamicArray {
public:
    explicit DynamicArray(std::size_t size) : data_(size) {}

    double& operator[](std::size_t index) {
        return data_[index];
    }

    const double& operator[](std::size_t index) const {
        return data_[index];
    }

    double& at(std::size_t index) {
        return data_.at(index);
    }

    const double& at(std::size_t index) const {
        return data_.at(index);
    }

    std::size_t size() const noexcept { return data_.size(); }

private:
    std::vector<double> data_;
};
```

这里的 `operator[]` 继承了 `vector::operator[]` 的前置条件：索引必须有效，越界访问不能靠返回值补救；`at()` 则会在越界时抛出 `std::out_of_range`。自定义接口应把这种差别写进契约，让调用者知道自己选择的是哪条失败路径。

==== 输入输出运算符

元素可以访问之后，我们还常希望把整个对象写入日志，或从文本中读回来。对于 `std::cout << value`，左操作数是无法由我们修改的 `std::ostream`，所以针对自定义类型的 `<<` 要写成非成员函数；`>>` 同理。

下面约定向量的文本格式是三个以空白分隔的数。输入先读入临时变量，三个字段都成功后才更新对象，避免只读到一半时留下“新 x、旧 y、旧 z”的混合状态：

```cpp
#include <iostream>

class Vector3D {
public:
    Vector3D(double x = 0.0, double y = 0.0, double z = 0.0)
        : x(x), y(y), z(z) {}

    friend std::ostream& operator<<(std::ostream& os, const Vector3D& v);
    friend std::istream& operator>>(std::istream& is, Vector3D& v);

private:
    double x, y, z;
};

std::ostream& operator<<(std::ostream& os, const Vector3D& v) {
    return os << v.x << ' ' << v.y << ' ' << v.z;
}

std::istream& operator>>(std::istream& is, Vector3D& v) {
    double x, y, z;
    if (is >> x >> y >> z) {
        v = Vector3D(x, y, z);
    }
    return is;
}

int main() {
    Vector3D v1(1.0, 2.0, 3.0);
    std::cout << "v1 = " << v1 << '\n';

    Vector3D v2;
    std::cout << "输入向量 (x y z): ";
    if (std::cin >> v2) {
        std::cout << "你输入的向量是: " << v2 << '\n';
    } else {
        std::cerr << "输入格式错误\n";
    }

    return 0;
}
```

输出接受 `const` 引用，因为写出文本不应改变向量；输入接受非 `const` 引用，因为成功后需要赋新值。两个运算符都返回原来的流引用，于是流状态会继续传播，`std::cout << v1 << '\n'` 和 `if (std::cin >> v2)` 也才能按熟悉的方式组合。若类型还要校验坐标范围，应先构造并验证完整候选值，再决定异常或流失败如何报告。

==== 递增递减运算符

流运算符的写法由左右操作数决定，`++` 和 `--` 的特别之处则是同一符号有前置、后置两种语义。前置形式返回修改后的对象；后置形式要返回修改前的值。重载声明中的 `int` 形参只用于区分后置版本：

```cpp
#include <iostream>
#include <limits>
#include <stdexcept>

class Counter {
public:
    explicit Counter(int value = 0) : value_(value) {}

    Counter& operator++() {
        if (value_ == std::numeric_limits<int>::max()) {
            throw std::overflow_error("counter increment overflow");
        }
        ++value_;
        return *this;
    }

    Counter operator++(int) {
        Counter old = *this;
        ++(*this);
        return old;
    }

    Counter& operator--() {
        if (value_ == std::numeric_limits<int>::min()) {
            throw std::overflow_error("counter decrement overflow");
        }
        --value_;
        return *this;
    }

    Counter operator--(int) {
        Counter old = *this;
        --(*this);
        return old;
    }

    int value() const noexcept { return value_; }

private:
    int value_;
};

int main() {
    Counter c(5);

    Counter afterPrefix = ++c;  // c 和 afterPrefix 都保存 6
    Counter beforePostfix = c++; // beforePostfix 保存 6，c 保存 7

    std::cout << afterPrefix.value() << ' '
              << beforePostfix.value() << ' '
              << c.value() << '\n';

    return 0;
}
```

后置版本复用前置版本，避免两处分别维护边界检查。它在语义上必须保留旧值，对复制昂贵的用户类型可能因此多出工作；对简单整数和轻量迭代器，优化器也可能消掉未使用的临时量。因此，不需要旧值时写 `++i`，首先是准确表达意图，而不是宣称它在所有构建中一定更快。

==== 类型转换运算符

有些类型除了参与运算，还需要转换成另一种表示。转换运算符写作 `operator 目标类型()`，前面不再写返回类型。是否允许编译器悄悄执行这次转换，则由接口设计决定。

```cpp
#include <iostream>
#include <stdexcept>

class Fraction {
public:
    Fraction(int numerator = 0, int denominator = 1)
        : numerator_(numerator), denominator_(denominator) {
        if (denominator == 0) {
            throw std::invalid_argument("fraction denominator must not be zero");
        }
    }

    explicit operator double() const {
        return static_cast<double>(numerator_) / denominator_;
    }

    explicit operator bool() const {
        return numerator_ != 0;
    }

private:
    int numerator_;
    int denominator_;
};

int main() {
    Fraction f(3, 4);

    // double d = f;  // 错误：double 转换被声明为 explicit
    double d = static_cast<double>(f);  // d 为 0.75

    if (f) {  // explicit operator bool 可用于这种布尔上下文
        std::cout << "分数非零\n";
    }

    // bool b = f;  // 错误：普通复制初始化不会采用 explicit 转换
    bool b = static_cast<bool>(f);

    return 0;
}
```

`explicit operator bool` 有一条有用的规则：它不能随意把对象变成整数，却可以出现在 `if`、`while` 和逻辑运算等需要判断真假的上下文中。对其他转换，也可以先采用 `explicit`，只有当转换无歧义、代价和信息损失都符合使用者直觉时，再有意识地允许隐式转换。

反方向的转换由构造函数控制。一个可用单个实参调用、且没有写 `explicit` 的构造函数可能参与隐式转换：

```cpp
class Vector3D {
public:
    explicit Vector3D(double value)
        : x_(value), y_(value), z_(value) {}

private:
    double x_, y_, z_;
};

int main() {
    // Vector3D v1 = 1.5;  // 错误：复制初始化不采用 explicit 构造函数
    Vector3D v2(1.5);      // 明确创建 (1.5, 1.5, 1.5)

    return 0;
}
```

这里特意只保留一个 `explicit Vector3D(double)`。若同时存在一个非 `explicit` 的 `double` 构造函数和一个 `explicit` 的 `int` 构造函数，整数仍可能绕道转换成 `double`，并不能靠后者彻底禁止隐式构造。判断转换是否存在时，要看完整的重载集合，而不能只盯着某一个构造函数。

==== 函数调用运算符

`operator()` 把“对象携带的状态”和“一次计算”连在一起。这样的对象称为函数对象，也常叫仿函数（functor）：

```cpp
#include <cmath>
#include <iostream>

class Adder {
public:
    explicit Adder(double increment) : increment_(increment) {}

    double operator()(double value) const {
        return value + increment_;
    }

private:
    double increment_;
};

class DistanceCalculator {
public:
    DistanceCalculator(double x, double y, double z)
        : originX_(x), originY_(y), originZ_(z) {}

    double operator()(double x, double y, double z) const {
        const double dx = x - originX_;
        const double dy = y - originY_;
        const double dz = z - originZ_;
        return std::hypot(dx, dy, dz);
    }

private:
    double originX_, originY_, originZ_;
};

int main() {
    Adder addFive(5.0);
    std::cout << addFive(10.0) << '\n';  // 15
    std::cout << addFive(20.0) << '\n';  // 25

    DistanceCalculator distFromOrigin(0, 0, 0);
    std::cout << distFromOrigin(3, 4, 0) << '\n';  // 5

    return 0;
}
```

这里的 `Adder` 记住增量，`DistanceCalculator` 记住参考点。三参数 `std::hypot` 会比直接计算 `sqrt(dx*dx + dy*dy + dz*dz)` 更稳妥地处理中间上溢和下溢；它在 C++17 中可用。

函数对象可以作为标准库算法的参数。算法只关心对象能否按要求调用，并不要求它一定是普通函数、类对象还是 lambda：

```cpp
#include <algorithm>
#include <vector>

std::vector<int> numbers = {1, 2, 3, 4, 5};

struct IsEven {
    bool operator()(int n) const {
        return n % 2 == 0;
    }
};

auto it = std::find_if(numbers.begin(), numbers.end(), IsEven());
```

C++11 之后，短小的一次性规则通常用 lambda 写得更近；需要命名、复用、维护较多状态或提供多个重载时，显式的函数对象类依然很合适。后文会单独展开 lambda。

==== 运算符重载的原则与限制

走过这些例子后，可以把边界收拢起来。下面列出初学阶段最容易误认为可以重载的项目，不把整套 C++ 表达式文法都搬到这里：

- `::` 作用域解析运算符
- `.` 成员访问运算符
- `.*` 成员指针访问运算符
- `?:` 条件运算符
- `sizeof`、`alignof`、`typeid` 和 `noexcept`
- `static_cast`、`dynamic_cast`、`const_cast` 与 `reinterpret_cast` 这些命名转换

能够重载也不等于值得重载。`&&`、`||` 和逗号运算符虽然可以重载，但重载后的求值行为不像内置版本那样直观，尤其不能把自定义 `&&`、`||` 当作短路控制流使用。设计接口时可以依次问：

- 读者能否从符号预期含义？若 `+` 实际执行保存、联网或修改左操作数，命名函数更清楚。
- 相关关系是否一致？若同时提供 `+` 与 `+=`，结果应遵守同一数值约定；`==`、排序和哈希也要表达兼容的相等概念。
- 混合类型是否真的自然？标量与向量的乘法适合支持两个方向，但并非每个二元操作都应强行对称。
- 失败路径是否明确？除零、越界、解析失败和数值溢出不能因为表达式变短就消失。

还有几条由语法决定的硬约束：不能改变运算符原有的优先级、结合方向和操作数个数；至少一个操作数必须是类或枚举类型。赋值 `=`、下标 `[]`、调用 `()` 和成员访问 `->` 必须重载为成员函数，类型转换运算符也必须是成员。复合赋值通常写成成员；若希望左操作数也参与隐式转换，对称算术运算通常更适合非成员。针对标准流的 `<<` 与 `>>` 则因为流位于左侧，只能写成非成员函数。

这些规则的目标不是让类型“看起来像内置类型”，而是让短表达式仍然可预测。最后用一个小型复数类把选择串起来，并把除零、输入失败等容易被漂亮语法遮住的路径一起处理。

==== 一个完整的例子

下面把本节的选择收进一个小型复数类。它有意允许 `double` 隐式转换成实部对应的复数，因此 `c + 2.0` 和 `2.0 + c` 都符合数学直觉；其他运算则复用复合赋值，避免维护两套公式：

```cpp
#include <cmath>
#include <iostream>
#include <stdexcept>

class Complex {
public:
    Complex() = default;

    // 有意保留隐式转换：实数 r 对应复数 (r, 0)。
    Complex(double real) : real_(real) {}

    Complex(double real, double imag) : real_(real), imag_(imag) {}

    double real() const noexcept { return real_; }
    double imag() const noexcept { return imag_; }

    double magnitude() const {
        return std::hypot(real_, imag_);
    }

    Complex& operator+=(const Complex& other) {
        real_ += other.real_;
        imag_ += other.imag_;
        return *this;
    }

    Complex& operator-=(const Complex& other) {
        real_ -= other.real_;
        imag_ -= other.imag_;
        return *this;
    }

    Complex& operator*=(const Complex& other) {
        const double newReal =
            real_ * other.real_ - imag_ * other.imag_;
        const double newImag =
            real_ * other.imag_ + imag_ * other.real_;
        real_ = newReal;
        imag_ = newImag;
        return *this;
    }

    Complex& operator/=(const Complex& other) {
        const double a = real_;
        const double b = imag_;
        const double c = other.real_;
        const double d = other.imag_;

        if (c == 0.0 && d == 0.0) {
            throw std::domain_error("cannot divide by zero complex value");
        }

        double newReal;
        double newImag;

        // 分支公式避免直接计算 c*c + d*d。
        if (std::abs(c) >= std::abs(d)) {
            const double ratio = d / c;
            const double denominator = c + d * ratio;
            newReal = (a + b * ratio) / denominator;
            newImag = (b - a * ratio) / denominator;
        } else {
            const double ratio = c / d;
            const double denominator = d + c * ratio;
            newReal = (a * ratio + b) / denominator;
            newImag = (b * ratio - a) / denominator;
        }

        real_ = newReal;
        imag_ = newImag;
        return *this;
    }

    Complex operator-() const {
        return Complex(-real_, -imag_);
    }

    Complex operator+() const {
        return *this;
    }

    bool operator==(const Complex& other) const {
        return real_ == other.real_ && imag_ == other.imag_;
    }

    bool operator!=(const Complex& other) const {
        return !(*this == other);
    }

    friend Complex operator+(Complex left, const Complex& right) {
        left += right;
        return left;
    }

    friend Complex operator-(Complex left, const Complex& right) {
        left -= right;
        return left;
    }

    friend Complex operator*(Complex left, const Complex& right) {
        left *= right;
        return left;
    }

    friend Complex operator/(Complex left, const Complex& right) {
        left /= right;
        return left;
    }

    friend std::ostream& operator<<(std::ostream& os, const Complex& value) {
        return os << value.real_ << ' ' << value.imag_;
    }

    friend std::istream& operator>>(std::istream& is, Complex& value) {
        double real;
        double imag;
        if (is >> real >> imag) {
            value = Complex(real, imag);
        }
        return is;
    }

private:
    double real_ = 0.0;
    double imag_ = 0.0;
};

int main() {
    Complex c1(3, 4);
    Complex c2(1, -2);

    std::cout << "c1 (real imag): " << c1 << '\n';
    std::cout << "c2 (real imag): " << c2 << '\n';
    std::cout << "|c1|: " << c1.magnitude() << '\n';

    std::cout << "c1 + c2: " << (c1 + c2) << '\n';  // 4 2
    std::cout << "c1 - c2: " << (c1 - c2) << '\n';  // 2 6
    std::cout << "c1 * c2: " << (c1 * c2) << '\n';  // 11 -2
    std::cout << "c1 / c2: " << (c1 / c2) << '\n';  // -1 2

    Complex c3 = c1 + 5.0;  // 5.0 转换为 Complex(5.0)
    Complex c4 = 2.0 * c1;  // 左操作数同样可以转换
    std::cout << "c1 + 5: " << c3 << '\n';  // 8 4
    std::cout << "2 * c1: " << c4 << '\n';  // 6 8

    return 0;
}
```

这个版本让 `==` 表示两个保存值按内置浮点规则相等；若应用需要“测量上足够接近”，仍应像前文那样另设带容差的命名函数。除法公式避免先平方分母的两个分量，可以减少一类中间上溢，但它并不承诺所有极端浮点输入都得到有限结果；无穷大、NaN 和结果超出 `double` 范围时，仍会遵循平台的浮点行为。

这仍是讲解接口关系的教学类型，工程代码通常应先考虑标准库的 `std::complex`。真正值得带到下一节的不是“尽量多重载几个符号”，而是契约意识：短语法也要说明修改对象与否、边界在哪里、失败后对象处于什么状态。STL 容器正是下一组这样的契约——它们把元素的存放方式、访问方式和迭代规则组织成几类可组合的接口。


=== STL 容器
// vector, deque, list
// map, unordered_map
// set, unordered_set
// queue, stack
// 如何选择容器
// === STL 容器

数组适合“元素数量和存储期都已经确定”的情形，工程中的数据却常常没有这么整齐：一帧里有多少目标要到运行时才知道，设备 ID 需要映射到状态，待处理任务还可能按到达顺序或优先级排队。标准库容器替我们管理元素的存储和生命周期，也给出了查找、插入、遍历等共同接口。

容器并不会替我们做完所有设计。选型时真正要问的是：需要连续内存吗，按位置还是按键访问，顺序是否有意义，插入后已有引用能否失效，最坏一次操作能否接受？先带着这些问题认识各类容器，后面的复杂度表才不会变成要背的口诀。

==== 容器的分类

日常所说的 STL 容器，可以先分成四组：

- *顺序容器*按位置组织元素。`array` 大小固定；`vector`、`deque`、`list` 和 `forward_list` 可动态改变大小，但内存布局与迭代器稳定性不同。
- *有序关联容器*包括 `set`、`map` 及允许重复键的 `multi` 版本。它们按照比较器维护键的顺序，查找、插入和删除通常有对数复杂度保证。
- *无序关联容器*包括 `unordered_set`、`unordered_map` 及其 `multi` 版本。它们按哈希值分桶，不承诺遍历顺序，查找等操作平均为常数复杂度、最坏为线性复杂度。
- *容器适配器*如 `stack`、`queue`、`priority_queue`，在底层容器之上收窄接口，只暴露栈、队列或堆所需的访问方式。

有序关联容器常由平衡树实现，无序容器常由哈希桶实现，但标准主要规定可观察行为和复杂度要求，并不要求某一种具体数据结构。先从最常作为顺序容器默认候选的 `vector` 看起。

==== vector：动态数组

`std::vector` 可以理解为会管理容量的连续数组。除专门压缩位存储的 `vector<bool>` 外，连续存储带来 O(1) 下标访问，也允许通过 `data()` 与需要连续区间的接口衔接；代价是扩容时可能要把现有元素搬到新的存储区。

构造方式与数组初始化很接近，但要留意“元素个数”和“元素内容”两种括号含义：

```cpp
#include <iostream>
#include <vector>

int main() {
    std::vector<int> numbers;
    std::vector<int> zeros(5);          // 5 个 0
    std::vector<int> tens(5, 10);       // 5 个 10
    std::vector<int> primes{2, 3, 5, 7, 11};
    std::vector<int> primesCopy = primes;

    std::cout << numbers.size() << ' '
              << zeros.size() << ' '
              << tens.front() << '\n';

    return 0;
}
```

尖括号里的模板参数是元素类型，因此 `std::vector<double>`、`std::vector<std::string>` 和 `std::vector<Target>` 分别管理不同类型的对象。容器会拥有这些元素；复制整个 `vector` 通常也会复制其中的元素。

访问时有两条不同契约。`operator[]` 要求调用者已经保证索引有效，`at()` 会检查并在越界时抛出 `std::out_of_range`：

```cpp
std::vector<int> v = {10, 20, 30, 40, 50};

int a = v[0];      // 10，不检查边界
int b = v.at(1);   // 20，检查边界

v[2] = 35;         // 修改元素
// v[10] = 100;    // 越界：违反 operator[] 的前置条件
// v.at(10) = 100; // 抛出 std::out_of_range 异常

int first = v.front();  // 第一个元素
int last = v.back();    // 最后一个元素
```

`front()`、`back()` 和 `pop_back()` 同样要求容器非空；它们不会用特殊值表示“没有元素”。若空状态来自外部输入，应先检查 `empty()`。

在末尾追加是 `vector` 最擅长的操作：

```cpp
std::vector<int> v;

v.push_back(10);   // 添加到末尾：{10}
v.push_back(20);   // {10, 20}
v.push_back(30);   // {10, 20, 30}

if (!v.empty()) {
    v.pop_back();  // {10, 20}
}

v.emplace_back(40);  // 用给定实参在末尾构造一个 int
```

`pop_back()` 是常数复杂度；`push_back()` 和 `emplace_back()` 是摊销常数复杂度，因为偶尔一次扩容可能需要移动或复制全部旧元素。`emplace_back(args...)` 会用实参直接构造末尾元素，但不等于任何情况下都“零拷贝”：扩容仍可能搬迁旧元素，传入一个已经构造好的对象时也未必比 `push_back` 更省工作。

这就引出了大小（size）和容量（capacity）的区别。大小是当前存在多少个元素，容量是当前存储区在再次分配前能容纳多少个元素：

```cpp
std::vector<int> v;

std::cout << "size: " << v.size() << '\n';
std::cout << "capacity: " << v.capacity() << '\n';

v.reserve(100);
std::cout << "size after reserve: " << v.size() << '\n';         // 仍为 0
std::cout << "capacity after reserve: " << v.capacity() << '\n'; // 至少 100

for (int i = 0; i < 50; ++i) {
    v.push_back(i);
}
std::cout << "size after append: " << v.size() << '\n';           // 50
std::cout << "capacity after append: " << v.capacity() << '\n';   // 至少 100

v.shrink_to_fit();  // 请求缩减容量，标准不要求实现一定照做
```

`reserve(100)` 不会创建 100 个元素，只是保证容量至少达到 100。若能够合理估计一帧目标数或一批消息数，预留容量可以减少这段增长过程中的重新分配；估计严重偏大也会保留更多内存，所以是否值得要结合数据规模和目标平台判断。

重新分配还有一个比时间更容易漏掉的后果：指向旧元素的迭代器、指针和引用都会失效。即使没有重新分配，在中间插入也会使插入点及其后的迭代器失效，删除则会使删除点及其后的迭代器失效。不要在可能改变 `vector` 的操作前保存元素引用，再不经检查地继续使用它。

只读遍历时，选择最能表达需求的写法即可：

```cpp
#include <cstddef>
#include <iostream>
#include <string>
#include <vector>

std::vector<int> v = {1, 2, 3, 4, 5};

// 需要索引时使用下标。
for (std::size_t i = 0; i < v.size(); ++i) {
    std::cout << v[i] << " ";
}

// 只需要小型值时，按值读取很直接。
for (int x : v) {
    std::cout << x << " ";
}

// 对较大的对象，用 const 引用避免为每一项创建副本。
std::vector<std::string> names = {"hero", "sentry"};
for (const std::string& name : names) {
    std::cout << name << " ";
}

// 需要迭代器本身时显式使用它。
for (auto it = v.begin(); it != v.end(); ++it) {
    std::cout << *it << " ";
}
```

在中间插入和删除需要移动后面的元素，因此是 O(n)。示例里的位置都由当前容器的有效迭代器计算得出：

```cpp
std::vector<int> v = {1, 2, 3, 4, 5};

// 在位置 2（第三个元素前）插入 100
v.insert(v.begin() + 2, 100);  // {1, 2, 100, 3, 4, 5}

// 删除位置 3 的元素
v.erase(v.begin() + 3);  // {1, 2, 100, 4, 5}

// 删除范围 [begin+1, begin+3)
v.erase(v.begin() + 1, v.begin() + 3);  // {1, 4, 5}

v.clear();
std::cout << std::boolalpha << v.empty() << '\n';  // true
```

这里的 O(n) 不等于“一定很慢”；元素大小、移动代价、缓存局部性和操作频率都会改变实际结果。先记住行为与失效规则，再谈是否需要换容器。

==== deque：双端队列

如果数据会从两端进出，`std::deque`（double-ended queue）比在 `vector` 头部反复搬动元素更贴合需求。它支持 O(1) 随机访问和两端常数复杂度的插入、删除，但元素不保证处于一整段连续内存中。常见实现使用若干内存块加一层索引，具体分块方式不是接口契约。

```cpp
#include <deque>

std::deque<int> dq = {2, 3, 4};

// 在两端操作都是高效的
dq.push_front(1);   // {1, 2, 3, 4}
dq.push_back(5);    // {1, 2, 3, 4, 5}

if (!dq.empty()) {
    dq.pop_front(); // {2, 3, 4, 5}
    dq.pop_back();  // {2, 3, 4}
}

int x = dq[1];      // 3
int y = dq.at(2);   // 4
```

`deque` 没有 `data()`、`capacity()` 和 `reserve()`；要把全部元素交给只接收连续缓冲区的接口，不能直接拿首元素地址充当整段数组。它的失效规则也与 `vector` 不同：例如在两端插入可能使已有迭代器失效，即使指向元素的引用仍有效；在中间插入、删除影响更大。需要长期保存迭代器或引用时，应针对具体操作查清规则，而不要从“没有整体扩容”推断它们一定稳定。

==== list：双向链表

`std::list` 提供双向链表语义。给定一个有效迭代器后，在该位置插入或删除是常数复杂度，而且除了被删除的元素，其他元素的迭代器和引用通常保持有效。代价是不能下标访问；为了找到“第 i 个元素”仍要从某处逐个走过去。

```cpp
#include <iostream>
#include <iterator>
#include <list>

std::list<int> lst = {1, 2, 3, 4, 5};

// 在两端操作
lst.push_front(0);   // {0, 1, 2, 3, 4, 5}
lst.push_back(6);    // {0, 1, 2, 3, 4, 5, 6}

// 不支持随机访问
// int x = lst[2];   // 错误！list 没有 operator[]

auto it = lst.begin();
std::advance(it, 2);  // 前进两步本身是 O(n)
std::cout << *it << '\n';  // 2

lst.insert(it, 100);  // 已找到位置后，插入为 O(1)
it = lst.erase(it);   // 删除原来的 2，返回下一元素的迭代器
```

链表还能在不逐个搬动元素的情况下拼接节点，并提供适配双向迭代器的成员算法。下面几个名称相似，但前置条件和作用范围并不相同：

```cpp
#include <list>

std::list<int> lst1 = {1, 3, 5};
std::list<int> lst2 = {2, 4, 6};

// 两边必须已经按同一规则排序。
lst1.merge(lst2);  // lst1 = {1, 2, 3, 4, 5, 6}, lst2 = {}

std::list<int> unsorted = {5, 2, 8, 1, 9};
unsorted.sort();  // {1, 2, 5, 8, 9}

// unique 只压缩相邻的重复项。
std::list<int> dups = {1, 1, 2, 2, 2, 3, 3};
dups.unique();  // {1, 2, 3}

std::list<int> vals = {1, 2, 3, 2, 4, 2};
vals.remove(2);  // {1, 3, 4}

std::list<int> rev = {1, 2, 3};
rev.reverse();  // {3, 2, 1}
```

`std::sort` 需要随机访问迭代器，不能直接用于 `list`，所以这里使用 `list::sort()`。链表的节点通常分散分配并带有链接开销，顺序遍历在许多平台上不如连续的 `vector` 友好；但若程序已经持有插入位置、需要拼接区间或要求其他元素地址稳定，`list` 的语义可能正合适。仅仅听到“中间插入多”还不够，找到那个中间位置的成本也要算进去。

==== set：有序集合

`std::set` 同时表达两件事：元素不重复，并按比较器维持顺序。查找、插入和按键删除具有 O(log n) 复杂度；默认比较器使用 `<` 所表达的顺序。比较器必须形成严格弱序，否则容器无法可靠判断两个键应排在哪里、是否等价。这里的“等价”由 `!comp(a, b) && !comp(b, a)` 决定，不一定调用 `operator==`。

```cpp
#include <iostream>
#include <set>

std::set<int> s;

// 插入元素
auto [firstIt, inserted] = s.insert(30);
s.insert(10);
s.insert(20);
auto [existingIt, insertedAgain] = s.insert(10);
std::cout << std::boolalpha << inserted << ' '
          << insertedAgain << '\n';  // true false

for (int x : s) {
    std::cout << x << " ";  // 10 20 30
}
std::cout << '\n';

auto it = s.find(20);
if (it != s.end()) {
    std::cout << "找到: " << *it << '\n';
}

if (s.count(20) != 0) {  // 对 set 而言只会是 0 或 1
    std::cout << "20 存在\n";
}

// C++20 起可以写得更直接：
// if (s.contains(20)) { ... }

s.erase(20);
if (!s.empty()) {
    s.erase(s.begin());
}

std::cout << "size: " << s.size() << '\n';
```

结构化绑定接住了 `insert` 返回的“元素位置 + 是否新插入”结果。`set` 迭代器提供的是不可修改的元素视图，因为原地改键可能破坏排序；需要改变键时应删除后重新插入，C++17 也可用节点句柄完成这类迁移。

例如，在单线程的一段处理流程里，可以用插入结果判断某个目标 ID 是否第一次出现：

```cpp
#include <set>

std::set<int> seenTargetIds;

bool firstObservation(int targetId) {
    return seenTargetIds.insert(targetId).second;
}
```

这个集合只解决去重，不自动解决多线程同步、过期 ID 清理或“处理失败后是否仍算见过”等业务问题。

==== map：有序键值对

`std::map<Key, Value>` 把唯一键映射到值，并按键的比较顺序遍历。按键查找、插入和删除是 O(log n)。与 `set` 一样，标准不要求它必须采用某一种树实现。

```cpp
#include <iostream>
#include <map>
#include <stdexcept>
#include <string>

std::map<std::string, int> ages;

ages.try_emplace("Alice", 25);          // 仅当键不存在时构造值
ages.insert_or_assign("Bob", 30);       // 插入或覆盖
ages.insert({"Charlie", 35});

std::cout << "Alice's age: " << ages.at("Alice") << '\n';

// operator[] 在键不存在时插入一个默认构造的 int（这里是 0）。
int& eveAge = ages["Eve"];
eveAge = 29;

try {
    int age = ages.at("Frank");
    std::cout << age << '\n';
} catch (const std::out_of_range& e) {
    std::cout << "Frank not found\n";
}

auto it = ages.find("Bob");
if (it != ages.end()) {
    std::cout << it->first << " is " << it->second << " years old\n";
}

for (const auto& [name, age] : ages) {
    std::cout << name << ": " << age << '\n';
}
```

只读查询时，`find()` 不抛异常并能表示“没找到”，`at()` 则把缺失键报告为异常。`operator[]` 适合确实要“缺失就创建默认值”的写入路径；拿它做只读查询会悄悄改变容器，而且要求值类型能够默认构造。

映射电机 ID 时，可以用 `try_emplace` 直接以构造参数创建 `Motor`，避免先要求一个无意义的默认电机：

```cpp
std::map<int, Motor> motors;
motors.try_emplace(1, 1, 10000.0);
motors.try_emplace(2, 2, 10000.0);
motors.try_emplace(3, 3, 8000.0);
motors.try_emplace(4, 4, 8000.0);

bool updateMotor(int id, double speed) {
    auto it = motors.find(id);
    if (it == motors.end()) {
        return false;
    }
    it->second.setSpeed(speed);
    return true;
}
```

这段代码只说明容器接口，仍假设 `Motor(int, double)` 和 `setSpeed` 已正确定义，也没有解决多个线程同时访问映射的问题。

==== unordered_set 和 unordered_map

如果不需要按键排序，可以考虑无序关联容器。它们通过哈希值选择桶，查找、插入、删除平均为 O(1)，最坏情况下为 O(n)。遍历顺序没有接口保证，插入或重新散列后还可能改变。

```cpp
#include <iostream>
#include <string>
#include <unordered_map>
#include <unordered_set>

std::unordered_set<int> us = {3, 1, 4, 1, 5, 9};
for (int x : us) {
    std::cout << x << " ";  // 不依赖这里的具体顺序
}
std::cout << '\n';

us.insert(2);
us.erase(4);
bool found = (us.find(5) != us.end());

std::unordered_map<std::string, int> scores;
scores.reserve(3);  // 已知大致元素数时，可减少增长过程中的 rehash
scores["Alice"] = 95;
scores["Bob"] = 87;
scores["Charlie"] = 92;

for (const auto& [name, score] : scores) {
    std::cout << name << ": " << score << '\n';
}
```

`reserve()` 针对预期元素数，而 `rehash()` 直接针对桶数；发生 rehash 会使迭代器失效。自定义键还必须同时给出相等关系和哈希函数，并满足一个关键约束：只要两个键按相等关系比较为真，它们的哈希值就必须相同。

```cpp
#include <cstddef>
#include <functional>
#include <unordered_set>

struct Point {
    int x;
    int y;

    bool operator==(const Point& other) const {
        return x == other.x && y == other.y;
    }
};

struct PointHash {
    std::size_t operator()(const Point& point) const {
        const std::size_t hx = std::hash<int>{}(point.x);
        const std::size_t hy = std::hash<int>{}(point.y);
        return hx ^ (hy + 0x9e3779b9U + (hx << 6U) + (hx >> 2U));
    }
};

int main() {
    std::unordered_set<Point, PointHash> points;
    points.insert({1, 2});
    points.insert({3, 4});
    return points.count({1, 2}) == 1 ? 0 : 1;
}
```

这个组合函数足够说明接口，却不是面向恶意输入的密码学哈希方案。无序容器也不天然比 `map` 更快：哈希计算、桶和节点的内存开销、键分布、数据规模及最坏时延要求都会影响选择。若需要稳定的排序遍历或对数级最坏复杂度，有序容器反而更直接；性能敏感时应在真实键与负载上测量。

==== stack：栈

`std::stack` 把底层容器收窄成后进先出（LIFO）接口：只能查看和移除最近压入的元素。默认底层容器是 `deque`，也可以在满足接口要求时显式选择其他容器。

```cpp
#include <iostream>
#include <stack>

std::stack<int> st;

// 压栈
st.push(10);
st.push(20);
st.push(30);

if (!st.empty()) {
    std::cout << "top: " << st.top() << '\n';  // 30
    st.pop();
}

while (!st.empty()) {
    std::cout << st.top() << " ";
    st.pop();
}
```

`top()` 和 `pop()` 都要求栈非空，且 `pop()` 只删除、不返回元素；需要保留值时应先读取 `top()`。适配器不暴露迭代器，正是为了让调用代码不能绕过“只看栈顶”的语义。括号匹配就是一个小例子：

```cpp
#include <stack>
#include <string>

bool isBalanced(const std::string& expr) {
    std::stack<char> st;

    for (char c : expr) {
        if (c == '(' || c == '[' || c == '{') {
            st.push(c);
        } else if (c == ')' || c == ']' || c == '}') {
            if (st.empty()) {
                return false;
            }

            const char top = st.top();
            if ((c == ')' && top != '(') ||
                (c == ']' && top != '[') ||
                (c == '}' && top != '{')) {
                return false;
            }
            st.pop();
        }
    }

    return st.empty();
}
```

==== queue：队列

`std::queue` 用同样的思路提供先进先出（FIFO）接口：从队尾加入，从队首查看和移除。

```cpp
#include <iostream>
#include <queue>

std::queue<int> q;

// 入队
q.push(10);
q.push(20);
q.push(30);

if (!q.empty()) {
    std::cout << "front: " << q.front() << '\n'; // 10
    std::cout << "back: " << q.back() << '\n';   // 30
    q.pop();
}

std::cout << "size: " << q.size() << '\n';  // 2
```

`front()`、`back()` 和 `pop()` 都要求队列非空。它适合表达广度优先搜索、按到达顺序处理命令等逻辑。例如，若采集与处理明确发生在同一个线程中，可以这样分离入队与单步处理：

```cpp
std::queue<SensorData> sensorQueue;

void sensorCallback(const SensorData& data) {
    sensorQueue.push(data);
}

bool processNext() {
    if (sensorQueue.empty()) {
        return false;
    }

    SensorData data = sensorQueue.front();
    sensorQueue.pop();
    process(data);
    return true;
}
```

对这段没有同步的代码而言，“同一线程”（或其他外部串行化保证）是必要条件，不是注释装饰。标准 `queue` 本身不提供并发同步；若回调和处理循环可能同时访问它，未受保护的 `push`、`empty`、`front` 和 `pop` 会产生数据竞争。那时需要互斥量与条件变量，或经过验证的并发队列，后面的多线程章节会给出完整协议。

==== priority_queue：优先队列

`std::priority_queue` 不按到达先后，而是让“最高”元素位于 `top()`。默认比较下，整数最大值在顶部；内部维护堆结构，查看顶部是 O(1)，插入和移除顶部是 O(log n)。

```cpp
#include <functional>
#include <iostream>
#include <queue>
#include <vector>

std::priority_queue<int> maxPq;
maxPq.push(30);
maxPq.push(10);
maxPq.push(20);

std::cout << maxPq.top() << '\n';  // 30
maxPq.pop();
std::cout << maxPq.top() << '\n';  // 20

std::priority_queue<int, std::vector<int>, std::greater<int>> minPq;
minPq.push(30);
minPq.push(10);
minPq.push(20);

std::cout << minPq.top() << '\n';  // 10
```

自定义类型需要提供一致的顺序。下面用整数优先级避开浮点 NaN 破坏严格弱序的问题，并用 `optional` 表达空队列，而不是直接对空队列调用 `top()`：

```cpp
#include <optional>
#include <queue>
#include <vector>

struct Target {
    int id;
    int priority;
};

struct LowerPriority {
    bool operator()(const Target& left, const Target& right) const {
        return left.priority < right.priority;
    }
};

std::priority_queue<Target, std::vector<Target>, LowerPriority> targetQueue;

void addTarget(const Target& t) {
    targetQueue.push(t);
}

std::optional<Target> takeHighestPriorityTarget() {
    if (targetQueue.empty()) {
        return std::nullopt;
    }

    Target t = targetQueue.top();
    targetQueue.pop();
    return t;
}
```

比较器在 `left` 应排在 `right` 后面时返回 `true`，所以较大的 `priority` 留在顶部。相同优先级之间没有稳定的先来先服务保证；若业务需要稳定次序，应把到达序号也纳入比较键。

==== 如何选择容器

选容器时先写下必须满足的语义，再比较性能：

- 固定编译期长度且由对象拥有的数据，可考虑 `array`；动态长度、连续存储或随机访问通常先看 `vector`。
- 需要从两端频繁进出且不要求整段连续内存，考虑 `deque`。
- 已经持有插入位置，还需要拼接节点或保持其他元素地址稳定，才是 `list` 的强理由；“中间插入”若每次都要线性查找位置，优势可能已经消失。
- 需要唯一键和有序遍历、范围查询或对数级最坏复杂度，选择 `set` / `map`；允许等价键重复时选择对应的 `multi` 版本。
- 不需要顺序、哈希和相等关系容易定义，并能接受平均复杂度与 rehash 行为时，再考虑 `unordered_set` / `unordered_map`。
- 接口本身就是 LIFO、FIFO 或按优先级取出时，用 `stack`、`queue`、`priority_queue` 能把不该出现的访问方式挡在外面。

下面的流程图只给出第一候选，迭代器稳定性、内存上限、最坏时延和外部接口仍可能改变答案：

```
按键查找？
├── 是 → 需要有序遍历、范围查询或对数级最坏复杂度？
│         ├── 是 → set / map
│         └── 否 → unordered_set / unordered_map
└── 否 → 访问模式受限为栈、队列或优先级？
          ├── 是 → 对应的容器适配器
          └── 否 → 需要连续存储或随机访问？
                    ├── 是 → vector
                    └── 否 → 两端频繁进出？
                              ├── 是 → deque
                              └── 否 → 检查 list 的稳定性/拼接优势是否必要
```

==== 容器的通用操作

容器接口相似，但不是完全相同。顺序容器和关联容器普遍提供大小、判空和迭代器；适配器有 `size()` 与 `empty()`，却故意不提供 `begin()` / `end()`。以下用两个 `vector` 展示常见部分：

```cpp
#include <utility>
#include <vector>

std::vector<int> first = {1, 2, 3, 4, 5};
std::vector<int> second = {1, 2, 4};

const auto count = first.size();
const bool hasNoElements = first.empty();
const auto implementationLimit = first.max_size();

auto begin = first.begin();   // 第一个元素；空容器中等于 end()
auto end = first.end();       // 尾后位置，不能解引用
auto reverseBegin = first.rbegin();
auto reverseEnd = first.rend();

const bool same = (first == second);
const bool lexicographicallyBefore = (first < second); // C++17 字典序比较

first.swap(second);
first.clear();
```

`max_size()` 是类型、分配器和实现给出的上限，不代表当前机器真能分配那么多元素。`clear()`、`swap()` 等操作也各有失效规则。无序关联容器支持相等比较，却没有按遍历次序定义的 `<`；C++20 还调整了若干关系运算符的表达方式。通用算法真正依赖的不是“所有容器方法都一样”，而是一对迭代器所描述的范围。

==== 实践中的性能考虑

复杂度表适合排除明显不合适的候选，但要把操作的前提写清楚：

```
操作                         vector       deque        list         set/map      unordered
下标访问                     O(1)         O(1)         不支持       不支持       不支持
末尾插入                     摊销 O(1)    O(1)         O(1)         -            -
开头插入                     O(n)         O(1)         O(1)         -            -
已知位置的单元素中间插入     O(n)         O(n)         O(1)         -            -
顺序查找某个值               O(n)         O(n)         O(n)         -            -
按键查找                     -            -            -            O(log n)     平均 O(1)，最坏 O(n)
按键插入或删除               -            -            -            O(log n)     平均 O(1)，最坏 O(n)
```

大 O 省略了元素移动代价、分配器、哈希计算、节点开销和缓存行为，也没有直接告诉我们一次最坏操作会卡多久。连续遍历常让 `vector` 受益于局部性，所以在一些数据规模上，移动一段紧凑元素仍可能比追逐链表节点快；这是常见测量结果，不是从复杂度自动推出的普遍结论。

对于普通动态序列，`vector` 是值得先评估的候选；如果正确性本身要求键排序、地址稳定或两端操作，就不必等性能分析后才换掉它。对控制周期等关心最坏时延的路径，还要单独检查扩容、节点分配和 rehash 是否可能落在关键时刻，必要时预留容量、把分配移出关键路径，或选择具有明确容量策略的其他组件，并在目标平台上测量。

到这里，容器负责“数据放在哪里以及怎样找到它”。下一节把视角移到“对一段数据做什么”：迭代器把范围的边界交给算法，使查找、排序、变换等操作不必为每一种容器各写一遍。


=== STL 算法与迭代器
// 迭代器概念
// 常用算法（sort, find, transform）
// 范围 for 循环
// === STL 算法与迭代器

容器解决存放问题，排序、查找、复制和统计则由算法接手。经典 STL 没让每个容器都各自实现一遍 `find`，而是让算法接收一对迭代器：它们描述从哪里开始、到哪里结束，以及这段范围支持哪些移动和访问操作。

这种分工不是“任意算法都能用于任意容器”。`sort` 需要快速跳到任意位置，`list` 的迭代器做不到；`stack` 又刻意不暴露迭代器。理解算法要求与迭代器能力怎样对上，比背函数名更重要。

==== 迭代器的概念

把迭代器想成“带有移动规则的当前位置”很有帮助：解引用读取当前位置，`++` 前进到下一项。但这个比喻有边界——尾后迭代器不能解引用，容器操作可能使迭代器失效，来自无关容器的迭代器也不能随意比较或拼成一个范围。

多数容器通过 `begin()` 和 `end()` 给出一个半开区间 `[begin, end)`：

```cpp
#include <iostream>
#include <vector>

int main() {
    std::vector<int> v = {10, 20, 30, 40, 50};

    std::vector<int>::iterator it = v.begin();
    const auto finish = v.end();

    if (it != finish) {
        std::cout << *it << '\n';  // 10
        ++it;
    }

    for (auto iter = v.begin(); iter != v.end(); ++iter) {
        std::cout << *iter << " ";
    }
    std::cout << '\n';

    return 0;
}
```

空容器的 `begin()` 等于 `end()`，循环自然一次也不执行。对非空范围，最后一个有效元素位于 `end()` 之前；`end()` 只是边界标记。一个有效范围还要求从起点按迭代器规则能够到达终点。

迭代器能力不是简单的“低级到高级”单线排行。传统 C++17 术语可以这样理解：

- *输入迭代器*可单向读取，常用于只能消费一次的数据源，例如输入流。
- *输出迭代器*提供单向写入位置；它与“可读”是另一条能力轴，不是输入迭代器的加强版。
- *前向迭代器*可以从同一位置多次遍历。是否能修改元素仍取决于解引用得到的类型；`const` 迭代器就只读。
- *双向迭代器*再增加 `--`。`list`、`set` 和 `map` 提供这一类别，不过后两者不能借迭代器修改键。
- *随机访问迭代器*可在同一范围内用 `+`、`-`、`[]` 和差值常数时间跳转。`vector`、`deque`、`array` 以及合适范围内的原生指针属于这一类。

C++20 还正式区分了*连续迭代器*：它在随机访问之外保证元素连续，典型例子是原生指针、`array` 和普通的 `vector<T>` 迭代器；`deque` 虽可随机访问，却不连续。

```cpp
#include <iostream>
#include <list>
#include <vector>

std::vector<int> v = {10, 20, 30, 40, 50};
auto it = v.begin();

it += 1;               // 指向 20
auto it2 = it + 2;     // 指向 40
auto diff = it2 - it;  // 2
bool before = it < it2;

std::cout << *it << ' ' << it[2] << ' '
          << diff << ' ' << before << '\n';

std::list<int> lst = {10, 20, 30};
auto lit = lst.begin();
++lit;
--lit;
// lit += 2;  // 错误：双向迭代器不支持随机跳转
```

上述算术只有在结果仍位于同一有效范围（或其尾后位置）时才成立。`std::sort` 要求随机访问迭代器，所以 `list` 改用成员 `sort()`；`std::find` 只需逐项读取，适用范围更广，但仍不能用于不提供迭代器的容器适配器。

==== 迭代器的种类

类别描述“能怎样移动”，具体迭代器类型还会限制读写方向。`const_iterator` 不允许通过这个迭代器修改元素：

```cpp
#include <vector>

std::vector<int> v = {10, 20, 30};

std::vector<int>::iterator it = v.begin();
*it = 100;

std::vector<int>::const_iterator cit = v.cbegin();
// *cit = 200;  // 错误：不能经由 cit 修改

const std::vector<int>& cv = v;
auto cit2 = cv.begin();
```

`cbegin()` / `cend()` 即使面对非 `const` 容器也返回常量迭代器。它只约束这条访问路径，并不冻结底层容器；其他非 `const` 引用仍可能修改元素或使该迭代器失效。

反向迭代器把前进方向翻转过来：

```cpp
#include <iostream>
#include <vector>

std::vector<int> v = {10, 20, 30, 40, 50};

for (auto rit = v.rbegin(); rit != v.rend(); ++rit) {
    std::cout << *rit << " ";
}
std::cout << '\n';  // 50 40 30 20 10

for (auto crit = v.crbegin(); crit != v.crend(); ++crit) {
    std::cout << *crit << " ";
}
```

输出范围必须有足够空间，否则普通写入迭代器会越界。插入迭代器换一种策略：算法每次写入时调用容器的插入操作，从而按需增长目标容器。

```cpp
#include <algorithm>
#include <iterator>
#include <list>
#include <vector>

std::vector<int> v = {1, 2, 3};
std::vector<int> result;

std::copy(v.begin(), v.end(), std::back_inserter(result));
// result = {1, 2, 3}

std::list<int> lst;
std::copy(v.begin(), v.end(), std::front_inserter(lst));
// lst = {3, 2, 1}，每次都插到最前面

std::vector<int> v2 = {10, 20};
std::copy(v.begin(), v.end(), std::inserter(v2, v2.begin() + 1));
// v2 = {10, 1, 2, 3, 20}
```

`back_inserter` 要求 `push_back`，`front_inserter` 要求 `push_front`，通用 `inserter` 则调用 `insert`。选择哪一个不仅决定能否编译，也会决定输出顺序和插入成本。

==== 常用算法概览

多数通用算法声明在 `<algorithm>`，数值累积相关算法主要在 `<numeric>`。调用时先看三个问题：输入范围是否有效，迭代器能力是否足够，比较器或谓词是否满足算法要求。

`std::sort` 默认按升序重排整个范围，也可以接收自定义比较器：

```cpp
#include <algorithm>
#include <functional>
#include <vector>

std::vector<int> v = {30, 10, 50, 20, 40};

std::sort(v.begin(), v.end());
// v = {10, 20, 30, 40, 50}

std::sort(v.begin(), v.end(), std::greater<>{});
// v = {50, 40, 30, 20, 10}

std::sort(v.begin(), v.end(), [](int a, int b) {
    return a > b;
});

std::vector<int> v2 = {5, 3, 1, 4, 2};
std::sort(v2.begin() + 1, v2.begin() + 4); // 排序索引 [1, 4)
// v2 = {5, 1, 3, 4, 2}
```

`sort` 要求随机访问迭代器，并保证 O(n log n) 量级的比较次数；标准不要求采用某个具名排序实现。比较器必须形成严格弱序，不能用 `<=` 代替 `<`，也不能在比较途中改变参与排序的键。`list` 没有随机访问迭代器，使用它自己的 `list::sort()`。

若相等键之间的原有顺序有意义，使用 `std::stable_sort`：

```cpp
#include <algorithm>
#include <string>
#include <vector>

struct Student {
    std::string name;
    int score;
};

std::vector<Student> students = {
    {"Alice", 90}, {"Bob", 85}, {"Charlie", 90}, {"David", 85}
};

// 按分数排序，相同分数保持原顺序
std::stable_sort(students.begin(), students.end(),
    [](const Student& a, const Student& b) {
        return a.score > b.score;
    });
// Alice(90), Charlie(90), Bob(85), David(85)
```

这里的“相等键”指比较器既不认为 `a` 在 `b` 前，也不认为 `b` 在 `a` 前。稳定性有成本，只有业务需要保留相对顺序时才值得作为约束。

线性查找返回第一个匹配位置；没有匹配时返回传入的尾后迭代器：

```cpp
#include <algorithm>
#include <iostream>
#include <iterator>
#include <vector>

std::vector<int> v = {10, 20, 30, 40, 50};

auto it = std::find(v.begin(), v.end(), 30);
if (it != v.end()) {
    std::cout << "找到: " << *it << '\n';
    std::cout << "位置: " << std::distance(v.begin(), it) << '\n';
} else {
    std::cout << "未找到\n";
}

auto it2 = std::find_if(v.begin(), v.end(), [](int x) {
    return x > 25;
});
if (it2 != v.end()) {
    std::cout << "第一个大于 25 的数: " << *it2 << '\n';
}

auto it3 = std::find_if_not(v.begin(), v.end(), [](int x) {
    return x < 35;
});
if (it3 != v.end()) {
    std::cout << "第一个不小于 35 的数: " << *it3 << '\n';
}
```

`std::distance` 对随机访问迭代器是 O(1)，对 `list` 一类迭代器则要逐步前进。即使我们“知道应该能找到”，也先与 `end()` 比较，再解引用返回值。

对已经按同一比较规则排序的随机访问范围，可以二分查询：

```cpp
#include <algorithm>
#include <vector>

std::vector<int> v = {10, 20, 30, 40, 50};  // 必须已排序

bool found = std::binary_search(v.begin(), v.end(), 30);
bool notFound = std::binary_search(v.begin(), v.end(), 35);

auto lower = std::lower_bound(v.begin(), v.end(), 30); // 第一个不小于 30
auto upper = std::upper_bound(v.begin(), v.end(), 30); // 第一个大于 30
```

`binary_search` 只回答是否存在；`lower_bound`、`upper_bound` 返回位置，还能描述一段等价元素。它们在 `vector` 上只需 O(log n) 次比较；面对非随机访问迭代器，比较次数虽仍是对数级，移动迭代器却可能是线性的。有序关联容器应优先使用自己的 `find` / `lower_bound`，以利用树结构。

计数同样有按值和按条件两种版本：

```cpp
#include <algorithm>
#include <iostream>
#include <vector>

std::vector<int> v = {1, 2, 3, 2, 4, 2, 5};

const auto twos = std::count(v.begin(), v.end(), 2);
std::cout << "2 出现了 " << twos << " 次\n";

const auto evens = std::count_if(v.begin(), v.end(), [](int x) {
    return x % 2 == 0;
});
std::cout << "偶数有 " << evens << " 个\n";
```

==== 变换与修改算法

查找只观察数据，`transform` 则把计算结果写到输出范围。若目标不是插入迭代器，它必须事先拥有足够空间：

```cpp
#include <algorithm>
#include <vector>

std::vector<int> v = {1, 2, 3, 4, 5};
std::vector<int> result(v.size());

std::transform(v.begin(), v.end(), result.begin(),
    [](int x) { return x * 2; });
// result = {2, 4, 6, 8, 10}

std::transform(v.begin(), v.end(), v.begin(),
    [](int x) { return x * x; });
// v = {1, 4, 9, 16, 25}

std::vector<int> a = {1, 2, 3};
std::vector<int> b = {4, 5, 6};
std::vector<int> sum(a.size());

std::transform(a.begin(), a.end(), b.begin(), sum.begin(),
    [](int x, int y) { return x + y; });
// sum = {5, 7, 9}
```

二元版本只接收第一段范围的终点，因此这里还约定 `b` 至少与 `a` 一样长。示例中的整数运算在给定值域内可表示；换成外部输入后，乘法和加法的有符号溢出边界仍需单独处理。

`for_each` 常用于对每项执行副作用，不过简单循环有时更直接：

```cpp
#include <algorithm>
#include <iostream>
#include <vector>

std::vector<int> v = {1, 2, 3, 4, 5};

std::for_each(v.begin(), v.end(), [](int x) {
    std::cout << x << " ";
});
std::cout << '\n';

std::for_each(v.begin(), v.end(), [](int& x) {
    x *= 2;
});
// v = {2, 4, 6, 8, 10}
```

复制也要求目标范围足够大；若目标容器从空开始，则用插入迭代器增长：

```cpp
#include <algorithm>
#include <iterator>
#include <vector>

std::vector<int> src = {1, 2, 3, 4, 5};
std::vector<int> dst(src.size());

std::copy(src.begin(), src.end(), dst.begin());
// dst = {1, 2, 3, 4, 5}

std::vector<int> evens;
std::copy_if(src.begin(), src.end(), std::back_inserter(evens),
    [](int x) { return x % 2 == 0; });
// evens = {2, 4}
```

源区间和目标区间若发生不符合算法要求的重叠，结果可能无效；向右搬动重叠区间时通常要看 `copy_backward`。普通赋值则可用 `fill`，按条件改值可用 `replace_if`：

```cpp
#include <algorithm>
#include <vector>

std::vector<int> v(10);
std::fill(v.begin(), v.end(), 42);
// v = {42, 42, 42, 42, 42, 42, 42, 42, 42, 42}

std::fill(v.begin(), v.begin() + 5, 0);
// v = {0, 0, 0, 0, 0, 42, 42, 42, 42, 42}

std::replace_if(v.begin(), v.end(),
    [](int x) { return x % 2 == 0; }, 0);
```

名字最容易造成误会的是 `remove`：通用算法拿不到容器对象，无法改变它的大小，只能把要保留的元素移到前面并返回新的逻辑终点。逻辑终点之后仍是有效对象，但它们的值处于未指定状态：

```cpp
#include <algorithm>
#include <vector>

std::vector<int> v = {1, 2, 3, 2, 4, 2, 5};

auto newEnd = std::remove(v.begin(), v.end(), 2);
v.erase(newEnd, v.end());
// v = {1, 3, 4, 5}

std::vector<int> v2 = {1, 2, 3, 4, 5, 6};
v2.erase(std::remove_if(v2.begin(), v2.end(),
    [](int x) { return x % 2 == 0; }), v2.end());
// v2 = {1, 3, 5}
```

C++20 为 `vector`、`deque` 等容器提供 `std::erase` / `std::erase_if`，把这两步封装起来。`list::remove` 则是容器成员，行为不同，调用时要分清名字属于哪一层。

`unique` 采用相同的“返回逻辑终点”模式，而且只合并相邻的等价元素：

```cpp
#include <algorithm>
#include <vector>

std::vector<int> v = {1, 1, 2, 2, 2, 3, 3, 4};

auto newEnd = std::unique(v.begin(), v.end());
v.erase(newEnd, v.end());
// v = {1, 2, 3, 4}

std::vector<int> v2 = {3, 1, 2, 1, 3, 2, 1};
std::sort(v2.begin(), v2.end());
v2.erase(std::unique(v2.begin(), v2.end()), v2.end());
// v2 = {1, 2, 3}
```

先排序再去重会丢掉原有顺序；若顺序有意义，应选择保序去重策略，而不是机械套用这两行。反转则直接交换范围两端的元素：

```cpp
#include <algorithm>
#include <vector>

std::vector<int> v = {1, 2, 3, 4, 5};
std::reverse(v.begin(), v.end());
// v = {5, 4, 3, 2, 1}
```

==== 数值算法

`<numeric>` 中的算法也围绕范围工作。`accumulate` 的初始值不只是“从几开始”，还决定累加器类型：

```cpp
#include <numeric>
#include <string>
#include <vector>

std::vector<int> v = {1, 2, 3, 4, 5};

int sum = std::accumulate(v.begin(), v.end(), 0);  // 15

int product = std::accumulate(v.begin(), v.end(), 1,
    [](int acc, int x) { return acc * x; });  // 120

std::vector<std::string> words = {"Hello", " ", "World"};
std::string sentence = std::accumulate(words.begin(), words.end(),
    std::string{});  // "Hello World"
```

若元素是 `double` 却把初始值写成整数 `0`，每一步都会按整数累加器转换，可能悄悄截断；应写 `0.0`。反过来，整数范围可能需要更宽的累加器。示例乘积在 1 到 5 内可表示，不说明更长输入不会发生有符号溢出。

`inner_product` 将两段范围逐项组合，再累加结果：

```cpp
#include <numeric>
#include <vector>

std::vector<double> a = {1.0, 2.0, 3.0};
std::vector<double> b = {4.0, 5.0, 6.0};

double dot = std::inner_product(a.begin(), a.end(), b.begin(), 0.0);
// 1*4 + 2*5 + 3*6 = 32
```

这里同样约定第二段至少与第一段一样长。`partial_sum` 把每一步的前缀结果写到目标范围：

```cpp
#include <numeric>
#include <vector>

std::vector<int> v = {1, 2, 3, 4, 5};
std::vector<int> prefix(v.size());

std::partial_sum(v.begin(), v.end(), prefix.begin());
// prefix = {1, 3, 6, 10, 15}
```

`iota` 则从给定起点反复递增并写入：

```cpp
#include <numeric>
#include <vector>

std::vector<int> v(10);
std::iota(v.begin(), v.end(), 1);
// v = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
```

这些算法保证的主要是调用次序和操作次数，并不自动提供高精度或溢出检查。对长浮点序列，舍入误差会随数据与累加顺序变化；对整数，结果超出类型范围时要在进入算法前选择更宽类型或检查边界。

==== 范围 for 循环

C++11 的范围 `for` 把“从 `begin` 走到 `end`”这一常见模式藏进语法里。只需要逐项访问时，它比手写迭代器更贴近意图：

```cpp
#include <iostream>
#include <vector>

std::vector<int> v = {1, 2, 3, 4, 5};

for (auto it = v.begin(); it != v.end(); ++it) {
    std::cout << *it << " ";
}

for (int x : v) {
    std::cout << x << " ";
}
```

循环变量的声明决定每轮是复制、只读借用还是可写借用：

```cpp
#include <iostream>
#include <string>
#include <vector>

std::vector<std::string> names = {"Alice", "Bob", "Charlie"};

// 每轮复制一个 string，修改 name 不影响容器。
for (std::string name : names) {
    std::cout << name << '\n';
}

// 只读且不复制元素。
for (const std::string& name : names) {
    std::cout << name << '\n';
}

// 经由引用修改容器中的元素。
for (std::string& name : names) {
    name = "Mr. " + name;
}

for (const auto& name : names) {
    std::cout << name << '\n';
}
```

`const auto&` 是只读大型元素的常见选择，但小整数按值读取更简单。需要处理代理引用等特殊迭代器时，`auto&&` 也可能合适；不要把某一种写法当成所有元素类型的硬规则。

范围 `for` 通过语言规定的 `begin` / `end` 查找工作，因此不只适用于标准容器：

```cpp
#include <iostream>
#include <map>
#include <string>
#include <vector>

std::vector<int> vec = {1, 2, 3};
for (int x : vec) { /* ... */ }

int arr[] = {1, 2, 3, 4, 5};
for (int x : arr) { /* ... */ }

for (int x : {1, 2, 3, 4, 5}) { /* ... */ }

std::string str = "Hello";
for (char c : str) { /* ... */ }

std::map<std::string, int> ages = {{"Alice", 25}, {"Bob", 30}};
for (const auto& [name, age] : ages) {
    std::cout << name << ": " << age << '\n';
}
```

它不会直接暴露当前索引。索引本来就是业务数据时，可以显式维护；需要随机访问位置时，普通下标循环更清楚：

```cpp
#include <cstddef>
#include <iostream>
#include <vector>

std::vector<int> v = {10, 20, 30, 40, 50};

for (std::size_t i = 0; i < v.size(); ++i) {
    std::cout << i << ": " << v[i] << '\n';
}

std::size_t index = 0;
for (const auto& x : v) {
    std::cout << index << ": " << x << '\n';
    ++index;
}
```

范围循环仍受容器失效规则约束。循环内部给 `vector` 追加元素、删除当前位置或触发 rehash，都可能使语言内部保存的迭代器失效；需要结构性修改时，应采用该容器支持的显式迭代器模式或先收集修改请求。

==== 算法与谓词

谓词把“什么算匹配”交给调用者。查找、计数等算法通常接收一元谓词，排序则接收比较两个元素的二元谓词。普通函数可以直接作为谓词：

```cpp
#include <algorithm>
#include <vector>

bool isPositive(int x) {
    return x > 0;
}

std::vector<int> v = {-2, -1, 0, 1, 2};
auto count = std::count_if(v.begin(), v.end(), isPositive);  // 2
```

需要携带配置时，函数对象可以把阈值存进对象：

```cpp
#include <algorithm>
#include <iostream>
#include <vector>

struct GreaterThan {
    int threshold;

    explicit GreaterThan(int value) : threshold(value) {}

    bool operator()(int x) const {
        return x > threshold;
    }
};

std::vector<int> v = {1, 5, 3, 8, 2, 9, 4};
auto it = std::find_if(v.begin(), v.end(), GreaterThan(6));
if (it != v.end()) {
    std::cout << *it << '\n';  // 8
}
```

短小且只在调用处使用的规则，常用 lambda 就地表达：

```cpp
#include <algorithm>
#include <vector>

std::vector<int> v = {1, 5, 3, 8, 2, 9, 4};

auto it = std::find_if(v.begin(), v.end(), [](int x) {
    return x > 6;
});

int threshold = 6;
auto it2 = std::find_if(v.begin(), v.end(), [threshold](int x) {
    return x > threshold;
});

int sum = 0;
std::for_each(v.begin(), v.end(), [&sum](int x) {
    sum += x;
});
```

这里按值捕获 `threshold`，lambda 保存自己的副本；`sum` 按引用捕获，所以调用会修改外部变量。若 lambda 被保存到更长生命周期或交给其他线程，引用捕获的生命周期与同步问题要重新检查，后文会专门展开。

`<functional>` 还提供了一组常见运算函数对象。省略模板实参的透明形式（如 `std::greater<>`）能接受可比较的混合类型：

```cpp
#include <algorithm>
#include <functional>
#include <vector>

std::vector<int> v = {30, 10, 50, 20, 40};

std::sort(v.begin(), v.end(), std::greater<>{});
// v = {50, 40, 30, 20, 10}

// 还包括 less、plus、minus、multiplies、divides、
// negate、equal_to 和 not_equal_to 等。
```

谓词不应偷偷修改参与判断的元素；排序比较器还必须在全部待排值上保持严格弱序。代码能编译只说明调用形式匹配，不会替我们证明这两个语义条件。

==== 在 RoboMaster 开发中的应用

下面三个片段展示算法在机器人数据流中的常见形状。它们仍是教学模型：筛选阈值、单位、时序和故障策略要由具体系统定义，示例能编译不等于感知或控制策略已经验证。

目标列表通常先做有效性与业务筛选，再参与排序。这样比较器面对的距离、置信度都是有限数，能维持严格弱序：

```cpp
#include <algorithm>
#include <cmath>
#include <iostream>
#include <iterator>
#include <vector>

struct Target {
    int id;
    double distance;
    double confidence;
    bool isEnemy;
};

std::vector<Target> targets;

std::vector<Target> enemies;
enemies.reserve(targets.size());
std::copy_if(targets.begin(), targets.end(), std::back_inserter(enemies),
    [](const Target& target) {
        return target.isEnemy &&
               std::isfinite(target.distance) && target.distance >= 0.0 &&
               std::isfinite(target.confidence) &&
               target.confidence >= 0.5 && target.confidence <= 1.0;
    });

std::sort(enemies.begin(), enemies.end(),
    [](const Target& left, const Target& right) {
        return left.distance < right.distance;
    });

auto bestTarget = std::max_element(enemies.begin(), enemies.end(),
    [](const Target& left, const Target& right) {
        return left.confidence < right.confidence;
    });

if (bestTarget != enemies.end()) {
    std::cout << "候选目标 ID: " << bestTarget->id << '\n';
}
```

这里把低置信度过滤阈值写成 0.5 只是为了展示流程。“最高置信度”也不必然等于实际系统的最佳射击目标；真正策略可能还要联合距离、可见时间和运动状态。

统计传感器数据时，空输入和非有限值不能靠一个看似合理的数字掩盖。下面选择返回 `nullopt` 表示当前无法给出摘要，并在调用 `minmax_element` 前保证范围非空：

```cpp
#include <algorithm>
#include <cmath>
#include <numeric>
#include <optional>
#include <stdexcept>
#include <vector>

struct SensorReading {
    double timestamp;
    double value;
};

struct ReadingSummary {
    double minimum;
    double maximum;
    double mean;
    bool allWithinExpectedRange;
    bool hasLargeDeviation;
};

std::optional<ReadingSummary> summarizeReadings(
    const std::vector<SensorReading>& readings,
    double lower, double upper, double maxDeviation) {
    if (!std::isfinite(lower) || !std::isfinite(upper) ||
        !std::isfinite(maxDeviation) || lower > upper || maxDeviation < 0.0) {
        throw std::invalid_argument("invalid summary limits");
    }
    if (readings.empty() ||
        std::any_of(readings.begin(), readings.end(),
            [](const SensorReading& reading) {
                return !std::isfinite(reading.value);
            })) {
        return std::nullopt;
    }

    const double sum = std::accumulate(
        readings.begin(), readings.end(), 0.0,
        [](double total, const SensorReading& reading) {
            return total + reading.value;
        });
    if (!std::isfinite(sum)) {
        return std::nullopt;
    }
    const double mean = sum / static_cast<double>(readings.size());

    const auto [minIt, maxIt] = std::minmax_element(
        readings.begin(), readings.end(),
        [](const SensorReading& left, const SensorReading& right) {
            return left.value < right.value;
        });

    const bool allWithin = std::all_of(
        readings.begin(), readings.end(),
        [lower, upper](const SensorReading& reading) {
            return reading.value >= lower && reading.value <= upper;
        });

    const bool hasLargeDeviation = std::any_of(
        readings.begin(), readings.end(),
        [mean, maxDeviation](const SensorReading& reading) {
            return std::abs(reading.value - mean) > maxDeviation;
        });

    return ReadingSummary{
        minIt->value, maxIt->value, mean, allWithin, hasLargeDeviation};
}
```

这个两遍摘要适合解释算法组合，不是数值统计库。数据很长、量级悬殊或误差预算严格时，普通浮点求和的舍入误差仍需用目标数据评估；`nullopt` 是空输入还是坏数据，真实接口也可能需要用更丰富的错误类型区分。

固定数量电机的逐项运算可以直接落在 `array` 上。先限幅当前命令，再用同一索引计算误差：

```cpp
#include <algorithm>
#include <array>
#include <cmath>

std::array<double, 4> motorSpeeds = {1000.0, 2000.0, 1500.0, 1800.0};
const std::array<double, 4> targetSpeeds = {1200.0, 2200.0, 1600.0, 2000.0};

constexpr double maxSpeed = 5000.0;
std::transform(motorSpeeds.begin(), motorSpeeds.end(), motorSpeeds.begin(),
    [maxSpeed](double speed) {
        return std::clamp(speed, -maxSpeed, maxSpeed);
    });

std::array<double, 4> errors{};
std::transform(targetSpeeds.begin(), targetSpeeds.end(),
               motorSpeeds.begin(), errors.begin(),
               [](double target, double current) {
                   return target - current;
               });

constexpr double allowedError = 10.0;
const bool allOnTarget = std::all_of(errors.begin(), errors.end(),
    [allowedError](double error) {
        return std::abs(error) <= allowedError;
    });
```

这个判断只覆盖数组中四个有限示例值；速度单位、限幅位置和允许误差都应来自电机与控制器契约。

==== 算法的效率考虑

算法名相同，成本还会受迭代器类别和元素操作影响。以下是本章经典 C++17 调用的主要数量级：

```
算法                    主要复杂度                         关键前提
sort                    O(n log n) 次比较                  随机访问，严格弱序
stable_sort             有缓冲时 O(n log n)，否则可到 O(n log^2 n)  随机访问
find / count            O(n)                              可逐项读取
binary_search           O(log n) 次比较                   已按同一规则排序
transform / copy        O(n)                              输出范围足够
unique                  O(n)                              只处理相邻等价项
reverse                 O(n)                              双向迭代器
minmax_element          O(n)                              范围可比较
accumulate              O(n)                              累加器类型能表达中间值
```

表格没有显示所有常数，也没有把元素复制、比较器成本和分配算成同一个单位。更实用的判断方式是：

- 数据频繁更新且要按键查找时，评估关联容器；数据较小、连续遍历多时，线性查找或排序后的 `vector` 仍可能更合适。
- “先排序再多次二分”只有在查询次数足以摊薄排序成本、且期间不会反复打乱顺序时才划算。
- 标准容器的 `size()` 通常为常数复杂度，`end()` 也往往便宜；为省一次调用而缓存尾后迭代器，若循环中会修改容器，反而可能保存一个失效值。
- 输出数量可估计时，可用 `reserve()` 配合插入迭代器减少扩容；不能估计时先保证边界正确，再测量分配是否重要。
- 元素很大或比较器昂贵时，移动、间接排序或预计算键可能改变成本，但应在真实数据和目标构建上验证。

==== 自定义类型与算法

算法并不要求每个类型把所有运算符都重载齐全，只要求当前调用所用的操作成立。若一种顺序是类型天然且稳定的语义，可以把它定义在类型上：

```cpp
#include <algorithm>
#include <tuple>
#include <vector>

struct GridPoint {
    int x;
    int y;

    bool operator<(const GridPoint& other) const {
        return std::tie(x, y) < std::tie(other.x, other.y);
    }

    bool operator==(const GridPoint& other) const {
        return x == other.x && y == other.y;
    }
};

std::vector<GridPoint> points = {{1, 2}, {3, 1}, {2, 3}};
std::sort(points.begin(), points.end());

const GridPoint target = {3, 1};
auto it = std::find(points.begin(), points.end(), target);
```

若“按离原点距离”只是某一次操作的视角，就把规则留在调用处。距离相同再按坐标打破平局，使输出顺序确定：

```cpp
#include <algorithm>
#include <cmath>
#include <tuple>
#include <vector>

std::vector<GridPoint> points = {{1, 2}, {3, 1}, {2, 3}};

std::sort(points.begin(), points.end(),
    [](const GridPoint& left, const GridPoint& right) {
        const double leftDistance = std::hypot(left.x, left.y);
        const double rightDistance = std::hypot(right.x, right.y);
        if (leftDistance != rightDistance) {
            return leftDistance < rightDistance;
        }
        return std::tie(left.x, left.y) < std::tie(right.x, right.y);
    });
```

这里用整数坐标，所以转成 `double` 后的 `hypot` 不会遇到输入 NaN。若类型本身保存浮点坐标，必须先决定非有限值是否合法，并确保比较器在全部合法对象上形成严格弱序。反复计算昂贵排序键也可能成为热点，数据量大时可以预计算后再测量。

迭代器让算法看见一段范围，谓词和运算符则告诉算法元素能做什么。下一节进一步追到这些接口背后：模板如何让同一个容器或算法在满足要求的多种类型上生成实现，以及编译器报错为什么常常会指向这些要求。

=== 模板基础

`vector<int>` 与 `vector<std::string>` 共享同一套容器结构，`sort` 也能处理许多不同元素。它们并非真的接受“任意类型”：元素必须满足当前操作所需的构造、赋值或比较要求。模板（template）做的，是把这些尚未确定的类型和常量写成参数，等使用处给出具体实参后再形成对应的类或函数。

因此，学习模板的重点不只是尖括号语法，还包括三个问题：哪些部分保持通用，具体类型必须提供什么，错误会在定义阶段还是实例化阶段暴露。

==== 为什么需要模板

先看一个刻意朴素的交换函数：

```cpp
void swapInt(int& a, int& b) {
    int temp = a;
    a = b;
    b = temp;
}
```

若同样的步骤又要用于 `double`，复制一份只改类型当然能工作：

```cpp
void swapDouble(double& a, double& b) {
    double temp = a;
    a = b;
    b = temp;
}
```

重载可以统一函数名，却没有消除重复的函数体：

```cpp
void swap(int& a, int& b) { /* ... */ }
void swap(double& a, double& b) { /* ... */ }
void swap(std::string& a, std::string& b) { /* ... */ }
```

三段逻辑真正变化的只有类型。函数模板把这个变化点命名出来；当某个类型不支持函数体里的操作时，那次实例化就不成立，而不是在运行时猜测类型。

==== 函数模板

类型模板参数可用 `typename` 或 `class` 声明，两者在这里含义相同：

```cpp
template <typename T>
void swapValues(T& a, T& b) {
    T temp = a;
    a = b;
    b = temp;
}
```

这段实现要求 `T` 能复制构造并复制赋值，所以它不是对所有类型都可用。标准库的 `std::swap` 还会利用移动语义，工程代码通常直接使用它；这里保留展开步骤只是为了观察类型推导：

```cpp
#include <string>

int main() {
    int x = 10, y = 20;
    swapValues(x, y);  // T 推导为 int

    double a = 1.5, b = 2.5;
    swapValues(a, b);  // T 推导为 double

    std::string s1 = "hello", s2 = "world";
    swapValues(s1, s2);  // T 推导为 std::string

    return 0;
}
```

从模板和模板实参形成具体实体的过程称为实例化（instantiation）。这里不需要运行时类型分支，但最终是否内联、是否合并相同机器码、生成多少代码，仍由实现、优化选项和使用方式决定，不能仅凭“用了模板”断言汇编与手写版本完全相同。

多数时候让编译器推导即可，也可以显式写出模板实参：

```cpp
swapValues<int>(x, y);
swapValues<double>(a, b);
```

`swapValues(x, y)` 还要求两个实参把同一个 `T` 推导成一致类型；一个 `int` 与一个 `double` 不会因为都能做算术就自动选出公共 `T`。显式实参有时能解决无法推导的问题，也可能引入转换，因此仍要检查调用语义。

不同位置确实允许不同类型时，可以声明多个参数：

```cpp
#include <iostream>
#include <string>

template <typename T, typename U>
void printPair(const T& first, const U& second) {
    std::cout << "(" << first << ", " << second << ")\n";
}

int main() {
    printPair(10, 3.14);                    // T=int, U=double
    printPair(std::string("mode"), 42);     // T=string, U=int
    return 0;
}
```

`printPair` 又引入了一项要求：两个类型都必须能写入 `std::ostream`。原先若直接传 `std::vector<int>`，标准库没有为它提供通用 `operator<<`，这次实例化就会失败。模板复用了代码，却不会自动发明缺失的操作。

==== 类模板

类也能把成员类型参数化。先用只保存一个值的 `Box` 看清基本结构：

```cpp
template <typename T>
class Box {
public:
    explicit Box(const T& value) : data_(value) {}

    const T& value() const noexcept { return data_; }
    void setValue(const T& value) { data_ = value; }

private:
    T data_;
};
```

在 C++17 之前，使用这类模板时通常显式写出类型：

```cpp
#include <iostream>
#include <string>

int main() {
    Box<int> number(42);
    Box<std::string> text(std::string("hello"));

    std::cout << number.value() << ' ' << text.value() << '\n';
    return 0;
}
```

C++17 的类模板参数推导（CTAD）可以从构造调用形成候选类型：

```cpp
Box number(42);                  // Box<int>
Box text(std::string("hello")); // Box<std::string>
Box measurement(3.14);          // Box<double>
```

推导结果由构造函数和推导指引决定，并不保证就是我们心里想的拥有类型；字符串字面量、数组和引用尤其值得检查。需要明确语义时，直接写 `Box<std::string>` 没有什么不好。

稍实用一点的类模板可以组合已有容器，而不必为了展示模板再手写一套易错的内存管理。下面包装一个只暴露栈操作的序列：

```cpp
#include <cstddef>
#include <stdexcept>
#include <string>
#include <vector>

template <typename T>
class SimpleStack {
public:
    void push(const T& value) {
        data_.push_back(value);
    }

    void pop() {
        if (data_.empty()) {
            throw std::out_of_range("cannot pop an empty stack");
        }
        data_.pop_back();
    }

    T& top() {
        if (data_.empty()) {
            throw std::out_of_range("cannot read an empty stack");
        }
        return data_.back();
    }

    const T& top() const {
        if (data_.empty()) {
            throw std::out_of_range("cannot read an empty stack");
        }
        return data_.back();
    }

    bool empty() const noexcept { return data_.empty(); }
    std::size_t size() const noexcept { return data_.size(); }

private:
    std::vector<T> data_;
};

int main() {
    SimpleStack<int> numbers;
    numbers.push(10);
    numbers.push(20);

    SimpleStack<std::string> words;
    words.push("hello");

    return 0;
}
```

`push(const T&)` 要求 `T` 能从该引用复制到 `vector`；`top()` 返回的引用只在底层 `vector` 没有使它失效时可用。资源管理、拷贝控制和异常清理由 `vector` 承担，这比一个缺少拷贝构造、扩容回滚和容量溢出检查的教学裸数组更能说明“复用可靠组件”的价值。

==== 成员函数模板

普通类也可以把某个成员函数做成模板。例如，`Printer` 本身没有类型参数，每次 `print` 调用再独立推导：

```cpp
#include <iostream>

class Printer {
public:
    template <typename T>
    void print(const T& value) const {
        std::cout << value << '\n';
    }

    template <typename T, typename U>
    void printPair(const T& first, const U& second) const {
        std::cout << first << ", " << second << '\n';
    }
};

int main() {
    Printer p;
    p.print(42);           // 实例化 print<int>
    p.print(3.14);         // 实例化 print<double>
    p.print("hello");      // 实例化 print<const char*>
    p.printPair(1, "one"); // 实例化 printPair<int, const char*>
    return 0;
}
```

这里仍要求传入值可写入输出流。类模板也可以有自己的成员模板，例如允许 `Box<U>` 显式转换成 `Box<T>`：

```cpp
template <typename T>
class Box {
public:
    explicit Box(const T& value) : data_(value) {}

    template <typename U>
    explicit Box(const Box<U>& other) : data_(other.value()) {}

    const T& value() const noexcept { return data_; }

private:
    T data_;
};

int main() {
    Box<int> integer(42);
    Box<double> real(integer);  // 成员模板中的 U 为 int
    return 0;
}
```

构造函数写成 `explicit`，让可能损失信息的跨类型转换必须出现在调用点。只有当 `U` 保存的值能用来初始化 `T` 时，对应构造才成立；模板声明本身不会证明所有 `U -> T` 都安全。

==== 非类型模板参数

模板实参也可以是编译期值。允许作为非类型模板参数（non-type template parameter）的类型随语言标准扩展；本节先使用最常见的 `std::size_t`，把容量直接放进类型：

```cpp
#include <array>
#include <cstddef>

template <typename T, std::size_t N>
class FixedArray {
public:
    T& operator[](std::size_t index) {
        return data_[index];
    }

    const T& operator[](std::size_t index) const {
        return data_[index];
    }

    T& at(std::size_t index) {
        return data_.at(index);
    }

    const T& at(std::size_t index) const {
        return data_.at(index);
    }

    constexpr std::size_t size() const noexcept { return N; }

private:
    std::array<T, N> data_{};
};

int main() {
    FixedArray<int, 5> arr1;
    FixedArray<double, 10> arr2;

    for (std::size_t i = 0; i < arr1.size(); ++i) {
        arr1[i] = static_cast<int>(i * 10);
    }

    return 0;
}
```

`FixedArray<int, 5>` 与 `FixedArray<int, 6>` 是不同类型，容量可参与编译期推理。底层 `std::array` 还正确处理 `N == 0`；若直接声明原生成员 `T data[N]`，零长度在标准 C++ 中并不成立。这个简化包装会值初始化所有元素，因此构造非空数组还要求 `T` 能这样初始化；`operator[]` 不检查边界，`at()` 才报告越界。

值参数也能驱动递归实例化。下面把输入限制在 `std::uint64_t` 能表达的阶乘范围：

```cpp
#include <cstdint>
#include <iostream>

template <unsigned N>
struct Factorial {
    static_assert(N <= 20, "factorial result does not fit in uint64_t");
    static constexpr std::uint64_t value =
        static_cast<std::uint64_t>(N) * Factorial<N - 1>::value;
};

template <>
struct Factorial<0> {
    static constexpr std::uint64_t value = 1;
};

int main() {
    constexpr auto fact5 = Factorial<5>::value;
    std::cout << "5! = " << fact5 << '\n';
    return 0;
}
```

这是一种经典模板元编程写法，也顺便预览了全特化作为递归终点。现代 C++ 中，普通 `constexpr` 函数往往更容易阅读；模板递归适合教学机制，不必为了“在编译期”而强行采用。

==== 默认模板参数

模板参数和函数参数一样可以有默认值。继续用 `std::array` 保存数据，避免重新引入零长度原生数组：

```cpp
#include <array>
#include <cstddef>

template <typename T = int, std::size_t N = 10>
class Buffer {
public:
    T& operator[](std::size_t index) { return data_[index]; }
    const T& operator[](std::size_t index) const { return data_[index]; }
    constexpr std::size_t size() const noexcept { return N; }

private:
    std::array<T, N> data_{};
};

int main() {
    Buffer<> buf1;              // T=int, N=10
    Buffer<double> buf2;        // T=double, N=10
    Buffer<char, 256> buf3;     // T=char, N=256
    return 0;
}
```

标准容器也使用默认参数。下面只是为了说明形状而写的简化声明，不等同于标准头文件中的全部约束与声明细节：

```cpp
template <typename T, typename Allocator = std::allocator<T>>
class vector;
```

因此日常写 `std::vector<int>` 时，分配器参数采用默认值；只有确有分配策略需求时才显式改变它。

==== 模板特化

当某个具体类型需要不同实现时，可以特化模板。特化不应悄悄改变调用者依赖的基本语义，否则同一模板名会因类型不同表现得像两个无关接口。

全特化（full specialization）固定全部模板参数：

```cpp
#include <iostream>
#include <string>
#include <string_view>

template <typename T>
class TypeInfo {
public:
    static constexpr std::string_view name() { return "unknown"; }
};

template <>
class TypeInfo<int> {
public:
    static constexpr std::string_view name() { return "int"; }
};

template <>
class TypeInfo<double> {
public:
    static constexpr std::string_view name() { return "double"; }
};

template <>
class TypeInfo<std::string> {
public:
    static constexpr std::string_view name() { return "std::string"; }
};

int main() {
    std::cout << TypeInfo<int>::name() << '\n';
    std::cout << TypeInfo<double>::name() << '\n';
    std::cout << TypeInfo<std::string>::name() << '\n';
    std::cout << TypeInfo<char>::name() << '\n';
    return 0;
}
```

类模板还能偏特化（partial specialization）一部分形状，例如所有指针类型或所有定长数组类型：

```cpp
#include <cstddef>
#include <iostream>

template <typename T>
class TypeCategory {
public:
    void print() const { std::cout << "ordinary type\n"; }
};

template <typename T>
class TypeCategory<T*> {
public:
    void print() const { std::cout << "pointer type\n"; }
};

template <typename T, std::size_t N>
class TypeCategory<T[N]> {
public:
    void print() const { std::cout << "array extent " << N << '\n'; }
};

int main() {
    TypeCategory<int>{}.print();
    TypeCategory<int*>{}.print();
    TypeCategory<double[10]>{}.print();
    return 0;
}
```

函数模板不能偏特化；通常用函数重载、类型萃取或约束表达相应分支。特化与重载的选择还会影响名称查找和匹配规则，基础代码中不必一开始就用它们代替清晰的普通接口。

==== 模板与编译

模板常让错误位置显得“离调用很远”，原因在于检查分两个时机发生。编译器读到模板定义时会检查语法和不依赖模板参数的名称；依赖 `T` 的表达式是否成立，通常要等具体实例化时才能决定。未实例化不等于任意语法错误都能藏住。

隐式实例化还要求编译器在使用点能看到所需定义，因此模板定义通常放在头文件，或放在由头文件包含的实现文件中：

```cpp
// my_template.hpp
#ifndef RMCV_MY_TEMPLATE_HPP
#define RMCV_MY_TEMPLATE_HPP

template <typename T>
class MyTemplate {
public:
    void foo();
};

template <typename T>
void MyTemplate<T>::foo() {
    // 依赖 T 的实现也在调用方可见。
}

#endif
```

也可以在源文件中为一组已知类型做显式实例化，但那是另一种组织与构建权衡，不是“模板永远不能放 `.cpp`”。下面的比较表达式依赖 `T`，所以 `NoCompare` 的失败会在对应调用尝试实例化时暴露：

```cpp
template <typename T>
T maximum(const T& a, const T& b) {
    return (a > b) ? a : b;
}

struct NoCompare {
    int value;
};

int main() {
    int result = maximum(10, 20);

    NoCompare nc1{1}, nc2{2};
    // auto bad = maximum(nc1, nc2); // 错误：NoCompare 没有 operator>

    return 0;
}
```

读模板诊断时，先找“由哪个调用实例化了哪个模板”，再找第一项不满足的操作，通常比从最末尾的类型展开向上猜更有效。C++20 概念能把部分要求提前写进接口，稍后会看到。

==== 实际应用示例

模板适合表达“流程相同、类型或容量不同”的部分。第一个例子是简化的范围限制函数：

```cpp
#include <stdexcept>

template <typename T>
T clampValue(const T& value, const T& minVal, const T& maxVal) {
    if (maxVal < minVal) {
        throw std::invalid_argument("minimum must not exceed maximum");
    }
    if (value < minVal) {
        return minVal;
    }
    if (maxVal < value) {
        return maxVal;
    }
    return value;
}

double speed = clampValue(1250.0, -1000.0, 1000.0);
int pwm = clampValue(300, 0, 255);
```

它要求 `T` 可比较、可复制返回，并假设 `<` 对全部合法值形成合适顺序。浮点 NaN 不满足这一直觉，因此真实数值接口仍要先规定非有限输入的策略。C++17 已提供 `std::clamp`；这里重写一遍是为了显露模板要求，而不是建议重复造轮子。

数值模板还常需要主动限制类型。这个 PID 教学类只接受浮点类型，并在提交内部状态前检查时间步和中间结果：

```cpp
#include <algorithm>
#include <cmath>
#include <stdexcept>
#include <type_traits>

template <typename T>
class PIDController {
    static_assert(std::is_floating_point_v<T>,
                  "PIDController requires a floating-point type");

public:
    PIDController(T kp, T ki, T kd, T minOutput, T maxOutput)
        : kp_(kp), ki_(ki), kd_(kd),
          minOutput_(minOutput), maxOutput_(maxOutput) {
        if (!std::isfinite(kp_) || !std::isfinite(ki_) ||
            !std::isfinite(kd_) || !std::isfinite(minOutput_) ||
            !std::isfinite(maxOutput_) || minOutput_ > maxOutput_) {
            throw std::invalid_argument("invalid PID configuration");
        }
    }

    T compute(T setpoint, T measurement, T dt) {
        if (!std::isfinite(setpoint) || !std::isfinite(measurement) ||
            !std::isfinite(dt) || dt <= T{}) {
            throw std::invalid_argument("invalid PID input");
        }

        const T error = setpoint - measurement;
        if (!std::isfinite(error)) {
            throw std::overflow_error("PID error is not finite");
        }

        const T nextIntegral = integral_ + error * dt;
        const T derivative = hasPrevious_ ? (error - lastError_) / dt : T{};
        const T rawOutput =
            kp_ * error + ki_ * nextIntegral + kd_ * derivative;

        if (!std::isfinite(nextIntegral) || !std::isfinite(derivative) ||
            !std::isfinite(rawOutput)) {
            throw std::overflow_error("PID state is not finite");
        }

        integral_ = nextIntegral;
        lastError_ = error;
        hasPrevious_ = true;
        return std::clamp(rawOutput, minOutput_, maxOutput_);
    }

    void reset() noexcept {
        integral_ = T{};
        lastError_ = T{};
        hasPrevious_ = false;
    }

private:
    T kp_;
    T ki_;
    T kd_;
    T minOutput_;
    T maxOutput_;
    T integral_{};
    T lastError_{};
    bool hasPrevious_ = false;
};

int main() {
    PIDController<double> speedController(
        1.5, 0.1, 0.05, -1000.0, 1000.0);
    PIDController<float> angleController(
        2.0f, 0.0f, 0.1f, -100.0f, 100.0f);
    return 0;
}
```

`float` 与 `double` 在这里共享接口，不代表它们在控制精度、吞吐或目标硬件上可以随意互换。该类也没有抗积分饱和、采样抖动处理或经过验证的离散化方案；检查覆盖的是示例的数值状态转换，不是控制效果。

容量是编译期常量时，可以做一个不在运行时扩容的环形缓冲区。用 `optional` 表示尚未放置元素，就不必先默认构造 N 个 `T`：

```cpp
#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>

template <typename T, std::size_t N>
class RingBuffer {
    static_assert(N > 0, "ring buffer capacity must be positive");

public:
    bool push(const T& value) {
        if (full()) {
            return false;
        }
        slots_[tail_].emplace(value);
        tail_ = (tail_ + 1) % N;
        ++count_;
        return true;
    }

    bool pop(T& output) {
        if (empty()) {
            return false;
        }

        output = *slots_[head_];
        slots_[head_].reset();
        head_ = (head_ + 1) % N;
        --count_;
        return true;
    }

    bool empty() const noexcept { return count_ == 0; }
    bool full() const noexcept { return count_ == N; }
    std::size_t size() const noexcept { return count_; }

private:
    std::array<std::optional<T>, N> slots_{};
    std::size_t head_ = 0;
    std::size_t tail_ = 0;
    std::size_t count_ = 0;
};

RingBuffer<double, 100> sensorHistory;
RingBuffer<std::uint8_t, 256> rxBuffer;
```

这个版本的 `push` 依赖 `T` 可复制构造，`pop` 依赖可复制赋值；若给 `output` 赋值抛出异常，索引与槽位还没有改变。固定容量也不自动意味着线程安全、无锁或满足实时截止时间，这些都需要额外设计与测量。

类型参数还可以只承担“标签”角色，把底层表示相同、业务含义不同的 ID 分开：

```cpp
#include <stdexcept>

template <typename Tag>
class Id {
public:
    explicit Id(int value) : value_(value) {
        if (value < 0) {
            throw std::invalid_argument("ID must be nonnegative");
        }
    }

    int value() const noexcept { return value_; }

    bool operator==(const Id& other) const noexcept {
        return value_ == other.value_;
    }

private:
    int value_;
};

struct MotorTag {};
struct TargetTag {};

using MotorId = Id<MotorTag>;
using TargetId = Id<TargetTag>;

MotorId motor(1);
TargetId target(1);
// bool same = (motor == target); // 错误：两个 ID 是不同类型
```

这种“强类型 ID”没有运行时注册表或全局状态，只让编译器阻止把目标编号误传给电机接口。原始表示相同，不代表领域含义应该隐式混用。

==== 模板的优缺点

模板的价值在于把类型关系留在编译期：一份实现可以服务多种满足要求的类型，错误组合无需等到运行时才发现，优化器也能看到具体操作并决定是否内联或特化。它很适合容器、算法、单位标签和固定容量等抽象。

代价同样具体。模板定义常进入头文件，可能扩大重编译范围；多组实例可能增加编译时间和代码体积，不过链接器与优化器也可能合并或消除部分代码。若接口没有写清要求，诊断会沿着多层实例化展开。调试并非因为“模板天生不可调”，而是要知道当前查看的是哪一组实参形成的实例。

所以目标不是把所有函数都改成模板，而是在确有共同结构时参数化变化点，并让要求尽量靠近接口。

==== 现代 C++ 中的模板改进

C++11 引入变参模板（variadic templates），C++17 的折叠表达式又让参数包不必手写递归终点：

```cpp
#include <iostream>

template <typename... Args>
void printLine(const Args&... args) {
    ((std::cout << args << ' '), ...);
    std::cout << '\n';
}

int main() {
    printLine(1, 2.5, "hello", 'c');
    return 0;
}
```

这要求参数包中的每一项都可写入流。`auto` 与 `decltype` 则能让返回类型跟随表达式：

```cpp
template <typename T, typename U>
auto add(const T& a, const U& b) -> decltype(a + b) {
    return a + b;
}

// C++14 可以省略尾置返回类型
template <typename T, typename U>
auto multiply(const T& a, const U& b) {
    return a * b;
}
```

两个函数分别要求 `a + b` 或 `a * b` 是有效表达式；返回类型可能与任一输入类型都不同。C++20 的概念（concepts）可以把这类要求命名并放进接口：

```cpp
#include <concepts>

template <typename T>
concept GreaterComparable = std::copy_constructible<T> &&
    requires(const T& a, const T& b) {
    { a > b } -> std::convertible_to<bool>;
};

template <GreaterComparable T>
T maximum(const T& a, const T& b) {
    return (a > b) ? a : b;
}
```

这个概念检查“表达式存在、结果能转成 `bool`、值可复制返回”，却不会数学地证明 `>` 在所有值上形成良好顺序。概念改善了约束位置和许多诊断，不替代语义设计。

到这里已经足以读懂常见容器与算法的模板外形。SFINAE、类型萃取和更深的元编程可以按项目需要继续学习。下一节转向一个具体的类模板家族：智能指针怎样把动态对象的所有权和销毁动作纳入 RAII。

=== 智能指针
// unique_ptr
// shared_ptr
// weak_ptr
// 何时使用哪种
// === 智能指针

动态对象最难的往往不是取得地址，而是回答“谁负责让它活着，又由谁销毁”。把这份责任散落在多个 `new`、`delete`、提前返回和异常分支里，很容易漏掉一次或执行两次。

智能指针是把动态对象所有权放进 RAII 对象的类模板。`unique_ptr` 表达独占，`shared_ptr` 表达共同拥有，`weak_ptr` 观察一个共享对象而不延长其生命。它们能自动执行与所有权相匹配的销毁动作，却不会自动修复共享环、悬空的非拥有指针、对象内部的数据竞争或错误的所有权图。若值成员、`vector` 或其他容器已经能直接拥有对象，也不必为了“现代 C++”再额外分配一层。

==== 原始指针的问题

下面的数组在正常路径上会释放，但两个提前离开的路径都绕过了 `delete[]`：

```cpp
#include <stdexcept>

void processData(bool someError, bool anotherError) {
    int* data = new int[1000];

    if (someError) {
        return;  // data 泄漏
    }

    if (anotherError) {
        throw std::runtime_error("处理失败"); // data 泄漏
    }

    delete[] data;
}
```

试图在每个出口手工补删除也很脆弱：删除后抛出的异常若又被外层清理代码捕获，可能重复释放。对于单纯的动态整数序列，最直接的修复其实是让 `vector` 拥有元素：

```cpp
#include <stdexcept>
#include <vector>

void processData(bool someError, bool anotherError) {
    std::vector<int> data(1000);

    if (someError) {
        return;
    }
    if (anotherError) {
        throw std::runtime_error("处理失败");
    }
}
```

无论怎样离开函数，`data` 的析构函数都会处理它拥有的存储。智能指针采用同样的 RAII 思路，适合必须单独动态分配的对象，例如运行时选择具体派生类型或向外转移所有权。

==== unique_ptr：独占所有权

`std::unique_ptr<T>` 表示这一个指针对象独占所管理对象。它销毁或被重置时调用删除器；若它为空，则什么也不销毁。

```cpp
#include <iostream>
#include <memory>

class Motor {
public:
    explicit Motor(int id) : id_(id) {
        std::cout << "Motor " << id_ << " 创建\n";
    }
    ~Motor() {
        std::cout << "Motor " << id_ << " 销毁\n";
    }
    void run() const {
        std::cout << "Motor " << id_ << " 运行中\n";
    }

private:
    int id_;
};

int main() {
    auto motor1 = std::make_unique<Motor>(1);
    auto motor2 = std::make_unique<Motor>(2);

    motor1->run();
    motor2->run();

    if (motor1) {
        std::cout << "motor1 非空\n";
    }

    return 0;
}
```

`std::make_unique` 从 C++14 起可用。它把分配与所有权对象的构造放在一次表达式里，避免手写 `new`、类型重复和删除形式不匹配；需要自定义删除器时则要直接构造相应的 `unique_ptr`。

独占所有权不能复制，但可以显式转移：

```cpp
#include <iostream>
#include <memory>
#include <utility>

auto ptr1 = std::make_unique<Motor>(1);

// auto ptr2 = ptr1;  // 错误：复制会产生两个独占所有者

std::unique_ptr<Motor> ptr2 = std::move(ptr1);

if (!ptr1) {
    std::cout << "所有权已经转给 ptr2\n";
}
```

`std::move` 本身只是允许选择移动操作；`unique_ptr` 的移动构造保证把源指针置空。下一节会解释这套语言机制。

几个底层操作值得认识，但 `release()` 尤其容易把 RAII 责任重新丢回调用者：

```cpp
#include <memory>

auto ptr = std::make_unique<Motor>(1);

Motor* observer = ptr.get(); // 非拥有，只在 ptr 管理的对象仍存活时有效

Motor* released = ptr.release();
delete released;             // 这里必须接回销毁责任

ptr = std::make_unique<Motor>(2);
ptr.reset();                  // 销毁 Motor(2) 并置空

auto ptr2 = std::make_unique<Motor>(3);
ptr.swap(ptr2);
```

`get()` 不延长生命周期，`observer` 可能在 `reset()`、赋值或所有者析构后悬空。`release()` 主要用于把所有权交给明确接管的旧接口；普通业务代码若随手调用它，很容易重新制造泄漏。

数组有专门的 `unique_ptr<T[]>` 形式：

```cpp
#include <memory>

auto arr = std::make_unique<int[]>(100);
arr[0] = 10;
arr[99] = 20;
```

它会使用 `delete[]`，但下标仍不检查边界；需要大小、迭代器和检查访问时，`vector` 通常更合适。

函数签名可以直接说明所有权是否转移：

```cpp
#include <memory>
#include <utility>

std::unique_ptr<Motor> createMotor(int id) {
    return std::make_unique<Motor>(id);
}

void takeOwnership(std::unique_ptr<Motor> motor) {
    if (motor) {
        motor->run();
    }
}

void useMotor(Motor& motor) {
    motor.run();
}

void useMotorPtr(Motor* motor) {
    if (motor != nullptr) {
        motor->run();
    }
}

int main() {
    auto motor = createMotor(1);

    useMotor(*motor);           // 传递引用
    useMotorPtr(motor.get());   // 传递原始指针

    takeOwnership(std::move(motor));

    return 0;
}
```

返回 `unique_ptr` 表示调用者取得所有权；按值接收表示函数接管所有权。只借用时，非空对象用引用，可选对象用指针，并由调用方保证借用期间对象仍然存活。

==== shared_ptr：共享所有权

`std::shared_ptr<T>` 让多个指针对象共同拥有一个动态对象。它们共享控制块，其中记录强所有者等信息；最后一个强所有者释放后，被管理对象才会销毁。

```cpp
#include <iostream>
#include <memory>
#include <string>
#include <utility>

class Sensor {
public:
    explicit Sensor(std::string name) : name_(std::move(name)) {
        std::cout << "Sensor " << name_ << " 创建\n";
    }
    ~Sensor() {
        std::cout << "Sensor " << name_ << " 销毁\n";
    }

    const std::string& name() const noexcept { return name_; }

private:
    std::string name_;
};

int main() {
    auto sensor1 = std::make_shared<Sensor>("IMU");
    std::cout << "strong owners: " << sensor1.use_count() << '\n';

    {
        std::shared_ptr<Sensor> sensor2 = sensor1;
        std::shared_ptr<Sensor> sensor3 = sensor1;
        std::cout << "strong owners: " << sensor1.use_count() << '\n';
    }

    std::cout << "strong owners: " << sensor1.use_count() << '\n';
    return 0;
}
```

`use_count()` 适合观察和调试，不适合用来写“计数为 1 就可以无锁修改”之类的同步逻辑；并发环境中计数随时可能变化。不同 `shared_ptr` 实例共同管理控制块的操作可以安全并发进行，也不代表 `Sensor` 对象本身线程安全。

`std::make_shared<T>(args...)` 常把对象和控制块放进一次分配中，因此可减少分配次数并改善局部性。它也有权衡：只要还有 `weak_ptr` 指向控制块，合并分配占用的整块存储可能继续保留；自定义删除器等场景也要采用其他构造方式。这里应把它看作常用默认入口，而不是所有情形都更快的定理。

“许多模块会访问对象”本身还不足以选择共享所有权；只借用一个由场景或系统拥有的对象，用引用或观察指针更清楚。`shared_ptr` 适合多个参与者确实都要独立延长同一对象生命的情形。例如，生产者把一份不可变快照交给两个可能晚些完成的消费者：

```cpp
#include <memory>
#include <utility>

struct FrameSnapshot {
    int sequence;
};

class Recorder {
public:
    void retain(std::shared_ptr<const FrameSnapshot> frame) {
        frame_ = std::move(frame);
    }

private:
    std::shared_ptr<const FrameSnapshot> frame_;
};

class Analyzer {
public:
    void retain(std::shared_ptr<const FrameSnapshot> frame) {
        frame_ = std::move(frame);
    }

private:
    std::shared_ptr<const FrameSnapshot> frame_;
};

int main() {
    auto frame = std::make_shared<const FrameSnapshot>(FrameSnapshot{42});

    Recorder recorder;
    Analyzer analyzer;
    recorder.retain(frame);
    analyzer.retain(frame);

    frame.reset(); // 两个消费者仍共同维持快照生命
    return 0;
}
```

这里的 `const` 只阻止经由这些指针修改快照，并不让任意相关代码自动线程安全。真正的并发发布还要处理消费者之间的同步和队列协议。

==== weak_ptr：弱引用

`std::weak_ptr<T>` 观察一个 `shared_ptr` 所属的控制块，但不增加对象的强所有者数量，因此不会让对象继续存活。控制块本身通常要保留到弱观察者也消失之后。它常用来表示所有权图中的反向边，或“有就使用、没有就放弃”的缓存和观察关系。

若双向链表的两个方向都写成强所有权，局部变量销毁后节点仍彼此维持生命：

```cpp
#include <iostream>
#include <memory>
#include <string>
#include <utility>

class Node {
public:
    explicit Node(std::string name) : name_(std::move(name)) {
        std::cout << "Node " << name_ << " 创建\n";
    }
    ~Node() {
        std::cout << "Node " << name_ << " 销毁\n";
    }

    std::shared_ptr<Node> next;
    std::shared_ptr<Node> prev; // 这条反向边也拥有对象

private:
    std::string name_;
};

int main() {
    auto node1 = std::make_shared<Node>("A");
    auto node2 = std::make_shared<Node>("B");

    node1->next = node2;
    node2->prev = node1;

    return 0;
}
```

离开 `main` 时，两个局部 `shared_ptr` 消失，但 `node1->next` 与 `node2->prev` 仍各保留一个强所有者，所以两个析构函数都不会运行。若约定 `next` 是拥有方向、`prev` 只是反向观察，后者应改为弱指针：

```cpp
#include <iostream>
#include <memory>
#include <string>
#include <utility>

class Node {
public:
    explicit Node(std::string name) : name_(std::move(name)) {
        std::cout << "Node " << name_ << " 创建\n";
    }
    ~Node() {
        std::cout << "Node " << name_ << " 销毁\n";
    }

    std::shared_ptr<Node> next;
    std::weak_ptr<Node> prev;

private:
    std::string name_;
};

int main() {
    auto node1 = std::make_shared<Node>("A");
    auto node2 = std::make_shared<Node>("B");

    node1->next = node2;
    node2->prev = node1;

    return 0;
}
```

这次局部所有者消失后，强所有权链能够依次释放。具体析构日志顺序来自对象与成员销毁过程，不应拿来推导更一般图结构的释放顺序；关键是强所有权图中不再有环。

弱指针不能直接解引用。`lock()` 尝试取得一个临时强所有者：对象仍在就返回非空 `shared_ptr`，已经销毁就返回空。

```cpp
std::weak_ptr<Sensor> weakSensor;

{
    auto sensor = std::make_shared<Sensor>("GPS");
    weakSensor = sensor;

    if (auto owner = weakSensor.lock()) {
        std::cout << "Sensor 有效: " << owner->name() << '\n';
    }
}

if (auto owner = weakSensor.lock()) {
    std::cout << owner->name() << '\n';
} else {
    std::cout << "Sensor 已失效\n";
}
```

不要先用 `expired()` 判断、稍后再假定 `lock()` 一定成功；并发释放可能发生在两步之间。直接检查 `lock()` 的返回值，得到的非空 `shared_ptr` 会在当前使用期间维持对象生命。

缓存也可以只保存弱引用，使缓存本身不阻止对象回收：

```cpp
#include <memory>
#include <string>
#include <unordered_map>
#include <utility>

class Texture {
public:
    explicit Texture(std::string name) : name_(std::move(name)) {}

private:
    std::string name_;
};

class ResourceCache {
public:
    std::shared_ptr<Texture> getTexture(const std::string& name) {
        auto it = cache_.find(name);
        if (it != cache_.end()) {
            if (auto sp = it->second.lock()) {
                return sp;
            }
            cache_.erase(it);
        }

        auto texture = std::make_shared<Texture>(name);
        cache_.emplace(name, texture);
        return texture;
    }

private:
    std::unordered_map<std::string, std::weak_ptr<Texture>> cache_;
};
```

这只是单线程缓存骨架，还假设 `Texture(name)` 完成所需加载。并发调用需要同步，也要决定同名资源是否允许重复加载、失败怎样报告以及何时清理长期未访问的过期键。

==== 智能指针与自定义删除器

智能指针默认配对 `delete`，而 C 接口常要求 `fclose`、`camera_close` 等专用释放函数。删除器把这条配对规则变成类型的一部分。

```cpp
#include <cstdio>
#include <memory>
#include <stdexcept>

struct FileCloser {
    void operator()(std::FILE* file) const noexcept {
        if (file != nullptr) {
            std::fclose(file);
        }
    }
};

using FilePtr = std::unique_ptr<std::FILE, FileCloser>;

FilePtr openFile(const char* path, const char* mode) {
    std::FILE* raw = std::fopen(path, mode);
    if (raw == nullptr) {
        throw std::runtime_error("failed to open file");
    }
    return FilePtr(raw);
}

int main() {
    auto file = openFile("data.txt", "w");
    if (std::fputs("hello\n", file.get()) == EOF) {
        throw std::runtime_error("failed to write file");
    }
    return 0;
}
```

析构路径不能方便地向调用者报告 `fclose` 失败；若刷新或关闭错误会影响业务正确性，应另设可检查的显式提交/关闭操作，同时仍保留删除器作为兜底清理。`shared_ptr` 也能保存类型擦除后的自定义删除器，但“释放函数特殊”不等于资源就需要共享所有权。

同样的模式可以包住硬件库返回的不透明句柄：

```cpp
#include <memory>

struct CameraHandle;

CameraHandle* camera_open(const char* device);
void camera_close(CameraHandle* handle);

struct CameraCloser {
    void operator()(CameraHandle* handle) const noexcept {
        if (handle != nullptr) {
            camera_close(handle);
        }
    }
};

using CameraPtr = std::unique_ptr<CameraHandle, CameraCloser>;

CameraPtr openCamera(const char* device) {
    return CameraPtr(camera_open(device));
}
```

`openCamera` 用空指针表示库报告的打开失败，成功句柄离开作用域时调用 `camera_close`。真实封装还要按照该硬件 API 的线程、关闭次序和错误码契约补齐行为。

==== enable_shared_from_this

已经由 `shared_ptr` 拥有的对象，有时需要把同一个共享所有权交给外部。绝不能拿裸 `this` 新建另一个控制块：

```cpp
#include <memory>

class BadExample {
public:
    std::shared_ptr<BadExample> getShared() {
        return std::shared_ptr<BadExample>(this); // 新建了独立控制块
    }
};

auto ptr1 = std::make_shared<BadExample>();
auto ptr2 = ptr1->getShared();
```

两个控制块最终都会尝试删除同一对象，行为未定义。`std::enable_shared_from_this<T>` 让对象连接到原有控制块：

```cpp
#include <iostream>
#include <memory>

class Session : public std::enable_shared_from_this<Session> {
public:
    std::shared_ptr<Session> sharedSelf() {
        return shared_from_this();
    }

    std::weak_ptr<Session> weakSelf() noexcept {
        return weak_from_this(); // C++17
    }
};

int main() {
    auto first = std::make_shared<Session>();
    auto second = first->sharedSelf();
    std::cout << first.use_count() << '\n'; // 2
    return 0;
}
```

对象必须已经由兼容的 `shared_ptr` 管理，并公开、无歧义地继承这个基类；否则 `shared_from_this()` 会抛出 `std::bad_weak_ptr`。在构造函数中调用时，共享关系通常尚未建立。`weak_from_this()` 可用于只需观察自己的场景，但注册回调时仍要检查回调与对象是否会彼此形成新的强引用环。

==== 如何选择智能指针

先问对象是否必须动态分配。直接值成员最清楚；运行时多态、跨作用域转移、可选的大对象或稳定地址等需求，才可能把所有权推向智能指针。随后按所有权图选择：

- 一个明确所有者用 `unique_ptr`。工厂返回、类成员独占资源、容器保存不同派生对象，都是常见场景。
- 多个参与者确实都能独立延长对象生命时用 `shared_ptr`。仅仅“很多地方会读它”通常仍是一个所有者加若干借用者。
- 共享体系里不延长生命的观察边用 `weak_ptr`，每次使用前 `lock()`；它也用来切断强所有权环。
- 必须存在且只借用的参数用 `T&` / `const T&`，可空借用可用 `T*`。裸指针在这里表达观察，不负责 `delete`。

函数参数本身就是所有权文档：

```cpp
#include <memory>

class Job;
class Data;

void consume(std::unique_ptr<Job> job);      // 接管独占所有权
void retain(std::shared_ptr<const Data> data); // 保存一份共享所有权
void inspect(const Data& data);              // 非空、只读借用
void inspectOptional(const Data* data);       // 可空、只读借用
```

按值接收 `shared_ptr` 表明函数会取得或至少有权保留一份所有权；若函数只在调用期间查看对象，直接接收 `const Data&` 比 `const shared_ptr<Data>&` 更少耦合。无论采用哪种借用形式，接口都必须保证被借对象覆盖整个调用期。

==== 性能考虑

`unique_ptr` 的所有权操作通常只需移动一个指针和删除器状态。无状态删除器常能利用空基类优化，使对象大小接近裸指针，但标准不保证固定字节数；函数指针或有状态删除器会改变布局。

`shared_ptr` 需要控制块，复制和销毁共享所有者要同步更新计数；实现通常使用原子操作，这在高频跨线程复制时可能可测。解引用对象本身仍是通过保存的对象指针完成，并不是每次访问都必然比裸指针多一层控制块跳转。`weak_ptr::lock()` 则要尝试安全地增加强计数。

`make_shared` 常减少一次分配，但共分配也会让内存块保留到最后一个弱引用消失。自定义删除器、对象与控制块生命周期差异、分配器以及峰值内存都可能改变选择。

先让指针类型准确表达所有权，再在目标平台测量热点。若性能分析显示共享计数争用明显，真正要检查的通常是所有权是否划得过宽、任务边界是否在反复复制，而不是把 `shared_ptr` 偷换成没有生命周期协议的裸指针。

==== 实际应用示例

最后把所有权关系放进一个小型系统。`RobotSystem` 本身按值创建；它独占多态传感器，同时与外部调用者共同拥有一份只读目标快照，追踪器只观察该快照：

```cpp
#include <cmath>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <string_view>
#include <utility>
#include <vector>

class Sensor {
public:
    virtual ~Sensor() = default;
    virtual void update() = 0;
    virtual std::string_view name() const noexcept = 0;
};

class IMU : public Sensor {
public:
    IMU() { std::cout << "IMU 初始化\n"; }
    ~IMU() override { std::cout << "IMU 关闭\n"; }

    void update() override {
        std::cout << "IMU 更新数据\n";
    }

    std::string_view name() const noexcept override { return "IMU"; }
};

class Camera : public Sensor {
public:
    Camera() { std::cout << "Camera 初始化\n"; }
    ~Camera() override { std::cout << "Camera 关闭\n"; }

    void update() override {
        std::cout << "Camera 捕获图像\n";
    }

    std::string_view name() const noexcept override { return "Camera"; }
};

class Target {
public:
    Target(int id, double x, double y) : id_(id), x_(x), y_(y) {
        if (id < 0 || !std::isfinite(x) || !std::isfinite(y)) {
            throw std::invalid_argument("invalid target snapshot");
        }
        std::cout << "Target " << id_ << " 创建\n";
    }

    ~Target() {
        std::cout << "Target " << id_ << " 销毁\n";
    }

    int id() const noexcept { return id_; }

private:
    int id_;
    double x_;
    double y_;
};

class Tracker {
public:
    void observe(const std::shared_ptr<const Target>& target) {
        target_ = target;
    }

    void track() const {
        if (auto target = target_.lock()) {
            std::cout << "正在追踪目标 " << target->id() << '\n';
        } else {
            std::cout << "当前没有可用目标\n";
        }
    }

private:
    std::weak_ptr<const Target> target_;
};

class RobotSystem {
public:
    RobotSystem() {
        std::cout << "机器人系统启动\n";
    }

    ~RobotSystem() {
        std::cout << "机器人系统关闭\n";
    }

    void addSensor(std::unique_ptr<Sensor> sensor) {
        if (!sensor) {
            throw std::invalid_argument("sensor must not be null");
        }
        sensors_.push_back(std::move(sensor));
        std::cout << "添加传感器: " << sensors_.back()->name() << '\n';
    }

    void setTarget(std::shared_ptr<const Target> target) {
        if (!target) {
            throw std::invalid_argument("target must not be null");
        }
        currentTarget_ = std::move(target);
        tracker_.observe(currentTarget_);
    }

    void clearTarget() {
        currentTarget_.reset();
    }

    void updateSensors() {
        for (const auto& sensor : sensors_) {
            sensor->update();
        }
    }

    void trackTarget() const {
        tracker_.track();
    }

private:
    std::vector<std::unique_ptr<Sensor>> sensors_;
    std::shared_ptr<const Target> currentTarget_;
    Tracker tracker_;
};

int main() {
    RobotSystem robot;
    robot.addSensor(std::make_unique<IMU>());
    robot.addSensor(std::make_unique<Camera>());

    auto target = std::make_shared<const Target>(7, 100.0, 200.0);
    robot.setTarget(target);

    robot.updateSensors();
    robot.trackTarget();

    target.reset();
    robot.trackTarget(); // RobotSystem 仍拥有目标

    robot.clearTarget();
    robot.trackTarget(); // weak_ptr 已无法取得对象

    return 0;
}
```

传感器的具体类型在运行时不同，所以 `vector<unique_ptr<Sensor>>` 既保留多态，也让系统成为唯一所有者。目标快照在外部与系统之间短暂共享，`Tracker` 的弱观察不会延长生命。`RobotSystem` 自身没有跨作用域所有权需求，作为作用域内的局部值对象最清楚。

这组工具能让正确的所有权图自动清理资源，却不能保证借用方永不越界、对象操作线程安全或共享图没有环。下一节会解释刚才多次出现的 `std::move`：它如何允许 `unique_ptr` 以及其他资源拥有者转移内部状态，又为什么“写了 move”不等于一定发生了低成本移动。


=== 右值引用与移动语义
// 可选/进阶
// std::move
// 移动构造函数
// === 右值引用与移动语义

前一节里，`unique_ptr` 不能复制，却可以交给另一个所有者。这个“交出以后，原对象不再拥有资源”的动作，就是移动语义最直观的用法。不过，移动并不是专门给指针准备的性能开关。它首先表达的是一种许可：这个对象原来的值可以被取走，接收方不必保留一份相同的副本。

C++11 用右值引用表示这份许可，并提供 `std::move` 和 `std::forward` 帮助我们把许可传给合适的重载。理解这一节时，最好把三个问题分开：表达式是什么值类别、某个类型是否提供移动操作，以及这次移动究竟要做多少工作。三者有关，却不能画上等号。

==== 从问题出发

先看一份带日志的数据块。真正的数据交给 `vector` 管理，我们只记录复制和移动走了哪条路径：

```cpp
#include <cstddef>
#include <iostream>
#include <utility>
#include <vector>

class BigData {
public:
    explicit BigData(std::size_t size) : data_(size) {
        std::cout << "构造 " << data_.size() << " 个整数\n";
    }

    BigData(const BigData& other) : data_(other.data_) {
        std::cout << "复制 " << data_.size() << " 个整数\n";
    }

    BigData(BigData&& other) noexcept : data_(std::move(other.data_)) {
        std::cout << "移动数据块\n";
    }

    BigData& operator=(const BigData&) = default;
    BigData& operator=(BigData&&) noexcept = default;

private:
    std::vector<int> data_;
};

BigData createBigData() {
    BigData result(1'000'000);
    return result;
}

int main() {
    BigData data = createBigData();
}
```

不要先入为主地数出“两次复制”。在现代 C++ 中，编译器通常可以用命名返回值优化（NRVO）直接在 `data` 的位置构造 `result`；即使这次没有进行 NRVO，从函数返回非 `const` 局部对象时，语言规则也允许选择移动构造。哪条路径实际发生，取决于表达式、类型提供的操作和复制消除规则，可以用日志或编译器工具观察，不能只凭源码猜测。

如果确实走到移动构造，`vector` 可以把自己管理的状态转交给新对象，而不必逐个复制整数。这正是移动语义想解决的问题：源对象的旧值不再需要时，类型可以选择一种比复制更合适的转移方式。这里说“可以”很重要——移动的具体成本仍由类型决定。

==== 左值与右值

“左值能放在等号左边，右值只能放右边”是个容易失灵的口诀。`const int x` 是左值，却不能被赋值；某些右值又可以调用成员函数。更稳妥的入门视角是看表达式有没有可辨认的身份：

- *左值（lvalue）*通常指向一个有身份的对象，例如变量名或返回左值引用的函数调用。
- *纯右值（prvalue）*通常用于计算或初始化一个值，例如 `x + 5` 和按值返回的函数调用。
- *将亡值（xvalue）*仍指向有身份的对象，但表示它的资源可以被复用；`std::move(x)` 产生的表达式就是典型例子。

纯右值和将亡值合称右值。完整规则还有更多细节，不过这三个类别已经足够解释本节代码：

```cpp
int x = 10;        // 表达式 x 是左值
int y = x + 5;     // x + 5 是纯右值，表达式 y 仍是左值

int* p = &x;       // 可以取得 x 所指对象的地址
// int* q = &(x + 5);  // 内置取地址运算符不能这样作用于纯右值

std::string name = "robot";          // name 是左值
std::string full = name + "_front";  // 拼接表达式是纯右值
std::string next = std::move(name);   // std::move(name) 是将亡值
```

函数的返回类型也会影响调用表达式的值类别：

```cpp
std::string makeName();      // 调用结果是纯右值
std::string& currentName();  // 调用结果是左值

std::string a = makeName();
currentName() = "sentry";
```

变量有名字，不代表它保存的对象永远不能移动；它只意味着“写出这个变量名”得到的是左值表达式。接下来 `std::move` 做的，就是显式把这个左值表达式转换成将亡值。

==== 右值引用

C++11 引入右值引用，用 `&&` 表示。普通的右值引用可以绑定到右值，从而让重载区分“只借来看”和“允许取走”：

```cpp
int x = 10;

int& lref = x;       // 左值引用绑定到左值
// int& bad1 = 10;   // 非 const 左值引用不能这样绑定纯右值

int&& rref = 10;     // 右值引用绑定到纯右值
int&& sum = x + 5;
// int&& bad2 = x;   // 普通右值引用不能直接绑定左值

const int& view = 10; // const 左值引用也可以绑定，并延长临时量生命期
```

最后一行不是偶然留下的历史包袱。`const T&` 让函数在不修改实参的前提下统一观察左值和临时值，临时量在某些直接绑定场景下还会获得相应的生命期延长；具体生命期仍要按绑定位置判断，不能把一个局部引用再返回出去。

还有一个很容易漏掉的细节：*有名字的右值引用变量，在表达式中仍是左值*。

```cpp
void inspect(const std::string&) { std::cout << "只读观察\n"; }
void inspect(std::string&&)      { std::cout << "可消费对象\n"; }

std::string&& ref = std::string("camera");
inspect(ref);            // ref 有名字，所以选择 const& 版本
inspect(std::move(ref)); // 再次明确允许消费，选择 && 版本
```

这条规则让函数体不会因为参数类型写着 `&&` 就悄悄反复取走它；每一次继续转移，都要由代码明确表达。

==== 移动构造函数与移动赋值运算符

移动构造函数用源对象创建新对象，移动赋值则替换一个已经存在的对象。给刚才的类补上日志版本，接口大致如下：

```cpp
class BigData {
public:
    explicit BigData(std::size_t size) : data_(size) {}

    BigData(const BigData& other) : data_(other.data_) {
        std::cout << "复制构造\n";
    }

    BigData& operator=(const BigData& other) {
        data_ = other.data_;
        std::cout << "复制赋值\n";
        return *this;
    }

    BigData(BigData&& other) noexcept
        : data_(std::move(other.data_)) {
        std::cout << "移动构造\n";
    }

    BigData& operator=(BigData&& other) noexcept {
        data_ = std::move(other.data_);
        std::cout << "移动赋值\n";
        return *this;
    }

private:
    std::vector<int> data_;
};
```

这里让 `vector` 负责资源和异常安全，`BigData` 不再重复手写 `new[]`、`delete[]`。移动函数只把成员移动过去，源 `vector` 随后仍可析构或重新赋值。标准只保证多数标准库对象在移动后处于有效但未指定的状态；某个自定义类型若承诺移动后为空，应把它写进该类型的接口契约并保持这个不变量。

`noexcept` 也不是装饰性的“优化标签”。它向调用方承诺函数不会让异常逃出；承诺若被违反，程序会调用 `std::terminate`。只有在所有成员移动和函数体确实不会抛出时才应声明。上例使用默认分配器的 `vector` 移动构造满足这个条件，因此这项声明成立。

移动常被形容为“偷走指针”，这个比喻对 `unique_ptr` 和许多动态容器很形象，却不是语言保证。类型完全可以把“移动”实现成逐元素操作，甚至在没有可用移动重载时退回复制。`std::array<T, N>` 的移动就需要移动它的元素，工作量通常随 `N` 增长。判断成本要看具体类型和具体操作，而不是只看参数里有没有 `&&`。

==== std::move

临时值通常能自然匹配右值重载；有名字的对象则需要你明确表示“旧值可以被取走”。`std::move` 就是这个标记：

```cpp
#include <utility>

int main() {
    BigData source(1'000'000);
    BigData destination = std::move(source);

    // source 仍然是一个对象，可以析构，也可以重新赋值。
    source = BigData(32);
}
```

`std::move` 本身不搬数据，也不把 `source` 清空。它只进行值类别转换，让重载决议有机会选择接收右值引用的操作。真正发生复制、转移还是别的动作，由随后被调用的构造函数、赋值运算符或普通函数决定。它的作用可以近似理解为下面这个转换，实际标准库实现会处理更多类型细节：

```cpp
template <typename T>
std::remove_reference_t<T>&& move(T&& value) noexcept {
    return static_cast<std::remove_reference_t<T>&&>(value);
}
```

更准确地说，对象的状态是在某个消费操作执行后改变，而不是在求值 `std::move(source)` 的瞬间改变。若只写一行 `std::move(source);` 却不把结果交给任何操作，`source` 不会因此被移动。

移动后的对象仍然存在。你总可以在满足类型前置条件的情况下析构或重新赋值；还能做哪些观察，要看该类型的契约。例如 `unique_ptr` 明确保证移动后为空，标准库容器通常只给出“有效但未指定”的一般保证，不能统一假设它们的大小是零：

```cpp
std::string s1 = "Hello, World!";
std::string s2 = std::move(s1);

std::cout << s2 << '\n'; // 接收方获得原来的值
// 不依赖 s1 此刻的具体文本。

s1 = "New Value";
std::cout << s1 << '\n';
```

==== 何时使用 std::move

最清楚的使用场景，是接口本来就在转移所有权。以 `unique_ptr` 为例：

```cpp
void takeOwnership(std::unique_ptr<Motor> motor) {
    // motor 在这个作用域内拥有电机对象
}

auto motor = std::make_unique<Motor>(1);
takeOwnership(std::move(motor));
// unique_ptr 的契约保证 motor 现在为空
```

按值接收的“汇点参数”也常在函数内部移动进成员。调用者传左值时会先复制一份，传右值时则可移动进参数：

```cpp
class Topic {
public:
    explicit Topic(std::string name) : name_(std::move(name)) {}

private:
    std::string name_;
};
```

从容器元素或成员中移动会改变原对象，应当让接口名字表达这种变化，并建立清楚的移动后状态。例如“取走全部数据”可以写成：

```cpp
class Container {
public:
    std::vector<int> takeData() {
        return std::exchange(data_, {});
    }

private:
    std::vector<int> data_;
};
```

`std::exchange` 返回旧值并把成员设成显式的空值，因此调用后的状态不是猜出来的。若只对 `data_` 写 `std::move`，结果也可以成立，但成员随后是什么状态要服从 `vector` 的移动后契约。

从函数返回同类型的局部变量时，通常直接写变量名：

```cpp
BigData createData() {
    BigData data(1000);
    return data; // 给 NRVO 留出机会；未消除时可隐式选择移动
}
```

把这里写成 `return std::move(data);` 会让表达式不再满足针对命名局部变量的 NRVO 形式，所以通常没有帮助。不要把这条建议扩大到所有返回语句：返回成员、解引用结果或与返回类型不同的对象时，规则需要分别判断。

对 `const` 对象调用 `std::move` 得到的是 `const T&&`，不能去掉 `const`。多数类型的移动构造接收 `T&&`，于是常见重载集合会转而选择 `const T&` 复制构造，但这仍取决于该类型实际提供的重载：

```cpp
const std::string source = "immutable";
std::string copy = std::move(source); // 对 std::string 而言，这里复制
```

这也是为什么“为了快，到处加 `std::move`”并不可取。它会改变可选重载和源对象状态，却不提供通用的性能保证。

==== 完美转发与转发引用

模板中的 `T&&` 有时不是普通右值引用。只有当 `T` 正在由这个函数调用推导，并且写法符合相应形式时，它才是*转发引用*；类模板中已经确定的 `T&&`、`const T&&` 都不自动获得这个性质：

```cpp
template <typename T>
void relay(T&& value) { // T 由调用实参推导：转发引用
    // 名字 value 在函数体内仍是左值表达式
}

int x = 10;
relay(x);  // T 推导为 int&，引用折叠后参数是 int&
relay(10); // T 推导为 int，参数是 int&&
```

转发函数通常不消费所有实参，而是把调用者原来的值类别保留下来。`std::forward<T>` 根据推导出的 `T` 有条件地转换：

```cpp
void process(int&)  { std::cout << "左值版本\n"; }
void process(int&&) { std::cout << "右值版本\n"; }

template <typename T>
void relay(T&& value) {
    process(std::forward<T>(value));
}

int main() {
    int x = 10;
    relay(x);  // process(int&)
    relay(10); // process(int&&)
}
```

它最常出现在构造包装器和容器的 `emplace` 类接口中。下面的小工厂只是为了展示转发；实际创建 `unique_ptr` 应优先使用标准库已经提供的 `std::make_unique`：

```cpp
template <typename T, typename... Args>
T makeObject(Args&&... args) {
    return T(std::forward<Args>(args)...);
}
```

“完美”描述的是尽量保留值类别与 `const` 等性质，不代表构造必然零拷贝，也不验证被调用接口的业务语义。

==== 移动语义与标准库

标准库广泛支持移动语义，但不同操作有不同条件。以 `vector` 扩容为例，它需要把旧存储区的元素迁到新存储区。为了在异常时尽量保留原容器，常见路径会在下面两者间选择：

- 元素可无异常移动时，迁移元素；
- 移动可能抛出且元素可复制时，可能改用复制。

若元素只能移动且移动可能抛出，容器能提供的异常保证还会受标准规定和具体失败位置限制。因此，应根据实现是否真的不抛来声明 `noexcept`，而不是为了迫使容器选择某条路径而作出不实承诺。

```cpp
std::vector<BigData> blocks;
blocks.reserve(2);

blocks.emplace_back(1000);
blocks.emplace_back(2000);
blocks.emplace_back(3000); // 这里可能触发扩容和元素迁移
```

移动标准容器本身也不能统一写成“必然 O(1)”。移动构造一个使用兼容分配器的 `vector`，通常可以接管其存储；带特定分配器的移动构造、分配器不传播且不相等时的移动赋值，则可能逐元素处理。`string` 还可能采用小字符串等实现策略。需要复杂度承诺时，应查对应类型、操作和标准版本，而不是从“支持移动”推出结论。

==== 零法则与五法则

C++11 以后，一个直接管理资源的类可能要同时考虑析构、复制构造、复制赋值、移动构造和移动赋值，这就是常说的“五法则”。它不是“写了一个就必须机械写满五个”，而是提醒你：自定义其中一个，往往意味着资源语义特殊，另外几个不能未经检查地交给编译器。

更优先的做法是*零法则*：把资源交给 `vector`、`string`、`unique_ptr` 等成员，让成员组合出的默认操作表达类的语义。例如：

```cpp
class SampleBatch {
public:
    explicit SampleBatch(std::vector<float> samples)
        : samples_(std::move(samples)) {}

private:
    std::vector<float> samples_;
    std::string source_;
};
```

这个类不写任何特殊成员函数，也能随成员正确地复制和移动。如果业务上要求“批次只能转交，不能复制”，再明确删除复制操作：

```cpp
class ExclusiveBatch {
public:
    explicit ExclusiveBatch(std::vector<float> samples)
        : samples_(std::move(samples)) {}

    ExclusiveBatch(const ExclusiveBatch&) = delete;
    ExclusiveBatch& operator=(const ExclusiveBatch&) = delete;
    ExclusiveBatch(ExclusiveBatch&&) noexcept = default;
    ExclusiveBatch& operator=(ExclusiveBatch&&) noexcept = default;

private:
    std::vector<float> samples_;
};
```

删除复制是一项接口策略，不是“大对象就一定不能复制”的普遍规则。有些调用方确实需要快照，有些管线则希望编译器阻止意外复制；应由数据含义和性能测量共同决定。

==== 实际应用示例

图像帧很适合表达“独占后转交”的策略。下面把尺寸检查和像素存储放进一个 `Storage`，外层用 `unique_ptr` 管理整份状态。这样默认移动会让源 `Frame` 明确变空，也不需要手写五个资源函数：

```cpp
#include <cstddef>
#include <cstdint>
#include <limits>
#include <memory>
#include <stdexcept>
#include <utility>
#include <vector>

class Frame {
public:
    Frame(std::size_t width, std::size_t height)
        : storage_(std::make_unique<Storage>(width, height)) {}

    Frame(const Frame&) = delete;
    Frame& operator=(const Frame&) = delete;
    Frame(Frame&&) noexcept = default;
    Frame& operator=(Frame&&) noexcept = default;

    bool hasData() const noexcept {
        return static_cast<bool>(storage_);
    }

private:
    struct Storage {
        Storage(std::size_t w, std::size_t h)
            : width(w), height(h), pixels(byteCount(w, h)) {}

        static std::size_t byteCount(std::size_t width,
                                     std::size_t height) {
            constexpr std::size_t channels = 3;
            const auto max = std::numeric_limits<std::size_t>::max();
            if (width != 0 && height > max / width) {
                throw std::length_error("frame dimensions overflow");
            }
            const std::size_t pixels = width * height;
            if (pixels > max / channels) {
                throw std::length_error("frame byte count overflow");
            }
            return pixels * channels;
        }

        std::size_t width;
        std::size_t height;
        std::vector<std::uint8_t> pixels;
    };

    std::unique_ptr<Storage> storage_;
};
```

`hasData()` 让移动后的公开状态也有明确答案。这里禁止复制是管线的所有权选择；如果算法需要保留原图，应提供有明确名字的 `clone()`，或直接让帧类型可复制。

消息传递也能利用相同思路。先写一个*不负责线程同步*的收件箱，后面的多线程章节会再补上互斥和等待：

```cpp
#include <cstdint>
#include <iostream>
#include <optional>
#include <queue>
#include <string>
#include <utility>
#include <vector>

class Message {
public:
    Message(std::string topic, std::vector<std::uint8_t> payload)
        : topic_(std::move(topic)), payload_(std::move(payload)) {}

    Message(const Message&) = delete;
    Message& operator=(const Message&) = delete;
    Message(Message&&) noexcept = default;
    Message& operator=(Message&&) noexcept = default;

    const std::string& topic() const noexcept { return topic_; }

private:
    std::string topic_;
    std::vector<std::uint8_t> payload_;
};

class MessageInbox {
public:
    void push(Message message) {
        queue_.push(std::move(message));
    }

    std::optional<Message> tryPop() {
        if (queue_.empty()) {
            return std::nullopt;
        }
        Message result = std::move(queue_.front());
        queue_.pop();
        return result;
    }

private:
    std::queue<Message> queue_;
};

int main() {
    MessageInbox inbox;
    std::vector<std::uint8_t> payload(1024);

    inbox.push(Message("sensor/imu", std::move(payload)));
    if (auto message = inbox.tryPop()) {
        std::cout << message->topic() << '\n';
    }
}
```

这段代码展示的是值如何进入和离开队列，不是线程安全队列。若生产者与消费者在不同线程，无锁地同时访问 `queue_` 会产生数据竞争；仅仅把元素改成可移动类型不会解决同步问题。

处理函数可以按值接收一帧，清楚地表示“调用后由函数接管”。返回局部结果时仍直接写变量名：

```cpp
struct Target {
    float x;
    float y;
};

struct DetectionResult {
    explicit DetectionResult(Frame frame)
        : processedFrame(std::move(frame)) {}

    Frame processedFrame;
    std::vector<Target> targets;
    double processingTimeSeconds = 0.0;
};

DetectionResult detectTargets(Frame frame) {
    DetectionResult result(std::move(frame));
    // 填充 result.targets，并记录实际测得的耗时。
    return result;
}

int main() {
    Frame frame(1920, 1080);
    DetectionResult result = detectTargets(std::move(frame));
    // Frame 的契约保证：移动成功后 frame.hasData() 为 false。
}
```

这里只验证了所有权方向。按值传帧是否适合真实图像管线，还要结合缓冲池、驱动接口、并发模型和测量结果判断；编译器接受这段代码，不等于处理吞吐已经满足比赛要求。

==== 常见错误与最佳实践

最后把最常见的几个误区放在一起比较：

- `std::move` 是值类别转换，不是一次已经完成的搬运。
- 命名的右值引用仍是左值；继续转移时要再次使用 `std::move`，转发参数则按条件使用 `std::forward`。
- 移动后可以析构和重新赋值，其他操作取决于类型契约；不要凭经验假定它一定为空。
- 返回同类型局部变量时通常不写 `std::move`，让复制消除和隐式移动规则发挥作用。
- `std::move(const_object)` 不会去掉 `const`，常见类型因而仍会复制。
- `noexcept` 是必须兑现的承诺，只在实现确实不让异常逃出时使用。
- 优先采用零法则；只有直接管理特殊资源或刻意限制复制时，才自己设计特殊成员函数。

移动语义给类型提供了“接管旧值”的入口，却没有承诺接管必然便宜。写代码时先让所有权和对象状态清楚，再通过类型文档与测量判断成本。下一节的 Lambda 会遇到同样的值类别问题：捕获一个对象时，它究竟被复制、引用，还是移动进闭包，直接决定了回调能活多久、拥有什么。

=== Lambda 表达式
// ⚠️ 重要！ROS 回调常用
// Lambda 语法
// 捕获列表
// 应用场景
// === Lambda 表达式

上一节留下了一个问题：如果一段稍后执行的代码需要带走局部状态，它应该复制、引用，还是移动这些状态？Lambda 正是 C++ 用来描述这种“小段代码加随身状态”的语法。它常出现在 STL 算法、ROS 回调和异步任务里；写起来只有几行，真正要想清楚的却是闭包保存了什么，以及这些对象执行时是否还活着。

==== 为什么需要 Lambda

假设我们只想找出距离合适、置信度也够高的目标。用普通函数当然能完成，但阈值来自调用现场，单独定义一个全局函数就要额外传参或设计对象：

```cpp
#include <algorithm>
#include <vector>

struct Target {
    double distance;
    double confidence;
};

const Target* findCandidate(const std::vector<Target>& targets,
                            double maxDistance,
                            double minConfidence) {
    const auto it = std::find_if(
        targets.begin(), targets.end(),
        [maxDistance, minConfidence](const Target& target) {
            return target.distance <= maxDistance &&
                   target.confidence >= minConfidence;
        });
    return it == targets.end() ? nullptr : &*it;
}
```

方括号里的两个阈值会成为闭包的一部分，判断逻辑又留在 `find_if` 旁边。读者不必跳到别处寻找一个只用一次的函数，这正是 Lambda 最舒服的用法：短小、局部，而且需要携带少量上下文。

它并不天然优于命名函数。若规则很长、会被复用，或者“为什么这样判断”需要单独测试和命名，提取为普通函数或函数对象往往更清楚。

==== Lambda 的基本语法

以 C++17 常见写法来看，一个 Lambda 可以包含这些部分：

```text
[捕获列表](参数列表) mutable noexcept -> 返回类型 { 函数体 }
```

除捕获列表和函数体外，许多部分都能省略：

```cpp
auto greet = [] { std::cout << "Hello, Lambda!\n"; };
greet();

auto add = [](int a, int b) { return a + b; };
const int sum = add(3, 4);

int factor = 10;
auto scale = [factor](int value) { return value * factor; };
const int result = scale(5);
```

Lambda 表达式只是创建了一个可调用对象；末尾的 `()` 才是调用。参数与普通函数相似，返回类型在能一致推导时可以省略：

```cpp
auto magnitude = [](double value) {
    return value < 0.0 ? -value : value;
};

auto selectValue = [](bool useInteger) -> double {
    if (useInteger) {
        return 1;    // 转换为显式指定的 double
    }
    return 3.14;
};
```

`mutable` 允许修改闭包内按值保存的成员，`noexcept` 则承诺调用不会让异常逃出。后者必须与函数体和所调用操作的真实行为相符，不能为了“看起来更快”随手添加。

==== 捕获列表

捕获发生在 Lambda *创建时*。按值捕获保存当时的值，按引用捕获则继续指向原对象：

```cpp
int gain = 10;

auto snapshot = [gain] { return gain; };
auto liveView = [&gain] { return gain; };

gain = 20;
std::cout << snapshot() << '\n'; // 10
std::cout << liveView() << '\n'; // 20
```

常见形式可以这样读：

```cpp
[]          // 不捕获局部变量
[gain]      // 按值保存 gain
[&gain]     // 按引用借用 gain
[=]         // 用到的局部变量默认按值捕获
[&]         // 用到的局部变量默认按引用捕获
[=, &gain]  // 默认按值，gain 例外地按引用
[&, gain]   // 默认按引用，gain 例外地按值
[this]      // 保存当前对象的 this 指针
[*this]     // C++17：保存当前对象的一份副本
```

默认捕获不是“把作用域内所有变量全部塞进去”；闭包只捕获函数体按规则需要的实体。不过，`[=]` 和 `[&]` 会让后来加入的一次变量使用悄悄改变捕获集合。对于要跨作用域保存的回调，显式列出关键对象通常更容易审查生命周期。

按值捕获的成员默认从 `const` 调用运算符中访问，因此不能修改。`mutable` 改变的是闭包副本，不是外面的变量：

```cpp
int count = 0;
auto next = [count]() mutable {
    return ++count;
};

std::cout << next() << '\n'; // 1
std::cout << next() << '\n'; // 2
std::cout << count << '\n';  // 外部仍是 0
```

C++14 的初始化捕获还能改名、计算或移动一个对象：

```cpp
auto buffer = std::make_unique<std::vector<int>>(100);

auto task = [data = std::move(buffer)] {
    return data->size();
};

// unique_ptr 的移动契约保证 buffer 现在为空，task 独占这份 vector。
```

这个闭包含有 `unique_ptr`，所以它本身不可复制。后面选择 `std::function`、线程池或回调 API 时，要同时检查这些接口是否要求可调用对象可复制。

==== 捕获的注意事项

引用捕获是借用，不会延长被借对象的生命。下面的函数返回后，`count` 已经销毁，闭包里的引用随即悬空：

```cpp
std::function<int()> makeBrokenCounter() {
    int count = 0;
    return [&count] { return ++count; }; // 返回后调用是未定义行为
}
```

计数器需要拥有自己的状态，按值保存再用 `mutable` 即可：

```cpp
std::function<int()> makeCounter() {
    return [count = 0]() mutable {
        return ++count;
    };
}
```

捕获 `this` 也属于借用。闭包保存的是指针，并不会让对象自动活得更久：

```cpp
class Processor {
public:
    auto makeBorrowingTask() {
        return [this](int value) { return value * factor_; };
    }

private:
    int factor_ = 2;
};
```

只有在任务执行期间 `Processor` 仍然存在，这个回调才有效。若任务只需要成员当时的值，可以把它提出来保存：

```cpp
class Processor {
public:
    auto makeSnapshotTask() const {
        return [factor = factor_](int value) {
            return value * factor;
        };
    }

private:
    int factor_ = 2;
};
```

`[*this]` 也能在 C++17 中复制整个对象，但它要求对象可复制，而且得到的是对象复制语义定义下的快照：成员若是 `shared_ptr`，副本仍会共享其指向的数据；成员若含互斥量，复制甚至可能不可用。因此，“复制 this”不等于深复制，也不自动带来线程安全。

如果回调需要让一个共享管理的对象在执行期间存活，可以按值捕获 `shared_ptr`；如果回调不应延长生命，则捕获 `weak_ptr` 并在执行时 `lock()`。选择哪一种取决于所有权图，不能只为消除悬空而无条件改成共享所有权。

==== Lambda 的类型与存储

每个 Lambda 表达式都有自己唯一的闭包类型，即使函数体看起来完全相同：

```cpp
auto twice1 = [](int value) { return value * 2; };
auto twice2 = [](int value) { return value * 2; };

// decltype(twice1) 与 decltype(twice2) 是不同类型。
```

局部使用时，`auto` 会保留这个确切类型，编译器也更容易内联。通用函数可以直接接收模板参数：

```cpp
template <typename Function>
void transformInPlace(std::vector<int>& values, Function transform) {
    for (int& value : values) {
        value = transform(value);
    }
}

std::vector<int> values{1, 2, 3};
transformInPlace(values, [](int value) { return value * value; });
```

当程序确实需要在运行时保存不同类型的可调用对象时，`std::function` 提供统一接口：

```cpp
#include <functional>

std::function<int(int)> operation =
    [](int value) { return value * 2; };

operation = [](int value) { return value * value; };
if (operation) {
    std::cout << operation(5) << '\n';
}
```

这种类型擦除可能带来间接调用、对象存储和分配成本，具体是否分配由实现和闭包大小决定。在 C++17 中，放进 `std::function` 的可调用目标还必须可复制；前面捕获 `unique_ptr` 的闭包便不能直接放进去。空的 `std::function` 被调用会抛出 `std::bad_function_call`，所以可为空的接口应先检查。

无捕获 Lambda 可以在兼容时转换为普通函数指针，有捕获的闭包则携带状态，不能这样转换：

```cpp
int (*add)(int, int) =
    [](int a, int b) { return a + b; };

const int offset = 3;
// int (*bad)(int) = [offset](int x) { return x + offset; };
```

==== 泛型 Lambda（C++14）

参数写成 `auto`，就得到一个调用运算符为模板的闭包：

```cpp
auto print = [](const auto& value) {
    std::cout << value << '\n';
};

print(42);
print(3.14);
print(std::string("camera"));

auto add = [](const auto& a, const auto& b) {
    return a + b;
};
```

“泛型”不表示任意类型都能调用。`print` 要求表达式 `std::cout << value` 有效，`add` 要求两个实参支持相应的 `+`，返回类型也由该表达式决定。C++17 的报错通常会落在实例化位置；C++20 可以用模板参数列表和概念进一步写明要求。

==== ROS 回调中的 Lambda

ROS 2 的订阅、定时器和服务都接收可调用对象，Lambda 因而很常见。下面只展示接口形状；消息包、QoS 类型和个别重载会随 ROS 2 发行版变化，应以项目实际版本的文档和可编译接口为准：

```cpp
#include <chrono>
#include <rclcpp/rclcpp.hpp>
#include <sensor_msgs/msg/imu.hpp>

class RobotNode : public rclcpp::Node {
public:
    RobotNode() : Node("robot_node") {
        imu_sub_ = create_subscription<sensor_msgs::msg::Imu>(
            "imu/data",
            rclcpp::SensorDataQoS(),
            [this](sensor_msgs::msg::Imu::ConstSharedPtr message) {
                handleImu(*message);
            });

        using namespace std::chrono_literals;
        timer_ = create_wall_timer(10ms, [this] {
            controlOnce();
        });
    }

private:
    void handleImu(const sensor_msgs::msg::Imu& message) {
        // 校验并保存本次测量。
    }

    void controlOnce() {
        // 读取一致的状态快照，再完成一次控制计算。
    }

    rclcpp::Subscription<sensor_msgs::msg::Imu>::SharedPtr imu_sub_;
    rclcpp::TimerBase::SharedPtr timer_;
};
```

这里的 `[this]` 依赖节点、执行器和回调实体的生命周期约定。它也没有解决并发：单线程执行器会串行执行回调，多线程执行器以及不同回调组可能让订阅和定时器重叠访问成员。共享状态是否需要互斥、原子量或快照，要按实际执行器与回调组配置判断。

ROS 1 的 `roscpp` 同样能在很多订阅重载中使用 Lambda，但消息指针类型和重载签名不同。迁移示例时不要只替换命名空间；让编译器针对项目所用 ROS 版本检查确切回调类型。

==== STL 算法中的 Lambda

算法中的 Lambda 通常不需要离开当前函数，引用捕获因而较容易控制。下面把筛选、排序和提取串成一条处理链：

```cpp
#include <algorithm>
#include <cmath>
#include <iterator>
#include <vector>

struct Target {
    double distance;
    double confidence;
};

std::vector<double> selectDistances(std::vector<Target> targets,
                                    double minConfidence) {
    targets.erase(
        std::remove_if(
            targets.begin(), targets.end(),
            [minConfidence](const Target& target) {
                return !std::isfinite(target.distance) ||
                       !std::isfinite(target.confidence) ||
                       target.confidence < minConfidence;
            }),
        targets.end());

    std::sort(targets.begin(), targets.end(),
              [](const Target& a, const Target& b) {
                  return a.distance < b.distance;
              });

    std::vector<double> distances;
    distances.reserve(targets.size());
    std::transform(targets.begin(), targets.end(),
                   std::back_inserter(distances),
                   [](const Target& target) {
                       return target.distance;
                   });
    return distances;
}
```

排序前先排除非有限距离，使比较器在这个输入范围内形成一致顺序。一般来说，Lambda 的参数类型能通过编译只说明“可以调用”，并不证明谓词满足算法要求；排序比较仍须满足严格弱序，状态化谓词也不能在调用间随意改变判定规则。

==== 异步操作与 Lambda

异步任务会把闭包带出当前执行点，捕获生命周期必须重新检查。C++14 的移动捕获适合把一帧独占地交给任务：

```cpp
#include <future>
#include <utility>

std::future<DetectionResult> startDetection(Detector& detector,
                                            Frame frame) {
    return std::async(
        std::launch::async,
        [&detector, frame = std::move(frame)]() mutable {
            return detector.process(std::move(frame));
        });
}
```

这里 `frame` 由闭包拥有，`detector` 却只是引用：调用方必须保证它活到任务结束，而且若多个任务同时调用它，还要确认 `process` 是否支持并发。需要共享生命期时可以捕获 `shared_ptr<Detector>`，但那会改变所有权关系，应由系统设计决定。

显式指定 `std::launch::async` 表示请求异步执行；不指定策略时，实现也可以延迟到 `get()` 或 `wait()` 所在线程执行。任务中的异常会存进 `future`，在 `get()` 时重新抛出。大量帧各启动一个 `std::async` 也不等于形成了有界线程池，实际系统还要限制并发量、处理积压和停机。

下一节会系统讨论线程、互斥量和条件变量。在那之前，先记住：按值捕获解决的是闭包拥有状态，不能替代对共享对象的同步。

==== 高级用法

立即调用的 Lambda 很适合构造一个需要分支或校验的 `const` 值：

```cpp
const Config config = [&] {
    if (useDefault) {
        return Config::getDefault();
    }
    return Config::loadFromFile(filename);
}();
```

末尾的 `()` 立即执行闭包。这里按引用捕获没有跨越初始化语句，但仍要确保两个分支返回兼容类型，并让加载失败通过项目约定的异常或结果类型传出。

递归 Lambda 可以借助 `std::function`，也可以把自身作为参数传入。后者避免先声明一个类型擦除容器：

```cpp
auto factorial = [](auto&& self, unsigned int n) -> std::uint64_t {
    return n < 2 ? 1 : n * self(self, n - 1);
};

const auto value = factorial(factorial, 10);
```

这段写法只展示递归形状。`uint64_t` 的阶乘到 `20!` 仍可表示，超过这个范围会发生无符号回绕；若输入来自外部，应先限制范围或返回可表示失败的结果。

Lambda 也能成为有序容器的比较器：

```cpp
auto earlierDeadline = [](const Task& a, const Task& b) {
    return a.deadline < b.deadline;
};

std::set<Task, decltype(earlierDeadline)> tasks(earlierDeadline);
```

闭包类型会成为容器类型的一部分。比较器必须在容器整个生命期内保持严格弱序；如果它引用一个会改变排序规则的外部变量，容器内部顺序可能不再符合比较器，后续操作的行为就不再满足容器契约。

==== 最佳实践

Lambda 的价值在于把简单策略放回使用现场，而不是把所有逻辑压成匿名代码。审查一个 Lambda 时，可以沿着下面的顺序读：

1. 它什么时候执行，是立即调用、同步算法，还是稍后的回调？
2. 每个捕获是快照、借用还是所有权转移，执行时仍然有效吗？
3. 闭包会被复制吗，所用接口能否接收移动专用闭包？
4. 它会与其他任务并发读写同一对象吗？
5. 谓词或比较器是否满足调用方的语义要求，而不只是能编译？

只有局部、清楚的计算时，Lambda 往往比另起名字更顺；一旦错误处理、状态转换或业务规则开始遮住调用现场，命名函数、专门类和独立测试会更合适。这不是按行数划出的硬界线，而是看读者能否在当前位置理解它的输入、状态与结果。

下一节把异步回调背后的执行模型展开：线程怎样开始和结束，共享数据为什么会竞争，以及互斥量和条件变量各自解决什么问题。

=== 多线程基础
// std::thread
// mutex 与 lock_guard
// 条件变量
// RoboMaster 多线程应用
// === 多线程基础

相机采集、状态估计、通信和控制在逻辑上是几条不同的工作链。把它们全塞进一个循环，某一步阻塞就会拖住后面的步骤；拆成线程可以让独立工作重叠执行，也可能利用多个处理器核心。不过，“开了多个线程”不等于任务一定同时运行，更不等于满足实时期限。调度方式、核心数量、共享数据和最慢阶段都会影响结果。

这一节先建立一套最小而完整的思路：线程由谁结束，哪些状态被共享，用什么同步建立可见性，以及程序停机时怎样唤醒等待者。性能优化放在这些关系明确之后，否则一个跑得很快的数据竞争仍然是未定义行为。

==== 创建线程

`std::thread` 在构造后启动一个新的执行线程。下面的主线程和工作线程可以交错运行，但 `join()` 返回以后，工作线程已经结束，它对 `result` 的写入也对主线程可见：

```cpp
#include <iostream>
#include <thread>

int main() {
    int result = 0;

    std::thread worker([&result] {
        result = 42;
    });

    worker.join();
    std::cout << result << '\n';
}
```

这里在 `join()` 前只有工作线程访问 `result`，之后只有主线程访问，所以没有并发冲突。若主线程也在工作线程结束前读写它，就需要额外同步。

线程入口可以是普通函数、函数对象或 Lambda。构造函数会保存入口和参数的衰减副本，再从新线程调用它们；需要传左值引用时，应显式使用 `std::ref`，并保证被引用对象活到线程结束：

```cpp
#include <functional>
#include <string>
#include <thread>

void appendStatus(std::string& text) {
    text += " ready";
}

int main() {
    std::string status = "camera";
    std::thread worker(appendStatus, std::ref(status));
    worker.join();
}
```

一个 `std::thread` 若仍处于 `joinable()` 状态就被析构，程序会调用 `std::terminate`。通常应 `join()`，让拥有线程对象的作用域也拥有任务生命期。`detach()` 会切断这条管理关系：此后无法等待、取得结果或直接协调停机，线程捕获的引用也更容易悬空，因此不适合作为“嫌 join 麻烦”的默认选择。

```cpp
std::thread worker(doWork);
try {
    continueInCaller(); // 这里可能抛出异常
} catch (...) {
    worker.join();
    throw;
}
worker.join();
```

真实代码更适合用 RAII 封装这段清理。C++20 的 `std::jthread` 会在析构时请求停止并连接线程；在 C++17 项目中，可以使用经过审查的 joining-thread 封装，或把线程放进明确提供 `start()`、`stop()` 和析构清理的组件。无论采用哪种方式，都要避免工作线程反过来连接自己。

多个线程的执行顺序不能由创建顺序推断，连标准输出的片段也可能交错。日志系统若要求一条记录完整，需要自己串行化记录，或使用提供相应保证的日志设施。

==== 数据竞争与互斥量

C++ 内存模型中的数据竞争，不只是“两个操作碰巧同时发生”。简化来说，当不同线程对同一内存位置进行冲突访问、至少一个是写入，且操作之间没有适当的同步顺序时，就会发生数据竞争；结果是未定义行为。

```cpp
int counter = 0;

void incrementWithoutLock() {
    for (int i = 0; i < 100'000; ++i) {
        ++counter; // 两个线程这样调用会产生数据竞争
    }
}
```

`++counter` 的语言语义是一次读改写，不是普通 `int` 的原子操作。观察到小于预期的结果只是可能表现之一；未定义行为不能被限定为“偶尔丢一次加法”。

互斥量把共享状态和保护它的规则绑在一起：所有并发访问，包括读操作，都遵守同一把锁。

```cpp
#include <mutex>

class Counter {
public:
    void increment() {
        std::lock_guard<std::mutex> lock(mutex_);
        ++value_;
    }

    int value() const {
        std::lock_guard<std::mutex> lock(mutex_);
        return value_;
    }

private:
    mutable std::mutex mutex_;
    int value_ = 0;
};
```

“这个字段由 `mutex_` 保护”才是接口契约，仅在某个写入点随手加锁不够。返回引用或指针也要谨慎：函数返回后锁已经释放，调用方若继续通过别名访问内部对象，就绕开了保护。对于小型状态，返回按值快照通常更清楚。

互斥还能保护多个字段共同组成的不变量。例如目标速度的三个分量应该在同一次加锁中读写；把它们分别改成三个原子量，读线程仍可能拼出来自不同命令的混合快照。

==== lock_guard 与 unique_lock

手写 `lock()` / `unlock()` 很容易在提前返回或异常路径上漏掉解锁。`std::lock_guard` 用作用域管理锁，适合“进入代码块就加锁，离开就释放”的大多数场景：

```cpp
void update(State next) {
    std::lock_guard<std::mutex> lock(stateMutex);
    state = std::move(next);
}
```

`std::unique_lock` 体积和状态更多，但允许延迟加锁、临时解锁和转移锁所有权。条件变量需要在等待时自动释放再重新取得互斥量，因此通常与 `unique_lock` 配合：

```cpp
std::unique_lock<std::mutex> lock(stateMutex, std::defer_lock);
prepareLocalData();
lock.lock();
commitSharedState();
lock.unlock();
```

`try_lock_for` 和 `try_lock_until` 不是普通 `std::mutex` 的成员；需要定时尝试时要使用 `std::timed_mutex` 等支持定时锁定的类型。即便加上超时，程序仍要定义超时后保留旧状态、重试还是报告失败。

需要同时锁住多把互斥量时，逐把按不一致顺序获取可能死锁。C++17 的 `std::scoped_lock` 会使用避免死锁的锁定算法，并在作用域结束时全部释放：

```cpp
std::mutex leftMutex;
std::mutex rightMutex;

void swapShared(State& left, State& right) {
    std::scoped_lock lock(leftMutex, rightMutex);
    using std::swap;
    swap(left, right);
}
```

这不意味着任意加锁图都自动安全。递归调用、条件变量、持锁调用外部代码以及锁与线程连接之间仍可能形成等待环。更根本的办法是减少共享可变状态，并为整个组件规定一致的锁顺序。

==== 条件变量

互斥量解决“谁可以访问”，条件变量解决“条件不满足时怎样睡眠等待”。消费者不必反复轮询队列，而是在队列有数据或已经关闭时被唤醒：

```cpp
#include <condition_variable>
#include <mutex>
#include <optional>
#include <queue>
#include <thread>

std::queue<int> values;
std::mutex valuesMutex;
std::condition_variable valuesChanged;
bool closed = false;

void producer() {
    for (int value = 0; value < 10; ++value) {
        {
            std::lock_guard<std::mutex> lock(valuesMutex);
            values.push(value);
        }
        valuesChanged.notify_one();
    }

    {
        std::lock_guard<std::mutex> lock(valuesMutex);
        closed = true;
    }
    valuesChanged.notify_all();
}

std::optional<int> consumeOne() {
    std::unique_lock<std::mutex> lock(valuesMutex);
    valuesChanged.wait(lock, [] {
        return !values.empty() || closed;
    });

    if (values.empty()) { // closed 且已排空
        return std::nullopt;
    }
    const int value = values.front();
    values.pop();
    return value;
}
```

谓词所检查的 `values` 和 `closed` 都由同一把互斥量保护。`wait(lock, predicate)` 可以理解为循环：持锁检查谓词；不满足时原子地释放锁并睡眠；醒来后重新取得锁再检查。循环既处理虚假唤醒，也处理另一个消费者先拿走数据的情况。

通知表示“状态可能变了”，不是一份会被条件变量保存的数据。正确性来自受锁保护的状态和谓词，所以即使通知发生在消费者正式等待之前，消费者也能看见已经成立的条件。修改状态必须在锁内；通知常放在解锁后，以减少被唤醒线程立刻又阻塞在同一把锁上的机会，但具体位置还要看对象生命期和协议。

`notify_one()` 让一个等待者重新竞争锁，适合一次只新增一个可消费项；关闭队列时所有等待者都应重新检查 `closed`，通常使用 `notify_all()`。定时等待只说明某个时限内谓词是否成立，不能把线程调度精度等同于硬实时定时器。

==== 原子操作

`std::atomic<T>` 让针对该原子对象的操作不发生数据竞争，并提供线程间排序工具。它不保证在所有平台上无锁，也不保证一定比互斥量快：

```cpp
#include <atomic>
#include <thread>

std::atomic<int> counter{0};

void increment() {
    for (int i = 0; i < 100'000; ++i) {
        counter.fetch_add(1); // 默认使用顺序一致内存序
    }
}

int main() {
    std::thread first(increment);
    std::thread second(increment);
    first.join();
    second.join();

    return counter.load() == 200'000 ? 0 : 1;
}
```

常见操作包括 `load`、`store`、`exchange`、`fetch_add` 和比较交换。`compare_exchange_*` 失败时会把实际值写回 `expected`，因此循环通常写成：

```cpp
int expected = value.load();
while (!value.compare_exchange_weak(expected, desired(expected))) {
    // expected 已更新，重新计算希望写入的值。
}
```

这里假设 `desired` 不抛异常且能处理每个读到的值。弱比较交换允许偶发失败，放在循环中使用；强比较交换更适合不循环的一次判断。

默认内存序 `memory_order_seq_cst` 最容易推理。更弱的内存序可能减少某些平台上的约束，但它要求对发布、获取和对象生命期有完整证明，不应只凭性能直觉替换。原子量也只保护自己的访问；多个原子字段之间的业务不变量、容器操作和复合状态仍可能需要互斥量或不可变快照。

用原子 `running` 写成空转循环还会持续占用处理器。若线程本来在等任务，条件变量或 C++20 的原子等待通常更合适；停机时要同时改变停止状态并唤醒等待者。

==== 线程安全的数据结构

把锁藏进容器可以减少调用方遗漏同步的机会，但“每个成员函数各自加锁”不自动构成完整协议。阻塞队列尤其需要关闭语义，否则消费者可能在程序停机时永远睡着。

下面是一份 C++17 的最小可关闭队列。为使“移出队首再删除”具有清楚的失败语义，它要求 `T` 的移动构造不抛异常；更通用的实现需要另行设计异常时队首元素的状态。

```cpp
#include <condition_variable>
#include <mutex>
#include <optional>
#include <queue>
#include <type_traits>
#include <utility>

template <typename T>
class BlockingQueue {
    static_assert(std::is_nothrow_move_constructible_v<T>,
                  "BlockingQueue requires nothrow-movable values");

public:
    BlockingQueue() = default;
    BlockingQueue(const BlockingQueue&) = delete;
    BlockingQueue& operator=(const BlockingQueue&) = delete;

    bool push(T value) {
        {
            std::lock_guard<std::mutex> lock(mutex_);
            if (closed_) {
                return false;
            }
            queue_.push(std::move(value));
        }
        changed_.notify_one();
        return true;
    }

    std::optional<T> waitPop() {
        std::unique_lock<std::mutex> lock(mutex_);
        changed_.wait(lock, [this] {
            return closed_ || !queue_.empty();
        });

        if (queue_.empty()) {
            return std::nullopt;
        }
        T value = std::move(queue_.front());
        queue_.pop();
        return value;
    }

    void close() {
        {
            std::lock_guard<std::mutex> lock(mutex_);
            closed_ = true;
        }
        changed_.notify_all();
    }

private:
    std::mutex mutex_;
    std::condition_variable changed_;
    std::queue<T> queue_;
    bool closed_ = false;
};
```

`close()` 是幂等的：关闭后拒绝新元素，消费者会取完已有元素，然后收到 `nullopt`。这个队列仍是无界的；若生产持续快于消费，内存会增长。图像管线常需要容量上限、丢弃旧帧、覆盖最新帧或向上游施加背压，这些是业务策略，不能由一份“线程安全队列”替系统选择。

类似地，`empty()` 或 `size()` 即使内部加锁，也只是调用瞬间的快照。调用方不能根据 `if (!queue.empty())` 推断下一次弹出一定成功；两个操作之间状态可能已经改变。把“等待并取出”合成一个成员函数，才封装了需要的原子步骤。

==== RoboMaster 多线程应用

视觉管线可以把采集和检测分开，但先要画出停止路径。下面的骨架假设 `Camera::captureFor` 支持超时，`requestStop` 能无异常地解除设备阻塞，`Frame` 满足队列的无异常移动要求；这些都是项目接口必须验证的前置条件，而不是标准库替我们提供的保证：

```cpp
class VisionPipeline {
public:
    // start/stop 由同一个外部管理线程串行调用；本例只支持启动一次。
    void start() {
        if (started_) {
            throw std::logic_error("vision pipeline already started");
        }
        started_ = true;
        accepting_.store(true);

        try {
            processThread_ = std::thread(&VisionPipeline::processLoop, this);
            captureThread_ = std::thread(&VisionPipeline::captureLoop, this);
        } catch (...) {
            accepting_.store(false);
            camera_.requestStop();
            frames_.close();
            joinThreads();
            throw;
        }
    }

    void stop() noexcept {
        accepting_.store(false);
        camera_.requestStop();
        frames_.close();
        joinThreads();
    }

    ~VisionPipeline() {
        stop();
    }

    std::vector<Target> latestTargets() const {
        std::lock_guard<std::mutex> lock(resultMutex_);
        return latestTargets_;
    }

private:
    void captureLoop() {
        while (accepting_.load()) {
            auto frame = camera_.captureFor(std::chrono::milliseconds(50));
            if (frame && !frames_.push(std::move(*frame))) {
                break;
            }
        }
        frames_.close();
    }

    void processLoop() {
        while (auto frame = frames_.waitPop()) {
            auto targets = detector_.detect(*frame);
            std::lock_guard<std::mutex> lock(resultMutex_);
            latestTargets_ = std::move(targets);
        }
    }

    void joinThreads() noexcept {
        if (captureThread_.joinable()) {
            captureThread_.join();
        }
        if (processThread_.joinable()) {
            processThread_.join();
        }
    }

    Camera camera_;
    Detector detector_;
    BlockingQueue<Frame> frames_;

    mutable std::mutex resultMutex_;
    std::vector<Target> latestTargets_;

    std::atomic<bool> accepting_{false};
    bool started_ = false;
    std::thread captureThread_;
    std::thread processThread_;
};
```

这段代码表达了所有权和停机顺序，却仍不是可直接套用的设备驱动：若 `captureFor` 或 `detect` 永久阻塞，`stop()` 仍可能等不到线程；若它们抛异常并逃出线程入口，程序会终止，生产代码需要在线程边界捕获并上报；析构也必须从工作线程之外发生，否则可能连接自身。队列无界，处理速度也没有测量，这些都要在实际系统中补齐。

控制循环还有另一类误区：`sleep_for(1ms)` 不能证明循环达到 1 kHz。计算时间、抢占和时钟粒度都会引入延迟。较稳定的节拍通常按绝对时点推进，并记录超期：

```cpp
using Clock = std::chrono::steady_clock;
constexpr auto period = std::chrono::milliseconds(1);
auto next = Clock::now();

while (running.load()) {
    next += period;
    runOneControlStep();

    const auto now = Clock::now();
    if (now < next) {
        std::this_thread::sleep_until(next);
    } else {
        recordDeadlineMiss(now - next);
    }
}
```

这能减少“每轮计算时间都叠加到周期里”的漂移，并暴露超期，但通用桌面 Linux 上的普通 C++ 线程仍没有硬实时保证。控制频率、最坏执行时间、调度策略和失效行为要在目标硬件与负载下测量。

传感器融合也不只是“每个传感器一个线程”。只保留 `latestIMU` 会覆盖中间样本，排队则会增加延迟；按时间戳融合还要定义时钟来源、乱序和缺测策略。线程同步能够安全传递选定的数据，却不会替算法判断哪一份数据在时间上可比较。

==== 常见陷阱与最佳实践

多线程错误往往藏在正常路径之外。审查一个组件时，至少沿着这些问题走一遍：

- *生命期*：每个线程由谁连接？构造线程失败一半、工作函数抛异常或对象析构时会怎样？
- *共享状态*：哪些字段由哪把锁保护？返回的引用是否在解锁后逃逸？多个字段是否需要一致快照？
- *等待协议*：谓词对应的状态是否在同一把锁下修改？关闭时是否唤醒所有可能等待的线程？
- *锁顺序*：会不会持锁调用未知代码、日志、回调、`join()` 或另一个可能反向取锁的组件？
- *容量与时限*：生产快于消费时是阻塞、丢弃还是增长？超时后保留什么状态？

缩短临界区通常能减少争用，但不能把一个需要原子提交的状态拆开。常见做法是在锁外完成纯局部计算，再在锁内快速验证并提交；如果提交依赖计算前读到的旧状态，还要检查这期间状态是否已经变化。

线程 sanitizer、压力测试和故障注入能发现一部分竞争与停机问题，却只覆盖实际执行到的交错。一次没有报错的运行不能证明不存在数据竞争；设计层面的所有权、同步关系和停止协议仍需要代码审查。

多线程提供的是并发组织工具，不是自动的性能或实时性保证。下一节转向文件操作：那里同样有“程序内状态看似写完，外部世界却未必已经持久化”的边界，需要区分流状态、缓冲刷新和存储承诺。
=== 文件操作
// fstream
// 读写配置文件
// 日志记录
// === 文件操作

文件把程序的状态带到下一次运行，也把机器人现场带回离线分析环境。它看起来仍是熟悉的 `<<`、`>>` 和 `getline`，但多了几层容易混在一起的结果：路径能否打开、内容能否完整解析、数据是否写进流缓冲区，以及断电后是否真的留在存储介质上。

这一节会逐层区分这些边界。示例能说明 C++ 流的用法和一种文件格式的契约，却不能仅凭“程序运行完了”推断文件没有截断、格式能跨平台，或日志已经抵抗突然掉电。

==== fstream 基础

`<fstream>` 提供三类文件流：`ifstream` 读取，`ofstream` 写入，`fstream` 同时提供读写位置。它们都遵循 RAII，离开作用域时会关闭文件：

```cpp
#include <fstream>
#include <iostream>
#include <string>

bool writeReport(const std::string& path) {
    std::ofstream output(path, std::ios::out | std::ios::trunc);
    if (!output) {
        return false;
    }

    output << "camera = ready\n";
    output << "frames = " << 42 << '\n';
    output.flush();
    return static_cast<bool>(output);
}

bool printReport(const std::string& path) {
    std::ifstream input(path);
    if (!input) {
        return false;
    }

    std::string line;
    while (std::getline(input, line)) {
        std::cout << line << '\n';
    }
    return input.eof(); // 正常读到末尾，而不是中途 I/O 失败
}
```

析构关闭很适合清理资源，但析构函数无法把关闭阶段的失败返回给调用者。需要报告写入结果时，应在文件仍处于作用域内检查流状态；上例的 `flush()` 会把 C++ 流缓冲提交给下层，但仍不等于物理介质已经完成持久化。

常见打开模式可以组合：

```cpp
std::ios::in      // 允许读取
std::ios::out     // 允许写入
std::ios::app     // 每次写都定位到末尾
std::ios::trunc   // 打开时截断已有内容
std::ios::binary  // 禁用实现对文本换行等内容的转换
std::ios::ate     // 打开后先定位到末尾，之后仍可 seek
```

`ofstream(path)` 通常包含 `out | trunc`，所以打开已有配置会先清空它；追加日志则常用 `out | app`。`ate` 与 `app` 也不同：前者只是初始位置在末尾，后者要求每次写都在末尾。

流状态中，`fail()` 包含格式提取失败，`bad()` 表示更严重的底层错误，`eof()` 只说明已经遇到输入末尾。不要写成 `while (!file.eof())`：末尾标志通常在一次读取尝试后才设置，应直接把读取操作放进循环条件。

`clear()` 只清除流的状态位，不会修复磁盘错误，也不会自动移动读写位置。清除之后要明确下一步从哪里继续、坏输入由谁丢弃，否则循环可能反复读到同一处失败内容。

==== 文本文件读写

格式化提取适合结构简单、以空白分隔的数据。名字里含空格时，与其手写一个不完整的 CSV 解析器，不如先定义一个明确的小格式。例如每行写成：

```text
"Alice Smith" 25 3.80
"Bob Johnson" 22 3.50
```

`std::quoted` 能处理带引号的字符串。解析时先放进临时对象，整行通过校验后再提交：

```cpp
#include <cmath>
#include <fstream>
#include <iomanip>
#include <optional>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>

struct Student {
    std::string name;
    int age;
    double gpa;
};

std::optional<Student> parseStudent(const std::string& line) {
    std::istringstream input(line);
    Student candidate;

    if (!(input >> std::quoted(candidate.name)
                >> candidate.age
                >> candidate.gpa)) {
        return std::nullopt;
    }
    input >> std::ws;
    if (!input.eof()) { // 拒绝合法前缀后面的多余内容
        return std::nullopt;
    }
    if (candidate.name.empty() || candidate.age < 0 ||
        candidate.age > 150 || !std::isfinite(candidate.gpa) ||
        candidate.gpa < 0.0 || candidate.gpa > 4.0) {
        return std::nullopt;
    }
    return candidate;
}

std::vector<Student> readStudents(const std::string& path) {
    std::ifstream file(path);
    if (!file) {
        throw std::runtime_error("cannot open student file: " + path);
    }

    std::vector<Student> students;
    std::string line;
    std::size_t lineNumber = 0;
    while (std::getline(file, line)) {
        ++lineNumber;
        if (line.empty()) {
            continue;
        }
        auto student = parseStudent(line);
        if (!student) {
            throw std::runtime_error(
                "invalid student record at line " +
                std::to_string(lineNumber));
        }
        students.push_back(std::move(*student));
    }
    if (!file.eof()) {
        throw std::runtime_error("failed while reading: " + path);
    }
    return students;
}
```

抛错而不是悄悄跳过坏行，是这个示例选择的策略。遥测导入工具也许更适合收集所有行号后一次报告；在线控制配置则通常应拒绝部分有效的文件。重要的是策略明确，而不是失败时默默使用看似合理的默认值。

写出时同样要检查最终状态：

```cpp
bool writeStudents(const std::string& path,
                   const std::vector<Student>& students) {
    std::ofstream file(path, std::ios::trunc);
    if (!file) {
        return false;
    }

    file << std::setprecision(17);
    for (const Student& student : students) {
        file << std::quoted(student.name) << ' '
             << student.age << ' ' << student.gpa << '\n';
    }
    file.flush();
    if (!file) {
        return false;
    }
    file.close();
    return static_cast<bool>(file); // close 阶段的错误也会反映到流状态中
}
```

真正的 CSV 还涉及引号转义、字段内逗号、字段内换行、空字段和字符编码。用两次 `getline(..., ',')` 只能解析一个受限的“逗号分隔小格式”，不应对外宣称兼容 CSV；交换数据时优先采用经过测试的 CSV、JSON、YAML 或领域格式库。

==== 二进制文件读写

二进制模式不会自动让文件更快，也不定义数据布局。把整个结构体 `reinterpret_cast` 后写出，会把填充字节、字节序、`size_t` 宽度和本机浮点表示一起写进协议；换编译器、架构或结构体版本后，旧文件可能无法解释。

一个可演进的二进制格式至少要规定：魔数、版本、整数宽度与字节序、每条记录的类型与长度，以及不可信长度的上限。下面先实现固定的小端无符号整数和带长度记录：

```cpp
#include <array>
#include <cstdint>
#include <fstream>
#include <limits>
#include <optional>
#include <stdexcept>
#include <string>
#include <vector>

void writeU32LE(std::ostream& output, std::uint32_t value) {
    const std::array<char, 4> bytes{
        static_cast<char>(value & 0xffu),
        static_cast<char>((value >> 8) & 0xffu),
        static_cast<char>((value >> 16) & 0xffu),
        static_cast<char>((value >> 24) & 0xffu)
    };
    output.write(bytes.data(), static_cast<std::streamsize>(bytes.size()));
}

std::uint32_t readU32LE(std::istream& input) {
    std::array<unsigned char, 4> bytes{};
    input.read(reinterpret_cast<char*>(bytes.data()),
               static_cast<std::streamsize>(bytes.size()));
    if (!input) {
        throw std::runtime_error("truncated 32-bit field");
    }
    return static_cast<std::uint32_t>(bytes[0]) |
           (static_cast<std::uint32_t>(bytes[1]) << 8) |
           (static_cast<std::uint32_t>(bytes[2]) << 16) |
           (static_cast<std::uint32_t>(bytes[3]) << 24);
}

void writeRecord(std::ostream& output,
                 std::uint32_t type,
                 const std::vector<std::uint8_t>& payload) {
    if (payload.size() > std::numeric_limits<std::uint32_t>::max()) {
        throw std::length_error("record payload is too large");
    }
    writeU32LE(output, type);
    writeU32LE(output, static_cast<std::uint32_t>(payload.size()));
    if (!payload.empty()) {
        output.write(reinterpret_cast<const char*>(payload.data()),
                     static_cast<std::streamsize>(payload.size()));
    }
    if (!output) {
        throw std::runtime_error("record write failed");
    }
}
```

记录长度让读取方能跳过未知类型，但它也来自文件，不能直接拿来分配任意大小内存。读取器应先检查格式规定的上限，再分配并验证恰好读满。文件偏移的乘法同样要检查溢出和文件边界，不能只计算 `header + index * sizeof(record)` 后盲目 `seekg`。

传感器浮点值可以规定 IEEE 754 位模式与字节序，也可以采用带单位的定点整数，或交给 Protobuf、FlatBuffers、CBOR 等已定义编码。选择库不会自动验证业务单位和量程，这些仍要写进 schema 与读取校验。

==== 配置文件读写

配置的目标不是“尽量读出几个数”，而是在启动或更新时形成一份满足不变量的快照。建议把过程分成三步：完整解析文本、转换所有字段、最后一次性提交。若中间失败，正在运行的系统继续使用旧快照，而不是混入半份新配置。

下面的键值解析器会报告重复键和无等号的行，并在成功后才返回整张表：

```cpp
#include <fstream>
#include <map>
#include <stdexcept>
#include <string>

std::string trim(std::string text) {
    const auto first = text.find_first_not_of(" \t\r\n");
    if (first == std::string::npos) {
        return {};
    }
    const auto last = text.find_last_not_of(" \t\r\n");
    return text.substr(first, last - first + 1);
}

std::map<std::string, std::string>
readKeyValues(const std::string& path) {
    std::ifstream file(path);
    if (!file) {
        throw std::runtime_error("cannot open config: " + path);
    }

    std::map<std::string, std::string> staged;
    std::string line;
    std::size_t lineNumber = 0;
    while (std::getline(file, line)) {
        ++lineNumber;
        line = trim(std::move(line));
        if (line.empty() || line.front() == '#') {
            continue;
        }

        const auto equal = line.find('=');
        if (equal == std::string::npos) {
            throw std::runtime_error(
                "missing '=' at config line " +
                std::to_string(lineNumber));
        }
        std::string key = trim(line.substr(0, equal));
        std::string value = trim(line.substr(equal + 1));
        if (key.empty() || !staged.emplace(key, value).second) {
            throw std::runtime_error(
                "empty or duplicate key at config line " +
                std::to_string(lineNumber));
        }
    }
    if (!file.eof()) {
        throw std::runtime_error("I/O failure while reading config");
    }
    return staged;
}
```

类型转换也要拒绝“合法前缀”。`std::stoi("120rpm")` 可以先解析出 `120`；若格式不允许单位后缀，就必须检查消耗位置。浮点配置还应拒绝 NaN 和无穷值：

```cpp
#include <charconv>
#include <cmath>
#include <optional>
#include <string_view>

std::optional<int> parseInt(std::string_view text) {
    int value = 0;
    const auto result = std::from_chars(
        text.data(), text.data() + text.size(), value);
    if (result.ec != std::errc{} ||
        result.ptr != text.data() + text.size()) {
        return std::nullopt;
    }
    return value;
}

std::optional<bool> parseBool(std::string_view text) {
    if (text == "true")  return true;
    if (text == "false") return false;
    return std::nullopt;
}
```

整数是否允许前导 `+`、布尔值是否忽略大小写、未知键是错误还是警告，都属于格式契约。不要用 `catch (...)` 把任何转换失败都悄悄变成默认参数：默认值适合“字段确实可选”，不适合掩盖写错的电流上限。

保存运行配置时，直接以 `trunc` 打开正式文件会在写到一半时留下残缺内容。较稳妥的更新流程是在同一目录写临时文件，检查写入与关闭，再用操作系统支持的替换操作提交。若要求抵抗掉电，还要在目标平台处理文件 `fsync`、目录同步和重命名语义；标准 `fstream` 本身没有提供完整的跨平台持久化事务。

==== INI 格式配置文件

INI 看似只是多了 `[section]`，实际上并没有一份覆盖所有实现的统一规范：行内注释、重复键、转义、大小写和数组写法都可能不同。项目如果采用 INI，应先选定具体解析库和方言，再围绕它做类型与范围验证。

```ini
[pid.speed]
kp = 1.5
ki = 0.1
kd = 0.05

[limits]
max_speed_rpm = 5000
max_current_ma = 10000

[features]
auto_aim = true
```

把单位写进键名能减少“5000 到底是什么单位”的猜测，但仍应在加载后检查组合约束，例如电流必须为正、最小值不能大于最大值。解析库确认的是语法，控制器能否稳定工作还需要独立的参数验证与测试。

配置热更新还多一层并发问题：解析线程先构造不可变的新配置并完成校验，再在短临界区或原子 `shared_ptr` 交换中发布；读线程取得同一份快照。逐字段修改共享对象会让一次控制计算看到混合版本。

==== 日志记录

日志首先是一条事件记录，不是 `cout` 的别名。它至少需要时间、级别和消息，并定义多线程调用时一条记录是否会交错。下面是一份面向 Linux/POSIX 的小型 C++17 示例；`localtime_r` 是平台函数，不是标准 C++ 接口：

```cpp
#include <chrono>
#include <ctime>
#include <fstream>
#include <iomanip>
#include <mutex>
#include <sstream>
#include <stdexcept>
#include <string>

enum class LogLevel { debug, info, warning, error };

class Logger {
public:
    explicit Logger(const std::string& path)
        : file_(path, std::ios::app) {
        if (!file_) {
            throw std::runtime_error("cannot open log file: " + path);
        }
    }

    void setMinimumLevel(LogLevel level) {
        std::lock_guard<std::mutex> lock(mutex_);
        minimum_ = level;
    }

    bool log(LogLevel level, const std::string& message) {
        std::lock_guard<std::mutex> lock(mutex_);
        if (static_cast<int>(level) < static_cast<int>(minimum_)) {
            return true;
        }

        const auto now = std::chrono::system_clock::now();
        const std::time_t raw = std::chrono::system_clock::to_time_t(now);
        std::tm local{};
        if (localtime_r(&raw, &local) == nullptr) {
            return false;
        }

        file_ << std::put_time(&local, "%Y-%m-%d %H:%M:%S")
              << " [" << levelName(level) << "] "
              << message << '\n';
        return static_cast<bool>(file_);
    }

    bool flush() {
        std::lock_guard<std::mutex> lock(mutex_);
        file_.flush();
        return static_cast<bool>(file_);
    }

private:
    static const char* levelName(LogLevel level) noexcept {
        switch (level) {
            case LogLevel::debug:   return "DEBUG";
            case LogLevel::info:    return "INFO";
            case LogLevel::warning: return "WARN";
            case LogLevel::error:   return "ERROR";
        }
        return "UNKNOWN";
    }

    std::ofstream file_;
    std::mutex mutex_;
    LogLevel minimum_ = LogLevel::debug;
};
```

这把锁只协调同一个 `Logger` 实例内的调用，不会自动协调另一个进程或另一个独立实例。`log()` 返回写入流的结果，调用方还要决定日志失败时是降级到标准错误、增加计数还是触发停机；记录失败后继续安静运行，可能让最关键的故障恰好没有证据。

每条记录都 `flush()` 会增加 I/O 压力，但不 flush 又可能在崩溃时丢失尾部缓冲。常见系统会按级别、批次或周期刷新，并在严重错误时做更强处理。即便 `flush()` 成功，数据通常也只是交给操作系统缓存；抵抗掉电需要目标平台的持久化调用和存储保证。

==== 带格式化的日志

C++17 可以先用流构造完整消息，再把整条记录交给 logger：

```cpp
template <typename... Values>
bool logValues(Logger& logger, LogLevel level, Values&&... values) {
    std::ostringstream message;
    (message << ... << std::forward<Values>(values));
    if (!message) {
        return false;
    }
    return logger.log(level, message.str());
}

logValues(logger, LogLevel::info,
          "motor speed=", speedRpm,
          " rpm, temperature=", temperatureC, " C");
```

这避免了 `printf` 格式串与实参类型不匹配造成的未定义行为，也不会被固定的 1024 字节缓冲静默截断。它仍可能分配内存或在自定义 `operator<<` 中抛异常，不适合未经测量就放进严格时限路径。

C++20 的 `std::format` 能提供编译期可检查的格式字符串接口，但工具链支持度要以项目编译环境为准。成熟日志库通常还提供异步队列、结构化字段、源码位置和过滤；选用它们仍要配置队列满时策略，不能把“异步”理解为日志永不阻塞或永不丢失。

==== 日志文件轮转

轮转通常在写下一条记录前检查大小，把 `robot.log` 依次改名为 `.1`、`.2`，并删除超过保留数的旧文件。一个可用实现还要处理这些边界：

- 单条记录本身超过上限时，是允许一个超大文件、截断，还是拒绝记录；
- 文件大小以真实写入字节为准，不能只用 `message.size() + 1` 猜测编码和换行；
- `rename`、`remove`、重新打开任一步都可能失败，失败后当前日志写到哪里；
- 外部工具或另一个进程也可能移动文件，进程内互斥量管不到它们；
- 崩溃发生在一串改名中间时，编号可能出现空洞或重复。

因此，教程里的几行 `std::rename` 适合解释思路，不足以承诺可靠轮转。Linux 服务可以考虑 journald 或 logrotate，程序内可采用经过故障路径测试的日志库。保留数量、磁盘配额和磁盘写满后的降级行为也应在部署方案中明确。

==== 数据记录与回放

数据回放的价值在于“同一份输入能被明确解释”，所以格式契约比直接转储内存更重要。下面用前面的固定小端整数组成一个最小记录文件：文件头是 `RMCV` 和版本号；每条记录保存类型、相对启动时刻的纳秒数以及受限长度的负载。

```cpp
#include <array>
#include <chrono>
#include <cstdint>
#include <fstream>
#include <optional>
#include <stdexcept>
#include <string>
#include <vector>

void writeU64LE(std::ostream& output, std::uint64_t value) {
    for (unsigned int shift = 0; shift < 64; shift += 8) {
        output.put(static_cast<char>((value >> shift) & 0xffu));
    }
}

std::uint64_t readU64LE(std::istream& input) {
    std::uint64_t value = 0;
    for (unsigned int shift = 0; shift < 64; shift += 8) {
        const int byte = input.get();
        if (byte == std::char_traits<char>::eof()) {
            throw std::runtime_error("truncated 64-bit field");
        }
        value |= static_cast<std::uint64_t>(
                     static_cast<unsigned char>(byte)) << shift;
    }
    return value;
}

struct Record {
    std::uint32_t type;
    std::uint64_t elapsedNanoseconds;
    std::vector<std::uint8_t> payload;
};

class RecordWriter {
public:
    explicit RecordWriter(const std::string& path)
        : output_(path, std::ios::binary | std::ios::trunc),
          start_(std::chrono::steady_clock::now()) {
        if (!output_) {
            throw std::runtime_error("cannot create record file");
        }
        output_.write("RMCV", 4);
        writeU32LE(output_, 1); // format version
        ensureOutput();
    }

    void append(std::uint32_t type,
                const std::vector<std::uint8_t>& payload) {
        if (payload.size() > maxPayloadBytes) {
            throw std::length_error("record payload exceeds format limit");
        }
        const auto elapsed = std::chrono::steady_clock::now() - start_;
        const auto nanoseconds =
            std::chrono::duration_cast<std::chrono::nanoseconds>(elapsed);

        writeU32LE(output_, type);
        writeU64LE(output_, static_cast<std::uint64_t>(nanoseconds.count()));
        writeU32LE(output_, static_cast<std::uint32_t>(payload.size()));
        if (!payload.empty()) {
            output_.write(reinterpret_cast<const char*>(payload.data()),
                          static_cast<std::streamsize>(payload.size()));
        }
        ensureOutput();
    }

    bool flush() {
        output_.flush();
        return static_cast<bool>(output_);
    }

    static constexpr std::uint32_t maxPayloadBytes = 16u * 1024u * 1024u;

private:
    void ensureOutput() {
        if (!output_) {
            throw std::runtime_error("record file write failed");
        }
    }

    std::ofstream output_;
    std::chrono::steady_clock::time_point start_;
};

class RecordReader {
public:
    explicit RecordReader(const std::string& path)
        : input_(path, std::ios::binary) {
        if (!input_) {
            throw std::runtime_error("cannot open record file");
        }
        std::array<char, 4> magic{};
        input_.read(magic.data(), static_cast<std::streamsize>(magic.size()));
        if (!input_ || magic != std::array<char, 4>{'R', 'M', 'C', 'V'}) {
            throw std::runtime_error("invalid record-file magic");
        }
        if (readU32LE(input_) != 1) {
            throw std::runtime_error("unsupported record-file version");
        }
    }

    std::optional<Record> next() {
        const int first = input_.peek();
        if (first == std::char_traits<char>::eof()) {
            if (input_.eof()) {
                return std::nullopt;
            }
            throw std::runtime_error("record-file read failure");
        }

        Record record;
        record.type = readU32LE(input_);
        record.elapsedNanoseconds = readU64LE(input_);
        const std::uint32_t size = readU32LE(input_);
        if (size > RecordWriter::maxPayloadBytes) {
            throw std::runtime_error("record payload length is invalid");
        }
        record.payload.resize(size);
        if (size != 0) {
            input_.read(reinterpret_cast<char*>(record.payload.data()),
                        static_cast<std::streamsize>(size));
            if (!input_) {
                throw std::runtime_error("truncated record payload");
            }
        }
        return record;
    }

private:
    std::ifstream input_;
};
```

这份格式避免了结构体填充和本机 `size_t`，也限制了单条分配，但仍只是教学骨架：它没有校验和、压缩、索引、墙上时钟锚点或版本迁移。负载本身还需要按类型定义编码，回放时先核对类型与确切长度，再逐字段解码；不能把 `vector<uint8_t>` 直接强转成 `IMUData*`，那会重新引入对齐、生命期和布局问题。

记录时间使用 `steady_clock` 的相对值，适合重放间隔；它的 epoch 没有跨进程含义。若还要与赛场其他设备对时，应另外保存定义清楚的系统时间、时钟同步状态和误差来源。

最后，能够完整读取一次文件，只验证了这次编码/解码路径。记录系统是否适合比赛还取决于吞吐、队列积压、磁盘写满、进程崩溃和掉电恢复测试。文件操作把数据带出了进程，也把操作系统和存储设备的失败模式带了进来；下一节使用 Eigen 时，我们会回到内存中的数值计算，但同样需要区分“表达式可计算”和“问题在数值上可解”。

=== Eigen 矩阵库
// ⚠️ RoboMaster 必备
// 向量与矩阵运算
// 姿态表示（旋转矩阵、四元数）
// === Eigen 矩阵库

坐标变换、最小二乘和状态估计都离不开线性代数。Eigen 把向量、矩阵、分解和几何变换做成了接近公式的 C++ 接口，因此我们可以把注意力放在“这个矩阵表示什么”。不过，公式写得像纸面推导，并不表示维度、坐标系和数值条件会自动正确。

学习 Eigen 最值得养成的习惯，是让类型表达尺寸，让变量名表达坐标系，并用合适的分解求解问题。直接求逆、凭残差判断一切正常，或把四元数四个数塞进去就当作旋转，都可能得到可编译却不可信的结果。

==== 安装与配置

Ubuntu 软件源通常提供 Eigen 3：

```bash
sudo apt install libeigen3-dev
```

Eigen 主要由头文件组成。CMake 导入目标会传递包含目录和所需编译属性，不代表这里还链接了一份普通运行时库：

```cmake
cmake_minimum_required(VERSION 3.16)
project(eigen_demo LANGUAGES CXX)

find_package(Eigen3 3.3 REQUIRED NO_MODULE)

add_executable(eigen_demo main.cpp)
target_compile_features(eigen_demo PRIVATE cxx_std_17)
target_link_libraries(eigen_demo PRIVATE Eigen3::Eigen)
```

常用头文件按功能选取：

```cpp
#include <Eigen/Core>      // 基本矩阵和数组
#include <Eigen/Geometry>  // 四元数、轴角和变换
#include <Eigen/QR>        // QR 分解

// 小型教程也可以直接包含常用稠密功能：
#include <Eigen/Dense>
```

项目实际找到的 Eigen 版本、编译选项和 CPU 指令集会影响可用 API 与性能。构建成功只确认了这套工具链能实例化用到的代码，不证明目标设备上的耗时已经满足控制周期。

==== 向量与矩阵基础

`Matrix<Scalar, Rows, Cols>` 是核心模板。常用别名把标量与尺寸写进类型：

```cpp
#include <Eigen/Dense>

Eigen::Vector2d imagePoint;                 // 2x1 double
Eigen::Vector3d position;                   // 3x1 double
Eigen::RowVector3f row;                     // 1x3 float
Eigen::Matrix3d rotation;                   // 3x3 double
Eigen::Matrix<double, 3, 4> projection;     // 3x4 double

Eigen::VectorXd dynamicVector(12);          // 运行时长度
Eigen::MatrixXd dynamicMatrix(6, 9);        // 运行时 6x9
```

固定尺寸让编译器在编译期检查更多维度关系，也适合小型、尺寸恒定的机器人状态。动态尺寸适合数据量由文件或传感器决定的情况。固定尺寸不等于在所有场景都更快：大型固定对象会增加栈或对象体积，编译时间和代码尺寸也可能增长，选择应先服从问题尺寸。

默认构造的普通 Eigen 数值矩阵通常没有初始化。要从已知状态开始，应明确给值：

```cpp
Eigen::Vector3d point(1.0, 2.0, 3.0);

Eigen::Matrix3d matrix;
matrix << 1.0, 2.0, 3.0,
          4.0, 5.0, 6.0,
          7.0, 8.0, 9.0; // 逗号初始化器按书写的行列填入

const Eigen::Matrix3d zero = Eigen::Matrix3d::Zero();
const Eigen::Matrix3d identity = Eigen::Matrix3d::Identity();

Eigen::MatrixXd dynamic(3, 4);
dynamic.setZero();
```

访问使用从零开始的 `(row, column)`；向量只写一个索引。固定块能在编译期携带尺寸，动态块则需要运行时参数：

```cpp
const double x = point(0);
const double element = matrix(1, 2);

Eigen::Vector3d firstColumn = matrix.col(0);
Eigen::RowVector3d secondRow = matrix.row(1);
Eigen::Matrix2d corner = matrix.topLeftCorner<2, 2>();

Eigen::MatrixXd table(10, 6);
table.setZero();
Eigen::MatrixXd window = table.block(2, 1, 4, 3);
```

固定尺寸的错误经常在编译期暴露；动态尺寸不匹配通常依赖 Eigen 的运行时断言，而发布构建可能关闭断言。来自文件、网络或 OpenCV 的尺寸应在调用前显式校验，不能把断言当作输入错误处理。

==== 基本运算

矩阵乘法 `*` 与逐元素运算是两套含义。Eigen 用 `array()` 视图或 `cwise...` 方法表达逐元素操作：

```cpp
Eigen::Vector3d first(1.0, 2.0, 3.0);
Eigen::Vector3d second(4.0, 5.0, 6.0);

const double dot = first.dot(second);
const Eigen::Vector3d cross = first.cross(second);
const Eigen::Vector3d componentProduct = first.cwiseProduct(second);
const Eigen::Vector3d shifted = (first.array() + 1.0).matrix();

Eigen::Matrix3d A = Eigen::Matrix3d::Random();
Eigen::Matrix3d B = Eigen::Matrix3d::Random();
Eigen::Matrix3d product = A * B;
Eigen::Vector3d transformed = A * first;
```

归一化前要排除非有限值和接近零的长度。阈值应与单位和噪声尺度相符，下面的值只是调用方传入的策略：

```cpp
#include <cmath>
#include <optional>

std::optional<Eigen::Vector3d>
normalized(const Eigen::Vector3d& vector, double minimumNorm) {
    if (!vector.allFinite() || !std::isfinite(minimumNorm) ||
        minimumNorm <= 0.0) {
        return std::nullopt;
    }
    const double norm = vector.stableNorm();
    if (!std::isfinite(norm) || norm < minimumNorm) {
        return std::nullopt;
    }
    const Eigen::Vector3d result = vector / norm;
    if (!result.allFinite()) {
        return std::nullopt;
    }
    return result;
}
```

比较浮点矩阵通常用带容差的 `isApprox`，容差同样来自问题尺度。它只比较数值接近，不证明矩阵是一个物理上正确的标定结果。

求解 `A x = b` 时，优先让分解直接求 `x`，而不是先构造 `A.inverse()`：

```cpp
#include <Eigen/QR>
#include <optional>

std::optional<Eigen::VectorXd>
solveFullRankLeastSquares(const Eigen::MatrixXd& A,
                          const Eigen::VectorXd& b) {
    if (A.rows() != b.size() || A.rows() < A.cols() ||
        A.cols() == 0 || !A.allFinite() || !b.allFinite()) {
        return std::nullopt;
    }

    Eigen::ColPivHouseholderQR<Eigen::MatrixXd> decomposition(A);
    if (decomposition.rank() != A.cols()) {
        return std::nullopt;
    }

    Eigen::VectorXd x = decomposition.solve(b);
    if (!x.allFinite()) {
        return std::nullopt;
    }
    return x;
}
```

这个函数处理列满秩的方阵或超定最小二乘问题。`rank()` 仍依赖数值阈值；接近秩亏的系统可能对噪声非常敏感，必须结合奇异值、条件估计、参数尺度和领域阈值判断。一个很小的绝对残差也不一定够：当 `A`、`b` 的尺度巨大，或参数方向几乎不可辨识时，解仍可能不稳定。

分解要与矩阵结构匹配：一般可逆方阵可考虑带主元 LU；最小二乘常用 QR；对称正定系统可用 LLT/LDLT；需要观察秩与最小范数解时可考虑 SVD。`A.transpose() * A` 只保证半正定，只有 `A` 列满秩等条件成立时才是正定，而且形成正规方程会放大条件数问题。

对称矩阵的特征分解应使用自伴随求解器，并检查输入与求解状态：

```cpp
#include <Eigen/Eigenvalues>
#include <stdexcept>

Eigen::Matrix3d covariance;
covariance << 2.0, 0.2, 0.0,
              0.2, 1.0, 0.1,
              0.0, 0.1, 0.5;

if (!covariance.isApprox(covariance.transpose(), 1e-12)) {
    throw std::runtime_error("covariance is not symmetric");
}

Eigen::SelfAdjointEigenSolver<Eigen::Matrix3d> solver(covariance);
if (solver.info() != Eigen::Success) {
    throw std::runtime_error("eigendecomposition failed");
}
const Eigen::Vector3d eigenvalues = solver.eigenvalues();
```

求解成功说明算法为这份矩阵返回了结果，不自动证明协方差来源正确。若模型要求正半定，还要按允许的数值容差检查最小特征值。

==== 姿态表示

旋转矩阵、轴角、欧拉角和单位四元数描述的是同一个三维旋转，但接口约定必须先说清：角度是否为弧度，向量是列向量还是行向量，旋转是主动转动物体还是被动更换坐标系，乘法从哪一侧作用。

本节采用 Eigen 常见的列向量主动旋转写法，角度用弧度：

```cpp
#include <Eigen/Geometry>

constexpr double pi = 3.14159265358979323846;
const double yaw = pi / 4.0;
const double pitch = 0.2;
const double roll = -0.1;

const Eigen::AngleAxisd aboutZ(yaw, Eigen::Vector3d::UnitZ());
const Eigen::AngleAxisd aboutY(pitch, Eigen::Vector3d::UnitY());
const Eigen::AngleAxisd aboutX(roll, Eigen::Vector3d::UnitX());

// 右边先作用：先 roll，再 pitch，最后 yaw。
const Eigen::Matrix3d R =
    (aboutZ * aboutY * aboutX).toRotationMatrix();

const Eigen::Vector3d point(1.0, 0.0, 0.0);
const Eigen::Vector3d rotated = R * point;
```

欧拉角便于展示和人机输入，却存在表示不唯一、分支跳变和万向锁。`R.eulerAngles(2, 1, 0)` 返回 Eigen 所选范围内的一组 Z-Y-X 角，不应假定它能连续恢复生成这份旋转时的原始三个数。

单位四元数适合组合和插值，但“Quaternion 类型”不等于系数已经归一化：

```cpp
Eigen::Quaterniond orientation(
    Eigen::AngleAxisd(pi / 3.0, Eigen::Vector3d::UnitZ()));
orientation.normalize();

const Eigen::Vector3d rotatedByQuaternion = orientation * point;
const Eigen::Matrix3d rotationMatrix = orientation.toRotationMatrix();
const Eigen::Quaterniond inverse = orientation.inverse();

const Eigen::Quaterniond identity = Eigen::Quaterniond::Identity();
const Eigen::Quaterniond halfway = identity.slerp(0.5, orientation);
```

只有单位四元数的共轭才等于旋转的逆；接收外部四元数时，应检查四个系数有限且范数不接近零，再归一化或拒绝。`q` 与 `-q` 表示同一旋转，这会影响直接比较系数和时间序列连续化。`slerp` 的参数是否限制在 `[0, 1]`、是否允许外推，也应由调用接口明确。

旋转矩阵也有不变量：`R.transpose() * R` 应接近单位矩阵，行列式应接近 `+1`。普通 `Matrix3d` 不会阻止调用方传入缩放或反射；从估计结果构造姿态前要检查或投影到合适的旋转群，而不能仅看尺寸是 3x3。

==== 坐标变换

`Isometry3d` 把旋转和平移组合起来。最不容易读错的命名方式是 `T_target_source`：它把 source 坐标系中的坐标变成 target 坐标系中的坐标。

```cpp
Eigen::Isometry3d T_world_camera = Eigen::Isometry3d::Identity();
T_world_camera.linear() = orientation.toRotationMatrix();
T_world_camera.translation() = Eigen::Vector3d(0.2, 0.0, 1.5);

const Eigen::Vector3d p_camera(2.0, 0.5, 5.0);
const Eigen::Vector3d p_world = T_world_camera * p_camera;

const Eigen::Isometry3d T_camera_world = T_world_camera.inverse();
const Eigen::Vector3d recovered = T_camera_world * p_world;
```

这里 `T_world_camera * p_camera` 的下标像单位一样约掉。两个变换组合时同理：

```cpp
const Eigen::Isometry3d T_chassis_camera =
    T_chassis_gimbal * T_gimbal_camera;
const Eigen::Vector3d p_chassis = T_chassis_camera * p_camera;
```

右边的相机到云台先作用，再由云台到车体。`translate`、`pretranslate`、`rotate` 的组合顺序容易受当前变换影响；已有标定值时，直接给 `linear()` 和 `translation()` 赋值通常更清楚。

`Isometry3d` 的名字表达“调用者声称这是等距变换”，但直接写入 `linear()` 仍能破坏正交性。反求前要确保旋转部分有效；若混有缩放，应使用 `Affine3d` 等符合实际语义的类型，而不是让错误的模型躲在 `Isometry` 名字下。

==== RoboMaster 应用实例

自瞄坐标链首先要固定轴方向。假设相机、云台都采用 `x` 向前、`y` 向左、`z` 向上，下面的函数把相机测得的目标转到云台系，再计算视线角：

```cpp
#include <Eigen/Geometry>
#include <cmath>
#include <optional>
#include <utility>

class AimGeometry {
public:
    explicit AimGeometry(Eigen::Isometry3d T_gimbal_camera)
        : T_gimbal_camera_(std::move(T_gimbal_camera)) {}

    std::optional<Eigen::Vector2d>
    lineOfSightAngles(const Eigen::Vector3d& p_camera) const {
        if (!p_camera.allFinite()) {
            return std::nullopt;
        }

        const Eigen::Vector3d p_gimbal = T_gimbal_camera_ * p_camera;
        const double horizontal = std::hypot(p_gimbal.x(), p_gimbal.y());
        if (horizontal < 1e-9 && std::abs(p_gimbal.z()) < 1e-9) {
            return std::nullopt; // 目标与转轴原点重合，方向没有定义
        }

        const double yaw = std::atan2(p_gimbal.y(), p_gimbal.x());
        const double pitch = std::atan2(p_gimbal.z(), horizontal);
        return Eigen::Vector2d(yaw, pitch);
    }

private:
    Eigen::Isometry3d T_gimbal_camera_;
};
```

这只计算几何视线，不包含枪口偏移、弹道下坠、通信延迟、云台动态或目标预测。轴方向不同会改变符号；一份能输出角度的代码，不代表角度已经符合机械系统约定。固定变换还应来自标定并带版本与单位，而不是散落在构造函数里的“看起来差不多”的常数。

麦克纳姆轮运动学也依赖轮序、滚子方向和正方向约定。以下矩阵采用一种常见的编号，并在构造时拒绝退化几何：

```cpp
#include <Eigen/Dense>
#include <cmath>
#include <stdexcept>

class MecanumKinematics {
public:
    MecanumKinematics(double wheelRadius,
                      double halfLength,
                      double halfWidth)
        : radius_(wheelRadius), lever_(halfLength + halfWidth) {
        if (!std::isfinite(radius_) || !std::isfinite(lever_) ||
            radius_ <= 0.0 || halfLength < 0.0 || halfWidth < 0.0 ||
            lever_ <= 0.0) {
            throw std::invalid_argument("invalid mecanum geometry");
        }

        inverse_ << 1.0, -1.0, -lever_,
                    1.0,  1.0,  lever_,
                    1.0,  1.0, -lever_,
                    1.0, -1.0,  lever_;
        inverse_ /= radius_;

        const double scale = radius_ / 4.0;
        forward_ << scale,  scale,  scale,  scale,
                   -scale,  scale,  scale, -scale,
                   -scale / lever_,  scale / lever_,
                   -scale / lever_,  scale / lever_;
    }

    Eigen::Vector4d toWheelSpeeds(
        const Eigen::Vector3d& chassisVelocity) const {
        return inverse_ * chassisVelocity;
    }

    Eigen::Vector3d toChassisVelocity(
        const Eigen::Vector4d& wheelSpeeds) const {
        return forward_ * wheelSpeeds;
    }

private:
    double radius_;
    double lever_;
    Eigen::Matrix<double, 4, 3> inverse_;
    Eigen::Matrix<double, 3, 4> forward_;
};
```

如果实物轮序或电机正方向不同，需要相应交换矩阵的行或符号。轮速超限时，逐轮硬截断会改变期望的运动方向；常见策略是按最大比例整体缩放，但是否保留平移或旋转优先级属于底盘控制设计。上面的理想运动学没有包含打滑、轮径误差和执行器动态，需用实测验证。

EKF 和弹道模型同样能用 Eigen 实现，却不适合用几十行“完整类”制造已经可用的印象。EKF 还要处理雅可比、噪声离散化、角度残差、协方差对称性与正定性，更新时通常避免显式求逆并考虑 Joseph 形式；弹道则要验证可达性、单位、阻力模型、积分误差和根的分支。Eigen 负责矩阵计算，不验证这些模型假设。

==== 性能优化技巧

Eigen 的表达式模板会延迟并组合一部分运算，但“看起来一行”不代表没有临时量，也不保证与手写内核一样快。先用目标平台的优化构建测量，再针对热点调整：

- 小而固定的尺寸常有利于展开和向量化；大型对象或动态批量不应机械改成固定模板参数。
- `destination.noalias() = A * B` 是调用者承诺目标不与右侧操作数别名。承诺错误会得到错误结果，它不是通用的“加速开关”。
- `.eval()` 把表达式立即物化，可用于打断危险的惰性引用或明确别名边界，但也可能增加临时对象。
- 块表达式通常是原矩阵的视图。用 `auto` 保存后，原矩阵必须继续存活且不能以使视图失效的方式调整尺寸。
- Eigen 自己的线程与应用线程池、OpenMP、BLAS 线程可能叠加，产生过度订阅；线程数需要通过端到端测量配置。

`Map` 可以让 Eigen 查看已有连续内存，不发生数据复制，但布局、长度、对齐和生命期由调用方保证：

```cpp
double packet[9] = {
    1.0, 2.0, 3.0,
    4.0, 5.0, 6.0,
    7.0, 8.0, 9.0
};

using RowMajorMatrix3d =
    Eigen::Matrix<double, 3, 3, Eigen::RowMajor>;
Eigen::Map<RowMajorMatrix3d> mapped(packet);

mapped(1, 2) = 42.0; // 同时修改 packet[5]
```

Eigen 默认矩阵通常是列主序；网络包或 OpenCV 数据常按行存放，`Map` 类型必须显式匹配。带步长的图像行还需要 `Stride`，不能假定每行紧密连续。

对齐要求取决于 Eigen 版本、编译标准、标量、尺寸和启用的向量指令。C++17 对过对齐动态分配的支持解决了许多旧场景，但把固定尺寸可向量化成员放进自定义分配器、`std::vector` 或跨 ABI 结构时仍应查当前 Eigen 文档。不要机械给每个类添加 `EIGEN_MAKE_ALIGNED_OPERATOR_NEW`，也不要假定一个固定的 16 或 32 字节规则覆盖所有构建。

==== 常见错误

把常见问题放回它们对应的边界，会比背几条口诀更可靠：

```cpp
Eigen::MatrixXd A = readMatrix();
Eigen::VectorXd b = readVector();

if (A.rows() != b.size()) {
    throw std::invalid_argument("A and b dimensions do not match");
}
if (!A.allFinite() || !b.allFinite()) {
    throw std::invalid_argument("linear system contains NaN or infinity");
}

// 若目标出现在右侧，先物化结果，不要错误承诺 noalias。
A = (A * A).eval(); // 这里只在 A 为方阵时有意义
```

- 未初始化的矩阵不会自动变成零；构造后明确 `Zero()`、`Identity()` 或逐项赋值。
- 维度正确只说明乘法有定义，不说明单位、坐标系或时间戳匹配。
- 零向量和非有限向量不能直接归一化；接近零的阈值取决于尺度。
- 不要用显式逆代替线性求解，也不要把分解返回结果扩大为系统条件良好。
- `auto expression = A + B` 可能保存对操作数的引用；需要独立快照时写成具体矩阵类型或调用 `.eval()`。
- `float` 与 `double` 混合、行主序与列主序互操作时要显式转换并检查精度与布局。

Eigen 让矩阵代码更接近推导，但可信结果仍来自清楚的坐标约定、模型假设、输入校验和数值诊断。下一节的 Ceres 会把这些矩阵放进迭代优化器；在那里，“求解器收敛”也只能说明某个数值过程停止在一个解附近，不能单独证明参数可辨识或物理机制正确。

=== Ceres 非线性优化库

很多机器人问题最后都会写成“让预测尽量贴近观测”：相机参数让重投影误差变小，位姿让已知三维点落到对应像素，弹道参数让模拟轨迹接近实测落点。Ceres Solver 擅长求解这类非线性最小二乘问题，并提供自动求导、鲁棒损失和适合旋转等约束变量的流形接口。

它解决的是数值优化，不是自动建模。求解器停下来，只说明在给定残差、初值、约束和数据上满足了某个停止条件；它不会证明观测足以辨识参数，也不会证明拟合出来的系数就是某个真实物理机制。

==== 安装与配置

Ubuntu 软件源通常可以直接安装 Ceres 及其依赖：

```bash
sudo apt update
sudo apt install libceres-dev
```

软件源版本随 Ubuntu 发行版变化。若项目依赖较新的 `Manifold` API、特定稀疏后端或可复现结果，应把 Ceres 版本和构建选项写进项目配置，而不是默认“系统里有一个就行”。

CMake 推荐使用导入目标：

```cmake
cmake_minimum_required(VERSION 3.16)
project(ceres_demo LANGUAGES CXX)

find_package(Ceres REQUIRED)

add_executable(ceres_demo main.cpp)
target_compile_features(ceres_demo PRIVATE cxx_std_17)
target_link_libraries(ceres_demo PRIVATE Ceres::ceres)
```

稀疏求解器能否使用取决于这份 Ceres 的构建依赖。`find_package` 成功不表示 SuiteSparse、CUDA 或所有线性求解器都已启用；需要时检查 CMake 输出与 `Solver::Summary` 中的实际配置。

==== 非线性最小二乘问题

Ceres 处理的典型目标可以写成：

$ 1/2 sum_i rho_i(||f_i(x)||^2) $

`x` 是一个或多个参数块，`f_i` 是残差向量，`rho_i` 是可选的鲁棒损失。残差不是随便相减一下就结束了：不同观测若单位或噪声尺度不同，通常要先按标准差或协方差白化，否则数值大的单位会在平方和中占据更多权重。

下面用固定观测拟合 $y = exp(m x + c)$。每个点带一个正的 `sigma`，残差因此是无量纲的：

```cpp
#include <ceres/ceres.h>
#include <array>
#include <cmath>
#include <iostream>

struct ExponentialResidual {
    ExponentialResidual(double x, double y, double sigma)
        : x_(x), y_(y), inverseSigma_(1.0 / sigma) {}

    template <typename T>
    bool operator()(const T* const parameters, T* residual) const {
        const T prediction = ceres::exp(
            parameters[0] * T(x_) + parameters[1]);
        residual[0] = (prediction - T(y_)) * T(inverseSigma_);
        return true;
    }

private:
    double x_;
    double y_;
    double inverseSigma_;
};

int main() {
    struct Observation { double x; double y; double sigma; };
    const std::array<Observation, 6> observations{{
        {0.0, 1.10, 0.05},
        {0.5, 1.29, 0.05},
        {1.0, 1.49, 0.05},
        {1.5, 1.78, 0.05},
        {2.0, 2.03, 0.05},
        {2.5, 2.39, 0.05}
    }};

    double parameters[2] = {0.0, 0.0}; // m, c
    ceres::Problem problem;

    for (const Observation& observation : observations) {
        auto* cost =
            new ceres::AutoDiffCostFunction<ExponentialResidual, 1, 2>(
                new ExponentialResidual(
                    observation.x, observation.y, observation.sigma));
        problem.AddResidualBlock(cost, nullptr, parameters);
    }

    ceres::Solver::Options options;
    options.linear_solver_type = ceres::DENSE_QR;
    options.max_num_iterations = 50;
    options.minimizer_progress_to_stdout = false;

    ceres::Solver::Summary summary;
    ceres::Solve(options, &problem, &summary);

    if (!summary.IsSolutionUsable() ||
        !std::isfinite(parameters[0]) ||
        !std::isfinite(parameters[1])) {
        std::cerr << summary.BriefReport() << '\n';
        return 1;
    }

    std::cout << summary.BriefReport() << '\n'
              << "m=" << parameters[0]
              << ", c=" << parameters[1] << '\n';
}
```

这段代码展示了定义残差、加入问题、求解和检查报告的最短闭环。它没有证明指数模型适合某份真实数据，也没有检查参数不确定度。若所有 `x` 都挤在很窄的区间，`m` 与 `c` 还可能强相关；即使曲线在样本附近拟合得很好，外推也可能很差。

==== 核心概念

一个残差块由代价函数、可选损失函数和它引用的参数块组成。参数存储必须在求解期间保持地址稳定：把 `vector<double>` 的元素地址交给 Ceres 后再让这个 vector 扩容，会使指针失效。常见做法是先确定尺寸并分配所有参数，再构建 `Problem`。

代价函数主要有三种求导方式：

```cpp
struct AutoDiffCost {
    template <typename T>
    bool operator()(const T* const x, T* residual) const {
        residual[0] = x[0] * x[0] - T(10.0);
        return true;
    }
};

struct NumericDiffCost {
    bool operator()(const double* const x, double* residual) const {
        residual[0] = x[0] * x[0] - 10.0;
        return true;
    }
};

class AnalyticCost : public ceres::SizedCostFunction<1, 1> {
public:
    bool Evaluate(double const* const* parameters,
                  double* residuals,
                  double** jacobians) const override {
        const double x = parameters[0][0];
        residuals[0] = x * x - 10.0;
        if (jacobians != nullptr && jacobians[0] != nullptr) {
            jacobians[0][0] = 2.0 * x;
        }
        return std::isfinite(residuals[0]);
    }
};
```

- 自动求导让 Ceres 用 `Jet` 类型穿过模板表达式，通常能减少手写雅可比错误；它仍会忠实求导一个写错的模型。
- 数值求导便于包装只能接收 `double` 的旧函数，但步长、噪声、分支和参数尺度会影响近似。
- 解析求导可以利用结构并控制计算量，却需要独立检查导数实现，不能凭“手推公式”假定正确。

自动求导函数中的控制流也要谨慎。迭代次数随参数跳变、`abs` 的尖点、越界查表和积分提前停止，都可能让导数不连续或没有预期含义。模板能编译，只说明这些运算支持 `Jet`，不说明优化地形适合局部线性化。

鲁棒损失会降低大残差对目标的影响：

```cpp
auto* cost = makeReprojectionCost(observation);
auto* loss = new ceres::HuberLoss(2.0); // 阈值作用在白化后的残差尺度上
problem.AddResidualBlock(cost, loss, camera, point);
```

阈值 `2.0` 只有在残差尺度定义清楚时才有意义。鲁棒核能减轻异常点影响，却不能识别所有错误对应、修复系统偏差或创造缺失的信息。使用后应同时检查原始残差分布和被降权的样本，而不是只看鲁棒代价下降。

默认情况下，`Problem` 会按其 API 所述接管新建代价函数、损失函数和流形的所有权；具体构造重载与所有权选项会随 Ceres 版本演进。若改成 `DO_NOT_TAKE_OWNERSHIP`，调用方就必须保证对象比 `Problem` 活得久，不能为了少写 `new` 而模糊责任。

==== 参数化与流形

四元数只有三个局部自由度，直接在四个系数上做普通加法会离开单位球面。现代 Ceres 用 `Manifold` 描述局部更新：

```cpp
// ceres::QuaternionManifold 使用 [w, x, y, z] 顺序。
double rotation[4] = {1.0, 0.0, 0.0, 0.0};
problem.AddParameterBlock(rotation, 4);
problem.SetManifold(rotation, new ceres::QuaternionManifold);

// 平移是普通欧氏参数块。
double translation[3] = {0.0, 0.0, 1.0};
problem.AddParameterBlock(translation, 3);
```

`Eigen::Quaterniond::coeffs().data()` 的内存顺序通常是 `[x, y, z, w]`，与上面的 Ceres 顺序不同。直接优化 Eigen 的系数存储时，应使用 Ceres 对应版本提供的 `EigenQuaternionManifold`，并再次核对版本文档；名字里的 “Eigen” 正是在提醒这项布局差异。

流形维持表示约束，不保证初始数组自动有效。初始四元数应有限且归一化，也要避免接近零。优化后 `q` 与 `-q` 表示同一旋转，验证时应比较旋转作用或相对旋转，而不是逐系数要求同号。

固定整个参数块和设置边界的接口更直接：

```cpp
problem.SetParameterBlockConstant(intrinsics);

problem.SetParameterLowerBound(focalLength, 0, 1.0);
problem.SetParameterUpperBound(focalLength, 0, 5000.0);
```

边界只是搜索域，不是校准证据。结果贴在边界上可能表示数据偏好边界外、初值/尺度有问题，或模型不可辨识，应作为诊断信号。固定一部分坐标可用 `SubsetManifold`，但固定哪些自由度必须与 gauge freedom 和物理参考系一致。

旧版 Ceres 使用 `LocalParameterization`，新版文档主要使用 `Manifold`。复制网上示例前先确认项目版本，不要把两个时代的 API 拼在同一个代码块里。

==== 求解器配置

选项应根据参数块结构和规模设定，而不是把所有“高级开关”一起打开：

```cpp
ceres::Solver::Options options;
options.max_num_iterations = 100;
options.function_tolerance = 1e-8;
options.gradient_tolerance = 1e-10;
options.parameter_tolerance = 1e-10;
options.num_threads = 4;
options.linear_solver_type = ceres::DENSE_QR;

ceres::Solver::Summary summary;
ceres::Solve(options, &problem, &summary);

std::cout << summary.FullReport() << '\n';
if (!summary.IsSolutionUsable()) {
    throw std::runtime_error("Ceres did not produce a usable solution");
}
```

小型稠密问题常从 `DENSE_QR` 开始；典型 bundle adjustment 可以利用 Schur 结构；大型稀疏问题才会考虑相应稀疏求解器，并确认构建确实包含后端。正规方程类方法可能受条件数影响，不能只因一次运行更快就替代数值诊断。

迭代次数、函数变化、梯度和参数步长都只是停止条件。`CONVERGENCE` 不等于全局最优，也不等于参数正确；`NO_CONVERGENCE` 也可能留下一个对某些用途可评估的中间结果，但不能静默提交。至少要检查：

1. 初始与最终代价、终止原因及失败消息；
2. 参数与残差是否有限，是否撞到边界；
3. 原始残差按数据来源、位置和时间的分布；
4. 雅可比秩、协方差或其他可辨识性诊断；
5. 未参与拟合的独立数据或重复采集是否得到相近结果。

线程数越多也不保证越快。问题太小、残差过轻或系统已有线程池时，并行开销与过度订阅可能占上风；应在目标机器上测量，并把结果限定到对应数据规模和构建配置。

==== RoboMaster 应用：相机标定

相机标定通常同时估计内参、畸变和每张标定图的外参。残差是观测角点与模型投影之差，但一个可用流程还需要：

- 检查图像尺寸、角点顺序和亚像素定位质量；
- 给每张图提供有效的初始外参，避免初始深度为零；
- 让标定板覆盖视场、距离和倾角，不能只在画面中央平移；
- 明确畸变模型和参数顺序，不把 OpenCV、Ceres 与相机 SDK 的系数布局混用；
- 对焦距、主点和畸变设置物理可解释的范围，并观察是否撞界；
- 用未参与拟合的图像检查重投影，而不只报告训练集均方误差。

投影残差的核心形状可以这样写，实际标定还会把内参和畸变改成参数块：

```cpp
#include <ceres/ceres.h>
#include <ceres/rotation.h>

struct ReprojectionResidual {
    ReprojectionResidual(double pointX, double pointY, double pointZ,
                         double observedU, double observedV,
                         double fx, double fy, double cx, double cy,
                         double sigmaPixels)
        : point_{pointX, pointY, pointZ},
          observed_{observedU, observedV},
          intrinsics_{fx, fy, cx, cy},
          inverseSigma_(1.0 / sigmaPixels) {}

    template <typename T>
    bool operator()(const T* const quaternion,
                    const T* const translation,
                    T* residuals) const {
        const T point[3] = {
            T(point_[0]), T(point_[1]), T(point_[2])
        };
        T camera[3];
        ceres::QuaternionRotatePoint(quaternion, point, camera);
        camera[0] += translation[0];
        camera[1] += translation[1];
        camera[2] += translation[2];

        if (camera[2] <= T(1e-6)) {
            return false; // 该线性化点不在模型允许的相机前方
        }

        const T predictedU =
            T(intrinsics_[0]) * camera[0] / camera[2] + T(intrinsics_[2]);
        const T predictedV =
            T(intrinsics_[1]) * camera[1] / camera[2] + T(intrinsics_[3]);
        residuals[0] =
            (predictedU - T(observed_[0])) * T(inverseSigma_);
        residuals[1] =
            (predictedV - T(observed_[1])) * T(inverseSigma_);
        return true;
    }

private:
    double point_[3];
    double observed_[2];
    double intrinsics_[4];
    double inverseSigma_;
};
```

构造残差前还应验证 `sigmaPixels > 0`、所有数值有限、焦距为正。求值返回 `false` 会让 Ceres 处理这个无效点，但若初值本身让大量观测无效，优化并没有凭空找到正确象限的责任；应先用几何方法取得可行初值。

鲁棒核可以缓解少量角点误检，却不能替代角点质量控制。若内参变化很大仍有相近重投影误差，可能是采集姿态不足或参数相关，而不是“优化器很灵活”。

==== RoboMaster 应用：PnP 问题

PnP 已知内参和 3D—2D 对应，求相机位姿。实际工程常先用 OpenCV 的 PnP/RANSAC 获得初值与内点，再用 Ceres 在明确的内点集合上细化；局部优化器不负责从任意初值中发现正确姿态。

```cpp
#include <algorithm>
#include <Eigen/Core>
#include <cmath>
#include <stdexcept>
#include <vector>

struct PointObservation {
    Eigen::Vector3d point;
    Eigen::Vector2d pixel;
    double fx;
    double fy;
    double cx;
    double cy;
    double sigmaPixels;
};

ceres::Solver::Summary refinePose(
    const std::vector<PointObservation>& observations,
    double quaternion[4], // [w, x, y, z]
    double translation[3]) {
    if (observations.size() < 4) {
        throw std::invalid_argument("too few PnP correspondences");
    }

    double quaternionScale = 0.0;
    for (int i = 0; i < 4; ++i) {
        if (!std::isfinite(quaternion[i])) {
            throw std::invalid_argument("invalid initial quaternion");
        }
        quaternionScale = std::max(quaternionScale, std::abs(quaternion[i]));
    }
    if (quaternionScale == 0.0) {
        throw std::invalid_argument("initial quaternion is near zero");
    }

    double scaledNormSquared = 0.0;
    for (int i = 0; i < 4; ++i) {
        const double scaled = quaternion[i] / quaternionScale;
        scaledNormSquared += scaled * scaled;
    }
    const double scaledNorm = std::sqrt(scaledNormSquared);
    if (quaternionScale < 1e-12 / scaledNorm) {
        throw std::invalid_argument("initial quaternion is near zero");
    }
    for (int i = 0; i < 4; ++i) {
        quaternion[i] = (quaternion[i] / quaternionScale) / scaledNorm;
    }
    for (double value : {translation[0], translation[1], translation[2]}) {
        if (!std::isfinite(value)) {
            throw std::invalid_argument("invalid initial translation");
        }
    }

    ceres::Problem problem;
    problem.AddParameterBlock(quaternion, 4);
    problem.SetManifold(quaternion, new ceres::QuaternionManifold);
    problem.AddParameterBlock(translation, 3);

    for (const PointObservation& observation : observations) {
        if (!observation.point.allFinite() ||
            !observation.pixel.allFinite() ||
            !std::isfinite(observation.fx) || observation.fx <= 0.0 ||
            !std::isfinite(observation.fy) || observation.fy <= 0.0 ||
            !std::isfinite(observation.cx) ||
            !std::isfinite(observation.cy) ||
            !std::isfinite(observation.sigmaPixels) ||
            observation.sigmaPixels <= 0.0) {
            throw std::invalid_argument("invalid PnP observation");
        }
        auto* cost =
            new ceres::AutoDiffCostFunction<ReprojectionResidual, 2, 4, 3>(
                new ReprojectionResidual(
                    observation.point.x(),
                    observation.point.y(),
                    observation.point.z(),
                    observation.pixel.x(),
                    observation.pixel.y(),
                    observation.fx, observation.fy,
                    observation.cx, observation.cy,
                    observation.sigmaPixels));
        problem.AddResidualBlock(cost, new ceres::HuberLoss(2.0),
                                 quaternion, translation);
    }

    ceres::Solver::Options options;
    options.linear_solver_type = ceres::DENSE_QR;
    options.max_num_iterations = 50;

    ceres::Solver::Summary summary;
    ceres::Solve(options, &problem, &summary);
    return summary;
}
```

“至少四点”只是数量下限，不保证构型良好。共线、近共线、平面退化分支、重复点和错误对应都会影响可解性；装甲板这类共面点还可能出现多个姿态候选。细化后应检查正深度、重投影分布、旋转/平移跳变，并根据目标几何与时间连续性处理多解，而不是仅判断 `termination_type == CONVERGENCE`。

==== RoboMaster 应用：弹道模型参数辨识

弹道拟合尤其容易把数值结果讲成机制。假设阻力形式以后，Ceres 可以找出让该模型残差变小的参数；低代价只验证“这组参数与这批数据在这个模型下相容”，不能排除出膛速度偏差、枪口姿态误差、时间同步、空气密度或另一种阻力模型产生相同现象。

数值积分放进自动求导残差时，还要固定并验证积分方法。循环次数随参数变化、以“越过目标距离”为停止条件，会给目标函数引入不连续；过大的步长产生模型误差，过小步长又让每次线性化极其昂贵。更稳妥的路径可能是解析灵敏度、可微分的固定时间网格，或经梯度检查的数值求导封装，具体取决于模型。

辨识前应问：不同距离、仰角和速度是否真正激发了各参数？如果两个系数总以近似相同方式改变落点，它们就难以分别识别。把参数限制在“看起来合理”的范围能防止跑飞，却不能创造辨识信息。

最终至少用不同日期或未参与拟合的发射数据检验落点误差，并把效果与机制分开报告：可以说“在这些距离和环境下，校正后的预测误差降低”；没有排除替代解释时，不应说“已确认阻力系数就是误差根因”。

==== RoboMaster 应用：IMU 内参标定

IMU 的零偏、刻度和轴间不正交可以放入同一个残差模型，但观测设计决定它们是否可辨识。静止加速度计只知道重力模长时，并不知道每次姿态下完整的“真实重力向量”；若这个向量来自同一只待标定 IMU，就形成了循环论证。

多姿态静置法通常依赖已知重力模长和充分分散的朝向；更完整的标定还可能需要转台或外部姿态参考。温度、迟滞、安装应力和饱和也会让一次室温标定无法泛化到赛场全范围。

残差应按各轴噪声白化，尺度参数可用对数参数化保持为正，矩阵模型要明确“原始值到校正值”还是反方向。优化后除了代价，还要检查参数相关性、校正后静止模长在各姿态的分布，以及独立动态数据。参数数值像某个常见量级，只能说明相容，不能单独诊断传感器机制。

==== RoboMaster 应用：手眼标定

手眼标定常写成 $A X = X B$，但四个字母的坐标方向必须逐一注明。把“相机看标定板的运动”取逆与否写错，优化器仍可能给出一个有限矩阵，只是它不再表示预期的外参。

旋转残差与平移残差单位不同，直接拼成六维向量就隐含了一个权重选择；应依据测量噪声或任务尺度白化。运动对也要有足够多样的旋转轴和平移，若云台只绕一根轴小幅运动，某些自由度可能不可观。

四元数用流形维持单位长度后，旋转误差仍应采用在 SO(3) 上定义清楚的局部误差，并处理接近 180 度的分支。结果验证应使用未参与求解的运动对，分别报告旋转和平移闭环误差，还要在实物上验证外参链的方向。

因此，一段 `HandEyeResidual` 能编译只是模型实现的起点。只有坐标约定、数据激励、权重和独立验证都站得住，外参才适合进入部署候选。

==== 调试与常见问题

优化不理想时，不要先把迭代次数从 100 改成 1000。最小而有区分力的检查通常是：

1. 在初值处逐个计算残差，确认单位、符号、索引和有限性；
2. 对一小组参数比较自动/解析雅可比与中心有限差分；
3. 人为扰动一个参数，观察残差变化方向是否符合几何直觉；
4. 查看参数块尺度、雅可比列范数、秩和相关性；
5. 用已知参数生成合成数据，验证代码在明确假设下能否恢复，再把这个结果限定为代码测试；
6. 留出独立真实数据，检查效果能否离开拟合集合。

Ceres 可以在调试构建中检查梯度：

```cpp
ceres::Solver::Options options;
options.check_gradients = true;
options.gradient_check_relative_precision = 1e-6;
options.minimizer_progress_to_stdout = true;
```

有限差分与自动求导相符，能增加对导数实现的信心，却不能验证残差模型、数据对应或噪声假设。合成恢复也只验证代码在生成模型与测试假设下的行为，不是现实机制的独立证据。

性能调优同样从报告和 profile 开始。Schur 求解器适合特定块结构，稀疏求解器需要可用后端；把 `num_threads` 设为硬件线程数可能与图像管线争抢核心。`DO_NOT_TAKE_OWNERSHIP` 只改变生命期责任，不是普遍性能技巧。

最后，把结果分层陈述：直接测到的是代价、残差和留出集误差；参数与某种机制“相符”仍只是关联；只有独立干预、消融或能排除主要替代解释的证据，才支持因果结论。下一节转到 OpenCV 图像处理，同样会坚持这条边界：一张图上框出了灯条，不等于检测器已经覆盖比赛环境。

=== OpenCV 基础

OpenCV 是机器人视觉里最常见的工具箱之一：读相机、转换颜色、找轮廓、做透视变换和运行神经网络，都能在同一套接口里完成。本节不打算把两千多个函数排成字典，而是沿着仓库里的一个装甲板演示，先认识 `cv::Mat`，再把“亮斑—灯条—配对—分类”串成一条能观察每级输出的流水线。

配套素材位于 `examples/test.mp4`，程序在 `examples/cpp/color_spaces.cpp` 和 `examples/cpp/lightbar_pipeline.cpp`，模型及来源说明位于 `examples/cpp/model/`。示例中的相对路径以 `examples/cpp/` 为工作目录。安装了 OpenCV 4 开发包后，可以这样编译：

```bash
g++ -std=c++17 -O2 color_spaces.cpp -o color_spaces \
  $(pkg-config --cflags --libs opencv4)
```

这条命令能否执行取决于本机 `pkg-config` 与 OpenCV 安装；CMake 项目仍应使用自己的 `find_package(OpenCV)` 和目标配置。演示在一段固定视频上给出可复查的现象，不代表这些阈值已经覆盖相机、曝光和赛场的全部变化。

==== cv::Mat：图像头与共享像素

`cv::Mat` 同时保存尺寸、类型、步长等图像头信息，以及一块像素数据的视图。由 OpenCV 分配的普通 `Mat` 通常用引用计数共享像素，因此复制头很便宜；共享也意味着通过任一别名写像素，其他别名会看见变化：

```cpp
#include <opencv2/opencv.hpp>
#include <stdexcept>

cv::Mat image = cv::imread("frame.png", cv::IMREAD_COLOR);
if (image.empty()) {
    throw std::runtime_error("frame.png could not be decoded");
}

cv::Mat alias = image;       // 共享像素
cv::Mat snapshot = image.clone(); // 独立复制像素

alias.at<cv::Vec3b>(0, 0) = cv::Vec3b{0, 0, 255};
// image 的同一像素也改变，snapshot 不变。
```

“赋值产生别名，`clone()` 产生副本”是很有用的入门记忆，但还要补两条边界。第一，`Mat` 也可以包装调用方提供的外部缓冲区，此时外部对象的生命期未必由引用计数接管；第二，共享头的生命期管理不等于像素访问线程安全，多个线程并发写同一图像仍需要同步或独立副本。

ROI 也是共享视图：

```cpp
const cv::Rect requested(x, y, width, height);
const cv::Rect bounds(0, 0, image.cols, image.rows);
const cv::Rect clipped = requested & bounds;
if (clipped.empty()) {
    throw std::out_of_range("ROI does not intersect the image");
}

cv::Mat roi = image(clipped);       // 写 roi 会修改 image
cv::Mat roiCopy = roi.clone();      // 独立保存这一块
```

像素类型必须与访问模板一致：`CV_8UC3` 常对应 `cv::Vec3b`，但灰度图、浮点深度图和其他通道数需要不同类型。越界和类型错误不能依赖发布构建里的断言替输入校验。

图像按行保存，却不保证整个矩阵是一段没有间隙的连续数组。ROI 和带对齐步长的相机帧常使 `step` 大于一行有效字节；逐行访问可用 `ptr(row)`，只有 `isContinuous()` 成立时才适合把所有元素当成一段。访问顺序对性能的影响需要在目标图像、操作和硬件上测量，不能从一次基准固定出“快多少倍”。

==== 读取图像与视频

`imread` 失败时返回空矩阵，`imwrite` 用布尔结果报告编码/写入是否成功。视频文件和相机都通过 `VideoCapture`，但设备后端、编解码器与属性支持可能不同：

```cpp
#include <opencv2/opencv.hpp>
#include <optional>
#include <string>

std::optional<cv::Mat> grabFrame(const std::string& path,
                                 double positionMilliseconds) {
    if (positionMilliseconds < 0.0) {
        return std::nullopt;
    }

    cv::VideoCapture capture(path);
    if (!capture.isOpened()) {
        return std::nullopt;
    }
    if (!capture.set(cv::CAP_PROP_POS_MSEC, positionMilliseconds)) {
        return std::nullopt;
    }

    cv::Mat frame;
    if (!capture.read(frame) || frame.empty()) {
        return std::nullopt;
    }
    return frame;
}
```

对压缩视频按毫秒定位可能受关键帧和后端实现影响，得到的是该后端所能定位的帧，不应未经核对就当作精确传感器时间戳。相机的曝光、分辨率等 `set` 调用也可能被拒绝或近似处理；需要读回属性，并用图像与设备时间戳验证真实行为。

GUI 调试用的 `imshow` / `waitKey` 依赖显示环境，不适合无桌面的机器人进程。部署程序通常把中间结果写入有界调试通道或按需保存，同时检查磁盘和带宽策略。

==== 颜色空间：先问信号在哪里

OpenCV 读入彩色图的默认通道顺序是 BGR，不是 RGB。转换和拆分可以这样写：

```cpp
cv::Mat gray;
cv::Mat hsv;
cv::cvtColor(frame, gray, cv::COLOR_BGR2GRAY);
cv::cvtColor(frame, hsv, cv::COLOR_BGR2HSV);

std::vector<cv::Mat> channels;
cv::split(hsv, channels);
// channels[0] 是 H，channels[1] 是 S，channels[2] 是 V。
```

#figure(
  image("images/cpp-opencv-colorspaces.png", width: 100%),
  caption: [仓库样例在同一区域生成的 BGR、灰度、H 与 V 视图。这个样本里灯条在灰度和 V 中更突出；低饱和区域的 H 值则不适合单独解释。],
)

HSV 能把色相、饱和度和亮度分开观察，却没有保证 H 在所有像素上都可靠。饱和度很低时，色相对微小噪声很敏感；高光过曝时，各通道又可能一起接近上限。一个常见思路是先按亮度找发光候选，再在候选内部比较蓝、红证据，但它仍会受白平衡、曝光、传感器响应和背景颜色影响。

配套示例在轮廓内部累计 B 与 R 通道。白色核心对两边贡献相近，周围带色像素可能主导差值；这是对该图像形成结果的一种解释，不是对所有相机域的鲁棒性证明。更稳妥的评估要按相机、曝光、距离和场地分层统计混淆，而不是只观察一帧投票正确与否。

==== 实战：在比赛画面里找出装甲板

演示流水线有四级，每一级都把问题缩小一点：

- *亮度候选*：灰度图按阈值二值化，先找出亮区域，不在这一步决定阵营。
- *灯条筛选*：对轮廓拟合旋转矩形，用长度、宽长比和倾角筛出“像灯条”的候选，再统计颜色证据。
- *几何配对*：只在目标颜色中配对，检查两灯条长度、连线倾角和归一化间距。
- *图案分类*：把候选中间区域透视展开，交给随仓库提供的 MLP，拒绝 `negative` 或分数不足的候选。

这些阶段不是从“宽松”自动走向“真相”。每加一条规则都会同时改变假阳性和假阴性；分类器也只在训练分布与预处理一致的程度上有意义。把每级中间结果画出来，正是为了看见错误在哪一级进入、又在哪一级被保留或误删。

核心几何判断应先防住退化尺寸，并用 `atan2` 避免除以零：

```cpp
#include <cmath>

bool isLight(const Light& light) {
    if (!std::isfinite(light.length) ||
        !std::isfinite(light.width) ||
        !std::isfinite(light.tiltDegrees) ||
        light.length <= 0.0f || light.width <= 0.0f) {
        return false;
    }
    const float ratio = light.width / light.length;
    return ratio > 0.1f && ratio < 0.4f &&
           std::abs(light.tiltDegrees) < 40.0f;
}

bool hasArmorSpacing(const Light& left, const Light& right) {
    const float averageLength = (left.length + right.length) * 0.5f;
    if (!std::isfinite(averageLength) || averageLength <= 0.0f) {
        return false;
    }

    const cv::Point2f delta = right.center - left.center;
    const float distance = std::hypot(delta.x, delta.y) / averageLength;
    const float lineAngle = std::atan2(
        std::abs(delta.y), std::abs(delta.x)) * 180.0f /
        static_cast<float>(CV_PI);

    const bool small = distance >= 0.8f && distance < 3.2f;
    const bool large = distance >= 3.2f && distance < 5.5f;
    return (small || large) && lineAngle < 35.0f;
}
```

这里的数字是配套演示的配置，不是 OpenCV 或装甲板几何推导出的常数。换分辨率、镜头畸变、曝光或目标倾角后，候选分布会变化；阈值要在明确的数据集上选择，并在未参与选择的数据上报告召回与误检。

颜色累计应使用足够宽的整数类型，并只访问裁剪到图像内的掩膜区域：

```cpp
std::uint64_t blueSum = 0;
std::uint64_t redSum = 0;

for (int row = roi.y; row < roi.y + roi.height; ++row) {
    const cv::Vec3b* pixels = frame.ptr<cv::Vec3b>(row);
    const std::uint8_t* maskPixels = contourMask.ptr<std::uint8_t>(row);
    for (int col = roi.x; col < roi.x + roi.width; ++col) {
        if (maskPixels[col] != 0) {
            blueSum += pixels[col][0];
            redSum += pixels[col][2];
        }
    }
}
```

还要定义差值接近零时是“不确定”还是硬分到某一类；原演示用二选一，生产接口更适合保留置信或未知状态。

#block(breakable: false)[
#figure(
  image("images/cpp-opencv-lightbar.png", width: 100%),
  caption: [配套演示的四级输出：原帧、亮度二值图、灯条与配对候选，以及最终分类标记。它适合逐级追踪这一帧的取舍，不代表总体性能。],
)
]

在当前仓库素材、模型和本机 OpenCV 4.6 上直接运行随附程序，输出为：

```text
lights: 11
geometry candidates: 4
candidate center=(672, 511) -> guard 99.9%
candidate center=(734, 504) -> negative 100.0%
candidate center=(823, 500) -> negative 100.0%
candidate center=(798, 496) -> guard 99.9%
```

这直接说明该程序在所定位的帧上产生了 11 个灯条候选、4 个几何组合，并由模型给出上述 softmax 分数。它没有直接说明 11 个颜色标签全部正确，也没有证明两个 `guard` 就一定是真实哨兵。softmax 的 99.9% 更不是天然校准过的现实概率；两个候选还共享同一帧、同一车辆外观和同一模型，不能当作独立证据简单相乘。

图中可以看到级联的两面性：部分杂亮斑进入早期候选，后续几何或分类会删掉其中一些；“两灯之间不能夹第三灯”的规则也可能把被数字亮斑干扰的真实配对一起否决。这是该帧中可观察到的取舍，说明需要统计各级错误，而不是证明单帧几何在原理上永远无法区分。

时间跟踪能利用连续运动与身份一致性，帮助跨过短暂遮挡和单帧抖动；它也可能把稳定的假目标延续很多帧。神经网络能从数据学习比手写阈值更复杂的特征，却会带来训练域、置信校准和算力的新边界。成熟系统通常让检测、分类、跟踪和几何模型互相提供证据，同时保留失配与降级路径。

因此，这个示例最值得带走的不是 `160`、`0.4` 或某个分类分数，而是可观测的级联方法：每一级有清楚输入、输出与失败样本，参数来自数据，结论限定在测试域。检测框之后还要结合相机内参、点序与 PnP 处理三维位姿；那一步同样要检查多解、坐标约定和留出验证。

下一节把结果送出进程。串口协议面对的不是图像噪声，而是半包、粘包、校验失败和设备断开；处理方式仍相似——先定义边界，再让每一级只提交完整、可验证的数据。

=== 串口通信

视觉程序算出角度以后，还要把一串字节交给电控。Linux 把 USB 转串口设备暴露成 `/dev/ttyUSB*` 或 `/dev/ttyACM*`，但 `read` / `write` 看到的只是连续字节：它们不知道哪几个字节是一帧，也不知道某条指令是否已经过时。

因此串口程序其实有三层责任：termios 配置决定内核怎样交付字节，协议编码决定两端怎样解释字节，状态机决定怎样从半包、粘包和损坏中恢复。任何一层“差不多”都可能让另一端读出一个数值正常、含义却完全错误的命令。

仓库的 `examples/cpp/serial_loopback.cpp` 是一份紧凑的 pty 演示，便于观察原始模式、CRC 和逐字节解析。本节会先说明它验证了什么，再给出更适合长期协议的显式编码方式。

==== 打开并配置串口

串口可以用 `open` 取得文件描述符，再用 termios 配置成 115200、8 数据位、无校验、1 停止位（8N1）和无流控：

```cpp
#include <fcntl.h>
#include <termios.h>
#include <unistd.h>

bool configureSerial(int fd, speed_t baud = B115200) {
    termios settings{};
    if (tcgetattr(fd, &settings) != 0) {
        return false;
    }

    cfmakeraw(&settings);
    if (cfsetispeed(&settings, baud) != 0 ||
        cfsetospeed(&settings, baud) != 0) {
        return false;
    }

    settings.c_cflag &= static_cast<tcflag_t>(~(CSIZE | PARENB | CSTOPB));
    settings.c_cflag |= CS8 | CLOCAL | CREAD;
#ifdef CRTSCTS
    settings.c_cflag &= static_cast<tcflag_t>(~CRTSCTS);
#endif
    settings.c_iflag &= static_cast<tcflag_t>(~(IXON | IXOFF | IXANY));

    // 本例用 O_NONBLOCK + poll 管理等待，termios 本身不再阻塞。
    settings.c_cc[VMIN] = 0;
    settings.c_cc[VTIME] = 0;

    return tcsetattr(fd, TCSANOW, &settings) == 0;
}

int openSerial(const char* path) {
    const int fd = open(path, O_RDWR | O_NOCTTY | O_CLOEXEC | O_NONBLOCK);
    if (fd < 0) {
        return -1;
    }
    if (!configureSerial(fd)) {
        close(fd);
        return -1;
    }
    return fd; // 调用方拥有 fd，结束时必须 close。
}
```

`cfmakeraw` 关闭回显、规范行缓冲和常见字符转换，否则二进制中的控制字节可能被终端行规程解释。`O_NOCTTY` 避免设备成为进程的控制终端，`O_CLOEXEC` 避免文件描述符意外泄漏给 `exec` 后的新程序。

这里选用非阻塞描述符配合 `poll()`，所以 `VMIN` / `VTIME` 设为零。另一种方案是阻塞 `read`：当 `VMIN > 0` 且 `VTIME > 0` 时，计时通常要在首字节到达后才开始；对端完全沉默时仍可能一直等待。不要把两套等待模型混在一起，再靠一次实验猜超时语义。

事件循环应检查 `POLLIN`、`POLLOUT`、`POLLERR` 和 `POLLHUP`，处理被信号中断的 `poll/read/write`，并给停机留一条唤醒路径。`read` 与 `write` 都可能只处理请求的一部分；非阻塞模式还会返回 `EAGAIN`。发送函数必须保留未写尾部并等待下一次可写，不能把一次 `write(fd, frame, 13)` 等同于整帧已经上路。

`tcdrain()` 最多等待本机驱动的发送队列排空，不表示单片机已经解析或执行。需要确认的命令要在协议里设计应答、序号、超时和重试；只关心最新姿态的周期命令则可能选择丢弃旧帧。可靠性策略属于每种消息类型，不能统一叫作“UDP 哲学”。

设备打不开时可检查路径、占用者和当前发行版使用的设备组（不少 Ubuntu 系统是 `dialout`），但不要用长期 `chmod 666` 掩盖权限设计。USB 枚举名会变化，部署时可按稳定设备属性建立 udev 符号链接，并验证同型号多设备的区分方式。

==== 定义帧：先定义线上字节

把 `#pragma pack(1)` 的结构体直接写到串口很诱人，却把协议绑定到编译器布局、字节序、浮点格式和字段对齐。`static_assert(sizeof(Frame) == 11)` 只能确认本次编译的大小，不能说明另一端怎样解释每个 float，也不能提供版本迁移。

更稳妥的起点是先画出线上格式。下面定义一个固定 13 字节的小端帧：

```text
偏移  长度  含义
0     1     帧头 0xA5
1     1     协议版本 1
2     1     消息类型 1（云台指令）
3     1     负载长度 7
4     2     序号 uint16，小端
6     2     yaw，单位 0.01 度，int16，小端
8     2     pitch，单位 0.01 度，int16，小端
10    1     标志位，bit0 表示开火建议
11    2     CRC-16/CCITT-FALSE，小端，覆盖偏移 0..10
```

定点角度避免了跨 ABI 传 float，代价是范围和分辨率被协议固定。`int16` 的 0.01 度量化覆盖约 `[-327.68, 327.67]` 度；编码前必须检查有限性和范围，而不是让转换静默回绕。

CRC 参数也必须完整写出。这里使用多项式 `0x1021`、初值 `0xFFFF`、不反射、结果不异或的 CRC-16/CCITT-FALSE；标准测试串 `123456789` 应得到 `0x29B1`：

```cpp
#include <cstddef>
#include <cstdint>

std::uint16_t crc16CcittFalse(const std::uint8_t* data,
                              std::size_t size) {
    std::uint16_t crc = 0xFFFFu;
    for (std::size_t i = 0; i < size; ++i) {
        crc ^= static_cast<std::uint16_t>(data[i]) << 8;
        for (int bit = 0; bit < 8; ++bit) {
            crc = (crc & 0x8000u) != 0
                ? static_cast<std::uint16_t>((crc << 1) ^ 0x1021u)
                : static_cast<std::uint16_t>(crc << 1);
        }
    }
    return crc;
}
```

CRC 能以规定的检错性质发现许多传输错误，却不能保证所有损坏都被发现，也不是防伪认证。面对可能被主动注入的数据，需要带密钥的认证协议，而不是把 CRC 位数继续加大。

显式编码把范围检查和字节布局放在一起：

```cpp
#include <array>
#include <cmath>
#include <cstdint>
#include <limits>
#include <optional>

struct GimbalCommand {
    std::uint16_t sequence;
    double yawDegrees;
    double pitchDegrees;
    bool fire;
};

constexpr std::size_t commandFrameSize = 13;

void putU16LE(std::array<std::uint8_t, commandFrameSize>& frame,
              std::size_t offset, std::uint16_t value) {
    frame[offset] = static_cast<std::uint8_t>(value & 0xffu);
    frame[offset + 1] = static_cast<std::uint8_t>(value >> 8);
}

std::optional<std::array<std::uint8_t, commandFrameSize>>
encodeCommand(const GimbalCommand& command) {
    constexpr double scale = 100.0;
    constexpr double minimum =
        static_cast<double>(std::numeric_limits<std::int16_t>::min()) / scale;
    constexpr double maximum =
        static_cast<double>(std::numeric_limits<std::int16_t>::max()) / scale;

    if (!std::isfinite(command.yawDegrees) ||
        !std::isfinite(command.pitchDegrees) ||
        command.yawDegrees < minimum || command.yawDegrees > maximum ||
        command.pitchDegrees < minimum || command.pitchDegrees > maximum) {
        return std::nullopt;
    }

    const auto yaw = static_cast<std::int16_t>(
        std::lround(command.yawDegrees * scale));
    const auto pitch = static_cast<std::int16_t>(
        std::lround(command.pitchDegrees * scale));

    std::array<std::uint8_t, commandFrameSize> frame{};
    frame[0] = 0xA5u;
    frame[1] = 1u;
    frame[2] = 1u;
    frame[3] = 7u;
    putU16LE(frame, 4, command.sequence);
    putU16LE(frame, 6, static_cast<std::uint16_t>(yaw));
    putU16LE(frame, 8, static_cast<std::uint16_t>(pitch));
    frame[10] = command.fire ? 0x01u : 0x00u;

    const std::uint16_t crc = crc16CcittFalse(frame.data(), 11);
    putU16LE(frame, 11, crc);
    return frame;
}
```

字段单位、坐标正方向、序号回绕和未知 flag 位的处理也属于协议。版本字节只有在两端定义“不支持时怎样拒绝或降级”以后才真正有用。

==== 接收状态机：从任意切口重新同步

串口是字节流：一次 `read` 可能得到半帧、多帧或夹着噪声的一段。解析器应接受任意大小分块，并且 CRC 失败后从候选帧内部继续寻找下一个帧头，而不是整块清空后反复锁到同一个假头。

下面为了教学仍逐字节 `feed`。缓冲区最多只需保留一个固定帧的候选，因此在开头删除一个字节的线性成本有明确上限：

```cpp
#include <algorithm>
#include <cstdint>
#include <optional>
#include <vector>

std::uint16_t getU16LE(const std::uint8_t* data) {
    return static_cast<std::uint16_t>(data[0]) |
           static_cast<std::uint16_t>(
               static_cast<std::uint16_t>(data[1]) << 8);
}

std::int16_t decodeI16LE(const std::uint8_t* data) {
    const std::uint16_t raw = getU16LE(data);
    const int value = raw <= 0x7fffu
        ? static_cast<int>(raw)
        : static_cast<int>(raw) - 65536;
    return static_cast<std::int16_t>(value);
}

class CommandParser {
public:
    std::optional<GimbalCommand> feed(std::uint8_t byte) {
        buffer_.push_back(byte);

        for (;;) {
            const auto start =
                std::find(buffer_.begin(), buffer_.end(), 0xA5u);
            buffer_.erase(buffer_.begin(), start);
            if (buffer_.empty()) {
                return std::nullopt;
            }
            if (buffer_.size() < commandFrameSize) {
                return std::nullopt;
            }

            if (buffer_[1] != 1u || buffer_[2] != 1u ||
                buffer_[3] != 7u) {
                buffer_.erase(buffer_.begin());
                continue;
            }

            const std::uint16_t expected = getU16LE(buffer_.data() + 11);
            const std::uint16_t actual =
                crc16CcittFalse(buffer_.data(), 11);
            if (actual != expected) {
                buffer_.erase(buffer_.begin());
                continue;
            }
            if ((buffer_[10] & 0xfeu) != 0u) {
                buffer_.erase(buffer_.begin());
                continue; // 当前版本不接受未知标志位
            }

            constexpr double commandScale = 100.0;
            GimbalCommand command{
                getU16LE(buffer_.data() + 4),
                static_cast<double>(
                    decodeI16LE(buffer_.data() + 6)) / commandScale,
                static_cast<double>(
                    decodeI16LE(buffer_.data() + 8)) / commandScale,
                (buffer_[10] & 0x01u) != 0
            };
            buffer_.erase(buffer_.begin(),
                          buffer_.begin() + commandFrameSize);
            return command;
        }
    }

private:
    std::vector<std::uint8_t> buffer_;
};
```

固定长度让上面的上限容易推理。若协议允许可变负载，解析器要先限制长度字段，再等待 `header + payload + crc`；不能相信线上长度后直接分配。高吞吐场景可改用环形缓冲区，语义保持不变。

解析出 CRC 正确的帧仍只是第一关。接收方还要检查角度范围、flag 保留位和序号。序号可帮助发现重复或丢帧，但 `uint16` 会回绕，比较要用协议规定的模运算。对于云台/开火类命令，还应按本地单调时钟设置看门狗：超过新鲜度阈值就进入安全状态，不能因最后一帧 CRC 正确而无限沿用 `fire=true`。

“坏帧等下一帧”只适合高频、可覆盖且允许丢失的状态。参数写入、固件升级和一次性动作需要确认、幂等标识、重试上限或更完整的可靠传输。消息类型应明确选择语义。

==== 没有硬件也能测：pty 回环

Linux 的 `openpty` 可以创建一对互连伪终端。把 slave 配成 raw 后，从 master 写入的字节可以在 slave 读取，很适合测试 termios 与解析循环：

```cpp
#include <pty.h> // 链接时通常需要 -lutil

int master = -1;
int slave = -1;
if (openpty(&master, &slave, nullptr, nullptr, nullptr) != 0) {
    throw std::runtime_error("openpty failed");
}

if (!configureSerial(slave)) {
    close(master);
    close(slave);
    throw std::runtime_error("pty configuration failed");
}

// 测试结束时关闭 master 与 slave；生产代码用 RAII 封装描述符。
```

pty 不模拟波特率、USB 缓冲、电压、接地、线噪声或设备拔插。它验证的是本机字节路径，不能替代真实适配器与单片机的联调。

仓库随附的 `serial_loopback.cpp` 使用一份更小的 packed-float 演示帧，在同一主机 ABI 上发送一帧、两个垃圾字节和一帧 CRC 损坏数据。它的直接输出是：

```text
[recv] yaw=-12.50 pitch=3.75 fire=1 (crc ok)
[parser] CRC mismatch, frame dropped
bytes=24, valid frames=1
```

这验证了该程序在同机 pty 上的正常帧、前导垃圾和一种 CRC 错误路径。它没有验证跨编译器 packed 布局，也没有覆盖部分写、假帧头永久重同步、断线或物理时序；因此 packed 结构体适合看懂原理，不应被这次回环提升成推荐的长期 wire format。

针对本节显式编码的协议，至少应自动测试：每个可能切分位置、两帧粘连、帧前垃圾、CRC 字节和每个字段的单比特损坏、载荷内出现 `0xA5`、不支持版本、长度越界、序号回绕、超时安全状态以及重连。随机分块和模糊测试还能寻找没有手写到的组合；测试通过只覆盖运行到的情况，真实硬件仍要做拔插、干扰与负载测试。

现成的 Boost.Asio、ROS 串口封装可以减少系统调用样板，但不会替项目定义协议单位、生命期和失效策略。遇到问题时仍沿三层排查：设备和权限是否稳定，termios 是否真按预期生效，线上字节是否满足帧格式与时序。

这一章到这里收束。前半段从值、函数和类走到模板、所有权、移动与线程，后半段把语言工具接到 Eigen、Ceres、OpenCV 和串口。现在你已经能读懂一条从图像到指令的 C++ 链路，也知道编译通过只跨过了第一道门：坐标、模型、并发、协议与部署环境仍要逐层验证。后面的章节会把这些环节分别做深；带着本章建立的边界感，复杂代码就不再只是一团 API，而是一组可以逐项检查的契约。
