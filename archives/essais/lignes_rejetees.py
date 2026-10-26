#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
lignes_rejetees.py — montrer ce que la grammaire de `extrait_1968.py` REFUSE.

    python3 archives/essais/lignes_rejetees.py --dep 13
    python3 archives/essais/lignes_rejetees.py --dep 13 --pages 9-12 --tout

Pourquoi
--------
L'extraction du COG 1968 était à **77,6 % de rappel** avant l'élargissement de
la grammaire du 21 août 2026. Ce chiffre se remesure par
`python3 cog1968/rappel_1968.py`, qui confronte les codes lus à la liste des
communes vivantes au 1er janvier 1968 selon `cm_commune` — construite depuis
les mouvements INSEE, donc indépendante de l'OCR.

**Cette docstring renvoyait auparavant à une option `--attendu`
d'`extrait_1968.py` qui n'a jamais existé.** Je l'avais écrite ici, puis relue
comme un fait. Un chiffre sans commande qui le produise n'est pas une mesure. Les pages sont bien trouvées — il n'y a pas de filtre
de page, seules les pages de commune produisent des lignes — donc la perte est
ligne à ligne.

Une cause est établie et se voit à l'œil nu dans le fac-similé : **le COG rejette
l'article en fin de nom, entre parenthèses.**

    259   259   1 32 008  Barben (La).             315 ...
    253   253   2 31 011  Baux-de-Provence (Les).  295 ...

Or la classe de caractères du nom, dans `extrait_1968.py`, n'accepte ni `(`
ni `)`. Toute commune à article est donc perdue. Cela représente **6,3 % des
communes de 1968** et corrèle à −0,50 avec le rappel par département : la
Moselle, qui n'a presque aucun article, est à 88,7 % ; la Vendée et le Var, qui
en sont pleins, à 62 et 66 %.

**Mais cela n'explique qu'un tiers de la perte.** Le Territoire de Belfort n'a
aucun nom à article et plafonne à 53,8 %. Le reste doit être VU, pas supposé —
c'est l'objet de ce script.

Ce qu'il fait
-------------
Il rejoue la même chaîne OCR que l'extracteur, sur les mêmes pages, et imprime
les lignes qui **ressemblent à une ligne de commune sans en être une** aux yeux
de la grammaire : celles qui portent la signature « arrondissement, canton,
code à trois chiffres » sans que `LIGNE` les accepte.

C'est volontairement plus large que `LIGNE` : on veut voir les échecs, pas les
confirmer. Une ligne de titre ou de total apparaîtra donc parfois — c'est le
prix à payer pour ne rien cacher.
"""

import argparse
import re
import sys
from collections import Counter
from pathlib import Path

RACINE = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(RACINE / "cog1968"))
sys.path.insert(0, str(RACINE / "cog1954"))

# La chaîne OCR du projet : pdftoppm -r 300 -gray puis tesseract -l fra --psm 6.
# On la réutilise plutôt que de la réécrire — c'est la règle du dépôt, et son
# option `--dep` avait justement été écrite en prévision des fascicules de 1968.
from extrait_1954 import page_texte                      # noqa: E402
from extrait_1968 import LIGNE, EXCLUS, index            # noqa: E402

# Signature minimale d'une ligne de commune : arrondissement (1 caractère),
# canton (2), code INSEE (3). On ne demande RIEN sur le nom ni sur les
# populations — c'est précisément là que la grammaire échoue.
SIGNATURE = re.compile(r"(?<!\d)([\dOSlI])\s+([\dOSlI$]{2})\s+(\d{3})\s+(\S.*)$")

# Motifs de rejet connus, pour classer plutôt que de tout jeter en vrac.
MOTIFS = [
    ("article entre parenthèses", re.compile(r"\([A-Za-zÉÈÀ][a-zéèà']{1,3}\)")),
    ("appel de note",             re.compile(r"\(\d\)")),
    ("ligne de total",            re.compile(r"\bTOTAL\b|\bCanton\b", re.I)),
    ("pas de population finale",  re.compile(r"[^\d.\s]$")),
]


def classe(reste):
    for nom, rx in MOTIFS:
        if rx.search(reste):
            return nom
    return "autre"


def pages_de(spec, n_max):
    if not spec:
        return range(1, n_max + 1)
    out = []
    for bloc in spec.split(","):
        if "-" in bloc:
            a, b = bloc.split("-")
            out.extend(range(int(a), int(b) + 1))
        else:
            out.append(int(bloc))
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--dep", required=True, help="département, ex. 13")
    ap.add_argument("--pages", help="ex. 9-12 ou 9,11 ; par défaut tout le fascicule")
    ap.add_argument("--langue", default="fra")
    ap.add_argument("--tout", action="store_true",
                    help="imprimer aussi les lignes ACCEPTÉES, pour comparer")
    args = ap.parse_args()

    fasc = {d: p for d, p in index().items()}
    if args.dep not in fasc:
        sys.exit(f"Département {args.dep} absent de l'index des fascicules.")
    pdf = fasc[args.dep]
    print(f"{args.dep} : {Path(pdf).name}")

    # Même méthode que `extrait_1968.py` : `pdfinfo`, pas PyMuPDF — qui n'est
    # pas une dépendance du dépôt. Réutiliser ce qui existe plutôt que d'ajouter.
    import subprocess
    info = subprocess.run(["pdfinfo", str(pdf)], capture_output=True, text=True)
    m = re.search(r"^Pages:\s+(\d+)", info.stdout, re.M)
    if not m:
        sys.exit(f"pdfinfo n'a pas su lire {Path(pdf).name}")
    n_max = int(m.group(1))

    compte = Counter()
    n_ok = n_ko = 0
    for page in pages_de(args.pages, n_max):
        try:
            texte = page_texte(pdf, page, langue=args.langue)
        except Exception as e:                              # noqa: BLE001
            print(f"  page {page} : OCR impossible ({e})")
            continue
        for brut in texte.splitlines():
            # EXCLUS est appliqué ICI, comme dans `extrait_1968.py`.
            #
            # Il ne l'était pas, et ce script annonçait donc des « acceptées »
            # que l'extracteur rejetait ensuite : 20 sur deux pages des
            # Hauts-de-Seine quand l'extracteur en gardait 17 pour tout le
            # département. **Un diagnostic qui ne reproduit pas la chaîne qu'il
            # diagnostique mesure autre chose.** Corrigé le 22 août 2026.
            if EXCLUS.search(brut):
                continue
            accepte = LIGNE.search(brut)
            sig = SIGNATURE.search(brut)
            if accepte:
                n_ok += 1
                if args.tout:
                    print(f"  ok  p{page:>3} | {brut.strip()[:110]}")
            elif sig:
                n_ko += 1
                motif = classe(sig.group(4))
                compte[motif] += 1
                print(f"  KO  p{page:>3} [{motif:<26}] {brut.strip()[:110]}")

    print(f"\nacceptées : {n_ok}    rejetées : {n_ko}")
    if n_ko:
        print("\npar motif :")
        for motif, n in compte.most_common():
            print(f"   {motif:<28} {n:>5}   {n/n_ko:>5.1%}")
    print("\nCe tableau dit où porter l'effort. Une catégorie « autre » élevée"
          "\nsignifie qu'il reste un mécanisme à comprendre — le lire, pas le"
          "\ncontourner.")


if __name__ == "__main__":
    main()
