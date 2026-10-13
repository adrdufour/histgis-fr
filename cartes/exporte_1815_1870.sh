#!/usr/bin/env bash
# ============================================================================
# exporte_1815_1870.sh — porter sur la carte web les circonscriptions 1815-1870
#                        posées par `106` (et `105` pour l'Yonne), et les
#                        cantons 1815-1870 posés par `107`
#
#     conda activate histgis
#     bash cartes/exporte_1815_1870.sh                 # 1-2 : copie + export
#     bash cartes/exporte_1815_1870.sh --reprendre     # après un incident
#     bash cartes/exporte_1815_1870.sh --promouvoir    # 3 : bascule la carte servie
#     python3 cartes/web/servir.py                     # et la page s'ouvre
#
# CE QU'IL FAIT
# -------------
# 1. Copie la carte servie (`cartes/web/donnees`) dans `sorties/part_<date>` —
#    une seule fois : relancé, il REPREND dans le même dossier.
# 2. Y réexporte, trame de partition, les seuls départements dont la base a
#    changé : ceux de `106` et de `107`, l'Yonne (`105`) et le 54, où vit la
#    Meurthe d'avant 1871 — 87 depuis le 6 octobre 2026. `export_partition.sh --refaire` les refait même si leur
#    index existe — mais il ne reprend donc pas un lot à moitié fait : en cas
#    d'incident, relancer avec `--reprendre`, qui retire `--refaire` et ne
#    refait que les départements dont l'index est plus ancien que la copie.
#    L'index racine garde les départements non touchés (export partiel).
# 3. Avec `--promouvoir` (et SANS réexporter) : contrôle, puis renomme `cartes/web/donnees` en
#    `sorties/web_<date d'avant>` et le dossier neuf en `cartes/web/donnees`.
#    Rien n'est effacé — c'est la promotion du 23 septembre 2026.
#
# Durée : environ 2 h 30 pour 87 départements en lots de 4 sur 2 processus
# (la passe nationale du 23 septembre a pris 2 h 44 pour 97).
# ============================================================================
set -uo pipefail

RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$RACINE"

SORTIE=""
SERVIE="cartes/web/donnees"
PROMOUVOIR=""
REPRENDRE=""
for a in "$@"; do
    case "$a" in
        --promouvoir) PROMOUVOIR=1 ;;
        --reprendre)  REPRENDRE=1 ;;
        --sortie=*)   SORTIE="${a#--sortie=}" ;;
        -h|--help)    sed -n '2,30p' "${BASH_SOURCE[0]}"; exit 0 ;;
        *) echo "option inconnue : $a" >&2; exit 2 ;;
    esac
done

# Le dossier de travail : celui donné, sinon le dernier `part_*_1815`
# existant (reprise, promotion un autre jour), sinon un neuf daté d'aujourd'hui.
if [[ -z "$SORTIE" ]]; then
    SORTIE="$(ls -d sorties/part_*_1815 2>/dev/null | sort | tail -1)"
    if [[ -z "$SORTIE" || ( -z "$REPRENDRE" && -z "$PROMOUVOIR" ) ]]; then
        [[ -n "$SORTIE" && -z "$REPRENDRE" && -z "$PROMOUVOIR" ]] && \
            echo "  (un dossier $SORTIE existe déjà ; on repart d'un neuf daté d'aujourd'hui)"
        SORTIE="sorties/part_$(date +%F)_1815"
    fi
fi
echo "Dossier de travail : $SORTIE"

# 6 octobre 2026 : étendu à tous les départements qu'ont touchés `106`
# (seconde série : 01-20, 64-73, 83) et `107` (cantons 1815-1870, dont
# l'Aveyron, qui n'a que des cantons). Sans 75 ni 57.
DEPS=(01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20
      21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40
      41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 58 59 60 61 62 63
      64 65 66 67 68 69 70 71 72 73 74 76 77 78 79 80 81 82 83 84 85 86
      87 88 89)

