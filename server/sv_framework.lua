VyHub.Framework = VyHub.Framework or {}

function VyHub.Framework:getPlayerFromId(src)
    if (VyHub.Config.framework == "ESX") then
        return ESX.GetPlayerFromId(src)
    end
end

function VyHub.Framework:getPlayerFromIdentifier(identifier)
    if (VyHub.Config.framework == "ESX") then
        return ESX.GetPlayerFromIdentifier(identifier)
    end
end

function VyHub.Framework:getPlayerGroup(src)
    local xPlayer = VyHub.Framework:getPlayerFromId(src)
    if(not xPlayer) then
        return
    end
    if (VyHub.Config.framework == "ESX") then
        return xPlayer.getGroup()
    end
end

function VyHub.Framework:setPlayerGroup(src, group)
    local xPlayer = VyHub.Framework:getPlayerFromId(src)
    if(not xPlayer) then
        return
    end

    VyHub.Group.group_changes[src] = group

    if (VyHub.Config.framework == "ESX") then
        xPlayer.setGroup(group)
    end
end

function VyHub.Framework:getPlayers()
    if(VyHub.Config.framework == "ESX") then
        return ESX.GetExtendedPlayers()
    end
end