# Chargement PostGIS — histgis

Charge les CSV de `build/` (sortie de `trfgis_extract.py`) dans un schéma
PostgreSQL/PostGIS `histgis`. Cette passe couvre **les attributions**, pas
encore les géométries.

## Lancer

```bash
createdb histgis                 # une fois
cd sql && ./rebuild.sh           # tout : 01→04, GEOFLA, 05, 06, 07, 11
./controle_gay.sh                # contrôle indépendant, facultatif
```

`rebuild.sh` localise seul `COMMUNE.SHP` sous `sources/geofla/` et
`v_mvt_commune_*.csv` à la racine, et refuse de démarrer sans eux. Pour ne
charger que les attributions, sans géométrie : `./load.sh`.

Toute modification de `geom_correspondance.csv` ou des CSV de `build/` impose
`rebuild.sh` complet — ces fichiers sont lus par `02_load.sql`, pas par `05`.

Prérequis : PostgreSQL ≥ 13, extensions `postgis` et `btree_gist`
(paquet `postgresql-contrib`). Le script est **destructif** : il fait
`DROP SCHEMA histgis CASCADE` avant de recharger.

Les quatre fichiers s'enchaînent seuls, mais restent lançables un par un :

| Fichier | Rôle |
|---|---|
| `01_schema.sql` | tables, contraintes, index |
| `02_load.sql` | `\copy` des CSV, transformations, reconstruction des noms |
| `03_functions.sql` | `snapshot()`, `unit_nom()`, contrôles |
| `04_checks.sql` | rapport de recette (lecture seule) |

## Qui dépend de qui — à lire AVANT de rejouer un fichier

Écrit le 20 août 2026, après que l'ignorance de ces règles eut cassé la base
deux fois dans la même journée.

Les fichiers numérotés sont conçus pour se rejouer seuls : chacun retire son
passage par sa table de trace avant de recommencer. **C'est vrai isolément et
faux dans la chaîne**, pour deux raisons distinctes.

### 1. Un fichier qui crée des UNITÉS ne peut pas être rejoué tant qu'un autre les référence

`24_canton_moderne.sql`, `27_circo_2012.sql` et `28_circo_1986.sql` suppriment
leurs unités avant de les recréer. La clé étrangère `membership_unit_fk` le
refuse dès qu'un rattachement posé par un AUTRE fichier pointe dessus :

```
ERROR: update or delete on table "unit" violates foreign key constraint
DETAIL: Key (unit_id, niveau)=(0138, canton) is still referenced from membership
```

Qui référence quoi, mesuré :

| unités de | référencées par |
|---|---|
| `24` (cantons 1999-2012) | `38_decret_1982_ain`, `41_retablissement` |
| `27` / `28` (circos modernes) | `15_creation_arriere`, `41`, `42` |

**Marche à suivre** : mettre de côté les rattachements concernés, jouer le
fichier, les remettre, puis rejouer ce qui en dépend. Défaire par la trace
quand elle existe — `38_decret_1982_ain.sql` **n'en a pas**, il faut sauver ses
lignes à la main.

### 2. Une suppression en cascade détruit le travail des fichiers suivants

Plus insidieux, parce que **rien n'échoue**. `24` supprime ses 732
atomes-fractions avant de les recréer ; la cascade emporte tous les
`membership` qui s'y rattachaient — dont les circonscriptions que `27` et `28`
y avaient posées. `24` recrée les atomes, personne ne recrée les circos.

Constaté le 20 août : 261 rattachements de circonscription sur fractions pour
998 fractions existantes. La base restait parfaitement cohérente ; aucune
recette ne signalait rien ; seul un coup d'œil à la carte l'a vu — quatre
communes des Basses-Pyrénées avaient disparu entre 1987 et 1999.

**Après avoir rejoué `24`, il faut donc rejouer `43_circo_fraction.sql`**, qui
repose les circonscriptions manquantes sans toucher aux unités.

### Séquence sûre après un rejeu de `24`

