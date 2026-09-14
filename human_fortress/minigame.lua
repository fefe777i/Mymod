-- ============================================
-- МІНІ-ГРА "КВІТКАГЕЙМ" (ВЕРСІЯ З ТЕЛЕПОРТАЦІЄЮ ВНИЗ)
-- ============================================

-- 1. Реєстрація ігрових блоків
minetest.register_node("human_fortress:wool_game", {
    description = "Ігровий блок",
    tiles = {"wool_green.png"}, 
    groups = {snappy = 1, oddly_breakable_by_hand = 3, not_in_creative_inventory = 1},
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        if clicker and clicker:is_player() then
            human_fortress.check_game_step(pos, clicker)
        end
    end,
})

minetest.register_node("human_fortress:wool_game_active", {
    description = "Ігровий блок (Активний)",
    tiles = {"wool_blue.png"}, 
    groups = {not_in_creative_inventory = 1},
})

-- 2. Реєстрація головної квітки
minetest.register_node("human_fortress:flouwergame", {
    description = "Квіткагейм",
    drawtype = "mesh",
    mesh = "flou.obj",
    tiles = {"flou.png"},
    paramtype = "light",
    paramtype2 = "facedir",
    groups = {cracky = 3, oddly_breakable_by_hand = 3},

    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        if not clicker or not clicker:is_player() then return end
        
        local meta = minetest.get_meta(pos)
        local last_use = meta:get_int("last_use_time")
        local current_time = minetest.get_gametime()
        local cooldown = 180 

        if current_time < last_use + cooldown then
            local wait_time = (last_use + cooldown) - current_time
            minetest.chat_send_player(clicker:get_player_name(), 
                "⏳ Квітка виснажена! Зачекайте ще " .. wait_time .. " сек.")
            return
        end

        meta:set_int("last_use_time", current_time)
        human_fortress.start_wool_game(clicker, pos)
    end,
})

-- ============================================
-- НАГОРОДА: ФОРМСПЕКС З ЕЙДОСАМИ
-- ============================================

function human_fortress.show_reward_formspec(player, count)
    local name = player:get_player_name()
    local inv_name = "hf_reward_" .. name
    
    -- Видаляємо старий інвентар, якщо був
    local old_inv = minetest.get_inventory({type = "detached", name = inv_name})
    if old_inv then
        minetest.remove_detached_inventory(inv_name)
    end
    
    local inv = minetest.create_detached_inventory(inv_name, {
        allow_move = function() return 0 end,
        allow_put = function() return 0 end,
        allow_take = function(inv, listname, index, stack, player)
            return stack:get_count()
        end,
    })
    
    inv:set_size("main", 1)
    inv:add_item("main", ItemStack("human_fortress:edos " .. count))
    
    local formspec = 
        "size[8,4]" ..
        "bgcolor[#1a1a2e;true]" ..
        "box[0,0;8,0.8;#16213e]" ..
        "label[2.5,0.2;🏆 НАГОРОДА ЗА ПЕРЕМОГУ!]" ..
        "label[3,1.2;Забери свої ейдоси:]" ..
        "list[detached:" .. inv_name .. ";main;3.5,2;1,1;]" ..
        "list[current_player;main;0,3;8,1;]" ..
        "listring[detached:" .. inv_name .. ";main]" ..
        "listring[current_player;main]"
    
    minetest.show_formspec(name, "human_fortress:reward", formspec)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "human_fortress:reward" then return end
    
    local name = player:get_player_name()
    local inv_name = "hf_reward_" .. name
    local inv = minetest.get_inventory({type = "detached", name = inv_name})
    
    if inv then
        -- Переносимо залишки в інвентар гравця
        local leftover = inv:get_list("main")
        local player_inv = player:get_inventory()
        
        for _, stack in ipairs(leftover) do
            if not stack:is_empty() then
                if player_inv:room_for_item("main", stack) then
                    player_inv:add_item("main", stack)
                else
                    minetest.add_item(player:get_pos(), stack)
                    minetest.chat_send_player(name, "⚠️ " .. stack:get_count() .. " ейдосів випало (інвентар повний)!")
                end
            end
        end
        
        minetest.remove_detached_inventory(inv_name)
    end
    
    if fields.quit then
        minetest.chat_send_player(name, "🎁 Нагорода забрана!")
    end
end)

-- 3. Логіка гри Квіткагейм
human_fortress.game_data = {}

function human_fortress.start_wool_game(player, flower_pos)
    local name = player:get_player_name()
    local game_y = flower_pos.y - 10
    
    human_fortress.game_data[name] = {
        flower_pos = flower_pos,
        sequence = {},
        player_input = {},
        round = 1,
        block_positions = {
            {x = flower_pos.x - 1, y = game_y, z = flower_pos.z},
            {x = flower_pos.x + 0, y = game_y, z = flower_pos.z},
            {x = flower_pos.x + 1, y = game_y, z = flower_pos.z},
            {x = flower_pos.x + 2, y = game_y, z = flower_pos.z},
        }
    }
    
    player:set_pos({x = flower_pos.x, y = game_y + 1, z = flower_pos.z})
    
    for _, p in ipairs(human_fortress.game_data[name].block_positions) do
        minetest.set_node(p, {name = "human_fortress:wool_game"})
    end
    
    minetest.chat_send_player(name, "✨ Ви перемістилися вниз! Гра почнеться за 3 секунди.")
    minetest.sound_play("default_place_node", {pos = flower_pos, gain = 1.0}, true)
    
    minetest.after(3, function()
        human_fortress.show_sequence(name)
    end)
end

