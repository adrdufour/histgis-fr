# La chaîne `sql/` — qui fait quoi, dans quel ordre, et ce qui ne sert plus

Dressé le 20 août 2026 en lisant les 46 fichiers, pas en les supposant. La
journée a montré qu'on pouvait reconstruire la base en croyant l'avoir faite :
la chaîne s'est arrêtée après `24`, la couche des circonscriptions est restée
vide, et le contrôle indépendant n'en a rien dit — il ne regarde que 1870 et
1940.

**Trois familles**, et c'est la distinction qui manquait :

| famille | écrit dans la base ? | où |
|---|---|---|
| **construction** | oui — `membership`, `atom`, `unit`… | § 1 |
| **diagnostic** | non, lecture seule | § 2 |
| **espace séparé** | oui, mais dans `om_*` | § 3 |

---

## 1. La chaîne de construction, dans l'ordre

`rebuild.sh` couvre les étapes 1 à 8. `rejouer_apres_rebuild.sh` couvre le
reste. Les deux sont à jour au 20 août 2026.

| # | fichier | rôle | écrit | trace | `-v` requis |
|---|---|---|---|---|---|
| 1 | `01_schema.sql` | tables, contraintes `EXCLUDE`, index. **Destructif** : `DROP SCHEMA CASCADE` | — | — | — |
| 2 | `02_load.sql` | `\copy` des CSV de `build/`, reconstruction des noms | `atom` `unit` `unit_version` `membership` | — | `f` = dossier `build/` |
| 3 | `03_functions.sql` | `snapshot()`, `unit_nom()`, `check_*()` | — | — | — |
| 4 | `05_geom.sql` | polygones GEOFLA 2011 sur les atomes | `atom_geom` | — | — |
| 5 | `06_insee_mvt.sql` | mouvements INSEE, `commune_successeur` | `atom_geom` | — | `mvt` = `sources/v_mvt_commune_2025.csv` |
| 6 | `07_reliquat.sql` | rattrapage HAC des communes disparues | `atom_geom` | — | — |
| 7 | `11_scission.sql` | prolonge vers 1870 les communes nées pendant la série | `membership` | `scission_trace` | — |
| 8 | `15_creation_arriere.sql` | communes nées **après** la série : atome-fraction + chronologie de la mère | `atom` `atom_geom` `membership` | `creation_trace` | — |
| 8bis | `19_noms_geofla.sql` | table des noms de communes, projection de `geofla_commune` | — | — | — |
| 9 | `20_commune_moderne.sql` | chronologie communale 1943-2012 (tables `cm_*`) | — | — | — |
| 10 | `21_atomes_modernes.sql` | atomes manquants pour 1943-2012, crée `commune_moderne` | `atom` `atom_geom` | `atome_moderne_trace` | — |
| 11 | `22_cog_stage.sql` | charge les 14 millésimes du COG | — | — | — |
| 12 | `37_reparer_encodage.sql` | répare les noms lus en Latin-1. **Tourne à blanc par défaut** : relancer avec `-v appliquer=1` | `unit` `unit_version` | `encodage_trace` | — |
| 13 | `24_canton_moderne.sql` | cantons 1999-2012, atomes-fractions | `atom` `atom_geom` `unit` `unit_version` `membership` | `canton_moderne_trace` | — |
| 14 | `25_pseudo_canton.sql` | pseudo-cantons de Marseille et Lyon | `unit` `unit_version` `membership` | `pseudo_canton_trace` | — |
| 15 | `27_circo_2012.sql` | circonscriptions du découpage de 2009 (2010-2013) | `unit` `unit_version` `membership` | `circo_moderne_trace` | **`circo`** = `circo/circo_2012.csv` |
| 16 | `28_circo_1986.sql` | circonscriptions de 1986 (1986-2010) | `unit` `membership` | `circo1986_trace` | **`circo`** = `circo/circo_1986.csv` |
| 17 | `32_marseille_geom.sql` | géométrie des cantons de Marseille | `atom_geom` `membership` | `marseille_trace` | — |
| 18 | `38_decret_1982_ain.sql` | décret de 1982, cantons de Bourg-en-Bresse | `membership` `unit_version` | **AUCUNE** | — |
| 19 | `39_meurthe_1870.sql` | la Meurthe reprend le numéro 54 | `unit` | — (idempotent) | — |
| 20 | `40_scission_circo.sql` | comble les trous de la couche circo par les voisins de canton | `membership` | `scission_circo_trace` | — |
| 21 | `41_retablissement.sql` | communes rétablies après 1999 — trois voies | `membership` | `retablissement_trace` | — |
| 22 | `42_rattachement_arriere.sql` | rattache le passé d'un atome existant. **Rend 0 cas depuis que le garde-fou 6 de `15` résout les recodages** : Chisa et Butry sont traitées en amont. Reste comme filet | `membership` | `rattachement_arriere_trace` | — |
| 23 | `44_absorption_ancienne.sql` | absorbées puis rétablies avant 1943 (Cherré) | `membership` | `absorption_trace` | — |
| 24 | `46_creation_serie.sql` | nées pendant la série, sans rattachement — filiation HAC | `membership` | `creation_serie_trace` | `hac` (a un défaut) |

### Contraintes d'ordre, mesurées en les violant

1. **`21` avant `22`/`23`.** `21` crée `commune_moderne`, et `23_cog_diag.sql`
   — que `load_cog.sh` joue en dernier — l'exige.
