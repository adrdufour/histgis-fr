# Registre des mouvements cantonaux, 1941-1998

Fichier : `cantons/mouvements_cantonaux.csv`

## Pourquoi ce registre

Le trou cantonal 1941-1998 est le dernier blocage structurel du projet. TRF-GIS
s'arrête en 1940, le COG ne descend au canton qu'à partir de 1999, et la source
n'a livré que 66 événements MOD-43, tous entre 1995 et 1998. Entre les deux,
rien.

Ce registre comble l'intervalle par saisie manuelle, département par
département.

## Ce registre n'est pas une table de faits, c'est une table de dates

Il avait été conçu pour saisir à la main les mouvements cantonaux, département
par département. **L'Ain a montré que la saisie était inutile.**

La base porte déjà le rattachement cantonal de chaque commune en 1940
(TRF-GIS) et en 1999 (COG). Les `unit_id` sont partagés entre les deux couches,
le code Insee fait le pont, et le différentiel se calcule :
`sql/33_diff_cantonal.sql`, paramétré par département.

Ce que la machine ne sait pas produire, c'est la **date**. Le registre ne
consigne donc plus des événements dictés, mais les bornes temporelles
d'événements calculés.

### Ce que le calcul voit et que la dictée ne voyait pas

Sur le seul département de l'Ain, trois classes entières :

- **Les transferts** — une commune qui passe d'un canton ancien à un autre,
  sans qu'aucun canton ne naisse ni ne disparaisse. Quatre cas. Ni la lecture
  des cartes ni aucune remontée depuis 1999 ne les révèlent.
- **Les partages** — un chef-lieu réparti entre plusieurs cantons. Bourg-en-
  Bresse relève de trois cantons en 1999, Oyonnax de deux. La dictée comptait
  Bourg pour un seul démembrement.
- **La distinction fusion / mouvement cantonal**, que le seul comptage des
  effectifs confondait : quatorze cantons de l'Ain perdent des communes sans
  qu'aucune limite cantonale n'ait bougé.

### La leçon du partage

Une commune partagée entre plusieurs cantons est indistinguable, dans une
jointure sur le code Insee, d'une commune qui déménage : elle apparaît dans
deux cantons et la jointure y lit un départ. C'est le double comptage de
Marseille transposé du niveau géométrique au niveau du rattachement.

Rien ne l'aurait signalé sans la **recette d'équilibre** du § 6 de `33` — pour
chaque canton, effectif de 1940 moins les partis plus les arrivés doit valoir
l'effectif de 1999. Elle a sorti deux lignes en négatif, exactement les deux
chefs-lieux partagés.

Sur 90 départements, la confusion aurait fabriqué un faux démembrement dans
chaque chef-lieu divisé.

### Ce que ni le calcul ni les cartes ne donnent

La date des transferts. Une commune isolée qui change de canton ne déplace
aucune limite de circonscription, donc l'atlas ne la montrera jamais. Ces
lignes restent en `certitude = inconnue` sur tout l'intervalle 1940-1999, et le
resteront sans les décrets. À déclarer comme telles plutôt qu'à rattacher au
redécoupage le plus proche.

## Le schéma

| colonne | contenu |
|---|---|
| `dep` | code département sur deux caractères, `01`, `2A`… |
| `type` | `demembrement`, `fusion`, `renommage`, `transfert`, `stabilite` |
| `date_debut` | début de l'intervalle où l'événement a pu se produire |
| `date_fin` | fin de cet intervalle |
| `date_retenue` | la date posée en base — vide pour `stabilite` |
| `certitude` | `acte` (décret daté), `carte` (observation d'atlas), `borne_sup` (l'événement est survenu **au plus tard** à `date_fin`) |
| `canton_source` | le ou les cantons d'origine, séparés par `;` |
| `cantons_resultants` | **tous** les cantons issus, séparés par `;`, y compris celui qui garde le nom |
| `source` | d'où vient l'information |
| `remarque` | libre |

### Une date d'atlas est une borne, pas une date

L'atlas Gaudillère cartographie des **circonscriptions législatives**, pas des
cantons. Un canton n'y apparaît que lorsqu'il sert à délimiter une
circonscription : créé en 1872 mais sans rôle avant 1876, il se lira « créé en
1876 ».

Une observation d'atlas ne date donc pas un événement, elle établit qu'il était
**accompli au plus tard** à la date de la carte. La date réelle se situe entre
la carte précédente et celle-ci — d'où `date_debut` et `date_fin`.

