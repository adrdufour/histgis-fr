# Ce qui reste à faire

**Arrêté au 6 septembre 2026, file d'attente mise à jour le 24 septembre, puis le 11 octobre (point 0 et § 1 quater).** Les tâches sont classées par valeur, pas par
facilité. Le blocage est indiqué quand il y en a un : beaucoup de choses
attendent quelque chose plutôt que quelqu'un.

> Ce fichier a été condensé le 2 septembre 2026, puis de nouveau le
> 6 septembre. Il dérive en journal dès qu'on l'oublie : la même tâche
> reparaissant dans plusieurs tableaux avec des états différents, et des
> dizaines de lignes barrées qui racontent au lieu de dire quoi faire.
> **Ce qui est fait n'y figure plus** — c'est le rôle de `JOURNAL.md`, qui
> garde tout à sa date, et d'`ETAT.md`, qui dit où en est chaque couche.
> Seul ce qui reste ouvert est ici.
>
> *Le ménage du 6 septembre a retiré onze lignes barrées de la file d'attente
> — l'anneau de `84`, la fratrie contiguë, la trappe du vide, le déblocage de
> `38`, les deux exports, `environment.yml`, `.gitignore` — et deux sections
> entières devenues fausses. Rien de ce qui suit n'est fait.*

---

## 0. La file d'attente immédiate

Dans cet ordre, et **tout ce qui suit demande la base**. Rien n'est bloqué par
une source à trouver : ce sont des commandes à lancer et des sorties à lire.

| # | tâche | pourquoi maintenant |
|---|---|---|
| 0 | **Réexporter la carte, puis la promouvoir** | `110` (691 périodes) et `111` sont dans la base : `p111_trace` compte 40 lignes (20 `modifie`, 20 `insere`), mesuré le 11 octobre au soir — cette ligne disait « à rejouer », il l'a été. Mais le dernier export, `sorties/part_2026-10-11`, s'est achevé à 6 h 13, **avant** la pose de `110` (12 h 21) ; et `cartes/web/donnees`, la carte servie, date du 10 octobre et en diffère. Aucun des deux ne montre `110` ni `111`. Détail : § 1 quater |
| 1 | **Ce qui reste des trous cantonaux 1941-1998 — de la lecture, plus de règle** | Trois reports par les deux bouts, sur des jalons jugés par la géométrie (`96`) : `93` 29 841 lignes (1941-1953), `97` 30 453 (1941-1967), `95` 24 041 (1969-1998). Restent au 23 septembre au soir : **`95` 1 426 désaccords**, dont 109 trous corses d'« autre numéro » (le décret n° 73-825 n'est lu qu'à 15 lignes) ; **`93` 150 désaccords** ; les désaccords de `97` que l'annexe VII annonce (Metz-Campagne → Rombas, Belfort-Centre → Danjoutin…) ; les **échanges croisés** que `96` ne voit pas (Falaise-Nord/Sud, Issoudun-Nord/Sud : un bloc mal lu ensemble se touche lui-même) ; les fractions ; les « accord mais nommé ». Mesures : `diag_deux_bouts_1969_1999.sql`, `diag_deux_bouts_1955_1967.sql`, `diag_corse_1976.sql` |
| 2 | **Achever le dépouillement du recensement de 1954** | `94` l'a chiffré le 6 septembre : le jalon ne couvre que **79,0 %** des communes vivantes en 1940, et les **7 870 manquantes vivaient** — ce n'est pas de la mortalité, c'est de la lecture. Vaut 102 310 atome-années sur la seule fenêtre 1941-1953, plus le jalon lui-même, plus le report vers 1962 à venir. **Premier levier de toute la période.** Voir § 1 bis |
| 3 | **Afficher `repris` dans `cartes/web/index.html`** | l'export pose `repris` par unité à côté de `anr` et `repli` ; la page l'ignore. Une unité qui doit sa forme à une reprise doit pouvoir le dire, sans quoi la légende laisse croire à une trame entièrement attestée. **Seul point de cette file qui ne demande pas la base** |
| 4 | **Où est passé le sol des 318 ?** | ils ne sont PAS sans géométrie — `diag_sans_geometrie.sql` en a trouvé zéro le 5 septembre. Ils sont absents du **résultat** de `carte_partition_atome`, pas des tables qu'elle lit : un polygone entièrement recouvert par un mieux classé perd toutes ses faces. La question utile est « à qui leur sol a-t-il été donné ? », § 6 du même fichier, à coller dans une session où `diag_partition.sql` vient de matérialiser `d84`. Si le sol est repris à ~100 %, **la carte n'a pas de trou : elle a un défaut de légende** |
| 5 | **La couture entre départements vaut 0,019 km² et non 0** | 1,9 ha ne tranche pas entre « des lisières » et « un vrai doublon parmi des lisières ». Jouer le § 9 de `sql/diag_partition.sql`, qui nomme les paires et porte une colonne `deux_reprises`. Mesuré au passage : le triple don d'Anthé et Thézac existait dans la règle, pas sur la carte — `partition_un_dep` ne rend que les atomes `dedans`, et elles habitent le 47 |
| 6 | **Rendre au banc de `84` une entrée qui ne soit pas sa propre sortie** | son entrée est devenue sa sortie ; il ne peut plus rien réfuter. Les règles se mesurent en SQL contre la base |
| 7 | **Var : ranger Toulon-Est et Toulon-Ouest dans les circonscriptions de 1958** | sorti de `113` le 19 octobre 2026 : les fractions de Toulon posées par `116` portent ces deux cantons en 1958, que l'atlas (Toulon-1 en 4e, Toulon-2 en 3e) ne range pas. Adrien tranchera en faisant le Var : un alias dans `circo/composition_1958.py`, puis ce script et `113` rejoués |

**Avant et après chaque point, `psql -d histgis -f sql/diag_passages.sql`** —
lecture seule. Il dit quels fichiers sont réellement passés, lesquels ont une
trace vide, et relit `38` et `39` par leur effet — seconde lecture, indépendante
de leurs traces.

**Depuis le 22 septembre 2026, `histgis` se reconstruit par la chaîne et
seulement par elle** : `cd sql && ./rebuild.sh && ./rejouer_apres_rebuild.sh`,
sauvegarde `pg_dump -Fc` d'abord (celle du 22 est dans `build/`). Un fichier
joué à la main doit entrer dans le script le jour même, sans quoi le prochain
rebuild l'efface sans rien dire.

### `81` est joué — 6 septembre 2026, et l'attendu écrit ici était faux

**32 842 rattachements, 191 866 atome-années, du 1969-01-01 au 1985-03-10.**
Toutes les recettes de refus à zéro : § 6 aucune fenêtre même partiellement
occupée, 11 a zéro atome à deux cantons, 11 b les trois écarts nuls (`79`
intact), 11 c et 11 d à zéro.

**Ce fichier annonçait « si 1974 bouge, `81` a mordu sur `79` et il faut
s'arrêter ». 1974 a bougé — 5 198 → 9 771 — et `81` n'a mordu sur rien.**
La supposition sous-jacente était que la borne de la plupart des départements
serait la salve du 23 septembre 1973 ; le § 3 mesure une profondeur **moyenne
de 6,3 ans** depuis 1969, donc 1975, et une borne la plus haute au 1985-03-10.
Les 4 573 rattachements de plus sont de la couverture neuve, pas un
recouvrement — ce que disent le § 6 (zéro écarté) et le 11 b (`ecart_79` = 0).

