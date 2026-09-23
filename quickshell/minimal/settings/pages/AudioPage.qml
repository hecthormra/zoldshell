import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.settings 1.0

SettingsPage {
    id: root

    title: "Áudio"
    description: "Controle o volume e os dispositivos de áudio."

    property real volume: 0
    property bool muted: false

    property var sinks: []
    property var sources: []

    property string parseSection: ""

    function refreshAudio() {
        if (!volumeProcess.running)
            volumeProcess.running = true

        if (!statusProcess.running)
            statusProcess.running = true
    }

    function setVolume(value) {
        setVolumeProcess.command = [
            "wpctl",
            "set-volume",
            "@DEFAULT_AUDIO_SINK@",
            (value / 100).toFixed(2)
        ]

        setVolumeProcess.running = true
        root.volume = value
    }

    function toggleMute() {
        setMuteProcess.command = [
            "wpctl",
            "set-mute",
            "@DEFAULT_AUDIO_SINK@",
            "toggle"
        ]

        setMuteProcess.running = true
    }

    function setDefault(id) {
        setDefaultProcess.command = [
            "wpctl",
            "set-default",
            String(id)
        ]

        setDefaultProcess.running = true
    }

    Process {
        id: volumeProcess

        command: [
            "wpctl",
            "get-volume",
            "@DEFAULT_AUDIO_SINK@"
        ]

        running: false

        stdout: SplitParser {
            onRead: data => {
                const match = data.match(/Volume:\s+([0-9.]+)/)

                if (match)
                    root.volume = parseFloat(match[1]) * 100

                root.muted = data.includes("[MUTED]")
            }
        }
    }

    Process {
        id: statusProcess

        command: [
            "wpctl",
            "status"
        ]

        running: false

        stdout: SplitParser {
            onRead: data => {
                const line = data.trim()

                if (line.includes("Sinks:")) {
                    root.parseSection = "sinks"
                    return
                }

                if (line.includes("Sources:")) {
                    root.parseSection = "sources"
                    return
                }

                if (
                    line.includes("Filters:") ||
                    line.includes("Streams:") ||
                    line === "Video"
                ) {
                    root.parseSection = ""
                    return
                }

                const match = line.match(
                    /^(\*)?\s*(\d+)\.\s+(.+?)\s+\[vol:/
                )

                if (!match)
                    return

                const item = {
                    id: Number(match[2]),
                    name: match[3].trim(),
                    isDefault: !!match[1]
                }

                if (root.parseSection === "sinks") {
                    let list = root.sinks.filter(
                        device => device.id !== item.id
                    )

                    list.push(item)

                    root.sinks = list
                }

                if (root.parseSection === "sources") {
                    let list = root.sources.filter(
                        device => device.id !== item.id
                    )

                    list.push(item)

                    root.sources = list
                }
            }
        }

        onExited: {
            // statusProcess pode acumular dispositivos antigos.
            // Fazemos uma nova leitura completa periodicamente.
        }
    }

    Process {
        id: setVolumeProcess

        command: []
        running: false

        onExited: root.refreshAudio()
    }

    Process {
        id: setMuteProcess

        command: []
        running: false

        onExited: root.refreshAudio()
    }

    Process {
        id: setDefaultProcess

        command: []
        running: false

        onExited: {
            root.sinks = []
            root.sources = []
            root.refreshAudio()
        }
    }

    Timer {
        interval: 1500
        repeat: true
        running: root.visible

        onTriggered: {
            root.sinks = []
            root.sources = []
            root.refreshAudio()
        }
    }

    Component.onCompleted: root.refreshAudio()

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 12

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 110

            radius: 12
            color: root.theme.bgHover
            border.width: 1
            border.color: root.theme.bgBorder

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 14

                Text {
                    text: root.muted ? "󰝟" : "󰕾"
                    color: root.theme.textPrimary
                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 28
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5

                    Text {
                        text: "Volume"
                        color: root.theme.textPrimary
                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 13
                        font.bold: true
                    }

                    Slider {
                        id: volumeSlider

                        Layout.fillWidth: true

                        from: 0
                        to: 100
                        stepSize: 1

                        value: root.volume

                        onMoved: root.setVolume(value)
                    }
                }

                Text {
                    text: Math.round(root.volume) + "%"
                    color: root.theme.textPrimary
                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 13
                    font.bold: true

                    Layout.preferredWidth: 42
                    horizontalAlignment: Text.AlignRight
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 44

            radius: 10

            color: muteMouse.containsMouse
                   ? root.theme.bgHover
                   : root.theme.bgSurface

            border.width: 1
            border.color: root.theme.bgBorder

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 10

                Text {
                    text: root.muted ? "󰝟" : "󰕾"
                    color: root.theme.textPrimary
                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 18
                }

                Text {
                    text: root.muted ? "Áudio mutado" : "Áudio ativado"
                    color: root.theme.textPrimary
                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 12

                    Layout.fillWidth: true
                }

                Text {
                    text: root.muted ? "Ativar" : "Mutar"
                    color: root.theme.textSecondary
                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 11
                }
            }

            MouseArea {
                id: muteMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: root.toggleMute()
            }
        }

        Text {
            text: "SAÍDA"
            color: root.theme.textSecondary
            font.family: "JetBrains Mono Nerd Font"
            font.pixelSize: 10
            font.bold: true

            Layout.fillWidth: true
            Layout.topMargin: 4
        }

        Repeater {
            model: root.sinks

            delegate: Rectangle {
                required property var modelData

                Layout.fillWidth: true
                Layout.preferredHeight: 58

                radius: 10

                color: modelData.isDefault
                       ? root.theme.bgHover
                       : root.theme.bgSurface

                border.width: modelData.isDefault ? 2 : 1
                border.color: modelData.isDefault
                              ? root.theme.accent
                              : root.theme.bgBorder

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 12

                    Text {
                        text: "󰓃"
                        color: root.theme.textPrimary
                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 20
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: modelData.name

                            color: root.theme.textPrimary
                            font.family: "JetBrains Mono Nerd Font"
                            font.pixelSize: 12

                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: modelData.isDefault
                                  ? "Dispositivo de saída padrão"
                                  : "Dispositivo de saída"

                            color: root.theme.textSecondary
                            font.family: "JetBrains Mono Nerd Font"
                            font.pixelSize: 10
                        }
                    }

                    Text {
                        visible: modelData.isDefault

                        text: "󰄬"

                        color: root.theme.accent
                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 18
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        if (!modelData.isDefault)
                            root.setDefault(modelData.id)
                    }
                }
            }
        }

        Text {
            text: "ENTRADA"
            color: root.theme.textSecondary
            font.family: "JetBrains Mono Nerd Font"
            font.pixelSize: 10
            font.bold: true

            Layout.fillWidth: true
            Layout.topMargin: 4
        }

        Repeater {
            model: root.sources

            delegate: Rectangle {
                required property var modelData

                Layout.fillWidth: true
                Layout.preferredHeight: 58

                radius: 10

                color: modelData.isDefault
                       ? root.theme.bgHover
                       : root.theme.bgSurface

                border.width: modelData.isDefault ? 2 : 1
                border.color: modelData.isDefault
                              ? root.theme.accent
                              : root.theme.bgBorder

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 12

                    Text {
                        text: "󰍬"
                        color: root.theme.textPrimary
                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 20
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: modelData.name

                            color: root.theme.textPrimary
                            font.family: "JetBrains Mono Nerd Font"
                            font.pixelSize: 12

                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: modelData.isDefault
                                  ? "Dispositivo de entrada padrão"
                                  : "Dispositivo de entrada"

                            color: root.theme.textSecondary
                            font.family: "JetBrains Mono Nerd Font"
                            font.pixelSize: 10
                        }
                    }

                    Text {
                        visible: modelData.isDefault

                        text: "󰄬"

                        color: root.theme.accent
                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 18
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        if (!modelData.isDefault)
                            root.setDefault(modelData.id)
                    }
                }
            }
        }

        Text {
            text: "Backend: PipeWire + WirePlumber"
            color: root.theme.textSecondary
            font.family: "JetBrains Mono Nerd Font"
            font.pixelSize: 10

            Layout.fillWidth: true
            Layout.topMargin: 4
        }
    }
}
