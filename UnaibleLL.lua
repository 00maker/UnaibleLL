-- ============================================================
-- UnaibleLL - Client Visual Customization Suite v2
-- Clean white/light theme, smooth animations, weather effects
-- Place in StarterPlayerScripts or StarterGui
-- ============================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

-- ============================================================
-- COLOR PALETTE (clean white/light theme)
-- ============================================================
local COLORS = {
	BG_MAIN = Color3.fromRGB(240, 242, 248),
	BG_SIDEBAR = Color3.fromRGB(250, 251, 255),
	BG_CONTENT = Color3.fromRGB(245, 247, 252),
	BG_CARD = Color3.fromRGB(255, 255, 255),
	BG_HOVER = Color3.fromRGB(235, 238, 248),
	BG_INPUT = Color3.fromRGB(225, 228, 238),
	BG_TRACK = Color3.fromRGB(210, 215, 228),
	ACCENT = Color3.fromRGB(80, 120, 255),
	ACCENT_LIGHT = Color3.fromRGB(120, 155, 255),
	ACCENT_GREEN = Color3.fromRGB(60, 190, 110),
	TEXT_PRIMARY = Color3.fromRGB(30, 35, 55),
	TEXT_SECONDARY = Color3.fromRGB(100, 108, 130),
	TEXT_DIM = Color3.fromRGB(150, 158, 175),
	BORDER = Color3.fromRGB(215, 220, 235),
	TOPBAR = Color3.fromRGB(255, 255, 255),
	SHADOW = Color3.fromRGB(180, 185, 200),
	SCROLLBAR = Color3.fromRGB(180, 188, 210),
	DANGER = Color3.fromRGB(220, 70, 80),
}

local CONFIG = {
	DEFAULT_FOV = 70, MIN_FOV = 30, MAX_FOV = 120,
	DEFAULT_CLOCK = 14, MIN_CLOCK = 0, MAX_CLOCK = 24,
	TWEEN_SPEED = 0.35,
	BG_TRANSPARENCY = 0,
}

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================
local function create(className, props)
	local inst = Instance.new(className)
	for k, v in pairs(props) do
		if k ~= "Parent" then
			inst[k] = v
		end
	end
	if props.Parent then inst.Parent = props.Parent end
	return inst
end

local function tween(obj, props, duration)
	local info = TweenInfo.new(
		duration or CONFIG.TWEEN_SPEED,
		Enum.EasingStyle.Quart,
		Enum.EasingDirection.Out
	)
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

local function smoothTween(obj, props, duration)
	local info = TweenInfo.new(
		duration or 0.5,
		Enum.EasingStyle.Exponential,
		Enum.EasingDirection.Out
	)
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

local function addCorner(parent, radius)
	return create("UICorner", { CornerRadius = UDim.new(0, radius or 10), Parent = parent })
end

local function addStroke(parent, color, thickness, transparency)
	return create("UIStroke", {
		Color = color or COLORS.BORDER,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		Parent = parent,
	})
end

local function addPadding(parent, top, bot, left, right)
	return create("UIPadding", {
		PaddingTop = UDim.new(0, top or 0),
		PaddingBottom = UDim.new(0, bot or 0),
		PaddingLeft = UDim.new(0, left or 0),
		PaddingRight = UDim.new(0, right or 0),
		Parent = parent,
	})
end

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
-- MAIN CONTAINER
-- ============================================================
local mainFrame = create("Frame", {
	Name = "MainPanel",
	Size = UDim2.new(0, 700, 0, 480),
	Position = UDim2.new(0.5, -350, 0.5, -240),
	BackgroundColor3 = COLORS.BG_MAIN,
	BackgroundTransparency = CONFIG.BG_TRANSPARENCY,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Parent = screenGui,
})
addCorner(mainFrame, 14)
addStroke(mainFrame, COLORS.BORDER, 1, 0.3)

-- ============================================================
-- TOP BAR
-- ============================================================
local topBar = create("Frame", {
	Name = "TopBar",
	Size = UDim2.new(1, 0, 0, 48),
	BackgroundColor3 = COLORS.TOPBAR,
	BackgroundTransparency = 0,
	BorderSizePixel = 0,
	Parent = mainFrame,
})

