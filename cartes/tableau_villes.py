#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
tableau_villes.py — le tableau de suivi des 315 villes à découper

    python3 cartes/tableau_villes.py        # réécrit cartes/sorties/villes_decoupage_cantonal.xlsx

Trois feuilles :
  * Villes — une ligne par ville : fractions, partage en base, lignes tracées,
    périodes couvertes et non couvertes, ancres, verdict de la recette de `98`,
    entrées de `a_inscrire_en_base.md`, remarques, fractions et cantons ;
  * Fractions — une ligne par fraction, canton et nom de canton, avec ses dates ;
  * Lignes tracées — `cartes/coupes_ville.csv`, note comprise.

Tout est recalculé depuis la base, les deux CSV, la recette de `98` (passage à
blanc) et `a_inscrire_en_base.md` — SAUF la colonne « Remarques », écrite à la
main : elle est relue dans le fichier existant et recopiée telle quelle ; une
ville qui n'en a pas prend celle de REMARQUES ci-dessous.

Les dates de « Fractions » et « Lignes tracées » sont écrites en texte ISO
(1801-01-01) : Excel ne sait pas représenter une date d'avant 1900, et
Valenciennes commence en 1801.

Pas d'openpyxl sur ce poste : le classeur est écrit à la main (zipfile), comme
le premier tableau du 26 septembre 2026. Réécrit le 27 septembre 2026.
"""

from __future__ import annotations

import csv
import datetime as dt
import json
import re
import subprocess
import sys
import zipfile
import xml.etree.ElementTree as ET
from pathlib import Path
from xml.sax.saxutils import escape

ICI = Path(__file__).resolve().parent
RACINE = ICI.parent
SORTIE = ICI / "sorties" / "villes_decoupage_cantonal.xlsx"

# Remarques des villes tracées après le premier tableau. Une remarque déjà
# présente dans le fichier l'emporte toujours.
REMARQUES = {
    "05061": "Décret 82-78 (1982, 5 cantons) ; régime 1973-1982 (décret 73-651, 4 cantons) tracé sans ancres, absent de la ville en base.",
    "05023": "Décret 73-651 ; ligne de l'ancienne limite de Puy-Saint-Pierre pour 1974-1988 (commune associée comptée deux fois en base).",
    "04112": "Décret 85-127 (1985) ; régime 1973-1985 (décret 73-714) tracé sans ancres ; ligne de Saint-Martin-les-Eaux pour 1974-1980.",
    "04070": "Décret 73-714 ; régime 1973-1985 tracé à part (ville absente de la base à ces dates).",
    "03095": "Décret 85-82 (1985) ; commune entière sans canton de 1973 à 1985.",
    "06004": "Décret 85-143 (1985) et régime 1973-1985 (décret 73-811) ; Antibes-Sud / Antibes-Centre à vérifier.",
    "06027": "Décret 85-143 (1985) et régime 1982-1985 (décret 82-79).",
    "06029": "Décret 85-143 (1985) et régime 1973-1985 (décret 73-811) ; îles de Lérins ancrées au Centre.",
    "59350": "Gaudillère : 1858-1889 (5 cantons) et 1889-1941 (8 cantons), ancres datées ; morceau sud du Sud-Est au Nord-Est puis à l'Est (correction d'Adrien). Fin du régime de 1889 et limites de 1994 à vérifier.",
    "59512": "Gaudillère 1892-1982 (A-B, C-D) ; Roubaix-Ouest absent de la ville en base de 1968 à 1982.",
    "59599": "Gaudillère 1895 (A-B, B-C), supposé valable jusqu'en 2013 ; Nord-Est absent de la ville en base de 1968 à 1982.",
    "71076": "Gaudillère 1876-1986 : la Saône ; Chalon-Ville / Chalon-Périphérie (décret 73-769) absents de la base, non tracés.",
    "59606": "Gaudillère : découpage de 1801, supposé valable jusqu'en 2013 ; Est absent de la ville en base de 1968 à 1982.",
    "59650": "Gaudillère 1892, prolonge A-B de Roubaix ; la base met aussi une fraction de Roubaix-Ouest de 1892 à 1941, que le texte ne connaît pas.",
    "72181": "Gaudillère 1801-1892 dans le Mans d'avant 1855 : la Sarthe et la Cité (Le Mans-2 ouest + Cité, Le Mans-1 est) ; 1855-1892 : terres annexées = Le Mans-3 (précision d'Adrien). 1892-1967 : Sarthe, détour de la Cité (rue Barbier, pont du Greffier) et voie ferrée de Paris : Le Mans-1 nord-est (confirmé par Adrien), Le Mans-3 sud. Base vide de 1941 à 1982.",
    "63113": "Gaudillère 1801-1982 (A-B, C-D, E-F) : Est, Nord, Sud, Sud-Ouest ; ravin de Chanturgue, chemin de Haut-de-Chanturgue et rue de Coumon approchés par les chemins. Régime de 1982 à tracer.",
    "49328": "Gaudillère : la Loire, îles au Nord (rive sud de tous les bras), sauf l'île de l'est (16 ha) au Sud (correction d'Adrien), de 1963 (Nord-Est → Allonnes) à 2013 ; avant 1963, limite Nord-Est / Nord-Ouest non donnée.",
    "73065": "Gaudillère 1860-1973 (Boisse … faubourg Montmélian) sur la commune d'avant 1961 ; 1961-1973 : ancienne limite, terres annexées (Bissy, Chambéry-le-Vieux) sans fraction en base (La Motte-Servolex).",
    "66136": "Gaudillère : enclave urbaine de Perpignan-Ouest (1870-1973) ; décret 73-819 : Perpignan-I à VI dans la ville (1973-1982), VI = l'ancienne enclave. Numéros de la base supposés = I à VI. Régime de 1982 (9 cantons) à tracer.",
    "65440": "Gaudillère 1801-1853 et 1853-1973 (Nord à l'ouest, arbitrage d'Adrien) ; décret 73-729 : Tarbes-I à V dès 1973 (la limite de 1853 reste l'axe). Numéros de la base supposés = I à V.",
    "19272": "Gaudillère : la Corrèze (Nord à l'ouest, Sud à l'est), 1808-1982 ; décret 82-120 : Tulle-Urbain-Nord / Sud dès 1982, chemin du Monteil approché de hameau en hameau.",
    "53147": "Gaudillère : la Mayenne (Est rive gauche, Ouest rive droite), de 1802 à 2013 ; en base, l'atome entier dans l'Ouest en 1968-1973.",
    "79191": "Gaudillère (sans date) : Niort-1 / Niort-2 dans la commune d'avant 1964, tracée pour 1870-1964 ; décret 73-673 : Nord, Ouest, Est dès 1973. Rien entre 1964 et 1973.",
    "77288": "Décret du 28 octobre 1975 (limite dès 1976) ; Gaudillère concorde sauf à l'est (rue d'Estienne-d'Orves), où l'on suit le décret. Limite de 1870-1976 non tracée.",
    "77284": "Décret du 28 octobre 1975 (JO 9 novembre 1975), même énumération que Gaudillère : canal de l'Ourcq par le sud de sa boucle, puis déversoir vers la Marne. Fractions en base à partir de 1994.",
    "62570": "Décret 84-1236 (1985), même énumération que Gaudillère : Rouvroy à l'est, Avion à l'ouest ; D50E2 (ex-C.D. 50 E) reprise hors réseau. Fractions en base à partir de 1992.",
    "62160": "Gaudillère 1958 (Nord / Sud, gardée jusqu'en 2013), décret 84-1236 (Nord-Ouest, 1985) et décret 91-217 (Le Portel, 1992). En base, le Nord de 1968-1973 est rangé sous « Calais-Nord-Ouest ».",
    "62498": "Gaudillère 1902 (base : 1904) : route de La Bassée, avenues Bollaert et Maës, route d'Arras ; fin posée en 1949 (Lens-Ouest devient Liévin), à confirmer.",
    "60175": "Décret 73-668 : l'Oise, bras principal ; île Saint-Maurice à Creil-Sud (précision d'Adrien). Fractions en base seulement à partir de 1998.",
    "13055": "Gaudillère 1801-1886 (six cantons), 1886-1901 (huit) et 1901-1973 (douze) : quinze lignes. Limite par l'Huveaune vers l'amont et numéros 6/7, 8/9, 10/11 à confirmer sur le plan (variante aval prête). Traverse de Chaudelle introuvable. Fin de la limite est par les talwegs des vallons. Rien en base de 1941 à 1973.",
    "17306": "Gaudillère : limite Est / Ouest (rue des Chevreuils, boulevard de la Perche, boulevard Champlain, rue Font-de-Cherves, boulevard de la Grandière), posée 1985-2013. Place du Marché sans nom dans la BD TOPO ; allées Pastourelle et Raguideau longées par leur pied. Rien en base de 1973 à 1985.",
    "21231": "Gaudillère 1907-1973 : A-B (route de Langres, Godrans, Berbisey, cours du Parc) et C-D (rue de Corcelles, Liberté, Jeannin, boulevard de Strasbourg), qui partagent la rue Bossuet. Nord et Est sûrs par les contacts ; Sud (sud-est) et Ouest (sud-ouest) par les noms, à confirmer sur le plan. Les huit cantons de 1973 restent à tracer.",
    "22278": "Gaudillère : le Gouédic vers l'aval (jusqu'au Gouët), puis les rues jusqu'au boulevard de l'Atlantique ; posé 1870-1982. Le morceau sud touche Ploufragan (canton 1) sur 5,9 km. Les trois cantons de 1982 restent à tracer.",
    "33063": "Gaudillère 1801-1973 : cinq lignes A-B à I-J de la limite à la Garonne (axe du Jardin public en ligne droite, la Devèze couverte en ligne droite sur 423 m) et la Garonne ; rive droite au 5e de 1865 à 1888, puis 7e. Ancienne limite de Caudéran posée 1965-1973 (déduction : Caudéran au 2e). Numéros du nord au sud, à confirmer sur le plan. 2e et 6e absents de la base en 1968-1973. Les huit cantons de 1982 restent à tracer.",
    "27229": "Gaudillère 1863-1870 et décret 82-56 : limite du Nord posée 1870-2013 ; les trois limites de 1982 (Est, Sud, Ouest) posées 1982-2013. Rue de la Résistance et pont Eiffel introuvables (205 m de raccord). La ligne ne passe pas par les points triples (Parville, Gravigny).",
    "28085": "Gaudillère 1928-1940, posé 1870-1973 (mêmes cantons Nord et Sud ; le décret de 1973 reprend la suite à l'est). Départ au milieu de la rue du Parc, sur la limite de Lucé. Prolongement de l'avenue Jean-Mermoz par la route de Paris (1,8 km). Les quatre cantons de 1973 restent à tracer.",
    "30007": "Gaudillère 1958-1986 : limite Est / Ouest (Gardon, quai du 8-Mai, rues, Gardon), posée 1858-1973 ; la vieille ville est à l'Ouest (déduction). Rue du Canal identifiée par la géométrie. Limite Nord-Est / Sud-Est de 1973 à tracer (décret 73-721).",
    "31555": "Gaudillère 1801-1973 : la Garonne (bras ouest, 203 ha d'îles au Sud), A-B (route de Launaguet, canal du Midi sur 2,3 km, Capitole, place Saint-Pierre) et C-D (Pont-Neuf, rue de Metz, avenue Jean-Chaubet). Centre et Ouest absents de la base en 1968-1973.",
    "34032": "Gaudillère 1801-1973 : une ligne, de la D28 (route de Bessan) à l'ex-RN 9 (D609) par le Pont-Vieux. Chemin de Marseillan et rue du Pont-Vieux identifiés par la géométrie. Béziers-1 au nord (confirmé par Adrien).",
    "34172": "Gaudillère 1801-1973 : contour fermé du 1er canton (Écusson, 29 ha), A-B (route de Ganges) et C-D par l'ancienne voie ferrée de Paulhan (plan de Gaudillère), dont 283 m en ligne droite. Limite d'avant le chemin de fer non décrite.",
    "35238": "Gaudillère 1801-1973 (texte titré Reims par erreur) : A-B et la Vilaine, quatre cantons, ancres par les noms (plan). Prolongement de la rue Tronjolly : 262 m en ligne droite. Communes rurales de 1870-1941 décalées en base.",
    "37261": "Gaudillère 1801-1956 : la Loire par l'axe du bras nord (îles au Centre) et A-B (rue de la Victoire, boulevards Béranger et Heurteloup). A-B prolongée à l'ouest par le bras sud jusqu'à La Riche pour laisser l'île Simon au Centre (déduction, 16,5 ha). 1956-1973 reste à tracer.",
    "38053": "Décret 85-92 (JO 25 janvier 1985), que Gaudillère abrège. Canal du Mouturier absent de la BD TOPO : pris pour le cours aval du Bion (à confirmer). Route d'Italie = avenue Professeur-Tixier (C.D. 54). Stade Berliat, mur sud du CES Pré-Bénit.",
    "38169": "Décret 85-92 (JO 25 janvier 1985), que Gaudillère abrège. Rue Yves-Farge interrompue : 87 m franchis en ligne droite. Boulevard Paul-Langevin suivi par sa chaussée nord-est. La base n'a les fractions qu'à partir de 1998.",
    "42218": "Gaudillère : A-B (1857-1973, Grand'rue et D1082) et C-D (1860-1973), quatre cantons. Anciennes limites de Terrenoire, Saint-Victor et Rochetaillée posées pour 1969-1973 : morceaux sans ancre (double compte de l'ANR).",
    "43157": "Gaudillère et décret du 2 août 1973 : limite Nord-Ouest / Sud-Est, posée 1802-1973. Faubourg Saint-Jean, place du Pallet, rue Ronzon ; prolongement par le sentier et le chemin du 18-Août (à confirmer). Les cinq cantons de 1973 restent à tracer.",
    "44109": "Gaudillère 1801-1908 (cinq lignes, six cantons) et 1908-1973 (7e canton = ancien Chantenay au sud des boulevards Ingres et Chabas ; Doulon au 2e). Numéros d'après le plan de 1908-1973.",
    "49007": "Gaudillère 1801-1964 : la Maine (prolongée par la Mayenne, île Saint-Aubin au Nord-Est : déduction) et C-D. Sud-Est = entre la Maine et C-D ; à confirmer (Trélazé touche le morceau du Nord-Est).",
    "51454": "Gaudillère 1889-1973 : A-B, C-D (voie ferrée de Laon), E-F. Numéros déduits des communes rurales ; droite vers le chemin de Beine et prolongement de l'avenue d'Épernay (1,7 km) à confirmer. 1870-1889 reste à tracer.",
    "54395": "Gaudillère 1801-1879 (A-B, C-D) et 1879-1973 (canton Sud en deux tronçons). Parallèles au sud de la rue des Fabriques et au nord de la rue de la Salle approchées à 30 m ; après le port de Bonsecours, canal jusqu'au bord (déduction). Nancy-Est absent de la base en 1968-1973.",
    "57463": "Gaudillère (sans date) : bras mort de la Moselle ; C-D du pont Saint-Georges à la Seille, puis la Seille vers le sud. Posé 1801-1941 (C-D prolongé par la Seille après 1910) ; communes annexées dans leur canton de 1870. Période à confirmer.",
    "59178":"Gaudillère 1922 : la Scarpe canalisée (moyenne Scarpe puis Scarpe) et C-D (Clocher-Saint-Pierre … rue de Sin-le-Noble) ; Ouest / Nord / Sud, 1922-1982. En base, Ouest absent de la ville en 1968-1982.",
    "95585":"Décret 85-153 du 31 janvier 1985 = Gaudillère : boulevard du Général-de-Gaulle … place Suzanne-Valadon (D125, D316 = ex-R.N. 16 déviation) ; Nord-Est / Sud-Ouest, 1985-2013 ; décret de janvier 1976 : Sarcelles-Saint-Brice (ouest) / Sarcelles-Est, 1976-1985, tracé sans ancre (absent de la base).",
    "94037":"Décret 84-1242 = Gaudillère : avenue Pasteur … rue Albert-Guilpin ; ouest à Arcueil, est au Kremlin-Bicêtre, 1984-2013. Entière à Arcueil 1976-1985 (absent de la base).",
    "92048": "Décret 67-590 du 20 juillet 1967 = Gaudillère (vers 1986) : Savignac … rue de Belgique ; la partie nord-est (98 ha) à Issy-les-Moulineaux-Ouest, 1967-2013. Base : fractions seulement depuis 1998.",
    "86194":"Gaudillère (sans date) : Santos-Dumont … avenue Jacques-Cœur, d'un bord à l'autre ; posé 1862-1973 (fixation des limites Nord/Sud → Poitiers-1 à 5). En base, l'atome entier dans le Sud en 1968-1973.",
    "85191":"Décret 73-773 et Gaudillère (même limite, noms de 1995) : ancienne R.N. 160 (D760 en ville, D160 vers Les Essarts), rues des Sables, Poincaré, Clemenceau, du Président-de-Gaulle, Pompidou ; 1973-2013.",
    "84007":"Gaudillère (plan 1869-1870) : Rhône (du plan), rues Ferruce … Guillaume-Puy, avenue Pierre-Sémard (= avenue de Marseille, supposé), route de Marseille, chemin de la Signone (= ancien chemin de Noves, incertain). Posé 1801-1933 ; Avignon-Est et -Ouest (1933) absents de la base.",
    "83137":"Gaudillère 1901-1964 (plan de la loi du 8 juillet 1901, p. 647) : A-B et E-F suivent la voie ferrée vers l'est ; C-D monte au Faron (route du Faron, forts, caserne du Centre, Favières). 8327/8328 pris pour les 1er/2e cantons. Base : 1901-1941 seulement.",
    "78646":"Gaudillère 1801-1964 : A-D (D10, route de Saint-Cyr, rue de l'Indépendance-Américaine, cour du palais en ligne droite, avenue de Paris) et B-C (rue des Réservoirs, boulevard du Roi). Base : 1870-1941 seulement.",
    "76540":"Gaudillère 1801-1982 (plan de la loi du 27 novembre 1887, numéros lus sur le plan) : boulevards, B-H, G-H, F-H, I-J, la Seine ; île Lacroix au 6e (bras du Pré au Loup). F-H de 1801-1887 approchée par celle de 1887. Base : 1870-1941 seulement.",
    "76351":"Gaudillère 1888-1964 (plan de la loi du 7 juillet 1888, numéros lus sur le plan) ; Graville au 4e après 1919, Bléville (1953) et Sanvic (1955) au 6e (déduction). 7627-7629 pris pour les 1er-3e cantons. Base vide de 1941 à 1992.",
    "60057": "Gaudillère 1958 (horizon 1986 = fin de sa connaissance, prolongé à 2013) et décret 82-63 (Nord-Ouest ; ouest par les rivières de Saint-Quentin et de Saint-Just, puis l'Avelon). Aucune fraction en base de 1941 à 1998.",
}

# Remarques de REMARQUES révisées après coup (la ville a été reprise) : elles
# remplacent celle du fichier. N'y mettre que des remarques écrites par ce
# script, jamais une remarque d'Adrien.
REVISEES = {"60057", "62160", "79191", "19272", "65440", "66136", "49328", "72181"}

NS = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
NSR = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"


# ---------------------------------------------------------------------------
# lecture
# ---------------------------------------------------------------------------

def psql(sql: str) -> str:
    r = subprocess.run(["psql", "-d", "histgis", "-qAt", "-v", "ON_ERROR_STOP=1"],
                       input=sql, capture_output=True, text=True, cwd=RACINE)
    if r.returncode:
        sys.exit(r.stderr)
    return r.stdout


SQL_DONNEES = r"""
SET search_path TO histgis, public;
WITH a_couper AS (SELECT insee_geofla insee FROM atom JOIN atom_geom USING (atom_id)
                   WHERE insee_geofla IS NOT NULL AND fraction AND atom_id LIKE '%#%'
                   GROUP BY 1 HAVING count(*) > 1),
