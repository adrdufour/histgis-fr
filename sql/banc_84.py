#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""banc_84.py — le treillis de faces, éprouvé hors base sur l'export web.

    python3 sql/banc_84.py 1870          # les 98 départements
    python3 sql/banc_84.py 1870 01       # un seul, en détail

Ce n'est pas le livrable : c'est ce qui donne à `sql/84_carte_partition.sql`
ses chiffres attendus, et ce qui permet de dire qu'un algorithme a été mesuré
avant d'être écrit en SQL. Même rôle que `banc_82.sh` pour `82`, à ceci près
qu'un algorithme TOPOLOGIQUE ne peut pas s'éprouver sur des empreintes MD5 :
il lui faut de la vraie géométrie. D'où le choix de l'export web comme entrée —
`cartes/web/donnees/`, qui porte exactement ce que la carte dessine.

CE QUE CE BANC NE PEUT PAS DIRE. L'export est en WGS84 accroché à une grille de
25 m ; les surfaces sont donc approchées par un facteur équirectangulaire local
(±0,3 % sur la France), là où `84` travaillera en Lambert-93 exact. Les COMPTES
— faces, motifs, mères désignées, recouvrement résiduel nul ou non — sont
exacts ; les KM² sont des ordres de grandeur. Ne pas recopier ces derniers dans
la recette SQL sans les remesurer en base.

L'ALGORITHME, ET POURQUOI CHAQUE RÈGLE EST SANS SEUIL
-----------------------------------------------------
Le défaut à corriger est la couture de la trame hybride : là où un atome
retombe sur `atom_geom` (GEOFLA 2011) pendant que ses voisins sont dessinés par
ANR, les bords ne coïncident plus. 4 543 km² de recouvrement à 1870, contre
1,0 km² entre deux polygones ANR.

  1. **LA REPRISE.** Un atome que notre base fait vivre à la date et qu'ANR ne
     pourvoit pas alors reçoit **la différence des deux polygones du voisin qui
     s'en sépare l'année de sa prochaine apparition chez ANR** :

         territoire(fille, D) = voisin(D) − voisin(Y′),
         où Y′ est la première année > D où ANR pourvoit la fille,
         et le voisin est celui dont la chronologie ANR porte une coupure en Y′.

     Deux polygones datés, une soustraction, aucun seuil, et une frontière
     d'époque au lieu d'une frontière de 2011. Si plusieurs filles reparaissent
     la même année, la différence se partage en donnant chaque morceau à celle
     dont le polygone de repli le recouvre le plus — le repli redevient ce
     qu'il sait faire, un indice de position, jamais une mesure de surface.

     CE FICHIER A PORTÉ DEUX RÈGLES AVANT DE N'EN PORTER QU'UNE, et les deux
     échecs valent d'être gardés.

     *Premier échec — le repli n'est pas le territoire de la fille.* La règle
     disait d'abord : la fille garde son polygone GEOFLA, on le retranche de la
     mère. Résultat dans l'Ain : Loyes 10,08 → 0,48 km², Crépieux-la-Pape
     14,95 → 11,56, Rillieux-la-Pape réduite à 0,08 km². La cause est que
     `atom_geom` porte le polygone de la commune TERMINALE de la lignée
     Cassini — pour l'atome 40689 c'est Villieu-Loyes-Mollon, la fusionnée de
     1973, qui contient sa propre mère. *Un polygone de repli répond à la
     question « où est cette commune aujourd'hui », pas « quel sol tenait-elle
     alors ».*

     *Second échec — un trou de chronologie n'est pas une lacune.* La règle 0
     comblait les trous d'ANR en reportant le dernier polygone antérieur.
     Sur l'Aveyron, les dix plus grosses faces disputées portaient toutes ce
     motif : Saint-Beaulize contre Fondamente, La Serre contre
     Saint-Sernin-sur-Rance, Les Albres contre Aspriéres… Ces communes-là ont
     été RÉUNIES à leur voisine puis rétablies (chantier `41`), et le trou
     d'ANR est un fait, pas un oubli. Reporter le polygone d'avant la réunion
     par-dessus une voisine qui, elle, l'avait absorbé, recréait exactement le
     double comptage qu'on venait d'ôter. *Un trou dans une source datée peut
     être ce qu'elle a de plus exact.*

     La règle unique ci-dessus traite les deux cas sans les distinguer :
     naissance et rétablissement sont la même chose vue d'ANR — une
     réapparition en Y′, et une voisine qui se coupe le même millésime.

  2. **Polygoniser.** Nouer toutes les frontières, en tirer les faces. Une
     face est indivisible : elle a un propriétaire et un seul, ce qui rend le
     recouvrement impossible par construction plutôt que corrigé après coup.

  3. **Arbitrer chaque face**, dans l'ordre, en gardant le motif :
       `unique`          un seul candidat ;
       `source_datee`    un polygone ANR contre un repli sans filiation :
                         à l'ANR — la source datée garde son bord ;
       `departage`       à égalité, au plus petit polygone puis au plus petit
                         identifiant : déterministe, et rare ;
       `comblement`      aucun candidat — un trou interne — au voisin
                         partageant le plus long bord, itéré.

  4. **Redissoudre.** Les limites cantonales sont faites des mêmes arêtes que
     les limites communales : elles coïncident sans qu'on ait à le demander.

