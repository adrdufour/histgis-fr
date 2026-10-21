# Carte interactive — communes, cantons, circonscriptions, 1815-2012

Une page à curseur d'années et sélecteur de département. Trois niveaux
superposés : les communes en trait fin, les cantons en trait moyen sur fond
colorié, les circonscriptions législatives en trait épais.

## Marche à suivre

```bash
python3 cartes/export_web.py        # tous les départements ; --dsn pour une autre base
python3 cartes/web/servir.py        # ouvre http://127.0.0.1:8765/index.html
```

**Un export complet efface `dep/` en entier, outre-mer compris** : le relancer
ensuite avec `python3 cartes/export_web.py --outremer`, sans quoi le groupe
« Outre-mer » disparaît du sélecteur. C'est ce qui est arrivé à l'export du
4 octobre 2026 au soir ; les cinq dossiers ont été recopiés le 6 octobre depuis
`sorties/part_2026-10-04_1815` (l'ancien index est gardé dans
`donnees/index.avant_outremer.json`).

Pour la carte d'une liste de communes (export Commons, ci-dessous), une fois
après chaque export : `python3 cartes/web/noms_cog.py` puis
`python3 cartes/web/fonds_communes.py`.

Pour déposer des cartes sur Wikimedia Commons : voir
[plus bas](#exporter-vers-wikimedia-commons).

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

## Exporter vers Wikimedia Commons

Le bouton **Commons…**, en bas à droite, prépare l'une des quatre images pour
l'année affichée — deux par niveau, circonscriptions ou cantons —, et la dépose
sur Commons avec description, licence et catégories pré-remplies — et,
depuis le 6 octobre 2026, la carte d'une liste de communes, [plus
bas](#carte-dune-liste-de-communes-aop-intercommunalité) :

| image | contenu | nom proposé |
|---|---|---|
| **carte du département** | circonscriptions coloriées et numérotées, limites cantonales et communales en trait fin | `Circonscriptions législatives de la Côte-d'Or (1852-1869).svg` |
| **situation d'une circonscription** | le département en grisé, la circonscription choisie en rouge | `Côte-d'Or 2e circonscription 1852-1869 (localisation).svg` |
| **carte des cantons** | cantons coloriés et nommés, circonscriptions en trait épais, communes en trait fin | `Cantons de la Côte-d'Or (1875-1891).svg` |
| **situation d'un canton** | le département en grisé, le canton choisi en rouge | `Canton de Mirebeau (Côte-d'Or) 1875-1891 (localisation).svg` |

Les cantons (6 octobre 2026) suivent les mêmes règles, avec trois différences.
Le **coloriage** prend le vrai voisinage (deux cantons qui partagent des
sommets) et non l'emprise, qui ne suffit plus pour quarante unités. Les
**noms** prennent le plus grand corps qui tienne dans le canton, sur deux lignes
au besoin ; un canton de la Seine nommé `Paris-05` est affiché « 5e ». La
**période** compare la composition (atome → nom du canton), puisque les
identifiants d'unités cantonales ne portent pas d'année ; une plage qui bute
sur une année sans couche cantonale est dite ouverte.

L'image est un **SVG** autonome (styles en attributs, police DejaVu Sans, que
le moteur de rendu de Commons possède), licence **CC BY-SA 4.0**
(`{{self|cc-by-sa-4.0}}`). Rien n'est recalculé : tout vient des fichiers que
la page a déjà chargés, dans la projection de la page.

**La période du titre est celle du découpage, pas l'année du curseur.** Les
fichiers `x_<sig>.json` étant signés sur leur contenu, géométrie comprise, un
même découpage peut en avoir plusieurs (la Côte-d'Or en a deux pour celui de
1831) : la page compare donc les identifiants d'unités (`21-01@1852`) des
années voisines. Quand la plage touche une borne de la base, l'aperçu le dit —
le découpage peut valoir au-delà.

**La description** (`{{Information}}`, `{{fr}}` + `{{en}}`) donne la chambre,
la période, le nombre de circonscriptions, les élections générales tenues sur
ce découpage, et pour chaque circonscription le nombre de communes et — quand
la base tient la couche cantonale à cette date, donc pas avant 1870 — ses
cantons, avec « (partie) » pour un canton partagé. Sources : la composition
électorale selon la période (Gaudillère avant 1870, TRF-GIS 1870-1940, le
ministère après 1986), le fond communal (ANR-COMMUNES, et GEOFLA quand des
communes sont en repli). Tout se règle dans l'objet `COMMONS`, en tête du
second `<script>` d'`index.html` : catégories, sources, chambres, palette.

**Les catégories sont vérifiées en direct** : ✓ existe, ↪ catégorie redirigée,
✗ absente — avec, pour celles qui manquent, des suggestions de Commons à
cliquer. Celles de `COMMONS.categories` sont des propositions, pas des
certitudes : elles n'ont pas pu être vérifiées à l'écriture. *Une catégorie
qui n'existe pas ne produit pas d'erreur, elle range le fichier nulle part.*
Le nom de fichier est vérifié de même (libre / existe déjà).

Nom, description et catégories sont modifiables ; une retouche est gardée tant
qu'on ne change pas d'unité, de niveau, d'année ou de type de carte
(« réinitialiser » revient à la proposition). « télécharger le SVG » marche
sans rien configurer.

### Paragraphe pour Wikipédia

Sous le formulaire, un second champ donne en wikicode le paragraphe d'article
qui va avec l'image, sur le modèle de :

> À compter de 1946, Paris comprend trois circonscriptions, sur les six que
> compte le [[Seine (département)|département de la Seine]].
> * [[Première circonscription de la Seine (Quatrième République)|1re circonscription]] :
>   [[5e arrondissement de Paris|5e]], … et [[15e arrondissement de Paris|15e arrondissements]]

| carte | paragraphe |
|---|---|
| circonscriptions du département | une puce par circonscription : ses arrondissements de Paris et ses cantons (« (partie) » pour un canton coupé), ou à défaut de couche cantonale — avant 1870 — son nombre de communes |
| situation d'une circonscription | une phrase : « la 1re circonscription de … comprend les cantons de … » |
| cantons du département | une puce par canton, avec son nombre de communes |
| situation d'un canton | ses communes, toutes liées, et sa circonscription |

« lister les communes » remplace les nombres par la liste liée. Le texte se
retouche à la main comme les autres champs ; « copier » le met dans le
presse-papiers.

**Les liens sont vérifiés sur fr.wikipedia** (route `/commons/wikipedia` de
`servir.py`, lecture publique, sans jeton). Chaque lien porte des titres
candidats — `Antony (Hauts-de-Seine)` puis `Antony`, `Canton de Sceaux (Seine)`
puis `Canton de Sceaux` ; le premier qui existe, n'est pas une page d'homonymie
et, redirection suivie, mène bien à un canton (ou une circonscription, un
arrondissement) est retenu, et la redirection est remplacée par sa cible. Un
`Canton d'Asnières` redirigé vers la commune n'est donc **pas** pris pour un
lien bleu. Ce qui reste rouge est listé sous le texte ; « retirer les liens
rouges » les remplace par du texte simple.

