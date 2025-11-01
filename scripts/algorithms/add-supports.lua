local TYPE_TO_LAYER = require("scripts.rail-consts.raw.layer")
local LENGTH = require("scripts.rail-consts.raw.length")

local RailSegment = require("scripts.classes.rail-segment")

local function hasSupport(pointer)
    return Util.getEntityAt({
        type = "rail-support",
        direction = pointer.direction % 8,
        position = pointer.position,
        surface = pointer.surface,
    })
end

-- This isn't the best algorithm, as it may have edge cases around ramps that
-- aren't accounted for here. But maybe thisll work forever. who knows.
local function distanceSinceSupport(pointer, plannerInfo)
    if pointer.layer == defines.rail_layer.ground then return 0 end

    local maxDistance = plannerInfo.supportRange * 2
    local pathsToCheck = {{ pointer, 0 }}

    while #pathsToCheck > 0 do
        local pointer, distance = table.unpack(table.remove(pathsToCheck))

        -- Only continue down this branch if we haven't
        if distance < maxDistance then
            if hasSupport(pointer) then
                maxDistance = distance
            else
                for _, entity in pairs(RailSegment.getAllExistingFromPointer(pointer)) do
                    if entity.category == "ramp" then
                        -- This algorithm depends on all distances being in terms of the support's range.
                        maxDistance = math.max(maxDistance, distance + (plannerInfo.supportRange - plannerInfo.rampSupportRange))
                    else
                        local length = LENGTH[entity.category][entity.rotation]
                        local newDistance = distance + length

                        -- Correct for the fact that a segment cannot be partially supported by two supports.
                        if distance <= plannerInfo.supportRange and newDistance > plannerInfo.supportRange then
                            newDistance = plannerInfo.supportRange + length
                        end

                        table.insert(pathsToCheck, { entity.forward, newDistance })
                    end
                end
            end
        end
    end

    return maxDistance
end


--- Generates supports for the given path.
--- @param builder RailBuilder
return function(builder)
    if not builder.plannerInfo.supportName then return end

    local supportRange = builder.plannerInfo.supportRange
    local maxRange = supportRange * 2
    local currentDistance = distanceSinceSupport(builder.newPath.backward, builder.plannerInfo)

    -- I used to try to make the supports even, however i gave up. enjoy the ez algo.

    if currentDistance >= maxRange then
        table.insert(builder.entities, {
            type = builder.plannerInfo.supportName,
            position = builder.newPath.backward.position,
            direction = builder.newPath.backward.direction % 8
        })
        currentDistance = 0
    end

    for index, segment in ipairs(builder.newPath.segments) do
        local alignmentPoint = builder.alignmentPoints[index]

        local length = LENGTH[segment.category][segment.rotation]
        if currentDistance <= supportRange and currentDistance + length > supportRange then
            currentDistance = supportRange + length
        else
            currentDistance = currentDistance + length
        end

        if TYPE_TO_LAYER[segment.type] == defines.rail_layer.ground then
            currentDistance = 0
        elseif currentDistance > maxRange then
            table.insert(builder.entities, {
                type = builder.plannerInfo.supportName,
                position = segment.backward.position,
                direction = segment.backward.direction % 8
            })
            currentDistance = length
        elseif alignmentPoint and hasSupport(alignmentPoint.mainPoint) then
            table.insert(builder.entities, {
                type = builder.plannerInfo.supportName,
                position = segment.forward.position,
                direction = segment.forward.direction % 8
            })
            currentDistance = 0
        end
    end

    if currentDistance >= 4 and currentDistance > supportRange then
        table.insert(builder.entities, {
            type = builder.plannerInfo.supportName,
            position = builder.newPath.forward.position,
            direction = builder.newPath.forward.direction % 8
        })
    end
end
