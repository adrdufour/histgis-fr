#!/usr/bin/env python3
"""essai_ligne_souple.py — le couple arrondissement/canton, lu plus souplement.

    python3 archives/essais/essai_ligne_souple.py                  # 01, 09, 39, 70
    python3 archives/essais/essai_ligne_souple.py --deps 01,02,03
    python3 archives/essais/essai_ligne_souple.py --tous
    python3 archives/essais/essai_ligne_souple.py --deps 01 --montre 40

LECTURE SEULE. N'écrit aucun fichier, ne touche ni au CSV ni à la base.

CE QU'IL MESURE, ET POURQUOI
============================
`94` a montré que la lacune de 1954 n'est ni un défaut de scan ni un défaut
d'OCR : sur le corps du volume, le brut de `ocr_brut/` porte 41 996 lignes à
trois chiffres ou plus et l'extraction en retient 31 369 — **74,7 %**. Les pages
ont été lues ; un quart de leurs lignes est tombé à l'analyse. C'est pourquoi la
perte est uniforme d'un département à l'autre : chaque page en perd une part
comparable.

Ce qui casse est le couple `arrondissement canton`. `LIGNE` exige un blanc entre
les deux — `([\\dOoSlIi]{1,2})\\s+([\\dOoSlIi]{1,2})` — et le scan rend :

    1 28  ->  128        Arandas, Argis
    2 02  ->  2:02       Asnières-sur-Saône
    1 31  ->  1: 31      Anglefort

**Le seul changement essayé ici est ce séparateur** : il devient facultatif et
admet la ponctuation. Tout le reste de `LIGNE` — les sosies de chiffres, les
séparateurs de colonnes, le renvoi de note, l'exigence de trois nombres après le
nom — est repris tel quel, par substitution textuelle dans `LIGNE.pattern`.
*Changer une chose à la fois est ce qui permet d'attribuer le résultat.*

LE CONTRÔLE PRÉALABLE, QUI COMMANDE TOUT LE RESTE (§ 0)
=======================================================
Avant de mesurer un gain, le fichier vérifie que la règle ACTUELLE, rejouée sur
`ocr_brut/`, retrouve bien les lignes du CSV. Si elle ne les retrouvait pas, la
comparaison porterait sur autre chose que l'extraction réelle et le gain serait
un artefact. Mesuré le 6 septembre 2026 sur tout le corps : **31 272 retrouvées,
0 en trop**. *Un banc qui ne reproduit pas l'existant ne mesure pas sa
modification.*

DEUX ARBITRES, ET AUCUN N'EST LA RÈGLE ELLE-MÊME
================================================
Une lecture plus permissive gagne des lignes ET peut en inventer. Le gain brut
ne veut donc rien dire seul. Deux arbitres, indépendants du séparateur :

  1. **Le canton est-il attesté dans ce département ?** Les codes retenus au
     moins deux fois parmi les lignes DÉJÀ lues font la nomenclature de fait —
     2 900 codes sur 90 départements. Un canton inconnu du département est un
     mauvais découpage des chiffres.
  2. **Le nom tombe-t-il à sa place alphabétique ?** Le volume imprime les
     communes dans l'ordre, département par département. Une ligne récupérée
     doit se ranger entre la commune lue juste avant elle et celle lue juste
     après, sur la même page. Cet arbitre-là ne connaît ni les cantons ni les
     noms de communes : il ne juge que la POSITION, et c'est ce qui le rend
     indépendant du premier.

CE QUE CE FICHIER NE PEUT PAS DIRE
==================================
Il ne dit rien du taux d'accord de `93` § 4 bis — **98,78 % sur 26 544
comparables** —, qui est le contrôle qui compte vraiment et qui exige la base.
La recette du correctif est en DEUX termes, et le second commande : la
couverture doit monter depuis 79,0 %, **et cet accord ne doit pas baisser**.
*Un parseur plus permissif qui gagne de la couverture en perdant de l'accord
achète du volume avec des erreurs, et rien d'autre ne le dirait.*

Chaîne pour le vérifier, après le correctif : `extrait_1954.py`, puis `65`-`69`,
puis `93` (rejouable seul), puis `94` § 5.
"""
import argparse
import collections
import csv
import importlib.util
import re
import sys
import unicodedata
from pathlib import Path

ICI = Path(__file__).resolve().parents[2] / "cog1954"
BRUT = ICI / "ocr_brut"
CSV = ICI / "communes_1954_redecoupe.csv"
CORPS = range(83, 889)          # hors liminaires (15-82) et annexes (892-935)


