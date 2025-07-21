local CrosshairLib = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local guiName = "CrosshairGui"
local crosshairGui = nil
local center = nil
local parts = {}

local settings = {
    Thickness = 2,
    Length = 10,
    Gap = 4,
    Color = Color3.new(1, 1, 1),
    Spin = false,
    SpinSpeed = 90,
}

local spinConnection

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

local function updatePartsAppearance()
    if not center then return end

    -- Update color
    for _, part in ipairs(parts) do
        part.BackgroundColor3 = settings.Color
    end

    -- Update positions and sizes
    local g = settings.Gap
    local l = settings.Length
    local t = settings.Thickness

    parts[1].Size = UDim2.new(0, t, 0, l)          -- Top line
    parts[1].Position = UDim2.new(0.5, 0, 0.5, -(g + l / 2))

    parts[2].Size = UDim2.new(0, t, 0, l)          -- Bottom line
    parts[2].Position = UDim2.new(0.5, 0, 0.5, g + l / 2)

    parts[3].Size = UDim2.new(0, l, 0, t)          -- Left line
    parts[3].Position = UDim2.new(0.5, -(g + l / 2), 0.5, 0)

    parts[4].Size = UDim2.new(0, l, 0, t)          -- Right line
    parts[4].Position = UDim2.new(0.5, g + l / 2, 0.5, 0)
end

local function startSpin()
    if spinConnection then
        spinConnection:Disconnect()
        spinConnection = nil
    end
    spinConnection = RunService:BindToRenderStep("CrosshairSpin", Enum.RenderPriority.Last.Value, function(dt)
        if center and settings.Spin then
            center.Rotation = (center.Rotation + settings.SpinSpeed * dt) % 360
        end
    end)
end

local function stopSpin()
    if spinConnection then
        spinConnection:Disconnect()
        spinConnection = nil
    end
    if center then
        center.Rotation = 0
    end
end

function CrosshairLib:Init()
    self:Destroy()

    crosshairGui = Instance.new("ScreenGui")
    crosshairGui.Name = guiName
    crosshairGui.ResetOnSpawn = false
    crosshairGui.Parent = player:WaitForChild("PlayerGui")

    center = Instance.new("Frame")
    center.Size = UDim2.new(0, 4, 0, 4)
    center.Position = UDim2.new(0.5, -2, 0.5, -2)
    center.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    center.BorderSizePixel = 0
    center.AnchorPoint = Vector2.new(0.5, 0.5)
    center.Name = "Center"
    center.Parent = crosshairGui

    clearParts()

    local g = settings.Gap
    local l = settings.Length
    local t = settings.Thickness

    createLine(0, -(g + l / 2), t, l)  -- Top
    createLine(0, (g + l / 2), t, l)   -- Bottom
    createLine(-(g + l / 2), 0, l, t)  -- Left
    createLine((g + l / 2), 0, l, t)   -- Right

    updatePartsAppearance()

    if settings.Spin then
        startSpin()
    else
        stopSpin()
    end
end

function CrosshairLib:SetColor(color)
    settings.Color = color
    if crosshairGui then
        updatePartsAppearance()
    end
end

function CrosshairLib:SetThickness(value)
    settings.Thickness = value
    if crosshairGui then
        updatePartsAppearance()
    end
end

function CrosshairLib:SetLength(value)
    settings.Length = value
    if crosshairGui then
        updatePartsAppearance()
    end
end

function CrosshairLib:SetGap(value)
    settings.Gap = value
    if crosshairGui then
        updatePartsAppearance()
    end
end

function CrosshairLib:SetSpin(value)
    settings.Spin = value
    if crosshairGui then
        if value then
            startSpin()
        else
            stopSpin()
        end
    end
end

function CrosshairLib:SetSpinSpeed(value)
    settings.SpinSpeed = value
    -- No need to restart spin, speed will be used automatically next frame
end

function CrosshairLib:Destroy()
    stopSpin()

    if crosshairGui then
        crosshairGui:Destroy()
        crosshairGui = nil
        center = nil
        clearParts()
    end
end

return CrosshairLib
