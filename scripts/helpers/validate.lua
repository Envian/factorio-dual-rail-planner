local RAILDEFS = require("scripts.rail-config.common")

local validate = {}

function validate.position(position)
    return type(position.x) == "number" and type(position.y) == "number"
end

function validate.turn(turn)
    return type(turn) == "number" and turn >= -1 and turn <= 1
end

function validate.direction(direction)
    return type(direction) == "number" and direction >= 0 and direction <= 15
end

function validate.railEntity(rail)
    if rail.object_name ~= "LuaEntity" then return false end
    if not rail.valid then return false end

    if rail.type == "entity-ghost" then
        return not not RAILDEFS.RAIL_TYPE_CONFIG[rail.ghost_type]
    else
        return not not RAILDEFS.RAIL_TYPE_CONFIG[rail.type]
    end
end

return validate
