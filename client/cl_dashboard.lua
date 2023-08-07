VyHub.Dashboard = (VyHub.Dashboard or {})

VyHub.Dashboard.ui = (VyHub.Dashboard.ui or nil)

VyHub.Dashboard.html_ready = false

RegisterNetEvent("vyhub_lang_loaded", function()
    while (not VyHub.Dashboard.html_ready) do
        Citizen.Wait(50)
    end
    local license = VyHub.Framework:getLicense()
    SendNUIMessage({
        type = "init",
        data = {
            license = license,
            lang = VyHub.lang
        }
    })
end)
RegisterNUICallback("ready", function()
    VyHub.Dashboard.html_ready = true
end)
RegisterNUICallback("exit", function()
    SetNuiFocus(false, false)
end)

RegisterCommand("vh_dashboard", function(src, args)
    while (not VyHub.Dashboard.html_ready) do
        Citizen.Wait(50)
    end
    TriggerServerEvent("vyhub_dashboard")
    SendNUIMessage({
        type = "toggleUI",
        data = {
            toggle = true
        }
    })
    SetNuiFocus(true, true)
end)

RegisterNetEvent("vyhub_dashboard", function(users, perms)
    while (not VyHub.Dashboard.html_ready) do
        Citizen.Wait(50)
    end
    VyHub.Dashboard:load_users(users)
    VyHub.Dashboard:load_perms(perms)
end)

function VyHub.Dashboard:load_users(users)
    SendNUIMessage({
        type = "load_data",
        data = {
            users = users
        }
    })
end

function VyHub.Dashboard:load_perms(perms_json)
    SendNUIMessage({
        type = "load_perms",
        data = {
            perms = perms_json
        }
    })
end

RegisterNUICallback("warning_toggle", function(data)
    ExecuteCommand(f("vh_warning_toggle %s", data.id))
end)
RegisterNUICallback("warning_delete", function(data)
    ExecuteCommand(f("vh_warning_delete %s", data.id))
end)
RegisterNUICallback("ban_set_status", function(data)

    ExecuteCommand(f("ban_set_status %s %s", data.id, data.status))
end)
RegisterNUICallback("warning_create", function(data)
    ExecuteCommand(f('vh_warn %s "%s"', data.identifier, VyHub.Util:escape_concommand_str(data.reason)))
end)
RegisterNUICallback("ban_create", function(data)
    ExecuteCommand(f('vh_ban %s "%s" "%s"', data.identifier, data.minutes, VyHub.Util:escape_concommand_str(data.reason)))
end)
