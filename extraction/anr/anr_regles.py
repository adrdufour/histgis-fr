"""Extraction ANR-COMMUNES sous les regles arretees le 1er septembre 2026.

R1  intervalle semi-ouvert [StartDt, EndDt)
R2  dedoublonnage exact sur (Poly_ID, md5(geometrie), fenetre) — la fenetre
    fait partie de la cle : trois Poly_ID portent la meme geometrie sur deux
    fenetres successives, et les confondre coute des atomes.
R3  variantes d'un meme (id_com, fenetre) : arbitrees par anr_variantes.csv,
    produit par anr_variantes_verdict.py — la moins revendiquee par un tiers,
    a egalite la plus grande ; abstention si meme la meilleure est revendiquee
    pour l'essentiel.
R5  hors de ce fichier : les atomes qu'ANR ne couvre pas gardent leur geometrie
    actuelle, marquee source_geom.

Usage :  python3 anr_regles.py [annee ...]      (defaut : 1870 1940)
"""
import sqlite3, hashlib, pickle, sys, csv, os
from shapely import wkb

RACINE   = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
GPKG     = os.path.join(RACINE, "sources", "ANR_COMMUNES_22042026", "COMMUNES_22042026.gpkg")
VARIANTES= os.path.join(RACINE, "build", "anr_variantes.csv")
LAYER    = "geometries_only_processed"

def _wkb(blob):
    """Retire l'en-tete GeoPackage binaire pour ne garder que le WKB."""
    env = (blob[3] >> 1) & 0x07
    return blob[8 + {0: 0, 1: 32, 2: 48, 3: 48, 4: 64}[env]:]

def _verdicts():
    """poly_id -> True si R3 le retient. Absent du fichier = pas une variante."""
    if not os.path.exists(VARIANTES):
        raise SystemExit(f"{VARIANTES} manquant : lancer anr_variantes_verdict.py d'abord.")
    return {r["poly_id"]: r["verdict"] == "retenu"
            for r in csv.DictReader(open(VARIANTES))}

def extraire(year):
    v = _verdicts()
    c = sqlite3.connect(GPKG)
    vu, out = set(), []
    for i, nm, p, s, e, pt, g in c.execute(
            f"select id_com,NameCom,Poly_ID,StartDt,EndDt,PSEUDO_T,geom from '{LAYER}'"):
        if g is None:
            continue
        try:
            s, e = int(float(s)), int(float(e))
        except (TypeError, ValueError):
            continue
        if e <= s or not (s <= year < e):      # R1
            continue
        if v.get(p, True) is False:            # R3
            continue
        cle = (p, hashlib.md5(_wkb(g)).hexdigest(), s, e)   # la fenêtre fait partie de la clé
        if cle in vu:                          # R2
            continue
        vu.add(cle)
        out.append((int(i), nm, p, int(pt or 0), wkb.loads(_wkb(g))))
    return out

if __name__ == "__main__":
    for year in [int(a) for a in sys.argv[1:]] or [1870, 1940]:
        f = extraire(year)
        pickle.dump(f, open(f"/tmp/anr_regle_{year}.pkl", "wb"))
        ids = {x[0] for x in f}
        print(f"{year} : {len(f)} polygones, {len(ids)} id_com, "
              f"{sum(x[4].area for x in f)/1e6:,.0f} km²"
              + ("" if len(f) == len(ids) else "  ATTENTION : doublon d'id_com"))
