local DIRECTION_VECTORS = require("scripts.rail-consts.raw.direction-vectors")
local TURN_DISTANCE = require("scripts.rail-consts.turn-distance")
local PLANNER_INFO = require("scripts.rail-consts.planner-info")

local Turn = require("scripts.classes.turn")

local RailPath = require("scripts.classes.rail-path")

local algos = require("scripts.algorithms")

--- @class (exact) RailBuilder
--- @field player LuaPlayer
--- @field plannerInfo PlannerInfo
--- @field mainPath RailPath
--- @field newPath RailPath
--- @field alignmentPoints AlignmentPoint[]
--- @field entities BlueprintEntity[]
--- @field private railDistance number
--- @field private debt number
local RailBuilder = {}

---@diagnostic disable-next-line: inject-field
RailBuilder.__index = RailBuilder

--- Creates a new RailBuilder.
--- @param player LuaPlayer
--- @param planner string
--- @return RailBuilder
--- @diagnostic disable-next-line: inject-field
function RailBuilder.new(player, planner, mainPath)
    local builder = {}

    builder.player = player
    builder.plannerInfo = PLANNER_INFO[planner]
    builder.railDistance = settings.get_player_settings(player)["opposite-offset"].value

    if settings.get_player_settings(player)["left-hand-drive"].value then
        builder.railDistance = builder.railDistance * -1
    end

    -- Initiate opposite path.
    local startPointer = mainPath.backward:createReverse():createParrallel(builder.railDistance)

    -- Move our start point forward to account for any unpaid debt.
    local historyPointer = storage.history[player.index].pointer
    if historyPointer and mainPath.backward:isOpposite(historyPointer) then
        local debt = TURN_DISTANCE[historyPointer.direction][Turn.STRAIGHT] * storage.history[player.index].debt
        startPointer.position:move(DIRECTION_VECTORS[historyPointer.direction] * debt)
    end

    builder.newPath = RailPath.new(startPointer)
    builder.mainPath = mainPath
    builder.entities = {}
    builder.debt = 0

    setmetatable(builder, RailBuilder)
    return builder
end

function RailBuilder:buildPath()
    for _, segment in ipairs(self.mainPath.segments) do
        self.debt = algos.pathfind(self.newPath, segment.forward:createParrallel(self.railDistance), self.player)

        -- If we encounter an error, just bail.
        if self.debt < 0 then
            self.debt = 0
            break
        end
    end

    self.alignmentPoints = algos.getAlignmentPoints(self.newPath, self.mainPath)

    for _, segment in ipairs(self.newPath.segments) do
        table.insert(self.entities, {
            type = segment.type,
            position = segment.position,
            direction = segment.rotation,
        })
    end

    if DRAW_MODE then self:draw() end

    -- Update history
    storage.history[self.player.index].pointer = self.mainPath.forward
    storage.history[self.player.index].debt = self.debt
end

--- Adds extra non-rail elements, such as supports and signals.
function RailBuilder:addExtras()
    algos.addSupports(self)
    algos.addSignals(self)

    -- TODO: Add Signals
    -- TODO: Add Power Poles
end

function RailBuilder:finish()
    algos.buildBlueprint(self.entities, self.player, self.plannerInfo)
end

--- Draws both paths and their alignment points.
--- @private
function RailBuilder:draw()
    for _, pair in pairs(self.alignmentPoints) do
        local start = pair.mainPoint.position
        if pair.mainPoint.layer == defines.rail_layer.elevated then
            start = start + { x = 0, y = -3 }
        end

        local finish = pair.newPoint.position
        if pair.newPoint.layer == defines.rail_layer.elevated then
            finish = finish + { x = 0, y = -3 }
        end

        rendering.draw_line({
            color = { 1, 1, 1, 1 },
            width = 1,
            gap_length = 6/32,
            dash_length = 3/32,
            from = start,
            to = finish,
            surface = pair.mainPoint.surface
        })
    end

    for index, segment in ipairs(self.mainPath.segments) do
        segment:draw(self.player, index)
    end

    for index, segment in ipairs(self.newPath.segments) do
        segment:draw(self.player, index)
    end
end

require("scripts.profiling").register(RailBuilder, "RailBuilder")

script.register_metatable("RailBuilder", RailBuilder)
return RailBuilder
