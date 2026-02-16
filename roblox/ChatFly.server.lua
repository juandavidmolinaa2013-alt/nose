--[[
    Roblox (Luau) - Fly command (chat) + flight animations by AnimationId

    Place this Script in ServerScriptService.

    Command examples:
    - /Fly
    - /Unfly

    Setup:
    1) Add your admin UserIds in ADMINS.
    2) Also place FlyClient.local.lua in StarterPlayer > StarterPlayerScripts.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ADMINS = {
    12345678, -- replace with your UserId
}

local FLY_ON_COMMAND = "/fly"
local FLY_OFF_COMMAND = "/unfly"
local REMOTE_NAME = "FlyToggleRemote"

local remote = ReplicatedStorage:FindFirstChild(REMOTE_NAME)
if not remote then
    remote = Instance.new("RemoteEvent")
    remote.Name = REMOTE_NAME
    remote.Parent = ReplicatedStorage
end

local function isAdmin(userId: number): boolean
    for _, id in ipairs(ADMINS) do
        if id == userId then
            return true
        end
    end
    return false
end

local function normalizeMessage(message: string): string
    return string.lower(string.gsub(message, "^%s*(.-)%s*$", "%1"))
end

Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(message)
        local msg = normalizeMessage(message)

        if not isAdmin(player.UserId) then
            return
        end

        if msg == FLY_ON_COMMAND then
            remote:FireClient(player, true)
        elseif msg == FLY_OFF_COMMAND then
            remote:FireClient(player, false)
        end
    end)
end)
