VyHub.Cache = VyHub.Cache or {}

function VyHub.Cache:save(key, value)
    local resourcePath = GetResourcePath(GetCurrentResourceName())
    local data = {
        timestamp = os.time(),
        data = value
    }

    local filename = string.format("%s/data/%s.json", resourcePath, key)
    local json = json.encode(data)

    VyHub:msg("Write " .. filename .. ": " .. json, "debug")

    local file = io.open(filename, "w")
    if (file) then
        file:write(json)
        file:close()
    else

    end
end

function VyHub.Cache:get(key, max_age)
    local data_str = LoadResourceFile(GetCurrentResourceName(), f("data/%s.json", key))

    if (not data_str) then
        return nil
    end

    local data = json.decode(data_str)
    if (not data) then
        return nil
    end

    if (type(data) == "table" and data.timestamp and data.data) then
        if (max_age ~= nil and os.time() - data.timestamp > max_age) then
            return nil
        end

        return data.data
    end

    return nil
end
