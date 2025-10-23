local OPPOSITE_OFFSETS = require("scripts.rail-consts.raw.opposite-offsets")

local Turn = require("scripts.classes.turn")
local Vector2d = require("scripts.classes.vector")

--- @class (exact) RailPointer
--- @field position Vector2d
--- @field direction TrueDirection
--- @field layer defines.rail_layer
--- @field surface LuaSurface
local RailPointer = {}

---@diagnostic disable-next-line: inject-field
RailPointer.__index = RailPointer

--- Creates a new pointer.
--- @param params RailPointer
--- @return RailPointer
function RailPointer:new(params)
    return setmetatable({
        position = Vector2d:new(params.position),
        direction = params.direction,
        layer = params.layer,
        surface = params.surface
    }, RailPointer)
end

--- Returns the rail pointer in the opposite direction.
--- @return RailPointer
function RailPointer:createReverse()
    return RailPointer:new({
        position = Vector2d:new(self.position),
        direction = Turn.around(self.direction),
        layer = self.layer,
        surface = self.surface
    })
end

--- Creates a pointer for parrallel tracks.
--- @param trackOffset number
--- @return RailPointer
function RailPointer:createParrallel(trackOffset)
    local evenOffsets = math.floor(math.abs(trackOffset) / 2) * 2
    local oddOffsets = trackOffset % 2

    local offset =
        OPPOSITE_OFFSETS.even[self.direction] * evenOffsets +
        OPPOSITE_OFFSETS.odd[self.direction] * oddOffsets

    if trackOffset < 0 then
        offset:scale(-1)
    end

    return RailPointer:new({
        position = self.position + offset,
        direction = self.direction,
        layer = self.layer,
        surface = self.surface
    })
end

--- Checks if these pointers are at the same position,
--- but facing opposite directions.
--- @param other RailPointer
--- @return boolean
function RailPointer:isOpposite(other)
    return self.surface == other.surface
       and self.position.x == other.position.x
       and self.position.y == other.position.y
       and self.layer == other.layer
       and self.direction == Turn.around(other.direction)
end

--- Converts this table to a key for hash lookup.
--- @return string
function RailPointer:toKey()
    return self.surface.index .. "|"
        .. self.position.x .. "|"
        .. self.position.y .. "|"
        .. self.layer .. "|"
        .. self.direction
end

--- Converts this table to a key for hash lookup.
--- @return string
function RailPointer:toKeyReverse()
    return self.surface.index .. "|"
        .. self.position.x .. "|"
        .. self.position.y .. "|"
        .. self.layer .. "|"
        .. Turn.around(self.direction)
end

script.register_metatable("RailPointer", RailPointer)
return RailPointer
