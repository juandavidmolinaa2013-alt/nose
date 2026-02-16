--[[
    Roblox (Luau) - Sprint for Mobile button + PlayStation L2 hold

    Place this LocalScript in StarterPlayer > StarterPlayerScripts.

    Behavior:
    - Mobile: shows a sprint button only on touch devices.
    - PlayStation/Gamepad: holding L2 (ButtonL2) enables sprint.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local NORMAL_SPEED = 16
local SPRINT_SPEED = 28

local mobileHolding = false
local gamepadHolding = false

local sprintGui: ScreenGui? = nil
local sprintButton: TextButton? = nil

local function isSprinting(): boolean
    return mobileHolding or gamepadHolding
end

local function applySpeed(character: Model?)
    if not character then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    if isSprinting() then
        humanoid.WalkSpeed = SPRINT_SPEED
    else
        humanoid.WalkSpeed = NORMAL_SPEED
    end
end

local function getCharacter(): Model?
    return player.Character
end

local function setMobileHolding(holding: boolean)
    mobileHolding = holding
    applySpeed(getCharacter())
end

local function setGamepadHolding(holding: boolean)
    gamepadHolding = holding
    applySpeed(getCharacter())
end

local function createMobileButton()
    if not UserInputService.TouchEnabled then
        return
    end

    local playerGui = player:WaitForChild("PlayerGui")

    sprintGui = Instance.new("ScreenGui")
    sprintGui.Name = "SprintMobileGui"
    sprintGui.ResetOnSpawn = false
    sprintGui.IgnoreGuiInset = true
    sprintGui.Parent = playerGui

    sprintButton = Instance.new("TextButton")
    sprintButton.Name = "SprintButton"
    sprintButton.Size = UDim2.fromOffset(140, 140)
    sprintButton.AnchorPoint = Vector2.new(1, 1)
    sprintButton.Position = UDim2.new(1, -35, 1, -35)
    sprintButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    sprintButton.BackgroundTransparency = 0.25
    sprintButton.TextColor3 = Color3.new(1, 1, 1)
    sprintButton.TextScaled = true
    sprintButton.Font = Enum.Font.GothamBold
    sprintButton.Text = "RUN"
    sprintButton.Parent = sprintGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = sprintButton

    sprintButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            setMobileHolding(true)
        end
    end)

    sprintButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            setMobileHolding(false)
        end
    end)
end

player.CharacterAdded:Connect(function(character)
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.WalkSpeed = NORMAL_SPEED
    applySpeed(character)
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.KeyCode == Enum.KeyCode.ButtonL2 then
        setGamepadHolding(true)
    end
end)

UserInputService.InputEnded:Connect(function(input, _)
    if input.KeyCode == Enum.KeyCode.ButtonL2 then
        setGamepadHolding(false)
    end
end)

createMobileButton()
applySpeed(getCharacter())
