# État de la base `histgis`

**Dernière mise à jour : 11 octobre 2026** — § 1 (les couches posées depuis le
24 septembre) et § 2.3 (les JO lus, leurs tables, `110` et `111`). Le reste du
fichier est celui du 2 septembre, après le chargement d'ANR-COMMUNES et la
réécriture de `export_web.py` : chaque tableau porte sa date de mesure.

Trois documents, trois rôles. **`ETAT.md`** (ici) dit où en est chaque couche
*aujourd'hui* — un état, pas un récit : ce qui est faux est corrigé sur place,
pas ajouté à la suite. **`METHODE.md`** est la référence stable : architecture,
sources, limites, règles de travail. **`JOURNAL.md`** raconte dans l'ordre ce
qui a été tenté, raté et compris ; c'est lui qui porte l'historique, et rien
n'a besoin d'être répété ici pour être conservé. **`RESTE_A_FAIRE.md`** porte
la file d'attente.

> Ce fichier a été condensé le 2 septembre 2026 : il accumulait vingt-cinq
> sections datées où le même chiffre figurait dans trois états successifs sans
> qu'on sache lequel valait. Rien n'a été perdu — le détail de chaque campagne
> est dans `JOURNAL.md` à sa date. Les contradictions relevées au passage sont
> signalées « **à trancher** » ci-dessous plutôt que résolues en silence.

---

## 1. Ce que contient la base

PostgreSQL + PostGIS, schéma `histgis`, EPSG:2154 partout. Elle répond à :
*quelle était la carte des cantons et des circonscriptions législatives
françaises à telle date ?* — cible **1870-2012**, Paris remontant à **1815**.

```sql
SELECT unit_id, nom, geom FROM snapshot_geom('1885-06-01', 'canton');
SELECT unit_id, nom, geom FROM snapshot_geom_anr('1885-06-01', 'canton');
```

### Effectifs, par couche et par origine

Les totaux ne sont pas donnés en bloc, parce qu'aucun ne l'est de façon fiable
sans interroger la base : douze fichiers ont ajouté des atomes et des
rattachements depuis le chargement initial. Ce qui suit est **ce que chaque
étape a posé**, avec sa date de mesure.

| couche | effectif | posé par | mesuré le |
|---|---|---|---|
| chargement 1870-1940 | 38 442 atomes (333 fractions), 4 838 unités, 293 233 rattachements | `01`-`07` | 9 août |
| couverture 1870-1940 | +414 prolongements, +60 atomes-filles | `11`, `15`, `42`, `46` | 17-20 août |
| circo 1870-1940, comblement | 1 003 périodes sur 320 atomes | `40_scission_circo` | 15 août |
| trame communale 1943-2012 | 44 atomes modernes, 39 291 intervalles de chronologie | `20`, `21` | 15 août |
| cantons 1999-2012 | 3 844 cantons, 37 319 rattachements, 998 fractions | `24`, `25` | 15 août |
| circo 2009 (2010-2013) | 539 unités, 37 257 rattachements | `27`, `43` | 20 août |
| circo 1986 (1986-2010) | 534 unités, 37 132 rattachements | `28`, `43` | 20 août |
| jalon 1954 | 30 035 atomes, 2 946 cantons | `66`-`69` | 28 août |
| jalon 1968 | 32 659 rattachements, 2 899 cantons | `58`, `59` | 28 août |
| reports par les deux bouts | 1941-1953 : 29 841 lignes ; 1941-1967 : 30 453 ; 1969-1998 : 24 041 | `93`, `97`, `95`, sur des jalons jugés par `96` | 23 sept. |
| Seine 1815-1967, compléments | sol du Perreux rendu à Nogent, annexées et lambeaux prolongés jusqu'en 1863, cantons de Paris portés par les quartiers, banlieue prolongée de 1954 à 1968 (hypothèse) | `100` à `104` | 3 oct. — non chiffré ici |
| bois de Boulogne et de Vincennes hors de Paris, 1863-1925/1929 | 18,12 km² rendus à 8 communes, 27 fenêtres datées | `118` | 18 oct. — `build/p118.log` |
| circonscriptions 1815-1870 | un département par appel, 84 journaux dans `build/p106_NN.log` ; hors 75 (`87`-`91`), 89 (`105`), 57 (pas de trame de 1870) et l'Aveyron, non photographié | `64`, `105`, `106` | 4-6 oct. — effectifs dans les journaux |
| villes partagées entre circonscriptions | 15 villes de `circo/partition_ville.csv` (en cours) : 1876-1940, la circonscription portée par les fractions de 9 villes au lieu de l'unité fusionnée de la mère (11 unités « Ville (1-2) » vidées) ; Nice 5e et 6e en 1973-1986 ; 1986, 1820 et 1863 déjà en base. Nice n'a pas de lignes : ses fractions se superposent, hachurées | `123` | 21 oct. — `build/p123.log` |
| circonscriptions 1958-1986 | 74 départements depuis le 21 oct. (06 posé : alias Nice-1 → Nice-Est, 277 unités, 30 683 rattachements) ; avant, 73 départements sur les cartes de l'atlas (19 oct., après `120` ; le Var sorti, Toulon-Est/Ouest à ranger) : 271 unités, 30 788 rattachements (1 082 par repli sur le premier canton connu) ; lecture de carte sur photo, 31 « DOUTE », non confrontée au JO ; 23 divisions en attente (`circo/composition_1958_etat.csv`) | `113` | 13 oct. — `build/p113.log` |
| cantons 1815-1870 | le canton de 1870 remonté à 1815, sauf les exceptions de l'atlas ; France entière | `107` | 6 oct. — `build/p107.log` |
| villes multicantonales découpées | 412 lignes de coupe pour 124 clés (communes et quartiers de Paris) dans `cartes/coupes_ville.csv` ; la carte les lit depuis `99` | `98`, `99`, `101_paris_fractions_quartier`, `108`, `109` | 11 oct., compté dans le CSV |
| trous 1941-1998, par le JO | 691 périodes | `110` | 11 oct. |
| périodes démenties par un transfert | 20 modifiées, 20 insérées | `111` | 11 oct., `p111_trace` |
| trous traversant 1968, et chaînage par l'acte | 5 451 périodes, 178 361 atome-années (Belley, Civrieux) | `120` | 19 oct., `p120_qualite` ; reste dans `p120_reste` |
| salves 1973 / 1982 | 1 905 rattachements, 270 cantons | `75` | 28 août |
| salves restantes | 873 rattachements, 128 cantons | `76` | 28 août |
| transferts datés INSEE | 32 rattachements, 13 cantons | `77` | 28 août |
| report arrière depuis 1999 | 36 296 rattachements, 422 838 atome-années | `79` | 29 août |
| report avant depuis 1968 | 32 842 rattachements, 191 866 atome-années, jusqu'au 1985-03-10 | `81` | 6 sept. |
| report 1940 → 1954 | 29 686 rattachements, 385 885 atome-années | `93` | 6 sept. |
| trame géométrique datée | 45 113 polygones, 38 074 atomes pourvus | `82` | 1ᵉʳ sept. |

Instantanés utiles : `snapshot(1968-06-01)` = 32 842 rattachements et 2 911
cantons ; `snapshot(1990)` = 23 233 ; `snapshot(1998)` = 37 267.

> **Chiffres périmés à ne pas reprendre** : le jalon 1968 a valu successivement
> 30 939 puis 32 552 puis 32 659 rattachements au fil des relectures OCR ; seule
> la dernière valeur, et le `snapshot` qui l'accompagne, valent aujourd'hui.

**Intégrité déléguée à la base.** Deux contraintes `EXCLUDE USING gist` : un
atome n'appartient qu'à une unité par niveau à un instant donné, deux versions
d'une même unité ne se chevauchent pas. Une troisième, sur `atom_geom_anr` :
un polygone par atome et par date. Toutes validées sur les vraies données.

---

## 2. Où en est chaque couche

### 2.1 Géométrie communale — deux trames, l'une datée

**Depuis le 1ᵉʳ septembre 2026, la base porte deux trames géométriques.**

| | `atom_geom` | `atom_geom_anr` |
|---|---|---|
| origine | GEOFLA 2011, un polygone par atome | ANR-COMMUNES, 1790-2020, polygones datés |
| lignes | 38 442 | **45 113**, 38 074 atomes pourvus |
| recouvrement à 1870, **dans la table** | 3 945 km² | **101,0 km²** |
| recouvrement à 1870, **tel que la carte le dessine** | 3 945 km² | **4 542,8 km²** |
| lue par | `snapshot_geom()` | `snapshot_geom_anr()`, avec repli sur `atom_geom` |

Le recouvrement de 101,0 km² a été mesuré **deux fois par deux chemins qui ne
partagent pas une ligne de code** — shapely + STRtree hors base le matin,
PostGIS + GiST en base le soir — et les deux tombent au dixième près. Résidu
nommé : Notre-Dame-de-Briançon 93,6 km², Tours 6,9. `atom_geom` et `membership`
n'ont pas été touchés.

**Mais 101,0 km² n'est pas ce que la carte montre, et la ligne de dessous est
la vraie.** `check_geom_anr` joint `atom_geom_anr` à elle-même : elle mesure le
recouvrement **de la source**. La carte, elle, dessine le **composite**
`coalesce(ANR à la date, atom_geom)`, et personne ne l'avait mesuré. Fait le
2 septembre 2026, sur l'export web, à 1870, entre communes ordinaires :

| | paires | km² |
|---|---|---|
| ANR × ANR | 2 353 | **1,0** |
| **ANR × repli** | **1 618** | **4 542,8** |
| repli × repli | 2 | 0,0 |

72 départements. La couture est ce qui se passe là où un atome retombe sur
GEOFLA 2011 pendant que ses voisins viennent d'ANR : 393 superpositions
franches (4 267 km², les filles reportées en arrière par `11` posées entières
sur leur mère intacte) et 1 225 lisières (275 km², le double trait visible
entre Villieu-Loyes-Mollon et Meximieux). À 1940 la couture est presque éteinte,
1,3 km². Détail par paire : `sorties/anr/carte_couture_repli_1870.csv`.

*Une recette qui mesure la source ne mesure pas le composite qu'on en tire.*

**`sql/84_carte_partition.sql` la lève** — voir § 2.1 bis. `82` n'est pas en
cause et n'a pas bougé.

