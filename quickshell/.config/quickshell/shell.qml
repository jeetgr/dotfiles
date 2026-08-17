//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.bar
import qs.modules.osd
import qs.modules.launcher
import qs.modules.power
import qs.services

ShellRoot {
    readonly property bool _osdReady: !!Osd
    readonly property bool _launcherReady: !!Launcher

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
        active: PowerMenu.visible

        PowerWindow {
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

    }

    IpcHandler {
        target: "powermenu"

        function toggle(): void {
            PowerMenu.toggle();
        }

        function open(): void {
            PowerMenu.open();
        }

        function close(): void {
            PowerMenu.close();
        }

    }

}
