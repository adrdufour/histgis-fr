# HistGIS — carte du dossier

Base PostGIS des divisions administratives et électorales françaises,
interrogeable à n'importe quelle date : **quelle était la carte des cantons et
des circonscriptions législatives le 1ᵉʳ juin 1885 ?** Cible 1870-2012,
extension prévue vers 1815.

Schéma `histgis`, EPSG:2154 partout, sans exception.

---

## Par où commencer

Quatre documents font foi. Dans cet ordre :

| | |
|---|---|
| **`METHODE.md`** | ce que contient la base, l'architecture, les sources, les règles. À lire en premier. |
| **`ETAT.md`** | où en est chaque couche, ce qui est validé, ce qui ne l'est pas. Tenu par ajouts datés. |
| **`RESTE_A_FAIRE.md`** | les tâches, par valeur et non par facilité, avec le blocage quand il y en a un. |
| **`JOURNAL.md`** | les leçons transposables — ce que chaque erreur a appris. |

`BASE_POUR_QGIS.md` est une note de passation pour un agent qui aurait QGIS et
devrait cartographier les villes multicantonales.

---

## L'organisation, en une phrase

**On ne modifie jamais `sources/`, on ne sauvegarde jamais `sorties/` ni
`build/`, et tout le reste est du travail à conserver.**

```
projet_carte/
│
├─ METHODE.md  ETAT.md  RESTE_A_FAIRE.md  JOURNAL.md   les documents qui font foi
├─ BASE_POUR_QGIS.md                                    note de passation
├─ trfgis_extract.py                                    tête de chaîne : TRF-GIS → build/
├─ trfgis_fetch_inspect.py                              récupération du dépôt de reproduction
├─ geom_correspondance.csv                              lu par sql/02_load.sql, doit rester ici
│
├─ sources/     1,5 Go   DONNÉES REÇUES — jamais modifiées, hors dépôt git
├─ build/        21 Mo   sortie de trfgis_extract.py, entrée de sql/ — reconstruit, hors git
├─ sorties/      15 Mo   rapports de recette et GPKG de contrôle — régénérables
│
├─ sql/                  la chaîne de chargement, numérotée dans l'ordre
├─ cantons/              registre des mouvements cantonaux, annexe VII
├─ circo/                circonscriptions législatives, et tout Paris
├─ cog1954/              le recensement de 1954, extraction et contrôle
├─ cartes/               production de planches, couverture des découpages modernes
├─ gaudillere/           Marseille : protocole de géoréférencement
├─ jorf_txt/             OCR des JO de sources/modif_canton/
├─ docs/                 notes thématiques
└─ archives/             exploration ancienne, gardée pour mémoire, plus utilisée
```

---

## `sources/` — ce qu'on a reçu

**Rien ici ne se modifie.** Si un fichier de `sources/` doit être corrigé, la
correction se fait dans un script, pas dans la donnée : c'est ce qui permet de
retélécharger et de recommencer.

| | poids | quoi | licence |
|---|---|---|---|
| `trfgis/` | 905 Mo | TRF-GIS de Victor Gay — communes et cantons 1870-1940, avec son dépôt de reproduction | CC BY 4.0 |
| `modif_canton/` | 392 Mo | JO numérisés et clichés de l'annexe VII de Gaudillère | domaine public / Etalab |
| `geofla/` | 71 Mo | GEOFLA (trame communale 2011, cantons 2014), HAC, cantons 2025 | Licence Ouverte |
| `rp1954/` | 59 Mo | le volume du recensement de 1954 | domaine public |
| `cog/` | 55 Mo | Codes officiels géographiques 1999-2012 | Licence Ouverte |
| `arrondissement/` | 13 Mo | GEOFLA arrondissements, dont l'outre-mer | Licence Ouverte |

**`sources/` n'est pas dans git** — 1,5 Go sans historique à raconter. Un clone
du dépôt ne suffit donc pas à rejouer la chaîne : il faut retélécharger. Les
DOI sont dans `METHODE.md` § 3.

**Contrainte de licence, qui commande tout le reste** : le projet alimente
Wikipédia et Wikidata. Toute source doit être **CC BY-SA ou Licence Ouverte /
Etalab, et vérifiable par une URL publique**. Cela exclut l'ODbL (quartiers de
la Ville de Paris, ALPAGE-Vasserot) et le CC BY-NC-SA (Cassini-Geopeuple),
même quand la donnée serait parfaite.

---

## Ce qui se régénère, et par quelle commande

Si un de ces fichiers manque ou paraît douteux, il se refait. Rien n'y est
saisi à la main.

