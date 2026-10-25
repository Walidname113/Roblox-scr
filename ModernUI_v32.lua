local module = {}

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local ContentProvider  = game:GetService("ContentProvider")

local env = (type(getgenv) == "function" and getgenv()) or shared

local Theme = {
    Background  = Color3.fromRGB(15, 15, 18),
    SecondaryBg = Color3.fromRGB(22, 22, 26),
    AccentGlow  = Color3.fromRGB(168, 85, 247),
    TextMain    = Color3.fromRGB(243, 244, 246),
    TextMuted   = Color3.fromRGB(156, 163, 175),
    Border      = Color3.fromRGB(39, 39, 42),
    Success     = Color3.fromRGB(34, 197, 94),
    Danger      = Color3.fromRGB(239, 68, 68),
    Warning     = Color3.fromRGB(234, 179, 8),
    FontMain    = Enum.Font.Gotham,
    FontBold    = Enum.Font.GothamBold,
}

module.Version = "v32"
module.Theme = Theme

local Builders = {}
local Window = {}
Window.__index = Window
local Category = {}
Category.__index = Category

local orders = setmetatable({}, { __mode = "k" })

local function nextOrder(p)
    local n = (orders[p] or 0) + 1
    orders[p] = n
    return n
end

local function isPress(inp)
    return inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch
end

local function tween(obj, t, props, style, dir)
    local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

local function make(class, props, parent)
    local o = Instance.new(class)
    if o:IsA("GuiObject") then
        o.BorderSizePixel = 0
        o.BackgroundTransparency = (props.BackgroundColor3 and props.BackgroundTransparency == nil) and 0 or 1
        if o:IsA("GuiButton") then o.AutoButtonColor = false end
    end
    if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
        o.Text = ""
        o.Font = Theme.FontMain
        o.TextSize = 13
        o.TextColor3 = Theme.TextMain
    end
    for k, v in pairs(props) do o[k] = v end
    o.Parent = parent
    return o
end

local function corner(o, r)
    return make("UICorner", { CornerRadius = UDim.new(0, r) }, o)
end

