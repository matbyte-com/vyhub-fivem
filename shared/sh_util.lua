VyHub.Util = VyHub.Util or {}


function VyHub.Util:format_datetime(unix_timestamp)
    unix_timestamp = unix_timestamp or os.time()

    local tz_wrong = os.date("%z", unix_timestamp)
    local timezone = string.format("%s:%s", string.sub(tz_wrong, 1, 3), string.sub(tz_wrong, 4, 5))

    return os.date("%Y-%m-%dT%H:%M:%S" .. timezone, unix_timestamp)
end


function VyHub.Util:iso_to_unix_timestamp(datetime)
	if datetime == nil then return nil end

	local pd = date(datetime)

	if pd == nil then return nil end

	local time = os.time(
		{
			year = pd:getyear(),
			month = pd:getmonth(),
			day = pd:getday(),
			hour = pd:gethours(),
			minute = pd:getminutes(),
			second = pd:getseconds(),
		}
	)

	return time
end


function VyHub.Util:concat_args(args, pos)
	local toconcat = {}

	if pos > 1 then
		for i = pos, #args, 1 do
			toconcat[#toconcat+1] = args[i]
		end
	end

	return string.Implode(" ", toconcat)
end


function VyHub.Util:replace_colors(message)
	message = string.Replace(message, '"', '')
	message = string.Replace(message, '<red>', '", Color(255, 24, 35), "')
	message = string.Replace(message, '</red>', '", Color(255, 255, 255), "')
	message = string.Replace(message, '<green>', '", Color(45, 170, 0), "')
	message = string.Replace(message, '</green>', '", Color(255, 255, 255), "')
	message = string.Replace(message, '<blue>', '", Color(0, 115, 204), "')
	message = string.Replace(message, '</blue>', '", Color(255, 255, 255), "')
	message = string.Replace(message, '<yellow>', '", Color(229, 221, 0), "')
	message = string.Replace(message, '</yellow>', '", Color(255, 255, 255), "')
	message = string.Replace(message, '<pink>', '", Color(229, 0, 218), "')
	message = string.Replace(message, '</pink>', '", Color(255, 255, 255), "')

	return message
end

function VyHub.Util:print_chat(license, message, tag, color)
    local targetSrc = VyHub.Player:get_source(license)
    tag = (tag or "VyHub")
    color = (color or {255, 0, 0})
    TriggerClientEvent("chat:addMessage", targetSrc, {
        color = color,
        multiline = true,
        args = {tag, message}
    })
end

function VyHub.Util:print_chat_license(license, message, tag, color)
    local targetSrc = VyHub.Player:get_source(license)
    if(targetSrc) then
        tag = (tag or "VyHub")
        color = (color or {255, 0, 0})
        TriggerClientEvent("chat:addMessage", targetSrc, {
            color = color,
            multiline = true,
            args = {tag, message}
        })
    end
end

function VyHub.Util:play_sound_steamid(steamid, url)
	if steamid ~= nil and steamid ~= false then
		ply = player.GetBySteamID64(steamid)
	
		if IsValid(ply) then
			net.Start("vyhub_run_lua")
				net.WriteString([[sound.PlayURL ( "]] .. url .. [[", "", function() end)]])
			net.Send(ply)
		end
	end
end


function VyHub.Util:print_chat_all(message, tag, color)
    tag = (tag or "VyHub")
    color = (color or {255, 0, 0})
    TriggerClientEvent("chat:addMessage", -1, {
        color = color,
        multiline = true,
        args = {tag, message}
    })
end

function VyHub.Util:get_player_by_nick(nick)
	nick = string.lower(nick);
	
	for _,v in ipairs(player.GetHumans()) do
		if(string.find(string.lower(v:Name()), nick, 1, true) ~= nil)
			then return v;
		end
	end
end


function VyHub.Util:hex2rgb(hex)
    hex = hex:gsub("#","")
    if(string.len(hex) == 3) then
        return Color(tonumber("0x"..hex:sub(1,1)) * 17, tonumber("0x"..hex:sub(2,2)) * 17, tonumber("0x"..hex:sub(3,3)) * 17)
    elseif(string.len(hex) == 6) then
        return Color(tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6)))
    else
    	return Color(255,255,255)
    end
end

function VyHub.Util:iso_ts_to_local_str(iso_ts)
	-- Splitting the ISO timestamp into date and time components
    local date, time = iso_ts:match('^(%d+-%d+-%d+)[T ](%d+:%d+:%d+)')
    
    -- Splitting the date into year, month, and day components
    local year, month, day = date:match('^(%d+)-(%d+)-(%d+)$')
    
    -- Splitting the time into hour, minute, and second components
    local hour, minute, second = time:match('^(%d+):(%d+):(%d+)$')
    
    -- Converting the ISO timestamp to a local date and time
    local local_date_time = os.time({
        year = tonumber(year),
        month = tonumber(month),
        day = tonumber(day),
        hour = tonumber(hour),
        min = tonumber(minute),
        sec = tonumber(second)
    })
    
    -- Formatting the local date and time as a string
    local local_str = os.date("%Y-%m-%d %H:%M:%S", local_date_time)
    
    return local_str
end


function VyHub.Util:invalid_str(str_list)
	for _, str in ipairs(str_list) do
		if str == nil or string.gsub(str, " ", "") == "" then
			return true
		end
	end

	return false
end

function VyHub.Util:escape_concommand_str(str)
	str = string.Replace(str, '"', "'")

	return str
end

function VyHub.Util:endsWith(str, ending)
	return string.find(str, ending, #str - #ending + 1, true) ~= nil
end

function VyHub.Util:timer_loop(delay, callback)
    Citizen.CreateThread(function()
        while(true) do
            Citizen.Wait(delay)
            callback()
        end
    end)
end

function table.HasValue(tbl, val)
    for i, v in pairs(tbl) do
        if (v == val) then
            return true
        end
    end
    return false
end

function table.GetKeys(tbl)
    local outputTable = {}
    for i,v in pairs(tbl) do
        table.insert(outputTable, i)
    end
    return outputTable
end

function table.Count(tbl)
    local counter = 0
    for i,v in pairs(tbl) do
        counter = counter + 1
    end
    return counter
end

function table.IsEmpty(tbl)
    return (next(tbl) == nil)
end

function table.Merge(dest, src)
    for k, v in pairs(src) do
        if (type(v) == "table" and type(dest[k]) == "table") then
            table.Merge(dest[k], v)
        else
            dest[k] = v
        end
    end
    return dest
end

function math.Round(value, decimals)
    decimals = decimals or 0
    local factor = 10 ^ decimals
    return math.floor(value * factor + 0.5) / factor
end

function string.Replace(originalString, findString, replaceString)
    return originalString:gsub(findString, replaceString)
end

function VyHub.Util:dumpTable(table, nb)
    if nb == nil then
		nb = 0
	end

	if type(table) == 'table' then
		local s = ''
		for i = 1, nb + 1, 1 do
			s = s .. "    "
		end

		s = '{\n'
		for k,v in pairs(table) do
			if type(k) ~= 'number' then k = '"'..k..'"' end
			for i = 1, nb, 1 do
				s = s .. "    "
			end
			s = s .. '['..k..'] = ' .. self:dumpTable(v, nb + 1) .. ',\n'
		end

		for i = 1, nb, 1 do
			s = s .. "    "
		end

		return s .. '}'
	else
		return tostring(table)
	end
end