#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
consolide_registre.py — le registre des mouvements cantonaux, tous départements

    python3 cantons/consolide_registre.py

Produit `cantons/mouvements_cantonaux.csv`, qui remplace la saisie manuelle.

Ce que fait le script
---------------------
Il croise deux sources qui ne se recouvrent pas :

* **la base** sait QUELS mouvements ont eu lieu, et avec quelles communes —
  c'est le différentiel 1940→1999 de `33_diff_cantonal.sql`, généralisé aux 95
  départements ;
* **l'annexe VII** sait QUAND, au décret près, mais ne nomme aucune commune et
  s'arrête en 1986.

L'appariement se fait sur le nom du canton d'arrivée. Chaque mouvement reçoit
alors sa date d'acte, ou le statut qui dit pourquoi il n'en a pas.

Les quatre statuts, et ce qu'ils veulent dire
---------------------------------------------
`acte`
    l'annexe nomme le canton créé : date au jour près, la meilleure qualité.

`cadre_change`
    le différentiel ne mesure là aucune histoire cantonale mais un changement
    de cadre : Corse scindée en 1976, Seine et Seine-et-Oise démembrées en
    1964, Marseille et Lyon repliées en pseudo-cantons. Les cantons y sont
    anciens et n'ont pas bougé — c'est le département qui a changé sous eux.
    Ces lignes sont sorties des taux, sans quoi elles les dilueraient.

`post_1986`
    le canton existe en 1999 mais l'annexe ne le nomme nulle part. Elle
    s'arrête au découpage de 1986 : ces cantons sont postérieurs. Une
    quarantaine en métropole, mesurés par `verif_annexe_vii.py`. Datables
    seulement par une source qui couvre 1986-1999.

`inconnue`
    transfert isolé d'une commune d'un canton ancien à un autre. L'annexe VII
    ne recense JAMAIS ce type de mouvement — c'est une limite de la source, pas
    une lacune de la transcription. Ces lignes resteront indatées sans les
    décrets.

`partage`
    la commune relève de plusieurs cantons à la même date — chef-lieu divisé,
    cas Marseille-Lyon. Ce n'est pas un mouvement mais un état ; daté comme le
    démembrement qui l'accompagne quand il y en a un.

Ce que le registre ne dira pas
------------------------------
L'ordre des mouvements à l'intérieur d'un même décret, et les créations suivies
de suppressions qui se compensent — Bourg-en-Bresse est divisée en 1973 puis
redivisée en 1982, et le différentiel 1940→1999 n'en montre que le résultat.
L'annexe VII porte cette chronologie ; `annexe_vii.csv` la conserve intacte et
reste la référence pour l'histoire, ce fichier-ci pour la géométrie.
"""

import csv
import os
import re
import sys
import unicodedata
from pathlib import Path

import psycopg2

RACINE = Path(__file__).resolve().parent.parent
ANNEXE = RACINE / "cantons" / "annexe_vii.csv"
SORTIE = RACINE / "cantons" / "mouvements_cantonaux.csv"

DSN_CANDIDATS = [
    "dbname=histgis host=/var/run/postgresql",
    "dbname=histgis",
    "dbname=histgis host=localhost",
]

CHAMPS = ["dep", "type", "date_debut", "date_fin", "date_retenue", "certitude",
          "canton_source", "cantons_resultants", "communes", "source", "remarque"]

SQL_ETAT = """
SELECT d::date AS d, a.insee_geofla AS insee, m.unit_id,
       coalesce(uv.nom, u.nom) AS nom
FROM   (VALUES ('1940-06-01'), ('1999-06-01')) AS t(d)
JOIN   membership m ON m.niveau = 'canton' AND m.periode @> d::date
JOIN   atom a ON a.atom_id = m.atom_id
JOIN   unit u ON u.unit_id = m.unit_id
LEFT   JOIN unit_version uv ON uv.unit_id = u.unit_id AND uv.periode @> d::date
WHERE  a.insee_geofla IS NOT NULL
GROUP  BY 1, 2, 3, 4
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


