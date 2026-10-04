#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
corrige_codes.py — réparer les codes INSEE dont le NOM prouve qu'ils sont faux

    python3 cog1968/corrige_codes.py            # à blanc
    python3 cog1968/corrige_codes.py --appliquer

Pourquoi corriger, alors que le dépôt signale d'habitude sans toucher
---------------------------------------------------------------------
`hors_borne` signale et ne corrige pas, parce qu'un canton au-delà de la
numérotation de 1940 peut être une erreur de lecture **ou une création réelle**
— et rien ne les départage sans le tableau II.

Ici, trois signaux INDÉPENDANTS concordent sur chaque ligne retenue :

  1. **le nom** désigne une autre commune du département que le code
     (`controle_nom_code.py`) ;
  2. **le code lu apparaît deux fois** dans le département et **le code proposé
     n'y apparaît pas** — un test qui ne doit rien à la ressemblance des noms ;
  3. **un seul chiffre diffère**, à n'importe quelle position.

Le troisième n'a été ni cherché ni supposé : il est sorti de la mesure. Il sert
aussi de second filtre — un faux appariement de la comparaison floue diffère
presque toujours de deux ou trois chiffres.

Les substitutions, sur les 749 cas retenus :

    5 lu pour 3   288        6 lu pour 8   108
    8 lu pour 3   165        4 lu pour 3    47

**Le 3 est la victime des deux tiers des cas**, le 8 vient après. Une table de
sosies ne peut rien y faire — « 5 » est un chiffre parfaitement valide — c'est
le nom, et lui seul, qui tranche.

Ce que ce script NE corrige pas
-------------------------------
Les cas « probables » (le code proposé est absent mais le code lu n'est pas en
double) et « douteux » (les deux codes sont déjà présents) restent tels quels et
sortent dans le rapport. Ceux dont PLUSIEURS chiffres diffèrent non plus : leur
cause n'est pas établie — fusion de colonnes, ligne sautée, ou faux positif de
la comparaison floue.

