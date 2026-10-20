#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
composition_1958.py — de la transcription de l'atlas aux cantons de la base

    python3 circo/composition_1958.py          # écrit les deux CSV, lit la base

Lit `regles_1958_1986.py` (les cantons sous les noms de l'atlas) et la base
(les cantons vivants à la date de référence de chaque division), et écrit :

    circo/composition_1958_1986.csv   une ligne par (division, canton de l'atlas),
                                      avec l'unité de la base quand elle existe
    circo/composition_1958_etat.csv   une ligne par division : posable ou non,
                                      et pourquoi

UN DÉPARTEMENT EST POSABLE quand
  * tout canton de la base est rangé dans une circonscription et une seule ;
  * la carte ne porte aucun canton divisé (jetons « commune: », « reste: »…) :
    ceux-là demandent l'atome, pas le canton ;
  * moins de 15 % des cantons de l'atlas sont sans unité en base — au-delà,
    c'est la trame cantonale de la base qui manque (Orne, Savoie…), et poser
    reviendrait à ne presque rien poser sans le dire.

Les noms se rapprochent dans cet ordre : identiques à la casse et aux accents
près ; par ALIAS, ci-dessous, écrit à la main ; enfin par préfixe, si un seul
canton encore libre convient (« Montrevel » → Montrevel-en-Bresse).
"""
import collections, csv, subprocess, unicodedata
from pathlib import Path
from regles_1958_1986 import REGLES_1958

ICI = Path(__file__).resolve().parent

# (département, nom de l'atlas) → nom(s) de la base. Chefs-lieux déplacés,
# graphies, et villes dont la base numérote les cantons que l'atlas oriente
# (les cantons d'une même ville cités ici sont dans la même circonscription).
ALIAS = {
    ("06", "Lantosque"): ["Utelle"],
    ("19", "Brive-Nord"): ["Brives"], ("19", "Brive-Sud"): ["Brives"],
    ("20", "Sainte-Marie-Siché"): ["Santa-Maria-Siché"],
    ("20", "Porta"): ["La Porta"], ("20", "Saint-Laurent"): ["San-Lorenzo"],
    ("22", "Saint-Brieuc-Nord"): ["Saint-Brieuc-1"],
    ("22", "Saint-Brieuc-Sud"): ["Saint-Brieuc-2"],
    ("24", "Montpont"): ["Montpon-sur-l'Isle"],
    ("24", "Villefranche-de-Lonchat"): ["Villefranche-de-Longchapt"],
    ("34", "Sète"): ["Cette"],
    ("41", "Saint-Amand-Longpré"): ["Saint-Amand-de-Vendôme"],
    ("46", "Castelnau-de-Montratier"): ["Castelnau-Montratier"],
    ("51", "Givry-en-Argonne"): ["Dammartin-sur-Yvre"],
    ("52", "Nogent-le-Roi"): ["Nogent-en-Bassigny"],
    ("52", "Fays-Billot"): ["Fayl-Billot"],
    ("57", "Metzerwisse"): ["Metzervisse"],
    ("57", "Ars-sur-Moselle"): ["Gorze"],
    ("59", "Condé-sur-Escaut"): ["Condé-sur-l'Escaut"],
    ("60", "Nanteuil-le-Haudouin"): ["Nanteuil-le-Haudoin"],
    ("63", "Saint-Amant"): ["Saint-Amant-Roche-Savine"],
    ("68", "Sierentz"): ["Landser"],
    ("79", "Saint-Maixent-1"): ["Saint-Maixent-l'École-1"],
    ("79", "Saint-Maixent-2"): ["Saint-Maixent-l'École-2"],
    ("80", "Ailly"): ["Ailly-le-Haut-Clocher"],
    ("80", "Amiens-Nord-Ouest"): ["Amiens-1", "Amiens-2", "Amiens-3"],
    ("85", "Les Moutiers-les-Mauxfaits"): ["Moutiers-les-Mauxfaits"],
    # Ajoutés le 19 octobre 2026 : `120` a rendu la trame cantonale de 1958
    # aux départements absents du jalon de 1968 (Orne, Saône-et-Loire, Savoie),
    # et leurs graphies se lisent maintenant contre la base.
    ("61", "La Ferté-Fresnel"): ["La Ferté-Frênel"],
    ("71", "Chalon-Nord"): ["Chalon-sur-Saône-Nord"],
    ("71", "Chalon-Sud"): ["Chalon-sur-Saône-Sud"],
    ("73", "Pont-de-Beauvoisin"): ["Le Pont-de-Beauvoisin"],
    # Les jalons de 1954 et 1968 rangent sept communes au sud de Brive sous
    # l'unité de 1999 « Brive-la-Gaillarde-Sud-Est » ; `120` la fait vivre de
    # 1955 à 1968. Brive-Nord et Brive-Sud sont dans la même circonscription.
    ("19", "Brive-Sud"): ["Brives", "Brive-la-Gaillarde-Sud-Est"],
    # Metz : les fractions de la ville posées par `116` portent les cantons
    # Metz-1 à 3 ; Metz-Ville et Metz-Campagne sont dans la même circonscription.
    ("57", "Metz-Ville"): ["Metz-1", "Metz-2", "Metz-3"],
}


def cle(s):
    s = unicodedata.normalize("NFD", s.lower().replace("œ", "oe"))
    return "".join(c for c in s if c.isalnum())


def repare(nom):
    # quatre noms de `unit` portent deux U+FFFD pour une lettre accentuée
    return nom.replace("-��", "-É").replace("��", "é")


def base(dep, date):
    q = ("select distinct u.unit_id, u.nom from membership m join unit u using (unit_id) "
         f"where m.niveau='canton' and u.dep='{dep}' and m.periode @> date '{date}'")
    r = subprocess.run(["psql", "-d", "histgis", "-At", "-F", "\t", "-c", q],
                       capture_output=True, text=True, check=True)
    return {repare(n): i for i, n in (l.split("\t") for l in r.stdout.splitlines() if l)}


lignes, etats = [], []
for code, r in sorted(REGLES_1958.items()):
    dep = code[:2]
    ref = f"{r['depuis']}-12-01"
    noms = base(dep, ref)                       # nom réparé → unit_id
    par_cle = {cle(n): n for n in noms}
    pris = collections.defaultdict(set)         # nom de la base → circos
    divise = any(":" in c for cs in r["circos"].values() for c in cs)
    attente = []
    for circo, cantons in r["circos"].items():
        for c in cantons:
            if ":" in c:
                lignes.append([dep, r["nom"], r["depuis"], r["jusqu"], ref, circo, c, "", "", "divisé"])
                continue
            nu = c.split(" (")[0]
            cible = ALIAS.get((dep, nu)) or ([par_cle[cle(nu)]] if cle(nu) in par_cle else None)
            if cible:
                for n in cible:
                    if n in noms:
                        pris[n].add(circo)
                        lignes.append([dep, r["nom"], r["depuis"], r["jusqu"], ref, circo, c, noms[n], n, ""])
            else:
                attente.append((circo, c, nu))
    sans = []
    for circo, c, nu in attente:                # préfixe, parmi les cantons libres
        k = cle(nu)
        cand = [n for n in noms if n not in pris and (cle(n).startswith(k) or k.startswith(cle(n)))]
        if len(cand) == 1:
            pris[cand[0]].add(circo)
            lignes.append([dep, r["nom"], r["depuis"], r["jusqu"], ref, circo, c, noms[cand[0]], cand[0], "préfixe"])
        else:
            sans.append(c)
            lignes.append([dep, r["nom"], r["depuis"], r["jusqu"], ref, circo, c, "", "",
                           "ambigu" if cand else "sans unité en base"])
    oublies = sorted(set(noms) - set(pris))
    doubles = sorted(n for n, cs in pris.items() if len(cs) > 1)
    n_atlas = sum(len(cs) for cs in r["circos"].values())
    raisons = []
    if r.get("incomplet"): raisons.append("transcription incomplète")
    if divise:  raisons.append("cantons divisés")
    if oublies: raisons.append("en base, absents de la lecture : " + ", ".join(oublies))
    if doubles: raisons.append("dans deux circonscriptions : " + ", ".join(doubles))
    if len(sans) > 0.15 * n_atlas:
        raisons.append(f"{len(sans)} cantons de l'atlas sur {n_atlas} sans unité en base")
    etats.append([dep, r["nom"], r["depuis"], r["jusqu"], len(r["circos"]), len(noms),
                  "oui" if not raisons else "non", " ; ".join(raisons),
                  ", ".join(sans) if not raisons else ""])

with (ICI / "composition_1958_1986.csv").open("w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow("dep departement depuis jusqu reference circonscription canton_atlas "
               "canton_id canton_base note".split())
    w.writerows(lignes)
with (ICI / "composition_1958_etat.csv").open("w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow("dep departement depuis jusqu circos cantons_base posable raison "
               "atlas_sans_unite".split())
    w.writerows(etats)

oui = [e for e in etats if e[6] == "oui"]
print(f"{len(lignes)} lignes ; {len(oui)} divisions posables sur {len(etats)}")
print("posables :", " ".join(f"{e[0]}" for e in oui))
for e in etats:
    if e[6] == "non":
        print(f"  {e[0]} {e[1]} {e[2]}-{e[3]} : {e[7][:150]}")
for e in oui:
    if e[8]:
        print(f"  (posable, {e[0]}) atlas sans unité : {e[8]}")
