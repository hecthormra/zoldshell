import QtQuick

QtObject {
    id: root

    // =========================
    // APARÊNCIA
    // =========================

    property real panelOpacity: 1.0
    property int panelRadius: 12

    property real dockOpacity: 1.0
    property int dockRadius: 12

    // =========================
    // BAR
    // =========================

    property bool barVisible: true
    property int barHeight: 28

    // =========================
    // DOCK
    // =========================

    property bool dockVisible: true
    property int dockSize: 48

    // =========================
    // WIDGETS
    // =========================

    property bool perfMetersVisible: true
    property bool desktopWidgetsVisible: true
    property int desktopIconSize: 48
    property int desktopSpacing: 12
}
