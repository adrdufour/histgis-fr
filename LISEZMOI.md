# HistGIS — carte du dossier

Base PostGIS des divisions administratives et électorales françaises,
interrogeable à n'importe quelle date : **quelle était la carte des cantons et
des circonscriptions législatives le 1ᵉʳ juin 1885 ?** Cible **1870-2012**,
Paris remontant à **1815**, extension métropolitaine avant 1870 en projet.

Schéma `histgis`, EPSG:2154 partout, sans exception.

---

## Par où commencer

Quatre documents font foi. Dans cet ordre :

| | |
|---|---|
| **`METHODE.md`** | la référence stable. Partie I : architecture, sources, chaîne, limites, contrôles. Partie II : les règles de travail, indexées au § 10. **À lire en premier.** |
| **`ETAT.md`** | où en est chaque couche *aujourd'hui*. Un état, pas un récit : ce qui est faux y est corrigé sur place. |
| **`RESTE_A_FAIRE.md`** | la file d'attente, par valeur et non par facilité, avec le blocage quand il y en a un. |
| **`JOURNAL.md`** | le récit chronologique, seul document tenu **par ajouts**. C'est lui qui porte l'historique : rien n'a besoin d'être répété ailleurs pour être conservé. |

`BASE_POUR_QGIS.md` est une note de passation pour un agent qui aurait QGIS et
devrait cartographier les villes multicantonales.

Les notes de chantier vivent auprès de leur dossier : `sql/CHAINE.md`
(inventaire des 130 fichiers), `sql/README.md` (dépendances et ordre de rejeu),
`cog1954/note_1954.md`, `cog1968/note_1968.md`, `docs/note_1943_2012.md`,
`docs/note_circonscriptions.md`, `docs/note_outre_mer.md`, `circo/note_paris.md`.

