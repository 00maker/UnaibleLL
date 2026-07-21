-- ============================================================
-- UnaibleLL - Client Visual Customization Suite v19
-- Place in StarterPlayerScripts or StarterGui
-- ============================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")
local TeleportService = game:GetService("TeleportService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

-- Try to grab the control module for clean freecam movement disable
local controlModule
task.spawn(function()
	pcall(function()
		local ps = player:WaitForChild("PlayerScripts", 10)
		if ps then controlModule = require(ps:WaitForChild("PlayerModule")) end
	end)
end)

local lockedFOV = 70
local fovLockEnabled = true
local targetWalkSpeed = 16
local targetJumpPower = 50
local targetGravity = 196
local jumpLock = false
local tpSpeed = 200
local godMode = false
local antiStun = false
local freecamActive = false
local shiftLockActive = false

local tracersEnabled = false
local chamsEnabled = false
local tracerObjects = {}
local chamObjects = {}
local itemChamsEnabled = false
local itemHighlights = {}

local jumpEffectEnabled = false
local jumpFxColor = Color3.fromRGB(88, 126, 255)
local footstepsEnabled = false
local footstepHue = 0
local auraAttachment = nil
local currentAuraStyle = nil

local rgbThemeEnabled = false
local screenGlowEnabled = false
local watermarkEnabled = false
local crosshairEnabled = false
local rgbCursorEnabled = false
local globalHue = 0

local STORE_FILE = "UnaibleLL_Store.json"
local Store = {autoload = nil, configs = {}, waypoints = {}}
local Config = {}
local keybinds = {}
local toggleList = {}
local toggleByName = {}
local controlAppliers = {}
local bindListening = nil
local updateHUD, refreshConfigList, refreshWaypoints
local searchRegistry = {}
local shiftLockToggleContainer = nil

local function registerSearchable(frame, label, parent)
	table.insert(searchRegistry, {frame = frame, label = string.lower(label), parent = parent})
end

local function canUseFiles() return writefile ~= nil and readfile ~= nil and isfile ~= nil end

local function saveStore()
	if not canUseFiles() then return end
	local ok, enc = pcall(function() return HttpService:JSONEncode(Store) end)
	if ok and enc then pcall(function() writefile(STORE_FILE, enc) end) end
end

local function loadStore()
	if not canUseFiles() then return end
	local ok = pcall(function() return isfile(STORE_FILE) end)
	if not ok or not isfile(STORE_FILE) then return end
	local ok2, content = pcall(function() return readfile(STORE_FILE) end)
	if not ok2 then return end
	local ok3, dec = pcall(function() return HttpService:JSONDecode(content) end)
	if ok3 and type(dec) == "table" then
		Store = dec
		Store.configs = Store.configs or {}
		Store.waypoints = Store.waypoints or {}
	end
end
loadStore()

local function snapshotConfig()
	local snap = {flags = {}, keybinds = {}}
	for k, v in pairs(Config) do snap.flags[k] = v end
	for name, key in pairs(keybinds) do snap.keybinds[name] = key.Name end
	return snap
end

local function applySnapshot(snap)
	if type(snap) ~= "table" then return end
	for flag, val in pairs(snap.flags or {}) do
		Config[flag] = val
		if controlAppliers[flag] then pcall(controlAppliers[flag], val) end
	end
	keybinds = {}
	for name, keyName in pairs(snap.keybinds or {}) do
		local ok, kc = pcall(function() return Enum.KeyCode[keyName] end)
		if ok and kc then keybinds[name] = kc end
	end
	for _, h in ipairs(toggleList) do h.updateBindText() end
	if updateHUD then updateHUD() end
end

local function saveConfigAs(name)
	if not name or name == "" then return false end
	Store.configs[name] = snapshotConfig()
	saveStore()
	if refreshConfigList then refreshConfigList() end
	return true
end

local function loadConfigNamed(name)
	if Store.configs[name] then applySnapshot(Store.configs[name]) end
end

local function deleteConfigNamed(name)
	Store.configs[name] = nil
	if Store.autoload == name then Store.autoload = nil end
	saveStore()
	if refreshConfigList then refreshConfigList() end
end

local function setAutoload(name)
	Store.autoload = (Store.autoload == name) and nil or name
	saveStore()
	if refreshConfigList then refreshConfigList() end
end

local COLORS = {
	BG_MAIN = Color3.fromRGB(243, 245, 251),
	BG_SIDEBAR = Color3.fromRGB(252, 253, 255),
	BG_CONTENT = Color3.fromRGB(247, 249, 253),
	BG_CARD = Color3.fromRGB(255, 255, 255),
	BG_HOVER = Color3.fromRGB(234, 239, 251),
	BG_TRACK = Color3.fromRGB(214, 219, 232),
	ACCENT = Color3.fromRGB(88, 126, 255),
	ACCENT_2 = Color3.fromRGB(150, 105, 255),
	ACCENT_GREEN = Color3.fromRGB(52, 199, 123),
	TEXT_PRIMARY = Color3.fromRGB(26, 31, 50),
	TEXT_SECONDARY = Color3.fromRGB(110, 118, 140),
	BORDER = Color3.fromRGB(224, 229, 242),
	TOPBAR = Color3.fromRGB(255, 255, 255),
	SCROLLBAR = Color3.fromRGB(188, 196, 216),
	DANGER = Color3.fromRGB(235, 78, 88),
}

local function create(className, props)
	local inst = Instance.new(className)
	for k, v in pairs(props) do
		if k ~= "Parent" then inst[k] = v end
	end
	if props.Parent then inst.Parent = props.Parent end
	return inst
end

local function smoothTween(obj, props, dur, style, dir)
	TweenService:Create(obj, TweenInfo.new(dur or 0.4, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props):Play()
end

local function addCorner(p, r) return create("UICorner", {CornerRadius = UDim.new(0, r or 10), Parent = p}) end
local function addStroke(p, c, th, tr) return create("UIStroke", {Color = c or COLORS.BORDER, Thickness = th or 1, Transparency = tr or 0, Parent = p}) end
local function addPadding(p, t, b, l, r) return create("UIPadding", {PaddingTop = UDim.new(0, t or 0), PaddingBottom = UDim.new(0, b or 0), PaddingLeft = UDim.new(0, l or 0), PaddingRight = UDim.new(0, r or 0), Parent = p}) end
local function addGradient(p, c1, c2, rot) return create("UIGradient", {Color = ColorSequence.new(c1, c2), Rotation = rot or 0, Parent = p}) end

local function hoverCard(container, stroke)
	container.MouseEnter:Connect(function() smoothTween(stroke, {Transparency = 0.1, Color = COLORS.ACCENT}, 0.25) end)
	container.MouseLeave:Connect(function() smoothTween(stroke, {Transparency = 0.5, Color = COLORS.BORDER}, 0.25) end)
end

local screenGui = create("ScreenGui", {Name = "UnaibleLL", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = playerGui})
local espGui = create("ScreenGui", {Name = "UnaibleLL_ESP", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 999, Parent = playerGui})
local overlayGui = create("ScreenGui", {Name = "UnaibleLL_Overlay", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 998, Parent = playerGui})

local mainFrame = create("Frame", {Name = "MainPanel", Size = UDim2.new(0, 760, 0, 520), Position = UDim2.new(0.5, -380, 0.5, -260), BackgroundColor3 = COLORS.BG_MAIN, BorderSizePixel = 0, ClipsDescendants = true, Visible = false, Parent = screenGui})
addCorner(mainFrame, 16)
local ms = addStroke(mainFrame, COLORS.ACCENT, 1.5, 0.15)
addGradient(ms, COLORS.ACCENT, COLORS.ACCENT_2, 90)
create("ImageLabel", {Name = "Shadow", Size = UDim2.new(1, 70, 1, 70), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Image = "rbxassetid://6014261993", ImageColor3 = Color3.fromRGB(50, 60, 100), ImageTransparency = 0.5, ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450), ZIndex = -1, Parent = mainFrame})

local topBar = create("Frame", {Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = COLORS.TOPBAR, BorderSizePixel = 0, Parent = mainFrame})
local al = create("Frame", {Size = UDim2.new(1, 0, 0, 3), BackgroundColor3 = COLORS.ACCENT, BorderSizePixel = 0, Parent = topBar})
local alGrad = addGradient(al, COLORS.ACCENT, COLORS.ACCENT_2, 0)
create("Frame", {Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = COLORS.BORDER, BorderSizePixel = 0, Parent = topBar})
local logoC = create("Frame", {Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(0, 16, 0.5, -15), BackgroundColor3 = COLORS.ACCENT, BorderSizePixel = 0, Parent = topBar})
addCorner(logoC, 8)
addGradient(logoC, COLORS.ACCENT, COLORS.ACCENT_2, 45)
create("TextLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "∞", TextColor3 = Color3.fromRGB(255,255,255), TextSize = 18, Font = Enum.Font.GothamBold, Parent = logoC})
create("TextLabel", {Size = UDim2.new(0, 120, 1, 0), Position = UDim2.new(0, 56, 0, 0), BackgroundTransparency = 1, Text = "UnaibleLL", TextColor3 = COLORS.TEXT_PRIMARY, TextSize = 17, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, Parent = topBar})
local bdg = create("TextLabel", {Size = UDim2.new(0, 36, 0, 18), Position = UDim2.new(0, 150, 0.5, -9), BackgroundColor3 = COLORS.ACCENT, BackgroundTransparency = 0.85, Text = "v19", TextColor3 = COLORS.ACCENT, TextSize = 10, Font = Enum.Font.GothamBold, Parent = topBar})
addCorner(bdg, 5)
local searchBox = create("TextBox", {Size = UDim2.new(0, 180, 0, 30), Position = UDim2.new(1, -196, 0.5, -15), BackgroundColor3 = COLORS.BG_CONTENT, BorderSizePixel = 0, Text = "", PlaceholderText = "🔍 Search...", PlaceholderColor3 = COLORS.TEXT_SECONDARY, TextColor3 = COLORS.TEXT_PRIMARY, TextSize = 12, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Parent = topBar})
addCorner(searchBox, 8)
addStroke(searchBox, COLORS.BORDER, 1, 0.4)
addPadding(searchBox, 0, 0, 10, 10)

local sidebarFrame = create("Frame", {Size = UDim2.new(0, 172, 1, -50), Position = UDim2.new(0, 0, 0, 50), BackgroundColor3 = COLORS.BG_SIDEBAR, BorderSizePixel = 0, ClipsDescendants = true, Parent = mainFrame})
create("Frame", {Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0), BackgroundColor3 = COLORS.BORDER, BackgroundTransparency = 0.4, BorderSizePixel = 0, Parent = sidebarFrame})
local sidebarInner = create("ScrollingFrame", {Size = UDim2.new(1, -18, 1, -66), Position = UDim2.new(0, 9, 0, 12), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = sidebarFrame})
create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = sidebarInner})
local ftr = create("Frame", {Size = UDim2.new(1, -18, 0, 44), Position = UDim2.new(0, 9, 1, -50), BackgroundColor3 = COLORS.BG_CARD, BorderSizePixel = 0, Parent = sidebarFrame})
addCorner(ftr, 10)
addStroke(ftr, COLORS.BORDER, 1, 0.5)
local avt = create("ImageLabel", {Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(0, 7, 0.5, -15), BackgroundColor3 = COLORS.BG_HOVER, BorderSizePixel = 0, Image = "rbxthumb://type=AvatarHeadShot&id="..player.UserId.."&w=48&h=48", Parent = ftr})
addCorner(avt, 15)
create("TextLabel", {Size = UDim2.new(1, -46, 1, 0), Position = UDim2.new(0, 44, 0, 0), BackgroundTransparency = 1, Text = player.DisplayName, TextColor3 = COLORS.TEXT_PRIMARY, TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = ftr})

