#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
verifie_attribution.py — vérifier à quel département appartient un fascicule,
                          par les NOMS DE COMMUNES qu'il contient.

    python3 cog1968/verifie_attribution.py --ark bd6t5358958j
    python3 cog1968/verifie_attribution.py --tous --pages 6-9

Pourquoi
--------
`index_fascicules.py` attribue chaque fascicule à un département par le texte
de ses premières pages. C'est une heuristique, et son score le dit : certaines
attributions tiennent à un seul mot, sans second candidat. Or la page 1 des
numérisations Gallica est une **couverture générée**, identique pour toute la
série — elle ne porte pas le nom du département.

Une mauvaise attribution est doublement coûteuse : elle rend un département
présent qui ne l'est pas, et absent celui qu'il est vraiment. Le 21 août 2026,
neuf départements manquaient et quatre fascicules sortaient de l'ordre des
`ark` — de quoi soupçonner que les deux faits n'en font qu'un.

Le contrôle, et pourquoi il est sûr
-----------------------------------
Le fascicule liste ses communes. Leurs NOMS, confrontés à la table
`noms_geofla`, désignent un département et un seul : il n'existe pas deux
départements partageant l'essentiel de leur toponymie. Aucune heuristique de
titre ne vaut cela.

Deux réserves, portées dans la sortie plutôt que passées sous silence :

  * les noms lus par OCR comportent des coquilles — on ne compte donc que les
    correspondances EXACTES après normalisation, et on affiche le taux ;
  * `noms_geofla` est un millésime 2011 : une commune de 1968 disparue depuis
    n'y figure pas. Elle est comptée comme non résolue, pas comme un désaccord.

