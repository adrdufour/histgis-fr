"""Combien des actes connus (registre Légifrance + complément) les tables du JO
retrouvent-elles ? Par numéro de décret quand les deux l'ont, sinon par
(année de publication, département).

    python3 cantons/rappel_tables.py      (depuis la racine)
"""
import collections
import csv
import re
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
T = list(csv.DictReader(open(RACINE / "cantons/tables_jo_actes.csv", encoding="utf-8")))
par_num = {r["decret"] for r in T if r["decret"]}
par_dep = {(int(r["annee"]), r["dep"]) for r in T if r["dep"]}
# un décret régional sans département (« Divers cantons. Limites territoriales
# et création. — D. 28 janv. 1964 ») : on le reconnaît à sa date
par_date = {r["date_acte"] for r in T if r["date_acte"]}


def num(s):
    m = re.search(r"(\d{2})\s*-\s*(\d{1,4})", s or "")
    return f"{m.group(1)}-{int(m.group(2))}" if m else ""


par_num = {num(x) for x in par_num}
actes = []
for x in csv.DictReader(open(RACINE / "cantons/decrets_cantonaux.csv", encoding="utf-8")):
    actes.append((x["date_publication_jo"] or x["date_signature"], x["dep_code"], num(x["decret"]), x["objet"],
                  x["date_signature"]))
for x in csv.DictReader(open(RACINE / "cantons/decrets_complement.csv", encoding="utf-8")):
    for d in re.split(r"[ ;,|]+", x["deps"]):
        if d:
            actes.append((x["date_publication_jo"] or x["date_signature"], d, num(x["decret"]), x["objet"],
                          x["date_signature"]))

ok, manque = 0, collections.Counter()
lignes = []
for date, dep, n, objet, sig in actes:
    if not date or not ("1941" <= date[:4] <= "1990"):
        continue
    a = int(date[:4])
    trouve = ((n and n in par_num) or (a, dep) in par_dep or (a + 1, dep) in par_dep
              or (sig and sig in par_date))
    ok += bool(trouve)
    if not trouve:
        manque[a] += 1
    lignes.append({"date": date, "dep": dep, "decret": n, "objet": objet, "dans_les_tables": "oui" if trouve else "non"})
print("actes connus 1941-1990 :", len(lignes), "— retrouvés dans les tables :", ok)
print("manquants par année :", sorted(manque.items()))
with open(RACINE / "cantons/rappel_tables.csv", "w", newline="", encoding="utf-8") as fo:
    w = csv.DictWriter(fo, list(lignes[0]))
    w.writeheader()
    w.writerows(lignes)
