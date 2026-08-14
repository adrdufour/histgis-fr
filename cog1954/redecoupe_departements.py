#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
redecoupe_departements.py — retrouver les frontières par l'ordre alphabétique

    python3 cog1954/redecoupe_departements.py

Corrige `cog1954/communes_1954.csv` sans refaire l'OCR : seule l'attribution
des départements est recalculée. Écrit `communes_1954_redecoupe.csv` et laisse
l'original intact.

Le problème
-----------
Lire le département dans l'en-tête de page échoue silencieusement sur les
départements dont le nom est un SURNOM d'un autre. « HAUTE-LOIRE » dont l'OCR
abîme une lettre du premier mot correspond encore à « LOIRE » — et la page est
attribuée AVEC CONFIANCE au département précédent. Rien ne le signale : ce
n'est pas une page muette, c'est un faux positif.

Quatre départements y ont disparu, tous de la même famille :

    43 Haute-Loire   absorbée par 42 Loire
    52 Haute-Marne   absorbée par 51 Marne
    74 Haute-Savoie  absorbée par 73 Savoie
    87 Haute-Vienne  absorbée par 86 Vienne

et deux autres par des causes voisines : 67 Bas-Rhin dans 66, 17 dans 16. La
Marne ressortait avec 806 communes pour 620 réelles.

Le signal qui ne ment pas
-------------------------
Les communes sont imprimées dans l'ordre alphabétique **à l'intérieur de
chaque département**. Un retour brutal de la fin de l'alphabet au début est
donc une frontière — et ce signal ne dépend ni de l'OCR de l'en-tête, ni du
nom du département, ni de sa lisibilité. Il est porté par la structure du
tableau, pas par le texte.

Vérifié : page 448 « RANTONSE -> AGNAT » (Agnat est en Haute-Loire), page 521
« WITRY-LÈS-REIMS -> ALLICHAMPS » (Haute-Marne), page 751 « YENNE ->
ABONDANCE » (Haute-Savoie), page 860 « YVERSAY -> AIXE-SUR-VIENNE »
(Haute-Vienne).

Comment les deux signaux sont combinés
--------------------------------------
Ni l'un ni l'autre seul. Les ruptures alphabétiques découpent le volume en
blocs ; les en-têtes lus nomment les blocs. Un bloc dont l'en-tête répète
celui du bloc précédent est un département que l'en-tête n'a pas su nommer :
il reçoit le code suivant dans la série, puisque le volume suit la
numérotation de 1954.

C'est le même principe que partout ailleurs dans ce projet : deux sources
faibles et indépendantes valent mieux qu'une source forte, parce que leurs
erreurs ne se recouvrent pas.
"""

import collections
import csv
import re
import sys
import unicodedata
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
LU = RACINE / "cog1954" / "communes_1954.csv"
SORTIE = RACINE / "cog1954" / "communes_1954_redecoupe.csv"
RAPPORT = RACINE / "cog1954" / "frontieres_1954.csv"


def norm(s):
    s = unicodedata.normalize("NFD", (s or "").upper())
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    return re.sub(r"[^A-Z]", "", s)


def sequence_1954():
    """Les codes de département dans l'ordre du volume."""
    ordre = [f"{i:02d}" for i in range(1, 20)] + ["20"]
    ordre += [f"{i:02d}" for i in range(21, 75)]
    ordre += ["75", "78O"]                       # Seine, puis Seine-et-Oise
    ordre += [f"{i:02d}" for i in range(76, 91)]
    return [d for d in ordre if d not in ("78",)]


