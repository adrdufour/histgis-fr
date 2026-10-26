# Le registre des mouvements cantonaux

Le registre des mouvements cantonaux (`mouvements_cantonaux.csv`), sa
consolidation, son contrôle par l'annexe VII et la datation des cantons
`post_1986`.

Réunit, le 26 octobre 2026, des notes jusque-là séparées. Chaque
partie est reprise telle quelle ; le tableau donne l'ancien nom de
fichier, que citent encore `JOURNAL.md` et les notes anciennes.

| partie | ancien fichier |
|---|---|
| Registre des mouvements cantonaux, 1941-1998 | `note_mouvements.md` |
| Le registre des mouvements cantonaux — consolidé | `registre_consolide.md` |
| Vérification de l'annexe VII — résultat | `verification_annexe_vii.md` |
| Les cantons `post_1986` du registre — datation | `note_cantons_post1986.md` |
| Datation des 64 cantons `post_1986` — état après dépouillement des JO | `pdf_a_telecharger.md` |

## Registre des mouvements cantonaux, 1941-1998

Fichier : `cantons/mouvements_cantonaux.csv`

> **Correction du 2 septembre 2026 — deux affirmations de cette note ont été
> renversées par la suite du chantier.**
>
> 1. *« Entre les deux, rien. »* Faux depuis le 28 août : deux jalons de
>    recensement (1954, 1968), 343 actes au registre, les salves de décrets et
>    deux reports validés couvrent désormais l'intervalle — inégalement, et pour
>    partie sous convention. `ETAT.md` § 2.3.
> 2. *« Ce registre comble l'intervalle par saisie manuelle. »* Le registre a
>    **changé de nature en cours de route**, et c'est le fait le plus utile de
>    cette note. Il devait recueillir des mouvements dictés à la main ; la base
>    sait les calculer par différentiel 1940→1999. **Il ne consigne plus que des
>    dates** — et, depuis l'annexe VII, des dates de décret : l'Ain compte neuf
>    lignes en `certitude = acte` là où il avait des intervalles de vingt-huit
>    ans. Voir la partie « registre consolidé ».
>
> Ce qui reste exact et n'a pas d'équivalent ailleurs : les **274 transferts
> isolés de communes** que l'annexe VII ne recense jamais par construction, et
> qui resteront indatables sans les décrets. C'est une limite connue, pas une
> lacune du dépouillement.

### Pourquoi ce registre

Le trou cantonal 1941-1998 était, quand cette note a été écrite, le dernier
blocage structurel du projet. TRF-GIS s'arrête en 1940, le COG ne descend au
canton qu'à partir de 1999, et le fichier historique du COG n'a livré que
66 événements MOD-43, tous entre 1995 et 1998.

Ce registre devait combler l'intervalle par saisie manuelle, département par
département.

### Ce registre n'est pas une table de faits, c'est une table de dates

Il avait été conçu pour saisir à la main les mouvements cantonaux, département
par département. **L'Ain a montré que la saisie était inutile.**

La base porte déjà le rattachement cantonal de chaque commune en 1940
(TRF-GIS) et en 1999 (COG). Les `unit_id` sont partagés entre les deux couches,
le code Insee fait le pont, et le différentiel se calcule :
`sql/diag/33_diff_cantonal.sql`, paramétré par département.

Ce que la machine ne sait pas produire, c'est la **date**. Le registre ne
consigne donc plus des événements dictés, mais les bornes temporelles
d'événements calculés.

#### Ce que le calcul voit et que la dictée ne voyait pas

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

#### La leçon du partage

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

#### Ce que ni le calcul ni les cartes ne donnent

La date des transferts. Une commune isolée qui change de canton ne déplace
aucune limite de circonscription, donc l'atlas ne la montrera jamais. Ces
lignes restent en `certitude = inconnue` sur tout l'intervalle 1940-1999, et le
resteront sans les décrets. À déclarer comme telles plutôt qu'à rattacher au
redécoupage le plus proche.

