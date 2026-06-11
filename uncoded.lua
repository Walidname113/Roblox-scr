-- v31 (New: CreateList, CreatePlayerList refactor w/ subConfig + as subItem,
--      all widget types available as subConfig items including Slider/Toggle/Input/
--      ColorPicker/Label/Separator/List/PlayerList, widget:Destroy(), singleton guard,
--      all fixes from v30 preserved) --

local module = {}

local Players         = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService    = game:GetService("TweenService")
local player          = Players.LocalPlayer

local _activeInstance = nil

local Theme = {
    Background  = Color3.fromRGB(15, 15, 18),
    SecondaryBg = Color3.fromRGB(22, 22, 26),
    AccentGlow  = Color3.fromRGB(168, 85, 247),
    TextMain    = Color3.fromRGB(243, 244, 246),
    TextMuted   = Color3.fromRGB(156, 163, 175),
    Border      = Color3.fromRGB(39, 39, 42),
    Success     = Color3.fromRGB(34, 197, 94),
    Danger      = Color3.fromRGB(239, 68, 68),
    FontMain    = Enum.Font.Gotham,
    FontBold    = Enum.Font.GothamBold,
}

-- ─── instance state ───────────────────────────────────────────────────────────
local function newInstanceState()
    return { connections={}, trackedObjects={}, onCloseCallback=nil, activePicker=nil, autoOrder=0 }
end
local function trackConnection(S, c) table.insert(S.connections, c); return c end
local function trackObject(S, o)     table.insert(S.trackedObjects, o); return o end
local function nextOrder(S)          S.autoOrder = S.autoOrder + 1; return S.autoOrder end

local function disconnectAll(S)
    for i = #S.connections, 1, -1 do
        local c = S.connections[i]
        if c and c.Connected then c:Disconnect() end
        S.connections[i] = nil
    end
    if S.onCloseCallback then pcall(S.onCloseCallback); S.onCloseCallback = nil end
end
local function destroyAll(S)
    for i = #S.trackedObjects, 1, -1 do
        local o = S.trackedObjects[i]
        if o and o.Parent then o:Destroy() end
        S.trackedObjects[i] = nil
    end
end

-- ─── draggable ────────────────────────────────────────────────────────────────
local function makeDraggable(S, frame, handle)
    local dh = handle or frame
    local dragging, dragInput, dragStart, startPos
    trackConnection(S, dh.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging=true; dragStart=inp.Position; startPos=frame.Position
            local ec; ec=inp.Changed:Connect(function()
                if inp.UserInputState==Enum.UserInputState.End then dragging=false; if ec.Connected then ec:Disconnect() end end
            end); trackConnection(S, ec)
        end
    end))
    trackConnection(S, frame.InputChanged:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then dragInput=inp end
    end))
    trackConnection(S, UserInputService.InputChanged:Connect(function(inp)
        if inp==dragInput and dragging then
            local d=inp.Position-dragStart
            TweenService:Create(frame,TweenInfo.new(0.12,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
                Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)}):Play()
        end
    end))
end

