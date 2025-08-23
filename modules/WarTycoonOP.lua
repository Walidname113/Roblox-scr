local requiredGameId = 1526814825
if game.GameId ~= requiredGameId then return end

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
local ui = uiModule.CreateUI("War Tycoon by Kiyatsuka | Version: 1.1.7 optimization update")

local mainCategory = uiModule.CreateCategory("Main")
local espCategory = uiModule.CreateCategory("ESP")
local players = game:GetService("Players")
local localPlayer = players.LocalPlayer
local cam = workspace.CurrentCamera
local RunService = game:GetService("RunService")

local aimbotContainer = Instance.new("Frame")
aimbotContainer.Size = UDim2.new(1, -10, 0, 40)
aimbotContainer.BackgroundTransparency = 1
aimbotContainer.Parent = mainCategory

local aimbotToggle = uiModule.CreateToggle("Aimbot", aimbotContainer, function(state)
    aimbotEnabled = state
end)

aimbotToggle.Size = UDim2.new(1, -70, 1, 0)

local studs = 100

local distanceInput = Instance.new("TextBox")
distanceInput.Size = UDim2.new(0, 60, 0, 30)
distanceInput.Position = UDim2.new(1, -60, 0.5, -15)
distanceInput.Text = ""
distanceInput.PlaceholderText = "100 studs"
distanceInput.TextColor3 = Color3.new(1, 1, 1)
distanceInput.Font = Enum.Font.SourceSans
distanceInput.TextSize = 16
distanceInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Instance.new("UICorner", distanceInput)
distanceInput.Parent = aimbotContainer

