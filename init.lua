VyHub = VyHub or {}
VyHub.Config = VyHub.Config or {}

f = string.format

ESX = nil 
QBCore = nil

if GetResourceState("qb-core") == "started" then
    QBCore = exports["qb-core"]:GetCoreObject()
elseif GetResourceState("es_extended") == "started" then
    ESX = exports["es_extended"]:getSharedObject()
end


function VyHub:msg(message, type)
    type = type or "info"

    if type == "debug" and not VyHub.Config.debug then return end
 
    print(f("[%s] ", type), message)
end

