
=== Git 基本概念
// 从“复制文件备份”到“可追溯协作”
// - 什么是版本控制
// - Git 与 SVN 的核心差异
// - Git 的对象模型（commit/tree/blob）
// - 工作区、暂存区、版本库
// - HEAD、分支与标签
// - 为什么 RoboMaster 团队需要版本控制
// === Git 基本概念

很多新手最初对版本控制的理解是“备份”：改代码前先复制一个 `xxx_final.cpp`，改坏了再回到 `xxx_final_final.cpp`。这种方式在单人小脚本里还能使用，但在团队项目里很快就难以管理。你不知道哪个副本是最新的，不知道谁改了什么，也缺少比较和整合两人修改的可靠依据。版本控制系统的价值不只是保存历史，还在于提供可追溯的变更记录、协作机制和版本恢复入口。

Git 是目前广泛使用的分布式版本控制工具。从用户模型看，每次提交（commit）都指向项目的一份完整目录快照，而不只是按文件保存一串修改指令；底层仍会通过对象复用和压缩等方式节省空间。这套模型使分支、合并和版本恢复更容易管理。对于多人并行开发、赛季迭代频繁且需要长期交接的 RoboMaster 项目，版本控制应作为基础工程设施。

==== 版本控制到底解决什么问题

版本控制主要解决四类问题。

第一类是可追溯性。提交历史可以显示某项改动由谁在何时提交；配合可重复的测试或二分定位，还能查找某个可观察行为从哪个提交开始变化。参数为何改成当前数值，则取决于提交说明、评审或关联议题是否记录了理由。比赛当天出现异常时，这些记录可以缩小排查范围，但提交时间本身不能确认故障原因。

第二类是并行开发。视觉组、决策组、导航组可以在各自分支上推进不同改动，再按约定合并到主线。分支减少了直接覆盖彼此工作的机会，但共享接口和重叠修改仍需提前协调。

第三类是版本恢复。已经提交且仍可访问的版本可以作为回退候选；若同时保存了对应依赖、配置和制品，临场修复失败时就更容易恢复。Git 不会保存未提交修改，也不能单独恢复仓库外的模型、固件和设备状态。

第四类是知识传承。清晰的提交信息与改动记录可以补充设计文档，让后续成员了解系统如何演进，而不只看到当前版本的代码。

==== Git 的对象模型

理解 Git 不需要先背几十条命令，先理解它保存了什么。

Git 底层主要有三类对象：

- `blob`：文件内容。
- `tree`：目录结构，指向若干 `blob` 或子 `tree`。
- `commit`：一次快照，记录一个 `tree`、父提交、作者和提交信息。

分支本质上只是一个可移动的引用，指向某个提交。`HEAD` 是当前检出的引用。你执行一次 `git commit`，实际上是生成新提交并让当前分支指向它。

上面这套结构（`blob/tree/commit`、分支引用和 `HEAD`）可以解释很多常见现象：切换分支主要是在切换引用和工作区内容；分支关系可以通过提交图追踪；提交信息则说明一次变更的目的，帮助读者理解图中每个节点的含义。


==== 三个工作区：工作区、暂存区、版本库

Git 的日常操作围绕三个区域展开：

- 工作区（Working Tree）：你正在编辑的文件。
- 暂存区（Index / Staging Area）：本次准备提交的内容清单。
- 版本库（Repository）：Git 当前能够访问的已提交对象与引用。

这也是新手最容易混淆的地方。典型流程是：先在工作区改代码，用 `git add` 把“本次想提交”的改动放进暂存区，再用 `git commit` 把暂存区快照写入版本库。

```bash
# 1) 看当前改动
git status
# 2) 只暂存本次要提交的文件
git add src/detector.cpp
# 3) 生成提交
git commit -m "feat(detector): add contour pre-filter"
```

暂存区让你可以把工作区中的多项修改拆成语义清晰的小提交。例如，修复 bug 时又格式化了同一文件，可以只暂存与修复有关的部分，避免把无关改动放进同一个提交。

==== 为什么 RoboMaster 团队需要系统化使用 Git

RoboMaster 项目有三个典型特征：

- 赛季内需求变化快，试错密度高。
- 多模块并行（视觉、决策、通信、嵌入式）。
- 人员代际交接明显。

这些特点要求团队不只会运行 `git add` 和 `git commit`，还要约定分支策略、提交规范、合并流程和发布标签。缺少这些约定时，主分支可能长期不稳定，版本恢复、冲突处理和赛季交接都会变得困难。


