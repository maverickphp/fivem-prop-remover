--======================================================================
--  prop_remover - client.lua
--  Map/world props aren't networked, so deletion must run on each client.
--  The server sends us the saved "kill list" and we keep these props gone.
--  v2: ox_lib management menu (teleport / restore each prop), area wipe,
--  readable model names.
--======================================================================

lib.locale()  -- load locales/<Config.Locale>.json into the locale() function

local removedProps = {}      -- synced from server: { {id, model, x, y, z, by, time}, ... }
local removalMode  = false
local lastOutlined = nil
local isAdmin      = false   -- set by the server; gates the menu/commands

--------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------
local function notify(msg, kind)
    lib.notify({ title = locale('notify_title'), description = msg, type = kind or 'inform' })
end

local function rotationToDirection(rot)
    local z = math.rad(rot.z)
    local x = math.rad(rot.x)
    local num = math.abs(math.cos(x))
    return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end

-- Returns: hitBool, endCoords, entityHandle
local function aimRaycast(dist)
    local camRot   = GetGameplayCamRot(2)
    local camCoord = GetGameplayCamCoord()
    local dir      = rotationToDirection(camRot)
    local dest     = camCoord + (dir * dist)
    local handle   = StartShapeTestRay(
        camCoord.x, camCoord.y, camCoord.z,
        dest.x, dest.y, dest.z,
        -1, PlayerPedId(), 0
    )
    local _, hit, endCoords, _, entity = GetShapeTestResult(handle)
    return (hit == 1 or hit == true), endCoords, entity
end

local function deleteEntitySafe(entity)
    if entity and entity ~= 0 and DoesEntityExist(entity) then
        SetEntityAsMissionEntity(entity, true, true)
        DeleteEntity(entity)
        if DoesEntityExist(entity) then
            -- Fallback if it refuses to delete (some MLO-embedded props):
            -- shove it far under the map so it's out of sight.
            local c = GetEntityCoords(entity)
            SetEntityCoordsNoOffset(entity, c.x, c.y, c.z - 100.0, false, false, false)
        end
        return true
    end
    return false
end

local function drawText3D(coords, text)
    SetDrawOrigin(coords.x, coords.y, coords.z, 0)
    SetTextFont(4)
    SetTextScale(0.34, 0.34)
    SetTextColour(255, 255, 255, 215)
    SetTextOutline()
    SetTextCentre(true)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

local function drawHelp(text)
    SetTextFont(4)
    SetTextScale(0.45, 0.45)
    SetTextColour(255, 255, 255, 230)
    SetTextOutline()
    SetTextCentre(true)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.5, 0.04)
end

--------------------------------------------------------------------
-- Delete the prop the admin is aiming at, then ask server to save it
--------------------------------------------------------------------
local function tryRemoveAimed()
    local hit, _, entity = aimRaycast(Config.RayDistance)
    if not hit or not entity or entity == 0 or not DoesEntityExist(entity) then
        notify(locale('nothing_aimed'), 'error')
        return
    end
    if not IsEntityAnObject(entity) then
        notify(locale('not_a_prop'), 'error')
        return
    end

    local model  = GetEntityModel(entity)
    local coords = GetEntityCoords(entity)

    deleteEntitySafe(entity)                                   -- instant local feedback
    TriggerServerEvent('propremover:add', model, coords.x, coords.y, coords.z)
    notify(locale('removed_saving', GetReadablePropName(model)), 'success')
end

--------------------------------------------------------------------
-- Area wipe: delete every prop of the aimed model within a radius
--------------------------------------------------------------------
local function tryAreaWipe()
    local hit, _, entity = aimRaycast(Config.RayDistance)
    if not hit or not entity or entity == 0 or not IsEntityAnObject(entity) then
        notify(locale('not_a_prop'), 'error')
        return
    end

    local model  = GetEntityModel(entity)
    local center = GetEntityCoords(entity)
    local name   = GetReadablePropName(model)

    local confirm = lib.alertDialog({
        header   = locale('area_wipe_confirm_header'),
        content  = locale('area_wipe_confirm', name, Config.AreaWipeRadius),
        centered = true,
        cancel   = true,
    })
    if confirm ~= 'confirm' then return end

    local removed = 0
    for _ = 1, 64 do  -- cap so a bad radius can't loop forever
        local obj = GetClosestObjectOfType(
            center.x, center.y, center.z, Config.AreaWipeRadius, model,
            false, false, false
        )
        if obj and obj ~= 0 and DoesEntityExist(obj) then
            local c = GetEntityCoords(obj)
            deleteEntitySafe(obj)
            TriggerServerEvent('propremover:add', model, c.x, c.y, c.z)
            removed = removed + 1
        else
            break
        end
    end

    if removed > 0 then
        notify(locale('area_wipe_done', removed, name), 'success')
    else
        notify(locale('area_wipe_none', Config.AreaWipeRadius), 'error')
    end
