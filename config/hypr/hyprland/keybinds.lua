local mainMod = "SUPER"
local config = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local function quote(value) return "'" .. value:gsub("'", "'\\''") .. "'" end
local function script(name) return "bash " .. quote(config .. "/scripts/" .. name) end
local function shell(panel) return "qs -c hshell ipc call hshell toggle " .. panel end
local overrides = { bindings = {}, extra = {} }
local overrideFile = config .. "/hypr/hyprland/keybind-overrides.lua"
local file = io.open(overrideFile, "r")
if file then file:close(); overrides = dofile(overrideFile) end
local function register(key, action, options)
    local entry = overrides.bindings[key]
    if entry then
        if entry.disabled then return end
        key = entry.key
        if entry.command and entry.command ~= "" then action = hl.dsp.exec_cmd(entry.command) end
    end
    hl.bind(key, action, options)
end
local function bind(key, command) register(mainMod .. " + " .. key, hl.dsp.exec_cmd(command)) end

bind("SHIFT + R", script("screen-measure.sh"))
bind("SHIFT + T", script("screen-ocr.sh"))
bind("slash", "qs -c hshell ipc call hshell tool keybinds")
bind("Tab", "qs -c hshell ipc call hshell overview")
bind("Return", "python3 " .. quote(config .. "/scripts/open-default.py") .. " terminal")
bind("space", shell("launcher"))
bind("X", "python3 " .. quote(config .. "/scripts/open-default.py") .. " text")
bind("F", "python3 " .. quote(config .. "/scripts/open-default.py") .. " files")
bind("B", "python3 " .. quote(config .. "/scripts/open-default.py") .. " browser")
bind("SHIFT + L", script("lock.sh"))
bind("Escape", shell("power"))
bind("SHIFT + space", shell("menu"))
bind("SHIFT + M", "playerctl next")
bind("SHIFT + D", "qs -c hshell ipc call hshell tool download")
bind("SHIFT + C", "qs -c hshell ipc call hshell tool calculator")
bind("SHIFT + V", shell("clipboard"))
bind("SHIFT + U", "qs -c hshell ipc call hshell terminal update")
bind("SHIFT + Y", "qs -c hshell ipc call hshell terminal clean")
bind("SHIFT + E", script("screen-search.sh"))
bind("SHIFT + S", script("screenshot.sh") .. " region")
bind("SHIFT + X", script("screenshot.sh") .. " full")

register(mainMod .. " + Q", hl.dsp.window.close())
register(mainMod .. " + SHIFT + Q", hl.dsp.exit())
register(mainMod .. " + Z", hl.dsp.window.float({ action = "toggle" }))
register(mainMod .. " + W", hl.dsp.window.fullscreen())
register(mainMod .. " + E", hl.dsp.layout("swapsplit"))
register(mainMod .. " + D", hl.dsp.layout("togglesplit"))
for _, direction in ipairs({"left", "right", "up", "down"}) do
    register(mainMod .. " + " .. direction, hl.dsp.focus({ direction = direction }))
    register(mainMod .. " + SHIFT + " .. direction, hl.dsp.window.move({ direction = direction }))
end
for i = 1, 9 do
    register(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
    register(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
register(mainMod .. " + 0", hl.dsp.focus({ workspace = 10 }))
register(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))
register(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
register(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
register(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
register(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
register("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ +5%; qs -c hshell ipc call hshell osd volume"), { locked = true, repeating = true })
register("XF86AudioLowerVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ -5%; qs -c hshell ipc call hshell osd volume"), { locked = true, repeating = true })
register("XF86AudioMute", hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ toggle"), { locked = true })
register("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+; qs -c hshell ipc call hshell osd brightness"), { locked = true, repeating = true })
register("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-; qs -c hshell ipc call hshell osd brightness"), { locked = true, repeating = true })
register("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
register("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
register("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

bind("P", "protonvpn-app")
bind("O", "obs")
bind("R", "resolve")

bind("S", "signal-desktop")
bind("G", "gimp")
bind("K", "krita")
bind("L", "libreoffice")
bind("SHIFT + P", "qs -c hshell ipc call hshell profile")
bind("SHIFT + K", script("keyboard-next.sh"))
bind("SHIFT + I", "qs -c hshell ipc call hshell caffeine")
bind("SHIFT + O", "qs -c hshell ipc call hshell nightlight")
bind("SHIFT + N", "qs -c hshell ipc call hshell dnd")
bind("SHIFT + H", "qs -c hshell ipc call hshell pickcolor")
bind("SHIFT + J", "qs -c hshell ipc call hshell tool emoji")
local function zoomfunction(value)
    local zoomvalue = hl.get_config("cursor:zoom_factor")
    hl.config({ cursor = { zoom_factor = math.max(1.0, math.min(3.0, zoomvalue + value)) } })
end
register("SUPER + Minus", function() zoomfunction(-0.3) end, { repeating = true, description = "Screen: Zoom out" })
register("SUPER + Equal", function() zoomfunction(0.3) end, { repeating = true, description = "Screen: Zoom in" })
register("SUPER + code:82", function() zoomfunction(-0.3) end, { repeating = true })
register("SUPER + code:86", function() zoomfunction(0.3) end, { repeating = true })

for _, entry in ipairs(overrides.extra) do
    hl.bind(entry.key, hl.dsp.exec_cmd(entry.command))
end
