--// ==================== СЕРВИСЫ ====================
local Players              = game:GetService("Players")
local RunService           = game:GetService("RunService")
local UserInputService     = game:GetService("UserInputService")
local TweenService         = game:GetService("TweenService")
local HttpService          = game:GetService("HttpService")
local Workspace            = game:GetService("Workspace")
local ReplicatedStorage    = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local TextChatService      = game:GetService("TextChatService")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

--// ==================== НАСТРОЙКИ ====================
_G.CheatActive   = true
_G.TargetPart    = "HumanoidRootPart"
_G.FOV_Radius    = 60
_G.ShowFOV       = true
_G.RainbowFOV    = false
_G.ESP_Enabled   = false
_G.ESP_Names     = true
_G.ESP_Tracers   = false
_G.ESP_Distance  = true
_G.Player_FOV    = 120
_G.AimbotEnabled = false

local MenuKey = Enum.KeyCode.RightShift
local AimKey  = Enum.KeyCode.Q

local Connections   = {}
local ESP_Objects   = {}
local LastFOVUpdate = 0

--// ==================== UNLOAD ====================
local function Unload()
    _G.CheatActive = false
    _G.ShowFOV = false

    local gui = game.CoreGui:FindFirstChild("DllHub")
    if gui then gui:Destroy() end

    for _, obj in pairs(ESP_Objects) do
        for _, d in pairs(obj) do
            if typeof(d) == "Instance" then pcall(function() d:Destroy() end)
            elseif d.Remove then pcall(function() d:Remove() end) end
        end
    end
    ESP_Objects = {}

    for _, c in pairs(Connections) do
        pcall(function() c:Disconnect() end)
    end
    Connections = {}

    if Camera then Camera.FieldOfView = 70 end
    if FOVCircle and FOVCircle.Remove then pcall(function() FOVCircle:Remove() end) end
end

--// ==================== FOV CIRCLE ====================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.Filled = false
FOVCircle.Transparency = 1
FOVCircle.Visible = false

--// ==================== GUI ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DllHub"
ScreenGui.IgnoreGuiInset = true
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 550, 0, 450)
MainFrame.Position = UDim2.new(0.5, -275, 0.5, -225)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 20)

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 45)
Header.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
Header.Parent = MainFrame
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 20)

local HeaderFix = Instance.new("Frame")
HeaderFix.Size = UDim2.new(1, 0, 0, 10)
HeaderFix.Position = UDim2.new(0, 0, 1, -10)
HeaderFix.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
HeaderFix.BorderSizePixel = 0
HeaderFix.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "Dll hub | universal"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = Header

local dragging, dragStart, startPos
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)
Header.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
Connections.drag = UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                       startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 130, 1, -70)
Sidebar.Position = UDim2.new(0, 15, 0, 55)
Sidebar.BackgroundTransparency = 1
Sidebar.Parent = MainFrame
Instance.new("UIListLayout", Sidebar).Padding = UDim.new(0, 8)

local PageHolder = Instance.new("Frame")
PageHolder.Size = UDim2.new(1, -170, 1, -80)
PageHolder.Position = UDim2.new(0, 155, 0, 60)
PageHolder.BackgroundTransparency = 1
PageHolder.Parent = MainFrame

local function CreatePage()
    local F = Instance.new("ScrollingFrame")
    F.Size = UDim2.new(1, 0, 1, 0)
    F.BackgroundTransparency = 1
    F.Visible = false
    F.ScrollBarThickness = 0
    F.Parent = PageHolder
    Instance.new("UIListLayout", F).Padding = UDim.new(0, 10)
    return F
end

local AimPage  = CreatePage()
local VisPage  = CreatePage()
local ViewPage = CreatePage()
local MorePage = CreatePage()

