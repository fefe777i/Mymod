human_fortress.buildings_list = {
    townhall = {
        description = "Town Hall",
        tiles = {"human_fortress_townhall.png"},
        cost = {wood = 200, stone = 150},
        size = {x=5, y=4, z=5}
    },
    house = {
        description = "House",
        tiles = {"human_fortress_house.png"},
        cost = {wood = 100, stone = 50},
        size = {x=4, y=3, z=4}
    },
    barracks = {
        description = "Barracks",
        tiles = {"human_fortress_barracks.png"},
        cost = {wood = 150, stone = 100},
        size = {x=5, y=3, z=4}
    },
    storage = {
        description = "Storage",
        tiles = {"human_fortress_storage.png"},
        cost = {wood = 80, stone = 120},
        size = {x=3, y=3, z=3}
    },
    farm = {
        description = "Farm",
        tiles = {"human_fortress_farm.png"},
        cost = {wood = 60, stone = 30},
        size = {x=7, y=1, z=7}
    },
    wall = {
        description = "Стіна",
        tiles = {"human_fortress_wall.png"},
        cost = {wood = 40, stone = 80},
        size = {x=1, y=2, z=1}
    }
}

-- НАЙПРОСТІША ФУНКЦІЯ БУДІВНИЦТВА
human_fortress.start_building = function(type, pos, owner)
    local player_data = human_fortress.players[owner]
    if not player_data then 
        minetest.chat_send_player(owner, "Помилка: немає даних гравця")
        return 
    end
    
    local building_def = human_fortress.buildings_list[type]
    if not building_def then 
        minetest.chat_send_player(owner, "Помилка: невідома будівля")
        return 
    end
    
    -- Перевіряємо ресурси
    for resource, amount in pairs(building_def.cost) do
        if (player_data.resources[resource] or 0) < amount then
            minetest.chat_send_player(owner, "Не вистачає " .. resource .. ". Потрібно: " .. amount .. ", є: " .. (player_data.resources[resource] or 0))
            return
        end
    end
    
    -- Сплачуємо ресурси
    for resource, amount in pairs(building_def.cost) do
        player_data.resources[resource] = (player_data.resources[resource] or 0) - amount
    end
    
    -- Знаходимо робітників (будь-яких, не тільки воркерів)
    local available_units = {}
    for _, unit in ipairs(player_data.units) do
        if unit.command == nil then
            table.insert(available_units, unit)
            if #available_units >= 1 then break end -- Хоча б один робітник
        end
    end
    
    if #available_units == 0 then
        minetest.chat_send_player(owner, "Немає вільних юнітів для будівництва")
        -- Повертаємо ресурси
        for resource, amount in pairs(building_def.cost) do
            player_data.resources[resource] = (player_data.resources[resource] or 0) + amount
        end
        return
    end
    
    -- Коректуємо позицію (ставимо на верхню частину блоку)
    local build_pos = {
        x = math.floor(pos.x) + 0.5,
        y = pos.y + 1, -- на блок вище
        z = math.floor(pos.z) + 0.5
    }
    
    -- Видаємо команду кожному доступному юніту
    for _, unit in ipairs(available_units) do
        unit.command = "build"
        unit.target = build_pos
        unit.building_type = type
        unit.build_timer = 0
        
        -- Показуємо ціль
        minetest.add_particlespawner({
            amount = 20,
            time = 5,
            minpos = {x=build_pos.x-0.5, y=build_pos.y, z=build_pos.z-0.5},
            maxpos = {x=build_pos.x+0.5, y=build_pos.y+2, z=build_pos.z+0.5},
            minvel = {x=0, y=0.1, z=0},
            maxvel = {x=0, y=0.3, z=0},
            minacc = {x=0, y=0, z=0},
            maxacc = {x=0, y=0, z=0},
            minexptime = 1,
            maxexptime = 2,
            minsize = 1,
            maxsize = 2,
            collisiondetection = false,
            texture = "human_fortress_build_target.png",
            glow = 10
        })
        
        minetest.chat_send_player(owner, unit.type .. " починає будівництво " .. building_def.description)
    end
    
    -- Оновлюємо GUI
    local player_obj = minetest.get_player_by_name(owner)
    if player_obj then
        human_fortress.update_gui(player_obj)
    end
    
    return true
end

