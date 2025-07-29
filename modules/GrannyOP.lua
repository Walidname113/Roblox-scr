-- Names ESP fix
local requiredGameId = 2165551367
if game.GameId ~= requiredGameId then return end

local uiurl = "https://raw.githubusercontent.com/Walidname113/Roblox-scr/main/uncoded.lua"
local success, source = pcall(function()
    return game:HttpGet(uiurl)
end)
if not success then warn("Error load UI:", source) return end
local moduleFunc, err = loadstring(source)
if not moduleFunc then warn("Error module func:", err) return end

local uiModule = moduleFunc()
local ui = uiModule.CreateUI("Granny by Kiyatsuka | Version: 1.0.8 Public")

function ui.CreateToggleWithInput(title, parent, data)  
    local container = Instance.new("Frame")  
    container.Size = UDim2.new(1, 0, 0, 30)  
    container.BackgroundTransparency = 1  
    container.Parent = parent  
  
    local toggle = Instance.new("TextButton")  
    toggle.Size = UDim2.new(0, 100, 1, 0)  
    toggle.Position = UDim2.new(0, 0, 0, 0)  
    toggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)  
    toggle.TextColor3 = Color3.new(1, 1, 1)  
    toggle.Text = title  
    toggle.Parent = container  
  
    local input = Instance.new("TextBox")  
    input.Size = UDim2.new(0, 60, 1, 0)  
    input.Position = UDim2.new(0, 110, 0, 0)  
    input.BackgroundColor3 = Color3.fromRGB(30, 30, 30)  
    input.TextColor3 = Color3.new(1, 1, 1)  
    input.Text = type(data.default) == "function" and data.default() or (data.default or "")  
    input.Parent = container  
  
    local reset = Instance.new("TextButton")  
    reset.Size = UDim2.new(0, 30, 1, 0)  
    reset.Position = UDim2.new(0, 180, 0, 0)  
    reset.BackgroundColor3 = Color3.fromRGB(80, 30, 30)  
    reset.TextColor3 = Color3.new(1, 1, 1)  
    reset.Text = "X"  
    reset.Parent = container  
  
    local state = false  
  
    toggle.MouseButton1Click:Connect(function()  
        state = not state  
        toggle.BackgroundColor3 = state and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(50, 50, 50)  
        if data.onToggle then  
            data.onToggle(state, input.Text)  
        end  
    end)  
  
    input.FocusLost:Connect(function()  
        if data.onToggle then  
            data.onToggle(state, input.Text)  
        end  
    end)  
  
    reset.MouseButton1Click:Connect(function()  
        input.Text = type(data.default) == "function" and data.default() or (data.default or "")  
        if data.reset then  
            data.reset()  
        end  
    end)  
  
    return container  
end

local highlightsMap = {} -- [object] = {highlight, type="player"/"tool"/etc}

local function addHighlight(obj, espType, color, extra)
    if not obj or not obj.Parent then return end
    local old = highlightsMap[obj]
    if old then
        old.highlight:Destroy()
        local bb = obj:FindFirstChild("ToolESP_Billboard")
        if bb then bb:Destroy() end
        highlightsMap[obj] = nil
    end
    local hl = Instance.new("Highlight")
    hl.Adornee = obj
    hl.FillColor = color
    hl.FillTransparency = extra and extra.FillTransparency or 1
    hl.OutlineColor = color
    hl.OutlineTransparency = extra and extra.OutlineTransparency or 0
    hl.Parent = obj
    highlightsMap[obj] = {highlight = hl, type = espType}
end

local function removeHighlight(obj)
    if highlightsMap[obj] then
        highlightsMap[obj].highlight:Destroy()
        highlightsMap[obj] = nil
    end
    local bb = obj:FindFirstChild("ToolESP_Billboard")
    if bb then bb:Destroy() end
end

local function clearESPByType(t)
    for obj, data in pairs(highlightsMap) do
        if data.type == t then
            data.highlight:Destroy()
            local bb = obj:FindFirstChild("ToolESP_Billboard")
            if bb then bb:Destroy() end
            highlightsMap[obj] = nil
        end
    end
end

