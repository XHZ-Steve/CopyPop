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
    TextField {
        id: number
        objectName: control.controlName+"-number"
        Layout.preferredWidth: 70
        selectByMouse: true; horizontalAlignment: TextInput.AlignRight
        inputMethodHints: Qt.ImhFormattedNumbersOnly
        Accessible.name: control.label+"数值"
        color: tokens.text; font.pixelSize: 12; padding: 8
        property bool dirty: false
        text: Number(control.value).toFixed(control.decimals)
        validator: DoubleValidator { bottom: control.from; top: control.to; decimals: control.decimals; notation: DoubleValidator.StandardNotation; locale: "C" }
        function restore() { dirty=false; text=Qt.binding(function() { return Number(control.value).toFixed(control.decimals) }) }
        function commit() {
            var next=Number(text)
            if(dirty && acceptableInput && text.trim().length && isFinite(next)) control.edited(next)
            restore()
        }
        onTextEdited: dirty=true
        onEditingFinished: commit()
        onActiveFocusChanged: if(!activeFocus) commit()
        Keys.onEscapePressed: function(event) { restore(); focus=false; event.accepted=false }
        background: Rectangle {
            implicitHeight: 36; radius: 7; color: tokens.surface
            border.width: number.activeFocus ? 2 : 1
            border.color: number.activeFocus ? (number.acceptableInput ? tokens.accent : "#cf6659") : tokens.border
        }
    }
    Label { visible: control.unit.length>0; text: control.unit; color: tokens.muted; font.pixelSize: 11 }
}
