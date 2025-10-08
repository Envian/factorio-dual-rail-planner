--- @diagnostic disable: inject-field

--- @enum Turn
local turn = {
    LEFT = -1,
    STRAIGHT = 0,
    RIGHT = 1,
    AROUND = 8,
}

--- Rotates the given direction by the turn.
--- @param _ any
--- @param direction TrueDirection
--- @param turnDirection Turn
--- @return TrueDirection
local function call(_, direction, turnDirection)
    return (direction + turnDirection) % 16
end

--- Turns a direction around.
--- @param direction TrueDirection
--- @return TrueDirection
function turn.around(direction)
    return turn(direction, turn.AROUND)
end

--- Converts a direction or unnormalized turn into a series of left or right turns.
--- @param value Turn | TrueDirection
--- @return Turn
function turn.normalize(value)
    return ((value + 7) % 16) - 7
end

--- Converts the turn to readable text.
--- @param turnDirection Turn
--- @return string
function turn.toString(turnDirection)
    if     turnDirection == turn.LEFT     then return "left"
    elseif turnDirection == turn.STRAIGHT then return "straight"
    elseif turnDirection == turn.RIGHT    then return "right"
    elseif turnDirection == turn.AROUND   then return "around"
    else return tostring(turnDirection) end
end

setmetatable(turn, { __call = call })

return turn
