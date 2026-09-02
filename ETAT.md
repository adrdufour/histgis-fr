# État de la base `histgis`

**Dernière mise à jour : 2 septembre 2026**, après le chargement d'ANR-COMMUNES
et la réécriture de `export_web.py`.

Trois documents, trois rôles. **`ETAT.md`** (ici) dit où en est chaque couche
*aujourd'hui* — un état, pas un récit : ce qui est faux est corrigé sur place,
pas ajouté à la suite. **`METHODE.md`** est la référence stable : architecture,
sources, limites, règles de travail. **`JOURNAL.md`** raconte dans l'ordre ce
qui a été tenté, raté et compris ; c'est lui qui porte l'historique, et rien
n'a besoin d'être répété ici pour être conservé. **`RESTE_A_FAIRE.md`** porte
la file d'attente.

> Ce fichier a été condensé le 2 septembre 2026 : il accumulait vingt-cinq
> sections datées où le même chiffre figurait dans trois états successifs sans
> qu'on sache lequel valait. Rien n'a été perdu — le détail de chaque campagne
> est dans `JOURNAL.md` à sa date. Les contradictions relevées au passage sont
> signalées « **à trancher** » ci-dessous plutôt que résolues en silence.

---

## 1. Ce que contient la base

PostgreSQL + PostGIS, schéma `histgis`, EPSG:2154 partout. Elle répond à :
*quelle était la carte des cantons et des circonscriptions législatives
françaises à telle date ?* — cible **1870-2012**, Paris remontant à **1815**.

```sql
SELECT unit_id, nom, geom FROM snapshot_geom('1885-06-01', 'canton');
SELECT unit_id, nom, geom FROM snapshot_geom_anr('1885-06-01', 'canton');
```

### Effectifs, par couche et par origine

Les totaux ne sont pas donnés en bloc, parce qu'aucun ne l'est de façon fiable
sans interroger la base : douze fichiers ont ajouté des atomes et des
rattachements depuis le chargement initial. Ce qui suit est **ce que chaque
étape a posé**, avec sa date de mesure.

| couche | effectif | posé par | mesuré le |
|---|---|---|---|
| chargement 1870-1940 | 38 442 atomes (333 fractions), 4 838 unités, 293 233 rattachements | `01`-`07` | 9 août |
| couverture 1870-1940 | +414 prolongements, +60 atomes-filles | `11`, `15`, `42`, `46` | 17-20 août |
| circo 1870-1940, comblement | 1 003 périodes sur 320 atomes | `40_scission_circo` | 15 août |
| trame communale 1943-2012 | 44 atomes modernes, 39 291 intervalles de chronologie | `20`, `21` | 15 août |
| cantons 1999-2012 | 3 844 cantons, 37 319 rattachements, 998 fractions | `24`, `25` | 15 août |
| circo 2009 (2010-2013) | 539 unités, 37 257 rattachements | `27`, `43` | 20 août |
| circo 1986 (1986-2010) | 534 unités, 37 132 rattachements | `28`, `43` | 20 août |
| jalon 1954 | 30 035 atomes, 2 946 cantons | `66`-`69` | 28 août |
| jalon 1968 | 32 659 rattachements, 2 899 cantons | `58`, `59` | 28 août |
| salves 1973 / 1982 | 1 905 rattachements, 270 cantons | `75` | 28 août |
| salves restantes | 873 rattachements, 128 cantons | `76` | 28 août |
| transferts datés INSEE | 32 rattachements, 13 cantons | `77` | 28 août |
| report arrière depuis 1999 | 36 296 rattachements, 422 838 atome-années | `79` | 29 août |
| trame géométrique datée | 45 113 polygones, 38 074 atomes pourvus | `82` | 1ᵉʳ sept. |

Instantanés utiles : `snapshot(1968-06-01)` = 32 842 rattachements et 2 911
cantons ; `snapshot(1990)` = 23 233 ; `snapshot(1998)` = 37 267.

> **Chiffres périmés à ne pas reprendre** : le jalon 1968 a valu successivement
> 30 939 puis 32 552 puis 32 659 rattachements au fil des relectures OCR ; seule
> la dernière valeur, et le `snapshot` qui l'accompagne, valent aujourd'hui.

**Intégrité déléguée à la base.** Deux contraintes `EXCLUDE USING gist` : un
atome n'appartient qu'à une unité par niveau à un instant donné, deux versions
d'une même unité ne se chevauchent pas. Une troisième, sur `atom_geom_anr` :
un polygone par atome et par date. Toutes validées sur les vraies données.

---

## 2. Où en est chaque couche

### 2.1 Géométrie communale — deux trames, l'une datée

**Depuis le 1ᵉʳ septembre 2026, la base porte deux trames géométriques.**

