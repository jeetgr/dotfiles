//@ pragma UseQApplication
import QtQuick
import QtQuick.Layouts
import Quickshell

ShellRoot {
    // Touch singleton early so pills can call Osd during first paint.
    readonly property bool _osdReady: !!Osd

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

                    ActiveWindowPill {
                        id: activeWindow

                        anchors.left: workspaces.right
                        anchors.leftMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        maxWidth: {
                            let left = workspaces.x + workspaces.width + 6;
                            let room = clock.x - left - 18;
                            // Share left-of-clock space with media when both visible.
                            return Math.max(0, room * 0.55);
                        }
                        z: 1
                    }

                    ClockWidget {
                        id: clock

                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        z: 2
                    }

                    MediaPill {
                        anchors.left: activeWindow.visible ? activeWindow.right : workspaces.right
                        anchors.leftMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        maxWidth: {
                            let leftEdge = activeWindow.visible ? (activeWindow.x + activeWindow.width) : (workspaces.x + workspaces.width);
                            return Math.max(0, clock.x - leftEdge - 18);
                        }
                        z: 1
                    }

                    RowLayout {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        z: 1

                        CpuPill {
                        }

                        MemoryPill {
                        }

                        BacklightPill {
                        }

                        VolumePill {
                        }

                        MicPill {
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

                        PowerPill {
                        }

                    }

                }

            }

        }

    }

    LazyLoader {
        active: Osd.visible

        OsdWindow {
        }

    }

}
