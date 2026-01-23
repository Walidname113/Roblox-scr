local REQUIRED_GAME_ID = 8773050457
if game.GameId ~= REQUIRED_GAME_ID then return end

local uiurl = "https://raw.githubusercontent.com/Walidname113/Roblox-scr/main/uncoded.lua"
local success, source = pcall(function()
    return game:HttpGet(uiurl)
end)
if not success then return end

local moduleFunc = loadstring(source)
if not moduleFunc then return end

local uiModule = moduleFunc()
local ui = uiModule.CreateUI("SCP:RB by Kiyatsuka | Version: 1.3.3 Public.")
ui.SetMinimizedImage("130805202254686")

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local cam = workspace.CurrentCamera
local MAX_DISTANCE = 1200
local UPDATE_INTERVAL = 0.1

local highlights = {}
local billboards = {}
local healthGuis = {}
local teamSettings = {}
local espAllEnabled = false
local hpEspEnabled = false

local aimbotEnabled = false
local aimWallCheck = false
local aimTeamCheck = false
local currentTarget = nil
local studs = 100
local switchAngle = 10
local MIN_AIM_DISTANCE = 5

local teamRelations = {
    ["Class-D"] = {["Class-D"] = true, ["Chaos Insurgency"] = true},
    ["Foundation Personnel"] = {["Foundation Personnel"] = true, ["Security Department"] = true, ["Mobile Task Forces"] = true},
    ["Security Department"] = {["Foundation Personnel"] = true, ["Security Department"] = true, ["Mobile Task Forces"] = true},
    ["Mobile Task Forces"] = {["Foundation Personnel"] = true, ["Security Department"] = true, ["Mobile Task Forces"] = true},
    ["Chaos Insurgency"] = {["Class-D"] = true, ["Chaos Insurgency"] = true},
    ["Global Occult Coalition"] = {["Global Occult Coalition"] = true},
    ["Serpents Hand"] = {["Serpents Hand"] = true, ["SCP"] = true},
    ["SCP"] = {["Serpents Hand"] = true, ["SCP"] = true}
}

local function isAlly(player)
    if not localPlayer.Team or not player.Team then return false end
    local myTeamName = localPlayer.Team.Name
    local targetTeamName = player.Team.Name
    if teamRelations[myTeamName] and teamRelations[myTeamName][targetTeamName] then
        return true
    end
    return false
end

local function getCharacter()
    local c = localPlayer.Character
    if not c then return nil end
    return c, c:FindFirstChild("Humanoid"), c:FindFirstChild("HumanoidRootPart")
end

local function getHealthColor(perc)
    if perc >= 70 then
        return Color3.fromRGB(0, 255, 0):Lerp(Color3.fromRGB(255, 165, 0), (100 - perc) / 30)
    elseif perc >= 45 then
        return Color3.fromRGB(255, 165, 0):Lerp(Color3.fromRGB(255, 80, 80), (70 - perc) / 25)
    elseif perc >= 1 then
        return Color3.fromRGB(255, 80, 80):Lerp(Color3.fromRGB(139, 0, 0), (45 - perc) / 44)
    else
        return Color3.fromRGB(139, 0, 0):Lerp(Color3.fromRGB(0, 0, 0), 1 - (perc/1))
    end
end

local function isVisible(part)
    local origin = cam.CFrame.Position
    local direction = part.Position - origin
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {localPlayer.Character, cam}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(origin, direction, rayParams)
    return not result or result.Instance:IsDescendantOf(part.Parent)
end

local function cleanupPlayerEffects(player)
    if highlights[player] then highlights[player]:Destroy(); highlights[player] = nil end
    if billboards[player] then billboards[player]:Destroy(); billboards[player] = nil end
    if healthGuis[player] then healthGuis[player]:Destroy(); healthGuis[player] = nil end
end

