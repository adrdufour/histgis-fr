#!/usr/bin/env bash
# ============================================================================
# rejouer_apres_rebuild.sh — la chaîne de construction après `rebuild.sh`
#
#   cd sql && ./rebuild.sh && ./rejouer_apres_rebuild.sh
#
# À quoi ça sert
# --------------
# `rebuild.sh` est destructif (`DROP SCHEMA histgis CASCADE`) et ne va que
# jusqu'à `15`. Tout ce qui suit — couche moderne, cantons, circonscriptions,
# correctifs datés — doit être rejoué derrière, DANS L'ORDRE.
#
# Cet ordre n'était écrit nulle part avant le 20 août 2026, et son ignorance a
# cassé la base deux fois dans la même journée : une clé étrangère refusée
# parce qu'un fichier tardif occupait les unités d'un fichier plus ancien, puis
# une suppression en cascade qui a emporté sans un mot le travail de deux
# autres fichiers. Voir la section « Qui dépend de qui » de `sql/README.md`.
#
# Ce que ce script ne fait PAS
# ----------------------------
# Il ne joue aucun fichier de DIAGNOSTIC — 08, 09, 10, 12, 13, 14, 23, 26,
# 29 à 36, 43, 45. Ceux-là se lancent à la demande, ne modifient rien pour la
# plupart, et allongeraient inutilement une reconstruction déjà longue.
#
# `43_circo_fraction.sql` en particulier est INUTILE ici : il répare les
# circonscriptions des atomes-fractions après un rejeu isolé de `24`. Dans une
# chaîne complète, `27` et `28` passent après `24` et les posent eux-mêmes.
#
# Jusqu'où il va — complété le 6 septembre 2026
# ---------------------------------------------
# Il s'arrêtait à `40_scission_circo`, c'est-à-dire au 20 août. Les trente-deux
# étapes écrites depuis — les deux jalons (1954, 1968), le registre des actes,
# les salves, les deux reports, la trame ANR, la Seine de 1815 à 1967 et la
# partition — avaient une trace en base et ne figuraient dans aucun script :
# elles avaient été jouées à la main. **Un `rebuild.sh` les aurait toutes
# effacées sans que rien n'échoue.** Elles sont désormais ici, dans l'ordre du
# § 1 c de `sql/CHAINE.md`, qui n'a plus de raison d'être une procédure.
#
# Ce qu'il charge, en plus du SQL — ajouté le 2 septembre 2026
# ------------------------------------------------------------
# Trois jeux de données binaires, parce que `rebuild.sh` fait `DROP SCHEMA` et
# les emporte : la couche CANTON de GEOFLA avant `25`, les cinq lots
# d'outre-mer avant `40_outremer` (par `charger_outremer.sh`), et le
# GeoPackage ANR avant `82` (ajouté le 6 septembre).
#
# Aucun des trois n'était chargé par un script du dépôt. Le premier ne vivait
# qu'en commentaire dans l'en-tête de `25` ; le second dans un script que rien
# n'appelait. Les deux fichiers SQL s'arrêtaient donc sur leur garde-fou, et
# `25` — appelé tôt — bloquait tout ce qui suit : la chaîne ne pouvait pas
# aller au bout. C'est ce qui explique que les étapes tardives aient une trace
# en base alors que `25` et `40` n'en ont pas : elles ont été jouées à la main.
#
# **Un prérequis qui n'est écrit qu'en commentaire est un prérequis absent.**
# C'est le motif le plus fréquent de ce dépôt : `noms_geofla`, les tables
# parisiennes, `geofla_canton`, les lots d'outre-mer, et — trouvé le
# 6 septembre — `anr_commune`, dont dépendent `82`, `89`, `90`, `91` et `84`.
# ============================================================================
set -euo pipefail

ICI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RACINE="${1:-$(dirname "$ICI")}"

# La base est prise dans `PGDATABASE`, comme dans `rebuild.sh`, `load.sh` et
# `load_cog.sh` — et ce n'était PAS le cas avant le 6 septembre 2026.
#
# Le nom `histgis` était écrit en dur ici, à trois endroits : la variable
# `PSQL` et les deux `ogr2ogr`. Les quatre autres scripts de la chaîne
# honoraient `PGDATABASE` depuis toujours. **La conséquence est un piège, pas
# une inélégance** : `PGDATABASE=histgis_essai ./rebuild.sh` reconstruit la
# copie, puis `./rejouer_apres_rebuild.sh` écrit dans la VRAIE base — et rien
# n'échoue, les deux existent et ont le même schéma. On croit essayer, on
# écrase.
#
# C'est ce qui interdisait d'éprouver la chaîne complétée ailleurs que sur la
# base de travail, alors que c'est précisément une chaîne qui n'a jamais tourné
# au-delà de `25`.
#
#     PGDATABASE=histgis_essai ./rebuild.sh && PGDATABASE=histgis_essai ./rejouer_apres_rebuild.sh
#
# *Un jeu de scripts n'est cohérent qu'au niveau du moins cohérent d'entre eux,
# et celui-là ne se signale que quand il est trop tard.*
export PGDATABASE="${PGDATABASE:-histgis}"
PSQL="psql -v ON_ERROR_STOP=1 -q -d $PGDATABASE"
PG_DSN="dbname=$PGDATABASE"

