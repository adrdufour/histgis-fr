# Les cantons de 2025 peuvent-ils épargner du découpage manuel ?

Question posée le 11 août 2026 : récupérer des géométries cantonales, même
postérieures à 2012, pour limiter le nombre de villes à découper dans QGIS.

Réponse courte : **elles couvrent 67 % des villes mais seulement 26 % du
travail.** À prendre comme fond de calage, pas comme économie.

## Ce qui a été écarté d'abord

GEOFLA ne sert à rien pour cela, quel que soit le millésime. L'édition 2014
(`sources/geofla/canton2014`) compte 3 708 polygones dont **295 au code ≥ 90 — les
pseudo-cantons de ville**. Bordeaux tombe entièrement dans « 3399 », Toulouse
dans « 3199 », Lille dans « 5992 », Bourg-en-Bresse dans « 0199 ». L'IGN y
replie chaque ville divisée exactement comme la couche 1999 déjà en base ; les
348 cantons qui manquent au COG 2012 sont ceux-là. Aucune ligne intérieure.

## La donnée qui existe

**ADMIN EXPRESS version 4, avril 2025.** C'est la première à publier « le
contour réel » des cantons : la commune multi-cantonale y est scindée. Licence
Ouverte 2.0. Le champ `composition` le dit sans qu'on ait à mesurer :

| composition | cantons |
|---|---|
| Commune(s) entière(s) | 1 384 |
| Fraction d'une commune et de commune(s) entière(s) | 409 |
| Fraction de commune | 232 |
| Fractions de plusieurs communes | 19 |
| Fractions de plusieurs communes et de commune(s) entière(s) | 10 |
| NR | 1 |

**670 cantons sur 2 055 coupent au moins une commune**, pour 216 communes
coupées au total.

Jeu utilisé pour la mesure : `a_can2025.geojson` (icem7, d'après IGN COG CARTO
PLUS), géométrie **simplifiée** — bonne pour compter, pas pour digitaliser.
Pour QGIS il faudra ADMIN EXPRESS COG v4 complet.

## Le résultat

`cartes/couverture_cantons_2025.py`, sortie `couverture_cantons_2025.csv`.

| période | villes divisées | servies par 2025 | à tracer |
|---|---|---|---|
| historique (1870-1940) | 118 | 80 (67 %) | 38 |
| moderne (1943-2012) | 194 | 96 (49 %) | 98 |

Mais le taux par ville trompe. Ce qui coûte, ce sont les **coupes internes**,
et une ville servie ne l'est presque jamais autant qu'il faudrait :

| | coupes |
|---|---|
| à produire, période historique | 472 |
| offertes par le découpage 2025 | 123 |

**26 %.** Nantes demande 17 coupes internes, 2025 en offre 1. Limoges 15 pour
1, Toulouse 14 pour 1, Le Havre 14 pour 1.

La cause est la même partout : la maille cantonale s'est effondrée. 4 056
cantons au COG 2012, 2 055 en 2025. À l'intérieur d'une ville, le canton de
1870 était une unité petite ; celui de 2025 est un gros quartier.

## La règle qui prédit la disponibilité

Une commune est coupée en 2025 **si et seulement si elle pèse plus qu'un canton
entier de son département** — population communale rapportée à la population
départementale divisée par le nombre de cantons.

| | n | pop / cible (médiane) | au-dessus de 1 |
|---|---|---|---|
| historique, servies | 80 | 2,67 | 91 % |
| historique, à tracer | 38 | 0,67 | 13 % |
| moderne, servies | 96 | 1,39 | 85 % |
| moderne, à tracer | 98 | 0,75 | 17 % |

C'est la loi de 2013 : le découpage est fait « sur des bases essentiellement
démographiques ». Le seuil des 3 500 habitants n'explique rien ici — les
communes modernes non servies ont une médiane de 27 250 habitants.

Corollaire utile : la disponibilité n'est pas aléatoire, elle est **prévisible
et favorable**. Les villes servies sont les plus grosses, celles dont le
découpage manuel coûte le plus cher.

## Une prédiction fausse, et pourquoi

