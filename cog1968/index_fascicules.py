#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
index_fascicules.py — quel fascicule de 1968 est quel département ?

    python3 cog1968/index_fascicules.py

Produit `cog1968/fascicules_1968.csv` : ark, département, code, pages, doublons.

Pourquoi ce script existe
-------------------------
Les fascicules arrivent sous leur identifiant ark — `bd6t5358309b.pdf` — sans
rien dans le nom qui dise de quel département il s'agit. Or toute la suite en
dépend : `extrait_1968.py --dep NN` a besoin de savoir où chercher, et le
contrôle par le tableau II se fait département par département.

**La bonne nouvelle, mesurée le 15 août 2026** : les PDF portent une couche
texte partielle. Elle ne couvre PAS les tableaux — ceux-là sont des images
nues, et l'OCR reste à faire comme pour 1954 — mais elle couvre les
liminaires, page de titre comprise. Le département y est lisible sans OCR.

Le piège du sous-mot, rencontré ici pour la troisième fois
----------------------------------------------------------
Premier jet : comparer des chaînes normalisées sans accents ni ponctuation.
« Ain » devient `ain`, trois lettres qui se trouvent dans `certAINes`,
`AINsi`, `prochAIN`, `mAIN`. Résultat : 40 fascicules sur 83 attribués à l'Ain.

C'est exactement le défaut mesuré faux dans le parseur de 1954 — « le
département en sous-chaîne » — et retrouvé ici sous une autre forme. La
normalisation qui aplatit tout rend les noms comparables ET les rend
confusibles ; c'est le même geste qui produit les deux effets.

**Le correctif est la frontière de mot**, posée sur un texte dont on a retiré
les accents mais gardé les séparateurs. Les séparateurs internes restent
libres, parce que l'OCR met une espace là où le nom porte un tiret :
`basses[\\s\\-']*alpes` attrape « BASSES-ALPES » comme « BASSES  ALPES ».

Deux pièges de plus, mesurés et non devinés
--------------------------------------------
**« Paris » est le lieu d'impression de tous les fascicules.** Compter les
occurrences le fait donc sortir en second partout, avec des marges de 1,0 à
1,3 qui ne décident de rien. Une fréquence brute ne distingue pas un nom de
département d'un nom de ville d'édition.

**Un nom court est le préfixe d'un nom long.** « Loire » se trouve dans
« Loire-Atlantique », « Tarn » dans « Tarn-et-Garonne », « Indre » dans
« Indre-et-Loire », « Eure » dans « Eure-et-Loir », « Charente » dans
« Charente-Maritime ». La frontière de mot ne suffit pas : après « loire »
vient un tiret, pas une lettre.

**Et « le plus long d'abord » ne suffit pas non plus s'il s'applique au
document entier** : il suffit qu'un fascicule cite un département voisin dans
une phrase « DÉPARTEMENT DE … » pour que ce voisin l'emporte, parce que son
nom est plus long. C'est ainsi que l'Ain a disparu de l'index à l'essai
suivant. Le classement par longueur doit jouer **à position égale**, pas entre
deux endroits différents du texte.

D'où la règle retenue :

1. une **alternation unique** de tous les noms, ordonnée du plus long au plus
   court. Une alternation Python choisit la première branche qui tombe *à la
   position courante* : la préférence pour le nom long joue donc là où elle
   doit, et nulle part ailleurs ;
2. on cherche cette alternation précédée de **« DÉPARTEMENT DE »**, on compte
   toutes les occurrences, et **le plus fréquent gagne** — un voisin cité une
   fois ne bat pas le département du fascicule cité dix fois ;
3. à défaut de toute phrase, la fréquence du nom seul, **Paris exclu**.

