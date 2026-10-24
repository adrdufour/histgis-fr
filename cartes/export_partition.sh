#!/usr/bin/env bash
# ============================================================================
# export_partition.sh — la passe nationale de `--partition`, par lots, reprenable
#
#     bash cartes/export_partition.sh                      # tout ce qui manque
#     bash cartes/export_partition.sh --jobs 6              # six de front
#     bash cartes/export_partition.sh --lot 4 --jobs 2      # l'ancien réglage
#     bash cartes/export_partition.sh 52 04 12             # une sélection
#     bash cartes/export_partition.sh --refaire            # tout refaire, reprenable
#
# POURQUOI CE SCRIPT EXISTE
# -------------------------
# `export_web.py --partition` sur les 98 départements demande deux à trois
# heures d'un seul tenant. Le 3 septembre 2026, deux tentatives ont été
# interrompues au bout d'une dizaine de minutes : l'OOM killer du noyau abattait
# un backend PostgreSQL, et le cluster entier avec lui. Un processus long qui
# dépend d'un service qu'il ne contrôle pas n'a pas besoin d'être rendu
# increvable : il a besoin d'être REPRENABLE.
#
# (Le journal de PostgreSQL, lui, n'écrit que « received fast shutdown
# request » : c'est systemd qui arrête proprement l'unité APRÈS que le noyau a
# tué un de ses processus. Lu seul, ce message fait croire à un arrêt demandé —
# il m'a égaré deux fois. La cause ne se lit que dans `journalctl -k`.)
#
# D'où trois propriétés, et rien de plus :
#
#   * il travaille par LOTS — un lot perdu coûte quelques minutes, pas la nuit ;
#   * il REPREND — un département déjà écrit dans la sortie n'est pas refait,
#     donc relancer le script après un incident reprend là où il en était ;
#   * il ATTEND le serveur — si PostgreSQL est reparti, il le laisse revenir
#     avant de continuer, au lieu d'enchaîner 90 échecs en trois secondes.
#
# LES DÉFAUTS PAR DÉFAUT SONT PRUDENTS, ET MESURÉS. Le 3 septembre 2026, un
# backend PostgreSQL a atteint **12,7 Go** en traitant une vingtaine de
# départements à la suite sur la même connexion, et l'OOM killer du noyau a
# abattu le cluster. `export_web.py` rouvre désormais sa connexion après chaque
# département, ce qui rend la mémoire au système ; mais un département reste
# coûteux à lui seul, et deux processus valent mieux que huit sur une machine
# de 30 Go où tourne aussi un navigateur.
#
# PLUS DE DEUX PROCESSUS — 21 octobre 2026. Deux processus et des lots de
# quatre, c'était huit heures vingt pour la France (18-19 octobre). Deux
# changements, et une sécurité :
#
#   * `--jobs` se règle par défaut sur la MÉMOIRE DISPONIBLE et non plus sur
#     une constante : un processus par tranche de GO_PAR_JOB Go libres (3 ;
#     mesuré le 21 octobre 2026 à six de front sur l'Ain et cinq voisins :
#     0,7 Go au plus par backend, jamais moins de 20 Go libres, ×4,5),
#     plafonné à la moitié des cœurs. C'est la mémoire qui a tué le cluster le
#     3 septembre, pas les cœurs ;
#   * un lot vaut par défaut TROIS fois `--jobs`. Chaque lot attend son
#     département le plus lent avant de passer au suivant : avec des lots de
#     la taille du pool, la moitié des processus attendaient l'Aisne les bras
#     croisés. Plus le lot est grand, moins cette attente pèse — mais plus un
#     lot perdu coûte ;
#   * un lot qui échoue sur la CONNEXION (le serveur a coupé : OOM, le plus
#     souvent) divise `--jobs` par deux pour la suite de la nuit, au lieu de
#     reproduire la même panne lot après lot.
#
# Il ne remplace pas `export_web.py`, il l'appelle. Toute la logique d'export
# reste là-bas ; ici il n'y a qu'une boucle et de la patience.
#
# CE QU'IL NE RÉSOUT PAS. L'empreinte d'UN département reste grosse, et la
# cause probable est l'anneau de contexte de `84` : une boîte englobante élargie
# de 20 km, qui sur un département comme l'Aisne ratisse une bonne part de la
# Picardie pour une centaine de communes limitrophes utiles. La remplacer par un
# test de voisinage indexé diviserait le treillis, et avec lui la mémoire.
# C'est en tête de `RESTE_A_FAIRE.md`, et cela se vérifie contre un oracle
# connu : Ain 0,000 km² et 5 replis, Haute-Marne 10, Basses-Alpes 12.
# ============================================================================
set -uo pipefail

RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$RACINE"

SORTIE="sorties/part"
LOT=""
JOBS=""
GO_PAR_JOB="${GO_PAR_JOB:-3}"   # Go de mémoire disponible par processus
ROLE="histgis_carte"
BASE="histgis"
PYTHON="${PYTHON:-python3}"
DEPS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --lot)    LOT="$2";    shift 2 ;;
        --jobs)   JOBS="$2";   shift 2 ;;
        --sortie) SORTIE="$2"; shift 2 ;;
        --role)   ROLE="$2";   shift 2 ;;
        --refaire) REFAIRE=1;  shift ;;
        -h|--help) sed -n '2,32p' "${BASH_SOURCE[0]}"; exit 0 ;;
        *)        DEPS+=("$1"); shift ;;
    esac
done

JOURNAL="$SORTIE/../part_lots.log"
mkdir -p "$SORTIE"

# --- combien de front --------------------------------------------------------
# Lu une fois, au départ : le navigateur ouvert ou fermé au moment de lancer
# compte, et c'est voulu.
if [[ -z "$JOBS" ]]; then
    dispo_go=$(awk '/MemAvailable/ {print int($2 / 1048576)}' /proc/meminfo)
    coeurs=$(nproc)
    JOBS=$(( dispo_go / GO_PAR_JOB ))
    (( JOBS > coeurs / 2 )) && JOBS=$(( coeurs / 2 ))
    (( JOBS < 1 )) && JOBS=1
    echo "  --jobs $JOBS : ${dispo_go} Go disponibles / ${GO_PAR_JOB} Go par" \
         "processus, $coeurs cœurs" | tee -a "$JOURNAL"
fi
[[ -z "$LOT" ]] && LOT=$(( JOBS * 3 ))

# --- l'interpréteur, AVANT la boucle ----------------------------------------
# Le 3 septembre 2026, ce script a lancé 23 lots en deux secondes, chacun mort
# sur `ModuleNotFoundError: No module named 'psycopg2'` — un shell où
# l'environnement conda n'était pas actif. Vingt-trois répétitions de la même
# panne, et le résumé final annonçait « 92 départements manquent encore » sans
# jamais nommer la cause, qui n'était que dans le fichier de journal.
#
# *Ce qui ne peut pas marcher se vérifie une fois, avant la boucle ; ce qui peut
# échouer par intermittence se réessaie dedans.* La base est dans le second cas,
# l'interpréteur dans le premier.
if ! "$PYTHON" -c "import psycopg2" 2>/dev/null; then
    echo "ARRÊT : \`$PYTHON\` n'a pas psycopg2." >&2
    echo "  L'environnement du projet n'est probablement pas actif :" >&2
    echo "      conda activate histgis        # puis relancer" >&2
    echo "  ou désigner l'interpréteur explicitement :" >&2
    echo "      PYTHON=/chemin/vers/python3 bash cartes/export_partition.sh" >&2
    echo "  (les dépendances sont dans environment.yml à la racine)" >&2
    exit 1
fi

