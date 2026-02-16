--[[
    Roblox (Luau) - Head flashlight toggle (client)

    Place this LocalScript in StarterPlayer > StarterPlayerScripts.
    Works with: HeadFlashlight.server.lua

    Toggle key:
    - F (press once on/off)
]]

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local REMOTE_NAME = "HeadFlashlightToggleEvent"
local TOGGLE_KEY = Enum.KeyCode.F

local remote = ReplicatedStorage:WaitForChild(REMOTE_NAME)
local enabled = false

local function toggleFlashlight()
    enabled = not enabled
    remote:FireServer(enabled)
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.KeyCode == TOGGLE_KEY then
        toggleFlashlight()
    end
end)
