minetest.register_node("steamified:gearbox", {
    description = "Gearbox\n" .. minetest.colorize("#888888", "No stress impact") .. minetest.colorize("#cfc17f", "\nTransmits rotation along all three axes"),
    drawtype = "mesh",
    mesh = "gearbox_frame.obj",
    tiles = {"steamified_shaft.png"}, 
    inventory_image = "steamified_gearbox_inv.png",
    wield_image = "steamified_gearbox_inv.png",
    paramtype = "light",
    paramtype2 = "facedir",
    groups = {cracky = 2, stone = 1, kinetic_component = 1, kinetic_gearbox = 1},
    
    selection_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}
    },
    collision_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}
    },

    on_construct = function(pos)
        if not steamified.gearboxes then steamified.gearboxes = {} end
        steamified.gearboxes[steamified.hash_pos(pos)] = {pos = pos}
        steamified.save_data()
    end,

    after_place_node = function(pos, placer, itemstack, pointed_thing)
        local node = minetest.get_node(pos)

        local core_obj = minetest.add_entity(pos, "steamified:baked_entity")
        if core_obj then
            local core_ent = core_obj:get_luaentity()
            core_ent._param2 = node.param2
            core_ent._is_motor_shaft = true
            core_ent._mesh_prefix = "gearbox_inner" 
            core_ent._is_static_part = true
            core_ent._custom_textures = {"steamified_wood.png"}
            core_ent:refresh_properties()
        end

        local axes_planes = {"x", "y", "z"}
        for _, plane in ipairs(axes_planes) do
            local obj = minetest.add_entity(pos, "steamified:baked_entity")
            if obj then
                local ent = obj:get_luaentity()
                ent._param2 = node.param2
                ent._is_motor_shaft = true 
                ent._mesh_prefix = "shaft"
                ent._gearbox_axis_plane = plane 
                ent._custom_textures = {"steamified_shaft.png"}
                ent:refresh_properties()
            end
        end
        steamified.update_power_network()
    end,

    on_destruct = function(pos)
        if steamified.gearboxes then
            steamified.gearboxes[steamified.hash_pos(pos)] = nil
            steamified.save_data()
        end
        
        for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 0.5)) do
            local ent = obj:get_luaentity()
            if ent and ent.name == "steamified:baked_entity" then 
                if ent._sound_handle then minetest.sound_stop(ent._sound_handle) end
                obj:remove() 
            end
        end
        steamified.update_power_network()
    end,
})