def main():
    if not LU.exists():
        sys.exit(f"{LU} absent.")
    L = list(csv.DictReader(LU.open(encoding="utf-8")))
    L.sort(key=lambda l: int(l["page"]))
    print(f"{len(L)} lignes, "
          f"{len({l['dep'] for l in L if l['dep']})} départements avant redécoupe")

    # --- 1. les ruptures alphabétiques, page à page --------------------
    #
    # On ne compare pas ligne à ligne mais PAGE à PAGE : à l'intérieur d'une
    # page l'OCR intervertit des lignes, et chaque interversion produirait une
    # fausse frontière. D'une page à l'autre le désordre ne joue plus.
    par_page = collections.OrderedDict()
    for l in L:
        par_page.setdefault(int(l["page"]), []).append(l)

    pages = sorted(par_page)
    coupures = set()
    for i in range(1, len(pages)):
        prec = [norm(x["commune"]) for x in par_page[pages[i - 1]]]
        cour = [norm(x["commune"]) for x in par_page[pages[i]]]
        if not prec or not cour:
            continue
        # médiane des initiales plutôt que première et dernière : une seule
        # ligne mal lue ne doit pas décider d'une frontière.
        fin = sorted(c[:1] for c in prec if c)[len(prec) // 2:]
        deb = sorted(c[:1] for c in cour if c)[:max(1, len(cour) // 2)]
        if fin and deb and min(fin) >= "K" and max(deb) <= "E":
            coupures.add(pages[i])

    print(f"ruptures alphabétiques retenues : {len(coupures)} "
          f"(on attend une frontière par département)")

    # --- 2. blocs, puis nommage ----------------------------------------
    blocs, courant = [], []
    for p in pages:
        if p in coupures and courant:
            blocs.append(courant)
            courant = []
        courant.append(p)
    if courant:
        blocs.append(courant)

    # Un bloc minuscule n'est PAS un département. Sans ce filtre, une seule
    # ligne parasite lue dans les pages liminaires forme un bloc d'une commune,
    # consomme le code 01, et décale toute la série d'un cran : l'Ain devient
    # l'Aisne, sur quarante-trois départements. C'est le même mécanisme que le
    # garde-fou glouton abandonné la veille — une amorce fautive en tête qui
    # se propage — et la même parade : ne pas laisser une observation isolée
    # peser autant qu'un département entier.
    #
    # Le plus petit département de 1954 en compte plus de cent ; le seuil est
    # donc très large, il n'écarte que le bruit.
    MINI = 30
    fusionnes, attente, k = [], [], 0
    for b in blocs:
        if sum(len(par_page[p]) for p in b) < MINI:
            # Mis EN ATTENTE, pas conservé. Un bloc minuscule en tête de
            # volume ne doit surtout pas rester un bloc : c'était le défaut de
            # la première correction, et la série restait décalée.
            attente.extend(b)
            k += 1
            continue
        fusionnes.append(attente + b)
        attente = []
    if attente and fusionnes:
        fusionnes[-1].extend(attente)
    blocs = fusionnes
    print(f"blocs constitués : {len(blocs)}  ({k} blocs de moins de {MINI} "
          f"communes fusionnés — bruit, pas départements)")

    ordre = sequence_1954()
    attribue, rapport = {}, []
    precedent = None
    for k, bloc in enumerate(blocs):
        votes = collections.Counter(l["dep"] for p in bloc
                                    for l in par_page[p] if l["dep"])
        lu = votes.most_common(1)[0][0] if votes else None
        if lu and lu != precedent:
            dep, motif = lu, "en-tête"
        else:
            # L'en-tête répète le bloc précédent : département non nommé.
            # On prend le suivant dans la série de 1954.
            i = ordre.index(precedent) if precedent in ordre else -1
            dep = ordre[i + 1] if 0 <= i + 1 < len(ordre) else lu
            motif = "déduit de la série (en-tête absorbé)"
        for p in bloc:
            attribue[p] = dep
        rapport.append(dict(bloc=k, pages=f"{bloc[0]}-{bloc[-1]}",
                            communes=sum(len(par_page[p]) for p in bloc),
                            dep_entete=lu or "", dep_retenu=dep, motif=motif))
        precedent = dep

    for l in L:
        d = attribue.get(int(l["page"]))
        l["dep_avant"] = l["dep"]
        l["dep"] = d or l["dep"]

    with SORTIE.open("w", newline="", encoding="utf-8") as f:
        ch = [c for c in L[0] if c != "dep_avant"] + ["dep_avant"]
        w = csv.DictWriter(f, fieldnames=ch)
        w.writeheader()
        w.writerows(L)
    with RAPPORT.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(rapport[0]))
        w.writeheader()
        w.writerows(rapport)

    change = sum(1 for l in L if l["dep"] != l["dep_avant"])
    print(f"\n{len({l['dep'] for l in L})} départements après redécoupe, "
          f"{change} lignes réattribuées")
    dedu = [r for r in rapport if r["motif"].startswith("déduit")]
    print(f"{len(dedu)} blocs nommés par la série, faute d'en-tête lisible :")
    for r in dedu:
        print(f"   pages {r['pages']:>9s}  {r['communes']:4d} communes  "
              f"en-tête lu « {r['dep_entete']} » -> retenu {r['dep_retenu']}")
    print(f"\n{SORTIE}\n{RAPPORT}")


if __name__ == "__main__":
    main()