fr AS (SELECT a.insee_geofla insee, a.atom_id, g.source FROM atom a JOIN atom_geom g USING (atom_id)
        WHERE a.insee_geofla IN (SELECT insee FROM a_couper) AND a.fraction AND a.atom_id LIKE '%#%'),
mb AS (SELECT fr.insee, fr.atom_id, m.unit_id, lower(m.periode) d, upper(m.periode) f
         FROM fr JOIN membership m ON m.atom_id = fr.atom_id AND m.niveau = 'canton'),
nm AS (SELECT mb.*, coalesce(uv.nom, u.nom) nom,
              greatest(mb.d, lower(uv.periode)) d2, least(mb.f, upper(uv.periode)) f2
         FROM mb LEFT JOIN unit u ON u.unit_id = mb.unit_id AND u.niveau = 'canton'
         LEFT JOIN unit_version uv ON uv.unit_id = mb.unit_id AND uv.periode && daterange(mb.d, mb.f))
SELECT json_build_object(
 'villes', (SELECT json_agg(json_build_object(
      'insee', c.insee,
      'nom', (SELECT n.nom FROM noms_geofla n WHERE n.insee = c.insee LIMIT 1),
      'nfr', (SELECT count(*) FROM fr WHERE fr.insee = c.insee),
      'geofla', (SELECT count(*) FROM fr WHERE fr.insee = c.insee AND fr.source <> 'fraction_cog'),
      'cog', (SELECT count(*) FROM fr WHERE fr.insee = c.insee AND fr.source = 'fraction_cog'),
      'iris', (SELECT count(*) FROM iris_ville i WHERE i.code_insee = c.insee
                 OR (c.insee = '75056' AND i.code_insee LIKE '751%')
                 OR (c.insee = '69123' AND i.code_insee LIKE '693%')
                 OR (c.insee = '13055' AND i.code_insee LIKE '132%'))) ORDER BY c.insee)
      FROM a_couper c),
 'memb', (SELECT json_agg(json_build_object('insee', insee, 'atom', atom_id, 'unit', unit_id, 'nom', nom,
                 'd', coalesce(d2, d), 'f', coalesce(f2, f)) ORDER BY insee, atom_id, coalesce(d2, d))
            FROM nm));
