local TYPE_TO_LAYER = require("scripts.rail-consts.raw.layer")
local TYPE_TO_CATEGORY = require("scripts.rail-consts.raw.type-to-category")
local CATEGORY_TO_TYPE = require("scripts.rail-consts.raw.category-to-type")
local EDGE_OFFSET = require("scripts.rail-consts.raw.edge-offset")
local METADATA_BY_CATEGORY = require("scripts.rail-consts.by-category")
local METADATA_BY_TURN = require("scripts.rail-consts.by-turn")

local Helper = require("scripts.helpers")
local Turn = require("scripts.classes.turn")
local RailPointer = require("scripts.classes.rail-pointer")

--- @class (exact) RailSegment
--- @field turn Turn
--- @field category RailCategory
--- @field type RailEntityType
--- @field position Vector2d
--- @field rotation EntityDirection
--- @field surface LuaSurface
--- @field forward RailPointer
--- @field backward RailPointer
--- @field eventIndex number? The event number which created this segment.
--- @field entity LuaEntity? The rail entity. Use getEntity()
--- @field tiles LuaEntity[]? Tiles added to support this entity.
local RailSegment = {}
--- @diagnostic disable-next-line: inject-field
RailSegment.__index = RailSegment

------------------
-- Constructors --
------------------

--- Creates a new RailSegment from a pointer and turn.
--- @param pointer RailPointer
--- @param turn Turn
--- @return RailSegment
--- @diagnostic disable-next-line: inject-field
function RailSegment.fromPointer(pointer, turn)
    local segment = {}

    local forward = Turn(pointer.direction, turn)
    local backward = Turn.around(pointer.direction)
    local turnInfo = METADATA_BY_TURN[pointer.direction][turn]

    segment.turn = turn
    segment.category = turnInfo.category
    segment.type = CATEGORY_TO_TYPE[turnInfo.category][pointer.layer]
    segment.rotation = turnInfo.rotation
    segment.position = pointer.position - EDGE_OFFSET[turnInfo.category][backward]
    segment.surface = pointer.surface

    segment.forward = RailPointer:new({
        position = segment.position + EDGE_OFFSET[turnInfo.category][forward],
        direction = forward,
        layer = pointer.layer,
        surface = pointer.surface,
    })
    segment.backward = pointer:createReverse()

    segment.index = -1
    segment.support = nil
    segment.tiles = nil

    setmetatable(segment, RailSegment)
    return segment
end

--- Creates a new Ramp RailSegment from a starting pointer.
--- Nil if a ramp cannot be created.
--- @param pointer RailPointer
--- @return RailSegment?
--- @diagnostic disable-next-line: inject-field
function RailSegment.rampFromPointer(pointer)
    -- Ramps can only be made on cardinals.
    if pointer.direction % 4 ~= 0 then return nil end

    local segment = {}
    local backward = pointer:createReverse()

    segment.turn = Turn.STRAIGHT
    segment.category = "ramp"
    segment.type = "rail-ramp"
    segment.rotation = pointer.layer == defines.rail_layer.ground and pointer.direction or backward.direction
    segment.position = pointer.position - EDGE_OFFSET["ramp"][backward.direction]
    segment.surface = pointer.surface

    segment.forward = RailPointer:new({
        position = segment.position + EDGE_OFFSET["ramp"][pointer.direction],
        direction = pointer.direction,
        layer = pointer.layer == defines.rail_layer.ground and defines.rail_layer.elevated or defines.rail_layer.ground,
        surface = pointer.surface,
    })
    segment.backward = backward

    segment.support = nil
    segment.tiles = nil

    setmetatable(segment, RailSegment)
    return segment
end

--- Creates a new RailSegment from an existing entity
--- @param rail LuaEntity
--- @return RailSegment
--- @diagnostic disable-next-line: inject-field
function RailSegment.fromEntity(rail)
    local segment = {}

    local type = Helper.getEntityType(rail)
    local category = TYPE_TO_CATEGORY[type]
    local forward, backward = table.unpack(METADATA_BY_CATEGORY[category][rail.direction].edges)

    segment.turn = Helper.getTurnFromEntityDirections(forward, backward)
    segment.type = type
    segment.category = category
    segment.rotation = rail.direction
    segment.position = rail.position
    segment.surface = rail.surface

    segment.forward = RailPointer:new({
        position = EDGE_OFFSET[category][forward] + segment.position,
        direction = forward,
        layer = TYPE_TO_LAYER[segment.type],
        surface = rail.surface,
    })
    segment.backward = RailPointer:new({
        position = EDGE_OFFSET[category][backward] + segment.position,
        direction = backward,
        layer = type == "rail-ramp" and defines.rail_layer.ground or TYPE_TO_LAYER[segment.type],
        surface = rail.surface,
    })

    segment.entity = rail
    segment.support = nil
    segment.tiles = nil

    setmetatable(segment, RailSegment)
    return segment
