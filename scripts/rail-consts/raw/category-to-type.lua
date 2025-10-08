--- @type { [RailCategory]: { [defines.rail_layer]: RailEntityType } }
return {
    ["straight"] = {
        [defines.rail_layer.ground] = "straight-rail",
        [defines.rail_layer.elevated] = "elevated-straight-rail",
    },
    ["half-diagonal"] = {
        [defines.rail_layer.ground] = "half-diagonal-rail",
        [defines.rail_layer.elevated] = "elevated-half-diagonal-rail",
    },
    ["curved-a"] = {
        [defines.rail_layer.ground] = "curved-rail-a",
        [defines.rail_layer.elevated] = "elevated-curved-rail-a",
    },
    ["curved-b"] = {
        [defines.rail_layer.ground] = "curved-rail-b",
        [defines.rail_layer.elevated] = "elevated-curved-rail-b",
    },
    ["ramp"] = {
        [defines.rail_layer.ground] = "rail-ramp",
        [defines.rail_layer.elevated] = "rail-ramp",
    },
}
