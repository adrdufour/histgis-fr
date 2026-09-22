# La chaîne `sql/` — qui fait quoi, dans quel ordre, et ce qui ne sert plus

Dressé le 20 août 2026 en lisant les fichiers, pas en les supposant. La journée
avait montré qu'on pouvait reconstruire la base en croyant l'avoir faite : la
chaîne s'était arrêtée après `24`, la couche des circonscriptions était restée
vide, et le contrôle indépendant n'en avait rien dit — il ne regarde que 1870 et
1940.

**Relu et complété le 2 septembre 2026.** Ils sont **84**, pas 46 ; l'inventaire
du § 1 s'arrêtait à `47` et laissait hors tableau tout le chantier 1943-1999
(`58`-`83`), décrit plus bas en prose mais absent de l'ordre d'exécution.

**Trois familles**, et c'est la distinction qui manquait :

| famille | écrit dans la base ? | où |
|---|---|---|
| **construction** | oui — `membership`, `atom`, `unit`… | § 1 |
| **diagnostic** | non, lecture seule | § 2 |
| **espace séparé** | oui, mais dans `om_*` | § 3 |

---

## 0. AVERTISSEMENT — le trou est comblé, il n'est pas éprouvé

> **`rejouer_apres_rebuild.sh` va désormais jusqu'à `84`.** Complété le
> 6 septembre 2026 : les vingt-deux étapes qui manquaient y sont, dans l'ordre
> du § 1 c ci-dessous, avec leurs `-v`, leur `-1` là où le fichier le demande,
> et les trois prérequis binaires. **Le § 1 c n'est plus une procédure ; c'est
> une table de dépendances.**
>
> **Ce qui n'est toujours pas vrai : que cela fonctionne.** Le script n'a pas
> tourné. Il est vérifié hors base — `bash -n`, existence de chaque fichier
> cité, et le contrôle croisé qui compte : *tout fichier `sql/[0-9]*.sql` qui
> écrit dans la base est appelé par `rebuild.sh`, `load.sh`, `load_cog.sh` ou
> ce script*. Les vingt-neuf qui restent hors chaîne sont tous en lecture seule
> (§ 2). Mais **une chaîne ne se relit pas, elle se joue** : c'est la même
> phrase qu'au 2 septembre, et elle vaut toujours.
>
> **Deux recettes propres à cette complétion**, à lire au premier passage :
>
> * `diag_passages.sql` doit trouver une trace pour **toutes** les étapes, `25`,
>   `37` et `40` compris ;
> * `85_conflit_38_79.sql`, joué sans `-v`, doit trouver **zéro** fraction à
>   libérer. Il n'existe que parce que `79` a été joué après `38` hors de toute
>   chaîne ; dans l'ordre du script, `38` passe avant et le § 5 de `79` écarte
>   ces six atomes de lui-même. *S'il trouve quelque chose, c'est l'ordre du
>   script qui est faux, pas `85`.*
>
> Ce que la complétion ajoute au constat du 2 septembre, sans le retirer :
> **un quatrième prérequis ne vivait qu'en commentaire** — `anr_commune`, la
> couche du GeoPackage ANR chargée par un `ogr2ogr` écrit dans l'en-tête de
> `82` et dans `JOUER_82.md`, et par aucun script. Il en dépend plus que `82` :
> `89`, `90`, `91` et `84` lèvent tous une `EXCEPTION` sans lui.
>
> ---
>
> **L'état d'avant, conservé — c'est lui qui dit pourquoi le comblement valait
> une journée.** Le script s'arrêtait à `40_scission_circo.sql`, mesuré le
> 2 septembre 2026 en lisant ses invocations réelles et non ses commentaires.
> **Treize fichiers qui écrivent dans la base n'étaient appelés par aucun
> script** : `57`, `58`, `59`, `60`, `67`, `68`, `74`, `75`, `76`, `77`, `79`,
> `81`, `82` — tout le chantier 1943-1999 et la trame ANR — rejoints depuis par
> `87` à `91`. Leurs traces étaient pourtant en base : ils avaient été joués
> **à la main**, un par un.
>
> **Le prochain `rebuild.sh` aurait tout détruit sans que rien n'échoue.** La
> base se serait reconstruite, plus petite, en silence. C'est la mécanique qui
> a défait `39_meurthe_1870.sql` pendant quinze jours entre le 15 et le 30 août,
> appliquée cette fois à 1954, 1968, aux salves, aux deux reports, à la trame
> ANR et à la Seine entière.
>
> Ce que le 2 septembre change, et ce qu'il ne change pas : `38` et `39` ont
> maintenant une trace, donc un `rebuild.sh` qui les emporte se **voit**
> désormais dans `diag_passages.sql`. Il ne les remonte toujours pas pour
> autant. Une trace signale une perte, elle ne la répare pas.
>
> **Trois manques ont été comblés dans le script le 2 septembre 2026**, et ils
> avaient une seule et même cause : *un prérequis qui n'est écrit qu'en
> commentaire est un prérequis absent.*
>
> * `37_reparer_encodage.sql` n'était appelé par rien. L'étape annonçait
>   « COG 1999-2012 (22, 36, **37**, 23) » et déléguait à `load_cog.sh`, **qui
>   ne joue que `22` et `23`** ; le commentaire lui attribuait en prime la
>   création de `noms_geofla`, qui est le fait de `19`. Il est maintenant appelé
>   à côté de `50`, avec `-v appliquer=1`.
> * `25_pseudo_canton.sql` exige `geofla_canton`, que **rien ne chargeait** : la
>   commande `ogr2ogr` ne vivait qu'en commentaire dans son en-tête. Elle est
>   entrée dans la chaîne.
> * `40_outremer.sql` exige `om_commune_src`, que produit `charger_outremer.sh`,
>   **que rien n'appelait**. Le script est appelé avant lui, sous condition.
>
> *Un commentaire qui décrit ce que le code ne fait pas ne se dément jamais tout
> seul : la chaîne ne se plaint pas d'un fichier qu'elle n'appelle pas.*
>
> **Et une conséquence qui vaut pour la lecture de tout ce document** : `25`
> levait une `EXCEPTION`, et `set -euo pipefail` la propage. **La chaîne ne
> pouvait donc pas dépasser `25`.** Tout ce qui porte une trace au-delà a été
> joué à la main — c'est établi par l'état de la base, pas seulement soupçonné.
>
> Ce qui est en base se vérifie par `psql -d histgis -f sql/diag_passages.sql`.
> **Ces trois correctifs, eux, ne sont vérifiés par rien tant que le script n'a
> pas tourné** : une chaîne ne se relit pas, elle se joue.

---

## 1. La chaîne de construction, dans l'ordre

Ordre **réel**, relevé dans les invocations des deux scripts et dans les
prérequis déclarés par les fichiers eux-mêmes. La colonne « appelé par » est la
plus importante du tableau : elle dit ce qu'une reconstruction remonte et ce
qu'elle ne remonte pas.

### 1 a. `rebuild.sh` — le socle 1870-1940. DESTRUCTIF

| # | fichier | rôle | trace | `-v` |
|---|---|---|---|---|
| 1 | `01_schema.sql` | tables, contraintes `EXCLUDE`, index. **`DROP SCHEMA CASCADE`** | — | — |
| 2 | `02_load.sql` | `\copy` des CSV de `build/`, reconstruction des noms | — | `f` = dossier `build/` |
| 3 | `03_functions.sql` | `snapshot()`, `unit_nom()`, `check_*()` | — | — |
| 4 | `05_geom.sql` | polygones GEOFLA 2011 sur les atomes | — | — |
| 5 | `06_insee_mvt.sql` | mouvements INSEE, `commune_successeur` | — | `mvt` |
| 6 | `07_reliquat.sql` | rattrapage HAC des communes disparues | — | — |
| 7 | `11_scission.sql` | prolonge vers 1870 les communes nées pendant la série | `scission_trace` | — |
| 8 | `15_creation_arriere.sql` | communes nées **après** la série : atome-fraction + chronologie de la mère | `creation_trace` | — |

### 1 b. `rejouer_apres_rebuild.sh` — la couche moderne et les correctifs

Ordre réel du script. Les étapes marquées ⟨si⟩ sont sautées quand leur CSV
d'entrée manque — **et le script le dit, mais sur `stderr`, au milieu d'une
sortie trop longue pour être relue.**

