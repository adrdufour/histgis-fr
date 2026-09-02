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
# ============================================================================
set -euo pipefail

ICI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RACINE="${1:-$(dirname "$ICI")}"
PSQL="psql -v ON_ERROR_STOP=1 -q -d histgis"

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

# 22 charge les millésimes du COG, 37 crée `noms_geofla`, 23 diagnostique.
etape "COG 1999-2012 (22, 36, 37, 23)"
"$ICI/load_cog.sh" "$RACINE"

etape "24 — cantons 1999-2012"
$PSQL -f "$ICI/24_canton_moderne.sql"

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

etape "32 — géométrie des cantons de Marseille"
$PSQL -f "$ICI/32_marseille_geom.sql"

etape "40 — outre-mer"
$PSQL -v circo_om="$RACINE/circo/circo_outremer_1986_2012.csv" \
      -f "$ICI/40_outremer.sql"

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

etape "39 — la Meurthe reprend son numéro"
$PSQL -f "$ICI/39_meurthe_1870.sql"

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
etape "47 — circo de la mère, quand les voisins se taisent"
$PSQL -f "$ICI/47_circo_mere.sql"

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

Puis, pour la carte :

    python3 cartes/export_web.py
FIN
