hl.config({ decoration = { blur = { enabled = true, size = 4, passes = 2 } } })
hl.layer_rule({ name = "hshell-overview-blur", match = { namespace = "^hshell-overview-blur$" }, blur = true, ignore_alpha = 0, xray = false })