local function AddTab(name, page)
    local T = Instance.new("TextButton")
    T.Size = UDim2.new(1, 0, 0, 35)
    T.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    T.Text = name
    T.TextColor3 = Color3.new(1, 1, 1)
    T.Font = Enum.Font.GothamBold
    T.TextSize = 12
    T.Parent = Sidebar
    Instance.new("UICorner", T).CornerRadius = UDim.new(0, 10)
    T.MouseButton1Click:Connect(function()
        for _, p in ipairs(PageHolder:GetChildren()) do p.Visible = false end
        page.Visible = true
    end)
end

local function AddToggle(name, parent, default, callback)
    local T = Instance.new("TextButton")
    T.Size = UDim2.new(1, -5, 0, 40)
    T.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    T.Text = "  " .. name
    T.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    T.Font = Enum.Font.Gotham
    T.TextXAlignment = Enum.TextXAlignment.Left
    T.Parent = parent
    Instance.new("UICorner", T).CornerRadius = UDim.new(0, 10)

    local Ind = Instance.new("Frame")
    Ind.Size = UDim2.new(0, 12, 0, 12)
    Ind.Position = UDim2.new(1, -25, 0.5, -6)
    Ind.BackgroundColor3 = default and Color3.new(0, 1, 0.5) or Color3.new(1, 0, 0)
    Ind.Parent = T
    Instance.new("UICorner", Ind).CornerRadius = UDim.new(1, 0)

    local s = default
    T.MouseButton1Click:Connect(function()
        s = not s
        callback(s)
        TweenService:Create(Ind, TweenInfo.new(0.25),
            {BackgroundColor3 = s and Color3.new(0, 1, 0.5) or Color3.new(1, 0, 0)}):Play()
    end)
end

local function AddSlider(name, min, max, default, parent, callback)
    local F = Instance.new("Frame")
    F.Size = UDim2.new(1, -5, 0, 55)
    F.BackgroundTransparency = 1
    F.Parent = parent

    local L = Instance.new("TextLabel")
    L.Text = name .. ": " .. default
    L.Size = UDim2.new(1, 0, 0, 20)
    L.TextColor3 = Color3.new(1, 1, 1)
    L.Font = Enum.Font.Gotham
    L.BackgroundTransparency = 1
    L.TextXAlignment = Enum.TextXAlignment.Left
    L.Parent = F

    local Bg = Instance.new("Frame")
    Bg.Size = UDim2.new(1, -20, 0, 6)
    Bg.Position = UDim2.new(0, 10, 0, 35)
    Bg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    Bg.Parent = F
    Instance.new("UICorner", Bg)

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(120, 100, 255)
    Fill.Parent = Bg
    Instance.new("UICorner", Fill)

    local ds = false
    local function updateSlider()
        local mouseX = UserInputService:GetMouseLocation().X
        local move = math.clamp((mouseX - Bg.AbsolutePosition.X) / math.max(Bg.AbsoluteSize.X, 1), 0, 1)
        Fill.Size = UDim2.new(move, 0, 1, 0)
        local val = math.floor(min + (max - min) * move)
        L.Text = name .. ": " .. val
        callback(val)
    end

    Bg.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            ds = true
            updateSlider()
        end
    end)

    Connections["sliderMove"] = Connections["sliderMove"] or UserInputService.InputChanged:Connect(function(i)
        if not ds then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch then
            updateSlider()
        end
    end)

    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            ds = false
        end
    end)
end

--// ==================== ESP ====================
local function CreateESP(p)
    if ESP_Objects[p] then return end
    local o = {
        Box = Drawing.new("Square"),
        Out = Drawing.new("Square"),
        HBg = Drawing.new("Square"),
        HBar = Drawing.new("Square"),
        D = Drawing.new("Text"),
        N = Drawing.new("Text"),
        T = Drawing.new("Line"),
        Visible = false,
    }
    o.Box.Thickness = 1.5
    o.Out.Thickness = 3
    o.Out.Color = Color3.new(0, 0, 0)
    o.HBg.Filled = true
    o.HBg.Color = Color3.new(0, 0, 0)
    o.HBar.Filled = true
    o.D.Size = 14; o.D.Center = true; o.D.Outline = true
    o.N.Size = 14; o.N.Center = true; o.N.Outline = true
    o.T.Thickness = 1; o.T.Transparency = 0.6
    ESP_Objects[p] = o
