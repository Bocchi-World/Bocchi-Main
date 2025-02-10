repeat task.wait() until game:IsLoaded()

local player = game:GetService("Players").LocalPlayer
local playergui = player:WaitForChild("PlayerGui")
local roguelikeselect = playergui:WaitForChild("RoguelikeSelect")
local waveValue = game:GetService("Workspace"):WaitForChild("_wave_num")

roguelikeselect.Enabled = true
task.wait(0.5)
roguelikeselect.Enabled = false
local wavenumber = waveValue.Value
waveValue:GetPropertyChangedSignal("Value"):Connect(function()
    wavenumber = waveValue.Value
end)
repeat task.wait() until wavenumber and wavenumber >= 1

local function selectBestCard()
    local positiontable = {}
    local newoptions = {}
    local args = {}
    repeat task.wait() until roguelikeselect.Enabled

    wait()
    local optionframe = playergui.RoguelikeSelect.Main.Main.Items:FindFirstChild("OptionFrame")
    if not optionframe then return end

    optionframe.Active = true
    optionframe.Active = false
    wait(1)

    local options = playergui.RoguelikeSelect.Main.Main.Items:GetChildren()
    for _, v in pairs(options) do
        if v.Name == "OptionFrame" and v:IsA("Frame") and v:FindFirstChild("bg") then
            table.insert(positiontable, v.AbsolutePosition.X)
        end
    end

    table.sort(positiontable)

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
    if #newoptions < 3 then return end
    local priorityList = wavenumber <= getgenv().FocusWave and getgenv().PriorityCards or getgenv().Cards

    for _, card in ipairs(priorityList) do
        if newoptions[1].Text == card then
            args = {[1] = "1"}
            break
        elseif newoptions[2].Text == card then
            args = {[1] = "3"}
            break
        elseif newoptions[3].Text == card then
            args = {[1] = "2"}
            break
        end
    end

    wait(0.5)
    if args[1] then
        game:GetService("ReplicatedStorage").endpoints.client_to_server.select_roguelike_option:InvokeServer(unpack(args))
    end
end
roguelikeselect:GetPropertyChangedSignal("Enabled"):Connect(function()
    if roguelikeselect.Enabled then
        selectBestCard()
    end
end)
