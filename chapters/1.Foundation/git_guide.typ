#show raw.where(block: true): set block(inset: (left: 4em))

=== Git 基本概念
// 从“复制文件备份”到“可追溯协作”
// - 什么是版本控制
// - Git 与 SVN 的核心差异
// - Git 的对象模型（commit/tree/blob）
// - 工作区、暂存区、版本库
// - HEAD、分支与标签
// - 为什么 RoboMaster 团队必须使用 Git
// === Git 基本概念

很多新手最初对版本控制的理解是“备份”：改代码前先复制一个 `xxx_final.cpp`，改坏了再回滚到 `xxx_final_final.cpp`。这种方式在单人小脚本里还能勉强用，但在团队项目里会迅速失效。你不知道哪个副本是最新的，不知道谁改了什么，也无法把两个人的修改安全合并。版本控制系统的价值不只是保存历史，而是给团队提供一套可追溯、可协作、可回滚的工程机制。

Git 是目前事实标准的版本控制工具。它最核心的思想是：每次提交（commit）都是一个完整快照，而不是“增量补丁”。这让分支、合并、回滚都变得高效且可管理。对于 RoboMaster 这种多人并行开发、赛季节奏紧张、代码需要长期传承的项目，Git 不是可选项，而是基础设施。

==== 版本控制到底解决什么问题

版本控制主要解决四类问题。

第一类是可追溯性。你可以明确知道某个功能是谁在什么时间引入的，某个 bug 从哪个提交开始出现，某个参数为什么被改成当前数值。当系统比赛当天突然异常时，这种追溯能力非常关键。

第二类是并行开发。视觉组、决策组、导航组可以同时修改同一个仓库，不需要互相等待。每个人在自己的分支上推进，成熟后再合并到主线。

第三类是可回滚。新功能上线后如果性能下降，可以迅速回退到稳定版本；临场修复失败也能快速恢复。

第四类是知识传承。高质量的提交历史本身就是文档。后辈可以通过提交记录理解系统如何演进，而不是只看到当前这一帧静态代码。

==== Git 的对象模型：不是魔法，是数据结构

理解 Git 不需要先背几十条命令，先理解它保存了什么。

Git 底层主要有三类对象：

- `blob`：文件内容。
- `tree`：目录结构，指向若干 `blob` 或子 `tree`。
- `commit`：一次快照，记录一个 `tree`、父提交、作者和提交信息。

分支本质上只是一个可移动的引用，指向某个提交。`HEAD` 是当前检出的引用。你执行一次 `git commit`，实际上是生成新提交并让当前分支指向它。

上面这套结构（`blob/tree/commit` + 分支引用 + `HEAD`）可以解释很多常见现象：为什么切分支很快（只是移动引用）；为什么 Git 擅长合并（提交图是有向无环图）；为什么 commit message 很重要（它是历史图上的语义锚点）。


==== 三个工作区：工作区、暂存区、版本库

Git 的日常操作围绕三个区域展开：

- 工作区（Working Tree）：你正在编辑的文件。
- 暂存区（Index / Staging Area）：本次准备提交的内容清单。
- 版本库（Repository）：已经提交并永久记录的历史。

这也是新手最容易混淆的地方。典型流程是：先在工作区改代码，用 `git add` 把“本次想提交”的改动放进暂存区，再用 `git commit` 把暂存区快照写入版本库。

```bash
# 1) 看当前改动
git status
# 2) 只暂存本次要提交的文件
git add src/detector.cpp
# 3) 生成提交
git commit -m "feat(detector): add contour pre-filter"
```

暂存区的存在让你可以把一大坨修改拆成多个语义清晰的小提交。比如你一边修 bug 一边顺手格式化文件，可以只暂存 bug 修复部分，避免把不相关改动混进同一个提交。

==== 为什么 RoboMaster 团队必须系统化用 Git

RoboMaster 项目有三个典型特征：

- 赛季内需求变化快，试错密度高。
- 多模块并行（视觉、决策、通信、嵌入式）。
- 人员代际交接明显。

这决定了你们不能只“会用 git add/git commit”，而需要明确分支策略、提交规范、合并流程和发布标签。否则仓库会在赛季中后期迅速失控：主分支不稳定、回滚困难、冲突高发、交接成本爆炸。


=== 本地仓库操作
// 把单机开发流程跑通
// - 初始化与克隆
// - 状态检查：status/log/diff
// - add/commit 的正确用法
// - 撤销改动：restore/reset/revert
// - 标签与里程碑
// === 本地仓库操作

