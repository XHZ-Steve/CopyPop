import QtQuick

Item {
    id: paper
    objectName: "toast-paper"
    property bool active: false
    property real elapsed: 0
    property real duration: 460
    property color ink: "#78a7ff"
    property point lead: Qt.point(0,0)
    readonly property real progress: Math.min(1,elapsed/Math.max(1,duration))
    readonly property real spread: 1-Math.pow(1-Math.min(1,progress/0.24),3)
    readonly property real settle: 1-Math.pow(1-Math.max(0,(progress-0.24)/0.76),3)
    visible: active && progress<1
    x: lead.x; y: lead.y
    opacity: Math.min(1,progress/0.06)*(1-Math.pow(progress,3))
    Repeater {
        model: 10
        delegate: Rectangle {
            required property int index
            readonly property int side: index%2===0 ? -1 : 1
            readonly property real reach: paper.spread*(paper.width/2+12+(index%3)*9)-paper.settle*8
            width: 4+paper.spread*(20+index%3*5)-paper.settle*16+Math.min(22,Math.abs(paper.lead.x)*0.15)
            height: 3+index%3; radius: 1
            x: paper.width/2+side*reach-width/2
            y: paper.height/2+(index<5 ? -1 : 1)*(8+index%3*9)*paper.spread-height/2
            rotation: side*(12+index%3*22)*paper.spread
            color: Qt.lighter(paper.ink,1+(index%3)*0.14)
        }
    }
}
