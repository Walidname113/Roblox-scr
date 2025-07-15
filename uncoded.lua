-- Roblox UI Framework (fixed stacking bug + improved tab logic)
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function log(msg)
	print("[UI_LOG]: " .. tostring(msg))
end

local gui_framework = {}
log("Инициализация фреймворка...")

-- GUI
local success, err = pcall(function()
	gui_framework.ScreenGui = Instance.new("ScreenGui")
	gui_framework.ScreenGui.Name = "UniversalUI"
	gui_framework.ScreenGui.ResetOnSpawn = false
	gui_framework.ScreenGui.IgnoreGuiInset = true
	gui_framework.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui_framework.ScreenGui.Parent = game:GetService("CoreGui")
	log("ScreenGui вставлен в CoreGui")
end)
if not success then error("Ошибка GUI: " .. tostring(err)) end

-- Тема
gui_framework.Theme = {
	BackgroundColor = Color3.fromRGB(20, 20, 20),
	Transparency = 0.25,
	TextColor = Color3.fromRGB(255, 255, 255),
	Font = Enum.Font.GothamSemibold
}

local function apply_rounding(obj, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 6)
	corner.Parent = obj
end

function gui_framework:CreateWindow(title, author)
	log("Создание окна")

	local minimized = false
	local main = Instance.new("Frame")
	main.Name = "MainUI"
	main.Size = UDim2.new(0, 400, 0, 320)
	main.Position = UDim2.new(0.5, -200, 0.5, -160)
	main.AnchorPoint = Vector2.new(0.5, 0.5)
	main.BackgroundColor3 = self.Theme.BackgroundColor
	main.BackgroundTransparency = self.Theme.Transparency
	main.ZIndex = 10
	main.Parent = self.ScreenGui

	-- Сделать draggable только заголовок
	local titleBar = Instance.new("TextLabel")
	titleBar.Size = UDim2.new(1, 0, 0, 40)
	titleBar.BackgroundTransparency = 1
	titleBar.Text = string.format("%s | by %s", title or "UI", author or "unknown")
	titleBar.Font = self.Theme.Font
	titleBar.TextColor3 = self.Theme.TextColor
	titleBar.TextSize = 20
	titleBar.ZIndex = 11
	titleBar.Parent = main
	titleBar.Active = true
	titleBar.Draggable = true

	local minimizedBtn = Instance.new("TextButton")
	minimizedBtn.Size = UDim2.new(0, 30, 0, 30)
	minimizedBtn.Position = UDim2.new(1, -70, 0, 5)
	minimizedBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 0)
	minimizedBtn.Text = "-"
	minimizedBtn.TextColor3 = Color3.new(1, 1, 1)
	minimizedBtn.Font = self.Theme.Font
	minimizedBtn.TextSize = 18
	minimizedBtn.ZIndex = 11
	apply_rounding(minimizedBtn)
	minimizedBtn.Parent = main

	local restoreBtn = Instance.new("TextButton")
	restoreBtn.Size = UDim2.new(0, 50, 0, 50)
	restoreBtn.Position = UDim2.new(0.5, -25, 0.5, -25)
	restoreBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	restoreBtn.Text = "+"
	restoreBtn.TextColor3 = Color3.new(1, 1, 1)
	restoreBtn.Font = self.Theme.Font
	restoreBtn.TextSize = 30
	apply_rounding(restoreBtn)
	restoreBtn.Parent = main
	restoreBtn.Visible = false
	restoreBtn.ZIndex = 12

	restoreBtn.MouseButton1Click:Connect(function()
		main.Visible = true
		restoreBtn.Visible = false
		log("UI восстановлен")
	end)

	minimizedBtn.MouseButton1Click:Connect(function()
		main.Visible = false
		restoreBtn.Visible = true
		log("UI свернут")
	end)

	local close = Instance.new("TextButton")
	close.Size = UDim2.new(0, 30, 0, 30)
	close.Position = UDim2.new(1, -35, 0, 5)
	close.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
	close.Text = "X"
	close.TextColor3 = Color3.new(1, 1, 1)
	close.Font = self.Theme.Font
	close.TextSize = 18
	close.ZIndex = 11
	apply_rounding(close)
	close.Parent = main
	close.MouseButton1Click:Connect(function()
		log("UI закрыт")
		self.ScreenGui:Destroy()
	end)

	local tabContainer = Instance.new("Frame")
	tabContainer.Name = "Tabs"
	tabContainer.Position = UDim2.new(0, 0, 0, 40)
	tabContainer.Size = UDim2.new(0, 100, 1, -40)
	tabContainer.BackgroundTransparency = 1
	tabContainer.ZIndex = 11
	tabContainer.Parent = main

	local contentHolder = Instance.new("Frame")
	contentHolder.Name = "Content"
	contentHolder.Position = UDim2.new(0, 100, 0, 40)
	contentHolder.Size = UDim2.new(1, -100, 1, -40)
	contentHolder.BackgroundTransparency = 1
	contentHolder.ZIndex = 9
	contentHolder.Parent = main

	self.MainFrame = main
	self.Tabs = tabContainer
	self.Content = contentHolder

	self._categories = {} -- храним кнопки для управления выделением

	log("Окно создано")
	return self
