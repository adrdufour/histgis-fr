#!/usr/bin/env python3
"""Extrait les JO numérisés COLONNE PAR COLONNE, au lieu de les aplatir.

POURQUOI
========
Les fichiers de `jorf_txt/` ont été produits par une extraction linéaire. Or
le Journal officiel est sur DEUX COLONNES, et l'extraction les a fondues ligne
à ligne : chaque ligne du fichier porte la colonne de gauche puis celle de
droite. Deux décrets voisins s'y trouvent donc entrelacés, et le contenu de
l'un paraît AVANT son propre en-tête.

Vérifié sur `JORF_19820122_18.txt` : le décret n° 82-56 (Eure) a son texte aux
lignes 258-289 et son titre à la ligne 324. Un segmenteur qui lit dans l'ordre
attribue la colonne de droite au décret dont il a vu l'en-tête à gauche —
d'où « Evreux-Ouest » rangé sous le décret du Doubs, et « Lorient-Centre »
sous celui du Cantal.

`_raw.txt` ne corrige rien : il découpe les lignes fondues sans séparer les
colonnes.

DEUX MÉTHODES, ET POURQUOI LA PREMIÈRE A ÉTÉ ABANDONNÉE
======================================================
**`boite`** (le premier essai) rappelle `pdftotext` deux fois par page avec une
boîte de découpe, moitié gauche puis moitié droite. L'ordre est rétabli — c'est
mesuré, les inversions de numérotation tombent de 88 à 46 — mais **le texte est
abîmé** : le clipping REND À NOUVEAU la page, et tout ce qui touche la coupure
est perdu ou tronqué. Rejouer `composition_jo.py` dessus faisait tomber
l'extraction de 4 706 à 4 414 lignes et doublait les appariements par
ressemblance. On rétablissait l'ordre en détruisant le contenu.

**`gouttiere`** (retenue) ne redemande rien. Elle part du texte `-layout`
DÉJÀ RENDU — le même que celui de `jorf_txt/` — et le coupe en deux au blanc
vertical qui sépare les colonnes, ligne par ligne, puis empile les moitiés
gauches avant les moitiés droites. Aucun caractère n'est perdu ni relu : ce
sont exactement les mêmes octets, remis dans l'ordre de lecture.

*Une réparation qui repasse par la source rend une source différente.* Ici, il
ne fallait pas relire la page : il fallait la déplier.

    python3 cantons/jorf_colonnes.py                 # tous les PDF de JORF/
    python3 cantons/jorf_colonnes.py --mesure        # ne rien écrire, comparer
    python3 cantons/jorf_colonnes.py --methode boite # l'essai abandonné
    python3 cantons/jorf_colonnes.py JORF/xxx.pdf    # un seul

Sortie : `jorf_txt/<nom>_col.txt`. **On n'écrase pas les fichiers existants** —
la règle du dépôt est qu'on signale et qu'on ne supprime pas, et les deux
lectures devront être comparées avant qu'aucune ne soit retirée (leçon des
deux passes OCR de 1968, dont l'union valait mieux que chacune).

LA MESURE
=========
`--mesure` compte, dans chaque lecture, les en-têtes de décret repérables. Un
en-tête aplati dans la colonne de droite d'une autre ligne n'est pas repérable ;
l'écart mesure donc directement ce que l'entrelacement coûtait.

LIMITE CONNUE
=============
La gouttière est cherchée, pas supposée : on retient la bande de blancs
verticale la plus large dans la moitié centrale de la page, présente sur au
moins 85 % des lignes. **Une page sans gouttière est recopiée telle quelle** —
sommaires, tableaux pleine largeur, pages de titre. C'est le bon défaut : on ne
coupe que là où il y a manifestement deux colonnes.
"""

import re
import subprocess
import sys
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
PDF_DIR = RACINE / "JORF"
TXT_DIR = RACINE / "jorf_txt"

# « Décret n° 82-92 », « Décret n" 82-56 », « Décret n°  73-651 » — l'OCR
# malmène le signe ordinal, jamais le mot ni les chiffres.
EN_TETE = re.compile(r"D[ée]cret\s+n[°\"'ºo]?\s*(\d{2})\s*-\s*(\d+)")


def taille_page(pdf: Path):
    info = subprocess.run(["pdfinfo", str(pdf)], capture_output=True, text=True).stdout
    pages = re.search(r"Pages:\s+(\d+)", info)
    taille = re.search(r"Page size:\s+([\d.]+) x ([\d.]+)", info)
    if not pages or not taille:
        return None
    return int(pages.group(1)), float(taille.group(1)), float(taille.group(2))


