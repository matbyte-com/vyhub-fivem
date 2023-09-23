VyHub.Advert = VyHub.Advert or {}
VyHub.adverts = VyHub.adverts or {}

local current_advert = 0

function VyHub.Advert:refresh()
    VyHub.API:get("/advert/", nil, { active = "true", serverbundle_id = VyHub.server.serverbundle.id }, function(code, result)
        VyHub.adverts = result
    end)
end

function VyHub.Advert:show(advert)
	if advert then
		local lines =  VyHub.Util:string_split(advert.content, '\n')
		local color = VyHub.Util:hex2rgb(advert.color)

		local prefix = VyHub.Config.advert_prefix
		
		for _, line in ipairs(lines) do
			VyHub.Util:print_chat_all(line, prefix, color)
		end
	end
end

function VyHub.Advert:next()
	current_advert = current_advert + 1;

	local advert = VyHub.adverts[current_advert];

	if advert then
		VyHub.Advert:show(advert)
	else
		current_advert = 0
	end
end

AddEventHandler("vyhub_ready", function()
    VyHub.Advert:refresh()

    VyHub.Util:timer_loop(VyHub.Config.advert_interval * 1000, function()
		VyHub.Advert:next()
	end)

    VyHub.Util:timer_loop(300000, function ()
        VyHub.Advert:refresh()
    end)
end)