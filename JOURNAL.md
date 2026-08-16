# Journal de bord — contrôle et correction de la base 1870-1940

Récit chronologique, pour se souvenir non seulement de ce qui a été fait, mais
de ce qui a été essayé, raté, et pourquoi. Les trois documents se répartissent
ainsi :

- **`JOURNAL.md`** (ici) — l'histoire, dans l'ordre où elle s'est passée.
- **`ETAT.md`** — où en est la base aujourd'hui, et quoi faire ensuite.
- **`METHODE.md`** — la référence stable : sources, chaîne, limites.

À tenir en ajoutant une section datée en fin de fichier.

---

## 9 août 2026 — le contrôle indépendant

### Point de départ

Base `histgis` complète pour 1870-1940 : 38 442 atomes, 4 838 unités, 293 233
rattachements, aucune géométrie manquante. Toutes les recettes internes
passaient — zéro chevauchement, zéro orphelin, effectifs conformes à
l'histoire. Trois limites étaient connues et documentées.

Restait une question sans réponse : **ces contrôles valident la cohérence, pas
l'exactitude.** Rien ne prouvait que la carte produite fût la bonne.

D'où le choix de commencer par le contrôle indépendant : TRF-GIS livre pour
1870 et 1940 les cantons **déjà dissous** par Victor Gay, polygones qui ne
passent par aucune ligne de notre code.

### Le premier piège : les pseudo-cantons

Les shapefiles de Gay ne sont pas découpés en cantons réels mais en
**pseudo-cantons** : Montluçon-Est et Montluçon-Ouest ne forment qu'un
ensemble, parce que la trame communale ne sait pas couper une commune en deux.
Gay bute sur la même limite que nous, au même endroit. La comparaison ne peut
donc se faire qu'à ce niveau, avec les `MAPPING.tab` comme clé — lesquels ne
listent que les regroupements urbains, 289 lignes en 1870, l'identité valant
pour tout le reste.

### Le second piège, et l'erreur commise

Premier passage : IoU moyen 0,952, **239 clés orphelines**, 22 689 km²
manquants côté Gay, et les 25 pires écarts tous chefs-lieux.

Diagnostic : chez Gay un ensemble urbain n'occupe pas **un** polygone mais
plusieurs. Le polygone `pct_type = 'Pseudo canton'` ne porte que la commune
indivise — la ville — et les communes entières de chaque canton restent sous le
code du canton réel. Moulins : `0381` = les 8,5 km² de la ville, `0323` et
`0324` = les communes rurales. Trois polygones pour deux cantons.

Le repliement n'avait été appliqué qu'à notre côté : la comparaison opposait
deux cantons entiers à un centre-ville. Confirmation par le comptage — les 115
polygones `Pseudo canton` valent exactement les 115 pseudo-cantons produits par
le mapping.

**Corrigé en repliant les deux côtés.** Appariement parfait ensuite, zéro
collision de codes.

### Le verdict

| | 1870 | 1940 |
|---|---|---|
| tracés identiques | 82,7 % | 93,6 % |
| IoU moyen | 0,983 | 0,992 |

Puis la décomposition atome par atome, croisée avec l'origine de la géométrie :

| Source | Atomes (1870) | En désaccord |
|---|---|---|
| `geofla` non partagé | 34 894 | **0** |
| `geofla` partagé | 1 420 | 2 |
| `successeur` | 1 466 | 137 |
| `hac` | 11 | 2 |
| `hac_partage` | 6 | 3 |

**Aucun désaccord parmi les 34 894 atomes dont la géométrie vient directement
de GEOFLA.** Là où les données sont directes, elles sont exactes ; là où elles
sont reconstruites, elles se trompent dans les proportions annoncées. Les
`hac_partage`, dont le choix était arbitraire, se trompent 3 fois sur 6.

Acquis au passage : les polygones de Gay sont parfaitement disjoints, les
nôtres se recouvrent de **3 945 km²** — première mesure en surface des 218
communes revendiquées par plusieurs cantons. Et le département 99 de Gay est la
Meurthe d'avant 1871.

---

## Ce que le contrôle a révélé, et que rien d'interne ne pouvait voir

### 1. Les trous de couverture (5 926 km²)

`km2_nous_seul` valait 0,0 dans les 89 départements de 1870 : jamais de
territoire en trop, mais 5 926 km² manquants — huit fois l'écart de 1940. Un
écart à sens unique n'est pas une erreur d'attribution, c'est un trou.

Cause : la correspondance vers GEOFLA est plusieurs-vers-un. Quand une commune
d'époque s'est **scindée** depuis, un seul des codes issus de la scission est
retenu et le territoire de l'autre n'est réclamé par personne. `06` traite les
fusions ; le symétrique n'existait pas.

Démonstration au km² : 494 communes non couvertes pour 6 197 km², moins Tende
et La Brigue (271,1 km², italiennes jusqu'en 1947 et absentes de la couverture
de Gay elle-même) → **5 926 contre 5 926 attendus**. Et 743 contre 744 en 1940.

Bonne surprise : l'essentiel de ces communes est né **entre 1870 et 1940**,
donc TRF-GIS les suit déjà et leur atome existe. HAC n'a pas été nécessaire.

### 2. Le préfixe amputé de Marseille (133,66 km²)

`geom_correspondance.csv` donnait `1320` au lieu de `132`. Le `LIKE '1320%'` ne
prenait que les arrondissements 1 à 9. GEOFLA ne contient **aucun code 13055** :
Marseille n'y existe que sous ses seize arrondissements.

**Un préfixe trop long n'échoue pas, il ampute en silence.** L'atome avait une
géométrie, `check_geom()` ne signalait rien, toutes les recettes passaient.

### 3. La réutilisation des codes de canton en 1871

Découverte en analysant les erreurs du correctif de scission. TRF-GIS réemploie
les codes `depct` de part et d'autre de la rupture de 1871 : le 5705 de 1870
relève de la numérotation de la Meurthe, celui de 1921 de la Moselle
reconstituée. **Deux cantons sous une même clé**, que `unit_id` traite comme
une identité pérenne unique. C'est une limite du schéma, pas du correctif.

---

## Le correctif de scission, et son affinage

`11_scission.sql` prolonge vers l'arrière le premier rattachement des atomes
apparus en cours de série. Pari : *une commune nouvelle reste dans le canton de
sa mère.*

Trois garde-fous d'abord — seul le premier rattachement, chronologie du canton
d'accueil, recodages écartés. Résultat : **441 prolongements, 7 paris perdus**,
98,4 %.

