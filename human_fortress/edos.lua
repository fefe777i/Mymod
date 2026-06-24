local storage = minetest.get_mod_storage()

-- Підрахунок EDOS (інвентар)
function count_edos(player)
    if not player then return 0 end
    local inv = player:get_inventory()
    if not inv then return 0 end
    
    local count = 0
    local list = inv:get_list("main")
    
    for i = 1, #list do
        local stack = list[i]
        if stack and not stack:is_empty() and stack:get_name() == "human_fortress:edos" then
            count = count + stack:get_count()
        end
    end
    
    return count
end

-- Видалення EDOS (інвентар)
function remove_edos(player, amount)
    if not player then return 0 end
    local inv = player:get_inventory()
    if not inv then return 0 end
    
    local removed = 0
    local list = inv:get_list("main")
    
    for i = 1, #list do
        local stack = list[i]
        if stack and not stack:is_empty() and stack:get_name() == "human_fortress:edos" then
            local stack_count = stack:get_count()
            local to_remove = math.min(amount - removed, stack_count)
            
            if to_remove > 0 then
                if to_remove >= stack_count then
                    inv:set_stack("main", i, ItemStack(""))
                else
                    stack:set_count(stack_count - to_remove)
                    inv:set_stack("main", i, stack)
                end
                removed = removed + to_remove
            end
            
            if removed >= amount then
                break
            end
        end
    end
    
    return removed
end

-- Видача EDOS (інвентар)
function give_edos(player, amount)
    if not player then return 0 end
    local inv = player:get_inventory()
    if not inv then return 0 end
    
    local given = 0
    local stack_max = 99999
    
    while amount > 0 do
        local stack_size = math.min(amount, stack_max)
        local stack = ItemStack("human_fortress:edos " .. stack_size)
        
        if inv:room_for_item("main", stack) then
            inv:add_item("main", stack)
            given = given + stack_size
            amount = amount - stack_size
        else
            local pos = player:get_pos()
            if pos then
                pos.y = pos.y + 1
                minetest.add_item(pos, stack)
                given = given + stack_size
                amount = amount - stack_size
            else
                break
            end
        end
    end
    
    return given
end

-- ФУНКЦІЇ ДЛЯ РОБОТИ З ВАШОЮ СИСТЕМОЮ SCORE
-- Отримання ресурсів гравця з вашої системи
function get_player_resources(player_name)
    if not human_fortress or not human_fortress.edos_data then
        return {score = 0, wood = 0, stone = 0, food = 0}
    end
    
    local data = human_fortress.edos_data[player_name]
    if not data then
        return {score = 0, wood = 0, stone = 0, food = 0}
    end
    
    return {
        score = data.score or 0,
        wood = data.wood or 0,
        stone = data.stone or 0,
        food = data.food or 0
    }
end

-- Видалення ресурсів через вашу систему
function remove_resources(player_name, cost)
    if not human_fortress or not human_fortress.edos_data then
        return false
    end
    
    local data = human_fortress.edos_data[player_name]
    if not data then
        human_fortress.edos_data[player_name] = {}
        data = human_fortress.edos_data[player_name]
    end
    
    -- Перевіряємо чи достатньо ресурсів
    for resource, amount in pairs(cost) do
        if (data[resource] or 0) < amount then
            return false, resource
        end
    end
    
    -- Забираємо ресурси
    for resource, amount in pairs(cost) do
        data[resource] = (data[resource] or 0) - amount
    end
    
    -- Зберігаємо дані
    if human_fortress.save_data then
        human_fortress.save_data()
    end
    
    return true
end

-- Додавання ресурсів
function add_resources(player_name, resource, amount)
    if not human_fortress or not human_fortress.edos_data then
        return false
    end
    
    local data = human_fortress.edos_data[player_name]
    if not data then
        human_fortress.edos_data[player_name] = {}
        data = human_fortress.edos_data[player_name]
    end
    
    data[resource] = (data[resource] or 0) + amount
    
    if human_fortress.save_data then
        human_fortress.save_data()
    end
    
    return true
end

-- Дані гравців (для вилок)
local player_data = minetest.deserialize(storage:get_string("fortress_player_data")) or {}

-- Збереження даних
function save_fortress_data()
    storage:set_string("fortress_player_data", minetest.serialize(player_data))
end

-- Отримання даних гравця
function get_player_data(player_name)
    if not player_name then return {} end
    
    player_data[player_name] = player_data[player_name] or {
        upgrades = {},
        locations = {},
        words = {},
        units_mode = false,
        upgrade_scroll_x = 0,
        upgrade_scroll_y = 0,
        pending_activation_pos = nil
    }
    return player_data[player_name]
end

-- Скидання даних гравця
function reset_player_data(player_name)
    player_data[player_name] = {
        upgrades = {},
        locations = {},
        words = {},
        units_mode = false,
        upgrade_scroll_x = 0,
        upgrade_scroll_y = 0,
        pending_activation_pos = nil
    }
    save_fortress_data()
    minetest.chat_send_player(player_name, "🔄 Дані фортеці скинуто!")
end

-- Команда для скидання даних
minetest.register_chatcommand("reset_fortress", {
    description = "Скинути прогрес фортеці",
    func = function(name)
        reset_player_data(name)
    end
})

-- Команда для перевірки балансу
minetest.register_chatcommand("edos", {
    description = "Перевірити кількість Ейдосів",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if player then
            local inv_count = count_edos(player)
            local score_res = get_player_resources(name)
            minetest.chat_send_player(name, "💰 Інвентар: " .. inv_count .. " EDOS | Система: " .. (score_res.score or 0) .. " Ейдосів")
        end
    end
})

-- Команда для додавання Ейдосів (тест)
minetest.register_chatcommand("add_edos", {
    description = "Додати Ейдоси (для тесту)",
    func = function(name, amount)
        amount = tonumber(amount) or 10
        add_resources(name, "score", amount)
        minetest.chat_send_player(name, "✅ Отримано " .. amount .. " Ейдосів!")
        
        local resources = get_player_resources(name)
        minetest.chat_send_player(name, "💰 Поточний баланс: " .. (resources.score or 0) .. " Ейдосів")
    end
})