-- Gomorron Cheats - Universal Aimbot
-- Made by @gomorronmannen on Discord

-- Settings
local fov            = 150
local maxFOV         = 800
local showFOV        = true
local bodyParts      = {"Head", "Torso"}
local selectedPartIndex = 2
local lockPartDisplay   = bodyParts[selectedPartIndex]
local smoothness     = 0
local maxSmoothness  = 100
local espEnabled     = false
local aimbotEnabled  = false
local currentTarget  = nil
local uiVisible      = false

-- Services
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Camera           = workspace.CurrentCamera
local TweenService     = game:GetService("TweenService")

-- Ray params for wallcheck
local rayParams = RaycastParams.new()
rayParams.FilterType                   = Enum.RaycastFilterType.Blacklist
rayParams.FilterDescendantsInstances   = {}

-- FOV circle
local circle = Drawing.new("Circle")
circle.Transparency = 1
circle.Color        = Color3.new(255, 255, 255)
circle.Thickness    = 1
circle.NumSides     = 64

-- ESP setup and colors
local colors = {
    red    = Color3.new(1, 0, 0),
    blue   = Color3.new(0, 0, 1),
    green  = Color3.new(0, 1, 0),
    yellow = Color3.new(1, 1, 0),
}

local function setupESP(character)
    if not espMode or not character or character:FindFirstChild("__GomorronESP") then return end
    local hl = Instance.new("Highlight")
    hl.Name = "__GomorronESP"
    hl.Adornee = character
    hl.FillColor = colors[espMode]
    hl.OutlineColor = colors[espMode]
    hl.FillTransparency = 0.6
    hl.OutlineTransparency = 0
    hl.Parent = character
end

local function clearESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then
            local hl = plr.Character:FindFirstChild("__GomorronESP")
            if hl and (
                not espMode  -- no ESP active
                or (plr.Character:FindFirstChild("Humanoid") 
                    and plr.Character.Humanoid.Health <= 0) -- player is dead
            ) then
                hl:Destroy()
            end
        end
    end
end

spawn(function()
    while wait(0.5) do
        if espMode then -- check color mode instead of espEnabled
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= Players.LocalPlayer and plr.Character then
                    setupESP(plr.Character)
                end
            end
        end
        clearESP()
    end
end)

-- Target acquisition & lock-on
local function getClosestTarget()
    local best, sd = nil, math.huge
    local center = Camera.ViewportSize/2
    local origin = Camera.CFrame.Position
    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= Players.LocalPlayer and plr.Character then
            local partName = (lockPartDisplay == "Torso") and "HumanoidRootPart" or lockPartDisplay
            local part     = plr.Character:FindFirstChild(partName)
            local hum      = plr.Character:FindFirstChild("Humanoid")
            if part and hum and hum.Health > 0 then
                rayParams.FilterDescendantsInstances = {Players.LocalPlayer.Character, workspace.Terrain}
                local res = workspace:Raycast(origin, part.Position - origin, rayParams)
                if res and res.Instance and res.Instance:IsDescendantOf(plr.Character) then
                    local pos2d, on = Camera:WorldToViewportPoint(part.Position)
                    local dist2d = (Vector2.new(pos2d.X, pos2d.Y) - center).Magnitude
                    if on and dist2d <= fov and dist2d < sd then
                        sd, best = dist2d, plr
                    end
                end
            end
        end
    end
    currentTarget = best
end

local function lockOn()
    if currentTarget and currentTarget.Character then
        local name = (lockPartDisplay == "Torso") and "HumanoidRootPart" or lockPartDisplay
        local part = currentTarget.Character:FindFirstChild(name)
        if part then
            local alpha = math.clamp(1 - (smoothness / maxSmoothness), 0.01, 1)
            Camera.CFrame = Camera.CFrame:Lerp(
                CFrame.new(Camera.CFrame.Position, part.Position),
                alpha
            )
        else
            currentTarget = nil
        end
    end
end

