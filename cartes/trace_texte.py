# -*- coding: utf-8 -*-
"""
trace_texte.py — une limite décrite par une suite de voies, tracée dans la
                 voirie BD TOPO. À exécuter DANS QGIS (il lui faut `processing`).

    exec(open(".../cartes/trace_texte.py").read())
    ligne, rapport = trace("03190", ["Route de Decize", "Rue de Decize", …])
    ligne, rapport = trace_eau("03185", "le Cher", "1900-01-01")   # « séparation le Cher »

La suite — découpe d'essai, ancres, écriture, recette — est dans
`cartes/pose_coupe.py`, et le déroulé complet dans le skill
`.claude/skills/decoupe-ville/`.

Écrit sur Vienne le 24 septembre 2026, puis sorti en module pour Moulins : la
même mécanique servira aux 117 villes suivantes, et une méthode recopiée de
ville en ville diverge en silence.

LA MÉTHODE
----------
1. Chaque nom du texte est cherché dans `<insee>_voies.geojson`
   (`voie_nommee`, noms BAN), puis, à défaut, dans les tronçons
   (`nom_voie_ban_gauche/droite`) — « Route de Decize » n'existe qu'à ce
   niveau. Un nom introuvable est SIGNALÉ et sauté : la ligne passe alors par
   le plus court chemin entre ses deux voisins du texte (la place Modène à
   Vienne, la rue du Pont-Guinguet à Moulins).
2. Points de passage : pour chaque élément, le point le plus proche de
   l'élément précédent (entrée) et du suivant (sortie). Le PREMIER élément est
   pris depuis son sommet le plus éloigné du deuxième, le DERNIER jusqu'à son
   sommet le plus éloigné de l'avant-dernier : la limite suit la voie entière
   aux deux bouts, faute de texte qui dise où elle s'arrête.
3. Entre deux points : plus court chemin dans le réseau des tronçons
   (`native:shortestpathpointtopoint`). Les chemins sont CONCATÉNÉS dans
   l'ordre du texte, jamais réunis par `unaryUnion` : une union perd l'ordre
   et rend une multiligne (constaté sur Vienne).
4. Les boucles sont retirées : quand le chemin repasse à moins d'un mètre
   d'un sommet déjà visité, tout ce qui est entre les deux passages tombe. Un
   plus court chemin qui entre dans une place et en ressort fait une boucle
   (trois à Vienne, place Jouvenet, 18 à 20 m chacune).

Le rapport dit, élément par élément, l'écart au précédent et le détour du
chemin par rapport au vol d'oiseau. Un écart de plusieurs centaines de mètres
entre deux éléments consécutifs signale un nom mal identifié — c'est ainsi
que la place Saint-Pierre de Vienne (552 m hors de la chaîne) a été écartée.
"""

import unicodedata

import processing
from qgis.core import QgsGeometry, QgsPointXY, QgsVectorLayer

VOIRIE = "/home/adrien/Téléchargements/projet_carte/cartes/sorties/voirie/"


def _n(s):
    return unicodedata.normalize("NFD", str(s or "")).encode("ascii", "ignore").decode().lower().strip()


def elements(insee, noms):
    """{nom: géométrie}, et la liste des noms introuvables."""
    voies = QgsVectorLayer(VOIRIE + f"{insee}_voies.geojson", "v", "ogr")
    tron = QgsVectorLayer(VOIRIE + f"{insee}_troncons.geojson", "t", "ogr")
    cles = {_n(x): x for x in noms}
    geo = {}
    for f in voies.getFeatures():
        k = _n(f["nom_voie_ban"])
        if k in cles:
            g = QgsGeometry(f.geometry())
            geo[cles[k]] = geo[cles[k]].combine(g) if cles[k] in geo else g
    # Seconde passe, pour les seuls noms que `voie_nommee` ne connaît pas.
    manquants = {k: v for k, v in cles.items() if v not in geo}
    for f in tron.getFeatures():
        vus = {_n(f["nom_voie_ban_gauche"]), _n(f["nom_voie_ban_droite"])}
        for k in vus & manquants.keys():
            nom = manquants[k]
            g = QgsGeometry(f.geometry())
            geo[nom] = geo[nom].combine(g) if nom in geo else g
    return geo, [x for x in noms if x not in geo]


