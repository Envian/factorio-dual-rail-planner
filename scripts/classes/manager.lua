local RAILDEFS = require("scripts.rail-config.common")
local const = require("scripts.constants")

local TURN = require("scripts.helpers.turn")
local position = require("scripts.helpers.position")
local delay = require("scripts.helpers.delay")

local RailPointer = require("scripts.classes.rail-pointer")
local RailSegment = require("scripts.classes.rail-segment")
local RailBuilder = require("scripts.classes.rail-builder")

local Manager = {}
Manager.__index = Manager

local STATE = {
    DISABLED = 0,
    INACTIVE = 1,
    BUILDING = 2,
    ABORTING = 3,
}
Manager.STATE = STATE

function Manager.new(player)
    local manager = {}
    setmetatable(manager, Manager)

    manager.player = player
    manager.state = STATE.DISABLED
    manager.plannerName = nil
    manager.builder = nil
    manager.alerts = {}

    manager.lastRail = nil
    manager.deconstructedEntities = nil
    manager.builtEntities = nil

    return manager
end

function Manager:enable(plannerName)
    self.player.set_shortcut_toggled(const.SHORTCUT_PREFIX .. plannerName, true)

    self.state = STATE.INACTIVE
    self.plannerName = plannerName
    self.player.clear_cursor()
    self.player.cursor_ghost = plannerName
    self.deconstructedEntities = {}
    self.builtEntities = {}
end

function Manager:disable()
    self.player.set_shortcut_toggled(const.SHORTCUT_PREFIX .. self.plannerName, false)

    if self.builder then self.builder:finalize() end

    self.state = STATE.DISABLED
    self.plannerName = plannerName
    self.builder = nil
    self.lastRail = nil
    self.deconstructedEntities = nil
    self.builtEntities = nil
end

function Manager:togglePlanner(plannerName)
    if self.state == STATE.INACTIVE then
        self:disable()
        self.player.clear_cursor()
    elseif self.state == STATE.DISABLED then
        self:enable(plannerName)
    end
end

function Manager:checkCursor()
    if self.state == STATE.DISABLED or self.state == STATE.ABORTING then return end

    -- Check if we're still using the same planner.
    if not self.player.cursor_ghost or self.player.cursor_ghost.name.name ~= self.plannerName then
        self:disable()
    end
end

function Manager:entityBuilt(event)
    if self.state == STATE.DISABLED then return end

    if self.state == STATE.ABORTING then
        event.entity.order_deconstruction(self.player.force)
        return
    end

    -- Track all the entities involved in the upcoming "rail"
    table.insert(self.builtEntities, event.entity)

    if event.entity.type == "rail-support"
    or event.entity.ghost_type == "rail-support"
    or event.entity.name == "tile-ghost"
    then
        -- We only track these things so we can abort them
        return
    end

    local segment = RailSegment.fromEntity(event.entity)

    -- Will need two discrete branches - elevated and regular.
    if RAILDEFS.TYPE_TO_LAYER[segment.type] == defines.rail_layer.ground then
        self:handleGround(segment)
    else
        self:handleElevated(segment)
    end

    -- After a rail is built, reset the supporting components.
    self.deconstructedEntities = {}
    self.builtEntities = {}
    self.lastRail = segment
end

function Manager:handleGround(segment)
    if self.lastRail then
        -- Align the segments. If a builder is active, only align the new one. Otherwise align both
        if self.builder then self.lastRail:alignOther(segment)
        else self.lastRail:alignSegments(segment) end

        if self.lastRail:connectedTo(segment) then
            -- Scenario 1a: The player placed two rails, the 2nd connected to the 1st.
            if not self.builder then
                self.builder = RailBuilder.new(self.lastRail, "2-tile")
                self:extend(self.lastRail)
            end
            self:extend(segment)
            return
        else
            -- Scenario 1b: The player placed a followup rail, but it is not connected.
            if self.builder then
                -- TODO: How do we finalize here?
                -- self.builder:finalize()
                self.builder = nil
            end
        end
    end

    -- Scenario 2: A rail was placed, but it either is not connected to the
    -- previous rail, or there was no previous rail. We can extend if its built off an existing rail.
    local forwardExtensions = RailSegment.getAllExistingFromPointer(segment.forward)
    local backwardExtensions = RailSegment.getAllExistingFromPointer(segment.backward)

    if #forwardExtensions == 1 and #backwardExtensions == 0 then
        segment:reverse()
        forwardExtensions, backwardExtensions = backwardExtensions, forwardExtensions
    end

    if #forwardExtensions == 0 and #backwardExtensions == 1 then
        self.builder = RailBuilder.new(segment, "2-tile")
        self:extend(segment)
    end
end

function Manager:handleElevated(segment)
    -- TODO: Build the elevated rail algorithm
end

function Manager:extend(segment)
    if self.state == STATE.INACTIVE then
        self.state = STATE.BUILDING
        delay(0, function()
            local initialState = self.state

            if self.builder then
                self.state = STATE.DISABLED
                self.builder:build(self.player, self.plannerName)
                self.state = STATE.INACTIVE
            end

            if initialState == STATE.ABORTING then
                self.builder = nil
                self.player.clear_cursor()
                self.player.cursor_ghost = self.plannerName
            end
        end)
    end

    if not self.builder:handleExtension(segment) then
        self.player.print("[Dual Rail Planner] Could not complete the turn.")
        -- TODO: Add support for both abort and notify mode.

        -- Abort whatever the player last built.
        for _, entity in pairs(self.deconstructedEntities) do
            if entity and entity.valid then
                entity.cancel_deconstruction(self.player.force)
            end
        end

        for _, entity in pairs(self.builtEntities) do
            if entity and entity.valid then
                entity.order_deconstruction(self.player.force)
            end
        end

        self.deconstructedEntities = {}
        self.builtEntities = {}

        -- Build what we can.
        self.builder:finalize()
        self.state = STATE.ABORTING

        -- Clears the cursor and resets the user's planner.
        self.player.cursor_stack.set_stack("blueprint")
        self.player.cursor_stack_temporary = true
    end
end

function Manager:entityDeconstructed(event)
    if state == STATE.DISABLED then
        return
    elseif self.state == STATE.ABORTING then
        event.entity.cancel_deconstruction(self.player.force)
        return
    else
        table.insert(self.deconstructedEntities, event.entity)
    end
end

function Manager:undoRedoApplied(event)
    -- abort anything the builder is doing.
end

script.register_metatable("Manager", Manager)
return Manager