echo "base cible : $PGDATABASE"

# Deux étapes de cette chaîne chargent un shapefile — la couche CANTON de
# GEOFLA avant `25`, les cinq lots d'outre-mer avant `40_outremer`. Le contrôle
# est ici plutôt qu'au milieu du script : rien ne sert de rejouer une heure de
# SQL pour buter sur un binaire absent.
command -v ogr2ogr >/dev/null || { echo "ogr2ogr introuvable (apt install gdal-bin)" >&2; exit 1; }

etape() {
    printf '\n\033[1m── %s\033[0m\n' "$1"
}

cd "$RACINE"

# 20 puis 21 AVANT le COG : `21` crée `commune_moderne`, et `load_cog.sh` finit
# par `23_cog_diag.sql`, qui l'exige. L'ordre inverse échoue sur
# « commune_moderne absente ». Mesuré le 20 août 2026, en le faisant.
# `noms_geofla` était créée par un script de CARTES, hors de la chaîne : six
# fichiers SQL en dépendent et une reconstruction complète échouait dessus.
etape "19 — noms de communes (noms_geofla)"
$PSQL -f "$ICI/19_noms_geofla.sql"

etape "20 — chronologie communale 1943-2012"
$PSQL -f "$ICI/20_commune_moderne.sql"

etape "21 — atomes modernes (crée commune_moderne)"
$PSQL -f "$ICI/21_atomes_modernes.sql"

# 22 charge les millésimes du COG, 23 diagnostique. C'est tout ce que
# `load_cog.sh` fait.
#
# Ce commentaire annonçait « 22, 36, 37, 23 » et attribuait à `37` la création
# de `noms_geofla`, qui est le fait de `19`. Ni `36` ni `37` n'étaient appelés
# par quoi que ce soit — c'est l'origine de la trace absente de `37`, trouvée
# le 2 septembre 2026. `36` est un diagnostic et reste hors chaîne par la règle
# du bandeau ; `37` écrit, et il est désormais appelé plus bas, à sa place
# (après les fichiers qui posent des noms, pas avant).
#
# Un commentaire qui décrit ce que le code ne fait pas ne se signale jamais
# tout seul : la chaîne ne se plaint pas d'un fichier qu'elle n'appelle pas.
etape "COG 1999-2012 (22 puis 23)"
"$ICI/load_cog.sh" "$RACINE"

etape "24 — cantons 1999-2012"
$PSQL -f "$ICI/24_canton_moderne.sql"

# La couche CANTON de GEOFLA (édition 2014), exigée par `25` et par `26`.
#
# Elle n'était chargée par AUCUN script du dépôt : la commande ogr2ogr ne
# vivait qu'en commentaire, dans l'en-tête de `25` et en prérequis de `26`.
# `25` s'arrêtait donc sur son garde-fou « geofla_canton absente », et comme
# `set -euo pipefail` propage l'échec, la chaîne ne pouvait pas aller plus
# loin. C'est l'origine de la trace absente de `25` (2 septembre 2026), et le
# jumeau exact du défaut que `charger_outremer.sh` nomme dans son en-tête :
# une consigne en commentaire n'est pas exécutable.
#
# `-a_srs` et non `-t_srs` : le lot métropolitain est déjà en Lambert-93, il
# n'y a rien à reprojeter. Même choix que pour COMMUNE dans `rebuild.sh`.
# `rebuild.sh` fait DROP SCHEMA : la table part avec le reste, elle se recharge
# donc ici et pas là-bas.
etape "GEOFLA — couche CANTON 2014 (prérequis de 25 et 26)"
CANTON_SHP="$(find "$RACINE/sources/geofla" -iname 'CANTON.SHP' -print -quit 2>/dev/null || true)"
[[ -n "$CANTON_SHP" ]] || {
    echo "CANTON.SHP introuvable sous $RACINE/sources/geofla" >&2
    echo "  Sans lui, 25 ne peut pas poser les pseudo-cantons de Marseille et" >&2
    echo "  Lyon : les 25 arrondissements resteraient sans canton de 1999 à 2012." >&2
    exit 1
}
echo "  source : ${CANTON_SHP#$RACINE/}"
SHAPE_ENCODING=ISO-8859-1 ogr2ogr -f PostgreSQL "PG:$PG_DSN" "$CANTON_SHP" \
    -nln histgis.geofla_canton -nlt MULTIPOLYGON \
    -lco GEOMETRY_NAME=geom -a_srs EPSG:2154 -overwrite
echo "  chargé : histgis.geofla_canton (3 708 entités attendues)"

etape "25 — pseudo-cantons de Marseille et Lyon"
$PSQL -f "$ICI/25_pseudo_canton.sql"

# 27 et 28 APRÈS 24 : ils rattachent les circonscriptions aux atomes-fractions
# que 24 vient de créer. Inverser l'ordre les priverait de ces atomes.
# `27` et `28` chargent leur table source par `\copy` depuis une variable psql.
# Sans `-v circo=...`, le chemin est VIDE et psql échoue sur « :: Aucun fichier
# ou dossier de ce nom » — message opaque qui ne nomme ni le fichier ni la
# variable. C'est ce qui a arrêté la chaîne le 20 août 2026.
etape "27 — circonscriptions de 2012"
$PSQL -v circo="$RACINE/circo/circo_2012.csv" -f "$ICI/27_circo_2012.sql"

