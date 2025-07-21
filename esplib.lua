-- esplib.lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local camera = workspace.CurrentCamera
local localPlayer = Players.LocalPlayer

-- Settings
local ESP_SETTINGS = {
    Enabled = false,
    ShowSkeletons = false,
    SkeletonsColor = Color3.new(1, 1, 1),
    TeamCheck = false,
    WallCheck = false,
    -- Add other settings as needed
}

-- Bone definitions
local bonesR15 = {
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

local bonesR6 = {
    {"Head", "Torso"},
    {"Torso", "Left Arm"},
    {"Left Arm", "Left Leg"},
    {"Torso", "Right Arm"},
    {"Right Arm", "Right Leg"},
}

-- Utility to check R15 rig
local function isR15(character)
    return character:FindFirstChild("UpperTorso") and character:FindFirstChild("LowerTorso")
end

-- Drawing helper
local function createDrawing(class, props)
    local obj = Drawing.new(class)
    for k, v in pairs(props) do obj[k] = v end
    return obj
end

-- Cache table
local cache = {}

-- Create ESP data for a player
local function createESP(player)
    local esp = {
        skeletonLines = {},
    }
    cache[player] = esp
end

-- Remove ESP on player remove
local function removeESP(player)
    local esp = cache[player]
    if not esp then return end
    for _, bone in ipairs(esp.skeletonLines) do
        bone.line:Remove()
    end
    cache[player] = nil
end

-- Initialize for existing players
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= localPlayer then createESP(player) end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= localPlayer then createESP(player) end
end)

Players.PlayerRemoving:Connect(removeESP)

-- Update loop
RunService.RenderStepped:Connect(function()
    for player, esp in pairs(cache) do
        local char = player.Character
        if char and ESP_SETTINGS.Enabled and (not ESP_SETTINGS.TeamCheck or player.Team ~= localPlayer.Team) then

            -- Wall check (optional)
            if ESP_SETTINGS.WallCheck then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    local ray = Ray.new(camera.CFrame.Position, (root.Position - camera.CFrame.Position))
                    local hit = workspace:FindPartOnRayWithIgnoreList(ray, {camera, char})
                    if hit and not hit:IsDescendantOf(char) then
                        -- Player is behind a wall
                        for _, bone in ipairs(esp.skeletonLines) do bone.line.Visible = false end
                        continue
                    end
                end
            end

            -- Build skeleton lines once
            if ESP_SETTINGS.ShowSkeletons and #esp.skeletonLines == 0 then
                local boneset = isR15(char) and bonesR15 or bonesR6
                for _, pair in ipairs(boneset) do
                    local line = createDrawing("Line", {
                        Thickness = 1,
                        Color = ESP_SETTINGS.SkeletonsColor,
                        Transparency = 1,
                        Visible = false,
                    })
                    table.insert(esp.skeletonLines, {line = line, from = pair[1], to = pair[2]})
                end
            end

            -- Update skeleton drawing
            if ESP_SETTINGS.ShowSkeletons then
                for _, bone in ipairs(esp.skeletonLines) do
                    local fromPart = char:FindFirstChild(bone.from)
                    local toPart = char:FindFirstChild(bone.to)
                    local line = bone.line

                    if fromPart and toPart then
                        local p1, on1 = camera:WorldToViewportPoint(fromPart.Position)
                        local p2, on2 = camera:WorldToViewportPoint(toPart.Position)

                        if on1 and on2 then
                            line.From = Vector2.new(p1.X, p1.Y)
                            line.To = Vector2.new(p2.X, p2.Y)
                            line.Color = ESP_SETTINGS.SkeletonsColor
                            line.Visible = true
                        else
                            line.Visible = false
                        end
                    else
                        line.Visible = false
                    end
                end
            else
                for _, bone in ipairs(esp.skeletonLines) do
                    bone.line.Visible = false
                end
            end
        else
            -- Hide if not enabled or invalid
            for _, bone in ipairs(esp.skeletonLines) do
                bone.line.Visible = false
            end
        end
    end
end)

-- Public API
local ESPAPI = {}

function ESPAPI:SetEnabled(val)
    ESP_SETTINGS.Enabled = val
end

function ESPAPI:SetShowSkeletons(val)
    ESP_SETTINGS.ShowSkeletons = val
end

function ESPAPI:SetSkeletonsColor(color)
    ESP_SETTINGS.SkeletonsColor = color
end

function ESPAPI:SetTeamCheck(val)
    ESP_SETTINGS.TeamCheck = val
end

function ESPAPI:SetWallCheck(val)
    ESP_SETTINGS.WallCheck = val
end

return ESPAPI
