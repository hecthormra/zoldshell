pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    property real volume: 50
    property bool muted: false

    // ─────────────────────────────────────────────
    // Set volume
    // ─────────────────────────────────────────────

    function setVolume(v) {
        var clamped = Math.max(0, Math.min(v, 100))
        volume = clamped

        volumeProc.command = [
            "pactl",
            "set-sink-volume",
            "@DEFAULT_SINK@",
            Math.round(clamped) + "%"
        ]

        volumeProc.running = true
    }

    // ─────────────────────────────────────────────
    // Toggle mute
    // ─────────────────────────────────────────────

    function toggleMute() {
        muteProc.command = [
            "pactl",
            "set-sink-mute",
            "@DEFAULT_SINK@",
            "toggle"
        ]

        muteProc.running = true
        muted = !muted
    }

    // ─────────────────────────────────────────────
    // Read volume
    // ─────────────────────────────────────────────

    Process {
        id: volumeProc
        running: false
    }

    // ─────────────────────────────────────────────
    // Mute
    // ─────────────────────────────────────────────

    Process {
        id: muteProc
        running: false
    }

    // ─────────────────────────────────────────────
    // Poll volume
    // ─────────────────────────────────────────────

    Process {
        id: volProc

        command: [
            "bash",
            "-c",
            "pactl get-default-sink >/dev/null 2>&1 && " +
            "pactl get-sink-volume @DEFAULT_SINK@ | " +
            "head -1 | grep -o '[0-9]\\+%' | head -1"
        ]

        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                var match = text.trim().match(/([0-9]+)%/)

                if (match) {
                    root.volume = Math.max(
                        0,
                        Math.min(parseInt(match[1]), 100)
                    )
                }
            }
        }
    }

    // ─────────────────────────────────────────────
    // Poll timer
    // ─────────────────────────────────────────────

    Timer {
        interval: 2000
        repeat: true
        running: true

        onTriggered: volProc.running = true
    }
}
