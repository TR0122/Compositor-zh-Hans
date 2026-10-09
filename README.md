# Compositor 简体中文版

Compositor 是使用 Swift、SwiftUI 和 AppKit 开发的开源 macOS 图像编辑器。本仓库提供基于 [robbietilton/Compositor](https://github.com/robbietilton/Compositor) **v1.4.7** 的简体中文衍生版本，包含完整应用源码、中文资源、测试、构建脚本及文档。

**Apple 芯片（arm64） · macOS 26.0 或以上 · MIT License**

这是社区汉化版本，与上游开发者没有官方关联。原项目介绍见 [上游 README](README.upstream.md)。

## 下载和安装

在本仓库的 [Releases 页面](https://github.com/TR0122/Compositor-zh-Hans/releases)下载 `Compositor-1.4.7-zh-Hans-arm64.dmg`，打开后将「Compositor 中文版」拖到「应用程序」。可使用同一发布中的 `SHA256SUMS.txt` 校验文件。

本版本使用临时签名，尚未经过 Apple 公证；macOS 可能阻止首次打开。应用与英文原版使用不同的标识，可以并存。

## 汉化内容

- 菜单、工具栏、工具说明、图层、混合模式、调整和滤镜。
- Camera Raw、文件操作、快捷键编辑器、命令搜索、对话框和错误提示。
- 中文命令搜索、新建图层名称和操作历史。

品牌、字体、格式名称和技术缩写保留原文。用户已有项目中的自定义名称保留原样。`.comp` 格式、混合模式等序列化标识仍使用原有英文值。

快捷键沿用上游，例如 ⌘N 新建、⌘O 打开、⌘S 存储、⌘F 搜索命令、B 画笔、T 文字、V 移动/变换。上游 Sparkle 自动更新已移除，以免英文版更新覆盖译文。

## 从源码构建

### 使用 Xcode

安装包含 macOS 26 SDK 的完整 Xcode，打开 `Compositor.xcodeproj`，选择 **Compositor** scheme。使用自己的签名配置，或在终端执行本地签名构建：

```sh
xcodebuild -project Compositor.xcodeproj -scheme Compositor \
  -destination 'platform=macOS,arch=arm64' -configuration Release \
  -derivedDataPath DerivedData CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM= build
```

图标源文件和所有应用代码均包含在仓库中，Xcode 构建不需要预装官方应用。

### 仅使用 Command Line Tools

本次发布使用 Apple Swift 6.4 和 **macOS 26.5 SDK** 构建。备用脚本需要先从[官方 v1.4.7 发布](https://github.com/robbietilton/Compositor/releases/tag/v1.4.7)安装英文原版到 `/Applications/Compositor.app`，仅从它复制已经编译的图标资源；Swift 和 C 代码全部由本仓库重新编译。

```sh
python3 scripts/build-localized.py
python3 scripts/verify-localization.py
```

结果为 `dist/Compositor 中文版.app`。构建和验证脚本默认使用 `/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk`。

## 测试和发布

[VALIDATION.md](VALIDATION.md) 记录本次实际验证：独立集成检查 **84 项通过**，应用签名和资源检查通过，中文界面已启动验证。完整 Xcode 单元/UI 测试未在本机执行。

完整 Xcode 环境可运行：

```sh
xcodebuild -project Compositor.xcodeproj -scheme Compositor \
  -destination 'platform=macOS,arch=arm64' \
  CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM= test -only-testing:CompositorTests
```

`scripts/release.sh` 可以将本地构建打包为临时签名 DMG；`scripts/publish.sh` 使用已登录的 GitHub CLI 将 DMG 和源码发布到当前仓库，默认拒绝发布到上游仓库。二者均不需要上游签名密钥或 Sparkle 配置。

## 参与翻译

中文静态资源位于 [`Compositor/zh-Hans.lproj/Localizable.strings`](Compositor/zh-Hans.lproj/Localizable.strings)，查找入口为 [`Compositor/Localization.swift`](Compositor/Localization.swift)。动态文本也在 Swift 源码中。修改显示文本时，请保留 `.comp` 文件使用的枚举原始值和 PSD 等格式的内部键。

## 许可和来源

原始版权 **Copyright (c) 2026 Wonder Assembly LLC**，继续保留 [MIT 许可证](LICENSE)。汉化修改也以 MIT 许可证发布。

基线版本：上游 `v1.4.7`，提交 `675d8a4479de53c582c70ac3b7a46766f1fc7d1a`。本仓库包含修改后的完整源码；后续版本可继续合并上游更新并补充译文。
