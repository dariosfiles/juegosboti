
game:GetService("Lighting").ClockTime=13.5; game:GetService("Lighting").Brightness=0.95; game:GetService("Lighting").Ambient=Color3.fromRGB(145,150,165); game:GetService("Lighting").OutdoorAmbient=Color3.fromRGB(135,140,155); game:GetService("Lighting").FogEnd=99999; game:GetService("Lighting").GlobalShadows=false

if not game:IsLoaded() then game.Loaded:Wait() end

local Services = {
	Players = game:GetService("Players"),
	RunService = game:GetService("RunService"),
	UserInputService = game:GetService("UserInputService"),
	TweenService = game:GetService("TweenService"),
	Workspace = game:GetService("Workspace"),
	CoreGui = game:GetService("CoreGui"),
}

local Players = Services.Players
local RunService = Services.RunService
local UserInputService = Services.UserInputService
local TweenService = Services.TweenService
local Workspace = Services.Workspace
local CoreGui = Services.CoreGui

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ==================== SETTINGS ====================
local Settings = {
	CarpetSpeedEnabled = false,
	CarpetBoost = 2.5,
	ProtectVEnabled = false,
	KickOnStealEnabled = false,   -- New toggle
}

_G.InvisStealAngle      = 233
_G.SinkSliderValue      = 5
_G.AutoRecoverLagback   = true
_G.INVISIBLE_STEAL_KEY  = Enum.KeyCode.I   -- Fixed to I
_G.invisibleStealEnabled = false
_G.RecoveryInProgress   = false

-- ==================== KICK ON STEAL (Your Exact Logic) ====================
local kickConnections = {}

local function hasKeyword(text)
	if typeof(text) ~= "string" then return false end
	return string.find(string.lower(text), "you stole") ~= nil
end

local function kickPlayer()
	pcall(function()
		LocalPlayer:Kick("Femboy Hub INSTA LEAVE!\n\nYou stole a brainrot")
	end)
end

local function watchObject(obj)
	if not (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then
		return
	end
	if hasKeyword(obj.Text) then
		kickPlayer()
		return
	end
	local conn = obj:GetPropertyChangedSignal("Text"):Connect(function()
		if hasKeyword(obj.Text) then
			kickPlayer()
		end
	end)
	table.insert(kickConnections, conn)
end

local function scan(parent)
	for _, obj in ipairs(parent:GetDescendants()) do
		watchObject(obj)
	end
end

local function watchGui(gui)
	scan(gui)
	local conn = gui.DescendantAdded:Connect(function(desc)
		watchObject(desc)
	end)
	table.insert(kickConnections, conn)
end

local function startKickOnSteal()
	-- Clear old connections
	for _, c in ipairs(kickConnections) do
		pcall(function() c:Disconnect() end)
	end
	kickConnections = {}

	for _, gui in ipairs(PlayerGui:GetChildren()) do
		watchGui(gui)
	end

	table.insert(kickConnections,
		PlayerGui.ChildAdded:Connect(function(gui)
			watchGui(gui)
		end)
	)
end

local function stopKickOnSteal()
	for _, c in ipairs(kickConnections) do
		pcall(function() c:Disconnect() end)
	end
	kickConnections = {}
end

-- ==================== CORE STATES ====================
local animPlaying = false
local tracks = {}
local clone, oldRoot, hip, connection
local folderConnections = {}
local serverGhosts = {}
local ghostEnabled = true
local lagbackCallCount = 0
local lagbackWindowStart = 0
local lastLagbackTime = 0
local errorOrbActive = false
local errorOrb = nil

local antiDieConnection = nil
local carpetConnection = nil
local carpetGodConnection = nil

local invisGui, settingsGui

-- ==================== ANTI-DIE ====================
local function setupAntiDie()
	if antiDieConnection then antiDieConnection:Disconnect() end
	local character = LocalPlayer.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	antiDieConnection = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
		if not _G.invisibleStealEnabled then return end
		if humanoid.Health <= 0 then humanoid.Health = humanoid.MaxHealth end
	end)
end

local function disableAntiDie()
	if antiDieConnection then antiDieConnection:Disconnect() antiDieConnection = nil end
end

-- ==================== CARPET SPEED ====================
local function startCarpetSpeed()
	if carpetConnection then carpetConnection:Disconnect() end
	if carpetGodConnection then carpetGodConnection:Disconnect() end

	local character = LocalPlayer.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then return end

	carpetGodConnection = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
		if humanoid.Health <= 0 then humanoid.Health = humanoid.MaxHealth end
	end)

	carpetConnection = RunService.Heartbeat:Connect(function()
		if not Settings.CarpetSpeedEnabled then return end
		local tool = character:FindFirstChild("Flying Carpet")
		if tool and root then
			local boost = math.clamp(Settings.CarpetBoost, 1, 4)
			local vel = root.AssemblyLinearVelocity
			if vel.Magnitude > 2 then
				local boostVec = vel.Unit * (humanoid.WalkSpeed * (boost - 1)) * 0.016
				root.CFrame += boostVec
			end
		end
	end)
