# Carte interactive — communes, cantons, circonscriptions, 1815-2012

Une page à curseur d'années et sélecteur de département. Trois niveaux
superposés : les communes en trait fin, les cantons en trait moyen sur fond
colorié, les circonscriptions législatives en trait épais.

## Marche à suivre

```bash
python3 cartes/export_web.py        # tous les départements ; --dsn pour une autre base
python3 cartes/web/servir.py        # ouvre http://127.0.0.1:8765/index.html
```

Ouvrir `index.html` par un double-clic ne peut pas marcher : la page charge ses
données par `fetch()`, et les navigateurs refusent la requête sur `file://`.
`servir.py` sert le dossier et compresse le JSON à la volée.

Options utiles :

| commande | effet |
|---|---|
| `export_web.py 01 13 69` | n'exporte que ces départements |
| `export_web.py --grille 50` | quantification plus grossière, fichiers plus légers |
| `export_web.py --dsn "dbname=histgis host=…"` | base autre que la locale |
| `servir.py 9000 --sans-navigateur` | autre port, sans ouvrir de fenêtre |

Dans la page : flèches ← → pour avancer d'un an, molette pour zoomer, glisser
pour déplacer, clic sur une commune pour l'épingler dans le panneau, `#01/1885`
dans l'URL pour pointer une planche précise.

## Le curseur ne va pas de 1815 à 2012 partout

