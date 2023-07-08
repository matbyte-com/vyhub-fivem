Citizen.CreateThread(function()
    while (not VyHub.Framework:isPlayerLoaded()) do
        Citizen.Wait(100)
    end

    TriggerEvent("vyhub-fivem:playerLoaded")
    TriggerServerEvent("vyhub-fivem:playerLoaded")
end)
