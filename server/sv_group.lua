VyHub.Group = VyHub.Group or {}

VyHub.groups = VyHub.groups or nil
VyHub.groups_mapped = VyHub.groups_mapped or nil
VyHub.Group.group_changes = VyHub.Group.group_changes or {} -- dict(license, groupname) of the last in-game group change (VyHub -> GMOD). Used to prevent loop.

function VyHub.Group:refresh()
    VyHub.API:get("/group/", nil, nil, function(code, result)
        if result ~= VyHub.groups then
            VyHub.groups = result

            -- VyHub:msg(string.format("Found groups: %s", json.encode(result)), "debug")

            VyHub.groups_mapped = {}

            for _, group in pairs(VyHub.groups) do
                for _, mapping in pairs(group.mappings) do
                    if mapping.serverbundle_id == nil or mapping.serverbundle_id == VyHub.server.serverbundle.id then
                        VyHub.groups_mapped[mapping.name] = group
                        break
                    end
                end
            end
        end
    end, function(code, reason)
        VyHub:msg("Could not refresh groups. Retrying in a minute.", "error")
        timer.Simple(60, function()
            VyHub.Group:refresh()
        end)
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
        VyHub:msg(f("Could not find VyHub group with name '%s'", groupname), "error")

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

            local ply =  VyHub.Player.table[license]

            --if IsValid(ply) then
                VyHub.Player:refresh(ply.src)
            --end

            if callback then
                callback(true)
            end
        end, function(code, reason)
            VyHub:msg(f("Could not add membership in group %s for user %s.", groupname, license), "error")
            if callback then
                callback(false)
            end
        end)
    end)
end

--[[ function VyHub.Group:remove(license, processor_id, callback)
    VyHub.Player:get(license, function(user)
        if user == nil then
            if callback then
                callback(false)
                return
            end
        end

        local url = f('/user/%%s/membership?serverbundle_id=%s', VyHub.server.serverbundle.id)

        if processor_id ~= nil then
            url = url .. '&morph_user_id=' .. processor_id
        end

        VyHub.API:delete(url, {user.id}, function(code, result)
            VyHub:msg(f("Removed %s from all groups.", license), "success")

            local ply = player.GetBylicense64(license)

            if IsValid(ply) then
                VyHub.Player:refresh(ply)
            end

            if callback then
                callback(true)
            end
        end, function(code, reason)
            VyHub:msg(f("Could not remove %s from all groups.", license), "error")

            if callback then
                callback(false)
            end
        end)
    end)
end ]]
