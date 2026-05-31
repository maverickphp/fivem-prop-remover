Config = {}

-- Current resource version (used by the update checker, see bottom).
Config.Version = '2.0.0'

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
Config.AllowedGroups = { 'admin' }

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

Config.DeleteCommand = 'removeprop'    -- delete the prop you're aiming at
Config.DeleteKey     = 'DELETE'

Config.MenuCommand   = 'propmenu'      -- open the ox_lib management menu
Config.MenuKey       = 'F11'

Config.AreaWipeKey   = 'HOME'          -- (while in removal mode) wipe all of the
                                       --  aimed model within AreaWipeRadius
Config.AreaWipeRadius = 5.0            -- meters

-- Admin-only chat/console commands:
--   /undoprop    un-saves the most recent removal
--   /clearprops  un-saves ALL removals
--   /prophelp    show the controls

-- ============================================================
--  TUNING
-- ============================================================
Config.RayDistance     = 30.0   -- aim raycast reach (meters)
Config.MatchRadius     = 1.5    -- search radius when re-finding a saved prop
Config.CleanupInterval = 750    -- ms between "re-delete saved props near me" passes
Config.StreamDistance  = 300.0  -- only delete saved props within this distance of you

Config.HighlightAimedProp = true -- red outline on the prop you're aiming at

-- ============================================================
--  LOCALE
--  Translations live in  locales/<code>.json  (ox_lib locale system)
--  Bundled: 'en', 'fr', 'de', 'es', 'pt-br', 'it'
-- ============================================================
Config.Locale = 'en'

-- ============================================================
--  UPDATE CHECKER
--  On start, the server compares Config.Version to the latest GitHub
--  release tag and prints to console if a newer one exists.
-- ============================================================
Config.CheckUpdates = true
Config.GithubRepo   = 'maverickphp/fivem-prop-remover'