def trace(insee, noms, tolerance=5):
    geo, absents = elements(insee, noms)
    chaine = [x for x in noms if x in geo]
    rapport = [f"introuvable, sauté : {x}" for x in absents]

    prec = None
    for x in chaine:
        g = geo[x]
        ecart = "" if prec is None else f"  écart au précédent {g.distance(geo[prec]):5.0f} m"
        rapport.append(f"{x:32s} {g.length():6.0f} m{ecart}")
        prec = x

    def sommets(g):
        return [QgsPointXY(v) for v in g.vertices()]

    wp = [max(sommets(geo[chaine[0]]),
              key=lambda p: geo[chaine[1]].distance(QgsGeometry.fromPointXY(p)))]
    for i, x in enumerate(chaine):
        for j in (i - 1, i + 1):
            if 0 <= j < len(chaine):
                p = geo[x].nearestPoint(geo[chaine[j]]).asPoint()
                if wp[-1].distance(p) > 0.5:
                    wp.append(p)
    fin = max(sommets(geo[chaine[-1]]),
              key=lambda p: geo[chaine[-2]].distance(QgsGeometry.fromPointXY(p)))
    if wp[-1].distance(fin) > 0.5:
        wp.append(fin)

    pts = []
    for a, b in zip(wp, wp[1:]):
        r = processing.run("native:shortestpathpointtopoint", {
            "INPUT": VOIRIE + f"{insee}_troncons.geojson", "STRATEGY": 0,
            "TOLERANCE": tolerance,
            "START_POINT": f"{a.x()},{a.y()} [EPSG:2154]",
            "END_POINT": f"{b.x()},{b.y()} [EPSG:2154]", "OUTPUT": "memory:"})
        f = next(r["OUTPUT"].getFeatures(), None)
        if f is None or f.geometry().isEmpty():
            rapport.append(f"AUCUN CHEMIN entre ({a.x():.0f},{a.y():.0f}) et ({b.x():.0f},{b.y():.0f})")
            continue
        pl = sommets(f.geometry())
        if pl[0].distance(a) > pl[-1].distance(a):
            pl.reverse()
        for p in pl:
            if not pts or pts[-1].distance(p) > 0.01:
                pts.append(p)

    propre = []
    for p in pts:
        k = next((i for i, q in enumerate(propre) if q.distance(p) < 1.0), None)
        if k is not None:
            perte = QgsGeometry.fromPolylineXY(propre[k:] + [p]).length()
            rapport.append(f"boucle retirée : {perte:.0f} m près de ({p.x():.0f}, {p.y():.0f})")
            propre = propre[:k + 1]
        else:
            propre.append(p)
    ligne = QgsGeometry.fromPolylineXY(propre)
    rapport.append(f"LIGNE : {ligne.length():.0f} m, {len(propre)} sommets, "
                   f"simple = {ligne.isSimple()}")
    return ligne, rapport


def _intersections(g1, g2):
    """Les points où g1 et g2 se coupent, calculés MORCEAU PAR MORCEAU.

    `g1.intersection(g2)` sur deux réseaux entiers (toute la voie ferrée de
    Charleville-Mézières contre toute la Meuse) fait tomber GEOS — et avec lui
    le QGIS de l'utilisateur, le 25 septembre 2026. Reproduit ensuite dans un
    processus isolé : core dump au même appel. On ne croise donc que des
    morceaux dont les emprises se touchent, un par un.
    """
    def morceaux(g):
        return g.asGeometryCollection() if g.isMultipart() else [g]
    pts = []
    m2 = [(p, p.boundingBox()) for p in morceaux(g2)]
    for p1 in morceaux(g1):
        b1 = p1.boundingBox()
        for p2, b2 in m2:
            if not b1.intersects(b2):
                continue
            x = p1.intersection(p2)
            if not x.isEmpty():
                pts += [QgsPointXY(v) for v in x.vertices()]
    return pts


def _plus_court(reseau, a, b, tolerance=5):
    # Deux morceaux de réseau non reliés (une voie ferrée de service isolée à
    # Aix-en-Provence) : processing lève une exception. On rend None, et
    # l'appelant trace un segment droit en le disant dans le rapport.
    try:
        r = processing.run("native:shortestpathpointtopoint", {
            "INPUT": reseau, "STRATEGY": 0, "TOLERANCE": tolerance,
            "START_POINT": f"{a.x()},{a.y()} [EPSG:2154]",
            "END_POINT": f"{b.x()},{b.y()} [EPSG:2154]", "OUTPUT": "memory:"})
    except Exception:
        return None
    f = next(r["OUTPUT"].getFeatures(), None)
    if f is None or f.geometry().isEmpty():
        return None
    pl = [QgsPointXY(v) for v in f.geometry().vertices()]
    if pl[0].distance(a) > pl[-1].distance(a):
        pl.reverse()
    return pl


