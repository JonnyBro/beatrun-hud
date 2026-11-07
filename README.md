# Beatrun Weapon HUD

Rewrite of UnderSet's [beatrunhud](https://gitlab.com/UnderSet/beatrunhud) using BeatrunUI.

Made for the [Beatrun](https://github.com/JonnyBro/beatrun) gamemode, but works in any gamemode. Outside of Beatrun it keeps the same look and takes its colors from the GMod player and weapon colors.

## Features

- Ammo counter in the bottom right corner, styled after the Beatrun level panel: magazine, reserve, overfill (`+1`) and firemode
- Underbarrel / altfire panel that dims when not in use
- Low ammo and empty reserve pulse in the accent color
- Firemode and underbarrel key hints
- Optional health and armor panel in the bottom left corner, with stims and armor plates when supported
- Panels size themselves to their content
- Weapon base support: ARC9, ArcCW, MW Base, TFA, Sandstorm SWEPs (magazine-based reserve), regular SWEPs and HL2 weapons (bottomless clip, infinite ammo, jams, safety, extended magazines)
- Respects `SWEP:CustomAmmoDisplay` and `SWEP:Ammo1`, and adapts to SWEPs that report a wrong magazine size
- English and Russian localization

## Beatrun and other gamemodes

|               | Beatrun                                                      | Other gamemodes                                     |
| ------------- | ------------------------------------------------------------ | --------------------------------------------------- |
| Panel color   | `Beatrun_HUDCornerColor`                                     | `cl_playercolor`                                    |
| Text color    | `Beatrun_HUDTextColor`                                       | White                                               |
| Bar color     | `Beatrun_HUDTextColor`                                       | `cl_weaponcolor`                                    |
| Sway, dynamic | `Beatrun_HUDSway`, `Beatrun_HUDDynamic`                      | `Beatrun_AmmoHUDSway`, `Beatrun_AmmoHUDDynamic`     |
| Hiding        | `Beatrun_HUDHidden`, build mode, large menus                 | Camera and `HUDShouldDraw`                          |
| Health panel  | Above the level panel                                        | Bottom left corner, replaces the HL2 one            |
| Settings      | BeatrunUI window                                             | Derma window and Utilities → User in the spawn menu |

## Settings

Open with `beatrun_hud_settings` or from the context menu (C) → Beatrun HUD.

| ConVar                   | Default | Description                                    |
| ------------------------ | ------- | ---------------------------------------------- |
| `Beatrun_AmmoHUD`        | `1`     | Show the ammo counter                          |
| `Beatrun_AmmoHUDKeys`    | `1`     | Show firemode and underbarrel key hints        |
| `Beatrun_AmmoHUDHealth`  | `0`     | Show the health and armor panel                |
| `Beatrun_AmmoHUDSway`    | `1`     | HUD sway (outside of Beatrun)                  |
| `Beatrun_AmmoHUDDynamic` | `0`     | Fade the HUD while moving (outside of Beatrun) |

## Servers

Clients receive the Lua files automatically. Localization, the font and the health and armor icons are sent with `resource.AddSingleFile`, which requires FastDL or `sv_allowdownload`; players who subscribe to the addon don't need it.

## Credits

- [UnderSet/beatrunhud](https://gitlab.com/UnderSet/beatrunhud) - the original HUD this is forked from.
