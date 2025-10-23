-- luacheck: globals SERVER AddCSLuaFile util net hook timer PlayerPoints PlayerHistory IsValid

if SERVER then

AddCSLuaFile("cl_points.lua")

local PlayerPoints = PlayerPoints or {}
local PlayerHistory = PlayerHistory or {}

util.AddNetworkString("RequestPoints")
util.AddNetworkString("RequestPointsSync")
util.AddNetworkString("PointsResponse")
util.AddNetworkString("PointsSync")

local function SendPointsSync(ply)
    if not IsValid(ply) then return end

    local sid = ply:SteamID()
    local points = PlayerPoints[sid] or 0
    local history = PlayerHistory[sid] or {}

    net.Start("PointsSync")
    net.WriteUInt(points, 32)
    net.WriteUInt(#history, 16)
    for _, entry in ipairs(history) do
        net.WriteUInt(entry.time or 0, 32)
        net.WriteInt(entry.amount or 0, 32)
        net.WriteString(entry.reason or "")
    end
    net.Send(ply)
end

local function AddHistoryEntry(ply, amount, reason)
    local sid = ply:SteamID()
    PlayerHistory[sid] = PlayerHistory[sid] or {}

    table.insert(PlayerHistory[sid], 1, {
        time = os.time(),
        amount = amount,
        reason = reason
    })

    local maxEntries = 50
    if #PlayerHistory[sid] > maxEntries then
        for i = #PlayerHistory[sid], maxEntries + 1, -1 do
            PlayerHistory[sid][i] = nil
        end
    end
end

-- Handle point request from client
net.Receive("RequestPoints", function(_, ply)
    local sid = ply:SteamID()
    local rewardAmount = 10
    PlayerPoints[sid] = (PlayerPoints[sid] or 0) + rewardAmount

    AddHistoryEntry(ply, rewardAmount, "reason_menu_reward")

    net.Start("PointsResponse")
    net.WriteInt(rewardAmount, 32)
    net.WriteUInt(PlayerPoints[sid], 32)
    net.Send(ply)

    SendPointsSync(ply)
end)

net.Receive("RequestPointsSync", function(_, ply)
    SendPointsSync(ply)
end)

-- Chat command to show points
hook.Add("PlayerSay", "PointsChatCommand", function(ply, text)
    local normalized = string.lower(text or "")
    normalized = normalized:gsub("^%s+", ""):gsub("%s+$", "")

    if normalized == "!points" then
        local sid = ply:SteamID()
        local points = PlayerPoints[sid] or 0
        ply:ChatPrint("Ваши очки: " .. points)
        SendPointsSync(ply)
        return ""
    end
end)

hook.Add("PlayerInitialSpawn", "Points_SendInitialSync", function(ply)
    timer.Simple(1, function()
        if IsValid(ply) then
            SendPointsSync(ply)
        end
    end)
end)

hook.Add("PlayerDisconnected", "Points_Cleanup", function(ply)
    local sid = ply:SteamID()
    PlayerPoints[sid] = nil
    PlayerHistory[sid] = nil
end)

end