end

local function stopCarpetSpeed()
	if carpetConnection then carpetConnection:Disconnect() carpetConnection = nil end
	if carpetGodConnection then carpetGodConnection:Disconnect() carpetGodConnection = nil end
end

-- ==================== PROTECT V ====================
local function protectV()
	if not Settings.ProtectVEnabled then return end
	local character = LocalPlayer.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	if not backpack then return end

	local beehive = backpack:FindFirstChild("BeeHive")
	local sentry = backpack:FindFirstChild("All Seeing Sentry")

	task.spawn(function()
		if beehive then
			humanoid:EquipTool(beehive)
			task.wait(0.08)
			pcall(function() beehive:Activate() end)
			task.wait(0.15)
			humanoid:UnequipTools()
		end
		if sentry then
			humanoid:EquipTool(sentry)
			task.wait(0.08)
			pcall(function() sentry:Activate() end)
			task.wait(0.15)
			humanoid:UnequipTools()
		end
	end)
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.V and Settings.ProtectVEnabled then
		protectV()
	end
end)

-- ==================== DRAGGABLE ====================
local function MakeDraggable(handle, target)
	local dragging = false
	local dragInput
	local dragStart
	local startPos

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)

	handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

-- ==================== INVISIBLE STEAL CORE ====================
-- (Full core kept exactly as before - doClone, revertClone, etc.)

local function clearErrorOrb()
	if errorOrb and errorOrb.Parent then errorOrb:Destroy() end
	errorOrb = nil
	errorOrbActive = false
end

local function createErrorOrb()
	if errorOrbActive then return end
	errorOrbActive = true
	for _, ghost in pairs(serverGhosts) do if ghost and ghost.Parent then ghost:Destroy() end end
	serverGhosts = {}

	local sg = Instance.new("ScreenGui")
	sg.Name = "ErrorOrbGui"
	sg.ResetOnSpawn = false
	sg.Parent = PlayerGui

	local fr = Instance.new("Frame", sg)
	fr.Size = UDim2.new(0, 500, 0, 60)
	fr.Position = UDim2.new(0.5, -250, 0.3, 0)
	fr.BackgroundTransparency = 1

	local l1 = Instance.new("TextLabel", fr)
	l1.Size = UDim2.new(1, 0, 0.5, 0)
	l1.Text = "ERROR CAUSED BY PLAYER DEATH"
	l1.TextColor3 = Color3.fromRGB(255, 0, 0)
	l1.TextStrokeTransparency = 0
	l1.TextStrokeColor3 = Color3.new(0, 0, 0)
	l1.Font = Enum.Font.SourceSansBold
	l1.TextScaled = true

	local l2 = Instance.new("TextLabel", fr)
	l2.Size = UDim2.new(1, 0, 0.5, 0)
	l2.Position = UDim2.new(0, 0, 0.5, 0)
	l2.Text = "MUST RESET TO FIX ERROR"
	l2.TextColor3 = Color3.fromRGB(255, 0, 0)
	l2.TextStrokeTransparency = 0
	l2.TextStrokeColor3 = Color3.new(0, 0, 0)
	l2.Font = Enum.Font.SourceSansBold
	l2.TextScaled = true

	errorOrb = sg
end

