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
    width: 298; padding: 14; margins: 8; modal: false; focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    Component.onCompleted: { if("popupType" in picker) picker.popupType=Popup.Item }
    QtObject { id: parsed; property color value: "white" }
    function setColor(value) {
        parsed.value=value; hue=Math.max(0,parsed.value.hsvHue)*360
        saturation=parsed.value.hsvSaturation; brightness=parsed.value.hsvValue; alpha=parsed.value.a
    }
    function openFor(anchor,value) {
        setColor(value)
        var below=anchor.mapToItem(parent,0,anchor.height+6), above=anchor.mapToItem(parent,0,-height-6)
        x=Math.max(8,Math.min(parent.width-width-8,below.x+anchor.width-width))
        y=Math.max(8,Math.min(parent.height-height-8,below.y+height<parent.height-8 ? below.y : above.y)); open()
    }
    function acceptColor() { hex.commit(); accepted(selectedColor); close() }
    background: Rectangle { radius: 12; color: picker.theme.surface; border.color: picker.theme.border }
    enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 90 } }
    exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 70 } }
    contentItem: ColumnLayout {
        spacing: 12
        RowLayout {
            Layout.fillWidth: true
            Label { text: picker.title; color: picker.theme.text; font.pixelSize: 13; font.weight: Font.DemiBold; Layout.fillWidth: true }
            ActionButton { flat: true; padding: 3; Layout.preferredWidth: 24; Layout.preferredHeight: 24; icon.source: "qrc:/resources/icons/x.svg"; icon.width: 14; icon.height: 14; Accessible.name: "关闭取色面板"; onClicked: picker.close() }
        }
        GridLayout {
            columns: 8; rowSpacing: 7; columnSpacing: 7; Layout.alignment: Qt.AlignHCenter
            Repeater {
                model: ["#5989e8","#3770c9","#34a88a","#5bbdcc","#9a7dde","#d477a0","#df785e","#e1a556","#dce7fc","#c5d7ef","#bde4d6","#c5e9ec","#ddd1f4","#f2cbdc","#f3d3c9","#25334a"]
                delegate: ActionButton {
                    required property string modelData
                    Layout.preferredWidth: 26; Layout.preferredHeight: 26; padding: 0
                    Accessible.name: "使用颜色 "+modelData
                    background: Rectangle { radius: 6; color: parent.modelData; border.width: Qt.colorEqual(Qt.rgba(picker.selectedColor.r,picker.selectedColor.g,picker.selectedColor.b,1),parent.modelData) ? 2 : 0; border.color: picker.theme.text }
                    onClicked: { var keepAlpha=picker.alpha; picker.setColor(modelData); picker.alpha=keepAlpha }
                }
            }
        }
        Rectangle {
            id: plane; Layout.fillWidth: true; Layout.preferredHeight: 146
            color: Qt.hsva(picker.hue/360,1,1,1); clip: true; focus: true
            Accessible.name: "饱和度与亮度"
            Keys.onLeftPressed: picker.saturation=Math.max(0,picker.saturation-0.01)
            Keys.onRightPressed: picker.saturation=Math.min(1,picker.saturation+0.01)
            Keys.onUpPressed: picker.brightness=Math.min(1,picker.brightness+0.01)
            Keys.onDownPressed: picker.brightness=Math.max(0,picker.brightness-0.01)
            Rectangle { anchors.fill: parent; gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: "white" } GradientStop { position: 1; color: "transparent" } } }
            Rectangle { anchors.fill: parent; gradient: Gradient { GradientStop { position: 0; color: "transparent" } GradientStop { position: 1; color: "black" } } }
            Rectangle { x: picker.saturation*plane.width-6; y: (1-picker.brightness)*plane.height-6; width: 12; height: 12; radius: 6; color: "transparent"; border.width: 2; border.color: "white"; Rectangle { anchors.fill: parent; anchors.margins: 2; radius: 4; color: "transparent"; border.color: "#303030" } }
            MouseArea {
                anchors.fill: parent
                function choose(mouse) { picker.saturation=Math.max(0,Math.min(1,mouse.x/width)); picker.brightness=1-Math.max(0,Math.min(1,mouse.y/height)) }
                onPressed: function(mouse) { plane.forceActiveFocus(); choose(mouse) }
                onPositionChanged: function(mouse) { if(pressed) choose(mouse) }
            }
        }
        RowLayout {
            Layout.fillWidth: true; spacing: 8
            Slider {
                id: hueBar; Layout.fillWidth: true; Layout.preferredHeight: 36
                from: 0; to: 360; value: picker.hue; onMoved: picker.hue=value; Accessible.name: "色相"
                background: Rectangle {
                    x: hueBar.leftPadding; y: (hueBar.height-height)/2; width: hueBar.availableWidth; height: 9; radius: 4
                    gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: "#ff5050" } GradientStop { position: 0.167; color: "#ffff50" } GradientStop { position: 0.333; color: "#50ff50" } GradientStop { position: 0.5; color: "#50ffff" } GradientStop { position: 0.667; color: "#5050ff" } GradientStop { position: 0.833; color: "#ff50ff" } GradientStop { position: 1; color: "#ff5050" } }
                }
                handle: Rectangle { x: hueBar.leftPadding+hueBar.visualPosition*(hueBar.availableWidth-width); y: (hueBar.height-height)/2; width: 9; height: 17; radius: 4; color: Qt.hsva(picker.hue/360,1,1,1); border.width: 2; border.color: "white" }
            }
            NumberEntry { objectName: "popover-hue-number"; Layout.preferredWidth: 54; from: 0; to: 360; decimals: 0; value: picker.hue; label: "色相"; onEdited: function(value) { picker.hue=value } }
            Label { Layout.preferredWidth: 14; text: "°"; color: picker.theme.muted; font.pixelSize: 11 }
        }
        RowLayout {
            Layout.fillWidth: true; spacing: 8
            Slider {
                id: opacitySlider; Layout.fillWidth: true; Layout.preferredHeight: 36
                from: 0; to: 1; value: picker.alpha; onMoved: picker.alpha=value; Accessible.name: "透明度"
                background: Rectangle {
                    x: opacitySlider.leftPadding; y: (opacitySlider.height-height)/2; width: opacitySlider.availableWidth; height: 9; radius: 4; color: "#8993a1"; clip: true
                    Repeater { model: 24; Rectangle { required property int index; x: index*9; width: 4.5; height: 9; color: "#dce2eb" } }
                    Rectangle { anchors.fill: parent; radius: 4; gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: "transparent" } GradientStop { position: 1; color: Qt.rgba(picker.selectedColor.r,picker.selectedColor.g,picker.selectedColor.b,1) } } }
                }
                handle: Rectangle { x: opacitySlider.leftPadding+opacitySlider.visualPosition*(opacitySlider.availableWidth-width); y: (opacitySlider.height-height)/2; width: 9; height: 17; radius: 4; color: picker.selectedColor; border.width: 2; border.color: "white" }
            }
            NumberEntry { objectName: "popover-alpha-number"; Layout.preferredWidth: 54; from: 0; to: 100; decimals: 0; value: picker.alpha*100; label: "透明度"; onEdited: function(value) { picker.alpha=value/100 } }
            Label { Layout.preferredWidth: 14; text: "%"; color: picker.theme.muted; font.pixelSize: 11 }
        }
        RowLayout {
            Layout.fillWidth: true; spacing: 9
            Rectangle { width: 32; height: 32; radius: 7; color: picker.theme.background; Rectangle { anchors.fill: parent; radius: 7; color: picker.selectedColor; border.color: picker.theme.border } }
            TextField {
                id: hex; objectName: "popover-hex"; Layout.fillWidth: true
                text: picker.selectedColor.toString(); selectByMouse: true; maximumLength: 9
                Accessible.name: "十六进制颜色，八位为 ARGB"; color: picker.theme.text; font.pixelSize: 12
                validator: RegularExpressionValidator { regularExpression: /^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/ }
                function commit() { if(acceptableInput) picker.setColor(text); text=Qt.binding(function() { return picker.selectedColor.toString() }) }
                onEditingFinished: commit()
                background: Rectangle { radius: 7; color: picker.theme.surface; border.color: hex.activeFocus ? picker.theme.accent : picker.theme.border }
            }
        }
        RowLayout {
            Layout.alignment: Qt.AlignRight
            ActionButton { text: "取消"; onClicked: picker.close() }
            ActionButton { objectName: "popover-apply"; text: "应用颜色"; highlighted: true; onClicked: picker.acceptColor() }
        }
    }
}
