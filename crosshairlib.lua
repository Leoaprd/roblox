-- crosshairlib.lua
local CrosshairLib = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
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

function CrosshairLib:Init()
    -- Remove old GUI if already created
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

    -- Create crosshair lines
    createLine(0, -(g + l / 2), t, l)  -- Top
    createLine(0, (g + l / 2), t, l)   -- Bottom
    createLine(-(g + l / 2), 0, l, t)  -- Left
    createLine((g + l / 2), 0, l, t)   -- Right

    -- Enable spinning if applicable
    if settings.Spin then
        RunService:UnbindFromRenderStep("CrosshairSpin")
        RunService:BindToRenderStep("CrosshairSpin", Enum.RenderPriority.Last.Value, function(dt)
            if center then
                center.Rotation += settings.SpinSpeed * dt
            end
        end)
    else
        RunService:UnbindFromRenderStep("CrosshairSpin")
        if center then
            center.Rotation = 0
        end
    end
end

function CrosshairLib:SetColor(color)
    settings.Color = color
end

function CrosshairLib:SetThickness(value)
    settings.Thickness = value
end

function CrosshairLib:SetLength(value)
    settings.Length = value
end

function CrosshairLib:SetGap(value)
    settings.Gap = value
end

function CrosshairLib:SetSpin(value)
    settings.Spin = value
end

function CrosshairLib:SetSpinSpeed(value)
    settings.SpinSpeed = value
end

function CrosshairLib:Destroy()
    RunService:UnbindFromRenderStep("CrosshairSpin")

    if crosshairGui then
        crosshairGui:Destroy()
        crosshairGui = nil
        center = nil
        parts = {}
    end
end

return CrosshairLib
