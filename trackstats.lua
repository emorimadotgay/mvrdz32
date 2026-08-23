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

local function gInv()
    local itms = {}
    local r = RS:FindFirstChild("Remotes")
    if not r then return itms end
    local c = r:FindFirstChild("CommF_")
    if not c then return itms end
    local s, v = pcall(function() return c:InvokeServer("getInventory") end)
    if s and type(v) == "table" then
        for _, i in ipairs(v) do
            if type(i) == "table" and i.Name then
                table.insert(itms, {id = tostring(i.Name), lbl = tostring(i.Name), v = 1})
            end
        end
    end
    return itms
end

local function hF(inv, tid)
    local tg = tid:lower()
    for _, i in ipairs(inv) do
        local id = (i.id or ""):lower()
        local lbl = (i.lbl or ""):lower()
        if id == tg or id:find(tg, 1, true) or lbl:find(tg, 1, true) then return true end
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
    local inv = gInv()
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
        godhuman = mel == "godhuman",
        sanguine_art = mel == "sanguine art",
        cursed_dual_katana = hF(inv, "Cursed Dual Katana") or hT("Cursed Dual Katana"),
        true_triple_katana = hF(inv, "True Triple Katana") or hT("True Triple Katana"),
        shark_anchor = hF(inv, "Shark Anchor") or hT("Shark Anchor"),
        dark_blade = hF(inv, "Dark Blade") or hT("Dark Blade"),
        hallow_scythe = hF(inv, "Hallow Scythe") or hT("Hallow Scythe"),
        fox_lamp = hF(inv, "Fox Lamp") or hT("Fox Lamp"),
        yama = hF(inv, "Yama") or hT("Yama"),
        tushita = hF(inv, "Tushita") or hT("Tushita"),
        saddi = hF(inv, "Saddi") or hT("Saddi"),
        wando = hF(inv, "Wando") or hT("Wando"),
        shisui = hF(inv, "Shisui") or hT("Shisui"),
        saber = hF(inv, "Saber") or hT("Saber"),
        soul_guitar = hF(inv, "Soul Guitar") or hT("Soul Guitar"),
        kabucha = hF(inv, "Kabucha") or hT("Kabucha"),
        acidum_rifle = hF(inv, "Acidum Rifle") or hT("Acidum Rifle"),
        fruit_kitsune = hF(inv, "Kitsune-Kitsune") or hF(inv, "Kitsune"),
        fruit_dragon = hF(inv, "Dragon-Dragon") or hF(inv, "Dragon"),
        fruit_tiger = hF(inv, "Tiger-Tiger") or hF(inv, "Tiger") or hF(inv, "Leopard"),
        fruit_yeti = hF(inv, "Yeti-Yeti") or hF(inv, "Yeti"),
        fruit_dough = hF(inv, "Dough-Dough") or hF(inv, "Dough"),
        fruit_portal = hF(inv, "Portal-Portal") or hF(inv, "Portal"),
        fruit_buddha = hF(inv, "Buddha-Buddha") or hF(inv, "Buddha"),
        fruit_trex = hF(inv, "T-Rex-T-Rex") or hF(inv, "T-Rex"),
        fruit_mammoth = hF(inv, "Mammoth-Mammoth") or hF(inv, "Mammoth"),
        fruit_gas = hF(inv, "Gas-Gas") or hF(inv, "Gas"),
        fruit_spirit = hF(inv, "Spirit-Spirit") or hF(inv, "Spirit"),
        fruit_venom = hF(inv, "Venom-Venom") or hF(inv, "Venom"),
        fruit_control = hF(inv, "Control-Control") or hF(inv, "Control"),
        fruit_blizzard = hF(inv, "Blizzard-Blizzard") or hF(inv, "Blizzard"),
        fruit_lightning = hF(inv, "Lightning-Lightning") or hF(inv, "Lightning")
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
