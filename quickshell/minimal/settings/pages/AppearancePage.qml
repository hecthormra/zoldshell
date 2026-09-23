import QtQuick
import QtQuick.Layouts
import qs.settings 1.0

SettingsPage {
    id: root

    title: "Aparência"
    description: "Aparência global do shell."

    SettingsSliderRow {
        theme: root.theme

        title: "Opacidade do painel"

        from: 0.1
        to: 1
        stepSize: 0.05

        value: root.settings
               ? root.settings.panelOpacity
               : 1

        onValueEdited: {
            if (root.settings)
                root.settings.panelOpacity = value
        }
    }

    SettingsSliderRow {
        theme: root.theme

        title: "Raio dos painéis"

        from: 0
        to: 32
        stepSize: 1

        value: root.settings
               ? root.settings.panelRadius
               : 14

        onValueEdited: {
            if (root.settings)
                root.settings.panelRadius = value
        }
    }
}
