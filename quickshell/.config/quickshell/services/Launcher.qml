import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.components
import qs.services
pragma Singleton

QtObject {
    id: root

    property bool visible: false
    property string query: ""
    property int selectedIndex: 0
    property int maxResults: 24
    property var frecency: ({
        "apps": {
        },
        "commands": []
    })
    property var clips: []
    property var pins: []
    property int thumbRev: 0
    property var pendingPin: null
    property var pathCommands: []
    readonly property string mode: {
        let q = root.query;
        if (q.startsWith(">"))
            return "run";

        if (q.startsWith(";"))
            return "clip";

        if (q.startsWith("="))
            return "calc";

        if (q.startsWith(":"))
            return "power";

        if (q.startsWith("#"))
            return "windows";

        return "apps";
    }
    readonly property string needle: {
        let q = root.query;
        if (q.startsWith(">") || q.startsWith(";") || q.startsWith("=") || q.startsWith(":") || q.startsWith("#"))
            return q.slice(1).replace(/^\s+/, "");

        return q.trim();
    }
    readonly property string placeholder: {
        if (root.mode === "run")
            return "Run a command…";

        if (root.mode === "clip")
            return "Search clipboard…";

        if (root.mode === "calc")
            return "Evaluate…";

        if (root.mode === "power")
            return "Lock, logout, suspend…";

        if (root.mode === "windows")
            return "Switch windows…";

        return "Search apps…    > run    ; clip    = calc    : power    # windows";
    }
    readonly property string modeLabel: {
        if (root.mode === "run")
            return "Run";

        if (root.mode === "clip")
            return "Clip";

        if (root.mode === "calc")
            return "Calc";

        if (root.mode === "power")
            return "Power";

        if (root.mode === "windows")
            return "Windows";

        return "Apps";
    }
    readonly property color modeColor: {
        if (root.mode === "run")
            return Colors.green;

        if (root.mode === "clip")
            return Colors.peach;

        if (root.mode === "calc")
            return Colors.yellow;

        if (root.mode === "power")
            return Colors.red;

        if (root.mode === "windows")
            return Colors.sky;

        return Colors.mauve;
    }
    readonly property string modeGlyph: {
        if (root.mode === "run")
            return "";

        if (root.mode === "clip")
            return "󰅌";

        if (root.mode === "calc")
            return "󰃬";

        if (root.mode === "power")
            return "󰐥";

        if (root.mode === "windows")
            return "󰖯";

        return "󰀻";
    }
    readonly property var results: {
        let _q = root.query;
        let _clips = root.clips;
        let _pins = root.pins;
        let _thumbRev = root.thumbRev;
        let _freq = root.frecency;
        let _apps = DesktopEntries.applications;
        let _cmds = root.pathCommands;
        let _wins = Hyprland.toplevels;
        return root.buildResults();
    }
    property string homeDir: Quickshell.env("HOME") || ""
    readonly property string clipTools: (root.homeDir || "/home/jeetgr") + "/.config/hypr/scripts/clip-tools.sh"
    readonly property string clipStateDir: (root.homeDir || "/home/jeetgr") + "/.local/state/quickshell"
    property Process mkdirProc
    property FileView frecencyFile
    property FileView pinsFile
    property Process pathProc
    property Process clipProc
    property Process thumbProc
    property Process pinProc

    function fuzzyScore(query, text) {
        if (!text)
            return -1;

        if (!query)
            return 1;

        let q = query.toLowerCase();
        let t = text.toLowerCase();
        let idx = t.indexOf(q);
        if (idx >= 0)
            return 1200 - idx * 4 + (idx === 0 ? 80 : 0) - Math.max(0, t.length - q.length) * 0.02;

        let ti = 0;
        let score = 0;
        let prev = -2;
        for (let i = 0; i < q.length; i++) {
            let found = t.indexOf(q[i], ti);
            if (found < 0)
                return -1;

            if (found === prev + 1)
                score += 10;

            if (found === 0 || t[found - 1] === " " || t[found - 1] === "-" || t[found - 1] === ".")
                score += 14;

            score += 3;
            prev = found;
            ti = found + 1;
        }
        return score - t.length * 0.05;
    }

    function appScore(query, app) {
        let name = app.name || "";
        let generic = app.genericName || "";
        let id = app.id || "";
        let comment = app.comment || "";
        let keywords = "";
        if (app.keywords && app.keywords.length)
            keywords = app.keywords.join(" ");

        let best = Math.max(root.fuzzyScore(query, name), root.fuzzyScore(query, generic) * 0.7, root.fuzzyScore(query, id) * 0.5, root.fuzzyScore(query, comment) * 0.4, root.fuzzyScore(query, keywords) * 0.45);
        if (best < 0)
            return -1;

        return best + root.appFrecency(app.id);
    }

    function appFrecency(id) {
        if (!id)
            return 0;

        let entry = (root.frecency.apps || {
        })[id];
        if (!entry)
            return 0;

        let hours = Math.max(0, (Date.now() - (entry.last || 0)) / 3.6e+06);
        return (entry.count || 0) * 18 / (1 + hours / 18);
    }

    function evalMath(expr) {
        let s = (expr || "").replace(/\s/g, "");
        if (!s.length)
            return null;

        if (!/^[0-9+\-*/().%]+$/.test(s))
            return null;

        try {
            let result = Function('"use strict"; return (' + s + ")")();
            if (typeof result !== "number" || !isFinite(result))
                return null;

            return result;
        } catch (e) {
            return null;
        }
    }

    function allApps() {
        return DesktopEntries.applications.values || [];
    }

    function buildResults() {
        let mode = root.mode;
        let needle = root.needle;
        let out = [];
        if (mode === "apps") {
            let apps = root.allApps();
            for (let i = 0; i < apps.length; i++) {
                let app = apps[i];
            if (!app || app.noDisplay)
                continue;

                let score = root.appScore(needle, app);
                if (score < 0)
                    continue;

                out.push({
                    "kind": "app",
                    "title": app.name || app.id || "App",
                    "subtitle": app.genericName || app.comment || "",
                    "icon": app.icon || "",
                    "glyph": "󰀻",
                    "score": score,
                    "app": app
                });
            }
            out.sort((a, b) => {
                if (b.score !== a.score)
                    return b.score - a.score;

                return (a.title || "").localeCompare(b.title || "");
            });
        } else if (mode === "run") {
            let seen = {
            };
            let recents = root.frecency.commands || [];
            for (let i = 0; i < recents.length; i++) {
                let cmd = recents[i];
                if (!cmd)
                    continue;

                if (needle.length && root.fuzzyScore(needle, cmd) < 0)
                    continue;

                seen[cmd] = true;
                out.push({
                    "kind": "run",
                    "title": cmd,
                    "subtitle": "Recent",
                    "icon": "",
                    "glyph": "󰋚",
                    "score": 4000 - i,
                    "command": cmd
                });
            }
            let bins = root.pathCommands || [];
            for (let i = 0; i < bins.length; i++) {
                let cmd = bins[i];
                if (!cmd || seen[cmd])
                    continue;

                let score = needle.length ? root.fuzzyScore(needle, cmd) : 1;
                if (score < 0)
                    continue;

                seen[cmd] = true;
                out.push({
                    "kind": "run",
                    "title": cmd,
                    "subtitle": "Command",
                    "icon": "",
                    "glyph": "",
                    "score": needle.length ? score : 0,
                    "command": cmd
                });
            }
            out.sort((a, b) => {
                if (b.score !== a.score)
                    return b.score - a.score;

                return (a.title || "").localeCompare(b.title || "");
            });
            if (needle.length && !seen[needle])
                out.unshift({
                "kind": "run",
                "title": needle,
                "subtitle": "Run in background",
                "icon": "",
                "glyph": "",
                "score": 5000,
                "command": needle
            });

        } else if (mode === "clip") {
            let pinIds = {
            };
            let pins = root.pins || [];
            for (let i = 0; i < pins.length; i++) {
                let item = pins[i];
                if (!item || !item.id)
                    continue;

                pinIds[item.id] = true;
                let hay = (item.preview || "") + " " + (item.id || "");
                if (needle.length && root.fuzzyScore(needle, hay) < 0)
                    continue;

                out.push(root.clipResult(item, true, i));
            }
            let clips = root.clips || [];
            for (let i = 0; i < clips.length; i++) {
                let item = clips[i];
                if (!item || pinIds[item.id])
                    continue;

                let preview = item.preview || item.line || "";
                if (needle.length && root.fuzzyScore(needle, preview) < 0)
                    continue;

                out.push(root.clipResult(item, false, i));
            }
        } else if (mode === "calc") {
            if (!needle.length) {
                out.push({
                    "kind": "hint",
                    "title": "Type an expression",
                    "subtitle": "e.g.  (12 + 8) * 1.18",
                    "icon": "",
                    "glyph": "󰃬",
                    "score": 0
                });
            } else {
                let value = root.evalMath(needle);
                if (value === null)
                    out.push({
                    "kind": "hint",
                    "title": "Can't evaluate",
                    "subtitle": "Numbers and + − * / % ( ) only",
                    "icon": "",
                    "glyph": "󰃬",
                    "score": 0
                });
                else
                    out.push({
                    "kind": "calc",
                    "title": String(value),
                    "subtitle": needle + "  →  copy",
                    "icon": "",
                    "glyph": "󰃬",
                    "score": 1000,
                    "value": String(value)
                });
            }
        } else if (mode === "power") {
            let actions = PowerMenu.actions || [];
            for (let i = 0; i < actions.length; i++) {
                let a = actions[i];
                if (needle.length && (a.label || "").toLowerCase().indexOf(needle.toLowerCase()) < 0 && (a.id || "").indexOf(needle.toLowerCase()) < 0)
                    continue;

                out.push({
                    "kind": "power",
                    "title": a.label,
                    "subtitle": "Power",
                    "icon": "",
                    "glyph": a.glyph,
                    "score": 1000 - i,
                    "actionId": a.id
                });
            }
        } else if (mode === "windows") {
            let wins = (Hyprland.toplevels && Hyprland.toplevels.values) || [];
            let focusedWs = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1;
            for (let i = 0; i < wins.length; i++) {
                let t = wins[i];
                if (!t || Windows.isShellWindow(t))
                    continue;

                let title = Windows.titleOf(t);
                let cls = Windows.classOf(t);
                if (!title.length && !cls.length)
                    continue;

                let hay = (title + " " + cls).trim();
                let score = needle.length ? root.fuzzyScore(needle, hay) : 1;
                if (score < 0)
                    continue;

                if (t.urgent)
                    score += 3000;
                if (t.workspace && t.workspace.id === focusedWs)
                    score += 400;
                if (t.activated)
                    score -= 80;

                let wsLabel = Windows.workspaceLabel(t);
                out.push({
                    "kind": "window",
                    "title": title.length ? title : cls,
                    "subtitle": (wsLabel ? wsLabel + " · " : "") + (cls || "window"),
                    "icon": Windows.iconForToplevel(t),
                    "glyph": t.urgent ? "󰀨" : "󰖯",
                    "score": score,
                    "selector": Windows.selector(t),
                    "wayland": t.wayland
                });
            }
            out.sort((a, b) => {
                if (b.score !== a.score)
                    return b.score - a.score;

                return (a.title || "").localeCompare(b.title || "");
            });
        }
        let cap = mode === "run" ? 64 : root.maxResults;
        if (out.length > cap)
            out = out.slice(0, cap);

        return out;
    }

    function open() {
        Notifications.close();
        Cheatsheet.close();
        root.query = "";
        root.selectedIndex = 0;
        root.visible = true;
    }

    function openRun() {
        Notifications.close();
        Cheatsheet.close();
        root.query = ">";
        root.selectedIndex = 0;
        root.visible = true;
        if (root.pathCommands.length === 0)
            root.refreshPathCommands();

    }

    function openClip() {
        Notifications.close();
        Cheatsheet.close();
        root.query = ";";
        root.selectedIndex = 0;
        root.visible = true;
        root.refreshClips();
    }

    function openWindows() {
        if (root.visible && root.mode === "windows") {
            root.close();
            return ;
        }
        Notifications.close();
        Cheatsheet.close();
        Hyprland.refreshToplevels();
        root.query = "#";
        root.selectedIndex = 0;
        root.visible = true;
    }

    function openPower() {
        if (root.visible && root.mode === "power") {
            root.close();
            return ;
        }
        Notifications.close();
        Cheatsheet.close();
        root.query = ":";
        root.selectedIndex = 0;
        root.visible = true;
    }

    function close() {
        root.visible = false;
        root.query = "";
        root.selectedIndex = 0;
    }

    function toggle() {
        if (root.visible)
            root.close();
        else
            root.open();
    }

    function moveSelection(delta) {
        let count = root.results.length;
        if (count === 0) {
            root.selectedIndex = 0;
            return ;
        }
        root.selectedIndex = (root.selectedIndex + delta + count) % count;
    }

    function activateSelected() {
        let items = root.results;
        if (items.length === 0)
            return ;

        let index = Math.max(0, Math.min(items.length - 1, root.selectedIndex));
        root.activate(items[index]);
    }

    function activate(item) {
        if (!item || item.kind === "hint")
            return ;

        if (item.kind === "app")
            root.launchApp(item.app);
        else if (item.kind === "run")
            root.runCommand(item.command);
        else if (item.kind === "clip")
            root.copyClip(item);
        else if (item.kind === "calc")
            root.copyText(item.value);
        else if (item.kind === "power") {
            PowerMenu.run(item.actionId);
            root.close();
        } else if (item.kind === "window")
            root.focusWindow(item);
    }

    function launchApp(app) {
        if (!app)
            return ;

        app.execute();
        root.bumpApp(app.id);
        root.close();
    }

    function runCommand(command) {
        if (!command || !command.trim().length)
            return ;

        let cmd = command.trim();
        Quickshell.execDetached(["zsh", "-lc", cmd]);
        root.bumpCommand(cmd);
        root.close();
    }

    function focusWindow(item) {
        if (!item)
            return ;

        if (item.selector && item.selector.length)
            Hyprland.dispatch("hl.dsp.focus({ window = \"" + item.selector + "\" })");
        else if (item.wayland && item.wayland.activate)
            item.wayland.activate();

        root.close();
    }

    function clipId(line) {
        if (!line)
            return "";

        let tab = line.indexOf("\t");
        return tab >= 0 ? line.slice(0, tab) : line;
    }

    function isImagePreview(preview) {
        return /\[\[ binary data .*\b(png|jpe?g|webp|gif|bmp)\b/i.test(preview || "");
    }

    function imageLabel(preview) {
        let m = (preview || "").match(/binary data\s+(\S+(?:\s+\S+)?)\s+(\S+)\s+(\S+)/i);
        if (!m)
            return "Image";

        let mime = (m[2] || "image").toUpperCase();
        let size = m[3] || "";
        return size ? (mime + " · " + size) : mime;
    }

    function clipMime(item) {
        if (!item || !item.isImage)
            return "text/plain";

        let p = (item.preview || "").toLowerCase();
        if (p.indexOf("jpeg") >= 0 || p.indexOf("jpg") >= 0)
            return "image/jpeg";
        if (p.indexOf("webp") >= 0)
            return "image/webp";
        if (p.indexOf("gif") >= 0)
            return "image/gif";
        return "image/png";
    }

    function thumbPath(id) {
        return root.clipStateDir + "/clip-thumbs/" + id;
    }

    function pinPath(id) {
        return root.clipStateDir + "/clip-pins/" + id;
    }

    function clipResult(item, pinned, index) {
        let isImage = !!item.isImage;
        let thumb = "";
        if (isImage) {
            if (item.file && item.file.length)
                thumb = item.file;
            else
                thumb = root.thumbPath(item.id);
        }
        return {
            "kind": "clip",
            "id": item.id,
            "line": item.line,
            "preview": item.preview,
            "isImage": isImage,
            "pinned": pinned,
            "file": item.file || "",
            "thumbPath": thumb,
            "title": isImage ? root.imageLabel(item.preview) : (item.preview || "").replace(/\s+/g, " "),
            "subtitle": pinned ? "Pinned" : (isImage ? "Image" : "Clipboard"),
            "icon": "",
            "glyph": pinned ? "󰐃" : (isImage ? "󰋩" : "󰅌"),
            "score": (pinned ? 2000 : 1000) - index
        };
    }

    function selectedClip() {
        if (root.mode !== "clip")
            return null;

        let items = root.results;
        if (!items.length)
            return null;

        let index = Math.max(0, Math.min(items.length - 1, root.selectedIndex));
        let item = items[index];
        return item && item.kind === "clip" ? item : null;
    }

    function pinSelected() {
        root.togglePin(root.selectedClip());
    }

    function deleteSelected() {
        root.deleteClip(root.selectedClip());
    }

    function togglePin(item) {
        if (!item || item.kind !== "clip" || !item.id)
            return ;

        if (item.pinned) {
            root.removePin(item.id);
            return ;
        }
        root.pendingPin = item;
        pinProc.running = false;
        pinProc.running = true;
    }

    function removePin(id) {
        let current = root.pins || [];
        let gone = current.filter((p) => {
            return p.id === id;
        });
        root.pins = current.filter((p) => {
            return p.id !== id;
        });
        root.savePins();
        for (let i = 0; i < gone.length; i++) {
            if (gone[i].file)
                Quickshell.execDetached(["rm", "-f", gone[i].file]);

        }
    }

    function deleteClip(item) {
        if (!item || item.kind !== "clip")
            return ;

        if (item.pinned)
            root.removePin(item.id);

        if (item.line)
            Quickshell.execDetached([root.clipTools, "delete", item.line]);

        root.clips = (root.clips || []).filter((c) => {
            return c.id !== item.id && c.line !== item.line;
        });
        if (item.isImage && item.id)
            Quickshell.execDetached(["rm", "-f", root.thumbPath(item.id)]);

    }

    function copyClip(item) {
        if (!item)
            return ;

        if (item.file && item.file.length) {
            Quickshell.execDetached(["bash", "-c", "wl-copy --type \"$1\" < \"$2\"", "_", root.clipMime(item), item.file]);
            root.close();
            return ;
        }
        if (!item.line)
            return ;

        Quickshell.execDetached(["bash", "-c", "printf '%s\\n' \"$1\" | cliphist decode | wl-copy", "_", item.line]);
        root.close();
    }

    function copyText(text) {
        if (text === undefined || text === null)
            return ;

        Quickshell.execDetached(["bash", "-c", "printf '%s' \"$1\" | wl-copy", "_", String(text)]);
        root.close();
    }

    function bumpApp(id) {
        if (!id)
            return ;

        let apps = Object.assign({
        }, root.frecency.apps || {
        });
        let prev = apps[id] || {
            "count": 0,
            "last": 0
        };
        apps[id] = {
            "count": (prev.count || 0) + 1,
            "last": Date.now()
        };
        root.frecency = {
            "apps": apps,
            "commands": root.frecency.commands || []
        };
        root.saveFrecency();
    }

    function bumpCommand(command) {
        let list = (root.frecency.commands || []).filter((c) => {
            return c !== command;
        });
        list.unshift(command);
        if (list.length > 32)
            list = list.slice(0, 32);

        root.frecency = {
            "apps": root.frecency.apps || {
            },
            "commands": list
        };
        root.saveFrecency();
    }

    function saveFrecency() {
        try {
            frecencyFile.setText(JSON.stringify(root.frecency));
        } catch (e) {
        }
    }

    function loadFrecency() {
        try {
            let text = frecencyFile.text();
            if (!text || !text.trim().length)
                return ;

            let data = JSON.parse(text);
            if (!data || typeof data !== "object")
                return ;

            root.frecency = {
                "apps": data.apps || {
                },
                "commands": data.commands || []
            };
        } catch (e) {
        }
    }

    function savePins() {
        try {
            pinsFile.setText(JSON.stringify({
                "pins": root.pins || []
            }));
        } catch (e) {
        }
    }

    function loadPins() {
        try {
            let text = pinsFile.text();
            if (!text || !text.trim().length)
                return ;

            let data = JSON.parse(text);
            if (data && Array.isArray(data.pins))
                root.pins = data.pins;
            else if (Array.isArray(data))
                root.pins = data;
        } catch (e) {
        }
    }

    function refreshClips() {
        clipProc.running = false;
        clipProc.running = true;
    }

    function refreshThumbs() {
        thumbProc.running = false;
        thumbProc.running = true;
    }

    function refreshPathCommands() {
        pathProc.running = false;
        pathProc.running = true;
    }

    onModeChanged: {
        if (root.visible && root.mode === "clip")
            root.refreshClips();

        if (root.visible && root.mode === "run" && root.pathCommands.length === 0)
            root.refreshPathCommands();

    }
    onResultsChanged: {
        if (root.selectedIndex >= root.results.length)
            root.selectedIndex = Math.max(0, root.results.length - 1);

    }

    mkdirProc: Process {
        command: ["bash", "-c", "mkdir -p \"$1/clip-thumbs\" \"$1/clip-pins\"", "_", root.clipStateDir]
        running: root.homeDir.length > 0
    }

    frecencyFile: FileView {
        path: root.homeDir.length ? `${root.homeDir}/.local/state/quickshell/launcher-frecency.json` : ""
        onLoaded: root.loadFrecency()
        onPathChanged: {
            if (path)
                reload();

        }
    }

    pinsFile: FileView {
        path: root.homeDir.length ? `${root.homeDir}/.local/state/quickshell/clip-pins.json` : ""
        printErrors: false
        onLoaded: root.loadPins()
        onPathChanged: {
            if (path)
                reload();

        }
    }

    pathProc: Process {
        property var lines: []

        command: ["bash", "-c", "compgen -c | awk 'NF && !seen[$0]++'"]
        running: true
        onRunningChanged: {
            if (running)
                lines = [];

        }
        onExited: {
            let raw = pathProc.lines || [];
            raw.sort((a, b) => {
                return a.localeCompare(b);
            });
            root.pathCommands = raw;
        }

        stdout: SplitParser {
            onRead: (line) => {
                let name = line.trim();
                if (name.length)
                    pathProc.lines.push(name);

            }
        }

    }

    clipProc: Process {
        property var lines: []

        command: ["cliphist", "list"]
        running: false
        onRunningChanged: {
            if (running)
                lines = [];

        }
        onExited: {
            let out = [];
            let raw = clipProc.lines || [];
            for (let i = 0; i < raw.length; i++) {
                let line = raw[i];
                if (!line || !line.length)
                    continue;

                let tab = line.indexOf("\t");
                let id = tab >= 0 ? line.slice(0, tab) : line;
                let preview = tab >= 0 ? line.slice(tab + 1) : line;
                out.push({
                    "line": line,
                    "id": id,
                    "preview": preview,
                    "isImage": root.isImagePreview(preview)
                });
            }
            root.clips = out;
            if (out.some((c) => {
                return c.isImage;
            }))
                root.refreshThumbs();
        }

        stdout: SplitParser {
            onRead: (line) => {
                clipProc.lines = clipProc.lines.concat([line]);
            }
        }

    }

    thumbProc: Process {
        command: [root.clipTools, "thumbs", root.clipStateDir + "/clip-thumbs"]
        running: false
        onExited: root.thumbRev += 1
    }

    pinProc: Process {
        command: [root.clipTools, "save", (root.pendingPin && root.pendingPin.line) || "", (root.pendingPin && root.pinPath(root.pendingPin.id)) || ""]
        running: false
        onExited: {
            let item = root.pendingPin;
            root.pendingPin = null;
            if (exitCode !== 0 || !item || !item.id)
                return ;

            let file = root.pinPath(item.id);
            let pins = (root.pins || []).filter((p) => {
                return p.id !== item.id;
            });
            pins.unshift({
                "id": item.id,
                "line": item.line,
                "preview": item.preview,
                "isImage": !!item.isImage,
                "file": file
            });
            while (pins.length > 20) {
                let drop = pins.pop();
                if (drop && drop.file)
                    Quickshell.execDetached(["rm", "-f", drop.file]);

            }
            root.pins = pins;
            root.savePins();
        }
    }

}
