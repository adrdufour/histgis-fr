"""Extrait les compositions de cantons des JO du complément Wikipédia avec
l'extracteur déjà éprouvé, `cantons/composition_jo.py`, sans le modifier et
sans toucher à ses sorties.

`composition_jo.py` choisit les numéros du JO à lire d'après le registre
(`decrets_cantonaux.csv`) : il ne lit un JO que si un décret du registre y est
publié. Les actes du complément n'y sont pas, et ne doivent pas y être avant
d'avoir été lus. On lui donne donc un registre de substitution, bâti depuis
`decrets_complement.csv`, et des sorties à part.

Un acte qui touche plusieurs départements (la salve du 28 janvier 1964, la
Seine-et-Oise) y figure une fois par département : c'est ce qui permet au
vote de l'extracteur de rendre chaque canton à son département. Pour la
Seine-et-Oise, les départements sont ceux d'aujourd'hui (78, 91, 92, 93, 94,
95), parce que les noms sont appariés contre la nomenclature de GEOFLA.

    python3 cantons/wikipedia/composition_complement.py      (depuis la racine)

Sorties : cantons/wikipedia/composition_complement.csv
          cantons/wikipedia/composition_complement_rejets.csv
"""
import csv
import sys
import tempfile
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(RACINE / "cantons"))
import composition_jo as cj  # noqa: E402

NOMS_DEP = {
    "01": "AIN", "11": "AUDE", "16": "CHARENTE", "19": "CORREZE", "26": "DROME", "33": "GIRONDE",
    "37": "INDRE-ET-LOIRE", "38": "ISERE", "43": "HAUTE-LOIRE", "46": "LOT", "49": "MAINE-ET-LOIRE",
    "59": "NORD", "62": "PAS-DE-CALAIS", "64": "BASSES-PYRENEES", "67": "BAS-RHIN", "68": "HAUT-RHIN",
    "69": "RHONE", "76": "SEINE-MARITIME", "77": "SEINE-ET-MARNE", "80": "SOMME", "83": "VAR",
    "78": "SEINE-ET-OISE", "91": "SEINE-ET-OISE", "92": "SEINE-ET-OISE", "93": "SEINE-ET-OISE",
    "94": "SEINE-ET-OISE", "95": "SEINE-ET-OISE",
}

champs = ["date_signature", "date_publication_jo", "decret", "dep_code", "dep_nom_epoque", "objet",
          "cantons_cites_dans_le_titre", "legifrance_id", "legifrance_url", "deja_repere",
          "texte_integral_sur_legifrance"]
lignes = []
for a in csv.DictReader((RACINE / "cantons" / "decrets_complement.csv").open(encoding="utf-8")):
    if a["categorie"] != "composition" or not a["date_publication_jo"]:
        continue
    if a["date_signature"] < "1959":
        continue   # transcrits à la main, voir plus bas
    num = a["decret"] if a["decret"].startswith("n° ") and "-" in a["decret"] else ""
    for dep in a["deps"].split():
        lignes.append({"date_signature": a["date_signature"], "date_publication_jo": a["date_publication_jo"],
                       "decret": num, "dep_code": dep,
                       # sans numéro, l'extracteur ancre sur « Département (décret » :
                       # forme absente des JO de ces années, le vote décidera.
                       "dep_nom_epoque": NOMS_DEP.get(dep, ""),
                       "objet": a["objet"], "cantons_cites_dans_le_titre": "",
                       "legifrance_id": a["cle"], "legifrance_url": a["url"] or a["cle"],
                       "deja_repere": "non", "texte_integral_sur_legifrance": "non"})

