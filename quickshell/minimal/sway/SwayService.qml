import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    /*
     * Dados
     */
    property var workspaces: []
    property var windows: []
    property var tree: null

    property string activeWindowTitle: ""

    signal updated()

    /*
     * Workspace focado
     */
    readonly property var focusedWorkspace: {
        for (const ws of root.workspaces) {
            if (ws.focused)
                return ws
        }

        return null
    }

    /*
     * =========================================================
     * Atualização
     * =========================================================
     */

    function refreshWorkspaces() {
        if (!workspaceProc.running)
            workspaceProc.running = true
    }

    function refreshTree() {
        if (!treeProc.running)
            treeProc.running = true
    }

    function refresh() {
        refreshWorkspaces()
        refreshTree()
    }

    /*
     * =========================================================
     * Workspace
     * =========================================================
     */

    function switchWorkspace(name) {
        if (name === undefined || name === null)
            return

        workspaceSwitchProc.command = [
            "swaymsg",
            "workspace",
            name.toString()
        ]

        workspaceSwitchProc.running = true
    }

    /*
     * =========================================================
     * Janelas
     * =========================================================
     */

    function focusWindow(id) {
        if (id === undefined || id === null)
            return

        windowProc.command = [
            "swaymsg",
            "[con_id=" + id + "]",
            "focus"
        ]

        windowProc.running = true
    }

    function moveToScratchpad(id) {
        if (id === undefined || id === null)
            return

        windowProc.command = [
            "swaymsg",
            "[con_id=" + id + "]",
            "move",
            "scratchpad"
        ]

        windowProc.running = true
    }

    function showScratchpad(id) {
        if (id === undefined || id === null)
            return

        windowProc.command = [
            "swaymsg",
            "[con_id=" + id + "]",
            "scratchpad",
            "show"
        ]

        windowProc.running = true
    }

    /*
     * =========================================================
     * Construção da lista de janelas
     * =========================================================
     */

    function collectWindows(node, result, workspaceName) {
        if (!node)
            return

        /*
         * Descobre o workspace atual do container.
         */
        let wsName = workspaceName

        if (
            node.type === "workspace" &&
            node.name
        ) {
            wsName =
                node.name.toString()
        }

        /*
         * Container que representa uma janela.
         */
        if (
            node.id !== undefined &&
            node.id !== null &&
            (
                node.app_id ||
                node.window_properties
            )
        ) {
            let appId = ""

            if (node.app_id)
                appId =
                    node.app_id.toString()

            let className = ""

            if (
                node.window_properties &&
                node.window_properties.class
            ) {
                className =
                    node.window_properties.class.toString()
            }

            let title = ""

            if (node.name)
                title =
                    node.name.toString()

            result.push({
                id: node.id,
                title: title,
                appId: appId,
                className: className,
                workspace: wsName || "",
                focused: node.focused === true,
                floating:
                    node.type === "floating_con"
            })
        }

        /*
         * Containers normais.
         */
        const nodes =
            node.nodes || []

        for (const child of nodes) {
            collectWindows(
                child,
                result,
                wsName
            )
        }

        /*
         * Floating windows.
         */
        const floating =
            node.floating_nodes || []

        for (const child of floating) {
            collectWindows(
                child,
                result,
                wsName
            )
        }
    }

    /*
     * =========================================================
     * Encontrar aplicativos da Dock
     * =========================================================
     */

    function getWindowsForApp(app) {
        const result = []

        if (!app)
            return result

        const wantedMatch =
            app.match
                ? app.match
                    .toString()
                    .toLowerCase()
                : ""

        const wantedAppId =
            app.appId
                ? app.appId
                    .toString()
                    .toLowerCase()
                : ""

        let exe = ""

        if (app.cmd) {
            exe =
                app.cmd
                    .split(/\s+/)[0]
                    .split("/")
                    .pop()
                    .replace(
                        /\.[^/.]+$/,
                        ""
                    )
                    .toLowerCase()
        }

        for (const win of root.windows) {
            let matched = false

            /*
             * Match por título.
             */
            if (wantedMatch) {
                if (
                    win.title
                        .toLowerCase()
                        .includes(wantedMatch)
                ) {
                    matched = true
                }
            }

            /*
             * Match por app_id.
             */
            else if (wantedAppId) {
                if (
                    win.appId
                        .toLowerCase()
                        .includes(wantedAppId)
                ) {
                    matched = true
                }
            }

            /*
             * Match automático pelo executável,
             * app_id ou class.
             */
            else if (exe) {
                const appId =
                    win.appId
                        .toLowerCase()

                const cls =
                    win.className
                        .toLowerCase()

                if (
                    appId.includes(exe) ||
                    cls.includes(exe) ||
                    (
                        cls &&
                        exe.includes(cls)
                    )
                ) {
                    matched = true
                }
            }

            if (matched)
                result.push(win)
        }

        return result
    }

    /*
     * =========================================================
     * Título da janela focada
     * =========================================================
     */

    function findFocusedTitle(node) {
        if (!node)
            return ""

        if (node.focused === true) {
            if (node.name)
                return node.name.toString()
        }

        const nodes =
            node.nodes || []

        for (const child of nodes) {
            const result =
                findFocusedTitle(child)

            if (result)
                return result
        }

        const floating =
            node.floating_nodes || []

        for (const child of floating) {
            const result =
                findFocusedTitle(child)

            if (result)
                return result
        }

        return ""
    }

    /*
     * =========================================================
     * Workspaces
     * =========================================================
     */

    Process {
        id: workspaceProc

        command: [
            "swaymsg",
            "-t",
            "get_workspaces",
            "-r"
        ]

        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data =
                        JSON.parse(text)

                    root.workspaces =
                        data.sort(
                            (a, b) =>
                                a.num - b.num
                        )

                    root.updated()

                } catch (e) {
                    console.error(
                        "SwayService workspace:",
                        e
                    )
                }
            }
        }
    }

    /*
     * =========================================================
     * Árvore do Sway
     * =========================================================
     */

    Process {
        id: treeProc

        command: [
            "swaymsg",
            "-t",
            "get_tree",
            "-r"
        ]

        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data =
                        JSON.parse(text)

                    root.tree = data

                    const result = []

                    root.collectWindows(
                        data,
                        result,
                        ""
                    )

                    root.windows =
                        result

                    root.activeWindowTitle =
                        root.findFocusedTitle(
                            data
                        )

                    root.updated()

                } catch (e) {
                    console.error(
                        "SwayService tree:",
                        e
                    )
                }
            }
        }
    }

    /*
     * =========================================================
     * Troca de workspace
     * =========================================================
     */

    Process {
        id: workspaceSwitchProc

        running: false
    }

    /*
     * =========================================================
     * Controle de janelas
     * =========================================================
     */

    Process {
        id: windowProc

        running: false
    }

    /*
     * =========================================================
     * Atualização automática
     * =========================================================
     */

    Timer {
        id: refreshTimer

        interval: 500

        running: true

        repeat: true

        onTriggered: {
            root.refresh()
        }
    }

    /*
     * Primeira atualização.
     */
    Component.onCompleted: {
        root.refresh()
    }
}

