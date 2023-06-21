AddEventHandler("gameEventTriggered", function(event, data)
    if (event ~= "CEventNetworkEntityDamage") then
        return
    end
    local victim, victimDied = data[1], data[4]
    if (not IsPedAPlayer(victim)) then
        return
    end
    local player = PlayerId()
    local playerPed = PlayerPedId()
    if (victimDied and NetworkGetPlayerIndexFromPed(victim) == player and (IsPedDeadOrDying(victim, true) or IsPedFatallyInjured(victim))) then
        local killerEntity, deathCause = GetPedSourceOfDeath(playerPed), GetPedCauseOfDeath(playerPed)
        local killerClientId = NetworkGetPlayerIndexFromPed(killerEntity)
        if (killerEntity ~= playerPed and killerClientId and NetworkIsPlayerActive(killerClientId)) then
            playerKilledByPlayer(GetPlayerServerId(killerClientId), killerClientId, deathCause)
        else
            playerKilled(deathCause)
        end
    end
end)

function playerKilledByPlayer(killerServerId, killerClientId, deathCause)
    local victimCoords = GetEntityCoords(PlayerPedId())
    local killerCoords = GetEntityCoords(GetPlayerPed(killerClientId))
    local distance = #(victimCoords - killerCoords)

    local data = {
        victimCoords = {
            x = math.floor(victimCoords.x + 0.5),
            y = math.floor(victimCoords.y + 0.5),
            z = math.floor(victimCoords.z + 0.5)
        },
        killerCoords = {
            x = math.floor(killerCoords.x + 0.5),
            y = math.florr(killerCoords.y + 0.5),
            z = math.floor(killerCoords.z + 0.5)
        },

        killedByPlayer = true,
        deathCause = deathCause,
        distance = math.floor(distance + 0.5),

        killerServerId = killerServerId,
        killerClientId = killerClientId
    }

    TriggerEvent("vyhub-fivem:onPlayerDeath", data)
    TriggerServerEvent("vyhub-fivem:onPlayerDeath", data)
end

function playerKilled(deathCause)
    local playerPed = PlayerPedId()
    local victimCoords = GetEntityCoords(playerPed)

    local data = {
        victimCoords = {
            x = math.floor(victimCoords.x + 0.5),
            y = math.floor(victimCoords.y + 0.5),
            z = math.floor(victimCoords.z + 0.5)
        },

        killedByPlayer = false,
        deathCause = deathCause
    }

    TriggerEvent("vyhub-fivem:onPlayerDeath", data)
    TriggerServerEvent("vyhub-fivem:onPlayerDeath", data)
end