local function createServerGhost(position)
	if not ghostEnabled or errorOrbActive then return end
	local now = tick()
	if now - lastLagbackTime < 0.05 then return end
	lastLagbackTime = now
	if now - lagbackWindowStart > 1 then lagbackCallCount = 0; lagbackWindowStart = now end
	lagbackCallCount += 1
	if lagbackCallCount >= 7 then createErrorOrb(); return end

	for _, g in pairs(serverGhosts) do if g and g.Parent then g:Destroy() end end
	serverGhosts = {}

	local sg = Instance.new("ScreenGui")
	sg.Name = "LagbackNotification"
	sg.ResetOnSpawn = false
	sg.Parent = PlayerGui

	local sl = Instance.new("TextLabel", sg)
	sl.Size = UDim2.new(0, 500, 0, 30)
	sl.Position = UDim2.new(0.5, -250, 0.15, 0)
	sl.BackgroundTransparency = 1
	sl.Text = "LAGBACK DETECTED"
	sl.TextColor3 = Color3.fromRGB(255, 0, 0)
	sl.TextStrokeTransparency = 0
	sl.TextStrokeColor3 = Color3.new(0, 0, 0)
	sl.Font = Enum.Font.SourceSansBold
	sl.TextScaled = true

	local sw = Instance.new("TextLabel", sg)
	sw.Size = UDim2.new(0, 650, 0, 25)
	sw.Position = UDim2.new(0.5, -325, 0.15, 32)
	sw.BackgroundTransparency = 1
	sw.Text = "DISABLE INVISIBLE STEAL NOW OR YOU WILL BE KILLED BY ANTICHEAT"
	sw.TextColor3 = Color3.fromRGB(200, 200, 200)
	sw.TextStrokeTransparency = 0
	sw.TextStrokeColor3 = Color3.new(0, 0, 0)
	sw.Font = Enum.Font.SourceSansBold
	sw.TextScaled = true

	task.delay(1.5, function() if sg and sg.Parent then sg:Destroy() end end)

	local ghost = Instance.new("Part")
	ghost.Name = "LagbackGhost"
	ghost.Shape = Enum.PartType.Ball
	ghost.Size = Vector3.new(3, 3, 3)
	ghost.Color = Color3.fromRGB(255, 0, 0)
	ghost.Material = Enum.Material.Glass
	ghost.Transparency = 0.3
	ghost.CanCollide = false
	ghost.Anchored = true
	ghost.CastShadow = false
	ghost.Position = position + Vector3.new(0, 5, 0)
	ghost.Parent = Workspace.CurrentCamera

	local bb = Instance.new("BillboardGui", ghost)
	bb.Size = UDim2.new(0, 400, 0, 60)
	bb.StudsOffset = Vector3.new(0, 4, 0)
	bb.AlwaysOnTop = true

	local bl = Instance.new("TextLabel", bb)
	bl.Size = UDim2.new(1, 0, 0, 25)
	bl.Text = "LAGBACK DETECTED"
	bl.TextColor3 = Color3.fromRGB(255, 0, 0)
	bl.TextStrokeTransparency = 0
	bl.TextStrokeColor3 = Color3.new(0, 0, 0)
	bl.Font = Enum.Font.SourceSansBold
	bl.TextScaled = true

	local bw = Instance.new("TextLabel", bb)
	bw.Size = UDim2.new(1, 0, 0, 25)
	bw.Position = UDim2.new(0, 0, 0, 25)
	bw.Text = "DISABLE INVISIBLE STEAL NOW OR YOU WILL BE KILLED BY ANTICHEAT"
	bw.TextColor3 = Color3.fromRGB(200, 200, 200)
	bw.TextStrokeTransparency = 0
	bw.TextStrokeColor3 = Color3.new(0, 0, 0)
	bw.Font = Enum.Font.SourceSansBold
	bw.TextScaled = true

	table.insert(serverGhosts, ghost)
end

local function clearAllGhosts()
	for _, ghost in pairs(serverGhosts) do pcall(function() if ghost and ghost.Parent then ghost:Destroy() end end) end
	serverGhosts = {}
	clearErrorOrb()
	lagbackCallCount = 0
	lastLagbackTime = 0
end

local function removeFolders()
	local pf = Workspace:FindFirstChild(LocalPlayer.Name)
	if not pf then return end

	local dr = pf:FindFirstChild("DoubleRig")
	if dr then
		local rr = dr:FindFirstChild("HumanoidRootPart") or dr:FindFirstChildWhichIsA("BasePart")
		if rr and ghostEnabled then createServerGhost(rr.Position) end
		dr:Destroy()
	end

	local cs = pf:FindFirstChild("Constraints")
	if cs then cs:Destroy() end

	local conn = pf.ChildAdded:Connect(function(child)
		if child.Name == "DoubleRig" then
			task.defer(function()
				local rr = child:FindFirstChild("HumanoidRootPart") or child:FindFirstChildWhichIsA("BasePart")
				if rr and ghostEnabled then createServerGhost(rr.Position) end
				child:Destroy()
			end)
		elseif child.Name == "Constraints" then
			child:Destroy()
		end
	end)
	table.insert(folderConnections, conn)
end

local function doClone()
	local character = LocalPlayer.Character
	if not (character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0) then return false end

	hip = character.Humanoid.HipHeight
	oldRoot = character:FindFirstChild("HumanoidRootPart")
	if not oldRoot or not oldRoot.Parent then return false end

	for _, c in pairs(oldRoot:GetChildren()) do
		if (c:IsA("Attachment") and (c.Name:find("Beam") or c.Name:find("Attach"))) or c:IsA("Beam") then c:Destroy() end
	end

	local tmp = Instance.new("Model")
	tmp.Parent = game
	character.Parent = tmp
	clone = oldRoot:Clone()
	clone.Parent = character
	oldRoot.Parent = Workspace.CurrentCamera
	clone.CFrame = oldRoot.CFrame
	character.PrimaryPart = clone
	character.Parent = Workspace

	for _, v in pairs(character:GetDescendants()) do
		if v:IsA("Weld") or v:IsA("Motor6D") then
			if v.Part0 == oldRoot then v.Part0 = clone end
			if v.Part1 == oldRoot then v.Part1 = clone end
		end
	end
	tmp:Destroy()
	return true
end