```bash
# 1. sauver ce qui pointe sur les unités de 24 (38 n'a pas de trace)
psql -d histgis -c "CREATE TABLE reprise_24 AS SELECT m.atom_id, m.unit_id,
    m.niveau, m.valid_from, m.valid_to FROM membership m
   WHERE m.niveau='canton' AND EXISTS (SELECT 1 FROM canton_moderne_trace t
         WHERE t.quoi='unit' AND t.cle=m.unit_id);"
psql -d histgis -c "DELETE FROM membership m USING retablissement_trace t
   WHERE t.membership_id=m.membership_id; TRUNCATE retablissement_trace;"
psql -d histgis -c "DELETE FROM membership m WHERE m.niveau='canton'
   AND EXISTS (SELECT 1 FROM canton_moderne_trace t
       WHERE t.quoi='unit' AND t.cle=m.unit_id);"

# 2. reconstruire
psql -d histgis -f sql/24_canton_moderne.sql

# 3. remettre, puis rejouer ce qui dépend de la couche
psql -d histgis -c "INSERT INTO membership (atom_id,unit_id,niveau,valid_from,valid_to)
   SELECT r.* FROM reprise_24 r WHERE EXISTS (SELECT 1 FROM unit u
     WHERE u.unit_id=r.unit_id AND u.niveau=r.niveau);"
psql -d histgis -f sql/43_circo_fraction.sql
psql -d histgis -f sql/41_retablissement.sql
python3 cartes/export_web.py
```

### Les fichiers qui attendent un chemin en ligne de commande

Cinq fichiers chargent leur source par `\copy` depuis une **variable psql**.
Sans `-v`, le chemin est vide et psql échoue sur un message opaque qui ne nomme
ni le fichier ni la variable :

```
psql:sql/27_circo_2012.sql:76: error: :: Aucun fichier ou dossier de ce nom
```

| fichier | variable | valeur |
|---|---|---|
| `02_load.sql` | `f` | dossier `build/` |
| `06_insee_mvt.sql` | `mvt`, `butoir` | `sources/v_mvt_commune_2025.csv` |
| `08_controle_gay.sql` | `mapping` | correspondance de Gay |
| `27_circo_2012.sql` | `circo` | `circo/circo_2012.csv` |
| `28_circo_1986.sql` | `circo` | `circo/circo_1986.csv` |
| `40_outremer.sql` | `circo_om` | `circo/circo_outremer_1986_2012.csv` |
| `45`, `46` | `hac` | `hac/hac_filiation.csv` — **ont un défaut** |

`\copy` résout les chemins relatifs depuis le répertoire de LANCEMENT, pas
depuis le fichier `.sql` : passer des chemins absolus. `rejouer_apres_rebuild.sh`
le fait ; un lancement à la main doit y penser.

**Les trois derniers portent un `\if :{?var}` avec une valeur par défaut**, les
autres non. C'est une incohérence à corriger : un fichier qui échoue faute d'un
argument devrait le DIRE, pas produire « :: Aucun fichier ».

### La règle générale

**Une table de trace protège son fichier, pas ses voisins.** Elle dit ce qu'un
fichier a posé ; elle ne dit rien de ce que d'autres ont bâti par-dessus. Avant
tout `DELETE` en cascade, se demander qui s'appuie sur ce qu'on retire — la
base ne le dira pas, puisqu'il ne restera aucune contradiction.

## Modèle

Géométrie et attribution restent découplées, comme prévu.

- **`atom`** — plus petite unité au rattachement stable : une commune Cassini
  entière, ou une fraction (`atom_id = 'cassini#canton'`, `fraction = true`)
  quand un pseudo-canton recouvre plusieurs cantons réels.
- **`unit`** — canton ou circonscription, identité pérenne.
- **`unit_version`** — le nom d'une unité sur un intervalle, reconstruit à
  partir des renommages détectés année par année.
- **`membership`** — le cœur : `(atom, unit, [valid_from, valid_to))`.
  La géométrie d'un canton à une date = union des atomes rattachés à cette
  date. Rien n'est pré-dissous.
- **`regime_electoral`** — régime de scrutin déduit, année par année.
- **`diag_*`** — traces des cas douteux de l'extraction. À consulter, pas à
  joindre.

L'intégrité temporelle repose sur deux contraintes `EXCLUDE USING gist` :
un atome n'appartient qu'à une unité par niveau à un instant donné, et deux
versions d'une même unité ne se chevauchent pas. C'est la base qui refuse
les incohérences, pas le code de chargement.