Les cartes se succèdent par découpage, non par élection. Pour la période qui
nous intéresse : …1928-1940, **1945-1958**, **1958-1986**, **1986**. Un
mouvement observé sur la carte de 1986 a donc pu survenir n'importe quand
depuis 1958. **Vingt-huit ans d'incertitude**, qu'il serait malhonnête de
masquer derrière une date unique.

### Ce que cette imprécision coûte, et ce qu'elle ne coûte pas

Elle ne coûte **rien à la couche circonscriptions**, qui est le but. Une
circonscription se définit par cantons à la date de son découpage, et c'est
exactement à ces dates-là que l'atlas donne la composition. Les bornes tombent
sur les mêmes charnières que le besoin.

Elle coûte à la **couche cantonale interrogée à une date quelconque**. Demander
les cantons de l'Ain au 1er janvier 1975 renverra la composition de 1958, avec
une incertitude déclarée : quatre démembrements ont pu déjà avoir eu lieu. Cette
incertitude doit être lisible en base, pas seulement dans cette note.

Un décret retrouvé lève la borne et fait passer la ligne de `borne_sup` à
`acte`. C'est le seul moyen de resserrer, et il se fait ligne par ligne.

### `stabilite` : l'absence de changement est une information

« Pas d'autres modifications jusqu'à 1815 » n'est pas une absence de données,
c'est une affirmation positive, et elle vaut autant que les événements. Sans
elle, un intervalle vide serait indistinguable d'un intervalle non dépouillé.
Ces lignes portent `date_eff` et `date_fin`, et rien d'autre.

### Plusieurs cantons sources : la remontée casse

Un canton issu de **deux** parents brise la règle. Si B sort de A₁ et A₂, on
sait que ses communes venaient de l'un ou de l'autre, mais pas lesquelles — et
le COG 1999 ne le dira pas. Ces lignes demandent une liste nominative de
communes, ou restent indéterminées.

C'est le cas de Villars en 1876, sans conséquence ici : 1876 tombe dans la
couverture de TRF-GIS, qui porte déjà la réponse.

Deux conventions qui évitent les pièges :

**`cantons_resultants` contient le survivant.** « Miribel créé à partir de
Montluel » s'écrit source `Montluel`, résultants `Miribel;Montluel`. Sans quoi
la règle de remontée ne saurait pas que Montluel fait partie de l'ensemble à
réunir.

**`certitude` est une colonne, pas un commentaire.** Une date d'année posée au
1er janvier doit rester distinguable d'une date de décret. Le projet ne mélange
pas ce qu'il sait et ce qu'il approche.

## Ce qui est saisi

### Ain (01) — complet de 1815 à 1986

| intervalle | événement |
|---|---|
| 1815-1876 | stable |
| ≤ 1876 | **Villars** apparaît, aux dépens de Saint-Trivier-sur-Moignans **et** Chalamont |
| 1876-1945 | stable |
| 1945-1958 | **Châtillon-de-Michaille** renommé **Bellegarde** — nom seul |
| 1958-1986 | **Oyonnax** → Oyonnax-Nord, Oyonnax-Sud (le nom source disparaît) |
| 1958-1986 | **Montluel** → Miribel, Montluel |
| 1958-1986 | **Reyrieux** → Trévoux, Reyrieux |
| 1958-1986 | **Bourg-en-Bresse** → Viriat, Péronnas, Bourg-en-Bresse |

**Ce que ça règle.** Entre 1876 et 1958, l'Ain ne connaît aucune modification
cantonale, et le seul mouvement suivant est un changement de nom. La
composition que TRF-GIS donne pour 1940 vaut donc telle quelle jusqu'au
découpage de 1958, et le COG 1999 prend le relais après 1986. **Le trou
1941-1998 se ferme pour ce département**, sans qu'aucune géométrie soit à
reconstruire : il n'y a rien eu à reconstruire.

Reste une zone grise de 1958 à 1986, où l'on sait *ce qui* s'est produit mais
pas *quand*. C'est une incertitude, pas un trou.

C'est le premier département traité. Si la situation se répète, l'ampleur du
blocage était très surestimée.

**Le cas Villars, résolu sans défaut de source.** TRF-GIS porte Villars dès
1870, l'atlas ne le montre qu'en 1876. Les deux sont vrais : un canton peut
exister sans servir de limite de circonscription. Il n'y a rien à corriger — et
c'est justement pourquoi une date d'atlas ne doit jamais être lue comme une
date de création.

