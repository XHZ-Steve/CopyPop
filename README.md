# CopyPop

Windows 剪贴板微交互工具。复制时回应一束流光，输入前提示剪贴板类型，专注时静静退到托盘。

## 运行

从 `dist/CopyPop-1.0.0-windows-x64.zip` 解压到可写目录，运行 `CopyPop.exe`。不要直接在压缩包内启动。首次欢迎页可选择开机启动；点击 Get Started 后应用启动选项。关闭设置默认留在托盘，右键托盘图标可暂停、排除应用、打开欢迎页或退出。重复启动会唤醒设置。

目标系统为 Windows 10 22H2 / Windows 11 x64。当前构建与自动化测试在 Windows 11、Qt 6.11.1、MinGW 13.1.0 上执行。第三方应用与混合 DPI 验收范围见 [兼容性记录](docs/COMPATIBILITY.md)。

## 功能

- Win32 剪贴板事件、序列去重，识别文本、URL、图片、文件及其他格式。不保存历史，无上传功能。
- UI Automation MTA 选区查询、多矩形、短期几何快照、180ms 过期结果丢弃；不支持 TextPattern 的标准 Edit 使用有界几何查询降级。
- Shimmer / Pulse / Dissolve、选区自适应、颜色/透明度/速度/强度/曲线、实时预览。复制特效页可暂停、继续或拖动进度检查；展开调试参数可调整圆角、轮廓、流光宽度/倾角、脉冲次数和消散密度/距离，并显示选区边界。
- 颜色设置使用锚定色块的页内悬浮取色面板，支持 HSV、透明度和十六进制输入，确认后保存，取消或点外部关闭不修改颜色。所有设置滑条、取色滑条和预览进度均支持直接输入数值；子选项按用途分组，应用覆盖同样分组。复选框、下拉菜单和滑条采用统一样式。侧栏悬停高亮以 100 ms 快速切换；选中填充先在 85 ms 内拉长到目标边缘，再以 230 ms 缓动收回。快速切换从当前形状重定向，遵循系统减少动画偏好。
- 无法精确定位选区时，在鼠标光标旁显示 Copied；在“降级提示”中可设置开关、字样、文字/背景颜色（支持透明通道）、系统字体、字号、加粗、透明度、时长、偏移和圆角。淡入/淡出时长、曲线、位移和跟随力度/阻尼均可调整。提示通过 Qt 动画帧按实际时间计算弹簧加速度，预览与桌面共用 CopyToast 和 MotionFollower；移动预览区域内的光标可查看帧率和速度。实际提示在固定透明承载窗口内移动，并用单调时钟计算淡入淡出，持续跟随时不重启或延长动画。
- 独立透明窗口，输入穿透、不激活、不永久置顶；拖动跟随、按需滚动查询、失效取消。
- 可编辑控件焦点光标提示，默认 1.5 秒；密码框跳过，输入时隐藏。
- 全屏、Windows 演示/忙碌状态、离线游戏路径清单、逐应用排除。
- 浅色/深色/系统主题、JSON 配置导入导出、逐应用继承与覆盖、托盘与本地诊断。

## 构建

安装 CMake ≥3.25、Ninja、Qt ≥6.5（推荐 6.11.1）及其匹配的 MinGW 或 MSVC x64 编译器。需要 Core / Gui / Widgets / Quick / QuickControls2 / Network / Svg 模块；本地存在测试源码时额外需要 Test 模块。

```powershell
./scripts/build.ps1 -Configuration release
./scripts/build.ps1 -Configuration debug
# 非标准安装路径：指定具体 Kit，而不是 Qt 安装根目录
./scripts/build.ps1 -QtRoot C:/Qt/6.11.1/mingw_64
./scripts/package.ps1 -QtRoot C:/Qt/6.11.1/mingw_64
# NSIS 在 PATH 中时生成安装程序
./scripts/package.ps1 -QtRoot C:/Qt/6.11.1/mingw_64 -Installer
```

GitHub Actions 的 push/PR 默认仅构建 Debug；手动运行可选择 Release，不自动打包或发布。PowerShell 中应把编译器参数整体加引号，例如 `cmake --preset debug "-DCMAKE_CXX_COMPILER=cl.exe"`，避免 `.exe` 被拆成源码路径。

任务目标文档、`tests/` 和 `scripts/test-*.ps1` 仅保留在本地，通过 `.gitignore` 排除。公开仓库不包含这些文件，构建自动跳过本地测试目标。

脚本会探测常见 Qt 安装目录，核对 MinGW 主版本并明确指定 C++ 编译器，避免混用 MSYS2。MSVC Kit 通过 VsDevCmd 加载 x64 编译环境。CMakePresets 提供 release/debug 配置；自定义 Kit 可使用 `QT_ROOT` 或 `CMakeUserPresets.json`。

开发目录运行 exe 时需将 Kit 的 bin 加入 PATH。发布包通过 windeployqt 部署 Qt、QML、平台插件及编译器运行时，用户无需安装 Qt。

## 测试与诊断

```powershell
# 本地保留 tests/ 时，build.ps1 自动执行 CTest；匹配工具链环境下也可执行：
ctest --preset release --output-on-failure
./build/release/CopyPop.exe --smoke-test --test-config E:/temp/copypop-test.json
```

本地测试文件不纳入 Git；仅克隆公开源码时可运行上述 smoke-test。开发机另有 `scripts/test-deployment.ps1` 检查发布目录的独立运行。

核心测试覆盖 60/144/240 Hz 下弹簧计算的一致性、配置校验、持久化、迁移、规则继承、路径匹配和合成数据的类型识别。界面/原生测试打开本项目的测试窗口，检查真实控件点击、三种预览、主题、覆盖层属性，以及独立进程标准 Edit / 密码框的选区访问。不会向其他应用发送输入，也不会修改系统剪贴板。

配置存于 Qt 的用户 AppConfigLocation（通常 `%LOCALAPPDATA%/CopyPop/CopyPop/config.json`），诊断页显示实际位置。日志默认关闭，开启后仅写时间和固定事件名。损坏配置保留 `.invalid-backup` 供恢复。卸载不会删除用户配置；关闭开机启动或使用安装包卸载可移除启动项。

## 架构

`src/platform` 隔离 Win32、MTA UIA 查询和异步剪贴板分类；`src/core` 负责配置/规则；`App` 协调事件、保护状态与托盘；`IOverlayRenderer` 隔离渲染器；`qml/EffectLayer.qml` 同时服务桌面覆盖层和交互预览。没有全局键盘钩子、注入、跨进程 SetParent 或游戏内部 API。

剪贴板更新与“推测刚执行复制”是不同事件。只有按键状态证据，或剪贴板来源为前台窗口且查询确认存在选区时才播放。无法确定来源时可跳过；这会牺牲部分应用里的覆盖率，以避免后台同步误触发。

## 开源许可

CopyPop 使用 [MIT](LICENSE)；Lucide 使用 ISC。Qt 采用动态链接和 LGPLv3 路径。可替换兼容的 Qt 动态库，不限制为调试修改 Qt 所需的反向工程。许可证、精确源码获取方式及发布义务见 [第三方声明](THIRD_PARTY_NOTICES.md)。
