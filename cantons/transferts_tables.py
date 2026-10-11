"""Des 97 transferts isolés que les tables du JO datent (dates_par_tables_jo.csv)
à un fichier que 110 sait poser, au format de transferts_complement.csv.

Ce qu'il faut à la règle C, c'est la date de PUBLICATION (effet = lendemain).
La table ne donne que l'année, la page du JO et, le plus souvent, la date du
décret (« … au canton de Villars-les-Dombes. — D. 11 avril 1972, p. 4039 »).
La date de publication se lit dans la pagination : le JO est paginé d'un bout
à l'autre de l'année, et une page ne paraît pas avant le dernier acte signé
qu'elle porte, ni avant ceux des pages qui la précèdent. Pour chaque année, on
relève dans la table tous les couples (date d'acte, page) — quelques milliers
— et la date de parution d'une page est estimée par le plus récent acte signé
aux pages qui la précèdent (ou à elle-même). On en écarte les dates aberrantes
(l'OCR change un mois) : une date qui dépasse de plus de quinze jours la
médiane des cinquante pages suivantes est ignorée.

Contrôle : les actes dont la date de publication est connue par ailleurs
(registre Légifrance, complément lu au JO) et dont la table donne la page.

Sorties :
  cantons/jo_page_date.csv            l'estimateur, contrôlé (écart en jours)
  cantons/transferts_tables_jo.csv    les transferts, prêts pour 110

    python3 cantons/transferts_tables.py     (depuis la racine)
"""
import bisect
import csv
import datetime as dt
import re
import statistics
import sys
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(RACINE / "cantons"))
import tables_jo as tj  # noqa: E402

MOIS = r"(janv|janvier|f[ée]v|f[ée]vr|f[ée]vrier|mars|avr|avril|mai|juin|juil|juill|juillet|ao[ûu]t|sept|septembre|oct|octobre|nov|novembre|d[ée]c|d[ée]cembre)"
ACTE_PAGE = re.compile(r"\b(?:D|Arr|L|O|D[ée]cret|Arr[êe]t[ée])\.?\s*(?:n[°o]\s*)?(?:[\d]{2}-\d{1,4}\s*)?(?:du\s+)?"
                       r"(\d{1,2}|1er)\s*(?:er)?\s+" + MOIS + r"\.?\s+(\d{4})[^p]{0,25}?p\.\s*(\d{1,5})\b", re.I)


def mois(m):
    k = tj.sans_accents(m.lower()).rstrip(".")
    return tj.MOIS.get(k) or tj.MOIS.get(k[:4]) or tj.MOIS.get(k[:3])


def points(annee):
    f = RACINE / "jorf_txt" / f"TABLE_ANALYTIQUE_JORF_{annee}_col.txt"
    if not f.exists():
        return []
    t = tj.nettoie(f.read_text(encoding="utf-8", errors="replace"))
    out = []
    for m in ACTE_PAGE.finditer(t):
        a = int(m.group(3))
        mo = mois(m.group(2))
        j = 1 if m.group(1).lower().startswith("1") and m.group(1).lower() == "1er" else int(m.group(1))
        if a not in (annee, annee - 1) or not mo:
            continue
        try:
            d = dt.date(a, mo, j)
        except ValueError:
            continue
        out.append((int(m.group(4)), d))
    return sorted(out)


class Estimateur:
    def __init__(self, annee):
        pts = points(annee)
        gardes = []
        for i, (p, d) in enumerate(pts):
            suite = [x[1].toordinal() for x in pts[i:i + 50]]
            med = statistics.median(suite) if suite else d.toordinal()
            if d.toordinal() <= med + 15:
                gardes.append((p, d))
        self.pages, self.maxi = [], []
        m = dt.date(annee - 1, 12, 31)
        for p, d in gardes:
            m = max(m, d)
            self.pages.append(p)
            self.maxi.append(m)
        self.annee = annee

    def date(self, page):
        i = bisect.bisect_right(self.pages, page) - 1
        if i < 0:
            return dt.date(self.annee, 1, 1)
        # l'acte signé la veille paraît le lendemain : au plus tôt, maxi + 1
        return min(self.maxi[i] + dt.timedelta(days=1), dt.date(self.annee, 12, 31))


EST = {}


def date_jo(annee, page):
    if annee not in EST:
        EST[annee] = Estimateur(annee)
    return EST[annee].date(page)