local function isTargetVisible(target)
    if not target or not target.Character then return false end

    local partName = (lockPartDisplay == "Torso") and "HumanoidRootPart" or lockPartDisplay
    local part = target.Character:FindFirstChild(partName)
    local hum  = target.Character:FindFirstChild("Humanoid")
    if not part or not hum or hum.Health <= 0 then
        return false
    end

    rayParams.FilterDescendantsInstances = {Players.LocalPlayer.Character, workspace.Terrain}
    local origin = Camera.CFrame.Position
    local result = workspace:Raycast(origin, part.Position - origin, rayParams)

    -- If ray hits the target's character, they are visible
    return (result and result.Instance and result.Instance:IsDescendantOf(target.Character))
end

-- RenderStepped hook for FOV circle & aimlock
RunService.RenderStepped:Connect(function()
    local center = Camera.ViewportSize/2
    circle.Visible  = showFOV and aimbotEnabled
    circle.Radius   = fov
    circle.Position = center
if aimbotEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
    if currentTarget then
        -- Cancel lock if target goes behind wall
        if not isTargetVisible(currentTarget) then
            currentTarget = nil
        else
            lockOn()
        end
    else
        getClosestTarget()
    end
else
    currentTarget = nil
end
end)

-- Glassmorphic UI creation with Tab System
local function createUI()
    -- Clean up old UI
    if game.CoreGui:FindFirstChild("GomorronAimbotUI") then
        game.CoreGui.GomorronAimbotUI:Destroy()
        local oldBlur = workspace.CurrentCamera:FindFirstChild("GomorronUIBlur")
        if oldBlur then oldBlur:Destroy() end
    end

    -- ScreenGui
    local screen = Instance.new("ScreenGui")
    screen.Name = "GomorronAimbotUI"
    screen.ResetOnSpawn = false
    screen.Parent = game.CoreGui
    screen.Enabled = true

    -- Background blur
    local blur = Instance.new("BlurEffect")
    blur.Name = "GomorronUIBlur"
    blur.Size = 0
    blur.Enabled = false
    blur.Parent = workspace.CurrentCamera

    -- Main panel
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 420, 0, 345)
    main.Position = UDim2.new(1, 340, 0, 80)
    main.AnchorPoint = Vector2.new(1, 0)
    main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    main.BackgroundTransparency = 0.1
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Parent = screen
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 16)

    -- Gradient overlay
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 40)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 20))
    }
    grad.Parent = main

    -- Outline
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(199, 135, 93)
    stroke.Transparency = 0.8
    stroke.Thickness = 2
    stroke.Parent = main

    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 95) -- Slightly taller header
    header.BackgroundTransparency = 1
    header.Parent = main

    -- Logo with slightly rounded corners (bigger)
    local logo = Instance.new("ImageLabel")
    logo.Size = UDim2.new(0, 78, 0, 78) -- Slightly bigger
    logo.Position = UDim2.new(0, 10, 0.5, -39) -- Perfectly centered vertically
    logo.Image = "rbxassetid://102193454780356"
    logo.BackgroundTransparency = 0
    logo.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    local logoCorner = Instance.new("UICorner")
    logoCorner.CornerRadius = UDim.new(0, 12) -- Rounded but still rectangular
    logoCorner.Parent = logo
    logo.Parent = header

    -- Title (center aligned with logo)
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -115, 0, 36)
    title.Position = UDim2.new(0, 110, 0.5, -26) -- Slightly above center for balance
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(199, 135, 93)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 28
    title.Text = "Gomorron Cheats"
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    -- Subtitle (just below title)
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -115, 0, 20)
    subtitle.Position = UDim2.new(0, 110, 0.5, 12) -- Perfectly under title
    subtitle.BackgroundTransparency = 1
    subtitle.TextColor3 = Color3.fromRGB(200, 200, 200)
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 16
    subtitle.Text = "Universal Aimbot & ESP"
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = header
    
    -- Tween setup
    local blurOpen = TweenService:Create(blur, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {Size = 24})
    local blurClose = TweenService:Create(blur, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = 0})
    local openTween = TweenService:Create(main, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {Position = UDim2.new(1, -340, 0, 80)})
    local closeTween = TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Position = UDim2.new(1, 340, 0, 80)})

    blur.Enabled = true
    blurOpen:Play()
    openTween:Play()
    uiVisible = true

    -- Make UI draggable
    local function makeDraggable(handle, frame)
        local dragging, dragInput, startPos, startMousePos
        handle.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                startPos = frame.Position
                startMousePos = inp.Position
                inp.Changed:Connect(function()
                    if inp.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        handle.InputChanged:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseMovement then
                dragInput = inp
            end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if dragging and inp == dragInput then
                local delta = inp.Position - startMousePos
                frame.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end)
    end
    makeDraggable(header, main, grad, logo, stroke)

    -- Utility: Slider & Toggle
    local function addSlider(y, labelText, initial, maxVal, onChange, parent)
        local current = initial
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0, 300, 0, 24)
        lbl.Position = UDim2.new(0, 10, 0, y)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 18
        lbl.Text = labelText .. ": " .. current
        lbl.Parent = parent

        local track = Instance.new("Frame")
        track.Size = UDim2.new(0, 300, 0, 12)
        track.Position = UDim2.new(0, 10, 0, y + 28)
        track.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        track.BackgroundTransparency = 0.2
        Instance.new("UICorner", track).CornerRadius = UDim.new(0, 6)
        track.Parent = parent

        local thumb = Instance.new("Frame")
        thumb.Size = UDim2.new(current / maxVal, 0, 1, 0)
        thumb.BackgroundColor3 = Color3.fromRGB(199, 135, 93)
        Instance.new("UICorner", thumb).CornerRadius = UDim.new(0, 6)
        thumb.Parent = track

        local dragging = false
        track.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
        end)
        track.InputChanged:Connect(function(i)
            if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                local x = math.clamp(i.Position.X - track.AbsolutePosition.X, 0, track.AbsoluteSize.X)
                local pct = x / track.AbsoluteSize.X
                current = math.floor(pct * maxVal)
                onChange(current)
                thumb.Size = UDim2.new(pct, 0, 1, 0)
                lbl.Text = labelText .. ": " .. current
            end
        end)
        track.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
    end

    local function addToggle(y, labelText, getter, setter, parent)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 300, 0, 32)
        btn.Position = UDim2.new(0, 10, 0, y)
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        btn.BackgroundTransparency = 0.3
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 18
        btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        btn.AutoButtonColor = false
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        btn.Parent = parent

        local function update()
            local on = getter()
            btn.Text = labelText .. ": " .. (on and "ON" or "OFF")
            btn.BackgroundTransparency = on and 0.1 or 0.3
            btn.TextColor3 = on and Color3.fromRGB(199, 135, 93) or Color3.fromRGB(200, 200, 200)
        end

        btn.MouseButton1Click:Connect(function()
            setter(not getter())
            update()
        end)
        update()
    end

    -- Tabs
    local sideTabs = Instance.new("Frame")
    sideTabs.Size = UDim2.new(0, 90, 1, -80)
    sideTabs.Position = UDim2.new(0, 0, 0, 80)
    sideTabs.BackgroundTransparency = 1
    sideTabs.Parent = main

    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, -90, 1, -80)
    contentFrame.Position = UDim2.new(0, 90, 0, 80)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = main

    local aimbotFrame = Instance.new("Frame")
    aimbotFrame.Size = UDim2.new(1, 0, 1, 0)
    aimbotFrame.BackgroundTransparency = 1
    aimbotFrame.Parent = contentFrame

    local espFrame = Instance.new("Frame")
    espFrame.Size = UDim2.new(1, 0, 1, 0)
    espFrame.BackgroundTransparency = 1
    espFrame.Visible = false
    espFrame.Parent = contentFrame

