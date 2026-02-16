--[[
    Roblox (Luau) - Head flashlight (server)

    Place this Script in ServerScriptService.
    Works with: HeadFlashlight.client.lua (LocalScript)

    Behavior:
    - Each player can toggle a light on their head.
    - Toggle key is handled client-side (default: F).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local REMOTE_NAME = "HeadFlashlightToggleEvent"
local ATTACHMENT_NAME = "HeadFlashlightAttachment"
local SPOT_NAME = "HeadFlashlightSpot"
local POINT_NAME = "HeadFlashlightPoint"

-- Tuning
local SPOT_BRIGHTNESS = 3.5
local SPOT_RANGE = 36
local SPOT_ANGLE = 95
local POINT_BRIGHTNESS = 1
local POINT_RANGE = 14
local SHADOWS = true

local remote = ReplicatedStorage:FindFirstChild(REMOTE_NAME)
if not remote then
    remote = Instance.new("RemoteEvent")
    remote.Name = REMOTE_NAME
    remote.Parent = ReplicatedStorage
end

local function getHead(character: Model): BasePart?
    local head = character:FindFirstChild("Head")
    if head and head:IsA("BasePart") then
        return head
    end
    return nil
end

local function getOrCreateFlashlightParts(character: Model): (SpotLight?, PointLight?)
    local head = getHead(character)
    if not head then
        return nil, nil
    end

    local attachment = head:FindFirstChild(ATTACHMENT_NAME)
    if not attachment or not attachment:IsA("Attachment") then
        attachment = Instance.new("Attachment")
        attachment.Name = ATTACHMENT_NAME
        attachment.Parent = head
    end

    local spot = attachment:FindFirstChild(SPOT_NAME)
    if not spot or not spot:IsA("SpotLight") then
        spot = Instance.new("SpotLight")
        spot.Name = SPOT_NAME
        spot.Parent = attachment
    end

    spot.Enabled = false
    spot.Brightness = SPOT_BRIGHTNESS
    spot.Range = SPOT_RANGE
    spot.Angle = SPOT_ANGLE
    spot.Shadows = SHADOWS

    local point = attachment:FindFirstChild(POINT_NAME)
    if not point or not point:IsA("PointLight") then
        point = Instance.new("PointLight")
        point.Name = POINT_NAME
        point.Parent = attachment
    end

    point.Enabled = false
    point.Brightness = POINT_BRIGHTNESS
    point.Range = POINT_RANGE
    point.Shadows = SHADOWS

    return spot, point
end

local function setFlashlightEnabled(player: Player, enabled: boolean)
    local character = player.Character
    if not character then
        return
    end

    local spot, point = getOrCreateFlashlightParts(character)
    if spot then
        spot.Enabled = enabled
    end
    if point then
        point.Enabled = enabled
    end
end

local function setupPlayer(player: Player)
    player.CharacterAdded:Connect(function(character)
        getOrCreateFlashlightParts(character)
    end)

    if player.Character then
        getOrCreateFlashlightParts(player.Character)
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end
Players.PlayerAdded:Connect(setupPlayer)

remote.OnServerEvent:Connect(function(player, enabled)
    if typeof(enabled) ~= "boolean" then
        return
    end

    setFlashlightEnabled(player, enabled)
end)