local contentArea = create("Frame", {Size = UDim2.new(1, -172, 1, -50), Position = UDim2.new(0, 172, 0, 50), BackgroundColor3 = COLORS.BG_CONTENT, BorderSizePixel = 0, ClipsDescendants = true, Parent = mainFrame})

local allPages = {}
local allNavBtns = {}
local activeTab = nil

local function createPage(name)
	local page = create("ScrollingFrame", {Name = name, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = COLORS.SCROLLBAR, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, Parent = contentArea})
	addPadding(page, 18, 18, 20, 20)
	create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10), Parent = page})
	allPages[name] = page
	return page
end

local searchPage = create("ScrollingFrame", {Name = "Search", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, Parent = contentArea})
addPadding(searchPage, 18, 18, 20, 20)
create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10), Parent = searchPage})

local function switchToTab(name)
	if searchBox.Text ~= "" then searchBox.Text = "" end
	searchPage.Visible = false
	if activeTab == name then return end
	for _, p in pairs(allPages) do p.Visible = false end
	for _, info in pairs(allNavBtns) do
		info.accent.Visible = false
		info.label.TextColor3 = COLORS.TEXT_SECONDARY
		info.icon.TextColor3 = COLORS.TEXT_SECONDARY
		smoothTween(info.btn, {BackgroundTransparency = 1}, 0.25)
	end
	activeTab = name
	if allPages[name] then
		local pg = allPages[name]
		pg.Visible = true
		pg.Position = UDim2.new(0, 12, 0, 0)
		pg.GroupTransparency = nil
		smoothTween(pg, {Position = UDim2.new(0, 0, 0, 0)}, 0.4, Enum.EasingStyle.Quint)
	end
	if allNavBtns[name] then
		local info = allNavBtns[name]
		info.accent.Visible = true
		info.label.TextColor3 = COLORS.ACCENT
		info.icon.TextColor3 = COLORS.ACCENT
		smoothTween(info.btn, {BackgroundTransparency = 0}, 0.25)
		info.btn.BackgroundColor3 = COLORS.BG_HOVER
	end
end

local function createNavButton(icon, name, order)
	local btn = create("TextButton", {Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = COLORS.BG_HOVER, BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", LayoutOrder = order, AutoButtonColor = false, Parent = sidebarInner})
	addCorner(btn, 10)
	local accent = create("Frame", {Size = UDim2.new(0, 3, 0, 16), Position = UDim2.new(0, 2, 0.5, -8), BackgroundColor3 = COLORS.ACCENT, BorderSizePixel = 0, Visible = false, Parent = btn})
	addCorner(accent, 2)
	local iconLbl = create("TextLabel", {Size = UDim2.new(0, 22, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = icon, TextSize = 13, Font = Enum.Font.GothamBold, TextColor3 = COLORS.TEXT_SECONDARY, Parent = btn})
	local lbl = create("TextLabel", {Size = UDim2.new(1, -42, 1, 0), Position = UDim2.new(0, 38, 0, 0), BackgroundTransparency = 1, Text = name, TextSize = 12, Font = Enum.Font.GothamMedium, TextColor3 = COLORS.TEXT_SECONDARY, TextXAlignment = Enum.TextXAlignment.Left, Parent = btn})
	allNavBtns[name] = {btn = btn, accent = accent, label = lbl, icon = iconLbl}
	btn.MouseEnter:Connect(function() if activeTab ~= name then smoothTween(btn, {BackgroundTransparency = 0.5}, 0.15) end end)
	btn.MouseLeave:Connect(function() if activeTab ~= name then smoothTween(btn, {BackgroundTransparency = 1}, 0.15) end end)
	btn.MouseButton1Click:Connect(function() switchToTab(name) end)
end

local function applySearch(query)
	query = string.lower(query or "")
	if query:gsub("%s+", "") == "" then
		searchPage.Visible = false
		for _, e in ipairs(searchRegistry) do
			if e.frame.Parent ~= e.parent then e.frame.Parent = e.parent end
			e.frame.Visible = true
		end
		local t = activeTab or "Camera"
		activeTab = nil
		switchToTab(t)
		return
	end
	for _, pg in pairs(allPages) do pg.Visible = false end
	for _, info in pairs(allNavBtns) do
		info.accent.Visible = false
		info.btn.BackgroundTransparency = 1
	end
	activeTab = nil
	for _, e in ipairs(searchRegistry) do
		if string.find(e.label, query, 1, true) then
			e.frame.Parent = searchPage
			e.frame.Visible = true
		else
			if e.frame.Parent ~= e.parent then e.frame.Parent = e.parent end
			e.frame.Visible = false
		end
	end
	searchPage.Visible = true
end
searchBox:GetPropertyChangedSignal("Text"):Connect(function() applySearch(searchBox.Text) end)

local function createHeader(parent, text, order)
	create("TextLabel", {Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Text = text, TextColor3 = COLORS.TEXT_PRIMARY, TextSize = 14, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = order or 0, Parent = parent})
end

local function createSlider(parent, label, min, max, default, layoutOrder, callback, flag)
	local initial = (flag and Config[flag] ~= nil) and Config[flag] or default
	local container = create("Frame", {Size = UDim2.new(1, 0, 0, 60), BackgroundColor3 = COLORS.BG_CARD, BorderSizePixel = 0, LayoutOrder = layoutOrder, Parent = parent})
	addCorner(container, 10)
	local st = addStroke(container, COLORS.BORDER, 1, 0.5)
	hoverCard(container, st)
	create("TextLabel", {Size = UDim2.new(0.6, 0, 0, 20), Position = UDim2.new(0, 14, 0, 6), BackgroundTransparency = 1, Text = label, TextColor3 = COLORS.TEXT_PRIMARY, TextSize = 11, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left, Parent = container})
	local vb = create("Frame", {Size = UDim2.new(0, 48, 0, 18), Position = UDim2.new(1, -60, 0, 6), BackgroundColor3 = COLORS.BG_HOVER, BorderSizePixel = 0, Parent = container})
	addCorner(vb, 5)
	local vl = create("TextLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = tostring(initial), TextColor3 = COLORS.ACCENT, TextSize = 11, Font = Enum.Font.GothamBold, Parent = vb})
	local track = create("Frame", {Size = UDim2.new(1, -28, 0, 5), Position = UDim2.new(0, 14, 0, 40), BackgroundColor3 = COLORS.BG_TRACK, BorderSizePixel = 0, Parent = container})
	addCorner(track, 3)
	local initFill = math.clamp((initial - min) / (max - min), 0, 1)
	local fill = create("Frame", {Size = UDim2.new(initFill, 0, 1, 0), BackgroundColor3 = COLORS.ACCENT, BorderSizePixel = 0, Parent = track})
	addCorner(fill, 3)
	addGradient(fill, COLORS.ACCENT, COLORS.ACCENT_2, 0)
	local knob = create("Frame", {Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(initFill, -7, 0.5, -7), BackgroundColor3 = Color3.fromRGB(255,255,255), BorderSizePixel = 0, ZIndex = 2, Parent = track})
	addCorner(knob, 7)
	addStroke(knob, COLORS.ACCENT, 2, 0)
	local function setValue(val, fire)
		if (max - min) <= 10 then val = math.floor(val * 100 + 0.5) / 100 else val = math.floor(val + 0.5) end
		val = math.clamp(val, min, max)
		local dr = math.clamp((val - min) / (max - min), 0, 1)
		fill.Size = UDim2.new(dr, 0, 1, 0)
		knob.Position = UDim2.new(dr, -7, 0.5, -7)
		vl.Text = tostring(val)
		if flag then Config[flag] = val end
		if fire and callback then pcall(callback, val) end
	end
	local isDragging = false
	track.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then isDragging = true; local rel = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1); setValue(min + (max-min)*rel, true) end end)
	knob.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then isDragging = true end end)
	UserInputService.InputChanged:Connect(function(input) if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then local rel = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1); setValue(min + (max-min)*rel, true) end end)
	UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then isDragging = false end end)
	if flag then controlAppliers[flag] = function(v) setValue(v, true) end end
	if flag and Config[flag] ~= nil and callback then pcall(callback, initial) end
	registerSearchable(container, label, parent)
	return container
end

local function createToggle(parent, label, default, layoutOrder, callback, flag, bindable)
	if bindable == nil then bindable = true end
	local initial = (flag and Config[flag] ~= nil) and Config[flag] or default
	local container = create("Frame", {Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = COLORS.BG_CARD, BorderSizePixel = 0, LayoutOrder = layoutOrder, Parent = parent})
	addCorner(container, 10)
	local st = addStroke(container, COLORS.BORDER, 1, 0.5)
	hoverCard(container, st)
	create("TextLabel", {Size = UDim2.new(1, bindable and -126 or -66, 1, 0), Position = UDim2.new(0, 14, 0, 0), BackgroundTransparency = 1, Text = label, TextColor3 = COLORS.TEXT_PRIMARY, TextSize = 11, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left, Parent = container})
	local bindBtn = create("TextButton", {Size = UDim2.new(0, 44, 0, 24), Position = UDim2.new(1, -108, 0.5, -12), BackgroundColor3 = COLORS.BG_CONTENT, BorderSizePixel = 0, Text = "＋", TextColor3 = COLORS.TEXT_SECONDARY, TextSize = 10, Font = Enum.Font.GothamBold, AutoButtonColor = false, Visible = bindable, Parent = container})
	addCorner(bindBtn, 6)
	addStroke(bindBtn, COLORS.BORDER, 1, 0.5)
	local toggleBg = create("Frame", {Size = UDim2.new(0, 40, 0, 22), Position = UDim2.new(1, -54, 0.5, -11), BackgroundColor3 = initial and COLORS.ACCENT_GREEN or COLORS.BG_TRACK, BorderSizePixel = 0, Parent = container})
	addCorner(toggleBg, 11)
	local toggleKnob = create("Frame", {Size = UDim2.new(0, 16, 0, 16), Position = initial and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8), BackgroundColor3 = Color3.fromRGB(255,255,255), BorderSizePixel = 0, Parent = toggleBg})
	addCorner(toggleKnob, 8)
	local state = initial
	local handle = {name = label, bindable = bindable, container = container}
	handle.getState = function() return state end
	handle.setState = function(new, fire)
		state = new
		smoothTween(toggleBg, {BackgroundColor3 = state and COLORS.ACCENT_GREEN or COLORS.BG_TRACK}, 0.2)
		smoothTween(toggleKnob, {Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)}, 0.2, Enum.EasingStyle.Back)
		if flag then Config[flag] = state end
		if fire and callback then pcall(callback, state) end
		if updateHUD then updateHUD() end
	end
	handle.updateBindText = function()
		local key = keybinds[label]
		bindBtn.Text = key and key.Name or "＋"
		bindBtn.TextColor3 = key and COLORS.ACCENT or COLORS.TEXT_SECONDARY
	end
	local clickBtn = create("TextButton", {Size = UDim2.new(0, 56, 1, 0), Position = UDim2.new(1, -56, 0, 0), BackgroundTransparency = 1, Text = "", Parent = container})
	clickBtn.MouseButton1Click:Connect(function() handle.setState(not state, true) end)
	if bindable then
		bindBtn.MouseButton1Click:Connect(function() bindListening = handle; bindBtn.Text = "..."; bindBtn.TextColor3 = COLORS.ACCENT end)
	end
	if flag then controlAppliers[flag] = function(v) handle.setState(v, true) end end
	table.insert(toggleList, handle)
	toggleByName[label] = handle
	handle.updateBindText()
	if flag and Config[flag] ~= nil and state and callback then pcall(callback, state) end
	if updateHUD then updateHUD() end
	registerSearchable(container, label, parent)
	return handle
