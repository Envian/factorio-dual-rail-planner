local RailPointer = require("scripts.classes.rail-pointer")
local RailSegment = require("scripts.classes.rail-segment")
local TURN = require("scripts.helpers.turn")

local RailBuilder = {}
RailBuilder.__index = RailBuilder

-- { pointer, plannerName, player }
function RailBuilder.new(params)
    assert(getmetatable(params.pointer) == RailPointer)
    assert(type(params.plannerName) == "string")
    assert(params.player.object_name == "LuaPlayer")

    local builder = {}

    builder.pointer = params.pointer
    builder.plannerName = params.plannerName
    builder.player = params.player

    builder.leftsBuilt = 0
    builder.straightsBuilt = 0
    builder.history = {}

    setmetatable(builder, RailBuilder)
    return builder
end

function RailBuilder:extend(turnDirection)
    if turnDirection == TURN.STRAIGHT then
        self.straightsBuilt = self.straightsBuilt + 1

        -- Negative and zero here means there was a debt which was paid.
        if self.straightsBuilt > 0 then
            self:build(RailSegment.fromPointer(self.pointer, TURN.STRAIGHT))
        end

        if self.straightsBuilt >= 0 then
            self.leftsBuilt = 0
        end
    elseif turnDirection == TURN.RIGHT then
        local straightsToAdd = RIGHT_TURN_EXTENSIONS.before[self.pointer.direction] or 0

        -- If we come out of a left turn with straight debts, and we make a right turn too quickly, then
        -- we would need to rewind a while and rebuild the turn. This is not implemented yet.
        if straightsToAdd < -self.straightsBuilt then
            return false
        end

        for n = 1, straightsToAdd or 0 do
            self:extend(TURN.STRAIGHT)
        end

        self:build(RailSegment.fromPointer(self.pointer, TURN.RIGHT))

        self.leftsBuilt = 0
        self.straightsBuilt = 0

        for n = 1, RIGHT_TURN_EXTENSIONS.after[self.pointer.direction] or 0 do
            self:extend(TURN.STRAIGHT)
        end
    elseif turnDirection == TURN.LEFT then
        local leftTurnConfig = LEFT_TURN_CORRECTIONS[(self.pointer.direction + self.leftsBuilt) % 4]
        -- Used in the odd case where one of two (or more) straights were added, but not all that are needed.
        local debtDirection = self.pointer.direction

        self.leftsBuilt = self.leftsBuilt + 1
        leftTurnConfig = (leftTurnConfig or {})[self.leftsBuilt]

        if not leftTurnConfig then
            return false
        end

        for _, targetRewind in pairs(leftTurnConfig.rewinds) do
            -- Rewinds are reversed
            local railToRewind = RailSegment.fromPointer(self.pointer:createReverse(), targetRewind * -1)

            -- TODO: Rewinds can use history now instead of searching for rails.

            local rewoundRail = table.remove(self.history)
            if rewoundRail and rewoundRail.turn ~= targetRewind then
                table.insert(self.history, rewoundRail) -- Add it back so we can reference it later.
                return false
            end

            railToRewind:deconstruct(self.player)
            self.pointer = railToRewind.forward:createReverse()
        end

        for _, targetTurn in pairs(leftTurnConfig.extensions) do
            -- If the debt is partially paid, adjust here.
            if self.lastBuiltRail == TURN.STRAIGHT and self.straightsBuilt < 0 and self.pointer.direction == debtDirection then
                self:build(RailSegment.fromPointer(self.pointer, TURN.STRAIGHT))
            end

            self:build(RailSegment.fromPointer(self.pointer, targetTurn))
        end

        self.straightsBuilt = -leftTurnConfig.debt
    end

    return true
end

function RailBuilder:extendRamp()
    self:build(RailSegment.rampFromPointer(self.pointer))
    self.straightsBuilt = 0
    self.leftsBuilt = 0
    return true
end

function RailBuilder:cleanup()
    -- This is broken and wrong. move it to the manager
    if self.straightsBuilt < 0 then
        for n = 1, -self.straightsBuilt do
            self:build(TURN.STRAIGHT)
        end
    end
end

function RailBuilder:build(rail)
    rail:build(self.player, self.plannerName)

    table.insert(self.history, rail)
    if #self.history > RAIL_HISTORY_SIZE then
        table.remove(self.history, 1)
    end

    self.pointer = rail.forward
end

function RailBuilder:getRewind()
    local reverseExtensions = self.pointer:createReverse():getAllExtensions()
    local existingExtensions = filterForExistingSegments(reverseExtensions)

    -- Don't rewind if there are multiple options, or if its a ramp.
    if #existingExtensions > 1 or (existingExtensions[1] and existingExtensions[1].type == "rail-ramp") then
        return nil
    else
        -- Return the real reverse if it exists, otherwise return the first (straight)
        return existingExtensions[1] or reverseExtensions[1]
    end
end

script.register_metatable("RailBuilder", RailBuilder)
return RailBuilder