import QtQuick
import qs.components
import qs.services
pragma Singleton

QtObject {
    id: root

    property bool visible: false
    readonly property var groups: [
        {
            "title": "Launch",
            "accent": Colors.mauve,
            "binds": [
                {
                    "keys": "Super  Return",
                    "action": "Terminal"
                },
                {
                    "keys": "Super  E",
                    "action": "Files"
                },
                {
                    "keys": "Super  B",
                    "action": "Browser"
                },
                {
                    "keys": "Super  Space",
                    "action": "Launcher"
                },
                {
                    "keys": "Super  Shift  Space",
                    "action": "Run command"
                },
                {
                    "keys": "Super  Tab",
                    "action": "Window switcher"
                },
                {
                    "keys": "Super  V",
                    "action": "Clipboard"
                },
                {
                    "keys": "Super  N",
                    "action": "Notifications"
                },
                {
                    "keys": "Super  M",
                    "action": "Power menu"
                },
                {
                    "keys": "Super  ?",
                    "action": "This cheatsheet"
                }
            ]
        },
        {
            "title": "Window",
            "accent": Colors.blue,
            "binds": [
                {
                    "keys": "Super  Q",
                    "action": "Close"
                },
                {
                    "keys": "Super  F",
                    "action": "Fullscreen"
                },
                {
                    "keys": "Super  Shift  F",
                    "action": "Maximize"
                },
                {
                    "keys": "Super  Shift  V",
                    "action": "Toggle float"
                },
                {
                    "keys": "Super  P",
                    "action": "Pseudo tile"
                },
                {
                    "keys": "Super  H J K L",
                    "action": "Focus"
                },
                {
                    "keys": "Super  Shift  H J K L",
                    "action": "Move window"
                },
                {
                    "keys": "Super  R",
                    "action": "Resize submap  ·  Esc exit"
                },
                {
                    "keys": "Super  drag / Super  r-click",
                    "action": "Move / resize"
                }
            ]
        },
        {
            "title": "Workspace",
            "accent": Colors.lavender,
            "binds": [
                {
                    "keys": "Super  1–0",
                    "action": "Focus workspace"
                },
                {
                    "keys": "Super  Shift  1–0",
                    "action": "Move to workspace"
                },
                {
                    "keys": "Super  S",
                    "action": "Scratchpad"
                },
                {
                    "keys": "Super  Shift  S",
                    "action": "Send to scratchpad"
                },
                {
                    "keys": "Super  scroll",
                    "action": "Next / prev workspace"
                }
            ]
        },
        {
            "title": "Capture / session",
            "accent": Colors.peach,
            "binds": [
                {
                    "keys": "Print",
                    "action": "Copy region"
                },
                {
                    "keys": "Super  Print",
                    "action": "Copy screen"
                },
                {
                    "keys": "Super  Shift  Print",
                    "action": "Save region"
                },
                {
                    "keys": "Super  Alt  Print",
                    "action": "Edit region"
                },
                {
                    "keys": "Super  Escape",
                    "action": "Lock"
                },
                {
                    "keys": "Super  T",
                    "action": "Toggle touchpad"
                }
            ]
        },
        {
            "title": "Hardware",
            "accent": Colors.teal,
            "binds": [
                {
                    "keys": "Vol  /  mute",
                    "action": "Sink volume"
                },
                {
                    "keys": "Mic mute",
                    "action": "Source mute"
                },
                {
                    "keys": "Brightness",
                    "action": "Backlight"
                },
                {
                    "keys": "Media keys",
                    "action": "Play / next / prev"
                }
            ]
        }
    ]

    function open() {
        Launcher.close();
        Notifications.close();
        root.visible = true;
    }

    function close() {
        root.visible = false;
    }

    function toggle() {
        if (root.visible)
            root.close();
        else
            root.open();
    }

}
