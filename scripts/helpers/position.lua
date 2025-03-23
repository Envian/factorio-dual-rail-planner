local position = {}

function position.add(a, b)
    return {x = a.x + b.x, y = a.y + b.y}
end

function position.subtract(a, b)
    return {x = a.x - b.x, y = a.y - b.y}
end

return position