| | `atom_geom` | `atom_geom_anr` |
|---|---|---|
| origine | GEOFLA 2011, un polygone par atome | ANR-COMMUNES, 1790-2020, polygones datés |
| lignes | 38 442 | **45 113**, 38 074 atomes pourvus |
| recouvrement à 1870 | 3 945 km² | **101,0 km²** |
| lue par | `snapshot_geom()` | `snapshot_geom_anr()`, avec repli sur `atom_geom` |

Le recouvrement de 101,0 km² a été mesuré **deux fois par deux chemins qui ne
partagent pas une ligne de code** — shapely + STRtree hors base le matin,
PostGIS + GiST en base le soir — et les deux tombent au dixième près. Résidu
nommé : Notre-Dame-de-Briançon 93,6 km², Tours 6,9. `atom_geom` et `membership`
n'ont pas été touchés.

**Ce qui lit `atom_geom` directement voit toujours l'ancienne valeur.** C'est
une transition, pas une migration : les deux tables coexistent, et seul ce qui
passe par `snapshot_geom_anr()` ou par l'export web bénéficie de la correction.

Le pont est une jointure d'entiers : `id_com` d'ANR **est** l'identifiant
Cassini de `atom.cassini`. 99,91 % des atomes non-fraction retrouvés, 99,66 %
d'accord sur les noms. Cinq règles de sélection, aucune n'arbitrant une
frontière, dans `sorties/anr/anr_regles.py` et `sql/82_anr_geom.sql`.

### 2.2 Cantons 1870-1940 — close, contrôlée

Complète, contrôlée contre les cantons dissous de Victor Gay (§ 3.1), et rien
n'y a bougé depuis le 20 août. Effectifs conformes à l'histoire à chaque date
testée : 89 départements en 1870, 87 après la perte de l'Alsace-Moselle,
90 après 1919 ; 2 862 à 3 028 cantons ; bascules liste/uninominal aux bonnes
années. Les 1 690 atomes dont la chronologie est trouée exactement de 1871 à
1919 sont l'Alsace-Moselle — une validation, pas une anomalie.

**Un fait à connaître avant de cartographier** : le département **54 change de
territoire au 1ᵉʳ janvier 1871 sans changer de numéro.** Les deux périodes ne se
recouvrent pas, donc une requête à date donnée reste sans ambiguïté ; mais une
planche qui empile « le 54 » sur toute la série montrera **deux emprises**. Et
les deux mouvements de 1871 ne sont pas symétriques : la Meurthe perd sa partie
est — **242 de ses 708 communes portent aujourd'hui un INSEE 57** — et gagne
l'arrondissement de Briey, venu de la Moselle. Meurthe-et-Moselle n'est donc pas
la Meurthe amputée, c'est la Meurthe amputée **plus** Briey. (Voir § 6 : cela
suppose que `39_meurthe_1870.sql` soit appliqué.)

### 2.3 Cantons 1943-1999 — comblés en jalons, plus en trou

**Plus aucune date entre 1954 et 1999 ne renvoie le vide.** Ce n'est pas une
carte complète — de l'ordre de 1 200 cantons sur 4 000 à certaines dates — mais
le blocage structurel du projet a cessé d'en être un.

| ce qui répond | fondement de la date | fichier |
|---|---|---|
| 1954 | un recensement — un fait | `66`-`69` |
| 1968 | un recensement — un fait | `58`, `59` |
| Yvelines 1968 | la naissance d'un département — un fait | `74` |
| 1973 et 1982 | convention, 37,0 % de dates incertaines | `75` |
| les autres salves | convention, **93,7 % incertaines** | `76` |
| 66 transferts de commune | 30 datés au jour près par l'INSEE | `77` |
| 1987-1999 par report arrière depuis 1999 | inférence validée (§ 3.4) | `79` |
| 1969-1973 par report avant depuis 1968 | inférence validée, **pas encore posée** | `81` |

**Asymétrie à connaître avant toute lecture.** L'incertitude de date ne pèse que
sur les cantons *modifiés*. La part des actes de création pure s'effondre avec
le temps — 100 % en 1967, 63,8 % en 1973/1982, **9,1 %** ensuite. Donc :
**toute lecture des cantons entre 1985 et 1998 doit joindre `p76_qualite`**,
sans quoi elle prendra une convention pour un fait. 1973-1984 est sensiblement
plus sûr, 1968 et 1954 le sont tout à fait.

Les deux jalons de recensement s'accordent à **94,5 %** sur 25 258 communes —
deux fascicules, deux chaînes OCR, deux méthodes d'appariement, et c'est le seul
contrôle dont la période dispose. Dispersion à surveiller : Belfort 67,9 %,
Corse 85,9 %, Moselle 86,5 %, Isère 89,4 %. Le désaccord ne dit pas laquelle des
deux lectures a tort. La Seine (10,0 %) et la Seine-et-Oise (46,4 %) ne sont pas
au bas de la distribution mais **hors** d'elle : l'éclatement de 1968 a
redécoupé la région parisienne en même temps qu'il la renumérotait — deux
cartes, pas deux lectures contradictoires.

