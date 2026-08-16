#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
tableau2_1968.py — la recette de contrôle fournie par la source

    python3 cog1968/tableau2_1968.py --dep 02
    python3 cog1968/tableau2_1968.py --dep 02 --confronte

Produit `cog1968/tableau2_1968.csv` : un canton par ligne, avec son **nombre
de communes**.

Pourquoi c'est la pièce qui manquait
------------------------------------
L'extraction du tableau III (`extrait_1968.py`) lit 80 % des communes de
l'Aisne et retrouve 37 cantons — le compte exact de 1940. Mais elle ne peut
pas dire d'elle-même *combien* il en manque, ni *où*. Deux questions restent
ouvertes et aucun de ses garde-fous n'y répond :

* les 38 divergences avec 1940 sont-elles des erreurs d'OCR ou de vrais
  transferts de communes ?
* les 20 % de communes non lues sont-elles réparties au hasard, ou
  concentrées sur quelques cantons — auquel cas la composition de ceux-là
  serait fausse et non pas seulement incomplète ?

Le **tableau II** répond aux deux, parce qu'il donne le nombre de communes par
canton. C'est un contrôle que la source fournit elle-même, et 1954 ne l'avait
pas.

La structure, page 7 du fascicule de l'Aisne
--------------------------------------------
```
   Arrondissement de CHÂTEAU-THIERRY.
   (5 Cantons.)

   10.125   9.246  03  Charly ...............  19  10.171   9.460   9.551
   19.560  18.899  08  Château-Thierry ......  21  21.874  21.151  21.249
    7.067   7.322  10  Condé-en-Brie ........  27   7.340   7.039   7.040
    7.738   7.685  15  Fère-en-Tardenois ....  24   7.668   7.794   7.794
    6.566   5.415  23  Neuilly-Saint-Front ..  33   6.305   5.171   5.171
   53.566  51.567          TOTAL .............  124  55.638  53.615  53.805
```

Le nombre qui suit immédiatement le nom est **le nombre de communes**.
19 + 21 + 27 + 24 + 33 = 124, et la ligne TOTAL le confirme : la source porte
sa propre vérification.

Trois choses en sortent, dont deux qu'on n'était pas venu chercher :

* le **nombre de communes** par canton — le contrôle attendu ;
* le **nom du canton à la date**, que `unit_version` réclame et que le tableau
  III ne donne pas. Une carte de 1968 affichait jusqu'ici les libellés de 1999 ;
* le **nombre de cantons par arrondissement**, annoncé en toutes lettres
  (« 5 Cantons »), soit une seconde recette indépendante de la première.
