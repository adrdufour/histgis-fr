#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
extrait_1954.py — la composition cantonale de 1954, page par page

    python3 cog1954/extrait_1954.py                  # tout le volume
    python3 cog1954/extrait_1954.py --pages 96-120    # un essai
    python3 cog1954/extrait_1954.py --jobs 8          # parallelisme

Produit `cog1954/communes_1954.csv` : une ligne par commune, avec son
arrondissement et son canton au recensement de 1954.

Pourquoi ce script existe
-------------------------
Le trou cantonal 1943-1999 est le seul blocage structurel du projet : aucune
source ne donne la composition communale des cantons entre l'arrêt de TRF-GIS
en 1940 et le début du COG en 1999.

Le recensement de 1954 la donne, pour toute la métropole, à une date. Source en
domaine public : https://www.bnsp.insee.fr/ark:/12148/bc6p06z8sm1

Ce que porte le document
------------------------
Contrairement à ce qu'on pouvait craindre, la composition n'est pas implicite
dans la mise en page : elle est EXPLICITEMENT CODÉE. Chaque ligne de commune
porte deux colonnes numériques étroites — arrondissement et canton — glissées
entre la population de 1946 et le nom :

    Populat. | Populat. | Arr | Cant |              | Populat. |
     totale  |  totale  |     |      | COMMUNES     |  totale  | ...
      1936   |   1946   |     |      |              |   1954   |
    ---------|----------|-----|------|--------------|----------|
        202  |     148  |  1  |  15  | Goussancourt |    132   |
      6.981  |   6.031  |  5  |  16  | Guise        |  6.091   |

Et cette numérotation est CELLE DE LA BASE : vérifié sur 22 communes de
l'Aisne, 22 concordances. Aucune traduction de codes n'est nécessaire entre
1940 et 1954.

Le PDF n'a aucune couche texte — 958 pages d'images bitonales à 300 dpi. D'où
l'OCR. Le cas est favorable : imprimerie propre, fond blanc, colonnes nettes.

Prudence de lecture
-------------------
Ce script LIT, il ne tranche pas. Il sort ce qu'il croit avoir lu, avec le
numéro de page, pour que chaque ligne reste vérifiable sur l'image. Les
contrôles sont dans `controle_1954.py`, séparément — un extracteur qui juge sa
propre sortie ne trouve jamais rien.

