#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
carte_villes_multicantonales.py — les communes qui attendent une coupe

    /usr/bin/python3 archives/planches/carte_villes_multicantonales.py

Produit dans `cartes/` :
    villes_multicantonales.gpkg  deux couches : `villes` et `fond_communes`
    villes_multicantonales.qgz   projet QGIS pointant sur ce gpkg
    villes_multicantonales.png   tirage A3, 200 dpi
    villes_multicantonales.pdf   le meme, vectoriel

Ce que la carte montre — et ce qu'elle ne montre pas
----------------------------------------------------
Elle ne montre PAS ou passent les coupes internes : ces lignes n'existent
dans aucune donnee du projet, c'est precisement le chantier. Elle montre
quelles communes en attendent, et combien. Voir `BASE_POUR_QGIS.md` §0.

Interpreteur
------------
PyQGIS n'est que dans les dist-packages systeme : `/usr/bin/python3`, pas
le python de miniforge. Le module `qgis` est introuvable depuis conda.

Le filtre qui manque dans BASE_POUR_QGIS.md §3
----------------------------------------------
La requete publiee dans la note rend 315 communes et 750 coupes, pas les
119 et 214 annonces deux lignes plus bas. Il lui manque l'exclusion de
`atom_geom.source = 'fraction_cog'` — que le paragraphe « A ne pas
confondre » de la meme section decrit pourtant comme un autre chantier,
une autre periode. Avec l'exclusion : 119 communes, 333 atomes-fraction,
214 coupes, et la distribution annoncee (81 / 16 / 13, Lyon 12,
Marseille 11). Sans elle on ramasse les 274 communes partagees d'apres
1943, dont 78 sont deja dans les 119.

Pourquoi un GeoPackage et pas des couches PostGIS vivantes
----------------------------------------------------------
Le fournisseur postgres de QGIS 3.22 part en core dump sur cette requete
passee en sous-requete d'URI ; la meme requete rend ses 119 lignes en
30 ms sous psql. On materialise donc dans un gpkg. Effet de bord utile :
le projet s'ouvre sans PostgreSQL, ce que `BASE_POUR_QGIS.md` §6 pose
comme exigence de repli.
"""

import os
import subprocess
import sys

from qgis.core import (
    QgsApplication, QgsProject, QgsVectorLayer,
    QgsGraduatedSymbolRenderer, QgsRendererRange, QgsFillSymbol,
    QgsPalLayerSettings, QgsTextFormat, QgsTextBufferSettings,
    QgsVectorLayerSimpleLabeling, QgsPrintLayout, QgsLayoutItemMap,
    QgsLayoutItemLegend, QgsLayoutItemLabel, QgsLayoutPoint, QgsLayoutSize,
    QgsUnitTypes, QgsLayoutExporter, QgsCoordinateReferenceSystem,
)
from qgis.PyQt.QtGui import QColor, QFont

ICI = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sorties")
os.makedirs(ICI, exist_ok=True)   # les sorties binaires sont isolées
GPKG = os.path.join(ICI, "villes_multicantonales.gpkg")
PG = "dbname=histgis"

# A3 portrait, comme les planches de cartes_cantons.py.
PAGE = (297, 420)
LARGEUR = 273

# Convention etablie du projet : le rouge signale la commune revendiquee par
# plusieurs cantons (cartes_cantons.py la hachure en #c00000). On reste dans
# la meme famille pour que les deux jeux de planches se lisent ensemble.
CLASSES = [
    (0.5, 1.5, "1 coupe", "#f7c9b0"),
    (1.5, 3.5, "2 a 3 coupes", "#e8794a"),
    (3.5, 99.5, "4 coupes et plus", "#a01010"),
]

MENTION = ("Les limites internes de ces communes n'existent pas dans les "
           "donnees : elles restent a tracer. La carte dit combien de coupes "
           "chaque commune attend, jamais ou elles passent.")

# Lyon et Marseille sont absentes de geofla_commune et de noms_geofla : GEOFLA
# 2011 les livre en arrondissements (69381-69389, 13201-13216). Leur geometrie
# vient d'atom_geom (source union_prefixe), seul le libelle manque.
SQL_VILLES = """
SELECT a.insee_geofla                        AS insee,
       coalesce(n.nom,
                CASE a.insee_geofla WHEN '69123' THEN 'LYON'
                                    WHEN '13055' THEN 'MARSEILLE' END,
                a.insee_geofla)              AS commune,
       count(*)                              AS fractions,
       count(*) - 1                          AS coupes,
       ST_Union(g.geom)                      AS geom
