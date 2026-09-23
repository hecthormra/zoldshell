import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    property var theme

    property string icon: ""
    property string label: ""

    // 0 - 100
    property real value: 50

    property color iconColor: root.theme
        ? root.theme.accentPrimary
        : "#7aa2f7"

    signal moved(real value)
    signal iconClicked()

    spacing: 6

    // =========================================================
    // HEADER
    // =========================================================

    RowLayout {
        Layout.fillWidth: true

        Text {
            text: root.icon

            color: root.iconColor

            font.pixelSize: 18
            font.family: "JetBrainsMono Nerd Font"

            MouseArea {
                anchors.fill: parent

                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    root.iconClicked()
                }
            }
        }

        Text {
            text: root.label

            color: root.theme
                ? root.theme.textPrimary
                : "#c0caf5"

            font.pixelSize: 12
            font.family: "JetBrainsMono Nerd Font"

            Layout.fillWidth: true
        }

        Text {
            text: Math.round(root.value) + "%"

            color: root.theme
                ? root.theme.textMuted
                : "#565f89"

            font.pixelSize: 12
            font.family: "JetBrainsMono Nerd Font"

            horizontalAlignment: Text.AlignRight
        }
    }

    // =========================================================
    // SLIDER
    // =========================================================

    Rectangle {
        id: track

        Layout.fillWidth: true

        height: 6
        radius: 3

        color: root.theme
            ? root.theme.bgBase
            : "#1a1b26"

        // -----------------------------------------------------
        // FILL
        // -----------------------------------------------------

        Rectangle {
            id: fill

            width: track.width * Math.max(
                0,
                Math.min(100, root.value)
            ) / 100

            height: track.height

            radius: track.radius

            color: root.iconColor

            Behavior on width {
                NumberAnimation {
                    duration: 60
                    easing.type: Easing.OutQuad
                }
            }
        }

        // -----------------------------------------------------
        // THUMB
        // -----------------------------------------------------

        Rectangle {
            id: thumb

            width: 14
            height: 14

            radius: 7

            color: root.theme
                ? root.theme.textPrimary
                : "#c0caf5"

            x: fill.width - width / 2

            anchors.verticalCenter: parent.verticalCenter

            Behavior on x {
                NumberAnimation {
                    duration: 60
                    easing.type: Easing.OutQuad
                }
            }
        }

        // -----------------------------------------------------
        // MOUSE CONTROL
        // -----------------------------------------------------

        MouseArea {
            anchors.fill: parent

            cursorShape: Qt.PointingHandCursor

            onPressed: function(mouse) {
                seek(mouse.x)
            }

            onPositionChanged: function(mouse) {
                if (pressed)
                    seek(mouse.x)
            }

            function seek(mouseX) {
                var clamped = Math.max(
                    0,
                    Math.min(mouseX, track.width)
                )

                root.value =
                    (clamped / track.width) * 100

                root.moved(root.value)
            }
        }
    }
}
