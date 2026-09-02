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
— 12 930 km² au niveau cantonal, 3 945 au niveau des atomes. Les compter
ensemble reviendrait à s'attribuer une dette qu'aucun travail de dessin ne peut
rembourser. Le panneau les compte séparément ; cliquer sur le polygone dit
lequel des deux cas s'applique et pourquoi.

> **Et le second des deux a presque disparu.** Depuis le 1ᵉʳ septembre 2026, la
> trame datée d'ANR ramène le recouvrement entre communes distinctes de
> **3 945 km² à 101,0** — le bleu croisé, l'artefact de la correspondance vers
> GEOFLA. Résidu nommé : Notre-Dame-de-Briançon 93,6 km², Tours 6,9. **L'ocre
> penché, lui, ne bouge pas** : ANR livre le polygone de la commune-mère entière
> et ne sait pas la découper entre deux cantons. Les 333 fractions restent à
> tracer, et c'est toujours le chantier de `BASE_POUR_QGIS.md`.
>
> Gain non cherché : **l'empreinte de regroupement devient datée.** Deux atomes
> que la trame de 2011 confondait sous un même polygone peuvent en avoir deux
> distincts en 1870 — c'est précisément le mécanisme qui fait tomber le
> recouvrement, et la carte le montre maintenant commune par commune.

**Le regroupement passe par l'empreinte du polygone, jamais par le code
INSEE** — même règle que `cartes_cantons.py` : « un code est une reconstruction,
l'empreinte est un fait ». Elle est nécessaire dans les deux sens : Lyon et
Marseille portent des codes différents pour un même terrain
(`atom_geom.source = 'union_prefixe'`), et trois communes fondues portent un
code identique pour trois noms. Un polygone contesté est donc dessiné une fois
et porte tous les noms qui le revendiquent, empilés.

## Ce que la page montre — et ce qu'elle refuse de montrer

**Le curseur va de 1815 à 2012, la base non.** Elle tient une composition
cantonale en 1870-1940, **1954, 1968, et de façon inégale de 1969 à 1999**, puis
1999-2012 ; une composition électorale en 1870-1940, 1986-2010 et 2010-2012.

> **Mise à jour du 2 septembre 2026.** Ce paragraphe disait « le trou cantonal
> 1941-1998 » comme d'un vide. Il ne l'est plus : les jalons de recensement
> (`59`, `68`), le registre des actes et les deux reports (`79`, `81`) y ont
> posé des rattachements — `snapshot(1990)` rend 23 233 lignes contre ~1 069
> avant le chantier. **Ce n'est pas une carte complète** — de l'ordre de 1 200
> cantons sur 4 000 à certaines dates — et surtout, **une bonne part de ces
> dates est une convention, pas un fait** : toute lecture des cantons entre 1985
> et 1998 doit joindre `p76_qualite`, dont 93,7 % des lignes sont marquées
> incertaines. La page doit le dire ; vérifier qu'elle le dit.

Partout où la base n'a rien — avant 1870, et sur ce qui reste creux entre les
jalons — la page affiche un contour départemental grisé, emprunté à l'année
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

> **Réécrit le 1ᵉʳ septembre 2026.** La phrase qui tenait toute l'architecture
> de `export_web.py` — *« la géométrie d'un atome ne bouge jamais »* — est
> devenue fausse avec `atom_geom_anr`, la trame communale datée d'ANR-COMMUNES.
> Brancher la nouvelle source sans toucher au reste aurait produit une carte qui
> se trompe **en silence** : deux années de même composition mais de formes
> différentes auraient partagé le même fichier, et une édition de polygone
> tombant une année sans mouvement administratif n'aurait jamais été
> échantillonnée. *Une borne qu'on n'interroge pas ne produit pas une erreur,
> elle produit un silence.*

Le script repère les *configurations* distinctes et n'écrit un fichier que par
configuration, avec un index année → configuration. Un département de 1870 à
1940 en compte quelques-unes, pas soixante-et-onze.

Ce qui a changé avec la trame datée :

