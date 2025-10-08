-- Aggregates all info from the `raw` folder into a collection

--- @type { [RailCategory]: EntityDirection[] }
local ALL_CATEGORIES_AND_DIRECTIONS = {
    ["straight"] = {
        defines.direction.north,
        defines.direction.northeast,
        defines.direction.east,
        defines.direction.southeast,
    },
    ["half-diagonal"] = {
        defines.direction.north,
        defines.direction.northeast,
        defines.direction.east,
        defines.direction.southeast,
    },
    ["curved-a"] = {
        defines.direction.north,
        defines.direction.northeast,
        defines.direction.east,
        defines.direction.southeast,
        defines.direction.south,
        defines.direction.southwest,
        defines.direction.west,
        defines.direction.northwest,
    },
    ["curved-b"] = {
        defines.direction.north,
        defines.direction.northeast,
        defines.direction.east,
        defines.direction.southeast,
        defines.direction.south,
        defines.direction.southwest,
        defines.direction.west,
        defines.direction.northwest,
    },
    ["ramp"] = {
        defines.direction.north,
        defines.direction.east,
        defines.direction.south,
        defines.direction.west,
    },
}

local GROUND_TYPES = {
    ["straight-rail"] = "straight",
    ["half-diagonal-rail"] = "half-diagonal",
    ["curved-rail-a"] = "curved-a",
    ["curved-rail-b"] = "curved-b",
    ["rail-ramp"] = "ramp",
}

local EDGES = require("scripts.rail-consts.raw.edges")
local LENGTH = require("scripts.rail-consts.raw.length")

--- @class RailCategoryConsts
--- @field edges [defines.direction, defines.direction]
--- @field category RailCategory
--- @field length number

--- @type { [RailCategory]: { [EntityDirection]: RailCategoryConsts } }
local BY_TYPE = {}

for type, category in pairs(GROUND_TYPES) do
    local cConsts = {}
    BY_TYPE[type] = cConsts

    for _, rotation in ipairs(ALL_CATEGORIES_AND_DIRECTIONS[category]) do
        cConsts[rotation] = {
            edges = EDGES[category][rotation],
            length = LENGTH[category][rotation],
        }
    end
end

BY_TYPE["elevated-straight-rail"] = BY_TYPE["straight-rail"]
BY_TYPE["elevated-half-diagonal-rail"] = BY_TYPE["half-diagonal-rail"]
BY_TYPE["elevated-curved-rail-a"] = BY_TYPE["curved-rail-a"]
BY_TYPE["elevated-curved-rail-b"] = BY_TYPE["curved-rail-b"]

return BY_TYPE
