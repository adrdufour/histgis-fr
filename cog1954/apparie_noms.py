#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
apparie_noms.py — donner un code INSEE aux communes lues en 1954

    python3 cog1954/apparie_noms.py              # à blanc
    python3 cog1954/apparie_noms.py --appliquer

Le volume de 1954 n'imprime PAS le code INSEE — contrairement à celui de 1968.
La jointure passe donc par le nom, et c'est là que le dépouillement perdait
7 576 communes.

CE QUE `variantes()` CHANGE
==========================
`cog1954/normalise_nom.py` reconstruit les formes à essayer : article postposé
remis en tête, « St » déployé en « Saint », caractère parasite initial retiré,
et leurs combinaisons. Mesuré sur les 7 609 orphelins : **2 583 retrouvés en
correspondance exacte, 3 514 en flou, 1 512 restants** — 80 %.

CE QUI EST POSÉ, ET CE QUI NE L'EST PAS
=======================================
Quatre classes, et une seule est écrite comme un fait :

    ferme            correspondance EXACTE, et la commune n'est visée par
                     aucune autre ligne du département — 2 576 cas
    exact_collision  correspondance exacte mais DEUX lignes visent la même
                     commune : l'une des deux est une relecture de l'autre
    flou             ressemblance à 0,85 — proposé, pas posé
    aucun            rien trouvé

**Seule `ferme` reçoit un code.** Les autres sont marquées et gardent leur
colonne `insee` vide.

POURQUOI LE FLOU N'EST PAS POSÉ
===============================
Les collisions le montrent : sur 8 cibles visées deux fois, deux sont de vrais
faux appariements — `Barneville-sur-Mer` rapproché de `Bréville`,
`Balmelles (Les)` de `Salelles`. Et les collisions ne révèlent que la partie
visible : un faux qui tombe sur une commune libre passe inaperçu.

**Un appariement par ressemblance n'est sûr que confirmé par une information
qui ne doit rien à la ressemblance.** C'est la leçon des 121 codes orphelins de
1968, où le test « doublon présent / proposé absent » jouait ce rôle. Ici le
second signal existe — le CANTON, porté par la ligne de 1954 — mais il demande
la composition cantonale de 1940 ou 1999, et ce sera un autre fichier.

