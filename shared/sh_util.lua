VyHub.Util = VyHub.Util or {}
VyHub.Util.cancelled_timers = VyHub.Util.cancelled_timers or {}
VyHub.Util.timer_fns = VyHub.Util.timer_fns or {}


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
    return table.concat(args, " ", pos)
end

function VyHub.Util:replace_colors(message)
	message = string.Replace(message, '<red>', '~r~')
	message = string.Replace(message, '</red>', '~w~')
	message = string.Replace(message, '<green>', '~g~')
	message = string.Replace(message, '</green>', '~w~')
	message = string.Replace(message, '<blue>', '~b~')
	message = string.Replace(message, '</blue>', '~w~')
	message = string.Replace(message, '<yellow>', '~y~')
	message = string.Replace(message, '</yellow>', '~w~')
	message = string.Replace(message, '<pink>', '~q~')
	message = string.Replace(message, '</pink>', '~w~')
    message = string.Replace(message, '<orange>', '~o~')
	message = string.Replace(message, '</orange>', '~w~')

	return message
end

function VyHub.Util:print_chat_license(license, message, tag, color)
    local targetSrc = VyHub.Player:get_source(license)
    if(targetSrc) then
        tag = (tag or "[VyHub]")
        color = (color or {255, 0, 0})
        TriggerClientEvent("chat:addMessage", targetSrc, {
            color = color,
            multiline = true,
            args = {tag, VyHub.Util:replace_colors(message)}
        })
    end
end


function VyHub.Util:print_chat_all(message, tag, color)
    tag = (tag or "[VyHub]")
    color = (color or {255, 0, 0})
    TriggerClientEvent("chat:addMessage", -1, {
        color = color,
        multiline = true,
        args = {tag, VyHub.Util:replace_colors(message)}
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
        return {tonumber("0x"..hex:sub(1,1)) * 17, tonumber("0x"..hex:sub(2,2)) * 17, tonumber("0x"..hex:sub(3,3)) * 17}
    elseif(string.len(hex) == 6) then
        return {tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6))}
    else
    	return {255,255,255}
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

function VyHub.Util:timer_loop(delay, callback, name)
    if name then
        VyHub.Util.cancelled_timers[name] = nil
    end

    if name then
        VyHub.Util.timer_fns[name] = callback
    end

    Citizen.CreateThread(function()
        while(true) do
            Citizen.Wait(delay)

            if name and VyHub.Util.cancelled_timers[name] then
                break
            end

            if name then
                VyHub.Util.timer_fns[name]()
            else
                callback()
            end
        end
    end)
end

function VyHub.Util:cancel_timer(name)
    VyHub.Util.cancelled_timers[name] = true
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

function VyHub.Util:string_split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end
