pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string desktopDir: ""
    property bool initialLoadComplete: false

    property string positionsFile:
        Quickshell.dataPath("desktop-positions.json")

    // ============================================================
    // ITENS OCULTOS DO DESKTOP
    // ============================================================

    property string hiddenItemsFile:
        Quickshell.dataPath("desktop-hidden.json")

    property var hiddenItems: ({})

    property bool hiddenItemsLoaded: false

    // ============================================================
    // GRID
    // ============================================================

    property int maxRowsHint: 15
    property int maxColumnsHint: 10

    property bool gridReady: false
    property bool positionsLoaded: false
    property bool desktopScanComplete: false

    // ============================================================
    // THUMBNAILS
    // ============================================================

    property bool thumbnailRunPending: false
    property bool thumbnailGenerationActive: false

    property var thumbnailQueue: []
    property int thumbnailQueueIndex: 0
    property var currentThumbnailJob: null
    property int thumbnailsGenerated: 0

    readonly property var thumbnailVideoExtensions:
        ["mp4", "webm", "mov", "avi", "mkv", "gif"]

    readonly property var thumbnailImageExtensions:
        ["jpg", "jpeg", "png", "webp", "tif", "tiff", "bmp"]

    // ============================================================
    // MODEL
    // ============================================================

    property ListModel items: ListModel {
        id: itemsModel
    }

    property var iconPositions: ({})

    property var tempDesktopFiles: []
    property var tempItems: []

    property int currentDesktopFileIndex: -1

    property bool parsingInProgress: false
    property bool needsRescan: false

    property bool _initialized: false


    // ============================================================
    // GRID
    // ============================================================

    onMaxRowsHintChanged: checkGridReady()
    onMaxColumnsHintChanged: checkGridReady()
    onPositionsLoadedChanged: checkGridReady()
    onHiddenItemsLoadedChanged: checkGridReady()

    function checkGridReady() {

        if (maxRowsHint > 0 &&
            maxColumnsHint > 0 &&
            positionsLoaded &&
            hiddenItemsLoaded &&
            !gridReady) {

            gridReady = true

            console.log(
                "Grid ready - rows:",
                maxRowsHint,
                "cols:",
                maxColumnsHint
            )
        }

        if (gridReady &&
            positionsLoaded &&
            hiddenItemsLoaded &&
            desktopScanComplete &&
            !parsingInProgress &&
            !initialLoadComplete) {

            console.log(
                "Finalizing initial desktop with",
                tempItems.length +
                tempDesktopFiles.length,
                "items"
            )

            finalizeItems()
        }
    }


    // ============================================================
    // POSITIONS
    // ============================================================

    function savePositions() {

        var json =
            JSON.stringify(
                iconPositions,
                null,
                2
            )

        savePositionsProcess.command = [
            "sh",
            "-c",
            "printf '%s' '" +
            json.replace(
                /'/g,
                "'\\''"
            ) +
            "' > '" +
            positionsFile.replace(
                /'/g,
                "'\\''"
            ) +
            "'"
        ]

        savePositionsProcess.running = true
    }


    function loadPositions() {
        loadPositionsProcess.running = true
    }


    function updateIconPosition(
        path,
        gridX,
        gridY
    ) {

        if (!path)
            return

        iconPositions[path] = {
            x: gridX,
            y: gridY
        }

        savePositions()
    }


    function removeIconPosition(path) {

        if (!path)
            return

        if (iconPositions[path] !== undefined)
            delete iconPositions[path]

        savePositions()
    }


    function getIconPosition(path) {
        return iconPositions[path] || null
    }


    function calculateAutoPosition(index) {

        var usedPositions = {}

        for (var key in iconPositions) {

            var pos =
                iconPositions[key]

            if (
                pos &&
                pos.x !== undefined &&
                pos.y !== undefined
            ) {

                usedPositions[
                    pos.x + "," + pos.y
                ] = true
            }
        }

        var gridX = 0
        var gridY = 0
        var checked = 0

        while (checked <= index) {

            var posKey =
                gridX + "," + gridY

            if (!usedPositions[posKey]) {

                if (checked === index) {

                    return {
                        x: gridX,
                        y: gridY
                    }
                }

                checked++
            }

            gridY++

            if (gridY >= maxRowsHint) {

                gridY = 0
                gridX++
            }
        }

        return {
            x: gridX,
            y: gridY
        }
    }


    // ============================================================
    // HIDDEN ITEMS
    // ============================================================

    function isItemHidden(path) {

        if (!path)
            return false

        return hiddenItems[path] === true
    }


    function saveHiddenItems() {

        var json =
            JSON.stringify(
                hiddenItems,
                null,
                2
            )

        saveHiddenItemsProcess.command = [
            "sh",
            "-c",
            "printf '%s' '" +
            json.replace(
                /'/g,
                "'\\''"
            ) +
            "' > '" +
            hiddenItemsFile.replace(
                /'/g,
                "'\\''"
            ) +
            "'"
        ]

        saveHiddenItemsProcess.running = true
    }


    function hideItem(path) {

        if (!path)
            return

        hiddenItems[path] = true

        saveHiddenItems()

        removeIconPosition(path)

        var index = -1

        for (
            var i = 0;
            i < items.count;
            i++
        ) {

            var item =
                items.get(i)

            if (item.path === path) {

                index = i
                break
            }
        }

        if (index >= 0) {

            items.setProperty(
                index,
                "name",
                ""
            )

            items.setProperty(
                index,
                "path",
                ""
            )

            items.setProperty(
                index,
                "type",
                "placeholder"
            )

            items.setProperty(
                index,
                "icon",
                ""
            )

            items.setProperty(
                index,
                "isDesktopFile",
                false
            )

            items.setProperty(
                index,
                "isPlaceholder",
                true
            )
        }

        console.log(
            "Hidden desktop item:",
            path
        )
    }


    function showItem(path) {

        if (!path)
            return

        if (hiddenItems[path] !== undefined)
            delete hiddenItems[path]

        saveHiddenItems()

        scanDesktop()
    }


    function removeFromDesktop(path) {

        hideItem(path)
    }


    function removeDesktopItem(path) {

        removeFromDesktop(path)
    }


    // ============================================================
    // LOAD HIDDEN ITEMS
    // ============================================================

    Process {
        id: loadHiddenItemsProcess

        running: false

        command: [
            "cat",
            hiddenItemsFile
        ]

        stdout: StdioCollector {

            onStreamFinished: {

                if (text.trim().length > 0) {

                    try {

                        var parsed =
                            JSON.parse(text)

                        root.hiddenItems = {}

                        for (
                            var key in parsed
                        ) {

                            if (
                                parsed[key] === true
                            ) {

                                root.hiddenItems[key] =
                                    true
                            }
                        }

                        console.log(
                            "Loaded",
                            Object.keys(
                                root.hiddenItems
                            ).length,
                            "hidden desktop items"
                        )

                    } catch (e) {

                        console.warn(
                            "Error parsing hidden items:",
                            e
                        )
                    }
                }

                root.hiddenItemsLoaded = true
            }
        }

        stderr: StdioCollector {

            onStreamFinished: {

                root.hiddenItemsLoaded = true
            }
        }
    }


    Process {
        id: saveHiddenItemsProcess

        running: false

        command: []

        stderr: StdioCollector {

            onStreamFinished: {

                if (text.length > 0) {

                    console.warn(
                        "Error saving hidden items:",
                        text
                    )
                }
            }
        }
    }


    // ============================================================
    // DESKTOP DIRECTORY
    // ============================================================

    function getDesktopDir() {
        getDesktopDirProcess.running = true
    }


    function scanDesktop() {

        if (!desktopDir)
            return

        if (parsingInProgress) {

            needsRescan = true

        } else {

            scanProcess.running = true
        }
    }


    // ============================================================
    // FILE TYPES / ICONS
    // ============================================================

    function getFileType(fileName) {

        var lower =
            fileName.toLowerCase()

        var ext =
            lower.includes(".")
            ? lower.split(".").pop()
            : ""

        if (
            [
                "jpg",
                "jpeg",
                "png",
                "gif",
                "webp",
                "svg",
                "bmp"
            ].includes(ext)
        ) {
            return "image"
        }

        if (
            [
                "mp4",
                "webm",
                "mov",
                "avi",
                "mkv",
                "mp3",
                "wav",
                "ogg",
                "flac"
            ].includes(ext)
        ) {
            return "media"
        }

        if (ext === "pdf")
            return "pdf"

        if (
            [
                "txt",
                "md",
                "log"
            ].includes(ext)
        ) {
            return "text"
        }

        if (
            [
                "zip",
                "tar",
                "gz",
                "rar",
                "7z"
            ].includes(ext)
        ) {
            return "archive"
        }

        if (
            [
                "doc",
                "docx",
                "odt"
            ].includes(ext)
        ) {
            return "document"
        }

        return "file"
    }


    function getIconForType(type) {

        switch (type) {

        case "folder":
            return "folder"

        case "image":
            return "image-x-generic"

        case "media":
            return "video-x-generic"

        case "pdf":
            return "application-pdf"

        case "text":
            return "text-x-generic"

        case "archive":
            return "package-x-generic"

        case "document":
            return "x-office-document"

        default:
            return "text-x-generic"
        }
    }


    // ============================================================
    // OPEN FILE / FOLDER
    // ============================================================

    function openFile(filePath) {

        if (!filePath)
            return

        var escapedPath =
            filePath.replace(
                /'/g,
                "'\\''"
            )

        Qt.createQmlObject(`
            import Quickshell
            import Quickshell.Io

            Process {
                running: true

                command: [
                    "bash",
                    "-c",
                    "setsid xdg-open '${escapedPath}' < /dev/null > /dev/null 2>&1 &"
                ]

                onRunningChanged: {
                    if (!running)
                        destroy()
                }
            }
        `, root)
    }


    // ============================================================
    // DESKTOP FILE
    // ============================================================

    function parseDesktopFile(filePath) {

        parseDesktopProcess.command = [
            "cat",
            filePath
        ]

        parseDesktopProcess.running = true
    }


    function executeDesktopFile(filePath) {

        if (!filePath)
            return

        var escapedPath =
            filePath.replace(
                /'/g,
                "'\\''"
            )

        Qt.createQmlObject(`
            import Quickshell
            import Quickshell.Io

            Process {
                running: true

                command: [
                    "bash",
                    "-c",
                    "cd ~ && setsid gio launch '${escapedPath}' < /dev/null > /dev/null 2>&1 &"
                ]

                onRunningChanged: {
                    if (!running)
                        destroy()
                }
            }
        `, root)
    }


    // ============================================================
    // TRASH
    // ============================================================

    function trashFile(filePath) {

        if (!filePath)
            return

        var escapedPath =
            filePath.replace(
                /'/g,
                "'\\''"
            )

        Qt.createQmlObject(`
            import Quickshell
            import Quickshell.Io

            Process {
                running: true

                command: [
                    "bash",
                    "-c",
                    "gio trash '${escapedPath}'"
                ]

                onRunningChanged: {
                    if (!running) {

                        Qt.callLater(
                            function() {
                                DesktopService.scanDesktop()
                            }
                        )

                        destroy()
                    }
                }
            }
        `, root)
    }


    function deleteItem(filePath) {

        if (!filePath)
            return

        trashFile(filePath)
    }


    // ============================================================
    // MOVE ITEM
    // ============================================================

    function saveAllPositions() {

        iconPositions = {}

        for (
            var i = 0;
            i < items.count;
            i++
        ) {

            var item =
                items.get(i)

            if (
                !item.isPlaceholder &&
                item.path
            ) {

                var col =
                    Math.floor(
                        i / maxRowsHint
                    )

                var row =
                    i % maxRowsHint

                iconPositions[item.path] = {
                    x: col,
                    y: row
                }
            }
        }

        savePositions()
    }


    function moveItem(
        fromIndex,
        toIndex
    ) {

        if (
            fromIndex ===
            toIndex
        )
            return

        if (
            fromIndex < 0 ||
            toIndex < 0 ||
            fromIndex >= items.count
        )
            return

        if (
            toIndex >=
            items.count
        ) {

            toIndex =
                items.count - 1
        }

        var target =
            items.get(toIndex)

        var targetIsPlaceholder =
            target.isPlaceholder === true

        if (targetIsPlaceholder) {

            var item =
                items.get(fromIndex)

            items.setProperty(
                toIndex,
                "name",
                item.name
            )

            items.setProperty(
                toIndex,
                "path",
                item.path
            )

            items.setProperty(
                toIndex,
                "type",
                item.type
            )

            items.setProperty(
                toIndex,
                "icon",
                item.icon
            )

            items.setProperty(
                toIndex,
                "isDesktopFile",
                item.isDesktopFile
            )

            items.setProperty(
                toIndex,
                "isPlaceholder",
                false
            )

            items.setProperty(
                fromIndex,
                "name",
                ""
            )

            items.setProperty(
                fromIndex,
                "path",
                ""
            )

            items.setProperty(
                fromIndex,
                "type",
                "placeholder"
            )

            items.setProperty(
                fromIndex,
                "icon",
                ""
            )

            items.setProperty(
                fromIndex,
                "isDesktopFile",
                false
            )

            items.setProperty(
                fromIndex,
                "isPlaceholder",
                true
            )

        } else {

            items.move(
                fromIndex,
                toIndex,
                1
            )
        }

        saveAllPositions()
    }


    // ============================================================
    // THUMBNAILS
    // ============================================================

    function getThumbnailExtension(
        fileName
    ) {

        var dotIndex =
            fileName.lastIndexOf(".")

        if (
            dotIndex < 0 ||
            dotIndex ===
            fileName.length - 1
        ) {
            return ""
        }

        return fileName
            .substring(
                dotIndex + 1
            )
            .toLowerCase()
    }


    function getThumbnailKind(
        fileName
    ) {

        var ext =
            getThumbnailExtension(
                fileName
            )

        if (
            thumbnailVideoExtensions
                .includes(ext)
        )
            return "video"

        if (
            thumbnailImageExtensions
                .includes(ext)
        )
            return "image"

        return ""
    }


    function getThumbnailPath(
        fileName
    ) {

        return Quickshell.cachePath(
            "desktop_thumbnails/" +
            fileName +
            ".jpg"
        )
    }


    function getThumbnailCommand(
        job
    ) {

        if (
            job.kind ===
            "video"
        ) {

            return [
                "ffmpeg",
                "-hide_banner",
                "-loglevel",
                "error",
                "-y",
                "-i",
                job.source,
                "-ss",
                "00:00:01",
                "-vframes",
                "1",
                "-vf",
                "scale=64:64:force_original_aspect_ratio=increase,crop=64:64",
                "-q:v",
                "2",
                "-f",
                "image2",
                job.thumbnail
            ]
        }

        return [
            "convert",
            job.source,
            "-resize",
            "64x64^",
            "-gravity",
            "center",
            "-extent",
            "64x64",
            "-quality",
            "85",
            job.thumbnail
        ]
    }


    function generateThumbnails() {

        if (!desktopDir)
            return

        if (
            !initialLoadComplete ||
            parsingInProgress ||
            scanProcess.running
        ) {

            thumbnailRunPending = true

            if (initialLoadComplete)
                thumbnailTimer.restart()

            return
        }

        if (
            thumbnailGenerationActive
        ) {

            thumbnailRunPending = true

            return
        }

        thumbnailGenerationActive = true
        thumbnailRunPending = false

        thumbnailQueue = []
        thumbnailQueueIndex = 0
        currentThumbnailJob = null
        thumbnailsGenerated = 0

        for (
            var i = 0;
            i < items.count;
            i++
        ) {

            var item =
                items.get(i)

            if (
                item.isPlaceholder ||
                item.isDesktopFile ||
                item.type === "folder" ||
                !item.path
            ) {
                continue
            }

            var kind =
                getThumbnailKind(
                    item.name
                )

            if (!kind)
                continue

            thumbnailQueue.push({
                source: item.path,
                thumbnail:
                    getThumbnailPath(
                        item.name
                    ),
                kind: kind
            })
        }

        if (
            thumbnailQueue.length === 0
        ) {

            finishThumbnailGeneration()

            return
        }

        thumbnailSetupProcess.exec([
            "mkdir",
            "-p",
            Quickshell.cachePath(
                "desktop_thumbnails"
            )
        ])
    }


    function checkNextThumbnail() {

        if (
            !thumbnailGenerationActive
        )
            return

        if (
            thumbnailQueueIndex >=
            thumbnailQueue.length
        ) {

            finishThumbnailGeneration()

            return
        }

        currentThumbnailJob =
            thumbnailQueue[
                thumbnailQueueIndex
            ]

        thumbnailFreshnessProcess.exec([
            "test",
            currentThumbnailJob.source,
            "-nt",
            currentThumbnailJob.thumbnail
        ])
    }


    function generateCurrentThumbnail() {

        if (!currentThumbnailJob) {

            advanceThumbnailQueue()

            return
        }

        thumbnailProcess.exec(
            getThumbnailCommand(
                currentThumbnailJob
            )
        )
    }


    function advanceThumbnailQueue() {

        thumbnailQueueIndex++
        currentThumbnailJob = null

        Qt.callLater(
            checkNextThumbnail
        )
    }


    function finishThumbnailGeneration() {

        var generatedCount =
            thumbnailsGenerated

        thumbnailGenerationActive = false
        thumbnailQueue = []
        thumbnailQueueIndex = 0
        currentThumbnailJob = null
        thumbnailsGenerated = 0

        if (
            generatedCount > 0
        ) {

            console.log(
                "Thumbnail generation complete:",
                generatedCount,
                "generated"
            )

            Qt.callLater(
                scanDesktop
            )
        }

        if (
            thumbnailRunPending
        ) {

            thumbnailRunPending = false

            thumbnailTimer.restart()
        }
    }


    // ============================================================
    // INITIALIZE
    // ============================================================

    function initialize() {

        if (_initialized)
            return

        _initialized = true

        Qt.callLater(
            function() {

                loadHiddenItems()

                getDesktopDir()
            }
        )
    }


    function loadHiddenItems() {

        loadHiddenItemsProcess.running = true
    }


    // ============================================================
    // SAVE POSITIONS PROCESS
    // ============================================================

    Process {
        id: savePositionsProcess

        running: false
        command: []

        stderr: StdioCollector {

            onStreamFinished: {

                if (text.length > 0) {

                    console.warn(
                        "Error saving positions:",
                        text
                    )
                }
            }
        }
    }


    // ============================================================
    // LOAD POSITIONS
    // ============================================================

    Process {
        id: loadPositionsProcess

        running: false

        command: [
            "cat",
            positionsFile
        ]

        stdout: StdioCollector {

            onStreamFinished: {

                if (
                    text.trim().length > 0
                ) {

                    try {

                        var parsed =
                            JSON.parse(text)

                        root.iconPositions = {}

                        for (
                            var key in parsed
                        ) {

                            root.iconPositions[key] = {
                                x: parsed[key].x,
                                y: parsed[key].y
                            }
                        }

                        console.log(
                            "Loaded",
                            Object.keys(
                                root.iconPositions
                            ).length,
                            "icon positions"
                        )

                    } catch (e) {

                        console.warn(
                            "Error parsing positions file:",
                            e
                        )
                    }
                }

                root.positionsLoaded =
                    true
            }
        }

        stderr: StdioCollector {

            onStreamFinished: {

                root.positionsLoaded =
                    true
            }
        }
    }


    // ============================================================
    // GET DESKTOP DIRECTORY
    // ============================================================

    Process {
        id: getDesktopDirProcess

        running: false

        command: [
            "sh",
            "-c",
            "echo ${XDG_DESKTOP_DIR:-$HOME/Desktop}"
        ]

        stdout: StdioCollector {

            onStreamFinished: {

                root.desktopDir =
                    text.trim()

                console.log(
                    "Desktop directory:",
                    root.desktopDir
                )

                console.log(
                    "Positions file:",
                    root.positionsFile
                )

                console.log(
                    "Hidden items file:",
                    root.hiddenItemsFile
                )

                loadPositions()
                scanDesktop()

                directoryWatcher.path =
                    root.desktopDir

                directoryWatcher.reload()
            }
        }
    }


    // ============================================================
    // DIRECTORY WATCHER
    // ============================================================

    FileView {
        id: directoryWatcher

        path: ""
        watchChanges: true
        printErrors: false

        onFileChanged: {

            console.log(
                "Desktop directory changed, rescanning..."
            )

            scanDesktop()

            thumbnailTimer.restart()
        }
    }


    // ============================================================
    // SCAN DESKTOP
    // ============================================================

    Process {
        id: scanProcess

        running: false

        command: [
            "sh",
            "-c",
            "ls -1ap '" +
            root.desktopDir.replace(
                /'/g,
                "'\\''"
            ) +
            "' | grep -v '^\\.$' | grep -v '^\\.\\.$'"
        ]

        stdout: StdioCollector {

            onStreamFinished: {

                var raw =
                    text.trim()

                var entries =
                    raw.length > 0
                    ? raw.split("\n")
                    : []

                var newItems = []
                var pendingDesktopFiles = []

                for (
                    var i = 0;
                    i < entries.length;
                    i++
                ) {

                    var entry =
                        entries[i]

                    if (!entry)
                        continue

                    var isDir =
                        entry.endsWith("/")

                    var name =
                        isDir
                        ? entry.slice(
                            0,
                            -1
                        )
                        : entry

                    var fullPath =
                        root.desktopDir +
                        "/" +
                        name

                    if (
                        name.startsWith(".")
                    )
                        continue

                    // ========================================
                    // NÃO MOSTRAR ITENS OCULTOS
                    // ========================================

                    if (
                        root.isItemHidden(
                            fullPath
                        )
                    ) {

                        console.log(
                            "Skipping hidden item:",
                            name
                        )

                        continue
                    }


                    // ========================================
                    // PASTA
                    // ========================================

                    if (isDir) {

                        newItems.push({
                            name: name,
                            path: fullPath,
                            type: "folder",
                            icon: "folder",
                            isDesktopFile: false,
                            sortOrder: 0
                        })


                    // ========================================
                    // DESKTOP FILE
                    // ========================================

                    } else if (
                        name.endsWith(
                            ".desktop"
                        )
                    ) {

                        pendingDesktopFiles.push({
                            name: name,
                            path: fullPath,
                            type: "application",
                            icon:
                                "application-x-executable",
                            isDesktopFile: true,
                            sortOrder: 1
                        })


                    // ========================================
                    // ARQUIVO NORMAL
                    // ========================================

                    } else {

                        var fileType =
                            root.getFileType(
                                name
                            )

                        newItems.push({
                            name: name,
                            path: fullPath,
                            type: fileType,
                            icon:
                                root.getIconForType(
                                    fileType
                                ),
                            isDesktopFile: false,
                            sortOrder: 2
                        })
                    }
                }


                if (
                    !root.parsingInProgress
                ) {

                    root.tempDesktopFiles =
                        pendingDesktopFiles

                    root.tempItems =
                        newItems

                    root.desktopScanComplete =
                        true

                    root.checkGridReady()

                    if (
                        pendingDesktopFiles.length >
                        0
                    ) {

                        root.parsingInProgress =
                            true

                        root.currentDesktopFileIndex =
                            0

                        root.parseNextDesktopFile()

                    } else {

                        if (
                            root.gridReady &&
                            root.positionsLoaded
                        ) {

                            root.finalizeItems()
                        }
                    }

                } else {

                    root.needsRescan =
                        true
                }
            }
        }

        stderr: StdioCollector {

            onStreamFinished: {

                if (text.length > 0) {

                    console.warn(
                        "Error scanning desktop:",
                        text
                    )
                }
            }
        }
    }


    // ============================================================
    // PARSE .DESKTOP FILE
    // ============================================================

    Process {
        id: parseDesktopProcess

        running: false
        command: []

        stdout: StdioCollector {

            onStreamFinished: {

                if (
                    root.currentDesktopFileIndex < 0 ||
                    root.currentDesktopFileIndex >=
                    root.tempDesktopFiles.length
                ) {
                    return
                }

                var item =
                    root.tempDesktopFiles[
                        root.currentDesktopFileIndex
                    ]

                var lines =
                    text.split("\n")

                var name = ""

                var icon =
                    "application-x-executable"

                for (
                    var i = 0;
                    i < lines.length;
                    i++
                ) {

                    var line =
                        lines[i].trim()

                    if (
                        line.startsWith(
                            "Name="
                        )
                    ) {

                        name =
                            line.substring(5)

                    } else if (
                        line.startsWith(
                            "Icon="
                        )
                    ) {

                        icon =
                            line.substring(5)
                    }
                }

                if (name)
                    item.name = name

                if (icon)
                    item.icon = icon
            }
        }

        onRunningChanged: {

            if (
                !running &&
                root.currentDesktopFileIndex >= 0
            ) {

                root.currentDesktopFileIndex++

                if (
                    root.currentDesktopFileIndex <
                    root.tempDesktopFiles.length
                ) {

                    Qt.callLater(
                        root.parseNextDesktopFile
                    )

                } else {

                    root.parsingInProgress =
                        false

                    root.currentDesktopFileIndex =
                        -1

                    if (
                        root.gridReady &&
                        root.positionsLoaded
                    ) {

                        root.finalizeItems()
                    }

                    if (
                        root.needsRescan
                    ) {

                        root.needsRescan =
                            false

                        root.scanDesktop()
                    }
                }
            }
        }

        stderr: StdioCollector {

            onStreamFinished: {

                if (text.length > 0) {

                    console.warn(
                        "Error parsing .desktop file:",
                        text
                    )
                }
            }
        }
    }


    // ============================================================
    // PARSE NEXT
    // ============================================================

    function parseNextDesktopFile() {

        if (
            currentDesktopFileIndex >= 0 &&
            currentDesktopFileIndex <
            tempDesktopFiles.length
        ) {

            var item =
                tempDesktopFiles[
                    currentDesktopFileIndex
                ]

            parseDesktopProcess.command = [
                "cat",
                item.path
            ]

            parseDesktopProcess.running =
                true

        } else {

            parsingInProgress =
                false

            if (
                gridReady &&
                positionsLoaded
            ) {

                finalizeItems()
            }
        }
    }


    // ============================================================
    // FINALIZE MODEL
    // ============================================================

    function finalizeItems() {

        var allItems =
            tempItems.concat(
                tempDesktopFiles
            )

        // Remove qualquer item que tenha sido ocultado
        var visibleItems = []

        for (
            var h = 0;
            h < allItems.length;
            h++
        ) {

            if (
                !isItemHidden(
                    allItems[h].path
                )
            ) {

                visibleItems.push(
                    allItems[h]
                )
            }
        }

        allItems =
            visibleItems

        allItems.sort(
            function(a, b) {

                if (
                    a.sortOrder !==
                    b.sortOrder
                ) {

                    return a.sortOrder -
                           b.sortOrder
                }

                return a.name.localeCompare(
                    b.name
                )
            }
        )

        items.clear()

        var gridSize =
            maxRowsHint *
            maxColumnsHint

        for (
            var i = 0;
            i < gridSize;
            i++
        ) {

            items.append({

                name: "",

                path: "",

                type: "placeholder",

                icon: "",

                isDesktopFile: false,

                isPlaceholder: true,

                gridX:
                    Math.floor(
                        i /
                        maxRowsHint
                    ),

                gridY:
                    i %
                    maxRowsHint
            })
        }

        var usedIndices = {}


        for (
            var j = 0;
            j < allItems.length;
            j++
        ) {

            var item =
                allItems[j]

            var savedPos =
                getIconPosition(
                    item.path
                )

            var gridIndex = -1

            if (
                savedPos &&
                savedPos.x >= 0 &&
                savedPos.y >= 0 &&
                savedPos.x <
                    maxColumnsHint &&
                savedPos.y <
                    maxRowsHint
            ) {

                gridIndex =
                    savedPos.x *
                    maxRowsHint +
                    savedPos.y

                if (
                    usedIndices[
                        gridIndex
                    ]
                ) {

                    gridIndex = -1
                }
            }


            if (
                gridIndex === -1
            ) {

                for (
                    var k = 0;
                    k < gridSize;
                    k++
                ) {

                    if (
                        !usedIndices[k]
                    ) {

                        gridIndex = k

                        break
                    }
                }
            }


            if (
                gridIndex >= 0 &&
                gridIndex < items.count
            ) {

                usedIndices[
                    gridIndex
                ] = true

                var col =
                    Math.floor(
                        gridIndex /
                        maxRowsHint
                    )

                var row =
                    gridIndex %
                    maxRowsHint


                items.setProperty(
                    gridIndex,
                    "name",
                    item.name
                )

                items.setProperty(
                    gridIndex,
                    "path",
                    item.path
                )

                items.setProperty(
                    gridIndex,
                    "type",
                    item.type
                )

                items.setProperty(
                    gridIndex,
                    "icon",
                    item.icon ||
                    root.getIconForType(
                        item.type
                    )
                )

                items.setProperty(
                    gridIndex,
                    "isDesktopFile",
                    item.isDesktopFile
                )

                items.setProperty(
                    gridIndex,
                    "isPlaceholder",
                    false
                )

                items.setProperty(
                    gridIndex,
                    "gridX",
                    col
                )

                items.setProperty(
                    gridIndex,
                    "gridY",
                    row
                )
            }
        }

        root.initialLoadComplete =
            true
    }


    // ============================================================
    // THUMBNAIL PROCESSES
    // ============================================================

    Process {
        id: thumbnailSetupProcess

        running: false
        command: []

        onExited: (
            exitCode,
            exitStatus
        ) => {

            if (
                exitCode !== 0
            ) {

                console.warn(
                    "Could not create thumbnail cache directory"
                )

                root.finishThumbnailGeneration()

                return
            }

            Qt.callLater(
                root.checkNextThumbnail
            )
        }
    }


    Process {
        id: thumbnailFreshnessProcess

        running: false
        command: []

        onExited: (
            exitCode,
            exitStatus
        ) => {

            if (
                !root.thumbnailGenerationActive
            )
                return

            if (
                exitCode === 0
            ) {

                root.generateCurrentThumbnail()

            } else {

                root.advanceThumbnailQueue()
            }
        }
    }


    Process {
        id: thumbnailProcess

        running: false
        command: []

        onExited: (
            exitCode,
            exitStatus
        ) => {

            if (
                !root.thumbnailGenerationActive ||
                !root.currentThumbnailJob
            ) {
                return
            }

            if (
                exitCode === 0
            ) {

                root.thumbnailsGenerated++

            } else {

                console.warn(
                    "Thumbnail failed:",
                    root.currentThumbnailJob.source,
                    "exit code:",
                    exitCode
                )
            }

            root.advanceThumbnailQueue()
        }

        stderr: StdioCollector {

            onStreamFinished: {

                if (text.length > 0) {

                    console.warn(
                        "Thumbnail generator output:",
                        text
                    )
                }
            }
        }
    }


    // ============================================================
    // THUMBNAIL TIMER
    // ============================================================

    Timer {
        id: thumbnailTimer

        interval: 1000
        running: false

        onTriggered:
            root.generateThumbnails()
    }


    onDesktopDirChanged: {

        if (desktopDir)
            thumbnailTimer.running = true
    }


    onInitialLoadCompleteChanged: {

        if (
            initialLoadComplete &&
            thumbnailRunPending &&
            !thumbnailGenerationActive
        ) {

            thumbnailTimer.restart()
        }
    }
}