local activeTab = "Aimbot"
local tabPadding = 15

local function createSideTab(name, order, onClick)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.Position = UDim2.new(0, 3, 0, tabPadding + (order - 1) * 45)
    btn.BackgroundTransparency = 1
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.TextColor3 = (name == activeTab) and Color3.fromRGB(199, 135, 93) or Color3.fromRGB(200, 200, 200)
    btn.Text = name
    btn.Parent = sideTabs

    local underline = Instance.new("Frame")
    underline.AnchorPoint = Vector2.new(0.5, 1)
    underline.Position = UDim2.new(0.5, 0, 1, 0)
    underline.Size = UDim2.new(0.8, 0, 0, 2)
    underline.BackgroundColor3 = Color3.fromRGB(199, 135, 93)
    underline.Visible = (name == activeTab)
    underline.Parent = btn

    btn.MouseButton1Click:Connect(function()
        activeTab = name
        onClick()
        for _, child in ipairs(sideTabs:GetChildren()) do
            if child:IsA("TextButton") then
                local isActive = (child.Text == activeTab)
                child.TextColor3 = isActive and Color3.fromRGB(199, 135, 93) or Color3.fromRGB(200, 200, 200)
                if child:FindFirstChildOfClass("Frame") then
                    child:FindFirstChildOfClass("Frame").Visible = isActive
                end
            end
        end
    end)
