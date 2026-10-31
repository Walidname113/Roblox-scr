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
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then return end

local UPDATE_INTERVAL = 0.1
local MOVEMENT_INTERVAL = 0.5
local HIGHLIGHT_RANGE = 700
local MAX_HIGHLIGHTS = 31
local NO_FOG_DISTANCE = 1000000
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
    Title = "{gamename} | By Kiyatsuka v2.1",
})

Window:SetMinimizedImage(MINIMIZED_ICON)

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


local AIM_MAX_DISTANCE = 100
local AIM_DISTANCE_TOLERANCE = 10
local AIM_ACQUIRE_ANGLE = 10
local PRETARGET_ANGLE = 12
local AIM_SMOOTHING = 0.28
local AIM_UPDATE_NAME = "SCPRB_Aimbot_Update"
local AIM_GUI_NAME = "SCPRB_Aimbot_Controls"
local AIM_STATUS_GUI_NAME = "SCPRB_Aimbot_Status"

local aimEnabled = false
local choseCorner = true
local choseNearest = false
local wallCheck = true
local teamCheck = true
local blockMovement = false
local forcedLock = false
local currentTarget = nil
local preTarget = nil
local suppressedTarget = nil
local aimState = "Waiting"
local lostStateUntil = 0
local aimToggle
local aimCornerToggle
local aimNearestToggle
local aimWallToggle
local aimTeamToggle
local aimGui
local aimPanel
local aimStatusGui
local aimStatusLabels = {}
local aimStatusValues = {}
local aimGuiConnections = {}
local aimGuiPosition = UDim2.new(1, -214, 1, -158)

local function disconnectAimGuiConnections()
    for _, connection in ipairs(aimGuiConnections) do
        connection:Disconnect()
    end
    table.clear(aimGuiConnections)
end

local function getAimTargetPart(player)
    local character, humanoid, root = getCharacterData(player)
    if not character or humanoid.Health <= 0 then return nil end
    local part = character:FindFirstChild("Head") or root
    if not part or not part:IsA("BasePart") then return nil end
    return part, character, humanoid, root
end

local function getTargetDistance(player, part)
    local character = LocalPlayer.Character
    local localRoot = character and (
        character:FindFirstChild("HumanoidRootPart")
        or character.PrimaryPart
        or character:FindFirstChild("Head")
    )
    if not localRoot or not part then return math.huge end
    return (localRoot.Position - part.Position).Magnitude
end

local function getTargetAngle(part)
    local camera = Workspace.CurrentCamera
    if not camera or not part then return math.huge end
    local offset = part.Position - camera.CFrame.Position
    if offset.Magnitude <= 0 then return 0 end
    local dot = math.clamp(camera.CFrame.LookVector:Dot(offset.Unit), -1, 1)
    return math.deg(math.acos(dot))
end

local function isTargetVisible(player, part, character)
    local camera = Workspace.CurrentCamera
    if not camera or not part then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local exclude = {}
    if LocalPlayer.Character then table.insert(exclude, LocalPlayer.Character) end
    if character then table.insert(exclude, character) end
    params.FilterDescendantsInstances = exclude
    params.IgnoreWater = true
    local direction = part.Position - camera.CFrame.Position
    local result = Workspace:Raycast(camera.CFrame.Position, direction, params)
    return result == nil
end

local function normalizeTeamName(team)
    if not team then return "" end
    return string.lower(team.Name):gsub("[^%w]", "")
end

local function classifyTeam(team)
    local name = normalizeTeamName(team)
    if name == "" then return "unknown" end
    if name == "lobby" then return "lobby" end
    if string.find(name, "classd", 1, true) or name == "cd" then return "cdci" end
    if string.find(name, "chaos", 1, true) or name == "ci" or string.find(name, "insurgency", 1, true) then return "cdci" end
    if string.find(name, "staff", 1, true) or name == "fp" or string.find(name, "foundationpersonnel", 1, true) then return "foundation" end
    if string.find(name, "security", 1, true) or name == "sd" then return "foundation" end
    if name == "mtf" or string.find(name, "mobiletaskforce", 1, true) then return "foundation" end
    if name == "scp" or name == "scps" or string.find(name, "scp", 1, true) then return "scpserpent" end
    if string.find(name, "serpent", 1, true) or name == "sh" then return "scpserpent" end
    if name == "goc" or string.find(name, "globaloccult", 1, true) then return "goc" end
    return "unknown"
end

local function isHostileTeam(targetTeam, localTeam)
    if not targetTeam or not localTeam then return true end
    if targetTeam == localTeam then return false end

    local targetGroup = classifyTeam(targetTeam)
    local localGroup = classifyTeam(localTeam)

    if targetGroup == "lobby" then return false end
    if targetGroup == "unknown" or localGroup == "unknown" then
        return targetTeam ~= localTeam
    end
    if targetGroup == localGroup then return false end

    if targetGroup == "goc" then
        return localGroup == "scpserpent"
    end
    if localGroup == "goc" then
        return targetGroup == "scpserpent"
    end

    return true
