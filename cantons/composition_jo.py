#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
composition_jo.py — la composition cantonale, tirée du texte des JO numérisés

    python3 cantons/composition_jo.py
    python3 cantons/composition_jo.py --jo JORF_19670722_169

Produit `cantons/composition_jo.csv` — une ligne par (décret, canton, commune) —
et `cantons/composition_jo_non_appariees.csv` pour ce qui résiste.

Pourquoi un second extracteur
-----------------------------
`composition_decrets.py` lit la colonne `texte` de
`communes_coupees_1973_1984.csv`, c'est-à-dire les seuls segments qu'un premier
passage avait retenus parce qu'ils portaient une **commune coupée**. C'était le
bon chemin quand on cherchait les villes partagées ; c'est le mauvais quand on
cherche la composition, parce qu'un canton sans commune coupée — la grande
majorité — n'entre jamais dans le fichier.

Ici on repart du texte du JO. Le segment « Canton de X comprenant les communes
de A, B et C » est auto-suffisant : il porte son nom de canton et sa liste. On
les prend tous.

Ce que ce script ne fait pas
---------------------------
Il ne pose rien en base. Il ne dit pas la composition des cantons que le décret
ne touche pas. Et le taux d'appariement n'est toujours pas un taux d'exactitude :
un nom bien apparié dans le mauvais canton reste une erreur, et rien ici ne la
voit. C'est au contrôle indépendant de le dire.

Le découpage en colonnes — CORRIGÉ le 28 août 2026
--------------------------------------------------
On lisait `*_raw.txt` en croyant qu'il suivait l'ordre de lecture des colonnes.
**C'était faux.** `_raw.txt` découpe les lignes fondues par `-layout`, il ne
sépare pas les colonnes : le JO est sur deux colonnes, et le contenu d'un
décret y paraît AVANT son propre en-tête. Sur `JORF_19820122_18_raw.txt`, le
décret n° 82-56 (Eure) a son texte aux lignes 412-431 et son titre à la 470.

Conséquence mesurée : « Evreux-Ouest » rangé sous le décret du Doubs et
« Lorient-Centre » sous celui du Cantal, l'ancre ayant été prise dans la
colonne de gauche pendant que le texte courait à droite.

On lit désormais `*_col.txt`, produit par `cantons/jorf_colonnes.py` — deux
appels à `pdftotext` par page, une boîte par colonne. Sur les JO exploités, les
inversions de numérotation des décrets tombent de 88 à 46.

`--source raw` rejoue l'ancienne lecture : on signale, on ne supprime pas, et
les deux lectures doivent pouvoir être comparées.
"""

import argparse
import collections
import csv
import difflib
import glob
import os
import re
import unicodedata
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
DECRETS = RACINE / "cantons" / "decrets_cantonaux.csv"
NOMS = RACINE / "build" / "noms_geofla.csv"
MVT = RACINE / "sources" / "v_mvt_commune_2025.csv"
SORTIE = RACINE / "cantons" / "composition_jo.csv"
RESTE = RACINE / "cantons" / "composition_jo_non_appariees.csv"

# Seuil de ressemblance, repris tel quel de composition_decrets.py. Choisi
# avant de mesurer, et non ajusté ensuite.
SEUIL = 0.88

# ---------------------------------------------------------------------------
# Nettoyage du texte — repris de extraire_communes_coupees.py, où il a été
# éprouvé sur les JO de 1973/1982/1984.

VOCAB = ["portion", "portions", "territoire", "territoires", "partie", "parties",
         "fraction", "fractions", "commune", "communes", "ville", "comprenant",
         "comportant", "canton", "cantons", "delimitee", "delimite", "delimitees",
         "situee", "situe", "incluse", "incluses", "departement", "conseil",
         "general", "prefecture", "chef-lieu"]


def _rep(mot):
    return re.compile("|".join(re.escape(mot[:i]) + r"\s+" + re.escape(mot[i:])
                               for i in range(2, len(mot) - 1)), re.I)


REPARS = [(_rep(m), m) for m in VOCAB]


def repare(t):
    """L'OCR du JO coupe des mots en deux (« terri toire »). On les recolle."""
    for rx, mot in REPARS:
        t = rx.sub(lambda m: m.group(0)[0].upper() + mot[1:]
                   if m.group(0)[0].isupper() else mot, t)
    return t