"""


def recette() -> dict[str, str]:
    """La recette §5a de `98`, jouée à blanc : insee -> verdict."""
    r = subprocess.run(["psql", "-q", "-d", "histgis", "-f", "sql/98_coupe_ville.sql"],
                       capture_output=True, text=True, cwd=RACINE)
    out = {}
    for l in r.stdout.splitlines():
        m = re.match(r"\s*(\d[\dAB]\d{3})\s*\|\s*\d{4}-\d\d-\d\d\s*\|(.*)", l)
        if m:
            out[m.group(1)] = m.group(2).split("|")[-1].strip()
    return out


def a_inscrire() -> dict[str, list[str]]:
    """`a_inscrire_en_base.md` : insee -> numéros des entrées de la ville."""
    out, courant = {}, None
    for l in (ICI / "a_inscrire_en_base.md").read_text(encoding="utf-8").splitlines():
        m = re.match(r"## .*\((\d[\dAB]\d{3})\)\s*$", l)
        if m:
            courant = m.group(1)
            continue
        if l.startswith("## "):
            courant = None
        m = re.match(r"### (\d+)\.", l)
        if m and courant:
            out.setdefault(courant, []).append(m.group(1))
    return out


def lire_xlsx(path: Path) -> dict[str, list[dict]]:
    """Le classeur existant, feuille par feuille, en dictionnaires colonne -> valeur."""
    z = zipfile.ZipFile(path)
    n = {"m": NS}
    ss = []
    if "xl/sharedStrings.xml" in z.namelist():
        for si in ET.fromstring(z.read("xl/sharedStrings.xml")).findall("m:si", n):
            ss.append("".join(t.text or "" for t in si.iter(f"{{{NS}}}t")))
    wb = ET.fromstring(z.read("xl/workbook.xml"))
    rmap = {r.get("Id"): r.get("Target") for r in ET.fromstring(z.read("xl/_rels/workbook.xml.rels"))}
    out = {}
    for s in wb.find("m:sheets", n):
        t = rmap[s.get(f"{{{NSR}}}id")]
        t = t if t.startswith("xl/") else "xl/" + t.lstrip("/")
        rows = []
        for r in ET.fromstring(z.read(t)).iter(f"{{{NS}}}row"):
            row = {}
            for c in r.findall("m:c", n):
                col = re.match(r"[A-Z]+", c.get("r")).group()
                v = c.find("m:v", n)
                if c.get("t") == "s" and v is not None:
                    row[col] = ss[int(v.text)]
                elif c.get("t") == "inlineStr":
                    row[col] = "".join(x.text or "" for x in c.iter(f"{{{NS}}}t"))
                else:
                    row[col] = v.text if v is not None else None
            rows.append(row)
        out[s.get("name")] = rows
    return out


# ---------------------------------------------------------------------------
# périodes
# ---------------------------------------------------------------------------

def D(s):
    return dt.date.fromisoformat(s) if s else dt.date(9999, 1, 1)


def fusionne(iv):
    iv = sorted(iv)
    out = []
    for a, b in iv:
        if out and a <= out[-1][1]:
            out[-1] = (out[-1][0], max(out[-1][1], b))
        else:
            out.append((a, b))
    return out


def soustrait(a, b):
    """Les intervalles de `a` que `b` ne couvre pas."""
    out = []
    for x, y in a:
        cur = [(x, y)]
        for u, v in b:
            nxt = []
            for p, q in cur:
                if v <= p or u >= q:
                    nxt.append((p, q))
                    continue
                if p < u:
                    nxt.append((p, u))
                if v < q:
                    nxt.append((v, q))
            cur = nxt
        out += cur
    return fusionne(out)


def jour(d: dt.date) -> str:
    return str(d.year) if (d.month, d.day) == (1, 1) else d.strftime("%d/%m/%Y")


def periodes(iv) -> str | None:
    return ", ".join(f"{jour(a)}–{jour(b)}" for a, b in iv) or None


def partage(memb):
    """Les périodes où au moins deux fractions ont un canton, et le maximum simultané."""
    bornes = sorted({m[k] for m in memb for k in ("d", "f")})
    out, mx = [], 0
    for a, b in zip(bornes, bornes[1:]):
        n = len({m["atom"] for m in memb if m["d"] <= a < m["f"]})
        mx = max(mx, n)
        if n >= 2:
            out.append((a, b))
    return fusionne(out), mx


# ---------------------------------------------------------------------------
# écriture xlsx
# ---------------------------------------------------------------------------

# styles : 0 défaut, 1 en-tête, 2 faite, 3 partielle, 4 texte replié, 5 faite replié, 6 partielle replié
STYLES = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<fonts count="2"><font><sz val="10"/><name val="Arial"/></font><font><b/><sz val="10"/><color rgb="FFFFFFFF"/><name val="Arial"/></font></fonts>
<fills count="5"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill>
<fill><patternFill patternType="solid"><fgColor rgb="FF2F5597"/></patternFill></fill>
<fill><patternFill patternType="solid"><fgColor rgb="FFE2F0D9"/></patternFill></fill>
<fill><patternFill patternType="solid"><fgColor rgb="FFFFF2CC"/></patternFill></fill></fills>
<borders count="2"><border/><border><bottom style="thin"><color rgb="FFBFBFBF"/></bottom></border></borders>
<cellStyleXfs count="1"><xf/></cellStyleXfs>
<cellXfs count="7">
<xf fontId="0" fillId="0" borderId="0" applyAlignment="1"><alignment vertical="top"/></xf>
<xf fontId="1" fillId="2" borderId="1" applyFont="1" applyFill="1" applyAlignment="1"><alignment vertical="center" wrapText="1"/></xf>
<xf fontId="0" fillId="3" borderId="0" applyFill="1" applyAlignment="1"><alignment vertical="top"/></xf>
<xf fontId="0" fillId="4" borderId="0" applyFill="1" applyAlignment="1"><alignment vertical="top"/></xf>
<xf fontId="0" fillId="0" borderId="0" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf>
<xf fontId="0" fillId="3" borderId="0" applyFill="1" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf>
<xf fontId="0" fillId="4" borderId="0" applyFill="1" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf>
</cellXfs></styleSheet>"""


