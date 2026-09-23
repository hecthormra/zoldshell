import QtQuick

Rectangle {
    id: root

    property bool checked: false
    property var theme: null

    signal toggled(bool value)

    width: 42
    height: 22
    radius: 11

    color: root.checked
        ? (root.theme ? root.theme.accentPrimary : "#00ff9c")
        : (root.theme ? root.theme.bgHover : "#444444")

    Rectangle {
        width: 18
        height: 18
        radius: 9

        anchors.verticalCenter: parent.verticalCenter

        x: root.checked
            ? parent.width - width - 2
            : 2

        color: root.checked
            ? "#202020"
            : "#aaaaaa"

        Behavior on x {
            NumberAnimation {
                duration: 120
            }
        }
    }

    MouseArea {
        anchors.fill: parent

        cursorShape: Qt.PointingHandCursor

        onClicked: {
            root.checked = !root.checked
            root.toggled(root.checked)
        }
    }
}