=== 本地仓库操作
// 把单机开发流程跑通
// - 初始化与克隆
// - 状态检查：status/log/diff
// - add/commit 的正确用法
// - 撤销改动：restore/reset/revert
// - 标签与里程碑
// === 本地仓库操作

远程协作建立在本地仓库操作之上。先能准确区分工作区、暂存区和提交历史，才能避免在推送与合并时扩大本地的误操作。

==== 创建仓库：`init` 与 `clone`

新项目从零开始时用 `git init`：

```bash
mkdir rm_vision
cd rm_vision

git init
# 创建 README、构建文件和源码后，先检查待加入的路径
git status --short
git add README.md CMakeLists.txt src/
git diff --staged
git commit -m "chore: initialize repository"
```

已有远程项目时用 `git clone`：

```bash
git clone git@github.com:team/rm_vision.git
cd rm_vision
```

如果仓库含子模块，建议直接递归克隆：

```bash
git clone --recursive git@github.com:team/rm_vision.git
```

==== 每天都要看的三个命令

`git status`、`git log`、`git diff` 是日常检查仓库状态最常用的三个命令。

```bash
# 工作区/暂存区状态
git status
# 最近提交图
git log --oneline --graph --decorate -20
# 未暂存改动
git diff
# 已暂存改动
git diff --staged
```

- `status` 看当前工作区和暂存区状态。
- `log` 看历史结构，`--graph` 可以看到分支合并关系。
- `diff` 看改动内容，`--staged` 看已暂存内容。

提交前先看 `status` 和 `diff --staged`，有助于发现误暂存的文件或遗漏的改动。

==== `add` 与 `commit`：提交的是“意图”而不是“时间点”

初学者常见的问题是，代码刚能运行就直接执行：

```bash
git add . && git commit -m "update"
```

这样容易把不相关改动放进同一个提交，也无法从提交信息判断修改目的。

更好的流程是：

1. 先把一个最小功能改完整。
2. 用 `git add <file>` 或交互式 `git add -p` 精确暂存。
3. 写有语义的提交信息。

```bash
git add -p src/tracker.cpp
git commit -m "fix(tracker): guard against empty candidate set"
```

推荐提交信息结构：

- `feat`: 新功能
- `fix`: 缺陷修复
- `refactor`: 以保持外部行为为目标的结构调整
- `docs`: 文档
- `test`: 测试
- `chore`: 杂项维护

例如，一次为串口帧增加 CRC16 校验的提交可以写成：

```text
feat(protocol): add crc16 verification for serial frames
```

==== 撤销改动：先搞清你要撤销哪一层

Git 的“撤销”命令多，是因为它们作用层不同。

只撤销工作区改动（未暂存）：

```bash
git restore src/detector.cpp
```

这条命令会丢弃该文件尚未提交的工作区修改。执行前先查看差异：

```bash
git diff -- src/detector.cpp
```

确认内容仍有保留价值时，应先提交到临时分支或另存补丁。

撤销暂存（保留工作区修改）：

```bash
git restore --staged src/detector.cpp
```

回退分支指针（谨慎）：

```bash
git reset --soft HEAD~1   # 回退一个提交，改动留在暂存区
git reset --mixed HEAD~1  # 回退一个提交，改动留在工作区
```

对外已发布历史不要用 `reset` 改写，应该用 `revert` 生成反向提交：

```bash
git revert 4f3a2c1  # 替换为需要撤销的提交 ID
```

一个常用的判断起点是：

- 仅本地私有分支可改写历史（`reset/rebase`）。
- 已推送且他人可能基于其开发的历史，用 `revert`。

如果误用了 `reset` 或 `rebase`，先停止继续改写历史，再查看当前克隆的引用日志：

```bash
git reflog --date=local
git branch rescue/before-reset 4f3a2c1  # 替换为 reflog 中确认的提交 ID
```

`reflog` 记录的是这个本地仓库中 `HEAD` 和分支引用曾经指向的位置，可以帮助找回仍未被清理的提交；它不是远程审计日志，也不会保存被 `restore` 覆盖的未提交内容。确认目标提交后先创建救援分支，比立即再次执行 `reset` 更便于核对。

==== 用标签（Tag）标记发布里程碑

比赛前后可以用标签标记发布候选。下面的 `git tag` 默认指向当前 `HEAD`，不会包含尚未提交的配置或源码；创建前先确认工作树和目标提交：

