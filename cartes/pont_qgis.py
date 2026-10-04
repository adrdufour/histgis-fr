#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
pont_qgis.py — parler au QGIS ouvert, pour découper les villes multicantonales

    python3 cartes/pont_qgis.py ping
    python3 cartes/pont_qgis.py ville 38544        # monte le plan de travail
    python3 cartes/pont_qgis.py villes             # les 315, par coupes
    python3 cartes/pont_qgis.py appel get_layers '{}'

Pourquoi un pont, et pas le connecteur MCP
------------------------------------------
Le greffon `qgis_mcp_plugin` écoute sur 127.0.0.1:9876 dès que QGIS tourne.
Le connecteur MCP `qgis` de `~/.claude.json` lance `uvx` pour parler à ce même
port ; quand `uvx` manque, ou que la session a démarré avant son installation,
le connecteur tombe et la socket, elle, reste ouverte. Ce fichier parle
directement à la socket : il ne dépend ni d'uv, ni d'un redémarrage de session.

Protocole : longueur sur 4 octets big-endian, puis JSON
`{"type": …, "params": {…}}`. `QGIS_MCP_TOKEN` est joint s'il est défini —
le greffon refuse tout sans lui quand la variable est posée de son côté.

Ce que `ville` monte, et dans quel ordre
----------------------------------------
De bas en haut, parce que l'ordre de la légende est l'ordre du travail :

  fond communes    les voisines, contour gris — pour voir où la ville s'arrête
  ville            l'atome entier, en rouge, SANS remplissage : c'est le
                   polygone que les N fractions se partagent, et le seul
                   contour qui fasse foi
  iris             la trame d'accrochage, étiquetée par `nom_iris`

Les IRIS ne sont PAS les limites cantonales — ils sont calés sur la voirie et
les îlots, sauf à Paris. C'est un support où l'on CHOISIT des lignes déjà
propres au lieu d'en dessiner de nouvelles. `RESTE_A_FAIRE.md` § 2.

Toutes les couches sont des tables PostGIS entières avec un filtre `sql=`,
jamais une sous-requête : le fournisseur postgres de QGIS 3.22 part en core
dump sur une sous-requête d'URI (mesuré le 14 août 2026), alors qu'un filtre
sur table passe sans broncher.
"""

from __future__ import annotations

import json
import os
import socket
import struct
import subprocess
import sys

HOTE, PORT = "127.0.0.1", 9876
ENTETE = struct.Struct(">I")
PG = "dbname='histgis' host=/var/run/postgresql port=5432"


class PontFerme(RuntimeError):
    """QGIS n'écoute pas — greffon arrêté, ou QGIS fermé."""


def appel(type_, _delai=180, **params):
    """Un aller-retour avec le greffon. Lève sur refus, rend `result`."""
    try:
        s = socket.create_connection((HOTE, PORT), timeout=_delai)
    except OSError as e:
        raise PontFerme(
            f"{HOTE}:{PORT} ne répond pas ({e}). QGIS est-il ouvert, et le "
            "greffon qgis_mcp démarré (menu Extensions) ?") from e
    try:
        cmd = {"type": type_, "params": params}
        jeton = os.environ.get("QGIS_MCP_TOKEN", "").strip()
        if jeton:
            cmd["token"] = jeton
        charge = json.dumps(cmd).encode()
        s.sendall(ENTETE.pack(len(charge)) + charge)

        tampon = b""
        while len(tampon) < 4:
            bout = s.recv(65536)
            if not bout:
                raise PontFerme("fermeture avant l'en-tête")
            tampon += bout
        taille = ENTETE.unpack(tampon[:4])[0]
        tampon = tampon[4:]
        while len(tampon) < taille:
            bout = s.recv(65536)
            if not bout:
                raise PontFerme("fermeture pendant le corps")
            tampon += bout
        reponse = json.loads(tampon[:taille])
    finally:
        s.close()

    if reponse.get("status") != "success":
        raise RuntimeError(f"{type_} refusé : {reponse.get('message')}")
    return reponse.get("result")


def sql(requete):
    """Une requête sur histgis, hors QGIS. psql plutôt que psycopg2 : ce
    fichier doit tourner sous l'interpréteur système, celui qui a PyQGIS."""
    out = subprocess.run(
        ["psql", "-d", "histgis", "-At", "-F", "\t", "-c", requete],
        capture_output=True, text=True, check=True).stdout
    return [l.split("\t") for l in out.splitlines() if l]


# Marseille, Lyon et Paris sont codées par ARRONDISSEMENT MUNICIPAL dans
# CONTOURS-IRIS comme dans GEOFLA, jamais par leur code de commune. Joindre
# `code_insee = '13055'` rend ZÉRO, et un zéro n'a pas l'air d'une erreur :
# pour une petite ville ce serait la bonne réponse. C'est le piège n° 2 du
# `LISEZMOI.md`, et c'est l'ordre de grandeur attendu — 393 IRIS pour
# Marseille, 185 pour Lyon — qui le fait voir, pas la plausibilité.
PREFIXE_ARRONDISSEMENT = {"13055": "132", "69123": "693", "75056": "751"}


