-- ============================================
-- СИСТЕМА ШАКАЛІВ (jackals.lua)
-- СПАВН ЧЕРЕЗ НОДУ-СПАВНЕР, ЗА ОСОБИСТИМ ЧАСОМ ГРАВЦЯ
-- ============================================

human_fortress.jackals = human_fortress.jackals or {
    player_waves = {},
    spawners = {},
}

local JACKAL_SETTINGS = {
    base_health = 30,
    base_damage = 8,
    base_speed = 2,
    min_level = 6,
}

local SPAWNER_RADIUS = 15   -- радіус в нодах, у якому спавнер "бачить" гравця
local last_spawner_day = {} -- [player_name] = ігровий день, коли востаннє спрацював спавнер

-- ============================================
-- КІЛЬКІСТЬ ШАКАЛІВ ЗА РІВНЕМ
-- ============================================

local function get_jackal_count_for_level(level)
    local count = 0
    local ranges = {
        {min = 6,  max = 15, mult = 1},
        {min = 16, max = 25, mult = 2},
        {min = 26, max = 40, mult = 3},
        {min = 41, max = 60, mult = 4},
        {min = 61, max = 80, mult = 6},
        {min = 81, max = 100, mult = 10},
    }

    for _, range in ipairs(ranges) do
        if level >= range.min then
            local levels = math.min(level, range.max) - range.min + 1
            if levels > 0 then
                count = count + levels * range.mult
            end
        end
    end

    if level > 100 then
        count = count + (level - 100) * 12
    end

    return count
end

-- ============================================
-- СУТНІСТЬ ШАКАЛА
-- ============================================

minetest.register_entity("human_fortress:jackal", {
    initial_properties = {
        visual = "mesh",
        mesh = "jackal.obj",
        textures = {"jackal.png"},
        visual_size = {x=6, y=6},
        collisionbox = {-0.3, -0.5, -0.3, 0.3, 0.5, 0.3},
        physical = true,
        pointable = true,
        static_save = true,
        stepheight = 0.6,
        eye_height = 0.8,
    },

    jackal_data = {
        owner = nil,
        health = JACKAL_SETTINGS.base_health,
        damage = JACKAL_SETTINGS.base_damage,
        speed = JACKAL_SETTINGS.base_speed,
    },

    on_step = function(self, dtime)
        if not self.jackal_data then return end

        if self.jackal_data.health <= 0 then
            self.object:remove()
            return
        end

        local pos = self.object:get_pos()
        if not pos then return end

        local target = nil
        if self.jackal_data.owner and self.jackal_data.owner ~= "" then
            target = minetest.get_player_by_name(self.jackal_data.owner)
        end

        if target then
            local target_pos = target:get_pos()
            local dist = vector.distance(pos, target_pos)

            if dist > 2 then
                local dir = vector.direction(pos, target_pos)
                dir.y = 0
                local len = math.sqrt(dir.x*dir.x + dir.z*dir.z)
                if len > 0.01 then
                    dir.x = dir.x / len
                    dir.z = dir.z / len

                    local yaw = math.atan2(dir.x, -dir.z)
                    self.object:set_yaw(yaw)

                    local vel = self.object:get_velocity() or {x=0, y=0, z=0}
                    vel.x = dir.x * self.jackal_data.speed
                    vel.z = dir.z * self.jackal_data.speed
                    self.object:set_velocity(vel)
                end
            else
                self.object:set_velocity({x=0, y=0, z=0})

                self.attack_timer = (self.attack_timer or 0) + dtime
                if self.attack_timer >= 1 then
                    target:set_hp(target:get_hp() - self.jackal_data.damage)
                    self.attack_timer = 0
                    minetest.sound_play("default_punch", {to_player = self.jackal_data.owner, gain = 0.5})

                    if target:get_hp() <= 0 then
                        self.object:remove()
                    end
                end
            end
        else
            self.object:set_velocity({x=0, y=0, z=0})
        end

        local vel = self.object:get_velocity() or {x=0, y=0, z=0}
        vel.y = vel.y - 9.8 * dtime
        if vel.y < -10 then vel.y = -10 end
        self.object:set_velocity(vel)
    end,

    on_punch = function(self, puncher)
        self.jackal_data.health = self.jackal_data.health - 10
        if self.jackal_data.health <= 0 then
            self.object:remove()

            local owner = self.jackal_data.owner
            if owner and human_fortress.jackals.player_waves[owner] then
                local wave = human_fortress.jackals.player_waves[owner]

                for i = #wave.active, 1, -1 do
                    local j = wave.active[i]
                    if not j.object:get_pos() or j == self then
                        table.remove(wave.active, i)
                    end
                end

                if #wave.active == 0 then
                    minetest.chat_send_player(owner, "✅ Всі шакали знищені!")
                end
            end
        end
    end,
})
-- ============================================
-- НОДА-СПАВНЕР (працює через node timer, тільки коли прогружена)
-- ============================================

