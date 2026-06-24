-- ai.lua - Версія з професіями, інвентарем та здачею ресурсів

-- Таблиці ресурсів - ТІЛЬКИ ЕФІРНІ ДЕРЕВА!
human_fortress.wood_nodes = human_fortress.wood_nodes or {
    "human_fortress:ether_tree_small",
    "human_fortress:ether_tree_small_plus",
    "human_fortress:ether_tree_medium",
    "human_fortress:ether_tree_big",
}

human_fortress.stone_nodes = human_fortress.stone_nodes or {
    "default:stone", 
    "default:cobble", 
    "human_fortress:stone"
}

human_fortress.food_nodes = human_fortress.food_nodes or {
    "farming:wheat_8", 
    "human_fortress:food_source"
}

-- ДОДАНО: таблиця будівель
human_fortress.buildings = human_fortress.buildings or {}

-- НАЛАШТУВАННЯ ПРОФЕСІЙ
human_fortress.profession_config = {
    basic = {
        can_gather = {"wood", "stone", "food"},
        gather_amount = 1,
        inventory_size = 500
    },
    lumberjack = {
        can_gather = {"wood"},
        gather_amount = 1,  -- ЗМІНЕНО: тепер 1, бо це ефір
        inventory_size = 500
    },
    miner = {
        can_gather = {"stone"},
        gather_amount = 5,
        inventory_size = 500
    },
    farmer = {
        can_gather = {"food"},
        gather_amount = 5,
        inventory_size = 500
    },
    warrior = {
        can_gather = {},
        gather_amount = 0,
        inventory_size = 0
    },
    archer = {
        can_gather = {},
        gather_amount = 0,
        inventory_size = 0
    }
}
-- ============================================
-- ОБГОРТКА ДЛЯ СУМІСНОСТІ
-- ============================================

human_fortress.process_ai = function(unit_data, dtime, current_pos)
    if not unit_data or not current_pos then return end
    if not unit_data.command or unit_data.health <= 0 then return end
    
    -- ВИКЛИКАЄМО ВІДПОВІДНУ ФУНКЦІЮ
    if unit_data.command == "move" then
        human_fortress.move_ai(unit_data, dtime, current_pos, unit_data.ai_data)
    elseif unit_data.command == "gather" then
        human_fortress.gather_ai(unit_data, dtime, current_pos, unit_data.ai_data)
    elseif unit_data.command == "deposit" then
        human_fortress.deposit_ai(unit_data, dtime, current_pos, unit_data.ai_data)
    end
end
-- ФУНКЦІЇ ПЕРЕВІРКИ
human_fortress.is_wood = function(nodename)
    for _, name in ipairs(human_fortress.wood_nodes) do
        if nodename == name then return true end
    end
    return false
end

human_fortress.is_stone = function(nodename)
    for _, name in ipairs(human_fortress.stone_nodes) do
        if nodename == name then return true end
    end
    return false
end

human_fortress.is_food = function(nodename)
    for _, name in ipairs(human_fortress.food_nodes) do
        if nodename == name then return true end
    end
    return false
end

-- ФУНКЦІЯ ДЛЯ ОТРИМАННЯ ТИПУ РЕСУРСУ
human_fortress.get_resource_type = function(nodename)
    if human_fortress.is_wood(nodename) then 
        return "wood"  -- ЦЕ ЕФІР, АЛЕ В СИСТЕМІ wood
    end
    if human_fortress.is_stone(nodename) then return "stone" end
    if human_fortress.is_food(nodename) then return "food" end
    return nil
end

-- ФУНКЦІЯ ДЛЯ ЗБОРУ З ЕФІРНОГО ДЕРЕВА
local function gather_from_ether_tree(pos, puncher)
    if not puncher or not puncher:is_player() then return 0 end
    
    local meta = minetest.get_meta(pos)
    local remaining = meta:get_int("remaining")
    local player_name = puncher:get_player_name()
    
    if remaining <= 1 then
        -- Останній удар
        minetest.remove_node(pos)
        return 1
    else
        meta:set_int("remaining", remaining - 1)
        return 1
    end
