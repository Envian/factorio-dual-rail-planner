

-- Currently unused. Dynamcially registering events takes a few ms per time, while
-- just letting the ontick go brr is unlikely to have a notable performance impact.





-- local RailBuilder = require("scripts.classes.rail-builder")

-- local reportProfiling = require("scripts.profiling").report

-- local function unregister()
--     if not storage.onticks.registered then return end
--     storage.onticks.registered = false
--     script.on_event(defines.events.on_tick, nil)
-- end

-- local function onTickHandler(event)
--     for _, parser in pairs(storage.parsers) do
--         local path = parser:getPath()
--         if path then
--             local builder = RailBuilder.new(parser.player, parser.planner, path)
--             builder:buildPath()
--             builder:addExtras()
--             builder:finish()
--             reportProfiling()
--         end
--     end

--     -- Unregister for performance.
--     unregister()
-- end

-- local function register()
--     -- if storage.onticks.registered then return end
--     -- storage.onticks.registered = true
--     script.on_event(defines.events.on_tick, onTickHandler)
-- end

-- -- Currently this is the only conditional event registration.
-- -- script.on_load(function()
-- --     if storage.onticks.registered then
-- --         script.on_event(defines.events.on_tick, onTickHandler)
-- --     elseif __Profiler then
-- --         -- FMTK Profiler doesn't work with temporarily registered planners.
-- --         register()
-- --         register = function() end
-- --         unregister = function() end
-- --     end
-- -- end)

-- register()
-- register = function() end
-- unregister = function() end

-- return {
--     register = register
-- }