***Une recette qui annonce un nombre supposé apprend à ignorer ses propres
alarmes.*** L'attendu est corrigé dans `81` § 11 f et ici. Et un détail de
lecture qui a failli passer : le relevé d'avant et celui d'après ne partagent
qu'**une seule date**, 1974 — « 1989 → 23 236 » puis « 1990 → 23 236 » ne sont
pas deux mesures du même point.

Couverture après coup : 1969 → 32 842, 1972 → 32 774, 1974 → 9 771,
1976 → 9 135, 1980 → 9 135, 1985 → 21 534, 1990 → 23 236.

Trois départements sous 85 % de jamais-nommés, et ce sont ceux qu'on attendait :
**20, 91, 95** — la Corse et l'éclatement de la Seine-et-Oise, pas un trou du
registre. 40 départements et 14 844 lignes ont un premier acte jamais dépouillé :
la borne est juste, la composition de l'acte est inconnue.

### La chaîne va jusqu'à `84` — complété le 6 septembre 2026, jamais joué

`rejouer_apres_rebuild.sh` s'arrêtait à `40_scission_circo`, c'est-à-dire au
20 août. **Vingt-deux étapes qui écrivent dans la base n'y figuraient pas** :
les deux jalons de recensement (`58`-`60`, `65`-`69`), le registre des actes
(`72`), les salves (`74`-`77`), les deux reports (`79`, `81`), la trame ANR
(`82`), la Seine de 1815 à 1967 (`87`-`91`), Paris 1848 (`57`) et la partition
(`84`). Leurs traces étaient en base : elles avaient été jouées à la main.

**Un `rebuild.sh` les aurait toutes effacées sans que rien n'échoue** — la base
se serait reconstruite, plus petite, en silence. C'est la mécanique qui a défait
`39` pendant quinze jours en août, à une tout autre échelle.

Elles sont désormais dans le script, dans l'ordre du § 1 c de `sql/CHAINE.md`,
avec leurs `-v`, leur `-1` là où le fichier le demande, et **un quatrième
prérequis qui ne vivait qu'en commentaire** : `anr_commune`, la couche du
GeoPackage ANR chargée par un `ogr2ogr` écrit dans l'en-tête de `82` et par
aucun script. `82`, `89`, `90`, `91` et `84` lèvent tous une `EXCEPTION` sans
elle. C'est le quatrième cas après `noms_geofla`, les tables parisiennes,
`geofla_canton` et les lots d'outre-mer.

**Ce qui est vérifié, et ce qui ne l'est pas.** Hors base : `bash -n`, existence
de chaque fichier cité, et le contrôle qui compte — *tout fichier
`sql/[0-9]*.sql` qui écrit dans la base est appelé par un script* ; les
vingt-neuf qui restent dehors sont tous en lecture seule. En base : **rien.**

Deux recettes propres à cette complétion, au premier passage :

* `diag_passages.sql` doit trouver une trace pour **toutes** les étapes, `25`,
  `37` et `40` compris — les trois qui n'en ont jamais eu ;
* `85_conflit_38_79.sql`, joué sans `-v`, doit trouver **zéro** fraction à
  libérer. Il n'existe que parce que `79` avait été joué après `38` hors de
  toute chaîne ; dans l'ordre du script, `38` passe avant et le § 5 de `79`
  écarte ces six atomes de lui-même. *S'il trouve quelque chose, c'est l'ordre
  du script qui est faux, pas `85`.*

### Ce que `38` laisse ouvert, et c'est une ligne

`38` est passé le 5 septembre — la ville n'est plus coupée par des cantons qui
n'existaient pas. Reste que l'occupant des trois communes entières est `76`, qui
porte un acte du JO plaçant Montagnat et Saint-Just à Péronnas et Saint-Denis à
Viriat au scrutin de mars 1985, donc **postérieur** au décret. Aucun désaccord :
le § 6 de `38` est simplement trop large, et sa borne haute devrait être la date
d'effet de cet acte et non `1999-01-01`.

---

## 0 bis. La carte web — écrit le 6 septembre 2026, à moitié joué

Deux défauts signalés en regardant la carte : « j'ai encore le département 99
Meurthe » et « je voudrais pouvoir afficher les outre-mers ». Le second est
**joué** ; le premier ne l'est pas, et **aucun export n'a tourné**. Le récit est
dans `JOURNAL.md` au 6 septembre.

### a. Le 99 fantôme — `sql/92_meurthe_circo.sql`

`39` ne touche que `niveau = 'canton'`. Il reste une unité circo en `99`,
`L9901@1870`, et elle suffit à faire un 99ᵉ département dans l'export. Effet
secondaire, plus gênant que le premier : **la Meurthe de 1870 est coupée en
deux**, ses cantons dans le 54, sa circonscription dans un 99 sans cantons.

```bash
psql -d histgis -f sql/diag_passages.sql        # avant, lecture seule
psql -d histgis -f sql/92_meurthe_circo.sql     # sans `-1` : transaction propre
```

Attendus, tirés de `build/` le 6 septembre 2026 :

| recette | attendu |
|---|---|
| § 3 a — trace | **1 unité**, `L9901@1870` |
| § 3 b — unités en `99`, tous niveaux | **zéro ligne** |
| § 3 c — le 54 au 1ᵉʳ juin 1870 | canton 29 unités ; **circo 1 unité, 714 rattachements** |
| § 3 d — la bascule | `L9901@1870` sur `[1870-01-01, 1871-01-01)`, puis `L5401@1871` |
| § 3 e — atomes à double | **0** |
| § 3 f — atomes du 54 | doit **changer** entre 1870 et 1871 : la Meurthe perd l'est, gagne Briey |

La ligne du § 3 c est celle qui vaut d'être lue : avant ce fichier, la ligne
`circo` est **absente**, et c'est le trou que la planche de 1870 montrait sans
le dire.

### b. L'outre-mer — `cartes/export_web.py --outremer`

Trois différences de modèle interdisaient de réutiliser le chemin
métropolitain : `char(3)` contre `char(2)`, EPSG:4326 contre 2154, et **ni ANR
ni partition**. Un bloc de requêtes et une fonction d'export à part, plus trois
correctifs de page (codes à trois caractères dans le hash, groupes dans le
sélecteur, communes non rattachées dessinées).

