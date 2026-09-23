import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.settings 1.0

SettingsPage {
    id: root

    property string defaultFont: "JetBrains Mono Nerd Font"

    title: "Atalhos"
    description: "Atalhos definidos na configuração do Sway."

    property string configText: ""

    Process {
        id: configProcess

        command: [
            "sh",
            "-c",
            "cat \"$HOME/.config/sway/config\" 2>/dev/null"
        ]

        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                root.configText = this.text
            }
        }
    }

    function extractShortcuts() {
        const lines = root.configText.split("\n")
        const result = []

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim()

            if (line.startsWith("bindsym "))
                result.push(line)
        }

        return result
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 10

        Text {
            text: "Atalhos do Sway"
            color: root.theme.textPrimary
            font.family: root.defaultFont
            font.pixelSize: 14
            font.bold: true
        }

        Text {
            text: "Estes atalhos são lidos diretamente do seu config."
            color: root.theme.textSecondary
            font.family: root.defaultFont
            font.pixelSize: 11
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        Repeater {
            model: root.extractShortcuts()

            delegate: Rectangle {
                required property string modelData

                Layout.fillWidth: true
                implicitHeight: 52

                radius: 10
                color: root.theme.bgSurface
                border.width: 1
                border.color: root.theme.bgBorder

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12

                    Text {
                        text: "󰌆"
                        color: root.theme.accentPrimary
                        font.family: root.defaultFont
                        font.pixelSize: 19
                    }

                    Text {
                        text: modelData
                        color: root.theme.textPrimary
                        font.family: root.defaultFont
                        font.pixelSize: 10
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}