Dépendances : poppler-utils (pdftoppm), tesseract-ocr, tesseract-ocr-fra.
"""

import argparse
import csv
import multiprocessing
import re
import subprocess
import sys
import tempfile
import unicodedata
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
DOSSIER = RACINE / "cog1954"
SORTIE = DOSSIER / "communes_1954.csv"
BRUT = DOSSIER / "ocr_brut"

CHAMPS = ["page", "dep", "dep_nom", "arr", "canton", "commune", "pop_1954",
          "ligne_brute"]


def pdf():
    c = sorted(DOSSIER.glob("*RP_1954*.pdf")) or sorted(DOSSIER.glob("*.pdf"))
    if not c:
        sys.exit(f"Aucun PDF dans {DOSSIER}.\n"
                 "À récupérer sur https://www.bnsp.insee.fr/ark:/12148/bc6p06z8sm1")
    return c[0]


def noms_departements():
    """Les noms servent à repérer les changements de département.

    On repère par le NOM et non par le code : l'en-tête imprime « AISNE (02) »
    mais l'OCR rend « (92) » une fois sur deux — deux chiffres isolés dans un
    filet sont ce qu'il lit le plus mal. Un nom de dix lettres, lui, résiste.
    """
    f = RACINE / "cantons" / "annexe_vii.csv"
    d = {}
    for l in csv.DictReader(f.open(encoding="utf-8")):
        if l["dep_nom"]:
            d[tuple(mots(l["dep_nom"]))] = (l["dep"], l["dep_nom"])
    return d


def sansaccent(s):
    s = unicodedata.normalize("NFD", (s or "").upper())
    return "".join(c for c in s if unicodedata.category(c) != "Mn")


def mots(s):
    """Découpe en MOTS, jamais en chaîne aplatie.

    C'est la leçon que le premier essai a rappelée durement : en cherchant le
    nom du département comme sous-chaîne, une page de l'Aisne est ressortie
    « Eure » et 72 lignes ont atterri dans l'Allier. « EURE » et « ALLIER »
    sont des sous-chaînes de mots courants — « Saint-Vallier » contient
    « ALLIER ». Un nom court se trouve partout si on le cherche n'importe où.

    La même erreur que « dignelesbainso » découpé en (« dignelesbain »,
    « so »), et que « le roule » confondu avec « roule ». Le mot est la seule
    unité qui ne mente pas.
    """
    return [m for m in re.findall(r"[A-Z]+", sansaccent(s)) if m]


# Le volume imprime les noms de 1954, pas ceux d'aujourd'hui. Quatre
# départements ont été rebaptisés depuis, et leurs pages étaient invisibles :
# elles allaient grossir le département précédent par héritage. Le 63 a ainsi
# avalé 426 lignes qui appartenaient au 64.
#
# C'est le même piège que « Santé » contre « Parc-de-Montsouris » à Paris :
# une source ancienne parle la langue de son temps.
ALIAS_1954 = {
    ("BASSES", "ALPES"):        ("04", "Basses-Alpes (1954)"),
    ("LOIRE", "INFERIEURE"):    ("44", "Loire-Inférieure (1954)"),
    ("BASSES", "PYRENEES"):     ("64", "Basses-Pyrénées (1954)"),
    ("SEINE", "INFERIEURE"):    ("76", "Seine-Inférieure (1954)"),
    ("SEINE", "ET", "OISE"):    ("78O", "Seine-et-Oise (1954)"),
    ("CORSE",):                 ("20", "Corse (1954)"),
    ("SEINE",):                 ("75", "Seine (1954)"),
}

# Ordre des départements dans le volume, qui suit la numérotation de 1954.
# Il sert de garde-fou : une page ne peut pas revenir en arrière.
def rang(dep):
    if dep == "78O":
        return 78.5
    if dep in ("2A", "2B"):
        return 20
    try:
        return float(dep)
    except ValueError:
        return 99


def entete_departement(ligne):
    """Rend (code, nom) si la ligne est un en-tête de département.

    Deux conditions, pas une. Les mots du nom doivent apparaître CONSÉCUTIFS
    dans la ligne — et la ligne doit ressembler à un en-tête : courte, et
    majoritairement en capitales, puisque le volume imprime ainsi ses titres
    courants. Sans la seconde condition, un nom de commune en capitales dans
    une ligne de tableau suffirait à faire basculer le département.
    """
    if len(ligne) > 70:
        return None
    lettres = [c for c in ligne if c.isalpha()]
    # Trois lettres au minimum, pas quatre : l'Ain, le Var et le Lot
    # s'écrivent en trois. Un seuil à quatre les perdait tous les trois,
    # silencieusement, et leurs pages seraient parties dans le département
    # précédent par héritage d'en-tête.
    if len(lettres) < 3 or sum(c.isupper() for c in lettres) < 0.6 * len(lettres):
        return None
    toks = mots(ligne)
    if not toks or len(toks) > 8:
        # Un en-tête est court. Le bruit de bord de scan, lui, est bavard :
        # « DRE MORALE RSS EURE PERLES POUR EE EEE IA ER RO » a fait basculer
        # une page de l'Aisne dans l'Eure, parce qu'il contient par hasard le
        # mot EURE et qu'il arrivait AVANT le vrai en-tête.
        return None
    meilleur = None
    for cles, v in list(DEPS.items()) + list(ALIAS_1954.items()):
        n = len(cles)
        # Aucun filtre sur la longueur des mots. Un garde-fou « au moins trois
        # lettres » rejetait le « et » de Eure-et-Loir, Saône-et-Loire,
        # Meurthe-et-Moselle, et le « d' » de Val-d'Oise et Côte-d'Or : ces
        # départements devenaient Eure, Saône, Meurthe, Oise, Côte. La
        # protection contre les faux positifs est ailleurs — dans l'exigence
        # de mots CONSÉCUTIFS et dans la forme d'en-tête.
        if n == 0:
            continue
        for i in range(len(toks) - n + 1):
            if tuple(toks[i:i + n]) == cles:
                # le nom le plus long l'emporte : « ALPES » ne doit pas
                # coiffer « HAUTES ALPES » ni « ALPES MARITIMES »
                if meilleur is None or n > meilleur[0]:
                    meilleur = (n, v)
    if meilleur is None:
        # Repli : le code imprimé entre parenthèses. Six départements — la
        # Haute-Marne, le Bas-Rhin, le Haut-Rhin, la Haute-Saône, la
        # Haute-Savoie, les Deux-Sèvres — se détectent sans faute sur du
        # texte propre : leur échec vient de l'OCR de leurs pages, pas de la
        # règle. Un second canal, même faible, vaut mieux qu'un héritage
        # silencieux. Score bas, donc toujours battu par le nom.
        m = re.search(r"\(\s*(\d{1,2})\s*\)", ligne)
        if m:
            c = f"{int(m.group(1)):02d}"
            for cles, v in DEPS.items():
                if v[0] == c:
                    return (*v, 1)
        return None
    # Un score, pour choisir la MEILLEURE ligne de la page et non la
    # première. Le code entre parenthèses — « AISNE (02) » — est la marque
    # de l'en-tête véritable ; le bruit ne l'a jamais.
    score = meilleur[0] + (3 if re.search(r"\(\s*\d{1,2}\s*\)", ligne) else 0)
    return (*meilleur[1], score)


# Une ligne de commune : deux entiers étroits, puis le nom, puis les
# populations. Le séparateur de colonnes est un filet que l'OCR rend
# indifféremment « | », « { », « } », « [ », « § » ou rien du tout — d'où la
# classe permissive plutôt qu'un caractère attendu.
# Jusqu'à trois caractères : l'OCR rend parfois un seul filet par « }{ ».
SEP = r"[|\[\]{}§!ijl/\\]{0,3}"
# Séparateur ENTRE deux colonnes chiffrées : n'importe quel caractère non
# alphanumérique, ou un groupe d'au plus deux lettres qui n'est pas suivi
# d'une troisième — « Ù », « L° » passent, « Cant » et « Ouest » non.
SEPNUM = r"(?:[^\dA-Za-zÀ-ÿ]|[A-Za-zÀ-ÿ]{1,2}(?![A-Za-zÀ-ÿ])){1,6}"
LIGNE = re.compile(
    # Les sosies de chiffres sont admis dans le CODE DE CANTON. « 2 3i » pour
    # « 2 31 » faisait perdre Tende, l'une des trois créations que l'annexe VII
    # garantit sur la période — donc l'un des trois étalons du chantier. Un
    # « i » pour un « 1 », un « O » pour un « 0 », un « S » pour un « 5 » : ce
    # sont les confusions constantes de l'OCR sur les petits chiffres isolés
    # dans un filet. La ligne brute est conservée, donc la substitution reste
    # vérifiable sur l'image.
    r"(?<![\d.])([\dOoSlIi]{1,2})\s+([\dOoSlIi]{1,2})\s*" + SEP +
    # Les parenthèses appartiennent au nom : le volume écrit « Haucourt (Le) »,
    # « Hérie-la-Viéville (Le) ». Les exclure perdait la commune entière.
    r"\s*([A-Za-zÀ-ÿ][A-Za-zÀ-ÿ'’\-\.\(\) ]{1,44}?)" +
    # Le RENVOI DE NOTE, « Tende (1) », « Fressinières (1) ». Il contient un
    # chiffre, que la classe du nom n'admet pas — et la lecture s'arrêtait à la
    # parenthèse. C'est ce qui faisait perdre Tende, l'un des trois étalons du
    # chantier : la commune la mieux documentée du volume était invisible à
    # cause d'un appel de note.
    #
    # Les communes portant un renvoi sont précisément celles que le volume
    # commente — donc les plus intéressantes. Les perdre était le pire des
    # biais possibles : celui qui écarte les cas remarquables.
    r"(?:\s*\(\d{1,2}\))?" +
    r"\s*[.,]\s*" +
    # Une lettre parasite est admise ENTRE LE NOM ET LE PREMIER CHIFFRE, comme
    # elle l'est déjà entre deux colonnes. C'est le même filet vertical mal
    # lu : « Ubraye. iii 100 17 85 », « Chabottonnes. S 50 48 »,
    # « Villars-Colmars. j 131 ». Exiger un chiffre immédiatement après le
    # point rejetait 18 % des lignes du volume — la moitié pour cette seule
    # raison. La règle devait valoir partout où deux colonnes se touchent, pas
    # seulement entre les nombres.
    SEPNUM + r"?" +
    # AU MOINS TROIS NOMBRES doivent suivre le nom. C'est ce qui sépare une
    # ligne de tableau d'une ligne de nomenclature, et c'est le seul critère
    # qui ait tenu à la mesure. Une commune traîne derrière elle six à huit
    # colonnes chiffrées, dont sa population répétée — « Bussiares. 112 112
    # 85 27 — 74 38 ». La nomenclature, elle, n'a rien après le nom :
    # « Neuilly-le-Réal ......... 2 25 » s'arrête au code du canton suivant.
    #
    # Deux critères plus intuitifs ont été essayés et mesurés faux : les
    # points de conduite (le « … » du bruit de scan les imite, cinq communes
    # perdues) et le nombre de couples de chiffres (les colonnes de
    # population en fabriquent, 78 communes perdues).
    # Immédiatement après le nom, et sans AUCUNE lettre entre eux. Sans cette
    # exigence, le regard portait jusqu'au bout de la ligne et retrouvait ses
    # trois nombres dans la colonne du canton SUIVANT : dix lignes de
    # nomenclature repassaient pour des communes, « Gannat » se voyait
    # attribuer le canton 02. Les colonnes d'un tableau sont contiguës ; un
    # mot entre deux nombres signifie qu'on a changé de bloc.
    # Un séparateur EXIGÉ entre les nombres. Avec un séparateur facultatif, le
    # moteur d'expressions rationnelles découpait « 2 25 » en « 2 », « 2 »,
    # « 5 » pour satisfaire la règle — trois nombres là où il n'y en avait que
    # deux. Une règle qu'un moteur peut satisfaire en coupant les chiffres en
    # deux ne mesure rien.
    # Entre deux colonnes de chiffres, l'OCR laisse parfois une lettre isolée :
    # le filet vertical du tableau, lu « Ù », « À », « L° ». Interdire toute
    # lettre rejetait dix-sept communes réelles de l'Aisne, dont Crouy et
    # Essômes-sur-Marne. Mais tout autoriser laissait repasser la
    # nomenclature.
    #
    # Ce qui sépare les deux : entre deux nombres d'un tableau il y a une
    # LETTRE ISOLÉE, dans la nomenclature il y a un MOT. On admet donc un ou
    # deux caractères alphabétiques d'affilée, jamais trois.
    r"(?=\d+(?:" + SEPNUM + r"\d+){2})" +
    # La population est FACULTATIVE, et c'est délibéré. « Harly. 6644 » est un
    # collage d'OCR entre deux colonnes : le nombre est faux et doit être
    # refusé. Mais l'arrondissement et le canton, eux, étaient parfaitement
    # lus. Perdre le rattachement cantonal d'une commune parce que sa
    # population est illisible serait le pire des échanges — c'est le canton
    # qu'on vient chercher, pas la population. La colonne vide sera signalée
    # par les contrôles.
    #
    # Le séparateur de milliers du volume est le point ; un nombre sans point
    # au-delà de trois chiffres est un collage, donc rejeté.
    r"(\d{1,3}(?:\.\d{3})*(?!\d))?"
)

# Une commune renvoyée à une autre : « Grand-Verly (voir Verly). » Ce n'est
# pas une ligne de données, et la prendre pour telle inventerait un
# rattachement.
RENVOI = re.compile(r"\(\s*voir\b", re.I)

# La ligne de TOTAL départemental a la forme d'une ligne de commune et se
# faisait lire comme telle — « TOTAL » ressortait en commune du canton 99.
TOTAUX = re.compile(r"\bTOTAL|\bENSEMBLE\b", re.I)

# La NOMENCLATURE CANTONALE, imprimée en tête de chaque département :
#
#   Bourbon-l'Archambault ... 2 01   Escurolles ......... 3 10
#   Cérilly ................ 1 02   Gannat ............. 3 11
#
# Ce sont des CANTONS, pas des communes, et le parseur de communes y voyait
# des rattachements qui n'existent pas — « Montlucon Cant. Est » rangé comme
# une commune du canton 10. Les points de conduite les trahissent : aucune
# ligne de tableau n'en porte.
#
# Ces lignes sont mises de côté plutôt que jetées : elles donnent les NOMS des
# cantons de 1954, que la base ne connaît que par leurs codes.
# Ce qui distingue une ligne de nomenclature d'une ligne de commune n'est PAS
# la ponctuation. Les points de conduite semblaient un bon signal — jusqu'à ce
# qu'on mesure : le « … » que l'OCR sème en bord de scan apparaît dans des
# lignes parfaitement ordinaires, et le critère faisait perdre cinq communes
# réelles de l'Aisne, dont Seraucourt-le-Grand et Vaux-Andigny. Un critère qui
# supprime des données pour se protéger du bruit coûte plus qu'il ne rapporte.
#
# Le vrai signal est structurel : la nomenclature imprime PLUSIEURS cantons
# par ligne, sur deux ou trois colonnes —
#
#   Bourbon-l'Archambault ... 2 01   Escurolles ......... 3 10
#
# — donc plusieurs couples arrondissement-canton. Une ligne de commune n'en a
# qu'un, par construction. C'est la forme du tableau qui tranche, pas sa
# typographie.
_COUPLE = re.compile(r"(?<![\d.])\d{1,2}\s+\d{2}(?![\d.])")


class NOMENCLATURE:
    """Détection de repli, appliquée SEULEMENT aux lignes que LIGNE a refusées.

    L'ordre compte : on essaie d'abord de lire la ligne comme une commune, on
    ne la classe qu'ensuite. Classer avant de lire, c'était écarter des
    communes sur une ressemblance.
    """

    @staticmethod
    def search(s):
        return bool(re.search(r"\.{3,}", s)) and len(_COUPLE.findall(s)) >= 1


SOSIES = str.maketrans({"O": "0", "o": "0", "S": "5", "l": "1", "I": "1",
                        "i": "1"})


def chiffre(s):
    """« 3i » -> 31. Les sosies de l'OCR ramenés à leur chiffre."""
    return int((s or "0").translate(SOSIES))


