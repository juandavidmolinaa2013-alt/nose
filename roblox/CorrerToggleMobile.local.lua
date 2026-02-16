--[[
    Mobile sprint toggle from StarterGui/Correr/Run

    UI expected in StarterGui:
    - ScreenGui named: Correr
    - ImageButton named: Run (child of Correr)

    Place this LocalScript as a child of the ImageButton "Run"
    (StarterGui > Correr > Run > LocalScript)
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local runButton = script.Parent

local NORMAL_SPEED = 16
local RUN_SPEED = 28
local RUN_ANIMATION_ID = "rbxassetid://0000000000" -- replace with your run animation id

local running = false
local runTrack: AnimationTrack? = nil
local heartbeatConn: RBXScriptConnection? = nil

local function getHumanoid(): Humanoid?
    local character = player.Character
    if not character then
        return nil
    end
    return character:FindFirstChildOfClass("Humanoid")
end

local function stopRunAnimation()
    if runTrack and runTrack.IsPlaying then
        runTrack:Stop(0.15)
    end
end

local function ensureRunAnimation(humanoid: Humanoid)
    if runTrack then
        return
    end

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end

    local anim = Instance.new("Animation")
    anim.AnimationId = RUN_ANIMATION_ID

    runTrack = animator:LoadAnimation(anim)
    runTrack.Priority = Enum.AnimationPriority.Movement
    runTrack.Looped = true
end

local function updateRunAnimationState()
    local humanoid = getHumanoid()
    if not humanoid then
        stopRunAnimation()
        return
    end

    ensureRunAnimation(humanoid)

    local shouldPlay = running and humanoid.MoveDirection.Magnitude > 0.05
    if shouldPlay then
        if runTrack and not runTrack.IsPlaying then
            runTrack:Play(0.15)
        end
    else
        stopRunAnimation()
    end
end

local function applySpeed()
    local humanoid = getHumanoid()
    if not humanoid then
        return
    end

    humanoid.WalkSpeed = running and RUN_SPEED or NORMAL_SPEED
end

local function setVisualState()
    if runButton:IsA("ImageButton") then
        runButton.ImageColor3 = running and Color3.fromRGB(120, 255, 120) or Color3.fromRGB(255, 255, 255)
    end
end

local function toggleRun()
    running = not running
    applySpeed()
    setVisualState()
    updateRunAnimationState()
end

-- Only enable this system for mobile/touch players.
if not UserInputService.TouchEnabled then
    runButton.Visible = false
    script.Disabled = true
    return
end

if not runButton:IsA("ImageButton") then
    warn("CorrerToggleMobile.local.lua must be parented to ImageButton 'Run'.")
    return
end

runButton.MouseButton1Click:Connect(toggleRun)

player.CharacterAdded:Connect(function(character)
    runTrack = nil

    local humanoid = character:WaitForChild("Humanoid")
    humanoid.WalkSpeed = NORMAL_SPEED

    task.wait(0.1)
    applySpeed()
    setVisualState()
    updateRunAnimationState()
end)

if heartbeatConn then
    heartbeatConn:Disconnect()
end
heartbeatConn = RunService.Heartbeat:Connect(function()
    updateRunAnimationState()
end)

applySpeed()
setVisualState()
updateRunAnimationState()
