#!/usr/bin/env python3
"""
resoudre_absorbantes.py — complète la colonne `cible` de geom_correspondance.csv
en interrogeant l'API Métadonnées de l'INSEE sur la filiation des communes
disparues entre 1943 et 2011.

Usage :
    python3 resoudre_absorbantes.py geom_correspondance.csv
    python3 resoudre_absorbantes.py geom_correspondance.csv --out resolu.csv

L'API exige un en-tête Accept explicite : sans lui elle répond 406. Elle est
interrogée à 2,1 s par requête, très en deçà du quota de 10 000 par jour.

Le script ne complète que les lignes de méthode `absorbee` dont la cible est
vide, et laisse en l'état celles qu'il ne sait pas résoudre : une filiation
inventée déplacerait silencieusement des communes entières sur les cartes.
"""

import argparse
import csv
import json
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

BASE = "https://api.insee.fr/metadonnees/V1/geo"
ENTETES = {"Accept": "application/json",
           "User-Agent": "histgis/1.0 (recherche academique)"}
DELAI = 2.1


def interroger(chemin):
    url = f"{BASE}{chemin}"
    req = urllib.request.Request(url, headers=dict(ENTETES))
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)


def suivants(code):
    """Communes qui succèdent à une commune supprimée.

    On essaie d'abord /suivants, qui donne la filiation directe. En cas
    d'échec on retombe sur une interrogation datée, l'API acceptant une
    date antérieure à la suppression.
    """
    tentatives = [
        f"/commune/{code}/suivants",
        f"/commune/{code}/suivant",
        f"/commune/{code}?date=2010-01-01",
    ]
    for chemin in tentatives:
        try:
            data = interroger(chemin)
        except urllib.error.HTTPError as e:
            if e.code in (404, 400, 406):
                continue
            raise
        except urllib.error.URLError:
            raise
        if not data:
            continue
        if isinstance(data, dict):
            data = [data]
        codes = []
        for item in data:
            c = item.get("code") or item.get("com")
            nom = item.get("intitule") or item.get("libelle") or ""
            if c and c != code:
                codes.append((c, nom))
        if codes:
            return codes, chemin
    return [], None


def diagnostic(code):
    """Affiche la réponse brute de chaque endpoint, sans filtrage."""
    chemins = [
        f"/commune/{code}",
        f"/commune/{code}?date=2010-01-01",
        f"/commune/{code}/suivants",
        f"/commune/{code}/precedents",
        f"/commune/{code}/ascendants",
    ]
    for chemin in chemins:
        print(f"\n--- {chemin}")
        try:
            data = interroger(chemin)
            print(json.dumps(data, ensure_ascii=False, indent=2)[:900])
        except urllib.error.HTTPError as e:
            print(f"HTTP {e.code}")
        except Exception as e:
            print(f"erreur : {e}")
        time.sleep(DELAI)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("csv_in", nargs="?", default="")
    ap.add_argument("--out", default="")
    ap.add_argument("--debug", default="", help="code commune à diagnostiquer")
    a = ap.parse_args()

    if a.debug:
        diagnostic(a.debug)
        return
    if not a.csv_in:
        sys.exit("Indiquer un CSV ou --debug CODE.")

    with open(a.csv_in, newline="", encoding="utf-8") as fh:
        lignes = list(csv.DictReader(fh))
        champs = lignes[0].keys() if lignes else []

    n_resolus = n_echecs = 0
    for ligne in lignes:
        if ligne["methode"] != "absorbee" or ligne["cible"].strip():
            continue
        code = ligne["insee"]
        try:
            codes, chemin = suivants(code)
        except Exception as e:
            print(f"  {code} : erreur réseau ({e})", file=sys.stderr)
            n_echecs += 1
            time.sleep(DELAI)
            continue

        if len(codes) == 1:
            ligne["cible"] = codes[0][0]
            ligne["commentaire"] += f" -> {codes[0][1]} [{chemin}]"
            print(f"  {code} -> {codes[0][0]} {codes[0][1]}")
            n_resolus += 1
        elif len(codes) > 1:
            # Plusieurs successeurs : le territoire a été partagé, le choix
            # n'est pas mécanique et doit être tranché à la main.
            détail = "; ".join(f"{c} {n}" for c, n in codes)
            ligne["commentaire"] += f" | PLUSIEURS SUCCESSEURS : {détail}"
            print(f"  {code} : {len(codes)} successeurs, à trancher",
                  file=sys.stderr)
            n_echecs += 1
        else:
            ligne["commentaire"] += " | non résolu par l'API"
            print(f"  {code} : aucune filiation trouvée", file=sys.stderr)
            n_echecs += 1
        time.sleep(DELAI)

    sortie = a.out or a.csv_in
    with open(sortie, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=list(champs))
        w.writeheader()
        w.writerows(lignes)

    print(f"\n{n_resolus} résolues, {n_echecs} à traiter à la main.",
          file=sys.stderr)
    print(f"Écrit dans {sortie}", file=sys.stderr)


if __name__ == "__main__":
    main()
