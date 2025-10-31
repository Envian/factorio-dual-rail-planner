local const = require("scripts.constants")

--- @alias RailEntities RailEntityType | "rail-support" | "rail-signal"

--- @class PlannerInfo
--- @field supportName string
--- @field supportRange number
--- @field rampSupportRange number
--- @field names { [RailEntities]: string }
--- @field tileSizes { [RailEntities]: { w: number, h: number } }

--- @type { [string]: PlannerInfo }
local PLANNER_MAP = {}

for _, modData in pairs(prototypes.mod_data) do
    if modData.data_type == const.DATA_REGISTERED_PLANNER_TYPE then
        local planner = prototypes.item[modData.data.planner]
        local mockPlanner = prototypes.item[modData.data.mockPlanner]
        local signal = prototypes.entity[modData.data.signal]
        local support = planner.support or {}
        local ramp = {}

        local names = {
            ["rail-support"] = support.name,
            ["rail-signal"] = modData.data.signal,
        }
        local tileSizes = {
            ["rail-support"] = { w = support.tile_width, h = support.tile_height },
            ["rail-signal"] = { w = signal.tile_width, h = signal.tile_height },
        }

        for _, rail in pairs(planner.rails) do
            names[rail.type] = rail.name
            tileSizes[rail.type] = { w = rail.tile_width, h = rail.tile_height }

            if rail.type == "rail-ramp" then
                ramp = rail
            end
        end

        PLANNER_MAP[modData.data.planner] = {
            names = names,
            tileSizes = tileSizes,
            supportRange = support.support_range or 0,
            rampSupportRange = ramp.support_range or 0,
            supportName = support.name,
        }
    end
end

return PLANNER_MAP