local function revertClone()
	local character = LocalPlayer.Character
	if not oldRoot or not oldRoot:IsDescendantOf(Workspace) or not character or (character:FindFirstChild("Humanoid") and character.Humanoid.Health <= 0) then return end

	local tmp = Instance.new("Model")
	tmp.Parent = game
	character.Parent = tmp
	oldRoot.Parent = character
	character.PrimaryPart = oldRoot
	character.Parent = Workspace
	oldRoot.CanCollide = true

	for _, v in pairs(character:GetDescendants()) do
		if v:IsA("Weld") or v:IsA("Motor6D") then
			if v.Part0 == clone then v.Part0 = oldRoot end
			if v.Part1 == clone then v.Part1 = oldRoot end
		end
	end

	if clone then
		local p = clone.CFrame
		clone:Destroy()
		clone = nil
		oldRoot.CFrame = p
	end
	oldRoot = nil
	if character:FindFirstChild("Humanoid") then character.Humanoid.HipHeight = hip end

	clearAllGhosts()
end

local function animationTrickery()
	local character = LocalPlayer.Character
	if not (character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0) then return end

	local anim = Instance.new("Animation")
	anim.AnimationId = "http://www.roblox.com/asset/?id=18537363391"
	local humanoid = character.Humanoid
	local animator = humanoid:FindFirstChild("Animator") or Instance.new("Animator", humanoid)
	local animTrack = animator:LoadAnimation(anim)
	animTrack.Priority = Enum.AnimationPriority.Action4
	animTrack:Play(0, 1, 0)
	anim:Destroy()

	table.insert(tracks, animTrack)
	animTrack.Stopped:Connect(function() if animPlaying then animationTrickery() end end)

	task.delay(0, function()
		animTrack.TimePosition = 0.7
		task.delay(0.3, function() if animTrack then animTrack:AdjustSpeed(math.huge) end end)
	end)
end

local function turnOff()
	clearAllGhosts()
	disableAntiDie()
	stopCarpetSpeed()

	if not animPlaying then return end

	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	animPlaying = false
	_G.invisibleStealEnabled = false

	for _, t in pairs(tracks) do pcall(function() t:Stop() end) end
	tracks = {}

	if connection then connection:Disconnect() connection = nil end
	for _, c in ipairs(folderConnections) do if c then c:Disconnect() end end
	folderConnections = {}

	revertClone()
	if humanoid then pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end) end
end

local function turnOn()
	if animPlaying then return end
	local character = LocalPlayer.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	animPlaying = true
	_G.invisibleStealEnabled = true
	tracks = {}

	setupAntiDie()
	removeFolders()

	local success = doClone()
	if success then
		task.wait(0.05)
		animationTrickery()

		local lastSetPosition = nil
		local skipFrames = 5

		connection = RunService.PreSimulation:Connect(function()
			if not (character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 and oldRoot) then return end

			local root = character.PrimaryPart or character:FindFirstChild("HumanoidRootPart")
			if not root then return end

			if skipFrames > 0 then
				skipFrames -= 1
				lastSetPosition = nil
			elseif lastSetPosition and ghostEnabled then
				local currentPos = oldRoot.Position
				local jumpDist = (currentPos - lastSetPosition).Magnitude
				if jumpDist > 3 and not _G.RecoveryInProgress then
					lastSetPosition = nil
					createServerGhost(currentPos)

					if _G.AutoRecoverLagback and _G.toggleInvisibleSteal then
						_G.RecoveryInProgress = true
						task.spawn(function()
							pcall(_G.toggleInvisibleSteal)
							task.wait(0.5)
							pcall(_G.toggleInvisibleSteal)
							_G.RecoveryInProgress = false
						end)
					end
				end
			end

			if clone then clone.CanCollide = false end
			for _, c in pairs(oldRoot:GetChildren()) do
				if c:IsA("Attachment") or c:IsA("Beam") then c:Destroy() end
			end

			local rotAngle = _G.InvisStealAngle or 180
			local sa = (_G.SinkSliderValue or 5) * 0.5
			local cf = root.CFrame - Vector3.new(0, sa, 0)
			oldRoot.CFrame = cf * CFrame.Angles(math.rad(rotAngle), 0, 0)
			oldRoot.AssemblyLinearVelocity = root.AssemblyLinearVelocity
			oldRoot.CanCollide = false

			lastSetPosition = oldRoot.Position
		end)
	end
end

_G.toggleInvisibleSteal = function()
	if animPlaying then turnOff() else turnOn() end
end

-- ==================== FEMBOY INVIS GUI (Green) ====================
invisGui = Instance.new("ScreenGui")
invisGui.Name = "FemboyInvisPanel"
invisGui.ResetOnSpawn = false
invisGui.Parent = PlayerGui
invisGui.Enabled = true

local iFrame = Instance.new("Frame", invisGui)
iFrame.Size = UDim2.new(0, 260, 0, 340)
iFrame.Position = UDim2.new(0.85, 0, 0.12, 0)
iFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Instance.new("UICorner", iFrame).CornerRadius = UDim.new(0, 8)

