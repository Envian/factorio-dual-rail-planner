local Vector2d = require("scripts.classes.vector")

return {
    [defines.direction.north] = { Vector2d:new(-2, 0) },
    [defines.direction.east]  = { Vector2d:new( 0,-2) },
    [defines.direction.south] = { Vector2d:new( 2, 0) },
    [defines.direction.west]  = { Vector2d:new( 0, 2) },
    [defines.direction.northeast] = { Vector2d:new(-2, 0), Vector2d:new(-4,-2), Vector2d:new(-6,-4), Vector2d:new(-6,-6) },
    [defines.direction.southeast] = { Vector2d:new( 2, 0), Vector2d:new( 4,-2), Vector2d:new( 6,-4), Vector2d:new( 6,-6) },
    [defines.direction.southwest] = { Vector2d:new( 2, 0), Vector2d:new( 4, 2), Vector2d:new( 6, 4), Vector2d:new( 6, 6) },
    [defines.direction.northwest] = { Vector2d:new(-2, 0), Vector2d:new(-4, 2), Vector2d:new(-6, 4), Vector2d:new(-6, 6) },
    [defines.direction.northnortheast] = { Vector2d:new(-2, 0), Vector2d:new(-4,-2) },
    [defines.direction.eastnortheast]  = { Vector2d:new( 0,-2), Vector2d:new(-2,-4) },
    [defines.direction.eastsoutheast]  = { Vector2d:new( 0,-2), Vector2d:new( 2,-4) },
    [defines.direction.southsoutheast] = { Vector2d:new( 2, 0), Vector2d:new( 4,-2) },
    [defines.direction.southsouthwest] = { Vector2d:new( 2, 0), Vector2d:new( 4, 2) },
    [defines.direction.westsouthwest]  = { Vector2d:new( 0, 2), Vector2d:new( 2, 4) },
    [defines.direction.westnorthwest]  = { Vector2d:new( 0, 2), Vector2d:new(-2, 4) },
    [defines.direction.northnorthwest] = { Vector2d:new(-2, 0), Vector2d:new(-4, 2) },
}
