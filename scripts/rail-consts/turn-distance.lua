local DIRECTION_VECTORS = require("scripts.rail-consts.raw.direction-vectors")
local BY_TURN = require("scripts.rail-consts.by-turn")

local Vector2d = require("scripts.classes.vector")
local Turn = require("scripts.classes.turn")

--- @alias TurnNumbers [ number, number, number, number ]

--- @type { [TrueDirection]: { [number]: number } }
local TURN_DISTANCES = {}

for dir = defines.direction.north, defines.direction.northnorthwest do
    local straightVector = BY_TURN[dir][Turn.STRAIGHT].offset

    TURN_DISTANCES[dir] = {
        [Turn.STRAIGHT] = math.sqrt(straightVector.x * straightVector.x + straightVector.y * straightVector.y),
    }

    local startVector = DIRECTION_VECTORS[dir]
    local leftPos, rightPos = Vector2d:new({ x = 0, y = 0 }), Vector2d:new({ x = 0, y = 0 })

    for turnCount = 0, 3 do
        leftPos:move(BY_TURN[Turn(dir, -turnCount)][-1].offset)
        rightPos:move(BY_TURN[Turn(dir, turnCount)][1].offset)

        local leftVector = DIRECTION_VECTORS[Turn(dir, -(turnCount + 1))]
        local rightVector = DIRECTION_VECTORS[Turn(dir, turnCount + 1)]

        TURN_DISTANCES[dir][-(turnCount + 1)] = leftPos:crossProduct(leftVector) / startVector:crossProduct(leftVector)
        TURN_DISTANCES[dir][turnCount + 1] = rightPos:crossProduct(rightVector) / startVector:crossProduct(rightVector)
    end
end


return TURN_DISTANCES
