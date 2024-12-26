function doTurn(direction, turn)
    return (direction + turn) % 16
end

function getTurnFromDirections(forward, backward)
    return ((forward - backward + 9) % 16) - 1
end

function addPositions(a, b)
    return {x = a.x + b.x, y = a.y + b.y}
end

function subtractPositions(a, b)
    return {x = a.x - b.x, y = a.y - b.y}
end

function isValidDirection(direction)
    return type(direction) == "number" and direction >= 0 and direction <= 15
end

function isValidRailTurn(turn)
    return type(turn) == "number" and turn >= -1 and turn <= 1
end

function isValidPosition(position)
    return type(position.x) == "number" and type(position.y) == "number"
end

function isValidRailEntity(rail)
    if rail.object_name ~= "LuaEntity" then return false end
    if not rail.valid then return false end

    if rail.type == "entity-ghost" then
        return not not RAIL_TYPE_TO_CATEGORY[rail.ghost_type]
    else
        return not not RAIL_TYPE_TO_CATEGORY[rail.type]
    end

end

function filterForExistingSegments(extensions)
    local result = {}
    for _, extension in pairs(extensions) do
        if extension:getEntity() then
            table.insert(result, extension)
        end
    end
    return result
end

local nextTickCallbacks = nil
local function onNextTickHandler(event)
    for _, callback in pairs(nextTickCallbacks[game.tick] or {}) do
        callback(event)
    end
    nextTickCallbacks[game.tick] = nil

    if table_size(nextTickCallbacks) == 0 then
        script.on_event(defines.events.on_tick, nil)
        nextTickCallbacks = nil
    end
end

function delay(ticks, callback)
    assert(type(ticks) == "number" and ticks > 0, "delay must be a positive number")

    if not nextTickCallbacks then
        nextTickCallbacks = {}
        script.on_event(defines.events.on_tick, onNextTickHandler)
    end

    local callbacks = nextTickCallbacks[ticks + game.tick]

    if not callbacks then
        callbacks = {}
        nextTickCallbacks[ticks + game.tick] = callbacks
    end

    table.insert(callbacks, callback)
end


TURN = {
    LEFT = -1,
    STRAIGHT = 0,
    RIGHT = 1,
    AROUND = 8,

    toString = function(turn)
        if     turn == TURN.LEFT     then return "left"
        elseif turn == TURN.STRAIGHT then return "straight"
        elseif turn == TURN.RIGHT    then return "right"
        elseif turn == TURN.AROUND   then return "around"
        else return tostring(turn) end
    end
}

defines.direction.toString = function(direction)
    if     direction == defines.direction.north          then return "North"
    elseif direction == defines.direction.northnortheast then return "North North East"
    elseif direction == defines.direction.northeast      then return "North East"
    elseif direction == defines.direction.eastnortheast  then return "East North East"
    elseif direction == defines.direction.east           then return "East"
    elseif direction == defines.direction.eastsoutheast  then return "East South East"
    elseif direction == defines.direction.southeast      then return "South East"
    elseif direction == defines.direction.southsoutheast then return "South South East"
    elseif direction == defines.direction.south          then return "South"
    elseif direction == defines.direction.southsouthwest then return "South South West"
    elseif direction == defines.direction.southwest      then return "South West"
    elseif direction == defines.direction.westsouthwest  then return "West South West"
    elseif direction == defines.direction.west           then return "West"
    elseif direction == defines.direction.westnorthwest  then return "West North West"
    elseif direction == defines.direction.northwest      then return "North West"
    elseif direction == defines.direction.northnorthwest then return "North North West"
    else return tostring(direction) end
end