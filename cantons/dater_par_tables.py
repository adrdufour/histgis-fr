"""Date les mouvements non datés de mouvements_cantonaux.csv par les tables
analytiques du JO (1941-1990).

On ne part pas de l'extraction (tables_jo_actes.csv) mais des mouvements :
pour chaque commune sans date, on cherche dans le texte de chaque table son
nom, à quelques mots avant « canton de <canton d'arrivée> ». La comparaison
est approchée (l'OCR des tables écrit « Tanonnat » pour Taponnat, « Créziôres »
pour Crézières) : le nom doit ressembler à 85 % au moins, et le canton
d'arrivée doit être là, nommé.

Une commune qui change de canton figure dans la table de l'année de l'acte.
L'année trouvée est donc celle de l'acte ; la page renvoie au JO, d'où l'on
tirera la date exacte et la date d'effet.

Sortie : cantons/dates_par_tables_jo.csv
    python3 cantons/dater_par_tables.py      (depuis la racine)
"""
import csv
import difflib
import re
import unicodedata
from collections import defaultdict
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent


def norm(s):
    s = unicodedata.normalize("NFD", s.lower().replace("œ", "oe"))
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    s = re.sub(r"[’']", " ", s)
    s = re.sub(r"\bst\b", "saint", s)
    s = re.sub(r"\bste\b", "sainte", s)
    return re.sub(r"[^a-z0-9]+", " ", s).strip()


# noms de communes
noms = defaultdict(set)
with open(RACINE / "sources/cog/1999/comsimp1999.txt", encoding="latin1") as f:
    for x in csv.DictReader(f, delimiter="\t"):
        noms[x["DEP"] + x["COM"]].add(x["NCCENR"])
for x in csv.DictReader(open(RACINE / "sources/v_mvt_commune_2025.csv", encoding="utf-8")):
    for c, l in ((x["COM_AV"], x["LIBELLE_AV"]), (x["COM_AP"], x["LIBELLE_AP"])):
        if l:
            noms[c].add(l)

# textes des tables, normalisés, une chaîne par année
tables = {}
for a in range(1941, 1991):
    f = RACINE / "jorf_txt" / f"TABLE_ANALYTIQUE_JORF_{a}_col.txt"
    if f.exists():
        t = f.read_text(encoding="utf-8", errors="replace").replace("­", "")
        t = re.sub(r"-\s*\n\s*(?=[a-zà-ÿ])", "", t)
        tables[a] = (norm(t), t)


def canton_cle(s):
    s = re.sub(r"^\S+\s+", "", s.strip())                 # retire le code « 4207 »
    s = re.sub(r"\b\d+\s*(er|e)?\s*canton\b", "", s, flags=re.I)
    k = norm(s)
    k = re.sub(r"^(le|la|les|l) ", "", k)
    return k


# Index : pour chaque année, le mot qui suit « canton de » -> positions.
# Sans lui, chaque mouvement rebalayait cinquante tables entières.
INDEX = {}
for a, (t, _) in tables.items():
    idx = defaultdict(list)
    for m in re.finditer(r"\bcanton (?:de |d |du |des )?(?:la |le |les |l )?([a-z0-9]+)", t):
        idx[m.group(1)].append((m.start(), m.end()))
    INDEX[a] = idx


def cherche(nom_com, canton_arr, annees):
    """[(année, score, page, extrait)] : le canton d'arrivée nommé, la commune juste avant."""
    kc = canton_cle(canton_arr)
    if len(kc) < 3:
        return []
    tete = kc.split()[0]
    nc = norm(nom_com)
    out = []
    for a in annees:
        if a not in tables:
            continue
        t = tables[a][0]
        for d, f in INDEX[a].get(tete, []):
            # le canton nommé doit ressembler au canton d'arrivée EN ENTIER, pas
            # seulement par son premier mot (« Saint-Quentin » n'est pas « Saint-Mandé »)
            apres = re.sub(r"^canton (?:de |d |du |des )?(?:la |le |les |l )?", "", t[d:d + 120])
            if difflib.SequenceMatcher(None, kc, apres[:len(kc)]).ratio() < 0.85:
                continue
            mots = t[max(0, d - 90):d].split()
            best = 0.0
            for i in range(len(mots)):
                for j in range(i + 1, min(len(mots), i + 7) + 1):
                    cand = " ".join(mots[i:j])
                    if abs(len(cand) - len(nc)) > 6:
                        continue
                    best = max(best, difflib.SequenceMatcher(None, nc, cand).ratio())
            if best >= 0.85:
                pg = re.search(r"\bp (\d{2,5})\b", t[f:f + 160])
                out.append((a, round(best, 2), pg.group(1) if pg else "", t[max(0, d - 90):f + 60]))
    return out


mv = list(csv.DictReader(open(RACINE / "cantons/mouvements_cantonaux.csv", encoding="utf-8")))
rows = []
for i, m in enumerate(mv):
    if m["date_retenue"]:
        continue
    deb = int(m["date_debut"][:4]) if m["date_debut"] else 1941
    fin = int(m["date_fin"][:4]) if m["date_fin"] else 1990
    annees = range(max(1941, deb), min(1990, fin) + 1)
    codes = re.findall(r"\b\d[\dAB]\d{3}\b", m["communes"])
    for code in codes:
        for arr in [c for c in re.split(r"[;|]", m["cantons_resultants"]) if c.strip()]:
            # une ville qui donne son nom au canton d'arrivée : ce n'est pas un
            # rattachement de commune, c'est une ville partagée — les tables ne
            # le diront pas sous cette forme
            if any(norm(n) and norm(n) in canton_cle(arr) for n in noms.get(code, [])):
                continue
            hits = []
            for n in noms.get(code, []):
                hits += cherche(n, arr, annees)
            if not hits:
                continue
            ans = sorted({h[0] for h in hits})
            meilleur = max(hits, key=lambda h: h[1])
            rows.append({"ligne_mouvement": i + 2, "dep": m["dep"], "type": m["type"], "commune": code,
                         "nom": " / ".join(sorted(noms.get(code, []))), "canton_source": m["canton_source"],
                         "canton_arrivee": arr.strip(), "annees_table": " ".join(map(str, ans)),
                         "annee": meilleur[0], "page_jo": meilleur[2], "score": meilleur[1],
                         "unique": "oui" if len(ans) == 1 else "non", "extrait": meilleur[3][:220]})

with open(RACINE / "cantons/dates_par_tables_jo.csv", "w", newline="", encoding="utf-8") as fo:
    w = csv.DictWriter(fo, list(rows[0]))
    w.writeheader()
    w.writerows(rows)

import collections  # noqa: E402
nd = [m for m in mv if not m["date_retenue"]]
lignes = {r["ligne_mouvement"] for r in rows}
print("mouvements non datés :", len(nd), "— trouvés dans une table :", len(lignes))
print("par type :", dict(collections.Counter(mv[l - 2]["type"] for l in lignes)))
tr = {i + 2 for i, m in enumerate(mv) if m["type"] == "transfert"}
print("transferts isolés trouvés :", len(lignes & tr), "sur", len(tr),
      "— année unique :", len({r["ligne_mouvement"] for r in rows if r["unique"] == "oui"} & tr))