Qualité de lecture : 1954, `ferme` 88,5 %, `nom_flou_confirme` 11,4 %,
`atome_ambigu` 0,1 % (`c54_qualite`) ; 1968, `ferme` 79,9 %,
`canton_conteste` 3,1 % (`c68_qualite`), dépouillement de 30 128 lignes sur
31 400, soit 95,9 %.

**Le registre des actes** (`72`) porte 343 décrets moissonnés par titre et
1 212 cantons dépouillés des JO ; `acte_departement` et `acte_sans_effet` en
portent les exceptions, bâties en creux avec leur fondement cité. Le registre
consolidé compte **723 démembrements réels, dont 559 datés au décret (77 %)**,
90 % de ces dates tombant dans les décennies 1970 et 1980.

**Ce que le registre ne recensera jamais** : les **274 transferts isolés de
communes** entre cantons. L'annexe VII de Gaudillère ne consigne pas ce type de
mouvement, et aucune autre source ne les date en bloc. C'est une limite connue,
pas une lacune du dépouillement. S'y ajoutent les **48 cantons créés entre 1986
et 1999**, nommés un par un mais non datés faute de source couvrant la fenêtre.

### 2.4 Cantons 1999-2012 — posés, contrôlés

3 843 cantons en 1999, 3 846 en 2012, 37 319 rattachements, zéro chevauchement,
zéro rattachement entre 1941 et 1998 hors de ce que la période 2.3 a posé
depuis. Contrôlés contre la couche CANTON de GEOFLA (§ 3.2).

Trois décisions fondées, non conventionnelles :

* **Un seul espace de noms.** Un canton garde son `unit_id` de 1870 à 2012.
  Ce n'est pas une commodité : `ct_codes.do` de TRF-GIS aligne explicitement les
  codes de Gay sur le COG de 1954, et la filiation 1954 → 1999 est celle de
  l'Insee. 92,4 % des 2 943 codes partagés portent d'ailleurs le même nom. Ce
  qui est affirmé, c'est l'identité du canton ; pas sa composition dans
  l'intervalle.
* **Paris est résolu par la donnée**, pas supposé : le fichier cantons donne
  `cheflieu` = 75101 pour le canton 15 jusqu'à 75120 pour le 34. 280
  rattachements posés sans hypothèse.
* **Marseille et Lyon sont des pseudo-cantons**, et c'est la convention du
  domaine, pas un pis-aller : GEOFLA fait de même (`CODE_CANT = '99'`, d'où
  3 708 cantons chez l'IGN contre 3 876 au COG), comme Gay pour 1870-1940.
  Chaque arrondissement a été affecté au canton GEOFLA contenant son point
  intérieur — les 16 marseillais dans `1399`, les 9 lyonnais dans `6999`.

### 2.5 Circonscriptions législatives

| | 1870-1940 | 1986 | 2009 |
|---|---|---|---|
| période | série TRF-GIS | 24 nov. 1986 → 22 fév. 2010 | 23 fév. 2010 → fin |
| unités | 1 772 (dont 132 provisoires) | 534 | 539 |
| avec territoire | — | **533** | **524** |
| rattachements | — | 37 132 | 37 257 |
| Paris | par quartier depuis `52`-`57` | absent du tableau source | 4 circos sur 18 |

Recettes à zéro des deux côtés modernes : aucun chevauchement, aucun atome
relevant des deux découpages, bascule nette au 23 février 2010, 1870-1940
intact. La somme des maxima départementaux de 2009 retrouve **539 sièges
métropolitains**, le compte officiel, sans correction.

**Le résidu de 1986 est légitime et déclaré** : 113 communes n'ont aucune
circonscription de 1986 à 2013 parce que **le tableau officiel écrit
« circonscriptions 13 et 16 » sans répartir les communes**. Toutes recensées
dans `circo/circo_1986_indetermine.csv` (135 lignes), concentrées sur 18 cantons
du Nord (67 communes), du Rhône, des Bouches-du-Rhône, du Bas-Rhin, de
Charente-Maritime et de la Drôme, dont sept entièrement.

**Défaut d'affichage à corriger** : ces 113 communes ne sont pas *marquées*
indéterminées sur la carte, elles en sont **absentes**, ce qui contredit la
règle du projet — *ce qui n'a de nom nulle part est signalé comme tel, pas
maquillé*. Voir `RESTE_A_FAIRE.md`.

### 2.6 Paris — la couche la plus fine, et la seule qui remonte à 1815

Trame des **80 quartiers administratifs** reconstruite par union d'IRIS
(CONTOURS-IRIS, INSEE-IGN, Licence Ouverte 2.0 — le jeu de la Ville de Paris
étant en ODbL, inutilisable ici). 992 IRIS, 4 quartiers par arrondissement.

**Contrôle : 80 noms sur 80 retrouvés** dans le vocabulaire de la transcription
de l'atlas Gaudillère, deux sources jamais mises en contact. Douze écarts, tous
de nom, aucun de trame. Surface 105,43 km² contre 104,90 à GEOFLA — c'est l'IRIS
qui a raison (105,4 km² officiels, bois compris), GEOFLA qui généralise.

**386 circonscriptions sur 15 divisions de 1863 à 1986**, chacune rendant
105,43 km² — Paris entier à chaque date. Quatorze divisions se résolvent sans un
nom hors trame. Deux acquis non cherchés : **1958-1986 est posé** alors qu'il
est bloqué nationalement (à Paris il se définit par quartiers, pas par cantons),
et le régime de scrutin se lit dans les données — 1919-1928 et 1945-1958 ne
comptent que 3 circonscriptions pour 80 quartiers, scrutin de liste par secteur.

**Limites** : la trame ne vaut qu'à partir de 1860 (bois annexés en 1852 et
1860) ; sa fidélité aux limites de 1876 est réputée, non vérifiée ; 16 noms
d'avant 1860 se résolvent contre la trame moderne en désignant d'autres
territoires, et ne sont écartés que par une barrière de date.