def nettoie(t):
    t = t.replace("­", "").replace("’", "'").replace("‘", "'")
    # Un trait d'union en fin de ligne est ambigu : césure typographique, ou
    # trait d'union du nom ? La suite tranche, et il faut les DEUX cas.
    #   « Fonte-\nnay-Mauvoisin »  -> césure : on soude sans trait d'union
    #   « Jouy-\nMauvoisin »       -> nom composé : on garde le trait d'union
    # L'espace est toléré de part et d'autre du saut de ligne : la lecture par
    # colonnes indente la moitié droite, et sans cela la règle ne voyait plus
    # rien. C'est ce qui a fait perdre 26 communes au canton de
    # Bonnières-sur-Seine — par UN caractère au-dessus du plafond du § suivant.
    t = re.sub(r"-[ \t]*\n[ \t]*(?=[a-zà-ÿ])", "", t)
    t = re.sub(r"-[ \t]*\n[ \t]*(?=[A-ZÀ-Ý])", "-", t)
    return repare(re.sub(r"[ \t\n]+", " ", t))


def cle(s):
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    return re.sub(r"[^a-z0-9]", "", s.lower())


# ---------------------------------------------------------------------------
# Segmentation et amorces — mêmes expressions que les deux scripts existants.

DE = r"(?:d'|de\s+l'|de\s+la\s+|de\s+les\s+|des\s+|du\s+|de\s+)"
CANTON = re.compile(r"[Cc]anton\s+" + DE +
                    r"([^\n,]{1,55}?)\s*,?\s+"
                    # « comprend » à l'indicatif n'était pas prévu : les décrets
                    # de 1975 écrivent « Le canton de X comprend les communes
                    # de… » là où ceux de 1973 écrivent « comprenant ». Quatre
                    # décrets muets sur dix-sept tenaient à ce seul mot.
                    r"(?:comprennent|comprenant|comprend|comportant|"
                    r"d[ée]limit[ée]|constitu[ée]|form[ée]|compos[ée])")
FINDEC = re.compile(r"(Fait\s+à\s+Paris|est\s+charg[ée]\s+de\s+l'ex[ée]cution\s+du\s+pr[ée]sent\s+d[ée]cret)", re.I)
TOKEN = re.compile(r"[A-ZÉÈÀÂÎÔÛÇ][\wÀ-ÿ']{2,}(?:-[A-ZÉÈÀÂÎÔÛÇa-zà-ÿ'][\wÀ-ÿ']*){0,5}")

AMORCE = re.compile(
    r"(?:comprennent|comprenant|comprend|comportant|compos[ée]e?s?\s+d[eu]s?)\s+"
    r"(?:l(?:es?|a|')\s*\d?\s*"
    r"(?:anciennes?\s+|nouvelles?\s+)?communes?"
    r"(?:\s+associ[ée]es?)?)\s*"
    r"(?:de\s+|d[’']|du\s+|des\s+)",
    re.I)
FIN = re.compile(
    r",?\s*(?:ainsi\s*qu|et\s+(?:l[ae]s?\s+)?(?:portions?|partie)"
    r"|,?\s*(?:l[ae]s?\s+)?portions?\s+de\s+territoire"
    # « comprenant la commune de X ou est fixe son chef-lieu » — formule
    # courante des decrets de 1967. Sans cette borne, le nom de la commune
    # emporte toute la phrase : 31 lignes portaient « Fontenay-sous-Bois ou
    # est fixe son chef-lieu » et ne s'appariaient a rien. Le canton existait
    # dans le fichier, avec une commune fantome.
    r"|\s+o[uù]\s+est\s+fix[eé]"
    r"|\.\s+[A-Z]|\s;|Le\s+chef-lieu|$)",
    re.I)
