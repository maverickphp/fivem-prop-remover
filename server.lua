--======================================================================
--  prop_remover - server.lua
--  Permission is checked SERVER-SIDE (ESX / QBCore / ACE). The client only
--  *asks* to remove a prop; non-admins are rejected here no matter what.
--  v2: per-prop metadata (id / who / when), restore-by-id, update checker,
--  simple per-source rate limiting.
--======================================================================

local removedProps = {}
local nextId       = 1
local FILE         = 'data/removed_props.json'

-- ---- framework objects (loaded only for the mode you picked) ----
local ESX, QBCore
CreateThread(function()
    if Config.PermissionMode == 'esx' then
        local tries = 0
        while not ESX and tries < 50 do
            local ok, obj = pcall(function() return exports[Config.ESXResource]:getSharedObject() end)
            if ok and obj then ESX = obj break end
            tries = tries + 1
            Wait(200)
        end
        if not ESX then
            TriggerEvent('esx:getSharedObject', function(o) ESX = o end) -- very old ESX fallback
        end
        if ESX then print('[prop_remover] ESX linked.') else print('[prop_remover] WARNING: ESX not found.') end

    elseif Config.PermissionMode == 'qbcore' then
        local tries = 0
        while not QBCore and tries < 50 do
            local ok, obj = pcall(function() return exports[Config.QBCoreResource]:GetCoreObject() end)
            if ok and obj then QBCore = obj break end
            tries = tries + 1
            Wait(200)
        end
        if QBCore then print('[prop_remover] QBCore linked.') else print('[prop_remover] WARNING: QBCore not found.') end
    end
end)

-- ---- the admin gate ----
local function isAdmin(src)
    if not src or src == 0 then return false end

    if Config.PermissionMode == 'ace' then
        return IsPlayerAceAllowed(src, Config.AcePermission)

    elseif Config.PermissionMode == 'esx' then
        if not ESX then return false end
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return false end
        local group = (xPlayer.getGroup and xPlayer.getGroup()) or xPlayer.group
        for _, g in ipairs(Config.AllowedGroups) do
            if group == g then return true end
        end
        return false

    elseif Config.PermissionMode == 'qbcore' then
        if not QBCore then return false end
        for _, g in ipairs(Config.AllowedGroups) do
            if QBCore.Functions.HasPermission(src, g) then return true end
        end
        return false
    end
    return false
end

-- ---- simple rate limiting (defence in depth; events are already admin-gated) ----
local lastAction = {}
local function rateLimited(src, ms)
    local now = GetGameTimer()
    local last = lastAction[src] or 0
    if now - last < (ms or 150) then return true end
    lastAction[src] = now
    return false
end
AddEventHandler('playerDropped', function()
    lastAction[source] = nil
end)

-- ---- storage ----
local function loadProps()
    local raw = LoadResourceFile(GetCurrentResourceName(), FILE)
    local list = {}
    if raw and raw ~= '' then
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == 'table' then list = decoded end
    end
    -- migrate older entries (no id) + figure out nextId
    local maxId = 0
    for _, p in ipairs(list) do
        if type(p.id) ~= 'number' then
            maxId = maxId + 1
            p.id = maxId
        elseif p.id > maxId then
            maxId = p.id
        end
        if not p.modelName then p.modelName = GetReadablePropName(p.model) end
    end
    nextId = maxId + 1
    return list
end

local function persist()
    SaveResourceFile(GetCurrentResourceName(), FILE, json.encode(removedProps), -1)
end

local function syncAll()
    TriggerClientEvent('propremover:sync', -1, removedProps)
end

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    removedProps = loadProps()
    print(('[prop_remover] Loaded %d saved removal(s). Mode: %s'):format(#removedProps, Config.PermissionMode))
end)

-- ---- update checker ----
CreateThread(function()
    if not Config.CheckUpdates then return end
    PerformHttpRequest(('https://api.github.com/repos/%s/releases/latest'):format(Config.GithubRepo),
        function(code, body)
            if code == 200 and body then
                local ok, data = pcall(json.decode, body)
                if ok and data and data.tag_name then
                    local latest = (data.tag_name:gsub('^v', ''))
                    if latest ~= Config.Version then
                        print(('[prop_remover] ^3Update available: %s (you have %s) -> https://github.com/%s^7')
                            :format(latest, Config.Version, Config.GithubRepo))
                    else
                        print(('[prop_remover] Up to date (%s).'):format(Config.Version))
                    end
                end
            end
            -- 404 = no releases published yet; stay quiet.
        end, 'GET', '', { ['User-Agent'] = 'prop_remover' })
end)

-- Client just loaded -> send kill list + tell it whether this player is an admin
RegisterNetEvent('propremover:request', function()
    local src = source
    TriggerClientEvent('propremover:sync', src, removedProps)
    TriggerClientEvent('propremover:setAdmin', src, isAdmin(src))
end)

-- Live re-check (client asks again when toggling, in case rank changed mid-session)
RegisterNetEvent('propremover:checkAdmin', function()
    local src = source
    TriggerClientEvent('propremover:setAdmin', src, isAdmin(src))
end)

-- Admin removed a prop in-game -> save it forever
RegisterNetEvent('propremover:add', function(model, x, y, z)
    local src = source
    if rateLimited(src) then return end
    if not isAdmin(src) then
        print(('[prop_remover] %s tried to remove a prop WITHOUT permission. Ignored.'):format(src))
        return
    end
    if type(model) ~= 'number' or type(x) ~= 'number' or type(y) ~= 'number' or type(z) ~= 'number' then return end

    for _, p in ipairs(removedProps) do
        if p.model == model and math.abs(p.x - x) < 1.0 and math.abs(p.y - y) < 1.0 and math.abs(p.z - z) < 1.0 then
            return
        end
    end

    local entry = {
        id        = nextId,
        model     = model,
        modelName = GetReadablePropName(model),
        x = x, y = y, z = z,
        by   = GetPlayerName(src) or ('id ' .. src),
        time = os.date('%Y-%m-%d %H:%M'),
    }
    nextId = nextId + 1
    removedProps[#removedProps + 1] = entry
    persist()
    syncAll()
    print(('[prop_remover] %s saved removal of %s at %.2f, %.2f, %.2f (total: %d)')
        :format(entry.by, entry.modelName, x, y, z, #removedProps))
end)

-- Restore a single prop by id (from the management menu)
RegisterNetEvent('propremover:restoreOne', function(id)
    local src = source
    if rateLimited(src) then return end
    if not isAdmin(src) then return end
    if type(id) ~= 'number' then return end
    for i = 1, #removedProps do
        if removedProps[i].id == id then
            local p = table.remove(removedProps, i)
            persist()
            syncAll()
            print(('[prop_remover] %s restored %s (remaining: %d).')
                :format(GetPlayerName(src) or src, p.modelName or p.model, #removedProps))
            return
        end
    end
end)

RegisterNetEvent('propremover:undo', function()
    local src = source
    if not isAdmin(src) then return end
    if #removedProps > 0 then
        table.remove(removedProps, #removedProps)
        persist()
        syncAll()
        print(('[prop_remover] %s undid last removal (remaining: %d).'):format(src, #removedProps))
    end
end)

RegisterNetEvent('propremover:clear', function()
    local src = source
    if not isAdmin(src) then return end
    removedProps = {}
    persist()
    syncAll()
    print(('[prop_remover] %s cleared ALL saved removals.'):format(src))
end)
