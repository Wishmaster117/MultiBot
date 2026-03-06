# ACE3 UI Frame Inventory (Milestone 8)

Inventory of addon UI frame construction points found via `CreateFrame(...)` scan in `Core/`, `UI/`, and `Features/`.

> Goal: track every user-facing frame cluster to migrate to AceGUI (screen-by-screen), and check off progress per PR.

## Status legend
- `[x]` Migrated to AceGUI path (legacy fallback may still exist temporarily).
- `[ ]` Not migrated.
- `[-]` Keep as native frame (non-screen utility/runtime frame).

---

## 1) Interface Options / Configuration

- [x] **Options panel** (`/mbopt`, Interface Options category) — AceGUI path in place with temporary legacy fallback.  
  Files: `UI/MultiBotOptions.lua` (panel + sliders/dropdowns/buttons).  
  References: `UI/MultiBotOptions.lua:234`, `UI/MultiBotOptions.lua:268`.

---

## 2) Dedicated top-level windows/popups (user-facing)

- [x] **PVP window** (`MultiBotPVPFrame`) with tabs and dropdown (AceGUI widgets for tab group + bot dropdown, with legacy fallback).
  File: `UI/MultiBotPVPUI.lua`.  
  References: lines `11`, `98`, `201`.

- [x] **Spec window / inspect helpers** (`df` popup and related frame/button controls) migrated and finalized with AceGUI window path (close-cross UX), corrected layering/clickability, compacted frame height, and preserved legacy icon-button inspect-refresh behavior.
  File: `UI/MultiBotSpecUI.lua`.  
  References: lines `542`, `590` (plus timer/utility frames at `231`, `294`).

- [x] **Raidus management window** (`MultiBot.raidus`) finalized for the M8 slice with AceGUI host window path + legacy fallback, close-button state synchronization, visual polish, and drag/drop feedback integration.
  File: `Features/MultiBotRaidus.lua`.
  References: lines `119`, `164`, `599`, `1372`.
  
- [x] **Quest summary popup** (`MB_QuestPopup`) migrated to AceGUI host window path (no legacy frame fallback) while preserving dynamic rows/html content rendering.  
  File: `Core/MultiBotInit.lua`.  
  References: lines `1760`, `1787`, `1845`.

- [x] **Bot quest popup** (`MB_BotQuestPopup`) migrated to AceGUI host window path (no legacy frame fallback) while preserving dynamic quest rows/html content rendering.  
  File: `Core/MultiBotInit.lua`.  
  References: lines `1942`, `1966`, `1995`.

- [x] **Bot quest complete popup** (`MB_BotQuestCompPopup`) migrated to AceGUI host window path (no legacy frame fallback) while preserving dynamic rows/html content rendering.  
  File: `Core/MultiBotInit.lua`.  
  References: lines `2161`, `2185`, `2215`.

- [x] **Bot quest all popup** (`MB_BotQuestAllPopup`) migrated to AceGUI host window path (no legacy frame fallback) while preserving dynamic rows/html content rendering.  
  File: `Core/MultiBotInit.lua`.  
  References: lines `2387`, `2416`, `2467`

- [x] **GameObject popup/copy box** (`MB_GameObjPopup`, `MB_GameObjCopyBox`) migrated to AceGUI windows/widgets path (no legacy frame fallback).  
  File: `Core/MultiBotInit.lua`.  
  References: lines `2745`, `2789`

- [x] **Universal prompt dialog** (`MBUniversalPrompt`) migrated to AceGUI window+widgets path (no legacy frame fallback).  
  File: `Core/MultiBotInit.lua`.  
  References: line `2893`.

- [x] **Hunter prompt/search/family windows** (`MBHunterPrompt`, `MBHunterPetSearch`, `MBHunterPetFamily`) migrated to AceGUI host/prompt paths (no legacy frame fallback for prompt/search/family hosts; preview model retained).  
  File: `Core/MultiBotInit.lua`.  
  References: lines `5505`, `5551`, `5730`, `5588`.

---

## 3) Embedded controls inside existing screens (likely migrate with owning screen)

- [x] **Raidus slot/group controls** inside Raidus UI finalized in the Raidus migration slice.
  File: `Features/MultiBotRaidus.lua`.
  References: lines `415`, `945`, `989`, `1021`.

- [ ] **Quest/localization tooltip frame** (`MB_LocalizeQuestTooltip`) if moved with quest UI cleanup.  
  File: `Core/MultiBotInit.lua`.  
  Reference: line `1730`.

- [ ] **Hidden glyph tooltip** (`MBHiddenTip`) used by glyph interactions.  
  File: `Core/MultiBotInit.lua`.  
  Reference: line `4701`.

---

## 4) Runtime/utility frames (not direct Milestone 8 AceGUI screens)

- [-] **Minimap button** (`MultiBot_MinimapButton`) keep native frame.  
  File: `Core/MultiBotInit.lua`.

- [-] **Event/timer/dispatch helper frames** (`CreateFrame("Frame")` without visible UI).  
  Files: `Core/MultiBot.lua`, `Core/MultiBotThrottle.lua`, `Core/MultiBotHandler.lua`, `UI/MultiBotSpecUI.lua` (timer frame), `Core/MultiBotInit.lua` (misc helper frame usages).

- [-] **Engine widget factory primitives** in `Core/MultiBotEngine.lua` (button/check/model constructors for core UI system).  
  These are shared low-level primitives and should be migrated only when the owning screen is migrated.

---

## Per-PR update rule

For each Milestone 8 PR:
1. Update this inventory file (`[ ] -> [x]`) for the migrated screen/control cluster.
2. Update `docs/ace3-expansion-checklist.md` progress bullets.
3. Keep migrations localized (one UI domain per PR).