end

local function createButton(parent, label, layoutOrder, color, callback)
	local btn = create("TextButton", {Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = color or COLORS.ACCENT, BorderSizePixel = 0, Text = label, TextColor3 = Color3.fromRGB(255,255,255), TextSize = 12, Font = Enum.Font.GothamBold, LayoutOrder = layoutOrder, AutoButtonColor = false, Parent = parent})
	addCorner(btn, 10)
	btn.MouseEnter:Connect(function() smoothTween(btn, {BackgroundTransparency = 0.15}, 0.15) end)
	btn.MouseLeave:Connect(function() smoothTween(btn, {BackgroundTransparency = 0}, 0.15) end)
	btn.MouseButton1Click:Connect(function() if callback then callback() end end)
	return btn
end

local function createInput(parent, label, placeholder, layoutOrder, callback)
	local container = create("Frame", {Size = UDim2.new(1, 0, 0, 58), BackgroundColor3 = COLORS.BG_CARD, BorderSizePixel = 0, LayoutOrder = layoutOrder, Parent = parent})
	addCorner(container, 10)
	local st = addStroke(container, COLORS.BORDER, 1, 0.5)
	hoverCard(container, st)
	create("TextLabel", {Size = UDim2.new(1, -28, 0, 18), Position = UDim2.new(0, 14, 0, 5), BackgroundTransparency = 1, Text = label, TextColor3 = COLORS.TEXT_PRIMARY, TextSize = 11, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left, Parent = container})
	local box = create("TextBox", {Size = UDim2.new(1, -28, 0, 24), Position = UDim2.new(0, 14, 0, 26), BackgroundColor3 = COLORS.BG_CONTENT, BorderSizePixel = 0, Text = "", PlaceholderText = placeholder, PlaceholderColor3 = COLORS.TEXT_SECONDARY, TextColor3 = COLORS.TEXT_PRIMARY, TextSize = 11, Font = Enum.Font.Gotham, ClearTextOnFocus = false, Parent = container})
	addCorner(box, 6)
	addPadding(box, 0, 0, 8, 8)
	box.FocusLost:Connect(function(enter) if callback then callback(box.Text, enter) end end)
	return box
end

-- KEYBIND HUD
local hudFrame = create("Frame", {Name = "HUD", Size = UDim2.new(0, 200, 0, 220), Position = UDim2.new(0, 14, 0.5, -110), BackgroundColor3 = COLORS.BG_CARD, BackgroundTransparency = 0.05, BorderSizePixel = 0, Visible = false, Active = true, ZIndex = 150, Parent = screenGui})
addCorner(hudFrame, 10)
addStroke(hudFrame, COLORS.BORDER, 1, 0.4)
local hudH = create("Frame", {Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = COLORS.ACCENT, BorderSizePixel = 0, ZIndex = 151, Parent = hudFrame})
addCorner(hudH, 10)
addGradient(hudH, COLORS.ACCENT, COLORS.ACCENT_2, 0)
create("Frame", {Size = UDim2.new(1, 0, 0, 10), Position = UDim2.new(0, 0, 1, -10), BackgroundColor3 = COLORS.ACCENT, BorderSizePixel = 0, ZIndex = 151, Parent = hudH})
create("TextLabel", {Size = UDim2.new(1, -14, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = "Keybinds", TextColor3 = Color3.fromRGB(255,255,255), TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 152, Parent = hudH})
local hudList = create("ScrollingFrame", {Size = UDim2.new(1, -10, 1, -34), Position = UDim2.new(0, 5, 0, 32), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 151, Parent = hudFrame})
create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2), Parent = hudList})
do
	local d, ds, sp = false, nil, nil
	hudH.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = true; ds = i.Position; sp = hudFrame.Position end end)
	hudH.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = false end end)
	UserInputService.InputChanged:Connect(function(i) if d and i.UserInputType == Enum.UserInputType.MouseMovement then local delta = i.Position - ds; hudFrame.Position = UDim2.new(sp.X.Scale, sp.X.Offset + delta.X, sp.Y.Scale, sp.Y.Offset + delta.Y) end end)
end
updateHUD = function()
	if not hudFrame.Visible then return end
	for _, c in pairs(hudList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	local idx = 0
	for _, handle in ipairs(toggleList) do
		if handle.bindable then
			local key = keybinds[handle.name]
			if key then
				idx = idx + 1
				local on = handle.getState()
				local row = create("Frame", {Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, LayoutOrder = idx, ZIndex = 152, Parent = hudList})
				local dot = create("Frame", {Size = UDim2.new(0, 6, 0, 6), Position = UDim2.new(0, 2, 0.5, -3), BackgroundColor3 = on and COLORS.ACCENT_GREEN or COLORS.BG_TRACK, BorderSizePixel = 0, ZIndex = 153, Parent = row})
				addCorner(dot, 3)
				create("TextLabel", {Size = UDim2.new(1, -56, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = handle.name, TextColor3 = on and COLORS.TEXT_PRIMARY or COLORS.TEXT_SECONDARY, TextSize = 10, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 153, Parent = row})
				create("TextLabel", {Size = UDim2.new(0, 42, 1, 0), Position = UDim2.new(1, -44, 0, 0), BackgroundTransparency = 1, Text = "["..key.Name.."]", TextColor3 = COLORS.ACCENT, TextSize = 9, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 153, Parent = row})
			end
		end
	end
	if idx == 0 then
		create("TextLabel", {Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Text = "No keybinds set", TextColor3 = COLORS.TEXT_SECONDARY, TextSize = 10, Font = Enum.Font.Gotham, Parent = hudList})
	end
end

-- ============================================================
-- QUICK CONTROLS WIDGET (white, 0.5 transparent, scrolling, resizable, blue-knob sliders)
-- ============================================================
local qcFrame = create("Frame", {Name = "QuickControls", Size = UDim2.new(0, 230, 0, 160), Position = UDim2.new(1, -250, 0, 80), BackgroundColor3 = Color3.fromRGB(255,255,255), BackgroundTransparency = 0.5, BorderSizePixel = 0, Visible = false, Active = true, ClipsDescendants = true, ZIndex = 160, Parent = overlayGui})
addCorner(qcFrame, 12)
local qcStroke = addStroke(qcFrame, COLORS.ACCENT, 1.5, 0.2)
local qcHeader = create("Frame", {Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = Color3.fromRGB(255,255,255), BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 161, Parent = qcFrame})
addCorner(qcHeader, 12)
create("Frame", {Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 1, -12), BackgroundColor3 = Color3.fromRGB(255,255,255), BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 161, Parent = qcHeader})
create("TextLabel", {Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = "⚡ Quick Controls", TextColor3 = COLORS.TEXT_PRIMARY, TextSize = 11, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 162, Parent = qcHeader})
local qcScroll = create("ScrollingFrame", {Size = UDim2.new(1, -10, 1, -50), Position = UDim2.new(0, 5, 0, 32), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = COLORS.ACCENT, CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 161, Parent = qcFrame})
create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), Parent = qcScroll})

local function qcSlider(label, min, max, getVal, setVal, order)
	local row = create("Frame", {Size = UDim2.new(1, -4, 0, 44), BackgroundColor3 = Color3.fromRGB(255,255,255), BackgroundTransparency = 0.35, BorderSizePixel = 0, LayoutOrder = order, ZIndex = 162, Parent = qcScroll})
	addCorner(row, 8)
	create("TextLabel", {Size = UDim2.new(0.6, 0, 0, 16), Position = UDim2.new(0, 10, 0, 4), BackgroundTransparency = 1, Text = label, TextColor3 = COLORS.TEXT_PRIMARY, TextSize = 11, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 163, Parent = row})
	local valLbl = create("TextLabel", {Size = UDim2.new(0.35, 0, 0, 16), Position = UDim2.new(0.62, 0, 0, 4), BackgroundTransparency = 1, Text = tostring(getVal()), TextColor3 = COLORS.ACCENT, TextSize = 11, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 163, Parent = row})
	local track = create("Frame", {Size = UDim2.new(1, -20, 0, 5), Position = UDim2.new(0, 10, 0, 30), BackgroundColor3 = COLORS.BG_TRACK, BorderSizePixel = 0, ZIndex = 162, Parent = row})
	addCorner(track, 3)
	local ifill = math.clamp((getVal()-min)/(max-min),0,1)
	local fill = create("Frame", {Size = UDim2.new(ifill, 0, 1, 0), BackgroundColor3 = COLORS.ACCENT, BorderSizePixel = 0, ZIndex = 163, Parent = track})
	addCorner(fill, 3)
	addGradient(fill, COLORS.ACCENT, COLORS.ACCENT_2, 0)
	local knob = create("Frame", {Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(ifill, -7, 0.5, -7), BackgroundColor3 = Color3.fromRGB(255,255,255), BorderSizePixel = 0, ZIndex = 164, Parent = track})
	addCorner(knob, 7)
	addStroke(knob, COLORS.ACCENT, 2, 0)
	local dragging = false
	local function upd(x)
		local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		local v = math.floor(min + (max - min) * rel + 0.5)
		fill.Size = UDim2.new(rel, 0, 1, 0)
		knob.Position = UDim2.new(rel, -7, 0.5, -7)
		valLbl.Text = tostring(v)
		setVal(v)
	end
	track.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; upd(i.Position.X) end end)
	knob.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true end end)
	UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then upd(i.Position.X) end end)
	UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
	return {setDisplay = function()
		local rel = math.clamp((getVal()-min)/(max-min),0,1)
		valLbl.Text = tostring(getVal())
		fill.Size = UDim2.new(rel, 0, 1, 0)
		knob.Position = UDim2.new(rel, -7, 0.5, -7)
	end}
end

local qcSpeed = qcSlider("Speed", 16, 500, function() return targetWalkSpeed end, function(v)
	targetWalkSpeed = v
	local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if h then h.WalkSpeed = v end
	Config.walkspeed = v
	if controlAppliers.walkspeed then end
end, 1)
local qcJump = qcSlider("Jump", 50, 500, function() return targetJumpPower end, function(v)
	targetJumpPower = v
	jumpLock = true
	local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if h then h.UseJumpPower = true; h.JumpPower = v end
end, 2)
local qcGrav = qcSlider("Gravity", 0, 400, function() return targetGravity end, function(v)
	targetGravity = v
	workspace.Gravity = v
end, 3)

