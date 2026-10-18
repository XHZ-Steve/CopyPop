import QtQuick
import QtQuick.Controls.Basic
Slider {
    id: control
    Theme { id: tokens }
    implicitHeight: 34; leftPadding: 9; rightPadding: 9
    background: Rectangle {
        x: control.leftPadding; y: (control.height-height)/2
        width: control.availableWidth; height: 5; radius: 2.5; color: tokens.border
        Rectangle { width: parent.width*control.visualPosition; height: parent.height; radius: parent.radius; color: tokens.accent }
    }
    handle: Rectangle {
        x: control.leftPadding+control.visualPosition*(control.availableWidth-width)
        y: (control.height-height)/2
        width: 18; height: 18; radius: 9; color: tokens.surface
        border.width: 2; border.color: tokens.accent
        Rectangle { anchors.centerIn: parent; width: 6; height: 6; radius: 3; color: tokens.accent }
        Rectangle { anchors.centerIn: parent; width: 28; height: 28; radius: 14; color: "transparent"; border.width: 3; border.color: tokens.accent; opacity: control.pressed ? 0.3 : control.hovered || control.visualFocus ? 0.16 : 0 }
    }
}