| # | fichier | rôle | trace | `-v` |
|---|---|---|---|---|
| 9 | `19_noms_geofla.sql` | noms de communes, projection de `geofla_commune` | — | — |
| 10 | `20_commune_moderne.sql` | chronologie communale 1943-2012 (`cm_*`) | — | — |
| 11 | `21_atomes_modernes.sql` | atomes 1943-2012, crée `commune_moderne` | `atome_moderne_trace` | — |
| 12 | `load_cog.sh` → `22`, `23` | 14 millésimes du COG (en `WIN1252`), puis diagnostic. **Ni `36` ni `37`**, contrairement à ce que l'étape annonçait jusqu'au 2 septembre | — | — |
| 13 | `24_canton_moderne.sql` | cantons 1999-2012, atomes-fractions | `canton_moderne_trace` | — |
| 13 bis | *(`ogr2ogr`)* | couche **CANTON de GEOFLA 2014** → `geofla_canton`, `-a_srs EPSG:2154`. Prérequis de `25` et de `26`. **N'était chargée par aucun script avant le 2 septembre** : elle ne vivait qu'en commentaire, et `25` s'arrêtait sur son garde-fou | — | — |
| 14 | `25_pseudo_canton.sql` | pseudo-cantons de Marseille et Lyon | `pseudo_canton_trace` | — |
| 15 | `27_circo_2012.sql` | circonscriptions de 2009 (2010-2013) | `circo_moderne_trace` | **`circo`** |
| 16 | `28_circo_1986.sql` | circonscriptions de 1986 (1986-2010) | `circo1986_trace` | **`circo`** |
| 17 ⟨si⟩ | `49_circo_1986_partage.sql` | comble les indéterminations de `28` par l'atlas | `circo_partage_trace` | `partage` |
| 18 ⟨si⟩ | `51_circo_1986_correctif.sql` | l'Ain : 30 cantons sur 43 mal affectés par le ministère | `circo_correctif_trace` | `appliquer`, `correctif` |
| 19 | *(scripts Python de `circo/`)* | `paris_quartier`, `paris_circo`, `iris_paris` | — | — |
| 20 | `52_paris_circo_1986.sql` | Paris dans le découpage de 1986 | `paris_circo_trace` | `appliquer` |
| 21 | `53_paris_geom_iris.sql` | géométrie parisienne alignée sur la trame IRIS | `paris_geom_trace` | `appliquer` |
| 22 ⟨si⟩ | `54_paris_circo_1815.sql` | Paris de 1815 à 1863 (ALPAGE-Vasserot) | `paris_1815_trace` | `appliquer`, `src` |
| 23 | `56_paris_circo_1876.sql` | Paris au quartier 1876-1941, remplace TRF-GIS | `paris_1876_trace` | `appliquer` |
| 24 | `55_paris_circo_serie.sql` | Paris : 1863-1870 et 1941-1986 | `paris_serie_trace` | `appliquer` |
| 25 | `32_marseille_geom.sql` | géométrie des cantons de Marseille | `marseille_trace` | — |
| 25 bis ⟨si⟩ | `charger_outremer.sh` | les cinq lots GEOFLA d'outre-mer → `om_commune_src`, `om_canton_src`. Prérequis de `40`. **N'était appelé par rien avant le 2 septembre** | — | — |
| 26 ⟨si⟩ | `40_outremer.sql` | espace séparé `om_*` (§ 3). Sauté proprement si les lots manquent : les tables `om_*` ne partagent rien avec la métropole | `om_trace` | `circo_om` |
| 27 | `38_decret_1982_ain.sql` | décret de 1982, cantons de Bourg-en-Bresse | `p38_trace` | — |
| 28 | `50_noms_perdus_trfgis.sql` | 4 noms détruits **dans la source** (U+FFFD) | `noms_perdus_trace` | `appliquer` |
| 28 bis | `37_reparer_encodage.sql` | C1 de Windows-1252 lus en Latin-1 dans `unit.nom` et `unit_version.nom`. **Ici et non à l'étape COG** : il répare des tables qui n'existent pas encore à ce moment-là. Peut légitimement ne rien avoir à faire depuis que `load_cog.sh` lit en `WIN1252` | `encodage_trace` | **`appliquer`** |
| 29 | `39_meurthe_1870.sql` | la Meurthe reprend le numéro 54 — **cantons seulement** | `p39_trace` | — |
| 29 bis | `92_meurthe_circo.sql` | le même geste à l'étage **circo** : `L9901@1870` passe en 54. Sans lui, une unité reste en `99`, et la Meurthe de 1870 est coupée en deux — cantons dans le 54, circonscription dans un 99 sans cantons | `p92_trace` | — |
| 30 | `41_retablissement.sql` | communes rétablies après 1999 — trois voies | `retablissement_trace` | — |
| 31 | `42_rattachement_arriere.sql` | rattache le passé d'un atome existant. **Rend 0 cas** depuis que le garde-fou 6 de `15` résout les recodages : sa trace vide est l'état sain, pas une anomalie | `rattachement_arriere_trace` | — |
| 32 | `44_absorption_ancienne.sql` | absorbées puis rétablies avant 1943 (Cherré) | `absorption_trace` | — |
| 33 ⟨si⟩ | `46_creation_serie.sql` | nées pendant la série, sans rattachement — filiation HAC | `creation_serie_trace` | `hac` |
| 34 | `47_circo_mere.sql` | circo de la mère HAC quand les voisins sont muets | `circo_mere_trace` | — |
| 35 | `40_scission_circo.sql` | comble les trous circo par les voisins de canton. **En DERNIER**, après `46` : contrainte 5 | `scission_circo_trace` | — |

### 1 c. LES ÉTAPES TARDIVES — entrées dans le script le 6 septembre 2026

**C'était le trou du § 0, et cette liste en était la procédure.** Elle ne l'est
plus : `rejouer_apres_rebuild.sh` appelle désormais tout ce qui suit, dans cet
ordre, à la suite de `40_scission_circo`. Le tableau reste, comme **table de
dépendances** — c'est lui qui dit pourquoi l'ordre est celui-là, et ce que
chaque fichier exige avant de partir.

Cinq lignes s'y sont ajoutées depuis, écrites après le tableau d'origine et
rangées dans le script à la place que leurs propres garde-fous imposent :

| # | fichier | exige, et le dit par une `EXCEPTION` |
|---|---|---|
| s | `87_seine_canton_1954.sql` | le jalon `68` en base |
| t | `88_seine_circo_1945_1967.sql` | `68` **et** `87` — son § 1 nomme le second |
| u | `89_seine_annexees_1860.sql` | `anr_commune` **et** `atom_geom_anr`, donc `82` |
| v | `90_seine_1848_banlieue.sql` | l'unité `L7501@1848` de `57`, et les onze de `89` |
| w | `91_seine_1815_1870.sql` | les circos parisiennes de 1863 (`55`), `89`, et `68` |
| x | `84_carte_partition.sql` | `82` — « PRÉREQUIS : jouer sql/82_anr_geom.sql » |

`84` ne modifie aucune donnée : il pose des fonctions, une trace et une
procédure, que `DROP SCHEMA` emporte comme le reste et que
`cartes/export_web.py --partition` appelle. C'est à ce titre qu'il est dans la
chaîne, et à aucun autre.

| # | fichier | rôle | trace | `-v` |
|---|---|---|---|---|
| a | `57_paris_circo_1848.sql` | 1848-1852 : le département EST la circonscription | `paris_1848_trace` | **`appliquer`** |
| c | `58_cog1968_stage.sql` | dépôt et résolution du recensement de 1968. N'écrit pas dans `membership` | `c68_trace` | lancer depuis la RACINE |
| d | `59_cog1968_membership.sql` | **JALON 1968** — 32 659 rattachements, 2 899 cantons | `c68_trace`, `c68_qualite` | `-1` |
| e | `60_canton_forbach2.sql` | Forbach-II, canton que `59` délègue explicitement | `c60_trace` | — |
| f | `65`, `66`, `69` | noms de 1954, dépôt du recensement, pont Seine-et-Oise | — | RACINE |
| g | `67_cantons_1949_1951.sql` | les trois cantons créés entre 1940 et 1954 | `c67_trace` | `-1` |
| h | `68_cog1954_membership.sql` | **JALON 1954** — 30 035 atomes, 2 946 cantons | `c54_trace`, `c54_qualite` | `-1` |
| i | `72_registre_actes.sql` | registre des 343 décrets, `acte_composition`, `acte_silence` | — | — |
| j | `73_recette_1967.sql` | juge les décrets de 1967 par le jalon de 1968 | — | — |
| k | `74_yvelines_1967.sql` | Yvelines 1968, fascicule manquant — date d'effet = un FAIT | `y67_trace` | — |
| l | `75_composition_1973_1982.sql` | les deux grosses salves. **Première date conventionnelle** | `p75_trace`, `p75_qualite` | `-1` |
| m | `76_composition_salves_restantes.sql` | la longue traîne, même convention | `p76_trace`, `p76_qualite` | `-1` |
| n | `77_transferts_dates.sql` | 66 transferts de commune, dates INSEE — des FAITS | `p77_trace`, `p77_qualite` | `-1` |
| o | `79_report_1999_arriere.sql` | **REPORT ARRIÈRE** depuis 1999. Après `77`, jamais avant | `p79_trace`, `p79_qualite` | `-1` |
| p | `81_report_1968_avant.sql` | **REPORT AVANT** depuis 1968. Après `79`, qu'il prend pour témoin | `p81_trace`, `p81_qualite` | `-1` |
| p bis | `93_report_1940_1954.sql` | **1941-1953**, le dernier vide franc. Ne pose que là où 1940 et 1954 disent le même canton — deux bouts attestés, pas une absence de registre. Prérequis `67` et `68` ; indifférent à `79` et `81`, qui ne descendent pas sous 1968 | `p93_trace`, `p93_qualite` | `-1` |
| q | `82_anr_geom.sql` | trame ANR datée, **à côté** de `atom_geom`. Hors chaîne par conception | `a82_trace` | `variantes` |
| r | `85_conflit_38_79.sql` | **rend à `38` la fenêtre 1982-1999 que `79` occupe.** Instruit sans `-v`, corrige avec `appliquer=1`, se défait avec `defaire=1` | `p85_trace` | `appliquer`, `defaire` |

**`85` n'existe que parce que `79` a été joué hors ordre**, et il n'est PAS dans
le script. Le conflit qu'il répare est celui d'un report arrière posé APRÈS le
décret qu'il recouvre : joué dans l'ordre — `38` en `1 b`, puis `79` en `o` —
`79` écarte ces six atomes de lui-même, son § 5 n'écrivant que sur une fenêtre
entièrement libre. **C'est devenu la recette de la complétion** : au premier
passage complet, `85` joué sans `-v` doit trouver zéro fraction à libérer. S'il
en trouve, c'est l'ordre du script qui est faux. Écrit le 5 septembre 2026,
joué le même jour sur la base d'alors — où le conflit, lui, existait bel et
bien.

`64_composition_1815_stage.sql`, `70_report_1940_1954.sql` et
`71_desaccords_report_geometrie.sql` sont en lecture seule et se lancent à la
demande ; ils ne figurent pas ici pour cette raison.


### Contraintes d'ordre, mesurées en les violant

1. **`21` avant `22`/`23`.** `21` crée `commune_moderne`, et `23_cog_diag.sql`
   — que `load_cog.sh` joue en dernier — l'exige.
2. **`19` avant tout ce qui interroge `noms_geofla`** : `39`, `41`, `42`, `43`,
   `44`. Cette table était créée par `cartes/couverture_cantons_2025.py`, hors
   de la chaîne — une reconstruction complète échouait donc systématiquement
   dessus. **Une dépendance de la chaîne ne peut pas vivre hors de la chaîne.**
3. **`24` avant `27` et `28`** : ceux-ci rattachent les circonscriptions aux
   atomes-fractions que `24` vient de créer.
4. **Les correctifs datés en dernier**, parce qu'ils référencent les unités
   de `24`, `27` et `28`.
5. **`40_scission_circo` après `46`.** `40` répond par procuration — l'unanimité
   des voisins de canton — là où `46` répond directement, en tenant de HAC le
   nom de la mère. Une réponse par procuration ne doit jamais passer avant une
   réponse directe : placé en premier, `40` occupait le terrain, et le garde-fou
   4 de `46` (« rien sur une période déjà occupée ») faisait taire la meilleure
   source. Déplacé le 20 août 2026, après le cas de Villeneuve-la-Garenne.

### Les deux pièges de rejeu

**Clé étrangère.** `24`, `27` et `28` suppriment leurs unités avant de les
recréer ; `38`, `41`, `42`, `15` les référencent. Voir « Qui dépend de qui »
dans `README.md`.

**Cascade silencieuse.** `24` supprime ses 732 atomes-fractions ; la cascade
emporte les circonscriptions que `27` et `28` y avaient posées, et **rien
n'échoue**. C'est à cela que sert `43_circo_fraction.sql`.

---

## 2. Les fichiers de diagnostic — lecture seule

Aucun n'écrit dans la base. Ils se lancent à la demande et ne font pas partie
de la reconstruction.

