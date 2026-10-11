"""Ce qui a été LU dans les JO du complément, le 11 octobre 2026, et que
l'extracteur automatique (composition_complement.py) ne sait pas lire.

Trois sorties, toutes dans cantons/ :

  transferts_complement.csv   les rattachements de communes, une par ligne,
                              au format de transferts_legifrance.csv, plus la
                              date et le numéro du JO ;
  composition_complement.csv  l'extraction automatique (wikipedia/
                              composition_complement.csv), CORRIGÉE des
                              erreurs relevées à la relecture et COMPLÉTÉE des
                              compositions transcrites à la main ;
  corse_1975.csv              le tableau annexé à la loi n° 75-356 : toute la
                              Corse, canton par canton, au 15 mai 1975.

Chaque ligne transcrite à la main porte `appariement` calculé comme ailleurs
et `attribution = 'lecture'`. La phrase du JO qui la fonde est citée dans la
note (wikipedia/lecture_jo.md), pas ici.

    python3 cantons/wikipedia/lecture_jo.py        (depuis la racine)
"""
import csv
import re
import sys
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(RACINE / "cantons"))
import composition_jo as cj  # noqa: E402

viv = cj.noms_par_departement()
disp = cj.communes_disparues()
pref = cj.prefixes_par_departement(viv, disp)


def app(nom, dep):
    insee, ref, q = cj.apparie(nom, dep, viv, disp, pref)
    return insee, ref, q


LF = "https://www.legifrance.gouv.fr/jorf/jo/period/?datePubli={0}%2F{1}%2F{2}%20%3E%20{0}%2F{1}%2F{2}"


def url(jo):
    d = jo.split("_")[1]
    return LF.format(d[6:8], d[4:6], d[:4])


# ---------------------------------------------------------------------------
# 1. Transferts de communes entières
# (jo, signature, dep, commune, canton de départ, canton d'arrivée)
T = [
    ("JORF_19460504_104", "1946-05-03", "59", "Rainsars", "Trélon", "Avesnes-sur-Helpe-Sud"),
    ("JORF_19481028_256", "1948-10-26", "16", "Taponnat-Fleurignac", "Montembœuf", "La Rochefoucauld"),
    ("JORF_19490109_8", "1949-01-04", "01", "Saint-Sulpice", "Bâgé-le-Châtel", "Montrevel-en-Bresse"),
    ("JORF_19511117_272", "1951-11-14", "01", "Dompierre-sur-Chalaronne", "Thoissey", "Châtillon-sur-Chalaronne"),
    ("JORF_19511117_272", "1951-11-14", "11", "Saint-Couat-du-Razès", "Chalabre", "Limoux"),
    ("JORF_19511117_272", "1951-11-14", "64", "Salles-Mongiscard", "Salies-de-Béarn", "Orthez"),
    ("JORF_19620127_22", "1962-01-22", "43", "La Chapelle-Bertin", "Paulhaguet", "Allègre"),
    ("JORF_19640130_25", "1964-01-28", "95", "Méry-sur-Oise", "L'Isle-Adam", "Pontoise"),
    ("JORF_19640130_25", "1964-01-28", "95", "Butry-sur-Oise", "Pontoise", "L'Isle-Adam"),
    ("JORF_19640130_25", "1964-01-28", "78", "Achères", "Maisons-Laffitte", "Saint-Germain-en-Laye"),
    ("JORF_19640130_25", "1964-01-28", "76", "Gonfreville-l'Orcher", "Montivilliers", "Le Havre-III"),
    ("JORF_19691128_278", "1969-11-21", "78", "Toussus-le-Noble", "Bièvres (Essonne)", "Versailles-Sud"),
    ("JORF_19691128_278", "1969-11-21", "78", "Châteaufort", "Bièvres (Essonne)", "Versailles-Sud"),
]
rows = []
for jo, sig, dep, com, src, dst in T:
    insee, ref, q = app(com, dep)
    d = jo.split("_")[1]
    rows.append({"decret": "", "date": sig, "dep": dep, "commune": com, "insee": insee, "nom_ref": ref,
                 "appariement": q, "canton_source": src, "canton_destination": dst,
                 "legifrance_url": url(jo), "jo": jo,
                 "date_jo": f"{d[:4]}-{d[4:6]}-{d[6:8]}", "source": "lecture du JO"})