本地操作是所有协作流程的基石。你如果在本地不能稳定管理改动，到了远程协作只会放大问题。

==== 创建仓库：`init` 与 `clone`

新项目从零开始时用 `git init`：

```bash
mkdir rm_vision
cd rm_vision

git init
git add .
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

`git status`、`git log`、`git diff` 是最核心的可视化工具。

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

养成提交前先看 `status + diff --staged` 的习惯，能显著减少误提交。

==== `add` 与 `commit`：提交的是“意图”而不是“时间点”

初学者常见错误是：代码刚能跑就 `git add . && git commit -m "update"`。这会把不相关改动打包成噪声提交。

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
- `refactor`: 重构（不改行为）
- `docs`: 文档
- `test`: 测试
- `chore`: 杂项维护

示例：`feat(protocol): add crc16 verification for serial frames`

==== 撤销改动：先搞清你要撤销哪一层

Git 的“撤销”命令多，是因为它们作用层不同。

只撤工作区改动（未暂存）：

```bash
git restore src/detector.cpp
```

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
git revert <commit_sha>
```

规则很简单：

- 仅本地私有分支可改写历史（`reset/rebase`）。
- 已推送且他人可能基于其开发的历史，用 `revert`。

==== 标签（Tag）是发布里程碑，不是装饰

比赛前后建议打标签管理可复现版本：

```bash
git tag -a v2026-pre-match -m "Pre-match stable version"
git push origin v2026-pre-match
```

当现场需要快速回退到已验证版本时，标签能极大缩短决策时间。


=== GitHub/GitLab 远程协作
// 本地历史如何进入团队主线
// - remote/fetch/pull/push
// - SSH 认证
// - 上游同步
// - 常见协作冲突场景
// === GitHub/GitLab 远程协作

远程协作的核心不是“把代码传上去”，而是保持本地与远程历史的一致、可理解、可合并。

==== 远程仓库基础：`remote` / `fetch` / `pull` / `push`

查看远程：

```bash
git remote -v
```

同步远程引用（不自动合并）：

```bash
git fetch origin
```

拉取并合并：

```bash
git pull origin main
```

推送当前分支：

```bash
git push -u origin feature/armor-detector
```

推荐把 `pull` 设为 rebase，减少无意义 merge commit：

```bash
git config --global pull.rebase true
```

==== SSH 认证建议

