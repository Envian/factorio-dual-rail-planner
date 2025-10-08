--- @type { [RailEntityType]: defines.rail_layer }
return {
    ["straight-rail"] = defines.rail_layer.ground,
    ["half-diagonal-rail"] = defines.rail_layer.ground,
    ["curved-rail-a"] = defines.rail_layer.ground,
    ["curved-rail-b"] = defines.rail_layer.ground,

    -- EventParser depends on this being elevated. may be able to swap.
    ["rail-ramp"] = defines.rail_layer.elevated,

    ["elevated-straight-rail"] = defines.rail_layer.elevated,
    ["elevated-half-diagonal-rail"] = defines.rail_layer.elevated,
    ["elevated-curved-rail-a"] = defines.rail_layer.elevated,
    ["elevated-curved-rail-b"] = defines.rail_layer.elevated,
}
