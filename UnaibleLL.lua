-- ============================================================
-- UnaibleLL - Client Visual Customization Suite v11
-- Configs | Keybinds | HUD | Search | Server info | Player list
-- Waypoints | Tracers | Chams | Always-on WalkSpeed/Gravity lock
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

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

-- FOV lock state
local lockedFOV = 70
local fovLockEnabled = true

-- Player enforcement state
local targetWalkSpeed = 16
local targetJumpPower = 50
local targetGravity = 196
local jumpLock = false

-- Visuals state
local tracersEnabled = false
local chamsEnabled = false
local tracerObjects = {}   -- player -> {line drawing/frame}
local chamObjects = {}     -- player -> Highlight

-- ============================================================
-- STATE: config store, keybinds, control registry, search
-- ============================================================
local STORE_FILE = "UnaibleLL_Store.json"
local Store = { autoload = nil, configs = {}, waypoints = {} }
local Config = {}
local keybinds = {}
local toggleList = {}
local toggleByName = {}
local controlAppliers = {}
local bindListening = nil
local updateHUD
local refreshConfigList
local refreshWaypoints
local searchRegistry = {}

local function registerSearchable(frame, label, parent)
	table.insert(searchRegistry, {frame = frame, label = string.lower(label), parent = parent})
end

-- ============================================================
-- FILE HELPERS
-- ============================================================
local function canUseFiles()
	return (writefile ~= nil) and (readfile ~= nil) and (isfile ~= nil)
end

local function saveStore()
	if not canUseFiles() then return false end
	local ok, enc = pcall(function() return HttpService:JSONEncode(Store) end)
	if ok and enc then
		pcall(function() writefile(STORE_FILE, enc) end)
		return true
	end
	return false
end

local function loadStore()
	if not canUseFiles() then return end
	local okExists = pcall(function() return isfile(STORE_FILE) end)
	if not okExists or not isfile(STORE_FILE) then return end
	local ok, content = pcall(function() return readfile(STORE_FILE) end)
	if not ok or not content then return end
	local ok2, dec = pcall(function() return HttpService:JSONDecode(content) end)
	if ok2 and type(dec) == "table" then
		Store = dec
		Store.configs = Store.configs or {}
		Store.waypoints = Store.waypoints or {}
	end
end

loadStore()

-- ============================================================
-- CONFIG SNAPSHOT / APPLY
-- ============================================================
local function snapshotConfig()
	local snap = { flags = {}, keybinds = {} }
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
	local snap = Store.configs[name]
	if snap then applySnapshot(snap) end
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

-- ============================================================
-- COLORS
-- ============================================================
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

local CONFIG = {
	DEFAULT_FOV = 70, MIN_FOV = 30, MAX_FOV = 120,
	DEFAULT_CLOCK = 14, MIN_CLOCK = 0, MAX_CLOCK = 24,
}

-- ============================================================
-- UTILITIES
-- ============================================================
local function create(className, props)
	local inst = Instance.new(className)
	for k, v in pairs(props) do
		if k ~= "Parent" then inst[k] = v end
	end
	if props.Parent then inst.Parent = props.Parent end
	return inst
end

local function smoothTween(obj, props, duration)
	local t = TweenService:Create(obj, TweenInfo.new(duration or 0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function addCorner(p, r) return create("UICorner", {CornerRadius = UDim.new(0, r or 10), Parent = p}) end
local function addStroke(p, c, th, tr) return create("UIStroke", {Color = c or COLORS.BORDER, Thickness = th or 1, Transparency = tr or 0, Parent = p}) end
local function addPadding(p, t, b, l, r)
	return create("UIPadding", {PaddingTop=UDim.new(0,t or 0), PaddingBottom=UDim.new(0,b or 0), PaddingLeft=UDim.new(0,l or 0), PaddingRight=UDim.new(0,r or 0), Parent=p})
end
local function addGradient(p, c1, c2, rot) return create("UIGradient", {Color = ColorSequence.new(c1, c2), Rotation = rot or 0, Parent = p}) end

-- ============================================================
-- SCREEN GUI
-- ============================================================
local screenGui = create("ScreenGui", {
	Name = "UnaibleLL",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = playerGui,
})

-- ============================================================
-- MAIN FRAME
-- ============================================================
local mainFrame = create("Frame", {
	Name = "MainPanel",
	Size = UDim2.new(0, 0, 0, 0),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	BackgroundColor3 = COLORS.BG_MAIN,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Parent = screenGui,
})
addCorner(mainFrame, 16)
local mainStroke = addStroke(mainFrame, COLORS.ACCENT, 1.5, 0.15)
addGradient(mainStroke, COLORS.ACCENT, COLORS.ACCENT_2, 90)

create("ImageLabel", {
	Name = "Shadow",
	Size = UDim2.new(1, 60, 1, 60),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundTransparency = 1,
	Image = "rbxassetid://6014261993",
	ImageColor3 = Color3.fromRGB(60, 70, 110),
	ImageTransparency = 0.55,
	ScaleType = Enum.ScaleType.Slice,
	SliceCenter = Rect.new(49, 49, 450, 450),
	ZIndex = -1,
	Parent = mainFrame,
})

-- ============================================================
-- TOP BAR
-- ============================================================
local topBar = create("Frame", {
	Name = "TopBar",
	Size = UDim2.new(1, 0, 0, 50),
	BackgroundColor3 = COLORS.TOPBAR,
	BorderSizePixel = 0,
	Parent = mainFrame,
})
local accentLine = create("Frame", {
	Size = UDim2.new(1, 0, 0, 3),
	Position = UDim2.new(0, 0, 0, 0),
	BorderSizePixel = 0,
	BackgroundColor3 = COLORS.ACCENT,
	Parent = topBar,
})
addGradient(accentLine, COLORS.ACCENT, COLORS.ACCENT_2, 0)
create("Frame", {
	Size = UDim2.new(1, 0, 0, 1),
	Position = UDim2.new(0, 0, 1, -1),
	BackgroundColor3 = COLORS.BORDER,
	BorderSizePixel = 0,
	Parent = topBar,
})
local logoCircle = create("Frame", {
	Size = UDim2.new(0, 30, 0, 30),
	Position = UDim2.new(0, 16, 0.5, -15),
	BackgroundColor3 = COLORS.ACCENT,
	BorderSizePixel = 0,
	Parent = topBar,
})
addCorner(logoCircle, 8)
addGradient(logoCircle, COLORS.ACCENT, COLORS.ACCENT_2, 45)
create("TextLabel", {
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Text = "∞",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 18,
	Font = Enum.Font.GothamBold,
	Parent = logoCircle,
})
create("TextLabel", {
	Size = UDim2.new(0, 120, 1, 0),
	Position = UDim2.new(0, 56, 0, 0),
	BackgroundTransparency = 1,
	Text = "UnaibleLL",
	TextColor3 = COLORS.TEXT_PRIMARY,
	TextSize = 17,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = topBar,
})
local badge = create("TextLabel", {
	Size = UDim2.new(0, 36, 0, 18),
	Position = UDim2.new(0, 150, 0.5, -9),
	BackgroundColor3 = COLORS.ACCENT,
	BackgroundTransparency = 0.85,
	Text = "v11",
	TextColor3 = COLORS.ACCENT,
	TextSize = 10,
	Font = Enum.Font.GothamBold,
	Parent = topBar,
})
addCorner(badge, 5)

-- Search box (top bar)
local searchBox = create("TextBox", {
	Size = UDim2.new(0, 210, 0, 30),
	Position = UDim2.new(1, -226, 0.5, -15),
	BackgroundColor3 = COLORS.BG_CONTENT,
	BorderSizePixel = 0,
	Text = "",
	PlaceholderText = "🔍 Search functions...",
	PlaceholderColor3 = COLORS.TEXT_SECONDARY,
	TextColor3 = COLORS.TEXT_PRIMARY,
	TextSize = 12,
	Font = Enum.Font.Gotham,
	TextXAlignment = Enum.TextXAlignment.Left,
	ClearTextOnFocus = false,
	Parent = topBar,
})
addCorner(searchBox, 8)
addStroke(searchBox, COLORS.BORDER, 1, 0.4)
addPadding(searchBox, 0, 0, 10, 10)

-- ============================================================
-- SIDEBAR
-- ============================================================
local sidebarFrame = create("Frame", {
	Name = "Sidebar",
	Size = UDim2.new(0, 172, 1, -50),
	Position = UDim2.new(0, 0, 0, 50),
	BackgroundColor3 = COLORS.BG_SIDEBAR,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Parent = mainFrame,
})
create("Frame", {
	Size = UDim2.new(0, 1, 1, 0),
	Position = UDim2.new(1, -1, 0, 0),
	BackgroundColor3 = COLORS.BORDER,
	BackgroundTransparency = 0.4,
	BorderSizePixel = 0,
	Parent = sidebarFrame,
})
local sidebarInner = create("ScrollingFrame", {
	Size = UDim2.new(1, -18, 1, -66),
	Position = UDim2.new(0, 9, 0, 12),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 0,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	Parent = sidebarFrame,
})
create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = sidebarInner})

