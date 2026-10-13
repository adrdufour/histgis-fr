"""Extrait des pages « Liste des cantons de … » (fr.wikipedia) les changements
datés : une ligne par puce (ou paragraphe) des sections d'histoire, avec la date
la plus précise que porte la puce, son texte nettoyé, ses références et ses liens.

Entrée : wikipedia_listes_cantons.json, wikipedia_cantons_complements.json
Sortie : changements_wikipedia.csv (toutes années), changements_wikipedia_1940_1998.csv
"""
import json, re, csv, sys, unicodedata
import mwparserfromhell as mw

ICI = sys.argv[1] if len(sys.argv) > 1 else '.'

DEP = {"Ain":"01","Aisne":"02","Allier":"03","Alpes-de-Haute-Provence":"04","Hautes-Alpes":"05",
"Alpes-Maritimes":"06","Ardèche":"07","Ardennes":"08","Ariège":"09","Aube":"10","Aude":"11",
"Aveyron":"12","Bouches-du-Rhône":"13","Calvados":"14","Cantal":"15","Charente":"16",
"Charente-Maritime":"17","Cher":"18","Corrèze":"19","Corse-du-Sud":"2A","Haute-Corse":"2B",
"Corse":"20","Côte-d'Or":"21","Côtes-d'Armor":"22","Creuse":"23","Dordogne":"24","Doubs":"25",
"Drôme":"26","Eure":"27","Eure-et-Loir":"28","Finistère":"29","Gard":"30","Haute-Garonne":"31",
"Gers":"32","Gironde":"33","Hérault":"34","Ille-et-Vilaine":"35","Indre":"36","Indre-et-Loire":"37",
"Isère":"38","Jura":"39","Landes":"40","Loir-et-Cher":"41","Loire":"42","Haute-Loire":"43",
"Loire-Atlantique":"44","Loiret":"45","Lot":"46","Lot-et-Garonne":"47","Lozère":"48",
"Maine-et-Loire":"49","Manche":"50","Marne":"51","Haute-Marne":"52","Mayenne":"53",
"Meurthe-et-Moselle":"54","Meuse":"55","Morbihan":"56","Moselle":"57","Nièvre":"58","Nord":"59",
"Oise":"60","Orne":"61","Pas-de-Calais":"62","Puy-de-Dôme":"63","Pyrénées-Atlantiques":"64",
"Hautes-Pyrénées":"65","Pyrénées-Orientales":"66","Bas-Rhin":"67","Haut-Rhin":"68","Rhône":"69",
"Haute-Saône":"70","Saône-et-Loire":"71","Sarthe":"72","Savoie":"73","Haute-Savoie":"74",
"Seine":"75","Paris":"75","Seine-Maritime":"76","Seine-et-Marne":"77","Yvelines":"78","Deux-Sèvres":"79",
"Somme":"80","Tarn":"81","Tarn-et-Garonne":"82","Var":"83","Vaucluse":"84","Vendée":"85",
"Vienne":"86","Haute-Vienne":"87","Vosges":"88","Yonne":"89","Territoire de Belfort":"90",
"Essonne":"91","Hauts-de-Seine":"92","Seine-Saint-Denis":"93","Val-de-Marne":"94","Val-d'Oise":"95",
"Guadeloupe":"971","Martinique":"972","Guyane":"973","La Réunion":"974","Mayotte":"976",
"Seine-et-Oise":"78/91/95","Bourg-en-Bresse":"01"}

def departement(titre):
    t = re.sub(r'\s*\(.*\)$', '', titre)
    t = re.sub(r'\s+de \d{4} à \d{4}$', '', t)
    t = re.sub(r'^(Liste des (anciens )?cantons|Histoire du découpage cantonal|Anciens cantons)\s+', '', t)
    t = re.sub(r'^(du département )', '', t)
    t = re.sub(r"^(de la |de l'|des |du |de |d')", '', t)
    t = t.replace(' (département)', '')
    if t == 'Réunion': t = 'La Réunion'
    return t, DEP.get(t, '')