local retroStroke = Instance.new("UIStroke", iFrame)
retroStroke.Color = Color3.fromRGB(0, 255, 100)
retroStroke.Thickness = 3
retroStroke.Transparency = 0.2

local scanline = Instance.new("Frame", iFrame)
scanline.Size = UDim2.new(1, 0, 0, 2)
scanline.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
scanline.BackgroundTransparency = 0.85
local scanTween = TweenService:Create(scanline, TweenInfo.new(1.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true), {Position = UDim2.new(0, 0, 1, 0)})
scanTween:Play()

local iHeader = Instance.new("Frame", iFrame)
iHeader.Size = UDim2.new(1, 0, 0, 40)
iHeader.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
Instance.new("UICorner", iHeader).CornerRadius = UDim.new(0, 8)
MakeDraggable(iHeader, iFrame)

local iTitle = Instance.new("TextLabel", iHeader)
iTitle.Size = UDim2.new(1, -20, 1, 0)
iTitle.Position = UDim2.new(0, 12, 0, 0)
iTitle.BackgroundTransparency = 1
iTitle.Text = "FEMBOY INVIS"
iTitle.Font = Enum.Font.Arcade
iTitle.TextSize = 18
iTitle.TextColor3 = Color3.fromRGB(0, 255, 100)
iTitle.TextStrokeTransparency = 0
iTitle.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
iTitle.TextXAlignment = Enum.TextXAlignment.Left

local iContainer = Instance.new("Frame", iFrame)
iContainer.Size = UDim2.new(1, -20, 1, -55)
iContainer.Position = UDim2.new(0, 10, 0, 45)
iContainer.BackgroundTransparency = 1
local iLayout = Instance.new("UIListLayout", iContainer)
iLayout.Padding = UDim.new(0, 10)
iLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function CreateIRow(height)
	local r = Instance.new("Frame", iContainer)
	r.Size = UDim2.new(1, 0, 0, height or 32)
	r.BackgroundTransparency = 1
	return r
end

local row1 = CreateIRow(32)
local lbl1 = Instance.new("TextLabel", row1)
lbl1.Size = UDim2.new(0.55, 0, 1, 0)
lbl1.BackgroundTransparency = 1
lbl1.Text = "TOGGLE INVIS"
lbl1.TextColor3 = Color3.fromRGB(200, 255, 200)
lbl1.Font = Enum.Font.Arcade
lbl1.TextSize = 13
lbl1.TextXAlignment = Enum.TextXAlignment.Left

local btnInvis = Instance.new("TextButton", row1)
btnInvis.Size = UDim2.new(0, 55, 0, 26)
btnInvis.Position = UDim2.new(1, -60, 0.5, -13)
btnInvis.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
btnInvis.Text = "OFF"
btnInvis.Font = Enum.Font.Arcade
btnInvis.TextSize = 12
btnInvis.TextColor3 = Color3.fromRGB(255, 80, 80)
Instance.new("UICorner", btnInvis).CornerRadius = UDim.new(0, 6)

local keyLabel = Instance.new("TextLabel", row1)
keyLabel.Size = UDim2.new(0, 45, 0, 26)
keyLabel.Position = UDim2.new(1, -115, 0.5, -13)
keyLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
keyLabel.Text = "I"
keyLabel.Font = Enum.Font.Arcade
keyLabel.TextColor3 = Color3.fromRGB(0, 255, 200)
keyLabel.TextSize = 12
Instance.new("UICorner", keyLabel).CornerRadius = UDim.new(0, 6)

local row2 = CreateIRow(32)
local lbl2 = Instance.new("TextLabel", row2)
lbl2.Size = UDim2.new(0.6, 0, 1, 0)
lbl2.BackgroundTransparency = 1
lbl2.Text = "AUTO FIX LAGBACK"
lbl2.TextColor3 = Color3.fromRGB(200, 255, 200)
lbl2.Font = Enum.Font.Arcade
lbl2.TextSize = 13
lbl2.TextXAlignment = Enum.TextXAlignment.Left

local btnFix = Instance.new("TextButton", row2)
btnFix.Size = UDim2.new(0, 55, 0, 26)
btnFix.Position = UDim2.new(1, -55, 0.5, -13)
btnFix.BackgroundColor3 = _G.AutoRecoverLagback and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(40, 40, 45)
btnFix.Text = _G.AutoRecoverLagback and "ON" or "OFF"
btnFix.Font = Enum.Font.Arcade
btnFix.TextSize = 12
btnFix.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", btnFix).CornerRadius = UDim.new(0, 6)

btnFix.MouseButton1Click:Connect(function()
	_G.AutoRecoverLagback = not _G.AutoRecoverLagback
	btnFix.Text = _G.AutoRecoverLagback and "ON" or "OFF"
	btnFix.BackgroundColor3 = _G.AutoRecoverLagback and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(40, 40, 45)
end)