end

-- ПЕРЕВІРКА ЧИ МОЖЕ ПРОФЕСІЯ ЗБИРАТИ РЕСУРС
human_fortress.can_gather_resource = function(profession, resource_type)
    local config = human_fortress.profession_config[profession]
    if not config then return false end
    
    for _, res in ipairs(config.can_gather) do
        if res == resource_type then return true end
    end
    return false
end

-- ОТРИМАТИ КІЛЬКІСТЬ РЕСУРСІВ ЗА РАЗ
human_fortress.get_gather_amount = function(profession)
    local config = human_fortress.profession_config[profession]
    return config and config.gather_amount or 1
end

-- ОТРИМАТИ РОЗМІР ІНВЕНТАРЯ
human_fortress.get_inventory_size = function(profession)
    local config = human_fortress.profession_config[profession]
    return config and config.inventory_size or 500
end

-- ПІДРАХУНОК ЗАГАЛЬНОЇ КІЛЬКОСТІ В ІНВЕНТАРІ
human_fortress.get_total_inventory = function(inventory)
    local total = 0
    for resource, amount in pairs(inventory) do
        total = total + amount
    end
    return total
end

-- ПОШУК НАЙБЛИЖЧОЇ РАТУШІ
human_fortress.find_nearest_townhall = function(current_pos, owner)
    if not current_pos or not owner then return nil end
    
    local radius = 20
    local min_pos = vector.subtract(current_pos, {x=radius, y=radius, z=radius})
    local max_pos = vector.add(current_pos, {x=radius, y=radius, z=radius})
    
    local positions = minetest.find_nodes_in_area(min_pos, max_pos, {"human_fortress:townhall"})
    
    if #positions == 0 then
        positions = minetest.find_nodes_in_area(min_pos, max_pos, {"human_fortress:townhall_block"})
    end
    
    if #positions == 0 then
        return nil
    end
    
    local nearest = nil
    local nearest_dist = math.huge
    
    for _, pos in ipairs(positions) do
        local dist = vector.distance(current_pos, pos)
        if dist < nearest_dist then
            nearest_dist = dist
            nearest = pos
        end
    end
    
    return nearest
end

-- ЗДАТИ РЕСУРСИ В РАТУШУ
human_fortress.deposit_resources = function(unit_data)
    local owner = unit_data.owner
    if not human_fortress.edos_data[owner] then return end
    
    local inventory = unit_data.inventory or {}
    
    for resource, amount in pairs(inventory) do
        -- ВСІ ресурси зберігаються в edos_data
        human_fortress.edos_data[owner][resource] = (human_fortress.edos_data[owner][resource] or 0) + amount
    end
    
    -- Очищуємо інвентар
    unit_data.inventory = {wood = 0, stone = 0, food = 0}
    
    -- Оновлюємо GUI
    local player = minetest.get_player_by_name(owner)
    if player and human_fortress.update_gui then 
        human_fortress.update_gui(player)
    end
end

-- ПОШУК РЕСУРСУ
human_fortress.find_nearest_resource = function(current_pos, resource_type, radius)
    if not current_pos then return nil end
    radius = radius or 10
    local resource_nodes = {}
    
    if resource_type == "wood" then
        resource_nodes = human_fortress.wood_nodes  -- ТІЛЬКИ ЕФІРНІ ДЕРЕВА!
    elseif resource_type == "stone" then
        resource_nodes = human_fortress.stone_nodes
    elseif resource_type == "food" then
        resource_nodes = human_fortress.food_nodes
    else
        return nil
    end
    
    local min_pos = vector.subtract(current_pos, {x=radius, y=radius, z=radius})
    local max_pos = vector.add(current_pos, {x=radius, y=radius, z=radius})
    
    local positions = minetest.find_nodes_in_area(min_pos, max_pos, resource_nodes)
    
    if #positions == 0 then return nil end
    
    local nearest = nil
    local nearest_dist = math.huge
    
    for _, pos in ipairs(positions) do
        local dist = vector.distance(current_pos, pos)
        if dist < nearest_dist then
            nearest_dist = dist
            nearest = pos
        end
    end
    
    return nearest
