local TURN = require("scripts.helpers.turn")

local RAIL_TYPE_TO_CATEGORY = {
    ["straight-rail"] = "straight",
    ["half-diagonal-rail"] = "half-diagonal",
    ["curved-rail-a"] = "curved-a",
    ["curved-rail-b"] = "curved-b",
    ["rail-ramp"] = "ramp",
    ["elevated-straight-rail"] = "straight",
    ["elevated-half-diagonal-rail"] = "half-diagonal",
    ["elevated-curved-rail-a"] = "curved-a",
    ["elevated-curved-rail-b"] = "curved-b",
}

local LAYER_CATEGORY_TO_RAIL_TYPE = {
    [defines.rail_layer.ground] = {
        ["straight"] = "straight-rail",
        ["half-diagonal"] = "half-diagonal-rail",
        ["curved-a"] = "curved-rail-a",
        ["curved-b"] = "curved-rail-b",
        ["ramp"] = "rail-ramp",
    },
    [defines.rail_layer.elevated] = {
        ["straight"] = "elevated-straight-rail",
        ["half-diagonal"] = "elevated-half-diagonal-rail",
        ["curved-a"] = "elevated-curved-rail-a",
        ["curved-b"] = "elevated-curved-rail-b",
        ["ramp"] = "rail-ramp",
    },
}

local TYPE_TO_LAYER = {
    ["straight-rail"] = defines.rail_layer.ground,
    ["half-diagonal-rail"] = defines.rail_layer.ground,
    ["curved-rail-a"] = defines.rail_layer.ground,
    ["curved-rail-b"] = defines.rail_layer.ground,
    ["rail-ramp"] = defines.rail_layer.elevated, -- ramps need to use the elevated algorithm.
    ["elevated-straight-rail"] = defines.rail_layer.elevated,
    ["elevated-half-diagonal-rail"] = defines.rail_layer.elevated,
    ["elevated-curved-rail-a"] = defines.rail_layer.elevated,
    ["elevated-curved-rail-b"] = defines.rail_layer.elevated,
}

local RAIL_PATH_CONFIG = {
    ["straight"] = {
        edges = {
            [defines.direction.north] = { x =  0, y = -1 },
            [defines.direction.east]  = { x =  1, y =  0 },
            [defines.direction.south] = { x =  0, y =  1 },
            [defines.direction.west]  = { x = -1, y =  0 },
            [defines.direction.northeast] = { x =  1, y = -1 },
            [defines.direction.southeast] = { x =  1, y =  1 },
            [defines.direction.southwest] = { x = -1, y =  1 },
            [defines.direction.northwest] = { x = -1, y = -1 },
        },
        paths = {
            [defines.direction.north] = { defines.direction.north, defines.direction.south },
            [defines.direction.northeast] = { defines.direction.northeast, defines.direction.southwest },
            [defines.direction.east] = { defines.direction.east, defines.direction.west },
            [defines.direction.southeast] = { defines.direction.southeast, defines.direction.northwest },
        },
    },
    ["half-diagonal"] = {
        edges = {
            [defines.direction.northnortheast] = { x =  1, y = -2 },
            [defines.direction.northnorthwest] = { x = -1, y = -2 },
            [defines.direction.eastnortheast]  = { x =  2, y = -1 },
            [defines.direction.eastsoutheast]  = { x =  2, y =  1 },
            [defines.direction.southsoutheast] = { x =  1, y =  2 },
            [defines.direction.southsouthwest] = { x = -1, y =  2 },
            [defines.direction.westsouthwest]  = { x = -2, y =  1 },
            [defines.direction.westnorthwest]  = { x = -2, y = -1 },
        },
        paths = {
            [defines.direction.north] = { defines.direction.southsoutheast, defines.direction.northnorthwest },
            [defines.direction.northeast] = { defines.direction.northnortheast, defines.direction.southsouthwest },
            [defines.direction.east] = { defines.direction.eastnortheast, defines.direction.westsouthwest },
            [defines.direction.southeast] = { defines.direction.eastsoutheast, defines.direction.westnorthwest },
        },
    },
    ["curved-a"] = {
        edges = {
            [defines.direction.north] = { x =  0, y = -2 },
            [defines.direction.east]  = { x =  2, y =  0 },
            [defines.direction.south] = { x =  0, y =  2 },
            [defines.direction.west]  = { x = -2, y =  0 },
            [defines.direction.northnortheast] = { x =  1, y = -3 },
            [defines.direction.northnorthwest] = { x = -1, y = -3 },
            [defines.direction.eastnortheast]  = { x =  3, y = -1 },
            [defines.direction.eastsoutheast]  = { x =  3, y =  1 },
            [defines.direction.southsoutheast] = { x =  1, y =  3 },
            [defines.direction.southsouthwest] = { x = -1, y =  3 },
            [defines.direction.westsouthwest]  = { x = -3, y =  1 },
            [defines.direction.westnorthwest]  = { x = -3, y = -1 },
        },
        paths = {
            [defines.direction.north] = { defines.direction.south, defines.direction.northnorthwest },
            [defines.direction.northeast] = { defines.direction.northnortheast, defines.direction.south },
            [defines.direction.east] = { defines.direction.eastnortheast, defines.direction.west },
            [defines.direction.southeast] = { defines.direction.eastsoutheast, defines.direction.west },
            [defines.direction.south] = { defines.direction.north, defines.direction.southsoutheast },
            [defines.direction.southwest] = { defines.direction.north, defines.direction.southsouthwest },
            [defines.direction.west] = { defines.direction.east, defines.direction.westsouthwest },
            [defines.direction.northwest] = { defines.direction.east, defines.direction.westnorthwest },
        },
    },
    ["curved-b"] = {
        edges = {
            [defines.direction.northeast] = { x =  2, y = -2 },
            [defines.direction.southeast] = { x =  2, y =  2 },
            [defines.direction.southwest] = { x = -2, y =  2 },
            [defines.direction.northwest] = { x = -2, y = -2 },
            [defines.direction.northnortheast] = { x =  1, y = -2 },
            [defines.direction.northnorthwest] = { x = -1, y = -2 },
            [defines.direction.eastnortheast]  = { x =  2, y = -1 },
            [defines.direction.eastsoutheast]  = { x =  2, y =  1 },
            [defines.direction.southsoutheast] = { x =  1, y =  2 },
            [defines.direction.southsouthwest] = { x = -1, y =  2 },
            [defines.direction.westsouthwest]  = { x = -2, y =  1 },
            [defines.direction.westnorthwest]  = { x = -2, y = -1 },
        },
        paths = {
            [defines.direction.north] = { defines.direction.southsoutheast, defines.direction.northwest },
            [defines.direction.northeast] = { defines.direction.northeast, defines.direction.southsouthwest },
            [defines.direction.east] = { defines.direction.northeast, defines.direction.westsouthwest },
            [defines.direction.southeast] = { defines.direction.southeast, defines.direction.westnorthwest },
            [defines.direction.south] = { defines.direction.southeast, defines.direction.northnorthwest },
            [defines.direction.southwest] = { defines.direction.northnortheast, defines.direction.southwest },
            [defines.direction.west] = { defines.direction.eastnortheast, defines.direction.southwest },
            [defines.direction.northwest] = { defines.direction.eastsoutheast, defines.direction.northwest },
        },
    },
    ["ramp"] = {
        edges = {
            [defines.direction.north] = { x =  0, y = -8 },
            [defines.direction.east] =  { x =  8, y =  0 },
            [defines.direction.south] = { x =  0, y =  8 },
            [defines.direction.west] =  { x = -8, y =  0 },
        },
        paths = {
            [defines.direction.north] = { defines.direction.north, defines.direction.south },
            [defines.direction.east] = { defines.direction.east, defines.direction.west },
            [defines.direction.south] = { defines.direction.south, defines.direction.north },
            [defines.direction.west] = { defines.direction.west, defines.direction.east },
        },
    }
}


