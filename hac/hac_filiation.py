#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
hac_filiation.py — extraire de HAC la filiation des communes créées 1870-1941.

    python3 hac/hac_filiation.py            # écrit hac/hac_filiation.csv
    python3 hac/hac_filiation.py --dep 57   # limité à un département

À quoi ça sert
--------------
`11_scission.sql` prolonge vers 1870 les communes nées PENDANT la série, sur
un pari : « une commune nouvelle reste dans le canton de sa mère ». Il fait ce
pari **sans jamais savoir qui est la mère** — il n'a que la géométrie et les
cantons. 414 atomes ont été prolongés ainsi, dont 4 à tort selon le contrôle
Gay, et `METHODE.md` note que ces quatre « se tranchent sur pièces d'archives ».

HAC — *Des villages de Cassini aux communes d'aujourd'hui*, EHESS — nomme la
mère. Sa colonne `f./c./t.` donne, en clair :

    9222.0   "réunie en 1886, (avec Saint-Antoine-de-Rochefort) à
              La Ferté-Bernard • Créée en 1888, à partir de La Ferté-Bernard"

C'est donc une voie **indépendante** de celle de `11`, et le contrôle qui
manquait depuis le début.

La clé, et c'est ce qui rend l'exercice sûr
-------------------------------------------
**L'`id` de HAC EST la colonne `cassini` de TRF-GIS.** Vérifié sur Cherré
(9222), La Ferté-Bernard (18180), Saint-Antoine-de-Rochefort (30448) : mêmes
identifiants, mêmes communes. La fille n'a donc pas à être rapprochée par nom —
c'est la clé la plus sûre du projet, et celle que `METHODE.md` réclame.

**La mère, en revanche, n'est nommée qu'en clair.** Sur 447 créations de la
fenêtre, 45 ont une mère au nom non unique dans HAC : dix « Saint-Just », onze
« Sainte-Marie ». La résolution se fait donc **dans le département de la
fille**, et refuse tout cas qui ne donne pas exactement un candidat. On préfère
un trou déclaré à un rattachement inventé.

Le département et les noms viennent de la nomenclature TRF-GIS elle-même
(`COG_COMMUNES_*.txt`), pas de HAC : on reste dans le référentiel du projet, et
la correspondance cassini → département est un fait de la source, pas une
reconstruction.

Sortie
------
`hac/hac_filiation.csv` — une ligne par création résolue :

    cassini_fille, nom_fille, dep, annee, nom_mere_hac, cassini_mere, voie

`voie` vaut `unique` (un seul candidat dans le département), `homonyme_dep`
(plusieurs, écarté) ou `introuvable` (aucun). Seules les lignes `unique` sont
exploitables ; les autres sont écrites quand même, pour qu'on sache ce qu'on
ne sait pas.
"""

import argparse
import csv
import re
import sys
import unicodedata
from collections import Counter, defaultdict
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
HAC = RACINE / "sources" / "geofla" / "repro" / "source_data" / "HAC"
NOMENCLATURE = RACINE / "sources" / "trfgis" / "communes" / "Nomenclatures"
SORTIE = RACINE / "hac" / "hac_filiation.csv"

AN_MIN, AN_MAX = 1870, 1941

# « Créée en 1888, à partir de La Ferté-Bernard »
# Le corps s'arrête au séparateur d'événements (•), à une barre oblique (qui
# sépare plusieurs communes) ou à la fin. Les guillemets fermants du .tab
# traînent parfois : on les retire.
RX_CREATION = re.compile(r"[Cc]r[ée]{2}e\s+en\s+(\d{4}),\s*à\s+partir\s+de\s+([^•/]+)")


def nettoie(nom):
    """Normalisation pour comparer des noms : capitales, sans accents ni
    ponctuation. Même convention que le reste du dépôt — on compare des formes,
    on ne les réécrit pas.

    Les crochets sont retirés d'abord : HAC glisse parfois un commentaire dans
    le nom — « Solignac [confirmé en 1890] », « Santa-Maria-Siché [et diverses
    communes des cantons de …] ».
    """
    nom = re.sub(r"\[.*?\]", " ", nom)
    s = unicodedata.normalize("NFD", nom.strip().strip('"'))
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    s = s.upper()
    s = re.sub(r"^(LE|LA|LES|L)[\s']+", "", s)
    s = re.sub(r"[^A-Z0-9]+", "", s)
    return s


def lit_tab(chemin):
    """Les .tab de HAC sont tabulés, avec une ligne d'entête `id\t…`."""
    with open(chemin, encoding="utf-8") as f:
        for ligne in csv.reader(f, delimiter="\t"):
            if ligne and ligne[0] != "id":
                yield ligne


