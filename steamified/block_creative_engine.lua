minetest.register_node("steamified:creative_engine", {
    description = "Creative Generator\n" .. minetest.colorize("#888888", "Generates ∞ SU @ " .. steamified.config.RPM .. " RPM"),
    drawtype = "mesh",
    mesh = "furnace.obj",

    tiles = {"default_gold_block.png", "default_gold_block.png"},
    paramtype = "light",
    paramtype2 = "facedir",
    groups = {cracky = 1, stone = 1, creative_breakable = 1},
    
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

        if not steamified.creative_engines then steamified.creative_engines = {} end
        
        steamified.creative_engines[steamified.hash_pos(pos)] = {
            pos = pos,
            is_active = true
        }
        meta:set_string("infotext", "Creative Generator: ∞ SU / 64 RPM")
    end,
    
    after_place_node = function(pos, placer, itemstack, pointed_thing)
        local node = minetest.get_node(pos)
        local obj = minetest.add_entity(pos, "steamified:baked_entity")
        if obj then
            local ent = obj:get_luaentity()
            ent._param2 = node.param2
            ent._is_motor_shaft = true
            ent._custom_textures = {"steamified_shaft.png"}
            ent:refresh_properties()
        end
    end,
    
    on_destruct = function(pos)
        if steamified.creative_engines then
            steamified.creative_engines[steamified.hash_pos(pos)] = nil
        end
        
        for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 0.5)) do
            if obj:get_luaentity() and obj:get_luaentity().name == "steamified:baked_entity" then 
                obj:remove() 
            end
        end
    end,
})