function human_fortress.show_sequence(name)
    local data = human_fortress.game_data[name]
    if not data then return end
    
    data.sequence = {}
    data.player_input = {}
    
    local steps = 3 + data.round 
    
    for i = 1, steps do
        local rand_idx = math.random(1, 4)
        table.insert(data.sequence, rand_idx)
        
        minetest.after(i * 0.8, function()
            if human_fortress.game_data[name] then
                local p = data.block_positions[rand_idx]
                minetest.set_node(p, {name = "human_fortress:wool_game_active"})
                minetest.after(0.4, function()
                    if human_fortress.game_data[name] then
                        minetest.set_node(p, {name = "human_fortress:wool_game"})
                    end
                end)
            end
        end)
    end
end

function human_fortress.check_game_step(pos, player)
    local name = player:get_player_name()
    local data = human_fortress.game_data[name]
    if not data then return end
    
    local clicked_idx = 0
    for i, p in ipairs(data.block_positions) do
        if vector.equals(pos, p) then
            clicked_idx = i
            break
        end
    end
    
    if clicked_idx == 0 then return end
    
    table.insert(data.player_input, clicked_idx)
    local step = #data.player_input
    
    if data.player_input[step] ~= data.sequence[step] then
        minetest.chat_send_player(name, "❌ Помилка! Запам'ятовуй знову.")
        human_fortress.show_sequence(name)
        return
    end
    
    if #data.player_input == #data.sequence then
        if data.round < 3 then
            data.round = data.round + 1
            minetest.chat_send_player(name, "✅ Раунд " .. (data.round - 1) .. "/3 пройдено!")
            minetest.after(1, function() 
                human_fortress.show_sequence(name) 
            end)
        else
            -- ПЕРЕМОГА — ФОРМСПЕКС З НАГОРОДОЮ
            local reward_count = math.random(6, 20)
            
            minetest.chat_send_player(name, "🎉 Перемога! Забери нагороду!")
            human_fortress.show_reward_formspec(player, reward_count)
            
            minetest.after(0.5, function()
                player:set_pos(data.flower_pos)
                for _, p in ipairs(data.block_positions) do
                    minetest.remove_node(p)
                end
                human_fortress.game_data[name] = nil
            end)
        end
    end
end

-- ============================================
-- ДРУГА МІНІ-ГРА: ЛОГІЧНІ БЛОКИ (5 В РЯД)
-- ============================================

-- Функція перевірки перемоги
local function check_minigame_win(pos, player, teleporter_pos)
    if not teleporter_pos then return end
    
    local target_y = teleporter_pos.y - 10
    local all_same = true
    local first_param2 = nil
    local positions = {}

    for i = 1, 5 do
        local check_pos = {x = teleporter_pos.x + i, y = target_y, z = teleporter_pos.z + 2}
        table.insert(positions, check_pos)
        
        local node = minetest.get_node(check_pos)
        if node.name ~= "human_fortress:logic_block" then
            return
        end
        
        if first_param2 == nil then
            first_param2 = node.param2
        else
            if node.param2 ~= first_param2 then
                all_same = false
            end
        end
    end

    if all_same then
        local count = math.random(5, 14)
        
        minetest.chat_send_player(player:get_player_name(), "🎉 Перемога! Забери нагороду!")
        human_fortress.show_reward_formspec(player, count)

        player:set_pos({x = teleporter_pos.x, y = teleporter_pos.y + 1, z = teleporter_pos.z})

        for _, p in ipairs(positions) do
            minetest.remove_node(p)
        end
    end
end

minetest.register_node("human_fortress:tel0eporter", {
    description = "Телепортер в міні-гру",
    drawtype = "mesh",
    mesh = "stones.obj",
    tiles = {"stones.png"}, 
    paramtype = "light",
    groups = {cracky = 3},
    on_rightclick = function(pos, node, clicker)
        if not clicker or not clicker:is_player() then return end
        
        local player_name = clicker:get_player_name()
        local meta = clicker:get_meta()
        local last_time = meta:get_int("last_minigame_time") or 0
        local current_time = minetest.get_gametime()
        
        if current_time - last_time < 60 then
            local wait_time = 60 - (current_time - last_time)
            minetest.chat_send_player(player_name, "Зачекайте ще " .. wait_time .. " сек. перед наступною грою!")
            return
        end

        meta:set_int("last_minigame_time", current_time)

        local target = {x = pos.x, y = pos.y - 10, z = pos.z}
        clicker:set_pos(target)

        for i = 1, 5 do
            local b_pos = {x = target.x + i, y = target.y, z = target.z + 2}
            minetest.set_node(b_pos, {
                name = "human_fortress:logic_block",
                param2 = math.random(0, 1)
            })
            local b_meta = minetest.get_meta(b_pos)
            b_meta:set_string("teleport_pos", minetest.serialize(pos))
        end
        
        minetest.chat_send_player(player_name, "Гра почалася! Зробіть так, щоб усі малюнки на блоках дивилися в один бік.")
    end,
})

minetest.register_node("human_fortress:logic_block", {
    description = "Блок міні-гри",
    drawtype = "nodebox",
    paramtype = "light",
    paramtype2 = "facedir",
    tiles = {
        "logic.png", 
        "wool_green.png",    
        "wool_green.png"     
    },
    node_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
    },
    groups = {not_in_creative_inventory = 1},
    on_rightclick = function(pos, node, clicker)
        local new_p2 = (node.param2 == 0) and 1 or 0

        minetest.swap_node(pos, {name = node.name, param2 = new_p2})
        
        local meta = minetest.get_meta(pos)
        local tele_pos_str = meta:get_string("teleport_pos")
        if tele_pos_str ~= "" then
            local tele_pos = minetest.deserialize(tele_pos_str)
            check_minigame_win(pos, clicker, tele_pos)
        end
    end,
})