local player = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local mainContainer = ui.CreateCategory("Main")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer

local noclipConnection
local originalCameraMode
local originalWalkSpeed
local originalJumpPower
local infinityJumpEnabled = false

local function showJumpButton()
    local touchGui = player:WaitForChild("PlayerGui"):FindFirstChild("TouchGui")
    if touchGui then
        local jumpButton = touchGui:FindFirstChild("JumpButton", true)
        if jumpButton then
            jumpButton.Visible = true
        end
    end
end

local function cacheOriginalValues()
    task.wait(1)
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        originalWalkSpeed = humanoid.WalkSpeed
        originalJumpPower = humanoid.JumpPower
    end
    if not originalCameraMode then
        originalCameraMode = player.CameraMode
    end
end

if player.Character then
    cacheOriginalValues()
else
    player.CharacterAdded:Once(cacheOriginalValues)
end

player.CharacterAdded:Connect(function()
    task.wait(1)
    if noclipConnection then enableNoclip() end
    cacheOriginalValues()
end)

local function enableNoclip()
    if noclipConnection then return end
    noclipConnection = RunService.Stepped:Connect(function()
        local char = player.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end

local function disableNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
end

ui.CreateToggle("Noclip", mainContainer, function(state)
    if state then
        enableNoclip()
    else
        disableNoclip()
    end
end)

ui.CreateToggle("Freecam", mainContainer, function(state)
    if state then
        player.CameraMode = Enum.CameraMode.Classic
    else
        if originalCameraMode then
            player.CameraMode = originalCameraMode
        end
    end
end)

ui.CreateToggle("InfinityJump", mainContainer, function(state)
    infinityJumpEnabled = state
    if state then
        showJumpButton()
    end
end)

UserInputService.JumpRequest:Connect(function()
    if infinityJumpEnabled and player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
        player.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

ui.CreateToggleWithInput("SpeedHack", mainContainer, {
    default = function()
        return tostring(originalWalkSpeed or 16)
    end,
    reset = function()
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid and originalWalkSpeed then
            humanoid.WalkSpeed = originalWalkSpeed
        end
    end,
    onToggle = function(state, inputValue)
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        local speed = tonumber(inputValue)
        if humanoid and speed then
            humanoid.WalkSpeed = state and speed or (originalWalkSpeed or 16)
        end
    end
})

ui.CreateToggleWithInput("JumpHack", mainContainer, {
    default = function()
        return tostring(originalJumpPower or 50)
    end,
    reset = function()
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid and originalJumpPower then
            humanoid.JumpPower = originalJumpPower
        end
    end,
    onToggle = function(state, inputValue)
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        local power = tonumber(inputValue)
        if humanoid and power then
            humanoid.JumpPower = state and power or (originalJumpPower or 50)
        end
        if state then
            showJumpButton()
        end
    end
})

local tpContainer = Instance.new("Frame")
tpContainer.Size = UDim2.new(1, 0, 0, 30)
tpContainer.BackgroundTransparency = 1
tpContainer.Parent = mainContainer

local dropdownOpen = false
local selectedPlayer = nil
local playersList = {}

local dropdownButton = Instance.new("TextButton")
dropdownButton.Text = "▲ Select Player"
dropdownButton.Size = UDim2.new(0, 150, 1, 0)
dropdownButton.Position = UDim2.new(0, 0, 0, 0)
dropdownButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
dropdownButton.TextColor3 = Color3.new(1, 1, 1)
dropdownButton.Parent = tpContainer

local tpButton = Instance.new("TextButton")
tpButton.Text = "TP"
tpButton.Size = UDim2.new(0, 40, 1, 0)
tpButton.Position = UDim2.new(0, 155, 0, 0)
tpButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
tpButton.TextColor3 = Color3.new(1, 1, 1)
tpButton.Parent = tpContainer

local dropdownFrame = Instance.new("ScrollingFrame")
dropdownFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
dropdownFrame.BorderSizePixel = 0
dropdownFrame.Size = UDim2.new(0, 150, 0, 100)
dropdownFrame.Position = UDim2.new(0, 0, 1, 0)
dropdownFrame.Visible = false
dropdownFrame.ZIndex = 10
dropdownFrame.ClipsDescendants = true
dropdownFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
dropdownFrame.ScrollBarThickness = 5
dropdownFrame.Parent = tpContainer

local function clearList()
	for _, child in ipairs(dropdownFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

local function refreshPlayerList()
	clearList()
	playersList = {}
	local y = 0
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			table.insert(playersList, plr)
			local option = Instance.new("TextButton")
			option.Size = UDim2.new(1, 0, 0, 20)
			option.Position = UDim2.new(0, 0, 0, y)
			option.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			option.TextColor3 = Color3.new(1, 1, 1)
			option.Text = plr.Name
			option.ZIndex = 11
			option.Parent = dropdownFrame

			option.MouseButton1Click:Connect(function()
				selectedPlayer = plr
				dropdownButton.Text = "▲ " .. plr.Name
				dropdownFrame.Visible = false
				dropdownOpen = false
			end)

			y = y + 20
		end
	end
	dropdownFrame.CanvasSize = UDim2.new(0, 0, 0, y)
end

dropdownButton.MouseButton1Click:Connect(function()
	dropdownOpen = not dropdownOpen
	dropdownFrame.Visible = dropdownOpen
	dropdownButton.Text = (dropdownOpen and "▼ " or "▲ ") .. (selectedPlayer and selectedPlayer.Name or "Select Player")
	if dropdownOpen then
		refreshPlayerList()
	end
end)

tpButton.MouseButton1Click:Connect(function()
	if selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
		local root = selectedPlayer.Character.HumanoidRootPart
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			player.Character.HumanoidRootPart.CFrame = root.CFrame + Vector3.new(0, 3, 0)
		end
	end
end)

task.spawn(function()
	while true do
		if dropdownOpen then
			refreshPlayerList()
		end
		task.wait(10)
	end
end)

local contentContainer = ui.CreateCategory("ESP")

local toolESPEnabled = false
local toolsESPManuallyEnabled = false
local playerESPEnabled = false
local enemyESPEnabled = false
local trapESPEnabled = false
local namesESPEnabled = false

local highlightsMap = {}
local nameTagsMap = {}

local playerESPConnection = nil
local enemyESPConnection = nil
local trapESPConnection = nil

local function addHighlight(obj, espType, color, extra)
	if not obj or not obj.Parent then return end
	local old = highlightsMap[obj]
	if old then
		old.highlight:Destroy()
		highlightsMap[obj] = nil
	end
	local hl = Instance.new("Highlight")
	hl.Adornee = obj
	hl.FillColor = color
	hl.FillTransparency = extra and extra.FillTransparency or 1
	hl.OutlineColor = color
	hl.OutlineTransparency = extra and extra.OutlineTransparency or 0
	hl.Parent = obj
	highlightsMap[obj] = {highlight = hl, type = espType}
end

local function removeHighlight(obj)
	if highlightsMap[obj] then
		highlightsMap[obj].highlight:Destroy()
		highlightsMap[obj] = nil
	end
	if nameTagsMap[obj] then
		nameTagsMap[obj]:Destroy()
		nameTagsMap[obj] = nil
	end
end

local function clearESPByType(t)
	for obj, data in pairs(highlightsMap) do
		if data.type == t then
			data.highlight:Destroy()
			highlightsMap[obj] = nil
		end
	end
	if t == "player" or t == "enemy" then
		for obj, bb in pairs(nameTagsMap) do
			if obj and bb then
				bb:Destroy()
			end
		end
		table.clear(nameTagsMap)
	end
end

local function addNameTag(model, text, color)
	if not model:FindFirstChild("HumanoidRootPart") then return end
	if nameTagsMap[model] then nameTagsMap[model]:Destroy() end
	local bb = Instance.new("BillboardGui")
	bb.Name = "NameTag"
	bb.Size = UDim2.new(0, 100, 0, 20)
	bb.Adornee = model.HumanoidRootPart
	bb.AlwaysOnTop = true
	bb.StudsOffset = Vector3.new(0, 2.5, 0)
	bb.Parent = model
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = color
	lbl.TextScaled = true
	lbl.Font = Enum.Font.SourceSans
	lbl.TextStrokeTransparency = 0.5
	lbl.Parent = bb
	nameTagsMap[model] = bb
end

local function connectPlayerESPHandlers(playersFolder)
	if playerESPConnection then
		playerESPConnection:Disconnect()
	end
	if enemyESPConnection then
		enemyESPConnection:Disconnect()
	end

	if playerESPEnabled then
		playerESPConnection = playersFolder.ChildAdded:Connect(function(obj)
			if obj:IsA("Model") and obj.Name ~= "Enemy" then
				addHighlight(obj, "player", Color3.fromRGB(0,255,0))
				if namesESPEnabled then
					addNameTag(obj, obj.DisplayName or obj.Name, Color3.fromRGB(0, 255, 0))
				end
			end
		end)
	end

	if enemyESPEnabled then
		enemyESPConnection = playersFolder.ChildAdded:Connect(function(obj)
			if obj:IsA("Model") and obj.Name == "Enemy" then
				addHighlight(obj, "enemy", Color3.fromRGB(255,0,0))
				if namesESPEnabled then
					addNameTag(obj, obj.DisplayName or obj.Name, Color3.fromRGB(255, 0, 0))
				end
			end
		end)
	end

	if namesESPEnabled then
		for _, model in ipairs(playersFolder:GetChildren()) do
			if model:IsA("Model") and model:FindFirstChild("HumanoidRootPart") then
				if model.Name == "Enemy" and enemyESPEnabled then
					addNameTag(model, model.DisplayName or model.Name, Color3.fromRGB(255, 0, 0))
				elseif model.Name ~= "Enemy" and playerESPEnabled then
					addNameTag(model, model.DisplayName or model.Name, Color3.fromRGB(0, 255, 0))
				end
			end
		end
	end
end

local function setupToolESP()
	clearESPByType("tool")
	local map = workspace:FindFirstChild("Map")
	if not map then return end
	local currentMap
	for _, folder in ipairs(map:GetChildren()) do
		if folder:IsA("Folder") and folder.Name ~= "Players" and folder.Name ~= "Traps" then
			currentMap = folder
			break
		end
	end
	if not currentMap then return end
	local toolsFolder = currentMap:FindFirstChild("Tools")
	if not toolsFolder then return end

	local function addToolESP(toolModel)
		if not toolModel:IsA("Model") then return end
		addHighlight(toolModel, "tool", Color3.fromRGB(255,105,180), {FillTransparency=0.8, OutlineTransparency=1})
	end

	for _, tool in ipairs(toolsFolder:GetChildren()) do
		addToolESP(tool)
	end

	toolsFolder.ChildAdded:Connect(function(child)
		if toolESPEnabled then
			addToolESP(child)
		end
	end)

	toolsFolder.ChildRemoved:Connect(removeHighlight)
end

workspace.ChildAdded:Connect(function(child)
	if child.Name ~= "Map" then return end
	task.wait(1)

	if toolESPEnabled then
		clearESPByType("tool")
		setupToolESP()
	end

	if enemyESPEnabled then
		clearESPByType("enemy")
		for _, p in ipairs(child.Players:GetChildren()) do
			if p.Name == "Enemy" then
				addHighlight(p, "enemy", Color3.fromRGB(255,0,0))
				if namesESPEnabled then
					addNameTag(p, p.DisplayName or p.Name, Color3.fromRGB(255, 0, 0))
				end
			end
		end
	end

	if playerESPEnabled then
		clearESPByType("player")
		for _, p in ipairs(child.Players:GetChildren()) do
			if p.Name ~= "Enemy" then
				addHighlight(p, "player", Color3.fromRGB(0,255,0))
				if namesESPEnabled then
					addNameTag(p, p.DisplayName or p.Name, Color3.fromRGB(0, 255, 0))
				end
			end
		end
	end

	if namesESPEnabled then
		local playersFolder = child:FindFirstChild("Players")
		if playersFolder then
			for _, model in ipairs(playersFolder:GetChildren()) do
				if model:IsA("Model") and model:FindFirstChild("HumanoidRootPart") then
					if model.Name == "Enemy" and enemyESPEnabled then
						addNameTag(model, model.DisplayName or model.Name, Color3.fromRGB(255, 0, 0))
					elseif model.Name ~= "Enemy" and playerESPEnabled then
						addNameTag(model, model.DisplayName or model.Name, Color3.fromRGB(0, 255, 0))
					end
				end
			end
		end
	end

	if trapESPEnabled then
		clearESPByType("trap")
		for _, trap in ipairs(child.Traps:GetChildren()) do
			if trap:IsA("Model") then
				addHighlight(trap, "trap", Color3.fromRGB(255,0,0))
			end
		end
	end
end)

ui.CreateToggle("Tools ESP", contentContainer, function(state)
	toolESPEnabled = state
	toolsESPManuallyEnabled = state
	clearESPByType("tool")
	if state then setupToolESP() end
end)

ui.CreateToggle("Players ESP", contentContainer, function(state)
	playerESPEnabled = state
	clearESPByType("player")
	local folder = workspace:FindFirstChild("Map")
	local players = folder and folder:FindFirstChild("Players")
	if not players then return end
	if state then
		connectPlayerESPHandlers(players)
		for _, obj in ipairs(players:GetChildren()) do
			if obj.Name ~= "Enemy" then
				addHighlight(obj, "player", Color3.fromRGB(0,255,0))
				if namesESPEnabled then
					addNameTag(obj, obj.DisplayName or obj.Name, Color3.fromRGB(0, 255, 0))
				end
			end
		end
	elseif toolsESPManuallyEnabled then
		setupToolESP()
	end
end)

ui.CreateToggle("Enemy ESP", contentContainer, function(state)
	enemyESPEnabled = state
	clearESPByType("enemy")
	local folder = workspace:FindFirstChild("Map")
	local players = folder and folder:FindFirstChild("Players")
	if not players then return end
	if state then
		connectPlayerESPHandlers(players)
		for _, obj in ipairs(players:GetChildren()) do
			if obj.Name == "Enemy" then
				addHighlight(obj, "enemy", Color3.fromRGB(255,0,0))
				if namesESPEnabled then
					addNameTag(obj, obj.DisplayName or obj.Name, Color3.fromRGB(255, 0, 0))
				end
			end
		end
	end
end)

ui.CreateToggle("Traps ESP", contentContainer, function(state)
	trapESPEnabled = state
	if trapESPConnection then
		trapESPConnection:Disconnect()
	end
	clearESPByType("trap")
	if not state then return end
	local map = workspace:FindFirstChild("Map")
	local traps = map and map:FindFirstChild("Traps")
	if not traps then return end
	for _, obj in ipairs(traps:GetChildren()) do
		if obj:IsA("Model") then
			addHighlight(obj, "trap", Color3.fromRGB(255, 0, 0))
		end
	end
	trapESPConnection = traps.ChildAdded:Connect(function(obj)
		if trapESPEnabled and obj:IsA("Model") then
			addHighlight(obj, "trap", Color3.fromRGB(255, 0, 0))
		end
	end)
end)

ui.CreateToggle("Names ESP", contentContainer, function(state)
	namesESPEnabled = state

	local folder = workspace:FindFirstChild("Map")
	local players = folder and folder:FindFirstChild("Players")
	if not players then return end

	for _, model in ipairs(players:GetChildren()) do
		if model:IsA("Model") and model:FindFirstChild("HumanoidRootPart") then
			if model.Name == "Enemy" and enemyESPEnabled then
				if state then
					addNameTag(model, model.DisplayName or model.Name, Color3.fromRGB(255, 0, 0))
				else
					removeHighlight(model)
					addHighlight(model, "enemy", Color3.fromRGB(255, 0, 0))
				end
			elseif model.Name ~= "Enemy" and playerESPEnabled then
				if state then
					addNameTag(model, model.DisplayName or model.Name, Color3.fromRGB(0, 255, 0))
				else
					removeHighlight(model)
					addHighlight(model, "player", Color3.fromRGB(0, 255, 0))
				end
			end
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
