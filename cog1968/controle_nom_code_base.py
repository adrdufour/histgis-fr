#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
controle_nom_code_base.py — le nom confirme-t-il le code, dans ce que la BASE
a chargé du recensement de 1968 ?

    ~/miniforge3/envs/histgis/bin/python cog1968/controle_nom_code_base.py
    … --dep 01 --detail

Lecture seule. Écrit `cog1968/c68_suspects_base.csv`.

Pourquoi un second contrôle
---------------------------
`controle_nom_code.py` (22 août 2026) confrontait `communes_1968.csv`, la
première passe, aux noms de GEOFLA 2011. La base charge autre chose :
`communes_1968_fusion.csv` (`58`), qui ajoute les passes psm4, psm6 et 600, et
aucune étape de la chaîne ne lisait la liste des suspects. Le 21 octobre 2026,
l'Ain en a montré trois en base : la ligne « Beynost » sous le code de Birieux
(Birieux mise à Montluel), « Cressin-Rochefort » sous celui de Culoz (Culoz à
Belley), « Saint-Maurice-de-Rémens » sous celui de Viriat (Viriat coupée en
deux fractions). Voir `sql/121_ain_cessions_trous.sql`.

Deux changements par rapport au premier contrôle :
  * la source est `c68_lien` (une ligne par ligne de `c68_src`, avec le canton
    résolu), donc exactement ce que `59` a posé ;
  * la référence des noms est le COG de 2012 (`france2012.txt`), qui tient
    TOUTES les communes depuis 1943, disparues comprises, et tous leurs noms :
    une commune absorbée entre 1968 et 2011 n'échappe plus au contrôle.

Même discriminant : le nom lu ressemble-t-il davantage à une AUTRE commune du
département qu'à celle de son code ?

Ce que la base en a fait
------------------------
Pour chaque suspect, on regarde l'atome du code lu :
  * `canton_lu`   le canton de la ligne ;
  * `canton_54`, `canton_99`  ce que la base porte au 1954-06-01 et au
    1999-06-01 pour cet atome ;
  * `canton_68`   ce qu'elle porte au 1968-06-01, après `96` et les reports ;
  * `propose_68`  ce qu'elle porte au 1968-06-01 pour la commune du NOM.
Verdict :
  * `inoffensif`   le canton lu est aussi celui du code (voisines du même
    canton) : la ligne se trompe de commune, pas de canton ;
  * `en_base`      le canton lu est en base en 1968 pour l'atome du code, et
    ce n'est ni son canton de 1954 ni celui de 1999 : erreur posée ;
  * `ecartee`      le canton lu n'est pas en base en 1968 (retiré par `96`,
    contredit, ou atome non résolu) ;
  * `a_juger`      le canton lu est en base, et s'accorde avec 1954 OU 1999
    seulement.
"""

import argparse
import collections
import csv
import difflib
import sys
import unicodedata
from pathlib import Path

import psycopg2

RACINE = Path(__file__).resolve().parent.parent
COG = RACINE / "sources" / "cog" / "2012" / "france2012.txt"
SORTIE = RACINE / "cog1968" / "c68_suspects_base.csv"
CORRECTIONS = RACINE / "cog1968" / "c68_codes_corriges.csv"

# Les seuils de `controle_nom_code.py`, pour que les deux contrôles se
# comparent.
CONFORME = 0.80
CANDIDAT = 0.80


def cle(nom):
    """Sans accent, sans tiret, sans espace, sans renvoi « (1) »."""
    n = unicodedata.normalize("NFD", (nom or "").lower())
    n = "".join(c for c in n if unicodedata.category(c) != "Mn")
    n = n.split("(")[0]
    return "".join(c for c in n if c.isalpha())


def noms_cog():
    """code -> ensemble de clés (tous les noms connus du code depuis 1943)."""
    par_code = collections.defaultdict(set)
    lib = {}
    with open(COG, encoding="cp1252", newline="") as f:
        for r in csv.DictReader(f, delimiter="\t"):
            if len(r["DEP"]) != 2:
                continue
            code = r["DEP"] + r["COM"]
            art = (r["ARTMIN"] or "").strip("()")
            nom = r["NCCENR"]
            complet = (art + (" " if art and not art.endswith("'") else "") + nom).strip()
            par_code[code].add(cle(nom))
            par_code[code].add(cle(complet))
            if code not in lib or r["ACTUAL"] == "1":
                lib[code] = complet
    return par_code, lib


def ressemblance(lu, cles):
    best = 0.0
    for c in cles:
        if not c:
            continue
        if lu and (lu in c or c in lu) and min(len(lu), len(c)) >= 4:
            return 1.0
        best = max(best, difflib.SequenceMatcher(None, lu, c).ratio())
    return best


SQL_LIGNES = """
SELECT l.dep, l.insee, l.nom, l.canton, l.canton_id, l.accord, l.atome
FROM   c68_lien l
WHERE  (%(dep)s IS NULL OR l.dep = %(dep)s)
"""

SQL_CANTON = """
SELECT DISTINCT ON (a.insee_geofla, d)
       a.insee_geofla, d, m.unit_id
