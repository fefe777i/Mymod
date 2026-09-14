-- ============================================
-- ЮНІТ: ФЕРМЕР (Farmer)
-- ============================================

local farmer_data = {
    name = "Фермер",
    health = 20,
    speed = 2,
    cost = {wood = 60, food = 50},
}

mobs:register_mob("human_fortress:farmer", {
    type = "npc",
    passive = true,

    hp_min = farmer_data.health,
    hp_max = farmer_data.health,

    collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.3, 0.3},
    visual = "mesh",
    mesh = "ffom.gltf",
    textures = {"ffom.png"},
    visual_size = {x = 1, y = 1},

    walk_velocity = 1,
    run_velocity = farmer_data.speed,

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
        self.inventory = {food = 0}
        self.order = "stand"
        self.goto_destination = nil
        self.path_nodes = nil
        self.path_fail_count = 0
        self.use_direct_move = false
        self.move_timer = 0
        self.gather_timer = 0
        self.has_greeted = false
        self.last_gather_pos = nil
        self.unload_target = nil
        return true
    end,

    -- ========================================
    -- ЗБЕРЕЖЕННЯ / ВІДНОВЛЕННЯ
    -- ========================================
    get_staticdata = function(self)
        local data = {
            unit_data = self.unit_data or {},
            inventory = self.inventory or {food = 0},
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
        self.inventory = {food = 0}
        self.order = "stand"
        self.goto_destination = nil
        self.path_nodes = nil
        self.path_fail_count = 0
        self.use_direct_move = false
        self.move_timer = 0
        self.gather_timer = 0
        self.has_greeted = false
        self.last_gather_pos = nil
        self.unload_target = nil

        if staticdata and staticdata ~= "" then
            local data = minetest.deserialize(staticdata)
            if data and type(data) == "table" then
                self.unit_data = data.unit_data or {}
                self.inventory = data.inventory or {food = 0}
                self.order = data.order or "stand"
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
        minetest.add_item(drop_pos, "farm:wheat 20")

        if self.inventory and (self.inventory.food or 0) > 0 then
            minetest.add_item(drop_pos, "farm:wheat " .. self.inventory.food)
        end

        local owner = self.unit_data and self.unit_data.owner or ""
        if owner ~= "" then
            minetest.chat_send_player(owner, "💀 Твій Фермер загинув! Ресурси випали.")
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
        if not self.inventory then self.inventory = {food = 0} end

        local pos = self.object:get_pos()
        if not pos then return end

        local owner = self.unit_data.owner or ""

        -- Допоміжна функція руху
        local move_to = function(entity, target)
            local p = entity.object:get_pos()
            if not p or not target then return end

            local dist = vector.distance(p, target)
            if dist < 1.5 then return end
            self:set_animation("stand")

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
                self:set_animation("walk")
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
                minetest.chat_send_player(owner, "🌾 Фермер отримав наказ: " .. (self.order or "очікування"))
            end
        end

        -- РУХ (move)
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

        -- АВТО-РОЗВАНТАЖЕННЯ
        local total_food = self.inventory.food or 0

        if total_food >= 100 or self.order == "deposit" or self.order == "unload" then
            if not self.unload_target then
                local townhall = minetest.find_node_near(pos, 40, {"human_fortress:townhall"})
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
                    human_fortress.edos_data[owner].food = (human_fortress.edos_data[owner].food or 0) + total_food
                end

                minetest.chat_send_player(owner, "🌾 Фермер здав " .. total_food .. " їжі у Ратушу!")

                self.inventory.food = 0
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

        -- ЗБІР (gather)
        if self.order == "gather" and self.goto_destination then
            local dist = vector.distance(pos, self.goto_destination)

            if dist > 2.5 then
                self.last_gather_pos = self.goto_destination
                move_to(self, self.goto_destination)
                return
            else
                self.object:set_velocity({x=0, y=0, z=0})
                self:set_animation("punch")
                self.gather_timer = (self.gather_timer or 0) + dtime

                if self.gather_timer >= 2 then
                    local node = minetest.get_node(self.goto_destination)

                    if node.name == "human_fortress:rice" then
                        minetest.remove_node(self.goto_destination)
                        self.inventory.food = (self.inventory.food or 0) + 50
                        minetest.chat_send_player(owner, "🌾 Фермер зібрав рис (+50)")

                        -- Шукаємо наступний рис поблизу
                        local next_rice = minetest.find_node_near(self.goto_destination, 5, {"human_fortress:rice"})
                        if next_rice then
                            self.goto_destination = next_rice
                            self.path_nodes = nil
                        else
                            minetest.chat_send_player(owner, "⚠️ Поруч більше немає рису!")
                            self.order = "stand"
                            self.goto_destination = nil
                        end
                    else
                        minetest.chat_send_player(owner, "❌ Тут більше немає рису!")
                        self.order = "stand"
                        self.goto_destination = nil
                    end
                    self.gather_timer = 0
                end
            end
            return
        end

        -- Stand
        self:set_animation("stand")
    end,

    -- ========================================
    -- ПКМ МЕНЮ
    -- ========================================
    on_rightclick = function(self, clicker)
        local name = clicker:get_player_name()
        if name ~= (self.unit_data and self.unit_data.owner or "") then
            minetest.chat_send_player(name, "❌ Це чужий фермер!")
            return
        end

        local formspec =
            "size[5,4]" ..
            "label[0.5,0.2;🌾 ФЕРМЕР]" ..
            "label[0.5,1;📦 Їжі: " .. (self.inventory.food or 0) .. "/100]" ..
            "button[0.5,2;2,0.8;gather;🌾 Збирати]" ..
            "button[2.5,2;2,0.8;deposit;🏛️ Здати]"

        minetest.show_formspec(name, "human_fortress:farmer_menu_" .. (self.unit_data.unit_id or "unknown"), formspec)
    end,
})

