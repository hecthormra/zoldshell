import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

import "."

import "../theme_switcher"
import "../bar"
import "../services"

PanelWindow {
    id: desktop

    property var theme
    property var settings: null

    Connections {
        target: desktop.settings

        function onDesktopWidgetsVisibleChanged() {
            console.log(
                "DESKTOP VISIBLE MUDOU:",
                desktop.settings.desktopWidgetsVisible
           )
       }
  }

    property bool desktopEnabled: true
    property int barSize: 40
    
    property int iconSize:
        desktop.settings
        ? desktop.settings.desktopIconSize
        : 48

    property int spacingVertical:
        desktop.settings
        ? desktop.settings.desktopSpacing
        : 12
    
    property int iconCellExtra: 40
    property int animationDuration: 150
    property string defaultFont: "JetBrains Mono Nerd Font"

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    color: "transparent"

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "shell:desktop"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    
    visible: desktop.settings
        ? desktop.settings.desktopWidgetsVisible
        : desktop.desktopEnabled


    Component.onCompleted: {
        DesktopService.initialize()

        DesktopService.maxRowsHint =
            Qt.binding(function() {
                return iconContainer.maxRows
            })

        DesktopService.maxColumnsHint =
            Qt.binding(function() {
                return iconContainer.maxColumns
            })
    }


    /*
     * ============================================================
     * GRID DO DESKTOP
     * ============================================================
     */

    Item {
        id: iconContainer
        

        anchors.fill: parent

        anchors.margins: 16
        anchors.bottomMargin: barSize + 16
        anchors.topMargin: barSize + 16
        anchors.leftMargin: 16
        anchors.rightMargin: 16

        property int cellHeight:
            iconSize + iconCellExtra + spacingVertical

        property int cellWidth:
            cellHeight

        property int maxRows:
            Math.max(
                1,
                Math.floor(
                    height / cellHeight
                )
            )

        property int maxColumns:
            Math.max(
                1,
                Math.floor(
                    width / cellWidth
                )
            )

        Repeater {
            model: DesktopService.items

            delegate: Item {
                id: delegateRoot

                required property string name
                required property string path
                required property string type
                required property string icon
                required property bool isDesktopFile
                required property bool isPlaceholder
                required property int index

                width:
                    iconContainer.cellWidth

                height:
                    iconContainer.cellHeight

                x:
                    Math.floor(
                        index /
                        iconContainer.maxRows
                    ) *
                    iconContainer.cellWidth

                y:
                    (
                        index %
                        iconContainer.maxRows
                    ) *
                    iconContainer.cellHeight

                visible:
                    !isPlaceholder

                Behavior on x {
                    enabled:
                        desktop.animationDuration > 0 &&
                        !dragHandler.active

                    NumberAnimation {
                        duration:
                            desktop.animationDuration

                        easing.type:
                            Easing.OutCubic
                    }
                }

                Behavior on y {
                    enabled:
                        desktop.animationDuration > 0 &&
                        !dragHandler.active

                    NumberAnimation {
                        duration:
                            desktop.animationDuration

                        easing.type:
                            Easing.OutCubic
                    }
                }

                DesktopIcon {
                    id: iconItem

                    anchors.fill: parent

                    itemName:
                        delegateRoot.name

                    itemPath:
                        delegateRoot.path

                    itemType:
                        delegateRoot.type

                    itemIcon:
                        delegateRoot.icon

                    isDesktopFile:
                        delegateRoot.isDesktopFile

                    onActivated: {
                        console.log(
                            "Activated:",
                            itemName
                        )
                    }

                    onContextMenuRequested: {

                        desktopMenu.selectedPath =
                            delegateRoot.path

                        desktopMenu.selectedName =
                            delegateRoot.name

                        desktopMenu.selectedType =
                            delegateRoot.type

                        desktopMenu.selectedIsDesktopFile =
                            delegateRoot.isDesktopFile

                        desktopMenu.selectedIndex =
                            delegateRoot.index

                        desktopMenu.openForIcon(
                            iconItem.x +
                            iconItem.width / 2,
                            iconItem.y +
                            iconItem.height / 2
                        )
                    }

                    opacity:
                        dragHandler.active
                        ? 0.3
                        : 1.0

                    Behavior on opacity {
                        enabled:
                            desktop.animationDuration > 0

                        NumberAnimation {
                            duration:
                                desktop.animationDuration / 2

                            easing.type:
                                Easing.OutCubic
                        }
                    }

                    DragHandler {
                        id: dragHandler

                        target: dragPreview

                        onActiveChanged: {

                            if (!active) {

                                var targetIndex =
                                    delegateRoot.index

                                if (
                                    dragPreview.Drag.target &&
                                    dragPreview.Drag.target.visualIndex
                                    !== undefined
                                ) {

                                    targetIndex =
                                        dragPreview.Drag.target.visualIndex

                                } else {

                                    var gridPos =
                                        iconContainer.mapFromItem(
                                            dragPreview.parent,
                                            dragPreview.x,
                                            dragPreview.y
                                        )

                                    var dropX =
                                        gridPos.x +
                                        dragPreview.width / 2

                                    var dropY =
                                        gridPos.y +
                                        dragPreview.height / 2

                                    if (
                                        dropX >= 0 &&
                                        dropY >= 0 &&
                                        dropX <
                                        iconContainer.width &&
                                        dropY <
                                        iconContainer.height
                                    ) {

                                        var col =
                                            Math.floor(
                                                dropX /
                                                iconContainer.cellWidth
                                            )

                                        var row =
                                            Math.floor(
                                                dropY /
                                                iconContainer.cellHeight
                                            )

                                        col =
                                            Math.max(
                                                0,
                                                Math.min(
                                                    col,
                                                    iconContainer.maxColumns - 1
                                                )
                                            )

                                        row =
                                            Math.max(
                                                0,
                                                Math.min(
                                                    row,
                                                    iconContainer.maxRows - 1
                                                )
                                            )

                                        targetIndex =
                                            col *
                                            iconContainer.maxRows +
                                            row
                                    }
                                }

                                if (
                                    targetIndex !==
                                    delegateRoot.index
                                ) {

                                    DesktopService.moveItem(
                                        delegateRoot.index,
                                        targetIndex
                                    )
                                }

                                dragPreview.Drag.drop()
                            }
                        }
                    }
                }

                Item {
                    id: dragPreview

                    parent:
                        iconContainer

                    width:
                        delegateRoot.width

                    height:
                        delegateRoot.height

                    visible:
                        dragHandler.active

                    z: 999

                    DesktopIcon {
                        anchors.fill:
                            parent

                        itemName:
                            delegateRoot.name

                        itemPath:
                            delegateRoot.path

                        itemType:
                            delegateRoot.type

                        itemIcon:
                            delegateRoot.icon

                        isDesktopFile:
                            delegateRoot.isDesktopFile

                        opacity: 0.7
                        scale: 1.05
                    }

                    Drag.active:
                        dragHandler.active

                    Drag.source:
                        delegateRoot

                    Drag.hotSpot.x:
                        width / 2

                    Drag.hotSpot.y:
                        height / 2

                    Drag.keys:
                        ["desktopIcon"]
                }

                DropArea {
                    anchors.fill:
                        parent

                    keys:
                        ["desktopIcon"]

                    property int visualIndex:
                        delegateRoot.index

                    Rectangle {
                        anchors.fill:
                            parent

                        color:
                            "transparent"

                        border.color:
                            desktop.theme
                            ? desktop.theme.accentPrimary
                            : "transparent"

                        border.width:
                            2

                        radius:
                            4

                        visible:
                            parent.containsDrag

                        opacity:
                            0.5
                    }
                }
            }
        }
    }


    /*
     * ============================================================
     * CLIQUE DIREITO NO DESKTOP
     * ============================================================
     */

    MouseArea {
        id: desktopMouseArea

        anchors.fill:
            iconContainer

        z: -1

        acceptedButtons:
            Qt.RightButton

        propagateComposedEvents:
            true

        onClicked: function(mouse) {

            if (
                mouse.button ===
                Qt.RightButton
            ) {

                desktopMenu.clearSelection()

                desktopMenu.openForDesktop(
                    mouse.x,
                    mouse.y
                )
            }
        }
    }


    /*
     * ============================================================
     * MENU
     * ============================================================
     */

    Rectangle {
        id: desktopMenu

        property string selectedPath: ""
        property string selectedName: ""
        property string selectedType: ""
        property bool selectedIsDesktopFile: false
        property int selectedIndex: -1

        property bool iconSelected: false

        width: 230

        height:
            menuColumn.implicitHeight + 12

        color:
            desktop.theme
            ? desktop.theme.bgSurface
            : "transparent"

        border.color:
            desktop.theme
            ? desktop.theme.bgBorder
            : "transparent"

        border.width:
            1

        radius:
            8

        visible:
            false

        z:
            10000


        function clearSelection() {

            selectedPath = ""
            selectedName = ""
            selectedType = ""
            selectedIsDesktopFile = false
            selectedIndex = -1
            iconSelected = false
        }


        function openForDesktop(px, py) {

            clearSelection()

            openAt(
                px,
                py
            )
        }


        function openForIcon(px, py) {

            iconSelected = true

            openAt(
                px,
                py
            )
        }


        function openAt(px, py) {

            visible = true

            x =
                Math.max(
                    4,
                    Math.min(
                        px,
                        desktop.width -
                        width -
                        4
                    )
                )

            y =
                Math.max(
                    4,
                    Math.min(
                        py,
                        desktop.height -
                        height -
                        4
                    )
                )
        }


        function closeMenu() {

            visible = false
        }


        Column {
            id: menuColumn

            anchors.left:
                parent.left

            anchors.right:
                parent.right

            anchors.top:
                parent.top

            anchors.margins:
                6

            spacing:
                2


            /*
             * ====================================================
             * ABRIR
             * ====================================================
             */

            Rectangle {
                visible:
                    desktopMenu.iconSelected

                width:
                    parent.width

                height:
                    30

                radius:
                    5

                color:
                    openArea.containsMouse &&
                    desktop.theme
                    ? desktop.theme.bgHover
                    : "transparent"

                Text {
                    anchors.fill:
                        parent

                    anchors.leftMargin:
                        10

                    text:
                        "󰮂  Abrir"

                    color:
                        desktop.theme
                        ? desktop.theme.textPrimary
                        : "transparent"

                    font.family:
                        desktop.defaultFont

                    font.pixelSize:
                        11

                    verticalAlignment:
                        Text.AlignVCenter
                }

                MouseArea {
                    id: openArea

                    anchors.fill:
                        parent

                    hoverEnabled:
                        true

                    onClicked: {

                        desktopMenu.closeMenu()

                        if (
                            desktopMenu.selectedIsDesktopFile
                        ) {

                            DesktopService.executeDesktopFile(
                                desktopMenu.selectedPath
                            )

                        } else {

                            DesktopService.openFile(
                                desktopMenu.selectedPath
                            )
                        }
                    }
                }
            }


            /*
             * ====================================================
             * REMOVER ÍCONE
             * ====================================================
             */

            Rectangle {
                visible:
                    desktopMenu.iconSelected

                width:
                    parent.width

                height:
                    30

                radius:
                    5

                color:
                    removeArea.containsMouse &&
                    desktop.theme
                    ? desktop.theme.bgHover
                    : "transparent"

                Text {
                    anchors.fill:
                        parent

                    anchors.leftMargin:
                        10

                    text:
                        "󰆴  Remover ícone"

                    color:
                        desktop.theme
                        ? desktop.theme.textPrimary
                        : "transparent"

                    font.family:
                        desktop.defaultFont

                    font.pixelSize:
                        11

                    verticalAlignment:
                        Text.AlignVCenter
                }

                MouseArea {
                    id: removeArea

                    anchors.fill:
                        parent

                    hoverEnabled:
                        true

                    onClicked: {

                        var path =
                            desktopMenu.selectedPath

                        desktopMenu.closeMenu()

                        if (
                            path !== ""
                        ) {

                            DesktopService.removeDesktopItem(
                                path
                            )
                        }
                    }
                }
            }


            /*
             * ====================================================
             * MOSTRAR NOVAMENTE
             * ====================================================
             */

            Rectangle {
                width:
                    parent.width

                height:
                    30

                radius:
                    5

                color:
                    restoreArea.containsMouse &&
                    desktop.theme
                    ? desktop.theme.bgHover
                    : "transparent"

                Text {
                    anchors.fill:
                        parent

                    anchors.leftMargin:
                        10

                    text:
                        "󰁮  Mostrar novamente"

                    color:
                        desktop.theme
                        ? desktop.theme.textPrimary
                        : "transparent"

                    font.family:
                        desktop.defaultFont

                    font.pixelSize:
                        11

                    verticalAlignment:
                        Text.AlignVCenter
                }

                MouseArea {
                    id: restoreArea

                    anchors.fill:
                        parent

                    hoverEnabled:
                        true

                    onClicked: {

                        desktopMenu.closeMenu()

                        restoreHiddenPopup.open()
                    }
                }
            }


            Rectangle {
                visible:
                    desktopMenu.iconSelected

                width:
                    parent.width

                height:
                    1

                color:
                    desktop.theme
                    ? desktop.theme.bgBorder
                    : "transparent"
            }


            /*
             * ====================================================
             * NOVA PASTA
             * ====================================================
             */

            Rectangle {
                width:
                    parent.width

                height:
                    30

                radius:
                    5

                color:
                    newFolderArea.containsMouse &&
                    desktop.theme
                    ? desktop.theme.bgHover
                    : "transparent"

                Text {
                    anchors.fill:
                        parent

                    anchors.leftMargin:
                        10

                    text:
                        "󰉋  Nova pasta"

                    color:
                        desktop.theme
                        ? desktop.theme.textPrimary
                        : "transparent"

                    font.family:
                        desktop.defaultFont

                    font.pixelSize:
                        11

                    verticalAlignment:
                        Text.AlignVCenter
                }

                MouseArea {
                    id: newFolderArea

                    anchors.fill:
                        parent

                    hoverEnabled:
                        true

                    onClicked: {

                        desktopMenu.closeMenu()

                        nameDialog.mode =
                            "folder"

                        nameDialog.open()
                    }
                }
            }


            /*
             * ====================================================
             * NOVO ARQUIVO
             * ====================================================
             */

            Rectangle {
                width:
                    parent.width

                height:
                    30

                radius:
                    5

                color:
                    newFileArea.containsMouse &&
                    desktop.theme
                    ? desktop.theme.bgHover
                    : "transparent"

                Text {
                    anchors.fill:
                        parent

                    anchors.leftMargin:
                        10

                    text:
                        "󰈔  Novo arquivo"

                    color:
                        desktop.theme
                        ? desktop.theme.textPrimary
                        : "transparent"

                    font.family:
                        desktop.defaultFont

                    font.pixelSize:
                        11

                    verticalAlignment:
                        Text.AlignVCenter
                }

                MouseArea {
                    id: newFileArea

                    anchors.fill:
                        parent

                    hoverEnabled:
                        true

                    onClicked: {

                        desktopMenu.closeMenu()

                        nameDialog.mode =
                            "file"

                        nameDialog.open()
                    }
                }
            }


            /*
             * ====================================================
             * WALLPAPER
             * ====================================================
             */

            Rectangle {
                width:
                    parent.width

                height:
                    30

                radius:
                    5

                color:
                    wallpaperArea.containsMouse &&
                    desktop.theme
                    ? desktop.theme.bgHover
                    : "transparent"

                Text {
                    anchors.fill:
                        parent

                    anchors.leftMargin:
                        10

                    text:
                        "󰸉  Trocar wallpaper"

                    color:
                        desktop.theme
                        ? desktop.theme.textPrimary
                        : "transparent"

                    font.family:
                        desktop.defaultFont

                    font.pixelSize:
                        11

                    verticalAlignment:
                        Text.AlignVCenter
                }

                MouseArea {
                    id: wallpaperArea

                    anchors.fill:
                        parent

                    hoverEnabled:
                        true

                    onClicked: {

                        desktopMenu.closeMenu()

                        changeWallpaper()
                    }
                }
            }


            /*
             * ====================================================
             * WIDGET
             * ====================================================
             */

            Rectangle {
                width:
                    parent.width

                height:
                    30

                radius:
                    5

                color:
                    widgetArea.containsMouse &&
                    desktop.theme
                    ? desktop.theme.bgHover
                    : "transparent"

                Text {
                    anchors.fill:
                        parent

                    anchors.leftMargin:
                        10

                    text:
                        "󰐕  Adicionar widget"

                    color:
                        desktop.theme
                        ? desktop.theme.textPrimary
                        : "transparent"

                    font.family:
                        desktop.defaultFont

                    font.pixelSize:
                        11

                    verticalAlignment:
                        Text.AlignVCenter
                }

                MouseArea {
                    id: widgetArea

                    anchors.fill:
                        parent

                    hoverEnabled:
                        true

                    onClicked: {

                        desktopMenu.closeMenu()

                        addWidget()
                    }
                }
            }


            Rectangle {
                width:
                    parent.width

                height:
                    1

                color:
                    desktop.theme
                    ? desktop.theme.bgBorder
                    : "transparent"
            }


            /*
             * ====================================================
             * ATUALIZAR
             * ====================================================
             */

            Rectangle {
                width:
                    parent.width

                height:
                    30

                radius:
                    5

                color:
                    refreshArea.containsMouse &&
                    desktop.theme
                    ? desktop.theme.bgHover
                    : "transparent"

                Text {
                    anchors.fill:
                        parent

                    anchors.leftMargin:
                        10

                    text:
                        "󰑐  Atualizar"

                    color:
                        desktop.theme
                        ? desktop.theme.textPrimary
                        : "transparent"

                    font.family:
                        desktop.defaultFont

                    font.pixelSize:
                        11

                    verticalAlignment:
                        Text.AlignVCenter
                }

                MouseArea {
                    id: refreshArea

                    anchors.fill:
                        parent

                    hoverEnabled:
                        true

                    onClicked: {

                        desktopMenu.closeMenu()

                        DesktopService.scanDesktop()
                    }
                }
            }


            /*
             * ====================================================
             * CONFIGURAÇÕES
             * ====================================================
             */

            Rectangle {
                width:
                    parent.width

                height:
                    30

                radius:
                    5

                color:
                    settingsArea.containsMouse &&
                    desktop.theme
                    ? desktop.theme.bgHover
                    : "transparent"

                Text {
                    anchors.fill:
                        parent

                    anchors.leftMargin:
                        10

                    text:
                        "󰒓  Configurações"

                    color:
                        desktop.theme
                        ? desktop.theme.textPrimary
                        : "transparent"

                    font.family:
                        desktop.defaultFont

                    font.pixelSize:
                        11

                    verticalAlignment:
                        Text.AlignVCenter
                }

                MouseArea {
                    id: settingsArea

                    anchors.fill:
                        parent

                    hoverEnabled:
                        true

                    onClicked: {

                        desktopMenu.closeMenu()

                        settingsWindow.visible =
                            true
                    }
                }
            }
        }
    }


    /*
     * ============================================================
     * POPUP — ITENS OCULTOS
     * ============================================================
     */

    Popup {
        id: restoreHiddenPopup

        parent:
            Overlay.overlay

        anchors.centerIn:
            parent

        width:
            340

        height:
            Math.min(
                460,
                120 +
                hiddenItemsModel.count * 44
            )

        modal:
            true

        focus:
            true

        closePolicy:
            Popup.CloseOnEscape |
            Popup.CloseOnPressOutside

        background: Rectangle {

            color:
                desktop.theme
                ? desktop.theme.bgSurface
                : "transparent"

            border.color:
                desktop.theme
                ? desktop.theme.bgBorder
                : "transparent"

            border.width:
                1

            radius:
                10
        }


        ListModel {
            id: hiddenItemsModel
        }


        function reloadHiddenItems() {

            hiddenItemsModel.clear()

            var hidden =
                DesktopService.hiddenItems

            var paths =
                Object.keys(hidden)

            for (
                var i = 0;
                i < paths.length;
                i++
            ) {

                var path =
                    paths[i]

                if (
                    hidden[path] !== true
                ) {
                    continue
                }

                var parts =
                    path.split("/")

                var name =
                    parts.length > 0
                    ? parts[parts.length - 1]
                    : path

                hiddenItemsModel.append({
                    path: path,
                    name: name
                })
            }
        }


        onOpened: {

            reloadHiddenItems()
        }


        Column {
            anchors.fill:
                parent

            anchors.margins:
                12

            spacing:
                8


            Text {
                width:
                    parent.width

                text:
                    "Itens ocultos"

                color:
                    desktop.theme
                    ? desktop.theme.textPrimary
                    : "transparent"

                font.family:
                    desktop.defaultFont

                font.pixelSize:
                    14

                font.bold:
                    true
            }


            Text {
                width:
                    parent.width

                text:
                    "Escolha um item para mostrar novamente."

                color:
                    desktop.theme
                    ? desktop.theme.textSecondary
                    : "transparent"

                font.family:
                    desktop.defaultFont

                font.pixelSize:
                    10
            }


            Rectangle {
                width:
                    parent.width

                height:
                    1

                color:
                    desktop.theme
                    ? desktop.theme.bgBorder
                    : "transparent"
            }


            Item {
                width:
                    parent.width

                height:
                    parent.height - 108


                Text {
                    anchors.centerIn:
                        parent

                    visible:
                        hiddenItemsModel.count === 0

                    text:
                        "Nenhum item oculto"

                    color:
                        desktop.theme
                        ? desktop.theme.textSecondary
                        : "transparent"

                    font.family:
                        desktop.defaultFont

                    font.pixelSize:
                        11
                }


                ListView {
                    id: hiddenList

                    anchors.fill:
                        parent

                    clip:
                        true

                    visible:
                        hiddenItemsModel.count > 0

                    model:
                        hiddenItemsModel

                    spacing:
                        2

                    delegate: Rectangle {

                        width:
                            hiddenList.width

                        height:
                            40

                        radius:
                            6

                        color:
                            hiddenItemArea.containsMouse &&
                            desktop.theme
                            ? desktop.theme.bgHover
                            : "transparent"


                        Row {
                            anchors.fill:
                                parent

                            anchors.leftMargin:
                                8

                            anchors.rightMargin:
                                8

                            spacing:
                                8


                            Text {
                                width:
                                    26

                                height:
                                    parent.height

                                text:
                                    "󰉖"

                                color:
                                    desktop.theme
                                    ? desktop.theme.accentPrimary
                                    : "transparent"

                                font.family:
                                    desktop.defaultFont

                                font.pixelSize:
                                    16

                                horizontalAlignment:
                                    Text.AlignHCenter

                                verticalAlignment:
                                    Text.AlignVCenter
                            }


                            Text {
                                width:
                                    parent.width - 70

                                height:
                                    parent.height

                                text:
                                    model.name

                                color:
                                    desktop.theme
                                    ? desktop.theme.textPrimary
                                    : "transparent"

                                font.family:
                                    desktop.defaultFont

                                font.pixelSize:
                                    11

                                elide:
                                    Text.ElideMiddle

                                verticalAlignment:
                                    Text.AlignVCenter
                            }


                            Text {
                                width:
                                    28

                                height:
                                    parent.height

                                text:
                                    "󰁮"

                                color:
                                    desktop.theme
                                    ? desktop.theme.accentPrimary
                                    : "transparent"

                                font.family:
                                    desktop.defaultFont

                                font.pixelSize:
                                    14

                                horizontalAlignment:
                                    Text.AlignHCenter

                                verticalAlignment:
                                    Text.AlignVCenter
                            }
                        }


                        MouseArea {
                            id: hiddenItemArea

                            anchors.fill:
                                parent

                            hoverEnabled:
                                true

                            onClicked: {

                                var path =
                                    model.path

                                DesktopService.showItem(
                                    path
                                )

                                hiddenItemsModel.remove(
                                    index
                                )

                                if (
                                    hiddenItemsModel.count === 0
                                ) {

                                    restoreHiddenPopup.close()
                                }
                            }
                        }
                    }
                }
            }


            Button {
                width:
                    parent.width

                height:
                    30

                text:
                    "Fechar"

                onClicked: {

                    restoreHiddenPopup.close()
                }

                contentItem: Text {

                    text:
                        parent.text

                    color:
                        desktop.theme
                        ? desktop.theme.accentPrimary
                        : "transparent"

                    font.family:
                        desktop.defaultFont

                    font.pixelSize:
                        11

                    horizontalAlignment:
                        Text.AlignHCenter

                    verticalAlignment:
                        Text.AlignVCenter
                }

                background: Rectangle {

                    color:
                        parent.hovered &&
                        desktop.theme
                        ? desktop.theme.bgHover
                        : "transparent"

                    border.color:
                        desktop.theme
                        ? desktop.theme.accentPrimary
                        : "transparent"

                    border.width:
                        1

                    radius:
                        6
                }
            }
        }
    }


    /*
     * ============================================================
     * JANELA PARA NOMEAR ARQUIVO / PASTA
     * ============================================================
     */

    Popup {
        id: nameDialog

        property string mode:
            "folder"

        parent:
            Overlay.overlay

        anchors.centerIn:
            parent

        width:
            360

        padding:
            16

        modal:
            true

        focus:
            true

        closePolicy:
            Popup.CloseOnEscape

        background: Rectangle {

            color:
                desktop.theme
                ? desktop.theme.bgSurface
                : "transparent"

            border.color:
                desktop.theme
                ? desktop.theme.bgBorder
                : "transparent"

            border.width:
                1

            radius:
                10
        }


        ColumnLayout {

            width:
                parent.width

            spacing:
                10


            Text {

                Layout.fillWidth:
                    true

                text:
                    nameDialog.mode === "folder"
                    ? "Nova pasta"
                    : "Novo arquivo"

                color:
                    desktop.theme
                    ? desktop.theme.textPrimary
                    : "transparent"

                font.family:
                    desktop.defaultFont

                font.pixelSize:
                    15

                font.bold:
                    true
            }


            Text {

                Layout.fillWidth:
                    true

                text:
                    nameDialog.mode === "folder"
                    ? "Digite o nome da pasta:"
                    : "Digite o nome do arquivo:"

                color:
                    desktop.theme
                    ? desktop.theme.textSecondary
                    : "transparent"

                font.family:
                    desktop.defaultFont

                font.pixelSize:
                    11
            }


            TextField {
                id: nameField

                Layout.fillWidth:
                    true

                placeholderText:
                    nameDialog.mode === "folder"
                    ? "Nome da pasta"
                    : "Nome do arquivo"

                color:
                    desktop.theme
                    ? desktop.theme.textPrimary
                    : "transparent"

                font.family:
                    desktop.defaultFont

                font.pixelSize:
                    11

                background: Rectangle {

                    color:
                        desktop.theme
                        ? desktop.theme.bgSurface
                        : "transparent"

                    border.color:
                        desktop.theme
                        ? desktop.theme.bgBorder
                        : "transparent"

                    border.width:
                        1

                    radius:
                        6
                }

                Keys.onReturnPressed: {

                    nameDialog.create()
                }

                onAccepted: {

                    nameDialog.create()
                }
            }


            RowLayout {

                Layout.fillWidth:
                    true

                spacing:
                    6


                Item {
                    Layout.fillWidth:
                        true
                }


                Button {

                    text:
                        "Cancelar"

                    onClicked: {

                        nameDialog.close()
                    }

                    contentItem: Text {

                        text:
                            parent.text

                        color:
                            desktop.theme
                            ? desktop.theme.textPrimary
                            : "transparent"

                        font.family:
                            desktop.defaultFont

                        font.pixelSize:
                            11

                        horizontalAlignment:
                            Text.AlignHCenter

                        verticalAlignment:
                            Text.AlignVCenter
                    }

                    background: Rectangle {

                        color:
                            parent.hovered &&
                            desktop.theme
                            ? desktop.theme.bgHover
                            : "transparent"

                        border.color:
                            desktop.theme
                            ? desktop.theme.bgBorder
                            : "transparent"

                        border.width:
                            1

                        radius:
                            6
                    }
                }


                Button {

                    text:
                        nameDialog.mode === "folder"
                        ? "Criar pasta"
                        : "Criar arquivo"

                    onClicked: {

                        nameDialog.create()
                    }

                    contentItem: Text {

                        text:
                            parent.text

                        color:
                            desktop.theme
                            ? desktop.theme.accentPrimary
                            : "transparent"

                        font.family:
                            desktop.defaultFont

                        font.pixelSize:
                            11

                        font.bold:
                            true

                        horizontalAlignment:
                            Text.AlignHCenter

                        verticalAlignment:
                            Text.AlignVCenter
                    }

                    background: Rectangle {

                        color:
                            parent.hovered &&
                            desktop.theme
                            ? desktop.theme.bgHover
                            : "transparent"

                        border.color:
                            desktop.theme
                            ? desktop.theme.accentPrimary
                            : "transparent"

                        border.width:
                            1

                        radius:
                            6
                    }
                }
            }
        }


        onOpened: {

            nameField.text = ""

            Qt.callLater(
                function() {
                    nameField.forceActiveFocus()
                }
            )
        }


        function create() {

            var name =
                nameField.text.trim()

            if (
                name === ""
            ) {
                return
            }

            name =
                name.replace(
                    /[\/\\]/g,
                    ""
                )

            if (
                name === ""
            ) {
                return
            }

            if (
                mode === "folder"
            ) {

                createFolder(name)

            } else {

                createFile(name)
            }

            close()
        }
    }


    /*
     * ============================================================
     * PROCESSOS
     * ============================================================
     */

    Process {
        id: createFolderProcess

        running:
            false

        command:
            []
    }


    Process {
        id: createFileProcess

        running:
            false

        command:
            []
    }


    /*
     * ============================================================
     * CRIAR PASTA
     * ============================================================
     */

    function createFolder(name) {

        if (
            !DesktopService.desktopDir
        ) {
            return
        }

        var path =
            DesktopService.desktopDir +
            "/" +
            name

        createFolderProcess.command = [
            "mkdir",
            "-p",
            path
        ]

        createFolderProcess.running =
            true

        Qt.callLater(
            function() {
                DesktopService.scanDesktop()
            }
        )
    }


    /*
     * ============================================================
     * CRIAR ARQUIVO
     * ============================================================
     */

    function createFile(name) {

        if (
            !DesktopService.desktopDir
        ) {
            return
        }

        var path =
            DesktopService.desktopDir +
            "/" +
            name

        createFileProcess.command = [
            "touch",
            path
        ]

        createFileProcess.running =
            true

        Qt.callLater(
            function() {
                DesktopService.scanDesktop()
            }
        )
    }


    function changeWallpaper() {

        console.log(
            "Trocar wallpaper solicitado"
        )
    }


    function addWidget() {

        console.log(
            "Adicionar widget solicitado"
        )
    }


    /*
     * ============================================================
     * CONFIGURAÇÕES
     * ============================================================
     */

    Popup {
        id: settingsWindow

        parent:
            Overlay.overlay

        anchors.centerIn:
            parent

        width:
            460

        height:
            360

        modal:
            true

        focus:
            true

        closePolicy:
            Popup.CloseOnEscape |
            Popup.CloseOnPressOutside

        background: Rectangle {

            color:
                desktop.theme
                ? desktop.theme.bgSurface
                : "transparent"

            border.color:
                desktop.theme
                ? desktop.theme.bgBorder
                : "transparent"

            border.width:
                1

            radius:
                10
        }


        ColumnLayout {

            anchors.fill:
                parent

            anchors.margins:
                18

            spacing:
                12


            Text {

                text:
                    "Configurações do Desktop"

                color:
                    desktop.theme
                    ? desktop.theme.textPrimary
                    : "transparent"

                font.family:
                    desktop.defaultFont

                font.pixelSize:
                    16

                font.bold:
                    true
            }


            Text {

                text:
                    "Personalize a área de trabalho."

                color:
                    desktop.theme
                    ? desktop.theme.textSecondary
                    : "transparent"

                font.family:
                    desktop.defaultFont

                font.pixelSize:
                    11
            }


            Rectangle {

                Layout.fillWidth:
                    true

                height:
                    1

                color:
                    desktop.theme
                    ? desktop.theme.bgBorder
                    : "transparent"
            }


            CheckBox {

                text:
                    "Mostrar desktop"

                checked:
                    desktop.desktopEnabled

                onToggled: {

                    desktop.desktopEnabled =
                        checked
                }

                contentItem: Text {

                    text:
                        parent.text

                    color:
                        desktop.theme
                        ? desktop.theme.textPrimary
                        : "transparent"

                    font.family:
                        desktop.defaultFont

                    font.pixelSize:
                        11

                    leftPadding:
                        parent.indicator.width +
                        parent.spacing

                    verticalAlignment:
                        Text.AlignVCenter
                }
            }


            RowLayout {

                Layout.fillWidth:
                    true


                Text {

                    text:
                        "Tamanho dos ícones"

                    color:
                        desktop.theme
                        ? desktop.theme.textPrimary
                        : "transparent"

                    font.family:
                        desktop.defaultFont

                    font.pixelSize:
                        11
                }


                Slider {

                    Layout.fillWidth:
                        true

                    from:
                        32

                    to:
                        96

                    value:
                        desktop.iconSize

                    onMoved: {

                        desktop.iconSize =
                            value
                    }
                }
            }


            RowLayout {

                Layout.fillWidth:
                    true


                Text {

                    text:
                        "Espaçamento"

                    color:
                        desktop.theme
                        ? desktop.theme.textPrimary
                        : "transparent"

                    font.family:
                        desktop.defaultFont

                    font.pixelSize:
                        11
                }


                Slider {

                    Layout.fillWidth:
                        true

                    from:
                        4

                    to:
                        32

                    value:
                        desktop.spacingVertical

                    onMoved: {

                        desktop.spacingVertical =
                            value
                    }
                }
            }


            Item {

                Layout.fillHeight:
                    true
            }


            Button {

                Layout.alignment:
                    Qt.AlignRight

                text:
                    "Fechar"

                onClicked: {

                    settingsWindow.close()
                }

                contentItem: Text {

                    text:
                        parent.text

                    color:
                        desktop.theme
                        ? desktop.theme.accentPrimary
                        : "transparent"

                    font.family:
                        desktop.defaultFont

                    font.pixelSize:
                        11

                    horizontalAlignment:
                        Text.AlignHCenter

                    verticalAlignment:
                        Text.AlignVCenter
                }

                background: Rectangle {

                    color:
                        parent.hovered &&
                        desktop.theme
                        ? desktop.theme.bgHover
                        : "transparent"

                    border.color:
                        desktop.theme
                        ? desktop.theme.accentPrimary
                        : "transparent"

                    border.width:
                        1

                    radius:
                        6
                }
            }
        }
    }


    /*
     * ============================================================
     * FECHAR MENU CLICANDO FORA
     * ============================================================
     */

    MouseArea {
        id: menuCloser

        anchors.fill:
            parent

        z:
            9999

        visible:
            desktopMenu.visible

        acceptedButtons:
            Qt.LeftButton |
            Qt.RightButton

        onClicked: function(mouse) {

            if (
                mouse.x >= desktopMenu.x &&
                mouse.x <=
                    desktopMenu.x +
                    desktopMenu.width &&
                mouse.y >= desktopMenu.y &&
                mouse.y <=
                    desktopMenu.y +
                    desktopMenu.height
            ) {

                return
            }

            desktopMenu.closeMenu()
        }
    }


    /*
     * ============================================================
     * LOADING
     * ============================================================
     */

    Rectangle {

        anchors.centerIn:
            parent

        width:
            200

        height:
            60

        color:
            desktop.theme
            ? desktop.theme.bgSurface
            : "transparent"

        border.color:
            desktop.theme
            ? desktop.theme.bgBorder
            : "transparent"

        border.width:
            1

        radius:
            8

        visible:
            !DesktopService.initialLoadComplete


        Text {

            anchors.centerIn:
                parent

            text:
                "Loading desktop..."

            color:
                desktop.theme
                ? desktop.theme.textPrimary
                : "transparent"

            font.family:
                desktop.defaultFont

            font.pixelSize:
                12
        }
    }
}

