"""R3 : arbitrage des variantes ANR (meme id_com, meme fenetre).

Regle, sans seuil qui choisisse : retenir la variante dont la part revendiquee
par une commune TIERCE est la plus faible ; a egalite, la plus grande. Le seuil
de 50 % ne sert qu a decider de l ABSTENTION : si meme la meilleure variante est
revendiquee pour l essentiel, l id_com n a pas de geometrie sur cette fenetre.
"""
import sqlite3, hashlib, collections, csv
from shapely import wkb, STRtree
SEUIL=0.50  # ne sert qu a decider de l abstention, jamais a choisir entre variantes
c=sqlite3.connect("sources/ANR_COMMUNES_22042026/COMMUNES_22042026.gpkg")
def g2w(b):
    f=b[3]; env=(f>>1)&7; n={0:0,1:32,2:48,3:48,4:64}[env]; return b[8+n:]
rows=[]
for i,nm,p,s,e,g in c.execute("select id_com,NameCom,Poly_ID,StartDt,EndDt,geom from geometries_only_processed"):
    if g is None: continue
    s=int(float(s)); e=int(float(e))
    if e<=s: continue
    rows.append((int(i),nm,p,s,e,g))
vu=set(); dd=[]
for r in rows:
    k=(r[2],hashlib.md5(g2w(r[5])).hexdigest())
    if k in vu: continue
    vu.add(k); dd.append(r)
grp=collections.defaultdict(list)
for r in dd: grp[(r[0],r[3],r[4])].append(r)
var={k:v for k,v in grp.items() if len(v)>1}
print(f"{len(var)} groupes, {sum(len(v) for v in var.values())} polygones")

w=csv.writer(open("build/anr_variantes.csv","w",newline=""))
w.writerow(["id_com","nom","poly_id","an_debut","an_fin","km2","pct_revendique","revendique_par","verdict"])
stat=collections.Counter()
for (k,s,e),v in sorted(var.items()):
    Y=(s+e)//2
    autres=[(r[0],r[1],wkb.loads(g2w(r[5]))) for r in dd if r[3]<=Y<r[4] and r[0]!=k]
    tree=STRtree([x[2] for x in autres])
    lignes=[]
    for r in v:
        g=wkb.loads(g2w(r[5]))
        pris=0.0; qui=collections.Counter()
        for j in tree.query(g, predicate="intersects"):
            a=g.intersection(autres[j][2]).area
            if a>1e4: pris+=a; qui[autres[j][1]]+=a
        pct=pris/g.area if g.area else 0
        lignes.append([r[2], g.area, pct, ";".join(n for n,_ in qui.most_common(2)), r[1]])
    # la moins revendiquee d abord ; a egalite, la plus grande
    meilleure=min(lignes, key=lambda l:(round(l[2],6), -l[1]))
    gagnant = meilleure[0] if meilleure[2]<=SEUIL else None
    for l in lignes:
        verdict=("retenu" if l[0]==gagnant else
                 "ecarte : aucune variante libre" if gagnant is None else
                 "ecarte : plus revendiquee" if l[2]>meilleure[2]+1e-6 else
                 "ecarte : variante plus petite")
        stat[verdict]+=1
        w.writerow([k,l[4],l[0],s,e,round(l[1]/1e6,3),round(l[2],4),l[3],verdict])
    if gagnant is None: stat["groupe sans geometrie retenue"]+=1
for kk,vv in stat.most_common(): print(f"  {vv:4}  {kk}")
