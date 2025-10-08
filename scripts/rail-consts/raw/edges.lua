--- Map to determine where the rail's edges are from type and direction.
--- @type { [RailCategory]: { [EntityDirection]: [TrueDirection, TrueDirection] } }
return {
    ["straight"] = {
        [defines.direction.north] = { defines.direction.north, defines.direction.south },
        [defines.direction.northeast] = { defines.direction.northeast, defines.direction.southwest },
        [defines.direction.east] = { defines.direction.east, defines.direction.west },
        [defines.direction.southeast] = { defines.direction.southeast, defines.direction.northwest },
    },
    ["half-diagonal"] = {
        [defines.direction.north] = { defines.direction.southsoutheast, defines.direction.northnorthwest },
        [defines.direction.northeast] = { defines.direction.northnortheast, defines.direction.southsouthwest },
        [defines.direction.east] = { defines.direction.eastnortheast, defines.direction.westsouthwest },
        [defines.direction.southeast] = { defines.direction.eastsoutheast, defines.direction.westnorthwest },
    },
    ["curved-a"] = {
        [defines.direction.north] = { defines.direction.south, defines.direction.northnorthwest },
        [defines.direction.northeast] = { defines.direction.northnortheast, defines.direction.south },
        [defines.direction.east] = { defines.direction.eastnortheast, defines.direction.west },
        [defines.direction.southeast] = { defines.direction.eastsoutheast, defines.direction.west },
        [defines.direction.south] = { defines.direction.north, defines.direction.southsoutheast },
        [defines.direction.southwest] = { defines.direction.north, defines.direction.southsouthwest },
        [defines.direction.west] = { defines.direction.east, defines.direction.westsouthwest },
        [defines.direction.northwest] = { defines.direction.east, defines.direction.westnorthwest },
    },
    ["curved-b"] = {
        [defines.direction.north] = { defines.direction.southsoutheast, defines.direction.northwest },
        [defines.direction.northeast] = { defines.direction.northeast, defines.direction.southsouthwest },
        [defines.direction.east] = { defines.direction.northeast, defines.direction.westsouthwest },
        [defines.direction.southeast] = { defines.direction.southeast, defines.direction.westnorthwest },
        [defines.direction.south] = { defines.direction.southeast, defines.direction.northnorthwest },
        [defines.direction.southwest] = { defines.direction.northnortheast, defines.direction.southwest },
        [defines.direction.west] = { defines.direction.eastnortheast, defines.direction.southwest },
        [defines.direction.northwest] = { defines.direction.eastsoutheast, defines.direction.northwest },
    },
    ["ramp"] = {
        [defines.direction.north] = { defines.direction.north, defines.direction.south },
        [defines.direction.east] = { defines.direction.east, defines.direction.west },
        [defines.direction.south] = { defines.direction.south, defines.direction.north },
        [defines.direction.west] = { defines.direction.west, defines.direction.east },
    },
}
