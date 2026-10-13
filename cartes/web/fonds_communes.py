#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
fonds_communes.py — les deux fichiers de référence de la carte « liste de
communes » de l'export Commons (AOP, intercommunalité, pays…).

    python3 cartes/web/fonds_communes.py     # écrit donnees/france.json
                                             #   et donnees/cog_actuel.json

1. `donnees/france.json` — la France des départements, pour le médaillon de
   situation, outre-mer compris (chacun dans sa case, à sa propre échelle). Tiré des `contours.json` que `export_web.py` a déjà écrits : pas
   de base, pas de PostGIS. Chaque contour est simplifié (Douglas-Peucker,
   ~800 m) : le médaillon fait deux cents pixels pour mille kilomètres, une
   limite départementale à 25 m y serait cent fois trop fine. Les versions
   datées que la simplification rend identiques sont fusionnées : il en reste
   une ou deux par département là où `contours.json` en compte trente.
   Le fichier porte aussi, par département, ses bornes et ses absences
   (1871-1918 pour l'Alsace-Moselle) : le médaillon de 1900 ne doit pas
   dessiner la Moselle française.

2. `donnees/cog_actuel.json` — les communes d'AUJOURD'HUI ramenées aux codes
   de la base. Une liste d'AOP ou d'intercommunalité se donne avec les noms en
   vigueur, et 5 470 lignes de `v_mvt_commune_2025.csv` sont des communes
   nouvelles : « Haut Valromey » n'existe pas dans le COG 2012 que lit la base,
   mais Hotonnes, Le Grand-Abergement, Le Petit-Abergement et Ruffieu, oui.
   On rejoue les mouvements postérieurs au 1er janvier 2012 (fusions 31-34,
   changements de département 41, renommages 10) et on n'écrit que les codes
   dont le sens a changé : code actuel -> [nom actuel, [codes 2012]].

Bibliothèque standard seulement, comme `servir.py` et `noms_cog.py`.
"""
import csv
import json
import math
import sys
from pathlib import Path

ICI = Path(__file__).resolve().parent
RACINE = ICI / "donnees"
MVT = ICI.parents[1] / "sources" / "v_mvt_commune_2025.csv"
COG2012 = RACINE / "noms_cog.json"
FRANCE2012 = ICI.parents[1] / "sources" / "cog" / "2012" / "france2012.txt"
TOL_KM = 0.8          # tolérance de simplification du médaillon
DEPUIS = "2012-01-01"  # état du COG que lit la base
# Les seules dates où la carte des départements change à l'échelle du
# médaillon : 1871 (Francfort : Meurthe-et-Moselle, Belfort, l'Alsace-Moselle
# annexée), 1919 (retour), 1968 (région parisienne). La Corse de 1976 n'en
# est pas une : `20` et `2A`/`2B` sont des départements distincts, dont les
# bornes disent quand chacun paraît.
EPOQUES = [-10000, 1871, 1919, 1968]


# --------------------------------------------------------------------------
# Douglas-Peucker sur un anneau, en kilomètres approchés (équirectangulaire
# calée sur 46,5° N : à l'échelle du médaillon, c'est exact à mieux qu'un
# pixel). Un tri radial d'abord, qui ramène 14 000 sommets à quelques
# centaines avant l'algorithme, sans rien changer au résultat visible.
# --------------------------------------------------------------------------
KX = 111.32 * math.cos(math.radians(46.5))
KY = 111.32


def simplifie(anneau, tol=TOL_KM):
    p = [(x * KX, y * KY) for x, y in anneau]
    r = [0]
    for i in range(1, len(p)):
        a, b = p[r[-1]], p[i]
        if (b[0] - a[0]) ** 2 + (b[1] - a[1]) ** 2 >= (tol / 3) ** 2:
            r.append(i)
    if r[-1] != len(p) - 1:
        r.append(len(p) - 1)
    q = [p[i] for i in r]
    if len(q) < 4:
        return None
    garde = [False] * len(q)
    garde[0] = garde[-1] = True
    # anneau fermé : on coupe au point le plus éloigné du premier
    loin = max(range(len(q)), key=lambda i: (q[i][0] - q[0][0]) ** 2 + (q[i][1] - q[0][1]) ** 2)
    garde[loin] = True
    pile = [(0, loin), (loin, len(q) - 1)]
    while pile:
        i, j = pile.pop()
        if j <= i + 1:
            continue
        (ax, ay), (bx, by) = q[i], q[j]
        dx, dy = bx - ax, by - ay
        n = math.hypot(dx, dy) or 1e-12
        dmax, k = -1, -1
        for m in range(i + 1, j):
            d = abs(dy * (q[m][0] - ax) - dx * (q[m][1] - ay)) / n
            if d > dmax:
                dmax, k = d, m
        if dmax > tol:
            garde[k] = True
            pile += [(i, k), (k, j)]
    out = [(round(q[i][0] / KX, 4), round(q[i][1] / KY, 4)) for i in range(len(q)) if garde[i]]
    if len(out) < 4:
        return None
    return out


def aire_km2(anneau):
    a = 0.0
    for (x0, y0), (x1, y1) in zip(anneau, anneau[1:]):
        a += (x0 * KX) * (y1 * KY) - (x1 * KX) * (y0 * KY)
    return abs(a) / 2


def polygones(g, out):
    if not g:
        return out
    t = g.get("type")
    if t == "Polygon":
        out.append(g["coordinates"])
    elif t == "MultiPolygon":
        out.extend(g["coordinates"])
    elif t == "GeometryCollection":
        for x in g["geometries"]:
            polygones(x, out)
    return out


def contour_simplifie(g, tol=TOL_KM, aire_min=4):
    """Anneaux extérieurs seulement : à cette échelle un trou départemental
    (une enclave) fait moins d'un pixel, sauf le Comtat — dessiné par le
    Vaucluse, qui le recouvre."""
    polys = []
    for poly in polygones(g, []):
        if not poly or aire_km2(poly[0]) < aire_min:   # îlots invisibles
            continue
        r = simplifie(poly[0], tol)
        if r:
            polys.append([[list(c) for c in r]])
    return {"type": "MultiPolygon", "coordinates": polys} if polys else None


def france():
    index = json.loads((RACINE / "index.json").read_text(encoding="utf-8"))
    deps = {}
    for d in index["departements"]:
        code = d["code"]
        f_cont = RACINE / "dep" / code / "contours.json"
        f_idx = RACINE / "dep" / code / "index.json"
        if not f_cont.exists():
            continue
        cont = json.loads(f_cont.read_text(encoding="utf-8"))
        idx = json.loads(f_idx.read_text(encoding="utf-8")) if f_idx.exists() else {}
        # L'outre-mer a sa case, à sa propre échelle : la Martinique y fait
        # cent pixels pour soixante kilomètres, quatre fois l'échelle de la
        # métropole. On simplifie donc quatre fois moins, et on garde les
        # îlots dès 1 km² (les Saintes, Marie-Galante, Petite-Terre).
        dom = idx.get("espace", "metropole") != "metropole"
        tol, aire_min = (TOL_KM / 4, 1) if dom else (TOL_KM, 4)
        # `contours.json` n'est pas une suite de frontières : c'est, pour chaque
        # année servie, l'union des communes que la composition de cette année
        # rattache. Une composition incomplète (1955, 1973…) y fait des trous
        # — la Côte-d'Or perd 125 km² en 1955, le Var 900 en 1973. Le médaillon
        # ne retient donc que les ÉPOQUES où la carte des départements change
        # vraiment à cette échelle, et prend dans chacune le contour le plus
        # étendu, c'est-à-dire le plus complet.
        par_epoque = {}
        for an in sorted(cont, key=int):
            e = max(k for k, b in enumerate(EPOQUES) if int(an) >= b)
            g = contour_simplifie(cont[an], tol, aire_min)
            if not g:
                continue
            aire = sum(aire_km2(p[0]) for p in g["coordinates"])
            if e not in par_epoque or aire > par_epoque[e][0]:
                par_epoque[e] = (aire, g)
        # `a` : la première année de l'époque (1870 pour la première, faute
        # de contour plus ancien), pas celle du contour retenu.
        versions = [{"a": max(EPOQUES[e], min(int(x) for x in cont)), "g": g}
                    for e, (_, g) in sorted(par_epoque.items())]
        if not versions:
            continue
        deps[code] = {"nom": d["nom"], "noms": d.get("noms"),
                      "bornes": idx.get("bornes") or d.get("bornes"),
                      "absences": [[a, b] for a, b, *_ in idx.get("absences") or []],
                      "outremer": dom,
                      "v": versions}
        print(f"  {code} {d['nom']:<28} {len(cont):>3} contours -> {len(versions)} version(s)",
              flush=True)
    out = RACINE / "france.json"
    out.write_text(json.dumps({"tolerance_km": TOL_KM, "departements": deps},
                              ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(f"{len(deps)} départements -> {out} ({out.stat().st_size // 1024} Ko)")


def cog_actuel():
    if not MVT.exists():
        sys.exit(f"introuvable : {MVT}")
    if not COG2012.exists():
        sys.exit(f"introuvable : {COG2012} — lancer d'abord cartes/web/noms_cog.py")
    noms12 = json.loads(COG2012.read_text(encoding="utf-8"))
    with open(MVT, encoding="utf-8", newline="") as f:
        lignes = [r for r in csv.DictReader(f) if r["DATE_EFF"] > DEPUIS]
    lignes.sort(key=lambda r: r["DATE_EFF"])
    # Le COG 2012 tient aussi les communes disparues avant 2012 : on ne suit
    # que celles qui sont actives en 2012, c'est-à-dire celles que le fichier
    # des mouvements touche ou que rien ne touche — toutes, donc, puisqu'une
    # disparue n'apparaît dans aucun mouvement postérieur.
    actuel = {c: c for c in noms12}           # code 2012 -> code d'aujourd'hui
    nom = {}                                  # code d'aujourd'hui -> nom, s'il a changé
    par_date = {}
    for r in lignes:
        par_date.setdefault(r["DATE_EFF"], []).append(r)
    for date in sorted(par_date):
        lot = par_date[date]
        renvoi = {}
        for r in lot:
            if r["TYPECOM_AV"] != "COM" or r["TYPECOM_AP"] != "COM":
                continue
            if r["MOD"] in ("31", "32", "33", "34", "41"):
                renvoi[r["COM_AV"]] = r["COM_AP"]
            if r["MOD"] in ("10", "31", "32", "33", "34", "41"):
                nom[r["COM_AP"]] = r["LIBELLE_AP"]
        if renvoi:
            for c12, c in actuel.items():
                if c in renvoi:
                    actuel[c12] = renvoi[c]
    membres = {}
    for c12, c in actuel.items():
        membres.setdefault(c, []).append(c12)
    sortie = {}
    for c, ms in sorted(membres.items()):
        n = nom.get(c, noms12.get(c))
        if ms == [c] and n == noms12.get(c):
            continue                        # rien n'a changé : noms_cog suffit
        sortie[c] = [n, sorted(ms)]
    # Les codes du COG 2012 qui n'étaient déjà plus des communes en 2012
    # (associées, périmées, anciens codes) : la page les garde, pour une
    # carte ancienne, mais les fait passer après une commune active homonyme.
    # Un code peut figurer deux fois (active et ancienne) : il n'est inactif
    # que si aucune ligne ne le dit actif.
    statuts = {}
    if FRANCE2012.exists():
        with open(FRANCE2012, encoding="cp1252", newline="") as f:
            for r in csv.DictReader(f, delimiter="\t"):
                code = r["DEP"] + (r["COM"][-2:] if len(r["DEP"]) == 3 else r["COM"])
                statuts[code] = statuts.get(code, False) or r["ACTUAL"] == "1"
    inactives = sorted(c for c, actif in statuts.items() if not actif)
    out = RACINE / "cog_actuel.json"
    out.write_text(json.dumps({"millesime": "2025", "depuis": DEPUIS, "communes": sortie,
                               "inactives_2012": inactives},
                              ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    fusions = sum(1 for v in sortie.values() if len(v[1]) > 1)
    print(f"{len(sortie)} codes changés ({fusions} communes nouvelles ou fusions) -> {out}")


if __name__ == "__main__":
    quoi = sys.argv[1:] or ["cog", "france"]
    if "cog" in quoi:
        cog_actuel()
    if "france" in quoi:
        france()
