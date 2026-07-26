-- ============================================
-- ДЕРЕВО ПРОКАЧКИ - З JSON ЗБЕРЕЖЕННЯМ!
-- ============================================

local world_path = minetest.get_worldpath()
local upgrades_file = world_path .. "/upgrades.json"

-- Функція завантаження апгрейдів з JSON
local function load_upgrades_from_json()
    local file = io.open(upgrades_file, "r")
    if not file then
        -- Створюємо пустий файл
        local default = {}
        file = io.open(upgrades_file, "w")
        file:write(minetest.write_json(default, true))
        file:close()
        return {}
    end
    
    local content = file:read("*all")
    file:close()
    return minetest.parse_json(content) or {}
end

-- Функція збереження апгрейдів в JSON
local function save_upgrades_to_json(data)
    local file = io.open(upgrades_file, "w")
    file:write(minetest.write_json(data, true))
    file:close()
end

-- Глобальна таблиця апгрейдів (завантажується з JSON)
local player_upgrades = load_upgrades_from_json()

-- ДЕРЕВО ПРОКАЧКИ (Human Fortress x Мастерская 47)
local UPGRADE_TREE = {
    -- =========================================================================
    -- ЦЕНТРАЛЬНА ГІЛКА (БАЗА ТА МЕНЕДЖМЕНТ)
    -- =========================================================================
    {
        id = "townhall",
        name = "🏛️ Ратуша",
        description = "Центр вашої фортеці. Головний вузол керування.",
        cost = {score = 10, wood = 50, stone = 30},
        required = nil,
        icon = "human_fortress_townhall.png",
        position = {x = 0, y = 2},
        effects = {unlock_locations = {"plains"}, max_units = 5, resource_regen = 1}
    },
    {
    id = "stina",
    name = "Стіна",
    description = "стіна захищає всіх",
    cost = {score = 50, wood = 5000, stone = 3000},
    required = "townhall",
    icon = "stina.png",
    position = {x = 1, y = 2},
    },
    {
        id = "reflexion",
        name = "🧠 Рефлексія",
        description = "Усвідомлення своїх дій. Відкриває шлях до вищих технологій.",
        cost = {score = 150, wood = 40},
        required = "townhall",
        icon = "human_fortress_reflexion.png",
        position = {x = -2, y = 3},
        effects = {research_speed = 1.1}
    },
    {
        id = "intuition",
        name = "👁️ Інтуїція",
        description = "Почуття прихованих можливостей та небезпек.",
        cost = {score = 200, stone = 20},
        required = "reflexion",
        icon = "human_fortress_intuition.png",
        position = {x = -3, y = 4},
        effects = {crit_chance = 5}
    },
    {
        id = "evolution_leap",
        name = "⚡ Стрибок у розвитку",
        description = "З шансом 10% знижує необхідний рівень для наступних досліджень.",
        cost = {score = 300, stone = 15}, -- У серіалі: рівень 5, 15 ейдосів
        required = "reflexion",
        icon = "human_fortress_evolution_leap.png",
        position = {x = -4, y = 3},
        effects = {research_discount = 0.10}
    },
    {
        id = "bank",
        name = "🏦 Банк",
        description = "Будівля для надійного зберігання та приросту цінних ресурсів.",
        cost = {score = 400, stone = 150, wood = 100},
        required = "evolution_leap",
        icon = "human_fortress_bank.png",
        position = {x = -4, y = 5},
        effects = {gold_income = 2}
    },
    {
        id = "small_but_mighty",
        name = "💪 Мал да удал",
        description = "Малі юніти отримують бонус до швидкості та захисту.",
        cost = {score = 250, food = 50},
        required = "evolution_leap",
        icon = "human_fortress_small_mighty.png",
        position = {x = -6, y = 3},
        effects = {small_unit_speed = 1.15}
    },

    -- =========================================================================
    -- ГІЛКА ВИРОБНИЦТВА ТА СКЛАДІВ (ПРАВОРУЧ ВГОРУ ВІД РАТУШІ)
    -- =========================================================================
    {
        id = "rice_field",
        name = "🌾 Рисове поле",
        description = "Базове виробництво їжі для твоїх роботяг.",
        cost = {score = 120, wood = 40, food = 20},
        required = "townhall",
        icon = "human_fortress_rice_field.png",
        position = {x = 2, y = 3},
        effects = {food_production = 3}
    },
    {
        id = "warehouse",
        name = "📦 Склад",
        description = "Головне сховище для ресурсів вашого поселення.",
        cost = {score = 150, wood = 80, stone = 50},
        required = "rice_field",
        icon = "human_fortress_warehouse.png",
        position = {x = 2, y = 4},
        effects = {storage_capacity = 500}
    },
    {
        id = "warehouse_branch",
        name = "🏪 Філія складу",
        description = "Автоматично доставляє всі видобуті ресурси на головний склад.",
        cost = {score = 450, stone = 50}, -- У серіалі: рівень 8, 50 ейдосів, 12 сили
        required = "warehouse",
        icon = "human_fortress_warehouse_branch.png",
        position = {x = 1, y = 5},
        effects = {auto_delivery = true, transport_speed = 1.2}
    },
    {
        id = "watchtower",
        name = "🗼 Вишка",
        description = "Збільшує радіус огляду навколо промислової зони.",
        cost = {score = 180, wood = 100, stone = 30},
        required = "warehouse",
        icon = "human_fortress_watchtower.png",
        position = {x = 3, y = 4},
        effects = {view_distance = 15}
    },

    -- =========================================================================
    -- ВІЙСЬКОВА ГІЛКА (КАЗАРМИ ТА ЮНІТИ)
    -- =========================================================================
    
    {
        id = "barracks",
        name = "⚔️ Казарми",
        description = "Головна споруда для найму та підготовки бійців.",
        cost = {score = 150, wood = 120, stone = 80},
        required = "townhall",
        icon = "human_fortress_barracks.png",
        position = {x = 0, y = -1},
        effects = {unlock_buildings = {"barracks"}}
    },
    {
        id = "recruit",
        name = "🛡️ Рекрут",
        description = "Базовий бойовий юніт. Основа вашої майбутньої армії.",
        cost = {score = 150, food = 40},
        required = "barracks",
        icon = "human_fortress_recruit.png",
        position = {x = 0, y = -2},
        effects = {unlock_units = {"recruit"}}
    },
    {
        id = "spearman",
        name = "🔱 Спісник",
        description = "Спеціалізація рекрута. Ефективний проти кавалерії та великих ворогів.",
        cost = {score = 350, wood = 60},
        required = "recruit",
        icon = "human_fortress_spearman.png",
        position = {x = -2, y = -2},
        effects = {unlock_units = {"spearman"}, bonus_vs_large = 1.35}
    },
    {
        id = "berserk",
        name = "😡 Берсерк",
        description = "Спеціалізація рекрута. Шалена атака в ближньому бою ціною захисту.",
        cost = {score = 700, food = 80},
        required = "recruit",
        icon = "human_fortress_berserk.png",
        position = {x = 0, y = -4},
        effects = {unlock_units = {"berserk"}, damage_bonus = 1.5, defense_penalty = 0.8}
    },
    {
        id = "archer",
        name = "🏹 Лучник",
        description = "Бійці дальнього бою. Засипають ворога стрілами здалеку.",
        cost = {score = 200, wood = 80, food = 30},
        required = "recruit",
        icon = "human_fortress_archer.png",
        position = {x = 2, y = -2},
        effects = {unlock_units = {"archer"}}
    },
    {
        id = "calculation",
        name = "📊 Розрахунковість",
        description = "Військовий розрахунок підвищує точність та зменшує витрати на армію.",
        cost = {score = 280, food = 50},
        required = "archer",
        icon = "human_fortress_calculation.png",
        position = {x = 4, y = -2},
        effects = {unit_upkeep_discount = 0.15}
    },
    {
        id = "epilit_canyon",
        name = "🪨 Каньйон епілітів",
        description = "Військова зона розвідки. Дозволяє знаходити бойові трофеї.",
        cost = {score = 350, stone = 100},
        required = "calculation",
        icon = "human_fortress_epilit_canyon.png",
        position = {x = 4, y = -4},
        effects = {unlock_locations = {"epilit_canyon"}}
    },

    -- =========================================================================
    -- ГІЛКА РОБОЧИХ ТА ТЕРИТОРІЙ (ВЛІВО ВНІЗ)
    -- =========================================================================
    {
        id = "hardworker",
        name = "⛏️ Роботяга",
        description = "Збільшує базову швидкість збору ресурсів звичайними робітниками.",
        cost = {score = 120, food = 30},
        required = "townhall",
        icon = "human_fortress_hardworker.png",
        position = {x = -3, y = 0},
        effects = {gather_speed = 1.15}
    },
    {
        id = "farmer",
        name = "👨‍🌾 Спеціалізація: Фермер",
        description = "Робітники можуть перевчатися на фермерів. Ефективні на полях.",
        cost = {score = 200, wood = 30},
        required = "hardworker",
        icon = "human_fortress_farmer.png",
        position = {x = -5, y = 0},
        effects = {farmer_efficiency = 1.3}
    },
    {
        id = "fisherman",
        name = "🎣 Спеціалізація: Рибак",
        description = "Дозволяє виловлювати рибу на водних вузлах.",
        cost = {score = 180, wood = 40},
        required = "hardworker",
        icon = "human_fortress_fisherman.png",
        position = {x = -3, y = -1},
        effects = {unlock_fishing = true}
    },
    {
        id = "carpenter",
        name = "🪓 Спеціалізація: Тесля",
        description = "Переучує робітника на теслю. Швидкий крафт дерев'яних предметів.",
        cost = {score = 270, wood = 20}, -- У серіалі: рівень 7, 20 ейдосів, 7/7 атрибути
        required = "hardworker",
        icon = "human_fortress_carpenter.png",
        position = {x = -3, y = 1},
        effects = {wood_craft_speed = 1.4}
    },
    {
        id = "pier",
        name = "⚓ Пірс",
        description = "Будівля на воді для розширення логістики та рибальства.",
        cost = {score = 300, wood = 150},
        required = "carpenter",
        icon = "human_fortress_pier.png",
        position = {x = -3, y = 2},
        effects = {unlock_buildings = {"pier"}, fish_income = 2}
    },
    {
        id = "healthy_glacier",
        name = "🏔️ Здоровий лідник",
        description = "Відкриває доступ до ейдосних гейзерів та ефірних свердловин у регіоні.",
        cost = {score = 490, stone = 100}, -- У серіалі: рівень 9, 100 ейдосів, 13 сили
        required = "farmer",
        icon = "human_fortress_glacier.png",
        position = {x = -7, y = 0},
        effects = {unlock_resource_nodes = {"eidos_geyser", "ether_well"}}
    },
    {
        id = "twilight_graveyard",
        name = "🪦 Сутінковий могильник",
        description = "Територія, багата на містичні та підземні ресурси.",
        cost = {score = 550, stone = 150},
        required = "healthy_glacier",
        icon = "human_fortress_graveyard.png",
        position = {x = -8, y = 1},
        effects = {unlock_locations = {"twilight_graveyard"}}
    },
    {
        id = "monumental_valley",
        name = "🗿 Монументальна долина",
        description = "Локація з гігантськими покладами міцного каменю.",
        cost = {score = 650, stone = 300},
        required = "twilight_graveyard",
        icon = "human_fortress_monumental_valley.png",
        position = {x = -8, y = 2},
        effects = {unlock_locations = {"monumental_valley"}}
    },
    {
        id = "palace_garden",
        name = "🌳 Палацовий сад",
        description = "Елітна зона з рідкісними породами дерев та рослин.",
        cost = {score = 750, wood = 400},
        required = "monumental_valley",
        icon = "human_fortress_palace_garden.png",
        position = {x = -8, y = 3},
        effects = {unlock_locations = {"palace_garden"}}
    },
    {
        id = "floating_rocks",
        name = "☁️ Скелі, що ширяють",
        description = "Фінальна високогірна зона з найціннішими матеріалами.",
        cost = {score = 900, stone = 500, wood = 500},
        required = "palace_garden",
        icon = "human_fortress_floating_rocks.png",
        position = {x = -8, y = 4},
        effects = {unlock_locations = {"floating_rocks"}}
    },

    -- =========================================================================
    -- ЕКОНОМІЧНО-РЕЛІГІЙНА ГІЛКА (ПРАВОРУЧ ВНИЗ)
    -- =========================================================================
    {
        id = "head_on_shoulders",
        name = "👤 Голова на плечах",
        description = "Початкове познання соціуму. Покращує базовий інтелект поселенців.",
        cost = {score = 150, food = 30},
        required = "townhall",
        icon = "human_fortress_head_shoulders.png",
        position = {x = 3, y = 1},
        effects = {xp_gain_units = 1.1}
    },
    {
        id = "generous_soul",
        name = "💎 Щедра душа",
        description = "Шанс отримати випадковий подарунок або бонус від союзних фракцій +20%.",
        cost = {score = 2430, gold = 500}, -- У серіалі: рівень 33, 2100 ейдосів
        required = "head_on_shoulders",
        icon = "human_fortress_generous_soul.png",
        position = {x = 5, y = 1},
        effects = {tribute_chance = 0.20}
    },
    {
        id = "lizard_nest",
        name = "🦎 Гніздо ящерів",
        description = "Дослідження дикої зони проживання ящерів для торгівлі чи полювання.",
        cost = {score = 400, food = 100},
        required = "head_on_shoulders",
        icon = "human_fortress_lizard_nest.png",
        position = {x = 5, y = 2},
        effects = {unlock_locations = {"lizard_nest"}}
    },
    {
        id = "balanced_choice",
        name = "⚖️ Зважений вибір",
        description = "Початковий економічний вибір. Зменшує ймовірність помилок у крафті.",
        cost = {score = 130, wood = 30},
        required = "townhall",
        icon = "human_fortress_balanced_choice.png",
        position = {x = 3, y = -1},
        effects = {craft_fail_chance = 0}
    },
    {
        id = "profit_seeker",
        name = "💰 Шукач вигоди",
        description = "Робітники знаходять трохи більше золота або цінностей при видобутку.",
        cost = {score = 200, food = 40},
        required = "balanced_choice",
        icon = "human_fortress_profit_seeker.png",
        position = {x = 5, y = -1},
        effects = {gold_multiplier = 1.15}
    },
    {
        id = "willpower_decision",
        name = "✊ Вольове рішення",
        description = "Миттєво підвищує мораль та працездатність армії у критичний момент.",
        cost = {score = 250, food = 60},
        required = "profit_seeker",
        icon = "human_fortress_willpower.png",
        position = {x = 7, y = -1},
        effects = {army_morale = 20}
    },
    {
        id = "diplomacy",
        name = "🤝 Дипломатія",
        description = "Дає 20% шанс на успішний мирний результат або знижку при соціальних діях.",
        cost = {score = 590, food = 100}, -- У серіалі: рівень 9, 50 ейдосів
        required = "willpower_decision",
        icon = "human_fortress_diplomacy.png",
        position = {x = 7, y = 0},
        effects = {trade_discount = 0.20}
    },
    {
        id = "temple",
        name = "🛕 Храм",
        description = "Релігійна споруда для генерації віри та найму духовних юнітів.",
        cost = {score = 500, stone = 200, wood = 100},
        required = "diplomacy",
        icon = "human_fortress_temple.png",
        position = {x = 7, y = 1},
        effects = {unlock_buildings = {"temple"}, faith_regen = 1}
    },
    {
        id = "monk",
        name = "🧘 Монах",
        description = "Релігійний юніт підтримки. Здатний лікувати твоїх бійців на полі бою.",
        cost = {score = 400, food = 150},
        required = "temple",
        icon = "human_fortress_monk.png",
        position = {x = 7, y = 2},
        effects = {unlock_units = {"monk"}}
    },
    {
        id = "caster_spec",
        name = "🔮 Спеціалізація: Заклинатель",
        description = "Дозволяє монахам вивчати руйнівні або захисні бойові заклинання.",
        cost = {score = 600, stone = 80},
        required = "monk",
        icon = "human_fortress_caster.png",
        position = {x = 7, y = 3},
        effects = {magic_damage = 1.25}
    },
    {
        id = "apostate_spec",
        name = "🖤 Спеціалізація: Відступник",
        description = "Перетворює ченців на магів темряви з великою шкодою по площі.",
        cost = {score = 650, stone = 100},
        required = "monk",
        icon = "human_fortress_apostate.png",
        position = {x = 9, y = 2},
        effects = {aoe_damage = 1.3}
    },
    {
        id = "market",
        name = "⚖️ Ринок",
        description = "Дозволяє обмінювати ресурси між собою та торгувати з іншими фракціями.",
        cost = {score = 350, wood = 150, stone = 50},
        required = "diplomacy",
        icon = "human_fortress_market.png",
        position = {x = 9, y = 0},
        effects = {unlock_buildings = {"market"}, trade_routes = 1}
    },
    {
        id = "merchant_spec",
        name = "💼 Спеціалізація: Торговець",
        description = "Призначає робітника торговцем. Збільшує прибуток від торгових караванів.",
        cost = {score = 400, food = 80},
        required = "market",
        icon = "human_fortress_merchant.png",
        position = {x = 9, y = -1},
        effects = {caravan_income = 1.3}
    },

    -- =========================================================================
    -- ДОДАТКОВІ НАУКОВІ ТА МАГІЧНІ ВУЗЛИ
    -- =========================================================================
    {
        id = "scientist",
        name = "🧪 Вчений",
        description = "Будівля або познання для проведення складних алхімічних тестів.",
        cost = {score = 300, stone = 50},
        required = "townhall",
        icon = "human_fortress_scientist.png",
        position = {x = -1, y = 4},
        effects = {alchemy_speed = 1.25}
    },
    {
        id = "safety_tech",
        name = "⚠️ Техніка безпеки",
        description = "Зменшує шкоду робітникам від аварій або вибухів на виробництві.",
        cost = {score = 200, wood = 40},
        required = "scientist",
        icon = "human_fortress_safety_tech.png",
        position = {x = -1, y = 5},
        effects = {worker_accident_defense = 0.50}
    },
    {
        id = "ether_collector",
        name = "🔮 Спеціалізація: Ефірозбірщик",
        description = "Дозволяє робітникам ефективно видобувати чистий ефір зі свердловин.",
        cost = {score = 400, stone = 60},
        required = "healthy_glacier",
        icon = "human_fortress_ether_collector.png",
        position = {x = -5, y = 2},
        effects = {ether_gather_speed = 1.3}
    }
}
-- Отримання даних гравця (з JSON)
local function get_player_upgrades(player_name)
    if not player_upgrades[player_name] then
        player_upgrades[player_name] = {}
    end
    return player_upgrades[player_name]