end

local function HideESP(o)
    if not o.Visible then return end
    o.Visible = false
    for k, d in pairs(o) do
        if k ~= "Visible" and d.Visible then d.Visible = false end
    end
end

local function RemoveESP(p)
    local o = ESP_Objects[p]
    if not o then return end
    for k, d in pairs(o) do
        if k ~= "Visible" then pcall(function() d:Remove() end) end
    end
    ESP_Objects[p] = nil
end

--// ==================== ОСНОВНОЙ ЦИКЛ ====================
Connections.main = RunService.RenderStepped:Connect(function(dt)
    if not _G.CheatActive then return end

    if _G.ShowFOV then
        if not FOVCircle.Visible then FOVCircle.Visible = true end
        local now = os.clock()
        if now - LastFOVUpdate > 0.033 then
            LastFOVUpdate = now
            local vp = Camera.ViewportSize
            FOVCircle.Radius = _G.FOV_Radius
            FOVCircle.Position = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
            FOVCircle.Color = _G.RainbowFOV and Color3.fromHSV(tick() % 5 / 5, 1, 1) or Color3.new(1, 1, 1)
        end
    elseif FOVCircle.Visible then
        FOVCircle.Visible = false
    end

    if Camera.FieldOfView ~= _G.Player_FOV then
        Camera.FieldOfView = _G.Player_FOV
    end

    --// AIMBOT
    if _G.AimbotEnabled and UserInputService:IsKeyDown(AimKey) then
        local best, bestDist = nil, _G.FOV_Radius
        local center = Vector2.new(Camera.ViewportSize.X * 0.5, Camera.ViewportSize.Y * 0.5)
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local char = p.Character
                if char then
                    local part = char:FindFirstChild(_G.TargetPart)
                    local hum  = char:FindFirstChildOfClass("Humanoid")
                    if part and hum and hum.Health > 0 then
                        local sp, vis = Camera:WorldToViewportPoint(part.Position)
                        if vis then
                            local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                            if d < bestDist then best, bestDist = p, d end
                        end
                    end
                end
            end
        end
        if best then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, best.Character[_G.TargetPart].Position)
        end
    end

    --// ESP
    if _G.ESP_Enabled then
        local vpX = Camera.ViewportSize.X
        local vpY = Camera.ViewportSize.Y
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local myPos = myRoot and myRoot.Position

        for _, p in ipairs(Players:GetPlayers()) do
            if p == LocalPlayer then continue end
            local o = ESP_Objects[p]
            if not o then CreateESP(p); o = ESP_Objects[p] end

            local char = p.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum  = char and char:FindFirstChildOfClass("Humanoid")

            if root and hum and hum.Health > 0 then
                local pos, vis = Camera:WorldToViewportPoint(root.Position)
                if vis then
                    local topPos    = Camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3, 0))
                    local bottomPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3.5, 0))
                    local sY = bottomPos.Y - topPos.Y
                    if sY > 0 then
                        local sX = sY * 0.6
                        local bPos = Vector2.new(pos.X - sX * 0.5, pos.Y - sY * 0.5)

                        o.Box.Visible = true
                        o.Box.Size = Vector2.new(sX, sY)
                        o.Box.Position = bPos
                        o.Box.Color = Color3.new(1, 1, 1)

                        o.Out.Visible = true
                        o.Out.Size = o.Box.Size
                        o.Out.Position = bPos
                        o.Out.Transparency = 0.5

                        o.HBg.Visible = true
                        o.HBg.Size = Vector2.new(3, sY)
                        o.HBg.Position = Vector2.new(bPos.X - 6, bPos.Y)

                        local hp = hum.Health / math.max(hum.MaxHealth, 1)
                        o.HBar.Visible = true
                        o.HBar.Size = Vector2.new(2, sY * hp)
                        o.HBar.Position = Vector2.new(bPos.X - 5, bPos.Y + sY * (1 - hp))
                        o.HBar.Color = hp > 0.5 and Color3.new(1, 1, 1)
                                     or (hp > 0.2 and Color3.new(0.5, 0.5, 0.5) or Color3.new(0.1, 0.1, 0.1))

                        o.N.Visible = _G.ESP_Names
                        if _G.ESP_Names then
                            o.N.Position = Vector2.new(pos.X, bPos.Y - 16)
                            o.N.Text = p.DisplayName .. " (@" .. p.Name .. ")"
                            o.N.Color = Color3.new(1, 1, 1)
                        end

                        if _G.ESP_Distance and myPos then
                            o.D.Visible = true
                            o.D.Position = Vector2.new(pos.X, bPos.Y + sY + 2)
                            o.D.Text = math.floor((myPos - root.Position).Magnitude) .. "m"
                        elseif o.D.Visible then o.D.Visible = false end

                        if _G.ESP_Tracers then
                            o.T.Visible = true
                            o.T.From = Vector2.new(vpX * 0.5, vpY)
                            o.T.To = Vector2.new(pos.X, pos.Y + sY * 0.5)
                            o.T.Color = Color3.new(1, 1, 1)
                        elseif o.T.Visible then o.T.Visible = false end

                        o.Visible = true
                    else
                        HideESP(o)
                    end
                else
                    HideESP(o)
                end
            else
                HideESP(o)
            end
        end
    else
        for _, o in pairs(ESP_Objects) do HideESP(o) end
    end
