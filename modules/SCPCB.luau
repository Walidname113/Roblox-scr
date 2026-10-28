local REQUIRED_GAME_ID = 8773050457
local UI_URL = "https://raw.githubusercontent.com/Walidname113/Roblox-scr/refs/heads/main/ModernUI_v32.lua"
local MINIMIZED_ICON = ""

if not game:IsLoaded() then
    game.Loaded:Wait()
end

if game.GameId ~= REQUIRED_GAME_ID then
    return
end

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then return end

local UPDATE_INTERVAL = 0.1
local LOBBY_TEAM_NAME = "Lobby"
local SCP966_ROLE_ATTRIBUTE = "Role"
local SCP966_ROLE_NAME = "SCP-966"
local SCP966_TEMPLATE_PATH = {"Lobby", "SCPInfo", "966", "966"}
local PROXY_FOLDER_NAME = "SCP966_RigProxy"
local PROXY_UPDATE_NAME = "SCP966_RigProxy_Update"

local allEnabled = false
local allDistanceEnabled = false
local allHealthEnabled = false
local teamCards = {}
local visualsCache = {}
local proxies = {}
local playerConnections = {}
local allDistanceToggle
local allHealthToggle
local SafeContainer
local ProxyFolder
local Window

local loaded, uiModule = pcall(function()
    local source = game:HttpGet(UI_URL)
    local original = "onTap(hit, function() w:Set(not state) end)"
    local replacement = [[
        onTap(hit, function()
            if cfg.CanToggle and not cfg.CanToggle() then
                return
            end
            w:Set(not state)
        end)
    ]]
    local startIndex, endIndex = source:find(original, 1, true)
    assert(startIndex, "ModernUI toggle handler signature changed")
    source = source:sub(1, startIndex - 1) .. replacement .. source:sub(endIndex + 1)
    local factory = loadstring(source)
    assert(type(factory) == "function", "Invalid UI source")
    return factory()
end)

if not loaded or type(uiModule) ~= "table" or type(uiModule.new) ~= "function" then
    warn("[SCP:RB] ModernUI failed to load:", uiModule)
    return
end

Window = uiModule.new({
    Name = "SCPRB_ModernUI",
    Title = "SCP:RB | By Kiyatsuka v2.0",
})

if MINIMIZED_ICON ~= "" then Window:SetMinimizedImage(MINIMIZED_ICON) end

local Main = Window:Category("Main")
local ESP = Window:Category("ESP")
local Visuals = Window:Category("Visuals")
local Movement = Window:Category("Movement")

local oldContainer = CoreGui:FindFirstChild("SCPRB_ESP_Container")
if oldContainer then oldContainer:Destroy() end

SafeContainer = Instance.new("Folder")
SafeContainer.Name = "SCPRB_ESP_Container"
SafeContainer.Parent = CoreGui

local oldProxyFolder = Workspace:FindFirstChild(PROXY_FOLDER_NAME)
if oldProxyFolder then oldProxyFolder:Destroy() end

ProxyFolder = Instance.new("Folder")
ProxyFolder.Name = PROXY_FOLDER_NAME
ProxyFolder.Parent = Workspace

local function getSCP966Template()
    local current = Workspace
    for _, name in ipairs(SCP966_TEMPLATE_PATH) do
        current = current and current:FindFirstChild(name)
        if not current then return nil end
    end
    if current:IsA("Model") then return current end
    return nil
end

local SCP966Template = getSCP966Template()
if not SCP966Template then warn("[SCP:RB] SCP-966 template not found") end

local function getSub(toggle, index)
    return toggle and toggle.Subs and toggle.Subs[index]
end

local function setSubVisible(widget, visible)
    if widget then widget:SetVisible(visible) end
end

local function setOutline(widget, locked)
    local frame = widget and widget.Frame
    if not frame then return end
    local outline = frame:FindFirstChildOfClass("UIStroke")
    if not outline then return end
    outline.Color = locked and Color3.fromRGB(95, 95, 100) or Color3.fromRGB(39, 39, 42)
    outline.Transparency = locked and 0.2 or 0
end

local function getTeamColor(player)
    local team = player.Team
    return team and team.TeamColor.Color or Color3.new(1, 1, 1)
end

local function getCharacterData(player)
    local character = player.Character
    if not character then return nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
        or character.PrimaryPart
        or character:FindFirstChild("Head")
    if not humanoid or not root then return nil end
    return character, humanoid, root
end

local function getRoot(model)
    return model:FindFirstChild("HumanoidRootPart")
        or model.PrimaryPart
        or model:FindFirstChild("Torso")
        or model:FindFirstChild("UpperTorso")
        or model:FindFirstChild("Head")
end

local function getHealthColor(percent)
    return Color3.fromRGB(255, 60, 60):Lerp(
        Color3.fromRGB(0, 255, 0),
        math.clamp(percent, 0, 100) / 100
    )