etape "28 — circonscriptions de 1986"
$PSQL -v circo="$RACINE/circo/circo_1986.csv" -f "$ICI/28_circo_1986.sql"

# 49 juste après 28 : il comble les indéterminations que `28` a laissées, avec
# une source indépendante (atlas Gaudillère, § 5). Le CSV est engendré par
# `python3 circo/resoudre_1986_partage.py`.
if [ -f "$RACINE/circo/circo_1986_partage.csv" ]; then
    etape "49 — cantons partagés de 1986 (atlas Gaudillère)"
    $PSQL -v partage="$RACINE/circo/circo_1986_partage.csv" \
          -f "$ICI/49_circo_1986_partage.sql"
else
    echo "  circo_1986_partage.csv absent — 49 sauté." >&2
    echo "  Pour l'engendrer : python3 circo/resoudre_1986_partage.py" >&2
fi

# 51 : la colonne 1986 du ministère est brouillée pour l'Ain — 30 cantons sur
# 43 mal affectés. Corrigé d'après la loi n° 86-1197 et Gaudillère p. 89.
if [ -f "$RACINE/circo/circo_1986_correctifs.csv" ]; then
    etape "51 — correctif du découpage de 1986"
    $PSQL -v appliquer=1 -v correctif="$RACINE/circo/circo_1986_correctifs.csv" \
          -f "$ICI/51_circo_1986_correctif.sql"
fi

# --- Paris ------------------------------------------------------------------
# Quatre tables du schéma `histgis` sont produites par des scripts Python de
# `circo/` : `paris_quartier`, `paris_circo`, `paris_quartier_1815` et
# `iris_paris`. Elles vivaient HORS de la chaîne, et `rebuild.sh` les emportait
# à chaque reconstruction sans un mot — la leçon de `19_noms_geofla.sql`,
# répétée trois fois. Elles sont appelées ici.
#
# Ordre : la trame d'abord, le rattachement ensuite, le SQL en dernier.
#
# LES QUATRE SUIVENT `PGDATABASE`, et ce n'était pas le cas avant le
# 6 septembre 2026. Ils partagent la fonction `connexion()` de
# `paris_quartiers.py`, dont les trois DSN candidats portaient `dbname=histgis`
# en dur : **ils écrivaient dans la base de PRODUCTION pendant que la chaîne
# construisait la copie**, annonçaient leur succès, et `52` échouait vingt
# lignes plus bas sur « paris_quartier ou paris_circo absente » — dans la
# copie, où rien n'avait été posé. Le message était exact et désignait le
# mauvais coupable : les tables ne manquaient pas, elles étaient ailleurs.
#
# **Le premier correctif — leur passer `HISTGIS_DSN="$PG_DSN"` d'ici — était
# faux, et c'est instructif.** `psql` et `ogr2ogr` sont les binaires du
# système, dont libpq cherche la socket dans `/var/run/postgresql` ;
# `psycopg2` vient de l'environnement conda, où elle est cherchée dans `/tmp`.
# Le même `dbname=histgis_essai` a donc échoué côté Python à l'instant où il
# venait de réussir côté shell. C'est précisément ce que la liste de candidats
# de `connexion()` existe pour absorber, et lui imposer un DSN la
# court-circuitait.
#
# Le correctif juste est dans `paris_quartiers.py` : les candidats sont bâtis
# sur `PGDATABASE`, et le chemin de la socket reste CHERCHÉ. Rien à passer
# ici — `PGDATABASE` est exporté en tête de ce fichier.
#
# *Paramétrer, c'est choisir ce qui varie. Le nom de la base varie ; le chemin
# de la socket dépend du client, et le figer casse ce qui marchait.*
etape "Paris — trames et rattachements (scripts Python)"
python3 "$RACINE/circo/paris_quartiers.py"
python3 "$RACINE/circo/paris_circo.py"
if [ -d "$RACINE/42-Vasserot_quartiers_v1L93" ]; then
    python3 "$RACINE/circo/paris_quartiers_1815.py"
    python3 "$RACINE/circo/paris_circo_1815.py"
else
    echo "  couche ALPAGE-Vasserot absente — 1815 sauté." >&2
fi

etape "52 — Paris dans le découpage de 1986"
$PSQL -v appliquer=1 -f "$ICI/52_paris_circo_1986.sql"

etape "53 — géométrie parisienne alignée sur la trame IRIS"
$PSQL -v appliquer=1 -f "$ICI/53_paris_geom_iris.sql"

if [ -f "$RACINE/circo/paris_circo_1815.csv" ]; then
    etape "54 — Paris de 1815 à 1863 (ALPAGE-Vasserot)"
    $PSQL -v appliquer=1 -v src="$RACINE/circo/paris_circo_1815.csv" \
          -f "$ICI/54_paris_circo_1815.sql"
fi