J'avais annoncé que le taux moderne devait dépasser 90 %, deux découpages
séparés de trente ans devant se recouvrir presque partout, et qu'un chiffre
plus bas signalerait un défaut du test. Il est sorti à 49 %.

Le test n'avait pas de défaut : **le critère a changé**. Les communes
partagées d'après 1943 l'étaient sous un régime à 4 000 cantons ; 2015 en a
supprimé la moitié et une ville de 27 000 habitants tient désormais entière
dans un canton. La proximité chronologique ne garantit rien quand la règle de
découpe change entre les deux dates.

## Trois pièges rencontrés

**Le seuil de surface.** À 2 % de recouvrement, 8 156 communes ressortaient
« coupées » par GEOFLA 2014, toutes à 96/3 : c'était le décalage entre
millésimes, pas des coupes. Seuil retenu : 15 %.

**Le dénominateur.** Trois chiffres successifs pour « les villes à découper » —
270, puis 369, puis 118. Le premier comptait des codes de pseudo-canton qui
changent au fil des millésimes. Le second groupait par `insee_geofla` en
comptant les atomes, ce qui rassemble les communes anciennes **absorbées**,
qui partagent le rattachement GEOFLA sans avoir jamais été coupées. Seul le
troisième compte ce qu'il annonce : les atomes-fraction `cassini#canton`.

**Deux chantiers sous un seul nom.** `24_canton_moderne.sql` pose lui aussi des
atomes-fraction, marqués `atom_geom.source = 'fraction_cog'` : communes
partagées après 1943, données par le COG. Les compter avec les autres donnait
un taux moyen de 56 % qui ne décidait de rien.

## Ce qu'il faut en faire

Prendre la couche comme **fond de calage** : elle donne des lignes propres,
topologiquement valides, calées sur des rues et des cours d'eau réels, dans les
80 villes les plus lourdes. Elle ne dispense pas de tracer les 349 autres
coupes.

Pour aller plus loin il faudrait une trame de maille comparable à celle de
1870. Candidat à tester, non vérifié à ce jour : **CONTOURS-IRIS** (IGN/INSEE,
Licence Ouverte), dont les mailles font quelques milliers d'habitants et
suivent la voirie. Si les limites cantonales anciennes suivent des rues — ce
que les décrets laissent penser —, les arêtes d'IRIS en porteraient une bonne
part. À mesurer, pas à supposer.

---

## CONTOURS-IRIS comme trame de découpe — testé le 14 août 2026

L'hypothèse posée en fin de note précédente est vérifiée. **Elle tient.**

### La mesure

Le chantier réel n'est pas de 472 coupes mais de **214**, portées par 119
villes — et **81 de ces villes n'ont qu'une seule coupe à tracer**. Le compte
de 472 mélangeait les atomes-fraction de TRF-GIS et ceux du COG moderne.

Les IRIS n'existent que pour les communes de plus de 10 000 habitants et la
plupart de celles entre 5 000 et 10 000. D'où la question : combien de nos
villes sont au-dessus ?

| population | villes | coupes | IRIS |
|---|---|---|---|
| ≥ 10 000 | 108 | 182 | toujours |
| 5 000 - 10 000 | 7 | 7 | en général |
| < 5 000 | **2** | **2** | non |
| Lyon et Marseille | 2 | 23 | oui, très finement |
| **total** | **119** | **214** | |

**Seules Confolens (2 800 hab.) et Tartas (3 000 hab.) sont hors de portée**,
pour une coupe chacune.

### La densité

| ville | coupes à tracer | IRIS disponibles |
|---|---|---|
| Nantes | 6 | 97 |
| Dinan | 1 | 7 |
| Dourdan | 1 | 4 |
| Crest | 1 | 3 |
| Confolens | 1 | **1** |

La maille est d'un ordre de grandeur plus fine que le besoin partout où elle
existe.

### Comparaison avec ADMIN EXPRESS v4

| | villes couvertes | coupes couvertes |
|---|---|---|
| ADMIN EXPRESS v4 (cantons 2025) | 67 % | **26 %** |
| CONTOURS-IRIS | **97 %** | **88 %** |