local function stroke(o, color, thickness)
    return make("UIStroke", {
        Color = color or Theme.Border,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, o)
end

local function pad(o, l, t, r, b)
    return make("UIPadding", {
        PaddingLeft = UDim.new(0, l), PaddingTop = UDim.new(0, t),
        PaddingRight = UDim.new(0, r), PaddingBottom = UDim.new(0, b),
    }, o)
end

local function release(item)
    local t = typeof(item)
    if t == "RBXScriptConnection" then
        item:Disconnect()
    elseif t == "Instance" then
        item:Destroy()
    elseif t == "function" then
        item()
    elseif t == "thread" then
        if item ~= coroutine.running() then task.cancel(item) end
    elseif t == "table" then
        if type(item.Stop) == "function" then
            item:Stop()
        elseif type(item.Destroy) == "function" then
            item:Destroy()
        end
    end
end

local function fire(win, cb, ...)
    if not cb or not win.Alive then return end
    local ok, err = pcall(cb, ...)
    if not ok then warn("[ModernUI] callback: " .. tostring(err)) end
end

local function guarded(label, fn)
    task.spawn(function()
        local ok, err = pcall(fn)
        if not ok then warn("[ModernUI] " .. label .. ": " .. tostring(err)) end
    end)
end

local function trackInput(inp, onMove)
    local touch = inp.UserInputType == Enum.UserInputType.Touch
    local moveC, endC
    local function stop()
        if moveC then moveC:Disconnect(); moveC = nil end
        if endC then endC:Disconnect(); endC = nil end
    end
    moveC = UserInputService.InputChanged:Connect(function(i)
        if touch then
            if i ~= inp then return end
        elseif i.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end
        if inp.UserInputState == Enum.UserInputState.End then
            stop()
            return
        end
        onMove(i.Position)
    end)
    endC = UserInputService.InputEnded:Connect(function(i)
        if touch then
            if i == inp then stop() end
        elseif i.UserInputType == Enum.UserInputType.MouseButton1 then
            stop()
        end
    end)
    return stop
end

local function onTap(gui, fn, maxTime)
    local pressInp, startPos, startT
    gui.InputBegan:Connect(function(inp)
        if isPress(inp) then
            pressInp, startPos, startT = inp, inp.Position, os.clock()
        end
    end)
    gui.InputEnded:Connect(function(inp)
        if not startPos or not isPress(inp) then return end
        if inp.UserInputType == Enum.UserInputType.Touch and inp ~= pressInp then return end
        local moved = (inp.Position - startPos).Magnitude
        local held = os.clock() - startT
        startPos = nil
        if moved < 8 and (not maxTime or held <= maxTime) then fn() end
    end)
end

local function makeDraggable(frame, handle)
    local activeStop
    handle.InputBegan:Connect(function(inp)
        if not isPress(inp) then return end
        if activeStop then activeStop() end
        local start, origin = inp.Position, frame.Position
        local moved = false
        activeStop = trackInput(inp, function(pos)
            local d = pos - start
            if not moved then
                if d.Magnitude < 4 then return end
                moved = true
            end
            frame.Position = UDim2.new(origin.X.Scale, origin.X.Offset + d.X, origin.Y.Scale, origin.Y.Offset + d.Y)
        end)
    end)
    return function()
        if activeStop then activeStop(); activeStop = nil end
    end
end

function Window:Track(item)
    if not self.Alive then
        pcall(release, item)
        return item
    end
    self._items[#self._items + 1] = item
    return item
end

function Window:Connect(signal, fn)
    if not self.Alive then return nil end
    local c = signal:Connect(function(...)
        if self.Alive then fn(...) end
    end)
    self._items[#self._items + 1] = c
    return c
end

function Window:Spawn(fn, ...)
    if not self.Alive then return nil end
    local win = self
    local args = table.pack(...)
    local handle = {}
    local co = coroutine.create(function()
        local ok, err = pcall(fn, table.unpack(args, 1, args.n))
        if not ok then warn("[ModernUI] thread: " .. tostring(err)) end
        win._threads[handle] = nil
    end)
    handle.Thread = co
    function handle:Stop()
        if handle.Stopped then return end
        handle.Stopped = true
        win._threads[handle] = nil
        if co == coroutine.running() then
            task.defer(function() pcall(task.cancel, co) end)
        elseif coroutine.status(co) ~= "dead" then
            pcall(task.cancel, co)
        end
    end
    self._threads[handle] = true
    task.spawn(co)
    return handle
end

function Window:Delay(t, fn, ...)
    local args = table.pack(...)
    return self:Spawn(function()
        task.wait(t)
        if self.Alive then fn(table.unpack(args, 1, args.n)) end
    end)
end

function Window:Loop(interval, fn)
    if type(interval) == "function" then
        fn = interval
        interval = 0
    end
    interval = interval or 0
    return self:Spawn(function()
        local last = os.clock()
        while self.Alive do
            local now = os.clock()
            local ok, err = pcall(fn, now - last)
            last = now
            if not ok then warn("[ModernUI] loop: " .. tostring(err)) end
            if interval > 0 then task.wait(interval) else RunService.Heartbeat:Wait() end
        end
    end)
end

function Window:OnClose(fn)
    if not self.Alive then
        guarded("onclose", fn)
        return
    end
    self._hooks[#self._hooks + 1] = fn
end

function Window:IsAlive()
    return self.Alive
end

function Window:_addReset(w, fn)
    self._resets[#self._resets + 1] = { w = w, fn = fn }
end

function Window:_dropResets(w, run)
    for i = #self._resets, 1, -1 do
        local e = self._resets[i]
        if e.w == w then
            table.remove(self._resets, i)
            if run then guarded("reset", e.fn) end
        end
    end
end

function Window:_closePopup()
    local c = self._popupClose
    if c then
        self._popupClose = nil
        c(false)
    end
end

function Window:_fullSize()
    return UDim2.fromOffset(self._size.X, self.Compact and math.min(200, self._size.Y) or self._size.Y)
end

local function resolveTitle(title)
    title = tostring(title or "Modern Suite")

    local placeName

    if title:find("{gamename}", 1, true) then
        local success, info = pcall(function()
            local MarketplaceService =
                game:GetService("MarketplaceService")

            return MarketplaceService:GetProductInfoAsync(
                game.PlaceId,
                Enum.InfoType.Asset
            )
        end)

        if success
            and type(info) == "table"
            and type(info.Name) == "string"
            and info.Name ~= ""
        then
            placeName = info.Name
        else
            placeName = "Unknown Place"
        end

        title = title:gsub("{gamename}", function()
            return placeName
        end)
    end

    title = title:gsub("{placeid}", function()
        return tostring(game.PlaceId)
    end)

    title = title:gsub("{gameid}", function()
        return tostring(game.GameId)
    end)

    return title
end

function Window:SetTitle(text)
    self._title.Text = string.upper(resolveTitle(text))
end

function Window:SetCompact(v)
    self.Compact = v and true or false
    if self.Alive and not self.Hidden then
        tween(self._main, 0.3, { Size = self:_fullSize() })
    end
end

function Window:Hide()
    if not self.Alive or self.Hidden then return end
    self.Hidden = true
    self:_closePopup()
    local main, minF = self._main, self._minF
    tween(main, 0.2, { Size = UDim2.fromOffset(0, 0), GroupTransparency = 1 }).Completed:Once(function()
        if not self.Alive or not self.Hidden then return end
        main.Visible = false
        minF.Size = UDim2.fromOffset(0, 0)
        minF.Visible = true
        tween(minF, 0.25, { Size = UDim2.fromOffset(48, 48) }, Enum.EasingStyle.Back)
    end)
end

function Window:Show()
    if not self.Alive or not self.Hidden then return end
    self.Hidden = false
    local main, minF = self._main, self._minF
    tween(minF, 0.15, { Size = UDim2.fromOffset(0, 0) }).Completed:Once(function()
        if not self.Alive or self.Hidden then return end
        minF.Visible = false
        main.Visible = true
        tween(main, 0.25, { Size = self:_fullSize(), GroupTransparency = 0 }, Enum.EasingStyle.Back)
    end)
end

function Window:IsHidden()
    return self.Hidden
end

function Window:SetMinimizedImage(assetId)
    local minF, plus = self._minF, self._plus
    if self._imgLoad then self._imgLoad:Stop(); self._imgLoad = nil end
    self._imgToken = (self._imgToken or 0) + 1
    local mine = self._imgToken

    local function load(img)
        minF.Image = img
        plus.Visible = true
        local function done()
            if self.Alive and self._imgToken == mine then plus.Visible = false end
        end
        self._imgLoad = self:Spawn(function()
            pcall(function()
                ContentProvider:PreloadAsync({ minF }, function(_, status)
                    if status == Enum.AssetFetchStatus.Success then done() end
                end)
            end)
            for _ = 1, 300 do
                if self._imgToken ~= mine or not plus.Visible then return end
                if minF.IsLoaded then done(); return end
                task.wait(0.1)
            end
        end)
    end

    if assetId and assetId ~= "" then
        local s = tostring(assetId)
        load(s:find("^rbx") and s or ("rbxassetid://" .. s))
    elseif game.PlaceId ~= 0 then
        load("rbxthumb://type=Asset&id=" .. game.PlaceId .. "&w=150&h=150")
    end
end

function Window:RequestClose()
    if not self.Alive then return end
    if self._confirmClose then
        self:_closePopup()
        self._setConfirm(true)
    else
        self:Kill()
    end
end

function Window:Kill()
    if not self.Alive then return end
    self.Alive = false
    if env.__ModernUIActive == self then env.__ModernUIActive = nil end

    self:_closePopup()

    local resets = self._resets
    self._resets = {}
    for i = #resets, 1, -1 do guarded("reset", resets[i].fn) end

    local hooks = self._hooks
    self._hooks = {}
    for i = #hooks, 1, -1 do guarded("onclose", hooks[i]) end

    for h in pairs(self._threads) do h:Stop() end

    local items = self._items
    self._items = {}
    for i = #items, 1, -1 do pcall(release, items[i]) end

    local gui, main = self._gui, self._main
    if gui and gui.Parent then
        self._popups.Visible = false
        self._minF.Visible = false
        main.Interactable = false
        tween(main, 0.15, { GroupTransparency = 1 })
        task.delay(0.2, function() gui:Destroy() end)
    end
end

Window.Destroy = Window.Kill

local function baseWidget(win, frame)
    local w = { Frame = frame, _cleanups = {} }
    function w:Destroy()
        if self._destroyed then return end
        self._destroyed = true
        for i = #self._cleanups, 1, -1 do pcall(self._cleanups[i]) end
        win:_dropResets(self, win.Alive)
        if frame.Parent then frame:Destroy() end
    end
    function w:SetVisible(v)
        frame.Visible = v and true or false
    end
    return w
end

local function build(win, parent, typeName, cfg)
    local fn = Builders[typeName]
    if not fn then error("ModernUI: unknown widget type " .. tostring(typeName), 3) end
    if type(cfg) == "string" then cfg = { Text = cfg } end
    return fn(win, parent, cfg or {})
end

local function newCard(parent, height)
    local card = make("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Background,
        LayoutOrder = nextOrder(parent),
    }, parent)
    corner(card, 8)
    stroke(card, Theme.Border)
    make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, card)
    pad(card, 0, 0, 0, 0)
    local top = make("Frame", { Size = UDim2.new(1, 0, 0, height), LayoutOrder = 1 }, card)
    return card, top
end

local function extend(win, w, card, cfg, wrap)
    local padding = card:FindFirstChildOfClass("UIPadding")
    local hasDesc = type(cfg.Description) == "string" and cfg.Description ~= ""
    local sub
    if type(cfg.Sub) == "table" and #cfg.Sub > 0 then
        sub = make("Frame", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2,
        }, card)
        sub:SetAttribute("Bg", Theme.Background)
        make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }, sub)
        pad(sub, 12, 0, 12, 0)
        local subs = {}
        w.Subs = subs
        for _, item in ipairs(cfg.Sub) do
            local c = {}
            for k, v in pairs(item) do c[k] = v end
            if wrap and c.Callback then c.Callback = wrap(c.Callback) end
            subs[#subs + 1] = build(win, sub, c.Type, c)
        end
        w._cleanups[#w._cleanups + 1] = function()
            for i = #subs, 1, -1 do subs[i]:Destroy() end
        end
    end
    if hasDesc then
        local st = cfg.DescStyle or {}
        local holder = make("Frame", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 3,
        }, card)
        pad(holder, 14, 4, 14, 0)
        make("TextLabel", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = cfg.Description,
            TextColor3 = st.Color or Theme.TextMuted, TextTransparency = st.Transparency or 0,
            Font = st.Font or Theme.FontMain, TextSize = st.TextSize or 11, TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, holder)
    end
    local function refresh()
        local extra = hasDesc or (sub ~= nil and sub.Visible)
        padding.PaddingBottom = UDim.new(0, extra and 10 or 0)
    end
    refresh()
    return sub, refresh
end

local function rowLabel(top, text, size)
    return make("TextLabel", {
        Size = size or UDim2.new(1, -70, 1, 0), Position = UDim2.fromOffset(14, 0), Text = text,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
    }, top)
end

local function makeSwitch(parent, pos)
    local track = make("Frame", {
        Size = UDim2.fromOffset(42, 22), AnchorPoint = Vector2.new(1, 0.5),
        Position = pos, BackgroundColor3 = Theme.SecondaryBg,
    }, parent)
    corner(track, 11)
    stroke(track, Theme.Border)
    local knob = make("Frame", {
        Size = UDim2.fromOffset(16, 16), AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 3, 0.5, 0), BackgroundColor3 = Theme.TextMuted,
    }, track)
    corner(knob, 8)
    local sw = { Frame = track }
    function sw.Set(on, animate)
        local a = { BackgroundColor3 = on and Theme.AccentGlow or Theme.SecondaryBg }
        local b = {
            Position = UDim2.new(0, on and 23 or 3, 0.5, 0),
            BackgroundColor3 = on and Theme.TextMain or Theme.TextMuted,
        }
        if animate then
            tween(track, 0.2, a)
            tween(knob, 0.25, b, Enum.EasingStyle.Back)
        else
            for k, v in pairs(a) do track[k] = v end
            for k, v in pairs(b) do knob[k] = v end
        end
    end
    return sw
