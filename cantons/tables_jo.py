"""Les tables analytiques annuelles du Journal officiel, 1941-1990 : tout ce
qu'elles disent des cantons.

Entrée : jorf_txt/TABLE_ANALYTIQUE_JORF_AAAA_col.txt (pdftotext -layout, puis
cantons/jorf_colonnes.py), produits depuis sources/JORF/tables/*.pdf.

Méthode. La table est une suite d'articles qui finissent tous par un renvoi à
la page du JO (« p. 2585. »). On découpe le texte sur ces renvois ; un article
qui parle de canton ET d'un changement (rattachement, création,
sectionnement, chef-lieu, limites, dénomination…) est gardé ; le reste — juges
de paix, greffiers, cantonniers, élections — est écarté par motif. Dans chaque
article gardé, on cherche :
  * la commune et son canton d'arrivée (« Bio au canton de Gramat (Lot) »,
    « Commune des Hauts-de-Chée (Meuse). Rattachement au canton de… ») ;
  * le département, entre parenthèses ou après « département de » ;
  * la date de l'acte quand elle est donnée (« D. 19 janv. 1955 »).

Sorties :
  cantons/tables_jo_actes.csv     un article par ligne, avec ce qu'on a pu en tirer
  cantons/tables_jo_couverture.csv  pour chaque année : la table a-t-elle été lue,
                                    combien d'articles cantonaux elle porte

    python3 cantons/tables_jo.py          (depuis la racine)
"""
import csv
import difflib
import re
import sys
import unicodedata
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
TXT = RACINE / "jorf_txt"


def sans_accents(s):
    s = unicodedata.normalize("NFD", s)
    return "".join(c for c in s if unicodedata.category(c) != "Mn")


def cle(s):
    return re.sub(r"[^a-z0-9]+", " ", sans_accents(s.lower())).strip()


# --- départements, noms d'époque compris, et formes inversées des tables
DEP = {
    "ain": "01", "aisne": "02", "allier": "03", "basses alpes": "04", "alpes de haute provence": "04",
    "hautes alpes": "05", "alpes maritimes": "06", "ardeche": "07", "ardennes": "08", "ariege": "09",
    "aube": "10", "aude": "11", "aveyron": "12", "bouches du rhone": "13", "calvados": "14", "cantal": "15",
    "charente": "16", "charente inferieure": "17", "charente maritime": "17", "cher": "18", "correze": "19",
    "corse": "20", "corse du sud": "2A", "haute corse": "2B", "cote d or": "21", "cotes du nord": "22",
    "cotes d armor": "22", "creuse": "23", "dordogne": "24", "doubs": "25", "drome": "26", "eure": "27",
    "eure et loir": "28", "finistere": "29", "gard": "30", "haute garonne": "31", "gers": "32",
    "gironde": "33", "herault": "34", "ille et vilaine": "35", "indre": "36", "indre et loire": "37",
    "isere": "38", "jura": "39", "landes": "40", "loir et cher": "41", "loire": "42", "haute loire": "43",
    "loire inferieure": "44", "loire atlantique": "44", "loiret": "45", "lot": "46", "lot et garonne": "47",
    "lozere": "48", "maine et loire": "49", "manche": "50", "marne": "51", "haute marne": "52",
    "mayenne": "53", "meurthe et moselle": "54", "meuse": "55", "morbihan": "56", "moselle": "57",
    "nievre": "58", "nord": "59", "oise": "60", "orne": "61", "pas de calais": "62", "puy de dome": "63",
    "basses pyrenees": "64", "pyrenees atlantiques": "64", "hautes pyrenees": "65",
    "pyrenees orientales": "66", "bas rhin": "67", "haut rhin": "68", "rhone": "69", "haute saone": "70",
    "saone et loire": "71", "sarthe": "72", "savoie": "73", "haute savoie": "74", "seine": "75",
    "paris": "75", "seine inferieure": "76", "seine maritime": "76", "seine et marne": "77",
    "seine et oise": "78", "yvelines": "78", "deux sevres": "79", "somme": "80", "tarn": "81",
    "tarn et garonne": "82", "var": "83", "vaucluse": "84", "vendee": "85", "vienne": "86",
    "haute vienne": "87", "vosges": "88", "yonne": "89", "territoire de belfort": "90", "belfort": "90",
    "essonne": "91", "hauts de seine": "92", "seine saint denis": "93", "val de marne": "94",
    "val d oise": "95", "guadeloupe": "971", "martinique": "972", "guyane": "973", "reunion": "974",
}


