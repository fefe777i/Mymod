-- ============================================
-- ЮНІТ: ЛІСОРУБ (Lumberjack — Тільки Ефір)
-- ============================================

local lumberjack_data = {
    name = "Лісоруб",
    health = 25,
    speed = 2,
    cost = {wood = 80, food = 40},
}

mobs:register_mob("human_fortress:lumberjack", {
    type = "npc",
    passive = true,

    hp_min = lumberjack_data.health,
    hp_max = lumberjack_data.health,
    armor = 100,

    collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.3, 0.3},
    visual = "mesh",
    mesh = "fooom.obj",
    textures = {{"fooom.png"}},
    visual_size = {x=8, y=8},

    walk_velocity = 1,
    run_velocity = lumberjack_data.speed,
    jump = true,
    stepheight = 0.6,

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

    -- ========================================
    -- СПАВН
    -- ========================================
    on_spawn = function(self)
        self.unit_data = {
            unit_id = "u_" .. tostring(math.random(1000000, 9999999)) .. "_" .. tostring(os.time()) .. "_" .. tostring(math.random(1, 10000)),
        }
        self.inventory = {wood = 0}
        return true
    end,

    -- ========================================
    -- ЗБЕРЕЖЕННЯ / ВІДНОВЛЕННЯ
    -- ========================================
    get_staticdata = function(self)
        local data = {
            unit_data = self.unit_data or {},
            inventory = self.inventory or {wood = 0},
            order = self.order,
            goto_destination = self.goto_destination,
            last_gather_pos = self.last_gather_pos,
            has_greeted = self.has_greeted,
            unload_target = self.unload_target,
        }
        return minetest.serialize(data)
    end,

    on_activate = function(self, staticdata, dtime_s)
        if mobs.api and mobs.api.on_activate then
            mobs.api.on_activate(self, staticdata, dtime_s)
        end

        self.unit_data = {}
        self.inventory = {wood = 0}
        self.order = nil
        self.goto_destination = nil
        self.last_gather_pos = nil
        self.has_greeted = false
        self.unload_target = nil

        if staticdata and staticdata ~= "" then
            local data = minetest.deserialize(staticdata)
            if data and type(data) == "table" then
                self.unit_data = data.unit_data or {}
                self.inventory = data.inventory or {wood = 0}
                self.order = data.order
                self.goto_destination = data.goto_destination
                self.last_gather_pos = data.last_gather_pos
                self.has_greeted = data.has_greeted
                self.unload_target = data.unload_target
            end
        end

        -- Забираємо команду з черги
        local uid = self.unit_data and self.unit_data.unit_id
        if uid and human_fortress.pending_commands and human_fortress.pending_commands[uid] then
            local pending = human_fortress.pending_commands[uid]
            self.unit_data.command = pending.command
            self.unit_data.target = pending.target
            human_fortress.pending_commands[uid] = nil
        end
    end,

    -- ========================================
    -- СМЕРТЬ
    -- ========================================
    on_die = function(self, pos)
        local drop_pos = pos or self.object:get_pos()
        if not drop_pos then return end

        drop_pos.y = drop_pos.y + 0.5
        minetest.add_item(drop_pos, "human_fortress:ether_tree 25")

        if self.inventory and (self.inventory.wood or 0) > 0 then
            minetest.add_item(drop_pos, "human_fortress:ether_tree " .. self.inventory.wood)
        end

        local owner = self.unit_data and self.unit_data.owner or ""
        if owner ~= "" then
            minetest.chat_send_player(owner, "💀 Твій Лісоруб загинув! Ресурси випали.")
        end

        local uid = self.unit_data and self.unit_data.unit_id
        if uid and owner ~= "" and human_fortress.players and human_fortress.players[owner] then
            local list = human_fortress.players[owner].selected_ids or {}
            for i = #list, 1, -1 do
                if list[i] == uid then table.remove(list, i) end
            end
        end
        if uid and human_fortress.pending_commands then
            human_fortress.pending_commands[uid] = nil
        end
    end,

    -- ========================================
    -- ЗАХИСТ ВІД ВЛАСНИКА
    -- ========================================
    on_punch = function(self, hitter)
        local name = hitter:get_player_name()
        if name == (self.unit_data and self.unit_data.owner or "") then
            return false
        end
    end,

    -- ========================================
    -- ОСНОВНИЙ ЦИКЛ
    -- ========================================
    do_custom = function(self, dtime)

        -- Привітання
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

        -- Захист
        if not self.unit_data then self.unit_data = {} end
        if not self.inventory then self.inventory = {wood = 0} end

        local owner = self.unit_data.owner or ""

        -- Допоміжна функція руху
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
                self:set_animation("walk")
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

        -- Слухач команд
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
                minetest.chat_send_player(owner, "🪓 Лісоруб отримав наказ: " .. (self.order or "очікування"))
            end
        end

        -- АВТО-РОЗВАНТАЖЕННЯ
        local total_res = self.inventory.wood or 0

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
                    p_res.wood = (p_res.wood or 0) + total_res
                    minetest.chat_send_player(owner, "💰 Лісоруб здав " .. total_res .. " ефіру у Ратушу!")
                end

                self.inventory = {wood = 0}
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

        -- ЗБІР ЕФІРНОГО ДЕРЕВА (ТІЛЬКИ ВІН!)
        if self.order == "gather" and self.goto_destination then
            local pos = self.object:get_pos()
            local dist = vector.distance(pos, self.goto_destination)

            if dist > 2.5 then
                self.last_gather_pos = self.goto_destination
                move_to(self, self.goto_destination)
                return
            else
                self.object:set_velocity({x=0, y=0, z=0})
                self:set_animation("punch")
                self.gather_timer = (self.gather_timer or 0) + dtime

                if self.gather_timer >= 1.5 then
                    local node = minetest.get_node(self.goto_destination)

                    if node.name == "human_fortress:ether_tree" then
                        local meta = minetest.get_meta(self.goto_destination)
                        local rem = meta:get_int("remaining")
                        if rem == 0 then rem = 20 end -- дефолт, якщо не задано

                        local harvest = 5

                        if rem <= harvest then
                            minetest.remove_node(self.goto_destination)
                            self.inventory.wood = (self.inventory.wood or 0) + rem
                            minetest.chat_send_player(owner, "🌳 Ефірне дерево зрубано! +"..rem.." (всього: " .. self.inventory.wood .. ")")
                        else
                            meta:set_int("remaining", rem - harvest)
                            self.inventory.wood = (self.inventory.wood or 0) + harvest
                            minetest.chat_send_player(owner, "🪓 Лісоруб рубає Ефір (+" .. harvest .. "). Залишилось: " .. (rem - harvest))
                        end

                        -- Шукаємо наступне ефірне дерево поблизу
                        local next_tree = minetest.find_node_near(self.goto_destination, 5, {"human_fortress:ether_tree"})
                        if next_tree then
                            self.goto_destination = next_tree
                            self.path_nodes = nil
                        else
                            minetest.chat_send_player(owner, "⚠️ Поруч більше немає Ефірних дерев!")
                            self.order = "stand"
                            self.goto_destination = nil
                        end
                    else
                        minetest.chat_send_player(owner, "❌ Тут більше немає Ефірного дерева!")
                        self.order = "stand"
                        self.goto_destination = nil
                    end
                    self.gather_timer = 0
                end
            end
            return
        end

        -- РУХ (MOVE)
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
    end,
})

-- ============================================
-- РЕЄСТРАЦІЯ В СПИСКУ
-- ============================================

if not human_fortress.units_list then human_fortress.units_list = {} end
human_fortress.units_list.lumberjack = {
    name = lumberjack_data.name,
    health = lumberjack_data.health,
    speed = lumberjack_data.speed,
    cost = lumberjack_data.cost,
    profession = "lumberjack",
    entity = "human_fortress:lumberjack",
}

-- ============================================
-- ФУНКЦІЯ СПАВНУ
-- ============================================

function human_fortress.spawn_lumberjack(pos, player_name)
    local ent = minetest.add_entity(pos, "human_fortress:lumberjack")
    if not ent then return nil end
    local luaent = ent:get_luaentity()
    if not luaent then ent:remove() return nil end

    luaent.unit_data = luaent.unit_data or {}
    luaent.unit_data.owner = player_name
    luaent.inventory = {wood = 0}

    return ent
end

print("[Human Fortress] Юніт 'lumberjack' зареєстровано (RTS-версія, тільки Ефір)")