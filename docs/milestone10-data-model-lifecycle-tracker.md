# Milestone 10 — Data Model & Table Lifecycle Hardening Tracker

Ce document sert de suivi exécutable pour compléter le **Milestone 10** de la roadmap ACE3 :
- centraliser les accès aux stores runtime,
- supprimer les initialisations/validations ad-hoc,
- empêcher la création implicite de tables en lecture.

Référence roadmap : `ROADMAP.md` (D3 Milestone 10).

---

## 1) Objectifs fonctionnels (scope M10)

- [x] Tous les accès aux stores à fort churn passent par des accesseurs centralisés. *(PR1: base API centralisée introduite, bascule progressive par domaine)*
- [ ] Les lectures sont non-mutantes (pas de création de table cachée sur un read). *(PR2: progression via accesseurs centralisés; assainissement final des read-paths prévu PR3/PR4)*
- [x] Les écritures/initialisations explicites utilisent des helpers dédiés (`ensure*` / `getOrCreate*`). *(PR3: `EnsureMigrationStore`, `EnsureBotsStore`, `EnsureFavoritesStore`)*
- [x] Les validateurs dupliqués sont regroupés dans une couche unique de normalisation. *(PR3: validation/sanitization du store global bots centralisée dans `MultiBot.Store`)*
- [ ] Les modules ciblés n’ont plus de snippets one-off `if not t then t = {} end` hors helpers centralisés.

---

## 2) Inventaire des stores à couvrir

### 2.1 Stores prioritaires (bloquants M10)

- [ ] `db.profile.ui` (positions, états visuels, préférences UI ACE3)
- [ ] Stores runtime bots (cache roster, états temporaires, indexation runtime)
- [ ] Caches UI rapides (popups, sélections courantes, pagination, données de session)

### 2.2 Stores secondaires (si touchés par PR M10)

- [ ] Mémoire quick-bar / classes / contextes spécifiques
- [ ] Buffers de parsing whisper/chat
- [ ] Structures de mapping temporaires (lookup tables)

---

## 3) Plan de migration technique détaillé

## Phase A — Audit & cartographie

- [x] Lister tous les chemins de lecture/écriture des stores prioritaires. *(PR1: inventaire initial sur `Core/`, `UI/`, `Features/`)*
- [x] Taguer chaque accès : `READ`, `WRITE`, `READ_THEN_CREATE`, `VALIDATE`. *(PR1: tags appliqués dans la matrice pour les stores prioritaires)*
- [x] Identifier les créations implicites en lecture. *(PR1: pattern relevé sur plusieurs accès directs `profile.ui.*`)*
- [x] Identifier les validateurs dupliqués entre modules. *(PR1: duplication confirmée autour de `ui.mainBar` et stores UI voisins)*
- [x] Produire une matrice “store -> modules -> helpers actuels” dans ce document.

### Matrice (à remplir)

| Store | Modules consommateurs | Helper actuel | Risque principal | Action M10 |
|---|---|---|---|---|
| `db.profile.ui.mainBar` | `Core/MultiBotConfig.lua` | Accès directs + normalisation locale | `READ_THEN_CREATE` implicite + validateurs dupliqués | **PR1 fait**: API `MultiBot.Store` + migration domaine mainBar |
| `db.profile.ui` (minimap/strata/visibility/quick frames) | `Core/MultiBot.lua`, `UI/MultiBotTalentFrame.lua`, `UI/MultiBotSpecUI.lua`, `Features/MultiBotRaidus.lua` | Helpers locaux par module | Drift de schéma + créations inline | **PR2 fait (Core/MultiBot.lua)**, reste UI/Features à converger |
| Runtime bot store (`profile.bots`, états temporaires) | `Core/MultiBot.lua`, `Core/MultiBotHandler.lua`, `Core/MultiBotEngine.lua` | Mix helpers + snippets inline | Normalisation partielle et validations divergentes | **PR3 fait (Core/MultiBot.lua + Core/MultiBotHandler.lua)**, reste Engine à consolider |
| Quick UI caches (`MultiBot.*` runtime) | `UI/MultiBotQuest*`, `UI/MultiBotSpellBookFrame.lua`, `Features/MultiBotReward.lua` | Tables runtime ad-hoc | Mutations cachées / initialisations dispersées | PR4: wrappers runtime + hygiene read/write |

---

## Phase B — API de store centralisée

- [x] Définir une API unifiée de store (naming stable + responsabilités claires). *(PR1: `Core/MultiBotStore.lua`)*
- [ ] Séparer explicitement :
  - [x] `get*` (lecture pure, jamais de création), *(PR1: `GetProfileStore`, `GetUIStore`, `GetMainBarStore`)*
  - [x] `ensure*` / `getOrCreate*` (création explicite), *(PR1+PR3: `EnsureProfileStore`, `EnsureUIStore`, `EnsureMainBarStore`, `EnsureMigrationStore`, `EnsureBotsStore`, `EnsureFavoritesStore`)*
  - [x] `normalize*` (coercion/shape), *(PR1: `NormalizeMainBarSettings`)*
  - [x] `validate*` (contrats + garde-fous). *(PR3: `IsValidGlobalBotRosterEntry`, `SanitizeGlobalBotStore`)*