def dep_de(nom):
    k = cle(nom)
    # formes inversées des tables : « Rhin (Bas-) », « Alpes (Hautes-) », « Marne (Haute-) »
    m = re.match(r"^(\w[\w ]*?) (bas|basses|haut|haute|hautes)$", k)
    if m:
        k = m.group(2) + " " + m.group(1)
    k = re.sub(r"^(le|la|les|l) ", "", k)
    return DEP.get(k, "")


# --- découpage en articles
RENVOI = re.compile(r"p\.\s*(?:N\.\s*C\.\s*)?[\dOolI][\d OolI.]{0,6}\d?(?:\s*\([^)]{0,40}\))?\s*[.;]")
CANTON = re.compile(r"\bcantons?\b|\bcantonale?s?\b", re.I)
GARDE = re.compile(r"rattach|sectionn|cr[ée]ation|cr[ée][ée]|divis|chef-?\s*lieu|limites?\b|d[ée]limit|"
                   r"d[ée]nomination|nom\b|noms\b|transf[ée]r|d[ée]tach|suppression|supprim|modifi|r[ée]union|"
                   r"circonscriptions? (?:territoriales?|cantonales?|administratives?)", re.I)
ECARTE = re.compile(r"\bjuges?\b|greff|tribuna|cantonn|conseill|[ée]lect|scrutin|notair|huissi|\bpaix\b|"
                    r"d[ée]l[ée]gation sp[ée]ciale|commissaire|percept|syndica|association|gendarm|brigade|"
                    r"m[ée]decin|pharmac|v[ée]t[ée]rinaire|\b[ée]coles?\b|enseignement|remembrement|bois[ée]es|"
                    r"forestier|agricole|reconstruction|sinistr|\bvins?\b|appellation|\bimp[ôo]ts?\b|"
                    r"recensement|\bzones?\b|calamit|\btarifs?\b|\bprix\b|salaire", re.I)

MOIS = {"janv": 1, "jan": 1, "fev": 2, "fevr": 2, "mars": 3, "avr": 4, "avril": 4, "mai": 5, "juin": 6,
        "juil": 7, "juill": 7, "aout": 8, "sept": 9, "oct": 10, "nov": 11, "dec": 12}
DATE = re.compile(r"\b(?:D|Arr|L|D[ée]cret|Arr[êe]t[ée]|Loi)\.?\s*(?:n[°o]\s*[\d-]+\s*)?du\s+(\d{1,2}|1er)\s*(?:er)?\s+([a-zéèûô]+)\.?\s+(\d{4})", re.I)
DATE2 = re.compile(r"\b(?:D|Arr|L)\.\s*(\d{1,2}|1er)\s*(?:er)?\s+([a-zéèûô]+)\.?\s+(\d{4})", re.I)

COMMUNE_AU = re.compile(
    r"(?:(?:Commune|Communes)\s+(?:de\s+|d['’]\s*|des\s+|du\s+)?)?"
    r"(?P<com>[A-ZÉÈÂÎÔ][\w'’\-]*(?:[\s\-][\w'’\-]+){0,5}?)\s*,?\s+au\s+canton\s+(?:de\s+la\s+|de\s+l['’]\s*|d['’]\s*|du\s+|des\s+|de\s+)"
    r"(?P<canton>[A-ZÉÈÂÎÔ][\w'’\-]*(?:[\s\-][\w'’\-]+){0,5}?)\s*(?:\((?P<dep>[^)]{2,40})\))?\s*[,.;]")
COMMUNE_RATT = re.compile(
    r"Communes?\s+(?:de\s+|d['’]\s*|des\s+|du\s+)?(?P<com>[A-ZÉÈÂÎÔ][\w'’\-]*(?:[\s\-][\w'’\-]+){0,5}?)\s*"
    r"\((?P<dep>[^)]{2,40})\)\s*\.\s*Rattachement\s+au\s+canton\s+(?:de\s+la\s+|de\s+l['’]\s*|d['’]\s*|du\s+|de\s+)"
    r"(?P<canton>[A-ZÉÈÂÎÔ][\w'’\-]*(?:[\s\-][\w'’\-]+){0,5}?)\s*[.,;(]")