def colonne(pdf: Path, page: int, x: float, largeur: float, hauteur: float) -> str:
    r = subprocess.run(
        ["pdftotext", "-f", str(page), "-l", str(page),
         "-x", str(int(x)), "-y", "0",
         "-W", str(int(largeur)), "-H", str(int(hauteur)),
         "-layout", str(pdf), "-"],
        capture_output=True, text=True)
    return r.stdout


# ---------------------------------------------------------------------------
# MÉTHODE RETENUE : la gouttière
# ---------------------------------------------------------------------------

def gouttiere(lignes, marge=0.30, seuil=0.85, mini=3):
    """Position de la bande de blancs qui sépare les deux colonnes, ou None.

    On ne suppose pas la moitié de la page : on la cherche. Une colonne de
    caractères appartient à la gouttière si elle est blanche sur au moins
    `seuil` des lignes non vides. On retient la plus large bande de telles
    colonnes située dans la moitié centrale, et on rend son DÉBUT.

    `mini` écarte les alignements fortuits d'une ou deux espaces ; `marge`
    interdit de couper près des bords, où une marge de page produirait la même
    signature qu'une gouttière.
    """
    utiles = [l for l in lignes if l.strip()]
    if len(utiles) < 8:
        return None
    largeur = max(len(l) for l in utiles)
    if largeur < 40:
        return None
    bas, haut = int(largeur * marge), int(largeur * (1 - marge))

    blanches = []
    for c in range(bas, haut):
        vides = sum(1 for l in utiles if c >= len(l) or l[c] == " ")
        if vides >= seuil * len(utiles):
            blanches.append(c)
    if not blanches:
        return None

    # la plus large bande contiguë
    meilleure, courante = [], [blanches[0]]
    for c in blanches[1:]:
        if c == courante[-1] + 1:
            courante.append(c)
        else:
            if len(courante) > len(meilleure):
                meilleure = courante
            courante = [c]
    if len(courante) > len(meilleure):
        meilleure = courante
    return (meilleure[0], meilleure[-1] + 1) if len(meilleure) >= mini else None


def coupe(ligne, bande, jeu=6):
    """Où couper CETTE ligne, ou None si elle traverse les deux colonnes.

    Couper toutes les lignes au même caractère tranche dans les mots des
    lignes qui débordent — 15 % d'entre elles, par construction, puisque la
    gouttière n'est blanche que sur 85 %. On cherche donc, dans un voisinage
    de la bande, une vraie respiration (deux espaces au moins) propre à la
    ligne.

    Sans respiration, la ligne est PLEINE LARGEUR : bandeau de page, titre,
    tableau. On ne la coupe pas — elle reste entière à gauche. Une ligne
    pleine largeur coupée en deux donne deux moitiés fausses ; laissée
    entière, elle donne une ligne juste au mauvais endroit.
    """
    deb, fin = bande
    if len(ligne) <= deb:
        return len(ligne)
    zone = ligne[max(0, deb - jeu): fin + jeu]
    meilleur, taille, i = None, 0, 0
    while i < len(zone):
        if zone[i] == " ":
            j = i
            while j < len(zone) and zone[j] == " ":
                j += 1
            if j - i > taille:
                meilleur, taille = i, j - i
            i = j
        else:
            i += 1
    if meilleur is None or taille < 2:
        return None
    return max(0, deb - jeu) + meilleur


def sans_layout(pdf: Path) -> str:
    """La lecture brute, sans `-layout` — celle dont sont faits les `_raw.txt`."""
    return subprocess.run(["pdftotext", str(pdf), "-"],
                          capture_output=True, text=True).stdout


def par_gouttiere(pdf: Path) -> str:
    """Déplie le texte `-layout` sans le redemander : mêmes octets, autre ordre.

    REPLI. Quand une page ne montre pas de gouttière, on ne garde PAS son texte
    `-layout` : c'est précisément la forme entrelacée qu'on veut fuir. On
    reprend la page telle que `pdftotext` sans `-layout` la rend — la lecture
    des `_raw.txt`, qui au moins ne juxtapose pas deux colonnes sur une ligne.

    Sans ce repli, une seule page du JO du 23 janvier 1985 faisait perdre le
    canton de Friville-Escarbotin et ses neuf communes. *Un repli doit être le
    moins mauvais des états connus, pas le premier sous la main.*
    """
    brut = lineaire(pdf)
    pages_brutes = sans_layout(pdf).split("\f")
    sortie = []
    for i, page in enumerate(brut.split("\f")):
        lignes = page.split("\n")
        g = gouttiere(lignes)
        if g is None:
            sortie.append(pages_brutes[i] if i < len(pages_brutes) else page)
            continue
        gauche, droite = [], []
        for l in lignes:
            c = coupe(l, g)
            # On DÉSINDENTE les deux moitiés. Ce n'est pas cosmétique : la
            # moitié droite hérite sinon de toute la largeur de la gouttière,
            # et `composition_jo.nettoie()` recolle les mots coupés en fin de
            # ligne par la règle `-\n(?=[a-z])` — qui ne voit plus rien quand
            # une espace s'intercale. « Fonte-\n  nay-Mauvoisin » restait coupé,
            # et le canton de Bonnières-sur-Seine perdait ses 26 communes en
            # silence : ni sortie, ni rejet.
            if c is None:                 # ligne pleine largeur
                gauche.append(l.strip())
                droite.append("")
            else:
                gauche.append(l[:c].strip())
                droite.append(l[c:].strip())
        sortie.append("\n".join(gauche) + "\n" + "\n".join(droite))
    return "\f".join(sortie)