## Interroger

```sql
SET search_path TO histgis, public;

-- composition des cantons au 1er juin 1885
SELECT * FROM snapshot('1885-06-01', 'canton');

-- effectifs à une date
SELECT * FROM count_units('1914-06-01');

-- nom d'une unité à une date
SELECT unit_nom('0320', '1885-06-01');
```

Contrôles : `check_gaps(niveau)`, `check_coverage(date)`,
`check_nesting(date)`, `check_orphans()`.

## Résultat de l'essai à blanc

Chargement rejoué intégralement sur PostgreSQL 16 (cf.
`../rapport_chargement.txt`) : 38 442 atomes, 4 838 unités, 5 057 versions,
293 233 rattachements. Aucun chevauchement, aucun orphelin, couverture
canton/circo complète.

Les effectifs recoupent l'histoire :

| Date | Départements | Cantons | Circonscriptions |
|---|---|---|---|
| 1870 | 89 | 2 948 | 89 (scrutin de liste) |
| 1876 | 87 | 2 862 | 535 (uninominal) |
| 1885 | 87 | 2 867 | 87 (retour à la liste) |
| 1914 | 87 | 2 918 | 580 |
| 1928 | 90 | 3 024 | 590 |
| 1940 | 90 | 3 028 | 595 |

La perte puis le retour de l'Alsace-Moselle apparaissent au bon endroit : 89
→ 87 → 90 départements, et 1 690 atomes ont un trou de chronologie de
1871 à 1919 exactement.

## La 3e colonne d'`atom.csv` : deux formats possibles

Le loader accepte les deux sorties de `trfgis_extract.py` et range la valeur
dans la bonne colonne :

| build lancé avec | contenu de la colonne | colonne remplie |
|---|---|---|
| `--geom-col insee` | `01003`, `2A004`… | `atom.insee_geofla` |
| `--geom-col com_act` (défaut) | `1`, `2`, `3` | `atom.com_act` |

Les deux ne peuvent pas être remplies en même temps — l'extracteur n'écrit
qu'une colonne. Pour la géométrie c'est `insee` qu'il faut :

```bash
python3 trfgis_extract.py build sources/trfgis/communes/Nomenclatures \
    --out build --mapping sources/trfgis/cantons/Nomenclatures --geom-col insee
```

`--mapping` n'est pas optionnel en pratique : sans lui les pseudo-cantons ne
sont plus éclatés et les 333 atomes-fractions disparaissent.

## Pourquoi `com_act` n'était pas le bon choix

`atom.csv` porte une colonne intitulée `insee` qui vaut 1, 2 ou 3 — ce n'est
pas un code commune. `trfgis_extract.py` utilise `CLE_GEOM = "com_act"` pour
le rattachement à la trame GEOFLA 2011, or le codebook TRF-GIS définit
`com_act` comme un **statut** :

```
com_act   1 Current   2 Former (post-1943)   3 Former (pre-1943)
```

Le vrai code commune est la colonne `insee` des fichiers
`COG_COMMUNES_YYYY.txt` (`01003`, `01004`…). D'où le `--geom-col insee` de la
section précédente.

Attention : 37 648 codes Cassini pour 37 584 codes INSEE en
1870 — la correspondance n'est pas bijective, plusieurs communes historiques
partagent un code INSEE actuel. `geom_correspondance.csv` (chargé dans
`diag_geom_correspondance`) traite déjà les cas lourds : Lyon, Marseille,
fusions récentes.

## Autre point à trancher

132 circonscriptions citées par le membership n'existent pas dans les
nomenclatures — Paris (`U7580@…`, `U7581@…`) et Bouches-du-Rhône
(`U1381@…`), soit 134 rattachements. Elles sont créées avec
`provisoire = true` et `nom IS NULL` pour ne pas perdre l'information. Ce
sont les pseudo-circonscriptions de type arrondissement urbain, écartées à
l'extraction (`doublons_ecartes`). À reprendre côté extracteur si tu veux
leurs noms.

## Géométrie

