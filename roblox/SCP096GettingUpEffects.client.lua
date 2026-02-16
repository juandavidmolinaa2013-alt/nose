--[[
    SCP-096 getting up client effects

    Place this LocalScript in StarterPlayer > StarterPlayerScripts.
    Works with: SCP096ChaseSimplified.server.lua
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local REMOTE_NAME = "SCP096GettingUpEvent"
local remote = ReplicatedStorage:WaitForChild(REMOTE_NAME)

local gui: ScreenGui? = nil
local textLabel: TextLabel? = nil
local imageLabel: ImageLabel? = nil
local shakeConn: RBXScriptConnection? = nil

local function destroyEffects()
    if shakeConn then
        shakeConn:Disconnect()
        shakeConn = nil
    end

    if gui then
        gui:Destroy()
        gui = nil
    end
end

local function createEffects(text: string, imageId: string)
    destroyEffects()

    local playerGui = player:WaitForChild("PlayerGui")

    gui = Instance.new("ScreenGui")
    gui.Name = "SCP096GettingUpFX"
    gui.ResetOnSpawn = true
    gui.IgnoreGuiInset = true
    gui.Parent = playerGui

    textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(0.7, 0, 0.1, 0)
    textLabel.Position = UDim2.new(0.15, 0, 0.08, 0)
    textLabel.BackgroundTransparency = 0.2
    textLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.TextColor3 = Color3.fromRGB(255, 70, 70)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Text = text
    textLabel.Parent = gui

    imageLabel = Instance.new("ImageLabel")
    imageLabel.Size = UDim2.new(0.35, 0, 0.35, 0)
    imageLabel.Position = UDim2.new(0.325, 0, 0.58, 0)
    imageLabel.BackgroundTransparency = 1
    imageLabel.Image = imageId
    imageLabel.Parent = gui
end

local function startShake(duration: number)
    local start = time()
    local originalType = camera.CameraType
    local originalCFrame = camera.CFrame

    shakeConn = RunService.RenderStepped:Connect(function()
        if time() - start >= duration then
            if shakeConn then
                shakeConn:Disconnect()
                shakeConn = nil
            end
            camera.CFrame = originalCFrame
            camera.CameraType = originalType
            return
        end

        local offset = Vector3.new(
            (math.random() - 0.5) * 0.7,
            (math.random() - 0.5) * 0.7,
            (math.random() - 0.5) * 0.5
        )

        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = originalCFrame * CFrame.new(offset)
    end)
end

local function runEffects(payload)
    local duration = typeof(payload.duration) == "number" and payload.duration or 2.5
    local text = typeof(payload.text) == "string" and payload.text or "SCP-096 GETTING UP"
    local image = typeof(payload.image) == "string" and payload.image or "rbxassetid://0"

    createEffects(text, image)
    startShake(duration)

    task.delay(duration, function()
        destroyEffects()
    end)
end

remote.OnClientEvent:Connect(function(payload)
    runEffects(payload)
end)

player.CharacterAdded:Connect(function(character)
    local hum = character:WaitForChild("Humanoid")
    hum.Died:Connect(function()
        destroyEffects()
    end)
end)
