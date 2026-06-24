-- ============================================
-- ЮНІТ: ЛІСОРУБ (Lumberjack - Тільки Ефір)
-- ============================================

local lumberjack_data = {
    name = "Лісоруб",
    health = 25,
    speed = 2,
    cost = {wood = 80, food = 40},
}

mobs:register_mob("human_fortress:lumberjack", {
    type = "npc",
    passive = true,
    pathfinding = 1,
    
    -- Характеристики
    hp_min = lumberjack_data.health,
    hp_max = lumberjack_data.health,
    armor = 100,
    
    -- Візуал
    collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.3, 0.3},
    visual = "mesh",
    mesh = "fooom.obj",
    textures = {{"fooom.png"}},
    visual_size = {x=8, y=8},
    
    -- Рух
    walk_velocity = 1,
    run_velocity = lumberjack_data.speed,
    jump = true,
    stepheight = 0.6,
    
    on_spawn = function(self)
        self.profession = "lumberjack"
        self.owner = self.owner or ""
        self.wood_count = 0
        return true
    end,

    do_custom = function(self, dtime)
        -- 1. Здача ресурсу
        if self.wood_count >= 100 then
            local pos = self.object:get_pos()
            local townhall = minetest.find_node_near(pos, 20, {"human_fortress:townhall"})
            
            if townhall then
                if vector.distance(pos, townhall) > 3 then
                    mobs:goto_destination(self, townhall)
                else
                    if human_fortress.edos_data and human_fortress.edos_data[self.owner] then
                        local data = human_fortress.edos_data[self.owner]
                        data.wood = (data.wood or 0) + self.wood_count
                        minetest.chat_send_player(self.owner, "💰 Лісоруб здав ефір")
                        self.wood_count = 0
                    end
                end
            end
            return
        end

        -- 2. Видобуток (Тільки human_fortress:ether_tree)
        if self.order == "gather" and self.goto_destination then
            local pos = self.object:get_pos()
            if vector.distance(pos, self.goto_destination) <= 2.5 then
                self.gather_timer = (self.gather_timer or 0) + dtime
                if self.gather_timer >= 1.5 then
                    local node = minetest.get_node(self.goto_destination)
                    
                    if node.name == "human_fortress:ether_tree" then
                        local meta = minetest.get_meta(self.goto_destination)
                        local rem = meta:get_int("remaining") or 20
                        local harvest = 5
                        
                        if rem <= harvest then
                            minetest.remove_node(self.goto_destination)
                            self.wood_count = self.wood_count + rem
                        else
                            meta:set_int("remaining", rem - harvest)
                            self.wood_count = self.wood_count + harvest
                        end
                        self.order = "stand"
                    else
                        -- Якщо не ефір — ігноруємо
                        self.order = "stand"
                    end
                    self.gather_timer = 0
                end
            end
        end
    end,
})

-- Реєстрація в список
if not human_fortress.units_list then human_fortress.units_list = {} end
human_fortress.units_list.lumberjack = {
    name = lumberjack_data.name,
    health = lumberjack_data.health,
    speed = lumberjack_data.speed,
    cost = lumberjack_data.cost,
    profession = "lumberjack",
    entity = "human_fortress:lumberjack",
}