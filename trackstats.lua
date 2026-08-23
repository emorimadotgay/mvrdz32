local _G_KEY = getgenv and getgenv().EMORIMA_ACCOUNT_KEY or getgenv().TRACKSTATS_KEY or "TS-XXXXXX-XXXX"
local _G_API = getgenv and getgenv().EMORIMA_API or "https://qnguyen36.vercel.app"
local _G_ANON = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InljYXFodXJwcXNqY3pnYWh5cmJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODcyNTc0MjYsImV4cCI6MjEwMjgzMzQyNn0.zXpfH7y0BwRvQpBwa-yqyelrM0VWxXm8Q1uls6v9SpA"
local _G_DELAY = 60

local HS = game:GetService("HttpService")
local PLRS = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local lplr = PLRS.LocalPlayer

local function sget(f)
    local s, r = pcall(f)
    return s and r or nil
end

local function getd()
    local d = lplr:FindFirstChild("Data")
    if not d then d = lplr:WaitForChild("Data", 10) end
    return d
end

local function rv(p, k, d)
    if not p then return d end
    local n = p:FindFirstChild(k)
    return n and n.Value or d
end

local function gLvl() return sget(function() return tonumber(rv(getd(), "Level", 0)) or 0 end) or 0 end
local function gBeli() return sget(function() return tonumber(rv(getd(), "Beli", 0)) or 0 end) or 0 end
local function gFrag() return sget(function() return tonumber(rv(getd(), "Fragments", 0)) or 0 end) or 0 end
local function gBounty()
    return sget(function()
        local ls = lplr:FindFirstChild("leaderstats")
        if ls then
            local b = ls:FindFirstChild("Bounty/Honor") or ls:FindFirstChild("Bounty") or ls:FindFirstChild("Honor")
            if b then return tonumber(b.Value) or 0 end
        end
        local d = getd()
        if d then
            local b = d:FindFirstChild("Bounty") or d:FindFirstChild("Honor")
            if b then return tonumber(b.Value) or 0 end
        end
        return 0
    end) or 0
end
local function gRace() return sget(function() return tostring(rv(getd(), "Race", "Human")) end) or "Human" end
local function gRaceV()
    return sget(function()
        local r = RS:FindFirstChild("Remotes")
        if not r then return 0 end
        local c = r:FindFirstChild("CommF_")
        if not c then return 0 end
        local v = c:InvokeServer("getRaceLevel")
        return type(v) == "number" and v or 0
    end) or 0
end
local function gTier()
    return sget(function()
        local d = getd()
        if d and d:FindFirstChild("Race") and d.Race:FindFirstChild("C") then
            return tonumber(d.Race.C.Value) or 0
        end
        return 0
    end) or 0
end
local function gMelee()
    local function sc(c)
        if not c then return nil end
        for _, t in ipairs(c:GetChildren()) do
            if t:IsA("Tool") then
                local n = t.Name:lower():gsub("[_%-%s]+", " ")
                if n:find("god human") or n:find("godhuman") then return "godhuman"
                elseif n:find("sanguine") then return "sanguine art" end
            end
        end
        return nil
    end
    return sc(lplr.Character) or sc(lplr:FindFirstChild("Backpack")) or ""
end

local function cleanFruitName(raw)
    if not raw or raw == "" then return "None" end
    local name = tostring(raw):gsub("%s*[Pp]hysical%s*", ""):gsub("%s*Fruit%s*", ""):gsub("%s*fruit%s*", "")
    local p1, p2 = name:match("^([%w%s]+)%-(%w+)$")
    if p1 and p2 and p1:lower() == p2:lower() then return p1 end
    if name:find("%-") then
        local parts = string.split(name, "-")
        if #parts >= 2 and parts[1]:lower() == parts[2]:lower() then return parts[1] end
    end
    return name
end

local function gInvAdvanced()
    local fruits, swords, guns, materials, accessories = {}, {}, {}, {}, {}
    local fruitMap = {}
    
    pcall(function()
        -- FIX: Use getrenv().require to prevent executor from breaking game scripts with RobloxScript context errors
        local gameReq = (getrenv and getrenv().require) or require
        local ItemReplicationService = gameReq(RS:WaitForChild("ItemReplicationService", 3))
        local KEYS = gameReq(RS.ItemReplicationService:WaitForChild("KEYS", 3))
        local ItemConfig = gameReq(RS:WaitForChild("ItemConfig", 3))

        local getItems = ItemReplicationService.GetItems
        local a, b = debug.getupvalue(getItems, 2)
        local cacheTable = (type(a) == "table" and a) or (type(b) == "table" and b)
        local userCache = cacheTable and cacheTable[lplr.UserId]
        local items = userCache and userCache:GetItems(KEYS.QUANTITY)

        if items then
            for _, v in pairs(items) do
                if v.Value and v.Value > 0 then
                    pcall(function()
                        local matchRes = ItemConfig.match(v.ItemId)
                        if matchRes and matchRes.unwrap then
                            local info = matchRes:unwrap()
                            local rawName = tostring((info.Index and info.Index.StorageKey) or "")
                            local displayName = tostring((info.Display and info.Display.Name) or rawName)
                            local category = tostring((info.Display and info.Display.Category) or "")
                            local idType = tostring((info.Index and info.Index.IdType) or "")
                            local storageMethod = tostring((info.State and info.State.StorageMethod) or "")

                            if category == "Blox Fruit" or idType == "PhysicalMoveset" or storageMethod == "StoredFruits" then
                                local cName = cleanFruitName(displayName)
                                local key = cName:lower()
                                if fruitMap[key] then
                                    fruitMap[key].count = fruitMap[key].count + v.Value
                                else
                                    fruitMap[key] = { name = cName, count = v.Value }
                                    table.insert(fruits, fruitMap[key])
                                end
                            elseif category == "Sword" or (idType == "Weapon" and (rawName:find("Sword") or displayName:find("Katana") or displayName:find("Saber") or displayName:find("Blade") or displayName:find("Trident") or displayName:find("Tushita") or displayName:find("Yama"))) then
                                table.insert(swords, { name = displayName, count = v.Value })
                            elseif category == "Gun" or (idType == "Weapon" and (rawName:find("Gun") or displayName:find("Guitar") or displayName:find("Rifle") or displayName:find("Bow") or displayName:find("Kabucha") or displayName:find("Flintlock") or displayName:find("Bazooka") or displayName:find("Revolver"))) then
                                table.insert(guns, { name = displayName, count = v.Value })
                            elseif category == "Accessory" or category == "Wearable" or storageMethod == "WearablesUnlocked" then
                                table.insert(accessories, { name = displayName, count = v.Value })
                            elseif category == "Material" or idType == "Material" or storageMethod == "Materials" then
                                table.insert(materials, { name = displayName, count = v.Value })
                            end
                        end
                    end)
                end
            end
        end
    end)
    return fruits, swords, guns, materials, accessories