Réversible : `communes_1954_redecoupe.csv.avant_appariement` est écrit avant
toute modification, et la colonne `appariement` dit d'où vient chaque code.
"""

import argparse
import collections
import csv
import difflib
import shutil
import sys
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(RACINE / "cog1954"))
from normalise_nom import variantes, cle                  # noqa: E402

LU = RACINE / "cog1954" / "communes_1954_redecoupe.csv"
NOMS = RACINE / "build" / "noms_geofla.csv"
N1954 = RACINE / "cog1954" / "noms_1954.csv"

SEUIL_FLOU = 0.85


def charge_referentiel():
    """{dep: {cle du nom -> code INSEE}} pour les communes de 1954."""
    ref = collections.defaultdict(dict)
    for r in csv.DictReader(NOMS.open(encoding="utf-8")):
        i = r["insee"].strip()
        ref[i[:2]].setdefault(cle(r["nom"]), i)
    n_2011 = sum(len(v) for v in ref.values())

    if not N1954.exists():
        print("cog1954/noms_1954.csv absent — le référentiel ignorera les")
        print("communes disparues depuis 1954. Jouer sql/65_noms_1954.sql.\n")
        return ref, n_2011, 0

    for r in csv.DictReader(N1954.open(encoding="utf-8")):
        if r["nom"].strip():
            ref[r["code"][:2]].setdefault(cle(r["nom"]), r["code"])
    return ref, n_2011, sum(len(v) for v in ref.values()) - n_2011


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--appliquer", action="store_true")
    args = ap.parse_args()

    if not LU.exists():
        sys.exit(f"{LU} absent.")

    ref, n2011, n54 = charge_referentiel()
    print(f"référentiel : {n2011} noms de 2011 + {n54} de communes disparues\n")

    lignes = list(csv.DictReader(LU.open(encoding="utf-8")))

    # PREMIÈRE PASSE : proposer, sans rien décider.
    propositions = []
    for r in lignes:
        nom, dep = (r.get("commune") or "").strip(), (r.get("dep") or "").strip()
        if not nom or dep not in ref:
            propositions.append((r, None, "aucun"))
            continue
        vs = variantes(nom)
        hit = next((ref[dep][v] for v in vs if v in ref[dep]), None)
        if hit:
            propositions.append((r, hit, "exact"))
            continue
        trouve = None
        for v in vs:
            c = difflib.get_close_matches(v, ref[dep].keys(), n=1, cutoff=SEUIL_FLOU)
            if c:
                trouve = ref[dep][c[0]]
                break
        propositions.append((r, trouve, "flou" if trouve else "aucun"))

    # SECONDE PASSE : l'unicité ne se juge qu'une fois toutes les propositions
    # faites. C'est la faute commise le 22 août dans `codes_orphelins.py` —
    # le garde-fou y vérifiait que la cible n'était pas DÉJÀ LUE, jamais qu'une
    # autre proposition ne la visait aussi.
    vises = collections.Counter(h for _, h, v in propositions
                                if h and v == "exact")

    classes = collections.Counter()
    resultat = []
    for r, hit, voie in propositions:
        if voie == "exact" and vises[hit] == 1:
            statut, code = "ferme", hit
        elif voie == "exact":
            statut, code = "exact_collision", ""
        elif voie == "flou":
            statut, code = "flou", ""
        else:
            statut, code = "aucun", ""
        classes[statut] += 1
        resultat.append((r, code, statut, hit or ""))

    print(f"{len(lignes)} lignes lues\n")
    for k in ("ferme", "exact_collision", "flou", "aucun"):
        print(f"   {k:<18} {classes[k]:>6}"
              f"   {classes[k]/len(lignes):>5.1%}")

    print(f"\n   POSÉ (ferme uniquement)  {classes['ferme']}")
    print(f"   proposé sans être posé   {classes['flou'] + classes['exact_collision']}")

    if classes["exact_collision"]:
        print("\n  quelques collisions exactes — deux lectures d'une même commune,")
        print("  ou deux communes rapprochées à tort :")
        vus = set()
        for r, code, st, hit in resultat:
            if st == "exact_collision" and hit not in vus and len(vus) < 6:
                vus.add(hit)
                jum = [x[0]["commune"] for x in resultat if x[3] == hit]
                print(f"     {hit} <- {jum}")

    if not args.appliquer:
        print("\nÀ blanc. Relancer avec --appliquer.")
        return 0

    sauve = LU.with_suffix(".csv.avant_appariement")
    if not sauve.exists():
        shutil.copy2(LU, sauve)
        print(f"\n  sauvegarde : {sauve.name}")
    else:
        print(f"\n  sauvegarde déjà présente, conservée : {sauve.name}")

    champs = list(lignes[0].keys())
    for c in ("insee", "appariement", "insee_propose"):
        if c not in champs:
            champs.append(c)

    for r, code, statut, hit in resultat:
        r["insee"] = code
        r["appariement"] = statut
        # La proposition NON retenue est conservée : elle sera reprise quand le
        # canton fournira le second signal, et la perdre obligerait à tout
        # recalculer.
        r["insee_propose"] = hit if not code else ""

    with LU.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=champs)
        w.writeheader()
        w.writerows(lignes)

    print(f"\n{classes['ferme']} codes posés (`appariement = ferme`).")
    print(f"{classes['flou'] + classes['exact_collision']} propositions gardées "
          "dans `insee_propose`, sans code.")
    print("\nProchain pas : confirmer le flou par le CANTON, information")
    print("indépendante du nom. Sans quoi ces lignes resteront des propositions.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