| fichier | ce qu'il répond | `-v` |
|---|---|---|
| `04_checks.sql` | rapport de recette après chargement | — |
| `08_controle_gay.sql` | **le contrôle indépendant** : cantons dissous de Victor Gay, IoU, conformité | `mapping` |
| `09_ecart_detail.sql` | d'où viennent les écarts avec Gay ; score du pari de `11` | — |
| `10_couverture.sql` | territoire non couvert, commune par commune | — |
| `12_conflit_successeur.sql` | désaccords résiduels sur les atomes `successeur` | `date_ref` |
| `13_double_comptage.sql` | surface comptée deux fois, par deux méthodes | `date_ref` |
| `14_cle_partage.sql` | pourquoi les deux méthodes de `13` diffèrent de 108 km² | `date_ref` |
| `23_cog_diag.sql` | le COG chargé concorde-t-il avec `commune_moderne` | — |
| `26_controle_ign.sql` | **contrôle indépendant de 1999-2012** : la couche CANTON de GEOFLA (édition ED141, 2014). *Pas* ADMIN EXPRESS — l'en-tête du fichier le dit, cette ligne l'a affirmé à tort jusqu'au 2 septembre 2026 | `date_ref` |
| `29_villes_a_verifier.sql` | villes dont le découpage cantonal est douteux | — |
| `30_stabilite_cantonale.sql` | stabilité d'un canton dans le temps | `dep` |
| `31_marseille_inventaire.sql` | état des lieux Marseille avant `32` | — |
| `33_diff_cantonal.sql` | différentiel cantonal entre deux dates | `dep` |
| `34_orphelines_1941.sql` | communes éteintes avant 1999, sans canton moderne | `dep` |
| `35_atomes_hors_departement.sql` | atomes dont le polygone est dans un autre département | — |
| `36_recette_annexe_vi.sql` | recette de l'annexe VI (découpages électoraux) | — |
| `45_controle_hac.sql` | **second contrôle indépendant** : HAC nomme la mère | `hac` |
| `48_diag_mere_muette.sql` | quand les voisins de canton se taisent, la mère HAC répond-elle ? Mesure la classe avant d'écrire un correctif | — |
| `70_report_1940_1954.sql` | peut-on REPORTER une composition d'une date à l'autre ? | — |
| `71_desaccords_report_geometrie.sql` | la géométrie arbitre les désaccords de `70` | — |
| `73_recette_1967.sql` | juge les décrets de 1967 par le jalon de 1968 — cinq mois d'écart, le contrôle le plus serré du trou | — |
| `78_report_1999_arriere_diag.sql` | mesure le report arrière avant de l'écrire. **Se lit après `79`** | — |
| `80_report_1968_avant_diag.sql` | idem pour le report avant, et **porte la validation du registre** (§ 6 quinquies) | — |
| `83_anr_ecart_couverture.sql` | pourquoi 486 atomes et non 40 — devenu le **troisième contrôle indépendant** | `date` |
| `84_carte_partition.sql` | la trame nettoyée : sans trou ni superposition hors fractions. **Ne modifie aucune donnée** — que des fonctions, une trace et une procédure ; il est à ce titre dans les deux listes, ici parce qu'on l'interroge, en `1 c` parce qu'un `DROP SCHEMA` emporte ses fonctions. Joué et contrôlé les 3, 5 et 6 septembre 2026 : anneau de voisinage réel, trappe du vide, règle mosaïque de fratrie, recouvrement 0,000 km² | `date`, `dep` |
| `86_reprise_mosaique.sql` | compare les deux règles de partage d'une fratrie, l'en-vigueur et l'historique, toutes deux vivantes dans `84`. A servi à décider, sert à contrôler que la décision tient | `date` |
| `diag_partition.sql` | interroge la trame nettoyée sans la recalculer — replis nommés, motifs d'arbitrage, atomes que rien ne dessine (§ 8) | `date` |
| `diag_titre_composition.sql` | le titre d'un décret juge le découpage du JO | — |
| `diag_passages.sql` | **quels fichiers sont réellement passés sur cette base** — l'inventaire des traces attendues contre ce que la base porte | — |
| `diag_sans_geometrie.sql` | **les atomes que rien ne dessine, et l'unique échec de la reprise.** Sépare le défaut de chaîne de la limite de source par une colonne, et instruit La Guérinière. Ne recalcule PAS la partition — quelques secondes contre plusieurs minutes. Écrit le 5 septembre 2026, **jamais joué** | `date` |

**`45` ne modifie rien, et c'est délibéré.** Corriger la base d'après HAC lui
ferait perdre son indépendance — comme recopier Gay la ferait perdre au
contrôle géométrique.

---

## 3. `40_outremer.sql` — un espace de noms séparé

Seul fichier qui écrit dans des tables `om_*` (`om_atom`, `om_membership`,
`om_unit`…) et **ne touche à aucune table principale**. Les 129 communes
d'outre-mer y vivent à part, avec leurs propres fonctions `om_snapshot()`.

Conséquence à connaître : **aucune recette de la chaîne principale ne les
voit**, et le contrôle Gay non plus.

Collision de numéro : `40_outremer.sql` et `40_scission_circo.sql` portent le
même préfixe alors qu'ils n'ont rien à voir. À renuméroter.

---

## 4. Ce qui ne sert plus, ou mérite d'être revu

| fichier | verdict |
|---|---|
| `diag_marseille.sql` | **mort** — diagnostic ponctuel, remplacé par `31_marseille_inventaire.sql`. Aucun script ne l'appelle. |
| `23_cog_diag.sql` | **mal placé** — c'est un diagnostic, mais `load_cog.sh` le joue en dernier et son `RAISE EXCEPTION` fait échouer tout le chargement. Un diagnostic ne devrait pas bloquer une construction. |
| `43_circo_fraction.sql` | **conditionnel** — inutile dans une chaîne complète, indispensable après un rejeu isolé de `24`. |
| `38_decret_1982_ain.sql` | **doté d'une trace le 2 septembre 2026** (`p38_trace`, trois catégories distinctes). Il était jusque-là le seul fichier qui posait des rattachements sans pouvoir les défaire, et c'est lui qui a bloqué la reconstruction de `24`. Il **nomme désormais l'occupant** quand la fenêtre 1982-1999 est prise, au lieu de se taire. Éprouvé avec `39` par `sql/banc_38_39.sh` — six scénarios, dont les deux façons dont la fenêtre peut être prise. |
| `39_meurthe_1870.sql` | **doté d'une trace le 2 septembre 2026** (`p39_trace`). Cette ligne disait « sans trace, et ce n'est PAS sans risque » : il est idempotent, oui ; mais un `rebuild.sh` l'a défait le 15 août et **personne ne l'a su avant le 30**, parce que rien dans la base ne disait s'il était passé. L'idempotence protège du rejeu, pas de l'oubli. Sa trace vise l'`unit_id` `99xx`, jamais le département `99` — sans quoi elle serait vide sur une base déjà conforme, et le diagnostic crierait au faux. |

### Trous à combler dans la chaîne elle-même

**Cinq fichiers échouent sur un message opaque** quand leur variable manque :

```
psql:sql/27_circo_2012.sql:76: error: :: Aucun fichier ou dossier de ce nom
```

`02`, `06`, `08`, `27`, `28` n'ont pas de valeur par défaut ni de message clair,
là où `40_outremer`, `45` et `46` portent un `\if :{?var}`. **Cette incohérence
a coûté une soirée** : la chaîne s'est arrêtée après `24` sans qu'on sache
pourquoi, et la base est restée sans aucune circonscription moderne.

**Il manque une recette d'ensemble.** `controle_gay.sh` ne couvre que
1870-1940. Rien ne compte les quatre couches d'un coup — c'est ce qui a permis
de croire trois fois la reconstruction terminée. À écrire, et à mettre en fin
de `rejouer_apres_rebuild.sh`.

### Le jalon de 1968 (ajouté le 22 août 2026)

| fichier | rôle |
|---|---|
| `58_cog1968_stage.sql` | dépôt et résolution. **N'écrit ni dans `atom` ni dans `membership`** — méthode de `20` : mesurer, noter, puis écrire. Le `\copy` impose de lancer depuis la RACINE du dépôt. |
| `59_cog1968_membership.sql` | pose **32 659** rattachements sur `[1968-01-01, 1969-01-01)` pour 2 899 cantons (30 939 au premier passage : deux relectures OCR ont suivi). Tracé dans `c68_trace`, rejouable, à lancer avec `-1`. |

`59` défait son passage précédent **avant** de juger quoi que ce soit — la
leçon de `55`, dont le garde-fou se jugeait lui-même et refusait de tourner
deux fois.

Prérequis : `20` (cm_commune, cm_atome), `24` (unités canton), et `23` pour la
section 6 de `58`, qui est sautée proprement si `cog_rat` manque.

### Forbach-II et la délégation entre fichiers

`60_canton_forbach2.sql` pose un canton que `59` ne pose PAS — et cela ne tient
plus à l'ordre d'exécution.

**Le problème était circulaire.** En créant l'unité `5740`, `60` la rend connue
de `unit` ; `58` cesse alors de la ranger parmi les cantons inconnus ; `59` veut
donc poser ces seize communes que `60` occupe déjà. L'erreur n'apparaissait
qu'au SECOND rejeu, quand la base semblait stabilisée.

**La solution est une déclaration explicite, pas un ordre.** `59` porte une
table `c68_delegue` qui dit *ce canton n'est pas à moi*, et l'écarte quel que
soit l'état de la base. `60` vérifie de son côté que la déclaration existe
toujours, et refuse de tourner sinon.

    Une délégation n'existe que si les DEUX côtés la connaissent.

Un ordre d'exécution se perd — dans une reconstruction, une copie de script,
une reprise après incident. Une déclaration reste dans le fichier.

**Recette** : la fin de `59` liste les cantons délégués avec `en_base` et
`attendu`. Un `en_base` à 0 signifie que le fichier délégué n'a pas été joué —
ces communes sont alors absentes du jalon, et non mal rattachées.

Ordre recommandé : `58` → `59` → `60`. Mais les trois se rejouent dans
n'importe quel ordre sans conflit.

---

## 72 et 73 — le registre des actes entre en base, le membership attend

`72_registre_actes.sql` pose trois tables de référence — `acte_cantonal`
(343 décrets 1958-1999), `acte_composition` (4 958 lignes acte × canton ×
commune), `acte_transfert` (5 mouvements isolés de commune) — plus la table
dérivée `acte_silence`. **Il n'écrit aucun `membership`** : après son passage,
aucun `snapshot` ne répond différemment.

Ce n'est pas de la prudence, c'est l'ordre logique. Le report d'un état d'une
date à l'autre — la méthode retenue pour combler 1943-1999 — n'est licite que
si la liste des actes de l'intervalle est complète.

    Sans cette table, on ne peut pas distinguer
    « rien ne s'est passé » de « on ne sait pas ».