-- Profile footer
local footer = create("Frame", {
	Size = UDim2.new(1, -18, 0, 44),
	Position = UDim2.new(0, 9, 1, -50),
	BackgroundColor3 = COLORS.BG_CARD,
	BorderSizePixel = 0,
	Parent = sidebarFrame,
})
addCorner(footer, 10)
addStroke(footer, COLORS.BORDER, 1, 0.5)
local avatar = create("ImageLabel", {
	Size = UDim2.new(0, 30, 0, 30),
	Position = UDim2.new(0, 7, 0.5, -15),
	BackgroundColor3 = COLORS.BG_HOVER,
	BorderSizePixel = 0,
	Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=48&h=48",
	Parent = footer,
})
addCorner(avatar, 15)
create("TextLabel", {
	Size = UDim2.new(1, -46, 1, 0),
	Position = UDim2.new(0, 44, 0, 0),
	BackgroundTransparency = 1,
	Text = player.DisplayName,
	TextColor3 = COLORS.TEXT_PRIMARY,
	TextSize = 12,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd,
	Parent = footer,
})

-- ============================================================
-- CONTENT AREA
-- ============================================================
local contentArea = create("Frame", {
	Name = "Content",
	Size = UDim2.new(1, -172, 1, -50),
	Position = UDim2.new(0, 172, 0, 50),
	BackgroundColor3 = COLORS.BG_CONTENT,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Parent = mainFrame,
})

-- ============================================================
-- TAB SYSTEM
-- ============================================================
local allPages = {}
local allNavBtns = {}
local activeTab = nil

local function createPage(name)
	local page = create("ScrollingFrame", {
		Name = name,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = COLORS.SCROLLBAR,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = contentArea,
	})
	addPadding(page, 18, 18, 20, 20)
	create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10), Parent = page})
	allPages[name] = page
	return page
end

-- Search results page
local searchPage = create("ScrollingFrame", {
	Name = "SearchResults",
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = COLORS.SCROLLBAR,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	Visible = false,
	Parent = contentArea,
})
addPadding(searchPage, 18, 18, 20, 20)
create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10), Parent = searchPage})

local function switchToTab(name)
	if searchBox.Text ~= "" then searchBox.Text = "" end
	searchPage.Visible = false
	if activeTab == name then return end
	for _, page in pairs(allPages) do page.Visible = false end
	for _, info in pairs(allNavBtns) do
		info.accent.Visible = false
		info.label.TextColor3 = COLORS.TEXT_SECONDARY
		info.icon.TextColor3 = COLORS.TEXT_SECONDARY
		smoothTween(info.btn, {BackgroundTransparency = 1}, 0.2)
	end
	activeTab = name
	if allPages[name] then
		local pg = allPages[name]
		pg.Visible = true
		pg.Position = UDim2.new(0, 0, 0, 8)
		smoothTween(pg, {Position = UDim2.new(0, 0, 0, 0)}, 0.35)
	end
	if allNavBtns[name] then
		local info = allNavBtns[name]
		info.accent.Visible = true
		info.label.TextColor3 = COLORS.ACCENT
		info.icon.TextColor3 = COLORS.ACCENT
		info.btn.BackgroundTransparency = 0
		info.btn.BackgroundColor3 = COLORS.BG_HOVER
	end
end

local function createNavButton(icon, name, order)
	local btn = create("TextButton", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = COLORS.BG_HOVER,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		LayoutOrder = order,
		AutoButtonColor = false,
		Parent = sidebarInner,
	})
	addCorner(btn, 10)
	local accent = create("Frame", {
		Size = UDim2.new(0, 3, 0, 18),
		Position = UDim2.new(0, 2, 0.5, -9),
		BackgroundColor3 = COLORS.ACCENT,
		BorderSizePixel = 0,
		Visible = false,
		Parent = btn,
	})
	addCorner(accent, 2)
	local iconLbl = create("TextLabel", {
		Size = UDim2.new(0, 24, 1, 0),
		Position = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text = icon,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		TextColor3 = COLORS.TEXT_SECONDARY,
		Parent = btn,
	})
	local lbl = create("TextLabel", {
		Size = UDim2.new(1, -48, 1, 0),
		Position = UDim2.new(0, 42, 0, 0),
		BackgroundTransparency = 1,
		Text = name,
		TextSize = 13,
		Font = Enum.Font.GothamMedium,
		TextColor3 = COLORS.TEXT_SECONDARY,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = btn,
	})
	allNavBtns[name] = {btn = btn, accent = accent, label = lbl, icon = iconLbl}
	btn.MouseEnter:Connect(function() if activeTab ~= name then smoothTween(btn, {BackgroundTransparency = 0.5}, 0.15) end end)
	btn.MouseLeave:Connect(function() if activeTab ~= name then smoothTween(btn, {BackgroundTransparency = 1}, 0.15) end end)
	btn.MouseButton1Click:Connect(function() switchToTab(name) end)
end

-- ============================================================
-- SEARCH FILTER
-- ============================================================
local function applySearch(query)
	query = string.lower((query or ""))
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
		info.label.TextColor3 = COLORS.TEXT_SECONDARY
		info.icon.TextColor3 = COLORS.TEXT_SECONDARY
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

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	applySearch(searchBox.Text)
end)

-- ============================================================
-- COMPONENTS
-- ============================================================
local function createHeader(parent, text, order)
	create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = COLORS.TEXT_PRIMARY,
		TextSize = 15,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = order or 0,
		Parent = parent,
	})
end

local function hoverCard(container, stroke)
	container.MouseEnter:Connect(function() smoothTween(stroke, {Transparency = 0.1, Color = COLORS.ACCENT}, 0.2) end)
	container.MouseLeave:Connect(function() smoothTween(stroke, {Transparency = 0.5, Color = COLORS.BORDER}, 0.2) end)
end

local function createSlider(parent, label, min, max, default, layoutOrder, callback, flag)
	local initial = default
	if flag and Config[flag] ~= nil then initial = Config[flag] end

	local container = create("Frame", {
		Size = UDim2.new(1, 0, 0, 64),
		BackgroundColor3 = COLORS.BG_CARD,
		BorderSizePixel = 0,
		LayoutOrder = layoutOrder,
		Parent = parent,
	})
	addCorner(container, 10)
	local st = addStroke(container, COLORS.BORDER, 1, 0.5)
	hoverCard(container, st)
	create("TextLabel", {
		Size = UDim2.new(0.6, 0, 0, 22),
		Position = UDim2.new(0, 16, 0, 8),
		BackgroundTransparency = 1,
		Text = label,
		TextColor3 = COLORS.TEXT_PRIMARY,
		TextSize = 12,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = container,
	})
	local valueBadge = create("Frame", {
		Size = UDim2.new(0, 52, 0, 20),
		Position = UDim2.new(1, -68, 0, 8),
		BackgroundColor3 = COLORS.BG_HOVER,
		BorderSizePixel = 0,
		Parent = container,
	})
	addCorner(valueBadge, 6)
	local valueLbl = create("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = tostring(initial),
		TextColor3 = COLORS.ACCENT,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		Parent = valueBadge,
	})
	local track = create("Frame", {
		Size = UDim2.new(1, -32, 0, 6),
		Position = UDim2.new(0, 16, 0, 44),
		BackgroundColor3 = COLORS.BG_TRACK,
		BorderSizePixel = 0,
		Parent = container,
	})
	addCorner(track, 3)
	local initFill = math.clamp((initial - min) / (max - min), 0, 1)
	local fill = create("Frame", {
		Size = UDim2.new(initFill, 0, 1, 0),
		BackgroundColor3 = COLORS.ACCENT,
		BorderSizePixel = 0,
		Parent = track,
	})
	addCorner(fill, 3)
	addGradient(fill, COLORS.ACCENT, COLORS.ACCENT_2, 0)
	local knob = create("Frame", {
		Size = UDim2.new(0, 16, 0, 16),
		Position = UDim2.new(initFill, -8, 0.5, -8),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = track,
	})
	addCorner(knob, 8)
	addStroke(knob, COLORS.ACCENT, 2, 0)

	local function setValue(val, fire)
		if (max - min) <= 10 then
			val = math.floor(val * 100 + 0.5) / 100
		else
			val = math.floor(val + 0.5)
		end
		val = math.clamp(val, min, max)
		local dr = math.clamp((val - min) / (max - min), 0, 1)
		smoothTween(fill, {Size = UDim2.new(dr, 0, 1, 0)}, 0.05)
		smoothTween(knob, {Position = UDim2.new(dr, -8, 0.5, -8)}, 0.05)
		valueLbl.Text = tostring(val)
		if flag then Config[flag] = val end
		if fire and callback then pcall(callback, val) end
	end

	local isDragging = false
	local function updateFromInput(inputX)
		local p = track.AbsolutePosition.X
		local s = track.AbsoluteSize.X
		local rel = math.clamp((inputX - p) / s, 0, 1)
		setValue(min + (max - min) * rel, true)
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = true
			updateFromInput(input.Position.X)
		end
	end)
	knob.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = true
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromInput(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = false
		end
	end)

	if flag then controlAppliers[flag] = function(v) setValue(v, true) end end
	if flag and Config[flag] ~= nil and callback then pcall(callback, initial) end
	registerSearchable(container, label, parent)
	return container