end

local function is_blocked(pos)
    if not pos then return false end
    local node = minetest.get_node(pos)
    local def = minetest.registered_nodes[node.name]
    return def and def.walkable
end

-- ============================================
-- РОЗУМНИЙ РУХ З ОБХОДОМ ПЕРЕШКОД
-- ============================================

human_fortress.smart_move = function(unit_data, current_pos, target_pos, dtime)
    if not current_pos or not target_pos then return end
    local ai = unit_data.ai_data
    local entity = unit_data.entity
    if not entity then return end

    -- ========================================
    -- 1. ПЕРЕВІРКА НА МІСЦІ
    -- ========================================
    local dist_to_target = vector.distance(current_pos, target_pos)
    if dist_to_target < 1.0 then
        entity:set_velocity({x=0, y=0, z=0})
        unit_data.is_moving = false
        return
    end

    -- ========================================
    -- 2. ПОШУК ШЛЯХУ (A*)
    -- ========================================
    local need_new_path = false
    
    if not ai.path then
        need_new_path = true
    elseif not ai.path_target then
        need_new_path = true
    elseif vector.distance(ai.path_target, target_pos) > 2 then
        need_new_path = true
    elseif ai.stuck_time and ai.stuck_time > 2 then
        need_new_path = true
        ai.stuck_time = 0
    end
    
    if need_new_path then
        -- ШУКАЄМО ШЛЯХ В РАДІУСІ 20 БЛОКІВ
        ai.path = minetest.find_path(current_pos, target_pos, 20, 1, 2, "A*")
        ai.path_target = vector.new(target_pos)
        
        if ai.path and #ai.path > 1 then
            ai.path_index = 2  -- ПРОПУСКАЄМО ПЕРШУ ТОЧКУ
        else
            -- ЯКЩО НЕМАЄ ШЛЯХУ - ЙДЕМО ПРЯМО, АЛЕ З ПЕРЕВІРКОЮ
            ai.path = nil
        end
    end

    -- ========================================
    -- 3. ВИЗНАЧЕННЯ НАСТУПНОЇ ТОЧКИ
    -- ========================================
    local next_pos = target_pos
    local use_path = false
    
    if ai.path and ai.path[ai.path_index] then
        next_pos = ai.path[ai.path_index]
        use_path = true
        
        -- ПЕРЕВІРКА ЧИ ДІЙШЛИ ДО ПРОМІЖНОЇ ТОЧКИ
        if vector.distance(current_pos, next_pos) < 1.0 then
            ai.path_index = ai.path_index + 1
            if ai.path[ai.path_index] then
                next_pos = ai.path[ai.path_index]
            else
                -- ДІЙШЛИ ДО КІНЦЯ ШЛЯХУ
                next_pos = target_pos
                ai.path = nil
            end
        end
    end

    -- ========================================
    -- 4. РОЗРАХУНОК НАПРЯМКУ
    -- ========================================
    local dir = vector.direction(current_pos, next_pos)
    dir.y = 0
    
    local len = math.sqrt(dir.x*dir.x + dir.z*dir.z)
    if len > 0.01 then
        dir.x = dir.x / len
        dir.z = dir.z / len
        
        -- ПОВОРОТ
        local yaw = math.atan2(dir.x, -dir.z)
        entity:set_yaw(yaw)
        
        -- РУХ
        local vel = entity:get_velocity() or {x=0, y=0, z=0}
        vel.x = dir.x * unit_data.speed
        vel.z = dir.z * unit_data.speed
        
        -- ========================================
        -- 5. ПЕРЕВІРКА ПЕРЕШКОД ТА СТРИБКИ
        -- ========================================
        local check_pos = vector.add(current_pos, {x=dir.x, y=1, z=dir.z})
        local check_node = minetest.get_node(check_pos)
        local def = minetest.registered_nodes[check_node.name]
        
        if def and def.walkable then
            -- ПЕРЕШКОДА - СТРИБАЄМО
            if ai.jump_cooldown <= 0 then
                vel.y = 6
                ai.jump_cooldown = 1.0
            else
                -- СПРОБУЄМО ОБІЙТИ (трохи вбік)
                local side_dir = {x = dir.z, y = 0, z = -dir.x}
                vel.x = side_dir.x * unit_data.speed * 0.7
                vel.z = side_dir.z * unit_data.speed * 0.7
            end
        end
        
        entity:set_velocity(vel)
        unit_data.is_moving = true
        ai.stuck_time = 0
    else
        -- НЕ МОЖЕМО ВИЗНАЧИТИ НАПРЯМОК
        entity:set_velocity({x=0, y=0, z=0})
        unit_data.is_moving = false
        ai.stuck_time = (ai.stuck_time or 0) + dtime
    end

    -- ========================================
    -- 6. ОНОВЛЕННЯ ТАЙМЕРІВ
    -- ========================================
    if ai.jump_cooldown > 0 then
        ai.jump_cooldown = ai.jump_cooldown - dtime
    end