end

-- Перевірка чи розблоковано апгрейд
local function is_upgrade_unlocked(player_name, upgrade_id)
    local upgrades = get_player_upgrades(player_name)
    return upgrades[upgrade_id] or false
end

-- Отримання ресурсів гравця
local function get_player_resources(player_name)
    local data = human_fortress.edos_data[player_name]
    if not data then return {score=0, wood=0, stone=0, food=0} end
    return {
        score = data.score or 0,
        wood = data.wood or 0,
        stone = data.stone or 0,
        food = data.food or 0
    }
end

-- Зняття ресурсів
local function remove_resources(player_name, cost)
    local data = human_fortress.edos_data[player_name]
    if not data then return false end
    
    for res, amount in pairs(cost) do
        if (data[res] or 0) < amount then
            return false
        end
    end
    
    for res, amount in pairs(cost) do
        data[res] = (data[res] or 0) - amount
    end
    
    return true
end

-- Перевірка чи можна розблокувати
local function can_unlock_upgrade(player_name, upgrade)
    local upgrades = get_player_upgrades(player_name)
    
    if upgrades[upgrade.id] then
        return false, "already"
    end
    
    if upgrade.required then
        if not upgrades[upgrade.required] then
            return false, "required"
        end
    end
    
    local resources = get_player_resources(player_name)
    for resource, amount in pairs(upgrade.cost) do
        if (resources[resource] or 0) < amount then
            return false, "resources"
        end
    end
    
    return true, "ok"
