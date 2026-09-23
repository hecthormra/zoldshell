import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root

    property var theme

    property string title: ""
    property string description: ""

    property real from: 0
    property real to: 100
    property real stepSize: 1
    property real value: 0

    signal valueEdited(real value)

    Layout.fillWidth: true
    Layout.preferredHeight: 76

    ColumnLayout {
        anchors.fill: parent

        spacing: 5

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: root.title

                color: root.theme.textPrimary

                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 13

                Layout.fillWidth: true
            }

            Text {
                text: Math.round(root.value)

                color: root.theme.textSecondary

                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 11
            }
        }

        Text {
            visible: root.description !== ""

            text: root.description

            color: root.theme.textSecondary

            font.family: "JetBrains Mono Nerd Font"
            font.pixelSize: 11

            Layout.fillWidth: true
        }

        Slider {
            id: slider

            from: root.from
            to: root.to
            stepSize: root.stepSize

            value: root.value

            Layout.fillWidth: true

            onMoved: root.valueEdited(value)
        }
    }
}
