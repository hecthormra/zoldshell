import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.settings 1.0

SettingsPage {
    id: root

    title: "Rede"
    description: "Wi-Fi, Ethernet e gerenciamento das conexões."

    property bool wifiAvailable: false
    property bool wifiEnabled: false
    property bool wifiScanning: false

    property bool ethernetAvailable: false
    property bool ethernetConnected: false

    property string ethernetDevice: ""
    property string ethernetConnection: ""
    property string ethernetIp: ""
    property string ethernetGateway: ""
    property string ethernetDns: ""

    property string activeConnection: ""

    property var wifiNetworks: []

    property string wifiDevice: ""

    property string selectedSsid: ""
    property string selectedSecurity: ""
    property string selectedBssid: ""
    property string wifiPassword: ""

    property bool passwordDialogVisible: false
    property string wifiError: ""

    function refreshNetwork() {
        if (!deviceProcess.running)
            deviceProcess.running = true

        if (!wifiRadioProcess.running)
            wifiRadioProcess.running = true

        if (!activeProcess.running)
            activeProcess.running = true

        if (root.wifiAvailable &&
            root.wifiEnabled &&
            !wifiScanProcess.running)
            wifiScanProcess.running = true

        if (root.ethernetAvailable &&
            root.ethernetDevice !== "" &&
            !ethernetInfoProcess.running)
            ethernetInfoProcess.running = true
    }

    function resetNetworkState() {
        root.wifiAvailable = false
        root.wifiEnabled = false

        root.ethernetAvailable = false
        root.ethernetConnected = false

        root.ethernetDevice = ""
        root.ethernetConnection = ""
        root.ethernetIp = ""
        root.ethernetGateway = ""
        root.ethernetDns = ""

        root.wifiDevice = ""
        root.activeConnection = ""
        root.wifiNetworks = []
    }

    function toggleWifi() {
        if (!root.wifiAvailable)
            return

        wifiToggleProcess.command = [
            "nmcli",
            "radio",
            "wifi",
            root.wifiEnabled ? "off" : "on"
        ]

        wifiToggleProcess.running = true
    }

    function scanWifi() {
        if (!root.wifiAvailable ||
            !root.wifiEnabled)
            return

        if (wifiScanProcess.running)
            return

        root.wifiScanning = true
        wifiScanProcess.running = true
    }

    function connectWifi(ssid, security, bssid) {
        if (!root.wifiAvailable ||
            !root.wifiEnabled ||
            root.wifiDevice === "" ||
            ssid === "")
            return

        root.wifiError = ""

        if (security !== "") {
            root.selectedSsid = ssid
            root.selectedSecurity = security
            root.selectedBssid = bssid
            root.wifiPassword = ""
            root.passwordDialogVisible = true

            passwordPopup.open()

            return
        }

        wifiConnectProcess.command = [
            "nmcli",
            "device",
            "wifi",
            "connect",
            ssid,
            "ifname",
            root.wifiDevice
        ]

        wifiConnectProcess.running = true
    }

    function connectWifiWithPassword() {
        if (!root.wifiAvailable ||
            !root.wifiEnabled ||
            root.wifiDevice === "" ||
            root.selectedSsid === "" ||
            root.wifiPassword === "")
            return

        root.wifiError = ""

        wifiConnectProcess.command = [
            "nmcli",
            "device",
            "wifi",
            "connect",
            root.selectedSsid,
            "password",
            root.wifiPassword,
            "ifname",
            root.wifiDevice
        ]

        wifiConnectProcess.running = true
    }

    function disconnectEthernet() {
        if (!root.ethernetAvailable ||
            root.ethernetDevice === "")
            return

        ethernetDisconnectProcess.command = [
            "nmcli",
            "device",
            "disconnect",
            root.ethernetDevice
        ]

        ethernetDisconnectProcess.running = true
    }

    function connectEthernet() {
        if (!root.ethernetAvailable ||
            root.ethernetDevice === "")
            return

        ethernetConnectProcess.command = [
            "nmcli",
            "device",
            "connect",
            root.ethernetDevice
        ]

        ethernetConnectProcess.running = true
    }

    Process {
        id: deviceProcess

        command: [
            "nmcli",
            "-t",
            "-f",
            "DEVICE,TYPE,STATE,CONNECTION",
            "device"
        ]

        running: false

        stdout: SplitParser {
            onRead: data => {
                const fields = data.trim().split(":")

                if (fields.length < 4)
                    return

                const device = fields[0]
                const type = fields[1]
                const state = fields[2]
                const connection =
                    fields.slice(3).join(":")

                if (type === "ethernet") {
                    root.ethernetAvailable = true
                    root.ethernetDevice = device
                    root.ethernetConnected =
                        state === "connected"
                    root.ethernetConnection = connection
                }

                if (type === "wifi") {
                    root.wifiAvailable = true
                    root.wifiDevice = device
                }
            }
        }

        onExited: {
            if (!root.ethernetAvailable) {
                root.ethernetDevice = ""
                root.ethernetConnection = ""
                root.ethernetIp = ""
                root.ethernetGateway = ""
                root.ethernetDns = ""
            }

            if (!root.wifiAvailable) {
                root.wifiDevice = ""
                root.wifiNetworks = []
            }
        }
    }

    Process {
        id: wifiRadioProcess

        command: [
            "nmcli",
            "radio",
            "wifi"
        ]

        running: false

        stdout: SplitParser {
            onRead: data => {
                root.wifiEnabled =
                    data.trim() === "enabled"
            }
        }
    }

    Process {
        id: activeProcess

        command: [
            "nmcli",
            "-t",
            "-f",
            "GENERAL.CONNECTION",
            "device",
            "show"
        ]

        running: false

        stdout: SplitParser {
            onRead: data => {
                const value = data.trim()

                if (value !== "" &&
                    value !== "--") {
                    root.activeConnection = value
                }
            }
        }
    }

    Process {
        id: wifiToggleProcess

        command: []

        running: false

        onExited: {
            root.resetNetworkState()
            root.refreshNetwork()
        }
    }

    Process {
        id: wifiScanProcess

        command: [
            "nmcli",
            "-t",
            "-f",
            "IN-USE,SSID,BSSID,SIGNAL,SECURITY",
            "device",
            "wifi",
            "list",
            "--rescan",
            "yes"
        ]

        running: false

        stdout: SplitParser {
            onRead: data => {
                const line = data.trim()

                if (line === "")
                    return

                const fields = line.split(":")

                if (fields.length < 5)
                    return

                const inUse = fields[0]
                const ssid = fields[1]
                const bssid = fields[2]
                const signal = fields[3]
                const security =
                    fields.slice(4).join(":")

                if (ssid === "")
                    return

                for (let i = 0;
                     i < root.wifiNetworks.length;
                     i++) {

                    if (root.wifiNetworks[i].ssid === ssid) {
                        if (inUse === "*")
                            root.wifiNetworks[i].inUse = true

                        return
                    }
                }

                root.wifiNetworks.push({
                    ssid: ssid,
                    bssid: bssid,
                    signal: Number(signal),
                    security: security,
                    inUse: inUse === "*"
                })
            }
        }

        onStarted: {
            root.wifiScanning = true
            root.wifiNetworks = []
        }

        onExited: {
            root.wifiScanning = false
        }
    }

    Process {
        id: wifiConnectProcess

        command: []

        running: false

        stderr: SplitParser {
            onRead: data => {
                const error = data.trim()

                if (error !== "")
                    root.wifiError = error
            }
        }

        stdout: SplitParser {
            onRead: data => {
                const message = data.trim()

                if (message !== "")
                    console.log("nmcli:", message)
            }
        }

        onExited: {
            if (exitCode === 0) {
                root.passwordDialogVisible = false
                root.wifiPassword = ""
                root.wifiError = ""

                passwordPopup.close()

                root.resetNetworkState()
                root.refreshNetwork()
            } else {
                if (root.wifiError === "")
                    root.wifiError =
                        "Não foi possível conectar à rede."

                root.wifiPassword = ""

                passwordPopup.open()
            }
        }
    }

    Process {
        id: ethernetInfoProcess

        command: [
            "nmcli",
            "-t",
            "-f",
            "GENERAL.STATE,IP4.ADDRESS,IP4.GATEWAY,IP4.DNS",
            "device",
            "show",
            root.ethernetDevice
        ]

        running: false

        stdout: SplitParser {
            onRead: data => {
                const line = data.trim()

                if (line === "")
                    return

                const separator =
                    line.indexOf(":")

                if (separator < 0)
                    return

                const field =
                    line.substring(0, separator)

                const value =
                    line.substring(separator + 1)

                if (field === "IP4.ADDRESS[1]")
                    root.ethernetIp = value

                else if (field === "IP4.GATEWAY")
                    root.ethernetGateway = value

                else if (field === "IP4.DNS[1]")
                    root.ethernetDns = value
            }
        }
    }

    Process {
        id: ethernetDisconnectProcess

        command: []

        running: false

        onExited: {
            root.resetNetworkState()
            root.refreshNetwork()
        }
    }

    Process {
        id: ethernetConnectProcess

        command: []

        running: false

        onExited: {
            root.resetNetworkState()
            root.refreshNetwork()
        }
    }

    Timer {
        interval: 2500
        repeat: true
        running: root.visible

        onTriggered: {
            root.resetNetworkState()
            root.refreshNetwork()
        }
    }

    Component.onCompleted: {
        root.refreshNetwork()
    }

    ColumnLayout {
        Layout.fillWidth: true

        spacing: 12

        Text {
            text: "WI-FI"

            color: root.theme.textSecondary
            font.family: "JetBrains Mono Nerd Font"
            font.pixelSize: 10
            font.bold: true

            Layout.fillWidth: true
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 64

            radius: 10

            color: root.wifiAvailable
                   ? root.theme.bgSurface
                   : root.theme.bgHover

            border.width: 1
            border.color: root.theme.bgBorder

            opacity: root.wifiAvailable ? 1.0 : 0.55

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14

                spacing: 12

                Text {
                    text: "󰤨"

                    color: root.wifiAvailable
                           ? root.theme.textPrimary
                           : root.theme.textMuted

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 22
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Wi-Fi"

                        color: root.wifiAvailable
                               ? root.theme.textPrimary
                               : root.theme.textMuted

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    Text {
                        text: root.wifiAvailable
                              ? (root.wifiEnabled
                                 ? "Ativado"
                                 : "Desativado")
                              : "Nenhuma interface Wi-Fi detectada"

                        color: root.wifiAvailable
                               ? root.theme.textSecondary
                               : root.theme.textMuted

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 10
                    }
                }

                Rectangle {
                    visible: root.wifiAvailable

                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 24

                    radius: 12

                    color: root.wifiEnabled
                           ? root.theme.bgSelected
                           : root.theme.bgHover

                    Rectangle {
                        width: 18
                        height: 18

                        radius: 9

                        anchors.verticalCenter: parent.verticalCenter

                        x: root.wifiEnabled
                           ? parent.width - width - 3
                           : 3

                        color: root.wifiEnabled
                               ? root.theme.accentPrimary
                               : root.theme.textMuted

                        Behavior on x {
                            NumberAnimation {
                                duration: 120
                            }
                        }
                    }

                    TapHandler {
                        onTapped: root.toggleWifi()
                    }
                }

                Text {
                    visible: !root.wifiAvailable

                    text: "󰌙"

                    color: root.theme.textMuted
                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 18
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 64

            radius: 10

            color: root.wifiAvailable &&
                   root.wifiEnabled
                   ? root.theme.bgSurface
                   : root.theme.bgHover

            border.width: 1
            border.color: root.theme.bgBorder

            opacity: root.wifiAvailable &&
                     root.wifiEnabled
                     ? 1.0
                     : 0.45

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14

                spacing: 12

                Text {
                    text: "󰤨"

                    color: root.wifiAvailable &&
                           root.wifiEnabled
                           ? root.theme.textPrimary
                           : root.theme.textMuted

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 22
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Redes Wi-Fi"

                        color: root.wifiAvailable &&
                               root.wifiEnabled
                               ? root.theme.textPrimary
                               : root.theme.textMuted

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 12
                    }

                    Text {
                        text: root.wifiScanning
                              ? "Procurando redes..."
                              : root.wifiAvailable &&
                                root.wifiEnabled
                                ? "Procurar redes disponíveis"
                                : "Indisponível"

                        color: root.theme.textSecondary
                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 10
                    }
                }

                Text {
                    text: root.wifiScanning
                          ? "󰑓"
                          : "󰁔"

                    color: root.wifiAvailable &&
                           root.wifiEnabled
                           ? root.theme.accentPrimary
                           : root.theme.textMuted

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 20
                }

                TapHandler {
                    enabled: root.wifiAvailable &&
                             root.wifiEnabled

                    onTapped: root.scanWifi()
                }
            }
        }

        ColumnLayout {
            visible: root.wifiAvailable &&
                     root.wifiEnabled &&
                     root.wifiNetworks.length > 0

            Layout.fillWidth: true

            spacing: 6

            Text {
                text: "REDES ENCONTRADAS"

                color: root.theme.textSecondary
                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 10
                font.bold: true

                Layout.fillWidth: true
            }

            Repeater {
                model: root.wifiNetworks

                delegate: Rectangle {
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: 62

                    radius: 10

                    color: modelData.inUse
                           ? root.theme.bgSelected
                           : root.theme.bgSurface

                    border.width:
                        modelData.inUse ? 2 : 1

                    border.color:
                        modelData.inUse
                        ? root.theme.accentPrimary
                        : root.theme.bgBorder

                    RowLayout {
                        anchors.fill: parent

                        anchors.leftMargin: 14
                        anchors.rightMargin: 14

                        spacing: 10

                        Text {
                            text: modelData.inUse
                                  ? "󰤨"
                                  : "󰤯"

                            color: modelData.inUse
                                   ? root.theme.accentPrimary
                                   : root.theme.textPrimary

                            font.family: "JetBrains Mono Nerd Font"
                            font.pixelSize: 20
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: modelData.ssid

                                color: root.theme.textPrimary
                                font.family: "JetBrains Mono Nerd Font"
                                font.pixelSize: 12
                                font.bold: true

                                elide: Text.ElideRight

                                Layout.fillWidth: true
                            }

                            Text {
                                text: modelData.security !== ""
                                      ? "󰌾  "
                                        + modelData.security
                                        + " • "
                                        + modelData.signal
                                        + "%"
                                      : "Aberta • "
                                        + modelData.signal
                                        + "%"

                                color: root.theme.textSecondary

                                font.family: "JetBrains Mono Nerd Font"
                                font.pixelSize: 9

                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            text: modelData.signal >= 75
                                  ? "󰤨"
                                  : modelData.signal >= 45
                                    ? "󰤥"
                                    : "󰤢"

                            color: root.theme.textSecondary

                            font.family: "JetBrains Mono Nerd Font"
                            font.pixelSize: 18
                        }

                        TapHandler {
                            onTapped: root.connectWifi(
                                modelData.ssid,
                                modelData.security,
                                modelData.bssid
                            )
                        }
                    }
                }
            }
        }

        Text {
            visible: root.wifiAvailable &&
                     root.wifiEnabled &&
                     !root.wifiScanning &&
                     root.wifiNetworks.length === 0

            text: "Nenhuma rede encontrada."

            color: root.theme.textMuted

            font.family: "JetBrains Mono Nerd Font"
            font.pixelSize: 10

            Layout.fillWidth: true
        }

        Text {
            text: "ETHERNET"

            color: root.theme.textSecondary

            font.family: "JetBrains Mono Nerd Font"
            font.pixelSize: 10
            font.bold: true

            Layout.fillWidth: true
            Layout.topMargin: 4
        }

        Rectangle {
            Layout.fillWidth: true

            Layout.preferredHeight:
                root.ethernetAvailable ? 116 : 78

            radius: 10

            color: root.ethernetAvailable
                   ? (root.ethernetConnected
                      ? root.theme.bgHover
                      : root.theme.bgSurface)
                   : root.theme.bgHover

            border.width:
                root.ethernetConnected ? 2 : 1

            border.color:
                root.ethernetConnected
                ? root.theme.accentPrimary
                : root.theme.bgBorder

            opacity:
                root.ethernetAvailable ? 1.0 : 0.55

            RowLayout {
                anchors.fill: parent

                anchors.leftMargin: 14
                anchors.rightMargin: 14

                spacing: 12

                Text {
                    text: "󰈀"

                    color: root.ethernetAvailable
                           ? root.theme.textPrimary
                           : root.theme.textMuted

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 22
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    Text {
                        text: "Ethernet"

                        color: root.ethernetAvailable
                               ? root.theme.textPrimary
                               : root.theme.textMuted

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    Text {
                        text: root.ethernetAvailable
                              ? (root.ethernetConnected
                                 ? "Conectado"
                                 : "Desconectado")
                              : "Nenhuma interface Ethernet detectada"

                        color: root.theme.textSecondary

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 10
                    }

                    Text {
                        visible: root.ethernetAvailable

                        text: root.ethernetDevice
                              + " • "
                              + root.ethernetConnection

                        color: root.theme.textMuted

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 9

                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        visible: root.ethernetAvailable &&
                                 root.ethernetConnected &&
                                 root.ethernetIp !== ""

                        text: "IP: " + root.ethernetIp

                        color: root.theme.textSecondary

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 9

                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }

                Text {
                    visible: root.ethernetConnected

                    text: "󰄬"

                    color: root.theme.accentPrimary

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 18
                }
            }

            TapHandler {
                enabled: root.ethernetAvailable

                onTapped: {
                    if (root.ethernetConnected)
                        root.disconnectEthernet()
                    else
                        root.connectEthernet()
                }
            }
        }

        Rectangle {
            visible: root.ethernetAvailable &&
                     root.ethernetConnected

            Layout.fillWidth: true
            Layout.preferredHeight: 74

            radius: 10

            color: root.theme.bgSurface

            border.width: 1
            border.color: root.theme.bgBorder

            ColumnLayout {
                anchors.fill: parent

                anchors.leftMargin: 14
                anchors.rightMargin: 14
                anchors.topMargin: 9
                anchors.bottomMargin: 9

                spacing: 2

                Text {
                    text: "Gateway: "
                          + (root.ethernetGateway !== ""
                             ? root.ethernetGateway
                             : "—")

                    color: root.theme.textSecondary

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 9

                    Layout.fillWidth: true
                }

                Text {
                    text: "DNS: "
                          + (root.ethernetDns !== ""
                             ? root.ethernetDns
                             : "—")

                    color: root.theme.textSecondary

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 9

                    Layout.fillWidth: true
                }
            }
        }

        Text {
            text: "CONEXÃO"

            color: root.theme.textSecondary

            font.family: "JetBrains Mono Nerd Font"
            font.pixelSize: 10
            font.bold: true

            Layout.fillWidth: true
            Layout.topMargin: 4
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 64

            radius: 10

            color: root.theme.bgSurface

            border.width: 1
            border.color: root.theme.bgBorder

            RowLayout {
                anchors.fill: parent

                anchors.leftMargin: 14
                anchors.rightMargin: 14

                spacing: 12

                Text {
                    text: root.ethernetConnected
                          ? "󰩟"
                          : "󰅙"

                    color: root.ethernetConnected
                           ? root.theme.accentGreen
                           : root.theme.textMuted

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 22
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: root.ethernetConnected
                              ? "Conectado"
                              : "Nenhuma conexão ativa"

                        color: root.theme.textPrimary

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 12
                    }

                    Text {
                        text: root.ethernetConnected
                              ? root.ethernetConnection
                              : "NetworkManager"

                        color: root.theme.textSecondary

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 10
                    }
                }
            }
        }

        Text {
            visible: root.wifiError !== ""

            text: root.wifiError

            color: root.theme.accentRed

            font.family: "JetBrains Mono Nerd Font"
            font.pixelSize: 10

            wrapMode: Text.WordWrap

            Layout.fillWidth: true
        }

        Text {
            text: "Backend: NetworkManager + nmcli"

            color: root.theme.textSecondary

            font.family: "JetBrains Mono Nerd Font"
            font.pixelSize: 10

            Layout.fillWidth: true
            Layout.topMargin: 4
        }
    }

    Popup {
        id: passwordPopup

        modal: true
        focus: true

        width: Math.min(root.width - 40, 360)
        height: 190

        x: Math.max(
            20,
            (root.width - width) / 2
        )

        y: Math.max(
            20,
            (root.height - height) / 2
        )

        closePolicy:
            Popup.NoAutoClose

        onOpened: {
            passwordField.forceActiveFocus()
        }

        onClosed: {
            root.passwordDialogVisible = false
        }

        background: Rectangle {
            radius: 14

            color: root.theme.bgSurface

            border.width: 1
            border.color: root.theme.bgBorder
        }

        contentItem: ColumnLayout {
            anchors.fill: parent

            anchors.margins: 18

            spacing: 10

            Text {
                text: "Conectar ao Wi-Fi"

                color: root.theme.textPrimary

                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 15
                font.bold: true

                Layout.fillWidth: true
            }

            Text {
                text: root.selectedSsid

                color: root.theme.textSecondary

                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 10

                elide: Text.ElideRight

                Layout.fillWidth: true
            }

            TextField {
                id: passwordField

                Layout.fillWidth: true
                Layout.preferredHeight: 38

                placeholderText: "Senha da rede"

                echoMode: TextInput.Password

                color: root.theme.textPrimary

                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 11

                background: Rectangle {
                    radius: 8

                    color: root.theme.bgBase

                    border.width: 1
                    border.color: root.theme.bgBorder
                }

                onAccepted: {
                    root.wifiPassword = text
                    root.connectWifiWithPassword()
                }
            }

            Text {
                visible: root.wifiError !== ""

                text: root.wifiError

                color: root.theme.accentRed

                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 9

                wrapMode: Text.WordWrap

                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true

                spacing: 8

                Item {
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.preferredWidth: 82
                    Layout.preferredHeight: 32

                    radius: 8

                    color: root.theme.bgHover

                    Text {
                        anchors.centerIn: parent

                        text: "Cancelar"

                        color: root.theme.textSecondary

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 10
                    }

                    TapHandler {
                        onTapped: {
                            root.passwordDialogVisible = false
                            root.wifiPassword = ""
                            root.wifiError = ""

                            passwordPopup.close()
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 82
                    Layout.preferredHeight: 32

                    radius: 8

                    color: root.theme.accentPrimary

                    Text {
                        anchors.centerIn: parent

                        text: "Conectar"

                        color: root.theme.bgBase

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 10
                        font.bold: true
                    }

                    TapHandler {
                        onTapped: {
                            root.wifiPassword =
                                passwordField.text

                            root.connectWifiWithPassword()
                        }
                    }
                }
            }
        }
    }
}
