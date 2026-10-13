"""Bâtit cantons/decrets_complement.csv : les actes cantonaux que Wikipédia
date et que decrets_cantonaux.csv n'a pas. Chaque ligne a été relue à la main
(wikipedia/actes_absents_tri.csv) et rattachée à son numéro du JO sur Légifrance
(identifiant `JORF_AAAAMMJJ_NNN`, celui que porte le lien de téléchargement).

Ce n'est PAS un ajout au registre : rien ici n'a été lu au JO. C'est la liste
de ce qu'il faut lire. `a_lire = oui` tant que le texte n'a pas été vu.

    python3 cantons/wikipedia/batir_complement.py .     (depuis la racine)
"""
import csv, unicodedata, re, sys
R = sys.argv[1] if len(sys.argv) > 1 else '.'


def norm(s):
    s = unicodedata.normalize('NFD', s.lower())
    s = ''.join(c for c in s if unicodedata.category(c) != 'Mn')
    return re.sub(r'[^a-z0-9]+', ' ', s).strip()


insee = {}
with open(f'{R}/sources/cog/1999/comsimp1999.txt', encoding='latin1') as f:
    for x in csv.DictReader(f, delimiter='\t'):
        art = x['ARTMIN'].strip('()')
        nom = x['NCCENR']
        noms = {nom}
        if art:
            noms.add(art + ('' if art.endswith("'") else ' ') + nom)
        for n in noms:
            insee[(x['DEP'], norm(n))] = x['DEP'] + x['COM']


def codes(deps, noms):
    out = []
    for n in noms:
        c = next((insee[(d, norm(n))] for d in deps if (d, norm(n)) in insee), None)
        out.append(c or f'?{n}')
    return ' '.join(out)


def url_jo(iso):
    y, m, j = iso.split('-')
    d = f'{j}%2F{m}%2F{y}'
    return f'https://www.legifrance.gouv.fr/jorf/jo/period/?datePubli={d}%20%3E%20{d}'


