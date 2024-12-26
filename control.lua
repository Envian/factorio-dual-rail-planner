if script.active_mods["gvv"] then require("__gvv__.gvv")() end

require("scripts.constants")
require("scripts.manager")

local buildRecusionBlocker = false
lastBuiltRail = nil

script.on_init(function()
    storage.planners = {}
    for index, player in pairs(game.players) do
        storage.planners[index] = Manager.new(player)
    end
end)

script.on_event(defines.events.on_lua_shortcut, function(event)
    if string.sub(event.prototype_name, 1, string.len(SHORTCUT_PREFIX)) == SHORTCUT_PREFIX then
        local plannerName = string.sub(event.prototype_name, string.len(SHORTCUT_PREFIX) + 1)
        storage.planners[event.player_index]:togglePlanner(plannerName)
    end
end)

script.on_event(defines.events.on_player_created, function(event)
    storage.planners[event.player_index] = Manager.new(game.players[event.player_index])
end)

script.on_event(defines.events.on_player_removed, function(event)
    storage.planners[event.player_index] = nil
end)

script.on_event(defines.events.on_player_cursor_stack_changed, function(event)
    storage.planners[event.player_index]:checkCursor()
end)

local counter = 1

script.on_event(defines.events.on_built_entity, function(event)
    -- rendering.draw_text({
    --     text = tostring(counter),
    --     target = event.entity,
    --     surface = event.entity.surface,
    --     color = { r = 1, g = 0, b = 0 },
    -- })
    counter = counter + 1

    lastBuiltRail = event.entity
    if buildRecusionBlocker then return end

    buildRecusionBlocker = true
    storage.planners[event.player_index]:entityBuilt(event)
    buildRecusionBlocker = false
end, {
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
})

script.on_event(defines.events.on_pre_build, function(event)
    storage.planners[event.player_index]:entityPreBuilt(event)
end)

script.on_nth_tick(600, function(event)
    for _, planner in pairs(storage.planners) do
        planner:refreshAlerts()
    end
end)