end)

--// ==================== ОЧИСТКА ИГРОКОВ ====================
Players.PlayerRemoving:Connect(function(p) RemoveESP(p) end)
Players.PlayerAdded:Connect(function(p)
    if p ~= LocalPlayer then CreateESP(p) end
end)
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then CreateESP(p) end
end

--// ==================== UI ====================
AddTab("Aimbot", AimPage)
AddTab("Visuals", VisPage)
AddTab("View", ViewPage)
AddTab("More", MorePage)

AddToggle("Enable Aimbot", AimPage, false, function(v) _G.AimbotEnabled = v end)
AddSlider("Aimbot Radius", 30, 800, 120, AimPage, function(v) _G.FOV_Radius = v end)
AddToggle("Show FOV Circle", AimPage, true, function(v) _G.ShowFOV = v end)
AddToggle("Rainbow Circle", AimPage, false, function(v) _G.RainbowFOV = v end)

local TBtn = Instance.new("TextButton")
TBtn.Size = UDim2.new(1, -5, 0, 40)
TBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
TBtn.Text = "Target: Body"
TBtn.TextColor3 = Color3.new(1, 1, 1)
TBtn.Font = Enum.Font.Gotham
TBtn.Parent = AimPage
Instance.new("UICorner", TBtn).CornerRadius = UDim.new(0, 10)
TBtn.MouseButton1Click:Connect(function()
    _G.TargetPart = (_G.TargetPart == "Head" and "HumanoidRootPart" or "Head")
    TBtn.Text = "Target: " .. (_G.TargetPart == "Head" and "Head" or "Body")
end)

AddToggle("Enable Boxes", VisPage, false, function(v) _G.ESP_Enabled = v end)
AddToggle("Display Names", VisPage, true, function(v) _G.ESP_Names = v end)
AddToggle("Tracers", VisPage, false, function(v) _G.ESP_Tracers = v end)
AddToggle("Show Distance", VisPage, true, function(v) _G.ESP_Distance = v end)
AddSlider("Field of View", 30, 120, 70, ViewPage, function(v) _G.Player_FOV = v end)

local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(1, 0, 0, 100)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Text = "Owner: Dll\nMain User: goooooomeeerrr\n\nDll hub | universal"
InfoLabel.TextColor3 = Color3.new(1, 1, 1)
InfoLabel.Font = Enum.Font.GothamBold
InfoLabel.TextSize = 14
InfoLabel.Parent = MorePage

