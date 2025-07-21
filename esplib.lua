local ESP = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local localPlayer = Players.LocalPlayer

local BoxESP = {}

BoxESP.ESPSettings = {
    Enabled = true,
    BoxType = "box", -- "box" or "corner"
    BoxColor = Color3.fromRGB(0, 255, 0),
    BoxThickness = 2,
    BoxFilled = false,
    HealthBarEnabled = true,
    HealthBarWidth = 5,
    HealthBarColor = Color3.fromRGB(255, 0, 0),
    NameTagEnabled = true,
    NameTagColor = Color3.fromRGB(255, 255, 255),
    SkeletonEnabled = true,
    SkeletonColor = Color3.fromRGB(0, 255, 0),
    SkeletonThickness = 1,
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

    -- Box is now a table of lines for box or corner style
    data.BoxLines = {}

    -- We'll create 4 or 8 lines depending on box type
    local lineCount = BoxESP.ESPSettings.BoxType == "corner" and 8 or 4
    for _ = 1, lineCount do
        local line = create("Line", {
            Color = BoxESP.ESPSettings.BoxColor,
            Thickness = BoxESP.ESPSettings.BoxThickness,
            Visible = false,
            ZIndex = 2,
        })
        table.insert(data.BoxLines, line)
    end

    data.Name = create("Text", {
        Color = BoxESP.ESPSettings.NameTagColor,
        Size = 16,
        Center = true,
        Outline = true,
        Visible = false,
        ZIndex = 2,
        Text = player.Name,
    })

    data.HealthBarBG = create("Square", {
        Color = Color3.fromRGB(0, 0, 0),
        Thickness = 1,
        Filled = true,
        Visible = false,
        ZIndex = 2,
    })

    data.HealthBar = create("Square", {
        Color = BoxESP.ESPSettings.HealthBarColor,
        Thickness = 0,
        Filled = true,
        Visible = false,
        ZIndex = 3,
    })

    data.SkeletonLines = {}

    self.trackedPlayers[player] = data
end

function BoxESP:removeESP(player)
    local data = self.trackedPlayers[player]
    if data then
        for _, line in pairs(data.BoxLines) do
            line:Remove()
        end
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

local function drawBoxLines(data, minX, minY, width, height)
    local lines = data.BoxLines
    local thickness = BoxESP.ESPSettings.BoxThickness
    local color = BoxESP.ESPSettings.BoxColor
    local filled = BoxESP.ESPSettings.BoxFilled
    local boxType = BoxESP.ESPSettings.BoxType

    if boxType == "box" then
        -- 4 lines forming a rectangle
        if #lines < 4 then return end
        -- Top
        lines[1].From = Vector2.new(minX, minY)
        lines[1].To = Vector2.new(minX + width, minY)
        -- Bottom
        lines[2].From = Vector2.new(minX, minY + height)
        lines[2].To = Vector2.new(minX + width, minY + height)
        -- Left
        lines[3].From = Vector2.new(minX, minY)
        lines[3].To = Vector2.new(minX, minY + height)
        -- Right
        lines[4].From = Vector2.new(minX + width, minY)
        lines[4].To = Vector2.new(minX + width, minY + height)

        for i=1,4 do
            lines[i].Color = color
            lines[i].Thickness = thickness
            lines[i].Visible = true
        end
        -- Hide any extra lines if they exist
        for i=5,#lines do
            lines[i].Visible = false
        end
    elseif boxType == "corner" then
        -- 8 lines forming corners only
        if #lines < 8 then return end
        local cornerSize = math.min(width, height) * 0.15

        -- Top Left corner
        lines[1].From = Vector2.new(minX, minY)
        lines[1].To = Vector2.new(minX + cornerSize, minY)

        lines[2].From = Vector2.new(minX, minY)
        lines[2].To = Vector2.new(minX, minY + cornerSize)

        -- Top Right corner
        lines[3].From = Vector2.new(minX + width, minY)
        lines[3].To = Vector2.new(minX + width - cornerSize, minY)

        lines[4].From = Vector2.new(minX + width, minY)
        lines[4].To = Vector2.new(minX + width, minY + cornerSize)

        -- Bottom Left corner
        lines[5].From = Vector2.new(minX, minY + height)
        lines[5].To = Vector2.new(minX + cornerSize, minY + height)

        lines[6].From = Vector2.new(minX, minY + height)
        lines[6].To = Vector2.new(minX, minY + height - cornerSize)

        -- Bottom Right corner
        lines[7].From = Vector2.new(minX + width, minY + height)
        lines[7].To = Vector2.new(minX + width - cornerSize, minY + height)

        lines[8].From = Vector2.new(minX + width, minY + height)
        lines[8].To = Vector2.new(minX + width, minY + height - cornerSize)

        for i=1,8 do
            lines[i].Color = color
            lines[i].Thickness = thickness
            lines[i].Visible = true
        end
    else
        -- If boxType invalid, hide all lines
        for _, line in pairs(lines) do
            line.Visible = false
        end
    end
end

-- Add ESP for existing players
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= localPlayer then
        BoxESP:addESP(player)
    end
end

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
            for _, line in pairs(data.BoxLines) do
                line.Visible = false
            end
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

                    -- Draw box or corner
                    drawBoxLines(data, minX, minY, width, height)

                    -- Name tag
                    data.Name.Text = player.Name
                    data.Name.Position = Vector2.new(minX + width / 2, minY - 18)
                    data.Name.Color = BoxESP.ESPSettings.NameTagColor
                    data.Name.Visible = BoxESP.ESPSettings.NameTagEnabled

                    -- Health bar
                    if BoxESP.ESPSettings.HealthBarEnabled then
                        data.HealthBarBG.Size = Vector2.new(BoxESP.ESPSettings.HealthBarWidth, height)
                        data.HealthBarBG.Position = Vector2.new(minX - BoxESP.ESPSettings.HealthBarWidth - 5, minY)
                        data.HealthBarBG.Visible = true

                        local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                        data.HealthBar.Size = Vector2.new(BoxESP.ESPSettings.HealthBarWidth, height * healthPercent)
                        data.HealthBar.Position = Vector2.new(data.HealthBarBG.Position.X, minY + height * (1 - healthPercent))
                        data.HealthBar.Color = BoxESP.ESPSettings.HealthBarColor
                        data.HealthBar.Visible = true
                    else
                        data.HealthBar.Visible = false
                        data.HealthBarBG.Visible = false
                    end

                    -- Skeleton
                    if BoxESP.ESPSettings.SkeletonEnabled then
                        BoxESP:drawSkeleton(char, data)
                    else
                        for _, line in pairs(data.SkeletonLines) do
                            line.Visible = false
                        end
                    end
                else
                    for _, line in pairs(data.BoxLines) do
                        line.Visible = false
                    end
                    data.Name.Visible = false
                    data.HealthBar.Visible = false
                    data.HealthBarBG.Visible = false
                    for _, line in pairs(data.SkeletonLines) do
                        line.Visible = false
                    end
                end
            else
                for _, line in pairs(data.BoxLines) do
                    line.Visible = false
                end
                data.Name.Visible = false
                data.HealthBar.Visible = false
                data.HealthBarBG.Visible = false
                for _, line in pairs(data.SkeletonLines) do
                    line.Visible = false
                end
            end
        else
            for _, line in pairs(data.BoxLines) do
                line.Visible = false
            end
            data.Name.Visible = false
            data.HealthBar.Visible = false
            data.HealthBarBG.Visible = false
            for _, line in pairs(data.SkeletonLines) do
                line.Visible = false
            end
        end
    end
end)

