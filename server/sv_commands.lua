RegisterCommand("login", function(src, args)
    local uuid = args[1]
    if (not uuid) then
        return
    end

    local license = VyHub.Player:get_license(src)
    VyHub.Player:get(license, function(user)
        if (not user) then
            VyHub:msg(f("Could not send auth request for user %s, because no VyHub id is available.", license), "debug")
            return
        end
        VyHub.API:patch("/auth/request/%s", {uuid}, {
            user_type = "FIVEM",
            identifier = license
        }, function(code, result)
            VyHub:msg(f("Sent auth request for user %s with validation id %s", user.id, result.validation_uuid), "success")
        end, function(code, result)
            if (code ~= 404) then
                VyHub:msg(f("Could not send auth request or user %s", user.id
            ), "error")
            end
        end)
    end)
end)
