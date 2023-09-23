VyHub.Ban = VyHub.Ban or {}
VyHub.bans = VyHub.bans or {}
VyHub.Ban.ban_queue = VyHub.Ban.ban_queue or {}
VyHub.Ban.unban_queue = VyHub.Ban.unban_queue or {}

--[[
    ban_queue: Dict[<user_steamid>,List[Dict[...]\]\]
        user_license: str
        length: int (seconds)
        reason: str
        creator_license: str
        created_on: date
        status: str

    unban_queue: Dict[<user_license>, <processor_license>]
]] --

function VyHub.Ban:check_player_banned(license)
    local bans = VyHub.bans[license]
    local queued_bans = VyHub.Ban.ban_queue[license]

    local ban_exists = (bans ~= nil and not table.IsEmpty(bans))

    local queued_ban_exists = false

    if (queued_bans ~= nil) then
        for i, ban in pairs(queued_bans) do
            if (ban ~= nil and ban.status == 'ACTIVE') then
                queued_ban_exists = true
                break
            end
        end
    end

    local queued_unban_exists = VyHub.Ban.unban_queue[license] ~= nil

    return ((ban_exists or queued_ban_exists) and not queued_unban_exists)
end

function VyHub.Ban:kick_banned_players()
    for i, src in ipairs(GetPlayers()) do
        if VyHub.Ban:check_player_banned(VyHub.Player:get_license(src)) then
            DropPlayer(src, "You are banned from the server.")
        end
    end
end

function VyHub.Ban:refresh()
    VyHub.API:get("/server/bundle/%s/ban", {VyHub.server.serverbundle_id}, {
        active = "true"
    }, function(code, result)
        VyHub.bans = result

        VyHub.Cache:save("bans", VyHub.bans)

        VyHub:msg(f("Found %s users with active bans.", table.Count(VyHub.bans)), "debug")

        TriggerEvent("vyhub_bans_refreshed")
    end, function()
        VyHub:msg("Could not refresh bans, trying to use cache.", "error")

        local result = VyHub.Cache:get("bans")

        if (result ~= nil) then
            VyHub.bans = result

            VyHub:msg(f("Found %s users with cached active bans.", table.Count(VyHub.bans)), "neutral")

            TriggerEvent("vyhub_bans_refreshed")
        else
            VyHub:msg("No cached bans available!", "error")
        end
    end)
end

