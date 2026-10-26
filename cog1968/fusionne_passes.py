#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
fusionne_passes.py — réunir PLUSIEURS lectures OCR du même fascicule

    python3 cog1968/fusionne_passes.py            # à blanc
    python3 cog1968/fusionne_passes.py --appliquer

Pourquoi deux lectures valent mieux qu'une bonne lecture
--------------------------------------------------------
Le 22 août 2026, `essai_ocr.py` a mesuré `--psm 4` contre `--psm 6` sur trois
fascicules entiers : +27, +38, +24 communes justes. Porté aux 86 départements,
le gain net est tombé à **+130**. Explication, mesurée : 41 départements
gagnent (+447), 42 perdent (−317). Les trois fascicules du banc avaient été
choisis pour leurs pages effondrées — c'étaient les plus malades du lot.

Mais le même calcul a montré tout autre chose :

    psm 6 seul   27 972 codes bruts
    psm 4 seul   28 102
    communs      24 916
    UNION        31 158        (+3 056)

**Les deux chaînes ne se trompent pas aux mêmes endroits.** Elles ne se
recouvrent qu'à 89 %. Choisir la meilleure jette près de 3 000 communes que
l'autre savait lire.

Et une TROISIÈME vaut mieux que deux
------------------------------------
`essai_troisieme.py`, sur trois départements de niveaux différents : une lecture
en **600 dpi** ajoute ~4 000 rattachements à l'union des deux autres, pour ~57
faux. Or 600 dpi, SEULE, est la plus mauvaise variante du banc de qualité — elle
rend moins que psm 4 sur presque toutes les pages.

*En redondance, la décorrélation prime la performance.* Une lecture médiocre qui
se trompe ailleurs vaut mieux qu'une bonne lecture qui se trompe pareil.

Ce que la fusion produit
------------------------
Le regroupement se fait **par commune**, et les ENSEMBLES de cantons de chaque
passe sont comparés. La colonne **`accord`** dit ce qui s'est passé :

    `accord`           toutes les passes présentes disent la même chose
    `fraction`         l'une voyait un canton de plus ; on prend l'union
    `majorite`         deux lectures contre une — arbitré, cf. ci-dessous
    `canton_conteste`  égalité stricte, aucune majorité : on retient la passe
                       prioritaire et l'on écrit les autres dans `canton_autre`
    `psm6`/`psm4`/`600`  une seule passe a vu cette commune

**LE VOTE MAJORITAIRE n'existe qu'à partir de trois lectures.** À deux, un
désaccord ne se tranche pas : 1 156 communes (3,6 %) restaient en
`canton_conteste`, arbitrées par la seule priorité du fichier. À trois, deux
voix concordantes contre une donnent un arbitrage.

Il reste FAIBLE, et la colonne le dit — `majorite` n'est pas `accord`. Les trois
lectures partagent la même image et le même moteur : leurs erreurs sont
corrélées, et deux voix peuvent se tromper ensemble.

Une colonne **`desaccord`** énumère les champs qui divergent quand les deux
passes ont pourtant produit la même ligne : `arr` 12,5 %, `nom` 8,2 %,
`pop1968` 2,0 %. *On signale, on ne tranche pas* : la valeur retenue est celle
de psm 6, arbitrairement, et l'écart est écrit à côté pour être arbitré par une
source plutôt que par un tirage au sort.

Ce que la fusion N'EST PAS
--------------------------
Ce n'est pas un contrôle indépendant. Les passes lisent la MÊME image avec
le MÊME moteur : leurs erreurs sont corrélées, et un accord entre elles ne
prouve pas la justesse — il prouve seulement que la segmentation n'était pas en
cause. Le seul étalon indépendant reste `cm_commune`, construite des mouvements
INSEE (`rappel_1968.py`).

