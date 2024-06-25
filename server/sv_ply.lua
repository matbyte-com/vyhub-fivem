VyHub.Player = VyHub.Player or {}

VyHub.Player.connect_queue = VyHub.Player.connect_queue or {}
VyHub.Player.table = VyHub.Player.table or {}
VyHub.Player.src_map = VyHub.Player.src_map or {}
VyHub.Player.last_known_groups = VyHub.Player.last_known_groups or {}
VyHub.Player.properties = VyHub.Player.properties or {}

function VyHub.Player:initialize(ply, retry)
    if ply == nil then return end

    local license = VyHub.Player:get_license(ply)
    local nick = GetPlayerName(ply)

    VyHub.Player.src_map[license] = ply

    VyHub:msg(f("Initializing user %s, %s", nick, license))

    VyHub.API:get("/user/%s", {license}, {type = "FIVEM"}, function(code, result)
        VyHub:msg(f("Found existing user %s for license %s (%s).", result.id, license, nick), "success")
        result.src = ply
        VyHub.Player.table[license] = result

        VyHub.Player:refresh(ply, _, true)

        TriggerEvent("vyhub_ply_initialized", ply)
    end, function(code, reason)
        if code ~= 404 then
            VyHub:msg(f("Could not check if users %s exists. Retrying in a minute..", license), "error")

            Citizen.SetTimeout(60000, function() 
                VyHub.Player:initialize(ply)
            end)

            return
        end

        if retry then
            VyHub:msg(f("Could not create user %s. Retrying in a minute..", license), "error")

            Citizen.SetTimeout(60000, function() 
                VyHub.Player:initialize(ply)
            end)

            return
        end

        VyHub.Player:create(license, function()
            VyHub.Player:initialize(ply, true)
        end, function ()
            VyHub.Player:initialize(ply, true)
        end)
    end, { [404] = true })
end

function VyHub.Player:create(license, success, err)
    VyHub:msg(f("No existing user found for license %s. Creating..", license))
    local plySrc = VyHub.Player:get_source(license)
    if(not plySrc) then
        return
    end
    VyHub.API:post('/user/', nil, { identifier = license, username = GetPlayerName(plySrc), type = 'FIVEM' }, function()
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
            
            result.src = VyHub.Player:get_source(license)
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

        VyHub.API:get("/user/%s/group", {user.id}, { serverbundle_id = VyHub.server.serverbundle_id }, function(code, groups)
            local new_props = {}
            for _, group in pairs(groups) do
                for _, prop in pairs(group.properties) do
                    if prop.granted then
                        new_props[prop.name] = true
                    end
                end
            end
            VyHub.Player.properties = new_props

            if ESX then
                local highest = nil

                local currentGroups = VyHub.Framework:getPlayerGroups(ply)
                local currentGroup = nil

                if #currentGroups > 0 then
                    currentGroup = currentGroups[1]
                end

                VyHub.Player.last_known_groups[license] = currentGroup

                for _, group in pairs(groups) do
                    if highest == nil or highest.permission_level < group.permission_level then
                        highest = group
                    end
                end

                if highest == nil then
                    VyHub:msg(f("Could not find any active group for %s (%s)", GetPlayerName(ply), license), "debug")
                    return
                end

                local group = VyHub.groups_mapped_reversed[highest.id]

                if group == nil then
                    VyHub:msg(f("Could not find group name mapping for group %s.", highest.name), "debug")
                    return
                end

                if currentGroup and currentGroup ~= group then
                    VyHub.Framework:setPlayerGroup(ply, group)
                    VyHub.Util:print_chat_license(license, f(VyHub.lang.ply.group_changed, group))
                    VyHub:msg(f("Added %s to group %s (was %s before)", GetPlayerName(ply), group, currentGroup), "success")
                end
            else
                --[[ VyHub:msg(f("Checking groups for %s", GetPlayerName(ply)), "debug")
                local vyhub_groups = {}

                -- Add missing permissions
                for _, group in pairs(groups) do
                    local groupname = VyHub.groups_mapped_reversed[group.id]

                    if groupname then
                        vyhub_groups[groupname] = true

                        VyHub:msg(f("Player %s Group %s has: %s", ply, groupname, IsPlayerAceAllowed(ply, f("vyhub.group.%s", groupname))), "debug")

                        if not IsPlayerAceAllowed(ply, f("vyhub.group.%s", groupname)) then
                            ExecuteCommand(('add_principal identifier.license:%s %s'):format(license, groupname))
                            VyHub.Util:print_chat_license(license, f(VyHub.lang.ply.group_changed, groupname))
                            VyHub:msg(f("Added %s to group %s", GetPlayerName(ply), groupname), "success")
                        end
                    else
                        VyHub:msg(f("Could not find group name mapping for group %s.", group.name), "debug")
                    end
                end

                -- Remove permissions
                for groupname, _ in pairs(VyHub.groups_mapped) do
                    if not vyhub_groups[groupname] and IsPlayerAceAllowed(ply, f("vyhub.group.%s", groupname)) then
                        ExecuteCommand(('remove_principal identifier.license:%s %s'):format(license, groupname))
                        VyHub:msg(f("Removed %s from group %s", GetPlayerName(ply), groupname), "success")
                    end
                end ]]
            end
        end, function()
            
        end)
    end)
