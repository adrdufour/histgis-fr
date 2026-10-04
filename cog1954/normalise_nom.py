#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
normalise_nom.py — apparier un nom lu par l'OCR à une commune du référentiel

    from normalise_nom import variantes
    for v in variantes("St-Lary (Le)"):
        if v in ref_du_departement: ...

    python3 cog1954/normalise_nom.py --mesure     # rejoue la mesure ci-dessous

CE QUE CE MODULE A CORRIGÉ DANS LE DIAGNOSTIC
==============================================
Le 22 août 2026, `essai_troisieme_1954.py` comptait **215 « bruits »** sur trois
départements — des lignes acceptées par la grammaire dont le nom ne
correspondait à aucune commune. J'en avais conclu que « près de 40 % de ce que
la grammaire de 1954 accepte n'est pas une commune », et donc qu'il fallait la
RESSERRER.

**C'était faux.** En regardant les lignes une à une :

    fAiguillon (L')      ->  L'Aiguillon
    JArignac             ->  Arignac
    Puch (Le)            ->  Le Puch
    St-Lizier            ->  Saint-Lizier

Ce sont de vraies communes, mal NORMALISÉES. La grammaire est bonne ; c'est
l'appariement qui échouait. Avec les quatre règles ci-dessous, **83 % des 215
sont retrouvés** — 103 en correspondance exacte, 76 en flou — et les 36 restants
sont enfin du vrai bruit (`Cellcs`, `Scix`, `Mouiis`, lignes de nomenclature).

*J'ai pris trois fois de suite un défaut d'appariement pour un défaut de
lecture, puis pour un défaut de grammaire.*

LES QUATRE RÈGLES, TOUTES TIRÉES DE L'OBSERVATION
==================================================

1. **L'ARTICLE POSTPOSÉ.** Le volume écrit « Puch (Le) », « Bastide-de-Lordat
   (La) ». `nettoie_nom` le conserve tel quel, avec ce commentaire :

       « La remettre à l'endroit serait une interprétation, et la jointure
         sait déjà traiter l'article. »

   **La jointure ne le fait pas** : `cle()` produit `puchle` quand le
   référentiel porte `lepuch`. Une propriété affirmée dans un commentaire et
   jamais vérifiée — c'est probablement une bonne part des 7 576 orphelins de
   1954.

   On ne CHOISIT pas entre les deux formes : on essaie les DEUX. Le référentiel
   tranche, pas nous.

2. **SAINT ABRÉGÉ EN ST.** « St-Lizier », « Ste-Croix », « ST-GIRONS ». Les
   communes en Saint- font près d'un dixième des communes françaises : c'est le
   motif le plus rentable des quatre.

3. **LE CARACTÈRE PARASITE EN TÊTE.** « JArignac », « fAudressein »,
   « ÎCastillon » — le trait vertical du tableau, collé à l'initiale et lu comme
   une lettre. On essaie aussi le nom privé de son premier caractère.

4. **LA COMBINAISON DES TROIS.** « ÀSt-Paul-de-Jarrat » cumule parasite et
   abréviation ; les règles s'appliquent donc en cascade, pas isolément.

CE QUE CE MODULE NE FAIT PAS
============================
Il ne CHOISIT pas. Il produit la liste des formes à essayer, dans l'ordre du
plus sûr au moins sûr, et laisse l'appelant décider — en exact d'abord, en flou
ensuite. Un module qui trancherait ici cacherait le doute au lieu de le
transmettre.
"""

import re
import sys
import unicodedata

# L'article rejeté en fin de nom, entre parenthèses : la forme du volume.
ARTICLE = re.compile(r"^(.*?)\s*\((L[ae]s?|L')\)\s*$", re.I)

# « St », « Ste », « Sts », « Stes », avec ou sans point.
SAINT = re.compile(r"\bS(?:t|te|ts|tes)\b\.?", re.I)

_DEPLOIE = {"st": "Saint", "ste": "Sainte", "sts": "Saints", "stes": "Saintes"}


def cle(s):
    """Normalisation de comparaison : minuscules, sans accent ni ponctuation."""
    s = unicodedata.normalize("NFD", (s or "").lower())
    return "".join(c for c in s if c.isalnum())


def deploie_saint(nom):
    """« St-Lizier » -> « Saint-Lizier »."""
    return SAINT.sub(
        lambda m: _DEPLOIE.get(m.group(0).lower().rstrip("."), m.group(0)), nom)


def remet_article(nom):
    """« Puch (Le) » -> « Le Puch ». None si pas d'article postposé."""
    m = ARTICLE.match(nom.strip())
    if not m:
        return None
    a = m.group(2)
    return a + ("" if a.lower() == "l'" else " ") + m.group(1)


def variantes(nom, mini=4):
    """Les formes normalisées à essayer, sans doublon, ordre stable.

    L'ordre va du plus sûr au moins sûr : le nom tel quel d'abord, puis les
    reconstructions. L'appelant essaie en exact sur toute la liste avant de
    passer au flou — sans quoi une variante lointaine l'emporterait sur une
    correspondance exacte du nom d'origine.
    """
    formes = [nom]
    if SAINT.search(nom):
        formes.append(deploie_saint(nom))
    # Le caractère parasite en tête, et ses combinaisons.
    if len(nom) > 1 and not nom[1].isspace():
        formes.append(nom[1:])
        if SAINT.search(nom[1:]):
            formes.append(deploie_saint(nom[1:]))

    out = []
    for f in formes:
        for candidat in (f, remet_article(f)):
            if candidat is None:
                continue
            k = cle(candidat)
            if len(k) >= mini and k not in out:
                out.append(k)
    return out


# ---------------------------------------------------------------------------
# La mesure qui a justifié ce module, rejouable.
# ---------------------------------------------------------------------------
def _mesure():
    import collections
    import csv
    import difflib
    from pathlib import Path
    RACINE = Path(__file__).resolve().parent.parent
    sys.path.insert(0, str(RACINE / "cog1954"))
    from extrait_1954 import LIGNE, RENVOI, TOTAUX, nettoie_nom

    ref = collections.defaultdict(set)
    for r in csv.DictReader((RACINE / "build" / "noms_geofla.csv")
                            .open(encoding="utf-8")):
        ref[r["insee"].strip()[:2]].add(cle(r["nom"]))
    n54 = RACINE / "cog1954" / "noms_1954.csv"
    if n54.exists():
        for r in csv.DictReader(n54.open(encoding="utf-8")):
            if r["nom"].strip():
                ref[r["code"][:2]].add(cle(r["nom"]))
    else:
        print("noms_1954.csv absent — jouer sql/65_noms_1954.sql.\n")

    DEPS = {"09": range(147, 154), "34": range(378, 385), "90": range(886, 937)}
    avant = exact = flou = 0
    reste = []
    for dep, pages in DEPS.items():
        for p in pages:
            f = RACINE / "cog1954" / "ocr_brut" / f"p{p:04d}.txt"
            if not f.exists():
                continue
            for brut in f.read_text(encoding="utf-8", errors="replace").splitlines():
                s = brut.strip()
                if not s or RENVOI.search(s) or TOTAUX.search(s):
                    continue
                m = LIGNE.search(s)
                if not m:
                    continue
                nom = nettoie_nom(m.group(3))
                if len(cle(nom)) < 4 or cle(nom) in ref[dep]:
                    continue
                avant += 1
                vs = variantes(nom)
                if any(v in ref[dep] for v in vs):
                    exact += 1
                elif any(difflib.get_close_matches(v, ref[dep], n=1, cutoff=0.85)
                         for v in vs):
                    flou += 1
                else:
                    reste.append((dep, nom))

    print(f"noms non appariés par `cle()` seule   {avant}")
    print(f"   retrouvés en correspondance exacte {exact}")
    print(f"   retrouvés en flou (0,85)           {flou}")
    print(f"   restants — du vrai bruit           {len(reste)}")
    print(f"\n   TAUX DE RÉCUPÉRATION              "
          f"{(exact + flou) / max(avant, 1):.0%}")
    print("\n   les 12 premiers restants :")
    for d, n in reste[:12]:
        print(f"      {d}  « {n[:40]} »")


if __name__ == "__main__":
    if "--mesure" in sys.argv:
        _mesure()
    else:
        for essai in ("St-Lizier", "Puch (Le)", "JArignac", "ÀSt-Paul-de-Jarrat",
                      "Bastide-de-Lordat (La)", "Aulus-les-Bains"):
            print(f"{essai:<26} -> {variantes(essai)}")
