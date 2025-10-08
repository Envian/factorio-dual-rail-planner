local TYPE_TO_LAYER = require("scripts.rail-consts.raw.layer")
local SHORTCUT_PREFIX = require("scripts.constants").SHORTCUT_PREFIX

local Helpers = require("scripts.helpers")
local RailPath = require("scripts.classes.rail-path")
local RailSegment = require("scripts.classes.rail-segment")

local tickHandler = require("scripts.ontick")

-- So, here's how this works at a high level. We cannot determine the build order
-- with a single event, so we need to collect them to determine planner direction.
-- Ground and elevated rails have different rules for placement.
--
-- Ground paths:
--      Ground paths are easy. The planner places them one at a time in order.
--      The first tile placed goes into the "groundCache", any subsequent paths
--      extend off of that, giving us a direction, and converts to a proper "path"
--
-- Elevated paths:
--      This is some cursed shit. Elevated rails seem to follow the following rules:
--
--          1. Always build out from supports.
--          2. If the support does not exist, add them as we need them.
--          3. If the supports exists as real entites, Build forward facing rails
--             before placing backwards facing rails.
--          4. If the rail supports exist as ghosts, Ignore rule 1 and build in path order.
--
--      Because this can be chaotic, we track elevated rails by creating contiguous
--      segments of rails and tracking each in "elevatedCache". When we're ready
--      to finalize the path, order the segments so they can connect then follow
--      these rules:
--
--          1. If there's a "path" (or "LowConfidencePath"), build off of that.
--          2. If there's 3 or more segments, we can infer the direction.
--          3. If there's 1 or 2 segments, store it in the "lowConfidencePath".
--
-- Special Case: History
--      If we ever come across a rail segment (elevated or otherwise) which
--      is connected to the last path the player placed, we automatically convert
--      that segment into the "path".


--- @class (exact) EventParser
--- @field planner string?
--- @field private plannerItem string?
--- @field player LuaPlayer
--- @field private path RailPath?
--- @field private lowConfidencePath RailPath?
--- @field private eventIndex number?
--- @field private groundCache RailSegment?
--- @field private elevatedCache RailPath[]?
--- @field private support LuaEntity?
--- @field private tiles LuaEntity[]
local EventParser = {}
--- @diagnostic disable-next-line: inject-field
EventParser.__index = EventParser

-- Some local helpers that we don't intend to expose

--- Orders segments.
--- @param segments RailPath[]
--- @return RailPath[]
local function orderSegments(segments)
    local orderedPaths = {}

    local positionToPathMap = {}
    for _, subpath in pairs(segments) do
        positionToPathMap[subpath.forward:toKey()] = subpath
        positionToPathMap[subpath.backward:toKey()] = subpath
    end

    -- It is strictly important that we start our path from the first segment,
    -- and try to preserve its orientation.

    -- Grab forward paths.
    local currentPath = segments[1]
    while currentPath do
        table.insert(orderedPaths, currentPath)

        -- Gets the next edge
        local nextEdge = currentPath.forward
        currentPath = positionToPathMap[nextEdge:toKeyReverse()]

        -- reverse the next edge if its facing the wrong way.
        if currentPath and currentPath.forward:isOpposite(nextEdge) then
            currentPath:reverse()
        end
    end

    -- Grab reverse paths.
    currentPath = positionToPathMap[segments[1].backward:toKeyReverse()]
    while currentPath do
        table.insert(orderedPaths, 1, currentPath)

        -- Gets the next edge
        local nextEdge = currentPath.backward
        currentPath = positionToPathMap[nextEdge:toKeyReverse()]

        -- reverse the next edge if its facing the wrong way.
        if currentPath and currentPath.backward:isOpposite(nextEdge) then
            currentPath:reverse()
        end
    end

    return orderedPaths
end

