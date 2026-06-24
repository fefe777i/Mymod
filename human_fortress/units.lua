-- ============================================
-- units.lua - ПОВНА ВЕРСІЯ З ПІДТРИМКОЮ ОКРЕМИХ ФАЙЛІВ ЮНІТІВ
-- ============================================

-- Додай це на початку units.lua
human_fortress.update_gui = function(player)
    if human_fortress.update_hud then
        human_fortress.update_hud(player)
    end
    if unified_inventory and unified_inventory.get_formspec then
        player:set_inventory_formspec(unified_inventory.get_formspec(player))
    end
end

-- ============================================
-- ЗАВАНТАЖЕННЯ ЮНІТІВ З ОКРЕМИХ ФАЙЛІВ
-- ============================================

human_fortress.units = human_fortress.units or {}
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
    "elite_warrior.lua"
}

for _, file in ipairs(unit_files) do
    local filepath = units_path .. file
    local f = io.open(filepath, "r")
    if f then
        f:close()
        minetest.log("action", "[Human Fortress] Завантаження юніта: " .. file)
        dofile(filepath)
    else
        minetest.log("warning", "[Human Fortress] Файл юніта не знайдено: " .. filepath)
    end
end

minetest.log("action", "[Human Fortress] Завантажено юнітів: " .. dump(human_fortress.units_list))

-- ============================================
-- ФУНКЦІЯ ПЕРЕВІРКИ РЕСУРСІВ
-- ============================================
local function get_player_resources(player_name)
    if not human_fortress.edos_data then human_fortress.edos_data = {} end
    if not human_fortress.edos_data[player_name] then
        human_fortress.edos_data[player_name] = {
            score = 0,
            wood = 0,
            stone = 0,
            food = 0,
            ether = 0
        }
    end
    return human_fortress.edos_data[player_name]
end

-- ============================================
-- СТВОРЕННЯ ЮНІТА
-- ============================================
-- Заміни функцію human_fortress.create_unit у файлі units.lua:

human_fortress.create_unit = function(type, pos, owner)
    if not human_fortress.players then human_fortress.players = {} end
    if not human_fortress.players[owner] then
        human_fortress.players[owner] = {units = {}, selected = {}, last_id = 0}
    end
    local player_data = human_fortress.players[owner]
    
    local unit_info = human_fortress.units_list[type]
    if not unit_info then return nil end
    
    -- Перевірка ресурсів
    local resources = get_player_resources(owner)
    for resource, amount in pairs(unit_info.cost) do
        if (resources[resource] or 0) < amount then
            minetest.chat_send_player(owner, "❌ Не вистачає " .. resource)
            return nil
        end
    end

    -- Створення об'єкта
    local spawn_pos = {x = pos.x, y = pos.y + 1, z = pos.z}
    local entity_obj = minetest.add_entity(spawn_pos, unit_info.entity)
    
    if entity_obj then
        local luaentity = entity_obj:get_luaentity()
        if luaentity then
            -- ГАРАНТОВАНА ІНІЦІАЛІЗАЦІЯ (виправляє твій виліт)
            luaentity.unit_data = luaentity.unit_data or {}
            
            -- Рахуємо унікальний ID, який не збивається
            player_data.last_id = (player_data.last_id or 0) + 1
            local id = player_data.last_id

            -- Заповнюємо дані
            luaentity.unit_data.id = id
            luaentity.unit_data.owner = owner
            luaentity.unit_data.type = type
            luaentity.unit_data.health = unit_info.health
            luaentity.unit_data.speed = unit_info.speed
            luaentity.unit_data.profession = unit_info.profession
            
            -- Віднімаємо ресурси ТІЛЬКИ після успішного спавну
            for resource, amount in pairs(unit_info.cost) do
                resources[resource] = resources[resource] - amount
            end

            player_data.units[id] = luaentity
            minetest.chat_send_player(owner, "✅ Створено " .. unit_info.name)
            return entity_obj
        end
    end
    return nil
end

-- ============================================
-- ДОДАТКОВІ ФУНКЦІЇ ДЛЯ РОБОТИ З ЮНІТАМИ
-- ============================================

-- Отримання списку юнітів гравця
function get_player_units(player_name)
    if not human_fortress.players or not human_fortress.players[player_name] then return {} end
    return human_fortress.players[player_name].units or {}
end

-- Отримання професії юніта
function get_unit_profession(unit)
    if not unit or not unit.unit_data then return "unknown" end
    return unit.unit_data.profession or "basic"
end

-- Отримання кольору юніта (для мінімапу)
function get_unit_color(unit, viewer_name)
    if not unit or not unit.unit_data then return "#FFFFFF" end
    if unit.unit_data.owner == viewer_name then
        return "#FFFFFF"  -- Білий для своїх
    else
        return "#FF0000"  -- Червоний для чужих
    end
end

-- Оновлення позиції юніта (для мінімапу)
function get_unit_position(unit)
    if not unit or not unit.object then return nil end
    return unit.object:get_pos()
end

-- ============================================
-- КОМАНДИ ДЛЯ ЮНІТІВ
-- ============================================
human_fortress.command_unit = function(unit_id, owner, command, target)
    if not human_fortress.players or not human_fortress.players[owner] then return false end
    local unit = human_fortress.players[owner].units[unit_id]
    if not unit or not unit.unit_data then return false end
    
    unit.unit_data.command = command
    unit.unit_data.target = target
    
    return true
end

-- Видалення юніта
human_fortress.remove_unit = function(unit_id, owner)
    if not human_fortress.players or not human_fortress.players[owner] then return false end
    local units = human_fortress.players[owner].units
    if units and units[unit_id] then
        local unit = units[unit_id]
        if unit.object then
            unit.object:remove()
        end
        units[unit_id] = nil
        return true
    end
    return false
end

-- ============================================
-- ОБРОБНИК ПРИ ВИХОДІ ГРАВЦЯ
-- ============================================
minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    if human_fortress.players and human_fortress.players[name] then
        -- Не видаляємо юнітів, вони залишаються в світі
        -- Але очищаємо вибране
        human_fortress.players[name].selected = {}
    end
end)

-- ============================================
-- ОБРОБНИК ПРИ ВХОДІ ГРАВЦЯ
-- ============================================
minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    if not human_fortress.players then human_fortress.players = {} end
    if not human_fortress.players[name] then
        human_fortress.players[name] = {units = {}, selected = {}}
    end
end)

print("[Human Fortress] Units system loaded - модульна система з окремими файлами юнітів")
print("[Human Fortress] Всього юнітів: " .. dump(human_fortress.units_list))