**`charger_outremer.sh` et `40_outremer.sql` sont joués depuis le 6 septembre**,
et tout est à l'attendu au chiffre près sauf deux lignes, toutes deux
instruites et closes : la Guyane rend 83 752 km² contre 83 824 attendus
(−0,09 %, ordre de grandeur d'un `ST_MakeValid` sur un très grand polygone), et
**La Réunion affiche 6 circonscriptions en 2012 au lieu de 7**.

La manquante est la 1ʳᵉ, et sa seule commune est Saint-Denis, écartée par
`HAVING count(DISTINCT circo) = 1`. Elle est donc **entièrement contenue dans
une commune elle-même partagée entre deux circonscriptions** : une coupe
intracommunale, la même famille que Paris. Aucun rattachement
commune-par-commune ne peut la porter, quelle que soit la règle de filtrage.

| tâche | valeur | blocage |
|---|---|---|
| **Corriger l'attendu `4+4+2+7` de la recette de `40` en `4+4+2+6`, avec le motif** | forte | aucun ; sans quoi la ligne rejouera l'alarme à chaque passage sans rien apprendre à personne |
| Porter la 1ʳᵉ de La Réunion et les 28 multicantonales | moyenne | c'est le § 2 « villes à découper » transposé outre-mer : trame `iris_om`, à charger par `python3 cartes/recupere_iris_outremer.py --charger` |

*Une unité plus fine que la maille de rattachement ne se perd pas par erreur ;
elle est inexprimable dans le modèle, et c'est une propriété du modèle qu'il
faut déclarer, pas un cas à rattraper.*

### c. Puis l'export, dans cet ordre — le `rm -rf` n'est pas facultatif

```bash
rm -rf cartes/web/donnees/dep/99
python3 cartes/export_web.py 54 --partition --sortie cartes/web/donnees
python3 cartes/export_web.py --outremer
python3 cartes/web/servir.py
```

**Et une passe complète derrière, qui n'est pas dans cette liste par oubli.**
Le dernier export intégral date du 5 septembre à 09 h 49 — **antérieur à la
règle mosaïque de fratrie**, jouée le même jour. Les 98 départements portent
donc l'ancienne trame, celle où une seule des six filles de Tournon-d'Agenais
est dessinée et où Bourlens vaut 73,5 km² pour un repli de 15,6. La correction
est en base ; elle n'est sur aucune carte.

```bash
bash cartes/export_partition.sh                 # 98 départements, ~3,75 Go
```

**Pourquoi le `rm -rf` d'abord.** Un export partiel conserve dans l'index racine
tout département dont `dep/<code>/index.json` existe encore — c'est ce qui
empêche un export d'un seul département d'effacer les 97 autres du sélecteur.
Le corollaire est qu'un département devenu faux **survit à sa correction** : le
99 resterait dans la liste, avec ses fichiers, alors que la base n'en a plus.
*Un mécanisme qui protège ce qu'on n'a pas touché protège aussi ce qu'on vient
de supprimer.*

**Attendus de l'export.** Le 54 doit passer de `{"1870": {"c": "…", "x": ""}}` à
un `x` non vide, et `dep/99/` ne doit pas réapparaître. `--outremer` doit écrire
5 dossiers, annoncer 129 communes et **nommer Mayotte** comme servant zéro
année — si ce message manque, c'est que `40` a posé des rattachements qu'on ne
lui connaît pas, et il faut regarder pourquoi avant de se réjouir.

Le dossier portera alors **deux trames**, `partition` en métropole et
`geofla2015` outre-mer. L'export le dit (`trame: mixte` dans l'index racine,
détail dans `trames`), et ce n'est pas un défaut : `84` ne traite que la
métropole et ANR ne couvre pas l'outre-mer.

### d. Ce que la vérification hors base ne peut pas dire

Le banc (`python3 cartes/banc_export_web.py`, § 8) fait jouer l'export
d'outre-mer sur un faux curseur : il contrôle la tuyauterie — atomes écrits,
signatures qui pointent sur des fichiers existants, Mayotte non escamotée,
formes qui ne commencent pas avant la départementalisation. Il ne juge **aucune
géométrie**. Restent à voir sur la carte, et seulement là :

* la **coïncidence** des contours cantonaux dissous et des limites communales
  outre-mer — c'est le premier usage de `ST_SnapToGrid` en degrés dans ce
  dépôt, et la propriété qu'il garantit tient à ce que la même grille serve aux
  deux, pas à sa valeur métrique ;
* le **cadrage** des cinq départements, la projection de la page se recalant sur
  la bbox — un archipel étalé sur deux degrés n'a jamais été affiché ici ;
* **Mayotte dessinée sans couleur**, avec son bandeau « communes dessinées,
  aucun rattachement ». C'est le seul endroit où l'on verra si le correctif de
  page fait ce qu'il annonce.

---

## 1 quater. Après les JO lus et leurs tables annuelles — 11 octobre 2026

`110` a posé 691 périodes dans les trous (JO lus à la main, tables analytiques
annuelles du JO 1941-1990) ; `111` corrige les périodes que les transferts
démentent. Ce qu'ils laissent, du plus rentable au moins :

| tâche | ce qu'on sait | où |
|---|---|---|
| **Les 202 communes de cantons recomposés qu'aucun bord ne nomme** | presque toutes de Seine-et-Oise, 1964-1967 : les unités de ces cantons n'existent pas en base entre l'éclatement annoncé et 1968. Les créer (unités et versions), puis rejouer `110` | `sorties/p110_evenements.csv`, issue « aucun bord ne porte le nom du JO » |
| **Les 50 communes de cantons recomposés, « place occupée »** | `111` ne traite que les transferts. Même instruction à faire pour les recompositions : la base contredit-elle le JO, ou l'a-t-elle simplement devancé ? | idem, issue « place occupée » |
| **Les 177 transferts isolés introuvables dans les tables** | 274 non datés, 97 retrouvés. Le reste : artefacts de la base (un report qui a mal lu un bord) ou noms que l'OCR des tables 1941-1957 a trop abîmés (colonnes encore mêlées). Commencer par ceux dont les deux bords sont des jalons (1954, 1968) | `cantons/mouvements_cantonaux.csv` moins `cantons/dates_par_tables_jo.csv` |
| **Prouver l'absence d'acte par les tables** | les tables retrouvent 228 des 233 décrets de création et de recomposition connus : leur silence pour un (département, année) vaut présomption d'absence. Reste à en tirer une liste et à la donner aux reports comme « rien n'a bougé » attesté. Moins sûr pour les rattachements avant 1958 | `cantons/tables_jo_actes.csv`, `cantons/rappel_tables.csv` |
| **Deux transferts laissés par `111`** | Orgerus (78) : la base la met en 7815, code qui a été L'Isle-Adam puis Montfort-l'Amaury ; Ferreux (10) : « Romilly-sur-Seine » contre « Romilly-sur-Seine 1er canton », le numéro fait échouer la comparaison | à la main |
| **Corse 1975 : 7 communes sans unité** | Ajaccio, Bastia, Bonifacio : cantons de la loi 75-356 qui n'ont pas d'unité en base | `110` § 6 bis |
| **Rejouer dans le bon ordre** | `111` raccourcit des périodes de `79`, `81` et de la base d'origine. Rejouer un report, puis `110`, puis `111` ; rejouer `110` seul : défaire `111` d'abord | `sql/README.md`, « Qui dépend de qui », § 3 |
| Restes de la lecture des JO | le décret 68-168 et la table des changements de nom de 1985 ne sont pas lus | `cantons/wikipedia/lecture_jo.md` |

## 1 ter. L'intervalle noir entre les deux reports — 1 072 dép-années

> **Mis à jour le 23 septembre 2026.** Mesuré dans la base par
> `diag_intervalle_noir.sql`, le trou valait 357 788 atome-années et s'ouvrait
> en **1974**, au scrutin qui suit la salve de 1973 — pas en 1986. `95` en a
> comblé 93 % par l'accord des deux bouts (voir `JOURNAL.md`). Ce qui suit est
> l'analyse d'avant, gardée pour la trace ; ce qui reste est au point 1 du § 0.

Mesuré par `81` § 11 g, au premier passage réel : **15 départements sur 87 sont
couverts de bout en bout de 1969 à 1999 ; 72 ne le sont pas**, et le total des
fenêtres noires vaut 1 072 département-années. Elles se situent entre le
plafond de `81` (le premier acte postérieur à 1968, en moyenne 1975) et le
plancher de `79` (le dernier acte antérieur à 1999) — c'est-à-dire **1975-1986**,
la fenêtre que la carte montre le plus mince, et celle que `76` ne date que par
convention à 93,7 %.

C'est le poste le plus gros de toute la période, et il ne demande aucune source
neuve : ce sont les 86 actes non dépouillés, les 62 cantons annoncés au titre
d'un décret et jamais lus, et le chaînage acte par acte sur les 54 départements
intégralement dépouillés (§ 1). **La différence avec avant le 6 septembre est
qu'on sait maintenant combien ils valent et où ils sont.**

