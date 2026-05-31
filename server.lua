--======================================================================
--  prop_remover - server.lua
--  Permission is checked SERVER-SIDE (ESX / QBCore / ACE). The client only
--  *asks* to remove a prop; non-admins are rejected here no matter what.
--======================================================================

local removedProps = {}
local FILE = 'data/removed_props.json'

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

-- ---- storage ----
local function loadProps()
    local raw = LoadResourceFile(GetCurrentResourceName(), FILE)
    if raw and raw ~= '' then
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == 'table' then return decoded end
    end
    return {}
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

    removedProps[#removedProps + 1] = { model = model, x = x, y = y, z = z }
    persist()
    syncAll()
    print(('[prop_remover] %s saved removal of %s at %.2f, %.2f, %.2f (total: %d)'):format(src, model, x, y, z, #removedProps))
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