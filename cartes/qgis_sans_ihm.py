#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
qgis_sans_ihm.py — faire tourner trace_texte.py HORS du QGIS de l'utilisateur

    /usr/bin/python3 cartes/qgis_sans_ihm.py mon_trace.py

`mon_trace.py` est exécuté après l'initialisation de QGIS et de `processing`,
avec `trace()`, `trace_mixte()`, `trace_eau()` déjà chargés — le même
environnement qu'un `exec(open("cartes/trace_texte.py").read())` dans la
console de QGIS.

Pourquoi
--------
Le 25 septembre 2026, sur Charleville-Mézières, une intersection de tout le
réseau ferré avec toute la Meuse, lancée dans le QGIS ouvert d'Adrien par
`execute_code`, l'a fait tomber : processus disparu, socket fermée, couches
non enregistrées perdues. Les calculs de tracé n'ont besoin ni de carte ni
de couches affichées. Ils tournent donc ici, dans un processus à eux : s'il
plante, il plante seul. Le QGIS de l'utilisateur ne sert plus qu'à MONTRER.

Interpréteur : /usr/bin/python3 (PyQGIS n'est que dans les dist-packages
système).
"""

import sys
from pathlib import Path

from qgis.core import QgsApplication

QgsApplication.setPrefixPath("/usr", True)
_app = QgsApplication([], False)
_app.initQgis()

sys.path.append("/usr/share/qgis/python/plugins")
import processing  # noqa: E402
from processing.core.Processing import Processing  # noqa: E402
from qgis.analysis import QgsNativeAlgorithms  # noqa: E402

Processing.initialize()
QgsApplication.processingRegistry().addProvider(QgsNativeAlgorithms())

ICI = Path(__file__).resolve().parent
espace = {"__name__": "__trace__"}
exec(open(ICI / "trace_texte.py").read(), espace)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    exec(open(sys.argv[1]).read(), espace)
    _app.exitQgis()