tmp = Path(tempfile.mkstemp(suffix=".csv")[1])
with tmp.open("w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, champs)
    w.writeheader()
    w.writerows(lignes)

# --- Deux adaptations aux JO de 1962-1968, faites ICI et non dans composition_jo.py
#
# 1. Ces décrets écrivent « Canton de Taverny (mêmes arrondissement et
#    département), composé des communes de … ». La parenthèse porte le nom du
#    canton au-delà des 55 caractères que tolère `CANTON` ; on la retire avant
#    segmentation. Elle n'apporte rien : l'arrondissement est toujours le même.
# 2. « composé des communes de » (sans « les ») n'était pas prévu par `AMORCE`,
#    qui attendait « composé des … les communes ». L'article devient facultatif.
#
# Les décrets de 1946-1958 ont d'autres tournures (« ce canton comprendra en
# outre le territoire des communes de », « b) Les communes de ») : trop peu
# nombreux pour une règle, ils sont transcrits à la main dans
# lecture_jo_compositions.csv.
import re  # noqa: E402

_nettoie = cj.nettoie
PAREN = re.compile(r"\s*\((?:m[êe]mes|arrondissement|d[ée]partement)[^)]{0,160}\)", re.I)


# 3. Les JO de 1964 écrivent l'article en minuscule : « le Pecq », « le Raincy »,
#    « la Queue-en-Brie », « et de la Celle-Saint-Cloud ». `liste_communes`
#    n'accepte qu'un nom à majuscule et perdait ces communes sans un mot.
ARTICLE = re.compile(r"(,\s*|\bet\s+(?:de\s+|du\s+)?|\bdes\s+communes\s+de\s+|\bcommune\s+de\s+)"
                     r"(le|la|les)\s+(?=[A-ZÀ-Ý])")
DU = re.compile(r"\bcommunes?\s+du\s+(?=[A-ZÀ-Ý])")


# 5. « … Grigny et Viry-Châtillon. 1092 JOURNAL OFFICIEL Art. 16 … » : le
#    folio de page, collé après le point, empêchait `FIN` de voir la fin de la
#    liste, qui débordait sur l'article suivant. Et « et de Houilles »,
#    « et d'Achères » : le « de » laissé devant le nom le faisait rejeter.
FOLIO = re.compile(r"\s*(?:\b\d{1,2}\s+\w+\s+\d{4}\s+)?\b\d{2,5}\s+JOURNAL\s+OFFICIEL(?:\s+DE\s+LA\s+R[ÉE]PUBLIQUE\s+FRAN[ÇC]AISE)?"
                   r"|\s*\bDE,?\s+LA\s+R[ÉE]PUBLIQUE\s+FRAN[ÇC]AISE\s+\d{2,5}\b", re.I)
ET_DE = re.compile(r"\bet\s+(?:de\s+|d[’']\s*)(?=[A-ZÀ-Ý])")


def nettoie(t):
    t = PAREN.sub("", _nettoie(t))
    t = FOLIO.sub(" ", t)
    t = ET_DE.sub("et ", t)
    t = ARTICLE.sub(lambda m: m.group(1) + m.group(2).capitalize() + " ", t)
    return DU.sub(lambda m: m.group(0).replace(" du ", " de Le "), t)


cj.nettoie = nettoie

# 4. Un canton urbain s'écrit « composé de la partie de la ville de Valence …
#    ainsi que des communes de Beaumont-lès-Valence, … » ou, en 1962, « … et
#    les communes de Sallaumines, … ». La liste vient APRÈS la fraction, et
#    `AMORCE` ne la voyait pas : Valence-Sud, Corbeil-Essonnes-Sud, les cantons
#    de Lens et de Liévin sortaient « fraction seule », sans leurs communes.
AMORCE2 = re.compile(r"(?:ainsi\s+que\s+(?:de\s+)?(?:des|les)|\b[Ee]t\s+(?:les|des))\s+communes\s+"
                     r"(?:suburbaines\s+)?(?:de\s+|d[’'])")
_liste = cj.liste_communes


def liste_communes(texte, alerte=None):
    out = _liste(texte, alerte)
    m = AMORCE2.search(texte or "")
    if m:
        out += [n for n in _liste("comprenant les communes de " + texte[m.end():], alerte) if n not in out]
    return out


cj.liste_communes = liste_communes
cj.AMORCE = re.compile(
    r"(?:comprennent|comprenant|comprend|comportant|compos[ée]e?s?\s+d[eu]s?)\s+"
    r"(?:(?:l(?:es?|a|')\s*\d?\s*)?(?:anciennes?\s+|nouvelles?\s+)?communes?"
    r"(?:\s+associ[ée]es?)?)\s*"
    r"(?:de\s+|d[’']|du\s+|des\s+)",
    re.I)

cj.DECRETS = tmp
sys.argv = [sys.argv[0],
            "--sortie", str(RACINE / "cantons" / "wikipedia" / "composition_complement.csv"),
            "--rejets", str(RACINE / "cantons" / "wikipedia" / "composition_complement_rejets.csv")]
cj.main()
tmp.unlink()

# --- Reprise des sorties
#  * un nom de canton qui a avalé la fin du précédent (« Maisons-Laffitte ;
#    Canton de Chatou ») est ramené à son dernier « Canton de … » ;
#  * un « nom de commune » qui est en fait un nom de canton du même décret
#    (« Versailles-Nord » lu dans la liste de Juvisy, débordement sur l'article
#    suivant) est écarté — et compté.
sortie = RACINE / "cantons" / "wikipedia" / "composition_complement.csv"
rows = list(csv.DictReader(sortie.open(encoding="utf-8")))
DERNIER = re.compile(r".*[Cc]anton\s+(?:de\s+l'|de\s+la\s+|d'|du\s+|des\s+|de\s+)", re.S)
for r in rows:
    r["canton"] = DERNIER.sub("", r["canton"]).strip(" ;,")
noms_cantons = {(r["jo"], cj.cle(r["canton"])) for r in rows}
gardes = [r for r in rows if not (r["appariement"] == "aucun" and (r["jo"], cj.cle(r["nom_texte"])) in noms_cantons)]
print(f"\nreprise : {len(rows) - len(gardes)} nom(s) de canton lus comme communes, écartés")
with sortie.open("w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, list(rows[0]))
    w.writeheader()
    w.writerows(gardes)
