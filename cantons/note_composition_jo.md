# Dépouillement des JO numérisés — 1 212 cantons, 194 décrets

> **Chiffres à jour, 2 septembre 2026 : 4 739 lignes et 1 212 cantons.**
> Les 4 706 annoncés ici sont ceux du premier passage ; deux reprises ont suivi
> — la séparation des colonnes du JO, puis l'appariement par préfixe — et
> l'« État final » en fin de note porte les valeurs qui font foi.

Fichiers produits : `cantons/composition_jo.csv` (4 706 lignes), 
`cantons/composition_jo_non_appariees.csv` (151 rejets), 
`cantons/controle_composition_jo.csv` (le contrôle par le COG 1999).

Script : `cantons/composition_jo.py`. Contrôle : `cantons/controle_composition.py
--source cantons/composition_jo.csv`.

---

## 1. Le résultat

89 PDF de JO fournis, 86 convertis (trois étaient déjà sur disque), **30 numéros
exploités**.

| | |
|---|---|
| décrets dont on tire une composition | **194** sur 343 au registre |
| cantons distincts | **1 208** |
| lignes (décret × canton × commune) | 4 706 |
| communes distinctes rattachées | 3 461 |

Réparti par année de signature : 1961 (1), 1967 (732), 1970 (30), 1973 (1 951),
1974 (35), 1975 (101), 1976 (56), 1982 (1 035), 1984 (311), 1985 (449), 1988 (5).

Qualité d'appariement des noms : 80,5 % exacts, 2,3 % par `insee_mvt`
(communes disparues), 2,4 % par ressemblance, 9,7 % de cantons faits de
fractions seules, 3,3 % non appariés.

Sur les 58 numéros demandés, 44 sont arrivés ; les 14 manquants (404) portent
26 décrets, surtout 1988-1989.

---

## 2. Pourquoi un second extracteur

`composition_decrets.py` lit la colonne `texte` de
`communes_coupees_1973_1984.csv` — c'est-à-dire les seuls segments qu'un premier
passage avait retenus **parce qu'ils portaient une commune coupée**. Bon chemin
pour chercher les villes partagées ; mauvais pour chercher la composition, parce
qu'un canton sans commune coupée — la grande majorité — n'entre jamais dans le
fichier.

`composition_jo.py` repart du texte du JO et prend tous les segments
« Canton de X comprenant les communes de A, B et C ». D'où 4 706 lignes contre
1 295.

**On lit `*_raw.txt`, pas `*.txt`.** `pdftotext -layout` entrelace les deux
colonnes du JO sur la même ligne et fabrique des listes de communes qui n'ont
jamais existé. Sans `-layout`, l'ordre de lecture des colonnes est respecté.

**Les PDF portaient déjà une couche texte.** Aucun OCR n'a été nécessaire, et
la qualité est très au-dessus de celle des fascicules du COG 1968.

---

## 3. Le contrôle indépendant — COG 1999

Même juge que pour 1973/1982/1984, sur un corpus 2,5 fois plus gros.

| verdict | cantons |
|---|---|
| accord (≥ 80 % des communes dans le même canton en 1999) | **415** |
| accord partiel (50-80 %) | 99 |
| désaccord (< 50 %) | **5** |
| aucune commune retrouvée en 1999 | 8 |
| trop court (< 3 communes, non jugeable) | 282 |

**Sur les 519 cantons jugeables : 3 344 communes sur 3 635 retrouvées dans le
même canton en 1999 — 92,0 %.** L'étalon précédent était de 155 accords,
24 partiels, 0 désaccord.

### Les 5 désaccords, tous du même genre

Échirolles (38, 1973), Trappes (78, 1967), Valdoie (90, 1967), Évry (91, 1967),
Montgeron (91, 1967). Ce sont les banlieues qui ont le plus grossi entre le
décret et 1999, et qui ont donc été **redécoupées entre-temps**. C'est
exactement ce que la mise en garde du contrôle prévoit : un désaccord n'accuse
pas l'extraction, il peut venir du monde.

### Les 8 « aucune commune retrouvée » sont plus instructifs

- **5 relèvent du décret 82-82** (Jarville, Pompey, Saint-Max,
  Saint-Nicolas-de-Port, Tomblaine). Son département est vide, puisque son titre
  dit « divers départements » ; le contrôle cherche dans un département et ne
  trouve rien. Les cinq cantons sont en Meurthe-et-Moselle, autour de Nancy.
  Le verdict est un artefact de notre prudence, pas une erreur de lecture.
- **2 relèvent de la Corse** (73-825, Figari et Tallano-Scopamène). Le décret
  dit « CORSE », classé `20` ; le COG 1999 dit 2A. Même artefact de nomenclature
  que celui déjà signalé au registre.