end


-- ГОЛОВНИЙ ЦИКЛ AI
human_fortress.process_ai = function(unit_data, dtime, current_pos)
    if not unit_data or not current_pos then return end
    if not unit_data.command or unit_data.health <= 0 then return end
    
    -- Ініціалізація AI даних
    if not unit_data.ai_data then
        unit_data.ai_data = {
            stuck_time = 0, 
            last_pos = current_pos, 
            task_time = 0,
            jump_cooldown = 0, 
            path = nil, 
            path_index = 1,
            last_resource_type = nil,
        }
    end
    
    -- Ініціалізація інвентаря
    if not unit_data.inventory then
        unit_data.inventory = {wood = 0, stone = 0, food = 0}
    end
    
    local ai = unit_data.ai_data
    ai.task_time = ai.task_time + dtime
    ai.jump_cooldown = math.max(0, ai.jump_cooldown - dtime)
    
    -- ВИПРАВЛЕНО: перевірка на nil
    if ai.last_pos and vector.distance(current_pos, ai.last_pos) < 0.1 then
        ai.stuck_time = ai.stuck_time + dtime
    else
        ai.stuck_time = 0
        ai.last_pos = vector.new(current_pos)
    end
    
    if ai.stuck_time > 3 then
        ai.path = nil
        local vel = unit_data.entity:get_velocity()
        unit_data.entity:set_velocity({x=vel.x, y=5, z=vel.z})
        ai.stuck_time = 0
    end

    if ai.task_time > 45 and unit_data.target then
        unit_data.entity:set_pos(vector.add(unit_data.target, {x=0, y=1, z=0}))
        ai.task_time = 0
        ai.path = nil
    end
    
    if unit_data.command == "gather" then
        human_fortress.gather_ai(unit_data, dtime, current_pos, ai)
    elseif unit_data.command == "move" then
        human_fortress.move_ai(unit_data, dtime, current_pos, ai)
    elseif unit_data.command == "deposit" then
        human_fortress.deposit_ai(unit_data, dtime, current_pos, ai)
    end
end

-- AI ЗДАЧІ РЕСУРСІВ
human_fortress.deposit_ai = function(unit_data, dtime, current_pos, ai)
    if not current_pos or not unit_data then return end
    
    local townhall_pos = human_fortress.find_nearest_townhall(current_pos, unit_data.owner)
    
    if not townhall_pos or type(townhall_pos) ~= "table" or not townhall_pos.x then
        unit_data.command = nil
        return
    end
    
    local dist = vector.distance(current_pos, townhall_pos)
    
    if dist > 3 then
        human_fortress.smart_move(unit_data, current_pos, townhall_pos, dtime)
    else
        unit_data.entity:set_velocity({x=0, y=0, z=0})
        unit_data.is_moving = false
        
        -- Здаємо ресурси
        human_fortress.deposit_resources(unit_data)
        
        -- Повертаємося до збору, якщо був збір
        if ai.last_resource_type then
            local next_resource = human_fortress.find_nearest_resource(current_pos, ai.last_resource_type, 15)
            if next_resource then
                unit_data.target = next_resource
                unit_data.command = "gather"
                ai.path = nil
                ai.task_time = 0
            else
                unit_data.command = nil
                ai.last_resource_type = nil
            end
        else
            unit_data.command = nil
        end
    end
