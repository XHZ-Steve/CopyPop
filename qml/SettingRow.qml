import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Dialogs as Dialogs

Rectangle {
    id: row
    objectName: spec.key+"-row"
    required property var spec
    property var values: Config.values
    property var theme
    signal edit(var value)
    width: parent ? parent.width : 600
    implicitHeight: Math.max(76, description.implicitHeight + 30)
    color: "transparent"
    RowLayout {
        anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 24
        ColumnLayout {
            id: description
            Layout.fillWidth: true; spacing: 5
            Label { text: row.spec.label; color: row.theme.text; font.pixelSize: 14; font.weight: Font.Medium; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            Label { text: row.spec.note || ""; visible: text.length > 0; color: row.theme.muted; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap; lineHeight: 1.2 }
        }
        Switch {
            id: toggle
            objectName: row.spec.key + "-switch"
            visible: row.spec.type === "bool"
            checked: Boolean(row.values[row.spec.key])
            Accessible.name: row.spec.label
            onToggled: row.edit(checked)
            palette.highlight: row.theme.accent
            palette.dark: row.theme.muted
            indicator: Rectangle {
                implicitWidth: 44; implicitHeight: 24
                x: toggle.leftPadding; y: (toggle.height-height)/2
                radius: 12; color: toggle.checked ? row.theme.accent : row.theme.border
                border.width: toggle.activeFocus ? 2 : 0; border.color: row.theme.text
                Rectangle { x: toggle.checked ? 23 : 3; y: 3; width: 18; height: 18; radius: 9; color: "#ffffff"; Behavior on x { NumberAnimation { duration: 100 } } }
            }
        }
        StyledComboBox {
            id: chooser
            objectName: row.spec.key + "-combo"
            visible: row.spec.type === "choice"
            Layout.preferredWidth: 158
            model: row.spec.options || []
            textRole: "label"; valueRole: "value"
            currentIndex: { var opts = row.spec.options || []; for(var i=0;i<opts.length;i++) if(opts[i].value === row.values[row.spec.key]) return i; return 0 }
            Accessible.name: row.spec.label
            onActivated: row.edit(currentValue)
        }
        RowLayout {
            visible: row.spec.type === "number"
            Layout.preferredWidth: 204; Layout.maximumWidth: 204; spacing: 8
            StyledSlider {
                objectName: row.spec.key + "-slider"
                Layout.fillWidth: true
                from: row.spec.min || 0; to: row.spec.max || 1; stepSize: row.spec.step || 0.05
                value: Number(row.values[row.spec.key] || 0)
                Accessible.name: row.spec.label
                onMoved: row.edit(value)
            }
            Label { Layout.preferredWidth: 47; horizontalAlignment: Text.AlignRight; color: row.theme.muted; text: Number(row.values[row.spec.key]).toFixed(row.spec.decimals || 0) + (row.spec.unit || ""); font.pixelSize: 12 }
        }
        TextField {
            id: entry
            objectName: row.spec.key + "-text"
            visible: row.spec.type === "text"
            Layout.preferredWidth: 158
            text: String(row.values[row.spec.key] || "")
            Accessible.name: row.spec.label
            selectByMouse: true
            maximumLength: row.spec.maxLength || 32
            onEditingFinished: row.edit(text)
            color: row.theme.text; font.family: "Microsoft YaHei UI"; font.pixelSize: 12
            background: Rectangle { implicitHeight: 36; radius: 7; color: row.theme.surface; border.width: entry.activeFocus ? 2 : 1; border.color: entry.activeFocus ? row.theme.accent : row.theme.border }
        }
        RowLayout {
            visible: row.spec.type === "color"
            Layout.preferredWidth: 204; Layout.maximumWidth: 204; spacing: 8
            ActionButton {
                objectName: row.spec.key+"-picker"
                Layout.preferredWidth: 42; Layout.preferredHeight: 38
                Accessible.name: "选择"+row.spec.label
                onClicked: { colorDialog.selectedColor=String(row.values[row.spec.key]); colorDialog.open() }
                contentItem: Rectangle { radius: 5; color: String(row.values[row.spec.key]); border.color: row.theme.border }
            }
            TextField {
                objectName: row.spec.key+"-hex"
                Layout.fillWidth: true; text: String(row.values[row.spec.key]); maximumLength: 16; selectByMouse: true
                Accessible.name: row.spec.label+"色值"
                color: row.theme.text; font.pixelSize: 12; leftPadding: 10
                onEditingFinished: row.edit(text)
                background: Rectangle { implicitHeight: 38; radius: 8; color: row.theme.surface; border.color: parent.activeFocus ? row.theme.accent : row.theme.border }
            }
        }
        StyledComboBox {
            visible: row.spec.type === "font"
            Layout.preferredWidth: 204
            objectName: row.spec.key+"-font-picker"
            model: row.spec.type === "font" ? Qt.fontFamilies() : []
            currentIndex: model.indexOf(String(row.values[row.spec.key]))
            Accessible.name: "选择"+row.spec.label
            onActivated: row.edit(currentText)
        }
    }
    Dialogs.ColorDialog {
        id: colorDialog; objectName: row.spec.key+"-color-dialog"
        title: "选择"+row.spec.label
        options: Dialogs.ColorDialog.ShowAlphaChannel
        onAccepted: row.edit(selectedColor.toString())
    }
    Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; anchors.leftMargin: 20; anchors.rightMargin: 20; height: 1; color: row.theme.border; opacity: 0.55 }
}
