# Les trois circonscriptions de Bourg-en-Bresse en 1986

## La réponse

Bourg-en-Bresse (01053) est coupée entre **trois** des quatre circonscriptions
de l'Ain du découpage de 1986. La coupure n'est pas propre au découpage
législatif : elle est **cantonale**, et la loi du 24 novembre 1986 s'est
contentée de répartir les cantons existants.

| Circonscription | Canton intra-urbain | Autres cantons |
|---|---|---|
| **01-01** | 0105 Bourg-en-Bresse-**Est** | 10 cantons ruraux, dont 0139 Péronnas |
| **01-03** | 0137 Bourg-en-Bresse-**Nord-Centre** | 11 cantons, dont 0143 Viriat |
| **01-04** | 0138 Bourg-en-Bresse-**Sud** | 9 cantons |

La 2e circonscription (01-02) ne touche pas la ville.

Chacun de ces trois cantons ne contient **que** la commune 01053 : la limite
entre les trois circonscriptions à l'intérieur de Bourg-en-Bresse est donc
exactement la limite entre ces trois cantons.

Composition complète des quatre circonscriptions de l'Ain :
`circo/circo_1986_ain.csv`.

## D'où vient la coupure

Décret **n° 82-77 du 25 janvier 1982** (JO du 26 janvier 1982, p. 371) :

> « En remplacement des cantons de Bourg-en-Bresse-I, Bourg-en-Bresse-II et
> Bourg-en-Bresse-III, il est créé quatre cantons dénommés et délimités comme
> suit […] »

Quatre cantons : Bourg-Nord-Centre, Bourg-Est, Bourg-Sud — les trois qui
découpent la ville — et **Bourg-Couronne**, qui ne prend que des communes
périphériques et ne mord pas sur Bourg-en-Bresse. Couronne a ensuite été
scindée en Péronnas (0139) et Viriat (0143), d'où les six cantons du secteur
en 1999.

Ce décret remplace lui-même celui de 1973 (**n° 73-810 du 16 août 1973**), qui
avait créé Bourg-en-Bresse-I, II et III sur un tracé différent. Les deux textes
sont dans `cantons/communes_coupees_1973_1984.csv` ; **si vous cartographiez
1986, c'est le tracé de 1982 qu'il faut, pas celui de 1973.**

## Le texte des limites

`circo/bourg_en_bresse_1986_delimitations.md` porte les trois délimitations in
extenso, transcrites du JO. Elles sont décrites par voies, cours d'eau et voies
ferrées :

> Bourg-Sud : « au Sud, par la limite communale avec Péronnas ; à l'Ouest, par
> la limite de la commune de Bourg-en-Bresse ; au Nord, par la voie ferrée
> Bourg—Mâcon et par l'axe des voies ci-après : avenue des Anciens-Combattants,
> boulevard Paul-Bert (jusqu'à la place Perrier-Labalme), avenue
> Jean-Marie-Verne […] »

## Un détail qui va vous gêner

La limite entre Bourg-Nord-Centre et Bourg-Est passe **au milieu d'une rue, par
numéros de voirie** :

- Nord-Centre : « rue des Chrysanthèmes (jusqu'à son intersection avec l'impasse
  des Granges-Bardes, **sauf** les n°s 17, 19, 21, 23 et 25) »
- Est : « rue des Chrysanthèmes (jusqu'à son intersection avec l'impasse des
  Granges-Bardes, **y compris** les n°s 17, 19, 21, 23 et 25) »

Les deux formulations se répondent exactement — ce n'est pas une coquille d'OCR.
Cinq maisons changent de canton, donc de circonscription. Aucune reconstitution
par IRIS, par îlot ou par axe de voirie ne restituera ça : il faut soit
l'accepter comme limite approchée à l'échelle de la rue, soit descendre au
parcellaire.

À rapprocher de `paris_decoupage` : la même question s'y pose, et la même
réponse — la précision du texte dépasse celle des géométries disponibles.

## Sources

- Décret n° 82-77 du 25 janvier 1982 —
  https://www.legifrance.gouv.fr/jorf/id/JORFTEXT000000883847
  (JO numérisé : `sources/modif_canton/JORF_19820126_21.pdf`)
- Décret n° 73-810 du 16 août 1973 —
  https://www.legifrance.gouv.fr/jorf/id/JORFTEXT000000303616
- Rattachement canton → circonscription 1986 : `circo/circo_1986.csv`, issu du
  tableau de correspondance du ministère de l'Intérieur (Licence Ouverte).
