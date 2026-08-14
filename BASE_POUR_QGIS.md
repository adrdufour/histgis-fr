# HistGIS — note de passation pour une carte des villes multicantonales

Destinataire : un agent disposant de QGIS via MCP.
Objectif : **cartographier les communes réparties entre plusieurs cantons**,
celles qu'il faudra découper à la main.

---

## 0. Le point à comprendre avant tout le reste

**Ces communes n'ont PAS de géométrie découpée. C'est tout le problème.**

Une commune répartie entre trois cantons porte trois « atomes-fraction » dans
la base, et ces trois atomes partagent **le même polygone** : celui de la
commune entière. La ligne qui les sépare n'existe nulle part — elle est
précisément ce qu'il faut aller tracer.

Donc :

* une carte qui colorie les cantons **superposera** ces communes trois fois,
  sans que rien ne le signale ;
* la carte demandée ici ne montre pas *où* passent les coupes, mais **quelles
  communes en attendent, et combien**.

Toute carte qui prétendrait montrer les limites internes de ces villes serait
fausse.

---

## 1. Connexion

```
dbname=histgis
schéma :  histgis          →  SET search_path TO histgis, public;
SRID   :  EPSG:2154        (Lambert 93, partout, sans exception)
```

La socket varie selon l'installation. Essayer dans l'ordre :
`host=/var/run/postgresql`, puis défaut, puis `host=localhost`.
La libpq de conda cherche la socket dans `/tmp` alors que Debian/Ubuntu la
posent dans `/var/run/postgresql` — d'où des « No such file or directory »
alors que `psql` fonctionne dans le même shell.

---

## 2. Les tables utiles

### `atom` — l'unité de base
| colonne | |
|---|---|
| `atom_id` | texte. **`cassini#canton` = atome-fraction** |
| `cassini` | identifiant TRF-GIS ; préfixe `N` = commune recréée en arrière |
| `fraction` | booléen |
| `insee_geofla` | rattachement à la trame GEOFLA 2011, `char(5)` |

### `atom_geom` — un polygone par atome
| colonne | |
|---|---|
| `atom_id` | clé primaire |
| `geom` | `geometry(MultiPolygon, 2154)` |
| `source` | `geofla`, `union_prefixe`, `absorbee`, `successeur`, `fraction_cog`, `arrondissement`, `creation_arriere` |
| `partagee` | booléen |

**Plusieurs atomes peuvent porter le même polygone**, volontairement.

### `membership` — l'appartenance dans le temps
| colonne | |
|---|---|
| `atom_id`, `unit_id` | |
| `niveau` | `'canton'` ou `'circo'` |
| `valid_from`, `valid_to` | dates |
| `periode` | `daterange` calculée — **utiliser `periode @> DATE '1870-06-01'`** |

### `unit` et `unit_version`
`unit(unit_id, niveau, dep, nom)` porte le **dernier nom connu**, donc
anachronique. Pour un nom d'époque, joindre `unit_version(unit_id, nom,
periode)` avec le même filtre de date. Sans cela on affiche « Oyonnax-Nord »
sur une carte de 1940, où le canton n'existait pas encore.

### Tables annexes
| table | contenu |
|---|---|
| `geofla_commune(insee_com, nom_comm, geom)` | trame communale GEOFLA 2011 |
| `noms_geofla(insee, nom, dep)` | dictionnaire de noms, 36 610 communes |
| `can2025(can, nom, dep, composition, geom)` | cantons 2025, ADMIN EXPRESS v4 |
| `paris_quartier(quartier, arrondissement, nom, iris, geom)` | les 80 quartiers |
| `paris_circo(periode, circo, quartiers, q_list, source, geom)` | 386 circos |
| `iris_ville(code_iris, code_insee, nom_commune, nom_iris, type_iris, geom)` | **4 219 IRIS des 119 villes à découper** — la trame d'accrochage |

---

## 3. La requête qui donne les villes à découper

```sql
SET search_path TO histgis, public;

SELECT a.insee_geofla                    AS insee,
       coalesce(n.nom, a.insee_geofla)   AS commune,
       count(*)                          AS fractions,
       count(*) - 1                      AS coupes_a_tracer,
       ST_Union(g.geom)                  AS geom
FROM   atom a
JOIN   atom_geom g USING (atom_id)
LEFT   JOIN noms_geofla n ON n.insee = a.insee_geofla
WHERE  a.insee_geofla IS NOT NULL
  AND  a.fraction
  AND  a.atom_id LIKE '%#%'