def predicat_iris(insee, col="code_insee"):
    """Le prédicat SQL qui attrape les IRIS d'une commune, arrondissements
    compris. Rendu à part pour que le filtre de couche et le comptage ne
    puissent pas diverger."""
    p = PREFIXE_ARRONDISSEMENT.get(insee)
    return f"{col} LIKE '{p}%'" if p else f"{col} = '{insee}'"


# Toutes les villes à au moins deux fractions, quelle que soit l'origine de
# leur géométrie. Le filtre `source <> 'fraction_cog'` d'avant n'en gardait que
# 119 (214 coupes) : il écartait les 196 villes dont les fractions viennent du
# COG — Bourg, Laon, Vichy… —, pourtant découpées comme les autres. Constaté
# le 26 septembre 2026 : 315 villes, 750 coupes.
REQ_VILLES = """
SET search_path TO histgis, public;
SELECT a.insee_geofla,
       coalesce(n.nom, CASE a.insee_geofla WHEN '69123' THEN 'LYON'
                                           WHEN '13055' THEN 'MARSEILLE' END,
                a.insee_geofla),
       count(*) - 1,
       (SELECT count(*) FROM iris_ville i
         WHERE CASE a.insee_geofla
                 WHEN '13055' THEN i.code_insee LIKE '132%%'
                 WHEN '69123' THEN i.code_insee LIKE '693%%'
                 WHEN '75056' THEN i.code_insee LIKE '751%%'
                 ELSE i.code_insee = a.insee_geofla END),
       string_agg(a.atom_id, ',' ORDER BY a.atom_id)
  FROM atom a
  JOIN atom_geom g USING (atom_id)
  LEFT JOIN noms_geofla n ON n.insee = a.insee_geofla
 WHERE a.insee_geofla IS NOT NULL AND a.fraction AND a.atom_id LIKE '%%#%%'
 GROUP BY 1, 2 HAVING count(*) > 1
"""


def villes():
    lignes = sql(REQ_VILLES + " ORDER BY 3 DESC, 2")
    return [{"insee": i, "nom": nom, "coupes": int(c), "iris": int(n),
             "atomes": a.split(",")} for i, nom, c, n, a in lignes]


def _couche(uri, nom, apres=None):
    return appel("add_vector_layer", path=uri, name=nom, provider="postgres")


def prepare_ville(insee):
    """Monte le plan de travail d'une ville dans le QGIS ouvert."""
    v = next((v for v in villes() if v["insee"] == insee), None)
    if v is None:
        sys.exit(f"{insee} n'est pas dans les villes à découper "
                 "(moins de deux fractions en base).")
    if not v["iris"]:
        print(f"ATTENTION : {v['nom']} n'a aucun IRIS — aucune ligne interne "
              "d'accrochage. Confolens, Tartas et Le Quesnoy sont dans ce cas.")

    atomes = "','".join(a.replace("'", "''") for a in v["atomes"])

    # Le fond d'abord : il doit finir SOUS les autres.
    _couche(f"{PG} key='ogc_fid' table=\"histgis\".\"geofla_commune\" (geom) "
            f"sql=code_dept='{insee[:2]}'", f"Communes {insee[:2]}")
    _couche(f"{PG} key='atom_id' table=\"histgis\".\"atom_geom\" (geom) "
            f"sql=atom_id IN ('{atomes}')", f"{v['nom']} — atome entier")
    _couche(f"{PG} key='code_iris' table=\"histgis\".\"iris_ville\" (geom) "
            f"sql={predicat_iris(insee)}", f"{v['nom']} — IRIS ({v['iris']})")

    appel("set_project_crs", crs="EPSG:2154")
    etendue = sql("SET search_path TO histgis,public; "
                  "SELECT ST_XMin(e), ST_YMin(e), ST_XMax(e), ST_YMax(e) FROM "
                  f"(SELECT ST_Extent(geom) e FROM iris_ville "
                  f"WHERE {predicat_iris(insee)}) t")[0]
    x1, y1, x2, y2 = (float(x) for x in etendue)
    m = max(x2 - x1, y2 - y1) * 0.06
    appel("set_canvas_extent", xmin=x1 - m, ymin=y1 - m, xmax=x2 + m, ymax=y2 + m)

    print(f"{v['nom']} ({insee}) — {v['coupes']} coupe(s) à tracer, "
          f"{v['iris']} IRIS, {len(v['atomes'])} fractions")
    return v


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    quoi = sys.argv[1]
    if quoi == "ping":
        print(appel("ping"))
    elif quoi == "villes":
        for v in villes():
            print(f"  {v['insee']}  {v['nom'][:28]:<28} "
                  f"{v['coupes']:>2} coupe(s)  {v['iris']:>3} IRIS")
    elif quoi == "ville":
        prepare_ville(sys.argv[2])
    elif quoi == "appel":
        print(json.dumps(appel(sys.argv[2],
                               **json.loads(sys.argv[3] if len(sys.argv) > 3 else "{}")),
                         ensure_ascii=False, indent=2))
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
