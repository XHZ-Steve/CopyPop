import QtQuick
import QtQuick.Controls.Basic
CheckBox {
    id: control
    Theme { id: tokens }
    spacing: 9; padding: 6
    font.family: "Microsoft YaHei UI"; font.pixelSize: 13
    palette.windowText: tokens.text
    indicator: Rectangle {
        implicitWidth: 21; implicitHeight: 21
        x: control.leftPadding; y: (control.height-height)/2
        radius: 6
        color: control.checked ? tokens.accent : control.hovered ? tokens.selected : tokens.surface
        border.width: control.visualFocus ? 2 : 1
        border.color: control.visualFocus || control.checked ? tokens.accent : tokens.muted
        opacity: control.enabled ? 1 : 0.45
        Behavior on color { ColorAnimation { duration: 100 } }
        ActionButton {
            anchors.fill: parent; padding: 3; enabled: false
            visible: control.checkState === Qt.Checked
            icon.source: "qrc:/resources/icons/check.svg"; icon.color: tokens.accentText
            icon.width: 15; icon.height: 15
            Accessible.ignored: true
            background: Item {}
        }
        Rectangle { visible: control.checkState === Qt.PartiallyChecked; anchors.centerIn: parent; width: 10; height: 2; radius: 1; color: tokens.text }
    }
    contentItem: Text {
        text: control.text; font: control.font; color: tokens.text
        leftPadding: control.indicator.width+control.spacing
        verticalAlignment: Text.AlignVCenter
        opacity: control.enabled ? 1 : 0.45
    }
}