DEP_PAREN = re.compile(r"\(([A-ZÉÈÂÎÔ][^()]{2,40})\)")
DEP_TEXTE = re.compile(r"d[ée]partement\s+(?:de\s+la\s+|de\s+l['’]\s*|d['’]\s*|du\s+|des\s+|de\s+)([A-ZÉÈÂÎÔ][\w'’\- ]{2,35}?)(?=[,.;)]|\s+p\.|\s+—|\s+-\s)")


def nettoie(t):
    t = re.sub(r"­\s*\n\s*", "", t)                   # trait de césure invisible en fin de ligne
    t = t.replace("­", "").replace("’", "'")
    t = re.sub(r"-\s*\n\s*(?=[a-zà-ÿ])", "", t)      # césure
    t = re.sub(r"-\s*\n\s*", "-", t)                  # trait d'union de nom composé
    t = re.sub(r"Ann[ée]e\s+\d{4}\s+TABLE\s+ANALYTIQUE.*?\n", " ", t)
    return re.sub(r"\s+", " ", t)


def date_de(txt, annee):
    for rx in (DATE, DATE2):
        for m in rx.finditer(txt):
            j = 1 if m.group(1).lower().startswith("1er") else int(m.group(1))
            km = sans_accents(m.group(2).lower()).rstrip(".")
            mo = MOIS.get(km) or MOIS.get(km[:4]) or MOIS.get(km[:3])
            a = int(m.group(3))
            if mo and abs(a - annee) <= 1:
                return f"{a}-{mo:02d}-{j:02d}"
    return ""


def nature(t):
    t = sans_accents(t.lower())
    if re.search(r"au canton|rattachement au canton|rattach", t) and re.search(r"commune|au canton", t):
        return "rattachement"
    if re.search(r"chef-?\s*lieu", t):
        return "chef_lieu"
    if re.search(r"sectionn|creation|cree|divis", t):
        return "creation"
    if re.search(r"nom|denomination", t):
        return "denomination"
    if re.search(r"limite|delimit|circonscription", t):
        return "limites"
    return "autre"


# --- listes par département (1960-1990 surtout) :
#   Cantons.
#   Création. — Création et modification de cantons dans les départements suivants :
#   Ain. — D. 82-77 du 25 janv. 1982, p. 371 (rectif., p. 472).
#   - Allier. - D. 85-82 du 23 janv. 1985, p. 978.
# Seul l'en-tête parle de cantons : chaque entrée, prise isolément, n'est
# qu'un département et un décret. On lit donc la liste ligne à ligne, à la
# suite de l'en-tête, tant que les lignes sont des entrées.
ENTETE_LISTE = re.compile(r"cantons?\b.{0,60}?\bdans\s+les\s+d[ée]parte\s*-?\s*(?:ments)?", re.I)
ENTREE = re.compile(r"^\s*[-–—]?\s*(?P<dep>[A-ZÉÈÂÎÔ][\w'’\- ]{1,40}?)\s*(?:\([^)]{0,60}\))?\s*\.?\s*[-–—]*\s*(?P<reste>(?:D|Décr|Décret)\b.*)$")
# en tête de ligne, l'objet de la sous-rubrique : « Création. — Pyrénées-Atlantiques (modif. …). — D. 75-872 »
SOUS_RUBRIQUE = re.compile(r"^\s*(?P<o>Cr[ée]ation|Modification|Suppression|D[ée]limitation|Changements? de noms?)"
                           r"(?:\s+et\s+\w+)?\s*[.:]\s*[-–—]+\s*", re.I)


def dep_flou(nom):
    """Département d'une entrée de liste, OCR compris (« Sai'the », « Saône-et-Loife »)."""
    d = dep_de(nom)
    if d:
        return d
    k = re.sub(r"^(le|la|les|l) ", "", cle(nom))
    sans = {x.replace(" ", ""): x for x in DEP}
    m = difflib.get_close_matches(k.replace(" ", ""), list(sans), 1, 0.82)
    return DEP[sans[m[0]]] if m else ""
NUM_DECRET = re.compile(r"\b(\d{2})\s*-\s*(\d{1,4})\b")


