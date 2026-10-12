-- ============================================
-- NYCOLAS BLOX - Painel MM2
-- Key: NYCOLAS
-- ============================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

_G.infinjump = false
_G.aimbotEnabled = false
_G.flyEnabled = false
_G.noclip = false
_G.autoShootMurderer = false
_G.autoShootSheriff = false

local selectedPlayer = nil
local aimbotTarget = "Ninguém (Todos)"
local screenButtons = {}

local function getRole(player)
    if player == LocalPlayer then return "Local" end
    local char = player.Character
    if not char then return "Innocent" end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            local n = tool.Name:lower()
            if n:find("knife") or n:find("faca") or n:find("dagger") then return "Murderer" end
            if n:find("gun") or n:find("revolver") or n:find("pistol") then return "Sheriff" end
        end
    end
    local bp = player:FindFirstChild("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") then
                local n = tool.Name:lower()
                if n:find("knife") or n:find("faca") or n:find("dagger") then return "Murderer" end
                if n:find("gun") or n:find("revolver") or n:find("pistol") then return "Sheriff" end
            end
        end
    end
    return "Innocent"
end

local RoleESP = { Enabled = false, Highlights = {}, Roles = {} }
local RoleColors = {
    ["Murderer"] = Color3.fromRGB(255, 0, 0),
    ["Sheriff"] = Color3.fromRGB(0, 100, 255),
    ["Innocent"] = Color3.fromRGB(0, 255, 0)
}

local function ApplyHighlight(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char then return end
    local old = char:FindFirstChild("RoleESP")
    if old then old:Destroy() end
    local role = RoleESP.Roles[player] or getRole(player)
    if role ~= "Innocent" then RoleESP.Roles[player] = role end
    local color = RoleColors[role] or RoleColors["Innocent"]
    local h = Instance.new("Highlight")
    h.Name = "RoleESP"
    h.Adornee = char
    h.FillColor = color
    h.OutlineColor = Color3.new(1, 1, 1)
    h.FillTransparency = 0.5
    h.OutlineTransparency = 0
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = char
    local oldLabel = char:FindFirstChild("RoleLabel")
    if oldLabel then oldLabel:Destroy() end
    local head = char:FindFirstChild("Head")
    if head then
        local bb = Instance.new("BillboardGui")
        bb.Name = "RoleLabel"
        bb.Size = UDim2.new(0, 100, 0, 20)
        bb.StudsOffset = Vector3.new(0, 2.5, 0)
        bb.AlwaysOnTop = true
        bb.Parent = head
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = role == "Murderer" and "🔪 ASSASSINO" or role == "Sheriff" and "🔫 XERIFE" or "👤 Inocente"
        label.TextColor3 = color
        label.TextStrokeTransparency = 0
        label.Font = Enum.Font.GothamBold
        label.TextSize = 14
        label.Parent = bb
    end
    RoleESP.Highlights[player] = h
end

local function RemoveHighlight(player)
    local char = player.Character
    if char then
        if char:FindFirstChild("RoleESP") then char.RoleESP:Destroy() end
        local head = char:FindFirstChild("Head")
        if head and head:FindFirstChild("RoleLabel") then head.RoleLabel:Destroy() end
    end
    RoleESP.Highlights[player] = nil
end

local function ToggleESP(enabled)
    RoleESP.Enabled = enabled
    if enabled then
        RoleESP.Roles = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then ApplyHighlight(p) end
        end
    else
        for p, _ in pairs(RoleESP.Highlights) do RemoveHighlight(p) end
    end
end

Players.PlayerRemoving:Connect(function(p)
    RemoveHighlight(p)
    RoleESP.Roles[p] = nil
end)

task.spawn(function()
    while task.wait(0.5) do
        if RoleESP.Enabled then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then ApplyHighlight(p) end
            end
        end
    end
end)

local function getAimbotTarget()
    local closest = nil
    local shortest = 300
    local mousePos = UserInputService:GetMouseLocation()
    if aimbotTarget and aimbotTarget ~= "Ninguém (Todos)" and aimbotTarget ~= "" then
        local t = Players:FindFirstChild(aimbotTarget)
        if t and t.Character then
            local hrp = t.Character:FindFirstChild("HumanoidRootPart")
            local hum = t.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then return hrp end
        end
        return nil
    end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(mousePos.X, mousePos.Y)).Magnitude
                    if dist < shortest then
                        shortest = dist
                        closest = hrp
                    end
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if _G.aimbotEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = getAimbotTarget()
        if target then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        end
    end
