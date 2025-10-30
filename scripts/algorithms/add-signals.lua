local LENGTHS = require("scripts.rail-consts.raw.length")
local SIGNALS = require("scripts.rail-consts.raw.signals")

local Turn = require("scripts.classes.turn")
local helpers = require("scripts.helpers")
local RailSegment = require("scripts.classes.rail-segment")

local function getSignal(pointer, offset)
    return helpers.getEntityAt({
        type = { "rail-signal", "rail-chain-signal" },
        surface = pointer.surface,
        position = pointer.position + offset,
        direction = pointer.direction,
        -- direction = (pointer.direction - 8) % 16, -- Signals are reversed
    })
end

local function getBonusSignal(segment, direction)
    if not SIGNALS.bonusSignals[segment.category] then
        return nil
    end
    local bonusSignal = SIGNALS.bonusSignals[segment.category][segment.rotation]

    if bonusSignal.direction == direction then
        return nil
    end

    -- Signals are configured assuming you're approaching them in their direction.
    -- This algorithm is backtracking, so we're looking for signals opposite of
    -- our direction of travel
    return helpers.getEntityAt({
        type = { "rail-signal", "rail-chain-signal" },
        surface = segment.surface,
        position = segment.position + bonusSignal.position,
        direction = bonusSignal.signalDir,
        --direction = (bonusSignal.signalDir - 8) % 16, -- Signals are reversed
    }), bonusSignal.includeLength and 0 or LENGTHS[segment.category][segment.rotation]
end

local function getDistanceSinceSignal(pointer, maxDistance)
    local distanceSinceSignal = 0

    -- Get how far its been since the last signal.
    while distanceSinceSignal < maxDistance do
        local signals = SIGNALS.edgeSignals[Turn.around(pointer.direction)]

        if getSignal(pointer, signals[1]) or getSignal(pointer, signals[2]) then
            return distanceSinceSignal
        end

        -- Get next entity
        local nextSegments = RailSegment.getAllExistingFromPointer(pointer)
        if #nextSegments == 0 then return distanceSinceSignal
        elseif #nextSegments > 1 then return maxDistance end

        -- Check bonus signals
        local signal, distanceToAdd = getBonusSignal(nextSegments[1], pointer.direction)
        if signal then return distanceSinceSignal + distanceToAdd end

        -- Advance Forward
        distanceSinceSignal = distanceSinceSignal + LENGTHS[nextSegments[1].category][nextSegments[1].rotation]
        pointer = nextSegments[1].forward
    end

    return maxDistance
end

--- comment
--- @param builder RailBuilder
--- @param alignmentPoint AlignmentPoint
--- @return boolean
local function canBuildSignals(builder, alignmentPoint)
    -- Don't build if we're at the end of a path
    if alignmentPoint.newIndex == #builder.newPath.segments then return false end
    -- Doesn't seem like it matters
    -- if alignmentPoint.mainIndex == 0 then return false end

    -- Don't build if we'd end up attaching to a rail ramp
    local entity = builder.newPath.segments[alignmentPoint.newIndex + 1]
    if entity and entity.category == "ramp" then return false end

    entity = builder.mainPath.segments[alignmentPoint.mainIndex]
    if entity and entity.category == "ramp" then return false end

    return true
end

--- Adds signal entities
--- @param builder RailBuilder
return function(builder)
    -- We can only place signals on aligned points.
    if #builder.alignmentPoints == 0 then return end
    if not settings.get_player_settings(builder.player)["signals-enabled"].value then return end

    local minSignalDistance = settings.get_player_settings(builder.player)["signals-distance"].value

    local mainIndex = 0
    local newIndex = 0
    local mainDistanceSince = getDistanceSinceSignal(builder.mainPath.backward, minSignalDistance)
    local newDistanceSince = getDistanceSinceSignal(builder.newPath.backward, minSignalDistance)

    -- Special iter needed so 0 is called first.
    for _, alignmentPoint in helpers.alignmentIterator(builder.alignmentPoints) do
        -- Advance both sides and count distance.
        while mainIndex < alignmentPoint.mainIndex do
            mainIndex = mainIndex + 1
            local segment = builder.mainPath.segments[mainIndex]
            mainDistanceSince = mainDistanceSince + LENGTHS[segment.category][segment.rotation]
        end
        while newIndex < alignmentPoint.newIndex do
            newIndex = newIndex + 1
            local segment = builder.newPath.segments[newIndex]
            newDistanceSince = newDistanceSince + LENGTHS[segment.category][segment.rotation]
        end


        -- If its been far enough on both paths, place a signal.
        if  mainDistanceSince >= minSignalDistance and
            newDistanceSince >= minSignalDistance and
            canBuildSignals(builder, alignmentPoint)
        then
            mainDistanceSince = 0
            newDistanceSince = 0

            table.insert(builder.entities, {
                type = "rail-signal",
                rail_layer = alignmentPoint.mainPoint.layer,
                position = alignmentPoint.mainPoint.position + SIGNALS.edgeSignals[alignmentPoint.mainPoint.direction][1],
                direction = Turn.around(alignmentPoint.mainPoint.direction)
            })
            table.insert(builder.entities, {
                type = "rail-signal",
                rail_layer = alignmentPoint.newPoint.layer,
                position = alignmentPoint.newPoint.position + SIGNALS.edgeSignals[Turn.around(alignmentPoint.newPoint.direction)][1],
                direction = alignmentPoint.newPoint.direction
            })
        end
    end
end
