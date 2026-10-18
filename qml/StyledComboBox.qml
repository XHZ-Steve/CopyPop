import QtQuick
import QtQuick.Controls.Basic
ComboBox {
    id: control
    Theme { id: tokens }
    implicitHeight: 38; implicitWidth: 164
    font.family: "Microsoft YaHei UI"; font.pixelSize: 12
    leftPadding: 12; rightPadding: 34
    background: Rectangle {
        radius: 8; color: control.down ? tokens.selected : control.hovered ? tokens.sidebar : tokens.surface
        border.width: control.visualFocus ? 2 : 1
        border.color: control.visualFocus || control.popup.visible ? tokens.accent : tokens.border
        Behavior on color { ColorAnimation { duration: 100 } }
    }
    contentItem: Text { text: control.displayText; font: control.font; color: tokens.text; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
    indicator: ActionButton {
        x: control.width-30; y: (control.height-height)/2; width: 24; height: 24; padding: 3; enabled: false
        icon.source: "qrc:/resources/icons/chevron-down.svg"; icon.color: tokens.muted
        rotation: control.popup.visible ? 180 : 0
        Behavior on rotation { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        background: Item {}
        Accessible.ignored: true
    }
    delegate: ItemDelegate {
        required property int index
        width: control.popup.availableWidth; height: 36
        highlighted: control.highlightedIndex === index
        contentItem: Text { text: control.textAt(index); color: control.currentIndex===index ? tokens.accent : tokens.text; font: control.font; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
        background: Rectangle { radius: 6; color: parent.highlighted ? tokens.selected : "transparent" }
    }
    popup: Popup {
        margins: 8
        y: control.height+6; width: control.width
        padding: 6; implicitHeight: Math.min(contentItem.implicitHeight+12,270)
        contentItem: ListView {
            clip: true; implicitHeight: contentHeight
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            boundsBehavior: Flickable.StopAtBounds
            ScrollIndicator.vertical: ScrollIndicator {}
        }
        background: Rectangle { radius: 10; color: tokens.surface; border.color: tokens.border }
        enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 100 } }
        exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 80 } }
    }
}
