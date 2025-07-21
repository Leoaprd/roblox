local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "CrosshairGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local center = Instance.new("Frame")
center.Size = UDim2.new(0, 4, 0, 4)
center.Position = UDim2.new(0.5, -2, 0.5, -2)
center.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
center.BorderSizePixel = 0
center.AnchorPoint = Vector2.new(0.5, 0.5)
center.Name = "Center"
center.Parent = gui

local parts = {}

local settings = {
    Thickness = 2,
    Length = 10,
    Gap = 4,
    Color = Color3.new(1, 1, 1),
    Spin = false,
    SpinSpeed = 90,
}

local function clearParts()
    for _, v in ipairs(parts) do
        v:Destroy()
    end
    parts = {}
end

local function createLine(offsetX, offsetY, sizeX, sizeY)
    local part = Instance.new("Frame")
    part.Size = UDim2.new(0, sizeX, 0, sizeY)
    part.Position = UDim2.new(0.5, offsetX, 0.5, offsetY)
    part.AnchorPoint = Vector2.new(0.5, 0.5)
    part.BackgroundColor3 = settings.Color
    part.BorderSizePixel = 0
    part.Parent = center
    table.insert(parts, part)
end

local function drawCrosshair()
    clearParts()

    local g = settings.Gap
    local l = settings.Length
    local t = settings.Thickness

    -- Top, Bottom, Left, Right
    createLine(0, -(g + l / 2), t, l)
    createLine(0, g + l / 2, t, l)
    createLine(-(g + l / 2), 0, l, t)
    createLine(g + l / 2, 0, l, t)

    if settings.Spin then
        RunService:UnbindFromRenderStep("CrosshairSpin")
        RunService:BindToRenderStep("CrosshairSpin", Enum.RenderPriority.Last.Value, function(dt)
            center.Rotation += settings.SpinSpeed * dt
        end)
    else
        RunService:UnbindFromRenderStep("CrosshairSpin")
        center.Rotation = 0
    end
end

-- CONFIGURE YOUR CROSSHAIR SETTINGS HERE
settings.Color = Color3.new(1, 0, 0) -- Red
settings.Thickness = 3
settings.Length = 12
settings.Gap = 5
settings.Spin = true
settings.SpinSpeed = 180

-- Draw it
drawCrosshair()
