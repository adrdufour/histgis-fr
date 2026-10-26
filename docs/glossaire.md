# Glossaire

Le projet mobilise deux vocabulaires : celui de l'administration française,
que les lecteurs étrangers ne connaissent pas forcément, et celui que le
chantier s'est forgé au fil du travail, qui revient partout dans les notes.
Les deux sont réunis ici.

---

## 1. Le découpage administratif et électoral français

**Commune.** Le plus petit échelon administratif, environ 36 000 à 38 000
selon les époques. Les communes fusionnent, se scindent et changent de nom.
La vague de fusions la plus importante suit la loi Marcellin de 1971.

**Canton.** Un regroupement de communes, d'environ 2 900 à 4 000 cantons selon
les époques. Jusqu'en 2015, c'est la circonscription d'élection du conseiller
général (l'assemblée du département). Une grande ville peut être partagée entre
plusieurs cantons : la limite passe alors **à l'intérieur** de la commune, le
long de rues ou d'une rivière.

**Circonscription législative** (abrégée **circo** dans le projet). Le
territoire qui élit un député. Selon les époques, le scrutin est
**uninominal** (un député par circonscription, découpée dans le département)
ou **de liste** (la circonscription est le département entier). La table
`regime_electoral` donne le régime en vigueur pour chaque année.

**Département.** L'échelon au-dessus du canton. Son code (`01`, `13`, `2A`…)
préfixe les identifiants. Les départements ont eux aussi changé : la Seine et
la Seine-et-Oise sont démembrées en 1964-1968, la Corse est scindée en `2A`
et `2B` en 1976, la Moselle et l'Alsace sont annexées de 1871 à 1918.

**Arrondissement municipal.** Une subdivision de Paris, Lyon et Marseille. Les
référentiels modernes codent ces trois villes **par arrondissement**, pas par
commune. Une requête sur le code de commune de Marseille (`13055`) peut donc
renvoyer zéro résultat, sans que rien ne signale l'erreur.

**Décret.** L'acte qui crée, supprime ou redécoupe un canton. Il est publié au
**Journal officiel** (JO ou JORF) et consultable sur **Légifrance**. Le projet
date les mouvements cantonaux au décret chaque fois qu'il le peut.

**Code INSEE / COG.** Le Code officiel géographique de l'INSEE attribue un
code à 5 caractères à chaque commune (`01001`), et un code à chaque canton et
département. Le COG est republié chaque année ; le projet en lit les
millésimes 1999 à 2012.

**Code Cassini.** L'identifiant de commune utilisé par la base *Des villages de
Cassini aux communes d'aujourd'hui* (EHESS) et repris par TRF-GIS. Il désigne
une commune **d'époque**, alors que le code INSEE désigne une commune
actuelle. La correspondance entre les deux n'est pas bijective : plusieurs
communes historiques peuvent partager un même code actuel.

**IRIS.** Le découpage infra-communal de l'INSEE (environ 2 000 habitants par
IRIS). Le projet s'en sert comme fond d'accrochage pour découper les villes
et pour reconstituer les quartiers de Paris.

**Lambert-93 (EPSG:2154).** La projection officielle de la France
métropolitaine. Toute la base l'emploie.

---

## 2. Les sources, par leur nom court

| nom | ce que c'est |
|---|---|
| **TRF-GIS** | le jeu de données de Victor Gay : nomenclatures annuelles 1870-1940 (commune → canton → circonscription) et shapefiles des cantons de 1870 et 1940. Diffusé sur Harvard Dataverse. |
| **Gay** | dans les notes, désigne TRF-GIS ou son auteur. Le « contrôle Gay » compare la base aux cantons qu'il a lui-même dessinés. |
| **GEOFLA** | la trame communale de l'IGN : édition 2011 pour les communes, 2014 pour les cantons. |
| **ANR**, **ANR-COMMUNES** | une trame communale historique **datée**, de 1790 à 2020 (Zenodo). Une commune y a plusieurs polygones successifs. |
| **HAC** | *Des villages de Cassini aux communes d'aujourd'hui* (EHESS) : filiation des communes depuis 1801. |
| **Gaudillère** | Bernard Gaudillère, *Atlas historique des circonscriptions électorales françaises* (1995). Ses **annexes VI** (villes divisées, particularités des circonscriptions) et **VII** (mouvements cantonaux) sont dépouillées dans `circo/` et `cantons/`. |
| **BnSP** | la bibliothèque numérique de la statistique publique, où se trouvent les fascicules des recensements de 1954 et 1968. |
| **mouvements INSEE** | `v_mvt_commune_2025.csv` : toutes les fusions, scissions et renommages de communes depuis 1943. |

---

## 3. Le vocabulaire du modèle

**Atome.** La plus petite unité géographique dont le rattachement est stable.
C'est presque toujours une commune d'époque (`atom_id` = code Cassini), parfois
une **fraction** de commune. Un atome porte un polygone ; il n'appartient à rien
par lui-même.