### Le schéma

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

#### Une date d'atlas est une borne, pas une date

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

#### Ce que cette imprécision coûte, et ce qu'elle ne coûte pas

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

#### `stabilite` : l'absence de changement est une information

« Pas d'autres modifications jusqu'à 1815 » n'est pas une absence de données,
c'est une affirmation positive, et elle vaut autant que les événements. Sans
elle, un intervalle vide serait indistinguable d'un intervalle non dépouillé.
Ces lignes portent `date_eff` et `date_fin`, et rien d'autre.

#### Plusieurs cantons sources : la remontée casse

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

### Ce qui est saisi

#### Ain (01) — complet de 1815 à 1986

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

#### Aisne (02) — et le premier intervalle resserré

Cinq démembrements, trois partages, deux transferts. Les cinq cantons neufs —
Laon-Sud, Saint-Quentin-Nord et Sud, Soissons-Sud, Tergnier — figurent tous sur
la carte de 1986, donc `[1958, 1986]`.

#### Ce que l'atlas peut dire, et ce qu'il ne peut pas

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

#### Le trou 1941-1998 avale aussi des communes entières

`sql/diag/34_orphelines_1941.sql` est né d'une observation d'Adrien : une commune
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

#### Points de contrôle 1870-1940 pour l'Aisne

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

### La vérification, à lancer après chaque département

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

### Les événements antérieurs à 1941 sont un contrôle, pas une donnée

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

### Ordre de travail suggéré

Les départements où l'atlas Gaudillère donne la stabilité — comme les
Bouches-du-Rhône, où `30_stabilite_cantonale.sql` n'a trouvé que quatre cantons
éclatés — demandent peu de saisie. Commencer par eux permettrait de mesurer
tôt combien de départements sont réellement stables, et donc l'ampleur du
travail restant.

## Le registre des mouvements cantonaux — consolidé

`cantons/consolide_registre.py` produit `cantons/mouvements_cantonaux.csv` :
**2 024 lignes, 95 départements.** Il remplace la saisie manuelle, conservée
sous `mouvements_cantonaux.saisie_manuelle.csv` (rangé dans `archives/`) comme témoin.

### Le principe

Deux sources qui ne se recouvrent pas, croisées sur le nom du canton d'arrivée :

* **la base** sait QUELS mouvements ont eu lieu et QUELLES communes ils
  déplacent — c'est le différentiel 1940→1999 de `33_diff_cantonal.sql`,
  généralisé aux 95 départements ;
* **l'annexe VII de Gaudillère** sait QUAND, au décret près, mais ne nomme
  aucune commune et s'arrête au découpage de 1986.

Aucune des deux ne suffit. Ensemble elles donnent un mouvement daté et peuplé.

### Le résultat

|  | acte | borne_sup | post_1986 | inconnue | cadre_change | total |
|---|---|---|---|---|---|---|
| démembrement | 559 | 111 | 53 | 0 | 159 | 882 |
| partage | 680 | 116 | 71 | 0 | 1 | 868 |
| transfert | 0 | 0 | 0 | 274 | 0 | 274 |

**723 démembrements réels, dont 559 datés au décret — 77 %.** C'est le chiffre
qui compte : le démembrement est le seul des trois types qui déplace une
limite. Le partage est un état, le transfert une commune isolée.

Les 559 dates s'étalent de 1861 à 1986, mais **505 d'entre elles — 90 % —
tombent dans les seules décennies 1970 et 1980**. Six décrets portent à eux
seuls 283 démembrements, celui du 23.7.1973 en tête avec 61. Le registre
retrouve par un autre chemin le régime à deux vagues déjà lu dans l'annexe.

### Les cinq statuts

`acte` — l'annexe nomme le canton créé. Date au jour près.

`borne_sup` — le nom figure dans le texte du département sans qu'un
appariement exact soit possible. La date est encadrée : 1941–1986.

