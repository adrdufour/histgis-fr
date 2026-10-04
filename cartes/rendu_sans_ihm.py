# -*- coding: utf-8 -*-
"""
rendu_sans_ihm.py — une image PNG de la carte, sans le QGIS de l'utilisateur

À exécuter par `cartes/qgis_sans_ihm.py`, qui fournit QGIS initialisé :

    rendu(couches, "sortie.png", emprise=None, largeur=1600)

`couches` : liste de (QgsVectorLayer, style) dessinée dans l'ordre (la
première en dessous). `style` est un dict : couleur, epaisseur, remplissage
(couleur ou None), opacite, etiquette (nom de champ), tirets (bool).

Écrit le 25 septembre 2026 : le QGIS ouvert était tombé, et il fallait
continuer à VOIR les limites qu'on trace — une limite qu'on ne regarde pas est
une limite qu'on ne vérifie pas.
"""

from qgis.core import (QgsFillSymbol, QgsLineSymbol, QgsMapRendererParallelJob,
                       QgsMapSettings, QgsPalLayerSettings, QgsRectangle,
                       QgsTextBufferSettings, QgsTextFormat,
                       QgsVectorLayerSimpleLabeling, QgsCoordinateReferenceSystem)
from qgis.PyQt.QtCore import QSize
from qgis.PyQt.QtGui import QColor, QFont


def _style(lyr, s):
    geom = lyr.geometryType()  # 1 ligne, 2 polygone
    if geom == 2:
        remp = s.get("remplissage")
        sym = QgsFillSymbol.createSimple({
            "color": remp or "0,0,0,0",
            "style": "solid" if remp else "no",
            "outline_color": s.get("couleur", "#333333"),
            "outline_width": str(s.get("epaisseur", 0.4)),
            "outline_style": "dash" if s.get("tirets") else "solid"})
    else:
        sym = QgsLineSymbol.createSimple({
            "line_color": s.get("couleur", "#333333"),
            "line_width": str(s.get("epaisseur", 0.4)),
            "line_style": "dash" if s.get("tirets") else "solid"})
    sym.setOpacity(s.get("opacite", 1.0))
    lyr.renderer().setSymbol(sym)
    if s.get("etiquette"):
        p = QgsPalLayerSettings(); p.fieldName = s["etiquette"]; p.enabled = True
        if geom == 1:
            p.placement = QgsPalLayerSettings.Line
        fmt = QgsTextFormat(); fmt.setFont(QFont("DejaVu Sans")); fmt.setSize(s.get("taille", 9))
        fmt.setColor(QColor(s.get("couleur_texte", s.get("couleur", "#222222"))))
        b = QgsTextBufferSettings(); b.setEnabled(True); b.setSize(1); b.setColor(QColor("white"))
        fmt.setBuffer(b); p.setFormat(fmt)
        lyr.setLabeling(QgsVectorLayerSimpleLabeling(p)); lyr.setLabelsEnabled(True)


def rendu(couches, chemin, emprise=None, largeur=1600):
    for lyr, s in couches:
        _style(lyr, s)
    lyrs = [l for l, _ in couches]
    if emprise is None:
        emprise = QgsRectangle(lyrs[0].extent())
        for l in lyrs[1:]:
            emprise.combineExtentWith(l.extent())
        emprise.grow(max(emprise.width(), emprise.height()) * 0.03)
    ms = QgsMapSettings()
    ms.setLayers(list(reversed(lyrs)))          # QgsMapSettings : la première est au-dessus
    ms.setDestinationCrs(QgsCoordinateReferenceSystem("EPSG:2154"))
    ms.setExtent(emprise)
    hauteur = int(largeur * emprise.height() / emprise.width())
    ms.setOutputSize(QSize(largeur, hauteur))
    ms.setBackgroundColor(QColor("white"))
    job = QgsMapRendererParallelJob(ms)
    job.start(); job.waitForFinished()
    job.renderedImage().save(chemin, "png")
    return chemin
