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
if [ -d "$RACINE/sources/42-Vasserot_quartiers_v1L93" ]; then
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
# `annexes/gaudillere/marseille_cantons.gpkg`, la digitalisation à la main que le § 2 de
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
MARS_GPKG="$RACINE/annexes/gaudillere/marseille_cantons.gpkg"
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
    echo "  annexes/gaudillere/marseille_cantons.gpkg absent — 32 sauté." >&2
    echo "  C'est un chantier de SAISIE, pas un fichier égaré : géoréférencer" >&2
    echo "  et digitaliser dans QGIS, protocole dans" >&2
    echo "  annexes/gaudillere/protocole_georeferencement.md (RESTE_A_FAIRE § 2)." >&2
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

# 46 a besoin de annexes/hac/hac_filiation.csv, et `\copy` résout depuis le répertoire
# de lancement : le chemin est passé explicitement, comme pour 11.
if [ -f "$RACINE/annexes/hac/hac_filiation.csv" ]; then
    etape "46 — communes nées pendant la série, filiation HAC"
    $PSQL -v hac="$RACINE/annexes/hac/hac_filiation.csv" -f "$ICI/46_creation_serie.sql"
else
    echo "  hac_filiation.csv absent — 46 sauté." >&2
    echo "  Pour l'engendrer : python3 annexes/hac/hac_filiation.py" >&2
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
if [ -f "$RACINE/annexes/hac/hac_filiation.csv" ]; then
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
#   105 exige c15_composition (64) et atom_geom_anr (82) ; 64 n'exige rien
#   106 exige 64, 82, creation_trace (15) et la Meurthe rendue au 54 (39)
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

# `96` APRÈS les deux jalons et la Seine, AVANT le registre et les reports :
# `79`, `81`, `93` et `95` lisent les jalons dans `membership`, et c'est la
# lecture corrigée qu'ils doivent reporter. Écrit le 23 septembre 2026, sur
# Lamastre (lue « 3 19 » en 1954) et les 804 lectures de 1968 que 1954 et
# 1999 contredisent ensemble.
etape "96 — les jalons de 1954 et 1968 jugés par la géométrie"
$PSQL -1 -v appliquer=1 -f "$ICI/96_jalons_lecture_absurde.sql"

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

