-- ============================================
-- СИСТЕМА ШАКАЛІВ (jackals.lua) - ПРОСТИЙ СПАВН
-- ============================================

human_fortress.jackals = human_fortress.jackals or {
    player_waves = {},
}

local JACKAL_SETTINGS = {
    base_health = 30,
    base_damage = 8,
    base_speed = 2,
    min_level = 6,
}

-- ============================================
-- ФУНКЦІЯ РОЗРАХУНКУ КІЛЬКОСТІ ШАКАЛІВ
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
-- РЕЄСТРАЦІЯ СУТНОСТІ ШАКАЛА
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
        -- 1. Перевірка чи дані взагалі завантажились
        if not self.jackal_data then return end

        if self.jackal_data.health <= 0 then
            self.object:remove()
            return
        end
        
        local pos = self.object:get_pos()
        if not pos then return end
        
        -- 2. БЕЗПЕЧНА ПЕРЕВІРКА ГРАВЦЯ (виправляє помилку зі скріншота)
        local target = nil
        if self.jackal_data.owner and self.jackal_data.owner ~= "" then
            target = minetest.get_player_by_name(self.jackal_data.owner)
        end
        
        if target then
            local target_pos = target:get_pos()
            -- ... (далі твій код руху без змін)
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
                    -- Виправлено: звук грається тільки якщо власник онлайн
                    minetest.sound_play("default_punch", {to_player = self.jackal_data.owner, gain = 0.5})
                    
                    if target:get_hp() <= 0 then
                        self.object:remove()
                    end
                end
            end
        else
            -- Якщо гравця немає в мережі, шакал просто стоїть або видаляється через час
            self.object:set_velocity({x=0, y=0, z=0})
            -- Можна додати самознищення, якщо хочеш:
            -- self.object:remove()
        end
        
        -- Гравітація (завжди працює)
        local vel = self.object:get_velocity() or {x=0, y=0, z=0}
        vel.y = vel.y - 9.8 * dtime
        if vel.y < -10 then vel.y = -10 end
        self.object:set_velocity(vel)
    end,
    
    on_punch = function(self, puncher)
        self.jackal_data.health = self.jackal_data.health - 10
        if self.jackal_data.health <= 0 then
            self.object:remove()
            
            if self.jackal_data.owner and human_fortress.jackals.player_waves[self.jackal_data.owner] then
                local wave = human_fortress.jackals.player_waves[self.jackal_data.owner]
                for i, jackal in ipairs(wave.active) do
                    if jackal == self then
                        table.remove(wave.active, i)
                        break
                    end
                end
            end
        end
    end,
})

-- ============================================
-- ФУНКЦІЯ СПАВНУ ШАКАЛІВ (ЯК ТВАРИНИ)
-- ============================================

local function spawn_jackals(player)
    local pos = player:get_pos()
    local data = human_fortress.edos_data[player:get_player_name()]
    if not data then return end
    
    if data.level < JACKAL_SETTINGS.min_level then return end
    
    -- Видаляємо старих шакалів цього гравця
    local player_name = player:get_player_name()
    if human_fortress.jackals.player_waves[player_name] then
        for _, jackal in ipairs(human_fortress.jackals.player_waves[player_name].active) do
            if jackal and jackal.object then
                jackal.object:remove()
            end
        end
        human_fortress.jackals.player_waves[player_name].active = {}
    end
    
    -- Отримуємо кількість шакалів за рівнем
    local jackal_count = get_jackal_count_for_level(data.level)
    
    if jackal_count == 0 then return end
    
    -- Параметри спавну (як у тварин)
    local radius = 10
    local height = 2
    
    minetest.chat_send_player(player_name, "§E[Шакали]§F На тебе нападає " .. jackal_count .. " шакалів!")
    
    local spawned = 0
    
    for i = 1, jackal_count do
        local spawn_pos = {
            x = pos.x + math.random(-radius, radius),
            y = pos.y + math.random(0, height),
            z = pos.z + math.random(-radius, radius)
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
    
    print("[ШАКАЛИ] Створено " .. spawned .. " шакалів для " .. player_name)
end

-- ============================================
-- ФУНКЦІЯ ПЕРЕВІРКИ ЧАСУ
-- ============================================

local function is_time_to_spawn()
    local time = minetest.get_timeofday() * 24000
    -- 5:00 ранку = 5/24 від 24000 = 5000
    return time >= 4980 and time <= 5020  -- трохи ширше вікно
end

-- ============================================
-- ГЛОБАЛЬНИЙ STEP
-- ============================================

local timer = 0
minetest.register_globalstep(function(dtime)
    timer = timer + dtime
    if timer >= 1 then  -- перевірка щосекунди
        for _, player in ipairs(minetest.get_connected_players()) do
            if is_time_to_spawn() then
                spawn_jackals(player)
            end
        end
        timer = 0
    end
end)

-- ============================================
-- ПРИ ВИХОДІ ГРАВЦЯ
-- ============================================

minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    
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
-- ТЕСТОВІ КОМАНДИ
-- ============================================

minetest.register_chatcommand("test_jackals", {
    description = "Тестовий спавн шакалів",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then return end
        
        spawn_jackals(player)
    end
})

minetest.register_chatcommand("check_jackals", {
    description = "Перевірити кількість шакалів",
    func = function(name)
        local data = human_fortress.edos_data[name]
        if not data then return end
        
        local count = get_jackal_count_for_level(data.level)
        local time = minetest.get_timeofday() * 24000
        
        minetest.chat_send_player(name, "=== ШАКАЛИ ===")
        minetest.chat_send_player(name, "Рівень: " .. data.level)
        minetest.chat_send_player(name, "Шакалів: " .. count)
        minetest.chat_send_player(name, "Час: " .. math.floor(time) .. "/24000")
        
        if data.level < 6 then
            minetest.chat_send_player(name, "🛡️ Ще не нападають")
        end
        
        if is_time_to_spawn() then
            minetest.chat_send_player(name, "⚠️ ЗАРАЗ ЧАС НАПАДУ!")
        end
    end
})

minetest.register_chatcommand("remove_jackals", {
    description = "Видалити шакалів",
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

print("[Human Fortress] Шакали завантажено - ПРОСТИЙ СПАВН ЯК У ТВАРИН")