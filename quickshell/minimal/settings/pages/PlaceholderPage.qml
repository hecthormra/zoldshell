import QtQuick
import QtQuick.Layouts
import qs.settings 1.0

SettingsPage {
    id: root

    title: "Configuração"
    description: "Esta seção ainda será integrada ao backend do shell."

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 100

        radius: 12

        color: root.theme.bgHover

        Text {
            anchors.centerIn: parent

            text: "Em desenvolvimento 🐢"

            color: root.theme.textSecondary

            font.family: "JetBrains Mono Nerd Font"
            font.pixelSize: 13
        }
    }
}