-- Subtle bottom border on topbar
create("Frame", {
	Size = UDim2.new(1, 0, 0, 1),
	Position = UDim2.new(0, 0, 1, -1),
	BackgroundColor3 = COLORS.BORDER,
	BorderSizePixel = 0,
	Parent = topBar,
})

-- Logo
local logoLabel = create("TextLabel", {
	Size = UDim2.new(0, 32, 0, 48),
	Position = UDim2.new(0, 16, 0, 0),
	BackgroundTransparency = 1,
	Text = "∞",
	TextColor3 = COLORS.ACCENT,
	TextSize = 22,
	Font = Enum.Font.GothamBold,
	Parent = topBar,
})

local titleLabel = create("TextLabel", {
	Size = UDim2.new(0, 140, 0, 48),
	Position = UDim2.new(0, 48, 0, 0),
	BackgroundTransparency = 1,
	Text = "UnaibleLL",
	TextColor3 = COLORS.TEXT_PRIMARY,
	TextSize = 17,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = topBar,
})

-- Version badge
local versionBadge = create("TextLabel", {
	Size = UDim2.new(0, 36, 0, 18),
	Position = UDim2.new(0, 150, 0, 15),
	BackgroundColor3 = COLORS.ACCENT,
	BackgroundTransparency = 0.85,
	Text = "v2",
	TextColor3 = COLORS.ACCENT,
	TextSize = 10,
	Font = Enum.Font.GothamBold,
	Parent = topBar,
})
addCorner(versionBadge, 4)

-- Minimize button
local minimizeBtn = create("TextButton", {
	Size = UDim2.new(0, 32, 0, 28),
	Position = UDim2.new(1, -78, 0, 10),
	BackgroundColor3 = COLORS.BG_HOVER,
	BorderSizePixel = 0,
	Text = "−",
	TextColor3 = COLORS.TEXT_SECONDARY,
	TextSize = 16,
	Font = Enum.Font.GothamBold,
	Parent = topBar,
})
addCorner(minimizeBtn, 6)

-- Close button
local closeBtn = create("TextButton", {
	Size = UDim2.new(0, 32, 0, 28),
	Position = UDim2.new(1, -42, 0, 10),
	BackgroundColor3 = COLORS.DANGER,
	BackgroundTransparency = 0.9,
	BorderSizePixel = 0,
	Text = "✕",
	TextColor3 = COLORS.DANGER,
	TextSize = 11,
	Font = Enum.Font.GothamBold,
	Parent = topBar,
})
addCorner(closeBtn, 6)

-- Button hover effects
minimizeBtn.MouseEnter:Connect(function()
	smoothTween(minimizeBtn, { BackgroundColor3 = COLORS.BG_INPUT }, 0.2)
end)
minimizeBtn.MouseLeave:Connect(function()
	smoothTween(minimizeBtn, { BackgroundColor3 = COLORS.BG_HOVER }, 0.2)
end)
closeBtn.MouseEnter:Connect(function()
	smoothTween(closeBtn, { BackgroundTransparency = 0.7 }, 0.2)
end)
closeBtn.MouseLeave:Connect(function()
	smoothTween(closeBtn, { BackgroundTransparency = 0.9 }, 0.2)
end)

-- ============================================================
-- SIDEBAR
-- ============================================================
local sidebar = create("Frame", {
	Name = "Sidebar",
	Size = UDim2.new(0, 170, 1, -48),
	Position = UDim2.new(0, 0, 0, 48),
	BackgroundColor3 = COLORS.BG_SIDEBAR,
	BorderSizePixel = 0,
	Parent = mainFrame,
})

-- Right border on sidebar
create("Frame", {
	Size = UDim2.new(0, 1, 1, 0),
	Position = UDim2.new(1, -1, 0, 0),
	BackgroundColor3 = COLORS.BORDER,
	BackgroundTransparency = 0.4,
	BorderSizePixel = 0,
	Parent = sidebar,
})

local sidebarLayout = create("UIListLayout", {
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 4),
	Parent = sidebar,
})
addPadding(sidebar, 14, 14, 10, 10)

-- Navigation items
local navItems = {
	{ icon = "🎥", label = "Camera", order = 1 },
	{ icon = "🌤️", label = "Environment", order = 2 },
	{ icon = "🌧️", label = "Weather", order = 3 },
	{ icon = "🎬", label = "Effects", order = 4 },
	{ icon = "⚙️", label = "Settings", order = 5 },
}