Les sept noms ont désigné le défaut : trois relevaient de la rupture de 1871.
D'où un **quatrième garde-fou** — ne retenir que la plage d'existence
*continue* du canton aboutissant à la date d'apparition.

| | 3 garde-fous | 4 garde-fous |
|---|---|---|
| atomes prolongés | 441 | 414 |
| paris perdus | 7 | **4** |
| non couvert (1870) | 800 km² | 944 km² |
| IoU moyen | 0,99196 | 0,99173 |

Il retire 27 prolongements pour en supprimer 3 faux. Décision assumée : les 144
km² rendus au non-couvert sont **déclarés inconnus plutôt que rattachés au
hasard**, et sur ce terrain l'accord avec Gay ne prouvait rien — pour une
commune créée sous administration allemande, il a extrapolé comme nous.

Les quatre paris perdus restants — Mézières/Charleville, Donnemarie/Nangis,
Houat et Hœdic — n'ont **pas** été corrigés. Les régler en recopiant les
réponses de Gay ferait perdre au contrôle son indépendance, donc sa valeur.
Ils se tranchent sur pièces d'archives.

---

## Un incident de propagation

Le correctif Marseille est resté sans effet malgré un rechargement complet.
`diag_marseille.sql` a montré que la base lisait encore `cible = 1320` avec
l'ancien commentaire : **`geom_correspondance.csv` n'était pas propagé jusqu'à
la machine qui exécute `psql`, alors que les `.sql` l'étaient.**

Corrigé sur place par `sed`. À surveiller — si seuls les `.sql` circulent,
`build/` et les notes peuvent être périmés d'un côté sans que rien ne le
signale.

---

## État à la fin de la journée

Parcours complet du contrôle, à 1870 :

| | au départ | à l'arrivée |
|---|---|---|
| tracés identiques | 82,7 % | **92,8 %** |
| IoU moyen | 0,9826 | **0,9919** |
| pseudo-cantons sous 0,90 | 171 | 79 |
| surface commune | 98,21 % | 99,13 % |
| territoire non couvert | 5 926 km² | **811 km²** |
| communes non réclamées | 494 | 98 |

1940 suit à 93,63 % et 0,99235, 610 km² non couverts. Les deux dates sont au
même niveau, ce qu'elles n'étaient pas au départ — l'écart était le symptôme.

Sur **38 235 atomes de 1870, 148 sont rangés ailleurs par Gay** (0,39 %), dont
**trois seulement** sans explication connue.

### Fichiers produits

| Fichier | Rôle |
|---|---|
| `sql/08_controle_gay.sql` | mesure : appariement, IoU, surfaces |
| `sql/09_ecart_detail.sql` | explique : département, atome, paires, score du correctif |
| `sql/10_couverture.sql` | communes de la trame que nul atome ne réclame |
| `sql/11_scission.sql` | correctif : prolongement arrière, 4 garde-fous, réversible |
| `sql/12_conflit_successeur.sql` | diagnostic des 138 désaccords résiduels |
| `sql/13_double_comptage.sql` | réconcilie les deux mesures du recouvrement |
| `sql/14_cle_partage.sql` | attribue l'écart résiduel à la clé de regroupement |
| `sql/15_creation_arriere.sql` | atomes pour les communes nées après la série |
| `sql/controle_gay.sh` | orchestre 08 → 09 → 10, export GeoPackage |
| `sql/rebuild.sh` | reconstruction complète : load, GEOFLA, 05 → 07, 11 |
| `sql/diag_marseille.sql` | diagnostic ponctuel, gardé comme modèle |
| `METHODE.md` | note de méthode |

Ajouté aussi à `05_geom.sql` : un tableau affiché à chaque chargement disant ce
que chaque préfixe `union_prefixe` capte, avec le compte attendu — Paris 20,
Marseille 16, Lyon 9. Pour que le bogue de Marseille ne puisse pas se répéter
en silence.

---

## Le verdict de `12` : l'hypothèse tenait

`12_conflit_successeur.sql`, écrit la veille au soir, a été lancé. Il testait
l'idée que sur les 138 désaccords `successeur`, le `membership` dise vrai et que
ce soit la géométrie qui mente.

La colonne qui tranchait était `desaccord_hors_conflit` : les atomes en
désaccord dont le polygone n'est partagé avec personne. Elle vaut **zéro**.

| situation | atomes | en désaccord | |
|---|---|---|---|
| seul sur son polygone | 35 309 | 8 | 0,02 % |
| partage, même canton | 2 273 | 0 | 0,00 % |
| partage, cantons différents | 653 | 140 | **21,44 %** |

Le désaccord ne suit pas la source de la géométrie, il suit le partage. La
deuxième ligne est la plus parlante : quand deux atomes partagent un polygone
mais relèvent du même canton, l'union les recolle et le taux tombe à zéro.

Le compte se referme sur les 148 atomes connus : 140 dans les groupes éclatés,
8 hors conflit — 3 `hac_partage`, 2 `hac`, et 3 `geofla` qui sont exactement les
trois paris perdus du correctif de scission. **Plus un seul désaccord
inexpliqué.**

Et les trois départements où nous revendiquions du territoire de trop tiennent
chacun à un polygone : Haute-Marne 130,1 km² (70122), Deux-Sèvres 88,1 (49099),
Marne 59,0 (52182). Au km² près.

Une piste de travail se referme donc sans travail : reprendre les 138 atomes à
la main n'aurait rien corrigé. C'est le meilleur usage qu'on puisse faire d'un
fichier de diagnostic.

---

## `13` : un commentaire faux, et ce qu'il cachait

`12` annonçait 12 822 km² comptés en double et affirmait que le chiffre devait
« ressembler » aux 3 945 km² de `08`. Il en est 3,25 fois plus grand. Plutôt que
de trancher au jugé, `13_double_comptage.sql` mesure la même chose aux deux
niveaux et par deux méthodes indépendantes.

| | géométrie | nomenclature |
|---|---|---|
| entre cantons réels | 12 930 | 12 822 |
| après repliement | 3 945 | 3 837 |
| absorbé par le repliement | 8 985 | 8 985 |

L'explication est le repliement lui-même. `12` compte entre cantons réels ; `08`
travaille sur `ctrl_nous`, dissous par `deppct`. Or le repliement réunit
précisément les cantons qui se partagent une commune — c'est sa raison d'être.
Le commentaire de `12` a été corrigé.

**Ce que je n'avais pas prévu :** le résidu n'est pas urbain. Sur les 3 837 km²
qui survivent, 3 296 viennent de 105 groupes qui ne subissent aucun repliement —
des communes rurales partagées entre deux cantons ordinaires — contre 541 de
restes urbains. Le repliement règle le cas des villes en entier. Les 25 groupes
les plus coûteux de `12` étaient tous des villes ; ceux de `13` sont tous ruraux.

