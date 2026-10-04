# Note de méthode — base espace-temps `histgis`

Documentation interne, rédigée pour deux lecteurs : moi dans six mois, et celui
qui reprendra le chantier. Elle dit ce qui a été fait, pourquoi, ce qui n'a pas
marché, et ce qu'on sait de faux.

C'est la **référence stable** du projet. `ETAT.md` donne l'état courant de chaque
couche, `RESTE_A_FAIRE.md` la file d'attente, `JOURNAL.md` le récit
chronologique des campagnes.

**Dernière mise à jour : 2 septembre 2026.** Le document est en deux parties :
la **partie I** décrit la base — architecture, sources, chaîne, limites,
contrôles ; la **partie II** rassemble les règles de travail que le chantier a
payées pour apprendre. La partie II est indexée au § 10.

> Condensé le 2 septembre 2026. Le titre annonçait « 1870-1940 » alors que la
> base couvre 1870-2012 et remonte à 1815 pour Paris ; les effectifs dataient du
> 9 août ; les limites étaient annoncées comme quatre alors que le dépôt en
> citait sept ; et les règles de la partie II s'étaient accumulées sans ordre.
> Huit règles énoncées dans `JOURNAL.md` depuis le 28 août et jamais reportées
> ici y ont été ajoutées.

---

# Partie I — la base

## 1. Ce que contient la base

Une base PostgreSQL/PostGIS, schéma `histgis`, EPSG:2154 partout, qui répond à
une question : **quelle était la carte des cantons et des circonscriptions
législatives françaises à telle date ?** Géométries comprises.

Périmètre : **1870-2012** en métropole, **1815** pour Paris, l'outre-mer dans un
espace séparé (`om_*`).

```sql
SELECT unit_id, nom, geom FROM snapshot_geom('1885-06-01', 'canton');
SELECT unit_id, nom, geom FROM snapshot_geom_anr('1885-06-01', 'canton');
```

| Table | Contenu |
|---|---|
| `atom` | l'unité au rattachement stable — commune d'époque ou fraction |
| `atom_geom` | un polygone par atome, trame GEOFLA 2011 |
| `atom_geom_anr` | polygones **datés**, trame ANR-COMMUNES 1790-2020 |
| `unit`, `unit_version` | cantons et circonscriptions, avec leurs noms datés |
| `membership` | rattachements `[valid_from, valid_to)`, par niveau |
| `regime_electoral` | régime de scrutin, année par année |
| `*_trace`, `*_qualite` | ce que chaque fichier a posé, et à quel titre |

**Les effectifs ne sont pas donnés ici** : douze fichiers en ajoutent depuis le
chargement initial, et un total écrit dans une note se périme en une session.
`ETAT.md` § 1 les donne par couche, avec la date de mesure de chacun.

---

## 2. Le choix d'architecture, et ce qu'il coûte

**Géométrie et attribution sont découplées.** La géométrie vit au niveau de
l'atome ; l'attribution vit dans `membership`, sous forme d'intervalles
temporels. Rien n'est pré-dissous : `snapshot_geom(date)` fait l'union à la
demande.

Ce n'est pas le choix le plus rapide à l'exécution. C'en est un qui permet de
**changer de trame géométrique sans retoucher une seule attribution** — ce qui a
été fait le 1ᵉʳ septembre 2026 en chargeant ANR-COMMUNES à côté de GEOFLA, sans
qu'une ligne de `membership` bouge. Le découplage a payé une seconde fois sans
qu'on l'ait cherché : ANR dessine la France actuelle à toute date, Alsace-Moselle
comprise en 1900, mais nos 1 690 atomes alsaciens-mosellans ont un trou de
rattachement de 1871 à 1919 — donc `snapshot_geom_anr(1900)` ne les demande
jamais. Le polygone existe et personne ne l'appelle.

**L'atome** est la plus petite unité au rattachement stable : une commune entière
(`atom_id` = code Cassini), ou une **fraction** quand un pseudo-canton recouvre
plusieurs cantons réels (`atom_id = 'cassini#canton'`, `fraction = true`).

**Plusieurs atomes peuvent porter le même polygone**, volontairement — fractions,
route `successeur`, atomes modernes de `21`. C'est une conséquence directe de
l'architecture, et la source de deux familles de fautes symétriques : voir
§ 14.1.

**L'intégrité est déléguée à la base**, pas au code de chargement. Trois
contraintes `EXCLUDE USING gist` : un atome n'appartient qu'à une unité par
niveau à un instant donné ; deux versions d'une même unité ne se chevauchent
pas ; un atome n'a qu'un polygone ANR par date. C'est la base qui refuse les
incohérences, et elles ont été validées sur les vraies données.

---

## 3. Sources

| source | ce qu'elle apporte | licence |
|---|---|---|
| **TRF-GIS** (V. Gay, Harvard Dataverse) | attributions et nomenclatures 1870-1940, 71 millésimes ; et les cantons **déjà dissous** de 1870 et 1940, qui servent d'étalon | CC BY 4.0 |
| **GEOFLA 2011** (ED111) | trame communale, 36 610 communes — celle sur laquelle TRF-GIS a bâti ses nomenclatures, les codes correspondent exactement | Licence Ouverte |
| **GEOFLA 2014** (ED141) | couche CANTON, étalon de la période 1999-2012 | Licence Ouverte |
| **ANR-COMMUNES** | trame communale **historique datée**, 1790-2020 | voir Zenodo |
| **Mouvements de communes INSEE** | `v_mvt_commune_2025.csv`, remonte à 1943 | Licence Ouverte |
| **HAC** (*Des villages de Cassini…*, EHESS) | mouvements communaux depuis 1801, filiation nommée | — |
| **COG** 1999-2012 | nomenclature cantonale moderne, 14 millésimes | Licence Ouverte |
| **Recensements 1954 et 1968** (BnSP/INSEE) | composition cantonale au milieu du trou | domaine public |
| **Légifrance et JO** | 343 décrets cantonaux moissonnés par titre | domaine public |
| **Gaudillère**, *Atlas des circonscriptions électorales* | annexes VI et VII : particularités des circos, mouvements cantonaux datés au décret | — |
| **CONTOURS-IRIS** (INSEE-IGN) | trame de découpe des villes, et les 80 quartiers de Paris | Licence Ouverte 2.0 |

DOI, URL et pièges de lecture de chaque source : `sources/`, `LISEZMOI.md`, et
les notes de chantier (`docs/note_circonscriptions.md`,
`cog1954/note_1954.md`, `cog1968/note_1968.md`, `ANR_COMMUNES_22042026/README.md`).

**Contrainte de licence, qui commande tout le reste** : le projet alimente
Wikipédia et Wikidata. Toute source doit être **CC BY-SA ou Licence Ouverte /
Etalab, et vérifiable par une URL publique**. Cela exclut l'ODbL (quartiers de la
Ville de Paris, ALPAGE-Vasserot) et le CC BY-NC-SA (Cassini-Geopeuple), même
quand la donnée serait parfaite.

### Deux points de source à ne pas réapprendre

**`--geom-col insee`, pas `com_act`.** Le codebook TRF-GIS définit `com_act`
comme un **statut** — 1 actuelle, 2 ancienne post-1943, 3 ancienne pré-1943 — et
non comme un code commune. `atom.com_act` est vide depuis ce changement ; le
statut est reconstituable depuis les `COG_COMMUNES_YYYY.txt` si besoin.

**`-a_srs` et non `-t_srs`.** Les données *sont* en Lambert-93 : on déclare la
projection, on ne reprojette pas.

**La correspondance Cassini → INSEE n'est pas bijective** : 37 648 codes Cassini
pour 37 584 codes INSEE en 1870. Plusieurs communes historiques partagent un
code actuel — c'est la cause du § 6.1.

**`id_com` d'ANR EST l'identifiant Cassini.** Le README d'ANR ne le dit pas et ne
mentionne aucun code INSEE, de quoi croire qu'il faudrait un appariement par
nom. C'est faux : 99,91 % des atomes non-fraction se retrouvent par jointure
d'entiers, 99,66 % d'accord sur les noms.

---

## 4. La chaîne

Tout se rejoue de zéro. Inventaire complet des 84 fichiers dans
**`sql/CHAINE.md`** — ce que chacun fait, ce qu'il écrit, sa table de trace, ses
variables. Dépendances et ordre de rejeu dans **`sql/README.md`**, section
« Qui dépend de qui ».

```bash
# une seule fois : extraction et téléchargements
python3 trfgis_extract.py build sources/trfgis/communes/Nomenclatures \
    --out build --mapping sources/trfgis/cantons/Nomenclatures --geom-col insee
python3 trfgis_fetch_inspect.py fetch repro \
    --match '^COMMUNE\.(SHP|SHX|DBF|PRJ)$' --dest ./geofla
curl -O https://www.insee.fr/fr/statistiques/fichier/8377162/v_mvt_commune_2025.csv
createdb histgis

# à chaque reconstruction
cd sql && ./rebuild.sh           # 01→04, GEOFLA, 05, 06, 07, 11, 15
./rejouer_apres_rebuild.sh       # le reste de la chaîne, dans l'ordre
./controle_gay.sh                # contrôle indépendant, facultatif
```

`rebuild.sh` localise seul `COMMUNE.SHP` et `v_mvt_commune_*.csv`, et refuse de
démarrer sans eux. Il est **destructif** : `load.sh` fait
`DROP SCHEMA histgis CASCADE`. Toute modification de `geom_correspondance.csv` ou
des CSV de `build/` impose de tout rejouer — ces fichiers sont lus par
`02_load.sql`, pas par `05`.

### Trois façons de casser la chaîne sans le voir

1. **Un fichier qui crée des unités ne peut pas être rejoué tant qu'un autre les
   référence.** La clé étrangère `membership_unit_fk` le refuse. `24`, `27` et
   `28` sont concernés.
2. **La suppression de ses atomes emporte par cascade ce que d'autres ont posé
   dessus.** La reconstruction de `24` a ainsi emporté en silence les
   circonscriptions que `27` et `28` avaient posées sur ses 732
   atomes-fractions ; il a fallu `43` pour les reposer.
3. **La propagation entre dossiers.** Si seuls les `.sql` circulent, `build/`,
   `geom_correspondance.csv` et les notes peuvent être périmés d'un côté sans
   que rien ne le signale. Le correctif Marseille est resté sans effet une
   journée entière pour cette raison.

Dans les trois cas : **un résultat obtenu sur une base à demi reconstruite est
indiscernable d'un résultat juste.**

### Le rattrapage des communes disparues

La jointure directe sur le code INSEE laisse **1 504 atomes sans polygone** :
leur code d'époque a disparu avant 2011, presque toujours par fusion (loi
Marcellin, 1971). Dispersés — un quart des cantons est amputé à une date donnée —
et concentrés dans les départements les plus touchés.

`06_insee_mvt.sql` rejoue les mouvements INSEE jusqu'au 1ᵉʳ janvier 2011 et
remonte les chaînes d'absorption (deux sauts au maximum) : **1 487 atomes
récupérés**. `07_reliquat.sql` traite les **17 derniers**, disparus avant 1943
donc hors du fichier INSEE, par les fusions documentées dans HAC.

Répartition dans `atom_geom` :

| `source` | Atomes | Fiabilité |
|---|---|---|
| `geofla` | 36 901 | jointure directe sur le code |
| `successeur` | 1 487 | mouvements INSEE, auditables ligne à ligne |
| `union_prefixe` | 27 | Lyon et Marseille, arrondissements réunis |
| `hac` | 11 | successeur unique, sans ambiguïté |
| `absorbee` | 10 | `geom_correspondance.csv`, saisi à la main |
| `hac_partage` | 6 | **choix arbitraire** : premier successeur retenu |
| `creation_arriere` | 60 | communes nées après 1940 (§ 6.2 quater) |
| `arrondissement` | 25 | Marseille et Lyon, période moderne seulement |
| `fraction_cog` | 730 | communes partagées après 1943, posées par `24` |

S'y ajoutent, pour 1943-2012, 15 atomes `successeur` posés par `21` pour des
codes qui coexistaient avec l'atome qu'ils empruntaient, et 4 atomes `geofla`
pour Tende, La Brigue, Chisa et Butry-sur-Oise.

