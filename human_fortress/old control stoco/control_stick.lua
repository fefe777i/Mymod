-- ============================================
-- СТАРА СИСТЕМА КЕРУВАННЯ - 8 ПРЕДМЕТІВ
-- ============================================

-- Дані гравців для режиму командування
local cmd_mode = {}

-- ============================================
-- ФУНКЦІЯ БУДІВНИЦТВА (в control_stick.lua)
-- ============================================

local function build_structure(player_name, building_type, pos)
    -- ПЕРЕВІРКА ЧИ Є ТАКА БУДІВЛЯ
    if not BUILDING_SCHEMATICS or not BUILDING_SCHEMATICS[building_type] then
        minetest.chat_send_player(player_name, "❌ Немає схеми для: " .. building_type)
        return false
    end
    
    local schematic = BUILDING_SCHEMATICS[building_type]
    
    -- ПЕРЕВІРКА РЕСУРСІВ
    if human_fortress.edos_data and human_fortress.edos_data[player_name] then
        local resources = human_fortress.edos_data[player_name]
        for res, amount in pairs(schematic.cost) do
            if (resources[res] or 0) < amount then
                minetest.chat_send_player(player_name, "❌ Недостатньо " .. res .. " (треба " .. amount .. ")")
                return false
            end
        end
        
        -- ЗНІМАЄМО РЕСУРСИ
        for res, amount in pairs(schematic.cost) do
            resources[res] = (resources[res] or 0) - amount
        end
    end
    
    -- ВИКЛИКАЄМО on_built ПЕРЕД БУДІВНИЦТВОМ? НІ, ПІСЛЯ!
    local built_success = false
    
    -- ЯКЩО Є WorldEdit СХЕМАТ
    if schematic.schematic then
        local filepath = minetest.get_modpath("human_fortress") .. "/schematics/" .. schematic.schematic
        local file = io.open(filepath, "rb")
        
        if not file then
            minetest.chat_send_player(player_name, "❌ Файл схемату не знайдено: " .. schematic.schematic)
            return false
        end
        
        local data = file:read("*all")
        file:close()
        
        if worldedit and worldedit.deserialize then
            worldedit.deserialize(pos, data)
            built_success = true
            minetest.chat_send_player(player_name, "✅ Схемат розміщено!")
        else
            minetest.chat_send_player(player_name, "❌ WorldEdit не завантажено!")
            return false
        end
        
    -- ЯКЩО Є СПИСОК БЛОКІВ
    elseif schematic.nodes then
        local base_pos = {x = pos.x, y = pos.y + 1, z = pos.z}
        
        for _, node_data in ipairs(schematic.nodes) do
            local np = vector.add(base_pos, node_data.pos)
            local cur = minetest.get_node(np)
            if cur.name ~= "air" and cur.name ~= "ignore" then
                minetest.chat_send_player(player_name, "❌ Місце зайняте!")
                return false
            end
        end
        
        for _, node_data in ipairs(schematic.nodes) do
            local np = vector.add(base_pos, node_data.pos)
            minetest.set_node(np, {name = node_data.name})
        end
        built_success = true
    end
    
    -- ПІСЛЯ БУДІВНИЦТВА - ВИКЛИКАЄМО on_built
    if built_success and schematic.on_built then
        minetest.chat_send_player(player_name, "🏗️ Викликаю on_built для " .. building_type)
        schematic.on_built(player_name, pos)
    end
    
    minetest.chat_send_player(player_name, "✅ Побудовано: " .. (schematic.name or building_type))
    return true
end

