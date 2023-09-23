VyHub.Statistic = VyHub.Statistic or {}
VyHub.Statistic.playtime = VyHub.Statistic.playtime or {}
VyHub.Statistic.attr_def = VyHub.Statistic.attr_def or nil

function VyHub.Statistic:save_playtime()
    VyHub:msg(f("Saved playtime statistics: %s", json.encode(VyHub.Statistic.playtime)), "debug")

    VyHub.Cache:save("playtime", VyHub.Statistic.playtime)
end

function VyHub.Statistic:add_one_minute()

    local players = GetPlayers()
    for i, src in ipairs(players) do
        local plyLicense = VyHub.Player:get_license(src)
        VyHub.Player:get(plyLicense, function(user)
            if (not user) then
                VyHub:msg(f("Could not add playtime for user %s", plyLicense), "error")
                return
            end
            VyHub.Statistic.playtime[user.id] = (VyHub.Statistic.playtime[user.id] or 0) + 60
        end)
    end
    VyHub.Statistic:save_playtime()
end

function VyHub.Statistic:send_playtime()
    VyHub.Statistic:get_or_create_attr_definition(function(attr_def)
        if (attr_def == nil) then
            VyHub:msg("Could not send playtime statistics to API.", "warning")
            return
        end

        local user_ids = table.GetKeys(VyHub.Statistic.playtime)

        Citizen.CreateThread(function()
            for i, userId in ipairs(user_ids) do
                if (not userId) then
                    return
                end
                local seconds = VyHub.Statistic.playtime[userId]
                if (seconds and seconds > 0) then
                    local hours = math.Round(seconds / 60 / 60, 2)

                    if (hours) > 0 then
                        if (string.len(userId) < 10) then
                            VyHub.Statistic.playtime[userId] = nil
                            return
                        end

                        VyHub.API:post("/user/attribute/", nil, {
                            definition_id = attr_def.id,
                            user_id = userId,
                            serverbundle_id = VyHub.server.serverbundle.id,
                            value = tostring(hours)
                        }, function(code, result)
                            VyHub.Statistic.playtime[userId] = nil
                            VyHub.Statistic:save_playtime()
                        end, function(code, reason)
                            if (code == 404) then
                                VyHub.Statistic.playtime[userId] = nil
                                VyHub.Statistic:save_playtime()
                            end

                            VyHub:msg(f("Could not send %s seconds playtime of %s to API.", seconds, userId), "warning")
                        end)
                    end
                else
                    VyHub.Statistic.playtime[userId] = nil
                end
                Citizen.Wait(300)
            end
        end)
    end)
end

function VyHub.Statistic:get_or_create_attr_definition(callback)
    local function cb_wrapper(attr_def)
        VyHub.Statistic.attr_def = attr_def

        callback(attr_def)
    end

    if (VyHub.Statistic.attr_def) then
        callback(VyHub.Statistic.attr_def)
        return
    end

    VyHub.API:get("/user/attribute/definition/%s", {"playtime"}, nil, function(code, result)
        VyHub.Cache:save("playtime_attr_def", result)
        cb_wrapper(result)
    end, function(code, reason)
        if (code ~= 404) then
            local attr_def = VyHub.Cache:get("playtime_attr_def")
            cb_wrapper(attr_def)
        else
            VyHub.API:post("/user/attribute/definition/", nil, {
                name = "playtime",
                title = "Play Time",
                unit = "Hours",
                type = "ACCUMULATED",
                accumulation_interval = "day",
                unspecific = "true"
            }, function(code, result)
                VyHub.Cache:save("playtime_attr_def", result)
                cb_wrapper(result)
            end, function(code, reason)
                cb_wrapper(nil)
            end)
        end
    end)
end

AddEventHandler("vyhub_ready", function()
    VyHub.Statistic.playtime = VyHub.Cache:get("playtime") or {}

    VyHub.Statistic:send_playtime()

    VyHub.Util:timer_loop(60000, function()
        VyHub.Statistic:add_one_minute()
    end)

    VyHub.Util:timer_loop(60 * 60000, function()
        VyHub.Statistic:send_playtime()
    end)
end)
