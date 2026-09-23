import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root

    property var theme: null
    property var settings: null
    property var navigate: null

    property string title: ""
    property string description: ""

    default property alias content: contentColumn.data

    ScrollView {
        anchors.fill: parent
        anchors.margins: 20

        clip: true

        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        ColumnLayout {
            id: contentColumn

            width: Math.max(0, parent.width)

            spacing: 14

            Text {
                visible: root.title !== ""

                text: root.title

                color: root.theme.textPrimary

                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 22
                font.bold: true

                Layout.fillWidth: true
            }

            Text {
                visible: root.description !== ""

                text: root.description

                color: root.theme.textSecondary

                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 12

                wrapMode: Text.WordWrap

                Layout.fillWidth: true
            }
        }
    }
}
