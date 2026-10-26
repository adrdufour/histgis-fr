# Les décrets cantonaux et leur texte, 1941-1999

Comment les décrets ont été trouvés (Légifrance, tables du JO), lus (JO
numérisés, texte Légifrance 1990-1999, communes coupées) et ce qui peut en
entrer en base.

Réunit, le 26 octobre 2026, des notes jusque-là séparées. Chaque
partie est reprise telle quelle ; le tableau donne l'ancien nom de
fichier, que citent encore `JOURNAL.md` et les notes anciennes.

| partie | ancien fichier |
|---|---|
| Moissonnage Légifrance — les décrets cantonaux, 1958-1999 | `note_moisson_legifrance.md` |
| Décrets cantonaux 1973 / 1982 / 1984 — index et accès aux délimitations | `note_decrets_1973_1984.md` |
| Communes coupées entre plusieurs cantons — décrets de 1973, 1982 et 1984 | `note_communes_coupees.md` |
| Dépouillement des JO numérisés — 1 212 cantons, 194 décrets | `note_composition_jo.md` |
| 1990-1999 sur Légifrance — 100 % d'accord avec le COG, et cinq transferts que l'annexe VII ignore | `note_legifrance_1990_1999.md` |
| Les tables analytiques du JO, 1941-1990 — 11 octobre 2026 | `tables_jo.md` |
| Ce qui peut entrer en base, et dans quel ordre | `note_entree_en_base.md` |

## Moissonnage Légifrance — les décrets cantonaux, 1958-1999

Fichier produit : `cantons/decrets_cantonaux.csv` (343 décrets), qui remplace et
englobe `cantons/decrets_1973_1984.csv` (136).

