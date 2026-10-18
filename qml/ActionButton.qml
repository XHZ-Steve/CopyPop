import QtQuick
import QtQuick.Controls.Basic
Button {
    id: control
    Theme { id: tokens }
    implicitHeight: Math.max(36,contentItem.implicitHeight+16)
    implicitWidth: Math.max(80,contentItem.implicitWidth+28)
    padding: 10
    leftPadding: padding
    rightPadding: padding
    font.family: "Microsoft YaHei UI"
    font.pixelSize: 13
    icon.color: highlighted ? tokens.onAccent : tokens.text
    palette.buttonText: highlighted ? tokens.onAccent : tokens.text
    palette.highlightedText: tokens.onAccent
    background: Rectangle {
        radius: 8
        color: control.highlighted ? tokens.accent : control.down ? tokens.selected : control.hovered ? tokens.sidebar : tokens.surface
        border.width: control.activeFocus ? 2 : 1
        border.color: control.activeFocus ? tokens.accent : control.highlighted ? tokens.accent : control.flat ? "transparent" : tokens.border
        opacity: control.enabled ? 1 : 0.5
        Behavior on color { ColorAnimation { duration: 100 } }
    }
}