-- ПРОСТА ФУНКЦІЯ ЗАВЕРШЕННЯ БУДІВНИЦТВА
human_fortress.complete_building = function(pos, type, owner)
    local building_def = human_fortress.buildings_list[type]
    if not building_def then return end
    
    minetest.chat_send_player(owner, "Завершення будівництва " .. building_def.description)
    
    -- Створюємо просту будівлю (куб)
    local half_x = math.floor(building_def.size.x / 2)
    local half_z = math.floor(building_def.size.z / 2)
    
    -- Очищаємо область
    for dx = -half_x, half_x do
        for dy = 0, building_def.size.y - 1 do
            for dz = -half_z, half_z do
                local p = {
                    x = pos.x + dx,
                    y = pos.y + dy - 1, -- починаємо знизу
                    z = pos.z + dz
                }
                
                minetest.set_node(p, {name = "air"})
            end
        end
    end
    
    -- Будуємо фундамент
    for dx = -half_x, half_x do
        for dz = -half_z, half_z do
            local floor_pos = {
                x = pos.x + dx,
                y = pos.y - 1,
                z = pos.z + dz
            }
            
            minetest.set_node(floor_pos, {name = "default:stone"})
        end
    end
    
    -- Будуємо стіни та дах
    for dx = -half_x, half_x do
        for dz = -half_z, half_z do
            for dy = 0, building_def.size.y - 1 do
                local wall_pos = {
                    x = pos.x + dx,
                    y = pos.y + dy - 1,
                    z = pos.z + dz
                }
                
                -- Стіни тільки по краях, або повний блок для маленьких будівель
                if building_def.size.x <= 2 and building_def.size.z <= 2 then
                    -- Маленькі будівлі - повні блоки
                    minetest.set_node(wall_pos, {name = "default:wood"})
                else
                    -- Великі будівлі - стіни тільки по периметру
                    if dx == -half_x or dx == half_x or dz == -half_z or dz == half_z or dy == building_def.size.y - 1 then
                        minetest.set_node(wall_pos, {name = "default:wood"})
                    else
                        minetest.set_node(wall_pos, {name = "air"})
                    end
                end
            end
        end
    end
    
    -- Двері для будинків
    if type == "house" or type == "townhall" or type == "barracks" then
        local door_pos = {
            x = pos.x,
            y = pos.y,
            z = pos.z + half_z
        }
        
        -- Спробуємо поставити двері
        if minetest.get_node(door_pos).name == "air" then
            minetest.set_node(door_pos, {name = "doors:door_wood_a", param2 = 2})
        end
    end
    
    -- Ефекти завершення
    for i = 1, 30 do
        minetest.add_particle({
            pos = {
                x = pos.x + (math.random() - 0.5) * building_def.size.x,
                y = pos.y + math.random() * building_def.size.y,
                z = pos.z + (math.random() - 0.5) * building_def.size.z
            },
            velocity = {x=0, y=0.5, z=0},
            acceleration = {x=0, y=-0.2, z=0},
            expirationtime = math.random(2, 4),
            size = math.random(1, 3),
            texture = "human_fortress_completion.png",
            glow = 14
        })
    end
    
    -- Звук
    minetest.sound_play("default_place_node", {
        pos = pos,
        gain = 1.0,
        max_hear_distance = 15
    })
    
    -- Зберігаємо будівлю
    local player_data = human_fortress.players[owner]
    if player_data then
        player_data.buildings = player_data.buildings or {}
        table.insert(player_data.buildings, {
            type = type,
            pos = pos,
            created = os.time(),
            health = 100
        })
        
        minetest.chat_send_player(owner, building_def.description .. " успішно побудовано!")
    end
end

