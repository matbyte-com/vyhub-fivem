AddEventHandler("playerSpawned", function()
    VyHub:msg("Player spawned")
    TriggerServerEvent("vyhub-fivem:playerSpawned")
end)