# 56 AVANT 55 : `56` retire les rattachements d'arrondissement de 1876-1941 et
# pose les quartiers à la place. `55` ne comble que des périodes vides et
# refuse de tourner si elles ne le sont pas — mais les siennes ne chevauchent
# pas celles de `56`, donc l'ordre est indifférent entre eux. Il est fixé ici
# pour que la sortie se lise dans l'ordre chronologique du travail.
etape "56 — Paris au quartier, 1876-1941 (remplace TRF-GIS)"
$PSQL -v appliquer=1 -f "$ICI/56_paris_circo_1876.sql"

etape "55 — Paris : 1863-1870 et 1941-1986"
$PSQL -v appliquer=1 -f "$ICI/55_paris_circo_serie.sql"

# --- Marseille, SOUS CONDITION -----------------------------------------------
# `32` était appelé sans condition, et il ne pouvait PAS passer : son entrée est
# `gaudillere/marseille_cantons.gpkg`, la digitalisation à la main que le § 2 de
# `RESTE_A_FAIRE.md` décrit comme « le plus gros chantier manuel restant, et
# rien n'est commencé ». **Le fichier n'existe pas**, et les deux `ogr2ogr` qui
# l'importeraient ne vivaient que dans l'en-tête de `32`.
#
# La chaîne était donc déjà cassée ici AVANT la complétion du 6 septembre —
# à une étape que personne n'avait jamais atteinte, `25` bloquant bien plus
# haut. *Un fichier appelé sans condition dans une chaîne qui ne va pas
# jusqu'à lui n'est pas un appel : c'est une intention.*
#
# Ce n'est donc pas un prérequis manquant comme les quatre autres, où la donnée
# était sur le disque et la commande en commentaire. Ici la donnée reste à
# produire, et le fichier est sauté en le disant — comme `49`, `51`, `46`
# et l'outre-mer.
MARS_GPKG="$RACINE/gaudillere/marseille_cantons.gpkg"
if [ -f "$MARS_GPKG" ]; then
    etape "Marseille — les deux couches du GeoPackage (prérequis de 32)"
    ogr2ogr -f PostgreSQL "PG:$PG_DSN" "$MARS_GPKG" \
        -nln histgis.gaud_lignes     -nlt LINESTRING -overwrite lignes
    ogr2ogr -f PostgreSQL "PG:$PG_DSN" "$MARS_GPKG" \
        -nln histgis.gaud_etiquettes -nlt POINT      -overwrite etiquettes
    echo "  chargé : gaud_lignes, gaud_etiquettes (12 étiquettes attendues)"

    etape "32 — géométrie des cantons de Marseille"
    $PSQL -1 -f "$ICI/32_marseille_geom.sql"
else
    echo "  gaudillere/marseille_cantons.gpkg absent — 32 sauté." >&2
    echo "  C'est un chantier de SAISIE, pas un fichier égaré : géoréférencer" >&2
    echo "  et digitaliser dans QGIS, protocole dans" >&2
    echo "  gaudillere/protocole_georeferencement.md (RESTE_A_FAIRE § 2)." >&2
    echo "  Conséquence, connue et déclarée : les douze atomes-fractions de" >&2
    echo "  Marseille gardent le polygone de la ville entière, d'où 1 176 km²" >&2
    echo "  comptés en trop en 1870 et 2 587 en 1940 — le premier poste du" >&2
    echo "  double comptage de \`12\`." >&2
fi

# --- outre-mer --------------------------------------------------------------
# `40_outremer.sql` était bien appelé ici, avec son `-v circo_om` et son CSV
# présent sur le disque — et il s'arrêtait pourtant sur son garde-fou
# « om_commune_src absente ». La cause n'était pas dans le SQL : les tables
# `om_*_src` viennent de `charger_outremer.sh`, que RIEN n'appelait. Origine de
# la trace absente de `40`, trouvée le 2 septembre 2026.
#
# `rejouer_circo.sh` connaissait déjà la question et la traitait par un test de
# présence ; la même prudence est reprise ici, avec le chargement en plus.
# L'outre-mer vit dans ses propres tables `om_*` et ne partage rien avec la
# métropole : son absence ne doit pas arrêter la chaîne, mais elle doit se dire.
if find "$RACINE/sources/outremer" -path "*2015-03-04*" -ipath "*/COMMUNE/*" \
        -iname 'COMMUNE.SHP' -print -quit 2>/dev/null | grep -q .; then
    etape "outre-mer — les cinq lots GEOFLA (prérequis de 40)"
    HISTGIS_DSN="$PG_DSN" bash "$ICI/charger_outremer.sh"

    etape "40 — outre-mer"
    $PSQL -v circo_om="$RACINE/circo/circo_outremer_1986_2012.csv" \
          -f "$ICI/40_outremer.sql"
else
    echo "  lots GEOFLA d'outre-mer absents — 40_outremer sauté." >&2
    echo "  Pour les récupérer : bash sources/outremer/telecharger_outremer.sh" >&2
    echo "  Sans conséquence pour la métropole : les tables om_* sont séparées." >&2
fi

# --- correctifs datés, tous additifs et tracés -------------------------------
# Ils viennent APRÈS les couches qu'ils corrigent, et plusieurs référencent des
# unités créées par 24, 27 ou 28 : c'est ce qui interdit de rejouer ceux-là
# seuls sans défaire ceux-ci d'abord.
etape "38 — décret de 1982, cantons de Bourg-en-Bresse"
$PSQL -f "$ICI/38_decret_1982_ain.sql"

