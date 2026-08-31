#import "/template/template.typ": *

=== 为什么是 VSCode

编辑器是个人选择，但战队里存在一个协作约束：当新队员喊「这里编译不过」时，能不能在他的屏幕上快速定位问题。如果大家用同一个编辑器，老队员可以直接接手操作；如果每个人的编辑器都不同，帮忙调试的成本会明显上升。

VSCode 成为默认推荐的原因，是它在几个 RoboMaster 会用到的场景里同时够用：C++ 与 Python 的补全和调试、CMake 集成、SSH 远程开发、以及 AI 代理的官方插件。它不是任何单项里最强的，但避免了「写 C++ 用一个、跑 Python 用另一个、连车再换一个」。

熟悉 Vim 或 CLion 的队员不必迁移。本节的配置思路（`compile_commands.json` 驱动补全、远程开发的工作模式）在其他编辑器上同样适用，只是配置位置不同。

=== 扩展清单

下面是一台开发机上实际安装的扩展，按用途分组。安装可以直接用命令行：

```bash
code --install-extension ms-vscode.cpptools-extension-pack
```

#figure(
  table(
    columns: (auto, auto),
    align: (left, left),
    stroke: (x, y) => (
      top: if y == 0 or y == 1 { 1pt } else { 0pt },
      bottom: if y == 12 { 1pt } else { 0pt },
    ),
    inset: 5pt,
    table.header([*扩展 ID*], [*用途*]),
    [`ms-vscode.cpptools-extension-pack`], [C/C++ 语言支持、调试、CMake 集成（含 cpptools 与 cmake-tools）],
    [`ms-vscode.cmake-tools`], [CMake 配置与构建（非 ROS 项目用）],
    [`ms-python.python`], [Python 语言支持],
    [`ms-python.vscode-pylance`], [Python 类型检查与补全],
    [`ms-python.debugpy`], [Python 调试器],
    [`rust-lang.rust-analyzer`], [Rust 语言服务（部分模块用 Rust 重写时需要）],
    [`eamodio.gitlens`], [行级 blame、提交历史、分支比较],
    [`myriad-dreamin.tinymist`], [Typst 语言服务，写本书这类文档用],
    [`anthropic.claude-code`], [Claude Code 编辑器集成],
    [`openai.chatgpt`], [Codex 编辑器集成],
    [`ms-ceintl.vscode-language-pack-zh-hans`], [中文界面],
    [`tomoki1207.pdf`], [编辑器内直接预览 PDF，看编译出的文档不用切窗口],
  ),
  caption: [实际在用的 VSCode 扩展],
)

用户设置保持在最小规模。`~/.config/Code/User/settings.json` 只有三项：

```json
{
    "claudeCode.preferredLocation": "panel",
    "workbench.colorTheme": "Dark Modern",
    "rust-analyzer.checkOnSave": false
}
```

保持用户级设置精简是有意的：项目相关的配置应该放进项目自己的 `.vscode/settings.json` 并提交到仓库，这样每个克隆仓库的人都得到相同的配置。写进用户设置的项目配置只对自己生效，别人克隆下来仍然报错。

`rust-analyzer.checkOnSave` 关闭是因为它默认每次保存都跑 `cargo check`，在大型项目上会持续占用 CPU。需要检查时手动跑即可。

=== 让 C++ 补全真正工作：compile_commands.json

新队员在 ROS 工作空间里最常遇到的挫折是：代码能编译通过，但编辑器里满屏红波浪线，`#include <rclcpp/rclcpp.hpp>` 报找不到，跳转定义也不工作。

原因是编辑器不知道编译这个文件时用了哪些 `-I` 头文件路径和 `-D` 宏定义。这些信息在 CMake 里，编辑器读不到。解决办法是让 CMake 导出一份编译数据库 `compile_commands.json`，编辑器读它。

对 colcon 工作空间：

```bash
colcon build --cmake-args -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
```

或者写进 colcon 的默认配置，避免每次都要记住这个参数：

```yaml
# <工作空间>/colcon_defaults.yaml
build:
  cmake-args: ["-DCMAKE_EXPORT_COMPILE_COMMANDS=ON"]
  symlink-install: true
```

编译后每个包的 `build/<包名>/compile_commands.json` 会生成。colcon 不会自动合并成一份，需要在工作空间根目录合并：

```bash
# 装 jq 后合并所有包的编译数据库
jq -s 'add' build/*/compile_commands.json > compile_commands.json
```

然后在项目的 `.vscode/settings.json` 里指向它：

```json
{
    "C_Cpp.default.compileCommands": "${workspaceFolder}/compile_commands.json",
    "C_Cpp.default.cppStandard": "c++17",
    "files.associations": {
        "*.launch.py": "python"
    }
}
```

#note[
`symlink-install: true` 值得单独说。加上这个选项后，colcon 在 `install/` 里创建的是指向源码的符号链接而不是拷贝。改 Python 节点、launch 文件或配置 YAML 之后不需要重新 `colcon build`，直接重启节点即可生效。调参阶段这能省下大量等待时间。C++ 源码修改仍然需要重新编译。
]

