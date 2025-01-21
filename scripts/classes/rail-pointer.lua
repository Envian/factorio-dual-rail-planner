local validate = require("scripts.helpers.validate")
local TURN = require("scripts.helpers.turn")

local RailPointer = {}
RailPointer.__index = RailPointer

-- { position, direction, layer, surface }
function RailPointer.new(params)
    assert(validate.position(params.position))
    assert(validate.direction(params.direction))
    assert(params.layer == defines.rail_layer.ground or params.layer == defines.rail_layer.elevated)
    assert(params.surface.object_name == "LuaSurface")

    local pointer = {}

    pointer.position = params.position
    pointer.direction = params.direction
    pointer.layer = params.layer
    pointer.surface = params.surface

    setmetatable(pointer, RailPointer)
    return pointer
end

function RailPointer:createReverse()
    return RailPointer.new({
        position = self.position,
        direction = TURN.around(self.direction),
        layer = self.layer,
        surface = self.surface
    })
end

function RailPointer:isOpposite(other)
    return self.surface == other.surface
       and self.position.x == other.position.x
       and self.position.y == other.position.y
       and self.layer == other.layer
       and self.direction == TURN.around(other.direction)
end

-- Read Only
function RailPointer:__newIndex(key, value)
    error("Rail Pointers are read only.")
end

function RailPointer:__eq(other)
    return self.surface == other.surface
       and self.position.x == other.position.x
       and self.position.y == other.position.y
       and self.layer == other.layer
       and self.direction == other.direction
end

script.register_metatable("RailPointer", RailPointer)
return RailPointer