**Ce qui lit `atom_geom` directement voit toujours l'ancienne valeur.** C'est
une transition, pas une migration : les deux tables coexistent, et seul ce qui
passe par `snapshot_geom_anr()` ou par l'export web bénéficie de la correction.

Le pont est une jointure d'entiers : `id_com` d'ANR **est** l'identifiant
Cassini de `atom.cassini`. 99,91 % des atomes non-fraction retrouvés, 99,66 %
d'accord sur les noms. Cinq règles de sélection, aucune n'arbitrant une
frontière, dans `sorties/anr/anr_regles.py` et `sql/82_anr_geom.sql`.

### 2.1 bis Trame nettoyée — écrite, mesurée hors base, PAS ENCORE JOUÉE

`sql/84_carte_partition.sql` rend une trame **sans trou et sans superposition**
hors fractions. Couche dérivée, lue à la demande : `atom_geom`, `atom_geom_anr`
et `membership` sont intacts, et `snapshot_geom_anr()` répond comme avant.

**Une seule règle, la reprise.** Un atome que la base fait vivre à la date et
qu'ANR ne pourvoit pas alors reçoit `voisin(D) − voisin(Y′)`, où Y′ est sa
prochaine apparition chez ANR et le voisin celui dont la chronologie s'y coupe.
Villieu à 1870 = Loyes(1870) − Loyes(1897) = 5,68 km², et Loyes garde les 4,40
restants. Deux polygones datés, une soustraction, aucun seuil, et une frontière
d'époque au lieu d'une frontière de 2011. Les frontières sont ensuite nouées et
polygonisées : une face, un propriétaire, donc **recouvrement impossible par
construction** plutôt que corrigé après coup.

Mesuré par `sql/banc_84.py` sur la vraie géométrie de l'export :

| à 1870 | avant | après |
|---|---|---|
| recouvrement, 23 départements | 6 923,6 km² | **0,000** |
| trou non comblé | — | **0,000** |
| atome sans aucune face | — | **0** |

Passe nationale à 1870 : 38 331 atomes dessinés, 37 497 par ANR, **432 repris**,
111 replis résiduels (souvent une mère hors département, limite du banc), 291
fractions et partagées inchangées.

**JOUÉ ET CONTRÔLÉ le 2 septembre 2026, sur l'Ain à 1870.** `check_partition`
rend **recouvrement hors fraction 0,000 km²**, zéro géométrie invalide, et
**les trois comptes tombent exactement sur ceux du banc** : 458 atomes
dessinés, 7 repris par différence, 0 repli résiduel. Deux chemins qui ne
partagent pas une ligne de code — shapely sur l'export WGS84 accroché à 25 m,
PostGIS sur la géométrie Lambert-93 réelle — et les comptes sont les mêmes.

L'Aveyron suit : 0,000 km² lui aussi, zéro géométrie invalide, 306 atomes,
19 reprises, 3 replis résiduels. C'est le département qui éprouve le vrai
mécanisme — Saint-Beaulize, La Serre, Les Albres y ont été réunies puis
rétablies, et c'est là que la règle « combler le trou par report » s'était
brisée.

Emprises : 5 812 km² projetés pour l'Ain, 8 770 pour l'Aveyron, contre 5 762 et
8 735 km² pour ces départements aujourd'hui. **Ce contrôle-là ne vaut qu'à un
demi-point près** : le facteur d'aire du Lambert-93 varie avec la latitude, et
le 1,0084 d'`ETAT.md` est une moyenne nationale. Il dit que le nettoyage ne se
paie ni en trous ni en débordements ; il ne dit pas mieux, et l'annoncer à
0,03 % sur l'Ain était une précision empruntée à une moyenne.

**Un défaut de la recette, trouvé par l'Aveyron.** `check_partition` portait
`1870-01-01` par défaut, tandis que `export_web.py` et le banc observent l'année
au **1ᵉʳ décembre**. La colonne « attendu » comparait donc deux cartes distantes
de onze mois — d'où 19 reprises contre 18 au banc, et 3 replis résiduels contre
1. Le défaut par défaut est passé au 1ᵉʳ décembre. *Une colonne « attendu » qui
ne partage pas la convention de ce qu'elle compare est pire qu'une colonne
vide : elle a l'air de valider.*

Cinq erreurs de SQL avaient été trouvées avant le premier appel et une sixième
par lui : les colonnes de `RETURNS TABLE` deviennent des variables PL/pgSQL, et
**un corps PL/pgSQL n'est analysé qu'au premier appel** — le fichier se charge
sans rien dire de ce qu'il contient. Détail dans `JOURNAL.md`.

**PASSE NATIONALE PASSÉE le 2 septembre 2026**, au 1ᵉʳ décembre 1870 :

| contrôle | 2 sept. | **5 sept., règle mosaïque** |
|---|---|---|
| atomes dessinés | 38 129 | **38 142** (+13) |
| repris par différence | 433 | **447** |
| repli GEOFLA résiduel | 84 | **83** |
| **recouvrement hors fraction** | **0,000 km²** | **0,000 km²** |
| dont couture entre départements | 0,000 km² | 0,019 km² |
| somme des aires hors fraction | 548 576 km² | 548 576 km² |
| géométries invalides | 0 | 0 |

> **Ces deux lignes bougeront au prochain passage**, et dans un sens connu : la
> trappe du vide fermée le 5 septembre retire de la reprise les atomes servis
> avec un `MULTIPOLYGON EMPTY` et les rend au repli. Au national, ils sont deux ;
> **par département — et c'est ainsi que la carte travaille — leur nombre est à
> lire, pas à déduire**, le cadre changeant le résultat de la reprise.

**Les deux zéros ne disent pas la même chose.** Le premier était le but du
fichier. Le second était une inconnue : le treillis se bâtit département par
département, donc deux communes séparées par une limite départementale sont
arbitrées deux fois, dans deux cadres où les tiers présents diffèrent. Rien ne
garantissait qu'une lisière disputée tombe du même côté. Elle tombe du même
côté partout. *Un découpage qui ne laisse pas de trace de lui-même est une
propriété du résultat, pas de la méthode qui l'a obtenu — et elle se vérifie.*

**Les 84 replis résiduels sont nommés** (`sql/diag_partition.sql`), et il n'y a
pas une surprise dans le lot :

| | n | km² | ce que c'est |
|---|---|---|---|
| fractions | 54 | 83,7 | par construction — elles gardent le polygone de la mère |
| jamais pourvus par ANR | 27 | 196,8 | dont **les 20 arrondissements de Paris**, couverts par la trame des quartiers (§ 2.7) |
| pourvus avant 1870 seulement | 2 | 46,9 | Sébazac-Concourès et Roches-Prémarie-Andillé |
| réapparaissent, mais sans mère trouvée | **1** | 0,4 | La Guérinière — le seul angle mort de la règle |

Hors Paris et hors fractions, **il reste dix communes** : Sébazac-Concourès,
Sebrazac, Tauriac-de-Naucelle, Puilboreau, un atome corse sans nom (2A325),
L'Aubépin, Saint-Hubert, La Salvetat-Belmontet, La Guérinière,
Roches-Prémarie-Andillé. **Quatre des six doublons nommés au § 8 de `82`** y
figurent, et **les deux « pourvus sur une fenêtre antérieure à 1870 »** du même
paragraphe sont exactement la troisième ligne du tableau. La confrontation
retrouve la liste de `82` sans l'avoir cherchée.

~~**Un seul cas où la règle de reprise échoue sur toute la France**, 0,4 km².~~
**La cause est trouvée le 5 septembre 2026, et elle n'est pas celle qu'on
croyait ; l'ampleur, elle, reste à trancher.**

Ce n'est **ni** une lacune de la source **ni** l'histoire des deux
communes-mères. Noirmoutier rétrécit bien en 1919, de **16,426 km²** (36,393 →
19,967), et une mère existe qui se coupe exactement en Y′. Mais elle a **deux
filles ce millésime-là** — La Guérinière et **L'Épine** (85083) —, voisines sur
la même île, et `partition_reprise` déplie le reste par `ST_Dump`, **qui ne
sépare que les composantes déconnectées** :

| fille | son repli | recouvre le morceau | rang | ce qu'elle obtient |
|---|---|---|---|---|
| L'Épine | 8,704 km² | 8,349 | 1 | **tout le morceau : 16,426 km²** |
| La Guérinière | 7,918 km² | 7,485 | 2 | rien — retombe sur son repli |

Les deux replis font ensemble 16,622 km² pour un morceau de 16,426 : **elles
font à elles deux exactement ce que la mère a perdu.** Le compteur `fratrie`
valait 2 sur ce couple et n'en tirait aucune conséquence — *une valeur calculée
que rien ne lit n'est pas une garde, c'est une décoration.*

**Le corollaire n'avait pas été vu, et il est plus grave que le trou : la sœur
servie est dessinée trop grande.** L'Épine reçoit près du double de son
territoire. Un atome muet se voit ; un atome enflé se confond avec un atome
juste.

**Et c'est pourquoi aucune recette ne pouvait l'attraper.** Une sœur enflée
occupe le sol de sa sœur muette : le treillis lui donne les faces, et la
surface totale est conservée. L'emprise nationale tombait juste — 548 576 km²
contre 548 489 d'étalon, +0,016 % — parce qu'un échange ne change pas une
somme. *Une recette qui mesure un total ne voit pas une permutation.*

**L'AMPLEUR EST MESURÉE, en appelant la règle elle-même.**
`partition_reprise` est `LANGUAGE sql STABLE`, sans table temporaire, et son
`p_dep` accepte `NULL` : appelée sans département, elle fait la France entière
— c'est `partition_un_dep` qui exige un département, pas elle. Au 1ᵉʳ décembre
1870 (`sql/diag_sans_geometrie.sql` § 7 g) :

| | n | lecture |
|---|---|---|
| candidats à la reprise | 486 | vivants, non-fractions, avec repli, sans ANR à la date |
| servis par la reprise | 435 | |
| **muets malgré un Y′** | **13** | ANR reparle d'eux, la règle ne leur rend rien |
| sans Y′ | 38 | limite de source, rien à réparer |

