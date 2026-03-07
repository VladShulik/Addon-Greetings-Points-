if CLIENT then

local SHOP_WEAPONS = {
    { class = "weapon_crowbar", name = "Crowbar", price = 25 },
    { class = "weapon_stunstick", name = "Stunstick", price = 35 },
    { class = "weapon_pistol", name = "Pistol", price = 45 },
    { class = "weapon_357", name = "357 Magnum", price = 80 },
    { class = "weapon_smg1", name = "SMG", price = 90 },
    { class = "weapon_ar2", name = "AR2", price = 120 },
    { class = "weapon_shotgun", name = "Shotgun", price = 110 },
    { class = "weapon_crossbow", name = "Crossbow", price = 150 },
    { class = "weapon_frag", name = "Grenade", price = 70 },
    { class = "weapon_rpg", name = "RPG", price = 250 }
}

local pointsLabel
local cachedPoints = 0
local adminScroll
local adminFrame

net.Receive("PointsResponse", function()
    local msg = net.ReadString()
    chat.AddText(Color(0, 255, 0), msg)
end)

net.Receive("SendCurrentPoints", function()
    cachedPoints = net.ReadInt(32)

    if IsValid(pointsLabel) then
        pointsLabel:SetText("Ваши очки: " .. cachedPoints)
    else
        chat.AddText(Color(0, 255, 0), "Ваши очки: " .. cachedPoints)
    end
end)

net.Receive("PointsShopPurchaseResult", function()
    local success = net.ReadBool()
    local _ = net.ReadString()
    local newPoints = net.ReadInt(32)

    if success then
        cachedPoints = newPoints
        if IsValid(pointsLabel) then
            pointsLabel:SetText("Ваши очки: " .. cachedPoints)
        end
    end
end)

local function RequestCurrentPoints()
    net.Start("RequestCurrentPoints")
    net.SendToServer()
end

local function ShowPointsPopup()
    local frame = vgui.Create("DFrame")
    frame:SetSize(300, 110)
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
    frame:SetSize(260, 100)
    frame:Center()
    frame:SetTitle("Мои очки")
    frame:MakePopup()

    pointsLabel = vgui.Create("DLabel", frame)
    pointsLabel:Dock(FILL)
    pointsLabel:SetContentAlignment(5)
    pointsLabel:SetText("Загрузка...")

    RequestCurrentPoints()
end

local function ShowShopMenu()
    local frame = vgui.Create("DFrame")
    frame:SetSize(400, 440)
    frame:Center()
    frame:SetTitle("Магазин оружия")
    frame:MakePopup()

    local topPanel = vgui.Create("DPanel", frame)
    topPanel:Dock(TOP)
    topPanel:SetTall(35)

    local pointsInfo = vgui.Create("DLabel", topPanel)
    pointsInfo:Dock(FILL)
    pointsInfo:SetContentAlignment(5)
    pointsInfo:SetText("Ваши очки: " .. cachedPoints)

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)

    for _, weapon in ipairs(SHOP_WEAPONS) do
        local row = vgui.Create("DPanel", scroll)
        row:Dock(TOP)
        row:DockMargin(5, 5, 5, 0)
        row:SetTall(40)

        local label = vgui.Create("DLabel", row)
        label:Dock(LEFT)
        label:SetWide(220)
        label:SetText("  " .. weapon.name .. " (" .. weapon.class .. ")")

        local priceLabel = vgui.Create("DLabel", row)
        priceLabel:Dock(LEFT)
        priceLabel:SetWide(70)
        priceLabel:SetContentAlignment(5)
        priceLabel:SetText(weapon.price .. " очк.")

        local buyButton = vgui.Create("DButton", row)
        buyButton:Dock(FILL)
        buyButton:SetText("Купить")

        function buyButton:DoClick()
            net.Start("PointsShopBuyWeapon")
            net.WriteString(weapon.class)
            net.SendToServer()

            timer.Simple(0.15, function()
                pointsInfo:SetText("Ваши очки: " .. cachedPoints)
            end)
        end
    end

    RequestCurrentPoints()
    local timerName = "PointsShopRefreshLabel" .. frame:EntIndex()
    timer.Create(timerName, 0.25, 0, function()
        if not IsValid(frame) then
            timer.Remove(timerName)
            return
        end

        pointsInfo:SetText("Ваши очки: " .. cachedPoints)
    end)