end

local function createToggle(parent, label, default, layoutOrder, callback, flag, bindable)
	if bindable == nil then bindable = true end
	local initial = default
	if flag and Config[flag] ~= nil then initial = Config[flag] end

	local container = create("Frame", {
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = COLORS.BG_CARD,
		BorderSizePixel = 0,
		LayoutOrder = layoutOrder,
		Parent = parent,
	})
	addCorner(container, 10)
	local st = addStroke(container, COLORS.BORDER, 1, 0.5)
	hoverCard(container, st)
	create("TextLabel", {
		Size = UDim2.new(1, bindable and -130 or -70, 1, 0),
		Position = UDim2.new(0, 16, 0, 0),
		BackgroundTransparency = 1,
		Text = label,
		TextColor3 = COLORS.TEXT_PRIMARY,
		TextSize = 12,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = container,
	})
	local bindBtn = create("TextButton", {
		Size = UDim2.new(0, 46, 0, 26),
		Position = UDim2.new(1, -112, 0.5, -13),
		BackgroundColor3 = COLORS.BG_CONTENT,
		BorderSizePixel = 0,
		Text = "＋",
		TextColor3 = COLORS.TEXT_SECONDARY,
		TextSize = 11,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = false,
		Visible = bindable,
		Parent = container,
	})
	addCorner(bindBtn, 6)
	addStroke(bindBtn, COLORS.BORDER, 1, 0.5)

	local toggleBg = create("Frame", {
		Size = UDim2.new(0, 42, 0, 24),
		Position = UDim2.new(1, -58, 0.5, -12),
		BackgroundColor3 = initial and COLORS.ACCENT_GREEN or COLORS.BG_TRACK,
		BorderSizePixel = 0,
		Parent = container,
	})
	addCorner(toggleBg, 12)
	local toggleKnob = create("Frame", {
		Size = UDim2.new(0, 18, 0, 18),
		Position = initial and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Parent = toggleBg,
	})
	addCorner(toggleKnob, 9)

	local state = initial
	local handle = { name = label, bindable = bindable }
	local function applyVisual()
		smoothTween(toggleBg, {BackgroundColor3 = state and COLORS.ACCENT_GREEN or COLORS.BG_TRACK}, 0.25)
		smoothTween(toggleKnob, {Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)}, 0.25)
	end
	handle.getState = function() return state end
	handle.setState = function(new, fire)
		state = new
		applyVisual()
		if flag then Config[flag] = state end
		if fire and callback then pcall(callback, state) end
		if updateHUD then updateHUD() end
	end
	handle.updateBindText = function()
		local key = keybinds[label]
		bindBtn.Text = key and key.Name or "＋"
		bindBtn.TextColor3 = key and COLORS.ACCENT or COLORS.TEXT_SECONDARY
	end

	local btn = create("TextButton", {
		Size = UDim2.new(0, 60, 1, 0),
		Position = UDim2.new(1, -60, 0, 0),
		BackgroundTransparency = 1,
		Text = "",
		Parent = container,
	})
	btn.MouseButton1Click:Connect(function() handle.setState(not state, true) end)
	bindBtn.MouseButton1Click:Connect(function()
		bindListening = handle
		bindBtn.Text = "..."
		bindBtn.TextColor3 = COLORS.ACCENT
	end)

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
	local btn = create("TextButton", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = color or COLORS.ACCENT,
		BorderSizePixel = 0,
		Text = label,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		LayoutOrder = layoutOrder,
		AutoButtonColor = false,
		Parent = parent,
	})
	addCorner(btn, 10)
	btn.MouseEnter:Connect(function() smoothTween(btn, {BackgroundTransparency = 0.15}, 0.15) end)
	btn.MouseLeave:Connect(function() smoothTween(btn, {BackgroundTransparency = 0}, 0.15) end)
	btn.MouseButton1Click:Connect(function() if callback then callback() end end)
	return btn
end

local function createInput(parent, label, placeholder, layoutOrder, callback)
	local container = create("Frame", {
		Size = UDim2.new(1, 0, 0, 62),
		BackgroundColor3 = COLORS.BG_CARD,
		BorderSizePixel = 0,
		LayoutOrder = layoutOrder,
		Parent = parent,
	})
	addCorner(container, 10)
	local st = addStroke(container, COLORS.BORDER, 1, 0.5)
	hoverCard(container, st)
	create("TextLabel", {
		Size = UDim2.new(1, -32, 0, 20),
		Position = UDim2.new(0, 16, 0, 6),
		BackgroundTransparency = 1,
		Text = label,
		TextColor3 = COLORS.TEXT_PRIMARY,
		TextSize = 12,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = container,
	})
	local box = create("TextBox", {
		Size = UDim2.new(1, -32, 0, 26),
		Position = UDim2.new(0, 16, 0, 28),
		BackgroundColor3 = COLORS.BG_CONTENT,
		BorderSizePixel = 0,
		Text = "",
		PlaceholderText = placeholder,
		PlaceholderColor3 = COLORS.TEXT_SECONDARY,
		TextColor3 = COLORS.TEXT_PRIMARY,
		TextSize = 12,
		Font = Enum.Font.Gotham,
		ClearTextOnFocus = false,
		Parent = container,
	})
	addCorner(box, 6)
	addPadding(box, 0, 0, 8, 8)
	box.FocusLost:Connect(function(enter) if callback then callback(box.Text, enter) end end)
	return box
end

-- ============================================================
-- FUNCTIONS HUD (bindable only)
-- ============================================================
local hudFrame = create("Frame", {
	Name = "FunctionsHUD",
	Size = UDim2.new(0, 210, 0, 240),
	Position = UDim2.new(0, 16, 0.5, -120),
	BackgroundColor3 = COLORS.BG_CARD,
	BackgroundTransparency = 0.05,
	BorderSizePixel = 0,
	Visible = false,
	Active = true,
	ZIndex = 150,
	Parent = screenGui,
})
addCorner(hudFrame, 10)
addStroke(hudFrame, COLORS.BORDER, 1, 0.4)
local hudHeader = create("Frame", {
	Size = UDim2.new(1, 0, 0, 30),
	BackgroundColor3 = COLORS.ACCENT,
	BorderSizePixel = 0,
	ZIndex = 151,
	Parent = hudFrame,
})
addCorner(hudHeader, 10)
addGradient(hudHeader, COLORS.ACCENT, COLORS.ACCENT_2, 0)
create("Frame", {
	Size = UDim2.new(1, 0, 0, 10),
	Position = UDim2.new(0, 0, 1, -10),
	BackgroundColor3 = COLORS.ACCENT,
	BorderSizePixel = 0,
	ZIndex = 151,
	Parent = hudHeader,
})
create("TextLabel", {
	Size = UDim2.new(1, -16, 1, 0),
	Position = UDim2.new(0, 12, 0, 0),
	BackgroundTransparency = 1,
	Text = "Functions",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 13,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 152,
	Parent = hudHeader,
})
local hudListF = create("ScrollingFrame", {
	Size = UDim2.new(1, -12, 1, -38),
	Position = UDim2.new(0, 6, 0, 34),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = COLORS.SCROLLBAR,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ZIndex = 151,
	Parent = hudFrame,
})
create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3), Parent = hudListF})

do
	local dragging, ds, sp = false, nil, nil
	hudHeader.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true; ds = input.Position; sp = hudFrame.Position
		end
	end)
	hudHeader.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - ds
			hudFrame.Position = UDim2.new(sp.X.Scale, sp.X.Offset + delta.X, sp.Y.Scale, sp.Y.Offset + delta.Y)
		end
	end)
end

