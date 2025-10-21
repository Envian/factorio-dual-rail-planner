local Vector2d = require("scripts.classes.vector")

local ELEVATED_OFFSET = Vector2d:new({ x = 0, y = -3 })
local ENTITY_NUMBER_OFFSET = Vector2d:new({ x = 0, y = -0.18 })
local PATH_NUMBER_OFFSET = Vector2d:new({ x = 0, y = 0.18 })

local BOX = {
    VERTICIES = {
        { x = 0.75, y = -0.35 },
        { x = 0.75, y = 0.35 },
        { x = -0.75, y = -0.35 },
        { x = -0.75, y = 0.35 },
    },
    COLOR_BG = { 0, 0, 0, 0.75 },
    COLOR_BORDER = { 0, 0, 0, 1 },
    COLOR_BORDER_WIDTH = 2,
    COLOR_PATH = { 0.5, 1, 1, 1 },
    COLOR_ENTITY = { 1, 1, 0.5, 1 },
}

local POINT = {
    COLOR_BG = { 0, 0, 0, 1 },
    COLOR_POSITION = { 1, 0, 0, 1 },
    COLOR_EDGE = { 0.5, 0, 0, 1 },
    COLOR_ELEVATED = { 0, 0.5, 0.5, 1 },
    COLOR_REWIND = { 0, 0, 0, 1 },
    COLOR_REWIND_ELEVATED = { 0, 0, 0, 1 },
    RADIUS = 1 / 14,
    BORDER = 2,
}

local PATH = {
    BACKWARD_OFFSET = { x = 0.1, y = 0 },
    COLOR = { 0, 1, 1, 1 },
    COLOR_BG = { 0, 0.5, 0.5, 1 },
    COLOR_ALT = { 1, 1, 0, 1 },
    COLOR_BG_ALT = { 0.5, 0.5, 0, 1 },
    WIDTH = 4,
    WIDTH_BG = 6,
    TRIANGLE_VERTICIES = {
        { x = -0.1, y = 0 },
        { x = -0.35, y = 0.35 },
        { x = -0.35, y = -0.35 },
    },
    TRIANGLE_VERTICIES_BG = {
        { x = -0.1 + 1/32, y = 0 },
        { x = -0.35 - 1/32, y = 0.35 + 1/12 },
        { x = -0.35 - 1/32, y = -0.35 - 1/12 },
    },
    TRIANGLE_BACK = { x = -0.25, y = 0 },
}

local REWIND = {
    BACKWARD_OFFSET = { x = 0.1, y = 0 },
    COLOR = { 0, 0, 0, 1 },
    COLOR_BG = { 0.25, 0.25, 0.25, 1 },
    WIDTH = 2,
    WIDTH_BG = 3,
}

--- Rotates a point around its center, then adds an offset.
--- @param point Vector2d
--- @param radians number
--- @param offset Vector2d
--- @return Vector2d
local function rotateThenAdd(point, radians, offset)
    return Vector2d:new({
        x = point.x * math.cos(radians) - point.y * math.sin(radians) + offset.x,
        y = point.x * math.sin(radians) + point.y * math.cos(radians) + offset.y,
    })
end

--- Rotates an array of points around its center, then adds an offset.
--- @param points Vector2d[]
--- @param radians number
--- @param offset Vector2d
--- @return Vector2d[]
local function rotateThenAddList(points, radians, offset)
    local rotated = {}
    for _, point in ipairs(points) do
        table.insert(rotated, rotateThenAdd(point, radians, offset))
    end
    return rotated
end

local function drawPosition(player, surface, position, color)
    rendering.draw_circle({
        color = POINT.COLOR_BG,
        radius = POINT.RADIUS,
        filled = true,
        target = position,
        surface = surface,
        players = { player },
        only_in_alt_mode = true,
    })
    rendering.draw_circle({
        color = color,
        radius = POINT.RADIUS,
        width = POINT.BORDER,
        filled = false,
        target = position,
        surface = surface,
        players = { player },
        only_in_alt_mode = true,
    })
end