团队仓库建议统一 SSH 协议，避免 HTTPS 反复输密码。

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
cat ~/.ssh/id_ed25519.pub
```

把公钥添加到 GitHub/GitLab 后，用以下命令验证：

```bash
ssh -T git@github.com
```

==== Fork 模式与 Upstream 同步

如果你们采用 Fork 工作流，通常会有两个远程：

- `origin`：你自己的 fork。
- `upstream`：团队主仓库。

```bash
git remote add upstream git@github.com:team/rm_vision.git
git fetch upstream
git checkout main
git rebase upstream/main
git push origin main
```

这样可以保证你的功能分支始终基于最新主线。

==== 协作中最常见的三个坑

第一个坑：直接在 `main` 上开发。结果是主分支长期不稳定，任何人 pull 都可能失败。

第二个坑：长时间不同步主线。你写了一周再合并，冲突会集中出现。

第三个坑：把编译产物推上去（如 `build/`、`install/`、`log/`）。仓库体积和冲突风险都会失控。


=== 分支管理
// 让多人并行开发可控
// - 分支命名规范
// - feature/hotfix/release 分支
// - merge 与 rebase 的取舍
// - 冲突处理流程
// === 分支管理

分支不是为了“展示技巧”，而是为了隔离风险。每个功能、缺陷修复都应在独立分支完成，经过评审再合并。

==== 推荐分支模型（适配学生团队）

对 RoboMaster 团队来说，简单模型通常比复杂 Git Flow 更实用：

- `main`：始终可发布、可运行。
- `dev`（可选）：阶段性集成分支。
- `feature/*`：功能分支。
- `fix/*`：缺陷修复分支。
- `hotfix/*`：比赛期紧急修复分支。

分支命名建议包含模块和目标：

- `feature/vision-armor-classifier`
- `fix/tracker-timeout`
- `hotfix/serial-crc`

==== merge 和 rebase 怎么选

`merge` 保留真实分支拓扑，历史更完整；`rebase` 让历史更线性、阅读更干净。

常见实践：

- 本地整理自己分支时，优先 `rebase`。
- 合并到主线时，使用 PR 平台的 `Squash merge` 或普通 `merge`，保持审查记录。

把 `rebase` 理解为“重放提交”，把 `merge` 理解为“创建汇合点”，就不会混淆。

==== 冲突处理：不要慌，按流程来

发生冲突时的标准流程：

```bash
git fetch origin
git rebase origin/main
# 编辑冲突文件，手动选择内容
git add <resolved_file>
git rebase --continue
```

冲突文件会出现标记：

```text
<<<<<<< HEAD
本分支内容
=======
目标分支内容
>>>>>>> origin/main
```

处理原则：

- 先保证编译通过，再追求局部优雅。
- 冲突解决后必须运行相关测试或最小回归验证。
- 复杂冲突不要单打独斗，直接拉相关作者一起看。


=== 团队工作流（PR、Code Review）
// 从“我写完了”到“团队可接收”
// - PR 生命周期
// - 审查清单
// - 提交粒度与可读性
// - CI 与门禁
// === 团队工作流（PR、Code Review）

PR（Pull Request / Merge Request）是团队协作的核心接口。它不仅是合并代码的入口，也是技术讨论、知识扩散和质量守门点。

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
- 30 分钟压力测试无崩溃

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

==== CI 与合并门禁

建议把以下检查设为 PR 必过门禁：

- 编译通过（Debug/Release 至少一套）。
- 单元测试通过。
- 基础静态检查通过（如 `clang-tidy` 的关键规则）。

把 CI 作为硬门禁后，主分支通常会稳定很多，线上回滚次数也会下降。

==== 团队落地清单（可放入 README）

如果你希望这章内容真正执行起来，可以先把下面 5 条写进团队规约：

1. `main` 开启保护，不允许直接 push。
2. 所有改动通过 PR 合并，至少 1 人 review。
3. CI 未通过禁止合并。
4. 提交信息遵循 `type(scope): message`。
5. 功能分支尽量短周期（建议 1~3 天内发起 PR）。

规则不用一开始就很复杂，先把这 5 条执行稳定，比讨论流程名字更重要。


=== .gitignore 与 submodule
// 管理仓库边界
// - 哪些文件不该入库
// - .gitignore 规则写法
// - 子模块的使用场景
// - submodule 的常见坑
// === .gitignore 与 submodule

==== `.gitignore`：让仓库只保存源码与必要资产

Git 不应跟踪编译产物、临时文件和本地环境文件。基础篇里前面已经大量出现 `build/ install/ log/`，这些都应该忽略。

RoboMaster C++/ROS2 项目常用的 `.gitignore` 示例：

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

# IDE
.vscode/
.idea/

# Python
__pycache__/
*.pyc

# Logs & runtime
*.log
core

# OS junk
.DS_Store
Thumbs.db
```

如果某文件已经被跟踪，再写到 `.gitignore` 不会自动生效，需要先取消跟踪：

```bash
git rm -r --cached build
git commit -m "chore(git): stop tracking build artifacts"
```

==== 什么时候该用 submodule

`submodule` 用于把另一个仓库作为“固定版本依赖”嵌入当前仓库，典型场景：

- 你们维护了一套通用算法库，多个项目共享。
- 需要锁定第三方仓库的特定提交，避免上游变动破坏稳定性。

添加子模块：

```bash
git submodule add git@github.com:team/rm_common.git third_party/rm_common
git commit -m "chore: add rm_common submodule"
```

更新子模块到新提交：

```bash
cd third_party/rm_common
git checkout main
git pull
cd ../..
git add third_party/rm_common
git commit -m "chore(submodule): bump rm_common"
```

克隆含子模块仓库后初始化：

```bash
git submodule update --init --recursive
```

==== submodule 常见误区

第一个误区是忘记更新子模块指针。你在子模块目录改完代码，但主仓库没 `git add` 子模块路径，别人拿不到更新。

第二个误区是把 submodule 当包管理器。若依赖频繁改动且强耦合，直接合并到同仓库或改用包管理方案通常更省心。

第三个误区是忽略开发体验。新成员不会处理 submodule，会导致“代码看着完整但编译不过”。必须在 README 写清初始化命令。


=== 小结：把 Git 当作工程系统而不是命令集合

学 Git 的终点不是记住更多命令，而是建立稳定的工程流程：

- 本地改动可控（小步提交、语义清晰）。
- 分支协作可控（隔离风险、及时同步）。
- 合并质量可控（PR + Review + CI）。
- 发布回滚可控（标签与稳定分支）。

把这四条流程长期执行下来，仓库会更稳：新人更容易接手，比赛前回滚也更快。
