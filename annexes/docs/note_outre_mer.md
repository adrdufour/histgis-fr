# L'outre-mer — repérage des sources, 16 août 2026

> **Mise à jour du 16 août, après téléchargement.** Les archives sont sur le
> disque et vérifiées. Deux choses annoncées ici se sont révélées fausses à
> l'ouverture, elles sont corrigées en place et détaillées au §5 :
> les lots « tous thèmes » ne contiennent que les cantons, et GEOFLA
> n'individualise pas les cantons des communes multicantonales — 45 % seulement
> des cantons d'outre-mer ont un polygone propre. Le §6 rend compte de la trame
> communale, dont la recette est passée sans réserve.

L'outre-mer était jusqu'ici **hors périmètre** (`ETAT.md` §Limites, `JOURNAL.md`
l. 615, `note_1943_2012.md` §168). Cette note rouvre le dossier : que faut-il
récupérer, où, sous quelle licence, et ce qui bloque.

Périmètre demandé : les quatre vieilles colonies, plus Mayotte, Saint-Pierre-et-
Miquelon, Saint-Barthélemy et Saint-Martin, plus le Pacifique, plus l'Algérie et
les colonies à députés. Trois niveaux : communes, cantons, circonscriptions.

Conclusion en une phrase : **les DOM sont à portée immédiate, le Pacifique bute
sur une licence, l'Algérie est un chantier d'un autre ordre.**

---

## 1. Ce qui est déjà sur le disque, et qu'on ne savait pas

`circo/correspondance_2012.xls` — le fichier du ministère de l'Intérieur qui a
servi pour 1986 et 2012 — **contient l'outre-mer**. Il avait été filtré à
l'extraction, `note_circonscriptions.md` §2.2 le signalant comme hors périmètre.

171 lignes, extraites dans `circo/circo_outremer_1986_2012.csv` :

| dép. | code Intérieur | cantons | communes | circo 1986 | circo 2012 |
|---|---|---|---|---|---|
| 971 Guadeloupe | `ZA` | 40 | 32 | 4 | 4 |
| 972 Martinique | `ZB` | 45 | 34 | 4 | 4 |
| 973 Guyane | `ZC` | 19 | 22 | 2 | 2 |
| 974 La Réunion | `ZD` | 49 | 24 | 5 | **7** |

Trois recoupements indépendants tombent juste, ce qui donne confiance dans la
lecture :

- **Guadeloupe : 40 cantons pour 43 codes.** `ZA23`, `ZA25` et `ZA29` manquent —
  ce sont Saint-Barthélemy et les deux cantons de Saint-Martin, détachés en 2007.
  Le fichier est donc bien postérieur à la partition, et les 32 communes le
  confirment.
- **La Réunion passe de 5 à 7 circonscriptions**, ce qu'a fait le redécoupage de
  2010. C'est le seul département d'outre-mer qui bouge entre les deux colonnes.
- Mayotte, Saint-Pierre-et-Miquelon, Saint-Barthélemy et Saint-Martin sont
  **absents** du fichier : ils n'étaient pas départements en 1986 et ont obtenu
  leurs sièges en 2012 par une autre voie.

### Le piège du code commune, différent de la métropole

`note_circonscriptions.md` §2.1 pose `insee = dep.zfill(2) || com.zfill(3)`.
**Cette règle est fausse outre-mer.** Le `Code commune` y porte déjà le chiffre
du département :

| dép. | `Code commune` | INSEE |
|---|---|---|
| `ZA` | 101 → 134 | `97` + code, soit 97101 → 97134 |
| `ZB` | 201 → 234 | 97201 → 97234 |
| `ZC` | 301 → 362 | 97301 → 97362 |
| `ZD` | 401 → 424 | 97401 → 97424 |

Donc `insee = '97' || com`, tout simplement. Vérifié sur cinq communes connues :
Cayenne 97302, Saint-Denis 97411, Fort-de-France 97209, Les Abymes 97101,
Saint-Paul 97415. Appliquer la règle métropolitaine aurait donné `ZA101`.

---

## 2. Les trames géométriques — GEOFLA couvre les DOM

