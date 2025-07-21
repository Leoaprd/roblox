local ESP = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local localPlayer = Players.LocalPlayer

ESP.ESPSettings = {
    Enabled = false,
    LocalPlayerESPEnabled = false,

    BoxESPEnabled = false,
    BoxType = "Box", -- "Box" or "Corner"
    BoxESPSetBoxThickness = 2,
    BoxESPSetBoxFilled = false,
    BoxColor = Color3.fromRGB(0, 255, 0),
    BoxFillColor = Color3.fromRGB(255, 0, 0),
    BoxFillTransparency = 0.5,

    HealthBarEnabled = false,
    HealthBarColor = Color3.fromRGB(255, 0, 0),
    HealthBarWidth = 5,

    NameTagEnabled = false,
    NameTagColor = Color3.fromRGB(255, 255, 255),

    SkeletonEnabled = false,
    SkeletonColor = Color3.fromRGB(0, 255, 0),
    SkeletonThickness = 1,
}

local R6Bones = {
    {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Left Arm", "Left Forearm"},
    {"Left Forearm", "Left Hand"}, {"Torso", "Right Arm"}, {"Right Arm", "Right Forearm"},
    {"Right Forearm", "Right Hand"}, {"Torso", "Left Leg"}, {"Left Leg", "Left Foot"},
    {"Torso", "Right Leg"}, {"Right Leg", "Right Foot"},
}

local R15Bones = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
}

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
        Color = self.ESPSettings.BoxColor,
        Filled = self.ESPSettings.BoxESPSetBoxFilled,
        Transparency = self.ESPSettings.BoxFillTransparency,
        Visible = false,
        ZIndex = 2
    })

    data.Corner = {
        TL = create("Line", {}), TR = create("Line", {}),
        BL = create("Line", {}), BR = create("Line", {}),
    }

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
        for _, line in pairs(data.SkeletonLines) do line:Remove() end
        for _, line in pairs(data.Corner) do line:Remove() end
        trackedPlayers[player] = nil
    end
end

local function getCharacterParts(character)
    local parts = {}
    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("BasePart") then table.insert(parts, part) end
    end
    return parts
end

local function isR15(character)
    return character:FindFirstChild("LowerTorso") and character:FindFirstChild("UpperTorso")
end

local function isPlayerAlive(character)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
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

for _, player in ipairs(Players:GetPlayers()) do
    if shouldTrackPlayer(player) then ESP:addESP(player) end
end

