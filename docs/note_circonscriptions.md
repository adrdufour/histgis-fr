# Note de lecture — circonscriptions législatives 1986 et 2012

Source : *Tableau de correspondance des communes et des cantons pour les
élections législatives de 2012*, ministère de l'Intérieur, publié sur
data.gouv.fr sous **Licence Ouverte / Etalab** — donc compatible CC BY-SA et
republiable sur Wikipédia.

Fichier `circo/correspondance_2012.xls`, une seule feuille « Communes de
France », 37 875 lignes utiles, 9 colonnes. Écrite avant tout chargement, comme
`note_lecture_trfgis.md` l'a été pour TRF-GIS, et pour la même raison : ce
fichier ne dit pas ce qu'on croit à première vue.

---

## 1. Ce que le fichier contient

Une ligne par couple **(canton, commune)**, avec les deux découpages côte à
côte : `Circ. législative 1986` et `Circ. législative 2012`. C'est exactement la
maille de nos atomes et de nos atomes-fractions — le raccord se fait sans
transformation.

Métropole : **37 704 lignes, 36 830 communes, 3 883 cantons**. Ces 3 883 cantons
sont *exactement* ceux que `24` a posés pour 2012. Le fichier et la base
parlent la même nomenclature.

### Le calendrier, à ne pas confondre avec les millésimes

| découpage | élections concernées |
|---|---|
| ordonnance de 1958 | 1958, 1962, 1967, 1968, 1973, 1978, 1981 |
| **loi du 24 novembre 1986** | **1988, 1993, 1997, 2002, 2007** |
| **ordonnance du 29 juillet 2009** | **2012** (et 2017, identique) |

L'élection de 1986 elle-même s'est tenue **à la proportionnelle
départementale**, sans circonscriptions. La carte dite « de 1986 » ne sert donc
qu'à partir de 1988.

Le découpage de 1958 n'est pas dans ce fichier, et il renvoie aux cantons de
1958 — hors d'atteinte tant que le trou cantonal 1943-1998 n'est pas comblé.

---

## 2. Les pièges, tous vérifiés sur pièces

### 2.1 Les codes n'ont pas de zéros de tête

`Code département` vaut `1` pour l'Ain, `Code commune` vaut `2` pour
L'Abergement-de-Varey. Concaténer naïvement confond l'Ain 355 et Marseille
(13055) : c'est l'erreur qui m'a d'abord fait compter 2 818 communes
multicantonales là où il y en a **354**.

Le code INSEE se reconstitue en `dep.zfill(2) || com.zfill(3)`. En revanche
`Code dépt-canton` est correctement cadré sur 4 caractères, et vaut toujours
`dep || ct` — vérifié, zéro écart sur 37 875 lignes.

### 2.2 L'outre-mer utilise les codes du ministère de l'Intérieur

`ZA`, `ZB`, `ZC`, `ZD` et non `971` à `974`. Sans effet ici, l'outre-mer étant
hors périmètre, mais il faut le filtrer explicitement.

### 2.3 Le fichier descend SOUS la commune, et se répète

Le `Code commune` n'est pas toujours numérique :

| forme | lignes | signification |
|---|---|---|
| numérique | 37 345 | commune entière |
| `###SN##` | 213 | section électorale |
| `###AR##` | 102 | arrondissement municipal |
| `###SR##` | 44 | secteur (Marseille) |

**89 communes sont décrites à deux granularités à la fois** : une ligne pour la
commune entière ET des lignes pour ses sections. Lyon apparaît sous `123` *et*
sous `123AR01` à `123AR09`. Marseille n'a pas de ligne commune, mais ses 16
arrondissements *et* ses 8 secteurs — un secteur valant deux arrondissements,
le territoire y est décrit deux fois.

**Additionner les lignes sans choisir un niveau double donc le territoire.**

### 2.4 En 1986, une valeur peut être du texte

145 lignes portent un `Circ. législative 1986` non numérique : `1 et 2`,
`3 4 et 5`, `13 et14`, `19 et 21`… Un canton à cheval sur deux
circonscriptions y est noté ainsi plutôt que sur deux lignes. La colonne 2012,
elle, est **entièrement numérique** — les cas de partage y sont exprimés par
duplication de ligne, ce qui est plus propre.

### 2.5 Paris 1986 est inutilisable

