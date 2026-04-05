TODO

* Milestone 10 voir pourquoi les quetes incompletes ne s'affichent pas par bot
* Uniformiser le template des frame quetes comme celle de Itemus
* Uniformiser le template de la frame reward comme celle de itemus
* Raidus doit se rafraichir à l'ouverture et fermeture
* dans la liste des quêtes des fois c'est l'ID de la queête qui apparait et pas le tritre
* Mettre une option pour choisir la tailles des icones de la main barre et des quickhunter/shaman
* Voir si il y'a pas d'autres option que l'on peut ajouter à la frame options de multibot
* creer le multilangue pour le tooltip: setTooltip(self, "Show / Hide / Move Quick Shaman") des fichiers quickshaman et quickhunter
* Finir les options de déplacement des boutons
* faire en sorte que les menus déroulants de la main barre se ferment quand on on ouvre un autre
* revoir le fichiers UI/MultiBotTalent, la partie des glyphes et des talents car il y'a eu des modifications dans le fichiers .conf de multibot
* pourquoi les glyphes sont longues a afficher?
* Implémenter la commande outfit
* implémenter RTI

Comment marche outfit:

Les commande de outfit sont les suivantes:

outfit <name> +[item] to add items
outfit <name> -[item] to remove items
outfit <name> equip/replace/reset(efface le set en question)/update(créé un set outfit) to equip items

Lors de leurs création les sets outfit sont gardés en mémoire dans une liste simple vector<string> le module garde les outfits dans la valeur AI outfit list
Exemple:
pve=42943,48685,44195.....
heal=44202,44309,37111.....

Les outfits restent en mémoire mais ne sont pas sauvegardés dans la table : playerbots_db_store, pour les sauvegarder il faut wisp au bot par exemple : nc +passive
Si il y'a plkusieurs outfits ils sont sauvegardés sous forme : pve=42943,48685,44195,....^heal=44202,44309,37111,...^resist=123,456,....


Créer un outfit : 
1) Tu mets au bot son stuff PvE

Soit en lui faisant équiper ses pièces une par une, soit par n’importe quel moyen que tu utilises déjà pour lui mettre son équipement.

2) Tu snapshots ce qu’il porte actuellement
/w NomDuBot outfit pve update

Ça enregistre tout ce qu’il a actuellement équipé dans un outfit nommé pve.

3) Tu mets ensuite au bot son stuff PvP
4) Tu snapshots à nouveau
/w NomDuBot outfit pvp update

Ça crée l’outfit pvp.

Ensuite pour switcher

Pour équiper un set déjà enregistré :

/w NomDuBot outfit pve equip

ou

/w NomDuBot outfit pvp equip
Différence entre equip et replace

C’est important :

equip
/w NomDuBot outfit pve equip

Le bot essaie d’équiper les items du set, sans vider d’abord tout l’équipement actuel.

replace
/w NomDuBot outfit pve replace

Là, le bot range d’abord son équipement actuel dans ses sacs, puis équipe le set.

Donc pour un vrai switch complet PvE ↔ PvP, le plus propre est souvent :

/w NomDuBot outfit pve replace
/w NomDuBot outfit pvp replace
Voir les outfits enregistrés
/w NomDuBot outfit ? un wisp directe ne marche pas il faut un /W nom du bot

Ça affiche la liste des outfits et leurs items.

Ajouter ou retirer des pièces à la main

Le code supporte aussi :

/w NomDuBot outfit <nom> +[item]
/w NomDuBot outfit <nom> -[item]

Exemple :

/w NomDuBot outfit pve +[Épée du boss]
/w NomDuBot outfit pve -[Ancien casque]

Là, il faut en pratique envoyer un lien d’objet cliquable en chat.
Le parseur lit les Hitem: des links WoW, donc ce n’est pas fait pour taper juste un nom brut au clavier.

Reset d’un outfit

Pour supprimer le contenu d’un set :

/w NomDuBot outfit pve reset
Procédure conseillée pour toi

Pour créer pve et pvp proprement :

1. Mettre le bot en stuff PvE
2. /w BotName outfit pve update

3. Mettre le bot en stuff PvP
4. /w BotName outfit pvp update

5. Vérifier
   /w BotName outfit ?

6. Switch quand tu veux
   /w BotName outfit pve replace
   /w BotName outfit pvp replace
Petit point utile

L’outfit stocke des item IDs. Donc conceptuellement, c’est bien un set d’objets, pas un vrai “gear manager” avancé avec profils complexes.

Je peux aussi te faire un mini mémo ultra court des commandes outfit, prêt à garder sous la main en jeu.

Mettre en place un gestionnaire d'outfits, genre outfitter mais sur le bot