`acte_silence` donne, département par département, le dernier acte connu avant
1968 et le premier après. C'est la matière première de l'extension du jalon que
`RESTE_A_FAIRE.md` réclamait — **et pas son autorisation** : un silence est une
absence d'acte dans notre liste, pas une preuve de stabilité.

`73_recette_1967.sql` juge les décrets de 1967 par le jalon de 1968 déjà en
base. Sa particularité : **cinq mois séparent les deux sources**, là où le
contrôle habituel regarde trente ans plus tard. Un désaccord ne peut donc pas
être imputé au monde — il accuse l'une des deux lectures. C'est le contrôle le
plus serré dont le trou 1943-1999 dispose.

Il interroge le MODÈLE (`membership` au 1er juin 1968), pas le fichier de
préparation : c'est la base telle qu'elle répondra qui est jugée. Et il apparie
les cantons **par la composition**, jamais par le nom — le nom est ce que l'OCR
abîme, quand ce n'est pas la nomenclature qui le déplace.

`\copy` **apparie les colonnes par position, pas par nom**, même avec
`HEADER true`. `composition_legifrance.py` a été aligné sur l'ordre de
`composition_jo.csv` pour cette seule raison. Deux fichiers aux mêmes colonnes
dans un ordre différent se chargeraient en silence dans les mauvaises cases.

Ordre : `72` → `73`. Les deux se rejouent : leurs tables sont reconstruites de
zéro et rien n'est écrit hors d'elles.

**Ce qui n'est pas posé, et pourquoi.** Les 1 267 compositions et les cinq
transferts attendent une décision qui n'est pas technique : les décrets de 1973,
1982 et 1985 ne portent aucune clause d'effet, et les conseils généraux se
renouvelaient par moitié — « le prochain renouvellement » d'un canton dépend de
sa série, que nous n'avons pas. `73` § 5 simule la pose des cinq transferts et
montre que la place est libre. Il ne manque que la convention. Voir
`cantons/note_entree_en_base.md` § 4.

---

## 74 — quand un contrôle trouve autre chose que ce qu'il cherchait

`73` devait juger les décrets de 1967 par le jalon de 1968. Il a rendu 45
accords et 0 désaccord — et **14 cantons dont aucune commune n'est retrouvée**,
tous dans le même département.

Ce n'était pas une faiblesse de lecture : le 78 est l'un des neuf fascicules du
COG 1968 introuvables sur BnSP (61, 71 à 78). Le contrôle a mis au jour un trou
documenté ailleurs parce qu'il regardait autre chose.

`74_yvelines_1967.sql` comble ce trou par l'acte qui l'aurait rempli. C'est le
premier `membership` posé par ce chantier, et il l'est pour une raison précise :

    sa date d'effet n'est pas une convention.

Les Yvelines naissent le 1er janvier 1968 ; le décret du 20 juillet 1967 crée
leurs cantons avec effet à cette naissance. `valid_from` est un fait juridique,
là où les compositions de 1973, 1982 et 1985 attendent toujours qu'on tranche.

Le fichier vérifie que le département est bien absent du jalon avant d'écrire —
il refuserait d'écraser une lecture directe par une déduction. Il résout
l'identité des cantons par la composition contre 1999 (seuil 80 %, minimum trois
communes), écarte et liste ce qui ne résout pas, et refuse tout en bloc si un
atome est réclamé par deux cantons du même décret.

Attendu : 11 cantons posés, 155 rattachements ; 6 trop courts, 2 accords
partiels, 1 désaccord (Trappes, ville nouvelle redécoupée depuis).

Ordre : `72` → `73` → `74`.

---

## 75 — la première date qui soit une convention, et non un fait

`75_composition_1973_1982.sql` pose dans `membership` les compositions des deux
plus grosses salves de décrets — 1973 (1 951 lignes) et 1982 (1 035). C'est le
premier fichier du dépôt dont la **date de début n'est pas dans la source**.

    valid_from = premier tour du renouvellement des conseils généraux
                 qui suit la signature du décret

Les décrets de 1973, 1982 et 1985 ne portent aucune clause d'effet : sur les
233 segments de décret cantonal des JO, sept seulement en ont une. Mais chaque
salve est signée quelques semaines avant un renouvellement — juillet-août 1973
pour le scrutin du 23 septembre, janvier-février 1982 pour celui du 14 mars —
et le seul décret du lot qui le dise, celui de 1997, dit exactement cela. Le
premier tour est retenu parce que c'est lui qui élit sous le nouveau découpage.

**Ce que la convention coûte, et où c'est écrit.** Les conseils généraux se
renouvelaient par moitié : « le prochain renouvellement » d'un canton dépend de
sa série, que nous n'avons pas. Pour un canton créé la question ne se pose pas
— il entre en vigueur au scrutin qui l'élit ; pour un canton modifié, le
décalage possible est de trois ans. `p75_qualite` porte donc `serie_inconnue`
et `decalage_max_annees` ligne à ligne, sur le modèle de `c68_qualite`. **Une
convention doit être lisible comme une convention.**

**Deux tables de référence, faites pour `76`.** `scrutin_cantonal` (les
renouvellements de 1961 à 2001, sourcés) et `acte_effet` (date d'effet et borne
haute des 343 actes du registre, pas seulement des deux salves). Une convention
qui changerait entre deux fichiers n'en serait plus une.

**La borne haute** est la date d'effet du premier acte postérieur touchant le
même département, plafonnée à `1999-01-01` où `24` reprend la main. Un acte
vaut jusqu'au suivant, et le suivant prend effet à SON scrutin : fermer à sa
signature créerait un trou pendant lequel l'ancienne composition était pourtant
en vigueur. Tout acte postérieur ferme, **même muet** — fermer trop tôt ne coûte
que de la couverture, fermer trop tard pose des rattachements faux qu'aucune
recette ne distinguerait des vrais.

**L'identité des cantons** passe par la composition contre 1999, comme dans
`74` : 80 % de la liste du décret, minimum trois communes entières. On ne
résout **pas** contre 1968, et c'est délibéré — un canton créé en 1973 par
scission a toutes ses communes dans le canton-mère en 1968, et le vote
désignerait la mère. 1968 sert de diagnostic (§ 8), jamais de résolution.

### Trois défauts trouvés par le banc d'essai, et non par la relecture

`sql/banc_75.sh` monte un PostgreSQL jetable, y pose le schéma réel et une
couche de 1999 synthétique (`sql/banc_75_donnees.sql`), puis joue `72` et `75`
sur les **vrais** CSV. Il a rendu trois défauts qu'aucune lecture n'avait vus :

1. **`\set` avale le commentaire de fin de ligne.** `\set fin_serie '1999-01-01'
   -- 24 reprend ici` met tout le texte dans la variable, et le premier cast en
   `date` échoue. Les commentaires vont au-dessus, jamais à côté.
2. **Une commune citée deux fois n'est pas deux rattachements.** Un décret peut
   la nommer deux fois, et le JO et Légifrance se recouvrent sur 283 cantons.
   L'insertion posait deux lignes identiques et `membership_non_chevauchant`
   refusait la seconde, au milieu de l'écriture. `p75_pose` groupe désormais.
3. **Un taux de 333 %.** Le vote se comptait sur des lignes et non sur des
   communes distinctes : un canton de trois communes en « retrouvait » dix.
   *Un taux supérieur à 100 % n'est pas un bon score, c'est un défaut de
   dénombrement.*
4. **Le même symptôme, une seconde cause — et le banc ne l'avait pas vue.**
   Le premier passage sur la VRAIE base a rendu 367 % pour Aureilhan. Le vote
   était bien compté sur des communes distinctes, mais agrégé **sans la
   période** : un canton cité par les deux salves a deux lignes dans `taille`,
   une par période, et un seul vote pour les deux. Corrigé en portant
   `valid_from`/`valid_to` dans la clé du vote — au § 5 comme au § 8.

Le § 5 ter **refuse désormais tout taux supérieur à 100 %**, et refuse en bloc.
La borne ne peut pas être franchie par construction : quand elle l'est, c'est
le dénombrement qui ment, et le dépassement fausse le seuil de 80 % dans le
sens permissif — le seul où plus rien ne le signale ensuite. Deux causes
différentes ont produit ce symptôme en une soirée ; le garde-fou vaut mieux
que la vigilance.

Le banc vérifie aussi la **rejouabilité**, que l'en-tête affirmait : `75` est
joué deux fois de suite et le nombre de rattachements doit être identique.

### Ce que le fichier refuse, et ce qu'il écarte

Le refus porte sur le CANTON quand la nomenclature ne le retrouve pas — trop
court, accord partiel, désaccord, département incompatible, deux cantons du
décret résolus vers la même unité. Règle de `60` : mieux vaut un canton absent
qu'un canton faux.

Il porte sur la **commune seule** quand deux cantons la réclament sur la même
période (§ 5 bis). Trouvé sur pièces : `14163` est donnée à la fois à
Ouistreham-Riva-Bella et à Troarn par la salve de 1982. La contradiction porte
sur cette ligne, pas sur les deux cantons — un refus en bloc serait une
punition collective. C'est le traitement que `59` réserve à ses `atome_ambigu`.

**Une normalisation, une seule** : les espaces autour des traits d'union et la
casse. Sans elle, « Saint-Quentin - Sud » et « Saint-Quentin-Sud » se
disputaient le même canton de 1999 et étaient refusés tous les deux — un canton
perdu par une espace. Elle ne rapproche pas deux noms voisins : deux noms qui
ne diffèrent que par une espace ne sont pas deux noms.

### Hors du fichier

Le décret n° 82-82 (« divers départements ») n'est pas posé — son titre ne
nomme aucun département, et il ne ferme donc aucun intervalle non plus. Huit
actes d'outre-mer et huit actes dont l'effet tombe après 1999 sont écartés et
comptés au § 2.

Ordre : `72` → `73` → `74` → `75`. Table de trace `p75_trace`. **`75`
référence les unités de `24`** : voir « Qui dépend de qui » dans `README.md`
avant de rejouer `24`.

---

## `diag_titre_composition.sql` — le titre juge le découpage du JO

Lecture seule, hors chaîne, comme `diag_marseille.sql`. Ne crée que des tables
`dtc_*`. Prérequis : `72`.

Né d'un refus de `75` le 28 août 2026. Le § 9 avait écarté « Evreux-Ouest » pour
département incompatible — lu sous le 25, cinq communes toutes dans le 27. Ce
n'était pas un département mal lu : le décret n° 82-55 est celui du Doubs, le
n° 82-56 celui de l'Eure et son titre nomme EVREUX-OUEST. **La coupure entre
deux décrets voisins du JO du 22 janvier 1982 est tombée un bloc trop loin.**

