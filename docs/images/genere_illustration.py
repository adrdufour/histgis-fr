#!/usr/bin/env python3
"""Dessine docs/images/illustration.svg, l'image d'accueil du README.

Un département FICTIF, vu à trois dates. Rien ici ne vient de la base : le
but est de montrer le principe du projet (les communes ne bougent pas, leur
rattachement change), pas une géographie réelle. Le tirage est déterministe :
rejouer le script redonne le même fichier.

    python3 docs/images/genere_illustration.py

Dépend de numpy et de shapely >= 2.0 (déjà dans environment.yml).
"""
import math
from pathlib import Path

import numpy as np
from shapely import voronoi_polygons
from shapely.geometry import LineString, MultiPoint, Point, Polygon
from shapely.ops import split, unary_union

ICI = Path(__file__).resolve().parent
SORTIE = ICI / "illustration.svg"

rng = np.random.default_rng(1885)

# ---------------------------------------------------------------- le territoire
def contour():
    pts = []
    for i in range(160):
        t = 2 * math.pi * i / 160
        r = 1 + 0.10 * math.sin(3 * t + 0.6) + 0.06 * math.cos(5 * t + 1.1) + 0.03 * math.sin(9 * t)
        pts.append((r * math.cos(t) * 1.05, r * math.sin(t) * 0.92))
    return Polygon(pts)


DEP = contour()
minx, miny, maxx, maxy = DEP.bounds

# germes des communes, relâchés (Lloyd) pour des cellules régulières
germes = []
while len(germes) < 64:
    p = Point(rng.uniform(minx, maxx), rng.uniform(miny, maxy))
    if DEP.contains(p):
        germes.append((p.x, p.y))
germes = np.array(germes)

def cellules(g):
    vor = voronoi_polygons(MultiPoint([tuple(x) for x in g]), extend_to=DEP.buffer(1))
    cel = []
    for x in g:
        p = Point(x)
        for c in vor.geoms:
            if c.contains(p):
                cel.append(c.intersection(DEP))
                break
    return cel

for _ in range(4):
    cel = cellules(germes)
    germes = np.array([[c.centroid.x, c.centroid.y] for c in cel])
COMMUNES = cellules(germes)
N = len(COMMUNES)

# ------------------------------------------------------- les cantons de 1885
def kmeans(x, k, it=40):
    c = x[rng.choice(len(x), k, replace=False)]
    for _ in range(it):
        lab = np.argmin(((x[:, None] - c[None]) ** 2).sum(-1), axis=1)
        c = np.array([x[lab == j].mean(0) for j in range(k)])
    return lab, c

lab, centres = kmeans(germes, 6)

# la ville : au cœur du canton le plus central, pour que la scission
# donne deux cantons de taille comparable
canton_ville = int(np.argmin((centres ** 2).sum(1)))
membres = [i for i in range(N) if lab[i] == canton_ville]
VILLE = min(membres, key=lambda i: np.linalg.norm(germes[i] - centres[canton_ville]))
# une ville s'étend : on lui donne le sol de ses deux plus proches voisines,
# qui disparaissent du dessin (elle reste un seul atome jusqu'à sa coupe)
ABSORBEES = sorted((i for i in membres if i != VILLE),
                   key=lambda i: np.linalg.norm(germes[i] - germes[VILLE]))[:2]
COMMUNES[VILLE] = unary_union([COMMUNES[VILLE], *(COMMUNES[i] for i in ABSORBEES)]).buffer(1e-6).buffer(-1e-6)
germes[VILLE] = COMMUNES[VILLE].centroid.coords[0]

# palette : une couleur par unité, gardée tant que l'unité vit
PALETTE = ["#8fb8de", "#f2c6a0", "#b7d7a8", "#d9b8e3", "#f5e19a", "#a8d8d0",
           "#f0a8a8", "#c9c3ec"]

# ------------------------------------------------- trois états du rattachement
# atome -> canton. La ville devient deux atomes (fractions) à partir de 1962.
def etat_1885():
    return {i: (None if i in ABSORBEES else int(lab[i])) for i in range(N)}

# 1962 : le canton de la ville est scindé en Nord et Sud, la ville coupée
cy_ville = float(np.median([germes[i][1] for i in membres]))
if abs(cy_ville - germes[VILLE][1]) > 0.05:
    cy_ville = germes[VILLE][1]
NOUVEAU = 6
def etat_1962():
    e = etat_1885()
    for i in range(N):
        if lab[i] == canton_ville and e[i] is not None and i != VILLE and germes[i][1] < cy_ville:
            e[i] = NOUVEAU
    e[VILLE] = None  # remplacée par ses deux fractions
    return e

# 2012 (après 1972 et 1985) : trois communes passent d'un canton à son voisin, deux communes fusionnent
def voisins(i, j):
    return COMMUNES[i].buffer(1e-6).intersects(COMMUNES[j])

