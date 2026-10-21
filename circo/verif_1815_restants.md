# Gaudillère 1815-1870, seconde série — points à vérifier

Lecture des 120 photos de `photos/1815_1870/` (seconde série, 4 octobre 2026), transcrite dans `circo/regles_1815_restants.py` et chargée par `circo/remonte_1815.py`. **Toutes les partitions sont complètes** (87 départements, 14 257 lignes dans `composition_1815_1870.csv`). Les numéros de photo sont le rang alphabétique des fichiers (1 = `PXL_20261004_131505689.jpg`).

## Ce que contient la série

| Photos | Département | Statut |
|---|---|---|
| 1-2 | Côte-d'Or (21) | déjà fait, non relu |
| 3-7 | Corse (20) | transcrit |
| 8-10 | Corrèze (19) | transcrit |
| 11-12 | Cher (18) | transcrit |
| 13-15 | Charente-Maritime (17) | transcrit |
| 16-17 | Charente (16) | transcrit |
| 18-20 | Cantal (15) | transcrit |
| 21-23 | Calvados (14) | transcrit |
| 24-26 | Bouches-du-Rhône (13) | transcrit |
| 27-29 | Aude (11) | transcrit |
| 30-31 | Aube (10) | transcrit |
| 32-33 | Ariège (09) | transcrit |
| 34-37 | Ardennes (08) | transcrit |
| 38-40 | Ardèche (07) | transcrit |
| 41-44 | Alpes-Maritimes (06) | transcrit (1860-1870) |
| 45-46 | Hautes-Alpes (05) | transcrit |
| 47-48 | Alpes-de-Haute-Provence (04) | transcrit |
| 49-51 | Allier (03) | transcrit |
| 52-53 | Aisne (02) | transcrit |
| 54-56 | Ain (01) | transcrit |
| 57-58 | Pyrénées-Atlantiques (64) | transcrit |
| 59-60 | Hautes-Pyrénées (65) | transcrit |
| 61 | Pyrénées-Orientales (66) | transcrit |
| 62-64 | Bas-Rhin (67) | transcrit |
| 65-67 | Haut-Rhin (68) | transcrit |
| 68-71 | Rhône (69) | transcrit |
| 72-73 | Haute-Saône (70) | transcrit |
| 74-76 | Saône-et-Loire (71) | transcrit |
| 77-78 | Sarthe (72) | transcrit |
| 79-81 | Mont-Blanc 1815, Savoie sarde 1848-1860 | **non posé** (territoire non français) |
| 82 | Savoie (73) | transcrit (1860-1870) |
| 83-102, 106-120 | 76 à 89 sauf 83 | déjà en base (règles de `remonte_1815.py`), non relus — les cartes peuvent servir à les contrôler |
| 103-105 | Var (83) | transcrit |

## Manques

- **Aveyron (12)** : aucune photo. Rien n'est posé.
- **Mayenne 1852-1870** : toujours pas photographiée.
- **Arrondissement de Grasse 1815-1860** : varois jusqu'en 1860, mais ses cantons sont au 06 dans la base. Ni les règles du Var ni celles du 06 ne le posent avant 1860 : trou connu.
- Périodes « pas de découpage » déclarées dans `t106_college` (`sql/106`) : 04 et 05 (1820-1831, 1852-1870), 20 (1820-1831, 1852-1857), 65 (1820-1831), 66 (1820-1831, 1852-1869).

## Limites — à reprendre à l'atome

- **13 Marseille** (1831-1870) : la ville est coupée en deux ou trois morceaux non nommés ; affectation des six cantons approchée.
- **69 Lyon** (toutes périodes) : les huit cantons posés entiers dans une seule circonscription, alors que la ville est partagée (1831-1848 : 1re à 3e ; 1869 : « Lyon 2 »).
- **67 Strasbourg 1831-1848** : la ville forme les 1re ET 2e ; les quatre cantons posés en 1re.
- **72 Le Mans 1831-1870** : partage des trois cantons urbains lu au mieux.
- Cantons divisés par une note de l'atlas, posés entiers : Tulle-Sud (19, 1820-1831), La Fère (02, 1820-1831), Tarbes-Sud (65, 1834-1848), Draguignan et Fréjus (83, 1820-1831).

## Doutes de lecture

- **01 Ain** : Villars n'est dessiné sur aucune carte, rangé avec Saint-Trivier-sur-Moignans. Corrigé le 10 octobre 2026 : Villars est créé le 18 juillet 1868 sur Saint-Trivier-sur-Moignans, Chalamont, Meximieux et Châtillon-sur-Chalaronne ; ses communes suivent leur ancien canton (`cantons/changements_communes_1815_1870.csv`), ce qui fait passer Birieux, Marlieux, Saint-Germain-sur-Renon et Saint-Paul-de-Varax dans la 2e circonscription en 1820-1821. Corrigé aussi le 10 octobre 2026 : Poncin est dans la 3e en 1852-1870 (cerné d'un trait épais côté Izernore, Brénod et Pont-d'Ain), il avait été laissé dans la 2e avec l'arrondissement de Nantua.
- **07 Ardèche 1852-1870** : Le Cheylard et Saint-Pierreville, cernés au nord et au sud, rangés dans la 1re.
- **11 Aude 1852-1869** : deux morceaux marqués « 2 » (Limoux et Narbonne) séparés par la 1re ; coquille possible.
- **13 Bouches-du-Rhône 1863-1869** : Berre à la 3e, Martigues à la 2e (inverse de 1852 et 1869).
- **17 Charente-Maritime 1821-1831** : Cozes rangé dans la 4e (Jonzac).
- **20 Corse** : Ghisoni non nommé, rangé avec Vezzani.
- **68 Haut-Rhin 1863-1869** : Mulhouse-Nord/-Sud cernés sans chiffre, rangés dans la 2e.
- **69 Rhône 1863-1869** : Limonest dans la 2e ; Neuville et Villeurbanne dans la 3e (qui serait en deux morceaux).
- **71 Saône-et-Loire 1820-1831** : Mont-Saint-Vincent rangé dans la 2e.
- **72 Sarthe** : la ville du Mans, voir Limites.
- **73 Savoie** : Chamoux, contourné par une boucle du trait, rangé dans la 1re.
- **83 Var** : Le Luc et Solliès-Pont ne sont dessinés qu'à partir de 1831 ; avant, ils suivent Besse et Cuers.

## Approximations de nomenclature

Cantons créés après la carte, rangés avec leur canton d'origine : Trouville (14), Commentry (03), Amplepuis (69), Le Creusot et Montceau-les-Mines (71), Marnay (70), La Seyne-sur-Mer (83). Cantons-fraction sans circonscription en 1876, rangés avec leur voisin urbain : Bastia-Terravecchia (20), Arles-Ouest (13), Nice-Est (06).
