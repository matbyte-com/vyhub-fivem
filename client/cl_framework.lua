VyHub.Framework = VyHub.Framework or {}

function VyHub.Framework:isPlayerLoaded()
    if (VyHub.Config.framework == "ESX") then
        return ESX ~= nil and ESX.IsPlayerLoaded()
    end
end

function VyHub.Framework:getLicense()
    if (VyHub.Config.framework == "ESX") then
        return ESX.PlayerData.identifier
    end
end
