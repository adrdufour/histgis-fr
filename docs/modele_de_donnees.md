# Le modèle de données

Ce document décrit la base `histgis` telle qu'un utilisateur la voit : ses
tables principales, ses conventions d'identifiants et les fonctions qui
servent à l'interroger. Pour la justification de chaque choix, voir
`METHODE.md` § 1, § 2 et § 5. Pour les termes, voir [`glossaire.md`](glossaire.md).

Tout se trouve dans le schéma `histgis`, en Lambert-93 (EPSG:2154).

```sql
SET search_path TO histgis, public;
```

---

## Le principe : géométrie et appartenance séparées

```
 ┌──────────────┐        ┌──────────────────────┐        ┌───────────────┐
 │    atom      │ 1    n │      membership      │ n    1 │     unit      │
 │──────────────│────────│──────────────────────│────────│───────────────│
 │ atom_id (PK) │        │ atom_id              │        │ unit_id (PK)  │
 │ cassini      │        │ unit_id, niveau      │        │ niveau        │
 │ fraction     │        │ valid_from, valid_to │        │ dep           │
 │ insee_geofla │        │ periode (daterange)  │        │ regime …      │
 └──────┬───────┘        └──────────────────────┘        └──────┬────────┘
        │ 1                                                     │ 1
        │                                                       │
        │ 0..1  ┌───────────────┐                         n     │
        ├───────│  atom_geom    │  polygone GEOFLA 2011   ┌─────┴─────────┐
        │       └───────────────┘                         │ unit_version  │
        │ 0..n  ┌───────────────┐                         │ nom, période  │
        └───────│ atom_geom_anr │  polygones datés (ANR)  └───────────────┘
                └───────────────┘
```

La carte d'une date se calcule ainsi : on prend les rattachements
(`membership`) valides à cette date, on récupère le polygone de chaque atome
**valide à cette date**, et on réunit les polygones par unité. Rien n'est
pré-calculé, ce qui permet de corriger une attribution ou de changer de fond
géométrique sans rien reconstruire d'autre.

---

## Les tables

### `atom` : l'unité au rattachement stable

| colonne | sens |
|---|---|
| `atom_id` | identifiant. Code Cassini pour une commune entière, `cassini#canton` pour une fraction, codes spécifiques pour les atomes modernes (après 1943) |
| `cassini` | code Cassini de la commune d'époque |
| `fraction` | `true` si l'atome n'est qu'un morceau de commune |
| `insee_geofla` | code INSEE de 2011 qui sert à trouver le polygone (`NULL` s'il n'y en a pas) |

**Attention : un `atom_id` ressemble à un code INSEE, mais ce n'en est pas
un.** Les deux sont des chaînes de 5 caractères, souvent identiques, parfois
non. Joignez toujours sur la bonne colonne (voir `METHODE.md` § 14.6).

### `unit` et `unit_version` : cantons et circonscriptions

