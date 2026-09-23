import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

import "../theme_switcher"
import "../services"

Item {
    id: root

    required property string itemName
    required property string itemPath
    required property string itemType
    required property string itemIcon

    property bool isDesktopFile: false

    signal activated
    signal contextMenuRequested

    readonly property string thumbnailPath: {
        if (!itemPath || itemPath.length === 0)
            return ""

        const ext =
            itemPath.substring(
                itemPath.lastIndexOf(".") + 1
            ).toLowerCase()

        const videoExts = [
            "mp4",
            "webm",
            "mov",
            "avi",
            "mkv",
            "gif"
        ]

        const imageExts = [
            "jpg",
            "jpeg",
            "png",
            "webp",
            "tif",
            "tiff",
            "bmp"
        ]

        if (
            itemType === "folder" ||
            isDesktopFile
        ) {
            return ""
        }

        if (
            videoExts.includes(ext) ||
            imageExts.includes(ext)
        ) {
            const fileName =
                itemPath.substring(
                    itemPath.lastIndexOf("/") + 1
                )

            return Quickshell.cachePath(
                "desktop_thumbnails/" +
                fileName +
                ".jpg"
            )
        }

        return ""
    }

    readonly property bool hasThumbnail:
        thumbnailPath.length > 0 &&
        Qt.platform.os !== "windows"

    property int thumbnailRefresh: 0

    FileView {
        path: root.thumbnailPath

        watchChanges:
            root.hasThumbnail

        printErrors: false

        onFileChanged: {
            root.thumbnailRefresh++
        }
    }

    width: 96
    height: 96

    /*
     * ============================================================
     * HOVER
     * ============================================================
     */

    Rectangle {
        id: background

        anchors.fill: parent

        color:
            Theme.bgSurface

        radius: 7

        opacity:
            hoverHandler.hovered
            ? 0.30
            : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: 120
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
    }

    /*
     * ============================================================
     * CLIQUE DUPLO
     * ============================================================
     */

    TapHandler {
        acceptedButtons:
            Qt.LeftButton

        onDoubleTapped: {
            root.activated()

            if (!root.itemPath)
                return

            if (root.isDesktopFile) {
                DesktopService.executeDesktopFile(
                    root.itemPath
                )
            } else {
                DesktopService.openFile(
                    root.itemPath
                )
            }
        }
    }

    /*
     * ============================================================
     * CLIQUE DIREITO
     * ============================================================
     */

    TapHandler {
        acceptedButtons:
            Qt.RightButton

        onTapped: {
            root.contextMenuRequested()
        }
    }

    HoverHandler {
        id: hoverHandler
    }

    /*
     * ============================================================
     * CONTEÚDO
     * ============================================================
     */

    ColumnLayout {
        anchors.fill: parent

        anchors.leftMargin: 5
        anchors.rightMargin: 5
        anchors.topMargin: 4
        anchors.bottomMargin: 4

        spacing: 4

        /*
         * ========================================================
         * ÍCONE
         * ========================================================
         */

        Item {
            Layout.alignment:
                Qt.AlignHCenter

            Layout.preferredWidth: 52
            Layout.preferredHeight: 52

            Image {
                id: iconImage

                anchors.fill: parent

                mipmap: true
                asynchronous: true
                smooth: true

                /*
                 * Usa diretamente o tema de ícones
                 * instalado no sistema, como Papirus.
                 */
                cache: false

                source: {
                    root.thumbnailRefresh

                    if (root.hasThumbnail) {
                        return (
                            "file://" +
                            root.thumbnailPath
                        )
                    }

                    if (
                        root.itemIcon &&
                        root.itemIcon.length > 0
                    ) {
                        return (
                            "image://icon/" +
                            root.itemIcon
                        )
                    }

                    return ""
                }

                fillMode:
                    Image.PreserveAspectFit

                visible:
                    source.length > 0

                onStatusChanged: {
                    if (
                        status === Image.Error &&
                        root.hasThumbnail &&
                        root.itemIcon &&
                        root.itemIcon.length > 0
                    ) {
                        source =
                            "image://icon/" +
                            root.itemIcon
                    }
                }
            }

            /*
             * Fallback para quando nenhum ícone
             * puder ser carregado.
             */

            Text {
                anchors.centerIn: parent

                visible:
                    !iconImage.visible ||
                    iconImage.status === Image.Error

                text:
                    root.itemType === "folder"
                    ? "󰉋"
                    : root.isDesktopFile
                        ? "󰀻"
                        : "󰈔"

                color:
                    Theme.accentPrimary

                font.family:
                    "JetBrains Mono Nerd Font"

                font.pixelSize: 34
            }
        }

        /*
         * ========================================================
         * NOME DO ÍCONE
         * ========================================================
         */

        Item {
            Layout.fillWidth: true

            Layout.preferredHeight: 34

            Text {
                id: itemTitle

                anchors.fill: parent

                text:
                    root.itemName

                color:
                    Theme.textPrimary

                font.family:
                    "JetBrains Mono Nerd Font"

                /*
                 * 11px fica mais elegante sem perder
                 * legibilidade.
                 */
                font.pixelSize: 11

                font.weight:
                    Font.Medium

                horizontalAlignment:
                    Text.AlignHCenter

                verticalAlignment:
                    Text.AlignVCenter

                wrapMode:
                    Text.Wrap

                maximumLineCount: 2

                elide:
                    Text.ElideRight

                lineHeight: 1.05

                lineHeightMode:
                    Text.ProportionalHeight

                /*
                 * Sem outline e sem DropShadow:
                 * visual mais limpo e leve.
                 */

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }
            }
        }
    }
}

