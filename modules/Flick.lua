local REQUIRED_GAME_ID = 8795154789
if game.GameId ~= REQUIRED_GAME_ID then return end

local uiurl = "https://raw.githubusercontent.com/Walidname113/Roblox-scr/main/uncoded.lua"
local success, source = pcall(function()
    return game:HttpGet(uiurl)
end)

if not success then
    warn("Error load UI:", source)
    return
end

local moduleFunc, err = loadstring(source)
if not moduleFunc then
    warn("Error module func:", err)
    return
end

local uiModule = moduleFunc()
local ui = uiModule.CreateUI("Flick by Kiyatsuka | Version: 1.0.4 Stable.")
ui.SetMinimizedImage("97837481633367")

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = localPlayer:GetMouse()

local scriptRunning = true
local connections = {}

local function trackConnection(conn)
    table.insert(connections, conn)
end

local ESP_Settings = {
    Box = false,
    BoxColor = Color3.fromRGB(255, 255, 0),
    Names = false,
    NamesColor = Color3.fromRGB(255, 0, 0),
    HP = false,
    Lines = false,
    LinesColor = Color3.fromRGB(0, 255, 255),
    Distance = false,
    DistanceColor = Color3.fromRGB(255, 255, 255)
}

local Aim_Settings = {
    Enabled = false,
    TargetPart = "Head",
    MaxDistance = 100,
    WallCheck = false,
    Smoothness = 0.08,
    HitboxActive = false,
    HitboxSize = 3,
    SilentAim = true
}

local PresetColors = {
    {n = "Red", c = Color3.fromRGB(255, 0, 0)},
    {n = "Green", c = Color3.fromRGB(0, 255, 0)},
    {n = "Blue", c = Color3.fromRGB(0, 150, 255)},
    {n = "Yellow", c = Color3.fromRGB(255, 255, 0)},
    {n = "Purple", c = Color3.fromRGB(170, 0, 255)},
    {n = "White", c = Color3.fromRGB(255, 255, 255)},
    {n = "Cyan", c = Color3.fromRGB(0, 255, 255)}
}

local originalHeadSizes = {}

local function ShowWarning(text)
    if not ui.ScreenGui then return end
    local warnFrame = Instance.new("Frame")
    warnFrame.Size = UDim2.new(0, 300, 0, 150)
    warnFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
    warnFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    warnFrame.ZIndex = 11000
    Instance.new("UICorner", warnFrame)
    Instance.new("UIStroke", warnFrame).Color = Color3.fromRGB(255, 0, 0)

    local msg = Instance.new("TextLabel", warnFrame)
    msg.Size = UDim2.new(1, -20, 0, 80)
    msg.Position = UDim2.new(0, 10, 0, 10)
    msg.BackgroundTransparency = 1
    msg.Text = text
    msg.TextColor3 = Color3.new(1,1,1)
    msg.Font = Enum.Font.GothamBold
    msg.TextSize = 16
    msg.TextWrapped = true

    local btn = Instance.new("TextButton", warnFrame)
    btn.Size = UDim2.new(0, 120, 0, 35)
    btn.Position = UDim2.new(0.5, -60, 0.7, 0)
    btn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    btn.Text = "Understood"
    btn.TextColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", btn)

    warnFrame.Parent = ui.ScreenGui
    btn.MouseButton1Click:Connect(function() warnFrame:Destroy() end)
end

local function ForceDisableToggle(container)
    local switch = container:FindFirstChild("switch") or container:FindFirstChildWhichIsA("Frame", true)
    if switch then
        local knob = switch:FindFirstChildWhichIsA("Frame", true)
        TweenService:Create(switch, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(70, 70, 70)}):Play()
        if knob then
            TweenService:Create(knob, TweenInfo.new(0.3), {Position = UDim2.new(0, 1, 0.5, -9)}):Play()
        end
    end
end

