import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.settings 1.0

SettingsPage {
    id: root

    title: "Wallpaper"
    description: "Escolha e gerencie o wallpaper do desktop."

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 12

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 180

            radius: 12
            color: root.theme.bgHover
            border.width: 1
            border.color: root.theme.bgBorder

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: "󰸉"
                    color: root.theme.textPrimary
                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 36
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "Seletor de wallpaper"
                    color: root.theme.textPrimary
                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 14
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "Escolha uma imagem para o desktop."
                    color: root.theme.textSecondary
                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 11
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 44

            radius: 10
            color: root.theme.bgHover

            border.width: 1
            border.color: root.theme.bgBorder

            Text {
                anchors.centerIn: parent

                text: "󰸉  Abrir seletor de wallpaper"

                color: root.theme.textPrimary
                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 12
                font.bold: true
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    Quickshell.execDetached(["qs", "-c", "minimal", "ipc", "call", "wallpaper", "toggle"])
                }
            }
        }

        Text {
            text: "Backend: awww"
            color: root.theme.textSecondary
            font.family: "JetBrains Mono Nerd Font"
            font.pixelSize: 10

            Layout.fillWidth: true
        }
    }
}