GEOFLA décrit « la France métropolitaine **et les DROM** ». Le catalogue de la
Géoplateforme donne, par département d'outre-mer, les mêmes thèmes qu'en
métropole. Millésimes disponibles : 1999, puis 2015 et 2016 — **il n'y a pas de
millésime 2011 outre-mer**, contrairement à la métropole.

### Le bon lot : l'édition du 4 mars 2015

C'est exactement le pendant du lot métropolitain déjà en place
(`sources/geofla/canton2014/GeoFLA_2-0__SHP_LAMB93_FXX_2015-03-04`) : même
version 2-0, même date, et surtout **les cantons d'avant la réforme de 2015**.
Prendre une édition de juillet ou décembre 2015 ferait entrer les nouveaux
cantons, sans usage ici.

| zone | lot | poids | md5 |
|---|---|---|---|
| D971 | `GeoFLA_2-0__SHP_UTM20W84GUAD_D971_2015-03-04` | 638 Ko | `ab3e0dd4…` |
| D972 | `GeoFLA_2-0__SHP_UTM20W84MART_D972_2015-03-04` | 642 Ko | `7d335db9…` |
| D973 | `GeoFLA_2-0__SHP_UTM22RGFG95_D973_2015-03-04` | 667 Ko | `8b926f91…` |
| D974 | `GeoFLA_2-0__SHP_RGR92UTM40S_D974_2015-03-04` | 637 Ko | `00bf1460…` |
| D976 | `GeoFLA_2-0__SHP_RGM04UTM38S_D976_2015-03-04` | 636 Ko | `e2341537…` |

**Ces lots ne contiennent que la couche `CANTON`**, malgré leur nom de lot sans
thème. Les communes font l'objet de cinq lots séparés
(`GEOFLA_2-0_COMMUNE_SHP_<CRS>_D97x_2015-03-04`, ~1,8 Mo chacun), à la même date.
Licence Ouverte. URL, md5 et décompression : `sources/outremer/telecharger_outremer.sh`.

**Cinq projections différentes**, une par territoire (UTM20 Guadeloupe, UTM20
Martinique, UTM22 RGFG95 Guyane, RGR92 UTM40S Réunion, RGM04 UTM38S Mayotte).
Rien de commun avec le Lambert-93 métropolitain : la reprojection est obligatoire
avant tout chargement, et c'est le premier endroit où une erreur passera
inaperçue.

### Le contrôle de stabilité : fait, et il est excellent

GEOFLA 1-0 donne les communes de 1999 pour Guadeloupe, Martinique et Réunion
(pas la Guyane, pas Mayotte). Comparées au fichier du ministère :

| dép. | 1999 | 2012 | écart |
|---|---|---|---|
| 971 Guadeloupe | 34 | 32 | `97123` Saint-Barthélemy et `97127` Saint-Martin |
| 972 Martinique | 34 | 34 | aucun |
| 974 La Réunion | 24 | 24 | aucun |

**90 communes sur 92 sont identiques**, et les deux écarts sont exactement le
détachement de 2007. La trame communale d'outre-mer ne bouge pas — c'est
l'hypothèse implicite de tout le projet dès qu'on projette une géométrie récente
sur le XIXᵉ siècle, et ici elle se vérifie au lieu de se supposer.

Le même fait apparaît par un troisième chemin au §1 : les codes cantonaux
`ZA23`, `ZA25` et `ZA29` manquants. Trois lectures indépendantes, un seul
événement.

### Ce que GEOFLA ne couvre pas

Saint-Pierre-et-Miquelon, Saint-Barthélemy et Saint-Martin ne sont pas dans
GEOFLA. Ils sont dans ADMIN EXPRESS COG, mais **en GeoPackage seulement**, et
seulement aux millésimes 2025 et 2026 (`ADMIN-EXPRESS-COG_4-0__GPKG_RGSPM06U21_SPM_2025-01-01`
pour SPM, téléchargé et ouvert). Le lot SPM donne deux communes, `97501`
Miquelon-Langlade et `97502` Saint-Pierre, avec
`code_insee_du_canton = 'NR'` — l'absence de canton y est explicite, pas
déduite. Géométrie de confort, pas un socle.

Saint-Barthélemy et Saint-Martin sont récupérables autrement, et mieux : le
millésime GEOFLA 1999 de la Guadeloupe les contient encore, sous leurs codes
`97123` et `97127`. Un jeu déjà sur le disque vaut mieux qu'un lot 2025.

