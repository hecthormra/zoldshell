import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property var theme

    property string icon: ""
    property string label: ""

    property bool hovered: false

    signal clicked()

    Layout.fillWidth: true

    height: 44

    radius: 10

    color: {
        if (!root.theme)
            return root.hovered
                ? "#24283b"
                : "#1a1b26"

        return root.hovered
            ? root.theme.bgHover
            : root.theme.bgBase
    }

    border.color: root.theme
        ? root.theme.bgBorder
        : "#32364a"

    border.width: 1

    Behavior on color {
        ColorAnimation {
            duration: 120
        }
    }

    Behavior on border.color {
        ColorAnimation {
            duration: 120
        }
    }

    // =========================================================
    // CONTENT
    // =========================================================

    Column {
        anchors.centerIn: parent

        spacing: 2

        Text {
            anchors.horizontalCenter: parent.horizontalCenter

            text: root.icon

            color: root.theme
                ? root.theme.textSecondary
                : "#a9b1d6"

            font.pixelSize: 17
            font.family: "JetBrainsMono Nerd Font"

            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter

            text: root.label

            color: root.theme
                ? root.theme.textMuted
                : "#565f89"

            font.pixelSize: 10
            font.family: "JetBrainsMono Nerd Font"

            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }
        }
    }

    // =========================================================
    // MOUSE
    // =========================================================

    MouseArea {
        anchors.fill: parent

        hoverEnabled: true

        cursorShape: Qt.PointingHandCursor

        onEntered: {
            root.hovered = true
        }

        onExited: {
            root.hovered = false
        }

        onClicked: {
            root.clicked()
        }
    }
}