def nettoie_nombre(s):
    return re.sub(r"[^\d]", "", s or "") or ""


def nettoie_nom(s):
    s = re.sub(r"\s+", " ", (s or "").strip(" .,"))
    # « Capelle (La) » : la forme du volume, conservée telle quelle. La
    # remettre à l'endroit serait une interprétation, et la jointure sait
    # déjà traiter l'article.
    return s


def page_texte(chemin_pdf, p, dpi=300, langue="fra"):
    with tempfile.TemporaryDirectory() as tmp:
        base = Path(tmp) / "pg"
        subprocess.run(["pdftoppm", "-r", str(dpi), "-gray", "-f", str(p),
                        "-l", str(p), "-png", str(chemin_pdf), str(base)],
                       check=True, capture_output=True)
        img = next(Path(tmp).glob("pg*.png"), None)
        if img is None:
            return ""
        r = subprocess.run(["tesseract", str(img), "-", "-l", langue,
                            "--psm", "6"],
                           capture_output=True, text=True)
        return r.stdout


def traite(args):
    chemin_pdf, p, langue = args
    txt = page_texte(chemin_pdf, p, langue=langue)
    lignes, nomencl = [], []
    entete, meilleur_score = None, -1
    for brut in txt.splitlines():
        s = brut.strip()
        if not s:
            continue
        cand = None if FORCE else entete_departement(s)
        if cand and cand[2] > meilleur_score:
            entete, meilleur_score = (cand[0], cand[1]), cand[2]
        if RENVOI.search(s) or TOTAUX.search(s):
            continue
        m = LIGNE.search(s)
        if not m:
            if NOMENCLATURE.search(s):
                nomencl.append(s)
            continue
        if m:
            arr, cant, nom, pop = m.groups()
            lignes.append(dict(page=p, arr=chiffre(arr), canton=chiffre(cant),
                               commune=nettoie_nom(nom),
                               pop_1954=nettoie_nombre(pop),
                               ligne_brute=s[:160]))
    return p, entete, lignes, txt, nomencl


