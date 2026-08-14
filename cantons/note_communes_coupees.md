# Communes coupées entre plusieurs cantons — décrets de 1973, 1982 et 1984

Extraction du texte intégral des 136 décrets, à partir des JO numérisés déposés
dans `modif_canton/`. Les PDF portent une couche OCR exploitable.

## Fichiers

| Fichier | Contenu |
|---|---|
| `cantons/communes_coupees_1973_1984.csv` | 579 lignes = un couple (canton × commune coupée), avec le **texte intégral du segment** |
| `cantons/communes_coupees_synthese.csv` | 171 communes, triées par nombre de cantons |
| `cantons/extraire_communes_coupees.py` | le script, rejouable |

## Résultat

**171 communes coupées, réparties sur 117 des 136 décrets.** Les 19 décrets
restants ne redécoupent que des communes entières.

- 529 repérages **explicites** (le texte nomme la commune fractionnée) ;
- 50 **déduits du nom du canton** (canton entièrement intra-urbain, délimité par
  des voies sans que la commune soit renommée — colonne `reperage`) ;
- 494 segments sur 579 contiennent la **description littérale de la limite**
  (axe de voies, rivière, voie ferrée). Les 85 autres renvoient au canton voisin
  (« la portion non incluse dans le canton défini ci-dessus »), donc la limite se
  reconstitue par complément.

### Distribution

| Cantons par commune | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10+ |
|---|---|---|---|---|---|---|---|---|---|---|
| Communes | 32 | 71 | 21 | 12 | 13 | 3 | 5 | 4 | 4 | 6 |

68 communes sont coupées en trois cantons ou plus.

### Les plus morcelées

Marseille 20 · Limoges 18 · Toulouse 15 · Nice 13 · Rennes 12 · Nantes 10 ·
Saint-Étienne, Orléans, Reims, Perpignan 9 · Bordeaux, Tours, Laval, Toulon 8 ·
Troyes, Aurillac, Dijon, Montpellier, Amiens 7.

### Par date

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

## Méthode, et pourquoi elle a changé en cours de route

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

## Contrôles passés

- **Zéro** commune non résolue contre le COG : par construction, une ligne n'est
  écrite que si le nom correspond à une commune réelle du département.
- **Zéro** homonymie ambiguë subsistante.
- 26 lignes sur 579 où le canton ne porte pas le nom de la commune coupée :
  vérifiées une à une, toutes légitimes — Charleville-Mézières partagée entre les
  cantons `Charleville-*` et `Mézières-*`, Chartres entamée par le canton de
  Mainvilliers, La Seyne-sur-Mer par celui de Saint-Mandrier, Le Creusot par
  `Creusot-Est` et `Creusot-Ouest`.

## Limites

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
  `build_txt/*_raw.txt`.

---

Sources : Journal officiel Lois et décrets, numéros 164 (17 juillet 1973),
171 (25 juillet 1973), 180 (4 août 1973), 190 (17 août 1973), 13 (16 janvier 1982),
18 (22 janvier 1982), 21 (26 janvier 1982) et 305 (30 décembre 1984).
Référentiel communal : COG INSEE 1999. Licence etalab-2.0.
