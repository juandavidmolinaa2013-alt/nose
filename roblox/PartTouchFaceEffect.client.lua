--[[
    Face UI + camera shake client effect

    Place this LocalScript in StarterPlayer > StarterPlayerScripts.

    Requires existing UI objects (in PlayerGui descendants):
    - ScreenGui named: Effect096
      - TextLabel named: VerCara
      - ImageLabel named: ImagenCalavera

    Both can start invisible; this script will show them for EFFECT_DURATION.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local REMOTE_NAME = "FaceTouchEffectEvent"

-- Easy tuning
local EFFECT_DURATION = 3
local SHAKE_INTENSITY = 0.18
local SHAKE_Z_INTENSITY = 0.08
local FORCE_TEXT = "¡You see his Face!"

local shakeConn: RBXScriptConnection? = nil

local function findGuiObjects(): (TextLabel?, ImageLabel?)
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then
        return nil, nil
    end

    local effectGui = playerGui:FindFirstChild("Effect096", true)
    if not effectGui or not effectGui:IsA("ScreenGui") then
        return nil, nil
    end

    local textObj = effectGui:FindFirstChild("VerCara", true)
    local imageObj = effectGui:FindFirstChild("ImagenCalavera", true)

    if textObj and not textObj:IsA("TextLabel") then
        textObj = nil
    end
    if imageObj and not imageObj:IsA("ImageLabel") then
        imageObj = nil
    end

    return textObj :: TextLabel?, imageObj :: ImageLabel?
end

local function stopShake()
    if shakeConn then
        shakeConn:Disconnect()
        shakeConn = nil
    end
end

local function startShake(duration: number)
    stopShake()

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    local start = time()
    local baseOffset = humanoid.CameraOffset

    shakeConn = RunService.RenderStepped:Connect(function()
        if time() - start >= duration then
            humanoid.CameraOffset = baseOffset
            stopShake()
            return
        end

        local offset = Vector3.new(
            (math.random() - 0.5) * SHAKE_INTENSITY,
            (math.random() - 0.5) * SHAKE_INTENSITY,
            (math.random() - 0.5) * SHAKE_Z_INTENSITY
        )

        humanoid.CameraOffset = baseOffset + offset
    end)
end

local function hideGuiNow()
    local textLabel, imageLabel = findGuiObjects()
    if textLabel then
        textLabel.Visible = false
    end
    if imageLabel then
        imageLabel.Visible = false
    end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.CameraOffset = Vector3.zero
    end
end

local function runEffect()
    local textLabel, imageLabel = findGuiObjects()
    if not textLabel and not imageLabel then
        warn("[PartTouchFaceEffect] No GUI objects found: Effect096/VerCara/ImagenCalavera.")
    end

    if textLabel then
        textLabel.Visible = true
        textLabel.Text = FORCE_TEXT
        textLabel.TextTransparency = 0
        textLabel.ZIndex = math.max(textLabel.ZIndex, 10)
    end
    if imageLabel then
        imageLabel.Visible = true
    end

    startShake(EFFECT_DURATION)

    task.delay(EFFECT_DURATION, function()
        hideGuiNow()
        stopShake()
    end)
end

local function onCharacterAdded(character: Model)
    local hum = character:WaitForChild("Humanoid")
    hum.Died:Connect(function()
        hideGuiNow()
        stopShake()
    end)
end

local remote = ReplicatedStorage:WaitForChild(REMOTE_NAME)
remote.OnClientEvent:Connect(function()
    runEffect()
end)

player.CharacterAdded:Connect(onCharacterAdded)

if player.Character then
    onCharacterAdded(player.Character)
end