```bash
git status --short
git show --stat --oneline HEAD
git tag -a v2026-pre-match -m "Pre-match stable version"
git push origin v2026-pre-match
```

当现场需要恢复到已验证版本时，标签可以明确指出候选提交，省去临时翻查提交历史的时间。标签本身不证明版本稳定，仍应记录它通过了哪些设备与场景的验证。


=== GitHub/GitLab 远程协作
// 本地历史如何进入团队主线
// - remote/fetch/pull/push
// - SSH 认证
// - 上游同步
// - 常见协作冲突场景
// === GitHub/GitLab 远程协作

远程协作不只是“把代码传上去”，还包括取得远程引用、判断本地与远程的先后或分叉关系，再选择合适的整合方式。

==== 远程仓库基础：`remote` / `fetch` / `pull` / `push`

查看远程：

```bash
git remote -v
```

同步远程引用（不自动合并）：

```bash
git fetch origin
```

按当前 `pull` 配置取得远程提交并整合到当前分支：

```bash
git pull origin main
```

这条命令把 `origin/main` 整合到当前检出的分支；它不会因为参数写了 `main` 就自动切换到本地 `main`。执行前应先用 `git status` 和 `git branch --show-current` 确认当前位置。

推送当前分支：

```bash
git push -u origin feature/armor-detector
```

如果团队约定用 rebase 整理尚未共享的本地提交，可以在当前仓库中把 `pull` 的默认行为设为 rebase，减少仅由同步操作产生的 merge commit：

```bash
git config pull.rebase true
```

这不是所有团队都必须采用的设置。rebase 会改写本地提交的父节点；已经共享、需要保留合并拓扑的分支应遵循团队约定，也可以显式选择 `git pull --no-rebase` 或先 `fetch` 再决定如何整合。只有希望所有本地仓库都采用同一默认值时，才应额外使用 `--global`。

==== SSH 认证建议