* **`communes.json` porte, par atome, une liste de versions** `v: [{a, k, c, g,
  r}]` — `a` la première année où la version vaut, `g` sa géométrie, `r` le
  drapeau de repli. Un intervalle sans géométrie s'écrit **comme vide**
  (`g: null`) et la commune n'est pas dessinée : sauter l'intervalle laisserait
  le polygone précédent à l'écran, puisque la page tient la version en vigueur
  jusqu'à la suivante. *Ne rien écrire n'est pas neutre quand le lecteur en aval
  prolonge.*
* **La signature couvre la composition ET les `poly_id` en vigueur**, et
  `annees_candidates()` lit une troisième famille de bornes — celles d'ANR — en
  plus de `membership` et `unit_version`.
* **Le nom de fichier est le md5 du contenu sérialisé**, pas de la signature
  d'entrée. Celle-ci est conservatrice : une commune qui perd un hameau au
  profit d'une voisine du *même* canton change de `poly_id` sans déplacer le
  contour cantonal d'un pouce, et signer sur l'entrée écrivait deux fichiers
  identiques sous deux noms. *Une signature d'entrée dit ce qu'il faut
  recalculer, une signature de sortie ce qu'il faut réécrire.*
* **Le repli est écrit, pas subi.** Chaque version porte `r`, chaque unité porte
  `n_anr` et `n_repli`, et la page affiche séparément l'export sans épaisseur,
  les communes en repli à cette année, et celles qu'aucune source ne sait
  dessiner. Une carte hybride qui ne dit pas où elle est hybride ment par
  omission.
* **`--jobs N`** : un processus par département, la connexion ouverte *après* le
  fork (contexte `spawn`). Le découpage s'arrête au département parce que c'est
  la seule unité qui écrive dans un dossier à elle. Un département qui échoue
  rend son erreur comme une donnée et le script sort en 1 — *un export incomplet
  qui ressemble à un export complet serait pire qu'un export absent.*

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
donnees/dep/NN/communes.json        atomes, chacun avec sa LISTE DE VERSIONS
donnees/dep/NN/c_<sig>.json         une configuration cantonale
donnees/dep/NN/x_<sig>.json         une configuration électorale
donnees/dep/NN/contours.json        emprises de référence, pour les années vides
```

`<sig>` est le md5 du **contenu** du fichier, pas de ce qui l'a engendré.

## Recettes

* **`cartes/banc_export_web.py`** couvre les fonctions pures : construction des
  versions, convention du 1ᵉʳ décembre, forme des requêtes. Il vérifie en
  particulier que les trois requêtes — atomes, cantons dissous, circos dissoutes
  — partagent une **expression unique**,
  `ST_MakeValid(ST_SnapToGrid(coalesce(ga.geom, ag.geom), grille))`. Avec une
  trame datée il ne suffit plus d'appliquer le même *ordre* d'opérations des
  deux côtés : il faut la même **source**, sinon un canton dessiné sur la forme
  d'ANR longerait des communes dessinées sur la forme de 2011 et la lisière
  serait un artefact de tuyauterie. Le banc contrôle cette identité sur le
  **texte** des requêtes — la seule chose qu'un banc hors base puisse en dire.
* Le banc de fumée montre, sur un cas fabriqué, **six compositions calculées
  pour deux fichiers écrits** : la signature de sortie fait son travail.
* Deux recettes plus anciennes, écrites en l'absence de PostGIS : le SQL contre
  un PostgreSQL doté de doublures des fonctions ST_*, sur un jeu reproduisant
  les discontinuités réelles ; et la page dans un DOM sans navigateur, sur deux
  départements fabriqués au Voronoï — sept scénarios, zéro erreur.

**Ce qu'aucune ne prouve, et qui ne se verra qu'après un export réel complet** :

1. le **poids** — la signature élargie multiplie les configurations. Attendu :
   92 Mo → deux à trois fois plus sur le disque, sans changement du coût par
   requête, les fichiers restant adressés par contenu ;
2. la **coïncidence visuelle** des limites cantonales et communales sur une
   année où ANR édite un polygone. C'est là, et seulement là, que se verrait une
   erreur d'ordre d'opérations ;
3. que `ST_UnaryUnion` dissout correctement sur les vraies géométries. C'est
   PostGIS qui en répond.
