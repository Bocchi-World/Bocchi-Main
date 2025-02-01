function UI()
    local player = game.Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    local oldGui = playerGui:FindFirstChild("BlackoutGui")
    if oldGui then
        oldGui:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BlackoutGui"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    screenGui.Parent = playerGui

    local uiFrame = Instance.new("Frame")
    uiFrame.Name = "UIFrame"
    uiFrame.Parent = screenGui
    uiFrame.Size = UDim2.new(1, 0, 1, 0)
    uiFrame.Position = UDim2.new(0, 0, 0, 0)
    uiFrame.BackgroundTransparency = 1 -- Ẩn nền

    local blackoutFrame = Instance.new("Frame")
    blackoutFrame.Name = "BlackoutFrame"
    blackoutFrame.Parent = uiFrame
    blackoutFrame.Size = UDim2.new(1, 0, 1, 0)
    blackoutFrame.Position = UDim2.new(0, 0, 0, 0)
    blackoutFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    blackoutFrame.BackgroundTransparency = 0.2

    local logo = Instance.new("ImageLabel")
    logo.Name = "Logo"
    logo.Parent = uiFrame
    logo.Image = "rbxassetid://85930027487051"
    logo.Size = UDim2.new(0.4, 0, 0.4, 0)
    logo.Position = UDim2.new(0.5, 0, 0.3, 0)
    logo.AnchorPoint = Vector2.new(0.5, 0.5)
    logo.BackgroundTransparency = 1
    logo.ScaleType = Enum.ScaleType.Fit
    
    local function createTextLabel(text, position)
        local textLabel = Instance.new("TextLabel")
        textLabel.Name = "TextLabel"
        textLabel.Parent = uiFrame
        textLabel.Text = text
        textLabel.Size = UDim2.new(0.6, 0, 0.1, 0)
        textLabel.Position = position
        textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = Color3.new(1, 1, 1)
        textLabel.TextSize = 30
        textLabel.Font = Enum.Font.Cartoon
        textLabel.TextStrokeTransparency = 0.8
        textLabel.TextXAlignment = Enum.TextXAlignment.Center
        textLabel.TextYAlignment = Enum.TextYAlignment.Center
        return textLabel
    end
    createTextLabel("discord.gg/bocchiworld", UDim2.new(0.5, 0, 0.4, 0))
    createTextLabel("JOIN AND BUY SCRIPT KAITUN NOW :))", UDim2.new(0.5, 0, 0.45, 0))
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Parent = screenGui
    toggleButton.Size = UDim2.new(0.05, 0, 0.05, 0)
    toggleButton.Position = UDim2.new(0.95, -30, 0.5, 0)
    toggleButton.AnchorPoint = Vector2.new(0.5, 0.5)
    toggleButton.BackgroundColor3 = Color3.fromRGB(255, 182, 193) -- Màu hồng nhạt
    toggleButton.Text = ""
    toggleButton.BorderSizePixel = 0
    toggleButton.AutoButtonColor = true
    toggleButton.ClipsDescendants = true
    toggleButton.ZIndex = 10
    toggleButton.TextTransparency = 1
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = toggleButton
    toggleButton.MouseButton1Click:Connect(function()
        uiFrame.Visible = not uiFrame.Visible
    end)
end

function JoinNewEvent()
    if game.PlaceId ~= 8304191830 then
        return
    end

    local player = game.Players.LocalPlayer
    local path = player:WaitForChild("PlayerGui"):WaitForChild("ContractsUI"):WaitForChild("Main"):WaitForChild("Main")
    local scroll = path:WaitForChild("Frame"):WaitForChild("Outer"):WaitForChild("main"):WaitForChild("Scroll")

    local tierToEventID = {
        ["Tier: 2"] = "__EVENT_CONTRACT_Sakamoto:1",
        ["Tier: 5"] = "__EVENT_CONTRACT_Sakamoto:2",
        ["Tier: 6"] = "__EVENT_CONTRACT_Sakamoto:3",
        ["Tier: 9"] = "__EVENT_CONTRACT_Sakamoto:4",
        ["Tier: 10"] = "__EVENT_CONTRACT_Sakamoto:5",
        ["Tier: 16"] = "__EVENT_CONTRACT_Sakamoto:6"
    }

    local missionFrames = {}
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("Frame") and child.Name == "MissionFrame" then
            table.insert(missionFrames, child)
        end
    end

    local highestUnclearedTier = nil  -- Lưu tier cao nhất chưa clear
    local highestEventID = nil  -- ID của tier cao nhất chưa clear

    for _, missionFrame in ipairs(missionFrames) do
        local difficulty = missionFrame:FindFirstChild("Main") and missionFrame.Main:FindFirstChild("Difficulty")
        local cleared = missionFrame:FindFirstChild("Main") and missionFrame.Main:FindFirstChild("Cleared")

        local tierText = difficulty and difficulty:IsA("TextLabel") and difficulty.Text or "Tier: ???"

        local clearStatus = (cleared and cleared:IsA("GuiObject") and cleared.Visible) and "Yes" or "No"

        print(tierText .. " | Clear: " .. clearStatus)

        if getgenv().Config["Auto Join Tier"][tierText] then
            if clearStatus == "No" and tierToEventID[tierText] then
                local eventID = tierToEventID[tierText]
                
                if not highestUnclearedTier or tonumber(tierText:match("%d+")) > tonumber(highestUnclearedTier:match("%d+")) then
                    highestUnclearedTier = tierText
                    highestEventID = eventID
                end
            end
        else
            print(tierText .. " skipped (Auto Join disabled)")
        end
    end

    if highestUnclearedTier then
        print("[Bocchi World] Running matchmaking for " .. highestUnclearedTier .. " -> " .. highestEventID)
        
        local args = {
            [1] = highestEventID
        }
        
        game:GetService("ReplicatedStorage").endpoints.client_to_server.request_matchmaking:InvokeServer(unpack(args))
    else
        print("[Bocchi World] Clear all")
    end
end
UI()
JoinNewEvent()
