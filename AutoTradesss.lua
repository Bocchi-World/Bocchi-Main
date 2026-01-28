repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local LP = Players.LocalPlayer
local Config = getgenv().Config or {}

local CHANGE_MAIN_AT = tonumber(Config["Change Acc Main When Has Sticker"] or 0)

local StickerTypes = require(RS.Stickers.StickerTypes)
local ClientStatCache = require(RS.ClientStatCache)
local Events = require(RS.Events)

local DEBUG = true
local WROTE_MAIN_FILE = false

local function dprint(...)
    if DEBUG then
        print("[AUTO-TRADE]", ...)
    end
end

-------------------------------------------------
-- UTILS
-------------------------------------------------
local function normalize(str)
    return tostring(str):lower():gsub("%s+", "")
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

-------------------------------------------------
-- MAIN DETECT
-------------------------------------------------
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

-------------------------------------------------
-- STICKER HELPERS
-------------------------------------------------
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

        if Config["Sticker Trade"] then
            for _, cfg in ipairs(Config["Sticker Trade"]) do
                if normalize(cfg) == normalize(name) then
                    table.insert(list, {
                        Name = name,
                        File = {slot1, slot2, typeId, slot4}
                    })
                    break
                end
            end
        end
    end

    return list
end

local function getStickerSlotCount()
    local book = getBook()
    if not book then return 0 end
    return #book
end

-------------------------------------------------
-- REMOTES
-------------------------------------------------
local function getRemote(name)
    local ev = RS:FindFirstChild("Events", true)
        and RS.Events:FindFirstChild(name, true)
    if not ev then
        dprint("Missing remote:", name)
    end
    return ev
end

local function addSticker(sessionId, file)
    local ev = getRemote("TradePlayerAddItem")
    if not ev then return end

    dprint("ALT -> ADD", sessionId, table.concat(file, ","))

    ev:FireServer(sessionId, {
        ["File"] = {
            [1] = file[1],
            [2] = file[2],
            [3] = file[3],
            [4] = file[4]
        },
        ["Category"] = "Sticker"
    })
end

local function acceptTrade(sessionId, altId, mainId, packs)
    local ev = getRemote("TradePlayerAccept")
    if not ev then return end

    dprint("ALT -> ACCEPT", sessionId, "Packs:", #packs)

    ev:FireServer(sessionId, {
        [tostring(altId)] = packs,
        [tostring(mainId)] = {}
    })
end

-------------------------------------------------
-- SESSION FIX
-------------------------------------------------
local function waitForSessionId(timeout)
    local sessionId
    local conn

    conn = Events.ClientListen("TradePlayerConfirmStart", function(sid)
        sessionId = sid
        dprint("ALT got sessionId:", sid)
    end)

    local t0 = tick()
    while tradeAnchor() and not sessionId do
        if timeout and tick() - t0 > timeout then
            break
        end
        task.wait(0.1)
    end

    if conn then conn:Disconnect() end
    return sessionId
end

-------------------------------------------------
-- FILE
-------------------------------------------------
local function completed(tag)
    pcall(function()
        writefile(LP.Name .. ".txt", tag or "Completed-DaTrade")
    end)
end

-------------------------------------------------
-- MAIN LOGIC
-------------------------------------------------
local function startMain()
    dprint("Running as MAIN")

    Events.ClientListen("TradeInformOfRequest", function(player, sessionId)
        dprint("Incoming trade from", player.Name, "Session:", sessionId)
        task.wait(0.1)
        Events.ClientCall("TradePlayerConfirmStart", sessionId)
        dprint("MAIN -> ConfirmStart", sessionId)
    end)

    task.spawn(function()
        while true do
            task.wait(0.25)

            local anchor = tradeAnchor()
            if anchor then
                local ok, btn = pcall(function()
                    return anchor.TradeFrame.ButtonAccept.ButtonTop
                end)

                if ok and btn and btn.Visible then
                    pcall(function()
                        firesignal(btn.MouseButton1Click)
                        firesignal(btn.Activated)
                        dprint("MAIN -> Click Accept")
                    end)
                end
            end

            if CHANGE_MAIN_AT > 0 and not WROTE_MAIN_FILE then
                local total = getStickerSlotCount()
                if total >= CHANGE_MAIN_AT then
                    WROTE_MAIN_FILE = true
                    completed("Completed-MainAutoTrade")
                    dprint("MAIN completed at", total)
                end
            end
        end
    end)
end

-------------------------------------------------
-- ALT LOGIC
-------------------------------------------------
local function startAlt()
    dprint("Running as ALT")

    local main
    repeat
        main = findMain()
        task.wait(1)
    until main

    dprint("Found MAIN:", main.Name, main.UserId)

    while true do
        local book = getBook()
        local valid = getValidStickers(book)

        if #valid == 0 then
            dprint("No stickers left, completed")
            completed("Completed-DaTrade")
            return
        end

        dprint("Request trade to MAIN")
        pcall(function()
            RS.Events.TradePlayerRequestStart:FireServer(main.UserId)
        end)

        local anchor = waitForTradeAnchor(30)
        if not anchor then
            dprint("Trade UI timeout, retry")
            task.wait(2)
            continue
        end

        local sessionId = waitForSessionId(20)
        if not sessionId then
            dprint("No sessionId, retry trade")
            task.wait(2)
            continue
        end

        local packs = {}
        local idx = 1

        for _, sticker in ipairs(valid) do
            if not tradeAnchor() then
                dprint("Trade closed while adding, break")
                break
            end

            addSticker(sessionId, sticker.File)

            packs[idx] = {
                ["Pack"] = {
                    ["File"] = {
                        [1] = sticker.File[1],
                        [2] = sticker.File[2],
                        [3] = sticker.File[3],
                        [4] = sticker.File[4]
                    },
                    ["Category"] = "Sticker"
                },
                ["Validated"] = false,
                ["Owner"] = tostring(LP.UserId),
                ["IDString"] = "U" .. LP.UserId .. ":Sticker:" ..
                    table.concat(sticker.File, "-"),
                ["ClientSide"] = true
            }

            idx += 1
            task.wait(0.15)
        end

        if tradeAnchor() and #packs > 0 then
            task.wait(0.3)
            acceptTrade(sessionId, LP.UserId, main.UserId, packs)
        end

        repeat task.wait(0.5) until not tradeAnchor()
        dprint("Trade ended, retry loop")
        task.wait(2)
    end
end

-------------------------------------------------
-- START
-------------------------------------------------
task.spawn(function()
    if isMain() then
        startMain()
    else
        startAlt()
    end
end)
