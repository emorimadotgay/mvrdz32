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
    local httpReq = {
        Url = req.Url or req.url,
        url = req.Url or req.url,
        Method = req.Method or req.method or "POST",
        method = req.Method or req.method or "POST",
        Headers = req.Headers or req.headers or { ["Content-Type"] = "application/json" },
        headers = req.Headers or req.headers or { ["Content-Type"] = "application/json" },
        Body = req.Body or req.body,
        body = req.Body or req.body
    }

    local fn = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
    if fn then return fn(httpReq) end
    return nil
end

-- Clean string or number into actual Sheckles count
local function cleanNumber(val)
    if type(val) == "number" then return val end
    if type(val) == "string" then
        -- Handle K, M, B, T, Qi suffixes (e.g. 452.9M -> 452900000)
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

-- Parse Roblox leaderstat string with Flower icon 🌸 (e.g. "1 🌸 452.9M" or "1🌸452.9B")
local function parseFlowerString(val)
    if type(val) == "number" then return val, nil end
    if type(val) ~= "string" then return 0, nil end

    -- Match level before icon and sheckles after icon (e.g. "1 🌸 452.9M")
    local lvlStr, shStr = string.match(val, "^(%d+)%s*[^%w%s%d]+%s*([%d%.]+%s*[KkMmBbQqTt]?)")
    if lvlStr and shStr then
        local lvl = tonumber(lvlStr) or 1
        local sh = cleanNumber(shStr)
        return sh, lvl
    end

    -- Match icon followed by sheckles (e.g. "🌸 452.9M")
    local shOnly = string.match(val, "[^%w%s%d]+%s*([%d%.]+%s*[KkMmBbQqTt]?)")
    if shOnly then
        return cleanNumber(shOnly), nil
    end

    return cleanNumber(val), nil
end

