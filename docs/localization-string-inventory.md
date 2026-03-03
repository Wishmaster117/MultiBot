# Localization String Inventory (Milestone 9 kickoff)

Initial inventory of user-facing hardcoded strings in `Core/`, `UI/`, and `Features/`.

## Method

- Commands used:
  - `rg -n 'SetText\(|tooltipText\s*=|AddLine\(|SendChatMessage\("' Core UI Features`
  - `rg -n 'MultiBot\.L\(\s*"[^"]+"\s*,' Core UI Features`
- Manual filtering was applied to keep only strings visible to users (panel labels, tooltips, tab labels, placeholders).

## Priority candidates

### UI

- `UI/MultiBotOptions.lua`
- Existing options labels/tooltips now route through locale keys without inline fallbacks in runtime call sites.
- `UI/MultiBotPVPUI.lua`
  - PvP panel labels now route through locale keys, with inline fallback duplicates removed in UI call sites.
  - Remaining direct `MultiBot.tips.*` reference (`pvparenanoteamrank`) has been migrated to `MultiBot.L("tips.every.pvparenanoteamrank")`.

### Core

- `Core/MultiBotThrottle.lua`
  - Runtime fallback literal removed from throttle installation message; call site now uses locale key only.
- `Core/MultiBotInit.lua`
  - Runtime localization reads in this file now use `MultiBot.L(...)` key lookups (including previous `MultiBot.tips.*` table reads migrated to locale keys).

### Features

- `Features/MultiBotReward.lua`
  - Whisper command construction is command protocol text, not user-facing labels.
  - No direct panel label migration performed in this kickoff.

## Inline fallback scan snapshot (current)

- Current scan result for `Core/UI/Features`:
  - `rg -n 'MultiBot\.L\(\s*"[^"]+"\s*,' Core UI Features`
  - No remaining `MultiBot.L(key, fallback)` call sites in these directories.

## Legacy tips-read scan snapshot (current)

- Focused scan for legacy table reads:
  - `rg -n 'MultiBot\.tips' Core UI Features`
- Current status:
  - `Core/MultiBotInit.lua`: migrated.
  - `UI/MultiBotPVPUI.lua`: migrated.
  - Remaining major target: `Features/MultiBotRaidus.lua`.


## Pipeline decisions in this kickoff

- Added a centralized locale access helper (`MultiBot.GetLocaleString` / `MultiBot.L`) with deterministic fallback order:
  1. Active AceLocale table
  2. Registered `enUS` defaults
  3. Per-call fallback string
  4. Locale key itself
- Added dedicated AceLocale registration file (`Locales/MultiBotAceLocale.lua`) to start new keys without rewriting legacy locale files.

## Next milestone-9 increments

1. Remove duplicate inline fallback literals in `UI/MultiBotPVPUI.lua` now that stable locale keys are in place. *(completed in latest increment)*
2. Continue migrating inline fallbacks in Core call sites (`Core/MultiBotInit.lua`, `Core/MultiBotThrottle.lua`) where locale keys are already stable.
3. Expand key coverage locale-by-locale while keeping deterministic fallback behavior.