-- Вхід в режим командування
local function enter_command_mode(player)
    local name = player:get_player_name()
    
    if cmd_mode[name] then
        minetest.chat_send_player(name, "❌ Ви вже в режимі командування!")
        return
    end
    
    -- Зберігаємо інвентар
    local inv = player:get_inventory()
    cmd_mode[name] = {
        inv = {},
        pos = player:get_pos(),
        hp = player:get_hp()
    }
    
    -- Зберігаємо поточний інвентар
    for i=1, inv:get_size("main") do
        local stack = inv:get_stack("main", i)
        if not stack:is_empty() then
            cmd_mode[name].inv[i] = stack:to_string()
        end
    end
    
    -- Очищаємо інвентар
    inv:set_list("main", {})
    
    -- Видаємо предмети керування (9 штук, включаючи вихід)
    local items = {
        "human_fortress:cmd_select",    -- 1. Виділення
        "human_fortress:cmd_move",       -- 2. Рух
        "human_fortress:cmd_gather",     -- 3. Збір
        "human_fortress:cmd_build",      -- 4. Будівництво
        "human_fortress:cmd_attack",     -- 5. Атака
        "human_fortress:cmd_enter",      -- 6. Увійти
        "human_fortress:cmd_repair",     -- 7. Ремонт
        "human_fortress:cmd_destroy",    -- 8. Знищення
        "human_fortress:cmd_exit",       -- 9. Вихід
    }
    
    for i, item in ipairs(items) do
        inv:set_stack("main", i, item .. " 1")
    end
    
    -- Телепорт вгору і політ
    local pos = player:get_pos()
    pos.y = pos.y + 30
    player:set_pos(pos)
    
    player:set_physics_override({
        speed = 1.2,
        jump = 1.5,
        gravity = 0,
    })
    
    -- Збільшена дальність
    player:set_properties({reach = 30.0})
    
    minetest.chat_send_player(name, "=====================================")
    minetest.chat_send_player(name, "🎮 РЕЖИМ КОМАНДУВАННЯ")
    minetest.chat_send_player(name, "=====================================")
    minetest.chat_send_player(name, "1 - Виділення юнітів")
    minetest.chat_send_player(name, "2 - Рух")
    minetest.chat_send_player(name, "3 - Збір ресурсів")
    minetest.chat_send_player(name, "4 - Будівництво")
    minetest.chat_send_player(name, "5 - Атака")
    minetest.chat_send_player(name, "6 - Увійти в будівлю")
    minetest.chat_send_player(name, "7 - Ремонт")
    minetest.chat_send_player(name, "8 - Знищення")
    minetest.chat_send_player(name, "9 - Вихід")
    minetest.chat_send_player(name, "=====================================")
end

-- Вихід з режиму командування
local function exit_command_mode(player)
    local name = player:get_player_name()
    local data = cmd_mode[name]
    
    if not data then return end
    
    -- Повертаємо на землю
    if data.pos then
        player:set_pos(data.pos)
    end
    
    -- Вимкаємо політ
    player:set_physics_override({
        speed = 1,
        jump = 1,
        gravity = 1,
    })
    
    -- Стандартна дальність
    player:set_properties({reach = 4.0})
    
    -- Очищаємо інвентар
    local inv = player:get_inventory()
    inv:set_list("main", {})
    
    -- Відновлюємо старий інвентар
    if data.inv then
        for i, stack in pairs(data.inv) do
            inv:set_stack("main", i, ItemStack(stack))
        end
    end
    
    cmd_mode[name] = nil
    minetest.chat_send_player(name, "🎮 Режим командування вимкнено")
end

-- Функція для отримання виділених юнітів
local function get_selected_units(player)
    local name = player:get_player_name()
    if not human_fortress.players or not human_fortress.players[name] then return {} end
    return human_fortress.players[name].selected or {}
end

-- Функція для встановлення виділених юнітів
local function set_selected_units(player, units)
    local name = player:get_player_name()
    if not human_fortress.players then human_fortress.players = {} end
    if not human_fortress.players[name] then human_fortress.players[name] = {units = {}, selected = {}} end
    human_fortress.players[name].selected = units
end

-- ============================================
-- 1. ПРЕДМЕТ - ВИДІЛЕННЯ
-- ============================================