# --- attendre que la base réponde -------------------------------------------
# Sans cette attente, un serveur en cours de redémarrage fait échouer le lot
# suivant en une seconde, et le suivant, et le suivant : on transformerait une
# interruption en abandon.
attendre_base() {
    local n=0
    until psql -d "$BASE" -Atc "SELECT 1" >/dev/null 2>&1; do
        n=$((n + 1))
        if [[ $n -eq 1 ]]; then
            echo "  … la base ne répond pas, attente (jusqu'à 10 min)" | tee -a "$JOURNAL"
        fi
        if [[ $n -gt 60 ]]; then
            # Un message qui constate sans dire quoi faire oblige à retrouver
            # la commande ailleurs, et c'est justement le moment où l'on est
            # pressé. Le nom du cluster est lu, pas supposé.
            local unite
            unite="$(systemctl list-units --all --no-legend 'postgresql@*' 2>/dev/null \
                     | awk '{print $1}' | head -1)"
            unite="${unite:-postgresql@14-main.service}"
            echo "  ABANDON : la base n'est pas revenue au bout de 10 minutes." \
                | tee -a "$JOURNAL"
            echo "  Le serveur est probablement arrêté. Après un OOM, systemd" \
                | tee -a "$JOURNAL"
            echo "  marque l'unité en échec et un simple start peut être refusé :" \
                | tee -a "$JOURNAL"
            echo "      sudo systemctl reset-failed $unite" | tee -a "$JOURNAL"
            echo "      sudo systemctl start $unite"        | tee -a "$JOURNAL"
            echo "      journalctl -k --since '-30 min' | grep -i 'out of memory'" \
                | tee -a "$JOURNAL"
            return 1
        fi
        sleep 10
    done
    [[ $n -gt 0 ]] && echo "  … la base est revenue après $((n * 10)) s" | tee -a "$JOURNAL"
    return 0
}