---

## 3. Le Pacifique — la trame existe, la licence bloque

> **Levé le 25 octobre 2026** (`sql/135_pacifique.sql`, récit dans
> `JOURNAL.md`). Nouvelle-Calédonie : le jeu simplifié de data.gouv.nc est en
> Licence Ouverte 2.0 ; c'est lui qui est chargé, pas le `.gdb` du DITTT, dont
> les CGU excluent l'exploitation commerciale. Polynésie : l'ODbL est
> acceptée, les cartes rendues étant des « œuvres produites » qui citent
> l'ISPF. Ce qui suit est l'état du 16 août.

**Polynésie française.** Le jeu « Limites géographiques administratives » de
l'ISPF sur data.gouv.fr donne communes, communes associées et îles en shapefile,
avec la hiérarchie complète. Il est publié en **ODbL**. C'est exactement le mur
d'ALPAGE-Vasserot pour le Paris d'avant 1860 (`RESTE_A_FAIRE.md` §3) :
incompatible avec la contrainte de licence du projet, et à traiter pareil —
soit une source de substitution, soit rien.

**Nouvelle-Calédonie.** BDADMIN-NC (gouvernement de la Nouvelle-Calédonie /
DITTT) porte les limites communales terrestres, diffusée par Géorep et
data.gouv.nc. La licence n'a pas pu être lue : les deux portails sont des
applications JavaScript et leur API n'a rien renvoyé depuis ici. **À vérifier
avant tout téléchargement** — c'est le point qui décide si la
Nouvelle-Calédonie entre ou non.

**Wallis-et-Futuna.** Rien trouvé. Trois circonscriptions coutumières, trois
communes de fait mais pas de communes de droit : le niveau communal n'existe
pas, ce qui rend l'objet différent du reste.

Rappel de calendrier, qui limite l'enjeu : les communes de Nouvelle-Calédonie
datent de 1961, celles de Polynésie de 1971. Sur la période 1870-2012, le
niveau communal du Pacifique n'existe que sur le dernier tiers. Les sièges
législatifs, eux, remontent à 1945.

---

## 4. L'Algérie et les colonies à députés — un autre chantier

C'est le morceau qui ne ressemble à aucun des précédents, et il faut le dire
avant de s'y engager : **aucune trame ouverte n'existe.**

Ce qu'on cherche : 3 départements de 1848 à 1955, puis 15 en 1962 ; des communes
de plein exercice et des communes mixtes dont le régime n'a pas d'équivalent
métropolitain ; des députés jusqu'en 1962. À quoi s'ajoutent le Sénégal (les
quatre communes, députés dès 1848 par intermittence puis 1871), l'Inde
française, la Cochinchine.

Ce qui existe et ne convient pas :

- **OSM et ses dérivés** (dont OSM2IGEO-Algérie sur data.gouv.fr) : géométrie
  d'aujourd'hui, et surtout **ODbL** — même mur que la Polynésie.
- **GADM** : usage non commercial, redistribution interdite. Exclu.
- **ANOM** (Archives nationales d'outre-mer) : la nomenclature des communes est
  là, avec les codes, mais sans géométrie.

La seule route propre est celle déjà éprouvée pour Marseille : **géoréférencer
des cartes du domaine public** et digitaliser. À l'échelle de l'Algérie, ce
n'est pas une tâche mais un projet séparé — et la couche départementale (3 puis
15 objets) coûte infiniment moins cher que la couche communale (plus de 1 500
communes en 1962). Si l'objet du projet est électoral, la couche départementale
et les circonscriptions suffisent probablement.

**Recommandation : traiter l'Algérie en dernier, au niveau départemental seul,
et seulement une fois les DOM chargés.** Le reste — Sénégal, Inde, Cochinchine —
se réduit à quelques points et n'a pas besoin de polygones.

---

## 5. Ce que l'ouverture des archives a démenti

Les neuf archives ont été téléchargées le 16 août. **Les cinq md5 relevés au flux
ATOM concordent exactement** — les fichiers sont ceux annoncés. Deux affirmations
de cette note, écrites d'après le catalogue, ne survivent pas à l'ouverture.

### Les lots « tous thèmes » n'en contiennent qu'un

