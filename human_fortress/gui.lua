-------------------------------------------------
-- Human Fortress RTS - HUD та Інтерфейс
-------------------------------------------------

-- Таблиця для кешування кількості юнітів
local unit_counts = {}
local unit_count_timer = 0

minetest.register_on_joinplayer(function(player)
    minetest.after(0.5, function()
        if player and player:is_player() then
            human_fortress.update_player_model(player)
        end
    end)
end)

-- 0. Функція зміни моделі гравця залежно від рівня
function human_fortress.update_player_model(player)
    if not player or not player:is_player() then return end
    local name = player:get_player_name()
    local data = human_fortress.edos_data[name]
    
    local level = 0
    if data and data.level then
        level = data.level
    end
    
    local model, texture, e_height, visual_size
    
    if level == 0 then
        model = "player_lvl_0.obj"
        texture = "player_lvl_0.png"
        e_height = 1
        visual_size = 8.0
    elseif level >= 1 and level < 10 then
        model = "player_lvl_0.obj"
        texture = "player_lvl_0.png"
        e_height = 1
        visual_size = 8.0
    elseif level >= 10 and level < 20 then
        model = "player_lvl_10.obj"
        texture = "player_lvl_10.png"
        e_height = 1.2
        visual_size = 8.0
    elseif level >= 20 and level < 30 then
        model = "player_lvl_20.obj"
        texture = "player_lvl_20.png"
        e_height = 1.4
        visual_size = 8.0
    elseif level >= 30 and level < 40 then
        model = "player_lvl_30.obj"
        texture = "player_lvl_30.png"
        e_height = 1.5
        visual_size = 8.1
    elseif level >= 40 and level < 50 then
        model = "player_lvl_40.obj"
        texture = "player_lvl_40.png"
        e_height = 1.6
        visual_size = 8.9
    else
        model = "character.b3d"
        texture = "character.png"
        e_height = 1.7
        visual_size = 1.3
    end

    player:set_properties({
        visual = "mesh",
        mesh = model,
        textures = {texture},
        visual_size = {x=visual_size, y=visual_size, z=visual_size},
        eye_height = e_height,
        sprite_yaw_correction = 0,
    })
end

-- Функція спавну подарунка
local function spawn_level3_gift(player)
    if not player or not player:is_player() then return end
    
    local pos = player:get_pos()
    pos.y = pos.y + 5
    
    minetest.add_entity(pos, "human_fortress:level_gift")
    
    minetest.chat_send_player(player:get_player_name(), 
        "🎁 Вітаю з 3 рівнем! Подарунок падає зверху!")
end

-- Entity подарунка
minetest.register_entity("human_fortress:level_gift", {
    initial_properties = {
        physical = false,
        visual = "sprite",
        visual_size = {x = 2, y = 2},
        textures = {"gift_box.png"},
    },
    
    on_step = function(self, dtime)
        if not self.object then return end
        
        local pos = self.object:get_pos()
        pos.y = pos.y - 5 * dtime
        
        if pos.y < 0 then
            self.object:remove()
        else
            self.object:set_pos(pos)
        end
    end,
})

-- Реєстрація блоків літер
local letters = {
    {name = "m", letter = "м"},
    {name = "o", letter = "о"},
    {name = "v", letter = "в"},
    {name = "a", letter = "а"}
}

for _, l in ipairs(letters) do
    minetest.register_node("human_fortress:letter_" .. l.name, {
        description = "Буква " .. string.upper(l.letter),
        tiles = {"letter_" .. l.letter .. ".png"},
        groups = {dig_immediate = 3},
        drawtype = "signlike",
        walkable = false,
        paramtype2 = "wallmounted",
        drop = "",
    })
end

-- ПОВОРОТ ПРИ НАТИСКАННІ
minetest.register_on_punchnode(function(pos, node, puncher)
    if not puncher or not puncher:is_player() then return end
    
    if node.name == "human_fortress:letter_m" or
       node.name == "human_fortress:letter_o" or
       node.name == "human_fortress:letter_v" or
       node.name == "human_fortress:letter_a" then
        local new_rot = (node.param2 + 90) % 360
        minetest.swap_node(pos, {
            name = node.name,
            param2 = new_rot
        })
        
        check_letters(puncher)
    end
end)

