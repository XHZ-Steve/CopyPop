import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
Rectangle {
    id: preview
    objectName: "live-preview"
    property var theme
    property bool compact: false
    implicitHeight: compact ? 160 : 280
    radius: 12; color: theme.surface; border.color: theme.border
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 22; spacing: 12
        RowLayout {
            Layout.fillWidth: true
            Label { text: "试着复制一下"; color: preview.theme.text; font.weight: Font.DemiBold; font.pixelSize: 15; Layout.fillWidth: true }
            Label { text: "Ctrl + C"; color: preview.theme.muted; font.pixelSize: 12 }
        }
        Item {
            id: sampleArea
            Layout.fillWidth: true; Layout.fillHeight: true
            TextEdit {
                id: sample; anchors.fill: parent; text: "灵感值得被看见。\nA little delight in every copy."; selectByMouse: true; readOnly: true
                color: preview.theme.text; font.family: "Microsoft YaHei UI"; font.pixelSize: 18; wrapMode: TextEdit.Wrap
                selectionColor: preview.theme.selected; selectedTextColor: preview.theme.text
                Accessible.name: "可选择并复制的示例文本"
                Keys.onPressed: function(event) {
                    if(event.matches(StandardKey.Copy) && selectedText.length) { copy(); preview.play(); event.accepted = true }
                }
                onSelectedTextChanged: if(selectedText.length === 0) actual.cancel()
            }
            EffectLayer { id: actual; anchors.fill: parent; regions: [{x:0,y:0,w:Math.min(sampleArea.width,310),h:28},{x:0,y:30,w:Math.min(sampleArea.width,275),h:28}]; settings: Config.values }
        }
        RowLayout {
            visible: !preview.compact; Layout.fillWidth: true
            ActionButton { text: "播放预览"; onClicked: preview.play(); Accessible.name: "播放当前动画设置" }
            ActionButton { objectName: "effect-pause"; text: actual.paused ? "继续" : "暂停"; enabled: actual.playing; onClicked: actual.togglePause() }
            Label { text: actual.chosenEffect+" · "+actual.regions.length+" 段选区 · "+Math.round(actual.baseDuration)+" ms"; color: preview.theme.muted; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
        }
        RowLayout {
            visible: !preview.compact; Layout.fillWidth: true
            StyledSlider { objectName: "effect-timeline"; Layout.fillWidth: true; from: 0; to: 1; stepSize: 0.001; value: actual.progress; onMoved: actual.seek(value); Accessible.name: "拖动检查特效进度" }
            Label { text: Math.round(actual.progress*100)+"%"; color: preview.theme.muted; font.pixelSize: 12; Layout.preferredWidth: 36; horizontalAlignment: Text.AlignRight }
        }
    }
    function play() {
        if(sample.selectionStart === sample.selectionEnd) sample.selectAll();
        var regions = [];
        var start = sample.selectionStart, end = sample.selectionEnd;
        var lineStart = sample.positionToRectangle(start);
        var last = lineStart;
        for(var i=start;i<end;i++) {
            var next = sample.positionToRectangle(i+1);
            if(next.y !== last.y) {
                if(last.x > lineStart.x) regions.push({x:lineStart.x,y:lineStart.y,w:last.x-lineStart.x,h:lineStart.height});
                lineStart=next;
            }
            last=next;
        }
        if(last.x > lineStart.x) regions.push({x:lineStart.x,y:lineStart.y,w:last.x-lineStart.x,h:lineStart.height});
        actual.regions=regions;
        actual.start();
    }
}