| tâche | valeur | blocage |
|---|---|---|
| **Lister les 72 départements et leur fenêtre noire** | forte | aucun — `p81_borne` porte `borne` et `plancher_de_79`, la requête est le § 11 g sans le `GROUP BY` |
| Attaquer les plus longues d'abord | forte | dépend du précédent ; le mur 1986-1989 (§ 1) en est probablement le cœur |
| **Le recensement de 1975** | forte | même série que 1962 et 1968, à chercher de la même façon (§ 1 bis) — il tomberait au milieu de l'intervalle noir |

---

## 1 bis. Sous 1954 — les deux fenêtres qui renvoient encore le vide franc

`ETAT.md` § 2.3 dit « plus aucune date entre 1954 et 1999 ». Sous 1954, il en
reste deux.

### 1941-1953 — `93` est joué, et son refus est le chantier

**29 686 rattachements, 385 885 atome-années, posés le 6 septembre 2026.**
Toutes les recettes à zéro ; les couches 1940, 1954, 1968 et circo intactes.
Le § 4 bis retrouve **98,78 % d'accord sur 26 544 comparables** — les deux
nombres exacts de `70`, par un autre fichier, ce qui vérifie que `93`
sélectionne bien la population que `70` avait mesurée. `ferme_canton` rend
100,00 %, comme il le doit.

Les onze moitiés basses de décret sont posées, les deux communes de Tende
n'ont aucun atome en 1940 : le § 5 est exactement à l'attendu.

**Ce qui reste vide, par ordre de valeur** (§ 10 du fichier) :

| classe | atomes | atome-années | ce qu'il faudrait |
|---|---|---|---|
| **absent du relevé de 1954** | **7 970** | **103 610** | ouvert par `94` — voir ci-dessous |
| fraction | 325 | 4 225 | une convention qui n'existe pas |
| désaccord | 323 | 4 199 | l'arbitrage géométrique de `71`, cas par cas |
| moitié haute des décrets | 11 | ~30 | les renouvellements de 1949 et 1951 dans `scrutin_cantonal` |

### `94` a réfuté l'hypothèse qui l'avait fait écrire — 6 septembre 2026

Les 7 970 devaient mêler des communes **mortes** dans la fenêtre — de la
couverture à prendre, que `93` refusait à tort — et des communes **non lues**.
Mesuré :

| classe | atomes | |
|---|---|---|
| vivante en 1954, non lue | **7 870** | 98,7 % |
| morte dans la fenêtre | 55 | **414 atome-années, 0,4 %** |
| jamais dans le COG | 45 | mortes de 1941-1942 ou sans code moderne |

**Il n'y a pas de § supplémentaire à écrire dans `93`** : le jeu vaut un
millième de ce qu'il a posé. Les 55 sont réelles et bien datées — Brest-2,
Brest-3, Douarnenez, Concarneau meurent en 1945 — mais la vague de fusions est
celle de 1971-1972, pas celle des années 1940. *Un nombre historiquement
plausible est un contrôle.*

**Le § 3 a démenti l'explication qu'il devait confirmer.** La perte de lecture
ne se concentre PAS sur les six départements nommés par `note_1954.md` : ils en
portent 491 sur 7 870, soit **6,2 %**. Elle est répartie sur presque tous les
départements, entre 19 et 42 % de leurs communes — Ariège 42,4 %, Haute-Saône
37,2 %, Jura 34,5 %, Ardennes 32,5 %. **Et le 52, donné pour ABSENT par la
note, ne perd que 30,2 % : cette liste de quatre départements est périmée.**

### La cause est trouvée, et ce n'est ni le scan ni l'OCR — 6 septembre 2026

**Les pages ont été lues ; le parseur perd un quart de leurs lignes.** Sur le
corps du volume (83-888), le brut de `ocr_brut/` porte **41 996 lignes** à trois
chiffres ou plus, l'extraction en retient **31 369** — **74,7 %**. Voilà
pourquoi la perte est uniforme : chaque page en perd une part comparable, donc
chaque département aussi. Les 118 pages absentes du CSV sont les liminaires
(15-82) et les annexes (892-935), pas des pages perdues.

**Ce qui casse est le couple `arrondissement canton`.** L'analyseur attend
`chiffre espace deux-chiffres` ; le scan rend `1 28 → 128`, `2 02 → 2:02`,
`4 22 → 4 2:`, `1 31 → 1: 31`, `1 01 → 1 Ot`. S'y ajoute le point final du nom,
rendu en virgule ou absent.

**Mesuré pour de bon le 6 septembre** par `cog1954/essai_ligne_souple.py`,
lecture seule, qui relâche ce seul séparateur dans la vraie `LIGNE` et vérifie
d'abord que la règle actuelle reproduit le CSV (31 272 retrouvées, **0 en trop**) :

| sur tout le volume | lignes |
|---|---|
| gagnées par la règle relâchée | **4 638** |
| dont **les deux arbitres d'accord** | **3 562** |
| canton attesté, ordre alphabétique non | 939 |
| ordre bon, canton inconnu du département | 83 |

**+11,6 %**, et la couverture du jalon passerait de **79,0 % à environ 88 %**.
Les départements qui gagnent le plus sont exactement ceux que `94` § 3 donnait
pour les plus abîmés : Ariège +39,1 %, Jura +32,8 %, Haute-Marne +28,8 %,
Haute-Saône +26,4 %, Doubs +26,2 %.

> **Correction : ce n'est PAS « le plafond approche les 7 870 »**, comme il
> était écrit ici la veille sur la foi d'une regex de diagnostic qui trouvait
> 5 056 candidates. C'est **la moitié du manque**. La regex ignorait le reste de
> `LIGNE` — l'exigence de trois nombres après le nom, le refus de la
> nomenclature — qui écarte à bon droit une part de ses candidates.
> ***Un outil grossier qui estime un gain l'estime toujours vers le haut : il ne
> porte aucune des contraintes qui font refuser.***

Le reste demande davantage que le séparateur : le `:` tenu pour un chiffre
(« 4 2: » = canton 22), le `t` pour un `1` (« 1 Ot » = 1 01), les noms dont
l'OCR a mangé la première lettre (« 3iyes. »). Chacun élargit la surface
d'erreur — à mesurer séparément, pas à empiler.

**L'assouplissement ne coûte rien à la rigueur** : deux arbitres indépendants
existent déjà — la nomenclature cantonale du département et le dictionnaire de
noms. Une ligne lue « 128 » se tente en « 1 28 » et se fait valider ou refuser.
C'est la méthode du dépôt : relâcher la lecture, laisser une source extérieure
arbitrer, comme `71` a arbitré par la géométrie.

**La recette qui jugera le correctif est double, et le second terme commande** :
la couverture doit monter depuis 79,0 %, **et le taux d'accord du § 4 bis de
`93` — 98,78 % — ne doit pas baisser**. *Un parseur plus permissif qui gagne de
la couverture en perdant de l'accord achète du volume avec des erreurs, et rien
d'autre ne le dirait.*

