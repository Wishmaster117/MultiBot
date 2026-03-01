# ACE3 Migration Checklist (Before/After Validation)

Checklist for each migration PR to verify no user-facing regressions.

## Current Progress Snapshot

- [x] ACE3 libraries are loaded from `MultiBot.toc`.
- [x] Lifecycle bridge exists (`OnInitialize` / `OnEnable`) with fallback behavior.
- [x] Central command alias registration is in place.
- [x] Central event/update dispatch entry points are in place.
- [x] Full event registration convergence (core + UI whisper handlers now dispatcher/lifecycle-driven, no standalone event listener frames remain).
- [x] SavedVariables migration to AceDB “cleanup remaining” (legacy cleanup/purge policy)
- [ ] Minimap/options persistence fully switched to AceDB “core migrated, remaining options pending”
- [ ] Optional AceGUI screen-by-screen migration.

---

## Smoke Tests (Run Before and After Each PR)

### 1) Load / reload safety
- [ ] Addon loads without Lua errors.
- [ ] `/reload` does not duplicate handlers, timers, or startup side effects.

### 2) Core slash commands
- [ ] `/multibot` toggles main UI.
- [ ] `/mbot` and `/mb` behave exactly like `/multibot`.
- [ ] `/mbopt` opens options panel reliably.
- [ ] `/mbclass` and `/mbclasstest` still work.

### 3) Core event-driven behavior
- [ ] Bot roster processing still populates units/buttons correctly.
- [ ] Party/raid refresh behavior remains stable.
- [ ] Frequent events do not create chat/event spam regressions.

### 4) Quest / whisper parsing
- [ ] Incompleted/completed quest parsing still updates expected views.
- [ ] "Quests all" aggregation completes and displays correctly.
- [ ] No blocking regressions between quest and non-quest whispers.

### 5) GameObject flow
- [ ] Capture starts on relevant section headers.
- [ ] Capture stops on terminal section/blank line and popup is shown once.
- [ ] Copy box output is complete and readable.

### 6) Persistence
- [ ] Frame positions restore after relog/reload.
- [ ] Portal memory restore works.
- [ ] Main UI visibility persists correctly.
- [ ] Main bar state toggles restore correctly.

### 7) Options / minimap
- [ ] Minimap button show/hide behavior is unchanged.
- [ ] Options panel controls still apply values immediately.

---