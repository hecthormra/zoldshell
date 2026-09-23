pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    property bool enabled: false

    function toggle() {
        if (enabled) {
            disableProc.running = true
        } else {
            enableProc.running = true
        }

        enabled = !enabled
    }

    Process {
        id: enableProc
        command: [
            "sh",
            "-c",
            "if command -v hyprctl >/dev/null 2>&1; then hyprctl hyprsunset temperature 4500; fi"
        ]
        running: false
    }

    Process {
        id: disableProc
        command: [
            "sh",
            "-c",
            "if command -v hyprctl >/dev/null 2>&1; then hyprctl hyprsunset temperature 6500; fi"
        ]
        running: false
    }
}