Le contrôle est indépendant par construction : `acte_cantonal.cantons_titre`
vient de l'index de Légifrance, `acte_composition.canton` du texte OCRisé du
JO. La colonne dormait sur le disque depuis le moissonnage du 28 août au matin.

**Ce qui est décisif et ce qui ne l'est pas.** Un titre ne nomme pas tous les
cantons touchés : « absent du titre » n'est pas une faute, et le § 2 le compte
à part. Le § 3 seul conclut — un canton absent du titre de SON décret et
réclamé par le titre d'un AUTRE décret **du même Journal officiel**, sans
second réclamant.

Résultats du premier passage :

* **deux cantons égarés**, tous deux dans le JO du 22 janvier 1982 :
  Evreux-Ouest (82-55 → 82-56, les communes donnent raison au titre) et
  Lorient-Centre (82-51 → 82-62, aucun code INSEE pour trancher — sans le
  titre, rien ne l'aurait signalé) ;
* **120 cantons retrouvés sur 184 annoncés, 65,2 %**, dix décrets complets sur
  45 — le rappel de l'extraction décret par décret, jusque-là inconnu.

Portée : **55 actes sur 343** ont un titre renseigné. Le contrôle ne juge pas
le corpus, il juge une fenêtre — mais dans cette fenêtre il ne partage rien
avec ce qu'il juge.

Les corrections se font dans `cantons/composition_jo.py`, à la coupure, jamais
en aval sur les CSV — et chacune doit être adossée à son titre.

---

## 76 — la longue traîne, sur la convention de 75

`76_composition_salves_restantes.sql` pose les compositions de toutes les
salves que `75` n'a pas prises : 1961, 1970, 1974-1976, 1984, 1985, 1988,
1991-1997. Environ 1 240 lignes sur 383 cantons. Chaque année compte peu ;
l'ensemble compte.

**La liste des salves est définie en creux** — les années des actes posables,
moins celles de `75`, moins 1967 — et non écrite à la main. Un décret qui
entrerait demain au registre tombe donc dans `76` sans qu'on y pense. Le
28 août au matin, 207 y sont entrés d'un coup.

### Ce qui n'est PAS dupliqué, et c'est tout le propos

`76` est le jumeau de `75`, section par section, et **les numéros de section
suivent ceux de `75`** pour que les deux fichiers se lisent en regard. Il n'y a
pas de § 2 :

    `scrutin_cantonal` et `acte_effet` ne sont pas reconstruites.
    La convention de date d'effet n'existe qu'à un seul endroit.

C'est la seule chose qu'il fallait absolument ne pas recopier. Deux fichiers
qui définiraient chacun leur convention finiraient par diverger, et le jour où
ils divergeraient **rien ne le dirait** : chacun rendrait des chiffres
cohérents, et la base porterait deux règles sous un seul nom.

La duplication de la mécanique est assumée, et son coût déclaré : un correctif
porté à `75` doit être reporté ici. Le **§ 10 f** rend la chose vérifiable — il
compte ce que les deux fichiers couvrent ensemble, et la somme doit être exacte
(au banc : 209 actes posables porteurs d'une composition = 124 par `75` + 75
par `76` + 10 laissés à 1967).

### 1967 est exclu, et ce n'est pas un oubli

Les six décrets du 20 juillet 1967 prennent effet à la naissance des
départements d'Île-de-France, le **1er janvier 1968** — un fait juridique, pas
le scrutin suivant. La convention y serait fausse de deux mois et demi. Ces
cantons sont déjà en base par deux voies exactes : le recensement de 1968
(`58` + `59`) pour cinq départements, `74` pour les Yvelines dont le fascicule
manque. `73` a mesuré leur accord : 45 accords, 0 désaccord.

*Une convention ne s'applique pas là où un fait est disponible.*

### Ce que `76` doit démontrer, et que `75` ne pouvait pas

Ces salves sont pour la plupart **plus proches de 1999** que celles de 1973.
`75` § 11 mesurait 63,6 % de résolution sans acte intercalé contre 50,8 %
au-delà de trois. Si l'explication tient — les refus viennent de la distance au
point de comparaison, pas d'une lecture douteuse — le § 11 de `76` doit montrer
la même pente. C'est le seul contrôle qui juge l'INTERPRÉTATION des refus, et
non les refus eux-mêmes.

Ordre : `72` → `73` → `74` → `75` → `76`. Table de trace `p76_trace`. **`76`
référence les unités de `24`**, comme `74` et `75`.

Éprouvé par `sql/banc_75.sh`, qui joue désormais `74`, `75` et `76` dans le
même banc — puis `75` et `76` une seconde fois — et vérifie qu'aucun des trois
ne recouvre les autres.

---

## 77 — les transferts de commune, où la date cesse d'être une convention

`77_transferts_dates.sql` pose les changements de canton d'une commune, et il
est le premier de la série dont **la date de début est un fait**.

### La source qu'on avait sous la main depuis le 9 août

`73` § 5 attendait « qu'il ne manque que la convention » pour cinq transferts
tirés du texte des décrets. Il n'en manquait pas.

Le fichier historique du COG 1999 — `Corhistoriq1999.txt`, modalité **43,
changement de canton** — en porte **soixante-six**, avec pour chacun la date de
l'acte, celle de sa publication, **sa date d'effet**, et le canton d'arrivée
codé. `cantons/transferts_insee.py` l'en extrait.

Le dépôt connaissait ce fichier et en avait tiré la conclusion juste — 66
changements seulement, tous postérieurs à 1995, donc aucune reconstitution de
1943-1995 par cette voie. C'était vrai, et cela n'épuisait pas la question :
*une source trop pauvre pour combler un trou peut être exactement assez riche
pour dater ce qu'on a déjà.*

### Les dates confirment `75` au lieu de le démentir

    Saint-Denis-des-Puits, Villebon (28)  décret du 10 avril 1995, JO du 15,
                                          EFFET LE 16 — le lendemain.
    Saint-Alban-de-Roche (38) + 60        décret du 26 février 1997, JO du 27,
                                          EFFET LE 1er AVRIL 1998.

Aucune n'est le premier tour du renouvellement, qui est la convention de `75`.
On y lirait un démenti ; c'est l'inverse :

* un **redécoupage** crée ou modifie des cantons — la carte doit exister au
  scrutin QUI ÉLIT, donc au premier tour ;
* un simple **rattachement** de commune ne demande aucune élection — il prend
  effet quand l'acte le dit, le lendemain de la publication en 1995, à
  l'installation du nouveau conseil (1er avril 1998, après le second tour du
  22 mars) pour la salve de 1997.

**Deux règles différentes parce que les actes sont de nature différente.**
C'est le premier élément extérieur qui vienne éclairer la convention de `75`.

### Deux sources doivent dire la même chose

Le canton d'arrivée est codé par l'INSEE (`dep || CT`). Le § 4 vérifie que le
COG de 1999 posé par `24` place bien la commune dans cette unité — `24` n'a
jamais lu `Corhistoriq1999.txt`. Un désaccord est refusé et listé. Et le § 6 c
compare, pour les trois mouvements connus des deux côtés, le canton **nommé**
par le décret et le canton **codé** par l'INSEE.

### « Place déjà occupée » n'est pas un échec

La salve de 1997 produit 61 de ces 66 mouvements, et c'est celle que `76` a
posée : la composition du canton d'arrivée est souvent déjà lue. Un transfert
écarté à ce titre est donc une confirmation, pas une perte. Le § 4 les compte
à part et nomme l'occupant.

### Deux corrections que le banc a imposées

1. **Le garde-fou a refusé de poser**, et il avait raison : Maxéville et
   Villers-lès-Nancy figurent deux fois dans le fichier de l'INSEE — 1er avril
   puis 13 novembre 1998, **vers le même canton**. Ce n'est pas un double
   déplacement mais une seconde écriture du même fait. On garde la première
   date, `n_actes` conserve la trace du doublon, et le garde-fou porte
   désormais sur le **chevauchement** et non sur la répétition : une commune a
   le droit de bouger deux fois, et les périodes s'enchaînent alors.
2. **`date_publication` est vide** pour les deux actes de 1993, seuls à relever
   d'une convention. Sans repli, `valid_from` partait NULL en écriture. Le banc
   ne l'a pas vu — ses deux atomes n'étaient pas résolus. On retombe sur le
   lendemain de la signature, et un verdict nomme désormais le cas.

Ordre : `72` → `73` → `74` → `75` → `76` → `77`. Trace `p77_trace`. **`77`
référence les unités de `24`**, comme `74`, `75` et `76`.

## 78 — le report EN ARRIÈRE depuis 1999, mesuré avant d'être posé

`sql/78_report_1999_arriere_diag.sql`, **lecture seule**, sur le modèle de
`70`/`71` : on mesure la méthode avant d'écrire quoi que ce soit.

