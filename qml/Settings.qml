import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

ApplicationWindow {
    id: settingsWindow
    width: 1040; height: 770; minimumWidth: 860; minimumHeight: 640
    title: "CopyPop"; color: tokens.background
    font.family: "Microsoft YaHei UI"
    font.pixelSize: 14
    property int page: typeof TestPage === "undefined" ? 0 : TestPage
    property var pages: [
        {title:"常规",subtitle:"悄然运行，随时可用。",icon:"settings-2"},
        {title:"复制特效",subtitle:"给每次复制，恰到好处的回应。",icon:"sparkles"},
        {title:"降级提示",subtitle:"无法精确定位选区时，在光标旁轻轻提示。",icon:"message-square"},
        {title:"光标提示",subtitle:"在开始输入前，了解剪贴板的内容类型。",icon:"text-cursor-input"},
        {title:"窗口追踪",subtitle:"让动效留在它应该出现的地方。",icon:"scan-line"},
        {title:"专注保护",subtitle:"专注、演示和游戏时，自动退到幕后。",icon:"shield-check"},
        {title:"应用规则",subtitle:"为每个应用保留自己的节奏。",icon:"app-window"},
        {title:"高级",subtitle:"诊断、配置与版本信息。",icon:"sliders-horizontal"}
    ]
    property var specs: [
        [
            {section:"运行行为",key:"enabled",label:"启用 CopyPop",note:"复制特效与光标提示的总开关。",type:"bool"},
            {key:"startup",label:"开机启动",note:"登录当前 Windows 账号时在托盘中启动。",type:"bool"},
            {key:"closeToTray",label:"关闭后留在托盘",note:"关闭设置窗口后继续运行；可从托盘菜单退出。",type:"bool"},
            {section:"外观",key:"theme",label:"外观",type:"choice",options:[{label:"跟随系统",value:"system"},{label:"浅色",value:"light"},{label:"深色",value:"dark"}]}
        ],
        [
            {section:"启用与模式",key:"effectsEnabled",label:"复制特效",note:"仅在有复制操作证据时播放。默认不播放粘贴动画。",type:"bool"},
            {key:"effect",label:"动画类型",type:"choice",options:[{label:"Shimmer · 流光",value:"shimmer"},{label:"Pulse · 脉冲",value:"pulse"},{label:"Dissolve · 消散",value:"dissolve"}]},
            {key:"adaptive",label:"自适应选区",note:"按行数增强多行流光；大面积消散改用轻量轮廓。",type:"bool"},
            {section:"颜色与强度",key:"color",label:"特效颜色",note:"点击色块打开取色器，也可输入色值。",type:"color"},
            {key:"intensity",label:"强度",type:"number",min:0.1,max:1,step:0.05,decimals:2},
            {key:"opacity",label:"不透明度",type:"number",min:0.05,max:1,step:0.05,decimals:2},
            {section:"播放节奏",key:"durationMode",label:"时长模式",type:"choice",options:[{label:"固定时长",value:"fixed"},{label:"自适应匀速",value:"adaptive"}]},
            {whenKey:"durationMode",whenValue:"fixed",key:"speed",label:"播放速度",type:"number",min:0.25,max:3,step:0.05,decimals:2,unit:"×"},
            {whenKey:"durationMode",whenValue:"fixed",key:"duration",label:"基础时长",type:"number",min:150,max:2500,step:50,unit:"ms"},
            {whenKey:"durationMode",whenValue:"fixed",key:"curve",label:"动画曲线",type:"choice",options:[{label:"柔和减速",value:"outCubic"},{label:"正弦缓入缓出",value:"inOutSine"},{label:"线性",value:"linear"}]},
            {whenKey:"durationMode",whenValue:"adaptive",key:"adaptiveBaseTime",label:"基础时间",note:"扫过 400 px 视觉路程所需的时间；匀速模式使用线性移动。",type:"number",min:100,max:2000,step:20,unit:"ms"},
            {whenKey:"durationMode",whenValue:"adaptive",key:"adaptiveTimeScale",label:"时长缩放比",note:"实际时长 = 基础时间 × 扫光路程 / 400 × 缩放比。越小越快。",type:"number",min:0.25,max:3,step:0.05,decimals:2,unit:"×"},
            {section:"系统偏好",key:"respectReducedMotion",label:"遵循系统动画偏好",note:"Windows 关闭动画效果时，使用短暂、低强度的脉冲。",type:"bool"}
        ],
        [
            {section:"启用",key:"fallbackEnabled",label:"启用 Copied 提示",note:"无法获得精确选区、查询超时或关闭复制特效时，显示光标旁提示。",type:"bool"},
            {section:"文字内容与字体",key:"fallbackText",label:"自定义字样",note:"最多 80 个字符，以纯文本显示。",type:"text",maxLength:80},
            {key:"fallbackFont",label:"字体",type:"font"},
            {key:"fallbackFontSize",label:"字号",type:"number",min:10,max:36,step:1,unit:"px"},
            {key:"fallbackBold",label:"加粗文字",type:"bool"},
            {key:"fallbackTextColor",label:"文字颜色",type:"color"},
            {section:"背景与外观",key:"fallbackBackgroundColor",label:"背景颜色",type:"color"},
            {key:"fallbackOpacity",label:"整体不透明度",type:"number",min:0.1,max:1,step:0.05,decimals:2},
            {key:"fallbackRadius",label:"背景圆角",type:"number",min:0,max:20,step:1,unit:"px"},
            {section:"显示位置",key:"fallbackOffsetX",label:"水平偏移",type:"number",min:-120,max:120,step:1,unit:"px"},
            {key:"fallbackOffsetY",label:"垂直偏移",type:"number",min:-120,max:120,step:1,unit:"px"},
            {section:"播放与淡入淡出",key:"fallbackDuration",label:"显示时长",type:"number",min:300,max:4000,step:100,unit:"ms"},
            {key:"fallbackFadeIn",label:"淡入时长",type:"number",min:0,max:800,step:10,unit:"ms"},
            {key:"fallbackFadeOut",label:"淡出时长",note:"淡入与淡出超过总时长时，按比例缩短。",type:"number",min:0,max:800,step:10,unit:"ms"},
            {key:"fallbackFadeCurve",label:"淡入淡出曲线",type:"choice",options:[{label:"正弦缓入缓出",value:"inOutSine"},{label:"柔和减速 / 加速",value:"outCubic"},{label:"线性",value:"linear"}]},
            {key:"fallbackLift",label:"淡入淡出位移",note:"遵循系统减少动画偏好；关闭动画时仅保留透明度变化。",type:"number",min:0,max:16,step:1,unit:"px"},
            {section:"光标跟随",key:"fallbackFollowStiffness",label:"跟随力度",note:"弹簧加速度系数，越高越快接近光标。按实际动画帧间隔计算。",type:"number",min:80,max:2000,step:20},
            {key:"fallbackFollowDamping",label:"跟随阻尼",note:"1 为临界阻尼；小于 1 有回弹，大于 1 更沉稳。",type:"number",min:0.4,max:2,step:0.05,decimals:2}
        ],
        [
            {section:"启用",key:"caretEnabled",label:"显示光标提示",note:"仅限可定位的可编辑控件；密码与受保护控件自动跳过。",type:"bool"},
            {section:"图标外观",key:"caretSize",label:"图标大小",type:"number",min:14,max:48,step:1,unit:"px"},
            {key:"caretOpacity",label:"不透明度",type:"number",min:0.1,max:1,step:0.05,decimals:2},
            {section:"显示位置",key:"caretOffsetX",label:"水平偏移",type:"number",min:-80,max:80,step:1,unit:"px"},
            {key:"caretOffsetY",label:"垂直偏移",type:"number",min:-80,max:80,step:1,unit:"px"},
            {section:"播放时序",key:"caretDuration",label:"显示时长",type:"number",min:300,max:4000,step:100,unit:"ms"},
            {key:"caretFade",label:"淡入 / 淡出时长",type:"number",min:50,max:600,step:10,unit:"ms"}
        ],
        [
            {section:"追踪策略",key:"hybridTracking",label:"智能混合追踪",note:"结合 UI Automation、焦点事件与短期几何快照。关闭后仅保留鼠标附近的复制反馈。",type:"bool"},
            {section:"选区与滚动",key:"scrollFollow",label:"精确滚动跟随",note:"按需重新查询真实选区。无法及时确认位置时取消特效。",type:"bool"},
            {key:"predictScroll",label:"短期预测跟随",note:"高级选项，默认关闭。只使用已观测的选区位移，不使用滚轮像素换算。",type:"bool"},
            {section:"窗口跟随",key:"dragFollow",label:"窗口拖动跟随",note:"跟随窗口坐标变化；调整大小导致文本重排时取消特效。",type:"bool"},
            {section:"层级与裁剪",key:"dynamicZ",label:"动态窗口层级",note:"显示时置于所属窗口上方，不使用永久全局置顶。前台切换始终取消。",type:"bool"},
            {key:"clipRegion",label:"有效区域裁剪",note:"几何查询始终裁剪到控件与客户区；追踪时进一步校验可见区域。",type:"bool"}
        ],
        [
            {section:"自动保护",key:"guardFullscreen",label:"全屏自动休眠",note:"识别覆盖显示器的全屏窗口，包括无边框全屏。",type:"bool"},
            {key:"guardGames",label:"已知游戏自动排除",note:"使用内置离线路径清单。其他游戏可在应用规则中添加。",type:"bool"},
            {key:"guardPresentation",label:"演示状态自动休眠",note:"遵循 Windows 演示、忙碌及 Direct3D 全屏状态。",type:"bool"}
        ],[],
        [{section:"日志记录",key:"diagnostics",label:"本地诊断日志",note:"仅记录事件名称和时间。不会记录剪贴板内容、窗口标题或按键。日志上限约 512 KB。",type:"bool"}]
    ]
    property bool showEffectTuning: false
    property var effectTuningSpecs: [
        {section:"通用几何",key:"effectRadius",label:"选区圆角",type:"number",min:0,max:16,step:1,unit:"px"},
        {key:"effectBorder",label:"轮廓基础宽度",type:"number",min:0,max:4,step:0.1,decimals:1,unit:"px"},
        {section:"流光 · Shimmer",key:"shimmerWidth",label:"流光宽度",note:"相对于每段选区宽度。",type:"number",min:10,max:100,step:1,unit:"%"},
        {key:"shimmerAngle",label:"流光倾角",type:"number",min:-45,max:45,step:1,unit:"°"},
        {section:"脉冲 · Pulse",key:"pulseCycles",label:"脉冲次数",type:"number",min:1,max:6,step:1},
        {section:"消散 · Dissolve",key:"dissolveDensity",label:"消散粒子密度",note:"每 100 px 的粒子数，每段最多 48 个。",type:"number",min:4,max:40,step:1},
        {key:"dissolveTravel",label:"消散移动距离",type:"number",min:0,max:100,step:1,unit:"px"},
        {section:"调试显示",key:"effectDebugBounds",label:"显示选区调试边界",note:"在预览和实际特效中标出真实选区；仅播放期间显示。",type:"bool"}
    ]
    Theme { id: tokens }
    palette.window: tokens.background
    palette.windowText: tokens.text
    palette.base: tokens.surface
    palette.text: tokens.text
    palette.button: tokens.surface
    palette.buttonText: tokens.text
    palette.highlight: tokens.accent
    palette.highlightedText: tokens.accentText
    onClosing: function(close) { if(!Config.values.closeToTray) App.quit() }
    RowLayout {
        anchors.fill: parent; spacing: 0
        Rectangle {
            Layout.fillHeight: true; Layout.preferredWidth: 216; color: tokens.sidebar
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 16; spacing: 5
                RowLayout {
                    Layout.topMargin: 18; Layout.bottomMargin: 28; Layout.leftMargin: 10; spacing: 12
                    Image { source: "qrc:/resources/icons/app.svg"; Layout.preferredWidth: 38; Layout.preferredHeight: 38; sourceSize: Qt.size(76,76) }
                    Label { text: "CopyPop"; color: tokens.text; font.pixelSize: 23; font.weight: Font.DemiBold }
                }
                SidebarNavigation {
                    objectName: "sidebar-navigation"
                    Layout.fillWidth: true
                    pages: settingsWindow.pages
                    currentIndex: settingsWindow.page
                    onSelected: function(index) { settingsWindow.page=index; scroller.contentItem.contentY=0 }
                }
                Item { Layout.fillHeight: true }
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 64; radius: 10; color: tokens.surface
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 12; spacing: 4
                        Label { text: App.status; color: tokens.accent; font.pixelSize: 13; font.weight: Font.DemiBold }
                        Label { text: "1.0.0 · Alpha"; color: tokens.muted; font.pixelSize: 11 }
                    }
                }
            }
        }
        ColumnLayout {
            Layout.fillHeight: true; Layout.fillWidth: true; Layout.margins: 32; spacing: 10
            Label { text: settingsWindow.pages[settingsWindow.page].title; color: tokens.text; font.pixelSize: 28; font.weight: Font.DemiBold; Layout.topMargin: 10 }
            Label { text: settingsWindow.pages[settingsWindow.page].subtitle; color: tokens.muted; font.pixelSize: 13; Layout.bottomMargin: 15; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            Rectangle {
                visible: App.notice.length > 0 || Config.error.length > 0
                Layout.fillWidth: true; implicitHeight: Math.max(48,noticeLabel.implicitHeight+22); radius: 8; color: tokens.selected
                RowLayout {
                    anchors.fill: parent; anchors.margins: 10
                    Label { id: noticeLabel; text: Config.error || App.notice; color: tokens.text; wrapMode: Text.WordWrap; Layout.fillWidth: true; font.pixelSize: 12 }
                    ActionButton { text: "关闭"; flat: true; onClicked: App.dismissNotice() }
                }
            }
            ScrollView {
                id: scroller
                objectName: "settings-scroll"
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                contentWidth: availableWidth
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ColumnLayout {
                    width: scroller.availableWidth; spacing: 18
                    Preview { visible: settingsWindow.page === 1; Layout.fillWidth: true; theme: tokens }
                    FallbackPreview { visible: settingsWindow.page === 2; Layout.fillWidth: true; theme: tokens }

                    RowLayout {
                        visible: settingsWindow.page === 1; Layout.fillWidth: true
                        Label { text: "主题预设"; color: tokens.muted; Layout.fillWidth: true }
                        Repeater {
                            model: [{label:"海蓝",value:"ocean"},{label:"薄荷",value:"mint"},{label:"蔷薇",value:"rose"}]
                            ActionButton { required property var modelData; text: modelData.label; highlighted: Config.values.preset===modelData.value; onClicked: App.preset(modelData.value) }
                        }
                    }
                    SettingsGroups {
                        Layout.fillWidth: true; visible: specifications.length>0
                        specifications: settingsWindow.specs[settingsWindow.page]; theme: tokens
                        onEdited: function(spec,value) { if(Config.set(spec.key,value) && spec.key==="color") Config.set("preset","custom") }
                    }
                    StyledCheckBox {
                        visible: settingsWindow.page === 1
                        text: "展开复制特效调试参数"; checked: settingsWindow.showEffectTuning
                        onToggled: settingsWindow.showEffectTuning=checked
                    }
                    SettingsGroups {
                        Layout.fillWidth: true; visible: settingsWindow.page===1 && settingsWindow.showEffectTuning
                        specifications: settingsWindow.effectTuningSpecs; theme: tokens
                        onEdited: function(spec,value) { Config.set(spec.key,value) }
                    }
                    Rectangle {
                        visible: settingsWindow.page === 0
                        Layout.fillWidth: true; implicitHeight: languageColumn.implicitHeight+40; color: tokens.surface; radius: 12; border.color: tokens.border
                        ColumnLayout {
                            id: languageColumn; anchors.fill: parent; anchors.margins: 20; spacing: 10
                            Label { text: "语言与引导"; color: tokens.text; font.weight: Font.Medium }
                            ActionButton { objectName: "reopen-welcome"; text: "重新打开欢迎页"; onClicked: App.showWelcome() }
                            Label { text: "简体中文\n配置保留语言标识，后续版本将加入更多界面语言。"; color: tokens.muted; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                        }
                    }
                    Rectangle {
                        visible: settingsWindow.page === 3
                        Layout.fillWidth: true; implicitHeight: typeColumn.implicitHeight+36; radius: 12; color: tokens.surface; border.color: tokens.border
                        ColumnLayout {
                            id: typeColumn; anchors.fill: parent; anchors.margins: 18; spacing: 10
                            Label { text: "显示这些内容类型"; color: tokens.text; font.weight: Font.Medium }
                            Flow {
                                objectName: "caret-types"
                                Layout.fillWidth: true; spacing: 8
                                Repeater {
                                    model: [{key:"text",name:"文本",icon:"type"},{key:"url",name:"链接",icon:"link"},{key:"image",name:"图片",icon:"image"},{key:"files",name:"文件",icon:"files"},{key:"other",name:"其他",icon:"circle-help"}]
                                    StyledCheckBox {
                                        required property var modelData
                                        objectName: "caret-type-"+modelData.key
                                        text: modelData.name; checked: Config.values.caretTypes.split(',').indexOf(modelData.key) >= 0
                                        icon.source: "qrc:/resources/icons/"+modelData.icon+".svg"; icon.color: tokens.accent
                                        onToggled: {
                                            var list = Config.values.caretTypes.split(',').filter(function(s){return s.length && s!==modelData.key});
                                            if(checked) list.push(modelData.key);
                                            Config.set("caretTypes",list.join(','))
                                        }
                                    }
                                }
                            }
                            Label { text: "开始输入、焦点变化或位置无法确认时提前隐藏。"; color: tokens.muted; font.pixelSize: 12; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                        }
                    }
                    ColumnLayout {
                        visible: settingsWindow.page === 5; Layout.fillWidth: true; spacing: 12
                        Label { text: "手动排除"; color: tokens.text; font.weight: Font.DemiBold }
                        Label { text: App.lastApplication.length ? "最近应用："+App.lastApplication : "切换到外部应用后，可从这里将它排除。"; color: tokens.muted; wrapMode: Text.WrapAnywhere; font.pixelSize: 12; Layout.fillWidth: true }
                        RowLayout {
                            ActionButton { text: "排除最近应用"; enabled: App.lastApplication.length>0; onClicked: App.excludeRecent() }
                            ActionButton { text: "管理应用规则"; onClicked: settingsWindow.page=6 }
                        }
                        Label { text: "保护状态会隐藏全部覆盖层并停止选区查询。普通动画预设和逐应用设置不会绕过全局保护。"; color: tokens.muted; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                    }
                    ColumnLayout {
                        visible: settingsWindow.page === 6; Layout.fillWidth: true; spacing: 14
                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: Config.applications.length + " 个应用规则"; color: tokens.muted; Layout.fillWidth: true }
                            ActionButton { text: "添加应用"; highlighted: true; onClicked: App.chooseApplication() }
                        }
                        Label { visible: Config.applications.length===0; text: "还没有应用规则。\n添加 .exe 文件，自定义动画或将该应用排除。\n未覆盖的选项会自动继承全局设置。"; color: tokens.muted; lineHeight: 1.6; Layout.fillWidth: true; wrapMode: Text.WordWrap; Layout.margins: 20 }
                        Repeater {
                            model: Config.applications
                            delegate: Rectangle {
                                required property var modelData; required property int index
                                Layout.fillWidth: true; implicitHeight: appRuleColumn.implicitHeight+32; radius: 10; color: tokens.surface; border.color: tokens.border
                                ColumnLayout {
                                    id: appRuleColumn; anchors.fill: parent; anchors.margins: 16; spacing: 9
                                    Label { text: modelData.path.split('/').pop(); color: tokens.text; font.pixelSize: 15; font.weight: Font.DemiBold }
                                    Label { text: modelData.path; color: tokens.muted; font.pixelSize: 11; wrapMode: Text.WrapAnywhere; Layout.fillWidth: true }
                                    RowLayout {
                                        Label { text: modelData.overrides.excluded ? "已排除" : Object.keys(modelData.overrides).length ? "已自定义 · 其余继承全局" : "全部继承全局设置"; color: tokens.muted; Layout.fillWidth: true; font.pixelSize: 12 }
                                        ActionButton { text: "编辑"; onClicked: ruleDialog.edit(modelData.path,modelData.overrides) }
                                        ActionButton { text: "删除"; onClicked: Config.removeRule(index) }
                                    }
                                }
                            }
                        }
                    }
                    ColumnLayout {
                        visible: settingsWindow.page === 7; Layout.fillWidth: true; spacing: 14
                        Label { text: "诊断状态"; color: tokens.text; font.weight: Font.DemiBold }
                        Rectangle {
                            Layout.fillWidth: true; implicitHeight: diagnosticText.implicitHeight+36; radius: 10; color: tokens.surface; border.color: tokens.border
                            Label { id: diagnosticText; anchors.fill: parent; anchors.margins: 18; text: App.diagnostics; color: tokens.muted; font.pixelSize: 12; lineHeight: 1.55; wrapMode: Text.WrapAnywhere }
                        }
                        Label { text: "配置与维护"; color: tokens.text; font.weight: Font.DemiBold }
                        Flow {
                            Layout.fillWidth: true; spacing: 10
                            ActionButton { text: "导入配置"; onClicked: App.importConfig() }
                            ActionButton { text: "导出配置"; onClicked: App.exportConfig() }
                            ActionButton { text: "打开日志目录"; onClicked: App.openLogs() }
                            ActionButton { text: "清除日志"; onClicked: App.clearLogs() }
                            ActionButton { text: "恢复默认"; onClicked: resetDialog.open() }
                            ActionButton { text: "关于 CopyPop"; onClicked: App.about() }
                        }
                        Label { text: "MIT 开源许可 · Lucide 图标（ISC）\nQt 动态链接，遵循 LGPLv3。许可证与依赖说明随发布包提供。"; color: tokens.muted; Layout.fillWidth: true; wrapMode: Text.WordWrap; font.pixelSize: 12; lineHeight: 1.5 }
                    }
                    Item { Layout.preferredHeight: 15 }
                }
            }
        }
    }
    Dialog {
        id: resetDialog; anchors.centerIn: parent; modal: true; title: "恢复默认设置？"; standardButtons: Dialog.Ok | Dialog.Cancel
        Label { text: "这将清除自定义设置和应用规则。"; color: tokens.text }
        onAccepted: App.resetConfig()
    }
    Dialog {
        id: ruleDialog; objectName: "rule-editor"; anchors.centerIn: parent; width: Math.min(620,settingsWindow.width-50); height: Math.min(650,settingsWindow.height-60); modal: true
        title: "编辑应用规则"; standardButtons: Dialog.Save | Dialog.Cancel
        property string path: ""
        property var overrides: ({})
        property var editable: [
            {section:"范围与开关",key:"excluded",label:"排除此应用",type:"bool"},
            {key:"effectsEnabled",label:"复制特效",type:"bool"},
            {key:"caretEnabled",label:"光标提示",type:"bool"},
            {key:"fallbackEnabled",label:"降级 Copied 提示",type:"bool"},
            {section:"窗口与选区追踪",key:"hybridTracking",label:"智能追踪",type:"bool"},
            {key:"scrollFollow",label:"滚动跟随",type:"bool"},
            {key:"dragFollow",label:"拖动跟随",type:"bool"},
            {section:"特效模式",key:"adaptive",label:"自适应特效",type:"bool"},
            {key:"effect",label:"动画类型",type:"choice",options:[{label:"流光",value:"shimmer"},{label:"脉冲",value:"pulse"},{label:"消散",value:"dissolve"}]},
            {section:"特效外观与节奏",key:"color",label:"颜色",type:"color"},
            {key:"durationMode",label:"时长模式",type:"choice",options:[{label:"固定时长",value:"fixed"},{label:"自适应匀速",value:"adaptive"}]},
            {key:"adaptiveBaseTime",label:"匀速基础时间（400 px）",type:"number",min:100,max:2000,step:20,unit:"ms"},
            {key:"adaptiveTimeScale",label:"匀速时长缩放比",type:"number",min:0.25,max:3,step:0.05,decimals:2,unit:"×"},
            {key:"duration",label:"固定时长",type:"number",min:150,max:2500,step:50,unit:"ms"},
            {key:"speed",label:"速度",type:"number",min:0.25,max:3,step:0.05,decimals:2},
            {key:"intensity",label:"强度",type:"number",min:0.1,max:1,step:0.05,decimals:2},
            {key:"opacity",label:"不透明度",type:"number",min:0.05,max:1,step:0.05,decimals:2}
        ]
        function edit(p,o) { path=p; overrides=Object.assign({},o); open() }
        function update(k,v) { var o=Object.assign({},overrides); o[k]=v; overrides=o }
        onAccepted: Config.setRule(path,overrides)
        ScrollView {
            anchors.fill: parent; clip: true; contentWidth: availableWidth
            ColumnLayout {
                width: parent.width; spacing: 0
                Label { text: ruleDialog.path; color: tokens.muted; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WrapAnywhere; Layout.bottomMargin: 10 }
                Label { text: "勾选左侧框以覆盖全局设置。取消勾选即恢复继承。"; color: tokens.muted; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                SettingsGroups {
                    Layout.fillWidth: true; specifications: ruleDialog.editable; theme: tokens
                    values: Object.assign({},Config.values,{excluded:false},ruleDialog.overrides)
                    overrides: true; overrideValues: ruleDialog.overrides
                    onEdited: function(spec,value) { ruleDialog.update(spec.key,value) }
                    onOverrideToggled: function(spec,enabled) {
                        if(enabled) ruleDialog.update(spec.key,spec.key==="excluded" ? false : Config.values[spec.key])
                        else { var next=Object.assign({},ruleDialog.overrides); delete next[spec.key]; ruleDialog.overrides=next }
                    }
                }
            }
        }
    }
}
