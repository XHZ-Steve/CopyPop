import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

ColumnLayout {
    id: groups
    property var specifications: []
    property var values: Config.values
    required property var theme
    property bool overrides: false
    property var overrideValues: ({})
    signal edited(var spec, var value)
    signal overrideToggled(var spec, bool enabled)
    spacing: 20
    readonly property var sections: {
        var result=[]
        for(var i=0;i<specifications.length;i++) {
            var spec=specifications[i]
            if(spec.section || !result.length) result.push({title:spec.section || "设置",rows:[]})
            result[result.length-1].rows.push(spec)
        }
        return result
    }
    Repeater {
        model: groups.sections
        delegate: ColumnLayout {
            required property var modelData
            Layout.fillWidth: true; spacing: 9
            Label { text: modelData.title; color: groups.theme.text; font.pixelSize: 14; font.weight: Font.DemiBold; Layout.leftMargin: 4 }
            Rectangle {
                Layout.fillWidth: true; implicitHeight: rows.implicitHeight
                radius: 12; color: groups.theme.surface; border.color: groups.theme.border
                ColumnLayout {
                    id: rows; width: parent.width; spacing: 0
                    Repeater {
                        model: modelData.rows
                        delegate: RowLayout {
                            id: row
                            required property var modelData
                            Layout.fillWidth: true; spacing: 0
                            StyledCheckBox {
                                visible: groups.overrides; Layout.leftMargin: 8
                                checked: groups.overrideValues[row.modelData.key]!==undefined
                                Accessible.name: "覆盖"+row.modelData.label
                                onToggled: groups.overrideToggled(row.modelData,checked)
                            }
                            SettingRow {
                                Layout.fillWidth: true; spec: row.modelData; theme: groups.theme; values: groups.values
                                enabled: !groups.overrides || groups.overrideValues[spec.key]!==undefined
                                opacity: enabled ? 1 : 0.5
                                onEdit: function(value) { groups.edited(spec,value) }
                            }
                        }
                    }
                }
            }
        }
    }
}