#attention[
不要用 CMake Tools 扩展去「配置」ROS 工作空间。CMake Tools 会试图自己调用 `cmake` 配置整个目录，而 colcon 有自己的多包构建逻辑，两者会互相覆盖 `build/` 目录，产生难以理解的编译错误。ROS 工作空间统一用终端里的 `colcon build`，CMake Tools 留给不用 ROS 的独立项目。
]

=== 远程开发：代码在笔记本，程序跑在车上

这是战队场景与普通软件开发差异最大的地方。视觉程序最终运行在车载计算单元（NUC、Jetson Orin 或类似设备）上，那台机器通常没有显示器和键盘，固定在车上，通过网线或 Wi-Fi 连接。

有三种工作方式，各有适用场合。

第一种，SSH 直连改代码。适合改一行参数、看日志这类小动作：

```bash
ssh nuc@192.168.1.100
```

优点是没有任何同步问题，缺点是在终端里编辑大段代码效率低。

第二种，VSCode Remote-SSH。装 `ms-vscode-remote.remote-ssh` 扩展后，VSCode 窗口连到车载机，编辑器界面在笔记本上，而文件、终端、编译、调试全部发生在车载机。这是调车时最常用的方式，因为它消除了「本地改完忘记同步上去」的整类错误。

配置写在 `~/.ssh/config`：

```
Host car
    HostName 192.168.1.100
    User nuc
    # 保持连接，避免调试时断开
    ServerAliveInterval 30
    ServerAliveCountMax 6
```

配好之后在 VSCode 里按 `Ctrl+Shift+P`，执行 `Remote-SSH: Connect to Host`，选 `car`。

第三种，本地开发加部署脚本。在笔记本上写和编译，用 `rsync` 同步到车上再运行。适合车载机性能弱、编译慢的情况：

```bash
rsync -avz --delete \
    --exclude 'build/' --exclude 'install/' --exclude 'log/' \
    ~/sentry_nav_26/src/ nuc@192.168.1.100:~/ws/src/
```

三种方式里，Remote-SSH 应该是默认选择，另外两种在它不可用时补位。

#attention[
Remote-SSH 首次连接会在车载机上下载并安装 VSCode Server（约 100 MB）。比赛现场网络通常不可用，务必在赛前有网络时先连一次，让 Server 装好。这是一个真实会在赛场上卡住整个队伍的问题。
]

先配好免密登录，避免每次输密码：

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"    # 已有可跳过
ssh-copy-id nuc@192.168.1.100
```

=== 调试配置

`launch.json` 提交到仓库，让每个人都能直接按 F5 调试。ROS 2 节点的 C++ 调试配置：

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "调试 armor_detector 节点",
            "type": "cppdbg",
            "request": "launch",
            "program": "${workspaceFolder}/install/armor_detector/lib/armor_detector/armor_detector_node",
            "args": ["--ros-args", "--params-file",
                     "${workspaceFolder}/src/armor_detector/config/detector.yaml"],
            "cwd": "${workspaceFolder}",
            "environment": [],
            "externalConsole": false,
            "MIMode": "gdb",
            "setupCommands": [
                {
                    "description": "为 gdb 启用整齐打印",
                    "text": "-enable-pretty-printing",
                    "ignoreFailures": true
                }
            ]
        }
    ]
}
```

要让断点真正命中，编译时必须带调试信息：

```bash
colcon build --cmake-args -DCMAKE_BUILD_TYPE=RelWithDebInfo
```

不要用 `Debug`：它会关闭优化，视觉节点的帧率会低到无法反映真实行为，一些只在正常帧率下出现的时序问题反而复现不了。`RelWithDebInfo` 保留优化同时带符号表，是调试视觉程序的合适档位。代价是部分变量会因为优化被显示为 `<optimized out>`。

#note[
调试视觉节点还有一条更实用的路径：录制一段 rosbag，然后离线回放调试。现场调车时间宝贵，而绝大多数算法问题可以在宿舍用回放数据复现。第三篇讨论的时间戳同步，正是让离线回放能忠实还原线上行为的前提。
]

=== Typst 文档写作

本书用 Typst 编写。写文档的环境配置只有两步：

```bash
# 装 typst（任选其一）
cargo install --locked typst-cli
# 或从 GitHub Releases 下载二进制放进 ~/.local/bin

# VSCode 扩展
code --install-extension myriad-dreamin.tinymist
```

`tinymist` 提供实时预览、语法检查、跳转和格式化。写作时按 `Ctrl+Shift+P` 执行 `Typst Preview` 打开侧边预览，保存即刷新。

命令行编译整本书：

```bash
cd RMCV_Tutorial
typst compile --font-path fonts main.typ
typst watch --font-path fonts main.typ    # 监听模式，改完自动重编
```

选 Typst 而不是 LaTeX 的理由，对学生团队特别成立：编译速度是秒级而非分钟级，错误信息指向具体行号而不是宏展开后的位置，安装只有一个二进制文件而不是几 GB 的发行版。代价是生态较新，一些 LaTeX 宏包还没有对应实现。

#note[
本地编译如果出现 `unknown font family` 警告，说明缺中文字体。装齐即可消除：

```bash
sudo apt install fonts-noto-cjk fonts-noto-cjk-extra fonts-lxgw-wenkai
```

正式发布版本以持续集成（CI）编译的产物为准——CI 环境里的字体是固定的，本地字体差异不会影响最终 PDF。
]