local KBtn = Instance.new("TextButton")
KBtn.Size = UDim2.new(1, 0, 0, 35)
KBtn.Text = "UNLOAD"
KBtn.BackgroundColor3 = Color3.fromRGB(60, 20, 25)
KBtn.TextColor3 = Color3.new(1, 0, 0)
KBtn.Parent = Sidebar
Instance.new("UICorner", KBtn)
KBtn.MouseButton1Click:Connect(Unload)

Connections.menu = UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == MenuKey then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

AimPage.Visible = true

--// ==================== ЧАТ-АДМИН ====================
local WhitelistUrl = "https://raw.githubusercontent.com/Bruhiscrazy/Obsidian-/refs/heads/main/Whitelist"
local whitelist, whitelistReady = {}, false

task.spawn(function()
    local ok, body = pcall(game.HttpGet, game, WhitelistUrl)
    if not ok or not body then return end
    local decodeOk, decoded = pcall(HttpService.JSONDecode, HttpService, body)
    if decodeOk and typeof(decoded) == "table" then
        whitelist = decoded
        whitelistReady = true
    end
end)

local function isAdmin(player)
    if not whitelistReady then return false end
    return table.find(whitelist, player.UserId) ~= nil
end

local function findPlayer(query)
    query = string.lower(query)
    for _, pl in ipairs(Players:GetPlayers()) do
        if string.find(string.lower(pl.Name), query, 1, true)
        or string.find(string.lower(pl.DisplayName), query, 1, true) then
            return pl
        end
    end
end

local function onAdminCommand(speaker, text)
    if not isAdmin(speaker) then return end
    if string.sub(text, 1, 1) ~= ":" then return end
    local args = {}
    for w in string.gmatch(string.sub(text, 2), "%S+") do table.insert(args, w) end
    local cmd = table.remove(args, 1)
    if not cmd then return end
    cmd = string.lower(cmd)
    local joined = table.concat(args, " ")
    if cmd == "b" and joined ~= "" then
        local t = findPlayer(joined)
        if t and t ~= speaker and t.Character and speaker.Character then
            local tr = t.Character:FindFirstChild("HumanoidRootPart")
            local sr = speaker.Character:FindFirstChild("HumanoidRootPart")
            if tr and sr then tr.CFrame = sr.CFrame + Vector3.new(3, 0, 3) end
        end
    elseif cmd == "re" and joined ~= "" then
        local t = findPlayer(joined)
        if t and t ~= speaker and t.Character then
            local h = t.Character:FindFirstChildOfClass("Humanoid")
            if h then h.Health = 0 end
        end
    elseif cmd == "k" and joined ~= "" then
        local t = findPlayer(joined)
        if t and t ~= speaker then pcall(function() t:Kick("Kicked by admin") end) end
    end
end

if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
    local channels = TextChatService:FindFirstChild("TextChannels")
    local general  = channels and channels:FindFirstChild("RBXGeneral")
    if general then
        general.MessageReceived:Connect(function(message)
            local src = message.TextSource
            if src then
                local pl = Players:GetPlayerByUserId(src.UserId)
                if pl then onAdminCommand(pl, message.Text) end
            end
        end)
    end
else
    local function hookChatted(player)
        player.Chatted:Connect(function(msg) onAdminCommand(player, msg) end)
    end
    for _, pl in ipairs(Players:GetPlayers()) do hookChatted(pl) end
    Players.PlayerAdded:Connect(hookChatted)
end

--// ==================== OBSIDIAN LIB ====================
local LibraryUrl = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"
local Library = loadstring(game:HttpGet(LibraryUrl))()