updateHUD = function()
	if not hudFrame.Visible then return end
	for _, c in pairs(hudListF:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end
	local idx = 0
	for _, handle in ipairs(toggleList) do
		if handle.bindable then
			idx += 1
			local on = handle.getState()
			local row = create("Frame", {Size = UDim2.new(1, -4, 0, 22), BackgroundTransparency = 1, LayoutOrder = idx, ZIndex = 152, Parent = hudListF})
			local dot = create("Frame", {
				Size = UDim2.new(0, 8, 0, 8),
				Position = UDim2.new(0, 2, 0.5, -4),
				BackgroundColor3 = on and COLORS.ACCENT_GREEN or COLORS.BG_TRACK,
				BorderSizePixel = 0,
				ZIndex = 153,
				Parent = row,
			})
			addCorner(dot, 4)
			create("TextLabel", {
				Size = UDim2.new(1, -60, 1, 0),
				Position = UDim2.new(0, 16, 0, 0),
				BackgroundTransparency = 1,
				Text = handle.name,
				TextColor3 = on and COLORS.TEXT_PRIMARY or COLORS.TEXT_SECONDARY,
				TextSize = 11,
				Font = Enum.Font.GothamMedium,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 153,
				Parent = row,
			})
			local key = keybinds[handle.name]
			create("TextLabel", {
				Size = UDim2.new(0, 44, 1, 0),
				Position = UDim2.new(1, -46, 0, 0),
				BackgroundTransparency = 1,
				Text = key and ("[" .. key.Name .. "]") or "",
				TextColor3 = COLORS.ACCENT,
				TextSize = 10,
				Font = Enum.Font.GothamBold,
				TextXAlignment = Enum.TextXAlignment.Right,
				ZIndex = 153,
				Parent = row,
			})
		end
	end
	if idx == 0 then
		create("TextLabel", {
			Size = UDim2.new(1, -8, 0, 40),
			Position = UDim2.new(0, 4, 0, 0),
			BackgroundTransparency = 1,
			Text = "No active functions",
			TextColor3 = COLORS.TEXT_SECONDARY,
			TextSize = 11,
			Font = Enum.Font.Gotham,
			Parent = hudListF,
		})
	end
end

-- ============================================================
-- NAV BUTTONS
-- ============================================================
createNavButton("🎥", "Camera", 1)
createNavButton("🌤️", "Environment", 2)
createNavButton("🌧️", "Weather", 3)
createNavButton("🎬", "Effects", 4)
createNavButton("💃", "Emotes", 5)
createNavButton("👤", "Player", 6)
createNavButton("🎯", "Visuals", 7)
createNavButton("📡", "Server", 8)
createNavButton("👥", "Players", 9)
createNavButton("💾", "Configs", 10)
createNavButton("⚙️", "Settings", 11)

-- ============================================================
-- PAGE: CAMERA
-- ============================================================
local camPage = createPage("Camera")
createHeader(camPage, "Camera Controls", 0)
createSlider(camPage, "Field of View", CONFIG.MIN_FOV, CONFIG.MAX_FOV, CONFIG.DEFAULT_FOV, 1, function(v) lockedFOV = v end, "fov")
createSlider(camPage, "Max Zoom Distance", 5, 400, 128, 2, function(v) player.CameraMaxZoomDistance = v end, "maxZoom")
createSlider(camPage, "Min Zoom Distance", 0.5, 20, 0.5, 3, function(v) player.CameraMinZoomDistance = v end, "minZoom")
createToggle(camPage, "Shift Lock Enabled", false, 4, function(state) player.DevEnableMouseLock = state end, "shiftLock")
createToggle(camPage, "Lock FOV", true, 5, function(state)
	fovLockEnabled = state
	if state then lockedFOV = camera.FieldOfView end
end, "fovLock")
createToggle(camPage, "Freecam Mode (WASD + Q/E)", false, 6, function(state)
	if state then
		camera.CameraType = Enum.CameraType.Scriptable
		RunService:BindToRenderStep("Freecam", 200, function(dt)
			local move = Vector3.new()
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += camera.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= camera.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= camera.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += camera.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.E) then move += Vector3.new(0, 1, 0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.Q) then move -= Vector3.new(0, 1, 0) end
			camera.CFrame = camera.CFrame + move * (dt * 60)
		end)
	else
		RunService:UnbindFromRenderStep("Freecam")
		camera.CameraType = Enum.CameraType.Custom
	end
end, "freecam")

-- ============================================================
-- PAGE: ENVIRONMENT
-- ============================================================
local envPage = createPage("Environment")
createHeader(envPage, "Lighting & Atmosphere", 0)
createSlider(envPage, "Time of Day", CONFIG.MIN_CLOCK, CONFIG.MAX_CLOCK, CONFIG.DEFAULT_CLOCK, 1, function(v) smoothTween(Lighting, {ClockTime = v}, 0.3) end, "clock")
createSlider(envPage, "Ambient Light", 0, 100, 50, 2, function(v)
	local m = v / 100
	Lighting.Ambient = Color3.fromRGB(m * 150, m * 150, m * 160)
end, "ambient")
createSlider(envPage, "Brightness", 0, 4, 2, 3, function(v) Lighting.Brightness = v end, "brightness")
createSlider(envPage, "Fog Distance", 0, 100, 0, 4, function(v)
	local fogEnd = 10000 - (v / 100) * 9700
	Lighting.FogEnd = fogEnd
	Lighting.FogStart = fogEnd * 0.05
	Lighting.FogColor = Color3.fromRGB(200, 205, 215)
end, "fog")
createSlider(envPage, "Exposure", -3, 3, 0, 5, function(v) Lighting.ExposureCompensation = v end, "exposure")
createToggle(envPage, "Global Shadows", true, 6, function(state) Lighting.GlobalShadows = state end, "shadows")
createToggle(envPage, "Fullbright", false, 7, function(state)
	if state then
		Lighting.Brightness = 3
		Lighting.Ambient = Color3.fromRGB(178, 178, 178)
		Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
	else
		Lighting.Ambient = Color3.fromRGB(70, 70, 78)
		Lighting.OutdoorAmbient = Color3.fromRGB(70, 70, 78)
	end
end, "fullbright")
createButton(envPage, "Set to Midnight 🌙", 8, COLORS.ACCENT_2, function() smoothTween(Lighting, {ClockTime = 0}, 0.5) end)
createButton(envPage, "Set to Noon ☀️", 9, COLORS.ACCENT, function() smoothTween(Lighting, {ClockTime = 12}, 0.5) end)

-- ============================================================
-- PAGE: WEATHER
-- ============================================================
local wthPage = createPage("Weather")
createHeader(wthPage, "Weather Effects", 0)

local weatherPart = Instance.new("Part")
weatherPart.Name = "UnaibleLL_WP"
weatherPart.Anchored = true
weatherPart.CanCollide = false
weatherPart.Transparency = 1
weatherPart.Size = Vector3.new(80, 1, 80)
weatherPart.Parent = workspace

local rainEmitter = Instance.new("ParticleEmitter")
rainEmitter.Texture = "rbxassetid://5765221959"
rainEmitter.Color = ColorSequence.new(Color3.fromRGB(180, 200, 220))
rainEmitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(1, 0.03)})
rainEmitter.Lifetime = NumberRange.new(0.8, 1.5)
rainEmitter.Rate = 0
rainEmitter.Speed = NumberRange.new(60, 80)
rainEmitter.SpreadAngle = Vector2.new(5, 5)
rainEmitter.EmissionDirection = Enum.NormalId.Bottom
rainEmitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(0.8, 0.3), NumberSequenceKeypoint.new(1, 1)})
rainEmitter.LightEmission = 0.1
rainEmitter.Parent = weatherPart

local snowEmitter = Instance.new("ParticleEmitter")
snowEmitter.Texture = "rbxassetid://241685484"
snowEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
snowEmitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 0.1)})
snowEmitter.Lifetime = NumberRange.new(3, 6)
snowEmitter.Rate = 0
snowEmitter.Speed = NumberRange.new(5, 12)
snowEmitter.SpreadAngle = Vector2.new(30, 30)
snowEmitter.EmissionDirection = Enum.NormalId.Bottom
snowEmitter.Rotation = NumberRange.new(0, 360)
snowEmitter.RotSpeed = NumberRange.new(-40, 40)
snowEmitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.7, 0.1), NumberSequenceKeypoint.new(1, 1)})
snowEmitter.LightEmission = 0.2
snowEmitter.Parent = weatherPart

local dustEmitter = Instance.new("ParticleEmitter")
dustEmitter.Texture = "rbxassetid://241685484"
dustEmitter.Color = ColorSequence.new(Color3.fromRGB(180, 160, 100))
dustEmitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.08), NumberSequenceKeypoint.new(1, 0.06)})
dustEmitter.Lifetime = NumberRange.new(4, 8)
dustEmitter.Rate = 0
dustEmitter.Speed = NumberRange.new(2, 6)
dustEmitter.SpreadAngle = Vector2.new(60, 60)
dustEmitter.EmissionDirection = Enum.NormalId.Left
dustEmitter.Rotation = NumberRange.new(0, 360)
dustEmitter.RotSpeed = NumberRange.new(-20, 20)
dustEmitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.8, 0.4), NumberSequenceKeypoint.new(1, 1)})
dustEmitter.Parent = weatherPart