CE QUE LE TREILLIS NE TOUCHE PAS. Les 333 fractions et les villes partagées
entrent comme UN propriétaire — la commune-mère — et ressortent dupliquées par
canton avec leur drapeau, comme aujourd'hui. Leur superposition est connue,
nommée et hachurée en légende ; la lever demande de tracer une ligne qu'aucune
source ne porte, et c'est un autre chantier.
"""
import json
import math
import os
import sys
import csv
import collections
import sqlite3

from shapely.geometry import shape
from shapely.ops import unary_union, polygonize
from shapely.strtree import STRtree

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE = os.path.join(RACINE, 'cartes', 'web', 'donnees', 'dep')
GPKG = os.path.join(RACINE, 'ANR_COMMUNES_22042026', 'COMMUNES_22042026.gpkg')

MOTIFS = ('unique', 'source_datee', 'departage', 'comblement')

# --- la règle de partage d'une fratrie, et les deux façons de la poser -------
#
# `--mosaique` (5 septembre 2026) change UNE chose, et c'est celle que la base a
# désignée comme fausse :
#
#   RÈGLE HISTORIQUE — le morceau connexe entier va à la fille dont le repli le
#   recouvre le plus. `ST_Dump` / `.geoms` ne sépare que les composantes
#   DÉCONNECTÉES, donc six filles voisines ne font qu'un morceau et une seule
#   sert. Mesuré en base le 5 septembre : des six filles de Tournon-d'Agenais,
#   Bourlens garde 73,518 km² pour un repli de 15,578 et les cinq autres ne
#   sont PAS DESSINÉES.
#
#   RÈGLE MOSAÏQUE — chaque fille reçoit `reste ∩ son repli`. Ce qu'aucun repli
#   ne réclame n'est donné à personne ici : le treillis le voit comme un trou et
#   le comble au voisin partageant le plus long bord, ce qui est le
#   comportement déjà déclaré. Aucun seuil, aucune proportion, aucune ligne
#   inventée — le repli reste un indice de POSITION, et la frontière posée est
#   celle du treillis.
#
# Ce qui autorise ce changement, et qui a été mesuré avant de l'écrire : la
# somme des replis des sœurs reproduit le morceau à moins d'un pour cent
# (73,793 contre 73,518 ; 18,942 contre 19,080). La mosaïque des replis PAVE le
# territoire à partager, elle ne le devine pas.
MOSAIQUE = False


# --- ce qu'ANR sait des naissances ----------------------------------------

def charge_filiation():
    """atom_id -> débuts de polygones ANR, et atom_id -> toutes ses bornes.

    Lu sur le gpkg et pas sur l'export : l'export borne ses versions à 1815 et
    confondrait une réapparition avec un début de fenêtre. C'est précisément la
    confusion qui faisait passer les trous de chronologie pour des
    superpositions inexpliquées.
    """
    a2c = {r['atom_id']: r['cassini']
           for r in csv.DictReader(open(os.path.join(RACINE, 'build', 'atom.csv')))}
    per = collections.defaultdict(list)
    con = sqlite3.connect(GPKG)
    for idc, s, e in con.execute(
            'SELECT id_com, StartDt, EndDt FROM geometries_only_processed'):
        try:
            per[str(idc)].append((int(float(s)), int(float(e))))
        except (TypeError, ValueError):
            pass
    debuts, bornes = {}, {}
    for atom, cass in a2c.items():
        p = per.get(cass)
        if not p:
            continue
        debuts[atom] = sorted({s for s, _ in p})
        bornes[atom] = {b for s, e in p for b in (s, e)}
    return debuts, bornes


def reapparition(atom, an, debuts):
    """La première année > `an` où ANR pourvoit cet atome, ou None.

    Naissance et rétablissement se lisent pareil : ANR n'a qu'une manière de
    dire « à partir d'ici, cette commune a un polygone ».
    """
    for s in debuts.get(atom, ()):
        if s > an:
            return s
    return None


def version(e, an):
    """La version géométrique en vigueur à `an`, ou None."""
    v = None
    for x in e['v']:
        if int(x['a']) <= an:
            v = x
    return v


def est_repli(v):
    return str(v['r']) == '1'


# --- le treillis -----------------------------------------------------------

def partition(polys, meta):
    """polys[i] polygone, meta[i] (cle, est_repli, aire).

    Rend (proprio, motif, faces), parallèles aux faces polygonisées.
    """
    frontieres = unary_union([p.boundary for p in polys])
    faces = [f for f in polygonize(frontieres) if not f.is_empty]
    arbre = STRtree(polys)

    proprio = [None] * len(faces)
    motif = [None] * len(faces)
    for k, f in enumerate(faces):
        pt = f.representative_point()
        cand = [int(i) for i in arbre.query(pt) if polys[int(i)].contains(pt)]
        if not cand:
            continue                                   # trou interne : plus bas
        if len(cand) == 1:
            proprio[k], motif[k] = cand[0], 'unique'
            continue
        dates = [i for i in cand if not meta[i][1]]
        if len(dates) == 1:
            proprio[k], motif[k] = dates[0], 'source_datee'
            continue
        pool = dates or cand
        proprio[k] = min(pool, key=lambda i: (meta[i][2], meta[i][0]))
        motif[k] = 'departage'

    # Les trous internes, au voisin partageant le plus long bord. Itéré, parce
    # qu'un trou peut ne toucher que d'autres trous ; on s'arrête dès qu'un
    # tour n'attribue plus rien, et ce qui reste est déclaré, pas comblé.
    arbre_f = STRtree(faces)
    reste = [k for k in range(len(faces)) if proprio[k] is None]
    while reste:
        progres, encore = False, []
        for k in reste:
            best, blen = None, 0.0
            for j in arbre_f.query(faces[k]):
                j = int(j)
                if j == k or proprio[j] is None:
                    continue
                bord = faces[k].intersection(faces[j])
                lg = bord.length if bord.geom_type != 'Point' else 0.0
                if lg > blen:
                    best, blen = proprio[j], lg
            if best is None:
                encore.append(k)
            else:
                proprio[k], motif[k] = best, 'comblement'
                progres = True
        if not progres:
            break
        reste = encore
    return proprio, motif, faces


# --- un département, à une date -------------------------------------------

def charge_dep(dep, an, debuts, bornes):
    """Les polygones d'un département après les règles 0 et 1.

    Séparé de `fait_dep` parce qu'un département a besoin de ses VOISINS pour
    être traité correctement : sans eux, un territoire enclavé — la Seine dans
    la Seine-et-Oise de 1870, l'enclave des papes dans la Drôme — ressemble à
    un trou du dessin, et le comblement le donne au premier voisin venu. Le
    premier jet de ce banc offrait ainsi les 478 km² du département de la Seine
    à ses voisines. *Un trou n'est un trou que dans un cadre assez large pour
    contenir ce qui le remplit.*
    """
    d = os.path.join(BASE, dep)
    ip = os.path.join(d, 'index.json')
    if not os.path.exists(ip):
        return None
    ix = json.load(open(ip))
    if str(an) not in ix['annees']:
        return None
    sig = ix['annees'][str(an)].get('c')
    if not sig:
        return None
    ratt = json.load(open(os.path.join(d, 'c_%s.json' % sig)))['rattachement']
    com = json.load(open(os.path.join(d, 'communes.json')))['communes']

    # `origine` garde ce que la carte dessine AUJOURD'HUI, pour mesurer l'écart.
    brut, compte, origine = {}, collections.Counter(), {}
    for k in ratt:
        e = com.get(k)
        if not e:
            continue
        v = version(e, an)
        if not v:
            continue
        try:
            po = shape(v['g']).buffer(0)
            if not po.is_empty:
                origine[k] = po
        except Exception:
            pass
        if not est_repli(v):
            brut[k] = (v['g'], 'anr', e['n'])
            compte['anr'] += 1
        else:
            brut[k] = (v['g'], 'repli', e['n'])
            compte['repli'] += 1

    geoms = {}
    for k, (gj, src, nom) in brut.items():
        try:
            p = shape(gj).buffer(0)
        except Exception:
            continue
        if not p.is_empty:
            geoms[k] = p

    # --- LA REPRISE : la fille reçoit la différence des polygones du voisin ---
    # `filles[voisin][Y]` : les atomes que la base fait vivre ici, qu'ANR ne
    # pourvoit pas à cette date, et qu'il fait reparaître en Y chez ce voisin.
    filles = collections.defaultdict(lambda: collections.defaultdict(list))
    sans_mere = []
    for k, (gj, src, nom) in list(brut.items()):
        if src != 'repli' or k not in geoms:
            continue
        Y = reapparition(k, an, debuts)
        if Y is None:
            continue                       # ANR ne la pourvoit jamais après
        mere = None
        for j, (gj2, src2, nom2) in brut.items():
            if j == k or src2 == 'repli' or j not in geoms:
                continue
            if Y not in bornes.get(j, ()):
                continue
            if geoms[k].intersects(geoms[j]):
                mere = j
                break
        if mere is None:
            sans_mere.append(k)
        else:
            filles[mere][Y].append(k)

    n_filles = n_partages = 0
    for mere, parY in filles.items():
        e_mere = com[mere]
        for Y, kids in parY.items():
            apres = next((x for x in e_mere['v']
                          if int(x['a']) == Y and not est_repli(x)), None)
            if apres is None:
                sans_mere.extend(kids)
                continue
            try:
                g_ap = shape(apres['g']).buffer(0)
            except Exception:
                sans_mere.extend(kids)
                continue
            diff = geoms[mere].difference(g_ap)
            if diff.is_empty:
                sans_mere.extend(kids)
                continue
            if len(kids) == 1:
                geoms[kids[0]] = diff
                brut[kids[0]] = (None, 'fille_anr', brut[kids[0]][2])
                n_filles += 1
            elif MOSAIQUE:
                # RÈGLE MOSAÏQUE — chaque fille prend ce que SON repli couvre
                # dans le reste. Deux filles contiguës cessent de se disputer un
                # morceau indivisible, puisqu'on ne partage plus des morceaux
                # mais du sol. Ce qu'aucun repli ne réclame reste sans
                # propriétaire : le treillis le comblera au plus long bord.
                pris = []
                for c in kids:
                    p = diff.intersection(geoms[c]).buffer(0)
                    if p.is_empty or p.area <= 0:
                        sans_mere.append(c)
                        continue
                    geoms[c] = p
                    brut[c] = (None, 'fille_anr', brut[c][2])
                    n_filles += 1
                    pris.append(c)
                if len(pris) > 1:
                    n_partages += 1
                elif not pris:
                    pass
            else:
                # RÈGLE HISTORIQUE — plusieurs filles la même année : chaque
                # morceau va à celle dont le repli le recouvre le plus. Le repli
                # sert d'indice de position, jamais de mesure. C'est la règle
                # que la mesure du 5 septembre 2026 a prise en défaut sur les
                # fratries CONTIGUËS, où il n'y a qu'un morceau pour six filles.
                morceaux = list(diff.geoms) if hasattr(diff, 'geoms') else [diff]
                part = {c: [] for c in kids}
                for m in morceaux:
                    best = max(kids, key=lambda c: geoms[c].intersection(m).area)
                    part[best].append(m)
                for c, ms in part.items():
                    if ms:
                        geoms[c] = unary_union(ms)
                        brut[c] = (None, 'fille_anr', brut[c][2])
                        n_filles += 1
                    else:
                        sans_mere.append(c)
                n_partages += 1
            geoms[mere] = g_ap        # la mère se réduit à son polygone d'après

    return dict(dep=dep, geoms=geoms, brut=brut, origine=origine,
                compte=compte, filles=n_filles, partages=n_partages,
                sans_mere=len(sans_mere))


def emprises():
    """Boîte englobante de chaque département, lue sur `contours.json`.

    Bon marché : il ne s'agit que de savoir QUI est voisin de qui, pas de
    dessiner. Charger les 98 `communes.json` pour cela coûterait cent fois plus.
    """
    box = {}
    for dep in sorted(os.listdir(BASE)):
        p = os.path.join(BASE, dep, 'contours.json')
        if not os.path.exists(p):
            continue
        c = json.load(open(p))
        gs = [shape(g) for g in c.values()]
        if not gs:
            continue
        b = [g.bounds for g in gs]
        box[dep] = (min(x[0] for x in b), min(x[1] for x in b),
                    max(x[2] for x in b), max(x[3] for x in b))
    return box


def voisins(dep, box):
    """Les départements dont l'emprise touche celle de `dep`, à 0,25° près."""
    b = box.get(dep)
    if not b:
        return []
    return [a for a, c in box.items()
            if a != dep and b[0] - .25 <= c[2] and c[0] <= b[2] + .25
            and b[1] - .25 <= c[3] and c[1] <= b[3] + .25]