# --- 1. la copie ------------------------------------------------------------
if [[ ! -d "$SORTIE" && -z "$PROMOUVOIR" ]]; then
    [[ -f "$SERVIE/index.json" ]] || { echo "ARRÊT : $SERVIE/index.json absent." >&2; exit 1; }
    echo "=== copie de $SERVIE vers $SORTIE (quelques minutes, ~3,5 Go) ==="
    cp -a "$SERVIE" "$SORTIE" || exit 1
    touch "$SORTIE/.copie_faite"
fi

# --- 2. l'export ------------------------------------------------------------
A_FAIRE=("${DEPS[@]}")
OPT=(--refaire)
if [[ -n "$REPRENDRE" ]]; then
    # Ne refaire que les départements dont l'index n'a pas été réécrit depuis
    # la copie : les autres sont déjà passés.
    A_FAIRE=()
    for d in "${DEPS[@]}"; do
        f="$SORTIE/dep/$d/index.json"
        if [[ ! -f "$f" || "$f" -ot "$SORTIE/.copie_faite" ]]; then
            A_FAIRE+=("$d")
        fi
    done
    echo "=== reprise : ${#A_FAIRE[@]} département(s) restent à refaire ==="
    [[ ${#A_FAIRE[@]} -eq 0 ]] && echo "Rien à refaire."
fi

if [[ -n "$PROMOUVOIR" ]]; then
    [[ -d "$SORTIE" ]] || { echo "ARRÊT : $SORTIE absent, rien à promouvoir." >&2; exit 1; }
    A_FAIRE=()          # la promotion ne réexporte jamais
fi

if [[ ${#A_FAIRE[@]} -gt 0 ]]; then
    # --refaire vaut pour TOUS les départements passés en argument ; en
    # reprise, ce sont précisément ceux qui restent.
    bash cartes/export_partition.sh "${OPT[@]}" --sortie "$SORTIE" "${A_FAIRE[@]}" \
        || { echo ""; echo "Export incomplet : relancer avec --reprendre." >&2; exit 1; }
fi

# --- contrôle : chaque département refait sert-il désormais 1815-1869 ? -----
echo ""
echo "=== années servies avant 1870, par département ==="
python3 - "$SORTIE" "${DEPS[@]}" <<'PY'
import json, sys, pathlib
sortie = pathlib.Path(sys.argv[1])
manque = []
for d in sys.argv[2:]:
    f = sortie / "dep" / d / "index.json"
    if not f.exists():
        manque.append(d); continue
    idx = json.loads(f.read_text(encoding="utf-8"))
    an = idx.get("annees", {})
    av = sorted(int(a) for a, v in an.items() if int(a) < 1870 and v.get("x"))
    ac = sorted(int(a) for a, v in an.items() if int(a) < 1870 and v.get("c"))
    print(f"  {d}  circo {len(av):>3} années"
          + (f" ({av[0]}-{av[-1]})" if av else " — AUCUNE")
          + f"   canton {len(ac):>3} années"
          + (f" ({ac[0]}-{ac[-1]})" if ac else " — AUCUNE"))
if manque:
    print("  index absent :", " ".join(manque))
PY

# --- 3. la promotion --------------------------------------------------------
if [[ -n "$PROMOUVOIR" ]]; then
    ANCIEN="sorties/web_$(date -r "$SERVIE/index.json" +%F)"
    [[ -e "$ANCIEN" ]] && ANCIEN="${ANCIEN}_$(date +%H%M)"
    echo ""
    echo "=== promotion : $SERVIE -> $ANCIEN ; $SORTIE -> $SERVIE ==="
    mv "$SERVIE" "$ANCIEN" && mv "$SORTIE" "$SERVIE" || exit 1
    rm -f "$SERVIE/.copie_faite"
    echo "Carte servie remplacée. L'ancienne est dans $ANCIEN."
    echo "    python3 cartes/web/servir.py"
else
    echo ""
    echo "Export dans $SORTIE. Si le contrôle ci-dessus est bon :"
    echo "    bash cartes/exporte_1815_1870.sh --promouvoir --sortie=$SORTIE"
fi
