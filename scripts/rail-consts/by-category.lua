local TYPE_TO_CATEGORY = require("scripts.rail-consts.raw.type-to-category")
local BY_TYPE = require("scripts.rail-consts.by-type")

--- @type { [RailEntityType]: { [EntityDirection]: RailCategoryConsts } }
local BY_CATEGORY = {}

for type, category in pairs(TYPE_TO_CATEGORY) do
    BY_CATEGORY[category] = BY_TYPE[type]
end

return BY_CATEGORY