with (RACINE / "cantons" / "transferts_complement.csv").open("w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, list(rows[0]))
    w.writeheader()
    w.writerows(rows)
print(f"transferts : {len(rows)} ; non appariés : {[r['commune'] for r in rows if not r['insee']]}")

# ---------------------------------------------------------------------------
# 2. Compositions : extraction automatique, corrections, ajouts
auto = list(csv.DictReader((RACINE / "cantons" / "wikipedia" / "composition_complement.csv").open(encoding="utf-8")))
champs = list(auto[0])

# 2 a. corrections de lecture relevées à la relecture (nom lu -> nom vrai)
CORR = {
    ("Angers-Nord", "Pelouailles"): "Pellouailles-les-Vignes",
    ("Versailles-Sud", "Bue"): "Buc",
    ("Liévin-Nord-Ouest", "Gouyen-Gohelle"): "Gouy-Servins",
}
# « Croissy, Beaubourg » : une seule commune, Croissy-Beaubourg, coupée par l'OCR
ECARTER = {("Lagny", "Beaubourg")}

out = []
for r in auto:
    if (r["canton"], r["nom_texte"]) in ECARTER:
        continue
    vrai = CORR.get((r["canton"], r["nom_texte"]))
    if vrai:
        i, n, q = app(vrai, r["dep"])
        r.update(insee=i, nom_ref=n, dep_insee=i[:2], appariement=q + " (corrigé à la relecture)")
    out.append(r)


# 2 b. compositions transcrites à la main
def ajoute(jo, sig, dep, canton, communes):
    for c in communes:
        i, n, q = app(c, dep)
        out.append({"jo": jo, "decret": "", "date": sig, "dep": dep, "canton": canton, "nom_texte": c,
                    "insee": i, "nom_ref": n, "dep_insee": i[:2] if i else "", "appariement": q,
                    "attribution": "lecture", "legifrance_url": url(jo)})


M = [
    ("JORF_19490907_211", "1949-09-05", "46", "Sousceyrac", ["Sousceyrac", "Calviac", "Comiac", "Lamativie", "Lacam-d'Ourcet"]),
    ("JORF_19510914_217", "1951-09-13", "19", "Brive-Nord", ["Dampniat", "Ussac", "Varetz", "Venarsal"]),
    ("JORF_19510914_217", "1951-09-13", "19", "Brive-Sud", ["Cosnac", "La Chapelle-aux-Brocs", "Estivals", "Jugeals-Nazareth",
                                                             "Malemort-sur-Corrèze", "Noailles", "Nespouls"]),
    ("JORF_19560805_181", "1956-08-04", "37", "Tours-Ouest", ["Berthenay", "Joué-lès-Tours", "La Riche", "Saint-Genouph",
                                                              "Savonnières", "Villandry"]),
    ("JORF_19560805_181", "1956-08-04", "37", "Tours-Est", ["Larçay", "Montlouis-sur-Loire", "Saint-Avertin",
                                                            "Saint-Pierre-des-Corps", "Véretz", "La Ville-aux-Dames"]),
    ("JORF_19580227_49", "1958-02-26", "68", "Colmar-Sud", ["Sainte-Croix-en-Plaine"]),
    ("JORF_19580227_49", "1958-02-26", "68", "Mulhouse-Sud", ["Bruebach", "Brunstatt", "Didenheim", "Flaxlanden",
                                                              "Galfingue", "Heimsbrunn", "Morschwiller-le-Bas", "Zillisheim"]),
    ("JORF_19580227_49", "1958-02-26", "68", "Wittenheim", ["Kingersheim", "Lutterbach", "Pfastatt", "Reiningue",
                                                            "Richwiller", "Wittenheim"]),
    ("JORF_19640130_25", "1964-01-28", "59", "Marcq-en-Barœul", ["Bondues", "Marcq-en-Barœul"]),
    ("JORF_19640130_25", "1964-01-28", "93", "Blanc-Mesnil", ["Le Blanc-Mesnil"]),
    ("JORF_19640130_25", "1964-01-28", "78", "Celle-Saint-Cloud", ["La Celle-Saint-Cloud"]),
    ("JORF_19640130_25", "1964-01-28", "78", "Saint-Germain-en-Laye", ["Achères"]),
    ("JORF_19640130_25", "1964-01-28", "95", "Argenteuil-Sud", ["Bezons"]),
    ("JORF_19640130_25", "1964-01-28", "76", "Havre-III", ["Gonfreville-l'Orcher"]),
    ("JORF_19680810_188", "1968-08-01", "38", "Pont-de-Chéruy", ["Anthon", "Charvieu-Chavagneux", "Chavanoz", "Janneyrias",
                                                                 "Pont-de-Chéruy", "Villette-d'Anthon"]),
]
for jo, sig, dep, canton, communes in M:
    ajoute(jo, sig, dep, canton, communes)

with (RACINE / "cantons" / "composition_complement.csv").open("w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, champs)
    w.writeheader()
    w.writerows(out)
print(f"compositions : {len(out)} lignes, {len({(r['dep'], r['canton'], r['date']) for r in out})} cantons ; "
      f"non appariées : {[(r['canton'], r['nom_texte']) for r in out if not r['insee'] and r['appariement'] != 'fraction seule']}")

# ---------------------------------------------------------------------------
# 3. La Corse au 15 mai 1975 : tableau annexé à la loi n° 75-356
CANTONS_CORSE = [
    ("2A", "Ajaccio (cantons I à V)"), ("2A", "Bastelica"), ("2A", "Celavo-Mezzana"), ("2A", "Cruzini-Cinarca"),
    ("2A", "Deux-Sevi (Les)"), ("2A", "Deux-Sorru (Les)"), ("2A", "Santa-Maria-Siché"), ("2A", "Zicavo"),
    ("2A", "Bonifacio"), ("2A", "Figari"), ("2A", "Levie"), ("2A", "Olmeto"), ("2A", "Petreto-Bicchisano"),
    ("2A", "Porto-Vecchio"), ("2A", "Sartène"), ("2A", "Tallano-Scopamène"),
    ("2B", "Alto-di-Casaconi"), ("2B", "Bastia (cantons I à IV)"), ("2B", "Borgo"), ("2B", "Capobianco"),
    ("2B", "Campoloro-di-Moriani"), ("2B", "Conca-d'Oro (La)"), ("2B", "Fiumalto-d'Ampugnani"),
    ("2B", "Haut-Nebbio (Le)"), ("2B", "Sagro-di-Santa-Giulia"), ("2B", "San-Martino-di-Lota"), ("2B", "Vescovato"),
    ("2B", "Belgodere"), ("2B", "Calenzana"), ("2B", "Calvi"), ("2B", "L'Ile-Rousse"),
    ("2B", "Bustanico"), ("2B", "Castifao-Morosaglia"), ("2B", "Corte"), ("2B", "Ghisoni"), ("2B", "Moïta-Verde"),
    ("2B", "Niolu-Omessa"), ("2B", "Orezza-Alesani"), ("2B", "Prunelli-di-Fiumorbo"), ("2B", "Venaco"),
    ("2B", "Vezzani"),
]
L = (RACINE / "jorf_txt" / "JORF_19750516_113_col.txt").read_text(encoding="utf-8", errors="replace").split("\n")
debut = next(i for i, l in enumerate(L) if l.strip() == "Tableau annexe")
fin = next(i for i in range(debut, len(L)) if L[i].lstrip().startswith("LOI organique"))
BRUIT = re.compile(r"^(D[ée]partement|Arrondissement|CANTONS|DE\s+LA|\d+\s+Mai|JOURNAL|Tableau)", re.I)
texte = []
for l in L[debut:fin]:
    s = l.strip().replace("’", "'")
    if s and not BRUIT.match(s):
        texte.append(s)


def cle_canton(s):
    return cj.cle(s.split("(")[0]).replace("lile", "ile")


idx = {cle_canton(n): (d, n) for d, n in CANTONS_CORSE}
blocs, cur = [], None
for s in texte:
    m = re.match(r"^(.+?)\s*(?:\.{2,}|_{2,}|\s{3,}|,\s{3,}|(?<=\))\.\s)\s*(.*)$", s)
    tete = cle_canton(m.group(1)) if m else ""
    # « Prunelli-di-Fiumorbor... » : l'OCR ajoute une lettre au nom du canton
    trouve = idx.get(tete) or next((v for k, v in idx.items() if len(tete) > 8 and tete.startswith(k)), None)
    if m and trouve:
        cur = [trouve, m.group(2)]
        blocs.append(cur)
    elif cur is not None:
        prec = cur[1]
        # fin de ligne sans virgule : césure (minuscule ensuite) ou nouveau nom
        if prec and not re.search(r"[,.\-]\s*$", prec):
            cur[1] = prec + ("" if s[:1].islower() else ", ") + s
        else:
            cur[1] = prec + " " + s
# Lectures fautives du tableau, relevées une à une sur le texte : virgule
# perdue entre deux noms, césure de fin de ligne prise pour un séparateur,
# abréviation, coquille de l'OCR.
REPARE_CORSE = [
    ("Poggiolo Renno", "Poggiolo, Renno"), ("Sorio San-Gavino-di-Tenda", "Sorio, San-Gavino-di-Tenda"),
    ("Galéria Manso", "Galéria, Manso"), ("Soota", "Sotta"), ("St-Florent", "Saint-Florent"),
    ("Santa, Lucia-di-Mercurio", "Santa-Lucia-di-Mercurio"), ("San, Gavino-di-Fiumorbo", "San-Gavino-di-Fiumorbo"),
    ("Santa, Lucia", "Santa-Lucia"), ("San, Lorenzo", "San-Lorenzo"),
]
corse = []
for (dep, canton), liste in blocs:
    liste = re.sub(r"\s*-\s*", "-", liste)
    for faux, vrai in REPARE_CORSE:
        liste = liste.replace(faux, vrai)
    for n in re.split(r"\s*[,.]\s+|\s*\.\s*$|\.\s*(?=[A-Z])", liste):
        n = n.strip(" .,")
        if not n:
            continue
        if n.endswith("(L')"):
            n = "L'" + n[:-4].strip()
        i, r, q = app(n, dep)
        corse.append({"dep": dep, "canton_1975": canton, "nom_texte": n, "insee": i, "nom_ref": r,
                      "appariement": q, "jo": "JORF_19750516_113", "acte": "loi n° 75-356 du 15 mai 1975, tableau annexe"})
with (RACINE / "cantons" / "corse_1975.csv").open("w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, list(corse[0]))
    w.writeheader()
    w.writerows(corse)
vus = {b[0][1] for b in blocs}
print(f"corse 1975 : {len(blocs)} cantons sur {len(CANTONS_CORSE)}, {len(corse)} communes ; "
      f"manquants : {[n for _, n in CANTONS_CORSE if n not in vus]} ; "
      f"non appariées : {[c['nom_texte'] for c in corse if not c['insee']]}")