- **1 est une vraie erreur d'attribution** : « Évreux-Ouest » est rangé sous le
  décret 82-55 (Doubs) alors qu'Évreux est dans l'Eure. Voir § 4.

---

## 4. Contrôle croisé des deux extractions

Là où les deux chaînes traitent le même canton, elles peuvent être comparées.
Elles n'ont ni le même point d'entrée ni le même découpage.

| | cantons |
|---|---|
| présents dans les deux | 283 |
| listes de communes **identiques** | **277** |
| ancienne strictement incluse dans la nouvelle | 6 |
| **divergentes** | **0** |
| seulement dans l'ancienne | 2 |
| seulement dans la nouvelle | 526 |

**Zéro divergence sur 283 cantons.** Les six où l'ancienne est incluse sont des
listes que le nouvel extracteur lit plus complètement.

Les deux cantons que seule l'ancienne connaît méritent d'être nommés, parce
qu'ils disent où la nouvelle est faible : Poitiers-III (73-677, une commune) et
**Évreux-Ouest (82-56)**. Sur ce dernier, c'est l'ancienne chaîne qui a raison.

---

## 5. Comment un décret est attribué à un canton, et ce que ça a coûté

Le JO ne dit pas, à chaque canton, de quel décret il relève. Il faut le déduire.

**La première version votait sur les communes reconnues.** Sur le JO du
22 juillet 1967 elle a donné **568 lignes sur 651 au seul décret des Yvelines**,
et **zéro à celui de l'Essonne**. La raison n'est pas une faute de lecture : en
juillet 1967 l'Essonne n'existe pas — elle naît le 1er janvier 1968 — et ses
communes portent encore des codes `78`. Le vote mesurait la nomenclature, pas le
décret.

**La version retenue s'appuie sur l'ancre** : le JO imprime le numéro du décret
en tête de chacun — « Essonne (décret n° 67-589 du 20 juillet 1967) ». On ne
cherche que les numéros attendus dans ce numéro-là, ce qui écarte d'office les
« Vu le décret n° 66-352 » des visas. Passage de 4 décrets à 6 sur ce JO, et de
64,3 % à 82,4 % d'appariements exacts.

**Mais l'ancre seule ne suffit pas.** Quand l'OCR abîme un numéro, l'ancre
manque et les cantons de ce décret se collent au décret précédent — sans bruit,
et par blocs entiers. Le vote sert donc de contradicteur : si les communes d'un
segment désignent massivement un autre département qui légifère dans le même
numéro, c'est l'ancre qui a tort. Gain : 158 → 191 décrets, et 64,3 % → 80,0 %.

Répartition finale : 3 656 lignes par l'ancre, 869 par le vote contredisant
l'ancre, 49 par le vote seul. La colonne `attribution` le dit ligne à ligne.

**Ce qui reste** : « Évreux-Ouest » (§ 3), où l'ancre de 82-56 a été perdue et où
le segment — une description de limites par des rues — ne cite pas assez de
communes pour que le vote se déclenche. Une sur 809.

---

## 6. Un mot manquait au vocabulaire

Dix-sept décrets restaient muets alors que leur JO était sur disque. Quatre
tenaient à un seul mot : les décrets de 1975 écrivent

> « Le canton de X **comprend** les communes de… »

quand ceux de 1973 écrivent « comprenant ». L'indicatif n'était pas dans
l'expression. Ajouté (`comprend`, `comprennent`), il rend 2 décrets et
112 lignes de plus.

Les treize autres muets restent à voir. Vingt-neuf décrets supplémentaires sont
muets **et doivent l'être** : ce sont des « modifications de limites
cantonales », qui décrivent des tracés de rues et ne contiennent aucune liste de
communes.

---

## 7. Ce que ce fichier n'est pas

- Il **ne pose rien en base**.
- Il ne donne la composition que des cantons **que le décret touche**, jamais
  celle des autres. C'est un delta, pas un état.
- **80,5 % de noms appariés n'est pas 80,5 % d'exactitude.** Un nom parfaitement
  apparié rangé sous le mauvais canton reste une erreur, et l'appariement ne
  peut pas la voir. C'est le contrôle du § 3 qui parle, pas ce taux-là.
- Le taux d'accord de 92 % est un **plancher** : entre le décret et 1999, une
  commune a pu changer de canton légitimement.

---

Sources : Journaux officiels numérisés (Légifrance, licence etalab-2.0),
COG INSEE 1999, GEOFLA, `insee_mvt`. Dépouillé le 28 août 2026.

---

# Reprise du 28 août 2026 — les colonnes, et quatre défauts d'appariement

Ancienne version conservée : `archives/composition_jo_2026-08-28_lecture_entrelacee.csv`.

## Le résultat

