# Les cantons `post_1986` du registre — datation

Fichier produit : `cantons/cantons_post1986_datation.csv` (64 cantons).

## Le résultat qui compte : la catégorie est mal nommée

Sur les 64 cantons que le registre classe `post_1986`, **19 sont antérieurs à
1986**. Le label ne dit pas « créé après 1986 » mais « non nommé par l'annexe
VII » — et l'annexe est muette bien avant sa date d'arrêt.

| Canton | Décret réel |
|---|---|
| 87 Limoges-Cité, Limoges-Le Palais, Limoges-Panazol | n° 73-821 du 16 août 1973 |
| 50 Ducey, La Haye-du-Puits, Sartilly | n° 73-664 du 13 juillet 1973 (piste) |
| 64 Arthez-de-Béarn, Pau-Sud | n° 73-669 du 13 juillet 1973 (piste) |
| 43 Le Puy-en-Velay Est / Ouest / Sud-Ouest, Saugues | n° 73-767 du 2 août 1973 (piste) |
| 17 La Rochelle 3e canton | n° 73-655 du 13 juillet 1973 |
| 22 Plérin | n° 82-54 du 20 janvier 1982 |
| 27 Vernon-Sud | n° 82-56 du 20 janvier 1982 |
| 33 Villenave-d'Ornon | n° 82-29 du 15 janvier 1982 |
| 87 Limoges-Landouge | n° 82-86 du 25 janvier 1982 |
| 62 Barlin | n° 84-1236 du 24 décembre 1984 |
| 90 Châtenois-les-Forges | décret du 19 janvier 1970 (piste) |

Sept d'entre eux étaient déjà sous nos yeux : ils figurent dans les décrets de
1973-1984 dépouillés à l'étape précédente. Les autres viennent de décrets
identifiés par leur titre sur Légifrance.

**Le chiffre de 48 (ou 64 lignes) surestime donc les créations tardives**, pour
la même raison que les 120 « créations » du Val-d'Oise et de la Corse
surestimaient les mouvements : une source silencieuse se déguise en événement.
C'est le piège déjà noté dans `registre_consolide.md`, sous une autre forme.

## État de la datation

| Statut | Cantons |
|---|---|
| **daté** (texte lu) | 51 |
| **piste** (décret identifié par son titre, texte non consultable) | 12 |
| **non retrouvé** | 1 — Le Havre 6e canton (76) |

Répartition des dates retenues :

| Date | Cantons | |
|---|---|---|
| 19 janvier 1970 | 1 | Territoire de Belfort |
| 1973 (13/07, 02/08, 16/08) | 13 | |
| 1982 (15/01, 20/01, 25/01) | 4 | |
| 24 décembre 1984 | 1 | |
| 21 avril 1988 | 2 | Isère (piste) |
| **27 février 1991** | **27** | la vague principale |
| 26 février 1993 | 1 | Seine-et-Marne |
| 13 janvier & 21-26 février 1997 | 13 | |

## Les deux vagues de la fin de période

**27-28 février 1991** — décrets n° 91-209 à 91-232, seize départements
métropolitains plus Guadeloupe et Réunion. C'est de loin la plus grosse : 27
des cantons cherchés, dont les onze du Pas-de-Calais (91-217) et les sept de
Brest (91-211).

**13 janvier et 21-27 février 1997** — huit départements. Les décrets de février
1997 **ne portent pas de numéro** (« Décret du 21 février 1997 portant
modification et création de cantons dans le département de… ») ; ils se citent
par date et département.

## Ce que ça change pour l'accès aux textes

Les décrets **de 1990 et après ont leur texte intégral sur Légifrance**, articles
et listes de communes compris — y compris les délimitations de communes coupées,
au même format que 1973 :

> « […] la portion de territoire de la commune d'Hénin-Beaumont située au
> Sud-Est d'une ligne définie par l'axe des voies ci-après […] »
> — décret n° 91-217, art. 2

Aucun PDF ni OCR nécessaire pour 1991, 1993 et 1997. En revanche 1970, 1988 et
tout l'avant-1990 restent tributaires des JO numérisés.

## Pour le trou cantonal 1943-1999

Recherche Légifrance, fonds JORF, « création de cantons », signature entre 1943
et 1985 : **207 décrets**. La liste des actes existe donc en entier et se
récupère par titre ; seul le contenu d'avant 1990 demande les JO papier.

Deux conséquences pratiques :

- les huit dates traitées jusqu'ici (1973, 1982, 1984) ne sont qu'une fraction
  de la série — il existe par exemple un décret n° 82-95 du **27 janvier 1982**,
  absent de la liste de départ ;
- la voie la plus économique pour combler le trou n'est pas de dater canton par
  canton, mais de **dépouiller les 207 décrets dans l'ordre**, puisque chacun
  porte lui-même sa date.

## Limites

- Les 12 « pistes » reposent sur le seul titre du décret : le bon département et
  la bonne période, pas la lecture du dispositif. À confirmer sur le JO.
- Le Havre 6e canton n'a aucun décret candidat sur 1943-1999 dans les titres
  Légifrance. Soit le titre est formulé autrement, soit la création est
  antérieure à 1943.
- L'appariement des noms tolère les variantes d'écriture des suffixes
  (« 3e Canton » ≈ « -III »). Deux cantons voisins d'une même ville pourraient
  en théorie être confondus ; aucun cas repéré ici.

---

Sources : Légifrance, fonds JORF (recherche par date de signature et en plein
texte des articles) ; JO numérisés déjà dépouillés dans `modif_canton/`.
Licence etalab-2.0.
