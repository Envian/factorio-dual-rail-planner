--- @class (exact) Vector2d
--- @field x number
--- @field y number
local Vector2d = {}

--- @diagnostic disable-next-line: inject-field
Vector2d.__index = Vector2d

--- @alias VectorLike Vector2d | Vector | MapPosition | TilePosition

--- Creates a new vector2d
--- @param xOrOther number | VectorLike
--- @param y number?
--- @return Vector2d
function Vector2d:new(xOrOther, y)
    return setmetatable(
        type(xOrOther) == "number" and { x = xOrOther, y = y } or
        { x = xOrOther.x or xOrOther[1], y = xOrOther.y or xOrOther[2] },
        Vector2d
    )
end

--- Moves this vector to another position.
--- @param other VectorLike
function Vector2d:move(other)
    self.x = self.x + (other.x or other[1])
    self.y = self.y + (other.y or other[2])
end

--- Scales this vector by a factor.
--- @param scale number
function Vector2d:scale(scale)
    self.x = self.x * scale
    self.y = self.y * scale
end

--- Returns the cross product of two vectors. This is magic, how does it work.
--- @param other VectorLike
--- @return number
function Vector2d:crossProduct(other)
    return self.x * (other.y or other[2]) - self.y * (other.x or other[1])
end

--- Gets the dot product of two vectors.
--- @param other VectorLike
--- @return number
function Vector2d:dotProduct(other)
    return self.x * (other.x or other[1]) + self.y * (other.y or other[2])
end

--- Compares two vectors
--- @param other VectorLike
--- @return boolean
function Vector2d:equals(other)
    return self.x == (other.x or other[1])
       and self.y == (other.y or other[2])
end

--- Adds two vectors and returns a new vector.
--- @param other VectorLike
--- @return Vector2d
function Vector2d:__add(other)
    return setmetatable({
        x = self.x + (other.x or other[1]),
        y = self.y + (other.y or other[2]),
    }, Vector2d)
end

--- Subtracts two vectors and returns a new vector.
--- @param other VectorLike
--- @return Vector2d
function Vector2d:__sub(other)
    return setmetatable({
        x = self.x - (other.x or other[1]),
        y = self.y - (other.y or other[2]),
    }, Vector2d)
end

--- Multiplies a vector by a scale and returns the result.
--- @param scale number
--- @return Vector2d
function Vector2d:__mul(scale)
    return setmetatable({
        x = self.x * scale,
        y = self.y * scale,
    }, Vector2d)
end

--- Divides a vector by a scale and returns the result.
--- @param scale number
--- @return Vector2d
function Vector2d:__div(scale)
    return setmetatable({
        x = self.x / scale,
        y = self.y / scale,
    }, Vector2d)
end

--- Compares two vectors
--- @param other Vector2d
--- @return boolean
function Vector2d:__eq(other)
    return self.x == other.x and self.y == other.y
end

return Vector2d