**L'idée.** Les décrets de 1990-1999 sont épuisés comme veine — `72` les a tous
chargés, et sur 83 seuls 19 portent une composition (40 déplacent des parcelles
entre communes, 29 décrivent des tracés de rues, 10 n'ont pas de texte). Ce
n'est donc pas en lisant davantage qu'on remplira la décennie. Mais si le
registre des actes est complet, alors pour un département dont le dernier acte
date de 1988, **rien n'a bougé de 1988 à 1999**, et la composition du COG vaut
pour toute la fenêtre.

C'est le § 5 de `cantons/note_entree_en_base.md` — « étendre là où un acte borne
l'intervalle des deux côtés » — pris par l'autre bout de la chaîne. Et il est
mieux placé là qu'autour de 1968 : le test propre y était déclaré indisponible
parce que les deux côtés venaient d'un OCR ; ici le haut est le COG, qui n'est
pas océrisé.

Mesure préalable sur `decrets_cantonaux.csv` : profondeur médiane **11 ans**,
55 départements sur 100 gagnent 10 ans ou plus, 9 remontent jusqu'à 1973.
La fenêtre couverte est donc grosso modo **1988-1999** — soit exactement le mur
de 1986-1989, que les décrets ne franchissent pas.

### Le contrôle du § 5, et pourquoi il est gratuit

`75` et `76` ont posé, **depuis le texte des décrets**, la composition des
cantons touchés par le dernier acte de leur département, de la date d'effet
jusqu'à 1999. Le COG dit la composition de ces mêmes cantons au 1er janvier
1999. Les deux périodes se touchent sans se recouvrir, et l'hypothèse du report
est précisément qu'elles coïncident. Un JO océrisé d'un côté, un fichier INSEE
de l'autre : contrôle indépendant, et il ne coûte rien puisque les deux couches
sont déjà en base.

**Il ne peut pas prouver le report, il peut le tuer.** Un désaccord est soit un
mouvement non enregistré — et le report meurt sur ce département — soit une
lecture fautive du JO, qui ne dit rien du report. Le § 5 rend donc la **borne
haute** du taux d'erreur, à lire contre les 89,8 % de 1954 → 1968 et les 99,5 %
de 1940 → 1954.

### Deux conventions de plancher, et on retient la prudente

`plancher_effet` (date d'effet, convention de `75`) descend en moyenne 208 jours
plus bas que `plancher_signature`. C'est la seconde qui est retenue : elle ne
suppose rien sur la date d'effet et couvre le cas d'un acte signé avant 1999
dont l'effet tombe après. L'écart est mesuré au § 2 ter — on sait ce que la
prudence coûte avant de la choisir.

### Ce que le banc a corrigé

Banc jetable (`pgserver`, schéma réel, tables vides puis peuplées à la main),
deux passages, sorties identiques, `membership` inchangé.

1. **Un acte d'outre-mer n'est pas un acte sans département.** Le premier jet
   les comptait ensemble sous `length(dep) <> 2` : 17 actes bloquants au lieu
   de 9, et un décret guadeloupéen pouvait abaisser le plafond métropolitain.
   Seul le `dep` VIDE est un poison — il a pu toucher n'importe quel
   département et rien ne dit lequel. *Deux causes d'exclusion ne font pas une
   seule catégorie.*
2. `percentile_cont` n'a pas de variante `numeric` : il rend un
   `double precision` que `round(x, n)` refuse. Cast explicite.
3. `date - date` rend un **entier de jours**, pas un intervalle : `extract(epoch
   FROM …)` y est une erreur, et elle ne se voit pas à la lecture.
4. psql **n'interpole pas ses variables dans une chaîne dollar-quotée** : la
   date du bloc `DO` de prérequis est écrite en clair. Le fichier aurait échoué
   sur son propre contrôle d'entrée.

### Ce qu'il ne mesure pas, et qu'aucune requête ne mesurera

Les transferts isolés de commune que l'annexe VII ne recense jamais par
construction — 274 non datés au registre. Sans décret au registre, le plancher
les ignore et le report passe par-dessus en silence. Seul ordre de grandeur
disponible : 0,29 % des communes en quatorze ans (`70`, `71`).

Prérequis : `24`, `72`, `75`, `76`. Aucune trace : rien n'est écrit.

### `78` — DEUX ERREURS TROUVÉES PAR LE PREMIER PASSAGE RÉEL, corrigées

Le fichier a tourné sur la vraie base le 29 août 2026. Il a rendu ses chiffres,
et deux d'entre eux ont démenti sa propre rédaction.

**1. Le plancher était pris du mauvais côté.** Le § 2 ter rend
`jours_en_trop = +183` sur **96 départements sur 96** : la date d'effet est
toujours POSTÉRIEURE à la signature. J'avais écrit que la signature était « plus
haute, donc plus prudente ». Elle est plus BASSE, donc la fenêtre est plus
LONGUE, et sur l'intervalle [signature, effet) c'est encore l'ANCIENNE
composition qui vaut — celle que le décret défait. Reporter l'état de 1999
par-dessus est faux par construction. `plancher_effet` est retenu ; la
profondeur médiane passe de 10,7 à ~10,2 ans.

*Une borne plus large n'est pas une borne plus prudente ; c'est l'inverse. Le
mot « prudent » avait été écrit avant que le sens de l'écart soit mesuré.*

**2. Le contrôle du § 5 n'est pas indépendant, et je l'avais annoncé comme
tel.** Il rend 676 accords sur 679, soit 99,85 % — un chiffre trop beau, et
c'est ce qui a fait regarder. `75` et `76` ne lisent pas un `unit_id` dans le
décret : ils résolvent le nom du canton **en votant contre la couche de 1999**,
et ne posent qu'au-delà de 80 % de communes partagées. L'échantillon du § 5 est
donc celui qui a été retenu PARCE QU'IL CONCORDAIT avec 1999.

C'est le piège que `70` § 2 documente déjà pour `ferme_canton`, et le fichier
qui le cite est tombé dedans. **Un échantillon filtré par le critère qu'on
mesure ne mesure plus rien.**

Ce que le § 5 dit encore, et c'est peu : le vote se fait au CANTON, la pose à la
COMMUNE, donc une commune minoritaire ressort en désaccord. Il mesure
l'unanimité des votes retenus. Le seul désaccord réel — atome `26344`, Allonnes
contre Sablé-sur-Sarthe, salve de 1982 — est de cette nature.

**D'où les §§ 5 ter et 5 quater**, ajoutés : ils comptent ce que le vote a
ÉCARTÉ (`accord partiel` entre 50 et 80 %, `desaccord` sous 50 %). Ces
cantons-là n'ont jamais été posés, donc n'entrent pas dans le § 5 — et ce sont
précisément ceux où quelque chose a bougé entre l'acte et 1999. Le rapport
`refusés / (refusés + résolus)` est la borne haute honnête du taux d'erreur du
report, et c'est elle qu'il faut confronter aux 89,8 % de 1954 → 1968.

### Ce que le premier passage a établi de solide

| | |
|---|---|
| départements avec un plancher | **96** sur 96, aucun sans acte |
| profondeur médiane | ~10 ans (max 25,5 : Dordogne, Jura, Landes, Deux-Sèvres) |
| atomes de la couche 1999 | 37 266 |
| fenêtre entièrement libre | **35 811 — 96,1 %** |
| déjà pleine | 114 |
| actes connus non dépouillés | **130, sur 56 départements** — ils bornent sans être lus |

**LE VERROU, et il n'était pas prévu : les 9 actes sans département plafonnent
le report au 7 août 1996.** Le plus tardif est un « modification de limites
cantonales » non numéroté de 1996, dont on ignore le département. Tant qu'il
n'est pas attribué, aucun report ne peut franchir cette date sans supposer
qu'il ne concernait pas le département traité — et la profondeur médiane tombe
de 10 ans à **2,4 ans**.

Sept des neuf portent l'objet « modification de limites cantonales », que la
classification de 1990-1999 donne comme des transferts de parcelles sans effet
sur l'appartenance. C'est vraisemblable, ce n'est pas établi. **Les attribuer un
par un est la tâche qui commande tout le reste du chantier** — neuf actes.

### `78` — TROISIÈME CORRECTION, au même endroit : la POPULATION

Le § 5 quater rendait **14,8 %** au premier passage réel. Le chiffre est juste
et la population est fausse : il comptait TOUS les cantons de `p75_lien` et
`p76_lien`, y compris ceux dont le décret n'est pas le dernier acte de son
département.

Un décret de 1973 dans un département qui a rebougé en 1985 n'a aucun rapport
avec le report : la fenêtre s'arrête à 1985 et ne descend jamais jusqu'à 1973.
Que sa composition ne se retrouve pas dans le COG de 1999 est **attendu** —
c'est l'acte de 1985 qui l'a défaite, et cela ne dit rien du report.

Le filtre existait déjà et je ne l'avais pas vu : `75`/`76` posent
`valid_to = least(effet de l'acte suivant, fin de série)`. Un lien dont la
période s'arrête **exactement** à la fin de série est, par construction, un lien
qu'aucun acte postérieur n'a interrompu. C'est la population du report, et elle
seule. Le § 5 (les 679 atomes) filtrait déjà là-dessus ; le § 5 quater, non.

Le § 5 quater affiche désormais **les deux populations côte à côte**, pour que
l'écart soit visible plutôt que corrigé en silence.

*Une mesure juste sur la mauvaise population reste une mesure fausse.* Trois
corrections sur ce fichier, trois fois le même genre de faute : le sens de
l'écart (§ 2 ter), le filtre de l'échantillon (§ 5), la population comptée
(§ 5 quater). Aucune n'était une erreur de SQL. **Ce qu'on compte importe plus
que la façon dont on le compte.**

### Ce que le premier passage a donné, et qui reste vrai

| | |
|---|---|
| départements pourvus d'un plancher | 96 sur 96 |
| profondeur médiane (sur `date_effet`) | **10,3 ans**, max 25,3 |
| atomes de 1999 à fenêtre entièrement libre | **36 557 sur 37 266 — 98,1 %** |
| `jours_en_trop` de la convention « signature » | +183, sur 96 départements sur 96 |
| actes connus non dépouillés | 130, sur 56 départements — ils bornent sans être lus |
| plafond des 9 actes anonymes | **1996-08-07** |

Le § 5 ter donne aussi la répartition des refus, et elle éclaire le poste de
perte connu : `accord partiel` vaut 60 cantons / 413 communes pour `75` et
12 / 85 pour `76`, à un taux moyen de 63,9 % et 69,5 % — donc environ un tiers
des communes de ces listes ne sont pas là où le décret les avait mises.
`trop court` (181 + 97 cantons, moins de trois communes) est exclu du ratio :
ce n'est pas un désaccord, c'est un silence.

## 79 — la composition de 1999 remonte le temps

`sql/79_report_1999_arriere.sql`. **Écrit dans `membership`**, trace `p79_trace`,
qualité `p79_qualite`. À jouer APRÈS `77` — voir l'avertissement d'ordre dans
`README.md`.

**Ce n'est pas une convention, c'est une inférence.** `75` suppose une DATE
(le scrutin suivant la signature) ; `79` suppose une ABSENCE — qu'aucun acte
n'est survenu entre le dernier acte du département et 1999. Une absence se
vérifie, et c'est tout l'objet de `72`. C'est la différence entre poser une
règle et lire un registre.

### Le plancher, le plafond, et la coupure

Plancher = **date d'effet** du dernier acte du département, jamais la signature
(183 jours d'écart, sur 96 départements sur 96 ; sur cet intervalle l'ancienne
composition vaut encore).

Plafond = signature du plus tardif des actes encore SANS DÉPARTEMENT. Au-dessous,
un acte inconnu a pu tomber n'importe où. Plutôt que de s'arrêter là ou de
l'ignorer, `79` **coupe la période en deux** :

    [plafond, 1999)     sous_plafond = false   aucun acte inconnu au-dessus
    [plancher, plafond) sous_plafond = true    un acte inconnu a pu y tomber

Les deux moitiés sont posées, la seconde se retire en une ligne :

```sql
DELETE FROM histgis.membership m USING histgis.p79_qualite q
 WHERE q.membership_id = m.membership_id AND q.sous_plafond;
```

*On signale, on ne supprime pas — mais on rend le retrait possible en une
requête.* C'est le motif de `p76_qualite` et `c68_qualite`, poussé d'un cran :
ici le drapeau ne décrit pas seulement la ligne, il la découpe.

### Ce qui n'est pas posé, et c'est voulu

Un atome dont la fenêtre est **même partiellement** occupée est laissé tel quel.
`59`, `74`, `75`, `76` et `77` sont mieux renseignés que le report ; découper
autour d'eux fabriquerait des périodes que personne ne saurait relire. Le § 5
compte les fenêtres occupées et nomme l'occupant.

Les atomes-fractions sont posés mais marqués (`p79_qualite.fraction`) : les
reporter en arrière affirme que la commune était déjà partagée entre les mêmes
cantons, ce qui est une prétention plus forte que le reste du fichier.

### Le banc

PostgreSQL jetable, `EXCLUDE` simulée par déclencheur (`btree_gist` absente du
binaire embarqué, comme pour `banc_75`). Trois départements, trois régimes :
plancher sous le plafond (coupure), plancher au-dessus (pas de coupure),
fenêtres déjà occupées par `75`/`76`. Un atome-fraction pour la ligne
correspondante.

13 lignes sur 8 atomes, 5 marquées `sous_plafond`, 2 fractions ; deux passages
donnent le même total (31 rattachements, 13 tracés) ; le `DELETE` retire
exactement 5 lignes et laisse la couche de 1999 intacte. Les recettes 10 a à
10 f valent toutes zéro.

*Note : deux passages ne rendent pas des sorties identiques au caractère près —
les `membership_id` avancent avec la séquence. Ce sont les EFFECTIFS qui doivent
coïncider, et ils coïncident.*

### Ce que personne ne verra

Un transfert isolé de commune qui n'a laissé aucun décret au registre. Le
plancher l'ignore, le report passe par-dessus en silence, et aucune recette ne
le distingue d'un rattachement juste. 274 non datés au registre cantonal ; seul
ordre de grandeur mesuré, 0,29 % des communes en quatorze ans (`70`, `71`).

### `79` — premier passage réel, 29 août 2026 : 52 798 rattachements

| | |
|---|---|
| posés | **52 798** sur 36 557 atomes |
| dont `sous_plafond = false` | 36 557 — `[1987-02-24, 1999-01-01)` au plus large |
| dont `sous_plafond = true` | 16 241 — `[1973-09-23, 1987-02-24)` au plus large |
| dont atomes-fractions | 1 344 |
| fenêtres déjà occupées, laissées | 709 |
| jalon 1968 | 32 842, **intact** |

`snapshot` : 1988 → 17 482, 1990 → 18 362, 1993 → 23 536, 1995 → 25 913,
1997 → 25 913, 1998 → 37 267. **Le trou de 1941-1998 cesse d'être un trou pour
la moitié de sa longueur.**

### La recette qui a crié, et c'était elle qui avait tort

Le § 10 c annonçait « attendu : 37 266 » et a rendu 37 286. Or `79` ne pose que
des lignes qui s'arrêtent au 1er janvier 1999 : aucune ne peut contenir le
1er juin 1999, donc ce compte ne POUVAIT pas bouger.

Le nombre était recopié de `78` § 4, où il désigne les atomes des départements
**pourvus d'un plancher** — pas la couche de 1999. Les 20 de l'écart sont des
atomes dont le département n'a aucun acte au registre : ils n'ont jamais été
dans le périmètre.

Corrigé par un **témoin pris avant l'écriture** (`p79_temoin`, § 2), et les
recettes 10 b et 10 c affichent désormais un ÉCART, qui doit valoir zéro. Un
§ ajouté liste les atomes hors périmètre par département — un département sans
aucun acte est soit un fait, soit un trou du moissonnage, et il faut pouvoir le
regarder.

*Une recette qui compare à un nombre venu d'ailleurs mesure la mémoire de celui
qui l'a écrite, pas la base.* Quatrième correction de cette famille sur ce
chantier, et la première qui se manifeste par une fausse alerte plutôt que par
un silence — c'est le bon sens de l'erreur.

### CONSÉQUENCE À CONNAÎTRE : la recette de `24` est périmée

`24_canton_moderne.sql` compte les rattachements tombant dans le trou
1941-1998 et **en attend zéro** (elle en trouvait deux, dont la ligne de `38`).
Après `79`, elle en trouvera **plus de cinquante mille**, et c'est normal : le
trou n'est plus un trou. La recette doit être réécrite — elle mesurait une
absence qui n'a plus lieu d'être.

## `72` § 3 ter — « modification de limites cantonales » recouvre deux choses

Trouvé le 29 août 2026 en lisant les huit derniers actes anonymes. Le libellé
ne distingue pas :

* un décret qui déplace une **commune** d'un canton à un autre — événement ;
* un décret qui échange des **parcelles** entre deux communes voisines. Les
  limites cantonales bougent « par voie de conséquence », mais aucune commune
  ne change de canton. Pour le `membership`, non-événement : c'est de la
  géométrie, et la géométrie du dépôt est celle de 2011.

La distinction ne se lit QUE dans le texte. D'où `acte_sans_effet`, alimentée
par `cantons/acte_sans_effet.csv` — **un recueil de preuves, pas une liste
d'identifiants** : chaque ligne cite le JO, le fichier, la ligne et le passage.
Un acte qui y figure ne borne plus rien, ni plancher ni plafond.

### Les huit actes, lus dans `jorf_txt` — rien à télécharger

Les six JO étaient déjà OCRisés sur disque. Ce n'était pas un chantier
d'acquisition mais de lecture.

| acte | département | nature | effet |
|---|---|---|---|
| 24.02.1987 | Aube (10) | parcelles, St-André-les-Vergers ↔ La Rivière-de-Corps | **non** |
| 06.08.1986 (a) | Saône-et-Loire (71) | parcelles, Sanvignes ↔ Saint-Vallier | **non** |
| 06.08.1986 (b) | Landes (40) + Pyr.-Atl. (64) | parcelles, Hastingues ↔ Sames | **non** |
| 28.08.1985 | Loir-et-Cher (41) | parcelles, Naveil ↔ Vendôme | **non** |
| 16.08.1985 (a) | Yvelines (78) | parcelles, Mantes-la-Jolie ↔ Limay | **non** |
| 16.08.1985 (b) | Meurthe-et-Moselle (54) | parcelles, Dombasle ↔ Sommerviller | **non** |
| 25.01.1982 `82-82` | **Meurthe-et-Moselle (54) SEUL** | 9 articles, création de cantons | **OUI** |
| 12.08.1964 `64-847` | Rhône (69) | territoire entre 5e et 6e cantons de Lyon | **non** |

**`82-82` est réglé sur pièce.** Le titre Légifrance dit « dans divers
départements » et c'est faux : le JO du 26 janvier 1982 imprime
« (Département de Meurthe-et-Moselle) » sous le numéro, et les neuf articles ne
nomment que des communes de ce département. L'ancien fichier lui donnait 54 par
défaut — *la valeur était juste et le fondement ne l'était pas ; c'est une
différence qui compte, parce qu'un défaut juste par hasard le reste jusqu'au
jour où il ne l'est plus.*

**Deux paires d'identifiants ne sont pas distinguables** : les deux décrets du
16.08.1985 et les deux du 06.08.1986 portent des titres Légifrance identiques,
et rien de local ne dit lequel est lequel. Sans portée ici, puisque les deux
membres de chaque paire sont des non-événements — l'indétermination porte sur
l'étiquette, pas sur le fait.

### Conséquence : plus aucun acte anonyme, donc plus de plafond

`sous_plafond` ne marquera plus rien : `79` pose une ligne par atome au lieu de
deux, et toutes sont propres.

### ET LE PROCHAIN LEVIER EST CHIFFRÉ

Qui fixe le plancher, par nature d'acte :

| départements | objet de l'acte |
|---|---|
| 47 | creation et modification de cantons |
| **38** | **modification de limites cantonales** |
| 9 | creation de cantons |
| 2 | suppression de cantons |

**38 départements sur 96 ont leur plancher fixé par un acte de la classe dont
7 sur 7 lus se sont révélés être des non-événements.** Si la classe entière était
lue et se confirmait, le report passerait de **972 à 1 329 département-années**,
médiane de 9,8 à **13,5 ans**. C'est +37 %, et les JO sont largement sur disque.

À lire, pas à supposer : sept observations ne font pas une règle sur cent deux
actes. Mais on sait désormais ce que la lecture vaut.

### `78` après `79` — le diagnostic prenait le remède pour la maladie

Trouvé au troisième passage réel, le 29 août 2026. `78` a rendu
`fenetre_entierement_libre = 0` et `deja_pleine = 37 238` : il tournait sur une
base où `79` était déjà posé, et comptait **les lignes de `79` comme des
fenêtres occupées**. Rien ne le signalait — les chiffres restaient cohérents,
ils ne voulaient simplement plus rien dire.

`78` mesure une OPPORTUNITÉ, pas un état. Son § 4 exclut désormais de
l'occupation tout ce que `p79_trace` porte. Vérifié au banc : 4 fenêtres libres
avant `79`, 4 après.

*Un diagnostic qui voit l'effet du remède le prend pour la maladie.* C'est le
même genre de faute que le § 5 quater (mauvaise population) et que le § 10 c
(témoin venu d'ailleurs) : jamais une erreur de SQL, toujours une erreur sur ce
qu'on croit compter.

### Le passage sans plafond — ce qui a changé, et ce qui n'a pas changé

| | avec plafond (1987-02-24) | sans plafond |
|---|---|---|
| lignes posées | 52 798 | **36 557** |
| atomes | 36 557 | 36 557 |
| marquées `sous_plafond` | 16 241 | **0** |
| **atome-années couvertes** | **345 840** | **345 840** |

**La couverture est identique au million près — elle l'était déjà.** Lever le
plafond n'a pas étendu le report d'un jour : il a fusionné les deux moitiés de
chaque période. Ce que les huit lectures ont acheté, ce sont **85 741
atome-années qui ont cessé d'être douteuses**, soit un quart du total, et une
table deux fois plus petite.

*Un gain qui ne se voit pas dans le total peut être le seul qui compte.*

### Paris n'a pas de plancher, et c'est un fait

Les 20 atomes hors périmètre du § 10 b/c sont ceux du département 75
(`Paris-01` et suivants, pseudo-cantons de `25`). Aucun décret cantonal
parisien n'est au registre — Paris ne relève pas du régime des décrets de
délimitation cantonale. Ce n'est pas un trou du moissonnage.

## Les 28 plancher-fixeurs de la classe « limites cantonales » sont relus

29 août 2026. Les 28 départements dont le plancher était fixé par un acte de
cette classe ET dont le texte est en clair sur Légifrance. Relus dans le
navigateur, **verdict écrit par acte** dans `cantons/acte_sans_effet.csv`, avec
la citation de l'article 1er.

| verdict | actes |
|---|---|
| échange de parcelles entre communes | 24 |
| axe de voie fixant une limite interne (Caen-I / Caen-III) | 1 |
| **commune entière change de canton — ÉVÉNEMENT** | **2** |
| (déjà connu : décret n° 96-709, Han-devant-Pierrepont) | 1 |

**Les deux événements sont exactement ceux que `transferts_legifrance.csv`
connaissait déjà** — Saint-Alban-de-Roche (38) et Saint-Denis-des-Puits +
Villebon (28). Une relecture indépendante retrouve les mêmes deux et n'en
invente aucun : c'est le meilleur contrôle qu'on pouvait espérer sur ce lot.

### Pourquoi il a fallu relire ce qui avait déjà été lu

Le dépouillement du 28 août avait établi « 40 des 56 sont des transferts de
parcelles » — mais **n'avait conservé que l'agrégat**. Le verdict par acte
n'existait nulle part, donc il n'était pas réutilisable. *Une classification qui
ne survit qu'en compte a été faite pour rien : il faut la refaire pour s'en
servir.* `acte_sans_effet.csv` la porte désormais acte par acte, citation à
l'appui.

### Le gain, et la correction de mon estimation

`acte_sans_effet` passe de 7 à 32 actes.

| | dép-années | médiane |
|---|---|---|
| avant | 972 | 9,8 ans |
| **après** | **1 144** | **13,4 ans** |

**+18 %, non +37 % comme je l'avais estimé.** L'estimation supposait que toute
la classe disparaîtrait du calcul ; en réalité **écarter un acte promeut le
précédent du même département, qui est souvent de la même classe**. 25 actes de
la classe fixent encore un plancher, contre 38 avant. Il reste un tour à faire,
et il rendra moins que le premier.

*Un levier qui se déplace quand on l'actionne ne rend pas ce qu'il promettait.*

## `24` — la recette du trou 1941-1998 est réécrite

Elle comptait les rattachements de la période et **en attendait zéro**. C'était
juste tant que la lacune était totale ; après `59`, `74`-`77` et `79`, elle en
trouve des dizaines de milliers. Elle mesurait une absence qui n'a plus lieu
d'être.

Elle contrôle désormais une **filiation** : chaque rattachement de la période
doit venir d'un fichier qui l'assume par sa table de trace, et c'est
`sans_trace` qui doit valoir zéro. La sortie nomme le poseur ligne par ligne.

*Une recette qui contrôle une absence expire le jour où l'absence est comblée ;
une recette qui contrôle une filiation ne périme pas.*

`24` tournant avant ces fichiers, il crée leurs traces vides avec
`IF NOT EXISTS` — chacun les crée de la même façon, rien n'est écrasé. Éprouvé
au banc : le poseur est nommé, et la ligne sans trace (celle de `38`, dette du
17 août) ressortait bien comme telle.

**Depuis le 2 septembre 2026, `p38_trace` est de la partie**, et la recette
compte ses lignes posées *comme ses lignes remontées* : `38` fait démarrer en
1982 trois rattachements qui existaient déjà, ce qui les fait entrer dans le
trou sans qu'aucune ligne soit créée. *Une trace qui ne dirait que les
insertions laisserait orphelin ce que le fichier s'est contenté de déplacer.*
Attention à la définition : `p38_trace` porte une colonne `avant` que les autres
n'ont pas, et `CREATE TABLE IF NOT EXISTS` n'ajoute pas de colonne à une table
qui existe déjà — les deux déclarations, celle de `24` et celle de `38`, doivent
rester identiques.

### Piège d'écriture : `csv.writer` termine ses lignes en CRLF

Le chargement de `acte_sans_effet.csv` a échoué au premier essai —
`unquoted carriage return found in data, line 9`. Le fichier avait été créé à la
main en `\n` puis complété par un script Python : **`csv.writer` utilise `\r\n`
par défaut** (c'est le RFC 4180), et `newline=''` empêche justement la
traduction. D'où un fichier aux fins de ligne mixtes, que `COPY … FORMAT csv`
refuse.

`72` étant joué avec `-1`, la transaction a été annulée en entier et la base est
restée dans son état précédent — **l'échec n'a rien coûté, et c'est le `-1` qui
l'a rendu gratuit**. Les deux CSV ont été normalisés en `\n`.

**Règle** : tout script qui écrit un CSV du dépôt passe
`lineterminator='\n'` à `csv.writer`. Un fichier à fins de ligne mixtes se lit
parfaitement en Python et casse au chargement — le genre de défaut qui ne se
voit que du côté où on ne regarde pas.

## ÉTAT ARRÊTÉ AU SOIR DU 29 AOÛT 2026 — `79` après la relecture de la classe

**C'est l'état de référence.**

| | avant la relecture | après |
|---|---|---|
| plancher médian | 10,3 ans | **13,8 ans** |
| lignes posées | 36 557 | 36 296 |
| **atome-années couvertes** | 345 840 | **422 838 (+22 %)** |
| fenêtres occupées, non posées | 709 | 970 |
| départements au dernier acte non dépouillé | 57 (23 649 lignes) | **44 (17 333)** |

`snapshot` : 1988 → 21 531, 1990 → 23 233, 1993 → 29 377, 1995 → 30 785,
1998 → 37 006. Écarts 1968 et 1999 à zéro, recettes 10 a à 10 f propres.

### LE COÛT QUI APPARAÎT AVEC LA PROFONDEUR

**261 atomes de moins sont posés qu'au passage précédent**, et ce n'est pas une
régression : leur fenêtre s'est allongée et touche désormais un rattachement
déjà en place, si bien que la règle « fenêtre ENTIÈREMENT libre » les écarte en
entier. On gagne de la profondeur et on perd des atomes.

`78` § 4 sépare les deux cas : **289 sont seulement PARTIELLEMENT occupés**,
donc récupérables en posant sur la seule part libre ; 681 sont entièrement
couverts et n'ont rien à gagner.

La règle « tout ou rien » avait été choisie parce que découper autour d'un
occupant « fabriquerait des périodes que personne ne saurait relire ». À 289
atomes, l'argument s'affaiblit : ce sont des périodes bornées des deux côtés par
des faits, et les décrire coûte une colonne. **C'est le prochain gain, et il est
petit mais propre.**

*Une règle prudente coûte d'autant plus cher que ce qu'elle protège grandit.*

### La médiane annoncée était 13,4, elle est 13,8

L'écart vient de mon estimation, pas de la base : je calculais la date d'effet
par « signature + 183 jours », le fichier la lit dans `scrutin_cantonal`. Le
`jours_en_trop` du § 2 ter est d'ailleurs passé de 189 à 264 — les planchers
ayant reculé vers des actes plus anciens, où l'écart signature/effet est plus
long.

---

## 82 — la trame communale historique, à côté et non à la place

`82_anr_geom.sql` est le premier fichier du dépôt à poser une géométrie
**datée**. Il ne s'insère pas dans la chaîne de reconstruction : il se joue
après elle, se défait par un `DROP`, et ne touche ni `membership` ni
`atom_geom`.

| ce qu'il lit | ce qu'il écrit | trace | `-v` |
|---|---|---|---|
| `anr_commune` (ogr2ogr), `build/anr_variantes.csv`, `atom` | `atom_geom_anr`, `anr_variante`, `a82_doublon`, `snapshot_geom_anr()`, `check_geom_anr()` | `a82_trace` | `variantes` |

**Prérequis** : charger la couche `geometries_only_processed` du GeoPackage ANR
avec `ogr2ogr` (commande dans l'en-tête du fichier), et avoir `build/anr_variantes.csv`
— produit par `sorties/anr/anr_variantes_verdict.py`, qui doit être relancé si le
jeu ANR change.

**Il ne crée aucune unité et n'en référence aucune** : les deux pièges de rejeu
ci-dessus ne le concernent pas, et rien n'a besoin d'être ajouté à la liste
« Qui dépend de qui » de `README.md`. C'est voulu — une géométrie n'a pas à
connaître les cantons.

**Deux lectures qui se ressemblent et ne sont pas la même.** Le § 8 liste les
atomes qu'ANR ne pourvoit à **aucune** date : six. La recette « trou réel » de
`check_geom_anr()` compte ceux qui manquent **à la date demandée** et qui vivent
à cette date : quarante à 1870, dont vingt à Paris. Trois atomes séparent les
deux listes — Sébazac-Concourès, Goutrens, Roches-Prémarie-Andillé, pourvus sur
une fenêtre qui s'arrête avant 1870. *Deux questions voisines n'ont pas la même
réponse, et c'est la question qu'il faut lire, pas le nombre.*

**`banc_82.sh`** l'éprouve sur un PostgreSQL jetable, sans postgis : la
géométrie y devient l'empreinte MD5 du WKB réel, ce qui permet d'exercer R2 et
les aires pour de vrai. Il a trouvé deux défauts que la relecture n'avait pas
vus — voir `JOURNAL.md` au 1ᵉʳ septembre.

---

## `84` — la carte nettoyée, dérivée et non substituée

| entrées | crée | trace | variables |
|---|---|---|---|
| `atom_geom_anr`, `atom_geom`, `membership`, `atom` | `partition_reprise()`, `carte_partition_atome()`, `carte_partition()`, `check_partition()`, `partition_journalise()` | `p84_trace`, à remplir par `CALL partition_journalise(…)` | `date`, `dep` |

**Il ne modifie aucune table du modèle.** `atom_geom`, `atom_geom_anr` et
`membership` sont intacts, `snapshot_geom_anr()` répond comme avant : `84` est
une lecture, pas une migration. Le défaire, c'est `DROP` sur cinq routines et
une table.

**Ce qu'il corrige** : la couture de la trame hybride. `82` a laissé un repli
(R5) sur `atom_geom`, et là où un atome y retombe pendant que ses voisins
viennent d'ANR, les bords ne coïncident plus — 4 542,8 km² de recouvrement à
1870 sur l'export web, contre 1,0 km² entre deux polygones ANR. Ce chiffre-là
n'est pas dans `check_geom_anr`, qui joint `atom_geom_anr` à elle-même :
*une recette qui mesure la source ne mesure pas le composite qu'on en tire.*

**Ordre** : après `82`, et sans rapport avec les autres. Il ne crée aucune unité
et n'en référence aucune ; comme `82`, il n'entre pas dans la liste « Qui dépend
de qui » de `README.md`.

**`banc_84.py` l'éprouve hors base**, sur `cartes/web/donnees/` — un algorithme
topologique ne s'éprouve pas sur des empreintes MD5 comme `banc_82.sh`, il lui
faut de la vraie géométrie. Il a trouvé les deux règles fausses que le fichier
raconte, et le piège du cadre départemental (478 km² de Seine offerts à la
Seine-et-Oise). Les comptes qu'il rend sont exacts, ses km² approchés à ±0,3 %.

**Non joué au 2 septembre 2026.** Le SQL a été écrit sans accès à une base.
`check_partition('1870-01-01', '01')` est ce qui dira ce qu'il en reste : la
ligne « recouvrement hors fraction » doit valoir 0,000.