Les treize, ~**158 km²** et non 0,4 : Beauvais (33,5), Saint-Sulpice 63 (18,3),
Anthé (14,4), La Guillermie (12,6), Cazideroque (12,3), Thézac (11,3),
Masquières (11,2), Amnéville (10,5), Velanne (8,1), La Guérinière (7,9),
Saint-Sulpice-des-Rivoires (7,2), Colomars (6,0), Chardeny (5,1). Quatre sont
du Lot-et-Garonne au même millésime — **la fratrie de six de Tournon-d'Agenais,
où Bourlens reçoit 73,5 km² pour un repli de 15,6.**

*(Deux estimations intermédiaires — 17 filles perdantes, §§ 7 e et 7 f — sont
fausses et conservées comme telles : elles partaient de la mère quand la règle
part de la fille, et comptaient chaque fille sous chacune de ses mères. Leur
propre sortie les réfute : Sury et This y figurent deux fois avec les rôles
inversés.)*

**DEUX ATOMES SONT SERVIS AVEC UN POLYGONE VIDE**, et c'est pire que d'être
muet : L'Étang-Bertrand (repli 8,5 km², reçue 0,000) et Courbiac (9,0 → 0,000).
Comptés `source = 'reprise'`, ils n'apparaissent **ni dans les 84 replis ni
dans les 13 muets**, et ne dessinent rien. `partition_reprise` rend un
`MULTIPOLYGON EMPTY`, qui n'est pas `NULL`, et le `DELETE FROM t84_src WHERE
geom IS NULL` de `84` § (a) le laisse passer. *Un test `IS NULL` sur une
géométrie ne teste pas l'absence de géométrie.* **C'est le seul des trois
défauts qui se corrige sans décider de rien** — un `HAVING NOT ST_IsEmpty(…)`
et un `OR ST_IsEmpty(geom)` les feraient retomber sur R5, le comportement
déclaré.

> **APPLIQUÉ ET JOUÉ LE 5 SEPTEMBRE 2026 — ET LA MESURE A DÉPLACÉ LE DÉFAUT.**
> Le correctif est en base (`prosrc LIKE '%ST_IsEmpty%'` rend `t`) et **rien
> n'a bougé** : 433 reprises, 84 replis, exactement comme avant. La raison est
> que le paragraphe ci-dessus décrit l'appel NATIONAL et non la carte. Dans leur
> propre département, L'Étang-Bertrand et Courbiac ne reçoivent pas un
> `MULTIPOLYGON EMPTY` mais un multipolygone de **6 et 33 morceaux d'aire
> totale nulle** — des lisières effondrées. `ST_IsEmpty` les déclare pleins.
>
> *Un filtre sur le vide ne voit pas un polygone d'aire nulle. « Avoir des
> points » et « avoir une surface » sont deux propriétés distinctes.*
>
> **La trappe fermée est donc réelle et sans victime sur la carte** : elle
> protège l'appel national, qui est un outil de diagnostic. Le vrai défaut est
> le point 7 du § 8 de `84`, mesuré de bout en bout le même jour — voir
> ci-dessous.

**SIX COMMUNES ENTRENT, UNE SEULE EST DESSINÉE** — mesuré de bout en bout le
5 septembre 2026 par `sql/diag_fratrie_carte2.sql`, sur la carte elle-même et
non sur l'appel national :

| mère | fille | repli | sur la carte |
|---|---|---|---|
| Tournon-d'Agenais (1876) | **Bourlens** | 15,578 | **oui, 73,518 km²** |
| | Anthé | 14,380 | non |
| | Cazideroque | 12,277 | non |
| | Thézac | 11,330 | non |
| | Masquières | 11,215 | non |
| | Courbiac | 9,013 | non |
| Bricquebec (1895) | **Rocheville** | 10,417 | **oui, 19,080 km²** |
| | L'Étang-Bertrand | 8,525 | non |

**66,74 km² et six communes** qui existent, qui sont dessinables, et qui sont
dessinées sous le nom d'une sœur. Le mécanisme : `ST_Dump` ne sépare que les
composantes déconnectées, six filles voisines ne font qu'un morceau,
`DISTINCT ON (mid)` le donne à celle dont le repli le recouvre le plus. Les
autres ne reçoivent rien, ne gagnent aucune face, et **sortent du résultat** —
elles tombent dans les 318. La mère est réduite de la totalité :
94,956 − 73,518 = 21,438, au km² près.

*Un défaut qui conserve la somme ne se trouve pas en pesant. Il faut compter les
objets, pas mesurer le tas.*

**ET CE QUI REND LE CORRECTIF DÉCIDABLE.** La somme des replis des sœurs
reproduit le morceau à partager à moins d'un pour cent — Tournon 73,793 contre
73,518 (−0,37 %), Bricquebec 18,942 contre 19,080 (+0,73 %). **La mosaïque des
replis pave le territoire.** Découper le morceau connexe en donnant chaque face
à la sœur dont le repli la recouvre n'invente donc aucune ligne : c'est la règle
déjà écrite — « le repli redevient ce qu'il sait faire, un indice de position »
— appliquée à la face au lieu du morceau. C'est un changement de règle, il se
décide en le disant, et il s'éprouve au banc avant la base.

**ET LE CADRE DÉPARTEMENTAL CHANGE LE RÉSULTAT DE LA REPRISE.** 13 muets au
national, 1 sur la carte : les deux ne calculent pas la même chose. Le bloc
`vivant` de `partition_reprise` est filtré par le département, le bloc `mere`
ne l'est pas — donc **moins de filles concourent pour le même morceau en
local**, et une fille qui perd au national gagne dans son département. Cela
contredisait l'affirmation écrite en tête de `partition_un_dep` — *« le
découpage par département rend EXACTEMENT le même dessin »* —, **corrigée dans
le fichier le 5 septembre 2026** : le mot juste est « le même TREILLIS », et
l'en-tête porte désormais l'exception en toutes lettres. C'est vrai du treillis, dont
les effets sont locaux ; **ce n'est pas vrai d'un arbitrage entre
prétendants**. Corollaire à vérifier : une fratrie à cheval sur deux
départements se ferait attribuer le même morceau deux fois, et cela se lirait
sur la ligne « couture entre départements » de `check_partition`.

> **CETTE LIGNE VALAIT 0,000 km² LE 2 SEPTEMBRE, ELLE VAUT 0,019 LE 5.** J'ai
> écrit le matin même qu'elle valait zéro et que le corollaire était donc nul,
> sous réserve que la mesure précédait la correction de l'anneau du 3 septembre.
> **La réserve a payé le jour même** : la passe nationale rejouée rend
> `couture entre départements = 0,019 km²`, tout le reste identique au chiffre
> près — 38 129 atomes, 433 reprises, 84 replis, recouvrement 0,000, emprise
> 548 576. Le corollaire n'est donc **pas** nul.
>
> 1,9 ha, c'est l'ordre de grandeur d'une lisière et non d'un territoire : la
> lecture la plus simple est qu'une frontière disputée entre deux départements
> ne tombe plus du même côté dans les deux cadres depuis que l'anneau épouse le
> voisinage réel. Mais **une fratrie à cheval recevant deux fois le même morceau
> se lirait au même endroit**, et 1,9 ha ne suffit pas à trancher entre les
> deux : il faut nommer les paires. C'est le § 9 de `sql/diag_partition.sql`,
> écrit pour ça, avec une colonne `deux_reprises` qui sépare les deux lectures.
>
> *La non-régression de l'anneau avait été vérifiée département par
> département — c'est-à-dire exactement là où cette ligne est sans objet par
> construction. Une recette qu'on ne peut pas lire dans le cadre où l'on éprouve
> un correctif ne le contrôle pas.*

*Une opération n'est découpable que si ses effets sont locaux — et deux
opérations aux propriétés opposées vivaient dans le même fichier sous la même
justification.*

**L'emprise se referme.** 548 576 km² contre l'étalon GEOFLA 2014 de
548 489 : **+0,016 %**. La partition récupère les 101 km² de recouvrement
d'ANR et ajoute de l'ordre de 80 km² de lisières internes comblées.

**Ce que le nettoyage a déplacé, mesuré atome par atome** (§ 7 du diagnostic —
surface après la partition moins surface sous `coalesce(ANR, atom_geom)`) :

| | atomes | km² net |
|---|---|---|
| inchangés à 0,1 ha près | 37 156 | 0,0 |
| ont perdu du sol | 653 | **−5 901,1** |
| ont gagné du sol | 266 | **+248,9** |

Les 5 901 km² perdus sont le double comptage qui disparaît : une fille reportée
en arrière revendiquait le polygone de sa commune terminale, sa mère revendiquait
le sien entier, et le même sol était compté deux fois. Les 653 perdants sont ces
filles et ces mères.

**Les 248,9 km² gagnés sont la seule terre que l'arbitrage ajoute** — 0,045 % du
pays, pour l'essentiel des lisières internes comblées au plus long bord. C'est
le majorant de ce que `84` invente, et il fallait le mesurer plutôt que le
déduire d'une somme de motifs.

**318 atomes vivants à 1870 ne sont dessinés nulle part** — ni ANR, ni reprise,
ni GEOFLA 2011. Ce n'est pas `84` qui les efface : ils manquaient déjà, et
`snapshot_geom_anr` les comptait sous `n_sans_geom` sans que le nombre ait
jamais été posé. C'est le vrai trou de la carte à cette date.

Et ils ne sont pas de la même espèce. Les vingt premiers sont surtout des
**atomes-fraction de villes multicantonales** — Montluçon, Moulins, Sedan,
Troyes, Carcassonne, Castelnaudary, Aix-en-Provence — qui n'ont AUCUNE
géométrie, pas même celle de leur mère. Ces cantons-là sont donc dessinés
courts, et ce défaut est antérieur à `82` comme à `84`. S'y mêlent quelques
communes disparues sans polygone GEOFLA, dont **Goutrens** : c'est le
troisième des trois que `82` § 8 nommait comme « pourvus sur une fenêtre
antérieure à 1870 », les deux autres étant dans la liste des replis ci-dessus.
**Le trio de `82` est refermé, par deux chemins différents.**

> **Piège de lecture, corrigé le soir même.** Le § 4 de `diag_partition.sql`
> donnait la surface totale des atomes portant chaque motif d'arbitrage, et sa
> légende invitait à y lire la surface arbitrée — un atome de 20 km² dont deux
> hectares ont été comblés pesait 20 dans la ligne `comblement`. Les 2 559,8 km²
> de cette ligne ne sont donc PAS ce que le comblement a ajouté. La question se
> pose au § 7, qui compare la surface de chaque atome avant et après.
> *Une colonne juste sous une légende fausse est une colonne fausse.*

`cartes/export_web.py --partition` sait la lire, en option et sans rien changer
par défaut, pour que les deux trames soient comparables avant qu'on remplace
l'une par l'autre. Coût mesuré : 24,5 années géométriques par département contre
une centaine d'années candidates, soit environ quatre fois le temps ordinaire —
351 s pour l'Ain, **~8,7 h en séquentiel pour la France**, deux heures à
`--jobs 6`.

**Export de l'Ain, mesuré le 2 septembre** : 62 atomes en repli au moins une
année → **5**. Le dossier ne grossit que de 6,5 % (27,20 → 28,98 Mo) pour
585 → 1 274 versions, la déduplication par `ST_Equals` ramenant une quarantaine
d'instantanés par commune à 2,75 versions.

**LE PLAFOND DE `84`, ET IL FAUT LE CONNAÎTRE AVANT DE JUGER.** Les fractions
restent en repli par construction. Sur l'ancien export, France entière :

| | atomes |
|---|---|
| en repli au moins une année | 4 291 (10,3 %) |
| dont **fractions**, hors portée de `84` | **1 256 (29 %)** |
| **corrigeables au mieux** | **3 035** |

La correction n'est donc pas uniforme, et l'écart entre départements est
énorme : l'Ain n'a que 5 fractions sur 62 replis et tombe à 1,1 % ; **Paris en a
128 sur 159**, plus 20 arrondissements qu'ANR ne pourvoit jamais, et son
plancher est vers 148. Les départements où `84` se juge vraiment sont ceux dont
le repli n'est presque pas fractionnaire — Haute-Marne (163 replis, 6 fractions)
et Basses-Alpes (58, 5).

### 2.2 Cantons 1870-1940 — close, contrôlée

Complète, contrôlée contre les cantons dissous de Victor Gay (§ 3.1), et rien
n'y a bougé depuis le 20 août. Effectifs conformes à l'histoire à chaque date
testée : 89 départements en 1870, 87 après la perte de l'Alsace-Moselle,
90 après 1919 ; 2 862 à 3 028 cantons ; bascules liste/uninominal aux bonnes
années. Les 1 690 atomes dont la chronologie est trouée exactement de 1871 à
1919 sont l'Alsace-Moselle — une validation, pas une anomalie.

**Un fait à connaître avant de cartographier** : le département **54 change de
territoire au 1ᵉʳ janvier 1871 sans changer de numéro.** Les deux périodes ne se
recouvrent pas, donc une requête à date donnée reste sans ambiguïté ; mais une
planche qui empile « le 54 » sur toute la série montrera **deux emprises**. Et
les deux mouvements de 1871 ne sont pas symétriques : la Meurthe perd sa partie
est — **242 de ses 708 communes portent aujourd'hui un INSEE 57** — et gagne
l'arrondissement de Briey, venu de la Moselle. Meurthe-et-Moselle n'est donc pas
la Meurthe amputée, c'est la Meurthe amputée **plus** Briey. (Voir § 6 : cela
suppose que `39_meurthe_1870.sql` soit appliqué.)

### 2.3 Cantons 1943-1999 — comblés en jalons, plus en trou

**Plus aucune date entre 1954 et 1999 ne renvoie le vide.** Ce n'est pas une
carte complète — de l'ordre de 1 200 cantons sur 4 000 à certaines dates — mais
le blocage structurel du projet a cessé d'en être un.

> **Et cette phrase ne disait rien de ce qui est SOUS 1954.** Deux fenêtres y
> renvoyaient le vide franc. **1941-1953 est comblé depuis le 6 septembre
> 2026** — `93`, 29 686 rattachements sur 38 304 atomes vivants en 1940. Reste
> **1955-1967**, qui attend un troisième jalon : le recensement de 1962, en
> ligne (§ 1 bis de `RESTE_A_FAIRE.md`). *Une borne d'affirmation se lit aussi
> par ce qu'elle laisse dehors.*

**Ce que 1941-1953 porte, et à quel titre.** `93` ne pose que là où les deux
relevés — TRF-GIS et le recensement, sans source commune — donnent le même
canton ; ailleurs il laisse un trou déclaré plutôt qu'un arbitrage.

| | atomes | atome-années | |
|---|---|---|---|
| posé, contrôlé aux deux bouts par un appariement indépendant | 26 221 | 340 873 | `controle_independant` |
| posé, accord vrai par construction (`ferme_canton`, `hors_c54`) | 3 454 | 44 902 | vaut un report à la `79` |
| posé sous décret, jusqu'à la signature | 11 | 110 | Sousceyrac, Brive-Sud |
| **refusé** — absent du relevé de 1954 | 7 970 | 103 610 | voir `94` |
| **refusé** — fraction, aucun contrôle possible | 325 | 4 225 | |
| **refusé** — désaccord entre les deux bouts | 323 | 4 199 | arbitrage de `71` |

Le taux d'accord se lit sur les seuls **comparables** : **98,78 % sur 26 544**
dans la classe indépendante — les deux nombres exacts de `70`, retrouvés par un
autre fichier. La classe `ferme_canton` rend 100,00 %, et c'est ce qu'elle doit
rendre : elle a été appariée parce que son canton concordait.

| ce qui répond | fondement de la date | fichier |
|---|---|---|
| 1941-1953 | accord de deux relevés indépendants — **posé le 6 sept. 2026** | `93` |
| 1954 | un recensement — un fait | `66`-`69` |
| 1968 | un recensement — un fait | `58`, `59` |
| Yvelines 1968 | la naissance d'un département — un fait | `74` |
| 1973 et 1982 | convention, 37,0 % de dates incertaines | `75` |
| les autres salves | convention, **93,7 % incertaines** | `76` |
| 66 transferts de commune | 30 datés au jour près par l'INSEE | `77` |
| 1987-1999 par report arrière depuis 1999 | inférence validée (§ 3.4) | `79` |
| 1969 → premier acte du département | inférence validée, **posée le 6 sept. 2026** | `81` |
| 1941-1998, dans les trous | JO lus à la main (13 transferts, plus 2 lus dans les tables le 24 oct. 2026, 73 cantons recomposés 1949-1968, Corse 1975) et **tables annuelles du JO** (93 transferts isolés). Convention de date (règle C), **posé le 11 oct. 2026** : 691 périodes | `110` |
| périodes démenties par ces transferts | raccourcies, l'avant ou l'après rendu au bon canton : 20 périodes de `79`, `81` et de la base d'origine. Posé, défait le 11 oct. 2026 pour éprouver le retour arrière, **puis rejoué : la base le porte** — `p111_trace` compte 40 lignes (20 `modifie`, 20 `insere`), mesuré le 11 oct. au soir. La carte servie, exportée avant, ne le montre pas encore | `111` |

**Asymétrie à connaître avant toute lecture.** L'incertitude de date ne pèse que
sur les cantons *modifiés*. La part des actes de création pure s'effondre avec
le temps — 100 % en 1967, 63,8 % en 1973/1982, **9,1 %** ensuite. Donc :
**toute lecture des cantons entre 1985 et 1998 doit joindre `p76_qualite`**,
sans quoi elle prendra une convention pour un fait. 1973-1984 est sensiblement
plus sûr, 1968 et 1954 le sont tout à fait.

Les deux jalons de recensement s'accordent à **94,5 %** sur 25 258 communes —
deux fascicules, deux chaînes OCR, deux méthodes d'appariement, et c'est le seul
contrôle dont la période dispose. Dispersion à surveiller : Belfort 67,9 %,
Corse 85,9 %, Moselle 86,5 %, Isère 89,4 %. Le désaccord ne dit pas laquelle des
deux lectures a tort. La Seine (10,0 %) et la Seine-et-Oise (46,4 %) ne sont pas
au bas de la distribution mais **hors** d'elle : l'éclatement de 1968 a
redécoupé la région parisienne en même temps qu'il la renumérotait — deux
cartes, pas deux lectures contradictoires.

Qualité de lecture : 1954, `ferme` 88,5 %, `nom_flou_confirme` 11,4 %,
`atome_ambigu` 0,1 % (`c54_qualite`) ; 1968, `ferme` 79,9 %,
`canton_conteste` 3,1 % (`c68_qualite`).

> **Le « 95,9 % » de 1954 ne mesure pas ce qu'on lui faisait dire — corrigé le
> 6 septembre 2026.** C'est 30 128 lignes sur 31 400 : la part des lignes
> **transcrites** qui ont reçu un code, donc la qualité de l'appariement. Les
> pages muettes ne sont pas au dénominateur, n'ayant produit aucune ligne.
>
> **La couverture du jalon sur les communes qui existaient est de 79,0 %**
> — 30 009 atomes comparables sur 37 979 vivants en 1940 (`94` § 5). Les
> **7 870 manquantes vivaient en 1954** : `94` le mesure par la chronologie de
> l'INSEE, qui ne trouve que 55 mortes dans la fenêtre. Et la perte **n'est pas
> concentrée** sur les quatre départements que `note_1954.md` donne pour
> absents — ils portent 6,2 % du total, et le 52 ne perd que 30 % de ses
> communes. C'est un défaut général du dépouillement, réparti entre 19 et 42 %
> par département.
>
> ***Un taux sans son dénominateur est une opinion présentée comme une
> mesure*** — celui-ci était rassurant depuis le 14 août 2026.

**Le registre des actes** (`72`) porte 343 décrets moissonnés par titre et
1 212 cantons dépouillés des JO ; `acte_departement` et `acte_sans_effet` en
portent les exceptions, bâties en creux avec leur fondement cité. Le registre
consolidé compte **723 démembrements réels, dont 559 datés au décret (77 %)**,
90 % de ces dates tombant dans les décennies 1970 et 1980.

**Les 274 transferts isolés de communes** entre cantons — ceux que l'annexe VII
de Gaudillère ne consigne pas, et que le registre Légifrance ignore faute de
texte indexé avant 1990 — **sont datés pour 97 d'entre eux** depuis le
11 octobre 2026, par les **tables analytiques annuelles du JO** (1941-1990,
`sources/JORF/tables/`) : chaque commune n'y paraît qu'une année, avec la page et le
plus souvent la date du décret (`cantons/dates_par_tables_jo.csv`). La date de
parution est estimée par la page : écart médian d'un jour sur 236 actes connus.
93 sont entrés par `110` (73 posés dans un trou) et `111` (18 corrigés sur une
période qui les démentait ; 2 laissés : Orgerus, Ferreux). **177 restent introuvables** dans les tables —
artefacts de la base ou noms que l'OCR a trop abîmés. Les tables retrouvent
228 des 233 décrets de création et de recomposition connus par ailleurs : leur
silence, pour un département et une année, vaut désormais présomption
d'absence d'acte (moins sûrement pour les rattachements avant 1958, dont la
mise en colonnes est encore mêlée). Détail : `cantons/note_decrets.md` (partie « Les tables analytiques du JO »).
S'y ajoutent les **48 cantons créés entre 1986 et 1999**, nommés un par un mais
non datés faute de source couvrant la fenêtre.

### 2.4 Cantons 1999-2012 — posés, contrôlés

3 843 cantons en 1999, 3 846 en 2012, 37 319 rattachements, zéro chevauchement,
zéro rattachement entre 1941 et 1998 hors de ce que la période 2.3 a posé
depuis. Contrôlés contre la couche CANTON de GEOFLA (§ 3.2).

Trois décisions fondées, non conventionnelles :

* **Un seul espace de noms.** Un canton garde son `unit_id` de 1870 à 2012.
  Ce n'est pas une commodité : `ct_codes.do` de TRF-GIS aligne explicitement les
  codes de Gay sur le COG de 1954, et la filiation 1954 → 1999 est celle de
  l'Insee. 92,4 % des 2 943 codes partagés portent d'ailleurs le même nom. Ce
  qui est affirmé, c'est l'identité du canton ; pas sa composition dans
  l'intervalle.
* **Paris est résolu par la donnée**, pas supposé : le fichier cantons donne
  `cheflieu` = 75101 pour le canton 15 jusqu'à 75120 pour le 34. 280
  rattachements posés sans hypothèse.
* **Marseille et Lyon sont des pseudo-cantons**, et c'est la convention du
  domaine, pas un pis-aller : GEOFLA fait de même (`CODE_CANT = '99'`, d'où
  3 708 cantons chez l'IGN contre 3 876 au COG), comme Gay pour 1870-1940.
  Chaque arrondissement a été affecté au canton GEOFLA contenant son point
  intérieur — les 16 marseillais dans `1399`, les 9 lyonnais dans `6999`.

### 2.5 Circonscriptions législatives

| | 1870-1940 | 1986 | 2009 |
|---|---|---|---|
| période | série TRF-GIS | 24 nov. 1986 → 22 fév. 2010 | 23 fév. 2010 → fin |
| unités | 1 772 (dont 132 provisoires) | 534 | 539 |
| avec territoire | — | **533** | **524** |
| rattachements | — | 37 132 | 37 257 |
| Paris | par quartier depuis `52`-`57` | absent du tableau source | 4 circos sur 18 |

Recettes à zéro des deux côtés modernes : aucun chevauchement, aucun atome
relevant des deux découpages, bascule nette au 23 février 2010, 1870-1940
intact. La somme des maxima départementaux de 2009 retrouve **539 sièges
métropolitains**, le compte officiel, sans correction.

**Le résidu de 1986 est légitime et déclaré** : 113 communes n'ont aucune
circonscription de 1986 à 2013 parce que **le tableau officiel écrit
« circonscriptions 13 et 16 » sans répartir les communes**. Toutes recensées
dans `circo/circo_1986_indetermine.csv` (135 lignes), concentrées sur 18 cantons
du Nord (67 communes), du Rhône, des Bouches-du-Rhône, du Bas-Rhin, de
Charente-Maritime et de la Drôme, dont sept entièrement.

**Défaut d'affichage à corriger** : ces 113 communes ne sont pas *marquées*
indéterminées sur la carte, elles en sont **absentes**, ce qui contredit la
règle du projet — *ce qui n'a de nom nulle part est signalé comme tel, pas
maquillé*. Voir `RESTE_A_FAIRE.md`.

### 2.6 Paris — la couche la plus fine, et la seule qui remonte à 1815

Trame des **80 quartiers administratifs** reconstruite par union d'IRIS
(CONTOURS-IRIS, INSEE-IGN, Licence Ouverte 2.0 — le jeu de la Ville de Paris
étant en ODbL, inutilisable ici). 992 IRIS, 4 quartiers par arrondissement.

**Contrôle : 80 noms sur 80 retrouvés** dans le vocabulaire de la transcription
de l'atlas Gaudillère, deux sources jamais mises en contact. Douze écarts, tous
de nom, aucun de trame. Surface 105,43 km² contre 104,90 à GEOFLA — c'est l'IRIS
qui a raison (105,4 km² officiels, bois compris), GEOFLA qui généralise.

**386 circonscriptions sur 15 divisions de 1863 à 1986**, chacune rendant
105,43 km² — Paris entier à chaque date. Quatorze divisions se résolvent sans un
nom hors trame. Deux acquis non cherchés : **1958-1986 est posé** alors qu'il
était bloqué nationalement (il ne l'est plus depuis `113`, 13 octobre) (à Paris il se définit par quartiers, pas par cantons),
et le régime de scrutin se lit dans les données — 1919-1928 et 1945-1958 ne
comptent que 3 circonscriptions pour 80 quartiers, scrutin de liste par secteur.

**Limites** : la trame est celle d'aujourd'hui. Les deux bois en sont
retirés de 1863 à leur annexion par `118` — Boulogne le 3 avril 1925,
Neuilly et le bois de Vincennes le 18 avril 1929 ; la zone des
fortifications, annexée de 1925 à 1930, ne l'est pas, faute d'IRIS à elle :
Paris fait 87,3 km² en 1900 au lieu d'environ 78 ; sa fidélité aux limites de 1876 est réputée, non vérifiée ; 16 noms
d'avant 1860 se résolvent contre la trame moderne en désignant d'autres
territoires, et ne sont écartés que par une barrière de date.

### 2.7 Outre-mer

Rouvert le 16 août 2026, dans un espace séparé (`om_*`, `40_outremer.sql`), sans
mélange avec la métropole. Circonscriptions DOM déjà sur disque, GEOFLA
2015-03-04 pour les trames, CONTOURS-IRIS couvrant 61 coupes sur 61. L'Algérie
reste bloquée par la licence. **Le Pacifique ne l'est plus depuis le
25 octobre 2026** (`135_pacifique.sql`) : Polynésie française sur la trame de
l'ISPF (ODbL, cartes rendues en « œuvre produite »), Nouvelle-Calédonie sur
celle de data.gouv.nc (Licence Ouverte 2.0), circonscriptions 1945-2012 tirées
des lois de 1977, 1986 et de l'ordonnance de 2009. Récit dans `JOURNAL.md`.

**`40_outremer.sql` n'est toujours pas joué** — son prérequis `om_commune_src`
vient de `charger_outremer.sh`, que rien n'appelait jusqu'au 2 septembre (§ 6).
Tout ce qui suit décrit donc ce que la chaîne fera, pas ce que la base porte.

**La carte web sait lire cet espace depuis le 6 septembre 2026**, par
`cartes/export_web.py --outremer`. Trois différences de modèle interdisaient de
réutiliser le chemin métropolitain, et elles valent d'être connues avant de lire
une planche d'outre-mer :

| | métropole | outre-mer |
|---|---|---|
| clé de département | `unit.dep`, `char(2)` | `om_unit.dep`, `char(3)` |
| projection | Lambert-93 (2154) | WGS84 (4326), surfaces en `geography` |
| épaisseur temporelle de la forme | ANR datée, `84` nettoyée | **aucune** — instantané GEOFLA 2015 |
| accrochage | 25 m | 25 m convertis en degrés (25,0 à 26,8 m selon la latitude) |

Toutes les communes d'outre-mer portent donc `r: 1` : leur forme est juste, sa
*date* n'est pas attestée. C'est la convention que `--sans-anr` emploie déjà en
métropole, pas une convention neuve.

**Deux trous connus, et l'export les montre au lieu de les combler.** Les 27
communes multicantonales n'ont aucun rattachement cantonal — GEOFLA ne les
découpe pas — et sortent hachurées, tracé à faire sur `iris_om`. **Mayotte n'a
aucun rattachement du tout** : le fichier du ministère qui les pose ne la
contient pas, ses 16 cantons ne venant que de GEOFLA. Son département s'affiche
donc avec ses communes dessinées, sans couleur, et zéro année servie.

Cela a demandé de corriger la page, qui ne dessinait que les communes présentes
dans un `rattachement` — le défaut que le § 2.5 nomme depuis août à propos des
113 communes de 1986. **Il n'est levé que pour l'outre-mer**, et la raison n'est
pas la prudence : en métropole, le rattachement est ce qui borne la *vie* d'un
atome, et s'en passer dessinerait des communes avant leur naissance. Outre-mer,
la trame étant un instantané, chaque version porte l'année de
départementalisation comme borne basse (1946, et 2011 pour Mayotte).

---

## 3. Les contrôles indépendants

Quatre étalons extérieurs, dont **aucun ne passe par une ligne de notre code**.
C'est le dispositif central du projet : les recettes internes valident la
cohérence, jamais l'exactitude.

| # | étalon | ce qu'il juge | verdict |
|---|---|---|---|
| 3.1 | cantons dissous de Gay | 1870-1940, géométrie et attributions | 3 désaccords hors artefact sur 38 235 atomes |
| 3.2 | couche CANTON de GEOFLA | 1999-2012 | 11 atomes sur 37 297, soit 0,03 % |
| 3.3 | HAC (filiation communale) | les paris de `11` | 98,2 % au canton, **100 %** aux circos |
| 3.4 | registre des actes vs COG 1999 | le report `79`/`81` | 94,9 % contre 33,5 %, 49 dép. sur 49 |
| 3.5 | ANR-COMMUNES (dates de naissance) | le report arrière de `11` | 84,1 % contre 33,9 %, 357 dates sur 359 |

### 3.1 Gay — 1870-1940

`sql/controle_gay.sh` (exige `gdal-bin`), sorties dans
`sorties/rapport_controle_gay.txt` et `controle_gay.gpkg`.

| | 1870 au départ | 1870 aujourd'hui | 1940 |
|---|---|---|---|
| pseudo-cantons comparés | 2 775 | 2 775 | 2 824 |
| tracés identiques | 82,7 % | **94,49 %** | **95,33 %** |
| IoU moyen | 0,9826 | **0,99281** | **0,99325** |
| territoire non couvert | 5 926 km² | **238 km²** | **32 km²** |
| communes non réclamées | 494 | 39 | 2 |

**Le résultat qui compte n'est pas le taux, c'est sa décomposition.** Le
désaccord ne suit pas la source de la géométrie, il suit le **partage de
polygone** :

| situation | atomes | en désaccord | |
|---|---|---|---|
| seul sur son polygone | 35 309 | 8 | 0,02 % |
| partage un polygone, même canton | 2 273 | 0 | 0,00 % |
| partage un polygone, cantons différents | 653 | 140 | **21,44 %** |

Et les 8 « hors conflit » se réduisent à **3** une fois vu que cinq d'entre eux
(3 `hac_partage`, 2 `hac`) partagent eux aussi leur polygone — vérifié atome par
atome. **Ces trois-là sont les paris perdus du correctif de scission, conservés
délibérément.** La base n'a aucun désaccord avec Gay qui ne soit ni un artefact
de trame, ni un choix assumé et tracé.

Corollaire à ne pas manquer : le « 3 sur 6 » qui semblait condamner
`hac_partage` mesure la trame, pas l'échec du choix arbitraire. Le contrôle Gay
ne peut plus servir à le condamner — sur ces six-là, il ne tranche pas. Ce qui
ne l'innocente pas : le rattachement par nom reste arbitraire et révocable.

**Les quatre paris perdus**, laissés en l'état parce que les corriger en
recopiant Gay ferait perdre au contrôle son indépendance :

| atome | INSEE | apparu | chez nous | chez Gay | km² |
|---|---|---|---|---|---|
| 37390 | 08447 | 1872 | Mézières | Charleville | 32,69 |
| 36437 | 77454 | 1874 | Donnemarie-en-Montois | Nangis | 10,60 |
| 17501 | 56086 | 1891 | Quiberon | Belle-Île | 3,25 |
| 17191 | 56085 | 1891 | Quiberon | Belle-Île | 2,25 |

HAC contredit Gay sur les deux premiers et donne raison à `11` (§ 3.3). Deux
sources indépendantes se contredisent : le dossier n'est pas clos, il n'est
plus vide.

### 3.2 GEOFLA — 1999-2012

`26_controle_ign.sql`. 3 162 pseudo-cantons comparés, appariement parfait dans
les deux sens, 548 463 km² contre 548 488 — **écart de 26 km², 0,005 %**, IoU
moyen 0,9646. Onze atomes rangés ailleurs sur 37 297, dont **zéro** pour
`fraction_cog`, `arrondissement`, `successeur` et `creation_arriere`.

Réserve d'emblée : contrôle plus faible que celui de Gay, nos communes étant de
l'édition GEOFLA 2011 et ces cantons de l'édition 2014. Les pires cas sont des
cantons urbains de moins de 3 km² en petite couronne. Seuls les écarts
d'attribution, qui portent sur des communes entières, concluent.

### 3.3 HAC — la filiation que `11` ne connaissait pas

`annexes/hac/hac_filiation.py`, `sql/45_controle_hac.sql`, **qui ne contient aucun
`INSERT`, `DELETE` ni `UPDATE`** : corriger la base d'après HAC lui ferait
perdre son indépendance.

La clé est donnée par la source : **l'`id` de HAC EST la colonne `cassini` de
TRF-GIS**. Aucun appariement par nom pour la fille — la clé la plus sûre du
projet. La mère, elle, n'est nommée qu'en clair et sous son nom d'*aujourd'hui*
(« La Baule-Escoublac » contre « Escoublac ») : indexer les deux formes fait
passer la résolution de 92,8 % à **99,3 %**, 444 filiations sur 447.

Verdict : **392 accords contre 7 désaccords au canton (98,2 %), 366 contre 0
aux circonscriptions (100 %)**. Les 7 désaccords ont tous la même forme — une
commune née d'une mère relevant d'un *autre* canton, l'acte de création changeant
le canton en même temps qu'il crée la commune. Le pari de `11` échoue exactement
là où il devait échouer, et nulle part ailleurs.

Bâtir `11` sur la filiation HAC a été essayé, mesuré, **et abandonné** :
11 paris perdus sur 425 contre 4 sur 414. Cause : HAC ne nomme qu'une mère quand
il y en a plusieurs. Détail dans `METHODE.md`.

### 3.4 Le registre des actes — le report de `79` et `81`

`80_report_1968_avant_diag.sql` § 6 quinquies. L'affirmation testée n'est pas la
tautologie « les communes que les décrets nomment ont changé de canton », mais
l'affirmation forte et réfutable du registre : **en dehors de ces 2 536 atomes,
rien n'a bougé en trente et un ans.**

| population | atomes | accord 1968/1999 |
|---|---|---|
| jamais nommé par un décret | 30 306 | **94,90 %** |
| nommé par un décret | 2 536 | **33,49 %** |

Écart de 61,4 points, et le test apparié ne laisse aucune place au doute :
**49 départements sur 49 dans le même sens**, écart médian +62,1, soit 2⁻⁴⁹ sous
l'hypothèse nulle. Le § 6 octies, écrit pour lister les anomalies, n'en trouve
aucune.

La borne, et elle n'est pas 100 % : les 5,1 % de désaccord résiduel mêlent l'OCR
de 1968, les cantons vidés sans être nommés (biais connu, de sens connu, qui
joue *contre* l'hypothèse) et d'éventuels vrais trous du registre. Le repère :
94,9 % se situe entre les 89,8 % de 1954 → 1968 et les 99,5 % de 1940 → 1954,
sur 31 ans contre 14.

Un département à regarder : **95**, dont les jamais-nommés ne font que 78,1 % —
le plus bas, et de loin. Val-d'Oise est né en 1968 de l'éclatement de la
Seine-et-Oise ; c'est probablement le redécoupage de la région parisienne, pas
un trou du registre.

### 3.5 ANR-COMMUNES — les dates de naissance

`83_anr_ecart_couverture.sql`, lecture seule. Ce qui devait n'être qu'une
explication d'écart de recette est devenu **la validation la plus nette
qu'ait reçue `11_scission.sql`**.

486 atomes vivants en 1870 sans polygone ANR. Décomposition :

| motif | n | dont posés par `11` |
|---|---|---|
| ANR ne fait naître la commune qu'après cette date | 379 | 359 |
| trou interne dans la chronologie ANR | 69 | 68 |
| Paris — trame des quartiers | 20 | 0 |
| ANR ignore cet `id_com` | 15 | 0 |
| ANR arrête la commune avant cette date | 3 | 0 |

| origine | n | qu'ANR fait naître après 1870 | |
|---|---|---|---|
| posé par `11` | 427 | 359 | **84,1 %** |
| non posé par `11` | 59 | 20 | **33,9 %** |

Et sur les 359 vraies naissances, `debut_reel` (mouvements INSEE) et `anr_debut`
(éditions ANR) tombent **sur la même année 357 fois — 99,4 %**, sans une ligne
de code commune. Le report arrière de `11` cesse d'être un pari raisonnable pour
devenir une inférence corroborée par une source qui ne l'a jamais vu.

---

## 4. Limites connues — à citer en légende de toute carte

Renvois vers `METHODE.md` § 6, où chacune est détaillée et mesurée.

* **§ 6.1 — Recouvrement de la trame 2011.** 3 945 km² comptés deux fois en 1870
  au niveau du contrôle, 12 930 entre cantons réels. **Ramené à 101,0 km² dans
  `atom_geom_anr` depuis le 1ᵉʳ septembre**, mais `atom_geom` reste intacte avec
  ses 3 945 : c'est la valeur que voit tout ce qui ne passe pas par
  `snapshot_geom_anr()`.
* **§ 6.2 — Trame incomplète.** Communes créées après la date interrogée.
  Ramenée de 5 926 km² à **238 km² en 1870** et 32 en 1940 par `11`, `15`, `42`
  et `46`.
* **§ 6.2 quinquies — Marseille et Lyon n'ont qu'un canton de 1999 à 2012.**
  Leur nombre réel a évolué (Marseille 22 → 25 en 2005, Lyon 13 → 14 en 2002)
  sans que le pseudo-canton bouge : la simplification masque une évolution réelle
  sans fausser le territoire.
* **§ 6.3 — Six atomes `hac_partage`** au rattachement arbitraire, tracé et
  révocable.
* **§ 6.4 — 132 circonscriptions sans nom**, provisoires, citées par le
  membership et absentes des nomenclatures TRF-GIS.
* **§ 6.5 — Paris n'est couvert qu'à 4 circonscriptions sur 18 en 2009**, le
  découpage coupant à l'intérieur des arrondissements ; 45 atomes n'ont aucune
  circonscription en 2012, 8 atomes relèvent de deux circonscriptions en 1986.
* **§ 6.6 — 113 communes indéterminées de 1986**, déclarées telles par la
  source, qui écrit « circonscriptions 13 et 16 » sans répartir les communes.
* **§ 6.7 — Poids mort géométrique** : sept communes rétablies après 2011 dont
  l'atome porte le polygone de leur absorbante, sans trou de couverture mais
  sans territoire propre.
* **§ 6.8 — Cinq limites propres à ANR** : les 333 fractions qu'il ne sait pas
  découper ; la Corse livrée en instantané (360 polygones justes, zéro édition
  historique contre 27,1 % nationalement) ; l'absence de frontière nationale
  (§ 5) ; les 101 km² résiduels ; et **532 `id_com` sur 40 572 (1,31 %) ayant un
  trou de chronologie non déclaré** — 11 113 années-communes, médiane 12 ans,
  75 trous couvrant 1870 et 6 couvrant 1940.

---

## 5. Ce qui bloque encore

1. **La frontière nationale, pour l'extension avant 1870.** ANR **dessine la
   France actuelle à toute date** : la Savoie et les Alpes-Maritimes y sont
   françaises en 1815 (769 communes, 14 899 km²), l'Alsace-Moselle en 1900
   (1 701 communes, 14 575 km²). Sans effet sur 1870-1940, où `membership`
   décide seul de ce qui s'affiche — mais poser 1815 depuis ANR sans rien faire
   d'autre, c'est annexer la Savoie quarante-cinq ans trop tôt. **La frontière
   devra venir de la nomenclature d'époque, département par département.**
2. **1986-1989 : 37 actes, aucun texte en clair, aucun dépouillé.** C'est le
   vrai mur de la période récente, et c'est aussi la fenêtre des 48 cantons
   créés entre 1986 et 1999, nommés et non datés.
3. **Les villes à découper** — 119 communes, 214 coupes, rien de tracé.
   La trame d'accrochage est en base (`iris_ville`, 4 219 IRIS, 211 coupes sur
   214 pourvues) ; le travail de digitalisation dans QGIS reste entier.
   Marseille est le cas d'école, protocole dans
   `annexes/gaudillere/protocole_georeferencement.md`.
4. **Six départements que le report ne rattrape pas** — 94, 95, 62, 77, 29, 91 :
   trop d'actes intercalés pour se résoudre contre 1999. Il leur faudrait un
   jalon intermédiaire, un recensement ou un acte que le registre ignore.

---

## 6. À vérifier en base — points ouverts, non tranchés

Ces points sont ouverts parce qu'ils demandent d'interroger la base ou une
pièce, pas parce qu'ils sont difficiles. Ils sont listés ici pour ne pas être
crus résolus.

**Ils se tranchent en une commande** :

```bash
psql -d histgis -f sql/diag_passages.sql     # lecture seule
```

Elle confronte l'inventaire des tables de trace **attendues** à ce que la base
porte (§ 1), relit `38` et `39` par leur effet (§ 2), et lit par leur effet ceux
dont la trace manque ou est vide (§ 4). Écrite le 2 septembre 2026, précisément
parce que la question « ce fichier est-il passé ? » n'avait pas de réponse.

### Ce que le premier passage a rendu, le 2 septembre 2026

**35 traces peuplées sur 44, aucune trace orpheline** — l'inventaire couvrait
exactement ce que la base porte. Restent neuf lignes, qui ne disent pas toutes
la même chose :

> **L'inventaire est passé à 46 le soir même**, `p38_trace` et `p39_trace`
> ayant été écrites (§ ci-dessous). Elles compteront pour absentes tant que les
> deux fichiers n'auront pas été rejoués, et ce sera exact : *un dénominateur
> qui change est ce qui arrive à toute mesure qu'on continue d'améliorer ; le
> chiffre de 35/44 vaut pour le 2 septembre au matin, il n'a pas à être
> réécrit.*

| fichier | trace | lecture |
|---|---|---|
| `32_marseille_geom` | absente | **normal** — attend le géoréférencement, chantier ouvert |
| `43_circo_fraction` | absente | **normal** — exclu de `rejouer_apres_rebuild.sh` exprès : il ne répare qu'après un rejeu *isolé* de `24` |
| `50_noms_perdus_trfgis` | vide | a tourné **avec** `appliquer=1` (sa trace n'existe que dans ce cas) et n'a rien eu à réparer |
| `42_rattachement_arriere` | vide | a tourné, zéro cas — état sain **si** Chisa et Butry ont bien leur passé (§ 4 e) |
| `37_reparer_encodage` | absente | **expliquée le 2 septembre : aucun script ne l'appelait.** `load_cog.sh` ne joue que `22` et `23`, alors que l'étape s'intitulait « 22, 36, 37, 23 ». Corrigé dans `rejouer_apres_rebuild.sh` |
| `25_pseudo_canton` | absente | **expliquée le 2 septembre : son prérequis n'existait qu'en commentaire.** `geofla_canton` n'était chargée par aucun script ; `25` s'arrêtait sur son garde-fou. Le chargement `ogr2ogr` est entré dans la chaîne |
| `40_outremer` | absente | **expliquée le 2 septembre : idem.** `om_commune_src` vient de `charger_outremer.sh`, que rien n'appelait. Le script est désormais appelé avant `40`, sous condition de présence des lots |
| `81_report_1968_avant` (×2) | absentes | attendu : le fichier n'a jamais été joué |

Les trois lignes en gras étaient les seules qui appelaient une action ; leur
cause est trouvée et les correctifs sont écrits (`JOURNAL.md`, 2 septembre).
**Elle est commune aux trois** : un prérequis qui n'est écrit qu'en commentaire
est un prérequis absent. Et comme `25` lève une `EXCEPTION` sous
`set -euo pipefail`, la chaîne ne pouvait pas aller au-delà de lui — ce qui
prouve, par l'autre bout, que tout ce qui a une trace au-delà a été joué à la
main.

Rien n'est vérifié tant que le script corrigé n'a pas tourné. Le § 4 du
diagnostic reste le juge, par l'**effet** : `25` par ses 25 rattachements
d'arrondissement au 1ᵉʳ juin 2012, `40` par la présence des tables `om_*`, `37`
par les octets de contrôle C1 dans `unit.nom` et `unit_version.nom` — étant
entendu que `37` peut légitimement n'avoir rien à réparer, `load_cog.sh` lisant
désormais le COG en `WIN1252`.

*Une trace absente n'est pas un défaut par elle-même ; c'est une question. Neuf
alarmes indistinctes valent moins que trois alarmes triées, et un diagnostic qui
crie à chaque passage cesse d'être lu.*

* **`39` ne couvrait qu'un étage sur deux — trouvé le 6 septembre 2026.** Sa
  clause porte `u.niveau = 'canton'`, et il restait **une unité en `99`** au
  niveau circo : `L9901@1870`, la Meurthe au scrutin de liste, 714
  rattachements. Elle suffisait à faire vivre un 99ᵉ département dans tout ce
  qui énumère `SELECT DISTINCT dep FROM unit`, l'export web en tête — et,
  surtout, **elle coupait la Meurthe de 1870 en deux** : ses cantons dans le 54,
  sa circonscription dans un 99 sans cantons. `sql/92_meurthe_circo.sql` le
  corrige, avec sa trace ; **écrit et parsé, pas encore joué**
  (`RESTE_A_FAIRE.md` § 0 bis). *Un correctif qui vise un niveau laisse l'autre
  derrière lui, et la recette qui l'accompagne ne peut pas le dire : elle compte
  ce qu'on lui a demandé de compter.*
* ~~**`39_meurthe_1870.sql` est-il appliqué ?**~~ — **CLOS le 2 septembre 2026,
  trace comprise.** Rejoué ce soir-là avec `p39_trace` : **29 unités tracées**,
  0 canton en `99`, 73 en `54`, 52 en `57`, 31 en `55`, et zéro atome rattaché à
  deux cantons du 54 à la même date. La Meurthe rend bien ses 29 cantons au
  1ᵉʳ juin 1870. La question n'est plus « l'état est-il bon ? » mais « le fichier
  est-il passé ? », et la base répond désormais elle-même.
  *Le cas B du banc était le bon* : la trace visant l'`unit_id` `99xx` et non le
  département, elle s'est peuplée sur une base où le travail était déjà fait —
  `cantons_en_99_avant = 0`, et 29 lignes tout de même.
* **`81_report_1968_avant.sql` n'est PAS joué** — établi le 2 septembre par deux
  chemins : `p81_trace` et `p81_qualite` sont absentes de la base, et
  `snapshot(1969-06-01)` rend **0 rattachement**. Attendu au passage :
  ~32 842 lignes, ~191 000 atome-années, `1969-06-01` passant de 0 à des dizaines
  de milliers, et **1974 et au-delà ne devant pas bouger** — le repère est
  5 198 rattachements sur 474 cantons au 1ᵉʳ juin 1974.
* ~~**`38_decret_1982_ain.sql` est bloqué**~~ — **CLOS le 5 septembre 2026 :
  `38` EST APPLIQUÉ.** `sql/85_conflit_38_79.sql` a libéré les trois fractions
  et `38` est passé derrière, rendant **3 remontées, 3 `unit_version`, 0
  rattachement de commune entière** avec le WARNING de son § 7 — l'attendu
  exact. Son § 7 c rend enfin les trois cantons au 1ᵉʳ juin 1986 sous leurs
  noms de 1982, `valid_from = 1982-01-26` : Bourg-Est, Bourg-Nord-Centre,
  Bourg-Sud. **La ville n'est plus coupée par des cantons qui n'existaient
  pas**, ce qui était l'objet du fichier depuis le 17 août.

  Les trois issues posées ci-dessous ne sont plus la question, mais leur
  analyse reste utile et **deux d'entre elles étaient mal posées** :

  — *L'issue 3, renoncer, était à écarter.* Sur les trois fractions, `38` et
    `79` disent le MÊME canton ; le texte primaire couvre seize ans là où le
    report en couvre dix. Laisser l'inférence primer sur l'acte qui la fonde
    n'était pas défendable.
  — *Les issues 1 et 2 étaient équivalentes, et démontrablement.* `79` n'écrit
    que sur une fenêtre entièrement libre (§ 5, `p79_libre`) ; rejoué après
    `38`, il se serait abstenu de lui-même. Le rejeu complet coûtait
    36 296 lignes pour le même état.
  — *Et le vrai correctif n'était aucune des trois : c'est l'ORDRE.* Le conflit
    n'existait que parce que `79` a été joué à la main, hors chaîne, après
    `38`. Quand `rejouer_apres_rebuild.sh` sera complété jusqu'à `83`, `38`
    devant `79` (il y est déjà, ligne 233), `85` deviendra inutile.

  **CE QUI RESTE OUVERT, ET QUI EST NEUF.** Le décret rattache aussi trois
  communes entières — Montagnat, Saint-Just, Saint-Denis-lès-Bourg — et elles
  sont occupées sur `[1985-03-10, 1992-03-22)` par `0139` Péronnas et `0143`
  Viriat, les deux successeurs de **Bourg-Couronne**. La transcription du JO
  donne pourtant raison à `38` sur 1982. Comme les bornes de l'occupant sont
  deux scrutins cantonaux, l'acte qu'il porte est **postérieur** au décret :
  il n'y a alors pas de désaccord mais **une fenêtre de `38` § 6 trop large**,
  qui court jusqu'en 1999 quand le décret ne vaut que jusqu'à l'acte suivant.
  La fenêtre réellement libre est `[1982-01-26, 1985-03-10)`.

  **L'OCCUPANT EST NOMMÉ : c'est `76`, et l'hypothèse est confirmée.** Le § 3
  bis élargi rend `canton_decret = Péronnas` pour Montagnat et Saint-Just,
  `Viriat` pour Saint-Denis, `n_actes = 1`, `provenance = 'jo'` (dépouillé de
  l'OCR du Journal officiel), convention `scrutin_suivant`. La borne basse au
  scrutin du 10 mars 1985 situe l'acte **entre mars 1982 et mars 1985**, donc
  après le décret 82-77.

  **Il n'y a donc aucun désaccord entre les deux sources** : un acte postérieur
  a déplacé ces trois communes vers Bourg-Couronne — devenu Péronnas et Viriat
  — et `38` § 6 prétend simplement courir jusqu'en 1999 quand le décret ne vaut
  que jusqu'à cet acte. Le correctif est d'une ligne, et il n'est pas fait :
  borner le § 6 de `38` à la date d'effet de l'acte suivant plutôt qu'à
  `1999-01-01`.

  *J'avais d'abord attribué l'occupant à `75` sur la seule forme de ses bornes,
  deux scrutins cantonaux. Mais `76` emploie la même convention, et `77` pose
  aussi des communes entières : une convention de dates partagée par trois
  fichiers ne désigne aucun des trois, elle ne fait que les rendre
  indiscernables. Seule la table de qualité tranche.*

  Pour mémoire, l'obstacle initial, mesuré le 2 septembre 2026 :

  ```
  REMONTEE IMPOSSIBLE — la fenetre 1982-1999 est deja prise :
    5260#0105 occupe par 0105 sur [1998-03-15,1999-01-01) ;
    5260#0137 occupe par 0137 sur [1998-03-15,1999-01-01) ;
    5260#0138 occupe par 0138 sur [1998-03-15,1999-01-01)
  ```

  **Ce n'est pas un désaccord de fond, c'est un conflit de bornes.** L'occupant
  attribue chaque fraction au MÊME canton que le décret de 1982 — `0105` occupe
  `5260#0105`. Les deux sources disent la même chose ; elles ne la font pas
  commencer à la même date. `38` la fait partir du texte (26 janvier 1982,
  publication au JO), l'occupant d'un plancher.

  **Présomption à vérifier, non encore prouvée** : `1998-03-15` a la forme d'un
  plancher de `79_report_1999_arriere.sql`, qui pose `[plancher, 1999-01-01)` par
  département, le plancher étant la date du dernier acte connu du registre. Une
  requête le dit :

  ```sql
  SELECT m.membership_id, m.atom_id, m.unit_id, m.periode,
         (SELECT count(*) FROM p79_trace t
           WHERE t.quoi='membership' AND t.cle = m.membership_id::text) AS pose_par_79
    FROM membership m
   WHERE m.niveau='canton' AND m.atom_id LIKE '5260#%'
   ORDER BY m.atom_id, m.valid_from;
  SELECT * FROM p79_plancher WHERE dep='01';
  ```

  **Trois issues, à trancher — aucune n'est un rafistolage :**

  1. *La voie du dépôt.* Défaire `79` par sa trace, jouer `38`, rejouer `79`.
     `79` ne pose que là où la fenêtre est entièrement libre : il cédera de
     lui-même les trois fractions à `38`, sans qu'aucune règle soit contournée.
     Coûteux (36 296 lignes) mais c'est la procédure écrite dans `sql/README.md`,
     et `81` n'est pas encore joué, donc l'ordre reste propre.
  2. *La voie chirurgicale.* Supprimer les trois lignes de l'occupant **et leurs
     lignes de trace**, puis jouer `38`. Équivalent au résultat de la voie 1 sur
     ces trois atomes seulement. À ne faire qu'en supprimant aussi la trace :
     une trace qui survit à ce qu'elle trace est l'anomalie que
     `diag_passages.sql` § 3 bis cherche.
  3. *Ne rien faire, et le dire.* L'occupant couvre 1998-1999 ; `38` ajouterait
     seize ans de couverture attestée par un texte primaire. Renoncer est
     défendable si l'on tient que `38` doit céder devant une couche systématique,
     mais alors il faut le décider, pas le subir.

  **Ce que le refus a prouvé au passage** : le § 3 fait son travail. Sans lui,
  la transaction serait tombée sur une violation d'`EXCLUDE` illisible — et
  avant le 2 septembre, sur rien du tout.

  Les deux autres parts du décret (les trois `unit_version` de 1982, les trois
  communes entières) n'ont pas été atteintes : le refus est intervenu avant.
  Leur état reste inconnu.