La trame de référence est **GEOFLA 2011** (édition `GEOFLA_1-1_SHP_LAMB93_FR-ED111`),
celle sur laquelle TRF-GIS a bâti ses nomenclatures : les codes d'`insee_geofla`
lui correspondent exactement. Elle est livrée dans le dépôt de reproduction de
TRF-GIS, ce qui évite de dépendre du catalogue IGN :

```bash
python3 trfgis_fetch_inspect.py fetch repro \
    --match '^COMMUNE\.(SHP|SHX|DBF|PRJ)$' --dest ./geofla --dry-run
```

Retirer `--dry-run` une fois la taille vérifiée (~18 Mo). Puis :

```bash
ogr2ogr -f PostgreSQL PG:"dbname=histgis" \
    sources/geofla/.../COMMUNES/COMMUNE.SHP \
    -nln histgis.geofla_commune -nlt MULTIPOLYGON \
    -lco GEOMETRY_NAME=geom -lco FID=gid -a_srs EPSG:2154 -overwrite

psql -d histgis -f sql/05_geom.sql
```

`-a_srs` plutôt que `-t_srs` : les données SONT déjà en Lambert-93, on déclare
sans reprojeter. Si les accents des noms de communes ressortent cassés,
préfixer la commande par `SHAPE_ENCODING=ISO-8859-1`.

La jointure directe laisse 1 504 atomes sans polygone : leur code INSEE
d'époque a disparu avant 2011, presque toujours par fusion (loi Marcellin,
1971). Deux scripts les rattrapent.

```bash
curl -O https://www.insee.fr/fr/statistiques/fichier/8377162/v_mvt_commune_2025.csv
psql -d histgis -v mvt="$PWD/v_mvt_commune_2025.csv" -f sql/06_insee_mvt.sql
psql -d histgis -f sql/07_reliquat.sql
```

`06` rejoue les mouvements de communes de l'INSEE jusqu'au 1ᵉʳ janvier 2011 et
remonte les chaînes d'absorption : 1 487 atomes récupérés, chaînes de deux
sauts au maximum. `07` traite les 17 derniers — disparus avant 1943, donc hors
du fichier INSEE — à partir des fusions documentées par HAC
(`source_data/HAC/communal.tab`), rattachés **par nom** puisque leurs codes
n'existent nulle part.

Répartition finale des sources dans `atom_geom` :

| `source` | Atomes | Fiabilité |
|---|---|---|
| `geofla` | 36 901 | jointure directe sur le code |
| `successeur` | 1 487 | mouvements INSEE, auditables ligne à ligne |
| `union_prefixe` | 27 | Lyon et Marseille, arrondissements réunis |
| `hac` | 11 | successeur unique, sans ambiguïté |
| `absorbee` | 10 | `geom_correspondance.csv`, saisi à la main |
| `hac_partage` | 6 | **choix arbitraire** : commune répartie entre plusieurs successeurs, le premier est retenu |

Ensuite :

```sql
SELECT unit_id, nom, geom FROM snapshot_geom('1885-06-01', 'canton');
```

### Le point délicat : les polygones partagés

Un polygone GEOFLA peut servir à plusieurs atomes, pour deux raisons
distinctes :

- deux communes historiques fusionnées depuis 2011 partagent un code INSEE ;
- une commune éclatée entre plusieurs cantons donne autant d'atomes-fractions,
  qui n'ont pas de géométrie propre.

Si ces atomes tombent dans des unités différentes, les polygones dissous se
recouvrent. Ce n'est pas un défaut du chargement, c'est la limite de la trame :
une géographie de 2011 ne peut pas restituer un découpage plus fin qu'elle.
`atom_geom.partagee` les marque, `check_geom_overlap(date)` chiffre les
recouvrements en km². À mentionner en légende de toute carte publiée.

C'est précisément ce que le passage à ANR-COMMUNES lèvera, quand l'embargo
tombera : une trame communale historique rendra les fractions représentables.

## Contrôle indépendant

`sources/trfgis/cantons/Shapefiles/CANTONS_1870.zip` et `CANTONS_1940.zip` contiennent
les cantons déjà dissous par Victor Gay. Ces polygones ne passent par aucune
ligne de notre code : les comparer à `snapshot_geom()` teste la chaîne
entière — extraction, attributions, rattrapages de communes disparues,
dissolution — contre une source indépendante.