-- Deep Multi-Source Scanner for Sheckles & Level
local function detectShecklesAndLevel()
    local targetNames = {"Sheckles", "Sheckle", "Money", "Coins", "Cash", "Balance", "Gold", "Currency"}
    
    -- 1. Check leaderstats
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        -- First check if any leaderstat contains flower icon 🌸 (like "1 🌸 452.9M")
        for _, child in ipairs(leaderstats:GetChildren()) do
            local txt = tostring(child.Value)
            if string.find(txt, "🌸") or string.find(child.Name, "🌸") then
                local sh, lvl = parseFlowerString(txt)
                if sh > 0 then
                    return sh, lvl or 1, "leaderstats." .. child.Name
                end
            end
        end

        for _, name in ipairs(targetNames) do
            local stat = leaderstats:FindFirstChild(name)
            if stat then
                local sh, lvl = parseFlowerString(stat.Value)
                if sh > 0 then return sh, lvl or 1, "leaderstats." .. name end
            end
        end
    end

    -- 2. Check direct children of LocalPlayer
    for _, name in ipairs(targetNames) do
        local child = LocalPlayer:FindFirstChild(name)
        if child then
            local sh, lvl = parseFlowerString(child.Value)
            if sh > 0 then return sh, lvl or 1, "LocalPlayer." .. name end
        end
    end

    -- 3. Check Data / PlayerData / Inventory under LocalPlayer
    for _, folderName in ipairs({"Data", "PlayerData", "Inventory", "Stats", "PlayerStats"}) do
        local folder = LocalPlayer:FindFirstChild(folderName)
        if folder then
            for _, name in ipairs(targetNames) do
                local child = folder:FindFirstChild(name)
                if child then
                    local sh, lvl = parseFlowerString(child.Value)
                    if sh > 0 then return sh, lvl or 1, "LocalPlayer." .. folderName .. "." .. name end
                end
            end
        end
    end

    -- 4. Check ReplicatedStorage Data Folders
    for _, repName in ipairs({"PlayerData", "Data", "PlayerStats", "Profiles"}) do
        local repFolder = ReplicatedStorage:FindFirstChild(repName)
        if repFolder then
            local pData = repFolder:FindFirstChild(LocalPlayer.Name) or repFolder:FindFirstChild(tostring(LocalPlayer.UserId))
            if pData then
                for _, name in ipairs(targetNames) do
                    local child = pData:FindFirstChild(name)
                    if child then
                        local sh, lvl = parseFlowerString(child.Value)
                        if sh > 0 then return sh, lvl or 1, "ReplicatedStorage." .. repName .. "." .. name end
                    end
                end
            end
        end
    end

    -- 5. Fallback: Scan PlayerGui Labels for 🌸, $, or Sheckles text
    local pgui = LocalPlayer:FindFirstChild("PlayerGui")
    if pgui then
        for _, gui in ipairs(pgui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Enabled then
                for _, desc in ipairs(gui:GetDescendants()) do
                    if desc:IsA("TextLabel") and desc.Visible then
                        local txt = desc.Text or ""
                        if string.find(txt, "🌸") or string.find(txt, "%$") or string.find(string.lower(txt), "sheckle") then
                            local sh, lvl = parseFlowerString(txt)
                            if sh > 0 then return sh, lvl or 1, "PlayerGui." .. desc.Name end
                        end
                    end
                end
            end
        end
    end

    return 0, 1, "Default (0)"
end

-- Deep Weather Scanner
local function detectWeather()
    local weatherFolder = workspace:FindFirstChild("Weather") or workspace:FindFirstChild("Environment") or Lighting:FindFirstChild("Weather") or workspace:FindFirstChild("CurrentWeather") or ReplicatedStorage:FindFirstChild("Weather")
    if weatherFolder then
        if weatherFolder:IsA("StringValue") then
            return weatherFolder.Value
        elseif weatherFolder:FindFirstChild("Current") then
            return tostring(weatherFolder.Current.Value)
        else
            return weatherFolder.Name
        end
    end
    return "Clear Sky"
end

-- Deep Inventory / Farm Collector
local function getGardenData()
    local sheckles, gardenLevel, shecklesSource = detectShecklesAndLevel()

    -- Rebirths
    local rebirths = 0
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats and leaderstats:FindFirstChild("Rebirths") then
        rebirths = cleanNumber(leaderstats.Rebirths.Value)
    end

    -- Inventory collection
    local petsList = {}
    local cropsList = {}
    local seedsList = {}
    local toolsList = {}
    local sprinklersList = {}
    local mutationsList = {}

    local function scanFolder(parent)
        if not parent then return end
        for _, child in ipairs(parent:GetChildren()) do
            local name = child.Name
            local lowerName = string.lower(name)

            if string.find(lowerName, "pet") or parent.Name == "Pets" then
                table.insert(petsList, name)
            elseif string.find(lowerName, "seed") or parent.Name == "Seeds" then
                table.insert(seedsList, name)
            elseif string.find(lowerName, "fruit") or string.find(lowerName, "crop") or parent.Name == "Crops" then
                table.insert(cropsList, name)
            elseif string.find(lowerName, "sprinkler") then
                table.insert(sprinklersList, name)
            elseif string.find(lowerName, "mut") or string.find(lowerName, "gold") or string.find(lowerName, "rainbow") then
                table.insert(mutationsList, name)
            else
                table.insert(toolsList, name)
            end
        end
    end

    local playerData = LocalPlayer:FindFirstChild("Data") or LocalPlayer:FindFirstChild("Inventory") or LocalPlayer:FindFirstChild("PlayerData")
    if playerData then
        scanFolder(playerData:FindFirstChild("Pets"))
        scanFolder(playerData:FindFirstChild("Crops"))
        scanFolder(playerData:FindFirstChild("Seeds"))
        scanFolder(playerData:FindFirstChild("Tools"))
    end

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        scanFolder(backpack)
    end

    -- Unlocked Plots Count
    local plotsCount = 4
    local plotsFolder = workspace:FindFirstChild("Plots") or workspace:FindFirstChild("GardenPlots") or workspace:FindFirstChild("Farms")
    if plotsFolder then
        local count = 0
        for _, pl in ipairs(plotsFolder:GetChildren()) do
            local owner = pl:FindFirstChild("Owner") or pl:FindFirstChild("Player")
            if owner and (owner.Value == LocalPlayer or tostring(owner.Value) == LocalPlayer.Name) then
                count = count + 1
            end
        end
        if count > 0 then plotsCount = count end
    end

    -- Rare items boolean flags
    local hasAether = false
    local hasDragon = false
    local hasPeach = false
    local hasTrinity = false
    local hasCelestiberry = false
    local hasDiscoBee = false
    local hasGoose = false
    local hasRainbowSeed = false

    for _, c in ipairs(cropsList) do
        local lc = string.lower(c)
        if string.find(lc, "aether") then hasAether = true end
        if string.find(lc, "dragon") then hasDragon = true end
        if string.find(lc, "peach") then hasPeach = true end
        if string.find(lc, "trinity") then hasTrinity = true end
        if string.find(lc, "celesti") then hasCelestiberry = true end
        if string.find(lc, "rainbow") then hasRainbowSeed = true end
    end

    for _, p in ipairs(petsList) do
        local lp = string.lower(p)
        if string.find(lp, "disco") then hasDiscoBee = true end
        if string.find(lp, "goose") then hasGoose = true end
    end

    return {
        secret_key = secretKey,
        stats = {
            roblox_username = LocalPlayer.Name,
            roblox_user_id = LocalPlayer.UserId,
            sheckles = sheckles,
            sheckles_source = shecklesSource,
            garden_level = gardenLevel,
            rebirths = rebirths,
            unlocked_plots = plotsCount,
            weather = detectWeather(),
            pets = petsList,
            crops = cropsList,
            seeds = seedsList,
            tools = toolsList,
            sprinklers = sprinklersList,
            mutations = mutationsList,
            has_aetherfruit = hasAether,
            has_dragon_fruit = hasDragon,
            has_golden_peach = hasPeach,
            has_trinity_fruit = hasTrinity,
            has_celestiberry = hasCelestiberry,
            has_disco_bee = hasDiscoBee,
            has_golden_goose = hasGoose,
            has_rainbow_seed = hasRainbowSeed,
        }
    }
end

local function sendTelemetry()
    local payload = getGardenData()
    local jsonStr = HttpService:JSONEncode(payload)

    local res = request_http({
        Url = API_URL,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = jsonStr
    })

    if res and (res.StatusCode == 200 or res.StatusDescription == "OK") then
        print("[Emorima Sync] Success! Sheckles: $" .. tostring(payload.stats.sheckles) .. " | LVL: " .. tostring(payload.stats.garden_level) .. " | Key: " .. tostring(secretKey))
    else
        warn("[Emorima Sync] Telemetry send failed:", res and res.StatusCode or "No Response")
    end
end

-- Run immediate & Loop every 10 seconds
task.spawn(function()
    print("========================================")
    print("🌿 EMORIMA GROW A GARDEN TRACKER LOADED 🌿")
    print("Player: " .. tostring(LocalPlayer.Name))
    print("Key:    " .. tostring(secretKey))
    print("========================================")
    while true do
        pcall(sendTelemetry)
        task.wait(10)
    end
end)