* **Chisa et Butry-sur-Oise — à trancher.** `ETAT.md` les rangeait parmi les
  « territoires neufs » aux côtés de Tende et La Brigue, et `METHODE.md` parmi
  les créations d'avant 1943 hors de portée du fichier INSEE. **Les deux étaient
  faux** : `insee_mvt` documente Chisa (`mod 20`, 12 avril 1947, détachée de
  Ventiseri) et Butry (1ᵉʳ août 1948, d'Auvers-sur-Oise). Le traitement a été
  fait par `42_rattachement_arriere.sql` ; c'est la **rédaction** qui restait
  fausse — corrigée ici et dans `METHODE.md` le 2 septembre.
* **Deux rattachements dans le trou 1941-1998** que la recette de `24` comptait
  sans les attendre. L'un est la ligne de `38` (décret de 1982, donnée réelle,
  exception légitime) ; l'autre n'a jamais été identifié. La recette a depuis été
  réécrite pour contrôler une filiation plutôt qu'une absence.
* **Le canton `1930`** de 1951 et celui de 1999 ne partagent qu'une commune sur
  sept : identité douteuse, à trancher par le registre cantonal.
* **Le doublon 99/57 sur neuf noms de cantons** — Albestroff, Château-Salins,
  Delme, Dieuze, Fénétrange, Lorquin, Phalsbourg, Sarrebourg, Vic-sur-Seille,
  exactement les cantons annexés. Communes distinctes de part et d'autre, aucun
  double rattachement. Question sur la source, à porter à Victor Gay.
