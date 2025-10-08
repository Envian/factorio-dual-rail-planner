local Helpers = require("scripts.helpers")
local RailPointer = require("scripts.classes.rail-pointer")
local RailSegment = require("scripts.classes.rail-segment")

--- @class (exact) RailPath
--- @field segments RailSegment[]
--- @field forward RailPointer
--- @field backward RailPointer
local RailPath = {}
--- @diagnostic disable-next-line: inject-field
RailPath.__index = RailPath

--- Creates a new path.
--- @param params RailSegment[] | RailPointer
--- @return RailPath
--- @diagnostic disable-next-line: inject-field
function RailPath.new(params)
    local path = {}

    if getmetatable(params) == RailPointer then
        -- RailPointer constructor.
        path.segments = {}
        path.forward = params
        path.backward = params:createReverse()
    else
        -- Array constructor
        path.segments = params
        path.forward = params[#params].forward
        path.backward = params[1].backward
    end


    setmetatable(path, RailPath)
    return path
end

--- Joins multiple rail segments together.
--- @param paths RailPath[]
--- @return RailPath
--- @diagnostic disable-next-line: inject-field
function RailPath.fromList(paths)
    local path = {}
    setmetatable(path, RailPath)

    path.segments = {}
    path.forward = paths[1].forward
    path.backward = paths[1].backward

    for index = 1, #paths[1].segments do
        table.insert(path.segments, paths[1].segments[index])
    end

    if #paths > 1 then
        if path.backward:isOpposite(paths[2].forward) or
           path.backward:isOpposite(paths[2].backward)
        then
            path:reverse()
        end
        for index = 2, #paths do
            path:join(paths[index])
        end
    end

    return path
end

--- Reverses this path.
function RailPath:reverse()
    table.reverse(self.segments)
    self.forward, self.backward = self.backward, self.forward
    for _, segment in ipairs(self.segments) do
        segment:reverse()
    end
end

--- Adds a rail to the path. Returns true if successful.
--- @param segment RailSegment
--- @return boolean
function RailPath:tryAdd(segment)
    segment:alignAwayFrom(self.forward)

    if segment.backward:isOpposite(self.forward) then
        table.insert(self.segments, segment)
        self.forward = segment.forward
        return true
    end

    -- Special case for reversing single rail paths.
    if #self.segments == 1 then
        segment:alignAwayFrom(self.backward)

        if segment.backward:isOpposite(self.backward) then
            self.segments[1]:reverse()
            table.insert(self.segments, segment)
            self.backward = self.segments[1].backward
            self.forward = segment.forward
            return true
        end
    end

    return false
end

--- Extends this path with the given turn.
--- @param turn Turn
function RailPath:extend(turn)
    local segment = RailSegment.fromPointer(self.forward, turn)
    table.insert(self.segments, segment)
    self.forward = segment.forward
end

--- Extends this path with a ramp.
function RailPath:extendRamp()
    local segment = RailSegment.rampFromPointer(self.forward)
    table.insert(self.segments, segment)
    if segment then
        self.forward = segment.forward
    end
end

--- Rewinds this path by one step, then returns the rewound segment
--- @return RailSegment?
function RailPath:rewind()
    local rewind = table.remove(self.segments)
    if rewind then
        self.forward = rewind.backward:createReverse()
    end
    return rewind
end

--- joins a path to the end of this one.
--- @param other RailPath
--- @return boolean
function RailPath:join(other)
    if self.forward:isOpposite(other.backward) then
        for _, segment in ipairs(other.segments) do
            table.insert(self.segments, segment)
        end
        self.forward = self.segments[#self.segments].forward
        return true
    end

    if self.forward:isOpposite(other.forward) then
        for index = #other.segments, 1, -1 do
            other.segments[index]:reverse()
            table.insert(self.segments, other.segments[index])
        end
        self.forward = self.segments[#self.segments].forward
        return true
    end

    return false
end

--- Gets the event numbers for the start and end of this path. For debugging.
--- @return string
function RailPath:range()
    if #self.segments == 1 then
        return tostring(self.segments[1].eventIndex)
    elseif #self.segments > 1 then
        return self.segments[1].eventIndex .. "-" .. self.segments[#self.segments].eventIndex
    end
    return "~"
end

return RailPath
