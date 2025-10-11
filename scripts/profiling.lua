-- Currently testing fmtk profiler mode more.
if not DEBUG_MODE then
    return {
        register = function() end,
        report = function() end
    }
end

local profilers = {}

local function createProfiler(func)
    local profiler = {
        calls = 0,
        timer = helpers.create_profiler(true),
    }

    return profiler, function(...)
        profiler.calls = profiler.calls + 1
        profiler.timer.restart()
        local result = table.pack(func(...))
        profiler.timer.stop()
        return table.unpack(result)
    end
end

local function register(entity, name, keys)
    local objectProfilers = {}

    if keys then
        for _, k in ipairs(keys) do
            local v = entity[k]

            if type(v) == "function" then
                local profiler
                profiler, entity[k] = createProfiler(v)
                objectProfilers[k] = profiler
            end
        end
    else
        for k, v in pairs(entity) do
            if type(v) == "function" then
                local profiler
                profiler, entity[k] = createProfiler(v)
                objectProfilers[k] = profiler
            end
        end
    end

    profilers[name] = objectProfilers
end

local function report()
    for oName, methods in pairs(profilers) do
        local message = {"", { "debug.profiler-report", oName }}

        for mName, profiler in pairs(methods) do
            table.insert(message, { "debug.profiler-line", mName, profiler.timer, profiler.calls })
            profiler.calls = 0
            profiler.timer = helpers.create_profiler(true)
        end

        drpDebug(message)
    end
end

return {
    register = register,
    report = report
}