* **Oyonnax** : l'annexe VII dit « dédoublement », donc canton source disparu ;
  l'Insee garde le code `0123` renommé Oyonnax-Nord.
* **Le fond cantonal de Gaudillère est-il datable ?** Si une nomenclature
  d'époque permettait d'en identifier le millésime, tout l'atlas deviendrait
  exploitable d'un coup. Question à poser à Victor Gay.
* **Numérotation `sql/`** : deux fichiers portent le numéro `40`
  (`40_outremer.sql`, `40_scission_circo.sql`), et le « `82`, le chaînage acte
  par acte » évoqué dans les notes d'août entre en collision avec
  `82_anr_geom.sql`. Le chaînage devra prendre un numéro libre.
  **Le piège a resservi le 6 septembre 2026** : `92_meurthe_circo.sql` avait
  d'abord été écrit en `86`, où `86_reprise_mosaique.sql` l'attendait. Attrapé
  avant le premier appel, en comptant les préfixes plutôt qu'en regardant la fin
  de `ls`, qui trie `diag_*` après les chiffres et ne montre donc jamais le
  dernier numéro. *Un doublon de numéro ne se voit pas au moment où on le crée ;
  il se voit quand on compte, et il faut compter exprès.* Le plus haut numéro
  occupé est aujourd'hui `91`.

