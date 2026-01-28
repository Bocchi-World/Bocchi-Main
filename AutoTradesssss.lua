repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local LP = Players.LocalPlayer
local Config = getgenv().Config or {}

local CHANGE_MAIN_AT = tonumber(Config["Change Acc Main When Has Sticker"] or 0)

local StickerTypes = require(RS.Stickers.StickerTypes)
local ClientStatCache = require(RS.ClientStatCache)
local Events = require(RS.Events)

local WROTE_MAIN_FILE = false

-------------------------------------------------
-- DEBUG
-------------------------------------------------
local function log(...)
    print("[AUTO TRADE]", ...)
end

-------------------------------------------------
-- UTILS
-------------------------------------------------
local function normalize(str)
    return tostring(str):lower():gsub("%s+", "")
end

-------------------------------------------------
-- MAIN LIST
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
-- STICKER NAME
-------------------------------------------------
local function getStickerNameById(typeId)
    for name, def in pairs(StickerTypes.Types) do
        if def.ID == typeId then
            return name
        end
    end
    return "Unknown"
end

-------------------------------------------------
-- BOOK
-------------------------------------------------
local function getBook()
    local ok, cache = pcall(function()
        return ClientStatCache:Get()
    end)
    if not ok or not cache then return nil end
    return cache.Stickers and cache.Stickers.Book
end

-------------------------------------------------
-- TRADE GUI
-------------------------------------------------
local function tradeAnchor()
    return LP.PlayerGui:FindFirstChild("ScreenGui")
        and LP.PlayerGui.ScreenGui:FindFirstChild("TradeLayer")
        and LP.PlayerGui.ScreenGui.TradeLayer:FindFirstChild("TradeAnchorFrame", true)
end

local function waitForTradeAnchor(timeout)
    local t0 = tick()
    while true do
        if tradeAnchor() then return true end
        if timeout and tick() - t0 > timeout then
            return false
        end
        task.wait(0.25)
    end
end

-------------------------------------------------
-- VALID STICKERS
-- FIX: SLOT 3 = data[3] (RAW)
-------------------------------------------------
local function getValidStickers(book)
    local list = {}
    if not book then return list end

    for _, data in ipairs(book) do
        local slot1 = data[1]
        local slot2 = data[2]
        local slot3 = data[3]
        local slot4 = data[4]

        local name = getStickerNameById(slot3)

        if Config["Sticker Trade"] then
            for _, cfg in ipairs(Config["Sticker Trade"]) do
                if normalize(cfg) == normalize(name) then
                    table.insert(list, {
                        Name = name,
                        File = {slot1, slot2, slot3, slot4}
                    })
                end
            end
        end
    end

    return list
end

-------------------------------------------------
-- REMOTES
-------------------------------------------------
local function addSticker(sessionId, file)
    local args = {
        [1] = sessionId,
        [2] = {
            ["File"] = {
                [1] = file[1],
                [2] = file[2],
                [3] = file[3],
                [4] = file[4]
            },
            ["Category"] = "Sticker"
        }
    }

    log("ADD STICKER", sessionId, table.concat(file, ", "))
    RS.Events.TradePlayerAddItem:FireServer(unpack(args))
end

local function acceptTrade(sessionId, altId, mainId, packs)
    local args = {
        [1] = sessionId,
        [2] = {
            [tostring(altId)] = packs,
            [tostring(mainId)] = {}
        }
    }

    log("ACCEPT TRADE", sessionId)
    RS.Events.TradePlayerAccept:FireServer(unpack(args))
end

-------------------------------------------------
-- FILE DONE
-------------------------------------------------
local function completed()
    pcall(function()
        writefile(LP.Name .. ".txt", "Completed-DaTrade")
    end)
    log("DONE - NO STICKER LEFT")
end

-------------------------------------------------
-- STICKER COUNT (MAIN)
-------------------------------------------------
local function getStickerSlotCount()
    local book = getBook()
    if not book then return 0 end
    return #book
end

-------------------------------------------------
-- MAIN LOGIC
-------------------------------------------------
local function startMain()
    log("RUNNING AS MAIN")

    Events.ClientListen("TradeInformOfRequest", function(player, sessionId)
        log("INCOMING TRADE FROM", player.Name, "SESSION", sessionId)
        task.wait(0.1)
        Events.ClientCall("TradePlayerConfirmStart", sessionId)

        task.wait(0.2)
        pcall(function()
            game:GetService("TextChatService").TextChannels.RBXGeneral:SendAsync(
                "Session ID: " .. tostring(sessionId)
            )
        end)
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
                    log("MAIN LIMIT REACHED", total)
                end
            end
        end
    end)
end

-------------------------------------------------
-- ALT LOGIC
-------------------------------------------------
local function startAlt()
    log("RUNNING AS ALT")

    local main
    repeat
        main = findMain()
        task.wait(1)
    until main

    log("FOUND MAIN:", main.Name)

    local currentSessionId = nil

    Events.ClientListen("TradeInformOfRequest", function(_, sid)
        currentSessionId = sid
        log("SESSION RECEIVED:", sid)
    end)

    while true do
        local book = getBook()
        local valid = getValidStickers(book)

        if #valid == 0 then
            completed()
            return
        end

        if not tradeAnchor() then
            log("REQUEST TRADE")
            pcall(function()
                RS.Events.TradePlayerRequestStart:FireServer(main.UserId)
            end)
        end

        if not waitForTradeAnchor(20) then
            log("NO TRADE GUI, RETRY")
            task.wait(2)
            continue
        end

        local t0 = tick()
        while not currentSessionId and tradeAnchor() do
            if tick() - t0 > 15 then break end
            task.wait(0.1)
        end

        if not currentSessionId then
            log("NO SESSION, RETRY")
            task.wait(2)
            continue
        end

        local packs = {}
        local idx = 1

        for _, sticker in ipairs(valid) do
            if not tradeAnchor() then
                log("TRADE CLOSED, WAIT MAIN")
                break
            end

            addSticker(currentSessionId, sticker.File)

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
            acceptTrade(currentSessionId, LP.UserId, main.UserId, packs)
        end

        repeat task.wait(0.5) until not tradeAnchor()
        currentSessionId = nil
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
