if SERVER then

AddCSLuaFile("autorun/cl_points.lua")

local PlayerPoints = PlayerPoints or {}

local ShopWeapons = {
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

util.AddNetworkString("RequestPoints")
util.AddNetworkString("PointsResponse")
util.AddNetworkString("RequestCurrentPoints")
util.AddNetworkString("SendCurrentPoints")
util.AddNetworkString("PointsShopBuyWeapon")
util.AddNetworkString("PointsShopPurchaseResult")
util.AddNetworkString("PointsAdminRequestPlayers")
util.AddNetworkString("PointsAdminPlayersData")
util.AddNetworkString("PointsAdminAdjustPoints")
util.AddNetworkString("PointsAdminMassAction")

local function GetPoints(ply)
    return PlayerPoints[ply:SteamID()] or 0
end

local function SetPoints(ply, amount)
    PlayerPoints[ply:SteamID()] = math.max(0, math.floor(amount))
end

local function SendCurrentPoints(ply)
    net.Start("SendCurrentPoints")
    net.WriteInt(GetPoints(ply), 32)
    net.Send(ply)
end

local function SendPointsMessage(ply, message)
    net.Start("PointsResponse")
    net.WriteString(message)
    net.Send(ply)
end

local function IsPlayerAdmin(ply)
    return IsValid(ply) and ply:IsPlayer() and ply:IsAdmin()
end

local function FindShopWeapon(class)
    for _, weapon in ipairs(ShopWeapons) do
        if weapon.class == class then
            return weapon
        end
    end

    return nil
end

net.Receive("RequestPoints", function(_, ply)
    SetPoints(ply, GetPoints(ply) + 10)
    SendPointsMessage(ply, "Теперь у вас " .. GetPoints(ply) .. " очков")
    SendCurrentPoints(ply)
end)

net.Receive("RequestCurrentPoints", function(_, ply)
    SendCurrentPoints(ply)
end)

net.Receive("PointsShopBuyWeapon", function(_, ply)
    local weaponClass = net.ReadString()
    local selectedWeapon = FindShopWeapon(weaponClass)

    if not selectedWeapon then
        SendPointsMessage(ply, "Это оружие недоступно в магазине")
        return
    end

    if not weapons.GetStored(selectedWeapon.class) then
        SendPointsMessage(ply, "Оружие " .. selectedWeapon.name .. " отсутствует на сервере")
        return
    end

    if ply:HasWeapon(selectedWeapon.class) then
        SendPointsMessage(ply, "У вас уже есть " .. selectedWeapon.name)
        return
    end

    local points = GetPoints(ply)
    if points < selectedWeapon.price then
        SendPointsMessage(ply, "Недостаточно очков. Нужно: " .. selectedWeapon.price)
        return
    end

    SetPoints(ply, points - selectedWeapon.price)
    ply:Give(selectedWeapon.class)

    if not ply:HasWeapon(selectedWeapon.class) then
        SetPoints(ply, points)
        SendPointsMessage(ply, "Не удалось выдать оружие")
        return
    end

    SendPointsMessage(ply, "Вы купили " .. selectedWeapon.name .. " за " .. selectedWeapon.price .. " очков")

    net.Start("PointsShopPurchaseResult")
    net.WriteBool(true)
    net.WriteString(selectedWeapon.class)
    net.WriteInt(GetPoints(ply), 32)
    net.Send(ply)

    SendCurrentPoints(ply)
end)

net.Receive("PointsAdminRequestPlayers", function(_, ply)
    if not IsPlayerAdmin(ply) then
        SendPointsMessage(ply, "Только администратор может открыть панель")
        return
    end

    local players = player.GetAll()

    net.Start("PointsAdminPlayersData")
    net.WriteUInt(#players, 8)

    for _, target in ipairs(players) do
        net.WriteEntity(target)
        net.WriteString(target:Nick())
        net.WriteString(target:SteamID())
        net.WriteInt(GetPoints(target), 32)
    end

    net.Send(ply)
end)

net.Receive("PointsAdminAdjustPoints", function(_, ply)
    if not IsPlayerAdmin(ply) then
        SendPointsMessage(ply, "Недостаточно прав")
        return
    end

    local target = net.ReadEntity()
    local operation = net.ReadString()
    local amount = math.floor(net.ReadInt(32))

    if not IsValid(target) or not target:IsPlayer() then
        SendPointsMessage(ply, "Игрок не найден")
        return
    end

    if operation ~= "set" and operation ~= "add" then
        SendPointsMessage(ply, "Неизвестная операция")
        return
    end

    if math.abs(amount) > 100000 then
        SendPointsMessage(ply, "Слишком большое значение")
        return
    end

    local oldValue = GetPoints(target)
    if operation == "set" then
        SetPoints(target, amount)
    else
        SetPoints(target, oldValue + amount)
    end

    local newValue = GetPoints(target)
    SendPointsMessage(ply, "Очки игрока " .. target:Nick() .. " изменены: " .. oldValue .. " -> " .. newValue)
    SendPointsMessage(target, "Администратор изменил ваши очки: " .. oldValue .. " -> " .. newValue)

    SendCurrentPoints(target)

    net.Start("PointsAdminPlayersData")
    net.WriteUInt(1, 8)
    net.WriteEntity(target)
    net.WriteString(target:Nick())
    net.WriteString(target:SteamID())
    net.WriteInt(newValue, 32)
    net.Send(ply)
end)


net.Receive("PointsAdminMassAction", function(_, ply)
    if not IsPlayerAdmin(ply) then
        SendPointsMessage(ply, "Недостаточно прав")
        return
    end

    local action = net.ReadString()
    local amount = math.floor(net.ReadInt(32))

    if action ~= "add_all" and action ~= "reset_all" then
        SendPointsMessage(ply, "Неизвестное массовое действие")
        return
    end

    if action == "add_all" and math.abs(amount) > 100000 then
        SendPointsMessage(ply, "Слишком большое значение")
        return
    end

    for _, target in ipairs(player.GetAll()) do
        local oldValue = GetPoints(target)
        if action == "reset_all" then
            SetPoints(target, 0)
            SendPointsMessage(target, "Администратор сбросил ваши очки")
        else
            SetPoints(target, oldValue + amount)
            SendPointsMessage(target, "Администратор изменил ваши очки на " .. amount)
        end

        SendCurrentPoints(target)
    end

    if action == "reset_all" then
        SendPointsMessage(ply, "Очки всех игроков сброшены")
    else
        SendPointsMessage(ply, "Очки всех игроков изменены на " .. amount)
    end
end)

hook.Add("PlayerSay", "PointsChatCommand", function(ply, text)
    local command = string.Trim(string.lower(text))

    if command == "!points" then
        ply:ChatPrint("Ваши очки: " .. GetPoints(ply))
        return ""
    end

    if command == "!shop" then
        ply:ConCommand("points_shop")
        return ""
    end

    if command == "!adminpoints" then
        if not IsPlayerAdmin(ply) then
            ply:ChatPrint("Только для администраторов")
            return ""
        end

        ply:ConCommand("points_admin")
        return ""
    end
end)

end