```bash
cd sql && ./controle_gay.sh          # exige gdal-bin, base déjà chargée
```

Le script dézippe, charge les shapefiles par `ogr2ogr`, construit la table de
correspondance depuis les `MAPPING.tab`, lance `08_controle_gay.sql`, et écrit
deux sorties : `rapport_controle_gay.txt` et `controle_gay.gpkg`.

### Ce qu'on compare, et pourquoi pas les cantons

Les shapefiles de Gay sont découpés en **pseudo-cantons** (`deppct`), pas en
cantons réels (`depct`). Un pseudo-canton regroupe les cantons urbains d'une
même ville : Montluçon-Est (`0320`) et Montluçon-Ouest (`0321`) ne forment
qu'un polygone « Montluçon » (`0380`), parce que la trame communale ne sait
pas couper une commune en deux. Gay bute sur la même limite que nous, au même
endroit — c'est donc au niveau du pseudo-canton, et là seulement, que les deux
côtés sont commensurables.

`COG_CANTONS_YYYY_MAPPING.tab` ne liste **que** ces regroupements (289 lignes
en 1870). Pour tout canton absent du fichier, `deppct = depct` : c'est
l'identité que pose `08_controle_gay.sql`, et `ctrl_corr.origine` trace lequel
des deux cas s'applique à chaque canton.

### Le piège : le repliement vaut pour les deux côtés

Chez Gay, un ensemble urbain n'est pas **un** polygone mais plusieurs. Le
polygone `pct_type = 'Pseudo canton'` ne porte que la commune indivise — la
ville — et les communes entières de chaque canton restent dans des polygones
distincts, portant le code du canton réel. Moulins : `0381` = les 8,5 km² de
la ville, `0323` et `0324` = les communes rurales de Moulins-Est et
Moulins-Ouest. Trois polygones pour deux cantons.

Le premier passage n'avait replié que notre côté et comparait donc deux
cantons entiers à un centre-ville : 239 clés orphelines, 22 689 km² manquants,
et les 25 pires écarts tous chefs-lieux. La correspondance s'applique
maintenant aussi aux polygones de Gay. `ctrl_ecart.n_pseudo` dit si un groupe
a subi ce repliement (`0` = canton rural, comparaison directe) et
`codes_gay` liste les codes d'origine.

Les cantons ruraux, eux, ne sont repliés d'aucun côté. C'est sur eux que le
contrôle est le plus probant, d'où les deux sections restreintes à
`n_pseudo = 0`.

### Lire le rapport

Les sections vont du plus grossier au plus fin, et il faut les lire dans
l'ordre : un écart de clé (section 2) invalide la lecture des sections
suivantes.

| Section | Ce qu'elle teste | Ce qu'un écart signifie |
|---|---|---|
| 1 | chargement des shapefiles | problème d'`ogr2ogr`, pas de données |
| 2 | appariement des `deppct` | nomenclature divergente — à régler avant tout |
| 3 | surface totale France, somme vs union | trame géométrique ; l'écart somme−union chiffre le double comptage des communes partagées |
| 4 | distribution de l'IoU | **le résultat** : conformité des tracés |
| 5-6 | pires écarts, par canton puis par département | où creuser |

L'**IoU** (intersection / union) vaut 1 pour deux tracés identiques. Elle est
préférable à un simple écart de surface : insensible à la taille du canton, et
symétrique — elle ne privilégie aucune des deux sources.

Un IoU imparfait n'est pas nécessairement une erreur. Les trois limites
connues produisent mécaniquement du bruit : les 218 communes revendiquées par
plusieurs cantons, les 1 487 communes disparues rattrapées par successeur INSEE
(Gay a pu trancher autrement), les 6 atomes `hac_partage`. La question utile
n'est pas « l'IoU est-il à 1 ? » mais « les écarts tombent-ils là où on les
attend ? ». D'où le GeoPackage.

### Le GeoPackage

`controle_gay.gpkg` porte trois couches : `ecarts` (la différence symétrique de
chaque pseudo-canton non conforme, attribuée), `nous`, `eux`. À superposer dans
QGIS : si les taches de `ecarts` coïncident avec des communes marquées
`atom_geom.partagee` ou `source <> 'geofla'`, l'explication est celle qu'on
croit. Si elles tombent ailleurs, c'est une piste d'erreur réelle.