end)

local function shoot()
    local vu = game:GetService("VirtualUser")
    vu:CaptureController()
    vu:ClickButton1(Vector2.new(0, 0))
    local char = LocalPlayer.Character
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then tool:Activate() end
    end
end

local function findRole(role)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            if getRole(p) == role then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then return hrp end
            end
        end
    end
    return nil
end

task.spawn(function()
    while task.wait(0.15) do
        if _G.autoShootMurderer then
            local t = findRole("Murderer")
            if t then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, t.Position)
                shoot()
            end
        end
        if _G.autoShootSheriff then
            local t = findRole("Sheriff")
            if t then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, t.Position)
                shoot()
            end
        end
    end
end)

local flyBV, flyBG = nil, nil

local function startFly()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    flyBV = Instance.new("BodyVelocity")
    flyBV.Velocity = Vector3.new(0, 0, 0)
    flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    flyBV.Parent = hrp
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    flyBG.P = 20e3
    flyBG.Parent = hrp
end

local function stopFly()
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
end

RunService.RenderStepped:Connect(function()
    if _G.flyEnabled and flyBV and flyBG then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hrp and hum then
            flyBG.CFrame = Camera.CFrame
            flyBV.Velocity = hum.MoveDirection * 50
        end
    end
end)

RunService.Stepped:Connect(function()
    if _G.noclip then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetChildren()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end
end)