SEPARE = re.compile(r"\s*,\s*|\s+et\s+", re.I)
# « Le chef-lieu de ce canton est fixé à Lorient. » Le décret nomme toujours
# le chef-lieu, et un chef-lieu EST une commune — à la différence des rues qui
# décrivent le reste d'un canton urbain.
CHEFLIEU = re.compile(r"chef-lieu\s+(?:de\s+ce\s+canton\s+)?est\s+fix[ée]\s+[àa]\s+"
                      r"([A-ZÀ-Ý][\wÀ-ÿ'’]*(?:[-\s][A-ZÀ-Ýa-zà-ÿ'’][\wÀ-ÿ'’]*){0,5})")

FRACTION = re.compile(r"portions?\s+de\s+territoire|parties?\s+"+DE+r"(?:ville|commune)|fractions?\s+"+DE+r"(?:ville|commune)", re.I)


# Plafond de longueur d'une liste de communes. Il garde contre le cas où
# `AMORCE` accroche mais `FIN` ne trouve rien, et où l'on avalerait la page.
#
# Il valait 400 et coupait DANS le corpus : le canton de Bonnières-sur-Seine
# (26 communes) produit une liste de 401 caractères et disparaissait — sans
# sortie et sans rejet, donc invisible. Un plafond qui décide de l'existence
# d'un canton ne doit ni être serré ni être muet.
#
# 1200 tient les plus longues listes réelles avec de la marge. Et le
# dépassement est désormais SIGNALÉ.
PLAFOND_LISTE = 1200


def liste_communes(texte, alerte=None):
    m = AMORCE.search(texte or "")
    if not m:
        return []
    reste = texte[m.end():]
    f = FIN.search(reste)
    segment = reste[:f.start()] if f else reste
    if len(segment) > PLAFOND_LISTE:
        if alerte is not None:
            alerte.append(len(segment))
        return []
    out = []
    for n in SEPARE.split(segment):
        n = n.strip(" .;:'’")
        # Les numeros d'article imprimes en marge du JO — « 28 Canton de… » —
        # restent colles au nom quand la colonne les emporte. Ils n'ont jamais
        # fait partie d'un nom de commune, et deux caracteres de trop
        # suffisaient a franchir la limite de longueur, donc a perdre le
        # canton sans un mot.
        n = re.sub(r"^\d{1,3}\s+|\s+\d{1,3}$", "", n)
        # Scories de numerisation collees devant le nom — « Colleville,^
        # Saint-Aubin-d'Arquenay » coutait la commune de
        # Saint-Aubin-d'Arquenay au canton d'Ouistreham-Riva-Bella : le nom
        # ne commencait plus par une majuscule, et le test le rejetait.
        n = re.sub(r"^[^\wÀ-ÿ]+", "", n)
        n = re.sub(r"\s*-\s*", "-", n)
        n = re.sub(r"\s+", " ", n)
        if 2 < len(n) < 45 and re.match(r"[A-ZÀ-Ÿ]", n):
            out.append(n)
    return out


# ---------------------------------------------------------------------------
# Dictionnaires de noms

def _dep(com):
    return com[:3] if com[:2] in ("97", "98") else com[:2]


def noms_par_departement():
    d = collections.defaultdict(dict)
    with NOMS.open(encoding="utf-8") as f:
        for l in csv.DictReader(f):
            d[l["dep"]][cle(l["nom"])] = (l["insee"], l["nom"])
    return d


def prefixes_par_departement(vivantes, disparues):
    """{dep: {clé d'un préfixe au trait d'union: [(insee, nom), ...]}}

    « Colleville-Montgomery » donne « Colleville ». Les décrets abrègent
    souvent ainsi. On n'indexe QUE les coupures au trait d'union — pas les
    préfixes de caractères, qui feraient de « Bar » une amorce pour la moitié
    de la Meuse.

    La liste est gardée entière, jamais réduite : c'est elle qui dit si le
    préfixe désigne une commune ou plusieurs. « Colleville » en désigne deux
    dans le Calvados — Montgomery et sur-Mer — et l'ambiguïté est un fait de
    la source, pas un défaut à trancher.
    """
    idx = collections.defaultdict(lambda: collections.defaultdict(list))
    for source in (vivantes, disparues):
        for dep, m in source.items():
            for _, (insee, nom) in m.items():
                bouts = nom.split("-")
                for i in range(1, len(bouts)):
                    k = cle("-".join(bouts[:i]))
                    if len(k) < 4:
                        continue
                    if (insee, nom) not in idx[dep][k]:
                        idx[dep][k].append((insee, nom))
    return idx


