VyHub.API = VyHub.API or {}

local content_type = "application/json; charset=utf-8"

function VyHub.API:request(method, url, path_params, query, headers, request_body, success, failed, no_error_for)
    url = f("%s%s", VyHub.API.url, url)
    no_error_for = no_error_for or {}

    if path_params ~= nil then 
        url = f(url, table.unpack(path_params)) 
    end

    if type(request_body) == "table" then 
        request_body = json.encode(request_body)
    end

    if query ~= nil then
        u = urllib.parse(url)
        u:setQuery(query)
        url = tostring(u:normalize())
        print(url)
    end

    response_func = function(code, body, headers)
        local result = body

        if headers["content-type"] == 'application/json' then
            result = json.decode(body) 
        end

        if code >= 200 and code < 300 then
            VyHub:msg(f("HTTP %s %s (%s): %s", method, url, json.encode(query),
                        code), "debug")

            if success ~= nil then
                -- VyHub:msg(f("Response: %s", body), "debug")

                success(code, result, headers)
            end
        else
            if no_error_for[code] == nil then
                VyHub:msg(
                    f("HTTP %s %s: %s \nQuery: %s\nBody: %s", method, url, code,
                      json.encode(query), request_body), "error")

                if code ~= 502 then
                    VyHub:msg(f("Response: %s", body), "error")
                end
            end

            if failed ~= nil then
                local err_text = json.encode(result)

                if type(result) == "table" and result.detail ~= nil and
                    result.detail.msg ~= nil then
                    err_text = f("%s (%s)", result.detail.msg,
                                 result.detail.code)
                end

                failed(code, result, headers, err_text)
            end
        end
    end

    failed_func = function(reason)
        VyHub:msg(f("HTTP %s request to %s failed with reason '%s'.\nQuery: %s\nBody: %s", method, url, reason, json.encode(query), request_body),"error")

        if failed ~= nil then failed(0, reason, {}) end
    end

    PerformHttpRequest(url, response_func, method, request_body, headers)
end

function VyHub.API:get(endpoint, path_params, query, success, failed, no_error_for)
    self:request("GET", endpoint, path_params, query, self.headers, nil, success, failed, no_error_for)
end

function VyHub.API:delete(endpoint, path_params, success, failed)
    self:request("DELETE", endpoint, path_params, nil, self.headers, nil, success, failed)
end

function VyHub.API:post(endpoint, path_params, body, success, failed, query)
    self:request("POST", endpoint, path_params, query, self.headers, body,success, failed)
end

function VyHub.API:patch(endpoint, path_params, body, success, failed)
    self:request("PATCH", endpoint, path_params, nil, self.headers, body,success, failed)
end

function VyHub.API:put(endpoint, path_params, body, success, failed)
    self:request("PUT", endpoint, path_params, nil, self.headers, body,success, failed)
end

AddEventHandler("vyhub_loading_finish", function()
    if VyHub.Util:invalid_str({
        VyHub.Config.api_url, VyHub.Config.api_key, VyHub.Config.server_id
    }) then
        VyHub:msg(
            "API URL, Server ID or API Key not set! Please follow the manual.",
            "error")

        SetTimeout(60000, function()
            TriggerEvent("vyhub_loading_finish")
        end)

        return
    end

    VyHub.API.url = VyHub.Config.api_url
    VyHub.API.headers = {
        Authorization = f("Bearer %s", VyHub.Config.api_key),
        ["Content-Type"] = content_type
    }

    if VyHub.Util:endsWith(VyHub.API.url, "/") then
        VyHub.API.url = string.sub(VyHub.API.url, 1, -2)
    end

    VyHub:msg(f("API URL is %s", VyHub.API.url))

    VyHub.API:get("/openapi.json", nil, nil, function(code, result, headers)
        VyHub:msg(f("Connection to API %s version %s successful!",
                    result.info.title, result.info.version), "success")

        TriggerEvent("vyhub_api_ready")
    end, function()
        VyHub:msg("Connection to API failed! Trying to use cache.", "error")

        TriggerEvent("vyhub_api_failed")
    end)
end)

TriggerEvent("vyhub_loading_finish")
