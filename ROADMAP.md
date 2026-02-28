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
- **Milestone 4 (Command system):** Mostly completed.
  - Central alias registration exists and is used for core commands.
- **Milestone 5 (Event bus migration):** Completed.
  - Dispatcher architecture drives core/quick-bar/UI whisper flows.
  - Legacy `CreateFrame + RegisterEvent + SetScript` listener blocks have been removed from addon runtime paths.
- **Milestone 6 (SavedVariables -> AceDB):** In progress.
  - AceDB bootstrap is now initialized for config timers/throttle + main UI/main bar state + layout memory + favorites + Raidus slot/layout persistence with legacy fallback; Raidus roster sorting path has been simplified (table.sort) and layout apply now uses indexed pool lookup to reduce repeated scans and Raidus group/slot sizing now uses shared constants and pool page navigation now uses a shared refresh helper/page-size constant, and auto-balance sizing/layout initialization now reuse shared constants/helpers, and Raidus slot traversal/serialization now use shared helpers and apply/invite flows now reuse shared helper routines without behavior change.
- **Milestone 7 (Minimap/options integration):** Partially completed.
  - Minimap hide/angle and global frame strata now use AceDB profile with legacy compatibility; broader options persistence remains.
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