local function createHealthESP(player, character)
    local head = character:FindFirstChild("Head")
    local hum = character:FindFirstChild("Humanoid")
    if not head or not hum or healthGuis[player] then return end

    local gui = Instance.new("BillboardGui")
    gui.Name = "HealthESP"
    gui.Adornee = head
    gui.Size = UDim2.new(0, 100, 0, 20)
    gui.StudsOffset = Vector3.new(0, 1.2, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = MAX_DISTANCE
    gui.Parent = head

    local label = Instance.new("TextLabel")
    label.Parent = gui
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Font = Enum.Font.Unknown
    label.FontFace = Font.new("rbxasset://fonts/families/PressStart2P.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    label.TextSize = 8
    label.TextStrokeTransparency = 0
    label.Text = ""
    
    healthGuis[player] = gui
end

local function create966Billboard(player, character)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp or billboards[player] then return end
    local scpTeam = Teams:FindFirstChild("SCP")
    local color = scpTeam and scpTeam.TeamColor.Color or Color3.new(1, 0, 0)
    local gui = Instance.new("BillboardGui")
    gui.Name = "SCP966ESP"
    gui.Size = UDim2.new(4, 0, 6, 0)
    gui.AlwaysOnTop = true
    gui.LightInfluence = 0
    gui.MaxDistance = 2000
    gui.Parent = hrp
    local container = Instance.new("Frame", gui)
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    local function mkPart(name, u1, u2, u3, u4)
        local p = Instance.new("Frame", container)
        p.Name = name
        p.BackgroundColor3 = color
        p.BorderSizePixel = 0
        p.BackgroundTransparency = 0.25
        p.Size = UDim2.fromScale(u1, u2)
        p.Position = UDim2.fromScale(u3, u4)
    end
    mkPart("Torso", 0.35, 0.50, 0.325, 0.25)
    mkPart("Head", 0.25, 0.20, 0.375, 0.05)
    mkPart("RightArm", 0.15, 0.45, 0.175, 0.275)
    mkPart("LeftArm", 0.15, 0.45, 0.675, 0.275)
    mkPart("RightLeg", 0.15, 0.50, 0.35, 0.55)
    mkPart("LeftLeg", 0.15, 0.50, 0.50, 0.55)
    local function line(x, y, w, h)
        local l = Instance.new("Frame", container)
        l.BackgroundColor3 = color
        l.BorderSizePixel = 0
        l.BackgroundTransparency = 0.10
        l.Size = UDim2.fromScale(w, h)
        l.Position = UDim2.fromScale(x, y)
    end
    line(0.325, 0.22, 0.35, 0.03)
    line(0.35, 0.50, 0.30, 0.03)
    line(0.425, 0.55, 0.05, 0.50)
    billboards[player] = gui
end

local function createHighlight(player, character)
    if highlights[player] then highlights[player]:Destroy() end
    
    local h = Instance.new("Highlight")
    h.Name = "PlayerHighlight"
    h.FillTransparency = 0.5
    h.OutlineTransparency = 0
    -- AlwaysOnTop гарантирует видимость сквозь стены
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop 
    h.Enabled = false
    
    local teamColor = player.Team and player.Team.TeamColor.Color or Color3.new(1, 1, 1)
    h.FillColor = teamColor
    h.OutlineColor = teamColor
    
    h.Adornee = character
    h.Parent = character
    highlights[player] = h
end

local function setupVisuals(player)
    local character = player.Character
    if not character or (player.Team and player.Team.Name == "Lobby") then 
        cleanupPlayerEffects(player)
        return 
    end
    
    createHealthESP(player, character)
    local role = player:GetAttribute("Role")
    if role == "SCP-966" then
        create966Billboard(player, character)
    else
        createHighlight(player, character)
    end
end

local mainCategory = ui.CreateCategory("Main")

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
Instance.new("UICorner", distanceInput).CornerRadius = UDim.new(0, 6)
distanceInput.Parent = aimbotContainer

distanceInput.FocusLost:Connect(function()
    local val = tonumber(distanceInput.Text)
    if val then studs = val else studs = 100 distanceInput.Text = "" end
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
Instance.new("UICorner", angleInput).CornerRadius = UDim.new(0, 6)
angleInput.Parent = angleInput.Parent or aimbotContainer

angleInput.FocusLost:Connect(function()
    local val = tonumber(angleInput.Text)
    if val then switchAngle = val else switchAngle = 10 angleInput.Text = "" end
end)

ui.CreateToggle("Wall check", mainCategory, function(state) aimWallCheck = state end)
ui.CreateToggle("Team check", mainCategory, function(state) aimTeamCheck = state end)

local espCategory = ui.CreateCategory("ESP")
ui.CreateToggle("ESP All (No Lobby)", espCategory, function(state) espAllEnabled = state end)
ui.CreateToggle("HP ESP", espCategory, function(state) hpEspEnabled = state end)

local targetTeams = {"Chaos Insurgency", "Serpents Hand", "Security Department", "Mobile Task Forces", "SCP", "Foundation Personnel", "Global Occult Coalition", "Class-D"}
for _, teamName in ipairs(targetTeams) do
    teamSettings[teamName] = false
    ui.CreateToggle("ESP " .. teamName .. " Team", espCategory, function(state) teamSettings[teamName] = state end)
end

ui.OpenFirstCategory()

local function onPlayerAdded(player)
    player.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        setupVisuals(player)
    end)
    player:GetPropertyChangedSignal("Team"):Connect(function()
        setupVisuals(player)
    end)
    if player.Character then setupVisuals(player) end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= localPlayer then onPlayerAdded(p) end
end
Players.PlayerRemoving:Connect(cleanupPlayerEffects)

RunService.RenderStepped:Connect(function()
    if not aimbotEnabled then return end
    local c, h, r = getCharacter()
    if not c or not r then return end
    local camCFrame = cam.CFrame
    local camDir = camCFrame.LookVector
    local camPos = camCFrame.Position

    if currentTarget then
        local targetDist = (currentTarget.Position - r.Position).Magnitude
        if not currentTarget.Parent or not currentTarget.Parent:FindFirstChild("Humanoid") 
            or currentTarget.Parent.Humanoid.Health <= 0 
            or targetDist > studs 
            or targetDist < MIN_AIM_DISTANCE
            or (aimWallCheck and not isVisible(currentTarget))
            or (aimTeamCheck and (isAlly(Players:GetPlayerFromCharacter(currentTarget.Parent)) or (Players:GetPlayerFromCharacter(currentTarget.Parent).Team and Players:GetPlayerFromCharacter(currentTarget.Parent).Team.Name == "Lobby"))) then
            currentTarget = nil
        end
    end

    local best, bestAngle = nil, math.rad(switchAngle)
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= localPlayer and plr.Character and plr.Team and plr.Team.Name ~= "Lobby" then
            local head = plr.Character:FindFirstChild("Head")
            local hum = plr.Character:FindFirstChild("Humanoid")
            if head and hum and hum.Health > 0 then
                local dist = (head.Position - r.Position).Magnitude
                if dist < studs and dist > MIN_AIM_DISTANCE then
                    if aimTeamCheck then
                        local plrTeam = plr.Team and plr.Team.Name
                        local myTeam = localPlayer.Team and localPlayer.Team.Name
                        if plrTeam == myTeam or isAlly(plr) then
                            continue
                        end
                    end
                    if aimWallCheck and not isVisible(head) then continue end
                    local dir = (head.Position - camPos).Unit
                    local angle = math.acos(math.clamp(camDir:Dot(dir), -1, 1))
                    if angle < bestAngle then
                        best = head
                        bestAngle = angle
                    end
                end
            end
        end
    end

    if best then
        currentTarget = best
    end
    if currentTarget then
        cam.CFrame = CFrame.new(cam.CFrame.Position, currentTarget.Position)
    end
end)

task.spawn(function()
    while true do
        local _, _, myRoot = getCharacter()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= localPlayer then
                local char = p.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChild("Humanoid")
                
                -- Если персонаж пересоздался, обновляем объекты
                if char and not (highlights[p] or billboards[p] or healthGuis[p]) then
                    setupVisuals(p)
                end

                local tName = p.Team and p.Team.Name or ""
                local isEspOn = (espAllEnabled or teamSettings[tName]) and tName ~= "Lobby"
                local inRange = myRoot and root and (myRoot.Position - root.Position).Magnitude <= MAX_DISTANCE

                if highlights[p] then
                    local h = highlights[p]
                    h.Enabled = isEspOn and inRange
                    if h.Enabled then
                        if h.Adornee ~= char then h.Adornee = char end
                        local teamColor = p.Team and p.Team.TeamColor.Color or Color3.new(1, 1, 1)
                        h.FillColor = teamColor
                        h.OutlineColor = teamColor
                    end
                end

                if billboards[p] then
                    billboards[p].Enabled = isEspOn and inRange
                end

                if healthGuis[p] then
                    local label = healthGuis[p]:FindFirstChildWhichIsA("TextLabel")
                    if hpEspEnabled and isEspOn and inRange and hum then
                        local perc = math.clamp(math.floor((hum.Health / hum.MaxHealth) * 100), 0, 100)
                        if label then
                            label.Text = "HP: " .. perc .. "%"
                            label.TextColor3 = getHealthColor(perc)
                        end
                        healthGuis[p].Enabled = true
                    else
                        healthGuis[p].Enabled = false
                    end
                end
            end
        end
        task.wait(UPDATE_INTERVAL)
    end
end)
