#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
controle_1954.py — juger l'extraction de 1954, et en tirer les créations

    python3 cog1954/controle_1954.py

Lit `cog1954/communes_1954.csv` produit par `extrait_1954.py` et rend deux
choses distinctes, qu'il ne faut jamais confondre :

* **des défauts de lecture** — codes impossibles, communes non retrouvées,
  populations refusées : à corriger ;
* **des résultats** — cantons présents en 1954 et absents en 1940 : à garder.

Séparer les deux est tout l'enjeu. Un canton inconnu dans un OCR peut être une
erreur de reconnaissance ou une création de 1948, et rien dans la ligne ne le
dit. **Ce qui les distingue est la répétition** : le bruit d'OCR est isolé et
aléatoire, une création se lit sur plusieurs communes contiguës à la fois. Le
script compte donc les occurrences avant de qualifier, et ne tranche jamais
sur une ligne unique.

Ce script ne touche pas à la base : il travaille sur les fichiers de `build/`,
pour rester utilisable même sans PostgreSQL.
"""

import collections
import csv
import re
import sys
import unicodedata
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
# On préfère le fichier REDÉCOUPÉ s'il existe : ses frontières
# départementales sont établies par l'ordre alphabétique et non par l'OCR des
# en-têtes, qui confond Haute-Loire avec Loire.
_RED = RACINE / "cog1954" / "communes_1954_redecoupe.csv"
if _RED.exists():
    LU = _RED
else:
    # Repli, mais annoncé. Le fichier non redécoupé porte les codes de
    # département tels que l'OCR les a lus, avec le décalage de 43 lignes
    # décrit dans note_1954.md. Y retomber sans le savoir fausse tout le
    # contrôle sans rien faire échouer.
    LU = RACINE / "cog1954" / "communes_1954.csv"
    print(f"ATTENTION : {_RED.name} absent, repli sur {LU.name} "
          f"(codes de département non redécoupés)")
SORTIE = RACINE / "cog1954" / "controle_1954.csv"
CREATIONS = RACINE / "cog1954" / "cantons_nouveaux_1954.csv"

# Au-dessous de ce nombre de communes, un code de canton inconnu est tenu pour
# du bruit d'OCR et non pour une création. Deux communes ne suffisent pas :
# une coquille sur un chiffre peut se répéter d'une ligne à l'autre quand deux
# communes voisines partagent la même graphie mal imprimée.
SEUIL_CREATION = 3

# Départements où « absent de 1940 » ne veut RIEN dire, parce que la base et le
# volume de 1954 n'y parlent pas du même cadre :
#
#   20   la Corse, que la base range en 2A/2B depuis le recodage de 1976 ;
#        Belgodère et Borgo existaient bien avant 1940 ;
#   75   la Seine, démembrée en 1964 en 75, 92, 93, 94 ;
#   78O  la Seine-et-Oise, démembrée la même année en 78, 91, 95 ;
#   13   Marseille et 69 Lyon, repliées en pseudo-cantons par
#        `25_pseudo_canton.sql`.
#
# Sans ce tri, 78 des 80 « créations » sont des artefacts de cadre. C'est le
# même piège que les 120 fausses créations tardives du registre cantonal et
# que les 22 atomes « déplacés » de `35` : un changement de référentiel se
# déguise en événement. Troisième fois qu'il se présente dans ce projet.
CADRE = {
    "20":  "Corse recodée 2A/2B en 1976",
    "75":  "Seine démembrée en 1964",
    "78O": "Seine-et-Oise démembrée en 1964",
    "13":  "Marseille repliée en pseudo-cantons",
    "69":  "Lyon replié en pseudo-cantons",
}


def cantons_transferes():   # noqa: C901
    """Cantons passés d'un département à un autre APRÈS 1954.

    Saint-Symphorien-d'Ozon ressortait en « création » : il est dans l'Isère
    en 1954 et dans le Rhône dans la base, parce qu'il a été rattaché au Rhône
    le 23 décembre 1967. Rien n'a été créé — la frontière a bougé.

    On ne code pas la liste en dur : l'annexe VII la porte déjà, sous les
    types `cession_departement` et `transfert_departement`. Une exclusion
    codée à la main aurait vieilli sans qu'on le sache ; celle-ci suit la
    transcription.
    """
    f = RACINE / "cantons" / "annexe_vii.csv"
    if not f.exists():
        return set()
    # Le texte est aplati EN ENTIER par département, et l'on teste
    # l'inclusion du nom du canton dedans. Comparer mot à mot ne marche pas :
    # « Saint-Symphorien-d'Ozon » est une expression, et aucun de ses mots
    # isolés ne la désigne. C'est encore la leçon de « le roule » contre
    # « roule », prise par l'autre bout — ici il faut la chaîne entière, là il
    # fallait le mot. Ce qui compte est de comparer ce que les deux sources
    # énoncent de la même façon.
    par_dep = collections.defaultdict(str)
    for l in csv.DictReader(f.open(encoding="utf-8")):
        if l["type"] in ("cession_departement", "transfert_departement"):
            par_dep[l["dep"]] += cle(l["texte"])
    return par_dep


def cle(nom):
    s = (nom or "").lower().replace("œ", "oe")
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    s = s.replace("sainte", "ste").replace("saint", "st")
    # « Capelle (La) » et « La Capelle » sont la même commune : le volume
    # rejette l'article en fin de nom, l'usage moderne le met devant.
    m = re.match(r"^(.*?)\s*\((le|la|les|l')\)\s*$", s, re.I)
    if m:
        s = m.group(2) + m.group(1)
    return re.sub(r"[^a-z0-9]+", "", s)


def main():
    if not LU.exists():
        sys.exit(f"{LU} absent. Lancer d'abord :\n"
                 "    python3 cog1954/extrait_1954.py")
    lignes = list(csv.DictReader(LU.open(encoding="utf-8")))
    print(f"{len(lignes)} lignes lues, "
          f"{len({l['dep'] for l in lignes if l['dep']})} départements")

    # --- référentiels de la base --------------------------------------
    unites = {}
    for l in csv.DictReader((RACINE / "build" / "unit_canton.csv")
                            .open(encoding="utf-8")):
        unites[l["unit_id"]] = l["nom"]

    # composition de 1940 : quelles communes, dans quel canton
    c40 = {}
    for l in csv.DictReader((RACINE / "build" / "membership_canton.csv")
                            .open(encoding="utf-8")):
        if l["valid_from"] <= "1940-06-01" < l["valid_to"] and l["insee"]:
            c40.setdefault(l["insee"][:2], {})[l["insee"]] = l["unit_id"]

    noms = {}
    f = RACINE / "build" / "noms_geofla.csv"
    if f.exists():
        for l in csv.DictReader(f.open(encoding="utf-8")):
            noms.setdefault(l["dep"], {})[cle(l["nom"])] = l["insee"]

    # --- contrôles ------------------------------------------------------
    par_dep = collections.defaultdict(list)
    for l in lignes:
        if l["dep"]:
            par_dep[l["dep"]].append(l)

    transferes = cantons_transferes()
    bilan, inconnus, creations = [], [], []
    for dep in sorted(par_dep):
        lot = par_dep[dep]
        codes = collections.Counter(f"{dep}{int(l['canton']):02d}" for l in lot)
        connus40 = set(c40.get(dep, {}).values())
        absents = {c: n for c, n in codes.items() if c not in unites}
        hors40 = {c: n for c, n in codes.items()
                  if c in unites and c not in connus40}

        # nom retrouvé dans la trame moderne ? mesure de la qualité de l'OCR
        # sur les noms, pas de la véracité du rattachement.
        ref = noms.get(dep, {})
        retrouves = sum(1 for l in lot if cle(l["commune"]) in ref) if ref else 0
        sans_pop = sum(1 for l in lot if not l["pop_1954"])
        herite = sum(1 for l in lot
                     if str(l.get("entete_heritee", "")).lower() == "true")

        bilan.append(dict(
            dep=dep, communes_1954=len(lot), communes_1940=len(c40.get(dep, {})),
            cantons_1954=len(codes), cantons_1940=len(connus40),
            codes_impossibles=sum(absents.values()),
            noms_retrouves=retrouves,
            taux_noms=f"{100*retrouves//len(lot)}%" if lot and ref else "",
            sans_population=sans_pop, entete_heritee=herite))

        # ERREUR DE CONCEPTION CORRIGÉE. Je cherchais les créations parmi les
        # codes PRÉSENTS dans la nomenclature et absents de 1940. C'est
        # impossible : la nomenclature est bâtie sur TRF-GIS, qui s'arrête en
        # 1940. Un canton créé en 1949 n'y figure pas, par construction — il
        # tombait donc dans le seau que j'avais étiqueté « bruit d'OCR ».
        #
        # Vérifié sur les trois créations que l'annexe VII date entre 1941 et
        # 1954 : Sousceyrac (46, 1949), Tende (06, 1951), Brive-N. et Brive-S.
        # (19, 1951). Aucune n'existe dans `unit_canton.csv`. Le test ne
        # pouvait pas les trouver là où je les cherchais.
        #
        # Les vraies créations sont donc ICI, parmi les codes hors
        # nomenclature répétés — à condition d'écarter d'abord les
        # départements à cadre changé, qui en fabriquent des dizaines.
        for c, n in sorted(absents.items()):
            inconnus.append(dict(dep=dep, code=c, communes=n,
                                 verdict=("cadre : " + CADRE[dep]) if dep in CADRE
                                 else "bruit d'OCR probable"
                                 if n < SEUIL_CREATION else
                                 "CANDIDAT création après 1940",
                                 exemples=" ; ".join(
                                     l["commune"] for l in lot
                                     if f"{dep}{int(l['canton']):02d}" == c)[:90]))
        for c, n in sorted(hors40.items()):
            creations.append(dict(
                dep=dep, code=c, nom=unites.get(c, ""), communes=n,
                verdict=("cadre : " + CADRE[dep]) if dep in CADRE
                        else "cadre : canton transféré de département après 1954"
                        if len(cle(unites.get(c, ""))) > 5
                        and cle(unites.get(c, "")) in transferes.get(dep, "")
                        else "création 1941-1954 probable" if n >= SEUIL_CREATION
                        else "trop peu de communes — bruit d'OCR probable",
                exemples=" ; ".join(l["commune"] for l in lot
                                    if f"{dep}{int(l['canton']):02d}" == c)[:90]))

    with SORTIE.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(bilan[0]))
        w.writeheader()
        w.writerows(bilan)

    with (RACINE / "cog1954" / "codes_hors_nomenclature_1954.csv").open(
            "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["dep", "code", "communes", "verdict",
                                          "exemples"])
        w.writeheader()
        w.writerows(inconnus)

    with CREATIONS.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["dep", "code", "nom", "communes",
                                          "verdict", "exemples"])
        w.writeheader()
        w.writerows(creations)

    tot = lambda k: sum(b[k] for b in bilan)
    print(f"\ncommunes lues 1954 : {tot('communes_1954')}   "
          f"(base 1940 : {tot('communes_1940')})")
    print(f"cantons distincts  : {tot('cantons_1954')}   "
          f"(base 1940 : {tot('cantons_1940')})")
    print(f"codes hors nomenclature : {tot('codes_impossibles')} lignes")
    print(f"populations refusées    : {tot('sans_population')} lignes")
    print(f"lignes à en-tête hérité : {tot('entete_heritee')}")
    if any(b["taux_noms"] for b in bilan):
        r, n = tot("noms_retrouves"), tot("communes_1954")
        print(f"noms retrouvés dans la trame moderne : {r}/{n} "
              f"— {100*r//max(n,1)} %")

    bruts = [c for c in creations if c["communes"] >= SEUIL_CREATION]
    cadre = [c for c in bruts if c["verdict"].startswith("cadre")]
    solides = [c for c in bruts if not c["verdict"].startswith("cadre")]
    print(f"\n{len(bruts)} cantons présents en 1954 et absents en 1940 "
          f"(au moins {SEUIL_CREATION} communes), dont :")
    print(f"  {len(cadre):3d} artefacts de CADRE — "
          f"{', '.join(sorted({c['verdict'][8:] for c in cadre}))}")
    print(f"  {len(solides):3d} candidats réels")
    print("\n**Les candidats réels — créations cantonales datées d'entre 1941 "
          "et 1954 :**")
    for c in sorted(solides, key=lambda x: -x["communes"]):
        print(f"  {c['code']}  {c['nom'][:26]:26s} {c['communes']:3d} communes")
    cand = [c for c in inconnus if c["verdict"].startswith("CANDIDAT")]
    print(f"\n**{len(cand)} codes hors nomenclature répétés hors cadre changé** "
          f"— c'est LÀ que sont les créations postérieures à 1940 :")
    for c in sorted(cand, key=lambda x: -x["communes"])[:20]:
        print(f"  {c['code']}  {c['communes']:3d} communes : {c['exemples'][:60]}")

    print("\nÀ confronter à l'annexe VII, qui ne compte qu'UNE décision "
          "cantonale dans les années 1940 et dix dans les années 1950 : deux "
          "sources sans rapport, un même ordre de grandeur attendu.")

    print(f"\n{SORTIE}\n{CREATIONS}")
    print("\nRappel : un code isolé n'est jamais une création. La répétition "
          "sur plusieurs communes est le seul signal qui distingue un fait "
          "d'une coquille.")


if __name__ == "__main__":
    main()