CARDINAUX = {"n": "n", "nord": "n", "s": "s", "sud": "s", "e": "e", "est": "e",
             "o": "o", "ouest": "o", "w": "o", "c": "c", "centre": "c"}


def _mots(nom):
    """Décompose un nom de canton en mots normalisés.

    Travailler sur les MOTS, jamais sur la chaîne aplatie. Une découpe par
    expression régulière sur « dignelesbainso » rend (« dignelesbain », « so ») :
    le `s` final de « Bains » est happé par le suffixe, et l'appariement avec
    « Digne-O. » échoue. Le mot est la seule unité qui ne mente pas.
    """
    s = (nom or "").lower().replace("œ", "oe").replace("æ", "ae")
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    s = re.sub(r"\b(\d+)\s*(?:er|eme|e)\b", r"\1", s)      # « 5e », « 1er » -> 5, 1
    s = s.replace("canton", "")
    out = []
    for p in re.split(r"[^a-z0-9]+", s):
        if not p:
            continue
        p = p.replace("sainte", "ste").replace("saint", "st")
        out.append(CARDINAUX.get(p, p))
    return out


def decompose(nom):
    """« Digne-les-Bains-Ouest » -> (« dignelesbains », « o »).

    Le suffixe est la suite des points cardinaux et des numéros qui terminent
    le nom ; la racine, tout ce qui précède. « Lens-Nord-Est » et « Lens-N.E. »
    donnent tous deux (« lens », « ne »).
    """
    m = _mots(nom)
    suff = []
    while m and (m[-1].isdigit() or m[-1] in ("n", "s", "e", "o", "c")):
        suff.insert(0, m.pop())
    return "".join(m), "".join(suff)


def cle(nom):
    racine, suffixe = decompose(nom)
    return racine + suffixe


# Filiations départementales : la base classe sous le code moderne, l'annexe
# sous celui d'alors. Chercher la date d'un canton de Haute-Corse dans la
# section « 2B » ne donne rien — l'annexe l'a rangé sous « 20 ». De même pour
# la petite couronne et l'Essonne, découpées dans la Seine et la Seine-et-Oise.
ANCETRES = {"2A": ["20"], "2B": ["20"],
            "92": ["75"], "93": ["75"], "94": ["75"],
            "91": ["78O"], "95": ["78O"], "78": ["78O"],
            "77": ["78O"]}


# Départements où le différentiel 1940→1999 ne mesure pas une histoire
# cantonale mais un changement de cadre. Le statut `post_1986` y mentirait :
# Belgodère et Borgo existaient bien avant 1940, ils ne « remontent » que
# parce que la Corse a été scindée en 1976 et la Seine démembrée en 1964. Le
# canton n'a pas bougé, c'est le département qui a changé sous lui.
#
# C'est la leçon de `35_atomes_hors_departement.sql` : 22 atomes déplacés
# devenaient 8 une fois les recodages retirés. Un état n'est pas un mouvement.
CADRE_CHANGE = {
    "2A": "Corse scindée en 1976 : cantons recodés 20 → 2A/2B",
    "2B": "Corse scindée en 1976 : cantons recodés 20 → 2A/2B",
    "91": "Seine-et-Oise démembrée en 1964",
    "95": "Seine-et-Oise démembrée en 1964",
    "92": "Seine démembrée en 1964",
    "93": "Seine démembrée en 1964",
    "94": "Seine démembrée en 1964",
    "13": "Marseille repliée en pseudo-cantons par 25_pseudo_canton.sql",
    "69": "Lyon replié en pseudo-cantons par 25_pseudo_canton.sql",
}


