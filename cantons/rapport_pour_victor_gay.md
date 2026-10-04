# Comparaison avec TRF-GIS — rapport à Victor Gay

Adrien Dufour — août 2026

Vous m'aviez écrit vouloir « le détail des comparaisons », en ajoutant avoir
« probablement fait quelques erreurs ». Ce rapport y répond. **Il n'en trouve
aucune.** Il apporte en revanche deux ou trois choses qui pourraient vous
servir, dont une source que vous cherchiez.

---

## 1. Ce qui a été comparé, et comment

J'ai reconstruit une géodatabase des divisions cantonales à partir de TRF-GIS,
puis j'ai confronté **ma reconstruction à vos polygones de cantons dissous**
pour 1870 et 1940 — les deux millésimes où vous les publiez.

Le contrôle est indépendant au sens strict : vos polygones n'entrent pas dans
la construction, ils n'interviennent qu'après, comme étalon. Aucun ajustement
n'a été fait pour améliorer le résultat ; toute divergence a été traitée comme
une information sur ma reconstruction, jamais comme un défaut de la vôtre.

## 2. Le résultat

**L'appariement des clés est parfait, avant toute géométrie.**

| | 1870 | 1940 |
|---|---|---|
| pseudo-cantons chez vous | 3 014 | 3 068 |
| cantons appariés | 2 775 | 2 824 |
| chez moi seulement | **0** | **0** |
| chez vous seulement | **0** | **0** |
| collisions de codes | 0 | 0 |

Aucune clé orpheline, dans aucun des deux sens. La nomenclature que vous avez
constituée et celle que j'ai reconstruite désignent exactement les mêmes
objets.

**Les surfaces concordent à moins d'un pour cent.**

| | vous (km²) | moi (km²) | écart |
|---|---|---|---|
| 1870 | 548 202 | 551 909 | 0,68 % |
| 1940 | 548 202 | 552 205 | 0,73 % |

Et cet écart s'explique entièrement : c'est du **double comptage**. La somme de
mes surfaces cantonales dépasse la surface de leur union de 3 945 km² en 1870
et 4 036 km² en 1940 — exactement l'écart constaté. Vos polygones, eux,
n'ont aucun double comptage : somme et union coïncident au km² près.

**Recouvrement géométrique : IoU 0,992** sur l'ensemble des cantons appariés.

## 3. Les désaccords, et pourquoi ils ne sont pas les vôtres

148 atomes en désaccord sur 38 235. J'ai cherché d'où ils venaient, en
formulant l'hypothèse avant de la tester.

**Le désaccord ne suit pas la source de la géométrie : il suit le partage de
polygone.**

| situation | atomes | en désaccord | |
|---|---|---|---|
| seul sur son polygone | 35 309 | 8 | 0,02 % |
| partage un polygone, même canton | 2 273 | 0 | **0,00 %** |
| partage un polygone, cantons différents | 653 | 140 | **21,4 %** |

Le mécanisme est le mien, pas le vôtre. Une commune A absorbée depuis par B
reçoit dans ma base le polygone de B — donc A ∪ B — tandis que B le reçoit
aussi par jointure directe : deux atomes, un seul polygone. Tant que A et B
sont dans le même canton, l'union les recolle, d'où la ligne à zéro. Quand ils
sont dans des cantons différents, le territoire est revendiqué deux fois.

**Après élimination de ce mécanisme, il reste trois désaccords sur 38 235**, et
ce sont trois arbitrages que j'ai posés délibérément et tracés comme tels.
Aucun désaccord inexpliqué ne subsiste.

## 4. Les trois cas où nous divergeons vraiment

Chacun tient à **un seul polygone partagé**, et dans chacun aucun de nous deux
n'a tort dans son propre cadre.

| département | surface en cause |
|---|---|
| Haute-Marne | 130,1 km² |
| Deux-Sèvres | 88,1 km² |
| Marne | 59,0 km² |

Cas d'école, la commune 52210 : haut-marnaise en 1870, absorbée depuis par une
commune de Haute-Saône. J'attribue le polygone au canton haut-marnais parce que
je suis la commune de 1870 ; vous l'attribuez au canton haut-saônois parce que
vous suivez le territoire moderne. Les deux lectures sont défendables et le
désaccord est une propriété du problème, pas une erreur.

## 5. Ce que je peux vous rendre

### 5.1 Une source pour 1954, que vous cherchiez

