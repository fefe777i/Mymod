-- ============================================
-- ЮНІТ: ЛУЧНИК (Archer) через Mobs Redo
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
    attack_type = "shoot", -- Змінюємо тип атаки на стрільбу!
    pathfinding = 1,
    
    -- Характеристики
    hp_min = archer_data.health,
    hp_max = archer_data.health,
    armor = 100,
    
    -- Дальня атака
    shoot_interval = 1.5,
    arrow = "mobs:arrow", -- Використовуємо стандартну стрілу з mobs_redo
    shoot_offset = 1,     -- Висота, з якої вилітає стріла
    
    -- Параметри стрільби
    view_range = archer_data.range,
    reach = archer_data.range,
    
    -- Візуал
    collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.3, 0.3},
    visual = "mesh",
    mesh = "arkfom.gltf",
    textures = {
        {"arkfom.png"},
    },
    visual_size = {x=1, y=1},
    
    animation = {
        speed_normal = 1,  
        stand_start = 0,    
        stand_end = 24,
        walk_start = 26,    
        walk_end = 38,
        shoot_start = 41,   
        shoot_end = 77,
       -- Встановлюємо швидкість 24 fps для збігу з розрахунками
    },
    
    -- Рух
    walk_velocity = 1,
    run_velocity = archer_data.speed,
    jump = true,
    stepheight = 0.6,
    
    -- Логіка RTS
    -- Замість on_step = function(self, dtime) ... end
do_custom = function(self, dtime)
    local vel = vector.length(self.object:get_velocity())

    if vel > 0.0 and self.animation_state ~= "walk" then
        self:set_animation("walk")
        self.animation_state = "walk"
    elseif vel <= 0.1 and self.animation_state ~= "stand" then
        self:set_animation("stand")
        self.animation_state = "stand"
    end
end,

    on_spawn = function(self)
        self.profession = "archer"
        self.owner = self.owner or ""
        return true
    end,

    -- Захист від дружнього вогню
    on_punch = function(self, hitter)
        local name = hitter:get_player_name()
        if name == self.owner then
            return false
        end
    end,
    
    -- Ефект стрільби
    custom_attack = function(self, target)
        if self.owner and self.owner ~= "" then
            minetest.chat_send_player(self.owner, "🏹 Лучник веде вогонь!")
        end
    end,
})

-- Реєстрація в списку RTS
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

print("[Human Fortress] Юніт 'archer' зареєстровано через Mobs Redo")