| colonne de `unit` | sens |
|---|---|
| `unit_id` | identifiant pérenne, unique tous niveaux confondus |
| `niveau` | `canton` ou `circo` |
| `dep` | code du département |
| `regime` | pour une circo : `liste` ou `uninominal` |
| `segment_depuis` | pour une circo : année d'ouverture du découpage auquel elle appartient |
| `nom` | dernier nom connu (colonne de confort, ne pas l'utiliser pour une date) |
| `provisoire` | unité citée par les sources mais absente des nomenclatures, donc sans nom attesté |

**Conventions d'identifiants** :

- **canton** : `DDNN`, soit le département suivi du numéro du (pseudo-)canton
  dans TRF-GIS. Un canton garde le même `unit_id` de 1870 à 2012.
- **circonscription** : `L` (scrutin de liste) ou `U` (uninominal), suivi du
  code brut département+circonscription, de `@` et de l'année d'ouverture du
  découpage. Une circonscription redécoupée est donc une nouvelle unité.

`unit_version` porte les **noms datés** : une ligne par nom et par période.
Pour obtenir le nom d'une unité à une date, utilisez `unit_nom(unit_id, date)`.

### `membership` : le cœur de la base

Une ligne par période de rattachement d'un atome à une unité.

| colonne | sens |
|---|---|
| `atom_id`, `unit_id`, `niveau` | qui appartient à quoi |
| `valid_from`, `valid_to` | intervalle `[début, fin)`, borne de fin **exclue** |
| `periode` | le même intervalle en `daterange`, indexé (GiST) |

La contrainte `membership_non_chevauchant` interdit qu'un atome appartienne à
deux unités d'un même niveau au même instant. La base refuse donc toute
incohérence de ce type au chargement.

Pour tester si un rattachement est valide à une date : `periode @> date '1885-06-01'`.

### `atom_geom` : la trame de 2011

Un polygone par atome, tiré de GEOFLA 2011. La colonne `source` dit comment
le polygone a été trouvé :

| `source` | sens |
|---|---|
| `geofla` | jointure directe sur le code INSEE |
| `successeur` | commune disparue avant 2011 : polygone de la commune qui l'a absorbée (mouvements INSEE) |
| `hac`, `hac_partage` | idem, d'après HAC ; `hac_partage` est un choix arbitraire entre plusieurs successeurs |
| `union_prefixe`, `arrondissement` | Lyon et Marseille, à partir de leurs arrondissements |
| `absorbee` | correspondance saisie à la main (`geom_correspondance.csv`) |
| `creation_arriere` | commune née après 1940, découpée rétroactivement dans sa mère |
| `fraction_cog` | fraction de commune pour la période moderne |

`partagee = true` signale qu'un même polygone est porté par plusieurs atomes.
C'est voulu, mais deux atomes qui partagent un polygone et tombent dans des
cantons différents produisent une superposition sur la carte.

### `atom_geom_anr` : la trame historique datée

Plusieurs polygones par atome, chacun valide sur une période
(`periode daterange`), tirés d'ANR-COMMUNES. Une contrainte garantit un seul
polygone par atome et par date. `poly_id` est l'identifiant du polygone chez
ANR.

### Autres tables utiles

| table | contenu |
|---|---|
| `regime_electoral` | régime de scrutin législatif, année par année |
| `insee_mvt`, `commune_successeur` | mouvements de communes INSEE depuis 1943 et chaînes d'absorption |
| `noms_geofla` | noms de communes de 2011 |
| `iris_ville` | fond IRIS des villes à découper |
| `*_trace` | ce que chaque fichier de la chaîne a posé (traçabilité) |
| `ctrl_*`, `diag_*` | résultats de contrôles et de diagnostics : à consulter, pas à joindre |
| `om_*` | l'outre-mer, dans un espace séparé avec ses propres fonctions (`om_snapshot`, `om_snapshot_geom`) |

---

## Les fonctions d'interrogation

| fonction | renvoie |
|---|---|
| `snapshot(date, niveau)` | une ligne par unité vivante : nom d'époque, nombre et liste des atomes. Pas de géométrie. |
| `snapshot_geom(date, niveau)` | la même chose avec la géométrie dissoute sur la trame **GEOFLA 2011**, plus `n_sans_geom` et `n_partagees` |
| `snapshot_geom_anr(date, niveau)` | la géométrie sur la trame **ANR datée**, avec repli sur GEOFLA ; `n_anr` et `n_repli` disent d'où vient chaque forme |
| `carte_partition(date, niveau, dep)` | la carte **sans trou ni superposition** (règle de reprise), plus `n_repris`. Lente : à appeler par département. |
| `carte_coupe_ville(insee, date)` | les fractions d'une ville découpée par ses rues, quand la coupe existe |
| `unit_nom(unit_id, date)` | le nom d'une unité à une date |
| `count_units(date)` | nombre d'unités, de départements et d'atomes par niveau |
| `om_snapshot(date, niveau)`, `om_snapshot_geom(date, niveau)` | équivalents pour l'outre-mer |

`niveau` vaut `'canton'` (par défaut) ou `'circo'`.

### Quelle fonction utiliser ?

- **Pour savoir quelle commune appartient à quel canton** : `snapshot`. La
  composition ne dépend pas du fond géométrique.
- **Pour une carte rapide** : `snapshot_geom_anr`. Les formes sont d'époque
  quand ANR les connaît, celles de 2011 sinon.
- **Pour une carte à publier** : `carte_partition`, département par
  département. C'est la seule qui garantit qu'aucune parcelle n'est comptée
  deux fois. C'est aussi ce qu'utilise la carte web.
- `snapshot_geom` (GEOFLA seul) sert surtout de référence et aux contrôles.
  Ses superpositions sont connues (environ 3 900 km² en 1870).

### Les contrôles

| fonction | vérifie |
|---|---|
| `check_gaps(niveau)` | atomes dont la chronologie a des trous |
| `check_coverage(date)` | communes rattachées à un canton mais pas à une circo, ou l'inverse |
| `check_nesting(date)` | cantons répartis sur plusieurs circonscriptions |
| `check_orphans()` | unités sans nom, atomes sans rattachement ni géométrie |
| `check_geom()`, `check_geom_overlap(date, niveau)` | couverture et superpositions de la trame GEOFLA |
| `check_geom_anr(date)` | idem pour la trame ANR |
| `check_partition(date, …)`, `check_coupe_partition(date, …)` | recettes de la carte partitionnée et des villes découpées |

---

## Exemples

```sql
-- Les cantons de l'Ain au 1ᵉʳ juin 1885, avec leur surface
SELECT unit_id, nom, round(ST_Area(geom) / 1e6) AS km2
FROM   snapshot_geom_anr('1885-06-01', 'canton')
WHERE  dep = '01'
ORDER  BY nom;

-- L'histoire d'une commune (ici Montluçon, INSEE 03185) : ses cantons successifs.
-- On passe par insee_geofla, car atom_id n'est pas un code INSEE. Une ville
-- partagée entre plusieurs cantons renvoie une ligne par fraction.
SELECT m.atom_id, m.valid_from, m.valid_to, m.unit_id,
       unit_nom(m.unit_id, m.valid_from) AS canton
FROM   membership m
JOIN   atom a USING (atom_id)
WHERE  a.insee_geofla = '03185' AND m.niveau = 'canton'
ORDER  BY m.valid_from, m.atom_id;

-- Les cantons qui existaient en 1900 et plus en 1960
SELECT unit_id, unit_nom(unit_id, '1900-01-01')
FROM   snapshot('1900-01-01', 'canton')
EXCEPT
SELECT unit_id, unit_nom(unit_id, '1900-01-01')
FROM   snapshot('1960-01-01', 'canton');

-- Exporter une carte en GeoPackage (en ligne de commande)
-- ogr2ogr -f GPKG cantons_1885.gpkg PG:"dbname=histgis" \
--   -sql "SELECT unit_id, nom, geom FROM histgis.snapshot_geom_anr('1885-06-01','canton')"
```

Le troisième exemple compare des **identités** de cantons : un canton qui
existe toujours mais a perdu des communes n'y figure pas.

---

## Lire un résultat correctement

1. **Aucune ligne ne veut pas dire zéro.** Une date sans source renvoie un
   résultat vide pour l'unité concernée. Comparez toujours un comptage à
   l'ordre de grandeur attendu : `count_units` donne entre 2 860 et 3 030
   cantons pour 1870-1940, et environ 3 800 vers 2000.
2. **Paris, Lyon et Marseille** sont codés par arrondissement dans les
   référentiels modernes : une jointure sur `13055`, `69123` ou `75056` peut
   ne rien renvoyer.
3. **Grouper par la géométrie, jamais par un code.** Pour compter des
   territoires distincts, regroupez sur `md5(ST_AsEWKB(geom))`, car plusieurs
   atomes peuvent porter le même polygone.
4. **Le référentiel bouge** : le recodage de la Corse en `2A`/`2B` (1976) ou le
   démembrement de la Seine (1964-1968) n'est pas un mouvement cantonal.
5. **Les compteurs `n_repli`, `n_repris`, `n_partagees` et `n_sans_geom`**
   disent à quel point une forme est sûre. Une carte publiée devrait les
   signaler.

Toutes ces règles, et d'autres, sont détaillées dans la partie II de
`METHODE.md` (index au § 10).
