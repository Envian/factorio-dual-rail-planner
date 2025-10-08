local const = require("scripts.constants")

-- TODO: Move this to a lib file so other mods can explicitly use it.

--- @class DRPModInfoPlanner
--- @field planner string
--- @field supportRange number
--- @field rampSupportRange number
--- @field signal string

--- Registers a planner for DRP placement.
--- @param planner data.RailPlannerPrototype
--- @param signal string
function registerPlanner(planner, signal)
    local support = data.raw["rail-support"][planner.support]
    local rampLength
    for _, railName in ipairs(planner.rails) do
        local ramp = data.raw["rail-ramp"][railName]
        if ramp then
            rampLength = ramp.support_range
            break
        end
    end

    data:extend({{
        type = "shortcut",
        name = const.SHORTCUT_PREFIX .. planner.name,
        localised_name = { "shortcut.planner-select-title", {"item-name." .. planner.name} },
        toggleable = true,
        action = "lua",
        style = "blue",
        icon = planner.icon,
        small_icon = planner.icon,
    }, {
        type = "mod-data",
        name = const.DATA_REGISTERED_NAME_PREFIX .. planner.name,
        data_type = const.DATA_REGISTERED_PLANNER_TYPE,
        data = {
            planner = planner.name,
            -- Temporary: currently no way to get support_range in runtime.
            -- Replace when fixed: https://forums.factorio.com/viewtopic.php?p=680829
            supportRange = support and support.support_range or 0,
            rampSupportRange = rampLength or 0,
            signal = signal,
        }
    }})
end

if data.raw["rail-planner"]["rail"] then
    registerPlanner(data.raw["rail-planner"]["rail"], "rail-signal")
end
