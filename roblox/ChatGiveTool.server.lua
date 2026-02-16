--[[
    Roblox (Luau) - Chat command giver
    Place this Script in ServerScriptService.

    Setup:
    1) Put your Tools in ServerStorage.
    2) Set your admin UserIds in ADMINS.
    3) In game chat, type examples:
       - /Give Card
       - /Give My Cool Tool

    Matching rules:
    - Case-insensitive name match.
    - Supports tool names with spaces.
    - Supports aliases so command still works even if tool is renamed:
      Add Attribute `GiveAliases` (string, comma-separated), e.g. "Card,BlackCard,IDCard"
]]

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local ADMINS = {
    3265730064,
}

local COMMAND = "/give" -- case-insensitive

local function isAdmin(userId: number): boolean
    for _, id in ipairs(ADMINS) do
        if id == userId then
            return true
        end
    end
    return false
end

local function normalize(text: string): string
    return string.lower(string.gsub(text, "^%s*(.-)%s*$", "%1"))
end

local function splitWords(text: string): {string}
    local words = {}
    for word in string.gmatch(text, "%S+") do
        table.insert(words, word)
    end
    return words
end

local function getToolAliases(tool: Tool): {string}
    local aliases = {}

    local attr = tool:GetAttribute("GiveAliases")
    if typeof(attr) == "string" then
        for part in string.gmatch(attr, "[^,]+") do
            table.insert(aliases, normalize(part))
        end
    end

    return aliases
end

local function resolveTool(query: string): Tool?
    local normalizedQuery = normalize(query)

    -- 1) Exact name (case-insensitive)
    for _, child in ipairs(ServerStorage:GetChildren()) do
        if child:IsA("Tool") and normalize(child.Name) == normalizedQuery then
            return child
        end
    end

    -- 2) Alias match (survives rename if alias kept)
    for _, child in ipairs(ServerStorage:GetChildren()) do
        if child:IsA("Tool") then
            local aliases = getToolAliases(child)
            for _, alias in ipairs(aliases) do
                if alias == normalizedQuery then
                    return child
                end
            end
        end
    end

    -- 3) Partial name match fallback
    for _, child in ipairs(ServerStorage:GetChildren()) do
        if child:IsA("Tool") and string.find(normalize(child.Name), normalizedQuery, 1, true) then
            return child
        end
    end

    return nil
end

local function giveTool(player: Player, toolQuery: string)
    local tool = resolveTool(toolQuery)
    if not tool then
        warn(("Tool query '%s' not found in ServerStorage."):format(toolQuery))
        return
    end

    local clone = tool:Clone()
    clone.Parent = player:WaitForChild("Backpack")
end

Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(message)
        local args = splitWords(message)
        if #args < 2 then
            return
        end

        if normalize(args[1]) ~= COMMAND then
            return
        end

        if not isAdmin(player.UserId) then
            return
        end

        -- Supports tool names with spaces: /give My Tool Name
        local toolQuery = table.concat(args, " ", 2)
        giveTool(player, toolQuery)
    end)
end)