# clé, signature, publication, n°, départements, objet, catégorie, JO, page, id Légifrance, communes, résumé
A = [
    # --- 1940-1957 : hors du registre par construction (il commence en 1958)
    ('01', '1949-01-04', '1949-01-09', '', '01', 'rattachement de commune a un canton', 'composition',
     'JORF_19490109_8', '405', '', ['Saint-Sulpice'],
     "Saint-Sulpice : Bâgé-le-Châtel -> Montrevel. Aussi sur Gallica : ark:/12148/bpt6k15801265/f5"),
    ('59', '1946-05-03', '1946-05-04', '', '59', 'rattachement de commune a un canton', 'composition',
     'JORF_19460504_104', '3763', '', ['Rainsars'],
     "Rainsars : Trélon -> Avesnes-sur-Helpe-Sud"),
    ('16', '1948-10-26', '1948-10-28', '', '16', 'rattachement de commune a un canton', 'composition',
     'JORF_19481028_256', '10472', '', ['Taponnat-Fleurignac'],
     "Taponnat : Montembœuf -> La Rochefoucauld"),
    ('62a', '1949-06-28', '1949-06-30', '', '62', 'creation et modification de cantons', 'composition',
     'JORF_19490630_154', '6435', '', ['Lens', 'Liévin'],
     "LU : Liévin érigé en chef-lieu ; Lens-Ouest devient canton de Liévin, moins sa part de Lens, "
     "rattachée au nouveau canton de Lens (ex-Lens-Est)"),
    ('46', '1949-09-05', '1949-09-07', '', '46', 'creation de cantons', 'composition',
     'JORF_19490907_211', '8978', '', [],
     "création de Sousceyrac (Latronquière, Bretenoux, Saint-Céré) — déjà dans 93 § 5 par l'annexe VII"),
    ('19', '1951-09-13', '1951-09-14', '', '19', 'creation et modification de cantons', 'composition',
     'JORF_19510914_217', '9548', '', [],
     "Brive -> Brive-Nord et Brive-Sud — déjà dans 93 § 5 par l'annexe VII"),
    ('01-11', '1951-11-14', '1951-11-17', '', '01 11', 'rattachement de commune a un canton', 'composition',
     'JORF_19511117_272', '11415', '', ['Dompierre-sur-Chalaronne', 'Saint-Couat-du-Razès'],
     "Dompierre-sur-Chalaronne : Thoissey -> Châtillon-sur-Chalaronne ; Saint-Couat-du-Razès : Chalabre -> Limoux (même page)"),
    ('64', '1951-11-14', '1951-11-17', '', '64', 'rattachement de commune a un canton', 'composition',
     'JORF_19511117_272', '11415', '', ['Salles-Mongiscard'],
     "TROUVÉ AU JO, absent de Wikipédia : Salles-Mongiscard, canton de Salies -> canton d'Orthez (Basses-Pyrénées)"),
    ('37', '1956-08-04', '1956-08-05', '', '37', 'creation et modification de cantons', 'composition',
     'JORF_19560805_181', '7380', '', [],
     "redécoupage des cantons de Tours (Tours-Est : la Fuye, Larçay, Montlouis, Saint-Avertin…)"),
    ('33', '1957-09-24', '1957-09-25', '', '33', 'creation de cantons', 'composition',
     'JORF_19570925_223', '9171', '', [],
     "création du canton de Mérignac, détaché de Pessac"),
    # --- 1958-1975 : textes que Légifrance n'indexe pas, donc absents du moissonnage
    ('68', '1958-02-26', '1958-02-27', '', '68', 'creation et modification de cantons', 'composition',
     'JORF_19580227_49', '2117-2118', '', [],
     "deux décrets : Colmar -> Colmar-Nord/-Sud ; Mulhouse -> Est, Nord, Ouest, Sud et Wittenheim"),
    ('62b', '1962-01-10', '1962-01-11', 'n° 62-5', '62', 'creation et modification de cantons', 'composition',
     'JORF_19620111_8', '316', '', [],
     "LU : Carvin, Houdain, Lens et Liévin répartis en neuf cantons (Carvin, Hénin-Liétard, Lens-Est, "
     "Lens-Nord-Est, Lens-Nord-Ouest, Liévin-Nord, Liévin-Nord-Ouest, Bruay-en-Artois, Houdain). "
     "Le 62-6 du même jour (JORFTEXT000000302017) ne crée que les arrondissements"),
    ('43', '1962-01-22', '1962-01-27', '', '43', 'rattachement de commune a un canton', 'composition',
     'JORF_19620127_22', '918', '', ['La Chapelle-Bertin'],
     "TROUVÉ AU JO, absent de Wikipédia : La Chapelle-Bertin, canton de Paulhaguet -> canton d'Allègre"),
    ('67', '1962-01-22', '1962-01-27', '', '67', 'creation et modification de cantons', 'composition',
     'JORF_19620127_22', '918', '', [],
     "les quatre cantons de Strasbourg redécoupés en huit cantons numérotés"),
    ('49a', '1963-05-30', '1963-06-05', '', '49', 'modification de limites cantonales', 'composition',
     'JORF_19630605_130', '5038', '', ['Saumur'],
     "LU : quartier de la Croix-Verte, Saumur-Nord-Est -> Saumur-Nord-Ouest, renommé Saumur-Nord ; "
     "chef-lieu de Saumur-Nord-Est transféré à Allonnes"),
    ('80', '1963-10-21', '1963-10-25', '', '80', 'modification de limites cantonales', 'composition',
     'JORF_19631025_251', '9558', '', ['Abbeville'],
     "limite infracommunale Abbeville-Nord / Abbeville-Sud"),
    ('69a', '1964-01-10', '1964-01-15', '', '69', 'creation et modification de cantons', 'composition',
     'JORF_19640115_12', '527', '', [],
     "Villeurbanne -> Villeurbanne-Nord, Villeurbanne-Sud et Bron"),
    ('64-01-28', '1964-01-28', '1964-01-30', '', '26 49 59 69 76 83', 'creation et modification de cantons',
     'composition', 'JORF_19640130_25', '1090-1093', '', ["Gonfreville-l'Orcher"],
     "salve du 28 janvier 1964 : Valence-Nord/-Sud (26) ; Angers-Nord/-Est (49) ; Marcq-en-Barœul (59) ; "
     "Lyon-XIII (69) ; Le Havre-III à -VII et Gonfreville-l'Orcher (76) ; Toulon-I, -III, -V (83)"),
    ('64-01-28-SO', '1964-01-28', '1964-01-30', '', '78 91 92 93 94 95', 'creation et modification de cantons',
     'composition', 'JORF_19640130_25', '1090-1091', '', ['Méry-sur-Oise', 'Butry-sur-Oise', 'Achères'],
     "TROUVÉ AU JO, absent de Wikipédia (pas de liste pour la Seine-et-Oise) : redécoupage de la "
     "Seine-et-Oise en seize articles — Méry-sur-Oise -> Pontoise, Butry-sur-Oise -> L'Isle-Adam, "
     "Boissy-Saint-Léger, Montmorency, Taverny, Poissy, Saint-Germain-en-Laye, Écouen, Corbeil-Essonnes, "
     "Villeneuve-Saint-Georges, Aulnay-sous-Bois, Le Raincy, Marly-le-Roi, Sèvres, Argenteuil… dédoublés"),
    ('77', '1964-07-29', '1964-08-04', '', '77', 'creation de cantons', 'composition',
     'JORF_19640804_180', '7047', '', [],
     "création du canton de Chelles, détaché de Lagny ; rectificatif au JO du 2 septembre 1964"),
    ('38', '1968-08-01', '1968-08-10', '', '38', 'creation de cantons', 'composition',
     'JORF_19680810_188', '7800', '', [],
     "création du canton de Pont-de-Chéruy (six communes de Meyzieu restées iséroises)"),
    ('62c', '1975-09-29', '1975-10-08', '', '62', 'modification de limites cantonales', 'composition',
     'JORF_19751008_234', '', 'JORFTEXT000000694240', ['Liévin'],
     "LU : la partie de Liévin dans Liévin-Nord-Ouest passe à Liévin-Nord, renommé Liévin ; "
     "Liévin-Nord-Ouest devient Bully-les-Mines, chef-lieu Bully-les-Mines"),
    ('85', '1975-10-10', '', '', '85', 'modification de limites cantonales', 'composition',
     '', '', '', ['Aizenay'],
     "décret en Conseil d'État : La Chapelle-Palluau (associée à Aizenay) passe de Palluau au Poiré-sur-Vie ; JO non trouvé"),
    # --- changements de département
    ('67-1205', '1967-12-29', '1967-12-30', 'loi n° 67-1205', '01 38 69', 'modification de limites departementales',
     'departement', 'JORF_19671230_303', '', 'JORFTEXT000000880759', [],
     "communes de l'Ain et de l'Isère rattachées au Rhône"),
    ('68-168', '1968-02-21', '', 'n° 68-168', '69', 'modification de limites cantonales', 'departement',
     '', '', 'JORFTEXT000000877293', [],
     "application de la loi 67-1205 dans le Rhône"),
    ('69b', '1969-11-21', '1969-11-28', '', '78 91', 'modification de limites departementales', 'departement',
     'JORF_19691128_278', '11615', '', ['Toussus-le-Noble', 'Châteaufort'],
     "Toussus-le-Noble et Châteaufort : Essonne -> Yvelines (canton de Versailles-Sud)"),
    ('75-356', '1975-05-15', '1975-05-16', 'loi n° 75-356', '20 2A 2B', 'modification de limites departementales',
     'departement', 'JORF_19750516_113', '', 'JORFTEXT000000521934', [],
     "réorganisation de la Corse ; la loi énumère les communes par canton"),
    # --- noms et chefs-lieux : probablement sans effet sur l'appartenance, à confirmer au JO
    ('68b', '1948-10-26', '1948-10-28', '', '68', 'transfert de chef-lieu', 'nom_seul',
     'JORF_19481028_256', '10472', '', [], "chef-lieu de Landser transféré à Sierentz"),
    ('57', '1950-03-16', '1950-03-21', '', '57', 'transfert de chef-lieu', 'nom_seul',
     'JORF_19500321_69', '3129', '', [], "chef-lieu de Gorze transféré à Ars-sur-Moselle"),
    ('51', '1957-06-04', '1957-06-06', '', '51', 'transfert de chef-lieu', 'nom_seul',
     'JORF_19570606_130', '5670', '', [], "chef-lieu de Dommartin-sur-Yèvre transféré à Givry-en-Argonne"),
    ('79', '1965-01-06', '1965-02-21', '', '79', 'changement de nom de canton', 'nom_seul',
     'JORF_19650221_44', '1483', '', [], "arrêté préfectoral : Châtillon-sur-Sèvre devient Mauléon"),
    ('35a', '1967-10-26', '1967-10-29', '', '35', 'changement de nom de canton', 'nom_seul',
     'JORF_19671029_253', '10644', '', [], "arrêté : Saint-Malo -> Saint-Malo-Nord, Saint-Servan -> Saint-Malo-Sud"),
    ('86', '1973-01-11', '1973-01-19', '', '86', 'transfert de chef-lieu', 'nom_seul',
     'JORF_19730119_16', '775', '', [], "chef-lieu de Leigné-sur-Usseau transféré à Saint-Gervais-les-Trois-Clochers"),
    ('85-01-16', '1985-01-16', '1985-01-18', '', '32 35', 'changement de nom de canton', 'nom_seul',
     'JORF_19850118_15', '686', 'JORFTEXT000000690188', [],
     "« portant changement de noms de cantons » : Auch-Sud-Est -> Auch-Sud-Est-Seissan ; les douze cantons de Rennes"),
    # --- annulations contentieuses
    ('CE-1967', '1977-11-18', '', '', '94', 'annulation contentieuse', 'decision_ce', '', '', '', [],
     "CE 18 novembre 1977 n° 1967 : annule les art. 2 (Villejuif, Ivry-Ouest) et 4 (Orly, Thiais) du décret de 1976"),
    ('CE-02482', '1978-07-12', '', '', '95', 'annulation contentieuse', 'decision_ce', '', '', '', [],
     "CE 12 juillet 1978 n° 02482 : annule le décret de 1976 en tant qu'il modifie le canton de Luzarches"),
    ('CE-187318', '1998-11-13', '', '', '54', 'annulation contentieuse', 'decision_ce', '', '', '', [],
     "CE 13 novembre 1998 n° 187318 : annule l'art. 5 (Laxou, Nancy-Ouest, Pompey) du décret de 1997"),
]