end

local function makeCheckbox(parent, pos)
    local box = make("Frame", {
        Size = UDim2.fromOffset(22, 22), AnchorPoint = Vector2.new(1, 0.5),
        Position = pos, BackgroundColor3 = Theme.SecondaryBg,
    }, parent)
    corner(box, 5)
    stroke(box, Theme.Border)
    local mark = make("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0), Text = "✓", Font = Theme.FontBold, Visible = false,
    }, box)
    local cb = { Frame = box }
    function cb.Set(on)
        box.BackgroundColor3 = on and Theme.AccentGlow or Theme.SecondaryBg
        mark.Visible = on
    end
    return cb
end

local function makeSelectorButton(top, rightReserve)
    local btn = make("TextButton", {
        Size = UDim2.new(1, -(24 + rightReserve), 0, 30), Position = UDim2.new(0, 12, 0.5, -15),
        BackgroundColor3 = Theme.SecondaryBg,
    }, top)
    corner(btn, 6)
    stroke(btn, Theme.Border)
    local txt = make("TextLabel", {
        Size = UDim2.new(1, -34, 1, 0), Position = UDim2.fromOffset(10, 0),
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
    }, btn)
    make("TextLabel", {
        Size = UDim2.fromOffset(20, 30), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -4, 0, 0),
        Text = "▼", TextSize = 11, TextColor3 = Theme.TextMuted,
    }, btn)
    return btn, txt
end

local function openDropdown(win, anchor, labels, isOn, onPick, keepOpen)
    win:_closePopup()
    local layer = win._popups
    local dim = make("TextButton", { Size = UDim2.new(1, 0, 1, 0), ZIndex = 1 }, layer)
    local ROW = 30
    local count = #labels
    local h = math.min(count, 5) * ROW
    local ap, as, vp = anchor.AbsolutePosition, anchor.AbsoluteSize, layer.AbsoluteSize
    local y = ap.Y + as.Y + 4
    if y + h > vp.Y then y = math.max(ap.Y - h - 4, 0) end
    local list = make("ScrollingFrame", {
        Size = UDim2.fromOffset(as.X, h), Position = UDim2.fromOffset(ap.X, y),
        BackgroundColor3 = Theme.SecondaryBg, ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.AccentGlow,
        CanvasSize = UDim2.new(0, 0, 0, count * ROW), ZIndex = 2,
    }, layer)
    corner(list, 6)
    stroke(list, Theme.AccentGlow)
    make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, list)

    local closed = false
    local function close()
        if closed then return end
        closed = true
        if win._popupClose == close then win._popupClose = nil end
        dim:Destroy()
        list:Destroy()
    end
    win._popupClose = close

    local buttons = {}
    local function paint()
        for i, b in ipairs(buttons) do
            b.TextColor3 = isOn(i) and Theme.AccentGlow or Theme.TextMuted
        end
    end
    for i, text in ipairs(labels) do
        local b = make("TextButton", {
            Size = UDim2.new(1, 0, 0, ROW), LayoutOrder = i, Text = text, TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        }, list)
        pad(b, 10, 0, 10, 0)
        buttons[i] = b
        b.MouseEnter:Connect(function() b.TextColor3 = Theme.TextMain end)
        b.MouseLeave:Connect(function() b.TextColor3 = isOn(i) and Theme.AccentGlow or Theme.TextMuted end)
        onTap(b, function()
            if keepOpen then
                onPick(i)
                paint()
            else
                close()
                onPick(i)
            end
        end)
    end
    paint()
    dim.Activated:Connect(close)
end

