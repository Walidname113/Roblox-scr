local requiredGameId = 1526814825
if game.GameId ~= requiredGameId then return end

local uiurl = "https://raw.githubusercontent.com/Walidname113/Roblox-scr/main/uncoded.lua"
local success, source = pcall(function()
    return game:HttpGet(uiurl)
end)
if not success then warn("Error load UI:", source) return end
local moduleFunc, err = loadstring(source)
if not moduleFunc then warn("Error module func:", err) return end

local uiModule = moduleFunc()
local ui = uiModule.CreateUI("War Tycoon by Kiyatsuka | Version: 1.0.6 Public")

local mainCategory = uiModule.CreateCategory("Main")
local espCategory = uiModule.CreateCategory("ESP")
local players = game:GetService("Players")
local localPlayer = players.LocalPlayer
local cam = workspace.CurrentCamera
local RunService = game:GetService("RunService")

local studs = 100
local aimbotEnabled = false

local aimbotToggle = uiModule.CreateToggle("Aimbot", mainCategory, function(state)
    aimbotEnabled = state
end)

local distanceInput = Instance.new("TextBox")
distanceInput.Size = UDim2.new(0, 60, 0, 30)
distanceInput.Position = UDim2.new(1, -65, 0, 0)
distanceInput.Text = tostring(studs)
distanceInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
distanceInput.TextColor3 = Color3.new(1, 1, 1)
distanceInput.Font = Enum.Font.SourceSans
distanceInput.TextSize = 16
Instance.new("UICorner", distanceInput)
distanceInput.Parent = aimbotToggle
distanceInput.FocusLost:Connect(function()
    local val = tonumber(distanceInput.Text)
    if val then studs = val end
end)

local boxESPEnabled, nickESPEnabled, hpESPEnabled, distESPEnabled = false, false, false, false
uiModule.CreateToggle("Box ESP", espCategory, function(state) boxESPEnabled = state end)
uiModule.CreateToggle("Nick ESP", espCategory, function(state) nickESPEnabled = state end)
uiModule.CreateToggle("HP ESP", espCategory, function(state) hpESPEnabled = state end)
uiModule.CreateToggle("Distance ESP", espCategory, function(state) distESPEnabled = state end)

local espStorage = {}

local function addHighlight(model)
    if not model then return end
    local highlight = Instance.new("Highlight")
    highlight.Adornee = model
    highlight.FillColor = Color3.new(1, 0, 0)
    highlight.OutlineColor = Color3.new(1, 0, 0)
    highlight.FillTransparency = 0.7
    highlight.OutlineTransparency = 0
    highlight.Parent = game.CoreGui
    return highlight
end

local function removeHighlight(highlight)
    if highlight then highlight:Destroy() end
end

