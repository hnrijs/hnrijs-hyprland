local mainMod = "SUPER"
local config = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local function quote(value) return "'" .. value:gsub("'", "'\\''") .. "'" end
local function script(name) return "bash " .. quote(config .. "/scripts/" .. name) end
local function shell(panel) return "qs -c hshell ipc call hshell toggle " .. panel end
local function bind(key, command) hl.bind(mainMod .. " + " .. key, hl.dsp.exec_cmd(command)) end

hl.on("hyprland.start", function()
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("python3 " .. quote(config .. "/scripts/wallpaper.py") .. " restore-wallpaper")
    hl.exec_cmd("hypridle")
    hl.exec_cmd(script("start-hshell.sh"))
end)
