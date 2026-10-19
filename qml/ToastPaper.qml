import QtQuick

Item {
    id: paper
    objectName: "toast-paper"
    property bool active: false
    property real elapsed: 0
    property real duration: 460
    property color ink: "#78a7ff"
    property bool multicolor: false
    property bool inspect: false
    property point lead: Qt.point(0,0)
    readonly property real progress: Math.max(0,Math.min(1,elapsed/Math.max(1,duration)))
    readonly property real spread: 1-Math.pow(1-Math.min(1,progress/0.35),3)
    readonly property real retreat: 1-Math.pow(1-Math.max(0,(progress-0.35)/0.65),3)
    visible: active && progress<1
    x: lead.x; y: lead.y
    Repeater {
        model: 12
        delegate: Item {
            required property int index
            readonly property real reach: Math.max(paper.width*0.65,paper.height*0.75)+12+(index%3)*6
            readonly property real innerEdge: reach*paper.retreat
            readonly property real outerEdge: reach*paper.spread
            x: paper.width/2; y: paper.height/2
            rotation: index*30-15
            Rectangle {
                objectName: "paper-ray"
                x: parent.innerEdge; y: -height/2
                width: Math.max(0,parent.outerEdge-parent.innerEdge); height: 3+parent.index%3; radius: 1
                color: paper.multicolor ? ["#6ca4ff","#ef7a95","#eebc62","#55c9ab","#a78aee","#69cde0"][parent.index%6] : paper.ink
            }
            Rectangle { visible: paper.inspect; width: parent.reach; height: 1; color: "#88ff00ff" }
        }
    }
    Rectangle { visible: paper.inspect; x: paper.width/2-3; y: paper.height/2-3; width: 6; height: 6; radius: 3; color: "#ff00ff" }
}