end

local function isTargetAllowed(player, part, character, distance, force)
    if not player or player == LocalPlayer or not part or not character then return false end
    if player.Team and classifyTeam(player.Team) == "lobby" then return false end
    if distance > AIM_MAX_DISTANCE + AIM_DISTANCE_TOLERANCE then return false end
    if not force and teamCheck and not isHostileTeam(player.Team, LocalPlayer.Team) then
        return false
    end
    if not force and wallCheck and not isTargetVisible(player, part, character) then
        return false
    end
    return true
end

local function getPreTargetCandidate()
    local bestPlayer, bestAngle, bestDistance = nil, PRETARGET_ANGLE, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not (player.Team and player.Team.Name == LOBBY_TEAM_NAME) then
            local part, character = getAimTargetPart(player)
            if part and character then
                local distance = getTargetDistance(player, part)
                local angle = getTargetAngle(part)
                if distance <= AIM_MAX_DISTANCE + AIM_DISTANCE_TOLERANCE and angle <= PRETARGET_ANGLE then
                    if angle < bestAngle - 0.15
                        or (math.abs(angle - bestAngle) <= 0.15 and distance < bestDistance) then
                        bestPlayer = player
                        bestAngle = angle
                        bestDistance = distance
                    end
                end
            end
        end
    end
    return bestPlayer
end

local function getAutomaticTarget()
    if not choseCorner and not choseNearest then return nil end
    local candidates = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local part, character = getAimTargetPart(player)
            if part and character then
                local distance = getTargetDistance(player, part)
                local angle = getTargetAngle(part)
                if isTargetAllowed(player, part, character, distance, false)
                    and (not choseCorner or angle <= AIM_ACQUIRE_ANGLE) then
                    candidates[#candidates + 1] = {
                        Player = player,
                        Part = part,
                        Character = character,
                        Distance = distance,
                        Angle = angle,
                    }
                end
            end
        end
    end
    table.sort(candidates, function(a, b)
        if choseCorner and choseNearest then
            if math.abs(a.Angle - b.Angle) > 0.75 then
                return a.Angle < b.Angle
            end
            return a.Distance < b.Distance
        elseif choseCorner then
            return a.Angle < b.Angle
        else
            return a.Distance < b.Distance
        end
    end)
    return candidates[1] and candidates[1].Player or nil
end

local function setAimState(state)
    aimState = state
    if state == "Lost" then
        lostStateUntil = os.clock() + 1.2
    end
end

local function clearAimTarget(clearPreTarget)
    currentTarget = nil
    forcedLock = false
    if clearPreTarget then
        preTarget = nil
        suppressedTarget = nil
    end
    setAimState("Lost")
end

local function createAimStatus()
    if aimStatusGui then aimStatusGui:Destroy() end
    aimStatusGui = Instance.new("ScreenGui")
    aimStatusGui.Name = AIM_STATUS_GUI_NAME
    aimStatusGui.ResetOnSpawn = false
    aimStatusGui.IgnoreGuiInset = true
    aimStatusGui.DisplayOrder = 20
    aimStatusGui.Parent = CoreGui

    local holder = Instance.new("Frame")
    holder.Name = "Status"
    holder.BackgroundTransparency = 1
    holder.BorderSizePixel = 0
    holder.Position = UDim2.new(0, 18, 0.5, -72)
    holder.Size = UDim2.fromOffset(360, 72)
    holder.Parent = aimStatusGui

    local font = Font.new(
        "rbxasset://fonts/families/PressStart2P.json",
        Enum.FontWeight.Regular,
        Enum.FontStyle.Normal
    )
    local rows = {
        {Key = "Lock", Prefix = "Lock: "},
        {Key = "Target", Prefix = "Target: "},
        {Key = "State", Prefix = "State: "},
    }
    table.clear(aimStatusLabels)
    table.clear(aimStatusValues)
    for index, row in ipairs(rows) do
        local label = Instance.new("TextLabel")
        label.Name = row.Key
        label.BackgroundTransparency = 1
        label.BorderSizePixel = 0
        label.Position = UDim2.fromOffset(0, (index - 1) * 23)
        label.Size = UDim2.fromOffset(360, 22)
        label.FontFace = font
        label.TextSize = 9
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextYAlignment = Enum.TextYAlignment.Center
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextStrokeTransparency = 0.5
        label.Text = row.Prefix
        label.Parent = holder
        aimStatusLabels[row.Key] = label
        aimStatusValues[row.Key] = row.Prefix
    end
end