Reproduction : `cantons/moisson_brute.txt` (la moisson telle qu'elle sort) et
`cantons/build_moisson.py` (le tri et la mise en forme).

---

### 1. Ce qui est acquis

**207 décrets nouveaux**, sur les 136 déjà repérés. Le moissonnage ne portait
que sur 1973, 1982 et 1984 ; il porte désormais sur tout le fonds JORF.

| période | déjà repérés | nouveaux | total |
|---|---|---|---|
| 1958-1972 | 0 | 18 | 18 |
| 1973 | 72 | 4 | 76 |
| 1974-1981 | 0 | 11 | 11 |
| 1982 | 43 | 17 | 60 |
| 1983-1989 | 21 | 74 | 95 |
| 1990-1999 | 0 | 83 | 83 |

#### La méthode, et pourquoi elle est exhaustive

Le fonds JORF de Légifrance est interrogé sur le **titre** seul, avec la requête
`cantons` (Légifrance lemmatise : `canton` et `cantons` rendent le même
ensemble), sans borne de date — les paramètres de date de l'interface sont
ignorés par le moteur, ce qui tombe bien. 805 titres en retour, plus 70 pour
`cantonales`, soit **871 titres distincts** pour tout le fonds, de 1937 à 2026.

**Contrôle de rappel** : les 136 décrets déjà repérés en 1973/1982/1984 sont
tous les 136 dans ces 871 titres. Le moissonnage précédent, fait par date de
signature, ne trouve donc rien que celui-ci ne trouve. C'est le meilleur
contrôle disponible : l'étalon est un dénombrement antérieur et indépendant,
et il est retrouvé sans exception.

Le filtre ne retient ensuite que les décrets de découpage : 343 sur 871.

#### Le piège du filtre, signalé et non effacé

Le premier tri perdait **un** décret sur 343 — le n° 82-35 (Pas-de-Calais).
Le motif d'exclusion du bruit vinicole, `/VINS?\b/`, avait mordu sur le canton
de **LIÉVIN**. Le décret est réinjecté explicitement dans `build_moisson.py`, où
la ligne porte son commentaire. Six autres textes sont écartés à la relecture et
nommés dans le script (caisses d'épargne, commissaires-priseurs, tribunal, deux
textes algériens hors champ, un texte de portée générale).

C'est la troisième fois que le contrôle de rappel contre un étalon existant
rattrape un défaut de filtre, et non un défaut de source.

---

### 2. Le résultat qui change quelque chose : 1990-1995

`RESTE_A_FAIRE.md` posait comme lacune n° 2 « toute liste d'actes pour
**1990-1995** — l'annexe VII s'arrête en 1989 et le COG 1999 ne remonte qu'à
avril 1995 ».

**49 décrets sont datés entre 1990 et 1995**, 83 entre 1990 et 1999. Et pour ces
textes-là, **Légifrance conserve le texte intégral** : pas de PDF, pas de
CAPTCHA, pas d'OCR. Vérifié sur le n° 91-218 (Seine-Maritime), dont les
articles s'affichent en clair — c'est le décret du renumérotage du Havre déjà
connu par `note_registre.md` (partie « Datation des 64 cantons post_1986 »).

La lacune 1990-1995 n'est donc plus documentaire. Elle est à dépouiller, et
`composition_decrets.py` sait déjà lire cette prose.

> **Suite, 29 août 2026 : la veine est ÉPUISÉE, pas inexploitée.** Les 83
> décrets de 1990-1999 ont tous été lus. **19 portent une composition
> cantonale** (en base par `76`), 4 déplacent une commune entière (posés par
> `77`), **40 transfèrent des parcelles entre communes** — un non-événement pour
> le `membership` —, 29 sont des tracés de rues sans liste de communes, et 10
> n'ont pas de texte sur Légifrance (non numérotés, 1990 et 1992).
>
> Erreur à ne pas refaire : l'absence de 1990, 1992, 1994-96 et 1998-99 dans
> `composition_legifrance.csv` avait été lue comme « pas dépouillé ». C'était
> « dépouillé, et il n'y avait rien à en tirer ». *Une année absente d'un fichier
> de sortie n'est pas une année non lue.*
>
> **Le vrai mur de la période récente est 1986-1989** : 37 actes, aucun texte en
> clair, aucun dépouillé. C'est aussi la fenêtre des 48 cantons créés entre 1986
> et 1999, nommés et non datés. La borne n'est pas l'annexe VII, c'est la mise
> en ligne de Légifrance — `texte_integral_sur_legifrance` bascule pile en 1990.

Répartition des 49 : 31 modifications de limites, 16 créations-modifications,
1 suppression, 1 rattachement.

---

### 3. Ce qui bloque encore : 124 décrets derrière le CAPTCHA

Pour les 124 décrets nouveaux antérieurs à 1990, Légifrance ne garde que le
titre. Il faut **58 numéros du JO** en version papier numérisée (≈ 30 Mo pièce),
un par date de publication — pas un par décret. Trois de ces 58 sont déjà dans
`jorf_txt/` (1970-01-21, 1982-01-28, 1988-04-22).

Le détail date par date est en sortie de `build_moisson.py`. Les numéros les
plus rentables :

| JO | décrets | départements |
|---|---|---|
| 1985-02-01 | 11 | 06, 14, 27, 34, 51, 56, 66, 70, 78, 84, 95 |
| 1985-01-30 | 7 | 04, 17, 19, 36, 44, 971, 973 |
| 1985-01-23 | 7 | 10, 11, 15, 29, 69, 77, 80 |
| 1982-01-28 | 7 | 14, 55, 64, 68, 76, 77, 86 — **déjà sur disque** |
| 1967-07-22 | 6 | 78, 91, 92, 93, 94, 95 — création des cantons de la petite couronne |
| 1982-02-04 | 5 | 13, 19, 2A, 63, 72 |
| 1985-01-24 | 5 | 03, 49, 58, 73, 91 |

Le JO du 22 juillet 1967 mérite d'être nommé : six décrets d'un coup, ceux qui
découpent en cantons les départements nés de l'éclatement de la Seine et de la
Seine-et-Oise. C'est un acte fondateur pour toute la couronne parisienne, et il
manquait.

---

### 3 bis. Quatre départements corrigés — le « NORD » qui n'en était pas un

*(ajouté après le dépouillement des JO, qui a servi de contrôle)*

Le département était déduit du titre par simple inclusion de chaîne. Or
Légifrance met la liste des cantons créés entre parenthèses à la fin du titre :

> `... DANS LE DEPARTEMENT DE L'OISE (BEAUVAIS-NORD-OUEST, BEAUVAIS-NORD-EST,
> COMPIEGNE-SUD-OUEST ...)`

Le mot **NORD** d'un nom de canton l'emportait sur le vrai département. Trois
décrets étaient donnés au Nord (59) sans y avoir la moindre part :

| décret | lu | est en réalité | ce qui trompait |
|---|---|---|---|
| 82-63 | 59 Nord | **60 Oise** | BEAUVAIS-NORD-OUEST |
| 82-64 | 59 Nord | **61 Orne** | ALENCON… (liste voisine) |
| 82-77 | 59 Nord | **01 Ain** | BOURG-NORD-CENTRE |

Un quatrième, **82-82**, ne porte aucun département : son titre dit « dans
divers départements ». L'ancien fichier lui donnait 54 par défaut ; il est
désormais vide, et signalé.

La règle est maintenant : ne chercher le nom qu'entre le mot `DEPARTEMENT` et
la parenthèse ouvrante. Sur les 343 décrets, elle ne change que ces quatre-là ;
les 339 autres sont confirmés à l'identique.

**C'est la deuxième occurrence du même défaut**, après le décret 82-35 perdu
parce que « LIÉVIN » contient « VIN ». Une sous-chaîne qui existe ailleurs dans
la ligne. Et c'est le JO — l'acte lui-même, qui imprime « Décret n° 82-64 du
20 janvier 1982 *(Département de l'Orne)* » en en-tête — qui l'a dit.

---

### 4. Confrontation au registre `mouvements_cantonaux.csv`

*(chiffres mis à jour après la correction ci-dessus)*

Sur 192 couples (département, date) datés au registre, **164 ont un décret** à la
même date de signature. L'écart va dans les deux sens, et il est plus large que
ce que la note de 1973/1982/1984 laissait voir.

#### 93 décrets sans décision au registre (1945-1989)

L'annexe VII sous-compte massivement. Quelques blocs entiers lui échappent :
les six décrets du 20 juillet 1967 (petite couronne), les quatre du 18 août
1973, les treize signés en 1985 hors des dates qu'elle retient, et la
quasi-totalité de 1986-1989.

#### 19 couples du registre sans décret trouvé (≥ 1945)

| date | départements |
|---|---|
| 1949-09-05 | 46 |
| 1955-01-19 | 06 |
| 1956-08-04 | 37 |
| 1958-02-26 | 68 |
| 1962-01-10 / 1962-01-22 | 62 / 67 |
| 1964-01-10 / 1964-01-28 / 1964-07-29 | 69 / 49, 59, 83, 91, 95 / 77 |
| 1972-10-20 | 38 |
| 1973-08-18 | 2A, 2B |
| 1982-01-25 / 1982-02-02 | 54 / 2B |
| 1982-12-24 | 09 |

**Trois de ces écarts sont des artefacts de nomenclature, pas des lacunes.**

- Le 18 août 1973, le registre inscrit 2A et 2B ; le décret n° 73-825 dit
  « CORSE » et il est classé ici en `20`. La partition de la Corse est de 1976.
  Les deux sources disent la même chose dans deux nomenclatures.
- Le 25 janvier 1982, le registre inscrit 54 ; le décret n° 82-82 est celui
  « dans divers départements » et le JO montre qu'il crée bien les cantons de
  Jarville, Pompey, Saint-Max, Saint-Nicolas-de-Port et Tomblaine, tous en
  Meurthe-et-Moselle.

  > **Réglé sur pièce le 29 août 2026.** La dernière phrase de ce point disait
  > « il ne se laisse simplement pas ranger sous un département unique ». C'est
  > faux : **`82-82` est la Meurthe-et-Moselle SEULE**, et le JO l'imprime sous
  > le numéro du décret. **C'est le titre Légifrance qui est faux**, pas le
  > décret. Le registre avait raison d'inscrire 54.
  >
  > Le cas a néanmoins mis à nu une limite du modèle : `acte_cantonal.dep` est
  > une colonne unique sous clé primaire, donc un acte ne pouvait désigner qu'UN
  > département. D'où la table **`acte_departement`** (`72` § 3 bis), bâtie en
  > creux — seuls les cas irréguliers y figurent, avec leur fondement cité.

**Deux autres ont été résolus par le JO** et ne figurent plus au tableau : le
20 janvier 1982, l'Oise et l'Orne paraissaient sans décret parce que le nôtre
les avait données au Nord (cf. § 3 bis). C'est la correction, pas la source, qui
manquait.

Les treize restants sont ouverts. Deux lectures possibles, qu'il ne faut pas
trancher ici : soit le registre date par la prise d'effet et le décret par la
signature — auquel cas l'appariement à date exacte est trop strict — soit ces
décisions n'ont pas pris la forme d'un décret indexé au titre par Légifrance.
Avant 1970 le fonds JORF est visiblement clairsemé : dix-huit décrets seulement
pour 1958-1972, quand le registre en suppose davantage.

**Ce qui a été vérifié et écarté** : l'hypothèse que Légifrance ait simplement
oublié d'indexer des décrets présents au JO. Sur les 32 numéros de JO où la
numérotation cantonale est contiguë, 128 numéros voisins apparaissent dans le
texte sans figurer à l'index ; **un seul** parle de cantons, et c'est une coquille
d'OCR du sommaire (`76-73` pour `76-78`). L'index de Légifrance n'a pas de trou
de cette nature.

---

### 5. Limites de ce fichier

- **Le département est déduit du titre**, par appariement sur une table de
  100 noms. Il est vide pour 8 décrets dont le titre ne nomme aucun département
  (formules « modification des limites territoriales de communes et de
  cantons »). Il n'est pas contrôlé pour les autres : c'est une lecture de
  titre, pas une lecture d'acte.
- **L'objet est déduit du titre** lui aussi, en cinq classes (création,
  création-modification, modification, suppression, rattachement). Le n° 91-218,
  « suppression et modification », est classé en suppression seule.
- **Les dates de publication au JO manquent pour les décrets ≥ 1990** : la page
  de résultats ne les affiche pas dans le même bloc. Sans conséquence, puisque
  ces textes se lisent en ligne.
- Ce fichier **ne pose rien en base**. C'est une liste d'actes à dépouiller.

---

Source : Légifrance, fonds JORF, recherche par titre. Licence etalab-2.0.
Moissonné le 28 août 2026.

## Décrets cantonaux 1973 / 1982 / 1984 — index et accès aux délimitations

Fichier produit : `cantons/decrets_1973_1984.csv` (136 décrets, 8 dates).

### 1. Ce qui est acquis

136 décrets identifiés sur Légifrance, un par département. Colonnes : date de
signature, date de publication au JO, numéro de décret, code et nom du
département à l'époque, objet, cantons cités dans le titre (1982 seulement),
identifiant et URL Légifrance, identifiant du JO numérisé.

> **Deux mises à jour, portées le 2 septembre 2026.**
>
> * **Le corpus n'est plus de 136 mais de 343 actes.** Le moissonnage par titre
>   du 28 août en a ajouté 207 d'un coup, couvrant 1958-1999. Le registre vit
>   désormais dans `cantons/decrets_cantonaux.csv` et en base par
>   `72_registre_actes.sql` ; ce fichier-ci reste l'index détaillé des trois
>   salves de 1973, 1982 et 1984.
> * **`82-82` n'est pas « divers départements ».** Lu au JO le 29 août : c'est
>   la **Meurthe-et-Moselle seule**, imprimée sous le numéro du décret. Le titre
>   Légifrance est faux, pas le décret.

| Date de signature | Décrets | Plage de numéros | JO de publication |
|---|---|---|---|
| 1973-07-13 | 28 | 73-651 → 73-678 | 17 juillet 1973, n° 164 |
| 1973-07-23 | 18 | 73-712 → 73-729 | 25 juillet 1973, n° 171 |
| 1973-08-02 | 14 | 73-761 → 73-774 | 4 août 1973, n° 180 |
| 1973-08-16 | 12 | 73-810 → 73-821 | 17 août 1973, n° 190 |
| 1982-01-15 | 17 | 82-22 → 82-38 | 16 janvier 1982, n° 13 (NC) |
| 1982-01-20 | 16 | 82-51 → 82-66 | 22 janvier 1982, n° 18 |
| 1982-01-25 | 10 | 82-77 → 82-86 | 26 janvier 1982, n° 21 |
| 1984-12-24 | 21 | 84-1222 → 84-1242 | 30 décembre 1984, n° 305 (NA) |

**Contrôle de complétude** : sur chacune des 8 dates la numérotation est
strictement contiguë, sans trou. L'énumération est donc exhaustive : aucun
décret de la série n'a été manqué.

### 2. Ce qui bloque pour les délimitations

Pour les textes antérieurs à 1990, **Légifrance ne conserve que le titre**. La
page d'un décret de 1973 ne contient aucun article : le corps du texte
(« Art. 1er — Le canton de X est composé des communes de… ») n'existe que dans
le **JO papier numérisé**.

Ces PDF (≈ 28 Mo par numéro) sont derrière un **CAPTCHA de téléchargement**
(`download-link-secure` → `captchaLink` dans `legifrance.js`). Je ne peux pas le
franchir. Le téléchargement manuel se fait depuis la page du décret, bouton
« Télécharger le Journal officiel… (version papier numérisée) ». Il n'y a que
**8 PDF à récupérer** — un par date, pas un par décret : tous les décrets d'une
même date sont dans le même numéro du JO.

Une fois les 8 PDF dans `sources/modif_canton/`, l'OCR et le découpage par décret sont
automatisables.

### 3. Sources de repli pour les délimitations

- **Titres de 1982** : les décrets de janvier 1982 nomment les cantons créés
  dans leur intitulé — repris dans la colonne `cantons_cites_dans_le_titre`.
  Ceux de 1973 et 1984 ne le font pas.
- **COG INSEE** : le diff commune → canton entre COG 1972/1975 et COG 1982/1985
  reconstitue la composition exacte des cantons créés. Machine-lisible et
  exhaustif, mais ce n'est pas la source juridique — à traiter comme un contrôle,
  pas comme un acte (cf. `METHODE.md`, cohérence ≠ exactitude).

### 4. Écarts relevés avec `mouvements_cantonaux.csv`

Tous les départements présents dans le registre à ces dates ont bien un décret
correspondant. **L'inverse n'est pas vrai** : 15 décrets visent des départements
pour lesquels le registre n'enregistre aucune décision à cette date.

| Date | Départements à décret sans décision au registre |
|---|---|
| 1973-07-23 | 03 Allier, 35 Ille-et-Vilaine |
| 1973-08-02 | 38 Isère, 43 Haute-Loire, 84 Vaucluse, 85 Vendée |
| 1973-08-16 | 01 Ain |
| 1982-01-15 | 17 Charente-Maritime, 78 Yvelines |
| 1982-01-20 | 2B Haute-Corse, 49 Maine-et-Loire |
| 1982-01-25 | 35 Ille-et-Vilaine |
| 1984-12-24 | 09 Ariège, 28 Eure-et-Loir, 32 Gers |

À vérifier : soit ces mouvements sont datés autrement dans le registre, soit ce
sont des lacunes de l'annexe VII. Dans les deux cas c'est notable.

---

Source : Légifrance, fonds JORF, recherche par date de signature.
Licence etalab-2.0.

## Communes coupées entre plusieurs cantons — décrets de 1973, 1982 et 1984

Extraction du texte intégral des 136 décrets, à partir des JO numérisés déposés
dans `sources/modif_canton/`. Les PDF portent une couche OCR exploitable.

### Fichiers

| Fichier | Contenu |
|---|---|
| `cantons/communes_coupees_1973_1984.csv` | 579 lignes = un couple (canton × commune coupée), avec le **texte intégral du segment** |
| `cantons/communes_coupees_synthese.csv` | 171 communes, triées par nombre de cantons |
| `cantons/extraire_communes_coupees.py` | le script, rejouable |

### Résultat

**171 communes coupées, réparties sur 117 des 136 décrets.** Les 19 décrets
restants ne redécoupent que des communes entières.

- 529 repérages **explicites** (le texte nomme la commune fractionnée) ;
- 50 **déduits du nom du canton** (canton entièrement intra-urbain, délimité par
  des voies sans que la commune soit renommée — colonne `reperage`) ;
- 494 segments sur 579 contiennent la **description littérale de la limite**
  (axe de voies, rivière, voie ferrée). Les 85 autres renvoient au canton voisin
  (« la portion non incluse dans le canton défini ci-dessus »), donc la limite se
  reconstitue par complément.

#### Distribution

| Cantons par commune | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10+ |
|---|---|---|---|---|---|---|---|---|---|---|
| Communes | 32 | 71 | 21 | 12 | 13 | 3 | 5 | 4 | 4 | 6 |

68 communes sont coupées en trois cantons ou plus.

#### Les plus morcelées

Marseille 20 · Limoges 18 · Toulouse 15 · Nice 13 · Rennes 12 · Nantes 10 ·
Saint-Étienne, Orléans, Reims, Perpignan 9 · Bordeaux, Tours, Laval, Toulon 8 ·
Troyes, Aurillac, Dijon, Montpellier, Amiens 7.

#### Par date

| Date | Lignes | Décrets | Communes coupées |
|---|---|---|---|
| 1973-07-13 | 129 | 24 | 44 |
| 1973-07-23 | 108 | 17 | 32 |
| 1973-08-02 | 66 | 13 | 23 |
| 1973-08-16 | 91 | 12 | 18 |
| 1982-01-15 | 40 | 14 | 17 |
| 1982-01-20 | 55 | 14 | 23 |
| 1982-01-25 | 36 | 8 | 10 |
| 1984-12-24 | 54 | 15 | 33 |

### Méthode, et pourquoi elle a changé en cours de route

Première tentative : découper le JO par décret, puis chercher les communes dans
chaque bloc. **Échec silencieux.** L'OCR d'une page à deux colonnes lit parfois
le titre imprimé en haut de la colonne 2 avant le corps de la colonne 1 ; deux
décrets voisins se retrouvent permutés. Le contrôle croisé contre le COG 1999 a
révélé le défaut : Angoulême rangé en Charente-Maritime, Lorient et Vannes en
Maine-et-Loire, Bordeaux en Dordogne, Blois dans les Landes. Sans ce contrôle,
21 lignes fausses passaient inaperçues.

Méthode retenue : **ne pas découper par décret du tout.** On découpe par segment
« Canton de X, comprenant… », qui est auto-suffisant, et c'est le COG qui
identifie la commune — donc son département, donc le décret, par le couple
(date de signature, département). L'identité de la commune n'est plus déduite
d'une position dans la page mais d'une correspondance avec le référentiel.

Deux corrections ont suivi, elles aussi révélées par le contrôle :

1. **Mots coupés par l'OCR** (« terri toire », « com munes », « déli mitée ») :
   l'amorce ne matchait pas et le segment continuait jusqu'au décret suivant,
   ramenant des communes étrangères. Recollage sur un vocabulaire fermé.
2. **Homonymies** : `Saint-Quentin` et `Laval` existaient aussi comme noms
   anciens dans Corhistoriq (37 et 51). Les communes du COG 1999 priment
   désormais sur les noms historiques. Zéro homonymie non résolue à l'arrivée.

### Contrôles passés

- **Zéro** commune non résolue contre le COG : par construction, une ligne n'est
  écrite que si le nom correspond à une commune réelle du département.
- **Zéro** homonymie ambiguë subsistante.
- 26 lignes sur 579 où le canton ne porte pas le nom de la commune coupée :
  vérifiées une à une, toutes légitimes — Charleville-Mézières partagée entre les
  cantons `Charleville-*` et `Mézières-*`, Chartres entamée par le canton de
  Mainvilliers, La Seyne-sur-Mer par celui de Saint-Mandrier, Le Creusot par
  `Creusot-Est` et `Creusot-Ouest`.

### Limites

- Le repérage « déduit du nom du canton » (50 lignes) est une **inférence**, pas
  une lecture : le décret délimite un canton par des voies sans nommer la
  commune, et le nom de la commune est tiré du nom du canton. À traiter comme
  vraisemblable, pas comme attesté.
- Les 19 décrets sans commune coupée n'ont pas été vérifiés un à un : l'absence
  peut venir d'une formulation non prévue plutôt que d'une absence réelle.
- Le référentiel est le COG **1999**. Une commune de 1973 fusionnée avant 1999 et
  absente de Corhistoriq ne peut pas être résolue, donc pas écrite. C'est un
  silence possible, jamais une erreur.
- La colonne `texte` est tronquée à 2 000 caractères. Les délimitations les plus
  longues (Marseille, Limoges) sont coupées ; le texte complet reste dans
  `jorf_txt/*_raw.txt`.

---

Sources : Journal officiel Lois et décrets, numéros 164 (17 juillet 1973),
171 (25 juillet 1973), 180 (4 août 1973), 190 (17 août 1973), 13 (16 janvier 1982),
18 (22 janvier 1982), 21 (26 janvier 1982) et 305 (30 décembre 1984).
Référentiel communal : COG INSEE 1999. Licence etalab-2.0.

## Dépouillement des JO numérisés — 1 212 cantons, 194 décrets

> **Chiffres à jour, 2 septembre 2026 : 4 739 lignes et 1 212 cantons.**
> Les 4 706 annoncés ici sont ceux du premier passage ; deux reprises ont suivi
> — la séparation des colonnes du JO, puis l'appariement par préfixe — et
> l'« État final » en fin de note porte les valeurs qui font foi.

Fichiers produits : `cantons/composition_jo.csv` (4 706 lignes), 
`cantons/composition_jo_non_appariees.csv` (151 rejets), 
`cantons/controle_composition_jo.csv` (le contrôle par le COG 1999).

Script : `cantons/composition_jo.py`. Contrôle : `cantons/controle_composition.py
--source cantons/composition_jo.csv`.

---

### 1. Le résultat

89 PDF de JO fournis, 86 convertis (trois étaient déjà sur disque), **30 numéros
exploités**.

| | |
|---|---|
| décrets dont on tire une composition | **194** sur 343 au registre |
| cantons distincts | **1 208** |
| lignes (décret × canton × commune) | 4 706 |
| communes distinctes rattachées | 3 461 |

Réparti par année de signature : 1961 (1), 1967 (732), 1970 (30), 1973 (1 951),
1974 (35), 1975 (101), 1976 (56), 1982 (1 035), 1984 (311), 1985 (449), 1988 (5).

Qualité d'appariement des noms : 80,5 % exacts, 2,3 % par `insee_mvt`
(communes disparues), 2,4 % par ressemblance, 9,7 % de cantons faits de
fractions seules, 3,3 % non appariés.

Sur les 58 numéros demandés, 44 sont arrivés ; les 14 manquants (404) portent
26 décrets, surtout 1988-1989.

---

### 2. Pourquoi un second extracteur

`composition_decrets.py` lit la colonne `texte` de
`communes_coupees_1973_1984.csv` — c'est-à-dire les seuls segments qu'un premier
passage avait retenus **parce qu'ils portaient une commune coupée**. Bon chemin
pour chercher les villes partagées ; mauvais pour chercher la composition, parce
qu'un canton sans commune coupée — la grande majorité — n'entre jamais dans le
fichier.

`composition_jo.py` repart du texte du JO et prend tous les segments
« Canton de X comprenant les communes de A, B et C ». D'où 4 706 lignes contre
1 295.

**On lit `*_raw.txt`, pas `*.txt`.** `pdftotext -layout` entrelace les deux
colonnes du JO sur la même ligne et fabrique des listes de communes qui n'ont
jamais existé. Sans `-layout`, l'ordre de lecture des colonnes est respecté.

**Les PDF portaient déjà une couche texte.** Aucun OCR n'a été nécessaire, et
la qualité est très au-dessus de celle des fascicules du COG 1968.

---

### 3. Le contrôle indépendant — COG 1999

Même juge que pour 1973/1982/1984, sur un corpus 2,5 fois plus gros.

| verdict | cantons |
|---|---|
| accord (≥ 80 % des communes dans le même canton en 1999) | **415** |
| accord partiel (50-80 %) | 99 |
| désaccord (< 50 %) | **5** |
| aucune commune retrouvée en 1999 | 8 |
| trop court (< 3 communes, non jugeable) | 282 |

**Sur les 519 cantons jugeables : 3 344 communes sur 3 635 retrouvées dans le
même canton en 1999 — 92,0 %.** L'étalon précédent était de 155 accords,
24 partiels, 0 désaccord.

#### Les 5 désaccords, tous du même genre

Échirolles (38, 1973), Trappes (78, 1967), Valdoie (90, 1967), Évry (91, 1967),
Montgeron (91, 1967). Ce sont les banlieues qui ont le plus grossi entre le
décret et 1999, et qui ont donc été **redécoupées entre-temps**. C'est
exactement ce que la mise en garde du contrôle prévoit : un désaccord n'accuse
pas l'extraction, il peut venir du monde.

#### Les 8 « aucune commune retrouvée » sont plus instructifs

- **5 relèvent du décret 82-82** (Jarville, Pompey, Saint-Max,
  Saint-Nicolas-de-Port, Tomblaine). Son département est vide, puisque son titre
  dit « divers départements » ; le contrôle cherche dans un département et ne
  trouve rien. Les cinq cantons sont en Meurthe-et-Moselle, autour de Nancy.
  Le verdict est un artefact de notre prudence, pas une erreur de lecture.
- **2 relèvent de la Corse** (73-825, Figari et Tallano-Scopamène). Le décret
  dit « CORSE », classé `20` ; le COG 1999 dit 2A. Même artefact de nomenclature
  que celui déjà signalé au registre.
- **1 est une vraie erreur d'attribution** : « Évreux-Ouest » est rangé sous le
  décret 82-55 (Doubs) alors qu'Évreux est dans l'Eure. Voir § 4.

---

### 4. Contrôle croisé des deux extractions

Là où les deux chaînes traitent le même canton, elles peuvent être comparées.
Elles n'ont ni le même point d'entrée ni le même découpage.

| | cantons |
|---|---|
| présents dans les deux | 283 |
| listes de communes **identiques** | **277** |
| ancienne strictement incluse dans la nouvelle | 6 |
| **divergentes** | **0** |
| seulement dans l'ancienne | 2 |
| seulement dans la nouvelle | 526 |

**Zéro divergence sur 283 cantons.** Les six où l'ancienne est incluse sont des
listes que le nouvel extracteur lit plus complètement.

Les deux cantons que seule l'ancienne connaît méritent d'être nommés, parce
qu'ils disent où la nouvelle est faible : Poitiers-III (73-677, une commune) et
**Évreux-Ouest (82-56)**. Sur ce dernier, c'est l'ancienne chaîne qui a raison.

---

### 5. Comment un décret est attribué à un canton, et ce que ça a coûté

Le JO ne dit pas, à chaque canton, de quel décret il relève. Il faut le déduire.

**La première version votait sur les communes reconnues.** Sur le JO du
22 juillet 1967 elle a donné **568 lignes sur 651 au seul décret des Yvelines**,
et **zéro à celui de l'Essonne**. La raison n'est pas une faute de lecture : en
juillet 1967 l'Essonne n'existe pas — elle naît le 1er janvier 1968 — et ses
communes portent encore des codes `78`. Le vote mesurait la nomenclature, pas le
décret.

**La version retenue s'appuie sur l'ancre** : le JO imprime le numéro du décret
en tête de chacun — « Essonne (décret n° 67-589 du 20 juillet 1967) ». On ne
cherche que les numéros attendus dans ce numéro-là, ce qui écarte d'office les
« Vu le décret n° 66-352 » des visas. Passage de 4 décrets à 6 sur ce JO, et de
64,3 % à 82,4 % d'appariements exacts.

**Mais l'ancre seule ne suffit pas.** Quand l'OCR abîme un numéro, l'ancre
manque et les cantons de ce décret se collent au décret précédent — sans bruit,
et par blocs entiers. Le vote sert donc de contradicteur : si les communes d'un
segment désignent massivement un autre département qui légifère dans le même
numéro, c'est l'ancre qui a tort. Gain : 158 → 191 décrets, et 64,3 % → 80,0 %.

Répartition finale : 3 656 lignes par l'ancre, 869 par le vote contredisant
l'ancre, 49 par le vote seul. La colonne `attribution` le dit ligne à ligne.

**Ce qui reste** : « Évreux-Ouest » (§ 3), où l'ancre de 82-56 a été perdue et où
le segment — une description de limites par des rues — ne cite pas assez de
communes pour que le vote se déclenche. Une sur 809.

---

### 6. Un mot manquait au vocabulaire

Dix-sept décrets restaient muets alors que leur JO était sur disque. Quatre
tenaient à un seul mot : les décrets de 1975 écrivent

> « Le canton de X **comprend** les communes de… »

quand ceux de 1973 écrivent « comprenant ». L'indicatif n'était pas dans
l'expression. Ajouté (`comprend`, `comprennent`), il rend 2 décrets et
112 lignes de plus.

Les treize autres muets restent à voir. Vingt-neuf décrets supplémentaires sont
muets **et doivent l'être** : ce sont des « modifications de limites
cantonales », qui décrivent des tracés de rues et ne contiennent aucune liste de
communes.

---

### 7. Ce que ce fichier n'est pas

- Il **ne pose rien en base**.
- Il ne donne la composition que des cantons **que le décret touche**, jamais
  celle des autres. C'est un delta, pas un état.
- **80,5 % de noms appariés n'est pas 80,5 % d'exactitude.** Un nom parfaitement
  apparié rangé sous le mauvais canton reste une erreur, et l'appariement ne
  peut pas la voir. C'est le contrôle du § 3 qui parle, pas ce taux-là.
- Le taux d'accord de 92 % est un **plancher** : entre le décret et 1999, une
  commune a pu changer de canton légitimement.

---

Sources : Journaux officiels numérisés (Légifrance, licence etalab-2.0),
COG INSEE 1999, GEOFLA, `insee_mvt`. Dépouillé le 28 août 2026.

---

## Reprise du 28 août 2026 — les colonnes, et quatre défauts d'appariement

Ancienne version conservée : `archives/composition_jo_2026-08-28_lecture_entrelacee.csv`.

### Le résultat

| | avant | après | |
|---|---|---|---|
| lignes | 4 706 | **4 737** | +31 |
| cantons | 1 208 | **1 212** | +4 |
| communes distinctes rattachées | 3 461 | **3 562** | +101 |
| appariements `exact` | 3 788 | **3 853** | +65 |
| **`aucun`** | 154 | **72** | **−82** |
| par `prefixe` (nouveau) | 0 | 70 | |
| `prefixe ambigu` (nouveau, déclaré) | 0 | 18 | |
| attribués par l'**ancre** | 3 716 | **4 013** | +297 |

Les deux contrôles indépendants :

| | cantons au titre | égarés | COG 1999 |
|---|---|---|---|
| avant | 120 / 184 — 65,2 % | **2** | 419 accords, 92,0 % |
| après | 122 / 184 — **66,3 %** | **0** | **420 accords**, 92,0 % |

Aucune régression, et les cantons égarés disparaissent.

### 1. La source : le JO est sur deux colonnes

Le script lisait `*_raw.txt` en croyant qu'il suivait l'ordre des colonnes.
C'était faux : `_raw` découpe les lignes fondues par `-layout`, il ne sépare
pas les colonnes. Le contenu d'un décret y paraît AVANT son propre en-tête —
sur `JORF_19820122_18`, le 82-56 a son texte aux lignes 412-431 et son titre à
la 470. D'où « Evreux-Ouest » sous le décret du Doubs et « Lorient-Centre »
sous celui du Cantal.

`cantons/jorf_colonnes.py` produit `*_col.txt`. **Deux méthodes ont été
essayées, et la première est instructive.**

`boite` rappelle `pdftotext` avec une boîte de découpe par colonne. L'ordre est
rétabli — mais le texte est abîmé : le clipping REND À NOUVEAU la page, et tout
ce qui touche la coupure disparaît. L'extraction tombait de 4 706 à **4 414**
lignes et les appariements par ressemblance doublaient.

*Une réparation qui repasse par la source rend une source différente.*

`gouttiere`, retenue, ne redemande rien : elle coupe le texte `-layout` déjà
rendu au blanc vertical qui sépare les colonnes, ligne par ligne. Mêmes octets,
autre ordre. Trois raffinements ont été nécessaires, chacun mesuré :

* couper au blanc **propre à chaque ligne**, dans un voisinage de la
  gouttière — une coupure au même caractère pour toutes tranche dans les mots
  des 15 % de lignes qui débordent ;
* ne pas couper les lignes **pleine largeur** (bandeaux, titres) : coupées en
  deux elles donnent deux moitiés fausses ;
* **désindenter les deux moitiés**, faute de quoi la moitié droite hérite de
  toute la largeur de la gouttière et `nettoie()` ne recolle plus les mots
  coupés en fin de ligne ;
* quand aucune gouttière n'est trouvée, **replier sur la lecture sans
  `-layout`** — pas sur le `-layout` entrelacé, qui est justement ce qu'on
  fuit. *Un repli doit être le moins mauvais des états connus, pas le premier
  sous la main.*

### 2. Le préfixe avant la ressemblance

Le décret écrit « Colleville » là où le référentiel écrit
« Colleville-Montgomery ». La ressemblance orthographique départage ces cas
**à l'envers** : « Colleville » ressemble davantage à « Cléville » (0,89) qu'à
« Colleville-Montgomery » (0,71). C'est ainsi que le canton d'Ouistreham-Riva-
Bella s'était vu attribuer une commune de Troarn.

On essaie donc le préfixe au trait d'union **avant** la ressemblance, dans les
deux sens — le décret abrège (« Colleville ») autant qu'il allonge
(« Ouistreham-Riva-Bella » pour la commune d'Ouistreham, désormais retrouvée).
70 lignes y gagnent un code.

Quand le préfixe désigne **plusieurs** communes — « Colleville » en désigne
deux dans le Calvados, Montgomery et sur-Mer — on ne choisit pas : la ligne
sort en `prefixe ambigu`, sans code, avec ses candidats au fichier des rejets.
18 lignes. *La source ne tranche pas, nous non plus.*

### 3. Un code pris par une pièce ne se partage pas

Passe de rattrapage : quand un acte attribue un même code INSEE à deux cantons
et qu'une seule des lectures est une pièce (`exact`, `disparue`, `prefixe`),
les autres sont refaites en s'interdisant ce code. **Une conjecture ne prend
pas la place d'une pièce.** Deux `exact` sur un même code ne sont pas tranchés
— ce serait une contradiction réelle de la source, et elle doit remonter.

### 4. Trois couperets muets

* **Le plafond de 400 caractères** sur une liste de communes. Le canton de
  Bonnières-sur-Seine produit **401** caractères et disparaissait — sans
  sortie et sans rejet. Porté à 1 200, et le dépassement est désormais
  signalé. *Un plafond qui décide de l'existence d'un canton ne doit ni être
  serré ni être muet.*
* **La césure de fin de ligne** ne se recollait que devant une minuscule.
  « Jouy-\nMauvoisin » restait coupé. On distingue désormais les deux cas : on
  soude sans trait d'union devant une minuscule (césure), on garde le trait
  d'union devant une majuscule (nom composé).
* **La formule « où est fixé son chef-lieu »** n'était pas une borne de liste :
  31 lignes portaient « Fontenay-sous-Bois où est fixé son chef-lieu » comme
  nom de commune et ne s'appariaient à rien. Le canton existait dans le
  fichier avec une commune fantôme.

### 5. Le vote lisait des noms de rues

Un canton urbain est décrit par des RUES. « rue Saint-Laurent », « rue
Colbert », « place Sadi-Carnot » existent aussi comme communes ailleurs en
France, et elles votaient. Le canton de **Marseille-I**, dont l'ancre — le
décret n° 73-812, Bouches-du-Rhône — était juste et à trente lignes de là,
s'est retrouvé en **Haute-Savoie**.

Deux corrections ont été essayées et mesurées avant de retenir la troisième :

1. *voter sur les seules communes lues* → Marseille rentre, mais le contrôle
   par les titres perd ce qu'il avait gagné (égarés 0 → 2). Le vote sur le
   segment travaille vraiment, ailleurs.
2. *refuser toute voix aux cantons sans communes entières* → Marseille rentre,
   Lorient-Centre repart dans le Cantal. Les deux cas s'opposent : à Marseille
   l'ancre a raison, à Lorient c'est le vote.
3. **retenue** — un canton sans communes entières vote avec les deux seuls
   noms de communes que le décret lui donne : **son chef-lieu**, toujours
   nommé, et sa propre tête de nom (« Marseille-I » → Marseille).

*On ne réduit pas le nombre de preuves, on écarte celles qui n'en sont pas.*

### Ce qu'il faut rejouer

`sql/72_registre_actes.sql` recharge `acte_composition` depuis ce fichier —
l'ordre des colonnes est inchangé, le `\copy` passe tel quel. Puis `73`, `74`,
`75`, qui en dépendent.

---

### Correctif du soir — la troncature passe APRÈS la ressemblance

Le premier passage en base a fait parler le § 5 bis de `75` : la commune
disputée avait changé. Ce n'était plus `9724` entre Ouistreham et Troarn, mais
`5861` entre **Cabourg et Ouistreham-Riva-Bella** — et cette collision-là était
de ma fabrication.

Le décret 82-92 donne « Breville » à Cabourg (Bréville, `14106`) et
« Bréville-Beuville » à Ouistreham — lecture OCR de **Biéville-Beuville**,
`14068`. La règle `prefixe lu`, placée avant la ressemblance, tronquait
« Bréville-Beuville » en « Bréville » et tombait sur la commune du canton
voisin. L'ancienne lecture, elle, faisait juste par ressemblance.

**La règle qui en sort : le nom entier porte plus d'information que sa
troncature.** Une ressemblance sur le nom COMPLET (Bréville-Beuville /
Biéville-Beuville, 0,94) doit l'emporter sur une correspondance exacte obtenue
en jetant la moitié du nom. Là où la ressemblance ne trouve rien —
« Ouistreham-Riva-Bella » ne ressemble à « Ouistreham » qu'à 0,69 — la
troncature reste seule, et elle a raison. `prefixe lu` passe donc après.

Et une scorie de numérisation : « Colleville,^ Saint-Aubin-d'Arquenay » faisait
perdre Saint-Aubin-d'Arquenay, le nom ne commençant plus par une majuscule. Les
caractères non alphabétiques sont désormais retirés en tête de nom.

#### État final

| | avant | après |
|---|---|---|
| lignes | 4 706 | **4 739** |
| cantons | 1 208 | **1 212** |
| communes distinctes | 3 461 | **3 565** |
| `exact` | 3 788 | **3 855** |
| `aucun` | 154 | **72** |
| codes réclamés par deux cantons d'un même acte | 1 | **0** |
| cantons au titre | 120/184 | **122/184** |
| égarés | 2 | **0** |
| COG 1999 | 419 accords, 92,0 % | **420**, 92,0 % |

Le canton d'Ouistreham-Riva-Bella, qui a servi de fil, est désormais lu
entier : Blainville, Biéville-Beuville, Bénouville, Ouistreham,
Périers-sur-le-Dan, Saint-Aubin-d'Arquenay — et « Colleville » déclaré
`prefixe ambigu`, parce que le Calvados en compte deux et que le décret ne
tranche pas.

## 1990-1999 sur Légifrance — 100 % d'accord avec le COG, et cinq transferts que l'annexe VII ignore

Fichiers produits : `cantons/composition_legifrance.csv` (252 lignes),
`cantons/transferts_legifrance.csv` (5 lignes),
`cantons/controle_composition_legifrance.csv`.

Entrée figée : `cantons/legifrance_1990_1999.txt`. Script :
`cantons/composition_legifrance.py`.

---

### 1. Ce que contiennent réellement les 83 décrets

Le moissonnage du matin annonçait « 83 décrets de 1990-1999 avec texte intégral,
c'est le lot suivant ». Le lot est plus petit qu'il n'y paraissait, et
différemment composé.

| | décrets |
|---|---|
| donnent une **composition cantonale** | **19** |
| déplacent **une commune entière** d'un canton à un autre | **4** |
| transfèrent des **parcelles entre deux communes** | 40 |
| autres | 10 |
| **sans aucun texte** sur Légifrance — titre seul | **10** |

Les 40 sont le gros du lot et ce sont des **non-événements pour la couche
cantonale**. Type :

> « Les parties de territoire de la commune de Sévérac-le-Château *(canton de
> Sévérac-le-Château)* … sont rattachées à la commune de Rivière-sur-Tarn
> *(canton de Peyreleau)*. »

L'opération traverse une limite cantonale — d'où le mot « canton » dans le titre,
d'où leur présence dans le moissonnage — mais **aucune commune ne change de
canton**. Cela concerne la géométrie communale, pas l'appartenance cantonale.

C'est une correction utile au plan : le nombre de décrets moissonnés ne mesure
pas la quantité de mouvement cantonal. Sur 1990-1999, 83 décrets ne portent que
19 compositions et 4 mouvements.

---

### 2. Le résultat, et un contrôle sans précédent dans le dépôt

252 lignes, **20 décrets, 71 cantons**, sur 1991, 1993 et 1997.

Appariement des noms : **93,3 % exacts**, 0,4 % par `insee_mvt`, 0,4 % par
ressemblance, 5,6 % de cantons faits de fractions seules — et **zéro rejet**.

#### Contrôle indépendant par le COG 1999

| verdict | cantons |
|---|---|
| accord | **34** |
| accord partiel | 0 |
| désaccord | **0** |
| trop court (< 3 communes, non jugeable) | 23 |

**208 communes sur 208 dans le même canton en 1999 — 100,0 %.**

À comparer aux 92,0 % du corpus tiré des JO numérisés, et aux 94,6 % de la
première extraction. C'est le seul lot du dépôt qui n'a **jamais rencontré
d'OCR** : le texte est natif. Deux causes se distinguent enfin :

- la proximité des dates (1991-1997 contre 1999) réduit le changement réel ;
- l'absence d'OCR supprime la perte de lecture.

On ne peut pas les séparer avec ce seul chiffre. Mais un lot sans OCR qui rend
100 % pose une borne : sur le corpus OCRisé, l'écart aux 92 % n'est pas
principalement une faute de méthode.

---

### 3. Les cinq transferts, et pourquoi ils comptent

Quatre décrets déplacent une commune entière d'un canton à un autre — cinq
communes en tout.

| date | dép. | commune | canton d'origine | canton d'arrivée |
|---|---|---|---|---|
| 1993-01-25 | 11 | Laprade | Mas-Cabardès | Saissac |
| 1993-01-27 | 38 | Vasselin | La Tour-du-Pin | Morestel |
| 1995-04-10 | 28 | Saint-Denis-des-Puits | La Loupe | Courville-sur-Eure |
| 1995-04-10 | 28 | Villebon | La Loupe | Courville-sur-Eure |
| 1997-02-26 | 38 | Saint-Alban-de-Roche | L'Isle-d'Abeau | Bourgoin-Jallieu - Sud |

Ce sont exactement les **« transferts isolés de commune »** dont
`mouvements_cantonaux.csv` porte, dès sa première ligne, la remarque :
*« l'annexe VII ne recense jamais ce type de mouvement »*. Le dépôt en compte
274 non datés. En voici cinq, **datés au jour près**, avec canton d'origine et
canton d'arrivée nommés.

**Contrôle** : les cinq communes sont, dans le COG 1999, dans le canton nommé
comme destination. Cinq sur cinq. (Pour Saint-Alban-de-Roche, le canton 38-04
rassemble Badinières, Domarin, Maubec, Nivolas-Vermelle, Sérézin-de-la-Tour… —
c'est bien la couronne sud de Bourgoin-Jallieu ; la ville elle-même relève d'un
autre canton, ce qui est le cas ordinaire d'un chef-lieu partagé.)

---

### 4. Ce qui manque encore, et ce que ça coûte

**10 décrets n'ont aucun texte sur Légifrance**, titre seul et bouton PDF. Tous
sont des décrets **non numérotés**, tous étiquetés « modification de limites
cantonales », et ils se rangent en deux blocs nets : avril-octobre 1990 (4) et
l'année 1992 entière (6).

La pleine année 1992 sans un seul texte n'est pas une coïncidence de tirage.
C'est une lacune du fonds, pas de notre lecture.

**Ce qu'elle coûte, probablement peu** : sur les 73 décrets dont on a le texte,
40 des 56 « modifications de limites cantonales » se sont révélées être des
transferts de parcelles entre communes, sans conséquence cantonale. Rien ne dit
que les 10 manquants soient d'une autre nature — mais rien ne le prouve non
plus, et c'est une inférence, pas un fait. Les récupérer demande 10 PDF de JO.

---

### 5. Comment le texte a été obtenu

Les pages `/jorf/id/…` sont rendues côté client : un `fetch` sans session ne
rend qu'une coquille, et `WebFetch` ne voit rien. Une fois la session établie
dans le navigateur, en revanche, `fetch` rend le document complet — vérifié en
comparant, sur le décret 91-217, les 14 articles et 7 977 caractères obtenus par
`fetch` à ceux de la page affichée : identiques.

L'extraction se fait donc dans le navigateur et son résultat est déposé dans
`cantons/legifrance_1990_1999.txt`, qui est la trace reproductible. Le script ne
refait que l'appariement des noms — la partie qu'on veut pouvoir rejouer et
discuter. Les expressions de segmentation sont celles de `composition_jo.py`,
portées telles quelles.

---

Source : Légifrance, fonds JORF, texte intégral. Licence etalab-2.0.
Contrôle : COG INSEE 1999. Dépouillé le 28 août 2026.

## Les tables analytiques du JO, 1941-1990 — 11 octobre 2026

### Ce qu'on a

- `sources/JORF/tables/TABLE_ANALYTIQUE_JORF_1941…1990.pdf` : les 50 tables annuelles (4,4 Go),
  téléchargées depuis Légifrance (`/download/file/<id>/TB`).
- `jorf_txt/TABLE_ANALYTIQUE_JORF_AAAA_col.txt` : leur texte, colonnes séparées.

### Ce qu'on en tire

| fichier | quoi |
|---|---|
| `cantons/tables_jo.py` → `tables_jo_actes.csv` | tout ce que les tables disent des cantons : 567 lignes (275 rattachements de communes, 213 créations, 36 changements de nom…) |
| `cantons/tables_jo.py --rappel` → `rappel_tables.csv` | contrôle : les actes connus par ailleurs (registre Légifrance + complément) que les tables retrouvent |
| `cantons/dater_par_tables.py` → `dates_par_tables_jo.csv` | les mouvements non datés de `mouvements_cantonaux.csv` cherchés dans les tables |
| `cantons/transferts_tables.py` → `transferts_tables_jo.csv`, `jo_page_date.csv` | les transferts datés, au format de `transferts_complement.csv`, avec la date de parution estimée par la page |

### Ce que valent les tables

Actes connus 1941-1990 retrouvés dans les tables : **263 sur 318**.

- créations et recompositions de cantons : **228 sur 233** ;
- les manquants sont surtout des « modifications de limites cantonales » de 1986-1990
  (55, dont 20 retrouvés) : ce sont des parties de territoire passées d'une commune à
  l'autre, que les tables classent sous « Circonscriptions administratives territoriales »,
  pas sous « Cantons ». Sans effet sur les communes entières.

Formes lues : articles « X au canton de Y (Dép.), p. N » ; listes « Création et modification
de cantons dans les départements suivants : Ain. — D. 82-77 du 25 janv. 1982, p. 371 » ;
rubriques « Cantons. — Essonne. Création et délimitation. — D. 67-589 » ; noms de
départements mal lus par l'OCR (« Sai'the », « Saône-et-Loife ») rapprochés à 82 %.

Limite : de 1941 à 1957 environ, la mise en colonnes mélange encore des lignes de deux
colonnes ; le département manque à 150 lignes. La recherche par commune
(`dater_par_tables.py`) ne s'en soucie pas : elle cherche dans le texte entier, nom approché.

### Les transferts isolés datés

Sur 274 transferts isolés sans date, **97** se retrouvent dans une table, chacun dans une
seule année ; contrôles justes (Saint-Couat 1951, Chambéon 1955, La Chapelle-Bertin 1962,
Salles-Mongiscard 1951, Crézières 1955, Belmont 1955). Après retrait des doublons et de ceux
déjà lus au JO : **93** dans `transferts_tables_jo.csv`, dont 53 avec la date du décret.

Date de parution (règle C : effet le lendemain) : estimée par la page. Pour une page, le
plus récent acte signé aux pages qui la précèdent, plus un jour. Contrôlé sur 236 actes
dont on connaît la date de parution : écart médian 1 jour, 229 à 7 jours au plus ; les
7 autres sont des numéros de page mal lus dans le contrôle, pas des erreurs de l'estimateur.

### Pose

`sql/110_pose_lecture_jo.sql` lit aussi `transferts_tables_jo.csv`, sous la
nature `transfert_table`. Même règle que les transferts lus au JO, une
différence : la table ne nomme pas le canton de départ ; la moitié gauche du
trou est posée au canton du bord gauche (fondement écrit dans `p110_qualite`).
Posé le 11 octobre 2026 : **142 périodes sur 73 communes** ; 20 tombent sur une
période déjà posée, et 110 s'en abstient.

`sql/111_corrige_transferts.sql` instruit ces 20 (et les 2 des transferts lus
au JO) : 13 communes gardées par la base dans leur canton de départ après
l'acte, 5 mises dans leur canton d'arrivée avant lui, 2 laissées (Orgerus,
Ferreux). Posé puis défait le 11 octobre pour éprouver le retour arrière ; à
rejouer avec `-v poser=on`.

Les deux sont dans `sql/rejouer_apres_rebuild.sh`, en dernier ; l'ordre de
rejeu est dans `sql/README.md`, « Qui dépend de qui », § 3.

### Ce qui reste

- 177 transferts isolés que les tables ne montrent pas (suivi : `RESTE_A_FAIRE.md` § 1 quater) : artefacts de la base, ou
  communes que l'OCR a trop abîmées. À trier.
- La preuve d'absence (« aucun acte dans ce département cette année-là ») : solide pour
  les créations et recompositions (98 %), moins pour les rattachements avant 1958.

## Ce qui peut entrer en base, et dans quel ordre

État au 28 août 2026, après le moissonnage Légifrance et le dépouillement des JO.
Matière disponible : `decrets_cantonaux.csv` (343 actes), `composition_jo.csv`
(4 706 lignes), `composition_legifrance.csv` (252), `transferts_legifrance.csv` (5).

> **Où en est ce plan, au 2 septembre 2026.** Cette note était un plan ; il a
> été exécuté en entier, et deux de ses hypothèses ont été renversées.
>
> * **Tout est posé** : `72` (registre), `73` (recette 1967), `74` (Yvelines),
>   `75` (salves 1973 et 1982), `76` (le reste), `77` (transferts), puis les deux
>   reports `79` et `81`. Voir `sql/CHAINE.md` § 1 c pour l'ordre réel.
> * **La convention de date d'effet est tranchée** — premier tour du
>   renouvellement des conseils généraux qui suit la signature — et elle est
>   inscrite ligne à ligne dans `p75_qualite` / `p76_qualite`, pas seulement
>   dans cette note.
> * **« Il ne manque que la convention » pour les cinq transferts était faux.**
>   Il ne manquait rien : `Corhistoriq1999.txt`, modalité 43, en porte **66**
>   avec leur date d'effet et le canton d'arrivée codé — treize fois plus de
>   communes, et une date qui est un fait, pas une convention. La source était
>   sur le disque depuis le 9 août et le dépôt l'avait jugée « trop pauvre »
>   pour une autre question. *Une source se juge par question, pas en bloc.*
> * `composition_jo.csv` compte **4 739 lignes** et **1 212 cantons** depuis
>   la séparation des colonnes du JO et la reprise de l'appariement, et non
>   4 706 / 1 208.

Rappel du modèle : `membership(atom_id, unit_id, [valid_from, valid_to))` avec
`EXCLUDE USING gist`. Un atome n'appartient qu'à une unité par niveau à un
instant donné. Poser quelque chose, c'est donc toujours **poser des bornes**, et
c'est là que se joue la difficulté.

---

### Le chiffre d'ensemble

| | |
|---|---|
| actes datés, 1958-1999 | 343 |
| cantons dont on a la composition | **1 267** (866 couples décret × canton) |
| communes distinctes rattachées | **3 578** |
| lignes portant un code INSEE | 4 307 sur 4 958 — 86,9 % |
| dont rattachables à un canton du COG 1999 | 553 sur 866 — 64 % |

Les 313 sans lien 1999 ne sont pas perdus : ce sont surtout des cantons de moins
de trois communes (le seuil du contrôle) et des cantons disparus avant 1999.

---

### 1. Le registre des actes — à poser en premier, risque nul

Une table `acte_cantonal` : date de signature, date de publication, numéro,
département, objet, URL Légifrance, présence du texte.

Ce n'est pas du `membership` et cela ne fait répondre aucun `snapshot`. C'est la
**colonne vertébrale** de tout le reste : elle transforme « on ne sait pas s'il
s'est passé quelque chose » en « aucun acte n'est enregistré ici ». Le report
d'un état d'une date à l'autre — la méthode retenue pour combler 1943-1999 —
n'est licite que si la liste des actes de l'intervalle est complète. Sans cette
table, la condition n'est pas vérifiable ; avec elle, elle devient une requête.

**Fichier `72`.** Aucune contrainte de bornes, aucun risque.

---

### 2. Les cinq transferts de commune — exacts, vérifiés, immédiats

| date | dép. | commune | de | vers |
|---|---|---|---|---|
| 1993-01-25 | 11 | Laprade | Mas-Cabardès | Saissac |
| 1993-01-27 | 38 | Vasselin | La Tour-du-Pin | Morestel |
| 1995-04-10 | 28 | Saint-Denis-des-Puits | La Loupe | Courville-sur-Eure |
| 1995-04-10 | 28 | Villebon | La Loupe | Courville-sur-Eure |
| 1997-02-26 | 38 | Saint-Alban-de-Roche | L'Isle-d'Abeau | Bourgoin-Jallieu - Sud |

Cinq lignes, cinq communes, canton d'origine et d'arrivée nommés, **confirmées
cinq fois sur cinq par le COG 1999**. Ce sont exactement les mouvements dont
`mouvements_cantonaux.csv` dit que l'annexe VII ne les recense jamais — le dépôt
en compte 274 non datés.

Ce sont les seules lignes du lot dont la date, la commune, l'origine et la
destination soient toutes les quatre explicites dans le texte. **Fichier `73`.**

---

### 3. Le jalon de 1967 — posable, et il valide le jalon de 1968

Les six décrets du 20 juillet 1967 créent les cantons de l'Essonne, des
Hauts-de-Seine, de la Seine-Saint-Denis, du Val-de-Marne, du Val-d'Oise et des
Yvelines, avec effet à la naissance de ces départements le 1er janvier 1968.

**Confrontation au COG 1968** — deux sources qui ne partagent rien : un texte de
décret OCRisé du JO du 22 juillet 1967 d'un côté, les fascicules du recensement
de 1968 OCRisés séparément de l'autre.

| | cantons |
|---|---|
| accord (≥ 80 %) | **45** |
| accord partiel | 4 |
| **désaccord** | **0** |
| trop court (< 3 communes) | 27 |
| aucune commune lue en 1968 | 14 |

Zéro désaccord. Par département : 21/21 en Essonne, 15/16 en Val-d'Oise, 4/4 en
Moselle, 2/3 en Val-de-Marne, 2/3 dans le Territoire de Belfort.

**Ce que cela permet, et qui est nouveau** : le jalon `[1968-01-01, 1969-01-01)`
de ces départements peut être **borné en arrière par un acte**, et non par une
supposition. Le décret est la borne inférieure, et il est daté. **Fichier `74`.**

---

### 4. Les compositions comme jalons datés — le gros du lot, et le vrai problème

1 267 cantons répartis sur 37 dates de signature, de 1961 à 1997 :

| année | lignes | | année | lignes |
|---|---|---|---|---|
| 1967 | 732 | | 1984 | 311 |
| 1970 | 30 | | 1985 | 449 |
| 1973 | 1 951 | | 1988 | 5 |
| 1974-1976 | 192 | | 1991 | 188 |
| 1982 | 1 035 | | 1993-1997 | 64 |

> **TRANCHÉ LE 28 AOÛT 2026 — Adrien retient le scrutin suivant la signature.**
> La convention est implémentée par `sql/75_composition_1973_1982.sql` pour les
> deux grosses salves, avec l'incertitude de série inscrite ligne à ligne dans
> `p75_qualite`. Deux tables de référence en sortent, faites pour être
> réutilisées par `76` : `scrutin_cantonal` (les renouvellements de 1961 à
> 2001) et `acte_effet` (date d'effet et borne haute des 343 actes).
> Le détail est dans `sql/CHAINE.md`, section 75. La section ci-dessous est
> conservée telle qu'elle était écrite avant la décision : c'est l'exposé du
> problème, et il reste exact.

#### Le problème : `valid_from` n'est pas la date de signature

Les décrets de 1973, 1982 et 1985 **ne portent aucune clause d'effet**. Leur
article final dit seulement « … est chargé de l'exécution du présent décret, qui
sera publié au Journal officiel de la République française ». Rien d'autre.
Vérifié sur les 233 segments de décret cantonal des JO : sept seulement portent
une clause explicite.

Mais la régularité est écrasante — chaque salve est signée quelques semaines
avant un renouvellement des conseils généraux :

| salve | signature | scrutin suivant |
|---|---|---|
| 1967 | juillet-août 1967 | 24 septembre / 1er octobre 1967 |
| 1973 | juillet-août 1973 | 23 / 30 septembre 1973 |
| 1976 | janvier 1976 | 7 / 14 mars 1976 |
| 1982 | janvier-février 1982 | 14 / 21 mars 1982 |
| 1984-1985 | décembre 1984 - janvier 1985 | 10 / 17 mars 1985 |
| 1988 | avril 1988 | septembre-octobre 1988 |
| 1991 | février 1991 | mars 1992 |
| 1997 | février 1997 | mars 1998 |

Et le seul décret du lot qui le dise en toutes lettres — celui de 1997 — dit
précisément cela : « prendra effet pour le prochain renouvellement des conseils
généraux ».

#### La limite qu'il ne faut pas franchir en silence

Les conseils généraux se renouvelaient **par moitié**, par séries. « Le prochain
renouvellement » d'un canton donné dépend donc de sa série, que nous n'avons
pas. Pour un canton créé, la question ne se pose guère — il entre en vigueur au
scrutin qui l'élit. Pour un canton *modifié*, elle se pose entièrement.

**Recommandation** : poser `valid_from` au scrutin qui suit la signature, et
inscrire la série manquante comme incertitude déclarée dans une colonne de
qualité — comme `c68_qualite` le fait pour 1968. Ne pas confondre une
convention avec un fait : le décalage possible est d'un renouvellement, soit
trois ans.

#### Et les bornes hautes

Étroites, comme pour 1968 : `[scrutin suivant, premier acte postérieur touchant
le même département)`. Ne pas étendre jusqu'à 1999. **Fichiers `75` et `76`.**

---

### 5. L'extension du jalon de 1968 — ce que `60` demandait, désormais possible… à mesurer

`RESTE_A_FAIRE.md` posait : « Étendre le jalon par département — demande une
source par département, pas un seuil. » La source existe maintenant.

Si la liste des actes est complète, l'intervalle de silence autour de 1968 est
long : **27,3 années en moyenne par département**. Beaucoup de départements
n'ont aucun acte entre 1943 et la salve de 1973 — l'Ain, les Bouches-du-Rhône et
la Corse, par exemple, seraient couverts de 1943 à août 1973.

**Mais la condition n'est pas démontrée**, et il faut le dire avant de poser
quoi que ce soit. Test conduit sur 25 398 communes lues à la fois en 1954 et en
1968 :

| | départements | accord 1954 → 1968 |
|---|---|---|
| **avec** acte(s) entre 1954 et 1968 | 14 | 90,9 % |
| **sans** acte entre 1954 et 1968 | 67 | **94,2 %** |

L'écart va dans le bon sens — 3,3 points — donc la liste des actes porte de
l'information. Mais 94,2 % n'est pas 100 %, et les deux côtés viennent d'un OCR
(rappel de 91,4 % pour 1968). On ne sait pas ce qui, dans les 5,8 % restants,
est du mouvement réel et ce qui est du bruit de lecture.

Le test propre — comparer 1968 au COG 1999, qui n'est pas OCRisé — **n'est pas
disponible** : les 100 départements ont au moins un acte entre 1969 et 1999.

**Recommandation** : ne pas étendre en masse. Étendre **là où un acte borne
l'intervalle des deux côtés**, département par département, et laisser le reste
ouvert. C'est plus lent et c'est le seul chemin qui ne fabrique pas de
rattachements faux qu'aucune recette interne ne saurait distinguer des vrais —
la leçon de l'affaire de l'Ain.

---

### 6. Ce qui ne doit pas entrer

- **Les 40 décrets de transfert de parcelles entre communes** (1990-1999). Ils
  traversent une limite cantonale mais ne changent l'appartenance d'aucune
  commune. Ils concernent la géométrie, et la géométrie du dépôt est celle de
  2011 : rien à y faire aujourd'hui. À garder au registre des actes, pas au
  `membership`.
- **Les 29 décrets de « modification de limites cantonales »** muets par nature :
  ils décrivent des tracés de rues, sans liste de communes. Rien à poser.
- **Les 10 décrets de 1990 et 1992 sans texte**, et les 26 décrets dont le JO est
  revenu en 404. Ils sont au registre comme actes connus et non dépouillés —
  ce qui est précisément l'information utile pour interdire un report par-dessus.
- ~~**Le décret 82-82** tant que ses départements ne sont pas établis un par un~~
  — **RÉGLÉ le 29 août 2026, sur pièce** : c'est la **Meurthe-et-Moselle seule**,
  et le JO l'imprime sous le numéro du décret. Le titre Légifrance « dans divers
  départements » est faux. Il est posable, et la table `acte_departement`
  (`72` § 3 bis) porte désormais ce genre d'exception avec son fondement.

---

### Ordre proposé

| fichier | contenu | risque |
|---|---|---|
| `72` | registre des 343 actes | nul |
| `73` | les 5 transferts de commune | très faible |
| `74` | le jalon 1967, borné par le décret et le COG 1968 | faible — contrôlé à 45/0 |
| `75` | les compositions 1973 et 1982 (les deux grosses salves) | **écrit et éprouvé au banc le 28 août 2026** |
| `76` | le reste des compositions | moyen — même convention, tables de `75` |
| `77` | extension du jalon 1968 là où deux actes bornent | à mesurer d'abord |

Les trois premiers étaient posables tels quels. Le quatrième demandait de
trancher la convention de date d'effet et de l'inscrire **comme** convention :
c'est fait, et l'incertitude qu'elle porte est une colonne de la base, pas une
note de bas de page.

Restent à placer les cinq transferts isolés de commune, que `73` § 5 simule
sans écrire : ils relèvent de la même convention et attendent que `75` ait
tourné sur la vraie base.

---

Sources des dates de scrutin : [france-politique.fr](https://www.france-politique.fr/elections-cantonales.htm),
[1967](https://en.wikipedia.org/wiki/1967_French_cantonal_elections),
[1973](https://en.wikipedia.org/wiki/1973_French_cantonal_elections),
[1976](https://en.wikipedia.org/wiki/1976_French_cantonal_elections),
[1982](https://en.wikipedia.org/wiki/1982_French_cantonal_elections),
[1985](https://en.wikipedia.org/wiki/1985_French_cantonal_elections).
