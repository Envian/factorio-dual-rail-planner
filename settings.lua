data:extend({
    {
        type = "bool-setting",
        name = "debug-mode",
        order = "zz-debug-a",
        setting_type = "startup",
        default_value = false,
    },

    -- Rail Pathing Settings
    {
        type = "int-setting",
        name = "opposite-offset",
        order = "a-path-a",
        setting_type = "runtime-per-user",
        default_value = 3,
        minimum_value = 1,
    },
    {
        type = "bool-setting",
        name = "left-hand-drive",
        order = "a-path-b",
        setting_type = "runtime-per-user",
        default_value = false,
    },

    -- Rail Signal Settings
    {
        type = "bool-setting",
        name = "signals-enabled",
        order = "b-signal-a",
        setting_type = "runtime-per-user",
        default_value = true,
    },
    {
        type = "int-setting",
        name = "signals-distance",
        order = "b-signal-b",
        setting_type = "runtime-per-user",
        default_value = 35,
    },
})
