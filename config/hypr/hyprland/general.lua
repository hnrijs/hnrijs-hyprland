hl.config({
    general = {
        gaps_in = 5, gaps_out = 5, border_size = 2,
        col = { active_border = "rgba(FFFFFFFF)", inactive_border = "rgba(808080FF)" },
        resize_on_border = false, allow_tearing = false, layout = "dwindle",
    },
    decoration = {
        rounding = 0, active_opacity = 1.0, inactive_opacity = 1.0,
        dim_inactive = false, shadow = { enabled = false }, blur = { enabled = false },
    },
    animations = { enabled = true },
    render = { direct_scanout = false },
    dwindle = { preserve_split = true },
    master = { new_status = "master" },
    misc = { force_default_wallpaper = 0, disable_hyprland_logo = true },
})

hl.curve("hshell", { type = "bezier", points = {{0.16, 1}, {0.3, 1}} })
hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "hshell", style = "popin" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "hshell", style = "slide" })
hl.animation({ leaf = "fade", enabled = false })
hl.animation({ leaf = "layers", enabled = false })
