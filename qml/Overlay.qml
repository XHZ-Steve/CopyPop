import QtQuick
import QtQuick.Controls.Basic
Item {
    id: overlay
    property var regions: []
    property var settings: Config.values
    property string kind: ""
    property real caretAlpha: 0
    property bool following: false
    signal frameTick(real seconds)
    FrameAnimation { running: overlay.following; onTriggered: overlay.frameTick(frameTime) }
    function play() {
        if(kind==="copied") { copiedToast.play(); following=true }
        else if(kind.length) caretMotion.restart()
        else layer.start()
    }
    function cancel() { following=false; layer.cancel(); caretMotion.stop(); caretAlpha = 0; copiedToast.cancel() }
    EffectLayer { id: layer; anchors.fill: parent; regions: overlay.regions; settings: overlay.settings }
    Repeater {
        model: overlay.kind.length && overlay.kind!=="copied" ? overlay.regions : []
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
    CopyToast {
        id: copiedToast
        property var region: overlay.regions.length ? overlay.regions[0] : ({x:0,y:0,w:0,h:0})
        x: region.x; y: region.y; width: region.w; height: region.h
        settings: Object.assign({},Config.values,overlay.settings)
        onRunningChanged: if(!running) overlay.following=false
    }
    SequentialAnimation {
        id: caretMotion
        NumberAnimation { target: overlay; property: "caretAlpha"; from: 0; to: 1; duration: Math.min(overlay.settings.caretFade || 180,(overlay.settings.caretDuration || 1500)/3) }
        PauseAnimation { duration: Math.max(0,(overlay.settings.caretDuration || 1500)-2*(overlay.settings.caretFade || 180)) }
        NumberAnimation { target: overlay; property: "caretAlpha"; from: 1; to: 0; duration: Math.min(overlay.settings.caretFade || 180,(overlay.settings.caretDuration || 1500)/3) }
    }
}
