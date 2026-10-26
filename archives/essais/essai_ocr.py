#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
essai_ocr.py — quelle chaîne de lecture rend le plus de communes JUSTES ?

    python3 archives/essais/essai_ocr.py --dep 79
    python3 archives/essais/essai_ocr.py --dep 79 --grille long
    python3 archives/essais/essai_ocr.py --dep 79 --meilleures   # pour comparer

Pourquoi
--------
Le rappel de 1968 plafonne à 83,4 %, et la perte n'est plus dans la grammaire :
aux Deux-Sèvres, 258 lignes acceptées, 15 rejetées, 352 communes attendues. Les
94 manquantes **n'ont jamais produit de ligne** — l'OCR les a détruites au point
que même la signature « arrondissement, canton, code » a disparu.

La chaîne de lecture n'a jamais été mise à l'épreuve. Elle a été écrite pour
1954, reprise telle quelle pour 1968, et trois de ses paramètres n'ont jamais
bougé : **300 dpi**, **`--psm 6`**, et aucun prétraitement d'image.

Ce script les fait varier un à un et mesure.

Ce qu'il mesure, et pourquoi pas le nombre de lignes
-----------------------------------------------------
Compter les lignes acceptées récompenserait une chaîne qui produit du bruit
passant la grammaire. On compte donc les **codes INSEE distincts qui existent
réellement** dans le département selon `noms_geofla` — une ligne inventée n'y
contribue pas.

Deux colonnes en découlent :

  `justes`   codes distincts reconnus ET réels — c'est le chiffre à maximiser ;
  `faux`     codes lus qui n'existent pas dans le département — le bruit.

Une variante qui gagne 20 justes en gagnant 20 faux n'a rien gagné.