end

--------------------------------------------------------------------
-- Maintenance loop: keep saved props deleted (they re-stream as you move)
--------------------------------------------------------------------
CreateThread(function()
    while true do
        local wait = Config.CleanupInterval
        local count = #removedProps
        if count > 0 then
            local pc = GetEntityCoords(PlayerPedId())
            for i = 1, count do
                local p = removedProps[i]
                if p and #(pc - vector3(p.x, p.y, p.z)) < Config.StreamDistance then
                    local obj = GetClosestObjectOfType(
                        p.x, p.y, p.z, Config.MatchRadius, p.model,
                        false, false, false
                    )
                    if obj and obj ~= 0 and DoesEntityExist(obj) then
                        SetEntityAsMissionEntity(obj, true, true)
                        DeleteEntity(obj)
                    end
                end
            end
        else
            wait = 2000
        end
        Wait(wait)
    end
end)

--------------------------------------------------------------------
-- Removal-mode UI: outline + label the prop you're aiming at
--------------------------------------------------------------------
CreateThread(function()
    while true do
        if removalMode then
            if lastOutlined and DoesEntityExist(lastOutlined) then
                SetEntityDrawOutline(lastOutlined, false)
            end
            lastOutlined = nil

            drawHelp(('REMOVAL MODE  |  [%s] remove  |  [%s] area-wipe  |  [%s] exit')
                :format(Config.DeleteKey, Config.AreaWipeKey, Config.ToggleKey))

            local hit, _, entity = aimRaycast(Config.RayDistance)
            if hit and entity and entity ~= 0 and DoesEntityExist(entity) and IsEntityAnObject(entity) then
                if Config.HighlightAimedProp then
                    SetEntityDrawOutline(entity, true)
                    SetEntityDrawOutlineColor(255, 40, 40, 255)
                    lastOutlined = entity
                end
                drawText3D(GetEntityCoords(entity), GetReadablePropName(GetEntityModel(entity)))
            end
            Wait(0)
        else
            if lastOutlined and DoesEntityExist(lastOutlined) then
                SetEntityDrawOutline(lastOutlined, false)
                lastOutlined = nil
            end
            Wait(400)
        end
    end
end)

--------------------------------------------------------------------
-- ox_lib management menu
--------------------------------------------------------------------
local function showHelp()
    lib.alertDialog({
        header   = locale('help_header'),
        content  = locale('help_body', Config.ToggleKey, Config.DeleteKey, Config.MenuKey, Config.AreaWipeKey),
        centered = true,
    })
end

local function teleportTo(p)
    local ped = PlayerPedId()
    SetEntityCoords(ped, p.x + 0.0, p.y + 0.0, p.z + 1.0, false, false, false, false)
    notify(locale('teleported'), 'success')
end

local function restoreOne(p)
    TriggerServerEvent('propremover:restoreOne', p.id)
    notify(locale('restored'), 'success')
end

local function openEntry(p)
    lib.registerContext({
        id    = 'propremover_entry',
        title = GetReadablePropName(p.model),
        menu  = 'propremover_list',
        options = {
            { title = locale('entry_teleport'), icon = 'location-arrow', onSelect = function() teleportTo(p) end },
            { title = locale('entry_restore'),  icon = 'rotate-left',    onSelect = function() restoreOne(p) end },
        },
    })
    lib.showContext('propremover_entry')
end