-- API methods:

function ESP:BoxESPEnabled(state)
    BoxESP.ESPSettings.Enabled = state
end

function ESP:BoxType(type)
    if type == "box" or type == "corner" then
        BoxESP.ESPSettings.BoxType = type
        -- Refresh box lines count for all players
        for _, data in pairs(BoxESP.trackedPlayers) do
            -- Remove old lines
            for _, line in pairs(data.BoxLines) do
                line:Remove()
            end
            data.BoxLines = {}
            local lineCount = type == "corner" and 8 or 4
            for _ = 1, lineCount do
                local line = create("Line", {
                    Color = BoxESP.ESPSettings.BoxColor,
                    Thickness = BoxESP.ESPSettings.BoxThickness,
                    Visible = false,
                    ZIndex = 2,
                })
                table.insert(data.BoxLines, line)
            end
        end
    else
        warn("ESP:BoxType invalid value (must be 'box' or 'corner')")
    end
end

function ESP:BoxESPSetBoxThickness(thickness)
    BoxESP.ESPSettings.BoxThickness = thickness
    for _, data in pairs(BoxESP.trackedPlayers) do
        for _, line in pairs(data.BoxLines) do
            line.Thickness = thickness
        end
    end
end

function ESP:BoxESPSetBoxFilled(filled)
    BoxESP.ESPSettings.BoxFilled = filled
    -- Note: Filled box not implemented visually here, since Drawing API Line doesn't fill
    -- Could be extended by drawing a Filled Rectangle using 'Square' drawing objects
end

function ESP:SetHealthBarEnabled(state)
    BoxESP.ESPSettings.HealthBarEnabled = state
end

function ESP:SetHealthBarColor(color)
    BoxESP.ESPSettings.HealthBarColor = color
end

function ESP:SetNameTagEnabled(state)
    BoxESP.ESPSettings.NameTagEnabled = state
end

function ESP:SetNameTagColor(color)
    BoxESP.ESPSettings.NameTagColor = color
end

function ESP:SetSkeletonEnabled(state)
    BoxESP.ESPSettings.SkeletonEnabled = state
end

function ESP:SetSkeletonColor(color)
    BoxESP.ESPSettings.SkeletonColor = color
end

function ESP:SetSkeletonThickness(thickness)
    BoxESP.ESPSettings.SkeletonThickness = thickness
    for _, data in pairs(BoxESP.trackedPlayers) do
        for _, line in pairs(data.SkeletonLines) do
            line.Thickness = thickness
        end
    end
end

return ESP
