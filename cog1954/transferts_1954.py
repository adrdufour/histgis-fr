#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
transferts_1954.py — les communes qui ont changé de canton entre 1940 et 1954

    python3 cog1954/transferts_1954.py

Le volume de 1954 annonce que « de nombreuses communes ont changé de canton de
rattachement » et renvoie aux tableaux de population sans les lister. Ce
script les fait sortir, en confrontant commune par commune :

* la composition de **1940**, dans `build/membership_canton.csv` (TRF-GIS) ;
* la composition de **1954**, dans `cog1954/communes_1954_redecoupe.csv`.

C'est le dernier gisement de cette source, et le seul qui reste après
l'établissement des trois créations.

La difficulté, et pourquoi elle est irréductible
------------------------------------------------
**Le volume de 1954 ne porte aucun code Insee.** La jointure passe donc par le
NOM, dans le département — avec tout ce que cela suppose de fautes d'OCR
(« Neuilty-St-Front », « Ciermont-les-Fermes ») et de variantes d'usage
(« St-Priest » contre « Saint-Priest », « Capelle (La) » contre « La
Capelle »).

Le script ne cherche pas à forcer ces cas. Il rend séparément ce qu'il a
apparié et ce qu'il n'a pas su apparier, parce qu'un taux d'appariement est
lui-même une mesure : il dit ce que la comparaison couvre.

Trois verdicts, et un seul est un résultat
------------------------------------------
`stable`
    même canton en 1940 et en 1954. C'est le cas de l'écrasante majorité, et
    c'est en soi une information : la carte cantonale ne bouge presque pas.

`transfert`
    canton différent, les deux codes existant dans le département. C'est le
    résultat cherché — sous réserve du contrôle ci-dessous.

`code_douteux`
    le canton lu en 1954 n'existe pas dans la nomenclature du département.
    C'est une faute d'OCR sur un chiffre, pas un transfert. On les compte
    plutôt que de les jeter : leur nombre mesure le bruit résiduel.

Le contrôle qui sépare le fait du bruit
---------------------------------------
Un chiffre mal lu produit un transfert **isolé et incohérent** ; un vrai
mouvement de limite en produit **plusieurs vers le même canton**. Le script
compte donc, pour chaque couple (canton de départ, canton d'arrivée), combien
de communes font le même trajet — et cette colonne est la première à lire.

Elle ne tranche pas tout : un transfert isolé peut être réel. Elle donne un
ordre de confiance, pas un verdict.
"""

import collections
import csv
import re
import sys
import unicodedata
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
LU = RACINE / "cog1954" / "communes_1954_redecoupe.csv"
SORTIE = RACINE / "cog1954" / "transferts_1954.csv"
NON_APPARIES = RACINE / "cog1954" / "non_apparies_1954.csv"


def cle(nom):
    s = (nom or "").lower().replace("œ", "oe").replace("æ", "ae")
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    s = s.replace("sainte", "ste").replace("saint", "st")
    # « Capelle (La) » du volume et « La Capelle » de l'usage moderne : le
    # tableau rejette l'article en fin de nom pour classer alphabétiquement.
    m = re.match(r"^(.*?)\s*\((le|la|les|l')\)\s*$", s, re.I)
    if m:
        s = m.group(2) + m.group(1)
    return re.sub(r"[^a-z0-9]+", "", s)


def main():
    if not LU.exists():
        sys.exit(f"{LU} absent. Lancer d'abord redecoupe_departements.py")

    unites = {l["unit_id"]: l["nom"] for l in
              csv.DictReader((RACINE / "build" / "unit_canton.csv")
                             .open(encoding="utf-8"))}

    # 1940 : insee -> unit_id
    c40 = {}
    for l in csv.DictReader((RACINE / "build" / "membership_canton.csv")
                            .open(encoding="utf-8")):
        if l["valid_from"] <= "1940-06-01" < l["valid_to"] and l["insee"]:
            c40[l["insee"]] = l["unit_id"]

    # noms des communes -> insee, par département
    par_nom = collections.defaultdict(dict)
    for l in csv.DictReader((RACINE / "build" / "noms_geofla.csv")
                            .open(encoding="utf-8")):
        par_nom[l["dep"]][cle(l["nom"])] = l["insee"]

    lignes = list(csv.DictReader(LU.open(encoding="utf-8")))
    print(f"{len(lignes)} communes lues en 1954, "
          f"{len(c40)} rattachements connus en 1940")

    resultats, orphelins = [], []
    for l in lignes:
        dep = l["dep"]
        if not dep:
            continue
        insee = par_nom.get(dep, {}).get(cle(l["commune"]))
        if not insee:
            orphelins.append(dict(dep=dep, commune=l["commune"],
                                  cle=cle(l["commune"]), page=l["page"],
                                  motif="nom introuvable dans la trame"))
            continue
        u40 = c40.get(insee)
        if not u40:
            orphelins.append(dict(dep=dep, commune=l["commune"],
                                  cle=cle(l["commune"]), page=l["page"],
                                  motif="commune sans canton en 1940"))
            continue
        u54 = f"{dep}{int(l['canton']):02d}"
        if u54 == u40:
            verdict = "stable"
        elif u54 not in unites:
            verdict = "code_douteux"
        else:
            verdict = "transfert"
        resultats.append(dict(dep=dep, insee=insee, commune=l["commune"],
                              canton_1940=u40, nom_1940=unites.get(u40, ""),
                              canton_1954=u54, nom_1954=unites.get(u54, ""),
                              verdict=verdict, page=l["page"],
                              compagnons=0))

    # combien de communes font le MÊME trajet : le signal qui sépare le
    # mouvement de limite de la faute de lecture isolée.
    trajets = collections.Counter(
        (r["canton_1940"], r["canton_1954"]) for r in resultats
        if r["verdict"] == "transfert")
    for r in resultats:
        if r["verdict"] == "transfert":
            r["compagnons"] = trajets[(r["canton_1940"], r["canton_1954"])]

    with SORTIE.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(resultats[0]))
        w.writeheader()
        w.writerows(sorted(resultats, key=lambda r: (r["verdict"] != "transfert",
                                                     -r["compagnons"], r["dep"])))
    with NON_APPARIES.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["dep", "commune", "cle", "page",
                                          "motif"])
        w.writeheader()
        w.writerows(orphelins)

    n = collections.Counter(r["verdict"] for r in resultats)
    tot = len(resultats)
    print(f"\ncommunes appariées : {tot} "
          f"({100*tot//max(len(lignes),1)} % des lignes lues)")
    for v in ("stable", "transfert", "code_douteux"):
        print(f"   {v:14s} {n[v]:6d}  {100*n[v]//max(tot,1):3d} %")
    print(f"\nnon appariées : {len(orphelins)}")
    for m, k in collections.Counter(o["motif"] for o in orphelins).most_common():
        print(f"   {m:38s} {k}")

    tr = [r for r in resultats if r["verdict"] == "transfert"]
    groupes = [r for r in tr if r["compagnons"] >= 3]
    print(f"\n**{len(tr)} transferts**, dont {len(groupes)} dans un mouvement "
          f"de 3 communes ou plus vers le même canton.")
    print("\nles trajets les plus fournis :")
    for (a, b), k in trajets.most_common(12):
        print(f"   {k:3d} communes  {a} {unites.get(a,'')[:20]:20s} "
              f"-> {b} {unites.get(b,'')[:20]}")
    print(f"\n{SORTIE}\n{NON_APPARIES}")


if __name__ == "__main__":
    main()