`post_1986` — le canton existe en 1999, l'annexe ne le nomme nulle part.
**48 cantons dans 23 départements** hors changements de cadre. Non datables
par cette source, qui s'arrête treize ans trop tôt.

`inconnue` — transfert isolé d'une commune. L'annexe VII ne recense **jamais**
ce type de mouvement : c'est une limite de la source, pas une lacune de la
transcription. Les 274 lignes resteront indatées sans les décrets eux-mêmes.

`cadre_change` — voir ci-dessous.

### Le piège du cadre départemental

**160 lignes, 9 départements : 2A, 2B, 91 à 95, 13, 69.**

Le différentiel 1940→1999 y lit un mouvement là où il n'y en a pas. Belgodère
et Borgo existaient bien avant 1940 ; ils ne « remontent » que parce que la
Corse a été scindée en 1976. Bourg-la-Reine de même, parce que la Seine a été
démembrée en 1964. Le canton n'a pas bougé — **le département a changé sous
lui.** Marseille et Lyon s'y ajoutent, repliées en pseudo-cantons par
`25_pseudo_canton.sql`.

Rangées d'abord en `post_1986`, ces lignes affirmaient 120 créations tardives
imaginaires. Elles ont maintenant leur statut et sortent des taux.

C'est exactement la correction de `35_atomes_hors_departement.sql`, où 22
atomes « déplacés » n'étaient que 8 une fois les recodages retirés. **Le même
piège deux fois : un changement de référentiel se déguise en événement.**

### La double mesure du post-1986

Le chiffre de 48 n'est pas une estimation mais une convergence.

`verif_annexe_vii.py` compare des **effectifs** — `cantons_1999 − cantons_1940`
contre `créations − disparitions` — et ne connaît aucun nom de canton. Son
résidu national donnait « une quarantaine ».

`consolide_registre.py` apparie des **noms** et ne compte rien. Il en trouve 48.

Et les listes coïncident département par département : Albi-Est, Albi-Ouest,
Castres-Ouest pour le Tarn ; Castelnau-le-Lez, Lattes, Pignan pour l'Hérault ;
Blagnac, Portet-sur-Garonne, Tournefeuille pour la Haute-Garonne ; les dix du
Pas-de-Calais. Ce sont des cantons périurbains portant des noms de communes,
signature des créations de la fin des années 1980.

**Deux chemins sans rapport aboutissent à la même liste nominative.** C'est un
contrôle indépendant au sens de `METHODE.md`, et il donne un ordre de grandeur
que ni l'annexe ni le COG ne portent — le COG ne commence qu'en 1999.

### Ce que l'appariement a coûté

Le nom d'un canton s'allonge entre sa création et 1999 : « Digne-O. » devient
« Digne-les-Bains-Ouest », « Brive-S.E. » devient
« Brive-la-Gaillarde-Sud-Est ». Une comparaison de chaînes entières les
déclarait inconnus.

L'appariement compare donc **racine et suffixe séparément** — même point
cardinal ou même numéro, une racine préfixe de l'autre. Deux pièges au passage,
qui valent d'être notés :

* la décomposition doit travailler sur les **mots**, jamais sur la chaîne
  aplatie. Une expression régulière sur « dignelesbainso » rend
  (« dignelesbain », « so ») : le `s` de « Bains » est happé par le suffixe ;
* les **codes départementaux ne concordent pas** entre les deux sources.
  L'annexe classe la Corse sous 20, la petite couronne sous 75, l'Essonne et
  le Val-d'Oise sous 78O. Ajaccio-1 était déclaré postérieur à 1986 quand
  l'annexe le date du 18.8.1973. Une table `ANCETRES` fait remonter la
  filiation.

### Ce que le registre ne dira pas

L'ordre des mouvements à l'intérieur d'un même décret. Et les créations suivies
de suppressions qui se compensent : Bourg-en-Bresse est divisée en 1973 puis
redivisée en 1982, le différentiel 1940→1999 n'en montre que le résultat.