local navButtons = {}
local currentTab = "Camera"

local function createNavItem(data)
	local btn = create("TextButton", {
		Name = data.label .. "Nav",
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = COLORS.BG_HOVER,
		BackgroundTransparency = (data.label == currentTab) and 0 or 1,
		BorderSizePixel = 0,
		Text = "",
		LayoutOrder = data.order,
		AutoButtonColor = false,
		Parent = sidebar,
	})
	addCorner(btn, 10)

	-- Accent indicator
	local accentBar = create("Frame", {
		Name = "Accent",
		Size = UDim2.new(0, 3, 0, 18),
		Position = UDim2.new(0, 2, 0.5, -9),
		BackgroundColor3 = COLORS.ACCENT,
		BorderSizePixel = 0,
		Visible = (data.label == currentTab),
		Parent = btn,
	})
	addCorner(accentBar, 2)

	create("TextLabel", {
		Size = UDim2.new(0, 24, 1, 0),
		Position = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text = data.icon,
		TextSize = 14,
		Font = Enum.Font.Gotham,
		TextColor3 = COLORS.TEXT_PRIMARY,
		Parent = btn,
	})

	local nameLbl = create("TextLabel", {
		Size = UDim2.new(1, -48, 1, 0),
		Position = UDim2.new(0, 42, 0, 0),
		BackgroundTransparency = 1,
		Text = data.label,
		TextSize = 13,
		Font = Enum.Font.GothamMedium,
		TextColor3 = (data.label == currentTab) and COLORS.TEXT_PRIMARY or COLORS.TEXT_SECONDARY,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = btn,
	})

	-- Hover animation
	btn.MouseEnter:Connect(function()
		if data.label ~= currentTab then
			smoothTween(btn, { BackgroundTransparency = 0.4 }, 0.2)
		end
	end)
	btn.MouseLeave:Connect(function()
		if data.label ~= currentTab then
			smoothTween(btn, { BackgroundTransparency = 1 }, 0.2)
		end
	end)

	navButtons[data.label] = { button = btn, accent = accentBar, nameLabel = nameLbl }
	return btn
end

for _, item in ipairs(navItems) do
	createNavItem(item)
end

-- ============================================================
-- CONTENT AREA
-- ============================================================
local contentArea = create("Frame", {
	Name = "ContentArea",
	Size = UDim2.new(1, -170, 1, -48),
	Position = UDim2.new(0, 170, 0, 48),
	BackgroundColor3 = COLORS.BG_CONTENT,
	BackgroundTransparency = 0,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Parent = mainFrame,
})

-- ============================================================
-- PAGE SYSTEM
-- ============================================================
local pages = {}

local function createPage(name)
	local page = create("ScrollingFrame", {
		Name = name .. "Page",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = COLORS.SCROLLBAR,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = (name == currentTab),
		Parent = contentArea,
	})
	addPadding(page, 18, 18, 20, 20)
	create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 10),
		Parent = page,
	})
	pages[name] = page
	return page
end

-- ============================================================
-- SECTION HEADER COMPONENT
-- ============================================================
local function createSectionHeader(parent, text, order)
	local lbl = create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = COLORS.TEXT_PRIMARY,
		TextSize = 15,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = order or 0,
		Parent = parent,
	})
	return lbl
end

