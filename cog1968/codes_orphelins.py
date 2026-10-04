#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
codes_orphelins.py — retrouver le code d'une commune que la trame ignore

    python3 cog1968/codes_orphelins.py              # à blanc
    python3 cog1968/codes_orphelins.py --appliquer

Ce que `corrige_codes.py` ne peut pas voir
------------------------------------------
`corrige_codes.py` part du CODE : il cherche son nom dans la trame et vérifie
qu'il correspond au nom lu. Sa première ligne utile est donc

    vrai = ref.get(r["insee"])
    if not vrai: continue

**Un code absent de la trame est sauté.** Or c'est exactement le cas des lignes
que `59` refuse de poser sous le motif « commune inconnue de cm_commune ».

On prend donc le problème par l'autre bout : partir du NOM, chercher la commune
dans son département, et proposer son code.

CE QUE LA MESURE A CORRIGÉ DANS L'IDÉE DE DÉPART
------------------------------------------------
Je comptais « récupérer 845 communes ». C'est faux. Sur 2 267 lignes dont le
code est inconnu de la trame 2011 :

    1 369   nom introuvable — le NOM et le CODE sont fautifs, irrécupérable
      724   le code proposé est DÉJÀ lu ailleurs dans le département
      121   récupérables
       36   plusieurs chiffres diffèrent, ou nom trop court
       17   cible déjà visée par une autre orpheline (cf. `cibles` plus bas)

Les 724 ne sont pas des communes manquantes : ce sont des **lignes parasites**.
La commune est déjà lue correctement sous son bon code, et cette ligne-ci est
une lecture fautive de la même. Elles ne polluent pas la base — leur code étant
inconnu, `59` ne les pose pas — mais elles gonflent le CSV et faussent tout
compte de lignes.

**On les MARQUE, on ne les supprime pas** (`doublon_probable`), selon la règle
du dépôt.

UN FAIT QUI VAUT D'ÊTRE NOTÉ
----------------------------
Sur ces 724 parasites, **135 portent `accord = accord`** : les TROIS lectures
ont produit le même code, et il est faux. Seul le nom le révèle.

C'est la démonstration empirique de ce que `fusionne_passes.py` annonçait sans
le prouver : les trois passes lisent la même image avec le même moteur, leurs
erreurs sont corrélées, et **un accord ne garantit pas la justesse** — il
garantit seulement que la segmentation n'était pas en cause.

LES GARDE-FOUS, REPRIS DE `corrige_codes.py`
--------------------------------------------
  1. le nom lu correspond à une commune du département — exactement, ou à 0,85
     de similarité ;
  2. le code proposé n'est PAS déjà présent dans la lecture du département —
     sans quoi on créerait un doublon ;
  3. **un seul chiffre diffère**.

Le troisième filtre est aussi un contrôle : les faux appariements de la
comparaison floue diffèrent de deux ou trois chiffres.

Position du chiffre fautif, mesurée sur les 121 retenus : **centaine 101**,
unité 11, dizaine 9. C'est l'inverse de `corrige_codes.py` (dizaine 328,
centaine 108, unité 15) — et c'est logique : une centaine fausse fait sortir le
code de la trame, donc échappe à l'autre script et atterrit ici. **Les deux
scripts se partagent le champ sans se recouvrir.**

