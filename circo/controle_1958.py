#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
controle_1958.py — la transcription de 1958 forme-t-elle une partition ?

    python3 circo/controle_1958.py            # tous les départements
    python3 circo/controle_1958.py 59 62      # ceux-là

Lecture seule. Pour chaque département de regles_1958_1986.py, compare les
cantons nommés à ceux que la base porte à la date de l'ordonnance : un nom
sans canton, un canton nommé deux fois, un canton oublié. Les jetons
« commune: », « communes: », « ville: », « reste: », « partie: » désignent
un canton divisé et comptent pour ce canton.
"""
import collections, subprocess, sys, unicodedata
from regles_1958_1986 import REGLES_1958

def cle(s):
    s = unicodedata.normalize("NFD", s.lower().replace("œ", "oe"))
    return "".join(c for c in s if c.isalnum())

def base(dep, date):
    q = ("select distinct u.nom from membership m join unit u using (unit_id) "
         f"where m.niveau='canton' and u.dep='{dep}' and m.periode @> date '{date}'")
    r = subprocess.run(["psql", "-d", "histgis", "-Atc", q], capture_output=True, text=True)
    return [x for x in r.stdout.splitlines() if x]

def trouve(nom, noms):
    k = cle(nom)
    exact = [n for n in noms if cle(n) == k]
    if exact:
        return exact
    return [n for n in noms if cle(n).startswith(k) or k.startswith(cle(n))]

bilan = collections.Counter()
for code, r in sorted(REGLES_1958.items()):
    dep = code[:2].replace("2A", "20").replace("2B", "20")
    if sys.argv[1:] and code not in sys.argv[1:] and dep not in sys.argv[1:]:
        continue
    noms = base(dep, f"{r['depuis']}-12-01" if r["depuis"] == 1958 else f"{r['depuis']}-06-01")
    vus, sans, flous = collections.Counter(), [], []
    for circo, cantons in r["circos"].items():
        for c in cantons:
            if ":" in c:
                genre, _, reste = c.partition(":")
                if genre in ("commune", "partie"):
                    continue
                c = reste.split(":")[0]
                divise = True
            else:
                divise = False
            m = trouve(c.split(" (")[0], noms)
            if not m:
                sans.append(c)
            elif len(m) > 1 and "(" not in c:
                flous.append(f"{c} → {', '.join(sorted(m))}")
            else:
                for n in m:
                    vus[n] += 0 if divise and vus[n] else 1
    oublies = sorted(set(noms) - set(vus))
    doubles = sorted(n for n, k in vus.items() if k > 1)
    etat = "ok" if not (sans or flous or oublies or doubles) else "À VOIR"
    bilan[etat] += 1
    print(f"{code} {r['nom']} — {len(r['circos'])} circ., {len(noms)} cantons en base : {etat}"
          + (" (incomplet)" if r.get("incomplet") else ""))
    for t, l in (("sans canton en base", sans), ("ambigu", flous),
                 ("nommé deux fois", doubles), ("oublié", oublies)):
        if l:
            print(f"    {t} : {'; '.join(l)}")
print(dict(bilan))