-- ============================================================
-- SLIDER COMPONENT (white clean style)
-- ============================================================
local function createSlider(parent, label, min, max, default, layoutOrder, callback)
	local container = create("Frame", {
		Name = label,
		Size = UDim2.new(1, 0, 0, 64),
		BackgroundColor3 = COLORS.BG_CARD,
		BorderSizePixel = 0,
		LayoutOrder = layoutOrder,
		Parent = parent,
	})
	addCorner(container, 10)
	addStroke(container, COLORS.BORDER, 1, 0.5)

	create("TextLabel", {
		Size = UDim2.new(0.65, 0, 0, 22),
		Position = UDim2.new(0, 16, 0, 8),
		BackgroundTransparency = 1,
		Text = label,
		TextColor3 = COLORS.TEXT_PRIMARY,
		TextSize = 12,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = container,
	})

	local valueLbl = create("TextLabel", {
		Name = "Value",
		Size = UDim2.new(0.3, 0, 0, 22),
		Position = UDim2.new(0.67, 0, 0, 8),
		BackgroundTransparency = 1,
		Text = tostring(default),
		TextColor3 = COLORS.ACCENT,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = container,
	})

	-- Track
	local track = create("Frame", {
		Name = "Track",
		Size = UDim2.new(1, -32, 0, 6),
		Position = UDim2.new(0, 16, 0, 42),
		BackgroundColor3 = COLORS.BG_TRACK,
		BorderSizePixel = 0,
		Parent = container,
	})
	addCorner(track, 3)

	local initFill = math.clamp((default - min) / (max - min), 0, 1)

	local fill = create("Frame", {
		Size = UDim2.new(initFill, 0, 1, 0),
		BackgroundColor3 = COLORS.ACCENT,
		BorderSizePixel = 0,
		Parent = track,
	})
	addCorner(fill, 3)

	local knob = create("Frame", {
		Name = "Knob",
		Size = UDim2.new(0, 16, 0, 16),
		Position = UDim2.new(initFill, -8, 0.5, -8),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = track,
	})
	addCorner(knob, 8)
	addStroke(knob, COLORS.ACCENT, 2, 0)

	-- Shadow on knob
	create("UIStroke", {
		Color = COLORS.SHADOW,
		Thickness = 1,
		Transparency = 0.6,
		Parent = knob,
	}):Destroy() -- We already have accent stroke

	local dragging = false

	local function update(inputX)
		local pos = track.AbsolutePosition.X
		local size = track.AbsoluteSize.X
		local rel = math.clamp((inputX - pos) / size, 0, 1)
		local value = min + (max - min) * rel

		-- Round based on range
		if (max - min) <= 10 then
			value = math.floor(value * 10 + 0.5) / 10
		else
			value = math.floor(value + 0.5)
		end

		local displayRel = (value - min) / (max - min)
		smoothTween(fill, { Size = UDim2.new(displayRel, 0, 1, 0) }, 0.08)
		smoothTween(knob, { Position = UDim2.new(displayRel, -8, 0.5, -8) }, 0.08)
		valueLbl.Text = tostring(value)

		if callback then callback(value) end
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			update(input.Position.X)
		end
	end)

	knob.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			update(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	return container
end

-- ============================================================
-- TOGGLE COMPONENT (clean white pill style)
-- ============================================================
local function createToggle(parent, label, default, layoutOrder, callback)
	local container = create("Frame", {
		Name = label,
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = COLORS.BG_CARD,
		BorderSizePixel = 0,
		LayoutOrder = layoutOrder,
		Parent = parent,
	})
	addCorner(container, 10)
	addStroke(container, COLORS.BORDER, 1, 0.5)

	create("TextLabel", {
		Size = UDim2.new(0.7, 0, 1, 0),
		Position = UDim2.new(0, 16, 0, 0),
		BackgroundTransparency = 1,
		Text = label,
		TextColor3 = COLORS.TEXT_PRIMARY,
		TextSize = 12,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = container,
	})

	local toggleBg = create("Frame", {
		Size = UDim2.new(0, 42, 0, 24),
		Position = UDim2.new(1, -58, 0.5, -12),
		BackgroundColor3 = default and COLORS.ACCENT_GREEN or COLORS.BG_TRACK,
		BorderSizePixel = 0,
		Parent = container,
	})
	addCorner(toggleBg, 12)

	local toggleKnob = create("Frame", {
		Size = UDim2.new(0, 18, 0, 18),
		Position = default and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Parent = toggleBg,
	})
	addCorner(toggleKnob, 9)

	local state = default

	local btn = create("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		Parent = container,
	})

	btn.MouseButton1Click:Connect(function()
		state = not state
		smoothTween(toggleBg, {
			BackgroundColor3 = state and COLORS.ACCENT_GREEN or COLORS.BG_TRACK
		}, 0.25)
		smoothTween(toggleKnob, {
			Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
		}, 0.25)
		if callback then callback(state) end
	end)

	return container, function() return state end
end

-- ============================================================
-- PAGE: CAMERA
-- ============================================================
local cameraPage = createPage("Camera")
createSectionHeader(cameraPage, "Camera Controls", 0)