# 50 : quatre noms de cantons détruits DANS la source TRF-GIS (U+FFFD). Sans
# lui, une reconstruction ramène « Orl<?><?>ans-Est » sur la carte. Il exige
# `appliquer=1` — comme `37`, il tourne à blanc par défaut.
etape "50 — noms détruits dans la source TRF-GIS"
$PSQL -v appliquer=1 -f "$ICI/50_noms_perdus_trfgis.sql"

# 37 : l'autre réparation de noms, et le pendant de `50`. Il remplace les
# caractères de contrôle C1 de `unit.nom` et `unit_version.nom` par ce que
# Windows-1252 place à ces positions — 1 975 valeurs au 11 août, tous les `œ`
# de la nomenclature. Sans lui, tout appariement par nom échoue en silence sur
# ces valeurs.
#
# ICI et pas dans l'étape COG, contrairement à ce que l'ancien commentaire
# annonçait : il répare `unit` et `unit_version`, qui n'existent pas encore
# quand `load_cog.sh` tourne. Il doit passer APRÈS les fichiers qui posent des
# noms.
#
# Il peut très bien ne rien avoir à faire, et ce sera un bon signe :
# `load_cog.sh` lit désormais le COG en WIN1252, ce qui tarit la source du
# défaut. Une trace vide voudra dire « a tourné, rien à réparer », comme celle
# de `50` — pas « n'a pas tourné ». C'est toute la différence que la trace
# absente ne permettait pas de faire.
#
# Comme `50`, il exige `appliquer=1` : sans lui il mesure, et n'écrit pas sa
# trace.
etape "37 — noms lus en Latin-1 alors qu'ils étaient en Windows-1252"
$PSQL -v appliquer=1 -f "$ICI/37_reparer_encodage.sql"

etape "39 — la Meurthe reprend son numéro"
$PSQL -f "$ICI/39_meurthe_1870.sql"

# Juste derrière `39`, et pas ailleurs : les deux font le même geste sur les
# deux étages d'une même unité administrative. `39` seul laisse une unité circo
# en `99` — donc un 99e département dans tout ce qui énumère les `dep`, et une
# Meurthe de 1870 coupée en deux, ses cantons dans le 54 et sa circonscription
# à part. Les séparer dans la chaîne, c'est se préparer à rejouer l'un sans
# l'autre.
etape "92 — la circonscription de la Meurthe rejoint le 54"
$PSQL -f "$ICI/92_meurthe_circo.sql"

etape "41 — communes rétablies après 1999"
$PSQL -f "$ICI/41_retablissement.sql"

etape "42 — rattacher le passé d'un atome existant"
$PSQL -f "$ICI/42_rattachement_arriere.sql"

etape "44 — absorptions anciennes"
$PSQL -f "$ICI/44_absorption_ancienne.sql"

# 46 a besoin de hac/hac_filiation.csv, et `\copy` résout depuis le répertoire
# de lancement : le chemin est passé explicitement, comme pour 11.
if [ -f "$RACINE/hac/hac_filiation.csv" ]; then
    etape "46 — communes nées pendant la série, filiation HAC"
    $PSQL -v hac="$RACINE/hac/hac_filiation.csv" -f "$ICI/46_creation_serie.sql"
else
    echo "  hac_filiation.csv absent — 46 sauté." >&2
    echo "  Pour l'engendrer : python3 hac/hac_filiation.py" >&2
fi

# 47 avant 40, pour la même raison qui met 46 avant lui : la filiation est une
# réponse DIRECTE, l'unanimité des voisins une réponse par procuration. 47
# ramasse le cas où les voisins sont muets — Port-Saint-Louis-du-Rhône, dont le
# seul voisin de canton est une fraction d'Arles sans circonscription.
# `47` lit `hac_filiation`, que `46` crée — il hérite donc de sa condition, et
# ne l'avait pas : `46` sauté, `47` s'arrêtait sur son garde-fou et emportait
# la chaîne. Trouvé à l'audit du 6 septembre, pas à l'exécution : le CSV est
# présent, la branche n'a jamais été prise. *Une étape conditionnelle rend
# conditionnel tout ce qui lit sa sortie, et cela ne se voit pas tant que la
# condition est vraie.*
if [ -f "$RACINE/hac/hac_filiation.csv" ]; then
    etape "47 — circo de la mère, quand les voisins se taisent"
    $PSQL -f "$ICI/47_circo_mere.sql"
else
    echo "  46 sauté, donc 47 aussi : il lit la table hac_filiation." >&2
fi

# 40 EN DERNIER, et c'est un déplacement du 20 août 2026.
#
# Il comble les trous de la couche circo par l'unanimité des voisins de canton.
# C'est une réponse par PROCURATION : elle ne vaut que là où une réponse plus
# directe manque. `46` répond mieux quand il le peut — il tient de HAC le nom
# de la mère — donc il doit passer AVANT et `40` ramasser ce qui reste.
#
# Placé avant, `40` comblait d'abord, et le garde-fou 4 de `46` (« rien sur une
# période déjà occupée ») empêchait ensuite la meilleure source de s'exprimer.
# Il manquait en outre tout ce que `46` venait d'ouvrir.
etape "40 — trous de la couche circo (après 46 : voir le commentaire)"
$PSQL -f "$ICI/40_scission_circo.sql"