do
	local d, ds, sp = false, nil, nil
	qcHeader.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then d = true; ds = i.Position; sp = qcFrame.Position end end)
	qcHeader.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then d = false end end)
	UserInputService.InputChanged:Connect(function(i) if d and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local delta = i.Position - ds; qcFrame.Position = UDim2.new(sp.X.Scale, sp.X.Offset + delta.X, sp.Y.Scale, sp.Y.Offset + delta.Y) end end)
end
local qcResize = create("TextButton", {Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(1, -18, 1, -18), BackgroundColor3 = COLORS.ACCENT, BackgroundTransparency = 0.2, BorderSizePixel = 0, Text = "⤡", TextColor3 = Color3.fromRGB(255,255,255), TextSize = 11, Font = Enum.Font.GothamBold, AutoButtonColor = false, ZIndex = 165, Parent = qcFrame})
addCorner(qcResize, 5)
do
	local rz, rs, initSize = false, nil, nil
	qcResize.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then rz = true; rs = i.Position; initSize = qcFrame.AbsoluteSize end end)
	qcResize.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then rz = false end end)
	UserInputService.InputChanged:Connect(function(i)
		if rz and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local delta = i.Position - rs
			qcFrame.Size = UDim2.new(0, math.clamp(initSize.X + delta.X, 180, 420), 0, math.clamp(initSize.Y + delta.Y, 120, 400))
		end
	end)
end

-- NAV
createNavButton("🎥", "Camera", 1)
createNavButton("🌤️", "Environment", 2)
createNavButton("🌧️", "Weather", 3)
createNavButton("🎬", "Effects", 4)
createNavButton("✨", "FX", 5)
createNavButton("💃", "Emotes", 6)
createNavButton("👤", "Player", 7)
createNavButton("🎯", "Visuals", 8)
createNavButton("📡", "Server", 9)
createNavButton("👥", "Players", 10)
createNavButton("💾", "Configs", 11)
createNavButton("⚙️", "Settings", 12)

-- CAMERA
local camPage = createPage("Camera")
createHeader(camPage, "Camera Controls", 0)
createSlider(camPage, "Field of View", 30, 120, 70, 1, function(v) lockedFOV = v end, "fov")
createSlider(camPage, "Max Zoom Distance", 5, 400, 128, 2, function(v) player.CameraMaxZoomDistance = v end, "maxZoom")
createSlider(camPage, "Min Zoom Distance", 0.5, 20, 0.5, 3, function(v) player.CameraMinZoomDistance = v end, "minZoom")
local slHandle = createToggle(camPage, "Shift Lock", false, 4, function(s)
	shiftLockActive = s
	if not s then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum.AutoRotate = true end
	end
end, "shiftLock")
shiftLockToggleContainer = slHandle.container
createToggle(camPage, "Lock FOV", true, 5, function(s) fovLockEnabled = s; if s then lockedFOV = camera.FieldOfView end end, "fovLock")
local freecamCFrame, freecamSpeed = nil, 60
createToggle(camPage, "Freecam (WASD/QE + Mouse)", false, 6, function(state)
	if state then
		freecamActive = true
		-- Disable movement cleanly (no PlatformStand -> no anticheat trigger)
		if controlModule then pcall(function() controlModule:GetControls():Disable() end) end
		freecamCFrame = camera.CFrame
		camera.CameraType = Enum.CameraType.Scriptable
		fovLockEnabled = false
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		RunService:BindToRenderStep("UnaibleLL_Freecam", Enum.RenderPriority.Camera.Value + 1, function(dt)
			local md = UserInputService:GetMouseDelta()
			local pos = freecamCFrame.Position
			local rot = freecamCFrame - pos
			rot = CFrame.Angles(0, -md.X * 0.4 * dt, 0) * rot * CFrame.Angles(-md.Y * 0.4 * dt, 0, 0)
			local move = Vector3.new()
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + rot.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - rot.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - rot.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + rot.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.E) then move = move + Vector3.new(0,1,0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.Q) then move = move - Vector3.new(0,1,0) end
			local mult = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and 3 or 1
			pos = pos + move * freecamSpeed * mult * dt
			freecamCFrame = CFrame.new(pos) * rot
			camera.CFrame = freecamCFrame
		end)
	else
		freecamActive = false
		RunService:UnbindFromRenderStep("UnaibleLL_Freecam")
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		camera.CameraType = Enum.CameraType.Custom
		if controlModule then pcall(function() controlModule:GetControls():Enable() end) end
		local h = toggleByName["Lock FOV"]; if h then fovLockEnabled = h.getState() end
	end
end, "freecam")
createSlider(camPage, "Freecam Speed", 10, 300, 60, 7, function(v) freecamSpeed = v end, "freecamSpeed")

-- ENVIRONMENT
local envPage = createPage("Environment")
createHeader(envPage, "Lighting & Atmosphere", 0)
createSlider(envPage, "Time of Day", 0, 24, 14, 1, function(v) smoothTween(Lighting, {ClockTime = v}, 0.3) end, "clock")
createSlider(envPage, "Ambient Light", 0, 100, 50, 2, function(v) local m = v/100; Lighting.Ambient = Color3.fromRGB(m*150, m*150, m*160) end, "ambient")
createSlider(envPage, "Brightness", 0, 4, 2, 3, function(v) Lighting.Brightness = v end, "brightness")
createSlider(envPage, "Fog Distance", 0, 100, 0, 4, function(v) local fe = 10000 - (v/100)*9700; Lighting.FogEnd = fe; Lighting.FogStart = fe*0.05; Lighting.FogColor = Color3.fromRGB(200,205,215) end, "fog")
createSlider(envPage, "Exposure", -3, 3, 0, 5, function(v) Lighting.ExposureCompensation = v end, "exposure")
createToggle(envPage, "Global Shadows", true, 6, function(s) Lighting.GlobalShadows = s end, "shadows")
createToggle(envPage, "Fullbright", false, 7, function(s) if s then Lighting.Brightness = 3; Lighting.Ambient = Color3.fromRGB(178,178,178); Lighting.OutdoorAmbient = Color3.fromRGB(178,178,178) else Lighting.Ambient = Color3.fromRGB(70,70,78); Lighting.OutdoorAmbient = Color3.fromRGB(70,70,78) end end, "fullbright")
createButton(envPage, "Set to Midnight 🌙", 8, COLORS.ACCENT_2, function() smoothTween(Lighting, {ClockTime = 0}, 0.5) end)
createButton(envPage, "Set to Noon ☀️", 9, COLORS.ACCENT, function() smoothTween(Lighting, {ClockTime = 12}, 0.5) end)

-- WEATHER
local wthPage = createPage("Weather")
createHeader(wthPage, "Weather Effects", 0)
local weatherPart = Instance.new("Part")
weatherPart.Name = "UnaibleLL_WP"; weatherPart.Anchored = true; weatherPart.CanCollide = false; weatherPart.Transparency = 1; weatherPart.Size = Vector3.new(80,1,80); weatherPart.Parent = workspace
local rainEmitter = Instance.new("ParticleEmitter"); rainEmitter.Texture = "rbxassetid://5765221959"; rainEmitter.Color = ColorSequence.new(Color3.fromRGB(180,200,220)); rainEmitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.05),NumberSequenceKeypoint.new(1,0.03)}); rainEmitter.Lifetime = NumberRange.new(0.8,1.5); rainEmitter.Rate = 0; rainEmitter.Speed = NumberRange.new(60,80); rainEmitter.SpreadAngle = Vector2.new(5,5); rainEmitter.EmissionDirection = Enum.NormalId.Bottom; rainEmitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.3),NumberSequenceKeypoint.new(0.8,0.3),NumberSequenceKeypoint.new(1,1)}); rainEmitter.LightEmission = 0.1; rainEmitter.Parent = weatherPart
local snowEmitter = Instance.new("ParticleEmitter"); snowEmitter.Texture = "rbxassetid://241685484"; snowEmitter.Color = ColorSequence.new(Color3.fromRGB(255,255,255)); snowEmitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.15),NumberSequenceKeypoint.new(1,0.1)}); snowEmitter.Lifetime = NumberRange.new(3,6); snowEmitter.Rate = 0; snowEmitter.Speed = NumberRange.new(5,12); snowEmitter.SpreadAngle = Vector2.new(30,30); snowEmitter.EmissionDirection = Enum.NormalId.Bottom; snowEmitter.Rotation = NumberRange.new(0,360); snowEmitter.RotSpeed = NumberRange.new(-40,40); snowEmitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.1),NumberSequenceKeypoint.new(0.7,0.1),NumberSequenceKeypoint.new(1,1)}); snowEmitter.LightEmission = 0.2; snowEmitter.Parent = weatherPart
local dustEmitter = Instance.new("ParticleEmitter"); dustEmitter.Texture = "rbxassetid://241685484"; dustEmitter.Color = ColorSequence.new(Color3.fromRGB(180,160,100)); dustEmitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.08),NumberSequenceKeypoint.new(1,0.06)}); dustEmitter.Lifetime = NumberRange.new(4,8); dustEmitter.Rate = 0; dustEmitter.Speed = NumberRange.new(2,6); dustEmitter.SpreadAngle = Vector2.new(60,60); dustEmitter.EmissionDirection = Enum.NormalId.Left; dustEmitter.Rotation = NumberRange.new(0,360); dustEmitter.RotSpeed = NumberRange.new(-20,20); dustEmitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.2),NumberSequenceKeypoint.new(0.8,0.4),NumberSequenceKeypoint.new(1,1)}); dustEmitter.Parent = weatherPart
local rainActive, snowActive, dustActive, lightningActive = false, false, false, false
createToggle(wthPage, "Rain", false, 1, function(s) rainActive = s; if s then smoothTween(Lighting, {FogEnd = 800, FogStart = 10}, 1); Lighting.FogColor = Color3.fromRGB(140,148,160); rainEmitter.Rate = 300 else smoothTween(Lighting, {FogEnd = 10000, FogStart = 0}, 1); rainEmitter.Rate = 0 end end, "rain", false)
createSlider(wthPage, "Rain Intensity", 50, 800, 300, 2, function(v) if rainActive then rainEmitter.Rate = v end end, "rainRate")
createToggle(wthPage, "Snow", false, 3, function(s) snowActive = s; if s then smoothTween(Lighting, {FogEnd = 1200, FogStart = 20}, 1); Lighting.FogColor = Color3.fromRGB(220,225,235); snowEmitter.Rate = 150 else smoothTween(Lighting, {FogEnd = 10000, FogStart = 0}, 1); snowEmitter.Rate = 0 end end, "snow", false)
createSlider(wthPage, "Snow Intensity", 30, 500, 150, 4, function(v) if snowActive then snowEmitter.Rate = v end end, "snowRate")
createToggle(wthPage, "Dust / Leaves", false, 5, function(s) dustActive = s; dustEmitter.Rate = s and 50 or 0 end, "dust", false)
createToggle(wthPage, "Lightning Flashes", false, 6, function(s) lightningActive = s; if s then task.spawn(function() while lightningActive and rainActive do task.wait(math.random(3,8)); if not lightningActive or not rainActive then break end; local o = Lighting.Brightness; Lighting.Brightness = 6; task.wait(0.05); Lighting.Brightness = o; task.wait(0.1); Lighting.Brightness = 4; task.wait(0.05); Lighting.Brightness = o end end) end end, "lightning", false)
createSlider(wthPage, "Wind Strength", 0, 50, 10, 7, function(v) snowEmitter.SpreadAngle = Vector2.new(v,v); rainEmitter.SpreadAngle = Vector2.new(v*0.3, v*0.3); dustEmitter.Speed = NumberRange.new(v*0.5, v) end, "wind")

