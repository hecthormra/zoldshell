import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property var theme

    property string title: ""
    property string description: ""

    property bool checked: false

    signal toggled(bool value)

    Layout.fillWidth: true
    Layout.preferredHeight: 64

    RowLayout {
        anchors.fill: parent

        spacing: 14

        ColumnLayout {
            Layout.fillWidth: true

            spacing: 3

            Text {
                text: root.title

                color: root.theme.textPrimary

                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 13
            }

            Text {
                visible: root.description !== ""

                text: root.description

                color: root.theme.textSecondary

                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 11

                wrapMode: Text.WordWrap

                Layout.fillWidth: true
            }
        }

        Rectangle {
            width: 44
            height: 24

            radius: 12

            color: root.checked
                   ? root.theme.accentPrimary
                   : root.theme.bgHover

            Rectangle {
                width: 18
                height: 18

                radius: 9

                anchors.verticalCenter: parent.verticalCenter

                x: root.checked ? parent.width - width - 3 : 3

                color: root.theme.textPrimary

                Behavior on x {
                    NumberAnimation {
                        duration: 120
                    }
                }
            }

            MouseArea {
                anchors.fill: parent

                onClicked: root.toggled(!root.checked)
            }
        }
    }
}
