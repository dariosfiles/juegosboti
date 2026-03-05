-- SERVICES
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

-- PLAYER SETUP
local player = Players.LocalPlayer

-- GUI SETUP
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GhostSystem_Final"
screenGui.ResetOnSpawn = false
local success, err = pcall(function() screenGui.Parent = CoreGui end)
if not success then screenGui.Parent = player:WaitForChild("PlayerGui") end

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 0, 0, 0)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 10, 20)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)
local uiStroke = Instance.new("UIStroke", mainFrame)
uiStroke.Thickness = 2
uiStroke.Color = Color3.fromRGB(130, 70, 210)
uiStroke.Transparency = 0.4

-- Top Bar
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 30)
topBar.BackgroundColor3 = Color3.fromRGB(25, 20, 35)
topBar.Parent = mainFrame
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 10)

local discordText = Instance.new("TextLabel")
discordText.Size = UDim2.new(1, -20, 1, 0)
discordText.Position = UDim2.new(0, 10, 0, 0)
discordText.BackgroundTransparency = 1
discordText.TextColor3 = Color3.fromRGB(180, 150, 255)
discordText.Text = "discord.gg/abSQfQ5c"
discordText.Font = Enum.Font.GothamBold
discordText.TextSize = 14
discordText.TextXAlignment = Enum.TextXAlignment.Left
discordText.Parent = topBar

--------------------------------------------------------------------
-- CONTAINERS
--------------------------------------------------------------------

-- 1. Loading Container
local loadContainer = Instance.new("Frame")
loadContainer.Size = UDim2.new(1, 0, 1, -30)
loadContainer.Position = UDim2.new(0, 0, 0, 30)
loadContainer.BackgroundTransparency = 1
loadContainer.Parent = mainFrame

local loadingText = Instance.new("TextLabel")
loadingText.Size = UDim2.new(1, 0, 1, 0)
loadingText.BackgroundTransparency = 1
loadingText.TextColor3 = Color3.fromRGB(255, 255, 255)
loadingText.Text = "Loading"
loadingText.Font = Enum.Font.GothamMedium
loadingText.TextSize = 22
loadingText.Parent = loadContainer

-- 2. Key System Container (Pop-in)
local keyContainer = Instance.new("Frame")
keyContainer.Size = UDim2.new(0, 0, 0, 0) 
keyContainer.Position = UDim2.new(0.5, 0, 0.5, 15)
keyContainer.AnchorPoint = Vector2.new(0.5, 0.5)
keyContainer.BackgroundTransparency = 1
keyContainer.Visible = false
keyContainer.Parent = mainFrame

local keyInput = Instance.new("TextBox")
keyInput.Size = UDim2.new(0, 240, 0, 40)
keyInput.Position = UDim2.new(0.5, 0, 0.35, 0)
keyInput.AnchorPoint = Vector2.new(0.5, 0.5)
keyInput.BackgroundColor3 = Color3.fromRGB(30, 25, 40)
keyInput.PlaceholderText = "Key"
keyInput.Text = ""
keyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
keyInput.Font = Enum.Font.Gotham
keyInput.TextSize = 14
keyInput.ClipsDescendants = true
keyInput.Parent = keyContainer
Instance.new("UICorner", keyInput)

local checkBtn = Instance.new("TextButton")
checkBtn.Size = UDim2.new(0, 160, 0, 40)
checkBtn.Position = UDim2.new(0.5, 0, 0.65, 0)
checkBtn.AnchorPoint = Vector2.new(0.5, 0.5)
checkBtn.BackgroundColor3 = Color3.fromRGB(100, 60, 180)
checkBtn.Text = "Check Key"
checkBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
checkBtn.Font = Enum.Font.GothamBold
checkBtn.TextSize = 14
checkBtn.Parent = keyContainer
Instance.new("UICorner", checkBtn)

local errorText = Instance.new("TextLabel")
errorText.Size = UDim2.new(1, 0, 0, 20)
errorText.Position = UDim2.new(0.5, 0, 0.9, 0)
errorText.AnchorPoint = Vector2.new(0.5, 0.5)
errorText.BackgroundTransparency = 1
errorText.TextColor3 = Color3.fromRGB(255, 80, 80)
errorText.Text = "Wrong key"
errorText.Font = Enum.Font.GothamMedium
errorText.TextSize = 14
errorText.Visible = false
errorText.Parent = keyContainer

-- 3. Patched Message (Scaled & Outlined)
local patchedText = Instance.new("TextLabel")
patchedText.Size = UDim2.new(0.85, 0, 0.5, 0) -- Scaled box size
patchedText.Position = UDim2.new(0.5, 0, 0.6, 0)
patchedText.AnchorPoint = Vector2.new(0.5, 0.5)
patchedText.BackgroundTransparency = 1
patchedText.TextColor3 = Color3.fromRGB(255, 50, 50)
patchedText.Text = "error, please join the discord and make sure the script is updated"
patchedText.Font = Enum.Font.FredokaOne
patchedText.TextScaled = true -- Full scaling enabled
patchedText.TextTransparency = 1
patchedText.Visible = false
patchedText.Parent = mainFrame

local textStroke = Instance.new("UIStroke", patchedText)
textStroke.Thickness = 2.5
textStroke.Color = Color3.fromRGB(0, 0, 0)
textStroke.Transparency = 1

--------------------------------------------------------------------
-- SMOOTH DRAGGING
--------------------------------------------------------------------
local function makeDraggable(frame)
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    RunService.RenderStepped:Connect(function()
        if dragging and dragInput then
            local delta = dragInput.Position - dragStart
            local targetPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            TweenService:Create(frame, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = targetPos}):Play()
        end
    end)
end
makeDraggable(mainFrame)

--------------------------------------------------------------------
-- LOGIC & ANIMATIONS
--------------------------------------------------------------------
local CORRECT_KEY = "querry-sFOlYpNCJT"

local function shakeUI()
    local originalPos = keyContainer.Position
    errorText.Visible = true
    for i = 1, 8 do
        keyContainer.Position = originalPos + UDim2.new(0, math.random(-6, 6), 0, 0)
        task.wait(0.02)
    end
    keyContainer.Position = originalPos
    task.wait(2)
    errorText.Visible = false
end

checkBtn.MouseButton1Click:Connect(function()
    if keyInput.Text == CORRECT_KEY then
        -- Animatedly shrink the key container
        local fadeOut = TweenService:Create(keyContainer, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0,0,0,0)})
        fadeOut:Play()
        fadeOut.Completed:Wait()
        keyContainer.Visible = false
        
        -- Reveal Scaled Patched Text
        patchedText.Visible = true
        TweenService:Create(patchedText, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
        TweenService:Create(textStroke, TweenInfo.new(0.6), {Transparency = 0}):Play()
    else
        shakeUI()
    end
end)

-- Initial Main Frame Pop In
TweenService:Create(mainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 320, 0, 180)}):Play()

-- Loading Sequence
task.spawn(function()
    local dots = ""
    while loadContainer.Visible do
        loadingText.Text = "Loading" .. dots
        dots = dots .. "."
        if #dots > 3 then dots = "" end
        task.wait(0.4)
    end
end)

task.delay(5, function()
    loadContainer.Visible = false
    keyContainer.Visible = true
    -- Pop-in animation for key container
    TweenService:Create(keyContainer, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 1, -30)}):Play()
end)
