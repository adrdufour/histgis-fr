# Divergences entre l'atlas Gaudillère et TRF-GIS

## RÉSOLU — l'auteur explique lui-même son fond cantonal

*Atlas historique des circonscriptions électorales françaises*, « Méthodologie
cartographique », p. 828. Ces pages tranchent D1 et D4, et fixent une fois pour
toutes ce qu'on peut demander à cet atlas.

L'auteur écarte d'emblée la cartographie rigoureuse : donner à chaque canton sa
configuration exacte de 1820, 1852 ou 1876 aurait exigé le dépouillement des
procès-verbaux d'élections ou des *Bulletins des lois*, « un tel travail, mené
dans quatre-vingt-dix départements, excédait de très loin les capacités d'un
chercheur isolé ».

> « On a donc, dans la plupart des cas, donné aux cantons **leurs limites
> actuelles**, mais en y apportant de nombreuses corrections. »

Le fond est donc celui des années 1980. Les corrections viennent de la « carte
Donnet » (1817, révisée 1884), du *Dictionnaire topographique* et de *Paroisses
et communes de France*, des arrêtés consulaires de 1801-1802, et surtout :

> « les lois et décrets créant de nouveaux cantons après 1801-1802. On en
> trouvera la **liste exhaustive à l'annexe VI**. »

Et l'auteur chiffre son propre résidu : « quelques centaines de communes à
peine — sur 38 000 — ont changé de canton depuis 1801-1802 ».

### La distinction que ça établit

Elle recoupe exactement celle que le registre avait adoptée :

| information | statut dans l'atlas | usage |
|---|---|---|
| **Existence d'un canton** à une date | corrigée exhaustivement (annexe VI) | fiable → `borne_sup` |
| **Rattachement d'une commune** à un canton | fond actuel, non corrigé | non fiable |

D1 et D4 sont donc résolus, et par le même mécanisme : Samoussy,
Martigny-Courpierre, Marigny-en-Orxois, Loupeigne et Les Omergues figurent dans
leur canton **des années 1980**, TRF-GIS dans leur canton d'époque. Ce sont
cinq des « quelques centaines » que l'auteur annonce. **Aucune des deux sources
n'a tort.**

Corollaire, qui invalide un raisonnement tenu en cours de route : qu'une carte
de 1986 diffère d'une carte de 1958 ne prouve pas que le fond suive les
rattachements. Les cantons *créés* entre les deux y apparaissent, et cela
suffit à expliquer la différence. Une correspondance 1940↔1958 sur les
rattachements est vraie par construction.

### Ce qu'il faut aller chercher : l'annexe VI

C'est la pièce la plus précieuse de l'ouvrage pour ce projet. Une liste
**exhaustive et datée** des lois et décrets créant des cantons depuis 1801
donnerait aux démembrements du registre des dates d'acte — `certitude = acte` —
là où ils portent aujourd'hui des intervalles de vingt-huit ans.

Elle réglerait aussi, seule, une bonne part du trou cantonal 1941-1998.

---

## Ce qui reste ouvert

Registre des désaccords **à ne pas arbitrer** tant qu'une troisième source
n'est pas disponible. Deux sont attendues :

- **ANR-COMMUNES**, embargo levé le 1ᵉʳ septembre 2026
  (Zenodo `10.5281/zenodo.3727274`) — trame communale historique ;
- **Victor Gay**, sollicité le 10 août 2026 sur la nomenclature cantonale de
  1954 dont son `ct_codes.do` prouve qu'il a disposé.

Chaque entrée est écrite pour être **rejouable** le jour où l'arbitre arrive :
commune, date, ce que dit chaque source, et ce qui a été fait en attendant.

## Pourquoi ne pas trancher

Les deux sources peuvent être justes en même temps. L'atlas cartographie des
**circonscriptions** ; les cantons n'y figurent que pour les délimiter, et rien
ne garantit que leur fond soit du millésime de la planche qui le porte. Un
auteur compose rarement un fond neuf pour chaque carte.

Arbitrer en faveur de TRF-GIS reviendrait à supposer ce qu'on cherche à
vérifier. Arbitrer en faveur de l'atlas ferait perdre au contrôle son
indépendance, comme pour les quatre paris perdus du correctif de scission,
laissés en l'état pour cette raison même.

---

## D1 — Quatre communes de l'Aisne, carte des circonscriptions de 1876

| commune | insee | atlas 1876 | TRF-GIS 1876 | circonscription (les deux) |
|---|---|---|---|---|
| Samoussy | 02697 | Laon | Sissonne | Laon-1 |
| Martigny-Courpierre | 02471 | Laon | Craonne | Laon-1 |
| Marigny-en-Orxois | 02465 | Charly | Château-Thierry | Château-Thierry |
| Loupeigne | 02442 | Fère-en-Tardenois | Oulchy-le-Château | Soissons |

**Ce qui concorde** : la circonscription, dans les quatre cas. Les deux sources
décrivent le même découpage électoral en passant par des cantons différents.

**Ce qui diverge** : le canton, et toujours vers un canton **limitrophe** — ce
qui exclut une erreur grossière de part et d'autre.

**Un détail qui oriente** : TRF-GIS fait passer Loupeigne d'Oulchy-le-Château à
Fère-en-Tardenois en **1924**. La base connaît donc le rattachement que
l'atlas montre, mais quarante-huit ans plus tard. Si le fond cantonal de
l'atlas était postérieur à ses planches, ce décalage s'expliquerait seul.

**Ce qui a été fait** : rien de corrigé. Le resserrement de Missy-aux-Bois,
obtenu par le même geste de lecture, a été **retiré** — son intervalle est
rendu à `[1940, 1999]`.

