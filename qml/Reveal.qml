import QtQuick
import QtQuick.Layouts

Item {
    id: reveal
    default property alias content: body.data
    property bool expanded: false
    property bool animate: !App.reducedMotion
    property bool ready: false
    property real fraction: expanded ? 1 : 0
    signal collapsing()
    implicitHeight: body.implicitHeight*fraction
    visible: expanded || fraction>0
    enabled: expanded
    clip: true
    Component.onCompleted: ready=true
    onExpandedChanged: if(!expanded && ready) collapsing()
    Behavior on fraction { enabled: reveal.ready && reveal.animate; NumberAnimation { duration: 190; easing.type: Easing.InOutCubic } }
    property ColumnLayout body: ColumnLayout { id: body; parent: reveal; width: reveal.width; spacing: 0; opacity: reveal.fraction }
}
