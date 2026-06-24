-- ============================================
-- ЗАВАНТАЖЕННЯ ВСІХ ЮНІТІВ
-- ============================================

human_fortress.units_list = human_fortress.units_list or {}

local units_path = minetest.get_modpath("human_fortress") .. "/units/"
local unit_files = {
    "worker.lua",
    "lumberjack.lua",
    "miner.lua",
    "farmer.lua",
    "warrior.lua",
    "samurai.lua",
    "archer.lua",
}

for _, file in ipairs(unit_files) do
    local filepath = units_path .. file
    local f = io.open(filepath, "r")
    if f then
        f:close()
        dofile(filepath)
        minetest.log("action", "[Human Fortress] Файл юніта завантажено: " .. file)
    else
        minetest.log("warning", "[Human Fortress] Файл юніта не знайдено: " .. filepath)
    end
end