end

function gui_framework:AddCategory(name)
	log("Добавление категории: " .. tostring(name))
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 30)
	button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	button.Text = name
	button.Font = self.Theme.Font
	button.TextColor3 = self.Theme.TextColor
	button.TextSize = 16
	apply_rounding(button)
	button.ZIndex = 11
	button.Parent = self.Tabs

	local content = Instance.new("Frame")
	content.Visible = false
	content.Size = UDim2.new(1, 0, 1, 0)
	content.BackgroundTransparency = 1
	content.Name = name .. "_Content"
	content.ZIndex = 9
	content.Parent = self.Content

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 5)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = content

	button.MouseButton1Click:Connect(function()
		-- Скрыть все контенты
		for _, tab in ipairs(self.Content:GetChildren()) do
			if tab:IsA("Frame") then
				tab.Visible = false
			end
		end
		content.Visible = true

		-- Сбросить цвет у всех кнопок и выделить активную
		for _, btn in ipairs(self.Tabs:GetChildren()) do
			if btn:IsA("TextButton") then
				btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			end
		end
		button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	end)

	-- Авто-выделение первого добавленного таба
	if #self._categories == 0 then
		button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		content.Visible = true
	end

	table.insert(self._categories, button)
	log("Категория " .. name .. " добавлена")
	return content
end

function gui_framework:CreateButton(parent, text, callback)
	log("Создание кнопки: " .. tostring(text))
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -10, 0, 30)
	btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	btn.Text = text
	btn.Font = self.Theme.Font
	btn.TextColor3 = self.Theme.TextColor
	btn.TextSize = 14
	apply_rounding(btn)
	btn.ZIndex = 9
	btn.Parent = parent
	btn.LayoutOrder = 0
	btn.MouseButton1Click:Connect(function()
		log("Нажата кнопка: " .. text)
		local ok, err = pcall(callback or function() end)
		if not ok then warn("Ошибка в кнопке: " .. tostring(err)) end
	end)
end

function gui_framework:CreateToggle(parent, text, default, callback)
	log("Создание переключателя: " .. tostring(text))
	local toggle = Instance.new("TextButton")
	toggle.Size = UDim2.new(1, -10, 0, 30)
	toggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	toggle.Text = text .. (default and " [ON]" or " [OFF]")
	toggle.Font = self.Theme.Font
	toggle.TextColor3 = self.Theme.TextColor
	toggle.TextSize = 14
	apply_rounding(toggle)
	toggle.ZIndex = 9
	toggle.Parent = parent
	toggle.LayoutOrder = 0

	local state = default or false
	toggle.MouseButton1Click:Connect(function()
		state = not state
		toggle.Text = text .. (state and " [ON]" or " [OFF]")
		log("Тоггл: " .. text .. " -> " .. tostring(state))
		pcall(function() if callback then callback(state) end end)
	end)
end

function gui_framework:CreateSlider(parent, min, max, callback)
	log("Создание слайдера: " .. min .. "-" .. max)
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, -10, 0, 30)
	box.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	box.Text = tostring(min)
	box.ClearTextOnFocus = false
	box.Font = self.Theme.Font
	box.TextColor3 = self.Theme.TextColor
	box.TextSize = 14
	apply_rounding(box)
	box.ZIndex = 9
	box.Parent = parent
	box.LayoutOrder = 0

	box.FocusLost:Connect(function()
		local val = tonumber(box.Text)
		if val and val >= min and val <= max then
			log("Слайдер установлен: " .. val)
			pcall(function() if callback then callback(val) end end)
		else
			warn("Слайдер вне диапазона, сброс к " .. min)
			box.Text = tostring(min)
		end
	end)
end

function gui_framework:CreateDropdown(parent, list, callback)
	log("Создание дропдауна (UI не реализован)")
	local dropdown = Instance.new("TextButton")
	dropdown.Size = UDim2.new(1, -10, 0, 30)
	dropdown.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	dropdown.Text = "Select..."
	dropdown.Font = self.Theme.Font
	dropdown.TextColor3 = self.Theme.TextColor
	dropdown.TextSize = 14
	apply_rounding(dropdown)
	dropdown.ZIndex = 9
	dropdown.Parent = parent
	dropdown.LayoutOrder = 0

	dropdown.MouseButton1Click:Connect(function()
		log("Дропдаун нажат")
		if callback then pcall(callback) end
	end)
end

function gui_framework:CreatePlayerDropdown(parent, callback)
	log("Список игроков")
	local players = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then table.insert(players, p.Name) end
	end
	self:CreateDropdown(parent, players, callback)
end

function gui_framework:CheckGameId(allowedId)
	if type(allowedId) ~= "number" then
		warn("[UI_LOG]: CheckGameId > Неверный тип gameId")
		return false
	end
	if game.GameId ~= allowedId then
		warn("[UI_LOG]: Игра не совпадает. Ожидался GameId " .. allowedId .. ", но получен " .. game.GameId)
		if self.ScreenGui then
			self.ScreenGui:Destroy()
		end
		return false
	end
	log("GameId совпадает: " .. allowedId)
	return true
end

log("UI Framework загружен")
return gui_framework
