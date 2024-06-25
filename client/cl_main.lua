VyHub.client_license = VyHub.client_license or nil

Citizen.CreateThread(function()
    while VyHub.client_license == nil do
        TriggerServerEvent("vyhub-fivem:clientInfo")
        VyHub:msg("Player not loaded yet", "debug")
        Citizen.Wait(1000)
    end

    VyHub:msg("Player loaded", "debug")

    TriggerEvent("vyhub-fivem:playerLoaded")
    TriggerServerEvent("vyhub-fivem:playerLoaded")
end)

RegisterNetEvent("vyhub-fivem:clientInfo", function(license)
    VyHub.client_license = license
end)