---

## 5. Décisions structurantes

**Un seul continuum d'atomes de 1870 à 2012.** 2 404 des 2 407 codes de communes
disparues entre 1943 et 2011 et préexistant à 1943 se raccordent à un atome
existant : le pont passe par le code INSEE et la fermeture transitive de `06`, il
n'a pas eu à être construit.

**Un seul espace de noms pour les cantons.** Un canton garde son `unit_id` de
1870 à 2012, avec un `membership` mince entre 1941 et 1998. Fondé, non
conventionnel : `ct_codes.do` de TRF-GIS s'intitule « ADJUST CANTONS CODES TO
MATCH 1954 COG » et aligne les codes de Gay sur le COG de 1954 ; la filiation
1954 → 1999 est celle de l'Insee. **Ce qui est affirmé, c'est l'identité du
canton ; pas sa composition dans l'intervalle.**

**Les arrondissements de Marseille et Lyon changent de statut en 1943.** Les
fractions restent l'attribution de 1870-1940, les arrondissements deviennent des
atomes de plein droit ensuite. Les deux familles portent des géométries qui se
recouvrent, mais leurs `membership` ne se croisent **jamais** dans le temps —
une recette le vérifie des deux côtés. L'éclatement rétroactif était infaisable :
TRF-GIS ne dit jamais quel arrondissement relève de quel canton en 1870, et faire
appartenir l'atome du 3ᵉ arrondissement aux dix cantons lyonnais viole
`membership_non_chevauchant`.

**Le pseudo-canton est la convention du domaine, pas un pis-aller.** Gay l'emploie
pour 1870-1940, l'IGN pour 2014 (`CODE_CANT = '99'`, d'où 3 708 cantons chez
l'IGN contre 3 876 au COG), et pour la même raison : une trame communale ne sait
pas couper une commune. Nous butons au même endroit qu'eux.

**L'absence signifie « on ne sait pas », la présence « on sait ».** C'est la règle
qui décide de tous les cas limites : à `1970-06-01` avant les jalons,
`count_units` ne renvoyait aucune ligne — pas un canton faux, pas une composition
interpolée, rien. Corollaire d'affichage : *ce qui n'a de nom nulle part est
signalé comme tel, pas maquillé* — une absence silencieuse sur une carte viole
cette règle autant qu'une invention.

---

## 6. Les limites connues

Toutes chiffrées par les contrôles du § 7. **À mentionner en légende de toute
carte publiée.** `ETAT.md` § 4 en donne le résumé numéroté.

### 6.1 Communes revendiquées par plusieurs cantons

**218 communes au 1ᵉʳ juin 1885, soit 0,6 %** — donc autant de zones où deux
cantons se recouvrent. En surface : **3 945 km² comptés deux fois en 1870**,
4 036 en 1940.

Deux causes : les communes historiques fusionnées depuis partagent un code
INSEE ; les communes éclatées entre cantons n'ont pas de géométrie propre.
C'est inhérent à la trame — une géographie de 2011 ne découpe pas plus fin
qu'elle-même — et TRF-GIS a exactement la même limite au même endroit.
`atom_geom.partagee` marque les cas, `check_geom_overlap(date)` les chiffre.
Invisible à l'échelle départementale, visible au zoom.

**Le chiffre dépend du niveau où on le lit**, et il faut le dire. Mesuré aux deux
par deux méthodes indépendantes — union de polygones d'un côté, comptage des
unités par groupe de partage de l'autre :

| | géométrie | nomenclature |
|---|---|---|
| entre cantons réels | 12 930 | 12 822 |
| après repliement en pseudo-cantons | 3 945 | 3 837 |
| absorbé par le repliement | 8 985 | 8 985 |

**C'est 3 945 km² qu'il faut citer** — le niveau auquel le contrôle opère et
auquel les deux sources sont commensurables ; 12 930 est le même phénomène vu
avant repliement (2,36 % du territoire, sur 8 756 km² de polygones éclatés en
236 groupes).

Contre-intuitif : **le résidu n'est pas urbain.** Sur les 3 837 km², 3 296
viennent de communes rurales partagées entre deux cantons ordinaires, contre 541
de restes urbains. Le repliement règle le cas des villes en entier.

Les deux méthodes divergeaient de **108 km² exactement aux deux niveaux** — un
décalage constant, donc une cause unique. `14_cle_partage.sql` l'a attribuée :
elle vient de la **clé de regroupement**, pas de la mesure. Cinq groupes portés
par des atomes rattachés par nom, dont aucune colonne ne dit quel polygone ils
portent : Lyon 47,85 km², 2A325 19,35, 51606 16,78, 60606 14,73, 08227 9,32 —
somme 108,03. Chacun ajoutant exactement une unité, sa surface compte une fois
de plus à chaque niveau, d'où la constance. L'hypothèse concurrente — des atomes
`geofla` recevant à tort la clé de leur successeur — a été testée et écartée :
un seul atome concerné.

**Correctif porté dans `12`**, qui groupe désormais sur `md5(ST_AsEWKB(geom))` :
36 489 groupes, 236 éclatés, 12 930 km². `13` conserve délibérément l'ancienne
clé — c'est lui qui documente l'écart.

**Depuis le 1ᵉʳ septembre 2026, ANR-COMMUNES ramène ce recouvrement à
101,0 km²** dans `atom_geom_anr`, résidu nommé (Notre-Dame-de-Briançon 93,6,
Tours 6,9). Mais `atom_geom` reste intacte avec ses 3 945 : **c'est la valeur que
voit tout ce qui ne passe pas par `snapshot_geom_anr()`.** Et ANR ne règle pas
les 333 fractions — il livre le polygone de la commune-mère entière et ne sait
pas la découper entre deux cantons.

Contrôle croisé qui vaut d'être connu : le double comptage **chez Gay est nul**
(548 202 km² en somme comme en union). Le phénomène est chez nous, pas dans la
comparaison. Et l'écart entre son union et la nôtre, 811 km², valait exactement
le trou de couverture du § 6.2 à cette date : deux chemins indépendants vers le
même nombre.

### 6.2 Trame incomplète : les communes créées après la date interrogée

**Corrigé pour l'essentiel** — de 5 926 km² non couverts en 1870 à **238**, et de
610 à **32** en 1940.

Le défaut : la correspondance vers GEOFLA est plusieurs-vers-un. Quand une
commune d'époque s'est **scindée** depuis, un seul des codes issus de la scission
est retenu et le territoire de l'autre n'est réclamé par aucun atome. `06` traite
les fusions ; l'opération symétrique n'existait pas.

Il a été découvert par le contrôle indépendant, et invisible aux recettes
internes faute de point de comparaison. Sa signature : l'écart est **à sens
unique** — `km2_nous_seul` vaut 0,0 dans les 89 départements de 1870 comme dans
les 90 de 1940. Nous ne revendiquons jamais un territoire de trop ; une commune
mal rattachée se retrouverait en trop quelque part.

#### 6.2 bis Le correctif `11_scission.sql`, et ce qu'il coûte

Il repose sur un fait établi par le contrôle : l'essentiel de ces communes est né
**entre 1870 et 1940**, donc TRF-GIS les suit déjà et leur atome existe, avec un
`membership` qui commence à leur année de création. Il suffit de prolonger ce
rattachement vers l'arrière.

Le pari : *une commune nouvelle reste dans le canton de sa mère.* 505 atomes
candidats, 50 écartés comme recodages, 414 prolongés. Réversible par
`scission_trace`, rejouable, et il retire ses propres lignes avant de
recommencer.

Le coût : **quatre paris perdus sur 414**, soit 99,0 % — nommés dans `ETAT.md`
§ 3.1, laissés en l'état délibérément. 4 982 km² rendus pour 49 km² mal
rattachés.

**Deux contrôles indépendants l'ont depuis validé** : HAC donne 98,2 % au canton
et **100 %** aux circonscriptions (§ 7.3), et ANR fait naître après 1870 les
communes que `11` a prolongées dans **84,1 %** des cas contre 33,9 % pour les
autres, les deux dates tombant sur la même année 357 fois sur 359 (§ 7.5). Le
pari est devenu une inférence corroborée.

#### 6.2 ter Le quatrième garde-fou, et son prix

Le premier passage perdait sept paris. Trois — 57369 Cattenom, 57474 Longuyon,
68048 Habsheim — étaient apparus en 1921 et 1928, après le retour de
l'Alsace-Moselle, et relevaient du même défaut : **TRF-GIS réutilise les codes de
canton de part et d'autre de la rupture de 1871.** Le 5705 de 1870 appartient à
la numérotation de la Meurthe, celui de 1921 à celle de la Moselle reconstituée —
deux cantons sous une même clé, que le modèle prend pour une unité pérenne
unique. C'est une limite du schéma, pas du correctif : `unit_id` suppose une
identité continue que les données ne garantissent pas.

Le **garde-fou 4** ne retient que la plage d'existence *continue* du canton
aboutissant à la date d'apparition. Il retire 27 prolongements pour en supprimer
3 faux — les 24 autres coïncidaient avec Gay, mais sur ce terrain l'accord ne
prouve rien : pour une commune créée sous administration allemande, Gay a dû
extrapoler comme nous, et deux extrapolations qui coïncident restent deux
extrapolations.

Il se justifie par un fait relatif aux données, **pas par le verdict de Gay** —
distinction qui n'est pas cosmétique, puisqu'elle seule préserve l'indépendance
du contrôle. Révocable : retirer la clause `WHERE retenu` de `scission_periode`.

#### 6.2 quater Les communes nées après la série

`11` ne pouvait rien pour les communes nées **après** 1940 : TRF-GIS ne les a
jamais vues. `15_creation_arriere.sql` les traite à partir des mouvements INSEE
(modalités 20 et 21), qui documentent leur création et nomment la mère.

Conception : plutôt qu'élargir la géométrie de l'atome mère — ce qui mêlerait
géométrie et attribution —, on crée un **atome-fraction** portant le polygone de
la fille et on lui recopie l'appartenance de la mère, année par année, aux deux
niveaux. `cassini` synthétique préfixé `N`, `fraction = true`,
`source = 'creation_arriere'`. Une année n'est comblée que si toutes les mères
candidates s'accordent sur la même unité ; sinon elle reste vide.

Le rattrapage se place honnêtement dans la hiérarchie de fiabilité : **5,26 % de
désaccord avec Gay**, entre `geofla` (0,01 %) et `successeur` (9,3 %).

**Ce qui reste non couvert en 1870** : 39 communes et 238 km², dont 37 créées
avant 1943 et hors de portée du fichier INSEE — Philippsbourg et une vingtaine
de mosellanes ou meurthe-et-mosellanes nées sous administration allemande. HAC
est la seule piste, au prix d'un rattachement par nom. S'y ajoutent **Kuntzig et
Stuckange** (8,6 km²), documentées mais dont la ligne INSEE a un `com_av` vide ou
égal à `com_ap`.

**Tende et La Brigue** (271,1 km²) ne sont pas un défaut mais un fait : italiennes
jusqu'au traité de Paris de 1947, leur mouvement INSEE a un `com_av` vide — la
source dit qu'il n'y a pas de mère.