Réversible : la colonne `insee_ocr` garde la lecture d'origine, et
`communes_1968.csv.avant_correction` est écrit avant toute modification.
"""

import argparse
import collections
import csv
import difflib
import shutil
import sys
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
LU = RACINE / "cog1968" / "communes_1968.csv"
NOMS = RACINE / "build" / "noms_geofla.csv"

sys.path.insert(0, str(RACINE / "circo"))
from extrait_paris import cle                            # noqa: E402

SEUIL = 0.80

# UN SEUL CHIFFRE DIFFÉRENT — et non « un écart inférieur à 10 ».
#
# Le premier passage, le 22 août 2026, retenait les écarts de 1 à 9. Il a
# corrigé 331 codes et j'en ai conclu que **le chiffre des unités** était le
# fautif dans 331 cas sur 331. C'était un artefact du filtre : un écart de moins
# de 10 exclut par construction toute erreur de dizaine.
#
# Sur les 562 écartés, 432 passent le même test du doublon/absent, et **413
# n'ont qu'un chiffre faux** — 328 fois la dizaine, 108 fois la centaine, 15
# fois l'unité. Avec la même table de confusions :
#
#     5 lu pour 3  186        6 lu pour 8   65
#     8 lu pour 3   71        4 lu pour 3   46
#
# Ce n'est donc pas une position qui est fragile, c'est le CHIFFRE 3 — victime
# des deux tiers des cas — et le 8 après lui.
#
# Le critère « un seul chiffre » est en outre un second filtre indépendant :
# les faux appariements de la comparaison floue diffèrent presque toujours de
# deux ou trois chiffres. « Blessey » proposé pour ESSEY : 084 contre 251.
UN_SEUL_CHIFFRE = True


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--appliquer", action="store_true")
    # LE FICHIER EST UN ARGUMENT depuis la fusion des deux passes. Le test du
    # doublon/absent dépend de ce qui est présent DANS LE MÊME FICHIER : sur la
    # fusion, un code que psm 6 avait mal lu peut être correctement présent
    # grâce à psm 4, ce qui change la conclusion. Corriger la fusion n'est donc
    # pas la somme des corrections de chaque passe.
    ap.add_argument("--fichier", default=None,
                    help="ex. communes_1968_fusion.csv (défaut : "
                         "communes_1968.csv)")
    args = ap.parse_args()

    global LU
    if args.fichier:
        f = Path(args.fichier)
        LU = f if f.is_absolute() else RACINE / "cog1968" / f.name
        if not LU.exists():
            sys.exit(f"{LU} absent.")

    ref, par_dep_ref = {}, collections.defaultdict(dict)
    for r in csv.DictReader(NOMS.open(encoding="utf-8")):
        i = r["insee"].strip()
        ref[i] = r["nom"]
        par_dep_ref[i[:2]][cle(r["nom"])] = i

    lignes = list(csv.DictReader(LU.open(encoding="utf-8")))
    compte = collections.defaultdict(collections.Counter)
    for r in lignes:
        compte[r["dep"]][r["insee"]] += 1

    corrigees, probables, douteuses, larges = [], 0, 0, 0
    for r in lignes:
        vrai = ref.get(r["insee"])
        if not vrai:
            continue
        lu, att = cle(r["nom"]), cle(vrai)
        if lu in att or att in lu or \
           difflib.SequenceMatcher(None, lu, att).ratio() >= SEUIL:
            continue
        c = difflib.get_close_matches(lu, par_dep_ref[r["dep"]].keys(),
                                      n=1, cutoff=SEUIL)
        if not c:
            continue
        prop = par_dep_ref[r["dep"]][c[0]]
        if prop == r["insee"]:
            continue
        n_diff = sum(1 for x, y in zip(r["insee"][2:], prop[2:]) if x != y)
        if n_diff != 1:
            larges += 1
            continue
        d = compte[r["dep"]]
        if d[r["insee"]] > 1 and d[prop] == 0:
            corrigees.append((r, prop))
        elif d[prop] == 0:
            probables += 1
        else:
            douteuses += 1

    print(f"{len(lignes)} lignes lues")
    print(f"  à corriger  (trois signaux concordants)   {len(corrigees):>5}")
    print(f"  probables   (code proposé absent seul)    {probables:>5}")
    print(f"  douteuses   (les deux codes présents)     {douteuses:>5}")
    print(f"  plus d'un chiffre différent, écarté       {larges:>5}")

    subs = collections.Counter()
    for r, prop in corrigees:
        a, b = r["insee"][2:], prop[2:]
        for x, y in zip(a, b):
            if x != y:
                subs[f"{x} lu pour {y}"] += 1
    if subs:
        print("\n  substitutions :")
        for k, v in subs.most_common(6):
            print(f"     {k:<16} {v:>4}")

    if not args.appliquer:
        print("\nÀ blanc. Relancer avec --appliquer.")
        return 0

    # La sauvegarde n'est écrite qu'une fois : au second passage, elle
    # contiendrait un état déjà corrigé et l'original serait perdu.
    sauve = LU.with_suffix(".csv.avant_correction")
    if not sauve.exists():
        shutil.copy2(LU, sauve)
        print(f"  sauvegarde de l'état d'origine : {sauve.name}")
    else:
        print(f"  sauvegarde déjà présente, conservée : {sauve.name}")

    a_corriger = {id(r): prop for r, prop in corrigees}
    champs = list(lignes[0].keys())
    if "insee_ocr" not in champs:
        champs.insert(champs.index("insee") + 1, "insee_ocr")

    for r in lignes:
        prop = a_corriger.get(id(r))
        # NE PAS ÉCRASER une correction antérieure. La version précédente
        # écrivait `insee_ocr = ""` sur toute ligne non corrigée ce coup-ci,
        # effaçant la trace des 331 codes réparés au passage d'avant. Un
        # deuxième passage aurait rendu le premier irréversible.
        r.setdefault("insee_ocr", "")
        if prop:
            if not r["insee_ocr"]:
                r["insee_ocr"] = r["insee"]
            r["insee"] = prop
            r["insee3"] = prop[2:]

    lignes.sort(key=lambda x: (x["dep"], x["insee"]))
    with LU.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=champs)
        w.writeheader()
        w.writerows(lignes)

    print(f"\n{len(corrigees)} codes corrigés.")
    print("  colonne `insee_ocr` : la lecture d'origine, pour tout défaire.")
    print("\nRelancer ensuite `python3 cog1968/rappel_1968.py` :")
    print("  le rappel ET les DOUBLONS doivent bouger de ce nombre,")
    print("  en sens inverse. Les « inconnus », eux, ne bougeront pas :")
    print("  un code mal lu designe une commune existante, pas un code absurde.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
