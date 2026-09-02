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

## 16 août 2026, fin de journée — CONTOURS-IRIS outre-mer : 61 coupes sur 61

Le trou ouvert le matin — 45 % des cantons d'outre-mer sans polygone propre — se
referme par le même chemin qu'en métropole, et un peu mieux.

Le WFS de la Géoplateforme, interrogé sur `STATISTICALUNITS.IRIS:contours_iris`,
donne **864 IRIS outre-mer**, dont **472 sur les 28 communes multicantonales**.
La condition nécessaire `IRIS ≥ coupes + 1` tient pour **28 communes sur 28,
61 coupes sur 61**. En métropole, trois villes restaient sans appui — ici,
aucune. Densité 7,7 IRIS par coupe.

Les deux cas les plus lourds sont les mieux servis : Saint-Denis 64 IRIS pour
8 coupes, Fort-de-France 38 pour 9. Ces deux comptes-là ont été redemandés au
service en `RESULTTYPE=hits` plutôt que déduits d'un dénombrement à la main :
64 et 38, les deux fois. Détail dans `cartes/iris_outremer.csv`.

**Le piège de Marseille n'a pas de jumeau ici.** En métropole, Marseille, Lyon
et Paris rendaient zéro IRIS interrogées par leur code de commune, parce que
l'INSEE y code par arrondissement municipal — un zéro plausible et donc muet.
Aucune commune d'outre-mer n'est dans ce cas : les 28 rendent des IRIS sous leur
propre code. Ce qui valait la peine d'être vérifié plutôt que supposé, puisque
le même zéro silencieux aurait été indiscernable d'une petite commune.

Ce que la trame ne prouve toujours pas : que les limites cantonales suivent des
limites d'IRIS. Comme en métropole, c'est un support de tracé et le taux de
reprise se mesurera dans QGIS.

**Il reste deux téléchargements** avant de pouvoir charger : les cinq lots
`COMMUNE` de GEOFLA, et la trame IRIS des 28 communes.

## 16 août 2026, dernière manche — la trame communale, et un défaut qui n'existe pas

Les cinq lots `COMMUNE` téléchargés, md5 concordants, recette écrite dans
`sources/outremer/recette_outremer.py` — qui se relance et qui a servi tout de
suite, puisqu'elle a d'abord planté sur une lecture de chemin trop maligne.

**129 communes, zéro géométrie invalide, zéro recouvrement.** Le contraste avec
la métropole est ce qu'il y a de plus notable : là-bas, la somme des cantons
dépasse leur union de 3 945 km² en 1870, parce que des communes historiques
fusionnées partagent un code INSEE et que les communes éclatées entre cantons
n'ont pas de géométrie propre. Outre-mer, somme et union sont égales **au
centième de km² près** dans les cinq départements. La limite principale du
projet, celle qu'on traîne depuis le début et qu'on annonce en note de méthode,
ne s'applique tout simplement pas ici.

Les surfaces tombent à 0,0-1,0 % de l'attribut `SUPERFICIE` du même jeu. C'est
un contrôle interne, mais c'est celui qui attrape une reprojection ratée, et
avec cinq CRS distincts il valait la peine d'être fait.

**L'attribution commune → canton était déjà dans le fichier.** `INSEE_COM` est
écrit en clair — rien à reconstituer — et les codes sont identiques à ceux du
ministère dans les quatre DOM, 112 sur 112. Mieux : la couche `COMMUNE` porte un
`CODE_CANT`, et pour les communes d'un seul canton il concorde **85 fois sur
85**. Deux sources indépendantes, zéro écart, pour la deuxième fois de la
journée.

Les 27 multicantonales portent le pseudo-code `90`-`99`, vérifié pour les 28
Mayotte comprise. Ce n'est pas une lacune silencieuse mais un aveu explicite —
et c'est la différence entre une source qui manque et une source qui ment. Le
niveau cantonal est donc acquis pour 85 des 112 communes des quatre DOM sans
aucun travail ; le reste est le chantier IRIS, dont on sait depuis ce matin
qu'il a de quoi tenir.

Il ne reste qu'un téléchargement avant de charger : la trame IRIS des 28.

## 16 août 2026 — le SRID tranché, et un garde-fou avant d'en avoir besoin

**Le Lambert-93 ne peut pas accueillir l'outre-mer.** Mesuré plutôt que
supposé : reprojeter les communes en 2154 gonfle les surfaces d'un facteur 1,28
en Guadeloupe, 1,31 en Martinique, 1,63 en Guyane, 2,61 à Mayotte et **3,54 à
La Réunion**, qui y passerait de 2 502 à 8 856 km². Ce ne sont pas des arrondis,
et tous les contrôles du projet sont surfaciques.

Décision : **l'outre-mer vit en 4326, la base métropolitaine ne bouge pas.** Les
surfaces s'y calculent en `geography`, exactes sur l'ellipsoïde et indépendantes
de toute projection ; `snapshot_geom()` reprojettera à la volée pour rendre une
couche unique. Rien à recharger, et le 2154 garde sa commodité métrique là où
il est défini.

**`cartes/recupere_iris_outremer.py`** est écrit, sur le modèle du script
métropolitain, avec trois différences assumées : sortie en 4326 ; liste des
28 communes lue dans `cartes/iris_outremer.csv` plutôt que déduite des atomes,
qui n'existent pas encore ; et pas de table d'arrondissements municipaux,
puisque aucune commune d'outre-mer n'est codée ainsi — vérifié, pas supposé.

**Le garde-fou vaut d'être noté parce qu'il devance le bogue.** En WFS 2.0,
`EPSG:4326` peut être servi en lat/lon au lieu de lon/lat selon
l'implémentation. Inverser les axes place la Guadeloupe (−61,5 ; 16,2) au large
de la Somalie (16,2 ; −61,5) : une géométrie valide, un décompte d'entités
juste, et une carte fausse. C'est le préfixe Marseille à l'échelle du globe.
Le script vérifie donc chaque entité contre l'emprise de son territoire et
refuse d'écrire si ça sort. Testé dans les deux sens sur des entités fabriquées.
Le service n'a pas encore été interrogé pour de vrai : si les axes sont bons, le
contrôle ne coûte rien ; s'ils ne le sont pas, il économise une journée.

## 16 août 2026 — la trame IRIS reçue, et le SQL écrit sans pouvoir l'essayer

`recupere_iris_outremer.py` lancé pour de vrai : **472 IRIS pour 28 communes,
exactement le nombre annoncé par le repérage**, 28 communes en trame
confortable, **61 coupes sur 61 pourvues**. Le garde-fou d'emprise passe : les
axes sont bien en lon/lat, le contrôle n'aura servi à rien — ce qui est le sort
normal d'un bon garde-fou, et ne dit pas qu'il était inutile.

**`sql/40_outremer.sql` est écrit, et n'a jamais tourné.** Il n'y avait pas de
PostgreSQL dans l'environnement de rédaction, et pas les droits pour en
installer. C'est écrit en tête du fichier plutôt que passé sous silence : les
chiffres attendus de ses recettes viennent de mesures réelles sur les
shapefiles, pas du script lui-même. Ce sont les recettes qui diront s'il les
atteint.

Deux choix de structure méritent d'être dits.

**Tables séparées, et pour deux raisons dont la seconde suffirait.** Le SRID,
d'abord : `atom_geom` est typé 2154, l'outre-mer vit en 4326. Mais aussi
`unit.dep`, qui est `char(2)` quand les départements d'outre-mer tiennent sur
trois caractères. On aurait pu leur donner les codes `ZA`-`ZD` du ministère,
qui font bien deux caractères — c'était tentant, et c'était faire entrer dans
une colonne un code que rien d'autre dans la base n'emploie. `om_unit.dep` est
donc `char(3)` et porte le code INSEE, celui qu'on lit partout ailleurs.

**Les deux contraintes `EXCLUDE USING gist` sont reprises telles quelles.**
C'est ce qui empêche de rattacher Fort-de-France à ses neuf cantons à la fois,
et donc ce qui oblige à laisser les 27 communes multicantonales sans
attribution jusqu'au découpage sur IRIS. La contrainte qui bloque est celle qui
protège : le même raisonnement qu'en 1870 pour Lyon.

Une erreur relevée à la relecture, avant qu'elle ne coûte : le script lisait
`om_canton_src` pour les cantons de Mayotte sans que rien n'ait jamais dit
comment charger cette table. L'en-tête donne maintenant la commande, et un
garde-fou refuse de démarrer sans elle plutôt que de poser 16 cantons au lieu
de 19 sans rien signaler.

## 17 août 2026 — la carte interactive, et un trou qu'on a refusé de combler

`cartes/export_web.py` et `cartes/web/index.html` : un curseur de 1815 à 2012,
un sélecteur de département, trois niveaux superposés — communes en trait fin,
cantons en trait moyen sur fond colorié, circonscriptions en trait épais.
Mode d'emploi et limites dans `cartes/web/LISEZMOI.md`.

**Le curseur va de 1815 à 2012, la base non, et la page le dit.** Elle tient
une composition cantonale en 1870-1940 et 1999-2012, électorale en 1870-1940,
1986-2010 et 2010-2012. Ailleurs — avant 1870, et dans le trou cantonal
1941-1998 — la page affiche un contour départemental grisé emprunté à l'année
datée la plus proche, **annoncé comme emprunté**, sous un bandeau qui dit qu'il
n'y a pas de source. C'était le choix à faire et il valait d'être fait
explicitement : reporter la composition de 1940 sur 1965 aurait donné une carte
pleine, plausible, et fausse. Une carte a l'autorité de ce qu'elle montre ; elle
ne dit pas qu'elle interpole. La jauge sous le curseur donne les années servies
d'un coup d'œil, ce qui rend le trou visible sans avoir à le chercher.

**Le poids a été traité par la structure, pas par la simplification.** La
géométrie d'un atome ne bouge jamais : elle sort une fois par département.
Ce qui bouge est le rattachement, et il ne bouge que quelques fois par période.
Le script repère les configurations distinctes — md5 de la composition, noms
d'époque compris — et n'écrit qu'un fichier par configuration. Réexporter la
même carte soixante-et-onze fois aurait pesé cent fois plus pour la même
information.

**L'accrochage à la grille plutôt que la simplification, et c'est le point
technique qui compte.** `ST_SimplifyPreserveTopology` appliqué polygone par
polygone écarte deux communes voisines et ouvre des lisières entre elles ; les
limites cantonales ne suivraient plus les limites communales qu'elles suivent
en réalité. `ST_SnapToGrid` à 25 m en Lambert-93, appliqué dans le même ordre
aux atomes et aux contours dissous, préserve les sommets partagés. La carte est
juste parce que les deux couches ont subi exactement le même traitement.

**Recette en deux passées, PostGIS n'étant pas installable ici.** Le SQL a
tourné contre un vrai PostgreSQL 16 doté de doublures des fonctions ST_*, sur
un jeu d'essai qui reproduit les discontinuités réelles : trou 1941-1998,
circonscriptions sans cantons en 1986-1998, un transfert de commune en cours de
période, un renommage de canton à mi-parcours. Dix-sept recettes, toutes
passées — dont le dédoublonnage (4 configurations cantonales et 3 électorales
là où il y a 97 années servies) et la restitution du nom d'époque. La page a
ensuite tourné dans un DOM sans navigateur sur deux départements fabriqués au
Voronoï, unions faites par shapely : sept scénarios rendus en images, zéro
erreur JavaScript.

Ce qu'aucune des deux ne prouve : que `ST_UnaryUnion` dissout correctement sur
les vraies géométries. C'est PostGIS qui en répond, et le premier export qui le
dira.

**Un défaut trouvé par le rendu, et qui ne se serait pas vu autrement.** En
1986-1998 la base tient les circonscriptions mais pas les cantons : colorier
par canton rendait une carte entièrement grise, indiscernable d'un bogue de
chargement alors qu'il y avait bien une information à montrer. Le coloriage
retient maintenant le niveau le plus fin disponible. C'est le genre de chose
qu'une recette sur les données ne peut pas attraper — il fallait regarder
l'image.

## 17 août 2026, second tour — cinq défauts remontés de l'usage

Premier export réel fait, cinq reproches, tous fondés. Ce qu'ils ont en commun
mérite d'être noté : **aucun n'était visible dans les données**. Les recettes
de la veille passaient toutes, et la page était inutilisable sur quatre points.

