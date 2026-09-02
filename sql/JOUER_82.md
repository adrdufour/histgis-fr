# Jouer `82_anr_geom.sql` sur la base

Trois commandes, depuis la racine du dépôt. Rien n'écrit dans `membership` ni
dans `atom_geom` : `82` crée ses propres tables et se défait par un `DROP`.

## 1. Charger la couche ANR dans PostGIS — une seule fois

```bash
cd ~/Téléchargements/projet_carte

ogr2ogr -f PostgreSQL PG:"dbname=histgis" \
    ANR_COMMUNES_22042026/COMMUNES_22042026.gpkg geometries_only_processed \
    -nln histgis.anr_commune -nlt MULTIPOLYGON \
    -lco GEOMETRY_NAME=geom -lco FID=gid -a_srs EPSG:2154 -overwrite \
    -lco SPATIAL_INDEX=NONE -lco UNLOGGED=YES \
    --config PG_USE_COPY YES -gt 65536
```

**Ce n'est pas « quelques minutes », et les quatre dernières options sont là pour
ça.** Le volume réel : 47 784 polygones, **550 Mo de géométrie, 34 millions de
sommets**, moyenne 11,3 Ko par commune et jusqu'à 0,4 Mo pour une seule. En
hexadécimal sur le fil, cela fait plus d'un gigaoctet de texte.

| option | ce qu'elle enlève |
|---|---|
| `-lco SPATIAL_INDEX=NONE` | **le gros morceau.** ogr2ogr construit sinon un index GiST sur 47 784 multipolygones énormes — et `82` **ne s'en sert jamais** : il joint sur `id_com` et recopie `geom`, sans un seul prédicat spatial. L'index utile, celui de `atom_geom_anr`, est construit par `82` lui-même. |
| `-lco UNLOGGED=YES` | le WAL. `anr_commune` est une table de transit : elle se recharge en rejouant l'étape 1, elle n'a rien à survivre. |
| `--config PG_USE_COPY YES` | les `INSERT` ligne à ligne, au profit de `COPY`. |
| `-gt 65536` | les validations de transaction tous les 20 000 enregistrements. |

Comptez tout de même **de dix minutes à une demi-heure** selon le disque. La
commande n'affiche rien pendant ce temps : ajoutez `-progress` pour une barre.

**C'est bien `geometries_only_processed`**, pas `with_pseudo_territories` — la
seconde n'apporte que 2 à 4 atomes sur 1870-1940 et en compte 267 de *moins* à
1870.

### Vérifier qu'elle avance, plutôt que d'attendre

Depuis un autre terminal :

```bash
watch -n5 'psql -d histgis -tAc "
  SELECT pg_size_pretty(pg_total_relation_size(''histgis.anr_commune'')),
         count(*) FROM histgis.anr_commune;"'
```

Le compte doit monter par paliers jusqu'à 47 784, pour une table d'environ 700 Mo
à 1 Go. S'il ne bouge plus du tout pendant plusieurs minutes :

```bash
psql -d histgis -c "SELECT pid, state, wait_event_type, wait_event,
                           now() - query_start AS depuis, left(query, 60)
                      FROM pg_stat_activity WHERE datname = 'histgis';"
```

Un `wait_event_type = 'IO'` dit que le disque travaille — c'est lent mais sain.
Un `state = 'idle in transaction'` qui dure, ou un verrou, dit autre chose.

## 2. Le verdict des variantes

`build/anr_variantes.csv` est déjà dans le dépôt. Il n'est à régénérer que si le
jeu ANR change :

```bash
python3 sorties/anr/anr_variantes_verdict.py     # écrit build/anr_variantes.csv
```

## 3. Jouer le fichier, en une transaction

```bash
psql -d histgis -1 -v variantes=build/anr_variantes.csv -f sql/82_anr_geom.sql
```

Le `-1` compte : en cas d'échec, rien n'est écrit. **Le chargement est rapide** —
une minute environ, la couche ANR étant déjà dans PostGIS.

### Ce qui doit sortir

```
variantes lues                    126   55 retenues, 6 en abstention
polygones posés                 45113   38 074 atomes pourvus
atomes doublons tranchés par ANR    6
```

## 4. Les recettes, APRÈS le `COMMIT` et non dedans

```bash
psql -d histgis -c "SELECT * FROM histgis.check_geom_anr('1870-01-01');"
psql -d histgis -c "SELECT * FROM histgis.check_geom_anr('1940-01-01');"
```

```
  atomes pourvus par ANR ................... 37 618   (38 006 à 1940)
  atomes non-fraction sans polygone ANR .... 491      (103 à 1940)
  dont vivants à cette date (trou réel) .... 40       (dont 20 Paris ; 31 à 1940)
  somme des aires, km² projetés ............ 548 496  (étalon GEOFLA : 548 489)
  recouvrement entre polygones, km² ........ 101,0    ← LE CONTRÔLE
  géométries invalides ..................... 0
```

**Les 101,0 km² sont le seul chiffre que le banc n'a pas pu vérifier** : il
demande `ST_Intersection`, donc un vrai PostGIS. Tout le reste y est déjà passé.
S'il sort autre chose, c'est là qu'il faut s'arrêter.

Comptez une à trois minutes pour cette ligne : elle croise 37 618 polygones deux
à deux par l'index spatial. **Elle est hors de la transaction du § 3
délibérément** — un contrôle long n'a rien à faire dans la transaction qu'il
contrôle, sans quoi s'impatienter coûte un `ROLLBACK` de tout le chargement.

## Relire plus tard

```bash
psql -d histgis -c "SELECT * FROM histgis.check_geom_anr('1940-01-01');"
psql -d histgis -c "SELECT unit_id, nom, n_atomes, n_anr, n_repli
                      FROM histgis.snapshot_geom_anr('1885-06-01')
                     WHERE n_repli > 0 ORDER BY n_repli DESC LIMIT 20;"
```

## Défaire

```bash
psql -d histgis -c "DROP TABLE IF EXISTS histgis.atom_geom_anr, histgis.anr_variante,
                                         histgis.a82_trace, histgis.a82_doublon;
                    DROP FUNCTION IF EXISTS histgis.snapshot_geom_anr(date, text);
                    DROP FUNCTION IF EXISTS histgis.check_geom_anr(date);"
```

`atom_geom`, `membership` et `unit` n'ont pas été touchés : il n'y a rien
d'autre à remettre en place. La ligne `'anr'` reste dans `atom_geom_source`,
sans conséquence.

## Prérequis, que `82` vérifie lui-même et refuse sans

| prérequis | pourquoi |
|---|---|
| `histgis.anr_commune` | l'étape 1 |
| extension `btree_gist` | la contrainte `EXCLUDE` du § 4 |
| `sql/07_reliquat.sql` joué | `atom_geom_source`, où le § 5 déclare sa source |
| table `atom` chargée | le pont `atom.cassini = anr.id_com` |

## Le banc, si vous préférez voir avant

```bash
bash sql/banc_82.sh
```

PostgreSQL jetable, sans postgis, où la géométrie devient l'empreinte MD5 du WKB
réel. Ne demande rien d'installé sinon `pip install pgserver`.
