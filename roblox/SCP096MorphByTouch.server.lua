--[[
    Roblox (Luau) - Touch Part "096" to morph into rig "SCP-096"

    Place this Script in ServerScriptService.

    Required:
    - Workspace Part named: 096
    - Morph rig model named: SCP-096 (recommended in ServerStorage)
      with Humanoid + HumanoidRootPart

    Put your own animation IDs below.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local TOUCH_PART_NAME = "096"
local RIG_NAME = "SCP-096"

-- YOUR ANIMATION IDS HERE
local WALK_ANIMATION_ID = "rbxassetid://0000000000"
local IDLE_ANIMATION_ID = "rbxassetid://0000000000"
local QUIETO_1_ANIMATION_ID = "rbxassetid://0000000000"
local QUIETO_2_ANIMATION_ID = "rbxassetid://0000000000"
local QUIETO_3_ANIMATION_ID = "rbxassetid://0000000000"

local TOUCH_DEBOUNCE = 2
local MOVE_THRESHOLD = 0.05
local QUIETO_SEQUENCE_DELAY = 60 -- 1 minute
local SLIDE_STOP_SPEED = 1.5 -- if horizontal speed is below this while idle, force stop to avoid drifting

local CAMERA_FIX_REMOTE_NAME = "SCP096MorphCameraRebind"

type AnimBundle = {
	walk: AnimationTrack?,
	idle: AnimationTrack?,
	quieto1: AnimationTrack?,
	quieto2: AnimationTrack?,
	quieto3: AnimationTrack?,
}

local touchDebounce: {[Player]: number} = {}
local loopConnByPlayer: {[Player]: RBXScriptConnection} = {}


local cameraFixRemote = ReplicatedStorage:FindFirstChild(CAMERA_FIX_REMOTE_NAME)
if not cameraFixRemote then
	cameraFixRemote = Instance.new("RemoteEvent")
	cameraFixRemote.Name = CAMERA_FIX_REMOTE_NAME
	cameraFixRemote.Parent = ReplicatedStorage
end

local function normalizeAnimId(id: string): string
	if id == "" then
		return ""
	end
	if string.find(id, "rbxassetid://", 1, true) then
		return id
	end
	local n = string.match(id, "%d+")
	if n then
		return "rbxassetid://" .. n
	end
	return id
end

local function findRigTemplate(): Model?
	local a = ServerStorage:FindFirstChild(RIG_NAME)
	if a and a:IsA("Model") then
		return a
	end
	local b = ReplicatedStorage:FindFirstChild(RIG_NAME)
	if b and b:IsA("Model") then
		return b
	end
	local c = Workspace:FindFirstChild(RIG_NAME)
	if c and c:IsA("Model") then
		return c
	end
	return nil
end

local function stopTrack(track: AnimationTrack?)
	if track and track.IsPlaying then
		track:Stop(0.15)
	end
end

local function playTrack(track: AnimationTrack?)
	if track and not track.IsPlaying then
		track:Play(0.15)
	end
end

local function loadTrack(animator: Animator, id: string, priority: Enum.AnimationPriority, looped: boolean): AnimationTrack?
	local fixed = normalizeAnimId(id)
	if fixed == "" or fixed == "rbxassetid://0000000000" then
		return nil
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = fixed
	local track = animator:LoadAnimation(animation)
	track.Priority = priority
	track.Looped = looped
	return track
end

local function loadAnimations(humanoid: Humanoid): AnimBundle
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	return {
		walk = loadTrack(animator, WALK_ANIMATION_ID, Enum.AnimationPriority.Movement, true),
		idle = loadTrack(animator, IDLE_ANIMATION_ID, Enum.AnimationPriority.Idle, true),
		quieto1 = loadTrack(animator, QUIETO_1_ANIMATION_ID, Enum.AnimationPriority.Action, false),
		quieto2 = loadTrack(animator, QUIETO_2_ANIMATION_ID, Enum.AnimationPriority.Action, false),
		quieto3 = loadTrack(animator, QUIETO_3_ANIMATION_ID, Enum.AnimationPriority.Action, false),
	}
end

local function stopAll(bundle: AnimBundle)
	stopTrack(bundle.walk)
	stopTrack(bundle.idle)
	stopTrack(bundle.quieto1)
	stopTrack(bundle.quieto2)
	stopTrack(bundle.quieto3)
end

local function stopQuieto(bundle: AnimBundle)
	stopTrack(bundle.quieto1)
	stopTrack(bundle.quieto2)
	stopTrack(bundle.quieto3)
end

local function playQuieto(track: AnimationTrack?)
	if not track then
		return
	end
	playTrack(track)
	task.wait(track.Length > 0 and track.Length or 1)
	stopTrack(track)
end

local function stopHorizontalSlide(humanoid: Humanoid)
	local root = humanoid.RootPart
	if not root or not root:IsA("BasePart") then
		return
	end

	local velocity = root.AssemblyLinearVelocity
	local horizontal = Vector3.new(velocity.X, 0, velocity.Z)
	if horizontal.Magnitude <= SLIDE_STOP_SPEED then
		root.AssemblyLinearVelocity = Vector3.new(0, velocity.Y, 0)
	end
end

local function startAnimationLoop(player: Player, humanoid: Humanoid)
	if loopConnByPlayer[player] then
		loopConnByPlayer[player]:Disconnect()
		loopConnByPlayer[player] = nil
	end

	local bundle = loadAnimations(humanoid)
	local stillTime = 0
	local quietoRunning = false
	local token = 0

	local function runQuietoSequence(thisToken: number)
		if quietoRunning then
			return
		end
		quietoRunning = true

		stopTrack(bundle.walk)
		stopTrack(bundle.idle)

		playQuieto(bundle.quieto1)
		if token ~= thisToken or humanoid.Health <= 0 then quietoRunning = false return end
		playQuieto(bundle.quieto2)
		if token ~= thisToken or humanoid.Health <= 0 then quietoRunning = false return end
		playQuieto(bundle.quieto3)
		if token ~= thisToken or humanoid.Health <= 0 then quietoRunning = false return end

		playTrack(bundle.idle)
		quietoRunning = false
		stillTime = 0
	end

	loopConnByPlayer[player] = RunService.Heartbeat:Connect(function(dt)
		if humanoid.Health <= 0 then
			stopAll(bundle)
			return
		end

		local moving = humanoid.MoveDirection.Magnitude > MOVE_THRESHOLD
		if moving then
			stillTime = 0
			token += 1
			quietoRunning = false
			stopQuieto(bundle)
			stopTrack(bundle.idle)
			playTrack(bundle.walk)
			return
		end

		stopTrack(bundle.walk)
		stopHorizontalSlide(humanoid)
		stillTime += dt

		if quietoRunning then
			return
		end

		if stillTime >= QUIETO_SEQUENCE_DELAY then
			token += 1
			local snapshot = token
			task.spawn(function()
				runQuietoSequence(snapshot)
			end)
		else
			playTrack(bundle.idle)
		end
	end)

	humanoid.Died:Connect(function()
		token += 1
		quietoRunning = false
		if loopConnByPlayer[player] then
			loopConnByPlayer[player]:Disconnect()
			loopConnByPlayer[player] = nil
		end
		stopAll(bundle)
	end)
end

local function getPlayerFromHit(hit: BasePart): Player?
	local model = hit:FindFirstAncestorOfClass("Model")
	if not model then
		return nil
	end
	return Players:GetPlayerFromCharacter(model)
end

local function morphPlayer(player: Player)
	local oldCharacter = player.Character
	if not oldCharacter then
		return
	end

	local oldRoot = oldCharacter:FindFirstChild("HumanoidRootPart")
	local spawnCFrame = oldRoot and oldRoot:IsA("BasePart") and oldRoot.CFrame or CFrame.new(0, 10, 0)

	local template = findRigTemplate()
	if not template then
		warn("[SCP096MorphByTouch] Rig SCP-096 not found.")
		return
	end

	local newCharacter = template:Clone()
	newCharacter.Name = player.Name

	local humanoid = newCharacter:FindFirstChildOfClass("Humanoid")
	local root = newCharacter:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or not root:IsA("BasePart") then
		warn("[SCP096MorphByTouch] Rig invalid (needs Humanoid + HumanoidRootPart).")
		newCharacter:Destroy()
		return
	end

	for _, d in ipairs(newCharacter:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
		end
	end

	newCharacter.Parent = Workspace
	newCharacter:PivotTo(spawnCFrame)

	-- Assign new character first, then cleanup old one to reduce camera/replication glitches.
	player.Character = newCharacter
	task.defer(function()
		if oldCharacter and oldCharacter.Parent then
			oldCharacter:Destroy()
		end
	end)

	startAnimationLoop(player, humanoid)
	cameraFixRemote:FireClient(player)
end

local touchPart = Workspace:FindFirstChild(TOUCH_PART_NAME)
if not touchPart or not touchPart:IsA("BasePart") then
	warn("[SCP096MorphByTouch] Part '096' not found in Workspace.")
	return
end

touchPart.Touched:Connect(function(hit)
	if not hit or not hit:IsA("BasePart") then
		return
	end

	local player = getPlayerFromHit(hit)
	if not player then
		return
	end

	local now = time()
	local last = touchDebounce[player] or 0
	if now - last < TOUCH_DEBOUNCE then
		return
	end
	touchDebounce[player] = now

	morphPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
	touchDebounce[player] = nil
	if loopConnByPlayer[player] then
		loopConnByPlayer[player]:Disconnect()
		loopConnByPlayer[player] = nil
	end
end)
