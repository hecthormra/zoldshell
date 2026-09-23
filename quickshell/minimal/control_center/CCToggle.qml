import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property var theme

    property string icon: ""
    property string label: ""
    property bool active: false

    property color activeColor: root.theme
        ? root.theme.accentPrimary
        : "#7aa2f7"

    signal clicked()

    Layout.fillWidth: true
    height: 64
    radius: 10

    color: {
        if (!root.theme)
            return "#24283b"

        return root.active
            ? Qt.rgba(
                root.activeColor.r,
                root.activeColor.g,
                root.activeColor.b,
                0.20
            )
            : root.theme.bgSurface
    }

    border.color: {
        if (!root.theme)
            return "#32364a"

        return root.active
            ? root.activeColor
            : root.theme.bgBorder
    }

    border.width: 1

    Behavior on color {
        ColorAnimation {
            duration: 150
        }
    }

    Behavior on border.color {
        ColorAnimation {
            duration: 150
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.horizontalCenter: parent.horizontalCenter

            text: root.icon

            color: {
                if (!root.theme)
                    return "#565f89"

                return root.active
                    ? root.activeColor
                    : root.theme.textMuted
            }

            font.pixelSize: 22
            font.family: "JetBrainsMono Nerd Font"

            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter

            text: root.label

            color: {
                if (!root.theme)
                    return "#565f89"

                return root.active
                    ? root.theme.textPrimary
                    : root.theme.textMuted
            }

            font.pixelSize: 11
            font.family: "JetBrainsMono Nerd Font"

            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent

        cursorShape: Qt.PointingHandCursor

        onClicked: {
            root.clicked()
        }
    }
}