end

function VyHub.Player:refresh(ply, callback, ignore_group)
    if not ply then return end

    if not ignore_group then
        VyHub.Player:check_group(ply)
    end
    VyHub.Player:check_username(ply)
end

function VyHub.Player:check_username(ply)
    local license = self:get_license(ply)
    
    VyHub.Player:get(license, function(user)
        if not user then
            VyHub:msg(f("Could not check username for user %s, because no VyHub id is available.", license), "debug")
            return
        end
        
        local currentName = GetPlayerName(ply)
        local oldName = user.username
        if(not oldName or currentName ~= oldName) then 
            VyHub.API:patch("/user/%s", {user.id}, {username = currentName}, function(code, result)
                VyHub:msg(f("Patched username for user %s (%s -> %s)", result.id, oldName, currentName), "success")
            end, function(code, result)
                if(code ~= 404) then
                    VyHub:msg(f("Could not patch username for user %s", result.id), "error")
                end
            end)
        end
    end)
end


function VyHub.Player:get_groups(license)
    local plySrc = VyHub.Player:get_source(license)
    local playerGroups = VyHub.Framework:getPlayerGroups(plySrc)

    local groups = {}

    for _, groupname in pairs(playerGroups) do
        local group = VyHub.groups_mapped[groupname]

        if group then
            groups[groupname] = group
        end
    end 

    return groups
end

function VyHub.Player:check_property(license, property)
    if VyHub.Player.properties[property] then
        return true
    end

    if VyHub.Player.table[license] then
        return VyHub.Player.table[license].admin
    end 

    return false
end

AddEventHandler('playerConnecting', function(name, setCallback, deferrals)    
    local source = source -- PlayerID

    if not source then return end

    deferrals.defer()
    Wait(0)
    deferrals.update("[VyHub] Checking Userdata")

    VyHub.Player:initialize(source)

    deferrals.done()
end)

RegisterNetEvent("vyhub-fivem:playerLoaded", function()
    local src = source
    local license = VyHub.Player:get_license(src)

    VyHub:msg("Player " .. src .." loaded. License: " .. license, "debug")

    if not source or not license then return end

    local ply_timer_name = "vyhub_player_" .. license

    VyHub.Util:timer_loop(300000, function() 
        local ping = GetPlayerPing(src)
        if not ping or ping <= 0 then
            VyHub:msg("Player " .. src .." not available anymore", "debug")
            VyHub.Util:cancel_timer(ply_timer_name)
            return
        end

        VyHub.Player:refresh(src)
    end, ply_timer_name)

    VyHub.Player:refresh(src, callback)

    Citizen.SetTimeout(30000, function()  
        VyHub.Player:refresh(src, callback)
    end)
end)

function VyHub.Player:get_license(player)
    for k, v in pairs(GetPlayerIdentifiers(player)) do
        if string.sub(v, 1, string.len("license:")) == "license:" then
            return v:gsub("license:", "")
        end
    end
end

function VyHub.Player:get_source(license)
    if VyHub.Player.src_map[license] then
        return VyHub.Player.src_map[license]
    end

    local players = GetPlayers()
    for i, src in ipairs(players) do
        local playerLicense = VyHub.Player:get_license(src)
        if (playerLicense == license) then
            return src
        end
    end
end

function VyHub.Player:get_steamid(player)
	for k,v in pairs(GetPlayerIdentifiers(player))do
        if string.sub(v, 1, string.len("steam:")) == "steam:" then
        	return tonumber(v:gsub("steam:", ""), 16)
        end
	end
end

RegisterNetEvent("vyhub-fivem:clientInfo", function()
    local src = source
    local license = VyHub.Player:get_license(src)

    if license then
        TriggerClientEvent("vyhub-fivem:clientInfo", src, license)
    end
end)