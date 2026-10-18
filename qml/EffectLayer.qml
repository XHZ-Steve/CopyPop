import QtQuick

Item {
    id: effect
    property var regions: []
    property var settings: Config.values
    property real progress: 1
    property bool playing: false
    property bool largeSelection: {
        var a = 0; for(var i=0;i<regions.length;i++) a += regions[i].w*regions[i].h;
        return a > 100000 || regions.length > 12
    }
    property string chosenEffect: settings.adaptive && largeSelection ? "pulse" : settings.effect || "shimmer"
    readonly property color ink: settings.color || "#5989e8"
    readonly property real strength: settings.intensity || 0.6
    signal finished()
    clip: true
    visible: playing
    function start() { motion.stop(); progress = 0; playing = true; motion.start() }
    function cancel() { motion.stop(); playing = false }
    NumberAnimation {
        id: motion; target: effect; property: "progress"; from: 0; to: 1
        duration: (effect.settings.duration || 700) / (effect.settings.speed || 1)
        easing.type: effect.settings.curve === "linear" ? Easing.Linear : effect.settings.curve === "inOutSine" ? Easing.InOutSine : Easing.OutCubic
        onFinished: { effect.playing = false; effect.finished() }
    }
    Repeater {
        model: effect.regions
        delegate: Item {
            id: region
            required property var modelData
            required property int index
            x: modelData.x; y: modelData.y; width: Math.max(3,modelData.w); height: Math.max(3,modelData.h)
            clip: true
            opacity: (effect.settings.opacity || 0.65) * Math.sin(Math.PI * effect.progress)
            Rectangle {
                anchors.fill: parent; radius: Math.min(4,height/3)
                color: Qt.rgba(effect.ink.r,effect.ink.g,effect.ink.b,effect.chosenEffect === "pulse" ? 0.05 : 0.12)
                border.width: effect.chosenEffect === "pulse" ? 1.2 + 1.5*effect.strength*Math.sin(effect.progress*Math.PI*2)*Math.sin(effect.progress*Math.PI*2) : 0.7
                border.color: Qt.rgba(effect.ink.r,effect.ink.g,effect.ink.b,0.65)
            }
            Rectangle {
                visible: effect.chosenEffect === "shimmer"
                width: Math.max(36,Math.min(180,region.width*0.4)); height: region.height
                x: effect.regions.length > 1 && effect.settings.adaptive ? (effect.width+width)*effect.progress-width-region.x : (region.width+width)*effect.progress-width
                rotation: -10
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 0.5; color: Qt.rgba(effect.ink.r,effect.ink.g,effect.ink.b,0.45+0.45*effect.strength) }
                    GradientStop { position: 1; color: "transparent" }
                }
            }
            Repeater {
                model: effect.chosenEffect === "dissolve" ? Math.min(24,Math.max(5,Math.round(region.width/12))) : 0
                delegate: Rectangle {
                    required property int index
                    width: 1.5 + effect.strength*2; height: width; radius: width/2; color: effect.ink
                    x: ((index*37+region.index*11)%101)/101*region.width + Math.sin(index*2.4)*effect.progress*15
                    y: region.height*(0.2+((index*17)%59)/100) - effect.progress*(8+index%6*5)
                    opacity: 1-effect.progress
                }
            }
        }
    }
}

