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
        Method = req.Method or req.method or "POST",
        Headers = req.Headers or req.headers or { ["Content-Type"] = "application/json" },
        Body = req.Body or req.body
    }
    local fn = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
    if fn then return fn(httpReq) end
    return nil
end

local function safeString(v)
    if v == nil then return "" end
    return tostring(v)
end

local function safeLower(v)
    if v == nil then return "" end
    return string.lower(tostring(v))
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
    local lower = safeLower(name)
    return string.find(lower, "level", 1, true) ~= nil or string.find(lower, "lvl", 1, true) ~= nil or string.find(lower, "rebirth", 1, true) ~= nil
end

local function isSheckleName(name)
    local lower = safeLower(name)
    return string.find(lower, "sheckle", 1, true) ~= nil or string.find(lower, "money", 1, true) ~= nil or string.find(lower, "coin", 1, true) ~= nil or string.find(lower, "cash", 1, true) ~= nil or string.find(lower, "balance", 1, true) ~= nil or string.find(lower, "gold", 1, true) ~= nil
end

local knownWeathers = {
    "Acid Rain", "Aurora Borealis", "Bat Attack", "Bee Swarm", "Blood Moon",
    "Chocolate Rain", "Corrupted Aura", "Crystal Beams", "Disco", "Earthquake",
    "Frost", "Gale", "Gold Moon", "Heat Wave", "Ice King", "Jandel Storm",
    "Mega Moon", "Meteor Shower", "Night", "Rain", "Rainbow", "Rainbow Moon",
    "Sandstorm", "Sheckle Rain", "Snowfall", "Solar Eclipse", "Starfall",
    "Sun God", "Thunderstorm", "Tornado", "Tropical Rain", "Zen Aura"
}

local knownPets = {
    "ankylosaurus", "apple_gazelle", "axolotl", "bacon_pig", "bagel_bunny",
    "bald_eagle", "bear_bee", "bee", "black_bunny", "black_dragon",
    "blood_hedgehog", "blood_kiwi", "blood_owl", "brontosaurus", "brown_mouse",
    "bunny", "butterfly", "capybara", "cat", "caterpillar", "chicken",
    "chicken_zombie", "chimera", "chinchilla", "cooked_owl", "corrupted_kitsune",
    "cow", "crab", "dairy_cow", "deer", "dilophosaurus", "disco_bee",
    "dog", "dragonfly", "echo_frog", "fennec_fox", "firefly", "flamingo",
    "french_fry_ferret", "frog", "giant_ant", "goblin_miner", "gold_lab",
    "golden_bee", "golden_dragonfly", "golden_goose", "golem", "gorilla_chef",
    "grey_mouse", "griffin", "hamster", "headless_horseman", "hedgehog",
    "hotdog_dachshund", "hyacinth_macaw", "hydra", "ice_serpent", "iguanodon",
    "jackalope", "kappa", "kitsune", "kiwi", "kodama", "koi", "lemon_lion",
    "lion", "lobster_thermidor", "maneki_neko", "meerkat", "messenger_pigeon",
    "mimic_octopus", "mizuchi", "mole", "monkey", "moon_cat", "moth",
    "nihonzaru", "orangutan", "ostrich", "owl", "pachycephalosaurus", "pack_bee",
    "panda", "pancake_mole", "parasaurolophus", "peacock", "petal_bee", "phoenix",
    "pig", "polar_bear", "praying_mantis", "pterodactyl", "queen_bee", "raccoon",
    "raju", "raptor", "red_fox", "red_giant_ant", "red_panda", "robin",
    "rooster", "ruby_squid", "sand_snake", "scarlet_macaw", "sea_otter", "sea_turtle",
    "seagull", "seal", "shiba_inu", "silver_monkey", "snail", "space_squirrel",
    "spaghetti_sloth", "spinosaurus", "spotted_deer", "spriggan", "squirrel",
    "starfish", "stegosaurus", "sugar_glider", "sushi_bear", "t_rex", "tanchozuru",
    "tanuki", "tarantula_hawk", "toucan", "triceratops", "tsuchinoko", "turtle",
    "unicorn", "wasp", "woody"
}