# ============================================================================
# LES ÉTAPES TARDIVES — ajoutées le 6 septembre 2026
# ============================================================================
# Tout ce qui suit a été écrit entre le 22 août et le 6 septembre 2026 et
# JOUÉ À LA MAIN, un fichier à la fois. Ce script s'arrêtait à `40_scission`,
# et `sql/CHAINE.md` § 1 c tenait la liste sous le titre « APPELÉS PAR AUCUN
# SCRIPT — à jouer à la main, dans cet ordre ». Tant que cette liste était la
# procédure, **le prochain `rebuild.sh` effaçait les deux jalons, les deux
# reports, le registre des actes, la trame ANR et toute la Seine** — et rien
# n'aurait échoué : la base se serait reconstruite, plus petite, en silence.
#
# L'ordre ci-dessous est celui de `CHAINE.md` § 1 c, complété des six fichiers
# écrits après lui (`87` à `91`, et `84`) et de leurs dépendances mesurées dans
# leurs propres garde-fous, pas déduites de leur numéro :
#
#   88 exige 68 et 87        (son § 1 le dit et lève une EXCEPTION)
#   89 exige anr_commune ET atom_geom_anr, donc 82
#   90 exige 57 (l'unité L7501@1848) et les onze annexées de 89
#   91 exige les circos parisiennes de 1863 (55), les annexées (89) et 1954 (68)
#   84 exige 82 — « PRÉREQUIS : jouer sql/82_anr_geom.sql avant celui-ci »
#
# `-1` là où le fichier le demande, et nulle part ailleurs : `38`, `39`, `92`
# et `84` ouvrent leur propre transaction et échouent sous `-1`.
#
# NE SONT PAS ICI, et ce n'est pas un oubli :
#   `73`, `78`, `80`, `83`, `86` et les `diag_*` — lecture seule (§ 2 de
#   CHAINE.md) ; ils s'appellent à la demande et allongeraient la chaîne sans
#   rien y écrire.
#   `85_conflit_38_79.sql` — il rend à `38` la fenêtre 1982-1999 que `79`
#   occupe, et ce conflit n'existe QUE parce que `79` a été joué après `38`
#   hors de toute chaîne. Ici `38` passe en ligne 259 et `79` bien plus bas :
#   le § 5 de `79` n'écrit que sur une fenêtre entièrement libre, donc il
#   écarte ces six atomes de lui-même. **Si un passage complet de ce script
#   laisse `85` avec quelque chose à faire, c'est l'ordre qui est faux, pas
#   `85`** — et c'est la recette de cette section.

# --- Paris, 1848 ------------------------------------------------------------
# Avant les jalons : `90` viendra plus bas lever la limite que celui-ci déclare
# (« nous ne posons que sa part parisienne »), et il exige l'unité L7501@1848.
etape "57 — Paris 1848-1852 : le département EST la circonscription"
$PSQL -1 -v appliquer=1 -f "$ICI/57_paris_circo_1848.sql"

# --- le jalon de 1968 -------------------------------------------------------
# `58` dépose et résout sans écrire dans `membership` ; `59` pose. La méthode
# de `20` : mesurer, noter, écrire ensuite.
etape "58 — recensement de 1968 : dépôt et résolution"
$PSQL -f "$ICI/58_cog1968_stage.sql"

etape "59 — JALON 1968 : 32 659 rattachements, 2 899 cantons"
$PSQL -1 -f "$ICI/59_cog1968_membership.sql"

# Forbach-II n'est ni dans TRF-GIS ni dans le COG — les deux seules sources de
# `unit`. Il est invisible par construction, et `59` le délègue explicitement.
etape "60 — Forbach-II, le canton que 59 délègue"
$PSQL -1 -f "$ICI/60_canton_forbach2.sql"

# --- le jalon de 1954 -------------------------------------------------------
# `65` et `69` sont en lecture seule mais ne sont PAS des diagnostics : ils
# écrivent deux CSV dont `66` et `68` se servent. Les sauter ne casse rien
# tout de suite — c'est bien le problème.
etape "65 — noms des communes vivantes en 1954 (produit noms_1954.csv)"
$PSQL -f "$ICI/65_noms_1954.sql"

etape "66 — recensement de 1954 : dépôt et résolution"
$PSQL -f "$ICI/66_cog1954_stage.sql"

etape "69 — le pont Seine / Seine-et-Oise (produit le CSV de correspondance)"
$PSQL -f "$ICI/69_pont_seine_et_oise.sql"

etape "67 — les trois cantons créés entre 1940 et 1954"
$PSQL -1 -f "$ICI/67_cantons_1949_1951.sql"

etape "68 — JALON 1954 : 30 035 atomes, 2 946 cantons"
$PSQL -1 -f "$ICI/68_cog1954_membership.sql"

# 87 juste après 68, et 88 juste après 87 : quatre noms que l'extraction du
# fascicule n'a pas su apparier (`Choisy-ic-Roi`, `Nolsy-ie-Sec`, `SCEAUX` en
# capitales, `Vitejuit`). `88` lève une EXCEPTION si le jalon ne les porte pas.
etape "87 — quatre communes de la Seine rendues au jalon cantonal de 1954"
$PSQL -1 -v appliquer=1 -f "$ICI/87_seine_canton_1954.sql"