-- ПРОСТИЙ AI ДЛЯ БУДІВНИЦТВА
human_fortress.build_ai = function(unit_data, dtime, current_pos)
    local target_pos = unit_data.target
    
    if not target_pos then
        unit_data.command = nil
        unit_data.building_type = nil
        return
    end
    
    local dist = vector.distance(current_pos, target_pos)
    
    if dist > 3 then
        -- Рухаємось до місця будівництва
        if unit_data.entity then
            local dir = vector.direction(current_pos, target_pos)
            local move_dir = vector.normalize({x=dir.x, y=0, z=dir.z})
            
            -- Дивимось на ціль
            unit_data.entity:set_yaw(math.atan2(move_dir.x, move_dir.z))
            
            -- Рухаємось
            local velocity = unit_data.entity:get_velocity() or {x=0, y=0, z=0}
            velocity.x = move_dir.x * unit_data.speed
            velocity.z = move_dir.z * unit_data.speed
            unit_data.entity:set_velocity(velocity)
            unit_data.is_moving = true
        end
    else
        -- Дійшли - починаємо будувати
        unit_data.is_moving = false
        if unit_data.entity then
            unit_data.entity:set_velocity({x=0, y=0, z=0})
            
            -- Дивимось на центр будівництва
            local dir = vector.direction(current_pos, target_pos)
            unit_data.entity:set_yaw(math.atan2(dir.x, dir.z))
        end
        
        -- Запускаємо таймер будівництва
        if not unit_data.build_timer then
            unit_data.build_timer = 0
            minetest.chat_send_player(unit_data.owner, 
                unit_data.type .. " починає будівництво " .. unit_data.building_type)
        end
        
        unit_data.build_timer = unit_data.build_timer + dtime
        
        -- Ефекти будівництва (партикли)
        if math.random() < 0.2 then
            minetest.add_particle({
                pos = {
                    x = target_pos.x + (math.random() - 0.5) * 2,
                    y = target_pos.y + math.random() * 2,
                    z = target_pos.z + (math.random() - 0.5) * 2
                },
                velocity = {x=0, y=0.1, z=0},
                acceleration = {x=0, y=0, z=0},
                expirationtime = 1,
                size = 1,
                texture = "default_wood.png",
                glow = 5
            })
        end
        
        -- Час будівництва
        local build_time = 5 -- секунд за замовчуванням
        
        if unit_data.building_type == "townhall" then
            build_time = 15
        elseif unit_data.building_type == "barracks" then
            build_time = 10
        elseif unit_data.building_type == "house" then
            build_time = 8
        elseif unit_data.building_type == "storage" then
            build_time = 6
        elseif unit_data.building_type == "farm" then
            build_time = 4
        elseif unit_data.building_type == "wall" then
            build_time = 3
        end
        
        -- Перевіряємо чи завершено
        if unit_data.build_timer >= build_time then
            if unit_data.building_type then
                human_fortress.complete_building(target_pos, unit_data.building_type, unit_data.owner)
            end
            
            -- Очищуємо дані
            unit_data.command = nil
            unit_data.target = nil
            unit_data.building_type = nil
            unit_data.build_timer = nil
            unit_data.is_moving = false
        end
    end
end
-- ДОДАЙТЕ ЦІ ФУНКЦІЇ ПЕРЕД human_fortress.process_ai

-- ФУНКЦІЯ ПРОСТОГО РУХУ (має бути в units.lua, але ми її тут створимо)
human_fortress.simple_move = function(unit_data, current_pos, target_pos, ai)
    if not unit_data.entity then return end
    
    local dir = vector.direction(current_pos, target_pos)
    local move_dir = vector.normalize({x=dir.x, y=0, z=dir.z})
    
    -- Дивимося в напрямку руху
    unit_data.entity:set_yaw(math.atan2(move_dir.x, move_dir.z))
    
    -- Рух до цілі
    local velocity = unit_data.entity:get_velocity() or {x=0, y=0, z=0}
    velocity.x = move_dir.x * unit_data.speed
    velocity.z = move_dir.z * unit_data.speed
    
    -- Автоматичний стрибок при ходьбі (1% шанс кожен кадр)
    if ai and ai.jump_cooldown and ai.jump_cooldown <= 0 and math.random() < 0.01 then
        velocity.y = 6
        ai.jump_cooldown = 0.8
    end
    
    unit_data.entity:set_velocity(velocity)
    unit_data.is_moving = true
end

-- AI ДЛЯ РУХУ (це та функція, якої не вистачає)
human_fortress.move_ai = function(unit_data, dtime, current_pos, ai)
    local target_pos = unit_data.target
    
    if not target_pos then
        unit_data.command = nil
        if unit_data.entity then
            unit_data.entity:set_velocity({x=0, y=0, z=0})
        end
        unit_data.is_moving = false
        return
    end
    
    local dist = vector.distance(current_pos, target_pos)
    
    if dist > 1 then
        -- Ініціалізація ai даних, якщо їх немає
        if not ai then
            ai = {}
        end
        if not ai.jump_cooldown then
            ai.jump_cooldown = 0
        end
        
        human_fortress.simple_move(unit_data, current_pos, target_pos, ai)
        
        -- Оновлюємо cooldown стрибка
        if ai.jump_cooldown > 0 then
            ai.jump_cooldown = ai.jump_cooldown - dtime
        end
    else
        -- Дійшли до цілі
        unit_data.command = nil
        if unit_data.entity then
            unit_data.entity:set_velocity({x=0, y=0, z=0})
        end
        unit_data.is_moving = false
    end
end

