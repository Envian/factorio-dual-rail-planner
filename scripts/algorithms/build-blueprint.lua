--- Builds a blueprint
--- @param entities BlueprintEntity[]
--- @param player LuaPlayer
--- @param plannerInfo PlannerInfo
return function(entities, player, plannerInfo)
    if #entities == 0 then return end

    -- TODO: This is technically not quite correct, however it seems to be
    -- producing correct results.

    local topleft = { x = entities[1].position.x, y = entities[1].position.y }
    local botright = { x = entities[1].position.x, y = entities[1].position.y }

    for index, entity in ipairs(entities) do
        entity.entity_number = index
        entity.name = plannerInfo.names[entity.type]

        local size = plannerInfo.tileSizes[entity.name]
        -- Account for rotation
        if math.floor((entity.direction % 8) / 4) == 1 then
            size = { w = size.h, h = size.w }
        end


        topleft.x = math.min(topleft.x, entity.position.x - size.w / 2)
        topleft.y = math.min(topleft.y, entity.position.y - size.h / 2)
        botright.x = math.max(botright.x, entity.position.x + size.w / 2)
        botright.y = math.max(botright.y, entity.position.y + size.h / 2)
    end

    -- Align edges to the rail grid
    topleft.x = math.floor(topleft.x / 2 + 0.5) * 2
    topleft.y = math.floor(topleft.y / 2 + 0.5) * 2
    botright.x = math.floor(botright.x / 2 + 0.5) * 2
    botright.y = math.floor(botright.y / 2 + 0.5) * 2

    local currentGhost = player.cursor_ghost
    player.cursor_stack.set_stack("blueprint")
    player.cursor_stack_temporary = true
    player.cursor_stack.set_blueprint_entities(entities)

    DISABLE_EVENTS = true
    player.build_from_cursor({
        position = {
            x = (topleft.x + botright.x) / 2 - 0.5,
            y = (topleft.y + botright.y) / 2 - 0.5,
        },
        direction = defines.direction.north,
        build_mode = defines.build_mode.superforced,
        skip_fog_of_war = false,
    })
    DISABLE_EVENTS = false

    player.clear_cursor()
    player.cursor_ghost = currentGhost

    if DRAW_MODE then
        rendering.draw_circle({
            color = { 0, 0, 0, 1 },
            target = {
                x = (topleft.x + botright.x) / 2,
                y = (topleft.y + botright.y) / 2,
            },
            radius = 0.15,
            filled = true,
            players = { player },
            surface = player.surface,
        })
        rendering.draw_circle({
            color = { 0, 1, 1, 1 },
            target = {
                x = (topleft.x + botright.x) / 2,
                y = (topleft.y + botright.y) / 2,
            },
            radius = 0.11,
            filled = true,
            players = { player },
            surface = player.surface,
        })
        rendering.draw_circle({
            color = { 1, 0, 1, 1 },
            target = {
                x = (topleft.x + botright.x) / 2,
                y = (topleft.y + botright.y) / 2,
            },
            radius = 0.07,
            filled = true,
            players = { player },
            surface = player.surface,
        })
    end
end
