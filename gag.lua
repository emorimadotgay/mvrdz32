-- [[ GROW A GARDEN TELEMETRY TRACKER SCRIPT - EMORIMA Ecosystem ]] --
local secretKey = getgenv().TRACKSTATS_KEY or getgenv().EMORIMA_KEY or getgenv().SECRET_KEY or "32char_secret_key_here"

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local API_URL = "https://qnguyen36.vercel.app/api/api_grow_garden"

local function request_http(req)
    local httpReq = {
        Url = req.Url or req.url, url = req.Url or req.url,
        Method = req.Method or req.method or "POST", method = req.Method or req.method or "POST",
        Headers = req.Headers or req.headers or { ["Content-Type"] = "application/json" },
        headers = req.Headers or req.headers or { ["Content-Type"] = "application/json" },
        Body = req.Body or req.body, body = req.Body or req.body
    }
    local fn = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
    if fn then return fn(httpReq) end
    return nil
end

local function cleanNumber(val)
    if type(val) == "number" then return val end
    if type(val) == "string" then
        local numStr, mult = string.match(val, "([%d%.]+)%s*([KkMmBbQqTt]?)")
        if numStr then
            local n = tonumber(numStr) or 0
            if mult == "K" or mult == "k" then return n * 1000 end
            if mult == "M" or mult == "m" then return n * 1000000 end
            if mult == "B" or mult == "b" then return n * 1000000000 end
            if mult == "T" or mult == "t" then return n * 1000000000000 end
            if mult == "Q" or mult == "q" or mult == "Qi" or mult == "qi" then return n * 1000000000000000 end
            return n
        end
    end
    return 0
end

local function parseFlowerString(val)
    if type(val) == "number" then return val, nil end
    if type(val) ~= "string" then return 0, nil end
    local lvlStr, shStr = string.match(val, "^(%d+)%s*[^%w%s%d]+%s*([%d%.]+%s*[KkMmBbQqTt]?)")
    if lvlStr and shStr then return cleanNumber(shStr), tonumber(lvlStr) or 1 end
    local shOnly = string.match(val, "[^%w%s%d]+%s*([%d%.]+%s*[KkMmBbQqTt]?)")
    if shOnly then return cleanNumber(shOnly), nil end
    return cleanNumber(val), nil
end

local function isLevelName(name)
    local lower = string.lower(name)
    return string.find(lower, "level") ~= nil or string.find(lower, "lvl") ~= nil or string.find(lower, "rebirth") ~= nil
end

local function isSheckleName(name)
    local lower = string.lower(name)
    return string.find(lower, "sheckle") ~= nil or string.find(lower, "money") ~= nil or string.find(lower, "coin") ~= nil or string.find(lower, "cash") ~= nil or string.find(lower, "balance") ~= nil or string.find(lower, "gold") ~= nil
end

local function fullGardenScan()
    local sheckles = 0
    local gardenLevel = 1
    local shecklesSource = "Default"
    local debugLog = {}

    -- 1. Scan leaderstats (Phân biệt rõ Level & Sheckles)
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        for _, child in ipairs(leaderstats:GetChildren()) do
            local name = child.Name
            local valStr = tostring(child.Value)
            table.insert(debugLog, "leaderstats." .. name .. " = " .. valStr)

            if isLevelName(name) then
                local lvl = cleanNumber(valStr)
                if lvl > 0 then gardenLevel = lvl end
            elseif isSheckleName(name) then
                local sh = parseFlowerString(valStr)
                if sh > 0 then sheckles = sh; shecklesSource = "leaderstats." .. name end
            elseif string.find(valStr, "🌸") then
                local sh, lvl = parseFlowerString(valStr)
                if sh and sh > 0 then sheckles = sh; shecklesSource = "leaderstats." .. name end
                if lvl and lvl > 0 then gardenLevel = lvl end
            end
        end
    end

    -- 2. Scan LocalPlayer Data Folders
    for _, folderName in ipairs({"Data", "PlayerData", "Inventory", "Stats", "PlayerStats", "Values", "SaveData"}) do
        local folder = LocalPlayer:FindFirstChild(folderName)
        if folder then
            for _, child in ipairs(folder:GetChildren()) do
                if child:IsA("ValueBase") then
                    local name = child.Name
                    local valStr = tostring(child.Value)
                    table.insert(debugLog, folderName .. "." .. name .. " = " .. valStr)

                    if isLevelName(name) then
                        local lvl = cleanNumber(valStr)
                        if lvl > 0 then gardenLevel = lvl end
                    elseif isSheckleName(name) then
                        local sh = cleanNumber(valStr)
                        if sh > sheckles then sheckles = sh; shecklesSource = folderName .. "." .. name end
                    end
                end
            end
        end
    end

    -- 3. Scan PlayerGui TextLabels (Nếu chưa tìm thấy Sheckles)
    if sheckles == 0 then
        local pgui = LocalPlayer:FindFirstChild("PlayerGui")
        if pgui then
            for _, gui in ipairs(pgui:GetChildren()) do
                if gui:IsA("ScreenGui") and gui.Enabled then
                    for _, desc in ipairs(gui:GetDescendants()) do
                        if desc:IsA("TextLabel") and desc.Visible then
                            local txt = desc.Text or ""
                            local lowerText = string.lower(txt)
                            local lowerName = string.lower(desc.Name)
                            if not isLevelName(lowerName) and not isLevelName(lowerText) then
                                if string.find(txt, "🌸") or string.find(txt, "%$") or string.find(lowerText, "sheckle") or string.find(lowerName, "sheckle") then
                                    table.insert(debugLog, "PlayerGui." .. desc.Name .. " = " .. txt)
                                    local sh = cleanNumber(txt)
                                    if sh > sheckles then sheckles = sh; shecklesSource = "PlayerGui." .. desc.Name end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return {
        secret_key = secretKey,
        stats = {
            roblox_username = LocalPlayer.Name,
            roblox_user_id = LocalPlayer.UserId,
            sheckles = sheckles,
            sheckles_source = shecklesSource,
            garden_level = gardenLevel,
            debug_log = debugLog
        }
    }
end

local function sendTelemetry()
    local payload = fullGardenScan()
    local res = request_http({
        Url = API_URL, Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode(payload)
    })
    if res and (res.StatusCode == 200 or res.StatusDescription == "OK") then
        print("[Emorima Sync] Telemetry synced! Sheckles: $" .. tostring(payload.stats.sheckles))
    end
end

task.spawn(function()
    print("🌿 EMORIMA GROW A GARDEN TRACKER LOADED 🌿")
    while true do
        pcall(sendTelemetry)
        task.wait(10)
    end
end)