`annexe_vii.csv` porte cette chronologie intacte et reste la référence pour
l'histoire ; ce fichier-ci pour la géométrie.

## Vérification de l'annexe VII — résultat

`cantons/verif_annexe_vii.py` confronte, département par département, l'écart
cantonal 1940→1999 de la base à ce que l'annexe VII explique.

    cantons_1999 − cantons_1940  ==  créations − disparitions

### Le résultat

**56 départements sur 85 bouclent exactement.** La transcription des 39 pages
est donc juste sur les deux tiers du pays, contrôlée par un calcul indépendant.

Onze départements sont écartés d'emblée, le test ne pouvant s'y appliquer :

| département | pourquoi |
|---|---|
| 75 | Paris n'a pas de cantons dans la base, mais des arrondissements |
| 91, 92, 93, 94, 95 | créés en 1964 ; leurs cantons de 1940 sont ceux de la Seine ou de la Seine-et-Oise, comptés sous leur code moderne |
| 78 | héritier partiel de la Seine-et-Oise démembrée |
| 2A, 2B | Corse recodée 20 → 2A/2B en 1976 ; l'annexe classe tout sous 20 |
| 13, 69 | Marseille et Lyon repliées en pseudo-cantons par `25_pseudo_canton.sql` |

### Ce que les 29 désaccords restants disent

Ce ne sont pas des erreurs de lecture. **L'annexe VII s'arrête au découpage de
1986 ; la comparaison va jusqu'en 1999.** Les cantons créés dans cet intervalle
de treize ans lui échappent par construction.

La démonstration tient dans la coïncidence des deux mesures. Pour chaque
département, le nombre de cantons de 1999 dont le nom n'apparaît **nulle part**
dans l'annexe égale son résidu :

| dép. | résidu | cantons non cités |
|---|---|---|
| 81 | +3 | Albi-Est, Albi-Ouest, Castres-Ouest |
| 34 | +3 | Castelnau-le-Lez, Lattes, Pignan |
| 31 | +3 | Blagnac, Portet-sur-Garonne, Tournefeuille |
| 35 | +2 | Betton, Cesson-Sévigné |
| 54 | +2 | Malzéville, Seichamps |
| 59 | +3 | Douai-Nord-Est, Seclin-Nord |

Et leurs noms sont ceux qu'on attend : **des cantons périurbains portant des
noms de communes**, signature des créations de la fin des années 1980.

À l'inverse, cinq départements — Sarthe, Yonne, Vaucluse, Tarn-et-Garonne,
Indre-et-Loire — ont un résidu non nul mais **aucun canton non cité**. Leur
écart vient du comptage, pas d'une lacune : le texte de l'annexe y emploie des
formes que la convention « division / dédoublement » ne suffit pas à trancher.

#### Un ordre de grandeur inédit

La somme des résidus positifs, minorée des négatifs, donne **une quarantaine de
cantons créés entre 1986 et 1999** en métropole. C'est un chiffre que ni
l'annexe ni le COG ne donnent — le COG ne commence qu'en 1999 — et il complète
la mesure du trou par son extrémité la plus récente.

### Le cas du Pas-de-Calais — clos

**Résidu +9**, le plus fort de tous, avec douze cantons non cités : Barlin,
Berck, Dainville, Divion, Douvrin, Montigny-en-Gohelle, Noyelles-sous-Lens,
Le Portel, Sains-en-Gohelle, Béthune-Est, plus deux appariements ratés
(Bruay-en-Artois renommé Bruay-la-Buissière en 1987, Boulogne-N.O.).

Neuf créations inexpliquées dans un seul département, quand aucun autre ne
dépasse trois : la transcription était suspecte. **Les pages 810 et 811 ont été
relues : elles sont complètes.** Le département s'arrête bien au décret du
24.12.1984, dernier point « Cr. Calais-S.E. ».

