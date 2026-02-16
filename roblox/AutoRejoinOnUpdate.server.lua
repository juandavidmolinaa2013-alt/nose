--[[
    Roblox (Luau) - Auto rejoin players into updated servers

    Place this Script in ServerScriptService.

    How it works:
    - Each code release has a BUILD_ID (string).
    - Servers store/read the latest BUILD_ID from MemoryStore.
    - If a server detects it is outdated, it teleports all players together
      to a new reserved server (latest code) so players don't rejoin manually.

    Important:
    - Update BUILD_ID on every publish (e.g. "2026-02-15_01").
]]

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local MemoryStoreService = game:GetService("MemoryStoreService")

local PLACE_ID = game.PlaceId
local BUILD_ID = "2026-02-15_01" -- change this every time you publish

local STORE_NAME = "LIVE_BUILD_VERSION"
local KEY_NAME = "CURRENT_BUILD"
local CHECK_INTERVAL = 10

local map = MemoryStoreService:GetSortedMap(STORE_NAME)
local isTeleporting = false

local function setLatestBuild()
    local ok, err = pcall(function()
        -- TTL 30 days
        map:SetAsync(KEY_NAME, BUILD_ID, 60 * 60 * 24 * 30)
    end)
    if not ok then
        warn("[AutoRejoinOnUpdate] Failed to set latest build:", err)
    end
end

local function getLatestBuild(): string?
    local ok, value = pcall(function()
        return map:GetAsync(KEY_NAME)
    end)
    if not ok then
        warn("[AutoRejoinOnUpdate] Failed to read latest build:", value)
        return nil
    end

    if typeof(value) == "string" then
        return value
    end
    return nil
end

local function getPlayersSnapshot(): {Player}
    local snapshot = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        table.insert(snapshot, plr)
    end
    return snapshot
end

local function teleportAllPlayersTogether()
    if isTeleporting then
        return
    end
    isTeleporting = true

    local players = getPlayersSnapshot()
    if #players == 0 then
        isTeleporting = false
        return
    end

    local options = Instance.new("TeleportOptions")
    options.ShouldReserveServer = true

    local ok, err = pcall(function()
        TeleportService:TeleportAsync(PLACE_ID, players, options)
    end)

    if not ok then
        warn("[AutoRejoinOnUpdate] Teleport failed:", err)
        isTeleporting = false
    end
end

-- Publish current server build as latest when server starts.
setLatestBuild()

while task.wait(CHECK_INTERVAL) do
    local latestBuild = getLatestBuild()
    if latestBuild and latestBuild ~= BUILD_ID then
        warn(("[AutoRejoinOnUpdate] Outdated server (%s). Latest is %s. Rejoining players..."):format(BUILD_ID, latestBuild))
        teleportAllPlayersTogether()
    end
end
