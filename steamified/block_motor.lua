minetest.register_node("steamified:motor", {
    description = "Furnace Generator\n" .. minetest.colorize("#888888", "Generates " .. steamified.config.MOTOR_OUTPUT .. " SU @ " .. steamified.config.RPM .. " RPM") .. minetest.colorize("#cfc17f", "\nMust be placed on top of a lit furnace to work."),
    drawtype = "mesh",
    mesh = "furnace.obj",
    tiles = {"steamified_steel_block.png", "steamified_steel_block.png"},
    paramtype = "light",
    paramtype2 = "facedir",
    groups = {cracky = 2, stone = 1},
    
    selection_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}
    },
    collision_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}
    },

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)

        steamified.motors[steamified.hash_pos(pos)] = {
            pos = pos,
            is_active = false,
            current_stress = 0
        }
        steamified.save_data()
        meta:set_string("infotext", "Furnace Engine: Idle (No heat source underneath)")
    end,
    
    after_place_node = function(pos, placer, itemstack, pointed_thing)
        local node = minetest.get_node(pos)
        local obj = minetest.add_entity(pos, "steamified:baked_entity")
        if obj then
            local ent = obj:get_luaentity()
            ent._param2 = node.param2
            ent._is_motor_shaft = true
            ent:refresh_properties()
        end
    end,
    
    on_destruct = function(pos)
        steamified.motors[steamified.hash_pos(pos)] = nil
        steamified.save_data()
        
        for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 0.5)) do
            if obj:get_luaentity() and obj:get_luaentity().name == "steamified:baked_entity" then 
                obj:remove() 
            end
        end
    end,
})
