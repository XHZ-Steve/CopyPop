import QtQuick
QtObject {
    property SystemPalette systemPalette: SystemPalette { colorGroup: SystemPalette.Active }
    readonly property bool dark: Config.values.theme === "dark" || (Config.values.theme === "system" && systemPalette.window.hslLightness < 0.5)
    readonly property color background: dark ? "#171c25" : "#f5f7fb"
    readonly property color sidebar: dark ? "#1d2430" : "#edf1f7"
    readonly property color surface: dark ? "#222b38" : "#ffffff"
    readonly property color text: dark ? "#ecf1fa" : "#202d43"
    readonly property color muted: dark ? "#acb9cc" : "#596b83"
    readonly property color border: dark ? "#3c4a5e" : "#d7e0eb"
    readonly property color accent: dark ? "#8fb6ff" : "#315fb2"
    readonly property color selected: dark ? "#2e405c" : "#dfe9fb"
    readonly property color accentText: dark ? "#12223c" : "#ffffff"
}