Le résidu est donc réel, et il rejoint l'explication générale : neuf cantons
créés dans le bassin minier et le Boulonnais **entre 1986 et 1999**, hors de
portée de l'annexe. Le seul cas qui pouvait encore la contredire la confirme.

Une correction de date au passage : `Cr. Noeux-les-Mines` est le dernier point
du décret du 16.8.1973, non du 29.9.1975 qui ne porte que des changements de
dénomination. Sans effet sur le décompte.

### Ce que le contrôle a produit au passage

Deux résultats que la vérification n'était pas censée donner.

**L'Oise a livré une information absente du texte.** Le livre écrit « Cr.
Compiègne-N. et Compiègne-S. » sans dire ce qu'il advient de l'ancien canton de
Compiègne. Le solde arithmétique impose qu'il disparaisse : sans cela l'Oise
compterait un canton de trop. Le contrôle ne s'est pas contenté de valider, il a
tranché une ambiguïté de la source.

**Et il a corrigé une erreur de transcription réelle** : la ligne du 13.7.1973
de l'Oise, à cheval sur la coupure des pages 809 et 810, avait été saisie deux
fois sous forme tronquée.

### Limites du contrôle

Il ne mesure que des **effectifs**. Un canton créé et un autre supprimé le même
jour se compensent et passent inaperçus. Il ne dit rien des transferts de
communes entre cantons, que l'annexe VII ne recense de toute façon jamais.

Et le parseur reste approximatif : le texte de l'annexe est en français libre,
et la convention « division / dédoublement » n'est pas toujours suivie — la
Sarthe crée six cantons du Mans « par division des 3 anciens », qui disparaissent
en réalité alors que la convention voudrait qu'ils subsistent.

## Les cantons `post_1986` du registre — datation

Fichier produit : `cantons/cantons_post1986_datation.csv` (64 cantons).

### Le résultat qui compte : la catégorie est mal nommée

Sur les 64 cantons que le registre classe `post_1986`, **19 sont antérieurs à
1986**. Le label ne dit pas « créé après 1986 » mais « non nommé par l'annexe
VII » — et l'annexe est muette bien avant sa date d'arrêt.

| Canton | Décret réel |
|---|---|
| 87 Limoges-Cité, Limoges-Le Palais, Limoges-Panazol | n° 73-821 du 16 août 1973 |
| 50 Ducey, La Haye-du-Puits, Sartilly | n° 73-664 du 13 juillet 1973 (piste) |
| 64 Arthez-de-Béarn, Pau-Sud | n° 73-669 du 13 juillet 1973 (piste) |
| 43 Le Puy-en-Velay Est / Ouest / Sud-Ouest, Saugues | n° 73-767 du 2 août 1973 (piste) |
| 17 La Rochelle 3e canton | n° 73-655 du 13 juillet 1973 |
| 22 Plérin | n° 82-54 du 20 janvier 1982 |
| 27 Vernon-Sud | n° 82-56 du 20 janvier 1982 |
| 33 Villenave-d'Ornon | n° 82-29 du 15 janvier 1982 |
| 87 Limoges-Landouge | n° 82-86 du 25 janvier 1982 |
| 62 Barlin | n° 84-1236 du 24 décembre 1984 |
| 90 Châtenois-les-Forges | décret du 19 janvier 1970 (piste) |

Sept d'entre eux étaient déjà sous nos yeux : ils figurent dans les décrets de
1973-1984 dépouillés à l'étape précédente. Les autres viennent de décrets
identifiés par leur titre sur Légifrance.

**Le chiffre de 48 (ou 64 lignes) surestime donc les créations tardives**, pour
la même raison que les 120 « créations » du Val-d'Oise et de la Corse
surestimaient les mouvements : une source silencieuse se déguise en événement.
C'est le piège déjà noté dans la partie « registre consolidé », sous une autre forme.

### État de la datation

