VyHub = VyHub or {}
VyHub.Config = VyHub.Config or {}

f = string.format

function VyHub:msg(message, type)
    type = type or "neutral"
 
    print(f("[%s] ", type), message)
end

VyHub:msg("1", "error")