Les titres des circonscriptions hors Ve République portent un suffixe de
régime (`COMMONS.regimesWiki`) : seul « (Quatrième République) » est attesté,
les autres sont des paris que la vérification tranche — les circonscriptions
d'arrondissement de 1876-1919 (« Beaune-1 ») ne sont pas liées du tout,
Wikipédia n'ayant pas de convention pour elles.

**Les noms de communes viennent du COG 2012**, pas de GEOFLA : `communes.json`
porte `MIREBEAU-SUR-BEZE`, et un titre de Wikipédia est sensible à la casse et
aux accents. `python3 cartes/web/noms_cog.py` écrit `donnees/noms_cog.json`
(code INSEE → nom typographié, article compris) depuis
`sources/cog/2012/france2012.txt` ; la page ne s'en sert que si le nom en
capitales concorde, et signale les noms qu'elle a dû deviner.

### Carte d'une liste de communes (AOP, intercommunalité…)

Ajoutée le 6 octobre 2026. Le troisième niveau du dialogue, **liste de
communes**, ne dépend ni du département ni de l'année affichés : on colle une
liste — une commune par ligne, ou séparées par des virgules —, la page la
résout, charge le ou les départements qu'elle touche et dessine l'une de deux
images :

| image | contenu | nom proposé |
|---|---|---|
| **carte des communes** | les départements touchés en grisé, leurs communes en trait blanc, celles de la liste en rouge ; en médaillon, la France des départements, ceux de la liste en rouge | `AOP Époisses (localisation).svg` |
| **situation en France** | la France des départements, ceux de la liste rosés, les communes en rouge | `AOP Époisses (localisation en France).svg` |

