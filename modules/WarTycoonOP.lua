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
local ui = uiModule.CreateUI("War Tycoon by Kiyatsuka | Version: 1.2.1 Bug Fixes.")

ui.SetMinimizedImage("108856686741748")

local mainCategory = uiModule.CreateCategory("Main")
local espCategory = uiModule.CreateCategory("ESP")
local players = game:GetService("Players")
local localPlayer = players.LocalPlayer
local cam = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local char, humanoid, hrp

local function getCharacter()
    if char and char.Parent then return char, humanoid, hrp end
    char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    humanoid = char:WaitForChild("Humanoid")
    hrp = char:WaitForChild("HumanoidRootPart")
    defaultWalkSpeed = humanoid.WalkSpeed
    defaultJumpPower = humanoid.JumpPower
    return char, humanoid, hrp
end

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
	Omega = Color3.fromRGB(255, 0, 255),
	Yankee = Color3.fromRGB(160, 160, 160)
}

local aimbotEnabled = false
local currentTarget = nil
local studs = 100
local switchAngle = 10
local smoothing = 0.1


local aimbotContainer = Instance.new("Frame")
aimbotContainer.Size = UDim2.new(1, -10, 0, 40)
aimbotContainer.BackgroundTransparency = 1
aimbotContainer.Parent = mainCategory

local aimbotToggle = uiModule.CreateToggle("Aimbot", aimbotContainer, function(state)
    aimbotEnabled = state
    if not state then currentTarget = nil end
end)
aimbotToggle.Size = UDim2.new(1, -140, 1, 0)

local distanceInput = Instance.new("TextBox")
distanceInput.Size = UDim2.new(0, 60, 0, 30)
distanceInput.Position = UDim2.new(1, -130, 0.5, -15)
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
        studs = 100
        distanceInput.Text = ""
    end
end)

local angleInput = Instance.new("TextBox")
angleInput.Size = UDim2.new(0, 60, 0, 30)
angleInput.Position = UDim2.new(1, -65, 0.5, -15)
angleInput.Text = ""
angleInput.PlaceholderText = "10°"
angleInput.TextColor3 = Color3.new(1, 1, 1)
angleInput.Font = Enum.Font.SourceSans
angleInput.TextSize = 16
angleInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Instance.new("UICorner", angleInput)
angleInput.Parent = aimbotContainer

angleInput.FocusLost:Connect(function()
    local val = tonumber(angleInput.Text)
    if val then
        switchAngle = val
    else
        switchAngle = 10
        angleInput.Text = ""
    end
end)

RunService.RenderStepped:Connect(function()
    if not aimbotEnabled then return end

    local char = localPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    local camDir = cam.CFrame.LookVector
    local camPos = cam.CFrame.Position

    if currentTarget and (not currentTarget.Parent or not currentTarget.Parent:FindFirstChild("Humanoid") 
        or currentTarget.Parent.Humanoid.Health <= 0 
        or (currentTarget.Position - char.HumanoidRootPart.Position).Magnitude > studs) then
        currentTarget = nil
    end

    local best, bestAngle = nil, math.rad(switchAngle)
    for _, plr in pairs(players:GetPlayers()) do
        if plr ~= localPlayer and plr.Character then
            local head = plr.Character:FindFirstChild("Head")
            local hum = plr.Character:FindFirstChild("Humanoid")
            if head and hum and hum.Health > 0 then
                local dir = (head.Position - camPos).Unit
                local angle = math.acos(math.clamp(camDir:Dot(dir), -1, 1))
                local dist = (head.Position - char.HumanoidRootPart.Position).Magnitude
                if dist < studs and angle < bestAngle then
                    best = head
                    bestAngle = angle
                end
            end
        end
    end

    if best and best ~= currentTarget then
        currentTarget = best
    end

    if currentTarget then
        local goal = CFrame.new(camPos, currentTarget.Position)
        cam.CFrame = cam.CFrame:Lerp(goal, smoothing)
    end
end)

local noFallEnabled = false
uiModule.CreateToggle("No Fall Damage", mainCategory, function(state)
    noFallEnabled = state
end)

