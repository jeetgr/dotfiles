import QtQuick
import Quickshell
import Quickshell.Io
import qs.components
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

        return "apps";
    }
    readonly property string needle: {
        let q = root.query;
        if (q.startsWith(">") || q.startsWith(";") || q.startsWith("=") || q.startsWith(":"))
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

        return "Search apps…    > run    ; clip    = calc    : power";
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

        return "󰀻";
    }
    readonly property var results: {
        let _q = root.query;
        let _clips = root.clips;
        let _freq = root.frecency;
        let _apps = DesktopEntries.applications;
        let _cmds = root.pathCommands;
        return root.buildResults();
    }
    property string homeDir: Quickshell.env("HOME") || ""
    property Process mkdirProc
    property FileView frecencyFile
    property Process pathProc
    property Process clipProc

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
            let clips = root.clips || [];
            for (let i = 0; i < clips.length; i++) {
                let item = clips[i];
                let preview = item.preview || item.line || "";
                if (needle.length && root.fuzzyScore(needle, preview) < 0)
                    continue;

                out.push({
                    "kind": "clip",
                    "title": preview.replace(/\s+/g, " "),
                    "subtitle": "Clipboard",
                    "icon": "",
                    "glyph": "󰅌",
                    "score": 1000 - i,
                    "line": item.line
                });
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
        }
        let cap = mode === "run" ? 64 : root.maxResults;
        if (out.length > cap)
            out = out.slice(0, cap);

        return out;
    }

    function open() {
        root.query = "";
        root.selectedIndex = 0;
        root.visible = true;
    }

    function openRun() {
        root.query = ">";
        root.selectedIndex = 0;
        root.visible = true;
        if (root.pathCommands.length === 0)
            root.refreshPathCommands();

    }

    function openClip() {
        root.query = ";";
        root.selectedIndex = 0;
        root.visible = true;
        root.refreshClips();
    }

    function openPower() {
        if (root.visible && root.mode === "power") {
            root.close();
            return ;
        }
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
            root.copyClip(item.line);
        else if (item.kind === "calc")
            root.copyText(item.value);
        else if (item.kind === "power") {
            PowerMenu.run(item.actionId);
            root.close();
        }
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

    function copyClip(line) {
        if (!line)
            return ;

        Quickshell.execDetached(["bash", "-c", "printf '%s\\n' \"$1\" | cliphist decode | wl-copy", "_", line]);
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

    function refreshClips() {
        clipProc.running = false;
        clipProc.running = true;
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
        command: ["mkdir", "-p", `${root.homeDir}/.local/state/quickshell`]
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
                out.push({
                    "line": line,
                    "preview": tab >= 0 ? line.slice(tab + 1) : line
                });
            }
            root.clips = out;
        }

        stdout: SplitParser {
            onRead: (line) => {
                clipProc.lines = clipProc.lines.concat([line]);
            }
        }

    }

}