| | avant | après | |
|---|---|---|---|
| lignes | 4 706 | **4 737** | +31 |
| cantons | 1 208 | **1 212** | +4 |
| communes distinctes rattachées | 3 461 | **3 562** | +101 |
| appariements `exact` | 3 788 | **3 853** | +65 |
| **`aucun`** | 154 | **72** | **−82** |
| par `prefixe` (nouveau) | 0 | 70 | |
| `prefixe ambigu` (nouveau, déclaré) | 0 | 18 | |
| attribués par l'**ancre** | 3 716 | **4 013** | +297 |

Les deux contrôles indépendants :

| | cantons au titre | égarés | COG 1999 |
|---|---|---|---|
| avant | 120 / 184 — 65,2 % | **2** | 419 accords, 92,0 % |
| après | 122 / 184 — **66,3 %** | **0** | **420 accords**, 92,0 % |

Aucune régression, et les cantons égarés disparaissent.

## 1. La source : le JO est sur deux colonnes

Le script lisait `*_raw.txt` en croyant qu'il suivait l'ordre des colonnes.
C'était faux : `_raw` découpe les lignes fondues par `-layout`, il ne sépare
pas les colonnes. Le contenu d'un décret y paraît AVANT son propre en-tête —
sur `JORF_19820122_18`, le 82-56 a son texte aux lignes 412-431 et son titre à
la 470. D'où « Evreux-Ouest » sous le décret du Doubs et « Lorient-Centre »
sous celui du Cantal.

`cantons/jorf_colonnes.py` produit `*_col.txt`. **Deux méthodes ont été
essayées, et la première est instructive.**

`boite` rappelle `pdftotext` avec une boîte de découpe par colonne. L'ordre est
rétabli — mais le texte est abîmé : le clipping REND À NOUVEAU la page, et tout
ce qui touche la coupure disparaît. L'extraction tombait de 4 706 à **4 414**
lignes et les appariements par ressemblance doublaient.

*Une réparation qui repasse par la source rend une source différente.*

`gouttiere`, retenue, ne redemande rien : elle coupe le texte `-layout` déjà
rendu au blanc vertical qui sépare les colonnes, ligne par ligne. Mêmes octets,
autre ordre. Trois raffinements ont été nécessaires, chacun mesuré :

* couper au blanc **propre à chaque ligne**, dans un voisinage de la
  gouttière — une coupure au même caractère pour toutes tranche dans les mots
  des 15 % de lignes qui débordent ;
* ne pas couper les lignes **pleine largeur** (bandeaux, titres) : coupées en
  deux elles donnent deux moitiés fausses ;
* **désindenter les deux moitiés**, faute de quoi la moitié droite hérite de
  toute la largeur de la gouttière et `nettoie()` ne recolle plus les mots
  coupés en fin de ligne ;
* quand aucune gouttière n'est trouvée, **replier sur la lecture sans
  `-layout`** — pas sur le `-layout` entrelacé, qui est justement ce qu'on
  fuit. *Un repli doit être le moins mauvais des états connus, pas le premier
  sous la main.*

## 2. Le préfixe avant la ressemblance

Le décret écrit « Colleville » là où le référentiel écrit
« Colleville-Montgomery ». La ressemblance orthographique départage ces cas
**à l'envers** : « Colleville » ressemble davantage à « Cléville » (0,89) qu'à
« Colleville-Montgomery » (0,71). C'est ainsi que le canton d'Ouistreham-Riva-
Bella s'était vu attribuer une commune de Troarn.

