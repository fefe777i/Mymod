-- ============================================
-- ЮНІТ: ЕЛІТНИЙ ВОЇН (Elite Warrior)
-- ============================================

mobs:register_mob("human_fortress:elite_warrior", {
    type = "npc",
    passive = false,
    attack_type = "dogfight",
    pathfinding = 1,
    
    -- Характеристики
    hp_min = 200,
    hp_max = 200,
    damage = 50,
    reach = 3,
    armor = 100,
    
    -- Візуал
    collisionbox = {-0.4, 0.0, -0.4, 0.4, 1.8, 0.4},
    visual = "mesh",
    mesh = "elite_warrior.obj",
    textures = {
        {"elite_warrior.png"},
    },
    visual_size = {x=3, y=3}, -- Якщо модель була x18, підкоригуй тут або в .obj
    
    -- Рух
    walk_velocity = 2,
    run_velocity = 4.2,
    jump = true,
    jump_height = 1.1,
    stepheight = 1.1,
    
    -- Звуки
    makes_footstep_sound = true,
    sounds = {
        death = "default_tool_breaks",
        attack = "default_punch",
    },

    -- RTS Логіка
    on_spawn = function(self)
        self.profession = "elite_warrior"
        self.owner = self.owner or ""
        return true
    end,

    -- Вимикаємо стандартний спавн у світі (щоб не з'являлися самі по собі)
    on_rightclick = function(self, clicker)
        local name = clicker:get_player_name()
        if name == self.owner then
        end
    end,
})

-- Додаємо в твій список для RTS системи
if not human_fortress.units_list then human_fortress.units_list = {} end
human_fortress.units_list.elite_warrior = {
    name = "Елітний воїн",
    health = 200,
    speed = 4.2,
    damage = 50,
    cost = {score = 1000, wood = 200, stone = 150},
    profession = "elite_warrior",
    entity = "human_fortress:elite_warrior",
}