Citizen.CreateThread(function()
    while (not VyHub.Framework:isPlayerLoaded()) do
        Citizen.Wait(100)
    end

    TriggerServerEvent("vyhub-fivem:playerLoaded")
end)