def apparie(nom, index_dep, decomp_dep):
    """Retrouve la date d'un canton dans l'index de l'annexe.

    Le nom d'un canton s'allonge avec le temps : « Digne-O. » créé en 1973 est
    « Digne-les-Bains-Ouest » en 1999, « Brive-S.E. » devient
    « Brive-la-Gaillarde-Sud-Est ». Une comparaison de chaînes entières les
    déclare inconnus et les range à tort parmi les cantons postérieurs à 1986.

    On compare donc racine et suffixe séparément : même point cardinal ou même
    numéro, et une racine préfixe de l'autre. Puis, en dernier recours, la
    simple inclusion — « caen5 » se retrouve dans
    « herouvillestclaircaen5 ».
    """
    k = cle(nom)
    if k in index_dep:
        return index_dep[k]
    rk, sk = decompose(nom)
    if len(rk) >= 4:
        for ra, sa, v in decomp_dep:
            if sk == sa and len(ra) >= 4 and (rk.startswith(ra) or ra.startswith(rk)):
                return v
    for autre, v in index_dep.items():
        if len(autre) >= 5 and autre in k:
            return v
    return None


def charge_annexe():
    """Index des créations de l'annexe : clé du canton créé -> (date, texte)."""
    index, decomp, brut = {}, {}, []
    for l in csv.DictReader(ANNEXE.open(encoding="utf-8")):
        brut.append(l)
        if l["type"] != "creation":
            continue
        avant = l["texte"].split("(")[0]
        avant = re.sub(r"^\s*Cr\.?\s*", "", avant, flags=re.I)
        noms = []
        for bout in re.split(r",|\bet\b|;", avant):
            bout = bout.strip(" .;")
            if len(bout) < 2:
                continue
            # « Toulouse-1 à Toulouse-15 » : développer la plage
            m = re.match(r"(.+?)-?(\d+)\s+à\s+(?:.*?-?)(\d+)\s*$", bout)
            if m and 0 < int(m.group(3)) - int(m.group(2)) < 40:
                noms += [f"{m.group(1)}-{i}"
                         for i in range(int(m.group(2)), int(m.group(3)) + 1)]
            else:
                noms.append(bout)
        for n in noms:
            val = (l["date_iso"], l["texte"])
            index.setdefault(l["dep"], {}).setdefault(cle(n), val)
            decomp.setdefault(l["dep"], []).append((*decompose(n), val))
    return index, decomp, brut


