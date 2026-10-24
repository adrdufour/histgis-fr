#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
cartes_cantons.py — une planche cantonale par département et par borne

    python3 archives/planches/cartes_cantons.py            # tous les départements
    python3 archives/planches/cartes_cantons.py 01 13 69   # une sélection

Produit `archives/planches/sorties/dep_NN.pdf`, trois pages : 1870, 1940, 1999.
Avec `--un-seul`, tout va dans `archives/planches/sorties/cantons_tous.pdf`, une
planche par page : plus commode pour comparer les departements.
Avec `--2025`, une quatrieme planche par departement, tiree de la table
`can2025` (ADMIN EXPRESS v4) : la seule des quatre qui coupe les villes.

Pourquoi ces trois dates et pas d'autres
----------------------------------------
Ce sont les seules où la base tient une information de source : TRF-GIS pour
1870 et 1940, le COG pour 1999. Toute autre date serait un report, et une
carte ne dit pas qu'elle interpole — elle a l'autorité de ce qu'elle montre.
Mieux vaut trois planches honnêtes que dix qui laissent croire.

À quoi ça sert
--------------
À dater les mouvements que `sql/33_diff_cantonal.sql` a calculés. Le script
dit *quoi*, les cartes de Gaudillère disent *quand*, et ces planches-ci
permettent de les superposer sans relire des listes de communes.

Ce que les planches ne montrent pas fidèlement
----------------------------------------------
Les communes partagées entre plusieurs cantons — Marseille, Lyon, Paris,
Bourg-en-Bresse — portent en base le polygone de la commune entière. Sur la
carte, leurs cantons se recouvrent donc exactement. Le pied de page le
rappelle département par département, avec le compte.

Dépendances : psycopg2, shapely, matplotlib.
    pip install psycopg2-binary shapely matplotlib --break-system-packages
"""

import csv
import os
import unicodedata
import sys
import textwrap
from contextlib import nullcontext
from pathlib import Path as FsPath

import psycopg2
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
from matplotlib.path import Path
from matplotlib.patches import PathPatch
from shapely import wkb
from shapely.ops import unary_union

# La libpq livrée par conda cherche la socket Unix dans /tmp, alors que les
# paquets Debian et Ubuntu la posent dans /var/run/postgresql. D'où un
# « No such file or directory » alors que psql fonctionne dans le même shell.
# On essaie les emplacements dans l'ordre, et TCP en dernier recours.
DSN_CANDIDATS = [
    "dbname=histgis host=/var/run/postgresql",
    "dbname=histgis",
    "dbname=histgis host=localhost",
]
SORTIE = FsPath(__file__).resolve().parent / "sorties"
SORTIE.mkdir(exist_ok=True)
DATES = [("1870-06-01", "1870", "TRF-GIS"),
         ("1940-06-01", "1940", "TRF-GIS"),
         ("1999-06-01", "1999", "COG Insee")]

SQL_CANTON = """
SELECT m.unit_id,
       coalesce(max(uv.nom), max(u.nom))               AS nom,
       ST_AsBinary(ST_UnaryUnion(ST_Collect(ag.geom))) AS geom,
       count(DISTINCT a.insee_geofla)                  AS communes
FROM   membership m
JOIN   atom a       ON a.atom_id = m.atom_id
JOIN   atom_geom ag ON ag.atom_id = a.atom_id
JOIN   unit u       ON u.unit_id = m.unit_id
LEFT   JOIN unit_version uv ON uv.unit_id = u.unit_id AND uv.periode @> %(d)s::date
WHERE  m.niveau = 'canton' AND m.periode @> %(d)s::date
  AND  left(a.insee_geofla, 2) = %(dep)s