| tâche | valeur | blocage |
|---|---|---|
| **Porter le séparateur relâché dans `extrait_1954.py`** — l'essai est fait, le correctif tient en une ligne de `LIGNE` | **la plus forte de la période** | aucun — pas de téléchargement, pas d'OCR à refaire. Une décision, pas un chantier |
| Puis rejouer `extrait_1954.py`, `65`-`69`, `93`, `94` § 5 | forte | dépend du précédent ; **la recette est en deux termes** — couverture 79,0 % → ~88 % ET accord de `93` § 4 bis maintenu à 98,78 %. Surveiller l'Indre : +25,5 % de lignes et déjà le plus bas accord (94,4 %) |
| Les trois substitutions restantes (`:` chiffre, `t→1`, nom amputé) | moyenne | à mesurer une par une avec `essai_ligne_souple.py` ; chacune élargit la surface d'erreur |
| **Dépouiller les NOTES DE BAS DE PAGE du volume de 1954** | forte, et sans rapport avec la couverture | elles datent des rattachements cantonaux au décret — « Par décret du 19 juillet 1952, la commune de NEUVILLE-SAINT-AMAND, qui était rattachée au canton de… ». C'est la matière que `72` ne trouve pas pour les années 1940-1950, et le type de mouvement que l'annexe VII ne consigne jamais |
| Corriger `note_1954.md` : ni « 161 pages muettes » ni « quatre départements absents » n'expliquent la lacune | forte | aucun ; la note envoie chercher là où ce n'est plus |

**Deux choses à instruire, petites mais nommées :**

* **Les 15 atomes `hors_c54` s'accordent à 26,67 %**, contre 98,78 % ailleurs —
  soixante-douze points d'écart. Hypothèse : ce sont pour l'essentiel des
  communes de la Seine, où l'accord 1940/1954 est structurellement bas (10,0 %
  au § 6 ter de `66`, l'éclatement de 1968 ayant renuméroté autant que
  redécoupé), dont les quatre que `87` a rendues au jalon sans ligne de
  qualité. **À vérifier, pas à supposer :**

  ```sql
  SELECT v.dep, count(*), count(*) FILTER (WHERE v.verdict = 'accord')
    FROM histgis.p93_verdict v WHERE v.appariement = 'hors_c54' GROUP BY 1;
  ```

  Si ce n'est pas la Seine, c'est que des lignes de 1954 entrent en base sans
  passer par `c54_qualite`, et il faut savoir par où.

* **Deux lignes portent `chrono_trouee`**, toutes deux dans l'Eure et toutes
  deux au canton de Saint-André-de-l'Eure (atomes `36094` et `5768`) : l'INSEE
  leur donne une disparition puis un rétablissement dans la fenêtre. Réserve
  déclarée, rien n'a été retiré. *Ne jamais refermer un tel trou d'office* —
  c'est la faute commise sur Cherré.

**Les départements les plus bas sont ceux qu'on attendait, et c'est le
contrôle le plus parlant de la journée.** 36 (94,4 %) et 14 (96,0 %) sont
l'Indre et le Calvados, c'est-à-dire **Issoudun-Nord/Sud et Falaise-Nord/Sud**,
deux des trois échanges croisés que `71` avait isolés comme des confusions de
lecture entre les deux moitiés d'un même chef-lieu. 19 (94,9 %) et 46 (97,2 %)
sont la Corrèze et le Lot — Brive-Sud et Sousceyrac, dont `70` § 3 annonçait
que le report DOIT s'y tromper. *Les quatre premiers désaccords du classement
étaient prédits, chacun par un fichier différent.*

### 1955-1967 — le jalon de 1962 est en ligne

C'était la fenêtre la plus dure : deux bouts attestés, mais **89,80 %** d'accord
entre eux, le plus mauvais des trois intervalles mesurés. Un report simple y
poserait des lignes fausses qu'aucune recette interne ne distinguerait des
vraies.

**Trouvé le 6 septembre 2026** — et `cog1954/note_1954.md` disait « à chercher » :

> *Recensement de 1962. Population du département... Arrondissements, cantons
> et communes*, INSEE — **domaine public**, ensemble **BnSP002**, celui des
> fascicules de 1968. Un fascicule par département.
> <https://www.bnsp.insee.fr/ark:/12148/bd6t53571595>

| tâche | valeur | blocage |
|---|---|---|
| **Énumérer les arks des fascicules de 1962** | forte | la vérification anti-robot de Gallica — `fetch_inspect.py` et son en-tête de navigateur, à la main, comme le 21 août pour 1968 |
| Vérifier que le tableau III porte bien le code de canton par commune | forte | dépend du précédent ; c'est le dispositif de 1968, à confirmer sur pièce et non par analogie |
| Puis la chaîne de `58`/`59`, telle quelle | forte | `extrait_1954.py --pdf … --dep …` accepte déjà les fascicules départementaux |
| Reporter 1954 → 1962 et 1962 → 1968 sur le modèle de `93` | forte | dépend du jalon |

---

## 1. Cantons 1943-1999 — étendre la couverture

Le trou n'en est plus un (`ETAT.md` § 2.3), mais la couverture reste molle
entre les jalons.

| tâche | valeur | blocage |
|---|---|---|
| **Rétroporter `pct_jamais_nommes` et son dénominateur dans `p79_qualite`** | forte | aucun — `p81_qualite` le porte déjà |
| **Poser sur la part libre des fenêtres partiellement occupées** | 289 atomes récupérables | aucun ; la règle « tout ou rien » coûte désormais plus qu'elle ne protège |
| Le **chaînage acte par acte** sur les 54 départements intégralement dépouillés | forte | prendre un numéro libre : `82` est pris par ANR |
| Second tour sur la classe « modification de limites cantonales » | moyenne | 25 actes fixent encore un plancher ; le premier tour a rendu +18 %, pas +37 % |
| Un **troisième jalon : le recensement de 1975** | forte | au milieu des 1 147 dép-années noires ; la chaîne de `59` se réutilise telle quelle |
| Les **86 actes non dépouillés** | moyenne | file au § 7 bis de `80` : 91 (6), 54 (5), 59 (5), 38 (4), 92 (4), 76 (4) |
| Les **62 cantons annoncés au titre d'un décret et jamais lus** | moyenne | c'est là que se joue le rappel de l'extraction : 122 sur 184 |
| Poser le transfert de **Han-devant-Pierrepont** | faible | `77` a lu la modalité 43, celui-ci est en modalité 41 |
| Les **24 actes dont le JO manque** (13 numéros) | faible | ils ne bloquent rien, ils enrichiraient les compositions |

**Réserve permanente à ne pas oublier** : *un décret nomme les cantons qu'il crée
ou modifie, jamais ceux qu'il vide.* Tout chaînage acte par acte hérite de ce
biais, dont le sens est connu — il joue contre l'hypothèse, ce qui rend un
accord élevé plus solide qu'il n'en a l'air, et un accord faible ambigu.

**La part `sous_plafond` se retire en une requête** si elle est un jour jugée
trop risquée :

```sql
DELETE FROM histgis.membership m USING histgis.p79_qualite q
 WHERE q.membership_id = m.membership_id AND q.sous_plafond;
```

### Le mur 1986-1989

37 actes, aucun texte en clair sur Légifrance, aucun dépouillé,
`composition_jo.csv` s'arrête à 1988 avec cinq lignes. C'est aussi la fenêtre des
**48 cantons créés entre 1986 et 1999**, nommés un par un et non datés. PDF du JO
requis, même chaîne que `composition_jo.py`.

À ne pas refaire : la veine 1990-1999 est **épuisée, pas inexploitée**. Les 83
décrets de la décennie ont été lus — 19 portent une composition (en base par
`76`), 4 déplacent une commune entière (posés par `77`), 40 transfèrent des
parcelles (non-événements), 29 sont des tracés de rues, 10 sont sans texte.
*Une année absente d'un fichier de sortie n'est pas une année non lue.*

---

## 2. Les villes à découper — 119, l'outillage est posé, une ville en banc d'essai

