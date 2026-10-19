import QtQuick
import QtQuick.Controls.Basic

TextField {
    id: number
    property real from: 0
    property real to: 1
    property real value: 0
    property int decimals: 2
    property string label: ""
    signal edited(real value)
    Theme { id: tokens }
    selectByMouse: true; horizontalAlignment: TextInput.AlignRight
    inputMethodHints: Qt.ImhFormattedNumbersOnly
    Accessible.name: number.label+"数值"
    color: tokens.text; font.pixelSize: 12; padding: 8
    property bool dirty: false
    text: Number(number.value).toFixed(number.decimals)
    validator: DoubleValidator { bottom: number.from; top: number.to; decimals: number.decimals; notation: DoubleValidator.StandardNotation; locale: "C" }
    function restore() { dirty=false; text=Qt.binding(function() { return Number(number.value).toFixed(number.decimals) }) }
    function commit() {
        var next=Number(text)
        if(dirty && acceptableInput && text.trim().length && isFinite(next)) number.edited(next)
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