---

## 7. Ce que la carte web sait faire, depuis le 1ᵉʳ septembre

`cartes/export_web.py` a été réécrit pour la trame datée. L'affirmation qui
tenait toute son architecture — *la géométrie d'un atome ne change jamais* — est
devenue fausse avec `atom_geom_anr`, et la brancher sans toucher au reste aurait
produit une carte qui se trompe **en silence**.

Ce qui est posé : `communes.json` porte par atome une **liste de versions**
`v: [{a, k, c, g, r}]` ; la signature couvre la composition **et** les `poly_id`
en vigueur ; `annees_candidates()` lit la troisième famille de bornes ; le nom
de fichier est le md5 du **contenu sérialisé**, la signature d'entrée ne servant
plus qu'à décider ce qu'il faut recalculer. Un intervalle sans géométrie s'écrit
**comme vide** (`g: null`) et la commune n'est pas dessinée — ne rien écrire
n'est pas neutre quand le lecteur en aval prolonge la version précédente.

Le repli est écrit, pas subi : chaque version porte `r`, chaque unité porte
`n_anr` et `n_repli`, et la page affiche séparément l'export sans épaisseur,
les communes en repli à cette année, et celles qu'aucune source ne sait
dessiner.

**Deux choses ne se vérifieront qu'après un export réel complet** : le poids
(attendu 92 Mo → deux à trois fois plus) et la **coïncidence visuelle** des
limites cantonales et communales sur une année où ANR édite un polygone — c'est
là, et seulement là, que se verrait une erreur d'ordre d'opérations.

