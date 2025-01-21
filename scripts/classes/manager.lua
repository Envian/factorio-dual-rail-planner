local TURN = require("scripts.helpers.turn")

local position = require("scripts.helpers.position")
local delay = require("scripts.helpers.delay")

local RailPointer = require("scripts.classes.rail-pointer")
local RailSegment = require("scripts.classes.rail-segment")
local RailBuilder = require("scripts.classes.rail-builder")

require("scripts.helpers")

local Manager = {}
Manager.__index = Manager

function Manager.new(player)
    local manager = {}
    setmetatable(manager, Manager)

    manager.player = player
    manager.alerts = {}

    manager.enabled = false
    manager.abort = false
    manager.mainPointer = nil
    manager.oppositeBuilder = nil
    manager.plannerName = nil

    manager.elevatedMode = false
    manager.elevatedQueue = {}

    return manager
end

function Manager:disable()
    if self.plannerName then
        self.player.set_shortcut_toggled(SHORTCUT_PREFIX .. self.plannerName, false)
    end

    self:reset()
    self.enabled = false
    self.abort = false
    self.plannerName = nil
end

function Manager:reset()
    if self.oppositeBuilder and self.oppositeBuilder.straightsBuilt < 0 then
        -- There's straights to build on the main path. Not in builder since builder is opposite only.
        for n = 1, -self.oppositeBuilder.straightsBuilt do
            local segment = RailSegment.fromPointer(self.mainPointer, TURN.STRAIGHT)
            segment:build(self.player, self.plannerName)
            self.mainPointer = segment.forward
        end
    end

    self.mainPointer = nil
    self.oppositeBuilder = nil

    self.elevatedMode = false
    self.elevatedQueue = nil
    self.lastSuppport = nil
end

function Manager:togglePlanner(plannerName)
    if self.enabled then
        self:disable()
        self.player.clear_cursor()
    else
        self.plannerName = plannerName
        self.enabled = true
        self.player.set_shortcut_toggled(SHORTCUT_PREFIX .. plannerName, true)
        self.player.clear_cursor()
        self.player.cursor_ghost = plannerName
    end
end

function Manager:checkCursor()
    if not self.enabled or self.abort then return end

    -- Check if we're still using the same planner.
    local stack = self.player.cursor_stack
    local ghost = self.player.cursor_ghost
    local item = (stack and stack.valid_for_read and stack) or (ghost and ghost.name)

    if not item or item.name ~= self.plannerName then
        self:disable()
    end
end