local rainActive, snowActive, dustActive, lightningActive = false, false, false, false

createToggle(wthPage, "Rain", false, 1, function(state)
	rainActive = state
	if state then
		smoothTween(Lighting, {FogEnd = 800, FogStart = 10}, 1)
		Lighting.FogColor = Color3.fromRGB(140, 148, 160)
		rainEmitter.Rate = 300
	else
		smoothTween(Lighting, {FogEnd = 10000, FogStart = 0}, 1)
		rainEmitter.Rate = 0
	end
end, "rain", false)
createSlider(wthPage, "Rain Intensity", 50, 800, 300, 2, function(v) if rainActive then rainEmitter.Rate = v end end, "rainRate")
createToggle(wthPage, "Snow", false, 3, function(state)
	snowActive = state
	if state then
		smoothTween(Lighting, {FogEnd = 1200, FogStart = 20}, 1)
		Lighting.FogColor = Color3.fromRGB(220, 225, 235)
		snowEmitter.Rate = 150
	else
		smoothTween(Lighting, {FogEnd = 10000, FogStart = 0}, 1)
		snowEmitter.Rate = 0
	end
end, "snow", false)
createSlider(wthPage, "Snow Intensity", 30, 500, 150, 4, function(v) if snowActive then snowEmitter.Rate = v end end, "snowRate")
createToggle(wthPage, "Dust / Leaves", false, 5, function(state) dustActive = state; dustEmitter.Rate = state and 50 or 0 end, "dust", false)
createToggle(wthPage, "Lightning Flashes", false, 6, function(state)
	lightningActive = state
	if state then
		task.spawn(function()
			while lightningActive and rainActive do
				task.wait(math.random(3, 8))
				if not lightningActive or not rainActive then break end
				local orig = Lighting.Brightness
				Lighting.Brightness = 6; task.wait(0.05)
				Lighting.Brightness = orig; task.wait(0.1)
				Lighting.Brightness = 4; task.wait(0.05)
				Lighting.Brightness = orig
			end
		end)
	end
end, "lightning", false)
createSlider(wthPage, "Wind Strength", 0, 50, 10, 7, function(v)
	snowEmitter.SpreadAngle = Vector2.new(v, v)
	rainEmitter.SpreadAngle = Vector2.new(v * 0.3, v * 0.3)
	dustEmitter.Speed = NumberRange.new(v * 0.5, v)
end, "wind")

-- ============================================================
-- PAGE: EFFECTS
-- ============================================================
local fxPage = createPage("Effects")
createHeader(fxPage, "Screen Effects", 0)
local letterboxTop = create("Frame", {Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 0, 0), BackgroundColor3 = Color3.fromRGB(0,0,0), BorderSizePixel = 0, ZIndex = 100, Parent = screenGui})
local letterboxBot = create("Frame", {Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 1, 0), AnchorPoint = Vector2.new(0, 1), BackgroundColor3 = Color3.fromRGB(0,0,0), BorderSizePixel = 0, ZIndex = 100, Parent = screenGui})
createSlider(fxPage, "Cinematic Bars %", 0, 20, 0, 1, function(v)
	local s = v / 100
	smoothTween(letterboxTop, {Size = UDim2.new(1, 0, s, 0)}, 0.3)
	smoothTween(letterboxBot, {Size = UDim2.new(1, 0, s, 0)}, 0.3)
end, "bars")
local blurEffect = Instance.new("BlurEffect"); blurEffect.Size = 0; blurEffect.Parent = Lighting
createSlider(fxPage, "Background Blur", 0, 24, 0, 2, function(v) smoothTween(blurEffect, {Size = v}, 0.2) end, "blur")
local cc = Instance.new("ColorCorrectionEffect"); cc.Parent = Lighting
createSlider(fxPage, "Saturation", -100, 100, 0, 3, function(v) cc.Saturation = v / 100 end, "sat")
createSlider(fxPage, "Contrast", -100, 100, 0, 4, function(v) cc.Contrast = v / 100 end, "con")
createSlider(fxPage, "Tint R", 0, 255, 255, 5, function(v) cc.TintColor = Color3.fromRGB(v, cc.TintColor.G * 255, cc.TintColor.B * 255) end, "tintR")
createSlider(fxPage, "Tint G", 0, 255, 255, 6, function(v) cc.TintColor = Color3.fromRGB(cc.TintColor.R * 255, v, cc.TintColor.B * 255) end, "tintG")
createSlider(fxPage, "Tint B", 0, 255, 255, 7, function(v) cc.TintColor = Color3.fromRGB(cc.TintColor.R * 255, cc.TintColor.G * 255, v) end, "tintB")
local bloom = Instance.new("BloomEffect"); bloom.Intensity = 0; bloom.Size = 24; bloom.Threshold = 1; bloom.Parent = Lighting
createSlider(fxPage, "Bloom Intensity", 0, 100, 0, 8, function(v) bloom.Intensity = v / 100; bloom.Threshold = 1 - (v / 200) end, "bloom")
local sunRays = Instance.new("SunRaysEffect"); sunRays.Intensity = 0; sunRays.Spread = 0.5; sunRays.Parent = Lighting
createSlider(fxPage, "Sun Rays", 0, 100, 0, 9, function(v) sunRays.Intensity = v / 100; sunRays.Spread = 0.2 + (v / 100) * 0.8 end, "sunrays")
local dof = Instance.new("DepthOfFieldEffect"); dof.FarIntensity = 0; dof.NearIntensity = 0; dof.FocusDistance = 20; dof.InFocusRadius = 15; dof.Enabled = false; dof.Parent = Lighting
createToggle(fxPage, "Depth of Field", false, 10, function(state) dof.Enabled = state; dof.FarIntensity = state and 0.5 or 0 end, "dof")

-- ============================================================
-- PAGE: EMOTES
-- ============================================================
local emotePage = createPage("Emotes")
createHeader(emotePage, "Emote Player", 0)
local currentTrack, emoteLooped, emoteSpeed, currentAnimId = nil, false, 1, nil
local function getAnimator()
	local char = player.Character or player.CharacterAdded:Wait()
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return nil end
	local animator = hum:FindFirstChildOfClass("Animator")
	if not animator then animator = Instance.new("Animator"); animator.Parent = hum end
	return animator
end
local function playEmote(animId)
	if not animId or animId == "" then return end
	local id = tostring(animId):match("%d+")
	if not id then return end
	local animator = getAnimator()
	if not animator then return end
	if currentTrack then currentTrack:Stop(0.1); currentTrack = nil end
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://" .. id
	currentAnimId = id
	local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
	if not ok or not track then warn("[UnaibleLL] Failed to load animation " .. id); return end
	currentTrack = track
	track.Looped = emoteLooped
	pcall(function() track.Priority = Enum.AnimationPriority.Action4 end)
	track:Play(0.15)
	track:AdjustSpeed(emoteSpeed)
end
local function stopEmote() if currentTrack then currentTrack:Stop(0.15); currentTrack = nil end end
createInput(emotePage, "Custom Emote ID", "Enter animation ID (e.g. 507771019)", 1, function(text, enter) if enter and text ~= "" then playEmote(text) end end)
createToggle(emotePage, "Loop Emote", false, 2, function(state)
	emoteLooped = state
	if currentTrack then
		currentTrack.Looped = state
		if state and not currentTrack.IsPlaying and currentAnimId then playEmote(currentAnimId) end
	end
end, "emoteLoop")
createSlider(emotePage, "Emote Speed", 0.1, 3, 1, 3, function(v) emoteSpeed = v; if currentTrack then currentTrack:AdjustSpeed(v) end end, "emoteSpeed")
createButton(emotePage, "⏹ Stop Emote", 4, COLORS.DANGER, function() stopEmote() end)
createHeader(emotePage, "Preset Emotes", 5)
local presetEmotes = {
	{name = "💃 Dance 1", id = "507771019"},
	{name = "🕺 Dance 2", id = "507776043"},
	{name = "🎉 Dance 3", id = "507777268"},
	{name = "👋 Wave", id = "507770239"},
	{name = "🙌 Cheer", id = "507770677"},
	{name = "👉 Point", id = "507770453"},
	{name = "😂 Laugh", id = "507770818"},
}
for i, emote in ipairs(presetEmotes) do
	createButton(emotePage, emote.name, 5 + i, COLORS.ACCENT, function() playEmote(emote.id) end)
end
player.CharacterAdded:Connect(function() currentTrack = nil end)

