if script.active_mods["gvv"] then require("__gvv__.gvv")() end

-- Helpers must be the first import.
require("scripts.helpers")

require("scripts.commands")
local const = require("scripts.constants")

local EventParser = require("scripts.classes.event-parser")
local RailBuilder = require("scripts.classes.rail-builder")
local reportProfiling = require("scripts.profiling").report

DISABLE_EVENTS = false

script.on_init(function()
    --- @type { [number]: EventParser }
    storage.parsers = {}
    --- @type { [number]: { pointer: RailPointer, debt: number } }
    storage.history = {}
    storage.onticks = { registered = false }

    for index, player in pairs(game.players) do
        storage.parsers[index] = EventParser.new(player)
        storage.history[index] = {}
    end

    -- TODO: Reset shortcut state
end)

-- NOTE: on_load is handled in ontick.lua

script.on_event(defines.events.on_player_removed, function(event)
    storage.parsers[event.player_index] = nil
end)

--
--  Activation Events
--

script.on_event(defines.events.on_lua_shortcut, function(event)
    if string.sub(event.prototype_name, 1, string.len(const.SHORTCUT_PREFIX)) == const.SHORTCUT_PREFIX then
        local plannerName = string.sub(event.prototype_name, string.len(const.SHORTCUT_PREFIX) + 1)
        storage.parsers[event.player_index]:toggle(plannerName)
    end
end)

script.on_event(defines.events.on_player_cursor_stack_changed, function(event)
    storage.parsers[event.player_index]:checkCursor()
end)

--
--  Construction Events
--

local entityFilter = {
    -- { filter = "rail" }, -- Currently not working with real entities.
    -- { mode = "or", filter = "ghost_type", type = "rail-support" },
    -- { mode = "or", filter = "ghost_type", type = "rail-signal" },
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
    -- game.print("Direction: " .. event.entity.direction)

    if DISABLE_EVENTS then return end
    storage.parsers[event.player_index]:entityBuilt(event.entity)
end, entityFilter)

-- script.on_event(defines.events.on_marked_for_deconstruction, function(event)
--     -- Robots which deconstruct rocks produce ghost items marked for deconstruction.
--     -- those events do not have a player index. Same with some other events.
--     if event.player_index then
--         storage.parsers[event.player_index]:entityDeconstructed(event)
--     end
-- end)

-- script.on_event({defines.events.on_redo_applied, defines.events.on_undo_applied}, function(event)
--     storage.parsers[event.player_index]:undoRedoApplied(event)
-- end)

script.on_event(defines.events.on_tick, function(event)
    for _, parser in pairs(storage.parsers) do
        if parser.hasEvents then
            local path = parser:getPath()
            if path then
                local builder = RailBuilder.new(parser.player, parser.planner, path)
                builder:buildPath()
                builder:addExtras()
                builder:finish()
                reportProfiling()
            end
        end
    end
end)