createSlider(cameraPage, "Field of View", CONFIG.MIN_FOV, CONFIG.MAX_FOV, CONFIG.DEFAULT_FOV, 1, function(v)
	smoothTween(camera, { FieldOfView = v }, 0.12)
end)

createSlider(cameraPage, "Camera Smoothness", 0, 100, 50, 2, function(v)
	-- Placeholder for custom cam smoothing
end)

createToggle(cameraPage, "Lock First Person", false, 3, function(state)
	if state then
		player.CameraMode = Enum.CameraMode.LockFirstPerson
	else
		player.CameraMode = Enum.CameraMode.Classic
	end
end)

createToggle(cameraPage, "Head Bobbing", false, 4, function(state)
	-- Placeholder for head bob effect
end)

-- ============================================================
-- PAGE: ENVIRONMENT
-- ============================================================
local envPage = createPage("Environment")
createSectionHeader(envPage, "Lighting & Time", 0)

createSlider(envPage, "Time of Day", CONFIG.MIN_CLOCK, CONFIG.MAX_CLOCK, CONFIG.DEFAULT_CLOCK, 1, function(v)
	smoothTween(Lighting, { ClockTime = v }, 0.3)
end)

createSlider(envPage, "Ambient Light", 0, 100, 50, 2, function(v)
	local m = v / 100
	Lighting.Ambient = Color3.fromRGB(m * 150, m * 150, m * 160)
end)

createSlider(envPage, "Brightness", 0, 4, 2, 3, function(v)
	Lighting.Brightness = v
end)

createSlider(envPage, "Fog Distance", 0, 100, 0, 4, function(v)
	local fogEnd = 10000 - (v / 100) * 9700
	Lighting.FogEnd = fogEnd
	Lighting.FogStart = fogEnd * 0.05
	Lighting.FogColor = Color3.fromRGB(200, 205, 215)
end)

createSlider(envPage, "Shadow Softness", 0, 2, 1, 5, function(v)
	Lighting.GlobalShadows = (v > 0)
end)

-- ============================================================
-- PAGE: WEATHER (particle-based effects)
-- ============================================================
local weatherPage = createPage("Weather")
createSectionHeader(weatherPage, "Weather Effects", 0)

-- Weather particle system
local weatherFolder = Instance.new("Folder")
weatherFolder.Name = "UnaibleLL_Weather"
weatherFolder.Parent = workspace

local rainPart = nil
local snowPart = nil
local rainActive = false
local snowActive = false

-- Helper to create weather attachment on camera
local function getWeatherPart()
	local existing = workspace:FindFirstChild("UnaibleLL_WeatherPart")
	if existing then return existing end

	local part = Instance.new("Part")
	part.Name = "UnaibleLL_WeatherPart"
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Size = Vector3.new(80, 1, 80)
	part.Parent = workspace
	return part
end

local weatherPart = getWeatherPart()

-- Rain emitter
local rainEmitter = Instance.new("ParticleEmitter")
rainEmitter.Name = "Rain"
rainEmitter.Texture = "rbxassetid://5765221959"
rainEmitter.Color = ColorSequence.new(Color3.fromRGB(180, 200, 220))
rainEmitter.Size = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.05),
	NumberSequenceKeypoint.new(1, 0.03),
})
rainEmitter.Lifetime = NumberRange.new(0.8, 1.5)
rainEmitter.Rate = 0
rainEmitter.Speed = NumberRange.new(60, 80)
rainEmitter.SpreadAngle = Vector2.new(5, 5)
rainEmitter.EmissionDirection = Enum.NormalId.Bottom
rainEmitter.Rotation = NumberRange.new(0, 0)
rainEmitter.RotSpeed = NumberRange.new(0, 0)
rainEmitter.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.3),
	NumberSequenceKeypoint.new(0.8, 0.3),
	NumberSequenceKeypoint.new(1, 1),
})
rainEmitter.LightEmission = 0.1
rainEmitter.Parent = weatherPart

