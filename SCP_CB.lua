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
local ui = uiModule.CreateUI("SCP:RB by Kiyatsuka | Version: 1.5.1 Safe")
ui.SetMinimizedImage("130805202254686")

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local cam = Workspace.CurrentCamera
local MAX_DISTANCE = 600
local UPDATE_INTERVAL = 0.1

local SafeContainer = Instance.new("Folder")
SafeContainer.Name = "EspContainer_" .. math.random(1000,9999)
SafeContainer.Parent = CoreGui

local VisualsCache = {}
local teamSettings = {}
local espAllEnabled = false
local hpEspEnabled = false
local distEspEnabled = false

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

local function getBestPart(character)
    return character:FindFirstChild("Head") 
        or character:FindFirstChild("HumanoidRootPart") 
        or character:FindFirstChild("Torso") 
        or character:FindFirstChild("UpperTorso")
        or character.PrimaryPart
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
    local result = Workspace:Raycast(origin, direction, rayParams)
    return not result or result.Instance:IsDescendantOf(part.Parent)
end

local function GetPlayerVisuals(player)
    if VisualsCache[player] then return VisualsCache[player] end

    local visuals = {
        Highlight = nil,
        InfoGui = nil,
        SkeletonGui = nil,
        Labels = {}
    }

    local h = Instance.new("Highlight")
    h.Name = "H_" .. player.Name
    h.FillTransparency = 0.5
    h.OutlineTransparency = 0
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Enabled = false
    h.Parent = SafeContainer
    visuals.Highlight = h

    local infoGui = Instance.new("BillboardGui")
    infoGui.Name = "I_" .. player.Name
    infoGui.Size = UDim2.new(0, 150, 0, 50)
    infoGui.StudsOffset = Vector3.new(0, 3, 0)
    infoGui.AlwaysOnTop = true
    infoGui.Enabled = false
    infoGui.Parent = SafeContainer

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Parent = infoGui

    local layout = Instance.new("UIListLayout")
    layout.Parent = container
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom

    local customFont = Font.new("rbxasset://fonts/families/PressStart2P.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)

    local distLabel = Instance.new("TextLabel")
    distLabel.BackgroundTransparency = 1
    distLabel.Size = UDim2.new(1, 0, 0, 15)
    distLabel.FontFace = customFont
    distLabel.TextSize = 8
    distLabel.TextColor3 = Color3.new(1, 1, 1)
    distLabel.TextStrokeTransparency = 0
    distLabel.LayoutOrder = 1
    distLabel.Parent = container
    visuals.Labels.Dist = distLabel

    local hpLabel = Instance.new("TextLabel")
    hpLabel.BackgroundTransparency = 1
    hpLabel.Size = UDim2.new(1, 0, 0, 15)
    hpLabel.FontFace = customFont
    hpLabel.TextSize = 8
    hpLabel.TextStrokeTransparency = 0
    hpLabel.LayoutOrder = 2
    hpLabel.Parent = container
    visuals.Labels.HP = hpLabel
    
    visuals.InfoGui = infoGui

    local skelGui = Instance.new("BillboardGui")
    skelGui.Name = "S_" .. player.Name
    skelGui.Size = UDim2.new(4, 0, 6, 0)
    skelGui.AlwaysOnTop = true
    skelGui.Enabled = false
    skelGui.Parent = SafeContainer
    
    local skelContainer = Instance.new("Frame", skelGui)
    skelContainer.Size = UDim2.new(1, 0, 1, 0)
    skelContainer.BackgroundTransparency = 1
    
    local p = Instance.new("Frame", skelContainer)
    p.BackgroundTransparency = 0.5
    p.BorderSizePixel = 0
    p.Size = UDim2.fromScale(0.5, 0.5)
    p.Position = UDim2.fromScale(0.25, 0.25)
    
    visuals.SkeletonGui = skelGui
    visuals.SkeletonPart = p

    VisualsCache[player] = visuals
    return visuals
end

local function ClearVisuals(player)
    if VisualsCache[player] then
        local v = VisualsCache[player]
        if v.Highlight then v.Highlight:Destroy() end
        if v.InfoGui then v.InfoGui:Destroy() end
        if v.SkeletonGui then v.SkeletonGui:Destroy() end
        VisualsCache[player] = nil
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
distanceInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
distanceInput.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", distanceInput).CornerRadius = UDim.new(0, 6)
distanceInput.Parent = aimbotContainer
distanceInput.FocusLost:Connect(function()
    studs = tonumber(distanceInput.Text) or 100
end)

local angleInput = Instance.new("TextBox")
angleInput.Size = UDim2.new(0, 60, 0, 30)
angleInput.Position = UDim2.new(1, -65, 0.5, -15)
angleInput.Text = ""
angleInput.PlaceholderText = "10°"
angleInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
angleInput.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", angleInput).CornerRadius = UDim.new(0, 6)
angleInput.Parent = aimbotContainer
angleInput.FocusLost:Connect(function()
    switchAngle = tonumber(angleInput.Text) or 10
end)

ui.CreateToggle("Wall check", mainCategory, function(state) aimWallCheck = state end)
ui.CreateToggle("Team check", mainCategory, function(state) aimTeamCheck = state end)

local espCategory = ui.CreateCategory("ESP")
ui.CreateToggle("ESP All (No Lobby)", espCategory, function(state) espAllEnabled = state end)
ui.CreateToggle("HP ESP", espCategory, function(state) hpEspEnabled = state end)
ui.CreateToggle("Distance ESP", espCategory, function(state) distEspEnabled = state end)

local targetTeams = {"Chaos Insurgency", "Serpents Hand", "Security Department", "Mobile Task Forces", "SCP", "Foundation Personnel", "Global Occult Coalition", "Class-D"}
for _, teamName in ipairs(targetTeams) do
    teamSettings[teamName] = false
    ui.CreateToggle("ESP " .. teamName .. " Team", espCategory, function(state) teamSettings[teamName] = state end)
end

ui.OpenFirstCategory()

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= localPlayer then GetPlayerVisuals(p) end
end
Players.PlayerRemoving:Connect(ClearVisuals)

RunService.RenderStepped:Connect(function()
    if not aimbotEnabled then return end
    local c, h, r = getCharacter()
    if not c or not r then return end
    local camPos = cam.CFrame.Position
    local camDir = cam.CFrame.LookVector

    if currentTarget then
        local targetRoot = currentTarget.Parent and (currentTarget.Parent:FindFirstChild("HumanoidRootPart") or currentTarget.Parent.PrimaryPart)
        if not targetRoot then currentTarget = nil return end
        
        local dist = (targetRoot.Position - r.Position).Magnitude
        if not currentTarget.Parent or not currentTarget.Parent:FindFirstChild("Humanoid") 
            or currentTarget.Parent.Humanoid.Health <= 0 
            or dist > studs 
            or dist < MIN_AIM_DISTANCE
            or (aimWallCheck and not isVisible(currentTarget)) then
            currentTarget = nil
        end
    end

    local best, bestAngle = nil, math.rad(switchAngle)
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= localPlayer and plr.Character and plr.Team and plr.Team.Name ~= "Lobby" then
            local targetPart = getBestPart(plr.Character)
            local hum = plr.Character:FindFirstChild("Humanoid")
            if targetPart and hum and hum.Health > 0 then
                if aimTeamCheck and isAlly(plr) then continue end
                local dist = (targetPart.Position - r.Position).Magnitude
                if dist < studs and dist > MIN_AIM_DISTANCE then
                    if aimWallCheck and not isVisible(targetPart) then continue end
                    local dir = (targetPart.Position - camPos).Unit
                    local angle = math.acos(math.clamp(camDir:Dot(dir), -1, 1))
                    if angle < bestAngle then
                        best = targetPart
                        bestAngle = angle
                    end
                end
            end
        end
    end
    if best then currentTarget = best end
    if currentTarget then cam.CFrame = CFrame.new(cam.CFrame.Position, currentTarget.Position) end
end)

task.spawn(function()
    while true do
        local _, _, myRoot = getCharacter()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= localPlayer then
                local char = p.Character
                local visuals = GetPlayerVisuals(p)
                local root = char and getBestPart(char)
                local hum = char and char:FindFirstChild("Humanoid")
                local tName = p.Team and p.Team.Name or ""
                local isEspOn = (espAllEnabled or teamSettings[tName]) and tName ~= "Lobby"
                local dist = (myRoot and root) and (myRoot.Position - root.Position).Magnitude or 99999
                local inRange = dist <= MAX_DISTANCE
                local shouldShow = isEspOn and inRange and root and hum and hum.Health > 0

                if visuals.Highlight then
                    visuals.Highlight.Enabled = shouldShow
                    if shouldShow then
                        visuals.Highlight.Adornee = char
                        local teamColor = p.Team and p.Team.TeamColor.Color or Color3.new(1, 1, 1)
                        visuals.Highlight.FillColor = teamColor
                        visuals.Highlight.OutlineColor = teamColor
                    end
                end

                if visuals.InfoGui then
                    visuals.InfoGui.Enabled = shouldShow and (hpEspEnabled or distEspEnabled)
                    if visuals.InfoGui.Enabled then
                        visuals.InfoGui.Adornee = root
                        if hpEspEnabled then
                            local perc = math.clamp(math.floor((hum.Health / hum.MaxHealth) * 100), 0, 100)
                            visuals.Labels.HP.Text = "HP: " .. perc .. "%"
                            visuals.Labels.HP.TextColor3 = getHealthColor(perc)
                            visuals.Labels.HP.Visible = true
                        else
                            visuals.Labels.HP.Visible = false
                        end
                        if distEspEnabled then
                            visuals.Labels.Dist.Text = "Dist: " .. math.floor(dist) .. " studs"
                            visuals.Labels.Dist.Visible = true
                        else
                            visuals.Labels.Dist.Visible = false
                        end
                    end
                end

                local role = p:GetAttribute("Role")
                if visuals.SkeletonGui then
                    if role == "SCP-966" and shouldShow then
                        visuals.SkeletonGui.Enabled = true
                        visuals.SkeletonGui.Adornee = root
                        local scpColor = Teams["SCP"] and Teams["SCP"].TeamColor.Color or Color3.new(1,0,0)
                        visuals.SkeletonPart.BackgroundColor3 = scpColor
                    else
                        visuals.SkeletonGui.Enabled = false
                    end
                end
            end
        end
        task.wait(UPDATE_INTERVAL)
    end
end)
