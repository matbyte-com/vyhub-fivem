VyHub.Group = VyHub.Group or {}

VyHub.groups = VyHub.groups or nil
VyHub.groups_mapped = VyHub.groups_mapped or nil
VyHub.groups_mapped_reversed = VyHub.groups_mapped_reversed or nil
VyHub.Group.group_changes = VyHub.Group.group_changes or {} -- dict(license, groupname) of the last in-game group change (VyHub -> GMOD). Used to prevent loop.

function VyHub.Group:refresh()
    VyHub.API:get("/group/", nil, nil, function(code, result)
        if result ~= VyHub.groups then
            VyHub.groups = result

            local groups_mapped_new = {}
            local groups_mapped_reversed_new = {}

            for _, group in pairs(VyHub.groups) do
                for _, mapping in pairs(group.mappings) do
                    if mapping.serverbundle_id == nil or mapping.serverbundle_id == VyHub.server.serverbundle.id then
                        groups_mapped_new[mapping.name] = group
                        groups_mapped_reversed_new[group.id] = mapping.name
                        break
                    end
                end
            end

            VyHub.groups_mapped = groups_mapped_new
            VyHub.groups_mapped_reversed = groups_mapped_reversed_new
        end
    end, function(code, reason)
        VyHub:msg("Could not refresh groups. Retrying in a minute.", "error")
    end)
end

function VyHub.Group:set(license, groupname, seconds, processor_id, callback)
    if seconds ~= nil and seconds == 0 then
        seconds = nil
    end

    if VyHub.groups_mapped == nil then
        VyHub:msg("Groups not initialized yet. Please try again later.", "error")

        return
    end

    local group = VyHub.groups_mapped[groupname]

    if group == nil then
        VyHub:msg(f("Could not find VyHub group with name '%s'", groupname), "debug")

        if callback then
            callback(false)
            return
        end
        return
    end

    VyHub.Player:get(license, function(user)
        if user == nil then
            if callback then
                callback(false)
                return
            end
        end

        local end_date = nil

        if seconds ~= nil then
            end_date = VyHub.Util:format_datetime(os.time() + seconds)
        end

        local url = '/user/%s/membership'

        if processor_id ~= nil then
            url = url .. '?morph_user_id=' .. processor_id
        end

        VyHub.API:post(url, {user.id}, {
            begin = VyHub.Util.format_datetime(),
            ["end"] = end_date,
            group_id = group.id,
            serverbundle_id = VyHub.server.serverbundle.id
        }, function(code, result)
            VyHub:msg(f("Added membership in group %s for user %s.", groupname, license), "success")

            VyHub.Player:get(license, function(user)
                local src = VyHub.Player:get_source(license)

                if src then
                    VyHub.Player:refresh(ply.src)
                end 
                

                if callback then
                    callback(true)
                end
            end)
        end, function(code, reason)
            VyHub:msg(f("Could not add membership in group %s for user %s.", groupname, license), "error")
            if callback then
                callback(false)
            end
        end)
    end)
end

if ESX then
    AddStateBagChangeHandler("group", nil, function(bagName, key, value, reserved, replicated)
        if (not value or string.find(bagName, "player:", 1, true) ~= 1) then
            return
        end
        local ply = GetPlayerFromStateBagName(bagName)
        if(not ply or ply <= 0) then
            return
        end
        local license = VyHub.Player:get_license(ply)
        local currentGroups = VyHub.Framework:getPlayerGroups(ply)
        if #currentGroups == 0 then return end
        local currentGroup = currentGroups[1]
        if not currentGroup then return end

        if VyHub.Group.group_changes[ply] == value then
            VyHub.Group.group_changes[ply] = nil
            return
        end

        if VyHub.Player.last_known_groups[license] == value then return end

        VyHub:msg(f("Detected group change of player %s to group %s (from %s)", license, value, VyHub.Player.last_known_groups[license]), "debug")

        VyHub.Group:set(license, value)

        VyHub.Player.last_known_groups[license] = value
    end)
end

AddEventHandler("vyhub_ready", function()
    VyHub.Util:timer_loop(60000*5, function()
        VyHub.Group:refresh()
    end)
end)