### 2.7 Outre-mer

Rouvert le 16 août 2026, dans un espace séparé (`om_*`, `40_outremer.sql`), sans
mélange avec la métropole. Circonscriptions DOM déjà sur disque, GEOFLA
2015-03-04 pour les trames, CONTOURS-IRIS couvrant 61 coupes sur 61. Pacifique
et Algérie restent bloqués par la licence.

---

## 3. Les contrôles indépendants

Quatre étalons extérieurs, dont **aucun ne passe par une ligne de notre code**.
C'est le dispositif central du projet : les recettes internes valident la
cohérence, jamais l'exactitude.

| # | étalon | ce qu'il juge | verdict |
|---|---|---|---|
| 3.1 | cantons dissous de Gay | 1870-1940, géométrie et attributions | 3 désaccords hors artefact sur 38 235 atomes |
| 3.2 | couche CANTON de GEOFLA | 1999-2012 | 11 atomes sur 37 297, soit 0,03 % |
| 3.3 | HAC (filiation communale) | les paris de `11` | 98,2 % au canton, **100 %** aux circos |
| 3.4 | registre des actes vs COG 1999 | le report `79`/`81` | 94,9 % contre 33,5 %, 49 dép. sur 49 |
| 3.5 | ANR-COMMUNES (dates de naissance) | le report arrière de `11` | 84,1 % contre 33,9 %, 357 dates sur 359 |

### 3.1 Gay — 1870-1940

`sql/controle_gay.sh` (exige `gdal-bin`), sorties dans
`sorties/rapport_controle_gay.txt` et `controle_gay.gpkg`.

| | 1870 au départ | 1870 aujourd'hui | 1940 |
|---|---|---|---|
| pseudo-cantons comparés | 2 775 | 2 775 | 2 824 |
| tracés identiques | 82,7 % | **94,49 %** | **95,33 %** |
| IoU moyen | 0,9826 | **0,99281** | **0,99325** |
| territoire non couvert | 5 926 km² | **238 km²** | **32 km²** |
| communes non réclamées | 494 | 39 | 2 |

**Le résultat qui compte n'est pas le taux, c'est sa décomposition.** Le
désaccord ne suit pas la source de la géométrie, il suit le **partage de
polygone** :

| situation | atomes | en désaccord | |
|---|---|---|---|
| seul sur son polygone | 35 309 | 8 | 0,02 % |
| partage un polygone, même canton | 2 273 | 0 | 0,00 % |
| partage un polygone, cantons différents | 653 | 140 | **21,44 %** |

Et les 8 « hors conflit » se réduisent à **3** une fois vu que cinq d'entre eux
(3 `hac_partage`, 2 `hac`) partagent eux aussi leur polygone — vérifié atome par
atome. **Ces trois-là sont les paris perdus du correctif de scission, conservés
délibérément.** La base n'a aucun désaccord avec Gay qui ne soit ni un artefact
de trame, ni un choix assumé et tracé.

Corollaire à ne pas manquer : le « 3 sur 6 » qui semblait condamner
`hac_partage` mesure la trame, pas l'échec du choix arbitraire. Le contrôle Gay
ne peut plus servir à le condamner — sur ces six-là, il ne tranche pas. Ce qui
ne l'innocente pas : le rattachement par nom reste arbitraire et révocable.

**Les quatre paris perdus**, laissés en l'état parce que les corriger en
recopiant Gay ferait perdre au contrôle son indépendance :

| atome | INSEE | apparu | chez nous | chez Gay | km² |
|---|---|---|---|---|---|
| 37390 | 08447 | 1872 | Mézières | Charleville | 32,69 |
| 36437 | 77454 | 1874 | Donnemarie-en-Montois | Nangis | 10,60 |
| 17501 | 56086 | 1891 | Quiberon | Belle-Île | 3,25 |
| 17191 | 56085 | 1891 | Quiberon | Belle-Île | 2,25 |