**Trois doutes à lever :**

- Trévoux est un chef-lieu nettement plus ancien que Reyrieux, et le sens
  attendu serait plutôt Trévoux → Reyrieux. La saisie dit l'inverse.
- Le nom de 1958 est-il *Bellegarde* ou *Bellegarde-sur-Valserine* ?
- « Saint-Trivier » : le département en a deux. Villars-les-Dombes étant en
  Dombes, sur-Moignans est retenu — à confirmer sur la carte.

### Aisne (02) — et le premier intervalle resserré

Cinq démembrements, trois partages, deux transferts. Les cinq cantons neufs —
Laon-Sud, Saint-Quentin-Nord et Sud, Soissons-Sud, Tergnier — figurent tous sur
la carte de 1986, donc `[1958, 1986]`.

### Ce que l'atlas peut dire, et ce qu'il ne peut pas

Un resserrement avait été tiré d'une lecture fine : **Missy-aux-Bois est dans
Vic-sur-Aisne sur la carte de 1986 alors que Soissons-Sud existe déjà**, d'où un
intervalle `[1986, 1999]` au lieu de `[1958, 1999]`.

**Ce resserrement a été retiré**, et la raison vaut pour tout le reste.

Quatre communes de l'Aisne relevées sur la carte des circonscriptions de 1876
sont, dans l'atlas, dans un canton **limitrophe** de celui que porte TRF-GIS :

| commune | atlas 1876 | TRF-GIS 1876 | circonscription |
|---|---|---|---|
| Samoussy | Laon | Sissonne | Laon-1 |
| Martigny-Courpierre | Laon | Craonne | Laon-1 |
| Marigny-en-Orxois | Charly | Château-Thierry | Château-Thierry |
| Loupeigne | Fère-en-Tardenois | Oulchy-le-Château | Soissons |

Les **circonscriptions concordent** dans les quatre cas. Les deux sources
décrivent donc le même découpage électoral, en passant par des cantons
différents. L'explication la plus simple est que le fond cantonal de l'atlas
n'est pas du millésime de la planche qu'il porte : un auteur compose rarement
un fond neuf pour chaque carte.

Trois conséquences, dont une désagréable :

1. **L'atlas n'est pas un contrôle utilisable sur la couche cantonale
   ancienne.** Ce qu'on croyait être la première source externe sur les cantons
   1870-1940 n'en est pas une.
2. **Il reste un contrôle sur la couche circonscriptions**, où il concorde — et
   c'est là qu'on en avait le plus besoin.
3. **Toute lecture commune-vers-canton de l'atlas est suspecte**, y compris
   celle de Missy-aux-Bois. Son intervalle est rendu à `[1940, 1999]`.

Ce que l'atlas continue de dire de façon fiable : **quels cantons existent** à
la date d'une carte. C'est une information de nomenclature, pas
d'appartenance — et c'est elle qui borne les démembrements à `[1958, 1986]`.
Ces bornes-là tiennent.

Reste acquis, indépendamment de l'atlas : la création d'un canton et l'arrivée
d'une commune dans ce canton sont **deux événements distincts**, que `33`
sépare et qu'il ne faut pas dater d'un seul coup.

### Le trou 1941-1998 avale aussi des communes entières

`sql/34_orphelines_1941.sql` est né d'une observation d'Adrien : une commune
présente dans une sortie de `33` mais introuvable sur la carte engendrée.

Le diagnostic a d'abord été mauvais — j'ai cru à un défaut de classement — et
la vraie anomalie était ailleurs, dans une colonne que j'avais sous les yeux :
**toutes ces communes ont leur dernier rattachement au 1er janvier 1941**, date
de fin de la série TRF-GIS. Une date qui vaut pour toutes les lignes n'est pas
une donnée, c'est une frontière de source.

La cause est structurelle. `24` construit les cantons modernes à partir des
millésimes du COG, qui commencent en 1999. Une commune éteinte avant 1999 ne
figure dans aucun d'eux et **ne reçoit donc jamais de canton**, alors qu'elle a
existé et relevé d'un canton pendant des décennies. La couche moderne est un
instantané projeté, pas une chronologie.

La mesure, sur deux départements :

| département | communes concernées | années vécues sans canton |
|---|---|---|
| Ain | 33 | 902 |
| Aisne | 18 | 525 |

Soit **1 427 années-communes**, et de l'ordre de 65 000 à l'échelle nationale
si ces deux départements sont représentatifs — extrapolation à traiter comme
telle, deux départements ne font pas un échantillon.

