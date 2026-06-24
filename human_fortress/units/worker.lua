-- ============================================
-- ЮНІТ: УНІВЕРСАЛЬНИЙ РОБІТНИК (Worker)
-- ============================================

local worker_data = {
    name = "Робітник",
    health = 20,
    speed = 2,
    cost = {wood = 50, food = 25},
}

mobs:register_mob("human_fortress:worker", {
    type = "npc",
    passive = true,
    unit_data = {}, -- Важливо для units.lua
    
    -- Характеристики
    hp_min = 20,
    hp_max = 20,
    collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.3, 0.3},
    visual = "mesh",
    mesh = "fom.obj",
    textures = {{"fom.png"}},
    visual_size = {x=8, y=8},
    
    on_spawn = function(self)
        self.unit_data = self.unit_data or {}
        self.inventory = {wood = 0, stone = 0, food = 0}
        return true
    end, -- Не забувай про кому!

    -- 1. ЦЯ ФУНКЦІЯ ПАКУЄ ДАНІ ПРИ ВИХОДІ З ГРИ АБО ВИВАНТАЖЕННІ КАРТИ
    get_staticdata = function(self)
        -- Зберігаємо всю таблицю unit_data та інвентар через вбудований серіалізатор Luanti
        local tmp = {
            unit_data = self.unit_data or {},
            inventory = self.inventory or {wood = 0, stone = 0, food = 0}
        }
        return minetest.serialize(tmp)
    end,

    -- 2. ЦЯ ФУНКЦІЯ РОЗПАКОВУЄ ДАНІ, КОЛИ ТИ ПЕРЕЗАХОДИШ В ГРУ
    on_activate = function(self, staticdata, dtime_s)
        -- Викликаємо базовий on_activate з Mobs API, щоб моб не зламався
        if mobs.api and mobs.api.on_activate then
            mobs.api.on_activate(self, staticdata, dtime_s)
        end

        -- Якщо є збережені дані — відновлюємо їх
        if staticdata and staticdata ~= "" then
            local data = minetest.deserialize(staticdata)
            if data then
                self.unit_data = data.unit_data or {}
                self.inventory = data.inventory or {wood = 0, stone = 0, food = 0}
            end
        end
    end,
    -- 3. ЛОГІКА СМЕРТІ ЮНІТА (ВИПАДІННЯ РЕСУРСІВ)
    on_die = function(self, pos)
        -- Якщо позиція чомусь загубилася, беремо поточні координати об'єкта
        local drop_pos = pos or self.object:get_pos()
        if not drop_pos then return end

        -- Трохи піднімаємо точку спавну предметів (на 0.5 блока), щоб вони не застрягали в текстурах підлоги
        drop_pos.y = drop_pos.y + 0.5

        -- А) Випадає половина вартості створення моба (25 ефірного дерева та 25 версиформу)
        -- Використовуємо реальні технічні назви твоїх блоків
        minetest.add_item(drop_pos, "human_fortress:versiforn_source 25")
        -- Замість "ether_tree" спавнимо або саджанець, або ефірне дерево/дошку (залежно від того, як названо твій блок)
        -- Якщо у тебе блок дерева називається інакше, просто підправ назву після двокрапки
        minetest.add_item(drop_pos, "human_fortress:ether_tree 25")

        -- Б) Випадає все, що було в рюкзаку Формикса на момент смерті
        if self.inventory then
            if (self.inventory.wood or 0) > 0 then
                minetest.add_item(drop_pos, "human_fortress:ether_tree " .. self.inventory.wood)
            end
            if (self.inventory.stone or 0) > 0 then
                -- Якщо накопав версиформ, то випаде версиформ, якщо звичайний камінь — камінь
                minetest.add_item(drop_pos, "human_fortress:versiforn_source " .. self.inventory.stone)
            end
            if (self.inventory.food or 0) > 0 then
                -- Спавнимо їжу (наприклад, пшеницю чи хліб, дивлячись що у тебе в моді за дефолту)
                minetest.add_item(drop_pos, "farm:wheat " .. self.inventory.food)
            end
        end

        -- Надсилаємо повідомлення власнику, якщо він є в мережі
        local owner = self.unit_data and self.unit_data.owner or ""
        if owner ~= "" then
            minetest.chat_send_player(owner, "💀 Твій Формикс загинув у бою! Ресурси випали на землю.")
        end
    end, -- Не забувай про кому в кінці!

    do_custom = function(self, dtime)
        -- ========================================================
        -- ОНОВЛЕНА ЛОГІКА ЮНІТА (HUMAN FORTRESS MOBS API)
        -- ========================================================

        -- 1. ЗАХИСТ ТА ІНІЦІАЛІЗАЦІЯ
        if not self.unit_data then 
            self.unit_data = {} 
        end
        if not self.inventory then
            self.inventory = {wood = 0, stone = 0, food = 0}
        end

        local owner = self.unit_data.owner or ""

        -- ДОПОМІЖНА ФУНКЦІЯ: РОЗВОРOT ТА РУХ ЮНІТА
        -- ДОПОМІЖНА ФУНКЦІЯ: НАКАЗ ДЛЯ ВБУДОВАНОГО ШІ (ПЛАВНИЙ РУХ)
