local const = require("scripts.constants")

-- TODO: Move this to a lib file so other mods can explicitly use it.
function registerPlanner(planner, options)
    data:extend({{
        type = "shortcut",
        name = const.SHORTCUT_PREFIX .. planner.name,
        localised_name = { "shortcut.planner-select-title", {"item-name." .. planner.name} },
        toggleable = true,
        action = "lua",
        style = "blue",
        icon = planner.icon,
        small_icon = planner.icon,
    }})
end

registerPlanner(data.raw["rail-planner"]["rail"])