def col(i: int) -> str:
    s = ""
    i += 1
    while i:
        i, r = divmod(i - 1, 26)
        s = chr(65 + r) + s
    return s


def feuille(entetes, lignes, largeurs, repli=(), teinte=None) -> str:
    """Une feuille : en-tête figée, filtre automatique, `teinte(ligne)` -> 'faite'|'partielle'|None."""
    x = [f'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
         f'<worksheet xmlns="{NS}" xmlns:r="{NSR}">'
         '<sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>'
         '</sheetView></sheetViews><sheetFormatPr defaultRowHeight="12.8"/><cols>']
    for i, w in enumerate(largeurs):
        x.append(f'<col min="{i + 1}" max="{i + 1}" width="{w}" customWidth="1"/>')
    x.append("</cols><sheetData>")

    def cellule(ref, v, s):
        if v is None or v == "":
            return f'<c r="{ref}" s="{s}"/>'
        if isinstance(v, (int, float)) and not isinstance(v, bool):
            return f'<c r="{ref}" s="{s}"><v>{v}</v></c>'
        return f'<c r="{ref}" s="{s}" t="inlineStr"><is><t xml:space="preserve">{escape(str(v))}</t></is></c>'

    x.append('<row r="1" ht="30" customHeight="1">' +
             "".join(cellule(f"{col(i)}1", h, 1) for i, h in enumerate(entetes)) + "</row>")
    for n, l in enumerate(lignes, start=2):
        t = teinte(l) if teinte else None
        cs = []
        for i, v in enumerate(l):
            s = {"faite": 2, "partielle": 3}.get(t, 0)
            if i in repli:
                s = {0: 4, 2: 5, 3: 6}[s]
            cs.append(cellule(f"{col(i)}{n}", v, s))
        x.append(f'<row r="{n}">' + "".join(cs) + "</row>")
    x.append(f'</sheetData><autoFilter ref="A1:{col(len(entetes) - 1)}{len(lignes) + 1}"/></worksheet>')
    return "".join(x)


