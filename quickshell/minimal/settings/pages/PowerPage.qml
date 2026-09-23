import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.settings 1.0

SettingsPage {
    id: root

    title: "Bateria"
    description: "Status da bateria e modo de desempenho."
    
    property string defaultFont: "JetBrains Mono Nerd Font"
    property bool hasBattery: false
    property int batteryPercent: 0
    property string batteryState: ""
    property string batteryTime: ""
    property string batteryCapacity: ""
    property string currentProfile: ""

    function refresh() {
        if (!batteryProcess.running)
            batteryProcess.running = true

        if (!profileProcess.running)
            profileProcess.running = true
    }

    function stateText(state) {
        switch (state) {
        case "charging":
            return "Carregando"

        case "discharging":
            return "Descarregando"

        case "fully-charged":
            return "Carga completa"

        case "empty":
            return "Vazia"

        case "pending-charge":
            return "Aguardando carregamento"

        case "pending-discharge":
            return "Aguardando descarga"

        default:
            return state || "Desconhecido"
        }
    }

    function setProfile(profile) {
        if (profileSetProcess.running)
            return

        profileSetProcess.command = [
            "/usr/bin/powerprofilesctl",
            "set",
            profile
        ]

        profileSetProcess.running = true
    }

    Process {
        id: batteryProcess

        command: [
            "sh",
            "-c",
            "device=$(upower -e 2>/dev/null | grep '/battery_' | head -n1); " +
            "if [ -n \"$device\" ]; then " +
            "echo \"BATTERY_FOUND\"; " +
            "upower -i \"$device\"; " +
            "else " +
            "echo \"NO_BATTERY\"; " +
            "fi"
        ]

        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const output = this.text

                root.hasBattery =
                    output.indexOf("BATTERY_FOUND") !== -1

                if (!root.hasBattery) {
                    root.batteryPercent = 0
                    root.batteryState = ""
                    root.batteryTime = ""
                    root.batteryCapacity = ""
                    return
                }

                function value(name) {
                    const match = output.match(
                        new RegExp(
                            "^\\s*" + name + ":\\s*(.+)$",
                            "m"
                        )
                    )

                    return match ? match[1].trim() : ""
                }

                const percentage = value("percentage")
                const state = value("state")
                const timeToEmpty = value("time to empty")
                const timeToFull = value("time to full")
                const capacity = value("capacity")

                if (percentage) {
                    const match = percentage.match(/([0-9]+)%/)

                    if (match)
                        root.batteryPercent = Number(match[1])
                }

                root.batteryState = root.stateText(state)

                if (state === "charging" && timeToFull) {
                    root.batteryTime =
                        "Tempo até carga completa: " + timeToFull
                } else if (state === "discharging" && timeToEmpty) {
                    root.batteryTime =
                        "Tempo restante: " + timeToEmpty
                } else {
                    root.batteryTime = ""
                }

                root.batteryCapacity = capacity
            }
        }
    }

    Process {
        id: profileProcess

        command: [
            "/usr/bin/powerprofilesctl",
            "get"
        ]

        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const value = this.text.trim()

                if (value !== "")
                    root.currentProfile = value
            }
        }
    }

    Process {
        id: profileSetProcess

        command: []

        running: false

        onExited: {
            root.refresh()
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: root.visible

        onTriggered: root.refresh()
    }

    Component.onCompleted: {
        root.refresh()
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 14

        Rectangle {
            Layout.fillWidth: true

            implicitHeight: root.hasBattery ? 120 : 82

            radius: 12

            color: root.theme.bgSurface

            border.width: 1
            border.color: root.theme.bgBorder

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16

                spacing: 6

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: root.hasBattery
                              ? "󰁹"
                              : "󰂑"

                        color: root.hasBattery
                               ? root.theme.batteryGood
                               : root.theme.textMuted

                        font.family: root.defaultFont
                        font.pixelSize: 24
                    }

                    ColumnLayout {
                        Layout.fillWidth: true

                        spacing: 2

                        Text {
                            text: root.hasBattery
                                  ? "Bateria"
                                  : "Nenhuma bateria detectada"

                            color: root.theme.textPrimary

                            font.family: root.defaultFont
                            font.pixelSize: 14
                            font.bold: true
                        }

                        Text {
                            visible: root.hasBattery

                            text: root.batteryPercent +
                                  "% • " +
                                  root.batteryState

                            color: root.theme.textSecondary

                            font.family: root.defaultFont
                            font.pixelSize: 11
                        }
                    }

                    Text {
                        visible: root.hasBattery

                        text: root.batteryPercent + "%"

                        color: root.theme.textPrimary

                        font.family: root.defaultFont
                        font.pixelSize: 20
                        font.bold: true
                    }
                }

                Text {
                    visible: root.hasBattery &&
                             root.batteryTime !== ""

                    text: root.batteryTime

                    color: root.theme.textSecondary

                    font.family: root.defaultFont
                    font.pixelSize: 11

                    Layout.fillWidth: true
                }

                Text {
                    visible: root.hasBattery &&
                             root.batteryCapacity !== ""

                    text: "Capacidade: " +
                          root.batteryCapacity

                    color: root.theme.textMuted

                    font.family: root.defaultFont
                    font.pixelSize: 10
                }
            }
        }

        Text {
            text: "Modo de desempenho"

            color: root.theme.textPrimary

            font.family: root.defaultFont
            font.pixelSize: 14
            font.bold: true

            Layout.topMargin: 4
        }

        Text {
            text: "Escolha como o sistema deve equilibrar desempenho e consumo."

            color: root.theme.textSecondary

            font.family: root.defaultFont
            font.pixelSize: 11

            wrapMode: Text.WordWrap

            Layout.fillWidth: true
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 68

                radius: 12

                color: root.currentProfile === "power-saver"
                       ? root.theme.bgSelected
                       : root.theme.bgSurface

                border.width: 1

                border.color: root.currentProfile === "power-saver"
                              ? root.theme.accentPrimary
                              : root.theme.bgBorder

                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12

                    spacing: 12

                    Text {
                        text: "󰾆"

                        color: root.currentProfile === "power-saver"
                               ? root.theme.accentPrimary
                               : root.theme.textSecondary

                        font.family: root.defaultFont
                        font.pixelSize: 22
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "Economia"

                            color: root.theme.textPrimary

                            font.family: root.defaultFont
                            font.pixelSize: 12
                            font.bold: true
                        }

                        Text {
                            text: "Menor consumo de energia."

                            color: root.theme.textSecondary

                            font.family: root.defaultFont
                            font.pixelSize: 10

                            Layout.fillWidth: true

                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        visible: root.currentProfile === "power-saver"

                        text: "✓"

                        color: root.theme.accentPrimary

                        font.family: root.defaultFont
                        font.pixelSize: 17
                        font.bold: true
                    }
                }

                MouseArea {
                    anchors.fill: parent

                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        root.setProfile("power-saver")
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 68

                radius: 12

                color: root.currentProfile === "balanced"
                       ? root.theme.bgSelected
                       : root.theme.bgSurface

                border.width: 1

                border.color: root.currentProfile === "balanced"
                              ? root.theme.accentPrimary
                              : root.theme.bgBorder

                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12

                    spacing: 12

                    Text {
                        text: "󰾅"

                        color: root.currentProfile === "balanced"
                               ? root.theme.accentPrimary
                               : root.theme.textSecondary

                        font.family: root.defaultFont
                        font.pixelSize: 22
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "Balanceado"

                            color: root.theme.textPrimary

                            font.family: root.defaultFont
                            font.pixelSize: 12
                            font.bold: true
                        }

                        Text {
                            text: "Equilíbrio entre desempenho e consumo."

                            color: root.theme.textSecondary

                            font.family: root.defaultFont
                            font.pixelSize: 10

                            Layout.fillWidth: true

                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        visible: root.currentProfile === "balanced"

                        text: "✓"

                        color: root.theme.accentPrimary

                        font.family: root.defaultFont
                        font.pixelSize: 17
                        font.bold: true
                    }
                }

                MouseArea {
                    anchors.fill: parent

                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        root.setProfile("balanced")
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 68

                radius: 12

                color: root.currentProfile === "performance"
                       ? root.theme.bgSelected
                       : root.theme.bgSurface

                border.width: 1

                border.color: root.currentProfile === "performance"
                              ? root.theme.accentPrimary
                              : root.theme.bgBorder

                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12

                    spacing: 12

                    Text {
                        text: "󰓅"

                        color: root.currentProfile === "performance"
                               ? root.theme.accentPrimary
                               : root.theme.textSecondary

                        font.family: root.defaultFont
                        font.pixelSize: 22
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "Performance"

                            color: root.theme.textPrimary

                            font.family: root.defaultFont
                            font.pixelSize: 12
                            font.bold: true
                        }

                        Text {
                            text: "Prioriza o desempenho do sistema."

                            color: root.theme.textSecondary

                            font.family: root.defaultFont
                            font.pixelSize: 10

                            Layout.fillWidth: true

                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        visible: root.currentProfile === "performance"

                        text: "✓"

                        color: root.theme.accentPrimary

                        font.family: root.defaultFont
                        font.pixelSize: 17
                        font.bold: true
                    }
                }

                MouseArea {
                    anchors.fill: parent

                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        root.setProfile("performance")
                    }
                }
            }
        }
    }
}
