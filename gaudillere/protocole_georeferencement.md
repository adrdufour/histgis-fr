# Protocole — géométries cantonales de Marseille, 1870-1940

But : donner à chacun des atomes-fractions de Marseille son vrai polygone, à la
place du polygone de la ville entière qu'ils partagent tous aujourd'hui.

## Ce que la base porte, et ce que ça coûte

| date | fractions | polygone porté | double comptage |
|---|---|---|---|
| 1870 | 6 | 235,22 km² chacune | **1 176 km²** |
| 1900 | 8 | 235,22 km² chacune | **1 647 km²** |
| 1940 | 12 | 235,22 km² chacune | **2 587 km²** |

Les douze atomes `21387#1313` à `21387#1324` portent **une seule et même
géométrie**. Marseille est à elle seule le premier poste du double comptage
mesuré par `12_conflit_successeur.sql`.

## Trois configurations suffisent

La base couvre 1870-1940, donc seules trois cartes servent :

| configuration | cantons | unit_id |
|---|---|---|
| 1870-1886 | 6 | 1313 à 1318 |
| 1886-1901 | 8 | 1313 à 1320 |
| 1901-1940 | 12 | 1313 à 1324 |

Les `membership` de la base se coupent **exactement** à 1886-01-01 et
1901-01-01 — les lois du 13 juillet 1886 et du 19 juin 1901, arrondies au 1er
janvier de leur propre année selon la convention annuelle de TRF-GIS. **L'atlas
et la source concordent**, ce qui est une confirmation de plus avant de
dessiner quoi que ce soit.

## Douze polygones, pas vingt-six

On pourrait croire qu'il faut un polygone par canton et par configuration, soit
26. C'est inutile, et la raison tient à l'architecture du projet : **géométrie
et attribution sont découplées**. Un atome a une géométrie fixe et un
rattachement qui varie dans le temps.

Les divisions de 1886 et 1901 étant cumulatives — elles ajoutent des lignes
sans en effacer —, leur superposition est la division la plus fine, celle de
1901 : **douze cellules**. Chaque cellule a une emprise stable sur toute la
série ; ce qui change en 1886 et en 1901, c'est le canton dont elle relève. Et
c'est précisément ce que `membership` sait porter.

Ces douze cellules sont les douze atomes qui existent déjà. Il n'y a donc rien
à créer : on remplace leur géométrie et on recalcule leurs rattachements
antérieurs — car la cellule qui est le 1er canton en 1901 relevait d'un autre
canton en 1870, et la base dit aujourd'hui le contraire.

---

## La méthode : découper, ne pas tracer

Le piège du géoréférencement est de tracer chaque canton séparément. On obtient
alors des bords qui ne coïncident pas — échardes, trous, unions qui ne font pas
la commune — et il faut passer des heures à nettoyer la topologie.

**Ne dessine que les lignes de division interne.** Le contour extérieur, nous
l'avons déjà : c'est le polygone GEOFLA de Marseille, exact au décamètre. Les
cantons s'en déduisent en le découpant.

Trois bénéfices immédiats. L'union des cantons vaut **exactement** la commune,
par construction. Le contour extérieur garde la précision de GEOFLA, et seules
les lignes internes portent l'imprécision de l'atlas. Et le travail de saisie
est divisé par trois ou quatre.

### Étape 1 — géoréférencer

Dans QGIS, géoréférencer chaque cliché sur le contour communal, que l'atlas
dessine et que nous avons en base :

```sql
-- exporter le contour de Marseille comme repère
COPY (SELECT ST_AsText(ST_Boundary(geom)) FROM histgis.atom_geom
      WHERE atom_id = '21387')
  TO '/tmp/marseille_contour.wkt';
```

Huit à douze points d'appui suffisent, pris sur des saillants nets du littoral
et des limites communales — les calanques au sud, la pointe nord-ouest vers
l'Estaque, les rentrants à l'est vers Allauch. Transformation polynomiale de
degré 1 ou 2 ; au-delà, on déforme pour masquer les défauts du dessin plutôt
que pour corriger la prise de vue.

**Noter l'erreur résiduelle moyenne** affichée par QGIS : c'est elle qu'il
faudra déclarer.

### Étape 2 — numériser les lignes internes

**Une seule couche de lignes**, cumulant les trois configurations, avec deux
champs :

| champ | contenu |
|---|---|
| `config` | `1870`, `1886` ou `1901` — la configuration où la ligne apparaît |
| `note` | libre — la voie suivie, si elle est identifiable |

Le champ `config` est documentaire : le découpage se fait avec toutes les
lignes à la fois. Il sert à relire et à corriger.

Ne trace **que** ce qui sépare deux cantons. Les lignes doivent dépasser
légèrement du contour communal des deux côtés : le découpage n'en sera que plus
propre.

En pratique cinq lignes pour 1870, deux de plus en 1886, quatre de plus en
1901 — soit **onze lignes en tout**, et non trois cartes complètes.

### Étape 3 — étiqueter les cellules

Une couche de points, **un point par cellule finale**, soit douze, posé à
l'intérieur :

| champ | contenu |
|---|---|
| `u1870` | le canton dont cette cellule relève en 1870-1886 |
| `u1886` | idem pour 1886-1901 |
| `u1901` | idem pour 1901-1940 |

Les trois champs sont obligatoires : toute cellule relève d'un canton à chacune
des trois dates. C'est cette table qui porte l'histoire — `u1870` et `u1886`
sont ce qui permet de reconstituer les divisions anciennes sans dessiner une
seule ligne de plus.

Attention à la renumérotation de 1886, que l'atlas signale : le 1er canton
devient le 3ème et réciproquement. `u1870` et `u1901` d'une même cellule
peuvent donc différer sans qu'aucune limite n'ait bougé.

### Étape 4 — livrer

Un GeoPackage `gaudillere/marseille_cantons.gpkg` en **EPSG:2154**, deux
couches : `lignes` et `etiquettes`. `sql/32_marseille_geom.sql` fait le reste —
découpage, vérifications, ingestion.

---

## Ce qu'il faudra déclarer, et pourquoi

Les cartes de l'atlas sont **schématiques** : dessins de synthèse à petite
échelle, pas des levés. La précision attendue est de l'ordre de la **centaine
de mètres** sur les lignes internes — à confirmer par l'erreur résiduelle du
géoréférencement.

Ce chiffre devra figurer dans `METHODE.md` au même titre que les 3 945 km² de
recouvrement, et sur toute carte publiée. La règle du projet ne change pas :
une géométrie reconstruite se déclare avec sa précision, sinon elle se fait
passer pour une mesure.

Deux limites qui ne se lèveront pas :

- **Deux cantons de 1801 n'ont aucune limite propre** dans le texte de l'atlas
  — le 3ème (« entre 1er et 3ème cantons », coquille) et le 6ème (« Est du
  4ème, Nord du 5ème »). Leurs contours ne viendront que de la carte, sans
  contrôle textuel possible.
- **L'auteur reconnaît avoir reconstruit** la ligne de division de 1876
  « approximativement », à partir de procès-verbaux d'élection. Le mot est de
  lui.

## Ce que ça rapportera, une fois fait

Marseille cesse d'être le premier poste du double comptage : 1 176 km² en 1870
et 2 587 en 1940 disparaissent du total. `12_conflit_successeur.sql` et
`controle_gay.sh` le mesureront avant/après, comme pour tout correctif de ce
projet — et le contrôle Gay dira si les cantons ainsi obtenus tombent où Gay
les met, ce qui est le seul jugement qui vaille.
