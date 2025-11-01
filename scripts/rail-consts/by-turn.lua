local EDGES = require("scripts.rail-consts.raw.edges")
local EDGE_OFFSET = require("scripts.rail-consts.raw.edge-offset")

local Turn = require("scripts.classes.turn")

--- @class TurnInfo
--- @field turn Turn
--- @field rotation EntityDirection
--- @field category RailCategory
--- @field offset Vector2d

--- @type { [TrueDirection]: { [Turn]: TurnInfo } }
local turnMap = {}

for category, rotations in pairs(EDGES) do
    if category ~= "ramp" then
        for rotation, directions in pairs(rotations) do
            local forward, backward = table.unpack(directions)
            local turn = Util.getTurnFromEntityDirections(forward, backward)

            forward, backward = Turn.around(forward), Turn.around(backward)

            if not turnMap[forward] then turnMap[forward] = {} end
            if not turnMap[backward] then turnMap[backward] = {} end

            turnMap[forward][-turn] = {
                turn = -turn,
                rotation = rotation,
                category = category,
                offset = EDGE_OFFSET[category][forward] - EDGE_OFFSET[category][backward],
            }
            turnMap[backward][turn] = {
                turn = turn,
                rotation = rotation,
                category = category,
                offset = EDGE_OFFSET[category][backward] - EDGE_OFFSET[category][forward],
            }
        end
    end
end

return turnMap