def trace_mixte(insee, etapes, date="1990-01-01", tolerance=5):
    """Une limite qui enchaîne rues, cours d'eau, voie ferrée et limite de
    commune — écrit sur Charleville-Mézières (décrets 73-715 et 82-23) :

        « … cours de la Meuse (de la rue Charles-Gilbert à la limite de Warcq),
          rue Voltaire …, voie ferrée (jusqu'au pont du faubourg du Theux) … »

    `etapes`, dans l'ordre du texte :
        ("voie", "Rue Voltaire")      une voie nommée (voies, puis tronçons)
        ("route", "D7N")              une route par son numéro actuel
                                      (l'ex-RN7 à Aix-en-Provence)
        ("eau", "meuse")              un cours d'eau : tout tronçon dont le
                                      toponyme CONTIENT ce mot (« la Meuse »
                                      et « la Meuse/Canal de l'Est »)
        ("fer",)                      la voie ferrée
        ("bord",)                     la limite de la commune (à la date)
        ("point", x, y)               un repère que rien d'autre ne localise
                                      (un pont, une borne kilométrique)

    Chaque élément est parcouru dans SON réseau : une rue par les tronçons de
    route, la Meuse par son axe, le chemin de fer par ses voies. Entre deux
    éléments, le point de passage est leur INTERSECTION quand ils se coupent —
    et, quand ils se coupent plusieurs fois (une voie ferrée franchit la Meuse
    à trois endroits), celle qui est la plus proche du point de passage
    précédent. S'ils ne se coupent pas, les points les plus proches, reliés
    par un segment ; entre deux voies qui ne se touchent pas (rue Thiers
    disparue), par le plus court chemin dans les rues.
    """
    import subprocess
    from qgis.core import QgsFeature
    voies_g, _ = elements(insee, [e[1] for e in etapes if e[0] == "voie"])
    eau = QgsVectorLayer(VOIRIE + f"{insee}_eau.geojson", "e", "ogr")
    fer = QgsVectorLayer(VOIRIE + f"{insee}_fer.geojson", "f", "ogr")
    routes = VOIRIE + f"{insee}_troncons.geojson"
    com = QgsGeometry.fromWkt(subprocess.run(
        ["psql", "-d", "histgis", "-At", "-c",
         f"SELECT ST_AsText(histgis.cible_ville('{insee}', DATE '{date}'))"],
        capture_output=True, text=True).stdout.strip())
    bord = QgsGeometry(com.constGet().boundary())

    def couche_de(feats, nom):
        return couche_de_geom(QgsGeometry.unaryUnion([QgsGeometry(f.geometry()) for f in feats]), nom)

    def couche_de_geom(g, nom):
        """Un réseau routable fait d'une géométrie linéaire (limites de
        commune comprises : un anneau fermé se parcourt dans les deux sens)."""
        mem = QgsVectorLayer("LineString?crs=EPSG:2154", nom, "memory"); fs = []
        for p in (g.asGeometryCollection() if g.isMultipart() else [g]):
            nf = QgsFeature(); nf.setGeometry(p); fs.append(nf)
        mem.dataProvider().addFeatures(fs)
        return mem

    rapport, elems = [], []   # (étiquette, géométrie, réseau ou None)
    for e in etapes:
        if e[0] == "voie":
            if e[1] not in voies_g:
                rapport.append(f"introuvable, sauté : {e[1]}"); continue
            elems.append((e[1], voies_g[e[1]], routes))
        elif e[0] == "route":
            # « route nationale 7 » : par son NUMÉRO (`cpx_numero`), que les
            # déclassements de 2006 ont changé — la RN7 d'Aix-en-Provence est
            # la D7N, la RN96 la D96. Une route traverse souvent toute la
            # commune : tenir compte du voisin du texte pour le bon tronçon.
            tron = QgsVectorLayer(routes, "t", "ogr")
            gs = [QgsGeometry(f.geometry()) for f in tron.getFeatures()
                  if _n(f["cpx_numero"]) == _n(e[1])]
            if not gs:
                rapport.append(f"introuvable, sauté : route {e[1]}"); continue
            elems.append((f"route:{e[1]}", QgsGeometry.unaryUnion(gs), routes))
        elif e[0] == "eau":
            fs = [f for f in eau.getFeatures() if _n(e[1]) in _n(f["cpx_toponyme_de_cours_d_eau"])]
            reseau = couche_de(fs, e[1])
            elems.append((f"eau:{e[1]}", QgsGeometry.unaryUnion([f.geometry() for f in fs]), reseau))
        elif e[0] == "fer":
            fs = list(fer.getFeatures())
            elems.append(("fer", QgsGeometry.unaryUnion([f.geometry() for f in fs]), couche_de(fs, "fer")))
        elif e[0] == "bord":
            elems.append(("bord", bord, couche_de_geom(bord, "bord")))
        elif e[0] == "commune":
            # « la limite de la commune de Warcq » : le contour de CETTE voisine,
            # pas le bord communal en général — qui, à Charleville-Mézières,
            # faisait partir la limite de l'autre bout de la ville.
            # ("commune", insee, date) : une commune DISPARUE, à une date où
            # elle existait — « les limites de l'ancienne commune de
            # Montcy-Saint-Pierre », fusionnée en 1966 : son polygone ANR
            # 1790-1966. Au milieu d'une liste, la limite est LONGÉE.
            dc = e[2] if len(e) > 2 else date
            w = subprocess.run(["psql", "-d", "histgis", "-At", "-c",
                "SELECT ST_AsText(ST_Boundary(ST_UnaryUnion(ST_Collect(coalesce(n.geom, g.geom))))) "
                "FROM histgis.atom a JOIN histgis.atom_geom g USING (atom_id) "
                "LEFT JOIN histgis.atom_geom_anr n ON n.atom_id = a.atom_id "
                f"AND n.periode @> DATE '{dc}' WHERE a.insee_geofla = '{e[1]}'"],
                capture_output=True, text=True).stdout.strip()
            gc = QgsGeometry.fromWkt(w)
            elems.append((f"commune:{e[1]}", gc, couche_de_geom(gc, e[1])))
        elif e[0] == "point":
            elems.append((f"point({e[1]:.0f},{e[2]:.0f})",
                           QgsGeometry.fromPointXY(QgsPointXY(e[1], e[2])), None))

    def passage(g1, g2, pres, frole=15):
        """Point de passage de g1 à g2, le plus proche de `pres` parmi :
        leurs intersections, et les sommets de g1 à moins de `frole` m de g2.

        Les seconds sont indispensables : une rivière qui LONGE une limite ne
        la croise pas, elle court à quelques mètres. À Charleville-Mézières, la
        Meuse longe Warcq à l'ouest et ne croise nettement le bord qu'au nord,
        près de Montcy-Notre-Dame : avec les seules intersections, la limite
        partait du nord et faisait 6,5 km de Meuse au lieu de quelques
        centaines de mètres."""
        cand = []
        for v in _intersections(g1, g2):
            cand.append((v, v))
        for v in g1.vertices():
            p = QgsPointXY(v)
            gp = QgsGeometry.fromPointXY(p)
            if g2.distance(gp) <= frole:
                cand.append((p, g2.nearestPoint(gp).asPoint()))
        if cand:
            return min(cand, key=lambda c: c[0].distance(pres)) if pres else cand[0]
        return g1.nearestPoint(g2).asPoint(), g2.nearestPoint(g1).asPoint()

    # EN PREMIER ou EN DERNIER, un bord, un repère, un cours d'eau ou une voie
    # ferrée n'est pas parcouru : c'est un point de départ ou d'arrivée, « la
    # voie ferrée (jusqu'au pont du faubourg du Theux) » s'arrête à la Meuse,
    # elle ne la suit pas. Parcourir la Meuse entière faute d'arrêt n'aurait
    # aucun sens. Pour la suivre, la mettre au milieu, entre deux éléments.
    def terminal(lab):
        return lab == "bord" or lab.startswith(("point", "eau:", "fer", "commune:"))

    # Un départ ou une arrivée sur une limite de commune tolère 60 m : l'axe
    # BD TOPO d'une rivière et le contour ANR qu'elle forme s'écartent de
    # plusieurs dizaines de mètres (Meuse contre Warcq).
    FROLE_BORD = 60

    g0 = elems[0][1]
    if terminal(elems[0][0]):
        pres = elems[2][1].centroid().asPoint() if len(elems) > 2 else None
        depart, _ = passage(elems[1][1], g0, pres,
                            FROLE_BORD if elems[0][0] in ("bord",) or elems[0][0].startswith("commune:") else 15)
        elems = elems[1:]
    else:
        depart = max((QgsPointXY(v) for v in g0.vertices()),
                     key=lambda p: elems[1][1].distance(QgsGeometry.fromPointXY(p)))
    fin_bord = terminal(elems[-1][0])
    dernier = elems[-1] if fin_bord else None
    if fin_bord:
        elems = elems[:-1]

    pts, courant = [depart], depart
    for i, (lab, g, reseau) in enumerate(elems):
        if i + 1 < len(elems):
            sortie, entree_suiv = passage(g, elems[i + 1][1], courant)
        elif dernier is not None:
            sortie, entree_suiv = passage(g, dernier[1], courant,
                                          FROLE_BORD if dernier[0] == "bord" or dernier[0].startswith("commune:") else 15)
        else:
            sortie = max((QgsPointXY(v) for v in g.vertices()),
                         key=lambda p: elems[i - 1][1].distance(QgsGeometry.fromPointXY(p)))
            entree_suiv = None
        chemin = _plus_court(reseau, courant, sortie, tolerance) if reseau and courant.distance(sortie) > 0.5 else [courant, sortie]
        if chemin is None:
            rapport.append(f"AUCUN CHEMIN dans « {lab} » : segment droit"); chemin = [courant, sortie]
        long = QgsGeometry.fromPolylineXY(chemin).length()
        rapport.append(f"{lab:36s} {long:6.0f} m")
        pts += chemin[1:]
        if entree_suiv is not None and entree_suiv.distance(sortie) > 0.5:
            suiv_voie = i + 1 < len(elems) and elems[i + 1][2] == routes and reseau == routes
            # D'une rue vers un REPÈRE d'arrivée éloigné — le point triple où la
            # limite doit toucher le bord (Troyes, axe 3 : 340 m entre la rue
            # Jeanne-d'Arc et le point Troyes / Sainte-Savine / Saint-André) :
            # par les rues aussi, pas par un trait droit à travers les îlots.
            vers_repere = (i == len(elems) - 1 and dernier is not None
                           and dernier[0].startswith("point") and reseau == routes
                           and entree_suiv.distance(sortie) > 30)
            par_rues = suiv_voie or vers_repere
            pont = _plus_court(routes, sortie, entree_suiv, tolerance) if par_rues else None
            if pont and pont[-1].distance(entree_suiv) > 0.5:
                pont.append(entree_suiv)
            pont = pont or [sortie, entree_suiv]
            rapport.append(f"   raccord {'par les rues' if par_rues else 'droit'} : "
                           f"{QgsGeometry.fromPolylineXY(pont).length():.0f} m")
            pts += pont[1:]
        courant = entree_suiv if entree_suiv is not None else sortie

    propre = []
    for p in pts:
        k = next((i for i, q in enumerate(propre) if q.distance(p) < 1.0), None)
        if k is not None:
            perte = QgsGeometry.fromPolylineXY(propre[k:] + [p]).length()
            if perte > 1:
                rapport.append(f"boucle retirée : {perte:.0f} m près de ({p.x():.0f}, {p.y():.0f})")
            propre = propre[:k + 1]
        else:
            propre.append(p)
    ligne = QgsGeometry.fromPolylineXY(propre)
    rapport.append(f"LIGNE : {ligne.length():.0f} m, simple = {ligne.isSimple()}, "
                   f"bouts au bord : {bord.distance(QgsGeometry.fromPointXY(propre[0])):.0f} m / "
                   f"{bord.distance(QgsGeometry.fromPointXY(propre[-1])):.0f} m")
    return ligne, rapport


