# MultiBot ACE3 Migration Roadmap (Updated)

## Current Status Snapshot

- **Milestone 1 (Baseline / safety net):** In progress.
  - Baseline behavior is mostly known through manual validation.
  - Migration checklist is tracked in `docs/ace3-migration-checklist.md` and must be updated per PR.
- **Milestone 2 (Add ACE3 libs):** Completed.
  - ACE3 libraries are loaded in `MultiBot.toc`.
- **Milestone 3 (Initialization lifecycle):** Mostly completed, hardening pending.
  - `OnInitialize` and `OnEnable` are in place.
  - Legacy frame-based startup/event code still exists in a few places.
- **Milestone 4 (Command system):** Completed.
  - Central alias registration is used for core commands via `RegisterCoreCommandsOnce` in lifecycle init.
  - Runtime command invocation paths are centralized through `RunRegisteredCommand` (slash + minimap click + helper dispatch).
- **Milestone 5 (Event bus migration):** Completed.
  - Dispatcher architecture drives core/quick-bar/UI whisper flows.
  - Legacy `CreateFrame + RegisterEvent + SetScript` listener blocks have been removed from addon runtime paths.
- **Milestone 6 (SavedVariables -> AceDB):** Functionally completed for runtime data paths; controlled legacy deprecation policy still pending.
  - AceDB bootstrap and migration helpers are in place and actively used across migrated features (global bot store, frame positions, quick-bar class states, Raidus layouts/main-bar state, timers/config branches).
  - One-way versioned cutover is now established for migrated paths, with compatibility fallbacks kept intentionally during transition.
  - Remaining work is now policy/documentation driven (legacy SavedVariables retention window and purge criteria), not core runtime wiring.
- **Milestone 7 (Minimap/options integration):** Completed for current options scope.
  - Options panel controls are now centralized on AceDB-backed helpers: timers (`Get/SetTimer`), throttle (`Get/SetThrottleRate`, `Get/SetThrottleBurst`), minimap (`Get/SetMinimapConfig`) and global frame strata (`Get/SetGlobalStrataLevel`).
  - Minimap hide/angle, global frame strata, spec dropdown position, hunter pet stance, shaman totems, quick-frame positions, Raidus layout slots, mainbar/layout state, Raidus sort-mode, Raidus selected-slot, and Raidus pool-page persistence are migrated to AceDB-backed storage with one-way compatibility cutover; spec dropdown, Raidus layout, mainbar/layout persistence, Raidus roster store reads, Raidus sort-mode, Raidus selected-slot, and Raidus pool-page now go through centralized core helpers (including page normalization write-back when pool-size shrinks), and the Raidus feature now calls core layout helpers directly (UI/features/handler no longer carry local migration blocks or local layout/sort wrapper shims for these paths); mainbar/layout handler path and spec-dropdown UI path now call core persistence helpers directly as well.
  - Saved-state reset flow clears both AceDB profile runtime state and legacy SavedVariables tables through a centralized helper used by DelSV, and DelSV suppresses the immediate logout-save pass during ReloadUI to prevent old runtime state from being re-written.
  - Current in-game validation protocol for Milestone 7 is documented in `docs/milestone-7-final-validation.md` and the exhaustive 77/77 Lua matrix `docs/milestone-7-audit-77x77.md`.
- **Milestone 8 (AceGUI UI refactor):** Not started.

---

## Execution Plan to Completion

## Phase A — Close lifecycle + command + event gaps

### A1. Lifecycle hardening
1. Keep `OnInitialize` / `OnEnable` as the single startup path.
2. Move remaining startup side effects behind lifecycle-safe guards.
3. Ensure no duplicate initialization on reload/login.

**Exit criteria**
- No duplicate startup behavior.
- No extra event registrations after repeated reloads.

### A2. Command system finalization
1. Keep `RegisterCommandAliases` as the only command registration API.
2. Remove scattered direct slash registrations if any remain.
3. Preserve all current aliases and behavior.

**Exit criteria**
- `/multibot`, `/mbot`, `/mb`, `/mbopt`, `/mbclass`, `/mbclasstest` unchanged.

### A3. Event convergence
1. Keep `DispatchEvent` / `DispatchUpdate` as central dispatch points.
2. Gradually migrate remaining local frame-event blocks into centralized registration.
3. Validate high-frequency paths for duplicate callback regressions.

**Exit criteria**
- No duplicated callbacks.
- No observable event spam regression.

---

## Phase B — SavedVariables migration to AceDB

### B1. Introduce AceDB schema (non-breaking)
1. Add `MultiBot.db = AceDB:New(...)` with defaults equivalent to current settings.
2. Keep legacy variables readable during transition.

### B2. One-way migration from legacy storage
1. Migrate old keys once (timers, throttle, minimap, visibility, strata, favorites).
2. Mark migration version to avoid repeated imports.

### B3. Switch runtime reads/writes to AceDB
1. Move runtime config access to AceDB first.
2. Keep temporary fallback reads for one transition cycle.

**Exit criteria**
- Existing users retain settings.
- Fresh installs use AceDB defaults.

---

## Phase C — Minimap/options and optional UI modernization

### C1. Minimap/options stabilization
1. Keep current options UI intact.
2. Connect minimap/options persistence fully to AceDB.
3. Optionally add LibDBIcon integration without behavior changes.

**Exit criteria**
- Minimap toggle and options panel behavior unchanged for users.

### C2. Optional AceGUI refactor (last)
1. Migrate one screen at a time.
2. Keep data/control flow equivalent for each migrated screen.
3. Avoid big-bang rewrites.

**Exit criteria**
- Screen-by-screen functional parity before moving forward.

---

## PR Order

1. Lifecycle hardening.
2. Command system finalization.
3. Event convergence.
4. AceDB bootstrap.
5. Legacy -> AceDB one-way migration.
6. Runtime switch to AceDB.
7. Minimap/options persistence finalization.
8. Optional per-screen AceGUI refactor.

---

## Risk Controls (Apply on every PR)

- Keep changes localized and incremental.
- Avoid duplicate helper logic.
- Prefer reusing existing APIs/functions over adding new parallel paths.
- Validate no duplicate event registration and no repeated side effects on reload.
- Keep behavior identical unless explicitly planned and documented.