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

local function AddColorPicker(container, defaultValue, callback)
    local label = container:FindFirstChildOfClass("TextLabel")
    if label then
        label.Size = UDim2.new(1, -110, 1, 0)
    end

    local colorBtn = Instance.new("TextButton")
    colorBtn.Size = UDim2.new(0, 24, 0, 24)
    colorBtn.Position = UDim2.new(1, -85, 0.5, -12)
    colorBtn.BackgroundColor3 = defaultValue
    colorBtn.Text = ""
    colorBtn.BorderSizePixel = 1
    colorBtn.BorderColor3 = Color3.fromRGB(255,255,255)
    colorBtn.ZIndex = 10
    Instance.new("UICorner", colorBtn).CornerRadius = UDim.new(0, 4)
    colorBtn.Parent = container

    local menu = Instance.new("ScrollingFrame")
    menu.Size = UDim2.new(0, 100, 0, 150)
    menu.Position = UDim2.new(1, 10, 0, -50)
    menu.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    menu.Visible = false
    menu.ZIndex = 5000
    menu.CanvasSize = UDim2.new(0, 0, 0, #PresetColors * 30 + 35)
    menu.ScrollBarThickness = 4
    menu.Active = true
    Instance.new("UICorner", menu)
    menu.Parent = colorBtn

    local close = Instance.new("TextButton", menu)
    close.Size = UDim2.new(0, 25, 0, 25)
    close.Position = UDim2.new(1, -25, 0, 0)
    close.Text = "×"
    close.TextColor3 = Color3.new(1, 1, 1)
    close.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
    close.TextSize = 20
    close.ZIndex = 5002
    Instance.new("UICorner", close)

    local layout = Instance.new("UIListLayout", menu)
    layout.Padding = UDim.new(0, 5)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local headerSpacer = Instance.new("Frame", menu)
    headerSpacer.Size = UDim2.new(1, 0, 0, 25)
    headerSpacer.BackgroundTransparency = 1
    headerSpacer.LayoutOrder = -1

    local isScrolling = false
    menu:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        isScrolling = true
    end)

    for i, data in ipairs(PresetColors) do
        local btn = Instance.new("TextButton", menu)
        btn.Size = UDim2.new(0, 80, 0, 25)
        btn.BackgroundColor3 = data.c
        btn.Text = ""
        btn.ZIndex = 5001
        btn.LayoutOrder = i
        Instance.new("UICorner", btn)
        
        btn.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if isScrolling then 
                    isScrolling = false 
                    return 
                end
                colorBtn.BackgroundColor3 = data.c
                menu.Visible = false
                callback(data.c)
            end
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
    local highlight = Instance.new("Highlight")
    highlight.Enabled = false
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = Color3.new(1,1,1)
    highlight.Name = "ESP_Highlight"

    local nameTag = Instance.new("BillboardGui")
    nameTag.Size = UDim2.new(0, 200, 0, 50)
    nameTag.AlwaysOnTop = true
    nameTag.Enabled = false
    
    local nameLabel = Instance.new("TextLabel", nameTag)
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextSize = 18
    local nameStroke = Instance.new("UIStroke", nameLabel)
    nameStroke.Color = Color3.new(1, 1, 1)
    nameStroke.Thickness = 1

    local hpLabel = Instance.new("TextLabel", nameTag)
    hpLabel.Size = UDim2.new(1, 0, 0.5, 0)
    hpLabel.Position = UDim2.new(0, 0, -0.4, 0)
    hpLabel.BackgroundTransparency = 1
    hpLabel.Font = Enum.Font.SourceSansBold
    hpLabel.TextSize = 16
    hpLabel.TextColor3 = Color3.new(0, 1, 0)
    local hpStroke = Instance.new("UIStroke", hpLabel)
    hpStroke.Color = Color3.new(1, 1, 1)
    hpStroke.Thickness = 1

    local function updateElements()
        if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then 
            highlight.Enabled = false
            nameTag.Enabled = false
            return 
        end
        
        local char = plr.Character
        local hum = char:FindFirstChildOfClass("Humanoid")
        
        highlight.Parent = char
        highlight.Enabled = ESP_Settings.Box
        highlight.FillColor = ESP_Settings.BoxColor

        nameTag.Parent = char:FindFirstChild("Head") or char.HumanoidRootPart
        nameTag.Adornee = char:FindFirstChild("Head") or char.HumanoidRootPart
        nameTag.StudsOffset = Vector3.new(0, 2.5, 0)
        nameTag.Enabled = (ESP_Settings.Names or ESP_Settings.HP)

        nameLabel.Visible = ESP_Settings.Names
        nameLabel.Text = plr.Name
        nameLabel.TextColor3 = ESP_Settings.NamesColor

        if hum then
            hpLabel.Visible = ESP_Settings.HP
            hpLabel.Text = "HP: " .. math.floor(hum.Health)
        else
            hpLabel.Visible = false
        end
    end

    local conn = RunService.RenderStepped:Connect(function()
        if not plr or not plr.Parent then
            highlight:Destroy()
            nameTag:Destroy()
            return
        end
        updateElements()
    end)
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= localPlayer then CreateESP(p) end
end
Players.PlayerAdded:Connect(function(p)
    if p ~= localPlayer then CreateESP(p) end
end)

ui.OpenFirstCategory()
