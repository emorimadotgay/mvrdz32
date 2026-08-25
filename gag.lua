-- [[ GROW A GARDEN TELEMETRY TRACKER SCRIPT - EMORIMA Ecosystem ]] --
-- Universal Auto-Execute Script for Solara, Wave, Codex, Delta, Fluxus, Hydrogen, Synapse, etc.

local secretKey = getgenv().TRACKSTATS_KEY or getgenv().EMORIMA_KEY or getgenv().SECRET_KEY or "32char_secret_key_here"

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

local API_URL = "https://qnguyen36.vercel.app/api/api_grow_garden"

local function request_http(req)
    if syn and syn.request then
        return syn.request(req)
    elseif http and http.request then
        return http.request(req)
    elseif http_request then
        return http_request(req)
    elseif fluxus and fluxus.request then
        return fluxus.request(req)
    elseif request then
        return request(req)
    end
    return nil
end

local function safeGetLeaderstat(names, defaultVal)
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        for _, n in ipairs(names) do
            local stat = leaderstats:FindFirstChild(n)
            if stat then return tonumber(stat.Value) or defaultVal end
        end
    end
    return defaultVal
end

local function getGardenData()
    -- Read Money / Sheckles
    local sheckles = safeGetLeaderstat({"Sheckles", "Money", "Coins", "Cash"}, 0)

    -- Read Level & Rebirths
    local gardenLevel = safeGetLeaderstat({"Level", "GardenLevel", "LVL"}, 1)
    local rebirths = safeGetLeaderstat({"Rebirths", "Rebirth"}, 0)

    -- Collect Pets, Seeds, Fruits, Tools, Sprinklers
    local petsList = {}
    local cropsList = {}
    local seedsList = {}
    local toolsList = {}
    local sprinklersList = {}
    local mutationsList = {}

    local playerData = LocalPlayer:FindFirstChild("Data") or LocalPlayer:FindFirstChild("Inventory") or LocalPlayer:FindFirstChild("PlayerData")
    if playerData then
        -- Pets
        local pets = playerData:FindFirstChild("Pets")
        if pets then
            for _, p in ipairs(pets:GetChildren()) do
                table.insert(petsList, p.Name)
            end
        end

        -- Seeds / Crops
        local crops = playerData:FindFirstChild("Crops") or playerData:FindFirstChild("Seeds") or playerData:FindFirstChild("Items")
        if crops then
            for _, c in ipairs(crops:GetChildren()) do
                table.insert(cropsList, c.Name)
            end
        end

        -- Tools / Sprinklers
        local tools = playerData:FindFirstChild("Tools") or playerData:FindFirstChild("Structures")
        if tools then
            for _, t in ipairs(tools:GetChildren()) do
                if string.find(string.lower(t.Name), "sprinkler") then
                    table.insert(sprinklersList, t.Name)
                else
                    table.insert(toolsList, t.Name)
                end
            end
        end
    end

    -- Check Backpack
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if string.find(string.lower(item.Name), "sprinkler") then
                if not table.find(sprinklersList, item.Name) then
                    table.insert(sprinklersList, item.Name)
                end
            elseif not table.find(toolsList, item.Name) then
                table.insert(toolsList, item.Name)
            end
        end
    end

    -- Server Weather Detection
    local serverWeather = "Clear Sky"
    local weatherFolder = workspace:FindFirstChild("Weather") or workspace:FindFirstChild("Environment") or Lighting:FindFirstChild("Weather") or workspace:FindFirstChild("CurrentWeather")
    if weatherFolder then
        if weatherFolder:IsA("StringValue") then
            serverWeather = weatherFolder.Value
        elseif weatherFolder:FindFirstChild("Current") then
            serverWeather = tostring(weatherFolder.Current.Value)
        else
            serverWeather = weatherFolder.Name
        end
    end

    -- Unlocked Plots Count
    local plotsCount = 4
    local plotsFolder = workspace:FindFirstChild("Plots") or workspace:FindFirstChild("GardenPlots") or workspace:FindFirstChild("Farms")
    if plotsFolder then
        local userPlots = 0
        for _, pl in ipairs(plotsFolder:GetChildren()) do
            local owner = pl:FindFirstChild("Owner") or pl:FindFirstChild("Player")
            if owner and (owner.Value == LocalPlayer or tostring(owner.Value) == LocalPlayer.Name) then
                userPlots = userPlots + 1
            end
        end
        if userPlots > 0 then
            plotsCount = userPlots
        end
    end

    -- Boolean Quick Flags for Vault Summary
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
            garden_level = gardenLevel,
            rebirths = rebirths,
            unlocked_plots = plotsCount,
            weather = serverWeather,
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
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = jsonStr
    })

    if res and (res.StatusCode == 200 or res.StatusDescription == "OK") then
        print("[Emorima Sync] Grow a Garden telemetry synced! Sheckles: $" .. tostring(payload.stats.sheckles))
    else
        warn("[Emorima Sync] Telemetry send failed:", res and res.StatusCode or "No Response")
    end
end

-- Run immediate & Loop every 15 seconds
task.spawn(function()
    print("Key: " .. tostring(secretKey))
    while true do
        pcall(sendTelemetry)
        task.wait(15)
    end
end)