# Rubrique « Cantons. — Essonne. Création et délimitation. — D. 67-589 du… »,
# suivie de « Hauts-de-Seine. Création et délimitation. — D. 67-590 du… » :
# l'entrée nomme un département, un objet, un décret.
ENTETE_CANTONS = re.compile(r"^\s*(?:Cantons?|CANTONS?)\s*(?:\.|:)?\s*(?:[-–—]+\s*(?P<suite>.*))?$")
ENTREE_OBJET = re.compile(r"^\s*[-–—]?\s*(?P<dep>[A-ZÉÈÂÎÔ][\w'’\- ]{1,40}?)\s*\.\s*"
                          r"(?P<objet>[^.—]{0,60}(?:cr[ée]ation|d[ée]limitation|limites|modification|suppression|nom)[^—]{0,60}?)"
                          r"\s*[-–—]+\s*(?P<reste>(?:D|Décr|Décret)\b.*)$", re.I)


def listes(lignes, annee):
    """Entrées des listes « … de cantons dans les départements suivants »
    et des rubriques « Cantons. — <département>. Création… — D. … »."""
    out = []
    i = 0
    while i < len(lignes):
        bloc = " ".join(lignes[i:i + 3]).replace("­", "")
        mc = ENTETE_CANTONS.match(lignes[i])
        if ENTETE_LISTE.search(re.sub(r"\s+", " ", lignes[i] + " " + (lignes[i + 1] if i + 1 < len(lignes) else ""))):
            stricte, tolere, j = False, 12, i + 1
        elif mc:
            # sous « Cantons. », seule une entrée qui dit son objet est prise ;
            # la première peut être sur la ligne même de l'en-tête
            stricte, tolere = True, 3
            j = i if mc.group("suite") else i + 1
        else:
            i += 1
            continue
        tete = re.sub(r"\s+", " ", bloc)
        objet = ("denomination" if re.search(r"changement de nom|d[ée]nomination", tete, re.I)
                 else "creation" if re.search(r"cr[ée]ation", tete, re.I)
                 else "modification")
        rate, premier_rate, vu_sr = 0, j, False
        while j < len(lignes) and rate <= tolere:
            ligne = lignes[j]
            if j == i and mc:
                ligne = mc.group("suite") or ""
            # « … (modif. D. 13 juil. 1973). — » / « D. 75-872 du … » : le décret à la ligne
            joint = bool(re.search(r"[-–—]\s*$", ligne)) and j + 1 < len(lignes)
            if joint:
                ligne = ligne + " " + lignes[j + 1].strip()
            sr = SOUS_RUBRIQUE.match(ligne)
            if sr and not ENTREE_OBJET.match(ligne):
                vu_sr = True
                o = sr.group("o").lower()
                objet = ("denomination" if "nom" in o else "creation" if o.startswith("cr")
                         else "suppression" if o.startswith("sup") else "limites")
                ligne = ligne[sr.end():]
            m = (ENTREE_OBJET.match(ligne) or (ENTREE.match(ligne) if vu_sr else None)) if stricte \
                else (ENTREE.match(ligne) or ENTREE_OBJET.match(ligne))
            if m and dep_flou(m.group("dep")):
                if "objet" in m.groupdict() and m.group("objet"):
                    o = m.group("objet")
                    objet = ("denomination" if re.search(r"\bnom", o, re.I)
                             else "creation" if re.search(r"cr[ée]ation", o, re.I)
                             else "suppression" if re.search(r"suppression", o, re.I) else "limites")
                reste = m.group("reste")
                # l'entrée peut courir sur deux lignes (date ou page renvoyées)
                k = j + 1 + joint
                while k < len(lignes) and not re.search(r"p\.\s*\d", reste) and k <= j + 2:
                    reste += " " + lignes[k].strip()
                    k += 1
                nd = NUM_DECRET.search(reste)
                pg = re.search(r"p\.\s*(\d[\d ]*\d|\d)", reste)
                out.append({"annee": annee, "page_jo": pg.group(1).replace(" ", "") if pg else "",
                            "date_acte": date_de(reste, annee), "nature": objet,
                            "dep": dep_flou(m.group("dep")), "dep_nom": m.group("dep").strip(),
                            "commune": "", "canton": "",
                            "decret": f"{nd.group(1)}-{nd.group(2)}" if nd else "",
                            "texte": (lignes[j].strip() + " " + reste)[:300], "source": "liste"})
                rate = 0
                j = k
                continue
            if ligne.strip():
                rate += 1
                if rate == 1:
                    premier_rate = j
            j += 1
        # on reprend à la première ligne qui n'était pas une entrée : elle
        # peut ouvrir une autre liste (« Cantons. » puis « Création. — … dans
        # les départements suivants : »)
        i = max(premier_rate if rate > tolere else j, i + 1)
    return out


