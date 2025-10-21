
local DIRECTION_VECTORS = require("scripts.rail-consts.raw.direction-vectors")
local TURN_DISTANCES = require("scripts.rail-consts.turn-distance")

local Turn = require("scripts.classes.turn")

local RailSegment = require("scripts.classes.rail-segment")
local RailPointer = require("scripts.classes.rail-pointer")

local MARGIN_OF_ERROR = 0.0000001

--- Floors this number with a fix for floating point arithmatic.
--- @param num number
--- @return number
local function integerize(num)
    return math.floor(num + MARGIN_OF_ERROR)
end

local function closeToZero(num)
    return num < MARGIN_OF_ERROR and num > -MARGIN_OF_ERROR
end

--- Finds a path to the goal
--- @param path RailPath
--- @param goal RailPointer
--- @param player LuaPlayer
--- @return number
return function(path, goal, player)
    local goalHeading = DIRECTION_VECTORS[goal.direction]
    local turns = Turn.normalize(goal.direction - path.forward.direction)

    -- Counted loop to prevent infinites.
    for _ = 1, 100 do
        local straightLength = TURN_DISTANCES[path.forward.direction][Turn.STRAIGHT]
        local currentHeading = DIRECTION_VECTORS[path.forward.direction]
        local offset = goal.position - path.forward.position
        local perpendicularDistance = offset:crossProduct(goalHeading)

        if turns == 0 then
            if not closeToZero(perpendicularDistance) then
                drpDebug({ "debug.s-bend-error" })
                if not DEBUG_MODE then
                    player.print({ "debug.s-bend-error" })
                end
                return -5
            else
                -- always add ramps first if necessary.
                if path.forward.layer ~= goal.layer then
                    if path.forward.direction % 4 ~= 0 then
                        drpDebug({ "debug.path-invalid-ramp" })
                        return -4
                    end

                    path:extendRamp()
                else
                    local segmentsToAdd = integerize(currentHeading:dotProduct(offset) / straightLength)

                    if segmentsToAdd >= 0 then
                        for _ = 1, segmentsToAdd do
                            path:extend(Turn.STRAIGHT)
                        end
                        return 0
                    elseif segmentsToAdd < 0 then
                        return -segmentsToAdd
                    end
                end
            end
        else
            -- More cross product magic.
            local rotationFactor = currentHeading:crossProduct(goalHeading)
            local currentTurn = turns > 0 and 1 or -1
            local turnSize = TURN_DISTANCES[path.forward.direction][turns]
            local straightDistance = perpendicularDistance / rotationFactor - turnSize

            -- Prevents infinite loops.
            assert(rotationFactor < -MARGIN_OF_ERROR or rotationFactor > MARGIN_OF_ERROR, "Turn algorithm invoked when straight.")

            -- This gets the distance to the intersection of the current and target line.
            if integerize(straightDistance) < 0 then
                -- Can't complete this turn, rewind and try again.
                local rewind = path:rewind()

                if rewind then
                    if rewind.type == "rail-ramp" then
                        drpError(player, { "debug.path-invalid-ramp" })
                        return -4
                    end
                    rewind:drawRewind(player)
                else
                    -- Can't simply rewind. Look backwards for existing rails to
                    local rewindables = RailSegment.getAllExistingFromPointer(path.backward)
                    local branches = RailSegment.getAllExistingFromPointer(path.backward:createReverse())

                    -- Look for an existing segment we can rip out.
                    if #rewindables == 1 and #branches == 0 then
                        rewind = rewindables[1]
                        if rewind.type == "rail-ramp" then
                            drpError(player, { "debug.path-invalid-ramp" })
                            return -4
                        end

                        if rewind.entity and rewind.entity.valid then
                            rewind.entity.order_deconstruction(player.force, player)
                        end
                        rewind:drawRewind(player)
                        rewind:reverse()

                        path.backward = rewind.backward
                        path.forward = path.backward:createReverse()
                    elseif #rewindables > 0 or #branches > 0 then
                        -- Don't rewind if we hit something.
                        drpDebug({ "debug.path-rewind-failed" })
                        return -2
                    else
                        -- Rewind with a fake straight if nothing else exists.
                        local straightsToRewind = integerize(straightDistance / straightLength)
                        path.forward = RailPointer:new({
                            direction = path.forward.direction,
                            layer = path.forward.layer,
                            surface = path.forward.surface,
                            position = path.forward.position + currentHeading * (straightsToRewind * -straightDistance),
                        })
                        path.backward = path.forward:createReverse()
                    end
                end

                if rewind then
                    turns = turns + rewind.turn
                end
            else
                -- Turning and can safely add the turn.
                local segmentsToAdd = integerize(straightDistance / straightLength)

                for _ = 1, segmentsToAdd do
                    path:extend(Turn.STRAIGHT)
                end

                path:extend(currentTurn)
                turns = turns - currentTurn
            end
        end

        if turns > 4 or turns < -4 then
            -- If we break out of the loop our turn is too steep.
            drpError(player, { "debug.path-too-sharp" })
            return -1
        end
    end

    drpDebug({ "debug.path-loop-break" })
    return -3
end
