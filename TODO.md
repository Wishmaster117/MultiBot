TODO

* Essayer de faire disparaitre la barre multibots au bout d'un temps et la faire apparaitre quand on passe la souris dessus.
* Faire en sorte que le réglage strata prenne en compte toutes les frames de multibots
* Mettre un bouton style décursive pour cacher la shaman quick et hunter quick
* Quand on deplace ou fait quelque chose dans l'ui il faudrait que ça se sauvegarde tout de suite dans les variables dans deco reco
* Raidus doit se rafraichir à l'ouverture et fermeture
* dans la liste des quêtes des fois c'est l'ID de la queête qui apparait et pas le tritre
* Afficher le pognon et les places de sacs dans la frame inventaire
* La fenêtre inventaire doit se rafraichir par exemple quand on fait le bot bouffer il faut que ce qu'il a bouffé se décompte

Ajouter unequipe item a multibot

Oui, avec ue [item], c’est encore plus faisable
Le fait que la commande soit :

ue [item]

change beaucoup la réponse : oui, c’est très faisable via interface graphique sur l’inspection d’un bot, et même de façon assez propre.

Pourquoi c’est une bonne nouvelle
1) Le protocole actuel de MultiBot sait déjà très bien travailler “par item link”
Dans la frame INVENTORY actuelle, les actions envoyées au bot sont déjà construites sous la forme :

s [item]

e [item]

u [item]

give [item]

destroy [item]

Donc l’addon a déjà exactement le pattern dont on a besoin :

récupérer un lien d’objet,

construire une commande whisper,

l’envoyer au bot. 

Du coup, ue [item] s’insère très naturellement dans le modèle existant.

Pourquoi l’inspection est un bon endroit pour ça
2) L’inspection ouvre déjà le bon contexte bot
Le code actuel a déjà un flux “Inspect bot” :

le bouton Inspect appelle InspectUnit(tName),

et déclenche aussi une requête d’inventaire du bot. 

Donc on a déjà :

le nom du bot cible,

l’ouverture de l’inspection,

et un écosystème UI orienté équipement / inventaire.

3) Si la commande cible l’item équipé, le clic sur un slot inspecté devient naturel
Comme ue attend un item link, la bonne UX serait simplement :

tu inspectes le bot,

tu cliques un slot équipé,

l’addon récupère le lien de l’objet porté,

puis envoie ue [item] au bot.

En pratique, c’est beaucoup plus simple que si la commande demandait un bag/slot exact.

Est-ce qu’il y a un risque d’ambiguïté ?
Oui, mais il est limité
Si tu fais l’action depuis un slot d’équipement visible, l’ambiguïté est faible :

l’utilisateur clique précisément l’objet actuellement porté ;

l’UI connaît l’objet visé.

Le seul vrai point à valider côté backend, c’est :

est-ce que ue [item] fonctionne bien même si le bot possède aussi un autre exemplaire identique dans ses sacs ?

Mon intuition
Souvent, si la commande backend interprète “unequip cet item équipé” à partir du lien, ça peut marcher correctement.
Mais ce point dépend totalement du code playerbots.

Donc :

UI : oui

ambiguïté backend : à vérifier

Là où il faut rester attentif
1) Le refresh après ue
Aujourd’hui, le handler refresh l’inventaire sur certains retours comme :

equipping

using

destroyed

etc. 

Donc si ue [item] renvoie un texte différent :

unequipping

removed

taken off

ou autre

il faudra penser à brancher ce message sur un refresh, sinon :

l’action peut réussir côté bot,

mais l’UI peut rester visuellement périmée.

C’est probablement le principal point technique.

2) L’inspection standard n’est pas encore enrichie par MultiBot pour cette action
Le code actuel montre bien le point d’entrée Inspect, mais pas encore une logique UI “unequip depuis le slot inspecté”. 

Donc oui, c’est faisable, mais aujourd’hui :

ce n’est pas encore implémenté

il faudrait ajouter cette interaction explicitement.

Quelle UX je recommanderais
Avec ue [item], ma recommandation serait :

Option la plus propre : clic droit sur item équipé dans l’inspection
Pourquoi ?

très naturel,

pas besoin d’un mode supplémentaire,

cohérent avec une action contextuelle sur équipement,

évite d’alourdir la fenêtre.

Option alternative : petit bouton Unequip”
Possible aussi, mais moins élégant.

Option que je recommanderais moins
Un mode global “Unequip” comme dans INVENTORY.
Ça marcherait, mais ce serait plus lourd qu’un simple clic contextuel sur un slot inspecté.

Donc, mon verdict
Oui, ça vaut le coup
Avec ue [item], oui, tu peux très raisonnablement exposer ça graphiquement dans la fenêtre d’inspection d’un bot.

Pourquoi c’est une bonne feature
le protocole s’aligne avec le modèle actuel “commande par item link” ; 

l’inspection est déjà présente ; 

l’action est conceptuellement liée à l’équipement, donc mieux placée là que dans la grille INVENTORY.

Ce qu’il faudra juste confirmer
que ue [item] déséquipe bien l’objet porté quand on lui passe le lien ;

quel message texte renvoie le bot après l’action ;

si l’UI doit refresh seulement l’inventaire, ou aussi l’inspection.

Réponse courte
Oui, avec ue [item], c’est une très bonne candidate pour une intégration UI sur l’inspection d’un bot.
Le vrai point de vigilance n’est pas l’interface, mais le refresh et la validation backend de la commande sur les objets équipés. 