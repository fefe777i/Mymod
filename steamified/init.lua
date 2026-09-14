steamified = {}
steamified.motors = {}            
steamified.miners = {}            
steamified.cogs = {}              
steamified.powered_positions = {} 
steamified.gearboxes = {}
steamified.creative_engines = {}
steamified.water_wheels = {}
steamified.rotators = {}
steamified.nodeentities = {}

local storage = minetest.get_mod_storage()

function steamified.load_data()
    local data = storage:get_string("motors")
    steamified.motors = data and data ~= "" and minetest.deserialize(data) or {}
    
    local miner_data = storage:get_string("miners")
    steamified.miners = miner_data and miner_data ~= "" and minetest.deserialize(miner_data) or {}

    local cog_data = storage:get_string("cogs")
    steamified.cogs = cog_data and cog_data ~= "" and minetest.deserialize(cog_data) or {}

    local creative_data = storage:get_string("creative_engines")
    steamified.creative_engines = creative_data and creative_data ~= "" and minetest.deserialize(creative_data) or {}

    local gearboxes_data = storage:get_string("gearboxes")
    steamified.gearboxes = gearboxes_data and gearboxes_data ~= "" and minetest.deserialize(gearboxes_data) or {}

    local water_wheels_data = storage:get_string("water_wheels")
    steamified.water_wheels = water_wheels_data and water_wheels_data ~= "" and minetest.deserialize(water_wheels_data) or {}

    local rotators_data = storage:get_string("rotators")
    steamified.rotators = rotators_data and rotators_data ~= "" and minetest.deserialize(rotators_data) or {}
end

function steamified.save_data()
    storage:set_string("creative_engines", minetest.serialize(steamified.creative_engines))
    storage:set_string("motors", minetest.serialize(steamified.motors))
    storage:set_string("miners", minetest.serialize(steamified.miners))
    storage:set_string("cogs", minetest.serialize(steamified.cogs))
    storage:set_string("gearboxes", minetest.serialize(steamified.gearboxes))
    storage:set_string("water_wheels", minetest.serialize(steamified.water_wheels))
    storage:set_string("rotators", minetest.serialize(steamified.rotators))
end

steamified.load_data()

local path = minetest.get_modpath("steamified")

-- Load core architectures
dofile(path .. "/api.lua")
dofile(path .. "/system_engine.lua")
dofile(path .. "/system_miner.lua")
dofile(path .. "/nodeentity.lua")
steamified.read_world = nodeentity.read_world

-- Load individual components
dofile(path .. "/block_motor.lua")
dofile(path .. "/block_miner.lua")
dofile(path .. "/block_kinetic.lua")
dofile(path .. "/block_creative_engine.lua")
dofile(path .. "/block_gearbox.lua")
dofile(path .. "/block_water_wheel.lua")
dofile(path .. "/block_rotator.lua")

-- Initial global state restoration sweep
if steamified.restore_saved_state then
    steamified.restore_saved_state()
end

dofile(path .. "/crafting.lua")

---
--- Load Block Modifiers (LBMs)
---

minetest.register_lbm({
    label = "Steamified: restore water wheels",
    name = "steamified:restore_water_wheel",
    nodenames = {"steamified:water_wheel"},
    run_at_every_load = true,
    action = function(pos, node)
        if not steamified.water_wheels then steamified.water_wheels = {} end
        local h = steamified.hash_pos(pos)
        
        -- Run dynamic environment check for fluids
        local active = steamified.is_adjacent_fluid(pos)
        if not active then
            local above = minetest.get_node_or_nil(vector.add(pos, {x = 0, y = 1, z = 0}))
            if above then
                local def = minetest.registered_nodes[above.name]
                if (def and def.liquidtype and def.liquidtype ~= "none") or (minetest.get_item_group(above.name, "liquid") > 0) then
                    active = true
                end
            end
        end

        steamified.water_wheels[h] = {pos = pos, active = active}
        
        -- Visual verification: ensure rolling wheel entity is loaded
        local found = false
        for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 0.5)) do
            local ent = obj:get_luaentity()
            if ent and ent.name == "steamified:baked_entity" then 
                found = true 
                break 
            end
        end
        
        if not found then
            local obj = minetest.add_entity(pos, "steamified:baked_entity")
            if obj then
                local ent = obj:get_luaentity()
                ent._param2 = node.param2
                ent._mesh_prefix = "wheel"
                ent._custom_textures = {"steamified_wood.png"}
                ent._rpm = steamified.config.WATER_WHEEL_RPM
                ent:refresh_properties()
            end
        end
        
        steamified.add_power_node(pos, "steamified:water_wheel")
        steamified.save_data()
        steamified.update_power_network()
    end,
})

