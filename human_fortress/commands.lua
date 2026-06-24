-- Система команд для Human Fortress RTS
human_fortress.select_units = function(player)
    local name = player:get_player_name()
    local player_data = human_fortress.players[name]
    if not player_data then return end
    
    player_data.selected = {}
    
    local pos = player:get_pos()
    local range = 10
    
    for _, unit in ipairs(player_data.units) do
        if unit.entity then
            local unit_pos = unit.entity:get_pos()
            if unit_pos and vector.distance(pos, unit_pos) < range then
                table.insert(player_data.selected, unit.id)
            end
        end
    end
    
    if #player_data.selected > 0 then
        minetest.chat_send_player(name, "Виділено " .. #player_data.selected .. " юнітів")
    else
        minetest.chat_send_player(name, "Немає юнітів поблизу")
    end
end

human_fortress.issue_command = function(player, command, target)
    local name = player:get_player_name()
    local player_data = human_fortress.players[name]
    if not player_data or #player_data.selected == 0 then 
        minetest.chat_send_player(name, "Немає виділених юнітів")
        return 
    end
    
    local command_count = 0
    
    for _, unit_id in ipairs(player_data.selected) do
        local unit = player_data.units[unit_id]
        if unit and unit.health > 0 then
            unit.command = command
            unit.target = target
            
            if command == "gather" then
                unit.final_command = "gather"
            elseif command == "build" then
                unit.final_command = "build"
            end
            
            command_count = command_count + 1
        end
    end
    
    if command_count > 0 then
        local command_names = {
            move = "руху",
            gather = "збору",
            build = "будівництва",
            attack = "атаки"
        }
        
        minetest.chat_send_player(name, 
            "Команда " .. (command_names[command] or command) .. 
            " видана " .. command_count .. " юнітам")
    else
        minetest.chat_send_player(name, "Не вдалося видати команду")
    end
end

-- Допоміжна функція для команди атаки
human_fortress.issue_attack_command = function(player, target_entity)
    local name = player:get_player_name()
    local player_data = human_fortress.players[name]
    if not player_data or #player_data.selected == 0 then return end
    
    for _, unit_id in ipairs(player_data.selected) do
        local unit = player_data.units[unit_id]
        if unit and unit.health > 0 then
            unit.command = "attack"
            unit.target = target_entity:get_pos()
            unit.attack_target = target_entity
            
            -- Перевірити, чи юніт може атакувати
            if unit.type == "worker" then
                minetest.chat_send_player(name, "Робітники не можуть атакувати!")
                unit.command = nil
            end
        end
    end
end

-- Функція для очищення команд
human_fortress.clear_commands = function(player)
    local name = player:get_player_name()
    local player_data = human_fortress.players[name]
    if not player_data then return end
    
    for _, unit in ipairs(player_data.units) do
        unit.command = nil
        unit.target = nil
        unit.attack_target = nil
        unit.gather_timer = nil
        unit.build_timer = nil
    end
    
    minetest.chat_send_player(name, "Всі команди очищено")
end

-- Функція для виділення всіх юнітів
human_fortress.select_all_units = function(player)
    local name = player:get_player_name()
    local player_data = human_fortress.players[name]
    if not player_data then return end
    
    player_data.selected = {}
    
    for id, unit in ipairs(player_data.units) do
        if unit and unit.health > 0 then
            table.insert(player_data.selected, id)
        end
    end
    
    if #player_data.selected > 0 then
        minetest.chat_send_player(name, "Виділено всіх юнітів: " .. #player_data.selected)
    else
        minetest.chat_send_player(name, "Немає юнітів")
    end
end

-- Функція для виділення юнітів за типом
human_fortress.select_units_by_type = function(player, unit_type)
    local name = player:get_player_name()
    local player_data = human_fortress.players[name]
    if not player_data then return end
    
    player_data.selected = {}
    
    for id, unit in ipairs(player_data.units) do
        if unit and unit.type == unit_type and unit.health > 0 then
            table.insert(player_data.selected, id)
        end
    end
    
    local type_names = {
        worker = "робітників",
        warrior = "воїнів",
        archer = "лучників"
    }
    
    if #player_data.selected > 0 then
        minetest.chat_send_player(name, 
            "Виділено " .. #player_data.selected .. " " .. 
            (type_names[unit_type] or unit_type))
    else
        minetest.chat_send_player(name, "Немає " .. (type_names[unit_type] or unit_type))
    end
end

-- Реєстрація чат-команд для керування
minetest.register_chatcommand("rts_select_all", {
    description = "Select all your units",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if player then
            human_fortress.select_all_units(player)
            return true, "All units selected"
        end
        return false, "Player not found"
    end
})

minetest.register_chatcommand("rts_select_workers", {
    description = "Select all workers",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if player then
            human_fortress.select_units_by_type(player, "worker")
            return true, "Workers selected"
        end
        return false, "Player not found"
    end
})

minetest.register_chatcommand("rts_select_warriors", {
    description = "Select all warriors",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if player then
            human_fortress.select_units_by_type(player, "warrior")
            return true, "Warriors selected"
        end
        return false, "Player not found"
    end
})

minetest.register_chatcommand("rts_select_archers", {
    description = "Select all archers",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if player then
            human_fortress.select_units_by_type(player, "archer")
            return true, "Archers selected"
        end
        return false, "Player not found"
    end
})

minetest.register_chatcommand("rts_clear_commands", {
    description = "Clear all commands from selected units",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if player then
            human_fortress.clear_commands(player)
            return true, "Commands cleared"
        end
        return false, "Player not found"
    end
})

minetest.register_chatcommand("rts_move", {
    description = "Send selected units to coordinates (x,y,z)",
    params = "<x> <y> <z>",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Player not found" end
        
        local x, y, z = param:match("^(%-?%d+)%s+(%-?%d+)%s+(%-?%d+)$")
        if not x or not y or not z then
            return false, "Usage: /rts_move <x> <y> <z>"
        end
        
        local target_pos = {
            x = tonumber(x),
            y = tonumber(y),
            z = tonumber(z)
        }
        
        human_fortress.issue_command(player, "move", target_pos)
        return true, "Move command issued to " .. minetest.pos_to_string(target_pos)
    end
})

minetest.register_chatcommand("rts_gather", {
    description = "Send selected units to gather at coordinates",
    params = "<x> <y> <z>",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Player not found" end
        
        local x, y, z = param:match("^(%-?%d+)%s+(%-?%d+)%s+(%-?%d+)$")
        if not x or not y or not z then
            return false, "Usage: /rts_gather <x> <y> <z>"
        end
        
        local target_pos = {
            x = tonumber(x),
            y = tonumber(y),
            z = tonumber(z)
        }
        
        -- Перевірити, чи це ресурс
        local node = minetest.get_node(target_pos)
        local is_resource = node.name == "human_fortress:wood" or 
                           node.name == "human_fortress:stone" or 
                           node.name == "human_fortress:food_source"
        
        if not is_resource then
            return false, "Це не ресурс для збору"
        end
        
        human_fortress.issue_command(player, "gather", target_pos)
        return true, "Gather command issued"
    end
})

minetest.register_chatcommand("rts_status", {
    description = "Show status of selected units",
    func = function(name, param)
        local player_data = human_fortress.players[name]
        if not player_data then return false, "Player data not found" end
        
        if #player_data.selected == 0 then
            return true, "Немає виділених юнітів. Загалом юнітів: " .. #player_data.units
        end
        
        local status = "Виділено " .. #player_data.selected .. " юнітів:\n"
        local types = {}
        local commands = {}
        
        for _, unit_id in ipairs(player_data.selected) do
            local unit = player_data.units[unit_id]
            if unit then
                -- Підрахунок за типами
                types[unit.type] = (types[unit.type] or 0) + 1
                
                -- Підрахунок за командами
                local cmd = unit.command or "без команди"
                commands[cmd] = (commands[cmd] or 0) + 1
            end
        end
        
        -- Додати інформацію про типи
        for unit_type, count in pairs(types) do
            local type_names = {
                worker = "робітників",
                warrior = "воїнів", 
                archer = "лучників"
            }
            status = status .. "  " .. count .. " " .. (type_names[unit_type] or unit_type) .. "\n"
        end
        
        -- Додати інформацію про команди
        status = status .. "Команди:\n"
        for cmd, count in pairs(commands) do
            local cmd_names = {
                move = "рух",
                gather = "збір",
                build = "будівництво",
                attack = "атака"
            }
            status = status .. "  " .. count .. " - " .. (cmd_names[cmd] or cmd) .. "\n"
        end
        
        return true, status
    end
})

print("[Human Fortress RTS] Commands system loaded")