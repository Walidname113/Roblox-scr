local uis = game:GetService("UserInputService")
local rs = game:GetService("RunService")
local players = game:GetService("Players")
local plr = players.LocalPlayer
local gui = script.Parent or plr.PlayerGui:FindFirstChild("InjectedGui") -- GUI

local main = gui and gui:FindFirstChild("Frame") or nil
if not main then
	warn("Main GUI frame not found")
	return
end

local nameEspEnabled = false

local espBtn = Instance.new("TextButton", main)
espBtn.Size = UDim2.new(0, 220, 0, 25)
espBtn.Position = UDim2.new(0, 10, 0, 225)
espBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
espBtn.TextColor3 = Color3.new(1, 1, 1)
espBtn.Font = Enum.Font.Gotham
espBtn.TextSize = 14
espBtn.Text = "Enable NameEsp"
Instance.new("UICorner", espBtn)

local espLabels = {}

local function createEspLabel(plr)
	local char = plr.Character
	if not char then return end
	local head = char:FindFirstChild("Head")
	if not head then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "NameEsp"
	billboard.Adornee = head
	billboard.Size = UDim2.new(0, 100, 0, 25)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.AlwaysOnTop = true

	local label = Instance.new("TextLabel", billboard)
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Text = plr.Name
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.Gotham
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center

	billboard.Parent = gui

	espLabels[plr] = billboard
end

local function removeEspLabel(plr)
	if espLabels[plr] then
		espLabels[plr]:Destroy()
		espLabels[plr] = nil
	end
end

local function toggleNameEsp(state)
	nameEspEnabled = state

	if nameEspEnabled then
		for _, p in pairs(players:GetPlayers()) do
			if p ~= plr then
				createEspLabel(p)
			end
		end

		players.PlayerAdded:Connect(function(p)
			if nameEspEnabled and p ~= plr then
				p.CharacterAdded:Connect(function()
					createEspLabel(p)
				end)
			end
		end)

		players.PlayerRemoving:Connect(function(p)
			removeEspLabel(p)
		end)

		for _, p in pairs(players:GetPlayers()) do
			if p ~= plr then
				p.CharacterAdded:Connect(function()
					removeEspLabel(p)
					createEspLabel(p)
				end)
			end
		end

	else
		for p, label in pairs(espLabels) do
			if label then
				label:Destroy()
			end
		end
		espLabels = {}
	end
end

espBtn.MouseButton1Click:Connect(function()
	toggleNameEsp(not nameEspEnabled)
	espBtn.Text = nameEspEnabled and "Disable NameEsp" or "Enable NameEsp"
end)