**Fraction.** Un atome qui représente un morceau de commune, quand celle-ci est
partagée entre plusieurs cantons. Son identifiant prend la forme
`cassini#canton`. Tant que la ville n'est pas découpée, toutes ses fractions
portent le polygone de la commune entière.

**Unité.** Un canton ou une circonscription. Son identité est pérenne : un
canton garde son `unit_id` de 1870 à 2012, et ses noms successifs sont datés
dans `unit_version`.

**Pseudo-canton.** Une unité qui regroupe plusieurs cantons réels qu'une trame
communale ne sait pas séparer, parce qu'ils se partagent une même ville. Ce
n'est pas un expédient propre au projet : TRF-GIS et l'IGN (code canton `99`)
emploient la même convention, pour la même raison.

**Rattachement**, **membership.** Le fait qu'un atome appartienne à une unité
sur un intervalle `[valid_from, valid_to)`, borne de fin exclue. C'est le cœur
de la base.

**Niveau.** `canton` ou `circo`. Un atome a un rattachement par niveau.

**Snapshot**, **instantané.** La carte reconstituée à une date donnée, en
réunissant les atomes de chaque unité.

**Trame.** Le fond de polygones communaux. Il y en a deux : `atom_geom`
(GEOFLA 2011, une forme par atome) et `atom_geom_anr` (ANR, des formes datées).

**Repli.** Quand ANR ne fournit pas de polygone pour un atome à une date, on
retombe sur la forme GEOFLA de 2011. Les fonctions comptent ces cas
(`n_repli`) pour que la carte puisse le signaler.

**Reprise.** La règle de `sql/84_carte_partition.sql` qui donne une forme
d'époque à un atome qu'ANR ne dessine pas encore à la date demandée : on
découpe son territoire dans celui de son voisin, par différence entre deux
polygones datés. C'est elle qui produit une carte sans trou ni superposition.

**Partition.** La carte obtenue après reprise, où chaque parcelle du sol
appartient à un seul atome (`carte_partition`).

**Coupe**, **découper une ville.** Tracer la ligne (des rues, une rivière) qui
sépare les fractions d'une ville multicantonale, puis l'inscrire dans
`cartes/coupes_ville.csv` et la jouer par `sql/98_coupe_ville.sql`.
**Ancre** : un point qui dit de quel côté de la ligne se trouve chaque fraction.

---

## 4. Le vocabulaire du chantier 1941-1998

TRF-GIS s'arrête en 1940 et le COG moderne commence en 1999. L'intervalle a
été reconstitué à partir de points de repère et d'actes.

**Trou**, **intervalle noir.** Une période où la base n'a aucune source pour
dire à quel canton appartient une commune.

**Jalon.** Un état complet et daté de la composition cantonale, tiré d'une
source : recensement de 1954 (`66`-`69`), recensement de 1968 (`58`-`59`),
COG de 1999.

**Salve.** Une vague de décrets de redécoupage signés ensemble, généralement
quelques semaines avant des élections cantonales (1973, 1982…).

**Report.** Prolonger un rattachement attesté vers l'avant ou vers l'arrière,
jusqu'au premier acte connu qui pourrait l'avoir modifié. **Report par les
deux bouts** : quand les deux jalons qui encadrent un intervalle sont
d'accord sur le rattachement d'une commune, on considère qu'il n'a pas changé
entre les deux. Les désaccords restent ouverts.

**Registre des actes.** La liste consolidée des décrets cantonaux, moissonnés
sur Légifrance et dans les Journaux officiels (`cantons/`).

---

## 5. Le vocabulaire de travail

**Chaîne.** La suite ordonnée des fichiers `sql/NN_*.sql` qui construit la base
depuis zéro. Les numéros indiquent l'ordre de création, pas toujours l'ordre
d'exécution : c'est `sql/rejouer_apres_rebuild.sh` qui fait foi.

**Recette.** Une requête de contrôle qui doit rendre un résultat attendu (le
plus souvent zéro ligne) à la fin d'un fichier de la chaîne.

**Banc**, **banc d'essai.** Un script qui rejoue un fichier de la chaîne sur une
base PostgreSQL jetable (`sql/banc_*.sh`, via `pgserver`) pour l'éprouver
avant de le jouer sur la vraie base.

**Diagnostic** (`diag_*.sql`). Une requête en lecture seule qui mesure un
problème sans rien modifier.

**Trace** (`*_trace`). Une table où chaque fichier de la chaîne enregistre ce
qu'il a posé. `sql/diag/diag_passages.sql` s'en sert pour savoir quels fichiers ont
réellement été joués.

**Contrôle indépendant.** Une comparaison avec une source qui n'a pas servi à
construire la couche contrôlée : Gay pour 1870-1940, GEOFLA 2014 pour
1999-2012, HAC pour la filiation communale, ANR pour les dates de création.
