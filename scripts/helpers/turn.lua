local turn = {
    LEFT = -1,
    STRAIGHT = 0,
    RIGHT = 1,
    AROUND = 8,
}

local function call(_, direction, turnDirection)
    return (direction + turnDirection) % 16
end

function turn.around(direction)
    return turn(direction, turn.AROUND)
end

function turn.toString(turnDirection)
    if     turnDirection == turn.LEFT     then return "left"
    elseif turnDirection == turn.STRAIGHT then return "straight"
    elseif turnDirection == turn.RIGHT    then return "right"
    elseif turnDirection == turn.AROUND   then return "around"
    else return tostring(turnDirection) end
end

setmetatable(turn, { __call = call })

return turn