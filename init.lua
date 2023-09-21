VyHub = VyHub or {}
VyHub.Config = VyHub.Config or {}

f = string.format

function VyHub:msg(message, type)
    type = type or "info"

    if type == "debug" and not VyHub.Config.debug then return end
 
    print(f("[%s] ", type), message)
end