-- Programmatically populated based on paths.
-- Map of current direction -> desired direction -> { type, rotation, offset = {x, y}}
local RAIL_TURN_MAP = {
    [defines.direction.north] = {},
    [defines.direction.northnortheast] = {},
    [defines.direction.northeast] = {},
    [defines.direction.eastnortheast] = {},
    [defines.direction.east] = {},
    [defines.direction.eastsoutheast] = {},
    [defines.direction.southeast] = {},
    [defines.direction.southsoutheast] = {},
    [defines.direction.south] = {},
    [defines.direction.southsouthwest] = {},
    [defines.direction.southwest] = {},
    [defines.direction.westsouthwest] = {},
    [defines.direction.west] = {},
    [defines.direction.westnorthwest] = {},
    [defines.direction.northwest] = {},
    [defines.direction.northnorthwest] = {},
}

for category, config in pairs(RAIL_PATH_CONFIG) do
    if category ~= "ramp" then
        for rotation, paths in pairs(config.paths) do
            local forward, backward = unpack(paths)

            RAIL_TURN_MAP[TURN.around(forward)][backward] = {
                category = category,
                rotation = rotation,
                offset = { x = -config.edges[forward].x, y = -config.edges[forward].y },
                config = config,
            }
            RAIL_TURN_MAP[TURN.around(backward)][forward] = {
                category = category,
                rotation = rotation,
                offset = { x = -config.edges[backward].x, y = -config.edges[backward].y },
                config = config,
            }
        end
    end
end

-- Planner -> Type -> Name
local PLANNER_PARTS = {}

for plannerName, planner in pairs(prototypes.get_item_filtered(
    {{ filter = "type", type = "rail-planner" }}
)) do
    local plannerConfig = {}
    PLANNER_PARTS[plannerName] = plannerConfig

    for _, rail in pairs(planner.rails) do
        plannerConfig[rail.type] = rail.name
    end
end

return {
    RAIL_TYPE_TO_CATEGORY = RAIL_TYPE_TO_CATEGORY,
    LAYER_CATEGORY_TO_RAIL_TYPE = LAYER_CATEGORY_TO_RAIL_TYPE,
    TYPE_TO_LAYER = TYPE_TO_LAYER,
    RAIL_PATH_CONFIG = RAIL_PATH_CONFIG,
    RAIL_TURN_MAP = RAIL_TURN_MAP,
    PLANNER_PARTS = PLANNER_PARTS,
    SPACING = {
        ["2-tile"] = require("scripts.rail-config.2-tile"),
    }
}