Deux contrôles croisés au passage. Le double comptage chez Gay est **nul** —
548 202 km² en somme comme en union : le phénomène est chez nous et non dans la
comparaison. Et l'écart entre son union et la nôtre, 548 202 contre 547 391,
vaut **811 km²**, exactement le trou de couverture mesuré par `10`. Deux chemins
indépendants, même nombre — le genre de coïncidence qui n'en est pas une.

Reste un résidu de **108 km²** entre les deux méthodes, identique aux deux
niveaux. Un décalage constant désigne une cause unique et bornée : probablement
les 17 atomes `hac` et `hac_partage`, rattachés par nom, dont le `code_2011`
n'est qu'une approximation — deux atomes portant le même polygone sous deux
codes différents seraient invisibles au comptage par nomenclature et bien vus
par la géométrie. Noté comme suite, enjeu 0,8 %.

---

## `14` : les 108 km², et une hypothèse fausse en chemin

Puisque la méthode géométrique ne suppose rien, c'est celle par nomenclature qui
devait se tromper — donc sa clé. `14_cle_partage.sql` refait le calcul avec
trois clés : celle de `12`, une version rendue sensible à `atom_geom.source`, et
l'empreinte binaire du polygone.

| clé | groupes | canton réel | après repliement |
|---|---|---|---|
| `cle_12` | 36 506 | 12 822 | 3 837 |
| `cle_source` | 36 506 | 12 822 | 3 837 |
| **`cle_geom`** | 36 489 | **12 930** | **3 945** |

L'empreinte retombe exactement sur les mesures géométriques. L'écart était une
affaire de clé, rien de plus : aucune attribution en cause.

**J'avais tort sur la cause.** Je soupçonnais les atomes `geofla` figurant aussi
comme `insee_ancien` dans les mouvements INSEE, qui auraient reçu la clé de leur
successeur par le `coalesce` : `cle_source` n'en distingue **qu'un seul**. La
bonne piste était l'autre — les atomes rattachés par nom, dont aucune colonne ne
dit quel polygone ils portent. Cinq groupes : Lyon 47,85, 2A325 19,35,
51606 16,78, 60606 14,73, 08227 9,32. Somme **108,03**, et la constance du
décalage s'explique enfin — chacun ajoute une unité, donc sa surface une fois de
plus à chaque niveau.

Leçon d'ingénierie, valable partout ailleurs : **grouper par la géométrie,
jamais par un code**. `code_2011` est une reconstruction, l'empreinte est un
fait. Le correctif à porter dans `12` n'est pas un `coalesce` plus fin.

### Ce que la section 5 a sorti au passage

Les cinq atomes en cause sont trois `hac_partage` et deux `hac` — trait pour
trait la composition des cinq désaccords que `12` rangeait « hors conflit ». Ils
n'y étaient que parce que sa clé ne voyait pas leur partage.

La requête a confirmé, aux cinq `atom_id` près et aux cantons près : 28580
(6910), 37694 (2053), 17193 (0828), 35396 (6020), 39369 (5125).

**`desaccord_hors_conflit` tombe donc de 8 à 3 sur 38 235 atomes** — les trois
paris perdus, conservés délibérément. La base n'a plus un seul désaccord avec
Gay qui ne soit ni un artefact de trame, ni un choix assumé et tracé.

Corollaire : le « 3 sur 6 » qui condamnait `hac_partage` mesure la trame, pas
l'échec du choix arbitraire. Il ne l'innocente pas pour autant — le rattachement
par nom reste arbitraire et révocable —, mais le contrôle Gay ne peut plus
servir à le condamner. Sur ces six-là, il ne tranche pas. Distinction qui n'est
pas de pure forme : elle change ce qu'on a le droit d'écrire en note de méthode.

C'est la dernière question que ce contrôle laissait ouverte. Le volet 1870-1940
est clos sur le fond.

---

## La dette technique payée : `12` groupe par l'empreinte

Le correctif est porté. `12_conflit_successeur.sql` groupe désormais sur
`md5(ST_AsEWKB(geom))`, `code_2011` restant comme simple étiquette lisible.
Sortie : 36 489 groupes, 236 éclatés, **12 930 km²** — et
`desaccord_hors_conflit` à **3**, produit par le fichier au lieu d'être
reconstitué à la main. Lyon apparaît enfin dans les 25 groupes les plus coûteux,
avec 430,7 km² et ses deux codes mêlés `69123;6938`.

Deux bénéfices annexes. `max(km2_polygone)` cesse d'être une approximation, tous
les membres d'un groupe ayant maintenant la même géométrie par construction — ce
que mesurait la § 4 de `14`, désormais sans objet. Et une colonne
`codes_multiples` rend visibles les polygones que l'ancienne clé séparait.

**Correction d'une prévision fausse au passage :** j'attendais 5 dans cette
colonne, il en sort **15**. Les 15 sont bien à codes mêlés ; seuls 5 sont *aussi*
éclatés entre cantons et portent les 108 km², les 10 autres tenant dans un seul
canton. La colonne a été dédoublée pour dire les deux.

`13` garde délibérément l'ancienne clé : son objet est de documenter l'écart, le
« corriger » lui ferait perdre sa fonction. Une note l'y précise.

Reste une réserve mineure : la ventilation rural/urbain du résidu (3 296 contre
541) a été établie avant le correctif et ne répartit pas les 108 km² restitués.
La conclusion ne bouge pas, la précision oui.

---

## `15` : les communes nées après la série

Dernier morceau du § 6.2. `11` avait comblé les communes nées entre 1870 et
1940 ; restaient celles nées après, que TRF-GIS n'a jamais vues et qui n'ont
aucun atome à prolonger. Les mouvements INSEE les documentent et nomment leur
mère.

Conception retenue : créer un **atome-fraction** portant le polygone de la fille
et lui recopier l'appartenance de la mère, plutôt qu'élargir la géométrie de la
mère. La première voie aurait été plus courte ; la seconde préserve le
découplage géométrie/attribution, qui est ce qui fait tenir tout le reste.

Premier passage : 55 atomes, 522 km², non couvert 811 → 293 km² en 1870 et
610 → 88 en 1940, tracés identiques 92,8 → 94,45 % et 93,63 → 95,29 %. Zéro
chevauchement. Le nouveau rattrapage se place tout seul dans la hiérarchie de
fiabilité : 3,70 % de désaccord, entre `geofla` et `successeur`.

