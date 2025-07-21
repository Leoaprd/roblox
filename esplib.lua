local ESP = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local localPlayer = Players.LocalPlayer

ESP.ESPSettings = {
    Enabled = true,
    LocalPlayerESPEnabled = false,      -- toggle local player ESP
    BoxESPEnabled = true,
    BoxType = "Box",                    -- "Box" or "Corner" (currently only Box implemented)
    BoxESPSetBoxThickness = 2,
    BoxESPSetBoxFilled = false,
    HealthBarEnabled = true,
    HealthBarColor = Color3.fromRGB(255, 0, 0),
    HealthBarWidth = 5,
    NameTagEnabled = true,
    NameTagColor = Color3.fromRGB(255, 255, 255),
    SkeletonEnabled = true,
    SkeletonColor = Color3.fromRGB(0, 255, 0),
    SkeletonThickness = 1,
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

function ESP:addESP(player)
    if trackedPlayers[player] then return end

    local data = {}

    data.Box = create("Square", {
        Thickness = self.ESPSettings.BoxESPSetBoxThickness,
        Color = Color3.fromRGB(0, 255, 0),
        Filled = self.ESPSettings.BoxESPSetBoxFilled,
        Visible = false,
        ZIndex = 2
    })

    data.Name = create("Text", {
        Color = self.ESPSettings.NameTagColor,
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
        Color = self.ESPSettings.HealthBarColor,
        Thickness = 0,
        Filled = true,
        Visible = false,
        ZIndex = 3
    })

    data.SkeletonLines = {}

    trackedPlayers[player] = data
end

function ESP:removeESP(player)
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
    return character:FindFirstChild("LowerTorso") and character:FindFirstChild("UpperTorso")
end

local function isPlayerAlive(character)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health > 0 then
        return true
    end
    return false
end

local function drawSkeleton(char, data)
    local bonesTable = isR15(char) and R15Bones or R6Bones
    local lines = data.SkeletonLines

    if #lines == 0 then
        for _ = 1, #bonesTable do
            local line = create("Line", {
                Color = ESP.ESPSettings.SkeletonColor,
                Thickness = ESP.ESPSettings.SkeletonThickness,
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
                line.Color = ESP.ESPSettings.SkeletonColor
                line.Thickness = ESP.ESPSettings.SkeletonThickness
            else
                line.Visible = false
            end
        else
            line.Visible = false
        end
    end
end

local function shouldTrackPlayer(player)
    if player == localPlayer then
        return ESP.ESPSettings.LocalPlayerESPEnabled
    else
        return true
    end
end

-- Initial player setup
for _, player in ipairs(Players:GetPlayers()) do
    if shouldTrackPlayer(player) then
        ESP:addESP(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    if shouldTrackPlayer(player) then
        ESP:addESP(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    ESP:removeESP(player)
end)

RunService.RenderStepped:Connect(function()
    if not ESP.ESPSettings.Enabled then
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
        if char and isPlayerAlive(char) then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                local parts = getCharacterParts(char)
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

                    -- Box ESP
                    if ESP.ESPSettings.BoxESPEnabled then
                        data.Box.Size = Vector2.new(width, height)
                        data.Box.Position = Vector2.new(minX, minY)
                        data.Box.Color = Color3.fromRGB(0, 255, 0)
                        data.Box.Thickness = ESP.ESPSettings.BoxESPSetBoxThickness
                        data.Box.Filled = ESP.ESPSettings.BoxESPSetBoxFilled
                        data.Box.Visible = true
                    else
                        data.Box.Visible = false
                    end

                    -- Name tag
                    if ESP.ESPSettings.NameTagEnabled then
                        data.Name.Text = player.Name
                        data.Name.Position = Vector2.new(minX + width / 2, minY - 18)
                        data.Name.Color = ESP.ESPSettings.NameTagColor
                        data.Name.Visible = true
                    else
                        data.Name.Visible = false
                    end

                    -- Health bar
                    if ESP.ESPSettings.HealthBarEnabled then
                        data.HealthBarBG.Size = Vector2.new(ESP.ESPSettings.HealthBarWidth, height)
                        data.HealthBarBG.Position = Vector2.new(minX - ESP.ESPSettings.HealthBarWidth - 5, minY)
                        data.HealthBarBG.Visible = true

                        local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                        data.HealthBar.Size = Vector2.new(ESP.ESPSettings.HealthBarWidth, height * healthPercent)
                        data.HealthBar.Position = Vector2.new(data.HealthBarBG.Position.X, minY + height * (1 - healthPercent))
                        data.HealthBar.Color = ESP.ESPSettings.HealthBarColor
                        data.HealthBar.Visible = true
                    else
                        data.HealthBar.Visible = false
                        data.HealthBarBG.Visible = false
                    end

                    -- Skeleton
                    if ESP.ESPSettings.SkeletonEnabled then
                        drawSkeleton(char, data)
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
                -- no humanoid
                data.Box.Visible = false
                data.Name.Visible = false
                data.HealthBar.Visible = false
                data.HealthBarBG.Visible = false
                for _, line in pairs(data.SkeletonLines) do
                    line.Visible = false
                end
            end
        else
            -- no character or dead
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

-- API Methods

function ESP:SetEnabled(state)
    self.ESPSettings.Enabled = state
end

function ESP:SetLocalPlayerESPEnabled(state)
    if self.ESPSettings.LocalPlayerESPEnabled ~= state then
        self.ESPSettings.LocalPlayerESPEnabled = state

        if state then
            self:addESP(localPlayer)
        else
            self:removeESP(localPlayer)
        end
    end
end

function ESP:SetBoxESPEnabled(state)
    self.ESPSettings.BoxESPEnabled = state
end

function ESP:SetBoxType(boxType)
    -- only "Box" supported for now
    if boxType == "Box" or boxType == "Corner" then
        self.ESPSettings.BoxType = boxType
    end
end

function ESP:SetBoxESPSetBoxThickness(thickness)
    self.ESPSettings.BoxESPSetBoxThickness = thickness
end

function ESP:SetBoxESPSetBoxFilled(filled)
    self.ESPSettings.BoxESPSetBoxFilled = filled
end

function ESP:SetHealthBarEnabled(state)
    self.ESPSettings.HealthBarEnabled = state
end

function ESP:SetHealthBarColor(color)
    self.ESPSettings.HealthBarColor = color
end

function ESP:SetHealthBarWidth(width)
    self.ESPSettings.HealthBarWidth = width
end

function ESP:SetNameTagEnabled(state)
    self.ESPSettings.NameTagEnabled = state
end

function ESP:SetNameTagColor(color)
    self.ESPSettings.NameTagColor = color
end

function ESP:SetSkeletonEnabled(state)
    self.ESPSettings.SkeletonEnabled = state
end

function ESP:SetSkeletonColor(color)
    self.ESPSettings.SkeletonColor = color
end

function ESP:SetSkeletonThickness(thickness)
    self.ESPSettings.SkeletonThickness = thickness
end

return ESP
