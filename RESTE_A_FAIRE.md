# Ce qui reste à faire — état au 14 août 2026

Dressé après la journée du 14 août. Les tâches sont classées par chantier, et
dans chacun par ordre de valeur, pas de facilité. Le blocage est indiqué quand
il y en a un : beaucoup de choses attendent quelque chose plutôt que quelqu'un.

---

## 1. Le trou cantonal 1955-1998 — le seul blocage structurel

C'était le seul obstacle à l'objectif du projet. Il n'est plus un mur mais une
série de jalons à extraire.

| tâche | état | blocage |
|---|---|---|
| **Récupérer un fascicule de 1968** et le passer dans la chaîne | à faire | **site BNSP indisponible** |
| Vérifier d'abord si le PDF de 1968 a une couche texte (`pdftotext -layout`) | à faire | idem |
| Extraire les 87 fascicules de 1968 | à faire | dépend du test ci-dessus |
| Vérifier l'existence de 1975, 1982, 1990 dans la série | à faire | idem |
| 1962 : confirmé présent, à extraire | à faire | idem |

**Premier fascicule conseillé : Calvados ou Aisne**, dont on a déjà la
composition de 1940 et de 1954 — trois dates à confronter au lieu de deux.

L'outil est prêt : `extrait_1954.py --pdf … --dep 14`. Sur un fascicule
départemental le département est dans le titre, donc toute la détection
d'en-tête et le redécoupage alphabétique deviennent inutiles.

## 2. Le volume de 1954 — acquis, perfectible

**Acquis** : trois créations cantonales établies par trois voies indépendantes,
98 % de stabilité 1940-1954, tableau A transcrit.

| tâche | valeur | difficulté |
|---|---|---|
| **Ajouter `insee_mvt.libelle_av` au dictionnaire de noms** | forte, **et démontrée** | faible |
| Remonter la couverture au-delà de 79 % | moyenne | moyenne |
| Poser 1954 dans la base (`membership` 1940 → 1954 + 3 créations) | forte | moyenne |

Le premier point est le meilleur rapport : 7 576 noms non appariés, dont une
part importante sont des communes disparues avant 2011, donc absentes de GEOFLA
qui sert de dictionnaire. Les ajouter ne touche pas à l'extraction.

**Le correctif a été mesuré ailleurs le 15 août** : appliqué aux rejets de
`composition_decrets.py`, `insee_mvt.libelle_av` en récupère 33 %, à condition
de contraindre le département. Le même dictionnaire sert les deux chantiers,
et l'implémentation est déjà écrite dans `cantons/composition_decrets.py`
(`communes_disparues()`) — il n'y a qu'à la reprendre.

**Abandonné, et à ne pas reprendre par cette voie** : les transferts de
communes entre cantons. 311 candidats, 227 réfutés par la géométrie, les
survivants indiscernables du bruit. Le volume dit qu'il y en a eu ; notre
lecture ne peut pas les distinguer d'un chiffre mal reconnu.

## 3. Paris — trame posée, découpage à finir

**Acquis** : les 80 quartiers reconstruits par union d'IRIS en Licence Ouverte,
80/80 noms confirmés par l'atlas, 386 circonscriptions posées sur 15 divisions,
`paris_circo.pdf` généré.

| tâche | valeur | blocage |
|---|---|---|
| **Les quartiers coupés par une rue** — 3 à 9 par division, 9 pour 1958-1986 | forte | axes BD TOPO à récupérer |
| Corriger la coquille de `paris_decoupage.xlsx` | faible | aucun |
| Dater la période `?-?` (37 circonscriptions complètes, sans date) | moyenne | pièces à trouver |
| La trame d'avant 1860 — 48 quartiers, 12 arrondissements | moyenne | **licence** |

La coquille : en 1857-1863, `montdepietemarais` fusionne deux quartiers en une
cellule, d'où 47 quartiers au lieu de 48. Les quatre autres périodes anciennes
en donnent bien 48.

