if script.active_mods["gvv"] then require("__gvv__.gvv")() end

require("scripts.constants")

DRP = {}

local Manager = require("scripts.classes.manager")

script.on_init(function()
    storage.managers = {}
    for index, player in pairs(game.players) do
        storage.managers[index] = Manager.new(player)
    end
end)

script.on_event(defines.events.on_lua_shortcut, function(event)
    if string.sub(event.prototype_name, 1, string.len(SHORTCUT_PREFIX)) == SHORTCUT_PREFIX then
        local plannerName = string.sub(event.prototype_name, string.len(SHORTCUT_PREFIX) + 1)
        storage.managers[event.player_index]:togglePlanner(plannerName)
    end
end)

script.on_event(defines.events.on_player_created, function(event)
    storage.managers[event.player_index] = Manager.new(game.players[event.player_index])
end)

script.on_event(defines.events.on_player_removed, function(event)
    storage.managers[event.player_index] = nil
end)

script.on_event(defines.events.on_player_cursor_stack_changed, function(event)
    storage.managers[event.player_index]:checkCursor()
end)

local entityFilter = {
    { filter = "rail" },
    { mode = "or", filter = "type", type = "rail-support" },
    { mode = "or", filter = "ghost_type", type = "rail-support" },
    { mode = "or", filter = "ghost_type", type = "straight-rail" },
    { mode = "or", filter = "ghost_type", type = "half-diagonal-rail" },
    { mode = "or", filter = "ghost_type", type = "curved-rail-a" },
    { mode = "or", filter = "ghost_type", type = "curved-rail-b" },
    { mode = "or", filter = "ghost_type", type = "rail-ramp" },
    { mode = "or", filter = "ghost_type", type = "elevated-straight-rail" },
    { mode = "or", filter = "ghost_type", type = "elevated-half-diagonal-rail" },
    { mode = "or", filter = "ghost_type", type = "elevated-curved-rail-a" },
    { mode = "or", filter = "name", name = "tile-ghost" },
}

script.on_event(defines.events.on_built_entity, function(event)
    if capturedEntities then table.insert(capturedEntities, event.entity) end

    if buildRecusionBlocker then return end

    buildRecusionBlocker = true
    storage.managers[event.player_index]:entityBuilt(event)
    buildRecusionBlocker = false
end, entityFilter)

-- This is rarely needed but performance is a crutch.
script.on_event(defines.events.on_marked_for_deconstruction, function(event)
    local manager = storage.managers[event.player_index]

    if manager.abort then
        event.entity.cancel_deconstruction(manager.player.force, manager.player)
    end
end)


-- Entity capture to help with buildFromCursor.
DRP.entityCapture = {}
local capturedEntities = nil

function DRP.entityCapture.begin()
    capturedEntities = {}
end

function DRP.entityCapture.finish()
    local entities = capturedEntities
    capturedEntities = nil
    return entities
end

-- Additional events are handled in other files:
-- on_tick -> helpers/delay.lua