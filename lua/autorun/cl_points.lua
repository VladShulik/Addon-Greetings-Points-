-- luacheck: globals CLIENT GetConVarString net chat Color KEY_F6 IsValid vgui
-- luacheck: globals FILL TOP BOTTOM LEFT RIGHT surface concommand hook
-- luacheck: globals LocalPlayer gui spawnmenu notification NOTIFY_HINT

if CLIENT then
    local LANG = {
        en = {
            frame_title = "Points",
            points_label = "Current points: %d",
            history_time = "Time",
            history_delta = "Delta",
            history_reason = "Reason",
            button_get_points = "Get 10 points",
            button_refresh = "Refresh",
            button_close = "Close",
            menu_open_button = "Open points panel",
            menu_hint = "Opens the points overview and history panel.",
            welcome_message = "Welcome! Press F6 or use 'points_menu' to open the points panel.",
            reason_menu_reward = "Menu reward",
            chat_points_awarded = "You received %d points. Total: %d.",
            chat_points_removed = "%d points were removed. Total: %d.",
            chat_points_total = "You now have %d points."
        },
        ru = {
            frame_title = "Очки",
            points_label = "Текущие очки: %d",
            history_time = "Время",
            history_delta = "Изменение",
            history_reason = "Причина",
            button_get_points = "Получить 10 очков",
            button_refresh = "Обновить",
            button_close = "Закрыть",
            menu_open_button = "Открыть меню очков",
            menu_hint = "Открывает панель очков и истории выдач.",
            welcome_message = "Добро пожаловать! Нажмите F6 или команду 'points_menu', чтобы открыть меню очков.",
            reason_menu_reward = "Награда из меню",
            chat_points_awarded = "Вы получили %d очков. Всего: %d.",
            chat_points_removed = "У вас забрали %d очков. Всего: %d.",
            chat_points_total = "Теперь у вас %d очков."
        }
    }

    local function getActiveLanguage()
        local lang = string.lower(GetConVarString("gmod_language") or "")
        if LANG[lang] then
            return lang
        end
        return "en"
    end

    local function T(key)
        local lang = getActiveLanguage()
        local langTable = LANG[lang] or LANG.en
        return (langTable and langTable[key]) or (LANG.en and LANG.en[key]) or key
    end

    net.Receive("PointsResponse", function()
        local delta = net.ReadInt(32)
        local total = net.ReadUInt(32)
        local message

        if delta > 0 then
            message = string.format(T("chat_points_awarded"), delta, total)
        elseif delta < 0 then
            message = string.format(T("chat_points_removed"), math.abs(delta), total)
        else
            message = string.format(T("chat_points_total"), total)
        end

        chat.AddText(Color(0, 255, 0), message)
    end)

    local currentPoints = 0
    local pointsHistory = {}
    local PointsUI = {
        frame = nil,
        list = nil,
        pointsLabel = nil
    }

    local hasShownWelcome = false
    local toggleKey = KEY_F6

    local function formatDelta(amount)
        if amount >= 0 then
            return "+" .. amount
        end
        return tostring(amount)
    end

    local function RequestPointsSync()
        net.Start("RequestPointsSync")
        net.SendToServer()
    end

    local function UpdatePointsUI()
        if not IsValid(PointsUI.frame) then return end

        if IsValid(PointsUI.pointsLabel) then
            PointsUI.pointsLabel:SetText(string.format(T("points_label"), currentPoints))
            PointsUI.pointsLabel:SizeToContents()
        end

        if IsValid(PointsUI.list) then
            PointsUI.list:Clear()
            for _, entry in ipairs(pointsHistory) do
                local timestamp = entry.time or 0
                local timeText = timestamp > 0 and os.date("%H:%M:%S", timestamp) or "-"
                local reasonText = T(entry.reason or "")
                PointsUI.list:AddLine(timeText, formatDelta(entry.amount or 0), reasonText)
            end
        end
    end

    local function EnsurePointsMenu()
        if IsValid(PointsUI.frame) then
            PointsUI.frame:SetVisible(true)
            PointsUI.frame:MakePopup()
            PointsUI.frame:MoveToFront()
            return PointsUI.frame
        end

        local frame = vgui.Create("DFrame")
        frame:SetSize(420, 320)
        frame:Center()
        frame:SetTitle(T("frame_title"))
        frame:MakePopup()
        frame.OnClose = function()
            PointsUI.frame = nil
        end

        local content = vgui.Create("DPanel", frame)
        content:Dock(FILL)
        content:DockPadding(8, 8, 8, 8)
        function content.Paint(_, w, h)
            surface.SetDrawColor(20, 20, 20, 220)
            surface.DrawRect(0, 0, w, h)
        end

        local pointsLabel = vgui.Create("DLabel", content)
        pointsLabel:Dock(TOP)
        pointsLabel:SetFont("Trebuchet24")
        pointsLabel:SetTextColor(Color(255, 255, 255))
        pointsLabel:SetText(string.format(T("points_label"), currentPoints))
        pointsLabel:SizeToContents()
        pointsLabel:DockMargin(0, 0, 0, 8)

        local list = vgui.Create("DListView", content)
        list:Dock(FILL)
        list:SetMultiSelect(false)
        list:AddColumn(T("history_time"))
        list:AddColumn(T("history_delta"))
        list:AddColumn(T("history_reason"))

        local buttonBar = vgui.Create("DPanel", content)
        buttonBar:Dock(BOTTOM)
        buttonBar:SetTall(32)
        buttonBar:DockMargin(0, 8, 0, 0)
        function buttonBar.Paint() end

        local getButton = vgui.Create("DButton", buttonBar)
        getButton:Dock(LEFT)
        getButton:SetWide(150)
        getButton:SetText(T("button_get_points"))
        function getButton.DoClick(_)
            net.Start("RequestPoints")
            net.SendToServer()
        end

        local refreshButton = vgui.Create("DButton", buttonBar)
        refreshButton:Dock(LEFT)
        refreshButton:DockMargin(8, 0, 0, 0)
        refreshButton:SetWide(120)
        refreshButton:SetText(T("button_refresh"))
        function refreshButton.DoClick(_)
            RequestPointsSync()
        end

        local closeButton = vgui.Create("DButton", buttonBar)
        closeButton:Dock(RIGHT)
        closeButton:SetWide(90)
        closeButton:SetText(T("button_close"))
        function closeButton.DoClick(_)
            frame:Close()
        end

        PointsUI.frame = frame
        PointsUI.list = list
        PointsUI.pointsLabel = pointsLabel

        UpdatePointsUI()

        return frame
    end

    local function TogglePointsMenu()
        if not IsValid(PointsUI.frame) then
            EnsurePointsMenu()
            RequestPointsSync()
            return
        end

        local frame = PointsUI.frame
        local visible = frame:IsVisible()
        frame:SetVisible(not visible)

        if frame:IsVisible() then
            frame:MakePopup()
            frame:MoveToFront()
            RequestPointsSync()
        end
    end

    concommand.Add("points_menu", function()
        TogglePointsMenu()
    end)

    hook.Add("PlayerButtonDown", "Points_OpenMenuKey", function(ply, key)
        if ply ~= LocalPlayer() then return end
        if vgui.CursorVisible() then return end
        if gui.IsGameUIVisible() then return end
        if key == toggleKey then
            TogglePointsMenu()
        end
    end)

    hook.Add("PopulateToolMenu", "Points_AddUtilitiesMenu", function()
        if not spawnmenu then return end
        spawnmenu.AddToolMenuOption("Utilities", "User", "PointsMenu", T("frame_title"), "", "", function(panel)
            panel:Button(T("menu_open_button"), "points_menu")
            panel:Help(T("menu_hint"))
        end)
    end)

    hook.Add("InitPostEntity", "Points_WelcomeMessage", function()
        if hasShownWelcome then return end
        hasShownWelcome = true
        notification.AddLegacy(T("welcome_message"), NOTIFY_HINT, 5)
        surface.PlaySound("buttons/button15.wav")
    end)

    net.Receive("PointsSync", function()
        currentPoints = net.ReadUInt(32)
        local count = net.ReadUInt(16)
        pointsHistory = {}
        for _ = 1, count do
            local timestamp = net.ReadUInt(32)
            local delta = net.ReadInt(32)
            local reason = net.ReadString()
            pointsHistory[#pointsHistory + 1] = {
                time = timestamp,
                amount = delta,
                reason = reason
            }
        end
        UpdatePointsUI()
    end)
end