HAC contredit Gay sur les deux premiers et donne raison à `11` (§ 3.3). Deux
sources indépendantes se contredisent : le dossier n'est pas clos, il n'est
plus vide.

### 3.2 GEOFLA — 1999-2012

`26_controle_ign.sql`. 3 162 pseudo-cantons comparés, appariement parfait dans
les deux sens, 548 463 km² contre 548 488 — **écart de 26 km², 0,005 %**, IoU
moyen 0,9646. Onze atomes rangés ailleurs sur 37 297, dont **zéro** pour
`fraction_cog`, `arrondissement`, `successeur` et `creation_arriere`.

Réserve d'emblée : contrôle plus faible que celui de Gay, nos communes étant de
l'édition GEOFLA 2011 et ces cantons de l'édition 2014. Les pires cas sont des
cantons urbains de moins de 3 km² en petite couronne. Seuls les écarts
d'attribution, qui portent sur des communes entières, concluent.

### 3.3 HAC — la filiation que `11` ne connaissait pas

`hac/hac_filiation.py`, `sql/45_controle_hac.sql`, **qui ne contient aucun
`INSERT`, `DELETE` ni `UPDATE`** : corriger la base d'après HAC lui ferait
perdre son indépendance.

La clé est donnée par la source : **l'`id` de HAC EST la colonne `cassini` de
TRF-GIS**. Aucun appariement par nom pour la fille — la clé la plus sûre du
projet. La mère, elle, n'est nommée qu'en clair et sous son nom d'*aujourd'hui*
(« La Baule-Escoublac » contre « Escoublac ») : indexer les deux formes fait
passer la résolution de 92,8 % à **99,3 %**, 444 filiations sur 447.

Verdict : **392 accords contre 7 désaccords au canton (98,2 %), 366 contre 0
aux circonscriptions (100 %)**. Les 7 désaccords ont tous la même forme — une
commune née d'une mère relevant d'un *autre* canton, l'acte de création changeant
le canton en même temps qu'il crée la commune. Le pari de `11` échoue exactement
là où il devait échouer, et nulle part ailleurs.

Bâtir `11` sur la filiation HAC a été essayé, mesuré, **et abandonné** :
11 paris perdus sur 425 contre 4 sur 414. Cause : HAC ne nomme qu'une mère quand
il y en a plusieurs. Détail dans `METHODE.md`.

### 3.4 Le registre des actes — le report de `79` et `81`

`80_report_1968_avant_diag.sql` § 6 quinquies. L'affirmation testée n'est pas la
tautologie « les communes que les décrets nomment ont changé de canton », mais
l'affirmation forte et réfutable du registre : **en dehors de ces 2 536 atomes,
rien n'a bougé en trente et un ans.**

| population | atomes | accord 1968/1999 |
|---|---|---|
| jamais nommé par un décret | 30 306 | **94,90 %** |
| nommé par un décret | 2 536 | **33,49 %** |

Écart de 61,4 points, et le test apparié ne laisse aucune place au doute :
**49 départements sur 49 dans le même sens**, écart médian +62,1, soit 2⁻⁴⁹ sous
l'hypothèse nulle. Le § 6 octies, écrit pour lister les anomalies, n'en trouve
aucune.