local function fullGardenScan()
    local sheckles = 0
    local gardenLevel = 1
    local shecklesSource = "Default"
    local debugLog = {}

    pcall(function()
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        if leaderstats then
            for _, child in ipairs(leaderstats:GetChildren()) do
                local name = safeString(child.Name)
                local valStr = safeString(child.Value)
                table.insert(debugLog, "leaderstats." .. name .. " = " .. valStr)

                if isLevelName(name) then
                    local lvl = cleanNumber(valStr)
                    if lvl > 0 then gardenLevel = lvl end
                elseif isSheckleName(name) then
                    local sh = parseFlowerString(valStr)
                    if sh > 0 then sheckles = sh; shecklesSource = "leaderstats." .. name end
                elseif string.find(valStr, "🌸", 1, true) then
                    local sh, lvl = parseFlowerString(valStr)
                    if sh and sh > 0 then sheckles = sh; shecklesSource = "leaderstats." .. name end
                    if lvl and lvl > 0 then gardenLevel = lvl end
                end
            end
        end
    end)

    pcall(function()
        for _, folderName in ipairs({"Data", "PlayerData", "Inventory", "Stats", "PlayerStats", "Values", "SaveData"}) do
            local folder = LocalPlayer:FindFirstChild(folderName)
            if folder then
                for _, child in ipairs(folder:GetChildren()) do
                    if child:IsA("ValueBase") then
                        local name = safeString(child.Name)
                        local valStr = safeString(child.Value)
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
    end)

    local pgui = LocalPlayer:FindFirstChild("PlayerGui")
    pcall(function()
        if pgui then
            for _, gui in ipairs(pgui:GetChildren()) do
                if gui:IsA("ScreenGui") and gui.Enabled then
                    for _, desc in ipairs(gui:GetDescendants()) do
                        if desc:IsA("TextLabel") and desc.Visible then
                            local txt = safeString(desc.Text)
                            local lowerText = safeLower(txt)
                            local lowerName = safeLower(desc.Name)

                            local lvlNum = string.match(txt, "[Ll][Vv][Ll]%s*[:%s]*%s*(%d+)") or string.match(txt, "[Ll][Ee][Vv][Ee][Ll]%s*[:%s]*%s*(%d+)")
                            if lvlNum then
                                local n = tonumber(lvlNum)
                                if n and n > gardenLevel then gardenLevel = n end
                            end

                            if sheckles == 0 and not isLevelName(lowerName) and not isLevelName(lowerText) then
                                if string.find(txt, "🌸", 1, true) or string.find(txt, "$", 1, true) or string.find(lowerText, "sheckle", 1, true) or string.find(lowerName, "sheckle", 1, true) then
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
    end)

    local serverWeather = "Clear Sky"
    pcall(function()
        for _, child in ipairs(workspace:GetChildren()) do
            local cName = safeLower(child.Name)
            for _, wName in ipairs(knownWeathers) do
                if string.find(cName, safeLower(wName), 1, true) then
                    serverWeather = wName
                    break
                end
            end
        end

        if serverWeather == "Clear Sky" then
            for _, child in ipairs(Lighting:GetChildren()) do
                local cName = safeLower(child.Name)
                for _, wName in ipairs(knownWeathers) do
                    if string.find(cName, safeLower(wName), 1, true) then
                        serverWeather = wName
                        break
                    end
                end
            end
        end

        if serverWeather == "Clear Sky" and pgui then
            for _, gui in ipairs(pgui:GetChildren()) do
                if gui:IsA("ScreenGui") and gui.Enabled then
                    for _, desc in ipairs(gui:GetDescendants()) do
                        if desc:IsA("TextLabel") and desc.Visible then
                            local txt = safeLower(desc.Text)
                            for _, wName in ipairs(knownWeathers) do
                                if string.find(txt, safeLower(wName), 1, true) then
                                    serverWeather = wName
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    local petsMap = {}
    local function checkAndAddPet(str)
        if not str then return end
        local lowerStr = safeLower(str)
        for _, pName in ipairs(knownPets) do
            local cleanP = string.gsub(pName, "_", " ")
            if string.find(lowerStr, pName, 1, true) or string.find(lowerStr, cleanP, 1, true) then
                petsMap[pName] = true
            end
        end
    end

    pcall(function()
        if LocalPlayer:FindFirstChild("Backpack") then
            for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do checkAndAddPet(item.Name) end
        end
        if LocalPlayer.Character then
            for _, item in ipairs(LocalPlayer.Character:GetChildren()) do checkAndAddPet(item.Name) end
        end
        if pgui then
            for _, gui in ipairs(pgui:GetChildren()) do
                if gui:IsA("ScreenGui") and gui.Enabled then
                    for _, desc in ipairs(gui:GetDescendants()) do
                        if desc:IsA("TextLabel") then
                            checkAndAddPet(desc.Name)
                            checkAndAddPet(desc.Text)
                        elseif desc:IsA("ImageLabel") then
                            checkAndAddPet(desc.Name)
                        end
                    end
                end
            end
        end
        for _, fName in ipairs({"Data", "PlayerData", "Inventory", "Pets", "Stats"}) do
            local f = LocalPlayer:FindFirstChild(fName)
            if f then
                for _, c in ipairs(f:GetDescendants()) do
                    checkAndAddPet(c.Name)
                    if c:IsA("ValueBase") then checkAndAddPet(safeString(c.Value)) end
                end
            end
        end
    end)

    local petsList = {}
    for p, _ in pairs(petsMap) do table.insert(petsList, p) end

    local plotsCount = 4
    pcall(function()
        local plotsFolder = workspace:FindFirstChild("Plots") or workspace:FindFirstChild("GardenPlots") or workspace:FindFirstChild("Farms") or workspace:FindFirstChild("Garden") or workspace:FindFirstChild("Islands")
        if plotsFolder then
            local count = 0
            for _, pl in ipairs(plotsFolder:GetChildren()) do
                local owner = pl:FindFirstChild("Owner") or pl:FindFirstChild("Player") or pl:FindFirstChild("PlotOwner")
                local isOwned = false
                if owner then
                    if owner.Value == LocalPlayer or safeString(owner.Value) == LocalPlayer.Name or safeString(owner.Value) == safeString(LocalPlayer.UserId) then
                        isOwned = true
                    end
                elseif string.find(safeLower(pl.Name), safeLower(LocalPlayer.Name), 1, true) then
                    isOwned = true
                elseif pl:GetAttribute("Owner") == LocalPlayer.Name or pl:GetAttribute("Player") == LocalPlayer.Name then
                    isOwned = true
                end

                if isOwned then
                    local tiles = pl:FindFirstChild("Tiles") or pl:FindFirstChild("Plots") or pl:FindFirstChild("Grid") or pl:FindFirstChild("Soil")
                    if tiles then
                        count = count + #tiles:GetChildren()
                    else
                        count = count + 1
                    end
                end
            end
            if count > 0 then plotsCount = count end
        end
    end)

    local hasAether = false; local hasDragon = false; local hasPeach = false
    local hasTrinity = false; local hasCelestiberry = false; local hasDiscoBee = false
    local hasGoose = false; local hasRainbowSeed = false

    for _, p in ipairs(petsList) do
        local lp = safeLower(p)
        if string.find(lp, "disco", 1, true) then hasDiscoBee = true end
        if string.find(lp, "goose", 1, true) then hasGoose = true end
    end

    return {
        secret_key = secretKey,
        stats = {
            roblox_username = LocalPlayer.Name,
            roblox_user_id = LocalPlayer.UserId,
            sheckles = sheckles,
            sheckles_source = shecklesSource,
            garden_level = gardenLevel,
            rebirths = 0,
            unlocked_plots = plotsCount,
            weather = serverWeather,
            pets = petsList,
            crops = {},
            seeds = {},
            tools = {},
            sprinklers = {},
            mutations = {},
            has_aetherfruit = hasAether,
            has_dragon_fruit = hasDragon,
            has_golden_peach = hasPeach,
            has_trinity_fruit = hasTrinity,
            has_celestiberry = hasCelestiberry,
            has_disco_bee = hasDiscoBee,
            has_golden_goose = hasGoose,
            has_rainbow_seed = hasRainbowSeed,
            debug_log = debugLog
        }
    }
end

local function sendTelemetry()
    local payload = fullGardenScan()
    if not payload then return end

    local jsonBody = HttpService:JSONEncode(payload)
    request_http({
        Url = API_URL,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = jsonBody
    })
end

task.spawn(function()
    while true do
        task.spawn(sendTelemetry)
        task.wait(10)
    end
end)