> **Mis à jour le 24 septembre 2026.** `98_coupe_ville.sql` (joué le 23 au soir,
> dans la chaîne) charge les coupes depuis deux CSV versionnés —
> `cartes/coupes_ville.csv` et `cartes/coupes_ville_ancres.csv` — et découpe
> au tirage, par des **lignes** et non des polygones : voir son en-tête pour le
> pourquoi. `cartes/pont_qgis.py` monte le plan de travail d'une ville dans le
> QGIS ouvert. **Une seule ville est saisie, Vienne (38544), et c'est un banc
> d'essai à refaire** : la ligne suit des grands quartiers INSEE qu'aucun texte
> n'établit comme limite cantonale. `iris_ville`, que le paragraphe plus bas
> dit « acquise et en base », avait été emportée par un `rebuild.sh` ; elle est
> désormais rechargée par la chaîne. Le reste de la section date d'avant.

C'est le plus gros chantier manuel restant, et le seul qui ne dépende d'aucune
source à trouver.

| tâche | valeur | blocage |
|---|---|---|
| **Marseille** : géoréférencer et digitaliser dans QGIS | forte | travail à la main ; protocole dans `gaudillere/protocole_georeferencement.md` |
| Puis lancer `sql/32_marseille_geom.sql` | — | dépend du précédent |
| Mesurer le **taux de reprise réel** ville par ville | forte | disposer d'une ligne n'est pas disposer de la bonne |
| Les 118 autres villes | forte | même travail |

**La trame d'accrochage est acquise et en base** : `histgis.iris_ville`,
4 219 IRIS, les 119 villes servies, **211 des 214 coupes** pourvues d'au moins
une ligne interne. Marseille reçoit 393 IRIS et Lyon 185, pour 11 et 12 coupes —
les deux villes les plus coûteuses sont les mieux dotées.

Trois villes sans appui, une coupe chacune : **Confolens** (16106), **Tartas**
(40313), **Le Quesnoy** (59481) — un seul IRIS, donc aucune ligne interne. Deux
en trame juste suffisante : Saint-Flour (15187) et Avesnes-sur-Helpe (59036).

**Ce que la trame ne prouve pas** : les IRIS sont calés sur la voirie et les
îlots, pas sur les limites cantonales — sauf à Paris, où l'INSEE les cale
explicitement sur les limites de quartier. Ailleurs c'est un support
d'accrochage : des lignes propres, topologiquement valides, calées sur des rues
réelles, où l'on choisit au lieu de dessiner.

ADMIN EXPRESS v4 (2025) reste utile comme **fond de calage, pas comme économie** :
26 % des coupes internes seulement (123 offertes sur 472 requises ; Nantes en
demande 17 et 2025 en offre 1).

---

## 3. Circonscriptions

| tâche | valeur | blocage |
|---|---|---|
| **Marquer les 113 communes indéterminées de 1986 sur la carte** | forte | aucun — voir ci-dessous |
| **Contrôler la couche circo** par les §§ 1, 3, 4 et 6 de l'annexe VI | forte | aucun : ce sont les seules sections qui ne passent pas par les cantons |
| Contrôle indépendant de la couche moderne | forte | les contours publiés sur data.gouv.fr peuvent jouer le rôle que GEOFLA a joué pour les cantons |
| Le découpage de **1958** hors Paris — ce que `113` n'a pas posé | moyenne | 68 départements posés le 13 octobre. Restent, par cause (`circo/composition_1958_etat.csv`) : **cantons divisés**, à descendre à l'atome avec les notes de l'atlas déjà recopiées (13, 33, 37, 38, 62, 69, 76, 90) ; **trame cantonale de 1958 absente de la base** (61, 71, 72, 73, 74, 77) ; **lecture à reprendre** (06, 44, 59, 68, la Corse de 1978) ; **à rephotographier** : Seine-et-Oise 1958-1967 de plus près, Jura et Haute-Saône, absents. Puis les 31 « DOUTE » de `circo/regles_1958_1986.py` à relire sur l'original, et le tableau de l'ordonnance n° 58-945 à confronter |
| **Paris en 1986** | moyenne | demanderait une autre source que le tableau de l'Intérieur |
| Les 8 atomes coupés entre circos sans l'être entre cantons | faible | il faudrait des atomes-fractions taillés sur les circonscriptions |

### Les 113 indéterminées — un défaut d'affichage, pas de données

De 1987 à 1999 la couche cantonale est mince, et c'est celle des
circonscriptions qui dessine les communes : ces 113 **disparaissent purement et
simplement** de la carte. Le projet a une règle explicite — *ce qui n'a de nom
nulle part est signalé comme tel, pas maquillé* — et une absence silencieuse la
contredit.

**À faire** : charger `circo/circo_1986_indetermine.csv` dans une table
`circo_indetermine`, et les faire dessiner par `export_web.py` avec un figuré
propre (hachure, comme les communes coupées), les circonscriptions candidates au
survol. **Aucun rattachement dans `membership`** : la source ne tranche pas, la
base ne doit pas trancher non plus.

**Piste de résolution, à évaluer séparément** : pour chacune, les
circonscriptions candidates sont connues, et le découpage de 2009 rattache la
commune à l'une d'elles. Là où les limites n'ont pas bougé entre 1986 et 2009, le
rapprochement serait dicté par la source — même forme d'argument que la voie
`fraction` de `41`. À mesurer avant d'y toucher, et à ne poser que si la
correspondance est unique.

---

## 4. Paris

**Acquis** : 80 quartiers reconstruits par union d'IRIS en Licence Ouverte,
80/80 noms confirmés par l'atlas, 386 circonscriptions sur 15 divisions,
1958-1986 posé, `paris_circo.pdf` généré.

| tâche | valeur | blocage |
|---|---|---|
| **Les quartiers coupés par une rue** — 3 à 9 par division, 9 pour 1958-1986 | forte | axes BD TOPO à récupérer |
| Dater la période `?-?` — 37 circonscriptions complètes, sans date | moyenne | pièces à trouver |
| La trame d'avant 1860 — 48 quartiers, 12 arrondissements | moyenne | **licence** : ALPAGE-Vasserot couvre exactement les 48 quartiers mais est en ODbL. Route propre : géoréférencer un plan du XIXᵉ en domaine public, protocole de Marseille |
| Corriger la coquille de `paris_decoupage.xlsx` | faible | aucun — en 1857-1863, `montdepietemarais` fusionne deux quartiers en une cellule, d'où 47 au lieu de 48 |

### 4 bis. La banlieue de la Seine — ouvert le 6 septembre 2026

Le 75 est entier de 1870 à 1940 (100 atomes) et se réduit à Paris à partir de
1945 : les **80 communes de banlieue n'ont plus aucun rattachement circo**.
Leur géométrie, elle, ne manque pas. Voir `circo/note_seine.md`.

**Acquis le 6 septembre 2026** : `87` à `91` joués. La Seine est continue de
1815 à 2012 ; 1866 rend 479,64 km², la Seine entière ; les planches nomment les
onze annexées dans les circos parisiennes. Voir `circo/note_seine.md` et
`circo/note_seine_1815_1870.md`.

