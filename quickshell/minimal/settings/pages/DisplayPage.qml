import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.settings 1.0

SettingsPage {
    id: root

    title: "Tela"
    description: "Resolução, frequência, escala e orientação dos monitores."

    property var outputs: []
    property int selectedOutput: 0

    property string pendingMode: ""
    property real pendingScale: 1.0
    property string pendingTransform: "normal"

    property bool loading: false
    property bool applying: false
    property string statusText: ""

    function refreshOutputs() {
        if (outputsProcess.running)
            return

        root.loading = true
        outputsProcess.running = true
    }

    function parseOutputs(text) {
        try {
            const data = JSON.parse(text)
            const result = []

            for (let i = 0; i < data.length; i++) {
                const output = data[i]

                if (!output)
                    continue

                // Ignora outputs virtuais/inativos
                if (output.name === "__i3")
                    continue

                if (output.active === false)
                    continue

                const currentMode =
                    output.current_mode || {}

                const width =
                    Number(
                        currentMode.width ||
                        output.rect?.width ||
                        0
                    )

                const height =
                    Number(
                        currentMode.height ||
                        output.rect?.height ||
                        0
                    )

                const refresh =
                    Number(
                        currentMode.refresh || 0
                    ) / 1000

                let modeText = ""

                if (width > 0 && height > 0) {
                    modeText =
                        width
                        + "x"
                        + height
                        + "@"
                        + refresh.toFixed(3)
                        + "Hz"
                }

                const modes = []

                if (Array.isArray(output.modes)) {
                    for (let m = 0;
                         m < output.modes.length;
                         m++) {

                        const mode =
                            output.modes[m]

                        const modeHz =
                            Number(mode.refresh || 0)
                            / 1000

                        modes.push({
                            width:
                                Number(mode.width || 0),

                            height:
                                Number(mode.height || 0),

                            hz:
                                modeHz,

                            refresh:
                                Number(mode.refresh || 0),

                            preferred:
                                mode.p == true ||
                                mode.preferred == true
                        })
                    }
                }

                result.push({
                    name:
                        output.name || "Unknown",

                    description:
                        output.make && output.model
                        ? output.make
                          + " "
                          + output.model
                        : (
                            output.description ||
                            output.name ||
                            "Monitor"
                        ),

                    make:
                        output.make || "",

                    model:
                        output.model || "",

                    serial:
                        output.serial || "",

                    active:
                        output.active !== false,

                    focused:
                        output.focused === true,

                    currentMode:
                        modeText,

                    currentWidth:
                        width,

                    currentHeight:
                        height,

                    currentHz:
                        refresh,

                    scale:
                        Number(
                            output.scale || 1.0
                        ),

                    transform:
                        output.transform ||
                        "normal",

                    x:
                        Number(
                            output.rect?.x || 0
                        ),

                    y:
                        Number(
                            output.rect?.y || 0
                        ),

                    modes:
                        modes
                })
            }

            return result

        } catch (error) {
            console.log(
                "DisplayPage: erro ao interpretar JSON:",
                error
            )

            return []
        }
    }

    function selected() {
        if (root.selectedOutput < 0 ||
            root.selectedOutput >= root.outputs.length)

            return null

        return root.outputs[
            root.selectedOutput
        ]
    }

    function initializePending() {
        const output =
            root.selected()

        if (!output)
            return

        root.pendingMode =
            output.currentMode

        root.pendingScale =
            output.scale

        root.pendingTransform =
            output.transform

        root.statusText = ""
    }

    function modeText(mode) {
        return mode.width
               + "×"
               + mode.height
               + " @ "
               + mode.hz.toFixed(3)
               + " Hz"
    }

    function applyChanges() {
        const output =
            root.selected()

        if (!output)
            return

        root.applying = true
        root.statusText = "Aplicando configuração..."

        applyModeProcess.command = [
            "swaymsg",
            "output",
            output.name,
            "mode",
            root.pendingMode
        ]

        applyModeProcess.running = true
    }

    function applyScale() {
        const output =
            root.selected()

        if (!output)
            return

        applyScaleProcess.command = [
            "swaymsg",
            "output",
            output.name,
            "scale",
            String(root.pendingScale)
        ]

        applyScaleProcess.running = true
    }

    function applyTransform() {
        const output =
            root.selected()

        if (!output)
            return

        applyTransformProcess.command = [
            "swaymsg",
            "output",
            output.name,
            "transform",
            root.pendingTransform
        ]

        applyTransformProcess.running = true
    }

    Process {
        id: outputsProcess

        command: [
            "swaymsg",
            "-r",
            "-t",
            "get_outputs"
        ]

        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const parsed =
                    root.parseOutputs(this.text)

                console.log(
                    "DisplayPage: outputs detectados =",
                    parsed.length
                )

                for (let i = 0;
                     i < parsed.length;
                     i++) {

                    console.log(
                        "DisplayPage:",
                        parsed[i].name,
                        parsed[i].description,
                        parsed[i].currentMode
                    )
                }

                root.outputs = parsed

                if (root.selectedOutput >=
                    parsed.length)

                    root.selectedOutput = 0

                root.initializePending()

                root.loading = false
            }
        }

        onExited: {
            root.loading = false
        }
    }

    Process {
        id: applyModeProcess

        command: []
        running: false

        onExited: {
            if (exitCode === 0) {
                root.statusText =
                    "Resolução aplicada."

                root.applyScale()
            } else {
                root.statusText =
                    "Não foi possível aplicar a resolução."

                root.applying = false
            }
        }
    }

    Process {
        id: applyScaleProcess

        command: []
        running: false

        onExited: {
            if (exitCode === 0) {
                root.statusText =
                    "Escala aplicada."

                root.applyTransform()
            } else {
                root.statusText =
                    "Não foi possível aplicar a escala."

                root.applying = false
            }
        }
    }

    Process {
        id: applyTransformProcess

        command: []
        running: false

        onExited: {
            if (exitCode === 0) {
                root.statusText =
                    "Configuração aplicada."

                root.applying = false

                refreshTimer.restart()
            } else {
                root.statusText =
                    "Não foi possível aplicar a orientação."

                root.applying = false
            }
        }
    }

    Timer {
        id: refreshTimer

        interval: 500

        onTriggered: {
            root.refreshOutputs()
        }
    }

    Component.onCompleted: {
        root.refreshOutputs()
    }

    ColumnLayout {
        Layout.fillWidth: true

        spacing: 12

        Text {
            text: "MONITORES"

            color:
                root.theme.textSecondary

            font.family:
                "JetBrains Mono Nerd Font"

            font.pixelSize: 10
            font.bold: true

            Layout.fillWidth: true
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight:
                root.outputs.length > 1
                ? 58 + root.outputs.length * 42
                : 70

            radius: 10

            color:
                root.theme.bgSurface

            border.width: 1

            border.color:
                root.theme.bgBorder

            ColumnLayout {
                anchors.fill: parent

                anchors.leftMargin: 14
                anchors.rightMargin: 14

                anchors.topMargin: 10
                anchors.bottomMargin: 10

                spacing: 6

                Repeater {
                    model: root.outputs

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        Layout.preferredHeight: 40

                        radius: 8

                        color:
                            index === root.selectedOutput
                            ? root.theme.bgSelected
                            : root.theme.bgHover

                        border.width:
                            index === root.selectedOutput
                            ? 1
                            : 0

                        border.color:
                            root.theme.accentPrimary

                        RowLayout {
                            anchors.fill: parent

                            anchors.leftMargin: 10
                            anchors.rightMargin: 10

                            spacing: 10

                            Text {
                                text: "󰍹"

                                color:
                                    modelData.focused
                                    ? root.theme.accentPrimary
                                    : root.theme.textSecondary

                                font.family:
                                    "JetBrains Mono Nerd Font"

                                font.pixelSize: 18
                            }

                            ColumnLayout {
                                Layout.fillWidth: true

                                spacing: 1

                                Text {
                                    text:
                                        modelData.name

                                    color:
                                        root.theme.textPrimary

                                    font.family:
                                        "JetBrains Mono Nerd Font"

                                    font.pixelSize: 10
                                    font.bold: true
                                }

                                Text {
                                    text:
                                        modelData.description

                                    color:
                                        root.theme.textSecondary

                                    font.family:
                                        "JetBrains Mono Nerd Font"

                                    font.pixelSize: 8

                                    Layout.fillWidth: true

                                    elide:
                                        Text.ElideRight
                                }
                            }

                            Text {
                                text:
                                    modelData.focused
                                    ? "FOCADO"
                                    : ""

                                color:
                                    root.theme.accentPrimary

                                font.family:
                                    "JetBrains Mono Nerd Font"

                                font.pixelSize: 7
                                font.bold: true
                            }
                        }

                        TapHandler {
                            onTapped: {
                                root.selectedOutput =
                                    index

                                root.initializePending()
                            }
                        }
                    }
                }

                Text {
                    visible:
                        root.outputs.length === 0

                    text:
                        root.loading
                        ? "Detectando monitores..."
                        : "Nenhum monitor detectado."

                    color:
                        root.theme.textSecondary

                    font.family:
                        "JetBrains Mono Nerd Font"

                    font.pixelSize: 10

                    Layout.fillWidth: true
                    Layout.alignment:
                        Qt.AlignVCenter
                }
            }
        }

        Text {
            text: "RESOLUÇÃO E FREQUÊNCIA"

            color:
                root.theme.textSecondary

            font.family:
                "JetBrains Mono Nerd Font"

            font.pixelSize: 10
            font.bold: true

            Layout.fillWidth: true
            Layout.topMargin: 4
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 62

            radius: 10

            color:
                root.theme.bgSurface

            border.width: 1

            border.color:
                root.theme.bgBorder

            RowLayout {
                anchors.fill: parent

                anchors.leftMargin: 14
                anchors.rightMargin: 14

                spacing: 10

                Text {
                    text: "󰹑"

                    color:
                        root.theme.textPrimary

                    font.family:
                        "JetBrains Mono Nerd Font"

                    font.pixelSize: 19
                }

                ColumnLayout {
                    Layout.fillWidth: true

                    spacing: 2

                    Text {
                        text: "Modo de vídeo"

                        color:
                            root.theme.textPrimary

                        font.family:
                            "JetBrains Mono Nerd Font"

                        font.pixelSize: 11
                        font.bold: true
                    }

                    Text {
                        text:
                            root.pendingMode !== ""
                            ? root.pendingMode
                            : "Carregando..."

                        color:
                            root.theme.textSecondary

                        font.family:
                            "JetBrains Mono Nerd Font"

                        font.pixelSize: 9
                    }
                }

                ComboBox {
                    id: modeCombo

                    Layout.preferredWidth: 190

                    enabled:
                        !root.loading &&
                        !root.applying &&
                        root.selected() !== null

                    model:
                        root.selected()
                        ? root.selected().modes
                        : []

                    textRole: ""

                    currentIndex: {
                        const output =
                            root.selected()

                        if (!output)
                            return -1

                        for (let i = 0;
                             i < output.modes.length;
                             i++) {

                            const mode =
                                output.modes[i]

                            const text =
                                mode.width
                                + "x"
                                + mode.height
                                + "@"
                                + mode.hz.toFixed(3)
                                + "Hz"

                            if (text ===
                                root.pendingMode)

                                return i
                        }

                        return -1
                    }

                    delegate: ItemDelegate {
                        required property var modelData

                        width:
                            modeCombo.popup.width

                        text:
                            root.modeText(modelData)

                        contentItem: Text {
                            text:
                                parent.text

                            color:
                                root.theme.textPrimary

                            font.family:
                                "JetBrains Mono Nerd Font"

                            font.pixelSize: 9

                            verticalAlignment:
                                Text.AlignVCenter
                        }

                        background:
                            Rectangle {
                                color:
                                    hovered
                                    ? root.theme.bgHover
                                    : root.theme.bgSurface
                            }
                    }

                    onActivated: function(index) {
                        const output =
                            root.selected()

                        if (!output ||
                            index < 0 ||
                            index >=
                            output.modes.length)

                            return

                        const mode =
                            output.modes[index]

                        root.pendingMode =
                            mode.width
                            + "x"
                            + mode.height
                            + "@"
                            + mode.hz.toFixed(3)
                            + "Hz"

                        root.statusText =
                            "Alterações pendentes."
                    }

                    contentItem: Text {
                        leftPadding: 10
                        rightPadding: 28

                        text:
                            modeCombo.currentIndex >= 0 &&
                            root.selected()
                            ? root.modeText(
                                root.selected()
                                .modes[
                                    modeCombo.currentIndex
                                ]
                              )
                            : "Selecionar modo"

                        color:
                            root.theme.textPrimary

                        font.family:
                            "JetBrains Mono Nerd Font"

                        font.pixelSize: 9

                        verticalAlignment:
                            Text.AlignVCenter

                        elide:
                            Text.ElideRight
                    }

                    background: Rectangle {
                        radius: 8

                        color:
                            root.theme.bgHover

                        border.width: 1

                        border.color:
                            root.theme.bgBorder
                    }
                }
            }
        }

        SettingsSliderRow {
            theme: root.theme

            title: "Escala"

            description:
                "Escala da interface do monitor."

            from: 0.5
            to: 2.0
            stepSize: 0.05

            value:
                root.pendingScale

            onValueEdited: function(value) {
                root.pendingScale =
                    Math.round(value * 100) / 100

                root.statusText =
                    "Alterações pendentes."
            }
        }

        Text {
            text: "ORIENTAÇÃO"

            color:
                root.theme.textSecondary

            font.family:
                "JetBrains Mono Nerd Font"

            font.pixelSize: 10
            font.bold: true

            Layout.fillWidth: true
            Layout.topMargin: 4
        }

        ComboBox {
            id: transformCombo

            Layout.fillWidth: true

            enabled:
                !root.loading &&
                !root.applying &&
                root.selected() !== null

            model: [
                "normal",
                "90",
                "180",
                "270",
                "flipped",
                "flipped-90",
                "flipped-180",
                "flipped-270"
            ]

            currentIndex: {
                for (let i = 0;
                     i < model.length;
                     i++) {

                    if (model[i] ===
                        root.pendingTransform)

                        return i
                }

                return 0
            }

            onActivated: function(index) {
                root.pendingTransform =
                    model[index]

                root.statusText =
                    "Alterações pendentes."
            }

            contentItem: Text {
                leftPadding: 12
                rightPadding: 30

                text:
                    transformCombo.displayText

                color:
                    root.theme.textPrimary

                font.family:
                    "JetBrains Mono Nerd Font"

                font.pixelSize: 10

                verticalAlignment:
                    Text.AlignVCenter
            }

            background: Rectangle {
                radius: 8

                color:
                    root.theme.bgSurface

                border.width: 1

                border.color:
                    root.theme.bgBorder
            }
        }

        Text {
            text: "INFORMAÇÕES"

            color:
                root.theme.textSecondary

            font.family:
                "JetBrains Mono Nerd Font"

            font.pixelSize: 10
            font.bold: true

            Layout.fillWidth: true
            Layout.topMargin: 4
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 118

            radius: 10

            color:
                root.theme.bgSurface

            border.width: 1

            border.color:
                root.theme.bgBorder

            ColumnLayout {
                anchors.fill: parent

                anchors.leftMargin: 14
                anchors.rightMargin: 14

                anchors.topMargin: 10
                anchors.bottomMargin: 10

                spacing: 4

                Text {
                    text:
                        root.selected()
                        ? "Atual: "
                          + root.selected()
                                .currentWidth
                          + "×"
                          + root.selected()
                                .currentHeight
                          + " @ "
                          + root.selected()
                                .currentHz
                                .toFixed(3)
                          + " Hz"
                        : "Atual: —"

                    color:
                        root.theme.textSecondary

                    font.family:
                        "JetBrains Mono Nerd Font"

                    font.pixelSize: 9

                    Layout.fillWidth: true
                }

                Text {
                    text:
                        root.selected()
                        ? "Escala atual: "
                          + root.selected()
                                .scale
                                .toFixed(2)
                        : "Escala atual: —"

                    color:
                        root.theme.textSecondary

                    font.family:
                        "JetBrains Mono Nerd Font"

                    font.pixelSize: 9

                    Layout.fillWidth: true
                }

                Text {
                    text:
                        root.selected()
                        ? "Transformação: "
                          + root.selected()
                                .transform
                        : "Transformação: —"

                    color:
                        root.theme.textSecondary

                    font.family:
                        "JetBrains Mono Nerd Font"

                    font.pixelSize: 9

                    Layout.fillWidth: true
                }

                Text {
                    text:
                        root.selected()
                        ? "Posição: "
                          + root.selected().x
                          + ", "
                          + root.selected().y
                        : "Posição: —"

                    color:
                        root.theme.textSecondary

                    font.family:
                        "JetBrains Mono Nerd Font"

                    font.pixelSize: 9

                    Layout.fillWidth: true
                }

                Text {
                    text:
                        root.selected()
                        ? "Modos disponíveis: "
                          + root.selected()
                                .modes.length
                        : "Modos disponíveis: —"

                    color:
                        root.theme.textMuted

                    font.family:
                        "JetBrains Mono Nerd Font"

                    font.pixelSize: 8

                    Layout.fillWidth: true
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 46

            radius: 10

            color:
                root.statusText !== ""
                ? root.theme.bgSelected
                : root.theme.bgSurface

            border.width: 1

            border.color:
                root.statusText !== ""
                ? root.theme.accentPrimary
                : root.theme.bgBorder

            RowLayout {
                anchors.fill: parent

                anchors.leftMargin: 12
                anchors.rightMargin: 12

                spacing: 10

                Text {
                    Layout.fillWidth: true

                    text:
                        root.statusText !== ""
                        ? root.statusText
                        : "Tudo atualizado"

                    color:
                        root.statusText !== ""
                        ? root.theme.accentPrimary
                        : root.theme.textSecondary

                    font.family:
                        "JetBrains Mono Nerd Font"

                    font.pixelSize: 9
                }

                Rectangle {
                    Layout.preferredWidth: 92
                    Layout.preferredHeight: 32

                    radius: 8

                    color:
                        root.statusText !== ""
                        ? root.theme.accentPrimary
                        : root.theme.bgHover

                    opacity:
                        root.applying ? 0.5 : 1.0

                    Text {
                        anchors.centerIn: parent

                        text:
                            root.applying
                            ? "Aplicando..."
                            : "Aplicar"

                        color:
                            root.statusText !== ""
                            ? root.theme.bgBase
                            : root.theme.textMuted

                        font.family:
                            "JetBrains Mono Nerd Font"

                        font.pixelSize: 9
                        font.bold: true
                    }

                    TapHandler {
                        enabled:
                            !root.applying &&
                            root.selected() !== null &&
                            root.statusText !== ""

                        onTapped: {
                            root.applyChanges()
                        }
                    }
                }
            }
        }

        Text {
            text:
                "Backend: Sway 1.12 + swaymsg JSON"

            color:
                root.theme.textMuted

            font.family:
                "JetBrains Mono Nerd Font"

            font.pixelSize: 8

            Layout.fillWidth: true
        }
    }
}
