steamified.timer = 0

minetest.register_globalstep(function(dtime)
    local network_update_needed = false

    for h, motor in pairs(steamified.motors) do
        if not motor or not motor.pos or not motor.pos.x then
            steamified.motors[h] = nil
            steamified.save_data()
            network_update_needed = true
        else
            local meta = minetest.get_meta(motor.pos)
            local stress = motor.current_stress or 0
            
            local base_pos = vector.new(motor.pos.x, motor.pos.y - 1, motor.pos.z)
            local base_node = minetest.get_node_or_nil(base_pos)
            
            local furnace_has_heat = false
            
            if base_node then

                if base_node.name == "default:furnace_active" then
                    furnace_has_heat = true

                elseif base_node.name == "default:furnace" then
                    local base_meta = minetest.get_meta(base_pos)
                    if base_meta and base_meta:get_float("fuel_time") > 0 then
                        furnace_has_heat = true
                    end
                end
            end

            if furnace_has_heat ~= motor.is_active then
                motor.is_active = furnace_has_heat
                network_update_needed = true
            end

            if motor.is_active then
                if stress > steamified.config.STRESS_THRESHOLD then
                    meta:set_string("infotext", "Furnace Engine: Overstressed\nStress: " .. stress .. "/" .. steamified.config.MOTOR_OUTPUT .. " SU")
                else

                    meta:set_string("infotext", "Furnace Engine: Running\nOutput: " .. steamified.config.MOTOR_OUTPUT .. " SU / " .. steamified.config.RPM .. " RPM\nStress: " .. stress .. "/" .. steamified.config.MOTOR_OUTPUT .. " SU")
                end
            else
                meta:set_string("infotext", "Furnace Engine: Idle (Furnace below is empty or unlit)")
            end
        end
    end

    if steamified.creative_engines then
        for h, engine in pairs(steamified.creative_engines) do
            if not engine or not engine.pos or not engine.pos.x then
                steamified.creative_engines[h] = nil
                steamified.save_data()
                network_update_needed = true
            else

                if engine.is_active ~= true then
                    engine.is_active = true
                    network_update_needed = true
                end
            end
        end
    end

    local global_timer = steamified.timer + dtime
    if global_timer >= 0.2 or network_update_needed then
        steamified.timer = 0
        steamified.update_power_network()
    else
        steamified.timer = global_timer
    end
end)