end


-- ОНОВЛЕНИЙ GATHER AI
human_fortress.gather_ai = function(unit_data, dtime, current_pos, ai)
    if not current_pos or not unit_data.target then return end
    
    local target_pos = unit_data.target
    local dist = vector.distance(current_pos, target_pos)
    
    if dist > 2.5 then
        human_fortress.smart_move(unit_data, current_pos, target_pos, dtime)
    else
        unit_data.entity:set_velocity({x=0, y=0, z=0})
        unit_data.is_moving = false
        
        local dir = vector.direction(current_pos, target_pos)
        unit_data.entity:set_yaw(math.atan2(-dir.x, dir.z))
        
        unit_data.gather_timer = (unit_data.gather_timer or 0) + dtime
        if unit_data.gather_timer >= 2 then
            local node = minetest.get_node(target_pos)
            if node.name ~= "air" then
                local res_type = human_fortress.get_resource_type(node.name)
                
                -- Перевірка чи може збирати цей ресурс
                if not human_fortress.can_gather_resource(unit_data.profession, res_type) then
                    unit_data.command = nil
                    return
                end
                
                ai.last_resource_type = res_type
                
                -- ОТРИМУЄМО КІЛЬКІСТЬ
                local amount = human_fortress.get_gather_amount(unit_data.profession)
                
                -- ДЛЯ ЕФІРНИХ ДЕРЕВ - СПЕЦІАЛЬНА ЛОГІКА
                if res_type == "wood" and node.name:find("ether_tree") then
                    local gathered = gather_from_ether_tree(target_pos, unit_data.entity)
                    if gathered > 0 then
                        unit_data.inventory.wood = (unit_data.inventory.wood or 0) + gathered
                    end
                else
                    -- Звичайний збір (для каменю/їжі)
                    unit_data.inventory[res_type] = (unit_data.inventory[res_type] or 0) + amount
                    minetest.remove_node(target_pos)
                end
            end
            
            unit_data.gather_timer = 0
            
            -- Перевірка чи інвентар повний
            local max_inventory = human_fortress.get_inventory_size(unit_data.profession)
            local current_inventory = human_fortress.get_total_inventory(unit_data.inventory)
            
            if current_inventory >= max_inventory then
                unit_data.command = "deposit"
                ai.path = nil
                ai.task_time = 0
            else
                local next_resource = human_fortress.find_nearest_resource(current_pos, ai.last_resource_type, 10)
                
                if next_resource then
                    unit_data.target = next_resource
                    unit_data.command = "gather"
                    ai.path = nil
                    ai.task_time = 0
                else
                    if current_inventory > 0 then
                        unit_data.command = "deposit"
                        ai.path = nil
                        ai.task_time = 0
                    else
                        unit_data.command = nil
                        ai.last_resource_type = nil
                    end
                end
            end
        end
    end
end

-- ============================================
-- ОНОВЛЕНА MOVE_AI
-- ============================================

human_fortress.move_ai = function(unit_data, dtime, current_pos, ai)
    if not current_pos or not unit_data.target then return end
    
    human_fortress.smart_move(unit_data, current_pos, unit_data.target, dtime)
    
    -- ПЕРЕВІРКА ЧИ ДІЙШЛИ
    if vector.distance(current_pos, unit_data.target) < 1.2 then
        unit_data.command = nil
        unit_data.target = nil
        unit_data.entity:set_velocity({x=0, y=0, z=0})
        unit_data.is_moving = false
        ai.path = nil
    end
end

print("[RTS] Smart AI with professions, inventory and resource deposit loaded!")