def main():
    rows, couv = [], []
    for annee in range(1941, 1991):
        f = TXT / f"TABLE_ANALYTIQUE_JORF_{annee}_col.txt"
        if not f.exists():
            couv.append({"annee": annee, "table_lue": "non", "articles_cantonaux": 0, "rattachements": 0,
                         "entrees_de_liste": 0})
            continue
        brut = f.read_text(encoding="utf-8", errors="replace")
        en_liste = listes(brut.splitlines(), annee)
        rows += en_liste
        texte = nettoie(brut)
        debut, articles = 0, []
        for m in RENVOI.finditer(texte):
            articles.append((texte[debut:m.end()], m.group(0)))
            debut = m.end()
        vus = set()
        n_art = n_ratt = 0
        for art, renvoi in articles:
            # on ne garde que la fin de l'article : un renvoi peut clore une longue
            # énumération, dont seul le dernier membre lui appartient
            tail = art[-700:]
            # « Bio au canton de Gramat (Lot), p. 3170. » : dans une liste de
            # rattachements, le mot « rattachement » n'est que dans l'en-tête de
            # la rubrique ; la tournure « X au canton de Y » suffit.
            au_canton = bool(COMMUNE_AU.search(tail) or COMMUNE_RATT.search(tail))
            if not CANTON.search(tail) or not (GARDE.search(tail) or au_canton) or ECARTE.search(tail[-300:]):
                continue
            page = re.sub(r"[^\d]", "", renvoi.replace("O", "0").replace("o", "0").replace("l", "1").replace("I", "1"))
            cles = (cle(tail[-250:]), page)
            if cles in vus:
                continue
            vus.add(cles)
            n_art += 1
            trouves = list(COMMUNE_RATT.finditer(tail)) + list(COMMUNE_AU.finditer(tail))
            base = {"annee": annee, "page_jo": page, "date_acte": date_de(tail, annee),
                    "nature": nature(tail), "texte": tail[-400:].strip()}
            if trouves:
                for t in trouves:
                    dn = t.group("dep") or ""
                    if not dep_de(dn):
                        mm = DEP_PAREN.findall(tail[t.end():t.end() + 80]) or DEP_TEXTE.findall(tail)
                        dn = mm[0] if mm else dn
                    com = re.sub(r"^(Rattachements?(?: de communes)?\s*[.:—-]*\s*|Communes?\s+(de|d'|des|du)\s+)", "", t.group("com")).strip()
                    rows.append(dict(base, nature="rattachement", commune=com, canton=t.group("canton").strip(),
                                     dep_nom=dn.strip(), dep=dep_de(dn)))
                    n_ratt += 1
            else:
                mm = DEP_PAREN.findall(tail[-300:]) or DEP_TEXTE.findall(tail)
                dn = next((x for x in mm if dep_de(x)), mm[-1] if mm else "")
                rows.append(dict(base, commune="", canton="", dep_nom=dn.strip(), dep=dep_de(dn)))
        couv.append({"annee": annee, "table_lue": "oui", "articles_cantonaux": n_art, "rattachements": n_ratt,
                     "entrees_de_liste": len(en_liste)})

    for r in rows:
        r.setdefault("source", "article")
        if "decret" not in r:
            nd = re.search(r"\bD\.\s*(?:n[°o]\s*)?(\d{2})\s*-\s*(\d{1,4})\b", r["texte"])
            r["decret"] = f"{nd.group(1)}-{nd.group(2)}" if nd else ""
    champs = ["annee", "page_jo", "date_acte", "nature", "dep", "dep_nom", "commune", "canton", "decret",
              "source", "texte"]
    with (RACINE / "cantons" / "tables_jo_actes.csv").open("w", newline="", encoding="utf-8") as fo:
        w = csv.DictWriter(fo, champs)
        w.writeheader()
        w.writerows(rows)
    with (RACINE / "cantons" / "tables_jo_couverture.csv").open("w", newline="", encoding="utf-8") as fo:
        w = csv.DictWriter(fo, list(couv[0]))
        w.writeheader()
        w.writerows(couv)
    import collections
    print(len(rows), "lignes ;", dict(collections.Counter(r["nature"] for r in rows)))
    print("sans département :", sum(1 for r in rows if not r["dep"]))


if __name__ == "__main__":
    main()