-- AI ДЛЯ ЗБОРУ РЕСУРСІВ (також потрібна для будівництва)
human_fortress.gather_ai = function(unit_data, dtime, current_pos, ai)
    -- Якщо gather_ai викликається під час будівництва, просто закінчуємо команду
    unit_data.command = nil
    unit_data.target = nil
    unit_data.is_moving = false
    
    if unit_data.entity then
        unit_data.entity:set_velocity({x=0, y=0, z=0})
    end
    
    minetest.chat_send_player(unit_data.owner, unit_data.type .. " не може збирати ресурси під час будівництва")
end

-- ТЕПЕР ОНОВЛЮЄМО process_ai ДЛЯ БУДІВНИЦТВА
human_fortress.process_ai = function(unit_data, dtime, current_pos)
    if not unit_data.command or unit_data.health <= 0 then return end
    
    -- Ініціалізація AI даних
    if not unit_data.ai_data then
        unit_data.ai_data = {
            stuck_time = 0,
            last_pos = current_pos,
            task_time = 0
        }
    end
    
    local ai = unit_data.ai_data
    ai.task_time = ai.task_time + dtime
    
    -- Обробка команд
    if unit_data.command == "gather" and unit_data.target then
        human_fortress.gather_ai(unit_data, dtime, current_pos, ai)
    elseif unit_data.command == "move" and unit_data.target then
        human_fortress.move_ai(unit_data, dtime, current_pos, ai)  -- ЦЕ ТЕПЕР ІСНУЄ!
    elseif unit_data.command == "build" and unit_data.target then
        human_fortress.build_ai(unit_data, dtime, current_pos)
    end
end
-- ОНОВЛЮЄМО process_ai ДЛЯ БУДІВНИЦТВА
human_fortress.process_ai = function(unit_data, dtime, current_pos)
    if not unit_data.command or unit_data.health <= 0 then return end
    
    -- Ініціалізація AI даних
    if not unit_data.ai_data then
        unit_data.ai_data = {
            stuck_time = 0,
            last_pos = current_pos,
            task_time = 0
        }
    end
    
    local ai = unit_data.ai_data
    ai.task_time = ai.task_time + dtime
    
    -- Обробка команд
    if unit_data.command == "gather" and unit_data.target then
        human_fortress.gather_ai(unit_data, dtime, current_pos, ai)
    elseif unit_data.command == "move" and unit_data.target then
        human_fortress.move_ai(unit_data, dtime, current_pos, ai)
    elseif unit_data.command == "build" and unit_data.target then
        human_fortress.build_ai(unit_data, dtime, current_pos) -- ЗМІНА ТУТ
    end
end

-- РЕЄСТРАЦІЯ БУДІВЕЛЬНИХ БЛОКІВ (для ручного створення)
for name, def in pairs(human_fortress.buildings_list) do
    minetest.register_node("human_fortress:building_" .. name, {
        description = def.description,
        tiles = def.tiles,
        groups = {cracky = 2, building = 1},
        paramtype2 = "facedir",
        on_construct = function(pos)
            local meta = minetest.get_meta(pos)
            meta:set_string("infotext", def.description)
        end,
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            local player_name = clicker:get_player_name()
            minetest.chat_send_player(player_name, "Це " .. def.description)
            return itemstack
        end
    })
end

-- ФУНКЦІЯ ДЛЯ ШВИДКОГО ТЕСТУ (можна видалити пізніше)
human_fortress.test_building = function(owner, building_type)
    local player = minetest.get_player_by_name(owner)
    if not player then return end
    
    local pos = player:get_pos()
    local dir = player:get_look_dir()
    pos.x = pos.x + dir.x * 5
    pos.y = pos.y + 1
    pos.z = pos.z + dir.z * 5
    
    human_fortress.start_building(building_type, pos, owner)
end

-- КОМАНДИ ДЛЯ ТЕСТУ
minetest.register_chatcommand("build_house", {
    description = "Test build house",
    func = function(name, param)
        human_fortress.test_building(name, "house")
        return true, "Building house..."
    end
})

minetest.register_chatcommand("build_townhall", {
    description = "Test build townhall",
    func = function(name, param)
        human_fortress.test_building(name, "townhall")
        return true, "Building townhall..."
    end
})

minetest.register_chatcommand("build_farm", {
    description = "Test build farm",
    func = function(name, param)
        human_fortress.test_building(name, "farm")
        return true, "Building farm..."
    end
})

minetest.register_chatcommand("build_barracks", {
    description = "Test build barracks",
    func = function(name, param)
        human_fortress.test_building(name, "barracks")
        return true, "Building barracks..."
    end
})

minetest.register_chatcommand("build_wall", {
    description = "Test build wall",
    func = function(name, param)
        human_fortress.test_building(name, "wall")
        return true, "Building wall..."
    end
})

print("[RTS] Simple building system loaded")