local BoxESP = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local localPlayer = Players.LocalPlayer

-- Settings
local ESPSettings = {
    Enabled = true,
    BoxColor = Color3.fromRGB(0, 255, 0),
    BoxThickness = 2,
    HealthBarWidth = 5,
    NameColor = Color3.fromRGB(255, 255, 255),
    SkeletonColor = Color3.fromRGB(0, 255, 0),
    SkeletonThickness = 1,
    ShowSkeleton = true,
}

-- R6 skeleton bones (joints)
local R6Bones = {
    {"Head", "Torso"},
    {"Torso", "Left Arm"},
    {"Left Arm", "Left Forearm"},
    {"Left Forearm", "Left Hand"},
    {"Torso", "Right Arm"},
    {"Right Arm", "Right Forearm"},
    {"Right Forearm", "Right Hand"},
    {"Torso", "Left Leg"},
    {"Left Leg", "Left Foot"},
    {"Torso", "Right Leg"},
    {"Right Leg", "Right Foot"},
}

-- R15 skeleton bones (more complex rig)
local R15Bones = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"},
}

-- Store Drawing objects per player
local trackedPlayers = {}

local function create(class, props)
    local obj = Drawing.new(class)
    for k, v in pairs(props) do
        obj[k] = v
    end
    return obj
end

local function addESP(player)
    local data = {}

    data.Box = create("Square", {
        Thickness = ESPSettings.BoxThickness,
        Color = ESPSettings.BoxColor,
        Filled = false,
        Visible = false,
        ZIndex = 2
    })

    data.Name = create("Text", {
        Color = ESPSettings.NameColor,
        Size = 16,
        Center = true,
        Outline = true,
        Visible = false,
        ZIndex = 2,
        Text = player.Name
    })

    data.HealthBarBG = create("Square", {
        Color = Color3.fromRGB(0, 0, 0),
        Thickness = 1,
        Filled = true,
        Visible = false,
        ZIndex = 2
    })

    data.HealthBar = create("Square", {
        Color = Color3.fromRGB(255, 0, 0),
        Thickness = 0,
        Filled = true,
        Visible = false,
        ZIndex = 3
    })

    -- For skeleton lines
    data.SkeletonLines = {}

    trackedPlayers[player] = data
end