`GeoFLA_2-0__SHP_<CRS>_D97x_2015-03-04` ne livre que `CANTON`. Le nom de lot sans
thème et le poids de 640 Ko laissaient croire à un paquet complet ; c'est un
paquet cantonal. Le même piège existait en métropole et n'avait pas été relevé :
`sources/geofla/canton2014/` ne contient, lui aussi, qu'un répertoire `CANTON`.

Les communes sont dans cinq lots séparés à la même date. Elles ont été ajoutées
au script ; il reste à les télécharger.

### GEOFLA n'individualise pas les cantons des communes multicantonales

C'est le point qui compte. Une commune partagée entre plusieurs cantons n'est pas
découpée : GEOFLA en fait **une seule entité**, portant un pseudo-code cantonal
pris dans `90`-`99` et le nom de la commune comme chef-lieu.

| dép. | cantons réels | polygones propres | agrégats | couverture |
|---|---|---|---|---|
| 971 Guadeloupe | 40 | 18 | 10 | 45 % |
| 972 Martinique | 45 | 24 | 6 | 53 % |
| 973 Guyane | 19 | 13 | 1 | 68 % |
| 974 La Réunion | 49 | 14 | 10 | **29 %** |
| 976 Mayotte | 19 | 16 | 1 | 84 % |
| **total 971-974** | **153** | **69** | **27** | **45 %** |

**Les 27 agrégats de GEOFLA correspondent, un pour un et nom pour nom, aux 27
communes multicantonales du fichier du ministère.** Deux sources qui ne se
connaissent pas tombent d'accord sans exception : Fort-de-France, Le Lamentin,
Les Abymes, Pointe-à-Pitre, Saint-Denis, Le Tampon, Cayenne, Mamoudzou… La
lecture est donc sûre, et c'est bien un manque de la source, pas de la lecture.

La Réunion est le cas extrême : **35 de ses 49 cantons n'ont aucune géométrie
propre**, parce que dix communes très peuplées y concentrent l'essentiel du
découpage. C'est plus mauvais que tout ce qu'on a rencontré en métropole.

**La suite était déjà écrite ailleurs, et elle marche.** C'est exactement le
problème des 119 villes multicantonales métropolitaines, résolu le 14 août par
CONTOURS-IRIS. Le WFS de la Géoplateforme a été interrogé le 16 août sur les 28
communes concernées :

| dép. | communes | coupes | IRIS |
|---|---|---|---|
| 971 Guadeloupe | 10 | 14 | 82 |
| 972 Martinique | 6 | 15 | 80 |
| 973 Guyane | 1 | 5 | 24 |
| 974 La Réunion | 10 | 25 | 253 |
| 976 Mayotte | 1 | 2 | 33 |
| **total** | **28** | **61** | **472** |

**864 IRIS outre-mer, dont 472 sur les 28 communes à découper.** La condition
nécessaire `IRIS ≥ coupes + 1` tient pour **28 communes sur 28, soit 61 coupes
sur 61** — mieux qu'en métropole, où trois villes restaient sans appui. Densité :
7,7 IRIS par coupe, du même ordre que le confort métropolitain.

Aucun cas limite, et les deux plus lourds sont les mieux servis : Saint-Denis
64 IRIS pour 8 coupes, Fort-de-France 38 pour 9. Les deux comptes ont été
recontrôlés un par un contre le service (`RESULTTYPE=hits`). Le détail est dans
`cartes/iris_outremer.csv`.

Ce que cela ne prouve pas, ici comme en métropole : que les limites cantonales
suivent des limites d'IRIS. C'est un support de tracé, pas une réponse — le taux
de reprise réel se mesurera commune par commune dans QGIS.

### Deux confirmations en passant

`CODE_CHF` de GEOFLA outre-mer porte le code commune sur trois chiffres — `608`
pour Dzaoudzi, `353` pour Maripasoula, `102` pour Anse-Bertrand — et
`'97' || CODE_CHF` donne le bon code INSEE. La règle du §1, tirée du fichier du
ministère, se retrouve inchangée dans une source qui n'a rien à voir.

`CODE_DEPT` vaut **`97` pour les cinq départements**. L'attribut ne distingue pas
la Guadeloupe de Mayotte : le département ne peut venir que du lot. Une jointure
naïve sur `CODE_DEPT` fusionnerait les cinq territoires en silence.