**Le texte et les hachures étaient exprimés en kilomètres.** Le `viewBox` est
gradué en unités de carte ; un `font-size: 9px` écrit dans la feuille de style
vaut donc neuf kilomètres de haut, et un motif de hachures au pas de six vaut
six kilomètres. Les traits s'en tiraient grâce à `vector-effect:
non-scaling-stroke`, qui n'a pas d'équivalent pour le texte ni pour les motifs
de remplissage. La taille est maintenant posée en unités de carte à chaque
rendu, à partir de l'échelle courante. Corollaire attrapé au passage :
`calibre()` rend la main sans rien faire quand le cadre est déjà posé, donc
sans repasser par `applique()` — les éléments fraîchement créés n'avaient
aucune taille du tout. Le redimensionnement est appelé explicitement en fin de
`dessine()`.

**Le curseur proposait des années où le département n'existe pas.** Il se borne
désormais au premier et au dernier millésime servi, déduits des données. Le 99
n'ouvre plus qu'une année.

**Et surtout, il fallait distinguer deux silences.** La base qui ne dit rien, et
le territoire qui n'est pas français. Les afficher pareil, c'était s'accuser
d'une lacune qu'on n'a pas : il n'y a pas de Moselle française en 1890, et ce
n'est pas un trou de couverture. Une table `ABSENCES` déclare les périodes
d'annexion et les motifs de bornes, en tête d'`export_web.py`, comme des
affirmations historiques datées et non comme une commodité d'affichage. Les
bornes, elles, restent déduites des données — la table ne fabrique aucun trou,
elle ne fait que motiver ceux qui existent.

**Le 99 méritait son nom.** C'est la Meurthe d'avant 1871, documentée au § 8 de
`METHODE.md` ; elle sortait sans libellé et avec un curseur de deux siècles
pour une seule année servie.

**Les noms de communes manquaient.** Joints depuis `noms_geofla`, à défaut
`geofla_commune`, avec un `ST_PointOnSurface` pour la pose. La requête est
assemblée selon les tables présentes plutôt que d'échouer sur une base
reconstruite sans ses annexes. Les étiquettes n'apparaissent qu'au zoom et les
communes trop petites restent muettes — une étiquette plus large que sa commune
masque ses voisines sans se lire elle-même.

**Le clic sur une ville multicantonale rend tous ses cantons.** Ses
atomes-fractions partagent un code INSEE ; la fiche les regroupe. C'est
précisément l'information que la carte ne peut pas porter, puisque ces cantons
s'y recouvrent exactement — la donner en clair là où le dessin échoue vaut
mieux que de la taire deux fois.

**Sur la méthode de recette.** La première passée de contrôle ne pouvait pas
attraper ces défauts : ils ne sont ni dans les données, ni dans le SQL. Il a
fallu rendre des images et les regarder. Deux limites d'outillage relevées au
passage — cairosvg n'applique pas les sélecteurs de classe et ignore `hsl()` et
les motifs, ce qui a d'abord fait passer un rendu correct pour un rendu cassé.
Le contrôle final est fait à `resvg`, qui rend patterns, `paint-order` et
`hsl()` comme un navigateur. **Un rendu de contrôle qui ment coûte plus cher
que pas de rendu du tout** : on corrige alors ce qui n'est pas cassé.

22 recettes SQL, 12 scénarios rendus, zéro erreur JavaScript.

## 17 août 2026, troisième tour — la page dépendait de son propre export

Trois reproches, et le premier enseignement porte sur les deux premiers : **la
page tenait pour acquis des champs que seul le nouvel export produit.** Sur un
export de la veille, les noms de communes n'existaient pas et le champ `bornes`
non plus — le curseur retombait sur 1815-2012 pour tous les départements, et
aucune étiquette ne pouvait s'afficher. Rien ne le disait. C'est la pire forme
de panne : la page rendait une carte plausible, et le défaut passait pour un
choix.

Deux correctifs, et le second est le vrai.

**Les bornes se recalculent depuis les clés d'`annees`**, qui existent depuis
toujours, au lieu de faire confiance à un champ ajouté hier. Le résultat est le
même quand l'export est à jour, et il est juste quand il ne l'est pas.

**Un export ancien est reconnu et annoncé.** L'absence de `n` sur les communes
suffit à le détecter ; le panneau dit alors ce qui manque et la commande à
relancer. Une page qui se dégrade doit dire qu'elle se dégrade — sans quoi
c'est l'utilisateur qui paie le diagnostic, deux fois.

**Le seuil d'affichage des noms était global, donc inutilisable.** Il exigeait
un zoom minimum avant de poser la moindre étiquette : à l'échelle du
département, *rien* n'apparaissait, y compris pour les communes qui auraient
largement tenu la leur — réglage indistinguable d'une panne, et c'est bien
comme une panne qu'il a été rapporté. Chaque commune porte maintenant son
propre seuil, et la règle est celle qu'on énoncerait à la main : une étiquette
plus large que sa commune ne se lit pas et masque ses voisines. Le seuil dépend
donc de la longueur du nom — « Ars » tient là où « Saint-Étienne-du-Grès »
déborde. Mesuré sur un département de 340 communes : 106 noms à l'échelle
départementale, 298 à mi-zoom, 340 au-delà. Les noms de communes sont désormais
la couche par défaut.

**La plage d'années sort du sélecteur de départements.** Elle allongeait chaque
ligne d'une information que le curseur donne déjà ; elle est rappelée en tête
de page une fois le département choisi.

Recette élargie : le même harnais tourne maintenant sur **deux jeux de
données**, le courant et un « export ancien » fabriqué en retirant les champs
récents. Les bornes du 99 y restent justes (1870-1870) et le diagnostic
s'affiche dans les trois départements testés. C'est ce second jeu qui manquait
la veille — on ne teste jamais assez le cas où l'on ne s'est pas encore mis à
jour soi-même.

**Rectification, le soir même.** Le garde-fou de `40_outremer.sql` s'est
déclenché au premier lancement : `om_commune_src` absente. Il avait raison, mais
la faute était en amont — la commande ogr2ogr était **en commentaire dans
l'en-tête**, et un commentaire ne s'exécute pas. Une consigne qu'il faut
recopier à la main est une consigne qu'on saute.

D'où `sql/charger_outremer.sh` : la boucle sur les cinq lots, communes et
cantons, `-t_srs` et non `-a_srs`, avec vérification des effectifs (129 communes,
113 entités cantonales) et du SRID avant de rendre la main. Détection des lots
répétée à blanc : 5 et 5.

## 17 août 2026, quatrième tour — deux recouvrements sous un seul drapeau

Trois demandes, et la deuxième valait mieux que ce qu'elle demandait.

**Le curseur est gradué par décennies.** Un tiret tous les dix ans, l'étiquette
une décennie sur une, deux ou cinq selon la largeur *mesurée* — quinze libellés
de quatre chiffres se chevauchent sur cinq cents pixels. Les bornes du
département restent toujours nommées : ce sont elles qui disent jusqu'où la base
va, et elles tombent rarement sur une décennie.

**Les noms de communes suivent le curseur.** `insee_mvt` porte 1 388
changements de nom (`mod = '10'`), datés, dont 753 dans les années 1950-60. Pour
une planche de 1885, la chronologie rend donc le nom *le plus ancien connu* —
celui d'avant le premier renommage enregistré — là où les planches PDF
affichent le nom de 2011. Ce n'est pas la vérité et la fiche le dit : le fichier
de l'Insee commence en 1943, un renommage de 1900 reste invisible.

**Et le point qui compte : `partagee` cachait deux défauts différents.** La
demande était « une couleur différente si la commune appartient à plusieurs
cantons, ou si ça résulte de noms de communes différents ». Ce sont exactement
les deux recouvrements que le projet mesure séparément depuis le contrôle Gay,
et que la carte confondait :

* **un seul code Cassini, plusieurs cantons** — la commune d'époque est
  réellement coupée et la base n'en tient pas le tracé interne. Marseille, Lyon,
  Bourg-en-Bresse. Ocre penché. **Il y a du travail à faire**, sur la trame IRIS.
* **plusieurs codes Cassini, plusieurs cantons** — des communes d'époque
  distinctes, fondues depuis, qui partagent un polygone de 2011. Espinouse,
  Saint-Jurson et Le Chaffaut sur 29,75 km². Bleu croisé. **Il n'y a rien à
  tracer** : c'est la correspondance plusieurs-vers-un vers GEOFLA, et aucun
  dessin ne la lèvera.
* **plusieurs Cassini, un seul canton** — pas de recouvrement, seulement des
  noms superposés. Liseré pointillé.

La distinction n'est pas cosmétique : l'une désigne un chantier, l'autre une
limite de la trame. Les compter ensemble, c'était s'attribuer une dette qu'on ne
peut pas rembourser.

**Le regroupement passe par l'empreinte du polygone, plus par le code INSEE.**
C'est la règle déjà posée dans `cartes_cantons.py` — « un code est une
reconstruction, l'empreinte est un fait » — et elle était nécessaire ici :
Lyon et Marseille ont des codes différents pour un même terrain
(`union_prefixe`), et trois communes fondues ont un code identique pour trois
noms. L'empreinte est un md5 du GeoJSON exporté, donc gratuite et exacte à la
grille près. Un polygone contesté est dessiné une fois et porte tous les noms
qui le revendiquent, empilés.

**Un bogue trouvé par la recette, pas par la relecture.** `chronologies()`
réutilisait le curseur avant que les communes eussent été lues : le second
`execute()` jetait le résultat en attente, et l'export mourait sur « no results
to fetch ». Écrit et relu deux fois sans le voir. La recette l'a eu au premier
essai — c'est l'argument pour l'avoir écrite.

23 recettes SQL, 12 scénarios rendus, les trois cas de partage vérifiés un à un
(type, noms, nombre de cantons, motif de remplissage), la chronologie contrôlée
au curseur. Zéro erreur JavaScript.

**Deux pannes au premier chargement réel, toutes deux de forme.**

L'encodage : les DBF de GEOFLA sont en ISO-8859-1 et ne portent pas de `.cpg`
— vérifié, l'octet `0xE9` de « Préfecture de région » est bien à l'offset 3452
et aucun fichier de code page n'accompagne le shapefile. Sans
`--config SHAPE_ENCODING ISO-8859-1`, ogr2ogr les lit comme de l'UTF-8 et refuse
d'écrire dès la première commune accentuée, Dzaoudzi. Le projet connaissait déjà
ce piège — `37_reparer_encodage.sql` en répare les dégâts après coup. Le prendre
en amont coûte une option.

Le `psql` sans base : `psql -f fichier.sql` se connecte à une base portant le nom
de l'utilisateur. Le script imprime maintenant la commande complète, `-d histgis`
et `-v ON_ERROR_STOP=1` compris, plutôt que de la laisser deviner.

Rien de tout cela ne touche aux données. Mais c'est la deuxième fois dans la
journée qu'une consigne juste, laissée sous une forme qu'on ne peut pas exécuter,
coûte un aller-retour.

**Le chargement passe, et le contrôle de position tient.** Les cinq lots
communaux et cantonaux entrent : 129 communes, 113 entités cantonales, SRID 4326
partout, et `om_canton_src` ne connaît **qu'un seul département** — c'est le
`CODE_DEPT = 97` annoncé, vu de la base cette fois.

Le garde-fou de reprojection donne la Guadeloupe à (−61,539 ; 16,198). C'était
l'endroit où une confusion `-a_srs` / `-t_srs` serait passée inaperçue ; elle ne
serait pas passée.

Troisième panne de forme, même famille que les deux précédentes : le chemin du
`\copy` était écrit `../circo/…`, relatif au dossier `sql/`. Or `\copy` résout
depuis le répertoire d'où psql est lancé, c'est-à-dire la racine. Corrigé avec
l'idiome psql qui rend une valeur par défaut quand `-v` n'a rien passé, et
doublé d'un contrôle : 171 lignes attendues, sinon on s'arrête. Un fichier
tronqué ou mal séparé aurait sinon donné des cantons manquants sans un mot.

## 17 août 2026, cinquième tour — une barre au lieu de deux

Le curseur et la jauge de disponibilité étaient deux barres empilées qui se
chevauchaient, et la borne du département doublait l'étiquette de décennie :
« 18701870 ». Les deux disaient la même chose au même endroit.

**La jauge est devenue la piste du curseur.** Le curseur est rendu transparent
et posé par-dessus. Il fallait pour cela régler un détail qui n'est pas
cosmétique : le rail d'un `input[type=range]` est en retrait de la demi-largeur
du bouton à chaque bout, si bien qu'une graduation posée en pourcentage de la
largeur totale ne tombe jamais sous le bouton. D'où une voie en retrait de la
même demi-largeur, et une échelle en `(a - a0) / (a1 - a0)` et non
`(a - a0) / n` — 1870 tombe désormais à 0 %, 2012 à 100 %, et les décennies
exactement entre les deux.

**Les bornes prennent la place avant les décennies.** Elles disent jusqu'où la
base va, donc elles sont posées d'abord ; une décennie à moins de 30 pixels
renonce à son libellé. C'est ce qui produisait le doublon. Et un département
servi sur une seule année — la Meurthe, 1870 — a ses deux bornes confondues :
un seul libellé.

Contrôlé sur trois départements aux bornes différentes : une seule barre, zéro
doublon d'étiquette, positions alignées au pourcent.

**Quatrième et dernière panne de forme, la plus instructive.** J'avais cru
qu'une variable psql non définie s'expansait en son propre nom, et bâti là-dessus
un `SELECT CASE WHEN :'circo_om' = ':circo_om'`. C'est faux : psql ne substitue
pas du tout une variable inconnue, et laisse le `:` dans le texte envoyé au
serveur, qui répond « syntax error at or near ":" ». L'idiome correct existe
depuis psql 10 et teste l'existence explicitement :

    \if :{?circo_om}
    \else
      \set circo_om 'circo/circo_outremer_1986_2012.csv'
    \endif

Relecture du fichier après coup : `\if` et `\endif` s'équilibrent, plus aucun
`SELECT` ne porte de substitution, et les six variables employées sont toutes
définies. Quatre allers-retours pour du gréement, aucun pour les données — ce
n'est pas la meilleure des proportions, mais c'est la bonne.

**Le piège documenté le matin m'a eu le soir.** `om_canton_src` empile les cinq
territoires et `CODE_DEPT` y vaut `97` pour tous — je l'avais écrit en toutes
lettres dans l'en-tête du fichier, puis j'ai filtré Mayotte sans filtrer du tout.
Le canton `01` des cinq DOM s'est présenté sous le même `unit_id` 97601, et
`om_unit_pkey` a refusé. La contrainte a fait exactement ce pour quoi elle est
là, et l'erreur s'est arrêtée à la première ligne fautive au lieu de produire
seize cantons plausibles et faux.

Le département se lit dans `CODE_CHF`, code de la commune chef-lieu sur trois
chiffres dont le premier est celui du département — encore la règle
`'97' || code`. Vérifié sur les 113 entités : **zéro discordance** entre le
département déduit de `CODE_CHF` et le lot d'origine. Le filtre rend 16 cantons
mahorais, d'Acoua à Tsingoni, ce qui est le compte attendu.

À noter au passage, sans conséquence ici : **deux entités ont un `CODE_CHF`
vide**, le canton 33 de Guadeloupe et le 22 de La Réunion. Ni l'un ni l'autre
n'est un agrégat. Ces deux-là viennent du fichier du ministère, pas de GEOFLA,
donc rien ne s'en trouve affecté — mais qui voudrait un jour déduire le
département de `CODE_CHF` pour les 971-974 devra prévoir le cas.

Un contrôle a été ajouté derrière : 16 cantons pour Mayotte, sinon on s'arrête.

**Le script va au bout, et les chiffres tombent.** 129 atomes, 169 cantons,
31 circonscriptions, 85 rattachements cantonaux et 219 rattachements de
circonscription. Communes par département : 32/34/22/24/17, et 10/6/1/10/1
multicantonales — les mêmes qu'à la lecture des shapefiles, retrouvées depuis
la base. Surfaces en `geography` : 1632, 1103, 83752, 2502, 363 km². Guyane
perd 72 km² sur la mesure planaire en UTM, soit 0,09 % : c'est l'écart normal
entre une surface projetée et une surface ellipsoïdale, pas une anomalie.

**Recouvrement : 0 km².** Vérifié cette fois dans PostGIS et non plus dans
shapely. La limite des 3 945 km² de la métropole n'a pas d'équivalent ici.

Deux choses à regarder demain. **31 circonscriptions posées pour 32 attendues**
(4+4+2+5 en 1986, 4+4+2+7 en 2012) : il en manque une, sans doute une
circonscription dont toutes les communes sont partagées, donc écartées par le
`HAVING count(DISTINCT) = 1`. La recette 5 la nommera. Et **5 communes sur 224
couples (commune, segment) relèvent de deux circonscriptions** — 342 lignes en
entrée, 219 retenues. Elles sont listées, et c'est le pendant outre-mer du
partage métropolitain.

Dernier correctif, de la même famille que les autres : la recette lisait
`iris_om` alors qu'un `NOTICE` en tête se contentait de prévenir qu'elle
pouvait manquer. Prévenir n'est pas protéger — une table absente est une
erreur, pas un compte à zéro. La requête est maintenant sous `\if` et se
rabat sur une version sans la colonne.

**`histgis.iris_om` : 472 IRIS, 2 405 km².** L'ordre de grandeur recoupe : les
28 communes concernées sont les plus peuplées, et La Réunion en concentre à elle
seule près de 1 400 km² (Saint-Paul, Saint-Benoît, Saint-Joseph, Le Tampon).
La trame de découpe est en place, en 4326 comme le reste de l'outre-mer.

Reste à relancer `40_outremer.sql` : la colonne IRIS apparaîtra dans la recette
des 28 communes en attente, et les recettes 5 nommeront la circonscription
manquante et les cinq communes partagées.

## 16 août 2026, clôture — l'outre-mer est en base, et la question ouverte a sa réponse

Toutes les recettes passent. 129 atomes, 169 cantons, 31 circonscriptions,
85 rattachements cantonaux, 219 de circonscription. Zéro chevauchement, zéro
géométrie invalide, zéro atome sans géométrie, SRID 4326 partout,
**0 km² de recouvrement**. Les effectifs par département et les surfaces
retrouvent, depuis la base, ce que shapely avait mesuré sur les shapefiles.

**La circonscription manquante est identifiée : c'est la 1re de La Réunion.**
La recette 5 donne 6 circonscriptions réunionnaises en 2009 au lieu de 7, et
`om_snapshot('2012-06-01','circo')` va de `974-02` à `974-07` sans `974-01`.
L'explication est dans le tableau d'à côté : la 1re circonscription est
**entièrement contenue dans Saint-Denis**, commune partagée entre deux
circonscriptions. Aucune commune ne lui appartient en entier, donc le
`HAVING count(DISTINCT) = 1` ne lui laisse rien, donc l'unité n'est pas créée.

Ce n'est pas un bogue mais la limite annoncée, et elle a un nom : tant que
Saint-Denis n'est pas découpée, une circonscription de La Réunion n'existe pas.
La bonne nouvelle est que Saint-Denis est la commune la mieux dotée de tout
l'outre-mer — **64 IRIS**. La trame est là, il n'y manque que le tracé.

Même mécanique, plus bénigne, pour les quatre autres partages de 2012
(Saint-André, Saint-Louis, Saint-Paul) et le seul de 1986 (Fort-de-France) :
là, les autres communes suffisent à faire exister la circonscription, seule
l'attribution de la commune partagée manque.

**Ce qui reste, dans l'ordre.** Découper les 28 communes sur trame IRIS dans
QGIS — c'est ce qui débloque à la fois les 68 cantons sans polygone propre et la
1re circonscription de La Réunion. Puis trancher la Nouvelle-Calédonie sur la
licence de BDADMIN-NC. L'Algérie, au niveau départemental, plus tard.

## 20 août 2026, soirée — trois pannes, dont une qui n'était pas dans la base

Journée de chasse aux trous vus sur la carte. Trois cas, trois causes
distinctes, et la plus coûteuse en temps n'était pas dans les données.

### Bihorel — le cache, pas la base

Bihorel disparaissait de 1987 à 1999 et revenait sans circonscription jusqu'en
2010. J'ai vérifié la base, l'export, les fichiers orphelins, l'unicité du
dossier, puis le cache — cinq étapes, en supposant à chaque fois où était la
faute. Le fichier sur disque était juste ; la page tenait une version périmée.

`servir.py` envoyait `Cache-Control: public, max-age=3600` sur **tous** les
fichiers, `index.json` compris. Or l'index est le seul dont le nom ne change
jamais : c'est lui qui dit quelle configuration porte quelle année. Le
navigateur gardait donc pendant une heure l'aiguillage d'avant le correctif.

Ce qui rendait la panne indétectable : `annee_ref` vaut 1987 dans l'ancien
fichier comme dans le nouveau. La console affichait « cfgCirco : 1987 », ce qui
avait l'air juste. Seul le contenu différait — 762 rattachements contre 763.

**Règle retenue : ne mettre en cache que ce dont le nom garantit le contenu.**
Les `c_<sig>.json` et `x_<sig>.json` sont adressés par leur contenu et se
gardent un an ; l'index et les communes passent en `no-cache`. Corrigé des deux
côtés — dans `servir.py` et dans `charge()` — pour que la carte reste juste même
servie par un autre serveur.

Le rechargement forcé n'avait rien changé, et c'est ce qui m'a égaré : Ctrl+Maj+R
ne couvre pas les `fetch()` déclenchés plus tard par le curseur.

### Villeneuve-la-Garenne — 40 reproduisait la faute qu'il reprochait à 11

Sans circonscription de 1893 à 1928, alors que sa mère — Gennevilliers, confirmé
par Wikipédia et la fiche Cassini 40353 — porte une chaîne complète.

`40_scission_circo.sql` avait deux angles morts, mesurés :

  1. Sa sélection partait de `GROUP BY atom_id` sur les rattachements circo. Un
     atome n'en ayant AUCUN n'apparaissait pas dans ce groupement, donc n'était
     jamais candidat. **270 atomes**, aux voisins pourtant unanimes.
  2. La dictée ne portait que sur les années antérieures au premier
     rattachement. Un trou de MILIEU restait invisible — **12 atomes**.

Le second est le plus instructif. L'en-tête de `40` reproche au garde-fou 1 de
`11_scission.sql` de ne prolonger que le premier rattachement, et reproduisait
exactement ce défaut. **Une critique juste ne protège pas de la faute qu'elle
nomme.**

Les candidats se définissent maintenant par un ÉTAT — toute année où l'atome a
un canton et pas de circonscription — et non par une histoire. La définition est
insensible à l'ordre de la chaîne, ce que l'ancienne n'était pas.

Posé : **7 932 années-communes, 348 atomes, 1 038 périodes** (contre 967
périodes et 308 atomes). Zéro atome dans deux circonscriptions à la fois.

`40` a été déplacé **après** `46` : il répond par procuration, `46` répond
directement en tenant de HAC le nom de la mère. Placé avant, il occupait le
terrain et le garde-fou 4 de `46` faisait taire la meilleure source.

### Les fractions — un remède plus cher que le mal

Le résiduel à 1870 est de 291 atomes : **290 fractions et un seul atome plein**.
Le garde-fou 3 de `40` les écarte, et son motif écrit ne tient pas — un
atome-fraction n'est pas une commune coupée, il est la part d'une commune dans
UN canton, donc la question a pour lui une réponse unique.

Mesuré avant de le lever : 243 fractions recevraient une réponse unanime, au
prix de **14 281 km² dessinés deux fois** sur la couche circo, puisqu'elles
portent le polygone de leur mère. Plus que le recouvrement déjà connu.

**Décision : on ne touche à rien.** L'embargo ANR-COMMUNES tombe le 1er
septembre et règle les géométries à la racine ; poser 243 rattachements pour les
redessiner douze jours plus tard serait du travail à refaire.

### Port-Saint-Louis-du-Rhône — une circularité parfaite

Seul atome plein qui résistait. Née en 1904 par détachement d'Arles, sans
circonscription de 1870 à 1901. Son canton 1304 ne compte alors que deux
membres : elle, et une FRACTION d'Arles — laquelle n'a pas de circonscription
précisément parce que le garde-fou 3 l'écarte. Le voisin unique est muet par
construction, et aucun élargissement de `40` ne l'aurait ouvert.

`48_diag_mere_muette.sql` a mesuré la classe avant d'écrire : **32
années-communes, un atome**. `47_circo_mere.sql` pose la règle plutôt que le cas
— « voisins muets, mère HAC unique, alors la mère » — parce que la classe n'est
petite qu'aujourd'hui : elle est tenue basse par le garde-fou 3, qui sautera.

**La recette est un vrai contrôle, et il passe.** La dernière ligne posée,
`U1303@1889`, se ferme au 1er janvier 1902 ; la ligne NATIVE `U1303@1902` s'y
ouvre. Même circonscription, ni trou ni chevauchement. La base confirme la
filiation d'elle-même, sans que HAC ni Wikipédia aient à être crus sur parole —
le contraire du piège de Cherré, où le témoin était resté muet.

### Deux dettes, laissées ouvertes et non enterrées

**La couche circo n'a aucun contrôle indépendant entre 1870 et 1940.**
`controle_gay.sh` ne regarde que les cantons. `40` vient d'y poser 7 932
années-communes sans que rien ne les vérifie. L'atlas Gaudillère est la bonne
réponse — il donne la composition des circonscriptions PAR CANTON, et la règle
de `40` est exactement une règle canton → circonscription. Le contrôle est donc
direct et n'exige aucune donnée communale. Seul Marseille est transcrit.

**`40` et `47` reposent sur la couche cantonale de `11`**, dont le pari est
mesuré par le contrôle Gay. Un mauvais canton propage désormais une mauvaise
circonscription. La dépendance n'était pas là avant ce soir.

## 20 août 2026, nuit — la couche circo refaite, et deux fautes de méthode

### Le découpage de 1986 courait jusqu'en 2010 : il court jusqu'en 2012

Signalé par Adrien. La base faisait basculer le découpage de 2009 au
**23 février 2010**, date de la loi ratifiant l'ordonnance n° 2009-935. Or
l'ordonnance fixe elle-même son entrée en vigueur **au prochain renouvellement
général** — juin 2012. Le découpage de 1986 a servi à cinq élections : 1988,
1993, 1997, 2002, 2007 (Sénat, dossier pjl09-048).

Deux années affichaient donc des circonscriptions où personne n'a jamais voté.

L'argument décisif est d'Adrien : « on ne sait jamais avec les législatives
partielles ». Une partielle se tient entre deux renouvellements, sur le
découpage **en vigueur** — celui de 1986 jusqu'en juin 2012.

La convention du projet ne change pas : elle date les ACTES, pas les scrutins.
Ce qui était faux, c'est la date d'acte retenue. Corrigé dans `27`, `28`,
`40_outremer` et `43_circo_fraction`.

### Les 125 communes indéterminées de 1986 : 115 levées

Adrien avait le § 5 de l'atlas Gaudillère, transcrit dans `1986 gaudilliere`.
Il énumère les cantons divisés de 1986 et dit, commune par commune, où chacune
vote. `resoudre_1986_partage.py` en fait une table, `49_circo_1986_partage.sql`
la charge : **118 lignes, 115 communes, 16 cantons**.

**Le contrôle est réel, et c'est ce qui compte.** Le ministère annonçait une
PAIRE de circonscriptions par canton sans dire laquelle ; l'atlas nomme les
communes. Les deux sources se recoupent sur la paire sans se recopier.
**Zéro des 118 lignes ne sort de la paire annoncée.**

Restent dix communes, toutes des villes coupées entre plusieurs
circonscriptions : arrondissements de Lyon, Roubaix, Drancy/Dugny/Le Bourget,
Cappelle-la-Grande et Saint-Pol-sur-Mer. Même famille que Paris et Saint-Denis
de La Réunion — le blocage est infra-communal, pas documentaire.

**Je m'étais trompé sur l'atlas** en cours de route : j'ai affirmé que son § 5
ne mentionnait aucun canton du Nord et qu'il contredisait donc le ministère. Il
en décrit dix. Je lisais le résumé de `annexe_vi.md` en le prenant pour la
source. **Une absence dans une transcription n'est pas une absence dans
l'original.** La note est corrigée.

Deux désaccords subsistent, consignés et non tranchés : l'atlas déclare divisés
les cantons de **Douai-Ouest** et de **Condé-sur-Escaut**, que le ministère
donne d'un seul tenant.

### La couche entière effacée, et remise

En rejouant `27` et `28` avec les nouvelles bornes, la couche est tombée de
37 000 rattachements à 118. La cause est un défaut de conception que j'avais
sous les yeux depuis le matin, écrit dans `README.md` : ces fichiers suppriment
leurs unités avant de les recréer, la clé étrangère les arrête quand un autre
fichier les référence — et psql validant chaque instruction séparément, la
suppression reste acquise. La base finit plus vide qu'avant.

Ce qui bloquait : les 118 lignes de `49`, et les rattachements modernes de
`40_scission_circo`. **`47` et `49` s'étaient ajoutés à la liste des dépendants
sans que je mette la liste à jour** — cette liste existe précisément pour
éviter cela.

Trois remèdes, tous en place :

* **`rejouer_circo.sh`** — retire les dépendants par leurs traces, repose `28`,
  `27`, l'outre-mer, puis `49`, `47`, `40` dans l'ordre. C'est le chemin normal.
* **Un contrôle préalable** dans `27` et `28` : ils refusent de commencer et
  **nomment la table de trace bloquante**, au lieu de laisser psql parler d'une
  contrainte sur `59-13@1986`.
* La liste de `README.md` complétée, avec la consigne de la tenir à jour.

Repères après remise : 37 132 rattachements pour 1986 (533 unités), 37 257 pour
2009 (539), zéro chevauchement, zéro atome dans deux circonscriptions.

### Deux fois la même faute de requête dans la soirée

`47` puis `40` ont tourné plusieurs minutes sans rendre la main, pour poser
quatre lignes et mille. Dans les deux cas j'avais fondu un filtre sélectif et
un filtre coûteux dans une seule requête, laissant le planificateur appliquer
le second à des millions de lignes.

`47` ne peut poser que là où HAC nomme une mère de façon unique : **444 lignes**,
contre 3,6 millions de couples année × atome. Conduire la requête par la table
la plus petite l'a ramené à quelques secondes.

**Conduire par la table la plus sélective n'est pas une optimisation : c'est la
différence entre une requête et une attente.** Deux fois dans la même soirée.

## 21 août 2026 — l'Ain, ou comment une base cohérente peut être fausse

Signalé par Adrien : « la carte des circonscriptions n'a pas de sens, les
circonscriptions sont en petit morceaux ». Quatre circonscriptions, **vingt-
trois morceaux disjoints**, alors que l'article L. 125 impose un territoire
continu.

### La mesure qui isole le coupable

Fragmentation comparée sur les 95 départements, couche 1986 contre couche 2009.
Vingt-six départements sortent fragmentés en 1986 — mais **vingt-cinq le sont
autant en 2009** : Morbihan, Finistère, Charente-Maritime, Var, Vendée,
Côtes-d'Armor. Ce sont les départements à îles. Belle-Île n'est pas un défaut.

L'Ain est seul : 4 circonscriptions pour 23 morceaux, sans une île, et d'un
seul tenant en 2009. **La colonne « Circ. législative 1986 » de
`correspondance_2012.xls` est brouillée pour ce département** — 30 cantons sur
43 mal affectés. La colonne 2012 du même fichier est juste, ce qui rend le
défaut invisible à toute comparaison interne.

### Le faux contrôle

J'ai d'abord confronté `circo_1986.csv` à `circo_1986_ain.csv` et annoncé
« zéro désaccord sur 43 cantons ». Le second est dérivé du premier — sa colonne
`nb_communes` le trahissait. **Comparer une source à sa propre copie donne
toujours zéro désaccord.** Consigné dans `METHODE.md`.

### La source qui fait foi

Loi n° 86-1197 du 24 novembre 1986 (JO du 25 novembre, p. 14171) et
**Gaudillère, p. 89**, via l'article « Liste des circonscriptions législatives
de l'Ain ». Contrôle interne de la source : les quatre listes totalisent
**43 cantons, chacun une fois exactement**.

**Bourg-en-Bresse n'est pas coupée.** Ses trois cantons sont dans la seule 1re
circonscription. `note_bourg_1986.md` est marquée FAUSSE en tête plutôt que
corrigée en silence : sa thèse entière venait de la colonne brouillée. Le
décret n° 82-77 de 1982 qu'elle cite reste juste pour les cantons.

### Le correctif

`circo/circo_1986_correctifs.csv` — table générique `dep, canton, canton_nom,
circo, source`, où la colonne `source` doit nommer un texte, pas un
raisonnement. `sql/51_circo_1986_correctif.sql` la pose, tourne à blanc par
défaut, trace tout dans `circo_correctif_trace`.

**291 rattachements changés sur 422.** Après passage : 4 circonscriptions,
**un seul morceau chacune**.

### Ce que ce cas laisse ouvert

Le défaut était invisible à toute recette interne : zéro chevauchement, zéro
atome à double, toutes les communes rattachées. La base était cohérente avec
elle-même de bout en bout. **C'est un œil humain sur une carte qui l'a vu.**

Et la fragmentation ne détecte que le désordre, pas l'erreur : un département
mal affecté vers des voisins immédiats sortirait d'un seul tenant. Savoir que
l'Ain était faux ne dit **rien** des 94 autres. Un contrôle exhaustif demande
la saisie des 555 circonscriptions de 1986 depuis l'atlas ou le JO — c'est
désormais le premier poste de doute de toute la couche électorale.

## 21 août 2026 — Paris entre dans la base, et la base remonte à 1815

### Le trou de 1986 est comblé

`28_circo_1986.sql` le déclarait : « Paris absent du découpage de 1986
(21 circonscriptions) ». La raison n'était pas un oubli mais une impossibilité —
le tableau du ministère ne descend pas sous la commune, et à Paris les
circonscriptions **coupent les arrondissements**.

Deux pièces existaient depuis le 14 août et n'avaient jamais servi :
`paris_decoupage.csv`, qui donne la composition PAR QUARTIER de dix-neuf
divisions de 1815 à 1986, et `paris_quartiers.py`, qui reconstruit les 80
quartiers par union d'IRIS. **Elles n'étaient pas en base** : `rebuild.sh` les
avait effacées, et rien dans la chaîne ne les recréait. Troisième récidive de
la leçon de `19_noms_geofla.sql`. Les quatre scripts sont désormais appelés par
`rejouer_apres_rebuild.sh`.

`52_paris_circo_1986.sql` pose 80 atomes de quartier, 21 unités et **73
rattachements**. Sept quartiers coupés entre deux circonscriptions ne sont pas
posés — nommés plutôt qu'attribués au jugé, comme le fait `27` pour les
communes coupées.

### GEOFLA est un produit généralisé — constat structurel

La superposition des couches était mauvaise. Trois hypothèses successives, deux
fausses :

1. *deux trames différentes* — vrai, mais insuffisant ;
2. *l'accrochage à 25 m* — **faux** : réexporté à 2 m, rien ne change ;
3. la géométrie elle-même.

Mesuré en base : **GEOFLA tient 0,9 sommet par kilomètre de contour**, un point
tous les 1 100 mètres. La trame IRIS en tient 5,9 à 8,3. Médiane de 13 sommets
par atome ; **26 % des atomes de plus d'un km² sont dessinés avec dix sommets ou
moins**. Clichy sort en pentagone.

Ce n'est pas un défaut de Paris mais le socle de `05_geom.sql`. GEOFLA est fait
pour la petite échelle et le tient parfaitement ; il ne peut pas tenir un autre
rôle. Cela explique aussi les écarts de 0,2 à 0,35 km² **dans les deux sens**
sur les arrondissements parisiens — signature d'une généralisation, pas d'une
erreur de tracé.

`53_paris_geom_iris.sql` réaligne les vingt arrondissements sur l'union de
leurs quartiers : 104,90 → **105,43 km²**, la surface officielle. Le même
chantier reste ouvert pour le reste de la France, et il est gros.

### La base remonte à 1815

Adrien a tranché la licence ODbL, et il avait raison : elle distingue la base
(partage à l'identique), les contenus (DbCL, droits levés) et **les œuvres
produites**, dont ALPAGE fixe la licence à **CC-BY-SA 2.0 pour toutes les
cartes**. Une carte tirée de Vasserot est donc publiable sur Commons. La ligne
passe entre produire une carte et republier des données : une base dérivée
reste ODbL, donc exclue de Wikidata, qui est en CC0.

Crédit obligatoire et nominatif : **© ALPAGE : Anne-Laure Bethe**.

La couche 42 d'ALPAGE donne les 48 quartiers des douze arrondissements
d'avant 1860, d'après l'atlas Perrot sur les plans Vasserot. Contrôles :

* 48 quartiers, 12 arrondissements, quatre chacun, numéros 1 à 48 sans trou ;
* **0,000 km² hors du Paris de 1860** — l'annexion n'a fait qu'ajouter, et
  l'emboîtement le confirme. C'est un contrôle géométrique indépendant de la
  source : il tombe si le géoréférencement de l'atlas est faux ;
* 32,70 km² contre 105,43 après 1860 : **la ville a triplé** ;
* **les cinq divisions d'avant 1860 partitionnent les 48 quartiers**, sans un
  absent ni un non résolu. 48 éléments ne tombent pas juste par hasard cinq
  fois de suite.

Le vocabulaire `paris_vocab_1815.csv` compte 48 clés : 41 directes et 7
corrections nommées une à une — deux articles, trois orthographes, une coquille
f/E, et **le renommage du Jardin du Roi en Jardin des Plantes**, qui est un
fait historique et non une faute de frappe.

`54_paris_circo_1815.sql` pose 48 atomes, 38 unités, 240 rattachements.
**La base commence désormais au 1er janvier 1815.**

Trois réserves écrites dans le fichier :

* **la trame n'est pas un instantané** — les levés vont de 1810 à 1836, soit un
  anachronisme possible d'un quart de siècle ;
* **le régime de scrutin est une contrainte du modèle**, pas une donnée : le
  schéma impose `liste` ou `uninominal`, et les collèges d'arrondissement de la
  Restauration n'entrent ni dans l'un ni dans l'autre. `provisoire = true` le
  dit dans la donnée ;
* **1848-1852 manque**, et 1850 sort vide à la recette — le trou se voit, comme
  le veut `ETAT.md`.

### Une virgule, corrigée dans le CSV et pas dans le tableur

`mont de piétémarais` collait deux quartiers. Dédoublé directement dans
`paris_decoupage.csv`, selon le critère du projet : les deux formes existent
ailleurs dans le fichier, cinq fois chacune. **`paris_decoupage.xlsx` n'a pas
été touché** — le prochain `extrait_paris.py` effacera la correction. À porter
dans le script, à côté des douze coquilles qu'il traite déjà.

### Les deux trous comblés — `55_paris_circo_serie.sql`

**1863-1870** (entre Vasserot et TRF-GIS) et **1941-1986** (où la couche circo
est vide dans toute la France). Quatre divisions, **52 unités, 312
rattachements**. Huit quartiers coupés en 1958-1986 — Picpus, Grenelle, Muette,
Plaine Monceau, Batignolles, Épinettes, Clignancourt, Villette — nommés, pas
attribués.

`1958-1986` est **le premier morceau de ce découpage posé dans la base**. La
province l'attend toujours derrière le trou cantonal 1943-1999 : il se définit
par cantons partout, sauf à Paris où il se définit par quartiers.

Le fichier porte un garde-fou que la soirée avait rendu nécessaire : il vérifie
que les périodes visées sont **vides pour Paris**, et refuse de s'appliquer
sinon. Combler et remplacer ne sont pas le même geste, et `27`/`28` ont montré
ce que coûte de les confondre.

Chaîne parisienne obtenue, de 1815 à 2012, avec deux interruptions déclarées :
1848-1852 et 1941-1945.

### Ce que la recette a révélé : Paris est plus grossier en 1870-1940 qu'avant

| date | atomes | circonscriptions |
|---|---|---|
| 1865 | 80 | 9 |
| **1900** | **20** | **20** |
| 1970 | 72 | 28 |
| 1990 | 73 | 21 |

TRF-GIS attribue la circonscription à l'arrondissement ENTIER. Paris sort donc
à vingt circonscriptions entre 1870 et 1940, là où la transcription en compte
**trente-sept en 1893 et quarante en 1902**. En poussant le curseur, la ville
s'affine, se simplifie brutalement en 1870, puis se raffine en 1945 —
l'inverse de ce qu'on attend d'une base historique.

Les neuf divisions de cette période sont transcrites et résolues. Les poser au
quartier corrigerait la période la mieux documentée de la base, mais ce serait
**remplacer** de la donnée : c'est le dernier chantier parisien, et il exige
son propre contrôle.

### 1876-1941 au quartier — `56_paris_circo_1876.sql`

Le seul fichier parisien qui **remplace** de la donnée, et le diagnostic a
changé en cours de route.

J'avais écrit que « TRF-GIS confond arrondissement et circonscription ».
**C'est faux pour 1876-1881** : la transcription y donne elle aussi vingt
circonscriptions, valant chacune exactement les quatre quartiers d'un
arrondissement. Paris élisait bien un député par arrondissement. Le découpage
se subdivise à partir de **1881** :

| division | circos | dont arrondissements entiers |
|---|---|---|
| 1876-1881 | 20 | **20 / 20** |
| 1881-1885 | 27 | 13 / 27 |
| 1889-1893 | 34 | 8 / 34 |
| 1893-1898 | 37 | 5 / 37 |
| 1902-1910 | 40 | 3 / 40 |
| 1928-1940 | 37 | 6 / 37 |

TRF-GIS reste à vingt sur toute la période : **il ne suit pas les redécoupages
successifs**. C'est une carte figée pendant soixante ans, pas une confusion de
nature.

Ce qui a autorisé le remplacement, faute de conflit à arbitrer : la
transcription **partitionne les 80 quartiers** sur chaque division, et son
alternance liste/uninominal **retrouve celle de TRF-GIS** — trois
circonscriptions en 1919-1928 des deux côtés, une seule en 1872 et 1887. Deux
sources indépendantes s'accordent là où TRF-GIS décrit un objet réel.

Posé : **220 rattachements retirés, 313 unités, 775 rattachements**. Les
périodes de liste 1870-1876 et 1885-1889 ne sont pas touchées — TRF-GIS y a
raison et la transcription n'a rien.

La division sans date `?-?` est posée en **1898-1902**, sur inférence déclarée
(`provisoire = true`) : c'est le seul intervalle uninominal non couvert, et la
seule division sans date. Les trois autres intervalles s'expliquent — deux
scrutins de liste et la guerre.

**Deux circonscriptions du 11e sortent sans territoire.** Roquette,
Saint-Ambroise et Sainte-Marguerite sont partagées par le boulevard Voltaire ;
ne pouvant descendre sous le quartier, les deux circonscriptions perdent leur
terrain. C'est la question ouverte n° 2 de `note_paris.md`, désormais visible
dans la donnée.

### Deux défauts de `55`, trouvés en relisant la sortie

**Le régime était une constante.** J'avais écrit `'uninominal'` en dur pour les
quatre divisions ; **1945-1958 est un scrutin de liste** — représentation
proportionnelle. Le compte le disait : trois circonscriptions pour Paris ne
peut pas être un uninominal. La donnée portait la réponse et je ne l'ai pas lue.

**Le garde-fou se jugeait lui-même.** Il vérifiait que les périodes étaient
vides AVANT de retirer son propre passage ; au second lancement il prenait ses
propres rattachements pour de la donnée à protéger et refusait de tourner.
**Un fichier rejouable efface sa trace d'abord, et juge ensuite.**

## 22 août 2026 — la chaîne d'OCR mise à l'épreuve, et trois erreurs de mesure

`--psm 4` remplace `--psm 6` pour 1968. Gain mesuré sur trois fascicules
entiers : **+22, +35, +22 communes justes**, faux quasi plats. Le mode « 4 »
suppose une colonne de texte de tailles variables, « 6 » un bloc uniforme :
le tableau III est en colonnes.

Le défaut de `page_texte` reste « 6 » ; 1968 passe « 4 » en argument. La mesure
porte sur les fascicules de 1968, pas sur les volumes de 1954.

### Ce qui a été éliminé, et sur quelle preuve

| variante | 79 | 43 | 65 | verdict |
|---|---|---|---|---|
| **psm 4** | **+28** | **+37** | **+32** | retenu, régulier |
| 400 dpi | +30 | +5 | +25 | effet de scan, non portable |
| 600 dpi | +21 | +34 | +1 | idem, plus instable |
| psm 11 / 12 | 0 justes | 0 | 0 | détruit la structure en lignes |
| seuillage | −25 | — | — | dégrade |
| netteté | +8 pour 9× le temps | — | — | non rentable |

(Écarts mesurés sur les quatre pages les plus faibles de chaque fascicule.)

### Trois fois le même piège, et il ne portait pas sur l'OCR

**Premier essai : des pages sans tableau.** Zéro partout, y compris pour le
témoin. *Un banc d'essai qui rend zéro pour le témoin ne rend pas un verdict,
il rend un silence* — et j'ai commenté le tableau comme s'il disait quelque
chose.

**Deuxième essai : les pages les plus productives**, choisies par un
`pages_productives()` que j'avais écrit moi-même. Ce sont par construction
celles que la chaîne lit déjà bien — 95 % de réussite — et toute variante ne
pouvait qu'y perdre. J'en ai conclu « le levier des paramètres est épuisé ».
Sur les pages faibles, le même banc, les mêmes variantes, la même heure : +30.
**Le choix de l'échantillon avait dicté la conclusion, et l'avait inversée.**

**Troisième : un classement bâti sur un écart de 2.** Aux Deux-Sèvres, 400 dpi
finissait deux points devant psm 4 ; j'ai déclaré 400 dpi vainqueur, prédit
qu'il gagnerait partout, et expliqué pourquoi. Deux départements de plus ont
montré que le vainqueur réel était le second, et que ma championne variait du
simple au sextuple selon le scan.

**Un angle mort, trouvé avant qu'il ne morde.** `pages_a_tester` classait les
pages par rendement croissant d'après `communes_1968.csv` — or une page qui n'a
rendu AUCUNE commune n'y écrit aucune ligne. Les pires pages du fascicule
étaient invisibles par construction. Corrigé par `--toutes`, qui parcourt
l'étendue min..max. Aucune page muette dans les trois fascicules testés.

### Ce que la journée aura donc appris sur la mesure

La régularité entre échantillons **indépendants** est ce qui distingue un effet
réel d'un accident local. Un classement sur un seul échantillon ne le peut pas,
quel que soit le soin mis à l'établir. Et le choix de l'échantillon fait partie
de la mesure : il doit être justifié comme elle, et écrit avant de regarder.

### Le résultat n'est pas venu du réglage, mais de la redondance

`--psm 4` porté aux 86 départements : **+130 communes**, contre les ~2 200 que
le banc laissait espérer. 41 départements gagnent (+447), 42 perdent (−317).
Les trois fascicules du banc — 79, 43, 65 — avaient été choisis pour leurs
pages effondrées : les plus abîmés du lot. Ils gagnent bien +27, +38, +24,
exactement comme mesuré. **Le banc était juste ; il n'était pas représentatif.**

Quatrième fois de la journée que le choix de l'échantillon dicte la conclusion
— et la leçon des trois premières était déjà écrite dans `METHODE.md` quand
j'ai commis la quatrième. *Écrire une règle ne suffit pas à l'appliquer : il
faut se demander, au moment de choisir, pourquoi ceux-là.*

Mais la comparaison des deux passes a montré l'essentiel :

    psm 6 seul   28 720 communes
    psm 4 seul   28 941
    communs      24 916
    UNION        31 697

**Elles ne se recouvrent qu'à 89 %.** Choisir la meilleure jetait 2 756
communes que l'autre savait lire. `fusionne_passes.py` les réunit.

| | |
|---|---|
| rappel psm 6 corrigé | 83,4 % |
| rappel psm 4 corrigé | 84,0 % |
| **rappel de la fusion** | **91,4 %** |
| départements sous 80 % | 20 → **2** |
| inconnus de l'étalon | 324 → 534 |

Les inconnus montent de 210 : c'est le prix de l'union, et il est faible devant
2 756. Sur la fusion, `corrige_codes.py` ne trouve plus **rien** à corriger —
192 cas passent en « douteux » parce que les deux codes sont désormais présents,
apportés chacun par une passe. Le critère refuse de trancher là où il tranchait
à l'aveugle sur une passe seule ; c'est un gain de prudence, pas une perte.

**J'ai failli effacer `communes_1968.psm6_corrige.csv`** avant de lancer la
nouvelle passe. C'est la règle du dépôt — *on signale, on ne supprime pas* —
qui a sauvé la moitié du résultat de la journée.

### Deux réserves portées dans la donnée

**La fusion n'est pas un contrôle indépendant.** Même image, même moteur : les
erreurs sont corrélées, et l'accord des deux passes ne prouve que l'innocence
de la segmentation. L'étalon reste `cm_commune`.

**1 156 communes ont un canton contesté** (3,6 %) — la colonne `accord` les
marque `canton_conteste`, et `canton_autre` porte la lecture écartée.

*Le chiffre annoncé le jour même était 2 319, soit le double.* Mon compteur
s'incrémentait à deux endroits — une fois par commune dans la branche, une fois
par ligne à la sortie de boucle — et le faux total avait déjà circulé dans ce
journal, dans la note et dans la mémoire quand le CSV lui-même l'a démenti.
**Un compteur qui s'incrémente à deux endroits finit toujours par mentir**, et
un chiffre publié doit pouvoir être recalculé depuis le fichier produit, jamais
seulement depuis la variable qui l'a fabriqué. C'est
précisément le rattachement que ce dépouillement cherche pour le trou de
1943-1999 : ces lignes ne devront pas entrer en base au même titre que les
autres. Une première version de la fusion les posait toutes les deux et
fabriquait 1 247 communes multicantonales imaginaires, là où le fascicule n'en
compte que 130 à 202.

## Le trou cantonal 1943-1999 reçoit son premier jalon

`58_cog1968_stage.sql` et `59_cog1968_membership.sql`. **30 939 rattachements
cantonaux posés au 1er janvier 1968**, sur 2 844 cantons, avec 460 atomes-
fraction créés pour les communes multicantonales.

Avant : `snapshot(1968)` ne renvoyait **aucun** canton. `24` le disait sans
détour — « le membership s'arrête en 1941 et reprend en 1999, avec RIEN entre
les deux ». Cinquante-huit ans muets.

### Les bornes, et pourquoi elles sont si courtes

`[1968-01-01, 1969-01-01)`. **Cette année et rien de plus.**

Un recensement dit un ÉTAT à une DATE. L'étendre jusqu'à 1999 ferait répondre
`snapshot` sur trente ans d'un coup, en supposant une stabilité que le registre
cantonal contredit — 48 démembrements postérieurs à 1986. L'accord de 88,3 %
entre 1968 et 1999 ne suffit pas : il tombe à 54 % dans le Val-de-Marne, 57 %
dans les Bouches-du-Rhône, 58 % dans les Hauts-de-Seine. Une borne large y
poserait des rattachements faux qu'aucune recette interne ne distinguerait des
vrais — la leçon de l'Ain.

L'extension sera `60`, département par département, sur pièces.

### Marquer plutôt qu'exclure, et les trois cas où c'est impossible

Décision d'Adrien : tout ce qui PEUT être posé l'est, avec sa qualité dans
`c68_qualite`.

| qualité | rattachements | part |
|---|---|---|
| `ferme` | 24 719 | 79,9 % |
| `lecture_unique` | 5 104 | 16,5 % |
| `canton_conteste` | 967 | 3,1 % |
| `atome_ambigu` | 149 | 0,5 % |

Trois classes échappent à la règle pour une raison **structurelle** et non
prudentielle : un `membership` ne peut référencer ni un canton absent de la
nomenclature (493 lignes), ni un atome inexistant (7), ni une commune que
`cm_commune` ignore en 1968 (537).

### Ce que 58 aurait dû mesurer et que je n'avais pas vu

`cm_atome` fait passer une commune disparue par son SUCCESSEUR. Deux communes
distinctes en 1968, fusionnées depuis, se résolvent donc au même atome — et
`membership_non_chevauchant` refuse le second rattachement si leurs cantons
diffèrent. Mon garde-fou d'origine levait une exception : il aurait fait
échouer tout le fichier sur un cas parfaitement prévisible.

**J'annonçais que le chiffre pourrait être gros et « limiter le jalon plus que
l'OCR ». Il y en a QUATRE** — deux en Corse, un en Moselle, un dans l'Essonne
— dont deux seulement à cantons divergents. La maille atomique tient bien mieux
que je ne le craignais. *Une inquiétude n'est pas une mesure ; celle-ci valait
2 lignes sur 30 941.*

### Quatre cantons à trancher sur pièces

Des 361 cantons cités par 1968 et absents de la nomenclature, la moyenne de
citation est de 1,4 : ce sont des codes mal lus. Quatre font exception et sont
des candidats à une **création réelle entre 1954 et 1968** :

| canton | citations | département | exemple |
|---|---|---|---|
| `5740` | 16 | Moselle | Alsting |
| `8051` | 6 | Somme | Agenvillers |
| `1454` | 6 | Calvados | Amfreville |
| `5181` | 5 | Marne | Faverolles-et-Coëmy |

Ils ne sont **pas** créés par `59` : créer une unité cantonale sur la foi de
l'OCR reviendrait à inventer un canton. À vérifier au Journal officiel.

### Recette

`hors_bornes` = 0, `atomes_au_31_12_1967` = 0. Le jalon ne déborde ni en aval
ni en amont. Les deux compteurs sont lus depuis `membership`, pas depuis la
table qui a servi à le remplir — *une recette qui relit sa propre source ne
vérifie que la copie.*

### Forbach-II — un canton invisible par construction

`60_canton_forbach2.sql`. Le recensement rattachait seize communes de Moselle à
un canton `5740` que `unit` ignorait. Ce n'était pas une erreur de lecture.

**Décret du 8 août 1967** : dédoublement de Forbach en Forbach-I et Forbach-II.
**Décret du 24 décembre 1984** : les deux disparaissent, redivisés en Forbach,
Stiring-Wendel et Behren-lès-Forbach.

Forbach-II n'existe ni en 1940 (TRF-GIS) ni en 1999 (COG) — **les deux seules
sources dont `unit` est faite**. Il était invisible par construction, et le
serait resté sans le recensement.

Composition publiée par Wikipédia : seize communes. Notre lecture : **les seize,
et rien d'autre**. Le contrôle est écrit dans le fichier et lève une exception
si la concordance n'est pas parfaite ; la comparaison porte sur le code INSEE,
jamais sur le nom — comparer l'OCR à lui-même ne prouve rien.

### Les trois autres candidats étaient des erreurs, et le disent

| lu | vrai | canton | preuve |
|---|---|---|---|
| `1454` | `1434` | Troarn | Amfreville, Escoville, Vimont s'imbriquent dans Bavent, Argences |
| `8051` | `8031` | Nouvion | Agenvillers, Gapennes voisines de Domvast, Canchy |
| `5181` | `5131` | Ville-en-Tardenois | Faverolles-et-Coëmy voisine de Branscourt |

Toutes trois suivent la table de confusion mesurée le matin même : **le chiffre
3 des dizaines lu 5 ou 8**. Et `5181` répartissait ses cinq communes sur TROIS
arrondissements — un canton ne fait pas cela.

**Un test que j'avais cru décisif ne prouvait rien.** Je comparais le
chevauchement entre le canton fantôme et son voisin par substitution, attendant
qu'un chevauchement fort trahisse le doublon. Il est nul dans les DEUX
hypothèses : une commune mal lue quitte le vrai canton pour le faux. Le critère
ne pouvait rien départager, et c'est la géographie qui a tranché — comme pour
les 311 faux transferts de 1954.

### Ce que cette vérification a vraiment trouvé

L'annexe VII compte **30 créations cantonales entre 1954 et 1968**, très
majoritairement urbaines — Nice, Mulhouse, Strasbourg, Lyon, Villeurbanne,
Le Mans, Belfort — et beaucoup disparaissent dès 1973.

**Ces cantons sont absents de TRF-GIS et du COG 1999 : ils sont invisibles à
notre nomenclature par construction.**

Cela corrige une explication donnée trop vite le matin. Les départements les
plus mal lus — 92, 13, 94, 93, 06, 69, 90 — ne souffraient pas d'une mise en
page particulière : leurs cantons de 1968 n'existent plus en 1999. Le Territoire
de Belfort à 59 % d'accord avec 1999 s'explique par les sept cantons créés le
9 août 1967.

*J'avais attribué à l'OCR ce qui relevait de la nomenclature.* Le signal était
le même — des départements urbains en bas de tableau — et j'ai retenu la
première cause plausible sans chercher la seconde.

### Le gisement de cantons disparus n'existe pas — la mesure l'a réfuté

`61_cantons_disparus_diag.sql`. J'annonçais 29 créations cantonales 1954-1968 à
récupérer. Résultat sur les 361 cantons inconnus :

| effectif | cantons | lignes |
|---|---|---|
| 8 et plus | **1** | 16 |
| 5 à 7 | 3 | 17 |
| 3 ou 4 | 23 | 74 |
| 1 ou 2 | 334 | 405 |

**Forbach-II est un cas isolé.** Les 334 cantons cités une ou deux fois sont des
codes mal lus — et le § 5 le confirme : huit des candidats à trois communes ou
plus chevauchent deux ou trois arrondissements, ce qu'aucun canton ne fait.

### Pourquoi les créations urbaines ne ressortent pas

Parce que **les villes elles-mêmes ne sont pas lues** :

    NICE, NANTES, BORDEAUX, STRASBOURG, TOULON, BREST, METZ, NANCY,
    ORLEANS, POITIERS, TROYES, DUNKERQUE, CHARTRES, BLOIS, AMIENS,
    MONTPELLIER, VALENCE, BAR-LE-DUC, CHARLEVILLE-MEZIERES

**19 manquantes sur 53 grandes villes dans le périmètre — 36 %, contre 8,6 %
pour l'ensemble des communes.** Caen ne sort qu'avec deux cantons quand le
décret de 1967 lui en donne quatre ; Belfort avec trois quand sept ont été
créés le 9 août 1967.

Les cantons urbains ne manquent donc pas parce qu'ils auraient disparu de la
nomenclature. **Ils manquent parce que leur ville échappe à l'OCR** — et une
ville perdue emporte tous ses cantons avec elle.

### Deux erreurs de raisonnement, du même genre

**J'ai attribué à la nomenclature ce qui relevait de la lecture** — après avoir,
le matin même, attribué à la lecture (la mise en page à accolades) ce qui
relevait de la nomenclature. Les deux fois, un signal unique — les départements
urbains en bas de tableau — admettait deux causes, et j'ai chaque fois retenu
la première venue sans chercher la seconde.

**Et j'avais abandonné le bon motif pour une mauvaise mesure.** Le 22 août au
matin, le motif « ville découpée en cantons » ne pesait que 167 lignes LUES, et
j'en ai conclu qu'il était marginal. Il l'est parmi les lignes acceptées, par
construction : ces lignes-là sont justement celles qui ont échoué. *Compter un
défaut parmi les cas où il ne s'est pas produit ne mesure pas sa fréquence.*

### La ligne de continuation des villes — mesurée, portée, non déployée

`essai_grammaire.py`, six départements, une seule passe d'OCR réutilisée par
quatre grammaires. Trois départements dont la préfecture manque (45, 10, 54) et
trois bien lus (21, 50, 32) : le gain se cherche chez les premiers, le coût chez
les seconds.

| variante | rattachements | faux |
|---|---|---|
| + deux-points | +5 | **+1** |
| **+ ligne de continuation** | **+9** | **0** |
| les deux | +11 | +1 |

**Retenu : la ligne de continuation seule.** Elle capte de toute façon
`ORLÉANS : Canton Ouest`, puisque la ligne porte le mot *canton*.

Porté dans `extrait_1968.py`, avec deux effets de bord traités :

* le nom est **récupéré** devant le séparateur — « ORLÉANS », « TROYES » — au
  lieu d'être jeté avec le libellé ;
* le même nettoyage s'applique aux lignes reconnues par la grammaire
  PRINCIPALE : « TROYES ) 3* Canton (1) » sortait jusqu'ici sous ce nom entier,
  désaccord garanti au contrôle nom/code. Aucune commune française ne porte
  « canton » dans son nom.

**NON DÉPLOYÉ.** Le gain extrapolé est de ~160 rattachements sur 30 939, soit
0,5 % : cela ne paie pas deux passes complètes d'OCR. Le correctif attend la
prochaine passe, quelle qu'en soit la raison — et la meilleure raison serait une
TROISIÈME lecture, puisque deux lectures ont valu +2 756 communes là où le
meilleur réglage n'en valait que +130.

### Une erreur d'une espèce nouvelle : le compteur, pas l'échantillon

Le premier banc rendait **+4**. Le second, sur les mêmes textes et les mêmes
grammaires, rend **+11**. Rien n'avait changé que la chose comptée.

Je comptais des **communes** pour juger un correctif qui produit des
**cantons** : une ville multicantonale vaut un code et plusieurs rattachements,
et Troyes — déjà lue par sa troisième ligne — gagne deux cantons sans gagner un
seul code.

Le pire est que je l'avais écrit, dans le message même où je proposais le banc :
« le rappel bougera à peine, mais la composition cantonale passera de partielle
à complète ». Puis j'ai construit le banc qui mesure le rappel.

Les erreurs précédentes de la journée portaient sur l'ÉCHANTILLON — mesurer là
où il n'y a rien à gagner, classer sur un seul cas. Celle-ci porte sur le
COMPTEUR : l'échantillon était bon, le témoin en place, les deux moitiés bien
choisies. **Énoncer ce qu'on veut mesurer ne garantit pas qu'on le mesure** ;
relire le compteur contre l'intention est un geste distinct, et il manquait.

## Le premier contrôle indépendant de la couche 1870-1940 trouve un défaut structurel

`62_recette_villes_divisees.sql` puis `63_diag_villes_divisees.sql`.

**La couche 1870-1940 ne contient AUCUNE ville divisée entre plusieurs
circonscriptions. L'annexe VI § 6 en annonce 19 en 1875, 22 en 1889, 41 en 1927.**

Ce n'est pas un écart de comptage. C'est une hypothèse fausse, héritée de
TRF-GIS : **chaque commune est attribuée ENTIÈRE à une circonscription unique.**
Le diagnostic l'établit sans ambiguïté :

| contrôle | résultat |
|---|---|
| rattachements circo à 1878, 1890, 1930 | 36 493 / 36 478 / 38 162 — la couche existe |
| colonne `cassini` des fractions | nue partout, 0 polluée sur 1 525 — ma requête était juste |
| **suffixe des 1 525 atomes-fraction** | **canton 1 525, circo 0** |
| communes à plusieurs circos, par segment | **1986 : 80 ; 2009 : 77 ; 1870-1940 : zéro** |

Les seules villes divisées de la base sont dans les couches que nous avons
posées nous-mêmes.

### Ce que cela signifie, et ce que cela ne signifie pas

Le défaut porte sur **19 à 41 communes** sur 36 000 — négligeable en surface,
massif en population : ce sont Bordeaux, Lyon, Marseille, Lille, Nantes, Le
Havre, Reims. Les circonscriptions urbaines de la Troisième République sont donc
fausses dans notre couche, chaque grande ville étant versée en bloc à l'une
d'elles.

**Aucune recette interne ne pouvait le voir.** La couche est parfaitement
cohérente avec elle-même : couverture qui boucle, zéro chevauchement, zéro
orphelin. C'est exactement le profil de l'Ain — et il avait fallu un œil humain
sur une carte.

### La limite de l'étalon lui-même

La matrice du § 6 dit QUELLES villes étaient divisées ; elle ne dit pas ENTRE
QUELLES circonscriptions. Elle permet donc de **détecter** et de **déclarer**,
pas de corriger. La composition est dans le corps de l'atlas, département par
département — un autre chantier, et bien plus long.

Transcrit à ce jour : **page 784 seulement** (24 villes, d'Aix-en-Provence à
Calais), dans `circo/annexe_vi_villes_divisees.csv`. Les pages 785 et 786 sont
photographiées à 90° et illisibles colonne par colonne ; les transcrire au jugé
fabriquerait un faux étalon, ce que la note d'`annexe_vi.md` met déjà en garde
de faire.

**Légende à ne pas oublier** : une date entre parenthèses signifie une division
à partir de cette date jusqu'à la fin du découpage — `(1902)` en colonne 1889
vaut 1902-1919, et non une annotation.

### La matrice du § 6 transcrite — et la règle de comptage déduite

`circo/annexe_vi_villes_divisees.csv` : **98 villes**, exactement le compte
annoncé. `circo/controle_annexe_vi.py` la confronte à la ligne TOTAL du tableau.

**Le texte ne dit pas si les villes divisées EN COURS de découpage — celles
marquées d'une date entre parenthèses — entrent dans le total. La mesure le
dit.** En comptant tout, 1889 donne 33 pour 22 annoncés ; en ne comptant que
les `X` pleins, elle donne 22 exactement, et 1927 donne 41 exactement.

**Deux colonnes indépendantes, deux concordances exactes : le total ne compte
que les villes divisées dès l'OUVERTURE du découpage.** La règle est déduite,
pas supposée — et elle valide du même coup la transcription des deux colonnes
les plus chargées.

| colonne | X pleins | TOTAL | écart |
|---|---|---|---|
| 1875 | 20 | 19 | +1 |
| **1889** | **22** | **22** | **0** |
| **1927** | **41** | **41** | **0** |

Sept colonnes sur douze retombent exactement, dont deux des trois qui nous
servent.

### Une hypothèse séduisante, délibérément NON appliquée

Quatre colonnes restent en écart. L'une a une explication qui règle tout :
**déplacer le `X` de Brest de 1875 vers 1867** ferait passer 1867 à 14 et 1875 à
19 — les deux valeurs attendues, d'un seul geste.

**Je ne l'ai pas fait.** Ce serait ajuster la transcription sur l'étalon qu'elle
sert à vérifier, et rendre circulaire tout contrôle ultérieur. Une explication
qui résout deux écarts à la fois est *plus* tentante, donc plus dangereuse.
L'hypothèse est écrite dans le script, à trancher sur l'original.

C'est la règle de `METHODE.md` — *ne jamais ajuster sur l'étalon* — et c'est la
première fois de la journée qu'elle coûte quelque chose.

## Remonter de 1876 à 1815 — trois départements reconstruits

`circo/remonte_1815.py`, `sql/64_composition_1815_stage.sql`.

**434 lignes, 14 périodes, 3 départements** (Yonne, Vosges, Haute-Vienne), de
1815 à 1870. Toutes les partitions sont complètes.

### Le principe : deux opérations suffisent

L'atlas décrit chaque découpage PAR DIFFÉRENCE avec un autre — 1852 par rapport
à 1876, 1820 par rapport à 1852, 1831 par rapport à 1815, 1815 par rapport à
1876 — et la chaîne se résout depuis la seule composition que nous ayons.

Toutes les tournures se ramènent à **deux opérations** : `reprend` (une circo
est l'union de circos de référence, plus des cantons) et `deplacer`. « La 3e
perd les cantons A et B au profit de la 2e » et « la 1re gagne les cantons C et
D » sont la MÊME chose : l'origine ne s'écrit pas, elle se calcule dans le
découpage de base. **Ce qu'on n'a pas à saisir, on ne peut pas le saisir faux.**

### La recette : la partition

À chaque période, les cantons doivent former une partition des cantons VIVANTS
du département. C'est un filet contre les fautes de saisie — pas une preuve
d'exactitude : une permutation de deux circonscriptions y passerait au travers.

Elle a attrapé une lacune réelle : **Vosges 1824-1828**, où l'atlas dit ce que
deviennent les 1re, 2e, 4e et 5e circonscriptions de 1831 et ne dit rien de la
3e. Lecture retenue — ce qui n'est pas mentionné ne change pas — signalée sur
les 5 lignes concernées par `interprete = oui`.

### Une erreur de ma part, du même genre que celles de la journée

Je contrôlais la partition contre TOUS les cantons de la nomenclature, laquelle
couvre 1870-2012. Limoges-Est et Limoges-Ouest n'existent pas en 1878 — créés
plus tard — et faisaient échouer les six périodes de la Haute-Vienne pour un
défaut imaginaire. *Le référentiel d'une partition doit être daté comme le
reste.*

### Pourquoi rien n'entre dans `membership`

**La base n'a aucun atome avant 1870** — mesuré : le plus ancien rattachement
s'ouvre au 1er janvier 1870.

Gaudillère garantit qu'aucun CANTON n'a bougé de 1815 à 1870. Mais les COMMUNES
ont bougé, et nous n'avons aucune source : l'INSEE commence en 1943, TRF-GIS en
1870. Poser les rattachements de 1815 sur les atomes de 1870 affirmerait que la
carte communale de 1815 est celle de 1870 — faux d'un nombre inconnu de
communes, et **invisible à toute recette**, comme l'Ain et comme les villes
divisées trouvées le même jour.

On dépose donc la composition CANTONALE, qui est ce que la source dit, et l'on
s'arrête là. Décision d'Adrien, et c'est la méthode de `20` et `58` : mesurer,
noter, écrire plus tard.

**Pour les villes divisées** des départements à venir, la décision est prise :
atome-fraction par circonscription, `cassini#circo`, comme pour les cantons —
avec la même limite, le territoire compté autant de fois qu'il y a de fractions.
Aucun des trois départements traités n'est concerné : la matrice du § 6 ne
connaît ni Auxerre, ni Sens, ni Épinal, et ne divise Limoges qu'en 1958.