| tâche | valeur | blocage |
|---|---|---|
| **Les onze annexées sont blanches en 1815-1820 et 1831-1848** | forte | mesuré sur l'export le 6 sept. : Passy, Auteuil, Montmartre, Belleville, Vaugirard… ne sont dessinées ni à 1817 ni à 1840. Dans `91` elles portent le côté `annexee`, qui ne rejoint que la division `tout` (1820-1831) ; les deux autres divisions partagent la banlieue entre les collèges de Saint-Denis et de Sceaux, et **aucun côté ne leur a été donné** — elles n'ont jamais eu de canton en 1954. Le comblement tient en onze lignes ajoutées à `circo/seine_arrondissements.csv` ou à `seine_annexees_circo.csv`. **Lecture à faire sur les planches 1815 et 1831-1848** : de quel côté de la limite Saint-Denis/Sceaux tombent Passy, Auteuil, Batignolles-Monceau, Montmartre, La Chapelle, La Villette, Belleville, Charonne, Bercy, Grenelle et Vaugirard ? La planche donne la règle — « séparés par la Seine à l'Ouest et la rue de Lagny à l'Est » — ce qui mettrait Grenelle et Vaugirard à Sceaux et les autres à Saint-Denis, **Bercy restant douteuse** (rive droite mais au sud de la rue de Lagny). À ne pas trancher par déduction géographique |
| **Confronter la transcription au JO** | forte | Légifrance ne reproduit pas les tableaux annexes de 1946 et de 1958 ; la transcription vient d'une synthèse tierce |
| **`circo/seine_second_empire.csv` n'est lu par rien** | moyenne | relevé le 6 septembre : aucun `.sql` ni `.py` du dépôt ne le charge. Soit il double une source déjà posée par `91` et il faut le dire, soit il porte une transcription qui n'est jamais entrée en base — les deux se ressemblent tant qu'on ne l'a pas ouvert |
| Confirmer la stabilité cantonale 1945-1968 | moyenne | la composition n'est lue qu'à 1954 et projetée ; 17 communes sur 80 en dépendent en 1958, les 80 en 1945-1958 |
| **L'anneau vide de 1860-1863** | moyenne | les annexées meurent en 1859, la division parisienne de 1857-1863 porte sur les 48 quartiers de Vasserot : 24 km² non dessinés. Basculer Paris sur la trame des 80 au 1ᵉʳ janvier 1860 — changement dans `55` |
| Rendre le sol à la mère jusqu'à la naissance de la fille | moyenne | **mesuré le 6 sept. : 367 atomes, 4 572,2 km².** Le report arrière de `11` n'est PAS à fermer — il comble ; c'est l'identité du dessin qu'il faut corriger, pas la couverture. Voir `sql/diag_report_arriere.sql` |
| Belleville en 1857-1863 | faible | l'atlas déclare sa propre ligne « purement arbitraire » ; à laisser nommée et non attribuée |
| 1941-1945 — l'Occupation | faible | rien de transcrit, ni Paris ni banlieue |
| 1968-1985 — la banlieue passe aux 92, 93, 94 | moyenne | ces départements n'ont aucune couche circo |
| Renommer « Paris 1e à 3e » de 1945-1958 en « Seine » | faible | aucun, mais c'est modifier de la donnée existante : passage à part |

---

## 5. ANR-COMMUNES — la migration est faite à côté, pas à la place

Chargé et contrôlé en base le 1ᵉʳ septembre : `atom_geom_anr`, 45 113 polygones
datés, 38 074 atomes pourvus, recouvrement **101,0 km² contre 3 945**.
`atom_geom` et `membership` n'ont pas été touchés.

| tâche | valeur | blocage |
|---|---|---|
| **Décider du sort de la double trame** | forte | `atom_geom` garde ses 3 945 km² ; faut-il migrer, ou garder les deux et documenter ? décision, pas travail |
| **Signaler à l'équipe ANR** : Beauvais, Flipou/Senneville, la Corse sans édition historique, les 3 `Poly_ID` à double fenêtre, les **532 trous de chronologie**, et **le territoire du Perreux** | moyenne | aucun |
| Décider du sort des 6 atomes doublons qu'ANR tranche (`a82_doublon`) | faible | décision |

**Le territoire du Perreux**, trouvé le 6 septembre en cherchant 3,81 km²
manquants sur la Seine : Nogent-sur-Marne vaut 4,19 km² sur `[1790,1860)` puis
6,76 sur `[1860,1887)`, et Le Perreux naît en 1887 avec 3,96. Interrogé à 1848,
ANR rend `PERSONNE` sur ce point — **le sol dont Le Perreux naîtra est sans
propriétaire pendant soixante-dix ans.** À joindre à la liste ci-dessus.

**Ce qu'ANR ne réglera pas, et il faut le savoir** : les 333 fractions. ANR livre
le polygone de la commune-mère entière et ne sait pas la découper entre deux
cantons. Le chantier du § 2 reste entier.

**Le verrou neuf, pour l'extension avant 1870** : ANR ignore la frontière
nationale (`ETAT.md` § 5). C'est le premier obstacle à lever pour 1815.

---

## 6. Extension avant 1870

Ouvert, non commencé hors Paris. Gaudillère est la source principale. La
géométrie ne coûte plus rien — `82` a chargé tout ANR, 1790-2020, donc 1815 est
déjà dessiné (39 157 polygones, recouvrement 144,8 km²) — **ce qui manque, ce
sont les attributions et la frontière.**

À 1815, **10 259 polygones ne sont pas terminaux** : ANR affirme pour eux une
forme pré-moderne précise au lieu de projeter celle d'aujourd'hui. C'est du
contenu, et il est là où nous n'avons rien.

---

## 7. Dettes et démarches

| tâche | état |
|---|---|
| **Envoyer le rapport à Victor Gay** — `cantons/rapport_pour_victor_gay.md` | rédigé, à relire et envoyer ; il a demandé le détail des comparaisons |
| Y joindre les deux paris que HAC lui conteste | Le Theux (08447) et Sognolles-en-Montois (77454), donnés en accord par HAC aux deux niveaux |
| Reprendre Houat et Hœdic avec les bons codes | `45` § 5 filtre sur `insee_geofla` ; 17501 et 17191 sont des identifiants d'atome, pas des codes INSEE |
| Confirmer la licence Cassini EHESS auprès du CRH avant publication | la CC BY 3.0 FR est portée par la notice du dépôt, pas par le site |
| CRH-EHESS et INSEE : relancer ? | courriels du 10 août sans réponse |
| Regrouper les scripts de 1954 et 1968 sous un nom générique | faible, ils font désormais le même travail |

---

## 8. Chantiers ouverts, à mesurer avant d'écrire

Rien ici ne doit être corrigé d'office. Ce sont des cas où la mesure décide.

### Les trous intérieurs courts apparus après `46`

Avant `46`, les trous de `membership` se répartissaient en deux groupes nets :
**2 ans** (Cherré, corrigé) et **48 ans** (l'Alsace-Moselle, qui doit rester
ouverte). Après, des durées intermédiaires apparaissent — 2, 4, 5, 7, 9, 18 ×2,
27, 35, 39 ×2 ans, soit une dizaine d'atomes.

Hypothèse la plus simple : `46` pose une fenêtre qui **ne rejoint pas** le
premier rattachement propre de la commune, sa borne étant
`min(création selon HAC, premier rattachement propre)` — TRF-GIS connaît
Neuilly-Plaisance dès 1882, HAC la crée en 1892, et l'écart reste vide.

**À faire** : lister ces atomes avec leur commune et les deux dates de création.
Si l'hypothèse tient, deux voies, et il faudra choisir **en le disant** : combler
jusqu'au premier rattachement propre, ou laisser le trou et **déclarer le
désaccord de dates** entre HAC et TRF-GIS. La seconde est cohérente avec le
reste du projet — on préfère un trou déclaré à un rattachement inventé.

**Ne pas refermer d'office** : c'est exactement la faute commise sur Cherré, où
un trou de deux ans enregistrait une absorption réelle.

### Les autres absorptions anciennes suivies d'un rétablissement

