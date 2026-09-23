import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.settings 1.0

Item {
    id: root

    property var theme: null
    property var settings: null
    property var navigate: null

    anchors.fill: parent

    ScrollView {
        id: scrollView

        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        anchors.topMargin: 12
        anchors.bottomMargin: 16

        clip: true

        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            id: content

            width: scrollView.availableWidth
            spacing: 12

            Text {
                text: "Configurações"

                color: root.theme
                       ? root.theme.textPrimary
                       : "#ffffff"

                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 20
                font.bold: true

                Layout.fillWidth: true
            }

            Text {
                text: "Configure seu shell em um único lugar."

                color: root.theme
                       ? root.theme.textSecondary
                       : "#aaaaaa"

                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 11

                Layout.fillWidth: true
                Layout.bottomMargin: 8
            }

            ColumnLayout {
                spacing: 8
                Layout.fillWidth: true

                SettingsHomeItem {
                    title: "Desktop"
                    description: "Widgets, espaçamento, tamanho dos ícones e elementos da área de trabalho."

                    theme: root.theme
                    settings: root.settings

                    onClicked: {
                        if (root.navigate)
                            root.navigate("desktop")
                    }
                }

                SettingsHomeItem {
                    title: "Aparência"
                    description: "Tema, transparência, bordas, cores e aparência geral do shell."

                    theme: root.theme
                    settings: root.settings

                    onClicked: {
                        if (root.navigate)
                            root.navigate("appearance")
                    }
                }

                SettingsHomeItem {
                    title: "Rede"
                    description: "Wi-Fi, Ethernet e gerenciamento das conexões de rede."

                    theme: root.theme
                    settings: root.settings

                    onClicked: {
                        if (root.navigate)
                            root.navigate("network")
                    }
                }

                SettingsHomeItem {
                    title: "Áudio"
                    description: "Volume, dispositivos de entrada e saída e controles do PipeWire."

                    theme: root.theme
                    settings: root.settings

                    onClicked: {
                        if (root.navigate)
                            root.navigate("audio")
                    }
                }

                SettingsHomeItem {
                    title: "Energia"
                    description: "Suspensão, desligamento e comportamento relacionado à energia."

                    theme: root.theme
                    settings: root.settings

                    onClicked: {
                        if (root.navigate)
                            root.navigate("power")
                    }
                }

                SettingsHomeItem {
                    title: "Widgets"
                    description: "Informações de CPU, memória e consumo dos componentes do shell."

                    theme: root.theme
                    settings: root.settings

                    onClicked: {
                        if (root.navigate)
                            root.navigate("widgets")
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 10
            }
        }
    }
}
