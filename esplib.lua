local ESP = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local localPlayer = Players.LocalPlayer

-- BoxESP internal settings and data
local BoxESP = {}

BoxESP.ESPSettings = {
    Enabled = true,
    BoxColor = Color3.fromRGB(0, 255, 0),
    BoxThickness = 2,
    HealthBarWidth = 5,
    NameColor = Color3.fromRGB(255, 255, 255),
    SkeletonColor = Color3.fromRGB(0, 255, 0),
    SkeletonThickness = 1,
    ShowSkeleton = true,
}

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

BoxESP.trackedPlayers = {}

local function create(class, props)
    local obj = Drawing.new(class)
    for k, v in pairs(props) do
        obj[k] = v
    end
    return obj
end

function BoxESP:addESP(player)
    local data = {}

    data.Box = create("Square", {
        Thickness = self.ESPSettings.BoxThickness,
        Color = self.ESPSettings.BoxColor,
        Filled = false,
        Visible = false,
        ZIndex = 2
    })

    data.Name = create("Text", {
        Color = self.ESPSettings.NameColor,
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

    data.SkeletonLines = {}

    self.trackedPlayers[player] = data
end

function BoxESP:removeESP(player)
    local data = self.trackedPlayers[player]
    if data then
        data.Box:Remove()
        data.Name:Remove()
        data.HealthBar:Remove()
        data.HealthBarBG:Remove()
        for _, line in pairs(data.SkeletonLines) do
            line:Remove()
        end
        self.trackedPlayers[player] = nil
    end
end

function BoxESP:getCharacterParts(character)
    local parts = {}
    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("BasePart") then
            table.insert(parts, part)
        end
    end
    return parts
end

function BoxESP:isR15(character)
    return character:FindFirstChild("LowerTorso") and character:FindFirstChild("UpperTorso")
end

function BoxESP:drawSkeleton(char, data)
    local bonesTable = self:isR15(char) and R15Bones or R6Bones
    local lines = data.SkeletonLines

    if #lines == 0 then
        for _ = 1, #bonesTable do
            local line = create("Line", {
                Color = self.ESPSettings.SkeletonColor,
                Thickness = self.ESPSettings.SkeletonThickness,
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
                line.Color = self.ESPSettings.SkeletonColor
                line.Thickness = self.ESPSettings.SkeletonThickness
            else
                line.Visible = false
            end
        else
            line.Visible = false
        end
    end
end

-- Initialization: add ESP for existing players
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= localPlayer then
        BoxESP:addESP(player)
    end
end

-- Player added/removed handlers
Players.PlayerAdded:Connect(function(player)
    if player ~= localPlayer then
        BoxESP:addESP(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    BoxESP:removeESP(player)
end)

RunService.RenderStepped:Connect(function()
    if not BoxESP.ESPSettings.Enabled then
        for _, data in pairs(BoxESP.trackedPlayers) do
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

    for player, data in pairs(BoxESP.trackedPlayers) do
        local char = player.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                local parts = BoxESP:getCharacterParts(char)

                local onScreen = false
                local minX, minY = math.huge, math.huge
                local maxX, maxY = -math.huge, -math.huge

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
                    data.Box.Color = BoxESP.ESPSettings.BoxColor
                    data.Box.Visible = true

                    -- Name tag
                    data.Name.Text = player.Name
                    data.Name.Position = Vector2.new(minX + width / 2, minY - 18)
                    data.Name.Color = BoxESP.ESPSettings.NameColor
                    data.Name.Visible = true

                    -- Health bar left side
                    data.HealthBarBG.Size = Vector2.new(BoxESP.ESPSettings.HealthBarWidth, height)
                    data.HealthBarBG.Position = Vector2.new(minX - BoxESP.ESPSettings.HealthBarWidth - 5, minY)
                    data.HealthBarBG.Visible = true

                    local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                    data.HealthBar.Size = Vector2.new(BoxESP.ESPSettings.HealthBarWidth, height * healthPercent)
                    data.HealthBar.Position = Vector2.new(data.HealthBarBG.Position.X, minY + height * (1 - healthPercent))
                    data.HealthBar.Visible = true

                    -- Skeleton
                    if BoxESP.ESPSettings.ShowSkeleton then
                        BoxESP:drawSkeleton(char, data)
                    else
                        for _, line in pairs(data.SkeletonLines) do
                            line.Visible = false
                        end
                    end
                else
                    data.Box.Visible = false
                    data.Name.Visible = false
                    data.HealthBar.Visible = false
                    data.HealthBarBG.Visible = false
                    for _, line in pairs(data.SkeletonLines) do
                        line.Visible = false
                    end
                end
            else
                data.Box.Visible = false
                data.Name.Visible = false
                data.HealthBar.Visible = false
                data.HealthBarBG.Visible = false
                for _, line in pairs(data.SkeletonLines) do
                    line.Visible = false
                end
            end
        else
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

-- BoxESP API methods

function BoxESP:SetEnabled(state)
    self.ESPSettings.Enabled = state
end

function BoxESP:SetBoxColor(color)
    self.ESPSettings.BoxColor = color
    for _, data in pairs(self.trackedPlayers) do
        data.Box.Color = color
    end
end

function BoxESP:SetHealthBarWidth(width)
    self.ESPSettings.HealthBarWidth = width
end

function BoxESP:SetNameColor(color)
    self.ESPSettings.NameColor = color
    for _, data in pairs(self.trackedPlayers) do
        data.Name.Color = color
    end
end

function BoxESP:SetSkeletonColor(color)
    self.ESPSettings.SkeletonColor = color
end

function BoxESP:SetSkeletonThickness(thickness)
    self.ESPSettings.SkeletonThickness = thickness
end

function BoxESP:SetShowSkeleton(state)
    self.ESPSettings.ShowSkeleton = state
end

function BoxESP:SetSkeletonColor(color)
    self.ESPSettings.SkeletonColor = color
    for _, data in pairs(self.trackedPlayers) do
        for _, line in pairs(data.SkeletonLines) do
            line.Color = color
        end
    end
end

-- Expose API from ESP module with BoxESP prefix

function ESP:BoxESPEnabled(state)
    BoxESP:SetEnabled(state)
end

function ESP:BoxESPSetBoxColor(color)
    BoxESP:SetBoxColor(color)
end

function ESP:BoxESPSetHealthBarWidth(width)
    BoxESP:SetHealthBarWidth(width)
end

function ESP:BoxESPSetNameColor(color)
    BoxESP:SetNameColor(color)
end

function ESP:BoxESPSetSkeletonColor(color)
    BoxESP:SetSkeletonColor(color)
end

function ESP:BoxESPSetSkeletonThickness(thickness)
    BoxESP:SetSkeletonThickness(thickness)
end

function ESP:BoxESPSetShowSkeleton(state)
    BoxESP:SetShowSkeleton(state)
end

return ESP
