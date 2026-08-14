#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
verif_annexe_vii.py — l'annexe VII rend-elle compte de l'écart 1940→1999 ?

    python3 cantons/verif_annexe_vii.py

Le contrôle
-----------
Pour chaque département, la base donne un nombre de cantons en 1940 et un autre
en 1999. L'annexe VII doit expliquer l'écart : autant de créations, moins autant
de suppressions, sur l'intervalle.

    cantons_1999 - cantons_1940  ==  créations - disparitions

Un désaccord signale l'un de trois problèmes, et le script ne prétend pas les
distinguer :

1. une page mal lue ou mal transcrite ;
2. une ligne que le parseur compte mal — le texte est en français libre ;
3. un mouvement que l'annexe VII n'enregistre pas.

C'est un **détecteur de zones à relire**, pas un juge. Les départements sont
classés par écart décroissant : les premiers sont ceux à rouvrir.

Comment on compte
-----------------
La règle vient de l'auteur (p. 787) :

  « L'indication "dédoublement" signifie que le canton dédoublé a disparu dans
    l'opération. Au contraire, l'expression "division" indique que le canton
    amputé subsiste, sauf indication contraire. »

Donc, pour chaque ligne `creation` :
  - on compte les cantons nommés après « Cr. » — en développant les plages
    « X-1 à X-12 », y compris en chiffres romains ;
  - on retranche 1 par canton dédoublé ;
  - on retranche les cantons suivis de « qui disparaît / disparaissent ».

Les lignes `suppression` retranchent 1.

Ce que le parseur rate sûrement
-------------------------------
Les formes mixtes du type « division A, qui demeure, et B, qui disparaît » :
il compte les disparitions globalement, sans les apparier à chaque canton. Sur
ces lignes il surestime ou sous-estime d'une unité. C'est assumé — le but est
de trier, pas de mesurer.
"""

import csv
import os
import re
import sys
import unicodedata
from pathlib import Path

import psycopg2

RACINE = Path(__file__).resolve().parent.parent
SRC = RACINE / "cantons" / "annexe_vii.csv"
DEBUT, FIN = "1941-01-01", "1999-01-01"

DSN_CANDIDATS = [
    "dbname=histgis host=/var/run/postgresql",
    "dbname=histgis",
    "dbname=histgis host=localhost",
]

ROMAINS = {"I": 1, "II": 2, "III": 3, "IV": 4, "V": 5, "VI": 6, "VII": 7,
           "VIII": 8, "IX": 9, "X": 10, "XI": 11, "XII": 12, "XIII": 13,
           "XIV": 14, "XV": 15}

SQL = """
WITH etat AS (
  SELECT d::date AS d, left(a.insee_geofla, 2) AS dep, m.unit_id
  FROM   (VALUES ('1940-06-01'), ('1999-06-01')) AS t(d)
  JOIN   membership m ON m.niveau = 'canton' AND m.periode @> d::date
  JOIN   atom a ON a.atom_id = m.atom_id
  WHERE  a.insee_geofla IS NOT NULL
  GROUP  BY 1, 2, 3
)
SELECT dep,
       count(DISTINCT unit_id) FILTER (WHERE d = '1940-06-01') AS n1940,
       count(DISTINCT unit_id) FILTER (WHERE d = '1999-06-01') AS n1999
