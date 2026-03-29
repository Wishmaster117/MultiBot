# Audit Milestone 8 Followup — migration Quests vers Ace3

Date d’audit: 2026-03-29
Branche auditée: `work` (HEAD local)

## Verdict (mis à jour)

La migration Quests/GameObject est désormais **quasi complète côté popups** :

- ✅ Frames Quests/GameObject extraites dans des fichiers dédiés `UI/`.
- ✅ Popups Quests (`Log`, `Incomplete`, `Completed`, `All`) rendus via widgets AceGUI.
- ✅ Popups GameObject (`Results`, `Copy`) en flux AceGUI nettoyé.
- ✅ Helpers legacy de construction de scroll/html supprimés de `UI/MultiBotQuestUIShared.lua`.
- ⚠️ Point restant principal: le **menu Quests** de la barre droite est encore sur le framework historique (`tRight.addFrame/addButton`) et pas sur un container AceGUI dédié.

## Changements validés depuis l’audit initial

### Popups migrés en rendu AceGUI
- `UI/MultiBotQuestLogFrame.lua`
- `UI/MultiBotQuestIncompleteFrame.lua`
- `UI/MultiBotQuestCompletedFrame.lua`
- `UI/MultiBotQuestAllFrame.lua`
- `UI/MultiBotGameObjectResultsFrame.lua`
- `UI/MultiBotGameObjectCopyFrame.lua`

### Nettoyage de code legacy
- Suppression des anciens constructeurs UI legacy maintenant inutiles dans `UI/MultiBotQuestUIShared.lua`:
  - `ClearFrameChildren`
  - `CreateSectionTitle`
  - `CreateSummaryLabel`
  - `CreateStyledScrollArea`
  - `CreateQuestHTML`
  - `BindHyperlinkTooltip`

## État fonctionnel

### Conservé
- Logique métier de parsing/agrégation Quests/GameObject.
- Modes groupe/whisper et enchaînement des actions.
- Tooltips, loading, close/hide, ESC, persistance de position.

### À finaliser
1. Migrer (ou assumer explicitement hors périmètre) `UI/MultiBotQuestsMenu.lua` vers un container AceGUI.
2. Faire une passe de validation in-game complète (parité visuelle + interactions).
3. Mettre à jour les trackers docs liés si nécessaire.

## Conclusion opérationnelle

Par rapport à l’objectif “on supprime la frame legacy et ses contours et on recode en Ace3”:

- ✅ **Objectif atteint sur les popups Quests/GameObject**.
- ⚠️ **Reste le menu Quests de la barre principale** (structure historique non-AceGUI).