Depuis octobre 2026 s'y ajoutent : `cartes/web/LISEZMOI.md` (la carte
interactive, l'export, le dépôt sur Wikimedia Commons),
`cartes/a_inscrire_en_base.md` (ce que la découpe des villes a montré de faux
dans la base, entrée par entrée), `.claude/skills/decoupe-ville/SKILL.md` (le
déroulé d'une découpe), `circo/verif_1815_21_63.md` et
`circo/verif_1815_restants.md` (lecture des photos de l'atlas, 1815-1870),
`cantons/wikipedia/note_wikipedia.md`, `cantons/wikipedia/lecture_jo.md` et
`cantons/tables_jo.md` (le trou 1941-1998 par le Journal officiel).

---

## L'organisation, en une phrase

**On ne modifie jamais `sources/`, on ne sauvegarde jamais `sorties/` ni
`build/`, et tout le reste est du travail à conserver.**

```
projet_carte/                              55 Go au total, relevé le 11 octobre 2026
│
├─ METHODE.md  ETAT.md  RESTE_A_FAIRE.md  JOURNAL.md   les documents qui font foi
├─ BASE_POUR_QGIS.md                                    note de passation
├─ trfgis_extract.py                                    tête de chaîne : TRF-GIS → build/
├─ trfgis_fetch_inspect.py                              récupération du dépôt de reproduction
├─ geom_correspondance.csv                              lu par sql/02_load.sql, doit rester ici
│
├─ sorties/                   33 Go   exports de la carte, rapports — RÉGÉNÉRABLES, hors git
├─ JORF/                     7,6 Go   PDF des Journaux officiels, dont tables/ (4,4 Go) — reçus
├─ cartes/web/donnees/       7,1 Go   la carte servie — RÉGÉNÉRABLE, hors git
├─ cartes/sorties/           3,3 Go   voirie BD TOPO par ville (3,2 Go), tableau des villes — hors git
├─ sources/                  1,8 Go   DONNÉES REÇUES — jamais modifiées, hors git
├─ ANR_COMMUNES_22042026/    1,2 Go   trame communale historique 1790-2020 — reçue
├─ build/                    614 Mo   sortie de trfgis_extract.py, journaux, un pg_dump (591 Mo)
├─ photo_1815_1870/          348 Mo   120 photos de l'atlas — NI REÇUES NI RÉGÉNÉRABLES, hors git
├─ Photos-1-001/             393 Mo   139 photos de l'atlas, 1940-1995 — NI REÇUES NI RÉGÉNÉRABLES, hors git
├─ jorf_txt/                 301 Mo   texte des JO ; *_raw, *_col et tables annuelles hors git
├─ polynesie/                 93 Mo   BD ADMIN Polynésie française — reçue
├─ nouvelle_caledonie/        36 Mo   BD ADMIN Nouvelle-Calédonie (DITTT) — reçue
│
├─ sql/                  la chaîne de chargement : 130 fichiers numérotés 01 à 111
├─ cantons/              registre des mouvements cantonaux, décrets, annexe VII,
│  └─ wikipedia/         récolte Wikipédia, lecture des JO, complément au registre
├─ circo/                circonscriptions législatives, tout Paris, 1815-1870
├─ cog1954/  cog1968/    les recensements, extraction et contrôle
├─ cartes/               découpe des villes, export et page web
├─ gaudillere/           Marseille : protocole de géoréférencement
├─ hac/                  filiation communale extraite de HAC
├─ docs/                 notes thématiques
├─ .claude/skills/       decoupe-ville : le déroulé d'une découpe de ville
├─ archives/             ce qui ne sert ni la base ni la carte web : voir archives/LISEZMOI.md
└─ _to_delete/           antichambre de la corbeille — hors git, se vide à la main
```

---

## `sources/` — ce qu'on a reçu

**Rien ici ne se modifie.** Si un fichier de `sources/` doit être corrigé, la
correction se fait dans un script, pas dans la donnée : c'est ce qui permet de
retélécharger et de recommencer.

| | poids | quoi | licence |
|---|---|---|---|
| `trfgis/` | 905 Mo | TRF-GIS de Victor Gay — communes et cantons 1870-1940, avec son dépôt de reproduction | CC BY 4.0 |
| `rp1968/` | 680 Mo | fascicules départementaux du recensement de 1968 | domaine public |
| `geofla/` | 71 Mo | GEOFLA (trame communale 2011, cantons 2014), HAC, cantons 2025 | Licence Ouverte |
| `rp1954/` | 59 Mo | le volume du recensement de 1954 | domaine public |
| `cog/` | 55 Mo | Codes officiels géographiques 1999-2012 | Licence Ouverte |
| `outremer/` | 37 Mo | circonscriptions et trames d'outre-mer | Licence Ouverte |
| `modif_canton/` | 18 Mo | clichés de l'annexe VII de Gaudillère | — |
| `arrondissement/` | 13 Mo | GEOFLA arrondissements, dont l'outre-mer | Licence Ouverte |
| `Tableau_de_correspondance_communes_cantons_circonscriptions_2012.xls` | 7,7 Mo | correspondance commune → canton → circonscription en 2012 | Licence Ouverte |

Le tableau de 2012 traînait à la racine jusqu'au 2 septembre 2026 ; aucun
script ne le lit par son chemin.

Reçus mais hors de `sources/`, pour des raisons historiques : `JORF/` (PDF des
Journaux officiels), `ANR_COMMUNES_22042026/` (Zenodo
`10.5281/zenodo.3727274`), `42-Vasserot_quartiers_v1L93/` (ODbL, inutilisable —
gardé pour référence), `polynesie/`, `nouvelle_caledonie/` (BD ADMIN du DITTT,
avec ses CGU et son lisez-moi).

> **La règle qui les visait leur échappait.** `.gitignore` ne connaissait que
> `sources/` : ces quatre dossiers, 4 Go, n'étaient ni suivis ni ignorés, donc
> à un `git add -A` d'entrer dans le dépôt. Chacun a désormais sa ligne.
> **Corollaire : une donnée reçue qui n'arrive pas dans `sources/` doit être
> ignorée nommément, le jour même.**

**`sources/` n'est pas dans git** — sans historique à raconter. Un clone du dépôt
ne suffit donc pas à rejouer la chaîne : il faut retélécharger. Les DOI sont dans
`METHODE.md` § 3.

**Contrainte de licence, qui commande tout le reste** : le projet alimente
Wikipédia et Wikidata. Toute source doit être **CC BY-SA ou Licence Ouverte /
Etalab, et vérifiable par une URL publique**. Cela exclut l'ODbL (quartiers de la
Ville de Paris, ALPAGE-Vasserot) et le CC BY-NC-SA (Cassini-Geopeuple), même
quand la donnée serait parfaite.

---

## Ce qu'on peut archiver pour gagner de la place

Relevé du 11 octobre 2026 : 55 Go, dont **la moitié en exports périmés**.
« Archiver » veut dire ici déplacer sur un autre disque, ou compresser ; rien
de ce tableau n'est lu par la chaîne.

| | poids | ce que c'est | risque à l'ôter |
|---|---|---|---|
| `sorties/part_2026-10-06_1815/` | 7,1 Go | export du 6 octobre, remplacé | nul — refait par `export_web.py` |
| `sorties/web_2026-10-10/` | 5,2 Go | copie de la carte servie, mise de côté (elle garde `index.avant_outremer.json`) | nul |
| `sorties/part_2026-10-04_1815/` | 5,0 Go | export du 4 octobre ; a servi le 6 à recopier l'outre-mer | nul |
| `sorties/part_2026-09-24_propre/` | 4,6 Go | export du 24 septembre | nul |
| `sorties/donnees_avant_84/` | 3,3 Go | la carte d'avant `84`, mise de côté le 2 septembre | nul pour la chaîne ; c'est le seul témoin de la carte d'avant la partition |
| `JORF/tables/` | 4,4 Go | les 50 tables annuelles du JO en PDF | faible — Légifrance les redonne ; les garder tant que la mise en colonnes de 1941-1957 est à refaire |
| `cartes/sorties/voirie/` | 3,2 Go | voirie BD TOPO, 4 GeoJSON par ville | faible — `cartes/recupere_voirie.py` la retélécharge ; ôter d'abord les villes écrites |
| `ANR_COMMUNES_22042026/` | 1,2 Go | trame ANR, déjà en base par `82` | faible — Zenodo `10.5281/zenodo.3727274` ; **exigée par un rebuild** |
| `sources/trfgis/`, `sources/rp1968/` | 905 + 680 Mo | reçus, dépouillés | faible — DOI dans `METHODE.md` § 3 ; `trfgis` exigé par un rebuild |
| `build/histgis_avant_chaine_2026-09-22.dump` | 591 Mo | sauvegarde d'avant la reconstruction par la chaîne | à remplacer par un `pg_dump -Fc` du jour avant de l'ôter |

Les cinq premières lignes font **25 Go** et ne demandent aucune précaution.
`sorties/part_2026-10-11/` (7,1 Go) est le dernier export et
`cartes/web/donnees/` (7,1 Go) la carte servie : ils diffèrent, **on garde les
deux** tant que l'un n'a pas été promu à la place de l'autre.

**Ce qu'il ne faut pas ôter sans copie ailleurs : `photo_1815_1870/`.** Ces 120
photos de l'atlas sont la source de `circo/regles_1815_*.py` ; elles ne sont ni
téléchargeables ni régénérables, et git les ignore (`*.jpg`). C'est le seul
dossier du projet dont la perte serait définitive.

Hors du dossier : le schéma `public` de la base porte 317 tables de travail des
découpes de villes (285 Mo, `nice_*`, `nimes_*`, `istres_*`…).

---

## Ce qui se régénère, et par quelle commande

Si un de ces fichiers manque ou paraît douteux, il se refait. Rien n'y est saisi
à la main.

| fichier | commande |
|---|---|
| `build/*.csv` | `python3 trfgis_extract.py build sources/trfgis/communes/Nomenclatures --out build --mapping sources/trfgis/cantons/Nomenclatures --geom-col insee` |
| toute la base | `sql/rebuild.sh` puis `sql/rejouer_apres_rebuild.sh` — **destructif**, il repart de zéro |
| `sorties/rapport_chargement.txt` | `sql/load.sh` |
| `sorties/rapport_controle_gay.txt`, `controle_gay.gpkg` | `sql/controle_gay.sh` |
| `cartes/web/donnees/` | `python3 cartes/export_web.py --jobs N` |
| `archives/planches/sorties/dep_NN.pdf` | `python3 archives/planches/cartes_cantons.py` (`--un-seul`, `--2025`) |
| `archives/planches/sorties/villes_multicantonales.*` | `python3 archives/planches/carte_villes_multicantonales.py` |
| `cartes/sorties/iris_villes.geojson` | `python3 cartes/recupere_iris.py --charger` |
| `archives/planches/sorties/paris_circo.pdf` | `python3 archives/planches/cartes_paris.py` |
| `cog1954/ocr_brut/`, `cog1968/ocr_brut/` | `python3 cog1954/extrait_1954.py --pdf …` — **des heures**, conservé exprès |

Les **CSV de travail restent auprès de leur script**, pas dans `sorties/` : ils se
lisent, se comparent d'une version à l'autre, et sont versionnés. Seuls les
binaires et les gros fichiers sont isolés.

---

## Les chantiers

| dossier | ce qu'on y trouve | état |
|---|---|---|
| `sql/` | 130 fichiers numérotés 01 à 111, plus `rebuild.sh`, `rejouer_apres_rebuild.sh`, `load_cog.sh`, `controle_gay.sh` et trois bancs d'essai. **Lire `sql/CHAINE.md` puis `sql/README.md`.** | chaîne complète 1815-2012 |
| `cantons/` | registre consolidé des mouvements cantonaux — 723 démembrements dont 559 datés au décret (77 %) — et 343 actes moissonnés, 1 212 cantons dépouillés des JO | actif |
| `circo/` | circonscriptions 1958/1986/2009, et tout Paris : 80 quartiers reconstruits par union d'IRIS, 386 circos sur 15 divisions de 1863 à 1986 | actif |
| `cog1954/`, `cog1968/` | extraction des deux recensements. 1954 : 3 créations cantonales établies par trois voies indépendantes. 1968 : 86 fascicules, rappel 91,4 % | acquis, perfectible |
| `cartes/` | couverture des découpages modernes, trame IRIS des 119 villes à découper, et **l'export de la carte web** | actif |
| `hac/` | filiation communale extraite de HAC — le troisième contrôle indépendant | acquis |
| `gaudillere/` | protocole de géoréférencement de Marseille — le cas d'école des onze coupes internes | à exécuter |
| `jorf_txt/` | texte OCR des JO. Les `*_raw.txt` sont l'OCR brut, hors dépôt | dépouillé |
| `archives/` | exploration ancienne, planches imprimables, filets de sécurité — voir `archives/LISEZMOI.md` | inactif |

---

## Trois pièges qui ont coûté cher, et qui reviendront

**Le référentiel bouge et se déguise en événement.** La Corse recodée 20 →
2A/2B en 1976, la Seine et la Seine-et-Oise démembrées en 1964, un canton
transféré d'un département à l'autre : rien de tout cela n'est un mouvement
cantonal, et rien de tout cela n'échoue à un contrôle de cohérence. **Avant de
déclarer un événement, vérifier que le référentiel n'a pas bougé.**

**Marseille, Lyon et Paris sont codées par arrondissement municipal**, pas par
leur code de commune — dans GEOFLA comme dans CONTOURS-IRIS. Interroger « 13055 »
rend **zéro**, et un zéro n'a pas l'air d'une erreur : pour une petite commune ce
serait la bonne réponse. **Un résultat nul se confronte à l'ordre de grandeur
attendu, pas à sa plausibilité.**

**Grouper par la géométrie, jamais par un code.** Plusieurs communes de 1870
fondues depuis en une seule partagent un unique polygone de 2011. Dessinées
séparément, elles s'empilent sans que rien ne le signale. Regrouper sur
`md5(ST_AsEWKB(geom))`.

La liste complète est dans `METHODE.md`, partie II, indexée au § 10.

---

## Git

Le dépôt versionne le code, le SQL, les documents et les CSV de travail. Il
exclut `sources/`, `build/`, `sorties/` et les binaires régénérables : voir
`.gitignore`, qui dit pourquoi ligne par ligne.

Le premier commit fige l'état du 14 août 2026, **avant** la réorganisation du
dossier. C'est lui qui rend tout déplacement annulable.

**Les deux dettes de dépôt sont soldées le 2 septembre 2026** (elles étaient
inscrites ici et au § 0 de `RESTE_A_FAIRE.md`) :

1. **`cartes/web/donnees/` était suivi** — 1 546 fichiers, 3,3 Go, un export
   que `export_web.py` refait en entier. À lui seul il produisait **96 % du
   bruit de `git status`** : 1 251 suppressions et 2 606 ajouts en attente au
   moindre export. Détaché de l'index par `git rm -r --cached`, gardé sur le
   disque. `index.html`, `servir.py` et `cartes/web/LISEZMOI.md` restent
   suivis : c'est du code écrit à la main.
2. **Les 4 Go de reçus sont ignorés nommément**, et les treize jours de
   travail sont versionnés — neuf commits, un par chantier.

Le dépôt passe de **1 744 fichiers / 932 Mo** à **384 / 91 Mo**, et
`git status` de 4 499 lignes à zéro. Les 91 Mo restent loin des *« quelques
Mo »* que ce fichier vise, pour une seule raison : `jorf_txt/` en pèse 52,
soit 57 % à lui seul. Dette ouverte, pas encore tranchée.

Sont sortis de l'index au passage, parce que la règle existait déjà sans
s'appliquer à ce qu'ils suivaient : les deux rapports de `sorties/` et
`cog1968/passe_1968.log`. **Git n'applique pas ses motifs d'exclusion à un
fichier déjà suivi** — c'est ce qui a laissé `cartes/web/` grossir sous une
règle qui aurait dû le prendre.

**Le 11 octobre 2026**, le travail du 4 au 11 octobre est versionné, et trois
règles entrent dans `.gitignore` : les `.txt` des tables annuelles du JO
(`pdftotext` sur les PDF, 94 Mo, refaits à l'identique — le contraire des
`.txt` nus de tesseract, qui restent), `_to_delete/`, et les verrous de
LibreOffice. Le dépôt local est sur `master` ; le distant `origin`
(`adrdufour/histgis-fr`) n'a plus de branche `master` mais une `main`, et rien
n'a été poussé ce jour-là.

Ce que le dépôt ne garde pas, et pourquoi : les `*.avant_*` (filets de
sécurité locaux), les `*.log` (traces d'exécution), les
`jorf_txt/*_col.txt` (refaits par `jorf_colonnes.py` depuis les PDF). Les
`.txt` nus de `jorf_txt/`, eux, restent : leur OCR dépend de la version de
tesseract et ne se reproduirait pas à l'identique.

---

## Environnement

`environment.yml` est à la racine depuis le 2 septembre 2026 :

```
conda env create -f environment.yml   # ou mamba
conda activate histgis
```

Il déclare `psycopg2`, `shapely` ≥ 2, `pyshp` (importé sous le nom
`shapefile`), `matplotlib-base`, `openpyxl`, `xlrd`, `pandas`, et — en
`pip:`, faute d'exister sur conda-forge — `pgserver`, dont dépendent les
bancs `sql/banc_*.sh`. Côté outils appelés en sous-processus : GDAL
(`ogr2ogr`), `poppler` (`pdftoppm`, `pdftotext`, `pdfinfo`), `tesseract`
avec `tesseract-data-fra`, ImageMagick (`magick`/`convert`, pour le seul
`cog1968/essai_ocr.py`) et `unzip`.

**Cette liste a été relevée sur les imports réels, et elle corrige celle qui
figurait ici.** `pyproj` y était annoncé alors qu'aucun script ne l'importe —
`cartes/couverture_cantons_2025.py` dit même l'inverse en toutes lettres ;
`pandas` et ImageMagick, eux, étaient utilisés sans être déclarés. Une liste
de dépendances recopiée de mémoire se trompe dans les deux sens à la fois.

Le serveur reste **hors** de l'environnement, à dessein — c'est le piège
ci-dessous : PostgreSQL ≥ 13 avec `postgis` et `btree_gist` s'installent par
le système, pas par conda.

**Piège de connexion** : la libpq de conda cherche la socket dans `/tmp` alors
que Debian et Ubuntu la posent dans `/var/run/postgresql`. D'où des « No such
file or directory » alors que `psql` fonctionne dans le même terminal. Les
scripts essaient les trois emplacements ; `HISTGIS_DSN` force le choix.
