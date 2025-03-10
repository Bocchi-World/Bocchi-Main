
local player = game.Players.LocalPlayer
local targetPath = player.PlayerGui.DungeonUI.Main.Main.Outer.MainHolder.Outer.LevelSelection.Inset.MainRow

local priorityList = getgenv().Config["Priority Item Join Dungeon"]
local function calculatePartScore(part)
    local score = 0
    local itemsFound = {}
    if part then
        for _, imageLabel in ipairs(part:GetChildren()) do
            if imageLabel:IsA("ImageLabel") and imageLabel.Visible == true then
                local name = imageLabel.Name
                local priority = table.find(priorityList, name)
                
                if priority then
                    local points = #priorityList - priority + 1
                    score = score + points
                    table.insert(itemsFound, name)
                end
            end
        end
    end

    return score, itemsFound
end
local function calculateFrameScore(frame)
    local totalScore = 0
    local totalItemsFound = {}
    local frameTop = frame:FindFirstChild("FrameTop")
    local main = frame:FindFirstChild("Main")
    if frameTop then
        local levelAttributesTop = frameTop:FindFirstChild("Frame"):FindFirstChild("Main")
        if levelAttributesTop then
            local score, itemsFound = calculatePartScore(levelAttributesTop:FindFirstChild("LevelAttributes"))
            totalScore = totalScore + score
            for _, item in ipairs(itemsFound) do
                table.insert(totalItemsFound, item)
            end
        end
    end
    if main then
        local score, itemsFound = calculatePartScore(main:FindFirstChild("LevelAttributes"))
        totalScore = totalScore + score
        for _, item in ipairs(itemsFound) do
            table.insert(totalItemsFound, item)
        end
    end

    return totalScore, totalItemsFound
end
function AutoJoinDungeon()
    local frameData = {}
    local frames = targetPath:GetChildren()
    local frameIndex = 1
    for _, frame in ipairs(frames) do
        if frame:IsA("Frame") and frame.Name == "Frame" then
            local score, itemsFound = calculateFrameScore(frame)
            table.insert(frameData, {
                Index = frameIndex,
                Score = score,
                Items = itemsFound
            })
            
            frameIndex = frameIndex + 1
        end
    end
    table.sort(frameData, function(a, b)
        return a.Score > b.Score
    end)
    
    for _, data in ipairs(frameData) do
        print("Room " .. data.Index .. ": Total Score = " .. data.Score .. ", Item = [" .. table.concat(data.Items, ", ") .. "]")
    end
    local bestFrame = frameData[1]
    if bestFrame then
        local args = {
         [1] = tostring(bestFrame.Index)
        }
    
        game:GetService("ReplicatedStorage").endpoints.client_to_server.dungeon_enter_room:InvokeServer(unpack(args))
    end
end
local targetPlaceId = 8304191830
if game.PlaceId == targetPlaceId then
    AutoJoinDungeon()
else
    local gameFinishedPath = game.Workspace:WaitForChild("_DATA"):WaitForChild("GameFinished")
    if gameFinishedPath and gameFinishedPath:IsA("BoolValue") then
        while true do
            if gameFinishedPath.Value == true then
                task.wait(3)
                AutoJoinDungeon()
                break
            end
            task.wait(1)
        end
    else
        warn("Không tìm thấy GameFinished hoặc không phải là BoolValue.")
    end
end
