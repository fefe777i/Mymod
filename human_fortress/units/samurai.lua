-- ============================================
-- ЮНІТ: САМУРАЙ (Samurai) через Mobs Redo
-- ============================================

local samurai_data = {
    name = "Самурай",
    health = 60,
    damage = 20,
    speed = 2.8,
    cost = {wood = 80, stone = 80, food = 100},
}

mobs:register_mob("human_fortress:samurai", {
    -- Технічні налаштування
    type = "npc",
    passive = false,
    attack_type = "dogfight",
    pathfinding = 1,
    
    -- Характеристики (брані з твого списку)
    hp_min = samurai_data.health,
    hp_max = samurai_data.health,
    damage = samurai_data.damage,
    reach = 2.5, -- Радіус атаки (як у твоєму коді)
    armor = 100,
    
    -- Візуал
    collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.3, 0.3},
    visual = "mesh",
    mesh = "sam.obj",
    textures = {
        {"sam.png"},
    },
    visual_size = {x=2.5, y=2.5}, -- Mobs Redo масштабує автоматично, якщо треба — підправ
    
    -- Рух
    walk_velocity = 1.5,
    run_velocity = samurai_data.speed,
    jump = true,
    jump_height = 1.1,
    stepheight = 0.6,
    
    -- Звуки та ефекти
    makes_footstep_sound = true,
    sounds = {
        attack = "default_punch",
        death = "default_tool_breaks",
    },

    -- RTS Логіка
    on_spawn = function(self)
        self.profession = "samurai"
        self.owner = self.owner or ""
        return true
    end,

    -- Обробка удару (власник не може бити свого)
    on_punch = function(self, hitter)
        local name = hitter:get_player_name()
        if name == self.owner then
            return false
        end
    end,
    
    -- Кастомна логіка атаки (повідомлення в чат, як було у тебе)
    custom_attack = function(self, target)
        if self.owner and self.owner ~= "" then
            local target_name = target:get_player_name()
            if target_name and target_name ~= "" then
                minetest.chat_send_player(self.owner, "⚔️ Самурай атакує " .. target_name)
            end
        end
    end,
})

-- РЕЄСТРАЦІЯ В СПИСОК RTS
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

print("[Human Fortress] Юніт 'samurai' зареєстровано через Mobs Redo")