> **Correction du 2 septembre 2026.** Ce paragraphe rangeait auparavant **Chisa
> et Butry-sur-Oise** parmi les communes « créées avant 1943, hors de portée du
> fichier INSEE », et `ETAT.md` parmi les « territoires neufs » aux côtés de
> Tende et La Brigue. **Les deux étaient faux.** `insee_mvt` documente Chisa
> (`mod 20`, 12 avril 1947, détachée de Ventiseri) et Butry (1ᵉʳ août 1948,
> d'Auvers-sur-Oise). Ce qui les avait fait échapper à `15` est le **recodage** :
> leur mouvement nomme `20366` et `78039`, codes d'avant le recodage de la Corse
> (1976) et de la Seine-et-Oise (1968), que `15` comparait au code GEOFLA
> moderne. `42_rattachement_arriere.sql` les traite depuis le 17 août 2026.
> L'erreur était dans la rédaction, pas dans la base.

#### 6.2 quinquies Marseille et Lyon n'ont qu'un canton, 1999-2012

La base ne représente **pas** les 22 cantons de Marseille ni les 13 de Lyon :
chaque ville forme un canton unique, auquel se rattachent ses 16 et ses 9
arrondissements, affectés géométriquement par point intérieur (`1399` et `6999`).

Le COG rattache ces cantons à la commune entière (`typct = 4`) sans jamais dire
quel arrondissement relève duquel, et GEOFLA fait exactement la même chose. **À
citer en légende** : le nombre réel de cantons de ces villes a évolué (Marseille
22 → 25 en 2005, Lyon 13 → 14 en 2002) sans que le pseudo-canton bouge. La
simplification masque une évolution réelle sans fausser le territoire.

**Le pseudo-canton se paie un niveau plus haut.** En renonçant à distinguer les
cantons de Marseille, on renonce aux circonscriptions qui les suivent : la
circonscription `13-08` de 1986, composée exclusivement de fractions des 11ᵉ, 12ᵉ
et 13ᵉ arrondissements, disparaît intégralement — ce qui est la bonne réponse, la
trame ne pouvant rien porter d'elle.

### 6.3 Six atomes au rattachement arbitraire

`source = 'hac_partage'` : commune répartie entre plusieurs successeurs, le
premier nommé a été retenu. Liste dans `07_reliquat.sql`, révocable.

**Nuance apportée par `14`, et vérifiée atome par atome.** Les cinq atomes
`hac`/`hac_partage` en désaccord avec Gay sont exactement les cinq que `14` § 5
place sur un polygone réclamé par plusieurs cantons. Leur désaccord ne **démontre**
donc rien contre l'attribution — le « 3 sur 6 » mesure la trame, pas l'échec du
choix arbitraire. Ce qui ne l'innocente pas : le rattachement par nom reste
arbitraire et révocable. Simplement, **sur ces six-là, le contrôle Gay ne tranche
pas.**

### 6.4 Cent trente-deux circonscriptions sans nom

Citées par le membership mais absentes des nomenclatures TRF-GIS — Paris
`U7580`/`U7581`, Bouches-du-Rhône `U1381` — pour 134 rattachements. Ce sont des
pseudo-circonscriptions d'arrondissement urbain, écartées à l'extraction. Créées
avec `provisoire = true` et `nom IS NULL` pour ne pas perdre l'information. À
reprendre côté extracteur si leurs noms sont voulus.

### 6.5 Paris n'est couvert qu'à 4 circonscriptions sur 18 en 2009

Le découpage de 2009 coupe **à l'intérieur des arrondissements** — treize des
vingt en relèvent de deux ou trois — et notre unité la plus fine à Paris, dans la
couche moderne, est l'arrondissement. Quinze des 539 circonscriptions sont donc
vides : quatorze à Paris, une à Lyon.

Le pseudo-découpage, qui a résolu Marseille et Lyon au niveau cantonal, a été
mesuré puis **écarté** : il relierait 17 des 18 circonscriptions parisiennes en
une seule composante. Paris deviendrait un bloc, ce qui est pire que quinze
unités vides. Les quatre circonscriptions pourvues le sont d'arrondissements
réellement non partagés ; les supprimer jetterait une information vraie.

45 atomes n'ont aucune circonscription en 2012 ; 31 en relèvent de deux, et 8 en
1986. Ces derniers étaient auparavant absents de la liste **parce qu'ils étaient
éliminés en amont, pas parce qu'ils étaient résolus** : la limite était masquée,
elle est maintenant déclarée.

### 6.6 Les 113 communes indéterminées de 1986

Le tableau officiel de 1986 écrit pour certains cantons « circonscriptions 13 et
16 » en toutes lettres, **sans dire quelle commune va où**. 135 lignes,
24 cantons, recensées dans `circo/circo_1986_indetermine.csv`. C'est un fait de
la source, pas un défaut — mais l'indétermination doit être **affichée**, et elle
ne l'est pas encore (`RESTE_A_FAIRE.md` § 3).

Conséquence méthodologique à ne pas oublier : le contrôle « aucun couple
canton-commune partagé » de `note_circonscriptions.md` § 4 ter avait tourné **sur
des données amputées de leurs contre-exemples**. Il ne pouvait que réussir.

### 6.7 Poids mort géométrique

Sept communes rétablies en 2012 ou après (52033, 52124, 52266, 52278, 52465,
55138, 76601) sont absentes de GEOFLA 2011, le millésime précédant leur
rétablissement. Leur atome existe par la route `successeur` et **porte le
polygone de leur absorbante** — leur aire est exactement celle de la mère. Elles
ne laissent aucun trou de couverture : leur territoire est couvert par l'atome de
la mère. Mais elles n'ont pas de territoire propre, et leur poser des
rattachements ferait compter le même polygone deux ou trois fois par le même
canton (§ 14.1).

### 6.8 Les cinq limites d'ANR-COMMUNES

1. **Les fractions** : ANR ne sait pas découper une commune partagée entre deux
   cantons. Les 333 fractions restent.
2. **La Corse est un instantané** : 360 polygones justes au km² près, mais
   **zéro édition historique** contre 27,1 % nationalement.
3. **Aucune frontière nationale.** ANR dessine la France actuelle à toute date :
   la Savoie et les Alpes-Maritimes y sont françaises en 1815 (769 communes,
   14 899 km²), l'Alsace-Moselle en 1900 (1 701 communes, 14 575 km²). L'emprise
   ne varie que de 126 km² sur deux siècles, ce qu'aucune reconstruction suivant
   les frontières ne pourrait faire. **Sans effet sur 1870-1940** (§ 2), mais
   c'est un verrou pour l'extension avant 1870.
4. **101,0 km² de recouvrement résiduel**, nommés : Notre-Dame-de-Briançon 93,6,
   Tours 6,9 — un défaut d'identité qui traverse deux siècles, présent à toutes
   les dates.
5. **532 `id_com` sur 40 572 (1,31 %) ont un trou de chronologie non déclaré** :
   un polygone avant, un après, rien entre. 11 113 années-communes, médiane
   12 ans, 75 trous couvrant 1870, 6 couvrant 1940, aucun en 1954. Vingt communes
   des Ardennes partagent la signature `1790-1828 | 1871-2020`. C'est la seule
   limite qui ne se voie qu'en interrogeant une date **à l'intérieur** du jeu
   plutôt qu'à ses bornes ; R5 la rattrape, `n_repli` la dit sur la carte.

---

## 7. Les contrôles indépendants

**Le dispositif central du projet.** Les recettes internes valident la
cohérence, jamais l'exactitude : le § 12 dit pourquoi, et le § 7.6 donne
l'exemple qui l'a établi.

Quatre étalons, dont aucun ne passe par une ligne de notre code. Les résultats
chiffrés sont dans `ETAT.md` § 3 ; ce qui suit est la **méthode** de chacun, et
les pièges qu'ils ont coûté.

### 7.1 Gay — les cantons dissous de 1870 et 1940

TRF-GIS livre, pour ces deux années seulement, les cantons **déjà dissous** par
Victor Gay (`sources/trfgis/cantons/Shapefiles/CANTONS_YYYY.zip`). Les comparer à
`snapshot_geom()` teste la chaîne entière — extraction, attributions,
rattrapages, dissolution.

```bash
cd sql && ./controle_gay.sh     # exige gdal-bin
```

**Le piège, et il est double.** Les shapefiles de Gay sont découpés en
**pseudo-cantons**, pas en cantons réels : Montluçon-Est et Montluçon-Ouest ne
forment qu'un ensemble, parce que la trame communale ne sait pas couper une
commune. Gay bute sur la même limite que nous, au même endroit — c'est donc à ce
niveau, et là seulement, que les deux côtés sont commensurables.

Second piège, plus vicieux : chez Gay un ensemble urbain n'est pas **un**
polygone mais plusieurs. Le polygone `pct_type = 'Pseudo canton'` ne porte que la
commune indivise ; les communes entières de chaque canton restent dans des
polygones séparés, sous le code du canton réel. Moulins : `0381` = les 8,5 km² de
la ville, `0323` et `0324` = les communes rurales. Trois polygones pour deux
cantons.

Un premier passage n'avait replié **que notre côté** : il comparait deux cantons
entiers à un centre-ville. Symptômes — 239 clés orphelines, 22 689 km² manquants,
les 25 pires écarts tous chefs-lieux. **Le repliement s'applique aux deux côtés.**

**Curiosités documentées.** Le département 99 apparaît en 1870 seulement,
25 pseudo-cantons : c'est la Meurthe d'avant 1871, présente des deux côtés, donc
sans conséquence sur le contrôle. Les 1 690 atomes dont la chronologie est trouée
exactement de 1871 à 1919 sont l'Alsace-Moselle — une validation, pas une
anomalie.

### 7.2 GEOFLA — les cantons de 1999-2012

`26_controle_ign.sql` compare `snapshot_geom('2012-06-01', 'canton')` à la couche
CANTON de GEOFLA.

**Réserve d'emblée** : ce contrôle est plus faible que celui de Gay. Ses cantons
étaient bâtis sur GEOFLA ED111, la trame même de nos communes ; la couche CANTON
disponible est l'édition ED141, de 2014. Un écart de tracé peut donc venir d'une
reprise de limites, et **seuls les écarts d'attribution, qui portent sur des
communes entières, concluent.**

**Le piège du repliement, retombé dedans.** Le premier jet a reproduit l'erreur
du § 7.1, pourtant écrite dans le dépôt : ne replier qu'un côté. Pire, il
déduisait le repliement de l'affectation géométrique des atomes — **c'est-à-dire
de la réponse à tester**. Résultat : 216 entités orphelines, 17 613 km²
d'excédent, IoU 0,917.

Corrigé en déduisant le repliement de **notre** nomenclature (deux cantons
fusionnent s'ils partagent une commune, composantes connexes) et en rattachant
les entités 9x par la commune qu'elles portent. Orphelines à zéro, excédent
ramené à 26 km².

### 7.3 HAC — la filiation que `11` ne connaissait pas

`hac/hac_filiation.py`, `sql/45_controle_hac.sql`. **Il ne contient aucun
`INSERT`, `DELETE` ni `UPDATE`** : corriger la base d'après HAC lui ferait perdre
son indépendance, exactement comme recopier Gay la ferait perdre au contrôle
géométrique.

La clé est donnée par la source : **l'`id` de HAC EST la colonne `cassini`**.
Vérifié sur Cherré (9222), La Ferté-Bernard (18180), Saint-Antoine (30448) — la
fille ne se rapproche par aucun nom, c'est la clé la plus sûre du projet. La
mère, elle, n'est nommée qu'en clair et sous son nom d'*aujourd'hui* :
« Villefranche-sur-Mer » contre « Villefranche », « La Baule-Escoublac » contre
« Escoublac ». Indexer les deux formes fait passer la résolution de 92,8 % à
99,3 %. Les 45 homonymes redoutés (dix « Saint-Just », onze « Sainte-Marie »)
tombent tous dès qu'on restreint au département de la fille.

**Une voie de construction reste légitime** et a été essayée : faire de HAC une
source de filiation pour `11`, comme `insee_mvt` l'est pour `15`, en laissant Gay
contrôler le résultat. Elle a été **mesurée et abandonnée** — voir § 13.3.

### 7.4 Le registre des actes — validation du report `79`/`81`

`80` § 6 quinquies compare, **dans un même département**, l'accord 1968/1999 des
atomes qu'un décret nomme et de ceux qu'aucun décret ne nomme. Un test de signe
département par département (§ 6 sexies) ne suppose aucune homogénéité.

**L'affirmation testée n'est pas une tautologie.** Ce n'est pas « les communes que
les décrets nomment ont changé de canton », c'est l'affirmation forte et
réfutable du registre : *en dehors de ces 2 536 atomes, rien n'a bougé en trente
et un ans.* Si le registre était incomplet, les communes déplacées par des actes
qu'il ignore se trouveraient chez les jamais-nommés et feraient chuter leur taux.

**Le biais restant a un sens connu** : un décret nomme les cantons qu'il crée ou
modifie, jamais ceux qu'il vide, donc des atomes réellement déplacés sont classés
« jamais nommés » et y font baisser l'accord. Le biais joue **contre**
l'hypothèse. Un accord élevé chez les jamais-nommés est donc acquis malgré lui ;
un accord faible pourrait n'être que lui.

Ce contrôle a d'abord échoué, et l'échec est instructif : voir § 11.4.

### 7.5 ANR — les dates de naissance

`83_anr_ecart_couverture.sql`, lecture seule. Ce qui devait n'être qu'une
explication d'écart de recette est devenu un contrôle à part entière, et il porte
sur une question que ni Gay ni HAC ne posaient : *quelle part de notre couverture
de 1870 est attestée, et quelle part est reportée ?*

Là où ANR refuse un polygone, il ne se trompe pas : **il refuse de suivre notre
report.** Et c'est exactement ce qu'on veut d'une source indépendante.
`debut_reel` vient des mouvements INSEE, `anr_debut` des éditions d'ANR ; les
deux chaînes n'ont pas une ligne de code commune.

### 7.6 Le bogue qui a fondé le dispositif

`geom_correspondance.csv` donnait `1320` comme préfixe pour Marseille. Le
`LIKE '1320%'` de `05_geom.sql` ne prenait que les arrondissements 13201 à 13209
et perdait les 10ᵉ à 16ᵉ. GEOFLA ne contient **aucun code 13055** : Marseille n'y
existe que sous ses seize arrondissements.

| | avec `1320` | avec `132` | chez Gay |
|---|---|---|---|
| Marseille | 101,57 | 235,22 | 235,22 |
| Allauch | 50,46 | 50,46 | 50,46 |
| Plan-de-Cuques | — | — | 8,57 |
| **total** | **152,03** | **285,69** | **294,25** |

IoU du pseudo-canton : 0,517 → 0,971. Le reliquat, Plan-de-Cuques, est une
commune créée après 1870 relevant du § 6.2. Lyon était sain.

**Ce que ce bogue enseigne, et c'est l'argument le plus concret en faveur du
contrôle indépendant.** Un préfixe trop long n'échoue pas, il **ampute en
silence** : l'atome avait bien une géométrie, `check_geom()` ne signalait rien,
toutes les recettes internes passaient. Il a fallu une source extérieure pour le
voir. `05_geom.sql` affiche désormais à chaque chargement ce que chaque préfixe
capte, avec le compte attendu — Paris 20, Marseille 16, Lyon 9.

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
années (1876, 1885, 1889…). Zéro chevauchement, zéro orphelin, couverture
canton/circonscription complète, zéro géométrie invalide. Rapport dans
`sorties/rapport_chargement.txt`.

Pour la période moderne, la contradiction est plus forte encore :
`20_commune_moderne.sql` reconstitue la chronologie communale sans rien écrire,
puis se soumet à l'ensemble des communes vivantes au 1ᵉʳ janvier 2011 selon
GEOFLA. Elle y retombe **au code près** : 39 291 intervalles pour 39 040 codes,
251 vies multiples, 38 068 communes en 1943, 36 630 en 2011 dont 36 610
métropolitaines.

---

## 9. Suites

Elles sont dans `RESTE_A_FAIRE.md`, tenu à jour. Les quatre axes :

1. **Étendre la couverture cantonale de 1943 à 1999** — jalon de 1975, chaînage
   acte par acte, le mur 1986-1989.
2. **Découper les 119 villes** dans QGIS, sur la trame IRIS déjà en base.
3. **Contrôler la couche circonscriptions**, qui reste la moins éprouvée.
4. **Étendre avant 1870**, où la géométrie est acquise et la frontière manque.

---

# Partie II — les règles de travail

## 10. Index

Ces règles ont toutes été payées. Chacune porte le cas qui l'a produite, parce
qu'une règle sans son cas ne se reconnaît pas dans la nature.

**§ 11 — Ce qu'un contrôle peut et ne peut pas montrer**
11.1 Une recette de cohérence ne voit que ce qui se contredit ·
11.2 Un contrôle qui ne peut pas échouer n'est pas un contrôle ·
11.3 Le choix de l'échantillon fait partie de la mesure ·
11.4 Un test incapable de montrer l'effet ne le réfute pas ·
11.5 Un banc qui ne reproduit pas le piège ne prouve rien de la parade ·
11.6 Un banc qui remplace une opération par un succédané gratuit ne teste plus
son prix · 11.7 Un contrôle long n'a rien à faire dans la transaction qu'il
contrôle · 11.8 Ne pas généraliser une mesure hors de son périmètre

**§ 12 — Dénominateurs et ordres de grandeur**
12.1 L'ordre de grandeur attendu s'écrit AVANT la requête ·
12.2 Un taux sans son dénominateur est une opinion présentée comme une mesure ·
12.3 Un taux supérieur à 100 % n'est pas un bon score ·
12.4 Le bon dénominateur est celui dont parle l'affirmation qu'on teste ·
12.5 Une moyenne sur deux populations non séparées ne décrit aucune des deux ·
12.6 Un taux qui décroît vers zéro est presque toujours un artefact de
construction · 12.7 Une absence se démontre, elle ne se constate pas ·
12.8 Un attendu mesuré sur les CSV d'entrée ne décrit pas la base qui en sort

**§ 13 — Lire une source**
13.1 Une irrégularité de la source est souvent la réponse, pas l'obstacle ·
13.2 Avant de déclarer une source fautive, chercher l'événement qu'elle
enregistre · 13.3 Une source qui nomme un fait ne vaut pas mieux qu'un pari
mesuré si elle ne nomme pas LE fait · 13.4 Une source se juge par question, pas
en bloc · 13.5 Un champ de confort n'est pas une source · 13.6 Une date au jour
près prime sur un millésime annuel · 13.7 Une lecture linéaire d'un texte sur
deux colonnes attribue au hasard · 13.8 Une réparation qui repasse par la source
rend une source différente · 13.9 On ne réduit pas le nombre de preuves, on
écarte celles qui n'en sont pas · 13.10 Remonter la chaîne jusqu'à la source
avant d'accuser un maillon · 13.11 Le référentiel bouge et se déguise en
événement

**§ 14 — Territoires, atomes et clés**
14.1 Interroger un atome ne renseigne pas sur un territoire ·
14.2 Grouper par la géométrie, jamais par un code ·
14.3 L'empreinte constate un partage, elle ne teste pas une identité ·
14.4 Une borne qu'on n'interroge pas produit un silence, pas une erreur ·
14.5 Une signature d'entrée n'est pas une signature de sortie ·
14.6 Un identifiant d'atome n'est pas un code INSEE ·
14.7 Les grandes villes sont codées par arrondissement, et zéro n'a pas l'air
d'une erreur

**§ 15 — Règles, garde-fous et conventions**
15.1 Un garde-fou juste peut se tromper de cible · 15.2 Un garde-fou qui
rattrape une règle fausse donne un résultat juste et une méthode fausse ·
15.3 Une règle vraie appliquée au-delà de son domaine produit une donnée fausse
et cohérente · 15.4 Un couperet muet décide plus qu'une règle · 15.5 Une
convention doit être lisible comme une convention · 15.6 Un refus juste peut
avoir un motif myope · 15.7 Une clause qui départage ne doit pas conditionner ·
15.8 Un garde-fou évalué à l'exécution ne protège pas d'une erreur d'analyse

**§ 16 — Hygiène d'exécution**

---

## 11. Ce qu'un contrôle peut et ne peut pas montrer

### 11.1 Une recette de cohérence ne voit que ce qui se contredit

C'est la règle mère du projet, et sept défauts l'ont établie en une seule
session : communes mortes sans aucun canton, polygones dans le mauvais
département, atomes sans rattachement, encodage CP1252 lu en Latin-1, communes
écartées d'une extraction, recette d'équilibre fausse, jointure sans filtre de
période. **Aucun n'était visible d'une recette de cohérence.** Tous laissaient la
base parfaitement cohérente : les atomes existaient, les géométries étaient
valides, les couvertures bouclaient. Trois ont été trouvés en **regardant une
carte**, deux par une **source externe**, deux par une recette qui mesurait autre
chose.

> Une recette de cohérence ne peut pas voir un polygone au mauvais endroit, une
> commune jamais rattachée, ni un nom mal encodé. Il faut regarder, et il faut
> un dehors.

**Le cas le plus net : une recette d'attribution ne voit pas une erreur de
surface.** Sept communes rétablies après 2011 portent le polygone de leur
absorbante (§ 6.7). En leur posant les rattachements de la mère, on faisait
réclamer le même polygone par deux ou trois atomes **rattachés au même canton**.
La recette compte les atomes rattachés à deux unités du même niveau à la même
date — et trois atomes dans le *même* canton ne se contredisent pas. Le canton
comptait pourtant ce territoire trois fois.

**Conséquence opératoire** : tout correctif qui ajoute des rattachements doit
être contrôlé **aussi** sur la géométrie, par `md5(ST_AsEWKB(geom))` (§ 14.2).

**Deux règles de lecture qui en découlent** :

* *Une date identique sur toutes les lignes n'est pas une donnée, c'est une
  frontière de source.* Les 51 communes mortes finissaient toutes au 1ᵉʳ janvier
  1941, fin de la série TRF-GIS.
* *Compter n'est pas déclarer.* L'extraction de 1986 comptait et affichait les
  135 lignes écartées ; rien n'en portait trace dans la base.

### 11.2 Un contrôle qui ne peut pas échouer n'est pas un contrôle

La carte des circonscriptions de l'Ain sortait en vingt-trois morceaux pour
quatre circonscriptions. Pour savoir si la source était en cause, j'ai confronté
`circo_1986.csv`, tiré du tableau du ministère, à `circo_1986_ain.csv`, présenté
comme une table de référence. **Zéro désaccord sur 43 cantons** — et j'ai conclu
que la source était saine.

Le second fichier est **dérivé du premier**. Sa colonne `nb_communes` le disait :
une table établie d'après un décret ne compte pas les communes, elle les nomme.
J'avais comparé une source à sa propre copie, ce qui rend toujours zéro
désaccord.

> Avant d'appeler « contrôle » une confrontation, établir que les deux termes
> **peuvent** diverger. La question n'est pas « sont-ils d'accord ? » mais « par
> quel chemin chacun est-il arrivé là ? »

Deux fichiers dans le même dossier, portant sur le même objet, sont a priori
suspects de partager une origine. La vraie source est venue de l'extérieur — loi
n° 86-1197 et Gaudillère p. 89 — et donnait une composition **entièrement
différente** : 30 cantons sur 43 changent de circonscription.

**Corollaire, plus inquiétant.** La fragmentation ne détecte que le **désordre**,
pas l'erreur : un département dont les cantons seraient mal affectés mais à des
voisins immédiats sortirait d'un seul tenant. Savoir que l'Ain était faux ne dit
rien des 94 autres.

### 11.3 Le choix de l'échantillon fait partie de la mesure

Trois façons de se tromper, toutes rencontrées en une matinée sur le même banc.

**Mesurer là où il n'y a rien à gagner.** Choisir les pages que la chaîne lit
déjà le mieux — 95 % de réussite — et conclure qu'aucune variante n'apporte rien.
*Tester le remède là où il n'y a pas de maladie.* On mesure sur les cas qui
échouent.

**Ne pas voir les cas qui échouent complètement.** Le sélecteur classait les pages
d'après le fichier des communes lues ; une page qui n'a rien rendu n'y figure
pas. Les pires cas étaient **invisibles par construction**. Un critère de
sélection tiré du résultat qu'on cherche à améliorer a toujours cet angle mort —
il faut lui adjoindre une source qui ignore le résultat.

**Classer sur un seul échantillon.** Deux variantes séparées par 2 points sur un
département : ce n'est pas un classement, c'est du bruit. Deux fascicules de plus
ont inversé l'ordre. **La régularité entre échantillons indépendants est ce qui
distingue un effet réel d'un accident local.**

**Le témoin, et ce qu'il faut faire quand il s'effondre.** La première ligne du
tableau est toujours la chaîne en service. Si le témoin lui-même rend un résultat
absurde, **la mesure est disqualifiée, pas l'objet mesuré** : on cherche l'erreur
dans le protocole avant de lire une seule autre ligne. Le premier essai a rendu
zéro pour tout le monde, témoin compris, et j'ai commenté le tableau au lieu de
m'arrêter. *Un contrôle qui rend zéro ne rend pas un verdict, il rend un
silence.*

### 11.4 Un test incapable de montrer l'effet ne le réfute pas

`80` § 6 devait juger le registre des actes : si le registre dit vrai, l'accord
1968/1999 doit être plus haut là où il n'enregistre aucun acte que là où il en
compte quatre. Résultat : `88,31 %` / `91,27 %` / `88,75 %`. Pas de pente, et la
catégorie du milieu la plus haute.

**Deux défauts, tous deux de ma rédaction.** Le **témoin n'existait pas** : la
ligne « 0 acte » est vide, tout département pourvu d'atomes en 1968 portant au
moins un acte — *une mesure sans témoin n'est pas une mesure*. Et **la strate ne
séparait pas ce qu'elle prétendait séparer** : 74 départements sur 98 ont pour
premier acte la salve du 23 septembre 1973, le plus gros redécoupage de la
période. « 1 acte » n'est pas le groupe qui a peu bougé, c'est celui qui n'a reçu
que l'événement majeur.

> Un test qui ne pouvait pas montrer la pente ne réfute pas la pente.

Lire ce plateau comme une réfutation aurait été plus grave que l'avoir écrit : il
aurait condamné `79` et ses 36 296 rattachements sur une mesure incapable. **Le
§ 6 est conservé tel quel dans le fichier** — un résultat qui ne conclut pas
reste un résultat, et l'effacer masquerait le défaut au lieu de l'enseigner.

Le test refait au bon niveau (§ 7.4) a rendu 94,90 contre 33,49, et 49
départements sur 49. Voir § 12.4 pour ce que l'écart entre les deux enseigne.

### 11.5 Un banc qui ne reproduit pas le piège ne prouve rien de la parade

`75` normalise les codes de la Corse parce que les décrets de 1973 écrivent `20`
et ceux de 1982 `2A`/`2B` — le recodage de 1976 tombe entre les deux salves. Le
premier banc passait ce test **sans rien exercer** : sa couche de 1999 déduisait
le département du code INSEE, et les codes corses de 1973 commencent eux aussi
par `20`. Les deux côtés portaient la même graphie, la normalisation n'avait rien
à absorber. Il a fallu **forcer** la Corse en `2B` dans les données du banc.

> Un test qui passe sans avoir rencontré le cas ne dit rien de plus qu'un test
> absent — et il dit en plus qu'on a vérifié.

Même leçon prise par l'autre bout : `banc_75_donnees.sql` § 5 pose délibérément
un jalon de 1968 dont un sixième des communes est **mal rattaché**. Le taux
mesuré par `81` y rend 84,2 % ; s'il avait rendu 100 %, c'est la mesure qui
aurait été cassée. **Un banc doit avoir une cible.**

### 11.6 Un banc qui remplace une opération par un succédané gratuit ne teste plus son prix

`banc_82.sh` remplace la géométrie par son empreinte MD5 et `ST_Intersects` par
une fonction qui renvoie `false`. La requête de recette y est donc **bien formée
et instantanée**. En base réelle, la même requête n'a jamais rendu la main :
elle joignait une CTE à elle-même par `ST_Intersects`, et **une CTE référencée
plusieurs fois est matérialisée, donc sans index** — PostgreSQL partait sur
37 618 × 37 618 intersections de multipolygones réels.

L'en-tête du banc disait bien « ce qu'il ne prouve pas : le recouvrement de
101,0 km², qui demande un vrai PostGIS ». Ce qui n'était pas écrit :

> Ne pas pouvoir mesurer une chose, c'est aussi ne pas pouvoir mesurer combien
> elle coûte.

### 11.7 Un contrôle long n'a rien à faire dans la transaction qu'il contrôle

Même épisode, et c'est le vrai défaut. `psql -1` tient tout ouvert :
s'impatienter devant une recette qui traîne, c'est faire un `ROLLBACK` sur un
chargement qui, lui, avait parfaitement réussi. `82` § 9 n'appelle donc plus les
recettes — il affiche ce qui est bon marché et **imprime les deux commandes à
lancer après le `COMMIT`**, sur des données acquises, où interrompre ne coûte
rien.

### 11.8 Ne pas généraliser une mesure hors de son périmètre

`--psm 4` est mesuré sur les fascicules de 1968 (+22, +35, +22 selon le scan).
Les volumes de 1954 sont d'une autre numérisation et d'une autre mise en page :
le défaut de `page_texte` reste donc « 6 », et 1968 passe « 4 » explicitement. Le
gain ne s'applique pas en douce à une campagne où il n'a pas été éprouvé.

Même famille : l'écart signature → effet des décrets vaut **59 jours** sur le
premier acte d'un département et **183** sur le dernier. Même convention, même
population, trois fois moins. *Une moyenne calculée sur un bout de la
distribution ne vaut pas pour l'autre.*

---

## 12. Dénominateurs et ordres de grandeur

C'est la famille de fautes la plus fréquente du projet — sept occurrences
recensées.

### 12.1 L'ordre de grandeur attendu s'écrit AVANT la requête

`42` a posé trois fois de suite quelque chose de faux. Aucune de ces erreurs
n'était syntaxique, aucune n'était détectable en relisant le code : la requête
était bien formée et la base ne pouvait pas la contredire. **Ce qui les a
révélées est à chaque fois la taille du résultat** — 144, puis 21, quand la
population attendue était de 2.

> Un résultat se confronte à l'ordre de grandeur attendu, pas à sa plausibilité.
> Et l'attendu doit être écrit **avant**, sans quoi il s'ajuste au constaté.

D'où le garde-fou de `42`, qui n'est pas une règle mais une alarme : le fichier
lève une exception au-delà de vingt cas quand deux sont attendus. **Un saut d'un
ordre de grandeur ne signifie jamais que l'histoire a changé.**

### 12.2 Un taux sans son dénominateur est une opinion présentée comme une mesure

`p81_qualite` porte `pct_jamais_nommes`, le taux du § 7.4 recalculé département
par département : chaque ligne posée sait ce que vaut le report là où elle est
posée. Le banc a montré que cela ne suffisait pas — un département où trois
atomes seulement sont jamais-nommés y affichait **66,7 %**, aussi précis
d'apparence que les 94,9 % nationaux et sans aucune valeur.

Un seuil aurait décidé à la place du lecteur. **Le dénominateur voyage donc avec
le taux** (`atomes_jamais_nommes`), et une tranche « trop peu d'atomes pour un
taux » est isolée. Quatrième fois que le dépôt le paie : les villes à découper
(270 puis 369 puis 119), le vote de `75` à 333 %, le § 6 de `80`, et celui-ci —
le seul des quatre arrêté avant d'entrer en base.

### 12.3 Un taux supérieur à 100 % n'est pas un bon score

La résolution d'un canton de décret se juge à la part de sa liste retrouvée en
1999. Le compte se faisait sur les **lignes** de composition, alors que la même
commune y figure deux fois quand deux décrets la citent. Aureilhan, trois
communes, en « retrouvait » dix : 333 %.

Le défaut n'était pas cosmétique. Le seuil d'acceptation est à 80 % : un
dénombrement gonflé fait passer des cantons que la règle aurait dû refuser, et
**dans le sens permissif** — le seul où rien ne le signale ensuite.

*Un indicateur qui peut dépasser sa borne ne mesure pas ce qu'il prétend.* Quand
une part dépasse 100 %, ce n'est jamais le numérateur qui est bon.

**Et le même symptôme est revenu le soir même, d'une autre cause** : 367 % pour
le même canton, cette fois parce que le vote était agrégé **sans la période**.
D'où la leçon qui compte, et qui n'est pas la correction :

> Quand un même symptôme peut naître de plusieurs causes, il faut le rendre
> impossible, pas le corriger.

`75` § 5 ter lève désormais une exception sur tout taux supérieur à 100 %. La
vigilance avait déjà échoué une fois ; elle a échoué deux fois.

### 12.4 Le bon dénominateur est celui dont parle l'affirmation qu'on teste

Le § 6 raté de `80` et le § 6 quinquies posent **la même question aux mêmes
données**. Le premier agrège au département et rend un plateau : 88,31 / 91,27 /
88,75. Le second descend à la commune et rend **94,90 contre 33,49**.

> L'agrégation au département a détruit un signal de 61 points.

Ce n'est pas seulement que le premier test était mal construit : c'est que le
registre parle de **communes**, et qu'un département est un mélange de communes
touchées et intactes dans des proportions qui n'ont rien à voir avec le nombre
d'actes. Compter les actes, c'était mesurer la **fréquence** des décrets ; il
fallait mesurer leur **emprise**.

### 12.5 Une moyenne sur deux populations non séparées ne décrit aucune des deux

`83` § 4 rendait un écart moyen de **−14,8 ans** entre nos dates de création et
celles d'ANR, ce qui semblait ruiner l'affaire — tout en annonçant dans le même
souffle **357 lignes sur 427 tombant sur l'année exacte**. Les deux ne pouvaient
pas être vrais ensemble.

Ils l'étaient. La moyenne mêlait 359 vraies naissances et 68 **trous internes**,
pour lesquels `anr_debut` n'est pas une date de naissance mais le début de la
période d'avant le trou — souvent 1790. Comparer 1790 à une création de 1880
fabrique un écart de −90 ans, et soixante-huit lignes suffisent à noyer trois
cent cinquante-sept accords parfaits.

**Le compte exact était affiché à côté, et il disait le contraire ; c'est lui qui
avait raison.**

### 12.6 Un taux qui décroît vers zéro est presque toujours un artefact de construction

La « part non terminale » des polygones ANR passe de 28,1 % en 1790 à 0,0 % en
2019. J'y ai d'abord lu « la richesse éditoriale d'ANR est en amont ». C'est une
sur-lecture : un `Poly_ID` de la forme `1943_0A_…` signifie « valable jusqu'en
1943 », un `COMMUNE_…` est le polygone terminal — **plus on approche de 2020,
plus les polygones sont terminaux par construction**. Les 0,0 % de 2019 ne
mesurent rigoureusement rien.

Ce que la colonne mesure vraiment, c'est le **rythme des remaniements
communaux** : un fait d'histoire, pas une propriété du jeu. Sixième occurrence de
ce piège dans le dépôt.

### 12.7 Une absence se démontre, elle ne se constate pas

J'ai lancé `ls JORF | head`, vu dix noms de fichiers, et écrit que les PDF du
Journal officiel n'étaient plus sur disque. Il y en a **89**, et ils couvrent les
trente JO exploités. Sur cette lecture d'un échantillon promu en fait, j'ai bâti
une recommandation entière et proposé deux correctifs de repli dont l'un était
inutile.

> Une commande qui tronque par conception ne peut pas fonder une affirmation
> d'absence.

Le dépôt applique déjà cette règle aux données — un silence dans `acte_silence`
est une absence d'acte *dans notre liste*, pas une preuve de stabilité. Il faut
l'appliquer aussi à ce qu'on croit voir sur le disque. Même famille : *une année
absente d'un fichier de sortie n'est pas une année non lue* — les décrets de
1990-1999 avaient tous été dépouillés, et l'absence de 1990, 1992, 1994-96 dans
`composition_legifrance.csv` signifiait « rien à en tirer ».

### 12.8 Un attendu mesuré sur les CSV d'entrée ne décrit pas la base qui en sort

La recette de `82` attendait 40 atomes sans polygone ANR ; elle en a trouvé 486.
La cause n'était pas dans `82` mais dans **ce sur quoi les 40 avaient été
comptés** : `build/atom.csv` et `build/membership_canton.csv`, c'est-à-dire la
base telle qu'elle sort de l'extraction. La base réelle a été enrichie depuis par
`11`, `15`, `41`, `44` et `46`.

Septième confusion de dénominateur du dépôt, et la première où le dénominateur
fautif était le mien plutôt que celui d'une source. Même famille qu'une fausse
alerte antérieure : « 61 cantons annoncés, 73 mesurés » — le compte venait de
`build/unit_canton.csv`, qui ne porte que la part TRF-GIS. *Un compte tiré du
fichier de chargement n'est pas un compte de la base.*

---

## 13. Lire une source

### 13.1 Une irrégularité de la source est souvent la réponse, pas l'obstacle

Ousse et Sendets n'avaient aucun canton entre 1999 et 2002. `41` cherchait
l'attribution de leur mère, Idron, sur son atome plein — et n'y trouvait rien,
parce que le COG range Idron dans **deux** cantons sur cette période et que toute
son attribution vit donc sur des atomes-fractions, exclus par `NOT am.fraction`.

Le réflexe est de voir dans cette coupure une gêne. **C'était l'inverse.** Le COG
coupait Idron *parce qu'*elle contenait deux anciennes communes relevant de
cantons différents. La coupure était la trace, dans la nomenclature de 1999, de
la structure que le rétablissement de 2001 allait révéler. Il suffisait alors de
rapprocher deux faits que la source donne tous les deux : *la fille hérite de la
fraction dont l'unité est celle qu'elle porte elle-même une fois rétablie.*
Correspondance unique **six fois sur six**, y compris quand la mère est coupée en
trois.

> Devant une irrégularité de la source — une commune coupée, un code réutilisé,
> une date qui ne tombe pas sur une frontière de millésime —, demander d'abord
> *pourquoi la source la produit* avant de la traiter comme du bruit.

Une nomenclature administrative n'introduit presque jamais une complication
gratuite ; elle enregistre quelque chose. Le projet a déjà payé l'inverse : les
codes de canton réutilisés en 1871 enregistraient l'annexion, et la coupure de
Marseille en arrondissements enregistrait sa taille.

**Corollaire** : un garde-fou qui écarte les cas irréguliers écarte aussi
l'information qu'ils portent. `NOT am.fraction` était juste tant qu'il s'agissait
d'éviter une fraction ambiguë ; il devenait aveugle dès que la fraction était la
seule à savoir.

### 13.2 Avant de déclarer une source fautive, chercher l'événement qu'elle enregistre

Cherré, dans la Sarthe, figure dans la nomenclature TRF-GIS en 1885, manque en
1886 et 1887, revient en 1888 — ligne identique, même canton. J'y ai vu une
omission et écrit un correctif dont l'en-tête affirmait : « aucune commune n'a
jamais cessé d'exister deux ans pour renaître à l'identique ». Affirmation sur le
monde, sans fondement, et fausse. **La Ferté-Bernard absorbe Cherré en 1886 ;
Cherré reprend son indépendance en 1888.** La disparition n'était pas un trou
dans la source : elle *était* l'événement.

Et la nomenclature le disait, dans une colonne que je n'avais pas lue :
Saint-Antoine-de-Rochefort, absorbée le même jour et jamais rétablie, y porte dès
1885 le code INSEE de La Ferté-Bernard et le drapeau `com_act = 3`. **Le témoin
était à trois lignes du cas.**

Ce qui rend l'épisode instructif, c'est que **le correctif fautif donnait le bon
résultat** : La Ferté-Bernard est chef-lieu du canton de Cherré, donc refermer le
trou « parce que c'est la même unité de part et d'autre » pose exactement ce que
donne la règle juste. Aucune recette n'aurait bronché. Une commune absorbée par
une voisine d'un **autre** canton aurait produit le même trou, et la règle fausse
l'aurait rempli du mauvais canton, en silence.

> Une absence dans une source sérielle est une donnée avant d'être un défaut.

**Corollaire** : ne jamais fonder un correctif sur une généralité historique qu'on
n'a pas vérifiée. « Cela ne se produit pas » n'est pas un argument.

### 13.3 Une source qui nomme un fait ne vaut pas mieux qu'un pari mesuré si elle ne nomme pas LE fait

`11` prolonge vers 1870 le canton qu'une commune rejoint à sa création — un
**pari**, fait sans savoir de qui elle est issue. HAC nomme sa mère, pour 444
créations sur 447. Bâtir sur ce fait plutôt que sur un pari paraissait
évidemment meilleur : une source contre une supposition.

**C'était plus mauvais**, et `controle_gay.sh` l'a dit sans ambiguïté :

| | paris perdus | taux | atomes mal placés (1870) |
|---|---|---|---|
| pari par prolongement | 4 / 414 | 99,0 % | **151** |
| filiation nommée par HAC | 11 / 425 | 97,4 % | **155** |

La cause était écrite comme réserve dans le fichier de contrôle, et je n'y avais
pas assez cru : **HAC ne nomme qu'une mère quand il y en a plusieurs.** Pornichet
est créée en 1900 à partir d'Escoublac *et* de Saint-Nazaire ; HAC ne cite
qu'Escoublac. Le canton d'attribution à la création dit où le territoire se
trouvait administrativement ; la mère citée dit d'où vient la paroisse. **Deux
faits différents, dont un seul répond à la question posée.**

> Avant de remplacer une heuristique par une source, vérifier que la source
> répond à la MÊME question. Une donnée peut être exacte, sourcée, vérifiable —
> et hors sujet.

**Corollaire de méthode, et c'est lui qui a sauvé la mise** : le critère
d'acceptation avait été écrit **avant** l'essai. Sans ce seuil posé d'avance, la
tentation aurait été de garder un résultat « fondé sur une source » en expliquant
l'écart. *Un critère écrit après coup se plie toujours au résultat.*

### 13.4 Une source se juge par question, pas en bloc

Le fichier historique du COG 1999 était connu du dépôt depuis le 9 août, et jugé :
il ne contient que 66 changements de canton, tous postérieurs à 1995, donc aucune
reconstitution de 1943-1995 n'est possible par cette voie. C'était exact, et c'est
resté la seule chose qu'on en disait pendant vingt jours.

Or il portait, pour chacun de ces 66 mouvements, la **date d'effet** et le canton
d'arrivée codé — c'est-à-dire précisément ce qui manquait à cinq transferts en
attente d'une convention. Treize fois plus de communes, et une date qui est un
fait.

> Une source trop pauvre pour combler un trou peut être exactement assez riche
> pour dater ce qu'on a déjà. Le verdict porté sur une source répond à la
> question qu'on lui posait ce jour-là.

### 13.5 Un champ de confort n'est pas une source

Le contrôle croisé de `77` comparait le canton nommé par un décret au nom porté
en base, et rendait un écart : « Bourgoin-Jallieu - Sud » contre « Bourgoin ». Le
canton était le bon — le code, confirmé par le COG. C'est le **champ lu** qui ne
l'était pas.

`unit.nom` est documenté depuis `01_schema.sql` comme « dernier nom connu
(dénormalisé, confort) » ; le nom d'époque vit dans `unit_version` et se lit par
`unit_nom(unit_id, date)`. Le dépôt avait la fonction et le contrôle ne s'en
servait pas.

C'est l'inverse du défaut habituel : au lieu de masquer une erreur, un mauvais
champ en **fabrique** une. Le coût est le même — on va chercher une faute là où
il n'y en a pas, et on finit par douter d'une lecture juste.

### 13.6 Une date au jour près prime sur un millésime annuel

`insee_mvt` date le rétablissement d'Ousse au 11 mars 2001 ; la couche moderne,
bâtie sur les millésimes annuels du COG, ne la connaît qu'au 1ᵉʳ janvier 2002.
Dix mois de vide qui ne correspondent à aucun fait.

> Quand deux sources datent le même événement à des granularités différentes, la
> plus fine fait foi, et l'écart se comble en reportant en arrière ce que la
> source grossière affirme — **sans jamais inventer une valeur**.

Le report doit être **borné à ce que la règle explique** : ici au premier
1ᵉʳ janvier suivant l'acte, c'est-à-dire à l'artefact de millésime et rien
d'autre. Voir § 15.3 pour ce qu'aurait coûté l'absence de borne.

### 13.7 Une lecture linéaire d'un texte sur deux colonnes attribue au hasard

Les JO numérisés sont sur deux colonnes, et l'extraction les a fondues **ligne à
ligne** : chaque ligne de `jorf_txt/` porte la colonne de gauche puis celle de
droite. Deux décrets voisins s'y trouvent entrelacés, et le contenu de l'un
paraît **avant son propre en-tête** — vérifié sur le JO du 22 janvier 1982, où le
décret n° 82-56 a son texte aux lignes 258-289 et son titre à la ligne 324.

Le symptôme ressemble à une coupure mal placée ; la cause est une mise en page, et
elle est systématique.

> Avant d'accuser la segmentation, vérifier que le texte qu'elle lit est dans
> l'ordre où il a été écrit. L'ordre d'un fichier texte paraît une évidence ; il
> est une hypothèse, et elle se teste en comparant la position d'un en-tête à
> celle de son contenu.

Correction (`cantons/jorf_colonnes.py`) : couper au blanc vertical qui sépare les
colonnes. Inversions de 88 à 46 sur les 30 JO exploités, pour huit en-têtes
perdus sur 548. **Un gain net, pas une cure** : les 46 restantes demanderont
autre chose.

### 13.8 Une réparation qui repasse par la source rend une source différente

Premier essai de la correction ci-dessus : rappeler `pdftotext` avec une boîte de
découpe par colonne. L'ordre était rétabli — et le texte abîmé, parce que le
clipping **rend à nouveau la page** et perd tout ce qui touche la coupure.
L'extraction tombait de 4 706 à 4 414 lignes. On rétablissait l'ordre en
détruisant le contenu.

La bonne réparation ne redemandait rien : couper le texte **déjà rendu**. Mêmes
octets, autre ordre.

> Quand un défaut porte sur l'ORDRE d'un texte, il se répare dans le texte. Y
> retourner par l'outil qui l'a produit, c'est accepter une seconde lecture — et
> une seconde lecture n'est jamais la même.

**Corollaire éprouvé le même jour** : *un repli doit être le moins mauvais des
états connus, pas le premier sous la main.* Les pages où aucune gouttière n'était
trouvée étaient recopiées depuis le `-layout`, c'est-à-dire dans la forme
entrelacée qu'on cherchait justement à fuir. Une seule page faisait perdre le
canton de Friville-Escarbotin et ses neuf communes.

### 13.9 On ne réduit pas le nombre de preuves, on écarte celles qui n'en sont pas

Le vote qui contredit l'ancre d'un décret parcourait tous les mots capitalisés du
segment. Or un canton urbain est décrit par des **rues** : « rue Saint-Laurent »,
« place Sadi-Carnot » existent aussi comme communes ailleurs en France, et elles
votaient. Marseille-I, dont l'ancre était juste et à trente lignes de là, s'est
retrouvé en Haute-Savoie.

Deux corrections ont été essayées et **mesurées** : voter sur les seules communes
lues (Marseille rentre, le contrôle par les titres reperd ce qu'il avait gagné) ;
refuser toute voix aux cantons sans communes entières (Marseille rentre,
Lorient-Centre repart dans le Cantal). Les deux cas s'opposaient, et c'est cela
qui a donné la règle : à Marseille l'ancre a raison, à Lorient c'est le vote. Ce
qui les départage n'est pas la **quantité** de preuves mais leur **qualité** — un
canton sans communes entières vote avec les deux seuls noms que le décret lui
donne.

> Une correction qui marche sur un cas et casse l'autre n'est pas trop faible :
> elle est mal posée. Il faut chercher ce qui distingue les deux, pas doser entre
> eux.

### 13.10 Remonter la chaîne jusqu'à la source avant d'accuser un maillon

La carte affichait « Orl<?><?>ans-Est » : deux caractères U+FFFD là où il n'y a
qu'un « é ». Le réflexe est de soupçonner l'affichage, puis l'export, puis le
chargement. Les octets fautifs sont présents **à chaque étage, y compris le
premier** : `COG_CANTONS_*_MAPPING.tab` porte déjà `EF BF BD EF BF BD`. Notre
chaîne transporte fidèlement une donnée détruite avant de nous parvenir.

La vérification coûte quatre commandes et se fait **dans l'ordre inverse du
flux** — carte, export, base, `build/`, source. On s'arrête au premier étage
sain : le défaut est né juste après. Ici on ne s'est jamais arrêté, ce qui est la
réponse la plus utile : elle exclut d'un coup tout le code du dépôt.

Deux U+FFFD pour une lettre est en outre une **signature lisible** : un seul
aurait désigné du Latin-1, deux désignent de l'UTF-8 mal relu.

**Et : ne pas mêler deux régimes de preuve dans le même fichier.**
`37_reparer_encodage.sql` répare du Windows-1252 lu en Latin-1 par une table
**bijective**, et son en-tête le revendique : « aucune ambiguïté, aucun choix ».
Y ajouter quatre noms reconstitués aurait ruiné cette garantie.
`50_noms_perdus_trfgis.sql` les porte donc à part, avec sa propre justification —
la lettre perdue est contrainte par ce qui reste (« Orl__ans » n'admet qu'une
lecture), le département et le millésime concordent. C'est de l'orthographe, pas
une attribution.

### 13.11 Le référentiel bouge et se déguise en événement

La Corse recodée 20 → 2A/2B en 1976, la Seine et la Seine-et-Oise démembrées en
1964, Marseille et Lyon repliées en pseudo-cantons : **rien de tout cela n'est un
mouvement cantonal, et rien de tout cela n'échoue à un contrôle de cohérence.**
160 lignes du registre cantonal en relèvent, et rangées d'abord parmi les
créations tardives, elles en inventaient 120. Même piège que les 22 atomes
« déplacés » de `35`, ramenés à 8.

> Avant de déclarer un événement, vérifier que le référentiel n'a pas bougé.

C'est aussi le recodage qui a fait échapper Chisa et Butry-sur-Oise à `15`
(§ 6.2 quater) : la résolution des codes doit être **transitive** — quatre codes
sont recodés deux fois de suite.

---

## 14. Territoires, atomes et clés

### 14.1 Interroger un atome ne renseigne pas sur un territoire

Un polygone peut être porté par **plusieurs atomes** — c'est une conséquence
directe de l'architecture (§ 2), pas un accident. Il en découle deux fautes
symétriques, produites le même jour dans deux fichiers différents :

* `41` posait des rattachements sur un atome dont le polygone était déjà porté
  par un autre, **rattaché à la même unité** : le canton comptait le territoire
  deux fois, trois pour Val-de-Meuse. Aucune recette d'unités ne le voyait,
  puisqu'il n'y avait pas de contradiction ;
* `42` cherchait les territoires non rattachés en interrogeant **un seul** des
  atomes portant le polygone : un atome moderne non rattaché en 1870 suffisait à
  faire croire à un trou là où un atome historique couvrait déjà. 21 communes
  candidates au lieu de 2.

> Toute question portant sur un TERRITOIRE — est-il couvert ? est-il rattaché ? à
> quelle unité ? — se pose sur l'ensemble des atomes qui le portent, jamais sur
> un atome pris isolément.

Le test de couverture de `10_couverture.sql` — un point intérieur contenu dans un
polygone d'atome — est le bon quantificateur ; l'identité d'un atome ne l'est pas.

**Corollaire, appris en le manquant** : `ST_Contains` et `ST_Equals` ne répondent
pas à la même question. `ST_Contains(atome, point)` dit « ce territoire est-il
couvert » ; `ST_Equals(atome, commune)` dit « quel atome EST cette commune ».
Employer le premier pour le second accroche toute fraction et tout polygone
englobant — 144 cas au lieu de 2.

**Même racine, quatrième occurrence** : un « recouvrement » à Moyenvic venait
d'une recette groupant par `insee_geofla`. Moyenvic porte deux atomes Cassini
distincts, deux communes de 1870 fondues depuis, chacune dans son canton. La
recette groupe désormais par `atom_id`, et rend 0. Le même geste avait donné 369
villes à découper au lieu de 119.

### 14.2 Grouper par la géométrie, jamais par un code

`code_2011` est une reconstruction, l'empreinte est un fait. Regroupés par
`md5(ST_AsEWKB(geom))`, les comptes par nomenclature reproduisent **exactement**
les mesures géométriques (§ 6.1) — l'écart de 108 km² était entièrement une
affaire de clé, aucune attribution en cause.

Conséquence pratique pour toute carte : plusieurs communes de 1870 fondues depuis
en une seule partagent un unique polygone de 2011. Dans les
Alpes-de-Haute-Provence, Espinouse, Saint-Jurson et Le Chaffaut portent les mêmes
29,75 km². Dessinées séparément, elles s'empilent — trois libellés au même
endroit, sans que rien ne l'indique.

Gain non cherché depuis ANR : **l'empreinte de regroupement devient datée.** Deux
atomes que la trame de 2011 confondait peuvent en avoir deux distincts en 1870 —
c'est précisément le mécanisme qui fait tomber le recouvrement de 3 945 à
101 km².

### 14.3 L'empreinte constate un partage, elle ne teste pas une identité

L'appariement des mères de `15` par empreinte binaire était trop strict :
`ST_UnaryUnion` peut **renormaliser une représentation sans changer la
géométrie**, ce qui faisait perdre Val-de-Reuil et Marcheprime. Corrigé par
`ST_Equals` avec repli sur `insee_geofla` — 57 mères sur 58 sont trouvées par les
deux voies, une seule par le code : le repli **complète** l'empreinte, il ne la
remplace pas.

> L'empreinte binaire est la bonne clé pour constater qu'un polygone est partagé,
> pas pour tester qu'il est le même. Identité de représentation et identité
> géométrique sont deux choses.

Corollaire du même épisode : le test « commune sans atome » comparait des
empreintes de polygones **entiers**, si bien que les 16 arrondissements de
Marseille en ressortaient comme non couverts alors que l'atome `union_prefixe`
porte leur **union**, qu'aucune empreinte de composant n'égale. Ils n'ont pas nui
— leur mère `13055` n'existe pas dans GEOFLA — mais **par chance, pas par
conception** : la recette d'alors n'aurait pas vu le double comptage. *Une
recette incapable d'attraper l'erreur qu'elle vise n'est pas une recette.*

### 14.4 Une borne qu'on n'interroge pas produit un silence, pas une erreur

`export_web.py` portait depuis toujours cette phrase en tête : *la géométrie d'un
atome ne change jamais.* Toute son architecture en descendait —
`communes.json` écrit une fois par département, signature portant sur la seule
composition, `annees_candidates()` ne lisant que les bornes de `membership` et
d'`unit_version`.

`atom_geom_anr` rend les trois faux d'un coup. Brancher la nouvelle source sans
toucher au reste aurait produit une carte qui se trompe **en silence** : deux
années de même composition mais de formes différentes auraient partagé le même
fichier, et une édition de polygone tombant une année sans mouvement
administratif n'aurait **jamais été échantillonnée** — le changement n'aurait pas
existé dans l'export, et aucune recette n'aurait pu le remarquer, puisque rien
n'aurait été demandé à la base.

> Le défaut n'est pas dans ce qu'on calcule, il est dans ce qu'on a omis de
> demander.

Même mécanisme que le trou de la couche circo et que le 0 rattachement au
1ᵉʳ juin 2012. **Et le pendant en écriture** : un intervalle sans géométrie doit
s'écrire **comme vide** (`g: null`), pas être sauté, parce que la page tient la
version en vigueur jusqu'à la suivante — *ne rien écrire n'est pas neutre quand
le lecteur en aval prolonge.*

### 14.5 Une signature d'entrée n'est pas une signature de sortie

La signature d'entrée de l'export est conservatrice : une commune qui perd un
hameau au profit d'une voisine du **même canton** change de `poly_id` sans
déplacer le contour cantonal d'un pouce. Signer sur l'entrée seule écrivait deux
fichiers identiques sous deux noms.

> Une signature d'entrée dit ce qu'il faut **recalculer**, une signature de
> sortie dit ce qu'il faut **réécrire** ; prendre l'une pour l'autre coûte soit
> des calculs inutiles, soit des fichiers en double.

Le nom de fichier est donc le md5 du **contenu sérialisé**. Sur un cas fabriqué :
six compositions calculées, deux fichiers écrits.

**Point voisin, de même famille** : la coïncidence des limites cantonales et
communales exige non seulement le même **ordre d'opérations** des deux côtés,
mais la même **source** — sinon un canton dessiné sur la forme d'ANR longerait
des communes dessinées sur la forme de 2011, et la lisière serait un artefact de
tuyauterie.

### 14.6 Un identifiant d'atome n'est pas un code INSEE, et les deux se ressemblent

`atom_id` vaut le code Cassini pour une commune entière — une suite de chiffres,
donc **indiscernable à l'œil d'un code INSEE**. Le dépôt s'y est fait prendre
trois fois, et chaque fois le symptôme a été le même : une requête bien formée
qui rend **zéro**, lu comme une absence.

* `45` § 5 filtre sur `insee_geofla` pour retrouver Houat et Hœdic ; les valeurs
  citées, `17501` et `17191`, sont des `atom_id`. Les deux paris n'y
  apparaissent donc jamais.
* Une note du dépôt désignait la ligne de `38_decret_1982_ain.sql` par « `31125`
  dans le canton `0138` ». `31125` est un `atom_id` ; Saint-Denis-les-Bourg
  porte l'INSEE `01344`, et `31125` lu comme un code INSEE tombe en
  Haute-Garonne. Un diagnostic écrit sur cette note a conclu « ligne absente »
  sur une base où elle pouvait très bien être présente.

> Un zéro obtenu en comparant une clé à une colonne qui n'est pas la sienne ne
> se distingue en rien d'un zéro vrai. Avant de conclure à une absence, vérifier
> que l'identifiant appartient au domaine de la colonne interrogée.

Le contrôle le plus court : un `atom_id` de commune entière existe dans
`atom.atom_id` ; un code INSEE existe dans `noms_geofla.insee`. Un identifiant
qui n'est dans ni l'un ni l'autre est une erreur de recopie, pas une donnée
manquante.

### 14.7 Les grandes villes sont codées par arrondissement, et zéro n'a pas l'air d'une erreur

Marseille, Lyon et Paris sont codées 13201-13216, 69381-69389 et 75101-75120 —
jamais par 13055, 69123 ni 75056. C'est vrai dans **GEOFLA, dans CONTOURS-IRIS et
dans le codage parisien** : trois sources indépendantes, trois fois la même
chausse-trappe.

Ce qui la rend dangereuse : **un zéro n'a pas l'air d'une erreur.** Pour une
commune de 3 000 habitants, zéro IRIS est la bonne réponse. L'anomalie n'a été
visible que parce qu'elle frappait les deux plus grandes villes du lot ; sur une
ville moyenne elle serait passée pour un fait, et trois coupes auraient été
tracées sans trame en croyant qu'il n'y en avait pas.

> Un résultat nul se confronte à l'ordre de grandeur attendu, pas à sa
> plausibilité.

---

## 15. Règles, garde-fous et conventions

### 15.1 Un garde-fou juste peut se tromper de cible

Le garde-fou 4 de `11` interdit de franchir une interruption de l'unité
d'accueil, pour une raison mesurée : en Alsace-Moselle, une interruption peut
cacher deux cantons différents sous une même clé (§ 6.2 ter).

**Le même garde-fou, appliqué aux circonscriptions, produit un défaut.** Une
interruption de circonscription ne signale pas une rupture de territoire mais
**l'alternance du mode de scrutin** : le segment uninominal n'a pas de membres
pendant les législatures élues au scrutin de liste. Le territoire, lui, n'a jamais
cessé d'appartenir à une circonscription. Coût mesuré : 356 atomes, et un trou de
couverture de 598 atomes à 1870 au lieu de 291. La signature ne laissait aucun
doute — les blocages tombaient exactement sur les bascules de régime : 1889 (104
atomes), 1876 (86), 1919 (59), 1928 (43), 1885 (19).

> Un garde-fou est écrit contre un mécanisme précis. En le transposant à une
> autre couche, vérifier que le mécanisme s'y retrouve.

**Corollaire : préférer un pont déjà vérifié à une reconstruction.** Le correctif
avait besoin de savoir de quelle commune une commune nouvelle était issue.
Reconstruire la filiation par la géométrie est un chantier ; la solution retenue
passe par **le canton**, que `11` avait déjà prolongé correctement, et demande son
avis aux voisins de canton — **en ne posant que s'ils sont unanimes**. Mesuré
avant d'écrire : 87,7 % d'unanimité, 12,3 % d'abstention, **zéro cas ambigu**.
Une règle qui ne tranche jamais un conflit et se tait quand elle ne sait pas coûte
quelques points de couverture et ne fabrique aucune erreur.

Vérification décisive : Arrien-en-Bethmale reçoit **exactement** la chaîne de
Bethmale, sa mère, alternances de scrutin comprises — sans que la filiation ait
été cherchée nulle part. Même signature pour Chisa recevant celle de Ventiseri.

### 15.2 Un garde-fou qui rattrape une règle fausse donne un résultat juste et une méthode fausse

Le commentaire de `41` annonçait 21 cas, la requête en a sorti 38 : elle prenait
tout mouvement `mod = '21'` postérieur à 1999 **sans jamais croiser la liste des
communes absentes du COG 1999**, qui était pourtant l'ensemble décrit trois
paragraphes plus haut.

Le résultat était pourtant presque juste, parce qu'un garde-fou refusait de poser
sur une période déjà occupée : 12 intrus sur 14 tombaient d'eux-mêmes. **Ils
tombaient pour la mauvaise raison** — la période était prise, pas la fenêtre
fausse — et il restait exactement les cas où la commune existait *et* avait un
trou dans son propre rattachement : cinq lignes fausses.

> Un garde-fou protège la base d'une contradiction, il ne rend pas une règle
> vraie. Quand un contrôle rattrape la quasi-totalité des cas qu'une règle admet
> à tort, c'est la règle qu'il faut réparer — sans quoi le prochain cas qui
> échappe au contrôle passe, et il passera silencieusement puisque tout sera
> cohérent.

**Corollaire de rédaction** : le commentaire décrivait un ensemble que la requête
ne calculait pas. *Quand un fichier annonce un dénominateur, la requête doit le
produire, et une recette doit le compter.*

### 15.3 Une règle vraie appliquée au-delà de son domaine produit une donnée fausse et cohérente

Le report de § 13.6 devait être borné au premier 1ᵉʳ janvier suivant l'acte.
Sans cette borne, le premier jet reportait *n'importe quel* rattachement
ultérieur : Ouézy, rétablie en 2006, recevait dès 2006 la circonscription issue
du découpage de **2009**, sur une période libre qu'aucun garde-fou n'aurait
refusée. Vérifié : les onze cas tombent tous sur le 1ᵉʳ janvier suivant, sans
exception. Le plus court est Paroy-en-Othe, rétablie le 31 décembre 2003 : son
trou durait **un jour**.

### 15.4 Un couperet muet décide plus qu'une règle

Un plafond de 400 caractères sur une liste de communes faisait disparaître le
canton de Bonnières-sur-Seine et ses 26 communes — la liste en faisait **401**.
Ni sortie, ni rejet, ni message : le canton n'existait simplement pas. Le plafond
gardait contre un cas réel — une amorce qui avale la page — mais il tranchait
sans le dire, et il tranchait serré. Deux autres défauts du même fichier tenaient
à un caractère du même ordre.

> Toute limite numérique qui peut supprimer un objet doit le signaler. Une limite
> qui rejette en silence n'est pas un garde-fou, c'est une décision cachée — et
> elle se découvre par hasard, des mois plus tard, en cherchant autre chose.

Même famille, formulée positivement : **on signale, on ne supprime pas.** C'est
cette règle qui a sauvé la passe OCR « perdante » de 1968 — psm 6 et psm 4 ne se
recouvrent qu'à 89 %, et leur **union** vaut +2 756 communes, faisant passer le
rappel de 84,0 % à 91,4 %. Le gain décisif n'est pas venu du réglage mais du fait
de **conserver deux lectures imparfaites au lieu d'en choisir une**.

### 15.5 Une convention doit être lisible comme une convention

Les décrets cantonaux de 1973, 1982 et 1985 ne portent aucune clause d'effet. La
base a pourtant besoin d'une borne basse. La convention retenue — **le premier
tour du renouvellement des conseils généraux qui suit la signature** — est
solide : chaque salve est signée quelques semaines avant un scrutin, et le seul
décret du lot qui le dise en toutes lettres dit exactement cela. Elle reste une
convention, et elle peut se tromper de trois ans : les conseils généraux se
renouvelaient par moitié, et la série d'un canton nous est inconnue.

> Ce qui n'est pas dans la source doit être visible **dans la base**, pas
> seulement dans la documentation. Une note de bas de page se perd ; une colonne
> se joint.

`p75_qualite` porte donc `convention`, `serie_inconnue` et `decalage_max_annees`
sur chaque ligne posée, comme `c68_qualite` porte la qualité de lecture de 1968.

**Corollaire** : quand la source lève le doute pour une partie du corpus, on ne
l'étend pas au reste. Un acte dont l'objet est `creation de cantons` fixe sa
propre date d'effet — le canton entre en vigueur au scrutin qui l'élit. Un acte
`creation et modification` ne le fait pas. Le discriminant ne tranche que dans un
sens, et le doute reste inscrit partout où il n'est pas levé.

### 15.6 Un refus juste peut avoir un motif myope

`75` a refusé la collision « Laval - Nord-Ouest / Laval - Sud-Ouest » au motif que
deux cantons du décret désignaient la même unité de 1999. **Le refus était bon,
le motif ne l'était pas** : le décret du 24 décembre 1984 remplace ces deux
cantons par quatre autres définis uniquement par des portions de la ville, et les
six communes rurales de 1973 se retrouvent ensemble en 1999. La résolution
n'échoue pas parce que la lecture est douteuse, mais parce qu'**un acte est passé
entre les deux dates** — et le registre le savait déjà.

> Un motif de refus qui décrit le symptôme empêche de compter les cas.

Nommer la cause les rend dénombrables : `75` § 11 croise désormais le verdict avec
le nombre d'actes intercalés. La résolution tombe de 63,6 % (aucun acte) à 52,9 %
(un ou deux) et 50,8 % (au-delà). **Les refus cessent d'être du bruit et
deviennent une prédiction** — celle de ce que la salve suivante fera gagner.

### 15.7 Une clause qui départage ne doit pas conditionner

`27` et `28` raccordaient une ligne source à son atome ainsi :

```sql
JOIN atom a       ON a.insee_geofla = s.insee
JOIN membership m ON m.atom_id = a.atom_id AND m.niveau = 'canton'
                 AND m.periode @> '2012-06-01'
```

**La jointure était interne** : l'atome devait avoir un canton à cette date pour
être retenu. Or le canton n'a jamais servi qu'à **départager** plusieurs atomes
portant le même code INSEE ; une commune qui n'en a qu'un n'a pas à l'être.
Bihorel, fusionnée le 1ᵉʳ janvier 2012, sortait sans un mot — comptée parmi les
« lignes source sans atome », un chiffre que les fichiers affichaient et que
personne ne lisait. `LEFT JOIN` et `DESC NULLS LAST` : la préférence demeure, la
condition disparaît. 71 et 60 lignes perdues ramenées à zéro.

> Une clause de préférence exprimée comme une clause de sélection élimine
> silencieusement ce qu'elle devait seulement classer.

**Et ce qui la rendait invisible : une dépendance croisée.** `41` a besoin des
unités que `27` et `28` créent — d'où sa place tardive dans la chaîne — mais
`27` et `28` avaient besoin d'une ligne que `41` est seul à poser. Aucune
recette ne pouvait le voir : le résultat était cohérent, simplement incomplet.

### 15.8 Un garde-fou évalué à l'exécution ne protège pas d'une erreur d'analyse

`83` gardait l'accès à `scission_trace` derrière un
`CASE WHEN to_regclass('histgis.scission_trace') IS NULL THEN NULL ELSE …`. Le
banc n'a pas cette table, et il a refusé le fichier : `ERROR: relation
"scission_trace" does not exist`. **PostgreSQL résout les relations à l'analyse
de la requête**, avant d'évaluer la moindre branche. Il a fallu du SQL dynamique
dans un `DO`.

---

## 16. Hygiène d'exécution

**Exécuter avant de livrer, même sur une base fabriquée.** `72` et `73` ont été
livrés sans avoir été exécutés, faute de PostgreSQL dans l'environnement
d'écriture. La réserve était portée au journal, ce qui était honnête, mais elle
reportait sur Adrien le travail de trouver les erreurs de syntaxe.
`sql/banc_75.sh` monte un PostgreSQL embarqué (`pip install pgserver`), y pose le
**schéma réel** et joue les fichiers sur les **vrais** CSV. Il a rendu trois
défauts qu'aucune relecture n'avait vus, dont un qui produisait un résultat
cohérent et faux. `banc_81.sh` et `banc_82.sh` suivent le même dispositif ;
`banc_82` en a trouvé quatre de plus, dont aucun n'était visible à l'œil.

Deux extensions manquent à ce PostgreSQL : `postgis`, hors sujet, et
`btree_gist`, sans laquelle les `EXCLUDE` ne se créent pas. Elles sont
**remplacées par des déclencheurs qui refusent les mêmes lignes** — ce qui
importe est le comportement, pas le mécanisme. Ce que le banc ne prouve pas doit
être dit aussi : ses effectifs sont ceux d'une couche synthétique, et il ne dit
rien du **coût** des requêtes (§ 11.6).

**Tout fichier qui écrit a une table de trace**, et il retire son passage avant
de recommencer. `38_decret_1982_ain.sql` et `39_meurthe_1870.sql` ont été les
deux dernières exceptions, et elles ont coûté cher : rien dans la base ne disait
s'ils étaient passés, et `39` a été défait par un `rebuild.sh` sans que rien ne
le signale pendant quinze jours. **Dette soldée le 2 septembre 2026** —
`p38_trace`, `p39_trace`, éprouvées par `sql/banc_38_39.sh`. Trois choses
apprises en les écrivant :

* **Une trace se cale sur ce qui NE bouge PAS.** `39` change le département des
  29 cantons de la Meurthe ; viser `dep = '99'` aurait donné une trace vide sur
  une base déjà conforme, donc le verdict « joué puis défait ? » sur une base
  saine. La trace vise l'`unit_id` `99xx`, qui ne bouge jamais. *Une trace calée
  sur ce que le fichier modifie est vide dès que le travail est fait.*
* **Une MISE À JOUR ne se défait pas par un DELETE.** Les deux fichiers
  modifient des lignes autant qu'ils en posent. La colonne `avant` garde la
  valeur d'origine ; sans elle, la trace sait dire qu'on est passé mais pas
  revenir en arrière — une demi-trace.
* **L'idempotence protège du rejeu, pas de l'oubli.** C'est l'argument qui avait
  dispensé `39` de trace, et il était faux : un fichier idempotent qu'un
  `DROP SCHEMA` a emporté se tait exactement comme un fichier qui vient de
  réussir. Zéro ligne modifiée, code de retour nul, dans les deux cas.

**Poser l'objet et sa trace dans la MÊME instruction**, via `RETURNING`, et
lancer tout script qui écrit avec `psql -1`. Un `NULL` non casté a laissé 25
atomes committés et non tracés, donc invisibles au retrait.

**Une table de trace ne sert pas qu'à défaire.** La recette 6 de `40` reconstitue
l'état d'avant à partir de la trace : `trou_avant = trou_résiduel + atomes
couverts`. C'est ce qui permet de répondre encore à une question qu'on ne s'était
pas posée avant d'agir.

**`csv.writer` termine ses lignes en `\r\n`.** Tout script qui complète un CSV du
dépôt doit passer `lineterminator='\n'`, sinon `COPY` refuse le fichier.

**Une union géométrique n'est pas nécessaire pour connaître une surface** quand
on sait déjà ce qui se recouvre : la somme des aires moins le recouvrement donne
le même nombre en une ligne, là où `ST_UnaryUnion(ST_Collect(geom))` sur 37 618
multipolygones épuise la mémoire.

**Le découpage d'un traitement parallèle s'arrête à l'unité qui écrit seule dans
son dossier.** Deux processus se partageant les configurations d'un même
département devraient s'accorder sur le dédoublonnage par contenu, donc se
parler. Et une connexion ouverte **avant** le fork partage ses descripteurs : en
contexte `spawn`, chaque worker ouvre la sienne. Un département qui échoue rend
son erreur comme une donnée, le parent la compte et le script sort en 1 — **un
export incomplet qui ressemble à un export complet serait pire qu'un export
absent.**
