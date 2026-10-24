# À inscrire en base — ce que les découpages de villes ont révélé

Ce fichier recense ce que la base `histgis` devrait savoir et ne sait pas, constaté en
découpant les villes multicantonales (`cartes/coupes_ville.csv`, `sql/98_coupe_ville.sql`,
skill `decoupe-ville`). **Rien de ce qui suit n'a été écrit en base** : un découpage range des
lignes et des ancres, il ne crée ni unité, ni fraction, ni appartenance. C'est à Adrien de
décider, et de l'inscrire par un fichier SQL numéroté.

Tenu à jour à chaque ville. Une entrée faite passe dans « Fait », avec le fichier SQL qui l'a
inscrite.

Le trou général des appartenances cantonales 1941-1998 est suivi ailleurs
(`RESTE_A_FAIRE.md`, point 1 ; `93`, `95`, `97`). Il touche toutes les fractions : 1941-1968
partout, puis de 1973 à la date COG de la fraction (1982 à 1998 selon la ville). Ici, seulement
ce qui est propre à une ville découpée, avec sa source.

**Couverture de 1941 — `sql/116_villes_couverture_1941.sql`, 13 octobre 2026.** Arbitrage
d'Adrien : « la base doit couvrir le maximum entre 1815 et 2025 ». Les fractions de 61 villes sont
posées de 1941 à la reprise de leur régime : jusqu'en 1968 quand la ville a les mêmes fractions des
deux côtés (119 fractions), jusqu'à la fin connue du régime pour Tours (1956), Angers, Le Havre,
Toulon, Versailles (1964), Le Mans (1967), Caen, Metz (1968), Marseille, Nantes, Montpellier,
Chalon, Montluçon, La Rochelle (1973), Rouen (1982), et pour Moulins (1973, puis 1985). Dans les
entrées ci-dessous, « les fractions de 1941 à 1968 » est donc fait ; restent les régimes
intermédiaires (Le Mans 1967-1982, Le Havre 1964-1992, Tours 1956-1968, Angers 1964-1973…), qui
demandent leurs lignes, les communes rurales, et les villes dont les fractions diffèrent en 1940
et à la reprise sans date connue (Lille, Lyon, Strasbourg, Limoges, Orléans, Brest, Amiens…).

---

## Bourg-en-Bresse (01053)

### 1. Les cantons Bourg-en-Bresse-I, II et III (1973-1982) n'existent pas

- **Inscrit par `sql/115_villes_nomenclature.sql` (13 octobre 2026)** : I sous 0137 (Nord-Centre), II sous 0105 (Est), III sous 0138 (Sud), du 1973-09-23 au 1982-01-26, avec Polliat, Saint-Denis-lès-Bourg, Viriat, Buellas, Lent, Montagnat, Montcet, Montracol, Péronnas, Saint-André-sur-Vieux-Jonc et Saint-Rémy ; les ancres non datées de 1982 servent aux deux régimes. Reste : Servas et Saint-Just (déjà rangés, non revus) ; Bourg-Couronne (point 2).
  Règle de nomenclature du 13 octobre 2026 (Adrien) : pas d'unité nouvelle, le canton disparu est porté par l'unité du régime suivant qui hérite de la plus grande part de son territoire dans la ville.

- **Source** : décret n° 73-810 du 16 août 1973 (JO du 17 août 1973),
  `cantons/communes_coupees_1973_1984.csv`.
- **Manque** : aucune unité (`unit`), aucune fraction de 5260, aucune appartenance. L'atome
  entier 5260 est dans 0105 « Bourg » jusqu'au 1973-09-23, puis dans rien jusqu'au 1982-01-26.
  Décision de nomenclature laissée en suspens par Adrien.
- **À inscrire** : trois unités, trois fractions `5260#<unité>`, appartenances
  **1973-09-23 → 1982-01-26**. Communes rurales d'après le décret :
  - I : Polliat, Saint-Denis-lès-Bourg ;
  - II : Viriat, Saint-Just ;
  - III : Buellas, Lent, Montagnat, Montcet, Montracol, Péronnas, Servas, Saint-André,
    Saint-Rémy.
- **Déjà prêt** : lignes `01053-4` et `01053-5` (valables 1973-09-23 → 1982-01-26), rangées
  sans ancre. Ancres à poser dans `cartes/coupes_ville_ancres.csv` une fois les fractions
  créées :
  - I : `POINT(871632 6570763)` (ouest) ;
  - II : `POINT(874000 6570000)` (nord-est) ;
  - III : `POINT(871300 6568700)` (sud).

  Puis `pose_coupe.py 01053 --coupe-id 01053-4 --coupe-id 01053-5 … --ancre …` à
  `--date-test 1978-01-01`, sans `--morceaux`.

### 2. Bourg-Couronne (1982) n'a pas d'unité

- **Inscrit par `sql/117_creations_caen_rochefort_bourg_larochelle.sql` (13 octobre 2026, accord d'Adrien)** : unité `C01-Bourg-Couronne` créée, ses onze communes du 1982-01-26 au 1985-03-10 (le canton est supprimé le 24 décembre 1984) ; Viriat dans 0143 de 1985 à 1998. Entrée close.

- **Source** : décret n° 82-77 du 25 janvier 1982 (JO du 26 janvier 1982, art. 1er) :
  Péronnas, Buellas, Lent, Montcet, Montracol, Polliat, Saint-André-sur-Vieux-Jonc,
  Saint-Rémy, Servas, Vandeins, Viriat ; chef-lieu Péronnas.
- **Manque** : l'unité ; ses communes n'ont pas d'appartenance pour 1982-1998 (Viriat n'a pas de
  canton en 1990 dans la base). Même décision de nomenclature que le point 1.
- Ne touche pas la ville elle-même : aucune ligne n'en dépend.

---

## Aix-en-Provence (13001)

### 4. Les trois cantons de 1982 commencent en 1992 dans la base

- **Inscrit par `sql/114_villes_lot_2.sql` (13 octobre 2026)** : les fractions Nord / Sud sur 1941-1968 et 1973-1982, les trois fractions de 1982-03-14 à 1992 ; Éguilles et Meyreuil dans 1302 de 1973 à 1992 ; les noms Nord-Est, Sud-Ouest, Centre dès 1982. Reste : la ligne Nord / Sud, faute de texte ; les communes rurales de 1301 et 1347 après 1982.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Source** : décret n° 82-119 du 2 février 1982 (JO du 4 février 1982, p. 454-455) : Centre,
  Nord-Est et Sud-Ouest remplacent Aix-Nord et Aix-Sud.
- **Base** :
  - `320#1301`, `320#1302` et `320#1347` n'ont d'appartenance qu'à partir du **1992-03-22** ;
  - 1301 et 1302 portent les noms « Aix-en-Provence-Nord / -Sud » jusqu'en 1999, alors que le
    décret dit Nord-Est / Sud-Ouest dès 1982 ;
  - de 1973-09-23 à 1992, aucune fraction d'Aix n'a de canton ;
  - `mouvements_cantonaux.csv` range le partage en « 1941-1986, borne_sup ».
- **À inscrire** :
  - appartenances des trois fractions à partir de **1982-02-04** (JO) ;
  - noms Nord-Est / Sud-Ouest à partir de cette date ;
  - le régime Aix-Nord / Aix-Sud n'a pas de texte de 1973 (cherché le 6 octobre 2026) :
    `chronologie_cantonale.csv` ne connaît aucun acte touchant Aix entre le découpage d'origine
    (1801) et le décret 82-119, et le décret 73-812 ne concerne que Marseille, Allauch et
    Marignane. Le partage Nord / Sud est donc continu de 1801 à 1982 ; les bornes 1941-1968 et
    1973-09-23 sont des trous de `membership`. À inscrire : appartenances de `320#1301` (Nord)
    et `320#1302` (Sud) sur 1941-1968 et du 1973-09-23 à la date retenue pour 1982 (communes
    rurales inchangées : Le Tholonet, Saint-Marc-Jaumegarde, Vauvenargues, Venelles / Éguilles,
    Meyreuil).
- **Ligne Nord / Sud : non tracée, faute de texte.** Rien dans `cantons/`, `jorf_txt/` (37
  fichiers citent Aix), `circo/`, `annexes/gaudillere/`, `cog1954/`, `cog1968/`, `sources/trfgis`, ni
  sur les photos 24-26 de `photos/1815_1870/`. Le décret 82-119 remplace les deux cantons sans les
  décrire ; Gaudillère ne divise Aix entre circonscriptions qu'en 1986. Source à fournir : arrêté
  du 17 frimaire an X, ou plan annexé au décret 82-119 (préfecture).
- Le décret 82-119 est absent de `cantons/communes_coupees_1973_1984.csv`.
- **Ligne** : `13001-1` et `13001-2` valent depuis le 1982-03-14 ; à aligner sur la date retenue.

---

## Lisieux (14366)

### 5. Le 3e canton : 1985, 1991 ou 1998 ?

- **Sources** :
  - décret n° 85-144 du 31 janvier 1985 (JO du 1er février 1985), qui crée Lisieux-II et
    Lisieux-III ;
  - décret du 27 février 1991 (JO du 28 février 1991), qui « crée » de nouveau Lisieux-III avec
    la même limite. Cela laisse penser que le décret de 1985 a été annulé : **à vérifier**,
    Conseil d'État 1985-1990.
- **Base** : `19690#1449` (3e canton) à partir du **1998-03-15**. `19690#1421` et `#1422` n'ont
  aucune appartenance de 1973-09-23 à 1998-03-15.
- **À inscrire** : selon la réponse sur l'annulation, le 3e canton à partir du 1985-03-10
  (cantonales) ou du 1991-02-28 (JO), et le 1er et le 2e sur 1973-1998.
- **Ligne** : `14366-3` et `14366-4` valent depuis le 1985-03-10 ; à aligner.

### 6. La cible de Lisieux avant 1960 est fausse

- Lisieux absorbe Saint-Jacques le 31 janvier 1960 (`insee_mvt`). L'ANR donne 278 ha de 1875 à
  1960, puis 1 308 ha.
- Mais `cible_ville()` réunit l'ANR de l'atome 19690 et le polygone GEOFLA 2011 des fractions
  (`atom_geom`), soit **1 346 ha dès 1900**. Les fractions de Lisieux dessinées avant 1960
  couvrent donc Saint-Jacques.
- Ce n'est pas une inscription, c'est un défaut de géométrie : soit une ANR datée pour les
  fractions, soit une `cible_ville()` qui s'en tient à l'ANR de l'atome entier quand elle existe.
- **Réglé le 27 septembre 2026 (Lille)** : `cible_ville()` donne désormais à chaque fraction l'ANR
  de son atome-mère (`cassini`). Lisieux fait 278 ha avant 1960. Les lignes `14366-1` et `-2`
  gardent leur date du 1960-01-31, celle de la fusion.

---

## Charleville-Mézières (08105)

### 7. Le régime 1973-1982 n'est ni en base ni tracé

- **Source** : décret n° 73-715 du 23 juillet 1973 (JO du 25 juillet 1973) : Charleville-La
  Houillère, Mézières-Centre-Ouest… (`cantons/communes_coupees_1973_1984.csv`).
- **Base** : l'atome 8443 est dans 0815 jusqu'au 1973-09-23 ; les cinq fractions commencent au
  1982-03-14.
- **À inscrire** : le régime 1973-1982. Les lignes pourront être tracées sur le texte de 73-715,
  comme Bourg 1973.

---

## Laon (02408)

### 10. L'échange de territoire de 1997 avec Athies-sous-Laon n'est pas dans l'ANR

- **Source** : décret du 13 février 1997 (JO du 16 février 1997). 21 ha 75 a 75 ca de Laon
  (partie Laon-Nord) passent à Athies-sous-Laon (Laon-Sud), et 13 ha 06 a 19 ca d'Athies
  passent à Laon. « Les limites territoriales des cantons de Laon-Nord et de Laon-Sud sont
  modifiées par voie de conséquence. »
- **Base** : `atom_geom_anr` n'a qu'un état pour Laon (18722, 1790-2020, 4 457 ha) et pour
  Athies (1566, 1790-2020).
- **À inscrire** : deux états ANR (avant et après le 1997-02-16), si la source ANR les donne ;
  sinon, signaler l'échange comme non représenté. Le canton de la part reçue par Laon n'est pas
  dit : sans doute Laon-Sud, qui borde Athies.

---

## Moulins (03190)

### 14. Moulins-Ouest et Moulins-Sud de 1973 à 1985, et un texte qui diverge de la ligne posée

- **13 octobre 2026** : réponse d'Adrien : « Moulins une ligne distincte ». Ligne `03190-2` écrite (1973-09-23 → 1985-03-10, décret 73-713) ; `03190-1` s'arrête au 1973-09-23 et sa géométrie est reprise sous `03190-3` de 1985 à 2013. Le décret donne toute la rive gauche à Moulins-Ouest : Sud 404,2 ha, Ouest 465,8 ha, contre 475,4 et 394,6 par Gaudillère (71 ha). Fractions inscrites par `sql/116` : Est / Ouest de 1941 à 1973, Sud / Ouest de 1973 à 1985. Reste : la limite d'après 1985 (aucun texte lu ; Gaudillère reprise faute de mieux) ; la berge de la rive gauche, tracée en trois segments.

- **Source** : décret n° 73-713 du 23 juillet 1973 (JO du 25 juillet 1973). Moulins-Sud (Bressolles,
  Toulon-sur-Allier et une partie de la ville) est délimité « du Nord au Sud » par la rue de
  Decize, la rue des Potiers, le cours Jean-Jaurès, la rue d'Allier, la place d'Allier, **la rue
  Blaise-Pascal, la place Garibaldi, la rue Jean-Bart, le pont Régemortes et la rive gauche de
  l'Allier** ; Moulins-Ouest a le reste.
- **Base** : les fractions `24214#0323` et `#0324` n'ont pas de canton de 1941 à 1985.
- **Ligne** : `03190-1` suit le texte de Gaudillère donné par Adrien (« … place d'Allier, rues
  du Pont-Guinguet, Laussedat, Règemortes, avenues de la Libération, Michelet »), sur 1870-2013,
  car Gaudillère ne montre aucun changement de 1815 à 1985. **Le décret de 1973 diverge après la
  place d'Allier.**
- **Question pour Adrien** : faut-il une ligne 1973-1985 sur le texte du décret, distincte de
  celle de Gaudillère ? Les deux textes décrivent-ils la même limite avec des noms différents ?

---

## Gap (05061)

### 15. Gap-Centre, Gap-Est, Gap-Ouest et Gap-Campagne de 1973 à 1982 : absents de la ville

- **Inscrit par `sql/115_villes_nomenclature.sql` (13 octobre 2026)** : Campagne 0509, Centre 0526, Est sous 0529 (Sud-Est), Ouest sous 0530 (Sud-Ouest), du 1973-09-23 au 1982-03-14 ; ancres datées par régime. Reste : rien pour la ville.
  Règle de nomenclature du 13 octobre 2026 (Adrien) : pas d'unité nouvelle, le canton disparu est porté par l'unité du régime suivant qui hérite de la plus grande part de son territoire dans la ville.

- **Sources** :
  - décret n° 73-651 du 13 juillet 1973 (JO du 17 juillet 1973), art. 2 : le canton de Gap est
    divisé en Gap-Centre, Gap-Ouest, Gap-Est (parties de la ville seules) et Gap-Campagne (La
    Freissinouse, Manteyer, Pelleautier, La Roche-des-Arnauds-Rabou, Romette et la partie de Gap
    au Nord et au Nord-Ouest du canal du Drac) ;
  - décret n° 82-78 du 25 janvier 1982 (JO du 26 janvier 1982, p. 372) : Gap-Est devient
    Gap-Nord-Est et Gap-Sud-Est, Gap-Ouest devient Gap-Nord-Ouest et Gap-Sud-Ouest.
- **Base** :
  - l'atome entier 15035 est dans 0509 jusqu'au 1973-09-23 ; les six fractions
    (`15035#0509`, `#0526` à `#0530`) ne commencent qu'au **1982-03-14**. De 1973-09-23 à
    1982-03-14, **la ville de Gap n'a aucun canton** ;
  - aucune unité pour Gap-Est et Gap-Ouest (1973-1982) ; 0526 Gap-Centre existe, mais n'a
    d'appartenance qu'à partir de 1982 ;
  - les communes rurales de Gap-Campagne sont bien dans 0509 dès 1973. Mais 0509 s'appelle
    « Gap » jusqu'en 1999, et « Gap-Campagne » seulement ensuite : même cas que les points 9, 11
    et 12, cette fois hors de l'Aisne. La règle générale probable du point 12 se confirme ;
  - Romette, réunie à Gap le 1er janvier 1975 (INSEE ; 1974-01-01 dans l'ANR), est déjà comprise
    dans la cible de Gap avant la fusion.
- **À inscrire** :
  - deux unités, Gap-Est et Gap-Ouest (1973-09-23 → 1982-03-14) ;
  - quatre fractions de Gap sur cette période (Campagne 0509, Centre 0526, Est, Ouest).
- **Déjà prêt** : lignes `05061-6`, `-7`, `-8` (1973-09-23 → 1982-03-14), rangées sans ancre,
  4 morceaux conformes. Ancres à poser : Campagne `POINT(943000 6396000)`, Centre
  `POINT(943500 6389500)`, Ouest `POINT(941500 6386500)`, Est `POINT(945500 6390000)`. Les
  lignes `05061-1` à `-5` (1982-2013) sont posées, ancrées et conformes.

---

## Manosque (04112)

### 17. Manosque de 1973 à 1988 : un trou de quinze ans, pour la ville et pour ses communes rurales

- **Inscrit par `sql/115_villes_nomenclature.sql` (13 octobre 2026)** : Nord 0413 et Sud sous 0432 (Sud-Est) de 1973 à 1985, les trois fractions de 1985 à 1988 ; Corbières, Sainte-Tulle, Montfuron et Pierrevert (0432, puis 0433 pour les deux dernières en 1985) ; ancres datées, une ancre Nord dans Saint-Martin-les-Eaux pour 1974-1980. Reste : l'appartenance de Saint-Martin-les-Eaux (double compte à trancher) ; la chronologie.
  Règle de nomenclature du 13 octobre 2026 (Adrien) : pas d'unité nouvelle, le canton disparu est porté par l'unité du régime suivant qui hérite de la plus grande part de son territoire dans la ville.

- **Sources** :
  - décret n° 73-714 du 23 juillet 1973 (JO du 25 juillet 1973), art. 3 : Manosque-Nord
    (Saint-Martin-les-Eaux, Volx et le nord de la ville) et Manosque-Sud (Corbières, Montfuron,
    Pierrevert, Sainte-Tulle et le reste de la ville) ;
  - décret n° 85-127 du 29 janvier 1985 (JO du 30 janvier 1985), art. 3 : Manosque-Nord (mêmes
    communes rurales), Manosque-Sud-Est (Corbières, Sainte-Tulle) et Manosque-Sud-Ouest
    (Montfuron, Pierrevert).
- **Chronologie fausse** : `cantons/chronologie_cantonale.csv` (Gaudillère, annexe VII) date la
  division en trois du « D. 20.2.1986 ». Le décret 86-251 de ce jour-là (JO du 26 février 1986)
  ne touche que Saint-Paul et Senez. Le texte de Manosque est bien celui du 29 janvier 1985.
- **Base** :
  - l'atome 20929 est dans 0413 jusqu'au 1973-09-23. Les trois fractions ne commencent qu'au
    **1988-09-25** : de 1973 à 1988, **la ville n'a aucun canton** ;
  - **Corbières, Montfuron, Pierrevert et Sainte-Tulle n'ont aucun canton de 1973-09-23 à
    1988-09-25**. Saint-Martin-les-Eaux non plus : elle est dans Reillanne jusqu'en 1973, puis
    n'a plus rien jusqu'en 1988. Seule Volx est suivie sans trou, dans 0413 ;
  - aucune unité Manosque-Sud (1973-1985) ;
  - 0413 s'appelle « Manosque » jusqu'en 1999, et non « Manosque-Nord » : sixième cas de la
    règle du point 12 ;
  - Saint-Martin-les-Eaux a été réunie à Manosque du 1er janvier 1975 au 12 juin 1980 (ANR :
    1974-01-01 → 1980-01-01). Même question de double compte qu'à Briançon (point 16) si
    l'atome de Saint-Martin reçoit un canton sur cette période.
- **À inscrire** :
  - l'unité Manosque-Sud (1973-09-23 → 1985-03-10) ;
  - les fractions de Manosque : Nord et Sud de 1973-09-23 à 1985-03-10, puis Nord, Sud-Est et
    Sud-Ouest de 1985-03-10 à 1988-09-25 ;
  - les communes rurales : Corbières, Montfuron, Pierrevert et Sainte-Tulle dans Manosque-Sud
    (1973-1985), puis dans 0432 et 0433 (1985-1988) ; Saint-Martin-les-Eaux dans 0413 dès 1973.
- **Déjà prêt** :
  - `04112-1` et `-2` (1985-03-10 → 2013), ancrées. Elles couvrent déjà 1985-1988 par
    chevauchement.
  - `04112-3` (1973-09-23 → 1985-03-10) et `04112-4` (Saint-Martin, 1974 → 1980), rangées sans
    ancre. Ancres à poser : Nord `POINT(922500 6311000)`, Sud `POINT(924250 6305700)`.
  - La fin de `04112-3` après l'avenue du Moulin-Neuf est une déduction arbitrée par Adrien
    (lieu-dit le Moulin Neuf, puis au plus près de la limite de Valensole).

---

## Antibes (06004)

### 20. Antibes, Biot et Vallauris de 1973 à 1998 : vingt-cinq ans sans canton

- **Inscrit par `sql/115_villes_nomenclature.sql` (13 octobre 2026)** : Nord sous 0601 (Antibes-Biot), Sud sous 0647 (Antibes-Centre) de 1973 à 1985, les trois fractions de 1985 à 1998 ; Biot dans 0601, Vallauris dans 0647 puis 0635 ; ancres datées. Reste : le texte qui renomme Antibes-Sud en Antibes-Centre ; Vallauris en double en 1969-1973.
  Règle de nomenclature du 13 octobre 2026 (Adrien) : pas d'unité nouvelle, le canton disparu est porté par l'unité du régime suivant qui hérite de la plus grande part de son territoire dans la ville.

- **Sources** :
  - décret n° 73-811 du 16 août 1973 (JO du 17 août 1973), art. 2 : Antibes-Nord (Biot et le
    nord-est de la ville) et Antibes-Sud (Vallauris et le reste) ;
  - décret n° 85-143 du 31 janvier 1985 (JO du 1er février 1985, p. 1378), art. 3 : « en
    remplacement des cantons d'Antibes-Nord et Antibes-Centre » (donc Antibes-Sud a été renommé
    Antibes-Centre entre 1973 et 1985 : texte à trouver). Il crée Antibes-Biot,
    Antibes-Centre et Vallauris-Antibes-Ouest. La chronologie cantonale écrit
    « Vallauris-Antibes-E. » ; le JO dit Ouest.
- **Base** :
  - l'atome 951 est dans 0601 jusqu'au 1973-09-23. Les trois fractions ne commencent qu'au
    **1998-03-15** : de 1973 à 1998, **la ville n'a aucun canton** ;
  - **Biot et Vallauris n'ont aucun canton de 1973-09-23 à 1998-03-15** ;
  - Vallauris a deux appartenances en 1969-1973 (0601 et 0620) : à vérifier ;
  - aucune unité pour Antibes-Nord, Antibes-Sud (1973-1985). Aucun nom avant 1999 pour 0635 et
    0647. 0601 s'appelle « Antibes » jusqu'en 1999, et « Antibes-Biot » ensuite : neuvième
    cas de la règle du point 12.
- **À inscrire** :
  - les unités Antibes-Nord et Antibes-Sud (Antibes-Centre ?), de 1973-09-23 à 1985-03-10 ;
  - les fractions d'Antibes de 1973 à 1998 ;
  - Biot et Vallauris dans leurs cantons de 1973 à 1998.
- **Déjà prêt** :
  - `06004-1` et `-2` (1985-03-10 → 2013), ancrées. Elles couvrent déjà 1985-1998.
  - `06004-3` (1973-09-23 → 1985-03-10), rangée sans ancre. Ancres à poser : Nord
    `POINT(1031335 6286328)`, Sud `POINT(1031942 6283235)`.
- **Îlots** : la cible d'Antibes est un multipolygone (13 îlots, 0,58 ha). `98` les rattache
  désormais au morceau ancré le plus proche (règle du 26 septembre 2026).

---

## Cagnes-sur-Mer (06027)

### 21. Le canton de Cagnes de 1973 à 1998 : un trou en trois temps

- **Inscrit par `sql/114_villes_lot_2.sql` (13 octobre 2026)** : les cinq communes dans 0605 de 1973 à 1982 ; Est et Ouest de 1982 à 1985, Centre, Ouest, Est de 1985 à 1998 ; Saint-Laurent-du-Var dans 0605 jusqu'en 1998 ; les noms. Reste : l'ancre de `06027-3`.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Sources** :
  - décret n° 82-79 du 25 janvier 1982 (JO du 26 janvier 1982), art. 1er : Cagnes-Est
    (Saint-Laurent-du-Var et l'est de la ville) et Cagnes-Ouest (Villeneuve-Loubet,
    La Colle-sur-Loup, Saint-Paul et l'ouest de la ville) ;
  - décret n° 85-143 du 31 janvier 1985 (JO du 1er février 1985), art. 4 : Cagnes-sur-Mer-Centre
    (la ville seule), Cagnes-sur-Mer-Ouest et Saint-Laurent-du-Var-Cagnes-sur-Mer-Est.
- **Base** :
  - de 1973 à 1982, le canton de Cagnes-sur-Mer (0605) est entier. Aucune de ses cinq
    communes (Cagnes, Saint-Laurent-du-Var, Villeneuve-Loubet, La Colle-sur-Loup, Saint-Paul)
    n'y a d'appartenance de 1973-09-23 à 1982-03-14 ;
  - Villeneuve-Loubet, La Colle-sur-Loup et Saint-Paul sont bien dans 0645 dès le 1982-03-14 ;
  - **Cagnes (atome 6536) et Saint-Laurent-du-Var n'ont aucun canton de 1973-09-23 à
    1998-03-15**. Les fractions de Cagnes ne commencent qu'en 1998 ;
  - 0605 n'a pas de nom de 1941 à 1999 dans `unit_version`, puis « Saint-Laurent-du-Var-Cagnes-
    sur-Mer-Est ». Il faudrait « Cagnes-Est » (1982-1985) puis ce nom (dixième cas de la
    règle du point 12). 0648 Centre n'a pas de nom avant 1999.
- **À inscrire** :
  - les cinq communes dans 0605 de 1973 à 1982 ;
  - les fractions de Cagnes : Est et Ouest de 1982 à 1985, puis Centre, Ouest et Est de 1985
    à 1998 ;
  - Saint-Laurent-du-Var dans 0605 de 1982 à 1998.
- **Déjà prêt** :
  - `06027-1` et `-2` (1985-03-10 → 2013), ancrées. Elles couvrent déjà 1985-1998.
  - `06027-3` (1982-03-14 → 1985-03-10), rangée sans ancre. Ancres à poser : Est
    `POINT(1035544 6295424)`, Ouest `POINT(1034032 6293813)`.

---

## Cannes (06029)

### 22. Cannes, Mandelieu et Théoule de 1973 à 1998 : vingt-cinq ans sans canton

- **Inscrit par `sql/115_villes_nomenclature.sql` (13 octobre 2026)** : Ouest sous 0649 (Cannes-Centre), Est et Lérins sous 0606 de 1973 à 1985, les trois fractions de 1985 à 1998 ; Mandelieu et Théoule dans 0649 puis 0636 ; ancres datées. Reste : rien.
  Règle de nomenclature du 13 octobre 2026 (Adrien) : pas d'unité nouvelle, le canton disparu est porté par l'unité du régime suivant qui hérite de la plus grande part de son territoire dans la ville.

- **Sources** :
  - décret n° 73-811 du 16 août 1973 (JO du 17 août 1973), art. 3 : Cannes-Ouest
    (Mandelieu-la-Napoule, Théoule et l'ouest de la ville) et Cannes-Est (le reste de la ville,
    îles de Lérins comprises) ;
  - décret n° 85-143 du 31 janvier 1985 (JO du 1er février 1985), art. 5 : Cannes-Centre
    (avec les îles de Lérins), Cannes-Est et Mandelieu-Cannes-Ouest. La chronologie cantonale
    n'a pas d'entrée pour 1985.
- **Base** :
  - l'atome 6806 est dans 0606 jusqu'au 1973-09-23. Les trois fractions ne commencent qu'au
    **1998-03-15** : de 1973 à 1998, **la ville n'a aucun canton** ;
  - **Mandelieu-la-Napoule et Théoule-sur-Mer n'ont aucun canton de 1973-09-23 à 1998-03-15** ;
  - aucune unité Cannes-Ouest (1973-1985). 0606 s'appelle « Cannes » jusqu'en 1999 : onzième cas
    de la règle du point 12. 0636 et 0649 n'ont pas de nom avant 1999.
- **À inscrire** :
  - l'unité Cannes-Ouest (1973-1985) ;
  - les fractions de Cannes de 1973 à 1998 ;
  - Mandelieu et Théoule dans Cannes-Ouest (1973-1985), puis dans 0636 (1985-1998).
- **Déjà prêt** :
  - `06029-1` et `-2` (1985-03-10 → 2013), ancrées. Les îles de Lérins ont leurs propres
    ancres de Cannes-Centre.
  - `06029-3` (1973-09-23 → 1985-03-10), rangée sans ancre. Ancres à poser : Ouest
    `POINT(1021400 6281188)` ; Est `POINT(1025837 6281146)`, plus `POINT(1027416 6277313)` et
    `POINT(1027148 6275956)` pour Lérins.

---

## Lille (59350)

### 23. Lille de 1858 à 1941 : ce que la base a, ce qui reste à tracer

- **Sources** : Gaudillère, extraits donnés par Adrien le 27 septembre 2026. Ils couvrent
  1801-1858 (A-B, C-D, E-F), 1858 (annexion de Fives, Moulins-Lille, Esquermes et Wazemmes ;
  limite du Sud-Ouest) et 1889 (Centre renommé Nord ; Sud-Ouest divisé en Centre, Sud-Ouest et
  Sud ; Nord-Est divisé en Nord-Est et Est).
- **Lecture** : le texte de 1889 fixe les secteurs de 1858. Le Centre est le secteur nord de la
  vieille ville. Le Nord-Est est le secteur est, et il s'étend hors les murs jusqu'à Fives.
  **Arbitrage d'Adrien** : hors les murs, la limite Nord-Est / Sud-Est prolonge C-D au plus
  court par les rues.
  **Correction d'Adrien (27 septembre 2026)** : le morceau sud du Sud-Est hors les murs (67,7 ha)
  va au Nord-Est de 1858 à 1889, puis à l'Est. Le Sud-Est se réduit à son morceau intra-muros
  (47,6 ha). Le prolongement de C-D ne le borne plus que sur 346 m.
- **Tracé** :
  - 1858-1889 : `59350-1` à `-4`, `-6`, `-9` ; ancres datées.
  - 1889-1941 : `59350-11` à `-19`, avec les trois nouvelles lignes de 1889 ; ancres datées.
  - Les deux régimes sont conformes.
- **Base** : cinq fractions de 1870 à 1889, puis huit de 1889 à 1941, avec les bons numéros. Rien
  à inscrire pour ces périodes.
- **À vérifier** : la date de fin du découpage de 1889. La base s'arrête en 1941 (trou général),
  reprend en 1968-1982 avec deux fractions (5940, 5946), puis en 1994-2013 avec les huit numéros
  de 1889. Le découpage de 1889 a-t-il duré jusqu'en 1973 ? Et celui de 1994 est-il le même
  (il faudrait alors prolonger les lignes) ou un autre ?
- **Géométrie** : avant le 27 septembre 2026, la cible de Lille en 1880 comprenait Lomme et
  Hellemmes (3 633 ha au lieu de 2 184). Voir le point 6 : réglé dans `98`.

---

## Roubaix (59512)

### 24. Roubaix-Ouest manque dans Roubaix de 1968 à 1982

- **Inscrit par `sql/114_villes_lot_2.sql` (13 octobre 2026)** : `29736#5954` dans 5954 de 1968 au 1982-03-14. Reste : rien.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Source** : Gaudillère, extrait donné par Adrien le 27 septembre 2026 : une seule limite
  pour 1892-1982, en deux lignes (A-B : rues Langevin, de Lille, Foch, Grand-Place, Grande-Rue ;
  C-D : boulevard de la République, rue d'Alsace, chemin de fer, place de la Gare, avenue
  J.-B.-Lebas). Trois cantons : Est, Nord, Ouest.
- **Base** :
  - 1892-1941 : trois fractions (`29736#5952` Est, `#5953` Nord, `#5954` Ouest) ;
  - 1968-1982 : seulement Est et Nord. Le canton Roubaix-Ouest existe bien à ces dates (avec
    Croix et Wasquehal), mais sans sa fraction de Roubaix.
- **Conséquence** : entre 1968 et 1982, le morceau ouest (174,6 ha, entre la limite de Croix et
  de Tourcoing, le boulevard de la République, la voie ferrée et la rue de Lille) n'est pas tiré.
- **À inscrire** : l'appartenance de `29736#5954` à Roubaix-Ouest (5954) du 1er janvier 1968 au
  14 mars 1982. L'ancre est déjà posée (POINT(711467 7066075), datée 1892-01-01 → 1982-03-14).
- **Tracé** : `59512-1` (A-B) et `59512-2` (C-D), du 1er janvier 1892 au 14 mars 1982.
  Conforme en 1892 et en 1900, et en 1950 grâce à la règle des ancres qui chevauchent (la base
  n'a aucun canton de 1941 à 1968).

---

## Tourcoing (59599)

### 25. Tourcoing-Nord-Est manque dans Tourcoing de 1968 à 1982

- **Inscrit par `sql/114_villes_lot_2.sql` (13 octobre 2026)** : `38378#5962` dans 5962 de 1968 au 1982-03-14. Reste : 1941-1968 et 1982-1994.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Source** : Gaudillère, extrait donné par Adrien le 27 septembre 2026 : limites de 1895, en
  deux lignes (A-B : rues de Paris … Racine ; B-C : rues de Dunkerque … de Mouscron). Trois
  cantons : Nord, Nord-Est, Sud. La chronologie ne donne aucun redécoupage de la ville après 1895.
- **Base** :
  - 1895-1941 et 1994-2013 : trois fractions (`38378#5961` Nord, `#5962` Nord-Est, `#5963` Sud) ;
  - 1968-1982 : seulement le Nord et le Sud ;
  - 1941-1968 et 1982-1994 : aucun canton.
- **Conséquence** : entre 1968 et 1982, le morceau nord (612,2 ha, entre A-B, B-C, la limite de
  Neuville-en-Ferrain et la frontière belge) n'est pas tiré.
- **À inscrire** : l'appartenance de `38378#5962` à Tourcoing-Nord-Est (5962) de 1968 à 1982. Et
  peut-être aussi de 1982 à 1994 pour les trois fractions, si la base doit couvrir ces années.
  L'ancre est déjà posée (POINT(711626 7070814), datée 1895-01-01 → 2013-01-01).
- **Tracé** : `59599-1` (A-B) et `59599-2` (B-C), du 1er janvier 1895 au 1er janvier 2013.
  Conforme en 1900, 1950, 1990 et 2005.

---

## Chalon-sur-Saône (71076)

### 26. Chalon-Ville et Chalon-Périphérie (1973-1985) n'existent pas

- **Sources** :
  - Gaudillère, extrait donné par Adrien le 27 septembre 2026 : « 1876-1986 : la Saône » ;
  - décret n° 73-769 du 2 août 1973 (JO du 4 août 1973), `cantons/communes_coupees_1973_1984.csv` :
    Chalon-sur-Saône-Nord est divisé en Chalon-sur-Saône-Ville et Chalon-sur-Saône-Périphérie.
    La portion de ville de Périphérie est décrite par des limites et des voies ; Ville a le reste
    de la rive droite ;
  - décret n° 84-1237 du 24 décembre 1984 : Centre, Nord, Ouest, Sud (en base à partir de 1985).
- **Base** :
  - 1870-1941 : `7729#7106` Nord, `7729#7107` Sud ;
  - 1941-1985 : aucun canton ;
  - à partir du 10 mars 1985 : quatre fractions.
- **À inscrire** :
  - Nord et Sud jusqu'en 1973 ;
  - puis Ville, Périphérie et Sud de 1973 à 1985. Ville et Périphérie sont deux unités à créer,
    chacune avec sa fraction de Chalon.
- **Tracé** : `71076-1` (la Saône), du 1er janvier 1876 au 10 mars 1985, avec des ancres datées.
  La limite entre Ville et Périphérie, sur la rive droite, est à tracer sur le texte de 73-769
  quand les unités existeront.
- **À vérifier** : le texte donne 1876 pour début, la base 1870. Quelle limite valait de 1870 à
  1876 ?

---

## Valenciennes (59606)

### 27. Valenciennes-Est manque dans Valenciennes de 1968 à 1982

- **Inscrit par `sql/114_villes_lot_2.sql` (13 octobre 2026)** : `38657#5965` dans 5965 de 1968 au 1982-03-14 ; la fraction existait, rangée sous Hautmont (`38657#5969`, retirée). Reste : 1941-1968 et 1982-1994.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Source** : Gaudillère, extrait donné par Adrien le 27 septembre 2026 : découpage de 1801,
  « n'a subi que d'imperceptibles modifications à la fin du XIXe siècle », sans texte de loi.
  Deux lignes : A-B (avenue Dampierre … rue de Paris) et C-D (avenue de Reims … le
  Vieil-Escaut). La création d'Anzin en 1982 prend sur les communes rurales de Valenciennes-Nord
  et ne recoupe pas la ville.
- **Base** :
  - 1870-1941 et 1994-2013 : `38657#5965` Est, `#5966` Nord, `#5967` Sud ;
  - 1968-1982 : seulement le Nord et le Sud ;
  - 1941-1968 et 1982-1994 : aucun canton.
- **Conséquence** : entre 1968 et 1982, le morceau est (247,5 ha, entre C-D, la limite de Marly
  et celle de Saint-Saulve) n'est pas tiré.
- **À inscrire** : l'appartenance de `38657#5965` à Valenciennes-Est (5965) de 1968 à 1982.
  L'ancre est déjà posée (POINT(737930 7028863), datée 1801-01-01 → 2013-01-01).
- **Tracé** : `59606-1` (A-B) et `59606-2` (C-D), de 1801 à 2013.

---

## Wattrelos (59650)

### 28. Une fraction de Roubaix-Ouest à Wattrelos après 1892, que le texte ne connaît pas

- **Inscrit par `sql/114_villes_lot_2.sql` (13 octobre 2026)** : l'appartenance de `41221#5954` à Roubaix-Ouest close au 1892-01-01 ; `98` rend la ville conforme. Reste : 1968-1982 et les deux points à vérifier.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Source** : Gaudillère, extrait donné par Adrien le 27 septembre 2026 : limite de 1892, une
  seule ligne (rues Carnot, Jean-Jaurès, Lebas, cours Saint-Liévin, rue Jules-Guesde) entre
  Roubaix-Nord et Roubaix-Est. Elle prolonge la ligne A-B de Roubaix.
- **Base** :
  - 1870-1892 : `41221#5952` Est et `41221#5954` Ouest ;
  - 1892-1941 : Est, Nord (`#5953`) **et Ouest** ;
  - 1994-2013 : Est et Nord.
- **Lecture** : Roubaix-Nord est créé en 1892 par division de l'Est et de l'Ouest. La part de
  Wattrelos qui était à l'Ouest est passée au Nord ; il n'y a plus d'Ouest à Wattrelos.
- **À inscrire** : clore l'appartenance de `41221#5954` à Roubaix-Ouest au 1er janvier 1892.
  Et, si la base doit couvrir 1968-1982, Est et Nord à Wattrelos (la base n'y a aucun canton).
- **Recette** : en attendant, `98` classe la ville « FRACTION SANS ANCRE (base) » en 1892. La
  ligne ferme et la ville est couverte.
- **Tracé** : `59650-1`, du 1er janvier 1892 au 1er janvier 2013, avec des ancres datées.
- **À vérifier** :
  - avant 1892 (Est / Ouest), la limite était-elle la même ligne ?
  - la limite de 1892 vaut-elle jusqu'en 2013 ?

---

## Beauvais (60057)

### 29. Beauvais n'a aucune fraction de 1941 à 1998

- **Inscrit par `sql/114_villes_lot_2.sql` (13 octobre 2026)** : Nord-Est et Sud-Ouest de 1941 au 1982-03-14 (l'atome entier retiré du Sud-Ouest), les trois fractions de 1982 à 1998. Reste : les quatre communes rurales de 1973 à 1982.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Sources** :
  - Gaudillère, extrait donné par Adrien le 27 septembre 2026 : limite Nord-Est / Sud-Ouest
    1958-1986 (rue de Saint-Just-des-Marais … rue Louis-Coatalen, chemin de fer) ;
  - décret n° 82-63 du 20 janvier 1982 (JO du 22 janvier 1982,
    `jorf_txt/JORF_19820122_18_col.txt`) : le Nord-Est est divisé en Nord-Est et Nord-Ouest.
    La limite sud du Nord-Est y est la même que chez Gaudillère.
- **Base** :
  - 1870-1941 : `3332#6003` Nord-Est, `3332#6004` Sud-Ouest. La cible de 1870-1943 est celle
    d'avant l'annexion de Marissel, Notre-Dame-du-Thil, Saint-Just-des-Marais et Voisinlieu
    (19 février 1943) ;
  - 1968-1973 : l'atome entier `3332` dans le Sud-Ouest. **Faux** : la ville était partagée ;
  - 1973-1998 : rien ;
  - à partir du 15 mars 1998 : Nord-Est, Sud-Ouest et Nord-Ouest (`3332#6040`).
- **À inscrire** :
  - `3332#6003` (Nord-Est) et `3332#6004` (Sud-Ouest) de 1958 à 1982, à la place de l'atome
    entier dans le Sud-Ouest ;
  - puis Nord-Est, Nord-Ouest et Sud-Ouest à partir du 22 janvier 1982 (JO).
- **Tracé** (tout est dessiné dès maintenant, par la règle du chevauchement) :
  - `60057-1` : limite du Sud-Ouest, partie commune à Gaudillère et au décret, de 1958 à 2013 ;
  - `60057-2` : ouest selon Gaudillère (rue de Saint-Just-des-Marais, puis l'Avelon), de 1958 à
    1982 ;
  - `60057-3` : ouest selon le décret de 1982 (rivières de Saint-Quentin et de Saint-Just, puis
    l'Avelon), de 1982 à 2013 ;
  - `60057-4` : limite Nord-Ouest / Nord-Est (ancienne RN 1, rue de Calais, rue Gambetta), de 1982
    à 2013.

  Les ancres sont datées : Nord-Est et Sud-Ouest pour 1958-1982, les trois cantons pour 1982-2013.
  **Arbitrages d'Adrien (27 septembre 2026)** : 1986 n'est que l'horizon de Gaudillère, qui ne
  connaît pas l'après-1995 ; la limite est prolongée jusqu'en 2013. À l'ouest, après 1982, on suit
  le décret. Environ 50 ha passent du Sud-Ouest au Nord-Ouest en 1982.
---

## Boulogne-sur-Mer (62160)

### 31. Boulogne-Nord de 1968 à 1973 rangé sous « Calais-Nord-Ouest »

- **Inscrit par `sql/114_villes_lot_2.sql` (13 octobre 2026)** : `5200#6213` de 1968 à 1973 à la place de `5200#6215` (Calais-Nord-Ouest, retirée) ; Nord et Sud de 1973 à 1985 ; Nord-Est, Sud, Nord-Ouest de 1985 à 1992 ; le nom Nord-Est dès 1985. `98` rend la ville conforme. Reste : les communes rurales.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Source** : Gaudillère, extrait donné par Adrien le 27 septembre 2026 : limite Nord / Sud
  1958-1986 (rues de Saint-Omer, de Porte-Neuve, boulevard Mariette, Grande-Rue, rue de la
  Lampe, pont de l'Entente-Cordiale, la Liane). Le décret n° 84-1236 du 24 décembre 1984 crée
  ensuite Boulogne-Nord-Ouest et Le Portel, et renomme le Nord en Nord-Est.
- **Base** :
  - 1870-1941 : `5200#6213` Nord, `5200#6214` Sud ;
  - 1968-1973 : `5200#6214` Sud et **`5200#6215` dans l'unité 6215 « Calais-Nord-Ouest »**, sans
    géométrie. C'est très probablement le Nord de Boulogne, pris sous un code de canton réutilisé
    plus tard par Calais-Nord-Ouest ;
  - 1973-1992 : rien ;
  - à partir du 22 mars 1992 : Nord(-Est), Sud, Nord-Ouest et Le Portel (le décret dit 1985).
- **À inscrire** :
  - l'appartenance de 1968-1973 : `5200#6213` (Boulogne-Nord) à la place de `5200#6215` ;
  - Nord et Sud de 1973 à 1985, puis le régime de 1985 à partir du 10 mars 1985.
- **Tracé** :
  - `62160-1` : la limite de 1958 (Saint-Omer, Grande-Rue, Liane), de 1958 à 2013. Les décrets de
    1984 et 1991 la gardent ;
  - `62160-2` : la limite Nord-Ouest / Nord-Est du décret 84-1236, de 1985 à 2013 ;
  - `62160-3` : la limite Le Portel / Sud du décret 91-217, de 1992 à 2013.

  Les ancres sont datées : Nord et Sud pour 1958-1985 ; Nord-Est, Nord-Ouest et Sud pour 1985-2013 ;
  Le Portel pour 1992-2013. Tout est dessiné, sauf le Nord en 1968-1973, et la recette dit
  « FRACTION ABSENTE + FRACTION SANS ANCRE (base) » pour cette seule période.
- **À inscrire aussi** : Nord-Est, Nord-Ouest et Sud du 10 mars 1985 au 22 mars 1992. La base les
  fait commencer en 1992, avec Le Portel, qui ne date bien que de 1992.

---

## Méricourt (62570)

### 32. Avion et Rouvroy à Méricourt de 1985 à 1992 : absents

- **Inscrit par `sql/114_villes_lot_2.sql` (13 octobre 2026)** : les deux fractions du 1985-03-10 au 1992-03-22. Reste : 1973-1985 (Avion, à vérifier).
  Ce qui suit est l'entrée d'avant l'inscription.

- **Source** : décret n° 84-1236 du 24 décembre 1984 (JO du 30 décembre 1984), art. 1er. Il crée
  le canton de Rouvroy (Drocourt, Rouvroy et la partie de Méricourt à l'est d'une ligne : voie
  ferrée Hénin-Beaumont - Lens, rues Pierre-Simon … Raoul-Briquet, déviation du C.D. 40, C.D. 50 E).
  Le reste de Méricourt demeure dans Avion.
- **Base** :
  - jusqu'au 23 septembre 1973 : l'atome entier `22076` dans Vimy (6245) ;
  - de 1973 à 1992 : rien ;
  - à partir du 22 mars 1992 : `22076#6252` Avion et `22076#6267` Rouvroy.
- **À inscrire** :
  - les deux fractions à partir du 10 mars 1985 ;
  - et, de 1973 à 1985, Méricourt entière dans son canton de 1973. Avion, d'après la
    chronologie, qui fait naître Rouvroy « par division d'Avion » ; à vérifier.
- **Tracé** : `62570-1`, du 10 mars 1985 au 1er janvier 2013, avec des ancres datées. Elles jouent
  déjà sur 1985-1992 par la règle des ancres datées.

---

## Meaux (77284)

### 33. Meaux-Nord et Meaux-Sud de 1976 à 1994 : absents

- **Inscrit par `sql/114_villes_lot_2.sql` (13 octobre 2026)** : la ville entière dans 7717 de 1955 au 1976-03-07, les deux fractions jusqu'en 1994, le nom Meaux-Nord dès 1976. Reste : rien.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Source** : décret du 28 octobre 1975 (JO du 9 novembre 1975, p. 11516-11517,
  `jorf_txt/JORF_19751109_261_col.txt`), art. 4. Le canton de Meaux est divisé en Meaux-Nord et
  Meaux-Sud, séparés par l'avenue Galliéni … l'avenue du Président-Roosevelt, le canal de l'Ourcq
  et le déversoir du canal vers la Marne. Le décret n'est pas dans
  `cantons/communes_coupees_1973_1984.csv`.
- **Base** :
  - l'atome entier `21801` dans « Meaux » (7717) jusqu'en 1955 ;
  - puis rien ;
  - à partir du 20 mars 1994 : `21801#7717` (« Meaux » jusqu'en 1999, puis « Meaux-Nord ») et
    `21801#7731` Meaux-Sud.
- **À inscrire** :
  - les deux fractions à partir du 7 mars 1976 (cantonales), avec les communes rurales du décret ;
  - le nom Meaux-Nord dès 1976 ;
  - la ville entière dans Meaux de 1955 à 1976.
- **Tracé** : `77284-1`, du 7 mars 1976 au 1er janvier 2013, avec des ancres datées. Elles jouent
  déjà sur 1976-1994.

---

## Melun (77288)

### 34. Melun-Nord et Melun-Sud de 1941 à 1994 : absents de la ville

- **Inscrit par `sql/114_villes_lot_2.sql` (13 octobre 2026)** : les deux fractions du 1976-03-07 à 1994. Reste : 1941-1976, dont la limite n'a pas de texte.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Source** : décret du 28 octobre 1975 (JO du 9 novembre 1975), art. 1er. Il recrée Melun-Nord
  et Melun-Sud avec une nouvelle limite dans la ville (rue de la Chasse … rue de Vaux), et crée
  Perthes et Savigny-le-Temple sur leurs communes rurales.
- **Base** : `21914#7718` Nord et `21914#7719` Sud de 1870 à 1941, puis de 1994 à 2013 seulement.
- **À inscrire** : les deux fractions de 1976 (7 mars) à 1994 ; celles de 1941-1976 si la base doit
  couvrir ces années.
- **Tracé** : `77288-1`, du 7 mars 1976 au 1er janvier 2013, avec des ancres datées. La limite
  d'avant 1976 n'est pas tracée : il faut son texte.

---

## Niort (79191)

### 35. Niort de 1941 à 1973 : l'atome entier dans Niort-1

- **Inscrit par `sql/114_villes_lot_2.sql` (13 octobre 2026)** : Niort-1 et Niort-2 en fractions de 1941 à 1973 (l'atome entier retiré), les noms Niort-Nord et Niort-Ouest dès 1973. Reste : la limite de 1964-1973.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Sources** :
  - Gaudillère, extrait donné par Adrien le 27 septembre 2026, sans date : la limite Niort-1 /
    Niort-2 dans la commune d'avant 1964 (avenue du Maréchal-de-Lattre … avenue de Paris) ;
  - décret n° 73-673 du 13 juillet 1973 (JO du 17 juillet 1973,
    `cantons/communes_coupees_1973_1984.csv`) : Niort-Nord, Niort-Ouest et Niort-Est remplacent
    Niort-1 et Niort-2, avec des limites dans la ville décrites voie par voie.
- **Base** :
  - 1870-1941 : `25044#7920` Niort-1, `25044#7921` Niort-2 ;
  - 1968-1973 : **l'atome entier `25044` dans Niort-1**, alors que la ville était partagée ;
  - à partir du 23 septembre 1973 : `#7920` (Niort-1, puis Niort-Nord en 1999), `#7921` (Niort-2,
    puis Niort-Ouest), `#7933` Niort-Est. Les noms Nord et Ouest datent de 1973 dans le décret.
- **À inscrire** :
  - Niort-1 / Niort-2 en fractions de 1941 à 1973, à la place de l'atome entier ;
  - les noms Niort-Nord et Niort-Ouest dès 1973.
- **Tracé** :
  - `79191-1` : la limite Niort-1 / Niort-2 (Gaudillère), du 1er janvier 1870 au 21 juin 1964, dans
    la commune d'avant les annexions ;
  - `79191-2` : la limite du Nord (décret 73-673), du 23 septembre 1973 au 1er janvier 2013 ;
  - `79191-3` : la limite Est / Ouest (décret 73-673), aux mêmes dates.

  Les ancres sont datées (1870-1964 et 1973-2013). Rien n'est tracé de 1964 à 1973 : la limite
  dans la commune agrandie n'a pas de texte.

---

## Tulle (19272)

### 37. Tulle de 1941 à 1985 : l'atome entier dans Tulle-Sud, puis les cantons urbains en retard

- **Inscrit par `sql/114_villes_lot_2.sql` (13 octobre 2026)** : les deux fractions de 1941 à 1982 (l'atome entier retiré), puis les cantons urbains de 1982 à 1985 sous leurs noms. Reste : la fraction `15794#1925` et `15506#1926` de 1968-1982, accrochées à d'autres atomes (Gimel ?), à examiner.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Sources** :
  - Gaudillère, extrait donné par Adrien le 27 septembre 2026 : « la Corrèze » sépare Tulle-Nord
    et Tulle-Sud ;
  - décret n° 82-120 du 2 février 1982 (JO du 4 février 1982, p. 456-457,
    `jorf_txt/JORF_19820204_29_col.txt`), art. 2 : Tulle-Urbain-Nord, Tulle-Urbain-Sud,
    Tulle-Campagne-Nord (Naves) et Tulle-Campagne-Sud (Laguenne) remplacent Tulle-Nord et
    Tulle-Sud. La limite dans la ville change : chemin rural près de Feix, rues Léger-Rabes,
    René-et-Émile-Fage, Félix-Vidalin, la Corrèze entre le pont de l'Escurol et la passerelle
    Mermoz, avenue Malaquin, rues de l'Estabournie et Pauphile, chemin du Monteil.
- **Base** :
  - 1870-1941 : `38367#1925` Tulle-Nord, `38367#1926` Tulle-Sud ;
  - 1968-1982 : **l'atome entier dans Tulle-Sud** ;
  - à partir du 10 mars 1985 : `#1925` et `#1926`, nommés Tulle-Nord et Tulle-Sud jusqu'en 1999,
    puis Tulle-Urbain-Nord et Tulle-Urbain-Sud.
- **À inscrire** :
  - les deux fractions de 1941 à 1982, à la place de l'atome entier ;
  - les cantons urbains dès le 14 mars 1982 (et non 1985), sous leurs noms du décret.
- **Tracé** :
  - `19272-1` : la Corrèze, du 1er janvier 1808 au 14 mars 1982 ;
  - `19272-2` : la limite des cantons urbains (décret 82-120), du 14 mars 1982 au 1er janvier 2013.

  Les ancres sont datées pour les deux périodes.

---

## Tarbes (65440)

### 38. Tarbes avant 1870, et le régime de 1973-1982

- **Sources** :
  - Gaudillère, extrait donné par Adrien le 28 septembre 2026 : limite Tarbes-Nord /
    Tarbes-Sud de 1801 à 1853 ;
  - chronologie : limites refixées le 7 juin 1853 ; Tarbes-1 à 5, Aureilhan et Séméac le
    23 juillet 1973.
- **Base** :
  - `37084#6521` Nord et `#6522` Sud de 1870 à 1941 et de 1968 à 1973 ;
  - rien de 1973 à 1982 ;
  - cinq fractions (1er à 5e canton) à partir du 14 mars 1982, alors que la chronologie donne 1973.
- **À inscrire** :
  - les appartenances d'avant 1870 si la base doit remonter à 1801 ;
  - les cinq cantons de 1973 à 1982.
- **Tracé** :
  - `65440-1` : la limite de 1801-1853 ;
  - `65440-2` : la limite de 1853, du 7 juin 1853 au 1er janvier 2013 : le décret 73-729 la garde
    comme axe de ses cinq cantons ;
  - `65440-3` (I / II), `-4` (III / IV-V, voie ferrée de Bayonne et gare) et `-5` (IV / V) : le
    décret 73-729, du 23 septembre 1973 au 1er janvier 2013.

  Nord à l'ouest, Sud à l'est (arbitrage d'Adrien). Les ancres sont datées pour les trois
  régimes. On suppose que les numéros 1er à 5e de la base correspondent à Tarbes-I à V du décret.

---

## Perpignan (66136)

### 39. Perpignan de 1973 à 1998 : sept puis neuf cantons absents

- **Sources** :
  - Gaudillère, extrait donné par Adrien le 28 septembre 2026 : la partie urbaine de
    Perpignan-Ouest est une enclave de 83 ha dans le canton Est, bordée par l'avenue
    Maréchal-Leclerc … la place de la Résistance ;
  - décret n° 73-819 du 16 août 1973 : Perpignan-I à VII (VI a exactement les limites de
    l'ancienne enclave de l'Ouest) ;
  - décret n° 82-84 du 25 janvier 1982 : Perpignan-VIII et IX, avec des limites redécrites pour
    I, III, IV et V (`cantons/communes_coupees_1973_1984.csv`).
- **Base** :
  - `26522#6608` Est et `#6609` Ouest en 1870-1941 et 1968-1973 ;
  - rien de 1973 à 1998 ;
  - à partir du 15 mars 1998 : 6608 et 6609, nommés Est et Ouest jusqu'en 1999 (puis « 1er » et
    « 2e canton »), et `#6620` à `#6626` (3e à 9e canton).
- **À inscrire** : les sept cantons de 1973 à 1982, puis les neuf de 1982 à 1998. Il faut aussi
  vérifier la correspondance entre les numéros 1er à 9e de la base et les cantons I à IX des
  décrets.
- **Tracé** :
  - `66136-1` : l'anneau de l'enclave (Ouest de 1870 à 1973, puis VI de 1973 à 1982) ;
  - `66136-2` et `-3` : la Têt, en deux traversées (I / rive droite) ;
  - `66136-4` : II / III (D617A, avenue Rosette-Blanc … rue Saint-Exupéry) ;
  - `66136-5` : III et II / IV (D914, route d'Elne, avenue d'Argelès, avenue Guynemer, rue
    Waldeck-Rousseau) ;
  - `66136-6` : IV / V (D900, avenue d'Espagne, avenue du Général-Guillaut) ;
  - `66136-7` : II / V (avenue de Grande-Bretagne, puis la Têt ; la rue de la Rivière est
    introuvable).

  Tout vaut du 23 septembre 1973 au 14 mars 1982, avec des ancres datées ; on suppose que les numéros
  1er à 6e de la base correspondent aux cantons I à VI. Le régime de 1982 (décret 82-84, neuf
  cantons) reste à tracer.

---

## Chambéry (73065)

### 40. Chambéry de 1941 à 1985, et les terres annexées en 1961

- **Inscrit par `sql/115_villes_nomenclature.sql` (13 octobre 2026)** : Nord et Sud de 1941 au 1973-09-23 ; les terres annexées en 1961 ancrées à Chambéry-Nord (arbitrage d'Adrien), plus de morceau vide. Reste : le régime de 1973-1985.
  Règle de nomenclature du 13 octobre 2026 (Adrien) : pas d'unité nouvelle, le canton disparu est porté par l'unité du régime suivant qui hérite de la plus grande part de son territoire dans la ville.

- **Sources** :
  - Gaudillère, extrait donné par Adrien le 28 septembre 2026 : limite Nord / Sud de 1860 à
    1973, décrite dans la commune d'avant l'annexion de Bissy et de Chambéry-le-Vieux (6 mai
    1961) ;
  - chronologie : Chambéry-Sud-Ouest, La Ravoire et Saint-Alban-Leysse le 2 août 1973 ;
    Chambéry-Est le 23 janvier 1985.
- **Base** :
  - `7760#7309` Nord et `#7310` Sud de 1870 à 1941 ;
  - rien de 1941 à 1985 ;
  - quatre fractions à partir du 10 mars 1985, alors que le Sud-Ouest date de 1973.
  - Bissy (`4350`) et Chambéry-le-Vieux (`7761`) sont dans La Motte-Servolex jusqu'en 1955, puis
    sans canton.
- **À inscrire** :
  - Nord et Sud de 1941 à 1973 ;
  - **une fraction de Chambéry dans La Motte-Servolex (7319) de 1961 à 1973**, pour les terres
    annexées (1 076,7 ha à l'ouest de l'ancienne limite ; ancre possible POINT(925840 6503285)) ;
  - le régime de 1973 (Nord, Sud, Sud-Ouest, et les parts de La Ravoire et de Saint-Alban-Leysse
    s'il y en a).
- **Tracé** :
  - `73065-1` : la limite du texte, du 24 novembre 1860 au 23 septembre 1973 ;
  - `73065-2` : l'ancienne limite de Chambéry, de 1961 à 1973.

  En 1961-1973, le morceau des terres annexées n'a pas d'ancre et n'est pas dessiné
  (`pose_coupe.py --vides-admis`).

---

## Saumur (49328)

### 41. Saumur de 1941 à 1985, et la limite Nord-Est / Nord-Ouest d'avant 1963

- **Inscrit par `sql/114_villes_lot_2.sql` (13 octobre 2026)** : Nord-Ouest et Sud de 1941 à 1985, Nord-Est de 1941 au 1963-05-30 (l'atome entier retiré). Reste : la limite Nord-Est / Nord-Ouest d'avant 1963.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Sources** :
  - Gaudillère, extrait donné par Adrien le 29 septembre 2026 : « la Loire (les îles appartenant
    au canton Nord) » ;
  - chronologie : transfert du chef-lieu de Saumur-Nord-Est à Allonnes le 30 mai 1963, avec
    fixation des limites.
- **Base** :
  - 1870-1941 : trois fractions (`35529#4927` Nord-Est, `#4928` Nord-Ouest, `#4929` Sud) ;
  - 1968-1973 : **l'atome entier dans le Sud** ;
  - rien de 1973 à 1985 ;
  - à partir du 10 mars 1985 : `#4928` (Nord-Ouest, puis Nord en 1999) et `#4929` Sud.
- **À inscrire** : Nord-Ouest et Sud de 1963 à 1985 (et Nord-Est de 1941 à 1963), à la place de
  l'atome entier dans le Sud en 1968-1973.
- **Tracé** :
  - `49328-1` (1963-1973, commune d'avant la fusion) ;
  - `49328-2` et `-3` (1973-2013, commune agrandie) : rive sud de l'ensemble des bras de la Loire,
    les îles allant au Nord, sauf l'île de l'est (16 ha), au Sud (correction d'Adrien, 1er octobre
    2026).
- **Non tracé** : avant 1963, la limite Nord-Est / Nord-Ouest au nord de la Loire. Le texte ne la
  donne pas.
---

## Le Mans (72181)

### 42. Le Mans : les trois cantons avant 1870 et de 1941 à 1967

- **Sources** :
  - Gaudillère, extraits donnés par Adrien le 1er octobre 2026 : 1801-1892 (la Sarthe et la
    Cité) et 1892-1967 (A-B : détour de la Cité par la rue Barbier et le pont du Greffier ; C-D :
    voie ferrée) ;
  - chronologie cantonale p. 815 : fixation des limites entre les 3 cantons le 13 juillet 1892 ;
    création des six cantons Le Mans-Centre, -Est, -Nord, -Nord-Ouest, -Sud et -Sud-Ouest le
    8 août 1967.
- **Base** : `20932#7219` Le Mans-1, `#7220` Le Mans-2, `#7221` Le Mans-3 de 1870 à 1941 ; rien
  de 1941 à 1982 (ni les trois cantons jusqu'en 1967, ni les six de 1967-1982).
- **À inscrire** : les trois fractions de 1801 à 1870 et de 1941 au 8 août 1967 ; les six cantons
  de 1967 à 1982.
- **Tracé** :
  - `72181-1` à `-23` (1801 → 13 juillet 1892, fin calée ce jour sur la chronologie au lieu du
    1er janvier 1892) ;
  - `72181-31` à `-33` (13 juillet 1892 → 8 août 1967), ancres datées : Le Mans-1 POINT(492000
    6772500), Le Mans-2 POINT(489000 6771500) et POINT(490892 6771343), Le Mans-3 POINT(491500
    6767000). Elles joueront de 1941 à 1967 dès que les appartenances seront inscrites.
---

## Le Havre (76351)

### 43. Le Havre : les six cantons de 1888, leurs noms, et 1941-1964

- **Sources** :
  - Gaudillère, page « Le Havre (1888-1964) » photographiée par Adrien le 2 octobre 2026 :
    plan annexé à la loi du 7 juillet 1888, limites A-B, C-D, E-F, et « la commune de
    Graville-Sainte-Honorine fut annexée au Havre (4ème canton) par la loi du 18/10/1919 » ;
  - chronologie cantonale p. 817 : Le Havre-1 à 6 le 7 juillet 1888 ; Le Havre-7 le 28 janvier
    1964.
- **Base** :
  - 1888-1941 : `16833#7627` à `#7632`, nommées Le Havre-Nord, -Sud, -Est, -4, -5, -6. Les trois
    premières gardent les noms des cantons d'avant 1888, que la loi de 1888 a supprimés ;
  - Graville (atome 16104) : Le Havre-Est 1870-1888, Le Havre-6 1888-1919, puis plus rien ;
  - rien de 1941 à 1992.
- **À inscrire** :
  - renommer 7627, 7628, 7629 en Le Havre-1, -2, -3 pour 1888-1964. La découpe les a prises dans
    cet ordre ; à confirmer ;
  - les six fractions de 1941 au 28 janvier 1964 ;
  - Graville au 4e canton de 1919 à 1964 : elle est dans l'ANR du Havre et ancrée au 4e.
- **Tracé** : `76351-1` à `-7` (1888-1964 : A-B, C-D en deux parties, E-F en deux parties,
  ancienne limite de Graville en deux tronçons) ; `76351-8` (limite de Bléville, 1953-1964) et
  `-9` (limite de Sanvic, 1955-1964). Bléville et Sanvic vont au 6e, dont elles étaient
  communes.
- **Corrigé dans `98`** (pas en base) : `cible_ville` écarte un atome absorbé dont toutes les ANR
  sont closes. Graville après 1919 reprenait jusque-là le contour moderne du Havre, et Gap
  l'atome 8884 après 1895. Il écarte aussi une commune encore à part qui a son propre canton
  (Graville avant 1919).
---

## Rouen (76540)

### 44. Rouen : les six cantons avant 1870 et de 1941 à 1982

- **Sources** :
  - Gaudillère, page « Découpage cantonal (1801-1982) » photographiée par Adrien le 2 octobre
    2026 : plan annexé à la loi du 27 novembre 1887, limites de 1801 à 1982 ;
  - chronologie cantonale p. 817 : limites de Rouen-3 et Rouen-4 fixées le 27 novembre 1887 ;
    Rouen-7 créé le 27 janvier 1982.
- **Base** : `29752#7642` à `#7647` (Rouen-1 à 6) de 1870 à 1941 seulement.
- **À inscrire** : les six fractions de 1801 à 1870 et de 1941 au 27 janvier 1982.
- **Tracé** : `76540-1` à `-6`, de 1801 à 1982, sauf `-2` (F-H, 1887-1982) et `-7` (F-H,
  1801-1887, reprise approchée du tracé de 1887). Les ancres sont datées de 1801 à 1982.
---

## Versailles (78646)

### 45. Versailles : Nord, Ouest, Sud avant 1870 et de 1941 à 1964

- **Sources** : Gaudillère, extrait donné par Adrien le 2 octobre 2026, 1801-1964 ; chronologie
  p. 818 : Versailles-Nord-Ouest créé le 28 janvier 1964.
- **Base** : `39569#7838` Nord, `#7839` Ouest, `#7840` Sud, de 1870 à 1941 seulement ; ensuite
  rien jusqu'en 1994. De 1994 à 1999, les fractions `#7826`, `#7827`, `#7829` portent les noms
  de Meulan, Milly, Montmorency, puis Versailles-Nord, -Nord-Ouest, -Sud. Les unités semblent
  réemployées : à vérifier.
- **À inscrire** : les trois fractions de 1801 à 1870 et de 1941 au 28 janvier 1964.
- **Tracé** : `78646-1` (A-D) et `-2` (B-C), de 1801 à 1964, ancres datées.
---

## Toulon (83137)

### 46. Toulon : les quatre cantons de 1901, leurs noms, et 1941-1964

- **Sources** :
  - Gaudillère p. 647, photographiée par Adrien le 2 octobre 2026 : plan annexé à la loi du
    8 juillet 1901, limites A-B, C-D, E-F ;
  - chronologie p. 820 : Toulon-3 et Toulon-4 le 8 juillet 1901 ; Toulon-5 le 28 janvier 1964.
- **Base** :
  - `37812#8327` « Toulon-Est », `#8328` « Toulon-Ouest », `#8329` Toulon-3, `#8330` Toulon-4,
    de 1901 à 1941. Les deux premières gardent les noms d'avant 1901 ;
  - de 1968 à 1973, seulement `#8329`, `#8330`, `#8331`.
- **À inscrire** :
  - renommer 8327 et 8328 en Toulon-1 et Toulon-2 pour 1901-1964. La découpe les a prises dans
    cet ordre : le 1er canton est à l'ouest, le 2e au centre-ouest. À confirmer ;
  - les quatre fractions de 1941 au 28 janvier 1964.
- **Contrôle** : en 1930, la base met Le Revest (83103) au canton Toulon-4. Or, selon le plan, le
  bord nord de la ville face au Revest est au 1er et au 3e canton (2,8 km de contact avec le
  1er). Le 4e canton ne touche que La Valette et La Garde. À vérifier.
- **Tracé** : `83137-1` (A-B), `-2` (C-D), `-3` (E-F), de 1901 à 1964, ancres datées.
---

## Alès (30007)

### 70. Alès : 1941-1968, et Nord-Est / Sud-Est dès 1973

- **Sources** : Gaudillère, Alès 1958-1986 (extrait donné par Adrien le 4 octobre 2026) ;
  chronologie : Alès dédoublé en Est et Ouest le 18 mai 1858, l'Est en Nord-Est et Sud-Est le
  23 juillet 1973 ; décret 73-721 (`jorf_txt/JORF_19730725_171_col.txt`, lignes 1703-1731, et
  `cantons/communes_coupees_1973_1984.csv`).
- **Base** : `347#3003` (Ouest) et `#3002` (Est) de 1870 à 1941 et de 1968 au 23 septembre 1973 ;
  rien de 1941 à 1968 ni de 1973 à 1992 ; `#3002` s'appelle encore « Alès-Est » de 1992 à 1999 ;
  `#3041` (Sud-Est) ne commence qu'en 1992.
- **À inscrire** : les deux fractions de 1941 à 1968 ; Nord-Est et Sud-Est dès 1973.
- **Tracé** : `30007-1` (Est / Ouest), 1858-05-18 → 1973-09-23 ; ancres datées Ouest
  POINT(785000 6336500) et Est POINT(787000 6339000). La même ligne vaut après 1973 (le décret
  ne divise que l'Est) : à prolonger jusqu'en 2013 quand la limite Nord-Est / Sud-Est sera
  tracée (décret 73-721 ; ancre prête pour le Sud-Est : POINT(788500 6336000), non éprouvée).
- **Tracé après 1973 (écrit le 21 octobre 2026)** : `30007-2` (Ouest / reste, reprise de `30007-1`
  avec l'axe du Grabieux que nomme le décret 73-721 au lieu du quai du 8-Mai, 0,97 ha) et `30007-3`
  (Nord-Est / Sud-Est, décret 73-721), 1973-09-23 → 2013-01-01, ancres datées Ouest
  POINT(785000 6336500), Nord-Est `347#3002` POINT(787500 6338700), Sud-Est `347#3041`
  POINT(788500 6336000) ; CONFORME au 2000-01-01 et au 1980-01-01 (`--morceaux 3`). Aucun texte ne
  change ces limites avant le décret 2014-226. Reste à inscrire : les trois fractions de
  1973-09-23 à 1992-03-22 (communes rurales du décret : Nord-Est = Rousson,
  Saint-Julien-les-Rosiers, Saint-Martin-de-Valgalgues ; Sud-Est = Les Plans, Méjannes-lès-Alès,
  Mons, Saint-Hilaire-de-Brethmas, Saint-Privat-des-Vieux, Salindres, Servas), et le nom
  « Alès-Nord-Est » de `#3002` dès 1973 (la base dit « Alès-Est » jusqu'en 1999).
---

## Évreux (27229)

### 71. Évreux : décret 82-56, à inscrire dès 1982

- **Inscrit par `sql/114_villes_lot_2.sql` (13 octobre 2026)** : Nord et Sud de 1941 à 1968, les quatre fractions de 1982 à 1992. Reste : rien.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Sources** : Gaudillère, Évreux 1863-1870 ; décret n° 82-56 du 20 janvier 1982 (JO du
  22 janvier ; `jorf_txt/JORF_19820122_18_col.txt`, lignes 599-630), qui divise le canton Sud en
  Est, Sud et Ouest et reprend mot pour mot la limite du Nord.
- **Base** : `13353#2716` (Nord) et `#2717` (Sud) de 1870 à 1941, de 1968 au 14 mars 1982 et de
  1992 à 2013 ; `#2737` (Est) et `#2738` (Ouest) seulement à partir du 22 mars 1992 ; rien de
  1941 à 1968 ni de 1982 à 1992.
- **À inscrire** : Nord et Sud de 1941 à 1968 ; les quatre fractions et leurs communes rurales
  dès le 14 mars 1982.
- **Tracé** : `27229-1` (Nord / reste), 1870 → 2013 ; `-2` (Ouest / Est), `-3` (Sud / Est), `-4`
  (Sud / Ouest), 1982-03-14 → 2013 ; ancres Nord POINT(563431 6883277), Sud
  POINT(565375 6880291), Est POINT(566113 6882399), Ouest POINT(563499 6880383).
---

## Angers (49007)

### 57. Angers : Nord-Est absent de 1968 à 1973, et 1941-1968

- **Sources** : Gaudillère, Angers 1801-1964 (extrait donné par Adrien le 3 octobre 2026).
- **Base** : `804#4901` à `#4903` (Nord-Est, Nord-Ouest, Sud-Est) de 1870 à 1941 ; de 1968 à
  1973, Nord-Ouest et Sud-Est seulement ; rien de 1941 à 1968.
- **À inscrire** : les trois fractions de 1941 à 1964 (mêmes limites selon le texte), et le
  régime de 1964-1973.
- **Tracé** : `49007-1` (la Maine, prolongée par la Mayenne) et `49007-2` (C-D), 1801-1964 ;
  ancres datées sur la même période. Attribution Nord-Est / Sud-Est et île Saint-Aubin à
  confirmer.
---

## Toulouse (31555)

### 67. Toulouse : Centre et Ouest absents de 1968 à 1973, et 1941-1968

- **Inscrit par `sql/114_villes_lot_2.sql` (13 octobre 2026)** : Centre et Ouest de 1968 à 1973. Reste : 1941-1968.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Sources** : Gaudillère, Toulouse 1801-1973 (extrait donné par Adrien le 3 octobre 2026) ;
  chronologie : Toulouse-1 à 15 créés le 16 août 1973.
- **Base** : `37818#3133` Centre, `#3134` Nord, `#3135` Ouest, `#3136` Sud de 1870 à 1941 ; de 1968
  au 23 septembre 1973, Nord et Sud seulement ; rien de 1941 à 1968 ni avant 1870.
- **À inscrire** : les quatre fractions de 1941 à 1968 ; Centre et Ouest de 1968 à 1973.
- **Tracé** : `31555-1` (E-F, la Garonne par le bras ouest, îles au Sud), `-2` (A-B), `-3` (C-D),
  1801 → 1973-09-23 ; ancres datées Ouest POINT(571000 6278000), Nord POINT(572500 6283000),
  Centre POINT(576500 6282000), Sud POINT(575000 6275000). Avant 1806 la cible est autre
  (11 125 ha), non éprouvée.

### 128. Toulouse : quinze cantons de 1973 à 1998, sans fraction en base

- **Inscrit par `sql/124_villes_lot_3.sql` (23 octobre 2026)** : les quinze fractions du 1973-09-23 au 1998-03-15 ; Ramonville (IX), Portet (XI), Cugnaux, Tournefeuille (XII), Saint-Loup (XV) ; Beauzelle, Blagnac, Colomiers, Cornebarrieu, Mondonville passent de 3151 (Blagnac, canton de 1997) à 3148 (Toulouse-XIII) ; Mondonville dans Toulouse-Ouest de 1955 à 1973 ; noms Toulouse-I à XV de 1973 à 1999. Reste : Portet, Cugnaux et Tournefeuille sans canton du 1998-03-15 au 1998-04-01 (leur canton de 1998 commence au COG) ; les onze fractions nées en 1973 n'ont pas de circonscription avant 1986 (le découpage de 1958 suit les quatre cantons de 1958, comme pour Nice).
  Ce qui suit est l'entrée d'avant l'inscription.

- **Sources** : décret n° 73-815 du 16 août 1973, JO du 17 août 1973
  (`jorf_txt/JORF_19730817_190_col.txt`, l. 1620-1800), qui décrit chacun des quinze cantons avec
  tous ses voisins ; décret du 26 février 1997 (`JORF_19970227_49`), communes rurales seules.
- **Base** : aucune fraction de 31555 entre le 23 septembre 1973 et le 15 mars 1998 ; du
  15 mars 1998 au 1er janvier 1999, `#3133` à `#3136` portent encore les noms Centre, Nord, Ouest,
  Sud au lieu de Toulouse-I à IV.
- **À inscrire** : les quinze fractions (`#3133`-`#3136`, `#3140`-`#3150` = Toulouse-I à XV) du
  23 septembre 1973 au 15 mars 1998, et les communes rurales de 1973 (VIII : Balma, Beaupuy,
  Drémil-Lafage, Flourens, Mondouzil, Mons, Montrabé, Pin-Balma, Quint ; IX : Ramonville ; XI :
  Portet ; XII : Cugnaux, Tournefeuille ; XIII : Beauzelle, Blagnac, Colomiers, Cornebarrieu,
  Mondonville ; XIV : Aucamville, Castelginest, Fenouillet, Fonbeauzard, Gagnac, Launaguet,
  Saint-Alban ; XV : Castelmaurou, Montberon, Pechbonnieu, Rouffiac, Saint-Geniès-Bellevue,
  Saint-Jean, Saint-Loup, L'Union) ; les noms Toulouse-I à IV dès 1973.
- **Tracé (écrit le 21 octobre 2026)** : `31555-1973-G`, `-AB`, `-CD` (lignes de Gaudillère
  reprises) et `-L1` à `-L12`, 1973-09-23 → 2013-01-01 ; ancres datées (points dans
  `cartes/sorties/decoupe_toulouse/commande.sh`), qui joueront quand les appartenances 1973-1998
  seront inscrites. CONFORME au 2000-01-01 (15 morceaux) et au 1980-01-01 (`--morceaux 15`).
---

## Tours (37261)

### 63. Tours : 1941-1968, et l'ANR de 1964-1970

- **Sources** : Gaudillère, Tours 1801-1956 (extrait donné par Adrien le 3 octobre 2026) ;
  chronologie : « Cr. Tours-E. et Tours-O. (division Tours-S.) », 4 août 1956.
- **Base** :
  - `37911#3721` Centre, `#3722` Nord, `#3723` Sud de 1870 à 1941 ; rien de 1941 à 1968 ; Ouest
    (`#3725`) et Est (`#3726`) n'apparaissent qu'en 1968 au lieu de 1956 ;
  - ANR de `37911` : 1 695 ha (1855-1964), puis 948 ha (1964-1970), moins qu'avant l'annexion de
    Saint-Symphorien et Sainte-Radegonde : anomalie probable ;
  - Saint-Symphorien (`34798`) n'a d'appartenance que de 1870 à 1941, Sainte-Radegonde (`31567`)
    jusqu'en 1955 ; La Ville-aux-Dames figure au canton Nord en 1900 alors qu'elle est rive
    gauche : à vérifier.
- **À inscrire** : les trois fractions de 1941 à 1956 ; Est et Ouest dès 1956 ; l'ANR de 1964-1970.
- **Tracé** : `37261-1` (C-D, bras nord de la Loire) et `37261-2` (A-B), 1801 → 1956-08-04 ; ancres
  datées Nord POINT(525600 6702750), Centre POINT(525800 6701900), Sud POINT(525500 6700000).
  Le régime de 1956-1968 (Est et Ouest issus du Sud) demande un autre texte.
---

## Avignon (84007)

### 47. Avignon : Est et Ouest de 1933 à 1941, et le régime de 1933

- **Sources** :
  - chronologie p. 821 : « Cr. Avignon-E. et Avignon-O. (division Avignon-N. et Avignon-S.) »,
    27 avril 1933 ;
  - Gaudillère : plan de 1869-1870, qui ne donne que la limite Nord / Sud.
- **Base** :
  - `2184#8402` Nord et `#8403` Sud de 1870 à 1941, sans Est ni Ouest après 1933 ;
  - Est et Ouest (`#8423`, `#8424`) n'apparaissent qu'en 1985.
- **À inscrire** :
  - de 1933 à 1941, les quatre cantons (Nord, Sud, Est, Ouest), à la place de Nord et Sud ;
  - Nord et Sud de 1801 à 1870.
- **Tracé** : `84007-1`, de 1801 au 27 avril 1933. Les limites de 1933 restent à trouver : texte
  de Gaudillère pour 1933, ou décret.
---

## Meudon (92048)

### 50. Meudon : Issy-les-Moulineaux-Ouest et Meudon de 1967 à 1998

- **Inscrit par `sql/114_villes_lot_2.sql` (13 octobre 2026)** : les deux fractions de 1968 à 1998. Reste : avant 1967.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Source** : décret 67-590 du 20 juillet 1967 (Hauts-de-Seine, JO du 22 juillet 1967,
  `jorf_txt/JORF_19670722_169_col.txt`, articles 29 et 30). Le décret 84-1241 du 24 décembre
  1984 ne touche pas ces cantons.
- **Base** :
  - l'atome entier `22356` au canton de Sèvres jusqu'en 1955 ;
  - rien de 1955 à 1998 ;
  - `22356#9222` Issy-les-Moulineaux-Ouest et `#9226` Meudon à partir du 15 mars 1998 (COG).
- **À inscrire** :
  - les deux fractions de 1967 (ou 1968, entrée en vigueur des départements) à 1998 ;
  - ce qui précède 1967, Seine-et-Oise : Meudon et Saint-Cloud depuis le 28 janvier 1964 ;
    Sèvres avant.
- **Tracé** : `92048-1`, de 1967 à 2013.
---

## Bourgoin-Jallieu (38053)

### 60. Bourgoin-Jallieu : décret 85-92, à inscrire dès 1985

- **Inscrit par `sql/114_villes_lot_2.sql` (13 octobre 2026)** : la ville dans 3804 de 1973 à 1985, les deux fractions de 1985 à 1998, le nom Bourgoin-Jallieu-Sud. Reste : le canton de L'Isle-d'Abeau et Saint-Alban-de-Roche.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Sources** : décret n° 85-92 du 24 janvier 1985, art. 4 et 5 (JO du 25 janvier 1985 ;
  `jorf_txt/JORF_19850125_21_col.txt`, lignes 1871-1889) ; Gaudillère l'abrège.
- **Base** :
  - `5316` entier au canton de Bourgoin (3804) jusqu'au 23 septembre 1973, puis rien jusqu'au
    15 mars 1998 ;
  - `5316#3804` (Bourgoin, puis Bourgoin-Jallieu-Sud en 1999) et `#3853` (Bourgoin-Jallieu-Nord)
    de 1998 à 2013 ;
  - le canton de L'Isle-d'Abeau (3858), créé par l'art. 5, ne commence qu'en 1998 ;
    L'Isle-d'Abeau (`17485`) et Saint-Alban-de-Roche (`30272`) sans canton de 1973 à 1998.
- **À inscrire** : le canton de Bourgoin maintenu de 1973 à 1985 ; les deux fractions et le
  canton de L'Isle-d'Abeau dès 1985 ; l'unité 3804 renommée Bourgoin-Jallieu-Sud dès 1985 ; le
  transfert de Saint-Alban-de-Roche (`cantons/transferts_legifrance.csv`, 26 février 1997).
- **Tracé** : `38053-1`, 1985-03-10 → 2013 ; ancres Nord POINT(877806 6503945) et Sud
  POINT(876138 6501408).
---

## Fontaine (38169)

### 59. Fontaine : décret 85-92, à inscrire dès 1985

- **Inscrit par `sql/114_villes_lot_2.sql` (13 octobre 2026)** : la ville, Seyssinet-Pariset, Seyssins, Engins et Saint-Nizier dans 3832 de 1973 à 1985 ; les deux fractions, Seyssinet et Seyssins (3856) de 1985 à 1998 ; les noms. Reste : rien.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Sources** : décret n° 85-92 du 24 janvier 1985 (JO du 25 janvier 1985, p. 1045 ;
  `jorf_txt/JORF_19850125_21_col.txt`, lignes 1663-1665 et 1727-1740) ; Gaudillère l'abrège.
- **Base** :
  - `14156` au canton de Sassenage (3832) jusqu'au 23 septembre 1973, puis aucun canton
    jusqu'au 15 mars 1998 ; même trou pour Seyssinet-Pariset, Seyssins, Engins et
    Saint-Nizier-du-Moucherotte, qu'aucun texte de 1973 ne concerne ;
  - fractions `14156#3832` (Fontaine-Sassenage) et `#3856` (Fontaine-Seyssinet) de 1998 à 2013 ;
  - l'unité 3832 n'a pas de version entre 1941 et 1999.
- **À inscrire** :
  - le canton de Sassenage maintenu de 1973 à 1985 pour ces communes ;
  - à partir de 1985 : les deux fractions de Fontaine ; Seyssinet-Pariset et Seyssins dans
    Fontaine-Seyssinet ; Noyarey, Sassenage et Veurey-Voroize dans Fontaine-Sassenage ; Engins et
    Saint-Nizier dans Villard-de-Lans.
- **Tracé** : `38169-1`, 1985-03-10 → 2013 ; ancres Nord POINT(911200 6459000) et Sud
  POINT(911200 6457800). La recette juge la ville au 15 mars 1998 tant que le trou reste.
---

## Gentilly (94037)

### 51. Gentilly : entière à Arcueil de 1976 à 1985, coupée de 1985 à 1994

- **Inscrit par `sql/114_villes_lot_2.sql` (13 octobre 2026)** : Gentilly et Arcueil dans 9434 de 1976 à 1985 (Arcueil jusqu'en 1994), les deux fractions de 1985 à 1994. Reste : rien.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Sources** :
  - décret de janvier 1976 (JO du 29 janvier 1976, `jorf_txt/JORF_19760129_24_col.txt`,
    art. 3) : « Les communes d'Arcueil et de Gentilly forment un nouveau canton » ;
  - décret 84-1242 du 24 décembre 1984 (JO du 30 décembre 1984) : Gentilly coupée entre Arcueil
    (ouest) et Le Kremlin-Bicêtre (est).
- **Base** :
  - l'atome entier `15323` au Kremlin-Bicêtre jusqu'au 7 mars 1976, puis rien ;
  - `15323#9434` Arcueil et `#9416` Kremlin-Bicêtre à partir du 20 mars 1994 (COG).
- **À inscrire** :
  - l'atome entier à Arcueil de 1976 au 24 décembre 1984 ;
  - les deux fractions de 1984-1985 à 1994.
- **Tracé** : `94037-1`, de 1984 à 2013.
---

## Chartres (28085)

### 69. Chartres : 1941-1968, et le régime de 1973-1998

- **Sources** : Gaudillère, Chartres 1928-1940 (extrait donné par Adrien le 4 octobre 2026) ;
  décret 73-719 du 23 juillet 1973 (`jorf_txt/JORF_19730725_171_col.txt`, lignes 1314-1381), qui
  reprend la même suite des Épars à « rue Jean-Mermoz et route de Paris » et crée Chartres-
  Nord-Ouest, Nord-Est, Sud-Ouest et Sud-Est ; décret 82-27 du 15 janvier 1982
  (`jorf_txt/JORF_19820116_13_col.txt`, lignes 1131-1143), qui dédouble le Nord-Ouest en Lucé et
  Mainvilliers : la part de Chartres passe à Mainvilliers avec les mêmes limites (Fbg-St-Jean,
  impasse St-Jean, Rechèvres, voie ferrée Paris-Brest). Rien d'autre avant le décret de 2014.
- **Base** : `8537#2807` (Nord) et `#2808` (Sud) de 1870 à 1941 et de 1968 au 23 septembre 1973 ;
  rien de 1941 à 1968. Puis `#2807` (Nord-Est, sans `unit_version` entre 1941 et 1999 : affiché
  « Chartres-Nord »), `#2825` (Sud-Est), `#2826` (Sud-Ouest) et `#2830` (Mainvilliers) du
  1998-03-15 au 2013 seulement : rien pour la ville du 1973-09-23 au 1998-03-15, alors que les
  communes rurales sont dans 2807, 2825, 2826 dès 1973 et dans 2829 / 2830 dès 1982. L'unité
  Chartres-Nord-Ouest n'existe pas : Lucé, Mainvilliers, Amilly, Cintray, Lèves, Bailleau et
  Saint-Aubin n'ont aucun canton de 1973 à 1982. Bascule de 1982 au 03-14, le décret est au JO du
  01-16. Le décret 73-719 manque dans `cantons/communes_coupees_1973_1984.csv`.
- **À inscrire** : les deux fractions de 1941 à 1968 ; les quatre fractions du 1973-09-23 au
  1998-03-15, avec Chartres-Nord-Ouest (unité, communes rurales, fraction) jusqu'en 1982 ; le nom
  Chartres-Nord-Est pour 2807 de 1973 à 1999.
- **Tracé** : `28085-1`, 1870 → 1973-09-23 ; ancres datées Nord POINT(590688 6818227) et Sud
  POINT(589846 6816676). `28085-2` (NO/SO, NE/SO, NE/SE), `28085-3` (NO/NE) et `28085-4` (SO/SE),
  1973-09-23 → 2013-01-01 (21 octobre 2026) ; ancres datées `#2807` Nord-Est, `#2825` Sud-Est,
  `#2826` Sud-Ouest, `#2830` Mainvilliers, posée dès 1973 sur la part du Nord-Ouest (à redater
  au 1982 si une unité Chartres-Nord-Ouest est inscrite sous un autre code). Question ouverte :
  l'« impasse Saint-Jean », introuvable — couloir le long de la voie ferrée retenu, autres lectures
  de 0,7 à 10,9 ha ; le plan annexé au décret trancherait.
---

## Douai (59178)

### 53. Douai : Douai-Ouest absent de la ville de 1968 à 1982, et 1941-1968

- **Inscrit par `sql/114_villes_lot_2.sql` (13 octobre 2026)** : `12105#5923` dans 5923 de 1968 au 1982-03-14 ; la fraction existait, rangée sous Dunkerque-Est (`12105#5925`, retirée). Reste : 1941-1968.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Sources** :
  - Gaudillère, découpage de 1922 (extrait donné par Adrien le 3 octobre 2026) : la Scarpe, et
    C-D de la place de Polincove à la rue de Sin-le-Noble ;
  - chronologie p. 809 : « Fix. limites Douai-E. et Douai-S. », 27 décembre 1922. La base n'a pas
    de Douai-Est : il s'agit sans doute de Douai-Ouest.
- **Base** :
  - `12105#5922` Nord, `#5923` Ouest, `#5924` Sud de 1870 à 1941 ;
  - Nord et Sud seulement de 1968 à 1982 ;
  - rien de 1941 à 1968.
- **À inscrire** :
  - Douai-Ouest de 1968 à 1982, sauf si la ville a quitté ce canton. La découpe de 1922 lui donne
    826 ha au nord-ouest de la Scarpe, qui sont perdus au tirage de 1968-1982 ;
  - les trois fractions de 1941 à 1968.
- **Tracé** : `59178-1` (la Scarpe) et `-2` (C-D), du 27 décembre 1922 au 14 mars 1982, ancres
  datées.
---

## Marseille (13055)

### 68. Marseille : avant 1870, et la bascule de 1886

- **Sources** : Gaudillère, Marseille 1801-1886 (extrait donné par Adrien le 3 octobre 2026) ;
  chronologie : création des 7e et 8e cantons le 13 juillet 1886.
- **Base** : `21387#1313` à `#1318` (Marseille-1 à 6) du 1er janvier 1870 au 1er janvier 1886, puis
  huit cantons, puis douze en 1901 ; rien avant 1870 ; la bascule est au 1er janvier 1886 et non
  au 13 juillet.
- **À inscrire** : les six cantons avant 1870 ; la date du 13 juillet 1886.
- **Tracé** :
  - 1801 → 1886 : `13055-1` à `-8`, autour de trois nœuds (boulevard d'Athènes, rue
    Saint-Savournin, chemin de Saint-Jean-du-Désert) ; ancres datées, une par canton ;
  - 1886 → 1901 (huit cantons) : `13055-1` à `-5`, `-7` et `-8` prolongées jusqu'en 1901 ; `-6`
    s'arrête en 1886 ; `-9` (traverse Santi … voie ferrée jusqu'à Saint-Charles, 4e / 5e), `-10`
    (Libération, Blancarde … avenue d'Haïti, 5e / 6e), `-11` (avenue de Toulon, Jarret, Huveaune
    vers l'AMONT, 6e / 7e) ; ancres datées 1886-1901, renumérotées (`#1313` sur l'ancien 3e,
    `#1315` sur l'ancien 1er, `#1320` sur l'ancien 6e). Variante prête si l'Huveaune se suit vers
    l'aval : `scratchpad/ma86/N3m.wkt`, table `public.ma86_l` (id N3m), ancre du 7e
    POINT(893000 6245000).
  - 1901 → 1973 (douze cantons) : les dix lignes précédentes prolongées jusqu'au 23 septembre
    1973 ; `-12` (place de la Joliette, rue de la République, 3e / 4e), `-13` (rue Bénédit …
    rue de l'Aiguillette, 6e / 7e), `-14` (Sakakini, Saint-Pierre, Auguste-Blanqui, 8e / 9e),
    `-15` (rue Paradis, boulevard Périer, rue du Commandant-Rolland, 10e / 11e) ; ancres datées
    1901-1973. Numéros 6/7, 8/9 et 10/11 déduits de l'ordre des cantons du décret 73-812, à
    confirmer sur le plan.
  - Les îles (397 ha) vont au canton de la côte la plus proche (Frioul et If au 11e en 1901 ;
    le décret de 1973 les donne à son canton III).
- **Base, 1901-1973** : les douze fractions `21387#1313` à `#1324` n'ont de canton que de 1901
  à 1941 ; rien de 1941 à 1973. À inscrire.
- **Source pour la suite** : décret 73-812 du 16 août 1973, vingt cantons, dans
  `cantons/communes_coupees_1973_1984.csv`.
---

## Metz (57463)

### 54. Metz : 1941-1973, et les fractions de 1968-1973 sous l'atome de Plantières-Queuleu

- **Sources** : Gaudillère (extrait donné par Adrien le 3 octobre 2026, sans date) ; chronologie
  p. 807-808 (Metz-Campagne divisé en 1967, Metz-4 en 1982).
- **Base** :
  - `22347#5717` à `#5719` (Metz-1, -2, -3) en 1870-1871 et 1919-1941 ;
  - de 1968 à 1973, des fractions `11767#5717` à `#5719` (fraction_cog) rattachées à l'atome
    11767 (Plantières-Queuleu, commune absorbée en 1907) et non à 22347 ;
  - rien de 1941 à 1968.
- **À inscrire** :
  - les fractions de Metz-1 à 3 de 1941 à 1973, sur l'atome 22347 ;
  - vérifier pourquoi les fractions de 1968-1973 sont posées sur 11767.
- **Tracé** : `57463-1` (bras mort, 1801-1941), `-2` (C-D jusqu'à la limite de 1870, 1801-1910),
  `-3` (C-D prolongé par la Seille, 1910-1941). Après 1961, la commune s'agrandit de Borny,
  Magny, Vallières… : lignes à reprendre.
---

## Nancy (54395)

### 55. Nancy : Nancy-Est absent de 1968 à 1973, et 1941-1968

- **Inscrit par `sql/114_villes_lot_2.sql` (13 octobre 2026)** : `24537#5419` de 1968 à 1973. Reste : 1941-1968.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Sources** : Gaudillère, Nancy 1801-1879 (extrait donné par Adrien le 3 octobre 2026).
- **Base** :
  - `24537#9916` à `#9918` (Est, Nord, Ouest, département de la Meurthe) en 1870-1871, puis
    `24537#5419` à `#5421` de 1871 à 1879 ; le Sud (`#5422`) à partir de 1879 ;
  - rien de 1941 à 1968 ;
  - de 1968 à 1973, Nord, Ouest et Sud seulement : Nancy-Est (`#5419`) manque.
- **À inscrire** : les fractions de 1941 à 1968, et Nancy-Est de 1968 à 1973.
- **Tracé** : `54395-1` (A-B) et `54395-2` (C-D), 1801-1973 ; `54395-3` et `-4` (limites est des
  deux tronçons du canton Sud), 1879-1973. Ancres datées : celles de `#99xx` jusqu'au 1er janvier
  1871, celles de `#54xx` ensuite ; le Sud a deux ancres. De 1968 à 1973, le morceau de l'Est
  (367 ha) n'est pas tiré, faute de fraction.
---

## Reims (51454)

### 56. Reims : 1941-1968 et 1973-1985

- **Sources** : Gaudillère, Reims 1889-1973 (extrait donné par Adrien le 3 octobre 2026).
- **Base** : `28831#5119` à `#5122` (Reims-1 à 4) de 1889 à 1941 et de 1968 au 23 septembre 1973 ;
  rien de 1941 à 1968 ni de 1973 à 1985 ; trois fractions seulement de 1870 à 1889.
- **À inscrire** : les fractions de 1941 à 1968 (mêmes limites selon le texte), et le régime de
  1973-1985.
- **Tracé** : `51454-1` (A-B), `-2` (C-D), `-3` (E-F), 1889-1973 ; ancres datées sur la même
  période. Numéros attribués par les communes rurales (1 sud-ouest, 2 nord-est, 3 sud-est,
  4 nord-ouest), à confirmer. À partir de 1970, La Neuvillette entre dans le morceau de Reims-4.
  Les limites de 1870-1889 (trois cantons) restent à tracer.
---

## Nantes (44109)

### 58. Nantes : 1941-1973, et les fractions de 1968-1973 sous l'atome de Doulon

- **Sources** : Gaudillère, Nantes 1801-1908 (extrait donné par Adrien le 3 octobre 2026) ;
  chronologie p. 802 (Nantes-7 créé le 3 avril 1908 par division de Nantes-6).
- **Base** :
  - `24557#4420` à `#4425` (Nantes-1 à 6) de 1870 à 1908, plus `#4426` (Nantes-7) de 1908 à 1941 ;
  - Chantenay (`8104`, canton Nantes-6) et Doulon (`12140`, canton de Carquefou) à part
    jusqu'en 1908 ;
  - de 1968 à 1973, des fractions `12140#4421` à `#4426` (fraction_cog) rattachées à l'atome de
    Doulon et non à 24557 ; Nantes-1 absent ; rien de 1941 à 1968.
- **À inscrire** : les fractions de 1941 à 1973 sur l'atome 24557 ; vérifier pourquoi celles de
  1968-1973 sont posées sur 12140.
- **Tracé** : `44109-1` à `-3` (A-B, B-C ouest, B-C est), 1801-1973 ; `-4` (E-F) et `-5` (G-H),
  1801-1908 ; `-6` (E-F depuis le nouveau bord ouest), `-7` (G-H, de la limite du 7e canton au nouveau bord
  est : la pointe ouest de la commune est au 7e d'après le plan) et
  `-8` (limite du 7e canton, presque l'ancienne limite de Chantenay), 1908-1973. Ancres datées
  d'après le plan de Gaudillère (1908-1973) : 1er nord-ouest, 2e nord-est (avec Doulon), 3e
  vieille ville, 4e sud, 5e entre B-C et E-F, 6e entre E-F et la Loire, 7e ancien Chantenay.
  Avant 1870 la base n'a pas d'appartenance pour Chantenay et Doulon : la cible les englobe
  (6 564 ha) et le tirage de 1850 est faux ; à corriger avec les appartenances d'avant 1870.
---

## Le Puy-en-Velay (43157)

### 61. Le Puy : les cinq cantons de 1973, et 1941-1968

- **Sources** : décret du 2 août 1973 (JO du 4 août 1973 ; `jorf_txt/JORF_19730804_180_col.txt`,
  lignes 2710-2835), qui remplace les deux cantons par cinq et redonne la suite de voies de
  Gaudillère ; chronologie : « Fix. limites Le Puy-N.O. et Le Puy-S.E. », 16 mars 1802.
- **Base** :
  - `28294#4319` (Nord-Ouest) et `#4320` (Sud-Est) de 1870 à 1941 et de 1968 au 23 septembre
    1973 ; rien de 1941 à 1968 ;
  - rien du 23 septembre 1973 au 10 mars 1985 ; `#4331` Est, `#4332` Ouest, `#4333` Sud-Ouest ne
    commencent qu'en 1985 ; `#4319` s'appelle encore « Le Puy-Nord-Ouest » de 1985 à 1999 alors
    que c'est Le Puy-Nord depuis 1973.
- **À inscrire** : les deux fractions de 1941 à 1968 ; les cinq cantons dès 1973.
- **Tracé** : `43157-1`, 1802-03-16 → 1973-09-23 ; ancres datées Nord-Ouest POINT(769890 6438900)
  et Sud-Est POINT(769545 6438450). Après 1973 la même ligne sépare Nord et Ouest d'Est, Sud-Est
  et Sud-Ouest : trois lignes du décret restent à tracer (Nord / Ouest, Est / Sud-Est,
  Sud-Ouest / Sud-Est).
---

## Saint-Étienne (42218)

### 62. Saint-Étienne : avant 1870, 1941-1968, et le double compte de 1969-1973

- **Sources** : Gaudillère (extraits donnés par Adrien le 3 octobre 2026) ; chronologie : limite
  Est / Ouest fixée le 19 août 1831, quatre cantons créés le 9 mai 1860 par division des deux
  anciens, décret du 13 juillet 1973.
- **Base** :
  - `31635#4219` Nord-Est, `#4220` Sud-Est, `#4221` Nord-Ouest, `#4222` Sud-Ouest de 1870 à 1941
    et de 1968 au 23 septembre 1973 ; rien avant 1870 ni de 1941 à 1968 ;
  - de 1969 à 1973, l'ANR de `31635` contient déjà Saint-Victor-sur-Loire, Terrenoire puis
    Rochetaillée, dont les atomes (34944, 37261, 29398) gardent géométrie et canton jusqu'au
    23 septembre 1973 : double compte. L'ANR les fait entrer au 1er janvier 1969, `insee_mvt`
    donne le 18 octobre 1969 (Saint-Victor) et le 1er janvier 1970 (Terrenoire).
- **À inscrire** : les unités Est / Ouest d'avant 1860 et les quatre cantons de 1860 à 1870 ; les
  fractions de 1941 à 1968 ; corriger l'ANR de 1969-1973.
- **Tracé** : `42218-1` (A-B, 1857 → 1973), `-2` (C-D, 1860-05-09 → 1973), `-3` (ancienne limite
  de Terrenoire) et `-4` (contour de Saint-Victor), 1969 → 1973, `-5` (ancienne limite de
  Rochetaillée), 1973. Les trois morceaux annexés restent sans ancre et ne sont pas tirés.
  Points pour Est / Ouest avant 1860 : POINT(810107 6482682) et POINT(808013 6481980).
---

## Rennes (35238)

### 64. Rennes : communes rurales de 1870-1941 rangées sous le mauvais code

- **Inscrit par `sql/114_villes_lot_2.sql` (13 octobre 2026)** : les communes rurales de 1815-1941 remises sous le bon canton (30 lignes : 3530 → 3531 → 3532 → 3530) ; `28930#3529` de 1968 à 1973. Reste : 1941-1968.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Sources** : Gaudillère, Rennes 1801-1973 (extrait donné par Adrien le 3 octobre 2026, titré
  « Reims » par erreur) ; chronologie : Rennes-I à X créés le 23 juillet 1973.
- **Base** :
  - `28930#3529` (Nord-Est), `#3530` (Nord-Ouest), `#3531` (Sud-Est), `#3532` (Sud-Ouest) de 1870
    à 1941 ; `#3530` à `#3532` seulement de 1968 à 1973 ; `#3529` sans appartenance de 1941 à 1992 ;
  - de 1870 à 1941 les communes rurales sont décalées par rapport aux noms : Cesson, Chantepie,
    Acigné, Vern sous 3530 (Nord-Ouest) ; Saint-Jacques, Vezin, Bruz, Noyal sous 3531 (Sud-Est) ;
    Pacé, Parthenay sous 3532 (Sud-Ouest). De 1954 à 1973 elles suivent bien les noms.
- **À inscrire** : pour 1870-1941, Cesson, Chantepie, Acigné, Vern → 3531 ; Saint-Jacques, Vezin,
  Bruz, Noyal → 3532 ; Pacé, Parthenay → 3530 ; les fractions de 1941 à 1968 et `#3529` jusqu'en
  1973.
- **Tracé** : `35238-1` (A-B) et `-2` (C-D, la Vilaine), 1801 → 1973-09-23 ; ancres datées posées
  par les noms des cantons, que le plan de Gaudillère confirme. Le lobe sud, que la rue de Nantes
  retraverse, est tout au Sud-Est sur le plan : pas de ligne dessus.
- **Constats du 24 octobre 2026 (tracé de 1973 et 1982)** :
  - sources : décret 73-723 (`jorf_txt/JORF_19730725_171_col.txt` l. 2041-2163), décret 82-80
    (`JORF_19820126_21` l. 727-791 : VIII-1 rural, VIII-2 urbain, VII coupé par bd Oscar-Leroux,
    bd Léon-Grimault, rue de Vern), décret du 16 janvier 1985 (`JORF_19850118_15_col.txt`
    l. 1792-1804 : noms seuls), décret 91-214 (Cesson-Sévigné et Betton, communes rurales seules) ;
  - aucune fraction de Rennes entre 1973-09-23 et 1992-03-22. À inscrire : Rennes-I à X de 1973 à
    1982 (`28930#3529` I, `#3530` II, `#3531` III, `#3532` IV, `#3544` V, `#3545` VI, `#3546` VII,
    `#3551` VIII, `#3548` IX, `#3549` X — codes à valider : la base met Noyal et Châtillon sous
    3547 (Bruz) de 1973 à 1982 et il n'y a pas d'atome `28930#3547`), puis les onze fractions de
    1982 (`#3550` VII-2) à 1992 ;
  - communes rurales sous le code de leur successeur de 1991, de 1973 à 1992 : Betton, Montgermont,
    Saint-Grégoire sous 3552 (Betton) au lieu de 3532 (Rennes-IV) ; Cesson-Sévigné sous 3553 au lieu
    de 3545 (Rennes-VI). Chantepie, Saint-Jacques et Vezin sans appartenance de 1973 à 1992 ;
  - de 1992 à 1999, pas d'`unit_version` : 3529 à 3532 s'affichent sous les noms de 1815
    (Nord-Est…), en double avec 3544, 3546 et 3549 ;
  - un atome 22672 (insee 35182, sans nom) a une ANR en 1980 qui touche Rennes sur 1,5 km, sans
    appartenance : à vérifier.
- **Tracé (24 octobre 2026)** : `35238-1973-*` (17 lignes, 1973-09-23 → 1982-03-14,
  `--morceaux 10`) et `35238-1982-*` (18 lignes, 1982-03-14 → 2013-01-01) ; ancres datées dans
  `cartes/sorties/decoupe_rennes/COMMANDES.sh`.
---

## Béziers (34032)

### 65. Béziers : 1941-1968 et les quatre cantons de 1973

- **Sources** : Gaudillère, Béziers 1801-1973 ; décret 73-722 du 23 juillet 1973, dont le texte
  est dans `cantons/communes_coupees_1973_1984.csv`, lignes 177 à 180 (Béziers-I à IV).
- **Base** : `4149#3404` (Béziers-1) et `#3405` (Béziers-2) de 1870 à 1941, de 1968 à 1973 et de
  1992 à 2013 ; `#3438` et `#3439` n'apparaissent qu'en 1992 ; Bassan sans canton de 1941 à 1973,
  Boujan et Lieuran de 1955 à 1973 ; Portiragnes à la fois dans Béziers-1 et Lodève de 1968 à 1973.
- **À inscrire** : les fractions de 1941 à 1968 ; le régime à quatre cantons dès 1973.
- **Tracé** : `34032-1`, 1801 → 1973-09-23 ; ancres datées Béziers-1 (nord) POINT(718275 6250736)
  et Béziers-2 (sud) POINT(718497 6247627). Béziers-1 au nord : confirmé par Adrien le 3 octobre
  2026 (Villeneuve et Cers, de Béziers-1, ne touchent pourtant que le morceau sud).
- **Constats du 24 octobre 2026 (tracé de 1973 et 1985)** :
  - décret 73-722 (JO du 25 juillet 1973, `jorf_txt/JORF_19730725_171_col.txt` l. 1895-2006) et
    décret 85-146 du 31 janvier 1985 (JO du 1er février, `jorf_txt/JORF_19850201_27_col.txt`
    l. 1450-1488 : art. 1, la poche de IV à l'ouest de la ligne Wilson … Castelbon passe à I ;
    art. 2, Lespignan passe de IV à III) ;
  - aucune fraction de Béziers du 1973-09-23 au 1992-03-22, alors que les communes rurales passent
    à 3405, 3438, 3439 dès le 1973-09-23. À inscrire : `4149#3404` (I, îlot central, sans commune
    rurale), `#3405` (II), `#3438` (III), `#3439` (IV), de 1973-09-23 à 1992-03-22 ;
  - Lespignan sans canton du 1985-03-10 au 1992-03-22 : à mettre dans 3438 (Béziers-III) ;
  - le code 3404, Béziers-1 au nord jusqu'en 1973, devient l'îlot central Béziers-I : ancres datées.
- **Tracé (24 octobre 2026)** : `34032-1973-I`, `-II-III`, `-III-IV`, `-II-IV` (1973-09-23 →
  1985-03-10, `--morceaux 4`) et `34032-1985-*` (1985-03-10 → 2013-01-01) ; ancres datées
  3404 POINT(718091 6249702), 3405 POINT(722094 6251772), 3438 POINT(714500 6250500),
  3439 POINT(717500 6246500). Sources et scripts : `cartes/sorties/decoupe_beziers/`.
---

## Montpellier (34172)

### 66. Montpellier : 1941-1992

- **Sources** : Gaudillère, Montpellier 1801-1973 ; chronologie : Montpellier-4 à 9 créés le
  23 juillet 1973, Montpellier-10 le 31 janvier 1985.
- **Base** : `23741#3422` à `#3424` (Montpellier-1 à 3) de 1870 à 1941, puis dix cantons à partir
  du 22 mars 1992 ; rien entre, alors que les communes rurales des 2e et 3e cantons sont suivies
  jusqu'en 1973.
- **À inscrire** : les trois fractions de 1941 à 1973 ; les cantons de 1973 et de 1985 à leur date.
- **Tracé** : `34172-1` (contour fermé du 1er canton), `-2` (A-B), `-3` (C-D, par l'ancienne voie ferrée de Paulhan
  d'après le plan), 1801 → 1973-09-23 ;
  ancres datées 1er POINT(770750 6279500), 2e POINT(773000 6280000), 3e POINT(768000 6278500).
- **Constats du 24 octobre 2026 (tracé de 1973 et 1985)** :
  - correction : la base a désormais `#3422` à `#3424` de 1941 au 1973-09-23 ;
  - sources : décret 73-722 (JO du 25 juillet 1973), décret 85-146 (JO du 1er février 1985,
    art. 4), décret 91-213 du 27 février 1991 (JO du 28 février, p. 2903 : Castelnau-le-Lez,
    Lattes, Pignan, communes rurales seules ; la ville garde les limites de 1985 jusqu'en 2015) ;
  - aucune fraction de Montpellier du 1973-09-23 au 1992-03-22. À inscrire : du 1973-09-23 au
    1985-03-10, `23741#3422` (I), `#3423` (II), `#3424` (III), `#3440` à `#3445` (IV à IX) ; du
    1985-03-10 au 1992-03-22, `#3422` à `#3446` (X) ;
  - communes rurales de 1973 à 1992 : Castelnau-le-Lez et Le Crès sans canton (à mettre au III,
    3424) ; Lattes, Palavas, Pérols sous 3448 « Lattes » dès 1973 alors qu'elles sont au V (3441)
    jusqu'au 1992-03-22 ; Grabels et Juvignac sans canton (IX, 3445, de 1973 à 1985, puis X, 3446) ;
    Cournonsec, Cournonterral, Fabrègues, Lavérune, Murviel, Pignan, Saint-Georges-d'Orques,
    Saint-Jean-de-Védas, Saussan sans canton (VIII, 3444, de 1973 à 1992). Clapiers et Montferrier
    bien sous 3423 ;
  - `unit_version` des unités 3440 à 3449 ne commence qu'en 1999.
- **Tracé (24 octobre 2026)** : `34172-1973-*` (12 lignes, 1973-09-23 → 1985-03-10,
  `--morceaux 10`) et `34172-1985-*` (18 lignes, 1985-03-10 → 2013-01-01) ; ancres datées dans
  `cartes/sorties/decoupe_montpellier/cmd_1973.sh` et `cmd_1985.sh`.
---

## Sarcelles (95585)

### 52. Sarcelles : 1964-1985

- **Inscrit par `sql/115_villes_nomenclature.sql` (13 octobre 2026)** : Est sous 9523 (Nord-Est) et Saint-Brice sous 9533 (Sud-Ouest) du 1976-03-07 au 1985-03-10, ancres datées. Reste : 1964-1976 ; la commune de Saint-Brice.
  Règle de nomenclature du 13 octobre 2026 (Adrien) : pas d'unité nouvelle, le canton disparu est porté par l'unité du régime suivant qui hérite de la plus grande part de son territoire dans la ville.

- **Sources** :
  - décret 67-593 du 20 juillet 1967 (JO du 22 juillet 1967) : canton de Sarcelles, la commune
    entière ;
  - décret de janvier 1976 (JO du 29 janvier 1976, art. 7 et 8) : Sarcelles-Saint-Brice (ouest de
    Sarcelles, avec Saint-Brice) et Sarcelles-Est. La limite est donnée voie par voie ;
  - décret 85-153 du 31 janvier 1985 (JO du 1er février) : Nord-Est et Sud-Ouest.
- **Base** :
  - l'atome entier `35344` au canton d'Écouen jusqu'en 1955 ;
  - rien de 1955 à 1985 ;
  - `#9523` Nord-Est et `#9533` Sud-Ouest à partir du 10 mars 1985.
- **À inscrire** :
  - Sarcelles entière au canton de Sarcelles (Sarcelles-Centre) de 1964 à 1976 ;
  - deux fractions, Sarcelles-Est et Sarcelles-Saint-Brice, de 1976 à 1985.
- **Tracé** :
  - `95585-1`, de 1985 à 2013 ;
  - `95585-2`, du 22 janvier 1976 au 10 mars 1985, écrit sans ancre. Points à poser : Sarcelles-Saint-Brice POINT(654109 6877489), 365,2 ha ; Sarcelles-Est POINT(655165 6876410), 477,5 ha.
---

## Dijon (21231)

### 72. Dijon : 1941-1968, et Nord et Sud absents de 1968 à 1973

- **Inscrit par `sql/114_villes_lot_2.sql` (13 octobre 2026)** : Nord et Sud de 1968 à 1973. Reste : 1941-1968.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Sources** : Gaudillère, Dijon 1907-1973 (extrait donné par Adrien le 4 octobre 2026).
- **Base** : `11845#2109` (Est), `#2110` (Nord), `#2111` (Ouest), `#2112` (Sud) de 1907 à 1941 ;
  rien de 1941 à 1968 ; de 1968 à 1973, Est et Ouest seulement.
- **À inscrire** : les quatre fractions de 1941 à 1968, Nord et Sud de 1968 à 1973.
- **Tracé** : `21231-1` (A-B) et `21231-2` (C-D), 1907-1973, ancres datées sur la même période.
  De 1968 à 1973, les morceaux du Nord (1 457 ha) et du Sud (979 ha) ne sont pas tirés, faute de
  fraction. Sud (sud-est) et Ouest (sud-ouest) sont attribués par les noms : à confirmer sur le plan.
- Constat du 18 octobre 2026 : la base porte désormais les quatre fractions de 1941 à 1968
  (`sql/116_villes_couverture_1941.sql`, vraisemblablement) ; le « Reste » ci-dessus est à vérifier.

### 120. Dijon : les noms de 2109, 2110, 2111 de 1973 à 1999 (Dijon-I, II, III)

- **Inscrit par `sql/124_villes_lot_3.sql` (23 octobre 2026)** : noms Dijon-I, II, III et V (2109, 2110, 2111, 2139) de 1973 à 1999. Reste : VI à VIII (2140-2142), que rien dans la base ne confirme.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Source** : décret n° 73-813 du 16 août 1973 (JO du 17 août 1973,
  `jorf_txt/JORF_19730817_190_col.txt`, l. 1336-1457).
- **Base** : de 1973-09-23 à 1999-01-01, `unit_version` nomme 2109, 2110, 2111 « Dijon-Est »,
  « Dijon-Nord », « Dijon-Ouest » ; 2112 est déjà « Dijon-IV » (entrée 98).
- **Vérifié par les communes rurales en 1980** : 2109 porte Saint-Apollinaire (21540), Ruffey (21535) et
  six autres communes (= Dijon-I du décret) ; 2110 porte Quetigny (21515),
  Chevigny-Saint-Sauveur (21171), Sennecey (21605) et cinq autres (= Dijon-II) ; 2111 n'a que Dijon (= Dijon-III,
  sans commune rurale au décret). 2139 porte Corcelles-les-Monts (21192) et six autres (= Dijon-V).
- **À inscrire** : les noms « Dijon-I », « Dijon-II », « Dijon-III » pour 2109, 2110, 2111 du
  1973-09-23 au 1999-01-01 (et, si on veut, « Dijon-V » à « Dijon-VIII » pour 2139-2142 sur la même
  période, au lieu de « Dijon 5e … 8e Canton »).
- **Tracé** : `21231-1973-L1` à `L7`, 1973-09-23 → 2013-01-01, écrits le 18 octobre 2026, ancres
  datées sur la même période. Le nom n'affecte pas le tirage. 2140, 2141, 2142 sont rattachés aux
  morceaux VI, VII, VIII par leurs seuls noms de 1999 (6e, 7e, 8e Canton) : rien dans la base ne
  le confirme (aucune commune rurale), et le contrôle par les logements ne départage pas ces trois
  morceaux de tailles voisines.

## Saint-Brieuc (22278)

### 73. Saint-Brieuc : 1941-1982

- **Inscrit par `sql/114_villes_lot_2.sql` (13 octobre 2026)** : les deux fractions de 1941 à 1982. Reste : `30713#2244`, fraction de 1968-1982 accrochée à un autre atome (commune 22276). Les limites de 1982 sont tracées le 18 octobre 2026 (`22278-1982-ouest-nord`, `-nord-sud`, `-ouest-sud`, 1982-03-14 → 2013, ancres datées `#2244` POINT(275800 6839800), `#2245` POINT(276000 6838500), `#2252` POINT(273000 6839500)) ; `22278-1` est prolongée au 1801-10-27 (arrêté du 5 brumaire an X, même ligne). Nom : 2244 et 2245 s'appellent « Saint-Brieuc-1 » et « -2 » de 1982 à 1999 (repli), alors que le décret 82-54 les nomme Saint-Brieuc-Nord et Saint-Brieuc-Sud.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Sources** : Gaudillère, Saint-Brieuc (extrait donné par Adrien le 4 octobre 2026).
- **Base** : `30795#2244` (canton 1, Nord) et `#2245` (canton 2, Midi) de 1870 à 1941 ; rien de
  1941 au 14 mars 1982, où commencent les trois cantons (Nord, Sud, Ouest).
- **À inscrire** : les deux fractions de 1941 à 1982.
- **Tracé** : `22278-1`, 1870-1982, ancres datées sur la même période. Les deux limites de 1982
  restent à tracer.

## Royan (17306)

### 74. Royan : 1973-1985

- **Sources** : Gaudillère, Royan (extrait donné par Adrien le 4 octobre 2026).
- **Base** : la commune entière (`29927`) au canton de Royan jusqu'au 23 septembre 1973 ; rien
  ensuite jusqu'au 10 mars 1985, où commencent `29927#1725` (Royan, puis Royan-Est) et `#1743`
  (Royan-Ouest).
- **À inscrire** : l'appartenance de 1973 à 1985 — commune entière si la division date bien de
  1985, à vérifier au décret.
- **Tracé** : `17306-1`, 1985-2013, ancres non datées.

## Bordeaux (33063)

### 75. Bordeaux : La Bastide avant 1865, Caudéran après 1965, 1941-1968, et les 2ᵉ et 6ᵉ de 1968 à 1973

- **Inscrit par `sql/114_villes_lot_2.sql` (13 octobre 2026)** : les 2ᵉ et 6ᵉ de 1968 à 1973. Reste : la rive droite avant 1865, 1941-1968, Caudéran 1955-1965, les huit cantons de 1982.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Sources** : Gaudillère, Bordeaux, organisation cantonale 1801-1973 (extrait donné par Adrien
  le 4 octobre 2026) : « les terrains […] sur la rive droite de la Garonne ont été détachés de la
  commune de Cenon et rattachés au 5ᵉ canton de Bordeaux en 1864-1865 seulement. Ils ont été
  érigés en 7ᵉ canton de Bordeaux en 1888 ».
- **Base** :
  - ANR de `4923` : 4 131 ha de 1790 à 1965, rive droite (622 ha) comprise dès 1790 ;
  - `4923#3308` à `#3313` (cantons 1 à 6) de 1870 à 1941, `#3314` (7ᵉ) de 1888 à 1941 ; aucune
    fraction ne porte la rive droite au 5ᵉ canton de 1870 à 1888 — une fraction n'a qu'un canton,
    c'est l'ancre datée du 5ᵉ qui la lui donne ;
  - rien de 1941 à 1968 ; de 1968 à 1973, les 1ᵉʳ, 3ᵉ, 4ᵉ, 5ᵉ et 7ᵉ seulement ;
  - Caudéran (`7232`) au 2ᵉ canton (3309) jusqu'en 1955, rien de 1955 à 1965 ; annexée en 1965
    dans l'ANR.
- **À inscrire** : l'ANR de Bordeaux sans la rive droite avant 1865 (alors à Cenon) ; les sept
  fractions de 1941 à 1968 ; les 2ᵉ et 6ᵉ de 1968 à 1973 ; Caudéran de 1955 à 1965.
- **Tracé** : `33063-1` à `-5` (A-B à I-J) et `33063-6` (la Garonne), 1801-1973 ; `33063-7` et
  `-8` (ancienne limite de Caudéran, au nord de A-B et au sud de C-D), 1965-1973, déduction :
  Caudéran laissée au 2ᵉ canton. Ancres datées ; la rive droite a celle du 5ᵉ de 1865 à 1888 et
  celle du 7ᵉ ensuite. De 1968 à 1973, les morceaux du 2ᵉ (997 ha, Caudéran comprise) et du 6ᵉ
  (465 ha) ne sont pas tirés, faute de fraction. Numéros attribués du nord au sud : à confirmer
  sur le plan. Les huit cantons de 1982 restent à tracer.

## Nîmes (30189)

### 76. Nîmes après 1880 : limites à tracer, et un trou de 1973 à 1992

- **Sources** :
  - Gaudillère, extrait donné par Adrien le 4 octobre 2026 : limites de 1801-1880, deux lignes
    (A-B : R.N. 106 … le Petit Vistre ; C-D : rue de la Madeleine … route d'Avignon) ;
  - `cantons/chronologie_cantonale.csv` : 1880-03-13 « Fix. limites Nîmes-1 et Nîmes-3 » ;
    1973-07-23 « Cr. Nîmes-4 et Nîmes-5 » ; 1982-01-20 « Cr. Nîmes-6 et La Vistrenque ».
- **Base** :
  - 1870-1941 et 1968-1973 : `25041#3017`, `#3018`, `#3019` (Nîmes-1, 2, 3) ;
  - 1973-09-23 → 1992-03-22 : aucun canton ;
  - à partir du 1992-03-22 : sept fractions (`#3042` à `#3045` en plus), alors que les textes
    datent Nîmes-4 et 5 de 1973, Nîmes-6 et La Vistrenque de 1982.
- **À inscrire** : les fractions de Nîmes de 1973 à 1992 (cinq cantons en 1973, sept en 1982).
  Rien à inscrire pour 1801-1880 : les trois fractions existent, à partir de 1870.
- **Tracé** : `30189-1` (A-B) et `30189-2` (C-D), du 1er janvier 1801 au 13 mars 1880, ancres
  datées. Conforme au 1er janvier 1875 (9 050 / 5 251 / 1 817 ha).
- **À vérifier** :
  - le texte des limites de 1880 : sans lui, 1880-1941 et 1968-1973 ne sont pas découpés ;
  - A-B donne à Nîmes-1 tout le sud de la commune au-delà du Vistre (2 274 ha, qui touche
    Bouillargues et Caissargues, du 3e canton) : position du point B sur le plan ;
  - C-D donne à Nîmes-3 un lobe de 67 ha au nord (Mont Duplan), relié par un goulot de 185 m.

- **Textes lus et tracé écrit (21 octobre 2026)** : décret 73-721 du 23 juillet 1973 (JO du
  25 juillet 1973, `jorf_txt/JORF_19730725_171_col.txt` l. 1620) : Nîmes-I, III, IV, V « en
  remplacement des premier et troisième cantons » ; IV avec Caissargues et Garons, III avec
  Bouillargues et Rodilhan, V avec Milhaud ; le 2e inchangé. Décret 82-57 du 20 janvier 1982 (JO du
  22 janvier 1982, `JORF_19820122_18_col.txt` l. 680) : III, IV, V, VI et La Vistrenque (Milhaud,
  Caissargues, Garons, Bouillargues, Rodilhan, et la part de Nîmes au sud du CD 135), en
  remplacement de III, IV et V ; I et 2 inchangés.
- **À inscrire** : 1973-09-23 → 1982-03-14 : Nîmes-I = `#3017`, 2 = `#3018`, III = `#3019`
  (+ Bouillargues, Rodilhan), IV = `#3042` (+ Caissargues, Garons), V = `#3043` (+ Milhaud) ;
  1982-03-14 → 1992-03-22 : les sept fractions de 1992 (`#3045` = La Vistrenque, chef-lieu
  Bouillargues). Base : Caissargues reste à 3019 et Milhaud à 3017 jusqu'au 1973-09-23 seulement ;
  Bouillargues et Rodilhan n'ont rien de 1973 à 1992.
- **Tracé** : `30189-3`/`-4` (1880-1973, HYPOTHESE, source `main` : la loi du 13 mars 1880 n'a pas
  été lue ; limite 1/3 prise sur I/IV + IV/V de 1973), `-5` à `-8` (1973-1982, `--morceaux 5`),
  `-9` à `-14` (1982-2013). Lignes, notes, commandes : `cartes/sorties/decoupe_nimes/`.
- **Les deux « à vérifier » de 1801** : le sud au-delà du Vistre est à Nîmes-V en 1973 (ancien
  1er) et à La Vistrenque en 1982 ; le lobe du Mont Duplan (Rangueil, Crucimèle, Bonfa, Rostand,
  Vincent-Faïta) est récité tel quel par IV en 1973 et en 1982.
- **Reste à lire** : loi du 13 mars 1880, JO du 14 mars 1880 (Gallica et HathiTrust : 403).
## Dole (39198)

### 78. Goux, fusionnée en 1973, garde une appartenance propre à Dole-Nord-Est jusqu'en 1999

- **13 octobre 2026** : réponse d'Adrien : « les communes fusionnées on garde leur appartenance pour tracer leur chemin mais il faut modifier la carte en conséquence ». L'appartenance de Goux reste ; `sql/84` dessine désormais une commune fusionnée encore vivante sur son dernier polygone ANR et la retranche de la ville. En 1980 : Goux 581 ha (3 719 avant), `11908#3913` 2 463 ha, `11908#3933` 702 ha. Vaut pour Puy-Saint-Pierre (déjà servie par la reprise), Saint-Martin-les-Eaux, Saint-Dézery, La Tourette, Saint-Étienne 1969-1973. Entrée close.

- **Source** : décret n° 73-659 du 13 juillet 1973 (JO du 17 juillet 1973,
  `cantons/communes_coupees_1973_1984.csv`), qui range Goux dans Dole-Nord-Est.
- **Base** : l'atome `15872` (Goux, 581 ha, ANR close au 1973-01-01, géométrie `successeur`) est
  dans 3913 du 1973-09-23 au 1999-01-01, alors que son territoire est déjà dans la cible de Dole
  (3 235 ha en 1972, 3 815 ha ensuite) et tombe dans la fraction `11908#3913`.
- **Conséquence** : même canton des deux côtés, rien de faux sur la carte ; Goux est comptée deux
  fois dans Dole-Nord-Est de 1973 à 1999 (comme Puy-Saint-Pierre à Briançon).
- **À inscrire** : à décider par Adrien — clore l'appartenance de `15872` en 1973, ou la laisser.
- **Tracé** : `39198-1` ne dépend pas de la décision.

---

## Le Cannet (06030)

### 79. Le canton du Cannet de 1955 à 1998 : deux trous, et les fractions de 1982 qui commencent en 1998

- **Inscrit par `sql/114_villes_lot_2.sql` (13 octobre 2026)** : les quatre communes dans 0634 de 1973 à 1982, les deux fractions de 1982 à 1998. Reste : 1955-1968 (décret de 1957 non vu).
  Ce qui suit est l'entrée d'avant l'inscription.

- **Sources** :
  - chronologie cantonale : « Cr. Le Cannet (division Cannes) », 21 octobre 1957 ;
  - décret n° 82-79 du 25 janvier 1982 (JO du 26 janvier 1982, `jorf_txt/JORF_19820126_21_col.txt`
    et `cantons/communes_coupees_1973_1984.csv`), art. 2 : le canton du Cannet est divisé en
    Le Cannet (l'est de la ville seul) et Mougins (Mougins, Mouans-Sartoux, La Roquette-sur-Siagne
    et l'ouest de la ville).
- **Base** :
  - l'atome `6809` est dans 0606 (Cannes) jusqu'au 1955-01-01, puis dans 0634 du 1968-01-01 au
    1973-09-23 seulement : **aucun canton de 1955 à 1968, ni de 1973-09-23 à 1998-03-15** ;
  - Mougins, Mouans-Sartoux et La Roquette-sur-Siagne : rien de 1955 à 1968 ni de 1973-09-23 au
    1982-03-14 ; elles sont bien dans 0646 dès le 1982-03-14 ;
  - les fractions `6809#0634` et `6809#0646` ne commencent qu'au **1998-03-15** ;
  - 0634 et 0646 n'ont pas de nom avant 1999 dans `unit_version`.
- **À inscrire** :
  - les quatre communes dans 0606 de 1955 au 21 octobre 1957, puis dans 0634 jusqu'en 1968 (à
    vérifier sur le décret de 1957, non vu) ;
  - les quatre communes dans 0634 de 1973-09-23 au 1982-03-14 ;
  - les deux fractions du Cannet dès le 1982-03-14.
- **Déjà prêt** : `06030-1` (1982-03-14 → 2013), ancrée ; elle couvre déjà 1982-1998
  (`carte_coupe_ville('06030', '1990-01-01')` rend 512 et 258 ha).

---

## Montluçon (03185)

### 82. Montluçon de 1973 à 1985 : quatre puis cinq cantons que la base ne connaît qu'à partir de 1985

- **Inscrit par `sql/115_villes_nomenclature.sql` (13 octobre 2026)** : Nord de 1973 sous 0331 (Nord-Est) avec Domérat, Saint-Victor et Vaux ; `#0320`, `#0321`, `#0332` de 1973 à 1985 ; `#0331` et `#0334` de 1982 à 1985 (Domérat dans 0334). Reste : rien.
  Règle de nomenclature du 13 octobre 2026 (Adrien) : pas d'unité nouvelle, le canton disparu est porté par l'unité du régime suivant qui hérite de la plus grande part de son territoire dans la ville.

- **Sources** :
  - décret n° 73-713 du 23 juillet 1973 (JO du 25 juillet 1973), art. 1er : Montluçon-Nord-I
    (Saint-Victor, Domérat, Vaux), Ouest-II (Lamaids, Prémilhat, Quinssaines), Sud-III
    (Lavault-Sainte-Anne, Néris-les-Bains, Lignerolles, Teillet-Argenty), Est-IV (Chamblet,
    Deneuille-les-Mines, Désertines, Saint-Angel, Verneix), chacun avec une partie de la ville ;
  - décret n° 82-22 du 15 janvier 1982 (JO du 16 janvier 1982) : Montluçon-Nord divisé en
    Montluçon-Nord-Est (Saint-Victor, Vaux) et Domérat-Montluçon-Nord-Ouest (Domérat).
- **Base** :
  - fractions `23649#0320` (Est) et `#0321` (Ouest) : 1870-1941 puis 1985-03-10 ; `#0331`, `#0332`,
    `#0334` seulement à partir du **1985-03-10** ; aucune fraction avec canton de 1941 à 1985 ;
  - aucune unité « Montluçon-Nord » pour 1973-1982 : Domérat (03101) et Saint-Victor (03262) n'ont
    aucun canton du 1973-09-23 au 1985-03-10 ; Néris, Prémilhat et Désertines sont bien rangés dès 1973.
- **À inscrire** :
  - une unité Montluçon-Nord, 1973-09-23 → 1982-03-14, avec Domérat, Saint-Victor, Vaux et une
    fraction de la ville ;
  - `#0320`, `#0321`, `#0332` du 1973-09-23 au 1985-03-10 ; `#0331` et `#0334` (et leurs communes)
    du 1982-03-14 au 1985-03-10.
- **Déjà prêt** : lignes `03185-2` à `03185-5` (1973-09-23 → 2013) et `03185-6` (1982-03-14 → 2013),
  ancres datées posées pour les cinq fractions. Ancre à poser pour le Nord de 1973-1982 :
  `POINT(669000 6584300)` (554,8 ha). La ligne `03185-1` (le Cher) s'arrête désormais au 1973-09-23.

## Carcassonne (11069)

### 87. Carcassonne : l'Ouest de 1968-1973 sous « Castelnaudary-Nord », rien de 1973 à 1998, et le décret de 1997 absent de la chronologie

- **Inscrit par `sql/114_villes_lot_2.sql` (13 octobre 2026)** : `6912#1108` de 1968 à 1973 à la place de `6912#1109` (retirée) ; les trois fractions et Pennautier de 1973 à 1998 ; les noms Carcassonne-I, II, III, II-Nord, II-Sud. Reste : le décret de 1997 dans la chronologie.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Sources** :
  - arrêté du 11 messidor an X (30 juin 1802), *Bulletin des lois* an XI, n° 228 bis, p. 137 :
    Carcassonne (Est) avec Berriac, Cavanac, Cazilhac, Couffoulens, Leuc, Palaja ; Carcassonne
    (Ouest) avec Pennautier. Il ne décrit pas la limite dans la ville ;
  - décret n° 73-653 du 13 juillet 1973 (JO du 17 juillet 1973, p. 7703 ;
    `jorf_txt/JORF_19730717_164_col.txt`) : Carcassonne-II et III remplacent Carcassonne-Ouest,
    Carcassonne-Est devient Carcassonne-I ;
  - décret n° 85-72 du 22 janvier 1985 (JO du 23 janvier 1985, p. 931-932 ;
    `jorf_txt/JORF_19850123_19_col.txt`), art. 2 : une portion de II passe à III ;
  - décret du 26 février 1997 (NOR INTA9700059D, JO du 27 février 1997 ;
    `jorf_txt/JORF_19970227_49_col.txt`, où l'OCR écrit « H-Sud » pour II-Sud ; numéro du décret
    absent de l'OCR) : création de Carcassonne II-Sud, II devient II-Nord, effet au renouvellement
    de mars 1998.
- **Base** :
  - 1815-1941 : `6912#1107` Est, `6912#1108` Ouest ;
  - 1968-1973 : `6912#1107` Est et **`6912#1109` dans l'unité 1109 « Castelnaudary-Nord »**, sans
    géométrie ; `6912#1108` n'a aucune appartenance. Cause : dans
    `cog1968/communes_1968_fusion.csv`, deux lignes ont leurs codes intervertis — « cARCASSONNE
    Canton Ouest » (canton 08) porte le code 11089, celui de Cenne-Monestiés, et
    « Cenne-Monestiés » (canton 09, Castelnaudary-Nord) porte le code 11069 ;
  - 1973-1998 : aucune fraction de la ville ; Pennautier (canton II) sans canton non plus ;
  - à partir du 1998-03-15 : `#1107` (1er canton), `#1108` (2e Canton-Nord), `#1135` (2e
    Canton-Sud), `#1132` (3e canton) : juste ;
  - `cantons/chronologie_cantonale.csv` ne connaît pas le décret de 1997.
- **À inscrire** :
  - 1968-1973 : `6912#1108` dans 1108 à la place de `6912#1109` ; Cenne-Monestiés (11089) dans
    1109 si elle y manque ;
  - 1973-09-23 → 1998-03-15 : `6912#1107` (Carcassonne-I), `6912#1108` (Carcassonne-II, avec
    Pennautier), `6912#1132` (Carcassonne-III) ; noms Carcassonne-I, II, III dès 1973 ;
  - le décret du 26 février 1997 dans la chronologie.
- **Déjà prêt** (écrit le 6 octobre 2026, ancres datées) :
  - `11069-1` : l'Aude, 1815 → 1973-09-23, Est / Ouest. DÉDUCTION du décret de 1973, confirmée
    par Adrien le 6 octobre 2026 ;
  - `11069-2`, `11069-3` : l'Aude et le contour de III, 1973-09-23 → 1985-03-10 ;
  - `11069-4`, `11069-5` : l'Aude et le contour de III après le décret 85-72, 1985-03-10 →
    1998-03-15 ;
  - `11069-6`, `11069-7`, `11069-8` : l'Aude, la voie ferrée de Toulouse, la limite II-Sud / III
    du décret de 1997, 1998-03-15 → 2013-01-01.

  Ancres : I `6912#1107` `POINT(649078 6234112)` ; II puis II-Nord `6912#1108`
  `POINT(647000 6236500)` ; III `6912#1132` `POINT(647300 6235000)` ; II-Sud `6912#1135`
  `POINT(643175 6234771)`. Le canton II de 1973-1998 est porté par `6912#1108`. De 1968 à 1973
  la découpe attend la correction du faux `6912#1109`.
- **À confirmer** (dit dans les notes) : l'île de 38,7 ha entre les deux bras de l'Aude, donnée
  à la rive droite ; la fermeture nord de la portion de 1985 par la voie ferrée (275 m) ; la
  bande de 0,9 ha entre le canal du Midi et l'avenue Pierre-Charles-Lespinasse, donnée à III en
  1998.

---

## Aubagne (13005)

### 92. Aubagne-Est et Aubagne-Ouest commencent en 2005 dans la base, en mars 2004 d'après le décret

- **Inscrit par `sql/114_villes_lot_2.sql` (13 octobre 2026)** : la bascule au 2004-03-21 pour la ville et les cinq communes d'Aubagne-Est (13 bornes). Reste : La Ciotat, la décision du Conseil d'État.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Source** : décret n° 2003-156 du 27 février 2003 (NOR INTA0300039D, JORF n° 50 du
  28 février 2003, texte n° 3, art. 2 et 4) ;
  https://www.legifrance.gouv.fr/jorf/id/JORFTEXT000000418871/. Il « prendra effet pour le
  prochain renouvellement des conseils généraux » : cantonales du 21 mars 2004. Texte absent du
  dépôt (`jorf_txt/`, `cantons/`).
- **Base** : fractions `1600#1305` (Aubagne-Ouest) et `1600#1354` (Aubagne-Est) à partir du
  **2005-01-01** (date COG) ; l'atome entier 1600 reste dans 1305 jusqu'au 2005-01-01. Même
  date 2005-01-01 pour l'entrée dans 1354 de Carnoux-en-Provence (N13119), Cassis (7049),
  Roquefort-la-Bédoule (29622), Cuges-les-Pins (11295) et Gémenos (15233).
- **À inscrire** : les deux fractions et les cinq communes d'Aubagne-Est à partir du
  **2004-03-21** (ou du 2003-02-28, date du JO, selon la convention retenue). Communes
  rurales d'après le décret : Est = Carnoux-en-Provence, Cassis, Cuges-les-Pins, Gémenos,
  Roquefort-la-Bédoule ; Ouest = La Penne-sur-Huveaune. Le même article réduit le canton de
  La Ciotat à La Ciotat et Ceyreste : vérifier sa date en base. Fin réelle des deux cantons :
  mars 2015 (base : 2013-01-01).
- **À vérifier** : une censure partielle du décret 2003-156 par le Conseil d'État est signalée
  (maire-info) ; la partie Aubagne / La Ciotat aurait été validée. Décision non lue.
- **Ligne** : `13005-1` écrite le 7 octobre 2026 (2004-03-21 → 2013-01-01, éprouvée au
  2005-01-01, conforme) ; ancres `1600#1305=ouest`, `1600#1354=est`. Bout sud hors texte,
  raccord au plus court sur Carnoux (arbitrage d'Adrien, 7 octobre 2026) : le plateau de
  Carpiagne est à l'Ouest. À réaligner si la date retenue est celle du JO.

---

## Arles (13004)

### 93. Port-Saint-Louis-du-Rhône et Saint-Martin-de-Crau ont un canton avant d'exister

- **Source** : ANR (`atom_geom_anr`) : 27686 Port-Saint-Louis à partir du 1904-01-01, 33313
  Saint-Martin-de-Crau à partir du 1925-01-01 ; loi du 15 novembre 1932 (canton de
  Port-Saint-Louis, `cantons/chronologie_cantonale.csv`).
- **Base** : `membership` met 27686 dans 1304 Arles-Ouest dès 1870-01-01 et 33313 dans 1303
  Arles-Est dès 1870-01-01, alors que leur sol est dans la cible d'Arles (102 985 ha avant 1904,
  97 247 ha de 1904 à 1925). Port-Saint-Louis sort d'Arles-Ouest au 1932-01-01 ; la loi est du
  15 novembre 1932.
- **À décider** : clore ces appartenances d'avant la création ; dater la sortie de
  Port-Saint-Louis du 1932-11-15.
- **Accord avec le texte** : les 5 704 ha d'Arles passés à Port-Saint-Louis sont tous à l'ouest
  du Vigueirat (canton Ouest de l'arrêté de l'an X), Saint-Martin tout à l'est.

### 94. Arles-Est et Arles-Ouest : trous 1941-1968 et 1973-1992

- **Inscrit par `sql/114_villes_lot_2.sql` (13 octobre 2026)** : les deux fractions sur 1941-1968 et 1973-1992. Reste : rien pour le n° 94.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Source** : arrêté du 17 frimaire an X (Bulletin des lois, 3e série, t. 5, n° 158,
  p. 209-213 ; Gallica, ark:/12148/bpt6k6515730s, vues 232-233) ; aucun texte postérieur trouvé
  (décrets 91-209 et 2003-156 sans Arles).
- **Base** : fractions `1256#1303` et `1256#1304` sur 1815-1941, 1968-1973-09-23 et
  1992-03-22-2013 (trou général). Après 1932, 1304 n'a que la fraction : de 1941 à 1968 et de
  1973 à 1992 le canton n'a aucun membre.
- **Ligne** : `13004-1` écrite le 7 octobre 2026 (1815-01-01 → 2013-01-01, source `texte`,
  conforme) ; elle vaut aussi dans les trous. Rue du Marché-Neuf prise pour la rue Gambetta
  (7,1 ha en jeu avec la rue du Président-Wilson) et canal de Craponne suivi hors texte de la
  rue au Vigueirat (56,7 ha en jeu) : « telle quelle », arbitrage d'Adrien du 7 octobre 2026.

## Hérouville-Saint-Clair (14327)

### 96. Les deux fractions de 1982 commencent en 1998 dans la base ; 1973-1982 est vide

- **Inscrit par `sql/114_villes_lot_2.sql` (13 octobre 2026)** : la ville entière dans 1440 (Caen-IV) de 1973 à 1982, les deux fractions de 1982 à 1998, les noms. Reste : le décret 82-132 dans `communes_coupees`.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Source** : décret n° 82-132 du 5 février 1982 (JO du 6 février 1982, p. 489-490,
  `sources/JORF/JORF_19820206_31.pdf`, déposé le 7 octobre 2026 ; pas encore dans `jorf_txt/`).
  Décret n° 73-763 du 2 août 1973 (`jorf_txt/JORF_19730804_180_col.txt`) : « Canton de Caen IV
  comprenant les communes d'Hérouville-Saint-Clair et de Mondeville ».
- **Base** :
  - `17048#1441` (Hérouville-Saint-Clair, Caen 5e canton) et `17048#1442` (Caen-Hérouville,
    Caen 6e canton) n'ont d'appartenance qu'à partir du **1998-03-15** ;
  - l'atome entier `17048` est dans 1408 Caen-Est jusqu'au 1973-09-23, puis dans rien ;
  - `cantons/mouvements_cantonaux.csv` (l. 219-220) date du 1973-08-02 le démembrement de 14327
    vers 1441 et 1442 : en 1973 la commune passe entière à Caen-IV, le partage est de 1982.
- **À inscrire** :
  - atome entier `17048` dans Caen-IV du 1973-09-23 à la date retenue pour 1982 ;
  - appartenances des deux fractions à partir de 1982 (JO 1982-02-06, ou 1982-03-14) ;
  - noms « Hérouville-Saint-Clair (Caen-V) » et « Caen-Hérouville (Caen-VI) » dès 1982.
- Le décret 82-132 est absent de `cantons/communes_coupees_1973_1984.csv` ; il porte aussi les
  limites des dix cantons de Caen (p. 489-490).
- **Ligne** : `14327-1` écrite le 7 octobre 2026 (1982-03-14 → 2013-01-01, source `texte`,
  conforme au 1998-03-15) ; ancres `17048#1441` = nord, `17048#1442` = sud. Texte collationné
  sur le JO. La bande entre le boulevard des Belles-Portes et la D515 (10,8 ha) va à Caen-VI.

## Chenôve (21166)

### 98. Le nom de Dijon-IV de 1973 à 1999

- **Inscrit par `sql/114_villes_lot_2.sql` (13 octobre 2026)** : le nom « Dijon-IV » pour 2112 de 1973 à 1999. Reste : I, II, III après vérification.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Source** : décret n° 73-813 du 16 août 1973 (JO du 17 août 1973,
  `jorf_txt/JORF_19730817_190_col.txt`, l. 1398-1405 et 1459-1468) : Dijon-I à Dijon-VIII,
  Chenôve et Fontaine-lès-Dijon remplacent Dijon-Est, -Nord, -Ouest et -Sud.
- **Base** : les appartenances sont justes (`9176#2112` et `9176#2138` depuis le 1973-09-23 ;
  Longvic, Marsannay-la-Côte, Neuilly-lès-Dijon, Ouges et Perrigny-lès-Dijon dans 2138 dès
  1973). Mais `unit_version` nomme 2112 « Dijon-Sud » de 1973 à 1999 (et 2109, 2110, 2111
  « Dijon-Est, -Nord, -Ouest ») au lieu de Dijon-IV (I, II, III) : nouveau cas de la règle du
  point 12. La correspondance 2109-2112 = Dijon-I à IV repose sur les noms de 1999 (« Dijon
  1er … 4e Canton ») ; elle n'a pas été vérifiée par les communes.
- **À inscrire** : le nom « Dijon-IV » pour 2112 à partir du 1973-09-23 (et I, II, III pour
  2109 à 2111, après vérification).
- **Ligne** : `21166-1` écrite le 7 octobre 2026 (1973-09-23 → 2013-01-01, source `texte`,
  conforme) ; ancres `9176#2112` = nord (65,4 ha), `9176#2138` = sud (680,3 ha). Le
  « boulevard du Nord » du décret est introuvable : pris pour le nord du boulevard Henri-Bazin.
- Les lignes de Dijon du régime 1973 (huit cantons, même décret, l. 1336-1457 du même fichier)
  sont tracées depuis le 18 octobre 2026 (`21231-1973-L1` à `L7`) ; la correspondance 2109-2111 =
  Dijon-I à III est vérifiée par les communes rurales (entrée 120).

## Beaune (21054)

### 100. Beaune-Nord est à l'ouest, Beaune-Sud à l'est ; ligne écrite sur une hypothèse

- **Source** : arrêté du 17 vendémiaire an X (Bulletin des lois, 3e série, n° 113, acte n° 919,
  p. 115 ; Gallica, ark:/12148/bpt6k6566479p, vue 135, non lue : captcha), lu par OCR dans
  Rondonneau, Collection générale des lois, p. 412-413 (archive.org `bub_gb_A25OAAAAYAAJ`). Il
  partage la ville par sections (Unité et Liberté au Nord, Fraternité et Égalité au Sud), sans
  nommer de voie.
- **Base** : fractions `3277#2105` (Beaune-Nord) et `3277#2106` (Beaune-Sud) sur 1815-1941 et
  1968-2013 ; rien entre 1941 et 1968 (trou général). Aloxe-Corton est bien au Nord en 1900 ;
  Bouilland et Échevronne (Nord d'après Wikipédia, absents de l'arrêté) n'ont pas été vérifiés.
- **À inscrire** : rien de propre à Beaune. Les ancres sont `ouest` / `est`, pas `nord` / `sud`.
- **Ligne** : `21054-1` écrite le 7 octobre 2026 (1815-01-01 → 2013-01-01, conforme), sur une
  HYPOTHÈSE : plan des sections de 1796 (Archives municipales de Beaune, trois sections
  seulement) dans les murs, déduction au-delà (2 170 m au nord, 2 786 m au sud) jusqu'aux
  points triples Savigny / Chorey et Pommard / Bligny.
- **À confirmer** : le texte sur l'original ; « Unité + Liberté (1801) = Liberté (1796) » ; le
  faubourg Saint-Nicolas (rangée ouest, environ 2 ha du mauvais côté ; variante IRIS : 83 ha) ;
  le tracé au sud de la Bouzaise (il coupe la rue du Faubourg Saint-Jacques). Pistes non
  consultées : Archives municipales ; Rossignol, « Histoire de Beaune » (1854).

---

## Caen (14118)

### 101. Caen de 1967 à 2013 : trois régimes tracés, un seul en base à ses dates

- **Inscrit par `sql/117_creations_caen_rochefort_bourg_larochelle.sql` (13 octobre 2026, accord d'Adrien)** : fraction `6530#1441` créée pour Caen-V de 1973 (unité 1441, nommée « Caen-V » de 1973 à 1982), ancre datée POINT(456000 6902400) ; `#1408`, `#1409`, `#1439`, `#1442` de 1973 à 1982 ; les neuf fractions de 1982 à 1998. Par `sql/116` : Est / Ouest de 1941 au 1967-09-24, puis les quatre cantons de 1967. Reste : les onze communes de banlieue de 1973 à 1998, Saint-Germain et Ifs avant 1973, le décret de 1998 dans la chronologie, Est / Ouest de 1815 à 1967 à tracer (texte).

- **Inscrit par `sql/115_villes_nomenclature.sql` (13 octobre 2026)** : Caen-Nord de 1967 : `6530#1439` de 1968 à 1973, ancre datée. Reste : tout le reste de l'entrée (1973-1998, Caen-V, communes de banlieue).
  Règle de nomenclature du 13 octobre 2026 (Adrien) : pas d'unité nouvelle, le canton disparu est porté par l'unité du régime suivant qui hérite de la plus grande part de son territoire dans la ville.

- **Sources** :
  - décret du 8 août 1967 (n° 67-668 d'après Wikipédia ; JO du 9 août 1967,
    `jorf_txt/JORF_19670809_184_col.txt`, l. 505-580) : Caen-Ouest, Nord, Est, Sud ;
  - décret n° 73-763 du 2 août 1973 (JO du 4 août 1973, p. 8533-8534,
    `jorf_txt/JORF_19730804_180_col.txt`, l. 2239-2298) : Caen-I à VI ;
  - décret n° 82-132 du 5 février 1982 (JO du 6 février 1982, p. 489-490,
    `sources/JORF/JORF_19820206_31.pdf` ; pas dans `jorf_txt/` ni dans
    `cantons/communes_coupees_1973_1984.csv`) : dix cantons ;
  - décret du 26 août 1998 (JO du 28 août 1998, `jorf_txt/JORF_19980828_198_col.txt`,
    l. 1600-1680) : l'axe du boulevard Georges-Pompidou devient la limite Caen-I / Caen-III
    (165 habitants de 1990 passent de III à I). **Absent de
    `cantons/chronologie_cantonale.csv`.**
- **Base** :
  - 1968-01-01 → 1973-09-23 : `6530#1408` (Est), `6530#1409` (Ouest), `6530#1440` (le Sud,
    sous le code du futur 4e canton). **Pas de fraction de Caen pour Caen-Nord** (unité 1439 :
    Authie, Épron, Saint-Contest), alors que c'est le plus grand morceau (1 071 ha).
    Saint-Germain-la-Blanche-Herbe (Nord) et Ifs (Sud) n'ont aucun canton de 1941/1955 à 1998 ;
    Rocquancourt est dans 1409 en 1970 (à vérifier).
  - 1973-09-23 → 1998-03-15 : **aucune fraction de Caen n'a de canton**, ni aucune des onze
    communes de banlieue (Bretteville-sur-Odon, Carpiquet, Louvigny, Authie, Saint-Germain,
    Saint-Contest, Épron, Mondeville, Fleury-sur-Orne, Ifs, Cormelles-le-Royal).
  - 1998-03-15 → 2013 : les neuf fractions, justes (attribution vérifiée par les communes
    rurales : 1408 = I, 1409 = II, 1439 = III, 1440 = IV, 1442 = VI, 1443 = VII, 1444 = VIII,
    1445 = IX, 1446 = X). `unit_version` nomme encore 1408 « Caen-Est » et 1409 « Caen-Ouest »
    du 1998-03-15 au 1999-01-01.
  - `cantons/mouvements_cantonaux.csv` l. 216-224 date du 1973-08-02 des partages de Caen vers
    1439, 1440, 1442 qui mêlent 1973 et 1982 ; l. 208-209 et 215 : trois « transferts isolés
    1940-1999 » (Saint-Contest, Bretteville-sur-Odon, Carpiquet) qui sont les décrets de 1967,
    1973 et 1982.
- **À inscrire** :
  - 1967-1973 : fraction `6530#1439` (Caen-Nord) ; Saint-Germain-la-Blanche-Herbe dans le Nord,
    Ifs dans le Sud ; noms Caen-Ouest, Caen-Nord, Caen-Est, Caen-Sud ;
  - 1973-09-23 → 1982-03-14 : Caen-I (`6530#1408` + Carpiquet, Bretteville-sur-Odon, Louvigny),
    Caen-II (`6530#1409` + Authie, Saint-Germain-la-Blanche-Herbe), Caen-III (`6530#1439` +
    Saint-Contest, Épron), Caen-IV (Hérouville-Saint-Clair entière, Mondeville ; rien de Caen),
    Caen-V (**fraction `6530#1441` à créer**, rien que de la ville, 404 ha), Caen-VI
    (`6530#1442` + Fleury-sur-Orne, Ifs, Cormelles-le-Royal) ;
  - 1982-03-14 → 1998-03-15 : les neuf fractions et les communes du décret 82-132 (I :
    Bretteville-sur-Odon ; II : Carpiquet, Saint-Germain, Authie, Saint-Contest ; IV : Épron ;
    VII : Mondeville ; VIII : Louvigny, Fleury-sur-Orne ; X : Cormelles-le-Royal, Ifs) ;
  - le décret du 26 août 1998 dans la chronologie.
- **Lignes** (écrites le 9 octobre 2026, CONFORME) :
  - `14118-1` à `-4` (1967-09-24 → 1973-09-23), `--morceaux 4 --vides-admis 1` ; ancres datées
    `6530#1409` = POINT(452500 6902300), `6530#1408` = POINT(455800 6903000), `6530#1440` =
    POINT(455000 6901300) ; Caen-Nord sans ancre : POINT(453800 6905000) ;
  - `14118-5` à `-9` (1973-09-23 → 1982-03-14), `--morceaux 5 --vides-admis 1` ; ancres datées
    `6530#1408` = POINT(452500 6902300), `6530#1409` = POINT(453000 6904500), `6530#1439` =
    POINT(455300 6905500), `6530#1442` = POINT(455000 6901300) ; Caen-V sans ancre :
    POINT(456000 6902400) ;
  - `14118-10` à `-19` (1982-03-14 → 2013-01-01), conforme au 1998-03-15, neuf ancres datées.
- **Reste à tracer** : Caen-Est / Caen-Ouest de 1815 à 1967 (base : 1815 → 1941, puis rien
  jusqu'en 1968). Ordonnance n° 492 du 30 décembre 1815, Bulletin des lois 1816, 1er semestre,
  p. 295 (Gallica, ark:/12148/bpt6k4861182/f331 ; page donnée par Adrien le 9 octobre 2026) : le
  Bulletin n'imprime que l'intitulé — elle « supprime la division de la ville de Caen […] en
  deux arrondissemens de justice de paix sous les dénominations de Nord et de Sud, prononcée par
  l'arrêté du 6 brumaire an X », et la divise « en deux arrondissemens dits de l'Est et de
  l'Ouest ». Aucune limite décrite : il faut Gaudillère ou le dispositif. La base fait commencer
  Caen-Est et Caen-Ouest au 1815-01-01 : jusqu'au 30 décembre 1815 le régime était Nord / Sud. Avant le 5 juin 1952 la cible est sans Venoix (2 260 ha ; atome `39306`, dans 1409).

### Lisieux — complément à l'entrée 5

- La page Wikipédia « Liste des cantons du Calvados » donne la réponse : décret n° 85-144 du
  31 janvier 1985 **annulé par le Conseil d'État, arrêt du 23 octobre 1985, n° 66.608** ; le
  3e canton date donc du décret n° 91-210 du 27 février 1991. À vérifier sur ArianeWeb.

---

## Nice (06088)

### 102. Nice de 1973 à 1998 : vingt-cinq ans sans canton, et les cantons 5 et 6 de 1955 absents

- **Inscrit par `sql/114_villes_lot_2.sql` (13 octobre 2026)** : les onze fractions de 1973 à 1982, les quatorze de 1982 à 1998 ; Falicon, Saint-André, La Trinité dans 0637 de 1973 à 1982. `98` dit « ligne qui ne ferme pas » en 1973 : les cantons I à III n'ont pas de limite tracée, les huit autres se tirent (6 315 ha). Reste : 1955-1973, 1919-1941 à confronter au JO.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Sources** :
  - décret n° 73-811 du 16 août 1973 (JO du 17 août 1973, p. 8916-8917 ;
    `jorf_txt/JORF_19730817_190_col.txt`), art. 1er : « en remplacement des 4e, 5e et 6e cantons
    de Nice », Nice-IV à Nice-XI ; Nice-VII comprend Falicon, Saint-André et La Trinité ;
  - décret n° 82-79 du 25 janvier 1982 (JO du 26 janvier 1982, p. 373-374 ;
    `jorf_txt/JORF_19820126_21_col.txt`), art. 3 : Nice-I, II, III, VII, IX, X redéfinis, création
    de Nice-XII, XIII (Falicon, Saint-André, La Trinité, l'Ariane) et XIV ;
  - décret n° 85-143 du 31 janvier 1985 (JO du 1er février 1985, p. 1378 ;
    `jorf_txt/JORF_19850201_27_col.txt`), art. 1er et 2 : nouvelles limites de Nice-I, II, III ;
    l'est de l'avenue Sainte-Marguerite passe de Nice-XIV à Nice-X ;
  - décret du 19 janvier 1955 (JO du 21 janvier 1955, p. 807) : six cantons — NON LU (Légifrance
    refuse la lecture automatique) ; loi du 7 février 1919 (JO du 9 février 1919, p. 1498 ;
    https://gallica.bnf.fr/ark:/12148/bpt6k6361179m/f2.item) — NON LUE (Gallica) ; décret impérial
    n° 8364 du 24 octobre 1860 (Bulletin des lois, 11e série, t. XVI, p. 960) — non lu.
- **Base** :
  - aucune fraction de Nice n'a de canton du 1973-09-23 au 1998-03-15 ; rien non plus de 1941 à
    1968 ;
  - Nice-5 et Nice-6 (1955) : aucune fraction de Nice de 1955 à 1973. L'unité 0632 existe de 1968
    à 1973, avec La Trinité, Saint-André-de-la-Roche et **Gourdon** (canton du Bar : à vérifier),
    sans fraction de la ville ; Falicon n'a aucun canton de 1955 à 1973 ;
  - Falicon, La Trinité et Saint-André sont sous 0643 (Nice-13) dès le 1973-09-23 : de 1973 à
    1982 le décret les met dans Nice-VII (0637) ; Nice-XIII n'est créé qu'en 1982 ;
  - `24984#0614` s'appelle « Nice-Est » de 1919 à 1941, de 1968 à 1973 et en 1998 : c'est Nice-1 ;
  - La Trinité est sous 0615 (« Nice-Ouest ») de 1860 à 1919 : à vérifier sur le décret de 1860.
- **À inscrire** :
  - de 1973-09-23 à 1982-03-14 : fractions #0617, #0632, #0633, #0637 à #0641 (Nice-IV à XI),
    et #0614 à #0616 (limites de 1955, non tracées) ; Falicon, Saint-André, La Trinité dans 0637 ;
  - de 1982-03-14 à 1998-03-15 : les quatorze fractions ; les trois communes dans 0643 ;
  - de 1955 à 1973 : Nice-5 et Nice-6 dans la ville, quand le décret de 1955 sera lu.
- **Tracé** (écrit le 9 octobre 2026 ; lignes communes répétées sous un identifiant par régime) :
  - `06088-1985-*` (22 lignes, 1985-03-10 → 2013) : CONFORME au 2000-01-01, 14 fractions ancrées ;
  - `06088-1982-*` (21 lignes, 1982-03-14 → 1985-03-10) : `--morceaux 14`, 14 ancres datées ;
  - `06088-1973-*` (14 lignes, 1973-09-23 → 1982-03-14) : `--morceaux 9 --vides-admis 1`, 8
    ancres ; les cantons 1, 2, 3 de 1955 restent soudés (1 064,5 ha), sans ancre ;
  - attribution fraction / canton d'après les noms de la base (« Nice 5e Canton » = 0632…) ;
    les communes de banlieue ne confirment que le XIII (0643) ;
  - lignes tracées par un plus court chemin PostGIS écrit pour Nice (hors dépôt), `trace_mixte()`
    rendant des lignes non simples ; rapport de chaque ligne dans sa note.
- **Tracé mais NON écrit** : 1919-1941 (5 lignes, conforme à blanc au 1930-01-01, Nice-1 56,7 ha,
  Nice-2 869,4, Nice-3 1 160,0, Nice-4 5 293,5). Le texte vient des pages Wikipédia « Canton de
  Nice-1 » à « -4 », pas du JO : à confronter au JO du 9 février 1919 avant d'écrire.
- **À vérifier sur les plans des décrets** : le partage parc Liserb (VI) / Liserb supérieur (VII)
  à Cimiez, une trentaine d'hectares ; la part de Nice dans Nice-XIII, dont le texte ne donne
  aucune limite (257,7 ha : l'Ariane, l'hôpital Sainte-Marie, la bande route de Levens – Paillon) ;
  la limite sud de Nice-VI (voie ferrée selon 1973, retenu ; boulevard Raimbaldi et bas de
  l'avenue des Arènes à Nice-III selon le texte de 1982 recopié de 1955) ; l'avenue du
  Petit-Piol, introuvable (248 m en ligne droite, environ 3 ha).
- **Reste à tracer** : 1860-1919 (Est / Ouest) et 1955-1973 (six cantons), faute de texte.

---

## Fait

## Falaise (14258)

### 97. FAIT (10 octobre 2026, `sql/108`) — Falaise-Nord et Falaise-Sud étaient intervertis de 1815 à 1941 ; ligne écrite sur des indications de paroisses

- **Inscrit par `sql/108_villes_aurillac_falaise_saintflour.sql`** : les 33 communes rurales échangent 1417 et 1418 sur 1815-1941 (66 lignes) ; les deux fractions gardent leur code (`13442#1417` dans 1417, le vrai Nord) et reçoivent 1941 → 1968 et 1973-09-23 → 1998-03-15. La ligne est désormais unique, `14258-1`, de 1815 à 2013, ancres non datées : `#1417` POINT(465870 6871680) (Saint-Laurent, coin nord-est), `#1418` POINT(466200 6870560) (Guibray).
- **Reste** : les deux faux transferts de `cantons/mouvements_cantonaux.csv` (l. 211-212) disparaîtront en rejouant `33` puis `72` ; 1941-1954 pour les 33 communes rurales viendra de `93` et `97` rejoués, qui s'arrêtaient sur le désaccord des deux bouts ; les questions de tracé ci-dessous (variante A, Frenaye, Ante, collation de Galeron et Langevin) restent ouvertes.

Ce qui suit est l'entrée telle qu'elle était avant l'inscription.

- **Source** : arrêté du 6 brumaire an X (Bulletin des lois, 3e série, t. 4, n° 129, acte
  n° 986 ; Gallica, ark:/12148/bpt6k6566479p, vues 348-349 ; lu en OCR, à relire sur l'image) :
  1re partie = « sections de la Révolution et de Guibray » + Damblainville, Eraines,
  Fresné-la-Mère, La Hoguette, Ners, Perteville, Versainville, Villy ; 2e partie = « section de
  la Liberté » + Aubigny, Potigny, Soulangy… Conseil général, 28 août 1856 (Gallica,
  ark:/12148/bpt6k5715263q, vue 274) et décret du 27 novembre 1859 : 1re = Sud, 2e = Nord.
- **Base** : de 1815 à 1941, l'unité 1417 « Falaise-Nord » a les 8 communes de la 1re partie (le
  Sud) et 1418 « Falaise-Sud » les 27 de la 2e (le Nord) ; à partir de 1968 la base est juste
  (1417 = 27 communes). `cantons/mouvements_cantonaux.csv` l. 211-212 en fait deux transferts
  1940-1999 qui n'ont pas eu lieu. Fractions `13442#1417` et `13442#1418` sur 1815-1941,
  1968-1973-09-23 et 1998-03-15-2013.
- **À inscrire** : échanger 1417 et 1418 dans `membership` sur 1815-1941, pour les communes et
  pour les deux fractions ; retirer les deux faux transferts ; appartenances des deux fractions
  sur 1941-1968 et 1973-09-23 → 1998-03-15 (régime continu de 1801 à 2015, aucun acte connu).
- **Ligne Nord / Sud : écrite le 10 octobre 2026, à confirmer** (`14258-1`, 1815 → 2013, source `main` ; d'abord en deux lignes
  à ancres datées, réunies après `sql/108`). L'arrêté ne décrit pas les sections,
  mais Langevin (Recherches historiques sur Falaise, 1814, p. 191-192) et Galeron (Statistique
  de l'arrondissement de Falaise, t. 1, 1826, p. 309-312 ; archive.org
  `statistiquedela00desngoog`, Gallica ark:/12148/bpt6k57889311 ; **lus en OCR, à collationner
  sur l'image, pages comprises**) donnent les paroisses : 1re division (Sud) = la Trinité « à
  l'exception de tout le côté droit de la route de Caen » et Guibray « moins le quartier de la
  Frenaye », plus « une vingtaine de maisons » de Saint-Gervais (Grand'rue, rue du Campferme) ;
  2e division (Nord) = Saint-Gervais et Saint-Laurent. **Le partage n'est donc pas est / ouest**,
  comme cette entrée le disait : le Nord est le coin nord-est de la commune (324,8 ha), le Sud
  le reste (855,3 ha), et le Sud touche Noron, Saint-Martin-de-Mieux, Saint-Pierre-du-Bû et
  Aubigny, disposition que Galeron critique (p. 311-312). Les points triples
  Versainville / Aubigny et La Hoguette / Saint-Pierre-du-Bû ne sont pas des bouts de la ligne.
- **Tracé** : D658 (route de Caen depuis le point où elle quitte la limite d'Aubigny, avenue
  d'Hastings, rue de Caen) ; dans les murs, limite de paroisse prise à la lettre, Poissonnerie
  supposée aux Halles (rue du Camp-Ferme, rue de Nyon, rue des Halles, pied du rempart sud) ;
  rue Georges-Clemenceau jusqu'au square Louis-Liard ; côté est du parc de la Fresnaye ; l'Ante
  jusqu'à la limite Versainville / Eraines.
- **Variante A non retenue** : dans les murs, l'axe de la route royale (rue de Caen, place du
  Docteur-Paul-German, rue Georges-Clemenceau) : Nord 320,4 ha, Sud 859,7 ha, soit 4,4 ha et
  220 logements de moins au Nord. Elle colle mieux à la population de 2012 (INSEE : fraction
  Nord 987 habitants, Sud 7 426, soit 11,7 % ; logements BD TOPO au Nord : 17,1 % pour A, 22,2 %
  pour la ligne écrite), mais donne au Sud dix fois la « vingtaine de maisons » de Galeron. La
  ville close a été rebâtie après 1944 : aucun des deux contrôles n'est décisif. Géométrie de A
  gardée dans `cartes/sorties/decoupe_falaise/hypA.wkt`.
- **Déductions à confirmer** : la borne est de la Frenaye (le texte dit « près de quatorze
  hectares », le parc BD TOPO en fait 21,6 : 7 ha d'incertitude ; la Ferme de la Vallée reste au
  Sud) ; l'Ante sur 760 m jusqu'au bord ; la validité de la limite de 1826 jusqu'en 2013 (aucun
  acte connu). À voir : cadastre napoléonien de Falaise (AD Calvados, 3 P, sections de la
  ville), délibération municipale de 1790 (AD 14, série L), plan de Gaudillère s'il existe.
- **Ancres datées, à reprendre quand l'inversion sera corrigée** : Sud POINT(466200 6870560)
  (Notre-Dame de Guibray) = `13442#1417` avant 1941, `13442#1418` ensuite ; Nord
  POINT(465870 6871680) (Saint-Laurent) = `#1418` avant 1941, `#1417` ensuite. Après correction :
  une seule ligne 1815-2013, `#1417` au nord-est, `#1418` au sud, ancres non datées.
- Aucun acte en 1973 ni en 1998 (contrôlé dans `cantons/`) : les trous 1941-1968 et
  1973-09-23 → 1998-03-15 des fractions sont des trous de la base.

## Aurillac (15014)

### 103. FAIT (10 octobre 2026, `sql/108`) — Aurillac de 1973 à 1985 : quatre cantons sans fraction, et des communes rurales sous le code du canton suivant

- **Inscrit par `sql/108`** : points 1 à 6 ci-dessous. Fractions Nord / Sud sur 1941 → 1973-09-23 (l'atome entier quitte Aurillac-Nord en 1968-1973), quatre fractions sur 1973-09-23 → 1985-03-10 ; Crandelles, Jussac, Naucelles, Teissières-de-Cornet passent de 1527 à 1502 jusqu'en 1985 ; Arpajon, Labrousse, Prunet, Vézac, Vezels-Roussy de 1526 à 1524 jusqu'en 1982 ; Reilhac (atome 28822, fondue dans Naucelles-Reilhac) posée dans 1502 de 1973 à 1985 ; noms de 1973, 1982 et 1985 dans `unit_version`. Les lignes `15014-1` à `-6` se tirent maintenant sur des fractions qui ont un canton.
- **Reste** : les trois points « À confirmer » en fin d'entrée (avenue de Tronquières, rue de Marmiesse, place Malhard).

Ce qui suit est l'entrée telle qu'elle était avant l'inscription.

- **Sources** : décret n° 73-716 du 23 juillet 1973 (JO du 25 juillet 1973, p. 8078-8079,
  `jorf_txt/JORF_19730725_171_col.txt`, l. 1062-1105) : Aurillac-I à IV ; décret n° 82-51 du
  20 janvier 1982 (`jorf_txt/JORF_19820122_18_col.txt`, l. 189-226) : I-Nord, II-Ouest, III-Sud,
  Arpajon-sur-Cère ; décret n° 85-73 du 22 janvier 1985 (`jorf_txt/JORF_19850123_19_col.txt`,
  l. 3363-3424) : Jussac, Aurillac-I à IV. Le canton IV n'est redécrit ni en 1982 ni en 1985.
- **Base** : fractions `1915#1502` (Nord) et `1915#1503` (Sud) de 1815 à 1941 ; rien de 1941 à
  1968 ; atome entier 1915 dans Aurillac-Nord (1502) de 1968 au 1973-09-23 ; **aucune
  appartenance cantonale d'Aurillac du 1973-09-23 au 1985-03-10** ; quatre fractions `#1502`,
  `#1503`, `#1524`, `#1525` du 1985-03-10 à 2013. `unit_version` nomme encore 1502
  « Aurillac-Nord » et 1503 « Aurillac-Sud » de 1985 à 1999 ; 1524 et 1525 n'ont pas de version
  avant 1999.
- **À inscrire** :
  1. les fractions `1915#1502` (I), `#1503` (II), `#1524` (III), `#1525` (IV) du 1973-09-23 au
     1985-03-10 (les limites changent au 1982-03-14, pas les fractions) ;
  2. Crandelles, Jussac, Naucelles, Teissières-de-Cornet : sous 1527 (Jussac) dès le 1973-09-23,
     alors que Jussac n'est créé qu'en 1985 ; elles sont d'Aurillac-I (1502) de 1973 à 1985 ;
  3. Arpajon-sur-Cère, Labrousse, Prunet, Vézac, Vezels-Roussy : sous 1526 (Arpajon-sur-Cère)
     dès 1973, alors que ce canton date de 1982 ; elles sont d'Aurillac-III (1524) du 1973-09-23
     au 1982-03-14 ;
  4. Reilhac : dans aucun des cantons 1502, 1503, 1524 à 1527 entre 1973 et 1985 (le décret dit
     « Naucelles-Reilhac ») : à vérifier ;
  5. les noms : Aurillac-I à IV en 1973 ; I-Nord, II-Ouest, III-Sud en 1982 ; I à IV en 1985 ;
  6. 1941-1973 : fractions Nord / Sud en continu (régime de l'an X jusqu'au décret de 1973),
     à la place de l'atome entier au Nord en 1968-1973.
- **Lignes** (écrites le 10 octobre 2026, ancres datées, les mêmes points pour 1973, 1982 et
  1985 : `#1502` POINT(655300 6426200), `#1503` POINT(654300 6422900), `#1524`
  POINT(655950 6424500), `#1525` POINT(657400 6426700)) :
  - `15014-0`, 1815 → 1973-09-23 : limite Nord / Sud. Arrêté du 27 vendémiaire an X (Bulletin
    des lois, an X, n° 935 ; lu sur l'image par Adrien) : « partira du Palais-de-Justice,
    passera par la rue des Droits-de-l'Homme, la place, les rues des Pâtissiers, Forgerons, du
    Salut, du Rieux et la place Malhard ». Géométrie du canton IV de 1973 : mêmes communes
    rurales, et trois rues retrouvées (Salut, Forgerons, Rieu) sur la ligne ou à son contact ;
    cinq repères introuvables ; hors de la vieille ville, déduction. Ancres `#1502`
    POINT(657400 6426700), `#1503` POINT(654300 6422900). Nord 1 172,1 ha, Sud 1 747,3 ha ;
  - `15014-1` à `-3`, 1973-09-23 → 1982-03-14 (`--morceaux 4`) : I 250,5 ha, II 1 062,5,
    III 434,3, IV 1 172,1 ; **ne tirent rien tant que le point 1 n'est pas inscrit** ;
  - `15014-4` à `-6`, 1982-03-14 → 1985-03-10 (`--morceaux 4`) : I 245,3 ha, II 863,9, III 638,2,
    IV 1 172,1 ; même réserve ;
  - `15014-7` à `-9`, 1985-03-10 → 2013 : I 928,4 ha, II 333,7, III 485,1, IV 1 172,1 ; conforme
    à la base, et les contacts sont ceux que le décret nomme.
- **À confirmer** : la fin de la limite II / III de 1982. Le texte s'arrête à « avenue de
  Tronquières » sans « jusqu'à la limite de la commune » ; la ligne est prolongée dans l'axe sur
  1 306 m. L'autre lecture (arrêt au bout de l'avenue, raccord de 289 m vers l'est) donnerait
  37,9 ha de plus au II, sans habitation ; sa géométrie est dans
  `cartes/sorties/decoupe_aurillac/15014-6_variante_texte.wkt`. Seul le plan annexé au décret
  82-51 trancherait. À confirmer aussi : la rue de Marmiesse de 1973 prolongée par le chemin du
  Bousquet (993 m) ; le « chemin du cimetière » pris sur la D453 ; la place Malhard et le
  Palais-de-Justice de 1801, si quelqu'un sait où ils étaient.

## Saint-Flour (15187)

### 104. FAIT (10 octobre 2026, `sql/108`) — Saint-Flour-Nord et Saint-Flour-Sud : deux fractions en continu de l'an X à 2015

- **Inscrit par `sql/108`** : les deux fractions sur 1941 → 1985-03-10 ; l'atome entier 31781 quitte Saint-Flour-Nord sur 1968 → 1973-09-23.
- **Reste** : la divergence Légifrance / Wikipédia sur le décret de 2014, et un texte ancien qui bornerait le Faubourg et la Ville.

Ce qui suit est l'entrée telle qu'elle était avant l'inscription.

- **Sources** : arrêté du 27 vendémiaire an X (Bulletin des lois, an X, 1er semestre, n° 935,
  p. 209 et suiv., Gallica ark:/12148/bpt6k6566479p/f229 ; lu sur l'image par Adrien) : « Le
  premier, dit du Nord, comprendra le territoire proprement appelé Faubourg de Saint-Flour. […]
  Le deuxième, dit du Sud, comprendra le territoire proprement appelé la Ville de Saint-Flour. »
  `cantons/chronologie_cantonale.csv` : aucun acte sur Saint-Flour entre 1801 et 2014. INSEE,
  populations légales du Cantal : fractions Saint-Flour-Nord et -Sud publiées jusqu'au
  1er janvier 2014.
- **Base** : `31781#1519` (Nord) et `31781#1520` (Sud) de 1815 à 1941 et du 1985-03-10 à 2013 ;
  atome entier 31781 dans Saint-Flour-Nord de 1968 au 1973-09-23 ; aucun canton pour la ville de
  1941 à 1968 ni du 1973-09-23 au 1985-03-10.
- **À inscrire** : les deux fractions en continu de 1815 à 2013. La date du 1985-03-10 n'a
  aucun décret derrière elle pour Saint-Flour, et l'atome entier au Nord en 1968-1973 est un
  artefact du COG (une commune, un code canton).
- **Ligne** : `15187-1`, 1815 → 2013, source `iris`, écrite le 10 octobre 2026 ; ancres non
  datées `31781#1519` POINT(707634 6436193), `31781#1520` POINT(704182 6436639). L'attribution
  vient du texte (faubourg au Nord, ville haute au Sud) ; le tracé est la limite des deux IRIS
  INSEE « Nord » et « Sud » (38,4 % de la population au Nord pour les IRIS de 2012-2013 comme
  pour les fractions cantonales de 2011, sans millésime commun). Nord 1 663,7 ha, Sud
  1 041,1 ha. Le partage du territoire rural ne vient que des IRIS : hypothèse avant 1999.
- **À part** : pour le décret n° 2014-149 (Saint-Flour-1 et -2, 2015), Légifrance met
  Saint-Flour-1 « à l'ouest » de la ligne et Wikipédia « à l'est » : à corriger d'un côté ou de
  l'autre. Sa ligne, tracée pour comparaison, diffère de la limite IRIS de 81 ha
  (`cartes/sorties/decoupe_saintflour/h2014.wkt`).

## Angoulême (16015)

### 77. FAIT (10 octobre 2026, `sql/109`) — Angoulême de 1941 à 1982 : les deux fractions absentes, l'atome entier dans Angoulême-2 en 1968-1973

- **Inscrit par `sql/109_ville_angouleme.sql`** : `853#1602` et `853#1603` sur 1941 → 1982-03-14 (l'atome entier quitte 1603 en 1968-1973) ; noms Angoulême-Ville-I et -Ville-II de 1973 à 1982, Angoulême-Est (1602), -Nord (1603) et -Ouest (1634) dès le 1982-03-14. La ligne `16015-1` (1876-1982) se tire maintenant jusqu'en 1982.
- **Régime de 1982 tracé le même jour** (décret n° 82-25, `jorf_txt/JORF_19820116_13_col.txt`, l. 938-990), ancres datées 1982-03-14 → 2013 : `16015-2` Nord / Ouest (la Charente, son bras sud jusqu'au pont de Saint-Cybard, avenue de Cognac, rues Léonard-Jarraud et de la Corderie), `16015-3` Ouest / Est (rues de Montmoreau, de la Quintinie, de Clérac à Sillac, Pierre-Grenet, voie de l'Europe, puis une droite de 916 m jusqu'au carrefour du boulevard de Bigorre et de la rue du Petit-Montbron, et 133 m jusqu'au bord), `16015-4` Nord / Est (avenue Gambetta, boulevards de la République, René-Chabasse, Liédot, Chanzy). Ouest 1 038,8 ha, `#1634` POINT(476911 6509218) ; Est 648,4 ha, `#1602` POINT(479300 6508700) ; Nord 483,8 ha, `#1603` POINT(479658 6510400). Populations estimées 15 371, 12 666 et 13 973 pour 14 917, 12 869 et 13 990 à l'INSEE (fractions cantonales, 2011).
- **Reste** : (a) « le prolongement de la rue Pierre-Grenet jusqu'à la limite » est lu par le décret n° 2014-195 du 20 février 2014 (Légifrance, JORFTEXT000028638343, art. 2 : « ligne droite dans le prolongement de la rue Pierre-Grenet jusqu'à l'intersection du boulevard de Bigorre et de la rue du Petit-Montbron, chemin des Eaux-Claires au pont Valto ») : un texte d'un autre régime, qui diffère en amont ; les deux autres lectures (droite dans l'axe de la rue, 34 ha vides de moins à l'Ouest ; voie de l'Europe vers le sud, `cartes/sorties/decoupe_angouleme/B_sud.wkt`, 58 ha de plus et 700 habitants d'écart avec l'INSEE) sont dans la note ; le plan annexé au décret de 1982 trancherait ; (b) « l'Anguienne depuis son embouchure jusqu'au pont de Saint-Cybard » prise pour le bras sud de la Charente ; (c) **1815-1876 reste sans coupe** : il faut le texte d'avant 1876 (arrêté de l'an X, décret du 16 mai 1863 « Fix. limites Angoulême-1 et 2 », ou Gaudillère) ; (d) le sens de la Charente et l'attribution 1er / 2e de la ligne `16015-1`, toujours déduits.

Ce qui suit est l'entrée telle qu'elle était avant l'inscription.

- **Sources** :
  - Gaudillère, extrait donné par Adrien le 4 octobre 2026 (1876-1919) : « charente, pont
    saint-cybard, avenue de cognac, rues L.Jarraud, de la corderie, montmoreau, avenue de navarre » ;
  - `cantons/chronologie_cantonale.csv` : 16 mai 1863, « Fix. limites Angoulême-1 et 2 » ;
  - décret n° 73-654 du 13 juillet 1973 (JO du 17 juillet 1973, `jorf_txt/JORF_19730717_164.txt`) :
    Angoulême-Ville-I et Angoulême-Ville-II = « la portion de territoire de la ville d'Angoulême
    comprise dans l'ancien premier (deuxième) canton » ; les communes rurales vont à La Couronne,
    Ruelle et Soyaux ;
  - décret n° 82-25 du 15 janvier 1982 (JO du 16 janvier 1982, `jorf_txt/JORF_19820116_13_col.txt`) :
    Angoulême-Nord, Est et Ouest.
- **Base** :
  - 1870-1941 : `853#1602` Angoulême-1, `853#1603` Angoulême-2 ;
  - 1941-1968 : rien ;
  - 1968-1973 : **l'atome entier `853` dans 1603 (Angoulême-2)** ;
  - 1973-1982 : rien (Angoulême-Ville-I et Ville-II absents) ;
  - à partir du 14 mars 1982 : `#1602`, `#1603`, `#1634`, nommés Angoulême-1 et 2 jusqu'en 1999
    (`unit_version` n'a « Angoulême-Est », « Nord » et « Ouest » qu'à partir de 1999).
- **À inscrire** :
  - les deux fractions `853#1602` et `853#1603` de 1941 à 1973, à la place de l'atome entier ;
  - de 1973 à 1982, les deux mêmes parts de ville sous Angoulême-Ville-I et Ville-II (même limite) ;
  - les noms Angoulême-Est, Nord et Ouest dès le 14 mars 1982.
- **Tracé** :
  - `16015-1` : la Charente en aval du pont Saint-Cybard, puis avenue de Cognac, rues
    Léonard-Jarraud, de la Corderie, de Montmoreau, avenue de Navarre ; du 1er janvier 1876 au
    14 mars 1982 ; ancres datées `853#1602` POINT(476911 6509218), 1 287,6 ha, et `853#1603`
    POINT(479658 6509101), 883,4 ha. Elles joueront en 1941-1982 quand les appartenances seront
    inscrites.
  - Sens de la Charente (aval) et prolongement au-delà de 1919 : déductions, à confirmer par
    Adrien ; 1870-1876 reste sans coupe.
  - Reste à tracer : les limites du décret 82-25 (1982-2013).

## Oyonnax (01283)

### 3. FAIT (11 octobre 2026, `sql/112`) — Oyonnax-Nord et Oyonnax-Sud commencent en 1998 dans la base, en 1982 dans le JO

- **Inscrit par `sql/112_villes_date_du_decret.sql`** : la ville entière dans 0123 du 1973-09-23 au 1982-03-14, puis `25988#0123` et `25988#0141` jusqu'au 1998-03-15 ; Bellignat, Groissiat, Martignat et Géovreisset dans 0123 puis 0141 aux mêmes dates. Date retenue : 1982-03-14, celle des communes rurales du canton et de la ligne `01283-1` (tirée au 1990-01-01 : Nord 1 761 ha, Sud 1 845 ha).
- **Reste** : le JO écrit « Géovreissiat » (01170, canton de Nantua) ; c'est Géovreisset (01171, limitrophe d'Oyonnax) que le COG met dans Oyonnax-Sud, et c'est elle qui est inscrite — à confirmer sur un rectificatif ; la date 1984-12-24 de la chronologie cantonale reste sans texte.

Ce qui suit est l'entrée telle qu'elle était avant l'inscription.

- **Source** : décret n° 82-77 du 25 janvier 1982 (JO du 26 janvier 1982, art. 2).
- **Base** : fractions `25988#0123` (Nord) et `25988#0141` (Sud) à partir du **1998-03-15**.
  L'atome entier 25988 est dans 0123 jusqu'au 1973-09-23, puis dans rien. La chronologie
  cantonale (`cantons/chronologie_cantonale.csv`) donne une troisième date : 1984-12-24.
- **À inscrire** :
  - 25988 dans 0123 (Oyonnax, non divisé) de 1973-09-23 à 1982-01-26 ;
  - les deux fractions de **1982-01-26** à 1998-03-15 ;
  - communes rurales : Nord = Dortan, Arbent, Belleydoux, Échallon ; Sud = Martignat,
    Groissiat, Bellignat, Géovreissiat.
- **Ligne** : `01283-1` vaut depuis le 1982-03-14. Si l'inscription retient le 1982-01-26, avancer
  la ligne à la même date (comme Bourg), pour que les deux régimes s'enchaînent.
- **Noté, sans suite** : le décret du 17 décembre 1996 (JO du 24 décembre 1996) échange
  2 a 7 ca et 1 a 60 ca entre Oyonnax et Arbent.

## Troyes (10387)

### 8. FAIT (11 octobre 2026, `sql/112`) — Les sept cantons de 1973 n'ont pas de fraction de Troyes avant 1988

- **Inscrit par `sql/112_villes_date_du_decret.sql`** : les sept fractions du 1973-09-23 au 1988-09-25 ; communes lues au décret 73-652 : Saint-Parres-aux-Tertres (1022), Villeloup (1029), Laines-aux-Bois, Saint-André-les-Vergers, Saint-Germain (1031), Bréviandes, Saint-Julien-les-Villas, Rosières (1032). Tirée au 1980-01-01 : sept morceaux, 1 329,1 ha.
- **Reste** : les trois fractions de 1941 à 1968 ; la chronologie (1985 pour 1973) ; la cible d'avant 1856 ; l'échange de 1986 dans l'ANR ; les deux points à vérifier sur le plan.

Ce qui suit est l'entrée telle qu'elle était avant l'inscription.

- **Source** : décret n° 73-652 du 13 juillet 1973 (JO du 17 juillet 1973, p. 7702-7703), art. 1er à 3 ;
  `jorf_txt/JORF_19730717_164_col.txt` ; `cantons/communes_coupees_1973_1984.csv`. Sept cantons
  Troyes-I à VII par division des trois anciens. Le décret n° 85-71 du 22 janvier 1985 (JO du
  23 janvier 1985) ne change rien dans Troyes (canton de La Chapelle-Saint-Luc seul, point 85).
- **Base** : les fractions `38334#1022`, `#1023`, `#1024` s'arrêtent au 1973-09-23 ; les sept
  fractions `#1022`, `#1023`, `#1024`, `#1029`, `#1030`, `#1031`, `#1032` ne commencent qu'au
  1988-09-25 (date COG). Entre les deux, la ville n'a aucun canton, alors que les communes
  rurales sont bien dans 1022, 1023 et 1029 dès le 1973-09-23. Aucune appartenance non plus de
  1941 à 1968.
- **À inscrire** : les sept fractions du 1973-09-23 au 1988-09-25, sous les mêmes unités :
  1022 = Troyes-I, 1023 = Troyes-II, 1024 = Troyes-III, 1029 = Troyes-IV, 1030 = Troyes-V,
  1031 = Troyes-VI, 1032 = Troyes-VII (correspondance établie par les communes de banlieue de
  1990). Attention : `#1022`, `#1023`, `#1024` ne désignent pas le même secteur avant et après
  1973 (Troyes-2 d'avant 1973 est l'ouest, Troyes-II d'après 1973 le nord-est).
- **Chronologie fausse** : `cantons/chronologie_cantonale.csv` date du 1985-01-22 la création de
  Troyes-3 à 7 ; c'est 1973 (déjà dit au point 85).
- **Cible avant 1856** : l'ANR de 38334 passe de 1 033,6 ha à 1 329,1 ha au 1856-01-01 (l'ouest,
  295 ha). Aucun atome ne couvre ce territoire avant 1856 : commune annexée à retrouver, avec
  son canton.
- **Échange de 1986 absent de l'ANR** : décret du 24 juin 1986 (JO du 28 juin 1986,
  `jorf_txt/JORF_19860628_149_col.txt`), 1 ha 20 a 16 ca de Saint-Julien-les-Villas (Troyes-VII)
  rattachés à Troyes (Troyes-V). Un seul état ANR 1856-2020.
- **Tracé** (écrit le 9 octobre 2026) : lignes `10387-1` à `-3` avancées à 1815 (1815-01-01 →
  1973-09-23), ancres datées `#1022` (780693.65 6800566.03), `#1023` (779547 6802204), `#1024`
  (780110.6 6798429.39) ; lignes `10387-4` à `-10` (1973-09-23 → 2013-01-01), ancres datées
  `#1022` (781471 6799542), `#1023` (780812 6801151), `#1024` (778310 6800755), `#1029`
  (779163 6801593), `#1030` (780528 6798937), `#1031` (779733 6798179), `#1032`
  (780119 6797503). Conforme en 1815, 1856, 1972, 1988 et 2005 ; les ancres de 1973 joueront
  dès 1973 le jour où les appartenances seront inscrites.
- **À vérifier sur le plan du décret** : le bout de la rue du Grand-Véon (nord retenu : Troyes-II
  borde alors Saint-Parres, canton I, sur 1 159 m) ; le bassin du canal entre les quais La
  Fontaine et du Comte-Henri (2,1 ha, donné à Troyes-V sur une seule ligne).

## Soissons (02722)

### 9. FAIT (11 octobre 2026, `sql/112`) — Le nom de Soissons-Nord de 1973 à 1999

- **Inscrit par `sql/112_villes_date_du_decret.sql`** : le nom « Soissons-Nord » pour 0231 du 1973-09-23 au 1999-01-01.
- **Reste** : rien.

Ce qui suit est l'entrée telle qu'elle était avant l'inscription.

- **Source** : décret n° 73-712 du 23 juillet 1973 (JO du 25 juillet 1973), article 5 remplacé
  par le décret n° 73-826 du 18 août 1973 (JO du 19 août 1973) : « Soissons-Nord » et
  « Soissons-Sud ».
- **Base** : les appartenances sont justes (`36448#0231` et `#0241` depuis le 1973-09-23). Mais
  `unit_version` nomme 0231 « Soissons » de 1973 à 1999, et « Soissons-Nord » seulement à partir
  de 1999.
- **À inscrire** : le nom « Soissons-Nord » pour 0231 à partir du 1973-09-23.
- Aucune ligne n'en dépend : `02722-1` est posée et conforme.

## Laon (02408)

### 11. FAIT (11 octobre 2026, `sql/112`) — Le nom de Laon-Nord de 1973 à 1999

- **Inscrit par `sql/112_villes_date_du_decret.sql`** : le nom « Laon-Nord » pour 0218 du 1973-09-23 au 1999-01-01.
- **Reste** : rien (l'entrée 10, l'échange de 1997, n'est pas faite).

Ce qui suit est l'entrée telle qu'elle était avant l'inscription.

- **Source** : décret n° 73-712 du 23 juillet 1973 (JO du 25 juillet 1973, art. 3) :
  « Laon-Nord » et « Laon-Sud ».
- **Base** : `unit_version` nomme 0218 « Laon » de 1973 à 1999 (même cas que Soissons, point 9).
- **À inscrire** : le nom « Laon-Nord » pour 0218 à partir du 1973-09-23.

## Saint-Quentin (02691)

### 12. FAIT (11 octobre 2026, `sql/112`) — Le nom de Saint-Quentin-Centre de 1973 à 1999 — et une règle générale probable

- **Inscrit par `sql/112_villes_date_du_decret.sql`** : le nom « Saint-Quentin-Centre » pour 0228 du 1973-09-23 au 1999-01-01.
- **Reste** : la règle générale : `unit_version` n'a rien entre 1941 et 1999 pour ces unités, et c'est `unit.nom` (le nom de 1940) qui s'affiche. À vérifier sur toute la France.

Ce qui suit est l'entrée telle qu'elle était avant l'inscription.

- **Source** : décret n° 73-826 du 18 août 1973 (JO du 19 août 1973), article 4 :
  Saint-Quentin-Centre, -Nord, -Sud.
- **Base** : 0228 s'appelle « Saint-Quentin » de 1973 à 1999, et « Saint-Quentin-Centre »
  seulement ensuite. Les appartenances des trois fractions sont justes depuis le 1973-09-23.
- **Constat général** : troisième cas dans l'Aisne après Soissons (point 9) et Laon (point 11).
  Pour chaque canton dédoublé en 1973, l'unité qui garde le numéro de l'ancien canton garde aussi
  son ancien nom jusqu'en 1999. C'est probablement systématique (`unit_version` alimenté par le
  COG 1999). À vérifier sur toute la France avant de corriger au cas par cas.

## Vichy (03310)

### 13. FAIT (11 octobre 2026, `sql/112`) — Vichy-Nord et Vichy-Sud de 1973 à 1985 : absents, et leurs communes mal rangées

- **Inscrit par `sql/112_villes_date_du_decret.sql`** : `39750#0329` et `39750#0330` du 1973-09-23 au 1985-03-10 ; Abrest, Saint-Yorre et Le Vernet passent de 0335 à 0330 sur la même période (6 lignes). La ligne `03310-2` se tire avec les ancres non datées déjà posées (1980-01-01 : Nord 357 ha, Sud 233 ha) : aucune ancre à ajouter.
- **Reste** : le nom « Vichy-Nord » pour 0329 dès 1973 ; la date 1982-01-15 de la chronologie.

Ce qui suit est l'entrée telle qu'elle était avant l'inscription.

- **Sources** :
  - décret n° 73-713 du 23 juillet 1973 (JO du 25 juillet 1973) : Vichy-Nord (partie de la ville
    seule) et Vichy-Sud (Abrest, Saint-Yorre, Le Vernet et le reste de la ville) ;
  - décret n° 85-82 du 23 janvier 1985 (JO du 24 janvier 1985), qui les remplace : Vichy-Nord et
    Vichy-Sud ne gardent que la ville, et Abrest, Saint-Yorre et Le Vernet passent à Cusset-Sud.
- **Base** :
  - fractions `39750#0329` et `#0330` seulement à partir du **1985-03-10** ; l'atome entier
    39750 n'a aucun canton de 1973-09-23 à 1985 ;
  - Abrest et Le Vernet sont dans **0335 Cusset-Sud dès 1973-09-23**, alors que ce canton est créé
    en 1985 : ils devraient être dans 0330 Vichy-Sud de 1973 à 1985 (Saint-Yorre à vérifier) ;
  - la chronologie cantonale date le dédoublement du 1982-01-15, sans texte à l'appui : c'est le
    décret de Montluçon (82-22) du même jour.
- **À inscrire** :
  - les deux fractions de Vichy de 1973-09-23 à 1985-03-10 ;
  - Abrest, Le Vernet (et Saint-Yorre) dans 0330 sur la même période.
- **Déjà prêt** : ligne `03310-2` (1973-09-23 → 1985-03-10), rangée sans ancre. Ancres à poser :
  Nord `POINT(732378 6559673)`, Sud `POINT(733365 6557954)`. La ligne `03310-1` (1985-2013) est
  posée et conforme.

## Briançon (05023)

### 16. FAIT (11 octobre 2026, `sql/112`) — Briançon-Nord et Briançon-Sud de 1973 à 1982, et Puy-Saint-Pierre compté deux fois de 1974 à 1988

- **Inscrit par `sql/112_villes_date_du_decret.sql`** : `5879#0506` et `5879#0525` du 1973-09-23 au 1982-03-14 (tirée au 1975-01-01 : Nord 1 475 ha, Sud 2 136 ha, Puy-Saint-Pierre comprise).
- **Reste** : le double compte de Puy-Saint-Pierre de 1974 à 1988, à trancher ; le nom « Briançon-Nord » pour 0506 dès 1973.

Ce qui suit est l'entrée telle qu'elle était avant l'inscription.

- **Source** : décret n° 73-651 du 13 juillet 1973 (JO du 17 juillet 1973), art. 1er :
  Briançon-Nord (Névache, Val-des-Prés, Montgenèvre et le nord de la ville), Briançon-Sud
  (Puy-Saint-André, Puy-Saint-Pierre, Villar-Saint-Pancrace, Cervières et le reste de la ville).
  Aucun texte ne change la limite ensuite.
- **Base** :
  - l'atome entier 5879 est dans 0506 jusqu'au 1973-09-23. Les fractions `5879#0506` et
    `#0525` ne commencent qu'au **1982-03-14** : **de 1973 à 1982, la ville n'a aucun canton**,
    alors que les communes rurales (Puy-Saint-Pierre dans 0525, par exemple) en ont un dès 1973 ;
  - 0506 s'appelle « Briançon » jusqu'en 1999, et « Briançon-Nord » seulement ensuite : même
    cas que les points 9, 11, 12 et 15 ;
  - Puy-Saint-Pierre a été réunie à Briançon du 1er juin 1974 au 1er janvier 1989 (INSEE). La
    cible de Briançon l'inclut de 1974-01-01 à 1988-01-01 (ANR), et l'atome de Puy-Saint-Pierre
    garde son appartenance à 0525 sur la même période. **L'ancienne commune est donc tirée deux
    fois** : comme atome propre et dans la fraction Sud de Briançon. Les deux sont dans 0525, si
    bien que la carte des cantons n'est pas fausse. Mais l'aire de 0525 compte deux fois environ
    740 ha. À trancher : retirer l'atome pendant la fusion, ou borner la cible de Briançon.
- **À inscrire** : les deux fractions de Briançon de 1973-09-23 à 1982-03-14.
- **Déjà prêt** : la ligne `05023-1` (1973-09-23 → 2013) et ses ancres (Nord
  `POINT(987500 6431000)`, Sud `POINT(988400 6427500)`) couvrent déjà le trou. Les ancres de
  1982 jouent, parce que leur appartenance chevauche la période de la ligne. La ligne `05023-2`
  (1974-01-01 → 1988-01-01) suit l'ancienne limite de Puy-Saint-Pierre pendant la fusion.

## Digne-les-Bains (04070)

### 18. FAIT (11 octobre 2026, `sql/112`) — Digne de 1973 à 1988 : la ville et Digne-Est absentes, Digne-Ouest présent

- **Inscrit par `sql/112_villes_date_du_decret.sql`** : `11835#0408` et `11835#0431` du 1973-09-23 au 1988-09-25 ; Entrages, La Robine-sur-Galabre et Marcoux dans 0408 sur la même période. Tirée au 1980-01-01 (Est 3 587 ha, Ouest 7 383 ha) et au 1986-06-01 (5 442 et 5 528 ha).
- **Reste** : le nom « Digne-Est » pour 0408 dès 1973 ; Marcoux de 1955 à 1973 (trou général) ; la date de la chronologie.

Ce qui suit est l'entrée telle qu'elle était avant l'inscription.

- **Sources** :
  - décret n° 73-714 du 23 juillet 1973 (JO du 25 juillet 1973), art. 1er : Digne-Est (Entrages,
    Les Dourbes, Marcoux, La Robine-sur-Galabre et l'est de la ville) et Digne-Ouest (onze
    communes et l'ouest de la ville) ;
  - décret n° 85-127 du 29 janvier 1985 (JO du 30 janvier 1985), art. 2 : une portion de la ville
    passe de Digne-Ouest à Digne-Est. La chronologie cantonale date ce changement du « 20.2.1986
    (fix. limites) » ; comme pour Manosque (point 17), le décret de ce jour-là ne concerne pas
    Digne.
- **Base** :
  - l'atome 11835 est dans 0408 jusqu'au 1973-09-23. Les fractions `#0408` et `#0431` ne
    commencent qu'au **1988-09-25** : de 1973 à 1988, **la ville n'a aucun canton** ;
  - **Digne-Ouest est complet** : Aiglun, Champtercier, Le Chaffaut-Saint-Jurson et Thoard sont
    dans 0431 dès le 1973-09-23 ;
  - **Digne-Est ne l'est pas** : Entrages, La Robine-sur-Galabre et Marcoux n'ont aucun canton de
    1973-09-23 à 1988-09-25 ;
  - 0408 s'appelle « Digne » jusqu'en 1999, et non « Digne-Est » : septième cas de la règle du
    point 12 ;
  - Les Dourbes, réunie à Digne le 1er mars 1974, est déjà dans la cible de Digne en 1973
    (même cas que Romette à Gap, point 15).
- **À inscrire** :
  - les fractions de Digne-Est (0408) et Digne-Ouest (0431) de 1973-09-23 à 1988-09-25 ;
  - Entrages, La Robine-sur-Galabre et Marcoux dans 0408 sur la même période.
- **Déjà prêt** :
  - `04070-1` (1985-03-10 → 2013), ancrée. Elle couvre déjà 1985-1988.
  - `04070-2` (1973-09-23 → 1985-03-10), rangée sans ancre. Ancres à poser : Est
    `POINT(962000 6338000)`, Ouest `POINT(956300 6339400)`.

## Cusset (03095)

### 19. FAIT (11 octobre 2026, `sql/112`) — Le canton de Cusset de 1973 à 1985 : la ville et quatre communes sans canton

- **Inscrit par `sql/112_villes_date_du_decret.sql`** : l'atome 11413, Busset, Mariol, Molles et La Chapelle dans 0306 du 1973-09-23 au 1985-03-10 (La Chapelle était bien dans 0306 jusqu'en 1955).
- **Reste** : La Chapelle de 1955 à 1973 (trou général) ; le nom « Cusset-Nord » pour 0306 dès 1985.

Ce qui suit est l'entrée telle qu'elle était avant l'inscription.

- **Source** : décret n° 85-82 du 23 janvier 1985 (JO du 24 janvier 1985), art. 1er : Cusset,
  Vichy-Nord et Vichy-Sud sont remplacés par Cusset-Nord, Cusset-Sud, Vichy-Nord et Vichy-Sud.
  Avant 1985, Cusset est une commune entière du canton de Cusset (0306), non coupée.
- **Base** :
  - l'atome entier 11413 (Cusset) n'a **aucun canton de 1973-09-23 à 1985-03-10**. Il est
    pourtant dans 0306 avant et, par ses fractions, après ;
  - Busset, Mariol et Molles n'ont aucun canton sur la même période, alors que Bost et les deux
    Creuzier sont bien dans 0306. La Chapelle n'en a aucun avant 1985 ;
  - Abrest, Le Vernet et Saint-Yorre sont dans 0335 dès 1973 : voir le point 13 ;
  - 0306 s'appelle « Cusset » jusqu'en 1999, et « Cusset-Nord » seulement ensuite : huitième cas
    de la règle du point 12.
- **À inscrire** : l'atome 11413, Busset, Mariol, Molles et La Chapelle dans 0306, de 1973-09-23
  à 1985-03-10 (La Chapelle : vérifier son canton d'avant 1973).
- **Déjà prêt** : la ligne `03095-1` (1985-03-10 → 2013), ancrée et conforme. Elle part
  exactement du bout de la ligne de Vichy `03310-1` sur la limite des deux communes.

## Creil (60175)

### 30. FAIT (11 octobre 2026, `sql/112`) — Creil-Nogent-sur-Oise et Creil-Sud de 1973 à 1998 : absents

- **Inscrit par `sql/112_villes_date_du_decret.sql`** : `10978#6011` et `10978#6038` du 1973-09-23 au 1998-03-15 ; Nogent-sur-Oise et Villers-Saint-Paul dans 6011 sur la même période ; le nom « Creil-Nogent-sur-Oise » pour 6011 du 1973-09-23 au 1999-01-01.
- **Reste** : Villers-Saint-Paul de 1955 à 1973 (trou général).

Ce qui suit est l'entrée telle qu'elle était avant l'inscription.

- **Source** : décret n° 73-668 du 13 juillet 1973 (JO du 17 juillet 1973), art. 2. Le canton de
  Creil est divisé en quatre : Creil-Nogent-sur-Oise (Nogent-sur-Oise, Villers-Saint-Paul et la
  ville au nord de l'Oise), Creil-Sud (la ville au sud de l'Oise), Montataire, Chantilly.
- **Base** :
  - jusqu'au 23 septembre 1973 : l'atome entier `10978` dans 6011 « Creil » ;
  - de 1973 à 1998 : rien, ni pour la ville, ni pour Nogent-sur-Oise et Villers-Saint-Paul ;
  - à partir du 15 mars 1998 : `10978#6011` (nommé « Creil » jusqu'en 1999, puis
    « Creil-Nogent-sur-Oise ») et `10978#6038` Creil-Sud.
- **À inscrire** : les deux fractions, ainsi que Nogent-sur-Oise et Villers-Saint-Paul, à partir du
  23 septembre 1973 ; le nom Creil-Nogent-sur-Oise pour 6011 dès 1973.
- **Tracé** : `60175-1` (l'Oise, bras principal ; l'île Saint-Maurice au Sud, précision
  d'Adrien), du 23 septembre 1973 au 1er janvier 2013, avec des ancres datées. Elles jouent déjà
  sur 1973-1998 par la règle du chevauchement.

## Mayenne (53147)

### 36. FAIT (11 octobre 2026, `sql/112`) — Mayenne de 1941 à 1992 : l'atome entier dans l'Ouest, puis rien

- **Inscrit par `sql/112_villes_date_du_decret.sql`** : `21721#5320` et `21721#5321` du 1941-01-01 au 1992-03-22 ; l'atome entier 21721 quitte Mayenne-Ouest sur 1968 → 1973-09-23.
- **Reste** : rien.

Ce qui suit est l'entrée telle qu'elle était avant l'inscription.

- **Source** : Gaudillère, extrait donné par Adrien le 27 septembre 2026 : « la Mayenne » sépare
  Mayenne-Est et Mayenne-Ouest. La chronologie donne ces deux cantons depuis le 16 mars 1802, sans
  changement ensuite.
- **Base** :
  - 1870-1941 et 1992-2013 : `21721#5320` Est, `21721#5321` Ouest ;
  - 1968-1973 : **l'atome entier `21721` dans Mayenne-Ouest** ;
  - 1973-1992 : rien.
- **À inscrire** : les deux fractions de 1941 à 1992, à la place de l'atome entier en 1968-1973.
- **Tracé** : `53147-1` (la Mayenne), du 16 mars 1802 au 1er janvier 2013, avec des ancres datées.
  Elles jouent aussi sur 1973-1992.

## La Roche-sur-Yon (85191)

### 48. FAIT (11 octobre 2026, `sql/112`) — La Roche-sur-Yon : le nom du canton Nord de 1973 à 1999

- **Inscrit par `sql/112_villes_date_du_decret.sql`** : le nom « La Roche-sur-Yon-Nord » pour 8523 du 1973-09-23 au 1999-01-01.
- **Reste** : rien.

Ce qui suit est l'entrée telle qu'elle était avant l'inscription.

- **Source** : décret 73-773 du 2 août 1973 (JO du 4 août), qui crée La Roche-sur-Yon-Nord et
  La Roche-sur-Yon-Sud.
- **Base** : `29394#8523` porte le nom « La Roche-sur-Yon » de 1973 à 1999, puis
  « Roche-sur-Yon-Nord » ; `#8531` porte « Roche-sur-Yon-Sud » dès 1973.
- **À inscrire** : nommer l'unité 8523 « La Roche-sur-Yon-Nord » dès le 23 septembre 1973.
- **Tracé** : `85191-1`, de 1973 à 2013, conforme.

## Poitiers (86194)

### 49. FAIT (11 octobre 2026, `sql/112`) — Poitiers : Nord et Sud de 1941 à 1973

- **Inscrit par `sql/112_villes_date_du_decret.sql`** : `27358#8621` et `27358#8622` du 1941-01-01 au 1973-09-23 ; l'atome entier 27358 quitte Poitiers-Sud sur 1968 → 1973-09-23.
- **Reste** : le régime de 1973-1982 (Poitiers-1 à 5) : la base ne reprend qu'au 1982-03-14, avec sept cantons.

Ce qui suit est l'entrée telle qu'elle était avant l'inscription.

- **Sources** : chronologie p. 821 : limites de Poitiers-Nord et Poitiers-Sud fixées le 16 avril
  1862 ; Poitiers-1 à 5 créés le 13 juillet 1973.
- **Base** :
  - `27358#8621` Nord et `#8622` Sud de 1870 à 1941 ;
  - de 1968 à 1973, l'atome entier `27358` dans le Sud ;
  - rien de 1941 à 1968.
- **À inscrire** : Nord et Sud de 1862 (ou 1870) au 13 juillet 1973, à la place de l'atome entier
  dans le Sud en 1968-1973.
- **Tracé** : `86194-1`, de 1862 à 1973, ancres datées.

## Grasse (06069)

### 80. FAIT (11 octobre 2026, `sql/112`) — Grasse de 1973 à 1998 : la ville sans canton, Grasse-Nord qui commence en 1998

- **Inscrit par `sql/112_villes_date_du_decret.sql`** : la ville entière dans 0610 du 1973-09-23 au 1985-03-10 ; `16069#0610` et `16069#0651` du 1985-03-10 au 1998-03-15 ; le nom « Grasse-Sud » pour 0610 du 1985-03-10 au 1999-01-01.
- **Reste** : le point d'arrivée de la « ligne droite », à trancher par Adrien.

Ce qui suit est l'entrée telle qu'elle était avant l'inscription.

- **Sources** : décret n° 85-143 du 31 janvier 1985 (JO du 1er février 1985,
  `jorf_txt/JORF_19850201_27_col.txt`), art. 6 : création de Grasse-Nord (le nord de la ville
  seul) ; le canton de Grasse devient Grasse-Sud.
- **Base** :
  - l'atome `16069` est dans 0610 jusqu'au 1973-09-23 ; les fractions `16069#0610` et
    `16069#0651` ne commencent qu'au **1998-03-15** : de 1973 à 1998, **la ville n'a aucun
    canton**, alors qu'Auribeau-sur-Siagne et Pégomas restent dans 0610 sans interruption ;
  - 0610 s'appelle « Grasse » jusqu'en 1941, n'a pas de nom ensuite, puis « Grasse-Sud » en 1999 ;
    0651 n'a pas de nom avant 1999 (règle du point 12).
- **À inscrire** :
  - la ville entière dans 0610 de 1973-09-23 au 1985-03-10 ;
  - les deux fractions dès le 1985-03-10, et les noms Grasse-Sud / Grasse-Nord à cette date.
- **Déjà prêt** : `06069-1` (1985-03-10 → 2013), ancrée ; elle couvre déjà 1985-1998.
- **À trancher par Adrien** : le point d'arrivée de la « ligne droite » finale. Retenu : la cote
  290,4 du texte (sommet du chemin du Piéchal sur la limite de Châteauneuf, 1019834 6292356).
  Le toponyme BD TOPO « la fontaine de l'ormeau » est 740 m plus au sud-est, à 252 m
  d'altitude ; le prendre déplacerait 32,5 ha de Grasse-Sud vers Grasse-Nord.

## Menton (06083)

### 81. FAIT (11 octobre 2026, `sql/112`) — Le canton de Menton de 1973 à 1998 : la ville et trois communes sans canton

- **Inscrit par `sql/112_villes_date_du_decret.sql`** : Menton, Gorbio, Roquebrune-Cap-Martin et Sainte-Agnès dans 0613 du 1973-09-23 au 1998-03-15.
- **Reste** : la lecture de la « route de Sainte-Agnès ».

Ce qui suit est l'entrée telle qu'elle était avant l'inscription.

- **Sources** : décret du 21 février 1997 (NOR INTA9700038D, JO du 23 février 1997,
  `jorf_txt/JORF_19970223_46_col.txt`), art. 1er : création de Menton-Ouest (Gorbio,
  Roquebrune-Cap-Martin, Sainte-Agnès et l'ouest de la ville) ; Menton devient Menton-Est. Effet
  au renouvellement de mars 1998 : la date de la base est la bonne.
- **Base** :
  - **Menton (atome `22015`), Gorbio, Roquebrune-Cap-Martin et Sainte-Agnès n'ont aucun canton
    de 1973-09-23 à 1998-03-15** ; seule Castellar reste dans 0613 sans interruption ;
  - 0613 s'appelle « Menton » jusqu'en 1941, n'a pas de nom ensuite, puis « Menton-Est » en 1999
    (règle du point 12).
- **À inscrire** : les quatre communes dans 0613 de 1973-09-23 au 1998-03-15 (canton entier,
  aucune coupe à ces dates).
- **Déjà prêt** : `06083-1` (1998-03-15 → 2013), ancrée.
- **À confirmer par Adrien** : la « route de Sainte-Agnès » est lue comme la D22 ; l'autre
  lecture (quitter l'avenue de Prades dès qu'elle croise la ligne à 63 kV) déplace 5,3 ha de
  l'Ouest vers l'Est. La part de Menton-Ouest fait 128 ha, 9 % de la commune.

## Sedan (08409)

### 83. FAIT (11 octobre 2026, `sql/112`) — Sedan de 1973 à 1982 : la ville sans canton, et « Sedan-Sud » qui est Sedan-Est

- **Inscrit par `sql/112_villes_date_du_decret.sql`** : `35814#0826`, `#0827` et `#0836` du 1973-09-23 au 1982-03-14 ; le nom « Sedan-Est » pour 0827 du 1973-09-23 au 1999-01-01.
- **Reste** : la limite Nord / Sud de 1870 à 1973 ; et, vu en passant, **Lamécourt (60345, Oise) est dans 0827 du 1973-09-23 au 1982-03-14** — sans doute prise pour Rubécourt-et-Lamécourt (08371) : **retirée par `sql/114`** (13 octobre 2026).

Ce qui suit est l'entrée telle qu'elle était avant l'inscription.

- **Source** : décret n° 73-715 du 23 juillet 1973 (JO du 25 juillet 1973), art. 3 : « en remplacement
  des cantons de Sedan-Nord et Sedan-Sud, il est créé trois cantons » : Sedan-Nord, Sedan-Ouest,
  Sedan-Est.
- **Base** :
  - fractions `35814#0826` et `#0827` sans canton du 1973-09-23 au 1982-03-14 ; `#0836` (Ouest)
    seulement à partir du 1982-03-14, alors que Donchery et Wadelincourt sont dans 0836 dès 1973-09-23 ;
  - l'unité 0827 s'appelle « Sedan-Sud » jusqu'en 1999, puis « Sedan-Est » : le décret la nomme
    Sedan-Est dès 1973.
- **À inscrire** : les trois fractions du 1973-09-23 au 1982-03-14 ; le nom Sedan-Est pour 0827 à
  partir de 1973.
- **Déjà prêt** : lignes `08409-1` à `08409-3` (1973-09-23 → 2013), ancres datées posées.
- **Manque** : la limite Nord / Sud de 1870 à 1973 (aucun texte dans le dépôt ; Frénois réunie en 1965).

## Romilly-sur-Seine (10323)

### 84. FAIT (11 octobre 2026, `sql/112`) — Romilly-I et Romilly-II commencent en 1988 dans la base, en 1973 dans le JO

- **Inscrit par `sql/112_villes_date_du_decret.sql`** : `29547#1020` et `29547#1027` du 1973-09-23 au 1988-09-25 ; les noms « Romilly-sur-Seine-I » et « -II » du 1973-09-23 au 1999-01-01.
- **Reste** : les deux points à confirmer de la note.

Ce qui suit est l'entrée telle qu'elle était avant l'inscription.

- **Source** : décret n° 73-652 du 13 juillet 1973 (JO du 17 juillet 1973), art. 4 ;
  `cantons/communes_coupees_1973_1984.csv`, `jorf_txt/JORF_19730717_164_col.txt`. Romilly-II n'a
  aucune commune rurale.
- **Base** :
  - l'atome entier 29547 est dans 1020 jusqu'au 1973-09-23, puis dans rien ;
  - les fractions `29547#1020` (I) et `29547#1027` (II) ne commencent qu'au **1988-09-25** (COG) ;
  - `unit_version` n'a rien pour 1020 entre 1941 et 1999 (« Romilly-sur-Seine », puis « 1er
    Canton »), et rien pour 1027 avant 1999.
- **À inscrire** : `29547#1020` dans 1020 et `29547#1027` dans 1027 du 1973-09-23 au 1988-09-25 ;
  les noms Romilly-sur-Seine-I et -II dès 1973.
- **Déjà prêt** : ligne `10323-1` (1973-09-23 → 2013-01-01), ancres non datées
  `POINT(755000 6824800)` pour I et `POINT(752000 6824000)` pour II. Rien à retoucher une fois
  les appartenances inscrites.
- **À confirmer** (dit dans la note de la coupe) : « la limite Ouest de la Petite-Béchère », lue
  comme le côté ouest du parc de la Béchère ; le tracé de 1973 de la rue du Général-de-Gaulle
  (triangle de 3,5 ha au canton I).

## La Chapelle-Saint-Luc (10081)

### 85. FAIT (11 octobre 2026, `sql/112`) — Le canton de La Chapelle-Saint-Luc commence en 1988 dans la base, en 1985 dans le JO

- **Inscrit par `sql/112_villes_date_du_decret.sql`** : `8317#1029` et `8317#1033` du 1985-03-10 au 1988-09-25 ; Les Noës-près-Troyes dans 1028 du 1973-09-23 au 1985-03-10 puis dans 1033 ; Macey, Montgueux, La Rivière-de-Corps, Sainte-Savine et Torvilliers dans 1028 du 1973-09-23 au 1988-09-25.
- **Reste** : Torvilliers de 1955 à 1973 (trou général) ; la chronologie ; les noms de 1028 et 1033 avant 1999 (« Chapelle-Saint-Luc », sans « La »).

Ce qui suit est l'entrée telle qu'elle était avant l'inscription.

- **Source** : décret n° 85-71 du 22 janvier 1985 (JO du 23 janvier 1985), art. 1er ;
  `jorf_txt/JORF_19850123_19_col.txt` : canton de La Chapelle-Saint-Luc = Les Noës-près-Troyes
  et la partie de La Chapelle à l'ouest de l'axe des avenues René-Coty et Roger-Salengro ;
  Troyes-IV et Sainte-Savine modifiés par voie de conséquence.
- **Base** :
  - l'atome entier 8317 est dans 1029 (Troyes-IV) du 1973-09-23 au 1985-03-10 ;
  - les fractions `8317#1029` et `8317#1033` ne commencent qu'au **1988-09-25** : de 1985-03-10
    à 1988-09-25, la commune n'a aucun canton ;
  - Les Noës-près-Troyes (atome 25092) : dans 1023 jusqu'au 1973-09-23, puis rien jusqu'au
    1988-09-25 (1033 ensuite) ;
  - le canton 1028 (Sainte-Savine) n'a aucun membre du 1973-09-23 au 1988-09-25 ;
  - `unit_version` ne connaît 1033 (« Chapelle-Saint-Luc », sans « La ») et 1028 qu'à partir de 1999.
- **À inscrire** :
  - `8317#1033` dans 1033 et `8317#1029` dans 1029, du 1985-03-10 au 1988-09-25 ;
  - Les Noës-près-Troyes dans 1028 du 1973-09-23 au 1985-03-10 (décret 73-652, art. 2 : « Canton
    de Sainte-Savine, comprenant les communes de Macey, Montgueux, Noes-près-Troyes, la
    Rivière-de-Corps, Sainte-Savine, et de Torvilliers »), puis dans 1033 ;
  - les autres communes du canton de Sainte-Savine dans 1028 dès 1973.
- **Chronologie fausse** : `cantons/chronologie_cantonale.csv` date du 1985-01-22 la création de
  Troyes-3, Troyes-4 et Sainte-Savine, et celle de Troyes-5 à 7 ; c'est le décret 73-652 du
  13 juillet 1973 (art. 2 et 3). Seule la création de La Chapelle-Saint-Luc est de 1985.
- **Déjà prêt** : ligne `10081-1` (1985-03-10 → 2013-01-01), ancres ouest (`8317#1033`) et est
  (`8317#1029`), non datées.

## Pamiers (09225)

### 86. FAIT (11 octobre 2026, `sql/112`) — Pamiers : la ville sans canton de 1955 à 1985, et « Pamiers-Ouest » nommé en 1999

- **Inscrit par `sql/112_villes_date_du_decret.sql`** : l'atome 26103 dans 0912 du 1955-01-01 au 1985-03-10 ; le nom « Pamiers-Ouest » pour 0912 du 1985-03-10 au 1999-01-01.
- **Reste** : les deux points à confirmer de la note.

Ce qui suit est l'entrée telle qu'elle était avant l'inscription.

- **Source** : décret n° 84-1223 du 24 décembre 1984 (JO du 30 décembre 1984, p. 4146-4147),
  art. 1er ; `jorf_txt/JORF_19841230_305_col.txt` : création de Pamiers-Est ; le canton de
  Pamiers « prend la dénomination de Pamiers-Ouest ».
- **Base** :
  - fractions `26103#0912` et `26103#0922` à partir du 1985-03-10 : juste ;
  - l'atome entier 26103 est dans 0912 jusqu'au 1955-01-01, puis dans rien jusqu'au 1985-03-10 ;
  - `unit_version` n'a rien pour 0912 entre 1941 et 1999, puis « Pamiers-Ouest ».
- **À inscrire** : l'atome 26103 dans 0912 de 1955 à 1985 (canton non divisé) ; le nom
  Pamiers-Ouest pour 0912 dès le 1985-03-10.
- **Noté, sans suite pour la ville** : décret n° 98-722 du 18 août 1998 (JO du 21 août 1998),
  27 ha 32 a 89 ca de Saint-Victor-Rouzaud (Pamiers-Ouest) rattachés à Artix (Varilhes) ; il ne
  touche pas la limite interne.
- **Déjà prêt** : ligne `09225-1` (1985-03-10 → 2013-01-01), ancres est (`26103#0922`) et ouest
  (`26103#0912`).
- **À confirmer** (dit dans la note de la coupe) : le « canal des usines », reconnu à sa seule
  géométrie ; la « rue de l'Hospice-de-Loumet », prise pour la rue de Loumet.

## Narbonne (11262)

### 88. FAIT (11 octobre 2026, `sql/112`) — Narbonne de 1973 à 1998 : la ville et Bages sans canton, les noms Est / Ouest / Sud en 1999

- **Inscrit par `sql/112_villes_date_du_decret.sql`** : `24587#1124`, `#1133`, `#1134` et Bages (dans 1134) du 1973-09-23 au 1998-03-15 ; les noms Narbonne-Est, -Ouest et -Sud du 1973-09-23 au 1999-01-01.
- **Reste** : Bizanet de 1955 à 1973 (trou général, constaté : 1124 jusqu'en 1955, 1133 depuis 1973) ; le boulevard de 1848.

Ce qui suit est l'entrée telle qu'elle était avant l'inscription.

- **Sources** : décret n° 73-653 du 13 juillet 1973, art. 3 (JO du 17 juillet 1973,
  p. 7703-7704, `jorf_txt/JORF_19730717_164_col.txt`) : le canton de Narbonne est remplacé par
  Narbonne-Est (partie de la ville), Narbonne-Sud (Bages et partie de la ville) et
  Narbonne-Ouest (Bizanet, Canet, Marcorignan, Montredon, Moussan, Névian, Raissac-d'Aude,
  Villedaigne et le reste de la ville). Décret n° 85-72 du 22 janvier 1985, art. 1er (JO du
  23 janvier 1985, `jorf_txt/JORF_19850123_19_col.txt`) : une portion de Narbonne-Ouest passe à
  Narbonne-Sud.
- **Base** :
  - jusqu'au 23 septembre 1973 : l'atome entier `24587` dans 1124 « Narbonne » ;
  - de 1973 à 1998 : rien pour la ville ; rien non plus pour Bages (`2358`), qui ne reparaît
    dans 1134 qu'au 15 mars 1998. Les huit communes de Narbonne-Ouest sont bien dans 1133 dès le
    23 septembre 1973 ;
  - à partir du 15 mars 1998 : `24587#1124`, `24587#1133`, `24587#1134` ; 1124 s'appelle
    « Narbonne » jusqu'en 1999 ;
  - Bizanet (`4369`) n'a aucun canton de 1955 à 1973 (constat de l'agent, à revérifier).
- **À inscrire** : les trois fractions de la ville et Bages (dans 1134) à partir du
  23 septembre 1973 ; les noms Narbonne-Est (1124), Narbonne-Ouest (1133) et Narbonne-Sud
  (1134) dès 1973 ; Bizanet dans 1124 de 1955 à 1973.
- **Déjà prêt** (écrit le 6 octobre 2026, ancres datées) : `11262-1` (limite de l'Est) et
  `11262-2` (Sud / Ouest de 1973), du 23 septembre 1973 au 10 mars 1985 ; `11262-3` (limite de
  l'Est, même géométrie) et `11262-4` (Sud / Ouest de 1985), du 10 mars 1985 au 1er janvier
  2013. Ancres : Est `POINT(708674 6229804)`, Sud `POINT(701347 6225374)`, Ouest
  `POINT(697340 6229713)`. Est 7 263,0 ha ; Sud 3 210,1 puis 3 301,7 ha ; Ouest 7 025,6 puis
  6 934,0 ha.
- **À confirmer** : en 1985, « l'axe du boulevard de 1848 (jusqu'à la voie de chemin de fer
  Béziers-Narbonne) » — le boulevard actuel est à l'est de la voie ferrée et la Robine à 337 m
  à l'ouest ; tracé par le prolongement de son axe sur 300 m (variante : 0,7 ha). Plan à la
  préfecture de l'Aude.

## Millau (12145)

### 89. FAIT (11 octobre 2026, `sql/112`) — Millau-Est et Millau-Ouest commencent au COG (1988), pas au décret (1973)

- **Inscrit par `sql/112_villes_date_du_decret.sql`** : `22497#1217` et `22497#1244` du 1973-09-23 au 1988-09-25 ; le nom « Millau-Est » pour 1217 du 1973-09-23 au 1999-01-01.
- **Reste** : la lecture de la RN 9.

Ce qui suit est l'entrée telle qu'elle était avant l'inscription.

- **Source** : décret n° 73-762 du 2 août 1973, art. 1er (JO du 4 août 1973),
  `jorf_txt/JORF_19730804_180_col.txt` l. 2137-2150, `cantons/communes_coupees_1973_1984.csv`.
- **Base** : l'atome entier 22497 est dans 1217 « Millau » jusqu'au 1973-09-23, puis dans rien
  jusqu'au 1988-09-25 ; les fractions `22497#1217` et `22497#1244` n'ont d'appartenance qu'à
  partir du 1988-09-25 (date COG). Les communes rurales, elles, basculent bien au 1973-09-23.
- **À inscrire** : appartenances `22497#1217` → 1217 et `22497#1244` → 1244 du
  **1973-09-23 au 1988-09-25**.
- **Nom** : l'unité 1217 s'appelle « Millau » de 1988 à 1999 et n'a pas de version de nom entre
  1941 et 1999 ; le décret la nomme « Millau-Est » dès 1973 (1244 n'a de version qu'à partir de
  1999 aussi).
- **Déjà prêt** : ligne `12145-1` (1973-09-23 → 2013-01-01) et ancres non datées
  `22497#1244` = POINT(703500.25 6333414.25), `22497#1217` = POINT(713633.97 6332042.15) :
  elles joueront dès que les appartenances existeront. Ouest 6 968,7 ha, Est 10 048,4 ha.
- **À confirmer** : au sud du pont Lerouge le décret ne cite plus de voie ; la ligne suit la
  RN 9 (D809 actuelle) sur 16 km jusqu'à La Cavalerie, lecture de « située à l'Ouest de la route
  nationale n° 9 ». 1 948,9 ha en jeu. Plan à la préfecture de l'Aveyron.

## Rodez (12202)

### 90. FAIT (11 octobre 2026, `sql/112`) — Les cantons de Rodez n'ont pas de fraction de la ville de 1973 à 1988

- **Inscrit par `sql/112_villes_date_du_decret.sql`** : `29437#1228` et `#1245` du 1973-09-23 au 1988-09-25 (une ligne par régime), `#1246` du 1982-03-14 au 1988-09-25 ; Le Monastère et Sainte-Radegonde dans 1228 ; Onet-le-Château et Sébazac-Concourès dans 1228 puis 1246 ; Olemps dans 1245 de 1982 à 1988 ; le nom « Rodez-Est » pour 1228 dès 1973.
- **Reste** : Moyrazès (1228 jusqu'en 1973, 1239 depuis 1988), que ni le décret de 1973 ni celui de 1982 ne nomme dans les cantons de Rodez ; la lecture de la RN 140.

Ce qui suit est l'entrée telle qu'elle était avant l'inscription.

- **Source** : décret n° 73-762 du 2 août 1973 (JO du 4 août 1973, p. 8532-8533,
  `jorf_txt/JORF_19730804_180_col.txt` l. 2151-2169) ; décret n° 82-24 du 15 janvier 1982
  (JO du 16 janvier 1982, `jorf_txt/JORF_19820116_13_col.txt` l. 874-901).
- **Base** : atome entier 29437 dans 1228 « Rodez » jusqu'au 1973-09-23, puis rien ; fractions
  `29437#1228`, `#1245`, `#1246` à partir du 1988-09-25 seulement (date COG). L'unité 1228
  s'appelle « Rodez » jusqu'en 1999 (aucune version « Rodez-Est » avant), et 1245 / 1246
  n'ont de version nommée qu'à partir de 1999. Le Monastère, Sainte-Radegonde et
  Onet-le-Château n'ont aucun canton de 1973-09-23 à 1988-09-25 ; Olemps aucun de 1982-03-14
  à 1988-09-25.
- **À inscrire** :
  - 1973-09-23 → 1982-03-14 : `29437#1245` dans Rodez-Ouest (avec Druelle, Luc, Olemps) ;
    `29437#1228` dans Rodez-Est (avec Sébazac-Concourès, Sainte-Radegonde, Onet-le-Château,
    Le Monastère) ;
  - 1982-03-14 → 1988-09-25 : `29437#1245` Rodez-Ouest (Olemps, Luc, Druelle) ; `29437#1228`
    Rodez-Est (Le Monastère, Sainte-Radegonde) ; `29437#1246` Rodez-Nord (Onet-le-Château,
    Sébazac-Concourès) ;
  - versions de nom « Rodez-Est » pour 1228 dès 1973-09-23, « Rodez-Nord » pour 1246 dès 1982.
- **Déjà prêt** : lignes `12202-1` (1973-09-23 → 1982-03-14), `12202-2` et `12202-3`
  (1982-03-14 → 2013-01-01) ; ancres datées Est `POINT(667195.38 6361448.45)`, Ouest
  `POINT(665231.04 6361971.85)`, Nord `POINT(664334.01 6363466.55)` (Nord depuis 1982
  seulement). 1973 : Ouest 766,6 ha, Est 359,0 ha ; 1982 : Ouest 446,1, Est 359,0, Nord 320,5 ha.
- **À confirmer** : le décret de 1982 ne nomme que « RN 88 », « route 140 » et « CD 994 ». La
  RN 140 est lue depuis le carrefour de la gare (avenues du Maréchal-Joffre et de la Gineste) ;
  lue depuis la limite nord-ouest (avenue de Decazeville), Rodez-Nord n'aurait que 104,4 ha
  (variante gardée dans `public.rodez_alt_coin_nord_ouest`). Plan à la préfecture de l'Aveyron.

## Istres (13047)

### 91. FAIT (11 octobre 2026, `sql/112`) — Le canton d'Istres de 1973 à 1992 : quatre communes sans canton, et Miramas à dater

- **Inscrit par `sql/112_villes_date_du_decret.sql`** : Istres, Fos-sur-Mer et Saint-Mitre-les-Remparts dans 1311 du 1973-09-23 au 1992-03-22 ; le nom « Istres-Nord » pour 1311 du 1992-03-22 au 1999-01-01.
- **Reste** : Miramas (texte à trouver) ; Saint-Chamas, dans 1311 jusqu'en 1973 et dans 1306 depuis 1992, sans canton entre les deux.

Ce qui suit est l'entrée telle qu'elle était avant l'inscription.

- **Source** : décret n° 91-209 du 27 février 1991 (JO du 28 février 1991, p. 2900-2901,
  `jorf_txt/JORF_19910228_51_col.txt`), art. 1er : « En remplacement des cantons d'Istres et de
  Berre-l'Étang », création d'Istres-Nord (Miramas et le nord d'Istres), d'Istres-Sud
  (Fos-sur-Mer, Saint-Mitre-les-Remparts et le reste d'Istres), de Berre-l'Étang et de Vitrolles.
  Effet « pour le prochain renouvellement des conseils généraux » (22 mars 1992).
- **Base** :
  - l'atome entier `17661` (Istres), Fos-sur-Mer (`14545`) et Saint-Mitre-les-Remparts (`33741`)
    sont dans 1311 jusqu'au 1973-09-23, puis **n'ont aucun canton jusqu'au 1992-03-22** ;
  - Miramas (`22570`) est dans 1332 Salon-de-Provence jusqu'au 1973-09-23, n'a rien ensuite, et
    reparaît dans 1311 au 1992-03-22. Le décret de 1991 la compte pourtant dans l'ancien canton
    d'Istres : son passage de Salon à Istres, entre 1973 et 1991, reste à dater (texte non
    cherché) ;
  - les fractions `17661#1311` et `17661#1349` commencent au 1992-03-22 : la date est juste ;
  - `unit_version` n'a aucun nom pour 1311 de 1941 à 1999, puis « Istres-Nord » ; aucun nom pour
    1349 avant 1999. Il faudrait « Istres » jusqu'au 1992-03-22, puis « Istres-Nord » et
    « Istres-Sud » dès cette date.
- **À inscrire** : Istres (atome entier), Fos-sur-Mer et Saint-Mitre-les-Remparts dans 1311 de
  1973-09-23 à 1992-03-22 ; Miramas dans 1332 puis 1311 selon le texte à trouver ; les noms
  ci-dessus.
- **Ligne** : `13047-1` écrite le 7 octobre 2026 (1992-03-22 → 2013-01-01, conforme). Aucune
  ligne ne dépend du trou 1973-1992 : la ville n'était pas divisée.

## Martigues (13056)

### 95. FAIT (11 octobre 2026, `sql/112`) — Le canton de Martigues de 1973 à 1992 : Martigues et Port-de-Bouc sans canton ; noms de 1992

- **Inscrit par `sql/112_villes_date_du_decret.sql`** : Martigues et Port-de-Bouc dans 1325 du 1973-09-23 au 1992-03-22 ; le nom « Martigues-Est » pour 1325 du 1992-03-22 au 1999-01-01.
- **Reste** : les huit autres communes de l'ancien canton (Marignane, Saint-Victoret, Carry-le-Rouet, Châteauneuf-les-Martigues, Ensuès-la-Redonne, Gignac-la-Nerthe, Le Rove, Sausset-les-Pins), sans canton de 1973 à 1992 : décret 73-812 à relire.

Ce qui suit est l'entrée telle qu'elle était avant l'inscription.

- **Source** : décret n° 91-209 du 27 février 1991 (JO du 28 février 1991, p. 2900-2901,
  `jorf_txt/JORF_19910228_51_col.txt`), art. 5 : création de Martigues-Ouest (Port-de-Bouc et
  l'ouest de Martigues) ; « le canton de Martigues est modifié par voie de conséquence et prend
  la dénomination de Martigues-Est ». Effet au renouvellement de mars 1992. Pour 1973 : décret
  n° 73-812 du 16 août 1973 (JO du 17 août 1973, `jorf_txt/JORF_19730817_190_col.txt`, art. 2
  et 3) : création de Marignane par division de Martigues, « les limites du canton de Martigues
  sont modifiées par voie de conséquence ».
- **Base** :
  - l'atome entier `21437` (Martigues) et Port-de-Bouc (`27653`) sont dans 1325 jusqu'au
    1973-09-23, puis **n'ont aucun canton jusqu'au 1992-03-22** ;
  - les fractions `21437#1325` et `21437#1350` commencent au 1992-03-22 : la date est juste ;
  - `unit_version` n'a aucun nom pour 1325 de 1941 à 1999 (puis « Martigues-Est ») ; aucun nom
    pour 1350 avant 1999.
- **À inscrire** : Martigues (atome entier) et Port-de-Bouc dans 1325 de 1973-09-23 à
  1992-03-22 ; noms « Martigues » jusqu'au 1992-03-22, puis « Martigues-Est » (1325) et
  « Martigues-Ouest » (1350) dès cette date.
- **Ligne** : `13056-1` écrite le 7 octobre 2026 (1992-03-22 → 2013-01-01, source `texte`,
  conforme) ; ancres `21437#1350` = POINT(863500 6259500), `21437#1325` = POINT(866500 6260500)
  et POINT(866792 6253859). Aucune ligne ne dépend du trou 1973-1992 : la ville n'était pas
  divisée. À confirmer sur plan : la « bretelle d'accès direct » (4,99 ha en jeu avec l'avenue
  du Moulin-de-France) et le chemin du Maroc (1,8 ha).

## Ussel (19275)

### 99. FAIT (11 octobre 2026, `sql/112`) — Ussel de 1955 à 1985 : la ville sans canton, et le nom d'Ussel-Est

- **Inscrit par `sql/112_villes_date_du_decret.sql`** : l'atome 38492 dans 1927 du 1955-01-01 au 1985-03-10 ; Chaveroche, Lignareix, Saint-Angel et Saint-Pardoux-le-Vieux dans 1927 du 1982-03-14 au 1985-03-10 ; le nom « Ussel-Est » du 1985-03-10 au 1999-01-01. Bascule au 1985-03-10, règle des recompositions.
- **Reste** : Saint-Dézery et La Tourette, fusionnées, qui gardent une appartenance propre ; la lecture non tranchée de la limite de Saint-Dézery.

Ce qui suit est l'entrée telle qu'elle était avant l'inscription.

- **Source** : décret n° 85-129 du 29 janvier 1985 (JO du 30 janvier 1985, p. 1275 déduite des
  en-têtes voisins, `jorf_txt/JORF_19850130_25_col.txt`, l. 2510-2528), art. 2 ;
  `cantons/mouvements_cantonaux.csv` l. 315-316.
- **Base** :
  - l'atome entier 38492 est dans 1927 « Ussel » jusqu'au 1955-01-01, puis dans rien jusqu'au
    1985-03-10 ;
  - Chaveroche (9026), Lignareix (19527), Saint-Angel (30432) et Saint-Pardoux-le-Vieux (33945)
    sont dans 1927 jusqu'au 1982-03-14, puis dans rien jusqu'au 1985-03-10 (1937 Ussel-Ouest
    ensuite) ;
  - Saint-Dézery (31183) et La Tourette (37851), fusionnées en 1972 et 1976 d'après l'ANR,
    gardent une appartenance propre à 1927 jusqu'au 1982-03-14 ;
  - `38492#1927` s'appelle « Ussel » de 1985 à 1999 et « Ussel-Est » seulement depuis 1999,
    alors que le décret dit « prend la dénomination d'Ussel-Est » dès 1985.
- **À inscrire** : l'atome 38492 dans 1927 de 1955 à 1985 ; les quatre communes rurales dans
  1927 de 1982-03-14 à 1985-03-10 ; le nom Ussel-Est dès 1985 ; décider si la bascule est au
  décret (1985-01-29) ou au 1985-03-10.
- **Lignes** : `19275-1` (limite de Saint-Dézery) et `19275-2` (C.D. 159 … Sarsonne … R.N. 89)
  écrites le 7 octobre 2026 (1985-03-10 → 2013-01-01, source `texte`, conformes) ; ancres
  `38492#1937` = `POINT(644500 6495000)`, `38492#1927` = `POINT(647500 6493000)` et
  `POINT(648700 6498200)` (Saint-Dézery).
- **Lecture non tranchée** : Saint-Dézery (367,9 ha) est à Ussel-Est si « la limite de la
  commune associée » est sa limite intérieure (lecture écrite). Si c'est son bord extérieur,
  retirer `19275-1` et la seconde ancre de `#1927` : Ussel-Ouest passe de 3 067,8 à 3 435,7 ha.

## Cognac (16102)

### 105. Cognac de 1955 à 1982 : la ville sans canton, puis sous Confolens-Sud, puis sans fraction jusqu'en 1982

- **Inscrit par `sql/114_villes_lot_2.sql` (13 octobre 2026)** : la ville dans 1613 de 1955 à 1973 (retirée de Confolens-Sud), les deux fractions dès 1973, les noms. Reste : Reignac.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Source** : décret n° 73-654 du 13 juillet 1973 (JO du 17 juillet 1973, art. 2 ;
  `jorf_txt/JORF_19730717_164_col.txt`, l. 1232-1250 ; `cantons/communes_coupees_1973_1984.csv`,
  l. 20-21) : « Le canton de Cognac est divisé en deux cantons », Cognac-Nord (Cherves-de-Cognac,
  Boutiers, Saint-Sulpice, Saint-Brice, Bréville, Mesnac, Richemont et une portion de Cognac) et
  Cognac-Sud (Châteaubernard, Merpins, Javrezac, Saint-Laurent, Ars, Louzac, Gimeux, Saint-André
  et le reste de Cognac). `cantons/chronologie_cantonale.csv` : 1973-07-13.
- **Base** (atome `9804`) :
  - 1815-1955 : dans 1613 (Cognac) ;
  - 1955-1968 : **aucun canton** ;
  - 1968 → 1973-09-23 : **dans 1615 (Confolens-Sud)** ;
  - 1973-09-23 → 1982-03-14 : **rien** (ni l'atome, ni les fractions), alors que les communes
    rurales sont réparties entre 1613 et 1633 dès le 1973-09-23 ;
  - à partir du 1982-03-14 : `9804#1613` et `9804#1633` ; 1613 s'appelle « Cognac » jusqu'en 1999
    (`unit_version` n'a « Cognac-Nord » et « Cognac-Sud » qu'à partir de 1999).
  - Aussi : Javrezac (atome 17815) absente de 1613 de 1955 à 1973, et dans 1615 de 1968 à 1973 ;
    Reignac (canton de Baignes) dans 1613 de 1968 à 1973.
- **À inscrire** :
  - `9804` dans 1613 de 1955 au 1973-09-23, à la place de 1615 en 1968-1973 ;
  - `9804#1613` et `9804#1633` dès le 1973-09-23 (aujourd'hui 1982-03-14) ;
  - les noms Cognac-Nord (1613) et Cognac-Sud (1633) dès le 1973-09-23 ;
  - à vérifier : Javrezac 1955-1973, Reignac 1968-1973.
- **Ligne** : `16102-1` écrite le 13 octobre 2026 (1973-09-23 → 2013-01-01, source `texte`,
  conforme au 1982-03-14) ; ancres datées `9804#1613` POINT(440985.47 6517020.4), 836,5 ha, et
  `9804#1633` POINT(440324.55 6515296.2), 652,4 ha. `carte_coupe_ville` la tire déjà en 1975 par
  les ancres datées. Logements BD TOPO au Nord 48,7 %, population INSEE 2011 de la fraction Nord
  47,0 % (8 746 / 9 865). Travail : `cartes/sorties/decoupe_cognac/`.
- **Lectures non tranchées** : (a) « pont de Crouin » pris pour le pont de la D941 sur la
  Charente, « rivière la Charente » pour le bras est : l'île entre canal et rivière (21,3 ha,
  90 logements) est au Nord, elle irait au Sud si la rivière du texte était le canal ; (b) « rue
  des Allées » prise pour l'allée Bernard-Guionnet d'après le décret n° 2014-195, lu sur
  Wikipédia et non collationné sur Légifrance (2,3 ha et 26 logements en jeu avec les allées de
  la Corderie) ; (c) le régime de 2015 a une autre limite à Crouin (îlots de 2,6 et 1,7 ha).

## Confolens (16106)

### 106. Confolens-Nord et Confolens-Sud : deux fractions en continu de 1802 à 2015 ; Abzac sans canton de 1955 à 1982

- **Inscrit par `sql/114_villes_lot_2.sql` (13 octobre 2026)** : les deux fractions sur 1941-1968 et 1973-1982 ; Abzac dans 1615 de 1955 à 1982 ; Javrezac dans 1613 de 1955 à 1973. Reste : rien.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Source** : arrêté du 9 pluviôse an X (29 janvier 1802), Bulletin des lois (Gallica
  ark:/12148/bpt6k6566855n/f192 ; page fournie en image par Adrien le 13 octobre 2026, collationnée),
  lu d'abord dans Rondonneau, Collection générale des lois, t. 8, p. 696 (archive.org
  bub_gb_A25OAAAAYAAJ, feuillet n754 ; `cartes/sorties/decoupe_confolens/ocr/`) : Confolens (Nord)
  = « la partie de cette commune située sur la rive gauche de la Vienne » + Ansac, Lessac,
  Ambernac, Hiesse, Epenède, Pleuville, Manot ; Confolens (Sud) = « la partie de Confolens située
  sur la rive droite de la Vienne » + Saint-Germain, Abzac, Oradour-Fanais, Brillac, Esse,
  Lesterps, Saint-Christophe, Montrollet, Saint-Maurice, Brigueil. Aucun acte ensuite avant le
  décret de 2014 (`cantons/chronologie_cantonale.csv`). INSEE, populations légales de la
  Charente : 1 360 (Nord) et 1 351 (Sud) habitants en 2010.
- **Base** : `10142#1614` et `10142#1615` sur 1815-1941, 1968 → 1973-09-23 et 1982-03-14 → 2013 ;
  rien de 1941 à 1968 ni du 1973-09-23 au 1982-03-14. Abzac (atome 55) n'a aucun canton du
  1955-01-01 au 1982-03-14. Cognac (9804) et Javrezac (17815) sont dans l'unité 1615
  « Confolens-Sud » du 1968-01-01 au 1973-09-23 (voir n° 105).
- **À inscrire** : les deux fractions sur 1941 → 1968 et 1973-09-23 → 1982-03-14 ; Abzac dans 1615
  sur 1955 → 1982-03-14 ; Cognac et Javrezac hors de 1615 en 1968-1973.
- **Ligne** : `16106-1` écrite le 13 octobre 2026 (1815-01-01 → 2013-01-01, source `texte`, axe de
  la Vienne, 2 879 m, conforme) ; ancres non datées `10142#1614` POINT(519685 6549141) (rive
  gauche, Saint-Barthélemy, 1 192,0 ha), `10142#1615` POINT(520010 6548734) (rive droite,
  Saint-Maxime, 708,0 ha). Elle se tirera dans les trous dès que les appartenances y seront.

## Rochefort (17299)

### 107. Rochefort : fractions trop tôt (1815-1852), absentes de 1941 à 1985, atome entier au Nord en 1968-1973, Sud vidé de ses communes en 1973

- **Inscrit par `sql/117_creations_caen_rochefort_bourg_larochelle.sql` (13 octobre 2026, accord d'Adrien)** : point (a) : unité `C17-Rochefort` créée, la ville entière et ses sept communes y sont de 1815 au 1852-06-29 ; les fractions et les communes ne commencent dans Rochefort-Nord et -Sud qu'à cette date. Reste : (d) Yves, (e) les noms.

- **Inscrit par `sql/114_villes_lot_2.sql` (13 octobre 2026)** : points (b) et (c) : les deux fractions de 1941 à 1985 (l'atome entier retiré), Fouras, Saint-Laurent-de-la-Prée, Vergeroux et l'Île-d'Aix dans 1722 jusqu'en 1985. Reste : (a) avant 1852, (d) Yves, (e) les noms.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Sources** : loi du 29 juin 1852 (Bulletin des lois, Xe série, t. 9, bull. 546, n° 4177, p. 1529 ;
  Gallica ark:/12148/bpt6k486128d/f1578, collationnée le 13 octobre 2026 sur l'image fournie par
  Adrien ; lue d'abord sur l'OCR archive.org bub_gb_KEmBvs4jnukC, extrait dans `cartes/sorties/decoupe_rochefort/ocr/`) : Nord = section
  urbaine nord + Breuil-Magné, Loire ; Sud = section urbaine sud + Saint-Laurent-de-la-Prée,
  Fouras, Île-d'Aix, Yves, Vergeroux. Décret n° 85-128 du 29 janvier 1985, art. 2
  (`jorf_txt/JORF_19850130_25_col.txt`, l. 2362-2421) : « en remplacement des cantons de
  Rochefort-Nord et Sud », Centre (fraction seule), Nord (Breuil-Magné, Fouras, Île-d'Aix,
  Loire-les-Marais, Saint-Laurent-de-la-Prée, Vergeroux, Yves + fraction), Sud (fraction seule).
  `cantons/chronologie_cantonale.csv` : rien entre 1852 et 1985.
- **Base** : `29352#1721` et `29352#1722` de 1815 à 1941 puis du 1985-03-10 à 2013 ; atome entier
  `29352` dans 1721 de 1968 au 1973-09-23 ; rien de 1941 à 1968 ni de 1973-09-23 à 1985-03-10.
  Fouras, Saint-Laurent-de-la-Prée, Vergeroux : dans 1722 jusqu'au 1973-09-23, puis sans canton
  jusqu'au 1985-03-10. Île-d'Aix : sans canton de 1941 à 1985. Yves : dans 1722 jusqu'en 1941,
  dans 1721 dès 1968. Noms de 1721 et 1722 absents de `unit_version` de 1941 à 1999, celui de
  1747 avant 1999.
- **À inscrire** : (a) avant le 29 juin 1852, un seul canton de Rochefort (la ville entière et les
  sept communes) : les deux fractions ne commencent qu'en 1852 ; (b) les deux fractions en continu
  de 1852-06-29 à 1985-03-10, sans l'atome entier en 1968-1973 (artefact du COG) ; (c) Fouras,
  Île-d'Aix, Saint-Laurent-de-la-Prée, Vergeroux dans Rochefort-Sud jusqu'au 1985-03-10 (aucun
  acte en 1973) ; (d) Yves : Sud d'après la loi de 1852, Nord dans la base dès 1968 — à
  vérifier ; (e) les noms.
- **Lignes écrites** le 13 octobre 2026 : `17299-1985-nord` et `17299-1985-sud` (1985-03-10 →
  2013-01-01, source `texte`, conformes), ancres datées `29352#1721` POINT(393738 6547733),
  525,1 ha ; `29352#1747` POINT(393100 6545400), 574,7 ha ; `29352#1722` POINT(391671 6544819),
  1 098,7 ha. INSEE 2011 : 11,7 / 46,8 / 41,5 % ; logements BD TOPO : 10,4 / 48,3 / 41,3 %.
  Lecture non tranchée : raccord avenue William-Ponty / rue des Broussailles par le quai de la
  Louisiane (écrit) ou la rue d'Orléans (`var_p2_orleans.wkt`, 3,0 ha et 23 logements de plus
  au Centre).
- **Ligne écrite** le 13 octobre 2026 : `17299-1852` (1852-06-29 → 1985-03-10, source `texte`,
  conforme), ancres datées `29352#1721` POINT(393150 6545350), 917,1 ha, et `29352#1722`
  POINT(393150 6544750), 1 281,5 ha. Texte collationné sur la page du Bulletin fournie par Adrien.
  `carte_coupe_ville` la tire en 1852, 1900, 1940 et, par les ancres datées, en 1970.
  Lectures non tranchées : (1) « le côté nord de la grande rue du faubourg, en deçà de la route
  de Saint-Malo » — ce qui est au-delà de la route et au nord du faubourg est donné au Sud ;
  l'autre lecture, non tracée, déplace de l'ordre de 365 ha ; (2) « rue de la République » de
  1852 = avenue Charles-de-Gaulle (ancienne rue Royale, d'après Thomas 1828 et Viaud 1845),
  l'avenue La Fayette déplaçant 2,7 ha et 230 logements (`var_a_lafayette_texte.wkt`).

## Saintes (17415)

### 108. Saintes : fractions absentes de 1941 à 1968 et de 1973 à 1985, communes rurales sans canton, nom de 1735 de 1985 à 1999

- **Inscrit par `sql/114_villes_lot_2.sql` (13 octobre 2026)** : les deux fractions sur 1941-1968 et 1973-1985, les neuf communes rurales, le nom Saintes-Ouest dès 1985. Reste : rien en base.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Sources** : arrêté du 27 brumaire an X (18 novembre 1801), Bulletin des lois, 3e série, n° 146,
  n° 1126 (lu sur l'image de Rondonneau, Collection générale des lois, t. 8, p. 577-578, archive.org
  bub_gb_A25OAAAAYAAJ, feuillets n635-n636, copies dans `cartes/sorties/decoupe_saintes/ocr/` ;
  Gallica ark:/12148/bpt6k6515730s/f37 À COLLATIONNER) : la ville divisée « par la route de
  Rochefort […] en suivant la rue de la Commune, celle de la Préfecture, jusqu'à la rivière, au
  port appelé le Petit-Saint-Jean », gauche = Nord (Bussac, Chaniers, La Chapelle-des-Pots, Le
  Douhet, Fontcouverte, Saint-Vaize, Vénérand), droite = Sud (Chermignac, Colombiers, Courcoury,
  Écurat, Saint-Georges, Les Gonds, La Jard, Nieul, Pessines, Préguillac, Thénac, Varzay).
  Décret n° 85-128 du 29 janvier 1985, art. 3 (`jorf_txt/JORF_19850130_25_col.txt`, l. 2423-2457) :
  « en remplacement des cantons de Saintes-Nord et Sud », Est, Nord, Ouest.
  `cantons/chronologie_cantonale.csv` : rien entre l'an X et 1985.
- **Base** : `31580#1734` (Nord) et `31580#1735` (Sud) de 1815 à 1941, de 1968 au 1973-09-23, puis
  du 1985-03-10 à 2013 ; `31580#1751` (Est) du 1985-03-10 à 2013 ; rien de 1941 à 1968 ni du
  1973-09-23 au 1985-03-10 (aucun acte en 1973 pour Saintes). Communes rurales (`membership`,
  relevé du 13 octobre 2026) : sans canton du 1973-09-23 au 1985-03-10, Chaniers, La
  Chapelle-des-Pots (1734), Colombiers, Courcoury (1735) ; sans canton de 1955 au 1985-03-10,
  Saint-Vaize (1734), Écurat, Thénac, La Jard, Les Gonds (1735). `unit_version` nomme 1735
  « Saintes-Sud » de 1985 à 1999 et « Saintes-Ouest » ensuite.
- **À inscrire** : (a) les deux fractions en continu de l'an X (ou 1815) au 1985-03-10 ; (b) les
  neuf communes rurales ci-dessus dans leur canton de l'an X jusqu'au 1985-03-10 ; (c) le nom
  « Saintes-Ouest » pour 1735 dès le 1985-03-10.
- **Lignes écrites** le 13 octobre 2026 : `17415-1801` (1801-11-18 → 1985-03-10, source `texte`,
  conforme), ancres datées `31580#1734` POINT(417750 6523870), 2 223,1 ha, et `31580#1735`
  POINT(415350 6521270), 2 360,9 ha ; `17415-1985-est` et `17415-1985-ouest` (1985-03-10 →
  2013-01-01, source `texte`, conformes), ancres datées `31580#1751` POINT(419100 6521750),
  798,5 ha ; `31580#1734` POINT(417000 6524950), 1 659,9 ha ; `31580#1735` POINT(414750 6520870),
  2 125,7 ha. INSEE 2011 : 27,5 / 41,3 / 31,1 % ; logements BD TOPO : 27,9 / 43,7 / 28,4 %.
  Lectures non tranchées : (1) la rive droite en 1801, que le texte ne nomme pas, donnée au Nord
  par la Charente vers l'amont (1 029 ha, 5 425 logements actuels ; appui : le décret de 1985
  borne Saintes-Ouest par le même tronçon de Charente et tire Saintes-Est de Saintes-Nord) ;
  (2) « chemin vicinal 17 » de 1985 = rue de la Côte-de-Beauté (environ 19 ha et 8 logements en
  jeu par la rue du Champ-de-Tir et la rue de Bellegarde, variante non tracée) ; (3) de la rue de
  la Préfecture au Petit-Saint-Jean par la rue Saint-Maur et la place Blair (1,7 ha, 42 logements
  par la rue Monconseil, `var_1801_monconseil.wkt`).

## Bourges (18033)

### 109. Bourges de 1973 à 1982 : quatre cantons sans fraction, et quatre communes voisines sans canton

- **Inscrit par `sql/114_villes_lot_2.sql` (13 octobre 2026)** : les quatre fractions de 1973 à 1982, les noms Bourges-I à V, Saint-Doulchard, La Chapelle-Saint-Ursin et Marmagne dans 1820, Fussy dans 1823. Reste : les lectures à confirmer.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Sources** : décret n° 73-764 du 2 août 1973 (JO du 4 août 1973, p. 8534 ;
  `jorf_txt/JORF_19730804_180_col.txt`, l. 2313-2420) : Bourges-I à IV, la ville seule ;
  décret n° 82-52 du 20 janvier 1982 (JO du 22 janvier 1982, p. 335 ;
  `jorf_txt/JORF_19820122_18_col.txt`, l. 245-300) : Bourges-V détaché de Bourges-I (art. 1er),
  canton de Saint-Doulchard (Saint-Doulchard, La Chapelle-Saint-Ursin, Marmagne) détaché de
  Mehun-sur-Yèvre (art. 2). Copie : `cartes/sorties/decoupe_bourges/sources.txt`. Textes lus sur
  l'OCR du JO, non collationnés sur Légifrance.
- **Base** : atome entier `5289` dans 1805 de 1815 au 1973-09-23 ; **aucune appartenance
  cantonale de Bourges du 1973-09-23 au 1982-03-14** ; cinq fractions `5289#1805`, `#1831`,
  `#1832`, `#1833`, `#1834` du 1982-03-14 à 2013, justes (attribution par le texte, contacts
  vérifiés). `unit_version` : 1805 n'a pas de nom entre 1941 et 1999 (le repli donne « Bourges »
  de 1982 à 1999, alors que c'est Bourges-I depuis 1973) ; 1831 à 1834 n'ont de version qu'à
  partir de 1999. Saint-Doulchard (31231), La Chapelle-Saint-Ursin (8331) et Marmagne (21269)
  n'ont aucun canton du 1973-09-23 au 1982-03-14 (Mehun-sur-Yèvre, 1820, jusqu'en 1982) ;
  Fussy (14943) n'en a aucun de 1955 à 1982 (Saint-Martin-d'Auxigny, 1823).
- **À inscrire** : `5289#1805` (I), `#1831` (II), `#1832` (III), `#1833` (IV) sur
  1973-09-23 → 1982-03-14 ; noms Bourges-I à IV dès 1973, Bourges-V dès le 1982-03-14 ; les trois
  communes dans 1820 de 1973 à 1982 ; Fussy dans 1823 de 1955 à 1982.
- **Lignes écrites** le 13 octobre 2026 : `18033-1` à `-3` (1973-09-23 → 1982-03-14,
  `--morceaux 4`, régime absent de la base), ancres datées `5289#1805` = POINT(654500 6668500),
  1 470,6 ha ; `#1831` = POINT(656500 6664000), 1 894,4 ha ; `#1832` = POINT(654500 6661500),
  2 603,2 ha ; `#1833` = POINT(652000 6665000), 888,2 ha ; `18033-4` à `-7` (1982-03-14 →
  2013-01-01, conformes), mêmes ancres plus `#1834` = POINT(656000 6666000), 472,7 ha, le I
  réduit à 997,9 ha. Les ancres de 1973 joueront dès que les fractions existeront. INSEE 2011 :
  13,5 / 18,4 / 29,8 / 22,4 / 16,0 % ; logements BD TOPO : 11,2 / 19,8 / 28,1 / 24,9 / 16,1 %.
- **Reste** : la « jonction en aval » de l'Auron et du canal de Berry, le choix du chenal (4,5 ha,
  2 logements), le carrefour du Beugnon, les 392 m de l'ancienne voie Bourges-Gien et la sortie
  est de la RN 151 (chaussée ou contre-allée, 3 à 4 ha) sont des lectures ; le plan annexé aux
  décrets (préfecture du Cher) les trancherait.

## La Rochelle (17300)

### 110. La Rochelle : fractions de 1985 accrochées à Laleu, régimes de 1973 et 1982 absents, Est / Ouest absents de 1941 à 1973, Cognehors et Saint-Maurice sans atome

- **Inscrit par `sql/117_creations_caen_rochefort_bourg_larochelle.sql` (13 octobre 2026, accord d'Adrien)** : points (a) et (c) : les neuf fractions de 1985 passent de l'atome de Laleu (`18407`) à celui de La Rochelle (`29365`), ancres comprises ; cantons I à IV de 1973 et I à VI de 1982 posés par numéro (I = 1723 … VI = 1745). Par `sql/116` : Est / Ouest de 1941 à 1973, l'atome entier de Laleu retiré. Reste : les communes rurales de 1973 et 1982, (d) Cognehors et Saint-Maurice, (e) les noms, le plan de 1858.

- **Sources** : arrêté du 27 brumaire an X (Bulletin des lois, 3e série, bull. 146, n° 1126 ; lu sur
  l'image de Rondonneau, Collection générale des lois, t. 8, p. 575-576, archive.org
  bub_gb_A25OAAAAYAAJ, `cartes/sorties/decoupe_larochelle/ocr/` ; Gallica
  ark:/12148/bpt6k6515730s/f37 À COLLATIONNER) : Est = Angoulins, Aytré, Cognehors, Dompierre,
  Lagord, Périgny, La Rochelle (part sud) ; Ouest = Esnandes, L'Houmeau, Laleu, Marsilly,
  Saint-Maurice, Nieul, La Rochelle (part nord), Saint-Xandre. Loi du 21-29 mai 1858 (Bulletin des
  lois, XIe série, bull. 605, n° 5607 ; lue sur l'OCR SEUL de Duvergier, archive.org
  bub_gb_BtUxAAAAIAAJ, NON COLLATIONNÉE) : Saint-Maurice et Cognehors supprimées, partagées entre
  La Rochelle, Laleu, Lagord, Périgny, Dompierre ; Puilboreau créée ; art. 3, la situation
  cantonale reste la même, sauf la section 6 de Saint-Maurice passée à Lagord (canton Est).
  Décrets 73-655 (JO du 17 juillet 1973), 82-26 (JO du 16 janvier 1982), 85-128 (JO du 30 janvier
  1985), tous dans `jorf_txt/`.
- **Base** : `29365` (La Rochelle) porte `29365#1723` et `#1724` de 1815 à 1941, rien ensuite.
  `18407` (Laleu, ANR close en 1880) porte l'atome entier dans 1723 de 1968 au 1973-09-23, puis
  les neuf fractions `18407#1723` … `#1750` du 1985-03-10 à 2013. Aucune fraction de 1941 à 1968
  ni du 1973-09-23 au 1985-03-10. Lagord, L'Houmeau, Nieul : dans 1750 dès le 1982-03-14 (ils
  étaient du canton I de 1982) ; L'Houmeau, Saint-Xandre sans canton de 1955 à 1982 ; aucune
  commune rurale du 1973-09-23 à 1982. Cognehors et Saint-Maurice n'ont pas d'atome : 1 219 ha
  sans commune avant 1858. Noms de 1723 et 1724 de 1985 à 1999 : « La Rochelle-Est » et
  « La Rochelle-Ouest » (ce sont La Rochelle-I et II).
- **À inscrire** : (a) les neuf fractions de 1985 sur l'atome de La Rochelle (`29365`) et non de
  Laleu, ou dire pourquoi ; (b) Est / Ouest en continu de 1801 au 1973-09-23, sans l'atome entier
  de 1968-1973 ; (c) les cantons I à IV de 1973 et I à VI de 1982, avec leurs communes (1973 : II
  = Dompierre, Esnandes, Lagord, L'Houmeau, Marsilly, Nieul, Puilboreau, Saint-Xandre ; IV =
  Angoulins, Aytré, Châtelaillon, Périgny ; 1982 : I = L'Houmeau, Lagord, Nieul ; V = Esnandes,
  Marsilly, Saint-Xandre, Puilboreau, Dompierre, Périgny ; VI = Aytré, Angoulins, Châtelaillon) ;
  décider sous quels codes (les ancres de 1973 et 1982 sont posées par numéro de canton, I = 1723,
  II = 1724, III = 1741, IV = 1742, V = 1744, VI = 1745 : à réécrire si la base choisit les codes
  des successeurs) ; (d) les communes de Cognehors (Est) et de Saint-Maurice (Ouest) jusqu'en
  1858, Puilboreau créée en 1858 ; (e) les noms.
- **Lignes écrites** le 13 octobre 2026 (commandes dans
  `cartes/sorties/decoupe_larochelle/commandes.sh`) : `17300-1985-A` à `-H` (1985-03-10 → 2013,
  source `texte`, conformes), ancres datées `18407#1723` POINT(376500 6570600), 712,6 ha ; `#1724`
  POINT(377000 6571800), 118,5 ha ; `#1741` POINT(378700 6571600), 155,4 ha ; `#1742`
  POINT(378800 6570700), 279,9 ha ; `#1744` POINT(380500 6572200), 135,3 ha ; `#1745`
  POINT(380000 6569000), 543,9 ha ; `#1748` POINT(381200 6571200), 336,8 ha ; `#1749`
  POINT(382300 6569800), 89,2 ha ; `#1750` POINT(375500 6572500), 640,0 ha ; `17300-1982-A` à `-F`
  (1982-03-14 → 1985-03-10, `--morceaux 6`, régime absent) ; `17300-1973-A` à `-C` (1973-09-23 →
  1982-03-14, `--morceaux 4`, régime absent) ; `17300-1858-ville` et `17300-1858-nord` (1858-01-01
  → 1973-09-23, source `main`) ; `17300-an10` (1801-11-18 → 1858-01-01, source `texte`), ancres
  `29365#1723` POINT(379650 6570560) et `29365#1724` POINT(379700 6570950).
- **`17300-1858-nord` est une HYPOTHÈSE, pas un texte** : la limite Saint-Maurice / Cognehors, de
  l'enceinte à Lagord, est sur le plan annexé à la loi de 1858, qui n'a pas été vu ; le tracé
  retenu est celui du décret de 1973 (avenue du 11-Novembre-1918, Champ-de-Mars, Porte-Dauphine,
  1 037 m). Si c'était le ruisseau de Lafond, plusieurs dizaines d'hectares de Fétilly
  changeraient de côté (non chiffré). À réécrire au vu du plan ou du cadastre (AD 17).
  `17300-1858-ville` est la ligne de l'an X prolongée par l'ancien contour communal (ANR
  1790-1858), lecture de l'art. 3 ; ce contour passe jusqu'à 320 m à l'ouest du chemin des
  Remparts (au plus 43,7 ha et 244 logements en jeu).
- **Lectures non tranchées** : rocade Nord / avenue Raymond-Poincaré en 1982, reliées par la voie
  non dénommée du décret de 1985 (l'autre lecture : 29 ha, 500 logements de Laleu vers le III) ;
  chemin rural 7 et chemin vicinal 16 en 1982 (non identifiés, ligne finie par la rue de la
  Tour-Carrée) ; La Faucherie (12,4 ha, sans logement) ; jonction de la gare des marchandises et
  quai du bassin à flot extérieur (1973, 1982) ; viaduc et môle d'escale au canton I en 1985
  (18,6 ha) ; Laleu réunie en 1880, supposée restée à l'Ouest (texte de la réunion non lu).

---

## Vierzon (18279)

### 111. Vierzon de 1973 à 1982 : la ville sans canton, ses communes rurales déjà dans Vierzon-II

- **Inscrit par `sql/124_villes_lot_3.sql` (23 octobre 2026)** : `39847#1829` et `#1830` du 1973-09-23 au 1982-03-14 ; noms Vierzon-I et Vierzon-II de 1973 à 1999. Reste : la place de la République et la concordance rue Romain-Rolland = rue des Ponts.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Sources** : décret n° 73-764 du 2 août 1973, art. 2 et 3 (JO du 4 août 1973, p. 8534-8535 ;
  `jorf_txt/JORF_19730804_180_col.txt`, l. 2421-2453 ; `cantons/communes_coupees_1973_1984.csv`) :
  le canton de Vierzon est divisé en Vierzon-I (la ville seule, au nord de la ligne) et Vierzon-II
  (Nançay, Neuvy-sur-Barangeon, Vouzeron, Saint-Laurent, Vignoux-sur-Barangeon, Massay,
  Saint-Hilaire-de-Court, Méry-sur-Cher, Thénioux et le reste de la ville) ; Saint-Laurent passe
  de Mehun-sur-Yèvre à Vierzon-II (art. 3). Aucun autre texte jusqu'au décret n° 2014-206.
  Copie : `cartes/sorties/decoupe_vierzon/sources.txt`. Texte lu sur l'OCR du JO.
- **Base** : atome entier `39847` dans 1829 de 1815 au 1973-09-23 ; **aucune appartenance
  cantonale de Vierzon du 1973-09-23 au 1982-03-14** ; fractions `39847#1829` et `#1830` du
  1982-03-14 à 2013, justes (1830 porte les neuf communes rurales du texte dès le 1973-09-23 ;
  1829 n'en porte aucune, comme le texte). `unit_version` : 1829 n'a pas de nom de 1941 à 1999
  (le repli donne « Vierzon » de 1982 à 1999, alors que c'est Vierzon-I depuis 1973) ; 1830 n'a
  de version qu'à partir de 1999.
- **À inscrire** : `39847#1829` (Vierzon-I) et `39847#1830` (Vierzon-II) sur 1973-09-23 →
  1982-03-14 ; noms Vierzon-I et Vierzon-II dès le 1973-09-23 (« 1er Canton », « 2e Canton » du
  COG de 1999 = les mêmes unités).
- **Ligne écrite** le 16 octobre 2026 : `18279-1` (1973-09-23 → 2013-01-01, conforme au 1990-01-01), ancres non
  datées `39847#1829` = POINT(630000 6685000), 5 702,5 ha ; `39847#1830` = POINT(629500 6678500),
  1 761,9 ha. Les mêmes ancres joueront de 1973 à 1982 quand les fractions y seront.
- **Reste** : la « place de la République » (prolongement de l'ancien canal) n'est pas localisée,
  l'axe du canal est suivi jusqu'à la rue des Ponts ; la concordance rue Romain-Rolland = rue des
  Ponts vient d'un site d'histoire locale (vierzonitude.fr), à confirmer (plan annexé au décret,
  préfecture du Cher, ou délibération municipale).

## Dinan (22050)

### 112. Dinan : fraction fantôme `11851#2219` (« Lannion ») en 1968-1982, Caouënnec absente de Lannion ; trou 1941-1968

- **Inscrit par `sql/124_villes_lot_3.sql` (23 octobre 2026)** : `11851#2219` retiré (1968-1982) ; `#2211` et `#2212` de 1941 à 1968. Caouënnec était déjà dans 2219 (`120`). `17035#2219` (L'Hermitage-Lorge dans Lannion) retiré aussi, avec `17035#2234`, qui doublait l'atome entier dans 2234 : même défaut du COG de 1968. Reste : rien.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Source** : arrêté des consuls du 5 brumaire an X (27 octobre 1801), Bulletin des lois, 3e série,
  B. 125, n° 967 (selon Rondonneau ; Wikipédia donne « n° 225 ») ; lu sur l'image dans Rondonneau,
  Collection générale des lois, t. 8 (1818), p. 482-484 (archive.org bub_gb_A25OAAAAYAAJ, feuillets
  n540-n542 ; `cartes/sorties/decoupe_dinan/sources/`). Deux justices de paix, Dinan (Est) = le midi
  de la ville + Saint-Hélen, Lanvallay, Léhon, Pleudihen, Saint-Solain, Tressaint ; Dinan (Ouest) =
  le nord + Aucaleuc, Bobital, Brusvily, Calorguen, Saint-Carné, le Hinglé, Plouër, Quévert,
  Saint-Samson, Taden, Trélivan, Trévron. Aucun acte ensuite pour la ville avant le décret 2014-150
  (`cantons/chronologie_cantonale.csv` : seulement le découpage d'origine). Gallica (Duvergier,
  t. XIII, p. 108, bpt6k54934475/f119) : bloqué (Cloudflare, 16 octobre 2026), non collationné.
  Source du fantôme : `cog1968/communes_1968.600.csv` (et `communes_1968_fusion.csv`, l. 8255) :
  la ligne `22,22050,,050,8,19,Caouënnec,327` porte le code 050 de Dinan au lieu de celui de
  Caouënnec (22030 en GEOFLA) — lecture OCR.
- **Base** : `11851#2211` (Dinan-Est) et `11851#2212` (Dinan-Ouest) sur 1815-1941 et 1968-2013,
  rien de 1941 à 1968. En 1968-01-01 → 1982-03-14, une troisième fraction `11851#2219`, unité 2219
  « Lannion », sans `atom_geom` ; Caouënnec-Lanvézéac (22030) n'a PAS l'unité 2219 sur cette
  période (Lannion : Dinan, Lannion, L'Hermitage-Lorge, Ploubezre, Ploulec'h, Rospez). Le même
  défaut touche peut-être L'Hermitage-Lorge (`17035#2219`, Lannion, 1968-1982, à vérifier). La
  fraction en trop empêche sans doute la règle A de `116` (mêmes fractions au 31 décembre 1940 et
  au 1er janvier 1968) de couvrir Dinan en 1941-1968.
- **À inscrire** : retirer `11851#2219` (1968-01-01 → 1982-03-14) ; mettre Caouënnec (22030) dans
  2219 sur la même période (vérifier dans le COG 1968 imprimé : Caouënnec et Lanvézéac séparées
  avant leur fusion) ; poser `11851#2211` et `#2212` de 1941 à 1968 (même régime de 1801 à 2015).
- **Ligne** : `22050-1801` écrite le 16 octobre 2026 (1801-10-27 → 2013-01-01, source `texte`, 2 337 m, conforme à
  blanc à 1830, 1900, 1990, 2005) ; ancres non datées `11851#2211` POINT(327350 6828300) (midi,
  157,3 ha), `11851#2212` POINT(327400 6829800) (nord, 236,9 ha). En 1968-1982 la recette dira
  « FRACTION SANS ANCRE (base) » pour `#2219` tant qu'elle n'est pas retirée.
- **Écart de population à signaler** (pas une correction de base) : les populations légales 2011
  (Est 4 727, Ouest 6 124) suivent les IRIS (nord 101-104 : 6 146 en 2012), donc toute la ville
  intra-muros à l'Est ; la ligne de l'an X donne à l'Ouest le nord de l'intra-muros (14,1 ha,
  494 logements, environ 600 habitants).

## Brive-la-Gaillarde (19031)

### 113. Brive : la ville entière jusqu'en 1982 malgré Brive-Nord / Brive-Sud (1951), communes rurales trouées, régime 1982-1985 absent, Cosnac et Malemort sans canton en 1982-1985

- **Inscrit par `sql/124_villes_lot_3.sql` (23 octobre 2026)** : `6008` entier dans 1906 arrêté au 1951-09-13 (lignes de 1968-1982 retirées) ; `#1906` et `#1930` de 1951 à 1982, les cinq fractions de 1982 à 1985 ; les sept communes de Brive-Sud dans 1930 du 1951-09-13 au 1954 (le trou 1955-1968 et Cosnac 1982-1985 étaient comblés par `120`) ; Malemort dans 1934 de 1982 à 1985 ; noms Brive-Nord, Brive-Sud (1951-1982), Brive-la-Gaillarde-Nord-Est (1982-1999). Alias de `circo/composition_1958.py` corrigé (Brive-Sud → 1930 seul). Reste : le chemin de Bassaler au Tilleul, le « n° 680 ».
  Ce qui suit est l'entrée d'avant l'inscription.

- **Sources** : décret du 13 septembre 1951 (JO du 14 septembre 1951, p. 9548 ;
  `sources/JORF/JORF_19510914_217.pdf` p. 4 ; `jorf_txt/JORF_19510914_217_col.txt`, l. 553-572) : Brive-Nord
  = la ville au nord de la ligne avenue de Bordeaux … avenue Thiers, « n° 680 », + Dampniat, Ussac,
  Varetz, Venarsal ; Brive-Sud = le reste + Cosnac, La Chapelle-aux-Brocs, Estivals,
  Jugeals-Nazareth, Malemort, Noailles, Nespouls. Décret n° 82-120 du 2 février 1982 (JO du
  4 février 1982, p. 456-457 ; `jorf_txt/JORF_19820204_29_col.txt`, l. 596-668) : Brive-Centre,
  -Nord-Est, -Nord-Ouest, -Sud-Est (+ Cosnac), -Sud-Ouest (+ Noailles, Nespouls, Estivals,
  Jugeals-Nazareth), Malemort (Varetz, Ussac, Malemort, Venarsal, La Chapelle-aux-Brocs,
  Dampniat). Décret n° 85-129 du 29 janvier 1985 (JO du 30 janvier 1985, p. 1275 ;
  `jorf_txt/JORF_19850130_25_col.txt`, l. 2472-2508) : limite Nord-Ouest / Sud-Ouest déplacée.
  Copie : `cartes/sorties/decoupe_brive/sources.txt`, images `sources/jo_*.png`.
- **Base** : atome `6008` entier dans 1906 (« Brives ») de 1815 au 1982-03-14 ; **rien du
  1982-03-14 au 1985-03-10** ; fractions `6008#1906` (NE), `#1930` (SE), `#1931` (Centre),
  `#1932` (NO), `#1933` (SO) du 1985-03-10 à 2013 (`fraction_cog`). Communes rurales :
  Ussac, Dampniat, Varetz, Venarsal dans 1906 jusqu'en 1982 (= Brive-Nord, juste) ; Cosnac,
  Jugeals, Malemort, Noailles, Estivals, Nespouls quittent 1906 le 1951-09-13 mais ne sont dans
  1930 (= Brive-Sud) que sur [1954-01-01, 1955-01-01) et [1968-01-01, 1982-03-14) : **trous
  1951-09-13 → 1954 et 1955 → 1968** ; La Chapelle-aux-Brocs dans 1930 seulement en 1954-1955
  (trou 1955 → 1982). 1982-1985 : Jugeals, Noailles, Estivals, Nespouls → 1933, Ussac, Dampniat,
  Varetz, Venarsal, La Chapelle → 1934 (justes) ; **Cosnac (1930) et Malemort (1934) sans canton
  du 1982-03-14 au 1985-03-10**. `unit_version` : 1906 s'appelle « Brives » jusqu'en 1999
  (Brive-Nord de 1951 à 1982, Brive-Nord-Est ensuite) ; 1930 à 1934 n'ont de nom qu'à partir de
  1999 (1930 = Brive-Sud de 1951 à 1982).
- **À inscrire** : `6008#1906` (Brive-Nord) et `6008#1930` (Brive-Sud) sur 1951-09-13 →
  1982-03-14, à la place de `6008` entier dans 1906 ; combler les trous de 1930 pour les sept
  communes de Brive-Sud (1951-09-13 → 1982-03-14) ; les cinq fractions `6008#1906`, `#1930`,
  `#1931`, `#1932`, `#1933` sur 1982-03-14 → 1985-03-10 ; Cosnac dans 1930 et Malemort dans 1934
  sur 1982-03-14 → 1985-03-10 ; noms Brive-Nord / Brive-Sud (1951-1982), Brive-Nord-Est,
  -Sud-Est, -Centre, -Nord-Ouest, -Sud-Ouest, Malemort (1982-1999).
- **Lignes écrites** le 16 octobre 2026 : `19031-51`
  (1951-09-13 → 1982-03-14, `--morceaux 2`), ancres datées `6008#1906` = POINT(583500 6453500)
  1 498,3 ha, `6008#1930` = POINT(583500 6449500) 3 360,1 ha ; `19031-82-A` à `-H`
  (1982-03-14 → 1985-03-10, `--morceaux 5`) et `19031-85-A` à `-H` (1985-03-10 → 2013-01-01),
  ancres datées NE POINT(585800 6453200), SE POINT(585800 6450500), Centre POINT(584700 6452050),
  NO POINT(583000 6453500), SO POINT(581500 6449000). Surfaces 1982 : NE 558,7, SE 2 110,7,
  Centre 139,8, NO 447,9, SO 1 601,3 ha ; 1985 : NO 766,0, SO 1 283,2 ha (les autres inchangées).
- **Reste** : le « chemin rural de Bassaler au Tilleul (depuis son intersection avec la limite
  communale de Noailles) » ne touche plus Noailles ; prolongé par déduction (Siorat, le Mas) :
  +211,9 ha au Sud-Ouest par la D920, −228,7 ha par Lagorse. « n° 680 » du texte de 1951 non
  identifié. Lotissements Yemaux, Ma Maison et usine Vendôme (1985) identifiés par le cadastre
  actuel. Le plan annexé aux décrets (« plans des lieux », préfecture de la Corrèze) trancherait.

## Guéret (23096)

### 114. Guéret-Nord de 1973 à 1999 : l'unité 2319 garde le nom « Guéret »

- **Inscrit par `sql/124_villes_lot_3.sql` (23 octobre 2026)** : noms « Guéret » (1941-1973) et « Guéret-Nord » (1973-1999) pour 2319. Reste : rien.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Source** : décret n° 73-717 du 23 juillet 1973 (JO du 25 juillet 1973, p. 8079 ;
  `jorf_txt/JORF_19730725_171_col.txt` ; `cantons/communes_coupees_1973_1984.csv`), art. 1er : « le
  canton de Guéret est divisé en trois cantons ». Guéret-Nord = Saint-Fiel, Glénic, Ajain, Jouillat,
  Ladapeyre + la ville au nord de la voie ferrée Bordeaux-Genève ; Guéret-Sud-Ouest = Saint-Victor,
  La Chapelle-Taillefert, Saint-Christophe, Savennes + la ville à l'ouest de l'axe route de Limoges,
  avenues du Limousin, de la Sénatorerie, de Laure, place Arfeuillère, ruisseau des Chers ;
  Guéret-Sud-Est = Sainte-Feyre, Saint-Laurent, La Saunière + le reste. Le décret vise un « plan des
  lieux » déposé à la préfecture de la Creuse (non vu).
- **Base** : fractions `16355#2319`, `#2326`, `#2327` de 1973-09-23 à 2013-01-01, communes rurales
  conformes au décret. Mais l'unité 2319 n'a pas de `unit_version` de 1941 à 1999 (versions :
  « Guéret » 1815-1941, « Guéret-Nord » 1999-2013) : elle s'affiche sous le nom de `unit`,
  « Guéret », de 1973 à 1999.
- **À inscrire** : `unit_version` 2319 « Guéret-Nord » sur [1973-09-23, 1999-01-01) ; « Guéret » sur
  [1941-01-01, 1973-09-23), où le canton est entier.
- **Lignes** : `23096-1` (voie ferrée) et `23096-2` (D940, Limousin, Sénatorerie, Laure, Arfeuillère,
  Chers) écrites le 18 octobre 2026 (1973-09-23 → 2013-01-01, source `texte`) ; ancres non datées
  `16355#2319` POINT(612800 6565500), `#2327` POINT(611800 6562500), `#2326` POINT(613400 6562300).
  Le nom n'affecte pas le tirage.

## Périgueux (24322)

### 115. Périgueux-Centre de 1973 à 1999 : l'unité 2427 garde le nom « Périgueux »

- **Inscrit par `sql/124_villes_lot_3.sql` (23 octobre 2026)** : noms « Périgueux » (1941-1973) et « Périgueux-Centre » (1973-1999) pour 2427. Reste : rien.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Source** : décret n° 73-656 du 13 juillet 1973 (JO du 17 juillet 1973 ;
  `jorf_txt/JORF_19730717_164_col.txt` ; `cantons/communes_coupees_1973_1984.csv`), art. 2 :
  Périgueux-Nord-Est = Trélissac, Château-l'Évêque, Champcevinel + le quartier Saint-Georges (rive
  gauche de l'Isle) ; Périgueux-Centre = la ville délimitée du pont de Coutras à Champcevinel (voie
  ferrée, cimetière, rues Louis-Blanc … Trarieux prolongée) ; Périgueux-Ouest = Chancelade, Marsac,
  Coulounieix-Chamiers + le reste de la ville.
- **Base** : fractions `26489#2427`, `#2449`, `#2450` de 1973-09-23 à 2013-01-01, communes rurales
  conformes au décret (Boulazac et Notre-Dame-de-Sanilhac restent à Saint-Pierre-de-Chignac, 2434).
  L'unité 2427 n'a pas de `unit_version` de 1941 à 1999 (« Périgueux » jusqu'en 1941,
  « Périgueux-Centre » de 1999 à 2013) : elle s'affiche « Périgueux » de 1973 à 1999. Même cas que
  Guéret-Nord (n° 114) et Bergerac (2403). Les unités 2449 et 2450 n'ont de version qu'à partir de
  1999, mais le repli sur le nom de `unit` est juste.
- **À inscrire** : `unit_version` 2427 « Périgueux-Centre » sur [1973-09-23, 1999-01-01) ;
  « Périgueux » sur [1941-01-01, 1973-09-23).
- **Lignes** : `24322-1` (l'Isle, lit de la rivière et non le canal) et `24322-2` (pont de Coutras,
  voie ferrée, cimetière, rues jusqu'à Champcevinel) écrites le 18 octobre 2026 (1973-09-23 →
  2013-01-01, source `texte`) ; ancres non datées `26489#2449` POINT(521900 6456300), `#2427`
  POINT(520900 6456900), `#2450` POINT(519300 6458500). Le nom n'affecte pas le tirage.

## Montbéliard (25388)

### 116. Montbéliard de 1955 à 1982 : la ville sans canton, Bethoncourt sans canton de 1973 à 1982, noms de 1973

- **Inscrit par `sql/124_villes_lot_3.sql` (23 octobre 2026)** : `23194` dans 2514 de 1955 à 1973 ; `#2514` et `#2530` de 1973 à 1982 ; nom Montbéliard-Est dès 1973. Bethoncourt était déjà comblé par `120`. Reste : les concordances de rues.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Source** : décret n° 73-814 du 16 août 1973, art. 2 (JO du 17 août 1973, p. 8921-8922 ;
  `jorf_txt/JORF_19730817_190_col.txt`, l. 1558-1594 ; `cantons/communes_coupees_1973_1984.csv`) :
  le canton de Montbéliard est divisé en Montbéliard-Est (Bethoncourt et la partie est de la
  ville) et Montbéliard-Ouest (Aibre, Allondans, Bart, Bavans, Beutal, Bretigney, Désandans, Dung,
  Échenans, Issans, Laire, Lougres, Présentevillers, Raynans, Saint-Julien-lès-Montbéliard,
  Sainte-Marie, Sainte-Suzanne, Semondans, Le Vernoy et le reste de la ville). Aucun autre texte
  jusqu'au décret de 2014 (82-55 ne touche pas la ville ; en 2015 la ville est entière dans le
  canton de Montbéliard). Le décret renvoie aux « plans des lieux » déposés à la préfecture du Doubs
  (non vus). Copie : `cartes/sorties/decoupe_montbeliard/sources.txt`.
- **Base** : atome entier `23194` dans 2514 jusqu'au 1955-01-01, puis **aucune appartenance
  cantonale de la ville du 1955-01-01 au 1982-03-14** (ses communes rurales sont dans 2514 sans
  trou de 1955 à 1973) ; fractions `23194#2514` et `#2530` (source `fraction_cog`) du 1982-03-14 à
  2013. Bethoncourt (atome 4019) dans 2514 jusqu'au 1973-09-23, **sans canton du 1973-09-23 au
  1982-03-14**, puis dans 2514. Les dix-neuf communes rurales de l'Ouest sont dans 2530 dès le
  1973-09-23 (juste). `unit_version` : 2514 n'a pas de version de 1941 à 1999 (le repli donne
  « Montbéliard » de 1982 à 1999, alors que c'est Montbéliard-Est depuis 1973) ; 2530 n'a de
  version qu'à partir de 1999 (repli juste).
- **À inscrire** : atome `23194` dans 2514 du 1955-01-01 au 1973-09-23 ; `23194#2514`
  (Montbéliard-Est) et `23194#2530` (Montbéliard-Ouest) du 1973-09-23 au 1982-03-14 ; Bethoncourt
  dans 2514 du 1973-09-23 au 1982-03-14 ; nom Montbéliard-Est (2514) dès le 1973-09-23.
- **Ligne** : `25388-1` écrite le 18 octobre 2026 (1973-09-23 → 2013-01-01, source `texte`, 3 962 m,
  conforme au 1982-03-14, 1990 et 2005) ; ancres non datées `23194#2514` POINT(986400 6718800),
  910,5 ha ; `23194#2530` POINT(983800 6721000), 588,8 ha. Elles joueront de 1973 à 1982 quand les
  fractions y seront.
- **Reste** : concordances déduites, à confirmer sur le plan du décret : route d'Héricourt = rue de
  la Seigneurie-d'Héricourt ; rue du Bois-d'Allondans = rue Louis-Pardonnet entre les rues
  Joseph-Rossel et de Horbourg ; rue de Cheneau-Prolongée entre Horbourg et Vignes (la route
  d'Allondans donnerait 1,65 ha et 25 logements à l'Ouest).

## Montélimar (26198)

### 117. Montélimar de 1973 à 1985 : la ville, Ancône et La Touche sans canton ; Montélimar-I sans nom jusqu'en 1999

- **Inscrit par `sql/124_villes_lot_3.sql` (23 octobre 2026)** : `23337#2616` et `#2633` de 1973 à 1985 ; noms Montélimar-I et Montélimar-II. Ancône et La Touche étaient déjà comblées par `120`. Reste : l'ancien lit du Roubion.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Source** : décret n° 73-718 du 23 juillet 1973, art. 3 (JO du 25 juillet 1973, p. 8080 ;
  `jorf_txt/JORF_19730725_171_col.txt` ; `cantons/communes_coupees_1973_1984.csv`) : le canton de
  Montélimar est divisé en Montélimar-I (Ancône et la ville « au Nord de la rivière le Roubion ») et
  Montélimar-II (Allan, Châteauneuf-du-Rhône, Espeluche, Malataverne, Montboucher-sur-Jabron,
  Portes-en-Valdaine, Puygiron, Rochefort-en-Valdaine, La Touche et la ville au Sud du Roubion).
  Aucun autre texte jusqu'au décret 2014-191, qui reprend « au nord / au sud du Roubion ».
- **Base** : atome `23337` entier dans 2616 jusqu'au 1973-09-23, puis **aucune appartenance de la
  ville du 1973-09-23 au 1985-03-10** ; fractions `23337#2616` et `#2633` (`fraction_cog`) du
  1985-03-10 au 2013-01-01. Ancône (atome 722) et La Touche (atome 18869) **sans canton du
  1973-09-23 au 1985-03-10** ; les huit autres communes du II sont dans 2633 dès le 1973-09-23
  (juste). `unit_version` : 2616 n'a pas de version avant 1999 (le repli affiche « Montélimar » de
  1985 à 1999, alors que c'est Montélimar-I depuis 1973).
- **À inscrire** : `23337#2616` (Montélimar-I) et `23337#2633` (Montélimar-II) du 1973-09-23 au
  1985-03-10 ; Ancône dans 2616 et La Touche dans 2633 sur la même période ; nom Montélimar-I
  (2616) dès le 1973-09-23.
- **Ligne** : `26198-1` écrite le 18 octobre 2026 (1973-09-23 → 2013-01-01, source `texte`,
  9 292 m, conforme au 1985-03-10 et en 2005) ; ancres non datées `23337#2616` nord, 2 297,2 ha ;
  `23337#2633` sud, 2 340,1 ha. Elles joueront de 1973 à 1985 quand les fractions y seront.
- **Reste** : à l'ouest du canal de dérivation (1957), la ligne suit l'« Ancien Lit Roubion » ;
  547 ha au I et 221 ha au II en dépendent (plan du décret non vu).

## Romans-sur-Isère (26281)

### 118. Romans de 1973 à 1985 : la ville sans fraction, Montmiral sans canton

- **Inscrit par `sql/124_villes_lot_3.sql` (23 octobre 2026)** : `29521#2621` et `#2635` de 1973 à 1985 ; noms Romans-sur-Isère (1941-1973), Romans-sur-Isère-I et -II (1973-1999). Montmiral était déjà dans 2635 (`120`). Reste : le passage à niveau.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Source** : décret n° 73-718 du 23 juillet 1973, art. 2 (JO du 25 juillet 1973, p. 8079-8080 ;
  `jorf_txt/JORF_19730725_171_col.txt`, l. 1250-1265 ; `cantons/communes_coupees_1973_1984.csv`) :
  Romans-sur-Isère-I = Clérieux, Saint-Bardoux, Peyrins, Mours-Saint-Eusèbe, Geyssans + la ville à
  l'ouest de l'axe rue des Remparts-Saint-Nicolas, rue Nugues, rue François-Pouzin, avenue
  Émile-Zola, route de Génissieux ; Romans-sur-Isère-II = Saint-Paul-lès-Romans, Génissieux,
  Triors, Châtillon-Saint-Jean, Saint-Bonnet-de-Valclérieux, Le Chalon, Saint-Laurent-d'Onay,
  Saint-Michel, Parnans, Crépol, Miribel, Montmiral + le reste de la ville. Aucun autre texte
  avant le décret de 2014. Copie : `cartes/sorties/decoupe_romans/sources.txt`.
- **Base** : atome entier `29521` dans 2621 jusqu'au 1973-09-23 ; **aucune appartenance
  cantonale de la ville du 1973-09-23 au 1985-03-10** ; fractions `29521#2621` (I) et `#2635`
  (II) du 1985-03-10 au 2013-01-01, justes (communes rurales conformes au décret dès le
  1973-09-23, populations INSEE 2011 à 0,1 point de la ligne). **Montmiral (atome 23686) n'a
  pas de canton du 1973-09-23 au 1985-03-10** (2635 seulement à partir de 1985). `unit_version` :
  2621 s'appelle « Romans-sur-Isère » de 1985 à 1999 (repli), « 1er Canton » ensuite.
- **À inscrire** : `29521#2621` (Romans-sur-Isère-I) et `29521#2635` (Romans-sur-Isère-II) sur
  1973-09-23 → 1985-03-10 ; Montmiral dans 2635 sur la même période ; nom
  « Romans-sur-Isère-I » pour 2621 dès le 1973-09-23 (« Romans-sur-Isère » sur [1941, 1973-09-23)).
- **Ligne** : `26281-1` écrite le 18 octobre 2026 (1973-09-23 → 2013-01-01, source `texte`,
  2 241 m, conforme au 1990-01-01 et au 2005-01-01) ; ancres non datées `29521#2621` =
  POINT(860000 6442000), 2 419,7 ha ; `29521#2635` = POINT(864000 6441000), 930,1 ha. Elles
  joueront de 1973 à 1985 quand les fractions y seront.
- **Reste** : le passage de la voie ferrée entre la rue François-Pouzin et l'avenue Émile-Zola
  (29 m en droite) suppose un passage à niveau en 1973, non vérifié.

## Crest (26108)

### 119. Crest : fractions absentes de 1973 à 1985 ; Aouste, Gigors et Saou sans canton de 1955 à 1985 ; Saou à Marsanne en 1968-1973

- **Inscrit par `sql/124_villes_lot_3.sql` (23 octobre 2026)** : `11045#2607` et `#2608` de 1973 à 1985. Aouste, Gigors et Saou étaient déjà comblées par `120`, Saou dans 2608 (plus dans Marsanne). Reste : rien.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Source** : arrêté des consuls du 9 frimaire an X (30 novembre 1801), Bulletin des lois B. 156,
  n° 1206 ; lu sur l'image de Rondonneau, *Collection générale des lois*, t. 8, p. 615-616
  (archive.org `bub_gb_A25OAAAAYAAJ`, feuillets n673-n674 ; copie dans
  `cartes/sorties/decoupe_crest/src/`) : « La rivière de Drôme servira de ligne de démarcation » ;
  Nord sur la rive droite, Sud sur la rive gauche. Aucun acte ensuite jusqu'au décret 2014-191 (la
  commune entière dans le canton de Crest). Gallica (`bpt6k6515730s/f202`) non collationné.
- **Base** : fractions `11045#2607` (Nord) et `#2608` (Sud) de 1815 au 1973-09-23 et du 1985-03-10
  à 2013, **aucune appartenance du 1973-09-23 au 1985-03-10**, alors que les unités 2607 et 2608 y
  ont leurs communes rurales. Aouste-sur-Sye (atome 991) et Gigors-et-Lozeron (15483) **sans canton
  du 1955-01-01 au 1985-03-10** (absentes de `cog1968/communes_1968_fusion.csv` pour la Drôme).
  Saou (35321) **sans canton en 1955-1968 et 1973-1985, et dans 2615 (Marsanne) en 1968-1973** :
  coquille du COG 1968, où Saou porte le code 26536 et où la ligne 26336 « Saurzet » (1 110 hab.,
  canton 15) est un doublon OCR de Sauzet.
- **À inscrire** : `11045#2607` → 2607 et `11045#2608` → 2608 sur [1973-09-23, 1985-03-10) ;
  Aouste-sur-Sye et Gigors-et-Lozeron dans 2607 sur [1955-01-01, 1985-03-10) ; Saou dans 2608 sur
  [1955-01-01, 1985-03-10) (au lieu de 2615 en 1968-1973).
- **Ligne** : `26108-1` écrite le 18 octobre 2026 (1801-11-30 → 2013-01-01, source `texte`,
  3 725 m, conforme en 1820, 1900, 1990 et 2010) ; ancres non datées `11045#2607` =
  POINT(860136 6406754), 1 557,5 ha ; `11045#2608` = POINT(859906 6404002), 809,8 ha. Elles
  joueront de 1973 à 1985 quand les fractions y seront.

## Besançon (25056)

### 121. Besançon de 1973 à 1982 : la ville sans canton, Chalezeule et Chalèze sans canton ; Nord-Est sous le nom « Besançon-Nord » jusqu'en 1999

- **Inscrit par `sql/124_villes_lot_3.sql` (23 octobre 2026)** : `3928#2505`, `#2506`, `#2528`, `#2529` de 1973 à 1982 ; Chalezeule et Chalèze dans 2528 ; nom Besançon-Nord-Est de 1982 à 1999. Arcier n'est plus une commune en base (Vaire-Arcier, canton 2513) : rien posé. Reste : l'île Saint-Pierre.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Source** : décret n° 73-814 du 16 août 1973, art. 1er (JO du 17 août 1973, p. 8921 ;
  `jorf_txt/JORF_19730817_190_col.txt`, l. 1520-1556) : Besançon-Nord est divisé en trois
  cantons, Besançon-Est (Chalezeule, Chalèze, Arcier et la partie est de la ville),
  Besançon-Ouest (la partie ouest de la ville, sans commune rurale) et Besançon-Nord (le reste de
  l'ancien Nord dans la ville). Décret n° 82-55 du 20 janvier 1982 (JO du 22 janvier 1982,
  p. 336-337 ; `jorf_txt/JORF_19820122_18_col.txt`, l. 495-536) : Nord → Nord-Est et Nord-Ouest,
  Ouest → Ouest et Planoise, tous sans commune rurale. Le Sud n'est touché par aucun des deux.
- **Base** : fractions `3928#2505` (Nord) et `#2506` (Sud) de 1815 au 1973-09-23 ; **aucune
  appartenance cantonale de la ville du 1973-09-23 au 1982-03-14** ; six fractions du 1982-03-14
  à 2013 (`#2505`, `#2506` en `geofla`, `#2528` Est, `#2529` Ouest, `#2532` Nord-Ouest, `#2533`
  Planoise en `fraction_cog`), justes (populations INSEE 2011 à 0,7 point au plus des morceaux).
  **Chalezeule (25112) et Chalèze (25111) n'ont pas de canton du 1973-09-23 au 1982-03-14**
  (2505 avant, 2528 après). Beure (Sud) est continu. `unit_version` : 2505 s'appelle
  « Besançon-Nord » de 1982 à 1999 (version de 1870), alors que c'est Besançon-Nord-Est depuis le
  décret 82-55 ; 2528, 2529, 2532, 2533 n'ont de version qu'à partir de 1999 (repli juste).
- **À inscrire** : `3928#2505` (Nord), `#2506` (Sud), `#2528` (Est), `#2529` (Ouest) sur
  1973-09-23 → 1982-03-14 ; Chalezeule et Chalèze dans 2528 sur la même période (et Arcier si la
  base l'a encore comme commune) ; nom « Besançon-Nord-Est » pour 2505 dès le 1982-03-14.
- **Lignes** : écrites le 18 octobre 2026, source `texte`. `25056-1801-doubs` (1801-10-19 →
  1973-09-23) ; `25056-1973-doubs`, `-est-ouest`, `-est-nord`, `-ouest-nord` (1973-09-23 →
  1982-03-14, quatre morceaux) ; `25056-1982-doubs`, `-est-ouest`, `-est-nordest`, `-ouest-nord`,
  `-vesoul`, `-kennedy` (1982-03-14 → 2013-01-01). Ancres datées 1973-1982, prêtes pour quand les
  fractions y seront : `#2505` POINT(928500 6689500), 3 397,8 ha ; `#2506` POINT(928700 6686000),
  475,5 ha ; `#2528` POINT(929700 6687300), 698,5 ha ; `#2529` POINT(927200 6685000), 1 936,4 ha.
- **Reste** : l'île Saint-Pierre est mise à l'Ouest à partir de 1973 sur la foi du décret
  2014-240 (« île Saint-Pierre incluse » dans Besançon-6), le décret de 1973 ne l'excluant que de
  l'Est ; le plan des lieux de 1973 (préfecture du Doubs) trancherait. Arrêté de l'an X lu dans
  Rondonneau, à collationner sur Gallica (ark:/12148/bpt6k6566479p/f206).

## Louviers (27375)

### 122. Louviers de 1982 à 1992 : la ville sans fraction, alors que ses communes rurales sont déjà partagées ; Louviers-Nord sous le nom « Louviers » jusqu'en 1999

- **Inscrit par `sql/124_villes_lot_3.sql` (23 octobre 2026)** : `20191#2721` et `#2739` de 1982 à 1992 ; nom Louviers-Nord dès 1982. Reste : rien.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Source** : décret n° 82-56 du 20 janvier 1982, art. 3 (JO du 22 janvier 1982, p. 337 ;
  `jorf_txt/JORF_19820122_18_col.txt`, l. 648-666) — le même décret que pour Évreux (n° 71) :
  Louviers est divisé en Louviers-Nord et Louviers-Sud. Wikipédia (« Liste des cantons de
  l'Eure ») : un seul canton de 1801 à 1982 ; le décret 2014-241 remet la ville entière dans le
  canton de Louviers.
- **Base (rebuild du 20 octobre 2026)** : atome 20191 entier dans 2721 jusqu'au 1982-03-14 ;
  fractions `20191#2721` (Louviers-Nord) et `20191#2739` (Louviers-Sud) du 1992-03-22 au
  2013-01-01 seulement ; **rien pour la ville du 1982-03-14 au 1992-03-22**, alors que les
  communes rurales y sont déjà partagées (6 dans 2721, 12 dans 2739 au 1985-01-01). Même trou
  qu'à Évreux. `unit_version` de 2721 : « Louviers » jusqu'en 1941, rien ensuite, « Louviers-Nord »
  à partir de 1999 seulement ; le repli affichera « Louviers » de 1982 à 1999 (comme Guéret-Nord,
  n° 114).
- **À inscrire** : `20191#2721` → 2721 et `20191#2739` → 2739 du 1982-03-14 au 1992-03-22.
  Communes du décret — Nord : Andé, Heudebouville, Incarville, Saint-Étienne-du-Vauvray,
  Saint-Pierre-du-Vauvray, Vironvay ; Sud : Acquigny, Amfreville-sur-Iton (« Anfreville »),
  Crasville (« Crosville » au JO), La Haye-le-Comte, La Haye-Malherbe, Hondouville,
  Le Mesnil-Jourdain, Pinterville, Quatremare, Surtauville, Surville, La Vacherie.
  Nom « Louviers-Nord » pour 2721 dès le 1982-03-14.
- **Lignes** : `27375-1` écrite le 20 octobre 2026, source `texte`, 1982-03-14 → 2013-01-01,
  ancres non datées `#2721` POINT(565000 6905500), 1 527,2 ha, `#2739` POINT(566500 6901800),
  1 181,2 ha ; elles joueront dès l'inscription.

## Bernay (27056)

### 123. Bernay-Est / Bernay-Ouest commencent en 1992 au lieu de 1985 ; la ville sans canton de 1982 à 1985

- **Inscrit par `sql/124_villes_lot_3.sql` (23 octobre 2026)** : `3797` dans 2705 de 1982 à 1985 ; `#2705` et `#2741` de 1985 à 1992 ; noms Bernay-Ouest et Bernay-Est dès 1985. Reste : rien.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Source** : décret n° 85-145 du 31 janvier 1985, art. 2 (JO du 1er février 1985, p. 1380 ;
  `jorf_txt/JORF_19850201_27_col.txt`, l. 1382-1424 — l'OCR écrit « Bemay »). Wikipédia
  (« Liste des cantons de l'Eure ») : un seul canton de l'an X à 1985 ; le décret 2014-241 remet
  la ville entière dans le canton de Bernay.
- **Base (rebuild du 20 octobre 2026)** : atome 3797 entier dans 2705 jusqu'au 1982-03-14, puis
  **sans canton jusqu'au 1985-03-10** ; fractions `3797#2705` (Ouest) et `3797#2741` (Est)
  seulement à partir du 1992-03-22. Les communes rurales de Bernay-Est (Carsix,
  Corneville-la-Fouquetière, Fontaine-l'Abbé, Menneval, Saint-Aubin-le-Vertueux,
  Saint-Clair-d'Arcey, Saint-Léger-de-Rôtes, Serquigny) sont dans 2741 dès le 1985-03-10.
  `unit_version` ne nomme 2741 « Bernay-Est » et 2705 « Bernay-Ouest » qu'à partir de 1999.
- **À inscrire** : 3797 dans 2705 du 1982-03-14 au 1985-03-10 ; `3797#2705` et `3797#2741` du
  1985-03-10 au 1992-03-22 ; les noms Bernay-Ouest / Bernay-Est dès le 1985-03-10.
- **Ligne** : `27056-1` écrite le 20 octobre 2026, source `texte`, 1985-03-10 → 2013-01-01,
  ancres non datées `#2705` POINT(522100 6892000), 1 234,5 ha, `#2741` POINT(527100 6889500),
  1 176,8 ha ; elles joueront dès l'inscription.

### 124. Fraction fantôme de Bézu-la-Forêt dans le canton de Bernay (1968-1982)

- **Fait en amont (constaté le 23 octobre 2026)** : `4164#2705` n'est plus en base ; Bézu-la-Forêt est entière dans 2722 de 1941 à 1999 (`96`, lecture de 1968 corrigée). Entrée close.

- **Base** : `4164#2705` (Bézu-la-Forêt, canton 2705 Bernay) du 1968-01-01 au 1982-03-14, à côté
  de `4164#2722` (Lyons).
- **Cause** : `cog1968/communes_1968_fusion.csv` l. 10492, « Bosc-Renoull-en-Ouche », doublon
  OCR de Bosc-Renoult-en-Ouche (27088, l. 10512), porte le code 066 de Bézu-la-Forêt et le
  canton 05 de Bernay (même cas que Saou / « Saurzet », n° 119).
- **À inscrire** : supprimer `4164#2705` ; Bézu-la-Forêt entière dans 2722 de 1968 à 1982.

## Valence (26362)

### 125. Valence : régimes 1964 (Nord / Sud) et 1973 (I à III) absents ; Bourg-lès-Valence et Saint-Marcel sans canton de 1973 à 1985

- **Inscrit par `sql/124_villes_lot_3.sql` (23 octobre 2026)** : a) `38655` entier arrêté au 1964-03-08 (lignes 1968-1973 retirées), `#2629` et `#2630` de 1964 à 1973 ; Étoile (dès 1941), Beaumont, Beauvallon, Portes (dès 1955) dans 2629 jusqu'en 1964, puis 2630 jusqu'en 1968 ; Montéléger 2629 puis 2630 jusqu'en 1973. b) `#2629`, `#2630`, `#2631` de 1973 à 1985 ; la correspondance I / II / III = 2629 / 2630 / 2631 est retenue (le décret 84-1224 garde la même géographie, et les codes de 1985 suivent ses numéros) ; Bourg-lès-Valence et Saint-Marcel dans 2632. Noms Valence-Nord / -Sud (1964-1973), Valence-I à IV. Reste : rien.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Sources** : décret du 28 janvier 1964 (JO du 30 janvier 1964, p. 1092 ;
  `jorf_txt/JORF_19640130_25_col.txt`, l. 2124-2161) ; décret n° 73-718 du 23 juillet 1973,
  art. 1er (JO du 25 juillet 1973, p. 8079-8080 ; `JORF_19730725_171_col.txt`, l. 1192-1240) ;
  décret n° 84-1224 du 24 décembre 1984 (JO du 30 décembre 1984, p. 4147 ;
  `JORF_19841230_305_col.txt`, l. 14493-14568).
- **Base (rebuild du 20 octobre 2026)** : la ville entière dans 2629 de 1955 au 1973-09-23 ;
  aucune fraction du 1973-09-23 au 1985-03-10 ; fractions `38655#2629`, `#2630`, `#2631`,
  `#2636` (I à IV) du 1985-03-10 au 2013-01-01, justes (populations 2011 à 0,5 point des
  morceaux).
- **À inscrire** :
  a) 1964-03-08 → 1973-09-23 : `38655#2629` (Valence-Nord) et `#2630` (Valence-Sud) au lieu de
     38655 entier. Codes lus sur les communes rurales : Bourg et Saint-Marcel en 2629 ; Beaumont,
     Beauvallon, Étoile, Portes en 2630 (« Valence 2e canton ») en 1968-1973. Pour 1964-1968,
     mettre les communes du Sud en 2630 : Beaumont, Beauvallon et Portes n'ont aucun canton de
     1955 à 1968, Étoile aucun de 1941 à 1968, Montéléger aucun de 1955 à 1973. Noms
     Valence-Nord / Valence-Sud de 2629 / 2630 pour 1964-1973 absents de `unit_version`.
  b) 1973-09-23 → 1985-03-10 : `38655#2629` (Valence-I), `#2630` (II), `#2631` (III), sans
     commune rurale. Bourg-lès-Valence et Saint-Marcel-lès-Valence n'ont aucun canton de 1973 à
     1985 : canton 2632 Bourg-lès-Valence au décret 73-718. Correspondance I/II/III =
     2629/2630/2631 SUPPOSÉE, à vérifier avant inscription.
- **Lignes** : écrites le 20 octobre 2026, source `texte`. `26362-1964-ns` (1964-03-08 →
  1973-09-23) ; `26362-1973-i`, `-1973-ii-iii` (→ 1985-03-10) ; `26362-1985-i`, `-1985-iii-iv`,
  `-1985-ii-iv` (→ 2013-01-01). Ancres datées prêtes : 1964 `#2629` POINT(850500 6428800),
  2 024,5 ha, `#2630` POINT(849000 6424500), 1 644,9 ha ; 1973 `#2629` POINT(849000 6427800),
  341,5 ha, `#2630` POINT(848500 6424800), 1 400,9 ha, `#2631` POINT(852000 6427000), 1 927,0 ha.

## Vernon (27681)

### 126. Vernon de 1982 à 1992 : la ville sans fraction, alors que ses communes rurales sont déjà partagées ; Vernon-Nord sous le nom « Vernon » jusqu'en 1999

- **Inscrit par `sql/124_villes_lot_3.sql` (23 octobre 2026)** : `39507#2736` et `#2740` de 1982 à 1992 ; noms Vernon-Nord et Vernon-Sud dès 1982. Reste : la rue Latérale, le prolongement vers Port-Villez.
  Ce qui suit est l'entrée d'avant l'inscription.

- **Source** : décret n° 82-56 du 20 janvier 1982, art. 2 (JO du 22 janvier 1982, p. 337 ;
  `jorf_txt/JORF_19820122_18_col.txt`, l. 631-647, relu sur `sources/JORF/JORF_19820122_18.pdf` p. 5) —
  même décret que Louviers (n° 122) et Évreux (n° 71) : Vernon est divisé en Vernon-Nord et
  Vernon-Sud. Le décret 2014-241 remet la ville entière dans le canton de Vernon. Rien dans
  `annexes/gaudillere/`.
- **Base** : atome 39507 entier dans 2736 jusqu'au 1982-03-14 ; fractions `39507#2736` (Nord) et
  `39507#2740` (Sud) du 1992-03-22 au 2013-01-01 seulement ; **rien pour la ville du 1982-03-14 au
  1992-03-22**, alors que les communes rurales y sont déjà partagées au 1985-01-01 (7 dans 2736 :
  Chambray, La Chapelle-Réanville, Sainte-Colombe-près-Vernon, Saint-Just, Saint-Marcel,
  Saint-Pierre-d'Autils, Villez-sous-Bailleul ; 6 dans 2740 : Douains, Houlbec-Cocherel,
  La Heunière, Mercey, Rouvray, Saint-Vincent-des-Bois — conformes au décret). `unit_version` de
  2736 : « Vernon » jusqu'en 1941, rien ensuite, « Vernon-Nord » à partir de 1999. À côté :
  Blaru et Port-Villez (unité 7802, Yvelines) portent le nom « Arpajon » en 1995.
- **À inscrire** : `39507#2736` → 2736 et `39507#2740` → 2740 du 1982-03-14 au 1992-03-22 ; noms
  « Vernon-Nord » pour 2736 et « Vernon-Sud » pour 2740 dès le 1982-03-14.
- **Lignes** : `27681-1` écrite le 21 octobre 2026, source `texte`, 1982-03-14 → 2013-01-01,
  ancres non datées `#2736` POINT(590000 6890000), 1 561,0 ha, `#2740` POINT(588500 6888000),
  1 864,7 ha ; elles joueront dès l'inscription. Questions ouvertes : la « rue Latérale » (lue :
  cité des Champsbourgs et rue du Colonel-Léo-Levasseur, le long de la voie Paris-Le Havre ;
  population au Nord 34,5 % contre 33,9 % légale ; l'autre lecture, rue Claude-Monet, 46,1 %) ;
  le prolongement sans texte jusqu'à Port-Villez par la voie ferrée (variante par la rue du
  Croquet : 9,1 ha, 64 logements). Fichiers de travail : `cartes/sorties/decoupe_vernon/`.

---

## Dreux (28134)

### 127. Dreux : régime de 1973 (Nord-Est / Sud-Ouest) absent ; fractions de 1982 seulement depuis 1998

- **Sources** : décret 73-719 du 23 juillet 1973 (JO du 25 juillet 1973,
  `jorf_txt/JORF_19730725_171_col.txt`, l. 1294-1401, art. 2 l. 1382-1400 ; absent de
  `cantons/communes_coupees_1973_1984.csv`) ; décret 82-27 du 15 janvier 1982 (JO du 16 janvier
  1982, `jorf_txt/JORF_19820116_13_col.txt`, l. 1145-1179 ; `communes_coupees_1973_1984.csv`
  l. 412-414) ; décret de 2014 (Dreux-1), lu sur la seule transcription de Wikipédia, qui reprend
  la ligne Ouest / Est de 1982 en traduisant les anciens noms. Rien dans `annexes/gaudillere/`.
- **Base** : 12219 entière dans 2813 jusqu'au 1973-09-23 ; rien pour la ville ni pour ses communes
  rurales du 1973-09-23 au 1982-03-14 ; communes rurales dans 2813 / 2827 / 2828 dès le
  1982-03-14, mais fractions `12219#2813`, `#2827`, `#2828` seulement à partir du 1998-03-15 ;
  pas de nom « Dreux-Est » pour 2813 avant 1999.
- **À inscrire** : les unités Dreux-Nord-Est et Dreux-Sud-Ouest (1973-09-23 → 1982-03-14), leurs
  communes (SO : Allainville, Aunay-sous-Crécy, Boissy-en-Drouais, Crécy-Couvé, Garancières,
  Garnay, Louvilliers, Luray, Marville-Moutiers-Brûlé, Saulnières, Tréon, Vernouillet ; NE :
  La Chapelle-Forainvilliers, Charpont, Chérisy, Écluzelles, Germainville, Mézières-en-Drouais,
  Montreuil, Ouerre, Sainte-Gemme-Moronval, Vert-en-Drouais) et les deux fractions de Dreux ; les
  trois fractions de 1982 dès le 1982-03-14 ; le nom Dreux-Est de 2813 dès 1982.
- **Lignes** : écrites le 21 octobre 2026, source `texte`. `28134-1` (1973-09-23 → 1982-03-14,
  sans ancre ; points proposés SO POINT(580900 6848300), NE POINT(578500 6851500)) ; `28134-2`
  (Ouest / Est) et `28134-3` (Sud), 1982-03-14 → 2013-01-01, ancres datées `#2827` Ouest
  POINT(577500 6851500), `#2813` Est POINT(581200 6849700), `#2828` Sud POINT(580900 6848300).
  Logements BD TOPO à 1,8 point au plus des populations légales 2011. Questions ouvertes : le
  départ sur la limite de Montreuil (lecture de 2014) alors que 1982 dit Chérisy ; la sente 74 et
  la « rue La Fayette » (1,44 ha, 10 logements), que les plans du décret, à la préfecture,
  trancheraient. Fichiers de travail : `cartes/sorties/decoupe_dreux/`.

---

## Ajaccio (2A004)

### 129. Ajaccio : régime de 1973 (Ajaccio-I à V) absent ; Alata, Villanova, Appietto, Afa, Bastelicaccia sans canton de 1973 à 1982

- **Sources** : décret 73-825 du 18 août 1973 (JO du 19 août 1973, p. 9014-9015,
  `jorf_txt/JORF_19730819_192_col.txt`, l. 940-1080) : le canton d'Ajaccio est remplacé par
  Ajaccio-I (Ouest-Ville), II (Vieille-Ville-Sud), III (Centre-Ville-Nord), IV (Nord, avec Alata et
  Villanova) et V (Est, avec Appietto, Afa et Bastelicaccia). Décret 82-121 du 2 février 1982 (JO
  du 4 février 1982, p. 457-458, `jorf_txt/JORF_19820204_29_col.txt`, l. 728-822) : crée VI et VII,
  redélimite IV et V. C'est le point « Corse 1975 : 7 communes sans unité » de `sql/110` § 6 bis.
- **Base** : Ajaccio entière dans 2001 jusqu'au 1973-09-23 ; fractions `339#2A01`, `#2A63`,
  `#2A64`, `#2A65`, `#2A66`, `#2A72`, `#2A73` seulement à partir du 1982-03-14 (date du scrutin,
  cohérente avec le décret 82-121) ; Alata, Villanova, Appietto, Afa et Bastelicaccia sans canton
  du 1973-09-23 au 1982-03-14.
- **À inscrire** : les unités Ajaccio-I à V du 1973-09-23 au 1982-03-14 (codes 20xx jusqu'au
  1976-01-01, puis 2Axx — sans doute 2A01, 2A63 à 2A66 comme ensuite), les appartenances des cinq
  fractions sur cette période, et les communes rurales : Alata et Villanova au IV, Appietto, Afa et
  Bastelicaccia au V.
- **Lignes** : écrites le 23 octobre 2026, source `texte`. Passe 1973 (`2A004-1973-*`, cinq
  lignes, `--morceaux 5`) avec ancres datées prêtes : I POINT(1172000 6107500), II POINT(1176650
  6108100), III POINT(1176450 6108900), IV POINT(1173000 6110500), V POINT(1178500 6109800). Passe
  1982 (`2A004-1982-*`, sept lignes). La limite IV / V de 1973 est une DÉDUCTION des listes de voies
  du décret (27,2 ha d'écart avec 1982). Fichiers de travail : `cartes/sorties/decoupe_ajaccio/`.

---

## Quimper (29232)

### 130. Quimper : aucune appartenance de 1955 à 1992 ; régimes de 1973 (I / II) et 1985 (I / II / III) absents

- **Sources** : décret 73-720 du 23 juillet 1973 (JO du 25 juillet 1973,
  `jorf_txt/JORF_19730725_171_col.txt`, l. 1433-1458) ; décret 85-74 du 22 janvier 1985 (JO du
  23 janvier 1985, p. 932-933, `jorf_txt/JORF_19850123_19_col.txt`, l. 3526-3553) ; décret
  2014-151 (transcription Wikipédia, non collationnée), qui confirme le centre de 1985.
- **Base** : l'atome `28471` n'a aucune appartenance cantonale du 1955-01-01 au 1992-03-22. Les
  atomes absorbés le 13 février 1960 (`12839` Ergué-Armel, `18125` Kerfeunteun, `26405` Penhars)
  s'arrêtent en 1955. Ergué-Gabéric (`12840`), Plomelin (`27177`) et Pluguffan (`27265`) n'ont rien
  du 1973-09-23 au 1992-03-22. Le nom de 2935 reste « Quimper » de 1992 à 1999.
- **À inscrire** : 1955-1973, Quimper entière (et les trois communes jusqu'en 1960) dans 2935 ;
  1973-09-23 → 1985-03-10, fractions `28471#2935` (Quimper-I, avec Plomelin et Pluguffan) et
  `28471#2948` (Quimper-II, avec Ergué-Gabéric), codes déduits de `cantons/mouvements_cantonaux.csv`
  et non lus dans le COG ; 1985-03-10 → 1992-03-22, les trois fractions telles qu'en 1992
  (Ergué-Gabéric en 2948, Plomelin et Pluguffan en 2952).
- **Lignes** : écrites le 23 octobre 2026, source `texte`. `29232-1` (1973-09-23 → 1985-03-10,
  `--morceaux 2`, ancres datées I POINT(171000 6792000) au nord, II POINT(172500 6787500) au sud :
  lecture de « à gauche » d'une ligne parcourue d'ouest en est, à confirmer) ; `29232-2` et
  `29232-3` (1985-03-10 → 2013-01-01 ; III ancré deux fois, lobe sud de 193 ha). Logements BD TOPO
  à 1,2 point au plus des populations légales 2011. Fichiers : `cartes/sorties/decoupe_quimper/`.

---

## Brest (29019)

### 131. Brest : rien de 1973 à 1992 ; cantons IV, VI, VII, VIII sans unité ; noms de 1991 ; atome entier sous Brest-3 de 1968 à 1973

- **Sources** : arrêté du 7 brumaire an X (Rondonneau t. 8 p. 512, feuillet n570) ; décret 73-720
  (JO du 25 juillet 1973) ; décret 85-74 (JO du 23 janvier 1985) ; décret 91-211 du 27 février 1991
  (texte intégral lu sur Légifrance, `cartes/sorties/decoupe_brest/decret_91-211.txt`).
- **Base** : trois fractions de 1815 à 1941 sur 573 ha ; aucune fraction entre 1941 et 1973, et
  l'atome 5761 entier sous Brest-3 de 1968-01-01 à 1973-09-23 (artefact : trois cantons après la
  fusion du 29 avril 1945) ; aucune appartenance pour Brest, Bohars, Guilers, Gouesnou, Guipavas,
  Le Relecq-Kerhuon et Plouzané du 1973-09-23 au 1992-03-22 ; 2903 nommé « Brest-Ville », 2904 et
  2905 « Brest-2 », « Brest-3 » de 1992 à 1999.
- **À inscrire** : les unités Brest-IV, VI, VII et VIII (I, II, III, V = 2903, 2904, 2905, 2945,
  déjà ancrés) ; 1973 : Plouzané et Guilers dans I, Bohars, Gouesnou, Guipavas, Le Relecq-Kerhuon
  dans VII ; 1985 : Guilers passe à VII, canton de Guipavas créé (Guipavas, Le Relecq-Kerhuon) ;
  une `unit_version` au 1992-03-22 pour les noms de l'art. 3 du décret 91-211 (Brest-Plouzané,
  Brest-Recouvrance, Brest-Centre, Brest-Bellevue). Ancres à poser le jour de l'inscription :
  1985 IV POINT(149034 6836462), VI POINT(146060 6838588), VII nord POINT(146810 6840987), VII sud
  POINT(143686 6837183), VIII POINT(147883 6838123) ; 1973 IV POINT(149034 6836462), VI
  POINT(146663 6838642), VII POINT(146829 6840978).
- **Sans texte** : la 4e section de l'an X (limite Brest-1 / Brest-2) et le régime 1945-1973.
  Hypothèse pour ce dernier : Brest-3 = ouest de la Penfeld (Recouvrance et ancienne
  Saint-Pierre-Quilbignon, 1 879 ha, ligne 1991-L4) ; ligne `29019-1801-P` prête, non écrite.
- **Lignes** : écrites le 23 octobre 2026, source `texte` : dix lignes 1991 (1992-03-22 →
  2013-01-01), dix 1985 (`--morceaux 9 --vides-admis 5`), six 1973 (`--morceaux 7 --vides-admis 3`).
  Population des IRIS au prorata des surfaces à 0,7 point au plus des fractions 2011. Fichiers :
  `cartes/sorties/decoupe_brest/`.

---

## Bastia (2B033)

### 132. Bastia : rien de 1941 à 1982 ; régime de 1973 (Bastia-I à V) absent ; Furiani sous Terravecchia de 1954 à 1973

- **Sources** : décret 73-825 du 18 août 1973, art. 2 (JO du 19 août 1973,
  `jorf_txt/JORF_19730819_192_col.txt`, l. 1079-1139) : Bastia-I (Centre), II (Fango), III
  (Turette), IV (Cimbalo), V (Montesoro, avec Furiani), par listes de voies et de quartiers. Décret
  82-53 du 20 janvier 1982 (JO du 22 janvier 1982, `jorf_txt/JORF_19820122_18_col.txt`,
  l. 346-364) : divise le V en V-Lupino et VI-Furiani-Montesoro. Loi 75-356 : son tableau imprime
  « Bastia (cantons I à IV) » alors que sa liste des circonscriptions en compte cinq. C'est le
  point « Corse 1975 » de `sql/110` § 6 bis. Avant 1973 : aucun texte de limite (le décret de 1811
  ne borne pas) ; un recueil médical de 1873 et une thèse de 1921 (archive.org) placent la limite
  aux ponts du Guadello.
- **Base** : `2849#2003` (Terravecchia) et `#2004` (Terranova) seulement du 1815-01-01 au
  1941-01-01 ; aucune fraction du 1941-01-01 au 1982-03-14. Furiani en 2004 jusqu'en 1941, sans
  canton de 1941 à 1954, en 2003 (Terravecchia) de 1954 au 1973-09-23 (le recueil de 1873 la met à
  Terranova), puis sans canton jusqu'en 1982.
- **À inscrire** : la ville en deux fractions (2003, 2004) de 1941 au 1973-09-23, et Furiani en
  2004 sur cette période, à vérifier ; les unités Bastia-I à V du 1973-09-23 au 1982-03-14 (codes
  20xx jusqu'en 1976, puis 2B03, 2B04, 2B67, 2B68, 2B69), leurs cinq fractions, et Furiani au V.
- **Lignes** : écrites le 23 octobre 2026. `2B033-1815-TV-TN` (1815 → 1973-09-23, source `main`,
  HYPOTHESE : limite de 1973 entre {I, II} et {III, IV, V}, sur le Guadello en ville ; ancres
  datées 2003 POINT(1228300 6199500), 2004 POINT(1227500 6196500)). Passe 1973 (`--morceaux 5`,
  ancres datées I POINT(1228480 6199200), II POINT(1227800 6199850), III POINT(1227367 6198266),
  IV POINT(1228760 6198640), V POINT(1227500 6196500)). Passe 1982, six lignes. Lignes de 1973
  tracées à mi-distance des voies listées (Voronoi), bornées par la limite Bastia-1 / 2 de 2014 et
  le V de 1982 ; population à 1,4 point au plus des fractions 2011. Questions : le Macchione
  (33,6 ha, environ 907 habitants) donné au III / IV contre la liste de 1973 ; les parcelles de
  1982 (droite de 434 m). Fichiers : `cartes/sorties/decoupe_bastia/`.

---

## Paris (75056) — les quartiers partagés entre deux circonscriptions

Tracé le 3 octobre 2026. Lignes, morceaux, points d'ancre et remarques :
`cartes/sorties/paris_coupes_quartiers.csv` (18 lignes, 17 coupes dont une en deux variantes) ;
image `cartes/sorties/paris_coupes_quartiers.png` ; en base, tables de travail
`public.paris_coupe_essai` et `public.paris_coupe_morceaux`. Voirie : `75056_*.geojson` et un
extrait par quartier `75PQnn_*.geojson`.

### 1. FAIT (3 octobre 2026) — les fractions de quartier, par `101` et `98`

- **Décision d'Adrien** : des fractions de quartier, découpées par `98`.
- **Inscrit** : `sql/101_paris_fractions_quartier.sql` lit `circo/paris_fractions_quartier.csv`
  (32 fractions `PQnn#<côté>`, 74 rattachements de niveau `circo`, 14 quartiers) ; `98` prend la
  clé `PQnn` (`coupe_cle()`, `coupe_niveau()`) ; `99` et `export_web.py` suivent la même clé.
  21 lignes et 32 ancres dans `cartes/coupes_ville.csv` et `coupes_ville_ancres.csv`.
- **Recette** : 14 quartiers conformes dans `98` ; `check_coupe_partition('1970-06-01', '75')`
  rend 7 quartiers découpés, recouvrement nul.
- **Reste hors base**, faute d'attribution ou de texte : Grandes-Carrières 1986 (ligne `PQ69-1`
  rangée sans fraction), Javel 1986 (deux variantes dans
  `cartes/sorties/paris_coupes_quartiers.csv`), Grenelle et Javel 1928-1940 (§ 2), Épinettes
  1958-1986 (§ 3). Tant qu'ils n'ont pas de rattachement, le treillis de `84` donne leur sol
  aux quartiers voisins (motif `comblement`).

### 2. Le 15ᵉ en 1928-1940 : la légende divise Grenelle et Javel, le plan non

- **Source** : légende du plan 1928-1940 (« le quartier de Javel était divisé suivant les rues de
  la Rosière et de Lourmel et l'avenue Félix Faure », « le quartier de Grenelle était divisé par
  les rues Dupleix et Violet ») ; plan photographié par Adrien le 3 octobre 2026.
- **Constat** : le plan trace XV1 = Grenelle + Necker et XV2 = Javel + Saint-Lambert par les
  limites de quartier, sans coupe intérieure — comme la transcription. La légende et son plan se
  contredisent. Les deux lignes sont tracées (Grenelle 100,5 + 46,6 ha ; Javel 214,9 + 45,2 ha)
  et **non appliquées**.

### 3. 1958-1986, 17ᵉ : ce que le plan corrige dans la transcription

- **Plaine-Monceau** : la transcription lui donnait la remarque des Batignolles. La légende du
  plan dit « divisé suivant les rues de Prony et de Courcelles ». Ligne tracée : ouest 40,5 ha à
  la 22ᵉ, est 100,3 ha à la 23ᵉ. À corriger dans `circo/paris_decoupage.csv` (remarque).
- **Épinettes** : entier dans la 24ᵉ sur le plan. La ligne `1958-1986, 23, epinettes` de la
  transcription est de trop ; le quartier n'est pas coupé.
- **Batignolles** : bande à l'est de Nollet-Darcet (13,9 ha) à la 24ᵉ, le reste à la 23ᵉ.

### 4. Numéros de circonscription que le plan 1928-1940 contredit

- **11ᵉ** : XI1 = Folie-Méricourt, XI2 = sud-ouest du boulevard Voltaire, XI3 = nord-est. La
  transcription nomme `3/11` la Folie-Méricourt et `1/11`, `2/11` les deux moitiés, à l'identique.
  Sans doute vrai aussi de 1889 à 1919 (la remarque dit « la 2eme et la 3eme »), sans plan vu.
- **7ᵉ** : VII1 = Invalides, Saint-Thomas-d'Aquin et l'est de l'École-Militaire ; VII2 =
  Gros-Caillou et l'ouest. La transcription de 1928-1940 porte l'inverse (`1/7` = Gros-Caillou).
- **12ᵉ, 1958-1986** : le nord de Picpus (127,4 ha) est à la 11ᵉ avec Bel-Air, le sud et le bois
  à la 12ᵉ — l'inverse de ce que les contacts laissaient déduire.

### 5. `ecole-militaire` deux fois dans la même circonscription (1958-1986 circo 5, 1986 circo 3)

- Doublon de saisie déjà noté dans `circo/note_paris.md` : pas une coupe, rien de tracé.