-- EFFECTS (now includes former Ghoul functions)
local fxPage = createPage("Effects")
createHeader(fxPage, "Screen Effects", 0)
local lbTop = create("Frame", {Size = UDim2.new(1,0,0,0), Position = UDim2.new(0,0,0,0), BackgroundColor3 = Color3.fromRGB(0,0,0), BorderSizePixel = 0, ZIndex = 100, Parent = overlayGui})
local lbBot = create("Frame", {Size = UDim2.new(1,0,0,0), Position = UDim2.new(0,0,1,0), AnchorPoint = Vector2.new(0,1), BackgroundColor3 = Color3.fromRGB(0,0,0), BorderSizePixel = 0, ZIndex = 100, Parent = overlayGui})
createSlider(fxPage, "Cinematic Bars %", 0, 20, 0, 1, function(v) local s = v/100; smoothTween(lbTop, {Size = UDim2.new(1,0,s,0)}, 0.3); smoothTween(lbBot, {Size = UDim2.new(1,0,s,0)}, 0.3) end, "bars")
local blurFX = Instance.new("BlurEffect"); blurFX.Size = 0; blurFX.Parent = Lighting
createSlider(fxPage, "Background Blur", 0, 24, 0, 2, function(v) smoothTween(blurFX, {Size = v}, 0.2) end, "blur")
local ccFX = Instance.new("ColorCorrectionEffect"); ccFX.Parent = Lighting
createSlider(fxPage, "Saturation", -100, 100, 0, 3, function(v) ccFX.Saturation = v/100 end, "sat")
createSlider(fxPage, "Contrast", -100, 100, 0, 4, function(v) ccFX.Contrast = v/100 end, "con")
createSlider(fxPage, "Tint R", 0, 255, 255, 5, function(v) ccFX.TintColor = Color3.fromRGB(v, ccFX.TintColor.G*255, ccFX.TintColor.B*255) end, "tintR")
createSlider(fxPage, "Tint G", 0, 255, 255, 6, function(v) ccFX.TintColor = Color3.fromRGB(ccFX.TintColor.R*255, v, ccFX.TintColor.B*255) end, "tintG")
createSlider(fxPage, "Tint B", 0, 255, 255, 7, function(v) ccFX.TintColor = Color3.fromRGB(ccFX.TintColor.R*255, ccFX.TintColor.G*255, v) end, "tintB")
local bloomFX = Instance.new("BloomEffect"); bloomFX.Intensity = 0; bloomFX.Size = 24; bloomFX.Threshold = 1; bloomFX.Parent = Lighting
createSlider(fxPage, "Bloom Intensity", 0, 100, 0, 8, function(v) bloomFX.Intensity = v/100; bloomFX.Threshold = 1 - (v/200) end, "bloom")
local sunFX = Instance.new("SunRaysEffect"); sunFX.Intensity = 0; sunFX.Spread = 0.5; sunFX.Parent = Lighting
createSlider(fxPage, "Sun Rays", 0, 100, 0, 9, function(v) sunFX.Intensity = v/100; sunFX.Spread = 0.2 + (v/100)*0.8 end, "sunrays")
local dofFX = Instance.new("DepthOfFieldEffect"); dofFX.FarIntensity = 0; dofFX.NearIntensity = 0; dofFX.FocusDistance = 20; dofFX.InFocusRadius = 15; dofFX.Enabled = false; dofFX.Parent = Lighting
createToggle(fxPage, "Depth of Field", false, 10, function(s) dofFX.Enabled = s; dofFX.FarIntensity = s and 0.5 or 0 end, "dof")

-- Former Ghoul functions merged here
createHeader(fxPage, "Client Visuals (zxc)", 11)
local glowFrames = {}
do
	local th = 3
	glowFrames.top = create("Frame", {Size = UDim2.new(1, 0, 0, th), Position = UDim2.new(0,0,0,0), BorderSizePixel = 0, BackgroundColor3 = COLORS.ACCENT, Visible = false, ZIndex = 90, Parent = overlayGui})
	glowFrames.bot = create("Frame", {Size = UDim2.new(1, 0, 0, th), Position = UDim2.new(0,0,1,-th), BorderSizePixel = 0, BackgroundColor3 = COLORS.ACCENT, Visible = false, ZIndex = 90, Parent = overlayGui})
	glowFrames.left = create("Frame", {Size = UDim2.new(0, th, 1, 0), Position = UDim2.new(0,0,0,0), BorderSizePixel = 0, BackgroundColor3 = COLORS.ACCENT, Visible = false, ZIndex = 90, Parent = overlayGui})
	glowFrames.right = create("Frame", {Size = UDim2.new(0, th, 1, 0), Position = UDim2.new(1,-th,0,0), BorderSizePixel = 0, BackgroundColor3 = COLORS.ACCENT, Visible = false, ZIndex = 90, Parent = overlayGui})
end
local crosshair = create("Frame", {Size = UDim2.new(0, 24, 0, 24), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 1, Visible = false, ZIndex = 130, Parent = overlayGui})
local chColor = Color3.fromRGB(0, 255, 120)
local chLines = {}
chLines.top = create("Frame", {Size = UDim2.new(0, 2, 0, 8), Position = UDim2.new(0.5, -1, 0, 0), BorderSizePixel = 0, BackgroundColor3 = chColor, ZIndex = 131, Parent = crosshair})
chLines.bot = create("Frame", {Size = UDim2.new(0, 2, 0, 8), Position = UDim2.new(0.5, -1, 1, -8), BorderSizePixel = 0, BackgroundColor3 = chColor, ZIndex = 131, Parent = crosshair})
chLines.left = create("Frame", {Size = UDim2.new(0, 8, 0, 2), Position = UDim2.new(0, 0, 0.5, -1), BorderSizePixel = 0, BackgroundColor3 = chColor, ZIndex = 131, Parent = crosshair})
chLines.right = create("Frame", {Size = UDim2.new(0, 8, 0, 2), Position = UDim2.new(1, -8, 0.5, -1), BorderSizePixel = 0, BackgroundColor3 = chColor, ZIndex = 131, Parent = crosshair})
local rgbCursor = create("Frame", {Size = UDim2.new(0, 10, 0, 10), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = COLORS.ACCENT, BorderSizePixel = 0, Visible = false, ZIndex = 140, Rotation = 45, Parent = overlayGui})
addStroke(rgbCursor, Color3.fromRGB(255,255,255), 1, 0)

createToggle(fxPage, "RGB Menu Theme", false, 12, function(s) rgbThemeEnabled = s end, "rgbTheme", false)
createToggle(fxPage, "RGB Screen Border", false, 13, function(s) screenGlowEnabled = s; for _, f in pairs(glowFrames) do f.Visible = s end end, "screenGlow", false)
createToggle(fxPage, "Crosshair", false, 14, function(s)
	crosshairEnabled = s
	crosshair.Visible = s
	-- hide shift lock toggle when crosshair on
	if shiftLockToggleContainer then shiftLockToggleContainer.Visible = not s end
end, "crosshair", false)
createSlider(fxPage, "Crosshair Hue", 0, 360, 130, 15, function(v) chColor = Color3.fromHSV(v/360, 0.9, 1); for _, l in pairs(chLines) do l.BackgroundColor3 = chColor end end, "crosshairHue")
createToggle(fxPage, "RGB Cursor", false, 16, function(s) rgbCursorEnabled = s; rgbCursor.Visible = s; UserInputService.MouseIconEnabled = not s end, "rgbCursor", false)

-- FX (player effects)
local function getHRP2() local c = player.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function clearAura() if auraAttachment then auraAttachment:Destroy(); auraAttachment = nil end end
local function buildAura(style)
	clearAura()
	local hrp = getHRP2()
	if not hrp then return end
	local att = Instance.new("Attachment"); att.Name = "UnaibleLL_Aura"; att.Parent = hrp
	local e = Instance.new("ParticleEmitter"); e.LightEmission = 0.7; e.LockedToPart = true
	if style == "Fire" then
		e.Color = ColorSequence.new(Color3.fromRGB(255,160,20), Color3.fromRGB(255,40,0)); e.Rate = 60; e.Speed = NumberRange.new(3,6); e.Lifetime = NumberRange.new(0.5,1); e.SpreadAngle = Vector2.new(25,25); e.EmissionDirection = Enum.NormalId.Top; e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.7), NumberSequenceKeypoint.new(1,0)})
	elseif style == "Rainbow" then
		e.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,0)),ColorSequenceKeypoint.new(0.2,Color3.fromRGB(255,255,0)),ColorSequenceKeypoint.new(0.4,Color3.fromRGB(0,255,0)),ColorSequenceKeypoint.new(0.6,Color3.fromRGB(0,255,255)),ColorSequenceKeypoint.new(0.8,Color3.fromRGB(0,0,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,0,255))}); e.Rate = 50; e.Speed = NumberRange.new(1,3); e.Lifetime = NumberRange.new(0.8,1.4); e.SpreadAngle = Vector2.new(180,180); e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.5), NumberSequenceKeypoint.new(1,0)})
	elseif style == "Galaxy" then
		e.Color = ColorSequence.new(Color3.fromRGB(150,100,255), Color3.fromRGB(60,90,255)); e.Rate = 70; e.Speed = NumberRange.new(0.5,2); e.Lifetime = NumberRange.new(1,2); e.SpreadAngle = Vector2.new(180,180); e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.3), NumberSequenceKeypoint.new(0.5,0.15), NumberSequenceKeypoint.new(1,0)}); e.Rotation = NumberRange.new(0,360); e.RotSpeed = NumberRange.new(-90,90)
	elseif style == "Holy" then
		e.Color = ColorSequence.new(Color3.fromRGB(255,245,180), Color3.fromRGB(255,255,255)); e.Rate = 45; e.Speed = NumberRange.new(2,4); e.Lifetime = NumberRange.new(0.8,1.5); e.SpreadAngle = Vector2.new(20,20); e.EmissionDirection = Enum.NormalId.Top; e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.6), NumberSequenceKeypoint.new(1,0)}); e.LightEmission = 1
	elseif style == "Shadow" then
		e.Color = ColorSequence.new(Color3.fromRGB(40,0,60), Color3.fromRGB(10,10,20)); e.Rate = 55; e.Speed = NumberRange.new(1,3); e.Lifetime = NumberRange.new(0.8,1.5); e.SpreadAngle = Vector2.new(180,180); e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.6), NumberSequenceKeypoint.new(1,0)}); e.LightEmission = 0
	end
	e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.2), NumberSequenceKeypoint.new(1,1)})
	e.Parent = att
	auraAttachment = att
	currentAuraStyle = style