# le transfert : les trois communes du canton 'donneur' les plus proches du 'receveur'
autres = [k for k in range(6) if k != canton_ville]
donneur, receveur = None, None
meilleur = 1e9
for a in autres:
    for b in autres:
        if a < b:
            d = np.linalg.norm(centres[a] - centres[b])
            if d < meilleur:
                meilleur, donneur, receveur = d, a, b
cand = [i for i in range(N) if lab[i] == donneur]
cand.sort(key=lambda i: np.linalg.norm(germes[i] - centres[receveur]))
TRANSFERT = cand[:3]
SUIVIE = TRANSFERT[0]                      # la commune dont on raconte l'histoire

# la fusion : deux communes voisines d'un même canton, loin de tout le reste
pool = [i for i in range(N) if lab[i] not in (canton_ville, donneur, receveur)]
FUSION = None
for i in pool:
    for j in pool:
        if i < j and lab[i] == lab[j] and voisins(i, j):
            FUSION = (i, j)
            break
    if FUSION:
        break

def etat_2012():
    e = etat_1962()
    for i in TRANSFERT:
        e[i] = int(receveur)
    return e

# la ligne de coupe de la ville : une « rue » ondulée d'ouest en est
vc = COMMUNES[VILLE]
bx0, _, bx1, _ = vc.bounds
rue = LineString([(bx0 - 0.05, cy_ville + 0.01), (bx0 + (bx1 - bx0) * 0.35, cy_ville - 0.025),
                  (bx0 + (bx1 - bx0) * 0.65, cy_ville + 0.02), (bx1 + 0.05, cy_ville - 0.01)])
morceaux = sorted(split(vc, rue).geoms, key=lambda g: -g.centroid.y)
VILLE_NORD, VILLE_SUD = morceaux[0], unary_union(morceaux[1:]).buffer(1e-6).buffer(-1e-6)

# ------------------------------------------------------------------- dessin
W, H = 1200, 640
PW = 360                 # largeur d'un panneau
MARGE_X = (W - 3 * PW) / 4
Y0 = 92                  # haut des cartes
ECH = PW / ((maxx - minx) * 1.08)

def proj(x, y, ox):
    return (ox + (x - minx) * ECH + PW * 0.04, Y0 + (maxy - y) * ECH)

def chemin(geom, ox):
    if geom.is_empty:
        return ""
    polys = getattr(geom, "geoms", [geom])
    d = []
    for p in polys:
        if p.geom_type != "Polygon":
            continue
        for anneau in [p.exterior, *p.interiors]:
            pts = [proj(x, y, ox) for x, y in anneau.coords]
            d.append("M" + " L".join(f"{a:.1f},{b:.1f}" for a, b in pts) + " Z")
    return " ".join(d)

def ligne(geom, ox):
    pts = [proj(x, y, ox) for x, y in geom.coords]
    return "M" + " L".join(f"{a:.1f},{b:.1f}" for a, b in pts)

def couleur(c):
    return PALETTE[c % len(PALETTE)]

