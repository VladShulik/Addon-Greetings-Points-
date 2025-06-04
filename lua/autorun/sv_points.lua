if SERVER then

AddCSLuaFile("cl_points.lua")

local PlayerPoints = PlayerPoints or {}

util.AddNetworkString("RequestPoints")
util.AddNetworkString("PointsResponse")

-- Handle point request from client
net.Receive("RequestPoints", function(len, ply)
    local sid = ply:SteamID()
    PlayerPoints[sid] = (PlayerPoints[sid] or 0) + 10

    local text = "Теперь у вас " .. PlayerPoints[sid] .. " очков"
    net.Start("PointsResponse")
    net.WriteString(text)
    net.Send(ply)
end)

-- Chat command to show points
hook.Add("PlayerSay", "PointsChatCommand", function(ply, text)
    if string.Trim(string.lower(text)) == "!points" then
        local sid = ply:SteamID()
        local points = PlayerPoints[sid] or 0
        ply:ChatPrint("Ваши очки: " .. points)
        return ""
    end
end)

end
