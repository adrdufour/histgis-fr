# Note de méthode — base espace-temps `histgis`, 1870-1940

Documentation interne. Rédigée pour deux lecteurs : moi dans six mois, et
celui qui reprendra le chantier. Elle dit ce qui a été fait, pourquoi, ce qui
n'a pas marché, et ce qu'on sait de faux.

C'est la référence stable du projet. `ETAT.md` donne l'état courant et les
suites, `JOURNAL.md` le récit chronologique des campagnes.

Dernière mise à jour : 9 août 2026, après le contrôle indépendant contre les
cantons dissous de Victor Gay.

---

## 1. Ce que contient la base

Une base PostgreSQL/PostGIS, schéma `histgis`, qui répond à une question :
**quelle était la carte des cantons et des circonscriptions législatives
françaises à telle date entre 1870 et 1940 ?** Géométries comprises.

```sql
SELECT unit_id, nom, geom FROM snapshot_geom('1885-06-01', 'canton');
```

| Table | Lignes | Contenu |
|---|---|---|
| `atom` | 38 442 | communes d'époque, dont 333 fractions |
| `atom_geom` | 38 442 | un polygone par atome, aucun trou |
| `unit` | 4 838 | 3 066 cantons, 1 772 circonscriptions |
| `unit_version` | 5 057 | noms datés |
| `membership` | 293 233 | rattachements `[valid_from, valid_to)` |
| `regime_electoral` | 71 | régime de scrutin, année par année |

---

## 2. Le choix d'architecture, et ce qu'il coûte

**Géométrie et attribution sont découplées.** La géométrie vit au niveau de
l'atome ; l'attribution vit dans `membership`, sous forme d'intervalles
temporels. Rien n'est pré-dissous : `snapshot_geom(date)` fait l'union à la
demande.

Ce n'est pas le choix le plus rapide à l'exécution. C'en est un qui permet de
changer de trame géométrique sans retoucher une seule attribution — ce qui
sera nécessaire quand ANR-COMMUNES lèvera son embargo (§ 8).

**L'atome** est la plus petite unité au rattachement stable : une commune
entière (`atom_id` = code Cassini), ou une fraction quand un pseudo-canton
recouvre plusieurs cantons réels (`atom_id = 'cassini#canton'`,
`fraction = true`).

**L'intégrité est déléguée à la base**, pas au code de chargement. Deux
contraintes `EXCLUDE USING gist` : un atome n'appartient qu'à une unité par
niveau à un instant donné ; deux versions d'une même unité ne se chevauchent
pas. C'est la base qui refuse les incohérences. Elles ont été validées sur les
vraies données, pas seulement en théorie.

---

## 3. Sources

### Attributions et nomenclatures — TRF-GIS

Victor Gay, *French Revolutionary Geographic Information System*, Harvard
Dataverse. Cantons : `10.7910/DVN/U85RSZ`. Circonscriptions :
`10.7910/DVN/L2LGDW`.

Nomenclatures annuelles `COG_COMMUNES_YYYY.txt` et
`COG_CANTONS_YYYY_MAPPING.tab`, de 1870 à 1940, soit 71 millésimes.
Extraction par `trfgis_extract.py` vers les CSV de `build/`.

### Trame géométrique — GEOFLA 2011

Édition `GEOFLA_1-1_SHP_LAMB93_FR-ED111`, 36 610 communes, Lambert-93
(EPSG:2154). C'est celle sur laquelle TRF-GIS a bâti ses nomenclatures : les
codes correspondent exactement. Elle est livrée dans le dépôt de reproduction
de TRF-GIS, ce qui évite de dépendre du catalogue IGN.

Récupération :

```bash
python3 trfgis_fetch_inspect.py fetch repro \
    --match '^COMMUNE\.(SHP|SHX|DBF|PRJ)$' --dest ./geofla --dry-run
```

### Mouvements de communes — INSEE

`v_mvt_commune_2025.csv`, remonte à 1943. Sert à retrouver la commune de 2011
qui a absorbé une commune d'époque disparue.

<https://www.insee.fr/fr/statistiques/fichier/8377162/v_mvt_commune_2025.csv>

### Fusions anciennes — HAC

`sources/geofla/repro/source_data/HAC/communal.tab`, dans le dépôt de reproduction
TRF-GIS. Documente les mouvements communaux depuis 1801. Ne contient **aucun
code INSEE** : le rattachement se fait par nom, avec ce que cela suppose
d'incertitude.

---

## 4. La chaîne, étape par étape

Tout se rejoue de zéro. Voir `sql/README.md` pour le détail des commandes.

```bash
# une seule fois : extraction et téléchargements
python3 trfgis_extract.py build sources/trfgis/communes/Nomenclatures \
    --out build --mapping sources/trfgis/cantons/Nomenclatures --geom-col insee
python3 trfgis_fetch_inspect.py fetch repro \
    --match '^COMMUNE\.(SHP|SHX|DBF|PRJ)$' --dest ./geofla
curl -O https://www.insee.fr/fr/statistiques/fichier/8377162/v_mvt_commune_2025.csv
createdb histgis

# à chaque reconstruction
cd sql && ./rebuild.sh          # load.sh → GEOFLA → 05 → 06 → 07 → 11 → 15
./controle_gay.sh               # 08 → 09 → 10, facultatif
```

