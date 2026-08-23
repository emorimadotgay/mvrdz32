local _G_KEY = getgenv and getgenv().EMORIMA_DEVICE_KEY or "DEV-XXXXXX"
local _G_API = getgenv and getgenv().EMORIMA_API or "https://qnguyen36.vercel.app"
local _G_DELAY = 15

local HS = game:GetService("HttpService")
local PLRS = game:GetService("Players")
local RS = game:GetService("RunService")
local SGui = game:GetService("StarterGui")
local lplr = PLRS.LocalPlayer

local fps = 0
local lst = tick()
local fcnt = 0
RS.RenderStepped:Connect(function()
    fcnt = fcnt + 1
    local now = tick()
    if now - lst >= 1 then
        fps = fcnt
        fcnt = 0
        lst = now
    end
end)

local function sget(f)
    local s, r = pcall(f)
    return s and r or nil
end

local function gPing()
    local p = sget(function() return lplr:GetNetworkPing() * 1000 end)
    return p and math.floor(p) or 0
end

local function cData()
    local hwid = sget(function() return HS:GenerateGUID(false) end) or "UNKNOWN"
    return {
        key = _G_KEY,
        roblox_username = lplr and lplr.Name or "Unknown",
        roblox_id = lplr and lplr.UserId or 0,
        fps = fps,
        ping = gPing(),
        uptime = math.floor(workspace.DistributedGameTime or 0),
        job_id = game.JobId,
        place_id = game.PlaceId,
        hwid = hwid,
        timestamp = os.time()
    }
end

local function sPing(d)
    local u = _G_API .. "/api/api_device_monitor"
    local req = (type(syn) == "table" and syn.request) or (type(http) == "table" and http.request) or (type(fluxus) == "table" and fluxus.request) or http_request or request
    if req then
        local s, e = pcall(function()
            req({
                Url = u,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HS:JSONEncode(d)
            })
        end)
        if not s then print("[Emorima DeviceMonitor] Request Error: " .. tostring(e)) end
    else
        warn("[Emorima DeviceMonitor] Your executor does not support HTTP requests!")
    end
end

if _G_KEY:find("XXXX") then return end
if lplr then if not lplr.Character then lplr.CharacterAdded:Wait() end end
task.wait(2)

print("[Emorima] DeviceMonitor Initialized! Pinging every " .. _G_DELAY .. "s...")
task.spawn(function()
    while true do
        pcall(function() sPing(cData()) end)
        task.wait(_G_DELAY)
    end
end)
