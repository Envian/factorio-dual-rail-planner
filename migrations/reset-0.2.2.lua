require("scripts.global")

local saveVersion = storage.version or "0.0.1"

if helpers.compare_versions(saveVersion, "0.2.2") < 0 then
    Util.resetState()

    -- Preserve the legacy rail gap
    for _, player in pairs(game.players) do
        settings.get_player_settings(player)["opposite-offset"] = { value = 2 }
    end
end