-- Snow emitter
local snowEmitter = Instance.new("ParticleEmitter")
snowEmitter.Name = "Snow"
snowEmitter.Texture = "rbxassetid://241685484"
snowEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
snowEmitter.Size = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.15),
	NumberSequenceKeypoint.new(1, 0.1),
})
snowEmitter.Lifetime = NumberRange.new(3, 6)
snowEmitter.Rate = 0
snowEmitter.Speed = NumberRange.new(5, 12)
snowEmitter.SpreadAngle = Vector2.new(30, 30)
snowEmitter.EmissionDirection = Enum.NormalId.Bottom
snowEmitter.Rotation = NumberRange.new(0, 360)
snowEmitter.RotSpeed = NumberRange.new(-40, 40)
snowEmitter.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.1),
	NumberSequenceKeypoint.new(0.7, 0.1),
	NumberSequenceKeypoint.new(1, 1),
})
snowEmitter.LightEmission = 0.2
snowEmitter.Parent = weatherPart

-- Keep weather part above player
RunService.RenderStepped:Connect(function()
	if workspace.CurrentCamera ~= camera then
		camera = workspace.CurrentCamera
	end

	if rainActive or snowActive then
		local camPos = camera.CFrame.Position
		weatherPart.CFrame = CFrame.new(camPos + Vector3.new(0, 40, 0))
	end
end)

-- Rain toggle
createToggle(weatherPage, "Rain", false, 1, function(state)
	rainActive = state
	if state then
		smoothTween(Lighting, { FogEnd = 800, FogStart = 10 }, 1)
		Lighting.FogColor = Color3.fromRGB(140, 148, 160)
		rainEmitter.Rate = 300
	else
		smoothTween(Lighting, { FogEnd = 10000, FogStart = 0 }, 1)
		rainEmitter.Rate = 0
	end
end)

createSlider(weatherPage, "Rain Intensity", 50, 800, 300, 2, function(v)
	if rainActive then
		rainEmitter.Rate = v
	end
end)

-- Snow toggle
createToggle(weatherPage, "Snow", false, 3, function(state)
	snowActive = state
	if state then
		smoothTween(Lighting, { FogEnd = 1200, FogStart = 20 }, 1)
		Lighting.FogColor = Color3.fromRGB(220, 225, 235)
		snowEmitter.Rate = 150
	else
		smoothTween(Lighting, { FogEnd = 10000, FogStart = 0 }, 1)
		snowEmitter.Rate = 0
	end
end)

createSlider(weatherPage, "Snow Intensity", 30, 500, 150, 4, function(v)
	if snowActive then
		snowEmitter.Rate = v
	end
end)

-- Thunder flash effect
createToggle(weatherPage, "Lightning Flashes", false, 5, function(state)
	if state then
		task.spawn(function()
			while state do
				task.wait(math.random(3, 8))
				if not rainActive then break end
				local origBrightness = Lighting.Brightness
				Lighting.Brightness = 6
				task.wait(0.05)
				Lighting.Brightness = origBrightness
				task.wait(0.1)
				Lighting.Brightness = 4
				task.wait(0.05)
				Lighting.Brightness = origBrightness
			end
		end)
	end
end)

-- Wind speed (affects snow direction)
createSlider(weatherPage, "Wind Strength", 0, 50, 10, 6, function(v)
	snowEmitter.SpreadAngle = Vector2.new(v, v)
	rainEmitter.SpreadAngle = Vector2.new(v * 0.3, v * 0.3)
end)

-- ============================================================
-- PAGE: EFFECTS
-- ============================================================
local fxPage = createPage("Effects")
createSectionHeader(fxPage, "Screen Effects", 0)

-- Letterbox
local letterboxTop = create("Frame", {
	Size = UDim2.new(1, 0, 0, 0),
	Position = UDim2.new(0, 0, 0, 0),
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BorderSizePixel = 0,
	ZIndex = 100,
	Parent = screenGui,
})

local letterboxBot = create("Frame", {
	Size = UDim2.new(1, 0, 0, 0),
	Position = UDim2.new(0, 0, 1, 0),
	AnchorPoint = Vector2.new(0, 1),
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BorderSizePixel = 0,
	ZIndex = 100,
	Parent = screenGui,
})

createSlider(fxPage, "Cinematic Bars %", 0, 20, 0, 1, function(v)
	local s = v / 100
	smoothTween(letterboxTop, { Size = UDim2.new(1, 0, s, 0) }, 0.3)
	smoothTween(letterboxBot, { Size = UDim2.new(1, 0, s, 0) }, 0.3)
end)

