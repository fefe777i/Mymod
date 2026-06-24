-- ============================================
-- ХІТБОКС ДЛЯ БУДІВЕЛЬ - ВИПРАВЛЕНО!
-- ============================================

minetest.register_entity("human_fortress:building_hitbox", {
    initial_properties = {
        physical = false,
        collide_with_objects = false,
        pointable = true,        -- МОЖНА ТИЦЯТИ, АЛЕ НЕ МОЖНА ВБИТИ
        visual = "wielditem",
        visual_size = {x = 0, y = 0},
        textures = {},
        collisionbox = {-1.5, -1.5, -1.5, 1.5, 1.5, 1.5},
        hp_max = 1,               -- МІНІМАЛЬНЕ ЗДОРОВ'Я
        immortal = true,          -- БЕЗСМЕРТНИЙ!
    },
    
    building_type = nil,
    owner = nil,
    building_pos = nil,
    size = {x=1, y=1, z=1},
    menu_function = nil,
    
    on_rightclick = function(self, clicker)
        if clicker and clicker:is_player() then
            local player_name = clicker:get_player_name()
            
            -- ПЕРЕВІРКА ВЛАСНИКА
            if self.owner and self.owner ~= player_name then
                minetest.chat_send_player(player_name, "❌ Це чужа будівля!")
                return
            end
            
            -- ВИКЛИКАЄМО ФУНКЦІЮ МЕНЮ
            if self.menu_function and _G[self.menu_function] then
                _G[self.menu_function](player_name, self.building_pos)
                return
            end
        end
    end,
    
    -- ЗАБОРОНЯЄМО ОТРИМАННЯ ШКОДИ
    on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
        -- НІЧОГО НЕ РОБИМО - ІГНОРУЄМО УДАРИ
        if puncher and puncher:is_player() then
            local player_name = puncher:get_player_name()
            -- ПРОСТО ПОВІДОМЛЕННЯ, ЩО ТИЦЯТИ ТРЕБА ПРАВОЮ КНОПКОЮ
            minetest.chat_send_player(player_name, "💡 Використовуй ПРАВУ кнопку миші щоб відкрити меню будівлі")
        end
        return false  -- НЕ НАНОСИМО ШКОДУ
    end,
    
    get_staticdata = function(self)
        return minetest.serialize({
            building_type = self.building_type,
            owner = self.owner,
            building_pos = self.building_pos,
            size = self.size,
            menu_function = self.menu_function,
        })
    end,
    
    on_activate = function(self, staticdata)
        if staticdata and staticdata ~= "" then
            local data = minetest.deserialize(staticdata)
            if data then
                self.building_type = data.building_type
                self.owner = data.owner
                self.building_pos = data.building_pos
                self.size = data.size
                self.menu_function = data.menu_function
                
                -- ВІДНОВЛЮЄМО ПОЗИЦІЮ
                if self.building_pos and self.size then
                    local pos = self.building_pos
                    local new_pos = vector.new(pos)
                    new_pos.x = new_pos.x + (self.size.x / 2) - 0.5
                    new_pos.y = new_pos.y + (self.size.y / 2) - 0.5
                    new_pos.z = new_pos.z + (self.size.z / 2) - 0.5
                    self.object:set_pos(new_pos)
                end
                
                -- ВСТАНОВЛЮЄМО БЕЗСМЕРТЯ ПРИ АКТИВАЦІЇ
                self.object:set_properties({immortal = true})
            end
        end
    end
})

print("[Human Fortress] Хітбокси завантажено (безсмертні)!")