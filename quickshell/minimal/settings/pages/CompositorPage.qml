import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.settings 1.0

SettingsPage {
    id: root

    title: "Compositor"
    description: "Configurações do Sway e do layout das janelas."

    property int innerGaps: 4
    property int outerGaps: 4
    property int borderWidth: 0
    property int floatingBorderWidth: 0

    property bool readingConfig: false

    function refreshCompositor() {
        if (configProcess.running)
            return

        root.readingConfig = true
        configProcess.running = true
    }

    function setInnerGaps(value) {
        const v = Math.round(value)

        innerGapsProcess.command = [
            "swaymsg",
            "gaps",
            "inner",
            String(v)
        ]

        innerGapsProcess.running = true
    }

    function setOuterGaps(value) {
        const v = Math.round(value)

        outerGapsProcess.command = [
            "swaymsg",
            "gaps",
            "outer",
            String(v)
        ]

        outerGapsProcess.running = true
    }

    function setBorderWidth(value) {
        const v = Math.round(value)

        borderProcess.command = [
            "swaymsg",
            "default_border",
            "pixel",
            String(v)
        ]

        borderProcess.running = true
    }

    function setFloatingBorderWidth(value) {
        const v = Math.round(value)

        floatingBorderProcess.command = [
            "swaymsg",
            "default_floating_border",
            "pixel",
            String(v)
        ]

        floatingBorderProcess.running = true
    }

    Process {
        id: configProcess

        command: [
            "swaymsg",
            "-t",
            "get_config"
        ]

        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const text = this.text

                const innerMatch =
                    text.match(/^\s*gaps\s+inner\s+(\d+)/m)

                const outerMatch =
                    text.match(/^\s*gaps\s+outer\s+(\d+)/m)

                const borderMatch =
                    text.match(
                        /^\s*default_border\s+pixel\s+(\d+)/m
                    )

                const floatingBorderMatch =
                    text.match(
                        /^\s*default_floating_border\s+pixel\s+(\d+)/m
                    )

                if (innerMatch)
                    root.innerGaps =
                        Number(innerMatch[1])

                if (outerMatch)
                    root.outerGaps =
                        Number(outerMatch[1])

                if (borderMatch)
                    root.borderWidth =
                        Number(borderMatch[1])

                if (floatingBorderMatch)
                    root.floatingBorderWidth =
                        Number(floatingBorderMatch[1])

                root.readingConfig = false
            }
        }

        onExited: {
            root.readingConfig = false
        }
    }

    Process {
        id: innerGapsProcess

        command: []
        running: false

        onExited: {
            root.refreshCompositor()
        }
    }

    Process {
        id: outerGapsProcess

        command: []
        running: false

        onExited: {
            root.refreshCompositor()
        }
    }

    Process {
        id: borderProcess

        command: []
        running: false

        onExited: {
            root.refreshCompositor()
        }
    }

    Process {
        id: floatingBorderProcess

        command: []
        running: false

        onExited: {
            root.refreshCompositor()
        }
    }

    Timer {
        interval: 2500
        repeat: true
        running: root.visible

        onTriggered: {
            root.refreshCompositor()
        }
    }

    Component.onCompleted: {
        root.refreshCompositor()
    }

    ColumnLayout {
        Layout.fillWidth: true

        spacing: 12

        Text {
            text: "JANELAS"

            color: root.theme.textSecondary

            font.family: "JetBrains Mono Nerd Font"
            font.pixelSize: 10
            font.bold: true

            Layout.fillWidth: true
        }

        SettingsSliderRow {
            theme: root.theme

            title: "Espaçamento interno"
            description: "Espaço entre as janelas."

            from: 0
            to: 32
            stepSize: 1

            value: root.innerGaps

            onValueEdited: function(value) {
                root.innerGaps = Math.round(value)
                root.setInnerGaps(value)
            }
        }

        SettingsSliderRow {
            theme: root.theme

            title: "Espaçamento externo"
            description:
                "Espaço entre as janelas e a borda da tela."

            from: 0
            to: 32
            stepSize: 1

            value: root.outerGaps

            onValueEdited: function(value) {
                root.outerGaps = Math.round(value)
                root.setOuterGaps(value)
            }
        }

        SettingsSliderRow {
            theme: root.theme

            title: "Borda"
            description:
                "Largura da borda das janelas."

            from: 0
            to: 8
            stepSize: 1

            value: root.borderWidth

            onValueEdited: function(value) {
                root.borderWidth = Math.round(value)
                root.setBorderWidth(value)
            }
        }

        SettingsSliderRow {
            theme: root.theme

            title: "Borda flutuante"
            description:
                "Largura da borda das janelas flutuantes."

            from: 0
            to: 8
            stepSize: 1

            value: root.floatingBorderWidth

            onValueEdited: function(value) {
                root.floatingBorderWidth =
                    Math.round(value)

                root.setFloatingBorderWidth(value)
            }
        }

        Text {
            text: "LAYOUT"

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
                    text: "󰕰"

                    color: root.theme.textPrimary

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 21
                }

                ColumnLayout {
                    Layout.fillWidth: true

                    spacing: 2

                    Text {
                        text: "Layout"

                        color: root.theme.textPrimary

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    Text {
                        text:
                            "Use os atalhos do Sway para alterar o layout."

                        color: root.theme.textSecondary

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 9

                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }
            }
        }

        Text {
            text: "SISTEMA"

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
                    text: "󰖲"

                    color: root.theme.accentPrimary

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 21
                }

                ColumnLayout {
                    Layout.fillWidth: true

                    spacing: 2

                    Text {
                        text: "Sway"

                        color: root.theme.textPrimary

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    Text {
                        text: "Sway 1.12 • wlroots"

                        color: root.theme.textSecondary

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 9
                    }
                }
            }
        }

        Text {
            text: root.readingConfig
                  ? "Sincronizando com o Sway..."
                  : "Configuração sincronizada com o Sway."

            color: root.theme.textMuted

            font.family: "JetBrains Mono Nerd Font"
            font.pixelSize: 9

            Layout.fillWidth: true
        }
    }
}
