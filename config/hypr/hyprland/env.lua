hl.env("TERMINAL", "alacritty")
hl.env("EDITOR", "nvim")
hl.env("VISUAL", "nvim")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Adwaita")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")

local config = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local path = config .. "/hypr/hyprland/app-env.lua"
local file = io.open(path, "r")
if file then
	file:close()
	dofile(path)
end
