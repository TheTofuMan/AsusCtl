pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Commons
import qs.Widgets
import Quickshell.Io
import qs.Services.UI
import QtQuick.Controls

Item {
    id: root

    // Plugin API (injected by PluginPanelSlot)
    property QtObject pluginApi: null
    readonly property QtObject pluginCore: pluginApi?.mainInstance

    // SmartPanel properties (required for panel behavior)
    readonly property Rectangle geometryPlaceholder: panelContainer
    readonly property bool allowAttach: true

    readonly property int contentPreferredWidth: 420 * Style.uiScaleRatio
    readonly property int contentPreferredHeight: panelContainer.implicitHeight //300 * Style.uiScaleRatio

    readonly property bool cardwireAvailable: root.pluginCore?.cardwireAvailable;

    property bool settingsVisible: false

    property int battery;

    ListModel{id:slashModes}
    ListModel{id:keyboardModes}

    anchors.fill: parent

    component IButton: Rectangle {
        id: iButton

        required property string mode

        required property bool _current

        readonly property bool _hovered: mouse.hovered

        required property string icon

        property string label

        readonly property color backgroundColor: {
            if (_hovered && enabled) {
                return Color.mHover;
            }

            return Color.mSurface;
        }

        readonly property color borderColor: {
            if (_current) {
                return Color.mPrimary;
            }

            return "transparent";
        }

        readonly property ColorAnimation animationBehaviour: ColorAnimation {
            duration: Style.animationFast
            easing.type: Easing.OutCubic
        }

        Layout.fillWidth: true
        implicitHeight: (contentRow.implicitHeight + (Style.marginL * 2)) * Style.uiScaleRatio

        radius: Style.iRadiusS
        color: backgroundColor
        border.width: Style.borderM
        border.color: borderColor

        Behavior on color {
            animation: iButton.animationBehaviour
        }

        Behavior on border.color {
            animation: iButton.animationBehaviour
        }

        ColumnLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: Style.marginXS
            Layout.fillWidth: true

            // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NIcon.qml
            NIcon {
                //anchors.horizontalCenter: parent.horizontalCenter
                Layout.alignment: Qt.AlignHCenter
                icon: iButton.icon
                pointSize: Style.fontSizeL
                color: Color.mOnSurfaceVariant

                Behavior on color {
                    animation: iButton.animationBehaviour
                }
            }

            // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NText.qml
            NText {
                text: iButton.label != "" ? iButton.label : iButton.mode
                pointSize: Style.fontSizeM
                font.weight: Style.fontWeightBold
                color: Color.mOnSurfaceVariant

                Behavior on color {
                    animation: iButton.animationBehaviour
                }
            }
        }

        HoverHandler {
            id: mouse
            enabled: true
            cursorShape: Qt.PointingHandCursor
        }
    }

    component CPUButton: IButton {
        id: cpubutton

        _current: mode == root.pluginApi.pluginSettings.currentMode

        TapHandler {
            enabled: true
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: {
                root.pluginCore?.setMode(mode)
            }
        }
    }

    component GPUButton: IButton {
        id: gpubutton

        _current: mode == root.pluginCore?.gpumode;

        TapHandler {
            enabled: true
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: root.pluginCore?.setModeGPU(gpubutton.mode)
        }
    }

    component Header: NBox {
        id: header

        Layout.fillWidth: true
        Layout.preferredHeight: headerRow.implicitHeight + Style.marginM * 2

        RowLayout {
            id: headerRow
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginM

            // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NIcon.qml
            NIcon {
                icon: root.pluginCore?.getModeIcon(pluginCore?.mode) ?? ""
                pointSize: Style.fontSizeXXL
                color: Color.mPrimary
            }

            // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NText.qml
            NText {
                Layout.fillWidth: true
                text: "G-Helper Noctalia"//root.pluginApi?.tr("gpu") ?? ""
                pointSize: Style.fontSizeL
                font.weight: Style.fontWeightBold
                color: Color.mOnSurface
            }

            // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NIconButton.qml
            NIconButton {
                icon: root.pluginCore?.getActionIcon(root.pluginCore?.pendingAction) ?? ""
                tooltipText: "Settings"
                baseSize: Style.baseWidgetSize * 0.8

                onClicked: {root.settingsVisible = root.settingsVisible == true ? false: true

                }

            }

            // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NIconButton.qml
            NIconButton {
                id: refreshButton
                icon: "settings"
                tooltipText: root.pluginApi.tr("tooltips.settings")
                baseSize: Style.baseWidgetSize * 0.8
                onClicked: BarService.openPluginSettings(screen, pluginApi.manifest)

                RotationAnimation {
                    id: rotationAnimator
                    target: refreshButton
                    property: "rotation"
                    to: 360
                    duration: 2000
                    loops: Animation.Infinite
                }
            }

            // https://github.com/noctalia-dev/noctalia-shell/blob/main/Widgets/NIconButton.qml
            NIconButton {
                icon: "close"
                tooltipText: root.pluginApi.tr("tooltips.close")
                baseSize: Style.baseWidgetSize * 0.8
                onClicked: root.pluginApi?.withCurrentScreen(screen => {
                    root.pluginApi?.closePanel(screen);
                })
            }
        }
    }

    component Battery: NBox{
        id: box
        Layout.fillWidth: true
        implicitHeight: 75 * Style.uiScaleRatio
        color: Color.mSurfaceVariant
        ColumnLayout{
            anchors {
              fill: parent
              margins: Style.marginM
            }
            NText{
                text: `Charge Limit: ${battery.value}%`
            }
            RowLayout{
                spacing: Style.marginL
                NSlider{
                    id: battery
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    stepSize: 1
                    value: {
                        root.battery
                    }
                    onPressedChanged: {
                        if(!pressed){
                            updateBattery.command = ["asusctl", "battery", "limit", value]
                            updateBattery.running = true
                        }
                    }
                    onValueChanged: {
                        if(value <= 20) {
                            value = 20
                        }
                    }
                }
                NButton{
                    text: "100%"
                    onClicked:{
                        updateBattery.command = ["asusctl", "battery", "oneshot"]
                        updateBattery.running = true
                    }
                    tooltipText: "Set Oneshot Charge Limit"
                }
            }
        }
    }

    component Settings: NBox {
        visible: root.settingsVisible

        color: Color.mSurfaceVariant

        opacity: root.settingsVisible ? 1 : 0.0
        Behavior on opacity {
            enabled: true
            NumberAnimation {
                duration: Style.animationNormal
                easing.type: Easing.OutCubic
            }
        }

        onVisibleChanged: {
            if(visible == false && root.settingsVisible){
                if(mode.currentKey == root.pluginApi?.pluginSettings.currentMode){
                    root.pluginCore?.setMode(mode.currentKey)
                }
            }
        }

        implicitWidth: settingsContent.implicitWidth + Style.marginM * 2
        implicitHeight: settingsContent.implicitHeight + Style.marginM * 2

        RowLayout{
            id: settingsContent
            spacing: Style.marginM
            anchors {
                fill: parent
                margins: Style.marginM
            }
            ColumnLayout{
                Layout.alignment: Qt.AlignTop
                Layout.margins: Style.marginS
                spacing: Style.marginM
                NTabBar{
                    Layout.fillWidth: true
                    tabHeight: 25
                    currentIndex: 0
                    distributeEvenly: false
                    NTabButton {
                        text: "CPU"
                        tabIndex: 0
                        checked: stack.currentIndex == 0
                        onClicked: stack.currentIndex = 0
                    }

                    NTabButton {
                        text: "GPU"
                        tabIndex: 1
                        checked: stack.currentIndex == 1
                        onClicked: stack.currentIndex = 1
                    }
                    NTabButton {
                        text: "Advanced"
                        tabIndex: 1
                        checked: stack.currentIndex == 2
                        onClicked: stack.currentIndex = 2
                    }
                }
                StackLayout{
                    id: stack
                    ColumnLayout{
                        spacing: Style.marginL
                        Layout.alignment: Qt.AlignTop

                        ColumnLayout{
                            spacing: Style.marginM
                            NLabel{
                                label: "CPU Boost"
                            }
                            NToggle{
                                id:boostToggle
                                Layout.fillWidth: false
                                checked: root.pluginApi?.pluginSettings[mode.currentKey]["boost"] ?? false
                                onToggled: {
                                    toggleBoost.running = true
                                }
                                Connections{
                                    target:toggleBoost
                                    function onExited(exitCode){
                                        if(exitCode == 0){
                                            boostToggle.checked = !boostToggle.checked
                                            root.pluginApi.pluginSettings = Object.assign(root.pluginApi.pluginSettings, { [mode.currentKey]: Object.assign(Object(), root.pluginApi.pluginSettings[mode.currentKey], {boost: boostToggle.checked}) })
                                            root.pluginApi.saveSettings()
                                        }
                                    }
                                }
                            }
                        }
                        ColumnLayout{
                            spacing: Style.marginM
                            NLabel{
                                label: "Power Limits"
                            }
                            ColumnLayout{
                                spacing: Style.marginS
                                ColumnLayout{
                                    NText{
                                        text: "CPU Sustained (SPL) " + spl.value + "W"
                                    }
                                    NSlider{
                                        id:spl
                                        Layout.fillWidth: true
                                        from: 1
                                        to: 80
                                        stepSize: 1
                                        value: root.pluginApi.pluginSettings[mode.currentKey]["spl"]
                                        onValueChanged: {
                                            if(parseInt(sppt.value) <= value) {
                                                sppt.value = value
                                            }
                                        }
                                    }
                                }
                                ColumnLayout{
                                    NText{
                                        text: "CPU Slow (sPPT) " + sppt.value + "W"
                                    }
                                    NSlider{
                                        id:sppt
                                        Layout.fillWidth: true
                                        from: 1
                                        to: 80
                                        stepSize: 1
                                        value: root.pluginApi.pluginSettings[mode.currentKey]["sppt"]
                                        onValueChanged:{
                                            if(parseInt(spl.value) >= value) {
                                                spl.value = value
                                            }
                                            if(parseInt(fppt.value) <= value){
                                                fppt.value = value
                                            }
                                        }
                                    }
                                }
                                ColumnLayout{
                                    NText{
                                        text: "CPU Fast (fPPT) " + fppt.value + "W"
                                    }
                                    NSlider{
                                        id:fppt
                                        Layout.fillWidth: true
                                        from: 1
                                        to: 80
                                        stepSize: 1
                                        value: root.pluginApi.pluginSettings[mode.currentKey]["fppt"]
                                        onValueChanged: {
                                            if(parseInt(sppt.value) >= value) {
                                                sppt.value = value
                                            }
                                        }
                                    }
                                }
                                NButton{
                                    text: "Apply"
                                    onClicked: {
                                        root.pluginApi.pluginSettings = Object.assign(root.pluginApi.pluginSettings, { [mode.currentKey]: Object.assign(Object(), root.pluginApi.pluginSettings[mode.currentKey], {spl: spl.value, sppt: sppt.value, fppt: fppt.value}) })
                                        root.pluginApi.saveSettings()
                                        if(mode.currentKey == root.pluginApi.pluginSettings.currentMode){

                                        }
                                    }
                                }
                            }
                        }
                    }
                    ColumnLayout{}
                    ColumnLayout{
                        visible: stack.currentIndex == 2
                        NText{
                            text: "CPU Temp Limit: " + temp.value + "°C"
                        }
                        NSlider{
                            id: temp
                            Layout.fillWidth: true
                            from: 75
                            to: 95
                            stepSize: 1
                            value: root.pluginApi.pluginSettings[mode.currentKey]["temp"] ?? 95
                        }
                        NText{
                            visible: stack.currentIndex == 2
                            text: "Offset: " + offset.value
                        }
                        NSlider{
                            id: offset
                            from: -40
                            to: 0
                            stepSize: 1
                            value: root.pluginApi.pluginSettings[mode.currentKey]["offset"] ?? 0
                            Layout.fillWidth: true
                            tooltipText: "Low values can be unstable"
                        }
                        NButton{
                            text: "Apply"
                            onClicked:{
                                changeOffset.command = ["pkexec", "sh", "-c", "ryzenadj --set-coall " + "0xfff" + parseInt(255 + offset.value).toString(16)]
                                changeOffset.running = true
                            }
                            Connections{
                                target: changeOffset
                                function onExited(exitCode){
                                    if(exitCode == 0){
                                        root.pluginApi.pluginSettings = Object.assign(root.pluginApi.pluginSettings, { [mode.currentKey]: Object.assign(Object(), root.pluginApi.pluginSettings[mode.currentKey], {offset: offset.value}) })
                                        root.pluginApi.saveSettings()
                                    }
                                }
                            }
                        }
                    }
                }
            }
            ColumnLayout{
                Layout.alignment: Qt.AlignTop
                RowLayout{
                    Layout.fillWidth: true
                    NLabel{
                        Layout.alignment: Qt.AlignLeft
                        label: "Fan Curves"
                    }
                    NComboBox{
                        id: mode
                        Layout.alignment: Qt.AlignRight
                        baseSize: 0.7
                        minimumWidth: 120
                        model: [
                            { "key": "Quiet", "name": "Quiet"},
                            { "key": "Balanced", "name": "Balanced" },
                            { "key": "Turbo", "name": "Turbo" },
                            { "key": "Custom", "name": "Custom" }
                        ]
                        currentKey: root.pluginApi?.pluginSettings.currentMode ?? "Balanced"
                        onSelected: key => {
                            currentKey = key
                            spl.value = root.pluginApi.pluginSettings[key]["spl"]
                            sppt.value = root.pluginApi.pluginSettings[key]["sppt"]
                            fppt.value = root.pluginApi.pluginSettings[key]["fppt"]
                            boostToggle.checked = root.pluginApi.pluginSettings[key]["boost"]
                        }
                    }
                }
                NBox{
                    Layout.alignment: Qt.AlignRight
                    implicitWidth: 300
                    implicitHeight: 220
                    color: Color.mShadow
                }
                NBox{
                    Layout.alignment: Qt.AlignRight
                    implicitWidth: 300
                    implicitHeight: 220
                    color: Color.mShadow
                }
            }
        }
    }

    Process {
        id: toggleBoost
        running: false
        command: ["pkexec", "sh", "-c", "echo $((($(cat /sys/devices/system/cpu/cpufreq/boost) - 1) * -1)) | tee /sys/devices/system/cpu/cpufreq/boost"]
    }

    Process {
        id: changeOffset
    }

    Process {
        id: updateBattery
        onExited: {
            getBattery.running = true
        }
    }

    Process {
        id: getBattery
        command: ["sh", "-c", "echo $(asusctl battery info) | grep -o -P '(?<=: ).*(?=%)'"]
        stdout: StdioCollector {
            onStreamFinished: {root.battery = parseInt(text.trim().toString())}
        }
    }

    Process {
        id: getSlash
        command: ["sh", "-c", "asusctl slash --list | grep -o -P '(?<=\").*(?=\")'"]
        stdout: StdioCollector {
            onStreamFinished: {
                slashModes.clear()
                text.trim().split("\n").forEach(item => {slashModes.append({name: item})})
            }
        }
    }

    Process {
        id: updateSlash
        onExited: {
            getSlash.running = true
        }
    }

    Process {
        id:getKeyboardModes
        command: ["sh", "-c", "asusctl aura effect | tail -n +3"]
        stdout: StdioCollector {
            onStreamFinished: {
                keyboardModes.clear()
                text.trim().split("\n").forEach(item => {
                    keyboardModes.append({name: item.trim()})
                })
            }
        }
    }

    Process {
        id: updateKeyboardModes
        onExited: {
            getKeyboardModes.running = true
        }
    }

    Rectangle {
        id: panelContainer
        x: Style.marginM
        y: Style.marginM
        color: Color.mShadow
        implicitHeight: main.implicitHeight + Style.marginM * 2
        //anchors.fill: parent

        Component.onCompleted: {
            getBattery.running =  true
            getSlash.running = true
            getKeyboardModes.running = true
        }

        NBox{
            id: settingsContainer
            x: parent.x - implicitWidth - Style.marginM*2
            y: parent.y - Style.marginM * 2 + parent.implicitHeight - implicitHeight
            visible: root.settingsVisible
            color: Color.mSurface
            opacity: 0.93
            implicitHeight: settings.implicitHeight + Style.marginM * 2
            implicitWidth: settings.implicitWidth + Style.marginM * 2
            MouseArea{
                anchors.fill: parent
                onClicked: {}
            }
        }

        Settings{
            id:settings
            anchors.centerIn: settingsContainer
        }

        ColumnLayout {
            id: main
            spacing: Style.marginXL
            Header {
               implicitWidth: root.contentPreferredWidth - Style.marginM*2
            }

            NBox{
                color: Color.mSurfaceVariant
                Layout.fillWidth: true
                implicitHeight: cpurow.implicitHeight + Style.marginM * 2
                ColumnLayout{
                    id: cpurow
                    spacing: Style.marginL
                    anchors {
                        fill: parent
                        margins: Style.marginM
                    }
                    NText{
                        text: "CPU Profile"
                    }
                    RowLayout {
                        spacing: Style.marginM

                        CPUButton {
                            mode: "Quiet"
                            icon: "bike"
                        }

                        CPUButton {
                            mode: "Balanced"
                            icon: "car"
                        }
                        CPUButton {
                            mode: "Turbo"
                            icon: "rocket"
                        }
                        CPUButton {
                            mode: "Custom"
                            icon: "car-fan"
                        }
                    }
                }
            }

            NBox{
                color: Color.mSurfaceVariant
                visible: root.cardwireAvailable
                Layout.fillWidth: true
                implicitHeight: gpurow.implicitHeight + Style.marginM * 2
                ColumnLayout{
                    id:gpurow
                    spacing: Style.marginL
                    anchors {
                        fill: parent
                        margins: Style.marginM
                    }
                    NText{
                        text: "GPU Mode"
                    }
                    RowLayout {
                        spacing: Style.marginM

                        GPUButton {
                            mode: "Eco"
                            icon: "leaf"
                        }
                        GPUButton {
                            mode: "Hybrid"
                            icon: "flower"
                        }
                        GPUButton {
                            mode: "Ultimate"
                            enabled: false
                            icon: "device-gamepad"
                        }
                        GPUButton {
                            mode: "Optimized"
                            enabled: false
                            icon: "bulb"
                        }
                    }
                }
            }

            NBox{
                id:slashOptions
                Layout.fillWidth: true
                implicitHeight: 75 * Style.uiScaleRatio
                color: Color.mSurfaceVariant
                ColumnLayout{
                    anchors {
                      fill: parent
                      margins: Style.marginM
                    }
                    NText{
                        text: `Slash Lighting`
                    }
                    RowLayout{
                        spacing: Style.marginS
                        // NComboBox{
                        //     minimumWidth: slashOptions.width/3 - Style.marginS*2/3 - Style.marginM*2/3
                        // }
                        // NComboBox{
                        //     minimumWidth: slashOptions.width/3 - Style.marginS*2/3 - Style.marginM*2/3
                        //     model: slashModes
                        // }
                        ComboBox{
                            Layout.fillWidth: true
                            Layout.minimumWidth: 150
                            model: slashModes
                            displayText: "Unknown"
                            onHoveredChanged:{
                                if(hovered){
                                    getSlash.running = true
                                }
                            }
                            onActivated:{
                                updateSlash.command = ["asusctl", "slash", "--mode", currentText]
                                updateSlash.running = true
                                currentValue = currentText
                                displayText = currentText
                            }
                        }
                        NSlider{
                            Layout.fillWidth: true
                            from: 0
                            to: 255
                            value: 255
                            stepSize: 1
                            tooltipText: "Brightness"
                            onPressedChanged: {
                                if(!pressed){
                                    updateSlash.command = ["asusctl", "slash", "-l", value]
                                    updateSlash.running = true
                                }
                            }
                        }
                        RowLayout{
                            NButton{
                                text: "-"
                                onClicked: {
                                    if(interval.value > 1){
                                        interval.value -= 1
                                        updateSlash.command = ["asusctl", "slash", "--interval", interval.value]
                                        updateSlash.running = true
                                    }
                                }
                                tooltipText: "Decrease Interval"
                            }
                            NText{
                                id:interval
                                property int value: 1
                                text: value
                            }
                            NButton{
                                text: "+"
                                onClicked: {
                                    if(interval.value < 5){
                                        interval.value += 1
                                        updateSlash.command = ["asusctl", "slash", "--interval", interval.value]
                                        updateSlash.running = true
                                    }
                                }
                                tooltipText: "Increase Interval"
                            }
                        }
                    }
                }
            }
            NBox{
                Layout.fillWidth: true
                implicitHeight: 75 * Style.uiScaleRatio
                color: Color.mSurfaceVariant
                ColumnLayout{
                    anchors {
                      fill: parent
                      margins: Style.marginM
                    }
                    NText{
                        text: `Keyboard`
                    }
                    RowLayout{
                        spacing: Style.marginS
                        ComboBox{
                            Layout.fillWidth: true
                            Layout.minimumWidth: 150
                            model: keyboardModes
                            displayText: {"Unknown"}
                            // onHoveredChanged:{
                            //     if(hovered){
                            //         getKeyboardModes.running = true
                            //     }
                            // }
                            onActivated:{
                                //updateKeyboardModes.command = ["asusctl", "slash", "--mode", currentText]
                                currentValue = currentText
                                displayText = currentText
                            }
                        }
                        NColorPicker{
                            Layout.fillWidth: true
                        }
                        NButton{
                            text: "Extra"
                            onClicked: Logger.e("", "Clicked")
                        }
                    }
                }
            }
            Battery{}
        }
    }
}