--- Rearranges the ordered segments, so they build off of the given pointer.
--- @param pointer RailPointer
--- @param segments RailPath[]
--- @return boolean
local function tryArrangeAwayFrom(pointer, segments)
    if pointer:isOpposite(segments[#segments].forward) or pointer:isOpposite(segments[1].backward) then
        return true
    elseif pointer:isOpposite(segments[#segments].forward) or pointer:isOpposite(segments[1].backward) then
        table.reverse(segments)
        return true
    end
    return false
end

--- Creates a new EventParser.
--- @param player LuaPlayer
--- @return EventParser
--- @diagnostic disable-next-line: inject-field
function EventParser.new(player)
    local parser = {}
    setmetatable(parser, EventParser)

    parser.planner = nil
    parser.player = player
    parser.eventIndex = 0

    parser.path = nil
    parser.lowConfidencePath = nil
    parser.elevatedCache = nil
    parser.groundCache = nil
    parser.tiles = {}

    return parser
end

--- Toggles the event parser for this planner type.
--- @param railPlanner string
function EventParser:toggle(railPlanner)
    if self.planner == railPlanner then
        self:disable()
    else
        if self.planner then
            drpDebug({ "debug.planner-disable", self.planner })
            self.player.set_shortcut_toggled(SHORTCUT_PREFIX .. self.planner, false)
        end
        self:enable(railPlanner)
    end
end

--- Enables this parser
--- @param railPlanner string
function EventParser:enable(railPlanner)
    drpDebug({ "debug.planner-enable", railPlanner })

    self.planner = railPlanner
    self.player.clear_cursor()
    self.player.cursor_ghost = self.planner
    self.player.set_shortcut_toggled(SHORTCUT_PREFIX .. railPlanner, true)
end

function EventParser:disable()
    drpDebug({ "debug.planner-disable", self.planner })

    self.player.clear_cursor()
    self.player.set_shortcut_toggled(SHORTCUT_PREFIX .. self.planner, false)
    self.planner = nil
    self.elevatedCache = nil -- Clear the cache so we don't accidentally use an incomplete one.
end

--- Checks the players cursor and self disables if the cursor is cleared or changed.
function EventParser:checkCursor()
    if self.planner == nil then return end

    -- Check if we're still using the same planner.
    if not self.player.cursor_ghost or self.player.cursor_ghost.name.name ~= self.planner then
        self:disable()
    end
end

--- Handles an entity event.
--- @param entity LuaEntity
function EventParser:entityBuilt(entity)
    if self.planner == nil then return end

    local type = Helpers.getEntityType(entity)

    if type == "tile-ghost" then
        table.insert(self.tiles, entity)
        return
    end

    local segment = RailSegment.fromEntity(entity)
    self.eventIndex = self.eventIndex + 1
    segment.eventIndex = self.eventIndex
    segment:drawEventText(self.player)

    if #self.tiles > 0 then
        segment.tiles = self.tiles
        self.tiles = {}
    end

    if segment.type == "rail-ramp" then
        if self.groundCache then
            self:handleGroundRail(segment)
        else
            self:handleElevatedRail(segment)
        end
    elseif TYPE_TO_LAYER[segment.type] == defines.rail_layer.ground then
        -- Connect the transition to ground.
        if self.elevatedCache then
            self:resolveElevatedRails()
        end

        if self.lowConfidencePath then
            self:connectLowConfidenceToTarget(segment)
        end

        self:handleGroundRail(segment)
    else
        self:handleElevatedRail(segment)
    end

    -- This planner now has something to check.
    tickHandler.register()
end

--- Handles ground rail events.
--- @private
--- @param segment RailSegment
function EventParser:handleGroundRail(segment)
    if self.path then
        -- Path exists. attempt to extend it.
        if self.path:tryAdd(segment) then
            return -- Successfully added.
        else
            -- Not connected
            drpDebug({ "", { "debug.not-connected" }, " @E", segment.eventIndex })
            -- TODO: What do we do when we have an initial path but fail to continue?
            -- Currently, we just remove the old path.
            self.path = nil
        end
    elseif self.groundCache then
        -- No path, but we have a cached entity.
        if self.groundCache:alignSegments(segment) then
            drpDebug({ "", { "debug.new-path" }, " @E", self.groundCache.eventIndex, "-", segment.eventIndex })
            self.path = RailPath.new({ self.groundCache, segment })
            self.groundCache = nil
            return
        end

        drpDebug({ "", { "debug.not-connected" }, " @E", segment.eventIndex })
    end

    -- -- This is only needed to support single tile extensions.
    -- local forwardExtensions = #RailSegment.getAllExistingFromPointer(segment.forward)
    -- local backwardExtensions = #RailSegment.getAllExistingFromPointer(segment.backward)

    -- if forwardExtensions > 0 and backwardExtensions == 0 then
    --     segment:reverse()
    --     drpDebug({ "", { "debug.new-path" }, " @E", segment.eventIndex })
    --     self.path = RailPath.new({ segment })
    --     return
    -- elseif backwardExtensions > 0 and forwardExtensions == 0 then
    --     drpDebug({ "", { "debug.new-path" }, " @E", segment.eventIndex })
    --     self.path = RailPath.new({ segment })
    --     return
    -- elseif forwardExtensions > 0 and backwardExtensions > 0 then
    --     -- TODO: Do we notify the user when ambiguous paths happen?
    --     drpDebug({ "", { "debug.ambiguous-path" }, " @E", segment.eventIndex })
    --     return
    -- end

    -- Try with history
    local lastPointer = storage.history[self.player.index].pointer
    if lastPointer and segment:alignAwayFrom(lastPointer) then
        self.path = RailPath.new({ segment })
        drpDebug({ "", { "debug.segment-algo-history" }, " @E", segment.eventIndex })
    end

    -- No path could be found
    self.groundCache = segment
end

--- Handles elevated rail events.
--- @private
--- @param segment RailSegment
function EventParser:handleElevatedRail(segment)
    if not self.elevatedCache then
        self.elevatedCache = { RailPath.new({ segment }) }
        return
    end

    local currentPath = self.elevatedCache[#self.elevatedCache]
    if not currentPath:tryAdd(segment) then
        drpDebug({ "", { "debug.segment-finalized" }, " @E", currentPath:range() })
        table.insert(self.elevatedCache, RailPath.new({ segment }))
    end
end

--- Resolves the current elevatedCache, moving it onto the path or making a new
--- path.
--- @private
function EventParser:resolveElevatedRails()
    if not self.elevatedCache then return end

    local orderedPaths = orderSegments(self.elevatedCache)
    drpDebug({ "debug.segment-report", #orderedPaths, #self.elevatedCache })

    -- Check for orphans
    if #orderedPaths ~= #self.elevatedCache then
        -- TODO Detailed orphan check.
    end

    if self.path then
        if tryArrangeAwayFrom(self.path.forward, orderedPaths) then
            drpDebug({ "debug.segment-algo-path" })

            for index = 1, #orderedPaths do
                self.path:join(orderedPaths[index])
            end

            self.elevatedCache = nil
            return
        else
            drpDebug({ "debug.not-connected" })
            self.path = nil
        end
    end

    if self.lowConfidencePath then
        -- Mostly the same as path, only lowConfidencePath can be flipped
        if tryArrangeAwayFrom(self.lowConfidencePath.forward, orderedPaths) then
            drpDebug({ "", { "debug.segment-algo-conf" }, " @E", self.lowConfidencePath.segments[1].eventIndex })

            for index = 1, #orderedPaths do
                self.lowConfidencePath:join(orderedPaths[index])
            end

            self.elevatedCache = nil
            self.path = self.lowConfidencePath
            self.lowConfidencePath = nil
            return
        elseif tryArrangeAwayFrom(self.lowConfidencePath.backward, orderedPaths) then
            drpDebug({ "", { "debug.segment-algo-conf" }, " @E", self.lowConfidencePath.segments[1].eventIndex })

            self.lowConfidencePath:reverse()
            for index = 1, #orderedPaths do
                self.lowConfidencePath:join(orderedPaths[index])
            end

            self.elevatedCache = nil
            self.path = self.lowConfidencePath
            self.lowConfidencePath = nil
            return
        else
            drpDebug({ "debug.not-connected" })
            self.lowConfidencePath = nil
        end
    end

    -- No existing path, so make it.
    if #orderedPaths > 2 then
        if self.elevatedCache[1] == orderedPaths[#orderedPaths] then
            table.reverse(orderedPaths)
        end

        -- There are 2 possible scenarios here:
        -- 1. The firstpath in event order is the first or last path. This is always the starting path.
        -- 2. The firstPath in event order is second. It will always be facing the correct direction,
        --    initially, so no need to correct. It can also only be >1 segment long.
        -- This code assumes that 1 and 2 are the only possible outcomes. Bugs and other issues may
        -- cause failures here.

        self.path = RailPath.fromList(orderedPaths)
        self.elevatedCache = nil

        drpDebug({ "", { "debug.segment-algo-long" }, " @E", self.path.segments[1].eventIndex })
        return
    end

    -- Create the lowConfidencePath
    self.lowConfidencePath = RailPath.fromList(orderedPaths)
    self.elevatedCache = nil

    local lastPointer = storage.history[self.player.index].pointer
    if lastPointer then
        -- Try to build the path off the history pointer.
        if self.lowConfidencePath.forward:isOpposite(lastPointer) then
            self.lowConfidencePath:reverse()
            self.path = self.lowConfidencePath
            self.lowConfidencePath = nil
            drpDebug({ "", { "debug.segment-algo-history" }, " @E", self.path.segments[1].eventIndex })
        elseif self.lowConfidencePath.backward:isOpposite(lastPointer) then
            self.path = self.lowConfidencePath
            self.lowConfidencePath = nil
            drpDebug({ "", { "debug.segment-algo-history" }, " @E", self.path.segments[1].eventIndex })
        end
    end
end

--- Connects a low confidence path to a target segment.
--- @param target RailSegment
function EventParser:connectLowConfidenceToTarget(target)
    if not self.lowConfidencePath then return end

    if self.lowConfidencePath.forward:isOpposite(target.forward) or
        self.lowConfidencePath.forward:isOpposite(target.backward)
    then
        self.path = self.lowConfidencePath
        drpDebug({ "", { "debug.segment-algo-ground" }, " @E", self.path.segments[1].eventIndex })
    elseif
        self.lowConfidencePath.backward:isOpposite(target.forward) or
        self.lowConfidencePath.backward:isOpposite(target.backward)
    then
        self.lowConfidencePath:reverse()
        self.path = self.lowConfidencePath
        drpDebug({ "", { "debug.segment-algo-ground" }, " @E", self.path.segments[1].eventIndex })
    else
        drpDebug({ "debug.not-connected" })
    end

    self.lowConfidencePath = nil
end

--- Gets the array of rail segments that have been placed by previous events.
--- @return RailPath?
function EventParser:getPath()
    -- Begin by giving the elevatedCache a chance to parse
    if self.elevatedCache then
        self:resolveElevatedRails()
    end

    if self.lowConfidencePath then
        -- TODO: Make this less noisy when profiling.
        drpDebug({ "", { "debug.ambiguous-path" }, " @E", self.lowConfidencePath:range() })
    end

    local path = self.path
    if path then
        -- We found a path so clear the ground cache.
        self.groundCache = nil
    end

    self.path = nil
    self.tiles = {}
    return path
end

script.register_metatable("EventParser", EventParser)
return EventParser