end
local pfxPage = createPage("FX")
createHeader(pfxPage, "Player Effects", 0)
createToggle(pfxPage, "Jump Shockwave", false, 1, function(s) jumpEffectEnabled = s end, "jumpFx", false)
createSlider(pfxPage, "Jump FX Hue", 0, 360, 220, 2, function(v) jumpFxColor = Color3.fromHSV(v/360, 0.8, 1) end, "jumpHue")
createToggle(pfxPage, "Rainbow Footsteps", false, 3, function(s) footstepsEnabled = s end, "footsteps", false)
createHeader(pfxPage, "Aura Style", 4)
local auraToggles = {}
local function selectAura(name, state)
	if state then
		buildAura(name)
		for other, h in pairs(auraToggles) do if other ~= name then h.setState(false, false) end end
	else
		if currentAuraStyle == name then clearAura(); currentAuraStyle = nil end
	end
end
auraToggles["Fire"] = createToggle(pfxPage, "Fire Aura", false, 5, function(s) selectAura("Fire", s) end, "auraFire", false)
auraToggles["Rainbow"] = createToggle(pfxPage, "Rainbow Aura", false, 6, function(s) selectAura("Rainbow", s) end, "auraRainbow", false)
auraToggles["Galaxy"] = createToggle(pfxPage, "Galaxy Aura", false, 7, function(s) selectAura("Galaxy", s) end, "auraGalaxy", false)
auraToggles["Holy"] = createToggle(pfxPage, "Holy Aura", false, 8, function(s) selectAura("Holy", s) end, "auraHoly", false)
auraToggles["Shadow"] = createToggle(pfxPage, "Shadow Aura", false, 9, function(s) selectAura("Shadow", s) end, "auraShadow", false)

-- EMOTES
local emotePage = createPage("Emotes")
createHeader(emotePage, "Emote Player", 0)
local currentTrack, emoteLooped, emoteSpeed, currentAnimId = nil, false, 1, nil
local function getAnimator() local char = player.Character; if not char then return nil end; local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return nil end; local a = hum:FindFirstChildOfClass("Animator"); if not a then a = Instance.new("Animator"); a.Parent = hum end; return a end
local function playEmote(id) if not id or id == "" then return end; id = tostring(id):match("%d+"); if not id then return end; local a = getAnimator(); if not a then return end; if currentTrack then currentTrack:Stop(0.1) end; local anim = Instance.new("Animation"); anim.AnimationId = "rbxassetid://"..id; currentAnimId = id; local ok, t = pcall(function() return a:LoadAnimation(anim) end); if not ok then return end; currentTrack = t; t.Looped = emoteLooped; pcall(function() t.Priority = Enum.AnimationPriority.Action4 end); t:Play(0.15); t:AdjustSpeed(emoteSpeed) end
local function stopEmote() if currentTrack then currentTrack:Stop(0.15); currentTrack = nil end end
createInput(emotePage, "Custom Emote ID", "Animation ID (e.g. 507771019)", 1, function(t, e) if e and t ~= "" then playEmote(t) end end)
createToggle(emotePage, "Loop Emote", false, 2, function(s) emoteLooped = s; if currentTrack then currentTrack.Looped = s end end, "emoteLoop", false)
createSlider(emotePage, "Emote Speed", 0.1, 3, 1, 3, function(v) emoteSpeed = v; if currentTrack then currentTrack:AdjustSpeed(v) end end, "emoteSpeed")
createButton(emotePage, "⏹ Stop Emote", 4, COLORS.DANGER, stopEmote)
createHeader(emotePage, "Presets", 5)
for i, e in ipairs({{n="💃 Dance 1",id="507771019"},{n="🕺 Dance 2",id="507776043"},{n="🎉 Dance 3",id="507777268"},{n="👋 Wave",id="507770239"},{n="🙌 Cheer",id="507770677"},{n="😂 Laugh",id="507770818"}}) do
	createButton(emotePage, e.n, 5+i, COLORS.ACCENT, function() playEmote(e.id) end)
end
player.CharacterAdded:Connect(function() currentTrack = nil end)

-- PLAYER
local playerPage = createPage("Player")
createHeader(playerPage, "Player Modifiers", 0)
local function getHumanoid() local c = player.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function getHRP(c) c = c or player.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function teleportTo(cf) local hrp = getHRP(); if not hrp then return end; local d = (cf.Position - hrp.Position).Magnitude; if d < 100 then hrp.CFrame = cf; return end; TweenService:Create(hrp, TweenInfo.new(math.clamp(d/tpSpeed, 0.05, 3), Enum.EasingStyle.Linear), {CFrame = cf}):Play() end
local function applyGodMode(hum)
	if not hum then return end
	pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false) end)
	pcall(function() hum.BreakJointsOnDeath = false end)
	pcall(function() hum.RequiresNeck = false end)
	hum.Health = hum.MaxHealth