local function removeESP(player)
    local data = trackedPlayers[player]
    if data then
        data.Box:Remove()
        data.Name:Remove()
        data.HealthBar:Remove()
        data.HealthBarBG:Remove()
        for _, line in pairs(data.SkeletonLines) do
            line:Remove()
        end
        trackedPlayers[player] = nil
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= localPlayer then
        addESP(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= localPlayer then
        addESP(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

local function getCharacterParts(character)
    local parts = {}
    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("BasePart") then
            table.insert(parts, part)
        end
    end
    return parts
end

local function isR15(character)
    -- Heuristic: R15 has LowerTorso and UpperTorso parts
    return character:FindFirstChild("LowerTorso") and character:FindFirstChild("UpperTorso")
end

local function drawSkeleton(char, data)
    local bonesTable = isR15(char) and R15Bones or R6Bones
    local lines = data.SkeletonLines

    -- Create lines if none exist
    if #lines == 0 then
        for _ = 1, #bonesTable do
            local line = create("Line", {
                Color = ESPSettings.SkeletonColor,
                Thickness = ESPSettings.SkeletonThickness,
                Transparency = 1,
                Visible = false,
                ZIndex = 3,
            })
            table.insert(lines, line)
        end
    end

    for i, bone in ipairs(bonesTable) do
        local fromPart = char:FindFirstChild(bone[1])
        local toPart = char:FindFirstChild(bone[2])

        local line = lines[i]

        if fromPart and toPart then
            local fromPos, fromVis = Camera:WorldToViewportPoint(fromPart.Position)
            local toPos, toVis = Camera:WorldToViewportPoint(toPart.Position)

            if fromVis and toVis then
                line.From = Vector2.new(fromPos.X, fromPos.Y)
                line.To = Vector2.new(toPos.X, toPos.Y)
                line.Visible = true
                line.Color = ESPSettings.SkeletonColor
                line.Thickness = ESPSettings.SkeletonThickness
            else
                line.Visible = false
            end
        else
            line.Visible = false
        end
    end
end

RunService.RenderStepped:Connect(function()
    if not ESPSettings.Enabled then
        for _, data in pairs(trackedPlayers) do
            data.Box.Visible = false
            data.Name.Visible = false
            data.HealthBar.Visible = false
            data.HealthBarBG.Visible = false
            for _, line in pairs(data.SkeletonLines) do
                line.Visible = false
            end
        end
        return
    end

    for player, data in pairs(trackedPlayers) do
        local char = player.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                local parts = getCharacterParts(char)

                local onScreen = false
                local minX, minY = math.huge, math.huge
                local maxX, maxY = -math.huge, -math.huge

                -- Calculate bounding box
                for _, part in ipairs(parts) do
                    local pos, vis = Camera:WorldToViewportPoint(part.Position)
                    if vis then
                        onScreen = true
                        if pos.X < minX then minX = pos.X end
                        if pos.Y < minY then minY = pos.Y end
                        if pos.X > maxX then maxX = pos.X end
                        if pos.Y > maxY then maxY = pos.Y end
                    end
                end

                if onScreen and minX < maxX and minY < maxY then
                    local width = maxX - minX
                    local height = maxY - minY

                    -- Box
                    data.Box.Size = Vector2.new(width, height)
                    data.Box.Position = Vector2.new(minX, minY)
                    data.Box.Color = ESPSettings.BoxColor
                    data.Box.Visible = true

                    -- Name tag
                    data.Name.Text = player.Name
                    data.Name.Position = Vector2.new(minX + width / 2, minY - 18)
                    data.Name.Visible = true

                    -- Health bar left side
                    data.HealthBarBG.Size = Vector2.new(ESPSettings.HealthBarWidth, height)
                    data.HealthBarBG.Position = Vector2.new(minX - ESPSettings.HealthBarWidth - 5, minY)
                    data.HealthBarBG.Visible = true

                    local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                    data.HealthBar.Size = Vector2.new(ESPSettings.HealthBarWidth, height * healthPercent)
                    data.HealthBar.Position = Vector2.new(data.HealthBarBG.Position.X, minY + height * (1 - healthPercent))
                    data.HealthBar.Visible = true

                    -- Skeleton
                    if ESPSettings.ShowSkeleton then
                        drawSkeleton(char, data)
                    else
                        for _, line in pairs(data.SkeletonLines) do
                            line.Visible = false
                        end
                    end
                else
                    -- Hide all if offscreen
                    data.Box.Visible = false
                    data.Name.Visible = false
                    data.HealthBar.Visible = false
                    data.HealthBarBG.Visible = false
                    for _, line in pairs(data.SkeletonLines) do
                        line.Visible = false
                    end
                end
            else
                -- Hide if no humanoid
                data.Box.Visible = false
                data.Name.Visible = false
                data.HealthBar.Visible = false
                data.HealthBarBG.Visible = false
                for _, line in pairs(data.SkeletonLines) do
                    line.Visible = false
                end
            end
        else
            -- Hide if no character
            data.Box.Visible = false
            data.Name.Visible = false
            data.HealthBar.Visible = false
            data.HealthBarBG.Visible = false
            for _, line in pairs(data.SkeletonLines) do
                line.Visible = false
            end
        end
    end
end)

-- API functions
function BoxESP:SetEnabled(state)
    ESPSettings.Enabled = state
end

function BoxESP:SetBoxColor(color)
    ESPSettings.BoxColor = color
    for _, data in pairs(trackedPlayers) do
        data.Box.Color = color
    end
end

function BoxESP:SetHealthBarWidth(width)
    ESPSettings.HealthBarWidth = width
end

function BoxESP:SetNameColor(color)
    ESPSettings.NameColor = color
    for _, data in pairs(trackedPlayers) do
        data.Name.Color = color
    end
end

function BoxESP:SetSkeletonColor(color)
    ESPSettings.SkeletonColor = color
end

function BoxESP:SetSkeletonThickness(thickness)
    ESPSettings.SkeletonThickness = thickness
end

function BoxESP:SetShowSkeleton(state)
    ESPSettings.ShowSkeleton = state
end

return BoxESP
