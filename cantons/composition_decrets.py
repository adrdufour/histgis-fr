#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
composition_decrets.py — la composition cantonale, tirée du texte des décrets

    python3 cantons/composition_decrets.py
    python3 cantons/composition_decrets.py --decret 82-77   # un seul décret

Produit `cantons/composition_decrets.csv` — une ligne par (décret, canton,
commune) — et `cantons/composition_non_appariees.csv` pour ce qui résiste.

Pourquoi
--------
Le trou cantonal 1941-1999 a longtemps été tenu pour un mur : les colonnes
structurées de `communes_coupees_1973_1984.csv` sont `canton` /
`commune_coupee`, jamais `canton` / `commune`. Le fichier recense les communes
*coupées*, pas la composition.

Mais la colonne `texte` porte le texte intégral du JO, et ce texte dit la
composition, en prose :

    « Canton de Bourg-Est comprenant les communes de Montagnat et Saint-Just
      ainsi que la portion de territoire de la ville de Bourg-en-Bresse
      délimitée, au Nord, par les limites communales de Viriat… »

C'est exactement l'état dans lequel était le recensement de 1954 avant qu'on
ne l'extraie. Sur les 579 lignes, **289 portent cette formule, couvrant 91 des
117 décrets**.

Ce que ce script ne fait pas
---------------------------
Il ne comble pas le trou à lui seul, et il ne le prétend pas. Un décret donne
la composition des cantons **qu'il crée ou modifie**, pas celle des 4 000
autres. Ce qui rend la chose exploitable est ailleurs : la base n'a pas besoin
de la composition à chaque date, elle a besoin d'une **base de départ et des
deltas**. 1940 est posé, 1954 est extrait, 1999 vient du COG. Les décrets sont
les deltas entre les deux.

Il ne pose rien en base non plus. Il produit un CSV à relire.

La difficulté réelle : l'OCR
----------------------------
Les noms sortent abîmés — « Saint-Denislès-Bourg » sans tiret, « Puy- Saint-
André » avec une espace après le tiret, « Oycnnax » pour Oyonnax, « les1
communes ». Le script distingue donc trois qualités d'appariement et les
compte séparément :

  exact         le nom normalisé tombe sur un nom de GEOFLA du département
  disparue      il tombe sur un `libelle_av` d'`insee_mvt` — une commune qui
                existait au décret et a fondu avant 2011
  ressemblance  il en approche à 0,88 ou mieux (difflib), du même département
  aucun         à relire à la main

Le troisième dictionnaire n'était pas prévu. Il s'est imposé en regardant les
88 noms rejetés au premier passage : « Campet », « Lucbardez », « Louzac »,
« Ferreux ». On les prend d'abord pour des coupures fautives de noms à
rallonge — Campet-et-Lamolère, Louzac-Saint-André. Le texte du JO dit
exactement « Campet » et « Louzac » : ce sont les vrais noms de 1982, et ce
sont les fusions postérieures qui ont produit les noms longs.

Le parseur n'était donc pas en cause, le dictionnaire l'était. GEOFLA 2011 ne
connaît que les communes survivantes. C'est le même défaut qui laisse 7 576
noms non appariés dans l'extraction de 1954, et le même correctif y répond :
`insee_mvt.libelle_av`, 7 668 libellés d'avant mouvement.