-- ПЕРЕВІРКА ЧИ ВСІ ПРАВИЛЬНО
local function check_letters(player)
    if not player then return end
    
    local pos = player:get_pos()
    local player_name = player:get_player_name()
    local letters_found = {}
    local all_correct = true
    
    for x = -10, 10 do
        for z = -10, 10 do
            local check_pos = {x = pos.x + x, y = pos.y, z = pos.z + z}
            local node = minetest.get_node(check_pos)
            
            if node.name == "human_fortress:letter_m" or
               node.name == "human_fortress:letter_o" or
               node.name == "human_fortress:letter_v" or
               node.name == "human_fortress:letter_a" then
                table.insert(letters_found, node)
                if node.param2 ~= 0 then
                    all_correct = false
                end
            end
        end
    end
    
    if #letters_found == 4 and all_correct then
        minetest.chat_send_all("🎉 Гравець " .. player_name .. " склав слово МОВА!")
        
        if human_fortress and human_fortress.edos_data and human_fortress.edos_data[player_name] then
            human_fortress.edos_data[player_name].score = (human_fortress.edos_data[player_name].score or 0) + 100
        end
        
        minetest.chat_send_player(player_name, "✅ +100 ейдосів!")
    end
end

-- Функція перевірки чи може гравець говорити
local function can_player_speak(name)
    if not human_fortress or not human_fortress.edos_data then
        return true
    end
    
    local data = human_fortress.edos_data[name]
    if not data then return true end
    
    return (data.level or 1) >= 3
end

-- 1. Глобальна функція оновлення HUD
function human_fortress.update_hud(player)
    if not player or not player:is_player() then return end
    
    local name = player:get_player_name()
    local hud = human_fortress.hud_ids and human_fortress.hud_ids[name]
    local data = human_fortress.edos_data and human_fortress.edos_data[name]
    
    if not hud or not data then return end
    
    if hud.rice_text then 
        player:hud_change(hud.rice_text, "text", tostring(data.food or 0)) 
    end
    if hud.vers_text then 
        player:hud_change(hud.vers_text, "text", tostring(data.stone or 0)) 
    end
    if hud.efir_text then 
        player:hud_change(hud.efir_text, "text", tostring(data.wood or 0)) 
    end
    
    if hud.edos_text then 
        player:hud_change(hud.edos_text, "text", tostring(data.score or 0)) 
    end
    
    if hud.level_text then 
        local new_text = "Lvl " .. tostring(data.level or 1)
        player:hud_change(hud.level_text, "text", new_text)
        
        if not hud.last_level or hud.last_level ~= data.level then
            hud.last_level = data.level
            human_fortress.update_player_model(player)
            
            if data.level == 3 then
                spawn_level3_gift(player)
            end
        end
    end

    -- Оновлення лічильника юнітів (з кешу)
    if hud.unit_text then
        local count = unit_counts[name] or 0
        player:hud_change(hud.unit_text, "text", tostring(count))
    end
end

-- 2. Функція "міст" для оновлення всього
function human_fortress.update_gui(player)
    if not player or not player:is_player() then return end
    
    human_fortress.update_hud(player)
    
    if unified_inventory and unified_inventory.get_formspec then
        minetest.after(0.1, function()
            if player and player:is_player() then
                player:set_inventory_formspec(unified_inventory.get_formspec(player))
            end
        end)
    end
end