end

local function BuildAdminPlayerRow(parent, data, refreshFn)
    local row = vgui.Create("DPanel", parent)
    row:Dock(TOP)
    row:DockMargin(5, 5, 5, 0)
    row:SetTall(66)

    local infoLabel = vgui.Create("DLabel", row)
    infoLabel:Dock(LEFT)
    infoLabel:SetWide(240)
    infoLabel:SetText("  " .. data.name .. "\n  " .. data.steamid .. " | Очки: " .. data.points)

    local entry = vgui.Create("DTextEntry", row)
    entry:Dock(LEFT)
    entry:SetWide(70)
    entry:SetNumeric(true)
    entry:SetText("10")

    local addBtn = vgui.Create("DButton", row)
    addBtn:Dock(LEFT)
    addBtn:SetWide(45)
    addBtn:SetText("+")
    function addBtn:DoClick()
        net.Start("PointsAdminAdjustPoints")
        net.WriteEntity(data.entity)
        net.WriteString("add")
        net.WriteInt(tonumber(entry:GetValue()) or 0, 32)
        net.SendToServer()
        timer.Simple(0.15, refreshFn)
    end

    local subBtn = vgui.Create("DButton", row)
    subBtn:Dock(LEFT)
    subBtn:SetWide(45)
    subBtn:SetText("-")
    function subBtn:DoClick()
        net.Start("PointsAdminAdjustPoints")
        net.WriteEntity(data.entity)
        net.WriteString("add")
        net.WriteInt(-(tonumber(entry:GetValue()) or 0), 32)
        net.SendToServer()
        timer.Simple(0.15, refreshFn)
    end

    local setBtn = vgui.Create("DButton", row)
    setBtn:Dock(FILL)
    setBtn:SetText("Set")
    function setBtn:DoClick()
        net.Start("PointsAdminAdjustPoints")
        net.WriteEntity(data.entity)
        net.WriteString("set")
        net.WriteInt(tonumber(entry:GetValue()) or 0, 32)
        net.SendToServer()
        timer.Simple(0.15, refreshFn)
    end
end

local function ShowAdminMenu()
    if not LocalPlayer():IsAdmin() then
        chat.AddText(Color(255, 0, 0), "Только для администраторов")
        return
    end

    local frame = vgui.Create("DFrame")
    frame:SetSize(560, 500)
    frame:Center()
    frame:SetTitle("Админ панель очков")
    frame:MakePopup()

    local refreshBtn = vgui.Create("DButton", frame)
    refreshBtn:Dock(TOP)
    refreshBtn:SetTall(32)
    refreshBtn:SetText("Обновить список")

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    adminFrame = frame
    adminScroll = scroll

    local function requestList()
        net.Start("PointsAdminRequestPlayers")
        net.SendToServer()
    end

    function refreshBtn:DoClick()
        requestList()
    end

    requestList()
end

net.Receive("PointsAdminPlayersData", function()
    if not IsValid(adminFrame) or not IsValid(adminScroll) then
        return
    end

    adminScroll:Clear()
    local amount = net.ReadUInt(8)

    for _index = 1, amount do
        local entity = net.ReadEntity()
        local name = net.ReadString()
        local steamid = net.ReadString()
        local points = net.ReadInt(32)

        BuildAdminPlayerRow(adminScroll, {
            entity = entity,
            name = name,
            steamid = steamid,
            points = points
        }, function()
            net.Start("PointsAdminRequestPlayers")
            net.SendToServer()
        end)
    end
end)

concommand.Add("points_menu", ShowPointsMenu)
concommand.Add("points_shop", ShowShopMenu)
concommand.Add("points_admin", ShowAdminMenu)

hook.Add("InitPostEntity", "Points_ShowPopup", ShowPointsPopup)
hook.Add("PlayerSpawn", "Points_ShowPopup_Spawn", function(ply)
    if ply == LocalPlayer() then
        ShowPointsPopup()
    end
end)

end