distanceInput.FocusLost:Connect(function()
    local val = tonumber(distanceInput.Text)
    if val then
        studs = val
    else
        distanceInput.Text = ""
        studs = 100
    end
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
    nameLabel.TextSize = 15
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
    distLabel.Position = UDim2.new(0, 0, -0.20, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.TextColor3 = Color3.new(1, 1, 1)
    distLabel.TextScaled = false
    distLabel.Font = Enum.Font.SourceSansBold
    distLabel.TextSize = 10
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

RunService.RenderStepped:Connect(function()
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

local autoCollectEnabled = false
local autoCollectToggle = uiModule.CreateToggle("Auto Collect Drones", mainCategory, function(state)
    autoCollectEnabled = state
end)

spawn(function()
    local player = game.Players.LocalPlayer
    local teamName = player:WaitForChild("leaderstats"):WaitForChild("Team").Value
    local collectorPart = workspace:WaitForChild("Tycoon"):WaitForChild("Tycoons")
                            :WaitForChild(teamName)
                            :WaitForChild("PurchasedObjects")
                            :WaitForChild("Lab Terminal Screen")
                            :WaitForChild("Research Screen")
                            :WaitForChild("Collector")
    local collectorCFrameBase = collectorPart.CFrame + Vector3.new(0, 5, 0)

    while true do
        if autoCollectEnabled then
            local caches = workspace:WaitForChild("ResearchCaches")
            local targetModel = nil

            for _, model in pairs(caches:GetChildren()) do
                local prompt = model:FindFirstChild("Interact", true)
                if prompt and prompt.Enabled then
                    targetModel = model
                    break
                end
            end

            if targetModel then
                local function teleportTo(model)
                    local char = player.Character or player.CharacterAdded:Wait()
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    local targetCFrame = model.WorldPivot + Vector3.new(0, 5, 0)
                    if hrp then
                        hrp.CFrame = targetCFrame
                    else
                        char:PivotTo(targetCFrame)
                    end
                end

                teleportTo(targetModel)
                task.wait(0.1)
                teleportTo(targetModel)

                local prompt = targetModel:FindFirstChild("Interact", true)
                if not prompt then
                    repeat
                        local added = targetModel.DescendantAdded:Wait()
                        if added:IsA("ProximityPrompt") then
                            prompt = added
                        end
                    until prompt
                end

                while not (prompt.Enabled and prompt:IsDescendantOf(workspace)) do
                    task.wait()
                end

                task.wait(0.1)
                prompt.HoldDuration = 1
                prompt.MaxActivationDistance = 10
                fireproximityprompt(prompt, 1)

                local char = player.Character or player.CharacterAdded:Wait()
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local backOffset = Vector3.new(0, 0, 2)
                if hrp then
                    hrp.CFrame = collectorCFrameBase + backOffset
                else
                    char:PivotTo(collectorCFrameBase + backOffset)
                end

                task.wait(8)
            else
                task.wait(1)
            end
        else
            task.wait(0.1)
        end
    end
end)

uiModule.CreateButton("Remove nearby tycoon lasers", mainCategory, function()
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local localPlayer = Players.LocalPlayer
    if not localPlayer then return end
    local teamName = localPlayer:WaitForChild("leaderstats"):WaitForChild("Team").Value

    local function removeObstruction(obstruction)
        if obstruction and obstruction:IsA("BasePart") and (obstruction.Name == "Laser" or obstruction.Name == "OwnerOnly") then
            obstruction:Destroy()
        end
    end

    local function removeLaserRecursively(folder)
        for _, child in ipairs(folder:GetChildren()) do
            if child:IsA("BasePart") and (child.Name == "Laser" or child.Name == "OwnerOnly") then
                child:Destroy()
            elseif child:IsA("Folder") then
                removeLaserRecursively(child)
            end
        end
    end

    local function removeObstructionsForAllExcept(teamName)
        local tycoonsFolder = Workspace:WaitForChild("Tycoon"):WaitForChild("Tycoons")

        for _, tycoon in ipairs(tycoonsFolder:GetChildren()) do
            if tycoon.Name ~= teamName then
                local purchasedObjects = tycoon:FindFirstChild("PurchasedObjects")
                if purchasedObjects then
                    local doorsToCheck = {
                        {name = "Bunker Owner Only Door", partName = "Laser"},
                        {name = "Helicopter Hanger Owner Only Door", partName = "Laser"},
                        {name = "Owner Only Door 3rd Floor", partName = "Laser"},
                        {name = "Owner Only Door 3rd Floor Roof", partName = "Laser"},
                        {name = "Owner Only Door Balcony", partName = "Laser"},
                        {name = "Research Lab Owner Only Door", partName = "Laser"},
                        {name = "Plane Hanger Owner Only Door", partName = "Laser"},
                        {name = "Vehicle Bay Owner Only Gate", partName = "OwnerOnly"},
                        {name = "Vehicle Bay Owner Only Door2", partName = "Laser"},
                        {name = "OwnerOnlyDoor2", partName = "Laser"},
                        {name = "Tank Building Owner Only Gate", partName = "OwnerOnly"}
                    }

                    for _, doorInfo in ipairs(doorsToCheck) do
                        local door = purchasedObjects:FindFirstChild(doorInfo.name)
                        if door then
                            local obstruction = door:FindFirstChild(doorInfo.partName)
                            removeObstruction(obstruction)
                        end
                    end

                    local ownerOnlyDoor = purchasedObjects:FindFirstChild("OwnerOnlyDoor")
                    if ownerOnlyDoor then
                        removeLaserRecursively(ownerOnlyDoor)
                    end
                end
            end
        end
    end

    removeObstructionsForAllExcept(teamName)
end)

local tycoonESPEnabled = false
local tycoonESPStorage = {}
local localPlayer = game:GetService("Players").LocalPlayer
local tycoonsFolder = workspace:WaitForChild("Tycoon"):WaitForChild("Tycoons")

local teamColors = {
    Alpha = Color3.fromRGB(255, 0, 0),
    Bravo = Color3.fromRGB(255, 165, 0),
    Charlie = Color3.fromRGB(255, 255, 0),
    Delta = Color3.fromRGB(0, 255, 0),
    Echo = Color3.fromRGB(0, 100, 0),
    Foxtrot = Color3.fromRGB(0, 255, 255),
    Golf = Color3.fromRGB(0, 0, 255),
    Hotel = Color3.fromRGB(0, 0, 139),
    Juliet = Color3.fromRGB(0, 0, 80),
    Kilo = Color3.fromRGB(128, 0, 128),
    Lima = Color3.fromRGB(178, 102, 255),
    Sierra = Color3.fromRGB(255, 224, 189),
    Tango = Color3.fromRGB(139, 69, 19),
    Zulu = Color3.fromRGB(128, 128, 128),
	Romeo = Color3.fromRGB(245, 222, 179),
	Omega = Color3.fromRGB(255, 0, 255)
}

local function getAnyBasePart(tycoon)
    for _, part in ipairs(tycoon:GetDescendants()) do
        if part:IsA("BasePart") and part:IsDescendantOf(workspace) then
            return part
        end
    end
    return nil
end

local function createTycoonLabel(tycoon)
    if tycoonESPStorage[tycoon] then return end
    local basePart = getAnyBasePart(tycoon)
    if not basePart then return end

    local billboard = Instance.new("BillboardGui")
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 150, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 150, 0)
    billboard.Adornee = basePart
    billboard.Parent = game.CoreGui

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = teamColors[tycoon.Name] or Color3.new(1,1,1)
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextSize = 14
    nameLabel.TextScaled = true
    if localPlayer:FindFirstChild("leaderstats") and localPlayer.leaderstats:FindFirstChild("Team") then
        local playerTeam = localPlayer.leaderstats.Team.Value
        if tycoon.Name == playerTeam then
            nameLabel.Text = tycoon.Name.." (You)"
        else
            nameLabel.Text = tycoon.Name
        end
    else
        nameLabel.Text = tycoon.Name
    end
    nameLabel.Parent = billboard

    tycoonESPStorage[tycoon] = billboard
end

local function removeTycoonLabel(tycoon)
    if tycoonESPStorage[tycoon] then
        tycoonESPStorage[tycoon]:Destroy()
        tycoonESPStorage[tycoon] = nil
    end
end

uiModule.CreateToggle("Tycoons ESP", espCategory, function(state)
    tycoonESPEnabled = state
    if not state then
        for tycoon, _ in pairs(tycoonESPStorage) do
            removeTycoonLabel(tycoon)
        end
	else
        for _, tycoon in ipairs(tycoonsFolder:GetChildren()) do
            createTycoonLabel(tycoon)
        end
    end
end)

tycoonsFolder.ChildAdded:Connect(function(tycoon)
    if tycoonESPEnabled then
        createTycoonLabel(tycoon)
    end
end)
tycoonsFolder.ChildRemoved:Connect(function(tycoon)
    removeTycoonLabel(tycoon)
end)

local RunService = game:GetService("RunService")
local updateInterval = 0.3
local lastUpdate = 0

RunService.RenderStepped:Connect(function(delta)
    lastUpdate = lastUpdate + delta
    if lastUpdate < updateInterval then return end
    lastUpdate = 0

    if not tycoonESPEnabled then return end

    for tycoon, billboard in pairs(tycoonESPStorage) do
        local basePart = getAnyBasePart(tycoon)
        if basePart then
            billboard.Adornee = basePart
            billboard.Enabled = true
        else
            billboard.Enabled = false
        end
    end
end)

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local settingsContainer = ui.CreateCategory("Settings")
local localPlayer = Players.LocalPlayer

local banner = Instance.new("Frame")
banner.Size = UDim2.new(1, 0, 0, 70)
banner.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
banner.BackgroundTransparency = 0
banner.Parent = settingsContainer

local pfp = Instance.new("ImageLabel")
pfp.Size = UDim2.new(0, 50, 0, 50)
pfp.Position = UDim2.new(0, 10, 0.5, -25)
pfp.BackgroundTransparency = 1
pfp.Image = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=420&height=420&format=png", localPlayer.UserId)
pfp.Parent = banner

local uicorner = Instance.new("UICorner", pfp)
uicorner.CornerRadius = UDim.new(1, 0)

local nameLabel = Instance.new("TextLabel")
nameLabel.Position = UDim2.new(0, 70, 0, 10)
nameLabel.Size = UDim2.new(1, -80, 0, 20)
nameLabel.Text = localPlayer.DisplayName ~= localPlayer.Name and localPlayer.DisplayName or localPlayer.Name
nameLabel.TextColor3 = Color3.new(1, 1, 1)
nameLabel.BackgroundTransparency = 1
nameLabel.Font = Enum.Font.SourceSansBold
nameLabel.TextSize = 20
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.Parent = banner

if localPlayer.DisplayName ~= localPlayer.Name then
	local userLabel = Instance.new("TextLabel")
	userLabel.Position = UDim2.new(0, 70, 0, 35)
	userLabel.Size = UDim2.new(1, -80, 0, 15)
	userLabel.Text = "@" .. localPlayer.Name
	userLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	userLabel.BackgroundTransparency = 1
	userLabel.Font = Enum.Font.SourceSans
	userLabel.TextSize = 14
	userLabel.TextXAlignment = Enum.TextXAlignment.Left
	userLabel.Parent = banner
end

local function createSettingButton(text, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 30)
	btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Text = text
	btn.Font = Enum.Font.SourceSansBold
	btn.TextSize = 16
	btn.Parent = settingsContainer

	btn.MouseButton1Click:Connect(callback)
end

createSettingButton("Rejoin Server", function()
	TeleportService:Teleport(game.PlaceId, localPlayer)
end)

createSettingButton("Server Hop", function()
	local servers = {}
	local pages
	local success, err = pcall(function()
		pages = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
	end)
	if not success or not pages or not pages.data then return end

	for _, server in ipairs(pages.data) do
		if server.playing < server.maxPlayers and server.id ~= game.JobId then
			table.insert(servers, server.id)
		end
	end

	if #servers > 0 then
		local random = servers[math.random(1, #servers)]
		TeleportService:TeleportToPlaceInstance(game.PlaceId, random, localPlayer)
	end
end)

createSettingButton("Leave Server", function()
	localPlayer:Kick("You left the game.")
end)

ui.OpenFirstCategory()
