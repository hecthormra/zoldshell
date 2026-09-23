import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property var theme

    implicitHeight: 28
    Layout.fillWidth: true

    RowLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            spacing: 5
            Layout.fillWidth: true

            Text {
                text: "󰤨"
                color: root.theme
                    ? root.theme.accentCyan
                    : "#7dcfff"

                font.pixelSize: 16
            }

            Text {
                text: "Network"
                color: root.theme
                    ? root.theme.textPrimary
                    : "#c0caf5"

                font.pixelSize: 12

                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        Text {
            text: "󰩟"
            color: root.theme
                ? root.theme.textMuted
                : "#565f89"

            font.pixelSize: 16
        }

        Text {
            text: "Connected"

            color: root.theme
                ? root.theme.textSecondary
                : "#a9b1d6"

            font.pixelSize: 12
        }
    }
}
