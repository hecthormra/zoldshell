pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    property real brightness: 50

    function setBrightness(v) {
        var clamped = Math.max(1, Math.min(v, 100))
        root.brightness = clamped

        setProc.command = [
            "brightnessctl",
            "set",
            Math.round(clamped) + "%"
        ]

        setProc.running = true
    }

    Process {
        id: setProc
        running: false
    }

    Process {
        id: readProc

        command: [
            "bash",
            "-c",
            "brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%'"
        ]

        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                var value = parseFloat(text.trim())

                if (!isNaN(value)) {
                    root.brightness = Math.max(
                        0,
                        Math.min(value, 100)
                    )
                }
            }
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: true

        onTriggered: readProc.running = true
    }
}
