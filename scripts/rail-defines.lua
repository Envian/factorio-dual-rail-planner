local TURN = require("scripts.helpers.turn")

RAIL_TYPE_TO_CATEGORY = {
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

LAYER_CATEGORY_TO_RAIL_TYPE = {
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

TYPE_TO_LAYER = {
    ["straight-rail"] = defines.rail_layer.ground,
    ["half-diagonal-rail"] = defines.rail_layer.ground,
    ["curved-rail-a"] = defines.rail_layer.ground,
    ["curved-rail-b"] = defines.rail_layer.ground,
    ["rail-ramp"] = defines.rail_layer.ground,
    ["elevated-straight-rail"] = defines.rail_layer.elevated,
    ["elevated-half-diagonal-rail"] = defines.rail_layer.elevated,
    ["elevated-curved-rail-a"] = defines.rail_layer.elevated,
    ["elevated-curved-rail-b"] = defines.rail_layer.elevated,
}

RAIL_PATH_CONFIG = {
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

OPPOSITE_OFFSET = {
    [defines.direction.north] = { x = -4, y =  0 },
    [defines.direction.east]  = { x =  0, y = -4 },
    [defines.direction.south] = { x =  4, y =  0 },
    [defines.direction.west]  = { x =  0, y =  4 },
    [defines.direction.northeast] = { x = -2, y = -4 },
    [defines.direction.southeast] = { x =  4, y = -2 },
    [defines.direction.southwest] = { x =  2, y =  4 },
    [defines.direction.northwest] = { x = -4, y =  2 },
    [defines.direction.northnortheast] = { x = -4, y = -2 },
    [defines.direction.eastnortheast]  = { x = -2, y = -4 },
    [defines.direction.eastsoutheast]  = { x =  2, y = -4 },
    [defines.direction.southsoutheast] = { x =  4, y = -2 },
    [defines.direction.southsouthwest] = { x =  4, y =  2 },
    [defines.direction.westsouthwest]  = { x =  2, y =  4 },
    [defines.direction.westnorthwest]  = { x = -2, y =  4 },
    [defines.direction.northnorthwest] = { x = -4, y =  2 },
}

RIGHT_TURN_EXTENSIONS = {
    before = {
        [defines.direction.north] = 1,
        [defines.direction.east] = 1,
        [defines.direction.south] = 1,
        [defines.direction.west] = 1,
    },
    after = {
        [defines.direction.north] = 1,
        [defines.direction.east] = 1,
        [defines.direction.south] = 1,
        [defines.direction.west] = 1,
        [defines.direction.northeast] = 1,
        [defines.direction.southwest] = 1,
        [defines.direction.northwest] = 1,
        [defines.direction.southeast] = 1,
    },
}

-- Corrections build off the end of the previous segment.
LEFT_TURN_CORRECTIONS = {
    [defines.direction.north] = {
        [1] = {
            debt = 0,
            rewinds = { TURN.STRAIGHT },
            extensions = { TURN.LEFT },
        },
        [2] = {
            debt = 0,
            rewinds = { },
            extensions = { TURN.LEFT },
        },
        [3] = {
            debt = 1,
            rewinds = { TURN.LEFT, TURN.LEFT, TURN.STRAIGHT },
            extensions = { TURN.LEFT, TURN.LEFT, TURN.STRAIGHT, TURN.LEFT },
        },
        [4] = {
            debt = 2,
            rewinds = { TURN.LEFT, TURN.STRAIGHT },
            extensions = { TURN.LEFT, TURN.LEFT, },
        },
    },
    [defines.direction.northeast] = {
        [1] = {
            debt = 0,
            rewinds = { TURN.STRAIGHT },
            extensions = { TURN.LEFT },
        },
        [2] = {
            debt = 1,
            rewinds = { },
            extensions = { TURN.LEFT },
        },
        [3] = {
            debt = 1,
            rewinds = { TURN.LEFT, TURN.LEFT, TURN.STRAIGHT },
            extensions = { TURN.LEFT, TURN.LEFT, TURN.STRAIGHT, TURN.LEFT },
        },
        [4] = {
            debt = 1,
            rewinds = { TURN.LEFT, TURN.STRAIGHT },
            extensions = { TURN.LEFT, TURN.LEFT },
        },
    },
    [defines.direction.northnortheast] = {
        [1] = {
            debt = 1,
            rewinds = { },
            extensions = { TURN.LEFT },
        },
        [2] = {
            debt = 1,
            rewinds = { TURN.LEFT, TURN.STRAIGHT },
            extensions = { TURN.LEFT, TURN.STRAIGHT, TURN.STRAIGHT, TURN.LEFT },
        },
        [3] = {
            debt = 1,
            rewinds = { TURN.LEFT, TURN.STRAIGHT },
            extensions = { TURN.LEFT, TURN.LEFT },
        },
        [4] = {
            debt = 1,
            rewinds = { TURN.LEFT, TURN.LEFT, TURN.STRAIGHT },
            extensions = { TURN.LEFT, TURN.LEFT, TURN.LEFT },
        },
    },
    [defines.direction.eastnortheast] = {
        [1] = {
            debt = 0,
            rewinds = { },
            extensions = { TURN.LEFT }
        },
        [2] = {
            debt = 1,
            rewinds = { TURN.LEFT, TURN.STRAIGHT },
            extensions = { TURN.LEFT, TURN.STRAIGHT, TURN.STRAIGHT, TURN.LEFT }
        },
        [3] = {
            debt = 2,
            rewinds = { TURN.LEFT, TURN.STRAIGHT },
            extensions = { TURN.LEFT, TURN.LEFT }
        },
        [4] = {
            debt = 1,
            rewinds = { TURN.LEFT, TURN.LEFT, TURN.STRAIGHT },
            extensions = { TURN.LEFT, TURN.LEFT, TURN.LEFT },
        },
    },
}

-- Programmatically populated based on paths.
-- Map of current direction -> desired direction -> { type, rotation, offset = {x, y}}
RAIL_TURN_MAP = {
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
PLANNER_PARTS = {}

for plannerName, planner in pairs(prototypes.get_item_filtered(
    {{ filter = "type", type = "rail-planner" }}
)) do
    local plannerConfig = {}
    PLANNER_PARTS[plannerName] = plannerConfig

    for _, rail in pairs(planner.rails) do
        plannerConfig[rail.type] = rail.name
    end
end