FROM   atom a
JOIN   membership m ON m.atom_id = a.atom_id AND m.niveau = 'canton'
CROSS  JOIN unnest(ARRAY['1954-06-01','1968-06-01','1999-06-01']::date[]) d
WHERE  m.periode @> d AND a.insee_geofla = ANY(%(codes)s)
ORDER  BY a.insee_geofla, d, a.fraction, m.unit_id
"""

SQL_CANTON_ATOME = """
SELECT m.atom_id, d, string_agg(DISTINCT m.unit_id, '+') AS u
FROM   membership m
CROSS  JOIN unnest(ARRAY['1954-06-01','1968-06-01','1999-06-01']::date[]) d
WHERE  m.niveau = 'canton' AND m.periode @> d
  AND  (m.atom_id = ANY(%(atomes)s) OR split_part(m.atom_id, '#', 1) = ANY(%(atomes)s))
GROUP  BY 1, 2
"""


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--dep")
    ap.add_argument("--dsn", default="dbname=histgis host=/var/run/postgresql")
    ap.add_argument("--detail", action="store_true")
    ap.add_argument("--ecrire-corrections", action="store_true",
                    help=f"écrire {CORRECTIONS.name}, lu par sql/58 (voir plus bas)")
    args = ap.parse_args()

    par_code, lib = noms_cog()
    par_dep = collections.defaultdict(dict)          # dep -> clé -> code
    for code, cles in par_code.items():
        for c in cles:
            if c:
                par_dep[code[:2]].setdefault(c, code)

    cx = psycopg2.connect(args.dsn)
    cx.set_session(readonly=True)
    cur = cx.cursor()
    cur.execute("SET search_path TO histgis, public")
    cur.execute(SQL_LIGNES, {"dep": args.dep})
    lignes = cur.fetchall()

    conformes = abimes = inconnus = 0
    suspects = []
    for dep, insee, nom, canton, canton_id, accord, atome in lignes:
        cles = par_code.get(insee)
        if not cles:
            inconnus += 1
            continue
        lu = cle(nom)
        if len(lu) < 3:
            abimes += 1
            continue
        r_code = ressemblance(lu, cles)
        if r_code >= CONFORME:
            conformes += 1
            continue
        cands = difflib.get_close_matches(lu, par_dep[dep].keys(), n=1, cutoff=CANDIDAT)
        if not cands or par_dep[dep][cands[0]] == insee:
            abimes += 1
            continue
        propose = par_dep[dep][cands[0]]
        r_prop = difflib.SequenceMatcher(None, lu, cands[0]).ratio()
        if r_prop <= r_code:
            abimes += 1
            continue
        suspects.append({
            "dep": dep, "insee_lu": insee, "nom_lu": nom,
            "nom_du_code": lib.get(insee, ""), "insee_propose": propose,
            "nom_propose": lib.get(propose, ""),
            "ressemblance_code": round(r_code, 2), "ressemblance_propose": round(r_prop, 2),
            "ecart": abs(int(propose[2:]) - int(insee[2:])) if propose[2:].isdigit() and insee[2:].isdigit() else "",
            "accord": accord, "canton_lu": canton_id, "atome": atome or "",
        })

    # Ce que la base en a fait.
    atomes = sorted({s["atome"] for s in suspects if s["atome"]})
    cur.execute(SQL_CANTON_ATOME, {"atomes": atomes})
    par_atome = collections.defaultdict(dict)
    for aid, d, u in cur.fetchall():
        base = aid.split("#")[0]
        prev = par_atome[base].get(str(d))
        par_atome[base][str(d)] = u if not prev else "+".join(sorted(set(prev.split("+")) | set(u.split("+"))))
    codes = sorted({s["insee_propose"] for s in suspects})
    cur.execute(SQL_CANTON, {"codes": codes})
    par_code_base = collections.defaultdict(dict)
    for code, d, u in cur.fetchall():
        par_code_base[code][str(d)] = u

    verdicts = collections.Counter()
    for s in suspects:
        b = par_atome.get(s["atome"], {})
        c54, c68, c99 = b.get("1954-06-01", ""), b.get("1968-06-01", ""), b.get("1999-06-01", "")
        s["canton_54"], s["canton_68"], s["canton_99"] = c54, c68, c99
        s["propose_68"] = par_code_base.get(s["insee_propose"], {}).get("1968-06-01", "")
        lu = s["canton_lu"]
        e54, e68, e99 = (set(x.split("+")) - {""} for x in (c54, c68, c99))
        if lu in e54 and lu in e99:
            v = "inoffensif"
        elif lu not in e68:
            v = "ecartee"
        elif lu not in e54 and lu not in e99:
            v = "en_base"
        else:
            v = "a_juger"
        # Le canton de la ligne est-il celui de la commune du NOM ?
        pb = par_code_base.get(s["insee_propose"], {})
        s["nom_confirme"] = "oui" if lu in {pb.get(d, "") for d in
                                            ("1954-06-01", "1968-06-01", "1999-06-01")} else "non"
        s["verdict"] = v
        verdicts[v] += 1

    ordre = {"en_base": 0, "a_juger": 1, "ecartee": 2, "inoffensif": 3}
    suspects.sort(key=lambda s: (ordre[s["verdict"]], s["dep"], s["insee_lu"]))
    champs = ["verdict", "dep", "insee_lu", "nom_du_code", "nom_lu", "insee_propose",
              "nom_propose", "ressemblance_code", "ressemblance_propose", "ecart",
              "accord", "atome", "canton_lu", "canton_54", "canton_68", "canton_99",
              "propose_68", "nom_confirme"]
    with SORTIE.open("w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=champs, extrasaction="ignore")
        w.writeheader()
        w.writerows(suspects)

    total = conformes + abimes + len(suspects)
    print(f"lignes de c68_lien : {len(lignes)} ; code absent du COG : {inconnus}")
    print(f"  nom conforme au code              {conformes:>6}  {conformes/total:6.1%}")
    print(f"  nom abîmé, pas de meilleur code   {abimes:>6}  {abimes/total:6.1%}")
    print(f"  nom d'une AUTRE commune           {len(suspects):>6}  {len(suspects)/total:6.1%}")
    print("\nce que la base en a fait :")
    for v in ("en_base", "a_juger", "ecartee", "inoffensif"):
        print(f"  {v:<12} {verdicts[v]:>5}")
    print("\npar passe d'OCR (accord) :")
    for a, n in collections.Counter(s["accord"] for s in suspects).most_common():
        nb = sum(1 for s in suspects if s["accord"] == a and s["verdict"] == "en_base")
        print(f"  {a:<16} {n:>5}   dont en_base {nb}")
    print("\nle canton de la ligne est celui de la commune du nom :")
    for v in ("en_base", "a_juger", "ecartee", "inoffensif"):
        n = sum(1 for s in suspects if s["verdict"] == v and s["nom_confirme"] == "oui")
        print(f"  {v:<12} {n:>5} / {verdicts[v]}")
    print("\ndépartements, erreurs en base :")
    c = collections.Counter(s["dep"] for s in suspects if s["verdict"] == "en_base")
    print("  " + "  ".join(f"{d}:{n}" for d, n in sorted(c.items())))
    print(f"\n{SORTIE.relative_to(RACINE)}")
    if args.ecrire_corrections:
        ecrire_corrections(cur, suspects)
    if args.detail:
        for s in suspects:
            if s["verdict"] in ("en_base", "a_juger"):
                print(f"  {s['verdict']:<8} {s['insee_lu']} {s['nom_du_code'][:22]:<22} "
                      f"lu « {s['nom_lu'][:24]:<24} » -> {s['insee_propose']} "
                      f"{s['nom_propose'][:20]:<20} lu {s['canton_lu']} "
                      f"54 {s['canton_54']} 68 {s['canton_68']} 99 {s['canton_99']}")
    return 0


FUSION = RACINE / "cog1968" / "communes_1968_fusion.csv"


def garder_dernieres(lignes):
    """Ne pas retirer la DERNIÈRE ligne d'un code quand elle était déjà écartée.

    Ajouté le 21 octobre 2026, après le premier rebuild corrigé : retirer une
    ligne `ecartee` qui est la seule de son code ôte à la commune sa lecture
    de 1968, que `96` savait corriger par ses arbitres (1954, 1999). Laon,
    Dax, Château-Gontier, Hinges, Barbazan-Debat et Théza avaient ainsi perdu
    leur canton de 1968. Une telle ligne reste au dépôt, telle quelle. Une
    ligne `en_base` est retirée même si elle est la dernière : un trou vaut
    mieux qu'un canton faux.
    """
    dans_src = collections.Counter(r["insee"] for r in
                                   csv.DictReader(FUSION.open(encoding="utf-8")))
    part = collections.Counter(l["insee_lu"] for l in lignes)
    arrive = collections.Counter(l["insee_corrige"] for l in lignes if l["action"] == "rendre")
    reste = {k: dans_src[k] - part[k] + arrive[k] for k in part}
    return [l for l in lignes
            if not (l["action"] == "retirer" and l["verdict"] == "ecartee"
                    and reste[l["insee_lu"]] == 0)]


def ecrire_corrections(cur, suspects):
    """Les lignes à rendre à leur commune, ou à retirer, pour `58`.

    Règles décidées le 21 octobre 2026 :
      * seules les lignes `en_base` et `ecartee` sont touchées : `inoffensif`
        et `a_juger` restent telles quelles ;
      * `nom_confirme = oui` (le canton de la ligne est celui de la commune
        nommée) : la ligne est RENDUE à la commune du nom — sauf si celle-ci a
        déjà sa propre ligne dans le dépôt, ou si deux lignes rendues au même
        code divergent de canton : `59` en ferait une fausse fraction, et la
        ligne est alors RETIRÉE ;
      * sinon (le nom désigne une autre commune, mais pas son canton) : le code
        et le canton sont faux tous les deux, la ligne est RETIRÉE ;
      * une ligne `ecartee` qui est la dernière de son code n'est pas retirée
        (voir `garder_dernieres`).

    Le fichier est écrit UNE fois, sur la base d'avant correction : rejoué sur
    une base déjà corrigée, le contrôle ne verrait plus ces lignes.
    """
    a_traiter = [s for s in suspects if s["verdict"] in ("en_base", "ecartee")]
    cur.execute("SELECT insee, canton, nom, page, dep || canton FROM c68_src")
    src = cur.fetchall()
    cles_suspectes = {(s["insee_lu"], s["canton_lu"], s["nom_lu"]) for s in a_traiter}
    deja = collections.defaultdict(set)              # code -> cantons de ses lignes propres
    page = {}
    for insee, canton, nom, pg, cid in src:
        page[(insee, cid, nom)] = pg
        if (insee, cid, nom) not in cles_suspectes:
            deja[insee].add(cid)
    rendus = collections.defaultdict(set)
    for s in a_traiter:
        if s["nom_confirme"] == "oui":
            rendus[s["insee_propose"]].add(s["canton_lu"])
    lignes = []
    for s in a_traiter:
        action, motif = "retirer", "nom d'une autre commune, canton d'aucune des deux"
        if s["nom_confirme"] == "oui":
            code = s["insee_propose"]
            if deja.get(code):
                motif = "la commune nommée a déjà sa ligne"
            elif len(rendus[code]) > 1:
                motif = "deux lignes rendues au même code, cantons divergents"
            else:
                action, motif = "rendre", "canton de la ligne = canton de la commune nommée"
        lignes.append({
            "dep": s["dep"], "insee_lu": s["insee_lu"], "canton": s["canton_lu"][2:],
            "nom_lu": s["nom_lu"], "page": page.get((s["insee_lu"], s["canton_lu"], s["nom_lu"]), ""),
            "action": action,
            "insee_corrige": s["insee_propose"] if action == "rendre" else "",
            "nom_corrige": s["nom_propose"] if action == "rendre" else "",
            "verdict": s["verdict"], "motif": motif,
        })
    lignes = garder_dernieres(lignes)
    with CORRECTIONS.open("w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=list(lignes[0].keys()))
        w.writeheader()
        w.writerows(lignes)
    c = collections.Counter((l["action"], l["motif"]) for l in lignes)
    print(f"\n{CORRECTIONS.relative_to(RACINE)} : {len(lignes)} lignes")
    for (a, m), n in sorted(c.items()):
        print(f"  {a:<8} {n:>4}  {m}")


if __name__ == "__main__":
    sys.exit(main())