SSH 是访问远程仓库的一种常见认证方式。配置密钥和 `ssh-agent` 后，可以避免每次操作都输入凭据；使用 HTTPS 配合凭据管理器同样可行，团队可按平台与设备管理要求选择。生成密钥前先检查 `~/.ssh/`：如果默认文件名已经用于其他系统，不要覆盖，应选择新的文件名并在 `~/.ssh/config` 中指定。下面只读取公钥文件，私钥 `~/.ssh/id_ed25519` 不应发送给他人：

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
cat ~/.ssh/id_ed25519.pub
```

把公钥添加到 GitHub/GitLab 后，用以下命令验证：

```bash
ssh -T git@github.com
```

首次连接前，应按平台官方文档核对服务器主机密钥指纹。GitHub 认证成功时会返回包含用户名并说明不提供 shell access 的消息；该测试不是打开远程终端，判断时应同时查看消息，而不能只凭是否得到 shell。使用 GitLab 或自建平台时，应把主机名改为对应服务器并参考平台说明。

==== Fork 模式与 Upstream 同步

如果你们采用 Fork 工作流，通常会有两个远程：

- `origin`：你自己的 fork。
- `upstream`：团队主仓库。

```bash
git remote add upstream git@github.com:team/rm_vision.git
git fetch upstream
git checkout main
git merge --ff-only upstream/main
git push origin main
```

这组命令有一个重要前提：个人 fork 的 `main` 没有独有提交。命令中的 `--ff-only` 只允许把本地主线快进到 `upstream/main`；一旦历史已经分叉，Git 就会停止并要求人工判断。

同步完成后，再从更新后的 `main` 创建功能分支，或按团队约定把已有功能分支 rebase/merge 到新基线。上面的命令本身并没有更新其他功能分支。

==== 协作中三个常见问题

第一个问题是直接在 `main` 上开发。未经审查和验证的修改会立刻进入主分支，使其他成员拉取后也受到影响。

第二个问题是长时间不同步主线。功能分支持续时间越长，与主线发生大量重叠修改的可能性越高，合并时就要一次处理更多冲突。

第三个问题是提交 `build/`、`install/`、`log/` 等编译或运行产物。这些文件通常能重新生成，却会增加仓库体积，并造成没有协作价值的冲突。


=== 分支管理
// 让多人并行开发可控
// - 分支命名规范
// - feature/hotfix/release 分支
// - merge 与 rebase 的取舍
// - 冲突处理流程
// === 分支管理

分支用于隔离尚未准备进入共享主线的改动。团队仓库通常让一项功能或缺陷修复在短期分支中完成，再按约定审查和合并；极小团队、练习仓库或紧急现场流程可以采用不同规则，但要明确谁能修改主线以及如何恢复。

==== 推荐分支模型（适配学生团队）

对 RoboMaster 团队来说，简单模型通常比复杂 Git Flow 更实用：

- `main`：团队的主要集成线；是否可发布取决于约定的检查与验证。
- `dev`（可选）：阶段性集成分支。
- `feature/*`：功能分支。
- `fix/*`：缺陷修复分支。
- `hotfix/*`：比赛期紧急修复分支。

分支命名建议包含模块和目标：

- `feature/vision-armor-classifier`
- `fix/tracker-timeout`
- `hotfix/serial-crc`

==== merge 和 rebase 怎么选

`merge` 把两段历史汇合；非快进合并可以保留分支的汇合点。`rebase` 则把一组提交复制到新的基线上，生成新的提交 ID，使这段历史更线性。两者都不会自动判断合并后的业务行为是否正确。

常见实践：

- 整理尚未共享的个人提交时，可以使用 `rebase`。
- 合并到主线时，使用 PR 平台的 `Squash merge` 或普通 `merge`，保持审查记录。

把 `rebase` 理解为“在新基线上重放并生成提交”，把非快进 `merge` 理解为“创建汇合点”，有助于区分两者对历史的影响。

==== 冲突处理流程

若团队选择在功能分支上 rebase 到最新主线，可以按下面的流程处理冲突：

```bash
git fetch origin
git rebase origin/main
# 编辑冲突文件，手动选择内容
git add path/to/resolved_file
git rebase --continue
```

冲突文件会出现标记：

#raw("<<<<<<< HEAD\n当前基线中的内容\n=======\n正在合入或重放的提交内容\n>>>>>>> <commit-or-branch>", block: true, lang: "text")

标记两侧的含义取决于正在执行 merge 还是 rebase：在上面的 `rebase origin/main` 中，`HEAD` 一侧通常是已经检出的新基线，另一侧是当前正在重放的提交，不能机械地把 `HEAD` 当成“我的修改”。先结合 `git status`、相关提交和共同基线确认来源。

处理原则：

- 先理解两边修改各自的意图，再决定最终行为；不能只以“能编译”为标准选择内容。
- 冲突解决后必须运行相关测试或最小回归验证。
- 涉及不熟悉的业务逻辑时，应请相关作者共同确认。


=== 团队工作流（PR、Code Review）
// 从“我写完了”到“团队可接收”
// - PR 生命周期
// - 审查清单
// - 提交粒度与可读性
// - CI 与门禁
// === 团队工作流（PR、Code Review）

PR（Pull Request；GitLab 中常称 Merge Request）把待合并的改动、讨论和自动检查集中在一个页面中。它既用于发起合并，也让其他成员了解修改背景、验证方法和风险。

==== 推荐 PR 流程

1. 从最新主线切功能分支。
2. 小步提交，保持每个提交可解释。
3. 推送远程后创建 PR。
4. 填写清晰描述：背景、改动、验证方式、风险点。
5. 至少一名同伴审查通过后合并。

PR 描述建议模板：

```markdown
## 背景
修复高速旋转目标下 tracker 丢失问题。

## 改动
- 调整候选目标门控条件
- 增加时间戳异常保护
- 新增 2 个单元测试

## 验证
- 本地回放数据集 `data/2026-01-armor.bag`
- 提交 `4f3a2c1` 在目标板 A、配置 B 下运行 30 分钟，未观察到崩溃

## 风险
参数阈值更严格，可能降低远距离召回率
```

==== Code Review 的关注重点

审查者应优先看四件事：

- 行为正确性：逻辑是否符合需求。
- 边界条件：空数据、超时、异常输入是否处理。
- 可维护性：命名、模块边界、耦合度。
- 回归风险：是否影响实时性、通信协议、关键路径。

不要把审查焦点浪费在格式争论上，格式交给 `clang-format`，审查聚焦语义和风险。

==== CI 与合并条件

可以把以下检查设为 PR 合并前必须满足的条件：

- 至少一套明确的构建配置编译通过（如 Debug 或 Release）。
- 单元测试通过。
- 基础静态检查通过（如 `clang-tidy` 的关键规则）。

这些自动检查能阻止已知的编译、测试和静态检查失败进入主分支，但不能覆盖实车时序、硬件兼容性等未被测试的路径。团队仍需要根据改动范围安排相应验证。

==== 团队执行清单（可放入 README）

如果你希望这章内容真正执行起来，可以先把下面 5 条写进团队规约：

1. 为 `main` 设置与平台能力相符的保护规则，并约定直接推送权限。
2. 共享主线的改动原则上通过 PR 合并，至少由 1 名其他成员审查。
3. 规定的 CI 检查失败时不合并；硬件路径另列验证要求。
4. 提交信息遵循 `type(scope): message`。
5. 能分阶段合并的功能尽早发起 PR；长分支要约定主线同步方式。

规则不必一开始就很复杂。先持续执行这五条，再根据实际冲突、发布和审查成本调整流程。


=== .gitignore 与 submodule
// 管理仓库边界
// - 哪些文件不该入库
// - .gitignore 规则写法
// - 子模块的使用场景
// - submodule 的常见误区
// === .gitignore 与 submodule

==== `.gitignore`：明确不纳入版本控制的文件

可重新生成的编译产物、临时文件和只属于本机的运行状态通常不应纳入版本控制。基础篇前面多次出现的 `build/`、`install/`、`log/` 一般都应忽略；依赖锁文件、团队共享的编辑器任务或可复现环境配置则可能需要提交，应按项目用途逐项判断。

RoboMaster C++/ROS 2 项目常用的 `.gitignore` 示例：

```gitignore
# Build outputs
build/
install/
log/

# CMake
CMakeCache.txt
CMakeFiles/
cmake_install.cmake
compile_commands.json

# IDE（若团队要共享 tasks.json 等配置，请按文件细分规则）
.vscode/
.idea/

# Python
__pycache__/
*.pyc

# Logs & runtime
*.log
core
core.*

# OS junk
.DS_Store
Thumbs.db
```

如果某文件已经被跟踪，再写到 `.gitignore` 不会自动生效，需要先取消跟踪：

```bash
git rm -r --cached -- build/
git commit -m "chore(git): stop tracking build artifacts"
```

这里的 `--cached` 只从暂存索引移除路径，保留当前工作区文件；提交后，其他成员更新到该版本时仍会看到仓库中的 `build/` 被删除。执行前应先确认目录确实是可再生成的产物，并把 `build/` 写入 `.gitignore`，避免随后再次加入。

==== 什么时候该用 submodule

`submodule` 用于把另一个仓库作为“固定版本依赖”嵌入当前仓库，典型场景：

- 你们维护了一套通用算法库，多个项目共享。
- 需要锁定第三方仓库的特定提交，避免上游变动破坏稳定性。

添加子模块：

```bash
git submodule add git@github.com:team/rm_common.git third_party/rm_common
git commit -m "chore: add rm_common submodule"
```

更新子模块到经过确认的新提交：

```bash
git -C third_party/rm_common fetch origin
git -C third_party/rm_common switch --detach a1b2c3d  # 替换为已审查的提交 ID
git add third_party/rm_common
git commit -m "chore(submodule): bump rm_common"
```

主仓库记录的是子模块提交 ID，而不是“跟随 `main`”这一意图。更新前应查看目标提交，更新后还要运行主项目所需的构建与测试；若团队需要自动跟随某个版本范围，包管理器或发布制品通常更合适。

克隆含子模块仓库后初始化：

```bash
git submodule update --init --recursive
```

==== submodule 常见误区

第一个误区是忘记更新子模块指针。你在子模块仓库提交了代码，但主仓库没有 `git add` 子模块路径并提交新的指针，其他人更新主仓库后仍会检出旧版本。

第二个误区是把 submodule 当作通用包管理器。若依赖与主项目频繁联动，放在同一仓库或使用能声明版本与依赖关系的包管理方案，维护成本可能更低。

第三个误区是没有记录初始化步骤。未拉取子模块时，目录可能存在但内容为空，构建随之失败；应在 README 中写明初始化和更新命令，并尽量让构建脚本给出明确提示。


=== 小结：把 Git 当作工程系统而不是命令集合

学 Git 的终点不是记住更多命令，而是建立稳定的工程流程：

- 本地改动可控（小步提交、语义清晰）。
- 分支协作可控（隔离风险、及时同步）。
- 合并质量可控（PR + Review + CI）。
- 发布版本可定位（标签、配置与发布记录）。

持续执行这些流程，可以减少误提交和无说明的历史分叉；新成员也更容易找到当前协作方式与已验证的发布版本。

下一章进入 ROS 2。届时，节点源码、参数文件、launch 配置和自定义消息都会成为需要共同版本化的工程内容，本章的检查差异、拆分提交和发布标签会直接用于这些文件。