L'avant-1860 : la couche ALPAGE-Vasserot existe et couvre exactement les 48
quartiers, mais elle est en **ODbL**. Route propre : géoréférencer un plan du
XIXe en domaine public, protocole de Marseille.

## 4. Les villes à découper — 119, et rien n'est commencé

| tâche | valeur | blocage |
|---|---|---|
| **Marseille** : géoréférencer et digitaliser dans QGIS | forte | à faire à la main |
| Puis lancer `sql/32_marseille_geom.sql` | — | dépend du précédent |
| Les 118 autres villes | forte | même travail |
| ~~Tester CONTOURS-IRIS comme trame de découpe~~ | **fait le 14 août — la trame est bonne** | — |
| ~~Récupérer les IRIS des 119 villes~~ | **fait le 14 août — `histgis.iris_ville`, 4 219 IRIS** | — |

**Testé, et l'hypothèse tient.** CONTOURS-IRIS couvre **97 % des villes et
88 % des coupes**, contre 26 % pour ADMIN EXPRESS. Le chantier réel est de
**214 coupes** et non 472, dont **81 villes à trait unique**. Seules Confolens
et Tartas, sous 5 000 habitants, sont sans trame — une coupe chacune.

**La trame est récupérée et chargée** : `histgis.iris_ville`, 4 219 IRIS, les
119 villes servies, **211 coupes sur 214** pourvues d'au moins une ligne
interne. Marseille (393 IRIS) et Lyon (185) sont les mieux dotées, ce qui tombe
bien puisqu'elles portent 23 des 214 coupes.

Trois villes sans appui, une coupe chacune : Confolens, Tartas et **Le Quesnoy**
— cette dernière n'était pas prévue par le seuil de population, elle est
apparue à la récupération.

Reste à mesurer le **taux de reprise réel** ville par ville dans QGIS : disposer
d'une ligne n'est pas disposer de la bonne. Marseille en premier, ses onze
lignes étant décrites dans `gaudillere/protocole_georeferencement.md`.

## 5. Circonscriptions législatives

| tâche | valeur | blocage |
|---|---|---|
| Contrôler la couche circo par l'annexe VI §§ 1, 3, 4, 6 | forte | aucun |
| `circo_1986_indetermine.csv` : 135 communes, 24 cantons à valeur textuelle | moyenne | aucun |
| Poser les circos nationales sur la trame cantonale | forte | **trou cantonal** |

Les sections 1, 3, 4 et 6 de l'annexe VI ne passent pas par les cantons : elles
sont contrôlables tout de suite, indépendamment du trou.

## 6. Dettes et démarches

| tâche | état |
|---|---|
| **Envoyer le rapport à Victor Gay** — `cantons/rapport_pour_victor_gay.md` | rédigé, à relire et envoyer |
| Confirmer la licence Cassini EHESS auprès du CRH avant publication | à faire |
| CRH-EHESS et INSEE : relancer ? | courriels du 10 août sans réponse |
| **Embargo ANR-COMMUNES** : levée le 1er septembre 2026 | attendre |

L'ANR-COMMUNES réglerait à la racine les recouvrements et les trous de
couverture. C'est dans deux semaines.

## 7. Limites connues, non résolues

* **Recouvrements** : 12 822 km² au niveau des cantons, 3 945 km² au niveau des
  atomes. Diagnostiqués — c'est le partage de polygone entre communes absorbées
  — mais non corrigés. Le correctif viendra de l'ANR.
* **`hac_partage`** : rattachement par nom, arbitraire et révocable. Le contrôle
  Gay ne peut ni le condamner ni l'innocenter.
* **48 cantons créés entre 1986 et 1999** : nommés, non datés. Il faut une
  source couvrant cette période.
* **274 transferts isolés de communes** dans le registre cantonal : l'annexe VII
  ne recense jamais ce type de mouvement. Indatables sans les décrets.