# `97` APRÈS `93` — c'est `93` qui borne par la gauche le trou 1955-1967 ;
# sans lui, les deux fenêtres se confondent. Il lit `cantons/annexe_vii.csv`
# par un \copy relatif à la RACINE. Écrit le 23 septembre 2026.
etape "97 — 1941-1967, entre deux bouts attestés"
$PSQL -1 -f "$ICI/97_report_deux_bouts_1941_1967.sql"

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
ANR_GPKG="$RACINE/sources/ANR_COMMUNES_22042026/COMMUNES_22042026.gpkg"
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

    # Ajoutés le 3 octobre 2026. `100` comble le sol du Perreux, sans
    # propriétaire dans ANR avant 1860, en le rendant à Nogent ; `101` prolonge
    # le sol des annexées jusqu'à la fin de la division 1857-1863. Tous deux
    # écrivent dans `atom_geom_anr`, donc après `82`/`89` ; `101` AVANT `91`,
    # qui borne les rattachements par la vie ANR de l'atome.
    etape "100 — le sol du Perreux rendu à Nogent avant 1860"
    $PSQL -1 -v appliquer=1 -f "$ICI/100_nogent_perreux_avant_1860.sql"

    etape "101 — les annexées jusqu'à la fin de la division 1857-1863"
    $PSQL -1 -v appliquer=1 -f "$ICI/101_seine_annexees_1859_1862.sql"

    # `90` et `91` ICI, et non après `104` : `102` calcule le lambeau contre
    # les atomes de la Seine VIVANTS sur [1860,1863), et ce sont les
    # rattachements de `91` qui les font vivre. Joués après lui, `102` ne
    # trouvait aucun lambeau et `118` refusait — rebuild du 19 octobre 2026.
    # `102` avait été joué à la main le 3 octobre, `91` déjà en place.
    # Ni `90` ni `91` ne lisent ce que posent `102`, `118`, `103`, `119`, `104`.
    etape "90 — la Seine de 1848 : la limite déclarée par 57 est levée"
    $PSQL -1 -v appliquer=1 -f "$ICI/90_seine_1848_banlieue.sql"

    etape "91 — la banlieue de la Seine, 1815-1870 (planches Gaudillère)"
    $PSQL -1 -v appliquer=1 -f "$ICI/91_seine_1815_1870.sql"

    etape "102 — les lambeaux pris par Paris en 1860 (bois de Boulogne, Ternes)"
    $PSQL -1 -v appliquer=1 -f "$ICI/102_seine_lambeaux_1860_1862.sql"

    etape "104 — les cantons de banlieue de la Seine prolongés de 1955 à 1967 (hypothèse)"
    $PSQL -1 -v appliquer=1 -f "$ICI/104_seine_cantons_1955_1967.sql"

    # --- l'Yonne avant 1870 -------------------------------------------------
    # Ajoutés le 4 octobre 2026. `64` dépose la composition cantonale des
    # découpages 1815-1870 lue dans Gaudillère (`c15_composition`) et n'écrit
    # rien d'autre ; il n'était appelé par aucun script, et un rebuild l'avait
    # emporté sans que rien ne le signale. `105` pose
    # l'Yonne de 1815 à 1870 sur cette table, bornée par la vie ANR de chaque
    # atome — d'où sa place après `82`. Son § 8 lit `84`, qui passe plus bas :
    # sur une base reconstruite il s'abstient, et le dit.
    etape "64 — les découpages 1815-1870 de Gaudillère (c15_composition)"
    $PSQL -f "$ICI/64_composition_1815_stage.sql"

    etape "105 — l'Yonne, 1815-1870 : cantons et circonscriptions"
    $PSQL -1 -v appliquer=1 -f "$ICI/105_yonne_1815_1870.sql"

    # Ajouté le 4 octobre 2026. `106` est `105` généralisé : les
    # circonscriptions 1815-1870 de `c15_composition`, un département par
    # appel, sur les atomes de 1870. Il exige `64`, `82` et `creation_trace`
    # (`15`), et lit la Meurthe dans le 54, donc après `39`. Refuse 75 (`87` à
    # `91`), 89 (`105`) et 57 (pas de trame française de 1870 en base).
    # Le 84 est dans la liste : sans lui, la carte de la Drôme d'avant 1870
    # absorbe l'Enclave des Papes (+127 km² à Vinsobres, par comblement).
    # Journal par département dans build/p106_NN.log.
    # Seconde série de photos (4 octobre 2026) : 01-11, 13-20, 64-73, 83.
    for d in 01 02 03 04 05 06 07 08 09 10 11 13 14 15 16 17 18 19 20 \
             21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 \
             41 42 43 44 45 46 47 48 49 50 51 52 53 55 56 58 59 60 61 62 63 \
             64 65 66 67 68 69 70 71 72 73 83 \
             99 74 76 77 78 79 80 81 82 84 85 86 87 88; do
        etape "106 — circonscriptions 1815-1870, département $d"
        $PSQL -P pager=off -1 -v appliquer=1 -v dep="$d" \
              -f "$ICI/106_circo_1815_1870.sql" > "$RACINE/build/p106_$d.log" 2>&1 \
            || { echo "  106 refusé sur $d — voir build/p106_$d.log" >&2; exit 1; }
    done

    # Ajouté le 6 octobre 2026. `107` pose les CANTONS 1815-1870 que `106` ne
    # pose pas : le canton de 1870 remonté à 1815, sauf les exceptions de
    # l'atlas (cantons pas encore créés ou pas encore scindés). France
    # entière en un appel ; mêmes prérequis que `106`. Exclut 75, 89, 57.
    etape "107 — cantons 1815-1870, France entière"
    $PSQL -P pager=off -1 -v appliquer=1 \
          -f "$ICI/107_cantons_1815_1870.sql" > "$RACINE/build/p107.log" 2>&1 \
        || { echo "  107 refusé — voir build/p107.log" >&2; exit 1; }

    # Ajouté le 10 octobre 2026. `108` inscrit ce que la découpe d'Aurillac, de
    # Falaise et de Saint-Flour a montré (cartes/a_inscrire_en_base.md, n° 97,
    # 103, 104) : Falaise-Nord et -Sud rétablis de 1815 à 1941, les quatre
    # cantons d'Aurillac de 1973 à 1985, les fractions en continu. APRÈS `107`
    # (il corrige des appartenances que `107` pose) et AVANT `98` (qui juge les
    # villes sur les appartenances de leurs fractions).
    etape "108 — Aurillac, Falaise, Saint-Flour : cantons corrigés par la découpe"
    $PSQL -P pager=off -1 -v appliquer=1 \
          -f "$ICI/108_villes_aurillac_falaise_saintflour.sql" > "$RACINE/build/p108.log" 2>&1 \
        || { echo "  108 refusé — voir build/p108.log" >&2; exit 1; }

    # Ajouté le 10 octobre 2026. `109` inscrit l'entrée n° 77 de
    # cartes/a_inscrire_en_base.md : Angoulême en deux fractions de 1941 à
    # 1982 (l'atome entier quitte Angoulême-2 en 1968-1973), noms de 1973 et
    # de 1982. Même place que `108` : après `107`, avant `98`.
    etape "109 — Angoulême : deux fractions de 1941 à 1982"
    $PSQL -P pager=off -1 -v appliquer=1 \
          -f "$ICI/109_ville_angouleme.sql" > "$RACINE/build/p109.log" 2>&1 \
        || { echo "  109 refusé — voir build/p109.log" >&2; exit 1; }

    # Ajouté le 11 octobre 2026. `112` inscrit un premier lot de 25 entrées de
    # cartes/a_inscrire_en_base.md : les villes dont les fractions existent
    # mais commencent à la date du COG (1982 à 1998) au lieu de celle du
    # décret. Ne crée ni unité ni atome. Même place que `108` et `109`.
    etape "112 — villes : la date du décret à la place de celle du COG"
    $PSQL -P pager=off -1 -v appliquer=1 \
          -f "$ICI/112_villes_date_du_decret.sql" > "$RACINE/build/p112.log" 2>&1 \
        || { echo "  112 refusé — voir build/p112.log" >&2; exit 1; }

    # Ajouté le 13 octobre 2026. `114` inscrit le deuxième lot (38 entrées) :
    # fractions oubliées ou rangées sous un autre canton, trous comblés,
    # Rennes 1815-1941, Aubagne au 2004-03-21. Ne crée ni unité ni atome.
    # Après `112` (Lamécourt, Sedan-Est), avant `98`.
    etape "114 — villes : deuxième lot de a_inscrire_en_base.md"
    $PSQL -P pager=off -1 -v appliquer=1 \
          -f "$ICI/114_villes_lot_2.sql" > "$RACINE/build/p114.log" 2>&1 \
        || { echo "  114 refusé — voir build/p114.log" >&2; exit 1; }

    # Ajouté le 13 octobre 2026. `115` inscrit les régimes de 1973 que l'on
    # croyait sans unité (Antibes, Cannes, Manosque, Chambéry, Bourg, Gap,
    # Sarcelles, Montluçon-Nord, Caen-Nord) sous l'unité du régime suivant.
    etape "115 — villes : les régimes portés par l'unité suivante"
    $PSQL -P pager=off -1 -v appliquer=1 \
          -f "$ICI/115_villes_nomenclature.sql" > "$RACINE/build/p115.log" 2>&1 \
        || { echo "  115 refusé — voir build/p115.log" >&2; exit 1; }

    # Ajouté le 13 octobre 2026. `116` couvre le trou de 1941 pour les
    # fractions de 61 villes (même régime en 1940 et à la reprise, ou fin de
    # régime connue), et Moulins de 1941 à 1985.
    etape "116 — villes : les fractions de 1941 à la reprise de leur régime"
    $PSQL -P pager=off -1 -v appliquer=1 \
          -f "$ICI/116_villes_couverture_1941.sql" > "$RACINE/build/p116.log" 2>&1 \
        || { echo "  116 refusé — voir build/p116.log" >&2; exit 1; }

    # Ajouté le 13 octobre 2026. `117` crée ce que 114 à 116 ne pouvaient pas :
    # la fraction de Caen-V (1973), les unités C17-Rochefort (avant 1852) et
    # C01-Bourg-Couronne (1982-1985), et passe les fractions de La Rochelle de
    # l'atome de Laleu à celui de La Rochelle.
    etape "117 — créations : Caen-V, Rochefort, Bourg-Couronne ; La Rochelle"
    $PSQL -P pager=off -1 -v appliquer=1 \
          -f "$ICI/117_creations_caen_rochefort_bourg_larochelle.sql" > "$RACINE/build/p117.log" 2>&1 \
        || { echo "  117 refusé — voir build/p117.log" >&2; exit 1; }

    # --- les villes multicantonales -----------------------------------------
    # Cinquième prérequis hors chaîne, découvert le 23 septembre 2026 :
    # `iris_ville` — 4 219 IRIS, la trame d'accrochage des 119 villes à
    # découper — était chargée par `cartes/recupere_iris.py` et par rien
    # d'autre. `rebuild.sh` l'avait emportée, `RESTE_A_FAIRE.md` § 2 la
    # déclarait toujours « acquise et en base », et elle n'a pas de table de
    # trace : RIEN ne pouvait signaler son absence. Rechargée depuis le
    # GeoJSON du 14 août, sans retoucher au WFS de l'IGN.
    IRIS_JSON="$RACINE/cartes/sorties/iris_villes.geojson"
    if [ -f "$IRIS_JSON" ]; then
        etape "iris_ville — trame d'accrochage des 119 villes (prérequis de 98)"
        python3 - "$IRIS_JSON" <<'PY'
