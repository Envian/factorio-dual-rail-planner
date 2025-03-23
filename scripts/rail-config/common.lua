local TURN = require("scripts.helpers.turn")

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

local LENGTH_STRAIGHT = 2
local LENGTH_DIAGONAL = 2 * math.sqrt(2)
local LENGTH_HALF_DIAGONAL = math.sqrt(20)
local LENGTH_RAMP = 16 -- guess, haven't checked.

-- If it was based on arc length, then we'd use 13*pi/8 for both, but instead
-- they used the linear length between the start and end.
local LENGTH_CURVE_A = math.sqrt(26)
local LENGTH_CURVE_B = 5

local RAIL_PATH_CONFIG = {
    ["straight"] = {
        category = "straight",
        type = {
            [defines.rail_layer.ground] = "straight-rail",
            [defines.rail_layer.elevated] = "elevated-straight-rail",
        },
        length = {
            [defines.direction.north] = LENGTH_STRAIGHT,
            [defines.direction.east] = LENGTH_STRAIGHT,
            [defines.direction.northeast] = LENGTH_DIAGONAL,
            [defines.direction.southeast] = LENGTH_DIAGONAL,
        },
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
        category = "half-diagonal",
        type = {
            [defines.rail_layer.ground] = "half-diagonal-rail",
            [defines.rail_layer.elevated] = "elevated-half-diagonal-rail",
        },
        length = {
            [defines.direction.north] = LENGTH_HALF_DIAGONAL,
            [defines.direction.east] = LENGTH_HALF_DIAGONAL,
            [defines.direction.northeast] = LENGTH_HALF_DIAGONAL,
            [defines.direction.southeast] = LENGTH_HALF_DIAGONAL,
        },
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
        category = "curved-a",
        type = {
            [defines.rail_layer.ground] = "curved-rail-a",
            [defines.rail_layer.elevated] = "elevated-curved-rail-a",
        },
        length = {
            [defines.direction.north] = LENGTH_CURVE_A,
            [defines.direction.east] = LENGTH_CURVE_A,
            [defines.direction.south] = LENGTH_CURVE_A,
            [defines.direction.west] = LENGTH_CURVE_A,
            [defines.direction.northeast] = LENGTH_CURVE_A,
            [defines.direction.southeast] = LENGTH_CURVE_A,
            [defines.direction.southwest] = LENGTH_CURVE_A,
            [defines.direction.northwest] = LENGTH_CURVE_A,
        },
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
        category = "curved-b",
        type = {
            [defines.rail_layer.ground] = "curved-rail-b",
            [defines.rail_layer.elevated] = "elevated-curved-rail-b",
        },
        length = {
            [defines.direction.north] = LENGTH_CURVE_B,
            [defines.direction.east] = LENGTH_CURVE_B,
            [defines.direction.south] = LENGTH_CURVE_B,
            [defines.direction.west] = LENGTH_CURVE_B,
            [defines.direction.northeast] = LENGTH_CURVE_B,
            [defines.direction.southeast] = LENGTH_CURVE_B,
            [defines.direction.southwest] = LENGTH_CURVE_B,
            [defines.direction.northwest] = LENGTH_CURVE_B,
        },
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
        category = "ramp",
        type = {
            [defines.rail_layer.ground] = "rail-ramp",
            [defines.rail_layer.elevated] = "rail-ramp",
        },
        length = {
            [defines.direction.north] = LENGTH_RAMP,
            [defines.direction.east] = LENGTH_RAMP,
            [defines.direction.south] = LENGTH_RAMP,
            [defines.direction.west] = LENGTH_RAMP,
        },
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

local RAIL_SIGNAL_POSITIONS = {
    [defines.direction.north] = { forward = { x =  1.5, y =  0.5 }, backward = { x = -1.5, y =  0.5 } },
    [defines.direction.east]  = { forward = { x = -0.5, y =  1.5 }, backward = { x = -0.5, y = -1.5 } },
    [defines.direction.south] = { forward = { x = -1.5, y = -0.5 }, backward = { x =  1.5, y = -0.5 } },
    [defines.direction.west]  = { forward = { x =  0.5, y = -1.5 }, backward = { x =  0.5, y =  1.5 } },

    [defines.direction.northeast] = { forward = { x =  0.5, y =  1.5 }, backward = { x = -1.5, y = -0.5 } },
    [defines.direction.southeast] = { forward = { x = -1.5, y =  0.5 }, backward = { x =  0.5, y = -1.5 } },
    [defines.direction.southwest] = { forward = { x = -0.5, y = -1.5 }, backward = { x =  1.5, y =  0.5 } },
    [defines.direction.northwest] = { forward = { x =  1.5, y = -0.5 }, backward = { x = -0.5, y =  1.5 } },

    [defines.direction.northnortheast] = { forward = { x =  0.5, y =  1.5 }, backward = { x = -1.5, y =  0.5 } },
    [defines.direction.eastnortheast]  = { forward = { x = -0.5, y =  1.5 }, backward = { x = -1.5, y = -0.5 } },
    [defines.direction.eastsoutheast]  = { forward = { x = -1.5, y =  0.5 }, backward = { x = -0.5, y = -1.5 } },
    [defines.direction.southsoutheast] = { forward = { x = -1.5, y = -0.5 }, backward = { x =  0.5, y = -1.5 } },
    [defines.direction.southsouthwest] = { forward = { x = -0.5, y = -1.5 }, backward = { x =  1.5, y = -0.5 } },
    [defines.direction.westsouthwest]  = { forward = { x =  0.5, y = -1.5 }, backward = { x =  1.5, y =  0.5 } },
    [defines.direction.westnorthwest]  = { forward = { x =  1.5, y = -0.5 }, backward = { x =  0.5, y =  1.5 } },
    [defines.direction.northnorthwest] = { forward = { x =  1.5, y =  0.5 }, backward = { x = -0.5, y =  1.5 } },
}

local BLUEPRINT_OFFSETS = {
    ["straight-rail"] = {
        [defines.direction.north] = { min = {x = -1, y = -1}, max = {x = 1, y = 1} },
        [defines.direction.east]  = { min = {x = -1, y = -1}, max = {x = 1, y = 1} },
        [defines.direction.northeast] = { min = {x = -2, y = -2}, max = {x = 2, y = 2} },
        [defines.direction.southeast] = { min = {x = -2, y = -2}, max = {x = 2, y = 2} },
    },
    ["half-diagonal-rail"] = {
        [defines.direction.north] = { min = {x = -1, y = -1}, max = {x = 1, y = 1} },
        [defines.direction.east]  = { min = {x = -1, y = -1}, max = {x = 1, y = 1} },
        [defines.direction.northeast] = { min = {x = -1, y = -1}, max = {x = 1, y = 1} },
        [defines.direction.southeast] = { min = {x = -1, y = -1}, max = {x = 1, y = 1} },
    },
    ["curved-rail-a"] = {
        [defines.direction.north] = { min = {x = -1, y = -2}, max = {x = 1, y = 2} },
        [defines.direction.east]  = { min = {x = -2, y = -1}, max = {x = 2, y = 1} },
        [defines.direction.south] = { min = {x = -1, y = -2}, max = {x = 1, y = 2} },
        [defines.direction.west]  = { min = {x = -2, y = -1}, max = {x = 2, y = 1} },
        [defines.direction.northeast] = { min = {x = -1, y = -2}, max = {x = 1, y = 2} },
        [defines.direction.southeast] = { min = {x = -2, y = -1}, max = {x = 2, y = 1} },
        [defines.direction.southwest] = { min = {x = -1, y = -2}, max = {x = 1, y = 2} },
        [defines.direction.northwest] = { min = {x = -2, y = -1}, max = {x = 2, y = 1} },
    },
    ["curved-rail-b"] = {
        [defines.direction.north] = { min = {x = -1, y = -1}, max = {x = 1, y = 1} },
        [defines.direction.east]  = { min = {x = -1, y = -1}, max = {x = 1, y = 1} },
        [defines.direction.south] = { min = {x = -1, y = -1}, max = {x = 1, y = 1} },
        [defines.direction.west]  = { min = {x = -1, y = -1}, max = {x = 1, y = 1} },
        [defines.direction.northeast] = { min = {x = -1, y = -1}, max = {x = 1, y = 1} },
        [defines.direction.southeast] = { min = {x = -1, y = -1}, max = {x = 1, y = 1} },
        [defines.direction.southwest] = { min = {x = -1, y = -1}, max = {x = 1, y = 1} },
        [defines.direction.northwest] = { min = {x = -1, y = -1}, max = {x = 1, y = 1} },
    },
    ["rail-ramp"] = {
        [defines.direction.north] = { min = {x = -1, y = -8}, max = {x = 1, y = 8} },
        [defines.direction.east]  = { min = {x = -8, y = -1}, max = {x = 8, y = 1} },
        [defines.direction.south] = { min = {x = -1, y = -8}, max = {x = 1, y = 8} },
        [defines.direction.west]  = { min = {x = -8, y = -1}, max = {x = 8, y = 1} },
    },
    ["rail-support"] = {
        [defines.direction.north] = { min = {x = -3, y = -2}, max = {x = 1, y = 2} },
        [defines.direction.east]  = { min = {x = -2, y = -3}, max = {x = 2, y = 1} },
        [defines.direction.northeast] = { min = {x = -3, y = -3}, max = {x = 1, y = 1} },
        [defines.direction.southeast] = { min = {x = -3, y = -3}, max = {x = 1, y = 1} },
        [defines.direction.northnortheast] = { min = {x = -2, y = -3}, max = {x = 2, y = 1} },
        [defines.direction.eastnortheast]  = { min = {x = -3, y = -2}, max = {x = 1, y = 2} },
        [defines.direction.eastsoutheast]  = { min = {x = -3, y = -2}, max = {x = 1, y = 2} },
        [defines.direction.southsoutheast] = { min = {x = -2, y = -3}, max = {x = 2, y = 1} },
    },
}

BLUEPRINT_OFFSETS["elevated-straight-rail"] = BLUEPRINT_OFFSETS["straight-rail"]
BLUEPRINT_OFFSETS["elevated-half-diagonal-rail"] = BLUEPRINT_OFFSETS["half-diagonal-rail"]
BLUEPRINT_OFFSETS["elevated-curved-rail-a"] = BLUEPRINT_OFFSETS["curved-rail-a"]
BLUEPRINT_OFFSETS["elevated-curved-rail-b"] = BLUEPRINT_OFFSETS["curved-rail-b"]


-- Programmatically populated based on paths.
-- Map of current direction -> desired direction -> { category, rotation, offset = {x, y}}
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

local RAIL_TYPE_CONFIG = {}

for category, config in pairs(RAIL_PATH_CONFIG) do
    RAIL_TYPE_CONFIG[config.type[defines.rail_layer.ground]] = config
    RAIL_TYPE_CONFIG[config.type[defines.rail_layer.elevated]] = config

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
    RAIL_TYPE_CONFIG = RAIL_TYPE_CONFIG,
    TYPE_TO_LAYER = TYPE_TO_LAYER,
    RAIL_PATH_CONFIG = RAIL_PATH_CONFIG,
    RAIL_TURN_MAP = RAIL_TURN_MAP,
    PLANNER_PARTS = PLANNER_PARTS,
    RAIL_SIGNAL_POSITIONS = RAIL_SIGNAL_POSITIONS,
    BLUEPRINT_OFFSETS = BLUEPRINT_OFFSETS,
    SPACING = {
        ["2-tile"] = require("scripts.rail-config.2-tile"),
    }
}