local SPAWNER_CHECK_RADIUS = 15  -- в якому радіусі шукати гравця біля спавнера
local SPAWN_RADIUS = 3           -- в якому радіусі навколо спавнера з'являються шакали
local last_spawner_day = {}      -- [player_name] = ігровий день останнього спрацювання

minetest.register_node("human_fortress:jackal_spawner", {
    description = "Кубло шакалів",
    tiles = {"default_grass.png", "default_dirt.png",
		{name = "default_dirt.png^default_grass_side.png",
			tileable_vertical = false}},
    groups = {cracky = 2, oddly_breakable_by_hand = 2},
    is_ground_content = false,

    on_construct = function(pos)
        local timer = minetest.get_node_timer(pos)
        timer:start(1) -- перевірка раз на секунду, поки блок прогружений
    end,

    on_timer = function(pos, elapsed)
        if not human_fortress.get_player_time then
            return true -- продовжуємо чекати, поки з'явиться функція часу
        end

        -- Шукаємо гравців поруч зі спавнером
        local objects = minetest.get_objects_inside_radius(pos, SPAWNER_CHECK_RADIUS)

        for _, obj in ipairs(objects) do
            if obj:is_player() then
                local player_name = obj:get_player_name()
                local hour, minute, day = human_fortress.get_player_time(player_name)

                if hour == 4 and minute == 40 and last_spawner_day[player_name] ~= day then
                    spawn_jackals_at_spawner(obj, pos)
                    last_spawner_day[player_name] = day
                end
            end
        end

        return true -- таймер триває, поки нода існує
    end,

    on_destruct = function(pos)
        -- нічого додатково видаляти не треба - таймер сам зупиниться
    end,
})

-- ============================================
-- СПАВН ШАКАЛІВ БІЛЯ КОНКРЕТНОГО СПАВНЕРА
-- ============================================

local function spawn_jackals_at_spawner(player, spawner_pos)
    local player_name = player:get_player_name()
    local data = human_fortress.edos_data[player_name]
    if not data then return end
    if data.level < JACKAL_SETTINGS.min_level then return end

    if human_fortress.jackals.player_waves[player_name] and
       #human_fortress.jackals.player_waves[player_name].active > 0 then
        return
    end

    if human_fortress.jackals.player_waves[player_name] then
        for _, jackal in ipairs(human_fortress.jackals.player_waves[player_name].active) do
            if jackal and jackal.object then
                jackal.object:remove()
            end
        end
        human_fortress.jackals.player_waves[player_name].active = {}
    end

    local jackal_count = get_jackal_count_for_level(data.level)
    if jackal_count == 0 then return end

    minetest.chat_send_player(player_name, "§E[Шакали]§F Кубло прокинулось о 4:40! На тебе нападає " .. jackal_count .. " шакалів!")

    local spawned = 0
    for i = 1, jackal_count do
        local spawn_pos = {
            x = spawner_pos.x + math.random(-SPAWN_RADIUS, SPAWN_RADIUS),
            y = spawner_pos.y + 1, -- саме "зверху себе"
            z = spawner_pos.z + math.random(-SPAWN_RADIUS, SPAWN_RADIUS)
        }

        local jackal = minetest.add_entity(spawn_pos, "human_fortress:jackal")
        if jackal then
            local luaentity = jackal:get_luaentity()
            if luaentity then
                luaentity.jackal_data.owner = player_name

                if not human_fortress.jackals.player_waves[player_name] then
                    human_fortress.jackals.player_waves[player_name] = {active = {}}
                end
                table.insert(human_fortress.jackals.player_waves[player_name].active, luaentity)
                spawned = spawned + 1
            end
        end
    end

    print("[ШАКАЛИ] Спавнер біля " .. minetest.pos_to_string(spawner_pos) .. " створив " .. spawned .. " шакалів для " .. player_name)
