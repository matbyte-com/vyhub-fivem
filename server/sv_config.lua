function VyHub.Config:load_cache_config()
    local ccfg = VyHub.Cache:get("config")

    if ccfg ~= nil and #table.GetKeys(ccfg) > 0 then
        for k,v in pairs(ccfg) do VyHub.Config[k] = v end
        VyHub:msg(f("Loaded cache config values: %s", table.concat(table.GetKeys(ccfg), ', ')))
    end
end

RegisterCommand("vh_setup", function(src, args)
    if src > 0 then return end
    if not args[1] or not args[2] or not args[3] then return end 

    ExecuteCommand(f("vh_config api_key \"%s\"", string.Replace(args[1], '"', '')))
    ExecuteCommand(f("vh_config api_url \"%s\"", string.Replace(args[2], '"', '')))
    ExecuteCommand(f("vh_config server_id \"%s\"", string.Replace(args[3], '"', '')))
end, true)
    
RegisterCommand("vh_config", function(src, args)
    if src > 0 then return end

    local ccfg = VyHub.Cache:get("config")

    if not args[1] or not args[2] then 
        if type(ccfg) == "table" then
            VyHub:msg("Additional config options:")
            VyHub:msg(VyHub.Util:dumpTable(ccfg))
        else
            VyHub:msg("No additional config options set.")
        end
        return
    end

    local key = args[1]
    local value = args[2]

    if type(ccfg) ~= "table" then
        ccfg = {}
    end

    if value == "false" then
        value = false
    elseif value == "true" then
        value = true
    end

    ccfg[key] = value
    VyHub.Cache:save("config", ccfg)

    VyHub.Config[key] = value

    VyHub:msg(f("Successfully set config value %s.", key))
end, true)

RegisterCommand("vh_config_reset", function(src, args)
    if src > 0 then return end

    VyHub.Cache:save("config", {})

    VyHub:msg(f("Successfully cleared additional config.", key))
end, true)