Petite satisfaction : 54 atomes en 1870 contre 55 en 1940. Une fille mosellane
dont la mère n'a aucun rattachement en 1870 n'a pas été comblée. Le garde-fou
qu'il avait fallu écrire explicitement dans `11` découle ici de la méthode
elle-même — on recopie une chronologie au lieu de la prolonger.

### Deux défauts, dont un évité par chance

**Le test « sans atome » est trop naïf.** Il compare des empreintes de polygones
entiers, donc les 16 arrondissements de Marseille et 2 de Lyon en sortent comme
non couverts — alors que leur territoire est porté par un atome `union_prefixe`
dont le polygone est leur union. Ils ont été écartés uniquement parce que leur
mère `13055` n'existe pas dans GEOFLA. **Si elle avait existé, Marseille aurait
été compté deux fois, et ma recette d'empreintes partagées ne l'aurait pas vu** :
le polygone d'un arrondissement n'égale pas celui de l'union. Une recette qui ne
peut pas attraper l'erreur qu'elle vise n'est pas une recette.

**L'appariement des mères est trop strict.** Val-de-Reuil et Marcheprime sont
restés non couverts alors qu'Incarville et Biganos sont des communes ordinaires.
`atom_geom.geom` passe par `ST_UnaryUnion`, qui peut renormaliser une
représentation sans changer la géométrie : l'empreinte diffère, les polygones
non. ~51 km² perdus pour cette raison.

**La leçon nuance celle de `14`**, et c'est la plus utile de la journée :
l'empreinte binaire est la bonne clé pour *constater qu'un polygone est partagé*,
elle ne l'est pas pour *tester que deux polygones sont le même*. Identité de
représentation et identité géométrique sont deux choses différentes, et j'ai
appliqué la première où il fallait la seconde.

### Les deux défauts corrigés, et le prix du correctif

Second passage, après correction. Le test de couverture passe à l'inclusion d'un
point intérieur, l'appariement des mères à `ST_Equals` avec repli sur le code.

| | 1er passage | 2e passage |
|---|---|---|
| filles candidates | 78 | **60** |
| atomes posés | 55 | **58** |
| non couvert 1870 | 293 km² | **238 km²** |
| non couvert 1940 | 88 km² | **32 km²** |
| tracés identiques 1870 | 94,45 % | **94,49 %** |
| tracés identiques 1940 | 95,29 % | **95,33 %** |

Les 18 arrondissements ont disparu de la liste des candidates, reconnus comme
couverts. Val-de-Reuil et Marcheprime ont trouvé leur mère. Et la nouvelle
recette — `territoires_deja_couverts`, fondée sur l'inclusion — sort à zéro,
cette fois en ayant pu échouer.

La ventilation par voie confirme la nature du défaut : **57 mères sur 58 sont
trouvées par les deux voies, une seule par le code**. `ST_Equals` n'a pas
remplacé l'empreinte, il l'a complétée exactement là où elle échouait.

**Le correctif n'est pas gratuit, et c'est le genre de chose qu'on aime taire.**
Les trois communes récupérées apportent un désaccord de plus : le taux de la
source passe de 3,70 % à **5,26 %**, les atomes mal placés de 150 à 151, l'IoU
moyen recule de 0,00003. 55 km² de couverture contre un atome. Les cas que la
première version ratait étaient précisément les plus difficiles — c'était
prévisible après coup, ça ne l'était pas avant.

Bogue d'affichage trouvé au passage : `count(*)` dans un `LATERAL` renvoie
toujours une ligne, donc `n` vaut 0 et jamais `NULL`. Tende et La Brigue, qui
n'ont aucune mère, étaient rangées dans la branche « plusieurs mères ». Sans
conséquence sur ce qui est posé, mais un rapport qui ment est un rapport à
corriger.

### Ce qui reste change de nature

39 communes et 238 km² en 1870, mais **37 d'entre elles sont « non
documentées »** — créées avant 1943, hors de portée du fichier INSEE. Chisa en
Haute-Corse, Philippsbourg, une vingtaine de mosellanes et meurthe-et-mosellanes
nées sous administration allemande. S'y ajoutent Kuntzig et Stuckange (8,6 km²),
documentées mais dont la ligne INSEE n'a pas de `com_av` exploitable.

Le fichier INSEE a donné tout ce qu'il avait ; la suite est HAC.

---

## Ouverture de 1943-2012 : explorer avant de concevoir

La question à trancher n'était pas « par quoi commencer » — la trame communale
s'impose, cantons et circonscriptions en dépendent — mais **ce que deviennent
les atomes à la charnière 1940/1943**. Un seul continuum 1870-2012, ou deux
générations juxtaposées ?

Plutôt que d'en décider sur des principes, mesure sur les deux fichiers déjà
présents : `v_mvt_commune_2025.csv` et `build/atom.csv`. Note complète dans
`note_1943_2012.md`.

Sur 1943-2011, 2 654 codes de communes disparaissent — mais **2 407 d'entre eux
préexistaient à 1943**, donc ont déjà un atome. Restait à savoir si le pont
Cassini → INSEE 1943, qu'on redoutait, devait être construit.

Il n'a pas à l'être. `atom.insee_geofla` est un vrai code INSEE : 1 501 des
2 407 s'y retrouvent tels quels. Les 906 absents sont concentrés en 78 (422),
20 (365) et 75 (80) — la Seine-et-Oise, la Corse, la Seine : les trois grands
**recodages** de 1968 et 1976. En suivant la fermeture transitive que `06`
implémente déjà, **903 des 906 aboutissent à un atome existant**. Les trois
exceptions sont en Guyane.

**2 404 sur 2 407, soit 99,9 %.** Le continuum est retenu, et il est presque
gratuit.

Ce que l'exploration signale pour la suite : les 247 communes créées après 1943
puis disparues avant 2011 (aucun atome, même mécanique que `15` mais avec une
fin de vie) ; les 900 recodages de modalité 41, à traiter comme correspondance
datée et **jamais** comme disparition suivie de création, ce qui doublerait le
territoire ; et un trou de deux ans et deux mois entre le 31 décembre 1940 et le
19 février 1943, qu'aucune source ne couvre et qu'il faudra déclarer tel quel.

---

## `20` : la chronologie communale, et une recette qui contredit

Premier fichier de la période moderne. Il ne touche ni `atom` ni `membership` :
il reconstitue la chronologie à partir des seuls mouvements INSEE, puis se
soumet à une contradiction possible — l'ensemble des communes vivantes au
1ᵉʳ janvier 2011 doit être exactement celui de GEOFLA.