end

    createSideTab("Aimbot", 1, function()
        aimbotFrame.Visible = true
        espFrame.Visible = false
    end)
    createSideTab("ESP", 2, function()
        aimbotFrame.Visible = false
        espFrame.Visible = true
    end)

    -- Controls
    addSlider(20, "FOV", fov, maxFOV, function(v) fov = v end, aimbotFrame)
    addSlider(80, "Smoothness", smoothness, maxSmoothness, function(v) smoothness = v end, aimbotFrame)
    addToggle(140, "Aimlock", function() return aimbotEnabled end, function(v) aimbotEnabled = v end, aimbotFrame)

    local partBtn = Instance.new("TextButton")
    partBtn.Size = UDim2.new(0, 300, 0, 32)
    partBtn.Position = UDim2.new(0, 10, 0, 200)
    partBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    partBtn.BackgroundTransparency = 0.3
    partBtn.Font = Enum.Font.GothamBold
    partBtn.TextSize = 18
    partBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    partBtn.Text = "Target: " .. lockPartDisplay
    Instance.new("UICorner", partBtn).CornerRadius = UDim.new(0, 8)
    partBtn.Parent = aimbotFrame

    partBtn.MouseButton1Click:Connect(function()
        selectedPartIndex = (selectedPartIndex % #bodyParts) + 1
        lockPartDisplay = bodyParts[selectedPartIndex]
        partBtn.Text = "Target: " .. lockPartDisplay
    end)

    -- Color toggles
    addToggle(20, "Highlight (Red)", function() return espMode == "red" end, function(v)
        espMode = v and "red" or nil
    end, espFrame)

    addToggle(70, "Highlight (Blue)", function() return espMode == "blue" end, function(v)
        espMode = v and "blue" or nil
    end, espFrame)

    addToggle(120, "Highlight (Green)", function() return espMode == "green" end, function(v)
        espMode = v and "green" or nil
    end, espFrame)

    addToggle(170, "Highlight (Yellow)", function() return espMode == "yellow" end, function(v)
        espMode = v and "yellow" or nil
    end, espFrame)

    -- Note
    local note = Instance.new("TextLabel")
    note.Size = UDim2.new(1, -20, 0, 20)
    note.Position = UDim2.new(0, 10, 1, -26)
    note.BackgroundTransparency = 1
    note.Text = "Toggle Menu With RightShift"
    note.TextColor3 = Color3.fromRGB(200, 200, 200)
    note.TextTransparency = 0.3
    note.Font = Enum.Font.Gotham
    note.TextSize = 14
    note.TextXAlignment = Enum.TextXAlignment.Center
    note.Parent = main

    -- Toggle UI with RightShift
    UserInputService.InputBegan:Connect(function(inp, gp)
        if not gp and inp.KeyCode == Enum.KeyCode.RightShift then
            if screen.Enabled then
                blurClose:Play()
                closeTween:Play()
                task.delay(0.35, function()
                    blur.Enabled = false
                    screen.Enabled = false
                end)
            else
                screen.Enabled = true
                blur.Enabled = true
                blurOpen:Play()
                openTween:Play()
            end
        end
    end)
end

-- Init
createUI()
