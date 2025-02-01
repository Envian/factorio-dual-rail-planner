local RAILDEFS = require("scripts.rail-config.common")

local position = require("scripts.helpers.position")
local TURN = require("scripts.helpers.turn")

local RailPointer = require("scripts.classes.rail-pointer")
local RailSegment = require("scripts.classes.rail-segment")

local RailBuilder = {}
RailBuilder.__index = RailBuilder

function RailBuilder.new(rail, spacing)
    assert(getmetatable(rail) == RailSegment)

    local builder = {}
    local originDirection = TURN.around(rail.backward.direction)

    builder.spacing = spacing
    builder.mainPointer = rail.forward
    builder.oppositePointer = RailPointer.new({
        position = position.add(rail.backward.position, RAILDEFS.SPACING[spacing].OPPOSITE_OFFSET[originDirection]),
        direction = originDirection,
        layer = rail.backward.layer,
        surface = rail.forward.surface,
    })

    builder.buildQueue = {}
    builder.deconstructionQueue = {}
    builder.leftsBuilt = 0
    builder.straightsBuilt = 0

    setmetatable(builder, RailBuilder)
    return builder
end

function RailBuilder:handleExtension(segment)
    -- Ramps don't have a turn, handle specially.
    if segment.type == "rail-ramp" then
        if self:isAligned() then
            self:queueBuild(RailSegment.rampFromPointer(self.oppositePointer))
        else
            -- Cannot extend a ramp if the builder is not aligned.
            return false
        end
    else
        local success = self:extend(segment.turn)
        if success then self.mainPointer = segment.forward end
        return success
    end
end

function RailBuilder:extend(turnDirection)
    local SPACING = RAILDEFS.SPACING[self.spacing]

    if turnDirection == TURN.STRAIGHT then
        self.straightsBuilt = self.straightsBuilt + 1

        -- Negative and zero here means there was a debt which was paid.
        if self.straightsBuilt > 0 then
            self:queueBuild(RailSegment.fromPointer(self.oppositePointer, TURN.STRAIGHT))
        end

        if self.straightsBuilt >= 0 then
            self.leftsBuilt = 0
        end
    elseif turnDirection == TURN.RIGHT then
        local straightsToAdd = SPACING.RIGHT_TURN_EXTENSIONS.before[self.oppositePointer.direction] or 0

        -- TODO: We can probably just do this, and check if there's debt after.
        -- If we come out of a left turn with straight debts, and we make a right turn too quickly, then
        -- we would need to rewind a while and rebuild the turn. This is not implemented yet.
        if straightsToAdd < -self.straightsBuilt then
            return false
        end

        for n = 1, straightsToAdd do
            self:extend(TURN.STRAIGHT)
        end

        self:queueBuild(RailSegment.fromPointer(self.oppositePointer, TURN.RIGHT))

        self.leftsBuilt = 0
        self.straightsBuilt = 0

        for n = 1, SPACING.RIGHT_TURN_EXTENSIONS.after[self.oppositePointer.direction] or 0 do
            self:extend(TURN.STRAIGHT)
        end
    elseif turnDirection == TURN.LEFT then
        local leftTurnConfig = SPACING.LEFT_TURN_CORRECTIONS[(self.oppositePointer.direction + self.leftsBuilt) % 4]
        -- Used in the odd case where one of two (or more) straights were added, but not all that are needed.
        self.leftsBuilt = self.leftsBuilt + 1
        leftTurnConfig = (leftTurnConfig or {})[self.leftsBuilt]

        if not leftTurnConfig then
            return false
        end

        for _, targetRewind in pairs(leftTurnConfig.rewinds) do
            local railRewound = self:getRewind(targetRewind)

            -- Get rewind returns one of the following:
            -- 1. the last segment from the build queue
            -- 2. a rail (real or otherwise) connected to the back of the current pointer.
            -- 3. nil if something has gone wrong
            if not railRewound or railRewound.turn ~= targetRewind then
                return false
            end

            self.oppositePointer = railRewound.backward:createReverse()
        end

        for _, targetTurn in pairs(leftTurnConfig.extensions) do
            self:queueBuild(RailSegment.fromPointer(self.oppositePointer, targetTurn))
        end

        self.straightsBuilt = -leftTurnConfig.debt
    end

    return true