MOIS = {'janvier':1,'février':2,'fevrier':2,'mars':3,'avril':4,'mai':5,'juin':6,'juillet':7,
        'août':8,'aout':8,'septembre':9,'octobre':10,'novembre':11,'décembre':12,'decembre':12,
        'janiver':1}
RX_JMA = re.compile(r"\b(1er|\d{1,2})\s*(?:er)?\s+(" + '|'.join(MOIS) + r")\s+(1[789]\d\d|20[0-2]\d)\b", re.I)
RX_MA = re.compile(r"\b(" + '|'.join(MOIS) + r")\s+(1[789]\d\d|20[0-2]\d)\b", re.I)
RX_A = re.compile(r"\b(1[789]\d\d|20[0-2]\d)\b")

def tpl_dates(code):
    """Remplace {{date|j|m|a}}, {{date-|…}}, {{date France|…}} par du texte."""
    for t in code.filter_templates(recursive=True):
        n = str(t.name).strip().lower()
        if n.startswith('date'):
            parts = [str(p.value).strip() for p in t.params if not p.showkey]
            parts = [p for p in parts if p]
            if parts:
                if len(parts) >= 3 and parts[1].isdigit():
                    mois = [k for k, v in MOIS.items() if v == int(parts[1])][0]
                    txt = f"{parts[0]} {mois} {parts[2]}"
                else:
                    txt = ' '.join(parts[:3])
                try: code.replace(t, txt)
                except ValueError: pass
    return code

def nettoie(wt):
    code = tpl_dates(mw.parse(wt))
    refs = []
    for tag in code.filter_tags(recursive=False):
        if str(tag.tag).lower() == 'ref':
            refs.append(tag)
    reftxt = []
    for r in refs:
        s = str(r.contents) if r.contents else ''
        urls = re.findall(r'https?://[^\s\]|}]+', s)
        plain = mw.parse(s).strip_code(normalize=True, collapse=True)
        reftxt.append((plain + ' ' + ' '.join(urls)).strip())
        try: code.remove(r)
        except ValueError: pass
    liens = [str(l.title).strip() for l in code.filter_wikilinks()]
    texte = code.strip_code(normalize=True, collapse=True)
    texte = re.sub(r'\s+', ' ', texte).strip(' :;*')
    return texte, ' || '.join(x for x in reftxt if x), liens

def meilleure_date(*textes):
    """Date la plus précise ; le premier texte (tête de puce) prime."""
    for txt in textes:
        m = RX_JMA.search(txt)
        if m:
            j = 1 if m.group(1).lower() == '1er' else int(m.group(1))
            return f"{m.group(3)}-{MOIS[m.group(2).lower()]:02d}-{j:02d}", 'jour', int(m.group(3))
    for txt in textes:
        m = RX_MA.search(txt)
        if m:
            return f"{m.group(2)}-{MOIS[m.group(1).lower()]:02d}", 'mois', int(m.group(2))
    for txt in textes:
        m = RX_A.search(txt)
        if m:
            return m.group(1), 'annee', int(m.group(1))
    return '', '', None

def nature(t):
    t = t.lower()
    out = []
    for k, rx in [('creation', r'cr[ée]ation|est cr[ée][ée]|sont cr[ée][ée]s|nouveaux? cantons?'),
                  ('suppression', r'suppression|supprim'),
                  ('division', r'divis|scind|scission|fraction|d[ée]coup'),
                  ('transfert_commune', r'passe du canton|passent du canton|transf[ée]r[ée]e?s? (du|au|de)|rattach|d[ée]tach[ée]e?s? du|est (int[ée]gr|incorpor)'),
                  ('chef_lieu', r'chef-lieu'),
                  ('renommage', r'renomm|d[ée]nomm|prend le nom|appel[ée]'),
                  ('limites', r'limite|modifi'),
                  ('arrondissement', r'arrondissement'),
                  ('departement', r'c[ée]d[ée]e?s? (au|à)|d[ée]partement d')]:
        if re.search(rx, t): out.append(k)
    return ';'.join(out)