Le témoin
---------
La première ligne du tableau est **toujours** la chaîne actuelle — 300 dpi,
psm 6, sans prétraitement. Les autres se lisent par rapport à elle. Sans témoin
dans le même tableau, un gain n'est qu'un chiffre.
"""

import argparse
import collections
import csv
import re
import subprocess
import sys
import tempfile
import time
from pathlib import Path

RACINE = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(RACINE / "cog1954"))
sys.path.insert(0, str(RACINE / "cog1968"))
from extrait_1968 import LIGNE, EXCLUS, index, SOSIES_1968   # noqa: E402

NOMS = RACINE / "build" / "noms_geofla.csv"

# Les variantes. `pre` est une chaîne d'options ImageMagick appliquée à l'image
# avant tesseract ; None signifie « pas de prétraitement », le cas actuel.
#
# Chaque variante ne bouge qu'UNE chose par rapport à la précédente, pour que le
# gain soit attribuable. C'est la discipline qui a permis d'attribuer, en août
# 2026, +10 points à la grammaire et +2,8 à la langue française.
VARIANTES_COURT = [
    ("actuel   300 psm6",      300, "6",  None),
    ("400 dpi",                400, "6",  None),
    ("600 dpi",                600, "6",  None),
    ("psm 4 (colonne)",        300, "4",  None),
]

# Grille resserrée autour de --psm, une fois la mesure faite sur trois
# départements : psm 4 gagne dans les trois (+28, +37, +32), la résolution non
# (400 dpi : +30, +5, +25 — erratique). On explore donc le MODE DE SEGMENTATION,
# qui est ce qui a répondu, et non le dpi, qui est ce que j'avais parié.
#
#   4  une colonne de texte de tailles variables   <- le gagnant
#   6  un bloc uniforme                            <- l'actuel
#  11  texte épars, sans ordre
#  12  texte épars avec détection d'orientation
# La grille du verdict : le témoin et le seul prétendant qui ait gagné sur les
# trois départements. Deux variantes seulement, pour pouvoir passer TOUTES les
# pages d'un fascicule en un temps raisonnable.
VARIANTES_VERDICT = [
    ("actuel   300 psm6",      300, "6",  None),
    ("psm 4 (colonne)",        300, "4",  None),
]

VARIANTES_PSM = [
    ("actuel   300 psm6",      300, "6",  None),
    ("psm 4 (colonne)",        300, "4",  None),
    ("400 + psm 4",            400, "4",  None),
    ("psm 11 (épars)",         300, "11", None),
    ("psm 12 (épars + osd)",   300, "12", None),
]

VARIANTES_LONG = VARIANTES_COURT + [
    ("400 + psm 4",            400, "4",  None),
    ("400 + seuil",            400, "6",  "-colorspace Gray -normalize -threshold 60%"),
    ("400 + netteté",          400, "6",  "-colorspace Gray -unsharp 0x1"),
    ("400 + seuil + psm 4",    400, "4",  "-colorspace Gray -normalize -threshold 60%"),
    ("600 + seuil",            600, "6",  "-colorspace Gray -normalize -threshold 60%"),
]


def pages_de(spec):
    out = []
    for bloc in spec.split(","):
        if "-" in bloc:
            a, b = bloc.split("-")
            out.extend(range(int(a), int(b) + 1))
        else:
            out.append(int(bloc))
    return out


def lit(pdf, page, dpi, psm, pre, langue="fra"):
    with tempfile.TemporaryDirectory() as tmp:
        base = Path(tmp) / "pg"
        subprocess.run(["pdftoppm", "-r", str(dpi), "-gray", "-f", str(page),
                        "-l", str(page), "-png", str(pdf), str(base)],
                       check=True, capture_output=True)
        img = next(Path(tmp).glob("pg*.png"), None)
        if img is None:
            return ""
        if pre:
            cible = Path(tmp) / "pre.png"
            outil = "magick" if which("magick") else "convert"
            subprocess.run([outil, str(img)] + pre.split() + [str(cible)],
                           check=True, capture_output=True)
            img = cible
        r = subprocess.run(["tesseract", str(img), "-", "-l", langue,
                            "--psm", psm],
                           capture_output=True, text=True)
        return r.stdout


def rendement(dep):
    """{page: communes lues} d'après l'extraction en place."""
    src = RACINE / "cog1968" / "communes_1968.csv"
    if not src.exists():
        return {}
    n = collections.Counter()
    for r in csv.DictReader(src.open(encoding="utf-8")):
        if r["dep"] == dep and r.get("page"):
            n[int(r["page"])] += 1
    return n


def pages_a_tester(dep, combien=4, pires=True):
    """Les pages sur lesquelles il y a quelque chose à gagner.

    DEUX PIÈGES SUCCESSIFS, tous deux commis le 22 août 2026.

    Le premier : choisir les pages à la main. Lancé sur les pages 12 à 15 des
    Deux-Sèvres, où il n'y a aucun tableau, le banc rendait zéro partout — y
    compris pour le témoin. *Un banc d'essai qui rend zéro pour le témoin ne
    mesure rien.*

    Le second, plus insidieux : choisir les pages les PLUS productives. Ce sont
    par construction celles que la chaîne actuelle lit déjà bien — 95 % de
    réussite mesurée — et aucune variante ne pouvait y gagner. **Je testais le
    remède là où il n'y a pas de maladie.**

    On prend donc par défaut les pages les PLUS FAIBLES du fascicule, celles où
    la marge existe. Le témoin y sera bas, et c'est le but.
    """
    n = rendement(dep)
    if not n:
        return []
    ordonnees = sorted(n.items(), key=lambda kv: kv[1], reverse=not pires)
    return sorted(p for p, _ in ordonnees[:combien])


def toutes_les_pages(dep):
    """Toutes les pages de tableau du fascicule, y compris les MUETTES.

    Angle mort de `pages_a_tester`, repéré le 22 août 2026 : une page qui n'a
    rendu AUCUNE commune n'écrit aucune ligne dans `communes_1968.csv`, donc
    n'apparaît pas dans `rendement()`. En classant les pages par rendement
    croissant, je ne voyais que celles qui avaient au moins parlé une fois —
    **les pires pages du fascicule m'étaient invisibles par construction.**

    On prend donc l'étendue min..max des pages connues : une page muette au
    milieu du tableau y figure, une page hors tableau ne rendra rien pour
    aucune variante et ne fausse donc pas la comparaison.
    """
    n = rendement(dep)
    if not n:
        return []
    return list(range(min(n), max(n) + 1))


def which(x):
    from shutil import which as w
    return w(x)


def codes(texte, dep):
    """Les codes INSEE que cette lecture rend, une fois la grammaire passée."""
    out = set()
    for brut in texte.splitlines():
        if EXCLUS.search(brut):
            continue
        m = LIGNE.search(brut.strip())
        if m:
            out.add(dep + m.group(5))
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--dep", required=True)
    ap.add_argument("--pages", help="ex. 12-15 ; par défaut, les pages les plus "
                                    "productives d'après communes_1968.csv")
    ap.add_argument("--langue", default="fra")
    ap.add_argument("--grille", choices=("court", "long", "psm", "verdict"),
                    default="court")
    ap.add_argument("--toutes", action="store_true",
                    help="toutes les pages du fascicule, muettes comprises")
    ap.add_argument("--meilleures", action="store_true",
                    help="tester sur les pages les mieux lues (par défaut : "
                         "les plus faibles, là où il y a à gagner)")
    args = ap.parse_args()

    reels = {r["insee"].strip() for r in csv.DictReader(NOMS.open(encoding="utf-8"))
             if r["insee"].strip().startswith(args.dep)}
    if not reels:
        sys.exit(f"Aucune commune du département {args.dep} dans {NOMS}.")

    fasc = index()
    if args.dep not in fasc:
        sys.exit(f"Département {args.dep} absent de l'index.")
    pdf = fasc[args.dep]
    if args.pages:
        pages = pages_de(args.pages)
    elif args.toutes:
        pages = toutes_les_pages(args.dep)
    else:
        pages = pages_a_tester(args.dep, pires=not args.meilleures)
    if not pages:
        sys.exit("Aucune page de tableau trouvée : préciser --pages.")

    variantes = {"court": VARIANTES_COURT, "long": VARIANTES_LONG,
                 "psm": VARIANTES_PSM, "verdict": VARIANTES_VERDICT}[args.grille]
    if any(v[3] for v in variantes) and not (which("magick") or which("convert")):
        print("ImageMagick absent : les variantes avec prétraitement seront sautées.\n")

    print(f"département {args.dep} — pages {','.join(map(str, pages))} — "
          f"{len(reels)} communes au référentiel")
    if args.toutes:
        n = rendement(args.dep)
        muettes = [p for p in pages if p not in n]
        print(f"  (TOUTES les pages du fascicule ; {len(muettes)} muettes "
              f"à l'extraction actuelle : {muettes or 'aucune'})")
    elif not args.pages:
        quoi = "les mieux lues" if args.meilleures else "LES PLUS FAIBLES"
        n = rendement(args.dep)
        detail = ", ".join(f"p{p}:{n[p]}" for p in pages)
        print(f"  (pages {quoi} du fascicule — {detail})")
    print()
    print(f"{'variante':<24}{'justes':>8}{'faux':>7}{'secondes':>10}")
    print("-" * 49)

    ref_justes = None
    for nom, dpi, psm, pre in variantes:
        if pre and not (which("magick") or which("convert")):
            continue
        t0 = time.time()
        vus = set()
        try:
            for p in pages:
                vus |= codes(lit(pdf, p, dpi, psm, pre, args.langue), args.dep)
        except subprocess.CalledProcessError as e:              # noqa: BLE001
            print(f"{nom:<24}   échec ({e})")
            continue
        justes = len(vus & reels)
        faux = len(vus - reels)
        if ref_justes is None:
            ref_justes = justes
            ecart = ""
        else:
            ecart = f"  {justes - ref_justes:+d}"
        print(f"{nom:<24}{justes:>8}{faux:>7}{time.time()-t0:>9.0f}s{ecart}")

    print("\nLire la colonne `justes` — et refuser un gain payé en `faux`.")
    print("Le témoin est la première ligne : la chaîne actuellement en service.")
    print("\nSi une variante gagne nettement, la porter dans")
    print("`cog1954/extrait_1954.py` (fonction `page_texte`) : 1954 en profitera")
    print("aussi, puisque 1968 importe sa chaîne au lieu de la recopier.")


if __name__ == "__main__":
    main()
