require("scripts.constants")

local railItemMap = {}

local RAIL_TYPES = {
    "straight-rail",
    "curved-rail-a",
    "curved-rail-b",
    "half-diagonal-rail",
    "rail-ramp",
    "elevated-straight-rail",
    "elevated-curved-rail-a",
    "elevated-curved-rail-b",
    "elevated-half-diagonal-rail",
}

function getRailDefine(railName)
    for _, railType in pairs(RAIL_TYPES) do
        if data.raw[railType][railName] then return data.raw[railType][railName] end
    end
end

function registerPlanner(planner, options)
    -- Start with a shortcut
    local extensions = {{
        type = "shortcut",
        name = SHORTCUT_PREFIX .. planner.name,
        localised_name = { "shortcut.planner-select-title", {"item-name." .. planner.name} },
        toggleable = true,
        action = "lua",
        style = "blue",
        icon = planner.icon,
        small_icon = planner.icon,
    }}

    for index, railName in pairs(planner.rails) do
        local rail = getRailDefine(railName)

        if not railItemMap[railName] then
            local fakeRail = {
                type = "item",
                name = FAKREAIL_PREFIX .. railName,
                hidden = true,
                hidden_in_factoriopedia = true,
                stack_size = 1,
                icons = rail.icons,
                icon = rail.icon,
                icon_size = rail.icon_size,
                place_result = rail.name,
                flags = {
                    "hide-from-bonus-gui",
                    "hide-from-fuel-tooltip",
                    "only-in-cursor",
                },
            }
            railItemMap[railName] = true
            table.insert(extensions, fakeRail)
        end
    end

    data:extend(extensions)
end

registerPlanner(data.raw["rail-planner"]["rail"])