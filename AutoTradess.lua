repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")

local LP = Players.LocalPlayer
local Config = getgenv().Config or {}

local CHANGE_MAIN_AT = tonumber(Config["Change Acc Main When Has Sticker"] or 0)

local StickerTypes = require(RS.Stickers.StickerTypes)
local ClientStatCache = require(RS.ClientStatCache)
local Events = require(RS.Events)

local WROTE_MAIN_FILE = false
local LAST_CLICK = 0
local CLICK_DELAY = 0.25

local function normalize(str)
    return tostring(str):lower():gsub("%s+", "")
end

local MAIN_LIST = {}

local function pushMain(v)
    if not v then return end
    MAIN_LIST[#MAIN_LIST + 1] = normalize(v)
end

if type(Config["Main Account"]) == "table" then
    for _, v in ipairs(Config["Main Account"]) do
        pushMain(v)
    end
else
    pushMain(Config["Main Account"])
end

local function isMainPlayer(p)
    if not p then return false end
    local uid = normalize(p.UserId)
    local name = normalize(p.Name)
    local dname = normalize(p.DisplayName)
    for _, main in ipairs(MAIN_LIST) do
        if uid == main or name == main or dname == main then
            return true
        end
    end
    return false
end

local function isMain()
    return isMainPlayer(LP)
end

local function findMain()
    for _, p in ipairs(Players:GetPlayers()) do
        if isMainPlayer(p) then
            return p
        end
    end
end

local function fireConnections(signal)
    local ok, conns = pcall(function()
        return getconnections(signal)
    end)
    if not ok or not conns then return end
    for _, c in ipairs(conns) do
        if typeof(c.Function) == "function" then
            pcall(c.Function)
        end
    end
end

local function hardClick(btn)
    if not btn or not btn:IsA("GuiButton") then return end
    if tick() - LAST_CLICK < CLICK_DELAY then return end
    LAST_CLICK = tick()
    pcall(function()
        btn.Visible = true
        btn.Active = true
        btn.AutoButtonColor = true
        local pos = btn.AbsolutePosition + (btn.AbsoluteSize / 2)
        UIS:SetMouseLocation(pos.X, pos.Y)
    end)
    fireConnections(btn.MouseButton1Down)
    fireConnections(btn.MouseButton1Click)
    fireConnections(btn.Activated)
end

local function tradeAnchor()
    return LP.PlayerGui:FindFirstChild("ScreenGui")
        and LP.PlayerGui.ScreenGui:FindFirstChild("TradeLayer")
        and LP.PlayerGui.ScreenGui.TradeLayer:FindFirstChild("TradeAnchorFrame", true)
end

local function waitForTradeAnchor(timeout)
    local t0 = tick()
    while true do
        local anchor = tradeAnchor()
        if anchor then return anchor end
        if timeout and tick() - t0 > timeout then
            return nil
        end
        task.wait(0.25)
    end
end

local function acceptButton(anchor)
    local ok, btn = pcall(function()
        return anchor.TradeFrame.ButtonAccept.ButtonTop
    end)
    if ok then return btn end
end

local function shouldAccept(btn)
    local label = btn:FindFirstChild("TextLabel", true)
    if not label or not label.Text then return false end
    local t = label.Text:lower()
    return t == "accept"
end

local function getStickerNameById(typeId)
    for name, def in pairs(StickerTypes.Types) do
        if def.ID == typeId then
            return name
        end
    end
    return "Unknown"
end

local function getBook()
    local ok, cache = pcall(function()
        return ClientStatCache:Get()
    end)
    if not ok or not cache then return nil end
    return cache.Stickers and cache.Stickers.Book
end

local function getValidStickers(book)
    local list = {}
    if not book then return list end

    for _, data in ipairs(book) do
        local slot1 = data[1]
        local slot2 = data[2]
        local typeId = data.TypeID or data[3]
        local slot4 = data[4]

        local name = getStickerNameById(typeId)
        for _, cfg in ipairs(Config["Sticker Trade"] or {}) do
            if normalize(cfg) == normalize(name) then
                table.insert(list, {
                    Name = name,
                    File = {slot1, slot2, typeId, slot4}
                })
            end
        end
    end

    return list
end

local function completed()
    pcall(function()
        writefile(LP.Name .. ".txt", "Completed-DaTrade")
    end)
end

local function addSticker(sessionId, file)
    RS.Events.TradePlayerAddItem:FireServer(sessionId, {
        File = {
            [1] = file[1],
            [2] = file[2],
            [3] = file[3],
            [4] = file[4]
        },
        Category = "Sticker"
    })
end

local function acceptTrade(sessionId, altId, mainId, packs)
    RS.Events.TradePlayerAccept:FireServer(sessionId, {
        [tostring(altId)] = packs,
        [tostring(mainId)] = {}
    })
end

local function getStickerSlotCount()
    local book = getBook()
    if not book then return 0 end
    return #book
end

local function startMain()
    Events.ClientListen("TradeInformOfRequest", function(player, sessionId)
        task.wait(0.1)
        Events.ClientCall("TradePlayerConfirmStart", sessionId)
    end)

    task.spawn(function()
        while true do
            local anchor = tradeAnchor()
            if anchor then
                local btn = acceptButton(anchor)
                if btn and shouldAccept(btn) then
                    hardClick(btn)
                end
            end
            task.wait(0.25)
        end
    end)

    task.spawn(function()
        while true do
            task.wait(2)
            if CHANGE_MAIN_AT > 0 and not WROTE_MAIN_FILE then
                local total = getStickerSlotCount()
                if total >= CHANGE_MAIN_AT then
                    WROTE_MAIN_FILE = true
                    pcall(function()
                        writefile(LP.Name .. ".txt", "Completed-MainAutoTrade")
                    end)
                end
            end
        end
    end)
end

local function startAlt()
    local main
    repeat
        main = findMain()
        task.wait(1)
    until main

    while true do
        local book = getBook()
        local valid = getValidStickers(book)

        if #valid == 0 then
            completed()
            return
        end

        pcall(function()
            RS.Events.TradePlayerRequestStart:FireServer(main.UserId)
        end)

        local anchor = waitForTradeAnchor(30)
        if not anchor then
            task.wait(2)
            continue
        end

        local sessionId
        local conn = Events.ClientListen("TradeInformOfRequest", function(_, sid)
            sessionId = sid
        end)

        local t0 = tick()
        while tradeAnchor() and not sessionId do
            if tick() - t0 > 15 then break end
            task.wait(0.1)
        end

        if conn then conn:Disconnect() end
        if not sessionId then
            task.wait(2)
            continue
        end

        local packs = {}
        local idx = 1

        for _, sticker in ipairs(valid) do
            while not tradeAnchor() do
                task.wait(1)
                main = findMain()
                if main then
                    pcall(function()
                        RS.Events.TradePlayerRequestStart:FireServer(main.UserId)
                    end)
                end
            end

            addSticker(sessionId, sticker.File)

            packs[idx] = {
                Pack = {
                    File = {
                        [1] = sticker.File[1],
                        [2] = sticker.File[2],
                        [3] = sticker.File[3],
                        [4] = sticker.File[4]
                    },
                    Category = "Sticker"
                },
                Validated = false,
                Owner = tostring(LP.UserId),
                IDString = "U" .. LP.UserId .. ":Sticker:" .. table.concat(sticker.File, "-"),
                ClientSide = true
            }

            idx += 1
            task.wait(0.15)
        end

        if tradeAnchor() and #packs > 0 then
            task.wait(0.3)
            acceptTrade(sessionId, LP.UserId, main.UserId, packs)
        end

        repeat task.wait(0.5) until not tradeAnchor()
        task.wait(2)
    end
end

task.spawn(function()
    if isMain() then
        startMain()
    else
        startAlt()
    end
end)
