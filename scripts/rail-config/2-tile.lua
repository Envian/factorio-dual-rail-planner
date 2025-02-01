local TURN = require("scripts.helpers.turn")

local OPPOSITE_OFFSET = {
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

local RIGHT_TURN_EXTENSIONS = {
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
local LEFT_TURN_CORRECTIONS = {
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

return {
    OPPOSITE_OFFSET = OPPOSITE_OFFSET,
    RIGHT_TURN_EXTENSIONS = RIGHT_TURN_EXTENSIONS,
    LEFT_TURN_CORRECTIONS = LEFT_TURN_CORRECTIONS,
}