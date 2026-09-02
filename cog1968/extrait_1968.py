#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
extrait_1968.py — la composition cantonale de 1968, fascicule par fascicule

    python3 cog1968/extrait_1968.py --dep 02
    python3 cog1968/extrait_1968.py --dep 02 --pages 18-30 --langue eng
    python3 cog1968/extrait_1968.py --tous            # les 83 fascicules

Produit `cog1968/communes_1968.csv`.

Ce que ce script NE réécrit PAS
-------------------------------
La chaîne d'OCR existe déjà : `cog1954/extrait_1954.py` rend une page en PNG
gris à 300 dpi (`pdftoppm`) puis la passe à `tesseract -l fra --psm 6`, le tout
en multiprocessing. Elle a été éprouvée sur 958 pages. **Elle est importée
telle quelle** — `page_texte`, `nettoie_nom`, `nettoie_nombre`, `SOSIES`.

Ce qui change est la **grammaire de la ligne**, et elle seule.

    1954   [arr] [canton] Nom.  [population]
    1968   [pop 1962] [pop 1962 sans doubles] [arr] [canton] [INSEE] Nom.  [pop 1968]

Lancer le parseur de 1954 sur un fascicule de 1968 rend **2 lignes sur 600** :
la chaîne tourne, la grammaire ne colle pas. C'est mesuré, pas supposé.

Ce que 1968 apporte, et que 1954 n'avait pas
--------------------------------------------
**Le code INSEE de la commune est imprimé.** Vérifié sur neuf communes de
l'Aisne, neuf concordances sur neuf avec `noms_geofla`. En 1954 la jointure
passait par le nom et laissait 7 576 orphelins ; ici il n'y a pas de jointure
par nom du tout. Le nom devient une pièce de contrôle au lieu d'être la clé.

Trois garde-fous en découlent :

* **le code croît** dans la page — l'INSEE est attribué dans l'ordre
  alphabétique. Un chiffre mal lu se détecte sur ses voisins, sans dictionnaire ;
* **le nom confirme le code**, et non l'inverse. Deux lectures indépendantes du
  même fait, dont l'une n'est plus nécessaire à l'autre ;
* **l'en-tête de page** porte « AISNE (02) » — le département ET son code, sur
  chaque feuille de tableau. Aucun héritage d'en-tête à gérer, aucune suite
  croissante à surveiller : les quatre pièges du volume national de 1954
  disparaissent.