La borne, et elle n'est pas 100 % : les 5,1 % de désaccord résiduel mêlent l'OCR
de 1968, les cantons vidés sans être nommés (biais connu, de sens connu, qui
joue *contre* l'hypothèse) et d'éventuels vrais trous du registre. Le repère :
94,9 % se situe entre les 89,8 % de 1954 → 1968 et les 99,5 % de 1940 → 1954,
sur 31 ans contre 14.

Un département à regarder : **95**, dont les jamais-nommés ne font que 78,1 % —
le plus bas, et de loin. Val-d'Oise est né en 1968 de l'éclatement de la
Seine-et-Oise ; c'est probablement le redécoupage de la région parisienne, pas
un trou du registre.

### 3.5 ANR-COMMUNES — les dates de naissance

`83_anr_ecart_couverture.sql`, lecture seule. Ce qui devait n'être qu'une
explication d'écart de recette est devenu **la validation la plus nette
qu'ait reçue `11_scission.sql`**.

486 atomes vivants en 1870 sans polygone ANR. Décomposition :

| motif | n | dont posés par `11` |
|---|---|---|
| ANR ne fait naître la commune qu'après cette date | 379 | 359 |
| trou interne dans la chronologie ANR | 69 | 68 |
| Paris — trame des quartiers | 20 | 0 |
| ANR ignore cet `id_com` | 15 | 0 |
| ANR arrête la commune avant cette date | 3 | 0 |

| origine | n | qu'ANR fait naître après 1870 | |
|---|---|---|---|
| posé par `11` | 427 | 359 | **84,1 %** |
| non posé par `11` | 59 | 20 | **33,9 %** |

Et sur les 359 vraies naissances, `debut_reel` (mouvements INSEE) et `anr_debut`
(éditions ANR) tombent **sur la même année 357 fois — 99,4 %**, sans une ligne
de code commune. Le report arrière de `11` cesse d'être un pari raisonnable pour
devenir une inférence corroborée par une source qui ne l'a jamais vu.

---

## 4. Limites connues — à citer en légende de toute carte

Renvois vers `METHODE.md` § 6, où chacune est détaillée et mesurée.

* **§ 6.1 — Recouvrement de la trame 2011.** 3 945 km² comptés deux fois en 1870
  au niveau du contrôle, 12 930 entre cantons réels. **Ramené à 101,0 km² dans
  `atom_geom_anr` depuis le 1ᵉʳ septembre**, mais `atom_geom` reste intacte avec
  ses 3 945 : c'est la valeur que voit tout ce qui ne passe pas par
  `snapshot_geom_anr()`.
* **§ 6.2 — Trame incomplète.** Communes créées après la date interrogée.
  Ramenée de 5 926 km² à **238 km² en 1870** et 32 en 1940 par `11`, `15`, `42`
  et `46`.
* **§ 6.2 quinquies — Marseille et Lyon n'ont qu'un canton de 1999 à 2012.**
  Leur nombre réel a évolué (Marseille 22 → 25 en 2005, Lyon 13 → 14 en 2002)
  sans que le pseudo-canton bouge : la simplification masque une évolution réelle
  sans fausser le territoire.
* **§ 6.3 — Six atomes `hac_partage`** au rattachement arbitraire, tracé et
  révocable.
* **§ 6.4 — 132 circonscriptions sans nom**, provisoires, citées par le
  membership et absentes des nomenclatures TRF-GIS.
* **§ 6.5 — Paris n'est couvert qu'à 4 circonscriptions sur 18 en 2009**, le
  découpage coupant à l'intérieur des arrondissements ; 45 atomes n'ont aucune
  circonscription en 2012, 8 atomes relèvent de deux circonscriptions en 1986.
* **§ 6.6 — 113 communes indéterminées de 1986**, déclarées telles par la
  source, qui écrit « circonscriptions 13 et 16 » sans répartir les communes.
* **§ 6.7 — Poids mort géométrique** : sept communes rétablies après 2011 dont
  l'atome porte le polygone de leur absorbante, sans trou de couverture mais
  sans territoire propre.
* **§ 6.8 — Cinq limites propres à ANR** : les 333 fractions qu'il ne sait pas
  découper ; la Corse livrée en instantané (360 polygones justes, zéro édition
  historique contre 27,1 % nationalement) ; l'absence de frontière nationale
  (§ 5) ; les 101 km² résiduels ; et **532 `id_com` sur 40 572 (1,31 %) ayant un
  trou de chronologie non déclaré** — 11 113 années-communes, médiane 12 ans,
  75 trous couvrant 1870 et 6 couvrant 1940.

---

## 5. Ce qui bloque encore

1. **La frontière nationale, pour l'extension avant 1870.** ANR **dessine la
   France actuelle à toute date** : la Savoie et les Alpes-Maritimes y sont
   françaises en 1815 (769 communes, 14 899 km²), l'Alsace-Moselle en 1900
   (1 701 communes, 14 575 km²). Sans effet sur 1870-1940, où `membership`
   décide seul de ce qui s'affiche — mais poser 1815 depuis ANR sans rien faire
   d'autre, c'est annexer la Savoie quarante-cinq ans trop tôt. **La frontière
   devra venir de la nomenclature d'époque, département par département.**
2. **1986-1989 : 37 actes, aucun texte en clair, aucun dépouillé.** C'est le
   vrai mur de la période récente, et c'est aussi la fenêtre des 48 cantons
   créés entre 1986 et 1999, nommés et non datés.
3. **Les villes à découper** — 119 communes, 214 coupes, rien de tracé.
   La trame d'accrochage est en base (`iris_ville`, 4 219 IRIS, 211 coupes sur
   214 pourvues) ; le travail de digitalisation dans QGIS reste entier.
   Marseille est le cas d'école, protocole dans
   `gaudillere/protocole_georeferencement.md`.
4. **Six départements que le report ne rattrape pas** — 94, 95, 62, 77, 29, 91 :
   trop d'actes intercalés pour se résoudre contre 1999. Il leur faudrait un
   jalon intermédiaire, un recensement ou un acte que le registre ignore.

---

## 6. À vérifier en base — points ouverts, non tranchés

Ces points sont ouverts parce qu'ils demandent d'interroger la base ou une
pièce, pas parce qu'ils sont difficiles. Ils sont listés ici pour ne pas être
crus résolus.

**Ils se tranchent en une commande** :

