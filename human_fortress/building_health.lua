local HEALTH_DEFAULT = 100
local HEALTH_DAMAGE_INTERVAL = 4
local HEALTH_DAMAGE_AMOUNT = 3
local HEALTH_SEARCH_RADIUS = 40
local HEALTH_ATTACK_RADIUS = 10

local bars = {}

local function core_key(pos)
    return minetest.pos_to_string(pos)
end

local function get_health_data(core_pos)
    if not core_pos or not human_fortress.get_core_data then
        return nil
    end

    local data = human_fortress.get_core_data(core_pos)
    if not data or data.building_type == "" then
        return nil
    end

    local meta = minetest.get_meta(core_pos)
    local max_hp = meta:get_int("building_max_hp")
    local hp = meta:get_int("building_hp")

    if max_hp <= 0 then
        local schematic = BUILDING_SCHEMATICS and BUILDING_SCHEMATICS[data.building_type]
        max_hp = (schematic and (schematic.health or schematic.max_hp)) or HEALTH_DEFAULT
        meta:set_int("building_max_hp", max_hp)
    end

    if hp <= 0 or hp > max_hp then
        hp = max_hp
        meta:set_int("building_hp", hp)
    end

    return data, hp, max_hp
end

local function remove_bar(core_pos)
    local key = core_key(core_pos)
    local entry = bars[key]
    if not entry then return end

    if entry.bg and entry.bg:get_pos() then
        entry.bg:remove()
    end
    if entry.load and entry.load:get_pos() then
        entry.load:remove()
    end

    bars[key] = nil
end

local function update_bar(core_pos, hp, max_hp, top_pos)
    local key = core_key(core_pos)
    local entry = bars[key]

    if not entry or not entry.bg or not entry.bg:get_pos() or not entry.load or not entry.load:get_pos() then
        remove_bar(core_pos)

        local bg = minetest.add_entity(top_pos, "human_fortress:building_health_bg")
        local load = minetest.add_entity(top_pos, "human_fortress:building_health_load")
        if not bg or not load then
            if bg then bg:remove() end
            if load then load:remove() end
            return
        end

        entry = {bg = bg, load = load}
        bars[key] = entry
    end

    local ratio = math.max(0, math.min(1, hp / math.max(1, max_hp)))
    local width = 3
    local height = 0.35

    entry.bg:set_pos(top_pos)
    entry.bg:set_properties({
        visual_size = {x = width, y = height}
    })

    local left_x = top_pos.x - width / 2
    local load_width = width * ratio
    local load_pos = {
        x = left_x + load_width / 2,
        y = top_pos.y,
        z = top_pos.z
    }

    entry.load:set_pos(load_pos)
    entry.load:set_properties({
        visual_size = {x = math.max(0.001, load_width), y = height}
    })
end

minetest.register_entity("human_fortress:building_health_bg", {
    initial_properties = {
        visual = "sprite",
        textures = {"health_bd.png"},
        visual_size = {x = 3, y = 0.35},
        physical = false,
        pointable = false,
        static_save = false,
    },
})

minetest.register_entity("human_fortress:building_health_load", {
    initial_properties = {
        visual = "sprite",
        textures = {"health_load.png"},
        visual_size = {x = 3, y = 0.35},
        physical = false,
        pointable = false,
        static_save = false,
    },
})

function human_fortress.set_building_hp(core_pos, hp)
    local data, _, max_hp = get_health_data(core_pos)
    if not data then return false end

    hp = math.max(0, math.min(max_hp, hp))
    minetest.get_meta(core_pos):set_int("building_hp", hp)

    if hp <= 0 then
        human_fortress.destroy_building_by_core(core_pos)
    end

    return true
end

function human_fortress.damage_building(core_pos, damage)
    local data, hp = get_health_data(core_pos)
    if not data then return false end

    damage = tonumber(damage) or 0
    if damage <= 0 then return false end

    return human_fortress.set_building_hp(core_pos, hp - damage)
end

function human_fortress.destroy_building_by_core(core_pos)
    local data = human_fortress.get_core_data and human_fortress.get_core_data(core_pos)
    if not data or not data.min or not data.max then
        remove_bar(core_pos)
        return false
    end

    for x = data.min.x, data.max.x do
        for y = data.min.y, data.max.y do
            for z = data.min.z, data.max.z do
                minetest.remove_node({x = x, y = y, z = z})
            end
        end
    end

    remove_bar(core_pos)

    if human_fortress.buildings and data.owner and human_fortress.buildings[data.owner] then
        for i = #human_fortress.buildings[data.owner], 1, -1 do
            local b = human_fortress.buildings[data.owner][i]
            if b.type == data.building_type and b.pos and data.building_pos and vector.equals(b.pos, data.building_pos) then
                table.remove(human_fortress.buildings[data.owner], i)
            end
        end
    end

    return true
