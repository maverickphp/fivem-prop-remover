--======================================================================
--  shared.lua
--  Builds a reverse lookup (model hash -> readable name) from PropNames.
--  Runs on BOTH client and server (GetHashKey exists on both), so labels,
--  the management menu, and console logs can all show readable names.
--======================================================================

local hashToName = {}

if PropNames then
    for i = 1, #PropNames do
        local name = PropNames[i]
        -- GetHashKey returns the same signed representation as GetEntityModel,
        -- so the keys line up at lookup time.
        hashToName[GetHashKey(name)] = name
    end
end

--- Returns a readable model name for a hash, or the hash as a string if unknown.
---@param model number
---@return string
function GetReadablePropName(model)
    if type(model) ~= 'number' then return tostring(model) end
    return hashToName[model] or tostring(model)
end
