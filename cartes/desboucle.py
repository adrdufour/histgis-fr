#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
desboucle.py — retirer d'une ligne de coupe ses recoupements, un par un

    python3 cartes/desboucle.py ligne.wkt ligne_propre.wkt

Une ligne tirée par plus courts chemins successifs se recoupe parfois : deux
chemins qui entrent et sortent d'un même carrefour, un raccord qui revient sur
ses pas. `ST_IsSimple` le dit ; `pose_coupe.py` le paie en miettes. On cherche
la première paire de segments non voisins qui se coupent, on remplace tout ce
qui est entre eux par leur point d'intersection, et on recommence.

Écrit le 25 septembre 2026 sur Saint-Quentin, après l'avoir fait à la main
pour Aix-en-Provence, Lisieux et Bourg-en-Bresse.
"""
import subprocess, sys
SQL = """
WITH l AS (SELECT ST_SetSRID(ST_GeomFromText(:'w'),2154) g),
 s AS (SELECT (d).path[1] i, (d).geom seg FROM (SELECT ST_DumpSegments((SELECT g FROM l)) d) x),
 x AS (SELECT a.i ia, b.i ib, ST_GeometryN(ST_Intersection(a.seg,b.seg),1) p FROM s a JOIN s b ON b.i > a.i + 1 AND ST_Intersects(a.seg,b.seg) ORDER BY a.i LIMIT 1),
 p AS (SELECT (d).path[1] i, (d).geom pt FROM (SELECT ST_DumpPoints((SELECT g FROM l)) d) y)
SELECT CASE WHEN (SELECT count(*) FROM x)=0 THEN 'OK' ELSE
  ST_AsText(ST_MakeLine(ARRAY(SELECT pt FROM (SELECT i, pt FROM p WHERE i <= (SELECT ia FROM x)
     UNION ALL SELECT (SELECT ia FROM x)+1, (SELECT p FROM x) UNION ALL SELECT i, pt FROM p WHERE i > (SELECT ib FROM x)) z ORDER BY i))) END;
"""
w = open(sys.argv[1]).read().strip(); n = 0
while True:
    r = subprocess.run(["psql","-d","histgis","-XAt","-v",f"w={w}"], input=SQL, capture_output=True, text=True).stdout.strip()
    if r == "OK" or not r: break
    w = r; n += 1
open(sys.argv[2], "w").write(w); print(n, "recoupement(s) retiré(s)")
