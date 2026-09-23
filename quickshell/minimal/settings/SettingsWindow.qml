import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

PanelWindow {
    id: root

    property var theme: null
    property var settings: null

    property string defaultFont: "JetBrains Mono Nerd Font"

    property bool visibleSettings: false
    property bool closing: false

    property string currentPage: "home"

    visible: visibleSettings || closing

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    color: "transparent"
    focusable: true

    function pageSource(page) {
        switch (page) {
        case "home":        return "pages/HomePage.qml"
        case "desktop":     return "pages/DesktopPage.qml"
        case "dock":        return "pages/DockPage.qml"
        case "bar":         return "pages/BarPage.qml"
        case "appearance":  return "pages/AppearancePage.qml"
        case "wallpaper":   return "pages/WallpaperPage.qml"
        case "compositor":  return "pages/CompositorPage.qml"
        case "display":     return "pages/DisplayPage.qml"
        case "network":     return "pages/NetworkPage.qml"
        case "audio":       return "pages/AudioPage.qml"
        case "power":       return "pages/PowerPage.qml"
        case "keyboard":    return "pages/KeyboardPage.qml"
        case "shortcuts":   return "pages/ShortcutsPage.qml"
        case "widgets":     return "pages/WidgetsPage.qml"
        default:            return "pages/HomePage.qml"
        }
    }

    function pageTitle(page) {
        switch (page) {
        case "home":        return "Configurações"
        case "desktop":     return "Desktop"
        case "dock":        return "Dock"
        case "bar":         return "Barra"
        case "appearance":  return "Aparência"
        case "wallpaper":   return "Wallpaper"
        case "compositor":  return "Compositor"
        case "display":     return "Display"
        case "network":     return "Rede"
        case "audio":       return "Áudio"
        case "power":       return "Energia"
        case "keyboard":    return "Teclado"
        case "shortcuts":   return "Atalhos"
        case "widgets":     return "Widgets"
        default:            return "Configurações"
        }
    }

    function openPage(page) {
        currentPage = page
    }

    function openSettings() {
        closing = false
        visibleSettings = true
        currentPage = "home"

        settingsFocus.forceActiveFocus()
    }

    function closeSettings() {
        visibleSettings = false
        closing = true

        closeTimer.restart()
    }

    function finishClose() {
        if (!visibleSettings)
            closing = false
    }

    // ============================================================
    // FOCO
    // ============================================================

    Item {
        id: settingsFocus

        anchors.fill: parent

        focus: true

        Keys.onEscapePressed: {
            if (root.currentPage !== "home") {
                root.currentPage = "home"
            } else {
                root.closeSettings()
            }

            event.accepted = true
        }
    }

    // ============================================================
    // OVERLAY
    // ============================================================

    Rectangle {
        anchors.fill: parent

        color: "#000000"
        opacity: 0.45

        MouseArea {
            anchors.fill: parent

            onClicked: {
                root.closeSettings()
            }
        }
    }

    // ============================================================
    // PAINEL
    // ============================================================

    Rectangle {
        id: panel

        anchors.centerIn: parent

        width: Math.min(
            900,
            Math.max(
                360,
                root.width - 24
            )
        )

        height: Math.min(
            620,
            Math.max(
                280,
                root.height - 24
            )
        )

        radius: root.settings &&
                root.settings.panelRadius !== undefined
                ? root.settings.panelRadius
                : 14

        color: root.theme &&
               root.theme.bgSurface !== undefined
               ? root.theme.bgSurface
               : "#202020"

        border.width: 1

        border.color: root.theme &&
                      root.theme.bgBorder !== undefined
                      ? root.theme.bgBorder
                      : "#383838"

        clip: true

        // ========================================================
        // HEADER
        // ========================================================

        Rectangle {
            id: header

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            height: 58

            color: "transparent"

            RowLayout {
                anchors.fill: parent

                anchors.leftMargin: 12
                anchors.rightMargin: 12

                spacing: 8

                // VOLTAR
                Rectangle {
                    visible: root.currentPage !== "home"

                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34

                    radius: 8

                    color: backMouse.containsMouse
                           ? root.theme.bgHover
                           : "transparent"

                    Text {
                        anchors.centerIn: parent

                        text: "‹"

                        color: root.theme.textPrimary

                        font.family: root.defaultFont
                        font.pixelSize: 24
                    }

                    MouseArea {
                        id: backMouse

                        anchors.fill: parent

                        hoverEnabled: true

                        onClicked: {
                            root.currentPage = "home"
                        }
                    }
                }

                // TITULO
                Text {
                    text: root.pageTitle(root.currentPage)

                    color: root.theme.textPrimary

                    font.family: root.defaultFont
                    font.pixelSize: 17
                    font.bold: true

                    elide: Text.ElideRight

                    Layout.fillWidth: true
                }

                // FECHAR
                Rectangle {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34

                    radius: 8

                    color: closeMouse.containsMouse
                           ? root.theme.bgHover
                           : "transparent"

                    Text {
                        anchors.centerIn: parent

                        text: "×"

                        color: root.theme.textSecondary

                        font.family: root.defaultFont
                        font.pixelSize: 21
                    }

                    MouseArea {
                        id: closeMouse

                        anchors.fill: parent

                        hoverEnabled: true

                        onClicked: {
                            root.closeSettings()
                        }
                    }
                }
            }
        }

        // ========================================================
        // LINHA
        // ========================================================

        Rectangle {
            anchors.top: header.bottom

            anchors.left: parent.left
            anchors.right: parent.right

            height: 1

            color: root.theme &&
                   root.theme.bgBorder !== undefined
                   ? root.theme.bgBorder
                   : "#383838"
        }

        // ========================================================
        // CONTEÚDO
        // ========================================================

        RowLayout {
            id: contentArea

            anchors.top: header.bottom

            anchors.left: parent.left
            anchors.right: parent.right

            anchors.bottom: parent.bottom

            spacing: 0

            // ====================================================
            // SIDEBAR
            // ====================================================

            Rectangle {
                visible: root.currentPage === "home"

                Layout.preferredWidth: Math.min(
                    205,
                    Math.max(
                        150,
                        panel.width * 0.30
                    )
                )

                Layout.fillHeight: true

                color: root.theme &&
                       root.theme.bgSurface !== undefined
                       ? root.theme.bgSurface
                       : "#202020"

                clip: true

                ScrollView {
                    id: sidebarScroll

                    anchors.fill: parent

                    clip: true

                    ScrollBar.vertical.policy:
                        ScrollBar.AsNeeded

                    ScrollBar.horizontal.policy:
                        ScrollBar.AlwaysOff

                    ColumnLayout {
                        id: sidebarColumn

                        /*
                         * O ColumnLayout recebe exatamente a largura
                         * disponível da sidebar.
                         */
                        width: Math.max(
                            0,
                            sidebarScroll.availableWidth - 16
                        )

                        x: 8
                        y: 8

                        spacing: 3

                        // ==================================================
                        // SHELL
                        // ==================================================

                        Text {
                            text: "SHELL"

                            color: root.theme.textSecondary

                            font.family: root.defaultFont
                            font.pixelSize: 10
                            font.bold: true

                            leftPadding: 8

                            Layout.fillWidth: true

                            Layout.topMargin: 4
                            Layout.bottomMargin: 4
                        }

                        SettingsMenuItem {
                            theme: root.theme
                            text: "Desktop"
                            icon: "󰍹"

                            onClicked: {
                                root.openPage("desktop")
                            }
                        }

                        SettingsMenuItem {
                            theme: root.theme
                            text: "Dock"
                            icon: "󰄀"

                            onClicked: {
                                root.openPage("dock")
                            }
                        }

                        SettingsMenuItem {
                            theme: root.theme
                            text: "Barra"
                            icon: "󰕮"

                            onClicked: {
                                root.openPage("bar")
                            }
                        }

                        // ==================================================
                        // APARÊNCIA
                        // ==================================================

                        Text {
                            text: "APARÊNCIA"

                            color: root.theme.textSecondary

                            font.family: root.defaultFont
                            font.pixelSize: 10
                            font.bold: true

                            leftPadding: 8

                            Layout.fillWidth: true

                            Layout.topMargin: 14
                            Layout.bottomMargin: 4
                        }

                        SettingsMenuItem {
                            theme: root.theme
                            text: "Aparência"
                            icon: "󰏘"

                            onClicked: {
                                root.openPage("appearance")
                            }
                        }

                        SettingsMenuItem {
                            theme: root.theme
                            text: "Wallpaper"
                            icon: "󰸉"

                            onClicked: {
                                root.openPage("wallpaper")
                            }
                        }

                        // ==================================================
                        // SISTEMA
                        // ==================================================

                        Text {
                            text: "SISTEMA"

                            color: root.theme.textSecondary

                            font.family: root.defaultFont
                            font.pixelSize: 10
                            font.bold: true

                            leftPadding: 8

                            Layout.fillWidth: true

                            Layout.topMargin: 14
                            Layout.bottomMargin: 4
                        }

                        SettingsMenuItem {
                            theme: root.theme
                            text: "Compositor"
                            icon: "󰖯"

                            onClicked: {
                                root.openPage("compositor")
                            }
                        }

                        SettingsMenuItem {
                            theme: root.theme
                            text: "Display"
                            icon: "󰍹"

                            onClicked: {
                                root.openPage("display")
                            }
                        }

                        SettingsMenuItem {
                            theme: root.theme
                            text: "Rede"
                            icon: "󰖩"

                            onClicked: {
                                root.openPage("network")
                            }
                        }

                        SettingsMenuItem {
                            theme: root.theme
                            text: "Áudio"
                            icon: "󰕾"

                            onClicked: {
                                root.openPage("audio")
                            }
                        }

                        SettingsMenuItem {
                            theme: root.theme
                            text: "Energia"
                            icon: "󰂄"

                            onClicked: {
                                root.openPage("power")
                            }
                        }

                        // ==================================================
                        // ENTRADA
                        // ==================================================

                        SettingsMenuItem {
                            theme: root.theme
                            text: "Teclado"
                            icon: "󰌌"

                            onClicked: {
                                root.openPage("keyboard")
                            }
                        }

                        SettingsMenuItem {
                            theme: root.theme
                            text: "Atalhos"
                            icon: "󰌆"

                            onClicked: {
                                root.openPage("shortcuts")
                            }
                        }

                        // ==================================================
                        // WIDGETS
                        // ==================================================

                        Text {
                            text: "WIDGETS"

                            color: root.theme.textSecondary

                            font.family: root.defaultFont
                            font.pixelSize: 10
                            font.bold: true

                            leftPadding: 8

                            Layout.fillWidth: true

                            Layout.topMargin: 14
                            Layout.bottomMargin: 4
                        }

                        SettingsMenuItem {
                            theme: root.theme
                            text: "Widgets"
                            icon: "󰝖"

                            onClicked: {
                                root.openPage("widgets")
                            }
                        }

                        Item {
                            Layout.preferredHeight: 20
                        }
                    }
                }
            }

            // ====================================================
            // ÁREA DAS PÁGINAS
            // ====================================================

            Rectangle {
                id: pageContainer

                Layout.fillWidth: true
                Layout.fillHeight: true

                color: "transparent"

                /*
                 * NÃO colocar ScrollView aqui.
                 *
                 * HomePage.qml já possui:
                 *
                 * ScrollView {
                 *     anchors.fill: parent
                 *     ...
                 * }
                 *
                 * As outras páginas também podem controlar
                 * seu próprio conteúdo.
                 */
                Loader {
                    id: pageLoader

                    anchors.fill: parent

                    active: root.visibleSettings ||
                            root.closing

                    asynchronous: false

                    source: root.pageSource(
                        root.currentPage
                    )

                    onLoaded: {
                        if (!item)
                            return

                        item.theme = root.theme
                        item.settings = root.settings

                        if (item.navigate !== undefined) {
                            item.navigate = function(page) {
                                root.openPage(page)
                            }
                        }
                    }
                }
            }
        }
    }

    // ============================================================
    // TIMER
    // ============================================================

    Timer {
        id: closeTimer

        interval: 180

        repeat: false

        onTriggered: {
            root.finishClose()
        }
    }
}