# --- la liste des départements ----------------------------------------------
if [[ ${#DEPS[@]} -eq 0 ]]; then
    attendre_base || exit 1
    mapfile -t DEPS < <(psql -d "$BASE" -Atc \
        "SELECT DISTINCT trim(dep) FROM histgis.unit ORDER BY 1")
fi

# Reprise : un département dont l'index existe déjà est considéré comme fait.
# C'est le fichier écrit EN DERNIER par `exporte_departement`, donc sa présence
# vaut preuve que le département est allé au bout.
#
# `--refaire` EST REPRENABLE LUI AUSSI (21 octobre 2026). Il refaisait tout à
# chaque lancement : une nuit interrompue à 4 h repartait de l'Ain. Le premier
# lancement pose un témoin daté dans la sortie ; un département dont l'index
# est PLUS RÉCENT que le témoin est fait. Le témoin s'efface quand tout est
# fait — relancer la même commande reprend donc là où la nuit s'est arrêtée.
TEMOIN="$SORTIE/.refaire_depuis"
if [[ -n "${REFAIRE:-}" && ! -f "$TEMOIN" ]]; then
    touch "$TEMOIN"
fi
A_FAIRE=()
for d in "${DEPS[@]}"; do
    f="$SORTIE/dep/$d/index.json"
    if [[ -f "$f" ]] && { [[ -z "${REFAIRE:-}" ]] || [[ "$f" -nt "$TEMOIN" ]]; }; then
        continue
    fi
    A_FAIRE+=("$d")
done

echo "=== $(date '+%F %T') — ${#A_FAIRE[@]} département(s) à faire sur ${#DEPS[@]}," \
     "lots de $LOT, $JOBS processus ===" | tee -a "$JOURNAL"

if [[ ${#A_FAIRE[@]} -eq 0 ]]; then
    echo "Rien à faire : tout est déjà dans $SORTIE." | tee -a "$JOURNAL"
    rm -f "$TEMOIN"
    exit 0
fi

# --- la boucle ---------------------------------------------------------------
i=0
perdus=()
sec=0            # lots consécutifs qui n'ont RIEN écrit
while [[ $i -lt ${#A_FAIRE[@]} ]]; do
    lot=("${A_FAIRE[@]:i:LOT}")
    i=$((i + LOT))
    echo "--- $(date '+%T') lot : ${lot[*]}" | tee -a "$JOURNAL"

    if ! attendre_base; then
        perdus+=("${lot[@]}")
        continue
    fi

    if "$PYTHON" cartes/export_web.py "${lot[@]}" \
            --partition --role "$ROLE" --jobs "$JOBS" --sortie "$SORTIE" \
            >> "$JOURNAL" 2>&1; then
        echo "    ok" | tee -a "$JOURNAL"
        sec=0
    else
        # Un lot peut échouer et avoir tout de même écrit une partie de ses
        # départements — c'est le cas quand le serveur tombe au milieu. Un lot
        # qui n'écrit RIEN, en revanche, échoue avant même de travailler.
        ecrits=0
        for d in "${lot[@]}"; do
            f="$SORTIE/dep/$d/index.json"
            if [[ -f "$f" ]] && { [[ -z "${REFAIRE:-}" ]] || [[ "$f" -nt "$TEMOIN" ]]; }; then
                ecrits=$((ecrits + 1))
            fi
        done
        perdus+=("${lot[@]}")
        # Le serveur a coupé : moins de front pour la suite. `export_web.py`
        # l'écrit en toutes lettres quand un échec vient de la connexion.
        if [[ $JOBS -gt 1 ]] && tail -40 "$JOURNAL" | grep -q "vient de la CONNEXION"; then
            JOBS=$(( JOBS / 2 ))
            echo "    connexion perdue : --jobs ramené à $JOBS pour la suite" \
                | tee -a "$JOURNAL"
        fi
        if [[ $ecrits -gt 0 ]]; then
            echo "    échec partiel ($ecrits écrits) — repris au prochain passage" \
                | tee -a "$JOURNAL"
            sec=0
        else
            sec=$((sec + 1))
            echo "    lot en échec, rien écrit ($sec d'affilée)" | tee -a "$JOURNAL"
            # DEUX LOTS DE SUITE SANS RIEN ÉCRIRE : la cause n'est pas
            # passagère. Continuer rejouerait la même panne quatre-vingt-dix
            # fois et enterrerait son message sous le résumé.
            # *Une boucle qui réessaie doit savoir remarquer qu'elle
            # n'avance pas.*
            if [[ $sec -ge 2 ]]; then
                echo "" | tee -a "$JOURNAL"
                echo "ARRÊT : deux lots de suite sans rien écrire — la panne" \
                    "n'est pas passagère." | tee -a "$JOURNAL"
                echo "  Les dernières lignes de $JOURNAL :" | tee -a "$JOURNAL"
                grep -vE "^(---|    |=== )" "$JOURNAL" | tail -15 >&2
                exit 1
            fi
        fi
    fi
done

# --- ce qui manque encore ----------------------------------------------------
manquants=()
for d in "${DEPS[@]}"; do
    f="$SORTIE/dep/$d/index.json"
    if [[ ! -f "$f" ]] || { [[ -n "${REFAIRE:-}" ]] && ! [[ "$f" -nt "$TEMOIN" ]]; }; then
        manquants+=("$d")
    fi
done

echo "=== $(date '+%F %T') — terminé ===" | tee -a "$JOURNAL"
if [[ ${#manquants[@]} -eq 0 ]]; then
    echo "Les ${#DEPS[@]} départements sont dans $SORTIE." | tee -a "$JOURNAL"
    rm -f "$TEMOIN"
    exit 0
fi
echo "${#manquants[@]} département(s) manquent encore :" | tee -a "$JOURNAL"
echo "  ${manquants[*]}" | tee -a "$JOURNAL"
echo "Relancer la MÊME commande : elle ne refera que ceux-là." | tee -a "$JOURNAL"
exit 1
