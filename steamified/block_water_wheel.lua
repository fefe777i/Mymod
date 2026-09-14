minetest.register_node("steamified:water_wheel", {
    description = "Water Wheel\n" .. minetest.colorize("#888888", "Generates " .. steamified.config.WATER_WHEEL_OUTPUT .. " SU @ " .. steamified.config.WATER_WHEEL_RPM .. " RPM") .. minetest.colorize("#cfc17f", "\nMust be adjacent to fluid (perferably water) to work."),
    drawtype = "airlike",
    tiles = {"steamified_wood.png"},
    inventory_image = "steamified_water_wheel_inv.png",
    wield_image = "steamified_water_wheel_inv_2.png",
    paramtype = "light",
    paramtype2 = "facedir",
    sunlight_propagates = true,
    walkable = true,
    pointable = true,
    diggable = true,
    selection_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
    },
    collision_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
    },
    groups = steamified.power_node_groups({groups = {choppy = 2, wood = 1}, has_shaft = true, has_cog = false}),

    after_place_node = function(pos)
        if not steamified.water_wheels then steamified.water_wheels = {} end
        local h = steamified.hash_pos(pos)
        steamified.water_wheels[h] = {pos = pos, active = steamified.is_adjacent_fluid(pos)}
        steamified.save_data()
        steamified.add_power_node(pos, "steamified:water_wheel")
        steamified.update_power_network()
    end,

    on_destruct = function(pos)
        if steamified.water_wheels then
            steamified.water_wheels[steamified.hash_pos(pos)] = nil
            steamified.save_data()
        end
        steamified.remove_power_node(pos)
        steamified.update_power_network()
    end,
})

steamified.register_power_node("steamified:water_wheel", {
    component_type = "generator",
    has_shaft = true,
    has_wheel = true,
    rpm = steamified.config.WATER_WHEEL_RPM,
    output = steamified.config.WATER_WHEEL_OUTPUT,
    wheel_textures = {"steamified_wood.png"},
    get_axis = function(node)
        return steamified.get_axis_vector(node.param2)
    end,
    is_active = function(pos)
        return steamified.is_adjacent_fluid(pos)
    end,
})

minetest.register_abm({
    label = "Steamified water wheel fluid check",
    nodenames = {"steamified:water_wheel"},
    interval = 2.0,
    chance = 1,
    action = function(pos)
        if not steamified.water_wheels then steamified.water_wheels = {} end
        local h = steamified.hash_pos(pos)
        local touching = steamified.is_adjacent_fluid(pos)
        local entry = steamified.water_wheels[h]
        local old_active = entry and (type(entry) == "table" and entry.active or entry)
        if old_active ~= touching then
            steamified.water_wheels[h] = {pos = pos, active = touching}
            steamified.save_data()
            steamified.update_power_network()
        end
    end,
})
