"""Les actes que Wikipédia date au jour (1940-1998) sont-ils au registre
decrets_cantonaux.csv ? Un acte = (département, date). Tolérance : ±3 jours sur
la signature ou la publication, Wikipédia citant indifféremment l'une ou l'autre.
Sortie : actes_wikipedia_vs_registre.csv
"""
import csv, collections, datetime as dt, sys
R = sys.argv[1] if len(sys.argv) > 1 else '../..'
d = lambda s: dt.date.fromisoformat(s)
reg = collections.defaultdict(list)
for x in csv.DictReader(open(f'{R}/cantons/decrets_cantonaux.csv')):
    for k in ('date_signature', 'date_publication_jo'):
        if x[k]: reg[x['dep_code'].zfill(2)].append((d(x[k]), x))
actes = collections.defaultdict(list)
for x in csv.DictReader(open(f'{R}/cantons/wikipedia/changements_wikipedia_1940_1998.csv')):
    if x['precision'] == 'jour':
        actes[(x['dep'], x['date'])].append(x)
out = []
for (dep, date), lignes in sorted(actes.items()):
    deps = {'20': ['20','2A','2B'], '2A': ['20','2A'], '2B': ['20','2B']}.get(dep, [dep])
    hits = [x for dd in deps for (t, x) in reg.get(dd, []) if abs((t - d(date)).days) <= 3]
    out.append({'dep': dep, 'date_wikipedia': date, 'au_registre': 'oui' if hits else 'non',
                'acte_registre': ' ; '.join(sorted({f"{h['date_signature']} {h['objet']} {h['legifrance_id']}" for h in hits})),
                'nb_lignes': len(lignes), 'nature': ';'.join(sorted({n for l in lignes for n in l['nature'].split(';') if n})),
                'texte': ' // '.join(l['texte'][:200] for l in lignes)[:800],
                'references': ' // '.join(sorted({l['references'][:250] for l in lignes if l['references']}))[:600],
                'page': lignes[0]['page']})
with open(f'{R}/cantons/wikipedia/actes_wikipedia_vs_registre.csv', 'w', newline='') as f:
    w = csv.DictWriter(f, list(out[0])); w.writeheader(); w.writerows(out)
c = collections.Counter((o['au_registre'], o['date_wikipedia'][:4] >= '1958') for o in out)
print(len(out), 'actes datés au jour ;', dict(c))