**Ce qui reste utilisable de l'atlas** : quels cantons **existent** à la date
d'une carte. Information de nomenclature, non d'appartenance ; c'est elle qui
borne les démembrements de l'Aisne à `[1958, 1986]`.

**Comment trancher, le jour venu** : une nomenclature cantonale d'époque —
celle de 1954 pour la période moderne, un *Bulletin des lois* pour 1876 —
donnant la composition communale du canton de Laon. Si Samoussy y figure,
l'atlas a raison et TRF-GIS manque des mouvements anciens ; sinon l'inverse.

---

## D2 — Densité des mouvements cantonaux anciens dans l'Aisne

TRF-GIS ne porte que **six dates de bascule et huit rattachements** entre 1870
et 1941, pour 834 communes : 1872, 1879, 1883 (×2), 1896, 1923, 1924 (×2).

Deux lectures, que rien ne départage pour l'instant. Soit les cantons de la
Troisième République étaient effectivement quasi immobiles — ce qui est
plausible et connu. Soit TRF-GIS ne capte qu'une fraction des mouvements
anciens, et les quatre observations de D1 en sont des exemples.

**Comment trancher** : appliquer le même comptage à plusieurs départements. Un
chiffre uniformément bas dans toute la France plaide pour la stabilité réelle ;
de fortes disparités sans cause historique plaideraient pour une couverture
inégale de la source.

---

## C1 — Concordance : cinq polygones contestés des Alpes-de-Haute-Provence

Contrepoint de D1, et le premier accord net entre l'atlas et la couche
cantonale.

Sur les polygones que plusieurs cantons revendiquent — parce que plusieurs
communes d'époque fondues depuis n'ont qu'une géométrie pour toutes — l'atlas
donne :

| polygone | atlas | TRF-GIS, atome `geofla` |
|---|---|---|
| Mallefougasse-Augès | Saint-Étienne-les-Orgues | Saint-Étienne-les-Orgues |
| Le Chaffaut-Saint-Jurson | Digne | Digne |
| La Robine-sur-Galabre | Digne | à vérifier |
| Majastres | Senez | Senez |
| Saint-Michel-l'Observatoire | Forcalquier | Forcalquier |
| Thorame-Haute | Colmars | Colmars |

**Cinq sur cinq.**

### Ce que cette concordance ne valide pas

L'atome `geofla` est celui de la commune **survivante**, entité qui n'existe
qu'après la fusion. Les atomes de source `successeur` — Augès dans Peyruis,
Levens dans Moustiers-Sainte-Marie, Colle-Saint-Michel et Peyresq dans
Saint-André-les-Alpes — portent le canton de communes **mortes**, et restent
invérifiés. Une carte qui ne les montre pas séparément ne peut rien en dire.

### Pourquoi il ne faut pas « trancher »

La tentation est de choisir un canton par polygone pour faire disparaître les
hachures. Ce serait une faute : sur ces polygones **la base n'est pas ambiguë,
elle est exacte deux fois**. Augès relevait de Peyruis, Mallefougasse de
Saint-Étienne-les-Orgues — deux communes distinctes, deux cantons distincts,
deux faits vrais. Ce qui est faux, c'est qu'elles partagent un polygone.

Arbitrer effacerait une information juste pour supprimer un symptôme. Le jour
où ANR-COMMUNES livrera la trame communale historique, chaque commune
retrouvera sa géométrie propre et les deux rattachements redeviendront
lisibles — à condition de les avoir gardés.

---

## D4 — Les Omergues (04140) : Banon ou Noyers-sur-Jabron ?

| source | canton | période |
|---|---|---|
| Gaudillère | Banon | **toutes** les cartes |
| TRF-GIS | Noyers-sur-Jabron | 1870-1941 |
| COG Insee | Noyers-sur-Jabron | 1999-2013 |

Le désaccord le plus net du registre. Les deux sources sont **internement
stables** et se contredisent sur toute la durée : aucune question de datation
ne peut l'expliquer. L'une des deux se trompe, ou décrit autre chose.

À noter : la base ne dit rien entre 1941 et 1999 — c'est le trou cantonal, à
sa place.

### Le motif se répète

Troisième fois, deuxième département. Dans l'Aisne (D1), quatre communes que
l'atlas place dans un canton **limitrophe** de celui de TRF-GIS. Ici, une
cinquième.

Ce motif — désaccord rare, toujours vers un canton voisin, jamais lointain —
est exactement ce que produirait une **nomenclature cantonale d'une autre
année**. Quelques communes de bordure changent de canton au fil des décennies ;
deux sources calées sur deux millésimes différents divergeront sur celles-là et
sur aucune autre.

Si c'est la bonne explication, elle est réconciliante : les deux sources
seraient justes, chacune à sa date, et il ne manquerait que de savoir laquelle.

**Comment trancher** : une nomenclature cantonale datée. Si Les Omergues relève
de Banon à une année et de Noyers-sur-Jabron à une autre, le motif est
confirmé et le millésime du fond de Gaudillère devient identifiable — ce qui
rendrait tout l'atlas exploitable d'un coup.

---

## D3 — Date de disparition de Lompnes (01220)

La nomenclature TRF-GIS classe Lompnes en `com_act = 2`, « ancienne, **post-
1943** ». Or elle est absente du fichier de mouvements de l'Insee, qui commence
en 1943 — ce qui la place **avant**. En 1964, la commune absorbante porte déjà
le nom composé Hauteville-Lompnes.

Écart d'un ou deux ans sur une commune. Sans effet sur le traitement — dans les
deux cas elle sort de la couche moderne — mais consigné plutôt que lissé.
