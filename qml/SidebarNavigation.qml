import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
Item {
    id: navigation
    property var pages: []
    property int currentIndex: 0
    property int hoveredIndex: -1
    property int hoverPosition: currentIndex
    readonly property int rowHeight: 42
    readonly property int rowSpacing: 4
    readonly property bool animate: !App.reducedMotion
    property bool ready: false
    Component.onCompleted: { selectedFill.topEdge=currentIndex*(rowHeight+rowSpacing); selectedFill.bottomEdge=selectedFill.topEdge+rowHeight; ready=true }
    onCurrentIndexChanged: if(ready) moveSelection()
    onAnimateChanged: if(ready) moveSelection()
    function moveSelection() {
        selectionMotion.stop()
        var top=currentIndex*(rowHeight+rowSpacing), bottom=top+rowHeight
        if(!animate || !ready) { selectedFill.topEdge=top; selectedFill.bottomEdge=bottom; return }
        // Extend the leading edge first, then let the trailing edge catch up.
        extendTop.to=Math.min(selectedFill.topEdge,top)
        extendBottom.to=Math.max(selectedFill.bottomEdge,bottom)
        retractTop.to=top; retractBottom.to=bottom
        selectionMotion.start()
    }
    implicitHeight: pages.length*rowHeight+Math.max(0,pages.length-1)*rowSpacing
    signal selected(int index)
    Theme { id: tokens }
    Rectangle {
        objectName: "sidebar-hover-fill"
        width: parent.width; height: navigation.rowHeight; radius: 8
        y: navigation.hoverPosition*(navigation.rowHeight+navigation.rowSpacing)
        color: tokens.surface; opacity: navigation.hoveredIndex>=0 ? 1 : 0
        Behavior on y { enabled: navigation.animate; NumberAnimation { duration: 100; easing.type: Easing.InOutCubic } }
        Behavior on opacity { NumberAnimation { duration: navigation.animate ? 100 : 0 } }
    }
    Rectangle {
        id: selectedFill
        objectName: "sidebar-selection-fill"
        property real topEdge: navigation.currentIndex*(navigation.rowHeight+navigation.rowSpacing)
        property real bottomEdge: topEdge+navigation.rowHeight
        width: parent.width; height: Math.max(navigation.rowHeight,bottomEdge-topEdge); radius: 8
        y: topEdge
        color: tokens.selected
    }
    SequentialAnimation {
        id: selectionMotion
        ParallelAnimation {
            NumberAnimation { id: extendTop; target: selectedFill; property: "topEdge"; duration: 85; easing.type: Easing.OutCubic }
            NumberAnimation { id: extendBottom; target: selectedFill; property: "bottomEdge"; duration: 85; easing.type: Easing.OutCubic }
        }
        ParallelAnimation {
            NumberAnimation { id: retractTop; target: selectedFill; property: "topEdge"; duration: 230; easing.type: Easing.OutCubic }
            NumberAnimation { id: retractBottom; target: selectedFill; property: "bottomEdge"; duration: 230; easing.type: Easing.OutCubic }
        }
    }
    Column {
        anchors.fill: parent; spacing: navigation.rowSpacing
        Repeater {
            model: navigation.pages
            delegate: ActionButton {
                required property var modelData
                required property int index
                objectName: "sidebar-item-"+index
                width: navigation.width; height: navigation.rowHeight
                text: modelData.title
                Accessible.role: Accessible.PageTab
                Accessible.selected: navigation.currentIndex===index
                onClicked: navigation.selected(index)
                onHoveredChanged: {
                    if(hovered) { navigation.hoveredIndex=index; navigation.hoverPosition=index }
                    else if(navigation.hoveredIndex===index) navigation.hoveredIndex=-1
                }
                background: Rectangle { radius: 8; color: "transparent"; border.width: parent.visualFocus ? 2 : 0; border.color: tokens.accent }
                contentItem: RowLayout {
                    spacing: 13
                    Item { Layout.preferredWidth: 8 }
                    ActionButton {
                        enabled: false; padding: 0
                        icon.source: "qrc:/resources/icons/"+modelData.icon+".svg"
                        icon.color: navigation.currentIndex===index ? tokens.accent : tokens.muted
                        icon.width: 19; icon.height: 19
                        Layout.preferredWidth: 20; Layout.preferredHeight: 24
                        Accessible.ignored: true
                        background: Item {}
                    }
                    Label { text: modelData.title; color: navigation.currentIndex===index ? tokens.accent : tokens.text; font.pixelSize: 14; font.weight: navigation.currentIndex===index ? Font.DemiBold : Font.Normal; Layout.fillWidth: true }
                }
            }
        }
    }
}
