--[[
    SCP-096 GettingUp FX bridge (addon)

    This script is additive: it does NOT replace your old SCP-096 chase script
    and does NOT modify your existing animation IDs there.

    Place this Script inside the SCP-096 model.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SCP = script.Parent
local humanoid = SCP:WaitForChild("Humanoid")

local REMOTE_NAME = "SCP096FaceFXEvent"
local EFFECT_DISTANCE = 250

-- Put the SAME GettingUp animation id(s) you already use in your old script.
-- This script does not change any animation, it only detects it.
local GETTING_UP_ANIMATION_IDS = {
    "rbxassetid://0000000000",
}

local function normalizeId(animationId: string): string
    local num = string.match(animationId, "%d+")
    return num or animationId
end

local idSet: {[string]: boolean} = {}
for _, id in ipairs(GETTING_UP_ANIMATION_IDS) do
    idSet[normalizeId(id)] = true
end

local remote = ReplicatedStorage:FindFirstChild(REMOTE_NAME)
if not remote then
    remote = Instance.new("RemoteEvent")
    remote.Name = REMOTE_NAME
    remote.Parent = ReplicatedStorage
end

local function fireNearbyPlayers()
    local root = SCP:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then
        return
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hrp and hum and hum.Health > 0 then
            local dist = (hrp.Position - root.Position).Magnitude
            if dist <= EFFECT_DISTANCE then
                remote:FireClient(plr)
            end
        end
    end
end

local animator = humanoid:FindFirstChildOfClass("Animator")
if not animator then
    animator = Instance.new("Animator")
    animator.Parent = humanoid
end

animator.AnimationPlayed:Connect(function(track)
    local anim = track.Animation
    if not anim then
        return
    end

    local id = normalizeId(anim.AnimationId)
    if idSet[id] then
        fireNearbyPlayers()
    end
end)
