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
--- @param setPrimary boolean
function registerPlanner(planner, signal, setPrimary)
    -- TODO: Show shortcut only when rail planner entity (Rail) has been researched.

    -- Clone the rail planner, but remove ramps since they aren't fully supported atm.
    local mockPlanner = table.deepcopy(planner)
    local validRails = {}
    for _, rail in ipairs(mockPlanner.rails) do
        -- Ramps are currently poorly supported. Remove them from the mock.
        if not data.raw["rail-ramp"][rail] then
            table.insert(validRails, rail);
        end
    end
    mockPlanner.name = const.MOCK_PLANNER_PREFIX .. planner.name
    mockPlanner.rails = validRails
    mockPlanner.localised_name = { "shortcut.planner-select-title", {"item-name." .. planner.name} }

    -- Hide this
    mockPlanner.flags = mockPlanner.flags or {}
    table.insert(mockPlanner.flags, "only-in-cursor")
    mockPlanner.hidden_in_factoriopedia = true
    mockPlanner.hidden = true

    if setPrimary then
        planner.flags = planner.flags or {}
        table.insert(planner.flags, "primary-place-result")
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
            mockPlanner = const.MOCK_PLANNER_PREFIX .. planner.name,
            signal = signal,
        }
    },
        mockPlanner
    })
end

if data.raw["rail-planner"]["rail"] then
    registerPlanner(data.raw["rail-planner"]["rail"], "rail-signal", true)
end