```bash
psql -d histgis -f sql/diag_passages.sql     # lecture seule
```

Elle confronte l'inventaire des 44 tables de trace **attendues** à ce que la base
porte (§ 1), lit par leur effet les fichiers qui n'ont pas de trace (§ 2), et
lit par leur effet ceux dont la trace manque ou est vide (§ 4). Écrite le
2 septembre 2026, précisément parce que la question « ce fichier est-il passé ? »
n'avait pas de réponse.

### Ce que le premier passage a rendu, le 2 septembre 2026

**35 traces peuplées sur 44, aucune trace orpheline** — l'inventaire couvre
exactement ce que la base porte. Restent neuf lignes, qui ne disent pas toutes
la même chose :

| fichier | trace | lecture |
|---|---|---|
| `32_marseille_geom` | absente | **normal** — attend le géoréférencement, chantier ouvert |
| `43_circo_fraction` | absente | **normal** — exclu de `rejouer_apres_rebuild.sh` exprès : il ne répare qu'après un rejeu *isolé* de `24` |
| `50_noms_perdus_trfgis` | vide | a tourné **avec** `appliquer=1` (sa trace n'existe que dans ce cas) et n'a rien eu à réparer |
| `42_rattachement_arriere` | vide | a tourné, zéro cas — état sain **si** Chisa et Butry ont bien leur passé (§ 4 e) |
| `37_reparer_encodage` | absente | **n'a jamais tourné avec `appliquer=1`** : sa trace est créée dans le `\if`. La réparation CP1252 → Latin-1 (1 975 valeurs, tous les `œ`) n'a peut-être jamais été appliquée |
| `25_pseudo_canton` | absente | **à expliquer** — il est pourtant appelé sans condition juste après `24` dans la chaîne |
| `40_outremer` | absente | **à expliquer** — appelé lui aussi, et son CSV d'entrée est bien sur le disque |
| `81_report_1968_avant` (×2) | absentes | attendu : le fichier n'a jamais été joué |

Les trois lignes en gras sont les seules qui appellent une action. Le § 4 du
diagnostic les lit par leur **effet**, seul juge : `25` par ses 25 rattachements
d'arrondissement au 1ᵉʳ juin 2012, `40` par la présence des tables `om_*`, `37`
par les octets de contrôle C1 dans `unit.nom` et `unit_version.nom`.

*Une trace absente n'est pas un défaut par elle-même ; c'est une question. Neuf
alarmes indistinctes valent moins que trois alarmes triées, et un diagnostic qui
crie à chaque passage cesse d'être lu.*

* ~~**`39_meurthe_1870.sql` est-il appliqué ?**~~ — **OUI, mesuré le 2 septembre
  2026** : 0 canton en `99`, 73 en `54`, et zéro atome rattaché à deux cantons du
  54 à la même date. L'état est conforme. **Mais `39` n'a toujours aucune table
  de trace** : ce qui est établi, c'est que la base est dans le bon état, pas que
  le fichier soit passé — un état peut être atteint autrement. C'est le même
  fichier qu'un `rebuild.sh` avait défait en silence entre le 15 et le 30 août.
  La dette reste ouverte (`RESTE_A_FAIRE.md` § 0).
* **`81_report_1968_avant.sql` n'est PAS joué** — établi le 2 septembre par deux
  chemins : `p81_trace` et `p81_qualite` sont absentes de la base, et
  `snapshot(1969-06-01)` rend **0 rattachement**. Attendu au passage :
  ~32 842 lignes, ~191 000 atome-années, `1969-06-01` passant de 0 à des dizaines
  de milliers, et **1974 et au-delà ne devant pas bouger** — le repère est
  5 198 rattachements sur 474 cantons au 1ᵉʳ juin 1974.
* **`38_decret_1982_ain.sql` — état indéterminé.** Le décret n° 82-77 pose trois
  choses distinctes : la remontée des trois fractions de Bourg-en-Bresse au
  26 janvier 1982, trois communes entières (01254 Montagnat, 01369 Saint-Just →
  `0105` ; 01344 Saint-Denis-les-Bourg → `0138`), et trois `unit_version`. Le
  § 2 c de `diag_passages.sql` les lit séparément, parce qu'un rejeu partiel en
  laisse passer une et pas les autres. **Piège au rejeu** : `38` n'insère que si
  la période est libre, et depuis que `75`, `76` et `79` écrivent sur 1982-1999,
  il peut ne rien poser **sans rien dire**. Lire le § 2 c après le rejeu, pas le
  code de retour.
* **Chisa et Butry-sur-Oise — à trancher.** `ETAT.md` les rangeait parmi les
  « territoires neufs » aux côtés de Tende et La Brigue, et `METHODE.md` parmi
  les créations d'avant 1943 hors de portée du fichier INSEE. **Les deux étaient
  faux** : `insee_mvt` documente Chisa (`mod 20`, 12 avril 1947, détachée de
  Ventiseri) et Butry (1ᵉʳ août 1948, d'Auvers-sur-Oise). Le traitement a été
  fait par `42_rattachement_arriere.sql` ; c'est la **rédaction** qui restait
  fausse — corrigée ici et dans `METHODE.md` le 2 septembre.
* **Deux rattachements dans le trou 1941-1998** que la recette de `24` comptait
  sans les attendre. L'un est la ligne de `38` (décret de 1982, donnée réelle,
  exception légitime) ; l'autre n'a jamais été identifié. La recette a depuis été
  réécrite pour contrôler une filiation plutôt qu'une absence.
* **Le canton `1930`** de 1951 et celui de 1999 ne partagent qu'une commune sur
  sept : identité douteuse, à trancher par le registre cantonal.
* **Le doublon 99/57 sur neuf noms de cantons** — Albestroff, Château-Salins,
  Delme, Dieuze, Fénétrange, Lorquin, Phalsbourg, Sarrebourg, Vic-sur-Seille,
  exactement les cantons annexés. Communes distinctes de part et d'autre, aucun
  double rattachement. Question sur la source, à porter à Victor Gay.
* **Oyonnax** : l'annexe VII dit « dédoublement », donc canton source disparu ;
  l'Insee garde le code `0123` renommé Oyonnax-Nord.
* **Le fond cantonal de Gaudillère est-il datable ?** Si une nomenclature
  d'époque permettait d'en identifier le millésime, tout l'atlas deviendrait
  exploitable d'un coup. Question à poser à Victor Gay.
* **Numérotation `sql/`** : deux fichiers portent le numéro `40`
  (`40_outremer.sql`, `40_scission_circo.sql`), et le « `82`, le chaînage acte
  par acte » évoqué dans les notes d'août entre en collision avec
  `82_anr_geom.sql`. Le chaînage devra prendre un numéro libre.

---

## 7. Ce que la carte web sait faire, depuis le 1ᵉʳ septembre

`cartes/export_web.py` a été réécrit pour la trame datée. L'affirmation qui
tenait toute son architecture — *la géométrie d'un atome ne change jamais* — est
devenue fausse avec `atom_geom_anr`, et la brancher sans toucher au reste aurait
produit une carte qui se trompe **en silence**.

Ce qui est posé : `communes.json` porte par atome une **liste de versions**
`v: [{a, k, c, g, r}]` ; la signature couvre la composition **et** les `poly_id`
en vigueur ; `annees_candidates()` lit la troisième famille de bornes ; le nom
de fichier est le md5 du **contenu sérialisé**, la signature d'entrée ne servant
plus qu'à décider ce qu'il faut recalculer. Un intervalle sans géométrie s'écrit
**comme vide** (`g: null`) et la commune n'est pas dessinée — ne rien écrire
n'est pas neutre quand le lecteur en aval prolonge la version précédente.

Le repli est écrit, pas subi : chaque version porte `r`, chaque unité porte
`n_anr` et `n_repli`, et la page affiche séparément l'export sans épaisseur,
les communes en repli à cette année, et celles qu'aucune source ne sait
dessiner.

**Deux choses ne se vérifieront qu'après un export réel complet** : le poids
(attendu 92 Mo → deux à trois fois plus) et la **coïncidence visuelle** des
limites cantonales et communales sur une année où ANR édite un polygone — c'est
là, et seulement là, que se verrait une erreur d'ordre d'opérations.

---

## 8. Comment tout se rejoue

```bash
cd ~/Téléchargements/projet_carte/sql
./rebuild.sh                 # load.sh → GEOFLA → 05 → 06 → 07 → 11 → 15
./rejouer_apres_rebuild.sh   # le reste de la chaîne, dans l'ordre
./controle_gay.sh            # contrôle indépendant, facultatif, exige gdal-bin
```

`rebuild.sh` est **destructif** — `load.sh` fait `DROP SCHEMA histgis CASCADE` —
et c'est voulu : `geom_correspondance.csv` et les CSV de `build/` sont lus par
`02_load.sql`, rejouer `05` seul ne servirait à rien.

**Lire « Qui dépend de qui » dans `sql/README.md` avant de rejouer un fichier
isolé**, et `sql/CHAINE.md` pour l'inventaire complet. Deux mécanismes cassent la
chaîne sans le dire : un fichier qui crée des unités ne peut pas être rejoué tant
qu'un autre les référence (clé étrangère), et la suppression de ses atomes emporte
par cascade ce que d'autres ont posé dessus. **Un résultat obtenu sur une base à
demi reconstruite est indiscernable d'un résultat juste.**

**Piège de propagation** : si seuls les `.sql` circulent entre les deux dossiers,
`build/`, `geom_correspondance.csv` et les notes peuvent être périmés d'un côté
sans que rien ne le signale. Le correctif Marseille est resté sans effet une
journée entière pour cette raison.
