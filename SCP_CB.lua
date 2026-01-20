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
local ui = uiModule.CreateUI("SCP:RB by Kiyatsuka | Version: 1.0.3 Public.")
ui.SetMinimizedImage("130805202254686")

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local MAX_DISTANCE = 1200
local UPDATE_INTERVAL = 0.1

local highlights = {}
local billboards = {}
local healthGuis = {}
local teamSettings = {}
local espAllEnabled = false

local function getHealthColor(perc)
	if perc >= 70 then
		return Color3.fromRGB(0, 255, 0):Lerp(Color3.fromRGB(255, 165, 0), (100 - perc) / 30)
	elseif perc >= 45 then
		return Color3.fromRGB(255, 165, 0):Lerp(Color3.fromRGB(255, 80, 80), (70 - perc) / 25)
	elseif perc >= 1 then
		return Color3.fromRGB(255, 80, 80):Lerp(Color3.fromRGB(139, 0, 0), (45 - perc) / 44)
	else
		return Color3.fromRGB(139, 0, 0):Lerp(Color3.fromRGB(0, 0, 0), 1 - perc)
	end
end

local function cleanupPlayerEffects(player)
	if highlights[player] then highlights[player]:Destroy(); highlights[player] = nil end
	if billboards[player] then billboards[player]:Destroy(); billboards[player] = nil end
	if healthGuis[player] then healthGuis[player]:Destroy(); healthGuis[player] = nil end
end

local function createHealthESP(player, character)
	local head = character:WaitForChild("Head", 5)
	if not head or healthGuis[player] then return end

	local gui = Instance.new("BillboardGui")
	gui.Name = "HealthESP"
	gui.Adornee = head
	gui.Size = UDim2.new(0, 100, 0, 20)
	gui.StudsOffset = Vector3.new(0, 1.2, 0)
	gui.AlwaysOnTop = true
	gui.Parent = head

	local label = Instance.new("TextLabel")
	label.Parent = gui
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Font = Enum.Font.Unknown
	label.FontFace = Font.new("rbxasset://fonts/families/PressStart2P.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	label.TextSize = 8
	label.TextStrokeTransparency = 0
	label.Text = "HP: 100%"
	
	healthGuis[player] = gui
end

local function create966Billboard(player, character)
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
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
	if highlights[player] then return end
	local h = Instance.new("Highlight")
	h.Adornee = character
	h.FillTransparency = 0.5
	h.OutlineTransparency = 0
	h.Enabled = false
	local teamColor = player.Team and player.Team.TeamColor.Color or Color3.new(1, 1, 1)
	h.FillColor = teamColor
	h.OutlineColor = teamColor
	h.Parent = character
	highlights[player] = h
end

local function setupVisuals(player)
	cleanupPlayerEffects(player)
	if player.Team and player.Team.Name == "Lobby" then return end
	local character = player.Character
	if not character then return end
	
	createHealthESP(player, character)
	local role = player:GetAttribute("Role")
	if role == "SCP-966" then
		create966Billboard(player, character)
	else
		createHighlight(player, character)
	end
end

local espCategory = ui.CreateCategory("ESP")

ui.CreateToggle("ESP All (No Lobby)", espCategory, function(state)
    espAllEnabled = state
end)

local targetTeams = {
    "Chaos Insurgency", "Serpents Hand", "Security Department", "Mobile Task Forces", 
    "SCP", "Foundation Personnel", "Global Occult Coalition", "Class-D"
}

for _, teamName in ipairs(targetTeams) do
    teamSettings[teamName] = false
    ui.CreateToggle("ESP " .. teamName .. " Team", espCategory, function(state)
        teamSettings[teamName] = state
    end)
end

ui.OpenFirstCategory()

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function()
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

task.spawn(function()
	while true do
		local myChar = localPlayer.Character
		local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
		
		for player, gui in pairs(healthGuis) do
			local char = player.Character
			local hum = char and char:FindFirstChild("Humanoid")
			local root = char and char:FindFirstChild("HumanoidRootPart")
			local tName = player.Team and player.Team.Name or ""
			local isEnabled = (espAllEnabled or teamSettings[tName]) and tName ~= "Lobby"
			
			if isEnabled and myRoot and root and hum then
				local dist = (myRoot.Position - root.Position).Magnitude
				if dist <= MAX_DISTANCE then
					local perc = math.clamp(math.floor((hum.Health / hum.MaxHealth) * 100), 0, 100)
					local label = gui:FindFirstChildWhichIsA("TextLabel")
					if label then
						label.Text = "HP: " .. perc .. "%"
						label.TextColor3 = getHealthColor(perc)
					end
					gui.Enabled = true
				else
					gui.Enabled = false
				end
			else
				gui.Enabled = false
			end
		end

		for player, highlight in pairs(highlights) do
            local tName = player.Team and player.Team.Name or ""
            local isEnabled = (espAllEnabled or teamSettings[tName]) and tName ~= "Lobby"
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if isEnabled and myRoot and root then
				highlight.Enabled = (myRoot.Position - root.Position).Magnitude <= MAX_DISTANCE
			else
				highlight.Enabled = false
			end
		end

		for player, billboard in pairs(billboards) do
            local tName = player.Team and player.Team.Name or ""
            local isEnabled = (espAllEnabled or teamSettings[tName]) and tName ~= "Lobby"
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if isEnabled and myRoot and root then
				billboard.Enabled = (myRoot.Position - root.Position).Magnitude <= MAX_DISTANCE
			else
				billboard.Enabled = false
			end
		end
		task.wait(UPDATE_INTERVAL)
	end
end)
