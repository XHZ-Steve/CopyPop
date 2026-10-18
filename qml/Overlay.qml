import QtQuick
import QtQuick.Controls.Basic
Item {
    id: overlay
    property var regions: []
    property var settings: ({})
    property string kind: ""
    property real caretAlpha: 0
    function play() { if(kind.length) { caretMotion.restart() } else layer.start() }
    function cancel() { layer.cancel(); caretMotion.stop(); caretAlpha = 0 }
    EffectLayer { id: layer; anchors.fill: parent; regions: overlay.regions; settings: overlay.settings }
    Repeater {
        model: overlay.kind.length ? overlay.regions : []
        delegate: Rectangle {
            required property var modelData
            x: modelData.x-3; y: modelData.y-3; width: modelData.w+6; height: modelData.h+6; radius: 7
            color: "#edf3ff"; border.color: "#c3d5ef"; opacity: overlay.caretAlpha * (overlay.settings.caretOpacity || 0.85)
            ActionButton {
                anchors.fill: parent; enabled: false; flat: true; padding: 5
                icon.source: "qrc:/resources/icons/" + ({text:"type",url:"link",image:"image",files:"files",other:"circle-help"}[overlay.kind] || "circle-help") + ".svg"
                icon.color: "#315fb2"; icon.width: modelData.w; icon.height: modelData.h
                background: Item {}
            }
        }
    }
    SequentialAnimation {
        id: caretMotion
        NumberAnimation { target: overlay; property: "caretAlpha"; from: 0; to: 1; duration: Math.min(overlay.settings.caretFade || 180,(overlay.settings.caretDuration || 1500)/3) }
        PauseAnimation { duration: Math.max(0,(overlay.settings.caretDuration || 1500)-2*(overlay.settings.caretFade || 180)) }
        NumberAnimation { target: overlay; property: "caretAlpha"; from: 1; to: 0; duration: Math.min(overlay.settings.caretFade || 180,(overlay.settings.caretDuration || 1500)/3) }
    }
}