import importlib.util, json, sys
s = importlib.util.spec_from_file_location("ri", "cartes/recupere_iris.py")
ri = importlib.util.module_from_spec(s); s.loader.exec_module(ri)
ri.charger(json.loads(open(sys.argv[1]).read())["features"])
PY

        # `101` AVANT `98` : il pose les fractions de quartier de Paris, que
        # les ancres de `98` référencent (3 octobre 2026).
        if [ -f "$ICI/101_paris_fractions_quartier.sql" ]; then
            etape "101 — Paris : les fractions de quartier (prérequis de 98)"
            $PSQL -1 -v appliquer=1 -f "$ICI/101_paris_fractions_quartier.sql"
        fi

        etape "98 — les villes multicantonales, découpées par leurs lignes"
        $PSQL -1 -v appliquer=1 -f "$ICI/98_coupe_ville.sql"
    else
        echo "  iris_ville NON rechargée : $IRIS_JSON absent."
        echo "  python3 cartes/recupere_iris.py --charger  (retélécharge)"
    fi

    # --- la carte -----------------------------------------------------------
    # `84` NE MODIFIE RIEN : que des fonctions, une trace et une procédure.
    # Il est ici parce que `cartes/export_web.py --partition` les appelle, et
    # qu'un DROP SCHEMA les emporte comme le reste.
    etape "84 — la trame de partition (fonctions ; ne modifie aucune donnée)"
    $PSQL -f "$ICI/84_carte_partition.sql"

    # `99` REMPLACE `carte_partition_atome` et `carte_partition` de `84` par des
    # versions qui découpent les villes à lignes (98). Il doit suivre `84` :
    # `84` rejoué seul remet ses fonctions et la carte redevient hachurée.
    if [ -f "$ICI/99_partition_coupes.sql" ]; then
        etape "99 — les villes découpées entrent dans la partition (fonctions)"
        $PSQL -1 -f "$ICI/99_partition_coupes.sql"
    fi

    # `118` et `119` ICI, après `84` et `99`, et non dans le bloc de la Seine :
    # leur recette (§ 5) appelle `carte_partition_atome` / `carte_partition`,
    # que `84` définit. Ajoutés le 18 octobre et joués à la main après tout le
    # reste, ils n'avaient jamais tourné dans la chaîne ; au rebuild du
    # 19 octobre 2026, `118` y tombait sur « function carte_partition_atome
    # does not exist ». `119` reste après `103`, qu'il suppose joué.
    # `103` ICI aussi, après `101_paris_fractions_quartier` : il pose le
    # canton des fractions de quartier de 1986 (`PQ22#86N`…), que ce `101`-là
    # crée. Joué plus haut, il en posait 305 au lieu de 329 (rebuild du
    # 19 octobre 2026) ; le 3 octobre il avait été joué à la main après lui.
    etape "103 — les cantons de Paris 1941-1998, par les deux bouts"
    $PSQL -1 -v appliquer=1 -f "$ICI/103_paris_cantons_1941_1998.sql"

    # Ajouté le 18 octobre 2026. `118` prolonge `102` jusqu'aux décrets
    # d'annexion des bois : Boulogne le 3 avril 1925, Neuilly et les sept
    # communes du bois de Vincennes le 18 avril 1929. Il recoupe les fenêtres
    # [1863,…) que `102` pose : à jouer APRÈS lui, et à défaire
    # (`-v defaire=1`) avant tout rejeu isolé de `102`.
    etape "118 — les bois de Boulogne et de Vincennes hors de Paris jusqu'en 1925-1929"
    $PSQL -P pager=off -1 -v appliquer=1 \
          -f "$ICI/118_paris_bois_1925_1929.sql" > "$RACINE/build/p118.log" 2>&1 \
        || { echo "  118 refusé — voir build/p118.log" >&2; exit 1; }

    # Ajouté le 18 octobre 2026. `119` étend la règle de `103` à 1876-1940 :
    # quand les quartiers portent la circonscription, ils portent aussi le
    # canton de leur arrondissement, et l'arrondissement ne le garde qu'au
    # scrutin de liste (1870-1876, 1885-1889). Sans lui, le treillis de `84`
    # donne toutes les faces aux quartiers et les vingt cantons parisiens
    # disparaissent de la carte. APRÈS `103`, qui lit le canton des
    # arrondissements au 1940-06-01 ; défaire `119` (`-v defaire=1`) avant
    # tout rejeu isolé de `103`.
    etape "119 — les cantons de Paris 1876-1940 portés par les quartiers"
    $PSQL -P pager=off -1 -v appliquer=1 \
          -f "$ICI/119_paris_cantons_1870_1940.sql" > "$RACINE/build/p119.log" 2>&1 \
        || { echo "  119 refusé — voir build/p119.log" >&2; exit 1; }

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
# LES JO LUS, ET LEURS TABLES ANNUELLES — ajouté le 11 octobre 2026
# ============================================================================
# `110` pose dans les TROUS ce que disent les JO lus à la main
# (`cantons/transferts_complement.csv` : 13 transferts ;
# `composition_complement.csv` : 73 cantons recomposés, 1949-1968 ;
# `corse_1975.csv` : la Corse de la loi 75-356) et les tables analytiques
# annuelles du JO (`transferts_tables_jo.csv` : 93 transferts isolés datés).
# `111` corrige les périodes que ces transferts DÉMENTENT : une commune gardée
# dans son canton de départ après l'acte, ou mise dans son canton d'arrivée
# avant lui.
#
# Ils viennent APRÈS TOUT LE RESTE, et c'est un ordre imposé :
#   * `110` ne remplit que les trous laissés par les reports (`79`, `81`, `93`,
#     `95`, `97`) et par `103` à `109`. Joué avant eux, il prendrait des places
#     qui leur reviennent, et ce n'est pas l'état dans lequel il a été jugé ;
#   * `111` MODIFIE des périodes que d'autres ont posées — `79`, `81`, la base
#     d'origine. Il doit passer après eux, sans quoi ils les reposeraient par
#     dessus ses corrections ou buteraient sur elles.
# Hors du bloc ANR : ni l'un ni l'autre ne lit `atom_geom_anr`.
#
# PAS DE `-1` : chacun ouvre et ferme sa propre transaction (BEGIN, puis
# COMMIT avec `-v poser=on`, ROLLBACK sans). Une transaction englobante n'y
# ajouterait rien qu'un avertissement.
#
# Rejouer `110` SEUL, hors de cette chaîne : défaire `111` d'abord
# (`-v defaire=on`), puis `110`, puis `111` — voir `sql/README.md`, « Qui
# dépend de qui », § 3.
etape "110 — les JO lus et leurs tables, posés dans les trous (règle C)"
$PSQL -P pager=off -v poser=on \
      -f "$ICI/110_pose_lecture_jo.sql" > "$RACINE/build/p110.log" 2>&1 \
    || { echo "  110 refusé — voir build/p110.log" >&2; exit 1; }