-- Blur
local blurEffect = Instance.new("BlurEffect")
blurEffect.Size = 0
blurEffect.Parent = Lighting

createSlider(fxPage, "Background Blur", 0, 24, 0, 2, function(v)
	smoothTween(blurEffect, { Size = v }, 0.2)
end)

-- Color correction
local cc = Instance.new("ColorCorrectionEffect")
cc.Parent = Lighting

createSlider(fxPage, "Saturation", -100, 100, 0, 3, function(v)
	cc.Saturation = v / 100
end)

createSlider(fxPage, "Contrast", -100, 100, 0, 4, function(v)
	cc.Contrast = v / 100
end)

createSlider(fxPage, "Tint R", 0, 255, 255, 5, function(v)
	cc.TintColor = Color3.fromRGB(v, cc.TintColor.G * 255, cc.TintColor.B * 255)
end)

createSlider(fxPage, "Tint G", 0, 255, 255, 6, function(v)
	cc.TintColor = Color3.fromRGB(cc.TintColor.R * 255, v, cc.TintColor.B * 255)
end)

createSlider(fxPage, "Tint B", 0, 255, 255, 7, function(v)
	cc.TintColor = Color3.fromRGB(cc.TintColor.R * 255, cc.TintColor.G * 255, v)
end)

-- ============================================================
-- PAGE: SETTINGS
-- ============================================================
local settingsPage = createPage("Settings")
createSectionHeader(settingsPage, "General", 0)

-- GUI Background Transparency slider
createSlider(settingsPage, "GUI Transparency %", 0, 80, 0, 1, function(v)
	local t = v / 100
	CONFIG.BG_TRANSPARENCY = t
	mainFrame.BackgroundTransparency = t
	topBar.BackgroundTransparency = t
	sidebar.BackgroundTransparency = t
	contentArea.BackgroundTransparency = t
end)

-- FPS Counter (movable)
local fpsEnabled = false
local fpsLabel = nil
local fpsDragging = false
local fpsDragStart = nil
local fpsStartPos = nil

createToggle(settingsPage, "FPS Counter (draggable)", false, 2, function(state)
	fpsEnabled = state
	if state then
		if not fpsLabel then
			fpsLabel = create("TextLabel", {
				Name = "FPSCounter",
				Size = UDim2.new(0, 90, 0, 30),
				Position = UDim2.new(1, -100, 0, 10),
				BackgroundColor3 = COLORS.BG_CARD,
				BackgroundTransparency = 0.1,
				Text = "0 FPS",
				TextColor3 = COLORS.ACCENT_GREEN,
				TextSize = 13,
				Font = Enum.Font.GothamBold,
				ZIndex = 200,
				Parent = screenGui,
			})
			addCorner(fpsLabel, 8)
			addStroke(fpsLabel, COLORS.BORDER, 1, 0.4)

			-- Make FPS counter draggable
			fpsLabel.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					fpsDragging = true
					fpsDragStart = input.Position
					fpsStartPos = fpsLabel.Position
				end
			end)

			fpsLabel.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					fpsDragging = false
				end
			end)

			-- FPS update loop
			local frameCount = 0
			local lastTime = tick()
			RunService.RenderStepped:Connect(function()
				if not fpsLabel or not fpsLabel.Parent then return end
				frameCount = frameCount + 1
				if tick() - lastTime >= 1 then
					fpsLabel.Text = tostring(frameCount) .. " FPS"
					frameCount = 0
					lastTime = tick()
				end
			end)
		end
		fpsLabel.Visible = true
	else
		if fpsLabel then
			fpsLabel.Visible = false
		end
	end
end)