En contrepartie, ces 51 fusions arrivent **datées au jour près** par le fichier
de mouvements de l'Insee. C'est la première information de datation du projet
qui ne dépende pas des cartes, et elle est plus fine que tout ce que l'atlas
peut donner.

### Points de contrôle 1870-1940 pour l'Aisne

Relevés sur l'atlas, à confronter à TRF-GIS — ils testent la source, ils ne la
complètent pas :

| commune | canton attendu |
|---|---|
| Samoussy | Laon |
| Martigny-Courpierre | Laon |
| Loupeigne | Fère-en-Tardenois |
| Marigny-en-Orxois | Charly |

```sql
SELECT g.nom_comm, m.valid_from, m.valid_to, u.nom AS canton
FROM   histgis.geofla_commune g
JOIN   histgis.atom a ON a.insee_geofla = g.insee_com
JOIN   histgis.membership m ON m.atom_id = a.atom_id AND m.niveau = 'canton'
JOIN   histgis.unit u ON u.unit_id = m.unit_id
WHERE  g.nom_comm ILIKE ANY (ARRAY['samoussy','martigny-courpierre',
                                   'loupeigne','marigny-en-orxois'])
ORDER  BY 1, 2;
```

## La vérification, à lancer après chaque département

L'Insee attribue aux cantons nouvellement créés des **codes en fin de série**
départementale. Un canton né en 1986 porte donc un code supérieur à ceux des
cantons anciens. C'est un contrôle indépendant de la saisie : il ne vient ni de
l'atlas ni de la mémoire, mais de la numérotation officielle.

```sql
-- les cantons du département, par code, dans le COG 1999
SELECT canton, nom, count(*) AS communes
FROM   histgis.cog_canton_liste
WHERE  left(insee, 2) = '01' AND millesime = 1999
GROUP  BY canton, nom
ORDER  BY canton;
```

Lecture attendue pour l'Ain : Miribel, Trévoux **ou** Reyrieux, Viriat,
Péronnas, Oyonnax-Nord et Oyonnax-Sud doivent figurer en fin de liste.

Le cas de Trévoux/Reyrieux se tranche seul : **celui des deux qui porte le code
le plus élevé est le nouveau**, donc le résultant, et l'autre est la source. Si
c'est Reyrieux, la ligne du registre doit être inversée.

Ce test ne vaut pas preuve — un département a pu être renuméroté en bloc — mais
un désaccord signale à coup sûr quelque chose à regarder.

## Les événements antérieurs à 1941 sont un contrôle, pas une donnée

TRF-GIS couvre 1870-1940. Tout mouvement dicté dans cet intervalle est déjà en
base : il ne comble aucun trou, il **teste la source**. Si la base ne le porte
pas, c'est un défaut de TRF-GIS, et c'est une trouvaille.

La création de Villars en 1876 se vérifie ainsi :

```sql
-- le canton de Villars existe-t-il, et depuis quand ?
SELECT u.unit_id, coalesce(uv.nom, u.nom) AS nom,
       min(m.valid_from) AS depuis, max(m.valid_to) AS jusqu_a,
       count(DISTINCT a.insee_geofla) AS communes
FROM   histgis.membership m
JOIN   histgis.atom a ON a.atom_id = m.atom_id
JOIN   histgis.unit u ON u.unit_id = m.unit_id AND u.niveau = 'canton'
LEFT   JOIN histgis.unit_version uv ON uv.unit_id = u.unit_id
WHERE  left(a.insee_geofla, 2) = '01'
  AND  coalesce(uv.nom, u.nom) ILIKE ANY (ARRAY['%villars%','%trivier%','%chalamont%'])
GROUP  BY 1, 2 ORDER BY 3, 2;
```

Trois lectures possibles. Villars apparaît en 1876 et les deux autres perdent
des communes à la même date : la source est juste et la dictée aussi. Villars
existe depuis 1870 : c'est la dictée qui se trompe de date. Villars n'existe
pas : TRF-GIS a manqué une création, ce qui serait le premier défaut de ce type
trouvé dans la source.

## Ordre de travail suggéré

Les départements où l'atlas Gaudillère donne la stabilité — comme les
Bouches-du-Rhône, où `30_stabilite_cantonale.sql` n'a trouvé que quatre cantons
éclatés — demandent peu de saisie. Commencer par eux permettrait de mesurer
tôt combien de départements sont réellement stables, et donc l'ampleur du
travail restant.
