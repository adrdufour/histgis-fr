#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
essai_grammaire.py — la grammaire élargie gagne-t-elle plus qu'elle ne coûte ?

    python3 cog1968/essai_grammaire.py --dep 45
    python3 cog1968/essai_grammaire.py --dep 45 --dep 10 --dep 54 --dep 21

Le défaut mesuré
----------------
19 grandes villes sur 53 manquent au recensement — **36 %, contre 8,6 % pour
l'ensemble des communes**. Nice, Nantes, Bordeaux, Strasbourg, Metz, Nancy,
Orléans, Troyes, Dunkerque…

La cause est visible dans les lignes rejetées :

    KO  2 22 234 ORLÉANS : Canton Ouest.      8.901 …
    KO  2 25 234 | Canton Sud (1).           18.537 …
    ok  3 24 387 TROYES ) 3* Canton (1).     31.741 …

Une ville multicantonale occupe une ligne PAR CANTON. Une seule porte son nom ;
les autres portent une accolade et le libellé du canton. Et ces lignes-là
portent quand même **l'arrondissement, le canton et le code de commune** —
c'est-à-dire tout ce qu'un rattachement demande. Le nom ne sert qu'au contrôle.

Deux échecs distincts, et aucun n'est une exclusion
---------------------------------------------------
`lignes_rejetees.py` les étiquette « ligne de total » parce qu'elles contiennent
le mot *Canton*. C'est l'étiquette du diagnostic, pas la cause : `EXCLUS` ne
retient que `total|ensemble`. **Ces lignes ne sont pas exclues, elles ne sont
pas reconnues.**

  1. `ORLÉANS : Canton Ouest` — le DEUX-POINTS n'est pas dans la classe de
     caractères du nom, alors que `)` y est. D'où l'asymétrie avec Troyes.
  2. `| 1er Canton` — la grammaire exige une INITIALE ALPHABÉTIQUE et trouve
     une accolade.

Ce que ce banc mesure
---------------------
Deux colonnes, et c'est la SECONDE qui décide :

  `communes`   codes INSEE distincts et réels — le rappel, qui bougera peu ;
  `rattach.`   paires commune-canton distinctes — **ce que le dossier cherche** ;
  `faux`       codes lus qui n'existent pas dans le département.

Une ville multicantonale vaut UN code et PLUSIEURS cantons. Troyes, déjà lue par
sa troisième ligne, ne gagne aucun code en gagnant deux cantons. Un premier
banc comptait les codes et rendait +4 sur 2 576 : un chiffre exact qui ne
mesurait pas le remède. *Écrire ce qu'on veut mesurer ne suffit pas — il faut
vérifier que le compteur le mesure.*

La première ligne est toujours la grammaire en service.

**Un élargissement de grammaire se paie toujours en bruit.** Accepter une
initiale non alphabétique ouvre la porte à n'importe quelle ligne de tableau.
La variante 2 exige donc le mot « canton » dans la ligne : elle ne s'applique
qu'au motif qu'elle vise.

L'ÉCHANTILLON, choisi avec ses deux moitiés
-------------------------------------------
Le 22 août 2026, j'ai mesuré trois fois de suite un remède sur des cas choisis
pour être malades, et conclu trois fois de travers. On teste donc à la fois des
départements dont la préfecture MANQUE (là où le gain doit apparaître) et des
départements bien lus (là où le bruit doit rester nul). Un gain qui coûterait
des `faux` ailleurs ne serait pas un gain.

    manquantes : 45 Orléans, 10 Troyes, 54 Nancy, 44 Nantes
    saines     : 21 Côte-d'Or, 50 Manche, 32 Gers