`rebuild.sh` localise seul `COMMUNE.SHP` et `v_mvt_commune_*.csv`. Il est
destructif : `load.sh` fait `DROP SCHEMA histgis CASCADE`. Toute modification
de `geom_correspondance.csv` ou des CSV de `build/` impose de tout rejouer —
ces fichiers sont lus par `02_load.sql`, pas par `05`.

| Fichier | Rôle |
|---|---|
| `01_schema.sql` | tables, contraintes, index |
| `02_load.sql` | chargement des CSV, reconstruction des noms |
| `03_functions.sql` | `snapshot()`, `unit_nom()`, contrôles |
| `04_checks.sql` | recette (lecture seule) |
| `05_geom.sql` | jointure à GEOFLA, `snapshot_geom()` |
| `06_insee_mvt.sql` | rattrapage des communes disparues, par successeur |
| `07_reliquat.sql` | les 17 dernières, par HAC |
| `08` à `10` + `controle_gay.sh` | contrôle indépendant (§ 7) |
| `11_scission.sql` | correctif de couverture (§ 6.2 bis), réversible |
| `12_conflit_successeur.sql` | anatomie des désaccords résiduels (§ 7 bis) |
| `13_double_comptage.sql` | réconcilie les deux mesures du recouvrement (§ 6.1) |
| `14_cle_partage.sql` | attribue l'écart résiduel à la clé de regroupement (§ 6.1) |

### Le rattrapage des communes disparues

La jointure directe sur le code INSEE laisse **1 504 atomes sans polygone** :
leur code d'époque a disparu avant 2011, presque toujours par fusion (loi
Marcellin, 1971). Ils sont dispersés — un quart des cantons est amputé à une
date donnée — et concentrés dans les départements les plus touchés par la loi.

`06_insee_mvt.sql` rejoue les mouvements INSEE jusqu'au 1ᵉʳ janvier 2011 et
remonte les chaînes d'absorption (deux sauts au maximum) : **1 487 atomes
récupérés**. `07_reliquat.sql` traite les **17 derniers**, disparus avant 1943
donc hors du fichier INSEE, par les fusions documentées dans HAC.

Répartition finale dans `atom_geom` :

| `source` | Atomes | Fiabilité |
|---|---|---|
| `geofla` | 36 901 | jointure directe sur le code |
| `successeur` | 1 487 | mouvements INSEE, auditables ligne à ligne |
| `union_prefixe` | 27 | Lyon et Marseille, arrondissements réunis |
| `hac` | 11 | successeur unique, sans ambiguïté |
| `absorbee` | 10 | `geom_correspondance.csv`, saisi à la main |
| `hac_partage` | 6 | **choix arbitraire** : premier successeur retenu |
| `creation_arriere` | 58 | communes nées après 1940, rattachées au canton de leur mère (§ 6.2 quater) |
| `arrondissement` | 25 | arrondissements de Marseille et Lyon, période moderne seulement |

À quoi s'ajoutent, pour 1943-2012 : 15 atomes `successeur` posés par `21` pour
des codes qui coexistaient avec l'atome qu'ils empruntaient, et 4 atomes
`geofla` pour Tende, La Brigue, Chisa et Butry-sur-Oise.

---

## 5. Décisions, et pourquoi

**`--geom-col insee`, pas `com_act`.** `trfgis_extract.py` utilisait
`CLE_GEOM = "com_act"` pour le rattachement à GEOFLA. Or le codebook TRF-GIS
définit `com_act` comme un **statut** — 1 actuelle, 2 ancienne post-1943,
3 ancienne pré-1943 — et non comme un code commune. Le build a été relancé.
Le loader accepte les deux formats et range la valeur dans la bonne colonne.

**`-a_srs` et non `-t_srs`.** Les données SONT en Lambert-93 : on déclare la
projection, on ne reprojette pas.

**La correspondance Cassini → INSEE n'est pas bijective.** 37 648 codes
Cassini pour 37 584 codes INSEE en 1870 : plusieurs communes historiques
partagent un code actuel. Conséquence directe en § 6.

### Ce qui n'a pas marché, pour ne pas y revenir

- **`ID_GEOFLA.tab`** n'est que la table attributaire du shapefile. Aucune
  information supplémentaire.
- **`insee_former.do`** n'est que de l'harmonisation de noms.
- **HAC** ne contient aucun code INSEE. Rattachement par nom obligatoire.
- **L'appariement par nom contre le COG 2005**, comme le fait Gay, a été
  abandonné au profit des mouvements INSEE : traçable ligne à ligne, et sans
  arbitrage sur les homonymes.

---

## 6. Les quatre limites connues

Toutes chiffrées par le contrôle du § 7. À mentionner en légende de toute
carte publiée.

### 6.1 Communes revendiquées par plusieurs cantons

**218 communes au 1ᵉʳ juin 1885, soit 0,6 %** — donc autant de zones où deux
cantons se recouvrent. Mesure en surface : **3 945 km² comptés deux fois en
1870**, 4 036 en 1940. La somme des surfaces cantonales vaut 546 221 km² pour
une union de 542 276.

Deux causes : les communes historiques fusionnées depuis partagent un code
INSEE ; les communes éclatées entre cantons n'ont pas de géométrie propre.

C'est inhérent à la trame — une géographie de 2011 ne découpe pas plus fin
qu'elle-même — et TRF-GIS a exactement la même limite au même endroit.
`atom_geom.partagee` marque les cas, `check_geom_overlap(date)` les chiffre.
Invisible à l'échelle départementale, visible au zoom.