---

## 6. La trame communale : recette passée, et un cadeau

Les cinq lots `COMMUNE` ont été téléchargés — md5 concordants — et passés à
`sources/outremer/recette_outremer.py`, qui rejoue tout et se relance.

| dép. | communes | attendu | invalides | somme km² | union km² | recouvrement | vs `SUPERFICIE` |
|---|---|---|---|---|---|---|---|
| 971 | 32 | 32 | 0 | 1 631,5 | 1 631,5 | **0,00** | −0,3 % |
| 972 | 34 | 34 | 0 | 1 103,7 | 1 103,7 | **0,00** | −0,4 % |
| 973 | 22 | 22 | 0 | 83 824,4 | 83 824,4 | **0,00** | −0,0 % |
| 974 | 24 | 24 | 0 | 2 501,6 | 2 501,6 | **0,00** | −0,1 % |
| 976 | 17 | 17 | 0 | 362,5 | 362,5 | **0,00** | −1,0 % |

**129 communes, zéro géométrie invalide, zéro recouvrement.** Le contraste avec
la métropole est net : là-bas, 3 945 km² sont comptés deux fois en 1870, parce
que des communes historiques fusionnées partagent un code INSEE. Outre-mer, ce
défaut n'existe pas — aucune commune n'est fractionnée dans la trame, et la
somme des surfaces égale l'union au centième de km² près. C'est la limite
principale du projet qui, ici, ne s'applique pas.

Les surfaces tombent à 0,0-1,0 % de l'attribut `SUPERFICIE` du même jeu : la
lecture et la projection sont bonnes.

### Le cadeau : l'attribution commune → canton est déjà là

`INSEE_COM` est écrit en clair dans la couche — inutile de reconstituer quoi que
ce soit — et les codes sont **identiques au fichier du ministère dans les quatre
DOM**, 112 sur 112.

Mieux : la couche `COMMUNE` porte un `CODE_CANT`, et pour les communes d'un seul
canton il **concorde 85 fois sur 85** avec le canton du fichier de l'Intérieur.

| dép. | monocantonales concordantes |
|---|---|
| 971 | 22 / 22 |
| 972 | 28 / 28 |
| 973 | 21 / 21 |
| 974 | 14 / 14 |

Les 27 communes multicantonales portent, elles, le pseudo-code `90`-`99` — la
façon dont GEOFLA dit « je ne découpe pas ». Ce n'est pas une lacune silencieuse
mais un aveu explicite, et il est exact : vérifié pour les 28 (Mayotte comprise).

Autrement dit, **l'attribution communale du niveau cantonal est acquise pour 85
des 112 communes des quatre DOM, sans travail**. Le reste est le chantier IRIS
du §5.

---

## 7. Le SRID : l'outre-mer vit en 4326

Le Lambert-93 n'est défini que pour la métropole. Reprojeter l'outre-mer en 2154
gonfle les surfaces — mesuré, pas supposé :

| dép. | aire native | en 2154 | facteur |
|---|---|---|---|
| 971 Guadeloupe | 1 631 km² | 2 092 km² | 1,28× |
| 972 Martinique | 1 104 km² | 1 451 km² | 1,31× |
| 973 Guyane | 83 824 km² | 136 372 km² | 1,63× |
| 976 Mayotte | 362 km² | 944 km² | 2,61× |
| 974 La Réunion | 2 502 km² | **8 856 km²** | **3,54×** |

Ce ne sont pas des arrondis, et tous les contrôles du projet sont surfaciques.

**Décision : tables d'outre-mer en EPSG:4326, base métropolitaine inchangée.**
Les surfaces s'y calculent en `geography` — exactes sur l'ellipsoïde,
indépendantes de toute projection. `snapshot_geom()` reprojettera à la volée
pour rendre une couche unique. Rien à recharger, et le 2154 garde sa commodité
métrique là où il est défini.

Corollaire à ne pas oublier : en 4326, `ST_Area(geom)` rend des **degrés
carrés** — un nombre qui ressemble à une surface sans en être une. Toute mesure
passe par `ST_Area(geom::geography)`.

### Le piège des axes, désamorcé d'avance

