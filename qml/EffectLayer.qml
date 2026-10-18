import QtQuick

Item {
    id: effect
    property var regions: []
    property var settings: Config.values
    property real progress: 1
    property bool playing: false
    property bool paused: false
    objectName: "effect-layer"
    property bool largeSelection: {
        var a = 0; for(var i=0;i<regions.length;i++) a += regions[i].w*regions[i].h;
        return a > 100000 || regions.length > 12
    }
    property string chosenEffect: settings.adaptive && largeSelection ? "pulse" : settings.effect || "shimmer"
    readonly property color ink: settings.color || "#5989e8"
    readonly property real strength: settings.intensity || 0.6
    readonly property real baseDuration: (settings.duration || 700)/(settings.speed || 1)
    signal finished()
    clip: true
    visible: playing
    function start() { motion.stop(); paused=false; progress = 0; playing = true; motion.from=0; motion.duration=baseDuration; motion.start() }
    function cancel() { motion.stop(); paused=false; playing = false }
    function togglePause() {
        if(!playing) return
        if(!paused) { paused=true; motion.pause() }
        else { paused=false; if(motion.running) motion.resume(); else { motion.from=progress; motion.duration=baseDuration*(1-progress); motion.start() } }
    }
    function seek(value) { motion.stop(); paused=true; playing=true; progress=Math.max(0,Math.min(1,value)) }
    NumberAnimation {
        id: motion; target: effect; property: "progress"; from: 0; to: 1
        duration: effect.baseDuration
        easing.type: effect.settings.curve === "linear" ? Easing.Linear : effect.settings.curve === "inOutSine" ? Easing.InOutSine : Easing.OutCubic
        onFinished: { effect.playing = false; effect.paused=false; effect.finished() }
    }
    Repeater {
        model: effect.regions
        delegate: Item {
            id: region
            required property var modelData
            required property int index
            x: modelData.x; y: modelData.y; width: Math.max(3,modelData.w); height: Math.max(3,modelData.h)
            clip: true
            opacity: (effect.settings.opacity || 0.65) * effect.ink.a * Math.sin(Math.PI * effect.progress)
            Rectangle {
                objectName: "effect-outline"
                anchors.fill: parent; radius: Math.min(effect.settings.effectRadius,height/2)
                color: Qt.rgba(effect.ink.r,effect.ink.g,effect.ink.b,effect.chosenEffect === "pulse" ? 0.05 : 0.12)
                border.width: effect.settings.effectBorder + (effect.chosenEffect === "pulse" ? 0.5 + 1.5*effect.strength*Math.pow(Math.sin(effect.progress*Math.PI*effect.settings.pulseCycles),2) : 0)
                border.color: Qt.rgba(effect.ink.r,effect.ink.g,effect.ink.b,0.65)
            }
            Rectangle {
                visible: effect.chosenEffect === "shimmer"
                objectName: "effect-shimmer"
                width: Math.max(12,region.width*effect.settings.shimmerWidth/100); height: region.height
                x: effect.regions.length > 1 && effect.settings.adaptive ? (effect.width+width)*effect.progress-width-region.x : (region.width+width)*effect.progress-width
                rotation: effect.settings.shimmerAngle
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 0.5; color: Qt.rgba(effect.ink.r,effect.ink.g,effect.ink.b,0.45+0.45*effect.strength) }
                    GradientStop { position: 1; color: "transparent" }
                }
            }
            Repeater {
                model: effect.chosenEffect === "dissolve" ? Math.min(48,Math.max(3,Math.round(region.width/100*effect.settings.dissolveDensity))) : 0
                delegate: Rectangle {
                    required property int index
                    width: 1.5 + effect.strength*2; height: width; radius: width/2; color: effect.ink
                    x: ((index*37+region.index*11)%101)/101*region.width + Math.sin(index*2.4)*effect.progress*effect.settings.dissolveTravel*0.47
                    y: region.height*(0.2+((index*17)%59)/100) - effect.progress*effect.settings.dissolveTravel*(0.25+index%6*0.15625)
                    opacity: 1-effect.progress
                }
            }
        }
    }
    Repeater {
        model: effect.settings.effectDebugBounds ? effect.regions : []
        delegate: Rectangle {
            required property var modelData
            x: modelData.x; y: modelData.y; width: modelData.w; height: modelData.h
            color: "transparent"; border.color: "#ed8b40"; border.width: 1
        }
    }
}
