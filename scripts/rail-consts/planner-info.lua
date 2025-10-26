local const = require("scripts.constants")

--- @alias RailEntities RailEntityType | "rail-support" | "rail-signal"

--- @class PlannerInfo
--- @field supportRange number
--- @field rampSupportRange number
--- @field names { [RailEntities]: string }
--- @field tileSizes { [RailEntities]: { w: number, h: number } }

--- @type { [string]: PlannerInfo }
local PLANNER_MAP = {}

for _, modData in pairs(prototypes.mod_data) do
    if modData.data_type == const.DATA_REGISTERED_PLANNER_TYPE then
        --- @type LuaItemPrototype
        local planner = prototypes.get_item_filtered({{
            --- @diagnostic disable-next-line: assign-type-mismatch
            filter = "name", name = modData.data.planner
        }})[modData.data.planner]

        local signal = prototypes.entity[modData.data.signal]
        local support = planner.support or {}

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
        end

        PLANNER_MAP[modData.data.planner] = {
            names = names,
            tileSizes = tileSizes,
            supportRange = modData.data.supportRange,
            rampSupportRange = modData.data.rampSupportRange,
        }
    end
end

return PLANNER_MAP
