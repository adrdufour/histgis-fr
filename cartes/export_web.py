#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
export_web.py — exporte la base `histgis` vers les fichiers que consomme
`cartes/web/index.html` (curseur d'années 1815-2012 + sélecteur de département).

    python3 cartes/export_web.py                  # tous les départements
    python3 cartes/export_web.py 01 13 69         # une sélection
    python3 cartes/export_web.py --grille 50      # quantification plus grossière

Sortie : `cartes/web/donnees/`, puis
    python3 cartes/web/servir.py
et la page s'ouvre. Un serveur est nécessaire : `fetch()` sur `file://` est
refusé par les navigateurs.

Ce que le script exporte, et pourquoi c'est découpé ainsi
--------------------------------------------------------
La géométrie d'un atome ne change jamais — `atom_geom` est posée une fois pour
toutes. Ce qui change d'une année à l'autre, c'est le *rattachement*. D'où :

  donnees/dep/NN/communes.json   géométrie des atomes, écrite une seule fois
  donnees/dep/NN/c_<sig>.json    une configuration cantonale : contours dissous
                                 + table atome → canton
  donnees/dep/NN/x_<sig>.json    idem pour les circonscriptions
  donnees/dep/NN/index.json      année → signature de configuration
  donnees/index.json             départements, noms d'époque, années servies

Une « configuration » est un état distinct de la composition. Entre 1870 et
1940 un département en compte quelques-unes, pas soixante-et-onze : réexporter
la même carte 71 fois pèserait cent fois plus pour la même information. La
signature est le md5 de la composition (atome > unité > nom), ce qui garantit
que deux années au contenu identique partagent un fichier, et que deux années
qui diffèrent d'un seul rattachement en ont deux.

Les années sans source
----------------------
Le script n'invente rien. Une année sans `membership` sort avec la signature
vide : la page affichera le bandeau « aucune source », et un contour
départemental de référence emprunté à l'année datée la plus proche — étiqueté
comme tel. C'est le parti pris du projet : l'absence de la ligne est le
résultat (`ETAT.md`, « le trou se voit dans les données »).

La quantification, et pourquoi ce n'est pas une simplification
--------------------------------------------------------------
Les coordonnées sont accrochées à une grille métrique en Lambert-93 avant
reprojection (`ST_SnapToGrid`, 25 m par défaut). Ce n'est pas
`ST_SimplifyPreserveTopology` : deux communes voisines qui partageaient un
sommet le partagent encore après accrochage, alors qu'une simplification
appliquée polygone par polygone les écarte et ouvre des lisières. Les contours
dissous subissent exactement les mêmes opérations dans le même ordre, donc les
limites cantonales coïncident avec les limites communales au pixel près.

Ce que les cartes ne montreront pas fidèlement
----------------------------------------------
Les communes partagées entre plusieurs cantons — Marseille, Lyon, Paris,
Bourg-en-Bresse — portent en base le polygone de la commune entière
(`atom_geom.partagee`). Leurs cantons se recouvrent donc exactement. Le drapeau
est exporté ; la page les hachure et les compte en pied de carte plutôt que de
laisser croire à un découpage qui n'existe pas.

Dépendances : psycopg2.
    pip install psycopg2-binary --break-system-packages
"""

import argparse
import hashlib
import json
import os
import sys
import time
from pathlib import Path

import psycopg2

# La libpq livrée par conda cherche la socket Unix dans /tmp, alors que les
# paquets Debian et Ubuntu la posent dans /var/run/postgresql. On essaie les
# emplacements dans l'ordre, TCP en dernier recours.
DSN_CANDIDATS = [
    "dbname=histgis host=/var/run/postgresql",
    "dbname=histgis",
    "dbname=histgis host=localhost",
]

RACINE = Path(__file__).resolve().parent
SORTIE = RACINE / "web" / "donnees"

AN_MIN, AN_MAX = 1815, 2012
MOIS_JOUR = (6, 1)          # date de référence dans l'année : 1er juin

# ---------------------------------------------------------------------------
# Noms de départements, par période. Un code ne suffit pas : `78` est
# Seine-et-Oise jusqu'en 1968 puis Yvelines, `75` est la Seine puis Paris, et
# `20` est la Corse jusqu'à sa partition. Afficher « Yvelines » sur une carte
# de 1885 serait un anachronisme silencieux — le genre que la page ne peut pas
# signaler elle-même.
# ---------------------------------------------------------------------------
NOMS_DEP = {
    "01": "Ain", "02": "Aisne", "03": "Allier", "04": [(AN_MIN, 1969, "Basses-Alpes"),
    (1970, AN_MAX, "Alpes-de-Haute-Provence")], "05": "Hautes-Alpes",
    "06": "Alpes-Maritimes", "07": [(AN_MIN, 1791, "Ardèche"), (1792, AN_MAX, "Ardèche")],
    "08": "Ardennes", "09": "Ariège", "10": "Aube", "11": "Aude", "12": "Aveyron",
    "13": "Bouches-du-Rhône", "14": "Calvados", "15": "Cantal", "16": "Charente",
    "17": [(AN_MIN, 1940, "Charente-Inférieure"), (1941, AN_MAX, "Charente-Maritime")],
    "18": "Cher", "19": "Corrèze", "20": "Corse", "2A": "Corse-du-Sud",
    "2B": "Haute-Corse", "21": "Côte-d'Or",
    "22": [(AN_MIN, 1989, "Côtes-du-Nord"), (1990, AN_MAX, "Côtes-d'Armor")],
    "23": "Creuse", "24": "Dordogne", "25": "Doubs", "26": "Drôme", "27": "Eure",
    "28": "Eure-et-Loir", "29": [(AN_MIN, 1989, "Finistère"), (1990, AN_MAX, "Finistère")],
    "30": "Gard", "31": "Haute-Garonne", "32": "Gers", "33": "Gironde",
    "34": "Hérault", "35": "Ille-et-Vilaine", "36": "Indre", "37": "Indre-et-Loire",
    "38": "Isère", "39": "Jura", "40": [(AN_MIN, 1956, "Landes"), (1957, AN_MAX, "Landes")],
    "41": "Loir-et-Cher", "42": "Loire", "43": "Haute-Loire",
    "44": [(AN_MIN, 1956, "Loire-Inférieure"), (1957, AN_MAX, "Loire-Atlantique")],
    "45": "Loiret", "46": "Lot", "47": "Lot-et-Garonne", "48": "Lozère",
    "49": [(AN_MIN, 1955, "Maine-et-Loire"), (1956, AN_MAX, "Maine-et-Loire")],
    "50": "Manche", "51": "Marne", "52": "Haute-Marne", "53": "Mayenne",
    "54": "Meurthe-et-Moselle", "55": "Meuse", "56": "Morbihan", "57": "Moselle",
    "58": "Nièvre", "59": "Nord", "60": "Oise", "61": "Orne",
    "62": "Pas-de-Calais", "63": "Puy-de-Dôme", "64": [(AN_MIN, 1968, "Basses-Pyrénées"),
    (1969, AN_MAX, "Pyrénées-Atlantiques")], "65": "Hautes-Pyrénées",
    "66": "Pyrénées-Orientales", "67": "Bas-Rhin", "68": "Haut-Rhin", "69": "Rhône",
    "70": "Haute-Saône", "71": "Saône-et-Loire", "72": "Sarthe", "73": "Savoie",
    "74": "Haute-Savoie", "75": [(AN_MIN, 1967, "Seine"), (1968, AN_MAX, "Paris")],
    "76": [(AN_MIN, 1954, "Seine-Inférieure"), (1955, AN_MAX, "Seine-Maritime")],
    "77": "Seine-et-Marne",
    "78": [(AN_MIN, 1967, "Seine-et-Oise"), (1968, AN_MAX, "Yvelines")],
    "79": "Deux-Sèvres", "80": "Somme", "81": "Tarn", "82": "Tarn-et-Garonne",
    "83": "Var", "84": "Vaucluse", "85": "Vendée", "86": "Vienne",
    "87": "Haute-Vienne", "88": "Vosges", "89": "Yonne",
    "90": "Territoire de Belfort", "91": "Essonne", "92": "Hauts-de-Seine",
    "93": "Seine-Saint-Denis", "94": "Val-de-Marne", "95": "Val-d'Oise",
    # `99` n'est pas un code d'usage : c'est la Meurthe d'avant 1871, que
    # TRF-GIS code ainsi faute de code INSEE — le département a disparu au
    # partage. Documenté dans METHODE.md, § « Curiosités documentées ».
    "99": "Meurthe (avant le partage de 1871)",
}


# ---------------------------------------------------------------------------
# Périodes où un département n'est pas français, n'existe pas encore, ou a
# cessé d'exister. Sans cette table, un trou de couverture et une absence de
# territoire se ressemblent : la page dirait « aucune source » pour la Moselle
# en 1890, alors que la bonne réponse est qu'il n'y a pas de Moselle française
# en 1890. Les bornes du curseur, elles, sont déduites des données ; cette table
# ne sert qu'à motiver les trous, jamais à en fabriquer.
#
# Chaque entrée est une affirmation historique datée, à contredire si elle est
# fausse — pas une commodité d'affichage.
# ---------------------------------------------------------------------------
ABSENCES = {
    "57": [(1871, 1918, "annexée à l'Empire allemand — traité de Francfort "
                        "(10 mai 1871) à l'armistice du 11 novembre 1918")],
    "67": [(1871, 1918, "annexé à l'Empire allemand — traité de Francfort "
                        "(10 mai 1871) à l'armistice du 11 novembre 1918")],
    "68": [(1871, 1918, "annexé à l'Empire allemand — traité de Francfort "
                        "(10 mai 1871) à l'armistice du 11 novembre 1918. "
                        "Le Territoire de Belfort, resté français, en est "
                        "détaché")],
}

# Motifs de début et de fin d'existence, affichés en bout de curseur.
BORNES_MOTIF = {
    "99": (None, "la Meurthe disparaît au partage de 1871 : l'essentiel forme "
                 "la Meurthe-et-Moselle, le reste est annexé avec la Moselle"),
    "20": (None, "la Corse est partagée en Corse-du-Sud et Haute-Corse "
                 "au 1er janvier 1976"),
    "2A": ("partition de la Corse, 1er janvier 1976", None),
    "2B": ("partition de la Corse, 1er janvier 1976", None),
    "91": ("créé par la réorganisation de la région parisienne — loi du "
           "10 juillet 1964, effet au 1er janvier 1968", None),
    "92": ("réorganisation de la région parisienne, 1er janvier 1968", None),
    "93": ("réorganisation de la région parisienne, 1er janvier 1968", None),
    "94": ("réorganisation de la région parisienne, 1er janvier 1968", None),
    "95": ("réorganisation de la région parisienne, 1er janvier 1968", None),
    "78": (None, "la Seine-et-Oise est démembrée au 1er janvier 1968 ; le code "
                 "78 désigne ensuite les Yvelines"),
}


def nom_dep(code, annee):
    """Nom porté par un département une année donnée."""
    v = NOMS_DEP.get(code)
    if v is None:
        return code
    if isinstance(v, str):
        return v
    for a, b, nom in v:
        if a <= annee <= b:
            return nom
    return v[-1][2]


# ---------------------------------------------------------------------------
# Connexion
# ---------------------------------------------------------------------------
def connecte(dsn_force=None):
    dernier = None
    for dsn in ([dsn_force] if dsn_force else DSN_CANDIDATS):
        try:
            cx = psycopg2.connect(dsn)
            cx.set_session(readonly=True, autocommit=True)
            with cx.cursor() as c:
                c.execute("SET search_path TO histgis, public")
            return cx
        except psycopg2.Error as e:
            dernier = e
    print("Connexion à la base `histgis` impossible.", file=sys.stderr)
    print(f"Dernière erreur : {dernier}", file=sys.stderr)
    sys.exit(1)


def date_ref(annee):
    return f"{annee:04d}-{MOIS_JOUR[0]:02d}-{MOIS_JOUR[1]:02d}"


# ---------------------------------------------------------------------------
# Repérage des configurations
#
# On ne teste pas les 198 années : la composition au 1er juin de l'année Y ne
# peut différer de celle de Y-1 que si une borne de `membership` (ou de
# `unit_version`) tombe dans l'intervalle. On calcule donc l'ensemble des
# années candidates à partir des bornes, et on n'échantillonne que celles-là.
# ---------------------------------------------------------------------------
SQL_BORNES = """
SELECT DISTINCT d FROM (
    SELECT m.valid_from AS d
    FROM   membership m JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
    WHERE  m.niveau = %(niveau)s AND u.dep = %(dep)s
    UNION ALL
    SELECT m.valid_to
    FROM   membership m JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
    WHERE  m.niveau = %(niveau)s AND u.dep = %(dep)s
    UNION ALL
    SELECT uv.valid_from
    FROM   unit_version uv JOIN unit u ON u.unit_id = uv.unit_id
    WHERE  u.niveau = %(niveau)s AND u.dep = %(dep)s
    UNION ALL
    SELECT uv.valid_to
    FROM   unit_version uv JOIN unit u ON u.unit_id = uv.unit_id
    WHERE  u.niveau = %(niveau)s AND u.dep = %(dep)s
) t
"""

SQL_SIGNATURE = """
SELECT md5(string_agg(m.atom_id || '>' || m.unit_id || '>' || coalesce(uv.nom, u.nom, ''),
                      ',' ORDER BY m.atom_id)) AS sig,
       count(*) AS n
FROM   membership m
JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
LEFT   JOIN unit_version uv ON uv.unit_id = u.unit_id AND uv.periode @> %(d)s::date
WHERE  m.niveau = %(niveau)s AND u.dep = %(dep)s AND m.periode @> %(d)s::date
"""


def annees_candidates(cur, dep, niveau):
    """Années où la composition peut changer, bornes du modèle à l'appui."""
    cur.execute(SQL_BORNES, {"dep": dep, "niveau": niveau})
    cand = {AN_MIN}
    for (d,) in cur.fetchall():
        if d is None:
            continue
        # une borne au 1888-02-03 déplace la composition observée au 1er juin
        # 1888 ; une borne au 1888-09-12 ne la déplace qu'au 1er juin 1889.
        y = d.year if (d.month, d.day) <= MOIS_JOUR else d.year + 1
        if AN_MIN <= y <= AN_MAX:
            cand.add(y)
    return sorted(cand)


def configurations(cur, dep, niveau):
    """année -> signature ('' si aucune source), et signature -> année de référence."""
    par_annee = {}
    sig_annee = {}
    courante = None
    cand = set(annees_candidates(cur, dep, niveau))
    for annee in range(AN_MIN, AN_MAX + 1):
        if annee in cand:
            cur.execute(SQL_SIGNATURE, {"dep": dep, "niveau": niveau, "d": date_ref(annee)})
            sig, n = cur.fetchone()
            courante = sig if (sig and n) else ""
            if courante and courante not in sig_annee:
                sig_annee[courante] = annee
        par_annee[annee] = courante or ""
    return par_annee, sig_annee


# ---------------------------------------------------------------------------
# Géométries
#
# `ST_SnapToGrid` avant reprojection, et le même ordre d'opérations pour les
# atomes et pour les unités dissoutes : c'est ce qui fait coïncider les limites
# cantonales avec les limites communales. `ST_MakeValid` derrière, parce que
# l'accrochage peut aplatir un anneau et produire une géométrie invalide.
# ---------------------------------------------------------------------------
GEOM_ATOME = "ST_MakeValid(ST_SnapToGrid(ag.geom, %(grille)s))"

# Le nom de la commune vient de `noms_geofla`, à défaut de `geofla_commune`.
# C'est un nom de 2011, donc potentiellement anachronique sur une planche de
# 1885 : la base ne tient pas de nom communal d'époque (`insee_mvt.libelle_av`
# le donnerait pour les disparues, c'est un chantier ouvert dans
# `RESTE_A_FAIRE.md`). La page l'affiche en le disant.
#
# Ces deux tables sont des annexes, pas le cœur du modèle : une base
# reconstruite sans elles doit exporter quand même, avec des communes sans nom
# plutôt qu'un export qui échoue. D'où la requête assemblée selon ce qui est
# présent, constaté une fois à la connexion.
def sql_communes(dico, geofla):
    champs, joints = [], []
    if dico:
        joints.append("LEFT JOIN noms_geofla n ON n.insee = a.insee_geofla")
        champs.append("n.nom")
    if geofla:
        joints.append("LEFT JOIN geofla_commune g ON g.insee_com = a.insee_geofla")
        champs.append("g.nom_comm")
    nom = f"coalesce({', '.join(champs)})" if champs else "NULL::text"
    return f"""
SELECT a.atom_id,
       a.insee_geofla,
       a.fraction,
       ag.partagee,
       {nom}                                                       AS nom,
       ST_AsGeoJSON(ST_Transform({GEOM_ATOME}, 4326), %(prec)s)     AS gj,
       ST_AsGeoJSON(ST_Transform(ST_PointOnSurface({GEOM_ATOME}), 4326),
                    %(prec)s)                                      AS pt
FROM   atom_geom ag
JOIN   atom a ON a.atom_id = ag.atom_id
{chr(10).join(joints)}
WHERE  ag.atom_id IN (
           SELECT DISTINCT m.atom_id
           FROM   membership m
           JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
           WHERE  u.dep = %(dep)s
       )
"""

SQL_UNITES = f"""
SELECT u.unit_id,
       coalesce(uv.nom, u.nom, u.unit_id)                AS nom,
       u.code,
       u.regime,
       u.provisoire,
       count(*)                                          AS n_atomes,
       count(*) FILTER (WHERE ag.atom_id IS NULL)        AS n_sans_geom,
       count(*) FILTER (WHERE ag.partagee)               AS n_partagees,
       array_agg(m.atom_id ORDER BY m.atom_id)           AS atomes,
       ST_AsGeoJSON(
           ST_Transform(
               ST_MakeValid(ST_UnaryUnion(ST_Collect({GEOM_ATOME}))), 4326),
           %(prec)s)                                     AS gj
FROM   membership m
JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
LEFT   JOIN unit_version uv ON uv.unit_id = u.unit_id AND uv.periode @> %(d)s::date
LEFT   JOIN atom_geom ag ON ag.atom_id = m.atom_id
WHERE  m.niveau = %(niveau)s AND u.dep = %(dep)s AND m.periode @> %(d)s::date
GROUP  BY u.unit_id, coalesce(uv.nom, u.nom, u.unit_id), u.code, u.regime, u.provisoire
"""

SQL_CONTOUR = f"""
SELECT ST_AsGeoJSON(
           ST_Transform(
               ST_MakeValid(ST_UnaryUnion(ST_Collect({GEOM_ATOME}))), 4326),
           %(prec)s)
FROM   membership m
JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
LEFT   JOIN atom_geom ag ON ag.atom_id = m.atom_id
WHERE  m.niveau = 'canton' AND u.dep = %(dep)s AND m.periode @> %(d)s::date
"""


def ecrit(chemin, obj):
    chemin.parent.mkdir(parents=True, exist_ok=True)
    with open(chemin, "w", encoding="utf-8") as f:
        json.dump(obj, f, ensure_ascii=False, separators=(",", ":"))
    return chemin.stat().st_size


def existe(cur, table):
    cur.execute("SELECT to_regclass(%s) IS NOT NULL", (f"histgis.{table}",))
    return cur.fetchone()[0]


def exporte_departement(cur, dep, grille, prec, sortie, sql_com):
    t0 = time.time()
    base = sortie / "dep" / dep
    params = {"dep": dep, "grille": grille, "prec": prec}

    cfg_canton, sig_canton = configurations(cur, dep, "canton")
    cfg_circo, sig_circo = configurations(cur, dep, "circo")

    if not sig_canton and not sig_circo:
        return None

    poids = 0

    # --- communes : géométrie statique, écrite une seule fois ---------------
    cur.execute(sql_com, params)
    communes = {}
    for atom_id, insee, fraction, partagee, nom, gj, pt in cur.fetchall():
        if not gj:
            continue
        p = json.loads(pt)["coordinates"] if pt else None
        communes[atom_id] = {
            "i": insee,
            "n": nom,
            "f": 1 if fraction else 0,
            "p": 1 if partagee else 0,
            "c": [round(p[0], 5), round(p[1], 5)] if p else None,
            "g": json.loads(gj),
        }
    poids += ecrit(base / "communes.json", {"dep": dep, "communes": communes})

    # --- une configuration par état distinct de la composition -------------
    def exporte_configs(sig_annee, niveau, prefixe):
        total = 0
        for sig, annee in sorted(sig_annee.items(), key=lambda kv: kv[1]):
            cur.execute(SQL_UNITES, dict(params, niveau=niveau, d=date_ref(annee)))
            unites, rattach = [], {}
            for (uid, nom, code, regime, provisoire, n_at, n_sg,
                 n_part, atomes, gj) in cur.fetchall():
                unites.append({
                    "id": uid, "nom": nom, "code": code, "regime": regime,
                    "prov": 1 if provisoire else 0,
                    "n": n_at, "sans_geom": n_sg, "partagees": n_part,
                    "g": json.loads(gj) if gj else None,
                })
                for a in atomes:
                    rattach[a] = uid
            total += ecrit(base / f"{prefixe}_{sig[:12]}.json", {
                "dep": dep, "niveau": niveau, "annee_ref": annee,
                "unites": unites, "rattachement": rattach,
            })
        return total

    poids += exporte_configs(sig_canton, "canton", "c")
    poids += exporte_configs(sig_circo, "circo", "x")

    # --- contours de référence, pour les années sans source ----------------
    # Ce ne sont pas des cartes : juste l'emprise du département, empruntée à
    # une année datée, que la page affiche en grisé et annonce comme empruntée.
    contours = {}
    for annee in sorted(set(sig_canton.values())):
        cur.execute(SQL_CONTOUR, dict(params, d=date_ref(annee)))
        r = cur.fetchone()
        if r and r[0]:
            contours[str(annee)] = json.loads(r[0])
    poids += ecrit(base / "contours.json", contours)

    # --- index du département ----------------------------------------------
    annees = {}
    for a in range(AN_MIN, AN_MAX + 1):
        c, x = cfg_canton[a], cfg_circo[a]
        if c or x:
            annees[str(a)] = {"c": c[:12] if c else "", "x": x[:12] if x else ""}
    # Bornes du curseur : premier et dernier millésime que la base sert pour ce
    # département. Déduites des données, jamais posées à la main — un
    # département dont la couverture s'arrête en 1940 doit le montrer.
    servies = sorted(int(a) for a in annees)
    poids += ecrit(base / "index.json", {
        "dep": dep,
        "annees": annees,
        "contours": sorted(int(y) for y in contours),
        "bornes": [servies[0], servies[-1]] if servies else None,
        "absences": [list(x) for x in ABSENCES.get(dep, [])],
        "motifs": list(BORNES_MOTIF.get(dep, (None, None))),
    })

    return {
        "dep": dep,
        "bornes": [servies[0], servies[-1]] if servies else None,
        "communes": len(communes),
        "cfg_canton": len(sig_canton),
        "cfg_circo": len(sig_circo),
        "annees": len(annees),
        "octets": poids,
        "secondes": round(time.time() - t0, 1),
    }


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("deps", nargs="*", help="codes de départements (défaut : tous)")
    ap.add_argument("--grille", type=float, default=25.0,
                    help="accrochage en mètres, Lambert-93 (défaut 25)")
    ap.add_argument("--precision", type=int, default=5,
                    help="décimales des coordonnées en degrés (défaut 5, ~1 m)")
    ap.add_argument("--sortie", type=Path, default=SORTIE)
    ap.add_argument("--dsn", default=None,
                    help="chaîne de connexion explicite (défaut : essais successifs)")
    args = ap.parse_args()

    cx = connecte(args.dsn)
    cur = cx.cursor()

    if args.deps:
        deps = [d.upper() for d in args.deps]
    else:
        cur.execute("SELECT DISTINCT dep FROM unit ORDER BY dep")
        deps = [r[0].strip() for r in cur.fetchall()]

    dico, geofla = existe(cur, "noms_geofla"), existe(cur, "geofla_commune")
    sql_com = sql_communes(dico, geofla)
    if not (dico or geofla):
        print("Attention : ni `noms_geofla` ni `geofla_commune` — les communes "
              "sortiront sans nom.")

    print(f"{len(deps)} département(s) à exporter, grille {args.grille} m.")
    args.sortie.mkdir(parents=True, exist_ok=True)

    rapport, total = [], 0
    for i, dep in enumerate(deps, 1):
        r = exporte_departement(cur, dep, args.grille, args.precision,
                                args.sortie, sql_com)
        if r is None:
            print(f"  [{i:>3}/{len(deps)}] {dep} — aucune unité, ignoré")
            continue
        rapport.append(r)
        total += r["octets"]
        print(f"  [{i:>3}/{len(deps)}] {dep} — {r['communes']:>4} communes, "
              f"{r['cfg_canton']:>3} config. cantonales, {r['cfg_circo']:>3} circo, "
              f"{r['annees']:>4} années servies, {r['octets']/1e6:>6.2f} Mo, "
              f"{r['secondes']:>5.1f} s")

    # --- index racine -------------------------------------------------------
    index = {"genere": time.strftime("%Y-%m-%d %H:%M"),
             "an_min": AN_MIN, "an_max": AN_MAX,
             "grille_m": args.grille,
             "departements": []}
    for r in rapport:
        index["departements"].append({
            "code": r["dep"],
            "nom": nom_dep(r["dep"], 1900),
            "noms": (NOMS_DEP.get(r["dep"]) if isinstance(NOMS_DEP.get(r["dep"]), list)
                     else None),
            "communes": r["communes"],
            "annees": r["annees"],
            "bornes": r["bornes"],
        })
    index["departements"].sort(key=lambda d: d["code"])
    ecrit(args.sortie / "index.json", index)

    print(f"\n{len(rapport)} départements écrits, {total/1e6:.1f} Mo au total.")
    print(f"Sortie : {args.sortie}")
    print("Servir la page :  python3 cartes/web/servir.py")
    cur.close()
    cx.close()


if __name__ == "__main__":
    main()
