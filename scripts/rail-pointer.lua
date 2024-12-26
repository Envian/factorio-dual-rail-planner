require("scripts.helpers")

RailPointer = {}
RailPointer.__index = RailPointer

-- { position, direction, layer, surface }
function RailPointer.new(params)
    local pointer = { }
    setmetatable(pointer, RailPointer)

    pointer.position = params.position
    pointer.direction = params.direction
    pointer.layer = params.layer
    pointer.surface = params.surface

    RailPointer.validate(pointer)

    return pointer
end

function RailPointer.validate(pointer)
    assert(isValidPosition(pointer.position))
    assert(isValidDirection(pointer.direction))
    assert(pointer.layer == defines.rail_layer.ground or pointer.layer == defines.rail_layer.elevated)
    assert(pointer.surface.object_name == "LuaSurface")
end

function RailPointer:createReverse()
    return RailPointer.new({
        position = self.position,
        direction = doTurn(self.direction, TURN.AROUND),
        layer = self.layer,
        surface = self.surface
    })
end

function RailPointer:isOpposite(other)
    return self.surface == other.surface
       and self.position.x == other.position.x
       and self.position.y == other.position.y
       and self.layer == other.layer
       and self.direction == doTurn(other.direction, TURN.AROUND)
end

function RailPointer:isSame(other)
    return self.surface == other.surface
       and self.position.x == other.position.x
       and self.position.y == other.position.y
       and self.layer == other.layer
       and self.direction == other.direction
end

script.register_metatable("RailPointer", RailPointer)