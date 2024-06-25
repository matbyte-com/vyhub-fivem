VyHub.Framework = VyHub.Framework or {}

function VyHub.Framework:getPlayerFromId(src)
    if ESX then
        return ESX.GetPlayerFromId(src)
    elseif QBCore then
        local data = QBCore.Functions.GetPlayer(tonumber(src))
        return data
    end
end

function VyHub.Framework:getPlayerGroups(src)
    if ESX then
        local xPlayer = VyHub.Framework:getPlayerFromId(src)
        if(not xPlayer) then
            return {}
        end

        return {xPlayer.getGroup()}
    elseif QBCore then
        local data = QBCore.Functions.GetPermission(tonumber(src))
        return data
    end

    return {}
end

function VyHub.Framework:setPlayerGroup(src, group)
    VyHub.Group.group_changes[src] = group

    if ESX then
        local xPlayer = VyHub.Framework:getPlayerFromId(src)
        if not xPlayer then
            return
        end

        xPlayer.setGroup(group)
    elseif QBCore then
        QBCore.Functions.AddPermission(tonumber(src), group)
    end
end

function VyHub.Framework:removePlayerGroup(src, group)
    VyHub.Group.group_changes[src] = group

    if ESX then
        return
    elseif QBCore then
        QBCore.Functions.RemovePermission(tonumber(src), group)
    end
end

function VyHub.Framework:getPlayers()
    if ESX then
        return ESX.GetExtendedPlayers()
    elseif QBCore then
        return QBCore.Functions.GetQBPlayers()
    end
end

function VyHub.Framework:getPlayerCharName(src)
    xPlayer = VyHub.Framework:getPlayerFromId(src)
    if not xPlayer then
        return
    end

    if ESX then
        return xPlayer.getName()
    elseif QBCore then
        return xPlayer.PlayerData.charinfo.firstname .. " " .. xPlayer.PlayerData.charinfo.lastname
    end
end