Il se borne au premier et au dernier millésime que la base sert pour le
département affiché — le libellé du sélecteur les rappelle. Le **99** (la
Meurthe d'avant 1871, que TRF-GIS code ainsi faute de code INSEE) n'ouvre
qu'une seule année ; la Moselle et les deux Rhin s'arrêtent en 1871 et
reprennent en 1919.

Cette dernière coupure n'est pas un trou de la base, et la page ne les affiche
pas pareil. **Deux silences se ressemblent et ne veulent pas dire la même
chose** : la base qui n'a rien à dire, et le territoire qui n'est pas français.
Le bandeau distingue « aucune source pour 1965 » de « pas de département à
cette date (1871-1918) — annexé à l'Empire allemand ». Confondre les deux
reviendrait à s'accuser d'une lacune qu'on n'a pas. Les périodes d'annexion
apparaissent hachurées dans la jauge, les motifs sont déclarés en tête de
`export_web.py` : ce sont des affirmations historiques datées, à contredire si
elles sont fausses.

## Noms de communes

Le nom vient de `noms_geofla`, à défaut de `geofla_commune.nom_comm`. Il paraît
dans l'infobulle, dans la fiche au clic, et en étiquettes quand le zoom est
assez fort — au-delà, trois cent quarante étiquettes se recouvrent et ne disent
plus rien ; les communes trop petites pour porter la leur restent muettes.

**C'est un nom de 2011, donc possiblement anachronique** sur une planche de
1885. La page le dit dans la fiche. La base ne tient pas de nom communal
d'époque : `insee_mvt.libelle_av` le donnerait pour les disparues, c'est un
chantier ouvert dans `RESTE_A_FAIRE.md`.

**Le nom suit le curseur.** `insee_mvt` porte 1 388 changements de nom
(`mod = '10'`), datés. Pour une planche de 1885, la chronologie rend le nom le
plus ancien *connu* — celui d'avant le premier renommage enregistré — là où les
planches PDF affichent celui de 2011. Ce n'est pas la vérité, et la fiche le
dit : le fichier de l'Insee commence en 1943, un renommage de 1900 reste
invisible.

## Les deux recouvrements, qui ne demandent pas le même travail

Un même polygone revendiqué par plusieurs cantons recouvre deux situations très
différentes, et la carte les distingue :

| aspect | situation | à faire |
|---|---|---|
| **ocre penché** | un seul code Cassini, plusieurs cantons — la commune d'époque est réellement coupée, la base n'en tient pas le tracé interne (Marseille, Lyon, Bourg-en-Bresse) | **tracer**, sur la trame IRIS |
| **bleu croisé** | plusieurs codes Cassini — des communes d'époque distinctes, fondues depuis, qui partagent un polygone de 2011 (Espinouse, Saint-Jurson et Le Chaffaut sur 29,75 km²) | **rien** : artefact de la correspondance vers GEOFLA |
| **liseré pointillé** | plusieurs communes d'époque, même canton | rien : noms superposés, pas de recouvrement |

Ce sont les deux défauts que le projet mesure séparément depuis le contrôle Gay
— 12 822 km² au niveau cantonal, 3 945 au niveau des atomes. Les compter
ensemble reviendrait à s'attribuer une dette qu'aucun travail de dessin ne peut
rembourser. Le panneau les compte séparément ; cliquer sur le polygone dit
lequel des deux cas s'applique et pourquoi.

**Le regroupement passe par l'empreinte du polygone, jamais par le code
INSEE** — même règle que `cartes_cantons.py` : « un code est une reconstruction,
l'empreinte est un fait ». Elle est nécessaire dans les deux sens : Lyon et
Marseille portent des codes différents pour un même terrain
(`atom_geom.source = 'union_prefixe'`), et trois communes fondues portent un
code identique pour trois noms. Un polygone contesté est donc dessiné une fois
et porte tous les noms qui le revendiquent, empilés.

## Ce que la page montre — et ce qu'elle refuse de montrer

**Le curseur va de 1815 à 2012, la base non.** Elle tient une composition
cantonale en 1870-1940 et 1999-2012, une composition électorale en 1870-1940,
1986-2010 et 2010-2012. Partout ailleurs — avant 1870, et dans le trou cantonal
1941-1998 — la page affiche un contour départemental grisé, emprunté à l'année
datée la plus proche et **annoncé comme emprunté**, sous un bandeau qui dit
qu'il n'y a pas de source. Rien n'est reporté, rien n'est interpolé. La jauge
sous le curseur donne d'un coup d'œil les années servies : vert pour une
composition cantonale, ocre pour une composition électorale, vert foncé pour
les deux.

C'est le parti pris du projet, pas une limitation de la page : « le trou se
voit dans les données » (`ETAT.md`). Une carte pleine partout laisserait croire
à une connaissance continue qu'on n'a pas.

**Les communes partagées entre plusieurs cantons sont hachurées.** Marseille,
Lyon, Paris, Bourg-en-Bresse et une centaine d'autres portent en base le
polygone de la commune entière : leurs cantons se recouvrent exactement. Les
colorier reviendrait à trancher un découpage qui n'existe pas dans la trame. Le
panneau de droite en donne le compte département par département, et l'infobulle
le dit commune par commune.

**Une circonscription sans territoire est signalée comme telle**, pas omise :
15 des 539 de 2009 et 1 des 534 de 1986 sont composées exclusivement de
fractions que la trame ne peut pas porter.

## Comment c'est fabriqué

`export_web.py` ne réécrit pas la géométrie année par année. La géométrie d'un
atome ne bouge jamais : elle sort une fois dans `communes.json`. Ce qui bouge,
c'est le rattachement — et il ne bouge que quelques fois par période. Le script
repère les *configurations* distinctes (md5 de la composition, noms d'époque
compris) et n'écrit un fichier que par configuration, avec un index année →
configuration. Un département de 1870 à 1940 en compte quelques-unes, pas
soixante-et-onze.

Les coordonnées sont accrochées à une grille métrique en Lambert-93
(`ST_SnapToGrid`, 25 m) **avant** reprojection, et les contours dissous
subissent les mêmes opérations dans le même ordre. Ce n'est pas une
simplification : `ST_SimplifyPreserveTopology` appliqué polygone par polygone
écarterait deux communes voisines et ouvrirait des lisières entre elles. Avec
l'accrochage, deux communes qui partageaient un sommet le partagent encore, et
les limites cantonales coïncident avec les limites communales qu'elles suivent.

## Arborescence produite

```
donnees/index.json                  départements, noms d'époque, années servies
donnees/dep/NN/index.json           année → signature de configuration
donnees/dep/NN/communes.json        géométrie des atomes (une seule fois)
donnees/dep/NN/c_<sig>.json         une configuration cantonale
donnees/dep/NN/x_<sig>.json         une configuration électorale
donnees/dep/NN/contours.json        emprises de référence, pour les années vides
```

## Recettes

Deux passées, en l'absence de PostGIS dans l'environnement de rédaction :

* le SQL du script a tourné contre un vrai PostgreSQL doté de doublures des
  fonctions ST_*, sur un jeu d'essai reproduisant les discontinuités réelles
  (trou 1941-1998, circos sans cantons en 1986-1998, un transfert de commune en
  cours de période, un renommage de canton). Dédoublonnage, trous, noms
  d'époque et drapeau `partagee` sont contrôlés ;
* la page a tourné dans un DOM sans navigateur sur deux départements fabriqués
  au Voronoï, unions faites par shapely : sept scénarios rendus, zéro erreur.

Ce qu'aucune des deux ne prouve : que `ST_UnaryUnion` dissout correctement sur
les vraies géométries. C'est PostGIS qui en répond, et la vraie base qui le
dira au premier export.
