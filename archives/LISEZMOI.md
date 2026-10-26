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

## `essais/` — les bancs d'essai de l'OCR des recensements

Rangés ici le 26 octobre 2026. Lecture seule, chacun a répondu à sa question
et la réponse est dans `JOURNAL.md` et dans les docstrings d'`extrait_1954.py`,
`extrait_1968.py` et `fusionne_passes.py` : `essai_ocr.py`,
`essai_grammaire.py`, `essai_troisieme.py`, `lignes_rejetees.py` (1968),
`essai_troisieme_1954.py`, `essai_ligne_souple.py` (1954). Ils restent
rejouables depuis la racine : leurs chemins pointent vers `cog1954/` et
`cog1968/`. `essai_troisieme_1954.py` demande le Python de `histgis`
(openpyxl, par `circo/extrait_paris.py`).

## `passes_1968/` — les trois lectures OCR du recensement de 1968

`communes_1968.psm6_corrige.csv`, `.psm4_corrige.csv`, `.600.csv`, et la
lecture `psm6_brut` d'avant correction des codes. Seule leur fusion,
`cog1968/communes_1968_fusion.csv`, est chargée (`sql/58`) ;
`cog1968/fusionne_passes.py` les lit ici pour la refaire.

## `mouvements_cantonaux.saisie_manuelle.csv`

La saisie à la main du registre, remplacée par `cantons/consolide_registre.py`
(voir `cantons/note_registre.md`). Gardée comme témoin.

## `remplaces/` — des contrôles qu'un successeur a rendus inutiles

* `controle_1958.py` : la partition de la transcription de 1958, sans les
  ALIAS. `circo/composition_1958.py` fait le même contrôle avec eux et l'écrit
  dans `composition_1958_etat.csv`.
* `controle_nom_code.py` et sa sortie `communes_1968_suspects.csv` : le nom
  confirme-t-il le code, sur la première passe de 1968 (`communes_1968.csv`,
  qui n'existe plus). `cog1968/controle_nom_code_base.py` le refait sur ce que
  la base a chargé.
