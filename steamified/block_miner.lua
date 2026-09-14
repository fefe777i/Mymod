minetest.register_node("steamified:miner", {
    description = "Miner\n" .. minetest.colorize("#888888", "Stress impact: " .. steamified.config.MINER_LOAD .. " SU") .. minetest.colorize("#cfc17f", "\nMines up to 16 blocks below"),
    drawtype = "mesh",
    mesh = "miner.obj",
    tiles = {"steamified_steel_block.png"},
    inventory_image = "steamified_miner_inv.png",
    wield_image = "steamified_miner_inv.png",
    paramtype = "light",
    paramtype2 = "facedir",
    groups = steamified.power_node_groups({groups = {cracky = 1, iron = 1}, has_shaft = true}),
    selection_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
    },
    collision_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
    },
    after_place_node = function(pos)
        steamified.miners[steamified.hash_pos(pos)] = pos
        steamified.add_power_node(pos, "steamified:miner")
        steamified.save_data()
        steamified.update_power_network()
    end,
    on_destruct = function(pos)
        steamified.miners[steamified.hash_pos(pos)] = nil
        steamified.remove_power_node(pos)
        steamified.save_data()
        steamified.update_power_network()
    end,
})

steamified.register_power_node("steamified:miner", {
    component_type = "consumer",
    has_shaft = true,
    has_cog = false,
    get_load = function() return steamified.config.MINER_LOAD end,
    get_axis = function(node) return steamified.get_axis_vector(node.param2) end,
})