FROM   etat GROUP BY dep ORDER BY dep
"""


def connexion():
    if os.environ.get("HISTGIS_DSN"):
        return psycopg2.connect(os.environ["HISTGIS_DSN"])
    for dsn in DSN_CANDIDATS:
        try:
            return psycopg2.connect(dsn)
        except psycopg2.OperationalError:
            pass
    raise SystemExit("Connexion impossible. Définir HISTGIS_DSN.")


def nombre(jeton):
    """« 12 » -> 12 ; « XII » -> 12 ; sinon None."""
    j = jeton.strip(" .,;")
    if j.isdigit():
        return int(j)
    return ROMAINS.get(j.upper())


def compte_crees(texte):
    """Combien de cantons cette ligne crée-t-elle ?

    Une même entrée de l'annexe peut porter plusieurs clauses `Cr.` séparées
    par des points-virgules — « Cr. A (division X) ; Cr. B (division Y) ». Ne
    lire que la première sous-compte lourdement : l'Indre-et-Loire y perdait
    sept cantons. On traite donc chaque clause séparément.
    """
    # « Cr. VIIIe Arrondissement de Lyon » est un arrondissement municipal,
    # pas un canton. Ces lignes ne créent aucune unité cantonale.
    if re.search(r"Arrondissement\s+de\s+Lyon", texte, flags=re.I):
        return 0
    return sum(_crees_clause(c) for c in texte.split(";"))


def _crees_clause(texte):
    """Compte les cantons d'une clause `Cr. …`.

    On découpe D'ABORD en fragments — virgules et « et » —, puis on développe
    les plages À L'INTÉRIEUR de chaque fragment. L'ordre inverse échouait sur
    « La Rochelle-1 à La Rochelle-4 », où le second membre répète un nom en
    plusieurs mots : la plage n'était pas reconnue et le fragment comptait pour
    un seul canton au lieu de quatre.
    """
    avant = texte.split("(")[0]
    avant = re.sub(r"^\s*Cr\.?\s*", "", avant, flags=re.I)

    total = 0
    for bout in re.split(r",|\bet\b", avant):
        bout = bout.strip(" .;")
        if len(bout) < 2 or bout.lower().startswith(("division", "dédoublement")):
            continue
        # « X-1 à X-12 », « X-1 à 12 », « Rennes-I à Rennes-X »
        m = re.search(r"([\dIVXL]+)\s+à\s+\D*?([\dIVXL]+)\s*$", bout)
        if m:
            a, b = nombre(m.group(1)), nombre(m.group(2))
            if a is not None and b is not None and b >= a:
                total += b - a + 1
                continue
        total += 1
    return total


def compte_disparus(texte):
    """Combien de cantons disparaissent dans l'opération ?"""
    n = 0
    # « dédoublement X » : X disparaît (convention de l'auteur)
    for m in re.finditer(r"dédoublement\s+([^)]*)", texte, flags=re.I):
        n += len([b for b in re.split(r",|\bet\b", m.group(1)) if b.strip(" .;")])
    # « (suppression X à Y) » : forme employée par le Loiret en 1982, où les
    # cantons remplacés sont annoncés par le mot « suppression » et non par
    # « qui disparaît ». Quatre cantons manquaient au décompte.
    for m in re.finditer(r"suppression\s+([^)]*)", texte, flags=re.I):
        bout = m.group(1).strip(" .;")
        p = re.search(r"([\dIVXL]+)\s+à\s+\D*?([\dIVXL]+)\s*$", bout)
        if p:
            a, b = nombre(p.group(1)), nombre(p.group(2))
            if a is not None and b is not None and b >= a:
                n += b - a + 1
                continue
        n += len([x for x in re.split(r",|\bet\b", bout) if x.strip(" .;")])

    # « qui disparaît » / « qui disparaissent » : les cantons cités avant.
    #
    # Forme mixte fréquente : « division A, qui demeure, et B, qui disparaît ».
    # Seul B disparaît. On ne garde donc que ce qui suit la dernière mention
    # « qui demeure », le cas échéant — sans quoi A serait compté à tort.
    for m in re.finditer(r"division\s+([^)]*?),?\s*qui\s+dispara", texte, flags=re.I):
        capture = m.group(1)
        if re.search(r"qui\s+demeur", capture, flags=re.I):
            capture = re.split(r"qui\s+demeure(?:nt)?", capture, flags=re.I)[-1]
        bouts = [b.strip(" .;,") for b in re.split(r",|\bet\b", capture)]
        bouts = [b for b in bouts if b and "demeur" not in b.lower()]
        n += max(1, len(bouts))
    return n


