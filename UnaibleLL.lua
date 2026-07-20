-- ============================================================
-- UnaibleLL - Client Visual Customization Suite v3
-- Clean white theme | F1 toggle | Auto-opens with animation
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
-- COLORS
-- ============================================================
local COLORS = {
	BG_MAIN = Color3.fromRGB(240, 242, 248),
	BG_SIDEBAR = Color3.fromRGB(250, 251, 255),
	BG_CONTENT = Color3.fromRGB(245, 247, 252),
	BG_CARD = Color3.fromRGB(255, 255, 255),
	BG_HOVER = Color3.fromRGB(232, 236, 248),
	BG_TRACK = Color3.fromRGB(210, 215, 228),
	ACCENT = Color3.fromRGB(80, 120, 255),
	ACCENT_GREEN = Color3.fromRGB(60, 190, 110),
	TEXT_PRIMARY = Color3.fromRGB(30, 35, 55),
	TEXT_SECONDARY = Color3.fromRGB(100, 108, 130),
	BORDER = Color3.fromRGB(215, 220, 235),
	TOPBAR = Color3.fromRGB(255, 255, 255),
	SCROLLBAR = Color3.fromRGB(180, 188, 210),
	DANGER = Color3.fromRGB(220, 70, 80),
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

local function addCorner(p, r)
	return create("UICorner", {CornerRadius = UDim.new(0, r or 10), Parent = p})
end

local function addStroke(p, c, th, tr)
	return create("UIStroke", {Color = c or COLORS.BORDER, Thickness = th or 1, Transparency = tr or 0, Parent = p})
end

local function addPadding(p, t, b, l, r)
	return create("UIPadding", {PaddingTop=UDim.new(0,t or 0), PaddingBottom=UDim.new(0,b or 0), PaddingLeft=UDim.new(0,l or 0), PaddingRight=UDim.new(0,r or 0), Parent=p})
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
-- MAIN FRAME (starts invisible for open anim)
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
addCorner(mainFrame, 14)
addStroke(mainFrame, COLORS.BORDER, 1, 0.3)

-- ============================================================
-- TOP BAR
-- ============================================================
local topBar = create("Frame", {
	Name = "TopBar",
	Size = UDim2.new(1, 0, 0, 48),
	BackgroundColor3 = COLORS.TOPBAR,
	BorderSizePixel = 0,
	Parent = mainFrame,
})

create("Frame", {
	Size = UDim2.new(1, 0, 0, 1),
	Position = UDim2.new(0, 0, 1, -1),
	BackgroundColor3 = COLORS.BORDER,
	BorderSizePixel = 0,
	Parent = topBar,
})

create("TextLabel", {
	Size = UDim2.new(0, 32, 0, 48),
	Position = UDim2.new(0, 16, 0, 0),
	BackgroundTransparency = 1,
	Text = "∞",
	TextColor3 = COLORS.ACCENT,
	TextSize = 22,
	Font = Enum.Font.GothamBold,
	Parent = topBar,
})

create("TextLabel", {
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

local badge = create("TextLabel", {
	Size = UDim2.new(0, 36, 0, 18),
	Position = UDim2.new(0, 152, 0, 15),
	BackgroundColor3 = COLORS.ACCENT,
	BackgroundTransparency = 0.85,
	Text = "v3",
	TextColor3 = COLORS.ACCENT,
	TextSize = 10,
	Font = Enum.Font.GothamBold,
	Parent = topBar,
})
addCorner(badge, 4)

create("TextLabel", {
	Size = UDim2.new(0, 60, 0, 48),
	Position = UDim2.new(1, -75, 0, 0),
	BackgroundTransparency = 1,
	Text = "[F1]",
	TextColor3 = COLORS.TEXT_SECONDARY,
	TextSize = 11,
	Font = Enum.Font.GothamMedium,
	Parent = topBar,
})

-- ============================================================
-- SIDEBAR CONTAINER
-- ============================================================
local sidebarFrame = create("Frame", {
	Name = "Sidebar",
	Size = UDim2.new(0, 170, 1, -48),
	Position = UDim2.new(0, 0, 0, 48),
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

local sidebarInner = create("Frame", {
	Name = "Inner",
	Size = UDim2.new(1, -20, 1, -28),
	Position = UDim2.new(0, 10, 0, 14),
	BackgroundTransparency = 1,
	Parent = sidebarFrame,
})

create("UIListLayout", {
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 4),
	Parent = sidebarInner,
})

-- ============================================================
-- CONTENT AREA
-- ============================================================
local contentArea = create("Frame", {
	Name = "Content",
	Size = UDim2.new(1, -170, 1, -48),
	Position = UDim2.new(0, 170, 0, 48),
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
	create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 10),
		Parent = page,
	})
	allPages[name] = page
	return page
end

local function switchToTab(name)
	if activeTab == name then return end

	-- Hide all pages, deactivate all buttons
	for tabName, page in pairs(allPages) do
		page.Visible = false
	end
	for tabName, info in pairs(allNavBtns) do
		info.accent.Visible = false
		info.label.TextColor3 = COLORS.TEXT_SECONDARY
		smoothTween(info.btn, {BackgroundTransparency = 1}, 0.2)
	end

	-- Activate selected
	activeTab = name
	if allPages[name] then
		allPages[name].Visible = true
	end
	if allNavBtns[name] then
		allNavBtns[name].accent.Visible = true
		allNavBtns[name].label.TextColor3 = COLORS.TEXT_PRIMARY
		allNavBtns[name].btn.BackgroundTransparency = 0
		allNavBtns[name].btn.BackgroundColor3 = COLORS.BG_HOVER
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

	create("TextLabel", {
		Size = UDim2.new(0, 24, 1, 0),
		Position = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text = icon,
		TextSize = 14,
		Font = Enum.Font.Gotham,
		TextColor3 = COLORS.TEXT_PRIMARY,
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

	allNavBtns[name] = {btn = btn, accent = accent, label = lbl}

	btn.MouseEnter:Connect(function()
		if activeTab ~= name then
			smoothTween(btn, {BackgroundTransparency = 0.5}, 0.15)
		end
	end)
	btn.MouseLeave:Connect(function()
		if activeTab ~= name then
			smoothTween(btn, {BackgroundTransparency = 1}, 0.15)
		end
	end)
	btn.MouseButton1Click:Connect(function()
		switchToTab(name)
	end)
end

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

local function createSlider(parent, label, min, max, default, layoutOrder, callback)
	local container = create("Frame", {
		Size = UDim2.new(1, 0, 0, 64),
		BackgroundColor3 = COLORS.BG_CARD,
		BorderSizePixel = 0,
		LayoutOrder = layoutOrder,
		Parent = parent,
	})
	addCorner(container, 10)
	addStroke(container, COLORS.BORDER, 1, 0.5)

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

	local valueLbl = create("TextLabel", {
		Size = UDim2.new(0.35, 0, 0, 22),
		Position = UDim2.new(0.62, 0, 0, 8),
		BackgroundTransparency = 1,
		Text = tostring(default),
		TextColor3 = COLORS.ACCENT,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = container,
	})

	local track = create("Frame", {
		Size = UDim2.new(1, -32, 0, 6),
		Position = UDim2.new(0, 16, 0, 44),
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
		Size = UDim2.new(0, 16, 0, 16),
		Position = UDim2.new(initFill, -8, 0.5, -8),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = track,
	})
	addCorner(knob, 8)
	addStroke(knob, COLORS.ACCENT, 2, 0)

	local isDragging = false

	local function update(inputX)
		local p = track.AbsolutePosition.X
		local s = track.AbsoluteSize.X
		local rel = math.clamp((inputX - p) / s, 0, 1)
		local val = min + (max - min) * rel
		if (max - min) <= 10 then
			val = math.floor(val * 10 + 0.5) / 10
		else
			val = math.floor(val + 0.5)
		end
		local dr = math.clamp((val - min) / (max - min), 0, 1)
		smoothTween(fill, {Size = UDim2.new(dr, 0, 1, 0)}, 0.05)
		smoothTween(knob, {Position = UDim2.new(dr, -8, 0.5, -8)}, 0.05)
		valueLbl.Text = tostring(val)
		if callback then callback(val) end
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = true
			update(input.Position.X)
		end
	end)
	knob.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = true
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			update(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = false
		end
	end)

	return container
end

local function createToggle(parent, label, default, layoutOrder, callback)
	local container = create("Frame", {
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
		smoothTween(toggleBg, {BackgroundColor3 = state and COLORS.ACCENT_GREEN or COLORS.BG_TRACK}, 0.25)
		smoothTween(toggleKnob, {Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)}, 0.25)
		if callback then callback(state) end
	end)

	return container
end

-- ============================================================
-- CREATE NAV BUTTONS (order matters)
-- ============================================================
createNavButton("🎥", "Camera", 1)
createNavButton("🌤️", "Environment", 2)
createNavButton("🌧️", "Weather", 3)
createNavButton("🎬", "Effects", 4)
createNavButton("👤", "Player", 5)
createNavButton("⚙️", "Settings", 6)

-- ============================================================
-- PAGE: CAMERA
-- ============================================================
local camPage = createPage("Camera")
createHeader(camPage, "Camera Controls", 0)

createSlider(camPage, "Field of View", CONFIG.MIN_FOV, CONFIG.MAX_FOV, CONFIG.DEFAULT_FOV, 1, function(v)
	smoothTween(camera, {FieldOfView = v}, 0.1)
end)

createSlider(camPage, "Zoom Distance", 5, 100, 20, 2, function(v)
	player.CameraMaxZoomDistance = v
end)

createSlider(camPage, "Min Zoom", 0.5, 20, 0.5, 3, function(v)
	player.CameraMinZoomDistance = v
end)

createToggle(camPage, "Shift Lock Style", false, 4, function(state)
	player.DevEnableMouseLock = state
end)

-- ============================================================
-- PAGE: ENVIRONMENT
-- ============================================================
local envPage = createPage("Environment")
createHeader(envPage, "Lighting & Atmosphere", 0)

createSlider(envPage, "Time of Day", CONFIG.MIN_CLOCK, CONFIG.MAX_CLOCK, CONFIG.DEFAULT_CLOCK, 1, function(v)
	smoothTween(Lighting, {ClockTime = v}, 0.3)
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

createSlider(envPage, "Exposure", -3, 3, 0, 5, function(v)
	Lighting.ExposureCompensation = v
end)

createToggle(envPage, "Global Shadows", true, 6, function(state)
	Lighting.GlobalShadows = state
end)

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

-- Rain
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

-- Snow
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

-- Leaves / dust
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

local rainActive = false
local snowActive = false
local dustActive = false
local lightningActive = false

RunService.RenderStepped:Connect(function()
	if workspace.CurrentCamera ~= camera then
		camera = workspace.CurrentCamera
	end
	if rainActive or snowActive or dustActive then
		weatherPart.CFrame = CFrame.new(camera.CFrame.Position + Vector3.new(0, 40, 0))
	end
end)

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
end)

createSlider(wthPage, "Rain Intensity", 50, 800, 300, 2, function(v)
	if rainActive then rainEmitter.Rate = v end
end)

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
end)

createSlider(wthPage, "Snow Intensity", 30, 500, 150, 4, function(v)
	if snowActive then snowEmitter.Rate = v end
end)

createToggle(wthPage, "Dust / Leaves", false, 5, function(state)
	dustActive = state
	dustEmitter.Rate = state and 50 or 0
end)

createToggle(wthPage, "Lightning Flashes", false, 6, function(state)
	lightningActive = state
	if state then
		task.spawn(function()
			while lightningActive and rainActive do
				task.wait(math.random(3, 8))
				if not lightningActive or not rainActive then break end
				local orig = Lighting.Brightness
				Lighting.Brightness = 6
				task.wait(0.05)
				Lighting.Brightness = orig
				task.wait(0.1)
				Lighting.Brightness = 4
				task.wait(0.05)
				Lighting.Brightness = orig
			end
		end)
	end
end)

createSlider(wthPage, "Wind Strength", 0, 50, 10, 7, function(v)
	snowEmitter.SpreadAngle = Vector2.new(v, v)
	rainEmitter.SpreadAngle = Vector2.new(v * 0.3, v * 0.3)
	dustEmitter.Speed = NumberRange.new(v * 0.5, v)
end)

-- ============================================================
-- PAGE: EFFECTS
-- ============================================================
local fxPage = createPage("Effects")
createHeader(fxPage, "Screen Effects", 0)

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
	smoothTween(letterboxTop, {Size = UDim2.new(1, 0, s, 0)}, 0.3)
	smoothTween(letterboxBot, {Size = UDim2.new(1, 0, s, 0)}, 0.3)
end)

local blurEffect = Instance.new("BlurEffect")
blurEffect.Size = 0
blurEffect.Parent = Lighting

createSlider(fxPage, "Background Blur", 0, 24, 0, 2, function(v)
	smoothTween(blurEffect, {Size = v}, 0.2)
end)

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

-- Bloom
local bloom = Instance.new("BloomEffect")
bloom.Intensity = 0
bloom.Size = 24
bloom.Threshold = 1
bloom.Parent = Lighting

createSlider(fxPage, "Bloom Intensity", 0, 100, 0, 8, function(v)
	bloom.Intensity = v / 100
	bloom.Threshold = 1 - (v / 200)
end)

-- Sun Rays
local sunRays = Instance.new("SunRaysEffect")
sunRays.Intensity = 0
sunRays.Spread = 0.5
sunRays.Parent = Lighting

createSlider(fxPage, "Sun Rays", 0, 100, 0, 9, function(v)
	sunRays.Intensity = v / 100
	sunRays.Spread = 0.2 + (v / 100) * 0.8
end)

-- ============================================================
-- PAGE: PLAYER
-- ============================================================
local playerPage = createPage("Player")
createHeader(playerPage, "Player Modifiers", 0)

createSlider(playerPage, "Walk Speed", 16, 200, 16, 1, function(v)
	local char = player.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = v end
	end
end)

createSlider(playerPage, "Jump Power", 50, 300, 50, 2, function(v)
	local char = player.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.UseJumpPower = true
			hum.JumpPower = v
		end
	end
end)

createSlider(playerPage, "Hip Height", 0, 10, 2, 3, function(v)
	local char = player.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then hum.HipHeight = v end
	end
end)

createToggle(playerPage, "Noclip", false, 4, function(state)
	if state then
		RunService:BindToRenderStep("Noclip", 1, function()
			local char = player.Character
			if char then
				for _, part in pairs(char:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = false
					end
				end
			end
		end)
	else
		RunService:UnbindFromRenderStep("Noclip")
	end
end)

createToggle(playerPage, "Infinite Jump", false, 5, function(state)
	if state then
		UserInputService.JumpRequest:Connect(function()
			local char = player.Character
			if char then
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
			end
		end)
	end
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
end)

-- Movable FPS counter
local fpsLabel = nil
local fpsDragging = false
local fpsDragStart = nil
local fpsStartPos = nil

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

			local fc = 0
			local lt = tick()
			RunService.RenderStepped:Connect(function()
				if not fpsLabel or not fpsLabel.Parent then return end
				fc = fc + 1
				if tick() - lt >= 1 then
					if fpsLabel.Visible then fpsLabel.Text = fc .. " FPS" end
					fc = 0
					lt = tick()
				end
			end)
		end
		fpsLabel.Visible = true
	else
		if fpsLabel then fpsLabel.Visible = false end
	end
end)

-- FPS drag
UserInputService.InputChanged:Connect(function(input)
	if fpsDragging and fpsLabel then
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - fpsDragStart
			fpsLabel.Position = UDim2.new(fpsStartPos.X.Scale, fpsStartPos.X.Offset + delta.X, fpsStartPos.Y.Scale, fpsStartPos.Y.Offset + delta.Y)
		end
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		fpsDragging = false
	end
end)

createToggle(setPage, "Show Coordinates", false, 3, function(state)
	local existing = screenGui:FindFirstChild("CoordsLabel")
	if state then
		if not existing then
			local coordLbl = create("TextLabel", {
				Name = "CoordsLabel",
				Size = UDim2.new(0, 200, 0, 24),
				Position = UDim2.new(0, 10, 1, -34),
				BackgroundColor3 = COLORS.BG_CARD,
				BackgroundTransparency = 0.2,
				Text = "X: 0  Y: 0  Z: 0",
				TextColor3 = COLORS.TEXT_PRIMARY,
				TextSize = 11,
				Font = Enum.Font.GothamMedium,
				ZIndex = 200,
				Parent = screenGui,
			})
			addCorner(coordLbl, 6)
			RunService.RenderStepped:Connect(function()
				if coordLbl and coordLbl.Parent and coordLbl.Visible then
					local char = player.Character
					if char and char:FindFirstChild("HumanoidRootPart") then
						local pos = char.HumanoidRootPart.Position
						coordLbl.Text = string.format("X: %.0f  Y: %.0f  Z: %.0f", pos.X, pos.Y, pos.Z)
					end
				end
			end)
		end
	else
		if existing then existing:Destroy() end
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
	Parent = setPage,
})
addCorner(resetBtn, 10)
addStroke(resetBtn, COLORS.DANGER, 1, 0.6)

resetBtn.MouseEnter:Connect(function()
	smoothTween(resetBtn, {BackgroundTransparency = 0.6}, 0.2)
end)
resetBtn.MouseLeave:Connect(function()
	smoothTween(resetBtn, {BackgroundTransparency = 0.85}, 0.2)
end)

resetBtn.MouseButton1Click:Connect(function()
	camera.FieldOfView = CONFIG.DEFAULT_FOV
	Lighting.ClockTime = CONFIG.DEFAULT_CLOCK
	Lighting.Ambient = Color3.fromRGB(70, 70, 78)
	Lighting.FogEnd = 10000
	Lighting.FogStart = 0
	Lighting.Brightness = 2
	Lighting.ExposureCompensation = 0
	blurEffect.Size = 0
	cc.Saturation = 0
	cc.Contrast = 0
	cc.TintColor = Color3.fromRGB(255, 255, 255)
	bloom.Intensity = 0
	sunRays.Intensity = 0
	letterboxTop.Size = UDim2.new(1, 0, 0, 0)
	letterboxBot.Size = UDim2.new(1, 0, 0, 0)
	rainEmitter.Rate = 0
	snowEmitter.Rate = 0
	dustEmitter.Rate = 0
	rainActive = false
	snowActive = false
	dustActive = false
	lightningActive = false
	mainFrame.BackgroundTransparency = 0
	topBar.BackgroundTransparency = 0
	sidebarFrame.BackgroundTransparency = 0
	contentArea.BackgroundTransparency = 0
end)

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
		mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-- ============================================================
-- F1 TOGGLE + OPEN ANIMATION ON START
-- ============================================================
local guiOpen = false
local FULL_SIZE = UDim2.new(0, 700, 0, 480)
local FULL_POS = UDim2.new(0.5, -350, 0.5, -240)

local function openGui()
	guiOpen = true
	mainFrame.Visible = true
	mainFrame.Size = UDim2.new(0, 0, 0, 0)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	smoothTween(mainFrame, {Size = FULL_SIZE, Position = FULL_POS}, 0.5)
end

local function closeGui()
	guiOpen = false
	smoothTween(mainFrame, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}, 0.35)
	task.delay(0.4, function()
		if not guiOpen then mainFrame.Visible = false end
	end)
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.F1 then
		if guiOpen then closeGui() else openGui() end
	end
end)

-- Set default tab and open GUI on load
switchToTab("Camera")
task.wait(0.5)
openGui()

-- Apply defaults
camera.FieldOfView = CONFIG.DEFAULT_FOV