**Le taux d'appariement n'est pas un taux d'exactitude.** Un nom bien apparié
dans le mauvais canton reste une erreur, et rien ici ne la verrait. C'est ce
que le contrôle indépendant devra dire, en confrontant au COG de 1999 les
cantons qui ont survécu — la seule source qui ne vienne pas des décrets.
"""

import argparse
import collections
import csv
import difflib
import re
import sys
import unicodedata
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
SOURCE = RACINE / "cantons" / "communes_coupees_1973_1984.csv"
NOMS = RACINE / "build" / "noms_geofla.csv"
MVT = RACINE / "sources" / "v_mvt_commune_2025.csv"
SORTIE = RACINE / "cantons" / "composition_decrets.csv"
RESTE = RACINE / "cantons" / "composition_non_appariees.csv"

# Seuil de ressemblance. Choisi avant de mesurer, et non ajusté ensuite : le
# régler sur le résultat reviendrait à fabriquer le taux qu'on veut lire.
SEUIL = 0.88

# ---------------------------------------------------------------------------
# L'amorce de composition. Six formes rencontrées dans les 579 lignes, plus
# quelques accidents d'OCR (« les1 communes », « la commune associée de »).
# On accepte largement ici : une amorce ratée coûte une ligne perdue, une
# amorce trop lâche coûte du bruit qu'on verra à l'appariement.
AMORCE = re.compile(
    r"comprenant\s+"
    r"(?:l(?:es?|a|')\s*\d?\s*"
    r"(?:anciennes?\s+|nouvelles?\s+)?communes?"
    r"(?:\s+associ[ée]es?)?)\s*"
    r"(?:de\s+|d[’']|du\s+|des\s+)",
    re.I)

# Ce qui ferme la liste. « et la portion » doit être reconnu AVANT qu'on ne
# découpe sur « et », sans quoi « portion » devient un nom de commune.
# `ainsi\s*qu` et non `ainsi\s+qu` : l'OCR soude « ainsi que » une fois sur
# deux, et le mot collé emportait le nom qui précède —
# « Saint-Denislès-Bourg ainsique » au lieu de « Saint-Denis-lès-Bourg ».
FIN = re.compile(
    r",?\s*(?:ainsi\s*qu|et\s+(?:l[ae]s?\s+)?(?:portions?|partie)"
    r"|,?\s*(?:l[ae]s?\s+)?portions?\s+de\s+territoire"
    r"|\.\s|\s;|$)",
    re.I)

# Découpage de la liste : virgules et « et ». Le « et » final d'une
# énumération française n'est pas une virgule, mais il joue le même rôle.
SEPARE = re.compile(r"\s*,\s*|\s+et\s+", re.I)


def cle(s):
    """Normalisation pour comparer deux noms de commune.

    Mêmes principes que partout dans le projet : sans accents, sans casse,
    sans ponctuation. On y ajoute le recollage des mots coupés par l'OCR —
    « Puy- Saint-André » et « PuySaint-Andre » doivent donner la même clé,
    sans quoi la moitié des noms tombe à côté pour une espace.
    """
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    return re.sub(r"[^a-z0-9]", "", s.lower())


def noms_par_departement():
    """{dep: {clé: (insee, nom)}} — les communes vivantes en 2011.

    Restreint au département : « Saint-Just » existe dans une dizaine de
    départements, et un appariement national en choisirait un au hasard.
    Mesuré : sans cette contrainte, « Saint-Hilaire » cité par un décret de
    l'Aube s'apparie à un code de Charente.
    """
    d = collections.defaultdict(dict)
    with NOMS.open(encoding="utf-8") as f:
        for l in csv.DictReader(f):
            d[l["dep"]][cle(l["nom"])] = (l["insee"], l["nom"])
    return d


def _dep(com):
    """Le département d'un code commune. 971-978 tiennent sur trois chiffres."""
    return com[:3] if com[:2] in ("97", "98") else com[:2]


def communes_disparues():
    """{dep: {clé: (code, libellé)}} — les communes mortes avant 2011.

    `insee_mvt` recense les mouvements communaux : fusions, scissions,
    changements de nom. Sa colonne `libelle_av` porte le nom d'AVANT, donc
    précisément ce que GEOFLA ne peut pas connaître.

    On garde le premier mouvement rencontré pour un nom donné. Une commune
    fusionnée puis refondue en porte plusieurs ; le premier est le plus proche
    de l'état où les décrets la nomment.
    """
    d = collections.defaultdict(dict)
    if not MVT.exists():
        print(f"  (dictionnaire des disparues absent : {MVT.name})")
        return d
    with MVT.open(encoding="utf-8") as f:
        for l in csv.DictReader(f):
            av, com = l.get("LIBELLE_AV"), l.get("COM_AV")
            if av and com:
                d[_dep(com)].setdefault(cle(av), (com, av))
    return d


