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
local ui = uiModule.CreateUI("SCP:RB by Kiyatsuka | Version: 1.4.0 Beta")
ui.SetMinimizedImage("130805202254686")

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local cam = workspace.CurrentCamera
local MAX_DISTANCE = 1200
local UPDATE_INTERVAL = 0.1

local highlights = {}
local billboards = {}
local infoGuis = {}

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
    local result = workspace:Raycast(origin, direction, rayParams)
    return not result or result.Instance:IsDescendantOf(part.Parent)
end

local function cleanupPlayerEffects(player)
    if highlights[player] then highlights[player]:Destroy(); highlights[player] = nil end
    if billboards[player] then billboards[player]:Destroy(); billboards[player] = nil end
    if infoGuis[player] then infoGuis[player]:Destroy(); infoGuis[player] = nil end
end

local function createInfoESP(player, character)
    if infoGuis[player] then infoGuis[player]:Destroy() end
    
    local adorneePart = getBestPart(character)
    if not adorneePart then return end

    local gui = Instance.new("BillboardGui")
    gui.Name = "InfoESP"
    gui.Adornee = adorneePart
    gui.Size = UDim2.new(0, 100, 0, 50)
    gui.StudsOffset = Vector3.new(0, 2.5, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = MAX_DISTANCE
    gui.Parent = adorneePart

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Parent = gui

    local layout = Instance.new("UIListLayout")
    layout.Parent = container
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    
    local distLabel = Instance.new("TextLabel")
    distLabel.Name = "DistanceLabel"
    distLabel.Parent = container
    distLabel.BackgroundTransparency = 1
    distLabel.Size = UDim2.new(1, 0, 0, 15)
    distLabel.Font = Enum.Font.Unknown
    distLabel.FontFace = Font.new("rbxasset://fonts/families/PressStart2P.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    distLabel.TextSize = 8
    distLabel.TextColor3 = Color3.new(1, 1, 1)
    distLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    distLabel.TextStrokeTransparency = 0
    distLabel.Text = ""
    distLabel.LayoutOrder = 1
    distLabel.Visible = false

    local hpLabel = Instance.new("TextLabel")
    hpLabel.Name = "HPLabel"
    hpLabel.Parent = container
    hpLabel.BackgroundTransparency = 1
    hpLabel.Size = UDim2.new(1, 0, 0, 15)
    hpLabel.Font = Enum.Font.Unknown
    hpLabel.FontFace = Font.new("rbxasset://fonts/families/PressStart2P.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    hpLabel.TextSize = 8
    hpLabel.TextStrokeTransparency = 0
    hpLabel.Text = ""
    hpLabel.LayoutOrder = 2
    hpLabel.Visible = false
    
    infoGuis[player] = gui
end

local function create966Billboard(player, character)
    local hrp = getBestPart(character)
    if not hrp or billboards[player] then return end
    
    local scpTeam = Teams:FindFirstChild("SCP")
    local color = scpTeam and scpTeam.TeamColor.Color or Color3.new(1, 0, 0)
    local gui = Instance.new("BillboardGui")
    gui.Name = "SCP966ESP"
    gui.Size = UDim2.new(4, 0, 6, 0)
    gui.AlwaysOnTop = true
    gui.LightInfluence = 0
    gui.MaxDistance = 1200
    gui.Parent = hrp
    local container = Instance.new("Frame", gui)
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    billboards[player] = gui
    
    local function mkPart(u1, u2, u3, u4)
        local p = Instance.new("Frame", container)
        p.BackgroundColor3 = color
        p.BorderSizePixel = 0
        p.BackgroundTransparency = 0.5
        p.Size = UDim2.fromScale(u1, u2)
        p.Position = UDim2.fromScale(u3, u4)
    end
    mkPart(0.5, 0.5, 0.25, 0.25)
end

local function createHighlight(player, character)
    if highlights[player] then highlights[player]:Destroy() end
    
    local h = Instance.new("Highlight")
    h.Name = "PlayerHighlight"
    h.FillTransparency = 0.5
    h.OutlineTransparency = 0
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
    task.spawn(function()
        local character = player.Character
        if not character or (player.Team and player.Team.Name == "Lobby") then 
            cleanupPlayerEffects(player)
            return 
        end
        
        if not getBestPart(character) then
            task.wait(1)
        end
        
        createInfoESP(player, character)
        
        local role = player:GetAttribute("Role")
        if role == "SCP-966" then
            create966Billboard(player, character)
        else
            createHighlight(player, character)
        end
    end)
end

-- UI Construction
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

-- Logic Handlers
local function onPlayerAdded(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        setupVisuals(player)
    end)
    player:GetPropertyChangedSignal("Team"):Connect(function() setupVisuals(player) end)
    if player.Character then setupVisuals(player) end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= localPlayer then onPlayerAdded(p) end
end
Players.PlayerRemoving:Connect(cleanupPlayerEffects)

-- Aimbot Loop
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
    if currentTarget then
        cam.CFrame = CFrame.new(cam.CFrame.Position, currentTarget.Position)
    end
end)

-- ESP Loop
task.spawn(function()
    while true do
        local _, _, myRoot = getCharacter()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= localPlayer then
                local char = p.Character
                if char and (not highlights[p] or not infoGuis[p]) then
                    setupVisuals(p)
                end

                if char then
                    local root = getBestPart(char)
                    local hum = char:FindFirstChild("Humanoid")
                    
                    local tName = p.Team and p.Team.Name or ""
                    local isEspOn = (espAllEnabled or teamSettings[tName]) and tName ~= "Lobby"
                    
                    local dist = (myRoot and root) and (myRoot.Position - root.Position).Magnitude or 99999
                    local inRange = dist <= MAX_DISTANCE
                    
                    local shouldShow = isEspOn and inRange and root

                    -- Highlight Logic
                    if highlights[p] then
                        local h = highlights[p]
                        h.Enabled = shouldShow
                        if shouldShow then
                            if h.Adornee ~= char then h.Adornee = char end
                            local teamColor = p.Team and p.Team.TeamColor.Color or Color3.new(1, 1, 1)
                            h.FillColor = teamColor
                            h.OutlineColor = teamColor
                        end
                    end

                    -- Info Logic (HP + Distance)
                    if infoGuis[p] then
                        local gui = infoGuis[p]
                        local hpLabel = gui:FindFirstChild("Frame") and gui.Frame:FindFirstChild("HPLabel")
                        local distLabel = gui:FindFirstChild("Frame") and gui.Frame:FindFirstChild("DistanceLabel")
                        
                        gui.Enabled = shouldShow and (hpEspEnabled or distEspEnabled)
                        
                        if gui.Enabled and hum and root then
                            -- HP update
                            if hpEspEnabled then
                                local perc = math.clamp(math.floor((hum.Health / hum.MaxHealth) * 100), 0, 100)
                                hpLabel.Text = "HP: " .. perc .. "%"
                                hpLabel.TextColor3 = getHealthColor(perc)
                                hpLabel.Visible = true
                            else
                                hpLabel.Visible = false
                            end

                            if distEspEnabled then
                                distLabel.Text = "Distance: " .. math.floor(dist) .. " studs"
                                distLabel.Visible = true
                            else
                                distLabel.Visible = false
                            end
                            
                            if gui.Adornee ~= root then
                                gui.Adornee = root
                                gui.Parent = root
                            end
                        end
                    end
                    
                    -- 966 Logic
                    if billboards[p] then
                        billboards[p].Enabled = shouldShow
                    end
                end
            end
        end
        task.wait(UPDATE_INTERVAL)
    end
end)
