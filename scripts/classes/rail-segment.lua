local RAILDEFS = require("scripts.rail-config.common")

local TURN = require("scripts.helpers.turn")
local validate = require("scripts.helpers.validate")
local position = require("scripts.helpers.position")

local RailPointer = require("scripts.classes.rail-pointer")

local CACHE_STATE = {
    EMPTY = 0,
    NIL = 1,
    CACHED = 2,
}

RailSegment = {}
RailSegment.__index = RailSegment

function RailSegment.fromPointer(pointer, turn)
    assert(getmetatable(pointer) == RailPointer)
    assert(validate.turn(turn))

    local segment = {}

    local targetDirection = TURN(pointer.direction, turn)
    local targetDefine = RAILDEFS.RAIL_TURN_MAP[pointer.direction][targetDirection]

    segment.turn = turn
    segment.type = RAILDEFS.LAYER_CATEGORY_TO_RAIL_TYPE[pointer.layer][targetDefine.category]
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
    -- segment.__cacheState = CACHE_STATE.EMPTY
    -- segment.__rail = nil

    setmetatable(segment, RailSegment)
    return segment
end

function RailSegment.rampFromPointer(pointer)
    assert(getmetatable(pointer) == RailPointer)

    -- Ramps can only be made on cardinals.
    if pointer.direction % 4 ~= 0 then return nil end

    local segment = {}
    local config = RAILDEFS.RAIL_PATH_CONFIG["ramp"]

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
    -- segment.__cacheState = CACHE_STATE.EMPTY
    -- segment.__rail = nil

    setmetatable(segment, RailSegment)
    return segment
end

function RailSegment.fromEntity(rail)
    assert(validate.railEntity(rail))

    local segment = {}

    local type = rail.type == "entity-ghost" and rail.ghost_type or rail.type
    local config = RAILDEFS.RAIL_PATH_CONFIG[RAILDEFS.RAIL_TYPE_TO_CATEGORY[type]]
    local forward, backward = unpack(config.paths[rail.direction])

    segment.turn = ((forward - backward + 9) % 16) - 1
    segment.type = type
    segment.rotation = rail.direction
    segment.position = rail.position
    segment.surface = rail.surface

    segment.forward = RailPointer.new({
        position = position.add(segment.position, config.edges[forward]),
        direction = forward,
        layer = RAILDEFS.TYPE_TO_LAYER[segment.type],
        surface = rail.surface,
    })
    segment.backward = RailPointer.new({
        position = position.add(segment.position, config.edges[backward]),
        direction = backward,
        layer = RAILDEFS.TYPE_TO_LAYER[segment.type],
        surface = rail.surface,
    })

    -- use getEntity
    -- segment.__cacheState = CACHE_STATE.CACHED
    -- segment.__rail = rail

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

function RailSegment.getAllExistingFromPointer(pointer)
    local result = {}
    for _, extension in pairs(RailSegment.getAllFromPointer(pointer)) do
        if extension:getEntity() then
            table.insert(result, extension)
        end
    end
    return result
end


function RailSegment:reverse()
    self.turn = -self.turn
    self.forward, self.backward = self.backward, self.forward
end

function RailSegment:alignOther(target)
    -- Flips the target rail so that this rail points to it.
    if self.forward:isOpposite(target.forward) then
        target:reverse()
    end
end

function RailSegment:alignSegments(target)
    -- Align both rails so that the current one points to the target one.
    if self.backward:isOpposite(target.backward) then
        self:reverse()
    elseif self.backward:isOpposite(target.forward) then
        self:reverse()
        target:reverse()
    elseif self.forward:isOpposite(target.forward) then
        target:reverse()
    end
end

function RailSegment:connectedTo(target)
    return self.forward:isOpposite(target.backward)
end

function RailSegment:getEntity()
    -- Is this really necessary? It can cause issues if our cache is ever invalid.
    -- if (self.__rail and not self.__rail.valid)
    -- or (self.__cacheState == CACHE_STATE.EMPTY)
    -- or (self.__cacheState == CACHE_STATE.CACHED and not self.__rail)
    -- then
    --     self.__rail = self.surface.find_entities_filtered({
    --         type = self.type,
    --         position = self.position,
    --         direction = self.rotation,
    --         limit = 1
    --     })[1] or self.surface.find_entities_filtered({
    --         type = "entity-ghost",
    --         ghost_type = self.type,
    --         position = self.position,
    --         direction = self.rotation,
    --         limit = 1
    --     })[1]
    --     self.__cacheState = self.__rail == nil and CACHE_STATE.NIL or CACHE_STATE.CACHED
    -- end
    -- return self.__rail
    return self.surface.find_entities_filtered({
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

function RailSegment:__eq(other)
    return self.type == other.type
       and self.rotation == other.rotation
       and self.position.x == other.position.x
       and self.position.y == other.position.y
       and self.surface == other.surface
end

script.register_metatable("RailSegment", RailSegment)
return RailSegment