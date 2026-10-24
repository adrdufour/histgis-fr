#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
resoudre_1986_partage.py — lever les indéterminations du découpage de 1986.

    cd circo && python3 resoudre_1986_partage.py

Le problème
-----------
`circo_1986.csv` est extrait du tableau de correspondance du ministère de
l'Intérieur (`correspondance_2012.xls`), dont la colonne « 1986 » vaut parfois
« 16 et 17 » : le canton — celui de 2012, qui sert de clé — chevauchait deux
circonscriptions de 1986. `extrait_circo.py` a mis ces cas de côté plutôt que
de trancher, dans `circo_1986_indetermine.csv` : **125 communes, 13 cantons**.

Sur la carte, ces communes n'apparaissent pas du tout. Un silence honnête, mais
qui se donne à voir comme une lacune de la base.

La source qui tranche
---------------------
Le **§ 5 de l'Atlas historique des circonscriptions électorales françaises**
(Gaudillère, 1995) énumère les cantons divisés et dit, pour chacun, quelles
communes vont où. Transcription dans `circo/notes_1986_gaudillere.txt`.

C'est une source INDÉPENDANTE du ministère. Elle peut donc à la fois lever
l'indétermination et servir de contrôle là où le ministère avait tranché — et
les deux désaccords qu'elle révèle sont signalés en fin d'exécution plutôt que
résolus en silence.

Ce que fait ce script
---------------------
Les règles ci-dessous sont la transcription du texte, canton par canton. Elles
ne sont PAS déduites : chaque entrée porte la phrase d'origine.

La résolution des noms se fait **à l'intérieur du canton concerné**, jamais sur
la France entière : l'univers est de trois à seize communes, ce qui rend
l'appariement sûr malgré les coquilles de la transcription (« leps » pour
Lys-lez-Lannoy, « roncourt » pour Roucourt, « esquerlin » pour Esquerchin).
Chaque coquille est écrite ici, visible, et non corrigée silencieusement.

Trois degrés de certitude, portés dans la colonne `voie` :

  `nommee`   la commune est nommée dans le texte — le cas le plus sûr ;
  `reste`    elle tombe sous « le reste du canton », et l'identification du
             canton de 1986 avec celui de 2012 est directe ;
  `reserve`  idem, mais l'identification repose sur une correspondance de noms
             entre deux découpages cantonaux différents. À relire.