### Expliquer les écarts : `09_ecart_detail.sql`

`08` mesure, `09` explique. Il est enchaîné automatiquement par le script et
répond à trois questions, dans l'ordre où elles se posent :

1. **Les contours de département coïncident-ils ?** À ce niveau, toute erreur
   d'attribution entre deux cantons voisins s'annule. Un IoU départemental
   proche de 1 alors que les cantons divergent prouve que le problème est une
   redistribution interne — donc une attribution, pas une trame.
2. **Quel territoire n'est couvert que d'un seul côté, et où ?** `ctrl_dep`
   porte `km2_nous_seul` et `km2_gay_seul`, plus la géométrie de la différence.
3. **Atome par atome, qui range quoi où ?** `ctrl_atome` donne pour chaque
   atome le pseudo-canton de Gay qui le contient, croisé avec
   `atom_geom.source` et `partagee`.

La question 3 est la seule qui décide. Les deux couches étant bâties sur les
mêmes polygones GEOFLA 2011, et celles de Gay étant disjointes (vérifié :
double comptage nul), un point intérieur à l'atome tombe dans un et un seul
pseudo-canton — `ST_PointOnSurface` suffit, sans calcul de recouvrement.

Un atome en désaccord alors qu'il est en `source = 'geofla'` et non partagé est
un atome **sans excuse** : aucune limite connue ne l'explique, c'est une erreur
d'attribution. C'est la ligne à regarder dans la section 4 du rapport.

Réserve : les 333 atomes-fractions partagent le polygone de leur commune et
reçoivent donc tous le même pseudo-canton, ce qui est faux pour tous sauf un.
`partagee` permet de les écarter.

### Couverture de la trame : `10_couverture.sql`

`09` a établi que `km2_nous_seul` vaut 0,0 dans tous les départements : nous ne
revendiquons jamais un territoire que Gay n'a pas, mais il nous en manque
5 926 km² en 1870. Un écart à sens unique n'est pas une erreur d'attribution,
c'est un trou de couverture.

Cause : la correspondance vers GEOFLA est plusieurs-vers-un. Quand une commune
d'époque s'est **scindée** depuis, nous ne gardons qu'un des codes issus de la
scission et le territoire de l'autre n'est réclamé par aucun atome. Gay part de
la trame 2011 et affecte chaque commune actuelle à un canton d'époque : il n'a
pas de trou par construction. `06` traite les fusions ; le symétrique n'existe
pas encore.

`10` nomme les communes non couvertes (`ctrl_non_couvert`, avec géométrie) et
les confronte aux créations INSEE `mod` 20 et 21 postérieures à la date. Le
test qui tranche est en section 1 : la somme des surfaces doit retomber sur le
`km2_gay_seul` de `09`. Rien n'est modifié — aucun atome n'est créé.

### Combler les trous : `11_scission.sql`

Correctif de la limite ci-dessus. **N'est pas lancé par `controle_gay.sh`** —
il modifie les données, il se lance à part et se mesure ensuite :

```bash
psql -d histgis -f sql/11_scission.sql
cd sql && ./controle_gay.sh          # pour noter le résultat
```

L'essentiel des communes non couvertes est né entre 1870 et 1940, donc TRF-GIS
les suit déjà : leur atome existe, son `membership` commence à leur année de
création. Le correctif prolonge ce premier rattachement vers l'arrière. Rien
n'est cherché à l'extérieur.

Cela revient à rattacher un territoire à un canton avant que la commune
existe. C'est cohérent avec le modèle — l'atome est la plus petite unité au
rattachement **stable**, pas une commune — et cela repose sur une hypothèse
énonçable : une commune nouvelle reste dans le canton de sa mère. Vraie presque
toujours. Le contrôle Gay la note.

Quatre garde-fous :

1. Seul le **premier** rattachement est prolongé. Les trous en milieu de
   chronologie restent : les 1 690 atomes absents de 1871 à 1919 sont
   l'Alsace-Moselle, ce trou-là est un fait.