## Troisième lecture — le jalon de 1968 passe à 32 552 rattachements

Rappel **91,4 % → 95,3 %**. Jalon en base : 30 955 → **32 552 rattachements**,
2 845 → **2 899 cantons**.

| qualité | 2 lectures | 3 lectures |
|---|---|---|
| `ferme` | 79,9 % | **91,9 %** |
| `lecture_unique` | 16,5 % | 5,1 % |
| `canton_conteste` | 3,1 % | 2,2 % |

**Le gain principal n'est pas le volume, c'est la qualité** : une ligne vue par
une seule passe devient une ligne vue par deux ou trois. Et `58 § 3 bis` le
confirme sur la résolution : `accord` se résout à 99,2 %, `majorite` à 93,5 %,
les lectures uniques à 79 %. *Le vote majoritaire produit une donnée nettement
meilleure qu'une lecture isolée* — ce qui n'allait pas de soi, les trois passes
partageant la même image.

600 dpi reste la plus mauvaise des trois lectures prise seule — 27 064 communes
contre 28 941 pour psm 4 — et c'est elle qui apporte le plus. **En redondance,
la décorrélation prime la performance.**

### Trois ruptures de contrat, toutes du même genre

Le rejeu de la chaîne a cassé trois fois, et jamais sur la logique métier :

1. **`\copy` et l'en-tête.** `WITH (HEADER true)` ne lit PAS l'en-tête pour
   apparier les colonnes : il le saute et se fie à l'ordre de la table. Le CSV
   avait gagné `libelle_canton` et `lectures` ; le message — « extra data after
   last expected column » — ne dit pas laquelle manque.

2. **Les statuts d'accord.** La fusion à trois lectures a remplacé `deux` par
   `accord`, `deux+fraction` par `fraction`, et ajouté `majorite`. Le préalable 3
   de `58` refusait tout. Les anciens noms sont désormais acceptés, et le message
   NOMME les statuts inconnus au lieu de les compter.

3. **`60` change ce que `59` croit devoir faire.** En créant l'unité 5740,
   `60_canton_forbach2` la rend connue de `unit` — donc `58` cesse de la ranger
   parmi les cantons inconnus, donc `59` veut poser ces seize communes que `60`
   occupe déjà, et `membership_non_chevauchant` refuse. **Le piège est
   circulaire et n'apparaît qu'au SECOND rejeu**, quand tout paraît stabilisé.

Corrigé par un garde-fou plutôt que par un ordre d'exécution : *un ordre se
perd, un garde-fou reste.* `59` écarte les atomes déjà rattachés par un tiers,
les compte et les nomme.

**Ces trois ruptures sont la même.** J'ai fait évoluer un format en amont — la
grammaire, puis la fusion, puis la nomenclature — sans propager en aval. Le
contrat entre les fichiers n'était écrit nulle part, donc rien ne signalait sa
rupture avant l'exécution. C'est le pendant, côté chaîne, de ce que la journée a
montré côté mesure : **ce qui n'est pas vérifié quelque part finit par être faux
quelque part.**

### Un affichage trompeur, corrigé

`58` annonçait « 30 622 lignes en conflit » : elles venaient de `59` lui-même au
tour précédent. Il distingue maintenant `poses_par_59_au_tour_precedent` de
`poses_par_un_tiers` — 16, tous Forbach-II. Seul le second chiffre mérite le nom
de conflit, et un chiffre inattendu y signalerait une vraie contradiction entre
sources.

### Forbach-II : la délégation remplace l'ordre d'exécution

Le § 3 bis d'hier écartait ce qui était PHYSIQUEMENT posé. Insuffisant : sur une
base reconstruite, `59` reposait les seize communes lui-même — **sans le
contrôle des 16/16** — et `60` échouait ensuite sur la contrainte. Le résultat
dépendait de l'ordre dans lequel les fichiers avaient été joués.

`59` porte désormais `c68_delegue`, qui déclare *ce canton n'est pas à moi* et
l'écarte quel que soit l'état de la base. `60` vérifie de son côté que la
déclaration existe encore, et refuse de tourner sinon.

    Une délégation n'existe que si les DEUX côtés la connaissent.

Après correction : § 3 bis **vide** — plus aucune collision possible — et la
recette de `59` boucle sur `en_base 16, attendu 16`. Les trois fichiers se
rejouent dans n'importe quel ordre.

**Un ordre d'exécution se perd** : dans une reconstruction, une copie de script,
une reprise après incident. Une déclaration reste dans le fichier, et deux
garde-fous qui se surveillent valent mieux qu'une convention que personne ne
relit.

C'est la même leçon que les trois ruptures de contrat du rejeu, prise par
l'autre bout : ce qui lie deux fichiers doit être écrit dans les deux.

## Les codes orphelins — 121 communes reprises par le nom

`cog1968/codes_orphelins.py`. Rappel **95,3 % → 95,6 %**, jalon 32 552 →
**32 659 rattachements**.

**`corrige_codes.py` ne pouvait pas les voir.** Il part du CODE, cherche son nom
dans la trame, et saute les codes absents (`if not vrai: continue`) — soit
exactement les lignes que `59` refuse sous le motif « commune inconnue ». On
prend donc le problème par l'autre bout : partir du NOM.

**Et la position du chiffre fautif s'inverse** : ici la CENTAINE domine (101 sur
121), là-bas la dizaine (328 sur 749). C'est mécanique et cela valide les deux
outils — une centaine fausse fait SORTIR le code de la trame, donc échappe au
premier script et atterrit dans le second. *Les deux se partagent le champ sans
se recouvrir, et sans que ce partage ait été conçu.*

### La prémisse était fausse d'un facteur six

J'annonçais « 845 communes à récupérer ». Sur 2 267 lignes au code inconnu :

| | |
|---|---|
| nom introuvable — nom ET code fautifs | 1 369 |
| **lignes parasites** — commune déjà lue sous son bon code | **724** |
| récupérables | 121 |
| plusieurs chiffres, nom trop court, collisions | 53 |

Les 724 ne sont pas des communes manquantes. Elles ne polluent pas la base —
leur code étant inconnu, `59` ne les pose pas — mais elles gonflent le CSV.
Marquées `doublon_probable`, pas supprimées.

### 135 lignes où les TROIS lectures s'accordent sur un code faux

C'est la démonstration empirique de la réserve que `fusionne_passes.py` posait
sans pouvoir la prouver : **même image, même moteur, erreurs corrélées**. Un
accord entre les trois passes ne garantit pas la justesse — il garantit que la
segmentation n'était pas en cause, et rien d'autre. Seul le nom l'a révélé.

Le § 4 bis de `58` remonte ce chiffre à chaque exécution.

### Deux garde-fous mis en défaut par une donnée qui n'existait pas encore

**Le mien** : `codes_orphelins.py` vérifiait que la cible n'était pas DÉJÀ lue
dans le département, jamais qu'une AUTRE correction ne la visait aussi. Dix-sept
orphelines corrigées vers la même commune, avec le même canton — doublons
exacts.

**Celui de `59`** : son nettoyage gardait `min(insee)` par atome pour départager
les collisions, ce qui suppose des `insee` DIFFÉRENTS. Face à deux doublons
parfaits il ne triait plus rien. Il déduplique désormais par `ctid`, l'identité
physique de la ligne — seule chose qui distingue deux lignes identiques.

*Un garde-fou est écrit contre les défauts connus au moment où on l'écrit.* Mon
script a créé une classe de données que `59` n'avait jamais eu à traiter, et le
filet a cédé exactement là. C'est la quatrième fois de la journée qu'un amont
modifié invalide un aval, et la seule où l'amont était neuf.

## 1954 — la redondance ne se transpose PAS, et le banc l'a dit en vingt minutes

`cog1954/essai_troisieme_1954.py`, `sql/65_noms_1954.sql`.

**Résultat négatif, et il évite cinq heures d'OCR.** Sur trois départements de
qualité différente, l'union de trois lectures apporte **+114 communes pour +178
de bruit**. Pour 1968, la troisième passe donnait +4 385 communes pour +311
inconnus — un ratio vingt-cinq fois meilleur.

### Pourquoi 1954 n'est pas 1968

Le tableau de 1968 imprime le CODE INSEE. Il donne donc deux informations
indépendantes : le code sert de clé, le nom de contrôle. Une ligne bruitée y
produit un code inexistant, immédiatement détectable — et c'est ce qui a permis
le vote majoritaire puis les 121 codes retrouvés par le nom.

**Le volume de 1954 ne porte que le nom.** Rien n'ancre la lecture, rien ne
filtre le bruit, et chaque lecture supplémentaire ajoute ses fausses lignes à
celles des autres.

### Une hypothèse démentie en chemin

J'attribuais le bruit au référentiel : la trame 2011 ne contient pas les
communes disparues depuis 1954, donc elles compteraient à tort comme fautives.
`65_noms_1954.sql` les a ajoutées — **4 038 noms tirés d'`insee_mvt.libelle_av`**
— et le bruit n'a baissé que de 5 % : 82 → 78 sur l'Ariège, 99 → 97 sur
l'Hérault.

Le référentiel était bien incomplet, et le corriger était juste. Mais il
n'expliquait pas le phénomène. *Une correction nécessaire n'est pas pour autant
la cause.*

### Ce que la mesure désigne à la place

**Près de 40 % de ce que la grammaire de 1954 accepte n'est pas une commune** —
78 bruits pour 127 justes sur l'Ariège, avec la lecture EN SERVICE. Le levier
n'est donc pas la redondance mais le resserrement de la grammaire, exactement
l'inverse de ce qui a marché pour 1968 où c'est l'élargissement qui payait.

### Un chiffre acquis au passage

`cm_commune` donne **38 062 communes vivantes au 10 mai 1954**. L'extraction en
lit 31 400, soit **82 %** — le premier attendu chiffré dont 1954 dispose.

## 1954 — ce n'était pas du bruit, c'était un défaut d'APPARIEMENT

`cog1954/normalise_nom.py`. **83 % des 215 « bruits » sont des communes
réelles**, mal normalisées.

### Trois diagnostics faux avant le bon

1. « Le référentiel est incomplet — la trame 2011 ignore les communes disparues
   depuis 1954. » Vrai, corrigé par `65_noms_1954.sql`, **et sans effet** : le
   bruit passe de 82 à 78 sur l'Ariège. *Une correction nécessaire n'est pas
   pour autant la cause.*

2. « La grammaire de 1954 accepte 40 % de non-communes ; il faut la resserrer. »
   **Faux.** En regardant les lignes une à une : `fAiguillon (L')`, `JArignac`,
   `Puch (Le)`, `St-Lizier` — ce sont toutes de vraies communes.

3. Le vrai défaut est dans la NORMALISATION du nom, en aval de la grammaire et
   en aval de l'OCR. **J'ai pris trois fois un défaut d'appariement pour un
   défaut de lecture.**

### Les quatre motifs, tous tirés de l'observation

| motif | exemple | |
|---|---|---|
| article postposé | `Puch (Le)` → `Le Puch` | `cle()` produisait `puchle` |
| **Saint abrégé** | `St-Lizier` → `Saint-Lizier` | ~10 % des communes françaises |
| caractère parasite en tête | `JArignac`, `fAudressein` | le trait du tableau lu comme lettre |
| combinaison | `ÀSt-Paul-de-Jarrat` | les règles s'appliquent en cascade |

Résultat : 103 retrouvés en correspondance EXACTE, 76 en flou, **36 restants**
qui sont enfin du vrai bruit — `Cellcs`, `Scix`, `Mouiis`, lignes de
nomenclature départementale.

### Un commentaire qui affirmait sans vérifier

`nettoie_nom` conserve l'article postposé, avec ce motif :

> « La remettre à l'endroit serait une interprétation, et la jointure sait déjà
>   traiter l'article. »

**La jointure ne le fait pas.** `cle()` rend `puchle` quand le référentiel porte
`lepuch`. Une propriété affirmée dans un commentaire, jamais éprouvée — et c'est
vraisemblablement une part des 7 576 orphelins de 1954.

Le module ne CHOISIT pas entre les formes : il les propose toutes, du plus sûr
au moins sûr, et laisse le référentiel trancher. *Un module qui trancherait ici
cacherait le doute au lieu de le transmettre.*

### Ce que cela change pour la suite

Le levier de 1954 n'est ni l'OCR ni la grammaire : c'est l'appariement, et il
ne coûte aucun calcul. Reste à porter `variantes()` dans la chaîne — `traite()`,
`controle_1954.py`, et partout où la jointure passe par le nom — puis à
remesurer les 7 576 orphelins.

**Et la fusion à trois lectures redevient une question ouverte** : elle avait
été écartée sur un ratio apport/bruit défavorable, calculé avec un compteur de
bruit largement faux.

### Les 7 576 orphelins de 1954 : 80 % récupérables

`variantes()` appliqué à `non_apparies_1954.csv` (7 609 lignes) :

| | |
|---|---|
| retrouvés en correspondance EXACTE | **2 583** |
| retrouvés en flou (0,85) | 3 514 |
| restants | 1 512 |

**80 %.** Le problème qui traînait depuis l'ouverture du dossier 1954 se règle
très largement par une normalisation de noms — sans un seul appel à tesseract.

### Le garde-fou, vérifié cette fois AVANT d'écrire

Le piège de `codes_orphelins.py` — deux lignes corrigées vers la même cible — a
été mesuré d'emblée : **8 collisions sur 6 097 appariements**, 16 lignes.

Et elles se lisent :

    Savines / Savines                       doublon légitime
    Plouëéc / Piouézec                      deux lectures de Plouézec
    Verdun-sur-Je-Doubs / Verdun-sur-ie-…   idem
    Barneville-sur-Mer -> Bréville          FAUX APPARIEMENT
    Balmelles (Les)    -> Salelles          FAUX APPARIEMENT

**Le flou se trompe**, et les collisions n'en montrent que la partie visible :
deux faux ne se révèlent que parce qu'ils sont tombés sur une cible déjà prise.

Les **2 576 appariements exacts ET uniques** sont sans risque. Les 3 514 flous
demandent un second signal avant d'être posés — le CANTON de la ligne de 1954,
confronté à celui de la commune candidate en 1940 ou 1999, en serait un, et il
est indépendant du nom.

*C'est la leçon des 121 codes orphelins de 1968 : un appariement par
ressemblance n'est sûr que confirmé par une information qui ne doit rien à la
ressemblance.*

### 26 202 codes posés sur 1954

`cog1954/apparie_noms.py --appliquer`. Sur les 31 400 lignes de
`communes_1954_redecoupe.csv` :

| classe | lignes | |
|---|---|---|
| **`ferme`** — exact ET unique | **26 202** | 83,4 %, code posé |
| `flou` — ressemblance 0,85 | 3 531 | proposé dans `insee_propose` |
| `exact_collision` | 40 | deux lignes visent la même commune |
| `aucun` | 1 627 | rien trouvé |

Les 40 collisions sont presque toutes des doublons légitimes — `Vailly-sur-Aisne`
lue deux fois, `Savines` deux fois. Une seule est ambiguë : `Fresnes` contre
`Fresnes-sous-Coucy`. Aucune n'est posée.

**L'unicité est jugée en SECONDE PASSE**, après toutes les propositions. C'est
la faute commise deux heures plus tôt dans `codes_orphelins.py`, où le garde-fou
vérifiait que la cible n'était pas déjà LUE mais jamais qu'une autre proposition
ne la visait aussi. Ici les deux passes sont séparées, et le défaut ne peut plus
se produire.

**Les 3 571 propositions non retenues sont conservées** dans `insee_propose`.
Les perdre obligerait à tout recalculer quand le canton fournira le second
signal.

### Le canton confirme le nom — 1954 atteint 94,1 %

`cog1954/confirme_par_canton.py`. Sur les 3 531 propositions floues :

| | |
|---|---|
| **CONFIRMÉ par le canton** | **3 361** — 97 % des jugeables |
| contredit | 115 |
| commune absente de 1940 | 55 |

État final de `communes_1954_redecoupe.csv` :

    ferme               26 202     appariement exact et unique
    ferme_canton         3 361     flou confirmé par le canton
    aucun                1 627
    canton_contredit       115
    canton_indetermine      55
    exact_collision         40
    ─────────────────────────
    AVEC UN CODE        29 563     94,1 % des 31 400 lignes

### Pourquoi le canton de 1940 et non celui de 1968

Les deux sont à quatorze ans de 1954. Mais Gaudillère établit que la carte
cantonale ne bouge que **trois fois** entre 1940 et 1954 — Sousceyrac, Tende,
Brive-Nord et Sud — quand son annexe VII compte **trente créations** entre 1954
et 1968.

*La proximité qui compte est celle des changements, pas celle des années.*

### Les 115 contredits ne sont pas posés, et c'est délibéré

Plusieurs sont vraisemblablement de bons appariements dont le CANTON est mal lu :

    Fleuriel (Allier)   canton lu 93 — l'Allier n'a pas 93 cantons
    Arricourt (08)      canton lu 23, réel 03
    Contreuve (08)      canton lu 11, réel 31

Le nom est peut-être juste. **Mais on ne confirme pas par un signal qu'on
soupçonne fautif.** Ils restent marqués `canton_contredit`, récupérables si une
troisième source apparaît.

### Le principe, énoncé une bonne fois

**Un appariement par ressemblance n'est sûr que confirmé par une information qui
ne doit rien à la ressemblance.**

C'est ce qui a validé les 121 codes orphelins de 1968 — le test « doublon
présent / proposé absent » — et c'est ce que fait ici le canton : le nom vient
d'une colonne, le canton d'une autre, deux chiffres lus à deux endroits
différents de la même ligne.

---

## 28 août 2026 — le second jalon : 1954 est en base

### Ce qui est posé

**29 472 rattachements cantonaux au 1er janvier 1954**, sur
`[1954-01-01, 1955-01-01)` et sur cette année seule — 29 461 par
`68_cog1954_membership.sql`, 11 par `67_cantons_1949_1951.sql`.
**2 903 cantons** peuplés.

| qualité | n | |
|---|---|---|
| `ferme` | 26 068 | 88,5 % — nom exact et unique |
| `nom_flou_confirme` | 3 351 | 11,4 % — ressemblance confirmée par le canton |
| `atome_ambigu` | 42 | 0,1 % — le code résout à plusieurs atomes |

Le trou 1943-1999 a maintenant **deux points au lieu d'un** :

    1954    29 472 atomes    2 903 cantons
    1968    32 659 atomes    2 899 cantons

Perdu au chargement : **83 lignes** sur un canton absent de la nomenclature,
**3** sans atome. Sur 29 563 lignes portant un code, c'est 0,3 %.

### 94,2 % d'accord entre deux lectures qui ne se doivent rien

Le § 6 de `66` compare, commune par commune, le canton lu en 1954 et celui lu en
1968 : **23 911 accords sur 25 370 comparables**. Deux fascicules différents,
deux chaînes OCR, deux méthodes d'appariement — l'une par le code imprimé,
l'autre par le nom reconstruit.

**Ce n'est pas une preuve d'exactitude.** Deux OCR peuvent buter sur la même
typographie, et les deux lectures partagent le même référentiel de communes. Ce
que le chiffre établit, c'est une cohérence *indépendante*, et c'est le seul
contrôle dont cette période dispose. *La cohérence n'est pas l'exactitude* —
règle déjà écrite pour la couche 1870-1940, valable ici sans changement.

La dispersion importe plus que la moyenne : Territoire de Belfort 67,9 % sur
78 communes, Moselle 86,5 %, Pas-de-Calais 89,8 %, Nord 91,4 %. Ces trois
derniers sont des départements que le dépouillement de 1968 lit mal. **Le
désaccord ne dit pas laquelle des deux lectures a tort**, et traiter 1968 comme
l'étalon serait une faute : les deux sont des lectures OCR de qualité comparable.

### Le contrôle qui manquait, et ce qu'il a trouvé

`apparie_noms.py` juge l'unicité de ses cibles en seconde passe — mais seulement
parmi ses propres appariements exacts. `confirme_par_canton.py` a ensuite posé
3 361 codes **sans vérifier qu'aucun ne visait une commune déjà prise**. Ce
contrôle n'avait jamais été fait ; le § 3 bis de `68` le fait.

**Trois collisions sur 29 424 lignes.** Deux sont des doublons de lecture
inoffensifs — `Équeurdreville` / `Équeurreville`, `Pommers` / `Pommier`. La
troisième est un vrai faux appariement :

    21268   « Flagey-lès-Auxonne » (ferme)  |  « Magny-lès-Auxonne » (ferme_canton)

Ce sont **deux communes distinctes** de Côte-d'Or, toutes deux réelles, toutes
deux au canton d'Auxonne. 21268 est bien Flagey ; Magny-lès-Auxonne — disparue
depuis par fusion avec Montarlot — a reçu le code de sa voisine par
ressemblance. Le canton, ici, ne pouvait pas jouer son rôle de second signal :
*il est le même pour les deux*.

**Le dégât est une perte, pas un faux.** Le rattachement posé (atome de Flagey
au canton 2103) est juste quelle que soit la ligne retenue ; c'est
Magny-lès-Auxonne qui manque au jalon.

*Un signal indépendant du nom ne discrimine que là où il varie.* Le canton
confirme excellemment entre communes éloignées et ne dit rien entre voisines —
qui sont précisément les plus ressemblantes de nom. La limite était prévisible ;
elle n'avait pas été énoncée.

Trois collisions sur 29 424, c'est **0,01 %** : la seconde passe reste très
largement bonne. Mais le taux vrai est plus élevé qu'affiché, puisque seules les
collisions se voient — un faux qui tombe sur une commune libre passe inaperçu.

### Quatre communes lues à deux cantons — fractions ou doublons ?

    11286   Peyriac-Minervois   | Peyrinc-Minervois       1115, 1125
    17385   St-Pierre-d'Oléron  | St-Pierrc-d'Oléron      1718, 1731
    42204   St-Bonnet-le-Château| St-Bonnet-le-Chôteau    4206, 4217
    70421   Port-sur-Saône      | Port-sur-Suône          7010, 7020

Elles ont reçu **8 atomes-fraction**, mécanisme de `24` § 4. Deux lectures sont
possibles et je ne tranche pas : soit ce sont de vraies communes
multicantonales — 1968 en compte 275 —, soit ce sont des doublons de lecture que
l'écart des cantons empêche de reconnaître comme tels. **Les quatre sont des
chefs-lieux de canton**, ce qui rend le partage plausible ; mais deux numéros
distants de dix dans le même département le rend moins évident.

À vérifier sur pièces. En attendant, ces huit fractions sont marquées et
comptées, pas cachées.

### Trois pièges de PostgreSQL, dans le même fichier

1. **`NULL` nu, `SELECT` contre `VALUES`.** Dans `INSERT … VALUES`, un `NULL`
   prend le type de la colonne visée ; dans `INSERT … SELECT`, il est typé
   `text`. `60` écrit les deux mêmes NULL et passe ; `67` échouait sur
   « segment_depuis is of type smallint ».
2. **`count(DISTINCT …) OVER (…)` n'existe pas.** La fenêtre ne sait pas
   dédupliquer. Agréger d'abord, rejoindre ensuite.
3. **`dep char(2)` trop court pour `78O`.** La Seine-et-Oise porte un code de
   trois caractères. Cf. ci-dessous.

### La Seine-et-Oise : 576 lignes perdues en silence

`apparie_noms.py` cherche le nom **dans le département lu**. `78O` n'existant
dans aucun référentiel, la branche `if dep not in ref` a classé ses 576 lignes
en `aucun` sans même essayer — **un tiers des 1 627 sans piste**.

Le département a été éclaté en 1968 entre les Yvelines, l'Essonne, les
Hauts-de-Seine, la Seine-Saint-Denis, le Val-de-Marne et le Val-d'Oise. Ses
communes existent toutes ; il suffit de les chercher dans les six successeurs.
Ce sera `69`.

*Un code qui ne correspond à rien ne produit pas d'erreur, il produit un vide.*

### « Invisibles » était faux — les trois cantons de 67 existaient déjà

`67` a posé ses onze rattachements et créé **zéro unité** : `INSERT 0 0`. Les
trois `unit_id` venaient de `24_canton_moderne.sql`, depuis le COG de 1999. Ils
ne sont invisibles qu'à TRF-GIS, qui s'arrête en 1940. Le § 4a de `66` le disait
déjà en ne les listant pas parmi les cantons inconnus — j'ai lu ce résultat
comme une confirmation au lieu d'une contradiction.

Réutiliser le numéro **affirme une identité**. Le § 2 bis de `68` la contrôle :

| canton | atomes 1954 | atomes 1999 | communs | |
|---|---|---|---|---|
| 4630 Sousceyrac | 4 | 5 | **4** | identité établie |
| 1930 Brive | 7 | 2 | **1** | **douteuse** |
| 0631 Tende | 0 | 2 | 0 | sans objet |

**Sousceyrac est acquis** : même nom, quatre communes sur quatre retrouvées,
une ajoutée en 45 ans.

**Brive ne l'est pas.** Le canton de 1999 s'appelle
« Brive-la-Gaillarde-Sud-Est », pas « Brive-Sud », et ne partage qu'**une
commune sur sept** avec celui de 1951. Deux lectures, que rien ne départage
ici : soit le canton a été redécoupé entre 1951 et 1999 — Brive a grossi —,
soit le numéro `1930` a été **réattribué**, et le chargement a fusionné deux
unités distinctes. C'est le piège des codes de canton réutilisés, déjà rencontré
dans TRF-GIS en 1871. Le registre cantonal consolidé tranchera s'il porte un
démembrement de Brive-Sud.

**Tende est un cas sain** : zéro atome parce que Tende et La Brigue n'en ont pas
du tout — françaises depuis le traité de Paris de 1947, absentes d'une trame qui
part de 1870. Le canton existe et il est vide, ce qui est exact.

### Le prix de la borne élargie : une commune