On essaie donc le préfixe au trait d'union **avant** la ressemblance, dans les
deux sens — le décret abrège (« Colleville ») autant qu'il allonge
(« Ouistreham-Riva-Bella » pour la commune d'Ouistreham, désormais retrouvée).
70 lignes y gagnent un code.

Quand le préfixe désigne **plusieurs** communes — « Colleville » en désigne
deux dans le Calvados, Montgomery et sur-Mer — on ne choisit pas : la ligne
sort en `prefixe ambigu`, sans code, avec ses candidats au fichier des rejets.
18 lignes. *La source ne tranche pas, nous non plus.*

## 3. Un code pris par une pièce ne se partage pas

Passe de rattrapage : quand un acte attribue un même code INSEE à deux cantons
et qu'une seule des lectures est une pièce (`exact`, `disparue`, `prefixe`),
les autres sont refaites en s'interdisant ce code. **Une conjecture ne prend
pas la place d'une pièce.** Deux `exact` sur un même code ne sont pas tranchés
— ce serait une contradiction réelle de la source, et elle doit remonter.

## 4. Trois couperets muets

* **Le plafond de 400 caractères** sur une liste de communes. Le canton de
  Bonnières-sur-Seine produit **401** caractères et disparaissait — sans
  sortie et sans rejet. Porté à 1 200, et le dépassement est désormais
  signalé. *Un plafond qui décide de l'existence d'un canton ne doit ni être
  serré ni être muet.*
* **La césure de fin de ligne** ne se recollait que devant une minuscule.
  « Jouy-\nMauvoisin » restait coupé. On distingue désormais les deux cas : on
  soude sans trait d'union devant une minuscule (césure), on garde le trait
  d'union devant une majuscule (nom composé).
* **La formule « où est fixé son chef-lieu »** n'était pas une borne de liste :
  31 lignes portaient « Fontenay-sous-Bois où est fixé son chef-lieu » comme
  nom de commune et ne s'appariaient à rien. Le canton existait dans le
  fichier avec une commune fantôme.

## 5. Le vote lisait des noms de rues

Un canton urbain est décrit par des RUES. « rue Saint-Laurent », « rue
Colbert », « place Sadi-Carnot » existent aussi comme communes ailleurs en
France, et elles votaient. Le canton de **Marseille-I**, dont l'ancre — le
décret n° 73-812, Bouches-du-Rhône — était juste et à trente lignes de là,
s'est retrouvé en **Haute-Savoie**.

Deux corrections ont été essayées et mesurées avant de retenir la troisième :

1. *voter sur les seules communes lues* → Marseille rentre, mais le contrôle
   par les titres perd ce qu'il avait gagné (égarés 0 → 2). Le vote sur le
   segment travaille vraiment, ailleurs.
2. *refuser toute voix aux cantons sans communes entières* → Marseille rentre,
   Lorient-Centre repart dans le Cantal. Les deux cas s'opposent : à Marseille
   l'ancre a raison, à Lorient c'est le vote.
3. **retenue** — un canton sans communes entières vote avec les deux seuls
   noms de communes que le décret lui donne : **son chef-lieu**, toujours
   nommé, et sa propre tête de nom (« Marseille-I » → Marseille).

*On ne réduit pas le nombre de preuves, on écarte celles qui n'en sont pas.*

## Ce qu'il faut rejouer

`sql/72_registre_actes.sql` recharge `acte_composition` depuis ce fichier —
l'ordre des colonnes est inchangé, le `\copy` passe tel quel. Puis `73`, `74`,
`75`, qui en dépendent.

---

## Correctif du soir — la troncature passe APRÈS la ressemblance

Le premier passage en base a fait parler le § 5 bis de `75` : la commune
disputée avait changé. Ce n'était plus `9724` entre Ouistreham et Troarn, mais
`5861` entre **Cabourg et Ouistreham-Riva-Bella** — et cette collision-là était
de ma fabrication.

Le décret 82-92 donne « Breville » à Cabourg (Bréville, `14106`) et
« Bréville-Beuville » à Ouistreham — lecture OCR de **Biéville-Beuville**,
`14068`. La règle `prefixe lu`, placée avant la ressemblance, tronquait
« Bréville-Beuville » en « Bréville » et tombait sur la commune du canton
voisin. L'ancienne lecture, elle, faisait juste par ressemblance.

**La règle qui en sort : le nom entier porte plus d'information que sa
troncature.** Une ressemblance sur le nom COMPLET (Bréville-Beuville /
Biéville-Beuville, 0,94) doit l'emporter sur une correspondance exacte obtenue
en jetant la moitié du nom. Là où la ressemblance ne trouve rien —
« Ouistreham-Riva-Bella » ne ressemble à « Ouistreham » qu'à 0,69 — la
troncature reste seule, et elle a raison. `prefixe lu` passe donc après.

Et une scorie de numérisation : « Colleville,^ Saint-Aubin-d'Arquenay » faisait
perdre Saint-Aubin-d'Arquenay, le nom ne commençant plus par une majuscule. Les
caractères non alphabétiques sont désormais retirés en tête de nom.

### État final

| | avant | après |
|---|---|---|
| lignes | 4 706 | **4 739** |
| cantons | 1 208 | **1 212** |
| communes distinctes | 3 461 | **3 565** |
| `exact` | 3 788 | **3 855** |
| `aucun` | 154 | **72** |
| codes réclamés par deux cantons d'un même acte | 1 | **0** |
| cantons au titre | 120/184 | **122/184** |
| égarés | 2 | **0** |
| COG 1999 | 419 accords, 92,0 % | **420**, 92,0 % |

Le canton d'Ouistreham-Riva-Bella, qui a servi de fil, est désormais lu
entier : Blainville, Biéville-Beuville, Bénouville, Ouistreham,
Périers-sur-le-Dan, Saint-Aubin-d'Arquenay — et « Colleville » déclaré
`prefixe ambigu`, parce que le Calvados en compte deux et que le décret ne
tranche pas.