| Statut | Cantons |
|---|---|
| **daté** (texte lu) | 51 |
| **piste** (décret identifié par son titre, texte non consultable) | 12 |
| **non retrouvé** | 1 — Le Havre 6e canton (76) |

Répartition des dates retenues :

| Date | Cantons | |
|---|---|---|
| 19 janvier 1970 | 1 | Territoire de Belfort |
| 1973 (13/07, 02/08, 16/08) | 13 | |
| 1982 (15/01, 20/01, 25/01) | 4 | |
| 24 décembre 1984 | 1 | |
| 21 avril 1988 | 2 | Isère (piste) |
| **27 février 1991** | **27** | la vague principale |
| 26 février 1993 | 1 | Seine-et-Marne |
| 13 janvier & 21-26 février 1997 | 13 | |

### Les deux vagues de la fin de période

**27-28 février 1991** — décrets n° 91-209 à 91-232, seize départements
métropolitains plus Guadeloupe et Réunion. C'est de loin la plus grosse : 27
des cantons cherchés, dont les onze du Pas-de-Calais (91-217) et les sept de
Brest (91-211).

**13 janvier et 21-27 février 1997** — huit départements. Les décrets de février
1997 **ne portent pas de numéro** (« Décret du 21 février 1997 portant
modification et création de cantons dans le département de… ») ; ils se citent
par date et département.

### Ce que ça change pour l'accès aux textes

Les décrets **de 1990 et après ont leur texte intégral sur Légifrance**, articles
et listes de communes compris — y compris les délimitations de communes coupées,
au même format que 1973 :

> « […] la portion de territoire de la commune d'Hénin-Beaumont située au
> Sud-Est d'une ligne définie par l'axe des voies ci-après […] »
> — décret n° 91-217, art. 2

Aucun PDF ni OCR nécessaire pour 1991, 1993 et 1997. En revanche 1970, 1988 et
tout l'avant-1990 restent tributaires des JO numérisés.

### Pour le trou cantonal 1943-1999

Recherche Légifrance, fonds JORF, « création de cantons », signature entre 1943
et 1985 : **207 décrets**. La liste des actes existe donc en entier et se
récupère par titre ; seul le contenu d'avant 1990 demande les JO papier.

Deux conséquences pratiques :

- les huit dates traitées jusqu'ici (1973, 1982, 1984) ne sont qu'une fraction
  de la série — il existe par exemple un décret n° 82-95 du **27 janvier 1982**,
  absent de la liste de départ ;
- la voie la plus économique pour combler le trou n'est pas de dater canton par
  canton, mais de **dépouiller les 207 décrets dans l'ordre**, puisque chacun
  porte lui-même sa date.

### Limites

- Les 12 « pistes » reposent sur le seul titre du décret : le bon département et
  la bonne période, pas la lecture du dispositif. À confirmer sur le JO.
- Le Havre 6e canton n'a aucun décret candidat sur 1943-1999 dans les titres
  Légifrance. Soit le titre est formulé autrement, soit la création est
  antérieure à 1943.
- L'appariement des noms tolère les variantes d'écriture des suffixes
  (« 3e Canton » ≈ « -III »). Deux cantons voisins d'une même ville pourraient
  en théorie être confondus ; aucun cas repéré ici.

---

Sources : Légifrance, fonds JORF (recherche par date de signature et en plein
texte des articles) ; JO numérisés déjà dépouillés dans `sources/modif_canton/`.
Licence etalab-2.0.

## Datation des 64 cantons `post_1986` — état après dépouillement des JO

**57 datés · 7 faux positifs · 0 piste restante — CLOS le 15 août 2026.**

Détail canton par canton dans `cantons_post1986_datation.csv`.

### Ce que les quatre PDF ont donné