local function AddColorPicker(container, defaultValue, callback)
    local colorBtn = Instance.new("TextButton")
    colorBtn.Size = UDim2.new(0, 24, 0, 24)
    colorBtn.Position = UDim2.new(1, -85, 0.5, -12)
    colorBtn.BackgroundColor3 = defaultValue
    colorBtn.Text = ""
    Instance.new("UICorner", colorBtn).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", colorBtn).Color = Color3.new(1,1,1)
    colorBtn.Parent = container

    local menu = Instance.new("ScrollingFrame")
    menu.Size = UDim2.new(0, 110, 0, 180)
    menu.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    menu.Visible = false
    menu.ZIndex = 12000
    menu.CanvasSize = UDim2.new(0, 0, 0, #PresetColors * 32 + 10)
    menu.ScrollBarThickness = 4
    Instance.new("UICorner", menu)
    menu.Parent = ui.ScreenGui

    local layout = Instance.new("UIListLayout", menu)
    layout.Padding = UDim.new(0, 5)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    for _, data in ipairs(PresetColors) do
        local btn = Instance.new("TextButton", menu)
        btn.Size = UDim2.new(0, 90, 0, 25)
        btn.BackgroundColor3 = data.c
        btn.Text = ""
        Instance.new("UICorner", btn)
        btn.MouseButton1Click:Connect(function()
            colorBtn.BackgroundColor3 = data.c
            menu.Visible = false
            callback(data.c)
        end)
    end

    colorBtn.MouseButton1Click:Connect(function()
        menu.Position = UDim2.new(0, colorBtn.AbsolutePosition.X + 35, 0, colorBtn.AbsolutePosition.Y)
        menu.Visible = not menu.Visible
    end)
end

local aimCategory = ui.CreateCategory("Aim Settings")

ui.CreateToggle("Aimbot", aimCategory, function(state)
    Aim_Settings.Enabled = state
end)

local boneContainer = Instance.new("Frame")
boneContainer.Size = UDim2.new(1, -4, 0, 42)
boneContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
Instance.new("UICorner", boneContainer).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", boneContainer).Color = Color3.fromRGB(39, 39, 42)
boneContainer.Parent = aimCategory

local boneLabel = Instance.new("TextLabel", boneContainer)
boneLabel.Size = UDim2.new(0, 120, 1, 0)
boneLabel.Position = UDim2.new(0, 14, 0, 0)
boneLabel.BackgroundTransparency = 1
boneLabel.Text = "Target Bone"
boneLabel.Font = Enum.Font.Gotham
boneLabel.TextSize = 13
boneLabel.TextColor3 = Color3.fromRGB(243, 244, 246)
boneLabel.TextXAlignment = Enum.TextXAlignment.Left

local dropdownBtn = Instance.new("TextButton", boneContainer)
dropdownBtn.Size = UDim2.new(0, 120, 0, 28)
dropdownBtn.Position = UDim2.new(1, -134, 0.5, -14)
dropdownBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
dropdownBtn.Text = "Head ▼"
dropdownBtn.Font = Enum.Font.GothamBold
dropdownBtn.TextColor3 = Color3.fromRGB(243, 244, 246)
dropdownBtn.TextSize = 12
Instance.new("UICorner", dropdownBtn).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", dropdownBtn).Color = Color3.fromRGB(39, 39, 42)

local listFrame = Instance.new("Frame", ui.ScreenGui)
listFrame.Size = UDim2.new(0, 120, 0, 64)
listFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
listFrame.Visible = false
listFrame.ZIndex = 15000
Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", listFrame).Color = Color3.fromRGB(168, 85, 247)

local listLayout = Instance.new("UIListLayout", listFrame)

local function makeDropdownItem(name, value)
    local b = Instance.new("TextButton", listFrame)
    b.Size = UDim2.new(1, 0, 0, 32)
    b.BackgroundTransparency = 1
    b.Text = name
    b.Font = Enum.Font.Gotham
    b.TextColor3 = Color3.fromRGB(156, 163, 175)
    b.TextSize = 12
    
    b.MouseButton1Click:Connect(function()
        Aim_Settings.TargetPart = value
        dropdownBtn.Text = name .. " ▼"
        listFrame.Visible = false
    end)
end
makeDropdownItem("Head", "Head")
makeDropdownItem("Torso", "HumanoidRootPart")

dropdownBtn.MouseButton1Click:Connect(function()
    listFrame.Position = UDim2.new(0, dropdownBtn.AbsolutePosition.X, 0, dropdownBtn.AbsolutePosition.Y + 32)
    listFrame.Visible = not listFrame.Visible
end)

local distanceContainer = Instance.new("Frame")
distanceContainer.Size = UDim2.new(1, -4, 0, 42)
distanceContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
Instance.new("UICorner", distanceContainer).CornerRadius = UDim.new(0, 8)
local distContStroke = Instance.new("UIStroke", distanceContainer)
distContStroke.Color = Color3.fromRGB(39, 39, 42)
distanceContainer.Parent = aimCategory

local distanceLabel = Instance.new("TextLabel", distanceContainer)
distanceLabel.Size = UDim2.new(0, 150, 1, 0)
distanceLabel.Position = UDim2.new(0, 14, 0, 0)
distanceLabel.BackgroundTransparency = 1
distanceLabel.Text = "Aimbot Distance (Studs)"
distanceLabel.Font = Enum.Font.Gotham
distanceLabel.TextSize = 13
distanceLabel.TextColor3 = Color3.fromRGB(243, 244, 246)
distanceLabel.TextXAlignment = Enum.TextXAlignment.Left

local distanceInput = Instance.new("TextBox", distanceContainer)
distanceInput.Size = UDim2.new(0, 70, 0, 28)
distanceInput.Position = UDim2.new(1, -84, 0.5, -14)
distanceInput.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
distanceInput.Text = tostring(Aim_Settings.MaxDistance)
distanceInput.PlaceholderText = "100"
distanceInput.Font = Enum.Font.GothamBold
distanceInput.TextColor3 = Color3.fromRGB(243, 244, 246)
distanceInput.TextSize = 12
Instance.new("UICorner", distanceInput).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", distanceInput).Color = Color3.fromRGB(39, 39, 42)

distanceInput.FocusLost:Connect(function()
    local val = tonumber(distanceInput.Text)
    if val then
        Aim_Settings.MaxDistance = val
    else
        distanceInput.Text = tostring(Aim_Settings.MaxDistance)
    end
end)

ui.CreateToggle("Wall Check", aimCategory, function(state)
    Aim_Settings.WallCheck = state
end)

ui.CreateToggle("Head Hitbox Expander", aimCategory, function(state)
    Aim_Settings.HitboxActive = state
end)

local espCategory = ui.CreateCategory("ESP Settings")

local boxT = ui.CreateToggle("Box ESP", espCategory, function(state) ESP_Settings.Box = state end)
AddColorPicker(boxT, ESP_Settings.BoxColor, function(c) ESP_Settings.BoxColor = c end)

local nameT = ui.CreateToggle("Names ESP", espCategory, function(state) ESP_Settings.Names = state end)
AddColorPicker(nameT, ESP_Settings.NamesColor, function(c) ESP_Settings.NamesColor = c end)

local hpT = ui.CreateToggle("HP ESP", espCategory, function(state) ESP_Settings.HP = state end)

local lineT = ui.CreateToggle("Line ESP", espCategory, function(state)
    if state and not ESP_Settings.Box then
        ShowWarning("Enable 'Box ESP' first!")
        ESP_Settings.Lines = false
        ForceDisableToggle(lineT)
        return
    end
    ESP_Settings.Lines = state
end)
AddColorPicker(lineT, ESP_Settings.LinesColor, function(c) ESP_Settings.LinesColor = c end)

local distT = ui.CreateToggle("Distance ESP", espCategory, function(state) ESP_Settings.Distance = state end)
AddColorPicker(distT, ESP_Settings.DistanceColor, function(c) ESP_Settings.DistanceColor = c end)

local function isTargetVisible(part, char)
    local origin = camera.CFrame.Position
    local direction = part.Position - origin
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {localPlayer.Character, camera}
    params.FilterType = Enum.RaycastFilterType.Exclude
    
    local result = workspace:Raycast(origin, direction, params)
    return not result or result.Instance:IsDescendantOf(char)
end

local function getClosestPlayerToCursor()
    local targetPlr, targetPart = nil, nil
    local shortestDistance = math.huge
    local mousePos = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)

    local myChar = localPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHrp then return nil, nil end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer and p.Character then
            local char = p.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            local part = char:FindFirstChild(Aim_Settings.TargetPart)

            if part and hum and hum.Health > 0 then
                local distToTarget = (myHrp.Position - part.Position).Magnitude
                if distToTarget <= Aim_Settings.MaxDistance then
                    if Aim_Settings.WallCheck and not isTargetVisible(part, char) then continue end

                    local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local mag = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        if mag < shortestDistance then
                            shortestDistance = mag
                            targetPlr = p
                            targetPart = part
                        end
                    end
                end
            end
        end
    end
    return targetPlr, targetPart
