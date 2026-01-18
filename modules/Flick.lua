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
local ui = uiModule.CreateUI("Flick by Kiyatsuka | Version: 1.0.1 Public.")
ui.SetMinimizedImage("97837481633367")

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

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

local PresetColors = {
    {n = "Red", c = Color3.fromRGB(255, 0, 0)},
    {n = "Green", c = Color3.fromRGB(0, 255, 0)},
    {n = "Blue", c = Color3.fromRGB(0, 150, 255)},
    {n = "Yellow", c = Color3.fromRGB(255, 255, 0)},
    {n = "Purple", c = Color3.fromRGB(170, 0, 255)},
    {n = "White", c = Color3.fromRGB(255, 255, 255)},
    {n = "Orange", c = Color3.fromRGB(255, 120, 0)},
    {n = "Cyan", c = Color3.fromRGB(0, 255, 255)}
}

-- Функция предупреждения
local function ShowWarning(text)
    local screenGui = ui.ScreenGui
    local warnFrame = Instance.new("Frame")
    warnFrame.Size = UDim2.new(0, 300, 0, 150)
    warnFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
    warnFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    warnFrame.BorderSizePixel = 0
    warnFrame.ZIndex = 10000
    Instance.new("UICorner", warnFrame)
    
    local stroke = Instance.new("UIStroke", warnFrame)
    stroke.Color = Color3.fromRGB(255, 0, 0)
    stroke.Thickness = 2

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
    btn.Position = UDim2.new(0.5, -60, 0.75, 0)
    btn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    btn.Text = "Understood"
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", btn)

    warnFrame.Parent = screenGui
    btn.MouseButton1Click:Connect(function() warnFrame:Destroy() end)
end

-- Исправленный выбор цвета (вынесен за пределы кнопок)
local function AddColorPicker(container, defaultValue, callback)
    local label = container:FindFirstChildOfClass("TextLabel")
    if label then label.Size = UDim2.new(1, -120, 1, 0) end

    local colorBtn = Instance.new("TextButton")
    colorBtn.Size = UDim2.new(0, 24, 0, 24)
    colorBtn.Position = UDim2.new(1, -85, 0.5, -12)
    colorBtn.BackgroundColor3 = defaultValue
    colorBtn.Text = ""
    colorBtn.BorderSizePixel = 1
    colorBtn.BorderColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", colorBtn).CornerRadius = UDim.new(0, 4)
    colorBtn.Parent = container

    local menu = Instance.new("ScrollingFrame")
    menu.Size = UDim2.new(0, 110, 0, 180)
    -- Позиционирование меню ПРАВЕЕ основного окна GUI
    menu.Position = UDim2.new(1, 190, 0, 0) 
    menu.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    menu.Visible = false
    menu.ZIndex = 5000
    menu.CanvasSize = UDim2.new(0, 0, 0, #PresetColors * 32 + 40)
    menu.ScrollBarThickness = 4
    Instance.new("UICorner", menu)
    menu.Parent = ui.MainFrame -- Привязка к главному фрейму для фиксации положения

    local close = Instance.new("TextButton", menu)
    close.Size = UDim2.new(0, 20, 0, 20)
    close.Position = UDim2.new(1, -25, 0, 5)
    close.Text = "×"
    close.TextColor3 = Color3.new(1,1,1)
    close.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    close.ZIndex = 5001
    Instance.new("UICorner", close)

    local layout = Instance.new("UIListLayout", menu)
    layout.Padding = UDim.new(0, 5)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local topSpacer = Instance.new("Frame", menu)
    topSpacer.Size = UDim2.new(1,0,0,30)
    topSpacer.BackgroundTransparency = 1
    topSpacer.LayoutOrder = 0

    local isScrolling = false
    menu:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        isScrolling = true
        task.delay(0.1, function() isScrolling = false end)
    end)

    for i, data in ipairs(PresetColors) do
        local btn = Instance.new("TextButton", menu)
        btn.Size = UDim2.new(0, 90, 0, 25)
        btn.BackgroundColor3 = data.c
        btn.Text = ""
        btn.ZIndex = 5001
        btn.LayoutOrder = i
        Instance.new("UICorner", btn)
        
        btn.MouseButton1Click:Connect(function()
            if not isScrolling then
                colorBtn.BackgroundColor3 = data.c
                menu.Visible = false
                callback(data.c)
            end
        end)
    end

    colorBtn.MouseButton1Click:Connect(function() menu.Visible = not menu.Visible end)
    close.MouseButton1Click:Connect(function() menu.Visible = false end)
end

local espCategory = ui.CreateCategory("ESP Settings")

-- Элементы управления
local boxT = ui.CreateToggle("Box ESP", espCategory, function(state)
    ESP_Settings.Box = state
end)
AddColorPicker(boxT, ESP_Settings.BoxColor, function(c) ESP_Settings.BoxColor = c end)