def classeur(path: Path, feuilles: list[tuple[str, str]]):
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("[Content_Types].xml",
                   '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
                   '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
                   '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
                   '<Default Extension="xml" ContentType="application/xml"/>'
                   '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
                   '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
                   + "".join(f'<Override PartName="/xl/worksheets/sheet{i + 1}.xml" '
                             'ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
                             for i in range(len(feuilles)))
                   + "</Types>")
        z.writestr("_rels/.rels",
                   '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
                   '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
                   '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
                   "</Relationships>")
        z.writestr("xl/workbook.xml",
                   f'<?xml version="1.0" encoding="UTF-8" standalone="yes"?><workbook xmlns="{NS}" xmlns:r="{NSR}"><sheets>'
                   + "".join(f'<sheet name="{escape(nom)}" sheetId="{i + 1}" r:id="rId{i + 1}"/>' for i, (nom, _) in enumerate(feuilles))
                   + "</sheets></workbook>")
        z.writestr("xl/_rels/workbook.xml.rels",
                   '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
                   '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
                   + "".join(f'<Relationship Id="rId{i + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet{i + 1}.xml"/>'
                             for i in range(len(feuilles)))
                   + f'<Relationship Id="rId{len(feuilles) + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
                   "</Relationships>")
        z.writestr("xl/styles.xml", STYLES)
        for i, (_, xml) in enumerate(feuilles):
            z.writestr(f"xl/worksheets/sheet{i + 1}.xml", xml)


