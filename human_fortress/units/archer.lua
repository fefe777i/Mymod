-- ============================================
-- СТРІЛА ЛУЧНИКА
-- ============================================

minetest.register_entity("human_fortress:archer_arrow", {
    physical = false,
    visual = "sprite",
    visual_size = {x = 0.5, y = 0.5},
    textures = {"mobs_arrow.png"}, -- якщо немає — заміни на "default_stick.png"
    collisionbox = {-0.1, -0.1, -0.1, 0.1, 0.1, 0.1},
    pointable = false,
    timer = 0,

    on_activate = function(self)
        self.object:set_armor_groups({immortal = 1})
    end,

    on_step = function(self, dtime)
        self.timer = self.timer + dtime
        if self.timer > 3 then
            self.object:remove()
            return
        end

        local pos = self.object:get_pos()
        local node = minetest.get_node(pos)

        if node.name ~= "air" and minetest.registered_nodes[node.name].walkable then
            self.object:remove()
            return
        end

        for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 1.5)) do
            if obj ~= self.object then
                local ent = obj:get_luaentity()
                local is_enemy = false

                if ent and ent.unit_data and ent.unit_data.owner and self.owner then
                    if ent.unit_data.owner ~= self.owner then
                        is_enemy = true
                    end
                elseif obj:is_player() and self.owner then
                    local pname = obj:get_player_name()
                    if pname ~= self.owner then
                        is_enemy = true
                    end
                end

                if is_enemy then
                    if ent and ent.health then
                        ent.health = ent.health - (self.damage or 8)
                    end
                    obj:punch(self.object, 1.0, {
                        full_punch_interval = 1.0,
                        damage_groups = {fleshy = self.damage or 8},
                    }, nil)

                    -- Ефект попадання
                    local p = obj:get_pos()
                    minetest.add_particlespawner({
                        amount = 8,
                        time = 0.2,
                        minpos = {x=p.x-0.3, y=p.y+1, z=p.z-0.3},
                        maxpos = {x=p.x+0.3, y=p.y+1.5, z=p.z+0.3},
                        minvel = {x=-2, y=0, z=-2},
                        maxvel = {x=2, y=2, z=2},
                        minacc = {x=0, y=-5, z=0},
                        texture = "mobs_arrow.png",
                    })

                    self.object:remove()
                    return
                end
            end
        end
    end,
})

-- ============================================
-- ЮНІТ: ЛУЧНИК (Archer)
-- ============================================

local archer_data = {
    name = "Лучник",
    health = 25,
    damage = 8,
    range = 10,
    speed = 2,
    cost = {wood = 40, food = 40},
}

