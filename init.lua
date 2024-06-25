VyHub = VyHub or {}
VyHub.Config = VyHub.Config or {}

f = string.format

ESX = nil 
QBCore = nil

if exports["qb-core"] then
    QBCore = exports["qb-core"]:GetCoreObject()
elseif exports["es_extended"] then
    ESX = exports["es_extended"]:getSharedObject()
end


function VyHub:msg(message, type)
    type = type or "info"

    if type == "debug" and not VyHub.Config.debug then return end
 
    print(f("[%s] ", type), message)
end