def panneau(ox, etat, annee, titre, notes, fractions, fusion, circ):
    s = []
    # atomes : communes entières, plus les fractions de la ville
    atomes = []
    for i in range(N):
        if etat.get(i) is None:
            continue
        g = COMMUNES[i]
        if fusion and i in fusion:
            if i == fusion[1]:
                continue
            g = unary_union([COMMUNES[fusion[0]], COMMUNES[fusion[1]]]).buffer(0)
        atomes.append((g, etat[i], i))
    if fractions:
        atomes.append((VILLE_NORD, int(canton_ville), "N"))
        atomes.append((VILLE_SUD, NOUVEAU, "S"))
    # fond des cantons
    for g, c, i in atomes:
        s.append(f'<path d="{chemin(g, ox)}" fill="{couleur(c)}" stroke="#ffffff" stroke-width="0.9"/>')
    # ancienne limite des communes fusionnées, en pointillé
    if fusion:
        lim = COMMUNES[fusion[0]].boundary.intersection(COMMUNES[fusion[1]].boundary)
        for seg in getattr(lim, "geoms", [lim]):
            if seg.geom_type == "LineString":
                s.append(f'<path d="{ligne(seg, ox)}" fill="none" stroke="#3d4a5c" '
                         f'stroke-width="1.4" stroke-dasharray="3 3"/>')
    # limites de cantons
    cantons = {}
    for g, c, i in atomes:
        cantons.setdefault(c, []).append(g)
    for c, gs in cantons.items():
        u = unary_union([x.buffer(1e-7) for x in gs]).buffer(-1e-7)
        s.append(f'<path d="{chemin(u, ox)}" fill="none" stroke="#3d4a5c" stroke-width="1.6" '
                 f'stroke-linejoin="round"/>')
    # circonscriptions : trait épais
    for groupe in circ:
        gs = [g for g, c, i in atomes if c in groupe]
        u = unary_union([x.buffer(1e-7) for x in gs]).buffer(-1e-7)
        s.append(f'<path d="{chemin(u, ox)}" fill="none" stroke="#1d2433" stroke-width="3.2" '
                 f'stroke-linejoin="round"/>')
    # la rue qui coupe la ville
    if fractions:
        r = rue.intersection(vc.buffer(-0.002))
        s.append(f'<path d="{chemin(vc, ox)}" fill="#c0392b" fill-opacity="0.10" stroke="#c0392b" '
                 f'stroke-width="1.2" stroke-dasharray="3 2"/>')
        for seg in getattr(r, "geoms", [r]):
            s.append(f'<path d="{ligne(seg, ox)}" fill="none" stroke="#ffffff" stroke-width="6" '
                     f'stroke-linecap="round"/>')
            s.append(f'<path d="{ligne(seg, ox)}" fill="none" stroke="#c0392b" stroke-width="3" '
                     f'stroke-linecap="round"/>')
        vx0, vy0 = proj((vc.bounds[0] + vc.bounds[2]) / 2, vc.bounds[3], ox)
        s.append(f'<text x="{vx0:.1f}" y="{vy0 - 4:.1f}" text-anchor="middle" class="petit" '
                 f'font-weight="700" style="fill:#c0392b" stroke="#fbfaf7" stroke-width="3" '
                 f'paint-order="stroke">ville coupée</text>')
    # la ville, pastille
    vx, vy = proj(*germes[VILLE], ox)
    s.append(f'<circle cx="{vx:.1f}" cy="{vy:.1f}" r="3.4" fill="#1d2433"/>')
    # la commune suivie
    gx, gy = proj(*COMMUNES[SUIVIE].centroid.coords[0], ox)
    s.append(f'<path d="{chemin(COMMUNES[SUIVIE], ox)}" fill="none" stroke="#e67e22" stroke-width="2.6"/>')
    s.append(f'<text x="{gx:.1f}" y="{gy + 4:.1f}" text-anchor="middle" class="petit" '
             f'font-weight="700" style="fill:#7a3d07">X</text>')
    # titres
    s.append(f'<text x="{ox + PW / 2:.1f}" y="{Y0 - 34}" text-anchor="middle" class="annee">{annee}</text>')
    s.append(f'<text x="{ox + PW / 2:.1f}" y="{Y0 - 14}" text-anchor="middle" class="sous">{titre}</text>')
    for k, n in enumerate(notes):
        s.append(f'<text x="{ox + PW / 2:.1f}" y="{Y0 + (maxy - miny) * ECH + 28 + 17 * k:.1f}" '
                 f'text-anchor="middle" class="note">{n}</text>')
    return "\n".join(s)

# regroupement des cantons en circonscriptions, par position de leur centre
def groupes_par_x(ids, k):
    ids = sorted(ids, key=lambda c: (centres[c][0] if c < 6 else centres[canton_ville][0]))
    taille = math.ceil(len(ids) / k)
    return [set(ids[i:i + taille]) for i in range(0, len(ids), taille)]

circ_1885 = groupes_par_x(list(range(6)), 2)
circ_1962 = groupes_par_x(list(range(7)), 3)
circ_2012 = [set(g) for g in circ_1962]
# un redécoupage électoral : le canton receveur change de circonscription
for g in circ_2012:
    g.discard(receveur)
cible = min((g for g in circ_2012 if donneur not in g), key=len, default=circ_2012[0])
cible.add(receveur)

svg = [f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}"
     role="img" aria-labelledby="t d">