def cassini_reference():
    """cassini -> (nom, dep), lu dans la nomenclature TRF-GIS.

    On lit PLUSIEURS millésimes et on garde la première occurrence : une
    commune créée en 1936 n'est pas dans le fichier de 1870. Les colonnes sont
    documentées par le CODEBOOK : 0 cassini, 1 insee, 3 com_name, 5 dep.
    """
    ref, insee_de = {}, {}
    fichiers = sorted(NOMENCLATURE.glob("COG_COMMUNES_[0-9]*.txt"))
    fichiers = [f for f in fichiers if "CODEBOOK" not in f.name]
    if not fichiers:
        sys.exit(f"Nomenclature TRF-GIS introuvable sous {NOMENCLATURE}")
    # du plus récent au plus ancien : le millésime tardif connaît toutes les
    # communes créées pendant la série
    for chemin in reversed(fichiers):
        with open(chemin, encoding="latin-1") as f:
            for ligne in csv.reader(f):
                if not ligne or ligne[0] == "cassini":
                    continue
                cid = ligne[0].strip()
                if cid and cid not in ref:
                    ref[cid] = (ligne[3].strip(), ligne[5].strip())
                    insee_de[cid] = ligne[1].strip()
    return ref, insee_de


def noms_modernes():
    """insee -> nom de GEOFLA 2011.

    HAC nomme la mère par son nom ACTUEL, la nomenclature TRF-GIS par celui de
    l'époque : « Villefranche-sur-Mer » contre « Villefranche »,
    « La Baule-Escoublac » contre « Escoublac », « Rillieux-la-Pape » contre
    « Rillieux ». Sans cette seconde clé, 32 mères sur 447 restaient
    introuvables — et toutes pour cette seule raison.
    """
    chemin = RACINE / "build" / "noms_geofla.csv"
    if not chemin.exists():
        return {}
    out = {}
    with open(chemin, encoding="utf-8") as f:
        for ligne in csv.reader(f):
            if len(ligne) >= 2 and ligne[0] != "insee":
                out[ligne[0].strip()] = ligne[1].strip()
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--dep", help="limiter à un département")
    ap.add_argument("--sortie", type=Path, default=SORTIE)
    args = ap.parse_args()

    ref, insee_de = cassini_reference()
    modernes = noms_modernes()
    print(f"Nomenclature TRF-GIS : {len(ref)} identifiants cassini")
    print(f"Noms GEOFLA 2011     : {len(modernes)}")

    # index nom normalisé -> [cassini], par département.
    # DEUX clés par commune : son nom d'époque et son nom de 2011. HAC emploie
    # le second, TRF-GIS le premier.
    par_dep = defaultdict(lambda: defaultdict(set))
    for cid, (nom, dep) in ref.items():
        par_dep[dep][nettoie(nom)].add(cid)
        moderne = modernes.get(insee_de.get(cid, ""))
        if moderne:
            par_dep[dep][nettoie(moderne)].add(cid)

    noms_hac = {r[0]: r[1].strip('"') for r in lit_tab(HAC / "header.tab")}

    lignes, compte = [], Counter()
    for r in lit_tab(HAC / "communal.tab"):
        texte = r[1].strip('"')
        if texte == "-":
            continue
        cid = r[0].replace(".0", "")
        for m in RX_CREATION.finditer(texte):
            annee = int(m.group(1))
            if not (AN_MIN <= annee <= AN_MAX):
                continue
            nom_mere = m.group(2).strip().rstrip('"').strip()
            nom_fille, dep = ref.get(cid, (noms_hac.get(r[0], "?"), ""))
            if args.dep and dep != args.dep:
                continue

            candidats = sorted(par_dep.get(dep, {}).get(nettoie(nom_mere), set()))
            if len(candidats) == 1:
                voie, cmere = "unique", candidats[0]
            elif len(candidats) > 1:
                voie, cmere = "homonyme_dep", ""
            else:
                voie, cmere = "introuvable", ""
            compte[voie] += 1
            lignes.append({
                "cassini_fille": cid, "nom_fille": nom_fille, "dep": dep,
                "annee": annee, "nom_mere_hac": nom_mere,
                "cassini_mere": cmere, "voie": voie,
            })

    args.sortie.parent.mkdir(parents=True, exist_ok=True)
    with open(args.sortie, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["cassini_fille", "nom_fille", "dep",
                                          "annee", "nom_mere_hac",
                                          "cassini_mere", "voie"])
        w.writeheader()
        w.writerows(sorted(lignes, key=lambda x: (x["dep"], x["annee"])))

    total = sum(compte.values())
    print(f"\nCréations HAC de {AN_MIN} à {AN_MAX} : {total}")
    for voie in ("unique", "homonyme_dep", "introuvable"):
        n = compte[voie]
        print(f"   {voie:14s} {n:5d}   {100*n/total:5.1f} %" if total else "")
    print(f"\nÉcrit : {args.sortie}")

    if compte["introuvable"]:
        print("\nMères introuvables — à examiner, pas à forcer :")
        for l in lignes:
            if l["voie"] == "introuvable":
                print(f"   {l['dep']} {l['annee']} {l['nom_fille']:28s} <- {l['nom_mere_hac']}")


if __name__ == "__main__":
    main()