Le signe est un trou intérieur dans la chronologie d'un atome ; la requête de
détection est en § 4 de `44_absorption_ancienne.sql`. Mesuré le 20 août :
1 690 trous côté canton, 1 684 côté circo, dont 1 689 et 1 683 de 48 ans qui sont
l'Alsace-Moselle. Le seul autre est Cherré, traité.

**Ne jamais refermer un tel trou d'office** : il faut trouver l'acte, nommer
l'absorbante, et ajouter une ligne sourcée à `absorption_ancienne`. Un trou peut
être borné par la même unité alors que l'absorbante relève d'un autre canton —
le résultat serait juste ici et faux ailleurs.

**Piste** : HAC documente les fusions antérieures à 1943 et est déjà une source
du projet. Elle permettrait de peupler `absorption_ancienne` sans passer par des
articles au cas par cas.

**Angle mort connu, qu'aucune recette ne voit** : une commune omise en **fin** de
série ne laisse pas de trou intérieur, sa période s'arrête simplement plus tôt.

### Ventiler les 108 km² entre rural et urbain

Point de finition sans enjeu. `13` § 3 a établi la ventilation avec l'ancienne
clé `code_2011`, sur 3 837 km² ; les 108 km² que la clé géométrique restitue n'y
sont pas répartis — Lyon (47,85) ira du côté urbain, les 60,18 restants sont à
classer. Rejouer `13` § 3 sur `cle_geom` suffirait. L'ordre de grandeur ne
bougera pas.

---

## 9. Voies explorées et fermées — à ne pas rouvrir sans raison neuve

| voie | verdict | date |
|---|---|---|
| **HAC comme source de filiation pour `11`** | essayé, mesuré, **abandonné** : 11 paris perdus sur 425 contre 4 sur 414. HAC ne nomme qu'une mère quand il y en a plusieurs | 20 août |
| **Les transferts de communes lus dans le volume de 1954** | 311 candidats, 227 réfutés par la géométrie, les survivants indiscernables du bruit | 14 août |
| **`ID_GEOFLA.tab`, `insee_former.do`** | l'un est la table attributaire du shapefile, l'autre de l'harmonisation de noms | — |
| **L'appariement par nom contre le COG 2005** | abandonné au profit des mouvements INSEE, traçables ligne à ligne | — |
| **Le pseudo-découpage appliqué à Paris 2009** | mesuré puis écarté : il relierait 17 des 18 circonscriptions parisiennes en une seule composante | — |
| **ADMIN EXPRESS comme trame de découpe** | 26 % des coupes ; CONTOURS-IRIS lui est supérieur d'un ordre de grandeur | 11 août |
| **Cassini-Geopeuple, quartiers de la Ville de Paris, ALPAGE-Vasserot** | licences incompatibles (CC BY-NC-SA, ODbL) quelle que soit la qualité de la donnée | — |

### Le détail du point 4 — deux problèmes sous un seul nombre

*Rangé ici et non dans la file : ce qui suit est une voie fermée — la question
« pourquoi n'ont-ils pas de géométrie ? » a reçu sa réponse, qui est qu'elle ne
se posait pas. La question ouverte, elle, est au point 4 de la file.*

Les 318 atomes sans géométrie à 1870 ne sont pas une population homogène. La
requête suivante ne demande pas la partition et répond en quelques secondes :

```sql
SELECT a.fraction, count(*)
FROM  (SELECT DISTINCT m.atom_id FROM histgis.membership m
        WHERE m.periode @> '1870-12-01'::date) v
JOIN   histgis.atom a ON a.atom_id = v.atom_id
WHERE  NOT EXISTS (SELECT 1 FROM histgis.atom_geom ag
                    WHERE ag.atom_id = a.atom_id)
  AND  NOT EXISTS (SELECT 1 FROM histgis.atom_geom_anr g
                    WHERE g.atom_id = a.atom_id
                      AND g.periode @> '1870-12-01'::date)
GROUP  BY 1;
```

**Les fractions** posent une question de chaîne, mais **pas celle qui était
écrite ici jusqu'au 5 septembre 2026.** La rédaction précédente disait :
« `05_geom.sql` donne à chaque atome-fraction le polygone de sa commune-mère,
et ceux-là ne l'ont pas reçu ». Les deux moitiés sont fausses, et il vaut mieux
le savoir avant de chercher.

* **`05_geom.sql` ne connaît pas les fractions.** Il ne cherche aucune mère : sa
  première insertion joint `atom.insee_geofla` à `geofla_commune.insee_com`
  pour tous les atomes indistinctement. Une fraction reçoit le polygone de sa
  commune parce qu'elle **porte le même code INSEE**, pas parce qu'une règle
  est allée le chercher. Le mot « mère » n'apparaît pas dans le fichier.
* **Le code INSEE ne manque à aucune fraction.** Relevé sur `build/atom.csv` :
  **333 lignes portent un `#`, les 333 portent un code INSEE** au format
  attendu par le `CASE` de `02_load.sql` § 3 — aucune vide, aucune valant 1, 2
  ou 3, les valeurs de `com_act` qui partagent la même colonne et auraient
  laissé `insee_geofla` à NULL.

**Et la mesure a tranché plus largement encore.** `diag_sans_geometrie.sql`,
joué le 5 septembre 2026, cherche les atomes vivants à 1870 qui n'ont ni
`atom_geom` ni polygone ANR à la date — les trois sources de `84`, la reprise
exigeant elle-même un repli. **Il en trouve zéro.**

Les 318 ne sont donc pas des atomes sans géométrie. Ce sont des atomes
**absents du résultat de `carte_partition_atome`**, ce qui n'est pas la même
chose — et le § 8 de `diag_partition.sql` affirmait pourtant le contraire en
toutes lettres (« ils manquaient déjà »). Son titre et sa légende sont corrigés.

Où ils se perdent : `partition_un_dep` finit par
`t84_src JOIN t84_prop JOIN net`, et un atome ne ressort que si son
propriétaire a gagné **au moins une face**. L'arbitrage du § (d) donne chaque
face à un seul propriétaire, dans l'ordre `est_repli`, `aire`, `pid` : un
polygone entièrement recouvert par un mieux classé perd tout. C'est le cas
attendu d'une fille reportée en arrière par `11`, dont le repli GEOFLA se
superpose au polygone ANR de sa mère intacte — les 393 superpositions franches
que `84` documente en tête.

**La question utile n'est plus « pourquoi n'ont-ils pas de géométrie ? » mais
« à qui leur sol a-t-il été donné ? »**, et elle ne se pose qu'à la partition.
La requête est au § 6 de `diag_sans_geometrie.sql`, écrite pour être collée
dans une session où `diag_partition.sql` vient de matérialiser `d84`. Si le sol
est repris à presque 100 %, **la carte n'a pas de trou : elle a un défaut de
légende** — un canton perd des communes à l'affichage sans perdre de surface.

*Une population définie par « absente du résultat d'une fonction » n'est pas
celle définie par « absente des tables qu'elle lit ». Les deux se disent avec
la même phrase française, et c'est tout le piège.*

**Les non-fractions** posent une question de source : commune disparue avant
2011, donc pas de GEOFLA, et ANR qui ne la pourvoit pas à cette date.
**Goutrens** en est le cas type, et referme le trio du § 8 de `82` dont les deux
autres — Sébazac-Concourès et Roches-Prémarie-Andillé — sont dans les replis.

*Un même symptôme — « rien à dessiner » — recouvre ici un défaut de chaîne et
une limite de source. Les compter ensemble empêche de traiter l'un ou l'autre.*
