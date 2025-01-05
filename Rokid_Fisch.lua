local Identifier = "jgtoolrobloxrejoin"
local RequestFunc = (syn and syn.request) or request or http_request
local PlayerService = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserID = PlayerService.LocalPlayer.UserId
local FileSys = loadstring(game:HttpGet("https://raw.githubusercontent.com/AhmadV99/Main/main/Library/File_System.lua"))()
local filePath = "JGHub/.key.json"
FileSys:GetFolder("JGHub")

local function extractNumber(value)
    local strValue = tostring(value):gsub(",", ""):gsub("[^%d]", "")
    return tonumber(strValue)
end

local function checkLeaderstats(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        warn("Leaderstats không tồn tại cho player:", player.Name)
        return false
    end

    local money = leaderstats:FindFirstChild("C$")
    local level = leaderstats:FindFirstChild("Level")

    if not money then
        warn("C$ không tồn tại trong leaderstats của player:", player.Name)
        return false
    end
    if not level then
        warn("Level không tồn tại trong leaderstats của player:", player.Name)
        return false
    end

    local moneyValue = extractNumber(money.Value)
    local levelValue = tonumber(level.Value) or 0

    return moneyValue >= getgenv().Player.Money and levelValue >= getgenv().Player.Level
end

local function checkRods(player)
    local playerstats = game:GetService("ReplicatedStorage"):FindFirstChild("playerstats")
    if not playerstats then return false end

    local playerFolder = playerstats:FindFirstChild(player.Name)
    if not playerFolder then return false end

    local rodsFolder = playerFolder:FindFirstChild("Rods")
    if not rodsFolder then return false end

    for _, itemName in ipairs(getgenv().Item) do
        if not rodsFolder:FindFirstChild(itemName) then
            return false
        end
    end

    return true
end

local player = game:GetService("Players").LocalPlayer

print("[Auto Change Acc Fisch - Rokid]")
print("--------")
print("[JG Hub] Check success ✅")
print("--------")
print("[JG Hub] Made by Jung Ganmyeon")
print("[Rokid] discord.gg/rokidmanager")
print("[Bocchi World] discord.gg/WjVdnrEq")
print("--------")

spawn(function()
    local accChecked = false
    while true do
        wait(5)
        if checkLeaderstats(player) and checkRods(player) then
            if not accChecked then
                request({
                    Url = 'http://localhost:5000/api/changeacc',
                    Method = 'POST',
                    Headers = { ['content-type'] = 'application/json' },
                    Body = HttpService:JSONEncode({ ['id'] = tostring(player.UserId) })
                })
                accChecked = true
            end
        else
            accChecked = false
        end
    end
end)
