# RoboMaster 视觉从入门到入土

面向 RoboMaster 视觉组新队员的系统教程，用 [Typst](https://typst.app/) 编写，覆盖 Linux/工具链基础、数学理论、实战技术到整车应用。

- **在线阅读**：<https://aurora-ujs.github.io/RMCV_Tutorial/>（内置 PDF 阅读器，支持目录跳转）
- **直接下载**：<https://aurora-ujs.github.io/RMCV_Tutorial/main.pdf>

## 本地构建

依赖：

| 依赖 | 版本/来源 | 说明 |
| --- | --- | --- |
| Typst | 0.15.x | `cargo install typst-cli` 或[官方发布页](https://github.com/typst/typst/releases) |
| Fira Mono | 仓库自带（`fonts/`） | 代码西文字体，无需安装 |
| LXGW WenKai | `sudo apt install fonts-lxgw-wenkai` | 代码中文注释字体（楷体风格） |
| Noto CJK | `sudo apt install fonts-noto-cjk fonts-noto-cjk-extra` | 正文宋体（Noto Serif CJK SC） |

编译（在仓库根目录）：

```bash
typst compile --font-path fonts main.typ
```

代码字体按 Fira Mono、DejaVu Sans Mono、LXGW 和 Noto CJK 候选依次回退；实际选中的字形取决于 Typst 版本和构建机已安装的字体。要产出与项目持续集成（CI）一致的正式版本，请使用工作流中的 Typst 版本并装齐上表字体。

## 仓库结构

```
main.typ              # 全书入口：篇章级标题 + include 各篇 index
template/template.typ # 全局模板：字体、页面、代码块样式、定理环境等
chapters/<N.Part>/    # 每篇一个目录：index.typ 挂章标题，正文按章分文件
fonts/                # 仓库自带字体（Fira Mono，OFL 许可）
web/index.html        # GitHub Pages 在线阅读器（pdf.js）
```

新增章节：在对应篇的 `index.typ` 里加 `== 章标题` 和 `#include`，章节文件内从 `===` 起头（章标题由 index 提供，文件内不要重复写 `==`）。

## 持续集成

推送到 `main` 后，GitHub Actions 会用固定版本的 Typst 和上表字体从源码编译 PDF 并部署到 GitHub Pages，见 [.github/workflows/deploy-pages.yml](.github/workflows/deploy-pages.yml)。发布产物以 CI 构建为准。

## 许可

正文内容以仓库根目录 [LICENSE](LICENSE)（GPL-3.0）发布；`fonts/fira-mono/` 下的 Fira Mono 字体为 SIL OFL 1.1 许可，随附其 LICENSE 文件。
