VyHub.Lang = VyHub.Lang or {}
VyHub.lang = VyHub.lang or nil

if (IsDuplicityVersion()) then
    function VyHub.Lang:load()
        local encoded_en = LoadResourceFile(GetCurrentResourceName(), "/lang/en.json")

        if (encoded_en == nil) then
            VyHub:msg("Missing language file en.json!!!", "error")
            return
        end

        local en = json.decode(encoded_en)

        if (type(en) ~= "table") then
            VyHub:msg("Could not load language file en.json!", "error")
            return
        end

        VyHub.lang = en

        VyHub:msg("Loaded language en.")

        if (VyHub.Config.lang ~= 'en') then
            local encoded_custom = LoadResourceFile(GetCurrentResourceName(), f("/lang/%s.json", VyHub.Config.lang))
            if (encoded_custom ~= nil) then
                local custom = json.decode(encoded_custom)
                if (type(custom) == "table") then
                    table.Merge(VyHub.lang, custom)
                    VyHub:msg(f("Loaded language %s.", VyHub.Config.lang))
                else
                    VyHub:msg(f("Could not load language file %s.json!", VyHub.Config.lang), "warning")
                end
            else
                VyHub:msg(f("Missing language file %s.json.", VyHub.Config.lang), "warning")
            end
        end
    end

    if (VyHub.lang == nil) then
        VyHub.Lang:load()
    end

    RegisterNetEvent("vyhub_lang", function()
        TriggerClientEvent("vyhub_lang", source, VyHub.lang)
    end)
else
    function VyHub.Lang:load()
        TriggerServerEvent("vyhub_lang")
    end

    RegisterNetEvent("vyhub_lang", function(data)
        VyHub.lang = data

        VyHub:msg("Loaded language.")

        TriggerEvent("vyhub_lang_loaded")
    end)

    Citizen.CreateThread(function()
        while (VyHub.lang == nil) do
            VyHub.Lang:load()
            Citizen.Wait(5000)
        end
    end)
end