etape "111 — les périodes que ces transferts démentent, corrigées"
$PSQL -P pager=off -v poser=on \
      -f "$ICI/111_corrige_transferts.sql" > "$RACINE/build/p111.log" 2>&1 \
    || { echo "  111 refusé — voir build/p111.log" >&2; exit 1; }

# Ajouté le 19 octobre 2026. `120` comble les trous que `93`, `95` et `97` ne
# voyaient pas : ceux qui TRAVERSENT 1968, faute de bout au jalon (Belley), par
# l'accord des deux bouts ; et les désaccords qu'un seul acte lu explique en
# ouvrant le bout droit (Civrieux, décret n° 84-1222), par le chaînage —
# `chainage_large` décidé par Adrien le 19 octobre 2026. Il lit les trous que
# laissent `110` et `111` : il passe après eux, et avant `113`, qui lit les
# cantons de 1958. Depuis la racine : ses \copy lisent `cantons/`.
etape "120 — trous par-delà 1968, et chaînage par l'acte"
( cd "$RACINE" && $PSQL -P pager=off -v poser=on -v chainage_large=on \
      -f "$ICI/120_trous_par_dela_1968.sql" > "$RACINE/build/p120.log" 2>&1 ) \
    || { echo "  120 refusé — voir build/p120.log" >&2; exit 1; }

