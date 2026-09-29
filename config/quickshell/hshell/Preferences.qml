pragma Singleton
import QtQuick
import Quickshell
import qs

Singleton {
    id: root
    property bool visualizer: false
    property bool hoverExpand: true
    property bool mediaCard: true
    property bool tray: true
    property bool notifications: true
    property bool weather: true
    property bool hideFullscreen: true
    property bool workspaceOsd: true
    property bool volumeOsd: true
    property bool showPower: true
    property bool showMic: true
    property bool showCapsLock: true
    property bool showIdle: true
    property bool showNightlight: true
    property bool showBluetooth: true
    property bool showWifi: true
    property real notificationSeconds: 3
    property string wallpaperFolder: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    property string backgroundColor: "141826"
    property string surfaceColor: "#222436"
    property string foregroundColor: "#82AAFF"
    property string accentColor: "#82AAFF"
    property string city: "Riga"
    property var cities: ["Riga"]
    property var pending: []
    property string writingKey: ""
    property var failedItem: []
    property bool loaded: false
    property var editedKeys: ({})
    property string saveError: ""
    readonly property bool saving: writer.running || pending.length > 0
    property var options: ({})
    function option(key, fallback) {
        return options[key] === undefined ? fallback : options[key];
    }
    function folder(key, fallback) {
        return String(option(key, fallback)).replace(/^~(?=\/|$)/, Quickshell.env("HOME"));
    }
    function eventEnabled(kind) {
        return option("events", {})[kind] !== false;
    }
    function setOptions(value) {
        save("options", JSON.stringify(value));
    }
    function searchUrl(engine, query) {
        const urls = {
            Google: "https://www.google.com/search?q=",
            DuckDuckGo: "https://duckduckgo.com/?q=",
            Brave: "https://search.brave.com/search?q=",
            Bing: "https://www.bing.com/search?q=",
            Startpage: "https://www.startpage.com/sp/search?query="
        };
        return (urls[engine] || urls.Google) + encodeURIComponent(query);
    }
    signal colorsReset
    function resetColors() {
        const defaults = {
            backgroundColor: "#080808",
            surfaceColor: "#202020",
            foregroundColor: "#ffffff",
            accentColor: "#ffffff"
        };
        const keys = Object.keys(defaults);
        keys.forEach(key => root[key] = defaults[key]);
        editedKeys = Object.assign({}, editedKeys, {
            backgroundColor: true,
            surfaceColor: true,
            foregroundColor: true,
            accentColor: true
        });
        pending = pending.filter(item => !keys.includes(item[0]) && item[0] !== "colors-reset").concat([["colors-reset", ""]]);
        saveError = "";
        colorsReset();
        flush();
    }
    function save(key, value) {
        editedKeys = Object.assign({}, editedKeys, {
            [key]: true
        });
        saveError = "";
        if (["visualizer", "hoverExpand", "mediaCard", "tray", "notifications", "weather", "hideFullscreen", "workspaceOsd", "volumeOsd", "showPower", "showMic", "showCapsLock", "showIdle", "showNightlight", "showBluetooth", "showWifi"].includes(key))
            root[key] = value === "true";
        if (["wallpaperFolder", "backgroundColor", "surfaceColor", "foregroundColor", "accentColor"].includes(key))
            root[key] = value;
        if (key === "notificationSeconds")
            notificationSeconds = Math.max(0.1, Math.min(10, Number(value)));
        if (key === "cities")
            cities = JSON.parse(value);
        if (key === "city")
            city = value;
        pending = pending.filter(item => item[0] !== key).concat([[key, value]]);
        flush();
    }
    function flush() {
        if (!loaded || writer.running || pending.length === 0 || saveError)
            return;
        const item = pending[0];
        pending = pending.slice(1);
        writingKey = item[0];
        writer.activeItem = item;
        writer.start(item[0] === "colors-reset" ? ["colors-reset"] : ["preference", item[0], item[1]]);
    }
    function reload() {
        if (saving)
            return;
        editedKeys = ({});
        loaded = false;
        reader.start(["preferences"]);
    }
    function retry() {
        saveError = "";
        if (failedItem.length) {
            pending = pending.filter(item => item[0] !== failedItem[0]).concat([failedItem]);
            failedItem = [];
        }
        if (!loaded)
            reader.start(["preferences"]);
        else
            flush();
    }
    Task {
        id: reader
        onFinished: success => {
            if (!success) {
                root.saveError = reader.error || "Could not load settings";
                return;
            }
            ["visualizer", "hoverExpand", "mediaCard", "tray", "notifications", "weather", "hideFullscreen", "workspaceOsd", "volumeOsd", "showPower", "showMic", "showCapsLock", "showIdle", "showNightlight", "showBluetooth", "showWifi"].forEach(k => {
                if (!root.editedKeys[k])
                    root[k] = result[k] !== "false" && result[k] !== false;
            });
            root.options = result.options || {};
            if (!root.editedKeys.visualizer)
                root.visualizer = result.visualizer === true || result.visualizer === "true";
            root.city = result.city || "Riga";
            root.cities = Array.isArray(result.cities) && result.cities.length ? result.cities : [root.city];
            root.notificationSeconds = Math.max(0.1, Math.min(10, Number(result.notificationSeconds || 3)));
            ["wallpaperFolder", "backgroundColor", "surfaceColor", "foregroundColor", "accentColor"].forEach(k => {
                if (result[k] && !root.editedKeys[k])
                    root[k] = result[k];
            });
            root.loaded = true;
            Qt.callLater(root.flush);
        }
    }
    Task {
        id: writer
        property var activeItem: []
        onFinished: success => {
            if (!success) {
                root.failedItem = activeItem;
                root.saveError = writer.error || "Could not save settings";
                return;
            }
            root.failedItem = [];
            if (root.writingKey === "options" && !root.pending.some(item => item[0] === "options"))
                root.options = result.options || JSON.parse(activeItem[1]);
            if (success && root.writingKey === "wallpaperFolder")
                WallpaperState.refreshWallpapers();
            Qt.callLater(root.flush);
        }
    }
    Component.onCompleted: reader.start(["preferences"])
}
