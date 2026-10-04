#!/usr/bin/env python3
"""transferts_insee.py — les changements de canton DATÉS par l'INSEE

    python3 cantons/transferts_insee.py

Produit `cantons/transferts_insee.csv`.

POURQUOI CE FICHIER, ALORS QU'ON AVAIT DÉJÀ CINQ TRANSFERTS
===========================================================
`cantons/transferts_legifrance.csv` porte **cinq** mouvements isolés de
commune, tirés du texte des décrets. `73` § 5 avait vérifié que la place était
libre pour les cinq, et il ne manquait que la date d'effet.

Le fichier historique du COG 1999 — `sources/cog/1999/Corhistoriq1999.txt`,
modalité **43, « changement de canton »** — en porte **soixante-six**, et il
donne pour chacun :

    * la date de l'acte (colonne LEG),
    * la date de publication au JO (colonne JO),
    * **la date d'EFFET** (colonne EFF),
    * et le canton d'arrivée, CODÉ (colonne CT), pas nommé.

C'est-à-dire exactement ce qui manquait, et pour treize fois plus de communes.

Le dépôt savait que ce fichier existait — `ETAT.md` note depuis le 9 août qu'il
ne contient que 66 changements de canton, tous entre 1995 et 1998, et en tire
qu'aucune reconstitution 1943-1995 n'est possible par cette voie. C'était vrai
et cela n'épuisait pas la question : *une source trop pauvre pour combler un
trou peut être exactement assez riche pour dater ce qu'on a déjà.*

CE QUE LES DATES DISENT, ET QUI DÉMENT UNE CONVENTION
=====================================================
    Saint-Denis-des-Puits, Villebon (28)
        décret du 10 avril 1995, JO du 15, EFFET LE 16 — le lendemain.
    Saint-Alban-de-Roche (38) et 60 autres
        décret du 26 février 1997, JO du 27, EFFET LE 1er AVRIL 1998.

Ni l'une ni l'autre n'est le premier tour du renouvellement, qui est la
convention de `75` et `76`. Et les deux ne suivent pas la même règle.

L'explication tient à la nature des actes, et elle est rassurante pour `75` :

    * un REDÉCOUPAGE crée ou modifie des cantons — la carte doit exister au
      scrutin QUI ÉLIT, donc au premier tour. C'est la convention de `75`.
    * un simple RATTACHEMENT de commune ne demande pas d'élection. Il prend
      effet quand l'acte le dit : le lendemain de sa publication en 1995, à
      l'installation du nouveau conseil (1er avril 1998) pour la salve de 1997,
      dont le décret annonçait précisément l'effet « pour le prochain
      renouvellement ».

*Deux règles différentes parce que les actes sont de nature différente* — et
non parce que l'une aurait été mal choisie.

LIMITE
======
Le fichier ne remonte pas avant 1994 : la documentation de l'INSEE dit que les
changements d'appartenance à un échelon supracommunal n'y sont répertoriés que
depuis cette date, et les données le confirment (aucune modalité 43 avant le
16 avril 1995). Les deux transferts de janvier 1993 connus par Légifrance
restent donc sans date d'effet certaine : c'est `77` qui les traite, à part et
sous convention déclarée.
"""

import csv
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
SOURCE = RACINE / "sources" / "cog" / "1999" / "Corhistoriq1999.txt"
SORTIE = RACINE / "cantons" / "transferts_insee.csv"

MOD_CHANGEMENT_CANTON = "43"


def jour(d):
    """« 16-04-1995 » -> « 1995-04-16 ». Vide si la case l'est."""
    d = (d or "").strip()
    if len(d) != 10:
        return ""
    j, m, a = d.split("-")
    return f"{a}-{m}-{j}"


def main():
    if not SOURCE.exists():
        print(f"source absente : {SOURCE}")
        return 1

    with SOURCE.open(encoding="latin-1") as f:
        r = csv.reader(f, delimiter="\t")
        next(r)
        lignes = [x for x in r if len(x) > 20 and x[8] == MOD_CHANGEMENT_CANTON]

    out = []
    for x in lignes:
        dep, canton, com = x[0].strip(), x[2].strip(), x[3].strip()
        # `unit_id` d'un canton est 'DDNN' — département puis numéro sur deux
        # chiffres. Vérifié sur les trois communes que Légifrance donne aussi :
        # 28+12 = 2812 (Courville-sur-Eure) et 38+04 = 3804
        # (Bourgoin-Jallieu - Sud), les deux confirmés par `73` § 5.
        out.append(dict(
            dep=dep,
            insee=dep + com,
            commune=x[20].strip(),
            canton_arrivee=dep + canton.zfill(2),
            date_acte=jour(x[4].lstrip("ADL")),
            date_jo=jour(x[5]),
            date_effet=jour(x[6]),
        ))

    out.sort(key=lambda d: (d["date_effet"], d["dep"], d["insee"]))
    with SORTIE.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(out[0].keys()))
        w.writeheader()
        w.writerows(out)

    print(f"{len(out)} changements de canton datés -> {SORTIE.name}")
    print(f"   communes distinctes : {len({d['insee'] for d in out})}")
    print(f"   cantons d'arrivée   : {len({d['canton_arrivee'] for d in out})}")
    print(f"   départements        : {len({d['dep'] for d in out})}")
    print("\npar date d'effet :")
    from collections import Counter
    for d, n in sorted(Counter(d["date_effet"] for d in out).items()):
        deps = sorted({x["dep"] for x in out if x["date_effet"] == d})
        print(f"   {d}  {n:>3} communes   dép. {' '.join(deps)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
