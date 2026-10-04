#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
recupere_voirie.py — la voirie nommée des villes à découper, depuis la BD TOPO

    python3 cartes/recupere_voirie.py 38544            # une ville
    python3 cartes/recupere_voirie.py 38544 13055      # plusieurs
    python3 cartes/recupere_voirie.py --toutes         # les 119

Produit, par ville, dans `cartes/sorties/voirie/` :
    <insee>_voies.geojson      BDTOPO_V3:voie_nommee — une entité par voie BAN,
                               tous tronçons réunis, `nom_voie_ban` en clair
    <insee>_troncons.geojson   BDTOPO_V3:troncon_de_route — le réseau entier,
                               y compris places et passages qu'aucune voie
                               nommée ne porte
    <insee>_eau.geojson        BDTOPO_V3:troncon_hydrographique — les textes
                               délimitent aussi par cours d'eau et canaux

Pourquoi la BD TOPO, et pas OpenStreetMap
-----------------------------------------
Les textes de délimitation (décrets, lois, arrêtés) décrivent les coupes par
rues, places, cours d'eau, voies ferrées. Les IRIS sont d'un ordre de grandeur
trop grossiers pour les suivre : à Vienne le plus petit fait 26 ha, ~505 m de
côté, et la chaîne de rues de la délimitation tient dedans.

OpenStreetMap porterait la même voirie, mais sous licence ODbL — exclue par la
contrainte du `LISEZMOI.md` : le projet alimente Wikipédia et Wikidata, toute
source doit être CC BY-SA ou Licence Ouverte. Proposé le 23 septembre 2026
avant qu'on ne s'en avise ; écarté le 24. La BD TOPO est sous **Licence
Ouverte Etalab 2.0** depuis 2021, et vient du même WFS que CONTOURS-IRIS.

Marseille, Lyon, Paris
----------------------
La BAN code leurs voies par ARRONDISSEMENT (13201-13216, 69381-69389,
75101-75120), jamais par le code de commune. `insee_commune = '13055'` rendrait
zéro voie — et zéro n'a pas l'air d'une erreur. Même piège, même parade que
`pont_qgis.py` : le préfixe d'arrondissement.

Rien n'est chargé en base : ces fichiers sont une trame de lecture pour QGIS.
La ligne de coupe qu'on en tire va dans `cartes/coupes_ville.csv`, et c'est
elle seule que `sql/98_coupe_ville.sql` charge.
"""

from __future__ import annotations

import json
import sys
import urllib.parse
import urllib.request
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
SORTIE = RACINE / "cartes" / "sorties" / "voirie"
WFS = "https://data.geopf.fr/wfs/ows"

PREFIXE_ARRONDISSEMENT = {"13055": "132", "69123": "693", "75056": "751"}

COUCHES = {
    # suffixe : (couche, attribut commune — un ou deux côtés)
    "voies":    ("BDTOPO_V3:voie_nommee", ["insee_commune"]),
    "troncons": ("BDTOPO_V3:troncon_de_route",
                 ["insee_commune_gauche", "insee_commune_droite"]),
}


def filtre(attributs, insee):
    p = PREFIXE_ARRONDISSEMENT.get(insee)
    un = (lambda a: f"{a} LIKE '{p}%'") if p else (lambda a: f"{a}='{insee}'")
    return " OR ".join(un(a) for a in attributs)


def get_feature(couche, cql=None, bbox=None, page=5000):
    """Tout ce que le WFS rend, page après page. Le serveur plafonne une
    réponse ; sans pagination, une grande ville serait tronquée en silence."""
    feats, debut = [], 0
    while True:
        q = {"SERVICE": "WFS", "VERSION": "2.0.0", "REQUEST": "GetFeature",
             "TYPENAMES": couche, "SRSNAME": "EPSG:2154",
             "OUTPUTFORMAT": "application/json",
             "COUNT": str(page), "STARTINDEX": str(debut)}
        if cql:
            q["CQL_FILTER"] = cql
        if bbox:
            q["BBOX"] = ",".join(str(v) for v in bbox) + ",EPSG:2154"
        url = WFS + "?" + urllib.parse.urlencode(q)
        with urllib.request.urlopen(url, timeout=180) as r:
            lot = json.load(r).get("features", [])
        feats += lot
        if len(lot) < page:
            return feats
        debut += page


def emprise(feats, marge=300):
    xs, ys = [], []
    def pts(c):
        if isinstance(c[0], (int, float)):
            xs.append(c[0]); ys.append(c[1])
        else:
            for s in c:
                pts(s)
    for f in feats:
        if f.get("geometry"):
            pts(f["geometry"]["coordinates"])
    return (min(xs) - marge, min(ys) - marge, max(xs) + marge, max(ys) + marge)


def ecrit(chemin, feats):
    chemin.write_text(json.dumps({
        "type": "FeatureCollection",
        "crs": {"type": "name", "properties": {"name": "urn:ogc:def:crs:EPSG::2154"}},
        "features": feats}, ensure_ascii=False))


def recupere(insee):
    SORTIE.mkdir(parents=True, exist_ok=True)
    bilan = {}
    for suffixe, (couche, attrs) in COUCHES.items():
        feats = get_feature(couche, cql=filtre(attrs, insee))
        ecrit(SORTIE / f"{insee}_{suffixe}.geojson", feats)
        bilan[suffixe] = feats
    # L'eau n'a pas d'attribut commune : on la prend dans l'emprise des voies.
    # Un cours d'eau qui borde la ville sans y entrer (le Rhône à Vienne) est
    # souvent une limite citée, et c'est l'emprise, pas la commune, qui l'attrape.
    boite = emprise(bilan["voies"] + bilan["troncons"])
    eau = get_feature("BDTOPO_V3:troncon_hydrographique", bbox=boite)
    ecrit(SORTIE / f"{insee}_eau.geojson", eau)
    # Le chemin de fer non plus n'a pas d'attribut commune, et les décrets le
    # citent sans cesse (« la voie ferrée jusqu'au pont du faubourg du Theux »,
    # Charleville-Mézières, 1973 et 1982). Ajouté le 25 septembre 2026.
    fer = get_feature("BDTOPO_V3:troncon_de_voie_ferree", bbox=boite)
    ecrit(SORTIE / f"{insee}_fer.geojson", fer)
    print(f"{insee} : {len(bilan['voies'])} voies nommées, "
          f"{len(bilan['troncons'])} tronçons, {len(eau)} tronçons d'eau, "
          f"{len(fer)} tronçons de voie ferrée")


def main():
    args = sys.argv[1:]
    if not args:
        sys.exit(__doc__)
    if args == ["--toutes"]:
        sys.path.insert(0, str(RACINE / "cartes"))
        from pont_qgis import villes
        args = [v["insee"] for v in villes()]
    for insee in args:
        recupere(insee)


if __name__ == "__main__":
    main()
