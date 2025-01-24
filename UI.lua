local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
local existingUI = playerGui:FindFirstChild("Bocchi UI")
if existingUI then
    existingUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Bocchi UI"
ScreenGui.Parent = playerGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true

local Frame = Instance.new("Frame")
local logo = Instance.new("ImageLabel")
local level = Instance.new("TextLabel")
local Name = Instance.new("TextLabel")
local Gold = Instance.new("TextLabel")
local Gems = Instance.new("TextLabel")
local BTP = Instance.new("TextLabel")
local status = Instance.new("TextLabel")
local link = Instance.new("TextLabel")
local Stars = Instance.new("TextLabel")
local fps = Instance.new("TextLabel")
local name = Instance.new("TextLabel")

Frame.Parent = ScreenGui
Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Frame.BackgroundTransparency = 0.300
Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
Frame.BorderSizePixel = 2
Frame.Size = UDim2.new(0.8, 0, 0.6, 0)
Frame.AnchorPoint = Vector2.new(0.5, 0.5)
Frame.Position = UDim2.new(0.5, 0, 0.5, 0)

logo.Name = "logo"
logo.Parent = Frame
logo.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
logo.BackgroundTransparency = 1.000
logo.BorderColor3 = Color3.fromRGB(255, 20, 185)
logo.BorderSizePixel = 3
logo.Position = UDim2.new(0.5, 0, 0.1, 0)
logo.Size = UDim2.new(0.2, 0, 0.2, 0)
logo.Image = "rbxassetid://120597571761072"
logo.AnchorPoint = Vector2.new(0.5, 0.5)

name.Name = "name"
name.Parent = Frame
name.BackgroundColor3 = Color3.fromRGB(66, 66, 66)
name.BackgroundTransparency = 1.000
name.BorderColor3 = Color3.fromRGB(0, 0, 0)
name.BorderSizePixel = 0
name.Position = UDim2.new(0.5, 0, 0.3, 0)
name.Size = UDim2.new(0.5, 0, 0.1, 0)
name.Font = Enum.Font.LuckiestGuy
name.Text = "BOCCHI WORLD"
name.TextColor3 = Color3.fromRGB(255, 255, 255)
name.TextSize = 30.000
name.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
name.AnchorPoint = Vector2.new(0.5, 0.5)

Name.Name = "Name"
Name.Parent = Frame
Name.BackgroundColor3 = Color3.fromRGB(66, 66, 66)
Name.BackgroundTransparency = 1.000
Name.BorderColor3 = Color3.fromRGB(0, 0, 0)
Name.BorderSizePixel = 0
Name.Position = UDim2.new(0.3, 0, 0.4, 0)
Name.Size = UDim2.new(0.4, 0, 0.1, 0)
Name.Font = Enum.Font.LuckiestGuy
Name.Text = "Name: " .. game.Players.LocalPlayer.Name
Name.TextColor3 = Color3.fromRGB(255, 255, 255)
Name.TextSize = 20.000
Name.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
Name.AnchorPoint = Vector2.new(0.5, 0.5)

level.Name = "level"
level.Parent = Frame
level.BackgroundColor3 = Color3.fromRGB(66, 66, 66)
level.BackgroundTransparency = 1.000
level.BorderColor3 = Color3.fromRGB(0, 0, 0)
level.BorderSizePixel = 0
level.Position = UDim2.new(0.3, 0, 0.5, 0)
level.Size = UDim2.new(0.4, 0, 0.1, 0)
level.Font = Enum.Font.LuckiestGuy
level.Text = "Level: "
level.TextColor3 = Color3.fromRGB(255, 255, 255)
level.TextSize = 20.000
level.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
level.AnchorPoint = Vector2.new(0.5, 0.5)

BTP.Name = "BTP"
BTP.Parent = Frame
BTP.BackgroundColor3 = Color3.fromRGB(66, 66, 66)
BTP.BackgroundTransparency = 1.000
BTP.BorderColor3 = Color3.fromRGB(0, 0, 0)
BTP.BorderSizePixel = 0
BTP.Position = UDim2.new(0.3, 0, 0.6, 0)
BTP.Size = UDim2.new(0.4, 0, 0.1, 0)
BTP.Font = Enum.Font.LuckiestGuy
BTP.Text = "BTP Level: "
BTP.TextColor3 = Color3.fromRGB(255, 255, 255)
BTP.TextSize = 20.000
BTP.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
BTP.AnchorPoint = Vector2.new(0.5, 0.5)

