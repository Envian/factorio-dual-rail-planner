function filterForExistingSegments(extensions)
    local result = {}
    for _, extension in pairs(extensions) do
        if extension:getEntity() then
            table.insert(result, extension)
        end
    end
    return result
end

defines.direction.toString = function(direction)
    if     direction == defines.direction.north          then return "north"
    elseif direction == defines.direction.northnortheast then return "north-north-east"
    elseif direction == defines.direction.northeast      then return "north-east"
    elseif direction == defines.direction.eastnortheast  then return "east-north-east"
    elseif direction == defines.direction.east           then return "east"
    elseif direction == defines.direction.eastsoutheast  then return "east-south-east"
    elseif direction == defines.direction.southeast      then return "south-east"
    elseif direction == defines.direction.southsoutheast then return "south-south-east"
    elseif direction == defines.direction.south          then return "south"
    elseif direction == defines.direction.southsouthwest then return "south-south-west"
    elseif direction == defines.direction.southwest      then return "south-west"
    elseif direction == defines.direction.westsouthwest  then return "west-south-west"
    elseif direction == defines.direction.west           then return "west"
    elseif direction == defines.direction.westnorthwest  then return "west-north-west"
    elseif direction == defines.direction.northwest      then return "north-west"
    elseif direction == defines.direction.northnorthwest then return "north-north-west"
    else return tostring(direction) end
end