import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import CopyPop 1.0

Rectangle {
    id: preview
    required property var theme
    implicitHeight: 260
    radius: 12; color: theme.surface; border.color: theme.border
    property real measuredHz: 0
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 20; spacing: 10
        RowLayout {
            Layout.fillWidth: true
            Label { text: "移动光标，调试跟随手感"; color: preview.theme.text; font.weight: Font.DemiBold; Layout.fillWidth: true }
            Label { text: "逐帧加速度跟随"; color: preview.theme.muted; font.pixelSize: 11 }
        }
        Item {
            id: field; Layout.fillWidth: true; Layout.fillHeight: true; clip: true
            Rectangle { anchors.fill: parent; radius: 8; color: preview.theme.background }
            MouseArea {
                id: mouse; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton
                onEntered: toast.play()
                onPositionChanged: follower.target=Qt.point(Math.max(0,Math.min(field.width-toast.width,mouseX+Config.values.fallbackOffsetX)),Math.max(0,Math.min(field.height-toast.height,mouseY+Config.values.fallbackOffsetY)))
            }
            MotionFollower {
                id: follower; objectName: "fallback-preview-follower"
                stiffness: Config.values.fallbackFollowStiffness; damping: Config.values.fallbackFollowDamping
            }
            FrameAnimation {
                running: preview.visible && (mouse.containsMouse || toast.running)
                onTriggered: {
                    if(App.reducedMotion) follower.reset(follower.target)
                    else follower.advance(frameTime)
                    preview.measuredHz=smoothFrameTime>0 ? 1/smoothFrameTime : 0
                }
            }
            CopyToast {
                id: toast; objectName: "fallback-preview"
                x: follower.position.x; y: follower.position.y
                width: Math.min(naturalWidth,field.width); height: naturalHeight
                preview: true
                settings: Object.assign({},Config.values,{reducedMotion:App.reducedMotion})
            }
            onWidthChanged: centerToast()
            onHeightChanged: centerToast()
            function centerToast() { follower.reset(Qt.point(Math.max(0,(width-toast.width)/2),Math.max(0,(height-toast.height)/2))) }
            Component.onCompleted: centerToast()
        }
        RowLayout {
            Layout.fillWidth: true
            ActionButton { text: "播放预览"; onClicked: toast.play() }
            Label { objectName: "fallback-motion-readout"; text: Math.round(preview.measuredHz)+" 帧/秒 · "+Math.round(Math.hypot(follower.velocity.x,follower.velocity.y))+" px/s"; color: preview.theme.muted; font.pixelSize: 11; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight }
        }
        Label { text: Config.values.fallbackEnabled ? "设置即时保存；淡入淡出包含在总时长内。" : "提示已关闭，仍可预览样式。"; color: preview.theme.muted; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
    }
}
