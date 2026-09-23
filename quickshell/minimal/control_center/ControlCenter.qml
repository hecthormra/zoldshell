import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

import "../theme_switcher"
import "../services"

PanelWindow {
    id: root

    property var theme
    property bool open: false
    property string sessionId: ""

    visible: open

    anchors {
        top: true
        right: true
    }

    implicitWidth: 320
    implicitHeight: contentCol.implicitHeight + 24

    color: "transparent"

    function toggle() {
        open = !open
    }

    // =========================================================
    // SESSION ID
    // =========================================================

    Process {
        id: sessionProcess

        command: [
            "sh",
            "-c",
            "loginctl show-session \"$XDG_SESSION_ID\" -p Id --value"
        ]

        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                var id = text.trim()

                if (id !== "")
                    root.sessionId = id
            }
        }
    }

    // =========================================================
    // POWER
    // =========================================================

    Process {
        id: powerProcess

        command: [
            "loginctl",
            "poweroff"
        ]

        running: false
    }

    // =========================================================
    // REBOOT
    // =========================================================

    Process {
        id: rebootProcess

        command: [
            "loginctl",
            "reboot"
        ]

        running: false
    }

    // =========================================================
    // LOGOUT
    // =========================================================

    Process {
        id: logoutProcess

        command: [
            "loginctl",
            "terminate-session",
            root.sessionId
        ]

        running: false
    }

    // =========================================================
    // CONFIRMATION
    // =========================================================

    property string pendingAction: ""

    Rectangle {
        anchors.fill: parent

        radius: 12

        color: root.theme
            ? root.theme.bgSurface
            : "#24283b"

        border.color: root.theme
            ? root.theme.bgBorder
            : "#32364a"

        border.width: 1

        ColumnLayout {
            id: contentCol

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 12
            }

            spacing: 12

            // =================================================
            // TITLE
            // =================================================

            Text {
                text: "Control Center"

                color: root.theme
                    ? root.theme.textPrimary
                    : "#c0caf5"

                font.pixelSize: 18
                font.bold: true

                Layout.fillWidth: true
            }

            // =================================================
            // TOGGLES
            // =================================================

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                CCToggle {
                    Layout.fillWidth: true

                    icon: "󰤨"
                    label: "Wi-Fi"

                    theme: root.theme

                    activeColor: root.theme
                        ? root.theme.accentCyan
                        : "#7dcfff"

                    active: WifiService.enabled

                    onClicked: WifiService.toggle()
                }

                CCToggle {
                    Layout.fillWidth: true

                    icon: "󰂯"
                    label: "BT"

                    theme: root.theme

                    activeColor: root.theme
                        ? root.theme.accentCyan
                        : "#7dcfff"

                    active: BluetoothService.enabled

                    onClicked: BluetoothService.toggle()
                }

                CCToggle {
                    Layout.fillWidth: true

                    icon: "󰂛"
                    label: "DND"

                    theme: root.theme

                    activeColor: root.theme
                        ? root.theme.accentOrange
                        : "#ff9e64"

                    onClicked: active = !active
                }

                CCToggle {
                    Layout.fillWidth: true

                    icon: "󰌵"
                    label: "Night"

                    theme: root.theme

                    activeColor: root.theme
                        ? root.theme.accentOrange
                        : "#ff9e64"

                    active: NightService.enabled

                    onClicked: NightService.toggle()
                }
            }

            // =================================================
            // SEPARATOR
            // =================================================

            Rectangle {
                Layout.fillWidth: true
                height: 1

                color: root.theme
                    ? root.theme.bgBorder
                    : "#32364a"
            }

            // =================================================
            // VOLUME
            // =================================================

            CCSlider {
                Layout.fillWidth: true

                theme: root.theme

                icon: AudioService.muted
                    ? "󰖁"
                    : "󰕾"

                label: "Volume"

                value: AudioService.volume

                iconColor: root.theme
                    ? root.theme.accentPrimary
                    : "#7aa2f7"

                onMoved: function(v) {
                    AudioService.setVolume(v)
                }

                onIconClicked: AudioService.toggleMute()
            }

            // =================================================
            // BRIGHTNESS
            // =================================================

            CCSlider {
                Layout.fillWidth: true

                theme: root.theme

                icon: "󰃠"
                label: "Brightness"

                value: BrightnessService.brightness

                iconColor: root.theme
                    ? root.theme.accentOrange
                    : "#ff9e64"

                onMoved: function(v) {
                    BrightnessService.setBrightness(v)
                }
            }

            // =================================================
            // SEPARATOR
            // =================================================

            Rectangle {
                Layout.fillWidth: true
                height: 1

                color: root.theme
                    ? root.theme.bgBorder
                    : "#32364a"
            }

            // =================================================
            // NETWORK
            // =================================================

            CCNetworkInfo {
                Layout.fillWidth: true

                theme: root.theme
            }

            // =================================================
            // POWER BUTTONS
            // =================================================

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                CCActionButton {
                    Layout.fillWidth: true

                    theme: root.theme

                    icon: "󰐥"
                    label: "Power"

                    onClicked: {
                        root.pendingAction = "power"
                    }
                }

                CCActionButton {
                    Layout.fillWidth: true

                    theme: root.theme

                    icon: "󰜉"
                    label: "Reboot"

                    onClicked: {
                        root.pendingAction = "reboot"
                    }
                }

                CCActionButton {
                    Layout.fillWidth: true

                    theme: root.theme

                    icon: "󰍃"
                    label: "Logout"

                    onClicked: {
                        root.pendingAction = "logout"
                    }
                }
            }
        }
    }

    // =========================================================
    // CONFIRMATION OVERLAY
    // =========================================================

    Rectangle {
        visible: root.pendingAction !== ""

        anchors.fill: parent

        radius: 12

        color: root.theme
            ? root.theme.bgBase
            : "#1a1b26"

        border.color: root.theme
            ? root.theme.bgBorder
            : "#32364a"

        border.width: 1

        Column {
            anchors.centerIn: parent

            width: parent.width - 40

            spacing: 12

            Text {
                width: parent.width

                horizontalAlignment: Text.AlignHCenter

                text: {
                    if (root.pendingAction === "power")
                        return "Power off?"

                    if (root.pendingAction === "reboot")
                        return "Reboot?"

                    return "Logout?"
                }

                color: root.theme
                    ? root.theme.textPrimary
                    : "#c0caf5"

                font.pixelSize: 18
                font.bold: true
            }

            Text {
                width: parent.width

                horizontalAlignment: Text.AlignHCenter

                text: {
                    if (root.pendingAction === "power")
                        return "Turn off the computer?"

                    if (root.pendingAction === "reboot")
                        return "Restart the computer?"

                    return "End the current session?"
                }

                color: root.theme
                    ? root.theme.textSecondary
                    : "#a9b1d6"

                font.pixelSize: 13

                wrapMode: Text.WordWrap
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter

                spacing: 8

                Rectangle {
                    width: 100
                    height: 40

                    radius: 8

                    color: root.theme
                        ? root.theme.bgHover
                        : "#1e2235"

                    border.color: root.theme
                        ? root.theme.bgBorder
                        : "#32364a"

                    Text {
                        anchors.centerIn: parent

                        text: "Cancel"

                        color: root.theme
                            ? root.theme.textPrimary
                            : "#c0caf5"

                        font.pixelSize: 13
                    }

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            root.pendingAction = ""
                        }
                    }
                }

                Rectangle {
                    width: 100
                    height: 40

                    radius: 8

                    color: root.theme
                        ? root.theme.accentPrimary
                        : "#7aa2f7"

                    Text {
                        anchors.centerIn: parent

                        text: "Confirm"

                        color: root.theme
                            ? root.theme.bgBase
                            : "#1a1b26"

                        font.pixelSize: 13
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            if (root.pendingAction === "power") {
                                root.pendingAction = ""
                                powerProcess.running = true
                            }
                            else if (root.pendingAction === "reboot") {
                                root.pendingAction = ""
                                rebootProcess.running = true
                            }
                            else if (root.pendingAction === "logout") {
                                if (root.sessionId !== "") {
                                    root.pendingAction = ""
                                    logoutProcess.running = true
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // =========================================================
    // ESCAPE
    // =========================================================

    Connections {
        target: Quickshell

        function onReloadCompleted() {
            root.pendingAction = ""
        }
    }
}
