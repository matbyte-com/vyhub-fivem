VyHub.Warning = VyHub.Warning or {}

function VyHub.Warning:create(license, reason, processor_license)
    processor_license = (processor_license or nil)

    VyHub.Player:get(license, function(user)
        if (user == nil) then
            VyHub.Util:print_chat_license(processor_license, f("Cannot find VyHub user with SteamID %s.", license))
            return
        end

        VyHub.Player:get(processor_license, function(processor)
            if (processor_license ~= nil and processor == nil) then
                return
            end

            local url = '/warning/'

            if (processor ~= nil) then
                url = url .. f('?morph_user_id=%s', processor.id)
            end

            VyHub.API:post(url, nil, {
                reason = reason,
                serverbundle_id = VyHub.server.serverbundle.id,
                user_id = user.id
            }, function(code, result)
                VyHub.Ban:refresh()
                VyHub:msg(f("Added warning for player %s: %s", user.username, reason))
                VyHub.Util:print_chat_all(f(VyHub.lang.warning.user_warned, user.username, processor.username, reason))
                VyHub.Util:print_chat_license(license, f(VyHub.lang.warning.received, processor.username, reason))
                VyHub.Util:play_sound_license(license, "https://cdn.vyhub.net/sound/negativebeep.wav")
                TriggerEvent("vyhub_dashboard_data_changed")
                TriggerClientEvent("vyhub_dashboard_data_changed", -1)
            end, function(code, err_reason, _, err_text)
                VyHub:msg(f("Error while adding warning for player %s: %s", user.username, err_text), "error")
                VyHub.Util:print_chat_license(processor_license, f(VyHub.lang.warning.create_error, user.username, err_text))
            end)
        end)
    end)
end

function VyHub.Warning:delete(warning_id, processor_license)
    processor_license = (processor_license or nil)

    VyHub.Player:get(processor_license, function(processor)
        if (not processor) then
            return
        end

        local url = '/warning/%s'

        if (processor ~= nil) then
            url = url .. f('?morph_user_id=%s', processor.id)
        end

        VyHub.API:delete(url, {warning_id}, function(code, result)
            VyHub:msg(f("%s deleted warning %s.", processor.username, warning_id))
            VyHub.Util:print_chat_license(processor_license, f(VyHub.lang.warning.deleted))
            -- VyHub.Util:print_chat_license(steamid, VyHub.lang.warning.deleted_self)
            hook.Run("vyhub_dashboard_data_changed")
        end, function(code, err_reason, _, err_text)
            VyHub:msg(f("Error while deleteing warning %s: %s", warning_id, err_text), "error")
            VyHub.Util:print_chat_license(processor_license, f(VyHub.lang.other.error_api, err_text))
        end)
    end)
end

function VyHub.Warning:toggle(warning_id, processor_license)
    processor_license = (processor_license or nil)

    VyHub.Player:get(processor_license, function(processor)
        if (not processor) then
            return
        end

        local url = '/warning/%s/toggle'

        if (processor ~= nil) then
            url = url .. f('?morph_user_id=%s', processor.id)
        end

        VyHub.API:patch(url, {warning_id}, nil, function(code, result)
            VyHub:msg(f("%s toggled warning %s.", processor.username, warning_id))
            VyHub.Util:print_chat_license(processor_license, f(VyHub.lang.warning.toggled))
            -- VyHub.Util:print_chat_license(steamid, VyHub.lang.warning.toggled_self)
            TriggerEvent("vyhub_dashboard_data_changed")
            TriggerClientEvent("vyhub_dashboard_data_changed", -1)
        end, function(code, err_reason, _, err_text)
            VyHub:msg(f("Error while toggling status of warning %s: %s", warning_id, err_text), "error")
            VyHub.Util:print_chat_license(processor_license, f(VyHub.lang.other.error_api, err_text))
        end)
    end)
end

function warn_command(license, args)
    if (not VyHub.Player:check_property(license, "warning_edit")) then
        VyHub.Util:print_chat(license, VyHub.lang.ply.no_permissions)
        return
    end

    if (args[1] and args[2]) then
        local reason = VyHub.Util:concat_args(args, 2)

        local targetSrc = tonumber(args[2])

        if (targetSrc) then
            VyHub.Warning:create(VyHub.Player:get_license(targetSrc), reason, license)
        end
    end

    VyHub.Util:print_chat(license, VyHub.lang.warning.cmd_help)

    return false
end

RegisterNetEvent("vyhub_ready", function()

    RegisterCommand("vh_warn", function(src, args)
        if (not args[1] or not args[2]) then
            return
        end

        if (src <= 0) then
            VyHub.Warning:create(args[1], args[2])
        else
            local license = VyHub.Player:get_license(src)
            if VyHub.Player:check_property(license, "warning_edit") then
                VyHub.Warning:create(args[1], args[2], license)
            else
                VyHub.Util:print_chat(license, VyHub.lang.ply.no_permissions)
            end
        end
    end)

    RegisterCommand("vh_warning_toggle", function(src, args)
        if (not args[1]) then
            return
        end

        local warning_id = args[1]

        if (src <= 0) then
            VyHub.Warning:toggle(warning_id)
        else
            local license = VyHub.Player:get_license(src)
            if (VyHub.Player:check_property(license, "warning_edit")) then
                VyHub.Warning:toggle(warning_id, license)
            else
                VyHub.Util:print_chat(license, VyHub.lang.ply.no_permissions)
            end
        end
    end)

    RegisterCommand("vh_warning_delete", function(src, args)
        if (not args[1]) then
            return
        end

        local warning_id = args[1]

        if (src <= 0) then
            VyHub.Warning:delete(warning_id)
        else
            local license = VyHub.Player:get_license(src)
            if (VyHub.Player:check_property(license, "warning_delete")) then
                VyHub.Warning:delete(warning_id, license)
            else
                VyHub.Util:print_chat(license, VyHub.lang.ply.no_permissions)
            end
        end
    end)
end)