-- ─── color picker ─────────────────────────────────────────────────────────────
local function createColorPickerUI(S, screenGui, defaultColor, callback)
    if S.activePicker then
        if S.activePicker.Parent then S.activePicker:Destroy() end
        S.activePicker = nil
    end
    local pf = Instance.new("Frame", screenGui)
    pf.Size=UDim2.new(0,340,0,350); pf.Position=UDim2.new(0.5,-170,0.5,-175)
    pf.BackgroundColor3=Color3.fromRGB(24,24,28); pf.ZIndex=5000; pf.Active=true
    Instance.new("UICorner",pf).CornerRadius=UDim.new(0,12)
    local ps=Instance.new("UIStroke",pf); ps.Color=Theme.Border; ps.Thickness=1
    trackObject(S,pf); S.activePicker=pf

    local dh=Instance.new("Frame",pf); dh.Size=UDim2.new(1,0,0,40); dh.BackgroundTransparency=1; dh.ZIndex=5001
    makeDraggable(S,pf,dh)
    local tl=Instance.new("TextLabel",dh); tl.Size=UDim2.new(1,-40,1,0); tl.Position=UDim2.new(0,16,0,0)
    tl.Text="Color Palette"; tl.TextColor3=Theme.TextMain; tl.Font=Theme.FontBold; tl.TextSize=15
    tl.TextXAlignment=Enum.TextXAlignment.Left; tl.BackgroundTransparency=1; tl.ZIndex=5002
    local xb=Instance.new("TextButton",pf); xb.Size=UDim2.new(0,24,0,24); xb.Position=UDim2.new(1,-36,0,8)
    xb.Text="×"; xb.Font=Theme.FontBold; xb.TextSize=18; xb.TextColor3=Theme.TextMuted; xb.BackgroundTransparency=1; xb.ZIndex=5005

    local td=Instance.new("Frame",pf); td.Size=UDim2.new(1,-32,0,130); td.Position=UDim2.new(0,16,0,45)
    td.BackgroundTransparency=1; td.ZIndex=5001
    local lcs=Instance.new("Frame",td); lcs.Size=UDim2.new(0.4,0,1,0); lcs.BackgroundColor3=defaultColor; lcs.ZIndex=5001
    Instance.new("UICorner",lcs).CornerRadius=UDim.new(0,6)
    local rsv=Instance.new("ImageLabel",td); rsv.Size=UDim2.new(0.6,-8,1,0); rsv.Position=UDim2.new(0.4,8,0,0)
    rsv.Image="rbxassetid://4155801252"; rsv.ZIndex=5001; rsv.Active=true
    Instance.new("UICorner",rsv).CornerRadius=UDim.new(0,6)
    local svs=Instance.new("Frame",rsv); svs.Size=UDim2.new(0,14,0,14); svs.AnchorPoint=Vector2.new(0.5,0.5)
    svs.BackgroundTransparency=1; svs.ZIndex=5002
    local sr=Instance.new("UIStroke",svs); sr.Color=Color3.new(1,1,1); sr.Thickness=2
    Instance.new("UICorner",svs).CornerRadius=UDim.new(1,0)

    local hs=Instance.new("Frame",pf); hs.Size=UDim2.new(1,-32,0,16); hs.Position=UDim2.new(0,16,0,190)
    hs.BackgroundColor3=Color3.new(1,1,1); hs.ZIndex=5001; hs.Active=true
    Instance.new("UICorner",hs).CornerRadius=UDim.new(1,0)
    local hg=Instance.new("UIGradient",hs)
    hg.Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0/6,Color3.fromRGB(255,0,0)),   ColorSequenceKeypoint.new(1/6,Color3.fromRGB(255,255,0)),
        ColorSequenceKeypoint.new(2/6,Color3.fromRGB(0,255,0)),   ColorSequenceKeypoint.new(3/6,Color3.fromRGB(0,255,255)),
        ColorSequenceKeypoint.new(4/6,Color3.fromRGB(0,0,255)),   ColorSequenceKeypoint.new(5/6,Color3.fromRGB(255,0,255)),
        ColorSequenceKeypoint.new(6/6,Color3.fromRGB(255,0,0)),
    })
    local hk=Instance.new("Frame",hs); hk.Size=UDim2.new(0,18,0,18); hk.AnchorPoint=Vector2.new(0.5,0.5)
    hk.Position=UDim2.new(0,0,0.5,0); hk.BackgroundColor3=Color3.new(1,1,1); hk.ZIndex=5002
    Instance.new("UICorner",hk).CornerRadius=UDim.new(1,0)
    local hr=Instance.new("UIStroke",hk); hr.Color=Color3.new(0,0,0); hr.Thickness=1.5

    local rc=Instance.new("Frame",pf); rc.Size=UDim2.new(1,-32,0,45); rc.Position=UDim2.new(0,16,0,222)
    rc.BackgroundColor3=Theme.SecondaryBg; rc.ZIndex=5001; rc.Active=true
    Instance.new("UICorner",rc).CornerRadius=UDim.new(0,8)
    Instance.new("UIStroke",rc).Color=Theme.Border
    local rl=Instance.new("TextLabel",rc); rl.Size=UDim2.new(0,45,1,0); rl.Position=UDim2.new(0,12,0,0)
    rl.Text="RGB"; rl.Font=Theme.FontBold; rl.TextSize=12; rl.TextColor3=Theme.TextMuted
    rl.TextXAlignment=Enum.TextXAlignment.Left; rl.BackgroundTransparency=1; rl.ZIndex=5002
    local ri=Instance.new("TextBox",rc); ri.Size=UDim2.new(1,-65,1,0); ri.Position=UDim2.new(0,55,0,0)
    ri.TextXAlignment=Enum.TextXAlignment.Left; ri.Font=Theme.FontMain; ri.TextSize=13
    ri.TextColor3=Theme.TextMain; ri.BackgroundTransparency=1; ri.ClearTextOnFocus=false; ri.ZIndex=5002

    local cH,cS,cV=defaultColor:ToHSV()
    local function upd()
        rsv.BackgroundColor3=Color3.fromHSV(cH,1,1)
        local fc=Color3.fromHSV(cH,cS,cV); lcs.BackgroundColor3=fc
        hk.Position=UDim2.new(cH,0,0.5,0); svs.Position=UDim2.new(cS,0,1-cV,0)
        if not ri:IsFocused() then ri.Text=string.format("%d, %d, %d",math.round(fc.R*255),math.round(fc.G*255),math.round(fc.B*255)) end
    end
    trackConnection(S, ri.FocusLost:Connect(function()
        local r,g,b=ri.Text:match("(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
        if r then local c=Color3.fromRGB(math.clamp(tonumber(r),0,255),math.clamp(tonumber(g),0,255),math.clamp(tonumber(b),0,255)); cH,cS,cV=c:ToHSV(); upd() end
    end))

    local settingH,settingSV=false,false
    trackConnection(S,hs.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then settingH=true; cH=math.clamp((inp.Position.X-hs.AbsolutePosition.X)/hs.AbsoluteSize.X,0,1); upd() end end))
    trackConnection(S,rsv.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then settingSV=true; cS=math.clamp((inp.Position.X-rsv.AbsolutePosition.X)/rsv.AbsoluteSize.X,0,1); cV=1-math.clamp((inp.Position.Y-rsv.AbsolutePosition.Y)/rsv.AbsoluteSize.Y,0,1); upd() end end))
    trackConnection(S,UserInputService.InputChanged:Connect(function(inp)
        if (settingH or settingSV) and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
            if settingH then cH=math.clamp((inp.Position.X-hs.AbsolutePosition.X)/hs.AbsoluteSize.X,0,1) end
            if settingSV then cS=math.clamp((inp.Position.X-rsv.AbsolutePosition.X)/rsv.AbsoluteSize.X,0,1); cV=1-math.clamp((inp.Position.Y-rsv.AbsolutePosition.Y)/rsv.AbsoluteSize.Y,0,1) end
            upd()
        end
    end))
    trackConnection(S,UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then settingH=false; settingSV=false end
    end))

    local ab=Instance.new("TextButton",pf); ab.Size=UDim2.new(0,140,0,36); ab.Position=UDim2.new(0,16,1,-52)
    ab.Text="Apply"; ab.Font=Theme.FontBold; ab.TextSize=13; ab.BackgroundColor3=Theme.Success; ab.TextColor3=Theme.TextMain; ab.ZIndex=5001
    Instance.new("UICorner",ab).CornerRadius=UDim.new(0,6)
    local cb2=Instance.new("TextButton",pf); cb2.Size=UDim2.new(0,140,0,36); cb2.Position=UDim2.new(1,-156,1,-52)
    cb2.Text="Cancel"; cb2.Font=Theme.FontBold; cb2.TextSize=13; cb2.BackgroundColor3=Theme.SecondaryBg; cb2.TextColor3=Theme.TextMuted; cb2.ZIndex=5001
    Instance.new("UICorner",cb2).CornerRadius=UDim.new(0,6); Instance.new("UIStroke",cb2).Color=Theme.Border

    local function closeAnim(save)
        if not pf.Parent then return end
        local os=pf.Size; local op=pf.Position
        for _,d in ipairs(pf:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then TweenService:Create(d,TweenInfo.new(0.12),{TextTransparency=1}):Play()
            elseif d:IsA("Frame") then TweenService:Create(d,TweenInfo.new(0.12),{BackgroundTransparency=1}):Play()
            elseif d:IsA("ImageLabel") or d:IsA("ImageButton") then TweenService:Create(d,TweenInfo.new(0.12),{BackgroundTransparency=1,ImageTransparency=1}):Play()
            elseif d:IsA("UIStroke") then TweenService:Create(d,TweenInfo.new(0.12),{Transparency=1}):Play() end
        end
        local t=TweenService:Create(pf,TweenInfo.new(0.15,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{
            Size=UDim2.new(0,os.X.Offset*0.8,0,os.Y.Offset*0.8),
            Position=UDim2.new(op.X.Scale,op.X.Offset+os.X.Offset*0.1,op.Y.Scale,op.Y.Offset+os.Y.Offset*0.1),
            BackgroundTransparency=1}); t:Play()
        local ec; ec=t.Completed:Connect(function()
            ec:Disconnect()
            if save and callback then callback(Color3.fromHSV(cH,cS,cV)) end
            if S.activePicker==pf then S.activePicker=nil end
            if pf.Parent then pf:Destroy() end
        end)
    end
    trackConnection(S,ab.MouseButton1Click:Connect(function() closeAnim(true) end))
    trackConnection(S,cb2.MouseButton1Click:Connect(function() closeAnim(false) end))
    trackConnection(S,xb.MouseButton1Click:Connect(function() closeAnim(false) end))

    pf.Size=UDim2.new(0,272,0,280); pf.Position=UDim2.new(0.5,-136,0.5,-140); pf.BackgroundTransparency=1
    TweenService:Create(pf,TweenInfo.new(0.25,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
        Size=UDim2.new(0,340,0,350),Position=UDim2.new(0.5,-170,0.5,-175),BackgroundTransparency=0}):Play()
    upd()
end

-- ─── dropdown overlay ─────────────────────────────────────────────────────────
local function closeDropdownOverlay(sg)
    local e=sg:FindFirstChild("__DropOverlay"); if e then e:Destroy() end
end
local function openDropdownOverlay(S, sg, anchor, options, onSelect)
    closeDropdownOverlay(sg)
    local ov=Instance.new("Frame",sg); ov.Name="__DropOverlay"; ov.BackgroundTransparency=1
    ov.Size=UDim2.new(1,0,1,0); ov.ZIndex=3000
    local dim=Instance.new("TextButton",ov); dim.Size=UDim2.new(1,0,1,0); dim.BackgroundTransparency=1; dim.Text=""; dim.ZIndex=3000
    local abs=anchor.AbsolutePosition; local absS=anchor.AbsoluteSize
    local ROW=30; local maxR=math.min(#options,5)
    local sc=Instance.new("ScrollingFrame",ov)
    sc.Size=UDim2.new(0,absS.X,0,maxR*ROW); sc.Position=UDim2.new(0,abs.X,0,abs.Y+absS.Y+4)
    sc.BackgroundColor3=Theme.SecondaryBg; sc.ScrollBarThickness=2
    sc.CanvasSize=UDim2.new(0,0,0,#options*ROW); sc.ZIndex=3001
    Instance.new("UICorner",sc).CornerRadius=UDim.new(0,6); Instance.new("UIStroke",sc).Color=Theme.AccentGlow
    local lay=Instance.new("UIListLayout",sc); lay.SortOrder=Enum.SortOrder.LayoutOrder
    for i,opt in ipairs(options) do
        local b=Instance.new("TextButton",sc); b.Size=UDim2.new(1,0,0,ROW); b.Text="  "..tostring(opt)
        b.BackgroundColor3=Theme.SecondaryBg; b.TextColor3=Theme.TextMuted; b.Font=Theme.FontMain
        b.TextSize=12; b.TextXAlignment=Enum.TextXAlignment.Left; b.LayoutOrder=i; b.ZIndex=3002
        trackConnection(S,b.MouseEnter:Connect(function() b.TextColor3=Theme.TextMain end))
        trackConnection(S,b.MouseLeave:Connect(function() b.TextColor3=Theme.TextMuted end))
        trackConnection(S,b.MouseButton1Click:Connect(function() ov:Destroy(); onSelect(opt) end))
    end
    trackConnection(S,dim.MouseButton1Click:Connect(function() ov:Destroy() end))
    return ov
end

-- ─── makeWidget helper ────────────────────────────────────────────────────────
local function makeWidget(container)
    local w={_container=container}
    function w:Destroy()
        if self._container and self._container.Parent then self._container:Destroy() end
    end
    return w
end

-- ─── buildSliderBody: shared between top-level and sub-item ──────────────────
-- Builds the slider track+fill+labels into `parent`, returns {currentVal, setVisual, getVal}.
local function buildSliderBody(S, parent, config, topH)
    config = config or {}
    local sType  = config.SliderType or "Number"
    local list   = config.List or {}
    local minVal = config.Min or 0
    local maxVal = config.Max or 100
    local defVal = config.Default

    local lbl=Instance.new("TextLabel",parent)
    lbl.Size=UDim2.new(1,-60,0,20); lbl.Position=UDim2.new(0,0,0,topH and 8 or 4)
    lbl.BackgroundTransparency=1; lbl.Text=config.Text or "Slider"
    lbl.TextColor3= topH and Theme.TextMain or Theme.TextMuted
    lbl.Font=Theme.FontMain; lbl.TextSize= topH and 13 or 12; lbl.TextXAlignment=Enum.TextXAlignment.Left

    local valLbl=Instance.new("TextLabel",parent)
    valLbl.Size=UDim2.new(0,50,0,20); valLbl.Position=UDim2.new(1, topH and -64 or -50, 0, topH and 8 or 4)
    valLbl.BackgroundTransparency=1; valLbl.TextColor3=topH and Theme.TextMuted or Theme.TextMain
    valLbl.Font=Theme.FontBold; valLbl.TextSize= topH and 13 or 12; valLbl.TextXAlignment=Enum.TextXAlignment.Right

    local yOff = topH and 36 or 26
    local slideBg=Instance.new("Frame",parent)
    slideBg.Size=UDim2.new(1, topH and -28 or 0, 0,6); slideBg.Position=UDim2.new(0,0,0,yOff)
    slideBg.BackgroundColor3=Theme.SecondaryBg; slideBg.Active=true
    Instance.new("UICorner",slideBg).CornerRadius=UDim.new(1,0); Instance.new("UIStroke",slideBg).Color=Theme.Border
    local fill=Instance.new("Frame",slideBg); fill.Size=UDim2.new(0,0,1,0)
    fill.BackgroundColor3=Theme.AccentGlow; Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)

    local function setV(pct) fill.Size=UDim2.new(math.clamp(pct,0,1),0,1,0) end
    local function getFromPct(pct)
        if sType=="Text" then return list[math.clamp(math.floor(pct*#list)+1,1,#list)]
        else return math.floor(minVal+(maxVal-minVal)*pct) end
    end
    local function pctFrom(v)
        if sType=="Text" then for i,x in ipairs(list) do if x==v then return #list>1 and (i-1)/(#list-1) or 0 end end; return 0
        else return (maxVal-minVal)>0 and (v-minVal)/(maxVal-minVal) or 0 end
    end

    if sType=="Text" then defVal=defVal or list[1] else defVal=defVal or minVal end
    local currentVal=defVal
    valLbl.Text=tostring(defVal); setV(pctFrom(defVal))

    local isDrag=false
    local function onDrag(inp)
        local sz=slideBg.AbsoluteSize.X; if sz<=0 then return end
        local pct=math.clamp((inp.Position.X-slideBg.AbsolutePosition.X)/sz,0,1)
        setV(pct); local v=getFromPct(pct); currentVal=v; valLbl.Text=tostring(v)
        if config.Callback then config.Callback(v) end
    end
    trackConnection(S,slideBg.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then isDrag=true; onDrag(inp) end
    end))
    trackConnection(S,UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then isDrag=false end
    end))
    trackConnection(S,UserInputService.InputChanged:Connect(function(inp)
        if isDrag and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then onDrag(inp) end
    end))

    return {
        getCurrentVal = function() return currentVal end,
        setValue = function(v)
            currentVal=v; valLbl.Text=tostring(v); setV(pctFrom(v))
            if config.Callback then config.Callback(v) end
        end,
    }
end

-- ─── buildListBody: shared between CreateList and CreatePlayerList ─────────────
-- actionConfig = { Type="Toggle"|"Button"|"Checkbox", Text=..., Callback=fn }
-- Returns anchor button (for overlay) and action widget table.
local function buildListBody(S, sg, container, labelText, isPlayerList, options, config)
    -- top row: selector button + optional action control
    local ROW_H = 46
    container.Size = UDim2.new(1,-4,0,ROW_H)

    local topRow=Instance.new("Frame",container)
    topRow.Size=UDim2.new(1,0,0,ROW_H); topRow.BackgroundTransparency=1; topRow.LayoutOrder=1

    -- action width depends on whether an action control is present
    local actionCfg = config.Action  -- {Type, Text, Callback}
    local actionW   = actionCfg and 88 or 0
    local btnW      = actionCfg and -(20+actionW+8) or -20

    local selBtn=Instance.new("TextButton",topRow)
    selBtn.Size=UDim2.new(1,btnW,0,32); selBtn.Position=UDim2.new(0,10,0.5,-16)
    selBtn.BackgroundColor3=Theme.SecondaryBg; selBtn.Font=Theme.FontMain; selBtn.TextSize=13
    selBtn.TextColor3=Theme.TextMain; selBtn.TextXAlignment=Enum.TextXAlignment.Left
    selBtn.TextTruncate=Enum.TextTruncate.AtEnd
    Instance.new("UICorner",selBtn).CornerRadius=UDim.new(0,6); Instance.new("UIStroke",selBtn).Color=Theme.Border

    local arrow=Instance.new("TextLabel",selBtn)
    arrow.Size=UDim2.new(0,20,1,0); arrow.Position=UDim2.new(1,-25,0,0)
    arrow.BackgroundTransparency=1; arrow.Text="▼"; arrow.TextColor3=Theme.TextMuted
    arrow.Font=Theme.FontMain; arrow.TextSize=12

    local selected = config.Default or "---"
    local function updateSelText() selBtn.Text="  "..labelText..": "..tostring(selected) end
    updateSelText()

    -- build player list dynamically
    local currentOptions = {}
    local function refreshOptions()
        if isPlayerList then
            currentOptions={}
            for _,p in ipairs(Players:GetPlayers()) do
                if p~=player then table.insert(currentOptions,p.Name) end
            end
        else
            currentOptions = options or {}
        end
    end

    local isOpen=false
    trackConnection(S,selBtn.MouseButton1Click:Connect(function()
        if isOpen then closeDropdownOverlay(sg); isOpen=false; arrow.Rotation=0
        else
            refreshOptions()
            isOpen=true; arrow.Rotation=180
            openDropdownOverlay(S,sg,selBtn,currentOptions,function(opt)
                selected=opt; updateSelText(); isOpen=false; arrow.Rotation=0
                if config.Callback then config.Callback(selected) end
            end)
        end
    end))

    -- PlayerList: live update on player join/leave
    if isPlayerList then
        trackConnection(S, Players.PlayerAdded:Connect(function() end))   -- just to keep state fresh; overlay is rebuilt on open
        trackConnection(S, Players.PlayerRemoving:Connect(function(p)
            if selected==p.Name then selected="---"; updateSelText() end
        end))
    end

    -- action control
    local actionWidget = nil
    if actionCfg then
        local aType = actionCfg.Type or "Button"
        local xOff  = -(actionW+8)

        if aType == "Button" then
            local ab=Instance.new("TextButton",topRow)
            ab.Size=UDim2.new(0,actionW,0,32); ab.Position=UDim2.new(1,-(actionW+8),0.5,-16)
            ab.Text=actionCfg.Text or "Go"; ab.Font=Theme.FontBold; ab.TextSize=12
            ab.BackgroundColor3=Theme.SecondaryBg; ab.TextColor3=Theme.TextMain
            Instance.new("UICorner",ab).CornerRadius=UDim.new(0,6)
            local abs2=Instance.new("UIStroke",ab); abs2.Color=Theme.Border
            trackConnection(S,ab.MouseEnter:Connect(function() TweenService:Create(abs2,TweenInfo.new(0.2),{Color=Theme.AccentGlow}):Play() end))
            trackConnection(S,ab.MouseLeave:Connect(function() TweenService:Create(abs2,TweenInfo.new(0.2),{Color=Theme.Border}):Play() end))
            trackConnection(S,ab.MouseButton1Click:Connect(function()
                if actionCfg.Callback then actionCfg.Callback(selected) end
            end))
            actionWidget = {SetText=function(_,t) ab.Text=t end, GetText=function() return ab.Text end}

        elseif aType == "Toggle" then
            local sw=Instance.new("Frame",topRow)
            sw.Size=UDim2.new(0,42,0,22); sw.Position=UDim2.new(1,-(42+14),0.5,-11)
            sw.BackgroundColor3=Theme.SecondaryBg
            Instance.new("UICorner",sw).CornerRadius=UDim.new(1,0)
            local swSt=Instance.new("UIStroke",sw); swSt.Color=Theme.Border
            local kn=Instance.new("Frame",sw); kn.Size=UDim2.new(0,16,0,16); kn.Position=UDim2.new(0,3,0.5,-8)
            kn.BackgroundColor3=Theme.TextMuted; Instance.new("UICorner",kn).CornerRadius=UDim.new(1,0)
            local en=false
            local function updSw(anim)
                local ti=TweenInfo.new(anim and 0.25 or 0,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
                local bi=TweenInfo.new(anim and 0.2 or 0)
                if en then TweenService:Create(sw,bi,{BackgroundColor3=Theme.AccentGlow}):Play(); TweenService:Create(kn,ti,{Position=UDim2.new(1,-19,0.5,-8),BackgroundColor3=Theme.TextMain}):Play()
                else TweenService:Create(sw,bi,{BackgroundColor3=Theme.SecondaryBg}):Play(); TweenService:Create(kn,ti,{Position=UDim2.new(0,3,0.5,-8),BackgroundColor3=Theme.TextMuted}):Play() end
            end
            updSw(false)
            local tp; trackConnection(S,sw.InputBegan:Connect(function(inp)
                if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then tp=inp.Position end
            end))
            trackConnection(S,sw.InputEnded:Connect(function(inp)
                if (inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch) and tp then
                    if (inp.Position-tp).Magnitude<8 then en=not en; updSw(true); if actionCfg.Callback then actionCfg.Callback(selected,en) end end; tp=nil
                end
            end))
            -- also allow clicking the label area
            trackConnection(S,selBtn.InputBegan:Connect(function() end)) -- no-op, keep selBtn for dropdown
            actionWidget = {SetValue=function(_,v) en=v; updSw(true); if actionCfg.Callback then actionCfg.Callback(selected,en) end end, GetValue=function() return en end}

        elseif aType == "Checkbox" then
            local chkFrame=Instance.new("Frame",topRow)
            chkFrame.Size=UDim2.new(0,22,0,22); chkFrame.Position=UDim2.new(1,-(22+14),0.5,-11)
            chkFrame.BackgroundColor3=Theme.SecondaryBg
            Instance.new("UICorner",chkFrame).CornerRadius=UDim.new(0,5)
            Instance.new("UIStroke",chkFrame).Color=Theme.Border
            local cm=Instance.new("TextLabel",chkFrame); cm.Size=UDim2.new(1,0,1,0); cm.Text="✓"
            cm.TextColor3=Theme.TextMain; cm.Font=Theme.FontBold; cm.TextSize=13; cm.BackgroundTransparency=1; cm.Visible=false
            local chkBtn=Instance.new("TextButton",chkFrame); chkBtn.Size=UDim2.new(1,0,1,0); chkBtn.BackgroundTransparency=1; chkBtn.Text=""
            local en2=false
            trackConnection(S,chkBtn.MouseButton1Click:Connect(function()
                en2=not en2; cm.Visible=en2
                if actionCfg.Callback then actionCfg.Callback(selected,en2) end
            end))
            actionWidget = {SetValue=function(_,v) en2=v; cm.Visible=v; if actionCfg.Callback then actionCfg.Callback(selected,en2) end end, GetValue=function() return en2 end}
        end
    end

    return selBtn, actionWidget, function() return selected end
end

-- ═════════════════════════════════════════════════════════════════════════════
-- applyFeatureExtensions — renders subConfig items into a container.
-- Supports ALL widget types as sub-items.
-- ═════════════════════════════════════════════════════════════════════════════
local applyFeatureExtensions  -- forward declaration (recursive)
applyFeatureExtensions = function(S, sg, container, description, subConfig, descStyle)
    local layout=container:FindFirstChildWhichIsA("UIListLayout")
    if not layout then
        layout=Instance.new("UIListLayout",container)
        layout.SortOrder=Enum.SortOrder.LayoutOrder; layout.Padding=UDim.new(0,6)
    end
    local padding=container:FindFirstChildWhichIsA("UIPadding")
    if not padding then
        padding=Instance.new("UIPadding",container)
        padding.PaddingTop=UDim.new(0,0); padding.PaddingBottom=UDim.new(0,0)
        padding.PaddingLeft=UDim.new(0,0); padding.PaddingRight=UDim.new(0,0)
    end
    if (description and description~="") or (subConfig and #subConfig>0) then
        container.AutomaticSize=Enum.AutomaticSize.Y; padding.PaddingBottom=UDim.new(0,10)
    end

    if subConfig and #subConfig>0 then
        local sf=Instance.new("Frame",container); sf.Size=UDim2.new(1,0,0,0)
        sf.BackgroundTransparency=1; sf.AutomaticSize=Enum.AutomaticSize.Y; sf.LayoutOrder=2
        local sl=Instance.new("UIListLayout",sf); sl.SortOrder=Enum.SortOrder.LayoutOrder; sl.Padding=UDim.new(0,6)
        local sp=Instance.new("UIPadding",sf); sp.PaddingLeft=UDim.new(0,14); sp.PaddingRight=UDim.new(0,14)

        local subOrd=0
        local function nso(item) subOrd=subOrd+1; return item.LayoutOrder or subOrd end

        for _,item in ipairs(subConfig) do
            local ic  -- item container

            -- ── Checkbox ──────────────────────────────────────────────────────
            if item.Type=="Checkbox" then
                ic=Instance.new("Frame",sf); ic.Size=UDim2.new(1,0,0,24); ic.BackgroundTransparency=1; ic.LayoutOrder=nso(item)
                local chk=Instance.new("TextButton",ic); chk.Size=UDim2.new(1,0,1,0); chk.BackgroundTransparency=1; chk.Text=""
                local box=Instance.new("Frame",chk); box.Size=UDim2.new(0,16,0,16); box.Position=UDim2.new(0,0,0.5,-8)
                box.BackgroundColor3=Theme.SecondaryBg; Instance.new("UICorner",box).CornerRadius=UDim.new(0,4); Instance.new("UIStroke",box).Color=Theme.Border
                local cm=Instance.new("TextLabel",box); cm.Size=UDim2.new(1,0,1,0); cm.Text="✓"; cm.TextColor3=Theme.TextMain
                cm.Font=Theme.FontBold; cm.TextSize=12; cm.BackgroundTransparency=1; cm.Visible=item.State or false
                local lbl=Instance.new("TextLabel",chk); lbl.Size=UDim2.new(1,-24,1,0); lbl.Position=UDim2.new(0,24,0,0)
                lbl.BackgroundTransparency=1; lbl.Text=item.Text or "Option"; lbl.TextColor3=Theme.TextMuted
                lbl.Font=Theme.FontMain; lbl.TextSize=12; lbl.TextXAlignment=Enum.TextXAlignment.Left
                local active=item.State or false
                trackConnection(S,chk.MouseButton1Click:Connect(function()
                    active=not active; cm.Visible=active
                    TweenService:Create(lbl,TweenInfo.new(0.2),{TextColor3=active and Theme.TextMain or Theme.TextMuted}):Play()
                    if item.Callback then item.Callback(active) end
                end))

            -- ── Toggle ────────────────────────────────────────────────────────
            elseif item.Type=="Toggle" then
                ic=Instance.new("Frame",sf); ic.Size=UDim2.new(1,0,0,30); ic.BackgroundTransparency=1; ic.LayoutOrder=nso(item)
                local lbl=Instance.new("TextLabel",ic); lbl.Size=UDim2.new(1,-60,1,0); lbl.Position=UDim2.new(0,0,0,0)
                lbl.BackgroundTransparency=1; lbl.Text=item.Text or "Toggle"; lbl.Font=Theme.FontMain; lbl.TextSize=12
                lbl.TextColor3=Theme.TextMain; lbl.TextXAlignment=Enum.TextXAlignment.Left
                local sw=Instance.new("Frame",ic); sw.Size=UDim2.new(0,36,0,18); sw.Position=UDim2.new(1,-40,0.5,-9)
                sw.BackgroundColor3=Theme.SecondaryBg; Instance.new("UICorner",sw).CornerRadius=UDim.new(1,0)
                local swSt=Instance.new("UIStroke",sw); swSt.Color=Theme.Border
                local kn=Instance.new("Frame",sw); kn.Size=UDim2.new(0,12,0,12); kn.Position=UDim2.new(0,3,0.5,-6)
                kn.BackgroundColor3=Theme.TextMuted; Instance.new("UICorner",kn).CornerRadius=UDim.new(1,0)
                local en=item.State or false
                local function updT(anim)
                    local ti=TweenInfo.new(anim and 0.2 or 0,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
                    local bi=TweenInfo.new(anim and 0.15 or 0)
                    if en then TweenService:Create(sw,bi,{BackgroundColor3=Theme.AccentGlow}):Play(); TweenService:Create(kn,ti,{Position=UDim2.new(1,-15,0.5,-6),BackgroundColor3=Theme.TextMain}):Play()
                    else TweenService:Create(sw,bi,{BackgroundColor3=Theme.SecondaryBg}):Play(); TweenService:Create(kn,ti,{Position=UDim2.new(0,3,0.5,-6),BackgroundColor3=Theme.TextMuted}):Play() end
                end; updT(false)
                local tp; local btn=Instance.new("TextButton",ic); btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1; btn.Text=""
                trackConnection(S,btn.InputBegan:Connect(function(inp)
                    if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then tp=inp.Position end
                end))
                trackConnection(S,btn.InputEnded:Connect(function(inp)
                    if (inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch) and tp then
                        if (inp.Position-tp).Magnitude<8 then en=not en; updT(true); if item.Callback then item.Callback(en) end end; tp=nil
                    end
                end))

            -- ── Color ─────────────────────────────────────────────────────────
            elseif item.Type=="Color" then
                ic=Instance.new("Frame",sf); ic.Size=UDim2.new(1,0,0,26); ic.BackgroundTransparency=1; ic.LayoutOrder=nso(item)
                local lbl=Instance.new("TextLabel",ic); lbl.Size=UDim2.new(0,100,1,0); lbl.BackgroundTransparency=1
                lbl.Text=item.Text or "Color"; lbl.TextColor3=Theme.TextMuted; lbl.Font=Theme.FontMain; lbl.TextSize=12; lbl.TextXAlignment=Enum.TextXAlignment.Left
                local ac=item.DefaultColor or Color3.fromRGB(168,85,247)
                local cb=Instance.new("TextButton",ic); cb.Size=UDim2.new(0,36,0,18); cb.Position=UDim2.new(1,-36,0.5,-9)
                cb.BackgroundColor3=ac; cb.Text=""; Instance.new("UICorner",cb).CornerRadius=UDim.new(0,4); Instance.new("UIStroke",cb).Color=Theme.Border
                trackConnection(S,cb.MouseButton1Click:Connect(function()
                    createColorPickerUI(S,sg,ac,function(c) ac=c; cb.BackgroundColor3=c; if item.Callback then item.Callback(c) end end)
                end))

            -- ── Input ─────────────────────────────────────────────────────────
            elseif item.Type=="Input" then
                local iH=item.InputHeight or 28; local ts=item.TextSize or 12
                local inT=item.InputType or "Any"; local mn=item.Min; local mx=item.Max
                local dv=item.Default or (inT=="Number" and 0 or "")
                ic=Instance.new("Frame",sf); ic.Size=UDim2.new(1,0,0,iH); ic.BackgroundTransparency=1; ic.LayoutOrder=nso(item)
                local lbl=Instance.new("TextLabel",ic); lbl.Size=UDim2.new(0,100,1,0); lbl.BackgroundTransparency=1
                lbl.Text=item.Text or "Input"; lbl.TextColor3=Theme.TextMuted; lbl.Font=Theme.FontMain; lbl.TextSize=ts; lbl.TextXAlignment=Enum.TextXAlignment.Left
                local bx=Instance.new("TextBox",ic); bx.Size=UDim2.new(1,-105,0,iH); bx.Position=UDim2.new(0,105,0.5,-iH/2)
                bx.BackgroundColor3=Theme.SecondaryBg; bx.Text=tostring(dv); bx.PlaceholderText=item.Placeholder or "Type here..."
                bx.PlaceholderColor3=Color3.fromRGB(100,100,105); bx.TextColor3=Theme.TextMain; bx.Font=Theme.FontMain
                bx.TextSize=ts; bx.ClearTextOnFocus=false
                Instance.new("UICorner",bx).CornerRadius=UDim.new(0,6); Instance.new("UIStroke",bx).Color=Theme.Border
                trackConnection(S,bx.FocusLost:Connect(function(ep)
                    if inT=="Number" then local n=tonumber(bx.Text) or dv; if mn then n=math.max(mn,n) end; if mx then n=math.min(mx,n) end; bx.Text=tostring(n); if item.Callback then item.Callback(n,ep) end
                    else if item.Callback then item.Callback(bx.Text,ep) end end
                end))

            -- ── Button ────────────────────────────────────────────────────────
            elseif item.Type=="Button" then
                ic=Instance.new("Frame",sf); ic.Size=UDim2.new(1,0,0,28); ic.BackgroundTransparency=1; ic.LayoutOrder=nso(item)
                local btn=Instance.new("TextButton",ic); btn.Size=UDim2.new(1,0,1,0); btn.BackgroundColor3=Theme.SecondaryBg
                btn.Text=item.Text or "Button"; btn.TextColor3=Theme.TextMain; btn.Font=Theme.FontBold; btn.TextSize=11
                Instance.new("UICorner",btn).CornerRadius=UDim.new(0,6)
                local bst=Instance.new("UIStroke",btn); bst.Color=Theme.Border
                trackConnection(S,btn.MouseEnter:Connect(function() TweenService:Create(bst,TweenInfo.new(0.2),{Color=Theme.AccentGlow}):Play() end))
                trackConnection(S,btn.MouseLeave:Connect(function() TweenService:Create(bst,TweenInfo.new(0.2),{Color=Theme.Border}):Play() end))
                trackConnection(S,btn.MouseButton1Click:Connect(function() if item.Callback then item.Callback() end end))

            -- ── Slider ────────────────────────────────────────────────────────
            elseif item.Type=="Slider" then
                ic=Instance.new("Frame",sf); ic.Size=UDim2.new(1,0,0,42); ic.BackgroundTransparency=1
                ic.LayoutOrder=nso(item); ic.AutomaticSize=Enum.AutomaticSize.Y
                local inner=Instance.new("Frame",ic); inner.Size=UDim2.new(1,0,0,42); inner.BackgroundTransparency=1
                buildSliderBody(S, inner, item, false)

            -- ── Dropdown ──────────────────────────────────────────────────────
            elseif item.Type=="Dropdown" then
                ic=Instance.new("Frame",sf); ic.Size=UDim2.new(1,0,0,32); ic.BackgroundTransparency=1
                ic.LayoutOrder=nso(item); ic.AutomaticSize=Enum.AutomaticSize.Y
                local dt=Instance.new("Frame",ic); dt.Size=UDim2.new(1,0,0,32); dt.BackgroundTransparency=1
                local btn=Instance.new("TextButton",dt); btn.Size=UDim2.new(1,0,0,32)
                btn.BackgroundColor3=Theme.SecondaryBg; btn.Text="  "..(item.Text or "Dropdown")..": "..tostring(item.Default or "---")
                btn.TextColor3=Theme.TextMain; btn.Font=Theme.FontMain; btn.TextSize=12; btn.TextXAlignment=Enum.TextXAlignment.Left
                Instance.new("UICorner",btn).CornerRadius=UDim.new(0,6); Instance.new("UIStroke",btn).Color=Theme.Border
                local arr=Instance.new("TextLabel",btn); arr.Size=UDim2.new(0,20,1,0); arr.Position=UDim2.new(1,-25,0,0)
                arr.BackgroundTransparency=1; arr.Text="▼"; arr.TextColor3=Theme.TextMuted; arr.Font=Theme.FontMain; arr.TextSize=10
                local isOp=false
                trackConnection(S,btn.MouseButton1Click:Connect(function()
                    if isOp then closeDropdownOverlay(sg); isOp=false; arr.Rotation=0
                    else isOp=true; arr.Rotation=180
                        openDropdownOverlay(S,sg,btn,item.Options or {},function(opt)
                            btn.Text="  "..(item.Text or "Dropdown")..": "..tostring(opt); isOp=false; arr.Rotation=0
                            if item.Callback then item.Callback(opt) end
                        end)
                    end
                end))

            -- ── Label ─────────────────────────────────────────────────────────
            elseif item.Type=="Label" then
                local lh=item.Height or 22
                ic=Instance.new("Frame",sf); ic.Size=UDim2.new(1,0,0,lh); ic.BackgroundTransparency=1; ic.LayoutOrder=nso(item)
                local lbl=Instance.new("TextLabel",ic); lbl.Size=UDim2.new(1,0,1,0)
                lbl.BackgroundTransparency=1; lbl.Text=item.Text or ""
                lbl.TextColor3=item.Color or Theme.TextMuted; lbl.Font=item.Bold and Theme.FontBold or Theme.FontMain
                lbl.TextSize=item.TextSize or 11; lbl.TextXAlignment=item.Align or Enum.TextXAlignment.Left; lbl.TextWrapped=true

            -- ── Separator ─────────────────────────────────────────────────────
            elseif item.Type=="Separator" then
                local sh=item.Height or 1; local svp=item.Padding or 4
                ic=Instance.new("Frame",sf); ic.Size=UDim2.new(1,0,0,sh+svp*2); ic.BackgroundTransparency=1; ic.LayoutOrder=nso(item)
                local ln=Instance.new("Frame",ic); ln.Size=UDim2.new(1,-8,0,sh); ln.Position=UDim2.new(0,4,0.5,-math.floor(sh/2))
                ln.BackgroundColor3=item.Color or Theme.Border; ln.BorderSizePixel=0
                Instance.new("UICorner",ln).CornerRadius=UDim.new(1,0)
                if item.Label and item.Label~="" then
                    ln.Visible=false
                    local bg=Instance.new("Frame",ln); bg.AnchorPoint=Vector2.new(0.5,0.5); bg.Position=UDim2.new(0.5,0,0.5,0)
                    bg.BackgroundColor3=Theme.SecondaryBg; bg.BorderSizePixel=0; bg.AutomaticSize=Enum.AutomaticSize.X; bg.Size=UDim2.new(0,4,1,8)
                    local sl2=Instance.new("TextLabel",bg); sl2.AutomaticSize=Enum.AutomaticSize.X; sl2.Size=UDim2.new(0,0,1,0)
                    sl2.BackgroundTransparency=1; sl2.Text=" "..item.Label.." "; sl2.TextColor3=item.LabelColor or Theme.TextMuted
                    sl2.Font=Theme.FontMain; sl2.TextSize=item.LabelSize or 10
                    task.defer(function() if ln and ln.Parent then ln.Visible=true end end)
                end

            -- ── List (sub-item) ───────────────────────────────────────────────
            elseif item.Type=="List" then
                ic=Instance.new("Frame",sf); ic.BackgroundTransparency=1; ic.LayoutOrder=nso(item)
                ic.AutomaticSize=Enum.AutomaticSize.Y; ic.Size=UDim2.new(1,0,0,0)
                local lbl2=Instance.new("UIListLayout",ic); lbl2.SortOrder=Enum.SortOrder.LayoutOrder; lbl2.Padding=UDim.new(0,4)
                local _, _, _ = buildListBody(S, sg, ic, item.Text or "List", false, item.Options or {}, {
                    Default=item.Default, Callback=item.Callback, Action=item.Action
                })
                applyFeatureExtensions(S, sg, ic, item.Description, item.subConfig, item.DescStyle)

            -- ── PlayerList (sub-item) ─────────────────────────────────────────
            elseif item.Type=="PlayerList" then
                ic=Instance.new("Frame",sf); ic.BackgroundTransparency=1; ic.LayoutOrder=nso(item)
                ic.AutomaticSize=Enum.AutomaticSize.Y; ic.Size=UDim2.new(1,0,0,0)
                local lbl3=Instance.new("UIListLayout",ic); lbl3.SortOrder=Enum.SortOrder.LayoutOrder; lbl3.Padding=UDim.new(0,4)
                buildListBody(S, sg, ic, item.Text or "Player", true, {}, {
                    Default=item.Default, Callback=item.Callback, Action=item.Action
                })
                applyFeatureExtensions(S, sg, ic, item.Description, item.subConfig, item.DescStyle)
            end

            -- recurse into sub-sub-config for items that support it
            if ic and item.subConfig and item.Type~="List" and item.Type~="PlayerList" then
                applyFeatureExtensions(S, sg, ic, item.Description, item.subConfig, item.DescStyle)
            end
        end
    end

    if description and description~="" then
        descStyle=descStyle or {}
        local dl=Instance.new("TextLabel",container); dl.Size=UDim2.new(1,-28,0,0); dl.Position=UDim2.new(0,14,0,0)
        dl.BackgroundTransparency=1; dl.Text=description; dl.TextColor3=descStyle.Color or Color3.fromRGB(255,255,255)
        dl.TextTransparency=descStyle.Transparency or 0; dl.Font=descStyle.Font or Theme.FontMain
        dl.TextSize=descStyle.TextSize or 11; dl.TextXAlignment=Enum.TextXAlignment.Left
        dl.TextWrapped=true; dl.AutomaticSize=Enum.AutomaticSize.Y; dl.LayoutOrder=3
        local dp=Instance.new("UIPadding",dl); dp.PaddingLeft=UDim.new(0,14); dp.PaddingRight=UDim.new(0,14)
    end
end

-- ═════════════════════════════════════════════════════════════════════════════
function module.CreateUI(title)
    if _activeInstance then pcall(function() _activeInstance.Close() end); _activeInstance=nil end

    local headerText = title or "Modern Suite"
    local S = newInstanceState()

    local sg=Instance.new("ScreenGui"); sg.Name="ModernScriptUI"; sg.ResetOnSpawn=false
    sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; sg.DisplayOrder=9999
    sg.Parent=player:WaitForChild("PlayerGui"); trackObject(S,sg)

    local mf=Instance.new("Frame"); mf.Size=UDim2.new(0,620,0,420); mf.Position=UDim2.new(0.5,-310,0.5,-210)
    mf.BackgroundColor3=Theme.Background; mf.BorderSizePixel=0; mf.Active=true; mf.ClipsDescendants=true; mf.Parent=sg
    Instance.new("UICorner",mf).CornerRadius=UDim.new(0,14); makeDraggable(S,mf); trackObject(S,mf)
    local mst=Instance.new("UIStroke",mf); mst.Color=Theme.Border; mst.Thickness=1; mst.ApplyStrokeMode=Enum.ApplyStrokeMode.Border

    local hl=Instance.new("Frame",mf); hl.Size=UDim2.new(1,0,0,1); hl.Position=UDim2.new(0,0,0,45)
    hl.BackgroundColor3=Theme.Border; hl.BorderSizePixel=0

    local hdr=Instance.new("TextLabel",mf); hdr.Size=UDim2.new(1,-120,0,45); hdr.Position=UDim2.new(0,20,0,0)
    hdr.Text=headerText:upper(); hdr.TextColor3=Theme.TextMain; hdr.BackgroundTransparency=1
    hdr.Font=Theme.FontBold; hdr.TextSize=14; hdr.TextXAlignment=Enum.TextXAlignment.Left
    local ug=Instance.new("UIGradient",hdr); ug.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Theme.TextMain),ColorSequenceKeypoint.new(1,Color3.fromRGB(200,200,200))})

    local cb=Instance.new("Frame",mf); cb.Size=UDim2.new(0,90,0,45); cb.Position=UDim2.new(1,-105,0,0); cb.BackgroundTransparency=1
    local function mkCtrlBtn(text,posX,col)
        local b=Instance.new("TextButton",cb); b.Size=UDim2.new(0,24,0,24); b.Position=UDim2.new(0,posX,0.5,-12)
        b.BackgroundColor3=Theme.SecondaryBg; b.Text=text; b.Font=Theme.FontBold; b.TextSize=11; b.TextColor3=Theme.TextMuted
        Instance.new("UICorner",b).CornerRadius=UDim.new(0,6); local st=Instance.new("UIStroke",b); st.Color=Theme.Border
        trackConnection(S,b.MouseEnter:Connect(function() TweenService:Create(b,TweenInfo.new(0.2),{BackgroundColor3=col,TextColor3=Theme.TextMain}):Play() end))
        trackConnection(S,b.MouseLeave:Connect(function() TweenService:Create(b,TweenInfo.new(0.2),{BackgroundColor3=Theme.SecondaryBg,TextColor3=Theme.TextMuted}):Play() end))
        return b
    end
    local minBtn  = mkCtrlBtn("—",0,Color3.fromRGB(234,179,8))
    local scaleBtn= mkCtrlBtn("~",30,Theme.AccentGlow)
    local closeBtn= mkCtrlBtn("×",60,Theme.Danger)

    -- confirm modal
    local cf=Instance.new("Frame",sg); cf.Size=UDim2.new(0,320,0,140); cf.Position=UDim2.new(0.5,-160,0.5,-70)
    cf.BackgroundColor3=Theme.SecondaryBg; cf.ClipsDescendants=true; cf.BackgroundTransparency=1; cf.Visible=false
    Instance.new("UICorner",cf).CornerRadius=UDim.new(0,12); Instance.new("UIStroke",cf).Color=Theme.Border; trackObject(S,cf)
    local ct=Instance.new("TextLabel",cf); ct.Size=UDim2.new(1,-40,0,60); ct.Position=UDim2.new(0,20,0,15)
    ct.Text="Are you sure?"; ct.TextColor3=Theme.TextMain; ct.BackgroundTransparency=1; ct.Font=Theme.FontMain; ct.TextSize=14; ct.TextWrapped=true
    local function mkMBtn(text,px,bg,tc) local b=Instance.new("TextButton",cf); b.Size=UDim2.new(0,130,0,36); b.Position=UDim2.new(0,px,1,-50); b.Text=text; b.BackgroundColor3=bg; b.TextColor3=tc; b.Font=Theme.FontBold; b.TextSize=13; Instance.new("UICorner",b).CornerRadius=UDim.new(0,8); return b end
    local yesB=mkMBtn("Yes",20,Theme.Danger,Theme.TextMain); local noB=mkMBtn("No",170,Color3.fromRGB(39,39,42),Theme.TextMain)

    local function animModal(show)
        if show then cf.Size=UDim2.new(0,320,0,120); cf.BackgroundTransparency=1; cf.Visible=true
            TweenService:Create(cf,TweenInfo.new(0.3,Enum.EasingStyle.Back),{Size=UDim2.new(0,320,0,140),BackgroundTransparency=0}):Play()
        else local tw=TweenService:Create(cf,TweenInfo.new(0.2,Enum.EasingStyle.Quad),{Size=UDim2.new(0,320,0,120),BackgroundTransparency=1}); tw:Play()
            tw.Completed:Connect(function() cf.Visible=false end) end
    end

    local function doClose() _activeInstance=nil; disconnectAll(S); destroyAll(S) end
    trackConnection(S,closeBtn.MouseButton1Click:Connect(function() animModal(true) end))
    trackConnection(S,noB.MouseButton1Click:Connect(function() animModal(false) end))
    trackConnection(S,yesB.MouseButton1Click:Connect(function() doClose() end))

    local isScaled=false; local normSz=UDim2.new(0,620,0,420); local smSz=UDim2.new(0,620,0,200)
    trackConnection(S,scaleBtn.MouseButton1Click:Connect(function()
        isScaled=not isScaled; TweenService:Create(mf,TweenInfo.new(0.3,Enum.EasingStyle.Quad),{Size=isScaled and smSz or normSz}):Play()
    end))

    -- minimized frame
    local minF=Instance.new("ImageButton"); minF.Size=UDim2.new(0,48,0,48); minF.Position=UDim2.new(0.05,0,0.1,0)
    minF.BackgroundColor3=Theme.Background; minF.Visible=false
    Instance.new("UICorner",minF).CornerRadius=UDim.new(1,0); Instance.new("UIStroke",minF).Color=Theme.AccentGlow
    makeDraggable(S,minF); minF.Parent=sg
    local plusIco=Instance.new("TextLabel",minF); plusIco.Size=UDim2.new(1,0,1,0); plusIco.Text="+"
    plusIco.TextColor3=Theme.AccentGlow; plusIco.BackgroundTransparency=1; plusIco.Font=Theme.FontBold; plusIco.TextSize=24; plusIco.Visible=true

    local function setMinImg(assetId)
        local function tryLoad(img)
            minF.Image=img
            local conn; conn=minF:GetPropertyChangedSignal("IsLoaded"):Connect(function()
                if minF.IsLoaded then plusIco.Visible=false; conn:Disconnect() end
            end); if minF.IsLoaded then plusIco.Visible=false; conn:Disconnect() end
        end
        if assetId and assetId~="" then tryLoad("rbxassetid://"..tostring(assetId))
        else local ok,pid=pcall(function() return game.PlaceId end); if ok and pid and pid~=0 then tryLoad("rbxthumb://type=Asset&id="..pid.."&w=150&h=150") end end
    end

    local function toggleMin(minimize)
        if minimize then
            local t=TweenService:Create(mf,TweenInfo.new(0.2,Enum.EasingStyle.Quad),{Size=UDim2.new(0,0,0,0),BackgroundTransparency=1}); t:Play()
            local c; c=t.Completed:Connect(function() c:Disconnect(); mf.Visible=false; minF.Visible=true; minF.Size=UDim2.new(0,0,0,0); TweenService:Create(minF,TweenInfo.new(0.25,Enum.EasingStyle.Back),{Size=UDim2.new(0,48,0,48)}):Play() end)
        else
            local t=TweenService:Create(minF,TweenInfo.new(0.15,Enum.EasingStyle.Quad),{Size=UDim2.new(0,0,0,0)}); t:Play()
            local c; c=t.Completed:Connect(function() c:Disconnect(); minF.Visible=false; mf.Visible=true
                TweenService:Create(mf,TweenInfo.new(0.25,Enum.EasingStyle.Back),{Size=isScaled and smSz or normSz,BackgroundTransparency=0}):Play() end)
        end
    end
    trackConnection(S,minBtn.MouseButton1Click:Connect(function() toggleMin(true) end))
    trackConnection(S,minF.MouseButton1Click:Connect(function() toggleMin(false) end))

    local catFrame=Instance.new("ScrollingFrame",mf); catFrame.Size=UDim2.new(0,160,1,-65); catFrame.Position=UDim2.new(0,12,0,55)
    catFrame.CanvasSize=UDim2.new(0,0,0,0); catFrame.ScrollBarThickness=0; catFrame.BackgroundTransparency=1
    catFrame.AutomaticCanvasSize=Enum.AutomaticSize.Y; trackObject(S,catFrame)
    local catLay=Instance.new("UIListLayout",catFrame); catLay.SortOrder=Enum.SortOrder.LayoutOrder; catLay.Padding=UDim.new(0,8)

    local contentF=Instance.new("Frame",mf); contentF.Size=UDim2.new(1,-196,1,-65); contentF.Position=UDim2.new(0,184,0,55)
    contentF.BackgroundColor3=Theme.SecondaryBg; contentF.BorderSizePixel=0
    Instance.new("UICorner",contentF).CornerRadius=UDim.new(0,10); Instance.new("UIStroke",contentF).Color=Theme.Border; trackObject(S,contentF)

    local cScroll=Instance.new("ScrollingFrame",contentF); cScroll.Size=UDim2.new(1,-16,1,-16); cScroll.Position=UDim2.new(0,8,0,8)
    cScroll.BackgroundTransparency=1; cScroll.ScrollBarThickness=4; cScroll.ScrollBarImageColor3=Theme.Border
    cScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; cScroll.CanvasSize=UDim2.new(0,0,0,0); trackObject(S,cScroll)
    local cPad=Instance.new("UIPadding",cScroll); cPad.PaddingBottom=UDim.new(0,10)

    local categories={}

    -- ── widgets ───────────────────────────────────────────────────────────────
    local uiData={}

    function uiData.CreateCategory(name)
        local btn=Instance.new("TextButton",catFrame); btn.Size=UDim2.new(1,-5,0,38)
        btn.Text="    "..name; btn.BackgroundColor3=Color3.fromRGB(24,24,27); btn.TextColor3=Theme.TextMuted
        btn.Font=Theme.FontMain; btn.TextSize=13; btn.TextXAlignment=Enum.TextXAlignment.Left
        Instance.new("UICorner",btn).CornerRadius=UDim.new(0,8); Instance.new("UIStroke",btn).Color=Theme.Border; trackObject(S,btn)
        local bar=Instance.new("Frame",btn); bar.Size=UDim2.new(0,4,0,16); bar.Position=UDim2.new(0,6,0.5,-8)
        bar.BackgroundColor3=Theme.AccentGlow; bar.Visible=false; Instance.new("UICorner",bar)
        local holder=Instance.new("Frame",cScroll); holder.Size=UDim2.new(1,0,0,0); holder.BackgroundTransparency=1; holder.Visible=false; trackObject(S,holder)
        local lay=Instance.new("UIListLayout",holder); lay.SortOrder=Enum.SortOrder.LayoutOrder; lay.Padding=UDim.new(0,8)
        trackConnection(S,lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            holder.Size=UDim2.new(1,0,0,lay.AbsoluteContentSize.Y)
            if holder.Visible then cScroll.CanvasSize=UDim2.new(0,0,0,lay.AbsoluteContentSize.Y) end
        end))
        trackConnection(S,btn.MouseButton1Click:Connect(function()
            for _,cat in ipairs(categories) do cat.holder.Visible=false; cat.bar.Visible=false
                TweenService:Create(cat.button,TweenInfo.new(0.2),{BackgroundColor3=Color3.fromRGB(24,24,27),TextColor3=Theme.TextMuted}):Play() end
            holder.Visible=true; bar.Visible=true; cScroll.CanvasSize=UDim2.new(0,0,0,lay.AbsoluteContentSize.Y)
            TweenService:Create(btn,TweenInfo.new(0.2),{BackgroundColor3=Theme.SecondaryBg,TextColor3=Theme.TextMain}):Play()
        end))
        table.insert(categories,{holder=holder,button=btn,bar=bar})
        return holder
    end

    -- ── Toggle ────────────────────────────────────────────────────────────────
    function uiData.CreateToggle(text, parent, callback, description, subConfig, descStyle)
        local container=Instance.new("Frame",parent); container.Size=UDim2.new(1,-4,0,42)
        container.BackgroundColor3=Theme.Background; container.LayoutOrder=nextOrder(S)
        Instance.new("UICorner",container).CornerRadius=UDim.new(0,8); Instance.new("UIStroke",container).Color=Theme.Border; trackObject(S,container)
        local tr=Instance.new("Frame",container); tr.Size=UDim2.new(1,0,0,42); tr.BackgroundTransparency=1; tr.LayoutOrder=1
        local lbl=Instance.new("TextLabel",tr); lbl.Size=UDim2.new(1,-60,1,0); lbl.Position=UDim2.new(0,14,0,0)
        lbl.BackgroundTransparency=1; lbl.Text=text; lbl.Font=Theme.FontMain; lbl.TextSize=13; lbl.TextColor3=Theme.TextMain; lbl.TextXAlignment=Enum.TextXAlignment.Left
        local sw=Instance.new("Frame",tr); sw.Size=UDim2.new(0,42,0,22); sw.Position=UDim2.new(1,-54,0.5,-11)
        sw.BackgroundColor3=Theme.SecondaryBg; Instance.new("UICorner",sw).CornerRadius=UDim.new(1,0); Instance.new("UIStroke",sw).Color=Theme.Border
        local kn=Instance.new("Frame",sw); kn.Size=UDim2.new(0,16,0,16); kn.Position=UDim2.new(0,3,0.5,-8)
        kn.BackgroundColor3=Theme.TextMuted; Instance.new("UICorner",kn).CornerRadius=UDim.new(1,0)
        local en=false
        local function updV(anim)
            local ti=TweenInfo.new(anim and 0.25 or 0,Enum.EasingStyle.Back,Enum.EasingDirection.Out); local bi=TweenInfo.new(anim and 0.2 or 0)
            if en then TweenService:Create(sw,bi,{BackgroundColor3=Theme.AccentGlow}):Play(); TweenService:Create(kn,ti,{Position=UDim2.new(1,-19,0.5,-8),BackgroundColor3=Theme.TextMain}):Play()
            else TweenService:Create(sw,bi,{BackgroundColor3=Theme.SecondaryBg}):Play(); TweenService:Create(kn,ti,{Position=UDim2.new(0,3,0.5,-8),BackgroundColor3=Theme.TextMuted}):Play() end
        end
        local tp; trackConnection(S,tr.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then tp=inp.Position end end))
        trackConnection(S,tr.InputEnded:Connect(function(inp)
            if (inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch) and tp then
                if (inp.Position-tp).Magnitude<8 then en=not en; updV(true); if callback then callback(en) end end; tp=nil end
        end))
        updV(false); applyFeatureExtensions(S,sg,container,description,subConfig,descStyle)
        local w=makeWidget(container)
        function w:SetValue(v) en=v; updV(true); if callback then callback(en) end end
        function w:GetValue() return en end
        return w
    end

    -- ── Button ────────────────────────────────────────────────────────────────
    function uiData.CreateButton(text, parent, callback, description, subConfig, descStyle)
        local container=Instance.new("Frame",parent); container.Size=UDim2.new(1,-4,0,40)
        container.BackgroundColor3=Theme.SecondaryBg; container.LayoutOrder=nextOrder(S)
        Instance.new("UICorner",container).CornerRadius=UDim.new(0,8)
        local bst=Instance.new("UIStroke",container); bst.Color=Theme.Border; trackObject(S,container)
        local btn=Instance.new("TextButton",container); btn.Size=UDim2.new(1,0,0,40); btn.Text=text
        btn.BackgroundTransparency=1; btn.TextColor3=Theme.TextMain; btn.Font=Theme.FontBold; btn.TextSize=13
        btn.AutoButtonColor=false; btn.LayoutOrder=1
        trackConnection(S,btn.MouseEnter:Connect(function() TweenService:Create(container,TweenInfo.new(0.2),{BackgroundColor3=Color3.fromRGB(30,30,37)}):Play(); TweenService:Create(bst,TweenInfo.new(0.2),{Color=Theme.AccentGlow}):Play() end))
        trackConnection(S,btn.MouseLeave:Connect(function() TweenService:Create(container,TweenInfo.new(0.2),{BackgroundColor3=Theme.SecondaryBg}):Play(); TweenService:Create(bst,TweenInfo.new(0.2),{Color=Theme.Border}):Play() end))
        trackConnection(S,btn.MouseButton1Click:Connect(function()
            local bd=TweenService:Create(btn,TweenInfo.new(0.08,Enum.EasingStyle.Quad),{Size=UDim2.new(1,0,0,36)})
            local bu=TweenService:Create(btn,TweenInfo.new(0.12,Enum.EasingStyle.Back),{Size=UDim2.new(1,0,0,40)}); bd:Play()
            local bc; bc=bd.Completed:Connect(function() bc:Disconnect(); bu:Play() end)
            if callback then callback() end
        end))
        applyFeatureExtensions(S,sg,container,description,subConfig,descStyle)
        local w=makeWidget(container)
        function w:SetText(t) btn.Text=t end; function w:GetText() return btn.Text end
        return w
    end

    -- ── Slider ────────────────────────────────────────────────────────────────
    function uiData.CreateSlider(text, parent, config, description, subConfig, descStyle)
        config=config or {}; config.Text=text
        local container=Instance.new("Frame",parent); container.Size=UDim2.new(1,-4,0,52)
        container.BackgroundColor3=Theme.Background; container.LayoutOrder=nextOrder(S)
        Instance.new("UICorner",container).CornerRadius=UDim.new(0,8); Instance.new("UIStroke",container).Color=Theme.Border; trackObject(S,container)
        local inner=Instance.new("Frame",container); inner.Size=UDim2.new(1,-28,1,0); inner.Position=UDim2.new(0,14,0,0)
        inner.BackgroundTransparency=1; inner.LayoutOrder=1
        local sb=buildSliderBody(S,inner,config,true)
        applyFeatureExtensions(S,sg,container,description,subConfig,descStyle)
        local w=makeWidget(container)
        function w:SetValue(v) sb.setValue(v) end
        function w:GetValue() return sb.getCurrentVal() end
        return w
    end

    -- ── Input ─────────────────────────────────────────────────────────────────
    function uiData.CreateInput(text, parent, config, description, subConfig, descStyle)
        config=config or {}
        local container=Instance.new("Frame",parent); container.Size=UDim2.new(1,-4,0,42)
        container.BackgroundColor3=Theme.Background; container.LayoutOrder=nextOrder(S)
        Instance.new("UICorner",container).CornerRadius=UDim.new(0,8); Instance.new("UIStroke",container).Color=Theme.Border; trackObject(S,container)
        local it=Instance.new("Frame",container); it.Size=UDim2.new(1,0,0,42); it.BackgroundTransparency=1; it.LayoutOrder=1
        local lbl=Instance.new("TextLabel",it); lbl.Size=UDim2.new(0,120,1,0); lbl.Position=UDim2.new(0,14,0,0)
        lbl.BackgroundTransparency=1; lbl.Text=text; lbl.TextColor3=Theme.TextMain; lbl.Font=Theme.FontMain; lbl.TextSize=13; lbl.TextXAlignment=Enum.TextXAlignment.Left
        local inT=config.InputType or "Any"; local mn=config.Min; local mx=config.Max
        local dv=config.Default or (inT=="Number" and 0 or "")
        local bx=Instance.new("TextBox",it); bx.Size=UDim2.new(1,-150,0,28); bx.Position=UDim2.new(0,136,0.5,-14)
        bx.BackgroundColor3=Theme.SecondaryBg; bx.Text=tostring(dv); bx.PlaceholderText=config.Placeholder or "Type here..."
        bx.PlaceholderColor3=Color3.fromRGB(100,100,105); bx.TextColor3=Theme.TextMain; bx.Font=Theme.FontMain; bx.TextSize=12; bx.ClearTextOnFocus=false
        Instance.new("UICorner",bx).CornerRadius=UDim.new(0,6); Instance.new("UIStroke",bx).Color=Theme.Border
        trackConnection(S,bx.FocusLost:Connect(function(ep)
            if inT=="Number" then local n=tonumber(bx.Text) or dv; if mn then n=math.max(mn,n) end; if mx then n=math.min(mx,n) end; bx.Text=tostring(n); if config.Callback then config.Callback(n,ep) end
            else if config.Callback then config.Callback(bx.Text,ep) end end
        end))
        applyFeatureExtensions(S,sg,container,description,subConfig,descStyle)
        local w=makeWidget(container)
        function w:SetValue(v) bx.Text=tostring(v); if config.Callback then config.Callback(v,false) end end
        function w:GetValue() return bx.Text end
        return w
    end

    -- ── Dropdown ──────────────────────────────────────────────────────────────
    function uiData.CreateDropdown(text, parent, config, description, subConfig, descStyle)
        config=config or {}
        local container=Instance.new("Frame",parent); container.Size=UDim2.new(1,-4,0,46)
        container.BackgroundColor3=Theme.Background; container.LayoutOrder=nextOrder(S)
        Instance.new("UICorner",container).CornerRadius=UDim.new(0,8); Instance.new("UIStroke",container).Color=Theme.Border; trackObject(S,container)
        local dt=Instance.new("Frame",container); dt.Size=UDim2.new(1,0,0,46); dt.BackgroundTransparency=1; dt.LayoutOrder=1
        local btn=Instance.new("TextButton",dt); btn.Size=UDim2.new(1,-20,0,32); btn.Position=UDim2.new(0,10,0.5,-16)
        btn.BackgroundColor3=Theme.SecondaryBg; btn.Text="  "..text..": "..tostring(config.Default or "---")
        btn.TextColor3=Theme.TextMain; btn.Font=Theme.FontMain; btn.TextSize=13; btn.TextXAlignment=Enum.TextXAlignment.Left
        Instance.new("UICorner",btn).CornerRadius=UDim.new(0,6); Instance.new("UIStroke",btn).Color=Theme.Border
        local arr=Instance.new("TextLabel",btn); arr.Size=UDim2.new(0,20,1,0); arr.Position=UDim2.new(1,-25,0,0)
        arr.BackgroundTransparency=1; arr.Text="▼"; arr.TextColor3=Theme.TextMuted; arr.Font=Theme.FontMain; arr.TextSize=12
        local sel=config.Default or "---"; local isOp=false
        trackConnection(S,btn.MouseButton1Click:Connect(function()
            if isOp then closeDropdownOverlay(sg); isOp=false; arr.Rotation=0
            else isOp=true; arr.Rotation=180
                openDropdownOverlay(S,sg,btn,config.Options or {},function(opt)
                    sel=opt; btn.Text="  "..text..": "..tostring(opt); isOp=false; arr.Rotation=0
                    if config.Callback then config.Callback(opt) end
                end) end
        end))
        applyFeatureExtensions(S,sg,container,description,subConfig,descStyle)
        local w=makeWidget(container)
        function w:SetValue(v) sel=v; btn.Text="  "..text..": "..tostring(v); if config.Callback then config.Callback(v) end end
        function w:GetValue() return sel end
        function w:SetOptions(opts) config.Options=opts end
        return w
    end

    -- ── MultiDropdown ─────────────────────────────────────────────────────────
    function uiData.CreateMultiDropdown(text, parent, config, description, subConfig, descStyle)
        config=config or {}; local sel={}
        if config.Default then for _,v in ipairs(config.Default) do sel[v]=true end end
        local container=Instance.new("Frame",parent); container.Size=UDim2.new(1,-4,0,46)
        container.BackgroundColor3=Theme.Background; container.LayoutOrder=nextOrder(S)
        Instance.new("UICorner",container).CornerRadius=UDim.new(0,8); Instance.new("UIStroke",container).Color=Theme.Border; trackObject(S,container)
        local dt=Instance.new("Frame",container); dt.Size=UDim2.new(1,0,0,46); dt.BackgroundTransparency=1; dt.LayoutOrder=1
        local function bldLbl() local k={}; for kk in pairs(sel) do table.insert(k,kk) end; return #k==0 and "  "..text..": ---" or "  "..text..": "..table.concat(k,", ") end
        local btn=Instance.new("TextButton",dt); btn.Size=UDim2.new(1,-20,0,32); btn.Position=UDim2.new(0,10,0.5,-16)
        btn.BackgroundColor3=Theme.SecondaryBg; btn.Text=bldLbl(); btn.TextColor3=Theme.TextMain; btn.Font=Theme.FontMain; btn.TextSize=13
        btn.TextXAlignment=Enum.TextXAlignment.Left; btn.TextTruncate=Enum.TextTruncate.AtEnd
        Instance.new("UICorner",btn).CornerRadius=UDim.new(0,6); Instance.new("UIStroke",btn).Color=Theme.Border
        local arr=Instance.new("TextLabel",btn); arr.Size=UDim2.new(0,20,1,0); arr.Position=UDim2.new(1,-25,0,0)
        arr.BackgroundTransparency=1; arr.Text="▼"; arr.TextColor3=Theme.TextMuted; arr.Font=Theme.FontMain; arr.TextSize=12
        local isOp=false
        local function openMOv()
            closeDropdownOverlay(sg)
            local ov=Instance.new("Frame",sg); ov.Name="__DropOverlay"; ov.BackgroundTransparency=1; ov.Size=UDim2.new(1,0,1,0); ov.ZIndex=3000
            local dim=Instance.new("TextButton",ov); dim.Size=UDim2.new(1,0,1,0); dim.BackgroundTransparency=1; dim.Text=""; dim.ZIndex=3000
            local abs2=btn.AbsolutePosition; local absS=btn.AbsoluteSize; local ROW=30; local opts=config.Options or {}
            local sc=Instance.new("ScrollingFrame",ov); sc.Size=UDim2.new(0,absS.X,0,math.min(#opts,5)*ROW)
            sc.Position=UDim2.new(0,abs2.X,0,abs2.Y+absS.Y+4); sc.BackgroundColor3=Theme.SecondaryBg
            sc.ScrollBarThickness=2; sc.CanvasSize=UDim2.new(0,0,0,#opts*ROW); sc.ZIndex=3001
            Instance.new("UICorner",sc).CornerRadius=UDim.new(0,6); Instance.new("UIStroke",sc).Color=Theme.AccentGlow
            local lay=Instance.new("UIListLayout",sc); lay.SortOrder=Enum.SortOrder.LayoutOrder
            local rbs={}
            local function refR() for on,rb in pairs(rbs) do rb.TextColor3=sel[on] and Theme.AccentGlow or Theme.TextMuted end end
            for i,opt in ipairs(opts) do
                local rb=Instance.new("TextButton",sc); rb.Size=UDim2.new(1,0,0,ROW); rb.Text="  "..tostring(opt)
                rb.BackgroundColor3=Theme.SecondaryBg; rb.TextColor3=sel[opt] and Theme.AccentGlow or Theme.TextMuted
                rb.Font=Theme.FontMain; rb.TextSize=12; rb.TextXAlignment=Enum.TextXAlignment.Left; rb.LayoutOrder=i; rb.ZIndex=3002
                rbs[opt]=rb
                trackConnection(S,rb.MouseButton1Click:Connect(function()
                    sel[opt]=not sel[opt] or nil; refR(); btn.Text=bldLbl()
                    local vals={}; for k in pairs(sel) do table.insert(vals,k) end
                    if config.Callback then config.Callback(vals) end
                end))
            end
            trackConnection(S,dim.MouseButton1Click:Connect(function() ov:Destroy(); isOp=false; arr.Rotation=0 end))
        end
        trackConnection(S,btn.MouseButton1Click:Connect(function()
            if isOp then closeDropdownOverlay(sg); isOp=false; arr.Rotation=0
            else isOp=true; arr.Rotation=180; openMOv() end
        end))
        applyFeatureExtensions(S,sg,container,description,subConfig,descStyle)
        local w=makeWidget(container)
        function w:SetValue(tbl) sel={}; for _,v in ipairs(tbl) do sel[v]=true end; btn.Text=bldLbl() end
        function w:GetValue() local v={}; for k in pairs(sel) do table.insert(v,k) end; return v end
        function w:SetOptions(opts) config.Options=opts end
        return w
    end

    -- ── ColorPicker ───────────────────────────────────────────────────────────
    function uiData.CreateColorPicker(text, parent, config, description, subConfig, descStyle)
        config=config or {}; local ac=config.Default or Color3.fromRGB(168,85,247)
        local container=Instance.new("Frame",parent); container.Size=UDim2.new(1,-4,0,42)
        container.BackgroundColor3=Theme.Background; container.LayoutOrder=nextOrder(S)
        Instance.new("UICorner",container).CornerRadius=UDim.new(0,8); Instance.new("UIStroke",container).Color=Theme.Border; trackObject(S,container)
        local row=Instance.new("Frame",container); row.Size=UDim2.new(1,0,0,42); row.BackgroundTransparency=1; row.LayoutOrder=1
        local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(1,-70,1,0); lbl.Position=UDim2.new(0,14,0,0)
        lbl.BackgroundTransparency=1; lbl.Text=text; lbl.TextColor3=Theme.TextMain; lbl.Font=Theme.FontMain; lbl.TextSize=13; lbl.TextXAlignment=Enum.TextXAlignment.Left
        local cb=Instance.new("TextButton",row); cb.Size=UDim2.new(0,42,0,22); cb.Position=UDim2.new(1,-56,0.5,-11)
        cb.BackgroundColor3=ac; cb.Text=""; Instance.new("UICorner",cb).CornerRadius=UDim.new(0,6); Instance.new("UIStroke",cb).Color=Theme.Border
        trackConnection(S,cb.MouseButton1Click:Connect(function()
            createColorPickerUI(S,sg,ac,function(c) ac=c; cb.BackgroundColor3=c; if config.Callback then config.Callback(c) end end)
        end))
        applyFeatureExtensions(S,sg,container,description,subConfig,descStyle)
        local w=makeWidget(container)
        function w:SetValue(c) ac=c; cb.BackgroundColor3=c; if config.Callback then config.Callback(c) end end
        function w:GetValue() return ac end
        return w
    end

    -- ── Label ─────────────────────────────────────────────────────────────────
    function uiData.CreateLabel(text, parent, config)
        config=config or {}
        local container=Instance.new("Frame",parent); container.Size=UDim2.new(1,-4,0,config.Height or 28)
        container.BackgroundTransparency=1; container.LayoutOrder=nextOrder(S); trackObject(S,container)
        local lbl=Instance.new("TextLabel",container); lbl.Size=UDim2.new(1,0,1,0); lbl.Position=UDim2.new(0,14,0,0)
        lbl.BackgroundTransparency=1; lbl.Text=text; lbl.TextColor3=config.Color or Theme.TextMuted
        lbl.Font=config.Bold and Theme.FontBold or Theme.FontMain; lbl.TextSize=config.TextSize or 12
        lbl.TextXAlignment=config.Align or Enum.TextXAlignment.Left; lbl.TextWrapped=true
        local w=makeWidget(container)
        function w:SetText(t) lbl.Text=t end; function w:GetText() return lbl.Text end; function w:SetColor(c) lbl.TextColor3=c end
        return w
    end

    -- ── Separator ─────────────────────────────────────────────────────────────
    function uiData.CreateSeparator(parent, config)
        config=config or {}; local h=config.Height or 1; local vp=config.Padding or 6
        local container=Instance.new("Frame",parent); container.Size=UDim2.new(1,-4,0,h+vp*2)
        container.BackgroundTransparency=1; container.LayoutOrder=nextOrder(S); trackObject(S,container)
        local line=Instance.new("Frame",container); line.Size=UDim2.new(1,-28,0,h); line.Position=UDim2.new(0,14,0.5,-math.floor(h/2))
        line.BackgroundColor3=config.Color or Theme.Border; line.BorderSizePixel=0
        Instance.new("UICorner",line).CornerRadius=UDim.new(1,0)
        if config.Label and config.Label~="" then
            line.Visible=false
            local bg=Instance.new("Frame",line); bg.AnchorPoint=Vector2.new(0.5,0.5); bg.Position=UDim2.new(0.5,0,0.5,0)
            bg.BackgroundColor3=Theme.SecondaryBg; bg.BorderSizePixel=0; bg.AutomaticSize=Enum.AutomaticSize.X; bg.Size=UDim2.new(0,4,1,8)
            local sl=Instance.new("TextLabel",bg); sl.AutomaticSize=Enum.AutomaticSize.X; sl.Size=UDim2.new(0,0,1,0)
            sl.BackgroundTransparency=1; sl.Text=" "..config.Label.." "; sl.TextColor3=config.LabelColor or Theme.TextMuted
            sl.Font=Theme.FontMain; sl.TextSize=config.LabelSize or 11
            task.defer(function() if line and line.Parent then line.Visible=true end end)
        end
        local w=makeWidget(container); function w:SetColor(c) line.BackgroundColor3=c end; return w
    end

    -- ── CreateList ────────────────────────────────────────────────────────────
    -- A generic selectable list. Options are provided by the caller.
    -- config = { Text, Options, Default, Callback, Action={Type,Text,Callback}, Description, subConfig, DescStyle }
    function uiData.CreateList(parent, config, description, subConfig, descStyle)
        config=config or {}
        local container=Instance.new("Frame",parent)
        container.BackgroundColor3=Theme.Background; container.LayoutOrder=nextOrder(S)
        Instance.new("UICorner",container).CornerRadius=UDim.new(0,8); Instance.new("UIStroke",container).Color=Theme.Border; trackObject(S,container)
        local lay=Instance.new("UIListLayout",container); lay.SortOrder=Enum.SortOrder.LayoutOrder; lay.Padding=UDim.new(0,0)

        local _, actionW, getSelected = buildListBody(S, sg, container, config.Text or "Select", false, config.Options or {}, config)
        applyFeatureExtensions(S, sg, container, description or config.Description, subConfig or config.subConfig, descStyle or config.DescStyle)

        local w=makeWidget(container)
        function w:GetSelected() return getSelected() end
        function w:SetOptions(opts) config.Options=opts end
        if actionW then
            function w:SetActionValue(v) actionW:SetValue(v) end
            function w:GetActionValue() return actionW:GetValue() end
        end
        return w
    end

    -- ── CreatePlayerList ──────────────────────────────────────────────────────
    -- Auto-populates with server players, removes on PlayerRemoving.
    -- config = { Text, Default, Callback, Action={Type,Text,Callback}, Description, subConfig, DescStyle }
    function uiData.CreatePlayerList(parent, config, description, subConfig, descStyle)
        config=config or {}
        -- backward compat: old signature was (parentFrame, callback)
        if type(config)=="function" then
            config={Callback=config}
        end
        local container=Instance.new("Frame",parent)
        container.BackgroundColor3=Theme.Background; container.LayoutOrder=nextOrder(S)
        Instance.new("UICorner",container).CornerRadius=UDim.new(0,8); Instance.new("UIStroke",container).Color=Theme.Border; trackObject(S,container)
        local lay=Instance.new("UIListLayout",container); lay.SortOrder=Enum.SortOrder.LayoutOrder; lay.Padding=UDim.new(0,0)

        local _, actionW, getSelected = buildListBody(S, sg, container, config.Text or "Player", true, {}, config)
        applyFeatureExtensions(S, sg, container, description or config.Description, subConfig or config.subConfig, descStyle or config.DescStyle)

        local w=makeWidget(container)
        function w:GetSelected() return getSelected() end
        if actionW then
            function w:SetActionValue(v) actionW:SetValue(v) end
            function w:GetActionValue() return actionW:GetValue() end
        end
        return w
    end

    -- ── misc ──────────────────────────────────────────────────────────────────
    local function openFirstCat()
        if #categories>0 then
            categories[1].holder.Visible=true; categories[1].bar.Visible=true
            categories[1].button.BackgroundColor3=Theme.SecondaryBg; categories[1].button.TextColor3=Theme.TextMain
            local l=categories[1].holder:FindFirstChildWhichIsA("UIListLayout")
            cScroll.CanvasSize=UDim2.new(0,0,0,l and l.AbsoluteContentSize.Y or 0)
        end
    end

    uiData.ScreenGui=sg; uiData.MainFrame=mf; uiData.MinimizedFrame=minF
    uiData.CategoryFrame=catFrame; uiData.ContentFrame=cScroll; uiData.Categories=categories
    uiData.SetMinimizedImage=setMinImg; uiData.OpenFirstCategory=openFirstCat
    uiData.Hide=function() toggleMin(true) end
    uiData.Show=function() toggleMin(false) end
    uiData.Close=function() doClose() end
    uiData.OnClose=function(cb) S.onCloseCallback=cb end

    module.CreateCategory      = uiData.CreateCategory
    module.CreateToggle        = uiData.CreateToggle
    module.CreateButton        = uiData.CreateButton
    module.CreateSlider        = uiData.CreateSlider
    module.CreateInput         = uiData.CreateInput
    module.CreateDropdown      = uiData.CreateDropdown
    module.CreateMultiDropdown = uiData.CreateMultiDropdown
    module.CreateColorPicker   = uiData.CreateColorPicker
    module.CreateLabel         = uiData.CreateLabel
    module.CreateSeparator     = uiData.CreateSeparator
    module.CreateList          = uiData.CreateList
    module.CreatePlayerList    = uiData.CreatePlayerList

    _activeInstance=uiData
    return uiData
end

return module