end

local function hF(arr, name)
    local tg = name:lower()
    for _, i in ipairs(arr) do
        local id = (i.name or ""):lower()
        if id == tg or id:find(tg, 1, true) then return true end
    end
    return false
end

local function hT(n)
    local tg = n:lower()
    local function sc(c)
        if not c then return false end
        for _, t in ipairs(c:GetChildren()) do
            if t:IsA("Tool") and t.Name:lower():find(tg, 1, true) then return true end
        end
        return false
    end
    return sc(lplr.Character) or sc(lplr:FindFirstChild("Backpack"))
end

local function cStats()
    local fruits, swords, guns, materials, accessories = gInvAdvanced()
    local mel = gMelee()
    
    return {
        roblox_username = lplr.Name,
        roblox_user_id = lplr.UserId,
        level = gLvl(),
        beli = gBeli(),
        fragments = gFrag(),
        bounty_honor = gBounty(),
        race = gRace(),
        race_ver = gRaceV(),
        tier = gTier(),
        melee = mel,
        godhuman = mel == "godhuman" or mel == "god human",
        sanguine_art = mel == "sanguine art",
        cursed_dual_katana = hF(swords, "Cursed Dual Katana") or hT("Cursed Dual Katana"),
        true_triple_katana = hF(swords, "True Triple Katana") or hT("True Triple Katana"),
        shark_anchor = hF(swords, "Shark Anchor") or hT("Shark Anchor"),
        dark_blade = hF(swords, "Dark Blade") or hT("Dark Blade"),
        hallow_scythe = hF(swords, "Hallow Scythe") or hT("Hallow Scythe"),
        fox_lamp = hF(swords, "Fox Lamp") or hT("Fox Lamp"),
        yama = hF(swords, "Yama") or hT("Yama"),
        tushita = hF(swords, "Tushita") or hT("Tushita"),
        saddi = hF(swords, "Saddi") or hT("Saddi"),
        wando = hF(swords, "Wando") or hT("Wando"),
        shisui = hF(swords, "Shisui") or hT("Shisui"),
        saber = hF(swords, "Saber") or hT("Saber"),
        soul_guitar = hF(guns, "Soul Guitar") or hT("Soul Guitar"),
        kabucha = hF(guns, "Kabucha") or hT("Kabucha"),
        acidum_rifle = hF(guns, "Acidum Rifle") or hT("Acidum Rifle"),
        fruit_kitsune = hF(fruits, "Kitsune"),
        fruit_dragon = hF(fruits, "Dragon"),
        fruit_tiger = hF(fruits, "Tiger") or hF(fruits, "Leopard"),
        fruit_yeti = hF(fruits, "Yeti"),
        fruit_dough = hF(fruits, "Dough"),
        fruit_portal = hF(fruits, "Portal"),
        fruit_buddha = hF(fruits, "Buddha"),
        fruit_trex = hF(fruits, "T-Rex"),
        fruit_mammoth = hF(fruits, "Mammoth"),
        fruit_gas = hF(fruits, "Gas"),
        fruit_spirit = hF(fruits, "Spirit"),
        fruit_venom = hF(fruits, "Venom"),
        fruit_control = hF(fruits, "Control"),
        fruit_blizzard = hF(fruits, "Blizzard"),
        fruit_lightning = hF(fruits, "Lightning")
    }
end

local function sStats(pld)
    local b = HS:JSONEncode({secret_key = _G_KEY, stats = pld, timestamp = os.time()})
    local u = _G_API .. "/api/api_trackstats"
    local req = (type(syn) == "table" and syn.request) or (type(http) == "table" and http.request) or (type(fluxus) == "table" and fluxus.request) or http_request or request
    if req then
        local s, e = pcall(function()
            req({Url = u, Method = "POST", Headers = {["Content-Type"] = "application/json", ["Authorization"] = "Bearer " .. _G_ANON}, Body = b})
        end)
        if not s then print("[Emorima TrackStats] Request Error: " .. tostring(e)) end
    else
        warn("[Emorima TrackStats] Your executor does not support HTTP requests!")
    end
end

if _G_KEY:find("XXXX") then return end
if not lplr.Character then lplr.CharacterAdded:Wait() end
task.wait(3)

print("[Emorima] TrackStats Initialized! Fetching data every " .. _G_DELAY .. "s...")
task.spawn(function()
    while true do
        pcall(function() sStats(cStats()) end)
        task.wait(_G_DELAY)
    end
end)
