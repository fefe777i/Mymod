-- my_mod/init.lua
-- Мод для розширеної води (розливається на 20 блоків)

local S = minetest.get_translator("my_mod")

-- ===================================================
-- РОЗШИРЕНА ВОДА (розливається на 20 блоків)
-- ===================================================

-- Створюємо маркер для розширювача води
minetest.register_node("my_mod:water_spreader", {
    description = S("Water Spreader"),
    tiles = {"default_water_source_animated.png"},
    groups = {not_in_creative_inventory = 1, water_spreader = 1},
    light_source = 0,
    walkable = false,
    buildable_to = true,
    liquid_range = 8,
    
    on_construct = function(pos)
        minetest.get_node_timer(pos):start(3)
    end,
    
    on_timer = function(pos)
        local radius = 20
        
        -- Шукаємо місця для води (тільки вниз і в сторони)
        local added = 0
        
        -- 1. СПОЧАТКУ ТЕЧЕМО ВНИЗ
        local below = {x = pos.x, y = pos.y - 1, z = pos.z}
        local node_below = minetest.get_node(below)
        
        if node_below.name == "air" or node_below.name == "default:water_flowing" then
            -- Перевіряємо чи є опора
            local node_below_2 = minetest.get_node({x = pos.x, y = pos.y - 2, z = pos.z})
            if node_below_2.name ~= "air" then
                minetest.set_node(below, {name = "default:water_source"})
                added = added + 1
            end
        end
        
        -- 2. ПОТІМ РОЗТІКАЄМОСЯ ПО ГОРИЗОНТАЛІ (якщо є опора знизу)
        -- Перевіряємо чи є під нами твердий блок
        local ground_below = minetest.get_node({x = pos.x, y = pos.y - 1, z = pos.z})
        local has_ground = (ground_below.name ~= "air" and 
                            ground_below.name ~= "default:water_source" and
                            ground_below.name ~= "default:water_flowing")
        
        if has_ground then
            -- Напрямки для розтікання (тільки по горизонталі)
            local directions = {
                {x = 1, y = 0, z = 0},   -- схід
                {x = -1, y = 0, z = 0},  -- захід
                {x = 0, y = 0, z = 1},   -- південь
                {x = 0, y = 0, z = -1},  -- північ
            }
            
            for _, dir in ipairs(directions) do
                local new_pos = vector.add(pos, dir)
                local dist = vector.distance(pos, new_pos)
                
                if dist <= radius then
                    local target_node = minetest.get_node(new_pos)
                    
                    -- Можна ставити воду тільки на повітря або текучу воду
                    if target_node.name == "air" or target_node.name == "default:water_flowing" then
                        -- Перевіряємо чи є під цією позицією твердий блок
                        local ground = minetest.get_node({x = new_pos.x, y = new_pos.y - 1, z = new_pos.z})
                        if ground.name ~= "air" then
                            -- Перевіряємо чи є шлях до води (не через стіни)
                            local ray = minetest.raycast(pos, new_pos, false, false)
                            local can_place = true
                            for pointed in ray do
                                if pointed.type == "node" then
                                    local node_path = minetest.get_node(pointed.under)
                                    if node_path.name ~= "air" and 
                                       node_path.name ~= "default:water_source" and
                                       node_path.name ~= "default:water_flowing" and
                                       node_path.name ~= "my_mod:water_spreader" then
                                        can_place = false
                                        break
                                    end
                                end
                            end
                            
                            if can_place then
                                minetest.set_node(new_pos, {name = "default:water_source"})
                                added = added + 1
                            end
                        end
                    end
                end
            end
        end
        
        -- Якщо додали багато води, зменшуємо інтервал
        if added > 5 then
            minetest.get_node_timer(pos):start(2)
        else
            minetest.get_node_timer(pos):start(3)
        end
        
        return true
    end
})



-- ===================================================
-- ВОДЯНИЙ ПЕНЗЕЛЬ (створює водойми на рівні землі)
-- ===================================================

minetest.register_tool("my_mod:water_brush", {
    description = S("Water Brush (creates large water bodies)"),
    inventory_image = "default_tool_steelpick.png^default_water.png",
    stack_max = 1,
    
    on_use = function(itemstack, user, pointed_thing)
        local pos = pointed_thing.above
        if not pos then 
            return 
        end
        
        local player_name = user:get_player_name()
        local radius = 20
        
        -- Знаходимо рівень землі під точкою
        local ground_pos = vector.copy(pos)
        while ground_pos.y > -100 do
            local node = minetest.get_node(ground_pos)
            if node.name ~= "air" then
                ground_pos.y = ground_pos.y + 1
                break
            end
            ground_pos.y = ground_pos.y - 1
        end
        
        -- Перевірка на захищену зону
        if minetest.is_protected(ground_pos, player_name) then
            minetest.chat_send_player(player_name, "Area is protected!")
            return
        end
        
        local count = 0
        
        -- Створюємо водойму (тільки на одному рівні, не вище)
        for x = -radius, radius do
            for z = -radius, radius do
                local dist = math.sqrt(x*x + z*z)
                if dist <= radius then
                    local new_pos = {x = ground_pos.x + x, y = ground_pos.y, z = ground_pos.z + z}
                    
                    if not minetest.is_protected(new_pos, player_name) then
                        local node = minetest.get_node(new_pos)
                        -- Перевіряємо що під водою є твердий блок
                        local below = minetest.get_node({x = new_pos.x, y = new_pos.y - 1, z = new_pos.z})
                        
                        if (node.name == "air" or node.name == "default:water_flowing") and 
                           below.name ~= "air" then
                            minetest.set_node(new_pos, {name = "my_mod:water_spreader"})
                            count = count + 1
                        end
                    end
                end
            end
        end
        
        minetest.chat_send_player(player_name, 
            "Created water body with radius " .. radius .. 
            " (added " .. count .. " water blocks)")
        
        if not minetest.is_creative_enabled(player_name) then
            itemstack:add_wear(65535 / 50)
            return itemstack
        end
    end
})

-- Крафт
minetest.register_craft({
    output = "my_mod:water_brush",
    recipe = {
        {"default:steel_ingot", "default:water_bucket", "default:steel_ingot"},
        {"default:steel_ingot", "default:diamond", "default:steel_ingot"},
        {"", "default:stick", ""}
    }
})

print("[my_mod] Loaded! Water flows naturally (down and sideways)")