Library.Scheme.BackgroundColor   = Color3.fromRGB(45, 10, 10)
Library.Scheme.MainColor         = Color3.fromRGB(65, 15, 15)
Library.Scheme.AccentColor       = Color3.fromRGB(255, 60, 60)
Library.Scheme.OutlineColor      = Color3.fromRGB(120, 40, 40)
Library.Scheme.FontColor         = Color3.fromRGB(255, 220, 220)
Library.Scheme.RedColor          = Color3.fromRGB(255, 80, 80)
Library.Scheme.DestructiveColor  = Color3.fromRGB(180, 30, 30)
Library.Scheme.DarkColor         = Color3.fromRGB(20, 5, 5)
Library.Scheme.WhiteColor        = Color3.fromRGB(255, 240, 240)
Library:UpdateColorsUsingRegistry()

local Window = Library:CreateWindow({
    Title = "Mobile Trigger Bot",
    Footer = "made by someone",
    ToggleKeybind = Enum.KeyCode.RightControl,
    Size = UDim2.fromOffset(450, 380),
    Acrylic = false,
    NotifySide = "Right",
    ShowCustomCursor = false,  -- ← выключено, меньше нагрузки
})

local TriggerTab = Window:AddTab("Trigger", "rbxassetid://10709751830")

--// ====== TRIGGER BOT ======
local Config = {
    Enabled = false,
    Connection = nil,
    canGrab = true,
    maxDistance = 20,
    preGrabDelay = 1e-05,
    postGrabDelay = 0.05,
    lastTarget = nil,
    lastHitTime = 0,
    targetMemoryDuration = 0.1,
    checkThrottle = 0.008,
    lastCheck = 0,
    cooldown = 0.8,
    lastReleaseTime = 0,

    --// WATCHDOG
    grabStartTime = 0,
    watchdogTimeout = 3,  -- если grab висит дольше 3 сек → сброс
}

local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Exclude

task.spawn(function()
    local ok, owned = pcall(function()
        return ReplicatedStorage.GamepassEvents.CheckForGamepass:InvokeServer(20837132)
    end)
    if ok and owned then Config.maxDistance = 29.3 end
end)

local gamepass = ReplicatedStorage:FindFirstChild("GamepassEvents")
if gamepass then
    local reachNotifier = gamepass:FindFirstChild("FurtherReachBoughtNotifier")
    if reachNotifier then
        reachNotifier.OnClientEvent:Connect(function() Config.maxDistance = 29.3 end)
    end
end

function Config:GetTarget()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    if Workspace:FindFirstChild("GrabParts") then return nil end
    Camera = Workspace.CurrentCamera
    if not Camera then return nil end

    local look = Camera.CFrame.LookVector
    RayParams.FilterDescendantsInstances = { character, Workspace.Terrain }

    local hit = Workspace:Raycast(Camera.CFrame.Position, look * 1000, RayParams)
    if not hit then
        for _, direction in ipairs({
            look,
            (look + Vector3.new(0, 0.075, 0)).Unit,
            (look - Vector3.new(0, 0.075, 0)).Unit,
        }) do
            hit = Workspace:Raycast(Camera.CFrame.Position, direction * 1000, RayParams)
            if hit then break end
        end
    end
    if not hit then return nil end

    local model = hit.Instance:FindFirstAncestorOfClass("Model")
    if not model or model == character then return nil end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return nil end
    local root = model:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    if (character.HumanoidRootPart.Position - root.Position).Magnitude > self.maxDistance then return nil end
    return model
end

local function fireGrab()
    pcall(function()
        ContextActionService:CallFunction("Grab", Enum.UserInputState.Begin, nil)
    end)
    task.wait(0.05)
    pcall(function()
        ContextActionService:CallFunction("Grab", Enum.UserInputState.End, nil)
    end)
end

function Config:ResetState(reason)
    self.canGrab = true
    self.lastTarget = nil
    self.grabStartTime = 0
    if reason then
        -- раскомментируй для дебага:
        -- warn("[TriggerBot] Reset:", reason)
    end
end

