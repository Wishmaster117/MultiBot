# MultiBot ACE3 — Main Bar Layout Migration Tracker

## Objectif global
Rendre la barre principale configurable et sûre à manipuler, avec une approche incrémentale en **2 phases**.

---

## Phase 1 — Plan ajusté (simple, rapide, propre)

### 1) Lock par défaut + déplacement sécurisé
- Par défaut : **tous les boutons sont verrouillés**.
- Déplacement autorisé uniquement si :
  - touche **Ctrl** enfoncée ;
  - **clic gauche** maintenu sur un bouton.
- Bénéfice : éviter les déplacements accidentels.

#### Pourquoi c’est simple à intégrer
- La base drag existe déjà (barre principale en drag + infra drag générique).

---

### 2) Modèle de sauvegarde unique (pas de variantes)
- Un seul objet : `mainLayout` (positions des boutons principaux).
- Format minimal par bouton : `{ x, y, visible }`.
- Aucune notion PvE/PvP/rôle/spec.

#### Base existante réutilisable
- Le système de persistance layout est déjà disponible :
  - `GetSavedLayoutValue`
  - `SetSavedLayoutValue`

---

### 3) Boutons `Save` / `Export` / `Import` / `Reset`
- **Save** : écrit les positions courantes dans la sauvegarde.
- **Export** : sérialise en string compacte (copiable).
- **Import** : colle la string et applique immédiatement.
- **Reset** : revient aux positions par défaut.

#### Cohérence existante
- Les positions par défaut existent déjà dans `resetDefaultWindowPositions`.

---

### 4) Import A -> B (cas d’usage principal)
- Sur perso A : `Export` → copier la string.
- Sur perso B : `Import` → coller la string → `Apply` → `Save`.
- Optionnel : checksum/version pour valider la compatibilité de la string.

---

### 5) UX minimale mais propre
- Message visuel :
  - `Locked` par défaut ;
  - `Hold Ctrl + Left Click to move`.
- Pendant drag : afficher les coordonnées.
- Fin de drag : autosave (ou save manuel, selon choix final).

---

### 6) Checkbox `Verrouiller déplacement barre`
#### Objectif
Ajouter dans le panneau Options une case simple :
- **Cochée** → barre principale verrouillée ;
- **Décochée** → barre déplaçable.

#### Pourquoi c’est rapide
- Le panneau options a déjà des `CheckBox` (legacy + ACE3).
- Le drag de la barre principale existe déjà (actuellement right-drag).
- Il suffit d’ajouter une condition de lock avant d’autoriser le déplacement.
- Le booléen peut être persisté comme les autres options UI.

#### Comportement UX proposé
- Valeur par défaut : `verrouillé = true`.
- Tooltip : `Décoche pour autoriser le déplacement de la barre principale`.
- Position : à côté des toggles UI existants dans le panneau Options.

---

## Phase 2 — Slots supplémentaires pour boutons custom

### Objectif
Ajouter des **emplacements vides** sur la barre principale pour y attacher des boutons custom.

### Approche propre
- Définir un nombre de slots configurables (`N`).
- Chaque slot = bouton standard MultiBot (même API `newButton`, `setPoint`, etc.).
- Slots stockés/chargés via la persistance layout existante.
- Le binding d’action du slot sera traité dans une phase dédiée :
  - menu de choix action,
  - macro command,
  - etc.

### Pourquoi plus tard
Cette partie touche :
- UX,
- modèle de données,
- assignation d’actions.

=> Mieux de la sortir du correctif lock/unlock pour garder la Phase 1 légère et livrable rapidement.

---

## Statut
- [ ] Phase 1 — Non démarrée
- [ ] Phase 2 — Non démarrée