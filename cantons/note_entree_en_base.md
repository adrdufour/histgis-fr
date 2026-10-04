# Ce qui peut entrer en base, et dans quel ordre

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

## Le chiffre d'ensemble

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

## 1. Le registre des actes — à poser en premier, risque nul

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

## 2. Les cinq transferts de commune — exacts, vérifiés, immédiats

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

## 3. Le jalon de 1967 — posable, et il valide le jalon de 1968

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

## 4. Les compositions comme jalons datés — le gros du lot, et le vrai problème

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

### Le problème : `valid_from` n'est pas la date de signature

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

### La limite qu'il ne faut pas franchir en silence

Les conseils généraux se renouvelaient **par moitié**, par séries. « Le prochain
renouvellement » d'un canton donné dépend donc de sa série, que nous n'avons
pas. Pour un canton créé, la question ne se pose guère — il entre en vigueur au
scrutin qui l'élit. Pour un canton *modifié*, elle se pose entièrement.

**Recommandation** : poser `valid_from` au scrutin qui suit la signature, et
inscrire la série manquante comme incertitude déclarée dans une colonne de
qualité — comme `c68_qualite` le fait pour 1968. Ne pas confondre une
convention avec un fait : le décalage possible est d'un renouvellement, soit
trois ans.

### Et les bornes hautes

Étroites, comme pour 1968 : `[scrutin suivant, premier acte postérieur touchant
le même département)`. Ne pas étendre jusqu'à 1999. **Fichiers `75` et `76`.**

---

## 5. L'extension du jalon de 1968 — ce que `60` demandait, désormais possible… à mesurer

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

## 6. Ce qui ne doit pas entrer

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

## Ordre proposé

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
