#!/usr/bin/env python3
"""
histgis — extrait_circo.py : le tableau de correspondance du ministère de
l'Intérieur, réduit à ce qui est chargeable.

    cd circo && python3 extrait_circo.py

Produit `circo_2012.csv` : une ligne par (canton, entité, circonscription),
métropole seulement, à une granularité unique par commune.

Les règles viennent de note_circonscriptions.md, et chacune a une raison :

  * codes SANS zéros de tête — `dep` vaut « 1 » pour l'Ain, `com` vaut « 2 » ;
    concaténer naïvement confond l'Ain 355 et Marseille 13055 ;
  * outre-mer en `ZA`-`ZD` chez le ministère, écarté du périmètre ;
  * le fichier descend sous la commune : `AR` arrondissement, `SR` secteur,
    `SN` section électorale. 89 communes sont décrites à DEUX granularités à
    la fois — additionner sans choisir doublerait le territoire.

Granularité retenue : `AR` quand la commune en a (Paris, Lyon, Marseille, dont
nous avons les arrondissements comme atomes), la commune entière sinon. Les
`SN` sont ignorées — nous n'avons pas de section électorale — et les `SR`
aussi, un secteur marseillais valant deux arrondissements déjà comptés.
"""
import csv, collections, re, sys
import xlrd

SRC = 'correspondance_2012.xls'
OUT = 'circo_2012.csv'
OUT86 = 'circo_1986.csv'
OUT86IND = 'circo_1986_indetermine.csv'

# arrondissements municipaux : base de codes INSEE
BASE_AR = {'75056': 75100, '69123': 69380, '13055': 13200}


def lire():
    wb = xlrd.open_workbook(SRC)
    sh = wb.sheet_by_name('Communes de France')

    def cell(r, c):
        v = sh.cell_value(r, c)
        return str(int(v)) if isinstance(v, float) else str(v).strip()

    for r in range(2, sh.nrows):
        dc, dep, _, ct, nomct, com, nomcom, c86, c12 = [cell(r, c) for c in range(9)]
        if not dc:
            continue
        dep = dep.zfill(2)
        if not (dep.isdigit() or dep in ('2A', '2B')):
            continue                                  # outre-mer, hors périmètre
        base = dep + com[:3].zfill(3)
        suffixe = 'commune' if com.isdigit() else com[3:5]
        yield dict(canton=dc, dep=dep, base=base, suffixe=suffixe, brut=com,
                   nom=nomcom, c86=c86, c12=c12)


