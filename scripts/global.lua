--
-- Global helpers
--

DEBUG_MODE = settings.startup["debug-mode"].value
DRAW_MODE = DEBUG_MODE

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

--- Prints a debug message only visible in stdout and debug mode.
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

--- Prints a message to the player.
--- @param p1 LuaPlayer | LocalisedString
--- @param p2 LocalisedString?
function drpInfo(p1, p2)
    local player
    local message

    if p1.object_name == "LuaPlayer" then
        player = p1
        message = p2
    else
        message = p1
    end

    (player and player.print or game.print)({ "info.player-message", message })

    local info = debug.getinfo(2, "lS")
    local fname = info.short_src:match("^.+/(.+)$")
    local body = { "debug.format", fname, info.currentline, message }
    localised_print({ "", { "debug.prefix", game and game.tick or "0" }, " ", body })

    if DEBUG_MODE and game then
        game.print(body, { skip = defines.print_skip.never, game_state = false })
    end
end

--- Prints an error message to the player.
--- @param player LuaPlayer
--- @param message LocalisedString
function drpError(player, message)
    local info = debug.getinfo(2, "lS")
    local fname = info.short_src:match("^.+/(.+)$")
    local body = { "error.format", fname, info.currentline, message }
    localised_print({ "", { "error.prefix", game and game.tick or "0" }, " ", body })

    if DEBUG_MODE and game then
        game.print(body, { skip = defines.print_skip.never, game_state = false })
    end

    player.print({ "error.player-message", message }, { skip = defines.print_skip.never, game_state = false })
end

--
-- Scoped Methods
--

Util = {}

--- Gets an entity's type, respecting ghost entities.
--- @param entity LuaEntity
--- @return string
function Util.getEntityType(entity)
    return entity.type == "entity-ghost" and entity.ghost_type or entity.type
end

--- Gets a turn from a direction
--- @param a TrueDirection
--- @param b TrueDirection
--- @return Turn
function Util.getTurnFromEntityDirections(a, b)
    return ((a - b + 9) % 16) - 1
end

--- Finds an exact entity in the game world.
--- @param params { type: string | string[], surface: LuaSurface, position: Vector2d, direction: defines.direction, layer: defines.rail_layer? }
--- @return LuaEntity?
function Util.getEntityAt(params)
    -- Search for real entities first.
    for _, entity in pairs(params.surface.find_entities_filtered({
        type = params.type,
        position = params.position,
        direction = params.direction,
        to_be_deconstructed = false,
    })) do
        -- find_entities_filtered checks collison box, not the entity center.
        if params.position:equals(entity.position) and (
            not params.layer or params.layer == entity.rail_layer
        ) then
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
        -- Currently, ghosts cannot determine rail layer of signals.
        -- if params.position:equals(entity.position) and (
            --     not params.layer or params.layer == entity.rail_layer
            -- ) then
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
function Util.edgeIter(path)
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

--- Iterates over alignment points, ensuring 0 is first.
--- @param alignmentPoints AlignmentPoint[]
--- @return fun(points: AlignmentPoint[], key: number?): number?, AlignmentPoint?
function Util.alignmentIterator(alignmentPoints)
    local first = alignmentPoints[0]

    return function(_, key)
        if not key and first then
            return 0, first
        end

        key, point = next(alignmentPoints, key ~= 0 and key or nil)
        if key == 0 then return nil, nil end
        return key, point
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
function Util.first(target, func)
    for n, val in ipairs(target) do
        local result = func(val)
        if result then return result, n, val end
    end
    return nil, nil, nil
end

-- Todo: organize my requires better.
local EventParser = require("scripts.classes.event-parser")

--- Resets the state of `storage` to its initial values.
function Util.resetState()
    storage.version = script.active_mods[script.mod_name]

    --- @type { [number]: EventParser }
    storage.parsers = {}
    --- @type { [number]: { pointer: RailPointer, debt: number } }
    storage.history = {}


    for index, player in pairs(game.players) do
        storage.parsers[index] = EventParser.new(player)
        storage.history[index] = {}
    end

    -- TODO: Reset shortcut state
end
