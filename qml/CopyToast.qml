import QtQuick
Rectangle {
    id: toast
    objectName: "copy-toast"
    property var settings: Config.values
    property bool preview: false
    property bool running: false
    property real alpha: 1
    readonly property int naturalWidth: Math.ceil(caption.implicitWidth)+24
    readonly property int naturalHeight: Math.ceil(caption.implicitHeight)+18
    implicitWidth: naturalWidth; implicitHeight: naturalHeight
    radius: settings.fallbackRadius
    color: settings.fallbackBackgroundColor
    visible: preview || running
    opacity: settings.fallbackOpacity*(running ? alpha : 1)
    transform: Translate { y: toast.running && !toast.settings.reducedMotion ? (1-toast.alpha)*4 : 0 }
    function play() { motion.stop(); running=true; motion.start() }
    function cancel() { motion.stop(); running=false }
    SequentialAnimation {
        id: motion
        NumberAnimation { target: toast; property: "alpha"; from: 0; to: 1; duration: 130; easing.type: Easing.OutCubic }
        PauseAnimation { duration: Math.max(0,toast.settings.fallbackDuration-260) }
        NumberAnimation { target: toast; property: "alpha"; from: 1; to: 0; duration: 130; easing.type: Easing.InCubic }
        onFinished: toast.running=false
    }
    Text {
        id: caption; objectName: "copy-toast-text"
        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
        text: toast.settings.fallbackText; textFormat: Text.PlainText
        color: toast.settings.fallbackTextColor
        font.family: toast.settings.fallbackFont
        font.pixelSize: toast.settings.fallbackFontSize
        font.bold: toast.settings.fallbackBold
        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
}