def main():
    lignes = [l for l in csv.DictReader(SRC.open(encoding="utf-8"))
              if DEBUT <= l["date_iso"] < FIN]

    par_dep = {}
    for l in lignes:
        d = par_dep.setdefault(l["dep"], dict(cr=0, supp=0, n=0, detail=[]))
        d["n"] += 1
        if l["type"] == "creation":
            c, s = compte_crees(l["texte"]), compte_disparus(l["texte"])
            d["cr"] += c
            d["supp"] += s
            d["detail"].append((l["date_iso"], f"+{c} -{s}", l["texte"][:90]))
        elif l["type"] == "suppression":
            d["supp"] += 1
            d["detail"].append((l["date_iso"], "-1", l["texte"][:90]))

    with connexion() as cx, cx.cursor() as cur:
        cur.execute("SET search_path TO histgis, public")
        cur.execute(SQL)
        base = {dep: (n40, n99) for dep, n40, n99 in cur.fetchall()}

    res = []
    for dep, (n40, n99) in sorted(base.items()):
        a = par_dep.get(dep, dict(cr=0, supp=0, n=0, detail=[]))
        attendu, constate = n99 - n40, a["cr"] - a["supp"]
        res.append((abs(attendu - constate), dep, n40, n99, attendu,
                    a["cr"], a["supp"], constate, attendu - constate, a))

    # Départements où le test ne peut pas s'appliquer, et pourquoi.
    INAPPLICABLE = {
        '75': "Paris : arrondissements, pas de cantons dans la base",
        '92': "créé en 1964 ; ses cantons de 1940 sont ceux de la Seine",
        '93': "créé en 1964 ; idem",
        '94': "créé en 1964 ; idem",
        '91': "créé en 1964 ; ses cantons de 1940 sont ceux de Seine-et-Oise",
        '95': "créé en 1964 ; idem",
        '78': "Yvelines : héritier partiel de la Seine-et-Oise démembrée",
        '2A': "Corse recodée 20 -> 2A/2B en 1976 ; l'annexe classe sous 20",
        '2B': "idem",
        '13': "Marseille repliée en pseudo-canton par 25_pseudo_canton.sql",
        '69': "Lyon repliée en pseudo-canton par 25_pseudo_canton.sql",
    }

    res.sort(reverse=True)
    print("Départements où le contrôle ne s'applique pas :")
    for d, raison in sorted(INAPPLICABLE.items()):
        print(f"  {d} — {raison}")
    print()
    res = [r for r in res if r[1] not in INAPPLICABLE]

    print(f"{'dep':4s} {'1940':>5s} {'1999':>5s} {'écart':>6s} "
          f"{'créés':>6s} {'supp':>5s} {'net':>5s} {'reste':>6s}")
    print("-" * 52)
    for _, dep, n40, n99, att, cr, sp, cst, diff, _a in res:
        marque = "  <<<" if diff else ""
        print(f"{dep:4s} {n40:5d} {n99:5d} {att:6d} {cr:6d} {sp:5d} {cst:5d} "
              f"{diff:6d}{marque}")

    mal = [r for r in res if r[0] != 0]
    print(f"\n{len(mal)} département(s) en désaccord sur {len(res)}")
    print("« reste » = écart de la base moins écart de l'annexe.")
    print("  positif : la base a plus de cantons que l'annexe n'en explique")
    print("  négatif : l'annexe en crée plus que la base n'en montre")

    if mal and "--noms" in sys.argv:
        print("\n=== cantons de 1999 absents en 1940, et ce que l'annexe en dit ===")
        print("Un canton NON CITÉ est un mouvement que l'annexe VII ignore,")
        print("ou une ligne omise à la transcription. C'est là qu'il faut regarder.\n")
        with connexion() as cx, cx.cursor() as cur:
            cur.execute("SET search_path TO histgis, public")
            cur.execute("""
                WITH etat AS (
                  SELECT d::date AS d, left(a.insee_geofla,2) AS dep,
                         m.unit_id, coalesce(uv.nom, u.nom) AS nom
                  FROM   (VALUES ('1940-06-01'),('1999-06-01')) AS t(d)
                  JOIN   membership m ON m.niveau='canton' AND m.periode @> d::date
                  JOIN   atom a ON a.atom_id = m.atom_id
                  JOIN   unit u ON u.unit_id = m.unit_id
                  LEFT   JOIN unit_version uv ON uv.unit_id=u.unit_id
                                             AND uv.periode @> d::date
                  WHERE  a.insee_geofla IS NOT NULL
                  GROUP  BY 1,2,3,4
                )
                SELECT dep, unit_id, max(nom)
                FROM   etat GROUP BY dep, unit_id
                HAVING count(*) FILTER (WHERE d='1940-06-01') = 0
                ORDER  BY dep, unit_id
            """)
            neufs = {}
            for dep, uid, nom in cur.fetchall():
                neufs.setdefault(dep, []).append((uid, nom or ""))

        def cle(s):
            """Clé comparable entre les deux notations.

            La base écrit « Lens-Nord-Est », « Toulouse 5e Canton »,
            « Nœux-les-Mines » ; l'annexe écrit « Lens-N.E. », « Toulouse-5 »,
            « Noeux-les-Mines ». Sans réduction commune, presque tous les
            cantons paraissent absents de l'annexe alors qu'ils y sont.

            On réduit donc les points cardinaux à leur initiale — ouest AVANT
            est, sinon « ouest » se ferait manger — et on supprime la mention
            « Ne Canton ».
            """
            s = (s or "").lower().replace("œ", "oe").replace("æ", "ae")
            s = unicodedata.normalize("NFD", s)
            s = "".join(c for c in s if unicodedata.category(c) != "Mn")
            s = "".join(c for c in s if c.isalnum())
            for avant, apres in (("ecanton", ""), ("canton", ""),
                                 ("sainte", "ste"), ("saint", "st"),
                                 ("ouest", "o"), ("nord", "n"),
                                 ("sud", "s"), ("est", "e"),
                                 ("centre", "c"), ("campagne", "camp"),
                                 ("ville", "vil")):
                s = s.replace(avant, apres)
            return s

        def corpus_dep(dep):
            """Le texte de l'annexe, plages numériques développées.

            « Cr. Toulouse-1 à Toulouse-15 » ne contient pas la chaîne
            « toulouse5 » : sans développement, cinq cantons toulousains
            paraissent absents alors qu'ils sont créés par cette ligne même.
            """
            txt = " ".join(l["texte"] for l in lignes if l["dep"] == dep)
            for m in re.finditer(r"([\w'’.\- ]+?)-?(\d+)\s+à\s+(?:[\w'’.\- ]*?-?)(\d+)",
                                 txt):
                base_nom, a, b = m.group(1).strip(), int(m.group(2)), int(m.group(3))
                if 0 < b - a < 40:
                    txt += " " + " ".join(f"{base_nom}-{i}" for i in range(a, b + 1))
            return cle(txt)

        for _, dep, *_r, a in mal[:15]:
            corpus = corpus_dep(dep)
            inconnus = [(u, n) for u, n in neufs.get(dep, [])
                        if cle(n)[:9] and cle(n)[:9] not in corpus]
            print(f"--- {dep} : {len(neufs.get(dep, []))} cantons neufs, "
                  f"{len(inconnus)} non cités par l'annexe")
            for u, n in inconnus:
                print(f"      {u}  {n}")

    if mal and "-v" in sys.argv:
        print("\n=== détail des départements en désaccord ===")
        for _, dep, *_r, a in mal[:12]:
            print(f"\n--- {dep} ---")
            for d, delta, txt in a["detail"]:
                print(f"  {d} {delta:>6s}  {txt}")


if __name__ == "__main__":
    main()
