require("scripts.constants")
require("scripts.helpers")
require("scripts.rail-defines")

require("scripts.rail-pointer")

RailSegment = {}
RailSegment.__index = RailSegment

function RailSegment.fromPointer(pointer, turn)
    local segment = { }
    setmetatable(segment, RailSegment)

    local targetDirection = doTurn(pointer.direction, turn)
    local targetDefine = RAIL_TURN_MAP[pointer.direction][targetDirection]
    local config = targetDefine.config

    segment.turn = turn
    segment.type = LAYER_CATEGORY_TO_RAIL_TYPE[pointer.layer][targetDefine.category]
    segment.category = targetDefine.category
    segment.rotation = targetDefine.rotation
    segment.position = addPositions(pointer.position, targetDefine.offset)
    segment.surface = pointer.surface

    segment.forward = RailPointer.new({
        position = addPositions(segment.position, config.edges[targetDirection]),
        direction = targetDirection,
        layer = pointer.layer,
        surface = pointer.surface,
    })
    segment.backward = pointer:createReverse()

    -- use getEntity
    segment._useRailCache = false
    segment._rail = nil

    segment:validate()
    return segment
end

function RailSegment.fromEntity(rail, hintDirection)
    local segment = { }
    setmetatable(segment, RailSegment)

    segment.type = rail.type == "entity-ghost" and rail.ghost_type or rail.type
    local config = RAIL_PATH_CONFIG[RAIL_TYPE_TO_CATEGORY[segment.type]]
    segment.category = RAIL_TYPE_TO_CATEGORY[segment.type]
    segment.rotation = rail.direction
    segment.position = rail.position
    segment.surface = rail.surface

    local forward, backward = unpack(config.paths[segment.rotation])
    if hintDirection == doTurn(forward, TURN.AROUND) then
        forward, backward = backward, forward
    end
    segment.turn = getTurnFromDirections(forward, backward)

    segment.forward = RailPointer.new({
        position = addPositions(segment.position, config.edges[forward]),
        direction = forward,
        layer = TYPE_TO_LAYER[segment.type],
        surface = rail.surface,
    })
    segment.backward = RailPointer.new({
        position = addPositions(segment.position, config.edges[backward]),
        direction = backward,
        layer = TYPE_TO_LAYER[segment.type],
        surface = rail.surface,
    })

    -- use getEntity
    segment._useRailCache = true
    segment._rail = rail

    segment:validate()
    return segment
end

function RailSegment.rampFromPointer(pointer)
    -- Ramps can only be made on cardinals.
    if pointer.direction % 4 ~= 0 then return end

    local segment = { }
    setmetatable(segment, RailSegment)

    local config = RAIL_PATH_CONFIG["ramp"]
    segment.turn = TURN.STRAIGHT
    segment.type = "rail-ramp"
    segment.category = "ramp"
    segment.rotation = pointer.layer == defines.rail_layer.ground and pointer.direction or doTurn(pointer.direction, TURN.AROUND)
    -- This depends on ramps being symmetrical.
    segment.position = addPositions(pointer.position, config.edges[pointer.direction])
    segment.surface = pointer.surface

    segment.forward = RailPointer.new({
        position = addPositions(segment.position, config.edges[pointer.direction]),
        direction = pointer.direction,
        layer = pointer.layer == defines.rail_layer.ground and defines.rail_layer.elevated or defines.rail_layer.ground,
        surface = pointer.surface,
    })
    segment.backward = pointer:createReverse()

    -- use getEntity
    segment._useRailCache = false
    segment._rail = nil

    segment:validate()
    return segment
end

function RailSegment.getAllFromPointer(pointer)
    if pointer.direction % 4 ~= 0 then
        return {
            RailSegment.fromPointer(pointer, TURN.STRAIGHT),
            RailSegment.fromPointer(pointer, TURN.RIGHT),
            RailSegment.fromPointer(pointer, TURN.LEFT),
        }
    else
        return {
            RailSegment.fromPointer(pointer, TURN.STRAIGHT),
            RailSegment.fromPointer(pointer, TURN.RIGHT),
            RailSegment.fromPointer(pointer, TURN.LEFT),
            RailSegment.rampFromPointer(pointer),
        }
    end
end

function RailSegment.validate(segment)
    assert(isValidRailTurn(segment.turn))
    assert(RAIL_TYPE_TO_CATEGORY[segment.type])
    assert(RAIL_PATH_CONFIG[segment.category])
    assert(isValidDirection(segment.rotation))
    assert(isValidPosition(segment.position))
    assert(segment.surface.object_name == "LuaSurface")
    assert(not segment._rail or segment._rail.object_name == "LuaEntity")

    RailPointer.validate(segment.forward)
    RailPointer.validate(segment.backward)
end

function RailSegment:isSame(other)
    return self.type == other.type
       and self.rotation == other.rotation
       and self.position.x == other.position.x
       and self.position.y == other.position.y
       and self.surface == other.surface
end

function RailSegment:reverse()
    self.turn = -self.turn
    self.forward, self.backward = self.backward, self.forward
end

function RailSegment:getEntity()
    if not self._useRailCache or (self._rail and not self._rail.valid) then
        self._useRailCache = true
        self._rail = self.surface.find_entities_filtered({
            type = self.type,
            position = self.position,
            direction = self.rotation,
            limit = 1
        })[1] or self.surface.find_entities_filtered({
            type = "entity-ghost",
            ghost_type = self.type,
            position = self.position,
            direction = self.rotation,
            limit = 1
        })[1]
    end
    return self._rail
end

-- { player, parts, buildMode }
function RailSegment:build(params)
    local rail = self:getEntity()

    -- If it already exists, we're done.
    if rail then
        return rail
    end

    local currentGhost = params.player.cursor_ghost
    params.player.cursor_stack.set_stack(FAKREAIL_PREFIX .. params.parts[self.type])
    params.player.build_from_cursor({
        position = self.position,
        direction = self.rotation,
        build_mode = params.buildMode == 0 and defines.build_mode.forced or params.buildMode,
        skip_fog_of_war = false,
    })
    params.player.clear_cursor()
    params.player.cursor_ghost = currentGhost

    self._rail = lastBuiltRail
    return self._rail
end

function RailSegment:deconstruct(player)
    local rail = self:getEntity()
    if not rail then return end

    if player.can_reach_entity(rail) and player.mine_entity(rail) then
        return
    end

    rail.order_deconstruction(player.force, player)
end

function RailSegment:draw(player)
    rendering.draw_line({
        color = { r = 1, g = 0, b = 0 },
        width = 2,
        from = self.position,
        to = self.forward.position,
        surface = self.surface,
        players = { player }
    })
    rendering.draw_line({
        color = { r = 1, g = 0, b = 0 },
        width = 2,
        from = self.position,
        to = self.backward.position,
        surface = self.surface,
        players = { player }
    })
    rendering.draw_circle({
        color = { r = 0, g = 1, b = 0 },
        radius = 0.1,
        filled = true,
        target = self.position,
        surface = self.surface,
        players = { player }
    })
end

script.register_metatable("RailSegment", RailSegment)