"""

import argparse
import collections
import csv
import re
import sys
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(RACINE / "cog1954"))
from extrait_1954 import page_texte, nettoie_nom            # noqa: E402
sys.path.insert(0, str(RACINE / "cog1968"))
from extrait_1968 import index                              # noqa: E402

SORTIE = RACINE / "cog1968" / "tableau2_1968.csv"
LU = RACINE / "cog1968" / "communes_1968.csv"

# La page du tableau II se reconnaît à son titre. On cherche largement :
# l'OCR rend « Tableau II » aussi bien « Tableau JI » ou « Tableau Il ».
EST_TABLEAU2 = re.compile(r"arrondissements?\s+et\s+cantons", re.I)

# « Arrondissement de CHÂTEAU-THIERRY. » puis « (5 Cantons.) »
ARRONDISSEMENT = re.compile(
    r"arrondissement\s+d[eu']\s*(.{2,40}?)\s*\.?\s*$", re.I)
NB_CANTONS = re.compile(r"\(\s*(\d{1,2})\s*cantons?\s*\.?\s*\)", re.I)

# ---------------------------------------------------------------------------
# L'ancrage est NUMÉRIQUE, pas textuel — et c'est la leçon de cette page.
#
# Premier jet : chercher le nom du canton, puis les points de conduite, puis
# le nombre. Résultat, 1 canton sur 37. En cause, les points de conduite
# eux-mêmes : l'OCR les lit comme des lettres et emporte le nom avec.
#
#   « Ree ME TEIN ak ciaieveibier arta Ses k's S uack ve a iiha tei 20 24.645 »
#
# Le nom est illisible, le code souvent aussi. Mais la charpente chiffrée
# résiste intacte : deux populations de 1962 en tête, trois de 1968 en queue,
# et **entre les deux, juste avant les trois dernières, le nombre de
# communes**. On lit donc la ligne par ses nombres et on prend le nom en
# supplément quand il a survécu, jamais comme condition.
CANTON = re.compile(
    r"^\W*([\d][\d.,]{2,8})\s+([\d][\d.,]{2,8})\s+"   # populations 1962
    r"(.*?)"                                          # code et nom, souvent perdus
    r"(\d{1,3})\s+"                                  # NOMBRE DE COMMUNES
    r"([\d][\d.,]{2,8})\s+([\d][\d.,]{2,8})\s+([\d][\d.,]{2,8})\s*$")

# Le code, quand il a survécu, ouvre le fragment illisible.
CODE = re.compile(r"^\s*([\dOSlI]{2})\b")
# Le nom, quand il a survécu : au moins trois lettres d'affilée et une
# majuscule. En dessous, c'est du bruit de points de conduite.
NOM = re.compile(r"([A-ZÉÈÀÇŒ][A-Za-zÉÈÊËÀÂÎÏÔÛÙÇŒéèêëàâîïôûùç'’\-]{2,}"
                 r"(?:[- ][A-Za-zÉÈÀÇŒéèêëàâîïôûùç'’\-]{2,}){0,4})")

# Le mot « TOTAL » quand il a survécu. En français il survit presque toujours ;
# en anglais l'OCR le rend « PTA epee eis bites ». On garde les deux
# détecteurs — le mot d'abord, l'arithmétique en secours — parce qu'ils
# échouent pour des raisons différentes.
MOT_TOTAL = re.compile(r"\bT\s*[O0]\s*T\s*A\s*[LI]\b", re.I)

SOSIES = str.maketrans({"O": "0", "S": "5", "l": "1", "I": "1", "$": "3"})


def lit_tableau2(pdf, langue="fra", pages_max=16):
    """Les premières pages d'un fascicule -> les cantons du tableau II."""
    cantons, totaux, arr, nb_annonce = [], [], "", {}
    courant = collections.Counter()
    for p in range(1, pages_max + 1):
        txt = page_texte(pdf, p, langue=langue)
        if not EST_TABLEAU2.search(txt):
            continue
        for brut in txt.splitlines():
            s = brut.strip()
            if not s:
                continue
            m = ARRONDISSEMENT.search(s)
            if m and not CANTON.search(s):
                arr = nettoie_nom(m.group(1)).upper()
                continue
            m = NB_CANTONS.search(s)
            if m and arr:
                nb_annonce[arr] = int(m.group(1))
                continue
            m = CANTON.search(s)
            if not m:
                continue
            milieu, n = m.group(3), int(m.group(4))
            # La ligne TOTAL a la même charpente qu'une ligne de canton, et
            # son libellé est aussi illisible. On ne la reconnaît donc pas au
            # mot « TOTAL » — souvent rendu « PTA epee eis bites » — mais à
            # l'arithmétique : c'est celle dont le nombre égale la somme des
            # lignes du bloc en cours. La source se dénonce elle-même.
            if MOT_TOTAL.search(milieu) or (n == courant[arr] and courant[arr] > 0):
                totaux.append((arr, n))
                courant[arr] = 0
                continue
            c = CODE.search(milieu)
            nm = NOM.search(milieu)
            cantons.append(dict(
                page=p, arrondissement=arr,
                canton=c.group(1).translate(SOSIES) if c else "",
                nom=nettoie_nom(nm.group(1)).strip(" .") if nm else "",
                communes=n))
            courant[arr] += n
    return cantons, totaux, nb_annonce


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dep", required=True)
    ap.add_argument("--langue", default="fra")
    ap.add_argument("--confronte", action="store_true",
                    help="comparer au tableau III déjà extrait")
    a = ap.parse_args()

    idx = index()
    if a.dep not in idx:
        raise SystemExit(f"Département {a.dep} absent de l'index.")
    cantons, totaux, nb_annonce = lit_tableau2(idx[a.dep], a.langue)
    if not cantons:
        raise SystemExit("Aucune ligne de canton reconnue dans le tableau II.")

    for c in cantons:
        c["dep"] = a.dep
    with SORTIE.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["dep", "arrondissement", "canton",
                                          "nom", "communes", "page"])
        w.writeheader()
        w.writerows(sorted(cantons, key=lambda x: x["canton"]))

    somme = sum(c["communes"] for c in cantons)
    print(f"{len(cantons)} cantons lus, {somme} communes annoncées")
    print(f"{len({c['arrondissement'] for c in cantons})} arrondissements\n")

    # Recette n° 1, interne au tableau : la somme par arrondissement doit
    # tomber sur la ligne TOTAL que la source imprime elle-même.
    par_arr = collections.Counter()
    for c in cantons:
        par_arr[c["arrondissement"]] += c["communes"]
    print("recette 1 — somme des cantons contre la ligne TOTAL :")
    for arr, t in totaux:
        s = par_arr.get(arr, 0)
        print(f"   {arr[:26]:26s} lu {s:4d}   TOTAL imprimé {t:4d}"
              f"   {'OK' if s == t else '<-- ÉCART'}")

    # Recette n° 2, indépendante : « (5 Cantons.) » annoncé en toutes lettres.
    nb_lu = collections.Counter(c["arrondissement"] for c in cantons)
    if nb_annonce:
        print("\nrecette 2 — nombre de cantons annoncé en toutes lettres :")
        for arr, n in nb_annonce.items():
            print(f"   {arr[:26]:26s} lu {nb_lu.get(arr,0):3d}   annoncé {n:3d}"
                  f"   {'OK' if nb_lu.get(arr,0) == n else '<-- ÉCART'}")

    if a.confronte:
        if not LU.exists():
            raise SystemExit("\nLancer d'abord extrait_1968.py --dep " + a.dep)
        lu = [l for l in csv.DictReader(LU.open(encoding="utf-8"))
              if l["dep"] == a.dep and not l["hors_borne"]]
        vus = collections.Counter()
        for l in {(x["insee"], x["canton"]) for x in lu}:
            vus[l[1]] += 1
        print(f"\nCONFRONTATION AU TABLEAU III")
        print(f"  communes annoncées par le tableau II : {somme}")
        print(f"  communes lues au tableau III         : {sum(vus.values())}")
        print(f"  manquantes                           : "
              f"{somme - sum(vus.values())}\n")
        ecarts = []
        for c in sorted(cantons, key=lambda x: x["canton"]):
            v = vus.get(c["canton"], 0)
            if v != c["communes"]:
                ecarts.append((c["canton"], c["nom"], v, c["communes"]))
        print(f"  cantons au compte juste : "
              f"{len(cantons) - len(ecarts)}/{len(cantons)}")
        if ecarts:
            print("\n  canton  nom                        lu   attendu   écart")
            for code, nom, v, att in ecarts:
                print(f"    {code}    {nom[:26]:26s} {v:3d}   {att:3d}"
                      f"   {v-att:+4d}")
        print("\nUn canton au compte juste n'est pas pour autant exact : il "
              "pourrait\ncompter le bon nombre de communes fausses. Le compte "
              "est nécessaire,\npas suffisant.")
    print(f"\n{SORTIE}")


if __name__ == "__main__":
    main()
