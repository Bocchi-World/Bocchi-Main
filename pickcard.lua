repeat task.wait() until game:IsLoaded()

local player = game:GetService("Players").LocalPlayer
local playergui = player:WaitForChild("PlayerGui")
local roguelikeselect = playergui:WaitForChild("RoguelikeSelect")
local waveValue = game:GetService("Workspace"):WaitForChild("_wave_num")
roguelikeselect.Enabled = true
task.wait(0.5) 
roguelikeselect.Enabled = false
local wavenumber
waveValue:GetPropertyChangedSignal("Value"):Connect(function()
    wavenumber = waveValue.Value
end)
local timeout = 10  
local startTime = tick()
repeat 
    task.wait()
    if tick() - startTime > timeout then
        warn("Timeout waiting for wavenumber update!")
        break
    end
until wavenumber and wavenumber >= 1

local positiontable = {}
local newoptions = {}
local args = {}
local isProcessing = false
playergui:FindFirstChild("RoguelikeSelect"):GetPropertyChangedSignal("Enabled"):Connect(function()
    if isProcessing then return end
    isProcessing = true
    wait()

    local optionframe = playergui.RoguelikeSelect.Main.Main.Items:FindFirstChild("OptionFrame")
    if not optionframe then 
        isProcessing = false
        return 
    end

    optionframe.Active = true
    optionframe.Active = false
    wait(1)

    local options = playergui.RoguelikeSelect.Main.Main.Items:GetChildren()
    positiontable = {}

    for _, v in pairs(options) do
        if v.Name == "OptionFrame" and v:IsA("Frame") and v:FindFirstChild("bg") then
            table.insert(positiontable, v.AbsolutePosition.X)
        end
    end

    table.sort(positiontable)
    newoptions = {}

    for _, v in pairs(options) do
        if v.Name == "OptionFrame" and v:IsA("Frame") and v:FindFirstChild("bg") then
            if v.AbsolutePosition.X == positiontable[1] then
                table.insert(newoptions, v.bg.Main.Title.TextLabel)
            elseif #newoptions >= 1 and v.AbsolutePosition.X == positiontable[2] then
                table.insert(newoptions, v.bg.Main.Title.TextLabel)
            elseif #newoptions >= 2 and v.AbsolutePosition.X == positiontable[3] then
                table.insert(newoptions, v.bg.Main.Title.TextLabel)
            end
        end
    end
    if #newoptions < 3 then
        warn("Không đủ lựa chọn trong GUI!")
        isProcessing = false
        return
    end
    local priorityList = (wavenumber and wavenumber <= getgenv().FocusWave) and getgenv().PriorityCards or getgenv().Cards

    for _, card in ipairs(priorityList) do
        if newoptions[1].Text == card then
            args = {[1] = "1"}
        elseif newoptions[2].Text == card then
            args = {[1] = "3"}
        elseif newoptions[3].Text == card then
            args = {[1] = "2"}
        end
    end

    wait(0.5)
    if args[1] then
        game:GetService("ReplicatedStorage").endpoints.client_to_server.select_roguelike_option:InvokeServer(unpack(args))
    end

    isProcessing = false
end)
if not roguelikeselect.Enabled then
    roguelikeselect.Enabled = true
    task.wait(0.5)
    roguelikeselect.Enabled = false
end