-- FPS drag handler (connected to global input)
UserInputService.InputChanged:Connect(function(input)
	if fpsDragging and fpsLabel and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - fpsDragStart
		fpsLabel.Position = UDim2.new(
			fpsStartPos.X.Scale, fpsStartPos.X.Offset + delta.X,
			fpsStartPos.Y.Scale, fpsStartPos.Y.Offset + delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		fpsDragging = false
	end
end)

-- Reset button
local resetBtn = create("TextButton", {
	Size = UDim2.new(1, 0, 0, 40),
	BackgroundColor3 = COLORS.DANGER,
	BackgroundTransparency = 0.85,
	BorderSizePixel = 0,
	Text = "Reset All to Default",
	TextColor3 = COLORS.DANGER,
	TextSize = 13,
	Font = Enum.Font.GothamBold,
	LayoutOrder = 10,
	AutoButtonColor = false,
	Parent = settingsPage,
})
addCorner(resetBtn, 10)
addStroke(resetBtn, COLORS.DANGER, 1, 0.6)

resetBtn.MouseEnter:Connect(function()
	smoothTween(resetBtn, { BackgroundTransparency = 0.6 }, 0.2)
end)
resetBtn.MouseLeave:Connect(function()
	smoothTween(resetBtn, { BackgroundTransparency = 0.85 }, 0.2)
end)

resetBtn.MouseButton1Click:Connect(function()
	camera.FieldOfView = CONFIG.DEFAULT_FOV
	Lighting.ClockTime = CONFIG.DEFAULT_CLOCK
	Lighting.Ambient = Color3.fromRGB(70, 70, 78)
	Lighting.FogEnd = 10000
	Lighting.FogStart = 0
	Lighting.Brightness = 2
	blurEffect.Size = 0
	cc.Saturation = 0
	cc.Contrast = 0
	cc.TintColor = Color3.fromRGB(255, 255, 255)
	letterboxTop.Size = UDim2.new(1, 0, 0, 0)
	letterboxBot.Size = UDim2.new(1, 0, 0, 0)
	rainEmitter.Rate = 0
	snowEmitter.Rate = 0
	rainActive = false
	snowActive = false
	mainFrame.BackgroundTransparency = 0
	topBar.BackgroundTransparency = 0
	sidebar.BackgroundTransparency = 0
	contentArea.BackgroundTransparency = 0
end)

-- ============================================================
-- TAB SWITCHING
-- ============================================================
local function switchTab(tabName)
	if tabName == currentTab then return end

	-- Deactivate old tab
	local old = navButtons[currentTab]
	if old then
		smoothTween(old.button, { BackgroundTransparency = 1 }, 0.25)
		old.accent.Visible = false
		old.nameLabel.TextColor3 = COLORS.TEXT_SECONDARY
	end
	if pages[currentTab] then
		pages[currentTab].Visible = false
	end

	currentTab = tabName

	-- Activate new tab
	local new = navButtons[currentTab]
	if new then
		new.button.BackgroundTransparency = 0
		smoothTween(new.button, { BackgroundColor3 = COLORS.BG_HOVER }, 0.25)
		new.accent.Visible = true
		new.nameLabel.TextColor3 = COLORS.TEXT_PRIMARY
	end
	if pages[currentTab] then
		pages[currentTab].Visible = true
	end
end

for name, data in pairs(navButtons) do
	data.button.MouseButton1Click:Connect(function()
		switchTab(name)
	end)
end

-- ============================================================
-- WINDOW DRAGGING
-- ============================================================
local dragging = false
local dragStart, startPos

topBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position
	end
end)

topBar.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end
end)

-- ============================================================
-- MINIMIZE / CLOSE / REOPEN
-- ============================================================
local isOpen = true
local fullSize = mainFrame.Size

minimizeBtn.MouseButton1Click:Connect(function()
	isOpen = not isOpen
	if isOpen then
		smoothTween(mainFrame, { Size = fullSize }, 0.4)
		task.delay(0.2, function()
			contentArea.Visible = true
			sidebar.Visible = true
		end)
		minimizeBtn.Text = "−"
	else
		contentArea.Visible = false
		sidebar.Visible = false
		smoothTween(mainFrame, { Size = UDim2.new(0, 700, 0, 48) }, 0.4)
		minimizeBtn.Text = "□"
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	smoothTween(mainFrame, {
		Size = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0),
	}, 0.35)
	task.delay(0.4, function()
		screenGui.Enabled = false
	end)
end)

-- F6 to reopen
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.F6 then
		if not screenGui.Enabled then
			screenGui.Enabled = true
			mainFrame.Size = fullSize
			mainFrame.Position = UDim2.new(0.5, -350, 0.5, -240)
			contentArea.Visible = true
			sidebar.Visible = true
			isOpen = true
			minimizeBtn.Text = "−"
		end
	end
end)

-- Apply defaults
camera.FieldOfView = CONFIG.DEFAULT_FOV