local function createESP(player)
    if espStorage[player] then
        espStorage[player].Billboard:Destroy()
        removeHighlight(espStorage[player].Highlight)
        espStorage[player] = nil
    end

    local billboard = Instance.new("BillboardGui")
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(4, 0, 5, 0)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.Adornee = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    billboard.Parent = game.CoreGui

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Nick"
    nameLabel.Size = UDim2.new(1, 0, 0, 15)
    nameLabel.Position = UDim2.new(0, 0, -0.4, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextScaled = false
    nameLabel.TextSize = 24
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.Parent = billboard

    local hpBar = Instance.new("Frame")
    hpBar.Name = "HP"
    hpBar.Size = UDim2.new(0.05, 0, 1, 0)
    hpBar.Position = UDim2.new(1.05, 0, 0, 0)
    hpBar.BackgroundColor3 = Color3.new(0, 1, 0)
    hpBar.BorderSizePixel = 0
    hpBar.Parent = billboard

    local distLabel = Instance.new("TextLabel")
    distLabel.Name = "Dist"
    distLabel.Size = UDim2.new(1, 0, 0, 25)
    distLabel.Position = UDim2.new(0, 0, -0.15, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.TextColor3 = Color3.new(1, 1, 1)
    distLabel.TextScaled = false
    distLabel.Font = Enum.Font.SourceSansBold
    distLabel.TextSize = 20
    distLabel.Parent = billboard

    espStorage[player] = {
        Billboard = billboard,
        Highlight = nil,
        HP = hpBar,
        Nick = nameLabel,
        Dist = distLabel
    }
end

local function setupPlayerESP(player)
    local function onCharacterAdded()
        task.wait(0.1)
        createESP(player)
    end
    player.CharacterAdded:Connect(onCharacterAdded)
    if player.Character then
        onCharacterAdded()
    end
end

players.PlayerAdded:Connect(function(p)
    if p ~= localPlayer then
        setupPlayerESP(p)
    end
end)

for _, p in ipairs(players:GetPlayers()) do
    if p ~= localPlayer then
        setupPlayerESP(p)
    end
end

local function isVisible(origin, target)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {localPlayer.Character}

    local direction = target.Position - origin
    local result = workspace:Raycast(origin, direction.Unit * direction.Magnitude, rayParams)

    if result then
        return result.Instance:IsDescendantOf(target.Parent)
    end
    return false
end

local function getBestTarget()
    if not localPlayer.Character or not localPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return nil
    end

    local origin = cam.CFrame.Position
    local bestTarget, bestDist = nil, studs

    for _, p in ipairs(players:GetPlayers()) do
        if p ~= localPlayer and p.Character and p.Character:FindFirstChild("Head") then
            local head = p.Character.Head
            local dist = (head.Position - localPlayer.Character.HumanoidRootPart.Position).Magnitude

            if dist <= studs and isVisible(origin, head) and dist < bestDist then
                bestTarget, bestDist = head, dist
            end
        end
    end

    return bestTarget
end

RunService.RenderStepped:Connect(function()
    if aimbotEnabled then
        local target = getBestTarget()
        if target then
            cam.CFrame = CFrame.new(cam.CFrame.Position, target.Position)
        end
    end

    for player, data in pairs(espStorage) do
        local billboard = data.Billboard
        local highlight = data.Highlight

        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            billboard.Adornee = player.Character.HumanoidRootPart
            billboard.Enabled = nickESPEnabled or hpESPEnabled or distESPEnabled

            if boxESPEnabled then
                if not highlight then
                    data.Highlight = addHighlight(player.Character)
                end
            else
                if highlight then
                    removeHighlight(highlight)
                    data.Highlight = nil
                end
            end

            billboard.Nick.Visible = nickESPEnabled
            billboard.Nick.Text = player.Name

            if hpESPEnabled and player.Character:FindFirstChild("Humanoid") then
                local humanoid = player.Character.Humanoid
                local hpRatio = humanoid.Health / humanoid.MaxHealth
                billboard.HP.Visible = true
                billboard.HP.Size = UDim2.new(0.05, 0, math.clamp(hpRatio, 0.1, 1), 0)
                billboard.HP.BackgroundColor3 =
                    hpRatio > 0.5 and Color3.new(0, 1, 0) or
                    hpRatio > 0.2 and Color3.new(1, 0.5, 0) or
                    Color3.new(1, 0, 0)
            else
                billboard.HP.Visible = false
            end

            if distESPEnabled and localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (player.Character.HumanoidRootPart.Position - localPlayer.Character.HumanoidRootPart.Position).Magnitude
                billboard.Dist.Visible = true
                billboard.Dist.Text = math.floor(dist) .. " studs"
                billboard.Dist.TextSize = 20
            else
                billboard.Dist.Visible = false
            end
        else
            billboard.Enabled = false
            if highlight then
                removeHighlight(highlight)
                data.Highlight = nil
            end
        end
    end
end)

local noclipEnabled = false
uiModule.CreateToggle("Noclip", mainCategory, function(state)
    noclipEnabled = state
end)

RunService.Stepped:Connect(function()
    if noclipEnabled and localPlayer.Character then
        for _, part in ipairs(localPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

ui.OpenFirstCategory()
