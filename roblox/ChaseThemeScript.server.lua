--[[
    Chase Theme Layers for SCP-096
    - Plays a segment (layer) of ChaseSound depending on nearest player distance.
    - Layers loop inside their own time ranges.
    - Every layer switch uses fade (normal approach / retreat).
    - If player moves very fast across layers, sound stays muted until layer stabilizes.
]]

local NPC = script.Parent
local HumanoidRootPart = NPC:WaitForChild("HumanoidRootPart")
local ChaseSound = NPC:WaitForChild("ChaseSound")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

ChaseSound.Looped = false
ChaseSound.PlaybackSpeed = 1
ChaseSound.Volume = 0

-- Distances and layer time windows requested:
-- 2-15, 15-29, 29-43, 43-158
-- Ordered NEAREST -> FARTHEST
local Layers = {
    { name = "L4", startTime = 43, endTime = 158, maxDistance = 50 },
    { name = "L3", startTime = 29, endTime = 43, maxDistance = 80 },
    { name = "L2", startTime = 15, endTime = 29, maxDistance = 130 },
    { name = "L1", startTime = 2, endTime = 15, maxDistance = 170 },
}

local TARGET_VOLUME = 1
local FADE_SWITCH_OUT = 0.10
local FADE_SWITCH_IN = 0.10
local FADE_LOOP_OUT = 0.06
local FADE_LOOP_IN = 0.06
local LOOP_GUARD = 0.03
local LAYER_STABILIZE_TIME = 0.22 -- silence until same layer holds this time

local activeTween: Tween? = nil
local currentLayerIndex: number? = nil
local pendingLayerIndex: number? = nil
local pendingSince = 0
local isSwitching = false
local isLoopRestarting = false

local function stopTween()
    if activeTween then
        activeTween:Cancel()
        activeTween = nil
    end
end

local function tweenVolume(target: number, duration: number)
    stopTween()
    local tween = TweenService:Create(
        ChaseSound,
        TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
        { Volume = target }
    )
    activeTween = tween
    tween:Play()
    tween.Completed:Connect(function()
        if activeTween == tween then
            activeTween = nil
        end
    end)
end

local function nearestDistance(): number?
    local closest = math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root and root:IsA("BasePart") then
                local d = (root.Position - HumanoidRootPart.Position).Magnitude
                if d < closest then
                    closest = d
                end
            end
        end
    end
    if closest == math.huge then
        return nil
    end
    return closest
end

local function layerForDistance(distance: number): number?
    for i, layer in ipairs(Layers) do
        if distance <= layer.maxDistance then
            return i
        end
    end
    return nil
end

local function stopWithFade()
    currentLayerIndex = nil
    pendingLayerIndex = nil
    pendingSince = 0

    if not ChaseSound.IsPlaying then
        ChaseSound.Volume = 0
        return
    end

    tweenVolume(0, FADE_SWITCH_OUT)
    task.delay(FADE_SWITCH_OUT, function()
        if currentLayerIndex == nil and pendingLayerIndex == nil then
            ChaseSound:Stop()
            ChaseSound.TimePosition = 0
            ChaseSound.Volume = 0
        end
    end)
end

local function playLayer(layerIndex: number)
    local layer = Layers[layerIndex]
    currentLayerIndex = layerIndex

    ChaseSound.TimePosition = layer.startTime
    if not ChaseSound.IsPlaying then
        ChaseSound:Play()
    end

    ChaseSound.Volume = 0
    tweenVolume(TARGET_VOLUME, FADE_SWITCH_IN)
end

local function switchToLayer(layerIndex: number)
    if isSwitching then
        return
    end

    isSwitching = true
    currentLayerIndex = nil -- keep muted during switch

    if ChaseSound.IsPlaying then
        tweenVolume(0, FADE_SWITCH_OUT)
        task.delay(FADE_SWITCH_OUT, function()
            playLayer(layerIndex)
            isSwitching = false
        end)
    else
        playLayer(layerIndex)
        isSwitching = false
    end
end

local function restartCurrentLayerWithFade()
    if isLoopRestarting or isSwitching then
        return
    end
    if not currentLayerIndex then
        return
    end

    isLoopRestarting = true
    local layerIndex = currentLayerIndex

    tweenVolume(0, FADE_LOOP_OUT)
    task.delay(FADE_LOOP_OUT, function()
        if currentLayerIndex ~= layerIndex then
            isLoopRestarting = false
            return
        end

        local layer = Layers[layerIndex]
        ChaseSound.TimePosition = layer.startTime
        if not ChaseSound.IsPlaying then
            ChaseSound:Play()
        end
        ChaseSound.Volume = 0
        tweenVolume(TARGET_VOLUME, FADE_LOOP_IN)
        isLoopRestarting = false
    end)
end

RunService.Heartbeat:Connect(function()
    local dist = nearestDistance()
    if not dist then
        stopWithFade()
        return
    end

    local desiredLayer = layerForDistance(dist)
    if not desiredLayer then
        stopWithFade()
        return
    end

    -- Stabilizer: if distance jumps quickly across layers, stay silent until stable.
    if pendingLayerIndex ~= desiredLayer then
        pendingLayerIndex = desiredLayer
        pendingSince = time()

        -- Mute immediately while waiting for stable target layer.
        if ChaseSound.IsPlaying then
            tweenVolume(0, FADE_SWITCH_OUT)
        end
        return
    end

    local stableFor = time() - pendingSince
    if stableFor < LAYER_STABILIZE_TIME then
        return
    end

    -- Stable layer achieved: if needed, switch with fade.
    if currentLayerIndex ~= desiredLayer then
        switchToLayer(desiredLayer)
        return
    end

    -- Normal loop inside the layer with fade to avoid hard cut.
    local layer = Layers[desiredLayer]
    if not ChaseSound.IsPlaying then
        playLayer(desiredLayer)
        return
    end

    if ChaseSound.TimePosition >= (layer.endTime - LOOP_GUARD) then
        restartCurrentLayerWithFade()
    end
end)