end
createSlider(playerPage, "Walk Speed", 16, 500, 16, 1, function(v) targetWalkSpeed = v; local h = getHumanoid(); if h then h.WalkSpeed = v end; qcSpeed.setDisplay() end, "walkspeed")
createSlider(playerPage, "Jump Power", 50, 500, 50, 2, function(v) targetJumpPower = v; local h = getHumanoid(); if h and jumpLock then h.UseJumpPower = true; h.JumpPower = v end; qcJump.setDisplay() end, "jumppower")
createToggle(playerPage, "Jump Lock", false, 3, function(s) jumpLock = s end, "jumpLockFlag")
createSlider(playerPage, "Gravity", 0, 400, 196, 4, function(v) targetGravity = v; workspace.Gravity = v; qcGrav.setDisplay() end, "gravity")
createToggle(playerPage, "Noclip", false, 5, function(s) if s then RunService:BindToRenderStep("Noclip", 1, function() local c = player.Character; if c then for _,p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end end) else RunService:UnbindFromRenderStep("Noclip") end end, "noclip")
createToggle(playerPage, "Infinite Jump", false, 6, function(s) if s and not _G.UnaibleLL_InfJump then _G.UnaibleLL_InfJump = true; UserInputService.JumpRequest:Connect(function() local h = toggleByName["Infinite Jump"]; if h and h.getState() then local hum = getHumanoid(); if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end end end) end end, "infjump")
createToggle(playerPage, "God Mode", false, 7, function(s) godMode = s; local hum = getHumanoid(); if hum then if s then applyGodMode(hum) else pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true) end) end end end, "godmode")
createToggle(playerPage, "Anti-Stun / Anti-Freeze", false, 8, function(s) antiStun = s end, "antistun")
createButton(playerPage, "Reset Character 🔄", 9, COLORS.DANGER, function() local c = player.Character; if c then local h = c:FindFirstChildOfClass("Humanoid"); if h then h:SetStateEnabled(Enum.HumanoidStateType.Dead, true); h.Health = 0 end end end)
createSlider(playerPage, "Teleport Speed", 20, 500, 200, 10, function(v) tpSpeed = v end, "tpSpeed")
createToggle(playerPage, "Quick Controls Widget", false, 11, function(s) qcFrame.Visible = s end, "qcWidget", false)
createHeader(playerPage, "Waypoints", 12)
local wpBox = createInput(playerPage, "Waypoint Name", "Name this spot, then Save", 13, nil)
createButton(playerPage, "📍 Save Current Position", 14, COLORS.ACCENT_GREEN, function() local hrp = getHRP(); if hrp and wpBox.Text ~= "" then Store.waypoints[wpBox.Text] = {hrp.Position.X, hrp.Position.Y, hrp.Position.Z}; saveStore(); wpBox.Text = ""; if refreshWaypoints then refreshWaypoints() end end end)
local wpHolder = create("Frame", {Size = UDim2.new(1,0,0,10), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 15, Parent = playerPage})
create("UIListLayout", {SortOrder = Enum.SortOrder.Name, Padding = UDim.new(0,5), Parent = wpHolder})
refreshWaypoints = function()
	for _,c in pairs(wpHolder:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	for name, pos in pairs(Store.waypoints) do
		local row = create("Frame", {Name = name, Size = UDim2.new(1,0,0,36), BackgroundColor3 = COLORS.BG_CARD, BorderSizePixel = 0, Parent = wpHolder})
		addCorner(row, 8); addStroke(row, COLORS.BORDER, 1, 0.5)
		create("TextLabel", {Size = UDim2.new(1,-110,1,0), Position = UDim2.new(0,12,0,0), BackgroundTransparency = 1, Text = "📍 "..name, TextColor3 = COLORS.TEXT_PRIMARY, TextSize = 11, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row})
		local tb = create("TextButton", {Size = UDim2.new(0,58,0,24), Position = UDim2.new(1,-104,0.5,-12), BackgroundColor3 = COLORS.ACCENT, BorderSizePixel = 0, Text = "Teleport", TextColor3 = Color3.fromRGB(255,255,255), TextSize = 9, Font = Enum.Font.GothamBold, AutoButtonColor = false, Parent = row})
		addCorner(tb, 6)
		tb.MouseButton1Click:Connect(function() teleportTo(CFrame.new(pos[1], pos[2]+3, pos[3])) end)
		local db = create("TextButton", {Size = UDim2.new(0,34,0,24), Position = UDim2.new(1,-40,0.5,-12), BackgroundColor3 = COLORS.DANGER, BorderSizePixel = 0, Text = "✕", TextColor3 = Color3.fromRGB(255,255,255), TextSize = 11, Font = Enum.Font.GothamBold, AutoButtonColor = false, Parent = row})
		addCorner(db, 6)
		db.MouseButton1Click:Connect(function() Store.waypoints[name] = nil; saveStore(); refreshWaypoints() end)
	end
end
player.CharacterAdded:Connect(function(char)
	local hum = char:WaitForChild("Humanoid", 5)
	if hum then
		hum.WalkSpeed = targetWalkSpeed
		if jumpLock then hum.UseJumpPower = true; hum.JumpPower = targetJumpPower end
		if godMode then applyGodMode(hum) end
		hum.HealthChanged:Connect(function() if godMode and hum and hum.Parent then hum.Health = hum.MaxHealth end end)
	end
	workspace.Gravity = targetGravity
	if currentAuraStyle then task.wait(0.4); buildAura(currentAuraStyle) end
end)

-- VISUALS
local visPage = createPage("Visuals")
createHeader(visPage, "Player ESP", 0)
local chamColor = Color3.fromRGB(88, 126, 255)
local function removeTracer(plr) if tracerObjects[plr] then tracerObjects[plr]:Destroy(); tracerObjects[plr] = nil end end
local function removeCham(plr) if chamObjects[plr] then chamObjects[plr]:Destroy(); chamObjects[plr] = nil end end
local function makeCham(plr)
	local char = plr.Character; if not char then return end
	local ex = chamObjects[plr]
	if ex and ex.Parent and ex.Adornee == char then return end
	if ex then ex:Destroy() end
	local hl = Instance.new("Highlight"); hl.FillColor = chamColor; hl.FillTransparency = 0.5; hl.OutlineColor = Color3.fromRGB(255,255,255); hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Adornee = char; hl.Parent = char
	chamObjects[plr] = hl
end
local function makeTracer(plr) if tracerObjects[plr] then return end; tracerObjects[plr] = create("Frame", {AnchorPoint = Vector2.new(0.5,0.5), BackgroundColor3 = chamColor, BorderSizePixel = 0, ZIndex = 10, Parent = espGui}) end
createToggle(visPage, "Tracers", false, 1, function(s) tracersEnabled = s; if not s then for p,_ in pairs(tracerObjects) do removeTracer(p) end end end, "tracers")
createToggle(visPage, "Player Chams", false, 2, function(s) chamsEnabled = s; if s then for _,p in ipairs(Players:GetPlayers()) do if p ~= player then makeCham(p) end end else for p,_ in pairs(chamObjects) do removeCham(p) end end end, "chams")
createSlider(visPage, "ESP Color (Hue)", 0, 360, 220, 3, function(v) chamColor = Color3.fromHSV(v/360, 0.7, 1); for _,hl in pairs(chamObjects) do hl.FillColor = chamColor end; for _,ln in pairs(tracerObjects) do ln.BackgroundColor3 = chamColor end end, "espHue")
createHeader(visPage, "Item ESP (YBA)", 4)
local YBA_ITEMS = {["Mysterious Arrow"]=true, ["Lucky Arrow"]=true, ["Rokakaka Fruit"]=true, ["Requiem Arrow"]=true, ["Rib Cage of The Saint's Corpse"]=true, ["Steel Ball"]=true, ["Stone Mask"]=true, ["Aja Mask"]=true, ["Diamond"]=true, ["Pure Rokakaka"]=true, ["Gold Coin"]=true, ["Diary"]=true, ["Half Stone Mask"]=true}
createToggle(visPage, "Item Chams", false, 5, function(s)
	itemChamsEnabled = s
	if not s then for _, hl in pairs(itemHighlights) do if hl and hl.Parent then hl:Destroy() end end; itemHighlights = {} end
end, "itemChams")
Players.PlayerRemoving:Connect(function(plr) removeTracer(plr); removeCham(plr) end)
Players.PlayerAdded:Connect(function(plr) plr.CharacterAdded:Connect(function() task.wait(0.5); if chamsEnabled and plr ~= player then makeCham(plr) end end) end)
for _, plr in ipairs(Players:GetPlayers()) do if plr ~= player then plr.CharacterAdded:Connect(function() task.wait(0.5); if chamsEnabled then makeCham(plr) end end) end end

-- Throttled item ESP scanner (fixes lag + detection)
task.spawn(function()
	while true do
		if itemChamsEnabled then
			for _, item in ipairs(workspace:GetDescendants()) do
				local nm = item.Name
				if (item:IsA("Model") or item:IsA("Tool") or item:IsA("BasePart")) and YBA_ITEMS[nm] and not itemHighlights[item] then
					local ok = pcall(function()
						local hl = Instance.new("Highlight")
						hl.FillColor = Color3.fromRGB(255, 215, 0)
						hl.FillTransparency = 0.25
						hl.OutlineColor = Color3.fromRGB(255, 255, 0)
						hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
						hl.Adornee = item
						hl.Parent = item
						itemHighlights[item] = hl
					end)
				end
			end
			for item, hl in pairs(itemHighlights) do
				if not item.Parent or not hl.Parent then
					if hl and hl.Parent then hl:Destroy() end
					itemHighlights[item] = nil
				end
			end
		end
		task.wait(1.5)
	end
end)

-- SERVER
local srvPage = createPage("Server")
createHeader(srvPage, "Server Info", 0)
local function infoCard(par, lbl, ord)
	local card = create("Frame", {Size = UDim2.new(1,0,0,50), BackgroundColor3 = COLORS.BG_CARD, BorderSizePixel = 0, LayoutOrder = ord, Parent = par}); addCorner(card, 10); addStroke(card, COLORS.BORDER, 1, 0.5)
	create("TextLabel", {Size = UDim2.new(1,-20,0,16), Position = UDim2.new(0,12,0,6), BackgroundTransparency = 1, Text = lbl, TextColor3 = COLORS.TEXT_SECONDARY, TextSize = 10, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left, Parent = card})
	return create("TextLabel", {Size = UDim2.new(1,-20,0,20), Position = UDim2.new(0,12,0,24), BackgroundTransparency = 1, Text = "...", TextColor3 = COLORS.TEXT_PRIMARY, TextSize = 14, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, Parent = card})
end
local pingV = infoCard(srvPage, "Ping (ms)", 1)
local plrsV = infoCard(srvPage, "Players in Server", 2)
local fpsV = infoCard(srvPage, "FPS", 3)
local ageV = infoCard(srvPage, "Session Time", 4)
createButton(srvPage, "🔄 Rejoin Server", 5, COLORS.ACCENT, function() pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player) end) end)
createButton(srvPage, "🎲 Server Hop", 6, COLORS.ACCENT_2, function() pcall(function() TeleportService:Teleport(game.PlaceId, player) end) end)
local sessionStart = tick()
local curFPS = 0
task.spawn(function()
	local fc, lt = 0, tick()
	RunService.RenderStepped:Connect(function() fc = fc + 1; if tick()-lt >= 1 then curFPS = fc; fc = 0; lt = tick() end end)
	while true do
		local ok, p = pcall(function() return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
		pingV.Text = ok and (p.." ms") or "N/A"
		plrsV.Text = #Players:GetPlayers().." / "..Players.MaxPlayers
		fpsV.Text = tostring(curFPS)
		local s = math.floor(tick()-sessionStart)
		ageV.Text = string.format("%02d:%02d:%02d", math.floor(s/3600), math.floor((s%3600)/60), s%60)
		task.wait(1)
	end
end)

-- PLAYERS
local plrPage = createPage("Players")
createHeader(plrPage, "Player List", 0)
local spectating = nil
local function stopSpectate()
	spectating = nil
	RunService:UnbindFromRenderStep("UnaibleLL_Spectate")
	camera.CameraType = Enum.CameraType.Custom
	local hum = getHumanoid()
	if hum then camera.CameraSubject = hum end
end
local function spectatePlayer(target)
	if not target or not target.Character then return end
	spectating = target
	camera.CameraType = Enum.CameraType.Scriptable
	RunService:BindToRenderStep("UnaibleLL_Spectate", Enum.RenderPriority.Camera.Value + 1, function()
		if not spectating or not spectating.Parent then stopSpectate(); return end
		local char = spectating.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local behind = hrp.CFrame * CFrame.new(0, 3, 12)
		camera.CFrame = CFrame.lookAt(behind.Position, hrp.Position + Vector3.new(0, 2, 0))
	end)
end
local plrHolder = create("Frame", {Size = UDim2.new(1,0,0,10), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1, Parent = plrPage})
create("UIListLayout", {SortOrder = Enum.SortOrder.Name, Padding = UDim.new(0,5), Parent = plrHolder})
createButton(plrPage, "⏹ Stop Spectating", 2, COLORS.DANGER, stopSpectate)
local function refreshPlayers()
	for _,c in pairs(plrHolder:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player then
			local row = create("Frame", {Name = plr.Name, Size = UDim2.new(1,0,0,42), BackgroundColor3 = COLORS.BG_CARD, BorderSizePixel = 0, Parent = plrHolder})
			addCorner(row, 10); addStroke(row, COLORS.BORDER, 1, 0.5)
			local pic = create("ImageLabel", {Size = UDim2.new(0,28,0,28), Position = UDim2.new(0,7,0.5,-14), BackgroundColor3 = COLORS.BG_HOVER, BorderSizePixel = 0, Image = "rbxthumb://type=AvatarHeadShot&id="..plr.UserId.."&w=48&h=48", Parent = row})
			addCorner(pic, 14)
			create("TextLabel", {Size = UDim2.new(1,-170,1,0), Position = UDim2.new(0,42,0,0), BackgroundTransparency = 1, Text = plr.DisplayName, TextColor3 = COLORS.TEXT_PRIMARY, TextSize = 11, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row})
			local tp = create("TextButton", {Size = UDim2.new(0,54,0,24), Position = UDim2.new(1,-118,0.5,-12), BackgroundColor3 = COLORS.ACCENT, BorderSizePixel = 0, Text = "Teleport", TextColor3 = Color3.fromRGB(255,255,255), TextSize = 9, Font = Enum.Font.GothamBold, AutoButtonColor = false, Parent = row})
			addCorner(tp, 6)
			tp.MouseButton1Click:Connect(function() local h = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart"); if h then teleportTo(h.CFrame * CFrame.new(0,0,3)) end end)
			local sp = create("TextButton", {Size = UDim2.new(0,54,0,24), Position = UDim2.new(1,-60,0.5,-12), BackgroundColor3 = COLORS.ACCENT_2, BorderSizePixel = 0, Text = "Spectate", TextColor3 = Color3.fromRGB(255,255,255), TextSize = 9, Font = Enum.Font.GothamBold, AutoButtonColor = false, Parent = row})
			addCorner(sp, 6)
			sp.MouseButton1Click:Connect(function() spectatePlayer(plr) end)
		end
	end
end
Players.PlayerAdded:Connect(function() task.wait(0.3); refreshPlayers() end)
Players.PlayerRemoving:Connect(function(plr) if spectating == plr then stopSpectate() end; task.wait(0.3); refreshPlayers() end)

-- CONFIGS
local cfgPage = createPage("Configs")
createHeader(cfgPage, "Save / Load Configs", 0)
local cfgBox = createInput(cfgPage, "Config Name", "Enter a name", 1, nil)
createButton(cfgPage, "💾 Save As New Config", 2, COLORS.ACCENT_GREEN, function() local n = cfgBox.Text; if n ~= "" then saveConfigAs(n); cfgBox.Text = "" end end)
createHeader(cfgPage, "Saved Configs", 3)
local cfgHolder = create("Frame", {Size = UDim2.new(1,0,0,10), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 4, Parent = cfgPage})
create("UIListLayout", {SortOrder = Enum.SortOrder.Name, Padding = UDim.new(0,5), Parent = cfgHolder})
refreshConfigList = function()
	for _,c in pairs(cfgHolder:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	for name, _ in pairs(Store.configs) do
		local isAuto = Store.autoload == name
		local row = create("Frame", {Name = name, Size = UDim2.new(1,0,0,36), BackgroundColor3 = COLORS.BG_CARD, BorderSizePixel = 0, Parent = cfgHolder})
		addCorner(row, 8); addStroke(row, isAuto and COLORS.ACCENT or COLORS.BORDER, 1, isAuto and 0 or 0.5)
		create("TextLabel", {Size = UDim2.new(1,-180,1,0), Position = UDim2.new(0,12,0,0), BackgroundTransparency = 1, Text = (isAuto and "★ " or "")..name, TextColor3 = COLORS.TEXT_PRIMARY, TextSize = 11, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row})
		local lb = create("TextButton", {Size = UDim2.new(0,44,0,22), Position = UDim2.new(1,-170,0.5,-11), BackgroundColor3 = COLORS.ACCENT, BorderSizePixel = 0, Text = "Load", TextColor3 = Color3.fromRGB(255,255,255), TextSize = 9, Font = Enum.Font.GothamBold, AutoButtonColor = false, Parent = row}); addCorner(lb, 5); lb.MouseButton1Click:Connect(function() loadConfigNamed(name) end)
		local ab = create("TextButton", {Size = UDim2.new(0,54,0,22), Position = UDim2.new(1,-120,0.5,-11), BackgroundColor3 = isAuto and COLORS.ACCENT_GREEN or COLORS.BG_CONTENT, BorderSizePixel = 0, Text = isAuto and "Auto ✓" or "Autoload", TextColor3 = isAuto and Color3.fromRGB(255,255,255) or COLORS.TEXT_SECONDARY, TextSize = 9, Font = Enum.Font.GothamBold, AutoButtonColor = false, Parent = row}); addCorner(ab, 5); ab.MouseButton1Click:Connect(function() setAutoload(name) end)
		local xb = create("TextButton", {Size = UDim2.new(0,30,0,22), Position = UDim2.new(1,-40,0.5,-11), BackgroundColor3 = COLORS.DANGER, BorderSizePixel = 0, Text = "✕", TextColor3 = Color3.fromRGB(255,255,255), TextSize = 10, Font = Enum.Font.GothamBold, AutoButtonColor = false, Parent = row}); addCorner(xb, 5); xb.MouseButton1Click:Connect(function() deleteConfigNamed(name) end)
	end
end

-- SETTINGS (watermark moved here)
local setPage = createPage("Settings")
createHeader(setPage, "UI Settings", 0)
createSlider(setPage, "GUI Transparency %", 0, 80, 0, 1, function(v) local t = v/100; mainFrame.BackgroundTransparency = t; topBar.BackgroundTransparency = t; sidebarFrame.BackgroundTransparency = t; contentArea.BackgroundTransparency = t end, "guiTrans")
createToggle(setPage, "Show Keybind HUD", false, 2, function(s) hudFrame.Visible = s; if s then updateHUD() end end, "showHUD")

-- Watermark (movable, controlled from settings)
local watermark = create("Frame", {Size = UDim2.new(0, 260, 0, 26), Position = UDim2.new(0, 10, 0, 6), BackgroundColor3 = Color3.fromRGB(15,15,20), BackgroundTransparency = 0.1, BorderSizePixel = 0, Visible = false, Active = true, ZIndex = 120, Parent = overlayGui})
addCorner(watermark, 6)
local wmStroke = addStroke(watermark, COLORS.ACCENT, 1.5, 0)
local wmAccent = create("Frame", {Size = UDim2.new(0, 3, 1, 0), Position = UDim2.new(0,0,0,0), BackgroundColor3 = COLORS.ACCENT, BorderSizePixel = 0, ZIndex = 121, Parent = watermark})
local wmText = create("TextLabel", {Size = UDim2.new(1, -14, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = "UnaibleLL", TextColor3 = Color3.fromRGB(235,235,245), TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 122, Parent = watermark})
do
	local d, ds, sp = false, nil, nil
	watermark.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then d = true; ds = i.Position; sp = watermark.Position end end)
	watermark.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then d = false end end)
	UserInputService.InputChanged:Connect(function(i) if d and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local delta = i.Position - ds; watermark.Position = UDim2.new(sp.X.Scale, sp.X.Offset + delta.X, sp.Y.Scale, sp.Y.Offset + delta.Y) end end)
end
createToggle(setPage, "Watermark (drag to move)", false, 3, function(s) watermarkEnabled = s; watermark.Visible = s end, "watermark", false)
createToggle(setPage, "Anti-AFK", false, 4, function(s) if s and not _G.UnaibleLL_AntiAFK then _G.UnaibleLL_AntiAFK = true; local vu = game:GetService("VirtualUser"); player.Idled:Connect(function() if toggleByName["Anti-AFK"] and toggleByName["Anti-AFK"].getState() then pcall(function() vu:Button2Down(Vector2.new(0,0), camera.CFrame); task.wait(1); vu:Button2Up(Vector2.new(0,0), camera.CFrame) end) end end) end end, "antiafk")

-- DRAGGING
local dragging, dragStart, startPos = false, nil, nil
topBar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = i.Position; startPos = mainFrame.Position end end)
topBar.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then local d = i.Position - dragStart; mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y) end end)

