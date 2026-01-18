local REQUIRED_GAME_ID = 
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
local ui = uiModule.CreateUI("Flick by Kiyatsuka | Version: 1.0.0 Public.")
ui.SetMinimizedImage("97837481633367")

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

local ESP_Settings = {
    Box = false,
    BoxColor = Color3.fromRGB(255, 0, 0),
    Names = false,
    NamesColor = Color3.fromRGB(255, 0, 0),
    HP = false
}

local PresetColors = {
    {n = "Red", c = Color3.fromRGB(255, 0, 0)},
    {n = "Green", c = Color3.fromRGB(0, 255, 0)},
    {n = "Blue", c = Color3.fromRGB(0, 150, 255)},
    {n = "Yellow", c = Color3.fromRGB(255, 255, 0)},
    {n = "Purple", c = Color3.fromRGB(170, 0, 255)},
    {n = "White", c = Color3.fromRGB(255, 255, 255)},
    {n = "Orange", c = Color3.fromRGB(255, 120, 0)}
}

local function AddColorPicker(parent, defaultValue, callback)
    local colorBtn = Instance.new("TextButton")
    colorBtn.Size = UDim2.new(0, 24, 0, 24)
    colorBtn.Position = UDim2.new(1, -75, 0.5, -12)
    colorBtn.BackgroundColor3 = defaultValue
    colorBtn.Text = ""
    colorBtn.BorderSizePixel = 1
    colorBtn.BorderColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", colorBtn).CornerRadius = UDim.new(0, 4)
    colorBtn.Parent = parent

    local menu = Instance.new("ScrollingFrame")
    menu.Size = UDim2.new(0, 100, 0, 150)
    menu.Position = UDim2.new(1, 10, 0, 0)
    menu.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    menu.Visible = false
    menu.ZIndex = 5000
    menu.CanvasSize = UDim2.new(0, 0, 0, #PresetColors * 30 + 30)
    menu.ScrollBarThickness = 4
    Instance.new("UICorner", menu)
    menu.Parent = colorBtn

    local close = Instance.new("TextButton", menu)
    close.Size = UDim2.new(0, 20, 0, 20)
    close.Position = UDim2.new(1, -25, 0, 5)
    close.Text = "×"
    close.TextColor3 = Color3.new(1,0,0)
    close.BackgroundTransparency = 1
    close.TextSize = 20
    close.ZIndex = 5001

    local layout = Instance.new("UIListLayout", menu)
    layout.Padding = UDim.new(0, 2)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local isScrolling = false
    menu.CanvasPosition = Vector2.new(0,0)
    menu:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        isScrolling = true
        task.delay(0.1, function() isScrolling = false end)
    end)

    for _, data in ipairs(PresetColors) do
        local btn = Instance.new("TextButton", menu)
        btn.Size = UDim2.new(0, 80, 0, 25)
        btn.BackgroundColor3 = data.c
        btn.Text = ""
        btn.ZIndex = 5001
        Instance.new("UICorner", btn)
        
        btn.MouseButton1Click:Connect(function()
            if isScrolling then return end
            colorBtn.BackgroundColor3 = data.c
            menu.Visible = false
            callback(data.c)
        end)
    end

    colorBtn.MouseButton1Click:Connect(function()
        menu.Visible = not menu.Visible
    end)
    close.MouseButton1Click:Connect(function()
        menu.Visible = false
    end)
end

local espCategory = ui.CreateCategory("ESP Settings")

local boxToggle = ui.CreateToggle("Box ESP", espCategory, function(state)
    ESP_Settings.Box = state
end)
AddColorPicker(boxToggle, ESP_Settings.BoxColor, function(c) ESP_Settings.BoxColor = c end)

local nameToggle = ui.CreateToggle("Names ESP", espCategory, function(state)
    ESP_Settings.Names = state
end)
AddColorPicker(nameToggle, ESP_Settings.NamesColor, function(c) ESP_Settings.NamesColor = c end)

ui.CreateToggle("HP ESP", espCategory, function(state)
    ESP_Settings.HP = state
end)

local function CreateESP(plr)
    local drawing = {}
    
    drawing.Box = Instance.new("Frame")
    drawing.Box.BackgroundTransparency = 0.6
    drawing.Box.BorderSizePixel = 1
    drawing.Box.Visible = false
    
    drawing.NameTag = Instance.new("TextLabel")
    drawing.NameTag.BackgroundTransparency = 1
    drawing.NameTag.Font = Enum.Font.SourceSansBold
    drawing.NameTag.TextSize = 16
    drawing.NameTag.Visible = false
    local stroke = Instance.new("UIStroke", drawing.NameTag)
    stroke.Color = Color3.new(1,1,1)
    stroke.Thickness = 1
    
    drawing.HPText = Instance.new("TextLabel")
    drawing.HPText.BackgroundTransparency = 1
    drawing.HPText.TextColor3 = Color3.fromRGB(0, 255, 0)
    drawing.HPText.Font = Enum.Font.SourceSansBold
    drawing.HPText.TextSize = 14
    drawing.HPText.Visible = false

    local screenGui = ui.ScreenGui
    drawing.Box.Parent = screenGui
    drawing.NameTag.Parent = screenGui
    drawing.HPText.Parent = screenGui

    local updater
    updater = RunService.RenderStepped:Connect(function()
        if not plr or not plr.Parent or not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then
            drawing.Box.Visible = false
            drawing.NameTag.Visible = false
            drawing.HPText.Visible = false
            if not plr or not plr.Parent then updater:Disconnect() end
            return
        end

        local char = plr.Character
        local hrp = char.HumanoidRootPart
        local hum = char:FindFirstChildOfClass("Humanoid")
        local pos, onScreen = camera:WorldToViewportPoint(hrp.Position)

        if onScreen then
            local sizeX = 2000 / pos.Z
            local sizeY = 3500 / pos.Z
            
            if ESP_Settings.Box then
                drawing.Box.Visible = true
                drawing.Box.Size = UDim2.new(0, sizeX, 0, sizeY)
                drawing.Box.Position = UDim2.new(0, pos.X - sizeX/2, 0, pos.Y - sizeY/2)
                drawing.Box.BackgroundColor3 = ESP_Settings.BoxColor
                drawing.Box.BorderColor3 = Color3.new(1,1,1)
            else
                drawing.Box.Visible = false
            end

            if ESP_Settings.Names then
                drawing.NameTag.Visible = true
                drawing.NameTag.Text = plr.Name
                drawing.NameTag.TextColor3 = ESP_Settings.NamesColor
                drawing.NameTag.Position = UDim2.new(0, pos.X - 50, 0, pos.Y - (sizeY/2) - 25)
                drawing.NameTag.Size = UDim2.new(0, 100, 0, 20)
            else
                drawing.NameTag.Visible = false
            end
        
            if ESP_Settings.HP and hum then
                drawing.HPText.Visible = true
                drawing.HPText.Text = "HP: " .. math.floor(hum.Health)
                drawing.HPText.Position = UDim2.new(0, pos.X - 50, 0, pos.Y - (sizeY/2) - 40)
                drawing.HPText.Size = UDim2.new(0, 100, 0, 20)
            else
                drawing.HPText.Visible = false
            end
        else
            drawing.Box.Visible = false
            drawing.NameTag.Visible = false
            drawing.HPText.Visible = false
        end
    end)
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= localPlayer then CreateESP(p) end
end
Players.PlayerAdded:Connect(function(p)
    if p ~= localPlayer then CreateESP(p) end
end)

ui.OpenFirstCategory()