# ---------------------------------------------------------------------------

def main():
    donnees = json.loads(psql(SQL_DONNEES))
    ancien = lire_xlsx(SORTIE) if SORTIE.exists() else {}
    anc_villes = {r.get("A"): r for r in ancien.get("Villes", [])[1:]}

    lignes_csv = list(csv.DictReader(open(ICI / "coupes_ville.csv", encoding="utf-8", newline="")))
    ancres_csv = list(csv.DictReader(open(ICI / "coupes_ville_ancres.csv", encoding="utf-8", newline="")))
    verdicts = recette()
    inscrire = a_inscrire()

    memb = {}
    for m in donnees["memb"]:
        m["d"], m["f"] = D(m["d"]), D(m["f"])
        memb.setdefault(m["insee"], []).append(m)
    atome_ville = {m["atom"]: m["insee"] for m in donnees["memb"]}

    # fractions : on fusionne les tranches contiguës de même canton et même nom
    fractions = []
    for insee, ms in memb.items():
        for m in sorted(ms, key=lambda m: (m["atom"], m["unit"], m["d"])):
            p = fractions[-1] if fractions else None
            if p and (p["atom"], p["unit"], p["nom"]) == (m["atom"], m["unit"], m["nom"]) and p["f"] >= m["d"]:
                p["f"] = max(p["f"], m["f"])
            else:
                fractions.append(dict(m))

    villes, rangs_fr = [], []
    nb = {"faite": 0, "partielle": 0}
    for v in donnees["villes"]:
        insee = v["insee"]
        anc = anc_villes.get(insee, {})
        nom = v["nom"] or anc.get("B") or ""
        ms = memb.get(insee, [])
        part, mx = partage(ms)
        lc = [l for l in lignes_csv if l["insee"] == insee]
        traces = fusionne([(D(l["valid_from"]), D(l["valid_to"])) for l in lc])
        non_couvert = soustrait(part, traces) if lc else []
        etat = "À faire" if not lc else ("Partielle" if non_couvert else "Faite")
        # ancres : celles des atomes de la ville
        ancres = sum(1 for a in ancres_csv if atome_ville.get(a["atom_id"]) == insee)
        fr_v = [f for f in fractions if f["insee"] == insee]
        cantons = {}
        for f in fr_v:
            cantons.setdefault((f["unit"], f["nom"]), []).append((f["d"], f["f"]))
        s_col = "\n".join(f"{u} {n} ({periodes(fusionne(iv))})"
                          for (u, n), iv in sorted(cantons.items(), key=lambda k: (k[0][0], min(k[1])[0])))
        origine = ("GEOFLA" if not v["cog"] else "COG" if not v["geofla"]
                   else f"mixte ({v['geofla']} GEOFLA, {v['cog']} COG)")
        rem = (REMARQUES[insee] if insee in REVISEES and lc
               else anc.get("R") or (REMARQUES.get(insee) if lc else None))
        if etat == "Faite":
            nb["faite"] += 1
        elif etat == "Partielle":
            nb["partielle"] += 1
        villes.append([insee, nom, insee[:2], v["nfr"], v["nfr"] - 1, mx, v["iris"], origine,
                       "non" if origine == "COG" else "oui", periodes(part), etat, len(lc),
                       periodes(traces), periodes(non_couvert), ancres,
                       verdicts.get(insee) if lc else None, ", ".join(inscrire.get(insee, [])) or None,
                       rem, s_col])
        for f in fr_v:
            rangs_fr.append([insee, nom, f["atom"], f["unit"], f["nom"], f["d"].isoformat(),
                             f["f"].isoformat() if f["f"].year < 9999 else None])

    noms = {v[0]: v[1] for v in villes}
    rangs_l = [[l["insee"], noms.get(l["insee"], ""), l["coupe_id"], l["valid_from"], l["valid_to"] or None,
                l["source"], l["note"]] for l in lignes_csv]

    f1 = feuille(["INSEE", "Commune", "Dép.", "Fractions en base", "Coupes à tracer", "Cantons max. simultanés",
                  "IRIS", "Origine des fractions", "Dans les 119 du skill",
                  "Partage en base (≥ 2 fractions avec canton)", "État", "Lignes tracées", "Périodes tracées",
                  "Partage en base non couvert", "Ancres", "Recette 98 §5a", "À inscrire en base (n°)",
                  "Remarques", "Fractions et cantons"],
                 villes, [8, 27, 5.7, 10, 10, 10, 7, 18, 10, 30, 11, 9, 25, 25, 8, 22, 11, 57, 45],
                 repli=(9, 12, 13, 17, 18),
                 teinte=lambda l: {"Faite": "faite", "Partielle": "partielle"}.get(l[10]))
    f2 = feuille(["INSEE", "Commune", "Fraction", "Canton (unit_id)", "Nom du canton", "Du", "Au"],
                 rangs_fr, [8, 27, 14, 10, 32, 11, 11])
    f3 = feuille(["INSEE", "Commune", "Coupe", "Du", "Au", "Source", "Note"],
                 rangs_l, [8, 22, 10, 11, 11, 8, 120], repli=(6,))
    tmp = SORTIE.with_suffix(".tmp.xlsx")
    classeur(tmp, [("Villes", f1), ("Fractions", f2), ("Lignes tracées", f3)])
    tmp.replace(SORTIE)
    print(f"{SORTIE.relative_to(RACINE)} : {len(villes)} villes ({nb['faite']} faites, {nb['partielle']} partielles), "
          f"{len(rangs_fr)} fractions, {len(rangs_l)} lignes")
    pas_tracees = [k for k in REMARQUES if not any(l["insee"] == k for l in lignes_csv)]
    if pas_tracees:
        print("remarques sans ligne :", pas_tracees)


if __name__ == "__main__":
    main()