Les deux sont en Licence Ouverte. Le second est massivement supérieur, pour la
raison qui avait fait échouer le premier : la maille cantonale de 2025 est un
gros quartier, celle des IRIS est un pâté de maisons.

### La réserve, qui reste entière

**Disposer d'une trame fine ne prouve pas que les limites de 1870 la suivent.**
Les IRIS sont calés sur les limites communales, la voirie et les îlots — pas
sur les limites cantonales.

Mais le précédent parisien est encourageant et il est documenté : à Paris,
l'INSEE cale explicitement les IRIS sur **les limites de quartier**, ce qui a
permis de reconstruire les 80 quartiers par simple union. Ailleurs, la trame
n'est qu'un support d'accrochage — des lignes propres, topologiquement valides,
calées sur des rues réelles, où l'on choisit au lieu de dessiner.

**Le taux de reprise réel se mesurera ville par ville dans QGIS**, Marseille en
premier puisque ses onze lignes sont décrites. Mais l'ordre de grandeur du
chantier vient de changer : 214 coupes, dont 189 avec une trame fine sous la
main, et 2 seulement à tracer sans aucun appui.

---

## La trame est récupérée — 14 août 2026

`cartes/recupere_iris.py`, sorties `iris_villes.geojson`, `iris_villes.csv`,
table `histgis.iris_ville`. **4 219 IRIS, les 119 villes servies.**

| | villes | coupes pourvues d'une trame |
|---|---|---|
| ADMIN EXPRESS v4 | 67 % | 123 / 472 mesurées alors — 26 % |
| **CONTOURS-IRIS** | **119 / 119** | **211 / 214 — 98,6 %** |

Le 88 % annoncé avant récupération était une estimation tirée des seuils de
population publiés par l'INSEE. La récupération fait mieux : le seuil des
5 000 habitants est appliqué plus souplement que la règle ne l'annonce.

| verdict | villes |
|---|---|
| trame confortable | 114 |
| trame juste suffisante | 2 |
| sans trame | 3 |

Trame juste suffisante : **Saint-Flour** (15187) et **Avesnes-sur-Helpe**
(59036), 2 IRIS pour 1 coupe — une seule ligne interne offerte.

Sans trame : **Confolens** (16106), **Tartas** (40313), **Le Quesnoy** (59481),
une coupe chacune, un seul IRIS donc aucune ligne interne.

### Le piège des arrondissements, rencontré une troisième fois

Le premier passage a rendu **zéro IRIS pour Marseille et zéro pour Lyon** —
les deux plus grosses villes du lot, 23 coupes à elles deux. CONTOURS-IRIS
code ces communes par **arrondissement municipal** : 13201-13216 et
69381-69389, jamais 13055 ni 69123. Marseille en a 393, Lyon 185.

C'est le même piège que dans GEOFLA, qui faisait ressortir Marseille comme
« non divisée », et que dans le codage parisien. Trois sources indépendantes,
trois fois la même chausse-trappe.

Ce qui le rend coûteux : **un zéro n'a pas l'air d'une erreur.** Pour une
commune de 3 000 habitants, zéro IRIS est la bonne réponse. L'anomalie n'a été
visible que parce qu'elle frappait les deux plus grandes villes de la liste —
si elle avait touché une ville moyenne, elle serait passée pour un fait.

D'où la règle, ajoutée à celles du projet : **un résultat nul doit être
confronté à l'ordre de grandeur attendu, pas seulement à sa plausibilité.**

### Ce que la trame ne dit toujours pas

`IRIS >= coupes + 1` est une **condition nécessaire**, pas une garantie que la
limite cantonale de 1870 figure parmi les lignes offertes. Les IRIS sont calés
sur la voirie et les îlots — sauf à Paris, où l'INSEE les cale explicitement
sur les limites de quartier. Le taux de reprise réel se mesurera ville par
ville dans QGIS, Marseille en premier puisque ses onze lignes sont décrites
dans `gaudillere/protocole_georeferencement.md`.
