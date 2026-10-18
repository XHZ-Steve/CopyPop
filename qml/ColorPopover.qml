import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Popup {
    id: picker
    property var theme
    property string title: "选择颜色"
    property real hue: 0
    property real saturation: 0
    property real brightness: 1
    property real alpha: 1
    readonly property color selectedColor: Qt.hsva(hue/360,saturation,brightness,alpha)
    signal accepted(color color)
    parent: Overlay.overlay
    width: 320; padding: 16; margins: 8
    modal: false; focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    Component.onCompleted: { if("popupType" in picker) picker.popupType=Popup.Item }
    QtObject { id: parsed; property color value: "white" }
    function setColor(value) {
        parsed.value=value
        hue=Math.max(0,parsed.value.hsvHue)*360
        saturation=parsed.value.hsvSaturation; brightness=parsed.value.hsvValue; alpha=parsed.value.a
    }
    function openFor(anchor, value) {
        setColor(value)
        var below=anchor.mapToItem(parent,0,anchor.height+6)
        var above=anchor.mapToItem(parent,0,-height-6)
        x=Math.max(8,Math.min(parent.width-width-8,below.x+anchor.width-width))
        y=Math.max(8,Math.min(parent.height-height-8,below.y+height<parent.height-8 ? below.y : above.y))
        open()
    }
    function acceptColor() { accepted(selectedColor); close() }
    background: Rectangle { radius: 12; color: picker.theme.surface; border.color: picker.theme.border }
    enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 90 } }
    exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 70 } }
    contentItem: ColumnLayout {
        spacing: 9
        Label { text: picker.title; color: picker.theme.text; font.pixelSize: 14; font.weight: Font.DemiBold }
        Rectangle {
            id: plane
            Layout.fillWidth: true; Layout.preferredHeight: 130
            color: Qt.hsva(picker.hue/360,1,1,1); clip: true
            Accessible.name: "饱和度与亮度选色区域"
            Rectangle { anchors.fill: parent; gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: "white" } GradientStop { position: 1; color: "transparent" } } }
            Rectangle { anchors.fill: parent; gradient: Gradient { GradientStop { position: 0; color: "transparent" } GradientStop { position: 1; color: "black" } } }
            Rectangle { x: picker.saturation*plane.width-6; y: (1-picker.brightness)*plane.height-6; width: 12; height: 12; radius: 6; color: "transparent"; border.width: 2; border.color: "white"; Rectangle { anchors.fill: parent; anchors.margins: 2; radius: 4; color: "transparent"; border.color: "#303030" } }
            MouseArea {
                anchors.fill: parent
                function choose(mouse) { picker.saturation=Math.max(0,Math.min(1,mouse.x/width)); picker.brightness=1-Math.max(0,Math.min(1,mouse.y/height)) }
                onPressed: function(mouse) { choose(mouse) }
                onPositionChanged: function(mouse) { if(pressed) choose(mouse) }
            }
        }
        RowLayout {
            Layout.fillWidth: true; spacing: 9
            Rectangle {
                width: 38; height: 36; color: "#eeeeee"; clip: true
                Repeater { model: 20; Rectangle { required property int index; x: index%5*8; y: Math.floor(index/5)*9; width: 8; height: 9; color: (index%5+Math.floor(index/5))%2 ? "#aaaaaa" : "#eeeeee" } }
                Rectangle { anchors.fill: parent; color: picker.selectedColor; border.color: picker.theme.border }
            }
            TextField {
                id: hex; objectName: "popover-hex"
                Layout.fillWidth: true; text: picker.selectedColor.toString(); selectByMouse: true; maximumLength: 9
                Accessible.name: "十六进制颜色，八位格式为透明度加 RGB"
                color: picker.theme.text; font.pixelSize: 12
                validator: RegularExpressionValidator { regularExpression: /^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/ }
                onEditingFinished: { if(acceptableInput) picker.setColor(text); text=picker.selectedColor.toString() }
                background: Rectangle { radius: 7; color: picker.theme.surface; border.color: hex.activeFocus ? picker.theme.accent : picker.theme.border }
            }
        }
        Label { text: "色相"; color: picker.theme.muted; font.pixelSize: 12 }
        NumericSlider { Layout.fillWidth: true; controlName: "popover-hue"; label: "色相"; from: 0; to: 360; stepSize: 1; decimals: 0; unit: "°"; value: picker.hue; onEdited: function(value) { picker.hue=value } }
        Label { text: "饱和度"; color: picker.theme.muted; font.pixelSize: 12 }
        NumericSlider { Layout.fillWidth: true; controlName: "popover-saturation"; label: "饱和度"; from: 0; to: 100; stepSize: 1; decimals: 0; unit: "%"; value: picker.saturation*100; onEdited: function(value) { picker.saturation=value/100 } }
        Label { text: "亮度"; color: picker.theme.muted; font.pixelSize: 12 }
        NumericSlider { Layout.fillWidth: true; controlName: "popover-brightness"; label: "亮度"; from: 0; to: 100; stepSize: 1; decimals: 0; unit: "%"; value: picker.brightness*100; onEdited: function(value) { picker.brightness=value/100 } }
        Label { text: "透明度"; color: picker.theme.muted; font.pixelSize: 12 }
        NumericSlider { Layout.fillWidth: true; controlName: "popover-alpha"; label: "透明度"; from: 0; to: 100; stepSize: 1; decimals: 0; unit: "%"; value: picker.alpha*100; onEdited: function(value) { picker.alpha=value/100 } }
        RowLayout {
            Layout.topMargin: 3; Layout.alignment: Qt.AlignRight
            ActionButton { text: "取消"; onClicked: picker.close() }
            ActionButton { objectName: "popover-apply"; text: "应用颜色"; highlighted: true; onClicked: picker.acceptColor() }
        }
    }
}