| PDF | Décret | Résultat |
|---|---|---|
| `JORF_19880422_95` | 88-398 (Isère) | ✅ **Saint-Ismier confirmé** — « Il est créé un canton de Saint-Ismier », détaché de Meylan, effet au 1er septembre 1988 |
| `JORF_19820128_23` | 82-95 (Pyrénées-Atlantiques) | ❌ crée Pau-Centre, Pau-Est, Pau-Nord, Lescar, Billère, Anglet-Nord — **pas Pau-Sud** |
| `JORF_19820128_23` | 82-97 (Seine-Maritime) | ❌ crée Sotteville-lès-Rouen-Est et Ouest, Saint-Étienne-du-Rouvray — **pas Le Havre** |
| `JORF_19700121_17` | décret du 19 janvier 1970 | ❌ crée Delle, Beaucourt, Grandvillars — **pas Châtenois-les-Forges** |

Un sur quatre. Les corps de 82-95 et 82-97 se trouvaient dans le JO **ordinaire**
du 28 janvier, pas dans le numéro complémentaire.

### Le Havre : ni création ni faux positif ordinaire, une renumérotation

Le décret **n° 91-218 du 27 février 1991** (texte intégral sur Légifrance, aucun
PDF nécessaire) :

> « Art. 1er. — Les cantons du Havre-I et du Havre-II sont réunis en un seul
> canton qui prend la dénomination du Havre-I.
> Art. 2. — Les cantons du Havre-III, IV, V, VI, VII, VIII, IX et X prennent
> respectivement les dénominations du Havre-II, III, IV, V, VI, VII, VIII et IX. »

Le « Havre 6e canton » de 1999 est donc **l'ancien Havre-VII**, décalé d'un rang.
Aucun canton n'a été créé.

**Conséquence au-delà du Havre** : toute la série havraise est décalée après
1991. Un appariement par nom entre un état antérieur et le COG 1999 associera
systématiquement le mauvais canton — et sans lever d'alerte, puisque les deux
noms existent de part et d'autre. À vérifier partout où un chef-lieu porte des
cantons numérotés (Le Havre, Rouen, Nice, Marseille…).

C'est le quatrième déguisement du même phénomène, après le changement de
département, le silence de la source et le renommage.

### Les 7 faux positifs

| Canton | Raison |
|---|---|
| 50 Ducey (5013), La Haye-du-Puits (5016), Sartilly (5042) | présents en 1872 et 1932 sous le même code |
| 43 Saugues (4325) | idem |
| 38 Vizille (3844) | idem |
| 64 Arthez-de-Béarn (6403) | « ARTHEZ » en 1872 — renommage |
| 76 Le Havre 6e (7656) | renumérotation par le décret 91-218 |

### Les 2 pistes restantes

Codes 6447 et 9010 : **absents des nomenclatures de 1872 et de 1932**, ce sont
donc de vraies créations. Les décrets restants pour ces départements :

| PDF | JO | Décret | Pour |
|---|---|---|---|
| `JORF_19750926_224` | 26 septembre 1975 | **75-872**, Pyrénées-Atlantiques | Pau-Sud |
| `JORF_19670810_185` | 10 août 1967 | **67-672**, Territoire de Belfort | Châtenois-les-Forges |

- 75-872 → https://www.legifrance.gouv.fr/jorf/id/JORFTEXT000000307309
- 67-672 → https://www.legifrance.gouv.fr/jorf/id/JORFTEXT000000702076

Ce sont les **derniers** décrets cantonaux que Légifrance recense pour ces deux
départements entre 1943 et 1999. S'ils ne contiennent pas ces cantons, la
création vient d'un décret dont le titre ne nomme pas le département (formule
« dans divers départements ») et il faudra changer de méthode de recherche.

### Rappel de méthode

Sur les 12 pistes fondées sur le seul titre du décret, **9 étaient fausses**
(73-664, 73-669, 84-1230, 84-1240, 82-95, 82-97, décret de 1970, et les deux
replis implicites). Une seule s'est vérifiée du premier coup : 88-398.

Le titre d'un décret donne un département et une date. Il ne dit jamais quels
cantons sont créés, et le taux d'erreur observé ici — 9 sur 12 — interdit de
l'utiliser autrement que comme piste à vérifier.

