# Le registre des mouvements cantonaux — consolidé

`cantons/consolide_registre.py` produit `cantons/mouvements_cantonaux.csv` :
**2 024 lignes, 95 départements.** Il remplace la saisie manuelle, conservée
sous `mouvements_cantonaux.saisie_manuelle.csv` comme témoin.

## Le principe

Deux sources qui ne se recouvrent pas, croisées sur le nom du canton d'arrivée :

* **la base** sait QUELS mouvements ont eu lieu et QUELLES communes ils
  déplacent — c'est le différentiel 1940→1999 de `33_diff_cantonal.sql`,
  généralisé aux 95 départements ;
* **l'annexe VII de Gaudillère** sait QUAND, au décret près, mais ne nomme
  aucune commune et s'arrête au découpage de 1986.

Aucune des deux ne suffit. Ensemble elles donnent un mouvement daté et peuplé.

## Le résultat

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

## Les cinq statuts

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

## Le piège du cadre départemental

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

## La double mesure du post-1986

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

## Ce que l'appariement a coûté

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

## Ce que le registre ne dira pas

L'ordre des mouvements à l'intérieur d'un même décret. Et les créations suivies
de suppressions qui se compensent : Bourg-en-Bresse est divisée en 1973 puis
redivisée en 1982, le différentiel 1940→1999 n'en montre que le résultat.

`annexe_vii.csv` porte cette chronologie intacte et reste la référence pour
l'histoire ; ce fichier-ci pour la géométrie.
