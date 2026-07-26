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
    -- ... вище ваш код ...
    visual = "mesh",
    mesh = "fom.gltf",
    textures = {{"fom.png"}},
    visual_size = {x=1, y=1},

    -- Додайте це:
    animation = {
        speed_normal = 1,
        speed_run = 15,
        stand_start = 13,
        stand_end = 37,
        walk_start = 0,
        walk_end = 12,
        punch_start = 41,
        punch_end = 60,
    },
    -- ... далі ваш код ...

    on_spawn = function(self)
        self.unit_data = self.unit_data or {}
        self.inventory = {wood = 0, stone = 0, food = 0}
        return true
    end,

    -- 1. ЦЯ ФУНКЦІЯ ПАКУЄ ДАНІ ПРИ ВИХОДІ З ГРИ АБО ВИВАНТАЖЕННІ КАРТИ
    get_staticdata = function(self)
        local tmp = {
            unit_data = self.unit_data or {},
            inventory = self.inventory or {wood = 0, stone = 0, food = 0}
        }
        return minetest.serialize(tmp)
    end,

    -- 2. ЦЯ ФУНКЦІЯ РОЗПАКОВУЄ ДАНІ, КОЛИ ТИ ПЕРЕЗАХОДИШ В ГРУ
    on_activate = function(self, staticdata, dtime_s)
        if mobs.api and mobs.api.on_activate then
            mobs.api.on_activate(self, staticdata, dtime_s)
        end

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
        local drop_pos = pos or self.object:get_pos()
        if not drop_pos then return end

        drop_pos.y = drop_pos.y + 0.5

        minetest.add_item(drop_pos, "human_fortress:versiforn_source 25")
        minetest.add_item(drop_pos, "human_fortress:ether_tree 25")

        if self.inventory then
            if (self.inventory.wood or 0) > 0 then
                minetest.add_item(drop_pos, "human_fortress:ether_tree " .. self.inventory.wood)
            end
            if (self.inventory.stone or 0) > 0 then
                minetest.add_item(drop_pos, "human_fortress:versiforn_source " .. self.inventory.stone)
            end
            if (self.inventory.food or 0) > 0 then
                minetest.add_item(drop_pos, "farm:wheat " .. self.inventory.food)
            end
        end

        local owner = self.unit_data and self.unit_data.owner or ""
        if owner ~= "" then
            minetest.chat_send_player(owner, "💀 Твій Формикс загинув у бою! Ресурси випали на землю.")
        end
    end,

    -- ========================================================
    -- ОСНОВНИЙ ЦИКЛ ЮНІТА (HUMAN FORTRESS MOBS API)
    -- ========================================================
    do_custom = function(self, dtime)

        -- 0. ПРИВІТАННЯ (не блокує основну логіку — без раннього return)
        self.timer_greet = (self.timer_greet or 0) + dtime
        if self.timer_greet >= 2 then
            self.timer_greet = 0

            local greet_pos = self.object:get_pos()
            local players = minetest.get_objects_inside_radius(greet_pos, 3)

            local player_found = false
            for _, obj in ipairs(players) do
                if obj:is_player() then
                    player_found = true
                    break
                end
            end

            if player_found and not self.has_greeted then
                minetest.sound_play("hello_sound", {pos = greet_pos, max_hear_distance = 10})
                self.has_greeted = true
            elseif not player_found then
                self.has_greeted = false
            end
        end

        -- 1. ЗАХИСТ ТА ІНІЦІАЛІЗАЦІЯ
        if not self.unit_data then
            self.unit_data = {}
        end
        if not self.inventory then
            self.inventory = {wood = 0, stone = 0, food = 0}
        end

        local owner = self.unit_data.owner or ""

        -- ДОПОМІЖНА ФУНКЦІЯ: НАКАЗ ДЛЯ ВБУДОВАНОГО ШІ (ПЛАВНИЙ РУХ)
        local move_to = function(entity, target)
            local pos = entity.object:get_pos()
            if not pos or not target then return end

            local dist = vector.distance(pos, target)
            if dist < 1.5 then return end
            self:set_animation("stand")

            entity.move_timer = (entity.move_timer or 0) + 0.1
            if entity.move_timer < 0.3 then return end
            entity.move_timer = 0

            if not entity.path_nodes or #entity.path_nodes == 0 then
                entity.path_fail_count = (entity.path_fail_count or 0)

                local path = minetest.find_path(pos, target, 20, 1, 4, "A*_strict")
                          or minetest.find_path(pos, target, 20, 2, 4, "A*")

                if path and #path > 1 then
                    entity.path_nodes = path
                    entity.path_fail_count = 0
                    table.remove(entity.path_nodes, 1)
                else
                    entity.path_fail_count = entity.path_fail_count + 1
                    if entity.path_fail_count >= 3 then
                        entity.use_direct_move = true
                        entity.path_fail_count = 0
                    else
                        -- Поки триває пошук шляху — стоїмо у "stand", щоб не залипало на "walk"
                        self:set_animation("stand")
                        return
                    end
                end
            end

            if entity.use_direct_move then
                local dir = vector.direction(pos, target)
                entity.object:set_velocity({
                    x = dir.x * 2.5,
                    y = entity.object:get_velocity().y,
                    z = dir.z * 2.5
                })
                local yaw = math.atan2(-dir.x, dir.z)
                entity.object:set_yaw(yaw)
                self:set_animation("walk") -- ВИПРАВЛЕННЯ: анімація ходьби для прямого руху

                if dist < 2.0 then
                    entity.use_direct_move = false
                end
                return
            end

            if entity.path_nodes and #entity.path_nodes > 0 then
                local next_step = entity.path_nodes[1]

                if vector.distance(pos, next_step) < 1.0 then
                    table.remove(entity.path_nodes, 1)
                    if #entity.path_nodes == 0 then return end
                    next_step = entity.path_nodes[1]
                end

                local dir = vector.direction(pos, next_step)
                entity.object:set_velocity({
                    x = dir.x * 2.5,
                    y = entity.object:get_velocity().y,
                    z = dir.z * 2.5
                })
                self:set_animation("walk")
                local yaw = math.atan2(-dir.x, dir.z)
                entity.object:set_yaw(yaw)
            end
        end

        -- 2. «СЛУХАЧ» КОМАНД ГРАВЦЯ
        if self.unit_data.command then
            self.order = self.unit_data.command
            self.goto_destination = self.unit_data.target

            self.path_nodes = nil
            self.path_fail_count = 0
            self.use_direct_move = false
            self.move_timer = 0
            self.unload_target = nil

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
                self:set_animation("stand")
            end
            return
        end

        -- 4. ЛОГІКА АВТО-РОЗВАНТАЖЕННЯ
        local total_res = (self.inventory.wood or 0) + (self.inventory.stone or 0) + (self.inventory.food or 0)

        if total_res >= 300 or self.order == "unload" then
            local pos = self.object:get_pos()

            if not self.unload_target then
                local townhall = minetest.find_node_near(pos, 55, {"human_fortress:townhall"})
                if townhall then
                    self.unload_target = townhall
                else
                    self.object:set_velocity({x=0, y=0, z=0})
                    return
                end
            end

            self.order = "unload"

            if vector.distance(pos, self.unload_target) > 3 then
                move_to(self, self.unload_target)
            else
                self.object:set_velocity({x=0, y=0, z=0})
                self:set_animation("stand")

                if human_fortress.edos_data and human_fortress.edos_data[owner] then
                    local p_res = human_fortress.edos_data[owner]
                    p_res.wood  = (p_res.wood  or 0) + (self.inventory.wood  or 0)
                    p_res.stone = (p_res.stone or 0) + (self.inventory.stone or 0)
                    p_res.food  = (p_res.food  or 0) + (self.inventory.food  or 0)

                    minetest.chat_send_player(owner, "💰 Робітник розвантажився у Ратуші!")
                end

                self.inventory = {wood = 0, stone = 0, food = 0}
                self.path_nodes = nil
                self.unload_target = nil

                if self.last_gather_pos then
                    self.goto_destination = self.last_gather_pos
                    self.order = "gather"
                else
                    self.order = "stand"
                end
            end
            return
        end

        -- 5. ЛОГІКА ЗБОРУ РЕСУРСІВ (GATHER)
        if self.order == "gather" and self.goto_destination then
            local pos = self.object:get_pos()
            local dist = vector.distance(pos, self.goto_destination)

            if dist > 2.5 then
                self.last_gather_pos = self.goto_destination
                move_to(self, self.goto_destination)
                return
            else
                self.object:set_velocity({x=0, y=0, z=0})
                self:set_animation("punch") -- анімація видобутку ресурсу
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
                    self:set_animation("punch") -- ВИПРАВЛЕННЯ: анімація удару
                    local target_ent = target_obj:get_luaentity()
                    if target_ent and target_ent.health then
                        target_ent.health = target_ent.health - 2
                        if target_ent.health <= 0 then
                            self.order = "stand"
                            self.enemy_object = nil
                            self:set_animation("stand")
                        end
                    end
                end
            else
                self.order = "stand"
                self.enemy_object = nil
                self:set_animation("stand")
            end
        end
    end, -- закриває do_custom
}) -- закриває mobs:register_mob

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