local function openColorPicker(win, default, onApply)
    win:_closePopup()
    local layer = win._popups
    local conns = {}
    local function bind(c) conns[#conns + 1] = c; return c end

    local dim = make("TextButton", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.55, ZIndex = 1,
    }, layer)
    local pf = make("CanvasGroup", {
        Size = UDim2.fromOffset(320, 320), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = Color3.fromRGB(24, 24, 28),
        GroupTransparency = 1, Active = true, ZIndex = 2,
    }, layer)
    corner(pf, 12)
    stroke(pf, Theme.Border)
    local sc = make("UIScale", { Scale = 0.92 }, pf)

    local handle = make("Frame", { Size = UDim2.new(1, 0, 0, 40), Active = true }, pf)
    make("TextLabel", {
        Size = UDim2.new(1, -50, 1, 0), Position = UDim2.fromOffset(16, 0),
        Text = "Color Palette", Font = Theme.FontBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left,
    }, handle)
    local xb = make("TextButton", {
        Size = UDim2.fromOffset(24, 24), Position = UDim2.new(1, -36, 0, 8),
        Text = "×", Font = Theme.FontBold, TextSize = 18, TextColor3 = Theme.TextMuted,
    }, pf)
    bind(makeDraggable(pf, handle))

    local preview = make("Frame", {
        Size = UDim2.fromOffset(110, 120), Position = UDim2.fromOffset(16, 46), BackgroundColor3 = default,
    }, pf)
    corner(preview, 6)
    local rsv = make("ImageLabel", {
        Size = UDim2.fromOffset(168, 120), Position = UDim2.fromOffset(136, 46),
        Image = "rbxassetid://4155801252", BackgroundColor3 = Color3.new(1, 0, 0), Active = true,
    }, pf)
    corner(rsv, 6)
    local cursor = make("Frame", { Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0.5, 0.5) }, rsv)
    corner(cursor, 7)
    make("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2 }, cursor)

    local hs = make("Frame", {
        Size = UDim2.fromOffset(288, 16), Position = UDim2.fromOffset(16, 180),
        BackgroundColor3 = Color3.new(1, 1, 1), Active = true,
    }, pf)
    corner(hs, 8)
    make("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0 / 6, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(1 / 6, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(2 / 6, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(3 / 6, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(4 / 6, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(5 / 6, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(6 / 6, Color3.fromRGB(255, 0, 0)),
        }),
    }, hs)
    local hk = make("Frame", {
        Size = UDim2.fromOffset(18, 18), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = Color3.new(1, 1, 1),
    }, hs)
    corner(hk, 9)
    make("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1.5 }, hk)

    local rc = make("Frame", {
        Size = UDim2.fromOffset(288, 40), Position = UDim2.fromOffset(16, 210), BackgroundColor3 = Theme.SecondaryBg,
    }, pf)
    corner(rc, 8)
    stroke(rc, Theme.Border)
    make("TextLabel", {
        Size = UDim2.fromOffset(45, 40), Position = UDim2.fromOffset(12, 0), Text = "RGB",
        Font = Theme.FontBold, TextSize = 12, TextColor3 = Theme.TextMuted, TextXAlignment = Enum.TextXAlignment.Left,
    }, rc)
    local ri = make("TextBox", {
        Size = UDim2.new(1, -65, 1, 0), Position = UDim2.fromOffset(55, 0),
        TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
    }, rc)

    local ab = make("TextButton", {
        Size = UDim2.fromOffset(136, 36), Position = UDim2.fromOffset(16, 268), Text = "Apply",
        Font = Theme.FontBold, BackgroundColor3 = Theme.Success,
    }, pf)
    corner(ab, 6)
    local cb = make("TextButton", {
        Size = UDim2.fromOffset(136, 36), Position = UDim2.fromOffset(168, 268), Text = "Cancel",
        Font = Theme.FontBold, TextColor3 = Theme.TextMuted, BackgroundColor3 = Theme.SecondaryBg,
    }, pf)
    corner(cb, 6)
    stroke(cb, Theme.Border)

    local cH, cS, cV = default:ToHSV()
    local function upd()
        rsv.BackgroundColor3 = Color3.fromHSV(cH, 1, 1)
        local fc = Color3.fromHSV(cH, cS, cV)
        preview.BackgroundColor3 = fc
        hk.Position = UDim2.new(cH, 0, 0.5, 0)
        cursor.Position = UDim2.new(cS, 0, 1 - cV, 0)
        if not ri:IsFocused() then
            ri.Text = string.format("%d, %d, %d", math.round(fc.R * 255), math.round(fc.G * 255), math.round(fc.B * 255))
        end
    end

    bind(ri.FocusLost:Connect(function()
        local r, g, b = ri.Text:match("(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
        if r then
            local c = Color3.fromRGB(math.clamp(tonumber(r), 0, 255), math.clamp(tonumber(g), 0, 255), math.clamp(tonumber(b), 0, 255))
            cH, cS, cV = c:ToHSV()
        end
        upd()
    end))

    local mode, stopTrack
    local function applyPos(pos)
        if mode == "h" then
            cH = math.clamp((pos.X - hs.AbsolutePosition.X) / hs.AbsoluteSize.X, 0, 1)
        elseif mode == "sv" then
            cS = math.clamp((pos.X - rsv.AbsolutePosition.X) / rsv.AbsoluteSize.X, 0, 1)
            cV = 1 - math.clamp((pos.Y - rsv.AbsolutePosition.Y) / rsv.AbsoluteSize.Y, 0, 1)
        end
        upd()
    end
    local function startTrack(inp, m)
        if stopTrack then stopTrack() end
        mode = m
        applyPos(inp.Position)
        stopTrack = trackInput(inp, applyPos)
    end
    bind(hs.InputBegan:Connect(function(inp)
        if isPress(inp) then startTrack(inp, "h") end
    end))
    bind(rsv.InputBegan:Connect(function(inp)
        if isPress(inp) then startTrack(inp, "sv") end
    end))
    bind(function()
        if stopTrack then stopTrack(); stopTrack = nil end
    end)

    local closed = false
    local function close(save)
        if closed then return end
        closed = true
        if win._popupClose == close then win._popupClose = nil end
        for _, c in ipairs(conns) do pcall(release, c) end
        if save then onApply(Color3.fromHSV(cH, cS, cV)) end
        tween(pf, 0.12, { GroupTransparency = 1 })
        tween(sc, 0.12, { Scale = 0.92 })
        dim:Destroy()
        task.delay(0.14, function() pf:Destroy() end)
    end
    win._popupClose = close

    bind(ab.Activated:Connect(function() close(true) end))
    bind(cb.Activated:Connect(function() close(false) end))
    bind(xb.Activated:Connect(function() close(false) end))
    bind(dim.Activated:Connect(function() close(false) end))

    upd()
    tween(pf, 0.2, { GroupTransparency = 0 })
    tween(sc, 0.2, { Scale = 1 }, Enum.EasingStyle.Back)
end

Builders.Toggle = function(win, parent, cfg)
    local card, top = newCard(parent, 42)
    rowLabel(top, cfg.Text or "Toggle")
    local sw = makeSwitch(top, UDim2.new(1, -12, 0.5, 0))
    local hit = make("TextButton", { Size = UDim2.new(1, 0, 1, 0) }, top)
    local w = baseWidget(win, card)
    local state = cfg.Default == true
    sw.Set(state, false)

    function w:Get() return state end
    function w:Set(v, silent)
        v = v and true or false
        if v == state then return end
        state = v
        sw.Set(v, true)
        if not silent then fire(win, cfg.Callback, state) end
    end
    function w:Toggle() w:Set(not state) end
    onTap(hit, function() w:Set(not state) end)

    if cfg.ResetOnKill ~= false then
        win:_addReset(w, function()
            if state then
                state = false
                if cfg.Callback then cfg.Callback(false) end
            end
        end)
    end
    extend(win, w, card, cfg)
    if state then fire(win, cfg.Callback, true) end
    return w
end

Builders.Checkbox = function(win, parent, cfg)
    local card, top = newCard(parent, 36)
    rowLabel(top, cfg.Text or "Option")
    local cb = makeCheckbox(top, UDim2.new(1, -12, 0.5, 0))
    local hit = make("TextButton", { Size = UDim2.new(1, 0, 1, 0) }, top)
    local w = baseWidget(win, card)
    local state = cfg.Default == true
    cb.Set(state)

    function w:Get() return state end
    function w:Set(v, silent)
        v = v and true or false
        if v == state then return end
        state = v
        cb.Set(v)
        if not silent then fire(win, cfg.Callback, state) end
    end
    onTap(hit, function() w:Set(not state) end)

    if cfg.ResetOnKill ~= false then
        win:_addReset(w, function()
            if state then
                state = false
                if cfg.Callback then cfg.Callback(false) end
            end
        end)
    end
    extend(win, w, card, cfg)
    if state then fire(win, cfg.Callback, true) end
    return w
end

Builders.Button = function(win, parent, cfg)
    local card, top = newCard(parent, 40)
    local st = card:FindFirstChildOfClass("UIStroke")
    local btn = make("TextButton", {
        Size = UDim2.new(1, 0, 0, 40), Text = cfg.Text or "Button", Font = Theme.FontBold,
    }, top)
    btn.MouseEnter:Connect(function()
        tween(card, 0.2, { BackgroundColor3 = Color3.fromRGB(30, 30, 37) })
        tween(st, 0.2, { Color = Theme.AccentGlow })
    end)
    btn.MouseLeave:Connect(function()
        tween(card, 0.2, { BackgroundColor3 = Theme.Background })
        tween(st, 0.2, { Color = Theme.Border })
    end)
    local w = baseWidget(win, card)
    local function press()
        tween(btn, 0.08, { Size = UDim2.new(1, 0, 0, 36) }).Completed:Once(function()
            tween(btn, 0.12, { Size = UDim2.new(1, 0, 0, 40) }, Enum.EasingStyle.Back)
        end)
        fire(win, cfg.Callback)
    end
    onTap(btn, press)
    function w:SetText(t) btn.Text = tostring(t) end
    function w:GetText() return btn.Text end
    function w:Fire() press() end
    extend(win, w, card, cfg)
    return w
end

Builders.Label = function(win, parent, cfg)
    local f = make("Frame", {
        Size = UDim2.new(1, 0, 0, cfg.Height or 28), AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = nextOrder(parent),
    }, parent)
    pad(f, 14, 4, 14, 4)
    local l = make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = cfg.Text or "",
        TextColor3 = cfg.Color or Theme.TextMuted, Font = cfg.Bold and Theme.FontBold or Theme.FontMain,
        TextSize = cfg.TextSize or 12, TextXAlignment = cfg.Align or Enum.TextXAlignment.Left,
        TextWrapped = true,
    }, f)
    local w = baseWidget(win, f)
    function w:SetText(t) l.Text = tostring(t) end
    function w:GetText() return l.Text end
    function w:SetColor(c) l.TextColor3 = c end
    return w
