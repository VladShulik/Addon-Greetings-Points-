if CLIENT then

-- Display message from server about points
net.Receive("PointsResponse", function()
    local msg = net.ReadString()
    chat.AddText(Color(0, 255, 0), msg)
end)

local pointsLabel

net.Receive("SendCurrentPoints", function()
    local points = net.ReadInt(32)
    if IsValid(pointsLabel) then
        pointsLabel:SetText("Ваши очки: " .. points)
    else
        chat.AddText(Color(0, 255, 0), "Ваши очки: " .. points)
    end
end)

local function ShowPointsPopup()
    local frame = vgui.Create("DFrame")
    frame:SetSize(250, 100)
    frame:Center()
    frame:SetTitle("Получить очки")
    frame:MakePopup()

    local button = vgui.Create("DButton", frame)
    button:Dock(FILL)
    button:SetText("Получить 10 очков")
    function button:DoClick()
        net.Start("RequestPoints")
        net.SendToServer()
        frame:Close()
    end
end

local function ShowPointsMenu()
    local frame = vgui.Create("DFrame")
    frame:SetSize(200, 80)
    frame:Center()
    frame:SetTitle("Мои очки")
    frame:MakePopup()

    pointsLabel = vgui.Create("DLabel", frame)
    pointsLabel:Dock(FILL)
    pointsLabel:SetContentAlignment(5)
    pointsLabel:SetText("Загрузка...")

    net.Start("RequestCurrentPoints")
    net.SendToServer()
end

concommand.Add("points_menu", ShowPointsMenu)

-- Show popup when the local player spawns
hook.Add("InitPostEntity", "Points_ShowPopup", ShowPointsPopup)
hook.Add("PlayerSpawn", "Points_ShowPopup_Spawn", function(ply)
    if ply == LocalPlayer() then
        ShowPointsPopup()
    end
end)

end