## 8. Hygiène du dépôt

| tâche | valeur | difficulté |
|---|---|---|
| Écrire `environment.yml` ou `requirements.txt` | moyenne | triviale |
| Regrouper les scripts de 1954 sous un nom générique (ils serviront à 1968) | faible | faible |

Aucun fichier d'environnement n'existe : psycopg2, matplotlib, shapely,
openpyxl, xlrd, pyshp, pyproj sont utilisés sans être déclarés nulle part.

---

## Ce qui se ferait le mieux maintenant, site indisponible

1. ~~Tester CONTOURS-IRIS~~, ~~récupérer les IRIS~~ — **faits**. 4 219 IRIS en
   base, 211 coupes sur 214 pourvues. Suite : **attaquer Marseille dans QGIS**,
   et mesurer le taux de reprise réel.
2. **Ajouter `insee_mvt.libelle_av`** au dictionnaire de noms de 1954.
3. **Contrôler la couche circo** par les sections de l'annexe VI qui ne passent
   pas par les cantons.
4. **Relire et envoyer** le rapport à Victor Gay.

## Chisa et Butry-sur-Oise : le recodage casse le raccord de `15` — 17 août 2026

Trouvé par Adrien : **Chisa est absente de la Corse 1870-1940.** Ce n'est pas un
fait mais un trou, et la documentation du dépôt se trompe à son sujet.

`insee_mvt` documente sa création : `mod 20`, **1947-04-12**, détachée de
**Ventiseri** (20342). Elle n'est donc ni un « territoire neuf » (contrairement à
Tende et La Brigue, italiennes jusqu'en 1947), ni « créée avant 1943, hors de
portée du fichier INSEE ». `ETAT.md`, `METHODE.md` et `JOURNAL.md` disent les
deux, et les deux sont faux — **à corriger en même temps que le correctif**.

**La cause.** `15_creation_arriere.sql` trouve bien la fille : son test de
« commune sans atome » est géométrique et Chisa y figure. Mais il cherche
ensuite le mouvement par `i.com_ap = s.insee_com`, c'est-à-dire par le code
GEOFLA **moderne**. Or la création nomme `20366`, et la Corse a été recodée en
1976 : GEOFLA porte `2B366`. La mère aussi a bougé, `20342` → `2B342`. Le
`JOIN LATERAL ... ON true` étant un jointure interne, la fille est **écartée en
silence**.

**L'ampleur, mesurée.** Croisement des 904 recodages `mod 41` avec les créations
`mod 20/21` : **4 lignes, 2 communes.**

| commune | créée | mère | recodage |
|---|---|---|---|
| Chisa `2B366` | 1947-04-12 | Ventiseri `20342` → `2B342` | Corse 1976 |
| Butry-sur-Oise `95120` | 1948-08-01 | Auvers-sur-Oise `78039` → `95039` | Seine-et-Oise 1968 |

Le défaut ne va pas au-delà. Ordre de grandeur du territoire récupéré : ~32 km²,
sur les 238 km² encore non couverts en 1870 (les « 4 territoires neufs » valaient
303,61 km², dont 271,1 pour Tende et La Brigue).

**Le correctif retenu : amender `15`, pas écrire un `42`.** `15` est rejouable
par conception — il supprime ses propres atomes et vide `creation_trace` avant de
recommencer — donc il se relance seul, sans reconstruction. C'est la leçon
écrite le même jour dans `METHODE.md` : réparer la règle là où elle vit plutôt
que la rattraper en aval.

**Ce qu'il faut écrire.** Une table de résolution des codes bâtie sur `mod 41`,
appliquée aux deux bouts du `LATERAL` : `com_ap` résolu vers l'avant pour
retrouver la fille, `com_av` résolu vers l'avant pour retrouver la mère dans
GEOFLA.

