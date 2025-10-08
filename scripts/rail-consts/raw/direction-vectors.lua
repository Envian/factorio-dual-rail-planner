local Vector2d = require("scripts.classes.vector")

-- Given a direction, returns a normalized direction vector in turn algorithms.

local function normalize(x, y)
    local scale = math.sqrt(x * x + y * y)
    return Vector2d:new({ x = x / scale, y = y / scale })
end

--- @type { [TrueDirection]: Vector2d }
return {
    [defines.direction.north] = normalize(0, -1),
    [defines.direction.east] = normalize(1, 0),
    [defines.direction.south] = normalize(0, 1),
    [defines.direction.west] = normalize(-1, 0),
    [defines.direction.northeast] = normalize(1, -1),
    [defines.direction.southeast] = normalize(1, 1),
    [defines.direction.southwest] = normalize(-1, 1),
    [defines.direction.northwest] = normalize(-1, -1),
    [defines.direction.northnortheast] = normalize(1, -2),
    [defines.direction.eastnortheast]  = normalize(2, -1),
    [defines.direction.eastsoutheast]  = normalize(2, 1),
    [defines.direction.southsoutheast] = normalize(1, 2),
    [defines.direction.southsouthwest] = normalize(-1, 2),
    [defines.direction.westsouthwest]  = normalize(-2, 1),
    [defines.direction.westnorthwest]  = normalize(-2, -1),
    [defines.direction.northnorthwest] = normalize(-1, -2),
}
