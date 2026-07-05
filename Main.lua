--[[ WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk! ]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Переменная для контроля работы скрипта
local isRunning = false
local farmThread = nil

local function getCharacter()
    local character = player.Character or player.CharacterAdded:Wait()
    return character:WaitForChild("HumanoidRootPart")
end

local positions = {
    Vector3.new(-65.00, 82.06, 1111.16),
    Vector3.new(-62.09, 64.48, 1369.88),
    Vector3.new(-56.87, 45.03, 2141.06),
    Vector3.new(-52.26, 77.51, 2531.64),
    Vector3.new(-50.92, 62.58, 2915.75),
    Vector3.new(-52.11, 65.76, 3355.92),
    Vector3.new(-40.52, 63.17, 3670.37),
    Vector3.new(-46.34, 50.46, 4117.53),
    Vector3.new(-44.82, 64.54, 4444.41),
    Vector3.new(-51.01, 14.28, 5216.232),
    Vector3.new(-51.15, 20.33, 5990.34),
    Vector3.new(-48.15, 64.66, 6458.56),
    Vector3.new(-52.21, 77.99, 6751.03),
    Vector3.new(-51.79, 27.31, 7274.15),
    Vector3.new(-79.17, 29.59, 7526.87),
    Vector3.new(-55.33, 41.38, 8299.41),
    Vector3.new(-51.21, -315.98, 8821.36),
    Vector3.new(-55.84, -353.82, 9486.40)
}

local function createPlatform(position)
    local platform = Instance.new("Part")
    platform.Size = Vector3.new(6, 1, 6)
    platform.Anchored = true
    platform.CanCollide = true
    platform.Position = position - Vector3.new(0, 3, 0)
    platform.Transparency = 0.6
    platform.Name = "TempPlatform"
    platform.Parent = workspace
    return platform
end

-- Основная функция цикла
local function runFarm()
    while isRunning do
        local hrp = getCharacter()
        for _, pos in ipairs(positions) do
            if not isRunning then break end
            local platform = createPlatform(pos)
            hrp.CFrame = CFrame.new(pos)
            task.wait(0.2)
            if platform then platform:Destroy() end
        end
        if isRunning then
            task.wait(8)
        end
    end
end

-- Создание интерфейса (UI)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FarmGui"
screenGui.ResetOnSpawn = false

if syn and syn.protect_gui then
    syn.protect_gui(screenGui)
    screenGui.Parent = CoreGui
else
    screenGui.Parent = player:WaitForChild("PlayerGui")
end

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 160, 0, 50)
toggleButton.Position = UDim2.new(0.5, 0, 0.4, 0)
toggleButton.AnchorPoint = Vector2.new(0.5, 0.5)
toggleButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
toggleButton.Text = "Farm: OFF"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 20
toggleButton.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 10)
uiCorner.Parent = toggleButton

-- Логика переключения кнопки
toggleButton.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    
    if isRunning then
        toggleButton.Text = "Farm: ON"
        toggleButton.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
        farmThread = task.spawn(runFarm)
    else
        toggleButton.Text = "Farm: OFF"
        toggleButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        if farmThread then
            farmThread = nil
        end
        for _, part in ipairs(workspace:GetChildren()) do
            if part.Name == "TempPlatform" then
                part:Destroy()
            end
        end
    end
end)

-- СКРИПТ ДЛЯ ПЕРЕТАСКИВАНИЯ КНОПКИ (Drag Implementation)
local dragging, dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    toggleButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

toggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = toggleButton.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

toggleButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)