Trois pièges évités par la lecture du fichier plutôt que par supposition. Les
lignes où `com_av = com_ap` sont des **témoins**, 609 des 1 316 fusions simples :
les traiter comme des mouvements ferait mourir puis renaître la survivante. Les
arrondissements municipaux portent `typecom = 'ARM'` — filtrer sur `COM` aurait
d'ailleurs suffi à écarter Marseille dans `15`, par un second chemin. Et les
recodages tuent un code pour en faire naître un autre, mais les deux doivent
pointer vers le même atome.

**Le premier passage a échoué, et c'était l'intérêt de la manœuvre.** 246
communes de GEOFLA manquaient, sans même un intervalle mort. Pour 248
rétablissements dans le fichier — le rapprochement s'imposait.

L'erreur : je posais une naissance en 1943 pour tout code « sans acte de
naissance ». Une commune qui existait en 1943, a fusionné en 1965 et a été
rétablie en 1975 **a** un acte de naissance, celui de 1975 ; elle était donc
exclue et perdait sa première vie. Le bon critère est que **le premier événement
du code soit un décès** — on ne meurt que si l'on était vivant.

Un signal aurait dû alerter avant la recette : `vies_multiples` valait 0, ce qui
est arithmétiquement impossible avec 248 rétablissements. Je l'ai ajouté au
rapport avec sa valeur attendue, pour que la prochaine fois l'anomalie se voie
sans qu'on ait à la chercher.

Après correction : `chez_geofla_seulement` = **0**, 251 vies multiples, 38 068
communes au 19 février 1943, 36 630 en 2011 — soit exactement GEOFLA une fois
retirés Lyon et les 19 communes d'outre-mer. La simulation retombe sur la trame
au code près.

Une fragilité déclarée au passage, trouvée en croisant la voie de raccord avec
l'ancienneté du code : pour un code né après 1943 puis disparu, l'atome trouvé
par succession est celui de la commune absorbante, donc trop grand. Même limite
de trame qu'au § 6.1, même remède. À chiffrer, pas à corriger.

Et une question de conception qui reviendra : **les arrondissements de Marseille
et de Lyon**. Le dispositif
`union_prefixe` tient pour 1870-1940 ; il ne tient plus quand les arrondissements
deviennent des entités administratives réelles, en 1946 et 1963, que les
circonscriptions législatives urbaines suivent. Trois options dans
`note_1943_2012.md` § 5 ter. À trancher avant d'écrire dans le modèle.

---

## `21` : les atomes modernes, ou le même bogue sous quatre déguisements

Premier fichier de la période moderne qui écrit dans le modèle. Il pose les
atomes manquants et la correspondance code → atome ; aucun `membership`, faute
d'unité moderne à quoi rattacher quoi que ce soit.

**La question des arrondissements, tranchée.** L'éclatement rétroactif que je
proposais dans la note était infaisable : TRF-GIS ne dit jamais quel
arrondissement relève de quel canton en 1870, et faire appartenir l'atome du
3ᵉ arrondissement aux dix cantons lyonnais viole `membership_non_chevauchant`.
La contrainte qui fait la fiabilité de la base est celle qui refuse cette
écriture, et c'est heureux — l'alternative était d'attribuer au jugé.

Retenu : les atomes-fractions restent l'attribution de 1870-1940, les
arrondissements deviennent des atomes de plein droit à partir de 1943, et les
`membership` des deux familles ne se croisent jamais dans le temps. Leurs
géométries se recouvrent, mais `snapshot_geom()` à une date donnée n'en voit
qu'une. Une recette le vérifie.

### Quatre passages, quatre fois le même bogue

C'est la partie instructive de la journée, et elle est peu flatteuse.

**Premier passage.** `am_manquant` ne testait que la voie directe et ignorait la
succession : **906 atomes créés pour rien**, la correspondance pointant vers des
atomes fantômes sans géométrie, et la voie `succession` rendue inatteignable.

**Deuxième.** Le garde-fou interrogeait des codes. Pont-de-Buis-lès-Quimerch est
une DESTINATION de fusion, pas une origine : aucun code ne la désigne, mais deux
atomes `successeur` portaient déjà exactement son polygone. Test par code là où
il fallait un test géométrique. Au passage, Chisa et Butry-sur-Oise recevaient
chacune deux atomes — un par code, alors qu'un recodage est un territoire.

**Troisième.** Une recette nouvelle — deux codes vivants à la même date ne
doivent jamais pointer sur le même atome — en a trouvé 13. J'ai traité le
conflit d'un code avec SON successeur : 4 sur 13. Deux communes absorbées par
une même troisième tombent pourtant sur le même atome sans qu'aucune ne soit
successeur de l'autre.

**Quatrième.** En comparant les rattachements résolus deux à deux, il en restait
1 — la voie `polygone`, ajoutée au deuxième passage, empruntait elle aussi un
atome. Pont-de-Buis et la commune 29138, vivante jusqu'en 1965, se le
partageaient pendant seize ans.

**La formulation qui tient**, et qui aurait évité les quatre : une voie qui
POSSÈDE un atome par son propre code n'a jamais de conflit ; une voie qui
l'EMPRUNTE en a toujours potentiellement un. Deux catégories, un seul test, plus
de cas particulier à oublier. J'énumérais des motifs là où il fallait mesurer
une propriété — et un motif oublié ne se signale pas.

Incident annexe, instructif aussi : un `NULL` non casté dans un `SELECT DISTINCT`
a fait échouer le script après la création de 25 atomes et avant leur traçage.
Committés, orphelins, invisibles au retrait. Corrigé en posant l'atome et sa
trace dans la MÊME instruction via `RETURNING` — l'idiome de `11_scission.sql` —
et en lançant avec `psql -1`.

### État à l'arrivée

44 atomes posés : 25 arrondissements (283,08 km²), 15 territoires partagés
(292,51), 4 territoires neufs (303,61) — Tende, La Brigue, Chisa, Butry.

Toutes les recettes à zéro : aucun code simultané sur un atome, aucun conflit de
territoire, aucun atome sans géométrie, relais 1941/1943 propre des deux côtés,
et les effectifs de 1870-1940 rigoureusement inchangés.

Les 36 610 communes de la trame sont désormais portées **et** nommées par un
atome. La correspondance `commune_moderne` couvre 39 291 intervalles : 38 125
codes par voie directe, 890 par succession, 2 par recodage, et 23 sans atome —
l'outre-mer, hors périmètre par cohérence avec une trame métropolitaine.

---

## Les cantons : le trou est dans la source, et une brèche s'ouvre

Journée en deux temps. D'abord établir ce qui existe, ensuite charger ce qui
existe.

### Ce que le COG dit, et ce qu'il ne dit pas