end

function human_fortress.find_building_core_for_jackal(pos)
    if not human_fortress.find_building_core then return nil end
    return human_fortress.find_building_core(pos, HEALTH_SEARCH_RADIUS)
end

local function add_gravity(entity, dtime)
    local vel = entity:get_velocity() or {x = 0, y = 0, z = 0}
    vel.y = vel.y - 9.8 * dtime
    if vel.y < -10 then vel.y = -10 end
    entity:set_velocity(vel)
end

local function attack_building(self, core_pos, dtime)
    self.building_attack_timer = (self.building_attack_timer or 0) + dtime
    if self.building_attack_timer >= HEALTH_DAMAGE_INTERVAL then
        if human_fortress.damage_building(core_pos, HEALTH_DAMAGE_AMOUNT) then
            self.building_attack_timer = 0
            minetest.sound_play("default_punch", {
                pos = self.object:get_pos(),
                gain = 0.5,
                max_hear_distance = 20
            })
        else
            self.building_attack_timer = 0
        end
    end
end

minetest.register_on_mods_loaded(function()
    local def = minetest.registered_entities["human_fortress:jackal"]
    if not def or def._building_health_wrapped then return end

    local old_on_step = def.on_step

    def.on_step = function(self, dtime)
        if not self.jackal_data then
            return old_on_step(self, dtime)
        end

        local pos = self.object:get_pos()
        if not pos then
            return old_on_step(self, dtime)
        end

        self.building_search_timer = (self.building_search_timer or 0) + dtime
        if self.building_search_timer >= 0.5 then
            self.building_search_timer = 0
            local core_pos = self.building_target

            if core_pos then
                local node_name = minetest.get_node(core_pos).name
                local data = human_fortress.get_core_data and human_fortress.get_core_data(core_pos)
                if not data or not node_name:find("^human_fortress:core_heart") then
                    core_pos = nil
                end
            end

            if not core_pos then
                core_pos = human_fortress.find_building_core_for_jackal(pos)
            end

            self.building_target = core_pos
        end

        local core_pos = self.building_target
        if not core_pos then
            return old_on_step(self, dtime)
        end

        local core_data = human_fortress.get_core_data and human_fortress.get_core_data(core_pos)
        if not core_data then
            self.building_target = nil
            return old_on_step(self, dtime)
        end

        local dist = vector.distance(pos, core_pos)
        if dist <= HEALTH_ATTACK_RADIUS then
            self.object:set_velocity({x = 0, y = 0, z = 0})
            attack_building(self, core_pos, dtime)
            add_gravity(self.object, dtime)
            return
        end

        local dir = vector.direction(pos, core_pos)
        dir.y = 0
        local len = math.sqrt(dir.x * dir.x + dir.z * dir.z)
        if len > 0.01 then
            dir.x = dir.x / len
            dir.z = dir.z / len

            self.object:set_yaw(math.atan2(dir.x, -dir.z))
            local vel = self.object:get_velocity() or {x = 0, y = 0, z = 0}
            vel.x = dir.x * self.jackal_data.speed
            vel.z = dir.z * self.jackal_data.speed
            self.object:set_velocity(vel)
        end

        add_gravity(self.object, dtime)
    end

    def._building_health_wrapped = true
end)

local scan_timer = 0
minetest.register_globalstep(function(dtime)
    scan_timer = scan_timer + dtime
    if scan_timer < 1 then return end
    scan_timer = 0

    local seen = {}

    for _, player in ipairs(minetest.get_connected_players()) do
        local pos = player:get_pos()
        local minp = {x = pos.x - 80, y = pos.y - 80, z = pos.z - 80}
        local maxp = {x = pos.x + 80, y = pos.y + 80, z = pos.z + 80}
        local nodes = minetest.find_nodes_in_area(minp, maxp, {"group:building_core"})

        for _, core_pos in ipairs(nodes) do
            local data, hp, max_hp = get_health_data(core_pos)
            if data and data.min and data.max then
                local top_y = data.max.y + 1.8
                local top_pos = {x = (data.min.x + data.max.x) / 2 + 0.5, y = top_y, z = (data.min.z + data.max.z) / 2 + 0.5}
                update_bar(core_pos, hp, max_hp, top_pos)
                seen[core_key(core_pos)] = true
            end
        end
    end

    for key, entry in pairs(bars) do
        local x, y, z = key:match("(-?[%d%.]+),(-?[%d%.]+),(-?[%d%.]+)")
        local pos
        if x and y and z then
            pos = {x = tonumber(x), y = tonumber(y), z = tonumber(z)}
        end

        if pos and not seen[key] then
            local node_name = minetest.get_node(pos).name
            if not node_name:find("^human_fortress:core_heart") then
                remove_bar(pos)
            end
        end
    end
end)
