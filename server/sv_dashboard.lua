VyHub.Dashboard = (VyHub.Dashboard or {})
VyHub.Dashboard.last_update = (VyHub.Dashboard.last_update or {})
VyHub.Dashboard.data = (VyHub.Dashboard.data or {})

function VyHub.Dashboard:reset()
    VyHub.Dashboard.data = {}
    VyHub.Dashboard.last_update = {}
    TriggerClientEvent("vyhub_dashboard_reload", -1)
end

function VyHub.Dashboard:fetch_data(user_id, callback)
    VyHub.API:get("/server/%s/user-activity?morph_user_id=%s", {VyHub.server.id, user_id}, nil, function(code, result)
        callback(result)
    end)
end

function VyHub.Dashboard:get_data(license, callback)
    if VyHub.Dashboard.data[license] == nil or VyHub.Dashboard.last_update[license] == nil or os.time() - VyHub.Dashboard.last_update[license] > 30 then
        VyHub.Player:get(license, function(user)
            if user then
                VyHub.Dashboard:fetch_data(user.id, function(data)
                    VyHub.Dashboard.data[license] = data
                    VyHub.Dashboard.last_update[license] = os.time()

                    callback(VyHub.Dashboard.data[license])
                end)
            end
        end)
    else
        callback(VyHub.Dashboard.data[license])
    end
end

function VyHub.Dashboard:get_permissions(license)
    return {
        warning_show = VyHub.Player:check_property(license, 'warning_show'),
        warning_edit = VyHub.Player:check_property(license, 'warning_edit'),
        warning_delete = VyHub.Player:check_property(license, 'warning_delete'),
        ban_show = VyHub.Player:check_property(license, 'ban_show'),
        ban_edit = VyHub.Player:check_property(license, 'ban_edit')
    }
end

RegisterNetEvent("vyhub_dashboard", function()
    local src = source
    local license = VyHub.Player:get_license(src)
    VyHub.Dashboard:get_data(license, function(users)
        local perms = VyHub.Dashboard:get_permissions(license)
        TriggerClientEvent("vyhub_dashboard", src, users, perms)
    end)
end)

AddEventHandler("vyhub_dashboard_data_changed", function()
    VyHub.Dashboard:reset()
end)
