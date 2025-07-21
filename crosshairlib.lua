-- CrosshairModule.lua
local CrosshairModule = {}

-- Services
local TweenService = game:GetService("TweenService")

-- Settings with defaults
CrosshairModule.Settings = {
    Style = "Cross", -- Dot, Square, Cross, Diamond, Arrow
    Color = Color3.new(1, 1, 1), -- white
    Size = 20, -- length/width of elements
    Thickness = 2, -- thickness of lines
    Spin = false, -- whether crosshair spins
    SpinSpeed = 90, -- degrees per second
}

-- Internal variables
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local crosshairGui = nil
local spinTween = nil

-- Helper to clear previous crosshair
local function clearCrosshair()
    if crosshairGui then
        crosshairGui:Destroy()
        crosshairGui = nil
    end
end

-- Create a Frame with common properties
local function createFrame(size, position)
    local frame = Instance.new("Frame")
    frame.Size = size
    frame.Position = position
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundColor3 = CrosshairModule.Settings.Color
    frame.BorderSizePixel = 0
    return frame
end

-- Create each style
local function createDot()
    local dot = createFrame(
        UDim2.new(0, CrosshairModule.Settings.Thickness, 0, CrosshairModule.Settings.Thickness),
        UDim2.new(0.5, 0, 0.5, 0)
    )
    dot.BackgroundTransparency = 0
    return {dot}
end

local function createSquare()
    local size = CrosshairModule.Settings.Size
    local t = CrosshairModule.Settings.Thickness
    local square = createFrame(UDim2.new(0, size, 0, size), UDim2.new(0.5, 0, 0.5, 0))
    square.BackgroundTransparency = 1

    -- Four lines forming a square border
    local top = createFrame(UDim2.new(1, 0, 0, t), UDim2.new(0.5, 0, 0, t/2))
    local bottom = createFrame(UDim2.new(1, 0, 0, t), UDim2.new(0.5, 0, 1, -t/2))
    local left = createFrame(UDim2.new(0, t, 1, 0), UDim2.new(0, t/2, 0.5, 0))
    local right = createFrame(UDim2.new(0, t, 1, 0), UDim2.new(1, -t/2, 0.5, 0))

    top.Parent = square
    bottom.Parent = square
    left.Parent = square
    right.Parent = square

    return {square}
end

local function createCross()
    local size = CrosshairModule.Settings.Size
    local t = CrosshairModule.Settings.Thickness

    -- Horizontal line
    local hLine = createFrame(UDim2.new(0, size, 0, t), UDim2.new(0.5, 0, 0.5, 0))
    -- Vertical line
    local vLine = createFrame(UDim2.new(0, t, 0, size), UDim2.new(0.5, 0, 0.5, 0))

    return {hLine, vLine}
end

local function createDiamond()
    local size = CrosshairModule.Settings.Size
    local t = CrosshairModule.Settings.Thickness
    local diamond = createFrame(UDim2.new(0, size, 0, size), UDim2.new(0.5, 0, 0.5, 0))
    diamond.BackgroundTransparency = 1

    -- Four lines rotated to form a diamond
    local top = createFrame(UDim2.new(0, t, 0, size/2), UDim2.new(0.5, 0, 0, size/4))
    top.Rotation = 45
    local right = createFrame(UDim2.new(0, t, 0, size/2), UDim2.new(1, -size/4, 0.5, 0))
    right.Rotation = 45
    local bottom = createFrame(UDim2.new(0, t, 0, size/2), UDim2.new(0.5, 0, 1, -size/4))
    bottom.Rotation = 45
    local left = createFrame(UDim2.new(0, t, 0, size/2), UDim2.new(0, size/4, 0.5, 0))
    left.Rotation = 45

    top.Parent = diamond
    right.Parent = diamond
    bottom.Parent = diamond
    left.Parent = diamond

    return {diamond}
end

local function createArrow()
    local size = CrosshairModule.Settings.Size
    local t = CrosshairModule.Settings.Thickness
    local arrow = createFrame(UDim2.new(0, size, 0, size), UDim2.new(0.5, 0, 0.5, 0))
    arrow.BackgroundTransparency = 1

    -- Create a simple arrow pointing up
    local shaft = createFrame(UDim2.new(0, t, 0, size * 0.7), UDim2.new(0.5, 0, 0.75, 0))
    local headLeft = createFrame(UDim2.new(0, t * 1.5, 0, t), UDim2.new(0.5, -t * 1.5, 0.25, 0))
    headLeft.Rotation = 45
    local headRight = createFrame(UDim2.new(0, t * 1.5, 0, t), UDim2.new(0.5, t * 1.5, 0.25, 0))
    headRight.Rotation = -45

    shaft.Parent = arrow
    headLeft.Parent = arrow
    headRight.Parent = arrow

    return {arrow}
end

-- Create crosshair elements based on current style
local function createCrosshairElements()
    if CrosshairModule.Settings.Style == "Dot" then
        return createDot()
    elseif CrosshairModule.Settings.Style == "Square" then
        return createSquare()
    elseif CrosshairModule.Settings.Style == "Cross" then
        return createCross()
    elseif CrosshairModule.Settings.Style == "Diamond" then
        return createDiamond()
    elseif CrosshairModule.Settings.Style == "Arrow" then
        return createArrow()
    else
        return createCross() -- fallback default
    end
end

-- Initialize crosshair GUI
function CrosshairModule:Init()
    clearCrosshair()

    crosshairGui = Instance.new("ScreenGui")
    crosshairGui.Name = "CustomCrosshair"
    crosshairGui.Parent = playerGui

    local container = Instance.new("Frame")
    container.Name = "Container"
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.Position = UDim2.new(0.5, 0, 0.5, 0)
    container.Size = UDim2.new(0, CrosshairModule.Settings.Size * 2, 0, CrosshairModule.Settings.Size * 2)
    container.BackgroundTransparency = 1
    container.Parent = crosshairGui

    local parts = createCrosshairElements()
    for _, part in pairs(parts) do
        part.Parent = container
    end

    -- Setup spinning if enabled
    if CrosshairModule.Settings.Spin then
        if spinTween then spinTween:Cancel() end
        spinTween = TweenService:Create(container, TweenInfo.new(360 / CrosshairModule.Settings.SpinSpeed, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Rotation = 360})
        spinTween:Play()
    end
end

-- Change style and update crosshair
function CrosshairModule:SetStyle(style)
    CrosshairModule.Settings.Style = style
    CrosshairModule:Init()
end

-- Change color and update crosshair
function CrosshairModule:SetColor(color)
    CrosshairModule.Settings.Color = color
    CrosshairModule:Init()
end

-- Change size and update crosshair
function CrosshairModule:SetSize(size)
    CrosshairModule.Settings.Size = size
    CrosshairModule:Init()
end

-- Change thickness and update crosshair
function CrosshairModule:SetThickness(thickness)
    CrosshairModule.Settings.Thickness = thickness
    CrosshairModule:Init()
end

-- Toggle spinning
function CrosshairModule:SetSpin(enabled)
    CrosshairModule.Settings.Spin = enabled
    CrosshairModule:Init()
end

-- Set spinning speed (degrees per second)
function CrosshairModule:SetSpinSpeed(speed)
    CrosshairModule.Settings.SpinSpeed = speed
    CrosshairModule:Init()
end

-- Remove crosshair
function CrosshairModule:Destroy()
    if spinTween then
        spinTween:Cancel()
    end
    clearCrosshair()
end

return CrosshairModule