GROUP  BY m.unit_id
ORDER  BY m.unit_id
"""

# Les communes sont tirées des mêmes atomes que les cantons : la trame
# communale affichée est exactement celle qui compose les cantons affichés.
# Le nom d'une commune se cherche en deux temps. GEOFLA 2011 ne connaît que
# les communes vivantes en 2011 : une commune fusionnée avant — Escaufourt en
# 1973, Lompnes avant 1943 — n'y figure pas, et la planche de 1870 affichait
# alors son code Insee, illisible. Le fichier de mouvements de l'Insee garde
# leur nom sous `libelle_av`, et c'est là qu'il faut aller le chercher.
# Ce qui n'a de nom nulle part est signalé comme tel, pas maquillé.
# On groupe par EMPREINTE DE POLYGONE, jamais par code commune.
#
# Plusieurs communes de 1870 fondues depuis en une seule partagent un unique
# polygone de 2011 : dans les Alpes-de-Haute-Provence, Espinouse, Saint-Jurson
# et Le Chaffaut portent les mêmes 29,75 km². Dessinés séparément, ils
# s'empilent — trois libellés au même endroit, trois cantons exactement
# superposés, et rien qui l'indique.
#
# Groupés par empreinte, le polygone est tracé une fois, porte tous les noms
# qui le revendiquent, et `n_cantons` dit combien de cantons se le disputent à
# cette date. C'est la règle déjà retenue pour tout calcul de recouvrement :
# grouper par la géométrie, jamais par un code — un code est une
# reconstruction, l'empreinte est un fait.
SQL_COMMUNE = """
WITH base AS (
    SELECT ag.geom, a.atom_id, m.unit_id,
           coalesce(
               g.nom_comm,
               (SELECT mv.libelle_av FROM insee_mvt mv
                WHERE  mv.com_av = a.insee_geofla
                ORDER  BY mv.date_eff LIMIT 1),
               '[' || a.insee_geofla || ']'
           )                          AS nom,
           (g.insee_com IS NULL)      AS disparue
    FROM   atom a
    JOIN   atom_geom ag ON ag.atom_id = a.atom_id
    JOIN   membership m ON m.atom_id = a.atom_id AND m.niveau = 'canton'
                       AND m.periode @> %(d)s::date
    LEFT   JOIN geofla_commune g ON g.insee_com = a.insee_geofla
    WHERE  left(a.insee_geofla, 2) = %(dep)s
)
SELECT string_agg(DISTINCT nom, ' / ' ORDER BY nom) AS noms,
       bool_and(disparue)                           AS disparue,
       count(DISTINCT unit_id)                      AS n_cantons,
       ST_AsBinary(geom)                            AS geom
FROM   base
GROUP  BY geom
"""

# Combien de communes relèvent de plusieurs cantons à cette date : c'est la
# mesure du recouvrement que la planche ne peut pas montrer.
SQL_PARTAGE = """
SELECT count(*) FROM (
    SELECT a.insee_geofla
    FROM   membership m JOIN atom a ON a.atom_id = m.atom_id
    WHERE  m.niveau = 'canton' AND m.periode @> %(d)s::date
      AND  left(a.insee_geofla, 2) = %(dep)s
    GROUP  BY a.insee_geofla HAVING count(DISTINCT m.unit_id) > 1
) t
"""


# ---------------------------------------------------------------------------
# La planche 2025. Elle ne vient pas de `membership` mais de la table
# `can2025`, posée par `cartes/couverture_cantons_2025.py` d'après ADMIN
# EXPRESS v4 — la première couche ouverte qui publie le contour RÉEL des
# cantons, c'est-à-dire qui coupe les communes multi-cantonales au lieu de les
# replier en pseudo-canton comme le fait GEOFLA.
#
# Deux avertissements que le pied de page doit porter, sans quoi la planche
# ment par omission :
#   - la trame communale reste GEOFLA 2011, la seule dont dispose la base ;
#     seuls les cantons sont de 2025 ;
#   - la géométrie du jeu simplifié n'est pas d'une précision métrique.
#
# Le seuil de 15 % est celui de tout le chantier : à 2 %, le simple décalage
# entre millésimes fait ressortir des milliers de communes « coupées ».
SEUIL_2025 = 0.15

SQL_CANTON_2025 = f"""
SELECT c.can, c.nom, ST_AsBinary(c.geom),
       (SELECT count(*) FROM geofla_commune g
        WHERE  g.geom && c.geom AND ST_Intersects(g.geom, c.geom)
          AND  ST_Area(ST_Intersection(g.geom, c.geom))
               / ST_Area(g.geom) > {SEUIL_2025})
