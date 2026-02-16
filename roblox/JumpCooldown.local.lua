--[[
    Roblox (Luau) - Jump cooldown (2 seconds)

    Place this LocalScript in:
    StarterPlayer > StarterPlayerScripts

    Effect:
    - The first jump works normally.
    - Next jumps are allowed only after cooldown time.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local JUMP_COOLDOWN = 2

local nextJumpTime = 0

local function getHumanoid(): Humanoid?
    local character = player.Character
    if not character then
        return nil
    end
    return character:FindFirstChildOfClass("Humanoid")
end

local function canJumpNow(): boolean
    return time() >= nextJumpTime
end

local function onJumpRequest()
    local humanoid = getHumanoid()
    if not humanoid then
        return
    end

    if canJumpNow() then
        nextJumpTime = time() + JUMP_COOLDOWN
        humanoid:SetAttribute("JumpCooldownEndsAt", nextJumpTime)
        -- Let jump happen naturally.
        return
    end

    -- Block only this jump input during cooldown.
    humanoid.Jump = false
end

player.CharacterAdded:Connect(function(character)
    character:WaitForChild("Humanoid")
    nextJumpTime = 0
end)

UserInputService.JumpRequest:Connect(onJumpRequest)
