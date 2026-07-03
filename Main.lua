--===================================================================================--
--                BUILD A BOAT FOR TREASURE: SUPREME ENGINE v10 (NEON GLASS)         --
--===================================================================================--

if not game:IsLoaded() then game.Loaded:Wait() end

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local DefaultWorldGravity = workspace.Gravity

-- [ГЛОБАЛЬНАЯ СТРУКТУРА НАСТРОЕК И ТЕЛЕМЕТРИИ]
local SupremeEngine = {
    Running = false,
    CurrentTween = nil,
    Speed = 375, -- Твоя дефолтная скорость
    
    -- Модули автоматизации
    AntiRagdoll = true,
    NoClip = true,
    VelocitySpoof = true,
    
    -- Статистика сессии
    Stats = {
        Runs = 0,
        GoldEarned = 0,
        StartTime = os.time(),
    }
}

-- Твои оригинальные точки полета
local destinations = {
    CFrame.new(-43.6134491, 62.1137619, 672.744934, -0.999842644, -0.00183729955, 0.017645346, 0, 0.994622767, 0.103564225, -0.0177407414, 0.103547923, -0.994466245),
    CFrame.new(-60.1504707, 97.4659729, 8767.91406, -0.99889338, 0.000705028593, 0.0470264405, 0, 0.999887645, -0.0149902813, -0.047031723, -0.0149736926, -0.998781145),
    CFrame.new(-54.331871, -345.398346, 9488.60645, -0.98221302, 0, 0.187770084, 0, 1, 0, -0.187770084, 0, -0.98221302),
}

-- Изоляция старых версий интерфейса
local safePlayerGui = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 3)
local oldUI = CoreGui:FindFirstChild("NeonUI") or (safePlayerGui and safePlayerGui:FindFirstChild("NeonUI"))
if oldUI then pcall(function() oldUI:Destroy() end) end

--===================================================================================--
--// NEON GLASS UI FRAMEWORK
--===================================================================================--

local NeonUI = {}

NeonUI.Theme = {
    Background = Color3.fromRGB(12, 14, 20),
    Panel = Color3.fromRGB(18, 22, 32),
    Stroke = Color3.fromRGB(60, 90, 160),
    Accent = Color3.fromRGB(80, 140, 255),
    Text = Color3.fromRGB(235, 240, 255),
}

function NeonUI:Create(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props) do
        inst[k] = v
    end
    return inst
end