Le fichier historique du COG 1999 compte 7 491 événements depuis 1943. Il
possède bien une modalité 43, « changement de canton », et un champ `CTANC`.
Elle est utilisée **66 fois, toutes entre le 16 avril 1995 et le 13 novembre
1998**. La documentation Insee l'annonce — les modifications d'appartenance à un
échelon supracommunal ne sont répertoriées que depuis 1994 — et les données le
confirment à la ligne près.

**Le trou 1943-1995 est donc dans la source, pas dans notre recherche.** C'est un
résultat, pas un échec : la question à poser à un archiviste cesse d'être « avez-
vous des données cantonales ? » pour devenir « le COG ne conserve rien avant
1995, quelle source le fait ? ».

La seconde prise espérée n'existe pas non plus : `france1999` liste bien toutes
les communes depuis 1943, mais les 2 471 disparues ont un champ `CT` vide.

Et un point de licence qui tranche une hésitation ancienne : **Cassini-Geopeuple
est en CC BY-NC-SA**. La clause non commerciale interdit la republication sur
Wikipédia. Cette piste sert à vérifier, jamais à publier.

### La brèche

Deux fichiers minuscules du dépôt de reproduction TRF-GIS ont changé la donne.

`cog_to_geofla_ct_2011.do` éclate Marseille, Lyon et Paris en arrondissements
avec des identifiants Cassini synthétiques — **exactement la conception retenue
par `21`**, arrivée indépendamment et confirmée par l'auteur de la source.

`ct_codes.do` s'intitule **« ADJUST CANTONS CODES TO MATCH 1954 COG »** et aligne
les codes de Gay sur le COG de 1954, au prix de 120 permutations. Deux
conséquences. La continuité de la nomenclature cantonale devient **documentée**
plutôt qu'inférée — les codes de 1870-1940 sont ceux de 1954, la filiation
1954 → 1999 est celle de l'Insee, et les 92,4 % de noms concordants ne sont plus
qu'une confirmation. Et surtout : **Victor Gay a eu en main une nomenclature
cantonale de 1954**. Le trou a un point d'ancrage en son milieu, et quelqu'un l'a
déjà exploité. Lui écrire est désormais la démarche la plus directe.

### Le chargement

14 millésimes, structure identique, vérifiée. En métropole : 36 565 communes,
3 876 cantons, 1 049 fractions en 1999. Le diff des millésimes trouve 23
communes changeant de canton — 17 en 2002, 5 en 2005, 1 en 2009 — et 10 cantons
créés pour 3 supprimés. Quatorze instantanés annuels valent mieux qu'un
historique qui ne consigne rien.

Paris s'est résolu par la donnée : `cheflieu` vaut 75101 pour le canton 15,
jusqu'à 75120 pour le 34. Paris n'a pas de cantons au sens électoral, ses
arrondissements en tiennent lieu. Marseille et Lyon résistent — `typct = 4`,
`cheflieu` renvoyant la commune entière, 22 cantons pour 16 arrondissements et
13 pour 9 — et sont reportés jusqu'à disposer d'une couche cantonale
géométrique.

`24_canton_moderne.sql` pose 3 844 cantons, 925 unités nouvelles, 2 919
réutilisées, 998 atomes-fractions et 37 319 rattachements. Zéro chevauchement,
zéro rattachement entre 1941 et 1998, effectifs de 1870-1940 inchangés.

**Deux choses à retenir.** À `1970-06-01`, `count_units` ne renvoie aucune
ligne : l'absence de la ligne EST le résultat. Et 266 des 998 fractions
existaient déjà avant 1941, entre les mêmes cantons — un quart des communes
coupées par une limite cantonale l'étaient par la même, un demi-siècle plus tard.
Confirmation non recherchée, et d'autant plus solide.

### Marseille et Lyon : la géométrie tranche par la négative

Restaient deux villes. J'ai cherché la couche cantonale de GEOFLA en espérant
qu'elle donnerait le rattachement canton → arrondissement. Elle a donné mieux :
la preuve qu'il n'existe pas.

**GEOFLA ne compte qu'un canton pour Marseille et un pour Lyon**, codés
`CODE_CANT = '99'`, chef-lieu 13201 et 69381. Et le même dispositif partout où
une commune est partagée : Villeurbanne 98, Vénissieux 97, Aix 97, Arles 98,
Istres 95, Martigues 96. 3 708 cantons chez l'IGN contre 3 876 au COG — les 168
d'écart sont cette fusion.

La raison est la nôtre, mot pour mot : GEOFLA est bâti sur la trame communale,
et une trame communale ne sait pas couper une commune. L'IGN bute au même
endroit que Gay en 1870 et que nous en 2012. **Le pseudo-canton n'est pas un
pis-aller, c'est la convention du domaine.**

`25_pseudo_canton.sql` pose donc deux unités et 25 rattachements. Le lien n'a
pas été codé en dur : chaque arrondissement a été affecté au canton GEOFLA
contenant son point intérieur, et les 16 marseillais tombent bien dans `1399`,
les 9 lyonnais dans `6999`. Recettes à zéro, effectifs finaux 3 843 cantons en
1999 et 3 846 en 2012.

Détail que le script a sorti et que je n'attendais pas : **le nombre de cantons
de ces villes a bougé** — Marseille de 22 à 25 en 2005, Lyon de 13 à 14 en
2002 — sans que le pseudo-canton change, la ville restant la ville. La
simplification masque une évolution réelle sans fausser le territoire, et ça
mérite d'être écrit plutôt que découvert par un lecteur.

Deux détours pour rien avant d'y arriver, et ils valent d'être notés. La page de
téléchargement de l'IGN est rendue en JavaScript : `web_fetch` n'en ramène
qu'une coquille. Et « arrondissement » chez l'IGN désigne l'échelon du
sous-préfet, pas l'arrondissement municipal — les premiers fichiers récupérés
étaient donc doublement hors sujet, et pour les DOM par-dessus le marché.

### Le contrôle indépendant de la période moderne — et la même erreur, six mois plus tard

Dernière pièce : noter 1999-2012 contre la couche CANTON de GEOFLA, comme
1870-1940 est noté contre les cantons dissous de Gay.

**Le premier jet a reproduit l'erreur du premier passage de `08`.** Elle est
pourtant écrite au § 7 de `METHODE.md`, en toutes lettres : « ne replier que
notre côté revient à comparer deux cantons à un centre-ville ». GEOFLA fusionne
les cantons d'une commune partagée en une entité codée 9x qui **ne porte que la
commune indivise** — exactement les polygones `pct_type = 'Pseudo canton'` de
Gay. Symptômes identiques à l'époque : 216 entités orphelines, 17 613 km²
d'excédent, IoU 0,917.