minetest.register_tool("human_fortress:cmd_select", {
    description = "🎮 Виділення юнітів (ЛКМ - область, Shift+ЛКМ - всі)",
    inventory_image = "human_fortress_cmd_select.png",
    
    on_use = function(itemstack, user, pointed_thing)
        local name = user:get_player_name()
        if not cmd_mode[name] then return end
        
        local ctrl = user:get_player_control()
        local selected = {}
        
        if pointed_thing and pointed_thing.type == "node" then
            local pos = pointed_thing.under
            
            if ctrl.aux1 then
                -- Виділити всіх
                if human_fortress.players and human_fortress.players[name] then
                    for id, unit in pairs(human_fortress.players[name].units or {}) do
                        if unit and unit.object then
                            table.insert(selected, id)
                        end
                    end
                end
                minetest.chat_send_player(name, "✅ Виділено ВСІХ юнітів: " .. #selected)
            else
                -- Виділити область
                if human_fortress.players and human_fortress.players[name] then
                    for id, unit in pairs(human_fortress.players[name].units or {}) do
                        if unit and unit.object then
                            local upos = unit.object:get_pos()
                            if upos and vector.distance(pos, upos) < 10 then
                                table.insert(selected, id)
                            end
                        end
                    end
                end
                minetest.chat_send_player(name, "✅ Виділено юнітів: " .. #selected)
            end
            
            set_selected_units(user, selected)
        end
        
        return itemstack
    end,
    
    on_place = function(itemstack, placer)
        -- Виділити всіх
        local name = placer:get_player_name()
        if not cmd_mode[name] then return end
        
        local selected = {}
        if human_fortress.players and human_fortress.players[name] then
            for id, unit in pairs(human_fortress.players[name].units or {}) do
                if unit and unit.object then
                    table.insert(selected, id)
                end
            end
        end
        
        set_selected_units(placer, selected)
        minetest.chat_send_player(name, "✅ Виділено ВСІХ юнітів: " .. #selected)
        return itemstack
    end
})

-- ============================================
-- 2. ПРЕДМЕТ - РУХ
-- ============================================

minetest.register_tool("human_fortress:cmd_move", {
    description = "🎮 Рух юнітів (ПКМ - точка призначення)",
    inventory_image = "human_fortress_cmd_move.png",
    
    on_use = function(itemstack, user, pointed_thing)
        local name = user:get_player_name()
        if not cmd_mode[name] then return end
        
        if pointed_thing and pointed_thing.type == "node" then
            local pos = pointed_thing.under
            local target = {x=pos.x+0.5, y=pos.y+1, z=pos.z+0.5}
            
            local selected = get_selected_units(user)
            
            if #selected == 0 then
                minetest.chat_send_player(name, "❌ Немає виділених юнітів!")
                return
            end
            
            for _, id in ipairs(selected) do
                local unit = human_fortress.players[name].units[id]
                if unit and unit.object then
                    unit.unit_data.command = "move"
                    unit.unit_data.target = target
                end
            end
            
            minetest.chat_send_player(name, "🚶 Рух: " .. #selected .. " юнітів")
        end
        
        return itemstack
    end
})

-- ============================================
-- 3. ПРЕДМЕТ - ЗБІР РЕСУРСІВ
-- ============================================

minetest.register_tool("human_fortress:cmd_gather", {
    description = "🎮 Збір ресурсів (ПКМ - ресурс)",
    inventory_image = "human_fortress_cmd_gather.png",
    
    on_use = function(itemstack, user, pointed_thing)
        local name = user:get_player_name()
        if not cmd_mode[name] then return end
        
        if pointed_thing and pointed_thing.type == "node" then
            local pos = pointed_thing.under
            local node = minetest.get_node(pos)
            
            -- Перевіряємо чи це ресурс
            local is_resource = false
            
            if node.name:find("tree") or node.name:find("wood") or node.name:find("ether") then
                is_resource = true
            elseif node.name:find("stone") or node.name:find("cobble") then
                is_resource = true
            elseif node.name:find("wheat") or node.name:find("food") then
                is_resource = true
            end
            
            if is_resource then
                local selected = get_selected_units(user)
                
                if #selected == 0 then
                    minetest.chat_send_player(name, "❌ Немає виділених юнітів!")
                    return
                end
                
                for _, id in ipairs(selected) do
                    local unit = human_fortress.players[name].units[id]
                    if unit and unit.object then
                        unit.unit_data.command = "gather"
                        unit.unit_data.target = pos
                    end
                end
                
                minetest.chat_send_player(name, "📦 Збір: " .. #selected .. " юнітів")
            else
                minetest.chat_send_player(name, "❌ Це не ресурс!")
            end
        end
        
        return itemstack
    end
})

-- ============================================
-- 4. ПРЕДМЕТ - БУДІВНИЦТВО
-- ============================================

minetest.register_tool("human_fortress:cmd_build", {
    description = "🎮 Будівництво (ПКМ - вибрати місце + меню)",
    inventory_image = "human_fortress_cmd_build.png",
    
    on_place = function(itemstack, placer, pointed_thing)
        local name = placer:get_player_name()
        if not cmd_mode or not cmd_mode[name] then 
            minetest.chat_send_player(name, "❌ Ти не в режимі командування!")
            return 
        end
        
        if pointed_thing and pointed_thing.type == "node" then
            local pos = pointed_thing.under
            
            -- Зберігаємо позицію
            if not cmd_mode[name].build then 
                cmd_mode[name].build = {} 
            end
            cmd_mode[name].build.pos = pos
            
            -- ДЕБАГ
            minetest.chat_send_player(name, "📌 Позиція збережена: " .. minetest.pos_to_string(pos))
            
-- Показуємо меню
local formspec = "size[6,9]" ..
    "bgcolor[#0A0A1A;true]" ..
    "box[0,0;6,0.8;#2D2D44]" ..
    "label[0.5,0.2;🏗️ ВИБІР БУДІВЛІ]" ..
    "button[0.5,1.2;5,0.8;build_townhall;🏛️ Ратуша]" ..
    "button[0.5,2.0;5,0.8;build_farm;🌾 Ферма]" ..
    "button[0.5,2.8;5,0.8;build_barracks;⚔️ Казарми]" ..
    "button[0.5,3.6;5,0.8;build_wall;🧱 Стіна]" ..
    "button[0.5,4.4;5,0.8;build_tower;🗼 Вежа]" ..
    "button[0.5,5.2;5,0.8;build_house;🏠 Дім]" ..
    "button[0.5,6.0;5,0.8;build_market;🏪 Ринок]"

            
            minetest.show_formspec(name, "human_fortress:build", formspec)
            minetest.chat_send_player(name, "📋 Меню відкрито")
        else
            minetest.chat_send_player(name, "❌ Натисни на блок!")
        end
        
        return itemstack
    end
})

-- ============================================
-- 5. ПРЕДМЕТ - АТАКА
-- ============================================

minetest.register_tool("human_fortress:cmd_attack", {
    description = "🎮 Атака (ПКМ - по ворогу)",
    inventory_image = "human_fortress_cmd_attack.png",
    
    on_use = function(itemstack, user, pointed_thing)
        local name = user:get_player_name()
        if not cmd_mode[name] then return end
        
        local target_pos = nil
        
        if pointed_thing.type == "object" then
            local obj = pointed_thing.ref
            if obj then
                target_pos = obj:get_pos()
            end
        elseif pointed_thing.type == "node" then
            target_pos = pointed_thing.under
        end
        
        if target_pos then
            local selected = get_selected_units(user)
            
            if #selected == 0 then
                minetest.chat_send_player(name, "❌ Немає виділених юнітів!")
                return
            end
            
            for _, id in ipairs(selected) do
                local unit = human_fortress.players[name].units[id]
                if unit and unit.object then
                    unit.unit_data.command = "attack"
                    unit.unit_data.target = target_pos
                end
            end
            
            minetest.chat_send_player(name, "⚔️ Атака: " .. #selected .. " юнітів")
        end
        
        return itemstack
    end
})

-- ============================================
-- 6. ПРЕДМЕТ - УВІЙТИ В БУДІВЛЮ
-- ============================================

minetest.register_tool("human_fortress:cmd_enter", {
    description = "🎮 Увійти в будівлю",
    inventory_image = "human_fortress_cmd_enter.png",
    
    on_use = function(itemstack, user, pointed_thing)
        local name = user:get_player_name()
        if not cmd_mode[name] then return end
        
        if pointed_thing and pointed_thing.type == "node" then
            local pos = pointed_thing.under
            local node = minetest.get_node(pos)
            
            local selected = get_selected_units(user)
            
            if #selected == 0 then
                minetest.chat_send_player(name, "❌ Немає виділених юнітів!")
                return
            end
            
            for _, id in ipairs(selected) do
                local unit = human_fortress.players[name].units[id]
                if unit and unit.object then
                    unit.unit_data.command = "enter"
                    unit.unit_data.target = pos
                end
            end
            
            minetest.chat_send_player(name, "🚪 Вхід: " .. #selected .. " юнітів")
        end
        
        return itemstack
    end
})


-- ============================================
-- 7. ПРЕДМЕТ - РЕМОНТ
-- ============================================

minetest.register_tool("human_fortress:cmd_repair", {
    description = "🎮 Ремонт будівлі",
    inventory_image = "human_fortress_cmd_repair.png",
    
    on_use = function(itemstack, user, pointed_thing)
        local name = user:get_player_name()
        if not cmd_mode[name] then return end
        
        if pointed_thing and pointed_thing.type == "node" then
            local pos = pointed_thing.under
            
            local selected = get_selected_units(user)
            
            if #selected == 0 then
                minetest.chat_send_player(name, "❌ Немає виділених юнітів!")
                return
            end
            
            for _, id in ipairs(selected) do
                local unit = human_fortress.players[name].units[id]
                if unit and unit.object then
                    unit.unit_data.command = "repair"
                    unit.unit_data.target = pos
                end
            end
            
            minetest.chat_send_player(name, "🔧 Ремонт: " .. #selected .. " юнітів")
        end
        
        return itemstack
    end
})
-- ============================================
-- 8. ПРЕДМЕТ - ЗНИЩЕННЯ
-- ============================================

minetest.register_tool("human_fortress:cmd_destroy", {
    description = "🎮 Знищення будівлі (Shift+ПКМ)",
    inventory_image = "human_fortress_cmd_destroy.png",
    
    on_use = function(itemstack, user, pointed_thing)
        local name = user:get_player_name()
        if not cmd_mode[name] then return end
        
        local ctrl = user:get_player_control()
        
        if pointed_thing and pointed_thing.type == "node" and ctrl.aux1 then
            local pos = pointed_thing.under
            minetest.remove_node(pos)
            minetest.chat_send_player(name, "💥 Будівлю знищено!")
        elseif pointed_thing and pointed_thing.type == "node" then
            minetest.chat_send_player(name, "⚠️ Утримуй Shift для знищення")
        end
        
        return itemstack
    end
})



-- ============================================
-- 9. ПРЕДМЕТ - ВИХІД
-- ============================================

minetest.register_tool("human_fortress:cmd_exit", {
    description = "🎮 Вийти з режиму командування",
    inventory_image = "human_fortress_cmd_exit.png",
    
    on_use = function(itemstack, user)
        exit_command_mode(user)
        return itemstack
    end
})


-- ============================================
-- ОБРОБНИК МЕНЮ БУДІВНИЦТВА (ПРАВИЛЬНИЙ!)
-- ============================================

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "human_fortress:build" then return end
    
    local name = player:get_player_name()
    
    if not cmd_mode[name] or not cmd_mode[name].build then 
        minetest.chat_send_player(name, "❌ Помилка: не в режимі командування")
        return 
    end
    
    local build_pos = cmd_mode[name].build.pos
    if not build_pos then 
        minetest.chat_send_player(name, "❌ Не вибрано позицію для будівництва")
        return 
    end
    
    for field, _ in pairs(fields) do
        if field:sub(1,6) == "build_" then
            local building_type = field:sub(7)
            
            -- ДЕБАГ
            minetest.chat_send_player(name, "🏗️ Будую: " .. building_type)
            
            -- ВИКЛИКАЄМО ФУНКЦІЮ БУДІВНИЦТВА
            if build_structure then
                build_structure(name, building_type, build_pos)
            else
                minetest.chat_send_player(name, "❌ ПОМИЛКА: функція build_structure не знайдена!")
            end
            
            -- ОЧИЩАЄМО ПОЗИЦІЮ
            cmd_mode[name].build.pos = nil
            
            -- ЗАКРИВАЄМО МЕНЮ
            minetest.close_formspec(name, "human_fortress:build")
            break
        end
    end
end)

-- ============================================
-- КНОПКА ДЛЯ ВХОДУ В РЕЖИМ (в меню вилки)
-- ============================================

function toggle_command_mode(player)
    local name = player:get_player_name()
    
    if cmd_mode[name] then
        exit_command_mode(player)
    else
        enter_command_mode(player)
    end
end


-- ПЕРЕВІРКА ЩО В ПАПЦІ BUILDINGS
minetest.after(5, function()
    local path = minetest.get_modpath("human_fortress") .. "/buildings"
    minetest.chat_send_all("📁 Папка buildings: " .. path)
    
    -- Спробуємо знайти файли
    local files = minetest.get_dir_list(path)
    if files then
        for _, file in ipairs(files) do
            minetest.chat_send_all("   📄 " .. file)
        end
    else
        minetest.chat_send_all("❌ Папка не знайдена або порожня")
    end
end)
print("[Human Fortress] Стара система керування з 8 предметами завантажена!")