Players.PlayerAdded:Connect(function(player)
    if shouldTrackPlayer(player) then ESP:addESP(player) end
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
            for _, l in pairs(data.SkeletonLines) do l.Visible = false end
            for _, l in pairs(data.Corner) do l.Visible = false end
        end
        return
    end

    for player, data in pairs(trackedPlayers) do
        local char = player.Character
        if char and isPlayerAlive(char) then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                local parts = getCharacterParts(char)
                local minX, minY = math.huge, math.huge
                local maxX, maxY = -math.huge, -math.huge
                local onScreen = false

                for _, part in ipairs(parts) do
                    local pos, vis = Camera:WorldToViewportPoint(part.Position)
                    if vis then
                        onScreen = true
                        minX = math.min(minX, pos.X)
                        minY = math.min(minY, pos.Y)
                        maxX = math.max(maxX, pos.X)
                        maxY = math.max(maxY, pos.Y)
                    end
                end

                if onScreen and minX < maxX and minY < maxY then
                    local width, height = maxX - minX, maxY - minY

                    -- Box and Corner rendering
                    if ESP.ESPSettings.BoxESPEnabled then
                        local isBox = ESP.ESPSettings.BoxType == "Box"
                        local isCorner = ESP.ESPSettings.BoxType == "Corner"

                        data.Box.Visible = isBox
                        if isBox then
                            data.Box.Position = Vector2.new(minX, minY)
                            data.Box.Size = Vector2.new(width, height)
                            data.Box.Thickness = ESP.ESPSettings.BoxESPSetBoxThickness
                            data.Box.Filled = ESP.ESPSettings.BoxESPSetBoxFilled
                            data.Box.Color = ESP.ESPSettings.BoxESPSetBoxFilled and ESP.ESPSettings.BoxFillColor or ESP.ESPSettings.BoxColor
                            data.Box.Transparency = ESP.ESPSettings.BoxESPSetBoxFilled and ESP.ESPSettings.BoxFillTransparency or 1
                        end

                        for _, l in pairs(data.Corner) do
                            l.Visible = isCorner
                            l.Thickness = ESP.ESPSettings.BoxESPSetBoxThickness
                            l.Color = ESP.ESPSettings.BoxColor
                        end

                        if isCorner then
                            local cl = math.min(width, height) * 0.25
                            data.Corner.TL.From = Vector2.new(minX, minY)
                            data.Corner.TL.To = Vector2.new(minX + cl, minY)

                            data.Corner.TR.From = Vector2.new(maxX, minY)
                            data.Corner.TR.To = Vector2.new(maxX - cl, minY)

                            data.Corner.BL.From = Vector2.new(minX, maxY)
                            data.Corner.BL.To = Vector2.new(minX + cl, maxY)

                            data.Corner.BR.From = Vector2.new(maxX, maxY)
                            data.Corner.BR.To = Vector2.new(maxX - cl, maxY)
                        end
                    else
                        data.Box.Visible = false
                        for _, l in pairs(data.Corner) do l.Visible = false end
                    end

                    if ESP.ESPSettings.NameTagEnabled then
                        data.Name.Text = player.Name
                        data.Name.Position = Vector2.new(minX + width / 2, minY - 18)
                        data.Name.Color = ESP.ESPSettings.NameTagColor
                        data.Name.Visible = true
                    else
                        data.Name.Visible = false
                    end

                    if ESP.ESPSettings.HealthBarEnabled then
                        data.HealthBarBG.Size = Vector2.new(ESP.ESPSettings.HealthBarWidth, height)
                        data.HealthBarBG.Position = Vector2.new(minX - ESP.ESPSettings.HealthBarWidth - 5, minY)
                        data.HealthBarBG.Visible = true

                        local hp = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                        data.HealthBar.Size = Vector2.new(ESP.ESPSettings.HealthBarWidth, height * hp)
                        data.HealthBar.Position = Vector2.new(data.HealthBarBG.Position.X, minY + height * (1 - hp))
                        data.HealthBar.Color = ESP.ESPSettings.HealthBarColor
                        data.HealthBar.Visible = true
                    else
                        data.HealthBar.Visible = false
                        data.HealthBarBG.Visible = false
                    end

                    if ESP.ESPSettings.SkeletonEnabled then
                        drawSkeleton(char, data)
                    else
                        for _, l in pairs(data.SkeletonLines) do l.Visible = false end
                    end
                end
            end
        end
    end
end)

-- API Methods
function ESP:SetEnabled(state) self.ESPSettings.Enabled = state end
function ESP:SetLocalPlayerESPEnabled(state) self.ESPSettings.LocalPlayerESPEnabled = state end
function ESP:SetBoxESPEnabled(state) self.ESPSettings.BoxESPEnabled = state end
function ESP:SetBoxType(t) if t == "Box" or t == "Corner" then self.ESPSettings.BoxType = t end end
function ESP:SetBoxESPSetBoxThickness(t) self.ESPSettings.BoxESPSetBoxThickness = t end
function ESP:SetBoxESPSetBoxFilled(f) self.ESPSettings.BoxESPSetBoxFilled = f end
function ESP:SetBoxColor(c) self.ESPSettings.BoxColor = c end
function ESP:SetBoxFillColor(c) self.ESPSettings.BoxFillColor = c end
function ESP:SetBoxFillTransparency(t) self.ESPSettings.BoxFillTransparency = math.clamp(t, 0, 1) end
function ESP:SetHealthBarEnabled(state) self.ESPSettings.HealthBarEnabled = state end
function ESP:SetHealthBarColor(c) self.ESPSettings.HealthBarColor = c end
function ESP:SetHealthBarWidth(w) self.ESPSettings.HealthBarWidth = w end
function ESP:SetNameTagEnabled(state) self.ESPSettings.NameTagEnabled = state end
function ESP:SetNameTagColor(c) self.ESPSettings.NameTagColor = c end
function ESP:SetSkeletonEnabled(state) self.ESPSettings.SkeletonEnabled = state end
function ESP:SetSkeletonColor(c) self.ESPSettings.SkeletonColor = c end
function ESP:SetSkeletonThickness(t) self.ESPSettings.SkeletonThickness = t end

return ESP