local function createScreenButtons()
    if screenButtons.frame then return end
    local gui = Instance.new("ScreenGui")
    gui.Name = "NycolasBloxButtons"
    gui.ResetOnSpawn = false
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 160, 0, 240)
    frame.Position = UDim2.new(0, 20, 0.5, -120)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundColor3 = Color3.fromRGB(75, 0, 130)
    title.Text = "⚔️ nycolas blox"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.BorderSizePixel = 0
    title.Parent = frame
    local tCorner = Instance.new("UICorner")
    tCorner.CornerRadius = UDim.new(0, 10)
    tCorner.Parent = title
    local btnAim = Instance.new("TextButton")
    btnAim.Size = UDim2.new(0.9, 0, 0, 40)
    btnAim.Position = UDim2.new(0.05, 0, 0, 40)
    btnAim.BackgroundColor3 = Color3.fromRGB(50, 0, 80)
    btnAim.Text = "🎯 Aimbot"
    btnAim.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnAim.Font = Enum.Font.GothamBold
    btnAim.TextSize = 13
    btnAim.BorderSizePixel = 0
    btnAim.Parent = frame
    local c1 = Instance.new("UICorner")
    c1.CornerRadius = UDim.new(0, 8)
    c1.Parent = btnAim
    btnAim.MouseButton1Click:Connect(function()
        _G.aimbotEnabled = not _G.aimbotEnabled
        if _G.aimbotEnabled then
            btnAim.BackgroundColor3 = Color3.fromRGB(170, 0, 255)
            btnAim.Text = "🎯 Aimbot ON"
        else
            btnAim.BackgroundColor3 = Color3.fromRGB(50, 0, 80)
            btnAim.Text = "🎯 Aimbot"
        end
    end)
    local btnM = Instance.new("TextButton")
    btnM.Size = UDim2.new(0.9, 0, 0, 40)
    btnM.Position = UDim2.new(0.05, 0, 0, 90)
    btnM.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
    btnM.Text = "🔴 Assassino"
    btnM.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnM.Font = Enum.Font.GothamBold
    btnM.TextSize = 13
    btnM.BorderSizePixel = 0
    btnM.Parent = frame
    local c2 = Instance.new("UICorner")
    c2.CornerRadius = UDim.new(0, 8)
    c2.Parent = btnM
    btnM.MouseButton1Click:Connect(function()
        _G.autoShootMurderer = not _G.autoShootMurderer
        if _G.autoShootMurderer then
            btnM.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            btnM.Text = "🔴 Assassino ON"
        else
            btnM.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
            btnM.Text = "🔴 Assassino"
        end
    end)
    local btnS = Instance.new("TextButton")
    btnS.Size = UDim2.new(0.9, 0, 0, 40)
    btnS.Position = UDim2.new(0.05, 0, 0, 140)
    btnS.BackgroundColor3 = Color3.fromRGB(0, 0, 80)
    btnS.Text = "🔵 Xerife"
    btnS.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnS.Font = Enum.Font.GothamBold
    btnS.TextSize = 13
    btnS.BorderSizePixel = 0
    btnS.Parent = frame
    local c3 = Instance.new("UICorner")
    c3.CornerRadius = UDim.new(0, 8)
    c3.Parent = btnS
    btnS.MouseButton1Click:Connect(function()
        _G.autoShootSheriff = not _G.autoShootSheriff
        if _G.autoShootSheriff then
            btnS.BackgroundColor3 = Color3.fromRGB(0, 100, 255)
            btnS.Text = "🔵 Xerife ON"
        else
            btnS.BackgroundColor3 = Color3.fromRGB(0, 0, 80)
            btnS.Text = "🔵 Xerife"
        end
    end)
    local btnESP = Instance.new("TextButton")
    btnESP.Size = UDim2.new(0.9, 0, 0, 40)
    btnESP.Position = UDim2.new(0.05, 0, 0, 190)
    btnESP.BackgroundColor3 = Color3.fromRGB(0, 60, 0)
    btnESP.Text = "👁️ ESP"
    btnESP.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnESP.Font = Enum.Font.GothamBold
    btnESP.TextSize = 13
    btnESP.BorderSizePixel = 0
    btnESP.Parent = frame
    local c4 = Instance.new("UICorner")
    c4.CornerRadius = UDim.new(0, 8)
    c4.Parent = btnESP
    btnESP.MouseButton1Click:Connect(function()
        RoleESP.Enabled = not RoleESP.Enabled
        ToggleESP(RoleESP.Enabled)
        if RoleESP.Enabled then
            btnESP.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            btnESP.Text = "👁️ ESP ON"
        else
            btnESP.BackgroundColor3 = Color3.fromRGB(0, 60, 0)
            btnESP.Text = "👁️ ESP"
        end
    end)
    local btnX = Instance.new("TextButton")
    btnX.Size = UDim2.new(0, 25, 0, 25)
    btnX.Position = UDim2.new(1, -28, 0, 3)
    btnX.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    btnX.Text = "X"
    btnX.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnX.Font = Enum.Font.GothamBold
    btnX.TextSize = 14
    btnX.BorderSizePixel = 0
    btnX.Parent = frame
    local cX = Instance.new("UICorner")
    cX.CornerRadius = UDim.new(0, 12)
    cX.Parent = btnX
    btnX.MouseButton1Click:Connect(function()
        frame.Visible = false
        _G.aimbotEnabled = false
        _G.autoShootMurderer = false
        _G.autoShootSheriff = false
        if RoleESP.Enabled then ToggleESP(false) end
    end)
    local dragging, dragInput, dragStart, startPos
    local function updateDrag(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    title.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then updateDrag(input) end
    end)
    screenButtons.frame = frame
    screenButtons.gui = gui
end

local function destroyScreenButtons()
    if screenButtons.gui then
        screenButtons.gui:Destroy()
        screenButtons = {}
        _G.aimbotEnabled = false
        _G.autoShootMurderer = false
        _G.autoShootSheriff = false
    end
end

local Window = Rayfield:CreateWindow({
    Name = "nycolas blox",
    LoadingTitle = "Carregando nycolas blox...",
    LoadingSubtitle = "by Nycolas",
    Theme = "Amethyst",
    ToggleUIKeybind = "K",
    ConfigurationSaving = { Enabled = false },
    KeySystem = true,
    KeySettings = {
        Title = "🔑 nycolas blox",
        Subtitle = "Digite a Key",
        Note = "Key: NYCOLAS",
        FileName = "NycolasKey",
        SaveKey = false,
        GrabKeyFromSite = false,
        Key = {"NYCOLAS"}
    }
})

local HomeTab = Window:CreateTab("Home", 4483362458)
HomeTab:CreateSection("👤 Player")
HomeTab:CreateToggle({Name = "God Mode", CurrentValue = false, Flag = "GodMode", Callback = function(v)
    local char = LocalPlayer.Character
    if char and char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid").MaxHealth = v and math.huge or 100
        char:FindFirstChildOfClass("Humanoid").Health = v and math.huge or 100
    end
end})
HomeTab:CreateToggle({Name = "No Clip", CurrentValue = false, Flag = "NoClip", Callback = function(v) _G.noclip = v end})
HomeTab:CreateSection("👁️ ESP")
HomeTab:CreateToggle({Name = "ESP Players", CurrentValue = false, Flag = "ESPPlayers", Callback = function(v) ToggleESP(v) end})

