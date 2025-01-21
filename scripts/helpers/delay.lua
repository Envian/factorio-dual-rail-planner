local nextTickCallbacks = nil

local function onNextTickHandler(event)
    for _, callback in pairs(nextTickCallbacks[game.tick] or {}) do
        callback(event)
    end
    nextTickCallbacks[game.tick] = nil

    if table_size(nextTickCallbacks) == 0 then
        script.on_event(defines.events.on_tick, nil)
        nextTickCallbacks = nil
    end
end

return function(ticks, callback)
    assert(type(ticks) == "number" and ticks >= 0, "delay must be a positive number")

    if not nextTickCallbacks then
        nextTickCallbacks = {}
        script.on_event(defines.events.on_tick, onNextTickHandler)
    end

    local callbacks = nextTickCallbacks[ticks + game.tick]

    if not callbacks then
        callbacks = {}
        nextTickCallbacks[ticks + game.tick] = callbacks
    end

    table.insert(callbacks, callback)
end