| fichier | commande |
|---|---|
| `build/*.csv` | `python3 trfgis_extract.py build sources/trfgis/communes/Nomenclatures --out build --mapping sources/trfgis/cantons/Nomenclatures --geom-col insee` |
| toute la base | `sql/rebuild.sh` — **destructif**, il repart de zéro |
| `sorties/rapport_chargement.txt` | `sql/load.sh` |
| `sorties/rapport_controle_gay.txt`, `controle_gay.gpkg` | `sql/controle_gay.sh` |
| `cartes/sorties/dep_NN.pdf` | `python3 cartes/cartes_cantons.py` (`--un-seul`, `--2025`) |
| `cartes/sorties/villes_multicantonales.*` | `python3 cartes/carte_villes_multicantonales.py` |
| `cartes/sorties/iris_villes.geojson` | `python3 cartes/recupere_iris.py --charger` |
| `circo/sorties/paris_circo.pdf` | `python3 circo/cartes_paris.py` |
| `cog1954/ocr_brut/` | `python3 cog1954/extrait_1954.py --pdf sources/rp1954/…` — **des heures**, conservé exprès |

Les **CSV de travail restent auprès de leur script**, pas dans `sorties/` : ils
se lisent, se comparent d'une version à l'autre, et sont versionnés. Seuls les
binaires et les gros fichiers sont isolés.

---

## Les chantiers

| dossier | ce qu'on y trouve | état |
|---|---|---|
| `sql/` | 33 étapes numérotées de 01 à 37, plus `rebuild.sh`, `load.sh`, `load_cog.sh`, `controle_gay.sh`. Lire `sql/README.md`. | chaîne complète 1870-2012 |
| `cantons/` | registre consolidé des mouvements cantonaux : 723 démembrements, 559 datés (77 %) | actif |
| `circo/` | circonscriptions 1958/1986/2009, et Paris : 80 quartiers reconstruits par union d'IRIS, 386 circos sur 15 divisions | actif |
| `cog1954/` | extraction du recensement de 1954 : 3 créations cantonales établies par trois voies indépendantes, 98 % de stabilité 1940-1954 | acquis, perfectible |
| `cartes/` | planches départementales, couverture des découpages modernes, trame IRIS des 119 villes à découper | actif |
| `gaudillere/` | protocole de géoréférencement de Marseille — le cas d'école des onze coupes internes | à exécuter |
| `jorf_txt/` | texte OCR des JO. Les `*_raw.txt` sont l'OCR brut, hors dépôt. | dépouillé |

---

## Trois pièges qui ont coûté cher, et qui reviendront

**Le référentiel bouge et se déguise en événement.** La Corse recodée 20 →
2A/2B en 1976, la Seine et la Seine-et-Oise démembrées en 1964, un canton
transféré d'un département à l'autre : rien de tout cela n'est un mouvement
cantonal, et rien de tout cela n'échoue à un contrôle de cohérence.
**Avant de déclarer un événement, vérifier que le référentiel n'a pas bougé.**

**Marseille, Lyon et Paris sont codées par arrondissement municipal**, pas par
leur code de commune — dans GEOFLA comme dans CONTOURS-IRIS. Interroger
« 13055 » rend **zéro**, et un zéro n'a pas l'air d'une erreur : pour une
petite commune ce serait la bonne réponse. **Un résultat nul se confronte à
l'ordre de grandeur attendu, pas à sa plausibilité.**

**Grouper par la géométrie, jamais par un code.** Plusieurs communes de 1870
fondues depuis en une seule partagent un unique polygone de 2011. Dessinées
séparément, elles s'empilent sans que rien ne le signale. Regrouper sur
`md5(ST_AsEWKB(geom))`.

La liste complète est dans `METHODE.md` § 6 et dans `JOURNAL.md`.

---

## Git

Le dépôt versionne le code, le SQL, les documents et les CSV de travail —
quelques mégaoctets. Il exclut `sources/`, `build/`, `sorties/` et les binaires
régénérables : voir `.gitignore`, qui dit pourquoi ligne par ligne.

Le premier commit fige l'état du 14 août 2026, **avant** la réorganisation du
dossier. C'est lui qui rend tout déplacement annulable.

---

## Environnement

Aucun fichier d'environnement n'existe encore — c'est une dette connue,
inscrite dans `RESTE_A_FAIRE.md` § 8. Sont utilisés sans être déclarés :
`psycopg2`, `matplotlib`, `shapely`, `openpyxl`, `xlrd`. Côté système :
PostgreSQL avec PostGIS, GDAL (`ogr2ogr`), `poppler-utils` (`pdftoppm`,
`pdfinfo`), `tesseract-ocr` avec le paquet français.

Piège de connexion : la libpq de conda cherche la socket dans `/tmp` alors que
Debian et Ubuntu la posent dans `/var/run/postgresql`. D'où des « No such file
or directory » alors que `psql` fonctionne dans le même terminal. Les scripts
essaient les trois emplacements ; `HISTGIS_DSN` force le choix.