-- ============================================
-- МЕНЮ
-- ============================================
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if not formname:find("^human_fortress:farmer_menu_") then return end

    local name = player:get_player_name()
    local target_uid = formname:match("^human_fortress:farmer_menu_(.+)$")

    for _, obj in ipairs(minetest.get_objects_inside_radius(player:get_pos(), 10)) do
        local ent = obj:get_luaentity()
        if ent and ent.name == "human_fortress:farmer" and ent.unit_data and ent.unit_data.owner == name then
            if not target_uid or target_uid == "unknown" or (ent.unit_data.unit_id == target_uid) then
                if fields.gather then
                    ent.order = "gather"
                    minetest.chat_send_player(name, "🌾 Фермер починає збір")
                elseif fields.deposit then
                    ent.order = "deposit"
                    minetest.chat_send_player(name, "🏛️ Фермер йде здавати ресурси")
                end
                break -- ВИПРАВЛЕННЯ: тільки одного фермера!
            end
        end
    end
end)

-- ============================================
-- РЕЄСТРАЦІЯ В СПИСКУ
-- ============================================
if not human_fortress.units_list then human_fortress.units_list = {} end
human_fortress.units_list.farmer = {
    name = farmer_data.name,
    health = farmer_data.health,
    speed = farmer_data.speed,
    cost = farmer_data.cost,
    profession = "farmer",
    entity = "human_fortress:farmer",
}

-- ============================================
-- ФУНКЦІЯ СПАВНУ
-- ============================================
function human_fortress.spawn_farmer(pos, player_name)
    local ent = minetest.add_entity(pos, "human_fortress:farmer")
    if not ent then return nil end
    local luaent = ent:get_luaentity()
    if not luaent then ent:remove() return nil end

    luaent.unit_data = luaent.unit_data or {}
    luaent.unit_data.owner = player_name
    luaent.inventory = {food = 0}

    return ent
end

print("[Human Fortress] Юніт 'farmer' зареєстровано (RTS-версія, стійка до вивантаження чанків)")