Le recensement observe le **10 mai** ; le jalon part du **1er janvier**, pour ne
pas couper l'année en deux morceaux disjoints avec `67`. Le § 7 mesure ce que
cet élargissement de quatre mois coûte : **une seule commune** posée n'existait
pas encore au 1er janvier 1954. La question était légitime, la réponse la rend
théorique.

### Les deux départements disparus — 28 août 2026, même journée

**+563 rattachements. Le jalon de 1954 passe de 29 472 à 30 035 atomes**, sur
2 946 cantons. Le dépouillement passe de 94,1 % à **95,9 %** des 31 400 lignes.

    ferme                26 668     84,9 %
    ferme_canton          3 460     11,0 %
    aucun                 1 066      3,4 %   (contre 1 627)

#### Le premier défaut : un code qui ne correspond à rien

`apparie_noms.py` cherche le nom **dans le département lu**. La Seine-et-Oise
porte `78O` sur trois caractères ; aucun référentiel ne le connaît ; la branche
`if dep not in ref` a classé ses **576 lignes en `aucun` sans même essayer** —
un tiers de tous les sans-piste, perdu d'un seul tenant et sans un message.

*Un code qui ne correspond à rien ne produit pas d'erreur, il produit un vide.*

#### Le second défaut, qui aurait été bien pire

La correction évidente — chercher dans les six départements successeurs —
donnait 549 codes sur 576, sans collision, avec le canton confirmant 98 % des
exacts. Tout paraissait bon. **Aucun de ces 549 codes n'aurait produit un seul
rattachement.**

    codes 78xxx vivants au 10 mai 1954 ......... 691
    codes 91, 92, 93, 94, 95 vivants en 1954 ..... 0

`cm_commune` modélise correctement l'éclatement de 1968 : en 1954 ces communes
portent la numérotation d'époque. `c54_lien` aurait posé
`commune_vivante = false` sur les 549 lignes et `68` n'aurait rien écrit — après
quoi j'aurais cherché la cause dans l'OCR.

Ce qui m'avait trompé : le vivier tiré de `build/membership_canton.csv` compte
lui aussi **691** communes, mais TRF-GIS les code en MODERNE quand `cm_commune`
les code en 1954. *Deux ensembles de même effectif décrits par deux
numérotations différentes — j'ai pris la coïncidence des comptes pour une
identité des clés.*

#### Le pont : l'atome, et il se contrôle tout seul

`sql/69_pont_seine_et_oise.sql` construit `code_1954 → atome → code_moderne`.
L'atome ne change pas quand l'INSEE renumérote : c'est la raison d'être du
modèle, et la traduction ne suppose rien.

**Le contrôle ne doit rien au pont.** Les successeurs des deux départements sont
un fait historique ; le pont les reconstitue :

| département | de la Seine | de la Seine-et-Oise | total | effectif réel |
|---|---|---|---|---|
| Hauts-de-Seine | 27 | 9 | 36 | **36** |
| Seine-Saint-Denis | 24 | 16 | 40 | **40** |
| Val-de-Marne | 29 | 18 | 47 | **47** |

Zéro ambiguïté, six communes sans code moderne sur 691. Et le canton confirme
**98,0 % des appariements exacts**, exactement comme avant la traduction : si le
pont avait été faux, ce taux se serait effondré.

Le pont règle en outre un problème sans autre issue : sur les 691 codes de 1954,
**seuls 454 portent un nom** dans `noms_1954.csv`. Les 237 autres ne sont jamais
nommés par les mouvements INSEE — mais leur descendance moderne l'est. La cible
est le code de 1954, atteinte par tous les noms connus de la commune : celui
d'époque quand il existe, celui d'aujourd'hui sinon. C'est ce qui rattrape
« Évry-Petit-Bourg », « Tremblay-lès-Gonesse », « Auteuil-le-Roi ».

#### Un signal absent n'est pas un signal contraire

Cinq communes du vivier n'ont **aucun** canton en 1940. Mon premier jet traitait
l'ensemble vide comme un désaccord et rejetait « Thionville-sur-Opion » →
*Thionville-sur-Opton*, que rien ne dément. `confirme_par_canton.py` faisait
déjà la distinction — « commune absente de 1940 » y est indéterminé, pas
contredit — et je ne l'avais pas reprise.

#### La reprise par le canton, essayée et REFUSÉE

Pour les 15 lignes restantes, j'ai mesuré une troisième passe : restreindre au
canton lu, puis prendre le nom le plus proche. Elle donne **15 bons et 1 faux**,
soit 6 % d'erreur sur une chaîne qui est à 0,01 % ailleurs.

Le cas qui la disqualifie est Butry-sur-Oise, dont le nom est lu parfaitement
mais dont la bonne réponse est absente du vivier : elle sort alors
Auvers-sur-Oise à 0,75 avec une marge confortable. **Quand la vraie cible manque,
« le plus proche du canton » en fabrique toujours une.** Quinze lignes ne valent
pas ce prix ; elles sont listées, nommables une à une, et attendent.

#### Ce que la Seine-et-Oise a révélé du § 6

La comparaison 1954/1968 joignait sur `insee`. Elle marchait pour 88
départements et **excluait silencieusement les deux départements disparus** :
1968 les code en moderne, 1954 en numérotation d'époque. La jointure passe
désormais par l'ATOME, qui est le même aux deux dates. Le chiffre de 94,2 % sur
25 370 communes était donc calculé sur un corpus amputé.

#### La mesure qui ignore les étiquettes — et l'échelle qui lui manquait

Le § 6 ter compare des **partitions** : pour chaque paire de communes lues aux
deux dates, sont-elles dans un même canton en 1954, et le sont-elles encore en
1968 ? La question ne dépend d'aucune nomenclature — c'est une propriété du
découpage, pas de son étiquetage — et c'est la seule voie ouverte pour deux
départements dont les identifiants de canton sont incomparables.

**Premier jet : je ne l'ai calculée que pour eux.** 46,4 % et 10,0 %, et je
proposais de les lire contre les 93 % du § 6. *Une part de paires conservées et
une part de communes au même canton ne vivent pas sur la même échelle*, et rien
ne disait qu'un découpage inchangé donnerait 93 % sur la première. J'avais
fabriqué un écart en confrontant deux grandeurs qui ne se confrontent pas —
exactement le défaut du 0,0 % que je venais de dénoncer, sous une autre forme.

Calculée pour les 90 départements, elle devient lisible :

    FRANCE                        89,8 %      147 976 paires
    ────────────────────────────────────
    75   Seine                    10,0 %
    78O  Seine-et-Oise            46,4 %
    90   Belfort                  69,5 %      ← le plus bas des 88 autres
    20   Corse                    74,9 %
    59   Nord                     82,8 %

**Le verdict est net.** Les deux départements disparus ne sont pas au bas d'une
distribution : ils en sont hors. Le suivant est à 69,5 %, et l'écart entre 46,4
et 69,5 est plus grand que celui entre 69,5 et la France entière. La Seine à
10 % signifie une recantonisation quasi totale.

**C'est un fait historique retrouvé, pas un défaut de lecture** : l'éclatement de
1968 a redécoupé les cantons de la région parisienne en même temps qu'il
renumérotait les départements. Nos deux lectures ne se contredisent pas — elles
décrivent deux cartes différentes.

Les douze départements les plus bas sur cette mesure sont pour l'essentiel les
mêmes que sur celle du § 6 (90, 20, 57, 37, 62, 59, 33, 16, 41, 66). Les deux
mesures descendent ensemble, ce qui est rassurant : **aucun département ne
montre la signature « renuméroté mais non redécoupé »**, qui serait un accord
élevé des partitions avec un désaccord des étiquettes. Là où les deux jalons
divergent, c'est le territoire qui a bougé.

#### Le § 6 national, corrigé deux fois

    94,2 %   25 370 communes   jointure par le code — corpus amputé
    93,0 %   25 664 communes   jointure par l'atome, deux départements incomparables inclus
    94,5 %   25 258 communes   jointure par l'atome, ces deux départements écartés

La baisse à 93,0 % mesurait mon défaut, pas la stabilité cantonale.

### 1815-1870 : sept départements de plus — 28 août 2026

`circo/remonte_1815.py` passe de **3 à 10 départements**, de 14 à 46 périodes,
de 434 à **1 359 lignes** dans `circo/composition_1815_1870.csv`.

    74 Haute-Savoie      1 période    (française depuis 1860 seulement)
    77 Seine-et-Marne    5
    79 Deux-Sèvres       5
    81 Tarn              6
    82 Tarn-et-Garonne   4
    86 Vienne            6
    84 Vaucluse          5   — partition rompue, cf. ci-dessous

**Trente-deux périodes nouvelles, trente et une partitions complètes.** Le
filet a tenu : chaque canton dans une circonscription et une seule, aucun
oublié, aucun nom hors nomenclature. La transcription a demandé de rétablir les
noms de l'atlas en noms de la nomenclature — « Lavaure » pour Lavaur,
« Caladen » pour Cadalen, « Mauzerte » pour Lauzerte, « Lecnloitre » pour
Lencloître, « Saint-Nicolas » pour Saint-Nicolas-de-la-Grave.

#### Le Vaucluse échoue, et le défaut n'est pas dans la transcription

`Avignon-Sud` n'a **aucune circonscription en 1876**. Son unique atome est
`2184#8403`, une FRACTION cantonale de la commune d'Avignon, que la couche circo
n'a jamais rattachée. Avignon-Nord perd de même son atome-fraction `2184#8402`.

C'est le défaut connu des 291 atomes résiduels, dont 290 fractions — et c'est
aussi, exactement, l'affaire des **villes divisées** : Avignon est partagée
entre cantons, et la couche circo ne sait pas la traiter.

*La reconstruction de 1815 audite la couche dont elle dépend.* Le Vaucluse ne
sera posable qu'une fois ce trou comblé ; les cinq périodes sont écrites et
attendent.

#### Deux règles transcrites littéralement et signalées

**Tarn, 1820-1831.** L'atlas écrit « par rapport à 1852 » mais cite les 2e, 3e
et 5e circonscriptions — 1852 n'en a que trois. La base ne peut être que 1831,
qui en a cinq. Retenu, et signalé.

**Vaucluse, 1820-1831.** Telle qu'écrite, la règle ne change RIEN : Avignon-Nord
et Bédarrides sont déjà dans la 1re en 1869, et Pernes, Mormoiron et Sault n'y
sont pas. Transcrite littéralement — la base visée est peut-être 1852.

#### Cinq départements NON transcrits, et pourquoi

Aucun n'est bloqué par la chaîne : ce sont des questions sur la source.

**80 Somme** — « cantons de Sains et Conty » (1869-1870). Il n'existe pas de
canton de Sains dans la Somme. Et « canton d'Ailly » est ambigu : Ailly-le-Haut-
Clocher ou Ailly-sur-Noye, les deux existent.

**76 Seine-Maritime** — 1831-1848 : « 1re, 2e et 3e circonscription : cantons de
Rouen ». Six cantons pour trois circonscriptions, sans dire lesquels vont où.
Non encodable en l'état.

**78 Seine-et-Oise** — 1831-1848 : la 1re prend Versailles-Nord, Ouest et Sud,
et la 2e « la circonscription de Versailles-1 » — qui contient déjà ces trois
cantons dans le découpage de 1876. Les deux règles se contredisent.

**83 Var** — l'arrondissement de Grasse passe aux Alpes-Maritimes en 1860. Les
cantons de Grasse, Cannes, Antibes, Vence, Coursegoules, Le Bar-sur-Loup,
Saint-Auban et Saint-Vallier-de-Thiey sont cités pour les périodes anciennes
mais ne sont plus dans le Var de 1876. **L'univers des cantons change en cours
de période**, et le script en suppose un seul. Plus la fusion Solliès-Pont /
Cuers avant 1831.

**85 Vendée** — « 1831-1869 » chevauche « 1852-1869 » : lire 1831-1848 ? Et le
redécoupage porté par la loi du 21 juillet 1824 (Mothe-Achard,
Moutiers-les-Mauxfaits, Sainte-Hermine) suppose une trame cantonale antérieure
à 1870, que la base n'a pas.

#### Les quatre départements bloqués sont levés — même jour

Adrien tranche les quatre questions : le canton de **Sains** existe bien, il
s'agit d'**Ailly-le-Haut-Clocher** pour la Somme, les six cantons de Rouen se
répartissent **deux par deux** entre les 1re, 2e et 3e circonscriptions, la
Seine-et-Oise de 1831 se lit **par rapport à 1876**, et la Vendée « 1831-1869 »
doit se lire **1831-1848**.

Total : **10 → 14 départements, 67 périodes, 2 183 lignes.**
(le Var reste seul de côté — voir plus bas.)

**Sains, et ce que la partition en dit.** La nomenclature 1870-2012 ne connaît
aucun canton de Sains dans la Somme ; le *Dictionnaire historique et
archéologique de la Picardie* (1909) range Sains-en-Amiénois dans le **canton de
Boves**. Le chef-lieu a donc été transféré entre 1869 et 1870, et TRF-GIS ne
connaît que le nom d'après. Lu ainsi, **les sept périodes de la Somme donnent
une partition complète** — Boves était le seul canton de l'arrondissement
d'Amiens que le découpage laissait sans emploi. Ce n'est pas une preuve, c'est
une concordance ; elle est signalée comme interprétation.

**Ce que la reconstruction découvre dans la couche de 1876.** Trois villes
apparaissent, chacune par le même symptôme :

    Avignon      atome 2184    fractions 2184#8402, 2184#8403
    Le Havre     atome 16833   fractions 16833#7627, #7628, #7629
    Rouen        atome 29752   fractions 29752#7642 … #7647

**Aucune de ces fractions cantonales n'a de circonscription en 1876.** Les
cantons qui n'ont QUE des fractions — Avignon-Sud, Le Havre-Sud — sont donc
invisibles à la couche circo, et cassaient les partitions.

C'est le défaut connu des 291 atomes résiduels, mais vu d'un autre angle : *la
reconstruction de 1815 audite la couche dont elle dépend*, ville par ville, et
elle nomme les villes.

Le Havre-Sud est rattaché sur la foi de la BASE, non de l'atlas : ses deux
cantons frères, Le Havre-Nord et Le Havre-Est, sont dans la circonscription
Le Havre-1. Avignon-Sud ne peut pas l'être — l'atlas met Avignon-Nord et
Avignon-Sud dans des circonscriptions différentes, et rien ne dit laquelle pour
la seconde. Ses périodes calculées par différence sont donc justes ; ses deux
périodes « identique à 1876 » héritent du trou et restent rompues. **Deux
partitions rompues sur soixante-sept.**

**Un correctif de fond au passage.** Le « reste » d'une période portait sur les
cantons du découpage de BASE, et non sur les cantons vivants à la date. Le trou
de 1876 se serait donc propagé à toutes les périodes reconstruites. *Le
référentiel d'une partition doit être les cantons vivants, pas ceux que la
couche de départ a bien voulu couvrir* — c'est le même principe que le correctif
Limoges-Est/Ouest, poussé d'un cran.

**Deux lectures « par rapport à » corrigées de la même façon.** Le Tarn
1820-1831 dit « par rapport à 1852 » et la Vendée 1820-1831 « par rapport à
1869 », mais tous deux citent des 5e circonscriptions que ces découpages n'ont
pas. Dans les deux cas la base ne peut être que **1831**, qui en a cinq.
Signalé, non corrigé en silence.

**Le Var reste seul de côté**, et pour une raison de fond : l'arrondissement de
Grasse passe aux Alpes-Maritimes en 1860. Huit cantons — Grasse, Cannes,
Antibes, Vence, Coursegoules, Le Bar-sur-Loup, Saint-Auban,
Saint-Vallier-de-Thiey — appartiennent au Var d'avant 1860 et à un autre
département après. **L'univers des cantons change en cours de série**, et le
script en suppose un par département. Plus la fusion Solliès-Pont / Cuers avant
1831, qui demande une trame cantonale antérieure à 1870.

## 28 août 2026 — le report est une méthode, et on sait ce qu'il coûte

Question posée : que manque-t-il pour étendre la couche cantonale de 1940 à
1999 ? Réponse construite en deux fichiers, `70` et `71`, tous deux en lecture
seule.

### Le banc : 1940 → 1954, le seul intervalle bien documenté

Le trou 1943-1999 a deux jalons bornés chacun à une année. Les étendre suppose
de REPORTER une composition, c'est-à-dire d'affirmer *rien d'autre n'est
arrivé*. Cette affirmation n'est certifiable nulle part : sur 2 024 mouvements
du registre, **785 ne sont pas datés**, dont 274 transferts isolés que l'annexe
VII ne couvre pas par construction.

**1940 → 1954 est le seul intervalle où l'on ait les deux bouts ET une liste
d'actes réputée complète** — trois créations seulement, établies par trois voies
indépendantes. *On teste la méthode là où elle a le plus de chances de marcher :
un échec y serait décisif, un succès n'y prouve que le cas facile.*

### Le piège de circularité, réglé avant de mesurer

`confirme_par_canton.py` a posé 3 460 codes **en retenant les lignes dont le
canton de 1954 concordait avec celui de 1940**. Les inclure aurait fait mesurer
au banc sa propre entrée. Seule la classe `ferme` — appariée sur le nom seul —
est indépendante : **3 450 rattachements écartés, 26 544 retenus.**

### Le résultat

| | |
|---|---|
| accord par commune, brut | **98,78 %** |
| accord purgé des lectures absurdes | **99,50 %** |
| paires conservées 1940 → 1954 | **97,87 %** |
| *témoin* 1954 → 1968 (66 § 6 ter) | *89,80 %* |

Trois créations en quatorze ans coûtent 2,1 % des paires ; trente créations en
quatorze ans en coûtent 10,2 %. **La divergence est portée par les créations
datées**, presque proportionnellement — pas par un bruit de fond ingérable.

### La géométrie tranche : 59 % des désaccords sont des lectures fausses

`71` mesure la distance de chaque commune en désaccord à son canton d'arrivée,
la commune elle-même retirée de l'union pour que la distance ne soit pas nulle
par construction.

    191 / 323   canton d'arrivée à plus de 5 km   -> lecture fausse
     33 / 323   entre 0 et 5 km                   -> indécis
     89 / 323   contigu                           -> transfert crédible
     10 / 323   sans géométrie

Nesle → Rue : 96 km. Saint-Hilaire-du-Harcouët → Montebourg : 93 km. Le Croisic
→ Moisdon-la-Rivière : 78 km. *Une commune ne traverse pas son département pour
changer de canton.*

### L'échange croisé — une signature que la distance ne voit pas

Parmi les 89 contigus, un motif inattendu :

    1417 Falaise-Nord  <-> 1418 Falaise-Sud    2 dans un sens, 4 dans l'autre
    3612 Issoudun-Nord <-> 3613 Issoudun-Sud   1 et 4
    2130 Saint-Seine   <-> 2136 Venarey        1 et 1

**Un redécoupage déplace une frontière : les communes vont toutes dans le même
sens.** Un échange croisé est la signature d'une confusion entre deux cantons
voisins — et deux des trois paires sont les deux moitiés Nord/Sud d'un même
chef-lieu, dont les numéros ne diffèrent que d'une unité.

La distance ne peut pas voir ce cas : les deux cantons sont contigus, donc
chaque ligne prise isolément est plausible. **C'est la structure de l'ensemble
qui la dément, pas la géométrie de chaque élément.** 13 lignes de plus écartées.

### Le chiffre qui répond à la question

**76 transferts non datés probables sur 26 544 communes en quatorze ans —
0,29 %.** C'est une borne HAUTE des vrais transferts : une lecture fausse qui
tombe par chance sur un canton voisin y est indiscernable d'un vrai transfert.

Rapporté à 1968 → 1999, trente et un ans, cela ferait de l'ordre de 0,6 % —
quand les créations, elles, coûtent 10 % sur quatorze ans.

**Conclusion : l'obstacle à l'extension 1940-1999 est DOCUMENTAIRE, pas
méthodologique.** Le report est une méthode utilisable dès que la liste des
actes de l'intervalle est complète. Ce qui manque :

1. le texte de ~400 décrets des années 1970-80 — Légifrance n'a été moissonné
   que pour 1973, 1982 et 1984 (136 décrets repérés, 91 dépouillés) ;
2. toute liste d'actes pour **1990-1995** — l'annexe VII s'arrête en 1989 et le
   COG 1999 ne remonte qu'à avril 1995 ;
3. la datation des 785 mouvements sans date, dont les 274 transferts isolés —
   mais on sait maintenant qu'ils coûtent 0,3 % par quinze ans, pas davantage.

---

## 28 août 2026 — le moissonnage Légifrance : 207 décrets de plus, et la lacune 1990-1995 tombe

La liste d'actes n'était moissonnée que pour 1973, 1982 et 1984. Elle l'est
maintenant pour tout le fonds JORF : **343 décrets de découpage cantonal,
1958-1999, dont 207 nouveaux.** Détail dans `cantons/note_moisson_legifrance.md`,
fichier `cantons/decrets_cantonaux.csv`, reproduction par
`cantons/build_moisson.py` sur `cantons/moisson_brute.txt`.

### Ce qui a rendu la chose facile, et qu'il faut retenir

Le moissonnage précédent interrogeait Légifrance **par date de signature** — ce
qui suppose de connaître les dates, donc de dépendre de l'annexe VII pour savoir
où chercher. La recherche **par titre**, sans borne de date, ne suppose rien :
871 titres pour tout le fonds, de 1937 à 2026. Le coût est de neuf pages de
résultats.

C'est le même renversement que pour 1954 : le levier n'était pas dans la qualité
de la lecture, il était dans le choix de la clé d'entrée.

### Le contrôle de rappel

Les 136 décrets déjà repérés sont **tous les 136** dans les 871 titres. L'étalon
est un dénombrement antérieur et indépendant, et il est retrouvé sans exception.
Le moissonnage par date ne trouvait donc rien que celui-ci ne trouve.

Le contrôle a aussi rattrapé un défaut de filtre, une fois de plus : le premier
tri perdait le décret n° 82-35 (Pas-de-Calais), parce que le motif d'exclusion du
bruit vinicole `/VINS?\b/` mordait sur le canton de **LIÉVIN**. Un sur 343. Sans
l'étalon, il partait sans bruit — c'est exactement le mode de défaillance contre
lequel la règle du dépôt existe. Le décret est réinjecté nommément dans le
script, avec son commentaire ; les six autres textes écartés y sont nommés aussi.

### Le résultat qui change le plan

`RESTE_A_FAIRE.md` tenait 1990-1995 pour une lacune documentaire : l'annexe VII
s'arrête en 1989, le COG 1999 ne remonte qu'à avril 1995. **49 décrets sont datés
entre 1990 et 1995, 83 entre 1990 et 1999 — et Légifrance en conserve le texte
intégral.** Pas de PDF, pas de CAPTCHA, pas d'OCR. Vérifié en clair sur le
n° 91-218 (Seine-Maritime), qui est le décret du renumérotage du Havre déjà
connu par ailleurs.

La lacune n'est plus documentaire, elle est à dépouiller.
`composition_decrets.py` sait déjà lire cette prose.

### Ce qui reste derrière le CAPTCHA

124 décrets nouveaux antérieurs à 1990, répartis sur **58 numéros du JO** à
récupérer en version papier numérisée (un par date de publication, pas un par
décret ; trois sont déjà sur disque). Le plus rentable est le JO du 22 juillet
1967 : six décrets d'un coup, ceux qui découpent en cantons les départements nés
de l'éclatement de la Seine et de la Seine-et-Oise. Acte fondateur de toute la
couronne parisienne, et il manquait.

### Ce que la confrontation au registre apprend

162 des 192 couples (département, date) datés au registre ont un décret à la même
date de signature. Mais **93 décrets n'ont aucune décision au registre** sur
1945-1989 : l'annexe VII sous-compte, et par blocs entiers — les six décrets du
20 juillet 1967, les quatre du 18 août 1973, la quasi-totalité de 1986-1989.

Dans l'autre sens, 21 couples du registre restent sans décret. Un au moins est un
artefact de nomenclature et non une lacune : le 18 août 1973 le registre inscrit
2A et 2B, le décret n° 73-825 dit « CORSE » — la partition est de 1976. Les
autres sont ouverts, et deux lectures restent possibles (le registre daterait par
la prise d'effet, le décret par la signature ; ou bien le fonds JORF est
clairsemé avant 1970). On ne tranche pas.

**Ce fichier ne pose rien en base.** C'est une liste d'actes, avec département et
objet déduits du titre — une lecture de titre, pas une lecture d'acte.

---

## 28 août 2026, soir — les JO sont arrivés : 1 208 cantons dépouillés, et deux fautes rattrapées par la source

89 PDF de JO déposés dans `JORF/`. Détail dans `cantons/note_composition_jo.md`,
fichiers `cantons/composition_jo.csv` et `cantons/controle_composition_jo.csv`,
script `cantons/composition_jo.py`.

**194 décrets, 1 208 cantons, 4 706 lignes, 3 461 communes rattachées.**

### Deux bonnes surprises techniques

**Les PDF portaient déjà une couche texte**, de bien meilleure qualité que les
fascicules du COG 1968. Aucun OCR. Le seul travail a été de lire `*_raw.txt`
plutôt que `*.txt` : `pdftotext -layout` entrelace les deux colonnes du JO sur
la même ligne et fabrique des listes de communes qui n'ont jamais existé.

**Il fallait un second extracteur, pas une adaptation.**
`composition_decrets.py` part de `communes_coupees_1973_1984.csv`, donc des
seuls segments retenus parce qu'ils portaient une commune coupée. Un canton sans
commune coupée — la grande majorité — n'y entre jamais. En repartant du texte du
JO on passe de 1 295 à 4 706 lignes.

### Le contrôle par le COG 1999

415 accords, 99 accords partiels, **5 désaccords**. Sur les 519 cantons
jugeables, 3 344 communes sur 3 635 dans le même canton en 1999 — **92,0 %**.
L'étalon précédent valait 155 / 24 / 0 sur un corpus 2,5 fois plus petit.

Les cinq désaccords sont Échirolles, Trappes, Valdoie, Évry, Montgeron : les
banlieues qui ont le plus grossi, donc celles qui ont été redécoupées entre le
décret et 1999. C'est ce que la mise en garde du contrôle prévoit.

### Le contrôle croisé, qui vaut plus que le précédent

Les deux extractions n'ont ni le même point d'entrée ni le même découpage. Là où
elles traitent le même canton — 283 cas — **277 listes sont identiques, 6 sont
des lectures plus complètes de la nouvelle, et zéro diverge.**

Deux cantons ne sont connus que de l'ancienne, et c'est là qu'il faut regarder :
Poitiers-III, et **Évreux-Ouest**, sur lequel l'ancienne a raison contre la
nouvelle. Un contrôle qui ne rend jamais l'ancienne gagnante ne contrôle rien.

### L'attribution : le vote mesurait la nomenclature, pas le décret

Le JO ne dit pas, canton par canton, de quel décret il relève. La première
version le déduisait par un vote sur les communes reconnues. Sur le JO du
22 juillet 1967 elle a donné **568 lignes sur 651 au seul décret des Yvelines,
et zéro à celui de l'Essonne** — parce qu'en juillet 1967 **l'Essonne n'existe
pas** : elle naît le 1er janvier 1968, et ses communes portent encore des codes
`78`. Arpajon est `78021`, pas `91021`.

C'est un cinquième déguisement du changement de département, après ceux déjà
recensés. Et il ne se voyait nulle part : chaque ligne prise isolément était
plausible.

La correction est de s'appuyer sur l'**ancre** — le JO imprime « Essonne (décret
n° 67-589 du 20 juillet 1967) » en tête — en ne cherchant que les numéros
attendus dans ce numéro-là, ce qui écarte les visas. Puis de garder le vote
comme **contradicteur** de l'ancre, parce qu'un numéro abîmé par l'OCR fait
glisser tout un bloc de cantons sur le décret précédent, silencieusement.
158 → 194 décrets, 64,3 % → 80,5 % d'appariements exacts.

### Le JO a corrigé Légifrance : trois décrets rendus à leur département

