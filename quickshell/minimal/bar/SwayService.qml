import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property var workspaces: []
    property string activeWindowTitle: ""

    Timer {
        interval: 250
        running: true
        repeat: true

        onTriggered: {
            workspaceProcess.running = true
            treeProcess.running = true
        }
    }

    Process {
        id: workspaceProcess

        command: ["swaymsg", "-t", "get_workspaces", "-r"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)

                    root.workspaces = data.map(function(ws) {
                        return {
                            id: ws.num,
                            name: ws.name,
                            focused: ws.focused,
                            urgent: ws.urgent
                        }
                    })
                } catch (e) {
                    console.log("Workspace JSON error:", e)
                }
            }
        }
    }

    Process {
        id: treeProcess

        command: ["swaymsg", "-t", "get_tree", "-r"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const tree = JSON.parse(text)
                    root.activeWindowTitle = findFocusedTitle(tree)
                } catch (e) {
                    console.log("Tree JSON error:", e)
                }
            }
        }
    }

    Process {
        id: switchProcess
    }

    function switchWorkspace(name) {
        switchProcess.command = [
            "swaymsg",
            "workspace",
            name.toString()
        ]

        switchProcess.running = true
    }

    function findFocusedTitle(node) {
        if (!node)
            return ""

        if (node.focused && node.name)
            return node.name

        if (node.nodes) {
            for (const child of node.nodes) {
                const result = findFocusedTitle(child)
                if (result)
                    return result
            }
        }

        if (node.floating_nodes) {
            for (const child of node.floating_nodes) {
                const result = findFocusedTitle(child)
                if (result)
                    return result
            }
        }

        return ""
    }

    Component.onCompleted: {
        workspaceProcess.running = true
        treeProcess.running = true
    }
}