minetest.register_lbm({
    label = "Steamified: restore gearbox visuals on block load",
    name = "steamified:restore_gearbox",
    nodenames = {"steamified:gearbox"},
    run_at_every_load = true,
    action = function(pos, node)
        if not steamified.gearboxes then steamified.gearboxes = {} end
        local h = steamified.hash_pos(pos)
        steamified.gearboxes[h] = {pos = pos}
        
        local found = false
        for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 0.5)) do
            local ent = obj:get_luaentity()
            if ent and ent.name == "steamified:baked_entity" then found = true break end
        end
        
        if not found then
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
        end
        steamified.save_data()
        steamified.update_power_network()
    end,
})

minetest.register_lbm({
    label = "Steamified: restore creative engine on block load",
    name = "steamified:restore_creative_engine",
    nodenames = {"steamified:creative_engine"},
    run_at_every_load = true,
    action = function(pos, node)
        if not steamified.creative_engines then steamified.creative_engines = {} end
        local h = steamified.hash_pos(pos)
        steamified.creative_engines[h] = {pos = pos, is_active = true}
        
        local found = false
        for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 0.5)) do
            local ent = obj:get_luaentity()
            if ent and ent.name == "steamified:baked_entity" then found = true break end
        end
        
        if not found then
            local obj = minetest.add_entity(pos, "steamified:baked_entity")
            if obj then
                local ent = obj:get_luaentity()
                ent._param2 = node.param2
                ent._is_motor_shaft = true
                ent._custom_textures = {"steamified_shaft.png"}
                ent:refresh_properties()
            end
        end
        
        steamified.add_power_node(pos, "steamified:creative_engine")
        steamified.save_data()
        steamified.update_power_network()
    end,
})

minetest.register_lbm({
    label = "Steamified: restore kinetic axle visuals on block load",
    name = "steamified:restore_axle",
    nodenames = {"steamified:axle"},
    run_at_every_load = true,
    action = function(pos, node)
        local found = false
        for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 0.5)) do
            local ent = obj:get_luaentity()
            if ent and ent.name == "steamified:baked_entity" then found = true break end
        end

        if not found then
            local obj = minetest.add_entity(pos, "steamified:baked_entity")
            if obj then
                local ent = obj:get_luaentity()
                ent._param2 = node.param2
                ent._mesh_prefix = "shaft"
                ent._custom_textures = {"steamified_shaft.png"}
                ent:refresh_properties()
            end
        end

        steamified.update_power_network()
    end,
})

minetest.register_lbm({
    label = "Steamified: restore cog visuals on block load",
    name = "steamified:restore_cog",
    nodenames = {"steamified:cog"},
    run_at_every_load = true,
    action = function(pos, node)
        if not steamified.cogs then steamified.cogs = {} end
        local h = steamified.hash_pos(pos)
        steamified.cogs[h] = pos

        local found = false
        for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 0.5)) do
            local ent = obj:get_luaentity()
            if ent and ent.name == "steamified:baked_entity" then found = true break end
        end

        if not found then
            local obj1 = minetest.add_entity(pos, "steamified:baked_entity")
            if obj1 then
                local ent1 = obj1:get_luaentity()
                ent1._param2 = node.param2
                ent1._mesh_prefix = "shaft"
                ent1._custom_textures = {"steamified_shaft.png"}
                ent1:refresh_properties()
            end

            local obj2 = minetest.add_entity(pos, "steamified:baked_entity")
            if obj2 then
                local ent2 = obj2:get_luaentity()
                ent2._param2 = node.param2
                ent2._mesh_prefix = "cog"
                ent2._custom_textures = {"steamified_wood.png"}
                ent2:refresh_properties()
            end
        end

        steamified.save_data()
        steamified.update_power_network()
    end,
})