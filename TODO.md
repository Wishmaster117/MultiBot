TODO

* Vente d'items de quetes, ça les vends quand même mais le bot les récupère, normallement ça devrait dire qu'il ne peux pas vendre un item de quête
* Voir si y'a pas d'autres appels à pageLabel:SetText(MB_PAGE_DEFAULT) dans les fichiers et remplacer par : +	pageLabel:SetText(MultiBot.MB_PAGE_DEFAULT or "0/0")
* Uniformiser le template des frame quetes comme celle de Itemus
* Uniformiser le template de la frame reward comme celle de itemus
* Essayer de faire disparaitre la barre multibots au bout d'un temps et la faire apparaitre quand on passe la souris dessus.
* Quand on deplace ou fait quelque chose dans l'ui il faudrait que ça se sauvegarde tout de suite dans les variables dans deco reco
* Raidus doit se rafraichir à l'ouverture et fermeture
* dans la liste des quêtes des fois c'est l'ID de la queête qui apparait et pas le tritre
* Mettre une option pour choisir la tailles des icones de la main barre et des quickhunter/shaman
* Voir si il y'a pas d'autres option que l'on peut ajouter à la frame options de multibot
* creer le multilangue pour le tooltip: setTooltip(self, "Show / Hide / Move Quick Shaman") des fichiers quickshaman et quickhunter
* Finir les options de déplacement des boutons
* Debuguer le blocage de la barre principale en déplacement ça a l'air de ne pas persister apres une deco reco
* Menu misc: faire en sorte que les barres horizontales des autres bots se ferment et que le menu se referme après avoir selectionné une action et que quand ce menu se referme toutes les barres de réouvrent.
* faite aussi ceci pour tout les menus deroulants de la every barre