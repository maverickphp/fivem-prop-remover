--======================================================================
--  prop_remover - client.lua
--  Map/world props aren't networked, so deletion must run on each client.
--  The server sends us the saved "kill list" and we keep these props gone.
--======================================================================

local removedProps = {}      -- synced from server: { {model=hash, x=, y=, z=}, ... }
local removalMode  = false
local lastOutlined = nil
local isAdmin      = false   -- set by the server; gates the menu/commands

--------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------
local function notify(msg)
    SetNotificationTextEntry('STRING')
    AddTextComponentSubstringPlayerName('[Prop Remover] ' .. msg)
    DrawNotification(false, true)
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
        notify('Nothing in your crosshair. Aim directly at the prop.')
        return
    end
    if not IsEntityAnObject(entity) then
        notify('That is not a world prop (looks like a ped or vehicle).')
        return
    end

    local model  = GetEntityModel(entity)
    local coords = GetEntityCoords(entity)

    deleteEntitySafe(entity)                                   -- instant local feedback
    TriggerServerEvent('propremover:add', model, coords.x, coords.y, coords.z)
    notify(('Removed prop %s and saving it permanently...'):format(model))
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

            drawHelp(('REMOVAL MODE  |  aim + [%s] to remove  |  [%s] to exit')
                :format(Config.DeleteKey, Config.ToggleKey))

            local hit, _, entity = aimRaycast(Config.RayDistance)
            if hit and entity and entity ~= 0 and DoesEntityExist(entity) and IsEntityAnObject(entity) then
                if Config.HighlightAimedProp then
                    SetEntityDrawOutline(entity, true)
                    SetEntityDrawOutlineColor(255, 40, 40, 255)
                    lastOutlined = entity
                end
                drawText3D(GetEntityCoords(entity), ('Model: %s'):format(GetEntityModel(entity)))
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
-- Commands & keybinds
--------------------------------------------------------------------
RegisterCommand(Config.ToggleCommand, function()
    TriggerServerEvent('propremover:checkAdmin')  -- refresh status in case rank changed
    if not isAdmin then
        notify('You do not have permission to use this.')
        return
    end
    removalMode = not removalMode
    notify(removalMode and 'Removal mode ON' or 'Removal mode OFF')
end, false)
RegisterKeyMapping(Config.ToggleCommand, 'Toggle prop removal mode', 'keyboard', Config.ToggleKey)

RegisterCommand(Config.DeleteCommand, function()
    if not isAdmin then
        notify('You do not have permission to use this.')
        return
    end
    if removalMode then
        tryRemoveAimed()
    else
        notify(('Enter removal mode first (%s / press %s).'):format(Config.ToggleCommand, Config.ToggleKey))
    end
end, false)
RegisterKeyMapping(Config.DeleteCommand, 'Remove the prop you are aiming at', 'keyboard', Config.DeleteKey)

RegisterCommand('undoprop', function()
    if not isAdmin then notify('You do not have permission to use this.') return end
    TriggerServerEvent('propremover:undo')
end, false)

RegisterCommand('clearprops', function()
    if not isAdmin then notify('You do not have permission to use this.') return end
    TriggerServerEvent('propremover:clear')
end, false)

--------------------------------------------------------------------
-- Sync with server
--------------------------------------------------------------------
RegisterNetEvent('propremover:sync', function(list)
    removedProps = list or {}
end)

RegisterNetEvent('propremover:setAdmin', function(state)
    isAdmin = state == true
end)

AddEventHandler('onClientResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    TriggerServerEvent('propremover:request')
end)