Le contrôle a sorti des cantons d'Alençon, Argentan, Flers, L'Aigle et Beauvais
sous un décret rangé dans le **Nord**. Le JO du 22 janvier 1982 imprime en
en-tête : « Décret n° 82-64 du 20 janvier 1982 (Département de **l'Orne**) ».

Le département était déduit du titre Légifrance par inclusion de chaîne. Or
Légifrance met la liste des cantons créés entre parenthèses à la fin du titre,
et le **NORD** de `BEAUVAIS-NORD-OUEST` ou de `BOURG-NORD-CENTRE` l'emportait
sur le vrai département.

| décret | lu | est en réalité |
|---|---|---|
| 82-63 | 59 Nord | **60 Oise** |
| 82-64 | 59 Nord | **61 Orne** |
| 82-77 | 59 Nord | **01 Ain** |
| 82-82 | 54 (par défaut) | **aucun** — « dans divers départements » |

**C'est la deuxième occurrence du même défaut dans la journée**, après le décret
82-35 perdu parce que « LIÉVIN » contient « VIN ». Une sous-chaîne qui existe
ailleurs dans la ligne, deux fois, dans deux sens opposés — une fois en perdant
un décret, une fois en en déplaçant trois. La règle est désormais de ne chercher
le nom qu'entre `DEPARTEMENT` et la parenthèse ouvrante ; sur 343 décrets elle
ne change que ces quatre-là.

**Conséquence sur la note du matin** : l'Oise et l'Orne au 20 janvier 1982 ne
sont plus des lacunes du registre. Les couples « registre sans décret » passent
de 21 à 19, et deux des dix-neuf restants sont des artefacts de nomenclature
identifiés (Corse `20` contre 2A/2B ; 82-82 « divers départements » contre 54).

### Une hypothèse vérifiée et écartée

Légifrance aurait-il omis d'indexer des décrets présents au JO ? Sur les
32 numéros où la numérotation cantonale est contiguë, 128 numéros voisins
apparaissent dans le texte sans figurer à l'index. **Un seul** parle de cantons,
et c'est une coquille d'OCR du sommaire (`76-73` pour `76-78`). L'index n'a pas
de trou de cette nature.

### Un mot manquait

Dix-sept décrets restaient muets alors que leur JO était sur disque. Quatre
tenaient à un seul mot : 1975 écrit « Le canton de X **comprend** les communes
de… » quand 1973 écrit « comprenant ». L'indicatif n'était pas dans
l'expression. Ajouté, il rend 2 décrets et 112 lignes.

Vingt-neuf autres décrets sont muets **et doivent l'être** : ce sont des
modifications de limites, qui décrivent des tracés de rues sans jamais lister de
communes.

### Ce qui reste

14 numéros de JO sont revenus en 404, portant 26 décrets, surtout 1988-1989. Et
les 83 décrets de 1990-1999 se lisent en clair sur Légifrance, sans PDF : c'est
le lot suivant, et il ne demande rien à personne.

---

## 28 août 2026, tard — 1990-1999 : 100 % d'accord, et cinq transferts que l'annexe VII ignore

Le lot annoncé le matin — « 83 décrets avec texte intégral, il ne demande rien à
personne » — a été dépouillé. Détail dans `cantons/note_legifrance_1990_1999.md`,
fichiers `cantons/composition_legifrance.csv` et
`cantons/transferts_legifrance.csv`, entrée figée dans
`cantons/legifrance_1990_1999.txt`, script `cantons/composition_legifrance.py`.

### Le lot était plus petit qu'il n'y paraissait, et autre chose

Sur les 83 décrets : **19 donnent une composition**, **4 déplacent une commune
entière d'un canton à un autre**, **40 transfèrent des parcelles entre deux
communes**, 10 sont d'autre nature, et **10 n'ont aucun texte** sur Légifrance.

Les 40 sont le gros du lot et ce sont des **non-événements cantonaux** :

> « Les parties de territoire de la commune de Sévérac-le-Château *(canton de
> Sévérac-le-Château)* … sont rattachées à la commune de Rivière-sur-Tarn
> *(canton de Peyreleau)*. »

L'opération traverse une limite cantonale — d'où le mot « canton » au titre,
d'où leur présence dans le moissonnage — mais aucune commune ne change de
canton. C'est de la géométrie communale.

**La leçon de plan** : le nombre de décrets moissonnés ne mesure pas la quantité
de mouvement cantonal. Il faudra s'en souvenir avant d'estimer le coût des
années qui restent.

### Le contrôle le plus propre du dépôt

252 lignes, 20 décrets, 71 cantons. Appariement : **93,3 % exact, zéro rejet**.
Contrôle par le COG 1999 : **34 accords, 0 partiel, 0 désaccord — 208 communes
sur 208, 100,0 %**.

C'est le seul lot qui n'a **jamais rencontré d'OCR** : le texte est natif. Deux
causes se mêlent (dates proches de 1999, absence d'OCR) et ce chiffre seul ne
les sépare pas. Mais il pose une borne : sur le corpus OCRisé à 92,0 %, l'écart
n'est pas principalement une faute de méthode.

### Cinq transferts isolés, datés au jour près

| date | dép. | commune | de | vers |
|---|---|---|---|---|
| 1993-01-25 | 11 | Laprade | Mas-Cabardès | Saissac |
| 1993-01-27 | 38 | Vasselin | La Tour-du-Pin | Morestel |
| 1995-04-10 | 28 | Saint-Denis-des-Puits | La Loupe | Courville-sur-Eure |
| 1995-04-10 | 28 | Villebon | La Loupe | Courville-sur-Eure |
| 1997-02-26 | 38 | Saint-Alban-de-Roche | L'Isle-d'Abeau | Bourgoin-Jallieu - Sud |

Ce sont précisément les mouvements dont `mouvements_cantonaux.csv` dit, dès sa
première ligne, que **l'annexe VII ne les recense jamais**. Le dépôt en compte
274 non datés ; en voici cinq datés, avec origine et destination nommées.

**Contrôle** : les cinq communes sont bien, au COG 1999, dans le canton nommé
comme destination. Cinq sur cinq. Pour Saint-Alban-de-Roche il faut regarder la
composition et non le nom : le canton 38-04 rassemble Badinières, Domarin,
Maubec, Nivolas-Vermelle, Sérézin-de-la-Tour — la couronne sud de
Bourgoin-Jallieu, la ville relevant d'un autre canton, cas ordinaire d'un
chef-lieu partagé.

### Ce qui manque : 1992 en entier

10 décrets n'ont que leur titre. Tous **non numérotés**, tous « modification de
limites cantonales », en deux blocs : avril-octobre 1990 (4) et **l'année 1992
entière** (6). Une pleine année sans un seul texte n'est pas un hasard de
tirage : c'est une lacune du fonds, pas de notre lecture.

Ce qu'elle coûte est probablement faible — 40 des 56 décrets de cette catégorie
dont on a le texte se sont révélés sans conséquence cantonale — mais c'est une
inférence, pas un fait. Dix PDF de JO la lèveraient.

### Le point technique à retenir

Les pages `/jorf/id/…` sont rendues côté client : `WebFetch` ne voit rien, et un
`fetch` sans session ne rend qu'une coquille. **Une fois la session établie dans
le navigateur, `fetch` rend le document complet** — vérifié sur le décret 91-217
en comparant les 14 articles et 7 977 caractères obtenus par `fetch` à ceux de
la page affichée : identiques. C'est ce qui a permis de prendre les 83 décrets
sans naviguer 83 fois.

Corollaire appris à ses dépens : **une navigation efface `window`**. Un
accumulateur doit vivre dans `localStorage`, qui survit au changement de page
sur la même origine.

---

## 28 août 2026, fin de journée — le registre des actes entre en base

Deux fichiers : `sql/72_registre_actes.sql` et `sql/73_recette_1967.sql`.
Le plan complet est dans `cantons/note_entree_en_base.md`.

**Ce qui est posé** : `acte_cantonal` (343 décrets 1958-1999), `acte_composition`
(4 958 lignes acte × canton × commune, 1 267 cantons, 3 578 communes),
`acte_transfert` (5 mouvements isolés), et la table dérivée `acte_silence`.

**Ce qui n'est pas touché** : `membership`. Aucun `snapshot` ne répond
différemment après ce passage.

### Pourquoi c'est le bon ordre, et pas de la timidité

Le report d'un état d'une date à l'autre n'est licite que si la liste des actes
de l'intervalle est complète. Tant que cette liste n'est pas en base, la
condition n'est pas vérifiable :

> on ne peut pas distinguer « rien ne s'est passé » de « on ne sait pas ».

`acte_silence` rend la distinction interrogeable — dernier acte connu avant
1968, premier après, par département. C'est exactement ce que `RESTE_A_FAIRE.md`
demandait pour `60` (« une source par département, pas un seuil »). Ce n'en est
pas pour autant l'autorisation : un silence est une absence d'acte **dans notre
liste**, pas une preuve de stabilité. Mesuré hors base sur 25 398 communes lues
en 1954 et en 1968 : 94,2 % d'accord là où aucun acte n'est enregistré contre
90,9 % là où il y en a — l'écart va dans le bon sens, mais les deux lectures
viennent d'un OCR et 94,2 % n'est pas 100 %.

### La recette de 1967, et pourquoi elle vaut plus que les autres

Le contrôle habituel du dépôt confronte une extraction au COG de 1999 : bon,
mais il regarde trente ans plus tard, et un désaccord peut venir du monde.

`73` confronte les décrets de 1967 au jalon de 1968 **déjà en base**. Cinq mois
séparent les deux sources, et elles ne partagent rien — un texte de décret
OCRisé du JO du 22 juillet 1967 d'un côté, les fascicules du recensement OCRisés
séparément de l'autre. **Un désaccord ne peut donc pas être imputé au monde : il
accuse l'une des deux lectures.** C'est le contrôle le plus serré dont le trou
1943-1999 dispose.

Mesuré hors base sur les fichiers d'étape : 45 accords, 4 partiels, **0
désaccord** — 21/21 en Essonne, 15/16 en Val-d'Oise. Les chiffres rendus par le
fichier SQL seront un peu plus bas : il interroge le `membership` réellement
posé, donc sans les lignes que `59` a refusé d'écrire (canton inconnu, atome
partagé). C'est voulu — c'est la base qu'on juge, pas le fichier de préparation.

### Ce qui n'est pas posé, et ce qui bloque

Les 1 267 compositions et les cinq transferts attendent **une décision qui n'est
pas technique**. Les décrets de 1973, 1982 et 1985 ne portent aucune clause
d'effet : leur article final dit seulement « … qui sera publié au Journal
officiel de la République française ». Vérifié sur les 233 segments de décret
cantonal des JO — sept seulement portent une clause explicite.

La régularité est pourtant écrasante : chaque salve est signée quelques semaines
avant un renouvellement des conseils généraux (1973 → 23/30 septembre 1973 ;
1982 → 14/21 mars 1982 ; 1985 → 10/17 mars 1985), et le seul décret du lot qui
le dise en toutes lettres — celui de 1997 — dit précisément cela.

**Mais les conseils généraux se renouvelaient par MOITIÉ.** « Le prochain
renouvellement » d'un canton dépend de sa série, que nous n'avons pas. Le
décalage possible est d'un renouvellement, soit trois ans. Poser `valid_from` à
la date de signature serait une convention déguisée en fait.

`73` § 5 simule donc la pose des cinq transferts sans écrire : atome trouvé,
canton de destination connu, place libre entre l'acte et 1999. Il ne manque que
la convention, et elle se tranche sur pièces, pas au clavier.

### Le piège évité au passage

`\copy` apparie les colonnes **par position et non par nom**, même avec
`HEADER true` — piège déjà noté par `58`. `composition_legifrance.csv` et
`composition_jo.csv` portaient les mêmes colonnes dans un ordre différent
(`nom_ref` et `dep_insee` permutées). Deux chargements dans les mauvaises cases,
en silence. `composition_legifrance.py` est aligné, et le commentaire dit
pourquoi.

### Réserve honnête

Ces deux fichiers **n'ont pas été exécutés** : la base tourne sur la machine
d'Adrien, pas dans l'environnement où ils ont été écrits, et aucun PostgreSQL n'y
était disponible. Ce qui a été vérifié hors base : l'ordre et le nom des colonnes
des quatre `\copy`, l'unicité de `legifrance_id` comme clé primaire, la
parsabilité de toutes les dates, et l'absence d'orphelin entre compositions,
transferts et registre (0 dans les trois cas). Ce qui ne l'a pas été : la syntaxe
SQL elle-même, et les effectifs que les recettes afficheront.

---

## 28 août 2026, après exécution — la recette a trouvé un trou qu'elle ne cherchait pas

`72` et `73` ont tourné sur la base. Résultats mesurés, et une découverte.

### Ce qui est en base

343 actes, 4 958 compositions (1 208 cantons par le JO, 71 par Légifrance),
5 transferts. **0 orphelin** dans les trois contrôles de cohérence. 4 307 lignes
sur 4 958 raccordées au continuum d'atomes, pour 3 578 codes INSEE distincts ;
6 codes portés par plusieurs atomes, phénomène connu de `58` § 3. 125 actes
muets sur 343 — ce sont les modifications de limites décrites par des rues et
les transferts de parcelles, comme attendu.

### Une prédiction fausse, et c'est une information

J'avais annoncé que `73` rendrait des chiffres **plus bas** que la simulation
faite hors base, puisqu'il interroge le `membership` réellement posé et non les
fichiers d'étape — donc sans les lignes que `59` a refusé d'écrire.

Il rend exactement les mêmes : **45 accords, 4 partiels, 0 désaccord, 27 trop
courts, 14 sans commune retrouvée.** Au canton près, dans chaque catégorie.

Ce que cela dit : les lignes écartées par `59` sont dispersées, et le vote
majoritaire par composition y est insensible. La recette juge la même chose que
le fichier de préparation — ce qui, cette fois, est rassurant, mais ne l'était
pas d'avance.

**387 communes sur 404 confirmées, 95,8 %**, sur des sources séparées de cinq
mois. Zéro désaccord, là où un désaccord n'aurait pas pu être imputé au monde.

### Les 14 muets sont tous dans le même département, et ce n'est pas un hasard

Les 14 cantons dont **aucune** commune n'est retrouvée en 1968 sont les 14
cantons d'Yvelines du décret n° 67-594. Pas un canton contesté, pas une lecture
douteuse : rien du tout, systématiquement.

`RESTE_A_FAIRE.md` le disait depuis le début sans qu'on ait fait le lien : neuf
fascicules du COG 1968 sont introuvables sur BnSP — **61 et 71 à 78**, soit
3 593 communes hors du jalon. Le 78 en fait partie.

La recette a donc trouvé un trou documenté ailleurs, sans le chercher, parce
qu'elle regardait autre chose. C'est le meilleur usage qu'on puisse faire d'un
contrôle.

**Ce que les décrets rendent dans ces neuf départements** : 555 communes
distinctes sur 3 593, avec une date. Dont 194 pour les seules Yvelines, sur
34 cantons.

### `74_yvelines_1967.sql` — le décret à la place du fascicule

Écrit dans la foulée, et c'est le **premier membership que ce chantier pose**.

Ce qui le distingue des compositions de 1973, 1982 et 1985 qui attendent
toujours : sa date d'effet n'est pas une convention. Les Yvelines naissent le
1er janvier 1968 par démembrement de la Seine-et-Oise, et le décret du
20 juillet 1967 crée leurs cantons avec effet à cette naissance.
`valid_from = 1968-01-01` est un fait juridique. Il n'y a rien à trancher.

L'identité des cantons passe par la composition — le décret nomme sans coder, et
le fascicule qui aurait codé est justement celui qui manque. Le canton retenu
est celui de 1999 qui partage au moins 80 % des communes, sur au moins trois.
Cohérent avec `24` § 1 : ce qui est affirmé est l'identité du canton, pas la
constance de sa composition.

Mesuré hors base : **11 cantons résolus, 155 rattachements posés** ; 6 écartés
comme trop courts, 2 en accord partiel (Chevreuse, Conflans-Sainte-Honorine),
1 en désaccord — **Trappes**, ville nouvelle qui a triplé depuis, redécoupée.
Les trois derniers ne sont pas posés et sont listés avec leur motif. Règle de
`60` : mieux vaut un canton absent qu'un canton faux.

La borne haute est un `\set` explicite, `1969-01-01` par défaut comme chez `59`.
`1976-01-15` — le premier acte suivant pour le 78 — serait défendable puisqu'un
acte vaut jusqu'au suivant, mais suppose la liste complète sur l'intervalle. Le
choix est laissé visible plutôt qu'hérité d'un défaut.

### Le chiffre qui interdit l'extension en arrière

`acte_silence` le dit sans détour : sur 100 départements, **86 n'ont aucun acte
enregistré avant 1968**, et le silence moyen autour du jalon vaut 29,0 années.

Quatre-vingt-six départements sans le moindre acte cantonal en vingt-cinq ans
n'est pas croyable. C'est une lacune du fonds JORF avant 1970, pas une stabilité
du territoire — et cela confirme, chiffre en main, qu'il ne faut pas étendre le
jalon vers l'arrière sur la seule foi du silence.

Les dix départements au silence le plus court sont tous récents ou remaniés :
90, 57, 14, 91, 78, 94, 93, 95, 49, 60. Ce sont ceux où il y a le plus à lire et
le moins à supposer.

---

## 28 août 2026, nuit — la convention est tranchée, et un banc d'essai la juge

Adrien retient le **scrutin suivant la signature** comme date d'effet. C'est la
décision qu'attendaient les 1 267 compositions chargées par `72` : elles entrent
en base pour les deux grosses salves, par `sql/75_composition_1973_1982.sql`.

### Ce qui change de nature dans le dépôt

Jusqu'ici, chaque `valid_from` posé venait d'un fait. `59` tenait sa date d'un
recensement, `74` de la naissance d'un département. **`75` est le premier
fichier dont la date de début est une convention** — et c'est pour cela que
l'essentiel de son travail n'est pas de poser des lignes mais de dire où la
règle peut se tromper.

Les conseils généraux se renouvelaient par moitié. « Le prochain
renouvellement » d'un canton dépend de sa série, que nous n'avons pas. Pour un
canton créé la question ne se pose guère ; pour un canton modifié, le décalage
possible est de trois ans. `p75_qualite` porte donc `serie_inconnue` et
`decalage_max_annees` sur chaque rattachement, comme `c68_qualite` porte la
qualité de lecture de 1968. Mesuré au banc : **deux tiers des rattachements
viennent d'actes de création pure**, donc sans incertitude de série ; un tiers
la porte.

L'objet de l'acte est le seul discriminant disponible, et il ne tranche que
dans un sens : `creation de cantons` lève le doute, `creation et modification`
ne le lève pas. On garde donc le doute là où la source ne le lève pas.

### Un PostgreSQL jetable, et trois défauts qu'aucune relecture n'avait vus

`72` et `73` avaient été livrés **sans avoir été exécutés**, faute de base dans
l'environnement d'écriture. La réserve était honnête ; elle ne devait pas
devenir une habitude. `sql/banc_75.sh` monte un PostgreSQL embarqué
(`pip install pgserver`), y pose le schéma réel et une couche de 1999
synthétique, puis joue `72` et `75` sur les **vrais** CSV du dépôt.

Il manque deux extensions à ce PostgreSQL : `postgis`, dont `75` n'a aucun
besoin, et `btree_gist`, sans laquelle les `EXCLUDE` ne se créent pas. Elles
sont **remplacées par des déclencheurs qui refusent exactement les mêmes
lignes** — ce n'est pas un contournement, c'est le comportement qu'on veut
éprouver. La suite l'a prouvé : c'est le déclencheur qui a levé le défaut n° 2.

**1. `\set` avale le commentaire de fin de ligne.**

    \set fin_serie '1999-01-01'   -- 24 reprend la main ici

La variable vaut `1999-01-01--24_canton_modernereprendlamainici`, et le premier
cast en `date` échoue. Erreur immédiate, donc bénigne — mais elle n'aurait été
vue qu'au lancement sur la vraie base, c'est-à-dire par Adrien.

**2. Une commune citée deux fois n'est pas deux rattachements.** Un décret peut
la nommer deux fois, et les deux extractions se recouvrent sur 283 cantons.
L'insertion posait deux lignes identiques et la contrainte refusait la seconde
**au milieu de l'écriture**. Le dédoublonnage écrit d'abord comparait
`(unit_id, valid_from)` par `<`, exactement la faute de `42` : *un `<` ne retire
que les doublons de valeurs différentes ; deux lignes identiques passent.* Il
fallait grouper, pas comparer.

**3. Un taux de résolution de 333 %.** Le vote se comptait sur des lignes et non
sur des communes distinctes : Aureilhan, trois communes, en « retrouvait » dix.
*Un taux supérieur à 100 % n'est pas un bon score, c'est un défaut de
dénombrement* — et il aurait faussé le seuil de 80 % dans le sens permissif,
donc posé des cantons faux sans que rien ne le signale.

Aucun des trois n'était visible à la lecture. Le troisième, en particulier,
rendait un résultat cohérent et faux.

### Deux choses que les vraies données ont dites

**Une commune disputée.** `14163` est donnée à la fois à Ouistreham-Riva-Bella
et à Troarn par la salve de 1982. Le modèle l'interdit, et il a raison.
Le premier jet refusait toute la salve sur ce seul cas ; c'est disproportionné.
**On écarte la commune, pas les deux cantons** : la contradiction porte sur
cette ligne, les autres communes ne sont contestées par personne. C'est ce que
`59` fait de ses 460 `atome_ambigu`. Le refus en bloc reste, mais au-delà de
cinquante cas — seuil posé avant la mesure : une poignée est du bruit de
lecture, cinquante diraient que la salve n'est pas lue comme un ensemble.

**Un canton perdu par une espace.** « Saint-Quentin - Sud » et
« Saint-Quentin-Sud » se disputaient le même canton de 1999 et étaient refusés
tous les deux pour collision. La normalisation ajoutée ne fait qu'une chose :
uniformiser les espaces autour des traits d'union et la casse. Elle ne
rapproche pas deux noms voisins, et n'a donc rien de commun avec l'appariement
par le nom que le dépôt s'interdit depuis la série havraise — *deux noms qui ne
diffèrent que par une espace ne sont pas deux noms.* « Rennes-VIII » et
« Rennes-VIII-1 » restent distincts, ce qui est le comportement voulu.

### Le piège que le banc a dû être forcé de montrer

Les décrets de 1973 écrivent la Corse `20`, ceux de 1982 `2A` et `2B` : le
recodage de 1976 tombe **entre les deux salves**. Une comparaison de département
au caractère près écarterait la Corse de 1973 en silence — le défaut exact qui a
coûté Chisa à `15`. `75` vote donc sur les atomes d'abord et vérifie la
compatibilité de département ensuite, avec `20`, `2A` et `2B` tenus pour un seul
département.

Le banc ne l'exerçait pas : sa couche de 1999 déduisait le département du code
INSEE, et les codes corses de 1973 commencent eux aussi par `20`. Il a fallu
**forcer** la Corse en `2B` dans les données du banc pour que le chemin soit
parcouru. *Un banc qui ne reproduit pas le piège ne prouve rien de la parade* —
et c'était vrai ici alors même que le code de la parade était correct.

### Et la rejouabilité, cette fois, est vérifiée

Le banc joue `75` deux fois de suite et compare : 2 101 rattachements, puis
2 101. L'en-tête de chaque fichier du dépôt affirme la rejouabilité depuis
`55` ; c'est la première fois qu'une exécution le montre.

### Ce qui reste

Les chiffres ci-dessus sont ceux du BANC, dont la couche de 1999 est fabriquée
depuis les décrets eux-mêmes : ils disent que la mécanique tourne, **pas ce que
la vraie base rendra**. Le taux de résolution réel dépend de `24`, et
`note_entree_en_base.md` l'annonce plus bas — 553 couples décret × canton sur
866 ont un lien avec 1999, soit 64 %. Le reste sont des cantons de moins de
trois communes et des cantons disparus avant 1999.

Suite : `76` pour les autres salves — 1967, 1970, 1974-1976, 1984, 1985, 1988,
1991-1997 — avec la même convention et les mêmes tables ; puis les cinq
transferts isolés, que `73` § 5 simule déjà ; puis `77`, l'extension du jalon de
1968 là où deux actes bornent l'intervalle.

## 28 août 2026, plus tard — le premier passage réel, et 367 %

Adrien a joué `75` sur la vraie base. Il pose **1 869 rattachements sur
266 cantons**, 60 départements pour 1973 et 42 pour 1982, toutes les recettes à
zéro, le jalon de 1968 intact à 32 659. Et une ligne qui dit que c'est faux :

    65 | Aureilhan | 3 communes | 11 partagées | taux 367 %

**Le même symptôme que l'après-midi, une cause différente.** Le comptage
portait bien, cette fois, sur des communes distinctes — la correction tenait.
Mais le vote était agrégé sur `(département, canton)` **sans la période**. Un
canton cité par les deux salves a deux lignes à juger, une par période, et
recevait un seul vote pour les deux : trois communes en 1982 confrontées aux
onze retrouvées sur 1973 *et* 1982 réunis.

Corrigé en portant `valid_from`/`valid_to` dans la clé du vote, au § 5 comme au
§ 8 — le diagnostic 1968 souffrait du même défaut, ce qui explique en partie
ses 168 cantons « à unité différente » sur 283.

### Ce que le banc n'a pas pu voir, et pourquoi

Le banc bâtit sa couche de 1999 depuis les décrets eux-mêmes, en retenant pour
chaque commune le canton de la salve la plus tardive. Les cantons cités deux
fois y sont donc plus rares et plus cohérents que dans la vraie nomenclature.
Le défaut existait, il ne se voyait pas.

*Un banc calibré sur la source qu'il teste ne teste pas la source.* C'est la
limite de la méthode, et elle était annoncée — « il montre que la mécanique
tourne, il ne dit rien de ce que la vraie base rendra ». Elle vient d'être
vérifiée dans le sens désagréable.

### La correction qui compte n'est pas celle du calcul

Deux causes différentes ont produit le même symptôme en une soirée. La
troisième aurait été trouvée par un troisième hasard, ou pas.

`75` § 5 ter **lève désormais une exception sur tout taux supérieur à 100 %**,
et refuse en bloc. La borne ne peut pas être franchie par construction :
`partagees` est un sous-ensemble de `communes`. Quand elle l'est, ce n'est
jamais le score qui est bon — et le dépassement fausse le seuil de 80 % **dans
le sens permissif**, en faisant passer des cantons que la règle aurait dû
refuser. C'est la seule direction où plus rien ne le signale ensuite.

Écrit dans `METHODE.md` : *quand un même symptôme peut naître de plusieurs
causes, il faut le rendre impossible, pas le corriger.*

### Deux collisions à regarder sur pièces

Elles ne sont pas des défauts de calcul, et le fichier a raison de refuser :

* **Laval - Nord-Ouest et Laval - Sud-Ouest** (53), trois communes chacun,
  100 % tous les deux, tous deux vers `5332`. Deux cantons distincts de 1973
  que la nomenclature de 1999 réunit — ou dont les communes citées sont des
  fractions de la ville. À trancher au JO.
* **Aureilhan et Bordères-sur-l'Échez** (65), tous deux vers `6533`. Même
  question, et c'est le canton par lequel le défaut est sorti.

### Et la commune disputée, qui change de nom

Le § 5 bis rend `9724` et non `14163` : sur la vraie base, `atome` est un code
Cassini, pas un code INSEE. Le fait est le même — une commune du Calvados
donnée à la fois à Ouistreham-Riva-Bella et à Troarn par la salve de 1982 — mais
la note du 28 août au soir la désignait par son code de banc. Corrigé.

**À refaire** : rejouer `75`, qui se défait seul par `p75_trace`. Le nombre de
rattachements va baisser — les cantons qui ne résolvaient que par l'addition
des deux périodes ne résoudront plus, et c'est le but.

## 28 août 2026, fin — `75` tient, et un garde-fou trouve une coupure mal placée

Second passage sur la vraie base, après la correction de la période dans la clé
du vote.

| | |
|---|---|
| rattachements posés | **1 848** sur 266 cantons |
| taux supérieurs à 100 % | **0** (§ 5 ter, désormais bloquant) |
| chevauchements, périodes absurdes, débordements de 1999 | 0 |
| jalon de 1968 | 32 659 — intact |
| `snapshot(1974)` / `snapshot(1983)` | 1 160 / 1 363 rattachements |
| part au décalage de série possible | 37,2 % |

Le rejeu s'est défait proprement (`DELETE 1869`) avant de reposer 1 848 : la
rejouabilité annoncée depuis `55` est vérifiée sur la vraie base, et pas
seulement au banc. Les 21 rattachements de moins sont ceux qui ne résolvaient
que par l'addition des deux salves — leur disparition est le but de la
correction, pas son coût.

Les collisions tombent de 4 à 2 : Aureilhan et Bordères-sur-l'Échez étaient un
artefact du dénombrement. **Reste Laval - Nord-Ouest contre Laval - Sud-Ouest**
(53), trois communes et 100 % chacun, tous deux vers `5332` — deux cantons de
1973 que 1999 réunit, ou des fractions de ville. À trancher au JO.

### Le garde-fou du département ne visait pas ce qu'il a trouvé

Il restait un refus : **Evreux-Ouest, lu sous le département 25, cinq communes
toutes dans le 27**. J'ai d'abord cru à un département mal lu. Les pièces
disent autre chose :

* le décret n° 82-55 est celui du **Doubs** — son titre nomme Besançon,
  Audincourt, Valentigney, Pont-de-Roide ;
* le n° 82-56 est celui de l'**Eure**, et son titre nomme **EVREUX-OUEST** ;
* les deux se suivent dans le JO du 22 janvier 1982 ;
* et le compte se répond des deux côtés : 82-56 annonce sept cantons et n'en a
  que six, 82-55 en a un de trop.

**La coupure entre les deux décrets est tombée un bloc trop loin.** Ce n'est
pas une erreur de lecture de département, c'est une erreur de segmentation, et
la colonne `dep_insee` de l'extraction le disait déjà — `autre departement`,
inscrit sur les cinq lignes, jamais relu.

### Le contrôle qui dormait sur le disque

`acte_cantonal.cantons_titre` vient de l'**index de Légifrance** ;
`acte_composition.canton` vient du **texte OCRisé du JO**. Deux origines, donc
l'un peut juger l'autre. La colonne était là depuis le moissonnage du matin et
n'avait jamais servi.

`sql/diag_titre_composition.sql`, lecture seule, la met au travail. Résultat :

**Deux cantons égarés, tous deux dans le même JO** — celui du 22 janvier 1982.
Evreux-Ouest (82-55 → 82-56, les communes donnent raison au titre) et
**Lorient-Centre**, lu sous le décret 82-51 avec un département `15` — le
Cantal — quand le titre du 82-62 le réclame pour le Morbihan. Celui-là n'a
aucun code INSEE pour trancher : c'est une ligne de fraction seule, et sans le
titre rien ne l'aurait signalé.

**Et une mesure qui n'existait pas** : sur les 45 décrets dont le titre nomme
des cantons ET dont on a lu une composition, **120 cantons retrouvés sur 184
annoncés — 65,2 %**, et dix décrets complets seulement. C'est le rappel de
l'extraction décret par décret, jusqu'ici inconnu. Deux cas appellent un coup
d'œil : le n° 82-79 (06) annonce douze cantons et en rend trois ; le n° 82-35
(62) en rend huit dont **un seul** figure à son titre.

Portée du contrôle : **55 actes sur 343** ont un titre renseigné. Il ne juge
donc pas le corpus, il juge une fenêtre — mais dans cette fenêtre, il juge
sans rien partager avec ce qu'il juge.

### Ce qu'on ne fait pas ce soir

On ne corrige pas les CSV. La coupure se fait dans `cantons/composition_jo.py`,
et c'est là qu'il faut la reprendre — *réparer la règle là où elle vit plutôt
que la rattraper en aval*, comme pour `15` en août. Chaque déplacement de bloc
devra être adossé à son titre, et le contrôle rejoué après.

Note de lecture pour plus tard : le § 5 bis rend `9724` et non un code INSEE.
Sur la vraie base, `atome` est un code Cassini. Le fait est le même — une
commune du Calvados donnée à la fois à Ouistreham-Riva-Bella et à Troarn.

## 28 août 2026 — le JO répond, et la cause est une mise en page

Trois questions ouvertes, trois réponses au Journal officiel. Aucune n'était
celle que j'attendais.

### 1. Evreux-Ouest : la coupure n'est pas mal placée, le TEXTE est entrelacé

`jorf_txt/JORF_19820122_18.txt`, lignes 258 à 289 :

    Canton de Besançon - Nord-Ouest délimité par l’axe des voies    Art. 1er. — Le canton d’Evreux-Sud est divisé en trois cantons
    suivantes : route de Vesoul depuis la limite territoriale de la  dénommés et délimités comme suit :

**Le JO est sur deux colonnes, et l'extraction les a fondues ligne à ligne.**
Chaque ligne du fichier porte la colonne de gauche PUIS celle de droite. À
gauche court le décret n° 82-55 (Doubs, Besançon) ; à droite, le n° 82-56
(Eure, Evreux).

La conséquence se lit dans les numéros de ligne : le contenu du 82-56 est aux
lignes 258-289, et **son en-tête à la ligne 324**. Le texte d'un décret paraît
avant son propre titre. Un lecteur linéaire attribue donc la colonne de droite
au décret dont il a vu l'en-tête à gauche.

Ce n'était pas « une coupure tombée un bloc trop loin ». C'était vrai du
symptôme, faux de la cause, et je l'ai écrit trop vite hier soir.

**Le fichier `_raw.txt` a le même défaut** — il ne fait que découper les lignes
fondues, il ne sépare pas les colonnes. Vérifié : contenu du 82-56 aux lignes
412-431, en-tête à la 470.

### 2. Lorient-Centre : même mécanisme, et le titre avait raison

Décret n° 82-51 = **CANTAL** (Aurillac). Décret n° 82-62 = **MORBIHAN**
(Lorient-Centre, Lorient-Sud, Lorient-Nord, Ploemeur…). Le canton de Lorient a
été lu sous le décret du Cantal.

Dans le JO, l'en-tête du 82-62 paraît en colonne de droite à la ligne 533,
celui du 82-61 en colonne de gauche à la ligne 554 : **l'ordre des décrets est
inversé par la lecture linéaire.** Cette ligne-là n'avait aucun code INSEE — une
fraction de ville — et seule la confrontation au titre pouvait la démasquer.

### 3. Laval : ce n'était pas une erreur du tout

Le décret du 17 juillet 1973 (`JORF_19730717_164`) remplace Laval-Est et
Laval-Ouest par quatre cantons. Nord-Ouest reçoit Ahuillé, Courbeveille et
Saint-Berthevin ; Sud-Ouest reçoit Astillé, Montigné-le-Brillant et
Nuillé-sur-Vicoin. Trois communes chacun, plus une portion de ville — exactement
ce que `75` a lu.

Puis le décret du 24 décembre 1984 (`JORF_19841230_305`) :

> « En remplacement des cantons de Laval-Nord-Ouest, Laval-Sud-Ouest et
> Laval-Est, sont créés quatre cantons… »

et les nouveaux Laval-Nord-Ouest et Laval-Sud-Ouest sont définis **uniquement
par des portions de la commune de Laval**. Les six communes rurales sont
parties ailleurs. En 1999 elles se retrouvent ensemble, et les deux cantons de
1973 votent donc pour la même unité.

**Le refus de `75` est juste, son motif est myope.** « La résolution n'est plus
injective » décrit le symptôme ; la cause est qu'un acte est passé entre les
deux dates — et le registre le savait déjà.

### Ce que cela donne : le § 11

`75` compte désormais, pour chaque canton, les actes intercalés entre sa salve
et 1999, et croise avec le verdict. Si le taux de résolution baisse quand les
actes s'accumulent, alors les 63 accords partiels ne sont pas du bruit : ils
ont une cause nommée et datée, et ils se résoudront quand `76` aura rapproché
le point de comparaison.

Le banc ne peut pas juger ce diagnostic — sa couche de 1999 est bâtie depuis
les décrets eux-mêmes, donc rien ne s'y intercale. Il faut le vrai passage.

### Le chantier que cela ouvre, et son prix

La vraie réparation est en amont : **extraire chaque colonne séparément**, avec
les boîtes de `pdftotext -x -W` page par page, puis rejouer
`cantons/composition_jo.py`. Le gain se mesure d'avance : le rappel contre les
titres est de **65,2 %** aujourd'hui.

~~Obstacle immédiat : les PDF ne sont plus sur disque.~~ **FAUX, corrigé le
même jour** — voir la section suivante. J'avais lu un `ls | head` tronqué et
conclu de l'échantillon. Il y a **89 PDF**, et ils couvrent les 30 JO
exploités. Aucun remoissonnage n'est nécessaire.

Deux correctifs bon marché en attendant, l'un et l'autre adossés à une pièce :

1. **Le titre comme ancre.** Quand un canton lu sous le décret A est nommé au
   titre du décret B du même JO, il appartient à B.
   `diag_titre_composition.sql` le calcule déjà — deux cas, tous deux sûrs.
2. **Faire voter les lignes `autre departement`.** Elles portent un
   `dep_insee` : c'est précisément la pièce qui manquait. Les cinq lignes
   d'Evreux-Ouest le portaient, et le vote ne les a pas comptées.

## 28 août 2026 — les colonnes séparées, mesurées ; et la commune disputée n'existait pas

### D'abord une erreur à réparer

J'ai écrit que les PDF du JO n'étaient plus sur disque et qu'il fallait
remoissonner. C'est faux. Il y en a **89**, et ils couvrent les **30 JO
exploités par l'extraction**. J'avais lancé un `ls JORF | head`, vu dix noms,
et conclu de l'échantillon — puis bâti une recommandation entière dessus.

*Un `head` répond à la question « à quoi cela ressemble-t-il », jamais à
« combien y en a-t-il ».* Le dépôt a déjà écrit que le choix de l'échantillon
fait partie de la mesure ; ici il n'y avait même pas de mesure, seulement un
coup d'œil promu en fait.

### La séparation des colonnes fonctionne, et se mesure

`cantons/jorf_colonnes.py` appelle `pdftotext` deux fois par page — boîte de
gauche, boîte de droite — et concatène dans l'ordre de lecture. Sur les 30 JO
exploités :

| | linéaire | par colonnes |
|---|---|---|
| en-têtes de décret repérés | 548 | 540 |
| **inversions de numérotation** | **88** | **46** |

Une inversion — un décret n° 82-62 paraissant avant le n° 82-61 — est la
signature de l'entrelacement. **Elles tombent de moitié.**

Le test décisif, sur le JO du 22 janvier 1982 :

| | linéaire | par colonnes |
|---|---|---|
| en-tête du décret 82-56 | ligne 324 | ligne **548** |
| son contenu (Canton d'Evreux-Ouest) | ligne 281 | ligne **589** |

Le texte suit désormais son titre. Et l'ordre 82-61 puis 82-62 est rétabli, ce
qui rend Lorient-Centre au Morbihan. **Les deux cantons égarés se corrigent
par la source, sans règle ajoutée.**

### Ce que la mesure ne dit pas

Il reste **46 inversions**, et huit en-têtes perdus. La coupure à la moitié
exacte de la page abîme ce qui traverse les deux colonnes — bandeaux,
sommaires, tableaux. La séparation des colonnes est un gain net, pas une cure ;
elle divise le défaut par deux et le reste demandera autre chose.

Les fichiers sont écrits en `_col.txt` à côté des existants, **sans rien
écraser**. Les deux lectures devront être comparées avant qu'aucune ne soit
retirée — c'est la leçon des deux passes OCR de 1968, dont l'union valait mieux
que chacune.

### La commune disputée : « le plus proche » en avait fabriqué une

Le § 5 bis de `75` signalait l'atome `9724` réclamé par Ouistreham-Riva-Bella
et par Troarn. Le JO du 28 janvier 1982, décret n° 82-92 (Calvados), lu en
colonnes, dit :

> Canton de Ouistreham-Riva-Bella, comprenant les communes de
> Ouistreham-Riva-Bella, **Colleville**, Saint-Aubin-d'Arquenay,
> Periers-sur-le-Dan, Bréville-Beuville, Bénouville et Blainville.
>
> Canton de Troarn comprenant les communes de Touffreville, Cuverville, […]
> Canteloup et **Cléville**.

Il n'y a **aucune contradiction dans la source**. L'appariement a échoué sur
« Colleville » — absent du référentiel sous cette forme — et est retombé *par
ressemblance* sur **Cléville**, `14163`, qui appartient réellement à Troarn.

C'est mot pour mot la leçon de Butry-sur-Oise, écrite pour 1954 : *quand la
vraie cible manque, « le plus proche » en fabrique toujours une.* Elle vaut
pour les décrets comme pour le recensement.

Les codes justes, vérifiés dans les données du dépôt :

| lu | posé à tort | juste |
|---|---|---|
| Colleville | `14163` Cléville | **`14166`** Colleville-Montgomery |
| Saint-Aubin-d'Arquenay | *rien* | **`14558`** |
| Ouistreham-Riva-Bella | *rien* (`aucun`) | **`14488`** Ouistreham |

Confirmation extérieure : le fichier de 1954 place Colleville-Montgomery dans
le canton de **Douvres**, et c'est précisément le canton que le décret de 1982
divise pour créer Ouistreham-Riva-Bella.

**Combien de cas comme celui-là ?** Un seul. Mesuré sur les 4 958 lignes de
composition : un seul code INSEE est réclamé par deux cantons d'un même acte,
et c'est celui-ci. Le garde-fou du § 5 bis a trouvé l'unique aiguille.

La correction appartient à l'appariement de `composition_jo.py`, et deux règles
en sortent, chacune vérifiable :

1. **Un code déjà attribué en `exact` à un autre canton du même acte doit
   interdire une attribution par `ressemblance`.** L'exact est une pièce, la
   ressemblance une conjecture ; une conjecture ne prend pas la place d'une
   pièce.
2. **Un nom tronqué doit préférer le PRÉFIXE dans son département.**
   « Colleville » est un préfixe de « Colleville-Montgomery » ; « Cléville »
   n'en est pas un. La ressemblance orthographique les départage à l'envers.

## 28 août 2026 — `composition_jo.py` repris à la source, et cinq défauts

Le détail chiffré est dans `cantons/note_composition_jo.md`. Ancienne version
conservée : `archives/composition_jo_2026-08-28_lecture_entrelacee.csv`.

**Le résultat** : 4 737 lignes (+31), 1 212 cantons (+4), **101 communes
rattachées de plus**, et les appariements `aucun` divisés par deux — 154 → 72.
Les deux contrôles indépendants vont dans le même sens : cantons au titre
120 → 122, **égarés 2 → 0**, et le COG 1999 passe de 419 à 420 accords sans
bouger de 92,0 %.

### Ce que j'ai appris en me trompant deux fois de réparation

**Premier essai : découper la page.** Rappeler `pdftotext` avec une boîte par
colonne rétablit l'ordre — et détruit le texte. L'extraction tombait à 4 414
lignes, les ressemblances doublaient. *Une réparation qui repasse par la source
rend une source différente.* Il ne fallait pas relire la page, il fallait la
déplier : couper le texte `-layout` déjà rendu au blanc vertical, ligne par
ligne. Mêmes octets, autre ordre.

**Deuxième essai : faire taire le vote.** Le vote lisait des noms de rues comme
des communes — « rue Colbert », « place Sadi-Carnot » — et avait expédié le
canton de Marseille-I en Haute-Savoie contre une ancre pourtant juste. J'ai
d'abord restreint le vote aux communes lues : Marseille rentrait, et le
contrôle par les titres reperdait ce qu'il avait gagné. J'ai ensuite refusé
toute voix aux cantons sans communes entières : Marseille rentrait, et
Lorient-Centre repartait dans le Cantal.

Les deux cas s'opposent — à Marseille l'ancre a raison, à Lorient c'est le
vote — et c'est ce qui a fini par donner la bonne règle. Ce qui les départage
n'est pas la quantité de preuves mais leur **qualité** : un canton sans
communes entières ne vote pas avec ses rues, il vote avec les deux seuls noms
de communes que le décret lui donne — son **chef-lieu**, toujours nommé, et sa
propre tête de nom. *On ne réduit pas le nombre de preuves, on écarte celles
qui n'en sont pas.*

### Trois couperets qui décidaient en silence

* **401 caractères contre un plafond de 400.** Le canton de Bonnières-sur-Seine
  et ses 26 communes disparaissaient — ni sortie, ni rejet. Le plafond garde
  contre une amorce qui avale la page ; il ne doit pas décider de l'existence
  d'un canton, et surtout pas sans le dire.
* **La césure de fin de ligne** ne se recollait que devant une minuscule.
  « Jouy-\nMauvoisin » restait coupé — et ces deux caractères de trop étaient
  précisément ce qui franchissait le plafond ci-dessus.
* **« où est fixé son chef-lieu »** n'était pas une borne de liste : 31 lignes
  portaient toute la phrase comme nom de commune. Le canton existait dans le
  fichier, avec une commune fantôme.

Aucun des trois ne faisait échouer quoi que ce soit. C'est la marque du dépôt
depuis le contrôle Gay : *les recettes internes valident la cohérence, pas
l'exactitude.*

### Et le préfixe, qui n'aurait pas dû être un repli

« Colleville » ressemble davantage à « Cléville » (0,89) qu'à
« Colleville-Montgomery » (0,71). La ressemblance orthographique départage ces
cas à l'envers, et c'est ainsi qu'une commune de Troarn s'était retrouvée à
Ouistreham. Le préfixe au trait d'union passe désormais avant — dans les deux
sens, car le décret abrège autant qu'il allonge : « Ouistreham-Riva-Bella »
retrouve enfin la commune d'Ouistreham. 70 lignes y gagnent un code.

Et quand le préfixe désigne deux communes — « Colleville » en désigne deux
dans le Calvados — la ligne sort en `prefixe ambigu`, sans code, ses candidats
au fichier des rejets. 18 lignes. **La source ne tranche pas, nous non plus.**

### À rejouer

`sql/72_registre_actes.sql` recharge `acte_composition` depuis ce fichier —
l'ordre des colonnes est inchangé, le `\copy` passe tel quel. Puis `73`, `74`
et `75`, qui en dépendent. Les chiffres de `75` vont bouger : quatre cantons de
plus, et surtout trois cantons qui changent de département.

## 28 août 2026 — la base a jugé le correctif, et en a trouvé un défaut

Adrien a rejoué `72`, `73`, `74`, `75` et le diagnostic des titres. Le résultat
tient, et le garde-fou a fait exactement ce pour quoi il a été écrit.

### Ce qui est gagné

`74` pose **12 cantons et 183 rattachements** au lieu de 11 et 155 : le canton
de **Bonnières-sur-Seine et ses 26 communes** entre au jalon des Yvelines, à
100 % d'accord — c'est le canton que le plafond de 400 caractères faisait
disparaître.

`75` pose **1 902 rattachements sur 270 cantons** (contre 1 848 et 266), et
surtout **« département incompatible » a disparu** : Evreux-Ouest est rentré
dans l'Eure. `accord partiel` recule de 63 à 60. Le diagnostic des titres rend
**0 canton égaré** et 12 décrets complets au lieu de 10.

Le § 11 confirme le gradient sur des chiffres neufs : 63,6 % de résolution sans
acte intercalé, 52,9 % avec un ou deux, 50,8 % au-delà.

### Ce qui était cassé, et par moi

Le § 5 bis a signalé une commune disputée — mais **une autre** : `5861`, entre
**Cabourg et Ouistreham-Riva-Bella**. Le décret 82-92 donne « Breville » à
Cabourg (Bréville) et « Bréville-Beuville » à Ouistreham, lecture OCR de
Biéville-Beuville. Ma règle `prefixe lu`, placée avant la ressemblance,
tronquait le second en « Bréville » et le posait sur la commune du canton
voisin. **L'ancienne lecture faisait juste ; la mienne a introduit l'erreur.**

Le correctif est une question d'ordre, pas de force : *le nom entier porte plus
d'information que sa troncature.* Une ressemblance sur le nom complet
(Bréville-Beuville / Biéville-Beuville, 0,94) l'emporte sur une correspondance
exacte obtenue en jetant la moitié du nom. Là où la ressemblance ne trouve rien
— « Ouistreham-Riva-Bella » ne ressemble à « Ouistreham » qu'à 0,69 — la
troncature reste seule, et elle a raison.

Après correction : **zéro code réclamé par deux cantons d'un même acte**, sur
les 4 739 lignes. Les deux contrôles ne bougent pas — titres 122/184, égarés 0,
COG 1999 à 420 accords et 92,0 %.

### La leçon, et elle vaut plus que le correctif

Une règle ajoutée pour réparer un cas en a cassé un autre du même acte, et
**rien dans les recettes de l'extraction ne l'aurait vu** : les deux lectures
étaient plausibles, les deux codes existaient, les deux communes étaient dans
le bon département. C'est le § 5 bis de `75`, écrit pour un tout autre motif,
qui l'a rendu visible — parce qu'il regarde une propriété du MODÈLE (une
commune n'appartient qu'à un canton) et non une propriété de la lecture.

*Un garde-fou posé sur le modèle attrape des fautes que les recettes de
l'extraction ne peuvent pas voir.* Il faut donc rejouer la chaîne entière après
un correctif d'extraction, et pas seulement les contrôles du fichier corrigé.

Enfin, une scorie : « Colleville,^ Saint-Aubin-d'Arquenay » faisait perdre
Saint-Aubin-d'Arquenay, dont le nom ne commençait plus par une majuscule. Le
canton d'Ouistreham-Riva-Bella, qui aura servi de fil du début à la fin, est
désormais lu entier — « Colleville » excepté, déclaré `prefixe ambigu` parce
que le Calvados en compte deux et que le décret ne tranche pas.

## 28 août 2026 — `76`, la longue traîne, et ce qu'on refuse de dupliquer

`sql/76_composition_salves_restantes.sql` prend tout ce que `75` n'a pas pris :
1961, 1970, 1974-1976, 1984, 1985, 1988, 1991-1997 — environ 1 240 lignes sur
383 cantons. Éprouvé au banc, qui joue désormais `74`, `75` et `76` ensemble,
puis les rejoue : idempotent, **zéro chevauchement entre les trois**.

### La seule chose qu'il ne fallait pas recopier

`76` est le jumeau de `75`, section par section, numéros compris — pour que les
deux se lisent en regard. Il n'y a pas de § 2, et c'est délibéré :
`scrutin_cantonal` et `acte_effet` ne sont pas reconstruites, elles sont
reprises.

**La convention de date d'effet n'existe qu'à un seul endroit.** Deux fichiers
qui définiraient chacun la leur finiraient par diverger, et le jour où ils
divergeraient rien ne le dirait : chacun rendrait des chiffres cohérents, et la
base porterait deux règles sous un seul nom. C'est exactement la forme de
défaut que le dépôt cherche depuis le contrôle Gay — celle qu'aucune recette
interne ne voit.

La duplication de la MÉCANIQUE, elle, est assumée, et son coût est déclaré : un
correctif porté à `75` devra être reporté ici. Le § 10 f rend la chose
vérifiable en comptant ce que les deux couvrent ensemble. Au banc : 209 actes
posables porteurs d'une composition = 124 par `75` + 75 par `76` + 10 laissés à
1967. La somme est exacte, donc la paire est complète.

### La liste des salves est écrite en creux

Non pas « 1961, 1970, 1974… » mais « les années des actes posables, moins
celles de `75`, moins 1967 ». Ce n'est pas une élégance : une liste écrite à la
main se serait désynchronisée le jour où un décret de plus entrerait au
registre — et il en est entré **207 d'un coup** le 28 août au matin.

### 1967 est exclu, et c'est un point de méthode

Les six décrets du 20 juillet 1967 prennent effet à la naissance des
départements d'Île-de-France, le 1er janvier 1968. C'est un **fait juridique**,
pas le scrutin suivant : la convention y serait fausse de deux mois et demi. Et
ces cantons sont déjà en base par deux voies exactes — le recensement de 1968
pour cinq départements, `74` pour les Yvelines.

*Une convention ne s'applique pas là où un fait est disponible.* La règle vaut
au-delà : une convention est un pis-aller, et un pis-aller ne se généralise
jamais par confort.

### Ce que `76` doit démontrer, et que `75` ne pouvait pas

Ces salves sont pour la plupart plus proches de 1999. Si l'interprétation du
§ 11 est juste — les refus viennent de la distance au point de comparaison, pas
d'une lecture douteuse — alors le § 11 de `76` doit montrer **la même pente**.

C'est un contrôle d'un genre que le dépôt n'avait pas encore : il ne juge pas
un résultat, il juge une EXPLICATION. Au banc (couche 1999 synthétique, donc
sans valeur en soi) la pente est là : 67,6 %, 54,8 %, 41,8 %. Il faut la vraie
base pour conclure.

### Le banc a dû être élargi pour prouver quelque chose

Sa couche de 1999 ne contenait que les cantons des salves de 1973 et 1982.
`74` et `76` n'y posaient donc presque rien — 0 et 205 rattachements — faute
de cible à retrouver, et le banc les déclarait « joués » sans les avoir
exercés. En l'étendant à toutes les années : 33, 1 938 et 903.

*Un banc qui ne fournit pas de cible ne mesure pas un tir.* C'est la deuxième
fois en deux jours que le banc passe un test sans l'avoir couru — après la
Corse, qu'il avait fallu forcer.

## 28 août 2026 — `76` en base : le trou répond partout, et la couverture ajoutée est molle

873 rattachements sur 128 cantons. Aucun désaccord, aucune collision, aucune
commune disputée, aucun taux impossible, aucun chevauchement. Le § 10 f rend la
partition exacte : **209 actes posables porteurs d'une composition = 124 par
`75` + 75 par `76` + 10 laissés à 1967.**

### Le trou n'est plus un trou

`snapshot` répond désormais sur toute la période, et c'était l'objectif du
chantier depuis le 9 août :

| date | rattachements | cantons |
|---|---|---|
| 1968-06-01 | 32 842 | 2 911 |
| 1972-01-01 | 30 | 3 |
| 1974-01-01 | 1 228 | 178 |
| 1977-01-01 | 1 241 | 178 |
| 1980-01-01 | 1 241 | 178 |
| 1983-01-01 | 1 423 | 207 |
| 1986-01-01 | 1 241 | 185 |
| 1990-01-01 | 1 069 | 162 |
| 1993-01-01 | 970 | 154 |
| 1996-01-01 | 862 | 133 |
| 1998-06-01 | 679 | 105 |

Ce n'est pas une carte complète — 1 200 cantons sur 4 000 — mais **plus aucune
date entre 1968 et 1999 ne renvoie le vide**.

### La prédiction du § 11 est vérifiée, et la pente est plus raide

`76` devait montrer une meilleure résolution sans acte intercalé, ses salves
étant plus proches de 1999. C'est le cas :

| actes intercalés | `75` | `76` |
|---|---|---|
| aucun | 63,6 % | **67,6 %** |
| 1 ou 2 | 52,9 % | 55,7 % |
| 3 ou plus | 50,8 % | **34,5 %** |

Les deux premières lignes confirment l'explication. La troisième dit autre
chose : pour les salves tardives, avoir trois actes intercalés en si peu
d'années signale un département qui n'a pas cessé de bouger jusqu'en 1999 — le
signal est plus fort parce que l'intervalle est plus court. **Une même mesure,
deux régimes.**

### Le fait que je n'avais pas prévu, et qui compte le plus

`75` pose 37,0 % de ses rattachements avec un décalage possible de trois ans.
**`76` en pose 93,7 %.**

La cause est nette une fois cherchée : l'incertitude de série ne pèse que sur
les cantons MODIFIÉS, et la part des actes de création pure s'effondre avec le
temps.

| | lignes | « creation de cantons » |
|---|---|---|
| 1967 | 764 | **100,0 %** |
| 1973 / 1982 | 2 988 | 63,8 % |
| le reste (`76`) | 987 | **9,1 %** |

Les années 1985-1998 reposent donc presque entièrement sur une convention, là
où 1973 et 1982 reposaient pour près des deux tiers sur des créations dont la
date se déduit d'elle-même. La couverture ajoutée par `76` est réelle et
**molle**.

Cela ne condamne pas la pose : une incertitude déclarée vaut mieux qu'un trou
muet, et `p76_qualite` la porte ligne à ligne. Mais la conséquence est
opératoire, et elle est désormais écrite en tête du fichier : **toute lecture
des cantons entre 1985 et 1998 doit joindre `p76_qualite`**, faute de quoi elle
prendra une convention pour un fait.

C'est aussi une leçon sur la manière dont ce chantier a progressé : la
convention avait été éprouvée là où elle avait le plus de matière — les deux
grosses salves — et c'est justement là qu'elle coûtait le moins. *Éprouver une
règle sur son terrain le plus favorable ne dit pas ce qu'elle coûtera
ailleurs.*

### Un défaut de ma main, corrigé

Un `\echo` réécrit avait perdu son apostrophe fermante : `unterminated quoted
string` au § 10 b. Sans conséquence sur les données — psql signale et
poursuit — mais le banc ne l'avait pas vu, ses erreurs client passant dans le
même flux que les NOTICE. À surveiller.

## 28 août 2026 — `77`, et la source qu'on avait sous la main depuis vingt jours

`73` § 5 attendait depuis le 28 août « qu'il ne manque que la convention » pour
cinq transferts de commune. Il n'en manquait pas : il manquait de regarder.

Le fichier historique du COG 1999 — `Corhistoriq1999.txt`, modalité **43,
changement de canton** — porte **soixante-six** mouvements, avec pour chacun la
date de l'acte, celle de sa publication, **sa date d'effet**, et le canton
d'arrivée codé. Treize fois plus de communes que Légifrance, et la seule chose
qui manquait.

Le dépôt connaissait ce fichier depuis le 9 août. Il en avait tiré la
conclusion juste — 66 changements seulement, tous postérieurs à 1995, donc
aucune reconstitution de 1943-1995 par cette voie — et s'était arrêté là.
*Une source trop pauvre pour combler un trou peut être exactement assez riche
pour dater ce qu'on a déjà.* Une source se juge par question, pas en bloc.

### Les dates confirment `75` au lieu de le démentir

    Saint-Denis-des-Puits, Villebon (28)   décret du 10 avril 1995, JO du 15,
                                           EFFET LE 16 — le lendemain.
    Saint-Alban-de-Roche (38) et 60 autres décret du 26 février 1997, JO du 27,
                                           EFFET LE 1er AVRIL 1998.

Aucune n'est le premier tour du renouvellement, qui est la convention de `75`
et `76`. J'ai d'abord cru à un démenti. C'est l'inverse, et la raison tient à
la nature des actes : un **redécoupage** crée des cantons, donc la carte doit
exister au scrutin qui élit ; un simple **rattachement** de commune ne demande
aucune élection et prend effet quand l'acte le dit — le lendemain de la
publication en 1995, à l'installation du nouveau conseil (1er avril 1998, après
le second tour du 22 mars) pour la salve de 1997.

**Deux règles différentes parce que les actes sont de nature différente**, et
non parce que l'une aurait été mal choisie. C'est le premier élément extérieur
qui vienne éclairer la convention de `75` depuis qu'elle est posée — et il la
conforte.

### Le garde-fou a refusé de poser, et il avait raison

Premier passage au banc : « REFUS : 2 commune(s) déplacée(s) deux fois ».
Maxéville et Villers-lès-Nancy figurent deux fois dans le fichier de l'INSEE —
1er avril puis 13 novembre 1998 — **vers le même canton les deux fois**. Ce
n'est donc pas un double déplacement mais une seconde écriture du même fait,
probablement un rectificatif : la troisième commune du lot, Laxou, n'a qu'une
ligne.

Le garde-fou était mal posé, pas la donnée. Une commune A LE DROIT de bouger
deux fois ; ce qui est impossible, c'est qu'elle soit dans deux cantons au même
instant. Il porte désormais sur le **chevauchement** et non sur la répétition,
et les périodes s'enchaînent — chacune s'arrêtant au mouvement suivant. La
règle est écrite pour un cas qui n'existe pas dans ces données ; elle ne
manquera pas le jour où il se présentera.

### Ce que le banc n'a pas vu

`date_publication` est **vide** pour les deux actes de 1993, les seuls à
relever d'une convention. Sans repli, `valid_from` partait NULL à l'écriture.
Le banc ne l'a pas signalé parce que ses deux atomes n'étaient pas résolus : la
ligne était écartée plus tôt, pour une autre raison. *Un cas écarté en amont ne
teste pas ce qui l'attendait en aval.* On retombe sur le lendemain de la
signature, et un verdict nomme désormais le cas.

Et il a fallu, pour la troisième fois en deux jours, **fournir une cible au
banc** : sans unités nommées `DDNN` ni atomes pour ces communes, `77` rendait
54 « unité absente » et posait zéro, tout en étant déclaré joué.

### Résultat au banc

31 posés, 31 « place déjà occupée » — et ce n'est pas un échec : la salve de
1997 produit 61 de ces 66 mouvements, et c'est celle que `76` a posée. Un
transfert écarté à ce titre est une confirmation. Trois sans atome, un désaccord
avec le COG (perturbation voulue). Idempotent, zéro chevauchement entre `74`,
`75`, `76` et `77`.

## 28 août 2026 — `77` en base : 32 transferts, et zéro désaccord entre deux sources

32 rattachements posés — 30 datés par l'INSEE, 2 sous convention — sur
13 cantons, du 26 janvier 1993 au 13 novembre 1998. Aucun chevauchement, aucun
débordement, aucune trace sans qualité.

### Le contrôle qui comptait

**Zéro désaccord entre le fichier historique et le COG de 1999.** Les 66
mouvements désignent tous le même canton d'arrivée dans les deux fichiers, et
`24` n'a jamais lu `Corhistoriq1999.txt`. Deux écritures indépendantes de la
même administration se confirment sur la totalité du lot.

### Les 34 écartés sont une confirmation, pas une perte

Tous pour « place déjà occupée », et l'occupant est toujours `76`, à la date du
15 mars 1998 :

| canton | mouvements | exemple |
|---|---|---|
| 5442 | 11 | Agincourt |
| 5443 | 9 | Champenoux |
| 7434 | 7 | Allinges |
| 6631 | 4 | Canet-en-Roussillon |
| 0652 | 3 | Gorbio |

C'est la salve de 1997 vue par ses deux bouts : `76` a lu la COMPOSITION des
cantons d'arrivée, `77` lit le MOUVEMENT des communes vers eux. Les deux
disent la même chose, et la seconde n'a rien à ajouter là où la première a
déjà écrit. Un fichier qui pose peu parce qu'un autre a bien travaillé est un
bon fichier.

### Le seul écart, et il ne portait pas sur ce que je croyais

Le § 6 c comparait le canton **nommé** par le décret et le canton **codé** par
l'INSEE. Deux lignes concordent mot pour mot ; la troisième donne
« Bourgoin-Jallieu - Sud » côté décret et « Bourgoin » côté base.

Ce n'est pas un désaccord sur le canton — le code `3804` est confirmé par le
COG — mais sur **le champ que je lisais**. `unit.nom` est documenté depuis
`01_schema.sql` comme « dernier nom connu (dénormalisé, confort) », et il porte
ici le nom de 1870-1940. Le nom d'époque se lit dans `unit_version`, par la
fonction `unit_nom(unit_id, date)` qui existe depuis `03_functions.sql`.

Corrigé : le § 6 c affiche désormais les deux, le nom à la date et le nom
dénormalisé. *Un champ de confort n'est pas une source* — et un contrôle qui
lit le mauvais champ fabrique des désaccords qui n'existent pas. C'est
l'inverse exact du défaut habituel, et tout aussi coûteux : ici il aurait pu
faire soupçonner une lecture juste.

### Ce que `77` ajoute à la couverture

`snapshot(1993-06-01)` passe de 970 à 972, `snapshot(1998-12-01)` à 711 — les
deux transferts de 1993 et les trois de novembre 1998 sont précisément aux
extrémités où la couche était la plus mince. Trente-deux rattachements, mais
tous à des dates que rien d'autre ne renseignait, et **trente d'entre eux sur
une date qui est un fait**.

## 30 août 2026 — `80` joué : le report avant vaut 191 000 atome-années, et mon contrôle ne conclut pas

`sql/80_report_1968_avant_diag.sql`, lecture seule. Le mouvement symétrique de
`78`/`79` : partir du jalon de 1968 et monter jusqu'à la date d'effet du
premier acte de chaque département.

### Ce que le report avant rendrait

| | |
|---|---|
| départements | 98, dont 2 sans acte postérieur à 1968 |
| profondeur médiane | **4,7 ans** (moyenne 6,8 ; max 30) |
| département-années | **668** |
| atomes de 1968 | 32 842 |
| **à fenêtre entièrement libre** | **32 842 — la totalité** |
| couverture | **191 000 atome-années** |

**Aucune collision, pas une seule.** `79` descend jusqu'au DERNIER acte
(médiane ~1985), `80` monte jusqu'au PREMIER (médiane 1973,6) : les deux
fenêtres ne se touchent nulle part, sauf là où le premier acte est aussi le
dernier. Les 191 000 atome-années s'ajoutent donc en entier aux 422 838 déjà
posées — **+45 %**, sans qu'une ligne existante ait à céder la place.

Estimation d'hier, faite sur le CSV : 758 dép-années, médiane 5,6 ans. La base
dit 668 et 4,7. *Une estimation faite hors de la base la surestime de 13 % —
elle ignorait les actes que `acte_sans_effet` ne neutralise qu'en base.*

### La jonction, et les 19 départements déjà gagnés

| situation | départements | dép-années |
|---|---|---|
| un seul acte — les deux reports SE TOUCHENT | **19** | 172 |
| aucun acte — couvert de bout en bout | 2 | 60 |
| plusieurs actes — il reste un intervalle noir | 77 | 436 |

**Dix-neuf départements seraient couverts de 1969 à 1999 sans qu'aucun texte de
décret ait besoin d'être lu.** L'intervalle noir résiduel : 1 147 dép-années sur
77 départements, 264 actes à l'intérieur, dont **86 jamais dépouillés**. Il est
partout borné par les mêmes dates — premier acte 1973-09-23, dernier 1998-03-15
pour quatorze départements : ce sont les deux salves qui encadrent la période.

### Le § 2 ter dit 59 jours, et `78` en disait 183

L'écart signature → effet est de **59 jours** sur le PREMIER acte, contre 183
sur le DERNIER. Même convention, même population d'actes, trois fois moins.
La raison est dans la composition des deux bouts : le premier acte est presque
toujours la salve de 1973, signée en septembre pour un effet proche ; les
derniers actes sont dispersés. *Une moyenne calculée sur un bout de la
distribution ne vaut pas pour l'autre.*

### LE CONTRÔLE DU § 6 A ÉCHOUÉ, ET C'EST LE TEST QUI EST EN CAUSE

    1 acte 88,31 %  |  2 ou 3 actes 91,27 %  |  4 actes et plus 88,75 %

Pas de pente, et la catégorie du milieu est la plus haute. **Deux défauts, tous
deux de ma rédaction.**

**1. Le témoin n'existe pas.** La ligne « 0 acte » est VIDE : tout département
pourvu d'atomes en 1968 porte au moins un acte. La comparaison annoncée — sans
acte contre avec actes — n'a jamais eu de premier terme. *Une mesure sans
témoin n'est pas une mesure* : c'est mot pour mot la leçon du § 6 ter de `66`,
écrite dans ce dépôt il y a deux jours. Je l'ai refaite.

**2. La strate ne sépare pas ce qu'elle prétend séparer.** 74 départements sur
98 ont pour premier acte la salve du 23 septembre 1973 — le plus gros
redécoupage de la période. « 1 acte » n'est donc pas le groupe qui a peu bougé,
c'est le groupe qui n'a reçu QUE l'événement majeur. Le nombre d'actes ne
mesure pas le volume de changement.

***Un test qui ne pouvait pas montrer la pente ne réfute pas la pente.*** Lire
ce plateau comme une réfutation aurait été plus grave que l'avoir écrit : il
aurait condamné `79` et ses 36 296 rattachements sur une mesure incapable. Le
§ 6 est conservé tel quel dans le fichier — un résultat qui ne conclut pas
reste un résultat, et l'effacer masquerait le défaut au lieu de l'enseigner.

### Le contrôle qui peut conclure — § 6 quinquies, écrit, pas encore joué

Comparer **dans un même département** les atomes qu'un décret nomme
(`acte_composition.atome`) et ceux qu'aucun décret ne nomme. Même OCR, même
salve de 1973, même tout : le confondant du § 6 disparaît. Un test de signe
département par département (§ 6 sexies) ne suppose plus aucune homogénéité —
c'est exactement ce que le § 6 supposait à tort.

**Le biais restant a un sens connu** : un décret nomme les cantons qu'il crée
ou modifie, jamais ceux qu'il vide, donc des atomes réellement déplacés sont
classés « jamais nommés » et y font baisser l'accord. Le biais joue CONTRE
l'hypothèse. Un accord élevé chez les jamais-nommés serait donc acquis malgré
lui ; un accord faible pourrait n'être que lui. *Un biais dont on connaît le
sens n'invalide qu'une moitié des conclusions, et c'est celle qu'on cherche
qui survit.*

### À vérifier avant de conclure quoi que ce soit

Les 2 départements « sans acte postérieur à 1968 » n'ont AUCUN atome en 1968
(§ 6 bis rend zéro ligne). Ils viennent de l'`INSERT 0 2` qui complète
`r80_plafond` depuis `unit`, et ce sont probablement `2A`/`2B`, qui n'existent
pas dans la nomenclature de 1968. Leurs 60 dép-années sont alors fictives :

```sql
SELECT dep, plafond_effet, profondeur_annees FROM r80_plafond
 WHERE plafond_effet IS NULL;
```

**Réponse : ce sont `75` et `99`, pas la Corse.** Ma prédiction était fausse et
le défaut, lui, était bien réel. Le total du § 2 tombe de 668 à **608
dép-années** et la ligne « aucun acte — couvert de bout en bout » du § 5
disparaît.

Pour `75` ce n'est pas un accident : aucun décret cantonal parisien n'est au
registre, et c'est un FAIT — Paris ne relève pas du régime des décrets de
délimitation (`79` § 10 b/c). **Le fichier confondait « le registre ne dit
rien » avec « rien n'a bougé »**, alors que la première proposition peut aussi
vouloir dire que le département est hors du champ du registre. **`99` est identifié, et il découvre autre chose.**

***Un département sans atome n'est pas un département couvert*** — et un report
ouvert sur un ensemble vide affiche la profondeur maximale, donc se place en
tête de tous les classements. Le signal était là : le § 6 bis ne rendait aucune
ligne là où l'on attendait le témoin, et j'ai lu ce vide comme l'absence du
témoin plutôt que comme l'absence des départements eux-mêmes.

Corrigé : l'`INSERT` exige désormais un atome au jalon, et un § 2 zéro liste ce
qu'il écarte — *ce qu'on retire d'un compte doit rester visible quelque part.*

### `99` = la Meurthe, et `39_meurthe_1870.sql` n'est pas appliqué

`SELECT unit_id, nom FROM unit WHERE dep = '99'` rend Albestroff,
Château-Salins, Dieuze, Fénétrange, Lorquin, Phalsbourg, Baccarat, Bayon,
Blâmont, Lunéville-Nord/Sud, Nancy-Est/Nord/Ouest… : **les 29 cantons de la
Meurthe de 1870**, celle que l'annexion coupe en deux au 1er janvier 1871.

`99` est un artefact TRF-GIS — « un département qui n'a jamais existé », dit
`39_meurthe_1870.sql`, qui leur rend le **54** qu'ils portaient réellement. Sa
recette 1 attend « 99 absent ». **Or `99` est là.** `39` figure pourtant bien
dans `rejouer_apres_rebuild.sh` (étape 39) : il n'a simplement pas été rejoué
depuis le dernier `rebuild.sh`.

**Sans effet sur ce chantier** — la Meurthe meurt 97 ans avant le jalon de 1968,
et son exclusion du report avant est légitime pour cette raison-là, plus nette
que celle de Paris. Mais **tout regroupement par département sur 1870-1871 est
faussé sur la base actuelle**, et `39` n'a pas de table de trace : rien dans la
base ne dit s'il est passé. Même famille que `38_decret_1982_ain.sql`, que la
nouvelle recette de filiation de `24` fait ressortir « SANS TRACE ».

***Trois erreurs se sont croisées pour en révéler une quatrième.*** Un `INSERT`
trop large dans `80` a fait entrer un département sans atome ; le témoin vide du
§ 6 bis, que j'ai d'abord lu comme un défaut du test, était le signal ; et au
bout de la vérification il y avait une correction du 15 août qu'un rebuild avait
défaite en silence. *Un diagnostic bien tenu trouve autre chose que ce qu'il
cherchait — à condition qu'on aille au bout de ce qui l'étonne.*

À faire : `psql -d histgis -f sql/39_meurthe_1870.sql`, puis relire sa recette 1.

## 30 août 2026, soir — le report est validé : 94,9 % contre 33,5 %, et 49 départements sur 49

`80` rejoué après correction de l'`INSERT` et rejeu de `39`. Total ramené à
**608 département-années** sur 96 départements ; `75` seul est écarté, à
raison. Le § 6 quinquies, écrit ce matin après l'échec du § 6, a tourné.

### Le résultat

| population | atomes | accord 1968/1999 |
|---|---|---|
| **jamais nommé par un décret** | 30 306 | **94,90 %** |
| **nommé par un décret** | 2 536 | **33,49 %** |

**Écart : 61,4 points.** Et le test apparié ne laisse aucune place au doute :

| test de signe | départements | jamais mieux | nommés mieux | écart médian |
|---|---|---|---|---|
| tous (≥ 20 atomes de chaque côté) | 49 | **49** | **0** | **+62,1** |
| les 54 intégralement dépouillés | 28 | **28** | **0** | +58,3 |

**49 sur 49 dans le même sens.** Sous l'hypothèse nulle — le registre ne sait
rien — c'est 2⁻⁴⁹, soit une chance sur 560 000 milliards.

**Et le § 6 octies ne trouve rien.** Il était écrit pour lister les
départements en ANOMALIE, ceux où les jamais-nommés s'accorderaient moins bien
que les nommés. Ses vingt premières lignes, prises par écart croissant, vont de
**+13,5 à +56,6** : il n'y a pas une seule anomalie sur 49 départements.
*Une section qui cherche des exceptions et n'en trouve aucune a mieux travaillé
qu'une section qui en trouve.*

### Ce que cela valide, et ce que cela ne valide pas

L'hypothèse testée n'était pas « les communes que les décrets nomment ont
changé de canton » — ce serait une tautologie. C'était l'affirmation FORTE et
réfutable du registre : **« en dehors de ces 2 536 atomes, RIEN n'a bougé en
trente et un ans »**. Si le registre était incomplet, les communes déplacées
par des actes qu'il ignore se trouveraient chez les jamais-nommés et feraient
chuter leur taux. Elles n'y sont pas.

**`79` est validé en même temps que `80`** : les deux reposent sur la même
hypothèse, et c'est elle qui vient d'être éprouvée. Les 36 296 rattachements du
report arrière tiennent.

**La borne, et elle n'est pas 100 %.** Les 5,1 % de désaccord résiduel chez les
jamais-nommés mêlent trois choses qu'aucune requête ne sépare : l'OCR de 1968
(`59` : 79,9 % `ferme`, 3,1 % `canton_conteste`), les cantons **vidés sans être
nommés** par un décret — biais connu, de sens connu — et d'éventuels vrais trous
du registre. Le repère : 94,9 % se situe entre les 89,80 % de 1954 → 1968 et les
99,50 % de 1940 → 1954, sur un intervalle de 31 ans contre 14. C'est cohérent
avec tout ce que le dépôt a déjà mesuré.

Un département à regarder : **95, dont les jamais-nommés ne font que 78,1 %** —
le plus bas de la liste, et de loin. Val-d'Oise est né en 1968 de l'éclatement
de la Seine-et-Oise ; c'est très probablement le redécoupage de la région
parisienne, déjà rencontré au § 6 ter de `66` (Seine 10,0 %, Seine-et-Oise
46,4 %), et non un trou du registre. À vérifier avant d'écrire `81`.

### LA LEÇON, ET ELLE VAUT PLUS QUE LE RÉSULTAT

Le § 6 raté et le § 6 quinquies posent **la même question aux mêmes données**.
Le premier agrège au département et rend un plateau : 88,31 / 91,27 / 88,75.
Le second descend à la commune et rend 94,90 contre 33,49.

***L'agrégation au département a détruit un signal de 61 points.*** Ce n'est pas
seulement que mon premier test était mal construit : c'est que le registre parle
de COMMUNES, et qu'un département est un mélange de communes touchées et
intactes dans des proportions qui n'ont rien à voir avec le nombre d'actes.
Compter les actes, c'était mesurer la fréquence des décrets ; il fallait mesurer
leur EMPRISE. *Le bon dénominateur n'est pas celui dont on dispose, c'est celui
dont parle l'affirmation qu'on teste.*

**`81` peut être écrit.**

## 30 août 2026 — `81` écrit et éprouvé : zéro chevauchement entre les deux reports

`sql/81_report_1968_avant.sql` + `sql/banc_81.sh`. Le banc monte le schéma réel
(sans postgis, les deux `EXCLUDE` remplacées par des déclencheurs), pose les
données synthétiques de `banc_75_donnees.sql` et joue la chaîne **entière** :
72 → 74 → 75 → 76 → 77 → **79** → **81**, puis rejoue `81`.

| contrôle | résultat |
|---|---|
| chevauchements entre les deux reports | **0** |
| lignes posées par `81` | 3 013 |
| rejeu | 3 013 puis 3 013 — **idempotent** |
| `79` après le passage de `81` | 2 662 lignes, intactes |
| recettes 11 a à 11 e | toutes à zéro |

**La cible existait déjà, et elle est fausse exprès** : `banc_75_donnees.sql`
§ 5 pose un jalon de 1968 dont un sixième des communes est délibérément mal
rattaché. Le taux mesuré du § 5 de `81` y rend 84,2 % en moyenne — s'il avait
rendu 100 %, c'est la mesure qui aurait été cassée. *Trois fois en deux jours un
banc avait mesuré un tir sans cible ; celui-ci en avait une.*

### Ce que le banc a imposé, et que la lecture n'aurait pas trouvé

`p81_qualite` porte `pct_jamais_nommes`, le taux du § 6 quinquies recalculé
département par département : **chaque ligne posée sait ce que vaut le report
là où elle est posée**. C'est la colonne qui manque à `p79_qualite`.

Le banc a montré qu'elle ne suffisait pas. Un département où trois atomes
seulement sont jamais-nommés y affichait **66,7 %**, aussi précis d'apparence
que les 94,9 % nationaux et sans aucune valeur. `80` § 6 sexies s'en gardait par
un seuil de 20 ; ici le seuil aurait décidé à la place du lecteur. **Le
dénominateur voyage donc avec le taux** — `atomes_jamais_nommes` —, et le
§ 10 bis isole une tranche « trop peu d'atomes pour un taux ».

***Un taux sans son dénominateur est une opinion présentée comme une mesure.***
Quatrième fois que ce dépôt le paie : les villes à découper (270 puis 369 puis
119), le vote de `75` à 333 %, le § 6 de `80`, et maintenant celui-ci — le seul
des quatre à avoir été arrêté avant d'entrer en base.

### Deux symétries que l'écriture a rendues explicites

1. **La convention de date d'effet.** Elle raccourcit la fenêtre de `79` de
   183 jours et allonge celle de `81` de 59. Juste dans les deux cas, fondée sur
   le même fait : sur [signature, effet) c'est l'ancienne composition qui vaut.
2. **La borne des actes inconnus.** Pour `79`, qui remonte, la part risquée est
   SOUS la date de l'acte ; pour `81`, qui descend, elle est AU-DESSUS. Le
   mécanisme est inerte depuis le 29 août (plus aucun acte sans département)
   mais conservé : un acte non attribué peut reparaître, et rien d'autre ne le
   signalerait.

**Reste à jouer sur la vraie base.**

---

## 1er septembre 2026 — ANR-COMMUNES : la mesure avant la migration

L'embargo est levé, le jeu est sur le disque : `ANR_COMMUNES_22042026/`, deux
GeoPackages, 1,2 Go. Rien n'a été touché en base. La question posée d'abord est
celle qui décide de tout le reste : **ANR-COMMUNES réduit-il réellement les
3 945 km² de recouvrement, ou seulement les déplace-t-il ?**

### Le pont était déjà là

Le README annonce un `id_com` sans dire ce qu'il est, et ne mentionne aucun code
INSEE — de quoi croire qu'il faudrait rebâtir un appariement par nom, avec tous
les pièges déjà payés ailleurs.

C'est faux. **`id_com` est l'identifiant Cassini**, exactement la clé de
`atom.csv`. La vérification tient en deux chiffres :

| contrôle | résultat |
|---|---|
| atomes non-fraction retrouvés par `id_com = cassini` | 38 074 / 38 109 — **99,91 %** |
| accord des noms sur les atomes retrouvés | 36 446 / 36 571 — **99,66 %** |

Aucun appariement par nom n'est nécessaire. Le pont est une jointure d'entiers.

### Les 123 écarts de noms accusent la base, pas ANR

Sur 123 écarts, 67 ont une parenté lexicale — renommages ordinaires. Les 56
autres n'en ont aucune, et c'est là que c'est intéressant :

| cassini | INSEE | nom en base | nom ANR |
|---|---|---|---|
| 11767 | 57463 | METZ | Devant-les-Ponts |
| 12088 | 68224 | MULHOUSE | Dornach |
| 12140 | 44109 | NANTES | Doulon |
| 16104 | 76351 | LE HAVRE | Graville-Sainte-Honorine |
| 18407 | 17300 | LA ROCHELLE | Laleu |
| 15128 | 78361 | MANTES-LA-JOLIE | Gassicourt |

La base porte le nom **moderne de la commune absorbante**, ANR porte le nom
**historique de la commune absorbée**. Ce ne sont pas des erreurs
d'appariement : ce sont exactement les cas de polygone partagé qui fabriquent
nos recouvrements. **L'écart de nom est le symptôme du défaut qu'on cherche à
corriger** — et il désigne ANR comme plus fin, pas comme faux.

### La mesure du recouvrement

Intersection deux à deux par index spatial, sur les polygones valides à
l'année, seuil de bruit à 1 m².

| jeu | recouvrement total | même commune | communes différentes |
|---|---|---|---|
| `only_processed` 1870 | 1 214,2 km² (79 paires) | 890,6 (40) | **323,5 (39)** |
| `only_processed` 1940 | 496,4 km² (30 paires) | 379,1 (15) | **117,2 (15)** |
| `with_pseudo` 1940 | 495,2 km² (29 paires) | 379,1 (15) | **116,0 (14)** |

La colonne qui compte est la dernière. Le recouvrement « même commune » n'est
pas un conflit territorial : c'est un `id_com` portant deux polygones aux
fenêtres de validité qui se chevauchent — 41 cas à 1870, réglés par une règle de
choix, pas par un arbitrage géographique.

Le recouvrement réel entre communes distinctes est de **323,5 km² à 1870** et
**117,2 km² à 1940**, contre **3 945 km²** au niveau des atomes dans la base
actuelle. Réduction de **92 %** à 1870, **97 %** à 1940.

### Le contrôle d'emprise, avec son étalon

Une réduction du recouvrement ne vaut rien si elle s'obtient en perdant du
territoire. Il fallait un étalon dans la même projection — Lambert-93 déforme
les aires, et comparer une surface projetée aux 543 940 km² réels de la France
métropolitaine n'aurait rien prouvé.

GEOFLA 2014, cantons, même CRS : **548 489 km² projetés**, facteur 1,0084.

| jeu | somme des aires | − recouvrement | surface distincte | écart à GEOFLA |
|---|---|---|---|---|
| ANR 1870 `only_processed` | 550 045 | 1 214 | **548 831** | **+342 km² (+0,06 %)** |
| ANR 1940 `only_processed` | 549 327 | 496 | **548 831** | **+342 km² (+0,06 %)** |

Les deux années tombent sur la même valeur. **ANR couvre la France sans trou
mesurable et sans excès mesurable**, aux deux bornes de notre période.

Un troisième repère achève de situer ANR. Les trois emprises connues, toutes en
Lambert-93 :

| union | km² |
|---|---|
| notre base | 547 391 |
| Gay (polygones parfaitement disjoints) | 548 202 |
| GEOFLA 2014 | 548 489 |
| **ANR 1870 et 1940** | **548 831** |

ANR est **au-dessus de Gay de 629 km² et au-dessus de nous de 1 440 km²**, tout
en ayant douze fois moins de recouvrement que nous. Il couvre donc plus de
territoire avec moins de double comptage : c'est la signature d'une trame qui
comble des trous *et* défait des partages, les deux à la fois. C'est exactement
ce qu'on attendait de lui — et ce qu'aucune retouche de GEOFLA ne pouvait
donner, puisqu'une géographie de 2011 ne se découpe pas plus fin qu'elle-même.

### Ce qu'ANR ne donne pas

- **35 atomes sans `id_com`** : 20 arrondissements de Paris — déjà traités par
  la trame des quartiers, hors sujet —, 7 communes de Corse, 8 isolées
  (`sorties/anr/atomes_sans_polygone_anr.csv`).
- **754 atomes sans polygone valide à 1870** malgré un `id_com` présent, 357 à
  1940. À diagnostiquer avant migration. *(Chiffre faux, corrigé le jour même au
  § suivant : il était lu sur la couche `with_pseudo_territories`. Sur
  `only_processed`, c'est 490 et 102.)*
- **Les 333 fractions restent des fractions.** Leur `cassini` est présent dans
  ANR à 100 %, mais ANR livre le polygone de la commune-mère entière : il ne
  sait pas découper une commune partagée entre deux cantons. L'espoir consigné
  le 9 août — « ce jeu résoudra les 333 atomes-fractions » — **est déçu**. ANR
  règle le recouvrement, pas le fractionnement.
- **Les pseudo-territoires ne servent à rien ici** : sur notre période, la
  couche `with_pseudo_territories` n'apporte que 2 à 4 atomes de plus, et elle
  en compte 267 de *moins* à 1870 que `only_processed`. Les 4 239 polygones
  reconstruits par division en parts égales concernent presque tous des périodes
  hors 1870-1940. C'est `only_processed` qu'il faut charger, la seconde couche
  seulement marquée en regard.

### Fichiers produits, aucune écriture en base

`sorties/anr/` — `pont_cassini_anr.csv` (38 402 lignes, le pont complet avec
`Poly_ID` à 1870 et 1940), les trois tables de recouvrement,
`anr_id_com_multi_polygones.csv` (67 lignes, les cas à trancher),
`atomes_sans_polygone_anr.csv`.

### Le verdict

**La migration est justifiée.** Elle vaut 3 620 km² de recouvrement en moins à
1870, elle passe par une jointure d'entiers sans appariement par nom, et
l'emprise est contrôlée par un étalon externe dans la bonne projection.

Trois choses restent à régler **avant** de charger : la règle de choix pour les
41 `id_com` à deux polygones, le diagnostic des 754 sans polygone à 1870, et le
sort de la Corse. Et il faut consigner que les fractions ne sont pas réglées :
c'est la deuxième fois que ce dépôt fonde un espoir sur un jeu qu'il n'a pas
encore ouvert.

---

## 1er septembre 2026, suite — les trois verrous tombent

Les trois obstacles posés le matin même se sont révélés d'une autre nature que
prévu. Aucun des trois n'a demandé d'arbitrage géographique.

### Verrou 1 — les 41 `id_com` à deux polygones : trois causes, pas une

Le décompte de 41 mélangeait trois défauts sans rapport entre eux. Les séparer
suffit à les régler.

**Cause A, la borne partagée — 26 cas à 1870, 4 à 1940.** ANR écrit la fin d'un
polygone et le début du suivant sur la **même année** : Eaux-Bonnes est
`1790-1861` puis `1861-2020`. Tout test `Start <= année <= End` compte donc deux
fois toute commune dont l'édition tombe pile sur l'année interrogée. Ce n'est pas
un conflit de territoire, c'est une convention d'intervalle.

**Règle R1 : intervalle semi-ouvert `[StartDt, EndDt)`.** Elle épouse la
convention de date d'effet tranchée le 28 août — sur `[signature, effet)` c'est
l'ancienne composition qui vaut. Et surtout, **elle ne coûte rien** : 37 619
atomes pourvus à 1870 en fermé comme en semi-ouvert, 38 007 à 1940. *Zéro atome
perdu.* C'était la seule chose à vérifier avant de l'adopter, et il fallait la
vérifier : une règle d'intervalle qui gagne sur le recouvrement en perdant des
communes n'aurait été qu'un déplacement du problème.

**Cause B, le doublon exact — 9 cas à 1870, 11 à 1940.** Deux lignes, **même
`Poly_ID`, même empreinte MD5 de géométrie**. Bossay-sur-Claise, Cléré-du-Bois,
Cormicy. Rien à arbitrer. **Règle R2 : dédoublonnage sur `(Poly_ID, md5(geom))`.**

**Cause C, les variantes de section — 6 cas.** Même commune, même fenêtre, deux
ou trois géométries distinctes, suffixées `_0A_`, `_0B_`, `_0C_`. IoU de 0,51 à
0,75 : elles se recouvrent largement, ce ne sont donc pas des morceaux à réunir
mais des versions concurrentes.

Le test qui tranche n'est pas dans ANR, il est autour : **l'excédent du grand
polygone sur le petit est-il revendiqué par une commune tierce ?**

| id_com | commune | grand | petit | petit inclus dans grand | excédent revendiqué par un tiers |
|---|---|---|---|---|---|
| 5302 | Bourg-Lastic | 70,9 | 53,4 | 100 % | **0,0 %** |
| 11817 | Distroff | 16,9 | 12,5 | 100 % | **0,0 %** |
| 23450 | Montgaillard | 38,6 | 25,4 | 100 % | **0,0 %** |
| 26250 | Parves | 15,8 | 8,0 | 100 % | **0,0 %** |
| 31962 | Saint-Georges-des-Sept-Voies | 26,0 | 15,5 | 100 % | **0,0 %** |

Le petit est **inclus à 100 %** dans le grand, et l'excédent n'appartient à
personne d'autre. Retenir le grand comble donc un trou de couverture sans créer
un seul mètre carré de recouvrement. **Règle R3 : retenir la variante la plus
grande.** Décision tracée, réversible, et — c'est le point — *mesurée contre le
voisinage plutôt que choisie par convention*.

**Le sixième cas n'en était pas un — Beauvais.** Ses deux variantes `1943_0A` et
`1943_0B` sont revendiquées **à 100 % par Notre-Dame-du-Thil**, qui possède par
ailleurs son propre `id_com` (12335) et son propre polygone de 17,2 km². Beauvais
avant 1943 mesure 7,7 et 8,1 km² selon la variante, contre 33,0 km² après. Il n'y
a pas deux versions de Beauvais : **ANR a rangé sous Beauvais un morceau de la
commune qu'elle absorbera en 1943, et le vrai territoire de Beauvais avant 1943
est absent du jeu.** C'est un défaut d'ANR, isolé, à signaler en amont.
**Règle R4 : écarter les deux polygones ; Beauvais rejoint la liste des atomes
sans géométrie ANR.**

### Verrou 2 — les 754 atomes sans polygone : d'abord un chiffre faux

Le 754 du matin était lu sur `with_pseudo_territories`. Sur `only_processed`,
la couche qu'on a décidé de retenir, et sous la règle R1 : **490 à 1870, 102 à
1940**. Première leçon, déjà payée ailleurs : *un chiffre de diagnostic hérite de
la couche sur laquelle on l'a lu.*

Le tri décisif ne se fait pas dans ANR mais **contre notre propre base** : cet
atome est-il seulement vivant à cette date chez nous ? La fenêtre d'existence
sort de `membership_canton.csv`.

| | 1870 | 1940 |
|---|---|---|
| sans polygone ANR | 490 | 102 |
| dont **absents de notre base à cette date** — communes nées plus tard | 450 | 71 |
| **trou réel** | **40** | **31** |
| dont Paris (couvert par la trame des quartiers) | 20 | 20 |
| **hors Paris** | **20** | **11** |

Sur ces 20, la moitié n'est pas un trou d'ANR mais **notre poids mort** :
9 atomes portent un code INSEE déjà porté par un autre atome, et **ANR nomme le
survivant** — Fonteny, Venaco, Sebrazac, Goutrens, La Salvetat-Belmontet,
Saint-Hubert, L'Aubépin, Sébazac-Concourès, Roches-Prémarie-Andillé. Le jeu ne
crée pas un problème, **il en tranche un que nous portions depuis le début** (la
limite 7 de `METHODE.md`, les atomes doublons de la route `successeur`).

Reste **11 atomes réellement sans géométrie ANR à 1870** : 6 communes corses
dissoutes entre 1965 et 1974, Tauriac-de-Naucelle, Puilboreau, la 39524, plus
Aresches (ANR ne commence qu'en 1950) et Balaruc-le-Vieux (1886). **Règle R5 :
ces atomes-là gardent leur géométrie actuelle, marquée `source_geom = 'geofla'`.**
La trame sera hybride, et le dira.

### Verrou 3 — la Corse : complète, mais sans histoire

Le contrôle d'emprise s'applique aussi à une île. ANR livre pour la Corse à 1870
**360 polygones, 8 754 km²**. La Corse réelle fait 8 680 km² ; au facteur
Lambert-93 de 1,0084 établi le matin sur GEOFLA, on attend 8 753. **On tombe à un
km² près.** Il n'y a pas de trou corse dans ANR.

Mais le même jeu de 360 polygones porte **zéro édition historique** — tous sont
des `COMMUNE_...` valides de 1790 à 2020, contre 27,1 % de polygones édités pour
la France entière. **ANR affirme implicitement que la géographie communale corse
n'a pas bougé en deux siècles.** C'est faux — les six dissolutions de 1965-1974
le prouvent —, mais c'est sans effet sur 1870-1940, où aucun mouvement corse
n'est attesté chez nous. À déclarer, pas à corriger.

C'est exactement le défaut que ce dépôt avait déjà nommé chez lui à la limite 5 :
*un instantané projeté n'est pas une chronologie.* Il fallait vérifier qu'ANR
n'en souffrait pas — il en souffre, sur une île, et il faut le dire en légende.

Quant aux 7 atomes corses manquants : 6 sont les communes dissoutes après 1940,
hors période ; le septième est **Venaco, que nous portons deux fois** (cassini
20324 et 36152 pour le même 2B341). ANR ne connaît que 36152. **Aucun des sept
n'est un défaut d'ANR.**

### La remesure, qui est le seul verdict qui compte

Règles R1 à R4 appliquées, extraction rejouée, recouvrement recalculé.

| | avant règles | après règles |
|---|---|---|
| polygones à 1870 | 37 667 | 37 624 |
| `id_com` distincts à 1870 | 37 626 | **37 624** |
| recouvrement 1870 | 1 214,2 km² (79 paires) | **101,0 km² (11 paires)** |
| dont même `id_com` | 890,6 km² | **0,0 km²** |
| recouvrement 1940 | 496,4 km² (30 paires) | **101,0 km² (11 paires)** |
| dont même `id_com` | 379,1 km² | **0,0 km²** |
| surface distincte | 548 831 km² | 548 932 km² |

**Un polygone par `id_com`, exactement** — 37 624 pour 37 624. Le recouvrement
« même commune » n'est plus faible, il est **structurellement nul**. Et les deux
années retombent sur la même surface, 548 932 km², soit **+0,08 % de l'étalon
GEOFLA** : les 101 km² regagnés par R3 sont du territoire que personne ne
réclamait.

**Le résidu tient dans deux communes.** Sur les 101,0 km² restants,
**93,6 relèvent de Notre-Dame-de-Briançon** (Savoie), à qui ANR donne le polygone
de la future La Léchère tout en accordant le leur à Naves, Doucy, Celliers,
Pussy, Petit-Cœur et Les Avanchers ; **6,9 relèvent de Tours** face à
Joué-lès-Tours, Saint-Avertin et Saint-Pierre-des-Corps. **Deux communes font
99,4 % du reste.**

Tentative de correction par soustraction du parent : elle laisse 19 et 14 éclats
pour 4,7 et 9,5 km². **Écartée** — les contours ne sont pas emboîtés, seulement
voisins, et soustraire fabriquerait des artefacts là où il y a aujourd'hui deux
polygones honnêtes. Ces deux cas sont **nommés et déclarés**, pas rafistolés.

### Bilan des trois verrous

De 3 945 km² de recouvrement à **101,0 km²** : **−97,4 %**. Aucune des cinq
règles n'arbitre une frontière ; toutes se vérifient par un décompte. Et deux des
trois verrous se sont retournés en diagnostic de **notre** base : 9 atomes
doublons tranchés, un chiffre lu sur la mauvaise couche.

***Deux des trois obstacles à l'ingestion d'une source étaient des défauts de la
base d'accueil, que seule la confrontation révélait.***

Scripts et registres : `sorties/anr/anr_regles.py` (les règles R1-R4, exécutables),
`anr_trous_reels.csv` (les 40 et 31 atomes, avec verdict).

**Rien n'est encore chargé en base.** Ce qui manque maintenant est le `.sql`.

---

## 1er septembre 2026, fin — `82` écrit, et le banc trouve ce que la relecture n'avait pas vu

`sql/82_anr_geom.sql`, `sql/banc_82.sh`, `build/anr_variantes.csv`. Toujours
rien sur la vraie base : le banc tourne sur un PostgreSQL jetable.

### La décision de structure, et pourquoi elle n'était pas neutre

`atom_geom` donne **un** polygone par atome, pour toujours — c'est GEOFLA 2011,
qui n'a pas d'épaisseur temporelle. ANR en a une, et c'est l'essentiel de ce
qu'il apporte : une commune qui perd un hameau en 1875 a deux polygones
successifs. Écraser `atom_geom` aurait jeté cela pour un gain immédiat.

D'où **`atom_geom_anr(atom_id, periode, geom, poly_id, pseudo_t)`**, à côté et
non à la place, avec `EXCLUDE USING gist (atom_id WITH =, periode WITH &&)`.
Cette contrainte n'est pas une recette : une recette se lit après coup, une
contrainte refuse l'écriture. C'est elle qui rend structurellement impossible ce
que la mesure du matin avait constaté à la main.

Et `snapshot_geom_anr(date)` prend ANR quand il parle, retombe sur `atom_geom`
sinon (R5), en disant à chaque ligne combien d'atomes viennent d'où — `n_anr`,
`n_repli`. **Une unité dont `n_repli` est grand n'est pas fausse, elle est moins
bien datée, et il faut pouvoir le lire sans relire le fichier.**

### R3 avait un seuil, et le seuil décidait à ma place

Le premier jet écartait les variantes revendiquées à plus de 50 % par une
commune tierce, puis gardait la plus grande des autres. Il donnait à **Paris**,
sur 1790-1859, sa variante de 66,3 km² — revendiquée à 48,6 %, sous le seuil
d'un cheveu. C'est-à-dire **le Paris d'après l'annexion de 1860, reporté
jusqu'en 1790**, avalant la moitié de Vaugirard, de Clichy et d'Auteuil.

La règle réécrite ne compare plus à un seuil, elle compare les variantes entre
elles : **retenir la moins revendiquée ; à égalité, la plus grande.** Paris
reçoit alors la variante 0H, 34,1 km², que personne ne revendique — le Paris
d'avant 1860. Le seuil ne sert plus qu'à décider de l'**abstention**.

***Cinquième fois dans ce dépôt qu'un seuil tranche ce qu'il devait seulement
signaler.*** Et cette fois-ci il ne s'est pas trahi par un chiffre absurde : il
rendait 66,3 km² pour Paris, une valeur parfaitement plausible. Il a fallu
regarder QUI revendiquait.

Bénéfice de la réécriture : `R4`, le cas Beauvais, disparaît comme règle. Ce
n'est plus une exception codée en dur, c'est une **abstention** — comme Flipou
et Senneville, dont ANR a croisé les deux polygones. Trois groupes, même
mécanisme, aucune ligne spéciale.

### Le banc a trouvé deux défauts, dont un silencieux

**Le premier était bruyant.** `DROP FUNCTION IF EXISTS check_geom_anr();` ne
supprime pas `check_geom_anr(date)` : les signatures diffèrent. Le fichier
passait une fois et échouait au rejeu. Rejouable était écrit dans l'en-tête ; ce
n'était pas vrai.

**Le second ne disait rien du tout.** Le dédoublonnage R2 portait sur
`(poly_id, md5(géométrie))`. Le banc rendait 37 616 atomes à 1870 là où le
script Python en rendait 37 618. Deux.

La cause : **trois `Poly_ID` portent deux fois la même géométrie sur deux
fenêtres SUCCESSIVES** — `COMMUNE_…9759041` vaut 1790-1832 *et* 1832-2020, la
commune ayant été éditée à une date où sa forme n'a pas bougé. Ce ne sont pas
des doublons, ce sont deux périodes d'une même forme. La clé sans la fenêtre les
confondait et jetait la seconde, donc du temps de couverture, **sans que rien
n'échoue**. 69 lignes tombaient au lieu de 66.

***Un dédoublonnage qui oublie une dimension de la clé ne déduplique pas, il
tronque.*** Et il tronque en silence : moins de lignes, aucune erreur, aucune
contrainte violée. C'est la même famille que la cascade de `43` et que les sept
communes du garde-fou 6 — **les défauts de ce dépôt qui coûtent le plus cher
sont ceux où la base reste cohérente.**

Les deux défauts venaient de moi, pas d'ANR, et aucun des deux n'était visible à
la relecture. **Le banc a payé son écriture dès son premier passage.**

### Un banc pour un fichier entièrement géométrique

`75` et `81` se laissaient éprouver sans postgis parce qu'ils écrivaient des
rattachements. `82` n'écrit que des polygones. La sortie : dans
`sql/banc/banc_82_anr.csv`, **la géométrie est l'empreinte MD5 du WKB réel**, et
son aire voyage à côté.

Ce n'est pas un pis-aller. R2 porte précisément sur cette empreinte : au banc,
deux lignes que PostGIS jugerait identiques le sont aussi, et les 66 doublons
tombent exactement pareil. Le pont, lui, est éprouvé sur les **vrais** atomes —
`build/atom.csv` et `build/membership_canton.csv` chargés tels quels.

Ce que le banc prouve : la syntaxe, le pont, R1, R2, R3, l'exclusion des
fractions, l'absence de chevauchement, la rejouabilité. Ce qu'il ne prouve pas :
les 101,0 km² de recouvrement, qui demandent `ST_Intersection`. Ils ont été
mesurés hors base contre l'étalon GEOFLA, et c'est là qu'il faut les relire.
*Un banc qui ne peut pas mentir sur ce qu'il ne teste pas vaut mieux qu'un banc
complet qu'on ne peut pas faire tourner.*

### Le passage, au banc

```
variantes lues                    126   55 retenues, 6 en abstention
polygones posés                 45113   38 074 atomes pourvus
atomes doublons tranchés par ANR    6

1. chevauchements atome × période ......... 0
2. atomes pourvus ......................... 37 618 à 1870, 38 006 à 1940
3. R2 : 47 784 lignes → 47 718 ............ 66 doublons retirés
4. fractions pourvues ..................... 0
5. variantes écartées présentes ........... 0
6. rejeu .................................. 45 113 puis 45 113, idempotent
```

Les 37 618 ne sont pas les 37 624 polygones du matin : **six `id_com` d'ANR
n'ont aucun atome non-fraction chez nous**, 436 km². L'emprise attendue en base
est donc 548 395 km², contre 548 489 pour l'étalon GEOFLA — **−0,02 %**.

### Ce qui reste à faire, et qui n'est plus du travail de méthode

Charger la couche par `ogr2ogr`, jouer `82` sur la vraie base, lire
`check_geom_anr('1870-01-01')` et vérifier que le recouvrement y vaut bien
101,0 km² — le seul chiffre que le banc n'a pas pu contrôler.

---

## 1er septembre 2026, dernier volet — ANR hors 1870-1940, et la frontière qu'il ne connaît pas

ANR couvre 1790-2020. La question du soir : l'extension avant 1870 et la période
1943-2012, deux chantiers déjà au programme, viennent-elles de devenir moins
chères ? La méthode est celle du matin, appliquée à onze années.

### La table

| année | polygones | somme km² | part non terminale | recouvrement |
|---|---|---|---|---|
| 1790 | 39 425 | 545 074 | 28,1 % | — |
| 1815 | 39 157 | **548 835** | 26,2 % | **144,8** (28 paires) |
| 1841 | 37 780 | 548 896 | 19,4 % | — |
| 1870 | 37 624 | 548 932 | 16,0 % | **101,0** (11) |
| 1900 | 37 885 | 548 932 | — | — |
| 1940 | 38 012 | 548 932 | — | **101,0** (11) |
| 1954 | 37 994 | 548 961 | 13,9 % | — |
| 1968 | 37 686 | 548 940 | 12,6 % | **98,7** (9) |
| 1990 | 36 553 | 548 860 | 7,1 % | — |
| 2012 | 36 571 | 548 860 | 6,9 % | **0,0** (8) |
| 2019 | 34 838 | 548 843 | 0,0 % | — |

### Ce que la colonne de droite dit, et c'est la bonne nouvelle

**Le faible recouvrement n'est pas une propriété de 1870-1940, c'est une
propriété du jeu.** 145 km² au pire, en 1815 ; zéro mesurable en 2012, où les
huit paires ne sont que des contacts topologiques. Rien n'obligeait ANR à être
aussi propre là où nous n'avions pas regardé.

Et **Notre-Dame-de-Briançon est là à toutes les dates** — 89,7 km² à 1815 comme
à 1968, les mêmes quatre paires en tête. Ce n'est pas un défaut de période, c'est
un défaut d'identité qui traverse deux siècles : une seule commune, toujours la
même, et à elle seule l'essentiel du résidu partout.

### Ce que la colonne « part non terminale » ne dit PAS — correction

J'ai d'abord lu ces 28,1 % contre 6,9 % comme « la richesse éditoriale d'ANR est
en amont ». **C'est une sur-lecture, et il faut la corriger.** Un `Poly_ID` de
la forme `1943_0A_…` signifie « valable jusqu'en 1943 » ; un `COMMUNE_…` est le
polygone terminal. Plus on approche de 2020, plus les polygones sont terminaux
**par construction** — d'où les 0,0 % de 2019, qui ne mesurent rigoureusement
rien.

Ce que la colonne mesure vraiment : la part des communes qui changeront encore
de forme. Elle décrit **le rythme des remaniements communaux**, pas la qualité
documentaire d'ANR. Que ce rythme s'effondre après 1940 est un fait d'histoire,
pas une propriété du jeu.

Il en reste néanmoins ceci, qui vaut pour l'extension : à 1815, **10 259
polygones** ne sont pas terminaux, c'est-à-dire qu'ANR affirme pour eux une
forme pré-moderne précise au lieu de projeter celle d'aujourd'hui. C'est du
contenu, et il est là où nous n'avons rien.

*Un taux qui décroît régulièrement vers zéro est presque toujours un artefact de
construction avant d'être un fait.* Sixième fois.

### La frontière : ANR n'en a pas

L'emprise ne bouge pas d'un cheveu de 1815 à 2019 — 548 835 à 548 961 km², une
amplitude de 126 km² sur deux siècles. Une reconstruction qui suivrait les
frontières ne pourrait pas faire cela : la France de 1815 n'a ni la Savoie ni le
comté de Nice, et celle de 1871-1918 n'a pas l'Alsace-Moselle.

Deux épreuves, par le pont Cassini vers les codes de département :

| | 1815 | 1855 | 1870 | 1900 |
|---|---|---|---|---|
| Savoie + Alpes-Maritimes (sardes jusqu'en 1860) | **769 pol., 14 899 km²** | 774, 14 932 | 788, 14 945 | 796, 14 945 |
| Alsace-Moselle (allemande de 1871 à 1918) | 1 642, 14 565 | 1 689, 14 571 | 1 693, 14 575 | **1 701, 14 575 km²** |

**ANR dessine la France actuelle à toute date.** La Savoie y est française en
1815, l'Alsace-Moselle en 1900.

**Sans effet sur 1870-1940**, et pour une raison d'architecture : la carte se
construit depuis `membership`, pas depuis l'emprise d'ANR. Les 1 690 atomes
alsaciens-mosellans ont chez nous un trou de rattachement de 1871 à 1919 — c'est
même une des validations du chargement initial — donc `snapshot_geom_anr(1900)`
ne les demandera jamais. Le polygone existe dans `atom_geom_anr` et personne ne
l'appelle. **Le découplage géométrie/attribution paie ici sans qu'on l'ait
cherché.**

**Mais c'est un verrou pour l'extension avant 1870**, et il faut l'écrire avant
de commencer : poser 1815 depuis ANR sans rien faire d'autre, c'est annexer la
Savoie quarante-cinq ans trop tôt, 14 899 km² et 769 communes. La frontière
devra venir d'ailleurs — de la nomenclature d'époque, département par
département — et ANR ne la donnera pas.

### 1943-2012 : la géométrie y est déjà, et elle n'a rien coûté

`82` charge **tout ANR**, 1790-2020. La conséquence n'avait pas été énoncée :
la trame géométrique de 1943-2012 est donc posée par le même fichier, avec le
même pont, sans une ligne de plus. 37 994 polygones à 1954, 37 686 à 1968,
36 571 à 2012, pour un recouvrement de 98,7 km² à 1968 et nul à 2012.

**Ce qui manque à cette période n'est plus la géométrie, ce sont les
attributions** — le trou cantonal, les jalons de recensement, le registre des
actes. Le chantier ne change pas de nature, il perd une dimension.

### Bilan de la journée

Un jeu récupéré le matin, mesuré contre un étalon externe, réglé par cinq règles
dont aucune n'arbitre une frontière, codé, éprouvé au banc — qui a trouvé deux
défauts dont un silencieux —, et étendu le soir à deux siècles.

Recouvrement : **3 945 km² → 101,0**. Rien n'est encore joué sur la base.

---

## 1er septembre 2026, au premier passage en base — la recette ne rendait pas la main

`82` a chargé sans une erreur : 45 113 polygones, 126 variantes, 6 doublons —
**exactement les nombres du banc**. Puis il s'est arrêté sur `--- recettes à
1870 ---`, et il n'en est jamais revenu.

### Trois défauts dans une seule requête, qu'aucun banc ne pouvait voir

**Le premier : une CTE n'a pas d'index.** Les recettes lisaient
`WITH v AS (SELECT … WHERE periode @> p_date)`, puis joignaient `v` à `v` par
`ST_Intersects`. Or **une CTE référencée plusieurs fois est matérialisée** — et
une table matérialisée à la volée ne porte aucun index. `ST_Intersects` est
pourtant index-conscient, il porte son `&&` en lui ; simplement, il n'avait plus
d'index à consulter. PostgreSQL partait donc sur **37 618 × 37 618 paires en
boucle imbriquée**, chacune une intersection de multipolygones réels.

Le fichier ne s'est pas trompé de résultat. Il n'a pas rendu la main.

**Le deuxième :** `ST_Intersection` était calculé **deux fois par paire**, une
fois au `WHERE` pour le seuil de 1 m², une fois au `sum`. D'où la sous-requête
qui le calcule une seule fois.

**Le troisième**, tapi dans la ligne d'à côté : l'emprise passait par
`ST_UnaryUnion(ST_Collect(geom))` sur 37 618 multipolygones — précisément
l'opération qui avait fait tomber le script Python par épuisement mémoire le
matin même, et que j'avais alors contournée sans en tirer la leçon pour le SQL.
Remplacée par la somme des aires, dont on retranche le recouvrement déjà mesuré :
**même nombre, une ligne**. *Une union géométrique n'est pas nécessaire pour
connaître une surface quand on sait déjà ce qui se recouvre.*

### Pourquoi le banc ne pouvait rien dire

`banc_82.sh` remplace la géométrie par son empreinte MD5 et `ST_Intersects` par
une fonction qui renvoie `false`. La requête y est donc **bien formée et
instantanée** — le banc valide sa syntaxe et ne peut rien savoir de son coût.

***Un banc qui remplace une opération par un succédané gratuit ne teste plus son
prix.*** C'est la limite de fond de ce dispositif, et elle était écrite dans
l'en-tête du banc dès son premier jet : « ce qu'il ne prouve pas : le
recouvrement de 101,0 km², qui demande un vrai PostGIS ». Ce qui n'était pas
écrit, c'est que **ne pas pouvoir mesurer une chose, c'est aussi ne pas pouvoir
mesurer combien elle coûte**.

Le banc a tout de même servi une seconde fois : la requête corrigée introduit
l'opérateur `&&`, qu'il a fallu lui donner en succédané, et il a de nouveau
refusé la compilation jusqu'à ce que ce soit fait.

### La leçon d'architecture, qui vaut au-delà de ce fichier

Le vrai défaut n'est pas la CTE, c'est **d'avoir mis un contrôle long dans la
transaction qu'il contrôle**. `psql -1` tient tout ouvert : s'impatienter devant
une recette qui traîne, c'est faire un `ROLLBACK` sur un chargement qui, lui,
avait parfaitement réussi.

Le § 9 n'appelle donc plus les recettes. Il affiche ce qui est bon marché — la
trace, les six doublons — et **imprime les deux commandes à lancer après le
`COMMIT`**, sur des données acquises, où interrompre ne coûte rien.

***Un contrôle long n'a rien à faire dans la transaction qu'il contrôle.***

### Ce qui reste vrai

Le chargement lui-même n'a jamais été en cause : 45 113, 126, 6, aux trois
chiffres près ce que le banc annonçait. Les 101,0 km² restent à lire.

---

## 1er septembre 2026, le contrôle — 101,0 km², et un écart qui vaut mieux qu'une correction

```
recouvrement entre polygones, km²  |  101.0  |  attendu 101,0
somme des aires, km² projetés      | 548496  |  attendu 548 496
géométries invalides               |      0  |  attendu 0
atomes pourvus par ANR             |  37618  |  attendu 37 618
```

**Le seul chiffre que le banc ne pouvait pas rendre tombe au dixième près.**
Mesuré hors base le matin avec shapely et un index STRtree, retrouvé le soir en
base avec PostGIS et un index GiST, par deux chemins qui ne partagent pas une
ligne de code. De 3 945 km² à 101,0.

### Mais deux lignes divergent, et j'avais écrit les mauvais attendus

```
atomes non-fraction sans polygone ANR  |  533  |  attendu 491
dont vivants à cette date (trou réel)  |  486  |  attendu  40
```

486 contre 40. La cause n'est pas dans `82` : elle est dans **ce sur quoi
j'avais compté les 40**. Mes chiffres du matin sortaient de `build/atom.csv` et
`build/membership_canton.csv` — la base telle qu'elle sort de l'extraction. Or
la base réelle a été enrichie depuis par `11`, `15`, `41`, `44` et `46`, qui y
ont ajouté des atomes et **prolongé des rattachements vers l'arrière**.

***Un chiffre attendu mesuré sur les CSV d'entrée ne décrit pas la base qui en
est sortie.*** Septième confusion de dénominateur de ce dépôt, et la première
où le dénominateur fautif était le mien plutôt que celui d'une source.

### Ce que l'écart révèle, et qui vaut mieux que la correction

Les 486 ne sont pas des trous d'ANR. Ce sont, pour l'essentiel, des communes que
**notre base fait vivre en 1870 et qu'ANR ne fait naître que plus tard**.

`11_scission.sql` les y a portées, sur le pari qu'*une commune nouvelle reste
dans le canton de sa mère* — 414 atomes prolongés, pari mesuré contre Gay à
4 perdus sur 414. Sa table de trace porte même la colonne qui l'avoue :
`debut_reel`, « date d'apparition réelle de l'atome ». Nous savions que
c'étaient des inférences ; nous ne savions pas les compter à une date donnée.

**Là où ANR refuse un polygone, il ne se trompe pas : il refuse de suivre notre
report.** Et c'est exactement ce qu'on veut d'une source indépendante.

D'où `83_anr_ecart_couverture.sql`, en lecture seule : il décompose les 486 par
motif, croise avec `scission_trace`, et compare `debut_reel` — notre date, tirée
des mouvements INSEE — à la date de naissance qu'ANR donne à la même commune.
**Deux sources, une question, jamais confrontées jusqu'ici.**

Ce n'est plus un contrôle de chargement, c'est un **troisième contrôle
indépendant**, après Gay et HAC, et il porte sur une question que ni l'un ni
l'autre ne posait : *quelle part de notre couverture de 1870 est attestée, et
quelle part est reportée ?*

### Le banc a encore servi, et il a encore montré sa limite

`83` gardait l'accès à `scission_trace` derrière un
`CASE WHEN to_regclass('histgis.scission_trace') IS NULL THEN NULL ELSE …`.
Le banc n'a pas cette table, et il a refusé le fichier :

```
ERROR: relation "scission_trace" does not exist
```

**PostgreSQL résout les relations à l'ANALYSE de la requête**, avant d'évaluer
la moindre branche : un `CASE` ne protège pas d'une table absente. Il a fallu du
SQL dynamique dans un `DO`. *Un garde-fou évalué à l'exécution ne protège pas
d'une erreur d'analyse.*

Le banc a donc trouvé, en tout, **quatre défauts** que la relecture n'avait pas
vus : la signature du `DROP FUNCTION`, la clé de dédoublonnage sans la fenêtre,
l'opérateur `&&` manquant, et ce garde-fou-ci. Aucun n'était visible à l'œil.
Il n'a en revanche rien pu dire du coût de la recette de recouvrement — sa
limite de fond, déjà consignée.

### Où en est ANR, au soir du 1er septembre

Chargé, contrôlé, conforme. **`atom_geom_anr` : 45 113 polygones datés,
38 074 atomes pourvus, un polygone par atome et par date garanti par contrainte,
101,0 km² de recouvrement contre 3 945.** `atom_geom` et `membership` n'ont pas
été touchés.

---

## 1er septembre 2026, le troisième contrôle indépendant — ANR date les naissances, et `11` avait raison

`83` a tourné. Ce qui devait n'être qu'une explication d'écart est devenu la
validation la plus nette qu'ait reçue `11_scission.sql`.

### La décomposition des 486

| motif | n | dont posés par `11` |
|---|---|---|
| **ANR ne fait naître la commune qu'après cette date** | **379** | **359** |
| trou interne dans la chronologie ANR | 69 | 68 |
| Paris — trame des quartiers | 20 | 0 |
| ANR ignore cet `id_com` | 15 | 0 |
| ANR arrête la commune avant cette date | 3 | 0 |

**448 des 486 sont des atomes que `11` a portés en arrière.** L'écart n'était
pas un trou d'ANR : c'était notre report, vu de l'extérieur.

### Le contraste, qui a la forme d'une preuve

| origine | n | qu'ANR fait naître après 1870 | accord |
|---|---|---|---|
| **posé par `11`** | 427 | 359 | **84,1 %** |
| non posé par `11` | 59 | 20 | **33,9 %** |

Même signature que la validation du report de 1968 : 94,9 % contre 33,5 %.
L'affirmation testée n'est pas la tautologie « les communes que `11` a
prolongées n'existaient pas encore » — `11` ne s'est jamais demandé si elles
existaient, il a prolongé tout atome qu'un canton réclamait sans en avoir. Ce
qui est testé, c'est que **le sous-ensemble qu'il a choisi coïncide avec celui
qu'une source étrangère fait naître plus tard.** Il coïncide à 84 % contre 34 %.

### Et les deux dates tombent sur la même année — 357 fois sur 359

Le § 4 rendait d'abord un écart moyen de **−14,8 ans**, ce qui semblait ruiner
l'affaire, alors qu'il annonçait dans le même souffle **357 lignes sur 427
tombant sur l'année exacte**. Les deux ne pouvaient pas être vrais ensemble.

Ils l'étaient. La moyenne mêlait deux populations : les 359 vraies naissances, et
les **68 trous internes, pour lesquels `anr_debut` n'est pas une date de
naissance mais le début de la période d'AVANT le trou — souvent 1790.** Comparer
1790 à une création de 1880 fabrique un écart de −90 ans, et soixante-huit
lignes de cette sorte suffisent à noyer trois cent cinquante-sept accords
parfaits.

Le § 4 sépare désormais par motif. Sur les seules naissances : **357 sur 359,
soit 99,4 % d'accord à l'année près.** `debut_reel` vient des mouvements INSEE,
`anr_debut` des éditions d'ANR ; les deux chaînes n'ont pas une ligne de code
commune.

***Une moyenne calculée sur deux populations qu'on n'a pas séparées ne décrit
aucune des deux.*** Le compte exact était affiché à côté, et il disait le
contraire ; c'est lui qui avait raison.

### Ce que le § 5 a trouvé sans qu'on le cherche : ANR a des trous, et ne le dit pas

Vingt communes des Ardennes dans la liste des « inexpliqués », toutes avec la
**même signature** :

```
20484  1790-1865 | 1879-2020
 8408  1790-1828 | 1871-2020
 9278  1790-1828 | 1871-2020
12222  1790-1828 | 1871-2020        ← quarante-trois ans sans polygone
```

Un polygone avant, un polygone après, **rien entre les deux**. La commune n'a
pas disparu — elle est dans GEOFLA aujourd'hui. C'est ANR qui ne dit rien de
1828 à 1871.

Mesuré sur tout le jeu, hors base :

| | |
|---|---|
| `id_com` ayant au moins un trou de chronologie | **532 sur 40 572 — 1,31 %** |
| années-communes non couvertes | **11 113** |
| largeur médiane d'un trou | **12 ans** |
| trous couvrant 1870 / 1900 / 1940 / 1954 / 1968 | **75 / 17 / 6 / 0 / 2** |

Le phénomène est petit et **concentré sur le début de notre période** — 75 en
1870, six en 1940, aucun en 1954. La largeur de 43 ans revient 21 fois : c'est
le lot des Ardennes.

**R5 les rattrape déjà** : ces atomes gardent `atom_geom`, et `n_repli` le dira
sur la carte. Mais c'est une cinquième limite d'ANR à déclarer, à côté des
fractions, de la Corse, de la frontière et des 101 km² — et la seule qui ne se
voie qu'en interrogeant une date à l'intérieur du jeu plutôt qu'à ses bornes.

### Ce que cette journée a produit

ANR chargé et contrôlé, recouvrement divisé par trente-neuf, et **un contrôle
indépendant de plus** : le report arrière de `11` cesse d'être un pari
raisonnable pour devenir une inférence corroborée par une source qui ne l'a
jamais vu. Ce qui avait commencé comme un écart de recette à expliquer.

---

## 1er septembre 2026, la carte — l'affirmation en tête d'`export_web.py` était devenue fausse

`82` chargé et contrôlé, restait à faire parler la trame sur la carte. Je m'y
suis mis en croyant à un branchement d'une ligne : remplacer `atom_geom` par
`snapshot_geom_anr`. C'était sous-estimer ce que la table datée change.

### Ce qui bloquait, et qui n'était pas dans le SQL

`export_web.py` portait depuis toujours cette phrase en tête :

> La géométrie d'un atome ne change jamais — `atom_geom` est posée une fois pour
> toutes. Ce qui change d'une année à l'autre, c'est le *rattachement*.

Toute l'architecture du fichier en descendait. `communes.json` s'écrivait **une
fois par département** parce qu'un atome n'avait qu'un polygone. La signature
d'une configuration était le md5 de la **seule composition**, parce que seule la
composition bougeait. Et `annees_candidates()` ne lisait que les bornes de
`membership` et d'`unit_version`, parce qu'aucune autre borne n'existait.

`atom_geom_anr` rend les trois faux d'un coup. Brancher la nouvelle source sans
toucher au reste aurait produit une carte qui se trompe **en silence** :

- deux années de même composition mais de formes différentes auraient partagé le
  même `c_<sig>.json`, donc le contour cantonal de l'une aurait été affiché pour
  l'autre ;
- une édition de polygone tombant une année sans mouvement administratif
  n'aurait **jamais été échantillonnée** — le changement n'aurait pas existé
  dans l'export, et aucune recette n'aurait pu le remarquer, puisque rien
  n'aurait été demandé à la base.

***Une borne qu'on n'interroge pas ne produit pas une erreur, elle produit un
silence.*** C'est le même mécanisme que le trou de la couche circo et que le
0 rattachement au 1er juin 2012 : le défaut n'est pas dans ce qu'on calcule,
il est dans ce qu'on a omis de demander.

### Ce qui est posé

`communes.json` porte maintenant, par atome, une **liste de versions**
`v: [{a, k, c, g, r}]` — `a` la première année où la version vaut, `r` le
drapeau de repli. La signature couvre la composition **et** les `poly_id` en
vigueur. `annees_candidates()` lit la troisième famille de bornes.

Et les versions **comblent explicitement les intervalles découverts**, au lieu
de supposer qu'une source datée est continue. Les trois cas sont distincts et
tous les trois se produisent : avant la première édition d'ANR (le report
arrière de `11`), **entre deux éditions** (les 532 trous de chronologie), après
la dernière. Le deuxième est celui qu'on ne voit qu'en interrogeant l'intérieur
du jeu ; une boucle qui aurait pris le premier et le dernier segment aurait
affiché la forme de 1828 en 1850 comme si elle était attestée.

Le cas dégénéré a demandé une correction en cours de route. Ma première version
sautait un intervalle sans géométrie. Mais la page tient la version en vigueur
jusqu'à la suivante : sauter, c'était laisser le polygone précédent à l'écran.
Un intervalle vide s'écrit donc **comme vide**, `g: null`, et la commune n'est
pas dessinée. ***Ne rien écrire n'est pas neutre quand le lecteur en aval
prolonge.***

### Deux signatures, et elles ne font pas le même travail

La signature d'entrée est conservatrice : une commune qui perd un hameau au
profit d'une voisine du **même canton** change de `poly_id` sans déplacer le
contour cantonal d'un pouce. Signer sur l'entrée seule écrivait deux fichiers
identiques sous deux noms.

Le nom de fichier est donc devenu le md5 du **contenu sérialisé**, la signature
d'entrée ne servant plus qu'à décider ce qu'il faut recalculer. Le banc de
fumée le montre : sur un cas fabriqué, **six compositions calculées, deux
fichiers écrits**. ***Une signature d'entrée dit ce qu'il faut recalculer, une
signature de sortie dit ce qu'il faut réécrire ; prendre l'une pour l'autre
coûte soit des calculs inutiles, soit des fichiers en double.***

### La coïncidence des limites, qui se durcit d'un cran

Le fichier prenait déjà soin d'appliquer aux atomes et aux unités dissoutes le
même ordre d'opérations — c'est ce qui fait coïncider limites cantonales et
limites communales au pixel près. Avec la trame datée il faut la même **source**
et pas seulement le même ordre : sinon un canton dessiné sur la forme d'ANR
longerait des communes dessinées sur la forme de 2011, et la lisière serait un
artefact de tuyauterie. Les trois requêtes partagent maintenant une expression
unique, `ST_MakeValid(ST_SnapToGrid(coalesce(ga.geom, ag.geom), grille))`, et le
banc vérifie cette identité sur le **texte** des requêtes — la seule chose qu'un
banc hors base puisse en dire.

### Le repli est écrit, pas subi

Une carte hybride qui ne dit pas où elle est hybride ment par omission. Chaque
version porte `r`, chaque unité porte `n_anr` et `n_repli` — le pendant exact de
ce que rend `snapshot_geom_anr()` — et la page affiche les trois faits
séparément : l'export sans épaisseur, les communes en repli à cette année, les
communes qu'aucune source ne sait dessiner. La fiche d'une commune dit d'où
vient sa forme et sur quelles années elle vaut.

Un gain non cherché, au passage : l'empreinte de regroupement devient **datée**.
Deux atomes que la trame de 2011 confondait sous un même polygone peuvent
désormais en avoir deux distincts en 1870 — la clé d'ANR étant le code Cassini,
c'est précisément le mécanisme qui fait tomber le recouvrement de 3 945 à
101 km², et la carte le montre maintenant commune par commune.

### Parallélisme

Un processus par département, `--jobs`, une connexion par worker ouverte
**après** le fork (contexte `spawn` : une connexion psycopg2 transmise par
`fork` partage ses descripteurs, et deux processus liraient à tour de rôle la
réponse de l'autre). Le découpage s'arrête au département parce que c'est la
seule unité qui écrive dans un dossier à elle : deux processus se partageant les
configurations d'un même département devraient s'accorder sur le dédoublonnage
par contenu, donc se parler.

Un département qui échoue rend son erreur comme une donnée, le parent la compte
et le script sort en 1. Un export incomplet qui ressemble à un export complet
serait pire qu'un export absent.

### Ce qui reste à contrôler, et que rien d'écrit ici ne contrôle

`cartes/banc_export_web.py` couvre les fonctions pures — la construction des
versions, la convention du 1er décembre, la forme des requêtes. Il ne dit
**rien** des contours dissous ni du coût des requêtes, exactement comme
`banc_82.sh` ne pouvait rien dire des trois pièges de coût du § 7. Deux choses
ne se vérifieront qu'après un export réel :

1. le **poids** — la signature élargie multiplie les configurations, et il faut
   voir de combien (attendu : 92 Mo → deux à trois fois plus sur le disque, sans
   changement du coût par requête, les fichiers restant adressés par contenu) ;
2. la **coïncidence visuelle** des limites cantonales et communales sur une
   année où ANR édite un polygone — c'est là, et seulement là, que se verrait
   une erreur d'ordre d'opérations.

---

## 2 septembre 2026, le rangement — 96 % du bruit venait d'un seul dossier

Le dossier n'était pas en désordre : `LISEZMOI.md` en décrivait l'organisation
avec exactitude, et chaque chantier avait sa note. Le désordre était **dans
git**, et il tenait presque entier à une seule cause.

`git status` rendait 4 499 lignes : 1 251 suppressions, 2 912 non-suivis,
335 modifiés. De quoi rendre l'outil inutilisable — on ne relit pas 4 499
lignes pour voir si on a oublié un fichier. Sur ces 4 499, **4 156 venaient de
`cartes/web/donnees/`**, l'export de la carte interactive : 1 546 fichiers,
3,3 Go, suivis par inadvertance, et qu'`export_web.py` réécrit intégralement à
chaque passage. Chaque export produisait donc mille suppressions et deux mille
ajouts, tous sans intérêt, qui noyaient les cent dix fichiers de travail
réellement en attente.

`git rm -r --cached cartes/web/donnees/` ramène le compte à 188 non-suivis et
35 modifiés — et rien ne quitte le disque.

### Deux mécanismes de git qu'il vaut mieux connaître avant qu'après

**Git n'applique pas ses motifs d'exclusion à un fichier qu'il suit déjà.**
`sorties/` figure dans le `.gitignore` depuis le premier jour, et
`sorties/rapport_chargement.txt` était pourtant suivi : entré avant la règle, il
lui a échappé pour toujours. Écrire la règle ne rattrape rien, il faut
`git rm --cached`. C'est exactement le mécanisme qui a laissé `cartes/web/`
grossir sous une règle qui aurait dû le prendre. Corollaire de méthode : après
avoir ajouté un motif, **vérifier que ce qu'il vise n'était pas déjà suivi.**

**Un `#` en fin de ligne ne commente pas un `.gitignore`.** J'ai d'abord écrit
`/JORF/    # 2,6 Go — PDF des Journaux officiels`, en croyant documenter chaque
règle sur sa ligne. Le `#` n'ouvre un commentaire qu'en début de ligne : le
motif était donc la chaîne entière, espaces et texte compris, et n'ignorait
rien. Rien ne le signale — ni erreur, ni avertissement, et le fichier a l'air
juste. Découvert parce que les 1,2 Go d'`ANR_COMMUNES_22042026/` figuraient
encore parmi les fichiers à ajouter. **Un `.gitignore` se vérifie par
`git check-ignore -v`, jamais à l'œil.**

Piège dans le piège : `git check-ignore sources` répond « non ignoré » alors que
`git check-ignore sources/` répond « ignoré », et un chemin déjà suivi ne
remonte jamais. L'outil ne ment pas, il répond à une autre question que celle
qu'on croit poser.

### Ce que le `.gitignore` ne connaissait pas

Quatre dossiers reçus depuis le 14 août — `JORF/` (2,6 Go),
`ANR_COMMUNES_22042026/` (1,2 Go), `polynesie/`, `42-Vasserot_quartiers_v1L93/`
— n'étaient ni suivis ni ignorés : à un `git add -A` d'entrer dans le dépôt.
La règle qui les visait, `sources/`, ne les atteignait pas puisqu'ils n'y sont
pas. **Une donnée reçue qui n'arrive pas dans `sources/` échappe à la règle qui
la visait**, et doit donc être ignorée nommément, le jour de son arrivée.

### Le rangement proprement dit, qui est la plus petite partie

Trois entrées de racine étaient mal placées, et une quatrième mal nommée :

* le tableau de correspondance de 2012 (7,7 Mo) est une donnée reçue — il
  rejoint `sources/` ; aucun script ne le lisait par son chemin ;
* `BDADMIN-NC.gdb` et les deux PDF du DITTT (CGU, lisez-moi) forment un tout et
  deviennent `nouvelle_caledonie/`, à côté de `polynesie/` — que le voisinage
  dise la provenance ;
* **`1986 gaudilliere`** — sans extension, avec un espace, invisible à un glob,
  impossible à citer sans guillemets — devient
  `circo/notes_1986_gaudillere.txt`, auprès du chantier qui s'en sert. C'est la
  transcription du § 5 de l'atlas, la source qui tranche les cantons partagés
  entre circonscriptions en 1986 : elle méritait mieux qu'un nom de fichier
  provisoire à la racine.

Neuf `__pycache__` supprimés, régénérés à la prochaine exécution.

### Un correctif au correctif

Premier jet du motif : `cartes/web/`. Il emportait `index.html`, `servir.py` et
le `LISEZMOI.md` de la carte — 90 Ko de code et de documentation écrits à la
main, qu'aucun script ne refait. `RESTE_A_FAIRE.md` § 5 le disait en toutes
lettres et je l'avais manqué. Seul `donnees/` est régénérable ; c'est aussi lui
seul qui pèse les 3,3 Go. **Exclure au plus près : un motif trop large ne coûte
rien tant qu'on ne l'a pas essayé, et tout dès qu'on l'applique.**

### Où en est le dépôt

Huit commits, un par chantier : le `.gitignore` et le détachement, les rapports
de `sorties/`, le rangement de la racine, `sql/` (les 37 étapes 47 à 83 et les
trois bancs), `cantons/` (la moisson et la lecture en colonnes), `circo/`
(l'annexe VI et Paris jusqu'à 1815), les deux recensements, `jorf_txt/` et le
banc de l'export.

Le dépôt suivait 1 744 fichiers pour 932 Mo. Il en suit 384 pour 91 Mo.

**Correctif, écrit après vérification** : j'avais d'abord annoncé « une
vingtaine de Mo » sans mesurer, par simple soustraction des 3,3 Go détachés.
C'est 91 Mo, et l'écart n'est pas un détail — il dit où va réellement le poids :

| | |
|---|---|
| `jorf_txt/` | 52 Mo, les 86 JO océrisés — **57 % du dépôt à eux seuls** |
| `circo/` | 11 Mo |
| `sql/` | 8,1 Mo, dont 6,5 pour les jeux d'essai de `banc/` |
| `cog1954/`, `cog1968/` | 14 Mo à eux deux |
| tout le reste | 6 Mo |

Le principe affiché en tête du `.gitignore` — *« le dépôt doit rester léger,
quelques Mo »* — reste donc contredit d'un ordre de grandeur, et par une seule
cause. La question à trancher un jour n'est pas de savoir si 91 Mo est
acceptable, mais si l'OCR nu des JO doit vivre dans le dépôt ou à côté : c'est
une donnée intermédiaire, coûteuse à refaire mais non reproductible à
l'identique, et le dépôt n'a pas de catégorie pour ça.

Une décision de tri, au passage : les `jorf_txt/*_col.txt` sortent du dépôt
(35 Mo) parce que `jorf_colonnes.py` les refait en quelques minutes depuis les
PDF — même statut que les `_raw.txt`, déjà exclus. Les `.txt` nus **restent** :
leur OCR dépend de la version de tesseract et ne se reproduirait pas à
l'identique. Ce n'est pas le poids qui tranche, c'est la reproductibilité.

---

## 2 septembre 2026 (soir) — la couture de la trame hybride

Adrien signale un défaut de la carte « depuis l'ajout d'ANR », dans l'Ain, entre
Villieu-Loyes-Mollon et Meximieux : un double trait noir là où il n'en faut
qu'un.

### Ce que c'était

L'atome `40689` est Villieu. **ANR le fait naître en 1897**, par détachement de
Loyes, et il a raison. Notre base le fait vivre dès 1870 — report arrière de
`11`. ANR refusant le polygone, R5 retombe sur `atom_geom`, c'est-à-dire le
polygone **GEOFLA 2011 de Villieu-Loyes-Mollon, la fusionnée de 1973** : 15,84
km² posés sur Loyes (9,63 des 10,11) et Mollon (5,38 des 5,66), plus 0,198 km²
qui débordent sur Meximieux. À 1900 ANR pourvoit Villieu et le recouvrement
avec Meximieux tombe à zéro exactement.

Le retournement vaut d'être noté : **l'artefact apparaît là où ANR a réussi.**
Avant `82`, Loyes et Mollon étaient `sans_geom` — disparues avant 2011, pas de
repli — et le polygone de la fusionnée tenait leur place sans que rien ne
dépasse. ANR leur a rendu leur territoire ; le repli, lui, n'a pas lâché le
polygone moderne.

### L'ampleur, et la recette qui ne pouvait pas la voir

Mesuré sur `cartes/web/donnees/`, à 1870, entre communes ordinaires :
ANR × ANR 1,0 km² sur 2 353 paires ; **ANR × repli 4 542,8 km² sur 1 618
paires** ; repli × repli 0,0. 72 départements, 393 superpositions franches
(4 267 km²) et 1 225 lisières (275 km²). À 1940, 1,3 km² : la couture s'éteint
à mesure qu'ANR fait naître les filles.

`check_geom_anr` joint `atom_geom_anr` à elle-même. Ses 101,0 km² sont exacts —
et ne décrivent pas la carte, qui dessine `coalesce(ANR, atom_geom)`.
**Une recette qui mesure la source ne mesure pas le composite qu'on en tire.**
`ETAT.md` § 2.1 porte désormais les deux lignes.

### Trois règles écrites, deux jetées

Adrien tranche : la fille garde son sol, on découpe la mère ; les fractions
restent hachurées comme aujourd'hui ; le nettoyage vit en base.

**Premier jet — le repli comme territoire de la fille.** Lui laisser son
polygone GEOFLA puis le retrancher de la mère donnait, dans l'Ain : Loyes
10,08 → 0,48 km², Crépieux-la-Pape 14,95 → 11,56, Rillieux-la-Pape 11,34 →
0,08. `atom_geom` porte le polygone de la commune **terminale** de la lignée
Cassini ; pour `40689` c'est la fusionnée de 1973, qui contient sa propre mère.
*Un polygone de repli dit où une commune est aujourd'hui, pas quel sol elle
tenait alors.*

**Deuxième jet — combler les trous de chronologie d'ANR** en reportant le
dernier polygone antérieur. Sur l'Aveyron, les dix plus grosses faces disputées
portaient toutes ce motif : Saint-Beaulize contre Fondamente, La Serre contre
Saint-Sernin-sur-Rance, Les Albres contre Aspriéres. Ces communes ont été
**réunies à leur voisine puis rétablies** — le chantier `41` — et le trou d'ANR
est un fait. Reporter le polygone d'avant la réunion par-dessus la voisine qui
l'avait absorbée recréait le double comptage qu'on venait d'ôter.
*Un trou dans une source datée peut être ce qu'elle a de plus exact.*

**Ce qui reste, une règle unique.** `territoire(fille, D) = voisin(D) −
voisin(Y′)`, Y′ étant la prochaine apparition de la fille chez ANR et le voisin
celui dont la chronologie s'y coupe. Naissance et rétablissement sont le même
événement vu d'ANR. Le critère de désignation de la mère — une coupure ANR le
même millésime — retient 86,5 % des superpositions franches et 4,8 % des
lisières : il sépare les deux familles **sans qu'on lui ait donné de seuil**.

### Deux pièges du banc

**Le cadre.** Le premier treillis, calculé département par département, offrait
les **478 km² du département de la Seine** aux communes de Seine-et-Oise, et
l'enclave des papes à la Drôme : un territoire enclavé ressemble à un trou quand
le cadre s'arrête au département. D'où l'anneau de contexte de 20 km. *Un trou
n'est un trou que dans un cadre assez large pour contenir ce qui le remplit.*

**La déduplication.** Côté export, la première version dédoublonnait les
versions successives sur l'empreinte du GeoJSON. Éprouvé sur l'Ain : 916
instantanés donnaient **918** versions, soit aucune déduplication. La cause
n'est pas la sérialisation, elle est géométrique — le treillis est renoué à
chaque année, et une commune dont un *voisin* change gagne des sommets
colinéaires sur leur bord commun. `ST_Equals` comparé au précédent par `lag()`
ramène 2 748 instantanés à 920 versions sur six années d'échantillon.
*Deux dessins identiques peuvent avoir deux empreintes ; c'est l'égalité
géométrique qu'il faut demander, pas l'égalité des octets.*

### Ce qui est posé, et ce qui ne l'est pas

`sql/84_carte_partition.sql` (fonctions `partition_reprise`,
`carte_partition_atome`, `carte_partition`, `check_partition`, procédure
`partition_journalise`, table `p84_trace`), `sql/banc_84.py`, et le drapeau
`--partition` de `cartes/export_web.py`. Résultat du banc à 1870 sur 23
départements : recouvrement 6 923,6 → **0,000 km²**, trou non comblé 0,000,
aucun atome sans face.

**Le SQL n'a jamais été exécuté** — écrit sans accès à une base. Six erreurs ont
été trouvées à la relecture (SRID perdu par `ST_Extent`, fonction de fenêtre au
lieu d'un agrégat pour la fratrie, `ST_Node` sur une `GeometryCollection`,
`min(geom)`, `DISTINCT ON` sur une géométrie, `STABLE` mensonger) ; il en reste
sans doute. `check_partition` est ce qui les dira.

Ce fichier ne valide pas le report arrière de `11` : il rend dessinable ce que
la base affirme. La question de savoir si Villieu vivait en 1870 reste celle de
`83_anr_ecart_couverture.sql`, toujours à jouer.

### Le premier appel, et ce qu'un chargement réussi ne prouve pas

`psql -f sql/84_carte_partition.sql` passe sans une erreur : `CREATE FUNCTION`
cinq fois, `CREATE PROCEDURE`, et l'écho de fin. Puis le premier
`check_partition` tombe sur `column reference "geom" is ambiguous`, dans un
`DELETE FROM t84_src WHERE geom IS NULL` que le fichier portait depuis le début.

**Un corps PL/pgSQL n'est analysé qu'au premier appel.** Le chargement ne
vérifie que la syntaxe de l'enveloppe ; tout ce qui est entre `BEGIN` et `END`
attend qu'on s'en serve. Un fichier SQL qui se charge proprement ne dit donc
rien de ses fonctions procédurales — pour `82`, écrit en SQL pur, le chargement
valait contrôle ; ici il ne valait rien. *La forme d'un fichier décide de ce que
son chargement prouve.*

La cause : `RETURNS TABLE (atom_id, geom, source, motif, dedans)` déclare cinq
VARIABLES du même nom que les colonnes des tables temporaires du corps.
`#variable_conflict use_column` en tête règle toute la famille d'un coup.

**Quatre autres fautes trouvées dans la même relecture**, aucune ne s'étant
encore déclarée : `min(geometry)` — que PostGIS ne fournit pas — dans le calcul
de la différence, alors que le même piège avait été évité trois CTE plus haut ;
`ST_Polygonize` appelé comme une fonction scalaire alors que c'est un agrégat,
et dans la même liste de sélection que le `ST_Dump` qui le consomme ;
`row_number() OVER ()` mêlé au même `ST_Dump` ; et `ST_Multi` appliqué à des
différences qui peuvent rendre une `GeometryCollection` avec des lisières
linéaires — celle-là ne serait tombée que sur le premier département où le cas
se présente, c'est-à-dire tard.

### Le contrôle

Ain, 1870 : **recouvrement hors fraction 0,000 km²**, zéro géométrie invalide,
458 atomes dessinés, **7 repris par différence, 0 repli résiduel**.

Les trois comptes sont **exactement ceux du banc**, obtenus par un chemin qui ne
partage pas une ligne de code : shapely sur l'export WGS84 accroché à 25 m d'un
côté, PostGIS sur la géométrie Lambert-93 réelle de l'autre. Emprise 5 812 km²
projetés contre 5 810 attendus pour l'Ain au facteur 1,0084 — +0,03 %.

Le banc avait servi à écrire l'algorithme ; il sert maintenant de second chemin
pour le contrôler. C'était son intérêt, et il n'était pas prévu.

### La passe nationale, et un piège relu le matin puis réécrit le soir

Deux blocages avant qu'elle passe, et le second est le plus instructif.

**Le premier.** `carte_partition_atome` acceptait `NULL` et bâtissait UN treillis
national : `ST_Union` sur les frontières des 38 000 communes de France, puis
`ST_Polygonize` dessus. Elle n'a jamais rendu la main. Ce n'est pas de la
lenteur, c'est un changement de régime — et rien dans le résultat ne le
justifiait, puisqu'un atome ne dispute jamais une face à un autre situé à cent
kilomètres. Le banc, lui, avait toujours travaillé département par département
avec anneau de contexte : j'avais transcrit l'algorithme sans transcrire son
découpage. *Une opération globale qui n'a que des effets locaux doit être
découpée ; le seul travail est de choisir un cadre plus large que la portée des
effets.* Et une fonction muette qui dure des minutes est indiscernable d'une
fonction bloquée, d'où le `RAISE NOTICE` par département.

**Le second.** La boucle finissait ses 90 départements — les NOTICE le
disaient — puis la recette bloquait à son tour. `check_partition` lisait
`WITH c AS MATERIALIZED (…)` et joignait `c` à `c` par `ST_Intersects` : une
CTE matérialisée n'a pas d'index, `ST_Intersects` a beau porter son `&&` en
lui, il n'a plus rien à consulter, et PostgreSQL part sur 38 000 × 38 000
paires en boucle imbriquée.

**C'est mot pour mot le § 7 de `82_anr_geom.sql`**, « deux pièges de coût, payés
en direct », que j'avais relu le matin même pour comprendre `check_geom_anr`.
*Un piège consigné dans le dépôt n'est pas un piège évité : encore faut-il que
la relecture se fasse à l'endroit où il reparaît.* Table temporaire indexée en
GiST, `ST_Intersection` calculé une fois par paire — l'autre moitié du même
paragraphe.

**Deux garde-fous ajoutés au passage.** Un `DISTINCT ON (atom_id)`, parce qu'un
atome rattaché à des unités de deux départements (`35_atomes_hors_departement`)
serait rendu par les deux passes de la boucle et se recouvrirait lui-même de
toute sa surface. Et une ligne de recette séparée pour la couture entre
départements, parce que ce chiffre-là était une inconnue qu'il valait mieux
lire seul que noyé dans le total.

### Le résultat

Au 1ᵉʳ décembre 1870, France entière : 38 129 atomes dessinés, **433 repris par
différence**, **84 replis résiduels**, **recouvrement hors fraction 0,000 km²**,
**couture entre départements 0,000 km²**, zéro géométrie invalide, emprise
548 576 km².

Le second zéro n'était pas acquis. Deux communes séparées par une limite
départementale sont arbitrées dans deux cadres où les tiers diffèrent ; rien ne
garantissait qu'une lisière disputée tombe du même côté. Elle y tombe partout.

Les 84 replis contre 111 au banc confirment ce qui était annoncé : le banc
cherchait la mère dans le seul département, `84` la cherche dans l'anneau et en
trouve 27 de plus. Reste à les nommer un par un.

Deux chiffres ne sont pas expliqués et sont consignés comme tels dans
`ETAT.md` : l'emprise dépasse de 181 km² (+0,033 %) l'emprise nette d'ANR, ce
que le comblement des lisières internes explique plausiblement sans que ce soit
vérifié ; et les 38 129 atomes ne se comparent pas terme à terme aux 38 331 du
banc, qui ne comptait pas la même chose.

### Les 84 nommés, et deux choses qu'on ne cherchait pas

`sql/diag_partition.sql` — un fichier écrit parce que chaque question posée
séparément relançait les 90 départements. *Ce qui coûte des minutes ne se
demande pas une question à la fois.*

**Les 84 replis résiduels se décomposent sans une surprise** : 54 fractions
(par construction), 27 jamais pourvus par ANR — dont **les 20 arrondissements
de Paris**, que la trame des quartiers couvre par ailleurs —, 2 pourvus sur une
fenêtre antérieure à 1870, et **1 seul** où la règle de reprise échoue.

La confrontation avec le § 8 de `82` tombe juste sans qu'on l'ait cherchée :
quatre des six doublons y sont (Sebrazac, L'Aubépin, Saint-Hubert, La
Salvetat-Belmontet), et les deux « pourvus sur une fenêtre antérieure à 1870 »
sont exactement Sébazac-Concourès et Roches-Prémarie-Andillé, les deux que `82`
nommait. Un fichier écrit pour la géométrie retrouve la liste d'un fichier écrit
pour la chronologie.

**Un seul angle mort sur toute la France** : La Guérinière, 0,4 km². Elle
réapparaît chez ANR mais aucun voisin ne se coupe au même millésime — elle a été
formée en 1919 de deux communes-mères, ce qui est l'explication à vérifier. Une
règle sans seuil qui laisse un résidu à quatre décimales du pays se déclare ;
elle ne se rafistole pas.

**L'emprise se referme** : 548 576 km² contre l'étalon GEOFLA de 548 489,
+0,016 %. La partition récupère les 101 km² de recouvrement d'ANR et ajoute de
l'ordre de 80 km² de lisières internes comblées.

**Et un chiffre que personne n'avait posé : 318 atomes vivants à 1870 ne sont
dessinés nulle part.** Ni ANR, ni reprise, ni GEOFLA 2011. Ce n'est pas `84` qui
les efface — `snapshot_geom_anr` les comptait déjà sous `n_sans_geom`, mais le
nombre n'avait jamais été lu. C'est le vrai trou de la carte à cette date, et il
passe en tête de `RESTE_A_FAIRE.md`. *Une colonne qui existe depuis un mois n'est
pas un fait connu tant que personne n'en a lu la somme.*

**Une faute de légende, dans le diagnostic lui-même.** Son § 4 donnait la
surface totale des atomes portant chaque motif d'arbitrage, et annonçait que la
ligne `comblement` était « le premier suspect pour les +181 km² ». Elle vaut
2 559,8 km² : c'est la surface des 135 atomes concernés, pas celle qui a été
comblée — un atome de 20 km² dont deux hectares ont été comblés y pèse 20. La
colonne était juste, la légende fausse, et une colonne juste sous une légende
fausse est une colonne fausse. Le § 7 pose maintenant la vraie question :
la surface de chaque atome après la partition, moins celle qu'il avait avant.
