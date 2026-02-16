--[[
    Roblox (Luau) - Noclip by chat command (more reliable)

    Place this Script in ServerScriptService.

    Commands (accepted):
    - /noclip, noclip, !noclip, /e noclip
    - /clip, clip, !clip, /e clip
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")

local ADMINS = {
    3265730064,
}

-- If you want to test quickly without setting ADMINS, set this true.
local ALLOW_ALL_PLAYERS_FOR_TESTING = false

local NOCLIP_ALIASES = {
    ["/noclip"] = true,
    ["noclip"] = true,
    ["!noclip"] = true,
    ["/e noclip"] = true,
}

local CLIP_ALIASES = {
    ["/clip"] = true,
    ["clip"] = true,
    ["!clip"] = true,
    ["/e clip"] = true,
}

local NOCLIP_GROUP = "NoClipPlayers"
local ANTIFALL_ATTACHMENT_NAME = "NoClipAntiFallAttachment"
local ANTIFALL_FORCE_NAME = "NoClipAntiFallForce"
local noclipEnabled: {[Player]: boolean} = {}

local function isAdmin(userId: number): boolean
    if ALLOW_ALL_PLAYERS_FOR_TESTING then
        return true
    end

    for _, id in ipairs(ADMINS) do
        if id == userId then
            return true
        end
    end
    return false
end

local function normalizeMessage(message: string): string
    local lowered = string.lower(message)
    return string.gsub(lowered, "^%s*(.-)%s*$", "%1")
end

local function getRegisteredGroupNames(): {string}
    local names = {}

    local okNew, groupsNew = pcall(function()
        return PhysicsService:GetRegisteredCollisionGroups()
    end)

    if okNew and groupsNew then
        for _, info in ipairs(groupsNew) do
            table.insert(names, info.name)
        end
        return names
    end

    local okOld, groupsOld = pcall(function()
        return PhysicsService:GetCollisionGroups()
    end)

    if okOld and groupsOld then
        for _, info in ipairs(groupsOld) do
            table.insert(names, info.name)
        end
    end

    return names
end

local function ensureNoClipGroup()
    local names = getRegisteredGroupNames()
    local exists = false
    for _, groupName in ipairs(names) do
        if groupName == NOCLIP_GROUP then
            exists = true
            break
        end
    end

    if not exists then
        pcall(function()
            PhysicsService:RegisterCollisionGroup(NOCLIP_GROUP)
        end)
    end

    -- Make noclip group non-collidable with every existing group.
    local refreshed = getRegisteredGroupNames()
    for _, groupName in ipairs(refreshed) do
        pcall(function()
            PhysicsService:CollisionGroupSetCollidable(NOCLIP_GROUP, groupName, false)
        end)
    end
end


local function removeAntiFall(root: BasePart)
    local force = root:FindFirstChild(ANTIFALL_FORCE_NAME)
    if force and force:IsA("VectorForce") then
        force:Destroy()
    end

    local att = root:FindFirstChild(ANTIFALL_ATTACHMENT_NAME)
    if att and att:IsA("Attachment") then
        att:Destroy()
    end
end

local function ensureAntiFall(root: BasePart)
    local attachment = root:FindFirstChild(ANTIFALL_ATTACHMENT_NAME)
    if not attachment or not attachment:IsA("Attachment") then
        attachment = Instance.new("Attachment")
        attachment.Name = ANTIFALL_ATTACHMENT_NAME
        attachment.Parent = root
    end

    local force = root:FindFirstChild(ANTIFALL_FORCE_NAME)
    if not force or not force:IsA("VectorForce") then
        force = Instance.new("VectorForce")
        force.Name = ANTIFALL_FORCE_NAME
        force.RelativeTo = Enum.ActuatorRelativeTo.World
        force.ApplyAtCenterOfMass = true
        force.Attachment0 = attachment
        force.Parent = root
    end

    -- Counter gravity so player doesn't fall through the map while noclip is active.
    force.Force = Vector3.new(0, root.AssemblyMass * workspace.Gravity, 0)
end
local function setCharacterNoClip(character: Model)
    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.CollisionGroup = NOCLIP_GROUP
        end
    end

    local root = character:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        ensureAntiFall(root)
    end
end

local function setCharacterClip(character: Model)
    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.CanCollide = true
            descendant.CanTouch = true
            descendant.CollisionGroup = "Default"
        end
    end

    local root = character:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        removeAntiFall(root)
    end
end

ensureNoClipGroup()

Players.PlayerAdded:Connect(function(player)
    noclipEnabled[player] = false

    player.CharacterAdded:Connect(function(character)
        character.DescendantAdded:Connect(function(descendant)
            if noclipEnabled[player] and descendant:IsA("BasePart") then
                descendant.CanCollide = false
                descendant.CanTouch = false
                descendant.CollisionGroup = NOCLIP_GROUP
            end
        end)

        if noclipEnabled[player] then
            setCharacterNoClip(character)
        else
            setCharacterClip(character)
        end
    end)

    player.Chatted:Connect(function(message)
        if not isAdmin(player.UserId) then
            return
        end

        local msg = normalizeMessage(message)

        if NOCLIP_ALIASES[msg] then
            noclipEnabled[player] = true
            local character = player.Character
            if character then
                setCharacterNoClip(character)
            end
        elseif CLIP_ALIASES[msg] then
            noclipEnabled[player] = false
            local character = player.Character
            if character then
                setCharacterClip(character)
            end
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    noclipEnabled[player] = nil
end)

-- Keep noclip enforced (some systems reset collision properties).
RunService.Heartbeat:Connect(function()
    for player, enabled in pairs(noclipEnabled) do
        if enabled then
            local character = player.Character
            if character then
                setCharacterNoClip(character)
            end
        end
    end
end)
