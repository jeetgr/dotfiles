//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.bar
import qs.modules.osd
import qs.modules.launcher
import qs.modules.notifications
import qs.modules.cheatsheet
import qs.services

ShellRoot {
    readonly property bool _osdReady: !!Osd
    readonly property bool _launcherReady: !!Launcher
    readonly property bool _notificationsReady: !!Notifications
    readonly property bool _cheatsheetReady: !!Cheatsheet

    Scope {
        Variants {
            model: Quickshell.screens

            Bar {
            }

        }

    }

    LazyLoader {
        active: Osd.visible

        OsdWindow {
        }

    }

    LazyLoader {
        active: Launcher.visible

        LauncherWindow {
        }

    }

    LazyLoader {
        active: Notifications.visible

        NotificationWindow {
        }

    }

    LazyLoader {
        active: Notifications.popupCount > 0 && !Notifications.visible

        NotificationPopup {
        }

    }

    LazyLoader {
        active: Cheatsheet.visible

        CheatsheetWindow {
        }

    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            Launcher.toggle();
        }

        function open(): void {
            Launcher.open();
        }

        function close(): void {
            Launcher.close();
        }

        function openRun(): void {
            Launcher.openRun();
        }

        function openClip(): void {
            Launcher.openClip();
        }

        function openPower(): void {
            Launcher.openPower();
        }

        function openWindows(): void {
            Launcher.openWindows();
        }

    }

    IpcHandler {
        target: "notifications"

        function toggle(): void {
            Notifications.toggle();
        }

        function open(): void {
            Notifications.open();
        }

        function close(): void {
            Notifications.close();
        }

        function clear(): void {
            Notifications.clearAll();
        }

    }

    IpcHandler {
        target: "osd"

        function caps(): void {
            Osd.pollCaps();
        }

        function copied(): void {
            Osd.pushCopied("", false);
        }

    }

    IpcHandler {
        target: "cheatsheet"

        function toggle(): void {
            Cheatsheet.toggle();
        }

        function open(): void {
            Cheatsheet.open();
        }

        function close(): void {
            Cheatsheet.close();
        }

    }

    IpcHandler {
        target: "powermenu"

        function toggle(): void {
            Launcher.openPower();
        }

        function open(): void {
            Launcher.openPower();
        }

        function close(): void {
            Launcher.close();
        }

    }

}
