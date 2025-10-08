-- Interally, curved rails are just long diagonal straights.
local LENGTH_STRAIGHT = 2
local LENGTH_DIAGONAL = math.sqrt(8)
local LENGTH_HALF_DIAGONAL = math.sqrt(20)
local LENGTH_CURVE_A = math.sqrt(26)
local LENGTH_CURVE_B = 5
local LENGTH_RAMP = 16 -- guess, haven't checked.

-- This only has to respect direction because of straight rails.
--- @type { [RailCategory]: { [EntityDirection]: number } }
return {
    ["straight"] = {
        [defines.direction.north] = LENGTH_STRAIGHT,
        [defines.direction.east] = LENGTH_STRAIGHT,
        [defines.direction.northeast] = LENGTH_DIAGONAL,
        [defines.direction.southeast] = LENGTH_DIAGONAL,
    },
    ["half-diagonal"] = {
        [defines.direction.north] = LENGTH_HALF_DIAGONAL,
        [defines.direction.east] = LENGTH_HALF_DIAGONAL,
        [defines.direction.northeast] = LENGTH_HALF_DIAGONAL,
        [defines.direction.southeast] = LENGTH_HALF_DIAGONAL,
    },
    ["curved-a"] = {
        [defines.direction.north] = LENGTH_CURVE_A,
        [defines.direction.east] = LENGTH_CURVE_A,
        [defines.direction.south] = LENGTH_CURVE_A,
        [defines.direction.west] = LENGTH_CURVE_A,
        [defines.direction.northeast] = LENGTH_CURVE_A,
        [defines.direction.southeast] = LENGTH_CURVE_A,
        [defines.direction.southwest] = LENGTH_CURVE_A,
        [defines.direction.northwest] = LENGTH_CURVE_A,
    },
    ["curved-b"] = {
        [defines.direction.north] = LENGTH_CURVE_B,
        [defines.direction.east] = LENGTH_CURVE_B,
        [defines.direction.south] = LENGTH_CURVE_B,
        [defines.direction.west] = LENGTH_CURVE_B,
        [defines.direction.northeast] = LENGTH_CURVE_B,
        [defines.direction.southeast] = LENGTH_CURVE_B,
        [defines.direction.southwest] = LENGTH_CURVE_B,
        [defines.direction.northwest] = LENGTH_CURVE_B,
    },
    ["ramp"] = {
        [defines.direction.north] = LENGTH_RAMP,
        [defines.direction.east] = LENGTH_RAMP,
        [defines.direction.south] = LENGTH_RAMP,
        [defines.direction.west] = LENGTH_RAMP,
    },
}
