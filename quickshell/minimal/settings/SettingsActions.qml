pragma Singleton

import QtQuick

QtObject {
    id: root

    function toggleDock(settings) {
        if (settings) {
            console.log("DOCK ANTES:", settings.dockVisible)

            settings.dockVisible = !settings.dockVisible

            console.log("DOCK DEPOIS:", settings.dockVisible)
        } else {
            console.log("ERRO: settings é null")
        }
    }

    function toggleBar(settings) {
        if (settings) {
            console.log("BAR ANTES:", settings.barVisible)

            settings.barVisible = !settings.barVisible

            console.log("BAR DEPOIS:", settings.barVisible)
        } else {
            console.log("ERRO: settings é null")
        }
    }
}
