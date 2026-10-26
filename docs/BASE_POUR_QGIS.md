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

### `atom_geom_anr` — la trame **datée**, depuis le 1ᵉʳ septembre 2026
| colonne | |
|---|---|
| `atom_id`, `poly_id` | |
| `periode` | `daterange` — un polygone par atome **et par date**, garanti par contrainte |
| `geom` | `geometry(MultiPolygon, 2154)` |

45 113 polygones, 38 074 atomes pourvus, trame ANR-COMMUNES 1790-2020. Se lit par
`snapshot_geom_anr(date, niveau)`, qui **retombe sur `atom_geom`** là où ANR ne
dit rien et le signale (`n_anr`, `n_repli`).

**Ce qu'elle change pour une carte** : le recouvrement entre communes distinctes
passe de **3 945 km² à 101,0** à 1870. Mais `atom_geom` reste intacte avec ses
3 945 — **ce qui lit `atom_geom` directement voit toujours l'ancienne valeur.**
Pour une carte au zoom urbain, préférer `snapshot_geom_anr()`.

Ce qu'elle ne change **pas** : les 333 fractions. ANR livre le polygone de la
commune-mère entière et ne sait pas la découper entre deux cantons. **Le chantier
décrit ici reste entier.**

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
  AND  g.source <> 'fraction_cog'        -- ← INDISPENSABLE, voir ci-dessous
GROUP  BY 1, 2
HAVING count(*) > 1;
```

**Résultat attendu : 119 communes, 214 coupes.** Dont 81 communes à une seule
coupe, 16 à deux, 13 à trois ; Lyon en demande 12 et Marseille 11.

> **Correctif du 15 août 2026.** La quatrième condition manquait. Sans elle la
> requête rend **environ 312 communes** et non 119 : elle ramasse les communes
> partagées d'après 1943, dont les atomes-fraction portent eux aussi un `#` et
> `fraction = true`. Le paragraphe « À ne pas confondre » ci-dessous décrivait
> déjà le piège — la requête, elle, n'en tenait pas compte. Une prose juste
> au-dessus d'une requête qui la contredit est pire qu'un silence : elle
> autorise à ne pas vérifier.
>
> Cas concret : **Bourg-en-Bresse (01053) n'est PAS dans les 119.** Ses trois
> fractions sont posées par `24_canton_moderne.sql`, elle appartient au bloc
> moderne. `cartes/couverture_cantons_2025.csv` la classe bien
> `moderne (1943-2012)`.

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

Nuance depuis ANR : sur `atom_geom_anr`, **l'empreinte de regroupement devient
datée** — deux atomes que la trame de 2011 confondait peuvent en avoir deux
distincts en 1870. C'est précisément le mécanisme qui fait tomber le recouvrement
de 3 945 à 101 km². La règle ne change pas, son résultat oui.

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

* `archives/planches/cartes_cantons.py` produit déjà des planches A3 par département
  (1870, 1940, 1999, et 2025 avec `--2025`). Il **hachure en rouge** les
  communes revendiquées par plusieurs cantons : c'est la convention établie du
  projet, à réutiliser.
* `docs/gaudillere/protocole_georeferencement.md` décrit comment digitaliser les
  coupes de Marseille — onze lignes internes pour 1870, 1886 et 1901. C'est le
  cas d'école du chantier.
* `ETAT.md` donne l'état de chaque couche, `RESTE_A_FAIRE.md` § 2 le détail de
  ce chantier et ses blocages.
* `METHODE.md` porte les règles du projet, **indexées au § 10**. La première,
  apprise à répétition : *avant de déclarer un événement, vérifier que le
  référentiel n'a pas bougé.* Les plus utiles ici sont les § 14.1 (interroger un
  atome ne renseigne pas sur un territoire), § 14.2 (grouper par la géométrie) et
  § 14.6 (un identifiant d'atome n'est pas un code INSEE) et § 14.7 (les grandes
  villes codées par arrondissement).
