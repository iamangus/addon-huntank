# HunTank

A deliberately small WoW Forever addon: it shows **your threat percentage on each enemy nameplate**.

No bars, no threat window, no sorting, no automatic targeting, no pet control. Just the number, on the mob.

```
        Darkhound
  [██████████████]  85%
```

## Requirements

- World of Warcraft: Forever, interface `16001`
- Enemy nameplates enabled (`Ctrl+V`, or **Options → Nameplates → Show Enemy Nameplates**)

## Install with WoWUp

Add this repository as a GitHub source:

```
https://github.com/iamangus/addon-huntank
```

WoWUp installs the release zip and keeps it updated. The addon folder is `HunTank`.

Manual install: download the latest `HunTank-*-forever.zip`, unpack the `HunTank` folder into `World of Warcraft\_forever_\Interface\AddOns\` (or the Forever addon folder used by your install), then restart the client.

The `-forever` suffix is required by WoWUp's Forever provider.

## Commands

| Command | Meaning |
| --- | --- |
| `/ht` or `/ht help` | Show commands |
| `/ht on` / `/ht off` | Enable or disable |
| `/ht pos right\|left\|above\|below` | Placement around the nameplate |
| `/ht size 8-32` | Font size |
| `/ht color rrggbb` | Text color, e.g. `ffcc00` |
| `/ht outofcombat` | Show while out of combat too |
| `/ht status` | Show current settings |
| `/ht reset` | Restore defaults |

Defaults: on, right of the health bar, size 12, gold, combat only.

## What it does and does not do

It asks `UnitDetailedThreatSituation("player", nameplateUnit)` for your scaled threat percentage and displays it. On Forever those values are secret: the engine can format and display them, but addon code cannot read or compare them.

That is why this addon does **not**:

- sort nameplates by threat,
- highlight the highest or lowest,
- choose a target for you,
- send your pet at anything.

Those decisions stay with you. This addon only puts the number where you need it.

## Notes

- Threat data is per mob. A percentage below 100% means the mob's current target is ahead of you; 100% means it is on you.
- If you are not on a mob's threat table, the number is blank.
- In dungeons and raids the client may hide threat values for some units; those nameplates will stay blank.
- It does not replace or restyle Blizzard's nameplates. It only adds a font string to each plate.

## Changelog

- **0.1.1** — re-anchor the text to Blizzard's health bar once the nameplate exposes it, so it lines up with the bar instead of the whole plate.

## Development

Package a release:

```
./scripts/package.sh
```

The zip is written to `dist/HunTank-<version>-forever.zip` with `HunTank/` at the root, ready for WoWUp.

Release workflow: push a tag matching the TOC version, e.g. `v0.1.0`. GitHub Actions builds the zip and attaches it to the release.
