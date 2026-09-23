pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    property bool enabled: false

    // =========================================================
    // TOGGLE WIFI
    // =========================================================

    function toggle() {
        enabled = !enabled

        toggleProc.command = [
            "nmcli",
            "radio",
            "wifi",
            enabled ? "on" : "off"
        ]

        toggleProc.running = true
    }

    // =========================================================
    // TOGGLE PROCESS
    // =========================================================

    Process {
        id: toggleProc
        running: false
    }

    // =========================================================
    // CHECK WIFI STATE
    // =========================================================

    Process {
        id: wifiProc

        command: [
            "nmcli",
            "radio",
            "wifi"
        ]

        running: true
    }

    // =========================================================
    // POLL
    // =========================================================

    Timer {
        interval: 5000
        repeat: true
        running: true

        onTriggered: {
            wifiProc.running = true
        }
    }
}