Reste le tableau II — population et nombre de communes par canton — qui donne
une recette de contrôle fournie par la source. Il n'est pas encore extrait.
"""

import argparse
import collections
import csv
import multiprocessing
import os
import re
import sys
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(RACINE / "cog1954"))
# On importe la chaîne d'OCR de 1954 plutôt que de la recopier. Si elle est
# améliorée là-bas — prétraitement, dpi, langue — 1968 en profite sans rien
# changer ici.
#
# La réciproque n'est PAS vraie, et c'est délibéré : ce qui est mesuré sur les
# fascicules de 1968 ne vaut que pour eux. `PSM` ci-dessous est passé en
# argument à `page_texte` au lieu d'en changer le défaut, pour que le gain de
# 1968 ne s'applique pas en douce à une campagne où il n'a pas été éprouvé.
from extrait_1954 import page_texte, nettoie_nom, SOSIES   # noqa: E402

FASCICULES = RACINE / "sources" / "rp1968"
INDEX = RACINE / "cog1968" / "fascicules_1968.csv"
SORTIE = RACINE / "cog1968" / "communes_1968.csv"

# LE MODE DE SEGMENTATION DE TESSERACT, mesuré et non hérité.
#
# 1954 avait figé « 6 » — un bloc de texte uniforme — sans jamais l'éprouver, et
# 1968 en héritait. Le banc d'essai `essai_ocr.py`, sur trois fascicules
# ENTIERS confrontés aux codes INSEE réels, donne :
#
#     département        psm 6       psm 4        faux
#     79 Deux-Sèvres       213     235  (+22)   41 -> 45
#     43 Haute-Loire       185     220  (+35)    3 ->  5
#     65 Hautes-Pyrénées   353     375  (+22)    5 ->  6
#
# « 4 » suppose une COLONNE de texte de tailles variables : c'est la forme du
# tableau III. Le gain est régulier d'un fascicule à l'autre — c'est ce qui le
# distingue de la résolution, qui rend +30, +5 et +25 selon le scan et n'est
# donc pas un effet de chaîne.
PSM = "4"

# ---------------------------------------------------------------------------
# La ligne de commune du tableau III.
#
#   219  219   4  35  562  Nouvron-Vingré.   221  221  124  97  …
#   ─┬─  ─┬─   ┬  ─┬  ─┬─  ──────┬────────   ─┬─
#    │    │    │   │   │         │            └── population 1968
#    │    │    │   │   │         └── nom, terminé par un point ou une virgule
#    │    │    │   │   └── code INSEE de la commune, 3 chiffres
#    │    │    │   └── canton, 2 chiffres
#    │    │    └── arrondissement, 1 chiffre
#    │    └── population 1962 sans doubles comptes
#    └── population 1962 totale
#
# Les deux premières colonnes sont acceptées mais non exigées : le bord gauche
# de la page est le plus abîmé par la reliure, et une ligne dont la population
# de 1962 est illisible reste parfaitement utilisable — c'est le canton qu'on
# vient chercher, pas la démographie.
# Le nom, élargi le 20 août 2026 — trois mécanismes MESURÉS, pas supposés
# (`lignes_rejetees.py`, Bouches-du-Rhône et Territoire de Belfort) :
#
#   1. **L'article est rejeté en fin de nom, entre parenthèses** : « Barben
#      (La). », « Baux-de-Provence (Les). ». La classe n'acceptait pas `(`.
#      6,3 % des communes de 1968, et cela explique la géographie du rappel —
#      Moselle 88,7 %, Vendée 62,5 %, corrélation -0,50.
#   2. **Les appels de note**, « Andelnans (1). », parfois en accolades quand
#      l'OCR se trompe : « Bue {1}. ». À Belfort, 24 des 28 rejets.
#   3. **Les confusions de l'OCR** : « lstres » pour Istres — un `I` initial lu
#      `l` minuscule, quand le nom devait commencer par une majuscule — et
#      « Châäteauneuf », où un `ä` s'insère dans une classe qui l'ignorait.
#
# Élargir le nom fait entrer les lignes de TOTAL, qui portent la même
# signature — « 1°° Canton. », « TOTAL » — et ne sont pas des communes. D'où
# `EXCLUS`, appliqué avant : on élargit d'un côté, on referme de l'autre.
LIGNE = re.compile(
    r"(?:(\d[\d.\s]{0,9}?)\s+(\d[\d.\s]{0,9}?)\s+)?"     # populations 1962
    r"([\dOSlI])\s+"                                      # arrondissement
    r"([\dOSlI$]{2})\s+"                                  # canton
    r"(\d{3})\s+"                                         # code INSEE
    r"([A-Za-zÉÈÊËÀÂÄÎÏÔÖÛÜÙÇŒ]"                          # initiale, casse libre
    # L'ASTÉRISQUE, ajouté le 22 août 2026. Le fascicule marque certaines
    # communes d'un `*` accolé au nom — « Garches *. », « Sèvres *, »,
    # « Vaucresson *. », « Ville-d'Avray *. ». Sans lui dans la classe, la
    # ligne entière est rejetée et la commune perdue.
    #
    # Le motif se concentre sur les Hauts-de-Seine, la Seine-Saint-Denis et le
    # Val-de-Marne — les trois départements créés au 1er janvier 1968 — qui
    # sortaient à 31 %, 45 % et 47 % de rappel quand la moyenne est à 81 %.
    # C'est cohérent avec un renvoi signalant les communes touchées par la
    # réorganisation de la région parisienne, mais **le sens du symbole n'est
    # pas établi** : on l'accepte dans le nom sans prétendre l'interpréter.
    r"[A-Za-z0-9ÉÈÊËÀÂÄÎÏÔÖÛÜÙÇŒéèêëàâäîïôöûüùçœ'’\-\.\s(){}*]{2,54}?)"
    r"\s*[.,]\s+"                                         # le point final
    r"(\d[\d.]*)")                                        # population 1968

# Les lignes de TOTAL, et elles seules.
#
# Ce filtre excluait aussi le mot « canton », et c'était une faute — mesurée le
# 22 août 2026 sur les Hauts-de-Seine, le département le plus mal lu de France
# (31 % de rappel). Le fascicule y liste les communes multicantonales **une
# fois par canton** :
#
#   2 21 040 Issy-les-… ( Canton Est.    28.874 …
#   2 22 040 …Moulineaux - Canton Ouest. 22.792 …
#
# Même code INSEE 040, cantons 21 et 22. Idem Colombes (025), Nanterre (050),
# Courbevoie (026), Boulogne (012). **Ce ne sont pas des totaux : ce sont les
# fractions cantonales**, c'est-à-dire exactement la composition que ce script
# vient chercher. Les écarter revenait à jeter la donnée la plus précieuse du
# volume, et d'autant plus souvent que le département est urbain.
#
# Le raisonnement d'origine — « Marseille est découpée en 1er Canton, 2e
# Canton… sous le code 055 » — décrivait le bon phénomène et en tirait la
# mauvaise conclusion. Ces lignes marseillaises sont, elles aussi, la
# composition cantonale de Marseille.
#
# Restent à écarter les vrais récapitulatifs, « TOTAL » et « ENSEMBLE », qui ne
# portent pas de commune. Le contrôle que cette ouverture appelle est le
# nombre de codes INSEE distincts : une commune de plus est un gain, un code
# inconnu de l'étalon est une régression (`rappel_1968.py`).
EXCLUS = re.compile(r"\b(?:total|ensemble)\b", re.I)

# LA LIGNE DE CONTINUATION D'UNE VILLE MULTICANTONALE, ajoutée le 22 août 2026.
#
# Pas d'initiale alphabétique exigée — ces lignes commencent par une accolade —
# mais le mot « canton » OBLIGATOIRE : la règle ne s'applique qu'au motif
# qu'elle vise, et n'ouvre pas la grammaire à toute ligne de tableau.
#
# Le préfixe accepte les CHIFFRES, pour « 1er Canton » et « 3* Canton ». Une
# première version l'interdisait et rejetait du même coup les cantons numérotés,
# c'est-à-dire le cas le plus fréquent dans les grandes villes. Il est borné à
# 14 caractères, et le code INSEE l'ancre à gauche : les colonnes de population
# restent hors d'atteinte.
LIGNE_SUITE = re.compile(
    r"(?:(\d[\d.\s]{0,9}?)\s+(\d[\d.\s]{0,9}?)\s+)?"
    r"([\dOSlI])\s+"                       # arrondissement
    r"([\dOSlI$]{2})\s+"                   # canton
    r"(\d{3})\s+"                          # code INSEE
    r"([^.]{0,14}?\bcantons?\b[^.]{0,24})"  # « | 1er Canton », « ) 3* Canton »
    r"\s*[.,]\s+"
    r"(\d[\d.]*)", re.I)

# Aucune commune française ne porte « canton » dans son nom : sa présence
# signale toujours la mise en page d'une ville découpée en cantons.
CANTON_DANS_NOM = re.compile(r"\bcantons?\b", re.I)

# LES COLONNES DU CSV, définies UNE fois.
#
# Elles étaient écrites deux fois — dans `main()` et dans la reprise — et les
# deux listes devaient rester identiques sans que rien ne l'impose. Ajouter une
# colonne à l'une seulement produisait un `ValueError` au moment de l'écriture,
# c'est-à-dire après des heures d'OCR.
CHAMPS = ["dep", "insee", "insee3", "arr", "canton", "nom", "pop1968",
          "etoile", "libelle_canton", "hors_borne", "page"]

# « $ » pour « 3 » : confusion mesurée sur la première page OCRisée, où sept
# divergences sur huit portaient sur un 3 initial lu 8, 2 ou 1. On ne corrige
# ici que la substitution non ambiguë ; les autres se règlent par la monotonie
# du code INSEE, pas par une table de sosies qui devinerait.
SOSIES_1968 = str.maketrans({"O": "0", "S": "5", "l": "1", "I": "1", "$": "3"})


def bornes_cantonales():
    """{dep: plus haut code de canton connu en 1940} — une borne, pas un filtre.

    Un département de 37 cantons ne peut pas en porter un numéroté 94. Les
    codes lus au-delà de la borne sont donc presque sûrement des chiffres mal
    reconnus — mesuré sur l'Aisne : huit codes impossibles (50, 53, 54, 55, 60,
    82, 85, 94), vus une ou deux fois chacun, qui gonflaient le compte de 36 à
    44 cantons.

    **On signale, on ne supprime pas.** Un canton créé entre 1940 et 1968
    porterait justement un numéro au-delà de la borne : filtrer sur 1940
    reviendrait à faire de l'étalon un paramètre, et à rendre impossible la
    découverte même qu'on cherche. La colonne `hors_borne` marque la ligne, le
    tableau II tranchera.
    """
    hautes = collections.defaultdict(int)
    f = RACINE / "build" / "membership_canton.csv"
    if not f.exists():
        return hautes
    for l in csv.DictReader(f.open(encoding="utf-8")):
        u = l.get("unit_id") or ""
        if len(u) == 4 and u[2:].isdigit():
            hautes[u[:2]] = max(hautes[u[:2]], int(u[2:]))
    return hautes


def index():
    """{code département: chemin du fascicule} — écrit par index_fascicules.py."""
    if not INDEX.exists():
        raise SystemExit("Lancer d'abord : python3 cog1968/index_fascicules.py")
    d = {}
    for l in csv.DictReader(INDEX.open(encoding="utf-8")):
        if l["dep"]:
            d[l["dep"]] = FASCICULES / l["fichier"]
    return d


def traite(args):
    """Une page -> les lignes de commune qu'elle porte."""
    pdf, page, langue, dpi, psm = args
    out = []
    # PSM 4, et non le défaut 6 hérité de 1954. Mesuré le 22 août 2026 sur
    # trois fascicules entiers (79, 43, 65) : +22, +35, +22 communes justes,
    # sans envolée des faux. Voir `essai_ocr.py` et la docstring de
    # `page_texte`. Le défaut de 1954 n'a pas été touché : la mesure porte sur
    # les fascicules de 1968 et sur eux seuls.
    for brut in page_texte(pdf, page, langue=langue, dpi=dpi,
                           psm=psm).splitlines():
        # Les sous-totaux d'une grande ville portent la même signature qu'une
        # commune depuis que le nom est élargi. On les écarte AVANT la grammaire
        # plutôt que d'espérer qu'elle les refuse.
        if EXCLUS.search(brut):
            continue
        s = brut.strip()
        m = LIGNE.search(s)
        suite = False
        if not m:
            # LA LIGNE DE CONTINUATION D'UNE VILLE MULTICANTONALE.
            #
            # Une ville occupant plusieurs cantons tient sur autant de lignes,
            # et une seule porte son nom :
            #
            #     2 22 234 ORLÉANS : Canton Ouest.   8.901 …
            #     2 25 234 | Canton Sud (1).        18.537 …
            #
            # La seconde échoue sur `LIGNE`, qui exige une initiale
            # alphabétique et trouve une accolade. Or elle porte
            # l'arrondissement, le canton et le code de commune : tout ce qu'un
            # rattachement demande. Le nom n'y sert qu'au contrôle nom/code.
            #
            # Mesuré le 22 août 2026 par `essai_grammaire.py` sur six
            # départements, dont trois bien lus : **+9 rattachements, ZÉRO
            # faux**. C'est la variante la plus propre du banc — celle qui
            # ajoute le deux-points à la classe du nom gagne 5 de plus mais
            # coûte un faux.
            #
            # Le gain est petit — de l'ordre de 160 rattachements sur 30 939 —
            # et ne justifiait pas à lui seul de relancer les deux passes. Il
            # est posé ici pour la prochaine, quelle qu'en soit la raison.
            m = LIGNE_SUITE.search(s)
            suite = m is not None
        if not m:
            continue
        arr, canton, insee = (m.group(3).translate(SOSIES_1968),
                              m.group(4).translate(SOSIES_1968),
                              m.group(5))
        # L'asterisque est EXTRAIT du nom, pas jete : il porte une information
        # que la source a jugee utile d'ecrire. On ne sait pas encore laquelle,
        # d'ou une colonne plutot qu'une interpretation.
        nom = nettoie_nom(m.group(6))
        etoile = "oui" if "*" in nom else ""
        nom = nettoie_nom(nom.replace("*", ""))
        # Sur une ligne de continuation, le groupe 6 porte « | 1er Canton » et
        # NON un nom de commune. L'écrire dans la colonne `nom` empoisonnerait
        # `controle_nom_code.py`, qui compare le nom au code : il verrait des
        # centaines de communes nommées « Canton ». Le libellé va donc dans sa
        # propre colonne.
        #
        # MAIS la PREMIÈRE ligne d'une ville porte son nom devant le
        # séparateur — « ORLÉANS : Canton Ouest », « TROYES ) 3* Canton » — et
        # le jeter perdrait le seul contrôle nom/code disponible pour cette
        # commune. On le récupère quand il est là, et seulement alors.
        #
        # LE MÊME TRAITEMENT S'APPLIQUE AUX DEUX GRAMMAIRES. « TROYES ) 3*
        # Canton (1) » passe par `LIGNE`, pas par `LIGNE_SUITE`, et sortait
        # jusqu'ici avec ce nom entier — un désaccord garanti au contrôle
        # nom/code. Aucune commune française ne porte « canton » dans son nom :
        # sa présence signale toujours la mise en page d'une ville
        # multicantonale, quelle que soit la règle qui a reconnu la ligne.
        libelle = ""
        if suite or CANTON_DANS_NOM.search(nom):
            libelle = nom
            tete = re.split(r"[:|)\\/({]", nom, maxsplit=1)[0].strip(" .,-")
            nom = tete if len(re.sub(r"[^A-Za-zÀ-ÿ]", "", tete)) >= 3 else ""
        out.append(dict(page=page, arr=arr, canton=canton, insee3=insee,
                        nom=nom, etoile=etoile, libelle_canton=libelle,
                        pop1968=m.group(7).replace(".", "")))
    return page, out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dep", help="code département, ex. 02")
    ap.add_argument("--tous", action="store_true", help="les 83 fascicules")
    ap.add_argument("--pages", help="ex. 18-30 ; par défaut, tout le fascicule")
    ap.add_argument("--langue", default="fra")
    # LE DPI ET LE PSM SONT DES ARGUMENTS depuis le 22 août 2026, parce que la
    # REDONDANCE paie plus que le réglage. Mesuré par `essai_troisieme.py` :
    # une 3e lecture en 600 dpi apporte ~4 000 rattachements que l'union des
    # deux passes en service ne voit pas — alors que 600 dpi, SEULE, est la
    # plus mauvaise des variantes du banc de qualité.
    #
    # Ce n'est pas la performance d'une lecture qui compte pour la fusion,
    # c'est sa DÉCORRÉLATION : une lecture médiocre qui se trompe ailleurs vaut
    # mieux qu'une bonne lecture qui se trompe pareil.
    ap.add_argument("--dpi", type=int, default=300,
                    help="résolution de rendu (300 par défaut ; 600 pour une "
                         "troisième lecture décorrélée)")
    ap.add_argument("--psm", default=PSM,
                    help=f"segmentation tesseract ({PSM} par défaut)")
    ap.add_argument("--jobs", type=int,
                    default=max(1, (multiprocessing.cpu_count() or 2) - 1))
    # Une passe complète, c'est 83 fascicules et ~2 500 pages : des heures.
    # Accumuler en mémoire et n'écrire qu'à la fin, comme le faisait la
    # première version, fait perdre la nuit entière sur un plantage au 60e
    # département. On écrit donc après CHAQUE fascicule, et on sait reprendre.
    ap.add_argument("--reprendre", action="store_true",
                    help="sauter les départements déjà présents dans le CSV")
    # Sans `--reprendre`, le fichier est ouvert en mode « w » : un essai sur un
    # seul département ÉCRASE la passe complète. Il faut donc pouvoir écrire
    # ailleurs pour vérifier un correctif sans risquer des heures d'OCR.
    # IMPÉRATIF pour une lecture supplémentaire : sans `--sortie`, la nouvelle
    # passe ÉCRASE la précédente — et c'est justement la précédente qui fait la
    # moitié du résultat, la fusion valant plus que la meilleure passe seule.
    ap.add_argument("--sortie", type=Path, default=SORTIE,
                    help="fichier de sortie (défaut : cog1968/communes_1968.csv)")
    a = ap.parse_args()
    sortie_csv = a.sortie

    idx = index()
    if a.tous:
        cibles = sorted(idx.items())
    elif a.dep:
        if a.dep not in idx:
            raise SystemExit(f"Département {a.dep} absent de l'index.")
        cibles = [(a.dep, idx[a.dep])]
    else:
        raise SystemExit("Préciser --dep NN ou --tous.")

    deja = set()
    if a.reprendre and sortie_csv.exists():
        deja = {l["dep"] for l in csv.DictReader(sortie_csv.open(encoding="utf-8"))}
        cibles = [(d, p) for d, p in cibles if d not in deja]
        print(f"reprise : {len(deja)} départements déjà faits, "
              f"{len(cibles)} restants\n")
    neuf = not sortie_csv.exists() or (not a.reprendre)
    sortie = sortie_csv.open("w" if neuf else "a", newline="", encoding="utf-8")
    ecrivain = csv.DictWriter(sortie, fieldnames=CHAMPS)
    if neuf:
        ecrivain.writeheader()
        sortie.flush()

    bornes = bornes_cantonales()
    lignes = []
    for dep, pdf in cibles:
        import subprocess
        n = int(subprocess.run(["pdfinfo", str(pdf)], capture_output=True,
                               text=True).stdout.split("Pages:")[1].split()[0])
        if a.pages:
            d, _, f = a.pages.partition("-")
            pages = range(int(d), int(f or d) + 1)
        else:
            pages = range(1, n + 1)
        print(f"{dep} : {pdf.name[-18:]}, {n} pages, "
              f"{len(list(pages))} traitées, langue « {a.langue} »")
        with multiprocessing.Pool(a.jobs) as pool:
            for page, out in pool.imap_unordered(
                    traite, [(pdf, p, a.langue, a.dpi, a.psm) for p in pages]):
                for o in out:
                    o["dep"] = dep
                    o["insee"] = dep + o["insee3"]
                lignes += out
        # Écriture immédiate, fichier vidé sur le disque : ce qui est lu est
        # acquis, même si la machine s'arrête à la page suivante.
        du_dep = [l for l in lignes if l["dep"] == dep]
        for l in du_dep:
            b = bornes.get(dep, 99)
            l["hors_borne"] = ("oui" if l["canton"].isdigit()
                               and int(l["canton"]) > b else "")
        ecrivain.writerows(sorted(du_dep, key=lambda x: x["insee"]))
        sortie.flush()
        os.fsync(sortie.fileno())
        print(f"   {len(du_dep)} communes lues, écrites")

    if not lignes:
        raise SystemExit("Aucune ligne reconnue.")
    lignes.sort(key=lambda x: (x["dep"], x["insee"]))
    with sortie_csv.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=CHAMPS)
        w.writeheader()
        w.writerows(lignes)

    # Contrôle de monotonie : le code INSEE suit l'ordre alphabétique. Une
    # rupture signale un chiffre mal lu, sans avoir besoin d'un dictionnaire.
    ruptures = collections.defaultdict(int)
    for dep in {l["dep"] for l in lignes}:
        ordonne = [l for l in lignes if l["dep"] == dep]
        prec = ""
        for l in sorted(ordonne, key=lambda x: x["page"]):
            if prec and l["insee3"] < prec:
                ruptures[dep] += 1
            prec = l["insee3"]
    hb = [l for l in lignes if l["hors_borne"]]
    tous = {(l["dep"], l["canton"]) for l in lignes}
    sains = {(l["dep"], l["canton"]) for l in lignes if not l["hors_borne"]}
    print(f"\n{len(lignes)} communes, {len({l['dep'] for l in lignes})} départements")
    print(f"{len(tous)} cantons distincts, dont {len(tous) - len(sains)} "
          f"au-delà de la borne de 1940")
    if hb:
        print(f"   {len(hb)} lignes concernées — colonne hors_borne, "
              f"à trancher par le tableau II")
    if ruptures:
        print("\nruptures de l'ordre alphabétique (codes à revoir) :")
        for d, n in sorted(ruptures.items()):
            print(f"   {d} : {n}")
    print(f"\n{sortie_csv}")


if __name__ == "__main__":
    main()
