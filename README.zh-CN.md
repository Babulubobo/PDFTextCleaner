# 复制文本清理器

[English](README.md)

一个原生 macOS 菜单栏小工具：合并 PDF 复制文本中的段内断行，保留空行分隔的段落和常见列表，左右对比，编辑结果并一键复制。

## 下载

从仓库的 **Releases** 下载 macOS 压缩包，解压并打开 **PDF Text Cleaner.app**，也可以拖入“应用程序”目录。点击屏幕顶部菜单栏的文字勾选图标展开窗口；应用不显示 Dock 图标，不会自行设置开机启动。

已编译版本适用于 **Apple Silicon、macOS 13+**。Intel Mac 可从源码构建。发布包使用本地 ad hoc 签名，未进行 Developer ID 签名或 Apple 公证，macOS 可能要求手动确认打开下载的应用。

## 自动模式

**“自动清理剪贴板”默认开启**，开关状态会被记住。复制多行文本，稍等约半秒，再直接粘贴到目标应用，无需先打开清理器。

需要清理的内容会变成**纯文本**，不保留富文本样式。单行文字、无需变化的结果、文件、图片、多条剪贴板项目，以及带有敏感／临时／自动生成标记的内容会跳过。启动或开启功能时已有的剪贴板内容保持原样。

窗口展示最近一次自动清理前后的内容。“**还原本次复制**”恢复原始文本及其剪贴板格式，仅在剪贴板仍是该次自动清理结果时可用，绝不覆盖后来复制的新内容。还原后不会立即再次清理。

自动模式作用于所有符合条件的多行复制，无法判断是不是来自 PDF。复制代码、诗歌、地址等需要保留换行的内容时，请关闭自动模式。如果 macOS 提示剪贴板访问权限，自动模式需要此权限。

## 手动模式与规则

关闭自动模式，点击“粘贴文本”或在左侧按 ⌘V。右侧结果可以继续修改，再点击“复制结果”或按 ⇧⌘C。“试用示例”载入与界面语言对应的演示文本。

- 空行作为段落边界，常见编号列表和项目符号保留独立行。
- 中文断行直接连接，英文单词之间保留空格。
- “修复英文断词”默认关闭。开启后会把 `inter-` 换行 `national` 合成 `international`，也可能移除原本需要的连字符。
- 修改原文或选项会重新生成右侧结果，覆盖右侧手动修改。
- 没有空行时无法可靠识别原段落，可以补空行或修改右侧结果。

## 语言与隐私

界面自动跟随系统首选的受支持语言：**简体中文、繁体中文、英文**，其他语言回退英文。修改系统语言后请重新启动应用。清理不会翻译原文。

所有文本在本机处理，不联网、不收集分析数据、不保存剪贴板历史文件。最近的原文、结果及可还原内容仅在内存中保留，只保存自动模式开关偏好。应用不需要屏幕录制或辅助功能权限。

## 测试样例

复制 [Examples/before.txt](Examples/before.txt)，稍等片刻后粘贴到纯文本编辑器。预期结果见 [Examples/after.txt](Examples/after.txt)，可忽略文件末尾换行。

## 构建与检查

需要 macOS 13+ 和兼容的 **Swift 5.9+** 工具链（Xcode 或 Command Line Tools），无需第三方依赖。

```bash
swift run --disable-sandbox CleanerChecks
swift scripts/check-localizations.swift
bash scripts/build.sh
open "dist/PDF Text Cleaner.app"
```

剪贴板测试使用独立测试剪贴板，不读取或覆盖通用剪贴板。GitHub Actions 在推送和 PR 时运行检查与构建。默认构建当前 Mac 架构。

可选环境变量：`CONFIGURATION=debug`、`SIGNING_IDENTITY`、`APP_OUTPUT`、`BUILD_DIRECTORY`。

Release 构建会在签名前去除调试符号，并拒绝包含本机用户目录路径的程序。使用以下命令打包默认的 Release 构建，不携带 macOS 文件元数据：

```bash
ditto -c -k --norsrc --noextattr --noqtn --noacl --keepParent "dist/PDF Text Cleaner.app" "dist/PDF-Text-Cleaner.zip"
```