function NeonUI:Corner(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = obj
    return c
end

function NeonUI:Stroke(obj, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness or 1
    s.Parent = obj
    return s
end

function NeonUI:CreateWindow(title)
    local gui = self:Create("ScreenGui", {
        Name = "NeonUI",
        ResetOnSpawn = false,
        Parent = safePlayerGui or CoreGui
    })

    -- Главное окно (добавлена прозрачность 0.2)
    local main = self:Create("Frame", {
        Size = UDim2.fromOffset(520, 360),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = self.Theme.Panel,
        BackgroundTransparency = 0.2, 
        Parent = gui
    })

    self:Corner(main, 14)
    self:Stroke(main, self.Theme.Stroke, 1.5)

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(40,60,120)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10,10,20))
    }
    grad.Rotation = 45
    grad.Parent = main

    local top = self:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundTransparency = 1,
        Parent = main
    })

    local titleLbl = self:Create("TextLabel", {
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.fromOffset(14, 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = top
    })

    local closeBtn = self:Create("TextButton", {
        Size = UDim2.fromOffset(24, 24),
        Position = UDim2.new(1, -32, 0, 7),
        BackgroundColor3 = Color3.fromRGB(150, 40, 40),
        Text = "✕",
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        Parent = main
    })
    self:Corner(closeBtn, 6)
    closeBtn.MouseButton1Click:Connect(function()
        SupremeEngine.Running = false
        if SupremeEngine.CurrentTween then SupremeEngine.CurrentTween:Cancel() end
        workspace.Gravity = DefaultWorldGravity
        gui:Destroy()
    end)

    -- drag logic
    local dragging, dragStart, startPos
    top.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    -- Боковая панель (прозрачность увеличена до 0.5)
    local tabHolder = self:Create("Frame", {
        Size = UDim2.new(0, 140, 1, -52),
        Position = UDim2.fromOffset(12, 44),
        BackgroundTransparency = 0.5,
        BackgroundColor3 = Color3.fromRGB(10,12,18),
        Parent = main
    })
    self:Corner(tabHolder, 10)
    self:Stroke(tabHolder, Color3.fromRGB(35, 45, 70), 1)

    local tabList = Instance.new("UIListLayout")
    tabList.Padding = UDim.new(0, 6)
    tabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabList.Parent = tabHolder
    
    Instance.new("UIPadding", tabHolder).PaddingTop = UDim.new(0, 6)

    local pagesContainer = self:Create("Frame", {
        Size = UDim2.new(1, -174, 1, -52),
        Position = UDim2.fromOffset(162, 44),
        BackgroundTransparency = 1,
        Parent = main
    })

    local window = {
        Gui = gui,
        Main = main,
        PagesContainer = pagesContainer,
        Pages = {},
        Tabs = {},
        Current = nil
    }

    function window:CreatePage(name)
        local page = Instance.new("ScrollingFrame")
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.Visible = false
        page.ScrollBarThickness = 2
        page.ScrollBarImageColor3 = NeonUI.Theme.Stroke
        page.CanvasSize = UDim2.fromOffset(0, 320)
        page.Parent = pagesContainer

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 7)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = page

        self.Pages[name] = page
        return page
    end

    function window:Tab(name)
        local btn = NeonUI:Create("TextButton", {
            Size = UDim2.new(1, -12, 0, 36),
            Text = name,
            BackgroundColor3 = Color3.fromRGB(20,24,35),
            BackgroundTransparency = 0.3, -- Стеклянный эффект для кнопок вкладок
            TextColor3 = NeonUI.Theme.Text,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            Parent = tabHolder
        })
        NeonUI:Corner(btn, 8)
        NeonUI:Stroke(btn, Color3.fromRGB(30, 40, 60), 1)

        btn.MouseButton1Click:Connect(function()
            for _, p in pairs(self.Pages) do
                p.Visible = false
            end
            if self.Pages[name] then
                self.Pages[name].Visible = true
            end
        end)

        return btn
    end

    function window:Toggle(parent, text, default, callback)
        local state = default

        -- Плашка кнопки (добавлена прозрачность 0.3)
        local t = NeonUI:Create("TextButton", {
            Size = UDim2.new(1, -8, 0, 38),
            BackgroundColor3 = Color3.fromRGB(25,30,45),
            BackgroundTransparency = 0.3, 
            Text = text .. (state and " : ВКЛ" or " : ВЫКЛ"),
            TextColor3 = NeonUI.Theme.Text,
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            Parent = parent
        })
        NeonUI:Corner(t, 8)
        local s = NeonUI:Stroke(t, state and NeonUI.Theme.Accent or NeonUI.Theme.Stroke, 1)

        t.MouseButton1Click:Connect(function()
            state = not state
            t.Text = text .. (state and " : ВКЛ" or " : ВЫКЛ")
            s.Color = state and NeonUI.Theme.Accent or NeonUI.Theme.Stroke
            callback(state)
        end)

        return t
    end

    function window:Slider(parent, text, min, max, default, callback)
        local value = default

        -- Подложка слайдера (добавлена прозрачность 0.3)
        local frame = NeonUI:Create("Frame", {
            Size = UDim2.new(1, -8, 0, 52),
            BackgroundColor3 = Color3.fromRGB(25,30,45),
            BackgroundTransparency = 0.3, 
            Parent = parent
        })
        NeonUI:Corner(frame, 8)
        NeonUI:Stroke(frame, NeonUI.Theme.Stroke, 1)

        local label = NeonUI:Create("TextLabel", {
            Size = UDim2.new(1, -14, 0, 20),
            Position = UDim2.fromOffset(10, 6),
            BackgroundTransparency = 1,
            Text = text .. ": " .. value,
            TextColor3 = NeonUI.Theme.Text,
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = frame
        })

        local bar = NeonUI:Create("Frame", {
            Size = UDim2.new(1, -20, 0, 8),
            Position = UDim2.fromOffset(10, 34),
            BackgroundColor3 = Color3.fromRGB(15,18,25),
            Parent = frame
        })
        NeonUI:Corner(bar, 4)

        local fill = NeonUI:Create("Frame", {
            Size = UDim2.fromScale((default - min) / (max - min), 1),
            BackgroundColor3 = NeonUI.Theme.Accent,
            Parent = bar
        })
        NeonUI:Corner(fill, 4)

        bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                local function update(input)
                    local ratio = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                    value = math.floor(min + (max - min) * ratio)

                    fill.Size = UDim2.fromScale(ratio, 1)
                    label.Text = text .. ": " .. value
                    callback(value)
                end

                update(input)
                local move
                move = UserInputService.InputChanged:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
                        update(i)
                    end
                end)

                UserInputService.InputEnded:Once(function()
                    move:Disconnect()
                end)
            end
        end)

        return frame
    end

    function window:Label(parent, text)
        local l = NeonUI:Create("TextLabel", {
            Size = UDim2.new(1, -8, 0, 28),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = NeonUI.Theme.Text,
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = parent
        })
        return l
    end

    return window
end

-- ===================================================================================--
--                                 ЛОГИКА ПОЛЕТА И ДВИЖЕНИЯ                           --
-- ===================================================================================--

-- Проход сквозь стены (NoClip)
task.spawn(function()
    while true do
        RunService.Stepped:Wait()
        if SupremeEngine.Running and SupremeEngine.NoClip and LocalPlayer.Character then
            for _, limb in ipairs(LocalPlayer.Character:GetChildren()) do
                if limb:IsA("BasePart") then limb.CanCollide = false end
            end
        end
    end
end)

