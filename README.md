<img width="1024" height="559" alt="image" src="https://github.com/user-attachments/assets/3ac43983-8767-4dd6-9a17-4548ede1e9d3" />

# Breaking News
Work on porting MultiBot to ACE3 has started! You can test it by grabbing the feature/ace3-migration branch. It’s about 11% complete, so the addon is still running in a hybrid mode, but we’re already seeing noticeable gains in smoothness.

# MultiBot
User interface for AzerothCore-Module "Playerbots" by Playerbots team https://github.com/mod-playerbots/mod-playerbots.<br>
Tested with American, German, French and Spanish 3.3.5 Wotlk-Client.

# Installation
Simply place the files in a folder called "MultiBot" in your World of Warcraft AddOns directory.<br>
Example: "C:\WorldOfWarcraft\Interface\AddOns\MultiBot"
# Use
Start World of Warcraft and enter "/multibot" or "/mbot" or "/mb" in the chat, or use the minimap button.

---

## ⚠️ Notice — About This Fork

This is a fork of the original [MultiBot addon by Macx-Lio](https://github.com/Macx-Lio/MultiBot).

The reason for this fork is that I submitted several pull requests to the original repository, but since the creator, **Macx-Lio**, is currently unavailable, those changes could not be merged.

To allow the community to benefit from the additional features and improvements I have implemented, I’ve published this fork **as a temporary solution**.

> **All credit for the original addon goes to Macx-Lio.** I do not claim ownership of this project — I’m simply maintaining a working version until development resumes on the main repository.

Thank you for understanding.

---

# Comming soon

Port Multibot to ACE 3


# MultiBot ACE3 Migration Roadmap

## Current Status Snapshot

- **Milestone 1 (Baseline / safety net):** <span style="color:orange; font-weight:bold;">In progress</span>.
  - Baseline behavior is mostly known through manual validation.
  - Migration checklist is tracked in `docs/ace3-migration-checklist.md` and must be updated per PR.

- **Milestone 2 (Add ACE3 libs):** <span style="color:green; font-weight:bold;">Completed</span>.
  - ACE3 libraries are loaded in `MultiBot.toc`.

- **Milestone 3 (Initialization lifecycle):** Mostly <span style="color:green; font-weight:bold;">completed</span>, hardening pending.
  - `OnInitialize` and `OnEnable` are in place.
  - Legacy frame-based startup/event code still exists in a few places.

- **Milestone 4 (Command system):** <span style="color:green; font-weight:bold;">Completed</span>.
  - Central alias registration is used for core commands via `RegisterCoreCommandsOnce` in lifecycle init.
  - Runtime command invocation paths are centralized through `RunRegisteredCommand` (slash + minimap click + helper dispatch).

- **Milestone 5 (Event bus migration):** <span style="color:green; font-weight:bold;">Completed</span>.
  - Dispatcher architecture drives core/quick-bar/UI whisper flows.
  - Legacy `CreateFrame + RegisterEvent + SetScript` listener blocks have been removed from addon runtime paths.

- **Milestone 6 (SavedVariables -> AceDB):** <span style="color:green; font-weight:bold;">Completed</span>.
  - AceDB bootstrap/runtime migration is now complete for supported SavedVariables paths; one-way versioned legacy cutovers are in place with guarded legacy creation and post-migration cleanup to avoid stale duplicate persistence.

- **Milestone 7 (Minimap/options integration):** <span style="color:green; font-weight:bold;">Completed</span>.
  - Minimap hide/angle, global frame strata, options timers/throttle, Spec dropdown positions, Hunter/Shaman quick-bar positions, Hunter pet stance state and Shaman totem choice state now run through AceDB-backed helpers with one-way versioned legacy cutover and guarded legacy fallback (no legacy table creation on pure read paths).

- **Milestone 8 (AceGUI UI refactor):** <span style="color:orange; font-weight:bold;">In progress</span>.
  - `UI/MultiBotOptions.lua` panel content has been migrated to AceGUI widgets while preserving category registration and slash/open flows; remaining screens continue screen-by-screen.

- **Milestone 9 (Localization and text pipeline):** <span style="color:green; font-weight:bold;">Completed</span>.
  - Core locale loader + per-locale payload files are integrated (`Core/MultiBotLocale.lua`, `Locales/MultiBotAceLocale-*.lua`).
  - `Core/MultiBotInit.lua`, `Features/MultiBotRaidus.lua`, `Core/MultiBotEvery.lua`, `Core/MultiBotEngine.lua`, `Core/MultiBotHandler.lua`, `Strategies/MultiBotDruid.lua`, `Strategies/MultiBotPaladin.lua`, `Strategies/MultiBotMage.lua`, `Strategies/MultiBotWarlock.lua`, `Strategies/MultiBotPriest.lua`, `Strategies/MultiBotShaman.lua`, `Strategies/MultiBotHunter.lua`, `Strategies/MultiBotRogue.lua`, `Strategies/MultiBotDeathKnight.lua`, and `Strategies/MultiBotWarrior.lua` migration sweeps are completed for legacy `MultiBot.tips.*` runtime reads.
  - `Core/MultiBot.lua` bootstrap `MultiBot.tips` initialization lines were validated/documented as intentional non-runtime-tooltip compatibility paths.
  - Remaining UI literal cleanup is completed for Milestone 9 scope (GM shortcut labels, Raidus group title formatting, shared UI defaults for page/title labels) while preserving technical/protocol identifiers (e.g. internal "Inventory" button/event keys).

- **Milestone 10 (Data model and table lifecycle hardening):** <span style="color:red; font-weight:bold;">Planned</span>.
  - Normalize runtime stores and remove ad-hoc table creation paths via centralized getters/validators.

- **Milestone 11 (Scheduler/timers convergence):** <span style="color:red; font-weight:bold;">Planned</span>.
  - Route scattered timers/OnUpdate loops to a constrained scheduler strategy (AceTimer where appropriate, existing loops retained when safer).

- **Milestone 12 (Observability, diagnostics and perf guardrails):** <span style="color:red; font-weight:bold;">Planned</span>.
  - Add lightweight debug/perf toggles and migration diagnostics to validate behavior without chat spam.

- **Milestone 13 (Release hardening and deprecation window close):** <span style="color:red; font-weight:bold;">Planned</span>.
  - Close migration fallback window, document upgrade path, and freeze compatibility guarantees for release.