def trace_eau(insee, toponyme, date="1900-01-01"):
    """Une limite « séparation <cours d'eau> » — écrit sur Montluçon (le Cher).

    1. Le cours d'eau est pris dans `<insee>_eau.geojson` par
       `cpx_toponyme_de_cours_d_eau` (« le Cher »). Pour une grande rivière la
       BD TOPO donne un axe FICTIF au milieu de la surface en eau : c'est lui
       qu'on veut.
    2. Les îles cassent l'axe en morceaux (dix pour le Cher) : on prend le plus
       court chemin entre les deux bouts extrêmes du réseau, donc le bras le
       plus court autour de chaque île.
    3. On ne garde que la TRAVERSÉE : la frontière entre les deux plus grands
       morceaux que le cours d'eau découpe dans la commune. Là où la rivière
       EST la limite communale (le nord de Montluçon), elle sépare la commune
       de sa voisine, pas deux cantons ; la garder laisserait des miettes
       entre l'axe BD TOPO et le contour ANR, attribuées à personne.

    Rend (traversée, rapport). Le rapport liste les morceaux : s'il y en a plus
    de deux d'importance, la rivière n'est qu'UNE des limites de la ville et
    « les deux plus grands » n'est peut-être pas la bonne paire — à regarder.
    """
    import subprocess
    from qgis.core import QgsFeature
    eau = QgsVectorLayer(VOIRIE + f"{insee}_eau.geojson", "e", "ogr")
    mem = QgsVectorLayer("LineString?crs=EPSG:2154", "cours", "memory")
    fs = []
    for f in eau.getFeatures():
        if _n(f["cpx_toponyme_de_cours_d_eau"]) == _n(toponyme):
            g = QgsGeometry(f.geometry())
            for p in (g.asGeometryCollection() if g.isMultipart() else [g]):
                nf = QgsFeature(); nf.setGeometry(p); fs.append(nf)
    if not fs:
        noms = sorted({str(f["cpx_toponyme_de_cours_d_eau"]) for f in eau.getFeatures()
                       if f["cpx_toponyme_de_cours_d_eau"]})
        raise ValueError(f"« {toponyme} » absent. Cours d'eau présents : {noms}")
    mem.dataProvider().addFeatures(fs)
    rapport = [f"{toponyme} : {len(fs)} tronçons, "
               f"{sum(f.geometry().length() for f in fs):.0f} m"]

    from collections import Counter
    deg = Counter()
    for f in mem.getFeatures():
        l = f.geometry().asPolyline()
        for p in (l[0], l[-1]):
            deg[(round(p.x(), 2), round(p.y(), 2))] += 1
    bouts = [QgsPointXY(x, y) for (x, y), d in deg.items() if d == 1]
    # les deux bouts les plus éloignés l'un de l'autre
    a, b = max(((p, q) for i, p in enumerate(bouts) for q in bouts[i + 1:]),
               key=lambda pq: pq[0].distance(pq[1]))
    r = processing.run("native:shortestpathpointtopoint", {
        "INPUT": mem, "STRATEGY": 0, "TOLERANCE": 1,
        "START_POINT": f"{a.x()},{a.y()} [EPSG:2154]",
        "END_POINT": f"{b.x()},{b.y()} [EPSG:2154]", "OUTPUT": "memory:"})
    chemin = next(r["OUTPUT"].getFeatures()).geometry()
    rapport.append(f"chemin de bout en bout : {chemin.length():.0f} m ({len(bouts)} bouts au réseau)")

    wkt = subprocess.run(["psql", "-d", "histgis", "-At", "-c",
                          f"SELECT ST_AsText(histgis.cible_ville('{insee}', DATE '{date}'))"],
                         capture_output=True, text=True).stdout.strip()
    com = QgsGeometry.fromWkt(wkt)
    bord = QgsGeometry(com.constGet().boundary())
    poly = QgsGeometry.polygonize([bord.combine(chemin)])
    morceaux = sorted((g for g in poly.asGeometryCollection() if com.contains(g.pointOnSurface())),
                      key=lambda g: -g.area())
    rapport.append("morceaux (ha) : " + ", ".join(f"{g.area() / 1e4:.1f}" for g in morceaux))
    if len(morceaux) < 2:
        rapport.append("LE COURS D'EAU NE TRAVERSE PAS LA COMMUNE à cette date")
        return None, rapport
    p1, p2 = morceaux[0], morceaux[1]
    traversee = QgsGeometry(p1.constGet().boundary()).intersection(
        QgsGeometry(p2.constGet().boundary())).mergeLines()
    rapport.append(f"TRAVERSÉE : {traversee.length():.0f} m, multipart = {traversee.isMultipart()}")
    return traversee, rapport