-- Очистка скорости (Анти-откидывание)
local function NullifyNodeVelocity(rootPart)
    if SupremeEngine.VelocitySpoof and rootPart then
        rootPart.Velocity = Vector3.new(0, 0, 0)
        rootPart.RotVelocity = Vector3.new(0, 0, 0)
    end
end

-- Навигация по точкам с динамическим расчетом скорости в полете
local function NavigateViaTween(targetCFrame, setGravity)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local distance = (root.Position - targetCFrame.Position).Magnitude
    local duration = distance / SupremeEngine.Speed

    SupremeEngine.CurrentTween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
    SupremeEngine.CurrentTween:Play()

    local reached = false
    local connection
    connection = SupremeEngine.CurrentTween.Completed:Connect(function()
        reached = true
        connection:Disconnect()
    end)

    if setGravity then
        workspace.Gravity = DefaultWorldGravity
    else
        workspace.Gravity = 0
    end

    local lastSpeed = SupremeEngine.Speed
    while not reached and SupremeEngine.Running do
        if SupremeEngine.Speed ~= lastSpeed then
            lastSpeed = SupremeEngine.Speed
            if SupremeEngine.CurrentTween then SupremeEngine.CurrentTween:Cancel() end
            
            local currentDistance = (root.Position - targetCFrame.Position).Magnitude
            local newDuration = currentDistance / SupremeEngine.Speed
            SupremeEngine.CurrentTween = TweenService:Create(root, TweenInfo.new(newDuration, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
            SupremeEngine.CurrentTween:Play()
            connection = SupremeEngine.CurrentTween.Completed:Connect(function()
                reached = true
                connection:Disconnect()
            end)
        end
        NullifyNodeVelocity(root)
        RunService.Heartbeat:Wait()
    end
end

-- Цикл автоматизации автофарма
local function ExecuteAutomationLoop()
    while SupremeEngine.Running do
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local root = char:WaitForChild("HumanoidRootPart", 5)
        if not root then return end

        for i, cf in ipairs(destinations) do
            if not SupremeEngine.Running then return end
            NavigateViaTween(cf, i == #destinations)
        end

        SupremeEngine.Stats.Runs = SupremeEngine.Stats.Runs + 1
        SupremeEngine.Stats.GoldEarned = SupremeEngine.Stats.GoldEarned + 100

        repeat
            task.wait(1)
        until LocalPlayer.CharacterAdded:Wait()
    end
end

-- AntiAfk кликер (каждые 10 секунд жмет кнопку K)
task.spawn(function()
    while true do
        task.wait(10)
        if SupremeEngine.Running then
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.K, false, game)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.K, false, game)
        end
    end
end)

--===================================================================================--
-- СБОРКА ИНТЕРФЕЙСА СЛАЙДЕРОВ И КНОПОК
--===================================================================================--

local Window = NeonUI:CreateWindow("SUPREME ENGINE v10")

local MainPage = Window:CreatePage("🏠 Главная")
local SettingsPage = Window:CreatePage("⚙️ Настройки")
local StatsPage = Window:CreatePage("📊 Статистика")

Window:Tab("🏠 Главная")
Window:Tab("⚙️ Настройки")
Window:Tab("📊 Статистика")

MainPage.Visible = true

Window:Toggle(MainPage, "🚀 Автофарм + AntiAfk", false, function(state)
    SupremeEngine.Running = state
    if state then
        task.spawn(ExecuteAutomationLoop)
    else
        if SupremeEngine.CurrentTween then SupremeEngine.CurrentTween:Cancel() end
        workspace.Gravity = DefaultWorldGravity
    end
end)

Window:Toggle(MainPage, "👻 Проход Сквозь Стены", SupremeEngine.NoClip, function(v) SupremeEngine.NoClip = v end)
Window:Toggle(MainPage, "⚡ Стабилизатор Скорости", SupremeEngine.VelocitySpoof, function(v) SupremeEngine.VelocitySpoof = v end)

-- Ползунок, который регулирует скорость полета от 50 до 500
Window:Slider(SettingsPage, "Скорость полета", 50, 500, SupremeEngine.Speed, function(v) 
    SupremeEngine.Speed = v 
end)

local LabelRuns = Window:Label(StatsPage, "Пройдено раундов: 0")
local LabelGold = Window:Label(StatsPage, "Заработано золота (~): 0")
local LabelTime = Window:Label(StatsPage, "Время работы: 0 сек")

task.spawn(function()
    while true do
        task.wait(1)
        if Window.Gui.Parent then
            LabelRuns.Text = "Пройдено раундов: " .. SupremeEngine.Stats.Runs
            LabelGold.Text = "Заработано золота (~): " .. SupremeEngine.Stats.GoldEarned
            LabelTime.Text = "Время работы: " .. (os.time() - SupremeEngine.Stats.StartTime) .. " сек"
        else
            break
        end
    end
end)

-- Авто-респавн логика при перезагрузке персонажа
LocalPlayer.CharacterAdded:Connect(function()
    if SupremeEngine.Running then
        task.spawn(ExecuteAutomationLoop)
    end
end)