-- ============================================================
-- PAGE: PLAYER (with waypoints)
-- ============================================================
local playerPage = createPage("Player")
createHeader(playerPage, "Player Modifiers", 0)
local function getHumanoid()
	local char = player.Character
	if char then return char:FindFirstChildOfClass("Humanoid") end
	return nil
end
local function getHRP(char)
	char = char or player.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end
local function teleportTo(cframe)
	local hrp = getHRP()
	if hrp then hrp.CFrame = cframe end
end

createSlider(playerPage, "Walk Speed", 16, 500, 16, 1, function(v)
	targetWalkSpeed = v
	local hum = getHumanoid()
	if hum then hum.WalkSpeed = v end
end, "walkspeed")
createSlider(playerPage, "Jump Power", 50, 500, 50, 2, function(v)
	targetJumpPower = v
	local hum = getHumanoid()
	if hum and jumpLock then hum.UseJumpPower = true; hum.JumpPower = v end
end, "jumppower")
createToggle(playerPage, "Jump Lock", false, 3, function(state) jumpLock = state end, "jumpLockFlag")
createSlider(playerPage, "Gravity", 0, 400, 196, 4, function(v)
	targetGravity = v
	workspace.Gravity = v
end, "gravity")
createToggle(playerPage, "Noclip", false, 5, function(state)
	if state then
		RunService:BindToRenderStep("Noclip", 1, function()
			local char = player.Character
			if char then
				for _, part in pairs(char:GetDescendants()) do
					if part:IsA("BasePart") then part.CanCollide = false end
				end
			end
		end)
	else
		RunService:UnbindFromRenderStep("Noclip")
	end
end, "noclip")
createToggle(playerPage, "Infinite Jump", false, 6, function(state)
	if state and not _G.UnaibleLL_InfJump then
		_G.UnaibleLL_InfJump = true
		UserInputService.JumpRequest:Connect(function()
			local h = toggleByName["Infinite Jump"]
			if h and h.getState() then
				local hum = getHumanoid()
				if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
			end
		end)
	end
end, "infjump")
createButton(playerPage, "Reset Character 🔄", 7, COLORS.DANGER, function()
	local char = player.Character
	if char then local hum = char:FindFirstChildOfClass("Humanoid"); if hum then hum.Health = 0 end end
end)

createHeader(playerPage, "Waypoints", 8)
local wpNameBox = createInput(playerPage, "Waypoint Name", "Name this spot, then Save", 9, nil)
createButton(playerPage, "📍 Save Current Position", 10, COLORS.ACCENT_GREEN, function()
	local hrp = getHRP()
	if hrp and wpNameBox.Text ~= "" then
		local p = hrp.Position
		Store.waypoints[wpNameBox.Text] = {p.X, p.Y, p.Z}
		saveStore()
		wpNameBox.Text = ""
		if refreshWaypoints then refreshWaypoints() end
	end
end)
local wpHolder = create("Frame", {
	Size = UDim2.new(1, 0, 0, 10),
	BackgroundTransparency = 1,
	AutomaticSize = Enum.AutomaticSize.Y,
	LayoutOrder = 11,
	Parent = playerPage,
})
create("UIListLayout", {SortOrder = Enum.SortOrder.Name, Padding = UDim.new(0, 6), Parent = wpHolder})

refreshWaypoints = function()
	for _, c in pairs(wpHolder:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end
	local any = false
	for name, pos in pairs(Store.waypoints) do
		any = true
		local row = create("Frame", {
			Name = name,
			Size = UDim2.new(1, 0, 0, 40),
			BackgroundColor3 = COLORS.BG_CARD,
			BorderSizePixel = 0,
			Parent = wpHolder,
		})
		addCorner(row, 10)
		addStroke(row, COLORS.BORDER, 1, 0.5)
		create("TextLabel", {
			Size = UDim2.new(1, -140, 1, 0),
			Position = UDim2.new(0, 14, 0, 0),
			BackgroundTransparency = 1,
			Text = "📍 " .. name,
			TextColor3 = COLORS.TEXT_PRIMARY,
			TextSize = 12,
			Font = Enum.Font.GothamMedium,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = row,
		})
		local tpBtn = create("TextButton", {
			Size = UDim2.new(0, 74, 0, 26),
			Position = UDim2.new(1, -124, 0.5, -13),
			BackgroundColor3 = COLORS.ACCENT,
			BorderSizePixel = 0,
			Text = "Teleport",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 11,
			Font = Enum.Font.GothamBold,
			AutoButtonColor = false,
			Parent = row,
		})
		addCorner(tpBtn, 6)
		tpBtn.MouseButton1Click:Connect(function()
			teleportTo(CFrame.new(pos[1], pos[2] + 3, pos[3]))
		end)
		local delBtn = create("TextButton", {
			Size = UDim2.new(0, 40, 0, 26),
			Position = UDim2.new(1, -46, 0.5, -13),
			BackgroundColor3 = COLORS.DANGER,
			BorderSizePixel = 0,
			Text = "✕",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 12,
			Font = Enum.Font.GothamBold,
			AutoButtonColor = false,
			Parent = row,
		})
		addCorner(delBtn, 6)
		delBtn.MouseButton1Click:Connect(function()
			Store.waypoints[name] = nil
			saveStore()
			refreshWaypoints()
		end)
	end
	if not any then
		create("TextLabel", {
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundTransparency = 1,
			Text = "No waypoints saved.",
			TextColor3 = COLORS.TEXT_SECONDARY,
			TextSize = 12,
			Font = Enum.Font.Gotham,
			Parent = wpHolder,
		})
	end
end

player.CharacterAdded:Connect(function(char)
	local hum = char:WaitForChild("Humanoid", 5)
	if hum then
		hum.WalkSpeed = targetWalkSpeed
		if jumpLock then hum.UseJumpPower = true; hum.JumpPower = targetJumpPower end
	end
	workspace.Gravity = targetGravity
end)

-- ============================================================
-- PAGE: VISUALS (tracers + chams)
-- ============================================================
local visPage = createPage("Visuals")
createHeader(visPage, "Player ESP", 0)

local chamColor = Color3.fromRGB(88, 126, 255)

local function removeTracer(plr)
	if tracerObjects[plr] then
		tracerObjects[plr]:Destroy()
		tracerObjects[plr] = nil
	end
end
local function removeCham(plr)
	if chamObjects[plr] then
		chamObjects[plr]:Destroy()
		chamObjects[plr] = nil
	end
end
local function makeCham(plr)
	if chamObjects[plr] then return end
	local char = plr.Character
	if not char then return end
	local hl = Instance.new("Highlight")
	hl.Name = "UnaibleLL_Cham"
	hl.FillColor = chamColor
	hl.FillTransparency = 0.5
	hl.OutlineColor = Color3.fromRGB(255, 255, 255)
	hl.OutlineTransparency = 0
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Adornee = char
	hl.Parent = char
	chamObjects[plr] = hl
end
local function makeTracer(plr)
	if tracerObjects[plr] then return end
	local line = create("Frame", {
		Name = "UnaibleLL_Tracer",
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = chamColor,
		BorderSizePixel = 0,
		ZIndex = 90,
		Parent = screenGui,
	})
	tracerObjects[plr] = line
end

createToggle(visPage, "Tracers", false, 1, function(state)
	tracersEnabled = state
	if not state then
		for plr, _ in pairs(tracerObjects) do removeTracer(plr) end
	end
end, "tracers")
createToggle(visPage, "Chams / Highlight", false, 2, function(state)
	chamsEnabled = state
	if state then
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= player then makeCham(plr) end
		end
	else
		for plr, _ in pairs(chamObjects) do removeCham(plr) end
	end
end, "chams")
createSlider(visPage, "ESP Color (Hue)", 0, 360, 220, 3, function(v)
	chamColor = Color3.fromHSV(v / 360, 0.7, 1)
	for _, hl in pairs(chamObjects) do hl.FillColor = chamColor end
	for _, ln in pairs(tracerObjects) do ln.BackgroundColor3 = chamColor end
end, "espHue")
createToggle(visPage, "Team Check (skip same team)", false, 4, function() end, "teamCheck")

-- Cleanup on leave / rebuild on respawn
Players.PlayerRemoving:Connect(function(plr)
	removeTracer(plr)
	removeCham(plr)
end)
Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function()
		task.wait(0.5)
		if chamsEnabled and plr ~= player then makeCham(plr) end
	end)
end)
for _, plr in ipairs(Players:GetPlayers()) do
	if plr ~= player then
		plr.CharacterAdded:Connect(function()
			task.wait(0.5)
			if chamsEnabled then makeCham(plr) end
		end)
	end
end

-- ============================================================
-- PAGE: SERVER (info panel)
-- ============================================================
local srvPage = createPage("Server")
createHeader(srvPage, "Server Info", 0)

