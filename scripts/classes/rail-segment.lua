local TURN = require("scripts.helpers.turn")

local validate = require("scripts.helpers.validate")
local position = require("scripts.helpers.position")
local build = require("scripts.helpers.build")

local RailPointer = require("scripts.classes.rail-pointer")

RailSegment = {}
RailSegment.__index = RailSegment

function RailSegment.fromPointer(pointer, turn)
    assert(getmetatable(pointer) == RailPointer)
    assert(validate.turn(turn))

    local segment = {}

    local targetDirection = TURN(pointer.direction, turn)
    local targetDefine = RAIL_TURN_MAP[pointer.direction][targetDirection]

    segment.turn = turn
    segment.type = LAYER_CATEGORY_TO_RAIL_TYPE[pointer.layer][targetDefine.category]
    segment.rotation = targetDefine.rotation
    segment.position = position.add(pointer.position, targetDefine.offset)
    segment.surface = pointer.surface

    segment.forward = RailPointer.new({
        position = position.add(segment.position, targetDefine.config.edges[targetDirection]),
        direction = targetDirection,
        layer = pointer.layer,
        surface = pointer.surface,
    })
    segment.backward = pointer:createReverse()

    -- use getEntity
    segment._useRailCache = false
    segment._rail = nil
    segment._tiles = nil

    setmetatable(segment, RailSegment)
    return segment
end

function RailSegment.rampFromPointer(pointer)
    assert(getmetatable(pointer) == RailPointer)

    -- Ramps can only be made on cardinals.
    if pointer.direction % 4 ~= 0 then return nil end

    local segment = {}

    local config = RAIL_PATH_CONFIG["ramp"]

    segment.turn = TURN.STRAIGHT
    segment.type = "rail-ramp"
    segment.rotation = pointer.layer == defines.rail_layer.ground and pointer.direction or TURN.around(pointer.direction)
    -- This depends on ramps being symmetrical.
    segment.position = position.add(pointer.position, config.edges[pointer.direction])
    segment.surface = pointer.surface

    segment.forward = RailPointer.new({
        position = position.add(segment.position, config.edges[pointer.direction]),
        direction = pointer.direction,
        layer = pointer.layer == defines.rail_layer.ground and defines.rail_layer.elevated or defines.rail_layer.ground,
        surface = pointer.surface,
    })
    segment.backward = pointer:createReverse()

    -- use getEntity
    segment._useRailCache = false
    segment._rail = nil

    setmetatable(segment, RailSegment)
    return segment
end

function RailSegment.fromEntity(rail, hintDirection)
    assert(validate.railEntity(rail))
    assert(hintDirection == nil or validate.direction(hintDirection))

    local segment = {}

    segment.type = rail.type == "entity-ghost" and rail.ghost_type or rail.type

    local config = RAIL_PATH_CONFIG[RAIL_TYPE_TO_CATEGORY[segment.type]]

    local forward, backward = unpack(config.paths[rail.direction])
    if hintDirection == TURN.around(forward) then
        forward, backward = backward, forward
    end

    segment.rotation = rail.direction
    segment.position = rail.position
    segment.surface = rail.surface
    segment.turn = ((forward - backward + 9) % 16) - 1

    segment.forward = RailPointer.new({
        position = position.add(segment.position, config.edges[forward]),
        direction = forward,
        layer = TYPE_TO_LAYER[segment.type],
        surface = rail.surface,
    })
    segment.backward = RailPointer.new({
        position = position.add(segment.position, config.edges[backward]),
        direction = backward,
        layer = TYPE_TO_LAYER[segment.type],
        surface = rail.surface,
    })

    -- use getEntity
    segment._useRailCache = true
    segment._rail = rail

    setmetatable(segment, RailSegment)
    return segment
end

function RailSegment.getAllFromPointer(pointer)
    return {
        RailSegment.fromPointer(pointer, TURN.STRAIGHT),
        RailSegment.fromPointer(pointer, TURN.RIGHT),
        RailSegment.fromPointer(pointer, TURN.LEFT),
        RailSegment.rampFromPointer(pointer),
    }
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

-- { player, plannerName }
function RailSegment:build(player, plannerName)
    local rail = self:getEntity()

    -- If it already exists, we're done.
    if rail then
        return
    end

    local entities = build({
        player = player,
        name = PLANNER_PARTS[plannerName][self.type],
        position = self.position,
        rotation = self.rotation,
    })

    -- Sort results.
    self._tiles = {}
    for _, entity in pairs(entities) do
        if entity.type == "tile-ghost" then
            table.insert(self._tiles, entity)
        else
            self._rail = entity
        end
    end
end

function RailSegment:deconstruct(player)
    local rail = self:getEntity()
    if not rail then return end

    rail.order_deconstruction(player.force, player)
    if self._tiles then
        for _, tile in pairs(self._tiles) do
            tile.order_deconstruction(player.force, player)
        end
    end

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

function RailSegment:__eq(other)
    return self.type == other.type
       and self.rotation == other.rotation
       and self.position.x == other.position.x
       and self.position.y == other.position.y
       and self.surface == other.surface
end

script.register_metatable("RailSegment", RailSegment)
return RailSegment