local function updateAimStatus()
    if not aimStatusGui or not aimStatusGui.Parent then return end
    local lockText, lockColor
    if not aimEnabled then
        lockText, lockColor = "OFF", Color3.fromRGB(255, 70, 70)
    elseif currentTarget then
        lockText, lockColor = "ON", Color3.fromRGB(80, 255, 100)
    elseif not choseCorner and not choseNearest then
        lockText, lockColor = "OFF", Color3.fromRGB(255, 70, 70)
    elseif preTarget then
        lockText, lockColor = "Pre-target", Color3.fromRGB(255, 220, 65)
    else
        lockText, lockColor = "ON", Color3.fromRGB(80, 255, 100)
    end

    local targetText = "Nothing"
    local targetColor = Color3.fromRGB(255, 70, 70)
    local targetPlayer = currentTarget
    if targetPlayer and targetPlayer.Parent == Players then
        targetText = targetPlayer.DisplayName .. " (@" .. targetPlayer.Name .. ")"
        targetColor = Color3.fromRGB(80, 255, 100)
    end

    local stateText, stateColor
    if currentTarget then
        stateText, stateColor = "Locked", Color3.fromRGB(80, 255, 100)
    elseif preTarget then
        stateText, stateColor = "Pre-State", Color3.fromRGB(255, 220, 65)
    elseif aimState == "Lost" and os.clock() < lostStateUntil then
        stateText, stateColor = "Lost", Color3.fromRGB(255, 70, 70)
    else
        stateText, stateColor = "Waiting", Color3.new(1, 1, 1)
    end

    aimStatusLabels.Lock.Text = "Lock: " .. lockText
    aimStatusLabels.Lock.TextColor3 = lockColor
    aimStatusLabels.Target.Text = "Target: " .. targetText
    aimStatusLabels.Target.TextColor3 = targetColor
    aimStatusLabels.State.Text = "State: " .. stateText
    aimStatusLabels.State.TextColor3 = stateColor
end

local function makeAimButton(parent, text, position, size)
    local button = Instance.new("TextButton")
    button.AutoButtonColor = true
    button.BackgroundColor3 = Color3.fromRGB(39, 39, 42)
    button.BorderSizePixel = 0
    button.Position = position
    button.Size = size
    button.Font = Enum.Font.Gotham
    button.Text = text
    button.TextSize = 11
    button.TextColor3 = Color3.fromRGB(240, 240, 242)
    button.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = button
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(65, 65, 70)
    stroke.Thickness = 1
    stroke.Parent = button
    return button
end

local function destroyAimGui()
    disconnectAimGuiConnections()
    if aimGui then aimGui:Destroy() end
    if aimStatusGui then aimStatusGui:Destroy() end
    aimGui = nil
    aimPanel = nil
    aimStatusGui = nil
    table.clear(aimStatusLabels)
    table.clear(aimStatusValues)
end

local function resetAimSettingsToDefaults()
    choseCorner = true
    choseNearest = false
    wallCheck = true
    teamCheck = true
    if aimCornerToggle then aimCornerToggle:Set(true, true) end
    if aimNearestToggle then aimNearestToggle:Set(false, true) end
    if aimWallToggle then aimWallToggle:Set(true, true) end
    if aimTeamToggle then aimTeamToggle:Set(true, true) end
end

local function closeAimGuiConfirmed()
    aimEnabled = false
    currentTarget = nil
    preTarget = nil
    suppressedTarget = nil
    forcedLock = false
    setAimState("Waiting")
    if aimToggle then aimToggle:Set(false, true) end
    resetAimSettingsToDefaults()
    destroyAimGui()
end

