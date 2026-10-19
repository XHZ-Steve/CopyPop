import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Item {
    id: debug
    property var settings: Config.values
    property var regions: []
    property string kind: "settings"
    property bool showHud: true
    readonly property bool inspectRegions: kind==="" ? settings.debugSelectionBounds : kind==="copied" ? settings.debugToastBounds : kind!=="settings" && settings.debugCaretBounds
    property real hz: 0
    property real frameMs: 0
    property var samples: []
    readonly property var stats: App.performanceStats
    FrameAnimation {
        objectName: "debug-frame-clock"
        running: debug.visible && debug.showHud && (debug.settings.debugFrames || debug.settings.debugFrameGraph)
        onTriggered: {
            debug.hz=smoothFrameTime>0 ? 1/smoothFrameTime : 0
            debug.frameMs=frameTime*1000
            if(debug.settings.debugFrameGraph) {
                var next=debug.samples.slice(-31); next.push(debug.frameMs); debug.samples=next
            }
        }
    }
    Rectangle {
        visible: debug.settings.debugHostBounds || false
        anchors.fill: parent; color: "transparent"; border.width: 1; border.color: "#41cee8"
        Text { text: "承载区域 "+Math.round(debug.width)+" × "+Math.round(debug.height)+" DIP"; color: "#41cee8"; font.pixelSize: 10 }
    }
    Repeater {
        model: debug.inspectRegions ? debug.regions : []
        delegate: Rectangle {
            required property var modelData
            x: modelData.x; y: modelData.y; width: modelData.w; height: modelData.h
            color: "transparent"; border.width: 1.5
            border.color: debug.kind==="" ? "#ffa453" : debug.kind==="copied" ? "#61dfaa" : "#db97ff"
            Text { y: -13; text: Math.round(parent.width)+" × "+Math.round(parent.height); color: parent.border.color; font.pixelSize: 10 }
        }
    }
    Rectangle {
        objectName: "debug-monitor-hud"
        visible: debug.showHud && (debug.settings.debugProcess || debug.settings.debugFrames || debug.settings.debugFrameGraph || debug.settings.debugUia)
        anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 8
        width: Math.min(280,debug.width-16); height: readouts.implicitHeight+20
        radius: 7; color: "#ee142031"; border.color: "#6684a3"
        ColumnLayout {
            id: readouts; anchors.fill: parent; anchors.margins: 10; spacing: 5
            Text { text: "CopyPop · Debug"; color: "#b9d5ff"; font.pixelSize: 11; font.bold: true }
            Text { visible: debug.settings.debugProcess || false; text: "CPU "+Number(debug.stats.cpu).toFixed(1)+"% · 工作集 "+Number(debug.stats.memory).toFixed(1)+" MB\n私有内存 "+Number(debug.stats.privateMemory).toFixed(1)+" MB"; color: "#e0edff"; font.pixelSize: 11 }
            Text { visible: debug.settings.debugFrames || false; text: "动画帧率 "+Math.round(debug.hz)+" Hz · "+debug.frameMs.toFixed(1)+" ms"; color: "#e0edff"; font.pixelSize: 11 }
            Row {
                visible: debug.settings.debugFrameGraph || false; Layout.preferredHeight: 32; spacing: 2
                Repeater { model: debug.samples; Rectangle { required property var modelData; width: 5; height: Math.max(1,Math.min(32,modelData)); y: 32-height; color: modelData>20 ? "#ed987a" : "#75b7f5" } }
            }
            Text { visible: debug.settings.debugUia || false; text: "UIA "+debug.stats.uiaStatus+" · "+debug.stats.uiaMs+" ms\n超时 "+debug.stats.timeouts+" · 复制 "+debug.stats.copies+" · 动画 "+debug.stats.animations; color: "#e0edff"; font.pixelSize: 11 }
        }
    }
}