Gems.Name = "Gems"
Gems.Parent = Frame
Gems.BackgroundColor3 = Color3.fromRGB(66, 66, 66)
Gems.BackgroundTransparency = 1.000
Gems.BorderColor3 = Color3.fromRGB(0, 0, 0)
Gems.BorderSizePixel = 0
Gems.Position = UDim2.new(0.7, 0, 0.4, 0)
Gems.Size = UDim2.new(0.4, 0, 0.1, 0)
Gems.Font = Enum.Font.LuckiestGuy
Gems.Text = "Gems: "
Gems.TextColor3 = Color3.fromRGB(255, 255, 255)
Gems.TextSize = 20.000
Gems.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
Gems.AnchorPoint = Vector2.new(0.5, 0.5)

Gold.Name = "Gold"
Gold.Parent = Frame
Gold.BackgroundColor3 = Color3.fromRGB(66, 66, 66)
Gold.BackgroundTransparency = 1.000
Gold.BorderColor3 = Color3.fromRGB(0, 0, 0)
Gold.BorderSizePixel = 0
Gold.Position = UDim2.new(0.7, 0, 0.5, 0)
Gold.Size = UDim2.new(0.4, 0, 0.1, 0)
Gold.Font = Enum.Font.LuckiestGuy
Gold.Text = "Gold: "
Gold.TextColor3 = Color3.fromRGB(255, 255, 255)
Gold.TextSize = 20.000
Gold.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
Gold.AnchorPoint = Vector2.new(0.5, 0.5)

Stars.Name = "Stars"
Stars.Parent = Frame
Stars.BackgroundColor3 = Color3.fromRGB(66, 66, 66)
Stars.BackgroundTransparency = 1.000
Stars.BorderColor3 = Color3.fromRGB(0, 0, 0)
Stars.BorderSizePixel = 0
Stars.Position = UDim2.new(0.7, 0, 0.6, 0)
Stars.Size = UDim2.new(0.4, 0, 0.1, 0)
Stars.Font = Enum.Font.LuckiestGuy
Stars.Text = "Stars: "
Stars.TextColor3 = Color3.fromRGB(255, 255, 255)
Stars.TextSize = 20.000
Stars.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
Stars.AnchorPoint = Vector2.new(0.5, 0.5)

fps.Name = "fps"
fps.Parent = Frame
fps.BackgroundColor3 = Color3.fromRGB(66, 66, 66)
fps.BackgroundTransparency = 1.000
fps.BorderColor3 = Color3.fromRGB(0, 0, 0)
fps.BorderSizePixel = 0
fps.Position = UDim2.new(0.5, 0, 0.7, 0)
fps.Size = UDim2.new(0.4, 0, 0.1, 0)
fps.Font = Enum.Font.LuckiestGuy
fps.Text = "FPS: "
fps.TextColor3 = Color3.fromRGB(255, 255, 255)
fps.TextSize = 20.000
fps.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
fps.AnchorPoint = Vector2.new(0.5, 0.5)

status.Name = "status"
status.Parent = Frame
status.BackgroundColor3 = Color3.fromRGB(66, 66, 66)
status.BackgroundTransparency = 1.000
status.BorderColor3 = Color3.fromRGB(0, 0, 0)
status.BorderSizePixel = 0
status.Position = UDim2.new(0.5, 0, 0.8, 0)
status.Size = UDim2.new(0.4, 0, 0.1, 0)
status.Font = Enum.Font.LuckiestGuy
status.Text = "Status: "
status.TextColor3 = Color3.fromRGB(255, 255, 255)
status.TextSize = 30.000
status.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
status.AnchorPoint = Vector2.new(0.5, 0.5)

