import QtQuick
import Quickshell.Io

import qs.Services.UI
import QtQml
import qs.Commons

Item {
    id: root

    property QtObject pluginApi: null
    readonly property string pluginId: pluginApi?.pluginId
    readonly property string pluginVersion: pluginApi?.manifest.version ?? "???"
    property var settings: root.pluginApi?.pluginSettings

    readonly property QtObject pluginSettings: QtObject {
        readonly property var _manifest: root.pluginApi?.manifest.metadata.defaultSettings ?? {}
        readonly property var _user: root.pluginApi?.pluginSettings ?? {}

        property bool debug: _user.debug ?? _manifest.debug ?? false

        // rog-control-center
        readonly property QtObject rogcc: QtObject {
            readonly property var _manifest: root.pluginApi?.manifest.metadata.defaultSettings.rogcc ?? {}
            readonly property var _user: root.pluginApi?.pluginSettings.rogcc ?? {}

            property bool listenToNotifications: _user.listenToNotifications ?? _manifest.listenToNotifications ?? false
        }

        readonly property QtObject supergfxctl: QtObject {
            readonly property var _manifest: root.pluginApi?.manifest.metadata.defaultSettings.supergfxctl ?? {}
            readonly property var _user: root.pluginApi?.pluginSettings.supergfxctl ?? {}

            property bool patchPending: _user.patchPending ?? _manifest.patchPending ?? true
            property bool polling: _user.polling ?? _manifest.polling ?? false
            property int pollingInterval: _user.pollingInterval ?? _manifest.pollingInterval ?? 3000
        }
    }

    property string gpumode
    property bool cardwireAvailable: false
    property bool ryzenadjNoPass: false
    property bool boostWritable: false

    Component.onCompleted: {
        root.checkWrite.exited.connect(() => root.checkryzenadj.running = true)
        root.checkryzenadj.exited.connect(() => {setMode(settings.currentMode)})
        root.getGPU.running = true;
        root.checkWrite.running = true;
    }

    function getTooltip(): string {
        return `CPU mode: ${settings.currentMode}
        GPU mode: ${gpumode}`
    }

    IpcHandler {
        target: "plugin:asusprofiles"

        function openSettings() {
            if (root.pluginApi) {
                root.pluginApi.withCurrentScreen(screen => {
                    BarService.openPluginSettings(screen, pluginApi.manifest);
                });
            }
        }
        function openPanel() {
            if (root.pluginApi) {
                root.pluginApi.withCurrentScreen(screen => {
                    root.pluginApi.togglePanel(screen, root.pluginApi.barWidget);
                });
            }
        }
    }

    property Process setModeProc: Process {}

    readonly property Process getGPU: Process {
        id: getgpu
        running: false
        command: ["sh", "-c", " echo $(cardwire get) | grep -o -P '(?<=Mode: ).*$'"]
        stdout: StdioCollector {
            onStreamFinished: root.gpumode = text.trim()
        }
        onExited: exitCode => {
            root.cardwireAvailable = exitCode !== 0 ? false : true;
        }
    }

    readonly property Process checkryzenadj: Process{
        command: ["sudo", "-k", "-n", "ryzenadj", "-i"]
        onExited: exitCode => {
            root.ryzenadjNoPass = exitCode == 0 ? true : false;
        }
    }

    readonly property Process checkWrite: Process{
        command: ["sh", "-c", `echo ${root.settings[root.settings["currentMode"]]["boost"] ? 1 : 0} | sudo -k -n tee /sys/devices/system/cpu/cpufreq/boost`]
        onExited: exitCode => {
            root.boostWritable = exitCode == 0 ? true : false;
        }
    }

    function setMode(mode: string): void {
        root.setModeProc.exited.connect( exitCode => {
            if(exitCode == 0){
                root.pluginApi.pluginSettings.currentMode = mode;
                root.pluginApi.saveSettings();
            }
        })
        if(root.ryzenadjNoPass && root.boostWritable){
            root.setModeProc.exec(["sh", "-c", `sudo ryzenadj -a ${settings[mode]["spl"]}000 -b ${settings[mode]["sppt"]}000 -c ${settings[mode]["fppt"]}000 --set-coall=0xfff${parseInt(255 + settings[mode]["offset"]).toString(16)} ;
                echo ${settings[mode]["boost"]} | sudo tee /sys/devices/system/cpu/cpufreq/boost`]);
        } else{
            root.setModeProc.exec(["pkexec", "sh", "-c", `ryzenadj -a ${settings[mode]["spl"]}000 -b ${settings[mode]["sppt"]}000 -c ${settings[mode]["fppt"]}000 --set-coall=0xfff${parseInt(255 + settings[mode]["offset"]).toString(16)} ;
                echo ${settings[mode]["boost"]} | tee /sys/devices/system/cpu/cpufreq/boost`]);
        }
        Logger.i(root.pluginId, "Saving settings to " + mode)
    }

    function setModeGPU(mode): void {
        root.setModeProc.exec(["cardwire", "set", mode]);
        root.getGPU.running = true;
    }
}