end

local function CreateESP(plr)
    local highlight = Instance.new("Highlight")
    highlight.Enabled = false
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Parent = ui.ScreenGui

    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 200, 0, 70)
    billboard.AlwaysOnTop = true
    billboard.Enabled = false
    billboard.MaxDistance = 5000
    billboard.Parent = ui.ScreenGui

    local nameL = Instance.new("TextLabel", billboard)
    nameL.Size = UDim2.new(1, 0, 0, 20)
    nameL.BackgroundTransparency = 1
    nameL.Font = Enum.Font.SourceSansBold
    nameL.TextSize = 16
    Instance.new("UIStroke", nameL).Color = Color3.new(1,1,1)

    local hpL = Instance.new("TextLabel", billboard)
    hpL.Size = UDim2.new(1, 0, 0, 20)
    hpL.Position = UDim2.new(0, 0, 0, -20)
    hpL.BackgroundTransparency = 1
    hpL.Font = Enum.Font.SourceSansBold
    hpL.TextSize = 14
    Instance.new("UIStroke", hpL).Color = Color3.new(1,1,1)

    local distL = Instance.new("TextLabel", billboard)
    distL.Size = UDim2.new(1, 0, 0, 20)
    distL.BackgroundTransparency = 1
    distL.Font = Enum.Font.SourceSansBold
    distL.TextSize = 14
    Instance.new("UIStroke", distL).Color = Color3.new(1,1,1)

    local lineFrame = Instance.new("Frame", ui.ScreenGui)
    lineFrame.BorderSizePixel = 0
    lineFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    lineFrame.ZIndex = 0
    lineFrame.Visible = false

    local renderConnection
    renderConnection = RunService.RenderStepped:Connect(function()
        if not scriptRunning then
            renderConnection:Disconnect()
            return
        end

        if not plr or not plr.Parent or not plr.Character then
            highlight.Enabled = false
            billboard.Enabled = false
            lineFrame.Visible = false
            return
        end

        local character = plr.Character
        local hrp = character:FindFirstChild("HumanoidRootPart")
        local head = character:FindFirstChild("Head")
        local hum = character:FindFirstChildOfClass("Humanoid")
        
        if head and head:IsA("BasePart") then
            if not originalHeadSizes[plr] then
                originalHeadSizes[plr] = {Size = head.Size, CanCollide = head.CanCollide}
            end
            
            if Aim_Settings.HitboxActive then
                head.Size = Vector3.new(Aim_Settings.HitboxSize, Aim_Settings.HitboxSize, Aim_Settings.HitboxSize)
                head.Transparency = 0.5
                head.CanCollide = false
            else
                head.Size = originalHeadSizes[plr].Size
                head.Transparency = 0
                head.CanCollide = originalHeadSizes[plr].CanCollide
            end
        end

        if not hrp or not hum or hum.Health <= 0 then
            highlight.Enabled = false
            billboard.Enabled = false
            lineFrame.Visible = false
            return
        end

        highlight.Adornee = character
        highlight.Enabled = ESP_Settings.Box
        highlight.FillColor = ESP_Settings.BoxColor

        billboard.Adornee = hrp
        billboard.Enabled = (ESP_Settings.Names or ESP_Settings.HP or ESP_Settings.Distance)
        
        local sizeOffset = (character:GetExtentsSize().Y / 2)
        billboard.StudsOffset = Vector3.new(0, sizeOffset + 1.5, 0)

        nameL.Visible = ESP_Settings.Names
        nameL.Text = plr.Name
        nameL.TextColor3 = ESP_Settings.NamesColor

        hpL.Visible = ESP_Settings.HP
        hpL.Text = "HP: " .. math.floor(hum.Health)
        hpL.TextColor3 = Color3.fromHSV(math.clamp(hum.Health/hum.MaxHealth, 0, 1) * 0.3, 1, 1)

        distL.Visible = ESP_Settings.Distance
        distL.TextColor3 = ESP_Settings.DistanceColor
        distL.Position = UDim2.new(0, 0, 0, 60) 
        
        local charDist = 0
        local myChar = localPlayer.Character
        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if myHrp then
            charDist = (myHrp.Position - hrp.Position).Magnitude
            distL.Text = math.floor(charDist) .. " studs"
        end

        if ESP_Settings.Lines and ESP_Settings.Box then
            local bottomPos = hrp.Position - Vector3.new(0, sizeOffset, 0)
            local pos, onScreen = camera:WorldToViewportPoint(bottomPos)
            if onScreen then
                lineFrame.Visible = true
                local startPos = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                local endPos = Vector2.new(pos.X, pos.Y)
                local diff = endPos - startPos
                lineFrame.Size = UDim2.new(0, diff.Magnitude, 0, 1)
                lineFrame.Position = UDim2.new(0, (startPos.X + endPos.X) / 2, 0, (startPos.Y + endPos.Y) / 2)
                lineFrame.Rotation = math.deg(math.atan2(diff.Y, diff.X))
                lineFrame.BackgroundColor3 = ESP_Settings.LinesColor
            else
                lineFrame.Visible = false
            end
        else
            lineFrame.Visible = false
        end
    end)
    trackConnection(renderConnection)
