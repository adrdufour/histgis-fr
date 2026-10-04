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
print("\n§ 8. OUTRE-MER — l'export de bout en bout, sur un faux curseur")
# ---------------------------------------------------------------------------
# Ce paragraphe ne ressemble pas aux sept précédents, et il faut dire pourquoi.
# Les autres éprouvent des fonctions PURES ; celui-ci fait tourner
# `exporte_departement_om()`, qui interroge une base et écrit sur le disque.
#
# Il le peut parce que la fonction ne parle à PostgreSQL qu'à travers un
# curseur, et qu'un curseur est une toute petite interface : `execute` et
# `fetchall`/`fetchone`. Un mannequin qui répond selon la requête reçue suffit à
# faire jouer tout le chemin — les signatures, le dédoublonnage par contenu,
# l'écriture des cinq fichiers, et la forme exacte du JSON que la page lit.
#
# CE QU'IL NE DIT PAS, et c'est la même limite que partout ici : il ne juge
# aucune géométrie. `ST_SnapToGrid` et `ST_UnaryUnion` ne sont pas appelés — le
# mannequin rend du GeoJSON tout fait. Il juge la TUYAUTERIE, c'est-à-dire
# l'endroit où ce chemin-là peut se tromper en silence : un atome perdu, une
# signature qui pointe dans le vide, un département escamoté.
#
# *Une fonction qu'on ne peut éprouver qu'avec la base est une fonction qu'on
# n'éprouve pas ; c'est le curseur, et non la base, qui est sa dépendance.*
import json as _json                                           # noqa: E402
import tempfile                                                # noqa: E402

CARRE = ('{"type":"MultiPolygon","coordinates":'
         '[[[[-61.5,16.2],[-61.4,16.2],[-61.4,16.3],[-61.5,16.3],[-61.5,16.2]]]]}')
POINT = '{"type":"Point","coordinates":[-61.45,16.25]}'


class FauxCurseur:
    """Répond aux six requêtes d'outre-mer, et à rien d'autre.

    `rattache` vaut False pour rejouer Mayotte : des communes, des cantons, et
    pas une ligne de `om_membership`.
    """

    def __init__(self, communes, rattache=True):
        self.communes = communes
        self.rattache = rattache
        self.reponse = []

    def execute(self, sql, params=None):
        p = params or {}
        if "FROM   om_atom a\nWHERE  a.dep" in sql:            # SQL_OM_ATOMES
            self.reponse = [(c, c, None, False, c.endswith("9"), f"Commune {c}",
                             False) for c in self.communes]
        elif "om_atom_geom g" in sql and "ST_PointOnSurface" in sql:
            self.reponse = [(c, CARRE, POINT) for c in self.communes]
        elif "SELECT DISTINCT d FROM" in sql:                  # SQL_OM_BORNES
            import datetime
            self.reponse = ([] if not self.rattache else
                            [(datetime.date(1946, 3, 19),),
                             (datetime.date(1986, 11, 24),),
                             (datetime.date(2013, 1, 1),)])
        elif sql.lstrip().startswith("SELECT md5"):            # SQL_OM_SIGNATURE
            # LA BORNE DE 1946 EST DANS LE MANNEQUIN, ET C'EST LE PREMIER JET
            # QUI L'AVAIT OUBLIÉE. Sans elle, ce faux curseur rendait une
            # composition pour 1815 — une date où `om_membership` est
            # évidemment vide, puisque `40` ne pose rien avant le 19 mars 1946.
            # Le banc a signalé un département servi depuis 1815, et il avait
            # raison de le signaler : ce que le mannequin décrivait n'était pas
            # la base. *Un mannequin plus généreux que la source ne valide rien ;
            # il fait passer pour un défaut du code ce qui est un défaut du
            # banc, et — c'est plus grave — l'inverse aussi.*
            if not self.rattache or p["d"] < "1946-12-01":
                self.reponse = [(None, 0)]
            else:
                # Deux compositions distinctes : une avant 1986, une après.
                jeton = "avant" if p["d"] < "1986-12-01" else "apres"
                self.reponse = [(f"sig-{p['niveau']}-{jeton}",
                                 len(self.communes))]
        elif "array_agg(m.atom_id" in sql:                     # SQL_OM_UNITES
            self.reponse = [(f"{p['dep']}01", "Canton d'essai", "01", None,
                             False, len(self.communes), 0, 1, 0,
                             len(self.communes), 0, list(self.communes), CARRE)]
        else:                                                  # SQL_OM_CONTOUR
            self.reponse = [(CARRE,)]

    def fetchall(self):
        return self.reponse

    def fetchone(self):
        return self.reponse[0] if self.reponse else None


def joue_om(dep, communes, rattache=True):
    d = Path(tempfile.mkdtemp())
    r = E.exporte_departement_om(FauxCurseur(communes, rattache), dep,
                                 25.0, 5, d)
    lu = {f.name: _json.loads(f.read_text(encoding="utf-8"))
          for f in (d / "dep" / dep).glob("*.json")}
    return r, lu


# --- le cas ordinaire : la Guadeloupe -------------------------------------
r, f = joue_om("971", ["97101", "97102", "97109"])
verifie("les trois communes sont écrites", r["communes"], 3)
verifie("communes.json porte les trois atomes",
        sorted(f["communes.json"]["communes"]), ["97101", "97102", "97109"])
verifie("une version par commune, et elle part de la départementalisation",
        [(v["a"], len(f["communes.json"]["communes"][c]["v"]))
         for c in ["97101"] for v in f["communes.json"]["communes"][c]["v"]],
        [(E.AN_DEBUT_DOM["971"], 1)])
