# ACE3 Expansion Checklist (Post-M7)

Checklist for the full addon-wide ACE3 expansion after M7 completion.

## Scope and Principles

- [ ] Keep behavior parity first (no feature redesign during migration PRs).
- [ ] Reuse existing helpers before introducing new APIs.
- [ ] Avoid legacy table creation on read paths unless explicitly required.
- [ ] Keep PRs localized per subsystem/screen.

---

## Milestone 8 — AceGUI UI refactor

- [x] Inventory all legacy frame-based screens and map migration order.
  - Source of truth: `docs/ace3-ui-frame-inventory.md` (update per M8 PR).
- [ ] Migrate one screen at a time to AceGUI containers/widgets.
- [x] Options panel content migrated to AceGUI widgets (`UI/MultiBotOptions.lua`) while keeping InterfaceOptions category + slash entrypoint behavior.
- [x] Temporary shared migration debug helper introduced (`Core/MultiBotDebug.lua`) to avoid duplicated diagnostics across files.
- [x] PVP window migration slice completed for targeted controls (`UI/MultiBotPVPUI.lua`: bot selector dropdown + tab group, with localized fallback).
- [x] Spec window/inspect helper migration slice completed and finalized (`UI/MultiBotSpecUI.lua`): Ace window close-cross UX, layering/clickability fix, compact height, and position persistence via existing `specDropdownPositions` store.
- [x] Raidus migration/polish slice completed and finalized (`Features/MultiBotRaidus.lua`): Ace host window path + fallback, close-state sync with main button, score badges, drop feedback animation, and interactive contrast polish.
- [ ] Preserve slash entry points and open/close behavior.
- [ ] Keep persisted state routed through existing AceDB helpers.
- [ ] Validate visual/interaction parity per migrated screen.

## Milestone 9 — Localization and text pipeline

- [x] Inventory hardcoded user-facing strings in Core/UI/Features.
- [x] Move strings into locale tables (AceLocale strategy) where feasible.
- [x] Add deterministic fallback for missing locale keys.
- [ ] Remove duplicate literals once locale keys are stable. *(ongoing incremental cleanup by file)*

## Milestone 10 — Data model and table lifecycle hardening

- [ ] Centralize store accessors for profile/runtime tables.
- [ ] Remove duplicate validation/bootstrap snippets.
- [ ] Ensure read accessors are non-creating by default.
- [ ] Add cleanup for empty transient buckets where needed.

## Milestone 11 — Scheduler/timers convergence

- [ ] Inventory all `OnUpdate` loops and elapsed timers.
- [ ] Classify each loop (hot path/local, safe-to-centralize, keep-as-is).
- [ ] Migrate safe loops to a shared scheduler approach.
- [ ] Remove duplicate periodic loops after parity validation.

## Milestone 12 — Observability and perf guardrails

- [ ] Add subsystem debug toggles (off by default).
- [ ] Add lightweight counters around high-frequency handlers.
- [ ] Ensure diagnostics do not spam chat/log by default.
- [ ] Validate no notable overhead in normal mode.

## Milestone 13 — Release hardening and fallback closure

- [ ] Define closure policy for remaining legacy fallback writes.
- [ ] Document upgrade and rollback procedure.
- [ ] Execute full smoke + migration regression pass.
- [ ] Freeze release scope and publish compatibility notes.

---

## Post-M7 Smoke Tests (run per PR)

### 1) Startup / reload safety
- [ ] Addon loads without Lua errors.
- [ ] `/reload` does not duplicate handlers, loops, or startup effects.

### 2) UI parity
- [ ] Main UI toggles and panels open/close identically.
- [ ] Migrated AceGUI screens match legacy behavior.
- [ ] Drag/drop and frame anchoring still restore after relog/reload.

### 3) Persistence and migration safety
- [ ] No read path creates legacy tables accidentally.
- [ ] Legacy writes happen only in approved migration fallback windows.
- [ ] One-way migration markers prevent repeated imports.

### 4) Bot and event flows
- [ ] Roster refresh remains stable under frequent events.
- [ ] Whisper/quest parsing remains non-blocking and accurate.
- [ ] No new chat/event spam regressions.

### 5) Performance sanity
- [ ] No obvious CPU spikes from new scheduler/UI paths.
- [ ] No growth of transient tables across repeated open/close cycles.