- [x] Documenter les contrats de chaque helper (input/output/effets de bord). *(PR1: contrats implicites codés + ce tracker mis à jour)*
- [x] Ajouter des garde-fous nil-safe homogènes. *(PR2: `GetUIChildStore`, `EnsureUIChildStore`, `GetUIValue`, `SetUIValue`)*

### Contrat cible (checklist)

- [ ] Aucun `get*` ne crée de table.
- [ ] Toute création passe par un chemin intentionnel et nommé.
- [ ] Les normalisations sont idempotentes.
- [ ] Les validations n’altèrent pas l’état (sauf chemin `ensure*` explicite).

---

## Phase C — Refactor module par module

- [ ] Remplacer les accès directs stores par l’API centralisée.
- [ ] Supprimer les bootstraps inline dupliqués.
- [ ] Supprimer les validateurs locaux redondants.
- [ ] Conserver une parité fonctionnelle stricte (aucun changement UX attendu).

### Vagues de migration recommandées

1. [ ] Core runtime (init/handler/engine)
2. [ ] UI haute fréquence (main frame, quick interactions)
3. [ ] Features secondaires (popups/outils auxiliaires)
4. [ ] Stratégies/classes si elles touchent des stores normalisés

---

## Phase D — Durcissement & prévention de régression

- [ ] Ajouter assertions légères (mode debug) sur les chemins interdits de création implicite.
- [ ] Ajouter hooks de diagnostic désactivés par défaut.
- [ ] Vérifier qu’aucun module ne re-crée des chemins legacy en lecture.
- [ ] Vérifier l’absence de mutation cachée pendant les parcours UI.

---

## 4) Critères de sortie M10 (DoD)

- [ ] Aucun chemin de lecture ciblé ne crée de table implicitement.
- [ ] Les helpers de normalisation/validation sont factorisés et réutilisés.
- [ ] Les modules migrés n’ont plus de bootstrap inline ad-hoc.
- [ ] Les flux runtime restent inchangés côté utilisateur.
- [ ] Le document de checklist migration est mis à jour avec les validations M10.

---

## 5) Validation & tests (à exécuter par PR M10)

## 5.1 Sanity

- [ ] Chargement addon sans erreur Lua.
- [ ] `/reload` sans duplication d’état/handlers/timers.

## 5.2 Non-régression fonctionnelle

- [ ] Slash commands inchangées (`/multibot`, `/mb`, `/mbot`, `/mbopt`, etc.).
- [ ] Parsing whisper/quest non régressé.
- [ ] États UI restaurés correctement après relog/reload.

## 5.3 Validation spécifique M10

- [ ] Audit des reads : zéro création implicite détectée.
- [ ] Audit des écritures : création uniquement via `ensure*`/`getOrCreate*`.
- [ ] Audit de schéma : normalisation cohérente inter-modules.

---

## 6) Backlog PR suggéré (ordre d’atterrissage)

- [x] PR1 — Audit + ajout API store centralisée (sans bascule massive)
- [x] PR2 — Migration `db.profile.ui` vers accesseurs centralisés
- [x] PR3 — Migration runtime bot stores + validations communes
- [ ] PR4 — Migration quick UI caches + suppression bootstraps inline
- [ ] PR5 — Durcissement final + nettoyage + checklist release M10

---

## 7) Journal de suivi

### Entrées

- 2026-04-04 — Codex — PR1/commit courant — `db.profile.ui.mainBar` — Ajout `MultiBot.Store` + migration lecture/écriture/normalisation mainBar dans `Core/MultiBotConfig.lua`.
- 2026-04-04 — Codex — PR2/commit courant — `db.profile.ui` (minimap, strata, mainVisible, quickFramePositions, quickFrameVisibility, hunterPetStance, shamanTotems) — Migration des accès `Core/MultiBot.lua` vers API `MultiBot.Store`.
- 2026-04-04 — Codex — PR3/commit courant — stores runtime (`bots`, `favorites`, `migrations`, `layout/mainBar`) — Centralisation des accès/validations dans `MultiBot.Store` et migration des call sites Core.

### Décisions

- _AAAA-MM-JJ_ — _Décision architecture_ — _Impact_

### Risques ouverts

- [ ] _Risque 1_
- [ ] _Risque 2_

---

## 8) Définition “Done” finale

Le Milestone 10 est considéré terminé quand :
- les trois stores prioritaires sont passés sous API centralisée,
- les lectures sont prouvées non-mutantes,
- les snippets de bootstrap/validation ad-hoc sont supprimés des modules ciblés,
- et la non-régression fonctionnelle est validée sur le périmètre MultiBot actuel.