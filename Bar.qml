import QtQuick

import Quickshell

import qs.Widgets
import qs.Modules.Bar.Extras
import qs.Services.UI

Item {
    id: root

    // Plugin API (injected by PluginPanelSlot)
    property QtObject pluginApi: null
    readonly property QtObject pluginCore: pluginApi?.mainInstance

    // Required properties for bar widgets
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    readonly property string currentIcon: "tools"
    readonly property string currentLabel: "G-Helper"

    implicitWidth: pill.width
    implicitHeight: pill.height

    // https://github.com/noctalia-dev/noctalia-shell/blob/main/Modules/Bar/Extras/BarPill.qml
    BarPill {
        id: pill

        screen: root.screen
        oppositeDirection: BarService.getPillDirection(root)

        // makes the tooltip delay shorter
        forceClose: true

        icon: root.currentIcon
        tooltipText: root.pluginCore?.getTooltip() ?? ""

        onClicked: root.pluginApi?.openPanel(root.screen, this)

        onRightClicked: {
            const popupMenuWindow = PanelService.getPopupMenuWindow(root.screen);
            if (popupMenuWindow) {
                popupMenuWindow.showContextMenu(contextMenu);
                contextMenu.openAtItem(pill, root.screen);
            }
        }
    }

    // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NPopupContextMenu.qml
    NPopupContextMenu {
        id: contextMenu

        model: [
            {
                "label": root.currentLabel,
                "action": "current",
                "icon": root.currentIcon,
                "enabled": false
            },
            {
                "label": root.pluginApi?.tr("context-menu.settings"),
                "action": "widget-settings",
                "icon": "settings"
            }
        ]

        onTriggered: action => {
            var popupMenuWindow = PanelService.getPopupMenuWindow(screen);
            if (popupMenuWindow) {
                popupMenuWindow.close();
            }

            switch (action) {
                case "widget-settings":
                    BarService.openPluginSettings(screen, pluginApi.manifest);
                    break;
            }
        }
    }
}