GROUP  BY 1, 2
HAVING count(*) > 1;
```

**Résultat attendu : 119 communes, 214 coupes.** Dont 81 communes à une seule
coupe, 16 à deux, 13 à trois ; Lyon en demande 12 et Marseille 11.

### Pourquoi ces trois conditions et pas une

* `a.fraction` **seul** ramasse aussi les communes recréées par
  `15_creation_arriere.sql`, qui ne sont pas des villes.
* `LIKE '%#%'` **seul** ne suffirait pas non plus.
* **Grouper par `insee_geofla` en comptant les atomes sans ces filtres donne
  369 au lieu de 119** : on ramasse alors les communes anciennes *absorbées*,
  qui partagent un rattachement GEOFLA sans avoir jamais été coupées entre
  cantons. Le critère est le fractionnement, pas la cohabitation.

### À ne pas confondre
`atom_geom.source = 'fraction_cog'` marque les communes partagées **après
1943**, posées par `24_canton_moderne.sql`. C'est un autre chantier, une autre
période. Les mélanger fausse tout.

---

## 4. Ce que la carte doit montrer

Proposition, à adapter :

1. **Fond** : `geofla_commune`, contour fin gris.
2. **Couche principale** : le résultat de la requête ci-dessus, colorée par
   `coupes_a_tracer` — un dégradé de 1 à 12 fait l'affaire, ou trois classes
   (1 coupe / 2-3 / 4 et plus).
3. **Étiquettes** : `commune` + `coupes_a_tracer`.
4. **Mention obligatoire en légende** : *« les limites internes de ces communes
   n'existent pas dans les données ; elles restent à tracer »*. Sans cela, la
   carte laisse croire à un découpage qui n'a pas eu lieu.

Deux compléments possibles :

* **`can2025`** en surimpression, filtré sur `composition LIKE 'Fraction%'` :
  ce sont les cantons de 2025 qui coupent réellement une commune. Ils couvrent
  67 % des villes mais seulement **26 % des coupes** — utile comme fond de
  calage, pas comme réponse.
* **`iris_ville`** — déjà en base, plus besoin d'aller au WFS. 4 219 IRIS
  couvrant **les 119 villes**, et **211 des 214 coupes** disposent d'au moins
  une ligne interne. C'est la trame d'accrochage à privilégier : la maille
  cantonale de 2025 est un gros quartier, celle des IRIS un pâté de maisons.

  Trois villes sans appui, une coupe chacune : **Confolens** (16106),
  **Tartas** (40313), **Le Quesnoy** (59481) — un seul IRIS, donc aucune ligne
  interne. Deux en trame juste suffisante : **Saint-Flour** (15187) et
  **Avesnes-sur-Helpe** (59036), 2 IRIS pour 1 coupe.

  Source si rechargement nécessaire : `cartes/recupere_iris.py` (WFS
  `data.geopf.fr/wfs/ows`, couche `STATISTICALUNITS.IRIS:contours_iris`,
  Licence Ouverte 2.0).

---

## 5. Trois pièges qui ont déjà coûté cher

**Grouper par la géométrie, jamais par un code.** Plusieurs communes de 1870
fondues depuis en une seule partagent un unique polygone de 2011 : dans les
Alpes-de-Haute-Provence, Espinouse, Saint-Jurson et Le Chaffaut portent les
mêmes 29,75 km². Dessinés séparément, ils s'empilent — trois libellés au même
endroit, sans que rien ne l'indique. Regrouper sur `md5(ST_AsEWKB(geom))`.

**Le nom d'unité est anachronique** si l'on ne joint pas `unit_version` avec un
filtre de période.

**Marseille, Lyon et Paris sont codées par arrondissement municipal**, pas par
leur code de commune — 13201-13216, 69381-69389, 75101-75120. C'est vrai dans
GEOFLA comme dans CONTOURS-IRIS. Interroger `13055` rend **zéro**, et zéro ne
ressemble pas à une erreur : pour une petite commune ce serait la bonne
réponse. Confronter tout résultat nul à l'ordre de grandeur attendu.

**Une commune peut relever de plusieurs cantons à la même date** — c'est
exactement le sujet. Toute recette qui suppose une partition stricte
(somme des surfaces = surface du département) échouera, et l'écart mesure le
double comptage, pas une erreur.

---

## 6. Fichiers hors base, si la base n'est pas disponible

Tout est reproductible sans PostgreSQL à partir de `build/` :

| fichier | contenu |
|---|---|
| `build/atom.csv` | `atom_id, cassini, insee, fraction` — les 333 atomes-fraction sont ceux dont `atom_id` contient `#` |
| `build/membership_canton.csv` | `atom_id, cassini, insee, unit_id, valid_from, valid_to` |
| `build/unit_canton.csv` | `unit_id, dep, nom` |
| `build/noms_geofla.csv` | `insee, nom, dep` |
| `cartes/couverture_cantons_2025.csv` | villes divisées et couverture 2025 |

Géométrie communale : le shapefile GEOFLA ED111 sous
`sources/geofla/repro/source_data/GEOFLA/GEOFLA_1-1_SHP_LAMB93_FR-ED111/GEOFLA/1_DONNEES_LIVRAISON_2013-12-00225/GEOFLA_1-1_SHP_LAMB93_FR-ED111/COMMUNES/COMMUNE.SHP`
— Lambert 93, champs `INSEE_COM`, `NOM_COMM`, `POPULATION` (en milliers),
`CODE_DEPT`.

---

## 7. Pour aller plus loin

* `cartes/cartes_cantons.py` produit déjà des planches A3 par département
  (1870, 1940, 1999, et 2025 avec `--2025`). Il **hachure en rouge** les
  communes revendiquées par plusieurs cantons : c'est la convention établie du
  projet, à réutiliser.
* `gaudillere/protocole_georeferencement.md` décrit comment digitaliser les
  coupes de Marseille — onze lignes internes pour 1870, 1886 et 1901. C'est le
  cas d'école du chantier.
* `RESTE_A_FAIRE.md` donne l'état général et les blocages.
* `METHODE.md` porte les règles du projet. La première, apprise à répétition :
  **avant de déclarer un événement, vérifier que le référentiel n'a pas
  bougé.**