FROM   can2025 c
WHERE  c.dep = %(dep)s
ORDER  BY c.can
"""

SQL_COMMUNE_2025 = f"""
WITH b AS (
    SELECT g.insee_com, g.nom_comm, g.geom,
           count(*) FILTER (
               WHERE ST_Area(ST_Intersection(g.geom, c.geom))
                     / ST_Area(g.geom) > {SEUIL_2025}) AS n
    FROM   geofla_commune g
    LEFT   JOIN can2025 c
           ON c.geom && g.geom AND ST_Intersects(c.geom, g.geom)
    WHERE  left(g.insee_com, 2) = %(dep)s
    GROUP  BY 1, 2, 3
)
SELECT nom_comm, false, n, ST_AsBinary(geom) FROM b
"""


def planche_2025(cur, pdf, dep):
    """Ajoute la planche des cantons de 2025. Rend le nombre de pages."""
    cur.execute(SQL_CANTON_2025, {"dep": dep})
    cantons = [(c, n, wkb.loads(bytes(g)), k)
               for c, n, g, k in cur.fetchall() if g]
    if not cantons:
        return 0
    cur.execute(SQL_COMMUNE_2025, {"dep": dep})
    communes = [(nom, disp, n, wkb.loads(bytes(g)))
                for nom, disp, n, g in cur.fetchall() if g]
    partages = sum(1 for _, _, n, _ in communes if n > 1)
    fig, (axc, axl) = plt.subplots(2, 1, figsize=(11.69, 16.53),
                                   gridspec_kw={"height_ratios": [5, 1]})
    planche(axc, axl, cantons, communes, dep, "2025",
            "ADMIN EXPRESS v4 (IGN, Licence Ouverte 2.0), jeu simplifie. "
            "ATTENTION : seuls les CANTONS sont de 2025 ; la trame communale "
            "dessinee reste GEOFLA 2011, la seule dont dispose la base. Une "
            "commune creee ou fusionnee depuis 2011 est donc mal decoupee "
            "ici. Les cantons de 2025 coupent les grandes communes, ce que "
            "GEOFLA ne fait dans aucun millesime",
            partages)
    fig.tight_layout()
    pdf.savefig(fig)
    plt.close(fig)
    return 1


def vers_path(geom):
    """Convertit un polygone shapely en chemin matplotlib, trous compris."""
    polys = geom.geoms if geom.geom_type == "MultiPolygon" else [geom]
    sommets, codes = [], []
    for poly in polys:
        if poly.is_empty:
            continue
        for anneau in [poly.exterior] + list(poly.interiors):
            pts = list(anneau.coords)
            if len(pts) < 3:
                continue
            sommets.extend(pts)
            codes.extend([Path.MOVETO] + [Path.LINETO] * (len(pts) - 2)
                         + [Path.CLOSEPOLY])
    return Path(sommets, codes) if sommets else None


def planche(ax_carte, ax_leg, cantons, communes, dep, libelle, source, partages):
    couleurs = plt.get_cmap("tab20").colors

    for i, (uid, nom, geom, ncom) in enumerate(cantons):
        p = vers_path(geom)
        if p is None:
            continue
        ax_carte.add_patch(PathPatch(p, facecolor=couleurs[i % 20],
                                     edgecolor="#333333", linewidth=0.9,
                                     alpha=0.65, zorder=2))
        # l'étiquette : les deux derniers caractères du code, lisibles
        c = geom.representative_point()
        ax_carte.text(c.x, c.y, uid[-2:], fontsize=8, ha="center", va="center",
                      zorder=6, fontweight="bold", color="#8b0000",
                      bbox=dict(boxstyle="round,pad=0.18", fc="white",
                                ec="#8b0000", lw=0.4, alpha=0.85))

    n_disparues, n_contestes, km2_contestes = 0, 0, 0.0
    for noms, disparue, n_cantons, geom in communes:
        conteste = n_cantons > 1
        if conteste:
            n_contestes += 1
            km2_contestes += geom.area / 1e6
        if disparue:
            n_disparues += 1

        p = vers_path(geom)
        if p is not None:
            # Un polygone que plusieurs cantons revendiquent est hachuré de
            # rouge : son territoire est compté autant de fois qu'il a de
            # prétendants, et la carte doit le dire au lieu de superposer
            # silencieusement les cantons.
            ax_carte.add_patch(PathPatch(
                p, facecolor="none",
                edgecolor="#c00000" if conteste else "#777777",
                linewidth=0.8 if conteste else 0.3,
                hatch="////" if conteste else None,
                zorder=4 if conteste else 3))

        # Le nom, en très petit corps. Le PDF étant vectoriel, le zoom reste
        # net : mieux vaut un texte dense et lisible à l'écran qu'un
        # échantillon arbitraire de communes. Les communes disparues depuis
        # sont en italique — sur une planche de 1870, savoir qu'une commune
        # n'existe plus évite de la chercher en vain dans une source moderne.
        # Un polygone contesté porte plusieurs noms : les empiler
        # verticalement plutôt que de les aligner, sans quoi l'étiquette
        # déborde largement du contour et devient illisible.
        # Sur un polygone contesté, le texte ne doit PAS être rouge : il
        # deviendrait invisible sur les hachures de la même couleur. On le
        # laisse noir et on lui pose un fond blanc, qui le détache des
        # hachures sans les masquer. Le signal reste porté par le contour.
        c = geom.representative_point()
        ax_carte.text(c.x, c.y, noms.replace(" / ", "\n"), fontsize=2.9,
                      ha="center", va="center", zorder=5, linespacing=0.95,
                      color="#7a3b00" if (disparue and not conteste) else "#1a1a1a",
                      style="italic" if disparue else "normal",
                      fontweight="bold" if conteste else "normal",
                      bbox=dict(boxstyle="square,pad=0.12", fc="white",
                                ec="#c00000", lw=0.3, alpha=0.85)
                           if conteste else None)

    ax_carte.autoscale_view()
    ax_carte.set_aspect("equal")
    ax_carte.axis("off")
    ax_carte.set_title(f"Département {dep} — {libelle}\n"
                       f"{len(cantons)} cantons, {len(communes)} communes",
                       fontsize=11, pad=10)

    # la légende : code → nom, en deux colonnes si nécessaire
    ax_leg.axis("off")
    lignes = [f"{uid[-2:]}  {nom or '(sans nom)'}  ({ncom})"
              for uid, nom, _, ncom in cantons]
    milieu = (len(lignes) + 1) // 2
    for col, bloc in enumerate((lignes[:milieu], lignes[milieu:])):
        ax_leg.text(0.02 + col * 0.5, 0.98, "\n".join(bloc), fontsize=5.5,
                    va="top", ha="left", family="monospace",
                    transform=ax_leg.transAxes)

    # matplotlib ne replie pas le texte : une ligne trop longue sort de la
    # zone et disparaît sans avertissement. On replie donc à la main, en
    # traitant chaque paragraphe séparément.
    paragraphes = [
        f"Source des rattachements : {source}. Effectifs entre parenthèses : "
        f"communes du canton.",
        "Noms de communes : GEOFLA 2011, complété par le fichier de mouvements "
        "de l'Insee pour les communes disparues. Une commune renommée depuis "
        "s'affiche sous son nom moderne.",
    ]
    if n_disparues:
        paragraphes.append(
            f"En italique brun : {n_disparues} polygone(s) dont toutes les "
            f"communes ont disparu avant 2011. Un nom entre crochets est un "
            f"code Insee — la commune n'a de nom dans aucune source.")
    if n_contestes:
        paragraphes.append(
            f"HACHURÉ ROUGE : {n_contestes} polygone(s), {km2_contestes:.1f} "
            f"km², revendiqués par plusieurs cantons à cette date. Des communes "
            f"d'époque fondues depuis en une seule n'ont qu'une géométrie pour "
            f"toutes : leur territoire est compté autant de fois qu'il a de "
            f"prétendants. Limite de la trame 2011, non corrigeable — mais "
            f"affichée plutôt que masquée.")

    pied = "\n".join("\n".join(textwrap.wrap(p, width=155)) for p in paragraphes)
    if partages:
        pied += (f"\nATTENTION : {partages} commune(s) relèvent de plusieurs "
                 f"cantons à cette date et portent le polygone communal entier. "
                 f"Leurs cantons se recouvrent exactement sur la carte.")
    ax_leg.text(0.02, 0.02, pied, fontsize=5.5, va="bottom", ha="left",
                style="italic", color="#555555", transform=ax_leg.transAxes)


def _cle_unite(libelle):
    """`0320 Montlucon-Est` -> `0320` ; `Montmarault` -> `montmarault`."""
    lib = libelle.strip()
    if len(lib) >= 4 and lib[:4].isalnum() and (len(lib) == 4 or lib[4] == " "):
        return lib[:4]
    n = unicodedata.normalize("NFD", lib.lower())
    n = "".join(c for c in n if unicodedata.category(c) != "Mn")
    return "".join(c for c in n if c.isalnum())


def projection_1815():
    """Ce qu'il faut faire, département par département, pour remonter à 1815.

    La base ne contient RIEN avant 1870 : la série TRF-GIS commence là. Une
    planche « 1815 » est donc toujours une reconstruction, jamais une lecture.

    Deux conditions, et deux seulement.

    **Couverture.** Les intervalles du registre doivent pavér 1815-1870 sans
    trou. Un trou signifie qu'on ignore ce qui s'est passé pendant ces
    années-là, et une carte ne sait pas dire qu'elle ignore.

    **Réversibilité.** Chaque démembrement antérieur à 1870 se rejoue à
    l'envers : les cantons résultants sont refondus dans leur source. C'est la
    remontée du registre, appliquée avant le début de la série. L'Allier de
    1815 s'obtient ainsi de celui de 1870 en refondant Commentry dans
    Montmarault et les deux Montluçon en un seul.

    Un département stable est simplement le cas où la liste de refontes est
    vide — ce n'est pas un régime à part.

    Rend {dep: [(cle_source, [cles_resultants]), ...]} pour les départements
    éligibles. Les autres sont écartés, avec la raison.
    """
    reg = (FsPath(__file__).resolve().parents[2]
           / "cantons" / "mouvements_cantonaux.csv")
    if not reg.exists():
        return {}, {}

    par_dep = {}
    with reg.open(encoding="utf-8") as f:
        for l in csv.DictReader(f):
            deb, fin = l.get("date_debut") or "", l.get("date_fin") or ""
            if not deb or deb >= "1870-01-01":
                continue
            par_dep.setdefault(l["dep"], []).append(
                (deb, fin or deb, l.get("type"),
                 l.get("canton_source") or "", l.get("cantons_resultants") or ""))

    retenus, ecartes = {}, {}
    for dep, lignes in par_dep.items():
        # 1. le pavage de 1815 à 1870
        couvert, borne = [], "1815-01-01"
        for deb, fin, *_ in sorted(lignes):
            if deb > borne:
                break                      # trou : on ne sait pas
            borne = max(borne, fin)
        else:
            couvert = True
        if couvert is not True or borne < "1870-01-01":
            ecartes[dep] = f"registre incomplet, couvert jusqu'a {borne}"
            continue

        # 2. les refontes à rejouer, du plus récent au plus ancien
        refontes = [
            (_cle_unite(src.split(";")[0]),
             [_cle_unite(r) for r in res.split(";") if r.strip()])
            for deb, fin, typ, src, res in sorted(lignes, reverse=True)
            if typ == "demembrement" and src and res
        ]
        retenus[dep] = refontes
    return retenus, ecartes


def refondre(cantons, refontes):
    """Rejoue les démembrements à l'envers sur une liste de cantons.

    Chaque refonte fusionne les géométries des cantons résultants dans celle de
    leur source, et retire les résultants. Une refonte dont aucun résultant
    n'est trouvé est signalée, jamais silencieusement ignorée : mieux vaut une
    planche qui avoue une lacune qu'une planche qui la masque.
    """
    par_cle = {}
    for uid, nom, geom, ncom in cantons:
        par_cle.setdefault(_cle_unite(uid), []).append((uid, nom, geom, ncom))
        par_cle.setdefault(_cle_unite(nom or ""), []).append((uid, nom, geom, ncom))

    vivants = {uid: [uid, nom, geom, ncom] for uid, nom, geom, ncom in cantons}
    faits, rates = [], []

    for cle_src, cles_res in refontes:
        src = next((e for e in par_cle.get(cle_src, []) if e[0] in vivants), None)
        absorbes = []
        for cr in cles_res:
            if cr == cle_src:
                continue
            e = next((e for e in par_cle.get(cr, []) if e[0] in vivants), None)
            if e is not None and (src is None or e[0] != src[0]):
                absorbes.append(e)
        if src is None or not absorbes:
            rates.append(f"{cle_src} <- {'+'.join(cles_res)}")
            continue
        cible = vivants[src[0]]
        cible[2] = unary_union([cible[2]] + [e[2] for e in absorbes])
        cible[3] = cible[3] + sum(e[3] for e in absorbes)
        for e in absorbes:
            vivants.pop(e[0], None)
        faits.append(f"{cible[1] or src[0]} <- "
                     f"{'+'.join(e[1] or e[0] for e in absorbes)}")

    return [tuple(v) for v in vivants.values()], faits, rates


def departements(cur):
    cur.execute("""SELECT DISTINCT left(insee_geofla, 2) AS dep
                   FROM histgis.atom WHERE insee_geofla IS NOT NULL
                   ORDER BY 1""")
    return [r[0] for r in cur.fetchall()]


def connexion():
    """Ouvre la connexion, en essayant les emplacements de socket usuels."""
    if os.environ.get("HISTGIS_DSN"):
        return psycopg2.connect(os.environ["HISTGIS_DSN"])
    dernier = None
    for dsn in DSN_CANDIDATS:
        try:
            return psycopg2.connect(dsn)
        except psycopg2.OperationalError as e:
            dernier = e
    raise SystemExit(
        "Connexion impossible. Essayés :\n  "
        + "\n  ".join(DSN_CANDIDATS)
        + f"\n\nDernière erreur :\n{dernier}"
        "\nDéfinir HISTGIS_DSN pour forcer, par exemple :\n"
        "  export HISTGIS_DSN='dbname=histgis host=/var/run/postgresql user=adrien'"
    )


def main():
    args = sys.argv[1:]
    mode_1815 = "--1815" in args
    # `--un-seul` : tout dans un fichier, une planche par page, pour feuilleter
    # et comparer d'un departement a l'autre sans ouvrir 95 fichiers.
    mode_unique = "--un-seul" in args
    # `--2025` : ajoute une quatrieme planche par departement, tiree de
    # `can2025`. C'est la seule des quatre qui coupe les villes.
    mode_2025 = "--2025" in args
    voulus = [a for a in args if not a.startswith("--")]

    refontes_par_dep, ecartes = {}, {}
    if mode_1815:
        refontes_par_dep, ecartes = projection_1815()
        for dep, raison in sorted(ecartes.items()):
            print(f"  dep {dep} ecarte : {raison}")
        if not refontes_par_dep:
            raise SystemExit(
                "Aucun departement n'a de registre couvrant 1815-1870 sans trou\n"
                "dans cantons/mouvements_cantonaux.csv. Rien a reconstruire."
            )
        elig = set(refontes_par_dep)
        voulus = sorted(elig & set(voulus)) if voulus else sorted(elig)
        if not voulus:
            raise SystemExit(
                "Aucun des departements demandes n'a de registre complet\n"
                "jusqu'en 1815. Eligibles : " + ", ".join(sorted(elig))
            )
        for dep in voulus:
            n = len(refontes_par_dep[dep])
            print(f"  dep {dep} : {n} refonte(s) a rejouer"
                  if n else f"  dep {dep} : stable, aucune refonte")

    with connexion() as cx:
        cx.set_session(readonly=True)
        with cx.cursor() as cur:
            cur.execute("SET search_path TO histgis, public")
            if mode_2025:
                cur.execute("SELECT to_regclass('histgis.can2025')")
                if cur.fetchone()[0] is None:
                    raise SystemExit(
                        "Table can2025 absente. La poser d'abord :\n"
                        "    python3 cartes/couverture_cantons_2025.py")
            deps = voulus or departements(cur)
            unique, chemin_u, total = None, None, 0
            if mode_unique:
                chemin_u = SORTIE / ("cantons_tous_1815.pdf" if mode_1815
                                     else "cantons_tous.pdf")
                unique = PdfPages(chemin_u)
            for dep in deps:
                chemin = SORTIE / (f"dep_{dep}_1815.pdf" if mode_1815
                                   else f"dep_{dep}.pdf")
                pages = 0
                dates = ([("1870-06-01",
                           "1815 — projection",
                           "composition TRF-GIS de 1870. La base ne contient "
                           "rien avant 1870 : cette planche vaut pour 1815 "
                           "parce que l'atlas Gaudillere n'y releve AUCUNE "
                           "modification cantonale entre 1815 et 1876, et pour "
                           "cette raison seule")]
                         if mode_1815 else DATES)
                # nullcontext : le PDF commun ne doit pas etre ferme a la fin
                # de chaque departement, mais l'indentation du corps reste la
                # meme dans les deux modes.
                with (nullcontext(unique) if unique
                      else PdfPages(chemin)) as pdf:
                    for d, libelle, source in dates:
                        arg = {"d": d, "dep": dep}
                        cur.execute(SQL_CANTON, arg)
                        cantons = [(u, n, wkb.loads(bytes(g)), c)
                                   for u, n, g, c in cur.fetchall() if g]
                        if not cantons:
                            continue
                        if mode_1815:
                            cantons, faits, rates = refondre(
                                cantons, refontes_par_dep[dep])
                            source += (f". Refontes rejouees : "
                                       f"{'; '.join(faits) if faits else 'aucune'}")
                            if rates:
                                source += (f". NON APPLIQUEES, faute de "
                                           f"correspondance : {'; '.join(rates)}")
                        cur.execute(SQL_COMMUNE, arg)
                        communes = [(noms, disp, nc, wkb.loads(bytes(g)))
                                    for noms, disp, nc, g in cur.fetchall() if g]
                        cur.execute(SQL_PARTAGE, arg)
                        partages = cur.fetchone()[0]

                        # A3 portrait : il faut la place pour ~450 noms de
                        # communes sans que le corps devienne illisible.
                        fig, (axc, axl) = plt.subplots(
                            2, 1, figsize=(11.69, 16.53),
                            gridspec_kw={"height_ratios": [5, 1]})
                        planche(axc, axl, cantons, communes, dep,
                                libelle, source, partages)
                        fig.tight_layout()
                        pdf.savefig(fig)
                        plt.close(fig)
                        pages += 1

                    if mode_2025:
                        pages += planche_2025(cur, pdf, dep)
                total += pages
                if unique:
                    print(f"  dep {dep} : {pages} page(s)" if pages
                          else f"  dep {dep} : aucune donnée, ignoré")
                elif pages:
                    print(f"{chemin.name} : {pages} page(s)")
                else:
                    chemin.unlink(missing_ok=True)
                    print(f"dep {dep} : aucune donnée, ignoré")

            if unique:
                unique.close()
                print(f"\n{chemin_u.name} : {total} pages, "
                      f"{len(deps)} départements demandés")


if __name__ == "__main__":
    main()