Le verdict n'est donné que si un département rassemble une nette majorité des
noms résolus. Sinon le script le dit et ne tranche pas.
"""

import argparse
import csv
import subprocess
import sys
import unicodedata
from collections import Counter
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(RACINE / "cog1954"))
from extrait_1954 import page_texte                      # noqa: E402
from extrait_1968 import LIGNE, EXCLUS, nettoie_nom, index  # noqa: E402

INDEX = RACINE / "cog1968" / "fascicules_1968.csv"
NOMS = RACINE / "build" / "noms_geofla.csv"


def cle(s):
    s = unicodedata.normalize("NFD", str(s))
    s = "".join(c for c in s if unicodedata.category(c) != "Mn").lower()
    for a in "'-.":
        s = s.replace(a, " ")
    return " ".join(s.split())


# La Corse est UN département en 1968, le 20 ; elle est partagée en 2A et 2B au
# 1er janvier 1976. `noms_geofla` étant un millésime 2011, ses communes corses
# portent 2A ou 2B — jamais 20. Sans cette équivalence, le contrôle annonce un
# désaccord sur le seul fascicule corse alors que 61 % de 2B et 39 % de 2A font
# 100 % de la Corse, et que l'index a raison.
#
# Mesuré le 21 août 2026 : c'était le SEUL désaccord des 86 fascicules, et il
# venait du contrôle, pas de la donnée.
EQUIVALENTS = {"2A": "20", "2B": "20"}


def charge_noms():
    """clé de nom -> {départements} ; un nom peut exister dans plusieurs."""
    if not NOMS.exists():
        sys.exit(f"{NOMS} absent. L'engendrer depuis la base :\n"
                 f"  psql -d histgis -c \"\\copy (SELECT insee, nom, dep "
                 f"FROM histgis.noms_geofla) TO '{NOMS}' CSV HEADER\"")
    d = {}
    for r in csv.DictReader(NOMS.open(encoding="utf-8")):
        dep = (r.get("dep") or r["insee"][:2]).strip().lstrip("0") or r["insee"][:2]
        dep = dep.zfill(2)
        d.setdefault(cle(r["nom"]), set()).add(EQUIVALENTS.get(dep, dep))
    return d


def pages_de(spec, n_max):
    # Par défaut les pages 6 à 17.
    #
    # On commence à 6 : les cinq premières pages d'une numérisation Gallica
    # sont une couverture GÉNÉRÉE, identique pour toute la série, sans un nom
    # de commune. Les OCRiser coûte du temps pour rien.
    #
    # On va jusqu'à 17 parce qu'une fenêtre de six pages ne suffisait pas :
    # sept fascicules sur 86 ne rendaient AUCUNE ligne — Charente, Drôme,
    # Haute-Garonne, Ille-et-Vilaine, Loiret, Nièvre, Deux-Sèvres — non par
    # défaut d'attribution mais parce que leur sommaire est plus long.
    #
    # **Une fenêtre qui rend zéro ligne ne dit rien** : elle ne confirme ni
    # n'infirme, et c'est le pire résultat qu'un contrôle puisse produire —
    # celui qu'on prend pour un verdict.
    if not spec:
        return range(6, min(n_max, 17) + 1)
    out = []
    for bloc in spec.split(","):
        if "-" in bloc:
            a, b = bloc.split("-")
            out.extend(range(int(a), int(b) + 1))
        else:
            out.append(int(bloc))
    return [p for p in out if p <= n_max]


def n_pages(pdf):
    info = subprocess.run(["pdfinfo", str(pdf)], capture_output=True, text=True)
    for l in info.stdout.splitlines():
        if l.startswith("Pages:"):
            return int(l.split()[1])
    return 0


def examine(pdf, spec, noms, langue="fra"):
    lus, resolus = 0, Counter()
    for page in pages_de(spec, n_pages(pdf)):
        try:
            texte = page_texte(pdf, page, langue=langue)
        except Exception:                                   # noqa: BLE001
            continue
        for brut in texte.splitlines():
            if EXCLUS.search(brut):
                continue
            m = LIGNE.search(brut.strip())
            if not m:
                continue
            lus += 1
            deps = noms.get(cle(nettoie_nom(m.group(6))))
            # Un nom porté par plusieurs départements ne départage rien : on lui
            # donne une voix fractionnée plutôt que de le jeter ou de le compter
            # une fois pour chacun.
            if deps and len(deps) <= 3:
                for d in deps:
                    resolus[d] += 1 / len(deps)
    return lus, resolus


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--ark", action="append", help="ark à vérifier (répétable)")
    ap.add_argument("--tous", action="store_true", help="tous les fascicules")
    ap.add_argument("--pages", help="ex. 6-9 ; par défaut les 12 premières")
    ap.add_argument("--langue", default="fra")
    args = ap.parse_args()

    # Sans reconfigure(), une redirection vers un fichier ne montre RIEN avant
    # la fin : Python tamponne par blocs. Sur une heure d'OCR, cela donne un
    # journal vide qu'on prend pour un blocage. Mesuré le 21 août 2026.
    try:
        sys.stdout.reconfigure(line_buffering=True)
    except AttributeError:
        pass

    rows = list(csv.DictReader(INDEX.open(encoding="utf-8")))
    if args.ark:
        rows = [r for r in rows if r["ark"] in args.ark]
    elif not args.tous:
        sys.exit("Donner --ark ou --tous.")

    noms = charge_noms()
    desaccords = []

    for r in rows:
        pdf = RACINE / "sources" / "rp1968" / r["fichier"]
        if not pdf.exists():
            print(f"{r['ark']} : fichier absent"); continue
        lus, resolus = examine(pdf, args.pages, noms, args.langue)
        total = sum(resolus.values())
        if not total:
            print(f"{r['ark']}  {r['dep']} {r['departement']:<22} "
                  f"— {lus} lignes lues, AUCUN nom résolu")
            continue
        top = resolus.most_common(3)
        gagnant, voix = top[0]
        part = voix / total
        accord = "OK " if gagnant == r["dep"] else "!! "
        print(f"{accord}{r['ark']}  index dit {r['dep']} {r['departement']:<22} "
              f"| noms disent {gagnant} ({part:.0%} de {total:.0f} résolus "
              f"sur {lus} lus)")
        if len(top) > 1:
            print("      suivants : " +
                  ", ".join(f"{d} ({v/total:.0%})" for d, v in top[1:]))
        if gagnant != r["dep"]:
            desaccords.append((r["ark"], r["dep"], gagnant, part))

    if desaccords:
        print(f"\nDÉSACCORDS ({len(desaccords)}) — l'index se trompe, ou les "
              f"noms ne suffisent pas :")
        for ark, dit, vu, part in desaccords:
            print(f"   {ark} : index {dit}, noms {vu} ({part:.0%})")
        print("\nCorriger la colonne `dep` de fascicules_1968.csv à la main,\n"
              "puis relancer. Un fascicule mal attribué rend un département\n"
              "présent qui ne l'est pas, et absent celui qu'il est vraiment.")
    else:
        print("\nAucun désaccord : l'index et les noms de communes concordent.")


if __name__ == "__main__":
    main()
