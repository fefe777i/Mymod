-- ============================================
-- ЮНІТ: ФЕРМЕР (Farmer) через Mobs Redo
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
    pathfinding = 1,
    
    -- Характеристики
    hp_min = farmer_data.health,
    hp_max = farmer_data.health,
    armor = 100,
    
    -- Візуал
    collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.3, 0.3},
    visual = "mesh",
    mesh = "character.b3d",
    textures = {
        {"human_fortress_farmer_skin.png", "human_fortress_farmer_clothes.png"},
    },
    visual_size = {x=1, y=1},
    
    -- Рух
    walk_velocity = 1,
    run_velocity = farmer_data.speed,
    jump = true,
    stepheight = 0.6,
    
    -- RTS Логіка та інвентар
    on_spawn = function(self)
        self.profession = "farmer"
        self.owner = self.owner or ""
        self.food_count = 0 -- Поточна кількість їжі в руках
        return true
    end,

    -- Кастомна поведінка (замість старого on_step)
    do_custom = function(self, dtime)
        -- Якщо інвентар повний (наприклад, 100), шукаємо ратушу
        if self.food_count >= 100 then
            local pos = self.object:get_pos()
            local townhall = minetest.find_node_near(pos, 20, {"human_fortress:townhall"})
            
            if townhall then
                if vector.distance(pos, townhall) > 3 then
                    mobs:goto_destination(self, townhall)
                else
                    -- Здаємо ресурси
                    if human_fortress.edos_data and human_fortress.edos_data[self.owner] then
                        local data = human_fortress.edos_data[self.owner]
                        data.food = (data.food or 0) + self.food_count
                        minetest.chat_send_player(self.owner, "💰 Фермер здав " .. self.food_count .. " їжі")
                        self.food_count = 0
                    end
                end
            end
        end
    end,

    -- Логіка збору при натисканні (або можна автоматизувати)
    on_rightclick = function(self, clicker)
        local name = clicker:get_player_name()
        if name ~= self.owner then return end
        
        -- Тут можна відкрити меню або дати наказ "Збирати поруч"
    end,
})

-- Реєстрація в списку
if not human_fortress.units_list then human_fortress.units_list = {} end
human_fortress.units_list.farmer = {
    name = farmer_data.name,
    health = farmer_data.health,
    speed = farmer_data.speed,
    cost = farmer_data.cost,
    profession = "farmer",
    entity = "human_fortress:farmer",
}

print("[Human Fortress] Юніт 'farmer' зареєстровано через Mobs Redo")