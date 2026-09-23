import QtQuick
import qs.settings 1.0

SettingsPage {
    id: root

    title: "Widgets"
    description: "Controle os widgets do shell."

    SettingsSwitchRow {
        theme: root.theme

        title: "Medidores de performance"
        description: "Exibir CPU e memória nos widgets."

        checked: root.settings
                 ? root.settings.perfMetersVisible
                 : true

        onToggled: function(value) {
            if (root.settings)
                root.settings.perfMetersVisible = value
        }
    }
}