end

-- ============================================
-- ГЛОБАЛЬНИЙ STEP: перевірка ОСОБИСТОГО часу гравця
-- ============================================

local spawner_timer = 0
minetest.register_globalstep(function(dtime)
    spawner_timer = spawner_timer + dtime
    if spawner_timer < 1 then return end
    spawner_timer = 0

    local has_spawners = false
    for _ in pairs(human_fortress.jackals.spawners) do
        has_spawners = true
        break
    end
    if not has_spawners then return end

    if not human_fortress.get_player_time then return end

    for _, player in ipairs(minetest.get_connected_players()) do
        local player_name = player:get_player_name()
        -- ОСОБИСТИЙ час гравця, а не глобальний
        local hour, minute, day = human_fortress.get_player_time(player_name)

        if hour == 4 and minute == 40 and last_spawner_day[player_name] ~= day then
            local ppos = player:get_pos()

            for _, spawner_pos in pairs(human_fortress.jackals.spawners) do
                if vector.distance(ppos, spawner_pos) <= SPAWNER_RADIUS then
                    spawn_jackals_at_spawner(player, spawner_pos)
                    last_spawner_day[player_name] = day
                    break
                end
            end
        end
    end
end)

minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    last_spawner_day[name] = nil

    if human_fortress.jackals.player_waves[name] then
        for _, jackal in ipairs(human_fortress.jackals.player_waves[name].active) do
            if jackal and jackal.object then
                jackal.object:remove()
            end
        end
        human_fortress.jackals.player_waves[name].active = {}
    end
end)

-- ============================================
-- ТЕСТОВІ КОМАНДИ (теж особистий час)
-- ============================================

minetest.register_chatcommand("test_jackals", {
    description = "Тестовий спавн шакалів біля найближчого спавнера",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then return end

        local ppos = player:get_pos()
        local nearest, nearest_dist = nil, math.huge

        for _, spawner_pos in pairs(human_fortress.jackals.spawners) do
            local d = vector.distance(ppos, spawner_pos)
            if d < nearest_dist then
                nearest = spawner_pos
                nearest_dist = d
            end
        end

        if not nearest then
            minetest.chat_send_player(name, "❌ Немає жодного спавнера в світі!")
            return
        end

        spawn_jackals_at_spawner(player, nearest)
    end
})

minetest.register_chatcommand("check_jackals", {
    description = "Перевірити стан шакалів і особистий час",
    func = function(name)
        local data = human_fortress.edos_data[name]
        if not data then return end

        local count = get_jackal_count_for_level(data.level)
        local hour, minute, day = 0, 0, 0
        if human_fortress.get_player_time then
            hour, minute, day = human_fortress.get_player_time(name)
        end

        minetest.chat_send_player(name, "=== ШАКАЛИ ===")
        minetest.chat_send_player(name, "Рівень: " .. data.level)
        minetest.chat_send_player(name, "Шакалів у хвилі: " .. count)
        minetest.chat_send_player(name, "Твій особистий час: " .. string.format("%02d:%02d", hour, minute) .. " (день " .. day .. ")")

        if data.level < JACKAL_SETTINGS.min_level then
            minetest.chat_send_player(name, "🛡️ Ще не нападають (потрібен рівень " .. JACKAL_SETTINGS.min_level .. ")")
        end

        if hour == 4 and minute == 40 then
            minetest.chat_send_player(name, "⚠️ ЗАРАЗ ТВІЙ ЧАС НАПАДУ!")
        end
    end
})

minetest.register_chatcommand("remove_jackals", {
    description = "Видалити своїх шакалів",
    func = function(name)
        local count = 0

        if human_fortress.jackals.player_waves[name] then
            for _, jackal in ipairs(human_fortress.jackals.player_waves[name].active) do
                if jackal and jackal.object then
                    jackal.object:remove()
                    count = count + 1
                end
            end
            human_fortress.jackals.player_waves[name].active = {}
        end

        minetest.chat_send_player(name, "✅ Видалено " .. count .. " шакалів")
    end
})

print("[Human Fortress] Шакали завантажено - СПАВН ЧЕРЕЗ НОДУ, ЗА ОСОБИСТИМ ЧАСОМ ГРАВЦЯ")