EXCLU_SECTIONS = re.compile(r'composition (actuelle|détaillée)|répartition|homonymi|notes|références|voir aussi|articles? connexes?|liens? externes?|bibliographie|annexes|redécoupage cantonal de 2014|depuis 2015|à partir de 2015|2014 à aujourd|2015 à aujourd|de 2019|de 2020|tableau|liste avec élus', re.I)

def lignes_page(titre, p):
    wt = p['wikitext']
    nom, code = departement(p['title'])
    chemin = []      # titres de section
    pile = {}        # niveau de puce -> (tête, date)
    exclu = False
    dans_table = 0
    for i, ligne in enumerate(wt.split('\n')):
        s = ligne.strip()
        m = re.match(r'^(={2,6})\s*(.*?)\s*\1\s*$', s)
        if m:
            lvl = len(m.group(1))
            titre_sec = mw.parse(m.group(2)).strip_code().strip()
            chemin = chemin[:lvl-2] + [titre_sec]
            exclu = any(EXCLU_SECTIONS.search(c) for c in chemin)
            pile = {}
            continue
        if s.startswith('{|'): dans_table += 1
        if s.startswith('|}'): dans_table = max(0, dans_table-1); continue
        if dans_table or exclu or not s: continue
        if s.startswith(('[[Fichier', '[[File', '[[Image', '{{', '|', '!', '<!--', '__')) and not re.match(r'^\{\{date', s, re.I):
            continue
        pm = re.match(r'^([*#:]+)\s*(.*)$', s)
        niveau = len(pm.group(1)) if pm else 0
        corps = pm.group(2) if pm else s
        texte, refs, liens = nettoie(corps)
        if not texte: continue
        tete = re.split(r'\s:\s|^\S+\s*:', texte)[0] if ':' in texte[:40] else texte[:60]
        # la date se lit dans la tête, puis dans le texte, puis dans les refs, puis chez le parent
        date, prec, an = meilleure_date(tete, texte, refs)
        parent = None
        for k in sorted(pile):
            if k < niveau: parent = pile[k]
        if parent and (not date or (prec == 'annee' and parent[1] in ('jour','mois') and parent[2] == an) or niveau > 1 and prec == ''):
            date, prec, an = parent
        if niveau:
            pile = {k: v for k, v in pile.items() if k < niveau}
            pile[niveau] = (date, prec, an)
        # une date de parent plus précise de même année l'emporte aussi
        if parent and parent[2] == an and prec == 'annee' and parent[1] in ('jour','mois'):
            date, prec, an = parent
        if an is None: continue
        yield {
            'dep': code, 'dep_nom': nom, 'page': p['title'], 'revid': p['revid'],
            'section': ' > '.join(chemin), 'ligne_wikitext': i+1, 'niveau_puce': niveau,
            'date': date, 'precision': prec, 'annee': an,
            'nature': nature(texte), 'texte': texte, 'references': refs,
            'cantons_lies': ' ; '.join(l for l in liens if l.lower().startswith('canton')),
            'autres_liens': ' ; '.join(l for l in liens if not l.lower().startswith(('canton','fichier','file','image'))),
        }

def main():
    pages = {}
    for f in ('wikipedia_listes_cantons.json', 'wikipedia_cantons_complements.json'):
        for t, p in json.load(open(f'{ICI}/{f}'))['pages'].items():
            pages.setdefault(p['title'], p)
    rows = []
    for t, p in sorted(pages.items()):
        if t in ('Seine-et-Oise', 'Seine (département)'):
            continue   # pages de département : gardées en brut, pas extraites
        rows.extend(lignes_page(t, p))
    champs = list(rows[0].keys())
    with open(f'{ICI}/changements_wikipedia.csv', 'w', newline='') as fo:
        w = csv.DictWriter(fo, champs); w.writeheader(); w.writerows(rows)
    fen = [r for r in rows if 1940 <= r['annee'] <= 1998]
    with open(f'{ICI}/changements_wikipedia_1940_1998.csv', 'w', newline='') as fo:
        w = csv.DictWriter(fo, champs); w.writeheader(); w.writerows(fen)
    print(len(pages), 'pages ;', len(rows), 'lignes datées ;', len(fen), 'dans 1940-1998')

if __name__ == '__main__':
    main()
