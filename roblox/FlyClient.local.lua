--[[
    Roblox (Luau) - Client flight controller
    Place this LocalScript in StarterPlayer > StarterPlayerScripts.

    Receives on/off from ChatFly.server.lua via RemoteEvent: FlyToggleRemote

    Animation IDs (replace with your own):
    - FLY_IDLE_ANIMATION_ID: when flying and not moving
    - FLY_MOVE_ANIMATION_ID: when flying and moving
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local REMOTE_NAME = "FlyToggleRemote"

-- Replace with your own animation ids
local FLY_IDLE_ANIMATION_ID = "rbxassetid://0000000000"
local FLY_MOVE_ANIMATION_ID = "rbxassetid://0000000000"

local FLY_SPEED = 80
local VERTICAL_SPEED = 60
local MOBILE_PITCH_DEADZONE = 0.15

local isFlying = false
local moveUp = false
local moveDown = false
local moveForward = false
local moveBackward = false
local moveLeft = false
local moveRight = false
local heartbeatConn: RBXScriptConnection? = nil

local bodyVelocity: BodyVelocity? = nil
local bodyGyro: BodyGyro? = nil

local idleTrack: AnimationTrack? = nil
local moveTrack: AnimationTrack? = nil

local function getForwardRightFromCamera(cam: Camera, root: BasePart): (Vector3, Vector3)
    local forward = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
    if forward.Magnitude < 0.001 then
        forward = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
    end
    forward = forward.Unit

    local right = Vector3.new(cam.CFrame.RightVector.X, 0, cam.CFrame.RightVector.Z)
    if right.Magnitude < 0.001 then
        right = forward:Cross(Vector3.yAxis)
    end
    right = right.Unit

    return forward, right
end

local function getHorizontalInput(humanoid: Humanoid, cam: Camera, root: BasePart): Vector3
    local forward, right = getForwardRightFromCamera(cam, root)

    local horizontalInput = Vector3.zero
    if moveForward then
        horizontalInput += forward
    end
    if moveBackward then
        horizontalInput -= forward
    end
    if moveRight then
        horizontalInput += right
    end
    if moveLeft then
        horizontalInput -= right
    end

    -- Mobile Roblox joystick support
    if UserInputService.TouchEnabled then
        local moveDir = humanoid.MoveDirection
        if moveDir.Magnitude > 0 then
            horizontalInput += Vector3.new(moveDir.X, 0, moveDir.Z)
        end
    end

    if horizontalInput.Magnitude > 0 then
        return horizontalInput.Unit
    end

    return Vector3.zero
end

local function getVerticalInput(cam: Camera): number
    local vertical = 0

    -- Keyboard controls (PC)
    if moveUp then
        vertical += 1
    end
    if moveDown then
        vertical -= 1
    end

    -- Mobile controls: ascend/descend by camera pitch
    if UserInputService.TouchEnabled then
        local pitch = cam.CFrame.LookVector.Y
        if math.abs(pitch) >= MOBILE_PITCH_DEADZONE then
            vertical = pitch
        else
            vertical = 0
        end
    end

    return math.clamp(vertical, -1, 1)
end

local function stopTrack(track: AnimationTrack?)
    if track and track.IsPlaying then
        track:Stop(0.15)
    end
end

local function playTrack(track: AnimationTrack?)
    if track and (not track.IsPlaying) then
        track:Play(0.15)
    end
end

local function loadAnimations(humanoid: Humanoid)
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end

    local idleAnim = Instance.new("Animation")
    idleAnim.AnimationId = FLY_IDLE_ANIMATION_ID
    idleTrack = animator:LoadAnimation(idleAnim)
    idleTrack.Priority = Enum.AnimationPriority.Action
    idleTrack.Looped = true

    local moveAnim = Instance.new("Animation")
    moveAnim.AnimationId = FLY_MOVE_ANIMATION_ID
    moveTrack = animator:LoadAnimation(moveAnim)
    moveTrack.Priority = Enum.AnimationPriority.Action
    moveTrack.Looped = true
end

local function cleanupFlight(character: Model)
    stopTrack(idleTrack)
    stopTrack(moveTrack)

    if heartbeatConn then
        heartbeatConn:Disconnect()
        heartbeatConn = nil
    end

    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end

    if bodyGyro then
        bodyGyro:Destroy()
        bodyGyro = nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.PlatformStand = false
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end

local function startFlight(character: Model)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root or not root:IsA("BasePart") then
        return
    end

    loadAnimations(humanoid)

    humanoid.PlatformStand = true

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bodyGyro.P = 9e4
    bodyGyro.CFrame = root.CFrame
    bodyGyro.Parent = root

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bodyVelocity.Velocity = Vector3.zero
    bodyVelocity.Parent = root

    heartbeatConn = RunService.Heartbeat:Connect(function()
        if not isFlying or not bodyVelocity or not bodyGyro then
            return
        end

        local cam = workspace.CurrentCamera
        if not cam then
            return
        end

        local vertical = getVerticalInput(cam)
        local horizontal = getHorizontalInput(humanoid, cam, root)
        local velocity = horizontal * FLY_SPEED + Vector3.new(0, vertical * VERTICAL_SPEED, 0)
        bodyVelocity.Velocity = velocity
        bodyGyro.CFrame = CFrame.new(root.Position, root.Position + cam.CFrame.LookVector)

        local moving = velocity.Magnitude > 1
        if moving then
            stopTrack(idleTrack)
            playTrack(moveTrack)
        else
            stopTrack(moveTrack)
            playTrack(idleTrack)
        end
    end)
end

local function setFlying(enabled: boolean)
    local character = player.Character or player.CharacterAdded:Wait()

    if enabled == isFlying then
        return
    end

    isFlying = enabled
    if isFlying then
        startFlight(character)
    else
        cleanupFlight(character)
    end
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.KeyCode == Enum.KeyCode.Space then
        moveUp = true
    elseif input.KeyCode == Enum.KeyCode.LeftControl then
        moveDown = true
    elseif input.KeyCode == Enum.KeyCode.W then
        moveForward = true
    elseif input.KeyCode == Enum.KeyCode.S then
        moveBackward = true
    elseif input.KeyCode == Enum.KeyCode.A then
        moveLeft = true
    elseif input.KeyCode == Enum.KeyCode.D then
        moveRight = true
    end
end)

UserInputService.InputEnded:Connect(function(input, _)
    if input.KeyCode == Enum.KeyCode.Space then
        moveUp = false
    elseif input.KeyCode == Enum.KeyCode.LeftControl then
        moveDown = false
    elseif input.KeyCode == Enum.KeyCode.W then
        moveForward = false
    elseif input.KeyCode == Enum.KeyCode.S then
        moveBackward = false
    elseif input.KeyCode == Enum.KeyCode.A then
        moveLeft = false
    elseif input.KeyCode == Enum.KeyCode.D then
        moveRight = false
    end
end)

player.CharacterAdded:Connect(function(character)
    if isFlying then
        task.defer(function()
            startFlight(character)
        end)
    end
end)

local remote = ReplicatedStorage:WaitForChild(REMOTE_NAME)
if remote and remote:IsA("RemoteEvent") then
    remote.OnClientEvent:Connect(function(enabled: boolean)
        setFlying(enabled)
    end)
end
