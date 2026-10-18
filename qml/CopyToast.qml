import QtQuick
Rectangle {
    id: toast
    objectName: "copy-toast"
    property var settings: Config.values
    property bool preview: false
    property bool running: false
    property bool hasPlayed: false
    property real alpha: 1
    property real startedAt: 0
    property real elapsedMs: 0
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
    function ease(value,outgoing) {
        if(settings.fallbackFadeCurve==="linear") return value
        if(settings.fallbackFadeCurve==="outCubic") return outgoing ? Math.pow(value,3) : 1-Math.pow(1-value,3)
        return (1-Math.cos(Math.PI*value))/2
    }
    function alphaAt(time) {
        if(time>=settings.fallbackDuration) return 0
        if(fadeInTime>0 && time<fadeInTime) return ease(time/fadeInTime,false)
        var exitStart=settings.fallbackDuration-fadeOutTime
        if(fadeOutTime>0 && time>exitStart) return 1-ease((time-exitStart)/fadeOutTime,true)
        return 1
    }
    function play() { running=false; startedAt=App.monotonicTime(); elapsedMs=0; hasPlayed=true; alpha=alphaAt(0); running=true }
    function cancel() { running=false }
    onSettingsChanged: if(preview && !running) hasPlayed=false
    FrameAnimation {
        running: toast.running
        onTriggered: {
            // Share a monotonic elapsed timeline while native geometry and frame cadence change.
            toast.elapsedMs=App.monotonicTime()-toast.startedAt
            toast.alpha=toast.alphaAt(toast.elapsedMs)
            if(toast.elapsedMs>=toast.settings.fallbackDuration) toast.running=false
        }
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