local move_to = function(entity, target)
    local pos = entity.object:get_pos()
    if not pos or not target then return end

    -- 1. Створюємо таймер руху, щоб не оновлювати швидкість кожного кадру
    entity.move_timer = (entity.move_timer or 0) + 0.1 
    if entity.move_timer < 0.5 then return end -- Оновлюємо напрямок тільки раз на півсекунди
    entity.move_timer = 0

    -- 2. Розрахунок шляху
    if not entity.path_nodes or #entity.path_nodes == 0 then
        local path = minetest.find_path(pos, target, 15, 1, 4, "A*_strict")
        if path and #path > 1 then
            entity.path_nodes = path
            table.remove(entity.path_nodes, 1)
        else
            entity.order = "stand"
            entity.goto_destination = nil
            entity.path_nodes = nil
            return
        end
    end

    if entity.path_nodes and #entity.path_nodes > 0 then
        local next_step = entity.path_nodes[1]
        
        -- Якщо близько до точки — перемикаємо
        if vector.distance(pos, next_step) < 1.2 then
            table.remove(entity.path_nodes, 1)
            if #entity.path_nodes > 0 then next_step = entity.path_nodes[1] end
        end
        
        -- 3. ПЛАВНИЙ РУХ (без дьоргання)
        local dir = vector.direction(pos, next_step)
        local speed = 2.5
        
        -- Встановлюємо швидкість один раз на півсекунди
        entity.object:set_velocity({
            x = dir.x * speed,
            y = entity.object:get_velocity().y, -- Зберігаємо вертикальну швидкість (гравітацію)
            z = dir.z * speed
        })
        
        -- Поворот
        local yaw = math.atan2(-dir.x, dir.z)
        entity.object:set_yaw(yaw)
    end
