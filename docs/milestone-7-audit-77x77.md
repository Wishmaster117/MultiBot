# Milestone 7 audit 77/77 (Lua files)

This audit classifies every Lua file in the repository for Milestone 7 (minimap/options persistence scope).

## Scope used
- Minimap hide/angle persistence.
- Global frame strata persistence.
- Options sliders persistence (timers + throttle).
- Verification target: centralized helper usage (no UI-local persistence branch).

## Matrix

| File | Status | Notes |
|---|---|---|
| `Core/MultiBot.lua` | **OK** | Core persistence helpers for minimap/strata and migration keys are centralized here. |
| `Core/MultiBotConfig.lua` | **OK** | Core persistence helpers for timers/throttle are centralized here. |
| `Core/MultiBotEngine.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Core/MultiBotEvery.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Core/MultiBotHandler.lua` | **OK** | Uses GetGlobalStrataLevel/ApplyGlobalStrata in runtime path. |
| `Core/MultiBotInit.lua` | **OK** | Minimap button drag/show uses Get/SetMinimapConfig and Minimap_Refresh flow. |
| `Core/MultiBotThrottle.lua` | **OK** | Reads throttle values via centralized GetThrottleRate/GetThrottleBurst. |
| `Data/HunterPetFamily.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Data/HunterPetList_1.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Data/HunterPetList_2.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Data/HunterPetList_3.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Data/HunterPetList_4.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Data/MultiBotItemus.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Features/MultiBotNecronet.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Features/MultiBotRaidus.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Features/MultiBotReward.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Libs/AceAddon-3.0/AceAddon-3.0.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Libs/AceConsole-3.0/AceConsole-3.0.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Libs/AceDB-3.0/AceDB-3.0.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Libs/AceEvent-3.0/AceEvent-3.0.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Libs/AceGUI-3.0/AceGUI-3.0.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Libs/AceGUI-3.0/widgets/AceGUIContainer-BlizOptionsGroup.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Libs/AceGUI-3.0/widgets/AceGUIContainer-DropDownGroup.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Libs/AceGUI-3.0/widgets/AceGUIContainer-Frame.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Libs/AceGUI-3.0/widgets/AceGUIContainer-InlineGroup.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Libs/AceGUI-3.0/widgets/AceGUIContainer-ScrollFrame.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Libs/AceGUI-3.0/widgets/AceGUIContainer-SimpleGroup.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Libs/AceGUI-3.0/widgets/AceGUIContainer-TabGroup.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Libs/AceGUI-3.0/widgets/AceGUIContainer-TreeGroup.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Libs/AceGUI-3.0/widgets/AceGUIContainer-Window.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Libs/AceGUI-3.0/widgets/AceGUIWidget-Button.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Libs/AceGUI-3.0/widgets/AceGUIWidget-CheckBox.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Libs/AceGUI-3.0/widgets/AceGUIWidget-ColorPicker.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Libs/AceGUI-3.0/widgets/AceGUIWidget-DropDown-Items.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Libs/AceGUI-3.0/widgets/AceGUIWidget-DropDown.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Libs/AceGUI-3.0/widgets/AceGUIWidget-EditBox.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Libs/AceGUI-3.0/widgets/AceGUIWidget-Heading.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Libs/AceGUI-3.0/widgets/AceGUIWidget-Icon.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Libs/AceGUI-3.0/widgets/AceGUIWidget-InteractiveLabel.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Libs/AceGUI-3.0/widgets/AceGUIWidget-Keybinding.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Libs/AceGUI-3.0/widgets/AceGUIWidget-Label.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Libs/AceGUI-3.0/widgets/AceGUIWidget-MultiLineEditBox.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Libs/AceGUI-3.0/widgets/AceGUIWidget-Slider.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Libs/AceLocale-3.0/AceLocale-3.0.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Libs/AceTimer-3.0/AceTimer-3.0.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Libs/CallbackHandler-1.0/CallbackHandler-1.0.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Libs/LibDBIcon-1.0/LibDBIcon-1.0.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Libs/LibDropdown-1.0/LibDropdown-1.0.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Libs/LibDropdown-1.0/LibDropdown-1.0/LibDropdown-1.0.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Libs/LibStub/LibStub.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Libs/libdatabroker-1-1/LibDataBroker-1.1.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Locales/MultiBotLanguage-deDE.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Locales/MultiBotLanguage-enGB.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Locales/MultiBotLanguage-enUS.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Locales/MultiBotLanguage-esES.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Locales/MultiBotLanguage-frFR.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Locales/MultiBotLanguage-koKR.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Locales/MultiBotLanguage-ruRU.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Locales/MultiBotLanguage-zhCN.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Strategies/MultiBotDeathKnight.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Strategies/MultiBotDruid.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Strategies/MultiBotHunter.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Strategies/MultiBotMage.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Strategies/MultiBotPaladin.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Strategies/MultiBotPriest.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Strategies/MultiBotRogue.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Strategies/MultiBotShaman.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Strategies/MultiBotWarlock.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `Strategies/MultiBotWarrior.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `UI/MultiBotIconos.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `UI/MultiBotItem.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `UI/MultiBotOptions.lua` | **OK** | Options panel writes via centralized helpers (timer/throttle/minimap/strata). |
| `UI/MultiBotPVPUI.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `UI/MultiBotSpecUI.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `UI/MultiBotSpell.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `UI/MultiBotStats.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |
| `UI/MultiBotTalent.lua` | **Hors scope M7** | No Milestone 7 options/minimap persistence logic in this file. |

## Totals

- OK: **6**
- À corriger: **0**
- Hors scope M7: **71**