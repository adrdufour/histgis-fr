"""Les rattachements des tables du JO que `transferts_tables.py` n'a pas pris,
parce que la base n'avait AUCUN canton pour la commune à cette date.

`transferts_tables.py` ne convertit que les transferts de
`dates_par_tables_jo.csv`, c'est-à-dire ceux qu'il a pu rapprocher d'un
changement de canton DÉJÀ visible en base (bord gauche → bord droit). Une
commune dans un trou n'a pas de bord gauche à la date : son transfert restait
lu, mais jamais posé. Missy-aux-Bois (02) en est l'exemple signalé par Adrien
le 27 octobre 2026 : « Missy-aux-Bois au canton de Soissons (Aisne),
p. 10456 » dans la table de 1950, et aucun canton de 1941 à 1968 en base — sa
place était dessinée par Saconin-et-Breuil, le voisin, au titre du comblement.

Ici : toute ligne « rattachement » de `tables_jo_actes.csv` qui porte une
commune, un canton et un département ; la commune est appariée dans son
département par `apparie()` de `composition_jo.py` (jamais le repli national) ;
la date de parution est estimée par la page, comme dans `transferts_tables.py`,
et jamais antérieure au lendemain du décret quand la table le date. Les lignes
déjà dans `transferts_tables_jo.csv` ou `transferts_complement.csv` (même
commune, même année) sont écartées.

Sortie : `cantons/transferts_tables_trous.csv`, au format de
`transferts_complement.csv` — lu par `sql/137_trous_par_l_acte.sql`.

    python3 cantons/transferts_tables_trous.py     (depuis la racine)
"""
import csv
import datetime as dt
import re
import sys
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(RACINE / "cantons"))
from composition_jo import apparie, communes_disparues, noms_par_departement  # noqa: E402
from transferts_tables import date_jo  # noqa: E402
import tables_jo as tj  # noqa: E402

SORTIE = RACINE / "cantons" / "transferts_tables_trous.csv"


def main():
    vivantes = noms_par_departement()
    disparues = communes_disparues()
    deja = set()
    for f in ("transferts_tables_jo.csv", "transferts_complement.csv"):
        for r in csv.DictReader(open(RACINE / "cantons" / f, encoding="utf-8")):
            deja.add((r["insee"], r["date"][:4]))

    out, refus = [], []
    for r in csv.DictReader(open(RACINE / "cantons/tables_jo_actes.csv", encoding="utf-8")):
        if r["nature"] != "rattachement" or not (r["commune"] and r["canton"] and r["dep"]):
            continue
        if not r["page_jo"].isdigit():
            continue
        dep = r["dep"].zfill(2)
        a, p = int(r["annee"]), int(r["page_jo"])
        dj = date_jo(a, p)
        if r["date_acte"] and dj.isoformat() <= r["date_acte"]:
            dj = dt.date.fromisoformat(r["date_acte"]) + dt.timedelta(days=1)
        # « Maubec et Meyrie », « Trilbardou et de Vignely » : deux communes
        # rattachées par le même acte
        for nom in re.split(r"\s+et\s+(?:de\s+)?", r["commune"]):
            insee, ref, q = apparie(nom, dep, vivantes, disparues)
            if not insee or q in ("autre departement", "prefixe ambigu"):
                refus.append((r["annee"], dep, nom, q))
                continue
            if (insee, r["annee"]) in deja:
                continue
            out.append({"decret": r["decret"], "date": r["date_acte"] or dj.isoformat(), "dep": dep,
                        "commune": nom, "insee": insee, "nom_ref": ref, "appariement": q,
                        "canton_source": "", "canton_destination": r["canton"],
                        "legifrance_url": "", "jo": f"table analytique {a}, p. {p}",
                        "date_jo": dj.isoformat(),
                        "source": "table analytique du JO ; date de parution estimée par la page ; "
                                  "commune sans canton en base à la date (transferts_tables_trous.py)"})
    with open(SORTIE, "w", newline="", encoding="utf-8") as fo:
        w = csv.DictWriter(fo, list(out[0]))
        w.writeheader()
        w.writerows(out)
    print(len(out), "rattachements écrits dans", SORTIE.relative_to(RACINE), ";",
          len(refus), "non appariés :")
    for x in refus:
        print("  ", *x)


if __name__ == "__main__":
    main()
