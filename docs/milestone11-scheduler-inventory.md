# Milestone 11 — Inventaire des boucles et timers existants

Date d'audit: 2026-04-05.
Objectif: établir la cartographie complète des mécanismes temporels avant convergence scheduler (M11).

## 1) Boucles périodiques (`OnUpdate` / compteurs elapsed)

| ID | Fichier | Mécanisme | Portée | Usage principal | Fréquence / déclenchement | Nature M11 (pré-classement) |
|---|---|---|---|---|---|---|
| P1 | `Core/MultiBotHandler.lua` | `MultiBot:SetScript("OnUpdate")` + `HandleOnUpdate` | Runtime global | Pilote des automations `stats`, `talent`, `invite`, `sort` via compteurs `elapsed/interval` | Chaque frame (gating par intervalle configurable) | **Hot path**: conserver local, harmoniser le pilotage |
| P2 | `Core/MultiBotThrottle.lua` | Frame `OnUpdate` avec token-bucket | Runtime global | Throttle de `SendChatMessage` (débit + burst) + flush file d'attente | Chaque frame | **Hot path**: conserver local (critique anti-spam) |
| P3 | `UI/MultiBotMainUI.lua` | `HookScript("OnUpdate")` sur `multiBar` | UI principal | Autohide de la barre principale (interaction souris + délai) | Polling périodique avec intervalle interne (`MAINBAR_AUTOHIDE_UPDATE_INTERVAL`) | **Candidat** centralisation partielle (si sans régression UX) |
| P4 | `Features/MultiBotRaidus.lua` | Frame `OnUpdate` dédié feedback | UI Raidus | Extinction retardée du texte de feedback drag/drop | Temporaire pendant `RAIDUS_FEEDBACK_DURATION` | **Candidat safe** vers helper timer one-shot |
| P5 | `Features/MultiBotRaidus.lua` | Driver `OnUpdate` pulse slot | UI Raidus | Animation courte de pulse lors d'un drop | Temporaire pendant `RAIDUS_DROP_ANIM_DURATION` | **À garder local** (animation visuelle) |
| P6 | `UI/MultiBotSpecUI.lua` | Frame `OnUpdate` (0.2s) | UI Spec | Chaînage `talents` puis `talents spec list` | Temporaire (désarmé après seuil) | **Candidat safe** vers `TimerAfter` |
| P7 | `UI/MultiBotMinimap.lua` | `OnUpdate` activé durant drag | UI Minimap | Mise à jour angle minimap pendant déplacement bouton | Uniquement pendant drag | **À garder local** (interaction directe) |
| P8 | `UI/MultiBotHunterQuickFrame.lua` | `OnUpdate` one-shot sur preview model | UI Hunter Quick | Initialisation différée de scale/facing/display du modèle 3D | Une frame puis auto-nil | **Candidat safe** vers helper one-shot |
| P9 | `Core/MultiBotEngine.lua` | `_clickBlockerTicker` `OnUpdate` one-shot | Runtime/UI engine | Coalescence de demandes de recalcul click-blocker | Une frame puis flush queue | **Candidat safe** vers scheduler frame-next-tick |
| P10 | `Core/MultiBotAsync.lua` | Fallback `OnUpdate` si pas de `C_Timer.After` | Utilitaire global | Implémentation de `MultiBot.TimerAfter` en environnement legacy | Temporaire, selon délai demandé | **Base utilitaire**: conserver (compatibilité) |
| P11 | `Core/MultiBot.lua` | Fallback local `C_Timer_After` dans GM detect | Runtime système | Re-lance différée `RaidPool("player")` après détection compte | One-shot (0.2s) | **Duplication à converger** vers `MultiBot.TimerAfter` |

## 2) Timers différés one-shot (`MultiBot.TimerAfter`)

`MultiBot.TimerAfter` est défini/normalisé dans `Core/MultiBotAsync.lua` (utilise `C_Timer.After` si disponible, sinon fallback frame `OnUpdate`).

### 2.1 Répartition des appels par fichier

- `UI/MultiBotSpecUI.lua`: 6 appels
- `Core/MultiBotHandler.lua`: 4 appels
- `UI/MultiBotUnitsRootUI.lua`: 2 appels
- `UI/MultiBotTalentFrame.lua`: 2 appels
- `UI/MultiBotQuestsMenu.lua`: 2 appels
- `UI/MultiBotUnitsRosterUI.lua`: 1 appel
- `UI/MultiBotSpell.lua`: 1 appel
- `UI/MultiBotShamanQuickFrame.lua`: 1 appel
- `UI/MultiBotInventoryFrame.lua`: 1 appel
- `UI/MultiBotHunterQuickFrame.lua`: 1 appel
- `Core/MultiBotEngine.lua`: 1 appel

### 2.2 Usages fonctionnels identifiés

- **Quests / parsing / UI sync**: scheduling différé de rebuilds de listes et affichage progressif.
- **Roster / login / refresh**: retries légers au login et re-dispatch après initialisation UI.
- **Unités / guild roster**: retry différé pour peupler les données guilde/membres.
- **UI spécialisées** (Spec, Talent, Hunter/Shaman quick, Inventory, Spell): enchaînements asynchrones et refresh visuels/état.
- **Engine**: refresh inventaire bot avec délai optionnel.

## 3) Duplications et points de convergence prioritaires (entrée M11)

1. **Unifier tous les one-shot delay** sur `MultiBot.TimerAfter` (éviter les fallback locaux ad-hoc comme `C_Timer_After` inline de `Core/MultiBot.lua`).
2. **Documenter un owner unique par boucle périodique** (global runtime vs UI locale vs animation).
3. **Distinguer explicitement**:
   - boucles **hot path** à garder locales (throttle, automation core, drag handlers),
   - boucles **safe-to-centralize** (timeouts d'UI, retries one-shot, flush next-tick).

## 4) Vérifications techniques de l'audit

- Aucune occurrence `AceTimer` / `ScheduleTimer` / `ScheduleRepeatingTimer` active détectée dans `Core/`, `UI/`, `Features/`, `Strategies/`.
- Les mécanismes actuels reposent surtout sur:
  - `OnUpdate` périodique,
  - `MultiBot.TimerAfter` (wrapper unifié/fallback),
  - quelques timers one-shot inline historiques.

## 5) Sortie attendue pour la prochaine sous-étape M11

À partir de cet inventaire, la prochaine passe consiste à produire la **classification détaillée** (hot/local vs centralisable) avec décision par item (garder/migrer), puis plan PR séquencé de convergence.