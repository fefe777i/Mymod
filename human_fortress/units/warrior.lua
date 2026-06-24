-- ============================================
-- ЮНІТ: ВОЇН (Warrior) через Mobs Redo
-- ============================================

local warrior_data = {
    name = "Воїн",
    health = 40,
    damage = 10,
    speed = 1.5,
    cost = {wood = 30, stone = 40, food = 50},
}

mobs:register_mob("human_fortress:warrior", {
    type = "npc",
    passive = false,
    attack_type = "dogfight",
    pathfinding = 1,
    
    -- Характеристики
    hp_min = warrior_data.health,
    hp_max = warrior_data.health,
    damage = warrior_data.damage,
    reach = 2,
    armor = 100,
    
    -- Візуал
    collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.3, 0.3},
    visual = "mesh",
    mesh = "foom.obj",
    textures = {
        {"foom.png"},
    },
    visual_size = {x=10, y=10}, -- Твій масштаб моделі
    
    -- Рух
    walk_velocity = 1,
    run_velocity = warrior_data.speed,
    jump = true,
    stepheight = 0.6,
    
    -- RTS Логіка
    on_spawn = function(self)
        self.profession = "warrior"
        self.owner = self.owner or ""
        return true
    end,

    -- Захист від ударів власника
    on_punch = function(self, hitter)
        local name = hitter:get_player_name()
        if name == self.owner then
            return false -- Власник не може наносити шкоду
        end
    end,
})

-- Реєстрація в загальному списку
if not human_fortress.units_list then human_fortress.units_list = {} end
human_fortress.units_list.warrior = {
    name = warrior_data.name,
    health = warrior_data.health,
    speed = warrior_data.speed,
    damage = warrior_data.damage,
    cost = warrior_data.cost,
    profession = "warrior",
    entity = "human_fortress:warrior",
}

print("[Human Fortress] Юніт 'warrior' зареєстровано через Mobs Redo")