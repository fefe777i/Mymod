-- ============================================
-- ЮНІТ: САМУРАЙ (Samurai)
-- ============================================

local samurai_data = {
    name = "Самурай",
    health = 60,
    damage = 20,
    speed = 2.8,
    cost = {wood = 80, stone = 80, food = 100},
}

mobs:register_mob("human_fortress:samurai", {
    type = "npc",
    passive = false,

    -- Характеристики
    hp_min = samurai_data.health,
    hp_max = samurai_data.health,
    damage = samurai_data.damage,
    reach = 2.5,
    armor = 100,

    -- Візуал
    collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.3, 0.3},
    visual = "mesh",
    mesh = "sam.obj",
    textures = {{"sam.png"}},
    visual_size = {x=2.5, y=2.5},

    -- Рух
    walk_velocity = 1.5,
    run_velocity = samurai_data.speed,
    jump = true,
    jump_height = 1.1,
    stepheight = 0.6,
    makes_footstep_sound = true,

    sounds = {
        attack = "default_punch",
        death = "default_tool_breaks",
    },

    -- Анімації
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
        return true
    end,

    -- ========================================
    -- ЗБЕРЕЖЕННЯ / ВІДНОВЛЕННЯ
    -- ========================================
    get_staticdata = function(self)
        local data = {
            unit_data = self.unit_data or {},
            order = self.order,
            goto_destination = self.goto_destination,
            enemy_object = self.enemy_object,
            has_greeted = self.has_greeted,
        }
        return minetest.serialize(data)
    end,

    on_activate = function(self, staticdata, dtime_s)
        if mobs.api and mobs.api.on_activate then
            mobs.api.on_activate(self, staticdata, dtime_s)
        end

        self.unit_data = {}
        self.order = nil
        self.goto_destination = nil
        self.enemy_object = nil
        self.has_greeted = false

        if staticdata and staticdata ~= "" then
            local data = minetest.deserialize(staticdata)
            if data and type(data) == "table" then
                self.unit_data = data.unit_data or {}
                self.order = data.order
                self.goto_destination = data.goto_destination
                self.enemy_object = data.enemy_object
                self.has_greeted = data.has_greeted
            end
        end

        -- Забираємо команду з черги, якщо самурай прокинувся
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
        minetest.add_item(drop_pos, "human_fortress:versiforn_source 60")
        minetest.add_item(drop_pos, "human_fortress:ether_tree 60")

        local owner = self.unit_data and self.unit_data.owner or ""
        if owner ~= "" then
            minetest.chat_send_player(owner, "💀 Твій Самурай загинув у бою!")
        end

        -- Прибираємо з вибору та черги
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
        if not self.unit_data then
            self.unit_data = {}
        end

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
            self.enemy_object = nil
            self.unit_data.command = nil
            if owner ~= "" then
                minetest.chat_send_player(owner, "🗡️ Самурай отримав наказ: " .. (self.order or "очікування"))
            end
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

        -- КОМАНДНА АТАКА (ATTACK TARGET)
        if self.order == "attack_target" and self.enemy_object then
            local target_obj = self.enemy_object
            if target_obj and target_obj:get_pos() then
                local t_pos = target_obj:get_pos()
                local dist = vector.distance(self.object:get_pos(), t_pos)
                if dist > 2.5 then
                    move_to(self, t_pos)
                else
                    self.object:set_velocity({x=0, y=0, z=0})
                    self:set_animation("punch")
                    target_obj:punch(self.object, 1.0, {
                        full_punch_interval = 1.0,
                        damage_groups = {fleshy = samurai_data.damage},
                    }, nil)
                    local t_ent = target_obj:get_luaentity()
                    if (not t_ent) or (t_ent.health and t_ent.health <= 0) then
                        self.order = "stand"
                        self.enemy_object = nil
                        self:set_animation("stand")
                    end
                end
            else
                self.order = "stand"
                self.enemy_object = nil
                self:set_animation("stand")
            end
            return
        end

        -- АВТО-АГРЕСІЯ (шукає ворогів поблизу, якщо немає наказу)
        self.attack_timer = (self.attack_timer or 0) + dtime
        if self.attack_timer >= 1.5 and self.order ~= "move" and self.order ~= "attack_target" then
            self.attack_timer = 0
            local my_pos = self.object:get_pos()
            for _, obj in ipairs(minetest.get_objects_inside_radius(my_pos, 12)) do
                local lua_ent = obj:get_luaentity()
                if lua_ent and lua_ent.unit_data and lua_ent.unit_data.owner ~= owner and lua_ent.health and lua_ent.health > 0 then
                    if obj ~= self.object then
                        self.order = "attack_target"
                        self.enemy_object = obj
                        break
                    end
                end
            end
        end
    end,
})

-- ============================================
-- РЕЄСТРАЦІЯ В СПИСКУ
-- ============================================

if not human_fortress.units_list then human_fortress.units_list = {} end
human_fortress.units_list.samurai = {
    name = samurai_data.name,
    health = samurai_data.health,
    speed = samurai_data.speed,
    damage = samurai_data.damage,
    cost = samurai_data.cost,
    profession = "samurai",
    entity = "human_fortress:samurai",
}

-- ============================================
-- ФУНКЦІЯ СПАВНУ
-- ============================================

function human_fortress.spawn_samurai(pos, player_name)
    local ent = minetest.add_entity(pos, "human_fortress:samurai")
    if not ent then return nil end
    local luaent = ent:get_luaentity()
    if not luaent then ent:remove() return nil end

    luaent.unit_data = luaent.unit_data or {}
    luaent.unit_data.owner = player_name

    return ent
end

print("[Human Fortress] Юніт 'samurai' зареєстровано (RTS-версія, стійка до вивантаження чанків)")