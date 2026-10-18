# CopyPop

Windows 剪贴板微交互工具。复制时回应一束流光，输入前提示剪贴板类型，专注时静静退到托盘。

## 运行

从 `dist/CopyPop-1.0.0-windows-x64.zip` 解压到可写目录，运行 `CopyPop.exe`。不要直接在压缩包内启动。首次欢迎页可选择开机启动；点击 Get Started 后应用启动选项。关闭设置默认留在托盘，右键托盘图标可暂停、排除应用、打开欢迎页或退出。重复启动会唤醒设置。

目标系统为 Windows 10 22H2 / Windows 11 x64。当前构建与自动化测试在 Windows 11、Qt 6.11.1、MinGW 13.1.0 上执行。第三方应用与混合 DPI 验收范围见 [兼容性记录](docs/COMPATIBILITY.md)。

## 功能

- Win32 剪贴板事件、序列去重，识别文本、URL、图片、文件及其他格式。不保存历史，无上传功能。
- UI Automation MTA 选区查询、多矩形、短期几何快照、180ms 过期结果丢弃；不支持 TextPattern 的标准 Edit 使用有界几何查询降级。
- Shimmer / Pulse / Dissolve、选区自适应、颜色/透明度/速度/强度/曲线、实时预览。
- 独立透明窗口，输入穿透、不激活、不永久置顶；拖动跟随、按需滚动查询、失效取消。
- 可编辑控件焦点光标提示，默认 1.5 秒；密码框跳过，输入时隐藏。
- 全屏、Windows 演示/忙碌状态、离线游戏路径清单、逐应用排除。
- 浅色/深色/系统主题、JSON 配置导入导出、逐应用继承与覆盖、托盘与本地诊断。

## 构建

安装 CMake ≥3.25、Ninja、Qt ≥6.5（推荐 6.11.1）及其匹配的 MinGW 或 MSVC x64 编译器。需要 Core / Gui / Widgets / Quick / QuickControls2 / Network / Svg / Test 模块。

```powershell
./scripts/build.ps1 -Configuration release
./scripts/build.ps1 -Configuration debug
# 非标准安装路径：指定具体 Kit，而不是 Qt 安装根目录
./scripts/build.ps1 -QtRoot C:/Qt/6.11.1/mingw_64
./scripts/package.ps1 -QtRoot C:/Qt/6.11.1/mingw_64
# NSIS 在 PATH 中时生成安装程序
./scripts/package.ps1 -QtRoot C:/Qt/6.11.1/mingw_64 -Installer
# 在没有 Qt 环境变量的条件下检查发布目录（会打开本程序的测试窗口）
./scripts/test-deployment.ps1
```

脚本会探测常见 Qt 安装目录，核对 MinGW 主版本并明确指定 C++ 编译器，避免混用 MSYS2。MSVC Kit 通过 VsDevCmd 加载 x64 编译环境。CMakePresets 提供 release/debug 配置；自定义 Kit 可使用 `QT_ROOT` 或 `CMakeUserPresets.json`。

开发目录运行 exe 时需将 Kit 的 bin 加入 PATH。发布包通过 windeployqt 部署 Qt、QML、平台插件及编译器运行时，用户无需安装 Qt。

## 测试与诊断

```powershell
# build.ps1 自动执行 CTest，也可在匹配工具链环境下执行：
ctest --preset release --output-on-failure
./build/release/CopyPop.exe --smoke-test --test-config E:/temp/copypop-test.json
```

核心测试覆盖配置校验、持久化、迁移、规则继承、路径匹配和合成数据的类型识别。界面/原生测试打开本项目的测试窗口，检查真实控件点击、三种预览、主题、覆盖层属性，以及独立进程标准 Edit / 密码框的选区访问。不会向其他应用发送输入，也不会修改系统剪贴板。

配置存于 Qt 的用户 AppConfigLocation（通常 `%LOCALAPPDATA%/CopyPop/CopyPop/config.json`），诊断页显示实际位置。日志默认关闭，开启后仅写时间和固定事件名。损坏配置保留 `.invalid-backup` 供恢复。卸载不会删除用户配置；关闭开机启动或使用安装包卸载可移除启动项。

## 架构

`src/platform` 隔离 Win32、MTA UIA 查询和异步剪贴板分类；`src/core` 负责配置/规则；`App` 协调事件、保护状态与托盘；`IOverlayRenderer` 隔离渲染器；`qml/EffectLayer.qml` 同时服务桌面覆盖层和交互预览。没有全局键盘钩子、注入、跨进程 SetParent 或游戏内部 API。

剪贴板更新与“推测刚执行复制”是不同事件。只有按键状态证据，或剪贴板来源为前台窗口且查询确认存在选区时才播放。无法确定来源时可跳过；这会牺牲部分应用里的覆盖率，以避免后台同步误触发。

## 开源许可

CopyPop 使用 [MIT](LICENSE)；Lucide 使用 ISC。Qt 采用动态链接和 LGPLv3 路径。可替换兼容的 Qt 动态库，不限制为调试修改 Qt 所需的反向工程。许可证、精确源码获取方式及发布义务见 [第三方声明](THIRD_PARTY_NOTICES.md)。
