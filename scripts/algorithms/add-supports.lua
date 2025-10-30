local TYPE_TO_CATEGORY = require("scripts.rail-consts.raw.type-to-category")
local LENGTH = require("scripts.rail-consts.raw.length")

local Helpers = require("scripts.helpers")
local RailSegment = require("scripts.classes.rail-segment")

local function hasSupport(pointer)
    return Helpers.getEntityAt({
        type = "rail-support",
        direction = pointer.direction % 8,
        position = pointer.position,
        surface = pointer.surface,
    })
end

local function getSupportValue(pointer, plannerInfo)
    if pointer.layer == defines.rail_layer.ground then return 0 end

    local maxSupport = -plannerInfo.supportRange
    local pathsToCheck = {{ pointer, plannerInfo.supportRange }}

    while #pathsToCheck > 0 do
        local pointer, support = table.unpack(table.remove(pathsToCheck))

        -- Don't continue if we won't find any useful paths.
        if support >= maxSupport then
            if hasSupport(pointer) then
                maxSupport = math.max(maxSupport, support)
            else
                for _, entity in pairs(RailSegment.getAllExistingFromPointer(pointer)) do
                    if entity.category == "ramp" then
                        maxSupport = math.max(maxSupport, support - (plannerInfo.supportRange - plannerInfo.rampSupportRange))
                    else
                        local newSupport = support - LENGTH[entity.category][entity.rotation]
                        if support > 0 and newSupport < 0 then
                            newSUpport = -LENGTH[entity.category][entity.rotation]
                        end

                        table.insert(pathsToCheck, { entity.forward, newSupport })
                    end
                end
            end
        end
    end

    return maxSupport
end

--- Generates supports for the given path.
--- @param builder RailBuilder
return function(builder)
    local rampRange =  builder.plannerInfo.rampSupportRange
    local supportRange = builder.plannerInfo.supportRange

    local currentSupport = getSupportValue(builder.newPath.backward, builder.plannerInfo)

    local indexesWithSupports = {}
    local doubleCheckIndecies = {}

    -- Phase 1: Find all parrallel supports from the main path
    for index, pointer in Helpers.edgeIter(builder.newPath) do
        if pointer.layer == defines.rail_layer.ground then
            -- Checking to see if we need a support before this ramp down.
            if currentSupport < -rampRange then
                table.insert(doubleCheckIndecies, { index - 1, rampRange })
            end

            -- when we're on the ground, just set the support value to whatever
            -- ramps use.
            currentSupport = rampRange
        else
            if builder.alignmentPoints[index] and hasSupport(builder.alignmentPoints[index].mainPoint) then
                -- The main path has a support so copy it.
                indexesWithSupports[index] = true
                table.insert(builder.entities, {
                    type = "rail-support",
                    position = pointer.position,
                    direction = pointer.direction % 8
                })

                if currentSupport < -supportRange then
                    table.insert(doubleCheckIndecies, { index, supportRange })
                end

                currentSupport = supportRange
            end


            local segment = builder.newPath.segments[index + 1]
            if segment then
                local length = LENGTH[TYPE_TO_CATEGORY[segment.type]][segment.rotation]
                if currentSupport > 0 and currentSupport - length < 0 then
                    currentSupport = -length
                else
                    currentSupport = currentSupport - length
                end
            end
        end
    end

    -- There's a rare edge case where a turn is fully supported on the main path
    -- but not fully supported on the opposite.
    if currentSupport < 0 then
        -- If we hit the end and need a support, add one
        indexesWithSupports[#builder.newPath.segments] = true
        table.insert(builder.entities, {
            type = "rail-support",
            position = builder.newPath.forward.position,
            direction = builder.newPath.forward.direction % 8
        })
        if currentSupport > supportRange then
            table.insert(doubleCheckIndecies, { #builder.newPath.segments, supportRange })
        end
    end

    -- Add custom supports where needed.
    for _, pointToCheck in pairs(doubleCheckIndecies) do
        -- Get the length of the segment, and log the distances we can add supports.
        local endIndex = pointToCheck[1]
        local lengthPoints = {}
        local distanceSinceSupport = 0
        local existingSupport = pointToCheck[2]
        local index = endIndex

        while index >= 1 do
            local segment = builder.newPath.segments[index]

            -- End when we get to a support.
            if indexesWithSupports[index - 1] then
                existingSupport = existingSupport + supportRange
                break
            elseif segment.type == "rail-ramp" then
                existingSupport = existingSupport + rampRange
                break
            end

            distanceSinceSupport = distanceSinceSupport + LENGTH[TYPE_TO_CATEGORY[segment.type]][segment.rotation]
            table.insert(lengthPoints, { distanceSinceSupport, segment.backward })
            index = index - 1
        end

        local supportsToBuild = math.ceil((distanceSinceSupport - existingSupport) / supportRange)
        local supportStep = distanceSinceSupport / (supportsToBuild + 1)

        for target = supportStep, distanceSinceSupport - supportStep, supportStep do
            local minScore = 100000 -- arbitrarily large.
            local minPoint = nil

            for _, option in pairs(lengthPoints) do
                local score = math.abs(target - option[1])
                if minScore > score then
                    minScore = score
                    minPoint = option[2]
                end
            end

            table.insert(builder.entities, {
                type = "rail-support",
                position = minPoint.position,
                direction = minPoint.direction % 8
            })
        end
    end
end