RunService.Heartbeat:Connect(function()
    local _, h, r = getCharacter()
    if noFallEnabled and r then
        local velocity = r.Velocity
        if velocity.Y < -50 then
            local rayParams = RaycastParams.new()
            rayParams.FilterType = Enum.RaycastFilterType.Blacklist
            rayParams.FilterDescendantsInstances = {char}

            local result = workspace:Raycast(r.Position, Vector3.new(0, -10, 0), rayParams)
            if result and (r.Position.Y - result.Position.Y) <= 10 then
                r.Velocity = Vector3.new(velocity.X, -50, velocity.Z)
            end
        end
    end
end)

local speedHackEnabled, jumpHackEnabled, infinityJumpEnabled = false, false, false
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local localPlayer = game.Players.LocalPlayer
local defaultWalkSpeed, defaultJumpPower = 16, 50

local speedContainer = Instance.new("Frame")
speedContainer.Size = UDim2.new(1, -10, 0, 40)
speedContainer.BackgroundTransparency = 1
speedContainer.Parent = mainCategory

local speedToggle = uiModule.CreateToggle("Speed Hack", speedContainer, function(state)
    speedHackEnabled = state
    local _, h = getCharacter()
    if not state and h then
        h.WalkSpeed = defaultWalkSpeed
        speedInput.Text = tostring(defaultWalkSpeed)
    end
end)
speedToggle.Size = UDim2.new(1, -70, 1, 0)

local speedInput = Instance.new("TextBox")
speedInput.Size = UDim2.new(0, 60, 0, 30)
speedInput.Position = UDim2.new(1, -60, 0.5, -15)
speedInput.PlaceholderText = "Speed"
speedInput.TextColor3 = Color3.new(1,1,1)
speedInput.Font = Enum.Font.SourceSans
speedInput.TextSize = 16
speedInput.BackgroundColor3 = Color3.fromRGB(50,50,50)
Instance.new("UICorner", speedInput)
speedInput.Parent = speedContainer

task.spawn(function()
    local _, h = getCharacter()
    speedInput.Text = tostring(h and h.WalkSpeed or defaultWalkSpeed)
end)

speedInput.FocusLost:Connect(function()
    local _, h = getCharacter()
    local val = tonumber(speedInput.Text)
    if h then
        h.WalkSpeed = val or defaultWalkSpeed
        speedInput.Text = tostring(val or defaultWalkSpeed)
    end
end)

local jumpContainer = Instance.new("Frame")
jumpContainer.Size = UDim2.new(1, -10, 0, 40)
jumpContainer.BackgroundTransparency = 1
jumpContainer.Parent = mainCategory

local jumpToggle = uiModule.CreateToggle("Jump Hack", jumpContainer, function(state)
    jumpHackEnabled = state
    local _, h = getCharacter()
    if not state and h then
        h.JumpPower = defaultJumpPower
        jumpInput.Text = tostring(defaultJumpPower)
    end
end)
jumpToggle.Size = UDim2.new(1, -70, 1, 0)

local jumpInput = Instance.new("TextBox")
jumpInput.Size = UDim2.new(0, 60, 0, 30)
jumpInput.Position = UDim2.new(1, -60, 0.5, -15)
jumpInput.PlaceholderText = "Jump Power"
jumpInput.TextColor3 = Color3.new(1,1,1)
jumpInput.Font = Enum.Font.SourceSans
jumpInput.TextSize = 16
jumpInput.BackgroundColor3 = Color3.fromRGB(50,50,50)
Instance.new("UICorner", jumpInput)
jumpInput.Parent = jumpContainer

task.spawn(function()
    local _, h = getCharacter()
    jumpInput.Text = tostring(h and h.JumpPower or defaultJumpPower)
end)

jumpInput.FocusLost:Connect(function()
    local _, h = getCharacter()
    local val = tonumber(jumpInput.Text)
    if h then
        h.JumpPower = val or defaultJumpPower
        jumpInput.Text = tostring(val or defaultJumpPower)
    end
end)

uiModule.CreateToggle("Infinity Jump", mainCategory, function(state)
    infinityJumpEnabled = state
end)