Réversible : les fichiers d'entrée ne sont pas touchés.
"""

import argparse
import collections
import csv
import sys
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
D = RACINE / "cog1968"

# N LECTURES, et non plus deux. La première est prioritaire en cas d'égalité —
# un choix arbitraire, donc tracé.
#
# La troisième, 600 dpi, a été retenue sur son APPORT MARGINAL et non sur sa
# qualité : mesurée par `essai_troisieme.py` sur trois départements de niveaux
# différents, elle ajoute ~4 000 rattachements à l'union des deux autres pour
# ~57 faux — alors que, SEULE, c'est la plus mauvaise variante du banc de
# qualité. *En redondance, la décorrélation prime la performance.*
#
# Une passe absente est simplement ignorée : le fichier tourne à deux comme à
# trois.
# Chaque passe a un nom de fichier EXPLICITE. `communes_1968.csv` — le nom par
# défaut d'`extrait_1968.py` — n'apparaît plus ici : il désignait tantôt psm 6,
# tantôt psm 4, selon la dernière passe lancée, et c'est exactement ainsi qu'on
# écrase six heures d'OCR sans s'en apercevoir.
#
# Les trois passes sont rangées dans `archives/passes_1968/` depuis le 26 octobre
# 2026 : le recensement est acquis, seule la fusion est chargée (`sql/58`).
P = RACINE / "archives" / "passes_1968"
PASSES = [
    ("psm6", P / "communes_1968.psm6_corrige.csv"),
    ("psm4", P / "communes_1968.psm4_corrige.csv"),
    ("600",  P / "communes_1968.600.csv"),
]
SORTIE = D / "communes_1968_fusion.csv"

# Les champs sur lesquels un désaccord est signalé. `insee_ocr`, `page` et
# `hors_borne` en sont exclus : ils décrivent la LECTURE, pas la commune, et
# diffèrent normalement d'une passe à l'autre.
COMPARES = ("arr", "nom", "pop1968")


def charge(chemin):
    """{(dep, insee): {canton: ligne}} pour une passe.

    POURQUOI LA CLÉ N'INCLUT PAS LE CANTON, après une première version qui le
    faisait. Avec le canton dans la clé, une commune lue par les deux passes
    mais rattachée à deux cantons différents produit DEUX lignes exclusives, que
    la fusion compte comme deux gains et pose toutes les deux. Elle fabrique
    ainsi une commune multicantonale qui n'existe pas — et le canton est
    exactement ce que ce dépouillement vient chercher.

    Mesuré sur le fichier produit : **1 156 communes** (3,6 %) dont les deux
    lectures se contredisent sur le rattachement. Les vraies multicantonales,
    elles, sont 130 selon psm 6 et 202 selon psm 4.

    On regroupe donc par commune, et l'on compare les ENSEMBLES de cantons.
    """
    d = collections.defaultdict(dict)
    for r in csv.DictReader(chemin.open(encoding="utf-8")):
        d[(r["dep"], r["insee"])][r.get("canton", "")] = r
    return d


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--appliquer", action="store_true")
    args = ap.parse_args()

    presentes = [(n, f) for n, f in PASSES if f.exists()]
    if len(presentes) < 2:
        sys.exit("Il faut au moins deux passes sur disque.\n"
                 "Attendues : " + ", ".join(f.name for _, f in PASSES))
    for n, f in PASSES:
        if not f.exists():
            print(f"  passe `{n}` absente ({f.name}) — ignorée.")
    noms = [n for n, _ in presentes]
    n1 = noms[0]
    lect = {n: charge(f) for n, f in presentes}

    communes = sorted({k for d in lect.values() for k in d})
    fusion, desaccords = [], collections.Counter()
    compte_lignes, compte_communes = collections.Counter(), collections.Counter()

    for k in communes:
        # `vues` : {nom de passe -> {canton -> ligne}}, pour les seules passes
        # qui ont vu cette commune.
        vues = {n: lect[n][k] for n in noms if k in lect[n]}
        ens = {n: frozenset(v) for n, v in vues.items()}
        distincts = collections.Counter(ens.values())

        if len(vues) == 1:
            statut = next(iter(vues))
            retenu = set(next(iter(ens.values())))
            ecartes = set()

        elif len(distincts) == 1:
            # Toutes les passes présentes disent la même chose : le cas nominal.
            statut, retenu, ecartes = "accord", set(next(iter(distincts))), set()

        else:
            gros = max(distincts, key=len)
            if all(e <= gros for e in distincts):
                # L'un des ensembles contient tous les autres : profil d'une
                # multicantonale dont une passe a manqué une fraction.
                statut, retenu, ecartes = "fraction", set(gros), set()
            else:
                # LE VOTE MAJORITAIRE, possible à partir de TROIS lectures.
                #
                # À deux, un désaccord ne se tranche pas : on retenait la passe
                # prioritaire, arbitrairement, et 1 156 communes restaient en
                # `canton_conteste`. À trois, deux lectures qui concordent
                # contre une troisième donnent une majorité — et c'est un
                # arbitrage, pas un tirage au sort.
                #
                # Il reste un arbitrage FAIBLE : les trois lectures partagent
                # la même image et le même moteur, donc leurs erreurs sont
                # corrélées. Deux voix concordantes peuvent se tromper
                # ensemble. La colonne le dit — `majorite` n'est pas `accord`.
                tete = distincts.most_common()
                if len(tete) > 1 and tete[0][1] > tete[1][1]:
                    statut, retenu = "majorite", set(tete[0][0])
                    ecartes = {c for e, _ in tete[1:] for c in e} - retenu
                else:
                    # Égalité stricte : aucune majorité. On retient la passe
                    # prioritaire et l'on signale, comme avant.
                    statut = "canton_conteste"
                    premier = next(n for n in noms if n in vues)
                    retenu = set(ens[premier])
                    ecartes = {c for e in distincts for c in e} - retenu

        cantons = sorted(retenu)
        for c in cantons:
            r = next((vues[n][c] for n in noms if n in vues and c in vues[n]), None)
            if r is None:
                continue
            ligne = dict(r)
            ligne["accord"] = statut
            # Les écarts de champ se mesurent entre les passes qui portent
            # CETTE ligne — deux ou trois selon les cas.
            porteuses = [n for n in noms if n in vues and c in vues[n]]
            ecarts = []
            if len(porteuses) > 1:
                for x in COMPARES:
                    vals = {(vues[n][c].get(x) or "").strip() for n in porteuses}
                    if len(vals) > 1:
                        ecarts.append(x)
                        desaccords[x] += 1
            ligne["desaccord"] = "|".join(ecarts)
            ligne["canton_autre"] = "|".join(sorted(ecartes))
            ligne["lectures"] = str(len(porteuses))
            fusion.append(ligne)
        # COMPTER LES LIGNES ICI, ET RIEN D'AUTRE. La première version
        # incrémentait aussi `compte[statut]` dans les branches ci-dessus, si
        # bien que `canton_conteste` était compté deux fois — 2 319 annoncés
        # pour 1 156 communes réelles. Le chiffre a circulé dans JOURNAL.md, la
        # note et la mémoire avant d'être démenti par le fichier lui-même.
        # *Un compteur qui s'incrémente à deux endroits finit toujours par
        # mentir.* On compte une fois, à un seul endroit, et l'on distingue
        # explicitement les LIGNES des COMMUNES.
        compte_lignes[statut] += len(cantons)
        compte_communes[statut] += 1

    codes = {(l["dep"], l["insee"]) for l in fusion}

    for n, _ in presentes:
        la = sum(len(v) for v in lect[n].values())
        print(f"{n:<6} {la:>6} lignes, {len(lect[n]):>6} communes distinctes")
    meilleure = max(len(lect[n]) for n in noms)
    print(f"fusion {len(fusion):>6} lignes, {len(codes):>6} communes distinctes"
          f"   ({len(codes) - meilleure:+} sur la meilleure passe seule)\n")

    print(f"  {'statut':<18}{'communes':>10}{'lignes':>9}")
    ordre = ["accord", "fraction", "majorite", "canton_conteste"] + noms
    for st in ordre:
        if compte_communes[st]:
            print(f"  {st:<18}{compte_communes[st]:>10}{compte_lignes[st]:>9}")

    n_tot = max(len(communes), 1)
    print(f"\n  arbitré par MAJORITÉ (2 lectures contre 1)  "
          f"{compte_communes['majorite']:>6} communes "
          f"({compte_communes['majorite']/n_tot:.1%})")
    print(f"  CANTON CONTESTÉ, aucune majorité            "
          f"{compte_communes['canton_conteste']:>6} communes "
          f"({compte_communes['canton_conteste']/n_tot:.1%})")
    print(f"     -> retenu : lecture `{n1}` ; les autres sont en `canton_autre`.")
    print("     -> c'est le rattachement même que ce dépouillement cherche :")
    print("        ces lignes ne valent pas les autres et le disent.")

    if desaccords:
        print("\n  désaccords de champ entre passes portant la même ligne :")
        for c, n in desaccords.most_common():
            print(f"     {c:<10} {n:>6}")
        print(f"\n  Non tranchés : la valeur de `{n1}` est retenue, "
              "l'écart est signalé.")

    if not args.appliquer:
        print("\nÀ blanc. Relancer avec --appliquer.")
        return 0

    champs = list(fusion[0].keys())
    for c in ("accord", "desaccord", "canton_autre", "lectures"):
        if c not in champs:
            champs.append(c)
    with SORTIE.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=champs, extrasaction="ignore")
        w.writeheader()
        for l in fusion:
            w.writerows([{c: l.get(c, "") for c in champs}])

    print(f"\n{SORTIE.name} écrit — {len(fusion)} lignes.")
    print("Les deux fichiers d'entrée sont intacts.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
