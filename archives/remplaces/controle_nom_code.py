#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
controle_nom_code.py — le nom confirme-t-il le code INSEE ?

    python3 archives/remplaces/controle_nom_code.py
    python3 archives/remplaces/controle_nom_code.py --dep 62 --detail

Produit `cog1968/communes_1968_suspects.csv` : une ligne par rattachement dont
le NOM désigne une autre commune que son CODE.

Le principe
-----------
Chaque ligne du tableau III porte deux lectures indépendantes de la même
commune : son **code INSEE**, trois chiffres, et son **nom**, une quinzaine de
caractères. L'en-tête d'`extrait_1968.py` l'annonce depuis le premier jour —
« le nom confirme le code, et non l'inverse » — mais rien ne le vérifiait.

Quinze caractères résistent bien mieux à l'OCR que trois chiffres. Quand les
deux lectures se contredisent, **c'est presque toujours le code qui a tort**.

Ce que ce script distingue, et pourquoi c'est le point délicat
--------------------------------------------------------------
Un nom lu « Cevyzériat » pour CEYZERIAT n'est pas une erreur de code : c'est du
bruit d'OCR sur le nom lui-même. Une comparaison stricte en trouve 3 944 et
noie les vrais cas.

Le discriminant est ailleurs : **le nom lu ressemble-t-il davantage à une AUTRE
commune du même département ?** Si oui, le code est suspect ; sinon, le nom est
simplement abîmé.

  01015  lu « Arandas »   attendu ARBIGNIEU  → ressemble à 01013   suspect
  01072  lu « Cevyzériat » attendu CEYZERIAT → aucun autre candidat  bruit

Mesuré sur la passe du 21 août 2026 : 25 462 conformes, 904 noms abîmés sans
meilleur candidat, **991 codes suspects (3,6 %)**.

On SIGNALE, on ne corrige pas
-----------------------------
Le script écrit un fichier de suspects avec le code proposé, et ne touche pas à
`communes_1968.csv`. C'est la même règle que la colonne `hors_borne` : un
correctif automatique qui se tromperait une fois sur vingt introduirait des
erreurs invisibles, là où une liste se relit.

Le code proposé est presque toujours VOISIN de celui lu — 013 pour 015, 149
pour 148 — ce qui confirme la lecture d'un chiffre et non un décalage de ligne.
La colonne `ecart` le donne : un écart de 1 ou 2 conforte l'hypothèse, un écart
de 200 la ruine et désigne autre chose, probablement une fusion de colonnes.
"""

import argparse
import collections
import csv
import difflib
import sys
from pathlib import Path

RACINE = Path(__file__).resolve().parents[2]
LU = RACINE / "cog1968" / "communes_1968.csv"
NOMS = RACINE / "build" / "noms_geofla.csv"
SORTIE = RACINE / "archives" / "remplaces" / "communes_1968_suspects.csv"

sys.path.insert(0, str(RACINE / "circo"))
from extrait_paris import cle                            # noqa: E402

# Deux seuils, et ils ne jouent pas le même rôle.
#
# `CONFORME` : au-dessus, le nom lu et le nom attendu sont la même commune,
# quelles que soient les coquilles. Fixé bas (0,80) parce que l'OCR de ces
# fascicules abîme volontiers deux ou trois caractères sur quinze.
#
# `CANDIDAT` : en dessous, on n'accuse pas. Un nom trop abîmé ressemble à
# beaucoup de choses, et proposer un code sur une ressemblance faible
# reviendrait à fabriquer l'erreur qu'on prétend trouver.
CONFORME = 0.80
CANDIDAT = 0.80


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--dep", help="restreindre à un département")
    ap.add_argument("--detail", action="store_true", help="lister les suspects")
    args = ap.parse_args()

    for f in (LU, NOMS):
        if not f.exists():
            sys.exit(f"Fichier absent : {f}")

    ref, par_dep = {}, collections.defaultdict(dict)
    for r in csv.DictReader(NOMS.open(encoding="utf-8")):
        i = r["insee"].strip()
        ref[i] = r["nom"]
        par_dep[i[:2]][cle(r["nom"])] = i

    lignes = [r for r in csv.DictReader(LU.open(encoding="utf-8"))
              if not args.dep or r["dep"] == args.dep]

    conformes = abimes = 0
    suspects = []
    for r in lignes:
        vrai = ref.get(r["insee"])
        if not vrai:
            continue                       # commune disparue avant 2011
        lu, att = cle(r["nom"]), cle(vrai)
        if lu in att or att in lu or \
           difflib.SequenceMatcher(None, lu, att).ratio() >= CONFORME:
            conformes += 1
            continue
        cands = difflib.get_close_matches(lu, par_dep[r["dep"]].keys(),
                                          n=1, cutoff=CANDIDAT)
        if not cands or par_dep[r["dep"]][cands[0]] == r["insee"]:
            abimes += 1
            continue
        propose = par_dep[r["dep"]][cands[0]]
        suspects.append({
            "dep": r["dep"], "insee_lu": r["insee"], "nom_lu": r["nom"],
            "nom_attendu": vrai, "insee_propose": propose,
            "nom_propose": ref[propose],
            "ecart": abs(int(propose[2:]) - int(r["insee"][2:])),
            "canton": r["canton"], "page": r["page"],
        })

    with SORTIE.open("w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=list(suspects[0].keys()) if suspects
                           else ["dep", "insee_lu", "nom_lu", "nom_attendu",
                                 "insee_propose", "nom_propose", "ecart",
                                 "canton", "page"])
        w.writeheader()
        w.writerows(suspects)

    total = conformes + abimes + len(suspects)
    print(f"lignes confrontables : {total}")
    print(f"  nom conforme au code                  {conformes:>6}  "
          f"{conformes/total:6.1%}")
    print(f"  nom abîmé, aucun meilleur candidat    {abimes:>6}  "
          f"{abimes/total:6.1%}   bruit d'OCR")
    print(f"  nom d'une AUTRE commune du dept       {len(suspects):>6}  "
          f"{len(suspects)/total:6.1%}   CODE SUSPECT")
    print(f"\n{SORTIE.relative_to(RACINE)}")

    if suspects:
        ec = collections.Counter(min(s["ecart"], 10) for s in suspects)
        print("\nécart entre le code lu et le code proposé :")
        for e in sorted(ec):
            lib = f"{e}" if e < 10 else "10 et plus"
            print(f"   {lib:>10} : {ec[e]:>5}")
        print("   Un écart de 1 ou 2 conforte la lecture d'un chiffre.")
        print("   Un écart élevé désigne autre chose — fusion de colonnes,")
        print("   ligne sautée — et mérite d'être lu sur le fac-similé.")

        c = collections.Counter(s["dep"] for s in suspects)
        print("\ndépartements les plus touchés :")
        for d, n in c.most_common(10):
            t = sum(1 for r in lignes if r["dep"] == d)
            print(f"   {d}  {n:>4} / {t:>4}  {n/t:5.1%}")

    if args.detail:
        print()
        for s in suspects[:40]:
            print(f"   {s['dep']} {s['insee_lu']} « {s['nom_lu'][:26]:<26} »"
                  f"  -> {s['insee_propose']} {s['nom_propose'][:22]:<22}"
                  f"  écart {s['ecart']}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
