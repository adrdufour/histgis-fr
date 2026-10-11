"""Tri des actes datés par Wikipédia et absents de decrets_cantonaux.csv.
Le classement est fait à la lecture, acte par acte (dict TRI ci-dessous) ;
la date et la page du JO sont relues dans la référence Wikipédia.
Sortie : actes_absents_tri.csv
"""
import csv, re
MOIS = {'janvier':1,'janiver':1,'février':2,'mars':3,'avril':4,'mai':5,'juin':6,'juillet':7,
        'août':8,'septembre':9,'octobre':10,'novembre':11,'décembre':12}
# (dep, date) -> (catégorie, remarque)
TRI = {
 ('31','1997-02-16'): ('deja_au_registre', "décret du 26 février 1997 (JORFTEXT000000199864) ; Wikipédia date au 16"),
 ('51','1985-01-15'): ('deja_au_registre', "décret n° 82-32 du 15 janvier 1982 ; Wikipédia écrit 1985"),
 ('54','1982-01-25'): ('deja_au_registre', "décret n° 82-82, acte_departement.csv (titre « divers départements »)"),
 ('54','1996-08-07'): ('deja_au_registre', "décret n° 96-709, acte_departement.csv"),
 ('69','1964-08-12'): ('deja_au_registre', "décret n° 64-847, acte_departement.csv"),
 ('91','1968-01-01'): ('bruit', "paragraphe d'introduction"),
 ('11','1950-08-09'): ('arrondissement', "Tuchan change d'arrondissement ; aucune commune ne change de canton"),
 ('44','1976-08-20'): ('arrondissement', "deux cantons changent d'arrondissement"),
 ('45','1942-06-01'): ('arrondissement', "loi du 1er juin 1942, arrondissement de Pithiviers"),
 ('50','1952-02-11'): ('arrondissement', "La Haye-Pesnel change d'arrondissement"),
 ('50','1963-06-20'): ('arrondissement', "trois cantons changent d'arrondissement"),
 ('971','1949-08-02'): ('outremer', "loi n° 49-1102, création des cantons des DOM"),
 ('972','1949-08-02'): ('outremer', "loi n° 49-1102"),
 ('974','1949-08-02'): ('outremer', "loi n° 49-1102"),
 ('973','1969-03-17'): ('outremer', "décret n° 69-261, Guyane"),
 ('51','1957-06-04'): ('nom_seul', "transfert de chef-lieu Dommartin-sur-Yèvre -> Givry-en-Argonne"),
 ('57','1950-03-16'): ('nom_seul', "transfert de chef-lieu Gorze -> Ars-sur-Moselle"),
 ('68','1948-10-26'): ('nom_seul', "transfert de chef-lieu Landser -> Sierentz"),
 ('86','1973-01-11'): ('nom_seul', "transfert de chef-lieu Leigné-sur-Usseau -> Saint-Gervais-les-Trois-Clochers"),
 ('35','1967-10-26'): ('nom_seul', "arrêté : Saint-Malo -> Saint-Malo-Nord, Saint-Servan -> Saint-Malo-Sud"),
 ('79','1965-01-06'): ('nom_seul', "arrêté préfectoral : Châtillon-sur-Sèvre -> Mauléon"),
 ('32','1985-01-16'): ('nom_seul', "décret du 16 janvier 1985 : Auch-Sud-Est -> Auch-Sud-Est-Seissan"),
 ('35','1985-01-16'): ('nom_seul', "décret du 16 janvier 1985 : douze cantons de Rennes renommés"),
 ('54','1998-11-13'): ('decision_ce', "CE 13 novembre 1998 n° 187318 : annule l'art. 5 (Laxou, Nancy-Ouest, Pompey)"),
 ('94','1977-11-18'): ('decision_ce', "CE 18 novembre 1977 n° 1967 : annule les art. 2 et 4 du décret de 1976"),
 ('95','1978-07-12'): ('decision_ce', "CE 12 juillet 1978 n° 02482 : annule le décret de 1976 pour Luzarches"),
 ('01','1967-12-29'): ('departement', "loi n° 67-1205 : six communes de l'Ain passent au Rhône"),
 ('38','1967-12-29'): ('departement', "loi n° 67-1205 : communes de l'Isère passent au Rhône"),
 ('69','1967-12-29'): ('departement', "loi n° 67-1205 + décrets du 21 février 1968 et du 12 avril"),
 ('20','1975-05-15'): ('departement', "loi n° 75-356, bidépartementalisation de la Corse"),
 ('2A','1975-05-15'): ('departement', "loi n° 75-356"),
 ('2B','1975-05-15'): ('departement', "loi n° 75-356"),
 ('78','1969-11-24'): ('departement', "décret du 21 novembre 1969 : Toussus-le-Noble et Châteaufort passent aux Yvelines"),
 ('91','1969-11-24'): ('departement', "même décret, côté Essonne"),
}
def jo(refs):
    m = re.search(r"JORF\W*(?:du\s+)?(\d{1,2})(?:er)?\s+(\w+)\s+(\d{4})(?:\W+p\.\s*([\d. ]+))?", refs)
    if not m or m.group(2).lower() not in MOIS: return '', ''
    return f"{m.group(3)}-{MOIS[m.group(2).lower()]:02d}-{int(m.group(1)):02d}", (m.group(4) or '').replace('.', '').strip()
def signature(refs, texte):
    m = re.search(r"(?:[Dd]écret|[Ll]oi|[Aa]rrêté)[^,;]*?du (\d{1,2})(?:er)?\s+(\w+)\s+(\d{4})", refs + ' ' + texte)
    if m and m.group(2).lower() in MOIS:
        return f"{m.group(3)}-{MOIS[m.group(2).lower()]:02d}-{int(m.group(1)):02d}"
    return ''
out = []
for x in csv.DictReader(open('actes_wikipedia_vs_registre.csv')):
    if x['au_registre'] != 'non': continue
    cat, rq = TRI.get((x['dep'], x['date_wikipedia']), ('composition', ''))
    dpub, page = jo(x['references'])
    out.append({'dep': x['dep'], 'date_wikipedia': x['date_wikipedia'],
                'date_signature': signature(x['references'], x['texte']) or x['date_wikipedia'],
                'date_jo': dpub, 'page_jo': page, 'categorie': cat, 'remarque': rq,
                'texte': x['texte'][:300], 'references': x['references'][:300]})
with open('actes_absents_tri.csv', 'w', newline='') as f:
    w = csv.DictWriter(f, list(out[0])); w.writeheader(); w.writerows(out)
import collections
print(collections.Counter(o['categorie'] for o in out))
for o in out:
    if o['categorie'] == 'composition': print(o['dep'], o['date_signature'], 'JO', o['date_jo'] or '?', 'p.', o['page_jo'] or '?', '|', o['texte'][:90])