etape "88 — la banlieue de la Seine entre dans la couche circo, 1945-1967"
$PSQL -1 -v appliquer=1 -f "$ICI/88_seine_circo_1945_1967.sql"

# --- le registre des actes, puis les salves ---------------------------------
# `72` charge huit CSV par \copy relatifs à la RACINE — le `cd` du haut de ce
# script y pourvoit. `74` à `77` lisent le registre qu'il pose.
etape "72 — registre des 343 décrets cantonaux"
$PSQL -f "$ICI/72_registre_actes.sql"

etape "74 — Yvelines 1968 : le fascicule manque, la date d'effet est un FAIT"
$PSQL -f "$ICI/74_yvelines_1967.sql"

etape "75 — compositions de 1973 et 1982 (première date conventionnelle)"
$PSQL -1 -f "$ICI/75_composition_1973_1982.sql"

etape "76 — la longue traîne des salves, même convention"
$PSQL -1 -f "$ICI/76_composition_salves_restantes.sql"

etape "77 — 66 transferts de commune, dates INSEE : des faits, pas une règle"
$PSQL -1 -f "$ICI/77_transferts_dates.sql"

# --- les deux reports -------------------------------------------------------
# `79` APRÈS `77`, jamais avant : il ne pose que sur une fenêtre libre, et les
# faits doivent avoir pris leur place d'abord. `81` après `79`, qu'il prend
# pour témoin.
etape "79 — REPORT ARRIÈRE depuis 1999"
$PSQL -1 -f "$ICI/79_report_1999_arriere.sql"

etape "81 — REPORT AVANT depuis 1968 (79 pour témoin)"
$PSQL -1 -f "$ICI/81_report_1968_avant.sql"

# `93` ne dépend ni de `79` ni de `81` — il vit sous 1954, où aucun des deux ne
# descend. Il est placé ici parce que c'est le troisième report et qu'on les lit
# ensemble, pas parce qu'un ordre l'impose. Ses vrais prérequis sont `67` et
# `68`, joués plus haut.
etape "93 — 1941-1953, entre deux bouts attestés"
$PSQL -1 -f "$ICI/93_report_1940_1954.sql"

# `95` APRÈS `79` ET `81`, et c'est un ordre imposé, pas une commodité : il
# comble les trous ENTRE leurs deux reports, par l'accord du canton qui ferme
# le trou à gauche et de celui qui l'ouvre à droite. Joué avant eux, il ne
# trouverait aucun bout. Écrit le 23 septembre 2026.
etape "95 — 1969-1998, entre deux bouts attestés"
$PSQL -1 -f "$ICI/95_report_deux_bouts_1969_1999.sql"

# --- la trame communale historique ANR --------------------------------------
# Quatrième prérequis qui ne vivait qu'en commentaire, après `noms_geofla`, les
# tables parisiennes, `geofla_canton` et les lots d'outre-mer : `anr_commune`
# est chargée par un `ogr2ogr` écrit dans l'en-tête de `82` et dans
# `sql/JOUER_82.md`, et par aucun script. `rebuild.sh` fait DROP SCHEMA : elle
# part avec le reste.
#
# 550 Mo, 34 millions de sommets, de dix minutes à une demi-heure. C'est
# l'étape la plus longue de la chaîne — `SPATIAL_INDEX=NONE` est le gros gain,
# `82` ne faisant AUCUN prédicat spatial sur cette table.
ANR_GPKG="$RACINE/ANR_COMMUNES_22042026/COMMUNES_22042026.gpkg"
if [ -f "$ANR_GPKG" ] && [ -f "$RACINE/build/anr_variantes.csv" ]; then
    etape "ANR — la couche geometries_only_processed (prérequis de 82)"
    echo "  550 Mo : compter dix minutes à une demi-heure."
    ogr2ogr -f PostgreSQL "PG:$PG_DSN" "$ANR_GPKG" geometries_only_processed \
        -nln histgis.anr_commune -nlt MULTIPOLYGON \
        -lco GEOMETRY_NAME=geom -lco FID=gid -a_srs EPSG:2154 -overwrite \
        -lco SPATIAL_INDEX=NONE -lco UNLOGGED=YES \
        --config PG_USE_COPY YES -gt 65536
    echo "  chargé : histgis.anr_commune"

    etape "82 — trame ANR datée, à CÔTÉ de atom_geom et non à sa place"
    $PSQL -1 -v variantes="$RACINE/build/anr_variantes.csv" -f "$ICI/82_anr_geom.sql"

    # --- la Seine avant 1870 ------------------------------------------------
    # Les trois exigent `atom_geom_anr` : les onze communes annexées à Paris en
    # 1860 n'ont AUCUNE géométrie ailleurs, et le critère de pose de `90` est
    # « l'atome a un polygone ANR couvrant la date ». Sans ANR, `carte_partition`
    # les dessinerait quand même par le repli GEOFLA — avec leur forme de 2011.
    # Une commune de 1929 dessinée en 1848 n'est pas une approximation.
    etape "89 — les onze communes que Paris a mangées en 1860"
    $PSQL -1 -v appliquer=1 -f "$ICI/89_seine_annexees_1860.sql"

    etape "90 — la Seine de 1848 : la limite déclarée par 57 est levée"
    $PSQL -1 -v appliquer=1 -f "$ICI/90_seine_1848_banlieue.sql"

    etape "91 — la banlieue de la Seine, 1815-1870 (planches Gaudillère)"
    $PSQL -1 -v appliquer=1 -f "$ICI/91_seine_1815_1870.sql"

    # --- la carte -----------------------------------------------------------
    # `84` NE MODIFIE RIEN : que des fonctions, une trace et une procédure.
    # Il est ici parce que `cartes/export_web.py --partition` les appelle, et
    # qu'un DROP SCHEMA les emporte comme le reste.
    etape "84 — la trame de partition (fonctions ; ne modifie aucune donnée)"
    $PSQL -f "$ICI/84_carte_partition.sql"