**Saisie.** Noms (casse, accents, article et « St- » indifférents) ou codes
INSEE ; « Nom (21) » ou « Nom (Côte-d'Or) » lève une homonymie, et le champ
« limiter aux départements » la lève pour toute la liste. Un homonyme qui
reste est d'abord départagé par les départements des communes sûres (une
liste bourguignonne qui dit « Saint-Romain » ne parle pas de la Vienne) ;
sinon la page propose ses départements, et un clic écrit le code devant le
nom, dans la liste même. Sous la liste : trouvées, communes nouvelles,
homonymes, introuvables, sans forme à la date, doublons.

**Noms d'aujourd'hui, base de 2012.** Une liste d'AOP ou d'intercommunalité
se donne avec les communes en vigueur ; la base parle le COG 2012.
`fonds_communes.py` rejoue les mouvements de `sources/v_mvt_commune_2025.csv`
postérieurs au 1ᵉʳ janvier 2012 et écrit `donnees/cog_actuel.json` : une
commune nouvelle (Valforêt, Haut Valromey, Cherbourg-en-Cotentin) est dessinée
par les communes de 2012 qu'elle réunit, et la description le dit. Un code
INSEE se lit comme un code d'aujourd'hui : `01187` est Haut Valromey, pas
Hotonnes — pour Hotonnes seule, l'écrire en toutes lettres.

**Le fond est celui d'une année** (« limites communales de », par défaut la
dernière de la base). Une commune y est l'ensemble des atomes que la
composition de cette année rattache au dossier et qui portent son code —
Premeaux *et* Prissey pour Premeaux-Prissey ; une commune absorbée avant 2012
se cherche par son nom. Passer par la composition n'est pas un luxe : les
fichiers d'un département tiennent aussi les communes qu'il a perdues (la
Seine-et-Oise garde Corbreuse après 1968). Sans composition à la date, toutes
les communes du fichier sont dessinées, et la note sous l'aperçu le dit. Une
année ancienne ajoute l'année au nom du fichier et les catégories d'histoire.
Le dossier suit l'époque : une commune de l'Essonne est cherchée en
Seine-et-Oise avant 1968, de Corse-du-Sud en Corse avant 1976.

**Le contour départemental** est pris dans `contours.json`, qui n'est pas une
suite de frontières mais l'union des communes de chaque composition — trouée
quand celle-ci est incomplète (la Côte-d'Or perd 125 km² en 1955). On retient
le plus étendu de l'époque de la date. Même règle pour **le médaillon**
(`donnees/france.json`, simplifié à 800 m), sur quatre époques seulement : avant
1871, 1871-1918, 1919-1967, depuis 1968 — les seules où la carte des
départements change à cette échelle. Avant 1870 la base n'a pas de contour :
le médaillon montre la France de 1870, et l'aperçu le signale.

**L'outre-mer** est dans `france.json` aussi, chaque département dans sa case,
empilées en bas à gauche sur l'Atlantique, chacune à sa propre échelle (et
simplifiée quatre fois moins que la métropole). Les cases paraissent dans le
médaillon et sur la situation en France à partir de la départementalisation
(1946, Mayotte 2011). Une liste de communes d'outre-mer marche comme une autre :
la carte des communes est celle du département, le médaillon le colore dans sa
case. Les communes partagées entre cantons que la base ne découpe pas
(Saint-Denis de La Réunion) ne sont rattachées à aucun canton : une commune est
donc retenue soit par la composition de l'année, soit par son code INSEE quand
celui-ci désigne le dossier à cette date.

