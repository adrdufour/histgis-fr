# Note de lecture — le découpage électoral de Paris, 1815-1986

Source : `paris_decoupage.xlsx`, transcription manuelle.
Mise au propre : `circo/extrait_paris.py` → `circo/paris_decoupage.csv`.

## Ce que ce fichier change

Paris avait été **déclaré irréductible** : aucune trame administrative ne
permettait de poser ses circonscriptions, puisque certaines coupent les
quartiers. Ce fichier lève le blocage. Il donne la composition **par quartier**
de dix-neuf divisions électorales successives, de 1815 à 1986, et il nomme les
rues là où un quartier est coupé.

Deux acquis distincts :

1. **Le trou parisien de 1986** se comble. La couche posée par `28` exclut
   Paris, faute de source ; le tableau de l'Intérieur ne descend pas sous la
   commune.
2. **Le découpage de 1958-1986 devient accessible.** Nationalement il est
   bloqué par le trou cantonal 1941-1998, puisqu'il se définit par cantons.
   Mais à Paris il se définit par quartiers. C'est **le premier morceau de 1958
   qui peut être posé**, sans attendre la nomenclature cantonale.

## La recette de couverture : elle passe

Une division électorale doit partitionner la ville. Testé sur les douze
divisions postérieures à 1860, contre le référentiel des 80 quartiers
administratifs :

| division | quartiers cités | absents | inconnus |
|---|---|---|---|
| 1876-1881 | 80 | 0 | 0 |
| 1881-1885 | 80 | 0 | 0 |
| 1889-1893 | 80 | 0 | 0 |
| 1893-1898 | 80 | 0 | 0 |
| `?-?` | 80 | 0 | 0 |
| 1902-1910 | 80 | 0 | 0 |
| 1910-1914 | 80 | 0 | 0 |
| 1919-1928 | 80 | 0 | 0 |
| 1928-1940 | 80 | 0 | 0 |
| 1945-1958 | 80 | 0 | 0 |
| 1958-1986 | 80 | 0 | 0 |
| 1986 | 80 | 0 | 0 |

**Douze divisions, 110 ans, aucun quartier oublié ni inventé.** La
transcription est complète. C'est une garantie de cohérence, pas d'exactitude :
elle ne dit pas que chaque quartier est dans la bonne circonscription.

Le vocabulaire lui-même se sépare proprement en deux systèmes — les quartiers
d'avant 1860 et les 80 d'après —, ce qu'aucune consigne n'imposait.

## Ce que le tableur avait abîmé

**La numérotation, détruite par Excel.** De 1876 à 1940 une circonscription se
note `2/11` — 2ᵉ du 11ᵉ arrondissement. Excel a lu ces cellules comme des
dates. La perte est réversible, le mois portant la circonscription et le jour
l'arrondissement, et `extrait_paris.py` la défait. **Reformater la colonne en
texte** avant tout nouvel enregistrement.

**Un doublon strict.** Le libellé `1928-1940` couvrait deux blocs de 37
circonscriptions identiques ligne à ligne. Un seul est conservé.

**Douze coquilles**, chacune attestée par la coexistence des deux formes dans
le fichier : `art et metiers`, `chaussé d'antin`, `enfant rouges`, `faubourg
montmarte`, `la vilette`, `maisons-blanche`, `marché`, `montmarte`, `porte
saint-denis`, `rochechouar`, `saint aveye`, `saint-marguerite`. Noter que la
coquille est souvent **plus fréquente** que la forme correcte : la fréquence ne
décide de rien, seul le référentiel officiel tranchera, par jointure.

**Trois virgules manquantes**, qui collaient deux quartiers en un seul jeton :
`grandes-carrières-clignancourt`, `jardin-des-plantes val-de-grace` et
`mont de piétémarais`.

> **Attention — divergence entre le tableur et le CSV, 21 août 2026.**
>
> La troisième, `mont de piétémarais` (ligne 225, période 1857-1863,
> 6ᵉ circonscription), a été corrigée **directement dans
> `paris_decoupage.csv`**, dédoublée en `mont-de-piété` et `marais`.
> Sauvegarde de l'état antérieur : `paris_decoupage.csv.avant_virgule`.
>
> Critère retenu, celui du projet : les deux formes existent ailleurs dans le
> fichier, cinq fois chacune. Ce n'est pas une reconstitution, c'est un
> dédoublement attesté.
>
> **`paris_decoupage.xlsx` n'a pas été touché.** Le prochain
> `extrait_paris.py` effacera donc la correction. Deux issues : reporter la
> virgule dans le tableur, ou faire porter la correction par
> `extrait_paris.py` lui-même, à côté des douze coquilles qu'il traite déjà.
> La seconde est plus sûre — elle survit à une réédition du tableur.