2. **`19` avant tout ce qui interroge `noms_geofla`** : `39`, `41`, `42`, `43`,
   `44`. Cette table était créée par `cartes/couverture_cantons_2025.py`, hors
   de la chaîne — une reconstruction complète échouait donc systématiquement
   dessus. **Une dépendance de la chaîne ne peut pas vivre hors de la chaîne.**
3. **`24` avant `27` et `28`** : ceux-ci rattachent les circonscriptions aux
   atomes-fractions que `24` vient de créer.
4. **Les correctifs datés en dernier**, parce qu'ils référencent les unités
   de `24`, `27` et `28`.

### Les deux pièges de rejeu

**Clé étrangère.** `24`, `27` et `28` suppriment leurs unités avant de les
recréer ; `38`, `41`, `42`, `15` les référencent. Voir « Qui dépend de qui »
dans `README.md`.

**Cascade silencieuse.** `24` supprime ses 732 atomes-fractions ; la cascade
emporte les circonscriptions que `27` et `28` y avaient posées, et **rien
n'échoue**. C'est à cela que sert `43_circo_fraction.sql`.

---

## 2. Les fichiers de diagnostic — lecture seule

Aucun n'écrit dans la base. Ils se lancent à la demande et ne font pas partie
de la reconstruction.

| fichier | ce qu'il répond | `-v` |
|---|---|---|
| `04_checks.sql` | rapport de recette après chargement | — |
| `08_controle_gay.sql` | **le contrôle indépendant** : cantons dissous de Victor Gay, IoU, conformité | `mapping` |
| `09_ecart_detail.sql` | d'où viennent les écarts avec Gay ; score du pari de `11` | — |
| `10_couverture.sql` | territoire non couvert, commune par commune | — |
| `12_conflit_successeur.sql` | désaccords résiduels sur les atomes `successeur` | `date_ref` |
| `13_double_comptage.sql` | surface comptée deux fois, par deux méthodes | `date_ref` |
| `14_cle_partage.sql` | pourquoi les deux méthodes de `13` diffèrent de 108 km² | `date_ref` |
| `23_cog_diag.sql` | le COG chargé concorde-t-il avec `commune_moderne` | — |
| `26_controle_ign.sql` | second contrôle géométrique, sur ADMIN EXPRESS | `date_ref` |
| `29_villes_a_verifier.sql` | villes dont le découpage cantonal est douteux | — |
| `30_stabilite_cantonale.sql` | stabilité d'un canton dans le temps | `dep` |
| `31_marseille_inventaire.sql` | état des lieux Marseille avant `32` | — |
| `33_diff_cantonal.sql` | différentiel cantonal entre deux dates | `dep` |
| `34_orphelines_1941.sql` | communes éteintes avant 1999, sans canton moderne | `dep` |
| `35_atomes_hors_departement.sql` | atomes dont le polygone est dans un autre département | — |
| `36_recette_annexe_vi.sql` | recette de l'annexe VI (découpages électoraux) | — |
| `45_controle_hac.sql` | **second contrôle indépendant** : HAC nomme la mère | `hac` |

**`45` ne modifie rien, et c'est délibéré.** Corriger la base d'après HAC lui
ferait perdre son indépendance — comme recopier Gay la ferait perdre au
contrôle géométrique.

---

## 3. `40_outremer.sql` — un espace de noms séparé

Seul fichier qui écrit dans des tables `om_*` (`om_atom`, `om_membership`,
`om_unit`…) et **ne touche à aucune table principale**. Les 129 communes
d'outre-mer y vivent à part, avec leurs propres fonctions `om_snapshot()`.

Conséquence à connaître : **aucune recette de la chaîne principale ne les
voit**, et le contrôle Gay non plus.

Collision de numéro : `40_outremer.sql` et `40_scission_circo.sql` portent le
même préfixe alors qu'ils n'ont rien à voir. À renuméroter.

---

## 4. Ce qui ne sert plus, ou mérite d'être revu

| fichier | verdict |
|---|---|
| `diag_marseille.sql` | **mort** — diagnostic ponctuel, remplacé par `31_marseille_inventaire.sql`. Aucun script ne l'appelle. |
| `23_cog_diag.sql` | **mal placé** — c'est un diagnostic, mais `load_cog.sh` le joue en dernier et son `RAISE EXCEPTION` fait échouer tout le chargement. Un diagnostic ne devrait pas bloquer une construction. |
| `43_circo_fraction.sql` | **conditionnel** — inutile dans une chaîne complète, indispensable après un rejeu isolé de `24`. |
| `38_decret_1982_ain.sql` | **sans trace** — seul fichier qui pose des rattachements sans pouvoir les défaire. C'est lui qui a bloqué la reconstruction de `24`. |
| `39_meurthe_1870.sql` | sans trace, mais idempotent par construction (`UPDATE ... WHERE dep = '99'`). Sans risque. |

### Trous à combler dans la chaîne elle-même

**Cinq fichiers échouent sur un message opaque** quand leur variable manque :

```
psql:sql/27_circo_2012.sql:76: error: :: Aucun fichier ou dossier de ce nom
```

`02`, `06`, `08`, `27`, `28` n'ont pas de valeur par défaut ni de message clair,
là où `40_outremer`, `45` et `46` portent un `\if :{?var}`. **Cette incohérence
a coûté une soirée** : la chaîne s'est arrêtée après `24` sans qu'on sache
pourquoi, et la base est restée sans aucune circonscription moderne.

**Il manque une recette d'ensemble.** `controle_gay.sh` ne couvre que
1870-1940. Rien ne compte les quatre couches d'un coup — c'est ce qui a permis
de croire trois fois la reconstruction terminée. À écrire, et à mettre en fin
de `rejouer_apres_rebuild.sh`.
