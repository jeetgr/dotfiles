import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.modules.bar.pills

PanelWindow {
    property var modelData

    screen: modelData
    implicitHeight: Tokens.barHeight
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

    Item {
        anchors.fill: parent

        Workspaces {
            id: workspaces

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
        }

        ActiveWindowPill {
            id: activeWindow

            anchors.left: workspaces.right
            anchors.leftMargin: Tokens.rowGap
            anchors.verticalCenter: parent.verticalCenter
            maxWidth: {
                let left = workspaces.x + workspaces.width + Tokens.rowGap;
                let room = clock.x - left - 18;
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
            anchors.leftMargin: Tokens.rowGap
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
            spacing: Tokens.rowGap
            z: 1

            Cluster {
                CpuPill {
                    flat: true
                }

                MemoryPill {
                    flat: true
                }

                BacklightPill {
                    flat: true
                }

                VolumePill {
                    flat: true
                }

                MicPill {
                    flat: true
                }

                BluetoothPill {
                    flat: true
                }

                NetworkPill {
                    flat: true
                }

                BatteryPill {
                    flat: true
                }

            }

            TrayWidget {
            }

            PowerPill {
            }

        }

    }

}
