import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property var navigate: null
    property var settings: null
    property var theme: null 
   
    property string title: ""
    property string description: ""

    signal clicked()

    implicitHeight: 72
    Layout.fillWidth: true

    Rectangle {
        anchors.fill: parent

        radius: 10

        color: {
            if (!root.theme)
                return "transparent"

            return mouse.containsMouse
                   ? root.theme.bgHover
                   : "transparent"
        }

        border.width: 1

        border.color: {
            if (!root.theme)
                return "transparent"

            return root.theme.border
                   ? root.theme.border
                   : root.theme.bgHover
        }

        ColumnLayout {
            anchors.fill: parent

            anchors.leftMargin: 14
            anchors.rightMargin: 14
            anchors.topMargin: 10
            anchors.bottomMargin: 10

            spacing: 4

            Text {
                text: root.title

                color: root.theme
                       ? root.theme.textPrimary
                       : "#ffffff"

                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 13
                font.bold: true

                Layout.fillWidth: true
            }

            Text {
                text: root.description

                color: root.theme
                       ? root.theme.textSecondary
                       : "#aaaaaa"

                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 10

                wrapMode: Text.WordWrap

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