end

for _, p in ipairs(Players:GetPlayers()) do 
    if p ~= localPlayer then CreateESP(p) end 
end

trackConnection(Players.PlayerAdded:Connect(function(p) 
    if p ~= localPlayer then CreateESP(p) end 
end))

trackConnection(Players.PlayerRemoving:Connect(function(p)
    originalHeadSizes[p] = nil
end))

local oldRaycast
oldRaycast = hookfunction(workspace.Raycast, function(self, origin, direction, params)
    if scriptRunning and Aim_Settings.Enabled and Aim_Settings.SilentAim then
        local targetPlr, targetPart = getClosestPlayerToCursor()
        if targetPart then
            direction = (targetPart.Position - origin).Unit * direction.Magnitude
        end
    end
    return oldRaycast(self, origin, direction, params)
end)

local oldFindPartOnRay
oldFindPartOnRay = hookfunction(workspace.FindPartOnRay, function(self, ray, ignoreList, terrainCellsAreCubes, nonZeroVelocityConsideredMethod)
    if scriptRunning and Aim_Settings.Enabled and Aim_Settings.SilentAim then
        local targetPlr, targetPart = getClosestPlayerToCursor()
        if targetPart then
            ray = Ray.new(ray.Origin, (targetPart.Position - ray.Origin).Unit * ray.Direction.Magnitude)
        end
    end
    return oldFindPartOnRay(self, ray, ignoreList, terrainCellsAreCubes, nonZeroVelocityConsideredMethod)
end)