local PlayerTab = Window:CreateTab("Player", 4483362458)
PlayerTab:CreateSection("Movimento")
PlayerTab:CreateSlider({Name = "Velocidade", Range = {16, 250}, Increment = 1, Suffix = "Speed", CurrentValue = 16, Flag = "Speed", Callback = function(v)
    local c = LocalPlayer.Character
    if c and c:FindFirstChildOfClass("Humanoid") then c:FindFirstChildOfClass("Humanoid").WalkSpeed = v end
end})
PlayerTab:CreateSlider({Name = "Pulo", Range = {50, 500}, Increment = 5, Suffix = "Power", CurrentValue = 50, Flag = "Jump", Callback = function(v)
    local c = LocalPlayer.Character
    if c and c:FindFirstChildOfClass("Humanoid") then c:FindFirstChildOfClass("Humanoid").JumpPower = v end
end})
PlayerTab:CreateToggle({Name = "Pulo Infinito", CurrentValue = false, Flag = "InfJump", Callback = function(v) _G.infinjump = v end})

UserInputService.JumpRequest:Connect(function()
    if _G.infinjump then
        local c = LocalPlayer.Character
        if c and c:FindFirstChildOfClass("Humanoid") then c:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping") end
    end
end)

local ESPTab = Window:CreateTab("ESP", 4483362458)
ESPTab:CreateSection("ESP")
ESPTab:CreateToggle({Name = "ESP Todos os Players", CurrentValue = false, Flag = "ESPTodos", Callback = function(v) ToggleESP(v) end})
ESPTab:CreateParagraph({Title = "Cores", Content = "🔴 Assassino | 🔵 Xerife | 🟢 Inocente"})

local CombatTab = Window:CreateTab("Combate", 4483362458)
CombatTab:CreateSection("🎯 Aimbot")

local function getAimbotPlayerList()
    local list = {"Ninguém (Todos)"}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(list, p.Name) end
    end
    return list
end

local aimbotList = getAimbotPlayerList()

local AimbotDropdown = CombatTab:CreateDropdown({
    Name = "🎯 Alvo do Aimbot",
    Options = aimbotList,
    CurrentOption = {"Ninguém (Todos)"},
    MultipleOptions = false,
    Flag = "AimbotTarget",
    Callback = function(Option) aimbotTarget = Option[1] end
})

CombatTab:CreateButton({Name = "🔄 Atualizar Lista", Callback = function()
    aimbotList = getAimbotPlayerList()
    AimbotDropdown:Refresh(aimbotList, true)
end})

CombatTab:CreateToggle({Name = "🎯 Ativar Aimbot", CurrentValue = false, Flag = "AimbotToggle", Callback = function(v) _G.aimbotEnabled = v end})
CombatTab:CreateSection("🔫 Auto-Shoot")
CombatTab:CreateToggle({Name = "🔴 Auto-Shoot Assassino", CurrentValue = false, Flag = "AutoShootM", Callback = function(v) _G.autoShootMurderer = v end})
CombatTab:CreateToggle({Name = "🔵 Auto-Shoot Xerife", CurrentValue = false, Flag = "AutoShootS", Callback = function(v) _G.autoShootSheriff = v end})
CombatTab:CreateSection("📱 Botões na Tela")
CombatTab:CreateToggle({Name = "📱 Mostrar Botões", CurrentValue = false, Flag = "ShowButtons", Callback = function(v)
    if v then createScreenButtons() else destroyScreenButtons() end
end})

local TpTab = Window:CreateTab("Teleporte", 4483362458)
TpTab:CreateSection("Jogadores")

local function getPlayerList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(list, p.Name) end
    end
    return list
end

local tpList = getPlayerList()

local Drop = TpTab:CreateDropdown({
    Name = "Selecionar Jogador",
    Options = tpList,
    CurrentOption = {""},
    MultipleOptions = false,
    Flag = "PlayerDrop",
    Callback = function(Opt) selectedPlayer = Opt[1] end
})

TpTab:CreateButton({Name = "🔄 Atualizar 