**Attention, la résolution doit être TRANSITIVE.** Vérifié : quatre codes sont
recodés deux fois de suite — `78143` → `91143` et `78620` → `91620` passent par
un état intermédiaire. Un seul saut suffirait pour Chisa et Butry, mais une
résolution à un saut serait fausse en général, et c'est exactement le genre de
raccourci qui reviendra. Un `WITH RECURSIVE` sur `mod 41`, avec garde contre les
cycles.

**Recette** : Chisa et Butry doivent recevoir un atome-fraction
`source = 'creation_arriere'`, portant leur polygone GEOFLA et la chronologie de
Ventiseri / Auvers-sur-Oise ; le total des filles passe de 58 à 60 ; le non
couvert de 1870 baisse d'environ 32 km². Et le garde-fou 5 de `15` (territoire
déjà couvert, test par point intérieur) doit continuer d'écarter Marseille.

## Trois dettes découvertes le 17 août 2026 en cassant la base

Le rejeu de `15_creation_arriere.sql` a mis `24_canton_moderne.sql` en échec au
milieu de son travail : **37 261 rattachements cantonaux supprimés et non
reconstruits**. La base a été remise d'aplomb le jour même, mais trois défauts
de la chaîne sont apparus et restent à corriger.

### 1. `38_decret_1982_ain.sql` n'a aucune table de trace

Tous les fichiers qui posent des rattachements en ont une — `scission_trace`,
`creation_trace`, `canton_moderne_trace`, `retablissement_trace`… Lui insère
sans pouvoir défaire. C'est sa ligne unique (`31125` dans le canton `0138`, du
26 janvier 1982 au 1ᵉʳ janvier 1999) qui a bloqué la reconstruction de `24`, et
il a fallu la mettre de côté à la main dans une table `reprise_24`.

À faire : lui donner une trace sur le modèle des autres, et le rendre rejouable.

### 2. L'ordre de la chaîne n'est écrit nulle part — FAIT le 20 août 2026

**`24` ne peut pas être rejoué tant qu'un autre fichier occupe ses unités** —
la clé étrangère `membership_unit_fk` le refuse. Rien dans `sql/README.md` ne le
dit. La séquence de rattrapage était :

1. mettre de côté les rattachements portant sur les unités de `24` ;
2. jouer `24` ;
3. les remettre ;
4. rejouer `41` puis `42`, qui s'appuient sur la couche reconstruite.

Sans l'étape 4, `41` ne pose qu'une ligne au lieu de 17 — et rien ne signale que
le résultat est faux, puisqu'il est cohérent. **Un résultat obtenu sur une base
à demi reconstruite est indiscernable d'un résultat juste.**

**Fait** : section « Qui dépend de qui » en tête de `sql/README.md`, avec les
deux mécanismes (blocage de clé étrangère, destruction par cascade), le tableau
des dépendances mesurées et la séquence sûre de rejeu de `24`.

La cascade a d'ailleurs frappé une seconde fois le même jour, sans rien casser
de visible : la reconstruction de `24` a emporté les circonscriptions posées par
`27` et `28` sur ses 732 atomes-fractions. Corrigé par `43_circo_fraction.sql`.

### 3. Deux fichiers portent le numéro 40

`40_outremer.sql` et `40_scission_circo.sql`. Sans conséquence tant qu'on les
nomme en entier, mais la numérotation sert justement à donner l'ordre.

### Résidu à expliquer

La recette de `24` compte **2 rattachements dans le trou 1941-1998**, où elle en
attend zéro. L'un est la ligne de `38` — le décret de 1982 est une donnée réelle
dans cette période, donc une exception légitime à documenter plutôt qu'un
défaut. L'autre n'est pas identifié.

## Marquer les circonscriptions indéterminées de 1986 sur la carte

Trouvé le 20 août 2026 en refermant `43_circo_fraction.sql`.