# Et surtout PAS de `AN_MIN`. La version qui commencerait en 1815 ferait
# dessiner la Guadeloupe de 2015 sur une planche de la Restauration, sans
# qu'aucun message ne l'annonce : la forme serait là, plausible, et fausse de
# cent trente ans.
verifie("aucune version ne commence avant le département",
        min(v["a"] for c in f["communes.json"]["communes"].values()
            for v in c["v"]) >= 1946, True)

# `r: 1` sur TOUTES les communes. Ce n'est pas un défaut à corriger un jour :
# la trame d'outre-mer est un instantané GEOFLA 2015, et une carte qui ne dit
# pas qu'elle est plate laisse croire à une datation qu'elle n'a pas.
verifie("toutes les formes sont déclarées non datées (r = 1)",
        all(v["r"] == 1 for c in f["communes.json"]["communes"].values()
            for v in c["v"]), True)

# `multi` devient `p` : la commune est hachurée, et la page annonce déjà un
# tracé à faire sur la trame IRIS. C'est la SEULE information que l'export
# transporte sur les 27 multicantonales, et elle ne doit pas se perdre.
verifie("la multicantonale ressort drapeau `p` levé",
        f["communes.json"]["communes"]["97109"]["p"], 1)
verifie("les autres ne le sont pas",
        f["communes.json"]["communes"]["97101"]["p"], 0)
verifie("aucune commune ne porte de code Cassini",
        {c["s"] for c in f["communes.json"]["communes"].values()}, {None})

# L'index doit pointer sur des fichiers qui EXISTENT. C'est la faute que
# `nom_fichier()` guette côté métropole, et le chemin d'outre-mer la guette
# aussi — un index qui pointe dans le vide afficherait « aucune source » pour
# une année qui en a une, sans que rien ne le dise.
idx = f["index.json"]
noms = {p[:-5] for p in f if p.startswith(("c_", "x_"))}
pointes = {v[k] for v in idx["annees"].values() for k in ("c", "x") if v[k]}
verifie("tout ce que l'index désigne est écrit sur le disque",
        pointes - {n.split("_", 1)[1] for n in noms}, set())
verifie("l'index se déclare de l'espace outre-mer", idx["espace"], "outremer")
verifie("et de la trame GEOFLA 2015", idx["trame"], "geofla2015")
verifie("les bornes commencent à la départementalisation",
        idx["bornes"][0], 1946)
verifie("un contour de référence est écrit", len(f["contours.json"]), 1)

# --- le cas Mayotte : des communes, aucun rattachement --------------------
# C'est le paragraphe qui justifie que `exporte_departement_om` ne rende jamais
# `None`. La fonction métropolitaine rendrait ici « aucune unité, ignoré », et
# Mayotte disparaîtrait du sélecteur — le lecteur en conclurait que le projet
# l'ignore, alors que la base porte ses communes et ses cantons.
r, f = joue_om("976", ["97601", "97602"], rattache=False)
verifie("Mayotte est tout de même exportée", r["communes"], 2)
verifie("ses communes sont dessinées",
        sorted(f["communes.json"]["communes"]), ["97601", "97602"])
verifie("mais elle ne sert aucune année", f["index.json"]["annees"], {})
verifie("et ses bornes sont nulles, pas inventées",
        f["index.json"]["bornes"], None)
verifie("son contour de référence est rangé sous 2011, sa départementalisation",
        list(f["contours.json"]), ["2011"])
verifie("aucun fichier de configuration n'est écrit",
        [p for p in f if p.startswith(("c_", "x_"))], [])
# LA GARDE QUI EMPÊCHE L'ANACHRONISME. `bornes` est nul : sans `existence`, la
# page retomberait sur son curseur global, 1815-2012, et montrerait Mayotte au
# temps de la Restauration. Ce champ-là est la seule chose qui l'en empêche.
verifie("l'existence du département est déclarée, faute de bornes servies",
        f["index.json"]["existence"], [2011, E.AN_MAX])
verifie("et ses formes ne commencent pas avant",
        {v["a"] for c in f["communes.json"]["communes"].values()
         for v in c["v"]}, {2011})

# --- la grille, et ce qu'elle garantit ------------------------------------
# Même contrôle qu'au § 7, transposé : c'est la MÊME expression d'accrochage
# qui doit servir aux communes et au contour, sinon la limite cantonale
# dissoute ne longe plus la limite communale. Cela se lit dans le texte.
verifie("communes et contour d'outre-mer partagent l'expression de snap",
        E.sql_om_geom("g.geom") in E.SQL_OM_CONTOUR
        and E.sql_om_geom("g.geom") in E.SQL_OM_VERSION, True)
verifie("les unités dissoutes aussi",
        E.sql_om_geom("g.geom") in E.SQL_OM_UNITES, True)
verifie("l'accrochage est en degrés, pas en mètres",
        "%(pas)s" in E.SQL_OM_VERSION and "%(grille)s" not in E.SQL_OM_VERSION,
        True)
# Aucun `ST_Transform` : la géométrie est déjà en 4326, et l'écrire donnerait à
# croire qu'une conversion a lieu.
verifie("aucune reprojection sur le chemin d'outre-mer",
        any("ST_Transform" in q for q in
            (E.SQL_OM_VERSION, E.SQL_OM_UNITES, E.SQL_OM_CONTOUR)), False)

# ---------------------------------------------------------------------------
print()
if ECHECS:
    print(f"{len(ECHECS)} ÉCHEC(S) : " + ", ".join(ECHECS))
    sys.exit(1)
print("banc passé — les fonctions pures d'export_web.py tiennent.")
print("Rappel : ce banc ne dit RIEN des contours dissous ni du coût des "
      "requêtes. Ces deux-là ne se contrôlent qu'en base, après export.")
