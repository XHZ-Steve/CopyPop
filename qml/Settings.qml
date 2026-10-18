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
        {title:"光标提示",subtitle:"在开始输入前，了解剪贴板的内容类型。",icon:"text-cursor-input"},
        {title:"窗口追踪",subtitle:"让动效留在它应该出现的地方。",icon:"scan-line"},
        {title:"专注保护",subtitle:"专注、演示和游戏时，自动退到幕后。",icon:"shield-check"},
        {title:"应用规则",subtitle:"为每个应用保留自己的节奏。",icon:"app-window"},
        {title:"高级",subtitle:"诊断、配置与版本信息。",icon:"sliders-horizontal"}
    ]
    property var specs: [
        [
            {key:"enabled",label:"启用 CopyPop",note:"复制特效与光标提示的总开关。",type:"bool"},
            {key:"startup",label:"开机启动",note:"登录当前 Windows 账号时在托盘中启动。",type:"bool"},
            {key:"theme",label:"外观",type:"choice",options:[{label:"跟随系统",value:"system"},{label:"浅色",value:"light"},{label:"深色",value:"dark"}]},
            {key:"closeToTray",label:"关闭后留在托盘",note:"关闭设置窗口后继续运行；可从托盘菜单退出。",type:"bool"}
        ],
        [
            {key:"effectsEnabled",label:"复制特效",note:"仅在有复制操作证据时播放。默认不播放粘贴动画。",type:"bool"},
            {key:"effect",label:"动画类型",type:"choice",options:[{label:"Shimmer · 流光",value:"shimmer"},{label:"Pulse · 脉冲",value:"pulse"},{label:"Dissolve · 消散",value:"dissolve"}]},
            {key:"adaptive",label:"自适应选区",note:"短文本水平流光，多行整体扫光，大选区轻量轮廓。",type:"bool"},
            {key:"color",label:"特效颜色",note:"支持十六进制色值，例如 #5989e8。",type:"text"},
            {key:"speed",label:"播放速度",type:"number",min:0.25,max:3,step:0.05,decimals:2,unit:"×"},
            {key:"duration",label:"基础时长",type:"number",min:150,max:2500,step:50,unit:"ms"},
            {key:"intensity",label:"强度",type:"number",min:0.1,max:1,step:0.05,decimals:2},
            {key:"opacity",label:"不透明度",type:"number",min:0.05,max:1,step:0.05,decimals:2},
            {key:"curve",label:"动画曲线",type:"choice",options:[{label:"柔和减速",value:"outCubic"},{label:"正弦缓入缓出",value:"inOutSine"},{label:"线性",value:"linear"}]},
            {key:"respectReducedMotion",label:"遵循系统动画偏好",note:"Windows 关闭动画效果时，使用短暂、低强度的脉冲。",type:"bool"}
        ],
        [
            {key:"caretEnabled",label:"显示光标提示",note:"仅限可定位的可编辑控件；密码与受保护控件自动跳过。",type:"bool"},
            {key:"caretSize",label:"图标大小",type:"number",min:14,max:48,step:1,unit:"px"},
            {key:"caretOffsetX",label:"水平偏移",type:"number",min:-80,max:80,step:1,unit:"px"},
            {key:"caretOffsetY",label:"垂直偏移",type:"number",min:-80,max:80,step:1,unit:"px"},
            {key:"caretDuration",label:"显示时长",type:"number",min:300,max:4000,step:100,unit:"ms"},
            {key:"caretFade",label:"淡入 / 淡出时长",type:"number",min:50,max:600,step:10,unit:"ms"},
            {key:"caretOpacity",label:"不透明度",type:"number",min:0.1,max:1,step:0.05,decimals:2}
        ],
        [
            {key:"hybridTracking",label:"智能混合追踪",note:"结合 UI Automation、焦点事件与短期几何快照。关闭后仅保留鼠标附近的复制反馈。",type:"bool"},
            {key:"scrollFollow",label:"精确滚动跟随",note:"按需重新查询真实选区。无法及时确认位置时取消特效。",type:"bool"},
            {key:"predictScroll",label:"短期预测跟随",note:"高级选项，默认关闭。只使用已观测的选区位移，不使用滚轮像素换算。",type:"bool"},
            {key:"dragFollow",label:"窗口拖动跟随",note:"跟随窗口坐标变化；调整大小导致文本重排时取消特效。",type:"bool"},
            {key:"dynamicZ",label:"动态窗口层级",note:"显示时置于所属窗口上方，不使用永久全局置顶。前台切换始终取消。",type:"bool"},
            {key:"clipRegion",label:"有效区域裁剪",note:"几何查询始终裁剪到控件与客户区；追踪时进一步校验可见区域。",type:"bool"}
        ],
        [
            {key:"guardFullscreen",label:"全屏自动休眠",note:"识别覆盖显示器的全屏窗口，包括无边框全屏。",type:"bool"},
            {key:"guardGames",label:"已知游戏自动排除",note:"使用内置离线路径清单。其他游戏可在应用规则中添加。",type:"bool"},
            {key:"guardPresentation",label:"演示状态自动休眠",note:"遵循 Windows 演示、忙碌及 Direct3D 全屏状态。",type:"bool"}
        ],[],
        [{key:"diagnostics",label:"本地诊断日志",note:"仅记录事件名称和时间。不会记录剪贴板内容、窗口标题或按键。日志上限约 512 KB。",type:"bool"}]
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
                    ActionButton { icon.source: "qrc:/resources/icons/copy.svg"; icon.color: tokens.accent; icon.width: 23; icon.height: 23; enabled: false; Layout.preferredWidth: 38; Layout.preferredHeight: 38; background: Rectangle { radius: 11; color: tokens.selected } }
                    Label { text: "CopyPop"; color: tokens.text; font.pixelSize: 23; font.weight: Font.DemiBold }
                }
                Repeater {
                    model: settingsWindow.pages
                    delegate: ActionButton {
                        required property var modelData; required property int index
                        Layout.fillWidth: true; Layout.preferredHeight: 44
                        text: modelData.title; icon.source: "qrc:/resources/icons/"+modelData.icon+".svg"; icon.color: settingsWindow.page===index?tokens.accent:tokens.muted; icon.width: 19; icon.height: 19
                        display: AbstractButton.TextBesideIcon
                        highlighted: settingsWindow.page===index
                        Accessible.name: modelData.title
                        onClicked: { settingsWindow.page = index; scroller.contentItem.contentY = 0 }
                        background: Rectangle { radius: 8; color: settingsWindow.page===index?tokens.selected:parent.hovered?tokens.surface:"transparent"; border.color: parent.activeFocus?tokens.accent:"transparent" }
                        contentItem: RowLayout {
                            spacing: 13
                            Item { Layout.preferredWidth: 9 }
                            ActionButton { flat: true; enabled: false; padding: 0; icon.source: "qrc:/resources/icons/"+modelData.icon+".svg"; icon.color: settingsWindow.page===index?tokens.accent:tokens.muted; icon.width: 19; icon.height: 19; Layout.preferredWidth: 20; Layout.preferredHeight: 24; background: Item {} }
                            Label { text: modelData.title; color: settingsWindow.page===index?tokens.accent:tokens.text; font.weight: settingsWindow.page===index?Font.DemiBold:Font.Normal; font.pixelSize: 14; Layout.fillWidth: true }
                        }
                    }
                }
                Item { Layout.fillHeight: true }
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 64; radius: 10; color: tokens.surface
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 12; spacing: 4
                        Label { text: App.status; color: tokens.accent; font.pixelSize: 13; font.weight: Font.DemiBold }
                        Label { text: "1.0.0 · 仅在本地运行"; color: tokens.muted; font.pixelSize: 11 }
                    }
                }
                ActionButton { text: "重新打开欢迎页"; flat: true; Layout.fillWidth: true; onClicked: App.showWelcome(); font.pixelSize: 12 }
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
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                contentWidth: availableWidth
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ColumnLayout {
                    width: scroller.availableWidth; spacing: 18
                    Preview { visible: settingsWindow.page === 1; Layout.fillWidth: true; theme: tokens }
                    RowLayout {
                        visible: settingsWindow.page === 1; Layout.fillWidth: true
                        Label { text: "主题预设"; color: tokens.muted; Layout.fillWidth: true }
                        Repeater {
                            model: [{label:"海蓝",value:"ocean"},{label:"薄荷",value:"mint"},{label:"蔷薇",value:"rose"}]
                            ActionButton { required property var modelData; text: modelData.label; highlighted: Config.values.preset===modelData.value; onClicked: App.preset(modelData.value) }
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true; implicitHeight: rowStack.implicitHeight; radius: 12; color: tokens.surface; border.color: tokens.border
                        visible: settingsWindow.specs[settingsWindow.page].length > 0
                        ColumnLayout {
                            id: rowStack; width: parent.width; spacing: 0
                            Repeater {
                                model: settingsWindow.specs[settingsWindow.page]
                                SettingRow { required property var modelData; Layout.fillWidth: true; spec: modelData; theme: tokens; onEdit: function(value) { Config.set(spec.key,value) } }
                            }
                        }
                    }
                    Rectangle {
                        visible: settingsWindow.page === 0
                        Layout.fillWidth: true; implicitHeight: languageColumn.implicitHeight+40; color: tokens.surface; radius: 12; border.color: tokens.border
                        ColumnLayout {
                            id: languageColumn; anchors.fill: parent; anchors.margins: 20; spacing: 10
                            Label { text: "语言"; color: tokens.text; font.weight: Font.Medium }
                            Label { text: "简体中文\n配置保留语言标识，后续版本将加入更多界面语言。"; color: tokens.muted; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                        }
                    }
                    Rectangle {
                        visible: settingsWindow.page === 2
                        Layout.fillWidth: true; implicitHeight: typeColumn.implicitHeight+36; radius: 12; color: tokens.surface; border.color: tokens.border
                        ColumnLayout {
                            id: typeColumn; anchors.fill: parent; anchors.margins: 18; spacing: 10
                            Label { text: "显示这些内容类型"; color: tokens.text; font.weight: Font.Medium }
                            Flow {
                                Layout.fillWidth: true; spacing: 8
                                Repeater {
                                    model: [{key:"text",name:"文本",icon:"type"},{key:"url",name:"链接",icon:"link"},{key:"image",name:"图片",icon:"image"},{key:"files",name:"文件",icon:"files"},{key:"other",name:"其他",icon:"circle-help"}]
                                    CheckBox {
                                        required property var modelData
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
                        visible: settingsWindow.page === 4; Layout.fillWidth: true; spacing: 12
                        Label { text: "手动排除"; color: tokens.text; font.weight: Font.DemiBold }
                        Label { text: App.lastApplication.length ? "最近应用："+App.lastApplication : "切换到外部应用后，可从这里将它排除。"; color: tokens.muted; wrapMode: Text.WrapAnywhere; font.pixelSize: 12; Layout.fillWidth: true }
                        RowLayout {
                            ActionButton { text: "排除最近应用"; enabled: App.lastApplication.length>0; onClicked: App.excludeRecent() }
                            ActionButton { text: "管理应用规则"; onClicked: settingsWindow.page=5 }
                        }
                        Label { text: "保护状态会隐藏全部覆盖层并停止选区查询。普通动画预设和逐应用设置不会绕过全局保护。"; color: tokens.muted; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                    }
                    ColumnLayout {
                        visible: settingsWindow.page === 5; Layout.fillWidth: true; spacing: 14
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
                        visible: settingsWindow.page === 6; Layout.fillWidth: true; spacing: 14
                        Rectangle {
                            Layout.fillWidth: true; implicitHeight: diagnosticText.implicitHeight+36; radius: 10; color: tokens.surface; border.color: tokens.border
                            Label { id: diagnosticText; anchors.fill: parent; anchors.margins: 18; text: App.diagnostics; color: tokens.muted; font.pixelSize: 12; lineHeight: 1.55; wrapMode: Text.WrapAnywhere }
                        }
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
            {key:"excluded",label:"排除此应用",type:"bool"},
            {key:"effectsEnabled",label:"复制特效",type:"bool"},
            {key:"caretEnabled",label:"光标提示",type:"bool"},
            {key:"hybridTracking",label:"智能追踪",type:"bool"},
            {key:"scrollFollow",label:"滚动跟随",type:"bool"},
            {key:"dragFollow",label:"拖动跟随",type:"bool"},
            {key:"adaptive",label:"自适应特效",type:"bool"},
            {key:"effect",label:"动画类型",type:"choice",options:[{label:"流光",value:"shimmer"},{label:"脉冲",value:"pulse"},{label:"消散",value:"dissolve"}]},
            {key:"color",label:"颜色",type:"text"},
            {key:"duration",label:"时长",type:"number",min:150,max:2500,step:50,unit:"ms"},
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
                Repeater {
                    model: ruleDialog.editable
                    RowLayout {
                        required property var modelData
                        Layout.fillWidth: true; spacing: 0
                        CheckBox {
                            checked: ruleDialog.overrides[modelData.key] !== undefined
                            Accessible.name: "覆盖"+modelData.label
                            onToggled: {
                                if(checked) ruleDialog.update(modelData.key,modelData.key==="excluded"?false:Config.values[modelData.key]);
                                else { var o=Object.assign({},ruleDialog.overrides); delete o[modelData.key]; ruleDialog.overrides=o }
                            }
                        }
                        SettingRow {
                            Layout.fillWidth: true; spec: modelData; theme: tokens
                            values: Object.assign({},Config.values,{excluded:false},ruleDialog.overrides)
                            enabled: ruleDialog.overrides[modelData.key] !== undefined
                            opacity: enabled ? 1 : 0.5
                            onEdit: function(v) { ruleDialog.update(modelData.key,v) }
                        }
                    }
                }
            }
        }
    }
}
