import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
Window {
    id: welcome
    width: 610; height: 660; minimumWidth: 610; minimumHeight: 660
    title: "欢迎使用 CopyPop"; color: "transparent"
    flags: Qt.Window | Qt.FramelessWindowHint
    Theme { id: tokens }
    Rectangle {
        anchors.fill: parent; radius: 18; color: tokens.background; border.color: tokens.border
        MouseArea { anchors.top: parent.top; width: parent.width-55; height: 52; onPressed: welcome.startSystemMove() }
        ActionButton { anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 12; width: 34; height: 34; flat: true; icon.source: "qrc:/resources/icons/x.svg"; icon.color: tokens.muted; Accessible.name: "关闭欢迎界面并保留托盘运行"; onClicked: welcome.close() }
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 42; anchors.topMargin: 48; spacing: 16
            ActionButton { icon.source: "qrc:/resources/icons/copy.svg"; icon.width: 30; icon.height: 30; icon.color: tokens.accent; enabled: false; Layout.preferredWidth: 64; Layout.preferredHeight: 64; background: Rectangle { color: tokens.selected; radius: 16 } }
            Label { text: "CopyPop"; color: tokens.text; font.pixelSize: 34; font.weight: Font.DemiBold }
            Label { text: "复制的瞬间，轻轻亮一下。"; color: tokens.text; font.pixelSize: 22; font.weight: Font.Medium }
            Label { text: "选中文字并复制，让流光回应你的操作。\n静静待在托盘，在专注和游戏时自动休眠。"; color: tokens.muted; font.pixelSize: 14; lineHeight: 1.35; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            Preview { Layout.fillWidth: true; Layout.topMargin: 8; theme: tokens; compact: true }
            CheckBox { text: "开机时启动 CopyPop"; checked: Config.values.startup; onToggled: Config.set("startup",checked); palette.windowText: tokens.text; palette.base: tokens.surface; palette.text: tokens.text; palette.mid: tokens.border }
            ActionButton {
                objectName: "welcome-start"
                text: "Get Started"; Layout.fillWidth: true; Layout.preferredHeight: 46; highlighted: true
                palette.highlight: tokens.accent; palette.highlightedText: tokens.accentText
                onClicked: App.finishWelcome()
            }
            Label { text: "本地运行 · 无需账号 · 不保存剪贴板历史"; color: tokens.muted; font.pixelSize: 12; Layout.alignment: Qt.AlignHCenter }
        }
    }
}
