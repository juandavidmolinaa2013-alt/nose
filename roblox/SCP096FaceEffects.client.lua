--[[
    SCP-096 face effects (client)

    Place in StarterPlayer > StarterPlayerScripts
    Works with SCP096GettingUpFXBridge.server.lua
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local REMOTE_NAME = "SCP096FaceFXEvent"

local TEXT = "¡You see his Face!"
local IMAGE_ID = "rbxassetid://0" -- set your image id here
local DURATION = 2.5

local gui: ScreenGui? = nil
local shakeConn: RBXScriptConnection? = nil

local function clearEffects()
    if shakeConn then
        shakeConn:Disconnect()
        shakeConn = nil
    end

    if gui then
        gui:Destroy()
        gui = nil
    end
end

local function startShake(duration: number)
    local cam = workspace.CurrentCamera
    if not cam then
        return
    end

    local startTime = time()
    local originalType = cam.CameraType
    local original = cam.CFrame

    shakeConn = RunService.RenderStepped:Connect(function()
        if time() - startTime >= duration then
            if shakeConn then
                shakeConn:Disconnect()
                shakeConn = nil
            end
            cam.CameraType = originalType
            cam.CFrame = original
            return
        end

        local offset = Vector3.new(
            (math.random() - 0.5) * 0.7,
            (math.random() - 0.5) * 0.7,
            (math.random() - 0.5) * 0.4
        )
        cam.CameraType = Enum.CameraType.Scriptable
        cam.CFrame = original * CFrame.new(offset)
    end)
end

local function showEffects()
    clearEffects()

    local playerGui = player:WaitForChild("PlayerGui")

    gui = Instance.new("ScreenGui")
    gui.Name = "SCP096FaceFX"
    gui.ResetOnSpawn = true
    gui.IgnoreGuiInset = true
    gui.Parent = playerGui

    local image = Instance.new("ImageLabel")
    image.BackgroundTransparency = 1
    image.Size = UDim2.new(0.35, 0, 0.3, 0)
    image.Position = UDim2.new(0.325, 0, 0.12, 0)
    image.Image = IMAGE_ID
    image.Parent = gui

    local text = Instance.new("TextLabel")
    text.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    text.BackgroundTransparency = 0.25
    text.Size = UDim2.new(0.7, 0, 0.1, 0)
    text.Position = UDim2.new(0.15, 0, 0.45, 0)
    text.TextScaled = true
    text.Font = Enum.Font.GothamBold
    text.TextColor3 = Color3.fromRGB(255, 0, 0)
    text.Text = TEXT
    text.Parent = gui

    startShake(DURATION)

    task.delay(DURATION, function()
        clearEffects()
    end)
end

local remote = ReplicatedStorage:WaitForChild(REMOTE_NAME)
remote.OnClientEvent:Connect(function()
    showEffects()
end)

player.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid")
    hum.Died:Connect(function()
        clearEffects()
    end)
end)