**Le chiffre dépend du niveau où on le lit, et il faut le dire.** `13_double_
comptage.sql` le mesure aux deux, par deux méthodes indépendantes — union de
polygones d'un côté, comptage des unités par groupe de partage de l'autre :

| | géométrie | nomenclature |
|---|---|---|
| entre cantons réels | 12 930 | 12 822 |
| après repliement en pseudo-cantons | 3 945 | 3 837 |
| absorbé par le repliement | 8 985 | 8 985 |

Le repliement absorbe **8 985 km², soit 70 %**, et n'absorbe rien d'autre : les
105 groupes qui n'y sont pas soumis gardent leurs 3 296 km² intacts. C'est
attendu — le repliement réunit précisément les cantons qui se partagent une
commune. **C'est donc 3 945 km² qu'il faut citer**, le niveau auquel le contrôle
opère et auquel les deux sources sont commensurables ; **12 930** est le même
phénomène vu avant repliement (2,36 % du territoire, sur 8 756 km² de polygones
éclatés en 236 groupes).

Contre-intuitif et à retenir : le résidu n'est **pas** urbain. Sur les 3 837 km²
mesurés, 3 296 viennent de communes rurales partagées entre deux cantons
ordinaires, contre 541 de restes urbains. Le repliement règle le cas des villes
en entier.

Réserve : cette ventilation a été établie avec l'ancienne clé `code_2011`, avant
le correctif du § suivant. Les 108 km² restitués depuis n'y sont pas répartis —
Lyon (47,85) relève de l'urbain, les 60,18 restants sont à classer. L'ordre de
grandeur et la conclusion ne bougent pas ; rejouer `13` § 3 sur `cle_geom` les
préciserait.

Les deux méthodes divergeaient de 108 km² exactement aux deux niveaux.
`14_cle_partage.sql` a attribué l'écart : **il vient de la clé de regroupement,
pas de la mesure**. Regroupés par l'empreinte binaire du polygone
`md5(ST_AsEWKB(geom))` — la seule clé qui ne suppose rien — les comptes par
nomenclature reproduisent exactement les 12 930 et 3 945 géométriques.

En cause, cinq groupes portés par des atomes rattachés par nom, dont aucune
colonne ne dit quel polygone ils portent : Lyon 47,85 km² (`hac` mêlé à
`union_prefixe`), puis 2A325 19,35, 51606 16,78, 60606 14,73, 08227 9,32 —
somme **108,03**. Chacun ajoutant exactement une unité, sa surface compte une
fois de plus à chaque niveau : d'où la constance du décalage.

À retenir pour tout futur calcul de recouvrement : **grouper par la géométrie,
jamais par un code**. `code_2011` est une reconstruction, l'empreinte est un
fait. L'hypothèse concurrente — des atomes `geofla` recevant à tort la clé de
leur successeur — a été testée et écartée : un seul atome est concerné.

**Le correctif est porté dans `12`**, qui groupe désormais sur
`md5(ST_AsEWKB(geom))` et affiche 36 489 groupes, 236 éclatés, 12 930 km². Deux
bénéfices annexes : `max(km2_polygone)` cesse d'être une approximation, tous les
membres d'un groupe ayant la même géométrie par construction ; et une colonne
`codes_multiples` signale les 15 polygones que l'ancienne clé séparait — dont 5
seulement, ceux qui sont aussi éclatés entre cantons, portaient les 108 km².
`13` conserve délibérément l'ancienne clé : c'est lui qui documente l'écart.

Contrôle croisé : le double comptage chez Gay est **nul** — 548 202 km² en somme
comme en union. Le phénomène est chez nous, pas dans la comparaison. Et l'écart
entre son union et la nôtre, 811 km², vaut exactement le trou de couverture
du § 6.2 : deux chemins indépendants vers le même nombre.

### 6.2 Trame incomplète : les communes créées après la date

**Corrigé pour l'essentiel** — 5 926 km² non couverts en 1870 ramenés à 800.
Ce qui suit décrit le défaut, le § 6.2 bis le correctif et son coût.

Découvert par le contrôle indépendant, invisible aux recettes internes faute de
point de comparaison.

La correspondance vers GEOFLA est plusieurs-vers-un. Quand une commune
d'époque s'est **scindée** depuis, un seul des codes issus de la scission est
retenu et le territoire de l'autre n'est réclamé par aucun atome. `06` traite
les fusions ; l'opération symétrique n'existe pas.

L'écart est **à sens unique** : `km2_nous_seul` vaut 0,0 dans les 89
départements de 1870 comme dans les 90 de 1940. Nous ne revendiquons jamais un
territoire de trop — signature d'un trou de couverture et non d'une erreur
d'attribution.