## Ce qui reste ouvert

### 1. Une division sans date — `?-?`

Le libellé `1893-1898` couvrait deux divisions réellement différentes. La
première est la bonne pour 1893-1898 (confirmé) : le 4ᵉ arrondissement a deux
circonscriptions, le 16ᵉ une seule. La seconde inverse exactement ces deux
points — 4ᵉ fusionné, 16ᵉ dédoublé — et **sa période est inconnue**. Elle sort
sous `?-?`, déclarée plutôt que devinée.

Le sens du mouvement est cohérent avec la démographie : le 4ᵉ se dépeuple, le
16ᵉ se remplit. Un redécoupage postérieur à 1898, donc, mais la date doit venir
de la source.

### 2. Le 11ᵉ arrondissement : la remarque contredit la numérotation

De 1889 à 1940, le 11ᵉ a trois circonscriptions. Les données donnent :

- `1/11` : saint-ambroise, la roquette, sainte-marguerite
- `2/11` : saint-ambroise, la roquette, sainte-marguerite — **à l'identique**
- `3/11` : la folie-méricourt, seule

Or la remarque dit que le boulevard Voltaire séparait « **la 2ᵉ et la 3ᵉ**
circonscription du 11ᵉ ». Si elle a raison, la numérotation est décalée : les
deux circonscriptions jumelles devraient être la 2ᵉ et la 3ᵉ, et la
Folie-Méricourt être la 1ʳᵉ.

La remarque est la plus spécifique des deux et provient d'une observation
séparée : elle est probablement la bonne. Mais c'est une correction à valider
sur la source, pas à appliquer d'autorité.

### 3. Une seule coupure vraiment non documentée

Sur 38 quartiers partagés entre deux circonscriptions :

- **18** relèvent du 11ᵉ et sont couverts par la remarque du boulevard Voltaire ;
- **17** ont leur rue de partage nommée ;
- **2** ne sont pas des partages mais des **doublons de saisie** :
  `ecole-militaire` figure deux fois dans la même circonscription, en 1958-1986
  (circo 5) et en 1986 (circo 3) ;
- **1** reste sans explication : **les épinettes**, coupées entre les circos 23
  et 24 en 1958-1986. La remarque voisine ne nomme que les Batignolles.

Une seule inconnue sur 110 ans de découpages, c'est peu.

## Comment poser ces circonscriptions

La méthode est celle de Marseille, transposée.

**La trame** : les 80 quartiers administratifs, stables depuis 1860, dont la
Ville de Paris publie la géométrie en **Licence Ouverte** — compatible avec la
contrainte de licence du projet.

**Les coupures** : ne pas tracer les circonscriptions, mais découper le
quartier concerné par les axes nommés dans les remarques, puis recomposer. Les
axes viendront de la **BD TOPO** de l'IGN, en Licence Ouverte depuis 2021 —
et non d'OpenStreetMap, dont l'ODbL est un partage à l'identique incompatible
avec CC BY-SA.

**Les atomes** : comme à Marseille, l'overlay de toutes les coupures sur toute
la série donne des cellules à géométrie stable, dont seul le rattachement
varie. Pas de nouvel atome par période, pas de dimension temporelle à ajouter
à `atom_geom`.

## Ce que ça ne règle pas

Les divisions de 1852 à 1870 portent la mention **« rattaché hors-paris »** sur
sept circonscriptions : elles débordaient de la ville. Sans le détail des
communes suburbaines concernées, elles resteront incomplètes. C'est hors de la
période couverte par la base, donc sans urgence.

Les divisions antérieures à 1860 s'appuient sur l'ancien système de quartiers,
qui demandera sa propre trame — à traiter avec l'extension vers 1815, pas
avant.

---

# La trame géométrique — posée le 11 août 2026

`circo/paris_quartiers.py` → tables `iris_paris`, `paris_quartier` ;
contrôle dans `circo/paris_quartiers.csv`.

## Le chemin, et pourquoi il fallait le chercher

Le jeu de quartiers de la Ville de Paris est en **ODbL**, incompatible avec la
contrainte du projet. La trame vient donc d'ailleurs.