En WFS 2.0, `EPSG:4326` peut être servi en lat/lon plutôt qu'en lon/lat selon
l'implémentation. Inverser les axes place la Guadeloupe (−61,5 ; 16,2) au large
de la Somalie (16,2 ; −61,5) : géométrie valide, décompte juste, carte fausse.
C'est le bogue du préfixe Marseille à l'échelle du globe.

`cartes/recupere_iris_outremer.py` vérifie donc chaque entité contre l'emprise
de son territoire et **refuse d'écrire** si elle en sort. Testé dans les deux
sens. Le service n'a pas encore été interrogé pour de vrai : si les axes sont
bons, le contrôle ne coûte rien.

---

## 8. Ce que ça change pour la base

Le socle existant absorbe l'outre-mer sans modification d'architecture : les
atomes sont des géométries, `membership` est une attribution datée, rien n'est
pré-dissous. Un atome guadeloupéen est un atome comme un autre.

Trois points d'attention, tous du même genre que ceux déjà rencontrés :

1. **La reprojection.** Cinq CRS distincts, aucun n'étant le Lambert-93. Une
   erreur y sera silencieuse — géométrie valide, simplement au mauvais endroit.
   C'est le bogue du préfixe Marseille, en cinq exemplaires.
2. **La profondeur temporelle.** Les DOM ne sont départements que depuis 1946.
   Avant, ce sont des colonies avec des députés mais pas de cantons au sens
   métropolitain. Poser 1870-1946 outre-mer demande des sources d'un autre type
   que celles de la métropole — pas une extension, une enquête.
3. **Le même trou 1943-1999** qu'en métropole pour les cantons, avec en plus
   l'absence de tout millésime GEOFLA entre 1999 et 2015.

## 9. Prochaines étapes, dans l'ordre

1. ~~Télécharger~~ **fait** : neuf archives, cinq md5 concordants.
2. ~~Recouper les effectifs, comparer 1999 et 2015~~ **fait** : §5 et §2.
3. ~~Relancer le script pour les cinq lots `COMMUNE`~~ **fait** : recette passée,
   §6.
4. ~~Vérifier que CONTOURS-IRIS couvre les DOM~~ **fait** : 28/28 communes,
   61/61 coupes pourvues.
5. **Lancer `cartes/recupere_iris_outremer.py`** — écrit, testé à blanc, pas
   encore exécuté contre le service.
6. Écrire le `.sql` qui pose les 129 communes en atomes 4326, avec les
   85 rattachements cantonaux acquis et les circonscriptions 1986 et 2012 de
   `circo/circo_outremer_1986_2012.csv`.
7. ~~Trancher la Nouvelle-Calédonie sur la licence de BDADMIN-NC~~ **fait** le
   25 octobre 2026 : BDADMIN-NC écarté, jeu Licence Ouverte de data.gouv.nc
   chargé, Polynésie en ODbL avec lui (`135`).
8. L'Algérie, au niveau départemental, plus tard.

Tout ce qui se télécharge est sur le disque, sauf la trame IRIS, dont le script
est prêt.

---

## Sources

- [GEOFLA® — catalogue Géoplateforme](https://data.geopf.fr/telechargement/resource/GEOFLA)
- [ADMIN EXPRESS COG — catalogue Géoplateforme](https://data.geopf.fr/telechargement/resource/ADMIN-EXPRESS-COG)
- [Limites géographiques administratives (Polynésie française, ISPF) — ODbL](https://www.data.gouv.fr/datasets/limites-geographiques-administratives)
- [Communes de Nouvelle-Calédonie, limites terrestres simplifiées — data.gouv.nc](https://data.gouv.nc/explore/dataset/communes-nc-limites-terrestres-simplifiees/)
- [BDADMIN-NC : limites administratives — Géorep](https://georep.nc/node/1422)
- [Tableau des circonscriptions électorales départementales, DOM — Légifrance](https://www.legifrance.gouv.fr/codes/section_lc/JORFTEXT000000317302/LEGISCTA000006120408/)
- [Archives nationales d'outre-mer — Algérie](http://anom.archivesnationales.culture.gouv.fr/geo.php?lieu=Alg%C3%A9rie)
- `circo/correspondance_2012.xls` (ministère de l'Intérieur), déjà dans le dépôt