Chaque attribution sort avec sa méthode et sa marge, afin qu'on puisse juger
sur pièces plutôt que sur un total.
"""

import argparse
import collections
import csv
import re
import subprocess
import unicodedata
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
FASCICULES = RACINE / "sources" / "rp1968"
SORTIE = RACINE / "cog1968" / "fascicules_1968.csv"

# Les 95 départements métropolitains dans le découpage de 1968, c'est-à-dire
# APRÈS le démembrement de la Seine et de la Seine-et-Oise (1964) et AVANT les
# renommages de 1969-1970. D'où « Basses-Alpes » et non Alpes-de-Haute-Provence
# (renommé en 1970), « Basses-Pyrénées » et non Pyrénées-Atlantiques (1969),
# « Côtes-du-Nord » (Côtes-d'Armor en 1990), et une Corse encore indivise
# (2A/2B en 1976). Le jeu d'alias diffère donc de celui de 1954.
DEPARTEMENTS = {
    "01": "Ain", "02": "Aisne", "03": "Allier", "04": "Basses-Alpes",
    "05": "Hautes-Alpes", "06": "Alpes-Maritimes", "07": "Ardèche",
    "08": "Ardennes", "09": "Ariège", "10": "Aube", "11": "Aude",
    "12": "Aveyron", "13": "Bouches-du-Rhône", "14": "Calvados",
    "15": "Cantal", "16": "Charente", "17": "Charente-Maritime", "18": "Cher",
    "19": "Corrèze", "20": "Corse", "21": "Côte-d'Or", "22": "Côtes-du-Nord",
    "23": "Creuse", "24": "Dordogne", "25": "Doubs", "26": "Drôme",
    "27": "Eure", "28": "Eure-et-Loir", "29": "Finistère", "30": "Gard",
    "31": "Haute-Garonne", "32": "Gers", "33": "Gironde", "34": "Hérault",
    "35": "Ille-et-Vilaine", "36": "Indre", "37": "Indre-et-Loire",
    "38": "Isère", "39": "Jura", "40": "Landes", "41": "Loir-et-Cher",
    "42": "Loire", "43": "Haute-Loire", "44": "Loire-Atlantique",
    "45": "Loiret", "46": "Lot", "47": "Lot-et-Garonne", "48": "Lozère",
    "49": "Maine-et-Loire", "50": "Manche", "51": "Marne", "52": "Haute-Marne",
    "53": "Mayenne", "54": "Meurthe-et-Moselle", "55": "Meuse",
    "56": "Morbihan", "57": "Moselle", "58": "Nièvre", "59": "Nord",
    "60": "Oise", "61": "Orne", "62": "Pas-de-Calais", "63": "Puy-de-Dôme",
    "64": "Basses-Pyrénées", "65": "Hautes-Pyrénées",
    "66": "Pyrénées-Orientales", "67": "Bas-Rhin", "68": "Haut-Rhin",
    "69": "Rhône", "70": "Haute-Saône", "71": "Saône-et-Loire",
    "72": "Sarthe", "73": "Savoie", "74": "Haute-Savoie", "75": "Paris",
    "76": "Seine-Maritime", "77": "Seine-et-Marne", "78": "Yvelines",
    "79": "Deux-Sèvres", "80": "Somme", "81": "Tarn", "82": "Tarn-et-Garonne",
    "83": "Var", "84": "Vaucluse", "85": "Vendée", "86": "Vienne",
    "87": "Haute-Vienne", "88": "Vosges", "89": "Yonne",
    "90": "Territoire-de-Belfort", "91": "Essonne", "92": "Hauts-de-Seine",
    "93": "Seine-Saint-Denis", "94": "Val-de-Marne", "95": "Val-d'Oise",
}

# Correction manuelle, fondée sur un signal indépendant du texte : l'ordre des
# identifiants ark suit l'ordre des départements. `bd6t53583456` tombe entre
# Indre-et-Loire (37) et Jura (39) — c'est l'Isère. Le texte l'attribuait au
# Rhône, que le fascicule cite comme voisin ; le vrai Rhône est
# `bd6t5358391d`, avec un score de 9 contre 2.
#
# Deux signaux faibles et indépendants valent mieux qu'un signal fort : ni la
# fréquence ni la position ne suffisent seules, leur croisement décide.
CORRECTIONS = {"bd6t53583456": "38"}

# 22 pages suffisent : la couche texte s'arrête aux liminaires, et
# l'avertissement qui décrit les trois tableaux tombe vers la page 17.
PAGES = 22


def plat(s):
    """Sans accents ni casse, mais AVEC les séparateurs.

    C'est la différence qui compte. Retirer aussi les espaces et les tirets,
    comme le fait `cle()` ailleurs dans le projet, rend impossible toute
    frontière de mot — et c'est ainsi que « Ain » a ramassé 40 fascicules.
    """
    s = unicodedata.normalize("NFD", s or "")
    return "".join(c for c in s if unicodedata.category(c) != "Mn").lower()


def motif(nom):
    """Un nom de département -> une expression à frontières de mot.

    Les séparateurs internes sont libres : l'OCR rend « BASSES-ALPES » aussi
    bien « BASSES ALPES » que « BASSES- ALPES ».
    """
    bouts = [re.escape(plat(b)) for b in re.split(r"[-' ]", nom) if b]
    return re.compile(r"(?<![a-z])" + r"[\s\-'’]*".join(bouts) + r"(?![a-z])")


ORDRE = sorted(DEPARTEMENTS, key=lambda c: -len(DEPARTEMENTS[c]))


def _corps(nom):
    """Le nom, séparateurs internes libres (l'OCR change les tirets en espaces)."""
    return r"[\s\-'’]*".join(re.escape(plat(x))
                              for x in re.split(r"[-' ]", nom) if x)


# Une seule alternation, du nom le plus long au plus court. Python essaie les
# branches dans l'ordre écrit et retient la première qui tombe À LA POSITION
# COURANTE : « Loire-Atlantique » est donc tenté avant « Loire », et la
# préférence pour le nom long ne joue qu'entre deux lectures du même endroit.
_ALT = "|".join(f"(?P<d{c.replace('-', '_')}>{_corps(DEPARTEMENTS[c])})"
                for c in ORDRE)
RX_PHRASE = re.compile(
    r"departement\s*(?:de\s*l|de\s*la|des|du|de|d)?['’\s]*(?:" + _ALT
    + r")(?![a-z\-])")
RX_SEUL = re.compile(r"(?<![a-z])(?:" + _ALT + r")(?![a-z\-])")


def _compte(rx, texte, sauf=()):
    """{code: occurrences} — quel département ce texte nomme-t-il, et combien ?"""
    c = collections.Counter()
    for m in rx.finditer(texte):
        g = m.lastgroup
        if g:
            code = g[1:].replace("_", "-")
            if code not in sauf:
                c[code] += 1
    return c


def texte(pdf, pages=PAGES):
    r = subprocess.run(["pdftotext", "-f", "1", "-l", str(pages), str(pdf), "-"],
                       capture_output=True, text=True)
    return plat(r.stdout)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--pages", type=int, default=PAGES)
    a = ap.parse_args()

    if not FASCICULES.exists():
        raise SystemExit(f"Dossier absent : {FASCICULES}")
    pdfs = sorted(FASCICULES.glob("*.pdf"))
    print(f"{len(pdfs)} fascicules dans {FASCICULES.name}\n")

    lignes, par_dep = [], collections.defaultdict(list)
    for p in pdfs:
        t = texte(p, a.pages)
        methode = "phrase"
        sc = _compte(RX_PHRASE, t)
        if not sc:
            # Paris est le lieu d'impression de tous les fascicules : le
            # compter en recours le ferait gagner partout.
            methode = "fréquence"
            sc = _compte(RX_SEUL, t, sauf=("75",))
        top = sc.most_common(2)
        c1, s1 = top[0] if top else ("", 0)
        if p.stem[-12:] in CORRECTIONS:
            c1, methode = CORRECTIONS[p.stem[-12:]], "position ark"
        c2, s2 = top[1] if len(top) > 1 else ("", 0)
        lignes.append(dict(
            ark=p.stem[-12:], fichier=p.name, dep=c1,
            departement=DEPARTEMENTS.get(c1, ""), methode=methode, score=s1,
            second=DEPARTEMENTS.get(c2, ""), score_second=s2,
            marge=f"{s1/s2:.1f}" if s2 else "",
            pages=subprocess.run(["pdfinfo", str(p)], capture_output=True,
                                 text=True).stdout.split("Pages:")[-1]
                       .split()[0] if p else ""))
        if c1:
            par_dep[c1].append(p.name)

    with SORTIE.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(lignes[0]))
        w.writeheader()
        w.writerows(sorted(lignes, key=lambda x: x["dep"]))

    # Contrôle indépendant : l'ordre des ark suit l'ordre des départements.
    # Une rupture n'est pas une erreur en soi — quelques fascicules ont été
    # numérisés plus tard, sous un ark d'une autre série — mais toute rupture
    # à l'intérieur d'une série continue signale une attribution à revoir.
    par_ark = sorted(lignes, key=lambda x: x["ark"])
    prec, ruptures = 0, []
    for l in par_ark:
        d = int(l["dep"]) if l["dep"].isdigit() else 0
        if d and d <= prec:
            ruptures.append((l["ark"], l["dep"], l["departement"]))
        if d:
            prec = d
    if ruptures:
        print(f"contrôle par l'ordre des ark : {len(ruptures)} ruptures")
        for a, d, n in ruptures:
            print(f"   {a}  {d} {n}")
        print()

    manquants = [c for c in DEPARTEMENTS if c not in par_dep]
    doubles = {c: v for c, v in par_dep.items() if len(v) > 1}
    print(f"{len(par_dep)} départements identifiés sur 95")
    if manquants:
        print(f"\nABSENTS — {len(manquants)} fascicules à retélécharger :")
        for c in manquants:
            print(f"   {c}  {DEPARTEMENTS[c]}")
    if doubles:
        print(f"\nattribués deux fois — à trancher à la main :")
        for c, v in doubles.items():
            print(f"   {c} {DEPARTEMENTS[c]} : {len(v)} fichiers")
    print(f"\n{SORTIE}")


if __name__ == "__main__":
    main()