**CONTOURS-IRIS** (coédition INSEE-IGN) est en **Licence Ouverte 2.0**. Pour
les communes découpées en IRIS, les deux premiers caractères du numéro d'IRIS
désignent le grand quartier ; et à Paris, l'INSEE cale les limites d'IRIS sur
les limites d'arrondissement, **les limites de quartier** et les tronçons de
rue. Les 80 quartiers se reconstruisent par simple union, sans arbitrage :

    code_iris = 751 + AA + QQ + NN
                      |    |    +-- rang de l'IRIS dans le quartier
                      |    +------- quartier, 01 à 80, continu sur la ville
                      +------------ arrondissement

992 IRIS extraits par WFS, 80 quartiers, 4 par arrondissement, 20
arrondissements.

## Le contrôle qui compte

Les 80 noms tirés de l'INSEE, confrontés au vocabulaire de la transcription de
l'atlas. Deux sources qui n'avaient jamais été en contact :

| motif | n |
|---|---|
| direct | 68 |
| article ajouté | 6 |
| article retiré | 2 |
| orthographe | 2 |
| abréviation (Roule) | 1 |
| renommage (quartier 54) | 1 |
| **total** | **80 / 80** |

**Aucun écart de trame. Douze écarts de nom, tous expliqués.** L'article défini
se promène d'une source à l'autre et dans les deux sens — « Les Halles » contre
`halles`, « Roquette » contre `la roquette` : huit cas réglés par une règle,
sans table ni arbitrage.

### Deux acquis produits par la confrontation

**Le quartier 54 a été renommé.** L'atlas compte dans le 14e Montparnasse,
Plaisance, Petit-Montrouge et **Santé** ; l'INSEE écrit Parc-de-Montsouris.
`sante` a 14 occurrences, toujours dans le 14e, de 1863 à 1986. Ce n'est pas un
désaccord entre les sources : c'est une information que leur rapprochement
produit.

**Les deux systèmes de quartiers se distinguent d'eux-mêmes.** `roule` compte
14 occurrences, toujours dans le 8e, de 1863 à 1986 : c'est le quartier 30,
abrégé. Mais `le roule` en compte 5, sans arrondissement, et seulement de 1815
à 1863 — **c'est un autre quartier, celui d'avant 1860.** La séparation du
vocabulaire relevée plus haut sans explication trouve ici sa raison.

## La surface

Union des quartiers **105,43 km²**, Paris dans GEOFLA **104,90 km²**, écart
0,53 km². La superficie officielle de Paris bois compris est de 105,4 km² :
c'est l'union des IRIS qui a raison et GEOFLA qui rogne, sa généralisation
lissant les berges et les limites des bois. **La trame posée ici est plus fine
que celle sur laquelle tourne le reste de la base** — à ne pas oublier au
moment de recouper les deux.

## Ce que cette trame ne couvre pas

**Elle ne vaut qu'à partir de 1860.** Le bois de Boulogne n'entre dans Paris
qu'en 1852 et celui de Vincennes en 1860 : les quartiers 63-64 et 47-48
n'existent pas sous cette forme auparavant. Et la trame d'avant 1860 est de
toute façon un autre système, celui des douze arrondissements et de leurs
quarante-huit quartiers, dont le vocabulaire est déjà isolé dans
`paris_vocab.csv`.

**Elle est moderne.** Que les limites d'IRIS d'aujourd'hui rendent celles de
1876 est réputé, non vérifié. Le contrôle par les rues, là où une
circonscription coupe un quartier, en donnera l'occasion.

## Où en est le chantier parisien

* trame géométrique des 80 quartiers — **posée** ;
* composition des 19 divisions par quartier — **transcrite et contrôlée** ;
* ~~rattachement des circonscriptions à la trame — à faire~~ — **fait le 11 août
  2026**, et la section suivante le raconte : 386 circonscriptions sur 15
  divisions de 1863 à 1986, chacune rendant les 105,43 km² de Paris entier ;
* quartiers coupés par une rue — à traiter, axes BD TOPO ;
* trame d'avant 1860 — bloquée par la **licence** : ALPAGE-Vasserot couvre
  exactement les 48 quartiers mais est en ODbL, incompatible avec la contrainte
  CC BY-SA du projet. Route propre : géoréférencer un plan du XIXᵉ en domaine
  public.

---

# Les circonscriptions posées sur la trame — 11 août 2026