end

-- Розблокування апгрейда
local function unlock_upgrade(player_name, upgrade_id)
    local player = minetest.get_player_by_name(player_name)
    if not player then return false end
    
    local upgrade = nil
    for _, u in ipairs(UPGRADE_TREE) do
        if u.id == upgrade_id then
            upgrade = u
            break
        end
    end
    
    if not upgrade then 
        minetest.chat_send_player(player_name, "❌ Покращення не знайдено!")
        return false 
    end
    
    local can_unlock, reason = can_unlock_upgrade(player_name, upgrade)
    if not can_unlock then
        if reason == "resources" then
            minetest.chat_send_player(player_name, "❌ Недостатньо ресурсів!")
        elseif reason == "required" then
            minetest.chat_send_player(player_name, "❌ Потрібно розблокувати попереднє покращення!")
        elseif reason == "already" then
            minetest.chat_send_player(player_name, "❌ Вже розблоковано!")
        end
        return false
    end
    
    -- Знімаємо ресурси
    if not remove_resources(player_name, upgrade.cost) then
        minetest.chat_send_player(player_name, "❌ Помилка при знятті ресурсів!")
        return false
    end
    
    -- ЗАПИСУЄМО В JSON!
    if not player_upgrades[player_name] then
        player_upgrades[player_name] = {}
    end
    player_upgrades[player_name][upgrade_id] = true
    
    -- ЗБЕРІГАЄМО JSON
    save_upgrades_to_json(player_upgrades)
    
    minetest.chat_send_player(player_name, "✅ Розблоковано: " .. upgrade.name)
    minetest.chat_send_player(player_name, "💾 Збережено в JSON!")
    
    return true
