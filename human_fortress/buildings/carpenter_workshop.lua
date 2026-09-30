local storage = minetest.get_mod_storage()

local RECIPES = {
    chair = {
        name = "🪑 Стілець",
        item = "kitchen_furniture:chair",
        ether = 8,
        versi = 2,
        count = 1
    },
    ladder = {
        name = "🪜 Драбина",
        item = "default:ladder",
        ether = 6,
        versi = 1,
        count = 2
    },
    table = {
        name = "🪵 Стіл",
        item = "kitchen_furniture:table",
        ether = 14,
        versi = 4,
        count = 1
    },
    chest = {
        name = "📦 Дерев'яна скриня",
        item = "default:chest",
        ether = 18,
        versi = 5,
        count = 1
    }
}

local function get_data(name)
    return human_fortress.edos_data[name] or {}
end

local function show_menu(player_name, pos)
    local data = get_data(player_name)
    local formspec = "formspec_version[4]size[10,7]" ..
        "box[0,0;10,0.8;#2D2D44]" ..
        "label[0.5,0.2;🪚 ПЛОТНИЦЬКА МАЙСТЕРНЯ]" ..
        "label[6.3,0.2;🌲 " .. (data.ether or 0) .. "]" ..
        "label[8,0.2;🪨 " .. (data.versi or 0) .. "]" ..
        "label[0.5,1.05;Виберіть, що виробляти:]" ..
        "button[0.5,1.6;4.2,1;chair;🪑 Стілець\n8🌲 + 2🪨]" ..
        "button[5.2,1.6;4.2,1;ladder;🪜 Драбини ×2\n6🌲 + 1🪨]" ..
        "button[0.5,3;4.2,1;table;🪵 Стіл\n14🌲 + 4🪨]" ..
        "button[5.2,3;4.2,1;chest;📦 Скриня\n18🌲 + 5🪨]" ..
        "button[3.5,5.5;3,0.8;close;❌ ЗАКРИТИ]"
    minetest.show_formspec(player_name, "human_fortress:carpenter_workshop", formspec)
end

local function produce(player_name, recipe_id, pos)
    local player = minetest.get_player_by_name(player_name)
    if not player then return end

    local recipe = RECIPES[recipe_id]
    if not recipe then return end

    if not minetest.registered_items[recipe.item] then
        minetest.chat_send_player(player_name, "❌ Предмет не знайдено: " .. recipe.item)
        return
    end

    local data = get_data(player_name)
    local ether = data.ether or 0
    local versi = data.versi or 0

    if ether < recipe.ether then
        minetest.chat_send_player(player_name, "❌ Недостатньо Ефіру! Потрібно " .. recipe.ether .. ", є " .. ether)
        return
    end

    if versi < recipe.versi then
        minetest.chat_send_player(player_name, "❌ Недостатньо Версиформу! Потрібно " .. recipe.versi .. ", є " .. versi)
        return
    end

    local stack = ItemStack(recipe.item .. " " .. recipe.count)
    local leftover = player:get_inventory():add_item("main", stack)
    if not leftover:is_empty() then
        minetest.chat_send_player(player_name, "❌ Немає місця в інвентарі!")
        return
    end

    data.ether = ether - recipe.ether
    data.versi = versi - recipe.versi
    human_fortress.save_data(player_name)

    minetest.chat_send_player(player_name, "✅ Виготовлено: " .. recipe.name .. " ×" .. recipe.count)
    show_menu(player_name, pos)
end

if not BUILDING_MENUS then BUILDING_MENUS = {} end

BUILDING_MENUS.carpenter_workshop = function(player_name, core_pos)
    local core_data = human_fortress.get_core_data and human_fortress.get_core_data(core_pos)
    local owner = core_data and core_data.owner or ""
    if owner ~= "" and owner ~= player_name then
        minetest.chat_send_player(player_name, "❌ Це чужа будівля!")
        return
    end

    local tmp = minetest.deserialize(storage:get_string("carpenter_workshop_tmp")) or {}
    tmp[player_name] = core_pos
    storage:set_string("carpenter_workshop_tmp", minetest.serialize(tmp))
    show_menu(player_name, core_pos)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "human_fortress:carpenter_workshop" then return end

    local name = player:get_player_name()
    local tmp = minetest.deserialize(storage:get_string("carpenter_workshop_tmp")) or {}
    local pos = tmp[name]

    if fields.close then return true end

    for recipe_id in pairs(RECIPES) do
        if fields[recipe_id] then
            if pos then
                produce(name, recipe_id, pos)
            end
            return true
        end
    end

    return true
end)

return {
    id = "carpenter_workshop",
    data = {
        name = "🪚 Плотницька майстерня",
        description = "Виробництво дерев'яних меблів та конструкцій",
        unlock_required = "town_hall",
        cost = {
            score = 0,
            wood = 0,
            stone = 0,
            ether = 120,
            versi = 80
        },
        schematic = "carpenter_workshop.we",
        color = "#A66A32",
        on_built = function(player_name, pos)
            minetest.chat_send_player(player_name, "🪚 Плотницька майстерня побудована!")
        end
    }
}
