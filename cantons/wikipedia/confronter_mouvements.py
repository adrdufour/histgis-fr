"""Cherche, pour chaque mouvement non daté de mouvements_cantonaux.csv, la ou les
lignes de changements_wikipedia.csv du même département qui nomment la commune
(et, mieux, un des cantons en jeu). Ne tranche rien : propose une date et la cite.

Sortie : dates_proposees_wikipedia.csv
"""
import csv, re, unicodedata, collections, sys
R = sys.argv[1] if len(sys.argv) > 1 else '../..'
W = f'{R}/cantons/wikipedia'

def norm(s):
    s = unicodedata.normalize('NFD', s.lower())
    s = ''.join(c for c in s if unicodedata.category(c) != 'Mn')
    s = re.sub(r"[’'`]", "'", s)
    s = re.sub(r'\bst\b', 'saint', s); s = re.sub(r'\bste\b', 'sainte', s)
    return re.sub(r'[^a-z0-9\']+', ' ', s).strip()

# noms de communes : COG 1999 + tous les libellés du fichier des mouvements
noms = collections.defaultdict(set)
with open(f'{R}/sources/cog/1999/comsimp1999.txt', encoding='latin1') as f:
    for x in csv.DictReader(f, delimiter='\t'):
        art = x['ARTMIN'].strip('()')
        nom = x['NCCENR']
        noms[x['DEP'] + x['COM']].add(nom)
        if art: noms[x['DEP'] + x['COM']].add((art + ('' if art.endswith("'") else ' ') + nom))
for x in csv.DictReader(open(f'{R}/sources/v_mvt_commune_2025.csv')):
    for c, l in ((x['COM_AV'], x['LIBELLE_AV']), (x['COM_AP'], x['LIBELLE_AP'])):
        if l: noms[c].add(l)

def nom_canton(s):
    s = re.sub(r'^\S+\s+', '', s.strip())          # retire le code « 0102 »
    return s

wiki = collections.defaultdict(list)
for x in csv.DictReader(open(f'{W}/changements_wikipedia.csv')):
    x['_n'] = norm(x['texte'] + ' ' + x['autres_liens'] + ' ' + x['cantons_lies'])
    wiki[x['dep']].append(x)
for k in ('2A', '2B'): wiki['20'] += wiki[k]
for k in ('78', '91', '95'): wiki['78/91/95'] = wiki.get('78/91/95', [])

out = []
mv = list(csv.DictReader(open(f'{R}/cantons/mouvements_cantonaux.csv')))
for i, m in enumerate(mv):
    if m['date_retenue']:
        continue
    codes = re.findall(r'\b\d[\dAB]\d{3}\b', m['communes'])
    cand_cant = [norm(nom_canton(c)) for c in [m['canton_source']] + re.split(r'[;|]', m['cantons_resultants']) if c.strip()]
    deb = int(m['date_debut'][:4]) if m['date_debut'] else 1800
    fin = int(m['date_fin'][:4]) if m['date_fin'] else 2015
    lignes = wiki.get(m['dep'], [])
    for code in codes or ['']:
        ns = {norm(n) for n in noms.get(code, [])} - {''}
        for w in lignes:
            an = int(w['annee'])
            if not (deb <= an <= fin): continue
            hit_com = any(re.search(r"(^|[ '])" + re.escape(n) + r"($| )", w['_n']) for n in ns)
            hit_cant = [c for c in cand_cant if c and re.search(r"(^| )" + re.escape(c) + r"($| )", w['_n'])]
            if not hit_com and not (not codes and hit_cant): continue
            force = 'commune+canton' if hit_com and hit_cant else ('commune' if hit_com else 'canton')
            # une ville qui donne son nom au canton se retrouve dans toutes les lignes de ce canton
            if hit_com and any(any(n and n in c for n in ns) for c in cand_cant):
                force = 'ville_eponyme'
            out.append({'ligne_mouvement': i + 2, 'dep': m['dep'], 'type': m['type'], 'certitude': m['certitude'],
                        'canton_source': m['canton_source'], 'cantons_resultants': m['cantons_resultants'],
                        'commune': code, 'nom_commune': ' / '.join(sorted(noms.get(code, []))),
                        'fenetre': f"{m['date_debut']}..{m['date_fin']}",
                        'date_wikipedia': w['date'], 'precision': w['precision'], 'appariement': force,
                        'cantons_cites': '; '.join(hit_cant), 'texte_wikipedia': w['texte'][:400],
                        'references': w['references'][:300], 'page': w['page'], 'revid': w['revid']})

ch = list(out[0].keys())
with open(f'{W}/dates_proposees_wikipedia.csv', 'w', newline='') as f:
    wr = csv.DictWriter(f, ch); wr.writeheader(); wr.writerows(out)
non_dates = [m for m in mv if not m['date_retenue']]
touches = {(o['ligne_mouvement']) for o in out}
fort = {o['ligne_mouvement'] for o in out if o['appariement'] == 'commune+canton'}
# verdict par mouvement : une seule date proposée par appariement fort
g = collections.defaultdict(list)
for o in out: g[o['ligne_mouvement']].append(o)
verdict = {}
for k, v in g.items():
    fortes = {o['date_wikipedia'] for o in v if o['appariement'] in ('commune+canton', 'ville_eponyme')}
    verdict[k] = ('date_unique' if len(fortes) == 1 else 'dates_multiples' if fortes else 'appariement_faible')
for o in out: o['verdict'] = verdict[o['ligne_mouvement']]
with open(f'{W}/dates_proposees_wikipedia.csv', 'w', newline='') as f:
    wr = csv.DictWriter(f, list(out[0].keys())); wr.writeheader(); wr.writerows(out)
print('verdicts :', dict(collections.Counter(verdict.values())))
print('transferts isolés à date unique :', sum(1 for k, v in g.items() if v[0]['type'] == 'transfert' and verdict[k] == 'date_unique'))
print('mouvements non datés :', len(non_dates))
print('dont touchés par Wikipédia :', len(touches), '— par commune ET canton :', len(fort))
c = collections.Counter(m['type'] for j, m in enumerate(mv) if not m['date_retenue'] and (j + 2) in touches)
print('par type :', dict(c))
tr = [j+2 for j, m in enumerate(mv) if m['type'] == 'transfert']
print('transferts isolés (274) touchés :', len(set(tr) & touches), '— fort :', len(set(tr) & fort))
