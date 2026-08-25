-- [[ GROW A GARDEN TELEMETRY TRACKER SCRIPT - EMORIMA Ecosystem ]] --
-- Universal Auto-Execute Script for Solara, Wave, Codex, Delta, Fluxus, Hydrogen, Synapse, etc.

local secretKey = getgenv().TRACKSTATS_KEY or getgenv().EMORIMA_KEY or getgenv().SECRET_KEY or "32char_secret_key_here"

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local API_URL = "https://qnguyen36.vercel.app/api/api_grow_garden"

local function request_http(req)
    if syn and syn.request then return syn.request(req)
    elseif http and http.request then return http.request(req)
    elseif http_request then return http_request(req)
    elseif fluxus and fluxus.request then return fluxus.request(req)
    elseif request then return request(req) end
    return nil
end

local function cleanNumber(val)
    if type(val) == "number" then return val end
    if type(val) == "string" then
        local s = string.gsub(val, "[%$,%s]", "")
        local numStr, mult = string.match(s, "([%d%.]+)([KkMmBb]?)")
        if numStr then
            local n = tonumber(numStr) or 0
            if mult == "K" or mult == "k" then return n * 1000 end
            if mult == "M" or mult == "m" then return n * 1000000 end
            if mult == "B" or mult == "b" then return n * 1000000000 end
            return n
        end
    end
    return 0
end

local function detectSheckles()
    local targetNames = {"Sheckles", "Sheckle", "Money", "Coins", "Cash", "Balance", "Gold"}
    
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        for _, name in ipairs(targetNames) do
            local stat = leaderstats:FindFirstChild(name)
            if stat then
                local num = cleanNumber(stat.Value)
                if num > 0 then return num, "leaderstats." .. name end
            end
        end
    end

    for _, name in ipairs(targetNames) do
        local child = LocalPlayer:FindFirstChild(name)
        if child then
            local num = cleanNumber(child.Value)
            if num > 0 then return num, "LocalPlayer." .. name end
        end
    end

    for _, folderName in ipairs({"Data", "PlayerData", "Inventory", "Stats"}) do
        local folder = LocalPlayer:FindFirstChild(folderName)
        if folder then
            for _, name in ipairs(targetNames) do
                local child = folder:FindFirstChild(name)
                if child then
                    local num = cleanNumber(child.Value)
                    if num > 0 then return num, "LocalPlayer." .. folderName .. "." .. name end
                end
            end
        end
    end

    local pgui = LocalPlayer:FindFirstChild("PlayerGui")
    if pgui then
        for _, gui in ipairs(pgui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Enabled then
                for _, desc in ipairs(gui:GetDescendants()) do
                    if desc:IsA("TextLabel") and desc.Visible then
                        local txt = desc.Text or ""
                        if string.find(txt, "%$") or string.find(string.lower(txt), "sheckle") then
                            local num = cleanNumber(txt)
                            if num > 0 then return num, "PlayerGui." .. desc.Name end
                        end
                    end
                end
            end
        end
    end

    return 0, "Default (0)"
end

local function sendTelemetry()
    local sheckles, shecklesSource = detectSheckles()
    local payload = {
        secret_key = secretKey,
        stats = {
            roblox_username = LocalPlayer.Name,
            roblox_user_id = LocalPlayer.UserId,
            sheckles = sheckles,
            sheckles_source = shecklesSource,
            garden_level = 1,
            weather = "Clear Sky"
        }
    }

    local res = request_http({
        Url = API_URL,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode(payload)
    })

    if res and (res.StatusCode == 200 or res.StatusDescription == "OK") then
        print("[Emorima Sync] Success! Sheckles: $" .. tostring(sheckles) .. " (From: " .. tostring(shecklesSource) .. ") | Key: " .. tostring(secretKey))
    else
        warn("[Emorima Sync] Failed! Response:", res and res.StatusCode or "No Response")
    end
end

task.spawn(function()
    print("🌿 EMORIMA GROW A GARDEN TRACKER LOADED 🌿")
    while true do
        pcall(sendTelemetry)
        task.wait(10)
    end
end)
