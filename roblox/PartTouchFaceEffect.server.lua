--[[
    Part touch trigger for face UI effect

    Place this Script inside the Part that players touch.

    Expected GUI objects in each player:
    - ScreenGui named: Effect096
      - TextLabel named: VerCara
      - ImageLabel named: ImagenCalavera

    Cooldown rule requested:
    - Once a player activates the part, the trigger is locked globally.
    - It cannot be used again by anyone until that same player dies.

    Camera shake + GUI visibility is handled client-side.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local part = script.Parent
local REMOTE_NAME = "FaceTouchEffectEvent"

local remote = ReplicatedStorage:FindFirstChild(REMOTE_NAME)
if not remote then
    remote = Instance.new("RemoteEvent")
    remote.Name = REMOTE_NAME
    remote.Parent = ReplicatedStorage
end

local activePlayer: Player? = nil
local activeDiedConn: RBXScriptConnection? = nil
local recentTouch: {[Player]: number} = {}
local SAME_PLAYER_TOUCH_DEBOUNCE = 0.25

local function clearActivePlayer()
    activePlayer = nil

    if activeDiedConn then
        activeDiedConn:Disconnect()
        activeDiedConn = nil
    end
end

local function getPlayerFromHit(hit: BasePart): Player?
    local character = hit:FindFirstAncestorOfClass("Model")
    if not character then
        return nil
    end
    return Players:GetPlayerFromCharacter(character)
end

local function bindDeathUnlock(player: Player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    if activeDiedConn then
        activeDiedConn:Disconnect()
        activeDiedConn = nil
    end

    activeDiedConn = humanoid.Died:Connect(function()
        if activePlayer == player then
            clearActivePlayer()
        end
    end)
end

Players.PlayerRemoving:Connect(function(player)
    recentTouch[player] = nil
    if activePlayer == player then
        clearActivePlayer()
    end
end)

part.Touched:Connect(function(hit)
    if not hit or not hit:IsA("BasePart") then
        return
    end

    local player = getPlayerFromHit(hit)
    if not player then
        return
    end

    -- Tiny debounce to avoid multi-touch spam from one contact.
    local now = time()
    local lastTouch = recentTouch[player] or 0
    if now - lastTouch < SAME_PLAYER_TOUCH_DEBOUNCE then
        return
    end
    recentTouch[player] = now

    -- Global lock: if someone already activated, nobody can trigger until that player dies.
    if activePlayer then
        return
    end

    activePlayer = player
    bindDeathUnlock(player)
    remote:FireClient(player)
end)