---

## 8. Comment tout se rejoue

```bash
cd ~/Téléchargements/projet_carte/sql
./rebuild.sh                 # load.sh → GEOFLA → 05 → 06 → 07 → 11 → 15
./rejouer_apres_rebuild.sh   # le reste de la chaîne, dans l'ordre
./controle_gay.sh            # contrôle indépendant, facultatif, exige gdal-bin
```

`rebuild.sh` est **destructif** — `load.sh` fait `DROP SCHEMA histgis CASCADE` —
et c'est voulu : `geom_correspondance.csv` et les CSV de `build/` sont lus par
`02_load.sql`, rejouer `05` seul ne servirait à rien.

**Lire « Qui dépend de qui » dans `sql/README.md` avant de rejouer un fichier
isolé**, et `sql/CHAINE.md` pour l'inventaire complet. Deux mécanismes cassent la
chaîne sans le dire : un fichier qui crée des unités ne peut pas être rejoué tant
qu'un autre les référence (clé étrangère), et la suppression de ses atomes emporte
par cascade ce que d'autres ont posé dessus. **Un résultat obtenu sur une base à
demi reconstruite est indiscernable d'un résultat juste.**

**Piège de propagation** : si seuls les `.sql` circulent entre les deux dossiers,
`build/`, `geom_correspondance.csv` et les notes peuvent être périmés d'un côté
sans que rien ne le signale. Le correctif Marseille est resté sans effet une
journée entière pour cette raison.
