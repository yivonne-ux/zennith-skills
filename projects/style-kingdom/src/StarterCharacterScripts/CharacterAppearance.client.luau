--!strict
-- Style Kingdom — CharacterAppearance
-- Character setup: walk speed, name display, runway animation hooks

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Wait for character to be fully loaded
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:FindFirstChildWhichIsA("Humanoid")

-- If humanoid not found yet, wait briefly (don't infinite yield)
if not humanoid then
	humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
end

if not humanoid then
	warn("[CharacterAppearance] No humanoid found, skipping setup")
	return
end

local events = ReplicatedStorage:WaitForChild("Remotes", 5)
if not events then
	return
end
local eventsFolder = events:FindFirstChild("Events")
if not eventsFolder then
	return
end

-- ============================================================
-- CHARACTER SETUP
-- ============================================================
humanoid.WalkSpeed = 16
humanoid.JumpHeight = 7.2
humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
humanoid.HealthDisplayDistance = 0 -- No combat, hide health
humanoid.NameDisplayDistance = 50

-- ============================================================
-- RUNWAY WALK ANIMATION
-- ============================================================
local currentRunwayTrack: AnimationTrack? = nil

local runwayStartEvent = eventsFolder:FindFirstChild("ContestRunwayStart")
if runwayStartEvent then
	(runwayStartEvent :: RemoteEvent).OnClientEvent:Connect(function(walkerUserId: number)
		if walkerUserId == player.UserId and humanoid then
			-- Use default walk for now (custom anim added later with real asset ID)
			humanoid.WalkSpeed = 8 -- Slow runway walk
		end
	end)
end

local contestStateEvent = eventsFolder:FindFirstChild("ContestStateChanged")
if contestStateEvent then
	(contestStateEvent :: RemoteEvent).OnClientEvent:Connect(function(newState: string)
		if newState ~= "RUNWAY" and humanoid then
			humanoid.WalkSpeed = 16 -- Restore normal speed
			if currentRunwayTrack then
				currentRunwayTrack:Stop(0.3)
				currentRunwayTrack = nil
			end
		end
	end)
end

print("[Style Kingdom] CharacterAppearance initialized")