end

-- КОМАНДА ДЛЯ ПЕРЕВІРКИ JSON
minetest.register_chatcommand("check_json", {
    func = function(name)
        minetest.chat_send_player(name, "=== ПЕРЕВІРКА JSON ===")
        
        local upgrades = get_player_upgrades(name)
        minetest.chat_send_player(name, "📊 Твої апгрейди:")
        for k,v in pairs(upgrades) do
            minetest.chat_send_player(name, "   " .. k .. " = " .. tostring(v))
        end
        
        -- Показуємо шлях до файлу
        minetest.chat_send_player(name, "📁 Файл: " .. upgrades_file)
    end
})

-- ПОКАЗ МЕНЮ ПРОКАЧКИ (СКОРОЧЕНО)
function show_upgrades_menu(player_name, scroll_x, scroll_y)
    local data = get_player_data(player_name)
    local player = minetest.get_player_by_name(player_name)
    if not player then return end
    
    -- Отримуємо ресурси з вашої системи
    local resources = get_player_resources(player_name)
    local score = resources.score or 0
    
    -- Скрол
    scroll_x = scroll_x or data.upgrade_scroll_x or 0
    scroll_y = scroll_y or data.upgrade_scroll_y or 0
    
    -- Обмежуємо скрол
    scroll_x = math.max(-300, math.min(300, scroll_x))
    scroll_y = math.max(-200, math.min(200, scroll_y))
    
    -- Зберігаємо позицію скролу
    data.upgrade_scroll_x = scroll_x
    data.upgrade_scroll_y = scroll_y
    save_fortress_data()
    
    local formspec = "size[14,9]" ..
        "bgcolor[#0A0A1A;true]" ..
        
        -- Верхня панель з ресурсами
        "box[0,0;14,0.8;#2D2D44]" ..
        "label[0.5,0.2;🏛️ ДЕРЕВО ПРОКАЧКИ ФОРТЕЦІ]" ..
        "item_image[9.5,0.2;0.4,0.4;human_fortress:edos]" ..
        "label[10,0.2;× " .. score .. "]" ..
        "button[12.2,0.2;1.5,0.5;back;🔙 Назад]" ..
        
        -- Контейнер з скролом
        "container[0.5,1]" ..
        "box[0,0;13,7.2;#1E1E2E]"
    
    -- КНОПКИ СКРОЛУ
    formspec = formspec ..
        "button[0,3.2;0.8,0.8;scroll_left;◀]" ..
        "button[12.2,3.2;0.8,0.8;scroll_right;▶]" ..
        "button[6,0;0.8,0.8;scroll_up;▲]" ..
        "button[6,6.4;0.8,0.8;scroll_down;▼]" ..
        "label[5.8,7.8;X: " .. string.format("%.1f", scroll_x) .. " Y: " .. string.format("%.1f", scroll_y) .. "]"
    
    -- Знаходимо мінімальні та максимальні координати
    local min_x, max_x, min_y, max_y = 0, 0, 0, 0
    for _, upgrade in ipairs(UPGRADE_TREE) do
        min_x = math.min(min_x, upgrade.position.x)
        max_x = math.max(max_x, upgrade.position.x)
        min_y = math.min(min_y, upgrade.position.y)
        max_y = math.max(max_y, upgrade.position.y)
    end
    
    -- Розмір поля
    local field_width = 11
    local field_height = 6
    local scale = 1.6
    
    -- Центруємо дерево з урахуванням скролу
    local offset_x = (field_width / 2) - ((min_x + max_x) * scale / 2) - scroll_x * 2
    local offset_y = (field_height / 2) - ((min_y + max_y) * scale / 2) - scroll_y * 2
    
    -- Малюємо зв'язки
    for _, upgrade in ipairs(UPGRADE_TREE) do
        if upgrade.required then
            local parent = nil
            for _, u in ipairs(UPGRADE_TREE) do
                if u.id == upgrade.required then
                    parent = u
                    break
                end
            end
            
            if parent then
                local x1 = offset_x + parent.position.x * scale
                local y1 = offset_y + parent.position.y * scale
                local x2 = offset_x + upgrade.position.x * scale
                local y2 = offset_y + upgrade.position.y * scale
                
                if (x1 > -1 or x2 > -1) and (x1 < 14 or x2 < 14) and 
                   (y1 > -1 or y2 > -1) and (y1 < 8 or y2 < 8) then
                    
                    local parent_unlocked = is_upgrade_unlocked(player_name, parent.id)
                    local upgrade_unlocked = is_upgrade_unlocked(player_name, upgrade.id)
                    local line_color = "#808080"
                    
                    if parent_unlocked and upgrade_unlocked then
                        line_color = "#FFD700"
                    elseif parent_unlocked and not upgrade_unlocked then
                        if can_unlock_upgrade(player_name, upgrade) then
                            line_color = "#00FF00"
                        else
                            line_color = "#C0C0C0"
                        end
                    end
                    
                    local steps = 15
                    for i = 0, steps do
                        local t = i / steps
                        local x = x1 + (x2 - x1) * t
                        local y = y1 + (y2 - y1) * t
                        if x > 0 and x < 13 and y > 0 and y < 7 then
                            formspec = formspec .. "box[" .. x .. "," .. y .. ";0.05,0.05;" .. line_color .. "]"
                        end
                    end
                end
            end
        end
    end
    
    -- Малюємо апгрейди
    for _, upgrade in ipairs(UPGRADE_TREE) do
        local x = offset_x + upgrade.position.x * scale
        local y = offset_y + upgrade.position.y * scale
        
        if x > 0 and x < 13 and y > 0 and y < 7 then
            local unlocked = is_upgrade_unlocked(player_name, upgrade.id)
            local can_unlock, reason = can_unlock_upgrade(player_name, upgrade)
            
            local border_color = "#808080"
            if unlocked then
                border_color = "#FFD700"
            elseif can_unlock then
                border_color = "#00FF00"
            end
            
            local card_w = 1.6
            local card_h = 1.6
            
            formspec = formspec ..
                "box[" .. x-0.8 .. "," .. y-0.8 .. ";" .. card_w .. "," .. card_h .. ";" .. border_color .. "33]" ..
                "box[" .. x-0.75 .. "," .. y-0.75 .. ";" .. card_w-0.1 .. "," .. card_h-0.1 .. ";" .. 
                (unlocked and "#2A2A4A" or "#1A1A2A") .. "]" ..
                "image[" .. x-0.5 .. "," .. y-0.5 .. ";1,1;" .. (upgrade.icon or "unknown_item.png") .. "]" ..
                "label[" .. x-0.7 .. "," .. y+0.3 .. ";" .. upgrade.name .. "]"
            
            if not unlocked and can_unlock then
                formspec = formspec ..
                    "button[" .. x-0.7 .. "," .. y+0.5 .. ";1.4,0.25;unlock_" .. upgrade.id .. ";📌 Розблокувати]"
            end
            
            -- Показуємо ціну в EDOS
            if not unlocked and upgrade.cost.score then
                formspec = formspec ..
                    "item_image[" .. x-0.7 .. "," .. y-0.3 .. ";0.2,0.2;human_fortress:edos]" ..
                    "label[" .. (x-0.45) .. "," .. (y-0.35) .. ";" .. upgrade.cost.score .. "]"
            end
            
            if unlocked then
                formspec = formspec .. "label[" .. x-0.6 .. "," .. y-0.2 .. ";✅]"
            end
            
            formspec = formspec .. "tooltip[unlock_" .. upgrade.id .. ";" .. upgrade.description .. "]"
        end
    end
    
    formspec = formspec .. "container_end[]"
    
    minetest.show_formspec(player_name, "human_fortress:upgrades", formspec)