# Actes dont le texte a été lu au JO le 11 octobre 2026 (jorf_txt/*_col.txt) ;
# le détail de la lecture est dans cantons/wikipedia/lecture_jo.md.
LUS = {'59', '16', '01', '62a', '46', '19', '01-11', '64', '37', '33', '68', '62b', '43', '67',
       '49a', '80', '69a', '64-01-28', '64-01-28-SO', '62c', '68b', '57', '51'}

rows = []
for cle, sig, pub, dec, deps, objet, cat, jo, page, lid, coms, res in A:
    url = (f'https://www.legifrance.gouv.fr/jorf/id/{lid}' if lid else url_jo(pub) if pub else '')
    rows.append({'cle': f'WP-{cle}', 'date_signature': sig, 'date_publication_jo': pub, 'decret': dec,
                 'deps': deps, 'objet': objet, 'categorie': cat, 'jo': jo, 'page_jo': page,
                 'legifrance_id': lid, 'url': url,
                 'communes_insee': codes(deps.split(), coms) if coms else '',
                 'resume': res,
                 'source': 'jo' if res.startswith('TROUVÉ AU JO') else 'wikipedia',
                 'a_lire': 'non' if cle in LUS else 'oui'})

with open(f'{R}/cantons/decrets_complement.csv', 'w', newline='') as f:
    w = csv.DictWriter(f, list(rows[0]))
    w.writeheader()
    w.writerows(rows)

print(len(rows), 'actes ;', sum(r['communes_insee'].count('?') for r in rows), 'commune(s) non résolue(s)')
for r in rows:
    if r['communes_insee']:
        print(' ', r['cle'], r['communes_insee'])
