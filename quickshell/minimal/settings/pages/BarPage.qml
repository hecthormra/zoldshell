import QtQuick
import QtQuick.Layouts
import qs.settings 1.0

SettingsPage {
    id: root

    title: "Barra"
    description: "Configurações da barra principal."

    SettingsSwitchRow {
        theme: root.theme

        title: "Mostrar Barra"

        checked: root.settings
                 ? root.settings.barVisible
                 : true

        onToggled: {
            if (root.settings)
                root.settings.barVisible = value
        }
    }

    SettingsSliderRow {
        theme: root.theme

        title: "Altura"

        from: 20
        to: 80
        stepSize: 1

        value: root.settings
               ? root.settings.barHeight
               : 32

        onValueEdited: {
            if (root.settings)
                root.settings.barHeight = value
        }
    }
}