"""

import argparse
import collections
import csv
import re
import sys
import time
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(RACINE / "cog1954"))
sys.path.insert(0, str(RACINE / "cog1968"))
from extrait_1968 import LIGNE, EXCLUS, index, PSM        # noqa: E402
from extrait_1954 import page_texte                        # noqa: E402

NOMS = RACINE / "build" / "noms_geofla.csv"

# --- variante 1 : le deux-points et les barres, ajoutés à la classe du nom ---
#
# On reprend le motif en service et l'on n'ajoute QUE des caractères à la classe
# du nom. Rien d'autre ne bouge : c'est ce qui rend le gain attribuable.
LIGNE_PONCT = re.compile(
    LIGNE.pattern.replace(
        r"'’\-\.\s(){}*]{2,54}?)",
        r"'’\-\.\s(){}*:|\\/]{2,54}?)"))

# --- variante 2 : la ligne de continuation d'une ville multicantonale --------
#
# Pas d'initiale alphabétique exigée, mais le mot « canton » OBLIGATOIRE. Le
# nom n'est pas capturé : il n'existe pas sur ces lignes, et l'inventer serait
# pire que de le laisser vide. Le code INSEE suffit au rattachement.
#
# Le préfixe autorise les CHIFFRES : « 1er Canton », « 3* Canton ». Une première
# version l'interdisait (`[^\d]`) par crainte d'avaler les colonnes de
# population — et rejetait du même coup tous les cantons numérotés, c'est-à-dire
# le cas le plus fréquent dans les grandes villes. Le préfixe est donc borné à
# 14 caractères et le code INSEE l'ancre à gauche : les populations sont hors
# d'atteinte.
LIGNE_SUITE = re.compile(
    r"(?:(\d[\d.\s]{0,9}?)\s+(\d[\d.\s]{0,9}?)\s+)?"
    r"([\dOSlI])\s+"                     # arrondissement
    r"([\dOSlI$]{2})\s+"                 # canton
    r"(\d{3})\s+"                        # code INSEE
    r"([^.]{0,14}?\bcantons?\b[^.]{0,24})"  # « | 1er Canton », « ) 3* Canton »
    r"\s*[.,]\s+"
    r"(\d[\d.]*)", re.I)


SOSIE_CHIFFRE = str.maketrans({"O": "0", "S": "5", "l": "1", "I": "1", "$": "5"})


def codes(texte, dep, motifs):
    """{(code INSEE, canton)} que ces motifs tirent d'une page.

    ON COMPTE LES PAIRES, PAS LES CODES — corrigé après un premier banc qui
    mesurait la mauvaise chose.

    Ce correctif de grammaire vise les lignes de continuation des villes
    multicantonales. Or une ville vaut UN code même quand elle occupe trois
    lignes : Troyes, déjà lue par sa troisième ligne, ne gagne aucun code en
    gagnant deux cantons. Compter les codes distincts rend donc un gain
    dérisoire (+4 sur 2 576) qui ne dit rien de ce qui est réellement récupéré.

    J'avais annoncé cette limite dans le même message que celui où je proposais
    le banc, puis construit le banc qui l'ignorait. *Écrire ce qu'on veut
    mesurer ne suffit pas : il faut vérifier que le compteur le mesure.*
    """
    out = set()
    for brut in texte.splitlines():
        if EXCLUS.search(brut):
            continue
        s = brut.strip()
        for m in motifs:
            r = m.search(s)
            if r:
                out.add((dep + r.group(5),
                         r.group(4).translate(SOSIE_CHIFFRE)))
                break
    return out


def pages_du_dep(dep):
    src = RACINE / "cog1968" / "communes_1968_fusion.csv"
    n = collections.Counter()
    for r in csv.DictReader(src.open(encoding="utf-8")):
        if r["dep"] == dep and r.get("page"):
            n[int(r["page"])] += 1
    return list(range(min(n), max(n) + 1)) if n else []


VARIANTES = [
    ("actuelle (témoin)",        [LIGNE]),
    ("+ deux-points",            [LIGNE, LIGNE_PONCT]),
    ("+ ligne de continuation",  [LIGNE, LIGNE_SUITE]),
    ("les deux",                 [LIGNE, LIGNE_PONCT, LIGNE_SUITE]),
]


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--dep", action="append", required=True,
                    help="répétable : --dep 45 --dep 21")
    args = ap.parse_args()

    reels = collections.defaultdict(set)
    for r in csv.DictReader(NOMS.open(encoding="utf-8")):
        reels[r["insee"].strip()[:2]].add(r["insee"].strip())

    fasc = index()
    total = collections.Counter()

    for dep in args.dep:
        if dep not in fasc:
            print(f"département {dep} absent de l'index — sauté.")
            continue
        pages = pages_du_dep(dep)
        if not pages:
            print(f"département {dep} : aucune page connue — sauté.")
            continue

        # UNE SEULE PASSE D'OCR, réutilisée par toutes les variantes. C'est ce
        # qui rend la comparaison honnête : le texte est rigoureusement le même,
        # seule la grammaire change.
        t0 = time.time()
        textes = [page_texte(fasc[dep], p, psm=PSM) for p in pages]
        print(f"\ndépartement {dep} — {len(pages)} pages lues en "
              f"{time.time()-t0:.0f}s — {len(reels[dep])} communes au référentiel")
        print(f"{'grammaire':<28}{'communes':>8}{'rattach.':>10}"
              f"{'faux':>7}{'écart':>8}")
        print("-" * 61)

        ref = None
        for nom, motifs in VARIANTES:
            vus = set()
            for t in textes:
                vus |= codes(t, dep, motifs)
            # `justes` compte les COMMUNES réelles reconnues ; `ratt` compte
            # les RATTACHEMENTS commune-canton, qui sont l'objet du dossier.
            vrais = {(c, ct) for c, ct in vus if c in reels[dep]}
            justes = len({c for c, _ in vrais})
            ratt = len(vrais)
            faux = len({c for c, _ in vus if c not in reels[dep]})
            if ref is None:
                ref, ecart = ratt, ""
            else:
                ecart = f"{ratt - ref:+d}"      # l'écart porte sur les RATTACHEMENTS
            total[nom + "|justes"] += justes
            total[nom + "|ratt"] += ratt
            total[nom + "|faux"] += faux
            print(f"{nom:<28}{justes:>8}{ratt:>10}{faux:>7}{ecart:>8}")

    if len(args.dep) > 1:
        print(f"\n{'TOTAL sur ' + str(len(args.dep)) + ' départements':<28}"
              f"{'communes':>8}{'rattach.':>10}{'faux':>7}{'écart':>8}")
        print("-" * 61)
        ref = None
        for nom, _ in VARIANTES:
            j, r, f = (total[nom + "|justes"], total[nom + "|ratt"],
                       total[nom + "|faux"])
            if ref is None:
                ref, ecart = r, ""
            else:
                ecart = f"{r - ref:+d}"
            print(f"{nom:<28}{j:>8}{r:>10}{f:>7}{ecart:>8}")

    print("\nL'écart porte sur les RATTACHEMENTS, pas sur les communes :")
    print("une ville multicantonale vaut un seul code et plusieurs cantons,")
    print("et c'est le canton que le trou 1943-1999 réclame.")
    print("\nLire `rattach.` ET `faux`. Un élargissement de grammaire se paie")
    print("toujours en bruit ; la question est de savoir combien.")
    print("Et regarder les départements SAINS autant que les malades :")
    print("c'est là que le coût apparaît, pas le gain.")


if __name__ == "__main__":
    main()