--- Draw function for RailSegments.
--- @param self RailSegment
--- @param player LuaPlayer
--- @param pathIndex number
local function draw(self, player, pathIndex)
    local forward = self.forward.position
    local backward = self.backward.position

    if self.forward.layer == defines.rail_layer.elevated then
        forward = forward + ELEVATED_OFFSET
    end
    if self.backward.layer == defines.rail_layer.elevated then
        backward = backward + ELEVATED_OFFSET
    end

    local center = (forward + backward) / 2
    local directionVector = forward - backward
    local radians = math.atan2(directionVector.y, directionVector.x)

    -- Fuck performance im not opening up a photo editing app when i can just
    -- write more code.

    local arrowColorFG = self.eventIndex and PATH.COLOR or PATH.COLOR_ALT
    local arrowColorBG = self.eventIndex and PATH.COLOR_BG or PATH.COLOR_BG_ALT

    -- Path Arrows
    rendering.draw_line({
        color = arrowColorBG,
        width = PATH.WIDTH_BG,
        from = rotateThenAdd(PATH.BACKWARD_OFFSET, radians, backward),
        to = rotateThenAdd(PATH.TRIANGLE_BACK, radians, forward),
        surface = self.surface,
        players = { player },
        only_in_alt_mode = true,
    })
    rendering.draw_polygon({
        color = arrowColorBG,
        vertices = rotateThenAddList(PATH.TRIANGLE_VERTICIES_BG, radians, forward),
        surface = self.surface,
        players = { player },
        only_in_alt_mode = true,
    })
    rendering.draw_line({
        color = arrowColorFG,
        width = PATH.WIDTH,
        from = rotateThenAdd(PATH.BACKWARD_OFFSET, radians, backward),
        to = rotateThenAdd(PATH.TRIANGLE_BACK, radians, forward),
        surface = self.surface,
        players = { player },
        only_in_alt_mode = true,
    })
    rendering.draw_polygon({
        color = arrowColorFG,
        vertices = rotateThenAddList(PATH.TRIANGLE_VERTICIES, radians, forward),
        surface = self.surface,
        players = { player },
        only_in_alt_mode = true,
    })

    -- Main Box
    local boxVerticies = rotateThenAddList(BOX.VERTICIES, radians, center)
    rendering.draw_polygon({
        color = BOX.COLOR_BG,
        vertices = boxVerticies,
        surface = self.surface,
        players = { player },
        only_in_alt_mode = true,
    })
    rendering.draw_line({
        color = BOX.COLOR_BORDER,
        width = BOX.COLOR_BORDER_WIDTH,
        from = boxVerticies[1],
        to = boxVerticies[2],
        surface = self.surface,
        players = { player },
        only_in_alt_mode = true,
    })
    rendering.draw_line({
        color = BOX.COLOR_BORDER,
        width = BOX.COLOR_BORDER_WIDTH,
        from = boxVerticies[2],
        to = boxVerticies[4],
        surface = self.surface,
        players = { player },
        only_in_alt_mode = true,
    })
    rendering.draw_line({
        color = BOX.COLOR_BORDER,
        width = BOX.COLOR_BORDER_WIDTH,
        from = boxVerticies[4],
        to = boxVerticies[3],
        surface = self.surface,
        players = { player },
        only_in_alt_mode = true,
    })
    rendering.draw_line({
        color = BOX.COLOR_BORDER,
        width = BOX.COLOR_BORDER_WIDTH,
        from = boxVerticies[3],
        to = boxVerticies[1],
        surface = self.surface,
        players = { player },
        only_in_alt_mode = true,
    })

    -- Entity Center
    -- drawPosition(player, self.surface, self.position, POINT.COLOR_POSITION)

    local textRadians = radians % math.pi
    if textRadians > math.pi / 2 then
        textRadians = textRadians - math.pi
    end

    -- Debug Text
    if self.eventIndex then
        local epos = rotateThenAdd(ENTITY_NUMBER_OFFSET, textRadians % math.pi, center)
        local ppos = rotateThenAdd(PATH_NUMBER_OFFSET, textRadians % math.pi, center)
        if textRadians < 0 then
            epos, ppos = ppos, epos
        end

        -- Player path drawing.
        rendering.draw_text({
            text = "E" .. tostring(self.eventIndex),
            surface = self.surface,
            target = epos,
            color = { 1, 1, 0.5, 1 },
            scale = .75,
            players = { player },
            orientation = textRadians / math.pi / 2,
            alignment = "center",
            vertical_alignment = "middle",
            only_in_alt_mode = true,
        })
        rendering.draw_text({
            text = "P" .. tostring(pathIndex),
            surface = self.surface,
            target = ppos,
            color = { 0.5, 1, 1, 1 },
            scale = .75,
            players = { player },
            orientation = textRadians / math.pi / 2,
            alignment = "center",
            vertical_alignment = "middle",
            only_in_alt_mode = true,
        })
    else
        rendering.draw_text({
            text = "P" .. tostring(pathIndex),
            surface = self.surface,
            target = center,
            color = { 0.5, 1, 1, 1 },
            players = { player },
            orientation = textRadians / math.pi / 2,
            alignment = "center",
            vertical_alignment = "middle",
            only_in_alt_mode = true,
        })
    end

    -- Draw the forward and backward vectors.
    drawPosition(player, self.surface, self.forward.position, POINT.COLOR_EDGE)
    drawPosition(player, self.surface, self.backward.position, POINT.COLOR_EDGE)
    if self.forward.position ~= forward then
        drawPosition(player, self.surface, forward, POINT.COLOR_ELEVATED)
    end
    if self.backward.position ~= backward then
        drawPosition(player, self.surface, backward, POINT.COLOR_ELEVATED)
    end
