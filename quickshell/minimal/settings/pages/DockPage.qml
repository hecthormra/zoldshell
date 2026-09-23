import QtQuick
import QtQuick.Layouts
import qs.settings 1.0

SettingsPage {
    id: root

    title: "Dock"
    description: "Controle a aparência e o comportamento do dock."

    SettingsSwitchRow {
        theme: root.theme

        title: "Mostrar Dock"

        checked: root.settings
                 ? root.settings.dockVisible
                 : true

        onToggled: function(value) {
            if (root.settings)
                root.settings.dockVisible = value
        }
    }

    SettingsSliderRow {
        theme: root.theme

        title: "Tamanho"

        from: 24
        to: 128
        stepSize: 2

        value: root.settings
               ? root.settings.dockSize
               : 48

        onValueEdited: function(value) {
            if (root.settings)
                root.settings.dockSize = value
        }
    }

    SettingsSliderRow {
        theme: root.theme

        title: "Opacidade"

        from: 0
        to: 1
        stepSize: 0.05

        value: root.settings
               ? root.settings.dockOpacity
               : 1

        onValueEdited: function(value) {
            if (root.settings)
                root.settings.dockOpacity = value
        }
    }

    SettingsSliderRow {
        theme: root.theme

        title: "Raio"

        from: 0
        to: 32
        stepSize: 1

        value: root.settings
               ? root.settings.dockRadius
               : 12

        onValueEdited: function(value) {
            if (root.settings)
                root.settings.dockRadius = value
        }
    }
}