function Config:OnHeartbeat()
    if not self.Enabled then return end

    --// WATCHDOG: если canGrab=false дольше watchdogTimeout — принудительный сброс
    if not self.canGrab then
        if self.grabStartTime > 0 and tick() - self.grabStartTime > self.watchdogTimeout then
            warn("[TriggerBot] Watchdog: принудительный сброс (grab завис)")
            pcall(function()
                ContextActionService:CallFunction("Grab", Enum.UserInputState.End, nil)
            end)
            self:ResetState("watchdog")
        end
        return
    end

    if UserInputService:GetFocusedTextBox() then return end
    if tick() - self.lastCheck < self.checkThrottle then return end
    self.lastCheck = tick()

    if not Workspace:FindFirstChild("GrabParts") then
        if tick() - self.lastReleaseTime < self.cooldown then return end
    end

    local target = self:GetTarget()
    if target then
        self.lastTarget = target
        self.lastHitTime = tick()
    elseif self.lastTarget and tick() - self.lastHitTime > self.targetMemoryDuration then
        self.lastTarget = nil
    end

    if not self.lastTarget then return end

    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end

    --// Защита от мёртвых инстансов
    local ok, hasRoot = pcall(function()
        return self.lastTarget:FindFirstChild("HumanoidRootPart") ~= nil
    end)
    if not ok or not hasRoot then
        self.lastTarget = nil
        return
    end

    local myRoot = character.HumanoidRootPart
    local tgtRoot = self.lastTarget.HumanoidRootPart
    if not myRoot or not tgtRoot then
        self.lastTarget = nil
        return
    end

    if (myRoot.Position - tgtRoot.Position).Magnitude > self.maxDistance then
        self.lastTarget = nil
        return
    end

    --// Запуск grab
    self.canGrab = false
    self.grabStartTime = tick()

    task.spawn(function()
        task.wait(self.preGrabDelay)
        fireGrab()

        local started = tick()
        while Workspace:FindFirstChild("GrabParts") and tick() - started <= 1.6 do
            task.wait(0.02)
        end

        self.lastReleaseTime = tick()
        task.wait(self.postGrabDelay)
        self.canGrab = true
        self.grabStartTime = 0
        self.lastTarget = nil
    end)
end

local TriggerBox = TriggerTab:AddLeftGroupbox("Trigger Bot")
local StatusBox  = TriggerTab:AddRightGroupbox("Status")
local StatusLabel   = StatusBox:AddLabel("Status: Disabled")
local CooldownLabel = StatusBox:AddLabel("Cooldown: 0.55s (after release)")

TriggerBox:AddToggle("EnableTriggerBot", {
    Text = "Enable Trigger Bot",
    Default = false,
    Tooltip = "Toggle trigger bot on/off",
    Callback = function(enabled)
        Config.Enabled = enabled

        --// Сброс состояния при любом переключении
        Config.canGrab = true
        Config.lastTarget = nil
        Config.lastReleaseTime = 0
        Config.grabStartTime = 0

        if enabled and not Config.Connection then
            Config.Connection = RunService.Heartbeat:Connect(function()
                --// pcall вокруг всего — если что-то крашит, состояние сбросится
                local ok, err = pcall(function()
                    Config:OnHeartbeat()
                end)
                if not ok then
                    warn("[TriggerBot] Heartbeat error:", err)
                    Config.canGrab = true
                    Config.lastTarget = nil
                    Config.grabStartTime = 0
                end
            end)
            StatusLabel:SetText("Status: Active")
        elseif not enabled and Config.Connection then
            Config.Connection:Disconnect()
            Config.Connection = nil
            StatusLabel:SetText("Status: Disabled")
        end
    end,
})

TriggerBox:AddSlider("MaxDistance", {
    Text = "Max Distance",
    Default = 29.3, Min = 10, Max = 30, Rounding = 1,
    Tooltip = "Maximum grab range",
    Callback = function(value) Config.maxDistance = value end,
})

TriggerBox:AddSlider("PreGrabDelay", {
    Text = "Pre Grab Delay",
    Default = 1e-05, Min = 0, Max = 0.5, Rounding = 5,
    Tooltip = "Delay before grab (prediction)",
    Callback = function(value) Config.preGrabDelay = value end,
})