end

        -- 2. «СЛУХАЧ» КОМАНД ГРАВЦЯ
        if self.unit_data.command then
            self.order = self.unit_data.command
            self.goto_destination = self.unit_data.target
            self.path_nodes = nil
            self.unit_data.command = nil 
            
            if owner ~= "" then
                minetest.chat_send_player(owner, "👷 Юніт отримав наказ: " .. (self.order or "очікування"))
            end
        end

        -- 3. ВИКОНАННЯ РУХУ (MOVE)
        if self.order == "move" and self.goto_destination then
            local pos = self.object:get_pos()
            if vector.distance(pos, self.goto_destination) > 1.5 then
                move_to(self, self.goto_destination)
            else
                self.order = "stand"
                self.path_nodes = nil
                self.object:set_velocity({x=0, y=0, z=0})
            end
            return
        end

        -- 4. ЛОГІКА АВТО-РОЗВАНТАЖЕННЯ
        local total_res = (self.inventory.wood or 0) + (self.inventory.stone or 0) + (self.inventory.food or 0)
        if total_res >= 300 then
            local pos = self.object:get_pos()
            local townhall = minetest.find_node_near(pos, 55, {"human_fortress:townhall"})
            
            if townhall then
                if vector.distance(pos, townhall) > 3 then
                    move_to(self, townhall)
                else
                    if human_fortress.edos_data and human_fortress.edos_data[owner] then
                        local p_res = human_fortress.edos_data[owner]
                        p_res.wood = (p_res.wood or 0) + (self.inventory.wood or 0)
                        p_res.stone = (p_res.stone or 0) + (self.inventory.stone or 0)
                        p_res.food = (p_res.food or 0) + (self.inventory.food or 0)
                        
                        self.inventory = {wood = 0, stone = 0, food = 0}
                        self.path_nodes = nil
                        minetest.chat_send_player(owner, "💰 Робітник успішно розвантажився у Ратуші фортеці!")
                        
                        if self.goto_destination then
                            self.order = "gather"
                        else
                            self.order = "stand"
                        end
                    end
                end
            else
                self.object:set_velocity({x=0, y=0, z=0})
            end
            return 
        end

        -- 5. ЛОГІКА ЗБОРУ РЕСУРСІВ (GATHER)
        if self.order == "gather" and self.goto_destination then
            local pos = self.object:get_pos()
            local dist = vector.distance(pos, self.goto_destination)

            if dist > 2.5 then
                move_to(self, self.goto_destination)
            else
                self.object:set_velocity({x=0, y=0, z=0})
                self.gather_timer = (self.gather_timer or 0) + dtime
                
                if self.gather_timer >= 1.5 then
                    local node = minetest.get_node(self.goto_destination)
                    local node_def = minetest.registered_nodes[node.name]
                    local res_type = nil

                    if node_def and node_def.groups and node_def.groups.ether_tree then
                        res_type = "wood"
                    elseif node.name == "human_fortress:versiforn_source" or node.name:find("stone") then
                        res_type = "stone"
                    elseif node.name:find("wheat") or node.name:find("food") then
                        res_type = "food"
                    end

                    if res_type then
                        local meta = minetest.get_meta(self.goto_destination)
                        
                        if node_def and node_def.groups and node_def.groups.ether_tree then
                            local rem = meta:get_int("remaining")
                            if rem == 0 then rem = node_def._max_ether or 50 end 
                            
                            if rem <= 1 then 
                                minetest.remove_node(self.goto_destination)
                                self.order = "stand"
                                self.goto_destination = nil
                                minetest.chat_send_player(owner, "🌳 Ефірне дерево повністю вирубано!")
                            else 
                                meta:set_int("remaining", rem - 1) 
                            end
                            
                            self.inventory[res_type] = (self.inventory[res_type] or 0) + 1
                            minetest.chat_send_player(owner, "📦 Робітник викачує Ефір (+1). Залишилось у дереві: " .. (rem - 1))
                        
                        elseif node.name == "human_fortress:versiforn_source" then
                            self.inventory[res_type] = (self.inventory[res_type] or 0) + 70
                            minetest.set_node(self.goto_destination, {name = "default:stone"})
                            minetest.chat_send_player(owner, "💎 Знайдено Версиформ! Робітник викопав одразу +70 каменю.")
                            
                            local next_ore = minetest.find_node_near(self.goto_destination, 3, {"human_fortress:versiforn_source"})
                            if next_ore then
                                self.goto_destination = next_ore
                                self.path_nodes = nil
                            else
                                self.order = "stand"
                                self.goto_destination = nil
                            end
                        
                        else
                            minetest.remove_node(self.goto_destination)
                            self.inventory[res_type] = (self.inventory[res_type] or 0) + 1
                            self.order = "stand"
                            self.goto_destination = nil
                        end
                    else
                        self.order = "stand"
                        self.goto_destination = nil
                    end
                    self.gather_timer = 0
                end
            end
            return
        end

        -- 6. БОЙОВА ЛОГІКА
        self.attack_timer = (self.attack_timer or 0) + dtime
        if self.attack_timer >= 2.0 and self.order ~= "move" and self.order ~= "gather" then
            self.attack_timer = 0
            local my_pos = self.object:get_pos()
            
            for _, obj in ipairs(minetest.get_objects_inside_radius(my_pos, 12)) do
                local lua_ent = obj:get_luaentity()
                
                if lua_ent and lua_ent.unit_data and lua_ent.unit_data.owner ~= owner and lua_ent.health and lua_ent.health > 0 then
                    if self.attack then
                        self:attack(obj)
                        break
                    else
                        self.order = "attack_target"
                        self.enemy_object = obj
                        break
                    end
                end
            end
        end

        if self.order == "attack_target" and self.enemy_object then
            local target_obj = self.enemy_object
            if target_obj:get_pos() then
                local t_pos = target_obj:get_pos()
                local dist = vector.distance(self.object:get_pos(), t_pos)
                
                if dist > 2 then
                    move_to(self, t_pos)
                else
                    self.object:set_velocity({x=0, y=0, z=0})
                    local target_ent = target_obj:get_luaentity()
                    if target_ent and target_ent.health then
                        target_ent.health = target_ent.health - 2
                        if target_ent.health <= 0 then
                            self.order = "stand"
                            self.enemy_object = nil
                        end
                    end
                end
            else
                self.order = "stand"
                self.enemy_object = nil
            end
        end
    end, -- ← ТУТ ТЕПЕР ПРАВИЛЬНО: Закриваємо функцію do_custom всередині таблиці моба!
}) -- ← А ТУТ МИ ЗАКРИЛИ ТАБЛИЦЮ ТА ФУНКЦІЮ register_mob!

-- Додаємо в список
if not human_fortress.units_list then human_fortress.units_list = {} end
human_fortress.units_list.worker = {
    name = worker_data.name,
    health = worker_data.health,
    speed = worker_data.speed,
    cost = worker_data.cost,
    profession = "basic",
    entity = "human_fortress:worker",
}