def liste_communes(texte):
    """Le texte d'un article -> les noms de communes entières qu'il cite.

    Rend une liste vide quand le canton n'est fait que de fractions de ville,
    ce qui est le cas de 269 lignes sur 579 : « comprenant la portion de
    territoire de la ville de Nîmes déterminée… ». Ce vide est un résultat,
    pas un échec.
    """
    m = AMORCE.search(texte or "")
    if not m:
        return []
    reste = texte[m.end():]
    f = FIN.search(reste)
    segment = reste[:f.start()] if f else reste
    # Une liste qui s'étire sur plus de 400 caractères n'est plus une liste :
    # l'amorce est tombée sur autre chose, ou la fin n'a pas été vue.
    if len(segment) > 400:
        return []
    out = []
    for n in SEPARE.split(segment):
        n = n.strip(" .;:'’ ")
        n = re.sub(r"\s*-\s*", "-", n)      # « Puy- Saint-André »
        n = re.sub(r"\s+", " ", n)
        if 2 < len(n) < 45 and re.match(r"[A-ZÀ-Ÿ]", n):
            out.append(n)
    return out


def apparie(nom, dico, morts):
    """(code, libellé, qualité) — exact, disparue, ressemblance, ou rien.

    L'ordre compte. Une commune vivante l'emporte sur une commune morte de
    même nom : le décret parle d'un territoire qui existe encore, sauf preuve
    du contraire. La ressemblance vient en dernier — c'est la seule des trois
    qui puisse se tromper sans le dire.
    """
    k = cle(nom)
    if k in dico:
        i, n = dico[k]
        return i, n, "exact"
    if k in morts:
        i, n = morts[k]
        return i, n, "disparue"
    proches = difflib.get_close_matches(k, dico.keys(), n=1, cutoff=SEUIL)
    if proches:
        i, n = dico[proches[0]]
        return i, n, "ressemblance"
    return "", "", "aucun"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--decret", help="ne traiter qu'un décret, ex. 82-77")
    a = ap.parse_args()

    dico = noms_par_departement()
    morts = communes_disparues()
    lignes = list(csv.DictReader(SOURCE.open(encoding="utf-8")))
    if a.decret:
        lignes = [l for l in lignes if a.decret in (l["decret"] or "")]
        if not lignes:
            sys.exit(f"Aucune ligne pour le décret {a.decret}.")

    out, rate = [], []
    q = collections.Counter()
    cantons_servis = set()
    for l in lignes:
        dep = (l["dep_code"] or "").strip()
        noms = liste_communes(l["texte"])
        if noms:
            cantons_servis.add((l["decret"], l["canton"]))
        for n in noms:
            insee, geofla, qual = apparie(n, dico.get(dep, {}),
                                          morts.get(dep, {}))
            q[qual] += 1
            r = dict(decret=l["decret"], date=l["date_signature"], dep=dep,
                     canton=l["canton"], nom_texte=n, insee=insee,
                     nom_geofla=geofla, appariement=qual,
                     ville_coupee=l["commune_coupee"], jo=l["jo"])
            out.append(r)
            if qual == "aucun":
                rate.append(r)

    if not out:
        sys.exit("Aucune composition extraite.")
    with SORTIE.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(out[0]))
        w.writeheader(); w.writerows(out)
    if rate:
        with RESTE.open("w", newline="", encoding="utf-8") as f:
            w = csv.DictWriter(f, fieldnames=list(rate[0]))
            w.writeheader(); w.writerows(rate)

    tot = sum(q.values())
    print(f"{len(lignes)} lignes lues, "
          f"{len({l['decret'] for l in lignes})} décrets")
    print(f"{len(cantons_servis)} cantons pourvus d'une composition\n")
    print(f"{tot} rattachements de commune entière extraits")
    for k in ("exact", "disparue", "ressemblance", "aucun"):
        print(f"   {k:14s} {q[k]:5d}   {100*q[k]/tot:5.1f} %")
    print(f"\n{SORTIE}")
    if rate:
        print(f"{RESTE}   ({len(rate)} à relire)")
    print("\nUn taux d'appariement n'est pas un taux d'exactitude : un nom "
          "bien apparié\ndans le mauvais canton reste une erreur, et rien "
          "ici ne la verrait.")


if __name__ == "__main__":
    main()
