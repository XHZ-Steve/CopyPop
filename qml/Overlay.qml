import QtQuick
import QtQuick.Controls.Basic
Item {
    id: overlay
    property var regions: []
    property var settings: Config.values
    property string kind: ""
    property real caretAlpha: 0
    property bool caretRunning: false
    property real caretStartedAt: 0
    readonly property real caretFadeScale: Math.min(1,settings.caretDuration/Math.max(1,settings.caretFadeIn+settings.caretFadeOut))
    function caretAlphaAt(time) {
        if(time>=settings.caretDuration) return 0
        var incoming=settings.caretFadeIn*caretFadeScale, outgoing=settings.caretFadeOut*caretFadeScale
        if(incoming>0 && time<incoming) return time/incoming
        if(outgoing>0 && time>settings.caretDuration-outgoing) return (settings.caretDuration-time)/outgoing
        return 1
    }
    property bool following: false
    property point paperOffset: Qt.point(0,0)
    signal frameTick(real seconds)
    FrameAnimation { running: overlay.following; onTriggered: overlay.frameTick(frameTime) }
    function play() {
        if(kind==="copied") { copiedToast.play(); following=true }
        else if(kind.length) { caretStartedAt=App.monotonicTime(); caretAlpha=caretAlphaAt(0); caretRunning=true }
        else layer.start()
    }
    function cancel() { following=false; layer.cancel(); caretRunning=false; caretAlpha = 0; copiedToast.cancel() }
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
        paperOffset: overlay.paperOffset
        settings: Object.assign({},Config.values,overlay.settings)
        onRunningChanged: if(!running) overlay.following=false
    }
    FrameAnimation {
        running: overlay.caretRunning
        onTriggered: {
            var time=App.monotonicTime()-overlay.caretStartedAt
            overlay.caretAlpha=overlay.caretAlphaAt(time)
            if(time>=overlay.settings.caretDuration) overlay.caretRunning=false
        }
    }
    DebugOverlay { anchors.fill: parent; regions: overlay.regions; kind: overlay.kind; settings: overlay.settings }
}