**113 communes n'ont aucune circonscription de 1986 à 2013**, et c'est un fait
de la source, pas un défaut : le tableau officiel de 1986 écrit pour certains
cantons « circonscriptions 13 et 16 » en toutes lettres, sans répartir les
communes. Toutes sont recensées dans `circo/circo_1986_indetermine.csv`
(135 lignes). Elles se concentrent sur 18 cantons — Nord (67 communes), Rhône
(12), Bouches-du-Rhône (10), Bas-Rhin (10), Charente-Maritime (6), Drôme (6),
Seine-Saint-Denis (2) — dont **sept entièrement absents**.

**Le problème est d'affichage.** De 1987 à 1999 la couche cantonale n'existe
pas, donc seule celle des circonscriptions dessine les communes : ces 113
disparaissent purement et simplement. Or le projet a une règle explicite —
« ce qui n'a de nom nulle part est signalé comme tel, pas maquillé » — et une
absence silencieuse la contredit.

**À faire** : charger `circo_1986_indetermine.csv` dans une table
`circo_indetermine`, et faire dessiner ces communes par `export_web.py` avec un
figuré propre (hachure, comme les communes coupées), en indiquant les
circonscriptions candidates au survol. Pas de rattachement dans `membership` :
la source ne tranche pas, la base ne doit pas trancher non plus.

**Piste de résolution, à évaluer séparément** : pour chacune, les
circonscriptions candidates sont connues, et le découpage de 2009 rattache la
commune à l'une d'elles. Là où les limites n'ont pas bougé entre 1986 et 2009,
le rapprochement serait dicté par la source — même forme d'argument que la voie
`fraction` de `41`. À mesurer avant d'y toucher, et à ne poser que si la
correspondance est unique.

## Huit communes coupées entre circonscriptions sans l'être entre cantons

Écartées par `43_circo_fraction.sql`, garde-fou d'unicité : Lyon
(`69-13`/`69-14`), Nice (`06-07`/`06-08`), Marseille, et cinq fractions de
banlieue parisienne et mosellane. Le découpage législatif les partage, le
découpage cantonal non — **aucun atome ne peut porter la coupure**, puisque les
atomes-fractions sont taillés sur les cantons.

Même nature que les 132 pseudo-circonscriptions sans nom : il faudrait des
atomes-fractions taillés sur les circonscriptions, ce qui suppose une trame
géométrique du découpage législatif qu'on n'a pas.

## Reconduire une commune absente d'un millésime dans `trfgis_extract.py`

Trouvé le 20 août 2026 par Cherré (Sarthe, 72080), signalée absente de la carte
entre 1886 et 1888.

La nomenclature TRF-GIS donne un fichier par année. La ligne de Cherré figure
en 1885, **manque en 1886 et 1887**, et revient en 1888 **à l'identique** —
même canton de La Ferté-Bernard, même arrondissement, même département. C'est
une omission de la source, pas un événement administratif : aucune commune n'a
cessé d'exister deux ans pour renaître inchangée.

L'ampleur est minuscule et parfaitement mesurée. Trous intérieurs bornés par la
même unité, toutes couches confondues :

| durée | canton | circo | cause |
|---|---|---|---|
| 2 ans | 1 | 1 | Cherré — l'omission |
| 48 ans | 1 689 | 1 683 | Alsace-Moselle, 1871-1919, à laisser ouverte |

**Rien entre les deux.** La distribution est bimodale, ce qui rend un seuil
défendable : `44_lacune_nomenclature.sql` referme les trous de moins de cinq ans
bornés par la même unité.

**Le correctif est en aval.** Le vrai remède est dans `trfgis_extract.py` :
reconduire une commune absente d'un millésime lorsqu'elle reparaît inchangée au
suivant, en traçant la reconduction. Cela impose un `rebuild.sh` complet, d'où
le fichier SQL en attendant.

À vérifier au passage : la même omission touche-t-elle d'autres millésimes sans
laisser de trou intérieur — par exemple une commune absente du dernier fichier
d'une série, dont la période s'arrête simplement plus tôt ? Un trou intérieur se
voit ; une troncature en fin de série, non.
