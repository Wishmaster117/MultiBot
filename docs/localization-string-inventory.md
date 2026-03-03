# Localization String Inventory (Milestone 9 kickoff)

Initial inventory of user-facing hardcoded strings in `Core/`, `UI/`, and `Features/`.

## Method

- Command used:
  - `rg -n 'SetText\(|tooltipText\s*=|AddLine\(|SendChatMessage\("' Core UI Features`
- Manual filtering was applied to keep only strings visible to users (panel labels, tooltips, tab labels, placeholders).

## Priority candidates

### UI

- `UI/MultiBotOptions.lua`
  - `"Frame Strata"` (migrated to `MultiBot.L("options.frame_strata")`).
- `UI/MultiBotPVPUI.lua`
  - `"MultiBot PvP Panel"` (migrated to `MultiBot.L("options.pvp.title")`).
  - Remaining literals to migrate in a next pass:
    - `"Bot"`
    - `"Honneur"`
    - `"Arène"`
    - `"JcJ"`
    - `"Dummy tab (placeholder)"`

### Core

- `Core/MultiBotInit.lua`
  - Tooltip and fallback strings still use inline literals in a few blocks.
  - Several comments are in French and do not impact runtime localization, but user-facing fallback text should be routed through locale keys in a dedicated pass.

### Features

- `Features/MultiBotReward.lua`
  - Whisper command construction is command protocol text, not user-facing labels.
  - No direct panel label migration performed in this kickoff.

## Pipeline decisions in this kickoff

- Added a centralized locale access helper (`MultiBot.GetLocaleString` / `MultiBot.L`) with deterministic fallback order:
  1. Active AceLocale table
  2. Registered `enUS` defaults
  3. Per-call fallback string
  4. Locale key itself
- Added dedicated AceLocale registration file (`Locales/MultiBotAceLocale.lua`) to start new keys without rewriting legacy locale files.

## Next milestone-9 increments

1. Migrate remaining obvious UI literals in `UI/MultiBotPVPUI.lua`.
2. Migrate options/subpanel labels that still use inline text.
3. Expand key coverage locale-by-locale while keeping deterministic fallback behavior.