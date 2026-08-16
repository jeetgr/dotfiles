//@ pragma UseQApplication
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

ShellRoot {
    Scope {
        Variants {
            model: Quickshell.screens

            PanelWindow {
                property var modelData

                screen: modelData
                implicitHeight: 36
                color: "transparent"

                anchors {
                    top: true
                    left: true
                    right: true
                }

                margins {
                    top: 6
                    left: 10
                    right: 10
                }

                Rectangle {
                    color: "transparent"
                    anchors.fill: parent

                    Workspaces {
                        id: workspaces

                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    ClockWidget {
                        id: clock

                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Rectangle {
                        id: windowPill

                        readonly property string titleText: {
                            let toplevel = Hyprland.activeToplevel;
                            let focusedWs = Hyprland.focusedMonitor && Hyprland.focusedMonitor.activeWorkspace;
                            if (toplevel && toplevel.title && focusedWs && toplevel.workspace && toplevel.workspace.id === focusedWs.id)
                                return toplevel.title;
                            return "";
                        }
                        readonly property real maxWidth: Math.max(0, clock.x - (workspaces.x + workspaces.width) - 12)

                        anchors.left: workspaces.right
                        anchors.leftMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        visible: titleText.length > 0 && maxWidth > 24
                        width: Math.min(windowTitle.implicitWidth + 24, maxWidth)
                        height: 28
                        radius: 14
                        color: Colors.surface0

                        Text {
                            id: windowTitle

                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            verticalAlignment: Text.AlignVCenter
                            text: windowPill.titleText
                            font.family: "JetBrainsMono Nerd Font Propo"
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: Colors.subtext1
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                    }

                    RowLayout {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        CpuPill {
                        }

                        MemoryPill {
                        }

                        BacklightPill {
                        }

                        VolumePill {
                        }

                        BluetoothPill {
                        }

                        NetworkPill {
                        }

                        TlpPill {
                        }

                        BatteryPill {
                        }

                        TrayWidget {
                        }

                    }

                }

            }

        }

    }

}
