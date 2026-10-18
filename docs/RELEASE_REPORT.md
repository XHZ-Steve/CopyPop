# CopyPop 1.0.0 开发交付报告

任务基准日期：2026-10-18（用户时区 Asia/Shanghai）。实际执行平台：Windows 11 x64。

## 实现范围

已完成 C++20 / Qt Quick / Win32 的单进程模块化应用：剪贴板格式监听及去重、复制证据判定、MTA UIA 查询与几何降级、三种可定制动画、透明穿透非激活覆盖层、窗口拖动与按需滚动追踪、焦点光标类型提示、全屏/游戏/演示保护、首次欢迎页、七类设置、逐应用继承规则、JSON 导入导出、主题、托盘、开机启动、单实例 IPC 和本地诊断。

剪贴板延迟渲染读取使用与 UIA 分离的工作线程，分类过期时保留基础格式，避免来源应用阻塞设置窗口。

欢迎页和实时预览使用同一 QML EffectLayer；示例复制会调用 TextEdit 的真实 copy()。应用没有剪贴板历史、上传、登录、键盘钩子、注入、跨进程 SetParent 或游戏内部接口。

工程包含 MIT 许可证、Lucide/Qt/MinGW/NSIS 说明、对应 Qt 源码下载脚本与本地源码归档、示例配置、Debug/Release 预设、Windows 构建/部署脚本、NSIS 配置、自动化测试与 CI 配置。

## 实际验证

- Qt 6.11.1 + MinGW 13.1.0，Debug 与 Release 均实际编译成功。
- CTest 两组：core、ui_native 均通过。覆盖配置、规则、格式优先级、真实控件点击、三种预览、规则对话框、深浅主题、欢迎页主按钮文字对比度、五种光标图标、覆盖层 native 属性、跨进程标准 Edit 选区与密码保护、全屏几何判定。
- 独立发布目录移除 Qt PATH、QT_PLUGIN_PATH、QML_IMPORT_PATH、QML2_IMPORT_PATH 后执行，14 个主题/页面组合、欢迎页、原生覆盖层与单实例唤醒均通过。
- 检查截图并修复屏幕名称映射、原生窗口 owner 在 show() 后被重置、窗口销毁顺序、控件主题对比度、预览选区测量及部署多余模块等问题。
- 一次设置窗口打开的测试进程采样：3 秒 CPU 累计时间增量记录为 0ms，工作集约 161 MB。该样本是短期观察，包含已加载设置与渲染资源，不能代表长期后台性能或其他电脑的数值。

测试证据位于 build/release/Testing、build/debug/Testing、build/deployment-qa。构建中可选 Qt 模块及 D3D12 编译器探测提示未阻止构建或默认 D3D11 运行。

## 发布产物

- `dist/CopyPop-1.0.0-windows-x64/CopyPop.exe`：带依赖的运行目录；解压便携 ZIP 后可直接启动。
- `dist/CopyPop-1.0.0-windows-x64.zip`：Windows x64 便携包。
- `dist/CopyPop-1.0.0-win64.exe`：NSIS 安装包，已生成；尚未执行安装/卸载。
- `dist/CopyPop-1.0.0-third-party-sources/`：本次 Qt 版本所用组件的官方源码归档及 SHA256 清单。对外分发二进制时应同时提供此目录的下载。
- `dist/SHA256SUMS.txt`：最终二进制校验清单。

源码提交到配置的 Git 仓库。构建目录、测试截图、安装包和下载的第三方源码归档不纳入源码 Git 历史；发布产物保留在本地 dist。

## 验证边界与限制

未将 Chrome、Office、Electron、终端、真实游戏、IME、多显示器混合 DPI、热插拔、Windows 10、MSVC 或长时间压力场景标为通过。这些需要目标设备与应用版本的专项验收。

标准 Edit 在本机没有提供 TextPattern，因此实际命中 L2 近似几何；精确 L3 依赖目标应用的 provider。某些控件没有可靠光标范围时会跳过提示。UIA provider 永久阻塞时保持单工作线程并降级，不会强杀 COM 调用。对滚动、遮挡和前台上下文无法确认时，覆盖层优先取消。自动复制推断无法保证捕捉所有右键复制和代理剪贴板操作。

界面目前为简体中文，语言标识为后续本地化预留。程序尚未签名。完整兼容性矩阵、降级行为与建议验收步骤见 COMPATIBILITY.md。
