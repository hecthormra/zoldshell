import QtQuick
import QtQuick.Layouts
import qs.settings 1.0

SettingsPage {
    id: root

    title: "Desktop"
    description: "Configurações do ambiente de trabalho."

    SettingsSwitchRow {
        theme: root.theme

        title: "Widgets no desktop"
        description: "Exibir os widgets diretamente no desktop."

        checked: root.settings
                 ? root.settings.desktopWidgetsVisible
                 : false

        onToggled: {
            if (root.settings)
                root.settings.desktopWidgetsVisible = value
        }
    }

    SettingsSliderRow {
        theme: root.theme

        title: "Tamanho dos ícones"
        description: "Tamanho dos ícones do desktop."

        from: 24
        to: 128
        stepSize: 4

        value: root.settings
               ? root.settings.desktopIconSize
               : 48

        onValueEdited: {
            if (root.settings)
                root.settings.desktopIconSize = value
        }
    }

    SettingsSliderRow {
        theme: root.theme

        title: "Espaçamento"

        from: 0
        to: 64
        stepSize: 2

        value: root.settings
               ? root.settings.desktopSpacing
               : 8

        onValueEdited: {
            if (root.settings)
                root.settings.desktopSpacing = value
        }
    }
}