local function infoCard(parent, label, order)
	local card = create("Frame", {
		Size = UDim2.new(1, 0, 0, 54),
		BackgroundColor3 = COLORS.BG_CARD,
		BorderSizePixel = 0,
		LayoutOrder = order,
		Parent = parent,
	})
	addCorner(card, 10)
	addStroke(card, COLORS.BORDER, 1, 0.5)
	create("TextLabel", {
		Size = UDim2.new(1, -24, 0, 18),
		Position = UDim2.new(0, 14, 0, 8),
		BackgroundTransparency = 1,
		Text = label,
		TextColor3 = COLORS.TEXT_SECONDARY,
		TextSize = 11,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})
	local val = create("TextLabel", {
		Size = UDim2.new(1, -24, 0, 22),
		Position = UDim2.new(0, 14, 0, 26),
		BackgroundTransparency = 1,
		Text = "...",
		TextColor3 = COLORS.TEXT_PRIMARY,
		TextSize = 16,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})
	return val
end

local pingVal = infoCard(srvPage, "Ping (ms)", 1)
local playersVal = infoCard(srvPage, "Players in Server", 2)
local fpsVal = infoCard(srvPage, "FPS", 3)
local ageVal = infoCard(srvPage, "Session Time", 4)
local jobVal = infoCard(srvPage, "Server (Job) ID", 5)

createButton(srvPage, "🔄 Rejoin Server", 6, COLORS.ACCENT, function()
	pcall(function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
	end)
end)
createButton(srvPage, "🎲 Server Hop (new server)", 7, COLORS.ACCENT_2, function()
	pcall(function()
		TeleportService:Teleport(game.PlaceId, player)
	end)
end)

local sessionStart = tick()
task.spawn(function()
	local frameCount, lastT, fpsShown = 0, tick(), 0
	RunService.RenderStepped:Connect(function()
		frameCount += 1
		if tick() - lastT >= 1 then
			fpsShown = frameCount
			frameCount = 0
			lastT = tick()
		end
	end)
	while true do
		-- Ping
		local okPing, ping = pcall(function()
			return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
		end)
		pingVal.Text = okPing and (ping .. " ms") or "N/A"
		-- Players
		playersVal.Text = #Players:GetPlayers() .. " / " .. Players.MaxPlayers
		-- FPS
		fpsVal.Text = tostring(fpsShown)
		-- Session time
		local secs = math.floor(tick() - sessionStart)
		ageVal.Text = string.format("%02d:%02d:%02d", math.floor(secs/3600), math.floor((secs%3600)/60), secs%60)
		-- Job id
		jobVal.Text = (game.JobId ~= "" and game.JobId:sub(1, 18) .. "...") or "Studio"
		jobVal.TextSize = 12
		task.wait(1)
	end
end)

-- ============================================================
-- PAGE: PLAYERS (list, teleport, spectate)
-- ============================================================
local plrPage = createPage("Players")
createHeader(plrPage, "Player List", 0)

local spectating = nil
local function stopSpectate()
	spectating = nil
	local hum = getHumanoid()
	camera.CameraSubject = hum
	camera.CameraType = Enum.CameraType.Custom
end
local function spectatePlayer(target)
	if not target.Character then return end
	local hum = target.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		spectating = target
		camera.CameraSubject = hum
	end
end

local plrListHolder = create("Frame", {
	Size = UDim2.new(1, 0, 0, 10),
	BackgroundTransparency = 1,
	AutomaticSize = Enum.AutomaticSize.Y,
	LayoutOrder = 1,
	Parent = plrPage,
})
create("UIListLayout", {SortOrder = Enum.SortOrder.Name, Padding = UDim.new(0, 6), Parent = plrListHolder})

createButton(plrPage, "⏹ Stop Spectating", 2, COLORS.DANGER, function() stopSpectate() end)

local function refreshPlayers()
	for _, c in pairs(plrListHolder:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player then
			local row = create("Frame", {
				Name = plr.Name,
				Size = UDim2.new(1, 0, 0, 46),
				BackgroundColor3 = COLORS.BG_CARD,
				BorderSizePixel = 0,
				Parent = plrListHolder,
			})
			addCorner(row, 10)
			addStroke(row, COLORS.BORDER, 1, 0.5)
			local pic = create("ImageLabel", {
				Size = UDim2.new(0, 30, 0, 30),
				Position = UDim2.new(0, 8, 0.5, -15),
				BackgroundColor3 = COLORS.BG_HOVER,
				BorderSizePixel = 0,
				Image = "rbxthumb://type=AvatarHeadShot&id=" .. plr.UserId .. "&w=48&h=48",
				Parent = row,
			})
			addCorner(pic, 15)
			create("TextLabel", {
				Size = UDim2.new(1, -190, 1, 0),
				Position = UDim2.new(0, 46, 0, 0),
				BackgroundTransparency = 1,
				Text = plr.DisplayName,
				TextColor3 = COLORS.TEXT_PRIMARY,
				TextSize = 12,
				Font = Enum.Font.GothamMedium,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = row,
			})
			local tpBtn = create("TextButton", {
				Size = UDim2.new(0, 62, 0, 26),
				Position = UDim2.new(1, -132, 0.5, -13),
				BackgroundColor3 = COLORS.ACCENT,
				BorderSizePixel = 0,
				Text = "Teleport",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 10,
				Font = Enum.Font.GothamBold,
				AutoButtonColor = false,
				Parent = row,
			})
			addCorner(tpBtn, 6)
			tpBtn.MouseButton1Click:Connect(function()
				local thrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
				if thrp then teleportTo(thrp.CFrame * CFrame.new(0, 0, 3)) end
			end)
			local specBtn = create("TextButton", {
				Size = UDim2.new(0, 62, 0, 26),
				Position = UDim2.new(1, -66, 0.5, -13),
				BackgroundColor3 = COLORS.ACCENT_2,
				BorderSizePixel = 0,
				Text = "Spectate",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 10,
				Font = Enum.Font.GothamBold,
				AutoButtonColor = false,
				Parent = row,
			})
			addCorner(specBtn, 6)
			specBtn.MouseButton1Click:Connect(function() spectatePlayer(plr) end)
		end
	end
end

Players.PlayerAdded:Connect(function() task.wait(0.3); refreshPlayers() end)
Players.PlayerRemoving:Connect(function(plr)
	if spectating == plr then stopSpectate() end
	task.wait(0.3); refreshPlayers()
end)

-- ============================================================
-- PAGE: CONFIGS
-- ============================================================
local cfgPage = createPage("Configs")
createHeader(cfgPage, "Save / Load Configs", 0)
local nameBox = createInput(cfgPage, "Config Name", "Enter a name for this config", 1, nil)
createButton(cfgPage, "💾 Save As New Config", 2, COLORS.ACCENT_GREEN, function()
	local name = nameBox.Text
	if name and name ~= "" then
		if saveConfigAs(name) then nameBox.Text = "" end
	end
end)
createHeader(cfgPage, "Saved Configs", 3)
local configListHolder = create("Frame", {
	Size = UDim2.new(1, 0, 0, 10),
	BackgroundTransparency = 1,
	AutomaticSize = Enum.AutomaticSize.Y,
	LayoutOrder = 4,
	Parent = cfgPage,
})
create("UIListLayout", {SortOrder = Enum.SortOrder.Name, Padding = UDim.new(0, 6), Parent = configListHolder})

refreshConfigList = function()
	for _, c in pairs(configListHolder:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end
	local any = false
	for name, _ in pairs(Store.configs) do
		any = true
		local isAuto = (Store.autoload == name)
		local row = create("Frame", {
			Name = name,
			Size = UDim2.new(1, 0, 0, 40),
			BackgroundColor3 = COLORS.BG_CARD,
			BorderSizePixel = 0,
			Parent = configListHolder,
		})
		addCorner(row, 10)
		addStroke(row, isAuto and COLORS.ACCENT or COLORS.BORDER, 1, isAuto and 0 or 0.5)
		create("TextLabel", {
			Size = UDim2.new(1, -200, 1, 0),
			Position = UDim2.new(0, 14, 0, 0),
			BackgroundTransparency = 1,
			Text = (isAuto and "★ " or "") .. name,
			TextColor3 = COLORS.TEXT_PRIMARY,
			TextSize = 12,
			Font = Enum.Font.GothamMedium,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = row,
		})
		local loadBtn = create("TextButton", {
			Size = UDim2.new(0, 54, 0, 26),
			Position = UDim2.new(1, -184, 0.5, -13),
			BackgroundColor3 = COLORS.ACCENT,
			BorderSizePixel = 0,
			Text = "Load",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 11,
			Font = Enum.Font.GothamBold,
			AutoButtonColor = false,
			Parent = row,
		})
		addCorner(loadBtn, 6)
		loadBtn.MouseButton1Click:Connect(function() loadConfigNamed(name) end)
		local autoBtn = create("TextButton", {
			Size = UDim2.new(0, 74, 0, 26),
			Position = UDim2.new(1, -124, 0.5, -13),
			BackgroundColor3 = isAuto and COLORS.ACCENT_GREEN or COLORS.BG_CONTENT,
			BorderSizePixel = 0,
			Text = isAuto and "Auto ✓" or "Autoload",
			TextColor3 = isAuto and Color3.fromRGB(255,255,255) or COLORS.TEXT_SECONDARY,
			TextSize = 10,
			Font = Enum.Font.GothamBold,
			AutoButtonColor = false,
			Parent = row,
		})
		addCorner(autoBtn, 6)
		autoBtn.MouseButton1Click:Connect(function() setAutoload(name) end)
		local delBtn = create("TextButton", {
			Size = UDim2.new(0, 40, 0, 26),
			Position = UDim2.new(1, -46, 0.5, -13),
			BackgroundColor3 = COLORS.DANGER,
			BorderSizePixel = 0,
			Text = "✕",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 12,
			Font = Enum.Font.GothamBold,
			AutoButtonColor = false,
			Parent = row,
		})
		addCorner(delBtn, 6)
		delBtn.MouseButton1Click:Connect(function() deleteConfigNamed(name) end)
	end
	if not any then
		create("TextLabel", {
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundTransparency = 1,
			Text = "No saved configs yet.",
			TextColor3 = COLORS.TEXT_SECONDARY,
			TextSize = 12,
			Font = Enum.Font.Gotham,
			Parent = configListHolder,
		})
	end
end

createButton(cfgPage, "Overwrite Autoload with Current", 5, COLORS.ACCENT_2, function()
	if Store.autoload then saveConfigAs(Store.autoload) end
end)

-- ============================================================
-- PAGE: SETTINGS
-- ============================================================
local setPage = createPage("Settings")
createHeader(setPage, "UI Settings", 0)
createSlider(setPage, "GUI Transparency %", 0, 80, 0, 1, function(v)
	local t = v / 100
	mainFrame.BackgroundTransparency = t
	topBar.BackgroundTransparency = t
	sidebarFrame.BackgroundTransparency = t
	contentArea.BackgroundTransparency = t
end, "guiTransparency")

local fpsLabel, fpsDragging, fpsDragStart, fpsStartPos = nil, false, nil, nil
createToggle(setPage, "FPS Counter (drag to move)", false, 2, function(state)
	if state then
		if not fpsLabel then
			fpsLabel = create("TextLabel", {
				Name = "FPS",
				Size = UDim2.new(0, 90, 0, 30),
				Position = UDim2.new(1, -100, 0, 10),
				BackgroundColor3 = COLORS.BG_CARD,
				BackgroundTransparency = 0.1,
				Text = "0 FPS",
				TextColor3 = COLORS.ACCENT_GREEN,
				TextSize = 13,
				Font = Enum.Font.GothamBold,
				ZIndex = 200,
				Active = true,
				Parent = screenGui,
			})
			addCorner(fpsLabel, 8)
			addStroke(fpsLabel, COLORS.BORDER, 1, 0.4)
			fpsLabel.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					fpsDragging = true; fpsDragStart = input.Position; fpsStartPos = fpsLabel.Position
				end
			end)
			fpsLabel.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then fpsDragging = false end
			end)
			local fc, lt = 0, tick()
			RunService.RenderStepped:Connect(function()
				if not fpsLabel or not fpsLabel.Parent then return end
				fc += 1
				if tick() - lt >= 1 then
					if fpsLabel.Visible then fpsLabel.Text = fc .. " FPS" end
					fc = 0; lt = tick()
				end
			end)
		end
		fpsLabel.Visible = true
	else
		if fpsLabel then fpsLabel.Visible = false end
	end
end, "fps")
UserInputService.InputChanged:Connect(function(input)
	if fpsDragging and fpsLabel and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - fpsDragStart
		fpsLabel.Position = UDim2.new(fpsStartPos.X.Scale, fpsStartPos.X.Offset + delta.X, fpsStartPos.Y.Scale, fpsStartPos.Y.Offset + delta.Y)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then fpsDragging = false end
end)

