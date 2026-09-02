#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
banc_export_web.py — éprouve les fonctions PURES de `export_web.py`, sans base.

    python3 cartes/banc_export_web.py

Ce que ce banc peut contrôler, et ce qu'il ne peut pas
-----------------------------------------------------
Il ne touche ni à PostgreSQL ni au disque. Il ne dira donc RIEN sur la justesse
d'un contour dissous, sur la coïncidence des limites cantonales et communales,
ni sur le coût d'une requête — c'est exactement la limite que `sql/banc_82.sh`
s'était reconnue, et qui lui avait fait manquer les trois pièges de coût du § 7.

Ce qu'il contrôle est la chose que la base ne peut PAS contrôler à notre place :
la construction de la chronologie géométrique d'un atome à partir des segments
d'ANR. C'est du raisonnement sur des intervalles, et le raisonnement sur des
intervalles est là où ce dépôt s'est trompé le plus souvent — R1 et sa borne
semi-ouverte, R2 et sa fenêtre oubliée dans la clé, la convention de date
d'effet du 28 août. Une fonction qui pave 1815-2012 avec des trous à combler
mérite un banc à elle.

Le cas qui justifie ce fichier à lui seul est le § 3 : ANR a 532 trous de
chronologie qu'il ne déclare pas, et une commune des Ardennes documentée
`1790-1828 | 1871-2020` doit ressortir en TROIS versions, pas deux.
"""

import sys
import types
from pathlib import Path

# `export_web` importe psycopg2, qui n'a rien à faire dans un banc hors base.
# On le remplace par un mannequin : le banc n'appelle aucune fonction qui s'en
# sert, et exiger le pilote pour éprouver de l'arithmétique d'intervalles
# rendrait le banc injouable là où il est le plus utile — sur une machine qui
# n'a pas la base.
if "psycopg2" not in sys.modules:
    faux = types.ModuleType("psycopg2")
    faux.Error = Exception
    faux.connect = lambda *a, **k: (_ for _ in ()).throw(
        RuntimeError("le banc ne se connecte pas"))
    sys.modules["psycopg2"] = faux

sys.path.insert(0, str(Path(__file__).resolve().parent))
import export_web as E                                        # noqa: E402


ECHECS = []


def verifie(titre, obtenu, attendu):
    if obtenu == attendu:
        print(f"  ok   {titre}")
    else:
        print(f"  ÉCHEC {titre}\n        obtenu  : {obtenu}\n"
              f"        attendu : {attendu}")
        ECHECS.append(titre)


def geo(marque):
    """Un GeoJSON minimal mais DISTINCT, pour que les empreintes diffèrent."""
    return ('{"type":"Polygon","coordinates":[[[%d,0],[%d,1],[%d,1],[0,0]]]}'
            % (marque, marque, marque))


def pt(marque):
    return '{"type":"Point","coordinates":[%d.5,4.5]}' % marque


def resume(versions):
    """(année de début, source) — la seule chose que le banc a besoin de lire."""
    return [(v["a"], "vide" if v["g"] is None else ("repli" if v["r"] else "anr"))
            for v in versions]


print(__doc__.strip().splitlines()[0])
print()

# ---------------------------------------------------------------------------
print("§ 1. Couverture complète par ANR — une seule version, aucun repli")
# ---------------------------------------------------------------------------
v = E.construit_versions([(1790, 2020, geo(1), pt(1))], (geo(9), pt(9)))
verifie("un segment débordant des deux côtés", resume(v), [(1815, "anr")])
verifie("l'année de début est ramenée à AN_MIN", v[0]["a"], E.AN_MIN)

v = E.construit_versions(
    [(1790, 1876, geo(1), pt(1)), (1876, 2020, geo(2), pt(2))], (geo(9), pt(9)))
verifie("deux segments jointifs", resume(v), [(1815, "anr"), (1876, "anr")])

# ---------------------------------------------------------------------------
print("\n§ 2. ANR fait naître la commune APRÈS 1815 — le report de `11`")
# ---------------------------------------------------------------------------
# 448 des 486 atomes « vivants sans polygone ANR » sont de cette famille : notre
# base les fait vivre plus tôt qu'ANR ne les fait naître. Le repli doit couvrir
# l'avant, et être marqué comme tel — c'est la part INFÉRÉE de la couverture,
# celle que `83_anr_ecart_couverture.sql` chiffre.
v = E.construit_versions([(1880, 2020, geo(1), pt(1))], (geo(9), pt(9)))
verifie("repli avant la naissance", resume(v), [(1815, "repli"), (1880, "anr")])

# ---------------------------------------------------------------------------
print("\n§ 3. LE TROU DE CHRONOLOGIE — les vingt communes des Ardennes")
# ---------------------------------------------------------------------------
# `1790-1828 | 1871-2020` : un polygone avant, un après, RIEN entre. ANR ne le
# déclare pas. Une construction qui prendrait le premier et le dernier segment
# rendrait deux versions et afficherait la forme de 1828 en 1850 comme si elle
# était attestée.
v = E.construit_versions(
    [(1790, 1828, geo(1), pt(1)), (1871, 2020, geo(2), pt(2))], (geo(9), pt(9)))
verifie("trou interne comblé et marqué",
        resume(v), [(1815, "anr"), (1828, "repli"), (1871, "anr")])
verifie("le repli est bien la forme d'atom_geom",
        v[1]["k"], E.hashlib.md5(geo(9).encode()).hexdigest()[:10])

# Le même trou, mais sans polygone de repli disponible : l'intervalle doit être
# écrit COMME VIDE. Le sauter laisserait la page prolonger la version d'avant.
v = E.construit_versions(
    [(1790, 1828, geo(1), pt(1)), (1871, 2020, geo(2), pt(2))], None)
verifie("trou sans repli : version vide explicite",
        resume(v), [(1815, "anr"), (1828, "vide"), (1871, "anr")])

# ---------------------------------------------------------------------------
print("\n§ 4. Les cas dégénérés")
# ---------------------------------------------------------------------------
verifie("aucun segment ANR (fraction, ou atome qu'ANR ignore)",
        resume(E.construit_versions([], (geo(9), pt(9)))), [(1815, "repli")])
verifie("ni ANR ni atom_geom", resume(E.construit_versions([], None)),
        [(1815, "vide")])
verifie("segment entièrement hors fenêtre",
        resume(E.construit_versions([(1700, 1800, geo(1), pt(1))], (geo(9), pt(9)))),
        [(1815, "repli")])
verifie("segment vide (fin <= début)",
        resume(E.construit_versions([(1900, 1900, geo(1), pt(1))], (geo(9), pt(9)))),
        [(1815, "repli")])

# ANR s'arrête avant la fin de la fenêtre : le repli reprend la main.
verifie("ANR s'arrête en 1943",
        resume(E.construit_versions([(1790, 1943, geo(1), pt(1))], (geo(9), pt(9)))),
        [(1815, "anr"), (1943, "repli")])

# ---------------------------------------------------------------------------
print("\n§ 5. Dédoublonnage : la leçon de R2, transposée")
# ---------------------------------------------------------------------------
# Trois `Poly_ID` d'ANR portent DEUX FOIS la même géométrie sur deux fenêtres
# successives : la commune a été éditée à une date où sa forme n'a pas bougé.
# Deux versions de même empreinte ne sont qu'une, et les garder ferait croire à
# un changement de forme là où il n'y en a pas.
v = E.construit_versions(
    [(1790, 1876, geo(1), pt(1)), (1876, 2020, geo(1), pt(1))], (geo(9), pt(9)))
verifie("même forme sur deux fenêtres successives", resume(v), [(1815, "anr")])

# Mais un repli et une version ANR de même forme restent DEUX versions : `r`
# n'est pas une décoration, il dit si la date est attestée ou empruntée.
v = E.construit_versions([(1880, 2020, geo(9), pt(9))], (geo(9), pt(9)))
verifie("repli et ANR de même forme restent distincts",
        resume(v), [(1815, "repli"), (1880, "anr")])

# ---------------------------------------------------------------------------
print("\n§ 6. `annee_de_borne` — la convention du 1er décembre")
# ---------------------------------------------------------------------------
import datetime as dt                                          # noqa: E402
verifie("1er janvier vaut pour l'année même",
        E.annee_de_borne(dt.date(1876, 1, 1)), 1876)
verifie("une borne de février déplace l'année même",
        E.annee_de_borne(dt.date(1888, 2, 3)), 1888)
verifie("une borne du 1er décembre vaut encore pour l'année même",
        E.annee_de_borne(dt.date(1888, 12, 1)), 1888)
verifie("une borne du 12 décembre ne vaut qu'à l'année suivante",
        E.annee_de_borne(dt.date(1888, 12, 12)), 1889)

# ---------------------------------------------------------------------------
print("\n§ 7. Signature : la forme entre dans la clé, ou n'y entre pas")
# ---------------------------------------------------------------------------
avec = E.sql_signature(True)
sans = E.sql_signature(False)
verifie("avec ANR, la signature joint atom_geom_anr",
        "atom_geom_anr" in avec and "poly_id" in avec, True)
verifie("sans ANR, elle ne la joint pas",
        "atom_geom_anr" in sans, False)
verifie("aucune accolade de gabarit ne survit",
        ("{" in avec.replace("{", "", 0)) and False or
        ("{" not in avec and "{" not in sans), True)

u_anr, c_anr = E.sql_par_date(True)
u_old, c_old = E.sql_par_date(False)
verifie("les unités datées coalescent ANR puis atom_geom",
        "coalesce(ga.geom, ag.geom)" in u_anr, True)
verifie("le contour daté aussi — MÊME SOURCE que les communes",
        "coalesce(ga.geom, ag.geom)" in c_anr, True)
verifie("sans ANR, on retombe sur ag.geom seul",
        "coalesce(ga.geom" not in u_old and "ag.geom" in u_old, True)
verifie("aucune accolade de gabarit ne survit (unités)",
        "{" not in u_anr and "{" not in u_old, True)

# La coïncidence des limites est une propriété du TEXTE des requêtes : commune
# et contour doivent appliquer la même expression de snap à la même source. Le
# banc ne peut pas la vérifier sur des polygones, mais il peut la vérifier là.
verifie("communes et contours partagent l'expression de snap",
        E.geom_snap("coalesce(ga.geom, ag.geom)") in c_anr, True)

# ---------------------------------------------------------------------------
print()
if ECHECS:
    print(f"{len(ECHECS)} ÉCHEC(S) : " + ", ".join(ECHECS))
    sys.exit(1)
print("banc passé — les fonctions pures d'export_web.py tiennent.")
print("Rappel : ce banc ne dit RIEN des contours dissous ni du coût des "
      "requêtes. Ces deux-là ne se contrôlent qu'en base, après export.")
