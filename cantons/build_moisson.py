#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Assemble le moissonnage Legifrance en decrets_cantonaux.csv."""
import csv, collections, os

BASE='/sessions/festive-vigilant-planck/mnt/projet_carte/cantons'
DEP={"05":"HAUTES-ALPES","10":"AUBE","11":"AUDE","16":"CHARENTE","17":"CHARENTE-MARITIME","24":"DORDOGNE","33":"GIRONDE","36":"INDRE","39":"JURA","40":"LANDES","41":"LOIR-ET-CHER","42":"LOIRE","47":"LOT-ET-GARONNE","50":"MANCHE","51":"MARNE","53":"MAYENNE","57":"MOSELLE","60":"OISE","64":"PYRENEES-ATLANTIQUES","67":"BAS-RHIN","69":"RHONE","70":"HAUTE-SAONE","79":"DEUX-SEVRES","80":"SOMME","81":"TARN","82":"TARN-ET-GARONNE","86":"VIENNE","88":"VOSGES","02":"AISNE","03":"ALLIER","04":"ALPES-DE-HAUTE-PROVENCE","08":"ARDENNES","15":"CANTAL","23":"CREUSE","26":"DROME","28":"EURE-ET-LOIR","29":"FINISTERE","30":"GARD","34":"HERAULT","35":"ILLE-ET-VILAINE","37":"INDRE-ET-LOIRE","44":"LOIRE-ATLANTIQUE","45":"LOIRET","49":"MAINE-ET-LOIRE","55":"MEUSE","65":"HAUTES-PYRENEES","07":"ARDECHE","12":"AVEYRON","14":"CALVADOS","18":"CHER","32":"GERS","38":"ISERE","43":"HAUTE-LOIRE","54":"MEURTHE-ET-MOSELLE","71":"SAONE-ET-LOIRE","73":"SAVOIE","83":"VAR","84":"VAUCLUSE","85":"VENDEE","89":"YONNE","01":"AIN","06":"ALPES-MARITIMES","13":"BOUCHES-DU-RHONE","21":"COTE-D'OR","25":"DOUBS","31":"HAUTE-GARONNE","52":"HAUTE-MARNE","58":"NIEVRE","62":"PAS-DE-CALAIS","66":"PYRENEES-ORIENTALES","74":"HAUTE-SAVOIE","87":"HAUTE-VIENNE","48":"LOZERE","78":"YVELINES","22":"COTES-DU-NORD","27":"EURE","2B":"HAUTE-CORSE","56":"MORBIHAN","61":"ORNE","90":"TERRITOIRE DE BELFORT","09":"ARIEGE","46":"LOT","92":"HAUTS-DE-SEINE","94":"VAL-DE-MARNE","19":"CORREZE","2A":"CORSE-DU-SUD","20":"CORSE","59":"NORD","63":"PUY-DE-DOME","68":"HAUT-RHIN","72":"SARTHE","75":"PARIS","76":"SEINE-MARITIME","77":"SEINE-ET-MARNE","91":"ESSONNE","93":"SEINE-SAINT-DENIS","95":"VAL-D'OISE","971":"GUADELOUPE","972":"MARTINIQUE","973":"GUYANE","974":"REUNION"}
OBJ={'C':'creation de cantons','CM':'creation et modification de cantons','M':'modification de limites cantonales','S':'suppression de cantons','R':'rattachement de commune a un canton'}
# ecartes a la relecture : le titre porte « canton » sans qu'il s'agisse d'un
# acte de decoupage cantonal. On les signale ici, on ne les efface pas.
BRUIT={'677825':'caisses d epargne','334998':'commissaires-priseurs','305295':'tribunal',
       '704024':'Algerie (Oasis/Saoura), hors champ','679105':'extension a l Algerie, hors champ',
       '502524':'circonscriptions, portee generale'}