def fait_dep(dep, an, debuts, bornes, detail=False, charge=None, bbox=None):
    charge = charge if charge is not None else {}
    bbox = bbox if bbox is not None else emprises()

    def prends(dd):
        if dd not in charge:
            charge[dd] = charge_dep(dd, an, debuts, bornes)
        return charge[dd]

    r = prends(dep)
    if not r or not r['geoms']:
        return None
    geoms, brut, origine, compte = r['geoms'], r['brut'], r['origine'], r['compte']

    # --- un propriétaire par polygone DISTINCT ------------------------------
    # Les fractions d'une même commune-mère partagent le leur et ne doivent pas
    # se disputer le treillis : elles ressortent dupliquées, drapeau compris.
    groupes = {}
    for k, p in geoms.items():
        cle = p.wkb_hex if p.geom_type != 'GeometryCollection' else 'x' + k
        g = groupes.setdefault(cle, {'atomes': [], 'nom': brut[k][2],
                                     'src': brut[k][1]})
        g['atomes'].append(k)

    polys, meta, cles = [], [], []
    for cle, g in groupes.items():
        p = geoms[g['atomes'][0]]
        polys.append(p)
        meta.append((cle, g['src'] == 'repli', p.area))
        cles.append(cle)
    if not polys:
        return None
    n_propre = len(polys)

    # Le contexte : les voisins entrent dans le treillis, jamais dans le
    # résultat. Ils ne sont là que pour qu'un enclavé cesse d'être un trou.
    for dd in voisins(dep, bbox):
        rv = prends(dd)
        if not rv:
            continue
        vus = set()
        for k, p in rv['geoms'].items():
            cle = p.wkb_hex if p.geom_type != 'GeometryCollection' else 'x' + k
            if cle in vus:
                continue
            vus.add(cle)
            polys.append(p)
            meta.append((cle, rv['brut'][k][1] == 'repli', p.area))
            cles.append(cle)

    proprio, motif, faces = partition(polys, meta)

    lat0 = math.radians(sum(p.centroid.y for p in polys) / len(polys))
    f = 111320 * math.cos(lat0) * 110570 / 1e6          # deg² -> km², localement

    def recouvrement(gs):
        arbre = STRtree(gs)
        vus, s = set(), 0.0
        for i, p in enumerate(gs):
            for j in arbre.query(p):
                j = int(j)
                if j <= i or (i, j) in vus:
                    continue
                vus.add((i, j))
                if p.intersects(gs[j]):
                    g = p.intersection(gs[j])
                    if g.geom_type in ('Polygon', 'MultiPolygon'):
                        s += g.area * f
        return s

    # Ce que la polygonisation ne rend pas : l'union des faces devrait valoir
    # l'union des polygones. L'écart est une perte de topologie, pas un
    # arbitrage — il se mesure à part et ne se comble pas en silence.
    propre = unary_union(polys[:n_propre])
    perte = (propre.difference(unary_union(faces)).area
             if faces else propre.area)

    # Les faces du contexte ne sont là que pour tenir la topologie : ni le
    # décompte des motifs ni le résultat ne les regardent.
    par_mot, aire_mot, orphelines = collections.Counter(), collections.Counter(), 0.0
    parts = collections.defaultdict(list)
    for k, pr in enumerate(proprio):
        if pr is None:
            if propre.contains(faces[k].representative_point()):
                orphelines += faces[k].area * f
            continue
        if pr >= n_propre:
            continue
        par_mot[motif[k]] += 1
        aire_mot[motif[k]] += faces[k].area * f
        parts[pr].append(faces[k])
    nets = {i: unary_union(v) for i, v in parts.items()}
    ids = sorted(nets)

    # Le résultat, atome par atome, pour pouvoir le comparer à ce que la carte
    # dessine AUJOURD'HUI — c'est-à-dire aux polygones d'avant les règles 0 et 1.
    final = {}
    for cle_i, i in ((cles[i], i) for i in ids):
        for a in groupes[cle_i]['atomes']:
            final[a] = nets[i]

    if detail:
        for a in sorted(final, key=lambda x: brut[x][2]):
            av = origine[a].area * f
            ap = final[a].area * f
            if abs(av - ap) > 0.05:
                print('   %-30s %-12s %8.3f -> %8.3f km²  (%+.3f)'
                      % (brut[a][2], brut[a][1], av, ap, ap - av))

    return dict(dep=dep, n_poly=n_propre, n_faces=len(faces),
                n_contexte=len(polys) - n_propre,
                rec_avant=recouvrement(list(origine.values())),
                rec_apres=recouvrement([nets[i] for i in ids]),
                emprise_avant=unary_union(list(origine.values())).area * f,
                emprise_apres=unary_union([nets[i] for i in ids]).area * f,
                orphelines=orphelines, perte=perte * f,
                sans_face=n_propre - len(ids),
                filles=r['filles'], partages=r['partages'],
                anr=compte['anr'], repli=compte['repli'],
                orphelin=r['sans_mere'],
                deplace=sum(origine[a].symmetric_difference(final[a]).area * f
                            for a in final if a in origine) / 2,
                motifs=dict(par_mot), aires=dict(aire_mot))