link.Name = "link"
link.Parent = Frame
link.BackgroundColor3 = Color3.fromRGB(66, 66, 66)
link.BackgroundTransparency = 1.000
link.BorderColor3 = Color3.fromRGB(0, 0, 0)
link.BorderSizePixel = 0
link.Position = UDim2.new(0.5, 0, 0.9, 0)
link.Size = UDim2.new(0.4, 0, 0.1, 0)
link.Font = Enum.Font.LuckiestGuy
link.Text = "DISCORD.GG/BOCCHIWORLD"
link.TextColor3 = Color3.fromRGB(255, 255, 255)
link.TextSize = 20.000
link.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
link.AnchorPoint = Vector2.new(0.5, 0.5)

local function check_level()
    local player = game.Players.LocalPlayer
    local levelText = player:FindFirstChild("PlayerGui")
        and player.PlayerGui:FindFirstChild("spawn_units")
        and player.PlayerGui.spawn_units:FindFirstChild("Lives")
        and player.PlayerGui.spawn_units.Lives:FindFirstChild("Main")
        and player.PlayerGui.spawn_units.Lives.Main:FindFirstChild("Desc")
        and player.PlayerGui.spawn_units.Lives.Main.Desc:FindFirstChild("Level")
        and player.PlayerGui.spawn_units.Lives.Main.Desc.Level.Text

    if levelText then
        level.Text = "Level: " .. levelText
    else
        level.Text = "Level: N/A"
    end
end

local function updateResources()
    local player = game.Players.LocalPlayer
    local stats = player:FindFirstChild("_stats")
    if not stats then
        warn("Stats not found!")
        return
    end

    local gem = stats:FindFirstChild("gem_amount") and stats.gem_amount.Value or 0
    local gold = stats:FindFirstChild("gold_amount") and stats.gold_amount.Value or 0
    local stars = stats:FindFirstChild("star_amount") and stats.star_amount.Value or 0

    Gems.Text = "Gems: " .. tostring(gem)
    Gold.Text = "Gold: " .. tostring(gold)
    Stars.Text = "Stars: " .. tostring(stars)
end

local function getBattlePassLevel()
    local reachedTier, myBPexp, BattlePass = 0, 0, "No BattlePass data"
    local battlePassData = game:GetService("ReplicatedStorage"):FindFirstChild("BattlePassData")
    if battlePassData then
        for _, bpModule in ipairs(battlePassData:GetChildren()) do
            if bpModule:IsA('ModuleScript') then
                local bpModulereq = require(bpModule)
                if bpModulereq[battlePassID] then
                    myBPexp = ItemInventoryServiceClient['session']['profile_data']['battlepass_data']
                    if myBPexp and myBPexp[battlePassID] and myBPexp[battlePassID].xp then
                        myBPexp = myBPexp[battlePassID].xp
                    else
                        myBPexp = 0
                    end

                    for tierNumb, aboutTier in pairs(bpModulereq[battlePassID].tiers) do
                        if aboutTier.xp_required > myBPexp or reachedTierExp > aboutTier.xp_required then
                            continue
                        end
                        reachedTierExp = aboutTier.xp_required
                        reachedTier = tierNumb
                    end

                    if bpModulereq[battlePassID].tiers[tostring(tonumber(reachedTier) + 1)] then
                        nextTierExp = string.format(
                            '%s/%s',
                            myBPexp - reachedTierExp,
                            bpModulereq[battlePassID].tiers[tostring(tonumber(reachedTier) + 1)].xp_required - reachedTierExp
                        )
                    else
                        nextTierExp = 'MAX'
                    end

                    BattlePass = string.format('%s [%s]', reachedTier, nextTierExp)
                    break
                end
            end
        end
    end
    return reachedTier, myBPexp, BattlePass
end

function updateBattlePassDisplay()
    local _, _, BattlePass = getBattlePassLevel()
    BTP.Text = "BTP Level: " .. BattlePass
end

local function updateFPS()
    local fpsValue = math.floor(1 / game:GetService("RunService").RenderStepped:Wait())
    fps.Text = "FPS: " .. tostring(fpsValue)
end

while true do
    check_level()
    updateResources()
    updateBattlePassDisplay()
    updateFPS()
    wait(1)
end
