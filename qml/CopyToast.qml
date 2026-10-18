import QtQuick
Rectangle {
    id: toast
    objectName: "copy-toast"
    property var settings: Config.values
    property bool preview: false
    property bool running: false
    property bool hasPlayed: false
    property real alpha: 1
    readonly property real fadeScale: Math.min(1,settings.fallbackDuration/Math.max(1,settings.fallbackFadeIn+settings.fallbackFadeOut))
    readonly property int fadeInTime: Math.round(settings.fallbackFadeIn*fadeScale)
    readonly property int fadeOutTime: Math.round(settings.fallbackFadeOut*fadeScale)
    readonly property int naturalWidth: Math.ceil(caption.implicitWidth)+24
    readonly property int naturalHeight: Math.ceil(caption.implicitHeight)+18
    implicitWidth: naturalWidth; implicitHeight: naturalHeight
    radius: settings.fallbackRadius
    color: settings.fallbackBackgroundColor
    visible: preview || running
    opacity: settings.fallbackOpacity*(hasPlayed ? alpha : 1)
    transform: Translate { y: toast.running && !toast.settings.reducedMotion ? (1-toast.alpha)*toast.settings.fallbackLift : 0 }
    function play() { motion.stop(); alpha=0; hasPlayed=true; running=true; motion.start() }
    function cancel() { motion.stop(); running=false }
    onSettingsChanged: if(preview && !running) hasPlayed=false
    SequentialAnimation {
        id: motion
        NumberAnimation { target: toast; property: "alpha"; from: 0; to: 1; duration: toast.fadeInTime; easing.type: toast.settings.fallbackFadeCurve==="linear" ? Easing.Linear : toast.settings.fallbackFadeCurve==="outCubic" ? Easing.OutCubic : Easing.InOutSine }
        PauseAnimation { duration: Math.max(0,toast.settings.fallbackDuration-toast.fadeInTime-toast.fadeOutTime) }
        NumberAnimation { target: toast; property: "alpha"; from: 1; to: 0; duration: toast.fadeOutTime; easing.type: toast.settings.fallbackFadeCurve==="linear" ? Easing.Linear : toast.settings.fallbackFadeCurve==="outCubic" ? Easing.InCubic : Easing.InOutSine }
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
