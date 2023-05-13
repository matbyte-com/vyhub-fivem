VyHub.Player = VyHub.Player or {}

VyHub.Player.connect_queue = VyHub.Player.connect_queue or {}
VyHub.Player.table = VyHub.Player.table or {}

function VyHub.Player:initialize(ply, retry)
    if ply == nil then return end

    local license = VyHub.Player:get_license(ply)
    local nick = GetPlayerName(ply)

    VyHub:msg(f("Initializing user %s, %s", nick, license))

    VyHub.API:get("/user/%s", {license}, {type = "FIVEM"}, function(code, result)
        VyHub:msg(f("Found existing user %s for license %s (%s).", result.id, license, nick), "success")

        VyHub.Player.table[license] = result

        VyHub.Player:refresh(ply)

        TriggerEvent("vyhub_ply_initialized", ply)

        -- local ply_timer_name = "vyhub_player_" .. license

        -- VyHub.Util:timer_loop(60000, function() 
            
        -- end)
        -- timer.Create(ply_timer_name, VyHub.Config.player_refresh_time, 0, function()
        --     if IsValid(ply) then
        --         VyHub.Player:refresh(ply)
        --     else
        --         timer.Remove(ply_timer_name)
        --     end
        -- end)
    end, function(code, reason)
        if code ~= 404 then
            VyHub:msg(f("Could not check if users %s exists. Retrying in a minute..", license), "error")

            --VyHub.Util:timer_loop(60000, function() 
            --    VyHub.Player:initialize(ply)
            --end)

            return
        end

        if retry then
            VyHub:msg(f("Could not create user %s. Retrying in a minute..", license), "error")

            --VyHub.Util:timer_loop(60000, function() 
            --    VyHub.Player:initialize(ply)
            --end)

            return
        end

        VyHub.Player:create(license, function()
            VyHub.Player:initialize(ply, true)
        end, function ()
            VyHub.Player:initialize(ply, true)
        end)
    end, { 404 })
end

function VyHub.Player:create(license, success, err)
    VyHub:msg(f("No existing user found for license %s. Creating..", license))

    VyHub.API:post('/user/', nil, { identifier = license, type = 'FIVEM' }, function()
        if success then
            success()
        end
    end, function()
        if err then
            err()
        end
    end)
end

-- Return nil if license is nil or API error
-- Return false if license is false or could not create user
function VyHub.Player:get(license, callback, retry)
    if license == nil then
        callback(nil)
        return
    end

    if license == false then
        callback(false)
        return
    end

    if VyHub.Player.table[license] ~= nil then
        callback(VyHub.Player.table[license])
    else
        VyHub.API:get("/user/%s", {license}, {type = "FIVEM"}, function(code, result)
            VyHub:msg(f("Received user %s for license %s.", result.id, license), "debug")
    
            VyHub.Player.table[license] = result

            callback(result)
        end, function(code)
            VyHub:msg(f("Could not receive user %s.", license), "error")

            if code == 404 and retry == nil then
                VyHub.Player:create(license, function ()
                    VyHub.Player:get(license, callback, true)
                end, function ()
                    callback(false)
                end)
            else
                callback(nil)
            end
        end)
    end
end

function VyHub.Player:check_group(ply, callback)
    local license = self:get_license(ply)
    
    VyHub.Player:get(license, function(user)
        if not user then
            VyHub:msg(f("Could not check groups for user %s, because no VyHub id is available.", license), "debug")
            return
        end

        return

        VyHub.API:get("/user/%s/group", {user.id}, { serverbundle_id = VyHub.server.serverbundle_id }, function(code, result)
            local highest = nil

            for _, group in pairs(result) do
                if highest == nil or highest.permission_level < group.permission_level then
                    highest = group
                end
            end

            if highest == nil then
                VyHub:msg(f("Could not find any active group for %s (%s)", GetPlayerName(ply), license), "error")
                return
            end

            local group = nil

            for _, mapping in pairs(highest.mappings) do
                if mapping.serverbundle_id == nil or mapping.serverbundle_id == VyHub.server.serverbundle.id then
                    group = mapping.name
                    break
                end
            end

            if group == nil then
                VyHub:msg(f("Could not find group name mapping for group %s.", highest.name), "error")
                return
            end

            -- curr_group = ply:GetUserGroup()

            -- if curr_group ~= group then
            --     if serverguard then
            --         serverguard.player:SetRank(ply, group, false, true)
            --     elseif ulx then
            --         ULib.ucl.addUser( ply:SteamID(), {}, {}, group, true )
            --     elseif sam then
            --         sam.player.set_rank(ply, group, 0, true)
            --     elseif xAdmin and xAdmin.Admin.RegisterBan then
            --         xAdmin.SetGroup(ply, group, true)
            --     else
            --         ply:SetUserGroup(group, true)
            --     end
                
            --     VyHub:msg("Added " .. GetPlayerName(ply) .. " to group " .. group, "success")
            --     VyHub.Util:print_chat(ply, f(VyHub.lang.ply.group_changed, group))
            -- end
        end, function()
            
        end)
    end)
end

function VyHub.Player:refresh(ply, callback)
    -- VyHub.Player:check_group(ply)
end

function VyHub.Player:get_group(ply)
    if not IsValid(ply) then
        return nil
    end

    local group = VyHub.groups_mapped[ply:GetUserGroup()]

    if group == nil then
        return nil
    end

    return group
end

function VyHub.Player:check_property(ply, property)
    if not IsValid(ply) then return false end

    local group = VyHub.Player:get_group(ply)

    if group ~= nil then
        local prop = group.properties[property]

        if prop ~= nil and prop.granted then
            return true 
        end
    end

    if ply:GetNWBool("vyhub_admin", false) then
        return true
    end

    return false
end

AddEventHandler('playerConnecting', function(name, setCallback, deferrals)
    VyHub:msg("ply conn")
    local source = source -- PlayerID
    
    deferrals.defer()
    Wait(0)
    deferrals.update("[VyHub] Checking Userdata")

    VyHub:msg("ply conn2: " .. source)

    VyHub.Player:initialize(source)

    deferrals.done()
end)

function VyHub.Player:get_steamid(player)
    VyHub:msg(json.encode(GetPlayerIdentifiers(player)))
	for k,v in pairs(GetPlayerIdentifiers(player))do
        if string.sub(v, 1, string.len("steam:")) == "steam:" then
        	return tonumber(v:gsub("steam:", ""), 16)
        end
	end
end

function VyHub.Player:get_license(player)
    for k, v in pairs(GetPlayerIdentifiers(player)) do
        if string.sub(v, 1, string.len("license:")) == "license:" then
            return v:gsub("license:", "")
        end
    end
end