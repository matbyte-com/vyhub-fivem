VyHub.Dashboard = (VyHub.Dashboard or {})

VyHub.Dashboard.ui = (VyHub.Dashboard.ui or nil)

VyHub.Dashboard.html_loaded = false
VyHub.Dashboard.html_ready = false
VyHub.Dashboard.open = false

local function open_dashboard()
    while (not VyHub.Dashboard.html_ready) do
        Citizen.Wait(50)
    end
    SendNUIMessage({
        type = "toggleUI",
        data = {
            shown = true
        }
    })
    SetNuiFocus(true, true)
    TriggerScreenblurFadeIn(500)
    VyHub.Dashboard.open = true
    TriggerServerEvent("vyhub_dashboard")
end

local function close_dashboard()
    SendNUIMessage({
        type = "toggleUI",
        data = {
            shown = false
        }
    })
    TriggerScreenblurFadeOut(500)
    SetNuiFocus(false, false)
    VyHub.Dashboard.open = false
end

RegisterNetEvent("vyhub_lang_loaded", function()
    while (not VyHub.Dashboard.html_loaded) do
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
RegisterNUICallback("loaded", function()
    VyHub.Dashboard.html_loaded = true
end)
RegisterNUICallback("ready", function()
    VyHub.Dashboard.html_ready = true
end)
RegisterNUICallback("exit", function()
    close_dashboard()
end)

RegisterCommand(VyHub.Config.dashboard_command, function(src, args)
    open_dashboard()
end)

RegisterNetEvent("vyhub_dashboard", function(users, perms)
    while (not VyHub.Dashboard.html_ready) do
        Citizen.Wait(50)
    end
    VyHub:msg(f("Received %s users and %s perms", #users, #perms))
    VyHub.Dashboard:load_perms(perms)
    VyHub.Dashboard:load_users(users)
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
    ExecuteCommand(f("vh_ban_set_status %s %s", data.id, data.status))
end)
RegisterNUICallback("warning_create", function(data)
    ExecuteCommand(f('vh_warn %s "%s"', data.identifier, VyHub.Util:escape_concommand_str(data.reason)))
end)
RegisterNUICallback("ban_create", function(data)
    ExecuteCommand(f('vh_ban %s "%s" "%s"', data.identifier, data.minutes, VyHub.Util:escape_concommand_str(data.reason)))
end)


RegisterNetEvent("vyhub_dashboard_reload", function()
    if VyHub.Dashboard.open then
        TriggerServerEvent("vyhub_dashboard")
        VyHub:msg("Reloading dashboard data, because server told us.")
    end
end)