def communes_disparues():
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


def apparie(nom, dep, vivantes, disparues, prefixes=None, interdits=()):
    """(insee, nom_ref, qualité) — quatre dictionnaires, dans cet ordre.

    Les trois premiers sont ceux de `composition_decrets.py` : GEOFLA pour les
    communes vivantes, `insee_mvt.libelle_av` pour celles mortes avant 2011,
    la ressemblance pour ce que l'OCR abîme — tous restreints au département
    du décret, sans quoi « Saint-Just » s'apparie au hasard.

    Le quatrième est un repli : hors du département, France entière, et
    seulement si le nom n'est porté que par un seul département. Il sert peu
    (1,3 % des lignes) et il est toujours signalé comme tel : quand il tombe,
    c'est en général que le segment a été rattaché au mauvais décret, et c'est
    une information — pas une réparation.
    """
    k = cle(nom)

    def libre(i):
        return i not in interdits

    if k in vivantes.get(dep, {}):
        i, n = vivantes[dep][k]
        if libre(i):
            return i, n, "exact"
    if k in disparues.get(dep, {}):
        i, n = disparues[dep][k]
        if libre(i):
            return i, n, "disparue"

    # --- LE PRÉFIXE AVANT LA RESSEMBLANCE -----------------------------------
    # Ajouté le 28 août 2026, après Colleville / Cléville.
    #
    # Le décret écrit « Colleville » là où le référentiel écrit
    # « Colleville-Montgomery ». La ressemblance orthographique départage ces
    # cas À L'ENVERS : « Colleville » ressemble davantage à « Cléville » (0,89)
    # qu'à « Colleville-Montgomery » (0,71), et c'est ainsi qu'un canton s'est
    # vu attribuer la commune d'un autre.
    #
    # Le préfixe au trait d'union est une pièce, la ressemblance une
    # conjecture. On essaie donc la pièce d'abord — dans les deux sens, car le
    # décret abrège parfois (« Colleville ») et parfois allonge
    # (« Ouistreham-Riva-Bella » pour la commune d'Ouistreham).
    if prefixes is not None:
        cands = [c for c in prefixes.get(dep, {}).get(k, []) if libre(c[0])]
        if len(cands) == 1:
            i, n = cands[0]
            return i, n, "prefixe"
        if len(cands) > 1:
            # Deux communes portent le même préfixe. La source ne tranche pas ;
            # nous non plus. On le DIT, au lieu d'en choisir une.
            return "", "|".join(f"{i} {n}" for i, n in cands), "prefixe ambigu"

    pool = [x for x in list(vivantes.get(dep, {})) + list(disparues.get(dep, {}))
            if libre((vivantes.get(dep, {}).get(x) or disparues[dep][x])[0])]
    proches = difflib.get_close_matches(k, pool, n=1, cutoff=SEUIL)
    if proches:
        pr = proches[0]
        i, n = vivantes.get(dep, {}).get(pr) or disparues[dep][pr]
        return i, n, "ressemblance"

    # LE DÉCRET ALLONGE : on raccourcit le nom LU, au trait d'union, du plus
    # long au plus court, et on n'accepte qu'une correspondance EXACTE. Jamais
    # une ressemblance sur un nom déjà tronqué : deux approximations empilées
    # ne font pas une lecture.
    #
    # CE REPLI VIENT APRÈS LA RESSEMBLANCE, et c'est une correction du
    # 28 août 2026 au soir. Placé avant, il tranchait « Bréville-Beuville »
    # (lecture OCR de Biéville-Beuville) en « Bréville » — commune réelle du
    # Calvados, mais celle du canton voisin de Cabourg, qui la réclamait au
    # même acte. Le § 5 bis de `75` a signalé la collision.
    #
    # La règle qui en sort : **le nom entier porte plus d'information que sa
    # troncature.** Une ressemblance sur le nom COMPLET (Bréville-Beuville /
    # Biéville-Beuville, 0,94) doit l'emporter sur une correspondance exacte
    # obtenue en JETANT la moitié du nom. Là où la ressemblance ne trouve
    # rien — « Ouistreham-Riva-Bella » ne ressemble à « Ouistreham » qu'à
    # 0,69 — la troncature reste seule, et elle a raison.
    bouts = re.split(r"\s*-\s*", nom)
    for j in range(len(bouts) - 1, 0, -1):
        if len(bouts) - j > 2:
            break
        kk = cle("-".join(bouts[:j]))
        if len(kk) < 4:
            continue
        for source, _ in ((vivantes, "v"), (disparues, "d")):
            if kk in source.get(dep, {}):
                i, n = source[dep][kk]
                if libre(i):
                    return i, n, "prefixe lu"


    # hors du département du décret : on n'accepte que l'unicité nationale
    ailleurs = []
    for d, m in disparues.items():
        if k in m:
            ailleurs.append(m[k])
    for d, m in vivantes.items():
        if k in m and m[k] not in ailleurs:
            ailleurs.append(m[k])
    ailleurs = [x for x in ailleurs if libre(x[0])]
    uniq = {c for c, _ in ailleurs}
    if len(uniq) == 1:
        i, n = ailleurs[0]
        return i, n, "autre departement"
    if len(uniq) > 1:
        return "", "", "ambigu hors departement"
    return "", "", "aucun"


