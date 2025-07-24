local requiredGameId = 2165551367
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

local ui = uiModule.CreateUI("Granny by Kiyatsuka | Version: 1.0.2 Public")

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

local mainContainer = ui.CreateCategory("Main")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
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

local contentContainer = ui.CreateCategory("ESP")

local playersFolder = workspace:WaitForChild("Map"):WaitForChild("Players")
local trapsFolder = workspace:WaitForChild("Map"):WaitForChild("Traps")

local grannyESP, playerESP, trapESP, toolESP = {}, {}, {}, {}

local function createHighlight(model, color)
    local highlight = Instance.new("Highlight")
    highlight.Adornee = model
    highlight.FillTransparency = 1
    highlight.OutlineColor = color
    highlight.OutlineTransparency = 0
    highlight.Parent = model
    return highlight
end

local function clearESP(list)
    for _, esp in pairs(list) do
        if esp and esp.Parent then
            esp:Destroy()
        end
    end
    table.clear(list)
end

ui.CreateToggle("Enemy ESP", contentContainer, function(enabled)
    clearESP(grannyESP)
    if enabled then
        local playersFolder = workspace:WaitForChild("Map"):FindFirstChild("Players")
        if not playersFolder then return end

        for _, enemy in ipairs(playersFolder:GetChildren()) do
            if enemy.Name == "Enemy" then
                table.insert(grannyESP, createHighlight(enemy, Color3.fromRGB(255, 0, 0)))
            end
        end
    end
end)

ui.CreateToggle("Players ESP", contentContainer, function(enabled)
    clearESP(playerESP)
    if enabled then
        local playersFolder = workspace:WaitForChild("Map"):FindFirstChild("Players")
        if not playersFolder then return end

        for _, plr in ipairs(playersFolder:GetChildren()) do
            if plr.Name ~= "Enemy" then
                table.insert(playerESP, createHighlight(plr, Color3.fromRGB(0, 255, 0)))
            end
        end

        playersFolder.ChildAdded:Connect(function(plr)
            task.wait(1)
            if plr.Name ~= "Enemy" then
                table.insert(playerESP, createHighlight(plr, Color3.fromRGB(0, 255, 0)))
            end
        end)
    end
end)

ui.CreateToggle("Traps ESP", contentContainer, function(enabled)
    clearESP(trapESP)
    if enabled then
        local trapsFolder = workspace:WaitForChild("Map"):FindFirstChild("Traps")
        if not trapsFolder then return end

        for _, trapModel in ipairs(trapsFolder:GetChildren()) do
            if trapModel:IsA("Model") then
                table.insert(trapESP, createHighlight(trapModel, Color3.fromRGB(255, 0, 0)))
            end
        end

        trapsFolder.ChildAdded:Connect(function(trapModel)
            task.wait(1)
            if trapModel:IsA("Model") then
                table.insert(trapESP, createHighlight(trapModel, Color3.fromRGB(255, 0, 0)))
            end
        end)
    end
end)

ui.CreateToggle("Tools ESP", contentContainer, function(enabled)
    clearESP(toolESP)
    if enabled then
        local mapFolder = workspace:WaitForChild("Map")
        local currentMap = nil
        for _, child in ipairs(mapFolder:GetChildren()) do
            if child:IsA("Folder") and child.Name ~= "Players" and child.Name ~= "Traps" then
                currentMap = child
                break
            end
        end
        if not currentMap then return end

        local toolsFolder = currentMap:FindFirstChild("Tools")
        if not toolsFolder then return end

        local function addESP(toolModel)
            if not toolModel:IsA("Model") then return end

            local highlight = Instance.new("Highlight")
            highlight.FillColor = Color3.fromRGB(255, 105, 180)
            highlight.OutlineTransparency = 1
            highlight.Adornee = toolModel
            highlight.Parent = toolModel
            table.insert(toolESP, highlight)

            local primary = toolModel.PrimaryPart or toolModel:FindFirstChildWhichIsA("BasePart")
            if primary then
                local billboard = Instance.new("BillboardGui")
                billboard.Size = UDim2.new(0, 100, 0, 20)
                billboard.StudsOffset = Vector3.new(0, 2, 0)
                billboard.Adornee = primary
                billboard.AlwaysOnTop = true
                billboard.Parent = toolModel

                local textLabel = Instance.new("TextLabel")
                textLabel.Size = UDim2.new(1, 0, 1, 0)
                textLabel.BackgroundTransparency = 1
                textLabel.Text = toolModel.Name
                textLabel.TextColor3 = Color3.fromRGB(255, 105, 180)
                textLabel.TextScaled = true
                textLabel.Font = Enum.Font.SourceSans
                textLabel.TextStrokeTransparency = 0.5
                textLabel.Parent = billboard

                table.insert(toolESP, billboard)
            end
        end

        for _, toolModel in ipairs(toolsFolder:GetChildren()) do
            addESP(toolModel)
        end

        toolsFolder.ChildAdded:Connect(function(toolModel)
            task.wait(1)
            addESP(toolModel)
        end)
    end
end)

ui.OpenFirstCategory()
