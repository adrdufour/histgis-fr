# archives/ — ce qui ne sert ni la base ni la carte web

Rien ici n'est lu par la chaîne (`sql/`) ni par l'export de la carte
(`cartes/export_web.py`). Gardé pour mémoire ou pour être rejoué à la main.

## À la racine

L'exploration d'août 2026, d'avant la chaîne : rapports sur les DBF, les
en-têtes et GEOFLA, `resoudre_absorbantes.py`, `resoudre_par_nom.py`, la
première lecture entrelacée de la composition des JO (28 août), et la saisie
des partitions de ville du 21 octobre. `symbology-style.db` est la base de
styles que QGIS dépose dans le dossier d'où on le lance (hors git).

## `planches/` — les cartes imprimables

Rangées ici le 21 octobre 2026. Elles lisent la base mais n'y écrivent rien,
et la carte web ne les appelle pas. Elles restent rejouables :

| script | produit, dans `planches/sorties/` |
|---|---|
| `cartes_cantons.py` | `dep_NN.pdf`, une planche par département et par borne (`--un-seul`, `--2025`) |
| `cartes_paris.py` | `paris_circo.pdf`, les circonscriptions de Paris 1863-1986 ; importe `vers_path` de `cartes_cantons.py` |
| `carte_villes_multicantonales.py` | `villes_multicantonales.gpkg`, `.qgz`, `.png`, `.pdf` (à lancer avec le Python de QGIS) |

`cartes/export_web.py` et `cartes/web/index.html` citent encore
`cartes_cantons.py` en commentaire : c'est de là que viennent le regroupement
par empreinte géométrique et la chaîne de repli des noms.

## `filets/` — les sauvegardes `.avant_*` et les journaux des recensements

Les copies que `apparie_noms.py`, `seine_et_oise.py`, `corrige_codes.py`,
`codes_orphelins.py` écrivent avant de toucher un CSV, et les `*.log` des
passes de 1968. Les deux recensements sont acquis : ces filets ne servent plus
qu'à défaire une passe ancienne. Un nouveau passage des scripts les réécrit à
leur place d'origine. Hors git (`*.avant_*`, `*.log`).