`circo/paris_circo.py` → table `paris_circo` ; contrôle dans
`circo/paris_circo_controle.csv`.

**386 circonscriptions, quinze divisions, de 1863 à 1986.** Chaque division
rend 105,43 km² : la surface de Paris, à chaque date. La partition est exacte.

| période | circos | quartiers cités | partagés |
|---|---|---|---|
| 1863-1869 | 9 | 80 | 0 |
| 1869-1870 | 9 | 80 | 0 |
| 1876-1881 | 20 | 80 | 0 |
| 1881-1885 | 27 | 80 | 0 |
| 1889-1893 | 34 | 83 | 3 |
| 1893-1898 | 37 | 83 | 3 |
| 1902-1910 | 40 | 84 | 4 |
| 1910-1914 | 38 | 84 | 4 |
| 1914-1919 | 40 | 84 | 4 |
| 1919-1928 | **3** | 80 | 0 |
| 1928-1940 | 37 | 84 | 4 |
| 1945-1958 | **3** | 80 | 0 |
| 1958-1986 | 31 | 88 | 9 |
| 1986 | 21 | 87 | 8 |
| ?-? | 37 | 83 | 3 |

Quatorze divisions se résolvent sans un nom hors trame — deux de plus que les
douze contrôlées plus haut, qui ne testaient ni 1863-1869 ni 1869-1870.

**Le régime de scrutin se lit dans les chiffres.** 1919-1928 et 1945-1958 ne
comptent que trois circonscriptions pour 80 quartiers : c'est le scrutin de
liste par secteur. Aucune consigne ne l'imposait au tableur ; la donnée le dit
seule.

**1958-1986 est posé.** Nationalement, ce découpage était alors bloqué par le
trou cantonal 1941-1998 puisqu'il se définit par cantons. À Paris il se définit
par quartiers : c'est le premier morceau de 1958 qui existe en géométrie.

> **Nuance du 2 septembre 2026.** Le trou cantonal n'est plus vide : jalons de
> 1954 et 1968, registre des actes, deux reports validés. Le découpage de 1958
> hors Paris redevient donc envisageable — **mais pas gratuit** : la couverture
> cantonale est inégale, et entre 1985 et 1998 la plupart des dates sont des
> conventions et non des faits (`p76_qualite`). Deux autres morceaux sont
> acquis par ailleurs : les **57 circonscriptions de 1986 reprises de 1981**
> (annexe VI § 7), et **Marseille à 87 %** par l'atlas Gaudillère, qui établit
> qu'en 1958-1986 deux arrondissements seulement y sont divisés.

## Le piège des homonymes

Les cinq divisions antérieures à 1860 sont écartées par une barrière de date,
et cette barrière n'est pas une commodité. **Seize de leurs noms se résolvent
quand même** — Arsenal, Notre-Dame, Arcis, Montmartre, Temple — parce que les
deux systèmes de quartiers partagent des noms. Ils ne partagent pas les
territoires : le quartier de l'Arsenal de 1815 n'est pas le quartier 15 de
1876.

Sans la barrière, seize rattachements faux seraient posés, et ils seraient
**invisibles** : géométrie valide, noms plausibles, et une recette de
couverture muette puisqu'elle ne compte que ce qu'on lui donne. C'est
« le roule » contre « roule », en seize exemplaires.

Les 33 clés non résolues sont exactement le vocabulaire d'avant 1860 :
`marches`, `leroule`, `tuileries`, `feydeau`, `lemail`, `saintfustache`,
`temple`, `saintmartindeschamps`, `lombards`…

## Une inférence, déclarée

1914-1919 ne portait qu'une ligne de renvoi : « même découpage et mêmes
appellations que de 1902 à 1910 ». Les 84 lignes ont été matérialisées et
marquées `source = 'renvoi'` dans `paris_circo`. Elles sont déduites d'une note
du livre, non transcrites d'un tableau — et la couche le dit.

## Ce qui reste

* **Les quartiers partagés** : 3 à 9 selon la division, 9 pour 1958-1986.
  L'atlas y nomme les rues ; il faudra les axes BD TOPO pour couper. Le
  chantier est chiffré, et il est petit.
* **La période `?-?`** : 37 circonscriptions complètes mais sans date. Sa
  composition est identique à celle de 1893-1898 sur 83 quartiers — à trancher.
* **L'avant-1860** : autre trame, autre chantier.
