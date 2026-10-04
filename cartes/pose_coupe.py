#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
pose_coupe.py — éprouver les lignes de coupe d'une ville, poser les ancres, écrire

    # à blanc : découpe la commune avec la (ou les) ligne(s), dit ce qu'elle(s) rend(ent)
    python3 cartes/pose_coupe.py 03190 --wkt ligne.wkt --de 1870-01-01 --a 2013-01-01 \
        --ancre 24214#0323=sud-est --ancre 24214#0324=nord-ouest

    # plusieurs lignes à la fois (une ville à cinq cantons en demande au moins quatre)
    python3 cartes/pose_coupe.py 08105 --wkt l1.wkt --wkt l2.wkt --wkt l3.wkt … \
        --de 1982-03-14 --a 2013-01-01 --ancre …

    # puis la même commande avec une --note-fichier par ligne, et --ecrire

Ce que fait le passage à blanc — rien n'est écrit
-------------------------------------------------
Découpe `cible_ville(insee, date)` avec les lignes données ET les lignes déjà
posées pour la ville à cette date (hors celles qu'on remplace), exactement
comme `carte_coupe_ville()` le fera : chaque bout se raccorde au plus proche
du bord communal ou d'une autre ligne. Imprime chaque morceau — aire,
centroïde — et le nombre de fractions qui ont un canton à cette date. Autant
de morceaux que de fractions, sinon les lignes ne ferment pas ou laissent des
miettes : c'est ici qu'on le voit, pas après l'écriture.

POURQUOI PLUSIEURS LIGNES D'UN COUP — 25 septembre 2026. La première version
ne prenait qu'une ligne et refusait d'écrire une découpe incomplète. Or à
Charleville-Mézières, cinq cantons, aucune ligne seule ne rend cinq morceaux :
chacune était refusée. On éprouve et on écrit donc l'ensemble.

Les ancres
----------
`--ancre ATOME=DIRECTION` choisit, parmi les morceaux d'au moins 1 ha, celui
qui est le plus loin dans cette direction depuis le centre de la commune :
nord, sud, est, ouest, nord-est, sud-ouest… Le nom du canton dit souvent la
direction (Vienne-Nord, Montluçon-Est) ; c'est cette lecture-là qu'on
applique, et on la rend visible. `--ancre ATOME=POINT(x y)` pose un point
explicite quand le nom ne dit rien (« La Houillère », « Villers-Semeuse »).
Deux ancres sur le même morceau : refus.

Ce que fait `--ecrire`
----------------------
Remplace dans `cartes/coupes_ville.csv` les lignes de mêmes `coupe_id`, dans
`cartes/coupes_ville_ancres.csv` les ancres des mêmes atomes, puis joue
`sql/98_coupe_ville.sql` sous `appliquer` et imprime la recette de la ville.
Lire la recette, jamais le code de retour.

Écrit le 24 septembre 2026 après Vienne, Montluçon et Moulins.
"""

from __future__ import annotations

import argparse
import csv
import math
import re
import subprocess
import sys
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
LIGNES = RACINE / "cartes" / "coupes_ville.csv"
ANCRES = RACINE / "cartes" / "coupes_ville_ancres.csv"

DIRECTIONS = {"nord": (0, 1), "sud": (0, -1), "est": (1, 0), "ouest": (-1, 0)}


def psql(sql, **v):
    cmd = ["psql", "-d", "histgis", "-At", "-F", "\t", "-v", "ON_ERROR_STOP=1"]
    for k, x in v.items():
        cmd += ["-v", f"{k}={x}"]
    r = subprocess.run(cmd, input=sql, capture_output=True, text=True)
    if r.returncode:
        sys.exit(r.stderr)
    return [l.split("\t") for l in r.stdout.splitlines() if l and not l.startswith("SET")]


def sql_morceaux(n):
    """La découpe d'essai avec n lignes nouvelles, passées en :'w1'…, :'c1'…,
    et les ancres ponctuelles en :'pts' (MULTIPOINT, dans l'ordre) : la
    dernière colonne dit lesquelles tombent dans chaque morceau."""
    nouvelles = ",\n".join(f"(:'c{k}', ST_SetSRID(ST_GeomFromText(:'w{k}'), 2154))"
                           for k in range(1, n + 1))
    ids = ", ".join(f":'c{k}'" for k in range(1, n + 1))
    return f"""
SET search_path TO histgis, public;
WITH cible AS (SELECT cible_ville(:'insee', :'d'::date) g),
     bord  AS (SELECT ST_Boundary((SELECT g FROM cible)) g),
     toutes(cid, g) AS (
         VALUES {nouvelles}
         UNION ALL
         SELECT c.coupe_id, c.geom FROM coupe_ville c
          WHERE c.insee = :'insee' AND c.periode @> :'d'::date
            AND c.coupe_id <> ALL (ARRAY[{ids}])),
     -- raccord PUIS calage à 1 m sur le bord et les autres lignes : c'est ce
     -- que fait `carte_coupe_ville()` (voir `98`, Charleville-Mézières, L4).
     ref AS (SELECT t.cid, ST_Union((SELECT g FROM bord),
                 coalesce((SELECT ST_Union(o.g) FROM toutes o WHERE o.cid <> t.cid),
                          ST_GeomFromText('LINESTRING EMPTY', 2154))) r FROM toutes t),
     lames AS (SELECT ST_Snap(raccorde_ligne(t.g, ref.r), ref.r, 1.0) g
                 FROM toutes t JOIN ref USING (cid)),
     mo AS (SELECT (ST_Dump(ST_Polygonize(ST_Node(ST_Union(
                (SELECT g FROM bord), (SELECT ST_Union(g) FROM lames)))))).geom g)
SELECT ST_Area(g), ST_X(ST_Centroid(g)), ST_Y(ST_Centroid(g)),
       ST_AsText(ST_SnapToGrid(ST_PointOnSurface(g), 0.01)),
       -- un ILOT : un morceau qu'aucune ligne ne touche, partie entière de la
       -- cible (les îlots du cap d'Antibes). `98` le rattache au morceau ancré
       -- le plus proche ; il ne demande pas d'ancre.
       CASE WHEN ST_Intersects(g, (SELECT ST_Union(g) FROM lames)) THEN 'f' ELSE 't' END,
       coalesce((SELECT string_agg(((d).path[1] - 1)::text, ',')
                   FROM ST_Dump(ST_SetSRID(ST_GeomFromText(:'pts'), 2154)) d
                  WHERE ST_Contains(g, (d).geom)), '')
  FROM mo WHERE ST_Contains((SELECT g FROM cible), ST_PointOnSurface(g))
 ORDER BY 1 DESC;
"""


SQL_CONTEXTE = """
SET search_path TO histgis, public;
SELECT ST_Area(cible_ville(:'insee', :'d'::date)),
       ST_X(ST_Centroid(cible_ville(:'insee', :'d'::date))),
       ST_Y(ST_Centroid(cible_ville(:'insee', :'d'::date))),
       (SELECT string_agg(DISTINCT a.atom_id || '=' || coalesce(uv.nom, u.nom), ', ')
          FROM atom a
          JOIN membership m ON m.atom_id = a.atom_id AND m.niveau = 'canton' AND m.periode @> :'d'::date
          LEFT JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = 'canton'
          LEFT JOIN unit_version uv ON uv.unit_id = m.unit_id AND uv.periode @> :'d'::date
         WHERE a.insee_geofla = :'insee' AND a.atom_id LIKE '%#%');
"""

SQL_ROGNE = """
SET search_path TO histgis, public;
WITH l AS (SELECT ST_SetSRID(ST_GeomFromText(:'w'), 2154) g),
     p AS (SELECT (ST_Dump(ST_Difference((SELECT g FROM l),
              ST_Buffer(ST_Boundary(cible_ville(:'insee', :'d'::date)), :m)))).geom g)
SELECT ST_Length((SELECT g FROM l)), ST_Length(g), ST_AsText(ST_SnapToGrid(g, 0.01))
  FROM p ORDER BY ST_Length(g) DESC LIMIT 1;
"""


def direction(mot):
    x = y = 0.0
    for part in mot.lower().split("-"):
        if part not in DIRECTIONS:
            raise ValueError(f"direction inconnue : {mot}")
        x += DIRECTIONS[part][0]; y += DIRECTIONS[part][1]
    n = math.hypot(x, y)
    return x / n, y / n


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("insee")
    ap.add_argument("--wkt", action="append", required=True,
                    help="fichier contenant une LINESTRING, Lambert 93 ; répétable")
    ap.add_argument("--coupe-id", action="append", default=[],
                    help="un par --wkt, dans le même ordre ; défaut : <insee>-1, <insee>-2…")
    ap.add_argument("--note-fichier", action="append", default=[],
                    help="un par --wkt, dans le même ordre ; requis pour --ecrire")
    ap.add_argument("--de", required=True, help="valid_from des lignes (AAAA-MM-JJ)")
    ap.add_argument("--a", required=True, help="valid_to, exclu")
    ap.add_argument("--date-test", help="date de la découpe d'essai ; défaut : --de")
    ap.add_argument("--ancre", action="append", default=[], help="ATOME=direction ou ATOME=POINT(x y)")
    ap.add_argument("--rogner", type=float, metavar="M",
                    help="retirer de chaque ligne ce qui longe le bord communal à moins de M m "
                         "(Moulins : 10) ; la ligne écrite est la ligne rognée")
    ap.add_argument("--source", default="texte", choices=["texte", "iris", "main", "banc"])
    ap.add_argument("--morceaux", type=int, metavar="N",
                    help="régime sans fraction en base : N morceaux attendus, aucune ancre")
    ap.add_argument("--ancres-datees", action="store_true",
                    help="écrire les ancres avec --de/--a comme période de validité (Lille : les "
                         "mêmes fractions changent de limites d'un régime à l'autre)")
    ap.add_argument("--vides-admis", type=int, default=0, metavar="N",
                    help="avec --morceaux : N morceaux peuvent rester sans ancre, parce qu'ils "
                         "reviennent à un canton qui n'a pas de fraction de la ville en base "
                         "(Chambéry 1961-1973 : Bissy et Chambéry-le-Vieux, restés dans La "
                         "Motte-Servolex) ; ils ne seront pas tirés, et la note doit le dire")
    ap.add_argument("--ecrire", action="store_true")
    a = ap.parse_args()

    n = len(a.wkt)
    cids = a.coupe_id or [f"{a.insee}-{k}" for k in range(1, n + 1)]
    if len(cids) != n:
        sys.exit("autant de --coupe-id que de --wkt, ou aucun")
    d = a.date_test or a.de

    wkts = []
    for f in a.wkt:
        w = Path(f).read_text().strip()
        if not w.upper().startswith("LINESTRING"):
            sys.exit(f"{f} : une LINESTRING est attendue, pas {w[:20]}… "
                     "(une multiligne ne se raccorde pas : concaténer dans l'ordre du texte)")
        wkts.append(w)

    if a.rogner:
        # Une voie citée en tête ou en fin de texte peut ÊTRE la limite communale
        # sur une partie de son cours : la route de Decize à Moulins, 167 m. Là,
        # elle sépare la commune de sa voisine, pas deux cantons.
        for k, w in enumerate(wkts):
            lav, lap, w2 = psql(SQL_ROGNE, insee=a.insee, d=d, w=w, m=a.rogner)[0]
            wkts[k] = w2
            print(f"{cids[k]} : rognage à {a.rogner:g} m du bord, {float(lav):.0f} m -> {float(lap):.0f} m")

    aire, cx, cy, fractions = psql(SQL_CONTEXTE, insee=a.insee, d=d)[0]
    aire, cx, cy = float(aire), float(cx), float(cy)
    fr = [f for f in (fractions or "").split(", ") if f]
    actives = {f.split("=")[0] for f in fr}

    # Les ancres ponctuelles : celles de la commande, puis celles déjà posées
    # pour les AUTRES fractions actives de la ville (Lisieux : on pose les
    # lignes II/III sans reposer les deux ancres du 1er canton). Une fraction
    # peut en avoir plusieurs — une par morceau disjoint.
    donnees = [(s.partition("=")[0], s.partition("=")[2]) for s in a.ancre]
    cites = {x for x, _ in donnees}
    # Sans fraction active à la date (trou de `membership`), seules les ancres
    # de fractions qui ont un canton PENDANT la période des lignes — même règle
    # que `carte_coupe_ville()` (Bourg 1973-1982 : aucune).
    def portee(x):
        return psql("SET search_path TO histgis; SELECT count(*) FROM membership WHERE atom_id = :'x' "
                    "AND niveau = 'canton' AND periode && daterange(:'de'::date, :'a'::date);",
                    x=x, de=a.de, a=a.a) != [["0"]]
    # Une ancre datée (colonnes 4 et 5, vides = toujours) ne joue qu'à ses dates.
    def vaut(r, jour):
        return (len(r) < 5 or not r[3] or r[3] <= jour) and (len(r) < 5 or not r[4] or jour < r[4])
    deja = [(r[0], r[2]) for r in list(csv.reader(ANCRES.open()))[1:]
            if r[0] not in cites and vaut(r, d)
            and psql("SET search_path TO histgis; SELECT insee_geofla FROM atom WHERE atom_id = :'x';",
                     x=r[0]) == [[a.insee]]
            and (r[0] in actives or (not actives and portee(r[0])))]
    points = [(x, q.upper().replace(" (", "(")) for x, q in donnees if q.upper().startswith("POINT")] + deja
    pts = ("MULTIPOINT(" + ",".join(p[p.index("(") + 1:p.rindex(")")] for _, p in points) + ")"
           if points else "MULTIPOINT EMPTY")

    v = {"insee": a.insee, "d": d, "pts": pts}
    for k in range(n):
        v[f"w{k + 1}"] = wkts[k]; v[f"c{k + 1}"] = cids[k]
    # psql -At rend une colonne vide finale comme absente : d'où le `*reste`.
    tous = []
    ilots = []
    for m2, x, y, p, ilot, *reste in psql(sql_morceaux(n), **v):
        dans = reste[0] if reste else ""
        m = (float(m2), float(x), float(y), p, [int(i) for i in dans.split(",") if i])
        # Un îlot sans ancre (partie de la cible qu'aucune ligne ne touche) va au
        # morceau ancré le plus proche, au tirage comme ici : il n'est ni un
        # morceau à ancrer, ni un morceau perdu.
        # Et une miette de raccord (moins d'un hectare, sans ancre) aussi : même
        # règle que `98` depuis que la cible suit l'ANR (Lille, 27 septembre 2026).
        (ilots if (ilot == "t" or m[0] < 1e4) and not m[4] else tous).append(m)
    # Poussière de nodage : des polygones d'aire nulle que `ST_Polygonize`
    # rend là où un raccord frôle le bord. Même seuil que la recette de `98`.
    morceaux = [m for m in tous if m[0] >= 1.0]

    print(f"{a.insee} au {d} : cible {aire / 1e4:.1f} ha ; {len(fr)} fraction(s) avec canton : {', '.join(fr)}")
    print(f"  {n} ligne(s) éprouvée(s) : {', '.join(cids)}")
    if len(tous) > len(morceaux):
        print(f"  ({len(tous) - len(morceaux)} polygone(s) de poussière < 1 m² ignoré(s))")
    if ilots:
        print(f"  {len(ilots)} îlot(s) ou miette(s) sans ancre, {sum(m[0] for m in ilots) / 1e4:.2f} ha, "
              "rattaché(s) au morceau ancré le plus proche")
    for i, (m2, x, y, _, _) in enumerate(morceaux):
        print(f"  morceau {i} : {m2 / 1e4:8.1f} ha   centroïde ({x:.0f}, {y:.0f})"
              + ("   <- MIETTE" if m2 < 1e4 else ""))
    somme = sum(m[0] for m in morceaux) + sum(m[0] for m in ilots)

    # Qui tombe où : les ancres ponctuelles par la requête, les ancres en
    # direction par projection parmi les morceaux d'au moins 1 ha.
    ancres, occupe = [], {}
    for i, m in enumerate(morceaux):
        for k in m[4]:
            occupe.setdefault(i, []).append(points[k][0])
    for k, (atome, pt) in enumerate(points):
        i = next((i for i, m in enumerate(morceaux) if k in m[4]), None)
        origine = "point explicite" if k < len(points) - len(deja) else "ancre déjà posée"
        if k < len(points) - len(deja):
            ancres.append((atome, pt, f"{origine} -> morceau {i}"))
        else:
            print(f"  ancre {atome:14s} {pt:32s} ({origine} -> morceau {i})")
    gros = [i for i, m in enumerate(morceaux) if m[0] >= 1e4]
    for atome, quoi in donnees:
        if quoi.upper().startswith("POINT"):
            continue
        dx, dy = direction(quoi)
        i = max(gros, key=lambda k: (morceaux[k][1] - cx) * dx + (morceaux[k][2] - cy) * dy)
        occupe.setdefault(i, []).append(atome)
        ancres.append((atome, morceaux[i][3], f"{quoi} -> morceau {i}, {morceaux[i][0] / 1e4:.1f} ha"))
    for atome, pt, pourquoi in ancres:
        print(f"  ancre {atome:14s} {pt:32s} ({pourquoi})")

    # CONFORME : l'aire rendue égale la cible, chaque morceau porte UNE ancre,
    # chaque fraction active en a au moins une. Sans ancre du tout, l'ancienne
    # règle : autant de morceaux que de fractions.
    aire_ok = abs(somme - aire) < 1.0
    if a.morceaux is not None:
        # Un régime que la base ne connaît pas (Bourg-en-Bresse-I, II, III,
        # 1973-1982 : aucune fraction) : on range la ligne sans ancre, et on
        # vérifie le seul nombre de morceaux que le texte annonce.
        # DES ANCRES POUR PLUS TARD — 27 septembre 2026, Beauvais 1958-1986 : les
        # fractions existent en base (1870-1941, 1998-2013) mais sans appartenance
        # à ces dates. On admet des ancres nouvelles si chaque morceau en porte
        # exactement une : elles joueront le jour où les appartenances seront
        # inscrites.
        doubles = {i: x for i, x in occupe.items() if len(x) > 1}
        vides = [i for i in range(len(morceaux)) if i not in occupe]
        ok = (aire_ok and len(morceaux) == a.morceaux
              and (not (points or donnees) or (not doubles and len(vides) <= a.vides_admis)))
        if vides and len(vides) <= a.vides_admis:
            print(f"  {len(vides)} morceau(x) sans ancre admis (--vides-admis) : ils ne seront pas tirés")
        print(f"  {len(morceaux)} morceau(x) pour {a.morceaux} annoncé(s) par le texte, "
              + (f"{len(points)} ancre(s) posée(s) pour plus tard, " if points else "sans ancre, ") +
              f"somme {somme / 1e4:.1f} ha pour {aire / 1e4:.1f} : "
              + ("CONFORME" if ok else "NON CONFORME — ne pas écrire en l'état"))
    elif points or donnees:
        doubles = {i: x for i, x in occupe.items() if len(x) > 1}
        vides = [i for i in range(len(morceaux)) if i not in occupe]
        sans = actives - {x for xs in occupe.values() for x in xs}
        for i, x in doubles.items():
            print(f"  morceau {i} : {len(x)} ancres ({', '.join(x)}) — une ligne ne ferme pas")
        for i in vides:
            print(f"  morceau {i} : AUCUNE ancre — il sera perdu au tirage")
        if sans:
            print(f"  fractions sans ancre : {sorted(sans)}")
        ok = aire_ok and not doubles and not vides and not sans
    else:
        ok = aire_ok and len(morceaux) == len(fr)
    if a.morceaux is None:
      print(f"  {len(morceaux)} morceau(x) pour {len(fr)} fraction(s), "
          f"somme {somme / 1e4:.1f} ha pour {aire / 1e4:.1f} : "
          + ("CONFORME" if ok else "NON CONFORME — ne pas écrire en l'état"))

    if not a.ecrire:
        print("\nÀ blanc. Rien n'est écrit — relancer avec --note-fichier … --ecrire")
        return
    if not ok:
        sys.exit("Refus d'écrire : la découpe d'essai n'est pas conforme.")
    if len(a.note_fichier) != n:
        sys.exit("une --note-fichier par ligne : la note est la seule trace de ce qui est approché.")
    notes = [re.sub(r"\s+", " ", Path(f).read_text()).strip() for f in a.note_fichier]

    rows = list(csv.reader(LIGNES.open()))
    hdr, corps = rows[0], [r for r in rows[1:] if r[1] not in cids]
    for k in range(n):
        corps.append([a.insee, cids[k], a.de, a.a, a.source, notes[k], wkts[k]])
    with LIGNES.open("w", newline="") as f:
        w = csv.writer(f); w.writerow(hdr); w.writerows(corps)

    noms = dict(f.split("=", 1) for f in fr)
    # Une ancre posée pour une période où la base n'a rien (Beauvais 1958,
    # Boulogne 1985) : le nom vient de l'unité, à sa version la plus proche.
    for atome, _, _ in ancres:
        if atome not in noms:
            n = psql("SELECT coalesce((SELECT uv.nom FROM histgis.unit_version uv WHERE uv.unit_id = u.unit_id "
                     "ORDER BY lower(uv.periode) LIMIT 1), u.nom) FROM histgis.unit u "
                     "WHERE u.niveau = 'canton' AND u.unit_id = split_part(:'atome', '#', 2)", atome=atome)
            if n and n[0] and n[0][0]:
                noms[atome] = n[0][0]
    rows = list(csv.reader(ANCRES.open()))
    remplaces = {x[0] for x in ancres}
    # Ancres datées : on ne remplace que celles de la même période (ou sans date) ;
    # celles d'un autre régime de la même fraction restent.
    def recouvre(r):
        return (len(r) < 5 or not r[3] or r[3] < a.a) and (len(r) < 5 or not r[4] or r[4] > a.de)
    hdr = rows[0]
    corps = [r for r in rows[1:] if not (r[0] in remplaces and (not a.ancres_datees or recouvre(r)))]
    corps = [r + [""] * (5 - len(r)) for r in corps]
    for atome, pt, pourquoi in ancres:
        corps.append([atome, f"canton {noms.get(atome, '?')} ({pourquoi.split(' -> ')[0]})", pt,
                      a.de if a.ancres_datees else "", a.a if a.ancres_datees else ""])
    with ANCRES.open("w", newline="") as f:
        w = csv.writer(f); w.writerow(hdr); w.writerows(corps)
    print(f"\nécrit : {', '.join(cids)} dans {LIGNES.name}, {len(ancres)} ancre(s) dans {ANCRES.name}")

    r = subprocess.run(["psql", "-d", "histgis", "-1", "-v", "appliquer=1",
                        "-f", str(RACINE / "sql" / "98_coupe_ville.sql")],
                       cwd=RACINE, capture_output=True, text=True)
    sortie = r.stdout + r.stderr
    if "ERROR" in sortie:
        sys.exit(sortie[-3000:])
    for l in sortie.splitlines():
        if l.lstrip().startswith(a.insee) or "insee |" in l:
            print(l)


if __name__ == "__main__":
    main()
