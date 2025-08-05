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
local ui = uiModule.CreateUI("War Tycoon by Kiyatsuka | Version: 1.0.0 Public")

local mainCategory = uiModule.CreateCategory("Main")
local espCategory = uiModule.CreateCategory("ESP")
local players = game:GetService("Players")
local localPlayer = players.LocalPlayer
local cam = workspace.CurrentCamera

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

local function createBillboard(player)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_"..player.Name
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(4, 0, 5, 0)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 20)
    nameLabel.Position = UDim2.new(0, 0, 0, -20)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextScaled = true
    nameLabel.Name = "Nick"
    nameLabel.Parent = billboard

    local hpBar = Instance.new("Frame")
    hpBar.Size = UDim2.new(0.1, 0, 1, 0)
    hpBar.Position = UDim2.new(1.05, 0, 0, 0)
    hpBar.BackgroundColor3 = Color3.new(0, 1, 0)
    hpBar.Name = "HP"
    hpBar.Parent = billboard

    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1, 0, 0, 20)
    distLabel.Position = UDim2.new(-0.3, 0, 0.5, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.TextColor3 = Color3.new(1, 1, 1)
    distLabel.TextScaled = true
    distLabel.Name = "Dist"
    distLabel.Parent = billboard

    espStorage[player] = billboard
end

local function removeBillboard(player)
    if espStorage[player] then
        espStorage[player]:Destroy()
        espStorage[player] = nil
    end
end

players.PlayerAdded:Connect(function(p)
    createBillboard(p)
end)

players.PlayerRemoving:Connect(function(p)
    removeBillboard(p)
end)

for _, p in ipairs(players:GetPlayers()) do
    if p ~= localPlayer then
        createBillboard(p)
    end
end

task.spawn(function()
    while task.wait() do
        if aimbotEnabled then
            local char = localPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local nearest, minDist = nil, studs
                for _, p in ipairs(players:GetPlayers()) do
                    if p ~= localPlayer and p.Character then
                        local targetHrp = p.Character:FindFirstChild("HumanoidRootPart")
                        local head = p.Character:FindFirstChild("Head")
                        if targetHrp and head then
                            local dist = (targetHrp.Position - hrp.Position).Magnitude
                            if dist <= studs and dist < minDist then
                                nearest, minDist = head, dist
                            end
                        end
                    end
                end
                if nearest then
                    cam.CFrame = CFrame.new(cam.CFrame.Position, nearest.Position)
                end
            end
        end

        for p, billboard in pairs(espStorage) do
            if p.Character and p.Character:FindFirstChild("Head") then
                billboard.Adornee = p.Character.Head
                billboard.Enabled = boxESPEnabled or nickESPEnabled or hpESPEnabled or distESPEnabled

                billboard.Nick.Visible = nickESPEnabled
                billboard.Nick.Text = p.Name

                if hpESPEnabled and p.Character:FindFirstChild("Humanoid") then
                    local hp = p.Character.Humanoid.Health / p.Character.Humanoid.MaxHealth
                    billboard.HP.Visible = true
                    billboard.HP.Size = UDim2.new(0.1, 0, hp, 0)
                    billboard.HP.BackgroundColor3 = hp > 0.5 and Color3.new(0, 1, 0) or hp > 0.2 and Color3.new(1, 0.5, 0) or Color3.new(1, 0, 0)
                else
                    billboard.HP.Visible = false
                end

                if distESPEnabled and p.Character:FindFirstChild("HumanoidRootPart") and localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = (p.Character.HumanoidRootPart.Position - localPlayer.Character.HumanoidRootPart.Position).Magnitude
                    billboard.Dist.Visible = true
                    billboard.Dist.Text = math.floor(dist).." studs"
                else
                    billboard.Dist.Visible = false
                end
            else
                billboard.Enabled = false
            end
        end
    end
end)

ui.OpenFirstCategory()
