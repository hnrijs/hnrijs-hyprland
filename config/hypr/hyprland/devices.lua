_hshell_monitors_begin = true
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
hl.monitor({ output = "DP-3", mode = "1920x1080@280", position = "1080x1080", scale = 1, transform = 0 })
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "1080x0", scale = 1, transform = 0 })
hl.monitor({ output = "DP-1", mode = "1920x1080@180", position = "0x240", scale = 1, transform = 1 })
hl.monitor({ output = "DP-2", mode = "1920x1080@180", position = "3000x240", scale = 1, transform = 3 })
hl.config({ misc = { vrr = 0 } })
hl.workspace_rule({ workspace = "1", monitor = "DP-3", default = true })
hl.workspace_rule({ workspace = "2", monitor = "HDMI-A-1", default = true })
hl.workspace_rule({ workspace = "3", monitor = "DP-1", default = true })
hl.workspace_rule({ workspace = "4", monitor = "DP-2", default = true })
_hshell_monitors_end = true