local function CreateRetroSlider(parent, name, min, max, default, callback)
	local frame = Instance.new("Frame", parent)
	frame.Size = UDim2.new(1, 0, 0, 48)
	frame.BackgroundTransparency = 1

	local label = Instance.new("TextLabel", frame)
	label.Size = UDim2.new(1, 0, 0, 18)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(180, 255, 180)
	label.Font = Enum.Font.Arcade
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = name .. ": " .. default

	local slideBg = Instance.new("Frame", frame)
	slideBg.Size = UDim2.new(1, 0, 0, 8)
	slideBg.Position = UDim2.new(0, 0, 0, 25)
	slideBg.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	Instance.new("UICorner", slideBg).CornerRadius = UDim.new(1, 0)

	local fill = Instance.new("Frame", slideBg)
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
	fill.ZIndex = 12
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

	local knob = Instance.new("Frame", slideBg)
	knob.Size = UDim2.new(0, 14, 0, 14)
	knob.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.new(0, 0, 0.5, 0)
	knob.ZIndex = 13
	Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

	local function update(inputX)
		local p = math.clamp((inputX - slideBg.AbsolutePosition.X) / slideBg.AbsoluteSize.X, 0, 1)
		local val = min + (p * (max - min))
		if max > 100 then val = math.floor(val) else val = math.floor(val * 10) / 10 end
		fill.Size = UDim2.new(p, 0, 1, 0)
		knob.Position = UDim2.new(p, 0, 0.5, 0)
		label.Text = name .. ": " .. val
		callback(val)
	end

	local dragging = false
	slideBg.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			update(input.Position.X)
		end
	end)
	knob.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			update(input.Position.X)
		end
	end)

	local p = (default - min) / (max - min)
	fill.Size = UDim2.new(p, 0, 1, 0)
	knob.Position = UDim2.new(p, 0, 0.5, 0)
end

CreateRetroSlider(iContainer, "ROTATION", 180, 360, _G.InvisStealAngle, function(v)
	_G.InvisStealAngle = v
end)

CreateRetroSlider(iContainer, "DEPTH", 0.5, 10, _G.SinkSliderValue, function(v)
	_G.SinkSliderValue = v
end)

local function updateVisualState(on)
	btnInvis.Text = on and "ON" or "OFF"
	btnInvis.TextColor3 = on and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 80, 80)
	btnInvis.BackgroundColor3 = on and Color3.fromRGB(25, 60, 25) or Color3.fromRGB(40, 40, 45)
end

btnInvis.MouseButton1Click:Connect(function()
	pcall(_G.toggleInvisibleSteal)
	updateVisualState(_G.invisibleStealEnabled)
end)

UserInputService.InputBegan:Connect(function(input)
	if UserInputService:GetFocusedTextBox() then return end
	if input.KeyCode == _G.INVISIBLE_STEAL_KEY then
		pcall(_G.toggleInvisibleSteal)
		updateVisualState(_G.invisibleStealEnabled)
	end
end)

-- ==================== FEMBOY SETTINGS GUI (Yellow) ====================
settingsGui = Instance.new("ScreenGui")
settingsGui.Name = "FemboySettingsPanel"
settingsGui.ResetOnSpawn = false
settingsGui.Parent = PlayerGui
settingsGui.Enabled = true

local sFrame = Instance.new("Frame", settingsGui)
sFrame.Size = UDim2.new(0, 260, 0, 420)
sFrame.Position = UDim2.new(0.72, 0, 0.12, 0)
sFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 15)
Instance.new("UICorner", sFrame).CornerRadius = UDim.new(0, 8)

local sStroke = Instance.new("UIStroke", sFrame)
sStroke.Color = Color3.fromRGB(255, 220, 0)
sStroke.Thickness = 3
sStroke.Transparency = 0.2

local sScanline = Instance.new("Frame", sFrame)
sScanline.Size = UDim2.new(1, 0, 0, 2)
sScanline.BackgroundColor3 = Color3.fromRGB(255, 255, 200)
sScanline.BackgroundTransparency = 0.8
local sScanTween = TweenService:Create(sScanline, TweenInfo.new(1.8, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true), {Position = UDim2.new(0, 0, 1, 0)})
sScanTween:Play()

local sHeader = Instance.new("Frame", sFrame)
sHeader.Size = UDim2.new(1, 0, 0, 40)
sHeader.BackgroundColor3 = Color3.fromRGB(15, 15, 8)
Instance.new("UICorner", sHeader).CornerRadius = UDim.new(0, 8)
MakeDraggable(sHeader, sFrame)

local sTitle = Instance.new("TextLabel", sHeader)
sTitle.Size = UDim2.new(1, -20, 1, 0)
sTitle.Position = UDim2.new(0, 12, 0, 0)
sTitle.BackgroundTransparency = 1
sTitle.Text = "FEMBOY SETTINGS"
sTitle.Font = Enum.Font.Arcade
sTitle.TextSize = 18
sTitle.TextColor3 = Color3.fromRGB(255, 220, 0)
sTitle.TextStrokeTransparency = 0
sTitle.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
sTitle.TextXAlignment = Enum.TextXAlignment.Left