-- KEYBINDS
UserInputService.InputBegan:Connect(function(input, processed)
	if bindListening then
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.Escape then keybinds[bindListening.name] = nil else keybinds[bindListening.name] = input.KeyCode end
			bindListening.updateBindText(); bindListening = nil; saveStore()
			if updateHUD then updateHUD() end
			return
		end
	end
	if processed then return end
	for name, key in pairs(keybinds) do
		if input.KeyCode == key then
			local h = toggleByName[name]
			if h then h.setState(not h.getState(), true) end
		end
	end
end)

-- JUMP SHOCKWAVE
UserInputService.JumpRequest:Connect(function()
	if not jumpEffectEnabled then return end
	local hrp = getHRP2()
	if not hrp then return end
	local ring = Instance.new("Part")
	ring.Anchored = true; ring.CanCollide = false; ring.Material = Enum.Material.Neon; ring.Color = jumpFxColor
	ring.Shape = Enum.PartType.Cylinder; ring.Size = Vector3.new(0.3, 2, 2)
	ring.CFrame = CFrame.new(hrp.Position - Vector3.new(0, 2.8, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = workspace
	TweenService:Create(ring, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(0.3, 22, 22), Transparency = 1}):Play()
	Debris:AddItem(ring, 0.7)
end)

-- MAIN RENDER LOOP
RunService.RenderStepped:Connect(function()
	if workspace.CurrentCamera ~= camera then camera = workspace.CurrentCamera end
	if fovLockEnabled and camera.FieldOfView ~= lockedFOV then camera.FieldOfView = lockedFOV end
	if rainActive or snowActive or dustActive then weatherPart.CFrame = CFrame.new(camera.CFrame.Position + Vector3.new(0, 40, 0)) end

	-- shift lock (proper client implementation)
	if shiftLockActive and not freecamActive then
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hum and hrp then
			if not UserInputService:GetFocusedTextBox() then
				UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			end
			hum.AutoRotate = false
			local look = camera.CFrame.LookVector
			local flat = Vector3.new(look.X, 0, look.Z)
			if flat.Magnitude > 0.001 then
				flat = flat.Unit
				hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + flat)
			end
		end
	end

	globalHue = (globalHue + 0.004) % 1
	local rgb = Color3.fromHSV(globalHue, 0.8, 1)
	if rgbThemeEnabled then
		ms.Color = rgb
		alGrad.Color = ColorSequence.new(rgb, Color3.fromHSV((globalHue+0.15)%1, 0.8, 1))
	end
	if screenGlowEnabled then for _, f in pairs(glowFrames) do f.BackgroundColor3 = rgb end end
	if watermarkEnabled then
		wmStroke.Color = rgb
		wmAccent.BackgroundColor3 = rgb
		wmText.Text = "UnaibleLL  |  "..curFPS.." fps  |  "..player.DisplayName
	end
	if rgbCursorEnabled then
		local ml = UserInputService:GetMouseLocation()
		rgbCursor.Position = UDim2.fromOffset(ml.X, ml.Y)
		rgbCursor.BackgroundColor3 = rgb
	end

	if tracersEnabled then
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= player then
				local char = plr.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if hrp then
					local scp, onScreen = camera:WorldToViewportPoint(hrp.Position)
					if onScreen then
						if not tracerObjects[plr] then makeTracer(plr) end
						local ln = tracerObjects[plr]
						local vp = camera.ViewportSize
						local ox, oy = vp.X/2, vp.Y
						local dx, dy = scp.X - ox, scp.Y - oy
						local dist = math.sqrt(dx*dx + dy*dy)
						ln.Size = UDim2.fromOffset(2, dist)
						ln.Position = UDim2.fromOffset(ox + dx/2, oy + dy/2)
						ln.Rotation = math.deg(math.atan2(dy, dx)) - 90
						ln.Visible = true
					elseif tracerObjects[plr] then tracerObjects[plr].Visible = false end
				elseif tracerObjects[plr] then tracerObjects[plr].Visible = false end
			end
		end
	end

	if chamsEnabled then
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= player and plr.Character then
				local hl = chamObjects[plr]
				if not hl or not hl.Parent or hl.Adornee ~= plr.Character then makeCham(plr) end
			end
		end
	end

	if footstepsEnabled then
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.MoveDirection.Magnitude > 0.1 then
			footstepHue = (footstepHue + 0.02) % 1
			local part = Instance.new("Part")
			part.Size = Vector3.new(1.4, 0.15, 1.4)
			part.CFrame = CFrame.new(hrp.Position - Vector3.new(0, 2.9, 0))
			part.Anchored = true; part.CanCollide = false
			part.Color = Color3.fromHSV(footstepHue, 0.85, 1); part.Material = Enum.Material.Neon
			part.Shape = Enum.PartType.Cylinder; part.Orientation = Vector3.new(0, 0, 90)
			part.Parent = workspace
			TweenService:Create(part, TweenInfo.new(1), {Transparency = 1}):Play()
			Debris:AddItem(part, 1.1)
		end
	end
end)

-- HEARTBEAT ENFORCEMENT
RunService.Heartbeat:Connect(function()
	local char = player.Character
	local hum = getHumanoid()
	if hum then
		if godMode then hum.Health = hum.MaxHealth end
		if antiStun and not freecamActive and char then
			if hum.PlatformStand then hum.PlatformStand = false end
			if hum.Sit then hum.Sit = false end
			for _, d in ipairs(char:GetDescendants()) do
				if d:IsA("BasePart") then
					if d.Anchored then d.Anchored = false end
				elseif d:IsA("BodyVelocity") or d:IsA("BodyPosition") or d:IsA("BodyGyro") or d:IsA("BodyAngularVelocity") or d:IsA("AlignPosition") or d:IsA("AlignOrientation") or d:IsA("LinearVelocity") or d:IsA("AngularVelocity") then
					d:Destroy()
				end
			end
			if hum.WalkSpeed == 0 then hum.WalkSpeed = targetWalkSpeed end
		end
		if not hum.PlatformStand and not freecamActive then
			hum.WalkSpeed = targetWalkSpeed
			if jumpLock then hum.UseJumpPower = true; hum.JumpPower = targetJumpPower end
		end
	end
	if workspace.Gravity ~= targetGravity then workspace.Gravity = targetGravity end
end)

-- F1 TOGGLE (smoother)
local guiOpen = false
local function openGui()
	guiOpen = true
	mainFrame.Visible = true
	mainFrame.Size = UDim2.new(0, 200, 0, 140)
	mainFrame.Position = UDim2.new(0.5, -100, 0.5, -70)
	mainFrame.BackgroundTransparency = 1
	TweenService:Create(mainFrame, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, 760, 0, 520), Position = UDim2.new(0.5, -380, 0.5, -260), BackgroundTransparency = 0}):Play()
end
local function closeGui()
	guiOpen = false
	smoothTween(mainFrame, {Size = UDim2.new(0, 200, 0, 140), Position = UDim2.new(0.5, -100, 0.5, -70), BackgroundTransparency = 1}, 0.35)
	task.delay(0.4, function() if not guiOpen then mainFrame.Visible = false end end)
end
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.F1 then
		if guiOpen then closeGui() else openGui() end
	end
end)

-- INIT
switchToTab("Camera")
refreshConfigList()
refreshWaypoints()
refreshPlayers()
updateHUD()
if Store.autoload and Store.configs[Store.autoload] then
	task.defer(function() applySnapshot(Store.configs[Store.autoload]) end)
end
task.wait(0.5)
openGui()
