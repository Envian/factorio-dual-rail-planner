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

commands.add_command("drpclear", { "command-text.drpclear-help" }, function(event)
    drpInfo({ "command-text.drpclear-message" })

    rendering.clear()

    -- reset event index for easier reading.
    for _, parser in pairs(storage.parsers) do
        --- @diagnostic disable-next-line: invisible
        parser.eventIndex = 0
    end
end)

commands.add_command("drpreset", { "command-text.drpreset-help" }, function(event)
    drpInfo({ "command-text.drpreset-message" })
    Util.resetState()
end)

commands.add_command("drpmark", { "command-text.drpmark-help" }, function(event)
    local result, _, x, y = string.find(event.parameter or "", "^(-?%d+)[%s,]+(-?%d+)$")
    local player = game.players[event.player_index]

    if result then
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
        drpInfo(player, { "command-text.drpmark-message" })
    else
        drpInfo(player, { "command-text.drpmark-error" })
    end

end)

commands.add_command("drpdraw", { "command-text.drpdraw-help" }, function(event)
    if DRAW_MODE then
        drpInfo({ "command-text.drpdraw-disabled" })

        DRAW_MODE = false
        rendering.clear()

        -- reset event index for easier reading.
        for _, parser in pairs(storage.parsers) do
            --- @diagnostic disable-next-line: invisible
            parser.eventIndex = 0
        end
    else
        drpInfo({ "command-text.drpdraw-enabled" })
        DRAW_MODE = true
    end
end)
