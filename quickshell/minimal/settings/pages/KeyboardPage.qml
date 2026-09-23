import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.settings 1.0

SettingsPage {
    id: root

    property string defaultFont: "JetBrains Mono Nerd Font"

    title: "Teclado"
    description: "Configure o layout do teclado usado pelo Sway."

    property string currentLayout: "Detectando..."
    property string currentVariant: ""
    property bool applying: false
    property string statusText: ""

    property var layouts: [
        {
            name: "Português (Brasil)",
            layout: "br",
            variant: ""
        },
        {
            name: "Português (Brasil) — ABNT2",
            layout: "br",
            variant: "abnt2"
        },
        {
            name: "English (US)",
            layout: "us",
            variant: ""
        },
        {
            name: "English (US) — International",
            layout: "us",
            variant: "intl"
        },
        {
            name: "Português (Portugal)",
            layout: "pt",
            variant: ""
        },
        {
            name: "Español",
            layout: "es",
            variant: ""
        }
    ]

    function refreshLayout() {
        if (!getInputsProcess.running)
            getInputsProcess.running = true
    }


    function applyLayout(layout, variant) {
        if (applyProcess.running)
            return

        root.applying = true
        root.statusText = "Aplicando layout..."

        let value = layout

        if (variant !== "")
            value += "(" + variant + ")"

        applyProcess.command = [
            "swaymsg",
            "input",
            "type:keyboard",
            "xkb_layout",
            value
        ]

        applyProcess.running = true
    }          

    Process {
        id: getInputsProcess

        command: [
            "swaymsg",
            "-t",
            "get_inputs"
        ]

        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(this.text)

                    let found = false

                    for (let i = 0; i < data.length; i++) {
                        const input = data[i]

                        if (input.type !== "keyboard")
                            continue

                        if (!input.xkb_active_layout_name)
                            continue

                        root.currentLayout =
                            input.xkb_active_layout_name

                        root.currentVariant =
                            input.xkb_active_layout_code || ""

                        found = true
                        break
                    }

                    if (!found)
                        root.currentLayout = "Não detectado"

                } catch (e) {
                    root.currentLayout = "Não disponível"
                }
            }
        }
    }

    Process {
        id: applyProcess

        command: []

        running: false

        onExited: function(exitCode) {
            root.applying = false

            if (exitCode === 0)
                root.statusText = "Layout aplicado"
            else
                root.statusText = "Não foi possível aplicar o layout"

            root.refreshLayout()
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: root.visible

        onTriggered: root.refreshLayout()
    }

    Component.onCompleted: {
        root.refreshLayout()
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 14

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 96

            radius: 12
            color: root.theme.bgSurface

            border.width: 1
            border.color: root.theme.bgBorder

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 14

                Text {
                    text: "󰌌"
                    color: root.theme.accentPrimary
                    font.family: root.defaultFont
                    font.pixelSize: 28
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "Layout atual"
                        color: root.theme.textSecondary
                        font.family: root.defaultFont
                        font.pixelSize: 11
                    }

                    Text {
                        text: root.currentLayout
                        color: root.theme.textPrimary
                        font.family: root.defaultFont
                        font.pixelSize: 15
                        font.bold: true
                    }

                    Text {
                        visible: root.currentVariant !== ""
                        text: "Variante: " + root.currentVariant
                        color: root.theme.textMuted
                        font.family: root.defaultFont
                        font.pixelSize: 10
                    }
                }

                Rectangle {
                    visible: root.applying
                    Layout.preferredWidth: 90
                    Layout.preferredHeight: 30
                    radius: 8
                    color: root.theme.bgSelected

                    Text {
                        anchors.centerIn: parent
                        text: "Aplicando..."
                        color: root.theme.accentPrimary
                        font.family: root.defaultFont
                        font.pixelSize: 10
                    }
                }
            }
        }

        Text {
            text: "Layouts"
            color: root.theme.textPrimary
            font.family: root.defaultFont
            font.pixelSize: 14
            font.bold: true

            Layout.topMargin: 4
        }

        Text {
            text: "Selecione o layout que deseja usar."
            color: root.theme.textSecondary
            font.family: root.defaultFont
            font.pixelSize: 11

            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: root.layouts

                delegate: Rectangle {
                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: 64

                    radius: 11

                    color: root.currentLayout === modelData.name
                           ? root.theme.bgSelected
                           : root.theme.bgSurface

                    border.width: 1

                    border.color:
                        root.currentLayout === modelData.name
                        ? root.theme.accentPrimary
                        : root.theme.bgBorder

                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 13
                        spacing: 12

                        Text {
                            text:
                                root.currentLayout === modelData.name
                                ? "󰄬"
                                : "󰘆"

                            color:
                                root.currentLayout === modelData.name
                                ? root.theme.accentPrimary
                                : root.theme.textSecondary

                            font.family: root.defaultFont
                            font.pixelSize: 21
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: modelData.name

                                color: root.theme.textPrimary

                                font.family: root.defaultFont
                                font.pixelSize: 12
                                font.bold: true

                                Layout.fillWidth: true
                            }

                            Text {
                                text:
                                    modelData.layout +
                                    (modelData.variant !== ""
                                     ? " • " + modelData.variant
                                     : "")

                                color: root.theme.textMuted

                                font.family: root.defaultFont
                                font.pixelSize: 10
                            }
                        }

                        Text {
                            visible:
                                root.currentLayout === modelData.name

                            text: "✓"

                            color: root.theme.accentPrimary

                            font.family: root.defaultFont
                            font.pixelSize: 17
                            font.bold: true
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !root.applying

                        cursorShape:
                            enabled
                            ? Qt.PointingHandCursor
                            : Qt.ArrowCursor

                        onClicked: {
                            root.applyLayout(
                                modelData.layout,
                                modelData.variant
                            )
                        }
                    }
                }
            }
        }

        Rectangle {
            visible: root.statusText !== ""

            Layout.fillWidth: true
            implicitHeight: 42

            radius: 9
            color: root.theme.bgHover

            Text {
                anchors.centerIn: parent

                text: root.statusText

                color: root.theme.textSecondary

                font.family: root.defaultFont
                font.pixelSize: 10
            }
        }
    }
}
