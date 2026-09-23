import Quickshell
import "../sway"
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "config"
import "../theme_switcher"

PanelWindow {
    id: root

    SwayService {
        id: sway
    }

    required property var screen
    property var theme: Theme
    property var settings: null    

    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    WlrLayershell.namespace: "quickshelldock"
    WlrLayershell.layer: WlrLayer.Top

    /*
     * A dock continua ocupando espaço como a original.
     */
    exclusiveZone: 58

    color: "transparent"
    focusable: false
    
    visible: root.dockVisible

    implicitHeight: 60

    readonly property int dockHeight: 48
    readonly property real gap: 4

    /*
     * IMPORTANTE:
     *
     * Os aplicativos continuam vindo do DockApps.qml.
     *
     * Não existe Firefox/Kitty/Dolphin/Code fixados aqui.
     */
    readonly property var orderedApps: {
        let apps = []

        for (const app of DockApps.apps) {
            let entry = {
                icon: app.icon,
                name: app.name,
                cmd: app.cmd,
                order: app.order
            }

            if (app.match)
                entry.match = app.match

            if (app.appId)
                entry.appId = app.appId

            if (app.minimizable !== undefined)
                entry.minimizable = app.minimizable

            apps.push(entry)
        }

        apps.sort(
            (a, b) => a.order - b.order
        )

        return apps
    }

    property bool dockVisible:
        root.settings
            ? root.settings.dockVisible
            : true

    property bool mouseOverDockArea:
        triggerHover.hovered ||
        dockHover.hovered

    /*
     * Mantemos a dock visível.
     *
     * Isso evita o problema da dock ficar escondendo/cortando
     * enquanto estamos adaptando o backend.
     */
    property bool workspaceEmpty: false

    property int _badgeTick: 0

    /*
     * ---------------------------------------------------------
     * Sway / workspace
     * ---------------------------------------------------------
     */

    function currentWorkspaceName() {
        const ws = sway.focusedWorkspace

        if (!ws)
            return ""

        return ws.name !== undefined
            ? ws.name.toString()
            : ""
    }

    function currentWorkspaceNumber() {
        const ws = sway.focusedWorkspace

        if (!ws)
            return -1

        return ws.num !== undefined
            ? ws.num
            : -1
    }

    /*
     * ---------------------------------------------------------
     * Janelas
     * ---------------------------------------------------------
     */

    function getWindowsForApp(app) {
        return sway.getWindowsForApp(app)
    }

    function getUnreadCount(windows) {
        for (const win of windows) {
            const title =
                win.title || ""

            const m =
                title.match(
                    /Inbox \((\d[\d,]*)\)/
                )

            if (m) {
                const n =
                    parseInt(
                        m[1].replace(/,/g, ""),
                        10
                    )

                if (!isNaN(n) && n > 0)
                    return n
            }
        }

        return 0
    }

    /*
     * Verifica se a janela está no workspace atual.
     */
    function isWindowOnCurrentWorkspace(win) {
        const current =
            currentWorkspaceName()

        if (!current)
            return false

        return (
            win.workspace === current
        )
    }

    /*
     * Scratchpad do Sway.
     *
     * O Sway normalmente representa o scratchpad como:
     *
     * "__i3_scratch"
     */
    function isScratchpadWindow(win) {
        if (!win)
            return false

        const ws =
            (win.workspace || "").toString()

        return (
            ws === "__i3_scratch" ||
            ws.toLowerCase().includes("scratch")
        )
    }

    /*
     * ---------------------------------------------------------
     * Dock visibility
     * ---------------------------------------------------------
     */

    function showDockBar() {
        // A visibilidade agora é controlada por ShellSettings.
    }

    function scheduleHide() {
        // Auto-hide será implementado depois.
    }

    Component.onCompleted: {
        sway.refresh()
    }

    /*
     * O SwayService atualiza os dados.
     *
     * Isso força os delegates da dock a recalcularem
     * quais aplicativos estão abertos.
     */
    Connections {
        target: sway

        function onUpdated() {
            root._badgeTick++
        }
    }

    /*
     * Área invisível usada para detectar o mouse.
     */
    Rectangle {
        id: triggerStrip

        anchors.bottom: parent.bottom
        anchors.horizontalCenter:
            dockBar.horizontalCenter

        width: dockBar.width + 80
        height: 4

        color: "transparent"

        HoverHandler {
            id: triggerHover

            onHoveredChanged: {
                if (hovered)
                    root.showDockBar()
                else
                    root.scheduleHide()
            }
        }
    }

    /*
     * ---------------------------------------------------------
     * Dock
     * ---------------------------------------------------------
     */

    Rectangle {
        id: dockBar

        anchors.horizontalCenter:
            parent.horizontalCenter

        anchors.bottom:
            parent.bottom

        /*
         * Posição original.
         */
        anchors.bottomMargin:
            root.gap

        implicitWidth:
            row.implicitWidth + 16

        implicitHeight:
            row.implicitHeight + 16

        color:
            root.theme.bgBase

        radius: 18

        border.color:
            root.theme.bgBorder

        border.width: 1

        /*
         * Sombra.
         */
        Rectangle {
            anchors.fill: parent

            anchors.topMargin: 4

            radius: 18

            color: "#000000"

            opacity: 0.3

            z: -1
        }

        HoverHandler {
            id: dockHover

            onHoveredChanged: {
                if (hovered)
                    hideTimer.stop()
                else
                    root.scheduleHide()
            }
        }

        /*
         * -----------------------------------------------------
         * Apps
         * -----------------------------------------------------
         */

        RowLayout {
            id: row

            anchors.centerIn: parent

            spacing: 8

            Repeater {
                id: appRepeater

                model:
                    root.orderedApps

                delegate: Item {
                    id: appItem

                    implicitWidth: 40
                    implicitHeight: 40

                    /*
                     * Estado temporário usado durante
                     * abertura do aplicativo.
                     */
                    property bool busy: false

                    /*
                     * Janelas desse aplicativo.
                     *
                     * Vem diretamente do SwayService.
                     */
                    readonly property var windows:
                        root.getWindowsForApp(
                            modelData
                        )

                    readonly property bool isRunning:
                        windows.length > 0

                    readonly property int unreadCount: {
                        /*
                         * Dependência proposital para
                         * atualizar quando o SwayService
                         * receber nova árvore.
                         */
                        var tick = root._badgeTick

                        if (!isRunning)
                            return 0

                        return root.getUnreadCount(
                            windows
                        )
                    }

                    HoverHandler {
                        id: itemHover
                    }

                    /*
                     * Hover visual.
                     */
                    Rectangle {
                        anchors.fill: parent

                        anchors.margins: 2

                        radius: 12

                        color:
                            root.theme.textPrimary

                        opacity:
                            itemHover.hovered
                            ? 0.15
                            : 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 150
                            }
                        }
                    }

                    /*
                     * -------------------------------------------------
                     * Clique no aplicativo
                     * -------------------------------------------------
                     */
                    TapHandler {
                        acceptedButtons:
                            Qt.LeftButton

                        onSingleTapped: {
                            /*
                             * -----------------------------------------
                             * Aplicativo já está aberto
                             * -----------------------------------------
                             */
                            if (isRunning) {
                                const win =
                                    windows[0]

                                /*
                                 * Se estiver no workspace atual,
                                 * movemos para o scratchpad.
                                 */
                                if (
                                    root.isWindowOnCurrentWorkspace(
                                        win
                                    )
                                ) {
                                    if (
                                        modelData.minimizable !== false
                                    ) {
                                        for (
                                            const w of windows
                                        ) {
                                            if (
                                                root.isWindowOnCurrentWorkspace(
                                                    w
                                                )
                                            ) {
                                                sway.moveToScratchpad(
                                                    w.id
                                                )
                                            }
                                        }

                                        return
                                    }

                                    /*
                                     * Se não for minimizável,
                                     * simplesmente foca.
                                     */
                                    sway.focusWindow(
                                        win.id
                                    )

                                    return
                                }

                                /*
                                 * -------------------------------------
                                 * Está no scratchpad
                                 * -------------------------------------
                                 */
                                if (
                                    root.isScratchpadWindow(
                                        win
                                    )
                                ) {
                                    sway.showScratchpad(
                                        win.id
                                    )

                                    return
                                }

                                /*
                                 * -------------------------------------
                                 * Está em outro workspace
                                 * -------------------------------------
                                 *
                                 * Primeiro mudamos para o workspace
                                 * da janela.
                                 */
                                if (
                                    win.workspace &&
                                    win.workspace !==
                                    root.currentWorkspaceName()
                                ) {
                                    sway.switchWorkspace(
                                        win.workspace
                                    )
                                }

                                /*
                                 * Depois focamos a janela.
                                 */
                                sway.focusWindow(
                                    win.id
                                )

                                return
                            }

                            /*
                             * -----------------------------------------
                             * Aplicativo fechado
                             * -----------------------------------------
                             */

                            if (!busy) {
                                busy = true

                                bounceAnimation.start()

                                /*
                                 * Continua usando cmd do
                                 * DockApps.qml.
                                 *
                                 * Nada é fixado aqui.
                                 */
                                const cmdParts =
                                    modelData.cmd
                                        .split(/\s+/)

                                Quickshell.execDetached(
                                    cmdParts
                                )
                            }
                        }
                    }

                    /*
                     * Quando o aplicativo aparecer na árvore
                     * do Sway, encerra a animação de carregamento.
                     */
                    onIsRunningChanged: {
                        if (isRunning)
                            busy = false

                        if (!isRunning)
                            bounceAnimation.stop()

                        iconImg.y = 0
                    }

                    /*
                     * -------------------------------------------------
                     * Animação de abertura
                     * -------------------------------------------------
                     */
                    SequentialAnimation {
                        id: bounceAnimation

                        loops:
                            Animation.Infinite

                        NumberAnimation {
                            target: iconImg

                            property: "y"

                            from: 0
                            to: -6

                            duration: 220

                            easing.type:
                                Easing.OutQuad
                        }

                        NumberAnimation {
                            target: iconImg

                            property: "y"

                            to: 0

                            duration: 220

                            easing.type:
                                Easing.InOutQuad
                        }
                    }

                    /*
                     * -------------------------------------------------
                     * Ícone
                     * -------------------------------------------------
                     *
                     * NÃO é fixo.
                     *
                     * modelData.icon vem de DockApps.qml.
                     */
                    Image {
                        id: iconImg

                        anchors.centerIn:
                            parent

                        source:
                            Quickshell.iconPath(
                                modelData.icon,
                                true
                            )

                        width: 30
                        height: 30

                        fillMode:
                            Image.PreserveAspectFit

                        smooth: true
                    }

                    /*
                     * -------------------------------------------------
                     * Indicador de aplicativo aberto
                     * -------------------------------------------------
                     */
                    Rectangle {
                        visible:
                            isRunning

                        anchors.horizontalCenter:
                            parent.horizontalCenter

                        anchors.bottom:
                            parent.bottom

                        anchors.bottomMargin:
                            -6

                        width: 4
                        height: 4

                        radius: 2

                        color:
                            root.theme.accentPrimary
                    }

                    /*
                     * -------------------------------------------------
                     * Badge de notificações
                     * -------------------------------------------------
                     */
                    Rectangle {
                        visible:
                            unreadCount > 0

                        anchors.top:
                            parent.top

                        anchors.topMargin:
                            -4

                        anchors.right:
                            parent.right

                        anchors.rightMargin:
                            -4

                        width:
                            Math.max(
                                18,
                                badgeText.implicitWidth + 10
                            )

                        height: 18

                        radius: 9

                        color: "#ea4335"

                        border.color:
                            "#1e1e2e"

                        border.width:
                            1.5

                        Text {
                            id: badgeText

                            anchors.centerIn:
                                parent

                            text:
                                unreadCount > 99
                                ? "99+"
                                : unreadCount.toString()

                            color:
                                "#ffffff"

                            font.pixelSize:
                                10

                            font.bold:
                                true
                        }
                    }
                }
            }
        }
    }

    /*
     * Mantido para compatibilidade com a estrutura
     * da dock original.
     *
     * Atualmente não esconde a dock.
     */
    Timer {
        id: hideTimer

        interval: 500

        repeat: false

        onTriggered: {
            root.showDockBar()
        }
    }
}