function VyHub.Ban:handle_queue()
    local function failed_ban(license)
        VyHub:msg(f("Could not send ban of user %s to API. Retrying..", license), "error")
    end

    local function failed_unban(license)
        VyHub:msg(f("Could not send unban of user %s to API. Retrying..", license), "error")
    end

    local function failed_ban_abort(license)

    end

    if not table.IsEmpty(VyHub.Ban.ban_queue) then
        for license, bans in pairs(VyHub.Ban.ban_queue) do
            if (bans ~= nil) then
                if (not table.IsEmpty(bans)) then
                    for i, ban in ipairs(bans) do
                        if (ban ~= nil) then
                            VyHub.Player:get(ban.user_license, function(user)
                                if (user) then
                                    VyHub.Player:get(ban.creator_license, function(creator)
                                        if (creator == false) then
                                            return
                                        end

                                        local data = {
                                            length = ban.length,
                                            reason = ban.reason,
                                            serverbundle_id = VyHub.server.serverbundle.id,
                                            user_id = user.id,
                                            created_on = ban.created_on,
                                            status = ban.status
                                        }

                                        local morph_user_id = (creator and creator.id or nil)
                                        local url = '/ban/'

                                        if (morph_user_id ~= nil) then
                                            url = url .. f('?morph_user_id=%s', morph_user_id)
                                        end

                                        VyHub.API:post(url, nil, data, function(code, result)
                                            VyHub.Ban.ban_queue[license][i] = nil
                                            VyHub.Ban:save_queues()
                                            VyHub.Ban:refresh()

                                            local minutes = (data.length ~= nil and f(VyHub.lang.other.x_minutes, math.Round(data.length / 60)) or VyHub.lang.other.permanently)

                                            local creator_name = (creator and creator.username or "console")
                                            local msg = f(VyHub.lang.ban.user_banned, user.username, creator_name, minutes, data.reason)

                                            VyHub:msg(msg, "success")

                                            VyHub.Util:print_chat_all(msg)

                                            TriggerEvent("vyhub_dashboard_data_changed")
                                        end, function(code, reason)
                                            if (code >= 400 and code < 500) then
                                                local msg = reason

                                                local error_msg = f("Could not create ban for %s, aborting: %s", license, json.encode(msg))

                                                VyHub:msg(error_msg, "error")

                                                VyHub.Ban.ban_queue[license][i] = nil
                                                VyHub.Ban:save_queues()

                                                if (creator ~= nil) then
                                                    VyHub.Util:print_chat_license(creator.identifier, error_msg)
                                                end
                                            else
                                                failed_ban(ban.user_license)
                                            end
                                        end)
                                    end)
                                elseif (user == false) then
                                    VyHub.Ban.ban_queue[license][i] = nil
                                    VyHub.Ban:save_queues()
                                else
                                    failed_ban(ban.user_license)
                                end
                            end)
                        end
                    end
                else
                    VyHub.Ban.ban_queue[license] = nil
                    VyHub.Ban:save_queues()
                end
            end
        end
    end

    if (not table.IsEmpty(VyHub.Ban.unban_queue)) then
        for license, creator_license in pairs(VyHub.Ban.unban_queue) do
            if (creator_license) then
                VyHub.Player:get(license, function(user)
                    if (user == false) then
                        VyHub.Ban.unban_queue[license] = nil
                        VyHub.Ban:save_queues()

                        local error_msg = f("Could not unban user %s, aborting: User not found", license)

                        VyHub:msg(error_msg, "error")
                        VyHub.Util:print_chat_license(creator_license, error_msg)
                    elseif (user == nil) then
                        failed_unban(license)
                    else
                        local url = '/user/%s/ban'

                        creator_license = (creator_license == false and nil or creator_license)

                        local msg
                        VyHub.Player:get(creator_license, function(creator)
                            if (creator_license ~= nil and creator == nil) then
                                return
                            end

                            if (creator) then
                                url = url .. f('?morph_user_id=%s', creator.id)
                            end

                            VyHub.API:patch(url, {user.id}, nil, function(code, reslt)
                                VyHub.Ban.unban_queue[license] = nil
                                VyHub.Ban:save_queues()
                                VyHub.Ban:refresh()

                                msg = f("Successfully unbanned user %s.", license)
                                VyHub:msg(msg, "success")
                                VyHub.Util:print_chat_license(creator_license, msg)
                                TriggerEvent("vyhub_dashboard_data_changed")
                            end, function(code, reason)
                                if (code >= 400 and code < 500) then
                                    VyHub.Ban.unban_queue[license] = nil
                                    VyHub.Ban:save_queues()

                                    local error_msg = f("Could not unban user %s, aborting: %s", license, json.encode(msg))

                                    VyHub:msg(error_msg, "error")
                                    VyHub.Util:print_chat_license(creator_license, error_msg)
                                else
                                    failed_unban(license)
                                end
                            end)
                        end)
                    end
                end)
            end
        end
    end
end

function VyHub.Ban:create(license, length, reason, creator_license)
    length = tonumber(length)

    if (length == 0) then
        length = nil
    end

    local data = {
        user_license = license,
        length = (length and length * 60 or nil),
        reason = reason,
        creator_license = creator_license,
        created_on = VyHub.Util:format_datetime(),
        status = 'ACTIVE'
    }

    if (VyHub.Ban.ban_queue[license] == nil) then
        VyHub.Ban.ban_queue[license] = {}
    end

    table.insert(VyHub.Ban.ban_queue[license], data)

    local targetSrc = VyHub.Player:get_source(license)

    local lstr = (length == nil and VyHub.lang.other.permanently or f("%i %s", length, VyHub.lang.other.minutes))

    VyHub.Util:print_chat_all(f(VyHub.lang.ply.banned, GetPlayerName(targetSrc), lstr, reason))

    VyHub.Ban:kick_banned_players()
    VyHub.Ban:save_queues()
    VyHub.Ban:handle_queue()

    VyHub:msg(f("Scheduled ban for user %s.", license))
end

function VyHub.Ban:unban(license, processor_license)
    processor_license = (processor_license or false)

    VyHub.Ban.unban_queue[license] = processor_license

    VyHub.Ban:save_queues()
    VyHub.Ban:handle_queue()

    VyHub:msg(f("Scheduled unban for user %s.", license))
end

function VyHub.Ban:save_queues()
    VyHub.Cache:save("ban_queue", VyHub.Ban.ban_queue)
    VyHub.Cache:save("unban_queue", VyHub.Ban.unban_queue)
end

function VyHub.Ban:clear()
    VyHub.Ban.ban_queue = {}
    VyHub.Ban.unban_queue = {}
    VyHub.Ban:save_queues()
end

