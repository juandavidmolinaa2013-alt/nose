--[[
    Roblox (Luau) - Camera fix for SCP096 morph

    Place this LocalScript in StarterPlayer > StarterPlayerScripts.

    Fixes camera freeze by rebinding camera to the latest humanoid:
    - on CharacterAdded
    - when server explicitly signals morph completion
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local REMOTE_NAME = "SCP096MorphCameraRebind"

local function bindCameraToCurrentCharacter()
    local character = player.Character
    if not character then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 2)
    local camera = workspace.CurrentCamera
    if not humanoid or not camera then
        return
    end

    camera.CameraType = Enum.CameraType.Custom
    camera.CameraSubject = humanoid
end

local function rebindWithRetries()
    for _ = 1, 6 do
        bindCameraToCurrentCharacter()
        task.wait(0.1)
    end
end

player.CharacterAdded:Connect(function()
    task.defer(rebindWithRetries)
end)

local remote = ReplicatedStorage:FindFirstChild(REMOTE_NAME)
if remote and remote:IsA("RemoteEvent") then
    remote.OnClientEvent:Connect(function()
        task.defer(rebindWithRetries)
    end)
end

if player.Character then
    task.defer(rebindWithRetries)
end