createToggle(setPage, "Show Functions HUD", false, 3, function(state) hudFrame.Visible = state; if state then updateHUD() end end, "showHUD")
createToggle(setPage, "Anti-AFK", false, 4, function(state)
	if state and not _G.UnaibleLL_AntiAFK then
		_G.UnaibleLL_AntiAFK = true
		local vu = game:GetService("VirtualUser")
		player.Idled:Connect(function()
			if toggleByName["Anti-AFK"] and toggleByName["Anti-AFK"].getState() then
				pcall(function()
					vu:Button2Down(Vector2.new(0, 0), camera.CFrame)
					task.wait(1)
					vu:Button2Up(Vector2.new(0, 0), camera.CFrame)
				end)
			end
		end)
	end
end, "antiafk")

-- ============================================================
-- WINDOW DRAGGING
-- ============================================================
local dragging, dragStart, startPos = false, nil, nil
topBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true; dragStart = input.Position; startPos = mainFrame.Position
	end
end)
topBar.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-- ============================================================
-- KEYBIND HANDLING
-- ============================================================
UserInputService.InputBegan:Connect(function(input, processed)
	if bindListening then
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.Escape then
				keybinds[bindListening.name] = nil
			else
				keybinds[bindListening.name] = input.KeyCode
			end
			bindListening.updateBindText()
			bindListening = nil
			saveStore()
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

-- ============================================================
-- ENFORCEMENT LOOPS
-- ============================================================
RunService.RenderStepped:Connect(function()
	if workspace.CurrentCamera ~= camera then camera = workspace.CurrentCamera end
	if fovLockEnabled and camera.FieldOfView ~= lockedFOV then
		camera.FieldOfView = lockedFOV
	end
	if rainActive or snowActive or dustActive then
		weatherPart.CFrame = CFrame.new(camera.CFrame.Position + Vector3.new(0, 40, 0))
	end
	-- Tracers
	if tracersEnabled then
		local teamCheck = toggleByName["Team Check (skip same team)"] and toggleByName["Team Check (skip same team)"].getState()
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= player and not (teamCheck and plr.Team == player.Team) then
				local char = plr.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if hrp then
					local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
					if onScreen then
						if not tracerObjects[plr] then makeTracer(plr) end
						local ln = tracerObjects[plr]
						local vpSize = camera.ViewportSize
						local originX, originY = vpSize.X / 2, vpSize.Y
						local dx = screenPos.X - originX
						local dy = screenPos.Y - originY
						local dist = math.sqrt(dx*dx + dy*dy)
						local angle = math.atan2(dy, dx)
						ln.Size = UDim2.new(0, 2, 0, dist)
						ln.Position = UDim2.new(0, originX + dx/2, 0, originY + dy/2)
						ln.Rotation = math.deg(angle) - 90
						ln.Visible = true
					elseif tracerObjects[plr] then
						tracerObjects[plr].Visible = false
					end
				elseif tracerObjects[plr] then
					tracerObjects[plr].Visible = false
				end
			end
		end
	end
	-- Rebuild chams if a target respawned without one
	if chamsEnabled then
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= player and plr.Character and not chamObjects[plr] then
				makeCham(plr)
			end
		end
	end
end)

RunService.Heartbeat:Connect(function()
	local hum = getHumanoid()
	if hum then
		hum.WalkSpeed = targetWalkSpeed
		if jumpLock then hum.UseJumpPower = true; hum.JumpPower = targetJumpPower end
	end
	if workspace.Gravity ~= targetGravity then workspace.Gravity = targetGravity end
end)

-- Keep spectate camera valid
RunService.RenderStepped:Connect(function()
	if spectating then
		if not spectating.Parent or not spectating.Character then stopSpectate() end
	end
end)

-- ============================================================
-- F1 TOGGLE + OPEN ANIMATION
-- ============================================================
local guiOpen = false
local FULL_SIZE = UDim2.new(0, 760, 0, 520)
local FULL_POS = UDim2.new(0.5, -380, 0.5, -260)
local function openGui()
	guiOpen = true
	mainFrame.Visible = true
	mainFrame.Size = UDim2.new(0, 0, 0, 0)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	local t = TweenService:Create(mainFrame, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = FULL_SIZE, Position = FULL_POS})
	t:Play()
end
local function closeGui()
	guiOpen = false
	smoothTween(mainFrame, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}, 0.35)
	task.delay(0.4, function() if not guiOpen then mainFrame.Visible = false end end)
end
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.F1 then
		if guiOpen then closeGui() else openGui() end
	end
end)

-- ============================================================
-- INITIALIZE
-- ============================================================
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