def main():
    index, decomp, brut = charge_annexe()
    corpus = {}
    for l in brut:
        corpus.setdefault(l["dep"], []).append(l["texte"])
    corpus = {d: cle(" ".join(t)) for d, t in corpus.items()}

    with connexion() as cx, cx.cursor() as cur:
        cur.execute("SET search_path TO histgis, public")
        cur.execute(SQL_ETAT)
        etat = cur.fetchall()

    c40, c99, noms = {}, {}, {}
    for d, insee, uid, nom in etat:
        (c40 if str(d) == "1940-06-01" else c99).setdefault(insee, set()).add(uid)
        noms[uid] = nom or uid

    neufs = {u for s in c99.values() for u in s} - {u for s in c40.values() for u in s}

    # (source, destination, partagée ?) -> communes concernées
    #
    # Le drapeau `partage` se calcule COMMUNE PAR COMMUNE, jamais sur le
    # groupe. Oyonnax le montre : quatre communes quittent le canton pour
    # Oyonnax-Sud — c'est un démembrement — tandis que la ville d'Oyonnax
    # relève des deux à la fois — c'est un partage. Tester la survivance du
    # canton source sur le lot entier faisait basculer les cinq en partage,
    # et effaçait un démembrement que `33_diff_cantonal.sql` voyait.
    mvt = {}
    for insee in set(c40) | set(c99):
        a, b = c40.get(insee, set()), c99.get(insee, set())
        if not a or not b:
            continue                       # fusion ou création de commune
        partagee = bool(a & b)             # garde-t-elle un canton d'origine ?
        for src in (a - b) or a:
            for dst in b - a:
                mvt.setdefault((insee[:2], src, dst, partagee), []).append(insee)

    lignes = []
    for (dep, src, dst, partagee), communes in sorted(mvt.items()):
        if partagee:
            typ, cert, d1, d2 = "partage", "borne_sup", "", ""
        elif dst in neufs:
            typ = "demembrement"
        else:
            typ, cert = "transfert", "inconnue"

        if typ == "demembrement" or typ == "partage":
            trouve = None
            for d_ in [dep] + ANCETRES.get(dep, []):
                trouve = apparie(noms[dst], index.get(d_, {}), decomp.get(d_, []))
                if trouve:
                    break
            if trouve:
                d1 = d2 = trouve[0]
                cert = "acte"
                rem = trouve[1]
            elif cle(noms[dst])[:9] and cle(noms[dst])[:9] in corpus.get(dep, ""):
                d1, d2, cert = "1941-01-01", "1986-12-31", "borne_sup"
                rem = "cité par l'annexe VII sans qu'un appariement exact soit possible"
            elif dep in CADRE_CHANGE:
                d1, d2, cert = "", "", "cadre_change"
                rem = ("le différentiel 1940→1999 n'est pas ici un mouvement "
                       "cantonal : " + CADRE_CHANGE[dep])
            else:
                d1, d2, cert = "1986-01-01", "1999-01-01", "post_1986"
                rem = ("absent de l'annexe VII, qui s'arrête au découpage de 1986 : "
                       "canton créé entre 1986 et 1999, non datable par cette source")
        else:
            d1, d2 = "1940-01-01", "1999-01-01"
            rem = ("transfert isolé de commune : l'annexe VII ne recense jamais "
                   "ce type de mouvement")

        lignes.append(dict(
            dep=dep, type=typ, date_debut=d1, date_fin=d2,
            date_retenue=d1 if cert == "acte" else "",
            certitude=cert,
            canton_source=f"{src} {noms[src]}",
            cantons_resultants=f"{dst} {noms[dst]}",
            communes=" ".join(sorted(communes)),
            source="base + annexe VII" if cert == "acte" else "base",
            remarque=rem))

    lignes.sort(key=lambda r: (r["dep"], r["date_debut"], r["canton_source"]))
    with SORTIE.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=CHAMPS)
        w.writeheader()
        w.writerows(lignes)

    import collections
    print(f"{SORTIE.name} : {len(lignes)} lignes, "
          f"{len({l['dep'] for l in lignes})} départements\n")

    certs = ["acte", "borne_sup", "post_1986", "inconnue", "cadre_change"]
    croix = collections.Counter((l["type"], l["certitude"]) for l in lignes)
    print(f"{'':14s}" + "".join(f"{c:>13s}" for c in certs) + f"{'total':>8s}")
    for ty in sorted({l["type"] for l in lignes}):
        v = [croix.get((ty, c), 0) for c in certs]
        print(f"{ty:14s}" + "".join(f"{x:13d}" for x in v) + f"{sum(v):8d}")

    # Un partage est un ÉTAT — une commune relevant de plusieurs cantons —,
    # pas un mouvement. Le taux se calcule sur les seuls mouvements réels,
    # sans quoi il est dilué par des lignes qui ne datent rien.
    reels = [l for l in lignes
             if l["type"] != "partage" and l["certitude"] != "cadre_change"]
    n = sum(1 for l in reels if l["certitude"] == "acte")
    print(f"\n{len(reels)} mouvements réels (hors partages), "
          f"dont {n} datés au décret — {100*n//max(len(reels),1)} %.")
    d = [l for l in lignes if l["type"] == "demembrement"
         and l["certitude"] != "cadre_change"]
    nd = sum(1 for l in d if l["certitude"] == "acte")
    print(f"{len(d)} démembrements, dont {nd} datés — "
          f"{100*nd//max(len(d),1)} %. C'est le chiffre qui compte : "
          f"ce sont eux qui déplacent des limites.")
    cc = [l for l in lignes if l["certitude"] == "cadre_change"]
    if cc:
        print(f"\n{len(cc)} lignes écartées du calcul dans "
              f"{len({l['dep'] for l in cc})} départements : changement de cadre "
              f"départemental, pas mouvement cantonal.")


if __name__ == "__main__":
    main()
