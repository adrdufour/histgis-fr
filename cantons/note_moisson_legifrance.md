# Moissonnage Légifrance — les décrets cantonaux, 1958-1999

Fichier produit : `cantons/decrets_cantonaux.csv` (343 décrets), qui remplace et
englobe `cantons/decrets_1973_1984.csv` (136).

Reproduction : `cantons/moisson_brute.txt` (la moisson telle qu'elle sort) et
`cantons/build_moisson.py` (le tri et la mise en forme).

---

## 1. Ce qui est acquis

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

### La méthode, et pourquoi elle est exhaustive

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

### Le piège du filtre, signalé et non effacé

Le premier tri perdait **un** décret sur 343 — le n° 82-35 (Pas-de-Calais).
Le motif d'exclusion du bruit vinicole, `/VINS?\b/`, avait mordu sur le canton
de **LIÉVIN**. Le décret est réinjecté explicitement dans `build_moisson.py`, où
la ligne porte son commentaire. Six autres textes sont écartés à la relecture et
nommés dans le script (caisses d'épargne, commissaires-priseurs, tribunal, deux
textes algériens hors champ, un texte de portée générale).

C'est la troisième fois que le contrôle de rappel contre un étalon existant
rattrape un défaut de filtre, et non un défaut de source.

---

## 2. Le résultat qui change quelque chose : 1990-1995

`RESTE_A_FAIRE.md` posait comme lacune n° 2 « toute liste d'actes pour
**1990-1995** — l'annexe VII s'arrête en 1989 et le COG 1999 ne remonte qu'à
avril 1995 ».

**49 décrets sont datés entre 1990 et 1995**, 83 entre 1990 et 1999. Et pour ces
textes-là, **Légifrance conserve le texte intégral** : pas de PDF, pas de
CAPTCHA, pas d'OCR. Vérifié sur le n° 91-218 (Seine-Maritime), dont les
articles s'affichent en clair — c'est le décret du renumérotage du Havre déjà
connu par `pdf_a_telecharger.md`.

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

## 3. Ce qui bloque encore : 124 décrets derrière le CAPTCHA

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

## 3 bis. Quatre départements corrigés — le « NORD » qui n'en était pas un

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

## 4. Confrontation au registre `mouvements_cantonaux.csv`

*(chiffres mis à jour après la correction ci-dessus)*

Sur 192 couples (département, date) datés au registre, **164 ont un décret** à la
même date de signature. L'écart va dans les deux sens, et il est plus large que
ce que la note de 1973/1982/1984 laissait voir.

### 93 décrets sans décision au registre (1945-1989)

L'annexe VII sous-compte massivement. Quelques blocs entiers lui échappent :
les six décrets du 20 juillet 1967 (petite couronne), les quatre du 18 août
1973, les treize signés en 1985 hors des dates qu'elle retient, et la
quasi-totalité de 1986-1989.

### 19 couples du registre sans décret trouvé (≥ 1945)

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

## 5. Limites de ce fichier

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