FROM   histgis.atom a
JOIN   histgis.atom_geom g USING (atom_id)
LEFT   JOIN histgis.noms_geofla n ON n.insee = a.insee_geofla
WHERE  a.insee_geofla IS NOT NULL
  AND  a.fraction
  AND  a.atom_id LIKE '%#%'
  AND  g.source <> 'fraction_cog'
GROUP  BY 1, 2
HAVING count(*) > 1
"""

SQL_FOND = "SELECT insee_com, nom_comm, geom FROM histgis.geofla_commune"

# La trame communale seule vire au gris uniforme a l'echelle de la France :
# 36 610 contours sur 27 cm. Les departements, dissous depuis la meme couche,
# redonnent la structure sans ajouter de source.
SQL_DEP = ("SELECT code_dept, ST_Union(geom) AS geom "
           "FROM histgis.geofla_commune GROUP BY code_dept")


def materialise():
    """Fige les trois couches dans un gpkg. Aucune ecriture dans la base."""
    if os.path.exists(GPKG):
        os.remove(GPKG)
    for i, (nom, sql) in enumerate([("villes", SQL_VILLES),
                                    ("fond_communes", SQL_FOND),
                                    ("fond_departements", SQL_DEP)]):
        cmd = ["ogr2ogr", "-f", "GPKG", GPKG, "PG:" + PG, "-sql", sql,
               "-nln", nom, "-nlt", "MULTIPOLYGON", "-a_srs", "EPSG:2154"]
        if i:
            cmd.insert(3, "-update")
        subprocess.run(cmd, check=True, capture_output=True)


def couche(nom, titre):
    c = QgsVectorLayer(GPKG + "|layername=" + nom, titre, "ogr")
    if not c.isValid():
        sys.exit("couche invalide : " + nom)
    return c


def style_fond(c, couleur, epaisseur):
    c.renderer().setSymbol(QgsFillSymbol.createSimple({
        "color": "255,255,255,0",
        "outline_color": couleur,
        "outline_width": epaisseur,
    }))


def style_villes(c):
    plages = []
    for bas, haut, libelle, coul in CLASSES:
        s = QgsFillSymbol.createSimple({
            "color": coul,
            "outline_color": "60,60,60,255",
            "outline_width": "0.16",
        })
        plages.append(QgsRendererRange(bas, haut, s, libelle))
    r = QgsGraduatedSymbolRenderer("coupes", plages)
    c.setRenderer(r)

    # 81 des 119 communes n'attendent qu'une coupe. Les etiqueter toutes sur
    # une France A3 sature la carte et le moteur en supprime en silence — une
    # carte ne dit pas qu'elle a renonce a un libelle. On n'etiquette donc que
    # les 38 communes a deux coupes ou plus, et le pied de page le dit.
    p = QgsPalLayerSettings()
    p.fieldName = "\"commune\" || ' (' || \"coupes\" || ')'"
    p.isExpression = True
    p.placement = QgsPalLayerSettings.OverPoint
    p.priority = 10
    fmt = QgsTextFormat()
    fmt.setFont(QFont("DejaVu Sans", 7))
    fmt.setSize(7)
    fmt.setColor(QColor("#1a1a1a"))
    tampon = QgsTextBufferSettings()
    tampon.setEnabled(True)
    tampon.setSize(0.9)
    tampon.setColor(QColor(255, 255, 255, 230))
    fmt.setBuffer(tampon)
    p.setFormat(fmt)
    c.setLabeling(QgsVectorLayerSimpleLabeling(p))
    c.setLabelsEnabled(True)
    c.setSubsetString("")


def colonnes_liste(villes, par_colonne=20):
    """Les communes etiquetees, rangees en colonnes pour le pied de planche."""
    lignes = sorted(((f["coupes"], f["commune"]) for f in villes.getFeatures()
                     if f["coupes"] >= 2), key=lambda t: (-t[0], t[1]))
    txt = [f"{nom.title()} — {c}" for c, nom in lignes]
    n = (len(txt) + 2) // 3
    n = max(n, 1)
    return ["\n".join(txt[i:i + n]) for i in range(0, len(txt), n)]


def planche(projet, couches, fond, villes, n_villes, n_coupes, n_etiq,
            colonnes):
    mise = QgsPrintLayout(projet)
    mise.initializeDefaults()
    mise.setName("Villes multicantonales")
    mise.pageCollection().page(0).setPageSize(
        QgsLayoutSize(PAGE[0], PAGE[1], QgsUnitTypes.LayoutMillimeters))

    def label(txte, x, y, taille, gras=False, ital=False,
              coul="#1a1a1a", boite=None):
        it = QgsLayoutItemLabel(mise)
        it.setText(txte)
        f = QFont("DejaVu Sans")
        f.setPointSizeF(taille)
        f.setBold(gras)
        f.setItalic(ital)
        it.setFont(f)
        it.setFontColor(QColor(coul))
        mise.addLayoutItem(it)
        if boite:
            it.attemptResize(QgsLayoutSize(boite[0], boite[1],
                                           QgsUnitTypes.LayoutMillimeters))
        else:
            it.adjustSizeToText()
        it.attemptMove(QgsLayoutPoint(x, y, QgsUnitTypes.LayoutMillimeters))
        return it

    label("Les communes reparties entre plusieurs cantons", 12, 9, 20, gras=True)
    label(f"{n_villes} communes, {n_coupes} coupes a tracer — base histgis, "
          "atomes-fraction anterieurs a 1943", 12, 21, 11, ital=True,
          coul="#444444")

    carte = QgsLayoutItemMap(mise)
    carte.setCrs(QgsCoordinateReferenceSystem("EPSG:2154"))
    carte.setLayers(couches)
    carte.setBackgroundColor(QColor("#ffffff"))
    carte.setFrameEnabled(True)
    carte.setFrameStrokeColor(QColor("#aaaaaa"))
    mise.addLayoutItem(carte)
    carte.attemptMove(QgsLayoutPoint(12, 31, QgsUnitTypes.LayoutMillimeters))
    # zoomToExtent() laisse l'emprise vide tant que la carte n'en a pas une
    # (scale = nan, cadre blanc, aucune erreur levee). setExtent() prend, mais
    # redimensionne l'objet au ratio de l'emprise : la hauteur ci-dessous est
    # donc subie, pas choisie — d'ou le calcul de la suite de la planche.
    et = fond.extent()
    et.grow(20000)
    carte.attemptResize(QgsLayoutSize(LARGEUR, 300, QgsUnitTypes.LayoutMillimeters))
    carte.setExtent(et)
    bas = 31 + carte.sizeWithUnits().height()

    leg = QgsLayoutItemLegend(mise)
    leg.setTitle("Coupes en attente")
    leg.setLinkedMap(carte)
    leg.setAutoUpdateModel(False)
    racine = leg.model().rootGroup()
    for n in list(racine.children()):
        if n.name() != villes.name():
            racine.removeChildNode(n)
    leg.setBackgroundEnabled(True)
    leg.setBackgroundColor(QColor(255, 255, 255, 225))
    leg.setFrameEnabled(True)
    leg.setFrameStrokeColor(QColor("#aaaaaa"))
    mise.addLayoutItem(leg)
    # Coin bas-gauche du cadre : l'Atlantique y est vide sur toute la planche.
    leg.attemptMove(QgsLayoutPoint(18, bas - 40, QgsUnitTypes.LayoutMillimeters))

    label(MENTION, 12, bas + 7, 10, ital=True, coul="#8b0000", boite=(273, 12))

    label(f"Les {n_etiq} communes nommees sur la carte", 12, bas + 24, 10,
          gras=True)
    for i, col in enumerate(colonnes):
        label(col, 12 + i * 69, bas + 31, 7.5, boite=(68, 60))

    label(f"Etiquettes : seules les {n_etiq} communes a 2 coupes ou plus sont "
          "nommees ; les 81 a une seule coupe sont coloriees sans libelle. "
          "Dans les grappes serrees (Nord, Nancy) le moteur d'etiquetage en "
          "supprime : la liste ci-dessus les porte toutes.\n"
          "Lyon (69123) et Marseille (13055) sont absentes de GEOFLA 2011, "
          "livrees en arrondissements : geometrie reconstituee "
          "(atom_geom.source = union_prefixe).\n"
          "Source : histgis — atom, atom_geom, noms_geofla, geofla_commune. "
          "Lambert 93. Genere par archives/planches/carte_villes_multicantonales.py",
          12, 400, 8, coul="#555555", boite=(273, 16))

    projet.layoutManager().addLayout(mise)
    return mise


def main():
    QgsApplication.setPrefixPath("/usr", True)
    app = QgsApplication([], False)
    app.initQgis()

    materialise()

    projet = QgsProject.instance()
    projet.setCrs(QgsCoordinateReferenceSystem("EPSG:2154"))

    fond = couche("fond_communes", "Communes (GEOFLA 2011)")
    deps = couche("fond_departements", "Departements")
    villes = couche("villes", "Villes multicantonales")
    style_fond(fond, "215,215,215,255", "0.04")
    style_fond(deps, "130,130,130,255", "0.18")
    style_villes(villes)
    for c in (fond, deps, villes):
        projet.addMapLayer(c)

    coupes = [f["coupes"] for f in villes.getFeatures()]
    n_villes, n_coupes = len(coupes), sum(coupes)
    n_etiq = sum(1 for c in coupes if c >= 2)
    print(f"villes={n_villes} coupes={n_coupes} etiquetees={n_etiq}")

    # L'etiquetage se limite aux communes a 2 coupes ou plus.
    villes.labeling().settings().fieldName = villes.labeling().settings().fieldName
    p = villes.labeling().settings()
    p.dataDefinedProperties()
    from qgis.core import QgsProperty, QgsPalLayerSettings as PLS
    p.dataDefinedProperties().setProperty(
        PLS.Show, QgsProperty.fromExpression('"coupes" >= 2'))
    villes.setLabeling(QgsVectorLayerSimpleLabeling(p))

    mise = planche(projet, [villes, deps, fond], fond, villes,
                   n_villes, n_coupes, n_etiq, colonnes_liste(villes))

    qgz = os.path.join(ICI, "villes_multicantonales.qgz")
    projet.write(qgz)

    exp = QgsLayoutExporter(mise)
    ip = QgsLayoutExporter.ImageExportSettings()
    ip.dpi = 200
    png = os.path.join(ICI, "villes_multicantonales.png")
    r1 = exp.exportToImage(png, ip)
    pp = QgsLayoutExporter.PdfExportSettings()
    pp.dpi = 200
    pdf = os.path.join(ICI, "villes_multicantonales.pdf")
    r2 = exp.exportToPdf(pdf, pp)
    if r1 or r2:
        sys.exit(f"export en echec (png={r1}, pdf={r2})")
    print("ecrit :", GPKG, qgz, png, pdf, sep="\n  ")

    app.exitQgis()


if __name__ == "__main__":
    main()