# Departements corriges apres relecture du titre complet et du JO.
#
# Le premier passage cherchait le nom du departement dans TOUT le titre, par
# simple inclusion de chaine. Or Legifrance met la liste des cantons crees
# entre parentheses a la fin du titre : « ... DANS LE DEPARTEMENT DE L'OISE
# (BEAUVAIS-NORD-OUEST, ...) ». Le « NORD » d'un nom de canton l'emportait
# alors sur le vrai departement. Trois decrets etaient donnes au Nord (59)
# qui n'y ont rien a voir. La regle est desormais : ne chercher qu'entre
# « DEPARTEMENT » et la parenthese ouvrante.
#
# C'est le meme defaut que le decret 82-35 perdu par « LIEVIN » : une
# sous-chaine qui existe ailleurs dans la ligne. Trois occurrences, trois
# formes.
CORRECTION_DEP={
 '336970':('60',"82-63 : L'OISE, lu Nord a cause de BEAUVAIS-NORD-OUEST ; confirme par l'en-tete du JO du 22 janvier 1982"),
 '686561':('61',"82-64 : L'ORNE, lu Nord ; confirme par l'en-tete du JO du 22 janvier 1982"),
 '883847':('01',"82-77 : L'AIN, lu Nord a cause de BOURG-NORD-CENTRE"),
 '334636':('', "82-82 : « dans divers departements » — le titre ne nomme aucun departement, l'ancien fichier lui donnait 54 par defaut"),
}

rows=[]
for l in open(os.path.join(os.path.dirname(os.path.abspath(__file__)),'moisson_brute.txt')):
    l=l.rstrip('\n')
    if not l: continue
    p=(l.split('|')+[''])[:7]
    rows.append(dict(id=p[0],num=p[1],sig=p[2],jo=p[3],obj=p[4],dep=p[5],note=p[6]))
# le decret 82-35 : perdu par un faux positif du filtre (LIEVIN contient VIN)
rows.append(dict(id='880300',num='82-35',sig='1982-01-15',jo='1982-01-16',obj='CM',dep='62',
                 note='ARRAS, LIEVIN, SAMER, CERVIN'))
for r in rows:
    if r['id'] in CORRECTION_DEP:
        r['dep'],r['note']=CORRECTION_DEP[r['id']][0],CORRECTION_DEP[r['id']][1]
ecartes=[r for r in rows if r['id'] in BRUIT]
rows=[r for r in rows if r['id'] not in BRUIT]

anc={x['legifrance_id']:x for x in csv.DictReader(open(os.path.join(BASE,'decrets_1973_1984.csv')))}
out=[]
for r in sorted(rows,key=lambda r:(r['sig'],r['num'] or 'zz',r['dep'])):
    lid='JORFTEXT'+r['id'].zfill(12)
    a=anc.get(lid)
    out.append(dict(
        date_signature=r['sig'],
        date_publication_jo=r['jo'],
        decret=('n° '+r['num']) if r['num'] else '',
        dep_code=r['dep'],
        dep_nom_epoque=DEP.get(r['dep'],''),
        objet=OBJ.get(r['obj'],r['obj']),
        cantons_cites_dans_le_titre=(a or {}).get('cantons_cites_dans_le_titre','') or r['note'],
        legifrance_id=lid,
        legifrance_url='https://www.legifrance.gouv.fr/jorf/id/'+lid,
        deja_repere='oui' if a else 'non',
        texte_integral_sur_legifrance='oui' if r['sig']>='1990' else 'non',
    ))
cols=list(out[0].keys())
with open(os.path.join(BASE,'decrets_cantonaux.csv'),'w',newline='') as f:
    w=csv.DictWriter(f,cols); w.writeheader(); w.writerows(out)
print('ecrit decrets_cantonaux.csv :',len(out),'decrets ;',sum(1 for x in out if x['deja_repere']=='non'),'nouveaux')
print('ecartes :',len(ecartes))

# --- JO a recuperer : un PDF par numero de JO, decrets < 1990 non deja dispo
dispo={f.split('_')[-1].replace('.txt','') for f in os.listdir('/sessions/festive-vigilant-planck/mnt/projet_carte/jorf_txt')}
have_dates=set()
for f in os.listdir('/sessions/festive-vigilant-planck/mnt/projet_carte/jorf_txt'):
    for part in f.split('_'):
        if len(part)==8 and part.isdigit(): have_dates.add(part)
g=collections.defaultdict(list)
for x in out:
    if x['texte_integral_sur_legifrance']=='oui': continue
    if x['deja_repere']=='oui': continue
    g[x['date_publication_jo']].append(x)
print('\nJO a recuperer (%d numeros, %d decrets) :'%(len(g),sum(len(v) for v in g.values())))
for d in sorted(g):
    tag='  [deja en jorf_txt]' if d.replace('-','') in have_dates else ''
    print('  %s  %2d decret(s)  %s%s'%(d,len(g[d]),','.join(sorted({x['dep_code'] for x in g[d]})),tag))