local nameT = ui.CreateToggle("Names ESP", espCategory, function(state)
    ESP_Settings.Names = state
end)
AddColorPicker(nameT, ESP_Settings.NamesColor, function(c) ESP_Settings.NamesColor = c end)

ui.CreateToggle("HP ESP", espCategory, function(state)
    ESP_Settings.HP = state
end)

local lineT = ui.CreateToggle("Line ESP", espCategory, function(state)
    if state and not ESP_Settings.Box then
        ShowWarning("You must enable 'Box ESP' first to use 'Line ESP'!")
        -- Здесь логика переключения тоггла обратно должна быть в модуле, 
        -- но мы принудительно выключаем тех. часть:
        ESP_Settings.Lines = false
        return
    end
    ESP_Settings.Lines = state
end)
AddColorPicker(lineT, ESP_Settings.LinesColor, function(c) ESP_Settings.LinesColor = c end)

local distT = ui.CreateToggle("Distance ESP", espCategory, function(state)
    ESP_Settings.Distance = state
end)
AddColorPicker(distT, ESP_Settings.DistanceColor, function(c) ESP_Settings.DistanceColor = c end)

-- Логика отрисовки
local function CreateESP(plr)
    local highlight = Instance.new("Highlight")
    highlight.Enabled = false
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Name = "ESP_H"

    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 200, 0, 100)
    billboard.AlwaysOnTop = true
    billboard.Enabled = false

    local nameL = Instance.new("TextLabel", billboard)
    nameL.Size = UDim2.new(1, 0, 0.3, 0)
    nameL.BackgroundTransparency = 1
    nameL.Font = Enum.Font.SourceSansBold
    nameL.TextSize = 18
    Instance.new("UIStroke", nameL).Color = Color3.new(1,1,1)

    local hpL = Instance.new("TextLabel", billboard)
    hpL.Size = UDim2.new(1, 0, 0.3, 0)
    hpL.Position = UDim2.new(0,0,-0.3,0)
    hpL.BackgroundTransparency = 1
    hpL.TextColor3 = Color3.new(0,1,0)
    hpL.Font = Enum.Font.SourceSansBold
    Instance.new("UIStroke", hpL).Color = Color3.new(1,1,1)

    local distL = Instance.new("TextLabel", billboard)
    distL.Size = UDim2.new(1, 0, 0.3, 0)
    distL.Position = UDim2.new(0,0,0.8,0) -- Под ногами/снизу
    distL.BackgroundTransparency = 1
    distL.Font = Enum.Font.SourceSansBold
    Instance.new("UIStroke", distL).Color = Color3.new(1,1,1)

    local lineFrame = Instance.new("Frame", ui.ScreenGui)
    lineFrame.BorderSizePixel = 0
    lineFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    lineFrame.Visible = false

    RunService.RenderStepped:Connect(function()
        if not plr or not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then
            highlight.Enabled = false
            billboard.Enabled = false
            lineFrame.Visible = false
            return
        end

        local char = plr.Character
        local hrp = char.HumanoidRootPart
        local hum = char:FindFirstChildOfClass("Humanoid")
        
        -- Box/Highlight
        highlight.Parent = char
        highlight.Enabled = ESP_Settings.Box
        highlight.FillColor = ESP_Settings.BoxColor

        -- Billboard (Names, HP, Distance)
        billboard.Parent = char:FindFirstChild("Head") or hrp
        billboard.Adornee = char:FindFirstChild("Head") or hrp
        billboard.Enabled = true
        
        nameL.Visible = ESP_Settings.Names
        nameL.Text = plr.Name
        nameL.TextColor3 = ESP_Settings.NamesColor

        hpL.Visible = ESP_Settings.HP
        hpL.Text = hum and "HP: "..math.floor(hum.Health) or ""

        distL.Visible = ESP_Settings.Distance
        distL.TextColor3 = ESP_Settings.DistanceColor
        local dist = (localPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
        distL.Text = math.floor(dist).." studs"

        -- Line ESP
        if ESP_Settings.Lines and ESP_Settings.Box then
            local pos, onScreen = camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                lineFrame.Visible = true
                local startPos = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                local endPos = Vector2.new(pos.X, pos.Y)
                local distance = (endPos - startPos).Magnitude
                
                lineFrame.Size = UDim2.new(0, distance, 0, 1)
                lineFrame.Position = UDim2.new(0, (startPos.X + endPos.X) / 2, 0, (startPos.Y + endPos.Y) / 2)
                lineFrame.Rotation = math.deg(math.atan2(endPos.Y - startPos.Y, endPos.X - startPos.X))
                lineFrame.BackgroundColor3 = ESP_Settings.LinesColor
            else
                lineFrame.Visible = false
            end
        else
            lineFrame.Visible = false
        end
    end)
end

for _, p in ipairs(Players:GetPlayers()) do if p ~= localPlayer then CreateESP(p) end end
Players.PlayerAdded:Connect(function(p) if p ~= localPlayer then CreateESP(p) end end)

ui.OpenFirstCategory()
