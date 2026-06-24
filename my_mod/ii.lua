minetest.register_globalstep(function(dtime)

    for _, player in ipairs(minetest.get_connected_players()) do
        local pos = player:get_pos()

        for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 12)) do
            local ent = obj:get_luaentity()

            if ent and ent.name == "__builtin:item" then
                local p = obj:get_pos()
                local vel = obj:get_velocity()

                local node = minetest.get_node_or_nil({
                    x = p.x,
                    y = p.y - 0.5,
                    z = p.z
                })

                if node and minetest.registered_nodes[node.name].walkable then
                    local stack = ItemStack(ent.itemstring)
                    local count = stack:get_count()

                    -- сила залежить від кількості предметів
                    local power = 0.4 + (count * 0.02)

                    obj:set_velocity({
                        x = vel.x * 0.9 + math.random(-1,1) * 0.2,
                        y = math.abs(vel.y) * power,
                        z = vel.z * 0.9 + math.random(-1,1) * 0.2
                    })
                end
            end
        end
    end

end)