end

Builders.Separator = function(win, parent, cfg)
    local h = cfg.Height or 1
    local vp = cfg.Padding or 6
    local f = make("Frame", {
        Size = UDim2.new(1, 0, 0, h + vp * 2), LayoutOrder = nextOrder(parent),
    }, parent)
    local line = make("Frame", {
        Size = UDim2.new(1, -28, 0, h), Position = UDim2.new(0, 14, 0.5, -math.floor(h / 2)),
        BackgroundColor3 = cfg.Color or Theme.Border,
    }, f)
    if cfg.Label and cfg.Label ~= "" then
        make("TextLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 0, 0, 16), AutomaticSize = Enum.AutomaticSize.X,
            Text = " " .. cfg.Label .. " ", TextColor3 = cfg.LabelColor or Theme.TextMuted,
            TextSize = cfg.LabelSize or 11, BackgroundColor3 = parent:GetAttribute("Bg") or Theme.SecondaryBg,
        }, f)
    end
    local w = baseWidget(win, f)
    function w:SetColor(c) line.BackgroundColor3 = c end
    return w
end

Builders.Slider = function(win, parent, cfg)
    local card, top = newCard(parent, 54)
    local opts = cfg.Options
    if opts and #opts == 0 then opts = nil end
    local minV, maxV, step = cfg.Min or 0, cfg.Max or 100, cfg.Step or 1
    local decimals = #(tostring(step):match("%.(%d+)") or "")
    local suffix = cfg.Suffix or ""

    local lbl = rowLabel(top, cfg.Text or "Slider", UDim2.new(1, -100, 0, 20))
    lbl.Position = UDim2.fromOffset(14, 8)
    local valLbl = make("TextLabel", {
        Size = UDim2.fromOffset(80, 20), Position = UDim2.new(1, -94, 0, 8), Font = Theme.FontBold,
        TextColor3 = Theme.TextMuted, TextXAlignment = Enum.TextXAlignment.Right,
    }, top)
    local hit = make("Frame", { Size = UDim2.new(1, -28, 0, 22), Position = UDim2.fromOffset(14, 28), Active = true }, top)
    local bar = make("Frame", {
        Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0.5, -3), BackgroundColor3 = Theme.SecondaryBg,
    }, hit)
    corner(bar, 3)
    stroke(bar, Theme.Border)
    local fill = make("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.AccentGlow }, bar)
    corner(fill, 3)

    local function pctOf(v)
        if opts then
            for i, o in ipairs(opts) do
                if o == v then return #opts > 1 and (i - 1) / (#opts - 1) or 0 end
            end
            return 0
        end
        local span = maxV - minV
        return span > 0 and math.clamp((v - minV) / span, 0, 1) or 0
    end
    local function fromPct(p)
        if opts then
            return opts[math.clamp(math.floor(p * (#opts - 1) + 0.5) + 1, 1, #opts)]
        end
        local v = math.clamp(minV + math.floor((maxV - minV) * p / step + 0.5) * step, minV, maxV)
        return tonumber(string.format("%." .. decimals .. "f", v))
    end

    local value = fromPct(pctOf(cfg.Default ~= nil and cfg.Default or (opts and opts[1] or minV)))
    local function render()
        valLbl.Text = tostring(value) .. suffix
        fill.Size = UDim2.new(pctOf(value), 0, 1, 0)
    end
    render()

    local stopCur
    local function stopDrag()
        if stopCur then stopCur(); stopCur = nil end
    end
    local function update(x)
        local sz = bar.AbsoluteSize.X
        if sz <= 0 then return end
        local v = fromPct(math.clamp((x - bar.AbsolutePosition.X) / sz, 0, 1))
        if v ~= value then
            value = v
            render()
            fire(win, cfg.Callback, v)
        end
    end
    hit.InputBegan:Connect(function(inp)
        if not isPress(inp) then return end
        stopDrag()
        update(inp.Position.X)
        stopCur = trackInput(inp, function(pos) update(pos.X) end)
    end)
    win:Track(stopDrag)

    local w = baseWidget(win, card)
    w._cleanups[#w._cleanups + 1] = stopDrag
    function w:Get() return value end
    function w:Set(v, silent)
        local nv = fromPct(pctOf(v))
        if nv ~= value then
            value = nv
            render()
            if not silent then fire(win, cfg.Callback, value) end
        end
    end
    extend(win, w, card, cfg)
    return w
end

Builders.Input = function(win, parent, cfg)
    local card, top = newCard(parent, 42)
    rowLabel(top, cfg.Text or "Input", UDim2.new(0, 120, 1, 0))
    local box = make("TextBox", {
        Size = UDim2.new(1, -150, 0, 28), Position = UDim2.new(0, 136, 0.5, -14),
        BackgroundColor3 = Theme.SecondaryBg, PlaceholderText = cfg.Placeholder or "Type here...",
        PlaceholderColor3 = Color3.fromRGB(100, 100, 105), ClearTextOnFocus = false, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
    }, top)
    corner(box, 6)
    stroke(box, Theme.Border)
    pad(box, 8, 0, 8, 0)

    local numeric = cfg.Numeric == true
    local function normalize(v)
        if numeric then
            v = tonumber(v)
            if not v then return nil end
            if cfg.Min then v = math.max(v, cfg.Min) end
            if cfg.Max then v = math.min(v, cfg.Max) end
            if cfg.Integer then v = math.floor(v + 0.5) end
            return v
        end
        return tostring(v)
    end

    local value = normalize(cfg.Default)
    if value == nil then value = numeric and (cfg.Min or 0) or "" end
    box.Text = tostring(value)

    local w = baseWidget(win, card)
    function w:Get() return value end
    function w:Set(v, silent)
        local nv = normalize(v)
        if nv == nil then return end
        box.Text = tostring(nv)
        if nv ~= value then
            value = nv
            if not silent then fire(win, cfg.Callback, value, false) end
        end
    end
    box.FocusLost:Connect(function(enter)
        local nv = normalize(box.Text)
        if nv == nil then
            box.Text = tostring(value)
            return
        end
        box.Text = tostring(nv)
        if nv ~= value or enter then
            value = nv
            fire(win, cfg.Callback, value, enter)
        end
    end)
    extend(win, w, card, cfg)
    return w
end

Builders.ColorPicker = function(win, parent, cfg)
    local card, top = newCard(parent, 42)
    rowLabel(top, cfg.Text or "Color")
    local color = cfg.Default or Theme.AccentGlow
    local swatch = make("TextButton", {
        Size = UDim2.fromOffset(42, 22), AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0), BackgroundColor3 = color,
    }, top)
    corner(swatch, 6)
    stroke(swatch, Theme.Border)
    local w = baseWidget(win, card)
    function w:Get() return color end
    function w:Set(c, silent)
        if c == color then return end
        color = c
        swatch.BackgroundColor3 = c
        if not silent then fire(win, cfg.Callback, c) end
    end
    onTap(swatch, function()
        openColorPicker(win, color, function(c) w:Set(c) end)
    end)
    extend(win, w, card, cfg)
    return w
end

local function buildSelector(win, parent, cfg, isPlayers)
    local card, top = newCard(parent, 46)
    local w = baseWidget(win, card)

    local labelText = cfg.Text or (isPlayers and "Player" or "Select")
    local action = cfg.Action
    local actionType = action and (action.Type or "Button") or nil
    local hasText = action and action.Text and action.Text ~= ""
    local actionW = 0
    if action then
        actionW = action.Width
            or (actionType == "Button" and 88)
            or (actionType == "Toggle" and (hasText and 108 or 48))
            or (hasText and 94 or 30)
    end

    local selBtn, txt = makeSelectorButton(top, action and actionW + 8 or 0)

    local selected = nil
    local options, byName = {}, {}

    local function collect()
        if not isPlayers then return end
        options, byName = {}, {}
        for _, p in ipairs(Players:GetPlayers()) do
            if cfg.IncludeLocal or p ~= Players.LocalPlayer then
                options[#options + 1] = p.Name
                byName[p.Name] = p
            end
        end
        table.sort(options, function(a, b) return a:lower() < b:lower() end)
    end
    if isPlayers then
        collect()
    else
        for i, o in ipairs(cfg.Options or {}) do options[i] = o end
    end

    local function updateText()
        local d = "---"
        if selected ~= nil then d = isPlayers and selected.Name or tostring(selected) end
        txt.Text = labelText .. ": " .. d
    end
    updateText()

    local sub, refreshExtras = extend(win, w, card, cfg, function(cb)
        return function(...) cb(selected, ...) end
    end)
    if sub then
        sub.Visible = false
        refreshExtras()
    end

    local function choose(v, silent)
        if v == selected then return end
        selected = v
        updateText()
        if sub then
            sub.Visible = selected ~= nil
            refreshExtras()
        end
        if not silent then fire(win, cfg.Callback, selected) end
    end

    local actionState = false
    local setAction
    if action then
        local holder = make("Frame", {
            Size = UDim2.fromOffset(actionW, 30), AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -12, 0.5, 0),
        }, top)
        if actionType == "Button" then
            local b = make("TextButton", {
                Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Theme.SecondaryBg,
                Text = action.Text or "Go", Font = Theme.FontBold, TextSize = 12,
            }, holder)
            corner(b, 6)
            local bs = stroke(b, Theme.Border)
            b.MouseEnter:Connect(function() tween(bs, 0.2, { Color = Theme.AccentGlow }) end)
            b.MouseLeave:Connect(function() tween(bs, 0.2, { Color = Theme.Border }) end)
            onTap(b, function()
                if selected ~= nil then fire(win, action.Callback, selected) end
            end)
        else
            if hasText then
                make("TextLabel", {
                    Size = UDim2.new(1, -50, 1, 0), Text = action.Text, TextSize = 12,
                    TextColor3 = Theme.TextMuted, TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                }, holder)
            end
            local ctl = actionType == "Checkbox"
                and makeCheckbox(holder, UDim2.new(1, 0, 0.5, 0))
                or makeSwitch(holder, UDim2.new(1, 0, 0.5, 0))
            local hit = make("TextButton", { Size = UDim2.new(1, 0, 1, 0) }, holder)
            setAction = function(v, silent)
                v = v and true or false
                if v == actionState then return end
                actionState = v
                ctl.Set(v, true)
                if not silent then fire(win, action.Callback, selected, v) end
            end
            onTap(hit, function() setAction(not actionState) end)
            if action.ResetOnKill ~= false then
                win:_addReset(w, function()
                    if actionState then
                        actionState = false
                        if action.Callback then action.Callback(selected, false) end
                    end
                end)
            end
        end
    end

    onTap(selBtn, function()
        collect()
        local labels, idx = { "---" }, 0
        for i, o in ipairs(options) do
            labels[i + 1] = tostring(o)
            if selected ~= nil then
                if isPlayers then
                    if byName[o] == selected then idx = i + 1 end
                elseif o == selected then
                    idx = i + 1
                end
            end
        end
        openDropdown(win, selBtn, labels, function(i) return i == idx end, function(i)
            if i == 1 then
                choose(nil)
            else
                local o = options[i - 1]
                choose(isPlayers and byName[o] or o)
            end
        end, false)
    end)

    if isPlayers then
        local c = win:Connect(Players.PlayerRemoving, function(p)
            if selected == p then choose(nil) end
        end)
        w._cleanups[#w._cleanups + 1] = function() if c then c:Disconnect() end end
    end

    function w:Get() return selected end
    function w:Set(v, silent)
        if v == nil then return choose(nil, silent) end
        if isPlayers then
            local p = typeof(v) == "Instance" and v or Players:FindFirstChild(tostring(v))
            if p and p:IsA("Player") then choose(p, silent) end
        else
            for _, o in ipairs(options) do
                if o == v then return choose(v, silent) end
            end
        end
    end
    function w:SetOptions(list)
        if isPlayers then return end
        options = {}
        local found = false
        for i, o in ipairs(list) do
            options[i] = o
            if o == selected then found = true end
        end
        if selected ~= nil and not found then choose(nil) end
    end
    function w:GetAction() return actionState end
    function w:SetAction(v, silent)
        if setAction then setAction(v, silent) end
    end
    function w:SetText(t)
        labelText = tostring(t)
        updateText()
    end

    if cfg.Default ~= nil then w:Set(cfg.Default) end
    return w
end

Builders.Dropdown = function(win, parent, cfg) return buildSelector(win, parent, cfg, false) end
Builders.List = Builders.Dropdown
Builders.PlayerList = function(win, parent, cfg) return buildSelector(win, parent, cfg, true) end

Builders.MultiDropdown = function(win, parent, cfg)
    local card, top = newCard(parent, 46)
    local w = baseWidget(win, card)
    local labelText = cfg.Text or "Select"
    local selBtn, txt = makeSelectorButton(top, 0)

    local options = {}
    for i, o in ipairs(cfg.Options or {}) do options[i] = o end
    local set = {}
    for _, v in ipairs(cfg.Default or {}) do set[v] = true end

    local function list()
        local out = {}
        for _, o in ipairs(options) do
            if set[o] then out[#out + 1] = o end
        end
        return out
    end
    local function render()
        local names = {}
        for i, o in ipairs(list()) do names[i] = tostring(o) end
        txt.Text = labelText .. ": " .. (#names == 0 and "---" or table.concat(names, ", "))
    end
    render()

    onTap(selBtn, function()
        if #options == 0 then return end
        local labels = {}
        for i, o in ipairs(options) do labels[i] = tostring(o) end
        openDropdown(win, selBtn, labels, function(i) return set[options[i]] == true end, function(i)
            local o = options[i]
            set[o] = not set[o] or nil
            render()
            fire(win, cfg.Callback, list())
        end, true)
    end)

    function w:Get() return list() end
    function w:Set(tbl, silent)
        set = {}
        for _, v in ipairs(tbl) do set[v] = true end
        render()
        if not silent then fire(win, cfg.Callback, list()) end
    end
    function w:SetOptions(newOptions)
        options = {}
        local keep = {}
        for i, o in ipairs(newOptions) do
            options[i] = o
            if set[o] then keep[o] = true end
        end
        set = keep
        render()
    end
    extend(win, w, card, cfg)
    return w
end

for typeName in pairs(Builders) do
    Category[typeName] = function(self, cfg)
        return build(self._win, self._page, typeName, cfg)
    end
end

function Category:Select()
    for _, c in ipairs(self._win._cats) do
        local on = c == self
        c._page.Visible = on
        c._bar.Visible = on
        tween(c._btn, 0.2, {
            BackgroundColor3 = on and Theme.SecondaryBg or Color3.fromRGB(24, 24, 27),
            TextColor3 = on and Theme.TextMain or Theme.TextMuted,
        })
    end
end

function Window:Category(name)
    local cat = setmetatable({ _win = self, Name = name }, Category)
    local btn = make("TextButton", {
        Size = UDim2.new(1, -5, 0, 38), Text = "    " .. name, BackgroundColor3 = Color3.fromRGB(24, 24, 27),
        TextColor3 = Theme.TextMuted, TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = nextOrder(self._catFrame),
    }, self._catFrame)
    corner(btn, 8)
    stroke(btn, Theme.Border)
    local bar = make("Frame", {
        Size = UDim2.fromOffset(4, 16), Position = UDim2.new(0, 6, 0.5, -8),
        BackgroundColor3 = Theme.AccentGlow, Visible = false,
    }, btn)
    corner(bar, 2)
    local page = make("ScrollingFrame", {
        Size = UDim2.new(1, -16, 1, -16), Position = UDim2.fromOffset(8, 8),
        ScrollBarThickness = 4, ScrollBarImageColor3 = Theme.Border,
        AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
        ScrollingDirection = Enum.ScrollingDirection.Y, Visible = false,
    }, self._content)
    page:SetAttribute("Bg", Theme.SecondaryBg)
    make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }, page)
    pad(page, 0, 0, 8, 10)
    cat._btn, cat._bar, cat._page = btn, bar, page
    self._cats[#self._cats + 1] = cat
    onTap(btn, function() cat:Select() end)
    if #self._cats == 1 then cat:Select() end
    return cat
end

local function killActive()
    local prev = env.__ModernUIActive
    env.__ModernUIActive = nil
    if prev and type(prev.Kill) == "function" then pcall(prev.Kill, prev) end
end

local function resolveParent(cfg)
    if cfg.Parent then return cfg.Parent end
    if type(gethui) == "function" then
        local ok, h = pcall(gethui)
        if ok and typeof(h) == "Instance" then return h end
    end
    return Players.LocalPlayer:WaitForChild("PlayerGui")
end

function module.new(cfg)
    cfg = cfg or {}
    killActive()

    local parentGui = resolveParent(cfg)
    local name = cfg.Name or "ModernScriptUI"
    local stale = parentGui:FindFirstChild(name)
    if stale then stale:Destroy() end

    local size = cfg.Size or Vector2.new(620, 420)
    local win = setmetatable({
        Alive = true, Hidden = false, Compact = false, _size = size,
        _items = {}, _threads = {}, _resets = {}, _hooks = {}, _cats = {},
        _confirmClose = cfg.ConfirmClose ~= false,
    }, Window)
    if cfg.OnClose then win._hooks[1] = cfg.OnClose end

    local gui = make("ScreenGui", {
        Name = name, ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = cfg.DisplayOrder or 9999, IgnoreGuiInset = true,
    }, parentGui)

    local main = make("CanvasGroup", {
        Size = UDim2.fromOffset(size.X, size.Y),
        Position = UDim2.new(0.5, -size.X / 2, 0.5, -size.Y / 2),
        BackgroundColor3 = Theme.Background, GroupTransparency = 1, Active = true, ZIndex = 1,
    }, gui)
    corner(main, 14)
    stroke(main, Theme.Border)

    local bar = make("Frame", { Size = UDim2.new(1, 0, 0, 45), Active = true }, main)
    make("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = Theme.Border }, bar)
    local title = make("TextLabel", {
        Size = UDim2.new(1, -120, 1, 0), Position = UDim2.fromOffset(20, 0),
        Text = string.upper(resolveTitle(cfg.Title or "Modern Suite")), Font = Theme.FontBold, TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, bar)
    make("UIGradient", { Color = ColorSequence.new(Theme.TextMain, Color3.fromRGB(200, 200, 200)) }, title)

    local function ctrl(text, x, hoverColor, fn)
        local b = make("TextButton", {
            Size = UDim2.fromOffset(24, 24), Position = UDim2.new(1, -105 + x, 0.5, -12), Text = text,
            Font = Theme.FontBold, TextSize = 11, TextColor3 = Theme.TextMuted, BackgroundColor3 = Theme.SecondaryBg,
        }, bar)
        corner(b, 6)
        stroke(b, Theme.Border)
        b.MouseEnter:Connect(function() tween(b, 0.2, { BackgroundColor3 = hoverColor, TextColor3 = Theme.TextMain }) end)
        b.MouseLeave:Connect(function() tween(b, 0.2, { BackgroundColor3 = Theme.SecondaryBg, TextColor3 = Theme.TextMuted }) end)
        b.Activated:Connect(fn)
        return b
    end
    ctrl("—", 0, Theme.Warning, function() win:Hide() end)
    ctrl("~", 30, Theme.AccentGlow, function() win:SetCompact(not win.Compact) end)
    ctrl("×", 60, Theme.Danger, function() win:RequestClose() end)

    local catFrame = make("ScrollingFrame", {
        Size = UDim2.new(0, 160, 1, -65), Position = UDim2.fromOffset(12, 55), ScrollBarThickness = 0,
        AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
    }, main)
    make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }, catFrame)

    local content = make("Frame", {
        Size = UDim2.new(1, -196, 1, -65), Position = UDim2.fromOffset(184, 55), BackgroundColor3 = Theme.SecondaryBg,
    }, main)
    corner(content, 10)
    stroke(content, Theme.Border)

    local minF = make("ImageButton", {
        Size = UDim2.fromOffset(48, 48), Position = UDim2.new(0.05, 0, 0.1, 0),
        BackgroundColor3 = Theme.Background, Visible = false, ZIndex = 2,
    }, gui)
    corner(minF, 24)
    stroke(minF, Theme.AccentGlow)
    local plus = make("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0), Text = "+", TextColor3 = Theme.AccentGlow, Font = Theme.FontBold, TextSize = 24,
    }, minF)

    local popups = make("Frame", { Size = UDim2.new(1, 0, 1, 0), ZIndex = 10 }, gui)

    local cdim = make("TextButton", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1, Visible = false, ZIndex = 5,
    }, popups)
    local cbox = make("CanvasGroup", {
        Size = UDim2.fromOffset(320, 120), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundColor3 = Theme.SecondaryBg, GroupTransparency = 1, Visible = false, Active = true, ZIndex = 6,
    }, popups)
    corner(cbox, 12)
    stroke(cbox, Theme.Border)
    make("TextLabel", {
        Size = UDim2.new(1, -40, 0, 60), Position = UDim2.fromOffset(20, 15), TextSize = 14, TextWrapped = true,
        Text = cfg.ConfirmText or "Close the menu? All active functions will be stopped.",
    }, cbox)
    local yes = make("TextButton", {
        Size = UDim2.fromOffset(130, 36), Position = UDim2.new(0, 20, 1, -50), Text = "Yes",
        Font = Theme.FontBold, BackgroundColor3 = Theme.Danger,
    }, cbox)
    corner(yes, 8)
    local no = make("TextButton", {
        Size = UDim2.fromOffset(130, 36), Position = UDim2.new(0, 170, 1, -50), Text = "No",
        Font = Theme.FontBold, BackgroundColor3 = Theme.Border,
    }, cbox)
    corner(no, 8)

    local token = 0
    win._setConfirm = function(show)
        token = token + 1
        local mine = token
        if show then
            cdim.Visible = true
            cbox.Visible = true
            cbox.Size = UDim2.fromOffset(320, 120)
            tween(cdim, 0.2, { BackgroundTransparency = 0.55 })
            tween(cbox, 0.3, { Size = UDim2.fromOffset(320, 140), GroupTransparency = 0 }, Enum.EasingStyle.Back)
        else
            tween(cdim, 0.15, { BackgroundTransparency = 1 })
            tween(cbox, 0.15, { Size = UDim2.fromOffset(320, 120), GroupTransparency = 1 }).Completed:Once(function()
                if mine == token then
                    cdim.Visible = false
                    cbox.Visible = false
                end
            end)
        end
    end
    yes.Activated:Connect(function() win:Kill() end)
    no.Activated:Connect(function() win._setConfirm(false) end)
    cdim.Activated:Connect(function() win._setConfirm(false) end)

    win._gui, win._main, win._title, win._minF, win._plus = gui, main, title, minF, plus
    win._catFrame, win._content, win._popups = catFrame, content, popups

    win:Track(makeDraggable(main, bar))
    win:Track(makeDraggable(minF, minF))
    onTap(minF, function() win:Show() end, 0.35)

    if cfg.MinimizedImage ~= nil then win:SetMinimizedImage(cfg.MinimizedImage) end

    env.__ModernUIActive = win
    tween(main, 0.2, { GroupTransparency = 0 })
    return win
end

function module.Kill()
    killActive()
end

function module.GetActive()
    return env.__ModernUIActive
end

return module
