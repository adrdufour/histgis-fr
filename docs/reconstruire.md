# Reconstruire la base chez soi

Le dépôt ne contient ni les données sources ni la base. Ce document décrit
comment les réunir et rejouer la chaîne. Il résume `METHODE.md` § 4,
`sql/README.md` et `sql/CHAINE.md`, qui restent les références.

> **Avertissement.** La chaîne a été conçue et jouée sur une seule machine,
> celle de l'auteur. Elle n'a jamais été rejouée depuis un clone vierge, et
> quelques pièces manquent au dépôt (voir [ci-dessous](#ce-qui-manque-au-dépôt)).
> Prévoyez du temps, de la place disque (plus de 10 Go avec les sources) et de
> la patience.

---

## 1. Prérequis

**Serveur** : PostgreSQL ≥ 13 avec PostGIS ≥ 3.0 et `btree_gist`, installés par
le système, et non par conda :

```bash
sudo apt install postgresql postgresql-<version>-postgis-3
createdb histgis
psql -d histgis -c 'CREATE EXTENSION postgis; CREATE EXTENSION btree_gist;'
```

**Outils** : l'environnement conda fourni installe Python ≥ 3.11 et ses
bibliothèques (`psycopg2`, `shapely` 2, `pyshp`, `pandas`, `matplotlib`…),
ainsi que GDAL (`ogr2ogr`), poppler, tesseract (avec le français) et ImageMagick.

```bash
conda env create -f environment.yml     # ou mamba
conda activate histgis
```

**Piège de connexion** : la libpq de conda cherche la socket PostgreSQL dans
`/tmp`, alors que Debian et Ubuntu la placent dans `/var/run/postgresql`. Si
`psql` fonctionne mais que les scripts Python répondent « No such file or
directory », définissez la connexion explicitement :

```bash
export HISTGIS_DSN="dbname=histgis host=/var/run/postgresql"
export PGDATABASE=histgis        # lu par les scripts shell de sql/
```

---

## 2. Les sources à réunir

Toutes se rangent sous la racine du dépôt, dans des dossiers ignorés par git.
Les chemins ci-dessous sont ceux qu'attendent les scripts.

| emplacement | contenu | où le trouver |
|---|---|---|
| `sources/trfgis/` | TRF-GIS : nomenclatures communes (`doi:10.7910/DVN/LZTZWE`), cantons (`doi:10.7910/DVN/U85RSZ`), circonscriptions (`doi:10.7910/DVN/L2LGDW`), dépôt de reproduction (`doi:10.7910/DVN/6FCK3W`) | Harvard Dataverse, via `trfgis_fetch_inspect.py` |
| `sources/geofla/` | GEOFLA 2011 (`COMMUNE.SHP`) et GEOFLA 2014 (`CANTON.SHP`) | IGN, `data.geopf.fr/telechargement/resource/GEOFLA` ; `COMMUNE.SHP` figure aussi dans le dépôt de reproduction TRF-GIS |
| racine du dépôt | `v_mvt_commune_2025.csv`, mouvements de communes | `https://www.insee.fr/fr/statistiques/fichier/8377162/v_mvt_commune_2025.csv` |
| `sources/cog/` | COG 1999 à 2012, communes et cantons | INSEE (Code officiel géographique, millésimes antérieurs) |
| `ANR_COMMUNES_22042026/` | `COMMUNES_22042026.gpkg`, trame communale datée | Zenodo, `10.5281/zenodo.3727274` |
| `sources/outremer/` | trames et circonscriptions d'outre-mer | IGN (GEOFLA DOM) ; `polynesie/` et `nouvelle_caledonie/` pour les BD ADMIN locales |
| `sources/rp1954/`, `sources/rp1968/` | volumes des recensements de 1954 et 1968 (PDF) | BnSP (`bnsp.insee.fr`) : nécessaires seulement pour refaire l'OCR, dont le résultat est déjà versionné |
| `JORF/` | PDF des Journaux officiels | Gallica, Légifrance : liste dans `cantons/pdf_a_telecharger.md`. Seulement pour refaire l'OCR, dont le texte est déjà dans `jorf_txt/` |

Exemple pour TRF-GIS et la trame communale :

```bash
python3 trfgis_fetch_inspect.py fetch repro \
    --match '^COMMUNE\.(SHP|SHX|DBF|PRJ)$' --dest ./sources/geofla
curl -O https://www.insee.fr/fr/statistiques/fichier/8377162/v_mvt_commune_2025.csv
```

`python3 trfgis_fetch_inspect.py --help` liste les autres commandes et jeux
disponibles.

Ce qui est **déjà dans le dépôt** et n'a pas besoin d'être refait : les
dépouillements des recensements (`cog1954/`, `cog1968/`), le registre des
décrets (`cantons/`), les circonscriptions saisies (`circo/*.csv`), la
filiation HAC (`hac/hac_filiation.csv`), les coupes de villes
(`cartes/coupes_ville.csv`) et le texte OCR des Journaux officiels
(`jorf_txt/`).

---

## 3. Rejouer la chaîne

```bash
# 1. Extraire les nomenclatures TRF-GIS vers build/
python3 trfgis_extract.py build sources/trfgis/communes/Nomenclatures \
    --out build --mapping sources/trfgis/cantons/Nomenclatures --geom-col insee

# 2. Charger : attributions 1870-1940, trame GEOFLA, communes disparues
cd sql
./rebuild.sh                  # DESTRUCTIF : DROP SCHEMA histgis CASCADE

# 3. Tout le reste, dans l'ordre : période moderne, circonscriptions, Paris,
#    jalons 1954/1968, décrets, reports, trame ANR, partition…
./rejouer_apres_rebuild.sh

# 4. Facultatif : contrôle indépendant contre les cantons de Gay
./controle_gay.sh
```

Avant de commencer sur une base qui contient déjà du travail, faites une
sauvegarde (`pg_dump -Fc histgis > histgis.dump`).

`rejouer_apres_rebuild.sh` **saute avec un message**, au lieu d'échouer, les
étapes dont la donnée manque : Marseille, outre-mer, Paris 1815, ANR, etc. Lisez sa
sortie : une étape sautée ne signale aucune erreur, mais la base qui en résulte
est incomplète.

### Vérifier ce qui est réellement passé

```bash
psql -d histgis -f sql/diag_passages.sql     # lecture seule
```

Cette requête compare les tables de trace attendues à celles que la base
contient. C'est la seule façon de savoir si chaque fichier a bien été joué.
Comme le répètent les notes : *un résultat obtenu sur une base à demi
reconstruite est indiscernable d'un résultat juste.*

### Rejouer un seul fichier

À éviter si possible. Si c'est nécessaire, lisez d'abord la section « Qui
dépend de qui » de `sql/README.md`. Deux mécanismes cassent la chaîne sans
bruit :

1. un fichier qui crée des unités ne peut pas être rejoué tant qu'un autre les
   référence (clé étrangère) ;
2. supprimer les atomes d'un fichier emporte, par cascade, ce que d'autres
   fichiers avaient posé dessus.

---

## 4. Produire les cartes

```bash
# Carte web interactive (plusieurs heures pour la France entière)
python3 cartes/export_web.py --jobs 4
python3 cartes/web/servir.py                # http://127.0.0.1:8765/index.html

# Planches PDF par département
python3 cartes/cartes_cantons.py

# Paris
python3 circo/cartes_paris.py
```

Pour une carte ponctuelle, le plus simple est d'ouvrir la base dans QGIS et
d'ajouter une requête comme couche
(voir [`modele_de_donnees.md`](modele_de_donnees.md#exemples)).

---

## Ce qui manque au dépôt

Relevé en lisant les scripts. Ces pièces vivent sur la machine d'origine, hors
du suivi git :

| pièce | utilisée par | conséquence |
|---|---|---|
| `sorties/anr/anr_variantes_verdict.py` et sa sortie `build/anr_variantes.csv` | étape `82` (trame ANR) | sans elles, `82` et ce qui en dépend (`84`, `89`-`91`, la carte partitionnée) sont sautés |
| `sources/outremer/telecharger_outremer.sh` | `charger_outremer.sh`, étape `40_outremer` | l'outre-mer doit être téléchargé à la main |
| `cog/fetch_cog.sh` | `load_cog.sh` | les 14 millésimes du COG doivent être téléchargés à la main dans `sources/cog/` |
| `42-Vasserot_quartiers_v1L93/` (ALPAGE-Vasserot) | `circo/paris_quartiers_1815.py`, `paris_circo_1815.py` | donnée reçue mais sous licence ODbL, donc non diffusée : les étapes « Paris 1815 » sont sautées |

Les trois premières lignes sont des oublis à corriger : il faudrait versionner
ces scripts ou en documenter le remplacement. La dernière découle d'un choix de
licence.

Une autre étape est sautée pour une raison différente : `32` (cantons internes
de Marseille) attend `gaudillere/marseille_cantons.gpkg`, une digitalisation
**qui n'a pas encore été faite**. Le protocole est dans
`gaudillere/protocole_georeferencement.md`.
