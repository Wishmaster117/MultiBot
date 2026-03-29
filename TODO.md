TODO

* Voi si y'a pas d'autres appels à pageLabel:SetText(MB_PAGE_DEFAULT) dans les fichiers et remplacer par : +	pageLabel:SetText(MultiBot.MB_PAGE_DEFAULT or "0/0")
* Ressortir les UI quetes dans leurs propre fichiers et uniformiser le tempklate de la frame comme celle de Itemus
* Uniformiser le templste de la frame reward comme celle de itemus
* Essayer de faire disparaitre la barre multibots au bout d'un temps et la faire apparaitre quand on passe la souris dessus.
* Quand on deplace ou fait quelque chose dans l'ui il faudrait que ça se sauvegarde tout de suite dans les variables dans deco reco
* Raidus doit se rafraichir à l'ouverture et fermeture
* dans la liste des quêtes des fois c'est l'ID de la queête qui apparait et pas le tritre
* Afficher le pognon et les places de sacs dans la frame inventaire
* La fenêtre inventaire doit se rafraichir par exemple quand on fait le bot bouffer il faut que ce qu'il a bouffé se décompte
* Iconos ne mémorise pas sa position
* Revoir le positionnement des fleches et pages de Iconos
* Mettre une option pour choisir la tailles des icones de la main barre et des quickhunter/shaman
* Voir si il y'a pas d'autres option que l'on peut ajouter à la frame options de multibot
* creer le multilangue pour le tooltip: setTooltip(self, "Show / Hide / Move Quick Shaman") des fichiers quickshaman et quickhunter
* faire de la main barre + droite et gauche une barre de boutons ou l'on peux disposer les bouton changer l'orde etc...


 Ajouter la fonction unequipe à Multibit:
“unequip” est une action orientée équipement, donc elle colle naturellement à une vue d’inspection / slots d’équipement, alors que la réorganisation des sacs demande une logique de bag/slot bien plus lourde. 
Pourquoi c’est un bon candidat pour la fenêtre d’inspection

1) L’inspection est déjà centrée sur les slots d’équipement
Le code existant manipule déjà très bien la notion de slot d’équipement :
dans le calcul d’ilvl, on parcourt explicitement les slots 1..18 ;
dans itemus, il existe déjà une cartographie claire des slots d’équipement (S00, S01, etc.). 
Donc si la commande ue fonctionne par slot ou peut être reliée à un slot, l’intégration UI est très naturelle.

2) On a déjà un point d’entrée “Inspect”
L’addon sait déjà lancer l’inspection d’un bot via InspectUnit(...) :
depuis le bouton Inspect dans la Reward frame, et ailleurs dans l’addon. 
Donc graphiquement, il y a déjà un flux utilisateur existant :
ouvrir l’inspection du bot,
voir son équipement,
déclencher une action sur un slot équipé.

Là où il faut être prudent
Le vrai point clé : comment fonctionne exactement ue
C’est ça qui détermine la qualité de l’intégration.

Cas A — si ue fonctionne par slot
Exemple conceptuel :
ue head
ue 1
ue S01

Dans ce cas, c’est idéal.
Parce que la fenêtre d’inspection affiche précisément des slots. Tu peux donc faire une UI très propre :
clic droit sur un slot équipé → unequip ;
ou petit bouton contextuel sur chaque slot ;
ou mode “Unequip” activable, puis clic sur le slot.

Cas B — si ue fonctionne par item
Exemple conceptuel :
ue [ItemLink]
C’est encore faisable, mais un peu moins robuste :
s’il y a ambiguïté,
si deux objets identiques existent,
ou si la commande backend attend autre chose qu’un lien standard.

Cas C — si ue a une syntaxe spéciale côté playerbots
Alors il faudra juste aligner l’UI sur cette syntaxe.
Mais dans tous les cas, le concept UI reste pertinent.

“unequip” est une action sur :
un slot équipé,
ou un item actuellement porté.

Donc conceptuellement, la fenêtre d’inspection est le meilleur endroit :
plus logique pour l’utilisateur ;
plus lisible ;
moins ambigu ;
plus proche du modèle métier.

Est-ce que l’addon actuel est déjà prêt pour ça ?
Partiellement oui, mais pas complètement
Ce qui existe déjà :
l’addon sait ouvrir une inspection ; 
l’addon sait envoyer des commandes whisper à un bot ; 
l’addon a déjà des représentations de slots d’équipement dans d’autres zones du code. 

Ce qui manque encore :
une action UI dédiée “unequip” dans la vue d’inspection ;
un mapping propre entre slot UI et payload ue ;
et probablement un refresh fiable après l’action.

Le point technique le plus important à ne pas oublier
Le refresh après ue
Aujourd’hui, le handler refresh l’inventaire lorsqu’il détecte des messages du bot du genre :
equipping
using
destroyed
etc. 

Donc si la commande ue renvoie un message différent, par exemple :
unequipping
removed
taking off
ou autre
alors il faudra penser à raccrocher ce retour au refresh.
Sinon l’action pourra marcher côté bot, mais l’UI ne se resynchronisera pas proprement.

C’est probablement le principal piège de cette feature.

UX recommandé
Je verrais plutôt :

Option 1 — clic droit sur slot équipé
Très naturel :
clic gauche = comportement standard / tooltip ;
clic droit = ue sur le slot.

Option 2 — mode “Unequip”
Comme dans INVENTORY avec les modes d’action :
tu actives “Unequip” ;
puis tu cliques un slot inspecté.
C’est cohérent avec la philosophie existante de MultiBot, mais probablement un peu plus lourd que nécessaire.

Option 3 — petit bouton contextuel / menu sur slot
Plus explicite, mais visuellement plus chargé.
Mon avis
Le clic droit sur le slot équipé est probablement la meilleure UX :
rapide,
lisible,
très cohérent avec une frame d’inspection.

Au final
Condition indispensable
Il faut juste confirmer précisément :
la syntaxe réelle de ue,
si elle cible un slot ou un item,
quel message de retour elle produit, pour rebrancher le refresh.
Si ces 3 points sont clairs, alors oui, ça vaut complètement le coup de l’exposer graphiquement dans l’inspection d’un bot.