end

-- Обробник для меню прокачки
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "human_fortress:upgrades" then return end
    
    local player_name = player:get_player_name()
    local data = get_player_data(player_name)
    
    if fields.back then
        if show_vilka_menu then
            show_vilka_menu(player_name)
        end
        return
    end
    
    -- КНОПКИ СКРОЛУ
    local scroll_x = data.upgrade_scroll_x or 0
    local scroll_y = data.upgrade_scroll_y or 0
    local moved = false
    
    if fields.scroll_left then
        scroll_x = scroll_x - 0.5
        moved = true
    elseif fields.scroll_right then
        scroll_x = scroll_x + 0.5
        moved = true
    elseif fields.scroll_up then
        scroll_y = scroll_y - 0.5
        moved = true
    elseif fields.scroll_down then
        scroll_y = scroll_y + 0.5
        moved = true
    end
    
    if moved then
        show_upgrades_menu(player_name, scroll_x, scroll_y)
        return
    end
    
    -- Обробка розблокування
    for field, _ in pairs(fields) do
        if string.sub(field, 1, 7) == "unlock_" then
            local upgrade_id = string.sub(field, 8)
            unlock_upgrade(player_name, upgrade_id)
            show_upgrades_menu(player_name, data.upgrade_scroll_x, data.upgrade_scroll_y)
            return
        end
    end
