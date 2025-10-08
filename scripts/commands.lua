local EventParser = require("scripts.classes.event-parser")

-- Debug Commands
if not DEBUG_MODE then return end

-- local TestCategories = {
--     ["RailPointer"] = require("scripts.classes.rail-pointer_test"),
-- }

-- commands.add_command("drp_unittest", "Runs Dual Rail Planner unit tests", function(event)
--     local player = game.players[event.player_index]

--     for category, tests in pairs(TestCategories) do
--         for test, func in pairs(tests) do
--             local success, message = pcall(func)

--             if success then
--                 player.print(("[%s: %s] [color=0,255,0]Success[/color]"):format(category, test))
--             else
--                 player.print(("[%s: %s] [color=255,0,0]Failed[/color]: %s"):format(category, test, message))
--             end
--         end
--     end
-- end)

commands.add_command("drpclear", "Clears all debug annotations.", function(event)
    rendering.clear()

    -- reset event index for easier reading.
    for _, parser in pairs(storage.parsers) do
        --- @diagnostic disable-next-line: invisible
        parser.eventIndex = 0
    end
end)

commands.add_command("drpreset", "Resets Storage to default settings.", function(event)
    storage.parsers = {}
    storage.history = {}
    storage.onticks = { registered = false }

    script.on_event(defines.events.on_tick, nil)

    for index, player in pairs(game.players) do
        storage.parsers[index] = EventParser.new(player)
        storage.history[index] = {}
    end
end)

commands.add_command("drpmark", "Marks a place in the current world.", function(event)
    local result, _, x, y = string.find(event.parameter or "", "^(-?%d+)[%s,]+(-?%d+)$")

    if result then
        local player = game.players[event.player_index]

        rendering.draw_circle({
            color = { 0, 0, 0, 1 },
            target = { tonumber(x), tonumber(y) },
            radius = 0.15,
            filled = true,
            players = { player },
            surface = player.surface,
        })
        rendering.draw_circle({
            color = { 1, 0, 1, 1 },
            target = { tonumber(x), tonumber(y) },
            radius = 0.11,
            filled = true,
            players = { player },
            surface = player.surface,
        })
        rendering.draw_circle({
            color = { 0, 1, 1, 1 },
            target = { tonumber(x), tonumber(y) },
            radius = 0.07,
            filled = true,
            players = { player },
            surface = player.surface,
        })
    end
end)