def main():
    lignes = list(lire())
    print(f"lignes métropole : {len(lignes)}")

    # quelle granularité pour chaque commune ?
    gran = collections.defaultdict(set)
    for l in lignes:
        gran[l['base']].add(l['suffixe'])
    retenue = {}
    for base, s in gran.items():
        retenue[base] = 'AR' if 'AR' in s else 'commune'

    print("granularité retenue :",
          dict(collections.Counter(retenue.values())))
    print("communes à granularités multiples :",
          sum(1 for s in gran.values() if len(s) > 1))

    sorties, ecarte = [], collections.Counter()
    for l in lignes:
        if l['suffixe'] != retenue[l['base']]:
            ecarte[l['suffixe']] += 1
            continue
        if l['suffixe'] == 'AR':
            n = int(l['brut'][5:])
            insee = str(BASE_AR[l['base']] + n)
        else:
            insee = l['base']
        if not l['c12'].isdigit():                    # 2012 est entièrement numérique
            ecarte['circo12 non numérique'] += 1
            continue
        sorties.append(dict(canton=l['canton'], insee=insee,
                            niveau=l['suffixe'], nom=l['nom'],
                            circo=l['dep'] + '-' + l['c12'].zfill(2)))

    print("lignes écartées :", dict(ecarte))
    print("lignes retenues :", len(sorties))

    circos = sorted(set(s['circo'] for s in sorties))
    print("circonscriptions 2012 :", len(circos))
    sieges = collections.Counter()
    for s in sorties:
        d = s['circo'][:2]
        sieges[d] = max(sieges[d], int(s['circo'][3:]))
    print("sièges métropole (somme des maxima) :", sum(sieges.values()),
          "— attendu 539")

    # un couple (canton, entité) partagé entre deux circos ne pourra pas être posé
    part = collections.defaultdict(set)
    for s in sorties:
        part[(s['canton'], s['insee'])].add(s['circo'])
    multi = {k: v for k, v in part.items() if len(v) > 1}
    print(f"couples (canton, entité) partagés entre circos : {len(multi)}")
    for k, v in sorted(multi.items())[:12]:
        print("   ", k, "→", sorted(v))

    with open(OUT, 'w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=['canton', 'insee', 'niveau', 'nom', 'circo'])
        w.writeheader()
        w.writerows(sorted(sorties, key=lambda s: (s['canton'], s['insee'], s['circo'])))
    print(f"\nécrit : {OUT}")

    # ------------------------------------------------------------------
    # Le découpage de 1986, à part — il a deux défauts que 2012 n'a pas
    # ------------------------------------------------------------------
    print("\n" + "=" * 60)
    print("DÉCOUPAGE DE 1986 (élections de 1988 à 2007)")
    print("=" * 60)

    s86, ind86, ec86 = [], [], collections.Counter()
    for l in lignes:
        if l['suffixe'] != retenue[l['base']]:
            ec86['granularité non retenue'] += 1
            continue
        if l['dep'] == '75':
            # Toutes les lignes parisiennes portent « 42 », alors que Paris
            # comptait 21 circonscriptions. Preuve par le total : la somme des
            # maxima donne 576 sièges au lieu de 555, et 576 − 42 + 21 = 555.
            ec86['Paris (code 42, inutilisable)'] += 1
            continue
        if not l['c86'].isdigit():
            # « 1 et 2 », « 16 et 17 » : le canton est à cheval sur plusieurs
            # circonscriptions, et le fichier ne dit PAS quelle commune va où.
            # La trame ne descend pas plus bas : ces communes n'ont pas de
            # circonscription assignable en 1986.
            #
            # Elles étaient auparavant comptées ici puis abandonnées. Comptées
            # n'est pas déclaré : la base ne portait aucune trace de leur
            # existence, et le contrôle « aucun couple canton-commune partagé »
            # de note_circonscriptions.md § 4 ter tournait sur des données
            # amputées de ses propres contre-exemples — il ne pouvait que
            # réussir.
            #
            # Elles sortent désormais dans un fichier à part, pour que
            # l'indétermination soit une donnée et non une absence.
            ind86.append(dict(canton=l['canton'],
                              insee=(str(BASE_AR[l['base']] + int(l['brut'][5:]))
                                     if l['suffixe'] == 'AR' else l['base']),
                              niveau=l['suffixe'], nom=l['nom'],
                              circos=' '.join(l['dep'] + '-' + n.zfill(2)
                                              for n in re.findall(r'\d+', l['c86'])),
                              brut=l['c86']))
            ec86['valeur textuelle (sortie dans ' + OUT86IND + ')'] += 1
            continue
        if l['suffixe'] == 'AR':
            insee = str(BASE_AR[l['base']] + int(l['brut'][5:]))
        else:
            insee = l['base']
        s86.append(dict(canton=l['canton'], insee=insee, niveau=l['suffixe'],
                        nom=l['nom'], circo=l['dep'] + '-' + l['c86'].zfill(2)))

    print("lignes écartées :", dict(ec86))
    print("lignes retenues :", len(s86))
    c86 = sorted(set(s['circo'] for s in s86))
    print("circonscriptions 1986 (hors Paris) :", len(c86))
    si = collections.Counter()
    for s in s86:
        si[s['circo'][:2]] = max(si[s['circo'][:2]], int(s['circo'][3:]))
    print("sièges hors Paris (somme des maxima) :", sum(si.values()),
          "— attendu 534 (555 − 21 parisiens)")

    p86 = collections.defaultdict(set)
    for s in s86:
        p86[(s['canton'], s['insee'])].add(s['circo'])
    m86 = {k: v for k, v in p86.items() if len(v) > 1}
    print("couples (canton, entité) partagés :", len(m86))

    with open(OUT86, 'w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=['canton', 'insee', 'niveau', 'nom', 'circo'])
        w.writeheader()
        w.writerows(sorted(s86, key=lambda s: (s['canton'], s['insee'], s['circo'])))
    print(f"\nécrit : {OUT86}")

    # ------------------------------------------------------------------
    # Les indéterminées, déclarées et non perdues
    # ------------------------------------------------------------------
    cant_ind = sorted({i['canton'] for i in ind86})
    print(f"\ncantons à cheval sur plusieurs circonscriptions : {len(cant_ind)}")
    print(f"communes sans circonscription assignable en 1986 : {len(ind86)}")
    print("   ", ' '.join(cant_ind))
    with open(OUT86IND, 'w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=['canton', 'insee', 'niveau', 'nom',
                                          'circos', 'brut'])
        w.writeheader()
        w.writerows(sorted(ind86, key=lambda s: (s['canton'], s['insee'])))
    print(f"écrit : {OUT86IND}")


if __name__ == '__main__':
    main()