TriggerBox:AddSlider("PostGrabDelay", {
    Text = "Post Grab Delay",
    Default = 0.05, Min = 0, Max = 0.5, Rounding = 2,
    Tooltip = "Delay after grab release",
    Callback = function(value) Config.postGrabDelay = value end,
})

TriggerBox:AddSlider("TargetMemory", {
    Text = "Target Memory",
    Default = 0.1, Min = 0, Max = 1, Rounding = 2,
    Tooltip = "How long to remember target after losing sight",
    Callback = function(value) Config.targetMemoryDuration = value end,
})

TriggerBox:AddSlider("CheckThrottle", {
    Text = "Check Throttle",
    Default = 0.008, Min = 0.001, Max = 0.1, Rounding = 3,
    Tooltip = "Time between target checks",
    Callback = function(value) Config.checkThrottle = value end,
})

TriggerBox:AddSlider("Cooldown", {
    Text = "Cooldown",
    Default = 0.55, Min = 0.1, Max = 3, Rounding = 2,
    Tooltip = "Seconds between grabs (starts after release)",
    Callback = function(value)
        Config.cooldown = value
        CooldownLabel:SetText("Cooldown: " .. tostring(value) .. "s (after release)")
    end,
})

StatusBox:AddLabel("Pc but mobile")
StatusBox:AddLabel("Dont mess with with the other stuff")
StatusBox:AddLabel("Only use cooldown")
StatusBox:AddLabel("Mobile fps are bad ")
StatusBox:AddLabel("wont grab correctly due to 60fps")

--// ====== BIND CHARACTER (сброс при смерти И при респавне) ======
local function bindCharacter(character)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if humanoid then
        humanoid.Died:Connect(function()
            Config.canGrab = true
            Config.lastTarget = nil
            Config.lastReleaseTime = 0
            Config.grabStartTime = 0
            if Config.Enabled then
                StatusLabel:SetText("Status: Died - Reset")
            end
        end)
    end
end

--// Сброс состояния при респавне (CharacterAdded срабатывает и при первом спавне, и после смерти)
LocalPlayer.CharacterAdded:Connect(function(char)
    Config.canGrab = true
    Config.lastTarget = nil
    Config.lastReleaseTime = 0
    Config.grabStartTime = 0
    bindCharacter(char)
end)

if LocalPlayer.Character then
    bindCharacter(LocalPlayer.Character)
end

Library:Toggle(true)

--// ==================== HIGHLIGHT (клавиша Y) — БЕЗ GetMouse ====================
local highlightedPlayers = {}

local function applyHighlight(player)
    if not highlightedPlayers[player.Name] then return end
    local character = player.Character
    if not character then return end
    local highlight = character:FindFirstChild("EspHighlight")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "EspHighlight"
        highlight.FillColor = Color3.fromRGB(255, 0, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = character
    end
end

local function monitorPlayer(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        applyHighlight(player)
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then monitorPlayer(player) end
end
Players.PlayerAdded:Connect(monitorPlayer)

--// ЗАМЕНА GetMouse: используем ViewportPointToRay + Raycast
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode ~= Enum.KeyCode.Y then return end

    local mousePos = UserInputService:GetMouseLocation()
    local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = LocalPlayer.Character and {LocalPlayer.Character} or {}

    local hit = Workspace:Raycast(ray.Origin, ray.Direction * 1000, rayParams)
    if not hit then return end

    local character = hit.Instance:FindFirstAncestorOfClass("Model")
    if not character then return end

    local player = Players:GetPlayerFromCharacter(character)
    if not player or player == LocalPlayer then return end

    local pName = player.Name
    if highlightedPlayers[pName] then
        highlightedPlayers[pName] = nil
        local highlight = character:FindFirstChild("EspHighlight")
        if highlight then highlight:Destroy() end
    else
        highlightedPlayers[pName] = true
        applyHighlight(player)
    end
end)