def par_colonnes(pdf: Path) -> str:
    infos = taille_page(pdf)
    if infos is None:
        return ""
    pages, largeur, hauteur = infos
    morceaux = []
    for p in range(1, pages + 1):
        morceaux.append(colonne(pdf, p, 0, largeur / 2, hauteur))
        morceaux.append(colonne(pdf, p, largeur / 2, largeur / 2, hauteur))
    return "\n".join(morceaux)


def lineaire(pdf: Path) -> str:
    return subprocess.run(["pdftotext", "-layout", str(pdf), "-"],
                          capture_output=True, text=True).stdout


def en_tetes(texte: str):
    """Les en-têtes repérables, un par ligne. Un en-tête aplati dans la colonne
    de droite d'une autre ligne compte quand même s'il est reconnaissable —
    on ne mesure donc PAS l'entrelacement lui-même, mais ce qui en réchappe."""
    vus = []
    for ligne in texte.split("\n"):
        for m in EN_TETE.finditer(ligne):
            vus.append(f"{m.group(1)}-{m.group(2)}")
    return vus


def ordre_respecte(texte: str) -> tuple:
    """Un en-tête doit précéder le texte de son décret. Faute de savoir où
    finit un décret, on teste une propriété plus faible mais vérifiable : les
    en-têtes se suivent-ils dans l'ordre croissant des numéros ?

    Un entrelacement de colonnes inverse l'ordre — sur le JO du 22 janvier
    1982, le 82-62 paraît avant le 82-61. L'inversion est donc un signe, et
    son absence n'est pas une preuve."""
    nums = []
    for h in en_tetes(texte):
        a, b = h.split("-")
        nums.append((int(a), int(b)))
    inversions = sum(1 for i in range(1, len(nums)) if nums[i] < nums[i - 1])
    return len(nums), inversions


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    mesure = "--mesure" in sys.argv
    methode = "boite" if "--methode" in sys.argv and \
        sys.argv[sys.argv.index("--methode") + 1] == "boite" else "gouttiere"
    args = [a for a in args if a != "boite"]
    deplie = par_colonnes if methode == "boite" else par_gouttiere
    print(f"méthode : {methode}")
    pdfs = [Path(a) for a in args] if args else sorted(PDF_DIR.glob("*.pdf"))
    if not pdfs:
        print(f"Aucun PDF dans {PDF_DIR}")
        return 1

    TXT_DIR.mkdir(exist_ok=True)
    tot_lin = tot_col = tot_inv_lin = tot_inv_col = 0
    lignes = []

    for pdf in pdfs:
        col = deplie(pdf)
        if not col:
            print(f"  !! illisible : {pdf.name}")
            continue
        lin = lineaire(pdf)
        n_lin, inv_lin = ordre_respecte(lin)
        n_col, inv_col = ordre_respecte(col)
        tot_lin += n_lin; tot_col += n_col
        tot_inv_lin += inv_lin; tot_inv_col += inv_col
        lignes.append((pdf.stem, n_lin, n_col, inv_lin, inv_col))

        if not mesure:
            sortie = TXT_DIR / f"{pdf.stem}_col.txt"
            sortie.write_text(col)

    print(f"{'JO':<28} {'en-têtes lin.':>13} {'en-têtes col.':>13} "
          f"{'invers. lin.':>12} {'invers. col.':>12}")
    for nom, a, b, c, d in lignes:
        marque = "  <--" if b > a or d < c else ""
        print(f"{nom:<28} {a:>13} {b:>13} {c:>12} {d:>12}{marque}")
    print(f"{'TOTAL':<28} {tot_lin:>13} {tot_col:>13} "
          f"{tot_inv_lin:>12} {tot_inv_col:>12}")

    if not mesure:
        print(f"\nÉcrit dans {TXT_DIR}/*_col.txt — les fichiers existants sont "
              f"intacts.\nComparer AVANT de rejouer cantons/composition_jo.py.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
