--- @alias EdgeSignal { [TrueDirection]: [Vector2d, Vector2d] }

--- @class BonusSignal
--- @field position Vector2d
--- @field signalDir TrueDirection
--- @field direction TrueDirection
--- @field includeLength boolean

--- @alias BonusSignals { [EntityDirection]: BonusSignal }

--- @type { edgeSignals: EdgeSignal[], bonusSignals: { [RailCategory]: BonusSignals } }
return {
    edgeSignals = {
        [defines.direction.north] = { { x =  1.5, y =  0.5 }, { x =  1.5, y = -0.5 } },
        [defines.direction.east] =  { { x = -0.5, y =  1.5 }, { x =  0.5, y =  1.5 } },
        [defines.direction.south] = { { x = -1.5, y = -0.5 }, { x = -1.5, y =  0.5 } },
        [defines.direction.west] =  { { x =  0.5, y = -1.5 }, { x = -0.5, y = -1.5 } },

        [defines.direction.northeast] = { { x =  0.5, y =  1.5 }, { x =  1.5, y =  0.5 } },
        [defines.direction.southeast] = { { x = -1.5, y =  0.5 }, { x = -0.5, y =  1.5 } },
        [defines.direction.southwest] = { { x = -0.5, y = -1.5 }, { x = -1.5, y = -0.5 } },
        [defines.direction.northwest] = { { x =  1.5, y = -0.5 }, { x =  0.5, y = -1.5 } },

        [defines.direction.northnortheast] = { { x =  0.5, y =  1.5 }, { x =  1.5, y = -0.5 } },
        [defines.direction.eastnortheast] =  { { x = -0.5, y =  1.5 }, { x =  1.5, y =  0.5 } },
        [defines.direction.eastsoutheast] =  { { x = -1.5, y =  0.5 }, { x =  0.5, y =  1.5 } },
        [defines.direction.southsoutheast] = { { x = -1.5, y = -0.5 }, { x = -0.5, y =  1.5 } },
        [defines.direction.southsouthwest] = { { x = -0.5, y = -1.5 }, { x = -1.5, y =  0.5 } },
        [defines.direction.westsouthwest] =  { { x =  0.5, y = -1.5 }, { x = -1.5, y = -0.5 } },
        [defines.direction.westnorthwest] =  { { x =  1.5, y = -0.5 }, { x = -0.5, y = -1.5 } },
        [defines.direction.northnorthwest] = { { x =  1.5, y =  0.5 }, { x =  0.5, y = -1.5 } },
    },
    -- why do curved B's have a bonus spot for signals.
    bonusSignals = {
        ["curved-b"] = {
            [defines.direction.north] = {
                position = { x =  0.5, y = -0.5 },
                signalDir = defines.direction.southsoutheast,
                direction = defines.direction.northnorthwest,
                includeLength = false,
            },
            [defines.direction.east]  = {
                position = { x =  0.5, y =  0.5 },
                signalDir = defines.direction.westsouthwest,
                direction = defines.direction.eastnortheast,
                includeLength = false,
            },
            [defines.direction.south] = {
                position = { x = -0.5, y =  0.5 },
                signalDir = defines.direction.northnorthwest,
                direction = defines.direction.southsoutheast,
                includeLength = false,
            },
            [defines.direction.west]  = {
                position = { x = -0.5, y = -0.5 },
                signalDir = defines.direction.eastnortheast,
                direction = defines.direction.westsouthwest,
                includeLength = false,
            },
            [defines.direction.northeast] = {
                position = { x = -0.5, y = -0.5 },
                signalDir = defines.direction.northnortheast,
                direction = defines.direction.southwest,
                includeLength = true,
            },
            [defines.direction.southeast] = {
                position = { x =  0.5, y = -0.5 },
                signalDir = defines.direction.eastsoutheast,
                direction = defines.direction.northwest,
                includeLength = true,
            },
            [defines.direction.southwest] = {
                position = { x =  0.5, y =  0.5 },
                signalDir = defines.direction.southsouthwest,
                direction = defines.direction.northeast,
                includeLength = true,
            },
            [defines.direction.northwest] = {
                position = { x = -0.5, y =  0.5 },
                signalDir = defines.direction.westnorthwest,
                direction = defines.direction.southeast,
                includeLength = true,
            },
        },
    },
}
