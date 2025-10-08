--
-- Global helpers
--

DEBUG_MODE = settings.startup["debug-mode"].value

--- Reverses a table in memory
--- @param target any[]
table.reverse = function(target)
    for n = 1, #target / 2 do
        target[n], target[#target - n + 1] = target[#target - n + 1], target[n]
    end
end

--- Returns a new array, containing only the entries which pass the given func
--- @generic T
--- @param target T[]
--- @param func fun(value: T): boolean
--- @return T[]
table.filter = function(target, func)
    local result = {}
    for key, value in ipairs(target) do
        if func(value) then result[key] = value end
    end
    return result
end

--- Prints a debug message to stdout
--- @param message LocalisedString
function drpDebug(message)
    local info = debug.getinfo(2, "lS")
    local fname = info.short_src:match("^.+/(.+)$")
    local body = { "debug.format", fname, info.currentline, message }
    localised_print({ "", { "debug.prefix", game and game.tick or "0" }, " ", body })

    if DEBUG_MODE and game then
        game.print(body, { skip = defines.print_skip.never, game_state = false })
    end
end

--
-- Scoped helpers
--

--- Gets an entity's type, respecting ghost entities.
--- @param entity LuaEntity
--- @return string
local function getEntityType(entity)
    return entity.type == "entity-ghost" and entity.ghost_type or entity.type
end

--- Gets a turn from a direction
--- @param a TrueDirection
--- @param b TrueDirection
--- @return Turn
local function getTurnFromEntityDirections(a, b)
    return ((a - b + 9) % 16) - 1
end

--- Finds an exact entity in the game world.
--- @param params { type: string | string[], surface: LuaSurface, position: Vector2d, direction: defines.direction }
--- @return LuaEntity?
local function getEntityAt(params)
    -- Search for real entities first.
    for _, entity in pairs(params.surface.find_entities_filtered({
        type = params.type,
        position = params.position,
        direction = params.direction,
        to_be_deconstructed = false,
    })) do
        -- find_entities_filtered checks collison box, not the entity center.
        if params.position:equals(entity.position) then
            return entity
        end
    end

    -- Search for ghosts second.
    for _, entity in pairs(params.surface.find_entities_filtered({
        type = "entity-ghost",
        ghost_type = params.type,
        position = params.position,
        direction = params.direction,
        to_be_deconstructed = false,
    })) do
        -- find_entities_filtered checks collison box, not the entity center.
        if params.position:equals(entity.position) then
            return entity
        end
    end

    -- Nothing found.
    return nil
end

--- Iterates over the edges of a path
--- @param path RailPath
--- @return fun(): number?, RailPointer?
local function edgeIter(path)
    local index = -1
    local max = #path.segments

    return function()
        index = index + 1
        if index == 0 then
            return 0, path.backward:createReverse()
        end

        if index <= max then
            return index, path.segments[index].forward
        end
    end
end

--- Returns the first value returned by func
--- @generic T
--- @generic V
--- @param target T[]
--- @param func fun(T): V?
--- @return V?
--- @return integer?
--- @return T?
local function first(target, func)
    for n, val in ipairs(target) do
        local result = func(val)
        if result then return result, n, val end
    end
    return nil, nil, nil
end

return {
    getEntityType = getEntityType,
    getTurnFromEntityDirections = getTurnFromEntityDirections,
    getEntityAt = getEntityAt,
    edgeIter = edgeIter,
    first = first,
}