else
    echo "  GeoPackage ANR ou build/anr_variantes.csv absent — 82 sauté," >&2
    echo "  et avec lui 89, 90, 91 et 84, qui exigent tous atom_geom_anr." >&2
    echo "  Conséquences, à connaître avant de continuer sans :" >&2
    echo "    — la carte retombe sur la trame hybride et ses 4 542,8 km² de" >&2
    echo "      couture ; \`export_web.py --partition\` refusera de partir ;" >&2
    echo "    — la Seine n'a plus de banlieue avant 1870." >&2
    echo "  Le GeoPackage se demande à l'équipe ANR-COMMUNES ; le CSV de" >&2
    echo "  variantes s'engendre par sorties/anr/anr_variantes_verdict.py." >&2
fi

# ============================================================================
# LES DROITS DU RÔLE DE LA CARTE — ajouté le 22 septembre 2026
# ============================================================================
# `export_web.py --role histgis_carte` et `cartes/export_partition.sh`
# descendent dans ce rôle, qui n'a que SELECT : c'est ce qui rend au moteur la
# garantie qu'un export n'écrit rien (voir `connecte()` dans export_web.py).
#
# Ces droits portent sur le SCHÉMA, et `rebuild.sh` fait `DROP SCHEMA histgis
# CASCADE` : ils partent avec lui, en silence. Les droits sur la BASE
# (CONNECT, TEMPORARY) et l'appartenance au rôle survivent, eux. Sans ce
# bloc, le premier export après une reconstruction s'arrêtait sur
# « permission denied for schema histgis » à chaque lot. Septième prérequis
# qui ne vivait qu'en commentaire, dans la docstring d'un script Python.
#
# Le rôle est créé une fois, à la main, parce qu'il appartient au cluster et
# non à la base (voir la docstring) ; ce script ne le crée pas, il le sert.
etape "droits du rôle histgis_carte (le DROP SCHEMA les a emportés)"
$PSQL <<'SQL'
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'histgis_carte') THEN
        RAISE NOTICE 'Rôle histgis_carte absent : rien à rendre. Le créer une fois '
                     '(docstring de connecte() dans cartes/export_web.py) avant '
                     'd''exporter avec --role.';
        RETURN;
    END IF;
    GRANT USAGE ON SCHEMA histgis TO histgis_carte;
    GRANT SELECT ON ALL TABLES IN SCHEMA histgis TO histgis_carte;
    RAISE NOTICE 'histgis_carte : USAGE et SELECT rendus sur le schéma histgis.';
END $$;
SQL

cat <<'FIN'

──────────────────────────────────────────────────────────────────────
Chaîne rejouée.

La mesure qui fait foi est EXTÉRIEURE :

    cd sql && ./controle_gay.sh

Repères de la chaîne sans `46`, mesurés le 20 août 2026 :

    paris perdus        4 / 414   (99,03 %)
    atomes mal placés   149  (1870)   150  (1940)
    IoU moyen           0,99302      0,99346
    non couvert 1870    205 km²  sur 39 communes

`46` doit faire BAISSER le non-couvert sans faire monter les atomes
mal placés. S'ils montent, HAC nomme une mère dont le territoire ne
vient pas — c'est ce qui a fait rejeter l'essai sur `11` — et il faut
défaire plutôt qu'expliquer. La commande est en fin de `46`.

La recette PROPRE à la complétion du 6 septembre 2026 :

    psql -f sql/diag_passages.sql
    psql -f sql/85_conflit_38_79.sql      # instruit, n'écrit pas

`diag_passages` doit désormais trouver une trace pour TOUTES les étapes, y
compris `25`, `37` et `40` — les trois qui n'en avaient jamais eu, faute d'un
prérequis qui ne vivait qu'en commentaire.

`85` doit trouver ZÉRO fraction à libérer. Il n'existe que parce que `79` a été
joué après `38` hors de toute chaîne ; joué dans cet ordre, `79` écarte ces six
atomes de lui-même. **S'il trouve quelque chose, c'est l'ordre de ce script qui
est faux, pas `85`.**

Puis, pour la carte :

    python3 cartes/export_web.py                     # trame ordinaire
    bash cartes/export_partition.sh                  # trame de partition
    python3 cartes/export_web.py --outremer          # si 40 est passé
FIN