494 communes concernées en 1870, 69 en 1940. Les plus grandes :
Saint-Martin-de-Crau (216 km², détachée d'Arles en 1925), Port-Saint-Louis-du-
Rhône (1904), La Londe-les-Maures (1901), Le Grau-du-Roi (1879), Le Lavandou
(1913). En 1940, 67 des 69 sont des créations documentées par l'INSEE ; en
1870, 422 des 494 sont antérieures à 1943 et échappent au fichier.

### 6.2 bis Le correctif, et ce qu'il coûte

`sql/11_scission.sql`. Il repose sur un fait que le § 7 a permis d'établir :
l'essentiel de ces communes est né **entre 1870 et 1940**, donc TRF-GIS les
suit déjà et leur atome existe, avec un `membership` qui commence à leur année
de création. Il suffit de prolonger ce rattachement vers l'arrière. HAC n'a pas
été nécessaire.

Le pari : *une commune nouvelle reste dans le canton de sa mère.* 505 atomes
candidats au niveau canton, 50 écartés comme recodages, le reste prolongé sous
réserve des garde-fous.

Résultat à 1870, mesuré par le contrôle Gay :

| | avant | après |
|---|---|---|
| tracés identiques | 82,7 % | **92,8 %** |
| IoU moyen | 0,9826 | **0,9919** |
| pseudo-cantons sous 0,90 d'IoU | 171 | 79 |
| surface commune | 98,21 % | 99,13 % |
| territoire non couvert | 5 926 km² | 811 km² |
| communes non réclamées | 494 | 98 |

**1870 rejoint 1940** — 92,8 % contre 93,6 %, IoU 0,9919 contre 0,9924 — alors
que 1940 n'a gagné que ce que lui a rendu le correctif Marseille, n'ayant
jamais souffert du défaut de scission. C'est la preuve la plus nette que
l'anomalie corrigée était bien celle-là.

Le coût : **quatre paris perdus sur 414**, soit 99,0 % de réussite. Trois sont
en `geofla` non partagé, ligne qui était jusque-là à zéro.

| atome | INSEE | apparu | chez nous | chez Gay | km² |
|---|---|---|---|---|---|
| 37390 | 08447 | 1872 | Mézières | Charleville | 32,69 |
| 36437 | 77454 | 1874 | Donnemarie-en-Montois | Nangis | 10,60 |
| 17501 | 56086 | 1891 | Quiberon | Belle-Île | 3,25 |
| 17191 | 56085 | 1891 | Quiberon | Belle-Île | 2,25 |

4 982 km² rendus pour 49 km² mal rattachés. Le correctif est conservé, et reste
réversible par `scission_trace`.

Ces quatre-là restent en l'état, **délibérément**. Les corriger en recopiant les
réponses de Gay ferait perdre au contrôle son indépendance, donc sa valeur. Ils
se tranchent sur pièces historiques : Houat et Hœdic (56085, 56086)
relevaient-ils du canton de Quiberon ou de Belle-Île en 1870 ? La question a une
réponse dans les archives, pas dans notre étalon.

### 6.2 ter Le quatrième garde-fou, et son prix

Le premier passage perdait sept paris. Trois — 57369 Cattenom, 57474 Longuyon,
68048 Habsheim — étaient apparus en 1921 et 1928, donc après le retour de
l'Alsace-Moselle, et relevaient du même défaut : **TRF-GIS réutilise les codes
de canton de part et d'autre de la rupture de 1871**. Le 5705 de 1870 appartient
à la numérotation de la Meurthe, le 5705 de 1921 à celle de la Moselle
reconstituée. Deux cantons différents sous une même clé — que le modèle traite
comme une unité pérenne unique. C'est une limite du schéma, pas du correctif :
`unit_id` suppose une identité continue que les données ne garantissent pas.

Les garde-fous 1 et 2 ne voyaient rien, le canton d'accueil ayant des membres en
1870 comme en 1921. D'où le **garde-fou 4** : ne retenir que la plage
d'existence *continue* du canton aboutissant à la date d'apparition.

| | sans | avec |
|---|---|---|
| atomes prolongés | 441 | 414 |
| paris perdus | 7 | **4** |
| dont `geofla` non partagé | 4 | **3** |
| territoire non couvert (1870) | 800 km² | 944 km² |
| IoU moyen | 0,99196 | 0,99173 |

Il retire 27 prolongements pour en supprimer 3 faux : les 24 autres coïncidaient
avec Gay. Mais sur ce terrain l'accord ne prouve rien — pour une commune créée
sous administration allemande, Gay a dû extrapoler comme nous, et deux
extrapolations qui coïncident restent deux extrapolations. Les 144 km² rendus au
non-couvert sont concentrés en Moselle (23 communes) et sont désormais déclarés
inconnus plutôt que rattachés au hasard.

Ce garde-fou se justifie par un fait relatif aux données, pas par le verdict de
Gay — distinction qui n'est pas cosmétique, puisqu'elle seule préserve
l'indépendance du contrôle. Choix assumé, et révocable : retirer la clause
`WHERE retenu` de `scission_periode` restaure l'état précédent.

### 6.2 quater Les communes nées après la série

`11` ne pouvait rien pour les communes nées **après** 1940 : TRF-GIS ne les a
jamais vues, elles n'ont aucun atome à prolonger. `15_creation_arriere.sql` les
traite à partir des mouvements INSEE (modalités 20 et 21), qui documentent leur
création et nomment la commune mère.

Conception : plutôt qu'élargir la géométrie de l'atome mère — ce qui mêlerait
géométrie et attribution —, on crée un **atome-fraction** portant le polygone de
la fille et on lui recopie l'appartenance de la mère, année par année, aux deux
niveaux. `cassini` synthétique préfixé `N`, `fraction = true`,
`source = 'creation_arriere'` : rien ne doit le confondre avec un atome TRF-GIS.
Une année n'est comblée que si toutes les mères candidates s'accordent sur la
même unité ; sinon elle reste vide.

| | avant | après |
|---|---|---|
| non couvert 1870 | 811 km² | **238 km²** |
| non couvert 1940 | 610 km² | **32 km²** |
| tracés identiques 1870 | 92,8 % | **94,49 %** |
| tracés identiques 1940 | 93,63 % | **95,33 %** |
| double comptage | 3 945 / 4 036 | inchangé |

58 atomes, 577 km², 438 intervalles. Le rattrapage se place honnêtement dans la
hiérarchie : **5,26 % de désaccord avec Gay**, entre `geofla` (0,01 %) et
`successeur` (9,3 %). Le total d'atomes mal placés passe de 148 à 151.

**Deux défauts du premier passage, corrigés.** Le test « commune sans atome »
comparait des empreintes de polygones entiers : les arrondissements de Marseille
et de Lyon en ressortaient à tort, leur territoire étant porté par un atome
`union_prefixe` dont le polygone est leur union. Ils n'ont pas nui — leur mère
`13055` n'existe pas dans GEOFLA — mais **par chance, pas par conception** : la
recette d'alors, fondée sur l'égalité de polygone, n'aurait pas vu le double
comptage. Elle a été refaite sur l'inclusion d'un point intérieur.

Et l'appariement des mères par empreinte binaire était trop strict :
`ST_UnaryUnion` peut renormaliser une représentation sans changer la géométrie,
ce qui faisait perdre Val-de-Reuil et Marcheprime. Corrigé par `ST_Equals` avec
repli sur `insee_geofla` — 57 mères sur 58 sont trouvées par les deux voies, une
seule par le code : le repli complète l'empreinte, il ne la remplace pas.

Le correctif a coûté ce qu'il a rapporté, et il faut le dire : 55 km² de
couverture gagnés, un atome mal placé de plus, le taux de désaccord de la source
passant de 3,70 à 5,26 %. **Les cas que la première version ratait étaient les
plus difficiles.**

Nuance à porter au crédit de la leçon de `14` : **l'empreinte binaire est la
bonne clé pour constater qu'un polygone est partagé, pas pour tester qu'il est le
même.** Identité de représentation et identité géométrique sont deux choses.

Ce qui reste non couvert change de nature : 37 des 39 communes de 1870 sont
créées avant 1943 et échappent au fichier INSEE. La suite passe par HAC. S'y
ajoutent Kuntzig et Stuckange (8,6 km²), documentées mais dont la ligne INSEE
n'a pas de `com_av` exploitable.

### 6.2 quinquies Marseille et Lyon n'ont qu'un canton, 1999-2012

Sur la période moderne, la base ne représente **pas** les 22 cantons de
Marseille ni les 13 de Lyon : chaque ville forme un canton unique, auquel se
rattachent ses 16 et ses 9 arrondissements.

Ce n'est pas un choix de commodité. Le COG rattache ces cantons à la commune
entière (`typct = 4`, `cheflieu` valant 13055 ou 69123) sans jamais dire quel
arrondissement relève duquel. Et **GEOFLA fait exactement la même chose** : sa
couche CANTON ne compte qu'un canton par ville, codé `CODE_CANT = '99'`, comme
pour toutes les communes partagées — Villeurbanne 98, Vénissieux 97, Aix 97,
Arles 98. D'où 3 708 cantons chez l'IGN contre 3 876 au COG.

La cause est celle du § 6.1 : une trame communale ne sait pas couper une
commune. L'IGN bute au même endroit que Gay en 1870. Le pseudo-canton est donc
la convention du domaine, pas un pis-aller.

Le rattachement a été établi géométriquement — chaque arrondissement affecté au
canton GEOFLA contenant son point intérieur — et non supposé : les 16
marseillais tombent dans `1399`, les 9 lyonnais dans `6999`.

Conséquence à citer en légende de toute carte cantonale postérieure à 1999 :
le nombre de cantons de ces villes a évolué (Marseille de 22 à 25 en 2005, Lyon
de 13 à 14 en 2002) sans que le pseudo-canton bouge. La simplification masque
une évolution réelle sans fausser le territoire.

### 6.3 Six atomes au rattachement arbitraire

`source = 'hac_partage'` : commune répartie entre plusieurs successeurs, le
premier nommé a été retenu. Le contrôle en invalide **3 sur 6** — une fois sur
deux, comme le hasard le laissait craindre. Liste dans `07_reliquat.sql`,
révocable.

**Nuance apportée par `14`, et vérifiée.** Les cinq atomes `hac`/`hac_partage`
en désaccord sont `28580` (69232, canton 6910), `37694` (2A325, 2053), `17193`
(08227, 0828), `35396` (60606, 6020) et `39369` (51606, 5125) — exactement les
cinq que `14` § 5 place sur un polygone réclamé par plusieurs cantons. La
correspondance est totale, atome par atome et canton par canton.

Leur désaccord ne **démontre** donc plus rien contre l'attribution : il
s'explique par l'indivisibilité de la trame, au même titre que les 140 autres.
Le « 3 sur 6 » ne mesure pas l'échec du choix arbitraire, il mesure la trame.

Ce qui ne l'innocente pas pour autant — le rattachement par nom reste arbitraire
et révocable, simplement le contrôle Gay ne peut plus servir à le condamner.
Sur ces six-là, il ne tranche pas.

### 6.4 Cent trente-deux circonscriptions sans nom

Citées par le membership mais absentes des nomenclatures TRF-GIS — Paris
`U7580`/`U7581`, Bouches-du-Rhône `U1381` — pour 134 rattachements. Ce sont
des pseudo-circonscriptions d'arrondissement urbain, écartées à l'extraction.
Créées avec `provisoire = true` et `nom IS NULL` pour ne pas perdre
l'information. À reprendre côté extracteur si leurs noms sont voulus.

### Une note, pas une limite

`atom.com_act` est vide depuis le passage à `--geom-col insee` : l'extracteur
n'écrit qu'une colonne. Le statut est reconstituable depuis les
`COG_COMMUNES_YYYY.txt` en cas de besoin.

---

## 7. Le contrôle indépendant

### Principe

TRF-GIS livre, pour 1870 et 1940 seulement, les cantons **déjà dissous** par
Victor Gay (`sources/trfgis/cantons/Shapefiles/CANTONS_YYYY.zip`). Ces polygones ne
passent par aucune ligne de notre code. Les comparer à `snapshot_geom()` teste
la chaîne entière — extraction, attributions, rattrapages, dissolution — contre
une source qui ne dépend pas de nous.

```bash
cd sql && ./controle_gay.sh     # exige gdal-bin
```

Sorties : `rapport_controle_gay.txt` et `controle_gay.gpkg` (cinq couches, à
ouvrir dans QGIS).

### Le piège, et il est double

Les shapefiles de Gay sont découpés en **pseudo-cantons**, pas en cantons
réels. Montluçon-Est et Montluçon-Ouest ne forment qu'un ensemble, parce que la
trame communale ne sait pas couper une commune en deux. Gay bute sur la même
limite que nous, au même endroit : c'est donc à ce niveau, et là seulement, que
les deux côtés sont commensurables.

Second piège, plus vicieux : chez Gay un ensemble urbain n'est pas **un**
polygone mais plusieurs. Le polygone `pct_type = 'Pseudo canton'` ne porte que
la commune indivise — la ville — et les communes entières de chaque canton
restent dans des polygones séparés, sous le code du canton réel. Moulins :
`0381` = les 8,5 km² de la ville, `0323` et `0324` = les communes rurales.
Trois polygones pour deux cantons.

Un premier passage n'avait replié que notre côté : il comparait deux cantons
entiers à un centre-ville. Symptômes — 239 clés orphelines, 22 689 km²
manquants, les 25 pires écarts tous chefs-lieux. Le repliement s'applique aux
**deux** côtés.

### Résultats

Appariement parfait dans les deux sens, zéro collision de codes.

| | 1870 au départ | 1870 après correctifs | 1940 |
|---|---|---|---|
| pseudo-cantons comparés | 2 775 | 2 775 | 2 824 |
| tracés identiques (IoU ≥ 0,999) | 82,7 % | **92,8 %** | 93,6 % |
| IoU moyen | 0,9826 | **0,9919** | 0,9924 |
| pseudo-cantons sous 0,90 | 171 | 79 | 78 |
| surface commune | 98,21 % | 99,13 % | 99,16 % |
| territoire non couvert | 5 926 km² | 811 km² | 610 km² |

L'écart entre 1870 et 1940 était le symptôme du § 6.2, et il a disparu avec
lui : 1940, qui n'en souffrait pas, n'a gagné que ce que le correctif Marseille
lui a rendu. Les deux dates sont maintenant au même niveau.

Restreint aux cantons ruraux — seuls cas sans repliement d'aucun côté, donc où
un écart met directement en cause nos attributions — les chiffres suivent. La
structure de la comparaison n'est pas en cause.

### Le résultat qui compte

Décomposition atome par atome : pour chacun, le pseudo-canton où Gay le range,
croisé avec `atom_geom.source` et `partagee`.

Chiffres du **premier passage**, avant le correctif de scission (§ 6.2 bis) :
c'est celui-là qui juge la chaîne telle qu'elle a été construite.

| Source | Atomes (1870) | En désaccord | |
|---|---|---|---|
| `geofla` non partagé | 34 894 | **0** | 0,00 % |
| `geofla` partagé | 1 420 | 2 | 0,14 % |
| `successeur` | 1 466 | 137 | 9,35 % |
| `hac` | 11 | 2 | 18,2 % |
| `hac_partage` | 6 | 3 | 50,0 % |
| `union_prefixe`, `absorbee` | 24 | 0 | 0,00 % |

**Aucun désaccord parmi les 34 894 atomes dont la géométrie vient directement
de GEOFLA.** Pas un seul, ni en 1870 ni en 1940 (35 318 atomes). Les 144
atomes mal placés — 0,38 % — tombent tous dans les catégories reconstruites.

Là où les données sont directes, elles sont exactes. Là où elles sont
reconstruites, elles se trompent dans les proportions annoncées : le rattrapage
par successeur, la reconstitution la plus incertaine, se révèle juste à 90,7 %.

C'est la validation recherchée, et elle confirme les limites du § 6 au lieu
d'en révéler d'inconnues — à une exception près, § 6.2, que seul un point de
comparaison extérieur pouvait faire apparaître.

Après correctifs, la ligne `geofla` non partagé compte **3 désaccords sur
35 283** et le total s'établit à 148 sur 38 235 atomes, soit 0,39 %. C'est le
prix de 5 115 km² de couverture rendue, détaillé au § 6.2 bis.

### Vérification arithmétique du déficit de couverture

Le contrôle mesure 5 926 km² manquants en 1870. Le recensement des communes
non couvertes en trouve 6 197, dont **Tende et La Brigue** (271,1 km²),
italiennes jusqu'au traité de Paris de 1947 et donc absentes de la couverture
de Gay elle-même. Reste 5 926 contre 5 926 attendus ; 743 contre 744 en 1940.
Le déficit est intégralement expliqué.

### Un bogue trouvé au passage : le préfixe de Marseille

`geom_correspondance.csv` donnait `1320` comme préfixe pour Marseille. Le
`LIKE '1320%'` de `05_geom.sql` ne prenait que les arrondissements 13201 à
13209 et perdait les 10ᵉ à 16ᵉ. Corrigé en `132` — sans risque, les communes des
Bouches-du-Rhône s'arrêtant à 13119.

GEOFLA 2011 ne contient **aucun code 13055** : Marseille n'y existe que sous ses
seize arrondissements, pour 235,22 km². Le préfixe amputé n'en captait que
101,57. Le pseudo-canton se décompose exactement :

| | avec `1320` | avec `132` | chez Gay |
|---|---|---|---|
| Marseille | 101,57 | 235,22 | 235,22 |
| Allauch | 50,46 | 50,46 | 50,46 |
| Plan-de-Cuques | — | — | 8,57 |
| **total** | **152,03** | **285,69** | **294,25** |

IoU du pseudo-canton : 0,517 → **0,971**. Le reliquat est Plan-de-Cuques,
commune créée après 1870, qui relève du § 6.2. Lyon est sain : préfixe `6938`,
neuf arrondissements sur neuf.

**Ce que ce bogue enseigne.** Un préfixe trop long n'échoue pas, il ampute en
silence : l'atome a bien une géométrie, `check_geom()` ne signale rien, tous les
contrôles internes passent. Il a fallu une source extérieure pour le voir.
`05_geom.sql` affiche désormais à chaque chargement ce que chaque préfixe capte,
avec le compte attendu — Paris 20, Marseille 16, Lyon 9.

C'est l'argument le plus concret en faveur du contrôle indépendant : les
recettes internes valident la cohérence, pas l'exactitude.

### 7 bis. Anatomie des désaccords résiduels

`12_conflit_successeur.sql` répond à la question que le § 7 laisse ouverte :
les 148 atomes mal placés accusent-ils nos attributions ?

Non. Le désaccord ne suit pas la source de la géométrie, il suit le **partage
de polygone** :

| situation | atomes | en désaccord | |
|---|---|---|---|
| seul sur son polygone | 35 309 | 8 | 0,02 % |
| partage, même canton | 2 273 | 0 | 0,00 % |
| partage, cantons différents | 653 | 140 | **21,44 %** |

Le mécanisme est mécanique. Une commune A de 1870 absorbée depuis par B n'a plus
de polygone propre en 2011 : `06` lui donne celui de B, c'est-à-dire A ∪ B. Mais
B existe aussi comme atome et reçoit le même polygone par jointure directe. Deux
atomes, un polygone, chacun trop grand de la part de l'autre. Tant que A et B
sont dans le même canton, l'union les recolle et rien ne paraît — d'où la
deuxième ligne, à zéro.

`desaccord_hors_conflit`, la seule colonne qui accuserait les attributions, vaut
**zéro** pour les 138 atomes `successeur`. Les 8 désaccords hors conflit sont
tous déjà nommés : 3 `hac_partage` (§ 6.3), 2 `hac`, et 3 `geofla` qui sont
exactement les trois paris perdus du § 6.2 bis. **Aucun désaccord inexpliqué ne
subsiste dans la base.**

Et ce chiffre de 8 est encore trop généreux. `14` (§ 6.1) montre que les cinq
atomes `hac`/`hac_partage` sont eux aussi sur des polygones partagés, invisibles
à la clé de `12` : correctement groupés, ils sortent du « hors conflit ». La
vérification est faite, les cinq `atom_id` coïncident exactement.

**Le compte final est donc de 3 désaccords hors conflit sur 38 235 atomes**, et
ce sont les trois paris perdus du § 6.2 bis — conservés délibérément. Aucun
désaccord avec Gay ne subsiste qui ne soit ni un artefact de trame, ni un choix
assumé et tracé.

Les trois départements où nous revendiquons du territoire de trop tiennent
chacun à **un seul polygone partagé** : Haute-Marne 130,1 km² (groupe 70122),
Deux-Sèvres 88,1 (49099), Marne 59,0 (52182). La Haute-Marne est le cas d'école :
la commune 52210, haut-marnaise en 1870, a été absorbée depuis par une commune
de Haute-Saône ; nous donnons le polygone au canton haut-marnais, Gay au canton
haut-saônois, et aucun des deux n'a tort dans son cadre.

Conclusion opératoire : **il n'y a rien à corriger dans les attributions.** Le
correctif ne peut pas venir de GEOFLA et viendra d'ANR-COMMUNES (§ 9).

### 7 ter. Le contrôle indépendant de 1999-2012

La couche CANTON de GEOFLA joue pour la période moderne le rôle des cantons
dissous de Gay pour l'ancienne. `26_controle_ign.sql` la compare à
`snapshot_geom('2012-06-01', 'canton')`.

**Une réserve d'emblée** : ce contrôle est plus faible que celui de Gay. Ses
cantons étaient bâtis sur GEOFLA ED111, la trame même de nos communes ; la
couche CANTON disponible est l'édition ED141, de 2014. Un écart de tracé peut
donc venir d'une reprise de limites, et seuls les écarts d'attribution — qui
portent sur des communes entières — sont concluants.

**Le repliement, et le piège où le premier jet est tombé.** GEOFLA fusionne les
cantons d'une commune partagée en une entité codée 9x, qui **ne porte que la
commune indivise** : les communes entières restent sous le code du canton réel.
C'est trait pour trait la structure des `pct_type = 'Pseudo canton'` de Gay
(§ 7). Ne replier qu'un côté donnait 216 entités orphelines, 17 613 km²
d'excédent et un IoU de 0,917. Le premier jet déduisait de surcroît le
repliement de l'affectation géométrique des atomes, c'est-à-dire de la réponse
à tester.

Le repliement correct se déduit de **notre** nomenclature : deux cantons
appartiennent au même pseudo-canton s'ils se partagent une commune, et les
composantes connexes donnent les groupes. Côté IGN, les entités dont le code
est l'un des nôtres se replient par identité — la nomenclature est la même
(§ 6.2 quinquies) ; les entités 9x sont rattachées par la commune qu'elles
portent.

**Résultats.**

| | |
|---|---|
| pseudo-cantons comparés | 3 162 |
| appariement | parfait dans les deux sens |
| somme des surfaces | 548 463 km² contre 548 488 — écart 26 km², 0,005 % |
| IoU moyen | 0,9646 |
| sous 0,90 | 86 |

| source | atomes | en désaccord |
|---|---|---|
| `geofla` non partagé | 35 161 | **10** (0,03 %) |
| `geofla` partagé | 1 318 | 1 |
| `fraction_cog` | 730 | **0** |
| `arrondissement` | 25 | **0** |
| `successeur`, `creation_arriere` | 63 | **0** |

**11 atomes sur 37 297.** Les attributions de 1999-2012 sont donc justes, comme
celles de 1870-1940 le sont au § 7. L'écart d'IoU s'explique par la différence
d'édition : les pires cas sont des cantons urbains de moins de 3 km² en petite
couronne, où quelques mètres de reprise pèsent lourd en proportion.

### Curiosités documentées

Le **département 99** apparaît en 1870, 25 pseudo-cantons : Albestroff,
Baccarat, Bayon, Blâmont, Château-Salins. C'est la Meurthe d'avant 1871,
disparue au partage. Présente des deux côtés, sans conséquence sur le contrôle.

Les **1 690 atomes** dont la chronologie est trouée de 1871 à 1919 exactement
sont l'Alsace-Moselle. C'est une validation, pas une anomalie.

---

## 8. Ce qui est vérifié

Les effectifs recoupent l'histoire à chaque date testée.

| Date | Départements | Cantons | Circonscriptions |
|---|---|---|---|
| 1870 | 89 | 2 948 | 89 (scrutin de liste) |
| 1876 | 87 | 2 862 | 535 (uninominal) |
| 1885 | 87 | 2 867 | 87 (retour à la liste) |
| 1914 | 87 | 2 918 | 580 |
| 1928 | 90 | 3 024 | 590 |
| 1940 | 90 | 3 028 | 595 |

La perte puis le retour de l'Alsace-Moselle apparaissent au bon endroit :
89 → 87 → 90 départements. Les bascules liste/uninominal tombent aux bonnes
années (1876, 1885, 1889…).

Zéro chevauchement, zéro orphelin, couverture canton/circonscription complète,
zéro géométrie invalide. Rapport dans `rapport_chargement.txt`.

---

## 9. Suites

1. **Vérifier la propagation entre les deux dossiers.** Le correctif Marseille
   est resté sans effet un temps parce que `geom_correspondance.csv` n'arrivait
   pas jusqu'à la machine qui exécute `psql`, alors que les `.sql` y arrivaient.
   Si seuls les `.sql` circulent, `build/` et les notes peuvent être périmés
   d'un côté sans que rien ne le signale.

2. **Reprendre les quatre paris perdus** du § 6.2 bis, nommés par
   `09_ecart_detail.sql` § 8. Chacun est une commune qui a changé de canton en
   naissant : soit on corrige son rattachement à la main sur pièces
   historiques, soit on retire la ligne de `scission_trace`.

3. **Les communes nées après 1940** — 811 km² en 1870, 610 en 1940, Tende et La
   Brigue exclues (§ 7). Elles n'ont aucun atome. Il faudrait rejouer
   `insee_mvt` en sens inverse (`mod` 20 et 21) pour identifier leur mère, ou
   passer par HAC (`sources/geofla/repro/source_data/HAC/communal.tab`).

4. ~~Reprendre les 138 atomes `successeur`~~ — **clos par `12`** (§ 7 bis) : le
   `membership` est sain, le défaut est dans la trame, il n'y a rien à
   corriger. Restent les 3 `hac_partage` invalidés et les 2 `hac`, cinq lignes
   révocables.

4 bis. ~~Attribuer les 108 km² d'écart~~ — **clos par `14`** (§ 6.1) : artefact
   de clé de regroupement, aucune attribution en cause. Reste à porter le
   correctif dans `12` : grouper par `md5(ST_AsEWKB(geom))` et non par
   `code_2011`.

5. **Période 1943-2012.** Communes par l'API INSEE Métadonnées, cantons par les
   COG en ligne à partir de 1999, circonscriptions par Légifrance. Le trou
   **1943-1999** sur les cantons reste non résolu : pistes Cassini/EHESS ou
   volumes COG imprimés.

6. **ANR-COMMUNES**, embargo levé le 1ᵉʳ septembre 2026, Zenodo
   `10.5281/zenodo.3727274`. Trame communale historique : réglerait § 6.1 et
   § 6.2 à la racine, et c'est précisément ce que l'architecture découplée
   permet d'absorber sans retoucher aux attributions.

7. **Extension avant 1870**, avec Gaudillère (*Atlas historique des
   circonscriptions électorales françaises*, 1995) comme source principale.