end)

-- Ініціалізація
minetest.register_on_joinplayer(function(player)
    local player_name = player:get_player_name()
    local data = get_player_data(player_name)
    
    if not data.upgrades then
        data.upgrades = {}
    end
    
    -- Розблоковуємо Ратушу автоматично
    if not data.upgrades.townhall then
        data.upgrades.townhall = true
        minetest.chat_send_player(player_name, "🏛️ Ратушу розблоковано автоматично!")
    end
    
    if data.upgrade_scroll_x == nil then
        data.upgrade_scroll_x = 0
    end
    if data.upgrade_scroll_y == nil then
        data.upgrade_scroll_y = 0
    end
    
    save_fortress_data()
end)
-- Додайте цю функцію для перевірки чи гравець стоїть біля своєї вилки
local function is_near_own_vilka(player)
    if not player then return false end
    
    local pos = player:get_pos()
    if not pos then return false end
    
    -- Перевіряємо блоки навколо гравця (радіус 2)
    local check_positions = {
        {x = pos.x, y = pos.y, z = pos.z},
        {x = pos.x + 1, y = pos.y, z = pos.z},
        {x = pos.x - 1, y = pos.y, z = pos.z},
        {x = pos.x, y = pos.y + 1, z = pos.z},
        {x = pos.x, y = pos.y - 1, z = pos.z},
        {x = pos.x, y = pos.y, z = pos.z + 1},
        {x = pos.x, y = pos.y, z = pos.z - 1},
    }
    
    for _, check_pos in ipairs(check_positions) do
        local node = minetest.get_node(check_pos)
        if node.name == "human_fortress:vilka_active" then
            local meta = minetest.get_meta(check_pos)
            local owner = meta:get_string("owner")
            if owner == player:get_player_name() then
                return true
            end
        end
    end
    
    return false
end

-- Можна використовувати цю функцію в обробниках