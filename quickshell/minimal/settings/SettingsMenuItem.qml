import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property var theme: null
    property string text: ""
    property string icon: ""
    property bool selected: false

    signal clicked()

    Layout.fillWidth: true
    Layout.preferredHeight: 38

    Rectangle {
        anchors.fill: parent

        radius: 8

        color: {
            if (!root.theme)
                return "transparent"

            if (root.selected || mouse.containsMouse)
                return root.theme.bgHover

            return "transparent"
        }

        RowLayout {
            anchors.fill: parent

            anchors.leftMargin: 10
            anchors.rightMargin: 10

            spacing: 10

            Text {
                text: root.icon

                color: root.theme
                       ? root.theme.textPrimary
                       : "#ffffff"

                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 17
            }

            Text {
                text: root.text

                color: root.theme
                       ? root.theme.textPrimary
                       : "#ffffff"

                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 12

                Layout.fillWidth: true
            }
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent

        hoverEnabled: true

        onClicked: root.clicked()
    }
}