UserInputService.JumpRequest:Connect(function()
    local _, h = getCharacter()
    if infinityJumpEnabled and h then
        h:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

RunService.RenderStepped:Connect(function()
    local _, h = getCharacter()
    if not h then return end
    if speedHackEnabled then
        local val = tonumber(speedInput.Text) or defaultWalkSpeed
        h.WalkSpeed = val
        speedInput.Text = tostring(val)
    end
    if jumpHackEnabled then
        local val = tonumber(jumpInput.Text) or defaultJumpPower
        h.JumpPower = val
        jumpInput.Text = tostring(val)
    end
end)

local wallbangEnabled = false
uiModule.CreateToggle("Fire Through Walls (Not worked)", mainCategory, function(state)
    wallbangEnabled = state
end)

local function customRaycast(origin, direction)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {char}
    if wallbangEnabled then
        params.IgnoreWater = true
        return workspace:Raycast(origin, direction * 10000, params)
    else
        return workspace:Raycast(origin, direction, params)
    end
end

local boxESPEnabled, nickESPEnabled, hpESPEnabled, distESPEnabled = false, false, false, false
uiModule.CreateToggle("Box ESP", espCategory, function(state) boxESPEnabled = state end)
uiModule.CreateToggle("Nick ESP", espCategory, function(state) nickESPEnabled = state end)
uiModule.CreateToggle("HP ESP", espCategory, function(state) hpESPEnabled = state end)
uiModule.CreateToggle("Distance ESP", espCategory, function(state) distESPEnabled = state end)

local espStorage = {}

local function addHighlight(model, color)
    if not model then return end
    local highlight = Instance.new("Highlight")
    highlight.Adornee = model
    highlight.FillColor = color or Color3.new(1, 0, 0)
    highlight.OutlineColor = color or Color3.new(1, 0, 0)
    highlight.FillTransparency = 0.7
    highlight.OutlineTransparency = 0
    highlight.Parent = game.CoreGui
    return highlight
end

local function getPlayerTeamColor(player)
    if not player:FindFirstChild("leaderstats") then return Color3.new(1,0,0) end
    local teamStat = player.leaderstats:FindFirstChild("Team")
    if not teamStat then return Color3.new(1,0,0) end
    return teamColors[teamStat.Value] or Color3.new(1,0,0)
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

    if player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Team") then
        player.leaderstats.Team.Changed:Connect(function()
            if espStorage[player] and espStorage[player].Highlight then
                espStorage[player].Highlight.FillColor = getPlayerTeamColor(player)
                espStorage[player].Highlight.OutlineColor = getPlayerTeamColor(player)
            end
        end)
    end
end

local function setupPlayerESP(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.1)
        createESP(player)
    end)
    if player.Character then
        createESP(player)
    end
end

players.PlayerAdded:Connect(setupPlayerESP)

for _, p in ipairs(players:GetPlayers()) do
    if p ~= localPlayer then
        setupPlayerESP(p)
    end
end

RunService.RenderStepped:Connect(function()
    for player, data in pairs(espStorage) do
        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then
            if data.Highlight then
                removeHighlight(data.Highlight)
                data.Highlight = nil
            end
            data.Billboard.Enabled = false
            continue
        end

        local hrp = char.HumanoidRootPart
        data.Billboard.Adornee = hrp
        data.Billboard.Enabled = nickESPEnabled or hpESPEnabled or distESPEnabled

        if boxESPEnabled then
            local color = getPlayerTeamColor(player)
            if not data.Highlight then
                data.Highlight = addHighlight(char, color)
            else
                data.Highlight.FillColor = color
                data.Highlight.OutlineColor = color
            end
        else
            if data.Highlight then
                removeHighlight(data.Highlight)
                data.Highlight = nil
            end
        end

        data.Billboard.Nick.Visible = nickESPEnabled
        data.Billboard.Nick.Text = player.Name

        if hpESPEnabled and char:FindFirstChild("Humanoid") then
            local humanoid = char.Humanoid
            local hpRatio = humanoid.Health / humanoid.MaxHealth
            data.Billboard.HP.Visible = true
            data.Billboard.HP.Size = UDim2.new(0.05, 0, math.clamp(hpRatio, 0.1, 1), 0)
            data.Billboard.HP.BackgroundColor3 =
                hpRatio > 0.5 and Color3.new(0, 1, 0) or
                hpRatio > 0.2 and Color3.new(1, 0.5, 0) or
                Color3.new(1, 0, 0)
        else
            data.Billboard.HP.Visible = false
        end

        if distESPEnabled and localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (hrp.Position - localPlayer.Character.HumanoidRootPart.Position).Magnitude
            data.Billboard.Dist.Visible = true
            data.Billboard.Dist.Text = math.floor(dist).." studs"
        else
            data.Billboard.Dist.Visible = false
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