# Ajouté le 13 octobre 2026. `113` pose les circonscriptions de 1958-1986 des
# 68 départements « posables » de `circo/composition_1958_etat.csv`, par le
# canton que chaque atome a au 1er décembre 1958. Il LIT les cantons : il passe
# donc après tout ce qui en pose ou en corrige (`93`, `97`, `110`, `111`), et
# `circo/composition_1958.py` doit être rejoué AVANT lui si la trame cantonale
# de 1958 a changé (il écrit les identifiants d'unité dans le CSV ; `113`
# refuse, recette 1 bis, si l'un d'eux a disparu ou changé de nom).
etape "113 — circonscriptions 1958-1986 (cartes de Gaudillère)"
( cd "$RACINE" && $PSQL -P pager=off -1 -v appliquer=1 \
      -f "$ICI/113_circo_1958.sql" > "$RACINE/build/p113.log" 2>&1 ) \
    || { echo "  113 refusé — voir build/p113.log" >&2; exit 1; }

# Ajouté le 21 octobre 2026. `121` corrige à la main l'Ain : la cession au
# Rhône de 1967, le jalon de 1968 mal apparié, les communes absorbées, le trou
# 1973-1998. Il retire des périodes de `59` et de `113` : il passe après tout.
etape "121 — Ain : cessions au Rhône et trous 1955-1998"
( cd "$RACINE" && $PSQL -P pager=off -v poser=on \
      -f "$ICI/121_ain_cessions_trous.sql" > "$RACINE/build/p121.log" 2>&1 ) \
    || { echo "  121 refusé — voir build/p121.log" >&2; exit 1; }