local function openRemovedList()
    local options = {}
    if #removedProps == 0 then
        options[1] = { title = locale('list_empty'), disabled = true }
    else
        for i = 1, #removedProps do
            local p = removedProps[i]
            local desc = ('%.1f, %.1f, %.1f'):format(p.x, p.y, p.z)
            if p.by   then desc = desc .. '  •  ' .. locale('entry_by', p.by) end
            if p.time then desc = desc .. '  •  ' .. p.time end
            options[#options + 1] = {
                title       = GetReadablePropName(p.model),
                description = desc,
                arrow       = true,
                onSelect    = function() openEntry(p) end,
            }
        end
    end
    lib.registerContext({
        id      = 'propremover_list',
        title   = locale('list_title'),
        menu    = 'propremover_main',
        options = options,
    })
    lib.showContext('propremover_list')
end

local function toggleMode()
    removalMode = not removalMode
    notify(removalMode and locale('mode_on') or locale('mode_off'),
           removalMode and 'success' or 'inform')
end

local function openMenu()
    lib.registerContext({
        id      = 'propremover_main',
        title   = locale('menu_title'),
        options = {
            { title = locale('menu_toggle_mode'),
              description = locale('menu_area_wipe_hint', Config.AreaWipeKey),
              icon = 'eye', onSelect = toggleMode },
            { title = locale('menu_removed_list', #removedProps),
              icon = 'trash-can', arrow = true, onSelect = openRemovedList },
            { title = locale('menu_help'), icon = 'circle-question', onSelect = showHelp },
        },
    })
    lib.showContext('propremover_main')
end

--------------------------------------------------------------------
-- Commands & keybinds
--------------------------------------------------------------------
RegisterCommand(Config.ToggleCommand, function()
    TriggerServerEvent('propremover:checkAdmin')  -- refresh status in case rank changed
    if not isAdmin then notify(locale('no_permission'), 'error') return end
    toggleMode()
end, false)
RegisterKeyMapping(Config.ToggleCommand, 'Toggle prop removal mode', 'keyboard', Config.ToggleKey)

RegisterCommand(Config.DeleteCommand, function()
    if not isAdmin then notify(locale('no_permission'), 'error') return end
    if removalMode then
        tryRemoveAimed()
    else
        notify(locale('enter_mode_first', Config.ToggleCommand, Config.ToggleKey), 'error')
    end
end, false)
RegisterKeyMapping(Config.DeleteCommand, 'Remove the prop you are aiming at', 'keyboard', Config.DeleteKey)

RegisterCommand(Config.MenuCommand, function()
    TriggerServerEvent('propremover:checkAdmin')
    if not isAdmin then notify(locale('no_permission'), 'error') return end
    openMenu()
end, false)
RegisterKeyMapping(Config.MenuCommand, 'Open the prop remover menu', 'keyboard', Config.MenuKey)

-- Area wipe (only does anything while in removal mode)
RegisterCommand('propareawipe', function()
    if not isAdmin then notify(locale('no_permission'), 'error') return end
    if removalMode then
        tryAreaWipe()
    else
        notify(locale('enter_mode_first', Config.ToggleCommand, Config.ToggleKey), 'error')
    end
end, false)
RegisterKeyMapping('propareawipe', 'Area-wipe the aimed prop model', 'keyboard', Config.AreaWipeKey)

RegisterCommand('undoprop', function()
    if not isAdmin then notify(locale('no_permission'), 'error') return end
    TriggerServerEvent('propremover:undo')
end, false)

RegisterCommand('clearprops', function()
    if not isAdmin then notify(locale('no_permission'), 'error') return end
    TriggerServerEvent('propremover:clear')
end, false)

RegisterCommand('prophelp', function()
    showHelp()
end, false)

--------------------------------------------------------------------
-- Sync with server
--------------------------------------------------------------------
RegisterNetEvent('propremover:sync', function(list)
    removedProps = list or {}
    -- keep an open list menu fresh if the player is looking at it
    if lib.getOpenContextMenu() == 'propremover_list' then
        openRemovedList()
    end
end)

RegisterNetEvent('propremover:setAdmin', function(state)
    isAdmin = state == true
end)

AddEventHandler('onClientResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    TriggerServerEvent('propremover:request')
end)
