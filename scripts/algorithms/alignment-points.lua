local DIRECTION_VECTORS = require("scripts.rail-consts.raw.direction-vectors")

local Vector2d = require("scripts.classes.vector")

local MARGIN_OF_ERROR = 0.0000001

local DIAGONAL_CORRECTIONS = {
    [defines.direction.northeast] = Vector2d:new(-1, 1),
    [defines.direction.southeast] = Vector2d:new( 1, 1),
    [defines.direction.southwest] = Vector2d:new( 1,-1),
    [defines.direction.northwest] = Vector2d:new(-1,-1),
    [defines.direction.northnortheast] = Vector2d:new( 0, 1),
    [defines.direction.eastnortheast]  = Vector2d:new( 1, 0),
    [defines.direction.eastsoutheast]  = Vector2d:new(-1, 0),
    [defines.direction.southsoutheast] = Vector2d:new( 0, 1),
    [defines.direction.southsouthwest] = Vector2d:new( 0,-1),
    [defines.direction.westsouthwest]  = Vector2d:new(-1, 0),
    [defines.direction.westnorthwest]  = Vector2d:new( 1, 0),
    [defines.direction.northnorthwest] = Vector2d:new( 0,-1),
}

local function closeToZero(val)
    return val < MARGIN_OF_ERROR and val > -MARGIN_OF_ERROR
end

local function getAlignment(newPointer, mainPointer)
    local offset = mainPointer.position - newPointer.position
    local directionVector = DIRECTION_VECTORS[(newPointer.direction + 4) % 16]
    local perpendicularDistance = offset:crossProduct(directionVector)

    -- If they're facing the same way, never correlate them
    if newPointer.direction ~= mainPointer.direction then
        return false, perpendicularDistance
    end

    if closeToZero(perpendicularDistance) then
        return true, 0
    end

    -- Diagonals have different offsets for odd numbered rail gaps
    if newPointer.direction % 4 > 0 then
        offset:move(DIAGONAL_CORRECTIONS[newPointer.direction])

        local newPerpendicularDistance = offset:crossProduct(directionVector)

        if closeToZero(newPerpendicularDistance) then
            return true, newPerpendicularDistance
        end
    end

    return false, perpendicularDistance
end

--- @alias AlignmentPoint { newIndex: number, mainIndex: number, newPoint: RailPointer, mainPoint: RailPointer }

--- Generates a map of alignment points between two paths.
--- @param newPath RailPath
--- @param mainPath RailPath
--- @return AlignmentPoint[]
return function(newPath, mainPath)
    local newIndex = 0
    local mainIndex = 0
    local newPointer = newPath.backward:createReverse()
    local mainPointer = mainPath.backward:createReverse()

    local results = {}

    while true do
        local isAligned, offset = getAlignment(newPointer, mainPointer)

        if isAligned then
            results[newIndex] = {
                newIndex = newIndex,
                mainIndex = mainIndex,
                newPoint = newPointer,
                mainPoint = mainPointer
            }
        end

        if offset >= 0 then
            if newIndex >= #newPath.segments then break end

            newIndex = newIndex + 1
            newPointer = newPath.segments[newIndex].forward
        else
            if mainIndex >= #mainPath.segments then break end

            mainIndex = mainIndex + 1
            mainPointer = mainPath.segments[mainIndex].forward
        end
    end

    return results
end