function Manager:entityBuilt(event)
    if not self.enabled then return end

    if self.abort then
        self.player.print("Aborting: " .. event.entity.name)
        -- Anything built during an abortion is invalid.
        if not self.player.can_reach_entity(event.entity) or not self.player.mine_entity(event.entity) then
            event.entity.order_deconstruction(self.player.force, self.player)
        end
        return
    end

    if event.entity.type == "rail-support" or event.entity.type == "rail-ramp" then
        self.elevatedMode = true
        self.elevatedQueue = {}
        self.lastSupport = event.entity

        -- Don't immidiately process rail supports.
        if event.entity.type == "rail-support" then
            return
        end
    end

    local newSegment = RailSegment.fromEntity(event.entity, self.mainPointer and self.mainPointer.direction)

    if not self.elevatedMode then
        self:handleRailBuilt(newSegment)
    else
        local forwardExtensions = filterForExistingSegments(RailSegment.getAllFromPointer(newSegment.forward))
        local backwardExtensions = filterForExistingSegments(RailSegment.getAllFromPointer(newSegment.backward))

        if #forwardExtensions == 0 and #backwardExtensions == 0 then
            -- Check for supports. if the user is building off a support freeform.
            -- spawn a biter to tell them this is not supported.
        end

        if #self.elevatedQueue == 0 then
            -- If this is the first rail, we may already be done.
            if #forwardExtensions + #backwardExtensions == 1 then
                self:resolveSupportBuild(newSegment)
                return
            else
                table.insert(self.elevatedQueue, newSegment)
                return
            end
        end

        -- When we're wedged between two rails we're done.
        if #forwardExtensions == 1 and #backwardExtensions == 1 then
            if backwardExtensions[1]:isSame(self.elevatedQueue[#self.elevatedQueue]) then
                newSegment:reverse()
                forwardExtensions, backwardExtensions = backwardExtensions, forwardExtensions
            end

            self:resolveSupportBuild(newSegment)
            return
        else
            table.insert(self.elevatedQueue, newSegment)
            return
        end
    end
end

function Manager:resolveSupportBuild(newSegment)
    -- Connected to the old rail
    self:handleRailBuilt(newSegment)

    -- HandleRailBuild can reset the manager, which ends elevated mode.
    if not self.elevatedMode then return end

    -- Reprocess the previous rails in reverse order.
    for n = #self.elevatedQueue, 1, -1 do
        self:handleRailBuilt(self.elevatedQueue[n])

        -- HandleRailBuild can reset the manager, which ends elevated mode.
        if not self.elevatedMode then return end
    end

    -- TODO: Build the support.
    self.elevatedMode = false
    self.elevatedQueue = nil
    self.lastSupport = nil
end

function Manager:handleRailBuilt(newSegment)
    -- Check 1: Reset this path if the newly placed rail is not connected.
    if self.mainPointer then
        if not self.mainPointer:isOpposite(newSegment.backward) then
            self:reset()
        end
    end

    -- Step 2: Create pointers if they do not exist.
    if not self.mainPointer then
        local forwardExtensions = filterForExistingSegments(RailSegment.getAllFromPointer(newSegment.forward))
        local backwardExtensions = filterForExistingSegments(RailSegment.getAllFromPointer(newSegment.backward))

        if #backwardExtensions == 0 and #forwardExtensions > 0 then
            newSegment:reverse()
            forwardExtensions, backwardExtensions = backwardExtensions, forwardExtensions
        end

        if #forwardExtensions == 0 and #backwardExtensions > 0 then
            self.mainPointer = newSegment.backward:createReverse()
            self.oppositeBuilder = RailBuilder.new({
                pointer = RailPointer.new({
                    position = position.add(self.mainPointer.position, OPPOSITE_OFFSET[self.mainPointer.direction]),
                    direction = self.mainPointer.direction,
                    layer = self.mainPointer.layer,
                    surface = self.mainPointer.surface
                }),
                plannerName = self.plannerName,
                player = self.player,
            })
        end
    end

    -- Step 3: extend the rails
    if self.mainPointer then
        if newSegment.type ~= "rail-ramp" then
            if not self.oppositeBuilder:extend(newSegment.turn) then
                self:handleBrokenRail(newSegment, self.oppositeBuilder.history[#self.oppositeBuilder.history])
                return
            end
            self.mainPointer = newSegment.forward
        else
            local targetOppositePointer = RailPointer.new({
                position = position.add(self.mainPointer.position, OPPOSITE_OFFSET[self.mainPointer.direction]),
                direction = self.mainPointer.direction,
                layer = self.mainPointer.layer,
                surface = self.mainPointer.surface
            })

            if targetOppositePointer ~= self.oppositeBuilder.pointer then
                -- the current state of the builder isn't aligned. Mark an error and move on.
                if #self.oppositeBuilder.history > 0 then
                    self:handleBrokenRail(newSegment, self.oppositeBuilder.history[#self.oppositeBuilder.history])
                    return
                end
                self.oppositeBuilder = RailBuilder.new({
                    pointer = targetOppositePointer,
                    plannerName = self.plannerName,
                    player = self.player,
                })
            end

            if not self.oppositeBuilder:extendRamp() then
                self:handleBrokenRail(newSegment, self.oppositeBuilder.history[#self.oppositeBuilder.history])
                return
            end
            self.mainPointer = newSegment.forward
        end
    end
end

function Manager:handleBrokenRail(mainSegment, oppositeSegment)
    if true then
        -- Abort mode
        mainSegment:deconstruct(self.player)
        self:reset()
        self.abort = true
        self.player.clear_cursor()

        delay(5, function()
            -- Handle the cursor changing after an abort.
            self.player.clear_cursor() -- Just in the offchance the user selected something
            self.player.cursor_ghost = self.plannerName
            self.abort = false
        end)
    else
        -- Notify to Fix Mode
        self:registerBrokenRailAlert(oppositeSegment:getEntity())
        self:reset()
    end
end

function Manager:registerBrokenRailAlert(entity)
    self.player.add_custom_alert(entity, { type = "item", name = self.plannerName }, "Broken Rail!", true)

    local elevated = TYPE_TO_LAYER[entity.type == "entity-ghost" and entity.ghost_type or entity.type] == defines.rail_layer.elevated

    self.alerts[entity] = {
        expires = game.tick + ALERT_DURATION,
        sprite = rendering.draw_sprite({
            sprite = ALERT_SPRITE,
            target = {
                entity = entity,
                offset = elevated and { x = 0, y = -3 } or nil,
            },
            surface = entity.surface,
            players = { self.player },
        })
    }
end

function Manager:refreshAlerts()
    for entity, config in pairs(self.alerts) do
        if not entity.valid or game.tick > config.expires then
            if config.sprite.valid then config.sprite.destroy() end
            self.alerts[entity] = nil
        else
            self.player.add_custom_alert(entity, { type = "item", name = "rail" }, "Broken Rail!", true)
        end
    end
end

script.register_metatable("Manager", Manager)
return Manager