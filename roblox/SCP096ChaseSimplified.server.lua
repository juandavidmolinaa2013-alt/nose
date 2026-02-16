--[[
    SCP-096 simplified chase + animation trigger effects

    Place this Script inside the SCP-096 NPC model.
    Required in model:
    - Humanoid
    - HumanoidRootPart

    Optional:
    - Animator inside Humanoid (created automatically if missing)

    Also place `SCP096GettingUpEffects.client.lua` in StarterPlayerScripts.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NPC = script.Parent
local Humanoid = NPC:WaitForChild("Humanoid")
local Root = NPC:WaitForChild("HumanoidRootPart")

local REMOTE_NAME = "SCP096GettingUpEvent"
local remote = ReplicatedStorage:FindFirstChild(REMOTE_NAME)
if not remote then
    remote = Instance.new("RemoteEvent")
    remote.Name = REMOTE_NAME
    remote.Parent = ReplicatedStorage
end

-- Configure your animation IDs
local GETTING_UP_ANIMATION_ID = "rbxassetid://0000000000"
local RUN_ANIMATION_ID = "rbxassetid://0000000000"
local IDLE_ANIMATION_ID = "rbxassetid://0000000000"

local DETECTION_RANGE = 220
local ATTACK_RANGE = 6
local CHASE_DAMAGE = 20
local ATTACK_COOLDOWN = 1
local MOVE_UPDATE_RATE = 0.15

local isChasing = false
local didPlayGettingUp = false
local currentTarget: Player? = nil
local lastAttackTime = 0

local animator = Humanoid:FindFirstChildOfClass("Animator")
if not animator then
    animator = Instance.new("Animator")
    animator.Parent = Humanoid
end

local function loadTrack(animationId: string, priority: Enum.AnimationPriority, looped: boolean): AnimationTrack?
    if animationId == "" or animationId == "rbxassetid://0000000000" then
        return nil
    end

    local anim = Instance.new("Animation")
    anim.AnimationId = animationId
    local track = animator:LoadAnimation(anim)
    track.Priority = priority
    track.Looped = looped
    return track
end

local gettingUpTrack = loadTrack(GETTING_UP_ANIMATION_ID, Enum.AnimationPriority.Action, false)
local runTrack = loadTrack(RUN_ANIMATION_ID, Enum.AnimationPriority.Movement, true)
local idleTrack = loadTrack(IDLE_ANIMATION_ID, Enum.AnimationPriority.Idle, true)

local function stopTrack(track: AnimationTrack?)
    if track and track.IsPlaying then
        track:Stop(0.15)
    end
end

local function playTrack(track: AnimationTrack?)
    if track and not track.IsPlaying then
        track:Play(0.15)
    end
end

local function getClosestPlayer(): (Player?, number)
    local closestPlayer = nil
    local closestDist = math.huge

    for _, plr in ipairs(Players:GetPlayers()) do
        local character = plr.Character
        if character then
            local hum = character:FindFirstChildOfClass("Humanoid")
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 then
                local dist = (hrp.Position - Root.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestPlayer = plr
                end
            end
        end
    end

    return closestPlayer, closestDist
end

local function triggerGettingUpEffects(target: Player)
    remote:FireClient(target, {
        duration = gettingUpTrack and gettingUpTrack.Length > 0 and gettingUpTrack.Length or 2.5,
        text = "SCP-096 SE ESTA LEVANTANDO...",
        image = "rbxassetid://0", -- replace with your image id
    })
end

local function beginChase(target: Player)
    isChasing = true
    currentTarget = target

    stopTrack(idleTrack)

    if not didPlayGettingUp and gettingUpTrack then
        didPlayGettingUp = true
        playTrack(gettingUpTrack)
        triggerGettingUpEffects(target)

        task.wait(gettingUpTrack.Length > 0 and gettingUpTrack.Length or 2)
    end

    playTrack(runTrack)
end

local function endChase()
    isChasing = false
    currentTarget = nil
    stopTrack(runTrack)
    playTrack(idleTrack)
end

local function tryDamageTarget(target: Player)
    local character = target.Character
    if not character then
        return
    end

    local hum = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp or hum.Health <= 0 then
        return
    end

    local dist = (hrp.Position - Root.Position).Magnitude
    if dist > ATTACK_RANGE then
        return
    end

    if time() - lastAttackTime < ATTACK_COOLDOWN then
        return
    end

    lastAttackTime = time()
    hum:TakeDamage(CHASE_DAMAGE)
end

playTrack(idleTrack)

task.spawn(function()
    while Humanoid.Health > 0 do
        local target, dist = getClosestPlayer()

        if target and dist <= DETECTION_RANGE then
            if (not isChasing) or currentTarget ~= target then
                beginChase(target)
            end

            local char = target.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                Humanoid:MoveTo(hrp.Position)
                tryDamageTarget(target)
            end
        else
            if isChasing then
                endChase()
            end
        end

        task.wait(MOVE_UPDATE_RATE)
    end
end)

Humanoid.Died:Connect(function()
    stopTrack(gettingUpTrack)
    stopTrack(runTrack)
    stopTrack(idleTrack)
end)

RunService.Heartbeat:Connect(function()
    if Humanoid.Health <= 0 then
        return
    end

    if isChasing and currentTarget then
        local c = currentTarget.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if not c or not h or h.Health <= 0 then
            endChase()
        end
    end
end)