DEPS = {}
FORCE = None


def main():
    global DEPS, FORCE
    ap = argparse.ArgumentParser()
    ap.add_argument("--pages", default=None, help="ex. 96-120")
    ap.add_argument("--jobs", type=int, default=max(1, (multiprocessing.cpu_count() or 2) - 1))
    ap.add_argument("--langue", default="fra")
    ap.add_argument("--garder-ocr", action="store_true",
                    help="écrire le texte OCR brut dans cog1954/ocr_brut/")
    # Les recensements de 1962 et 1968 sont publiés en FASCICULES
    # DÉPARTEMENTAUX — 87 tomes pour 1968. Le département n'a alors plus à
    # être deviné : il est dans le titre du fascicule. `--dep 14` court-circuite
    # toute la détection d'en-tête, et avec elle les quatre pièges qu'elle a
    # coûtés sur le volume national de 1954.
    ap.add_argument("--dep", default=None,
                    help="forcer le département (fascicules départementaux)")
    ap.add_argument("--pdf", default=None,
                    help="chemin du PDF, si plusieurs sont présents")
    a = ap.parse_args()

    DEPS = noms_departements()
    src = Path(a.pdf) if a.pdf else pdf()
    FORCE = a.dep
    if a.dep:
        nom = next((v[1] for v in DEPS.values() if v[0] == a.dep), a.dep)
        print(f"département forcé : {a.dep} {nom} — "
              f"détection d'en-tête désactivée")
    # On VÉRIFIE avant de découper. La version précédente faisait
    # `.split("Pages:")[1]` sur la sortie de pdfinfo : quand pdfinfo échoue —
    # fichier absent, chemin erroné, PDF illisible — la sortie est vide et
    # l'erreur remontée était un IndexError, qui ne dit rien de la cause.
    # Un message d'erreur qui masque son origine coûte plus cher que le bogue.
    if not src.exists():
        sys.exit(f"Fichier introuvable : {src}")
    info = subprocess.run(["pdfinfo", str(src)], capture_output=True, text=True)
    if "Pages:" not in info.stdout:
        sys.exit(f"pdfinfo n'a pas su lire {src.name} :\n"
                 + (info.stderr.strip() or info.stdout.strip()
                    or "aucun message")
                 + "\n\nVérifier que le fichier est bien un PDF "
                   "(un téléchargement interrompu donne souvent une page HTML).")
    n = int(info.stdout.split("Pages:")[1].split()[0])
    if a.pages:
        d, _, f = a.pages.partition("-")
        pages = range(int(d), int(f or d) + 1)
    else:
        pages = range(1, n + 1)
    print(f"{src.name} : {n} pages ; traitement de {len(pages)}, "
          f"{a.jobs} processus, langue « {a.langue} »")

    if a.garder_ocr:
        BRUT.mkdir(exist_ok=True)

    # Le département est porté par l'en-tête de page. Une page dont l'en-tête
    # est illisible HÉRITE de la précédente — les pages se suivent dans
    # l'ordre du volume. On garde la trace de l'héritage : une composition
    # attribuée au mauvais département serait indétectable ensuite.
    resultats, nomenclature = {}, {}
    with multiprocessing.Pool(a.jobs) as pool:
        for i, (p, dep, lignes, txt, nomencl) in enumerate(
                pool.imap_unordered(traite,
                                    [(src, p, a.langue) for p in pages]), 1):
            resultats[p] = (dep, lignes)
            if nomencl:
                nomenclature[p] = nomencl
            if a.garder_ocr:
                (BRUT / f"p{p:04d}.txt").write_text(txt, encoding="utf-8")
            if i % 25 == 0 or i == len(pages):
                print(f"  {i}/{len(pages)} pages")

    # Garde-fou d'ORDRE, seconde version. Le volume suit la numérotation de
    # 1954 : la suite des départements ne peut que croître. Mais la première
    # version appliquait la règle GLOUTONNEMENT, page après page, et n'avait
    # aucun moyen de revenir sur une mauvaise amorce : les pages liminaires
    # citent des départements en vrac, la page 3 a fixé « 13 », et tout le
    # livre a ensuite été refusé pour cause de recul. Cinq départements au
    # lieu de quatre-vingts.
    #
    # On cherche donc la plus longue sous-suite croissante des candidats, et
    # on écarte ceux qui n'en font pas partie. Une amorce fautive isolée est
    # alors éliminée par le poids de tous les autres, au lieu de les
    # condamner. La contrainte est la même ; c'est la façon de l'appliquer
    # qui change tout.
    cands = [(p, resultats[p][0]) for p in sorted(resultats) if resultats[p][0]]
    garde = set()
    if cands:
        import bisect
        fins, pred, idx = [], [None] * len(cands), []
        for i, (_, d) in enumerate(cands):
            r = rang(d[0])   # `d` est le couple (code, nom)
            j = bisect.bisect_right(fins, r)
            if j == len(fins):
                fins.append(r)
                idx.append(i)
            else:
                fins[j] = r
                idx[j] = i
            pred[i] = idx[j - 1] if j else None
        k = idx[len(fins) - 1]
        while k is not None:
            garde.add(cands[k][0])
            k = pred[k]

    if FORCE:
        nom = next((v[1] for v in DEPS.values() if v[0] == FORCE), FORCE)
        for p in resultats:
            resultats[p] = ((FORCE, nom), resultats[p][1])
    courant, herite, sorties, reculs = None, 0, [], []
    for p in sorted(resultats):
        dep, lignes = resultats[p]
        if dep and p not in garde:
            reculs.append((p, courant[0] if courant else "-", dep[0]))
            dep = None
        if dep:
            courant = dep
        elif lignes:
            herite += 1
        for l in lignes:
            l["dep"] = courant[0] if courant else ""
            l["dep_nom"] = courant[1] if courant else ""
            l["entete_heritee"] = not dep
            sorties.append(l)

    with SORTIE.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=CHAMPS + ["entete_heritee"])
        w.writeheader()
        w.writerows(sorties)

    # La nomenclature est écrite à part, telle quelle. Elle n'est pas encore
    # exploitée : elle donne les NOMS des cantons de 1954, que la base ne
    # connaît que par leurs codes, et c'est un chantier en soi.
    if nomenclature:
        f = DOSSIER / "nomenclature_brute_1954.csv"
        with f.open("w", newline="", encoding="utf-8") as fh:
            w = csv.writer(fh)
            w.writerow(["page", "dep", "ligne"])
            for pg in sorted(nomenclature):
                d = resultats[pg][0]
                for l in nomenclature[pg]:
                    w.writerow([pg, d[0] if d else "", l])
        print(f"nomenclature cantonale mise de côté : "
              f"{sum(len(v) for v in nomenclature.values())} lignes, "
              f"{len(nomenclature)} pages -> {f.name}")

    vus = {l["dep"] for l in sorties if l["dep"]}
    print(f"\n{len(sorties)} lignes de commune, {len(vus)} départements")
    print(f"pages sans en-tête lisible, département hérité : {herite}")
    if reculs:
        print(f"en-têtes écartés car hors de la suite croissante : "
              f"{len(reculs)} — {reculs[:6]}")
    sans = [l for l in sorties if not l["dep"]]
    if sans:
        print(f"ATTENTION : {len(sans)} lignes sans département — "
              f"pages {sorted({l['page'] for l in sans})[:10]}")
    print(f"\n{SORTIE}")
    print("Contrôles : python3 cog1954/controle_1954.py")


if __name__ == "__main__":
    main()