end
--- Draws only the event index.
--- @param self RailSegment
--- @param player LuaPlayer
local function drawEventText(self, player)
    local forward = self.forward.position
    local backward = self.backward.position

    if self.forward.layer == defines.rail_layer.elevated then
        forward = forward + ELEVATED_OFFSET
    end
    if self.backward.layer == defines.rail_layer.elevated then
        backward = backward + ELEVATED_OFFSET
    end

    local center = { x = (forward.x + backward.x) / 2, y = (forward.y + backward.y) / 2 }
    local offsetVector = forward - backward
    local radians = math.atan2(offsetVector.y, offsetVector.x)

    local textRadians = radians % math.pi
    if textRadians > math.pi / 2 then
        textRadians = textRadians - math.pi
    end

    local epos = rotateThenAdd(ENTITY_NUMBER_OFFSET, textRadians % math.pi, center)
    local ppos = rotateThenAdd(PATH_NUMBER_OFFSET, textRadians % math.pi, center)
    if textRadians < 0 then
        epos, ppos = ppos, epos
    end

    rendering.draw_text({
        text = "E" .. tostring(self.eventIndex),
        surface = self.surface,
        target = epos,
        color = { 1, 1, 0.5, 1 },
        scale = .75,
        players = { player },
        orientation = textRadians / math.pi / 2,
        alignment = "center",
        vertical_alignment = "middle",
        only_in_alt_mode = true,
    })
end

local function drawRewind(self, player)
    local forward = self.forward.position
    local backward = self.backward.position

    if self.forward.layer == defines.rail_layer.elevated then
        forward = forward + ELEVATED_OFFSET
    end
    if self.backward.layer == defines.rail_layer.elevated then
        backward = backward + ELEVATED_OFFSET
    end

    -- Path Arrows
    rendering.draw_line({
        color = REWIND.COLOR_BG,
        width = REWIND.WIDTH_BG,
        from = backward,
        to = forward,
        surface = self.surface,
        players = { player },
        only_in_alt_mode = true,
    })
    rendering.draw_line({
        color = REWIND.COLOR,
        width = REWIND.WIDTH,
        from = backward,
        to = forward,
        surface = self.surface,
        players = { player },
        only_in_alt_mode = true,
    })

    drawPosition(player, self.surface, self.forward.position, POINT.COLOR_REWIND)
    drawPosition(player, self.surface, self.backward.position, POINT.COLOR_REWIND)
    if self.forward.position ~= forward then
        drawPosition(player, self.surface, forward, POINT.COLOR_REWIND_ELEVATED)
    end
    if self.backward.position ~= backward then
        drawPosition(player, self.surface, backward, POINT.COLOR_REWIND_ELEVATED)
    end
end

return {
    draw = draw,
    drawEventText = drawEventText,
    drawRewind = drawRewind,
}