# ---------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--jo", help="ne traiter qu'un numéro (ex. JORF_19670722_169)")
    ap.add_argument("--source", choices=("col", "raw"), default="col",
                    help="col = jorf_txt/*_col.txt (colonnes séparées, défaut) ; "
                         "raw = l'ancienne lecture entrelacée, pour comparer")
    ap.add_argument("--sortie", help="chemin du CSV produit (défaut : composition_jo.csv)")
    ap.add_argument("--rejets", help="chemin du CSV des rejets")
    args = ap.parse_args()

    suffixe = "_col.txt" if args.source == "col" else "_raw.txt"
    sortie = Path(args.sortie) if args.sortie else SORTIE
    reste = Path(args.rejets) if args.rejets else RESTE

    decrets = list(csv.DictReader(DECRETS.open(encoding="utf-8")))
    # {date_publication (AAAAMMJJ): [décret, ...]}
    parjo = collections.defaultdict(list)
    for r in decrets:
        if r["date_publication_jo"]:
            parjo[r["date_publication_jo"].replace("-", "")].append(r)

    vivantes = noms_par_departement()
    disparues = communes_disparues()
    prefixes = prefixes_par_departement(vivantes, disparues)

    lignes, rejets = [], []
    vus = collections.Counter()

    fichiers = sorted(glob.glob(str(RACINE / "jorf_txt" / ("*" + suffixe))))
    if not fichiers:
        print(f"aucun fichier {suffixe} dans jorf_txt/ — "
              f"lancer d'abord cantons/jorf_colonnes.py")
        return
    for path in fichiers:
        jo = os.path.basename(path).replace(suffixe, "")
        if args.jo and args.jo != jo:
            continue
        m = re.search(r"(\d{8})", jo)
        if not m:
            continue
        cand = parjo.get(m.group(1), [])
        if not cand:
            continue
        deps = {r["dep_code"] for r in cand if r["dep_code"]}
        txt = nettoie(open(path, encoding="utf-8", errors="replace").read())

        # Ancres : les positions où le numéro d'un décret de CE numéro de JO
        # apparaît dans le texte. On ne cherche que les numéros attendus, ce
        # qui écarte d'office les « Vu le décret n° 66-352 » des visas.
        ancres = []
        for r in cand:
            num = r["decret"].replace("n° ", "").strip()
            if not num:
                continue
            a, b = num.split("-")
            rx = re.compile(r"n[°ºo]\s*" + a + r"\s*[-–]\s*" + b + r"\b")
            for m in rx.finditer(txt):
                ancres.append((m.start(), r))
        # à défaut de numéro, le nom du département en tête de décret
        for r in cand:
            if any(x[1] is r for x in ancres) or not r["dep_nom_epoque"]:
                continue
            nomdep = r["dep_nom_epoque"].replace("-", "[- ]").title()
            rx = re.compile(r"\b" + nomdep + r"\s*\(\s*d[ée]cret", re.I)
            for m in rx.finditer(txt):
                ancres.append((m.start(), r))
        ancres.sort(key=lambda x: x[0])

        marks = [(x.start(), x.group(1).strip(" .,-")) for x in CANTON.finditer(txt)]
        for i, (p, nom_canton) in enumerate(marks):
            seg = txt[p: marks[i + 1][0] if i + 1 < len(marks) else len(txt)]
            f = FINDEC.search(seg)
            if f:
                seg = seg[:f.end()]
            if len(seg) > 4000:
                seg = seg[:4000]
            trop_long = []
            noms = liste_communes(seg, trop_long)
            if trop_long:
                rejets.append(dict(jo=jo, canton=nom_canton,
                                   motif="liste au-dela du plafond",
                                   extrait="%d caracteres (plafond %d)"
                                           % (trop_long[0], PLAFOND_LISTE)))
            if not noms and not FRACTION.search(seg):
                continue

            # Attribution du décret : par l'ancre, pas par le vote.
            #
            # La première version votait sur les communes reconnues. Elle a
            # rendu 568 lignes sur 651 au seul décret des Yvelines pour le JO
            # du 22 juillet 1967, et zéro à celui de l'Essonne : en 1967 les
            # communes de la future Essonne portent des codes 78, et le vote
            # les lisait comme des Yvelines. Le vote mesurait la nomenclature,
            # pas le décret.
            #
            # Le JO, lui, imprime le numéro du décret en tête de chacun :
            # « Essonne (décret n° 67-589 du 20 juillet 1967) ». On coupe
            # là-dessus. Le vote ne sert plus que de repli, et il est signalé
            # comme tel.
            #
            # L'ancre seule ne suffit pas : quand l'OCR abîme un numéro de
            # décret, l'ancre manque et les cantons de ce décret se collent au
            # décret précédent — sans bruit, et par blocs entiers. Le vote sert
            # alors de contradicteur : si les communes du segment désignent
            # massivement un autre département qui légifère dans ce même
            # numéro, c'est l'ancre qui a tort.
            # UN CANTON SANS LISTE DE COMMUNES N'A PAS DE VOIX
            #
            # Corrigé le 28 août 2026. Le vote parcourt tous les mots
            # capitalisés du segment. Or un canton urbain est décrit par des
            # RUES : « rue Saint-Laurent », « rue Colbert », « place
            # Sadi-Carnot ». Ces noms existent aussi comme communes ailleurs
            # en France, et ils votaient.
            #
            # Le canton de Marseille-I, dont l'ancre — le décret n° 73-812,
            # Bouches-du-Rhône — était juste et à trente lignes de là, s'est
            # ainsi retrouvé en Haute-Savoie, « ancre contredite » par une
            # poignée de plaques de rues.
            #
            # Restreindre le vote aux seules communes lues a été essayé et
            # MESURÉ : le contrôle par les titres perdait ce qu'il avait
            # gagné, les cantons égarés repassant de 0 à 2. Le vote sur le
            # segment travaille donc vraiment, ailleurs.
            #
            # Refuser toute voix à ces segments a été essayé aussi, et
            # MESURÉ : Marseille-I rentrait dans les Bouches-du-Rhône, mais
            # Lorient-Centre repartait dans le Cantal — lui aussi décrit par
            # des fractions, et lui aussi mal ancré. Les deux cas s'opposent :
            # à Marseille l'ancre a raison, à Lorient c'est le vote.
            #
            # Ce qui les départage n'est donc pas la présence d'une liste,
            # c'est la QUALITÉ DE LA PREUVE. Un canton sans communes entières
            # ne vote pas avec ses rues : il vote avec les deux seuls noms de
            # communes que le décret lui donne — **son chef-lieu**, toujours
            # nommé (« Le chef-lieu de ce canton est fixé à Lorient »), et le
            # sien propre, qui porte celui de sa ville (« Marseille-I »).
            #
            # C'est le même principe que partout ailleurs dans le dépôt : on
            # ne réduit pas le nombre de preuves, on écarte celles qui n'en
            # sont pas.
            votes = collections.Counter()
            if noms:
                source_votes = [t.group(0) for t in TOKEN.finditer(seg)]
            else:
                source_votes = [m.group(1) for m in CHEFLIEU.finditer(seg)]
                # « Marseille-I » -> « Marseille » ; « Lorient-Centre » ->
                # « Lorient ». On ne garde que la tête du nom, jamais le
                # qualificatif, qui n'est pas une commune.
                tete = re.split(r"\s*-\s*", nom_canton)[0]
                if len(tete) > 2:
                    source_votes.append(tete)
            for t in source_votes:
                k = cle(t)
                for d in deps:
                    if k in vivantes.get(d, {}):
                        votes[d] += 1

            d0, mode = None, ""
            precedentes = [a for a in ancres if a[0] <= p]
            if precedentes:
                d0, mode = precedentes[-1][1], "ancre"
            if votes:
                dd, nn = votes.most_common(1)[0]
                if d0 is None:
                    dec = [r for r in cand if r["dep_code"] == dd]
                    if dec:
                        d0, mode = dec[0], "vote"
                elif (dd != d0["dep_code"]
                      and nn >= (2 if noms else 1)
                      and nn >= 2 * votes.get(d0["dep_code"], 0)):
                    dec = [r for r in cand if r["dep_code"] == dd]
                    if dec:
                        d0, mode = dec[0], "vote (ancre contredite)"
            if d0 is None:
                rejets.append(dict(jo=jo, canton=nom_canton, motif="decret indetermine",
                                   extrait=seg[:200]))
                continue
            dep = d0["dep_code"]
            multi = mode
            num = d0["decret"].replace("n° ", "") or ("[" + d0["legifrance_id"][-6:] + "]")
            vus[(jo, dep)] += 1

            if not noms:
                lignes.append(dict(jo=jo, decret=num, date=d0["date_signature"], dep=dep,
                                   canton=nom_canton, nom_texte="", insee="", nom_ref="",
                                   dep_insee="",
                                   appariement="fraction seule", attribution=multi,
                                   legifrance_url=d0["legifrance_url"]))
                continue
            for n in noms:
                insee, ref, q = apparie(n, dep, vivantes, disparues, prefixes)
                # « prefixe ambigu » renvoie la LISTE des candidats dans `ref` :
                # elle a sa place dans le fichier des rejets, pas dans une
                # colonne qui promet un nom de référence unique.
                row = dict(jo=jo, decret=num, date=d0["date_signature"], dep=dep,
                           canton=nom_canton, nom_texte=n, insee=insee,
                           nom_ref=("" if q == "prefixe ambigu" else ref),
                           dep_insee=(insee[:3] if insee[:2] in ("97","98") else insee[:2]) if insee else "",
                           appariement=q, attribution=multi,
                           legifrance_url=d0["legifrance_url"])
                lignes.append(row)
                if q == "aucun":
                    rejets.append(dict(jo=jo, canton=nom_canton, motif="nom non apparie (%s)" % dep,
                                       extrait=n))
                elif q == "prefixe ambigu":
                    rejets.append(dict(jo=jo, canton=nom_canton,
                                       motif="prefixe ambigu (%s)" % dep,
                                       extrait="%s -> %s" % (n, ref)))

    if not lignes:
        print("aucune composition extraite")
        return

    # -----------------------------------------------------------------------
    # UN CODE PRIS EN `exact` NE SE PARTAGE PAS — passe de rattrapage
    #
    # Ajoutée le 28 août 2026. Sur les 4 958 lignes de la lecture précédente,
    # un seul code INSEE était réclamé par deux cantons d'un même acte :
    # `14163`, donné à Troarn en `exact` (« Cléville ») et à
    # Ouistreham-Riva-Bella par `ressemblance` (« Colleville »). Le décret ne
    # se contredit pas — c'est l'appariement qui a fabriqué une cible.
    #
    # Règle : quand un acte attribue un même code à deux cantons et qu'une
    # seule des lectures est une PIÈCE (`exact`, `disparue`, `prefixe`), les
    # autres sont refaites en s'interdisant ce code. Une conjecture ne prend
    # pas la place d'une pièce.
    #
    # On ne tranche PAS entre deux pièces : deux `exact` sur le même code
    # seraient une contradiction réelle de la source, et elle doit remonter.
    # -----------------------------------------------------------------------
    PIECES = {"exact", "disparue", "prefixe", "prefixe lu"}
    par_code = collections.defaultdict(list)
    for r in lignes:
        if r["insee"]:
            par_code[(r["legifrance_url"], r["insee"])].append(r)

    reprises = collections.Counter()
    for (url, insee), grp in par_code.items():
        if len({r["canton"] for r in grp}) < 2:
            continue
        fortes = [r for r in grp if r["appariement"] in PIECES]
        faibles = [r for r in grp if r["appariement"] not in PIECES]
        if not fortes or not faibles:
            if len(fortes) > 1:
                reprises["contradiction entre deux pièces (non tranchée)"] += 1
            continue
        for r in faibles:
            i2, n2, q2 = apparie(r["nom_texte"], r["dep"], vivantes, disparues,
                                 prefixes, interdits={insee})
            reprises["%s -> %s" % (r["appariement"], q2)] += 1
            r["insee"] = i2
            r["nom_ref"] = "" if q2 == "prefixe ambigu" else n2
            r["dep_insee"] = (i2[:3] if i2[:2] in ("97", "98") else i2[:2]) if i2 else ""
            r["appariement"] = q2
            rejets.append(dict(jo=r["jo"], canton=r["canton"],
                               motif="code deja pris en piece par un autre canton",
                               extrait="%s (%s) -> %s" % (r["nom_texte"], insee, q2)))

    lignes.sort(key=lambda r: (r["date"], r["dep"], r["canton"], r["nom_texte"]))
    with sortie.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(lignes[0].keys()))
        w.writeheader()
        w.writerows(lignes)
    if rejets:
        with reste.open("w", newline="", encoding="utf-8") as f:
            w = csv.DictWriter(f, fieldnames=list(rejets[0].keys()))
            w.writeheader()
            w.writerows(rejets)

    q = collections.Counter(r["appariement"] for r in lignes)
    print("source :", suffixe, "  ->", sortie.name)
    if reprises:
        print("\ncodes repris parce qu'un autre canton du même acte les tenait"
              " par une pièce :")
        for k, v in reprises.most_common():
            print("   %-44s %d" % (k, v))
    print("\nlignes (décret × canton × commune) :", len(lignes))
    print("décrets touchés :", len({r["decret"] for r in lignes}),
          "sur", len(decrets), "au registre des décrets")
    print("cantons distincts :", len({(r["dep"], r["canton"]) for r in lignes}))
    print("numéros de JO exploités :", len({r["jo"] for r in lignes}))
    print("\nqualité d'appariement :")
    for k, v in q.most_common():
        print("   %-16s %5d  %5.1f %%" % (k, v, 100 * v / len(lignes)))
    print("\nrejets :", len(rejets))
    par = collections.Counter(r["motif"].split(" (")[0] for r in rejets)
    for k, v in par.most_common():
        print("   %-30s %d" % (k, v))
    print("\npar date de signature :")
    for d, n in sorted(collections.Counter(r["date"] for r in lignes).items()):
        print("   %s  %5d lignes  %3d cantons  %2d décrets"
              % (d, n, len({(r["dep"], r["canton"]) for r in lignes if r["date"] == d}),
                 len({r["decret"] for r in lignes if r["date"] == d})))


if __name__ == "__main__":
    main()
