# 1990-1999 sur Légifrance — 100 % d'accord avec le COG, et cinq transferts que l'annexe VII ignore

Fichiers produits : `cantons/composition_legifrance.csv` (252 lignes),
`cantons/transferts_legifrance.csv` (5 lignes),
`cantons/controle_composition_legifrance.csv`.

Entrée figée : `cantons/legifrance_1990_1999.txt`. Script :
`cantons/composition_legifrance.py`.

---

## 1. Ce que contiennent réellement les 83 décrets

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

## 2. Le résultat, et un contrôle sans précédent dans le dépôt

252 lignes, **20 décrets, 71 cantons**, sur 1991, 1993 et 1997.

Appariement des noms : **93,3 % exacts**, 0,4 % par `insee_mvt`, 0,4 % par
ressemblance, 5,6 % de cantons faits de fractions seules — et **zéro rejet**.

### Contrôle indépendant par le COG 1999

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

## 3. Les cinq transferts, et pourquoi ils comptent

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

## 4. Ce qui manque encore, et ce que ça coûte

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

## 5. Comment le texte a été obtenu

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