end

--- Gets all possible rail segments from a given pointer.
--- @param pointer RailPointer
--- @return [RailSegment, RailSegment, RailSegment, RailSegment?]
--- @diagnostic disable-next-line: inject-field
function RailSegment.getAllFromPointer(pointer)
    return {
        RailSegment.fromPointer(pointer, Turn.STRAIGHT),
        RailSegment.fromPointer(pointer, Turn.RIGHT),
        RailSegment.fromPointer(pointer, Turn.LEFT),
        RailSegment.rampFromPointer(pointer),
    }
end

--- Gets all existing entity RailSegments attached to a given pointer.
--- @param pointer RailPointer
--- @return RailSegment[]
--- @diagnostic disable-next-line: inject-field
function RailSegment.getAllExistingFromPointer(pointer)
    local result = {}
    for _, extension in pairs(RailSegment.getAllFromPointer(pointer)) do
        if extension:getEntity() then
            table.insert(result, extension)
        end
    end
    return result
end

---------------
-- Alignment --
---------------

--- Modifies the current RailSegment, reversing it.
function RailSegment:reverse()
    self.turn = -self.turn
    self.forward, self.backward = self.backward, self.forward
end

--- Modifies the current RailSegment, reversing it so it faces away from the target.
--- @param target RailSegment | RailPointer
--- @return boolean
function RailSegment:alignAwayFrom(target)
    if getmetatable(target) == RailSegment then target = target.forward end

    --- @diagnostic disable-next-line: param-type-mismatch
    if self.forward:isOpposite(target) then
        -- Reverses self so this backward -> target forward
        self:reverse()
        return true
    end

    return target:isOpposite(self.backward)
end

--- Aligns two RailSegments, such that this -> forward is touching target -> backward
--- @param target RailSegment
--- @return boolean
function RailSegment:alignSegments(target)
    -- Reverses both so this.forward -> target.backward
    if self.backward:isOpposite(target.backward) then
        self:reverse()
        return true
    elseif self.backward:isOpposite(target.forward) then
        self:reverse()
        target:reverse()
        return true
    elseif self.forward:isOpposite(target.forward) then
        target:reverse()
        return true
    end
    return self.forward:isOpposite(target.backward)
end

--- Checks if this RailSegment leads into the target.
--- @param target RailSegment
--- @return boolean
function RailSegment:connectedTo(target)
    return self.forward:isOpposite(target.backward)
end

---------------------
-- Entity Checking --
---------------------

--- Gets the physical LuaEntity at this location, if it exists
--- @return LuaEntity?
function RailSegment:getEntity()
    if not self.entity or not self.entity.valid then
        self.entity = Helper.getEntityAt({
            type = self.type,
            surface = self.surface,
            position = self.position,
            direction = self.rotation
        })
    end

    return self.entity
end

--------------------
-- Helper Methods --
--------------------

function RailSegment:__eq(other)
    return self.type == other.type
       and self.rotation == other.rotation
       and self.position.x == other.position.x
       and self.position.y == other.position.y
       and self.surface == other.surface
end

local drawFunctions = require("scripts.classes.rail-segment_draw")

--- Renders this RailSegment and its event number on the screen. Debug only.
--- @param player LuaPlayer
--- @param pathIndex number
function RailSegment:draw(player, pathIndex)
    if DRAW_MODE then
        drawFunctions.draw(self, player, pathIndex)
    end
end

--- Renders this RailSegment's path number. Debug only.
--- @param player LuaPlayer
function RailSegment:drawEventText(player)
    if DRAW_MODE then
        drawFunctions.drawEventText(self, player)
    end
end

--- Renders this RailSegment as a rewind.
--- @param player LuaPlayer
function RailSegment:drawRewind(player)
    if DRAW_MODE then
        drawFunctions.drawRewind(self, player)
    end
end

script.register_metatable("RailSegment", RailSegment)
return RailSegment