local function createAimGui()
    destroyAimGui()
    aimGui = Instance.new("ScreenGui")
    aimGui.Name = AIM_GUI_NAME
    aimGui.ResetOnSpawn = false
    aimGui.IgnoreGuiInset = true
    aimGui.DisplayOrder = 15
    aimGui.Parent = CoreGui

    aimPanel = Instance.new("Frame")
    aimPanel.Name = "Controls"
    aimPanel.Size = UDim2.fromOffset(202, 116)
    aimPanel.Position = aimGuiPosition
    aimPanel.BackgroundColor3 = Color3.fromRGB(27, 27, 30)
    aimPanel.BorderSizePixel = 0
    aimPanel.Parent = aimGui
    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 7)
    panelCorner.Parent = aimPanel
    local panelStroke = Instance.new("UIStroke")
    panelStroke.Color = Color3.fromRGB(62, 62, 67)
    panelStroke.Thickness = 1
    panelStroke.Parent = aimPanel

    local header = Instance.new("TextLabel")
    header.Name = "Header"
    header.Position = UDim2.fromOffset(8, 3)
    header.Size = UDim2.new(1, -45, 0, 22)
    header.BackgroundTransparency = 1
    header.Font = Enum.Font.GothamSemibold
    header.Text = "Aimbot controls"
    header.TextSize = 12
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.TextColor3 = Color3.fromRGB(242, 242, 244)
    header.Parent = aimPanel

    local closeButton = makeAimButton(aimPanel, "×", UDim2.new(1, -28, 0, 4), UDim2.fromOffset(22, 20))
    closeButton.TextSize = 16
    local resetButton = makeAimButton(aimPanel, "Lock reset", UDim2.fromOffset(8, 32), UDim2.fromOffset(90, 29))
    local forceButton = makeAimButton(aimPanel, "Forced lock", UDim2.fromOffset(104, 32), UDim2.fromOffset(90, 29))
    local moveButton = makeAimButton(aimPanel, "Block movement: OFF", UDim2.fromOffset(8, 68), UDim2.fromOffset(186, 28))
    moveButton.TextSize = 10

    local confirmFrame = Instance.new("Frame")
    confirmFrame.Name = "ConfirmClose"
    confirmFrame.Visible = false
    confirmFrame.ZIndex = 5
    confirmFrame.Position = UDim2.fromOffset(8, 26)
    confirmFrame.Size = UDim2.new(1, -16, 1, -34)
    confirmFrame.BackgroundColor3 = Color3.fromRGB(31, 31, 34)
    confirmFrame.BorderSizePixel = 0
    confirmFrame.Parent = aimPanel
    local confirmCorner = Instance.new("UICorner")
    confirmCorner.CornerRadius = UDim.new(0, 5)
    confirmCorner.Parent = confirmFrame
    local confirmText = Instance.new("TextLabel")
    confirmText.BackgroundTransparency = 1
    confirmText.Position = UDim2.fromOffset(5, 3)
    confirmText.Size = UDim2.new(1, -10, 0, 25)
    confirmText.Font = Enum.Font.Gotham
    confirmText.Text = "Close and reset Aimbot?"
    confirmText.TextSize = 11
    confirmText.TextColor3 = Color3.fromRGB(245, 245, 245)
    confirmText.ZIndex = 6
    confirmText.Parent = confirmFrame
    local yesButton = makeAimButton(confirmFrame, "Confirm", UDim2.new(0, 5, 0, 34), UDim2.new(0.5, -7, 0, 25))
    yesButton.ZIndex = 6
    local noButton = makeAimButton(confirmFrame, "Cancel", UDim2.new(0.5, 2, 0, 34), UDim2.new(0.5, -7, 0, 25))
    noButton.ZIndex = 6
    for _, object in ipairs(confirmFrame:GetDescendants()) do
        if object:IsA("GuiObject") then object.ZIndex = math.max(object.ZIndex, 6) end
    end

    local dragging = false
    local dragInput
    local dragStart
    local startPosition
    local function updateDrag(input)
        local delta = input.Position - dragStart
        aimPanel.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
        aimGuiPosition = aimPanel.Position
    end

    table.insert(aimGuiConnections, header.InputBegan:Connect(function(input)
        if blockMovement then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = aimPanel.Position
            dragInput = input
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end))
    table.insert(aimGuiConnections, UserInputService.InputChanged:Connect(function(input)
        if dragging and not blockMovement
            and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
            updateDrag(input)
        end
    end))

    table.insert(aimGuiConnections, resetButton.Activated:Connect(function()
        suppressedTarget = preTarget or currentTarget
        currentTarget = nil
        forcedLock = false
        setAimState("Lost")
    end))
    table.insert(aimGuiConnections, forceButton.Activated:Connect(function()
        if preTarget and preTarget.Parent == Players then
            local part, character = getAimTargetPart(preTarget)
            local distance = part and getTargetDistance(preTarget, part) or math.huge
            if part and character and distance <= AIM_MAX_DISTANCE + AIM_DISTANCE_TOLERANCE then
                currentTarget = preTarget
                suppressedTarget = nil
                forcedLock = true
                setAimState("Locked")
            end
        end
    end))
    table.insert(aimGuiConnections, moveButton.Activated:Connect(function()
        blockMovement = not blockMovement
        closeButton.Active = not blockMovement
        closeButton.AutoButtonColor = not blockMovement
        moveButton.Text = "Block movement: " .. (blockMovement and "ON" or "OFF")
        moveButton.BackgroundColor3 = blockMovement
            and Color3.fromRGB(65, 65, 70)
            or Color3.fromRGB(39, 39, 42)
    end))
    table.insert(aimGuiConnections, closeButton.Activated:Connect(function()
        if blockMovement then return end
        confirmFrame.Visible = true
    end))
    table.insert(aimGuiConnections, noButton.Activated:Connect(function()
        confirmFrame.Visible = false
    end))
    table.insert(aimGuiConnections, yesButton.Activated:Connect(function()
        if blockMovement then return end
        closeAimGuiConfirmed()
    end))

    createAimStatus()
end

local function setAimbotEnabled(enabled)
    aimEnabled = enabled
    currentTarget = nil
    preTarget = nil
    suppressedTarget = nil
    forcedLock = false
    blockMovement = false
    setAimState("Waiting")
    if enabled then
        createAimGui()
    else
        destroyAimGui()
    end
end

local aimbotToggle = Main:Toggle({
    Text = "Aimbot",
    Default = false,
    Sub = {
        {
            Type = "Toggle",
            Text = "Chose Corner",
            Default = true,
            Callback = function(state) choseCorner = state end,
        },
        {
            Type = "Toggle",
            Text = "Chose nearest",
            Default = false,
            Callback = function(state) choseNearest = state end,
        },
        {
            Type = "Toggle",
            Text = "Wall check",
            Default = true,
            Callback = function(state) wallCheck = state end,
        },
        {
            Type = "Toggle",
            Text = "Team check",
            Default = true,
            Callback = function(state) teamCheck = state end,
        },
    },
    Callback = function(state)
        setAimbotEnabled(state)
    end,
})

