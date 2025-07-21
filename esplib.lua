local ESP = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local camera = workspace.CurrentCamera

local localPlayer = Players.LocalPlayer

local ESP_SETTINGS = {
    Enabled = true,
    ShowSkeletons = true,
    SkeletonsColor = Color3.fromRGB(0, 255, 0)
}

local bones = {
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
    {"RightLowerLeg", "RightFoot"}
}

-- Drawing utility
local function create(class, props)
    local obj = Drawing.new(class)
    for i, v in pairs(props) do
        obj[i] = v
    end
    return obj
end

-- ESP storage
local trackedPlayers = {}

-- Cleanup player ESP
local function cleanupESP(player)
    if trackedPlayers[player] then
        local esp = trackedPlayers[player]
        for _, bone in ipairs(esp.skeletonlines or {}) do
            if bone.line then
                bone.line:Remove()
            end
        end
        trackedPlayers[player] = nil
    end
end

-- Track new player
local function addESP(player)
    local esp = {
        skeletonlines = {}
    }
    trackedPlayers[player] = esp
end

-- Setup existing players
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= localPlayer then
        addESP(p)
    end
end

Players.PlayerAdded:Connect(function(p)
    if p ~= localPlayer then
        addESP(p)
    end
end)

Players.PlayerRemoving:Connect(function(p)
    cleanupESP(p)
end)

-- Render step
RunService.RenderStepped:Connect(function()
    if not ESP_SETTINGS.Enabled then
        for _, esp in pairs(trackedPlayers) do
            for _, bone in ipairs(esp.skeletonlines) do
                bone.line.Visible = false
            end
        end
        return
    end

    for player, esp in pairs(trackedPlayers) do
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            if ESP_SETTINGS.ShowSkeletons then
                -- Create skeleton lines if not created yet
                if #esp.skeletonlines == 0 then
                    for _, pair in ipairs(bones) do
                        local line = create("Line", {
                            Thickness = 1,
                            Color = ESP_SETTINGS.SkeletonsColor,
                            Transparency = 1,
                            Visible = false,
                            ZIndex = 2
                        })
                        table.insert(esp.skeletonlines, {
                            line = line,
                            from = pair[1],
                            to = pair[2]
                        })
                    end
                end

                for _, bone in ipairs(esp.skeletonlines) do
                    local partA = char:FindFirstChild(bone.from)
                    local partB = char:FindFirstChild(bone.to)

                    if partA and partB then
                        local aPos, onScreenA = camera:WorldToViewportPoint(partA.Position)
                        local bPos, onScreenB = camera:WorldToViewportPoint(partB.Position)

                        if onScreenA and onScreenB then
                            bone.line.From = Vector2.new(aPos.X, aPos.Y)
                            bone.line.To = Vector2.new(bPos.X, bPos.Y)
                            bone.line.Color = ESP_SETTINGS.SkeletonsColor
                            bone.line.Visible = true
                        else
                            bone.line.Visible = false
                        end
                    else
                        bone.line.Visible = false
                    end
                end
            end
        else
            -- Hide all lines if character invalid
            for _, bone in ipairs(esp.skeletonlines) do
                bone.line.Visible = false
            end
        end
    end
end)

-- API to configure
function ESP:SetEnabled(state)
    ESP_SETTINGS.Enabled = state
end

function ESP:SetSkeletons(state)
    ESP_SETTINGS.ShowSkeletons = state
end

function ESP:SetSkeletonColor(color)
    ESP_SETTINGS.SkeletonsColor = color
end

return ESP
