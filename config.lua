Config = {}

-- ============================================================
--  WHO CAN REMOVE PROPS
--  PermissionMode decides how admin status is checked:
--     'esx'    -> uses the player's ESX group  (DEFAULT for you)
--     'qbcore' -> uses QBCore.Functions.HasPermission
--     'ace'    -> uses a FiveM ACE permission (framework-free)
-- ============================================================
Config.PermissionMode = 'esx'

-- The group(s)/permission(s) allowed to remove props.
-- ESX groups:    'user', 'mod', 'admin', 'superadmin'
-- QBCore levels: 'user', 'mod', 'admin', 'god'
-- You chose TOP RANK ONLY -> superadmin.
Config.AllowedGroups = { 'superadmin' }

-- Only used when PermissionMode = 'ace'
-- (add to server.cfg:  add_ace group.admin propremover.manage allow)
Config.AcePermission = 'propremover.manage'

-- Resource names of your framework (change only if yours are renamed)
Config.ESXResource    = 'es_extended'
Config.QBCoreResource = 'qb-core'

-- ============================================================
--  CONTROLS  (only work for allowed admins)
-- ============================================================
Config.ToggleCommand = 'propremover'   -- toggle removal mode
Config.ToggleKey     = 'F10'

Config.DeleteCommand = 'removeprop'     -- delete the prop you're aiming at
Config.DeleteKey     = 'DELETE'

-- Admin-only chat/console commands:
--   /undoprop    un-saves the most recent removal (returns when area reloads)
--   /clearprops  un-saves ALL removals

-- ============================================================
--  TUNING
-- ============================================================
Config.RayDistance     = 30.0   -- aim raycast reach (meters)
Config.MatchRadius     = 1.5    -- search radius when re-finding a saved prop
Config.CleanupInterval = 750    -- ms between "re-delete saved props near me" passes
Config.StreamDistance  = 300.0  -- only delete saved props within this distance of you

Config.HighlightAimedProp = true -- red outline on the prop you're aiming at