def controle():
    """Écart entre la date estimée et la date connue, sur les actes connus."""
    T = list(csv.DictReader(open(RACINE / "cantons/tables_jo_actes.csv", encoding="utf-8")))
    page_de = {}
    for r in T:
        if r["decret"] and r["page_jo"].isdigit():
            page_de[re.sub(r"-0*", "-", r["decret"])] = (int(r["annee"]), int(r["page_jo"]))
    rows = []
    for x in csv.DictReader(open(RACINE / "cantons/decrets_cantonaux.csv", encoding="utf-8")):
        m = re.search(r"(\d{2})\s*-\s*(\d{1,4})", x["decret"] or "")
        if not m or not x["date_publication_jo"]:
            continue
        k = f"{m.group(1)}-{int(m.group(2))}"
        if k in page_de:
            a, p = page_de[k]
            rows.append((a, p, x["date_publication_jo"], x["decret"], "registre"))
    for x in csv.DictReader(open(RACINE / "cantons/decrets_complement.csv", encoding="utf-8")):
        if x["page_jo"].isdigit() and x["date_publication_jo"]:
            rows.append((int(x["date_publication_jo"][:4]), int(x["page_jo"]), x["date_publication_jo"],
                         x["decret"] or x["cle"], "complement"))
    out = []
    for a, p, vrai, quoi, src in rows:
        e = date_jo(a, p)
        out.append({"annee": a, "page_jo": p, "acte": quoi, "source": src, "date_jo_connue": vrai,
                    "date_jo_estimee": e.isoformat(),
                    "ecart_jours": (e - dt.date.fromisoformat(vrai)).days})
    return out


def main():
    ctl = controle()
    with open(RACINE / "cantons/jo_page_date.csv", "w", newline="", encoding="utf-8") as fo:
        w = csv.DictWriter(fo, list(ctl[0]))
        w.writeheader()
        w.writerows(ctl)
    ec = sorted(abs(r["ecart_jours"]) for r in ctl)
    print(f"contrôle de l'estimateur sur {len(ec)} actes : écart médian {statistics.median(ec)} j, "
          f"≤ 2 j : {sum(e <= 2 for e in ec)}, ≤ 7 j : {sum(e <= 7 for e in ec)}, max {ec[-1]} j")

    D = list(csv.DictReader(open(RACINE / "cantons/dates_par_tables_jo.csv", encoding="utf-8")))
    deja = {(r["insee"], r["date"][:4]) for r in
            csv.DictReader(open(RACINE / "cantons/transferts_complement.csv", encoding="utf-8"))}
    out, vus = [], set()
    for r in D:
        if r["type"] != "transfert" or r["unique"] != "oui" or not r["page_jo"].isdigit():
            continue
        cle = (r["commune"], r["annee"])
        if cle in vus:
            continue
        vus.add(cle)
        if cle in deja:
            continue  # déjà lu au JO, déjà dans transferts_complement.csv
        a, p = int(r["annee"]), int(r["page_jo"])
        # la date du décret, quand l'extrait la donne après le canton d'arrivée
        da = ""
        m = re.search(r"\b(?:d|arr)\s+(\d{1,2}|1er)\s+" + MOIS + r"\s+(\d{4})\s+p\s+" + str(p), r["extrait"])
        if m and mois(m.group(2)):
            try:
                da = dt.date(int(m.group(3)), mois(m.group(2)),
                             1 if m.group(1) == "1er" else int(m.group(1))).isoformat()
            except ValueError:
                da = ""
        dj = date_jo(a, p)
        if da and dj.isoformat() < da:
            dj = dt.date.fromisoformat(da) + dt.timedelta(days=1)
        nom = r["nom"].split(" / ")[0]
        out.append({"decret": "", "date": da or dj.isoformat(), "dep": r["dep"], "commune": nom,
                    "insee": r["commune"], "nom_ref": tj.sans_accents(nom).upper(), "appariement": "exact",
                    "canton_source": re.sub(r"^\S+\s+", "", r["canton_source"]),
                    "canton_destination": re.sub(r"^\S+\s+", "", r["canton_arrivee"]),
                    "legifrance_url": "", "jo": f"table analytique {a}, p. {p}",
                    "date_jo": dj.isoformat(),
                    "source": "table analytique du JO ; date de parution estimée par la page ; "
                              "canton de départ = bord gauche de la base (la table ne nomme que l'arrivée)"})
    with open(RACINE / "cantons/transferts_tables_jo.csv", "w", newline="", encoding="utf-8") as fo:
        w = csv.DictWriter(fo, list(out[0]))
        w.writeheader()
        w.writerows(out)
    print(len(out), "transferts écrits dans cantons/transferts_tables_jo.csv ;",
          sum(1 for x in out if x["date"] != x["date_jo"]), "avec la date du décret")


if __name__ == "__main__":
    main()
