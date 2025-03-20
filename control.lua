if script.active_mods["gvv"] then require("__gvv__.gvv")() end

local const = require("scripts.constants")
local Manager = require("scripts.classes.manager")

script.on_init(function()
    storage.managers = {}
    for index, player in pairs(game.players) do
        storage.managers[index] = Manager.new(player)
    end
end)

script.on_event(defines.events.on_lua_shortcut, function(event)
    if string.sub(event.prototype_name, 1, string.len(const.SHORTCUT_PREFIX)) == const.SHORTCUT_PREFIX then
        local plannerName = string.sub(event.prototype_name, string.len(const.SHORTCUT_PREFIX) + 1)
        storage.managers[event.player_index]:togglePlanner(plannerName)
    end
end)

script.on_event(defines.events.on_player_created, function(event)
    storage.managers[event.player_index] = Manager.new(game.players[event.player_index])
end)

script.on_event(defines.events.on_player_removed, function(event)
    -- TODO: Is there anything we need to clean up beyond just the manager?
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
    { mode = "or", filter = "ghost_type", type = "elevated-curved-rail-b" },
    { mode = "or", filter = "name", name = "tile-ghost" },
}

script.on_event(defines.events.on_built_entity, function(event)
    storage.managers[event.player_index]:entityBuilt(event)
end, entityFilter)

script.on_event(defines.events.on_marked_for_deconstruction, function(event)
    -- Robots which deconstruct rocks produce ghost items marked for deconstruction.
    -- those events do not have a player index.
    if event.entity.name == "item-on-ground" then return end

    storage.managers[event.player_index]:entityDeconstructed(event)
end)

script.on_event({defines.events.on_redo_applied, defines.events.on_undo_applied}, function(event)
    storage.managers[event.player_index]:undoRedoApplied(event)
end)

-- Additional events are handled in other files:
-- on_tick -> helpers/delay.lua