local oldFindPartOnRayWithIgnoreList
oldFindPartOnRayWithIgnoreList = hookfunction(workspace.FindPartOnRayWithIgnoreList, function(self, ray, ignoreList, terrainCellsAreCubes, nonZeroVelocityConsideredMethod)
    if scriptRunning and Aim_Settings.Enabled and Aim_Settings.SilentAim then
        local targetPlr, targetPart = getClosestPlayerToCursor()
        if targetPart then
            ray = Ray.new(ray.Origin, (targetPart.Position - ray.Origin).Unit * ray.Direction.Magnitude)
        end
    end
    return oldFindPartOnRayWithIgnoreList(self, ray, ignoreList, terrainCellsAreCubes, nonZeroVelocityConsideredMethod)
end)

local oldIndex
oldIndex = hookmetamethod(game, "__index", function(self, key)
    if scriptRunning and Aim_Settings.Enabled and Aim_Settings.SilentAim and self == mouse and (key == "Hit" or key == "Target") then
        local targetPlr, targetPart = getClosestPlayerToCursor()
        if targetPart then
            if key == "Hit" then
                return targetPart.CFrame
            elseif key == "Target" then
                return targetPart
            end
        end
    end
    return oldIndex(self, key)
end)

local aimConnection
aimConnection = RunService.RenderStepped:Connect(function()
    if not scriptRunning then
        aimConnection:Disconnect()
        return
    end

    if not Aim_Settings.Enabled then return end

    local targetPlr, targetPart = getClosestPlayerToCursor()
    if targetPart then
        local targetCFrame = CFrame.new(camera.CFrame.Position, targetPart.Position)
        camera.CFrame = camera.CFrame:Lerp(targetCFrame, Aim_Settings.Smoothness)
    end
end)
trackConnection(aimConnection)

ui.OpenFirstCategory()

ui.OnClose(function()
    scriptRunning = false
    
    Aim_Settings.Enabled = false
    Aim_Settings.HitboxActive = false
    for k in pairs(ESP_Settings) do ESP_Settings[k] = false end

    for _, conn in ipairs(connections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    table.clear(connections)

    for p, data in pairs(originalHeadSizes) do
        if p and p.Character