Toutes les lignes parisiennes portent `Circ. législative 1986 = 42`. Paris
comptait 21 circonscriptions en 1986 ; 42 n'est pas un numéro de
circonscription. La preuve par le total : la somme des maxima départementaux
donne **576 sièges métropolitains**, alors que la carte de 1986 en compte 555.
576 − 42 + 21 = **555**, exactement. L'anomalie est donc entièrement localisée
à Paris, et le reste du fichier est juste.

Pour 2012 le même calcul donne **539 sièges métropolitains** — le compte
officiel, sans correction.

---

## 3. Ce qui se pose sans difficulté, et ce qui résiste

**Le découpage de 2012 est directement constructible.** Colonne entièrement
numérique, cantons identiques aux nôtres, 539 sièges vérifiés. Les 77 couples
(canton, commune) partagés entre deux circonscriptions se concentrent sur 39
communes, dont l'essentiel est Paris, Lyon et Marseille — que les lignes `AR`
résolvent, puisque nous avons ces arrondissements comme atomes.

**Le découpage de 1986 se pose partout sauf à Paris**, au prix d'un traitement
des 145 valeurs textuelles.

**Restent irréductibles** quelques communes coupées entre deux circonscriptions
sans subdivision plus fine — Vallauris (06155, cantons 0635, circos 06-07 et
06-08), Saint-Priest (69290, canton 6945, circos 69-13 et 69-14). Même
indivisibilité qu'au § 6.1 de `METHODE.md`, un cran plus bas.

---

## 4. Conception proposée

Un niveau de granularité par ligne, choisi ainsi :

- **arrondissement** (`AR`) pour Paris, Lyon et Marseille — nos atomes
  d'arrondissement existent ;
- **commune** partout ailleurs ;
- **ignorer** les lignes `SN` (aucune section électorale dans nos atomes) et
  `SR` (les secteurs doublonnent les arrondissements).

Les unités `circo` reçoivent un identifiant distinct de celles de 1870-1940,
qui suivent la convention `L…@AAAA` / `U…@AAAA`. Deux découpages, deux jeux
d'unités, avec un `membership` par période : 1988-2007 pour la carte de 1986,
2012 pour celle de 2009.

Le trou 1941-1987 reste vide, comme pour les cantons — et pour la même raison.

---

## 4 bis. Le découpage de 2012, posé — et ce que Paris coûte

`27_circo_2012.sql` pose **539 unités** et **37 253 rattachements**, sans
chevauchement, sans toucher à 1870-1940. Quatre lignes source ne trouvent pas
d'atome — Bleury, Bihorel, Fort-Mardyck et Saint-Pol-sur-Mer, fusions de
2010-2012 que notre chronologie place ailleurs. Effet de millésime attendu.

**Mais 524 circonscriptions seulement ont un territoire.** Quinze n'en ont
aucun : quatorze à Paris, une à Lyon.

La cause est nette. Le découpage de 2009 **coupe à l'intérieur des
arrondissements** — treize des vingt arrondissements parisiens relèvent de deux
ou trois circonscriptions. Notre unité la plus fine à Paris étant
l'arrondissement, ces atomes sont indivisibles et ont été écartés ; les
circonscriptions qui n'avaient qu'eux se retrouvent vides.

**Le pseudo-découpage a été envisagé et écarté**, mesure à l'appui : regrouper
les circonscriptions qui se partagent un arrondissement relierait **17 des 18
circonscriptions parisiennes en une seule composante**. Paris deviendrait un
bloc unique — une perte bien pire que quinze unités vides. À Marseille (8
circonscriptions liées) et Lyon (6), la couverture survit ; ailleurs les
composantes ne dépassent pas quatre.

**Ce qui est retenu, et pourquoi.** L'état est conservé tel quel. La base n'est
pas une carte imprimée mais une base interrogeable, et sa convention est
constante depuis le trou cantonal : l'absence signifie « on ne sait pas », la
présence « on sait ». Les quatre circonscriptions parisiennes pourvues — 1ʳᵉ,
2ᵉ, 5ᵉ et 7ᵉ — le sont d'arrondissements réellement non partagés ; les
supprimer jetterait une information vraie.

**À citer en légende de toute carte de 2012** : Paris n'est couvert qu'à quatre
circonscriptions sur dix-huit, et 31 atomes relevant de deux circonscriptions
sont écartés — 45 atomes sans circonscription au total.

## 4 ter. Le découpage de 1986, posé — et plus propre que celui de 2012