aimToggle = aimbotToggle
aimCornerToggle = aimbotToggle.Subs and aimbotToggle.Subs[1]
aimNearestToggle = aimbotToggle.Subs and aimbotToggle.Subs[2]
aimWallToggle = aimbotToggle.Subs and aimbotToggle.Subs[3]
aimTeamToggle = aimbotToggle.Subs and aimbotToggle.Subs[4]

RunService:UnbindFromRenderStep(AIM_UPDATE_NAME)
RunService:BindToRenderStep(AIM_UPDATE_NAME, Enum.RenderPriority.Camera.Value + 2, function(deltaTime)
    if not aimEnabled then return end
    local nextPreTarget = getPreTargetCandidate()
    if nextPreTarget ~= preTarget then
        preTarget = nextPreTarget
        if suppressedTarget and preTarget ~= suppressedTarget then
            suppressedTarget = nil
        end
    end

    if currentTarget then
        local part, character = getAimTargetPart(currentTarget)
        local distance = part and getTargetDistance(currentTarget, part) or math.huge
        local aliveAndPresent = currentTarget.Parent == Players and part ~= nil and character ~= nil
        local visible = part and character and isTargetVisible(currentTarget, part, character)
        local allowed = aliveAndPresent
            and distance <= AIM_MAX_DISTANCE + AIM_DISTANCE_TOLERANCE
            and (forcedLock or not teamCheck or isHostileTeam(currentTarget.Team, LocalPlayer.Team))
            and (forcedLock or not wallCheck or visible)
        if not allowed then
            if wallCheck and not forcedLock and not visible then
                suppressedTarget = preTarget or currentTarget
            end
            clearAimTarget(false)
        else
            local camera = Workspace.CurrentCamera
            if camera then
                local goal = CFrame.lookAt(camera.CFrame.Position, part.Position)
                camera.CFrame = camera.CFrame:Lerp(goal, math.clamp(AIM_SMOOTHING * (deltaTime * 60), 0, 1))
            end
            setAimState("Locked")
        end
    elseif choseCorner or choseNearest then
        if preTarget and preTarget == suppressedTarget then
            setAimState("Lost")
        else
            local candidate = getAutomaticTarget()
            if candidate and candidate ~= suppressedTarget then
                local part = getAimTargetPart(candidate)
                if part then
                    currentTarget = candidate
                    forcedLock = false
                    setAimState("Locked")
                end
            elseif preTarget then
                setAimState("Pre-State")
            elseif aimState ~= "Lost" or os.clock() >= lostStateUntil then
                setAimState("Waiting")
            end
        end
    else
        currentTarget = nil
        forcedLock = false
        setAimState("Waiting")
    end
    updateAimStatus()
end)

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
    local camera = Workspace.CurrentCamera
    local origin = localRoot and localRoot.Position or (camera and camera.CFrame.Position)

    local entries = {}
    local candidates = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        local visuals = createPlayerVisuals(player)
        local character, humanoid, root = getCharacterData(player)
        local valid = character ~= nil
            and humanoid.Health > 0
            and player.Team ~= nil
            and player.Team.Name ~= LOBBY_TEAM_NAME
        local enabled = valid and isESPEnabled(player)
        local distance = (origin and root) and (origin - root.Position).Magnitude or nil

        local entry = {
            Player = player,
            Visuals = visuals,
            Character = character,
            Humanoid = humanoid,
            Root = root,
            Enabled = enabled,
            Distance = distance,
            Highlighted = false,
        }
        entries[#entries + 1] = entry

        if enabled and distance and distance <= HIGHLIGHT_RANGE then
            candidates[#candidates + 1] = entry
        end
    end

    table.sort(candidates, function(a, b)
        return a.Distance < b.Distance
    end)
    for index = 1, math.min(#candidates, MAX_HIGHLIGHTS) do
        candidates[index].Highlighted = true
    end

    for _, entry in ipairs(entries) do
        local player = entry.Player
        local visuals = entry.Visuals
        local highlight = visuals.Highlight
        local billboard = visuals.Billboard
        local teamColor = getTeamColor(player)

        local visualModel, visualRoot = nil, nil

        if entry.Highlighted then
            if isSCP966(player) then
                local proxyData = getProxy(player, entry.Character)
                if proxyData then
                    visualModel = proxyData.Model
                    visualRoot = proxyData.CloneRoot
                end
            else
                removeProxy(player)
                visualModel = entry.Character
                visualRoot = entry.Root
            end
        else
            removeProxy(player)
        end

        if visualModel then
            highlight.Adornee = visualModel
            highlight.FillColor = teamColor
            highlight.OutlineColor = teamColor
            highlight.Enabled = true
        else
            highlight.Enabled = false
            highlight.Adornee = nil
        end

        local distanceLabel = visuals.DistanceLabel
        local healthLabel = visuals.HealthLabel
        local canShowInfo = entry.Enabled and entry.Root ~= nil
        local showDistance, showHealth = false, false

        if canShowInfo then
            showDistance, showHealth = getESPOptions(player)
        end

        distanceLabel.Visible = canShowInfo and showDistance and entry.Distance ~= nil
        healthLabel.Visible = canShowInfo and showHealth
        billboard.Enabled = distanceLabel.Visible or healthLabel.Visible

        if billboard.Enabled then
            billboard.Adornee = visualRoot or entry.Root

            if distanceLabel.Visible then
                distanceLabel.Text = "Dist: " .. math.floor(entry.Distance) .. " studs"
                distanceLabel.TextColor3 = teamColor
            end

            if healthLabel.Visible then
                local humanoid = entry.Humanoid
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

local FULLBRIGHT_VALUES = {
    Brightness = 2,
    ClockTime = 14,
    GlobalShadows = false,
    Ambient = Color3.fromRGB(178, 178, 178),
    OutdoorAmbient = Color3.fromRGB(178, 178, 178),
}

local fullbrightEnabled = false
local noFogEnabled = false
local originalLighting = nil
local originalFogEnd = nil
local atmosphereState = {}

local function applyFullbright()
    for property, value in pairs(FULLBRIGHT_VALUES) do
        if Lighting[property] ~= value then
            Lighting[property] = value
        end
    end
end

local function setFullbright(enabled)
    if enabled then
        if not originalLighting then
            originalLighting = {}
            for property in pairs(FULLBRIGHT_VALUES) do
                originalLighting[property] = Lighting[property]
            end
        end
        fullbrightEnabled = true
        applyFullbright()
    else
        fullbrightEnabled = false
        if originalLighting then
            local saved = originalLighting
            originalLighting = nil
            for property, value in pairs(saved) do
                pcall(function()
                    Lighting[property] = value
                end)
            end
        end
    end
end

local function setNoFog(enabled)
    noFogEnabled = enabled
    if enabled then
        if originalFogEnd == nil then
            originalFogEnd = Lighting.FogEnd
        end
        if Lighting.FogEnd ~= NO_FOG_DISTANCE then
            Lighting.FogEnd = NO_FOG_DISTANCE
        end
        for _, item in ipairs(Lighting:GetDescendants()) do
            if item:IsA("Atmosphere") then
                if atmosphereState[item] == nil then
                    atmosphereState[item] = {
                        Density = item.Density,
                        Haze = item.Haze,
                    }
                end
                item.Density = 0
                item.Haze = 0
            end
        end
    else
        if originalFogEnd ~= nil then
            Lighting.FogEnd = originalFogEnd
            originalFogEnd = nil
        end
        for item, state in pairs(atmosphereState) do
            if item.Parent then
                item.Density = state.Density
                item.Haze = state.Haze
            end
        end
        table.clear(atmosphereState)
    end
end

Visuals:Toggle({
    Text = "No fog",
    Default = false,
    Callback = setNoFog,
})

Visuals:Toggle({
    Text = "Fullbright",
    Default = false,
    Callback = setFullbright,
})

local speedControl = nil
local jumpControl = nil
local speedEnabled = false
local jumpEnabled = false
local speedBase = 16
local jumpBase = 50
local speedApplied = nil
local jumpApplied = nil
local noclipEnabled = false
local noclipOriginal = setmetatable({}, { __mode = "k" })

local function getHumanoid()
    local character = LocalPlayer.Character
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function readJumpProperty(humanoid)
    if not humanoid then
        return 50
    end
    if humanoid.UseJumpPower then
        return humanoid.JumpPower
    end
    return humanoid.JumpHeight
end

local function writeJumpProperty(humanoid, value)
    if not humanoid then
        return
    end
    if humanoid.UseJumpPower then
        humanoid.JumpPower = value
    else
        humanoid.JumpHeight = value
    end
end

local function clampMovementValue(value)
    local number = tonumber(value)
    if not number then
        return nil
    end
    return math.clamp(number, 1, 999999)
end

local function createMovementControl(title, initialValue, callback)
    local page = Movement._page
    local root = Instance.new("Frame")
    root.Name = title:gsub("%s+", "") .. "Control"
    root.BackgroundTransparency = 1
    root.Size = UDim2.new(1, -20, 0, 74)
    root.Parent = page

    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.fromOffset(4, 0)
    titleLabel.Size = UDim2.new(0.58, -4, 0, 22)
    titleLabel.Font = Enum.Font.GothamMedium
    titleLabel.TextSize = 13
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextColor3 = Color3.fromRGB(235, 235, 235)
    titleLabel.Text = title
    titleLabel.Parent = root

    local input = Instance.new("TextBox")
    input.Name = "ValueInput"
    input.AnchorPoint = Vector2.new(1, 0)
    input.Position = UDim2.new(1, -2, 0, 0)
    input.Size = UDim2.fromOffset(92, 22)
    input.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    input.BorderSizePixel = 0
    input.Font = Enum.Font.Gotham
    input.TextSize = 12
    input.TextColor3 = Color3.fromRGB(255, 255, 255)
    input.ClearTextOnFocus = false
    input.Text = tostring(math.floor(initialValue))
    input.Parent = root
    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 5)

    local track = Instance.new("TextButton")
    track.Name = "SliderTrack"
    track.AutoButtonColor = false
    track.Text = ""
    track.Position = UDim2.fromOffset(4, 35)
    track.Size = UDim2.new(1, -8, 0, 12)
    track.BackgroundColor3 = Color3.fromRGB(48, 48, 58)
    track.BorderSizePixel = 0
    track.Parent = root
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(168, 85, 247)
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(0, 0, 0.5, 0)
    knob.Size = UDim2.fromOffset(16, 16)
    knob.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
    knob.BorderSizePixel = 0
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local rangeLabel = Instance.new("TextLabel")
    rangeLabel.BackgroundTransparency = 1
    rangeLabel.Position = UDim2.fromOffset(4, 51)
    rangeLabel.Size = UDim2.new(1, -8, 0, 17)
    rangeLabel.Font = Enum.Font.Gotham
    rangeLabel.TextSize = 10
    rangeLabel.TextColor3 = Color3.fromRGB(165, 165, 175)
    rangeLabel.TextXAlignment = Enum.TextXAlignment.Left
    rangeLabel.Parent = root

    local control = {
        Root = root,
        Value = initialValue,
        Base = math.max(1, initialValue),
        Enabled = false,
    }

    local function visualBounds()
        return control.Base, math.max(1000, control.Base)
    end

    local function render()
        local minimum, maximum = visualBounds()
        local pct
        if maximum <= minimum then
            pct = 0
        else
            pct = math.clamp((control.Value - minimum) / (maximum - minimum), 0, 1)
        end
        fill.Size = UDim2.new(pct, 0, 1, 0)
        knob.Position = UDim2.new(pct, 0, 0.5, 0)
        rangeLabel.Text = tostring(math.floor(minimum)) .. "  —  " .. tostring(math.floor(maximum)) .. "  |  Max input: 999999"
        input.Text = tostring(math.floor(control.Value))
    end

    function control:SetBase(value)
        control.Base = math.max(1, tonumber(value) or 1)
        render()
    end

    function control:Set(value, silent)
        local clamped = clampMovementValue(value)
        if not clamped then
            return
        end
        control.Value = clamped
        render()
        if not silent and callback then
            callback(control.Value)
        end
    end

    local dragging = false

    local function setFromX(x)
        local minimum, maximum = visualBounds()
        local width = math.max(1, track.AbsoluteSize.X)
        local pct = math.clamp((x - track.AbsolutePosition.X) / width, 0, 1)
        control:Set(minimum + (maximum - minimum) * pct, false)
    end

    track.InputBegan:Connect(function(inputObject)
        if inputObject.UserInputType == Enum.UserInputType.MouseButton1
            or inputObject.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromX(inputObject.Position.X)
        end
    end)

    Window:Connect(UserInputService.InputChanged, function(inputObject)
        if dragging and (inputObject.UserInputType == Enum.UserInputType.MouseMovement
            or inputObject.UserInputType == Enum.UserInputType.Touch) then
            setFromX(inputObject.Position.X)
        end
    end)

    Window:Connect(UserInputService.InputEnded, function(inputObject)
        if inputObject.UserInputType == Enum.UserInputType.MouseButton1
            or inputObject.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    input.FocusLost:Connect(function()
        local value = clampMovementValue(input.Text)
        if not value then
            render()
            return
        end
        control:Set(value, false)
    end)

    render()
    return control
end

local function applySpeed(value)
    local humanoid = getHumanoid()
    if not humanoid then
        return
    end
    local actual = clampMovementValue(value)
    if not actual then
        return
    end
    humanoid.WalkSpeed = actual
    speedApplied = actual
end

local function applyJump(value)
    local humanoid = getHumanoid()
    if not humanoid then
        return
    end
    local actual = clampMovementValue(value)
    if not actual then
        return
    end
    writeJumpProperty(humanoid, actual)
    jumpApplied = actual
end

local function setSpeedhack(enabled)
    speedEnabled = enabled
    local humanoid = getHumanoid()
    if not humanoid then
        return
    end
    if enabled then
        speedBase = humanoid.WalkSpeed
        if speedControl then
            speedControl:SetBase(speedBase)
            applySpeed(speedControl.Value)
        else
            applySpeed(speedBase)
        end
    else
        humanoid.WalkSpeed = speedBase
        speedApplied = nil
    end
end

local function setJumphack(enabled)
    jumpEnabled = enabled
    local humanoid = getHumanoid()
    if not humanoid then
        return
    end
    if enabled then
        jumpBase = readJumpProperty(humanoid)
        if jumpControl then
            jumpControl:SetBase(jumpBase)
            applyJump(jumpControl.Value)
        else
            applyJump(jumpBase)
        end
    else
        writeJumpProperty(humanoid, jumpBase)
        jumpApplied = nil
    end
end

local function restoreNoclip()
    for part, value in pairs(noclipOriginal) do
        if part and part.Parent then
            part.CanCollide = value
        end
    end
    table.clear(noclipOriginal)
end

local function updateNoclip()
    local character = LocalPlayer.Character
    if not character then
        return
    end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            if noclipOriginal[part] == nil then
                noclipOriginal[part] = part.CanCollide
            end
            if part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end

local noclipToggle = Movement:Toggle({
    Text = "Noclip",
    Default = false,
    Callback = function(state)
        noclipEnabled = state
        if not state then
            restoreNoclip()
        end
    end,
})

local speedToggle = Movement:Toggle({
    Text = "Speed hack",
    Default = false,
    Callback = function(state)
        if speedControl then
            speedControl.Enabled = state
        end
        setSpeedhack(state)
    end,
})

local jumpToggle = Movement:Toggle({
    Text = "Jump hack",
    Default = false,
    Callback = function(state)
        if jumpControl then
            jumpControl.Enabled = state
        end
        setJumphack(state)
    end,
})

local initialHumanoid = getHumanoid()
if initialHumanoid then
    speedBase = initialHumanoid.WalkSpeed
    jumpBase = readJumpProperty(initialHumanoid)
end

speedControl = createMovementControl("Speed value", speedBase, function(value)
    if speedControl and speedControl.Enabled then
        applySpeed(value)
    end
end)

jumpControl = createMovementControl("Jump value", jumpBase, function(value)
    if jumpControl and jumpControl.Enabled then
        applyJump(value)
    end
end)

speedControl.Enabled = speedEnabled
jumpControl.Enabled = jumpEnabled

noclipToggle.Frame.LayoutOrder = 1
speedToggle.Frame.LayoutOrder = 2
speedControl.Root.LayoutOrder = 3
jumpToggle.Frame.LayoutOrder = 4
jumpControl.Root.LayoutOrder = 5

Window:Loop(MOVEMENT_INTERVAL, function()
    if noFogEnabled then
        setNoFog(true)
    end

    local currentHumanoid = getHumanoid()
    if not currentHumanoid then
        return
    end

    if not speedEnabled then
        speedBase = currentHumanoid.WalkSpeed
        speedControl:SetBase(speedBase)
        speedControl:Set(speedBase, true)
    elseif speedApplied == nil or math.abs(currentHumanoid.WalkSpeed - speedApplied) > 0.01 then
        if speedApplied ~= nil then
            speedBase = currentHumanoid.WalkSpeed
            speedControl:SetBase(speedBase)
        end
        applySpeed(speedControl.Value)
    end

    local currentJump = readJumpProperty(currentHumanoid)
    if not jumpEnabled then
        jumpBase = currentJump
        jumpControl:SetBase(jumpBase)
        jumpControl:Set(jumpBase, true)
    elseif jumpApplied == nil or math.abs(currentJump - jumpApplied) > 0.01 then
        if jumpApplied ~= nil then
            jumpBase = currentJump
            jumpControl:SetBase(jumpBase)
        end
        applyJump(jumpControl.Value)
    end
end)

Window:Connect(RunService.Heartbeat, function()
    if fullbrightEnabled then
        applyFullbright()
    end
    if noFogEnabled and Lighting.FogEnd ~= NO_FOG_DISTANCE then
        Lighting.FogEnd = NO_FOG_DISTANCE
    end
end)

Window:Connect(RunService.Stepped, function()
    if noclipEnabled then
        updateNoclip()
    end
end)

Window:Connect(LocalPlayer.CharacterAdded, function(character)
    local newHumanoid = character:WaitForChild("Humanoid", 15)
    if not newHumanoid then
        return
    end
    speedBase = newHumanoid.WalkSpeed
    jumpBase = readJumpProperty(newHumanoid)
    speedApplied = nil
    jumpApplied = nil
    if speedEnabled then
        applySpeed(speedControl.Value)
    end
    if jumpEnabled then
        applyJump(jumpControl.Value)
    end
end)

Window:OnClose(function()
    allEnabled = false
    aimEnabled = false
    currentTarget = nil
    preTarget = nil
    forcedLock = false
    destroyAimGui()
    RunService:UnbindFromRenderStep(AIM_UPDATE_NAME)
    RunService:UnbindFromRenderStep(PROXY_UPDATE_NAME)

    setFullbright(false)
    setNoFog(false)
    speedEnabled = false
    jumpEnabled = false
    local currentHumanoid = getHumanoid()
    if currentHumanoid then
        currentHumanoid.WalkSpeed = speedBase
        writeJumpProperty(currentHumanoid, jumpBase)
    end
    noclipEnabled = false
    restoreNoclip()

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