2. Le prolongement suit la **chronologie du canton d'accueil**, pas le
   calendrier. Une commune alsacienne créée sous administration allemande et
   apparue en 1919 ne sera pas prolongée entre 1871 et 1919.
3. Les **recodages** sont écartés : si un autre atome portait le même code
   INSEE juste avant, le territoire était déjà couvert et le prolonger le
   doublerait.
4. Le prolongement **ne franchit pas une interruption** du canton d'accueil.
   TRF-GIS réutilise les codes `depct` de part et d'autre de la rupture de
   1871 : le 5705 de 1870 (Meurthe) et celui de 1921 (Moselle reconstituée)
   sont deux cantons sous une même clé. Seule la plage d'existence continue
   aboutissant à la date d'apparition est retenue. `scission_ilot.retenu`
   trace ce qui a été écarté.

Entièrement réversible — `scission_trace` garde les `membership_id` posés, et
la fin du rapport donne la commande pour les retirer. Le script retire ses
propres lignes avant de recommencer, il est donc rejouable.

### Les désaccords résiduels : `12_conflit_successeur.sql`

Après correctifs, 148 atomes de 1870 restent rangés ailleurs par Gay, dont 138
en `source = 'successeur'`. Ce script teste s'il s'agit d'erreurs d'attribution
ou d'un artefact de la trame, **avant** d'envisager quoi que ce soit.

```bash
psql -d histgis -f sql/12_conflit_successeur.sql     # après controle_gay.sh
```

L'hypothèse : une commune A de 1870 absorbée depuis par B reçoit le polygone de
B, c'est-à-dire A ∪ B. Mais B existe aussi comme atome et reçoit le même
polygone. Deux atomes, un polygone, chacun trop grand de la part de l'autre.
Tant que A et B sont dans le même canton l'union les recolle ; sinon les deux
cantons s'étendent l'un sur l'autre.

La colonne à lire est **`desaccord_hors_conflit`** en section 1 : les atomes en
désaccord dont le polygone n'est partagé avec personne. Ceux-là seuls
accuseraient les attributions. Si le compte est proche de zéro, le membership
est sain et le correctif ne peut venir que d'une trame plus fine — ANR-COMMUNES,
pas GEOFLA.

La section 6 donne le plancher : la surface des polygones éclatés entre cantons
est incompressible sur la trame 2011, quelle que soit la qualité des
attributions.

Rien n'est modifié ; seules les tables `conflit_atome` et `conflit_groupe` sont
créées.

### Tables laissées en base

`ctrl_gay` (polygones empilés), `ctrl_corr` (canton → pseudo-canton),
`ctrl_nous` / `ctrl_eux` (les deux couches dissoutes), `ctrl_ecart` (une ligne
par pseudo-canton, avec IoU), `ctrl_dep` (comparaison départementale, avec la
géométrie de l'écart), `ctrl_atome` (un atome, deux cantons),
`ctrl_non_couvert` et `ctrl_non_couvert_expl`. Toutes recréées à chaque
passage.

Le GeoPackage porte cinq couches : `ecarts`, `ecarts_dep`, `non_couvert`,
`nous`, `eux`. Les avertissements `multi-column primary key` d'`ogr2ogr` sont
sans effet.


## 39_meurthe_1870.sql — la Meurthe reprend son numéro

TRF-GIS range les 29 cantons de l'ancienne Meurthe sous un département « 99 »
qui n'a jamais existé. Ce fichier leur rend le **54**, qu'ils portaient
effectivement avant 1871.

Conséquence à connaître : **le département 54 change de territoire au
1ᵉʳ janvier 1871 sans changer de numéro.** La Meurthe (1870-1871, 29 cantons)
perd sa partie est, annexée, et gagne l'arrondissement de Briey venu de la
Moselle ; elle devient Meurthe-et-Moselle (1871-1941, 32 cantons). Les deux
périodes ne se recouvrent pas, donc aucune ambiguïté à une date donnée — mais
une carte qui empile « le 54 » sur toute la série montre deux emprises.

L'`unit_id` reste en `99xx` : un identifiant est opaque, et `54xx` est déjà
pris par les cantons de Meurthe-et-Moselle.

À rejouer après chaque `rebuild.sh`, comme `38_decret_1982_ain.sql`.