def main():
    global MOSAIQUE
    argv = [a for a in sys.argv[1:] if a != '--mosaique']
    MOSAIQUE = len(argv) != len(sys.argv) - 1
    an = int(argv[0]) if argv else 1870
    deps = argv[1:] or sorted(os.listdir(BASE))
    print(f'  règle de fratrie : {"MOSAÏQUE (reste ∩ repli)" if MOSAIQUE else "historique (morceau entier)"}')
    debuts, bornes = charge_filiation()
    tot, aires, n = collections.Counter(), collections.Counter(), 0
    for dep in deps:
        r = fait_dep(dep, an, debuts, bornes, detail=len(deps) < 4)
        if not r:
            continue
        n += 1
        for k in ('n_poly', 'n_faces', 'rec_avant', 'rec_apres', 'emprise_avant',
                  'emprise_apres', 'orphelines', 'perte', 'deplace', 'filles',
                  'partages', 'anr', 'repli', 'orphelin', 'sans_face'):
            tot[k] += r[k]
        for k, v in r['motifs'].items():
            tot['m_' + k] += v
        for k, v in r['aires'].items():
            aires[k] += v
    print(f'\n=== {an} — {n} départements, {tot["n_poly"]} polygones, '
          f'{tot["n_faces"]} faces ===')
    print(f'  recouvrement   avant {tot["rec_avant"]:10.1f} km²'
          f'   après {tot["rec_apres"]:9.3f} km²')
    print(f'  emprise        avant {tot["emprise_avant"]:10.1f} km²'
          f'   après {tot["emprise_apres"]:10.1f} km²')
    print(f'  trou non comblé                    {tot["orphelines"]:9.3f} km²')
    print(f'  perte de polygonisation            {tot["perte"]:9.3f} km²')
    print(f'  atomes sans aucune face            {tot["sans_face"]:9d}')
    print(f'  sol qui change de main             {tot["deplace"]:9.1f} km²')
    print('\n  d\'où vient la géométrie de chaque atome')
    print(f'    ANR à la date                    {tot["anr"]:9d}')
    print(f'    reprise (différence du voisin)   {tot["filles"]:9d}'
          f'   ({tot["partages"]} fratries partagées)')
    print(f'    repli GEOFLA 2011 résiduel       {tot["orphelin"]:9d}')
    print('\n  arbitrage des faces')
    for m in MOTIFS:
        if tot['m_' + m]:
            print(f'    {m:16s} {tot["m_" + m]:7d} faces  {aires[m]:10.1f} km²')


if __name__ == '__main__':
    main()
