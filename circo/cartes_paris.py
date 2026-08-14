#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
cartes_paris.py — les circonscriptions législatives de Paris, planche par division

    python3 circo/cartes_paris.py

Produit `circo/paris_circo.pdf`, une page par division électorale, de 1863 à
1986, dans l'ordre chronologique. Chaque planche superpose :

* les circonscriptions, en aplats colorés, étiquetées de leur numéro ;
* la trame des 80 quartiers, en fin trait gris, chacun nommé ;
* **en hachuré rouge, les quartiers revendiqués par plusieurs
  circonscriptions.**

Ce dernier point est le seul qui demande une explication. Une circonscription
coupe parfois un quartier ; l'atlas nomme alors les rues, mais la couche ne
sait pas encore couper — le quartier entier est donc attribué aux deux, et
leurs polygones se recouvrent exactement. La carte doit le dire plutôt que de
laisser croire à une partition nette. C'est la convention déjà retenue par
`cartes/cartes_cantons.py` pour les communes partagées entre cantons, et elle
garde ici le même sens.

Ce que ces planches ne montrent pas
-----------------------------------
La trame des quartiers est MODERNE — reconstruite par union d'IRIS. Qu'elle
rende les limites de 1876 est réputé, non vérifié. Et elle ne vaut qu'à partir
de 1860 : les divisions antérieures relèvent des douze arrondissements et ne
sont pas posées.

Dépendances : psycopg2, shapely, matplotlib — celles de `cartes_cantons.py`,
dont ce script réutilise le tracé.
"""

import sys
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt                          # noqa: E402
from matplotlib.backends.backend_pdf import PdfPages     # noqa: E402
from matplotlib.patches import PathPatch                 # noqa: E402
from shapely import wkb                                  # noqa: E402

RACINE = Path(__file__).resolve().parent.parent
SORTIE = RACINE / "circo" / "paris_circo.pdf"

sys.path.insert(0, str(RACINE / "cartes"))
sys.path.insert(0, str(RACINE / "circo"))
from cartes_cantons import vers_path                     # noqa: E402
from paris_quartiers import connexion                    # noqa: E402

SQL_CIRCO = """
SELECT periode, circo, quartiers, q_list, source, ST_AsBinary(geom)
FROM   paris_circo ORDER BY periode, circo
"""
SQL_QUARTIER = """
SELECT quartier, nom, ST_AsBinary(geom) FROM paris_quartier ORDER BY quartier
"""


def annee(p):
    t = (p or "").split("-")[0].strip()
    return int(t) if t.isdigit() else 9999


def planche(pdf, periode, circos, quartiers):
    # Un quartier revendiqué par plusieurs circonscriptions : le compte se
    # fait sur les LISTES portées par la couche, pas sur une intersection
    # géométrique. Les polygones se recouvrent exactement, une intersection
    # ne saurait pas les distinguer d'un simple contact.
    compte = {}
    for _, _, _, ql, _, _ in circos:
        for q in (ql or []):
            compte[q] = compte.get(q, 0) + 1
    partages = {q for q, n in compte.items() if n > 1}

    fig, ax = plt.subplots(figsize=(16.53, 11.69))       # A3 paysage
    couleurs = plt.get_cmap("tab20").colors

    for i, (_, lab, nq, ql, _, g) in enumerate(circos):
        geom = wkb.loads(bytes(g))
        p = vers_path(geom)
        if p is None:
            continue
        ax.add_patch(PathPatch(p, facecolor=couleurs[i % 20],
                               edgecolor="#222222", linewidth=1.2,
                               alpha=0.55, zorder=2))
        c = geom.representative_point()
        ax.text(c.x, c.y, lab, fontsize=11, ha="center", va="center",
                zorder=6, fontweight="bold", color="#00256b",
                bbox=dict(boxstyle="round,pad=0.25", fc="white",
                          ec="#00256b", lw=0.6, alpha=0.9))

    for q, nom, g in quartiers:
        geom = wkb.loads(bytes(g))
        p = vers_path(geom)
        conteste = q in partages
        if p is not None:
            ax.add_patch(PathPatch(
                p, facecolor="none",
                edgecolor="#c00000" if conteste else "#666666",
                linewidth=1.0 if conteste else 0.4,
                hatch="////" if conteste else None,
                zorder=4 if conteste else 3))
        c = geom.representative_point()
        # Noir sur fond blanc, jamais rouge : un texte rouge sur des hachures
        # rouges disparaît. Le signal reste porté par le contour.
        ax.text(c.x, c.y - 260, f"{q} {nom}", fontsize=4.6, ha="center",
                va="center", zorder=5, color="#1a1a1a",
                fontweight="bold" if conteste else "normal",
                bbox=dict(boxstyle="square,pad=0.12", fc="white",
                          ec="#c00000", lw=0.3, alpha=0.85)
                     if conteste else None)

    ax.autoscale_view()
    ax.set_aspect("equal")
    ax.axis("off")
    src = {s for _, _, _, _, s, _ in circos}
    ax.set_title(f"Paris — circonscriptions législatives {periode}\n"
                 f"{len(circos)} circonscriptions, 80 quartiers"
                 + (f", {len(partages)} partagé(s)" if partages else ""),
                 fontsize=15, pad=14)

    pied = [
        "Composition : atlas Gaudillere, annexe de Paris, transcrite dans "
        "circo/paris_decoupage.csv.",
        "Trame : 80 quartiers administratifs reconstruits par union d'IRIS "
        "(CONTOURS-IRIS, INSEE-IGN, Licence Ouverte 2.0). Trame MODERNE : "
        "sa fidelite aux limites de 1876 est reputee, non verifiee.",
    ]
    if partages:
        pied.append(
            f"HACHURE ROUGE : {len(partages)} quartier(s) revendique(s) par "
            f"plusieurs circonscriptions. L'atlas y nomme les rues, la couche "
            f"ne sait pas encore couper : le quartier entier est attribue a "
            f"chacune, et leurs polygones se recouvrent exactement.")
    if src == {"renvoi"}:
        pied.append(
            "SOURCE DEDUITE : cette division n'est pas transcrite d'un "
            "tableau mais deduite d'un renvoi du livre (meme decoupage que "
            "1902-1910).")
    fig.text(0.02, 0.02, "\n".join(pied), fontsize=7, va="bottom",
             color="#333333", wrap=True)
    fig.tight_layout(rect=[0, 0.07, 1, 1])
    pdf.savefig(fig)
    plt.close(fig)


def main():
    with connexion() as cx:
        cx.set_session(readonly=True)
        with cx.cursor() as cur:
            cur.execute("SET search_path TO histgis, public")
            cur.execute("SELECT to_regclass('histgis.paris_circo')")
            if cur.fetchone()[0] is None:
                sys.exit("Table paris_circo absente. Lancer d'abord :\n"
                         "    python3 circo/paris_circo.py")
            cur.execute(SQL_QUARTIER)
            quartiers = cur.fetchall()
            cur.execute(SQL_CIRCO)
            tout = cur.fetchall()

    par = {}
    for r in tout:
        par.setdefault(r[0], []).append(r)
    if not par:
        sys.exit("paris_circo est vide. Relancer circo/paris_circo.py.")

    with PdfPages(SORTIE) as pdf:
        for p in sorted(par, key=lambda x: (annee(x), x)):
            planche(pdf, p, par[p], quartiers)
            print(f"  {p:12s} {len(par[p]):3d} circonscriptions")
    print(f"\n{SORTIE} : {len(par)} planches")


if __name__ == "__main__":
    main()
