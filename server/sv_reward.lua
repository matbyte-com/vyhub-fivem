VyHub.Reward = VyHub.Reward or {}
VyHub.Reward.executed_rewards_queue = VyHub.Reward.executed_rewards_queue or {}
VyHub.Reward.executed_rewards = VyHub.Reward.executed_rewards or {}
VyHub.rewards = VyHub.rewards or {}

local RewardEvent = {
    DIRECT = "DIRECT",
    CONNECT = "CONNECT",
    SPAWN = "SPAWN",
    DEATH = "DEATH",
    DISCONNECT = "DISCONNECT",
    DISABLE = "DISABLE"
}

local RewardType = {
    COMMAND = "COMMAND",
    SCRIPT = "SCRIPT",
    CREDITS = "CREDITS",
    MEMBERSHIP = "MEMBERSHIP"
}

function VyHub.Reward:refresh(callback, limit_players, err)
    local user_ids = ""
    local players = limit_players or GetPlayers()

    for i, ply in pairs(players) do
        local plyLicense = VyHub.Player:get_license(ply)
        VyHub.Player:get(plyLicense, function(user)
            if (not user) then
                VyHub:msg(f("Could not check rewards for user %s, because no VyHub id is available.", plyLicense), "debug")
                return
            end
            local id = user.id

            if id and string.len(id) == 36 then
                local glue = '&'

                if user_ids == "" then
                    glue = '?'
                end

                user_ids = user_ids .. glue .. 'user_id=' .. id
            end
        end)
    end

    if user_ids == "" then
        VyHub.rewards = {}
    else
        local query = f("%s&active=true&serverbundle_id=%s&status=OPEN&foreign_ids=true", user_ids, VyHub.server.serverbundle.id)

        VyHub.API:get('/packet/reward/applied/user' .. query, nil, nil, function(code, result)
            if limit_players == nil then
                VyHub.rewards = result
                VyHub:msg(f("Found %i users with open rewards.", #result), "debug")
            else
                for license, arewards in pairs(result) do
                    VyHub.rewards[license] = arewards
                end
            end

            if callback then
                callback()
            end
        end, function(code, reason)
            if err then
                err()
            end
        end)
    end
end

function VyHub.Reward:set_executed(areward_id)
    VyHub.Reward.executed_rewards_queue[areward_id] = true
    table.insert(VyHub.Reward.executed_rewards, areward_id)

    VyHub.Reward:save_executed()
end

function VyHub.Reward:save_executed()
    VyHub.Cache:save("executed_rewards_queue", VyHub.Reward.executed_rewards_queue)
end

function VyHub.Reward:send_executed()
    for areward_id, val in pairs(VyHub.Reward.executed_rewards_queue) do
        if val ~= nil then
            VyHub.API:patch('/packet/reward/applied/%s', {areward_id}, {
                executed_on = {VyHub.server.id}
            }, function(code, result)
                VyHub.Reward.executed_rewards_queue[areward_id] = nil
                VyHub.Reward:save_executed()
            end, function(code, reason)
                if code >= 400 and code < 500 then
                    VyHub:msg(f("Could not mark reward %s as executed. Aborting.", areward_id), "error")
                    VyHub.Reward.executed_rewards_queue[areward_id] = nil
                    VyHub.Reward:save_executed()
                end
            end)
        end
    end
end

function VyHub.Reward:exec_rewards(event, license)
    license = license or nil

    local allowed_events = {event}

    local rewards_by_player = VyHub.rewards

    if license ~= nil then
        rewards_by_player = {}
        rewards_by_player[license] = VyHub.rewards[license]
    else
        if event ~= RewardEvent.DIRECT then
            return
        end
    end

    if event == RewardEvent.DIRECT then
        table.insert(allowed_events, RewardEvent.DISABLE)
    end

    for license, arewards in pairs(rewards_by_player) do
        for _, areward in pairs(arewards) do
            local se = true
            local reward = areward.reward

            if table.HasValue(allowed_events, reward.on_event) then

                if table.HasValue(VyHub.Reward.executed_rewards, areward.id) then
                    VyHub:msg(f("Skipped reward %s, because it already has been executed.", areward.id), "debug")
                else
                    local data = reward.data

                    if reward.type == RewardType.COMMAND then
                        if data.command ~= nil then
                            local cmd = VyHub.Reward:do_string_replacements(data.command, license, areward)
                            ExecuteCommand(cmd)
                        end
                    elseif reward.type == RewardType.SCRIPT then
                        local lua_str = data.script

                        if lua_str ~= nil then
                            lua_str = VyHub.Reward:do_string_replacements(lua_str, license, areward)
                            assert(load(lua_str))()
                        end
                    else
                        VyHub:msg(f("No implementation for reward type %s", reward.type) "warning")
                    end

                    VyHub:msg(f("Executed reward %s for user %s: %s", reward.type, license, json.encode(data)))

                    if se and reward.once then
                        VyHub.Reward:set_executed(areward.id)
                    end
                end
            end

        end
    end

    VyHub.Reward:send_executed()
end

function VyHub.Reward:do_string_replacements(inp_str, license, areward)
    local purchase_amount = "-"

    if areward.applied_packet.purchase ~= nil then
        purchase_amount = areward.applied_packet.purchase.amount_text
    end

    local playerSource = VyHub.Player:get_source(license)

    local char_name = VyHub.Framework:getPlayerCharName(playerSource)

    if not char_name then
        char_name = '-'
    end

    local steam_id = VyHub.Player:get_steamid(playerSource)

    if not steam_id then
        steam_id = '-'
    end

    local replacements = {
        ["id"] = playerSource,
        ["user_id"] = areward.user.id,
        ["nick"] = GetPlayerName(playerSource),
        ["license"] = license,
        ["char_name"] = char_name,
        ["steam_id"] = steam_id,
        ["applied_packet_id"] = areward.applied_packet_id,
        ["packet_title"] = areward.applied_packet.packet.title,
        ["purchase_amount"] = purchase_amount
    }

    for k, v in pairs(replacements) do
        inp_str = string.Replace(tostring(inp_str), "%%" .. tostring(k) .. "%%", tostring(v))
    end

    return inp_str
end

AddEventHandler("vyhub_ready", function()
    VyHub.Reward.executed_rewards_queue = VyHub.Cache:get("executed_rewards_queue") or {}

    VyHub.Reward:refresh(function()
        VyHub.Reward:exec_rewards(RewardEvent.DIRECT)
    end)

    VyHub.Util:timer_loop(60000, function()
        VyHub.Reward:refresh(function()
            VyHub.Reward:exec_rewards(RewardEvent.DIRECT)
        end)
    end)

    AddEventHandler("vyhub_ply_initialized", function(ply)
        local function exec_ply_rewards()
            VyHub.Reward:exec_rewards(RewardEvent.CONNECT, VyHub.Player:get_license(ply))
            TriggerEvent("vyhub_reward_post_connect", ply)
        end

        VyHub.Reward:refresh(exec_ply_rewards, {ply})
    end)

    RegisterNetEvent("vyhub-fivem:playerSpawned", function()
        VyHub.Reward:exec_rewards(RewardEvent.SPAWN, VyHub.Player:get_license(source))
    end)

    RegisterNetEvent("vyhub-fivem:onPlayerDeath", function(data)
        local playerLicense = VyHub.Player:get_license(source)
        VyHub.Reward:exec_rewards(RewardEvent.DEATH, playerLicense)
    end)
end)