end

local function isSCP966(player)
    return player:GetAttribute(SCP966_ROLE_ATTRIBUTE) == SCP966_ROLE_NAME
end

local function getMotorPath(model, motor)
    local segments = {}
    local current = motor
    while current and current ~= model do
        table.insert(segments, 1, current.Name)
        current = current.Parent
    end
    if current ~= model then return nil end
    return table.concat(segments, "/")
end

local function collectMotors(model)
    local result = {}
    for _, object in ipairs(model:GetDescendants()) do
        if object:IsA("Motor6D") then
            local path = getMotorPath(model, object)
            if path then result[path] = object end
        end
    end
    return result
end

local function removeProxy(player)
    local data = proxies[player]
    if not data then return end
    if data.Model then data.Model:Destroy() end
    proxies[player] = nil
end

local function createProxy(player, character)
    removeProxy(player)
    if not SCP966Template or not isSCP966(player) or not character or not character.Parent then
        return nil
    end

    local sourceRoot = getRoot(character)
    if not sourceRoot or not sourceRoot:IsA("BasePart") then return nil end

    local clone = SCP966Template:Clone()
    clone.Name = "SCP966_Proxy_" .. player.Name

    for _, object in ipairs(clone:GetDescendants()) do
        if object:IsA("BillboardGui")
            or object:IsA("SurfaceGui")
            or object:IsA("ProximityPrompt")
            or object:IsA("Script")
            or object:IsA("LocalScript")
            or object:IsA("Animator")
            or object:IsA("Humanoid") then
            object:Destroy()
        end
    end

    local cloneRoot = getRoot(clone)
    if not cloneRoot or not cloneRoot:IsA("BasePart") then
        clone:Destroy()
        warn("[SCP:RB] SCP-966 template root not found")
        return nil
    end

    local sourceMotors = collectMotors(character)
    local cloneMotors = collectMotors(clone)
    local matchedMotors = {}

    for path, sourceMotor in pairs(sourceMotors) do
        local cloneMotor = cloneMotors[path]
        if cloneMotor then
            cloneMotor.C0 = sourceMotor.C0
            cloneMotor.C1 = sourceMotor.C1
            cloneMotor.Transform = sourceMotor.Transform
            matchedMotors[#matchedMotors + 1] = {
                Source = sourceMotor,
                Clone = cloneMotor,
            }
        end
    end

    for _, object in ipairs(clone:GetDescendants()) do
        if object:IsA("BasePart") then
            object.CanCollide = false
            object.CanTouch = false
            object.CanQuery = false
            object.Massless = true
            object.LocalTransparencyModifier = 0
            object.Anchored = object == cloneRoot
        end
    end

    clone.Parent = ProxyFolder
    local pivotOffset = cloneRoot.CFrame:ToObjectSpace(clone:GetPivot())
    clone:PivotTo(sourceRoot.CFrame * pivotOffset)

    local data = {
        Model = clone,
        Character = character,
        SourceRoot = sourceRoot,
        CloneRoot = cloneRoot,
        PivotOffset = pivotOffset,
        Motors = matchedMotors,
    }
    proxies[player] = data

    print("[SCP:RB] SCP-966 proxy created:", player.Name, "| Matched joints:", #matchedMotors)
    return data
end

local function getProxy(player, character)
    local data = proxies[player]
    if data and data.Model and data.Model.Parent and data.Character == character then
        return data
    end
    return createProxy(player, character)
end

local function createPlayerVisuals(player)
    if visualsCache[player] then return visualsCache[player] end
    local visuals = {}

    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight_" .. player.Name
    highlight.Enabled = false
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Parent = SafeContainer
    visuals.Highlight = highlight

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Info_" .. player.Name
    billboard.Size = UDim2.fromOffset(220, 36)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = false
    billboard.Parent = SafeContainer

    local container = Instance.new("Frame")
    container.Size = UDim2.fromScale(1, 1)
    container.BackgroundTransparency = 1
    container.Parent = billboard

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.Parent = container

    local font = Font.new(
        "rbxasset://fonts/families/PressStart2P.json",
        Enum.FontWeight.Regular,
        Enum.FontStyle.Normal
    )

    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Name = "Distance"
    distanceLabel.Size = UDim2.new(1, 0, 0, 18)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.FontFace = font
    distanceLabel.TextSize = 8
    distanceLabel.TextColor3 = Color3.new(1, 1, 1)
    distanceLabel.TextStrokeTransparency = 0
    distanceLabel.LayoutOrder = 1
    distanceLabel.Visible = false
    distanceLabel.Parent = container

    local healthLabel = Instance.new("TextLabel")
    healthLabel.Name = "Health"
    healthLabel.Size = UDim2.new(1, 0, 0, 18)
    healthLabel.BackgroundTransparency = 1
    healthLabel.FontFace = font
    healthLabel.TextSize = 8
    healthLabel.TextStrokeTransparency = 0
    healthLabel.LayoutOrder = 2
    healthLabel.Visible = false
    healthLabel.Parent = container

    visuals.Billboard = billboard
    visuals.DistanceLabel = distanceLabel
    visuals.HealthLabel = healthLabel
    visualsCache[player] = visuals
    return visuals
end

local function clearPlayerVisuals(player)
    local visuals = visualsCache[player]
    if not visuals then return end
    if visuals.Highlight then visuals.Highlight:Destroy() end
    if visuals.Billboard then visuals.Billboard:Destroy() end
    visualsCache[player] = nil
end

local function isESPEnabled(player)
    local team = player.Team
    if not team or team.Name == LOBBY_TEAM_NAME then return false end
    if allEnabled then return true end
    local card = teamCards[team.Name]
    return card ~= nil and card.Enabled
end

local function getESPOptions(player)
    if allEnabled then return allDistanceEnabled, allHealthEnabled end
    local team = player.Team
    local card = team and teamCards[team.Name]
    if not card or not card.Enabled then return false, false end
    return card.DistanceEnabled, card.HealthEnabled
end

local function refreshAllSubtoggles()
    setSubVisible(allDistanceToggle, allEnabled)
    setSubVisible(allHealthToggle, allEnabled)
end

local function refreshTeamCards()
    for _, card in pairs(teamCards) do
        setOutline(card.Toggle, allEnabled)
        setSubVisible(card.DistanceToggle, card.Enabled)
        setSubVisible(card.HealthToggle, card.Enabled)
    end
end

local allToggle = ESP:Toggle({
    Text = "ESP All",
    Default = false,
    Sub = {
        {
            Type = "Toggle",
            Text = "Distance ESP",
            Default = false,
            Callback = function(state) allDistanceEnabled = state end,
        },
        {
            Type = "Toggle",
            Text = "Health ESP",
            Default = false,
            Callback = function(state) allHealthEnabled = state end,
        },
    },
    Callback = function(state)
        allEnabled = state
        if allEnabled then
            for _, card in pairs(teamCards) do
                if card.Enabled then card.Toggle:Set(false) end
                card.Enabled = false
            end
        end
        refreshAllSubtoggles()
        refreshTeamCards()
    end,
})

allDistanceToggle = getSub(allToggle, 1)
allHealthToggle = getSub(allToggle, 2)
refreshAllSubtoggles()

local function createTeamCard(team)
    if not team:IsA("Team") or team.Name == LOBBY_TEAM_NAME or teamCards[team.Name] then
        return
    end

    local card = {
        Team = team,
        Enabled = false,
        DistanceEnabled = false,
        HealthEnabled = false,
    }

    local toggle = ESP:Toggle({
        Text = "ESP " .. team.Name,
        Default = false,
        CanToggle = function() return not allEnabled end,
        Sub = {
            {
                Type = "Toggle",
                Text = "Distance ESP",
                Default = false,
                Callback = function(state) card.DistanceEnabled = state end,
            },
            {
                Type = "Toggle",
                Text = "Health ESP",
                Default = false,
                Callback = function(state) card.HealthEnabled = state end,
            },
        },
        Callback = function(state)
            if allEnabled then return end
            card.Enabled = state
            setSubVisible(card.DistanceToggle, state)
            setSubVisible(card.HealthToggle, state)
        end,
    })

    card.Toggle = toggle
    card.DistanceToggle = getSub(toggle, 1)
    card.HealthToggle = getSub(toggle, 2)
    teamCards[team.Name] = card

    setSubVisible(card.DistanceToggle, false)
    setSubVisible(card.HealthToggle, false)
    setOutline(toggle, allEnabled)
end

for _, team in ipairs(Teams:GetChildren()) do createTeamCard(team) end

Window:Connect(Teams.ChildAdded, function(team)
    createTeamCard(team)
    refreshTeamCards()
end)

Window:Connect(Teams.ChildRemoved, function(team)
    local card = teamCards[team.Name]
    if card then
        if card.Toggle and card.Toggle.Frame then card.Toggle.Frame:Destroy() end
        teamCards[team.Name] = nil
    end
end)

local function setupPlayer(player)
    if playerConnections[player] then return end
    local connections = {}
    playerConnections[player] = connections

    connections.CharacterAdded = player.CharacterAdded:Connect(function()
        removeProxy(player)
    end)
    connections.CharacterRemoving = player.CharacterRemoving:Connect(function()
        removeProxy(player)
    end)
    connections.RoleChanged = player:GetAttributeChangedSignal(SCP966_ROLE_ATTRIBUTE):Connect(function()
        removeProxy(player)
    end)
end

local function cleanupPlayer(player)
    removeProxy(player)
    clearPlayerVisuals(player)
    local connections = playerConnections[player]
    if connections then
        for _, connection in pairs(connections) do connection:Disconnect() end
    end
    playerConnections[player] = nil
end

for _, player in ipairs(Players:GetPlayers()) do setupPlayer(player) end
Window:Connect(Players.PlayerAdded, setupPlayer)
Window:Connect(Players.PlayerRemoving, cleanupPlayer)

RunService:UnbindFromRenderStep(PROXY_UPDATE_NAME)
RunService:BindToRenderStep(PROXY_UPDATE_NAME, Enum.RenderPriority.Camera.Value + 1, function()
    for player, data in pairs(proxies) do
        if not isSCP966(player)
            or not isESPEnabled(player)
            or not data.Model
            or not data.Model.Parent
            or not data.SourceRoot
            or not data.SourceRoot.Parent then
            removeProxy(player)
            continue
        end

        data.Model:PivotTo(data.SourceRoot.CFrame * data.PivotOffset)

        for _, pair in ipairs(data.Motors) do
            local sourceMotor = pair.Source
            local cloneMotor = pair.Clone
            if sourceMotor.Parent and cloneMotor.Parent then
                cloneMotor.C0 = sourceMotor.C0
                cloneMotor.C1 = sourceMotor.C1
                cloneMotor.Transform = sourceMotor.Transform
            end
        end
    end
end)

Window:Loop(UPDATE_INTERVAL, function()
    local localCharacter = LocalPlayer.Character
    local localRoot = localCharacter and (
        localCharacter:FindFirstChild("HumanoidRootPart")
        or localCharacter.PrimaryPart
    )

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        local visuals = createPlayerVisuals(player)
        local character, humanoid, root = getCharacterData(player)
        local valid = character ~= nil
            and humanoid.Health > 0
            and player.Team ~= nil
            and player.Team.Name ~= LOBBY_TEAM_NAME

        local enabled = valid and isESPEnabled(player)
        local is966 = isSCP966(player)
        local teamColor = getTeamColor(player)
        local highlight = visuals.Highlight
        local billboard = visuals.Billboard

        local visualModel = character
        local visualRoot = root

        if enabled and is966 then
            local proxyData = getProxy(player, character)
            if proxyData then
                visualModel = proxyData.Model
                visualRoot = proxyData.CloneRoot
            else
                visualModel = nil
                visualRoot = nil
            end
        elseif is966 then
            removeProxy(player)
        else
            removeProxy(player)
        end

        local canDisplay = enabled and visualModel ~= nil and visualRoot ~= nil
        highlight.Enabled = canDisplay

        if canDisplay then
            highlight.Adornee = visualModel
            highlight.FillColor = teamColor
            highlight.OutlineColor = teamColor
        else
            highlight.Adornee = nil
        end

        local distanceLabel = visuals.DistanceLabel
        local healthLabel = visuals.HealthLabel
        local showDistance, showHealth = false, false
        local distance

        if canDisplay then
            showDistance, showHealth = getESPOptions(player)
            if localRoot then
                distance = (localRoot.Position - root.Position).Magnitude
            end
        end

        distanceLabel.Visible = canDisplay and showDistance and distance ~= nil
        healthLabel.Visible = canDisplay and showHealth
        billboard.Enabled = distanceLabel.Visible or healthLabel.Visible

        if billboard.Enabled then
            billboard.Adornee = visualRoot

            if distanceLabel.Visible then
                distanceLabel.Text = "Dist: " .. math.floor(distance) .. " studs"
                distanceLabel.TextColor3 = teamColor
            end

            if healthLabel.Visible then
                local percent = 0
                if humanoid.MaxHealth > 0 then
                    percent = math.clamp(
                        math.floor(humanoid.Health / humanoid.MaxHealth * 100),
                        0,
                        100
                    )
                end
                healthLabel.Text = "HP: " .. percent .. "%"
                healthLabel.TextColor3 = getHealthColor(percent)
            end
        else
            billboard.Adornee = nil
        end
    end
end)

Window:OnClose(function()
    allEnabled = false
    RunService:UnbindFromRenderStep(PROXY_UPDATE_NAME)

    for player in pairs(proxies) do removeProxy(player) end
    for player in pairs(visualsCache) do clearPlayerVisuals(player) end
    for player in pairs(playerConnections) do cleanupPlayer(player) end

    if SafeContainer then SafeContainer:Destroy() end
    if ProxyFolder then ProxyFolder:Destroy() end

    table.clear(visualsCache)
    table.clear(teamCards)
    table.clear(proxies)
    table.clear(playerConnections)

    print("[SCP:RB] ESP unloaded")
end)

print("[SCP:RB] ESP initialized")
