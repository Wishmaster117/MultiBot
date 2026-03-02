# Milestone 7 — Final validation (Minimap / Options)

This document closes Milestone 7 for the **current options scope** and provides a reproducible in-game test protocol.

## 1) Options scope covered

Current options panel controls and their centralized persistence helpers:

- Minimap hide toggle -> `MultiBot.GetMinimapConfig` / `MultiBot.SetMinimapConfig` (`hide`).
- Minimap drag position (angle) -> `MultiBot.GetMinimapConfig` / `MultiBot.SetMinimapConfig` (`angle`).
- Global frame strata dropdown -> `MultiBot.GetGlobalStrataLevel` / `MultiBot.SetGlobalStrataLevel`.
- Timers sliders (`stats`, `talent`, `invite`, `sort`) -> `MultiBot.GetTimer` / `MultiBot.SetTimer`.
- Throttle sliders (`rate`, `burst`) -> `MultiBot.GetThrottleRate` / `MultiBot.SetThrottleRate`, `MultiBot.GetThrottleBurst` / `MultiBot.SetThrottleBurst`.

## 2) Remaining non-migrated options

At this time, no additional controls are exposed in `UI/MultiBotOptions.lua` outside the scope listed above.

If new controls are added to the options panel in the future, they must be wired to centralized helpers in `Core/MultiBot.lua`/`Core/MultiBotConfig.lua` (no UI-local persistence branch).

## 3) In-game validation protocol (manual)

> Run on a character with MultiBot enabled. Do all checks on a clean `/reload`, then on relog.

### A. Minimap visibility + angle

1. Open options with `/mbopt`.
2. Toggle "hide minimap button" ON.
3. `/reload`.
4. Expected: minimap button stays hidden.
5. Toggle OFF, drag minimap button to a new angle.
6. `/reload` then relog.
7. Expected: button remains visible and keeps the dragged angle.

### B. Global frame strata

1. Open `/mbopt`.
2. Change "Frame Strata" (e.g. HIGH -> DIALOG).
3. Open several MultiBot windows (main bar + any child windows).
4. Expected: strata change is applied consistently.
5. `/reload` then relog.
6. Expected: selected strata persists.

### C. Timers sliders

1. Open `/mbopt`.
2. Set non-default values for `stats`, `talent`, `invite`, `sort`.
3. Close/reopen options.
4. Expected: slider values are unchanged.
5. `/reload` then relog.
6. Expected: values persist.

### D. Throttle sliders

1. Open `/mbopt`.
2. Set non-default values for `rate` and `burst`.
3. Close/reopen options.
4. Expected: values are unchanged.
5. `/reload` then relog.
6. Expected: values persist.

### E. DelSV safety

1. Trigger DelSV from GM UI and confirm.
2. Addon reloads automatically.
3. Expected immediately after reload: options are reset to defaults.
4. Relog.
5. Expected: reset is still effective (no old runtime state restored by forced logout-save path).

## 4) Acceptance criteria to keep Milestone 7 closed

- All checks A-E pass on `/reload` and relog.
- No duplicated persistence logic is introduced in UI files.
- New options (if any) must use centralized helpers only.
## 5) Exhaustive Lua audit reference

- Exhaustive classification matrix (77/77 Lua files): `docs/milestone-7-audit-77x77.md`.
- This matrix must be updated if a new Lua file is added or if options/minimap persistence code is moved.