Et une faute que je n'avais pas commise la première fois : le repliement était
déduit de l'affectation géométrique des atomes, c'est-à-dire de la réponse que
le contrôle est censé tester. Circulaire.

Corrigé en le déduisant de **notre** nomenclature — deux cantons fusionnent
s'ils partagent une commune, composantes connexes — et en rattachant les
entités 9x par la commune qu'elles portent. Les orphelines tombent à zéro,
l'excédent de 17 613 km² à **26**.

**Le résultat.**

| | |
|---|---|
| pseudo-cantons | 3 162, appariement parfait |
| surfaces | 548 463 contre 548 488 km², écart 0,005 % |
| IoU moyen | 0,9646 |
| **atomes rangés ailleurs** | **11 sur 37 297, soit 0,03 %** |

Zéro désaccord sur les fractions, les arrondissements, les successeurs et les
créations arrière ; 10 sur 35 161 pour `geofla` non partagé. Les attributions
de la période moderne sont justes.

L'IoU de 0,965 vient d'ailleurs, et la conception l'avait anticipé : nos
communes sont de l'édition 2011, ces cantons de 2014. Les pires cas sont des
cantons urbains de moins de 3 km² en petite couronne, où quelques mètres de
reprise de limites pèsent lourd en proportion. Les deux mesures se séparent
proprement — c'était tout l'objet de la manœuvre.

**Ce que j'en retiens.** Connaître une erreur ne suffit pas à l'éviter : je
l'avais documentée, je l'ai refaite. Ce qui l'a rattrapée n'est pas la mémoire
mais la recette — des entités orphelines et un excédent de surface absurde, que
le rapport affichait en clair. Un contrôle bien construit protège aussi de
l'oubli de ses propres leçons.

### Les circonscriptions de 2012, et le prix de Paris

Source trouvée d'emblée : le tableau de correspondance du ministère de
l'Intérieur, en Licence Ouverte, qui donne commune, canton, circonscription de
1986 **et** de 2012 sur la même ligne. La maille est celle de nos atomes, et ses
3 883 cantons sont exactement ceux que `24` a posés.

Note de lecture écrite avant tout chargement — `note_circonscriptions.md` — et
elle a servi. Cinq pièges, dont deux m'avaient déjà eu :

**Les codes n'ont pas de zéros de tête.** Concaténer naïvement confond l'Ain 355
et Marseille 13055 : j'ai d'abord compté 2 818 communes multicantonales là où il
y en a 354.

**Paris 1986 est codé « 42 »** pour toutes ses lignes, alors que Paris comptait
21 circonscriptions. J'aurais pu y voir une convention obscure ; la vérification
par le total tranche — la somme des maxima donne 576 sièges métropolitains au
lieu de 555, et 576 − 42 + 21 = 555 exactement. L'anomalie est entièrement
localisée à Paris, le reste du fichier est juste. Pour 2012, le même calcul
donne 539 sans correction.

Le chargement pose 539 unités et 37 253 rattachements. Quatre communes ne se
raccordent pas — Bleury, Bihorel, Fort-Mardyck, Saint-Pol-sur-Mer, fusions de
2010-2012 que notre chronologie place ailleurs. Effet de millésime, attendu.

**Mais 524 circonscriptions seulement ont un territoire.** Le découpage de 2009
coupe à l'intérieur des arrondissements : treize des vingt arrondissements
parisiens relèvent de deux ou trois circonscriptions, et notre unité la plus
fine à Paris est l'arrondissement.

Le pseudo-découpage — le remède qui avait résolu les cantons de Marseille et
Lyon — a été mesuré avant d'être proposé. Il relierait **17 des 18
circonscriptions parisiennes en une seule composante**. Paris deviendrait un
bloc unique : pire que quinze unités vides. Écarté sur pièces.

L'état est conservé tel quel, et c'est un choix de cohérence. La base est
interrogeable, pas imprimée, et sa convention ne varie pas depuis le trou
cantonal : **l'absence signifie « on ne sait pas », la présence « on sait »**.
Les quatre circonscriptions parisiennes pourvues le sont d'arrondissements
réellement non partagés ; les effacer pour uniformiser jetterait une
information vraie.

### La leçon de `21`, transformée en garde

`24` s'ouvre sur un **contrôle préalable** : trois assertions qui lèvent une
exception et annulent la transaction. Aucun rattachement sans atome, aucun atome
portant deux cantons la même année, aucun identifiant pris par un autre niveau.
Plutôt que de découvrir le défaut au quatrième passage, le script refuse
d'écrire. Il n'a fallu qu'un seul correctif ensuite — et il était instructif :
`10142#1614` existait déjà. Conséquence logique de l'espace de noms unique, une
fraction se nommant « la part de X dans le canton Y » : si le canton garde son
code, la fraction garde le sien. Ce n'était pas une collision, c'était le même
atome.

---

## Les leçons, transposables au reste du projet

**Les recettes internes valident la cohérence, pas l'exactitude.** Trois défauts
réels ont été trouvés — trous de couverture, préfixe amputé, codes réutilisés —
et aucun ne faisait échouer un contrôle. Toutes les recettes passaient.

**Un correctif doit être notable.** Chaque intervention a été mesurée contre une
source qui ne dépend pas de nous, avant/après. C'est ce qui a permis de garder
le correctif de scission en connaissance de cause, et d'affiner le garde-fou 4
en sachant exactement ce qu'il coûtait.

**Ne pas ajuster sur l'étalon.** Le garde-fou 4 se justifie par un fait relatif
aux données — la réutilisation des codes en 1871. Corriger les quatre paris
perdus en recopiant Gay aurait été différent : cela aurait fait de l'étalon un
paramètre, et le contrôle n'aurait plus rien validé du tout.

**Mesurer avant de corriger.** Deux pistes de travail se sont refermées sans
qu'une seule ligne d'attribution soit touchée : les 138 atomes `successeur`, et
l'écart entre 12 822 et 3 945 km². Dans les deux cas un fichier de diagnostic a
coûté moins cher que le travail manuel qu'il a évité.

**Un commentaire d'intention n'est pas une mesure.** `12` affirmait que ses
12 822 km² devaient « ressembler » aux 3 945 de `08`. C'était écrit de bonne foi,
en raisonnant, et c'était faux — les deux ne comptent pas au même niveau. Un
chiffre annoncé comme comparable doit être comparé, pas supposé.

**Une erreur silencieuse coûte plus qu'une erreur bruyante.** Le préfixe `1320`
produisait une géométrie valide, simplement fausse. D'où le réflexe pris :
afficher au chargement ce qui est capté, avec l'attendu à côté.