local sContainer = Instance.new("Frame", sFrame)
sContainer.Size = UDim2.new(1, -20, 1, -55)
sContainer.Position = UDim2.new(0, 10, 0, 45)
sContainer.BackgroundTransparency = 1
local sLayout = Instance.new("UIListLayout", sContainer)
sLayout.Padding = UDim.new(0, 10)
sLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function CreateToggle(name, default, callback)
	local row = Instance.new("Frame", sContainer)
	row.Size = UDim2.new(1, 0, 0, 34)
	row.BackgroundTransparency = 1

	local lbl = Instance.new("TextLabel", row)
	lbl.Size = UDim2.new(0.65, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = name
	lbl.TextColor3 = Color3.fromRGB(255, 240, 180)
	lbl.Font = Enum.Font.Arcade
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left

	local btn = Instance.new("TextButton", row)
	btn.Size = UDim2.new(0, 55, 0, 26)
	btn.Position = UDim2.new(1, -60, 0.5, -13)
	btn.BackgroundColor3 = default and Color3.fromRGB(80, 60, 0) or Color3.fromRGB(40, 40, 30)
	btn.Text = default and "ON" or "OFF"
	btn.Font = Enum.Font.Arcade
	btn.TextSize = 12
	btn.TextColor3 = default and Color3.fromRGB(255, 255, 100) or Color3.fromRGB(200, 200, 180)
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

	btn.MouseButton1Click:Connect(function()
		default = not default
		btn.Text = default and "ON" or "OFF"
		btn.BackgroundColor3 = default and Color3.fromRGB(80, 60, 0) or Color3.fromRGB(40, 40, 30)
		btn.TextColor3 = default and Color3.fromRGB(255, 255, 100) or Color3.fromRGB(200, 200, 180)
		callback(default)
	end)
end

CreateToggle("Carpet Speed", Settings.CarpetSpeedEnabled, function(state)
	Settings.CarpetSpeedEnabled = state
	if state then startCarpetSpeed() else stopCarpetSpeed() end
end)

CreateToggle("Protect [V]", Settings.ProtectVEnabled, function(state)
	Settings.ProtectVEnabled = state
end)

-- Kick on Steal Toggle (using your exact logic)
CreateToggle("Kick on Steal", Settings.KickOnStealEnabled, function(state)
	Settings.KickOnStealEnabled = state
	if state then
		startKickOnSteal()
	else
		stopKickOnSteal()
	end
end)

-- LEAVE Button
local leaveBtn = Instance.new("TextButton", sContainer)
leaveBtn.Size = UDim2.new(1, 0, 0, 38)
leaveBtn.BackgroundColor3 = Color3.fromRGB(255, 220, 0)
leaveBtn.Text = "LEAVE"
leaveBtn.Font = Enum.Font.Arcade
leaveBtn.TextSize = 16
leaveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", leaveBtn).CornerRadius = UDim.new(0, 8)
leaveBtn.MouseButton1Click:Connect(function()
	LocalPlayer:Kick("You kicked yourself")
end)

-- USE GIANT POTION Button
local giantBtn = Instance.new("TextButton", sContainer)
giantBtn.Size = UDim2.new(1, 0, 0, 38)
giantBtn.BackgroundColor3 = Color3.fromRGB(255, 220, 0)
giantBtn.Text = "USE GIANT POTION"
giantBtn.Font = Enum.Font.Arcade
giantBtn.TextSize = 15
giantBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", giantBtn).CornerRadius = UDim.new(0, 8)
giantBtn.MouseButton1Click:Connect(function()
	local character = LocalPlayer.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	if not backpack then return end

	local potion = backpack:FindFirstChild("Giant Potion")
	if not potion then return end

	humanoid:EquipTool(potion)
	task.wait(0.1)
	pcall(function() potion:Activate() end)
	task.wait(0.4)
	humanoid:UnequipTools()
end)

-- ==================== "O" BUTTON ====================
local controlGui = Instance.new("ScreenGui")
controlGui.Name = "FemboyControlGui"
controlGui.ResetOnSpawn = false
controlGui.Parent = PlayerGui

local oButton = Instance.new("TextButton", controlGui)
oButton.Size = UDim2.new(0, 42, 0, 42)
oButton.Position = UDim2.new(0.5, 135, 0, 18)
oButton.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
oButton.Text = "O"
oButton.Font = Enum.Font.Arcade
oButton.TextSize = 24
oButton.TextColor3 = Color3.fromRGB(255, 220, 0)
Instance.new("UICorner", oButton).CornerRadius = UDim.new(1, 0)
local oStroke = Instance.new("UIStroke", oButton)
oStroke.Color = Color3.fromRGB(255, 220, 0)
oStroke.Thickness = 3

local guisVisible = true

oButton.MouseButton1Click:Connect(function()
	guisVisible = not guisVisible
	if invisGui then invisGui.Enabled = guisVisible end
	if settingsGui then settingsGui.Enabled = guisVisible end
end)

-- ==================== FEMBOY HUB WAVY TITLE ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FemboyWavePremium"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 240, 0, 65)
MainFrame.Position = UDim2.new(0.5, -120, 0, 20)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local UIStroke = Instance.new("UIStroke")
UIStroke.Thickness = 2
UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke.Parent = MainFrame

task.spawn(function()
	local hue = 0
	while true do
		hue = hue + 0.01
		if hue > 1 then hue = 0 end
		UIStroke.Color = Color3.fromHSV(hue, 0.7, 1)
		task.wait(0.03)
	end
end)

local TitleContainer = Instance.new("Frame")
TitleContainer.Size = UDim2.new(1, 0, 0.6, 0)
TitleContainer.Position = UDim2.new(0, 0, 0.05, 0)
TitleContainer.BackgroundTransparency = 1
TitleContainer.Parent = MainFrame

local titleText = "FEMBOY HUB"
local letters = {}
local charCount = #titleText
for i = 1, charCount do
	local letter = string.sub(titleText, i, i)
	local label = Instance.new("TextLabel")
	label.Text = letter
	label.Size = UDim2.new(1/charCount, 0, 1, 0)
	label.Position = UDim2.new((i-1)/charCount, 0, 0, 0)
	label.TextColor3 = Color3.fromRGB(255, 100, 180)
	label.Font = Enum.Font.LuckiestGuy
	label.TextSize = 26
	label.BackgroundTransparency = 1
	label.Parent = TitleContainer
	table.insert(letters, label)
end

RunService.RenderStepped:Connect(function()
	local t = tick()
	for i, label in ipairs(letters) do
		local yOffset = math.sin(t * 4 + (i * 0.5)) * 6
		label.Position = UDim2.new((i-1)/charCount, 0, 0, yOffset)
	end
end)

local Subtitle = Instance.new("TextLabel")
Subtitle.Text = "femboy stealing hub"
Subtitle.Size = UDim2.new(1, 0, 0.4, 0)
Subtitle.Position = UDim2.new(0, 0, 0.6, 0)
Subtitle.TextColor3 = Color3.fromRGB(255, 255, 255)
Subtitle.Font = Enum.Font.SourceSansBold
Subtitle.TextSize = 14
Subtitle.BackgroundTransparency = 1
Subtitle.Parent = MainFrame

-- ==================== INSTANT PROMPTS ====================
_G.InstantEnabled = true
local MAX_DISTANCE = 15
local trackedPrompts = {}
local activePrompts = {}

local function getRoot()
	local char = LocalPlayer.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function isTargetPrompt(prompt)
	if not prompt:IsA("ProximityPrompt") then return false end
	local text = (prompt.ActionText .. prompt.ObjectText):lower()
	return string.find(text, "steal") or string.find(text, "purchase") or string.find(text, "grab")
end

local function applyModifications(prompt)
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 20
	prompt.RequiresLineOfSight = false
end

local function hookPrompt(prompt)
	if not prompt:IsA("ProximityPrompt") then return end
	if isTargetPrompt(prompt) then
		applyModifications(prompt)
	end
	prompt:GetPropertyChangedSignal("Enabled"):Connect(function()
		if _G.InstantEnabled and isTargetPrompt(prompt) and not prompt.Enabled then
			task.wait(0.05)
			if prompt and prompt.Parent then prompt.Enabled = true end
		end
	end)
	trackedPrompts[prompt] = true
end

for _, obj in ipairs(Workspace:GetDescendants()) do hookPrompt(obj) end
Workspace.DescendantAdded:Connect(hookPrompt)

task.spawn(function()
	while true do
		task.wait(0.01)
		local root = getRoot()
		if _G.InstantEnabled and root then
			for prompt in pairs(trackedPrompts) do
				if prompt and prompt.Parent and isTargetPrompt(prompt) then
					applyModifications(prompt)
					local part = prompt.Parent:IsA("BasePart") and prompt.Parent or prompt.Parent:FindFirstChildWhichIsA("BasePart")
					if part and (part.Position - root.Position).Magnitude <= MAX_DISTANCE then
						if not activePrompts[prompt] then
							activePrompts[prompt] = true
							prompt:InputHoldBegin()
							task.delay(0.02, function()
								if prompt and prompt.Parent then
									prompt:InputHoldEnd()
									activePrompts[prompt] = nil
								end
							end)
						end
					end
				else
					trackedPrompts[prompt] = nil
				end
			end
		end
	end
end)

-- ==================== CHARACTER LIFECYCLE ====================
LocalPlayer.CharacterAdded:Connect(function()
	clearAllGhosts()
	disableAntiDie()
	stopCarpetSpeed()
	animPlaying = false
	_G.invisibleStealEnabled = false
end)

print("FEMBOY HUB Loaded")

-- Start kick monitoring if toggle is on by default (it's off)
if Settings.KickOnStealEnabled then
	startKickOnSteal()
end