mobs:register_mob("human_fortress:archer", {
    type = "npc",
    passive = false,

    hp_min = archer_data.health,
    hp_max = archer_data.health,
    armor = 100,

    view_range = archer_data.range,
    reach = archer_data.range,

    collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.3, 0.3},
    visual = "mesh",
    mesh = "arkfom.gltf",
    textures = {{"arkfom.png"}},
    visual_size = {x = 1, y = 1},

    walk_velocity = 1,
    run_velocity = archer_data.speed,
    jump = true,
    stepheight = 0.6,

    animation = {
        speed_normal = 1,
        speed_run = 15,
        stand_start = 0,
        stand_end = 24,
        walk_start = 26,
        walk_end = 38,
        punch_start = 41,
        punch_end = 77,
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
        self.has_greeted = false
        self.shoot_timer = 0

        if staticdata and staticdata ~= "" then
            local data = minetest.deserialize(staticdata)
            if data and type(data) == "table" then
                self.unit_data = data.unit_data or {}
                self.order = data.order
                self.goto_destination = data.goto_destination
                self.has_greeted = data.has_greeted
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
        minetest.add_item(drop_pos, "human_fortress:ether_tree 20")
        minetest.add_item(drop_pos, "human_fortress:versiforn_source 10")

        local owner = self.unit_data and self.unit_data.owner or ""
        if owner ~= "" then
            minetest.chat_send_player(owner, "💀 Твій Лучник загинув у бою!")
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
        local owner = self.unit_data.owner or ""
        local pos = self.object:get_pos()
        if not pos then return end

        -- Допоміжна функція руху
        local move_to = function(entity, target)
            local p = entity.object:get_pos()
            if not p or not target then return end
            local dist = vector.distance(p, target)
            if dist < 1.5 then return end
            self:set_animation("walk")

            entity.move_timer = (entity.move_timer or 0) + 0.1
            if entity.move_timer < 0.3 then return end
            entity.move_timer = 0

            if not entity.path_nodes or #entity.path_nodes == 0 then
                entity.path_fail_count = (entity.path_fail_count or 0)
                local path = minetest.find_path(p, target, 20, 1, 4, "A*_strict")
                          or minetest.find_path(p, target, 20, 2, 4, "A*")
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
                local dir = vector.direction(p, target)
                entity.object:set_velocity({
                    x = dir.x * 2.5,
                    y = entity.object:get_velocity().y,
                    z = dir.z * 2.5
                })
                local yaw = math.atan2(-dir.x, dir.z)
                entity.object:set_yaw(yaw)
                if dist < 2.0 then
                    entity.use_direct_move = false
                end
                return
            end

            if entity.path_nodes and #entity.path_nodes > 0 then
                local next_step = entity.path_nodes[1]
                if vector.distance(p, next_step) < 1.0 then
                    table.remove(entity.path_nodes, 1)
                    if #entity.path_nodes == 0 then return end
                    next_step = entity.path_nodes[1]
                end
                local dir = vector.direction(p, next_step)
                entity.object:set_velocity({
                    x = dir.x * 2.5,
                    y = entity.object:get_velocity().y,
                    z = dir.z * 2.5
                })
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
            self.shoot_timer = 0
            self.unit_data.command = nil
            if owner ~= "" then
                minetest.chat_send_player(owner, "🏹 Лучник отримав наказ: " .. (self.order or "очікування"))
            end
        end

        -- РУХ (MOVE)
        if self.order == "move" and self.goto_destination then
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

        -- КОМАНДНА АТАКА / АВТО-АГРЕСІЯ З КАЙТИНГОМ
        local function engage_target(target_obj)
            if not target_obj or not target_obj:get_pos() then
                return false
            end
            local t_pos = target_obj:get_pos()
            local dist = vector.distance(pos, t_pos)

            -- Відступаємо, якщо ворог занадто близько (< 4 блоки)
            if dist < 4 then
                local away_dir = vector.direction(t_pos, pos)
                self.object:set_velocity({
                    x = away_dir.x * 3,
                    y = self.object:get_velocity().y,
                    z = away_dir.z * 3
                })
                self:set_animation("walk")
                local yaw = math.atan2(-away_dir.x, away_dir.z)
                self.object:set_yaw(yaw)
                return true
            end

            -- Підходимо, якщо занадто далеко (> 10 блоків)
            if dist > 10 then
                move_to(self, t_pos)
                return true
            end

            -- Оптимальна відстань — стріляємо
            self.object:set_velocity({x=0, y=0, z=0})
            local aim_yaw = math.atan2(pos.x - t_pos.x, pos.z - t_pos.z) -- дивимось на ціль
            self.object:set_yaw(aim_yaw)

            self.shoot_timer = (self.shoot_timer or 0) + dtime
            if self.shoot_timer >= 1.5 then
                self.shoot_timer = 0

                -- Анімація стрільби
                self.object:set_animation({x=41, y=77}, 15, 0)

                -- Звук
                minetest.sound_play("mobs_bow", {pos = pos, max_hear_distance = 20})

                -- Випускаємо стрілу
                local arrow_pos = {x = pos.x, y = pos.y + 1.5, z = pos.z}
                local target_head = {x = t_pos.x, y = t_pos.y + 1.5, z = t_pos.z}
                local dir = vector.direction(arrow_pos, target_head)

                local arrow = minetest.add_entity(arrow_pos, "human_fortress:archer_arrow")
                if arrow then
                    arrow:set_velocity({x = dir.x * 25, y = dir.y * 25, z = dir.z * 25})
                    arrow:set_acceleration({x = 0, y = -5, z = 0})
                    local luaent = arrow:get_luaentity()
                    if luaent then
                        luaent.owner = owner
                        luaent.damage = archer_data.damage
                    end
                end

                if owner ~= "" then
                    minetest.chat_send_player(owner, "🏹 Лучник стріляє!")
                end
            end
            return true
        end

        if self.order == "attack_target" and self.enemy_object then
            if not engage_target(self.enemy_object) then
                self.order = "stand"
                self.enemy_object = nil
            end
            return
        end

        -- АВТО-АГРЕСІЯ
        self.attack_timer = (self.attack_timer or 0) + dtime
        if self.attack_timer >= 2.0 and self.order ~= "move" and self.order ~= "attack_target" then
            self.attack_timer = 0
            for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 10)) do
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

        -- Базова анімація
        if not self.order or self.order == "stand" then
            local vel = vector.length(self.object:get_velocity())
            if vel > 0.1 then
                self:set_animation("walk")
            else
                self:set_animation("stand")
            end
        end
    end,
})

-- ============================================
-- РЕЄСТРАЦІЯ В СПИСКУ
-- ============================================

if not human_fortress.units_list then human_fortress.units_list = {} end
human_fortress.units_list.archer = {
    name = archer_data.name,
    health = archer_data.health,
    speed = archer_data.speed,
    damage = archer_data.damage,
    cost = archer_data.cost,
    profession = "archer",
    entity = "human_fortress:archer",
}

-- ============================================
-- ФУНКЦІЯ СПАВНУ
-- ============================================

function human_fortress.spawn_archer(pos, player_name)
    local ent = minetest.add_entity(pos, "human_fortress:archer")
    if not ent then return nil end
    local luaent = ent:get_luaentity()
    if not luaent then ent:remove() return nil end

    luaent.unit_data = luaent.unit_data or {}
    luaent.unit_data.owner = player_name

    return ent
end

print("[Human Fortress] Юніт 'archer' зареєстровано (RTS-версія з фізичними стрілами)")