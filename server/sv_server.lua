VyHub.Server = VyHub.Server or {}

VyHub.Server.extra_defaults = {
    res_slots = 0,
    res_slots_keep_free = false,
    res_slots_hide = false,
}

VyHub.Server.reserved_slot_plys = VyHub.Server.reserved_slot_plys or {}

function VyHub.Server:get_extra(key)
    if VyHub.server.extra ~= nil and VyHub.server.extra[key] ~= nil then
        return VyHub.server.extra[key]
    end

    return VyHub.Server.extra_defaults[key]
end

function VyHub.Server:update_status()
    local user_activities = {}

    local data = {
        users_max = VyHub.Config.max_players,
        users_current = GetNumPlayerIndices(),
        is_alive = true,
    }

    VyHub:msg(f("Updating status: %s", json.encode(data)), "debug")

    VyHub.API:patch(
        '/server/%s',
        {VyHub.Config.server_id},
        data,
        function ()
        end,
        function ()
            VyHub:msg("Could not update server status.", "error")
        end
    )
end


RegisterNetEvent("vyhub_api_ready")
AddEventHandler("vyhub_api_ready", function()
    VyHub.Server:update_status()

    --VyHub.Util:timer_loop(60000, function() 
    --    VyHub.Server:update_status()
    --end)
end)