def charge_regles():
    """Importe `LIGNE`, `NOMENCLATURE`, `RENVOI`, `TOTAUX` du vrai extracteur.

    On ne recopie pas la règle : on la prend là où elle vit. Une copie
    divergerait un jour et rien ne le dirait.
    """
    spec = importlib.util.spec_from_file_location("e54", ICI / "extrait_1954.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def regle_souple(ligne):
    """`LIGNE` avec le SEUL séparateur arr/canton relâché.

    `\\s+` devient `[\\s:;.,]*`, et le premier groupe passe en NON GOURMAND pour
    que « 128 » se lise « 1 » + « 28 » et non « 12 » + « 8 » : l'arrondissement
    tient sur un chiffre dans l'immense majorité des départements, le canton sur
    deux. Sans cela le moteur découperait au mauvais endroit et l'arbitre du
    canton refuserait tout — on aurait mesuré une regex, pas une hypothèse.
    """
    avant = r"([\dOoSlIi]{1,2})\s+([\dOoSlIi]{1,2})"
    apres = r"([\dOoSlIi]{1,2}?)[\s:;.,]*([\dOoSlIi]{1,2})"
    if avant not in ligne.pattern:
        sys.exit("La tête de `LIGNE` a changé dans extrait_1954.py : "
                 "ce fichier ne sait plus quoi remplacer, et il vaut mieux "
                 "qu'il s'arrête que qu'il mesure autre chose.")
    return re.compile(ligne.pattern.replace(avant, apres, 1))


def cle(nom):
    """Clé de comparaison alphabétique : sans accents, sans ponctuation."""
    s = unicodedata.normalize("NFD", nom.lower())
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    return re.sub(r"[^a-z]", "", s)


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--deps", default="01,09,39,70",
                    help="départements à mesurer (défaut : 01,09,39,70 — l'Ain "
                         "pour comparer au connu, les trois plus touchés)")
    ap.add_argument("--tous", action="store_true", help="tout le volume")
    ap.add_argument("--montre", type=int, default=12,
                    help="nombre de lignes récupérées à afficher")
    args = ap.parse_args()

    mod = charge_regles()
    LIGNE, SOUPLE = mod.LIGNE, regle_souple(mod.LIGNE)
    NOMENCL, RENVOI, TOTAUX = mod.NOMENCLATURE, mod.RENVOI, mod.TOTAUX

    # --- la matière : le CSV, pour savoir ce qui est déjà lu et où ----------
    lignes_csv = collections.defaultdict(set)      # page -> {ligne_brute[:40]}
    page_dep = {}
    vus = collections.defaultdict(collections.Counter)   # dep -> {canton: n}
    noms_page = collections.defaultdict(list)      # page -> [nom, ...] dans l'ordre
    for r in csv.DictReader(open(CSV)):
        p = int(r["page"])
        lignes_csv[p].add(r["ligne_brute"].strip()[:40])
        if r["dep"]:
            page_dep.setdefault(p, collections.Counter())[r["dep"]] += 1
            if r["canton"].strip().isdigit():
                vus[r["dep"]][int(r["canton"])] += 1
            noms_page[p].append(r["commune"])
    page_dep = {p: c.most_common(1)[0][0] for p, c in page_dep.items()}
    atteste = {d: {k for k, n in c.items() if n >= 2} for d, c in vus.items()}

    deps = None if args.tous else set(args.deps.split(","))
    pages = [p for p in CORPS if (BRUT / f"p{p:04d}.txt").exists()
             and (deps is None or page_dep.get(p) in deps)]
    if not pages:
        sys.exit("Aucune page pour ces départements. Vus : "
                 + ",".join(sorted(set(page_dep.values()))))

    # --- § 0. la règle actuelle reproduit-elle le CSV ? ---------------------
    repro = manque = trop = 0
    brut_page = {}
    for p in pages:
        L = [l.rstrip() for l in open(BRUT / f"p{p:04d}.txt", errors="replace")]
        brut_page[p] = L
        strict = set()
        for l in L:
            s = l.strip()
            if not s or RENVOI.search(s) or TOTAUX.search(s):
                continue
            if LIGNE.search(s) and not NOMENCL.search(s):
                strict.add(s[:40])
        repro += len(strict & lignes_csv[p])
        manque += len(lignes_csv[p] - strict)
        trop += len(strict - lignes_csv[p])

    print("=" * 66)
    print(" § 0. LA RÈGLE ACTUELLE, REJOUÉE SUR LE BRUT")
    print("=" * 66)
    print(f"  retrouvées dans le CSV     {repro:6d}")
    print(f"  du CSV non retrouvées      {manque:6d}   (correctifs postérieurs)")
    print(f"  en trop                    {trop:6d}   doit valoir 0")
    if trop or repro == 0:
        sys.exit("\n  La reproduction échoue : tout gain mesuré ensuite serait "
                 "un artefact.\n  On s'arrête ici.")
    print("\n  Reproduction acquise — la mesure qui suit porte sur la vraie règle.")

    # --- §§ 1-2. le gain, et les deux arbitres -----------------------------
    c = collections.Counter()
    par_dep = collections.defaultdict(collections.Counter)
    montre = []
    for p in pages:
        dep = page_dep.get(p)
        deja = lignes_csv[p]
        # position des lignes déjà lues, pour l'arbitre alphabétique
        rang_lu = [(i, noms_page[p][k]) for k, (i, s) in enumerate(
            [(i, l.strip()[:40]) for i, l in enumerate(brut_page[p])
             if l.strip()[:40] in deja][:len(noms_page[p])])]
        for i, l in enumerate(brut_page[p]):
            s = l.strip()
            if not s or s[:40] in deja:
                continue
            if RENVOI.search(s) or TOTAUX.search(s) or NOMENCL.search(s):
                continue
            if LIGNE.search(s):
                continue                      # la règle actuelle la prend déjà
            m = SOUPLE.search(s)
            if not m:
                c["hors d'atteinte même relâchée"] += 1
                continue
            arr, ct, nom = m.group(1), m.group(2), m.group(3)
            try:
                ct = int(str(ct).translate(mod.SOSIES))
            except ValueError:
                c["canton illisible"] += 1
                continue
            c["gagnée par la règle relâchée"] += 1
            par_dep[dep]["gain brut"] += 1

            ok_canton = dep in atteste and ct in atteste[dep]
            # arbitre alphabétique : entre le nom lu juste avant et juste après
            avant = max((n for j, n in rang_lu if j < i), default=None,
                        key=lambda x: 0) if rang_lu else None
            av = [n for j, n in rang_lu if j < i]
            ap_ = [n for j, n in rang_lu if j > i]
            k = cle(nom)
            ok_ordre = True
            if av and ap_:
                ok_ordre = cle(av[-1]) <= k <= cle(ap_[0])
            elif av:
                ok_ordre = cle(av[-1]) <= k
            elif ap_:
                ok_ordre = k <= cle(ap_[0])

            if ok_canton and ok_ordre:
                c["  les DEUX arbitres d'accord"] += 1
                par_dep[dep]["retenue"] += 1
                if len(montre) < args.montre:
                    montre.append(f"{dep} arr {arr} ct {ct:02d}  {nom[:24]:24} | {s[:52]}")
            elif ok_canton:
                c["  canton oui, ordre alphabétique NON"] += 1
                par_dep[dep]["ordre non"] += 1
            elif ok_ordre:
                c["  ordre oui, canton INCONNU du département"] += 1
                par_dep[dep]["canton non"] += 1
            else:
                c["  les deux arbitres refusent"] += 1
                par_dep[dep]["refusée"] += 1

    print()
    print("=" * 66)
    print(" §§ 1-2. CE QUE LA RÈGLE RELÂCHÉE GAGNE, ET CE QUE LES ARBITRES EN DISENT")
    print("=" * 66)
    for k in ["gagnée par la règle relâchée", "  les DEUX arbitres d'accord",
              "  canton oui, ordre alphabétique NON",
              "  ordre oui, canton INCONNU du département",
              "  les deux arbitres refusent", "canton illisible",
              "hors d'atteinte même relâchée"]:
        if c[k]:
            print(f"  {c[k]:6d}  {k}")

    lu = sum(len(lignes_csv[p]) for p in pages)
    ret = c["  les DEUX arbitres d'accord"]
    print(f"\n  lignes déjà lues sur ces pages      {lu:6d}")
    print(f"  retenues en plus par les arbitres   {ret:6d}   "
          f"soit +{100*ret/lu:.1f} %")

    print()
    print(" par département — 'retenue' est le gain net")
    print(f"  {'dep':>4} {'lu':>7} {'gain brut':>10} {'retenue':>8} "
          f"{'ordre non':>10} {'canton non':>11} {'refusée':>8}")
    for d in sorted(par_dep):
        n = sum(len(lignes_csv[p]) for p in pages if page_dep.get(p) == d)
        x = par_dep[d]
        print(f"  {d:>4} {n:7d} {x['gain brut']:10d} {x['retenue']:8d} "
              f"{x['ordre non']:10d} {x['canton non']:11d} {x['refusée']:8d}")

    if montre:
        print("\n lignes récupérées, les deux arbitres d'accord :")
        for e in montre:
            print("   ", e)

    print()
    print("=" * 66)
    print(" Rien n'a été écrit. Le contrôle qui manque — et qui commande — est")
    print(" le taux d'accord de `93` § 4 bis, 98,78 % sur 26 544 comparables :")
    print(" il exige la base, et il ne doit PAS baisser quand la couverture")
    print(" monte. Chaîne : extrait_1954.py, puis 65-69, puis 93, puis 94 § 5.")
    print("=" * 66)


if __name__ == "__main__":
    main()
