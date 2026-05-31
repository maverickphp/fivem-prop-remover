# fivem-prop-remover

> Admin-only, server-persistent world-prop remover for FiveM. Aim at an unwanted map prop, press a key, and it's gone — for **every** player, **permanently**, surviving restarts.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![FiveM](https://img.shields.io/badge/FiveM-resource-orange)
![Framework](https://img.shields.io/badge/framework-ESX%20%7C%20QBCore%20%7C%20Standalone-blue)

---

## What it does

Map/world props (a floating BBQ grill, a misplaced bench, leftover MLO clutter) aren't networked entities — every player streams them locally from the map data. That means there's **no pure server-side native** that can delete them once for everyone.

This resource solves that with the only architecture that actually works:

1. An admin aims at a prop in-game and deletes it.
2. The removal (model + coordinates) is sent to the server, where the admin's rank is **verified server-side**.
3. The server saves it to a JSON file and pushes the "kill-list" to **every connected client**.
4. On join and on every restart, the list is re-synced, so the prop stays gone for everyone forever.

A lightweight client loop re-deletes saved props as the map re-streams them, so they don't pop back when players walk away and return.

## Features

- 🎯 **Aim-and-delete** — raycast from your camera, with a red outline + live model hash on whatever you're looking at.
- 🔒 **Server-authoritative permissions** — every removal is validated on the server. Non-admins are rejected even if they tamper with the client.
- 💾 **Permanent & global** — saved to JSON, synced to all players, survives restarts.
- 🧩 **Framework-agnostic** — ESX, QBCore, or standalone (ACE permissions). Switch with one config line.
- ♻️ **Re-stream proof** — maintenance loop keeps deleted props gone as the world reloads.
- ↩️ **Undo / clear** — `/undoprop` and `/clearprops` admin commands.
- 🛟 **Fallback for stubborn props** — if `DeleteEntity` refuses (some MLO-embedded props), the prop is shoved far under the map so it's out of sight.

## Requirements

- A FiveM server (artifact build with `fx_version 'cerulean'` or newer).
- One of: **ESX**, **QBCore**, or nothing (standalone via ACE).

## Installation

1. Download or clone this repo into your server's `resources/` directory. The folder name **becomes the resource name** — keep it simple:

   ```bash
   cd resources
   git clone https://github.com/maverickphp/fivem-prop-remover.git prop_remover
   ```

   (Or drop the unzipped folder in manually and rename it to `prop_remover`.)

2. Add it to your `server.cfg`:

   ```cfg
   ensure prop_remover
   ```

   > **ESX/QBCore:** make sure this line comes **after** `ensure es_extended` / `ensure qb-core`.

3. Configure permissions in [`config.lua`](config.lua) (see below). For **ACE / standalone** mode only, also add to `server.cfg`:

   ```cfg
   add_ace group.admin propremover.manage allow
   add_principal identifier.fivem:YOUR_ID group.admin
   ```

4. Restart the server (or `ensure prop_remover` from the console).

## Configuration

All settings live in [`config.lua`](config.lua). The important ones:

```lua
-- How admin status is checked: 'esx' | 'qbcore' | 'ace'
Config.PermissionMode = 'esx'

-- Who is allowed to remove props.
--   ESX groups:    'user', 'mod', 'admin', 'superadmin'
--   QBCore levels: 'user', 'mod', 'admin', 'god'
Config.AllowedGroups = { 'superadmin' }

-- Only used when PermissionMode = 'ace'
Config.AcePermission = 'propremover.manage'
```

| Setting | Default | Description |
|---------|---------|-------------|
| `Config.PermissionMode` | `'esx'` | `esx`, `qbcore`, or `ace` |
| `Config.AllowedGroups` | `{ 'superadmin' }` | Groups/levels allowed to remove props |
| `Config.ToggleKey` | `F10` | Toggle removal mode |
| `Config.DeleteKey` | `DELETE` | Delete the prop you're aiming at |
| `Config.RayDistance` | `30.0` | Aim raycast reach (meters) |
| `Config.CleanupInterval` | `750` | ms between re-delete passes |
| `Config.StreamDistance` | `300.0` | Only re-delete saved props within this range |

**Quick framework swap:**

- **ESX, admins too:** `Config.AllowedGroups = { 'superadmin', 'admin' }`
- **QBCore:** `Config.PermissionMode = 'qbcore'` and `Config.AllowedGroups = { 'god' }`
- **Standalone:** `Config.PermissionMode = 'ace'`

## Usage

1. Press **F10** (or type `/propremover`) to enter removal mode. You'll see an on-screen banner, and any prop you look at gets a red outline + its model hash.
2. Aim directly at the unwanted prop and press **DELETE** (or `/removeprop`). It vanishes instantly and is saved server-side.
3. Press **F10** again to exit.

It's now gone for every player and stays gone after restarts.

| Command | Who | Action |
|---------|-----|--------|
| `/propremover` (F10) | admin | Toggle removal mode |
| `/removeprop` (DELETE) | admin | Remove the prop you're aiming at |
| `/undoprop` | admin | Un-save the most recent removal |
| `/clearprops` | admin | Un-save **all** removals |

## How removal behaves

When you delete a prop, one of three things happens — and each tells you what kind of prop it is:

- **Gone and stays gone** → it was a standalone ymap world prop. Done.
- **Flickers back briefly when you move away and return** → working as intended; the map re-streams it and the cleanup loop re-deletes it. Lower `Config.CleanupInterval` for snappier re-removal.
- **Doesn't delete / drops under the map** → it's an MLO-embedded or locked LOD prop. The under-map fallback hides it; a truly locked prop needs a [CodeWalker](https://github.com/dexyfex/CodeWalker) `.ymap` edit instead.

## Troubleshooting

- **"You do not have permission"** — your account isn't in `Config.AllowedGroups`. For ESX, confirm your group with your admin tooling; for ACE, check your `add_principal` line.
- **Resource won't start** — ensure it loads *after* your framework in `server.cfg`.
- **Nothing in crosshair** — aim *directly* at the prop and get within `Config.RayDistance` meters.
- **Prop keeps coming back** — it's re-streaming. Confirm the cleanup loop is running (the prop should flicker out within `Config.CleanupInterval` ms). If it never goes, it's likely a locked map prop needing a CodeWalker edit.

## License

[MIT](LICENSE) © [maverickphp](https://github.com/maverickphp)