Vous m'écrivez que le COG de 1954 n'est pas en ligne, et que vous avez dû
forger une codification *ad hoc* pour les cantons disparus avant 1954
(article, p. 198).

Le volume du recensement de 1954 est en ligne, en **domaine public**, et il
porte plus que la nomenclature :

**<https://www.bnsp.insee.fr/ark:/12148/bc6p06z8sm1>**
*Recensement de 1954. Population de la France. Départements, arrondissements,
cantons et communes (métropole)* — 958 pages.

Trois choses y sont exploitables :

1. **La nomenclature cantonale avec ses codes**, en tête de chaque département,
   assortie de notes datant les créations récentes.
2. **Le « Tableau A — Modifications aux circonscriptions territoriales »**,
   page 895, qui donne les cantons créés **avec les communes qui les
   composent** et le décret, le canton supprimé, les cantons ayant changé
   d'arrondissement et ceux dont le chef-lieu a été transféré.
3. **La composition cantonale commune par commune** : chaque ligne du tableau
   de population porte deux colonnes numériques, arrondissement et canton,
   entre la population de 1946 et le nom de la commune. **Cette numérotation
   est celle de TRF-GIS** — vérifié sur 22 communes de l'Aisne, 22
   concordances, ce qui confirme sur pièces votre alignement sur le COG de
   1954.

Le PDF n'a pas de couche texte ; j'ai dû l'OCRiser. Les scripts et les données
extraites sont à votre disposition si cela vous est utile.

### 5.2 Le tableau A, transcrit

Les créations cantonales entre 1941 et 1954, d'après le tableau A :

| département | canton créé | communes | décret |
|---|---|---|---|
| Alpes-Maritimes | Tende | La Brigue, Tende | 10 sept. 1951 |
| Corrèze | Brive-la-Gaillarde-Nord | Brive-la-Gaillarde-Nord, Dampniat, Venarsal | 13 sept. 1951 |
| Corrèze | Brive-la-Gaillarde-Sud | Brive-la-Gaillarde-Sud, La Chapelle-aux-Brocs, Cosnac, Estivals, Jugeals-Nazareth, Malemort-sur-Corrèze, Nespouls, Noailles | 13 sept. 1951 |
| Lot | Sousceyrac | Comiac, Lacam-d'Ourcet, Lamativie, Sousceyrac | 5 sept. 1949 |

Plus la suppression du canton de Brive-la-Gaillarde le 13 septembre 1951, trois
changements d'arrondissement et quatre transferts de chef-lieu, tous datés.

**Une divergence interne au volume**, que je signale sans la trancher : le
tableau A date la création de Tende du **10 septembre 1950**, tandis que les
notes de bas de page des pages 19 et 126 impriment **10 septembre 1951**. Deux
mentions contre une, et l'atlas Gaudillère donne aussi 1951.

### 5.3 Ce que la comparaison 1940-1954 permet de dire

En confrontant la composition de 1940 (TRF-GIS) à celle lue dans le volume de
1954, sur 23 791 communes appariées : **98 % sont dans le même canton**. Les
créations relevées correspondent exactement au tableau A et à l'atlas
Gaudillère.

Les 311 « transferts » restants sont **du bruit d'OCR** : un test de contiguïté
géométrique en réfute 227 — une commune ne peut pas rejoindre un canton dont
elle est séparée de 100 km — et les survivants sont isolés ou situés sur la
frontière entre deux cantons appariés, là où une erreur de chiffre tombe par
hasard. Je ne peux donc rien affirmer sur les transferts de communes, que le
volume dit pourtant nombreux.

## 6. Ce que j'ai fait par ailleurs, si cela vous intéresse

L'annexe VII de l'atlas Gaudillère est transcrite intégralement — 1 098
décisions, 98 départements, 39 pages — et vérifiée par un contrôle arithmétique
indépendant : pour chaque département, `cantons_1999 − cantons_1940` doit
égaler `créations − disparitions`. **56 départements sur 85 bouclent
exactement** ; les résidus s'expliquent par les cantons créés entre 1986 et
1999, hors de portée de l'annexe. Cela donne au passage une mesure inédite :
**environ 48 cantons créés entre 1986 et 1999**, que ni l'annexe ni le COG ne
donnent.

---

Merci encore de votre réponse, qui a débloqué deux choses d'un coup : la
licence de la base Cassini EHESS, que j'avais confondue avec Cassini-Geopeuple,
et la piste du recensement de 1954. Le travail est en cours et je vous tiendrai
au courant.

Bien cordialement,
Adrien Dufour