<title id="t">histgis-fr : un même département à trois dates</title>
<desc id="d">Schéma illustratif sur un département fictif. Les communes restent les
mêmes ; leur rattachement aux cantons et aux circonscriptions change en 1962
et en 2012.</desc>
<style>
  text {{ font-family: "DejaVu Sans", "Segoe UI", Helvetica, Arial, sans-serif; fill: #1d2433; }}
  .annee {{ font-size: 26px; font-weight: 700; }}
  .sous  {{ font-size: 13px; fill: #55606e; }}
  .note  {{ font-size: 12.5px; fill: #3d4a5c; }}
  .petit {{ font-size: 11px; }}
  .tl    {{ font-size: 12.5px; }}
  .titre {{ font-size: 15px; font-weight: 700; }}
</style>
<rect x="0" y="0" width="{W}" height="{H}" rx="18" fill="#fbfaf7"/>
<rect x="0.5" y="0.5" width="{W - 1}" height="{H - 1}" rx="18" fill="none" stroke="#e3dfd6"/>
''']

ox = [MARGE_X + k * (PW + MARGE_X) for k in range(3)]
svg.append(panneau(ox[0], etat_1885(), "1885", "6 cantons · 2 circonscriptions",
                   ["Chaque commune est un atome,", "rattaché à un canton et à une circonscription"], False, None, circ_1885))
svg.append(panneau(ox[1], etat_1962(), "1962", "7 cantons · 3 circonscriptions",
                   ["Le canton de la ville est scindé :", "la limite suit une rue, la ville devient deux atomes"],
                   True, None, circ_1962))
svg.append(panneau(ox[2], etat_2012(), "2012", "7 cantons · 3 circonscriptions",
                   ["1972 : deux communes fusionnent (pointillé) ;", "1985 : trois communes, dont X, changent de canton"],
                   True, FUSION, circ_2012))

# flèches entre panneaux
for k in range(2):
    xa = ox[k] + PW + 4
    xb = ox[k + 1] - 4
    ym = Y0 + PW * 0.42
    svg.append(f'<path d="M{xa:.1f},{ym:.1f} L{xb - 6:.1f},{ym:.1f}" stroke="#9aa3ad" stroke-width="2"/>')
    svg.append(f'<path d="M{xb - 8:.1f},{ym - 5:.1f} L{xb:.1f},{ym:.1f} L{xb - 8:.1f},{ym + 5:.1f}" '
               f'fill="none" stroke="#9aa3ad" stroke-width="2"/>')

# légende des traits
LY = Y0 + (maxy - miny) * ECH + 82
legende = [("#ffffff", 0.9, "commune (atome)", "#d9d4c9"), ("#3d4a5c", 1.6, "canton", None),
           ("#1d2433", 3.2, "circonscription", None), ("#c0392b", 3, "limite dans une ville", None)]
lx = W / 2 - 330
for col, ep, lib, fond in legende:
    if fond:
        svg.append(f'<rect x="{lx - 2:.1f}" y="{LY - 9}" width="32" height="10" fill="{fond}"/>')
    svg.append(f'<line x1="{lx:.1f}" y1="{LY - 4}" x2="{lx + 28:.1f}" y2="{LY - 4}" stroke="{col}" '
               f'stroke-width="{ep}"/>')
    svg.append(f'<text x="{lx + 36:.1f}" y="{LY}" class="note">{lib}</text>')
    lx += 60 + 7.2 * len(lib)

# ligne de vie de la commune X : ce que stocke la table membership
TY = H - 96
TX0, TX1 = 210, W - 60
def tx(an):
    return TX0 + (an - 1870) / (2013 - 1870) * (TX1 - TX0)

svg.append(f'<text x="40" y="{TY - 30}" class="titre">Ce que la base stocke pour la commune X '
           f'<tspan class="sous" font-weight="400">— une ligne de membership par période [début, fin)</tspan></text>')
svg.append(f'<text x="40" y="{TY + 5}" class="tl">canton</text>')
svg.append(f'<text x="40" y="{TY + 33}" class="tl">circonscription</text>')

def barre(a, b, y, col, lib):
    svg.append(f'<rect x="{tx(a):.1f}" y="{y}" width="{tx(b) - tx(a):.1f}" height="18" rx="3" '
               f'fill="{col}" stroke="#3d4a5c" stroke-width="1"/>')
    svg.append(f'<text x="{tx(a) + 8:.1f}" y="{y + 14}" class="tl">{lib}</text>')

C, F = chr(65 + donneur), chr(65 + receveur)
barre(1870, 1985, TY - 9, couleur(donneur), f"canton {C}   [1870-01-01, 1985-03-10)")
barre(1985, 2013, TY - 9, couleur(receveur), f"canton {F}   [1985-03-10, …)")
barre(1870, 1958, TY + 19, "#dfe4ea", "1re circonscription   [1870, 1958)")
barre(1958, 1986, TY + 19, "#cdd5df", "2e   [1958, 1986)")
barre(1986, 2013, TY + 19, "#b9c4d2", "3e   [1986, …)")
for an in (1870, 1900, 1940, 1958, 1985, 2012):
    x = tx(an)
    svg.append(f'<line x1="{x:.1f}" y1="{TY + 41}" x2="{x:.1f}" y2="{TY + 47}" stroke="#55606e"/>')
    svg.append(f'<text x="{x:.1f}" y="{TY + 61}" text-anchor="middle" class="petit">{an}</text>')

svg.append(f'<text x="{W - 24}" y="26" text-anchor="end" class="petit" style="fill:#8a929c">'
           f'Schéma illustratif : département fictif, géométries tirées au hasard.</text>')
svg.append("</svg>\n")

SORTIE.write_text("\n".join(svg), encoding="utf-8")
print(f"{SORTIE} écrit ({SORTIE.stat().st_size // 1024} Ko), {N} communes, "
      f"ville = {VILLE}, transfert {donneur}->{receveur}, fusion {FUSION}")
