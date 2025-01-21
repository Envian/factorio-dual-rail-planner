
-- { player, name, position, rotation }
local function build(params)
    local currentGhost = params.player.cursor_ghost

    -- Do we want to cache the blueprints?
    params.player.cursor_stack.set_stack("blueprint")
    params.player.cursor_stack_temporary = true
    params.player.cursor_stack.set_blueprint_entities({{
        entity_number = 1,
        name = params.name,
        position = {0, 0},
        direction = params.rotation,
    }})

    DRP.entityCapture.begin()
    params.player.build_from_cursor({
        position = params.position,
        direction = defines.direction.north,
        build_mode = defines.build_mode.superforced,
        skip_fog_of_war = false,
    })
    local entities = DRP.entityCapture.finish()

    params.player.clear_cursor()
    params.player.cursor_ghost = currentGhost

    return entities
end

return build