import QtQuick
import QtQuick.Layouts
import qs.Widgets

RowLayout {
    id: root

    property QtObject pluginApi: null
    readonly property var pluginSettings: pluginApi?.pluginSettings
    readonly property QtObject pluginCore: pluginApi?.mainInstance

    function saveSettings(): void {
        root.pluginApi.saveSettings();
    }
}
