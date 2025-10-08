data:extend({
    {
        type = "bool-setting",
        name = "debug-mode",
        setting_type = "startup",
        default_value = true,
    },

    -- Rail Pathing Settings
    {
        type = "int-setting",
        name = "opposite-offset",
        setting_type = "runtime-per-user",
        default_value = 2,
        minimum_value = 1,
    },
    {
        type = "bool-setting",
        name = "left-hand-drive",
        setting_type = "runtime-per-user",
        default_value = false,
    },

    -- Rail Signal Settings
    {
        type = "bool-setting",
        name = "signals-enabled",
        setting_type = "runtime-per-user",
        default_value = true,
    },
    {
        type = "int-setting",
        name = "signals-distance",
        setting_type = "runtime-per-user",
        default_value = 35,
    },
})