-- 3. Створення HUD елементів
local function create_hud(player)
    if not player or not player:is_player() then return end
    local name = player:get_player_name()
    
    if not human_fortress.edos_data[name] then
        minetest.after(1, function() 
            if player and player:is_player() then
                create_hud(player) 
            end
        end)
        return
    end
    
    if not human_fortress.hud_ids then human_fortress.hud_ids = {} end
    if human_fortress.hud_ids[name] then
        for _, id in pairs(human_fortress.hud_ids[name]) do 
            if type(id) == "number" then
                player:hud_remove(id) 
            end
        end
    end
    
    local hud = {
        rice_icon = player:hud_add({
            hud_elem_type = "image", position = {x = 0, y = 0}, offset = {x = 70, y = 35},
            text = "human_fortress_r.png", scale = {x = 2.2, y = 2.2}, alignment = {x = 0, y = 0},
        }),
        rice_text = player:hud_add({
            hud_elem_type = "text", position = {x = 0, y = 0}, offset = {x = 105, y = 35},
            text = "0", number = 0xFFFFFF, alignment = {x = 0, y = 0},
        }),
        vers_icon = player:hud_add({
            hud_elem_type = "image", position = {x = 0, y = 0}, offset = {x = 70, y = 100},
            text = "human_fortress_v.png", scale = {x = 2.2, y = 2.2}, alignment = {x = 0, y = 0},
        }),
        vers_text = player:hud_add({
            hud_elem_type = "text", position = {x = 0, y = 0}, offset = {x = 105, y = 100},
            text = "0", number = 0xFFFFFF, alignment = {x = 0, y = 0},
        }),
        efir_icon = player:hud_add({
            hud_elem_type = "image", position = {x = 0, y = 0}, offset = {x = 70, y = 170},
            text = "human_fortress_ef.png", scale = {x = 2.2, y = 2.2}, alignment = {x = 0, y = 0},
        }),
        efir_text = player:hud_add({
            hud_elem_type = "text", position = {x = 0, y = 0}, offset = {x = 105, y = 170},
            text = "0", number = 0xFFFFFF, alignment = {x = 0, y = 0},
        }),
        -- === НОВЕ: Лічильник юнітів ===
        unit_icon = player:hud_add({
            hud_elem_type = "image", position = {x = 0, y = 0}, offset = {x = 200, y = 35},
            text = "human_fortress_fom.png", scale = {x = 2.2, y = 2.2}, alignment = {x = 0, y = 0},
        }),
        unit_text = player:hud_add({
            hud_elem_type = "text", position = {x = 0, y = 0}, offset = {x = 235, y = 35},
            text = "0", number = 0x00FFFF, alignment = {x = 0, y = 0},
        }),
        -- ==============================
        edos_icon = player:hud_add({
            hud_elem_type = "image", position = {x = 0, y = 0.5}, offset = {x = 20, y = 0},
            text = "edos.png", scale = {x = 3.5, y = 3.5}, alignment = {x = 1, y = 0},
        }),
        edos_text = player:hud_add({
            hud_elem_type = "text", position = {x = 0, y = 0.5}, offset = {x = 75, y = 0},
            text = "0", number = 0xFFFF00, alignment = {x = 1, y = 0},
        }),
        level_text = player:hud_add({
            hud_elem_type = "text", position = {x = 0, y = 0.55}, offset = {x = 70, y = 0},
            text = "Lvl 1", number = 0x00FF00, alignment = {x = 1, y = 0},
        }),
        last_level = 1
    }
    
    human_fortress.hud_ids[name] = hud
    
    minetest.after(0.2, function()
        if player and player:is_player() then
            human_fortress.update_gui(player)
        end
    end)
end

-- 4. Події
minetest.register_on_joinplayer(function(player)
    minetest.after(2, function() 
        if player and player:is_player() then
            create_hud(player) 
        end
    end)
end)

minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    if human_fortress.hud_ids then 
        human_fortress.hud_ids[name] = nil 
    end
    if unit_counts then
        unit_counts[name] = nil
    end
end)

-- 5. Крок (оновлюємо HUD + рахуємо юніти)
minetest.register_globalstep(function(dtime)
    -- Оновлення HUD ресурсів (кожні 0.5 сек)
    hud_timer = (hud_timer or 0) + dtime
    if hud_timer >= 0.5 then
        for _, player in ipairs(minetest.get_connected_players()) do
            if player and player:is_player() then
                human_fortress.update_hud(player)
            end
        end
        hud_timer = 0
    end

    -- Підрахунок юнітів (кожні 2 секунди, окремо)
    unit_count_timer = unit_count_timer + dtime
    if unit_count_timer >= 2.0 then
        for _, player in ipairs(minetest.get_connected_players()) do
            if player and player:is_player() then
                local name = player:get_player_name()
                local count = 0
                local ppos = player:get_pos()
                
                -- Шукаємо юнітів гравника в радіусі 300 блоків
                local objs = minetest.get_objects_inside_radius(ppos, 300)
                for _, obj in ipairs(objs) do
                    local ent = obj:get_luaentity()
                    if ent and ent.unit_data and ent.unit_data.owner == name then
                        count = count + 1
                    end
                end
                
                unit_counts[name] = count
            end
        end
        unit_count_timer = 0
    end
end)