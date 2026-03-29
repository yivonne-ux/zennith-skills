--!strict
-- Style Kingdom — CameraController
-- Handles camera modes: default, boutique, runway (cinematic follow)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local camera = Workspace.CurrentCamera

local events = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Events")

local CameraController = {}

-- ============================================================
-- CAMERA MODES
-- ============================================================
local currentMode: string = "DEFAULT"

function CameraController.setDefault()
	currentMode = "DEFAULT"
	camera.CameraType = Enum.CameraType.Custom
end

function CameraController.setBoutiqueView(targetPosition: Vector3)
	currentMode = "BOUTIQUE"
	camera.CameraType = Enum.CameraType.Scriptable

	local cameraPos = targetPosition + Vector3.new(15, 12, 15)
	local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local goal = { CFrame = CFrame.lookAt(cameraPos, targetPosition) }
	local tween = TweenService:Create(camera, tweenInfo, goal)
	tween:Play()
end

function CameraController.startRunwayCamera(walkerCharacter: Model)
	currentMode = "RUNWAY"
	camera.CameraType = Enum.CameraType.Scriptable

	local rootPart = walkerCharacter:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	-- Camera follows walker from a slight angle
	local connection: RBXScriptConnection? = nil
	connection = RunService.RenderStepped:Connect(function()
		if currentMode ~= "RUNWAY" then
			if connection then
				connection:Disconnect()
			end
			return
		end

		local root = rootPart :: BasePart
		local walkerPos = root.Position
		-- Camera slightly to the side and ahead of the walker
		local lookDir = root.CFrame.LookVector
		local sideOffset = root.CFrame.RightVector * 6
		local cameraPos = walkerPos + sideOffset + Vector3.new(0, 3, 0) - lookDir * 3

		camera.CFrame = CFrame.lookAt(cameraPos, walkerPos + Vector3.new(0, 2, 0))
	end)
end

function CameraController.stopRunwayCamera()
	CameraController.setDefault()
end

-- ============================================================
-- RUNWAY EVENT HANDLER
-- ============================================================
events:WaitForChild("ContestRunwayStart").OnClientEvent:Connect(function(walkerUserId: number)
	local walker = Players:GetPlayerByUserId(walkerUserId)
	if walker and walker.Character then
		CameraController.startRunwayCamera(walker.Character)

		-- Return to default after the walk duration
		task.delay(15, function()
			if currentMode == "RUNWAY" then
				CameraController.stopRunwayCamera()
			end
		end)
	end
end)

-- Return to default camera when contest ends
events:WaitForChild("ContestStateChanged").OnClientEvent:Connect(function(newState: string)
	if newState == "RESULTS" or newState == "IDLE" then
		if currentMode == "RUNWAY" then
			CameraController.stopRunwayCamera()
		end
	end
end)

print("[Style Kingdom] CameraController initialized")