# Ajouté le 21 octobre 2026. `122` pose le scrutin de liste départemental de
# 1945-1958 (une unité `L<dep>01@1945` par département hors de la Seine) sur
# tout atome qui a un canton du département dans la fenêtre. Il LIT les
# cantons, y compris ceux que `121` pose dès 1955 dans l'Ain : il passe après
# lui. Rejouer `121` seul (défaire, poser) demande de rejouer `122` ensuite.
etape "122 — circonscriptions 1945-1958 : scrutin de liste départemental"
$PSQL -P pager=off -1 -v appliquer=1 \
      -f "$ICI/122_circo_1945_1958.sql" > "$RACINE/build/p122.log" 2>&1 \
    || { echo "  122 refusé — voir build/p122.log" >&2; exit 1; }

# Ajouté le 21 octobre 2026. `123` lit `circo/partition_ville.csv` : la
# circonscription de chaque canton d'une ville partagée. 1876-1940 : il la pose
# sur les fractions et retire l'atome-mère des unités fusionnées (« Moulins
# (1-2) ») ; après 1958 il comble les fractions nées sous un canton neuf. Il
# passe APRÈS `113`, dont il lit les unités de 1958. Depuis la racine : \copy.
etape "123 — villes partagées entre plusieurs circonscriptions"
( cd "$RACINE" && $PSQL -P pager=off -1 -v appliquer=1 \
      -f "$ICI/123_circo_villes_partagees.sql" > "$RACINE/build/p123.log" 2>&1 ) \
    || { echo "  123 refusé — voir build/p123.log" >&2; exit 1; }

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