Sortie : `circo_1986_partage.csv`, colonnes canton, insee, nom, circo, voie.
N'écrit rien en base — c'est `49_circo_1986_partage.sql` qui charge.
"""

import csv
import sys
import unicodedata
from collections import defaultdict

REGISTRE = 'circo_1986_indetermine.csv'
SORTIE = 'circo_1986_partage.csv'


def cle(s):
    """Nom réduit à une clé comparable : sans accents, sans tirets, minuscule."""
    s = unicodedata.normalize('NFD', str(s))
    s = ''.join(c for c in s if unicodedata.category(c) != 'Mn').lower()
    for a, b in [("'", ' '), ('-', ' '), ('.', ' ')]:
        s = s.replace(a, b)
    return ' '.join(s.split())


# ---------------------------------------------------------------------------
# Les règles, transcrites du § 5. `phrase` est le texte d'origine : elle permet
# de relire la règle sans rouvrir la source.
#
# `nommees` : circonscription -> noms tels que le texte les écrit.
# `reste`   : circonscription des communes non nommées, ou None si le texte ne
#             la donne pas.
# ---------------------------------------------------------------------------
REGLES = [
    dict(canton='5940', label='Lille-Sud-Est', reste='59-01',
         nommees={'59-02': ['Lezennes', 'Ronchin']},
         phrase="lezennes et ronchin 2eme circonscription, le reste du canton 1re"),

    dict(canton='5933', label='Lannoy', reste=None,
         nommees={'59-06': ['Anstaing', 'Baisieux', 'Chéreng', 'Forest-sur-Marque',
                            'Gruson', 'Sailly-lez-Lannoy', 'Tressin', 'Willems'],
                  # « leps » : coquille de transcription pour Lys-lez-Lannoy.
                  # Le compte le confirme — 8 + 5 = 13, l'effectif du canton.
                  '59-07': ['Hem', 'Lannoy', 'Lys-lez-Lannoy', 'Leers', 'Toufflers']},
         phrase="anstaing, baisieux, chéreng, forest, gruson, sailly, tressin, "
                "willems 6eme ; hem, lannoy, leps, leers, toufflers 7eme"),

    dict(canton='5925', label='Dunkerque-Est', reste='59-13',
         nommees={'59-14': ['Bray-Dunes', 'Zuydcoote']},
         phrase="bray dunes et zuydcoote 14eme, le reste du canton 13eme"),

    dict(canton='5922', label='Douai-Nord', reste='59-16',
         nommees={'59-17': ['Sin-le-Noble', 'Waziers', 'Douai']},
         phrase="sin, waziers et la partie de douai appartenant a ce canton "
                "17eme, le reste du canton 16eme"),

    dict(canton='5924', label='Douai-Sud', reste='59-16',
         # « roncourt » : coquille pour Roucourt, seule commune approchante du canton.
         nommees={'59-17': ['Férin', 'Roucourt', 'Douai']},
         phrase="ferin, roncourt et la partie de douai 17eme, le reste 16eme"),

    dict(canton='5977', label='Douai-Nord-Est', reste='59-16', reserve=True,
         nommees={'59-17': ['Flers-en-Escrebieux', 'Douai']},
         phrase="canton douai ouest : courchelettes, cuincy, esquerlin, flers, "
                "lambers, lauwin et la partie de douai 17eme, le reste 16eme"),

    dict(canton='5967', label='Valenciennes-Sud', reste='59-19',
         nommees={'59-21': ['Valenciennes']},
         phrase="la partie de la ville appartenant a ce canton 21eme, "
                "le reste du canton dans la 19eme"),

    dict(canton='5966', label='Valenciennes-Nord', reste='59-20',
         nommees={'59-21': ['Valenciennes']},
         phrase="la partie de la ville de valenciennes appartenant a ce canton "
                "21eme, le reste du canton 20eme"),

    dict(canton='5971', label='Anzin', reste='59-20',
         nommees={'59-21': ['Saint-Saulve']},
         phrase="saint saulve 21eme, le reste du canton 20eme"),

    dict(canton='6952', label='Limonest (partie Champagne)', reste=None,
         nommees={'69-10': ['Dardilly'],
                  '69-05': ["Champagne-au-Mont-d'Or", 'Ecully']},
         phrase="dardilly dans la 10eme ; champagne, collonges, ecully, "
                "saint-cyr et saint didier dans la 5eme ; le reste dans la 8eme"),

    dict(canton='6910', label='Limonest', reste='69-08',
         nommees={'69-05': ["Collonges-au-Mont-d'Or", "Saint-Cyr-au-Mont-d'Or",
                            "Saint-Didier-au-Mont-d'Or"]},
         phrase="idem — la part du canton de Limonest restée sous ce code"),

    dict(canton='1311', label='Istres', reste='13-13',
         nommees={'13-16': ['Miramas']},
         phrase="miramas dans la 16eme, saint-chamas dans la 12eme, "
                "le reste du canton dans la 13eme"),

    dict(canton='1351', label='Salon', reste='13-11',
         nommees={'13-15': ['Aurons', 'La Barben', 'Pélissanne']},
         phrase="aurons, la barben et pélissanne dans la 15eme, "
                "le reste du canton dans la 11eme"),

    dict(canton='6716', label='Obernai', reste='67-05',
         nommees={'67-04': ['Innenheim']},
         phrase="innenheim, enclavée dans le canton de geispolsheim, "
                "incluse avec le 1er dans la 4eme"),

    dict(canton='1751', label='Saintes-Est', reste='17-03',
         nommees={'17-04': ['Colombiers', 'La Jard']},
         phrase="colombier et la jard, enclavées entre pons et gémozac, "
                "placées dans la 4eme ; le reste du canton dans la 3eme"),

    # Le Bourget : le seul canton à TROIS circonscriptions possibles chez le
    # ministère (3, 4 et 5). Le § 5 n'en dit rien : la carte « 1986 » de la
    # Seine-Saint-Denis (photo 131, fond communal) ne divise que Saint-Denis,
    # et range Dugny et Le Bourget avec Le Blanc-Mesnil et Stains (4e), Drancy
    # avec Bobigny (5e). Lu le 24 octobre 2026.
    dict(canton='9309', label='Le Bourget', reste=None,
         nommees={'93-04': ['Le Bourget', 'Dugny'], '93-05': ['Drancy']},
         phrase="(carte 1986, pas de texte) dugny et le bourget 4eme, "
                "drancy 5eme"),

    dict(canton='2613', label='Loriol', reste='26-02',
         nommees={'26-03': ['Ambonil']},
         phrase="ambonil, enclavé dans le canton de crest nord, "
                "placé comme ce dernier dans la 3eme"),
]

# Cantons que le texte déclare divisés mais que le ministère avait tranchés
# d'un seul tenant. Ce sont des DÉSACCORDS entre deux sources, pas des trous :
# on ne les résout pas, on les signale.
DESACCORDS = ['canton de douai ouest', 'canton de condé sur escaut']


def main():
    registre = list(csv.DictReader(open(REGISTRE, encoding='utf-8')))
    par_canton = defaultdict(list)
    for r in registre:
        par_canton[r['canton']].append(r)

    lignes, ennuis = [], []

    for regle in REGLES:
        ct = regle['canton']
        membres = par_canton.get(ct)
        if not membres:
            ennuis.append(f"canton {ct} ({regle['label']}) : absent du registre")
            continue

        index = {}
        for m in membres:
            index.setdefault(cle(m['nom']), []).append(m)

        pris = set()
        for circo, noms in regle['nommees'].items():
            for nom in noms:
                trouve = index.get(cle(nom))
                if not trouve:
                    ennuis.append(f"canton {ct} ({regle['label']}) : "
                                  f"« {nom} » introuvable parmi "
                                  f"{sorted(m['nom'] for m in membres)}")
                    continue
                for m in trouve:
                    if m['insee'] in pris:
                        continue
                    pris.add(m['insee'])
                    lignes.append(dict(canton=ct, insee=m['insee'], nom=m['nom'],
                                       circo=circo, voie='nommee'))

        if regle.get('reste'):
            voie = 'reserve' if regle.get('reserve') else 'reste'
            for m in membres:
                if m['insee'] not in pris:
                    lignes.append(dict(canton=ct, insee=m['insee'], nom=m['nom'],
                                       circo=regle['reste'], voie=voie))
        else:
            for m in membres:
                if m['insee'] not in pris:
                    ennuis.append(f"canton {ct} ({regle['label']}) : "
                                  f"{m['nom']} ({m['insee']}) non nommée et "
                                  f"pas de « reste » dans le texte")

    with open(SORTIE, 'w', newline='', encoding='utf-8') as fh:
        w = csv.DictWriter(fh, fieldnames=['canton', 'insee', 'nom', 'circo', 'voie'])
        w.writeheader()
        w.writerows(sorted(lignes, key=lambda r: (r['canton'], r['insee'])))

    # -- recette -----------------------------------------------------------
    couvert = {r['insee'] for r in lignes}
    tous = {r['insee'] for r in registre}
    par_voie = defaultdict(int)
    for r in lignes:
        par_voie[r['voie']] += 1

    print(f"{SORTIE} : {len(lignes)} lignes, {len(couvert)} communes")
    for v, n in sorted(par_voie.items()):
        print(f"   {v:<10} {n:>4}")

    print(f"\nregistre : {len(tous)} communes indéterminées")
    reste = sorted(tous - couvert)
    print(f"non levées : {len(reste)}")
    par_ct = defaultdict(list)
    for r in registre:
        if r['insee'] in reste:
            par_ct[r['canton']].append(r['nom'])
    for ct, noms in sorted(par_ct.items()):
        print(f"   canton {ct} : {', '.join(sorted(set(noms)))}")

    # Contrôle : chaque circonscription posée doit figurer parmi les deux (ou
    # trois) que le ministère annonçait pour ce canton. Un écart signifierait
    # que la règle a été mal transcrite.
    annonce = {r['canton']: set(r['circos'].split()) for r in registre}
    faux = [r for r in lignes if r['circo'] not in annonce.get(r['canton'], set())]
    print(f"\ncirconscriptions hors de celles annoncées par le ministère : {len(faux)}")
    for r in faux[:20]:
        print(f"   {r['canton']} {r['nom']} -> {r['circo']} "
              f"(annoncé : {' '.join(sorted(annonce.get(r['canton'], [])))})")

    if ennuis:
        print(f"\nÀ REGARDER ({len(ennuis)}) :")
        for e in ennuis:
            print(f"   {e}")

    print("\nDésaccords entre l'atlas et le ministère, non résolus :")
    for d in DESACCORDS:
        print(f"   {d} — divisé selon l'atlas, d'un seul tenant selon le ministère")

    return 0


if __name__ == '__main__':
    sys.exit(main())