**Le médaillon** se pose dans le coin le plus vide ; si aucun ne l'est (moins
de 4 % couvert), l'image s'élargit à droite, ou en bas pour une carte en
largeur. Une commune de quelques pixels est marquée d'un point rouge, et son
nom posé à côté.

**Description et catégories** : nature (appellation d'origine,
intercommunalité, autre — `COMMONS.natures`), nombre de communes, liste par
département, source de la liste (champ à remplir : l'aperçu le rappelle tant
qu'il est vide, et la description porte « à préciser »), sources du COG. Les
catégories viennent de `COMMONS.natures` et de `COMMONS.categoriesListe`
(« Maps of {dep} » par département) : des propositions, vérifiées comme les
autres. Le paragraphe pour Wikipédia liste toujours les communes, liées.

### Mettre en place le dépôt

Le procédé est celui de
[parliamentdiagram](https://github.com/slashme/parliamentdiagram) : la page
fabrique l'image et le wikitexte, le serveur local détient le jeton et parle à
l'API (`commons.py`, appelé par `servir.py`). Mais là où parliamentdiagram, en
service public, passe par le flux OAuth 1.0a complet, la page tourne ici pour
une seule personne : un **jeton OAuth 2 « owner-only »** suffit, approuvé sur-le-champ.

1. Sur meta.wikimedia.org,
   [proposer un consommateur OAuth 2](https://meta.wikimedia.org/wiki/Special:OAuthConsumerRegistration/propose/oauth2) :
   cocher *This consumer is for use only by …* ; droits *Edit existing pages*,
   *Upload new files*, *Upload, replace, and move files*.
2. Copier l'**Access token** affiché à la fin (il n'est montré qu'une fois).
3. `cp cartes/web/commons.toml.exemple cartes/web/commons.toml`, y coller le
   jeton. Le fichier est dans `.gitignore`.
4. Relancer `servir.py`. Le dialogue affiche « Dépôt sous le compte … ».

Pour un premier essai sans rien publier, mettre
`api = "https://test-commons.wikimedia.org/w/api.php"` dans `commons.toml` —
le dialogue signale alors « API de test ».

**Avertissements.** Si Commons répond qu'un fichier de ce nom existe déjà, ou
que le contenu est le doublon d'un fichier existant, le dialogue l'affiche et
propose « déposer quand même ». Comme dans parliamentdiagram, le serveur
n'accepte `ignorewarnings` que pour le couple (nom, contenu) qui vient de
recevoir cet avertissement : la page ne peut pas forcer un écrasement d'elle-même.

**Le jeton dépose sous ton nom, et n'importe quelle page ouverte dans le même
navigateur peut envoyer une requête à 127.0.0.1.** `servir.py` refuse donc les
routes `/commons/…` à toute autre origine que la sienne, et n'accepte que du
`application/json` — qu'un site tiers ne peut pas envoyer sans une requête
préalable CORS à laquelle le serveur ne répond pas.

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
INSEE** — même règle que `archives/planches/cartes_cantons.py` : « un code est une reconstruction,
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
donnees/noms_cog.json               code INSEE → nom typographié (noms_cog.py)
donnees/cog_actuel.json             communes 2025 → codes 2012 (fonds_communes.py)
donnees/france.json                 médaillon : départements simplifiés, par époque (fonds_communes.py)
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
