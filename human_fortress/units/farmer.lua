-- ============================================
-- ЮНІТ: ФЕРМЕР (Farmer) — повністю узгоджений з Worker
-- ============================================

local farmer_data = {
    name = "Фермер",
    health = 20,
    speed = 2,
    cost = {wood = 60, food = 50},
}

-- ============================================
-- РУХ (взято з Worker)
-- ============================================
local function move_to(self, target)
    local pos = self.object:get_pos()
    if not pos or not target then return end

    local dist = vector.distance(pos, target)
    if dist < 1.5 then return end

    self:set_animation("stand")

    self.move_timer = (self.move_timer or 0) + 0.1
    if self.move_timer < 0.3 then return end
    self.move_timer = 0

    if not self.path_nodes or #self.path_nodes == 0 then
        self.path_fail_count = (self.path_fail_count or 0)

        local path = minetest.find_path(pos, target, 20, 1, 4, "A*_strict")
               or minetest.find_path(pos, target, 20, 2, 4, "A*")

        if path and #path > 1 then
            self.path_nodes = path
            self.path_fail_count = 0
            table.remove(self.path_nodes, 1)
        else
            self.path_fail_count = self.path_fail_count + 1
            if self.path_fail_count >= 3 then
                self.use_direct_move = true
                self.path_fail_count = 0
            else
                self:set_animation("stand")
                return
            end
        end
    end

    if self.use_direct_move then
        local dir = vector.direction(pos, target)
        self.object:set_velocity({
            x = dir.x * 2.5,
            y = self.object:get_velocity().y,
            z = dir.z * 2.5
        })
        self:set_animation("walk")
        local yaw = math.atan2(-dir.x, dir.z)
        self.object:set_yaw(yaw)

        if dist < 2.0 then
            self.use_direct_move = false
        end
        return
    end

    if self.path_nodes and #self.path_nodes > 0 then
        local next_step = self.path_nodes[1]

        if vector.distance(pos, next_step) < 1.0 then
            table.remove(self.path_nodes, 1)
            if #self.path_nodes == 0 then return end
            next_step = self.path_nodes[1]
        end

        local dir = vector.direction(pos, next_step)
        self.object:set_velocity({
            x = dir.x * 2.5,
            y = self.object:get_velocity().y,
            z = dir.z * 2.5
        })
        self:set_animation("walk")
        local yaw = math.atan2(-dir.x, dir.z)
        self.object:set_yaw(yaw)
    end
end

-- ============================================
-- РЕЄСТРАЦІЯ ЮНІТА
-- ============================================
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

    -- ============================================
    -- ЗБЕРЕЖЕННЯ ДАНИХ
    -- ============================================
on_spawn = function(self)
    self.unit_data = self.unit_data or {}
    self.inventory = {food = 0}

    -- ВАЖЛИВО: owner має бути тут!
    self.unit_data.owner = self.unit_data.owner or self.owner or ""

    self.order = "stand"
    self.goto_destination = nil
    self.path_nodes = nil
    self.path_fail_count = 0
    self.use_direct_move = false
    self.move_timer = 0
    self.gather_timer = 0

    return true
end,


    get_staticdata = function(self)
        return minetest.serialize({
            unit_data = self.unit_data,
            inventory = self.inventory,
            order = self.order,
            goto_destination = self.goto_destination,
        })
    end,

    on_activate = function(self, staticdata)
        if staticdata and staticdata ~= "" then
            local data = minetest.deserialize(staticdata)
            if data then
                self.unit_data = data.unit_data or {}
                self.inventory = data.inventory or {food = 0}
                self.order = data.order or "stand"
                self.goto_destination = data.goto_destination
            end
        end
    end,

    -- ============================================
    -- ОСНОВНА ЛОГІКА
    -- ============================================
    do_custom = function(self, dtime)
        if not self.object then return end
        local pos = self.object:get_pos()
        if not pos then return end

        -- Захист від nil
        if not self.unit_data then self.unit_data = {} end
        if not self.inventory then self.inventory = {food = 0} end

        local owner = self.unit_data.owner or ""

        -- 1. Слухач команд
        if self.unit_data.command then
            self.order = self.unit_data.command
            self.goto_destination = self.unit_data.target

            self.path_nodes = nil
            self.path_fail_count = 0
            self.use_direct_move = false
            self.move_timer = 0

            self.unit_data.command = nil

            if owner ~= "" then
                minetest.chat_send_player(owner, "🌾 Фермер отримав наказ: " .. self.order)
            end
        end

        -- 2. Рух (move)
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

        -- 3. Розвантаження (deposit)
        if self.order == "deposit" or self.inventory.food >= 100 then
            local townhall = minetest.find_node_near(pos, 40, {"human_fortress:townhall"})
            if townhall then
                if vector.distance(pos, townhall) > 3 then
                    move_to(self, townhall)
                else
                    if human_fortress.edos_data and human_fortress.edos_data[owner] then
                        human_fortress.edos_data[owner].food =
                            (human_fortress.edos_data[owner].food or 0) + self.inventory.food
                    end

                    minetest.chat_send_player(owner, "🌾 Фермер здав " .. self.inventory.food .. " їжі")

                    self.inventory.food = 0
                    self.order = "stand"
                    self.goto_destination = nil
                end
            end
            return
        end

        -- 4. Збір (gather)
        if self.order == "gather" and self.goto_destination then
            local dist = vector.distance(pos, self.goto_destination)

            if dist > 2.5 then
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
                        self.inventory.food = self.inventory.food + 50

                        minetest.chat_send_player(owner, "🌾 Фермер зібрав рис (+50)")
                    end

                    self.order = "stand"
                    self.goto_destination = nil
                    self.gather_timer = 0
                end
            end
            return
        end

        -- 5. Stand
        self:set_animation("stand")
    end,

    -- ============================================
    -- ПКМ МЕНЮ
    -- ============================================
    on_rightclick = function(self, clicker)
        local name = clicker:get_player_name()
        if name ~= self.unit_data.owner then
            minetest.chat_send_player(name, "❌ Це чужий фермер!")
            return
        end

        local formspec =
            "size[5,4]" ..
            "label[0.5,0.2;🌾 ФЕРМЕР]" ..
            "label[0.5,1;📦 Їжі: " .. (self.inventory.food or 0) .. "/100]" ..
            "button[0.5,2;2,0.8;gather;🌾 Збирати]" ..
            "button[2.5,2;2,0.8;deposit;🏛️ Здати]"

        minetest.show_formspec(name, "human_fortress:farmer_menu", formspec)
    end,
})

-- ============================================
-- МЕНЮ
-- ============================================
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "human_fortress:farmer_menu" then return end

    local name = player:get_player_name()

    for _, obj in ipairs(minetest.get_objects_inside_radius(player:get_pos(), 10)) do
        local ent = obj:get_luaentity()
        if ent and ent.name == "human_fortress:farmer" and ent.unit_data.owner == name then
            if fields.gather then
                ent.order = "gather"
                minetest.chat_send_player(name, "🌾 Фермер починає збір")
            elseif fields.deposit then
                ent.order = "deposit"
                minetest.chat_send_player(name, "🏛️ Фермер йде здавати ресурси")
            end
        end
    end
end)

-- ============================================
-- Додаємо в список юнітів
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