function VyHub.Ban:create_ban_msg(ban)
    local msg = VyHub.Config.ban_message or "You have been banned. %reason% - %ban_date%, %unban_date%, %admin%"

    local created_on = VyHub.Util:iso_ts_to_local_str(ban.created_on)
    local ends_on = (ban.ends_on ~= nil and VyHub.Util:iso_ts_to_local_str(ban.ends_on) or VyHub.lang.other.never)
    local creator_username = (ban.creator ~= nil and ban.creator.username or VyHub.lang.other.unknown)
    local id = string.upper(string.sub(ban.id, 1, 8))
    local unban_url = (VyHub.Config.unban_url or VyHub.frontend_url or '-')

    msg = string.Replace(msg, '%%reason%%', ban.reason)
    msg = string.Replace(msg, '%%ban_date%%', created_on)
    msg = string.Replace(msg, '%%unban_date%%', ends_on)
    msg = string.Replace(msg, '%%admin%%', creator_username)
    msg = string.Replace(msg, '%%id%%', id)
    msg = string.Replace(msg, '%%unban_url%%', unban_url)

    return msg
end

function VyHub.Ban:ban_set_status(ban_id, status, processor_license)
    processor_license = (processor_license or nil)

    VyHub.Player:get(processor_license, function(processor)
        if (not processor) then
            return
        end

        local url = '/ban/%s'

        if (processor ~= nil) then
            url = url .. f('?morph_user_id=%s', processor.id)
        end

        VyHub.API:patch(url, {ban_id}, {
            status = status
        }, function(code, result)
            VyHub:msg(f("%s set ban status of ban %s of user %s to %s.", processor.username, ban_id, result.user.username, status))
            VyHub.Util:print_chat_license(processor_license, f(VyHub.lang.ban.status_changed, result.user.username, status))
            TriggerEvent("vyhub_dashboard_data_changed")
            VyHub.Ban:refresh()
        end, function(code, err_reason, _, err_text)
            VyHub:msg(f("Error while settings status of ban %s: %s", ban_id, err_text), "error")
            VyHub.Util:print_chat_license(processor_license, f(VyHub.lang.other.error_api, err_text))
        end)
    end)
end

AddEventHandler("vyhub_ready", function()
    VyHub.Ban:refresh()

    VyHub.Ban.ban_queue = VyHub.Cache:get("ban_queue") or {}
    VyHub.Ban.unban_queue = VyHub.Cache:get("unban_queue") or {}

    VyHub.Util:timer_loop(60000, function()
        VyHub.Ban:refresh()
    end)

    VyHub.Util:timer_loop(10000, function()
        VyHub.Ban:handle_queue()
    end)

    RegisterNetEvent("playerConnecting", function(name, setKickReason, deferrals)
        local src = source
        local license = VyHub.Player:get_license(src)
        local ip = GetPlayerEndpoint(src)
        deferrals.defer()
        Citizen.Wait(0)
        deferrals.update(f("Hello %s! Checking if you are banned..", name))
        Citizen.Wait(0)

        if (VyHub.Ban:check_player_banned(license)) then
            local msg = VyHub.lang.ply.banned_self

            local bans = VyHub.bans[license] or {}

            if (table.Count(bans) > 0) then
                local ban = bans[1]
                msg = VyHub.Ban:create_ban_msg(ban)
            end

            VyHub:msg(f("%s tried to connect with ip %s, but is banned.", license, ip))
            deferrals.done(msg)
        else
            deferrals.done()
        end
    end)
end)

AddEventHandler("vyhub_ready", function()
    AddEventHandler("vyhub_bans_refreshed", function()
        VyHub.Ban:kick_banned_players()
    end)

    RegisterCommand("vh_ban", function(src, args)
        if not args[1] or not args[2] or not args[3] then
            return
        end

        if (src <= 0) then
            VyHub.Ban:create(args[1], args[2], args[3])
        else
            local license = VyHub.Player:get_license(src)
            if (VyHub.Player:check_property(license, "ban_edit")) then
                VyHub.Ban:create(args[1], args[2], args[3], license)
            else
                VyHub.Util:print_chat_license(license, VyHub.lang.ply.no_permissions)
            end
        end
    end)

    RegisterCommand("vh_unban", function(src, args)
        if not args[1] then
            return
        end

        if (src <= 0) then
            VyHub.Ban:unban(args[1])
        else
            local license = VyHub.Player:get_license(src)
            if (VyHub.Player:check_property(license, "ban_edit")) then
                VyHub.Ban:unban(args[1], license)
            else
                VyHub.Util:print_chat_license(license, VyHub.lang.ply.no_permissions)
            end
        end
    end)

    RegisterCommand("vh_ban_set_status", function(src, args)
        if not args[1] or not args[2] then
            return
        end

        if args[2] ~= "UNBANNED" and args[2] ~= "ACTIVE" then
            return
        end

        if (src <= 0) then
            VyHub.Ban:ban_unban(args[1], args[2])
        else
            local license = VyHub.Player:get_license(src)
            if VyHub.Player:check_property(license, "ban_edit") then
                VyHub.Ban:ban_set_status(args[1], args[2], license)
            else
                VyHub.Util:print_chat_license(license, VyHub.lang.ply.no_permissions)
            end
        end
    end)
end)