Réversible : `insee_ocr` garde la lecture d'origine, et une sauvegarde est
écrite avant toute modification.
"""

import argparse
import collections
import csv
import difflib
import shutil
import sys
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
LU = RACINE / "cog1968" / "communes_1968_fusion.csv"
NOMS = RACINE / "build" / "noms_geofla.csv"

sys.path.insert(0, str(RACINE / "circo"))
from extrait_paris import cle                            # noqa: E402

SEUIL = 0.85          # plus strict que corrige_codes.py (0,80) : ici le code
                      # n'apporte aucune confirmation, le nom porte seul.
NOM_MINI = 4          # « Bue », « Ay » : trop court pour un appariement sûr


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--appliquer", action="store_true")
    ap.add_argument("--fichier", default=None)
    args = ap.parse_args()

    src = Path(args.fichier) if args.fichier else LU
    if not src.is_absolute():
        src = RACINE / "cog1968" / src.name
    if not src.exists():
        sys.exit(f"{src} absent.")

    ref, connus = collections.defaultdict(dict), set()
    for r in csv.DictReader(NOMS.open(encoding="utf-8")):
        i = r["insee"].strip()
        connus.add(i)
        ref[i[:2]][cle(r["nom"])] = i

    lignes = list(csv.DictReader(src.open(encoding="utf-8")))
    present = collections.defaultdict(set)
    for r in lignes:
        present[r["dep"]].add(r["insee"])

    classes = collections.Counter()
    corriges, parasites = [], []
    # LES CIBLES DÉJÀ ATTRIBUÉES.
    #
    # Le garde-fou 2 vérifie que le code proposé n'est pas DÉJÀ LU dans le
    # département. Il ne dit rien du cas où DEUX orphelines visent la même
    # cible — et deux lignes corrigées vers le même code, avec le même canton,
    # produisent un doublon exact que `59` ne sait pas départager : son
    # nettoyage garde `min(insee)` par atome, ce qui ne trie rien quand les
    # deux lignes ont le même `insee`.
    #
    # Mesuré : 17 collisions. On garde la PREMIÈRE (les lignes sont triées par
    # département et code) et l'on compte les autres.
    cibles = set()

    for r in lignes:
        if r["insee"] in connus:
            continue
        k = cle(r["nom"] or "")
        if len(k) < NOM_MINI:
            classes["nom trop court"] += 1
            continue
        hit, voie = ref[r["dep"]].get(k), "exact"
        if not hit:
            c = difflib.get_close_matches(k, ref[r["dep"]].keys(), n=1, cutoff=SEUIL)
            if not c:
                classes["nom introuvable dans le département"] += 1
                continue
            hit, voie = ref[r["dep"]][c[0]], "flou"

        n_diff = sum(1 for a, b in zip(r["insee"][2:], hit[2:]) if a != b)

        if hit in present[r["dep"]]:
            # La commune est déjà lue sous son bon code : cette ligne-ci est une
            # lecture fautive de la même. On la marque.
            classes["ligne parasite (commune déjà lue)"] += 1
            parasites.append((r, hit, n_diff))
            continue
        if n_diff != 1:
            classes[f"{n_diff} chiffres différents"] += 1
            continue
        if (r["dep"], hit) in cibles:
            classes["cible déjà visée par une autre orpheline"] += 1
            continue
        cibles.add((r["dep"], hit))
        classes[f"RETENU ({voie})"] += 1
        corriges.append((r, hit))

    print(f"{len(lignes)} lignes lues, "
          f"{sum(1 for r in lignes if r['insee'] not in connus)} au code inconnu\n")
    for k, n in classes.most_common():
        print(f"   {k:<38} {n:>5}")

    if corriges:
        subs, pos = collections.Counter(), collections.Counter()
        for r, h in corriges:
            for i, (a, b) in enumerate(zip(r["insee"][2:], h[2:])):
                if a != b:
                    subs[f"{a} lu pour {b}"] += 1
                    pos[["centaine", "dizaine", "unité"][i]] += 1
        print("\n  substitutions :")
        for k, n in subs.most_common(6):
            print(f"     {k:<16} {n:>4}")
        print(f"  position du chiffre fautif : {dict(pos)}")
        print("  (l'inverse de corrige_codes.py, où la DIZAINE domine — une")
        print("   centaine fausse fait sortir le code de la trame, donc échappe")
        print("   à l'autre script et atterrit ici.)")

    if parasites:
        acc = collections.Counter(r["accord"] for r, _, _ in parasites)
        print(f"\n  les {len(parasites)} lignes parasites, par confiance de lecture :")
        for k, n in acc.most_common():
            print(f"     {k:<18} {n:>5}")
        print(f"\n  dont {acc['accord']} où les TROIS lectures s'accordent sur un")
        print("  code faux. **Un accord ne garantit pas la justesse** : même")
        print("  image, même moteur, erreurs corrélées.")

    if not args.appliquer:
        print("\nÀ blanc. Relancer avec --appliquer.")
        return 0

    sauve = src.with_suffix(".csv.avant_orphelins")
    if not sauve.exists():
        shutil.copy2(src, sauve)
        print(f"\n  sauvegarde : {sauve.name}")
    else:
        print(f"\n  sauvegarde déjà présente, conservée : {sauve.name}")

    a_corriger = {id(r): h for r, h in corriges}
    a_marquer = {id(r) for r, _, _ in parasites}
    champs = list(lignes[0].keys())
    for c in ("insee_ocr", "doublon_probable"):
        if c not in champs:
            champs.append(c)

    for r in lignes:
        r.setdefault("insee_ocr", "")
        r.setdefault("doublon_probable", "")
        h = a_corriger.get(id(r))
        if h:
            if not r["insee_ocr"]:
                r["insee_ocr"] = r["insee"]
            r["insee"] = h
            r["insee3"] = h[2:]
        if id(r) in a_marquer:
            r["doublon_probable"] = "oui"

    lignes.sort(key=lambda x: (x["dep"], x["insee"]))
    with src.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=champs)
        w.writeheader()
        w.writerows(lignes)

    print(f"\n{len(corriges)} codes retrouvés par le nom.")
    print(f"{len(parasites)} lignes marquées `doublon_probable` — signalées, "
          "pas supprimées.")
    print("\nRAPPEL : le CSV gagne la colonne `doublon_probable`.")
    print("`58_cog1968_stage.sql` la déclare déjà — mais il lit ses colonnes")
    print("dans l'ORDRE, sans consulter l'en-tête : toute colonne ajoutée en")
    print("amont doit y être reportée AVANT de recharger.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
