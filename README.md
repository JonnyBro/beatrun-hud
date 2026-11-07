# Beatrun Weapon HUD

Rewrite of UnderSet's [beatrunhud](https://gitlab.com/UnderSet/beatrunhud) using BeatrunUI.

Requires the [Beatrun](https://github.com/JonnyBro/beatrun) gamemode. In other gamemodes the HUD isn't drawn and the default HL2 ammo counter is left alone.

## Features

- Ammo counter in the bottom right corner, styled after the Beatrun level panel: magazine, reserve, overfill (`+1`) and firemode
- Underbarrel / altfire panel that dims when not in use
- Low ammo and empty reserve pulse in the Beatrun accent color
- Firemode and underbarrel key hints
- Optional health and armor panel above the level panel, with stims and armor plates when supported
- Weapon base support: ARC9, ArcCW, MW Base, TFA, regular SWEPs and HL2 weapons (bottomless clip, infinite ammo, jams, safety)
- Follows the Beatrun HUD settings: text and corner colors, sway, dynamic and hidden modes; hides in build mode and behind large menus
- Settings window made with BeatrunUI
- English and Russian localization

## Settings

Open with `beatrun_hud_settings` or from the context menu (C) → Beatrun HUD.

| ConVar                  | Default | Description                             |
| ----------------------- | ------- | --------------------------------------- |
| `Beatrun_AmmoHUD`       | `1`     | Show the ammo counter                   |
| `Beatrun_AmmoHUDKeys`   | `1`     | Show firemode and underbarrel key hints |
| `Beatrun_AmmoHUDHealth` | `0`     | Show the health and armor panel         |

Colors, sway and visibility are taken from Beatrun (`Beatrun_HUDTextColor`, `Beatrun_HUDCornerColor`, `Beatrun_HUDSway`, `Beatrun_HUDDynamic`, `Beatrun_HUDHidden`).

## Credits

- [UnderSet/beatrunhud](https://gitlab.com/UnderSet/beatrunhud) - Forked from here.
