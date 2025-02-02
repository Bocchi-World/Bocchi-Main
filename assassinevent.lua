

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
    uiFrame.BackgroundTransparency = 1

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
    toggleButton.BackgroundColor3 = Color3.fromRGB(255, 182, 193)
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

local function AutoJoinAssassin()
    local scrollFrame = game.Players.LocalPlayer.PlayerGui.ContractsUI.Main.Main.Frame.Outer.main.Scroll
    local remoteEvent = game:GetService("ReplicatedStorage").endpoints.client_to_server.request_matchmaking
    local loadoutEvent = game:GetService("ReplicatedStorage").endpoints.client_to_server.load_team_loadout

    local missions = {}

    for _, missionFrame in ipairs(scrollFrame:GetChildren()) do
        if missionFrame:IsA("Frame") then
            local difficultyLabel = missionFrame:FindFirstChild("Main") and missionFrame.Main:FindFirstChild("Difficulty")
            local clearedCheck = missionFrame:FindFirstChild("Main") and missionFrame.Main:FindFirstChild("Cleared")

            if difficultyLabel and clearedCheck then
                local tierText = difficultyLabel.Text
                local tierNumber = tonumber(tierText:match("%d+")) or 0
                local isCleared = clearedCheck.Visible
                
                if tierNumber > 0 then
                    table.insert(missions, { tier = tierNumber, cleared = isCleared, frame = missionFrame })
                end
            end
        end
    end

    table.sort(missions, function(a, b)
        return a.tier > b.tier
    end)

    local tierID = 6
    for _, mission in ipairs(missions) do
        if not mission.cleared then
            local damageTypeIconsFrame = mission.frame.Main:FindFirstChild("DamageTypeIcons")
            if damageTypeIconsFrame then
                local resistanceFrameAmp = damageTypeIconsFrame:FindFirstChild("ResistanceFrameAmp")
                if resistanceFrameAmp then
                    for _, imageLabel in ipairs(resistanceFrameAmp:GetChildren()) do
                        if imageLabel:IsA("ImageLabel") then
                            if imageLabel.Image == "rbxassetid://11499571416" then
                                loadoutEvent:InvokeServer("2")
                            elseif imageLabel.Image == "rbxassetid://11499567212" then
                                loadoutEvent:InvokeServer("1")
                            end
                        end
                    end
                end

                task.wait(5)

                local args = {
                    [1] = "__EVENT_CONTRACT_Sakamoto:" .. tierID
                }
                remoteEvent:InvokeServer(unpack(args))
                break
            end
        end
        tierID = tierID - 1
    end
end

function isAuthorized(username)
    for _, v in ipairs(getgenv().Config["Accept Load Script"]) do
        if v == username then
            return true
        end
    end
    return false
end

function getUsername()
    return game.Players.LocalPlayer.Name
end

if isAuthorized(getUsername()) then
    UI()
    AutoJoinAssassin()
else
    print("You not has permission for load Assassin Event Scripts [Made by Bocchi World]!")
end