---

Sources : JO numérisés de `sources/modif_canton/` ; Légifrance, fonds JORF ;
nomenclatures cantonales 1872 et 1932 de `sources/trfgis/`. Licence etalab-2.0.


---

### Les deux dernières pistes, closes le 15 août 2026

Les deux PDF ont été déposés et dépouillés. **Tous deux portent une couche
texte native** : aucun OCR n'a été nécessaire, contrairement au volume de 1954.

#### Châtenois-les-Forges (90) — création confirmée

**Décret n° 67-672 du 9 août 1967**, JO du 10 août, page 8012. Le texte est sur
deux colonnes ; `pdftotext -layout` les entrelace et rend l'article illisible.
Il faut découper par colonne : `pdftotext -f 4 -l 4 -x 320 -W 320`.

> « Art. 1er. — En remplacement du canton de Belfort (territoire de Belfort),
> sont créés les sept cantons dénommés et composés comme suit : […]
> **5. Canton de Châtenois-les-Forges** comprenant les communes de
> Châtenois-les-Forges, Argiésans, Banvillars, Bavilliers, Bermont, Botans,
> Buc, Dorans, Trétudans, Urcerey et Vourvenans. »

Le décret crée sept cantons d'un coup : Belfort-Centre, -Est, -Ouest et -Nord
(quatre fractions de la ville), plus Châtenois-les-Forges, Danjoutin et Valdoie.

**Onze communes, onze appariements**, et deux d'entre eux méritent d'être
notés : **Trétudans (90097) et Vourvenans (90106) ne sont pas des fautes
d'OCR.** Ce sont deux communes réelles, fusionnées dans **Trévenans le
1ᵉʳ juillet 1972** — cinq ans après la création du canton. Le premier réflexe
avait été de « corriger » Vourvenans en Trévenans par ressemblance : c'eût été
remplacer le fait par le successeur du fait. `insee_mvt.libelle_av` tranche en
une requête.

Seul « Bue » est une vraie erreur de lecture, pour **Buc** (90020) — un `c` lu
`e`, une seule lettre.

#### Pau-Sud (64) — ce n'est PAS le 75-872

Le décret n° 75-872 du 3 septembre 1975 ne crée rien. Son article 1er dit :

> « Les quatrième et huitième alinéas de l'article 1er du **décret susvisé**
> sont remplacés par les dispositions suivantes : "Canton de Pau-IV-Ouest
> comprenant les communes de Narcastet, Rontignon, Uzos, Mazères-Lezons et
> Gelos ainsi que la portion du territoire de la ville de Pau…" »

Le décret visé est le **n° 73-669 du 13 juillet 1973**. C'est lui le texte
créateur ; le 75-872 se borne à redéfinir deux de ses alinéas.

**Trois enseignements, dont un désagréable.**

1. Le canton s'appelle **Pau-III-Sud** en 1975 et **Pau-Sud** au COG de 1999.
   La numérotation romaine a sauté entre les deux. C'est le cinquième
   déguisement du même phénomène, après le changement de département, le
   silence de la source, le renommage et la renumérotation du Havre.

2. **Le décret créateur était déjà dans nos fichiers.** `73-669` figure dans
   `communes_coupees_1973_1984.csv` — mais avec ses seules lignes **Bayonne et
   Biarritz**, qui relèvent de son article 2. **L'article 1er, celui de Pau,
   manque à la transcription.** Nous avons donc cherché pendant des semaines un
   décret que nous possédions, dont une moitié n'avait pas été relevée.

3. Conséquence à porter au dossier de l'exhaustivité :
   `communes_coupees_1973_1984.csv` **n'est pas complet décret par décret**. Un
   décret présent dans le fichier ne garantit pas que tous ses articles y
   soient. Toute mesure de couverture fondée sur le nombre de décrets présents
   surestime donc la couverture réelle.