`28_circo_1986.sql` pose **534 unités** et **37 129 rattachements**, période du
24 novembre 1986 au 22 février 2010. Trois communes ne se raccordent pas
(Bleury, Bihorel, Fort-Mardyck), même effet de millésime qu'en 2012.

Les deux amputations sont celles annoncées : **Paris absent** — 21
circonscriptions, code « 42 » inutilisable — et **135 lignes écartées** pour
valeur textuelle. Ce qui reste, 534 circonscriptions pour 534 sièges, est
exactement la carte de 1986 moins Paris.

**533 circonscriptions sur 534 ont un territoire**, contre 524 sur 539 en 2012.
Le découpage de 1986 suit mieux les cantons : il n'y a pas d'équivalent du
morcellement parisien de 2009.

**Huit atomes ont dû être écartés**, et la raison mérite d'être notée parce
qu'elle n'était pas visible à l'extraction. Celle-ci ne trouvait aucun couple
(canton, entité) partagé — c'était vrai. Mais les arrondissements de Marseille
et de Lyon sont rattachés à un **pseudo-canton** (§ 6.2 quinquies de
`METHODE.md`) : toutes les lignes d'un arrondissement se résolvent donc vers le
même atome, quel que soit leur canton. Deux cantons du même arrondissement dans
deux circonscriptions différentes, et l'atome relève des deux. Sept
arrondissements marseillais et un lyonnais sont dans ce cas.

C'est le pseudo-canton qui se paie un niveau plus haut : en renonçant à
distinguer les cantons de Marseille, on renonce aussi à distinguer les
circonscriptions qui les suivent.

**La circonscription perdue est identifiée : `13-08`**, huitième des
Bouches-du-Rhône. Elle n'apparaît que dans trois atomes — `A13211`
(13-06 / 13-08), `A13212` (13-01 / 13-08) et `A13213` (13-07 / 13-08) — tous
trois écartés. Elle était donc **composée exclusivement de fractions des 11ᵉ,
12ᵉ et 13ᵉ arrondissements de Marseille**, sans une seule commune ni un seul
arrondissement entier. Elle disparaît intégralement dès qu'on refuse de
trancher, et c'est cohérent : nous ne savons rien d'elle que la trame puisse
porter.

### Récapitulatif des deux découpages

| | 1986 | 2009 |
|---|---|---|
| période | 24 nov. 1986 → 22 fév. 2010 | 23 fév. 2010 → fin de série |
| scrutins | 1988, 1993, 1997, 2002, 2007 | 2012 |
| unités créées | 534 | 539 |
| avec territoire | **533** | **524** |
| rattachements | 37 129 | 37 253 |
| Paris | **absent** (21 circos) | 4 circos sur 18 |
| atomes écartés | 8 | 31 |

## 4 quater. Paris est irréductible, et ce n'est pas une dette

Ce que la base porte pour Paris en 2012 : **4 circonscriptions sur 18**, par
sept arrondissements non partagés.

| circonscription | arrondissements |
|---|---|
| `75-01@2009` | 1er, 2e, 8e |
| `75-02@2009` | 5e |
| `75-05@2009` | 3e, 10e |
| `75-07@2009` | 4e |

En 1986, aucune : le tableau du ministère code les 21 circonscriptions
parisiennes « 42 ».

J'avais envisagé de descendre au **quartier administratif** — Paris en compte
quatre-vingts, quatre par arrondissement — en supposant que l'ordonnance de
2009 s'y arrête. **Elle ne s'y arrête pas** : certaines circonscriptions
incluent des *fractions de quartier*, définies par listes de voies.

La conséquence est nette et vaut d'être écrite comme telle : **aucune trame
administrative ne permet de représenter les circonscriptions parisiennes**. Ni
la commune, ni l'arrondissement, ni le quartier. Il faudrait descendre à la
voie, ce qui sort du modèle — un atome est une unité au rattachement stable, et
un côté de rue n'en est pas une.

Paris n'est donc pas « pas encore fait ». Il est hors de portée de la
géographie que ce projet manipule, et le déclarer vaut mieux que de le
poursuivre.

## 5. Ce que cette note ne dit pas

Elle ne dit rien du découpage de **1958**, absent de ce fichier et suspendu au
trou cantonal. Rien non plus de l'outre-mer, hors périmètre. Et elle suppose ce
fichier exact : comme le reste, il devra être noté contre une source extérieure
— les contours de circonscriptions publiés sur data.gouv.fr feraient l'affaire,
au même titre que GEOFLA pour les cantons.
