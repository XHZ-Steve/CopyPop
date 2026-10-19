import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

RowLayout {
    id: control
    property string controlName: "numeric"
    property string label: ""
    property real from: 0
    property real to: 1
    property real stepSize: 0.05
    property int decimals: 2
    property string unit: ""
    property real value: 0
    signal edited(real value)
    spacing: 8
    Theme { id: tokens }
    StyledSlider {
        objectName: control.controlName+"-slider"
        Layout.fillWidth: true; Layout.minimumWidth: 60
        from: control.from; to: control.to; stepSize: control.stepSize; value: control.value
        Accessible.name: control.label
        onMoved: control.edited(value)
    }
    NumberEntry {
        objectName: control.controlName+"-number"; Layout.preferredWidth: 70
        from: control.from; to: control.to; value: control.value; decimals: control.decimals; label: control.label
        onEdited: function(value) { control.edited(value) }
    }
    Label { Layout.preferredWidth: 28; Layout.minimumWidth: 28; Layout.maximumWidth: 28; text: control.unit; color: tokens.muted; font.pixelSize: 11; horizontalAlignment: Text.AlignLeft }
}
