pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    property bool enabled: false

    function toggle() {
        if (enabled) {
            offProc.running = true
        } else {
            onProc.running = true
        }

        enabled = !enabled
    }

    Process {
        id: onProc
        command: ["rfkill", "unblock", "bluetooth"]
        running: false
    }

    Process {
        id: offProc
        command: ["rfkill", "block", "bluetooth"]
        running: false
    }

    Process {
        id: stateProc
        command: [
            "bash",
            "-c",
            "rfkill list bluetooth 2>/dev/null | grep -q 'Soft blocked: yes' && echo off || echo on"
        ]

        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                root.enabled = text.trim() === "on"
            }
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: true

        onTriggered: stateProc.running = true
    }
}