end

function RailBuilder:finalize()
    if self.straightsBuilt < 0 then
        for n = 1, -self.straightsBuilt do
            local segment = RailSegment.fromPointer(self.mainPointer, TURN.STRAIGHT)
            table.insert(self.buildQueue, segment)
            self.mainPointer = segment.forward
        end
    end
    self.straightsBuilt = 0
end

function RailBuilder:queueBuild(segment)
    table.insert(self.buildQueue, segment)
    self.oppositePointer = segment.forward
end

function RailBuilder:isAligned()
    local expectedPointer = RailPointer.new({
        position = position.add(self.mainPointer.position, RAILDEFS.SPACING[self.spacing].OPPOSITE_OFFSET[originDirection]),
        direction = originDirection,
        layer = self.mainPointer.layer,
        surface = self.mainPointer.surface,
    })
    return expectedPointer == self.oppositePointer
end

function RailBuilder:getRewind(preferredTurn)
    if #self.buildQueue > 0 then
        return table.remove(self.buildQueue)
    else
        -- No build queue, so rewind using real rails if available
        local reversePointer = self.oppositePointer:createReverse()
        local existingExtensions = RailSegment.getAllExistingFromPointer(reversePointer)

        if #existingExtensions == 0 then
            -- Return the rewind that the caller asked for
            local segment = RailSegment.fromPointer(reversePointer, preferredTurn * -1)
            segment:reverse()
            return segment
        elseif #existingExtensions == 1 and existingExtensions[1].type ~= "rail-ramp" then
            table.insert(self.deconstructionQueue, existingExtensions[1])
            existingExtensions[1]:reverse()
            return existingExtensions[1]
        else
            -- Don't rewind if there are multiple options, or if its a ramp.
            return nil
        end
    end
end

function RailBuilder:build(player, plannerName)
    -- Start with deconstructions.
    for _, segment in pairs(self.deconstructionQueue) do
        local entity = segment:getEntity()
        if entity and entity.valid then
            entity.order_deconstruction(player.force, player, 1)
        end
    end
    self.deconstructionQueue = {}

    -- Next, build - but only if we have something.
    if #self.buildQueue == 0 then return end

    local currentGhost = player.cursor_ghost

    player.cursor_stack.set_stack("blueprint")
    player.cursor_stack_temporary = true

    local blueprintEntities = {}
    local min = {x = self.buildQueue[1].position.x, y = self.buildQueue[1].position.y}
    local max = {x = self.buildQueue[1].position.x, y = self.buildQueue[1].position.y}

    for index, segment in pairs(self.buildQueue) do
        table.insert(blueprintEntities, {
            entity_number = index,
            name = RAILDEFS.PLANNER_PARTS[plannerName][segment.type],
            position = segment.position,
            direction = segment.rotation,
        })
        -- Blueprints are always centered around the mid point.
        if segment.position.x < min.x then min.x = segment.position.x end
        if segment.position.y < min.y then min.y = segment.position.y end
        if segment.position.x > max.x then max.x = segment.position.x end
        if segment.position.y > max.y then max.y = segment.position.y end
    end

    local offset = {
        x = (min.x + max.x) / 2 - self.buildQueue[1].position.x,
        y = (min.y + max.y) / 2 - self.buildQueue[1].position.y,
    }

    player.cursor_stack.set_blueprint_entities(blueprintEntities)
    player.build_from_cursor({
        position = {
            x = self.buildQueue[1].position.x + offset.x,
            y = self.buildQueue[1].position.y + offset.y,
        },
        direction = defines.direction.north,
        build_mode = defines.build_mode.superforced,
        skip_fog_of_war = false,
    })

    player.clear_cursor()
    player.cursor_ghost = currentGhost
    self.buildQueue = {}
end

script.register_metatable("RailBuilder", RailBuilder)
return RailBuilder