---

## 16 août 2026 — l'outre-mer : le fichier qu'on avait déjà

Ouverture du dossier outre-mer, jusque-là écarté par cohérence avec une trame
métropolitaine. Repérage complet dans `docs/note_outre_mer.md`.

**Le résultat le moins attendu ne vient pas du réseau mais du disque.**
`circo/correspondance_2012.xls` contient l'outre-mer depuis le début.
`note_circonscriptions.md` §2.2 l'avait vu, noté, et filtré — « sans effet ici,
l'outre-mer étant hors périmètre ». Le périmètre a changé, le fichier n'a pas
bougé : 171 lignes, 4 départements, les circonscriptions de 1986 et de 2012.
Extraites dans `circo/circo_outremer_1986_2012.csv`.

Trois recoupements valident la lecture sans rien lui emprunter. La Guadeloupe
donne 40 cantons pour 43 codes, et les trois manquants — `ZA23`, `ZA25`, `ZA29` —
sont Saint-Barthélemy et Saint-Martin, partis en 2007. La Réunion passe de 5 à 7
circonscriptions, ce qu'a fait le redécoupage de 2010. Les 32 communes de
Guadeloupe confirment la partition. Le fichier se date lui-même.

**Une règle vérifiée en métropole devient fausse outre-mer.**
`insee = dep.zfill(2) || com.zfill(3)` donne `ZA101` là où il faut `97101` : le
`Code commune` d'outre-mer porte déjà le chiffre du département, et la règle y
est `'97' || com`. Vérifié sur cinq communes connues. Cette erreur-là aurait été
silencieuse — des codes bien formés, simplement inexistants. Encore le préfixe
Marseille, sous un quatrième déguisement.

**GEOFLA couvre les DROM, mais pas au millésime 2011.** Le catalogue donne 1999,
puis 2015 et 2016 — rien entre les deux. Le bon lot est l'édition du 4 mars
2015, celle-là même qui sert déjà en métropole : version 2-0, cantons d'avant la
réforme, `COMMUNE` + `CANTON` + `ARRONDISSEMENT` + `DEPARTEMENT` dans le même
paquet. Cinq lots, cinq projections différentes, aucune n'étant le Lambert-93.
URL et md5 relevés au flux ATOM, script dans `sources/outremer/`.

Le millésime 1999 des communes offre un contrôle gratuit de stabilité de la
trame — l'hypothèse implicite dès qu'on projette une géométrie récente sur le
XIXᵉ siècle. À mesurer avant de charger, pas après.

**Deux murs de licence, et c'est le même qu'à Paris.** La Polynésie de l'ISPF
est en ODbL, comme ALPAGE-Vasserot. L'Algérie n'a d'autre source ouverte qu'OSM,
ODbL également, et GADM interdit la redistribution. Le seul chemin propre reste
celui de Marseille : géoréférencer du domaine public. À l'échelle de l'Algérie
ce n'est pas une tâche, c'est un projet ; et la couche départementale, 15 objets,
coûte infiniment moins que la couche communale.

**Ce qui n'a pas pu être fait ici :** télécharger. `data.geopf.fr` n'est pas
joignable depuis l'environnement de travail, seules les URL ont pu être
vérifiées. Le script est prêt à tourner sur la machine locale.

## 16 août 2026, suite — les archives ouvertes démentent le catalogue

Neuf archives téléchargées. **Les cinq md5 relevés au flux ATOM concordent
exactement** : les fichiers sont ceux annoncés, et le contrôle a servi. Puis
l'ouverture a démenti deux choses écrites la veille d'après le seul catalogue.

**Un lot sans nom de thème n'est pas un lot complet.**
`GeoFLA_2-0__SHP_<CRS>_D97x_2015-03-04` pèse 640 Ko et ne contient que `CANTON`.
J'avais lu « tous thèmes » dans l'absence de thème au nom, et l'avais écrit.
Le plus gênant est que la preuve du contraire était déjà sur le disque :
`sources/geofla/canton2014/` ne contient, lui non plus, qu'un répertoire
`CANTON`. Les communes sont dans cinq lots séparés à la même date, ajoutés au
script — la trame d'atomes reste donc à télécharger.

**GEOFLA ne découpe pas les communes multicantonales, outre-mer non plus.**
Une commune partagée entre plusieurs cantons y devient une entité unique, codée
`90` à `99`, portant le nom de la commune. Résultat : 69 polygones cantonaux
propres pour 153 cantons réels dans les quatre DOM, soit **45 %**. La Réunion
tombe à 29 % — 35 de ses 49 cantons sont noyés dans dix agrégats. C'est plus
mauvais que tout ce qu'on a vu en métropole.

Ce qui donne confiance dans la lecture : **les 27 agrégats correspondent un pour
un, et nom pour nom, aux 27 communes multicantonales du fichier du ministère**.
Fort-de-France, Le Lamentin, Les Abymes, Saint-Denis, Le Tampon, Cayenne,
Mamoudzou. Deux sources qui ne se connaissent pas, zéro exception. Le manque est
dans la source, pas dans la lecture — et la suite est déjà écrite : c'est le
problème des 119 villes, résolu le 14 août par CONTOURS-IRIS, à refaire pour 28
communes d'outre-mer.

**Le contrôle de stabilité communale est excellent, et il coûtait trois lignes.**
1999 contre 2012 : 90 communes identiques sur 92, les deux écarts étant `97123`
Saint-Barthélemy et `97127` Saint-Martin, détachés en 2007. L'hypothèse implicite
de tout le projet — une trame récente vaut pour le passé — se vérifie ici au lieu
de se supposer. Et le même événement était déjà lisible dans les codes cantonaux
`ZA23`, `ZA25`, `ZA29` manquants : trois chemins indépendants, un seul fait.

**Deux confirmations gratuites.** `CODE_CHF` de GEOFLA porte le code commune sur
trois chiffres — `608` Dzaoudzi, `353` Maripasoula — et `'97' || CODE_CHF` donne
le bon code INSEE : la règle tirée du fichier du ministère se retrouve dans une
source sans rapport. Et le lot SPM d'ADMIN EXPRESS donne
`code_insee_du_canton = 'NR'` pour ses deux communes : l'absence de canton y est
écrite, pas déduite.

**Un piège pour la suite :** `CODE_DEPT` vaut `97` pour les cinq départements.
L'attribut ne distingue pas la Guadeloupe de Mayotte, le département ne peut
venir que du lot. Une jointure sur `CODE_DEPT` fusionnerait les cinq territoires
sans rien signaler — encore une erreur qui produirait une géométrie valide.
