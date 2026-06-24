-- ============================================
-- ЮНІТ: ШАХТАР (Miner) через Mobs Redo
-- ============================================

local miner_data = {
    name = "Шахтар",
    health = 30,
    speed = 1.8,
    cost = {wood = 100, stone = 50, food = 30},
}

mobs:register_mob("human_fortress:miner", {
    type = "npc",
    passive = true,
    pathfinding = 1,
    
    -- Характеристики
    hp_min = miner_data.health,
    hp_max = miner_data.health,
    armor = 100,
    
    -- Візуал
    collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.3, 0.3},
    visual = "mesh",
    mesh = "character.b3d",
    textures = {
        {"human_fortress_miner_skin.png", "human_fortress_miner_clothes.png"},
    },
    visual_size = {x=1, y=1},
    
    -- Рух
    walk_velocity = 1,
    run_velocity = miner_data.speed,
    jump = true,
    stepheight = 0.6,
    
    -- RTS Логіка
    on_spawn = function(self)
        self.profession = "miner"
        self.owner = self.owner or ""
        self.stone_count = 0
        return true
    end,

    do_custom = function(self, dtime)
        -- Якщо інвентар повний, йдемо до Ратуші
        if self.stone_count >= 100 then
            local pos = self.object:get_pos()
            local townhall = minetest.find_node_near(pos, 20, {"human_fortress:townhall"})
            
            if townhall then
                if vector.distance(pos, townhall) > 3 then
                    mobs:goto_destination(self, townhall)
                else
                    -- Здача ресурсів
                    if human_fortress.edos_data and human_fortress.edos_data[self.owner] then
                        local data = human_fortress.edos_data[self.owner]
                        data.stone = (data.stone or 0) + self.stone_count
                        minetest.chat_send_player(self.owner, "💰 Шахтар здав " .. self.stone_count .. " каменю")
                        self.stone_count = 0
                    end
                end
            end
            return
        end

        -- Логіка видобутку (якщо є наказ gather)
        if self.order == "gather" and self.goto_destination then
            local pos = self.object:get_pos()
            local dist = vector.distance(pos, self.goto_destination)

            if dist <= 2.5 then
                self.gather_timer = (self.gather_timer or 0) + dtime
                if self.gather_timer >= 2 then
                    local node = minetest.get_node(self.goto_destination)
                    
                    -- ПЕРЕВІРКА: Тільки Versiforn Source
                    if node.name == "human_fortress:versiforn_source" then
                        -- Замінюємо на камінь
                        minetest.set_node(self.goto_destination, {name = "default:stone"})
                        
                        self.stone_count = self.stone_count + 3
                        minetest.chat_send_player(self.owner, "⛏️ Шахтар видобув ресурс (+3)")
                        
                        -- Скидаємо наказ після видобутку одного блоку
                        self.order = "stand"
                    else
                        -- Якщо на місці вже не той блок
                        self.order = "stand"
                    end
                    self.gather_timer = 0
                end
            end
        end
    end,
})

-- Реєстрація в списку
if not human_fortress.units_list then human_fortress.units_list = {} end
human_fortress.units_list.miner = {
    name = miner_data.name,
    health = miner_data.health,
    speed = miner_data.speed,
    cost = miner_data.cost,
    profession = "miner",
    entity = "human_fortress:miner",
}

print("[Human Fortress] Юніт 'miner' зареєстровано (Видобуток Versiforn)")