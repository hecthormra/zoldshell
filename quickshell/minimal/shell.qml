//@ pragma UseQApplication
//@ pragma Env QT_QPA_PLATFORMTHEME=gtk3
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import Quickshell
import Quickshell.Io
import QtQuick

import "bar"
import "notifications"
import "theme_switcher"
import "osd"
import "app_launcher"
import "control_center"
// import "dock"
// import "perfmeters"
import "desktop"
import "settings"
import "lockscreen"
import "wallpaper"

Scope {
    id: root

    ThemeSwitcher {
        id: ts
    }
    
    LockScreen {
        id: lockScreen

        theme: ts.theme
    }
 
    /*
     * ============================================================
     * WALLPAPER
     * ============================================================
     */

    WallpaperManager {
        theme: ts.theme
    }

    /*
     * ============================================================
     * CONFIGURAÇÕES GLOBAIS
     * ============================================================
     */

    ShellSettings {
        id: settings
    }

    /*
     * ============================================================
     * CONFIGURAÇÕES
     * ============================================================
     */

    SettingsWindow {
        id: settingsWindow

        theme: ts.theme
        settings: settings
    }

    /*
     * ============================================================
     * DESKTOP
     * ============================================================
     */

    Desktop {
        theme: ts.theme
        settings: settings
    }

    /*
     * ============================================================
     * PERFORMANCE
     * ============================================================
     */

    //PerfMeters {
    //    theme: ts.theme
    //    settings: settings
    //    topOffset: 40
    //}

    /*
     * ============================================================
     * BAR
     * ============================================================
     */

    Bar {
        theme: ts.theme
        settings: settings
        ccPanel: controlCenter
        settingsWindow: settingsWindow
    }

    /*
     * ============================================================
     * DOCK
     * ============================================================
     */

    //DockPanel {
    //    screen: Quickshell.primaryScreen
    //    theme: ts.theme
    //    settings: settings
    //}

    /*
     * ============================================================
     * CONTROL CENTER
     * ============================================================
     */

    ControlCenter {
        id: controlCenter

        theme: ts.theme
    }

    /*
     * ============================================================
     * APP LAUNCHER
     * ============================================================
     */

    AppLauncher {
        theme: ts.theme
    }

    /*
     * ============================================================
     * NOTIFICAÇÕES
     * ============================================================
     */

    NotificationPopup {
        theme: ts.theme
    }

    /*
     * ============================================================
     * OSD
     * ============================================================
     */

    OSD {
        theme: ts.theme
    }
}

