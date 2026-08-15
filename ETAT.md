# État du projet — reprise de conversation

Trois documents, trois rôles : **`ETAT.md`** (ici) dit où en est la base et
quoi faire ensuite ; **`METHODE.md`** est la référence stable — sources,
chaîne, limites ; **`JOURNAL.md`** raconte dans l'ordre ce qui a été tenté,
raté et compris.

Dernière mise à jour : 9 août 2026, après `12` à `15` — les désaccords résiduels
sont expliqués, et le territoire non couvert est tombé à 293 km² en 1870.

## Où on en est

La base `histgis` est **complète pour 1870-1940** : attributions et
géométries, interrogeable à n'importe quelle date. Elle tourne en local sur la
machine Linux (`~/Téléchargements/projet_carte`), PostgreSQL + PostGIS,
schéma `histgis`.

Tout se recharge de zéro avec `sql/load.sh` puis `05` → `06` → `07`. Voir
`sql/README.md` pour le détail des commandes.

## Contenu de la base

| Table | Lignes |
|---|---|
| `atom` | 38 442 (dont 333 fractions de commune) |
| `atom_geom` | 38 442 — aucun trou |
| `unit` | 4 838 (3 066 cantons, 1 772 circonscriptions dont 132 provisoires) |
| `unit_version` | 5 057 |
| `membership` | 293 233 |
| `regime_electoral` | 71 années |

Intégrité assurée par deux contraintes `EXCLUDE USING gist` : un atome
n'appartient qu'à une unité par niveau à un instant donné, deux versions d'une
même unité ne se chevauchent pas. Validées sur la vraie base, pas seulement en
théorie.

## Ce qui a été validé

Les effectifs recoupent l'histoire à chaque date testée : 89 départements en
1870, 87 après la perte de l'Alsace-Moselle, 90 après 1919 ; 2 862 à 3 028
cantons ; bascules liste/uninominal aux bonnes années (1876, 1885, 1889…).
1 690 atomes ont un trou de chronologie de 1871 à 1919 exactement — c'est
l'Alsace-Moselle, et c'est une validation, pas une anomalie.

Zéro chevauchement, zéro orphelin, couverture canton/circonscription complète,
zéro géométrie invalide. Rapport complet dans `rapport_chargement.txt`.

## Décisions prises, et pourquoi

**Géométrie et attribution découplées.** La géométrie vit au niveau de
l'atome, l'attribution dans `membership` avec des intervalles
`[valid_from, valid_to)`. Rien n'est pré-dissous : `snapshot_geom(date)` fait
l'union à la demande. C'est ce qui permettra d'absorber ANR-COMMUNES sans
retoucher aux attributions.

**`--geom-col insee`, pas `com_act`.** Le codebook TRF-GIS définit `com_act`
comme un statut (1 actuelle, 2 ancienne post-1943, 3 ancienne pré-1943), pas
un code commune. Le build a été relancé avec `--geom-col insee`. Le loader
accepte les deux formats et range la valeur dans la bonne colonne.

**Rattrapage des communes disparues.** 1 504 codes INSEE d'époque absents de
GEOFLA 2011, dispersés (un quart des cantons amputés à une date donnée),
concentrés dans les départements de la loi Marcellin. Résolus par les
mouvements de communes de l'INSEE rejoués jusqu'au 1ᵉʳ janvier 2011 (1 487),
puis par HAC pour les 17 antérieurs à 1943.

**Ce qui n'a pas marché, pour ne pas y revenir :** `ID_GEOFLA.tab` n'est que
la table attributaire du shapefile ; `insee_former.do` n'est que de
l'harmonisation de noms ; HAC ne contient aucun code INSEE. Gay apparie par
nom contre le COG 2005 — piste abandonnée au profit des mouvements INSEE.

## Limites connues, à mentionner en note de méthode

**218 communes revendiquées par plusieurs cantons** au 1ᵉʳ juin 1885, soit
0,6 % — donc autant de zones où deux cantons se recouvrent. Le contrôle Gay en
donne la mesure en surface : **3 945 km² comptés deux fois en 1870**, 4 036 en
1940 (somme des cantons 546 221 km² pour une union de 542 276). Deux causes : les
communes historiques fusionnées depuis partagent un code INSEE, et les
communes éclatées entre cantons n'ont pas de géométrie propre. Inhérent à la
trame : une géographie de 2011 ne découpe pas plus fin qu'elle-même. TRF-GIS
a la même limite. Invisible à l'échelle départementale, visible au zoom.

**6 atomes en `source = 'hac_partage'`** : commune répartie entre plusieurs
successeurs, le premier nommé a été retenu. Choix arbitraire, tracé comme tel,
révocable. Liste dans `sql/07_reliquat.sql`. Le contrôle Gay en invalide 3 sur
6 — une fois sur deux, comme le hasard le laissait craindre.

**132 circonscriptions `provisoire = true`** : citées par le membership mais
absentes des nomenclatures TRF-GIS (Paris `U7580`/`U7581`, Bouches-du-Rhône
`U1381`), 134 rattachements. Ce sont des pseudo-circonscriptions
d'arrondissement urbain écartées à l'extraction. Créées sans nom pour ne pas
perdre l'information. À reprendre côté extracteur si leurs noms sont voulus.

**`atom.com_act` est vide** depuis le passage à `--geom-col insee` :
l'extracteur n'écrit qu'une colonne. Le statut est reconstituable depuis les
`COG_COMMUNES_YYYY.txt` si besoin.

## Contrôle indépendant : fait, et concluant

`sql/controle_gay.sh` compare `snapshot_geom()` aux cantons déjà dissous par
Victor Gay (`CANTONS_1870.zip`, `CANTONS_1940.zip`) — des polygones qui ne
passent par aucune ligne de notre code. Une commande, sur la machine où tourne
la base :

```bash
cd sql && ./controle_gay.sh     # exige gdal-bin
```

Elle enchaîne `08` (mesure), `09` (explique les écarts), `10` (couverture), et
écrit `rapport_controle_gay.txt` plus `controle_gay.gpkg`. Méthode et grille de
lecture dans `sql/README.md`.

### Le résultat qui compte

**Sur les 34 894 atomes de 1870 en `source = 'geofla'` et non partagés, aucun
n'est en désaccord avec Gay. Aucun. Même chose sur les 35 318 de 1940.**

Les 144 atomes mal placés de 1870 (0,38 %) et les 149 de 1940 (0,39 %) tombent
tous dans les catégories déjà signalées comme fragiles :

| Source | Atomes | En désaccord | |
|---|---|---|---|
| `geofla` non partagé | 34 894 | 0 | 0,00 % |
| `geofla` partagé | 1 420 | 2 | 0,14 % |
| `successeur` | 1 466 | 137 | 9,35 % |
| `hac` | 11 | 2 | 18,2 % |
| `hac_partage` | 6 | 3 | 50,0 % |
| `union_prefixe`, `absorbee` | 24 | 0 | 0,00 % |

Le rattrapage par successeur INSEE concentre l'essentiel : 137 des 144. C'était
la reconstitution la plus incertaine, elle se révèle juste à 90,6 %. Et
`hac_partage`, dont on savait le choix arbitraire, se trompe une fois sur deux
— sur six atomes.

Autrement dit : là où nos données sont directes, elles sont exactes ; là où
elles sont reconstruites, elles se trompent dans les proportions annoncées. Le
contrôle valide la chaîne et confirme, chiffres à l'appui, les limites déjà
inscrites plus haut.

### Ce que la comparaison a produit d'autre

Appariement parfait dans les deux sens, zéro collision de codes, composition des
groupes conforme (115 groupes urbains, 3,08 polygones chacun, un seul de type
`Pseudo canton`).

| | 1870 | 1940 |
|---|---|---|
| pseudo-cantons comparés | 2 775 | 2 824 |
| tracés identiques | 82,7 % | 93,6 % |
| IoU moyen | 0,983 | 0,992 |
| surface commune | 98,2 % | 99,1 % |

Restreint aux cantons ruraux — seuls cas sans repliement d'aucun côté, donc où
un écart met directement en cause nos attributions — les chiffres sont les
mêmes (83,4 % et 93,6 %). La structure de la comparaison n'est donc pas en
cause.

Deux acquis au passage. Les polygones de Gay sont **parfaitement disjoints**
(double comptage nul) et totalisent 548 202 km² aux deux dates. Nos cantons,
eux, se recouvrent : somme 546 221 km² pour une union de 542 276 en 1870, soit
**3 945 km² de double comptage** — c'est la mesure directe des 218 communes
revendiquées par plusieurs cantons, jusqu'ici estimée en nombre et non en
surface. 4 036 km² en 1940.

Le **département 99** apparaît en 1870 seulement, 25 pseudo-cantons : Albestroff,
Baccarat, Bayon, Blâmont, Château-Salins. C'est la Meurthe d'avant 1871,
département disparu au partage de 1871. Présent des deux côtés, donc sans
conséquence sur le contrôle, mais à expliquer dans la note de méthode.

## Une quatrième limite, découverte au contrôle

Défaut que les recettes internes ne pouvaient pas voir, faute de point de
comparaison extérieur.

**Nous ne couvrons pas toute la trame.** `km2_nous_seul` vaut 0,0 dans les 89
départements de 1870 comme dans les 90 de 1940 : nous ne revendiquons jamais un
territoire que Gay n'a pas. Mais il nous manque **5 926 km² en 1870** et 744 en
1940. Un écart à sens unique n'est pas une erreur d'attribution — une commune
mal rattachée se retrouverait en trop quelque part — c'est un trou de
couverture.

L'explication tient à la nature de la correspondance vers GEOFLA, qui est
plusieurs-vers-un. Quand une commune d'époque s'est **scindée** depuis, nous ne
retenons qu'un des codes issus de la scission et le territoire de l'autre n'est
réclamé par aucun atome. Gay, lui, part de la trame 2011 et affecte chaque
commune actuelle à un canton d'époque : il n'a pas de trou par construction.
`06_insee_mvt.sql` traite les fusions ; l'opération symétrique n'existe pas.

Trois faits appuient l'hypothèse : le déficit est huit fois plus grand en 1870
qu'en 1940, alors qu'il s'est produit bien plus de scissions depuis 1870 que
depuis 1940 ; il est réparti sur presque tous les départements sans
concentration ; et les Bouches-du-Rhône passent de 557,9 km² manquants en 1870
à 150,0 en 1940 — Port-Saint-Louis-du-Rhône, détaché d'Arles en 1904, pèse une
centaine de km² et tombe exactement entre les deux dates.

**Hypothèse démontrée, au km² près.** `sql/10_couverture.sql` nomme 494
communes non couvertes en 1870 pour 6 197 km², et 69 en 1940 pour 1 014. Il
faut en retrancher **Tende et La Brigue** — 271,1 km² — italiennes jusqu'au
traité de Paris de 1947, donc absentes de la couverture de Gay aux deux dates
(leur `pct_gay` est nul). Reste :

| | non couvert | `km2_gay_seul` |
|---|---|---|
| 1870 | 5 926 | 5 926 |
| 1940 | 743 | 744 |

Le déficit est intégralement expliqué par des communes que nul atome ne
réclame. Les noms confirment : Saint-Martin-de-Crau, détachée d'Arles en 1925
(216 km², la plus grande) ; Port-Saint-Louis-du-Rhône, 1904 ; La
Londe-les-Maures, 1901 ; Le Grau-du-Roi, 1879 ; Le Lavandou, 1913.

Répartition des causes :

| | 1870 | 1940 |
|---|---|---|
| création INSEE documentée (≥ 1943) | 72 (1 024 km²) | 67 (982 km²) |
| non documentée (scission 1870-1943) | 422 (5 173 km²) | 2 (32 km²) |

Exactement la forme attendue. En 1940 tout est documenté, le fichier INSEE
couvrant la période ; en 1870 les 422 communes créées entre 1870 et 1943 lui
échappent.

Correctif en deux temps, aucun n'est fait :

1. **Post-1943** — rejouer `insee_mvt` en sens inverse (`mod` 20 et 21) et
   rattacher chaque commune née après la date à l'atome de sa mère. Mécanique,
   couvre 1 024 km² en 1870 et la quasi-totalité de 1940.
2. **1870-1943** — les 422 restantes, 5 173 km². Le fichier INSEE ne remonte
   pas si loin ; **HAC** (`source_data/HAC/communal.tab`), déjà utilisé par
   `07_reliquat.sql`, documente les créations depuis 1801 et est la piste
   naturelle.

Portée pratique : ces trous sont invisibles à l'échelle départementale (IoU
départemental moyen 0,988 en 1870 et 0,998 en 1940) et se voient au zoom, comme
les 218 recouvrements. Même traitement en note de méthode.

### Un bogue trouvé au passage, corrigé

`geom_correspondance.csv` donnait `1320` comme préfixe pour Marseille. Le
`LIKE '1320%'` de `05_geom.sql` ne prenait donc que les arrondissements 13201
à 13209 et perdait les 10ᵉ à 16ᵉ — **133,66 km²**. Corrigé en `132`, sans
risque puisque les communes des Bouches-du-Rhône s'arrêtent à 13119.

La vérification est arithmétique : notre Marseille de 1870 mesurait 152,03 km²
contre 294,25 chez Gay ; les sept arrondissements manquants (133,66) plus
Plan-de-Cuques (8,57, commune créée depuis, relevant du point 2 ci-dessus)
donnent 294,26. L'écart est expliqué à 1 hectare près.

**Il faut rejouer `05` → `06` → `07`** pour que la correction prenne effet.

### Un résidu bénin

Section 4 de `10` : la Moselle affiche −21,9 km² de résidu en 1870. Les deux
colonnes ne parlent pas du même code : `ctrl_non_couvert.dep` vient de GEOFLA
(département actuel), `ctrl_dep.dep` de Gay (département d'époque). La Meurthe
disparue et le partage de 1871 suffisent à l'expliquer, et les totaux nationaux
coïncident.

## Suites possibles

La note de méthode est écrite : `METHODE.md`. Documentation interne, elle
reprend sources, chaîne de traitement, décisions et impasses, les quatre
limites chiffrées et le contrôle indépendant. C'est le document à tenir à jour ;
`ETAT.md` reste le journal de bord.

## Correctif de couverture : lancé, et il tient

**Résultat à 1870, mesuré par le contrôle Gay.**

| | avant | après |
|---|---|---|
| tracés identiques | 82,7 % | **92,8 %** |
| IoU moyen | 0,983 | **0,992** |
| pseudo-cantons sous 0,90 | 171 | 80 |
| territoire non couvert | 5 926 km² | 944 km² |
| communes non réclamées | 494 | 105 |

**4 982 km² rendus à la couverture.** Zéro chevauchement introduit, nombre de
cantons inchangé aux quatre dates de recette.

Le signe le plus net : **1870 rejoint 1940** — 92,8 % contre 93,6 %, IoU 0,9917
contre 0,9922 — alors que 1940 n'a pas bougé d'un seul chiffre, n'ayant jamais
souffert du défaut. L'anomalie corrigée était bien celle-là.

**Le prix : quatre paris perdus sur 414, soit 99,0 % de réussite.**

| atome | INSEE | apparu | chez nous | chez Gay | km² |
|---|---|---|---|---|---|
| 37390 | 08447 | 1872 | Mézières | Charleville | 32,69 |
| 36437 | 77454 | 1874 | Donnemarie-en-Montois | Nangis | 10,60 |
| 17501 | 56086 | 1891 | Quiberon | Belle-Île | 3,25 |
| 17191 | 56085 | 1891 | Quiberon | Belle-Île | 2,25 |

Ils restent en l'état, **délibérément**. Les corriger en recopiant les réponses
de Gay ferait perdre au contrôle son indépendance, donc sa valeur. Ils se
tranchent sur pièces : Houat et Hœdic relevaient-ils de Quiberon ou de
Belle-Île en 1870 ? La réponse est dans les archives, pas dans l'étalon.

### Le garde-fou 4 : ce qu'il a corrigé, ce qu'il a coûté

Le premier passage perdait sept paris. Trois — 57369 Cattenom, 57474 Longuyon,
68048 Habsheim — étaient apparus en 1921 et 1928, après le retour de
l'Alsace-Moselle, et relevaient d'une même cause : **TRF-GIS réutilise les
codes de canton de part et d'autre de la rupture de 1871**. Le 5705 de 1870
relève de la numérotation de la Meurthe, celui de 1921 de la Moselle
reconstituée — deux cantons sous une même clé, que le modèle prend pour une
unité pérenne unique. Les garde-fous 1 et 2 ne pouvaient rien voir : le canton
d'accueil a bien des membres aux deux dates.

Le garde-fou 4 ne retient que la plage d'existence *continue* du canton
aboutissant à la date d'apparition. Effet mesuré :

| | sans garde-fou 4 | avec |
|---|---|---|
| atomes prolongés | 441 | 414 |
| paris perdus | 7 | **4** |
| dont `geofla` non partagé | 4 | **3** |
| territoire non couvert (1870) | 800 km² | 944 km² |
| IoU moyen | 0,99196 | 0,99173 |

**Il enlève 27 prolongements pour en supprimer 3 faux.** Les 24 autres étaient
d'accord avec Gay — mais sur ce terrain précis, l'accord ne prouve rien : pour
une commune créée sous administration allemande, Gay a dû extrapoler comme
nous. Deux extrapolations qui coïncident restent deux extrapolations.

Le territoire rendu au non-couvert est concentré en Moselle : 23 communes,
140,7 km². Il est désormais déclaré inconnu plutôt que rattaché au hasard.
C'est le sens du garde-fou, et c'est un choix, pas une évidence.

## Deux choses à faire tout de suite

**Marseille : réglé.** Le correctif n'atteignait pas la base — le fichier
`geom_correspondance.csv` n'était pas propagé jusqu'à `~/Téléchargements`, alors
que les `.sql` l'étaient. Corrigé sur place, rechargé, et Marseille a quitté le
classement des pires écarts : IoU de 0,517 à 0,971.

Le diagnostic avait tout prédit au km² près. GEOFLA ne contient **aucun** code
`13055` : Marseille n'y existe que sous ses seize arrondissements, pour
235,22 km². Le préfixe `1320` n'en captait que neuf, soit 101,57.

| | avec `1320` | avec `132` | chez Gay |
|---|---|---|---|
| Marseille | 101,57 | 235,22 | 235,22 |
| Allauch | 50,46 | 50,46 | 50,46 |
| Plan-de-Cuques | — | — | 8,57 |
| **total** | **152,03** | **285,69** | **294,25** |

Le territoire non couvert a perdu exactement 133 km² aux deux dates, et sept
communes — les sept arrondissements. Le reliquat, Plan-de-Cuques, est une
commune créée après 1870 : elle relève du § 6.2, pas du bogue. Lyon était sain.

**Leçon retenue, et elle vaut au-delà du cas.** Un préfixe trop long n'échoue
pas, il ampute en silence : l'atome avait bien une géométrie, `check_geom()` ne
signalait rien, toutes les recettes internes passaient. Il a fallu une source
extérieure pour le voir. `05_geom.sql` affiche désormais à chaque chargement ce
que chaque préfixe capte, avec le compte attendu — Paris 20, Marseille 16,
Lyon 9.

**À surveiller** : si seuls les `.sql` circulent entre les deux dossiers,
`build/`, `geom_correspondance.csv` et les notes peuvent être périmés d'un côté
sans que rien ne le signale.

## Où en est la base

Contrôle indépendant clos. Parcours complet, à 1870 :

| | au départ | maintenant |
|---|---|---|
| tracés identiques | 82,7 % | **92,8 %** |
| IoU moyen | 0,9826 | **0,9919** |
| pseudo-cantons sous 0,90 | 171 | 79 |
| surface commune | 98,21 % | 99,13 % |
| territoire non couvert | 5 926 km² | **811 km²** |
| communes non réclamées | 494 | 98 |

1940 : 93,63 % de tracés identiques, IoU 0,99235, 610 km² non couverts. Les deux
dates sont désormais au même niveau, ce qu'elles n'étaient pas au départ.

Sur 38 235 atomes de 1870, 148 sont rangés ailleurs par Gay — 0,39 % — dont
**trois seulement** en `geofla` non partagé, c'est-à-dire sans explication
connue. Les 145 autres relèvent des catégories reconstruites, dans les
proportions annoncées.

```bash
cd ~/Téléchargements/projet_carte/sql
chmod +x rebuild.sh
./rebuild.sh          # load.sh → GEOFLA → 05 → 06 → 07 → 11
./controle_gay.sh     # pour noter le résultat
```

`rebuild.sh` localise seul `COMMUNE.SHP` et `v_mvt_commune_*.csv`, et refuse de
démarrer s'il ne les trouve pas. Il est destructif — `load.sh` fait
`DROP SCHEMA histgis CASCADE` — et c'est voulu : `geom_correspondance.csv` est
lu par `02_load.sql`, rejouer `05` seul ne servirait à rien.

Bénéfice attendu : les arrondissements 10 à 16 de Marseille rejoignent la
commune, l'IoU du pseudo-canton marseillais passe de 0,52 à près de 1, et les
non-couverts perdent 133,66 km² de plus.

**Lire la nouvelle section 8 de `09`.** Elle nomme les sept communes que le
correctif a mal placées. C'est du travail à la main, mais borné à sept lignes.

## Comment marche le correctif

`sql/11_scission.sql` prolonge vers l'arrière le premier rattachement des
atomes apparus en cours de série. Hypothèse assumée : *une commune nouvelle
reste dans le canton de sa mère.* Trois garde-fous — seul le premier
rattachement est prolongé, donc les trous d'Alsace-Moselle restent intacts ; le
prolongement suit la chronologie du canton d'accueil et non le calendrier ; les
recodages sont écartés (50 sur 505 candidats). Réversible par `scission_trace`,
rejouable, et il retire ses propres lignes avant de recommencer.

## Les désaccords résiduels : ce n'est pas nous, c'est la trame

`12_conflit_successeur.sql` testait une hypothèse : que sur les 138 atomes
`successeur` en désaccord avec Gay, le `membership` dise vrai et que ce soit la
géométrie qui mente. Une commune absorbée depuis reçoit le polygone de
l'absorbante, laquelle existe aussi comme atome — deux atomes, un polygone,
chacun trop grand de la part de l'autre.

**L'hypothèse est vérifiée, et sans réserve.** Le désaccord ne suit pas la
source de la géométrie, il suit le partage de polygone :

| situation | atomes | en désaccord | |
|---|---|---|---|
| seul sur son polygone | 35 309 | 8 | 0,02 % |
| partage, même canton | 2 273 | 0 | 0,00 % |
| partage, cantons différents | 653 | 140 | **21,44 %** |

`desaccord_hors_conflit` — la seule colonne qui accuserait vraiment les
attributions — vaut **zéro** pour les 138 `successeur`. Pas un seul n'est en
désaccord tout en étant seul sur son polygone.

Le compte se referme : 140 désaccords dans les groupes éclatés, 8 hors conflit,
soit les 148 atomes connus. Et les 8 sont tous déjà nommés — 3 `hac_partage` et
2 `hac`, les rattachements arbitraires assumés au § *Limites*, plus **3 `geofla`
qui sont exactement les trois paris perdus** du correctif de scission. Il ne
reste aucun désaccord inexpliqué dans la base.

**Conséquence pratique : il n'y a rien à corriger.** La piste « reprendre les
138 atomes `successeur` » se referme sans travail manuel. Le correctif ne peut
pas venir de GEOFLA — une géographie ne se découpe pas plus fin qu'elle-même —
il viendra d'ANR-COMMUNES.

Les trois départements où nous revendiquions du territoire de trop s'expliquent
chacun par **un seul polygone partagé**, au km² près :

| département | km² en trop | groupe | pseudo-cantons |
|---|---|---|---|
| Haute-Marne | 130,1 | 70122 | 5212 ; 7004 |
| Deux-Sèvres | 88,1 | 49099 | 4912 ; 7909 |
| Marne | 59,0 | 52182 | 5124 ; 5218 ; 5225 |

La Haute-Marne est le cas d'école : la commune 52210, de Haute-Marne en 1870, a
été absorbée depuis par une commune de Haute-Saône (70122). Nous donnons les
130 km² du polygone au canton haut-marnais, Gay les donne au canton
haut-saônois. Aucun des deux n'a tort dans son cadre.

## Combien coûte l'indivisibilité de la trame : 12 822 ou 3 945 km² ?

`12` mesurait 12 822 km² comptés en double et annonçait que le chiffre devait
« ressembler » aux 3 945 km² de `08`. Il en est 3,25 fois plus grand. Le
commentaire était faux, `13_double_comptage.sql` l'établit.

**Les deux ne comptent pas au même niveau.** `12` compte entre cantons réels ;
`08` travaille sur `ctrl_nous`, dissous par `deppct`, donc **après repliement en
pseudo-cantons** — et le repliement réunit précisément les cantons qui se
partagent une commune, puisque c'est sa raison d'être.

Mesuré deux fois, par deux méthodes indépendantes — union de polygones d'un
côté, comptage des unités par groupe de partage de l'autre :

| | géométrie | nomenclature |
|---|---|---|
| entre cantons réels | 12 930 | 12 822 |
| après repliement | 3 945 | 3 837 |
| absorbé par le repliement | 8 985 | 8 985 |

Les deux méthodes divergent de **108 km² exactement aux deux niveaux** — un
décalage constant, donc une cause unique et bornée, non un désaccord de fond.
Piste : les 17 atomes `hac` et `hac_partage` sont rattachés par nom et leur
`code_2011` est une approximation assumée dans `12` ; deux atomes portant en
réalité le même polygone sous deux codes différents sont invisibles au comptage
par nomenclature et bien vus par la géométrie. À confirmer, l'enjeu est de
0,8 %.

**Le résidu n'est pas urbain, et c'était contre-intuitif.** Sur les 3 837 km²
qui survivent au repliement, **3 296 viennent de 105 groupes qui ne subissent
aucun repliement** — des communes rurales partagées entre deux cantons
ordinaires — contre 541 km² de restes urbains. Le repliement règle le cas des
villes en entier ; ce que le contrôle Gay voit encore est presque exclusivement
rural. Les groupes éclatés — 236 avec la clé géométrique — se réduisent à peu
près de moitié après repliement.

Réserve à lever : cette ventilation rural/urbain a été mesurée avec l'ancienne
clé `code_2011`, sur 3 837 km². Les 108 km² que la clé géométrique restitue n'y
sont pas ventilés — Lyon (47,85) ira du côté urbain, les 60,18 restants sont à
classer. Rejouer `13` § 3 sur `cle_geom` suffirait à trancher ; l'ordre de
grandeur ne bougera pas.

Deux contrôles croisés confirment le dispositif. Le double comptage chez Gay est
**nul** (548 202 km² en somme comme en union) : le phénomène est bien chez nous
et non un artefact de la comparaison. Et l'écart entre son union et la nôtre —
548 202 contre 547 391 — vaut **811 km²**, exactement le trou de couverture
mesuré par `10`. Deux chemins indépendants, même nombre.

**Le plancher de la trame se lit donc à deux niveaux** : 12 930 km² entre
cantons réels (2,36 % du territoire, sur 8 756 km² de polygones éclatés),
3 945 km² au niveau où le contrôle opère.
C'est le second qu'il faut citer en note de méthode, et seule une trame
communale historique peut l'abaisser.

## Les 108 km² attribués — et ce qu'ils cachaient

`14_cle_partage.sql` refait le calcul du double comptage avec trois clés de
regroupement : celle de `12`, une version corrigée sensible à
`atom_geom.source`, et l'empreinte binaire du polygone — la seule qui ne
suppose rien, deux atomes portant le même polygone recevant dans `05` une
géométrie construite à l'identique.

| clé | groupes | double, canton réel | après repliement |
|---|---|---|---|
| `cle_12` | 36 506 | 12 822 | 3 837 |
| `cle_source` (corrigée) | 36 506 | 12 822 | 3 837 |
| **`cle_geom`** (empreinte) | 36 489 | **12 930** | **3 945** |

L'empreinte reproduit exactement les mesures géométriques de `13`. **L'écart
était donc entièrement une affaire de clé : aucune attribution n'est en cause.**

L'hypothèse de départ était pourtant fausse. Je soupçonnais les atomes `geofla`
figurant aussi comme `insee_ancien` dans les mouvements INSEE, qui auraient reçu
à tort la clé du successeur : `cle_source` ne les distingue de `cle_12` que par
**un seul atome**. La cause est l'autre piste — les 17 atomes rattachés par nom,
dont aucune colonne ne dit quel polygone ils portent. Cinq groupes, et le compte
tombe juste :

| polygone | km² | cantons | sources | codes mêlés |
|---|---|---|---|---|
| Lyon | 47,85 | 10 | `hac` + `union_prefixe` | 69123 ; 6938 |
| Corse | 19,35 | 2 | `geofla` + `hac` | 2A249 ; 2A325 |
| Marne | 16,78 | 2 | `geofla` + `hac_partage` | 51235 ; 51606 |
| Oise | 14,73 | 2 | `geofla` + `hac_partage` | 60509 ; 60606 |
| Ardennes | 9,32 | 2 | `geofla` + `hac_partage` | 08203 ; 08227 |

47,85 + 19,35 + 16,78 + 14,73 + 9,32 = **108,03**. La constance d'un niveau à
l'autre s'explique du même coup : chacun de ces groupes ajoute exactement une
unité, donc sa surface compte une fois de plus au niveau canton réel comme après
repliement.

Le correctif à porter dans `12` n'est donc pas un `coalesce` plus fin, c'est de
grouper par `md5(ST_AsEWKB(geom))`. Aucun code ne dit ce qu'une empreinte dit.

### Ce que la section 5 révèle, et qui compte davantage

Les cinq atomes en cause — `69232`, `2A325`, `51606`, `60606`, `08227` — sont
**trois `hac_partage` et deux `hac`**. C'est trait pour trait la composition des
cinq désaccords que `12` classait « hors conflit », faute de voir qu'ils
partageaient leur polygone.

**Vérifié.** La requête donne exactement les cinq atomes attendus, cantons
compris :

| atome | INSEE | source | canton |
|---|---|---|---|
| 28580 | 69232 | `hac` | 6910 |
| 37694 | 2A325 | `hac` | 2053 |
| 17193 | 08227 | `hac_partage` | 0828 |
| 35396 | 60606 | `hac_partage` | 6020 |
| 39369 | 51606 | `hac_partage` | 5125 |

`desaccord_hors_conflit` ne vaut donc pas 8 mais **3 sur 38 235 atomes** — les
paris perdus du correctif de scission, conservés délibérément. **La base n'a
aucun désaccord avec Gay qui ne soit ni un artefact de trame, ni un choix assumé
et tracé.**

Corollaire, à porter en note de méthode : le « 3 sur 6 » qui condamnait
`hac_partage` mesure la trame, pas l'échec du choix arbitraire. Ce qui ne
l'innocente pas — le rattachement par nom reste arbitraire et révocable —, mais
le contrôle Gay ne peut plus servir à le condamner : sur ces six-là, il ne
tranche pas. Les corriger à la main ne gagnerait rien de mesurable.

## Les communes nées après la série : comblées pour l'essentiel

`15_creation_arriere.sql` traite ce que `11` ne pouvait pas atteindre : les
communes de la trame 2011 nées **après** 1940, que TRF-GIS n'a jamais vues et
qui n'ont donc aucun atome à prolonger. Le fichier INSEE documente leur création
(modalités 20 et 21) et nomme leur mère.

Le choix de conception : plutôt qu'élargir la géométrie de l'atome mère — ce qui
mêlerait géométrie et attribution et défairait le découplage —, on crée un
**atome-fraction** portant le polygone de la fille et on lui recopie
l'appartenance de la mère, année par année, aux deux niveaux. `cassini`
synthétique préfixé `N`, `fraction = true`, `source = 'creation_arriere'` : rien
ne doit pouvoir le confondre avec un atome TRF-GIS.

**Résultat, mesuré par le contrôle Gay**, après correction des deux défauts du
premier passage (voir plus bas) :

| | avant | après |
|---|---|---|
| non couvert 1870 | 811 km² | **238 km²** |
| non couvert 1940 | 610 km² | **32 km²** |
| tracés identiques 1870 | 92,8 % | **94,49 %** |
| tracés identiques 1940 | 93,63 % | **95,33 %** |
| IoU moyen 1870 | 0,9919 | 0,99281 |
| IoU moyen 1940 | 0,99235 | 0,99325 |
| double comptage | 3 945 / 4 036 | **inchangé** |

58 atomes posés pour 577 km², 438 intervalles (59 canton, 379 circo). Zéro
chevauchement, et surtout **zéro territoire déjà couvert** — la recette qui
compte. Les deux totaux non couverts retombent sur le `km2_gay_seul` de `09`.

**Le rattrapage se situe honnêtement dans la hiérarchie de fiabilité** :
3 désaccords sur 57, soit **5,26 %** — entre `geofla` (0,01 %) et `successeur`
(9,3 %). Le total d'atomes mal placés passe de 148 à 151.

À noter, parce que c'est le genre de chose qu'on aime taire : le premier passage
affichait 3,70 % (2 sur 54). Les trois communes récupérées par le correctif ont
apporté un désaccord de plus. **Les cas que la première version ratait étaient
précisément les plus difficiles** — 55 km² de couverture gagnés contre un atome
mal placé, et 0,00003 d'IoU. L'échange reste bon, il n'est pas gratuit.

Un détail qui vaut recette : un atome de moins en 1870 qu'en 1940. Une fille
mosellane dont la mère n'a aucun rattachement en 1870 n'a pas été comblée — le
garde-fou 4 de `11` a fonctionné ici sans qu'on ait eu à l'écrire, parce qu'on
recopie une chronologie au lieu de la prolonger.

### Les deux défauts du premier passage, dont un passé à côté par chance

**1. Le test « sans atome » était trop naïf.** Il comparait des empreintes de
polygones entiers. Les 16 arrondissements de Marseille et 2 de Lyon étaient donc
classés « sans atome » alors qu'ils sont couverts — par l'atome `union_prefixe`,
dont le polygone est leur *union*, et qu'aucune empreinte de composant n'égale.
Ils n'ont été écartés que parce que leur mère `13055` n'existe pas dans GEOFLA
(§ du bogue Marseille). **Si elle avait existé, Marseille aurait été compté deux
fois — et la recette d'empreintes partagées ne l'aurait pas vu**, le polygone
d'un arrondissement n'égalant pas celui de l'union. Une recette incapable
d'attraper l'erreur qu'elle vise n'est pas une recette.

Corrigé : test par point intérieur contenu dans un polygone d'atome, celui de
`10_couverture.sql`. 78 filles candidates deviennent 60, et la recette elle-même
a été refaite sur l'inclusion.

**2. L'appariement des mères était trop strict.** Val-de-Reuil (26,8 km²) et
Marcheprime (24,5) restaient non couverts alors qu'Incarville et Biganos sont
des communes ordinaires : `atom_geom.geom` est construit par `ST_UnaryUnion`,
qui peut renormaliser la représentation sans changer la géométrie.

Corrigé par `ST_Equals`, avec repli sur `insee_geofla`. La ventilation par voie
est instructive : **57 mères sur 58 sont trouvées par les deux voies**, une seule
par le code seul. `ST_Equals` n'a pas remplacé l'empreinte, il l'a complétée là
où elle échouait — ce qui est exactement la forme du défaut.

Leçon, et elle nuance celle de `14` : **l'empreinte binaire est la bonne clé pour
constater qu'un polygone est partagé, pas pour tester qu'il est le même.**
Identité de représentation et identité géométrique ne sont pas la même chose.

### Ce qui reste non couvert

39 communes et 238 km² en 1870 (hors Tende et La Brigue), 2 communes et 32 km²
en 1940. La composition a changé de nature : **37 des 39 sont « non
documentées »**, donc créées avant 1943, hors de portée du fichier INSEE — Chisa
en Haute-Corse (29,9 km²), Philippsbourg (24,6) et une vingtaine de communes
mosellanes ou meurthe-et-mosellanes, nées sous administration allemande.

Restent deux documentées qui échappent au script : **Kuntzig et Stuckange**
(8,6 km², créées le 1ᵉʳ janvier 1989). Leur ligne INSEE de modalité 20 a un
`com_av` vide ou égal à `com_ap`, que `15` écarte faute de mère nommable.
Micro-résidu, à traiter avec le reste.

La suite passe par **HAC**, qui documente les créations depuis 1801 — au prix
d'un rattachement par nom, avec l'incertitude que cela suppose.

## La période 1943-2012 : la trame communale est posée

Conception établie sur mesure dans `note_1943_2012.md` : **un seul continuum
d'atomes 1870-2012**. 2 404 des 2 407 codes de communes disparues entre 1943 et
2011 qui préexistaient à 1943 se raccordent à un atome existant — le pont passe
par le code INSEE et la fermeture transitive de `06`, il n'a pas eu à être
construit.

**`20_commune_moderne.sql`** reconstitue la chronologie sans rien écrire, puis se
soumet à une contradiction : l'ensemble des communes vivantes au 1ᵉʳ janvier 2011
doit être celui de GEOFLA. Après correction d'un bogue que la recette a révélé —
les communes rétablies perdaient leur première vie —, elle retombe sur la trame
**au code près** : 39 291 intervalles pour 39 040 codes, 251 vies multiples,
38 068 communes en 1943, 36 630 en 2011 dont 36 610 métropolitaines.

**`21_atomes_modernes.sql`** pose les atomes manquants et la correspondance
datée. Aucun `membership` : il n'y a pas encore d'unité moderne.

| famille | atomes | km² |
|---|---|---|
| arrondissements de Marseille et Lyon | 25 | 283,08 |
| territoires partagés | 15 | 292,51 |
| territoires neufs (Tende, La Brigue, Chisa, Butry) | 4 | 303,61 |

Correspondance `commune_moderne` : 38 125 codes par voie directe, 890 par
succession, 2 par recodage, 23 sans atome — l'outre-mer, **hors périmètre** par
cohérence avec une trame métropolitaine, choix révocable en une clause.

Toutes les recettes à zéro : aucun code simultané sur un même atome, aucun
conflit de territoire, aucun atome sans géométrie, et les 36 610 communes de la
trame portées **et** nommées. Les effectifs de 1870-1940 sont rigoureusement
inchangés.

### La question des arrondissements, tranchée

L'éclatement rétroactif était infaisable : TRF-GIS ne dit jamais quel
arrondissement relève de quel canton en 1870, et faire appartenir l'atome du
3ᵉ arrondissement aux dix cantons lyonnais viole `membership_non_chevauchant`.

Retenu : **les fractions restent l'attribution de 1870-1940, les arrondissements
deviennent des atomes de plein droit à partir de 1943.** Les deux familles
portent des géométries qui se recouvrent, mais leurs `membership` ne se croisent
jamais dans le temps — une recette le vérifie des deux côtés. Conséquence
assumée : les 430 km² de double comptage lyonnais de 1870 restent, aucune source
ne permettant de les lever.

### La leçon de `21`, qui a demandé quatre passages

Le même défaut sous quatre déguisements : voie directe seule (906 atomes de
trop), test par code au lieu de la géométrie (Pont-de-Buis dupliquée), conflit
traité pour le seul successeur direct (4 cas sur 13), puis la voie `polygone`
oubliée (1 dernier).

La formulation qui tient : **une voie qui possède un atome par son propre code
n'a jamais de conflit ; une voie qui l'emprunte en a toujours potentiellement
un.** Deux catégories, un seul test. J'énumérais des motifs là où il fallait
mesurer une propriété — et un motif oublié ne se signale pas.

Corollaire d'ingénierie : poser l'atome et sa trace dans la **même** instruction
via `RETURNING`, et lancer tout script qui écrit avec `psql -1`. Un `NULL` non
casté a laissé 25 atomes committés et non tracés, donc invisibles au retrait.

## Les cantons 1999-2012 sont posés

`load_cog.sh` charge les 14 millésimes du COG, `23_cog_diag.sql` mesure,
`24_canton_moderne.sql` écrit. Le tout en une transaction, précédé d'un
contrôle préalable qui annule tout si l'une de ses trois assertions échoue.

| | |
|---|---|
| cantons | **3 844** (3 841 en 1999, 3 844 dès 2005) |
| unités créées / réutilisées | 925 / **2 919** |
| atomes-fractions | 998, dont **266 héritées de 1870-1940** |
| rattachements | 37 319 intervalles |
| chevauchements | **0** |
| rattachements entre 1941 et 1998 | **0** |
| effectifs 1870-1940 | inchangés |

**Le trou se voit dans les données.** À `1970-06-01`, `count_units` ne renvoie
aucune ligne — pas un canton faux, pas une composition interpolée : rien. C'est
l'absence de la ligne qui est le résultat, et c'est ce que le modèle doit dire
quand la source ne dit rien.

### Trois décisions, et ce qui les fonde

**Un seul espace de noms.** Un canton garde son `unit_id` de 1870 à 2012, avec
un `membership` absent de 1941 à 1998. Ce n'est pas une commodité :
`ct_codes.do` du dépôt TRF-GIS s'intitule « ADJUST CANTONS CODES TO MATCH 1954
COG » et aligne les codes de Gay sur le COG de 1954. La filiation 1954 → 1999
est celle de l'Insee, donc **la continuité de la nomenclature est documentée**,
pas inférée — 92,4 % des 2 943 codes partagés portent d'ailleurs le même nom.
2 919 cantons portent aujourd'hui des rattachements des deux côtés du trou.

Ce qui est affirmé : l'identité du canton. Ce qui ne l'est pas : sa composition
entre 1941 et 1998.

**Paris est résolu par la donnée.** Paris n'a pas de cantons au sens électoral —
ses arrondissements en tiennent lieu dans les nomenclatures de l'Insee — et le
fichier cantons le dit : `cheflieu` vaut 75101 pour le canton 15, jusqu'à 75120
pour le 34. 280 rattachements posés sans supposition.

**Marseille et Lyon sont reportés.** Leurs cantons ont `typct = 4` et `cheflieu`
renvoie la commune entière : 22 cantons pour 16 arrondissements, 13 pour 9. Les
deux découpages se croisent et seule une couche cantonale géométrique peut
trancher. Déclarés inconnus plutôt que rattachés au jugé.

### Marseille et Lyon : la question est close, par la négative

`25_pseudo_canton.sql` les traite, et c'est GEOFLA qui a tranché.

Sa couche CANTON (édition 2014) ne compte **qu'un seul canton pour Marseille et
un pour Lyon**, codés `CODE_CANT = '99'`, de chef-lieu 13201 et 69381. Même
dispositif pour toutes les communes partagées : Villeurbanne 98, Vénissieux 97,
Aix 97, Arles 98, Istres 95, Martigues 96. D'où **3 708 cantons chez l'IGN
contre 3 876 au COG** — les 168 d'écart sont cette fusion.

La raison est la nôtre : GEOFLA est bâti sur la trame communale, et une trame
communale ne sait pas couper une commune. **Le pseudo-canton n'est donc pas un
pis-aller, c'est la convention du domaine** — Gay l'emploie pour 1870-1940,
l'IGN pour 2014, sous des codes différents et avec la même logique.

Le rattachement n'a pas été supposé : chaque arrondissement a été affecté au
canton GEOFLA contenant son point intérieur. Les 16 marseillais tombent tous
dans `1399`, les 9 lyonnais dans `6999`. 2 unités, 25 rattachements, toutes
recettes à zéro. Effectifs finaux : **3 843 cantons en 1999, 3 846 en 2012**.

**Limite à citer en légende.** Les 22 cantons de Marseille et les 13 de Lyon ne
sont pas représentés : nous ignorons quel arrondissement relève duquel, et
l'inventer serait un rattachement au jugé. Leur nombre a d'ailleurs évolué —
Marseille de 22 à 25 en 2005, Lyon de 13 à 14 en 2002 — sans que le
pseudo-canton bouge, la ville restant la ville. La simplification masque donc
une évolution réelle sans fausser le territoire.

### Le contrôle indépendant de 1999-2012 : concluant

`26_controle_ign.sql` compare `snapshot_geom('2012-06-01', 'canton')` à la
couche CANTON de GEOFLA — une source qui ne passe par aucune ligne de notre
code, comme les cantons dissous de Gay pour 1870-1940.

| | |
|---|---|
| pseudo-cantons comparés | 3 162 |
| appariement | **parfait dans les deux sens** |
| surfaces | 548 463 km² contre 548 488 — **écart de 26 km², soit 0,005 %** |
| IoU moyen | 0,9646 |
| pseudo-cantons sous 0,90 | 86 |
| **atomes rangés ailleurs** | **11 sur 37 297, soit 0,03 %** |

Le détail par source est le chiffre qui compte :

| source | atomes | en désaccord | |
|---|---|---|---|
| `geofla` non partagé | 35 161 | 10 | 0,03 % |
| `geofla` partagé | 1 318 | 1 | 0,08 % |
| `fraction_cog` | 730 | **0** | 0,00 % |
| `arrondissement` | 25 | **0** | 0,00 % |
| `successeur`, `creation_arriere` | 63 | **0** | 0,00 % |

**Les attributions de 1999-2012 sont justes.** L'écart d'IoU vient d'ailleurs :
nos communes sont de l'édition GEOFLA 2011, ces cantons de l'édition 2014, et
les pires cas sont des cantons urbains minuscules — 0,74 km² dans le
Val-de-Marne, 2,89 en Seine-Saint-Denis — où quelques mètres de reprise de
limites pèsent lourd en proportion. Les deux mesures se séparent proprement,
ce qui était l'objet de la conception.

**Le piège du repliement, retombé dedans.** Le premier jet de `26` a reproduit
l'erreur du premier passage de `08`, pourtant écrite au § 7 : ne replier qu'un
côté. GEOFLA fusionne les cantons d'une commune partagée en une entité codée
9x qui **ne porte que la commune indivise**, exactement comme les polygones
`pct_type = 'Pseudo canton'` de Gay. Résultat : 216 entités orphelines,
17 613 km² d'excédent, IoU 0,917. Pire, le repliement était déduit de
l'affectation géométrique des atomes — donc de la réponse à tester.

Corrigé en déduisant le repliement de **notre** nomenclature — deux cantons
fusionnent s'ils partagent une commune, composantes connexes — et en rattachant
les entités 9x par la commune qu'elles portent. Les orphelines tombent à zéro,
l'excédent de 17 613 km² à 26.

### Ce que le COG apprend au passage

Le fichier historique ne consigne que **66 changements de canton**, tous entre
avril 1995 et novembre 1998 — la documentation Insee l'annonce, les données le
confirment. Le trou 1943-1995 est donc **dans la source**, pas dans notre
recherche. Le diff des 14 millésimes, lui, trouve 23 communes changeant de
canton (17 en 2002, 5 en 2005, 1 en 2009) et 10 cantons créés pour 3 supprimés :
quatorze instantanés annuels valent mieux qu'un historique qui ne consigne rien.

Un quart des fractions cantonales de 1999 existaient déjà avant 1941, entre les
mêmes cantons. Confirmation non recherchée de la continuité.

## Les circonscriptions législatives de 2012

Source : tableau de correspondance du ministère de l'Intérieur, **Licence
Ouverte / Etalab**. Lecture et pièges dans `note_circonscriptions.md` —
l'équivalent de `note_lecture_trfgis.md` pour cette source, et pour la même
raison : le fichier ne dit pas ce qu'il paraît dire.

`extrait_circo.py` réduit le tableau à ce qui est chargeable, `27_circo_2012.sql`
pose : **539 unités, 37 253 rattachements**, zéro chevauchement, 1870-1940
inchangé. La somme des maxima départementaux retrouve **539 sièges
métropolitains** — le compte officiel, sans correction.

Période retenue : du **23 février 2010**, promulgation de la loi ratifiant
l'ordonnance de 2009, à la fin de la série. Aucune élection législative n'ayant
eu lieu entre 2007 et 2012, la borne aurait pu être placée n'importe où dans
cet intervalle ; la promulgation est le moment où la carte devient le droit.

### Ce que Paris coûte, et pourquoi on ne l'a pas maquillé

**524 circonscriptions sur 539 ont un territoire.** Les quinze autres sont
vides : quatorze à Paris, une à Lyon. Le découpage de 2009 coupe **à
l'intérieur des arrondissements** — treize des vingt arrondissements parisiens
relèvent de deux ou trois circonscriptions — et notre unité la plus fine à Paris
est l'arrondissement.

Le pseudo-découpage, qui a résolu Marseille et Lyon au niveau cantonal, a été
mesuré puis écarté : il relierait **17 des 18 circonscriptions parisiennes en
une seule composante**. Paris deviendrait un bloc, ce qui est pire que quinze
unités vides.

L'état est donc conservé tel quel, par cohérence avec la convention suivie
partout : **l'absence signifie « on ne sait pas », la présence « on sait »**.
Les quatre circonscriptions parisiennes pourvues le sont d'arrondissements
réellement non partagés ; les supprimer jetterait une information vraie.

À citer en légende : Paris n'est couvert qu'à 4 circonscriptions sur 18, et 45
atomes n'ont aucune circonscription en 2012.

## Le découpage de 1986, posé lui aussi

`28_circo_1986.sql` : **534 unités, 37 129 rattachements**, du 24 novembre 1986
au 22 février 2010 — scrutins de 1988, 1993, 1997, 2002 et 2007. L'élection de
mars 1986 s'étant tenue à la proportionnelle départementale, la carte dite « de
1986 » ne sert qu'à partir de 1988.

**533 circonscriptions sur 534 ont un territoire**, contre 524 sur 539 en 2012 :
le découpage de 1986 suit mieux les cantons, sans équivalent du morcellement
parisien de 2009.

Deux amputations, déclarées : **Paris est absent** (21 circonscriptions, code
« 42 » inutilisable) et 135 lignes écartées pour valeur textuelle. Les 534
circonscriptions restantes valent exactement les 555 de la carte de 1986 moins
les 21 parisiennes.

**Huit atomes écartés, et la cause est instructive.** L'extraction n'en trouvait
aucun : aucun couple (canton, entité) n'est partagé en 1986. Mais les
arrondissements de Marseille et de Lyon sont rattachés à un **pseudo-canton**,
donc toutes les lignes d'un arrondissement se résolvent vers le même atome quel
que soit leur canton. Deux cantons d'un même arrondissement dans deux
circonscriptions, et l'atome relève des deux. **Le pseudo-canton se paie un
niveau plus haut** : en renonçant à distinguer les cantons de Marseille, on
renonce aux circonscriptions qui les suivent.

La seule circonscription sans territoire est `13-08`, huitième des
Bouches-du-Rhône : elle était **composée exclusivement de fractions des 11ᵉ,
12ᵉ et 13ᵉ arrondissements de Marseille**, sans une commune ni un arrondissement
entier. Elle disparaît donc intégralement — ce qui est la bonne réponse, la
trame ne pouvant rien porter d'elle.

### Les deux découpages modernes

| | 1986 | 2009 |
|---|---|---|
| période | 24 nov. 1986 → 22 fév. 2010 | 23 fév. 2010 → fin de série |
| unités / avec territoire | 534 / **533** | 539 / **524** |
| rattachements | 37 129 | 37 253 |
| Paris | absent (21 circos) | 4 circos sur 18 |
| atomes écartés | 8 | 31 |

Recettes à zéro des deux côtés : aucun chevauchement, aucun atome relevant des
deux découpages, bascule nette au 23 février 2010, et 1870-1940 intact.

## Gaudillère — première validation externe de la couche circonscriptions

L'atlas Gaudillère, section Bouches-du-Rhône, transcrit dans
`gaudillere/marseille_complet.md` : découpages cantonaux 1801-1973 et
législatifs 1831-1986 pour Marseille.

**Une validation parfaite, et c'est la première de cette couche.** L'atlas nomme
les sept arrondissements divisés par le découpage de 1986 : Ier, VIème, Xème,
XIème, XIIème, XIIIème, XVème. `28_circo_1986.sql` avait écarté sept atomes
marseillais faute de pouvoir trancher — `A13201`, `A13206`, `A13210`, `A13211`,
`A13212`, `A13213`, `A13215`, soit les arrondissements 1, 6, 10, 11, 12, 13,
15. **Sept sur sept.**

Les 1 772 circonscriptions de 1870-1940 n'avaient jamais été confrontées à quoi
que ce soit — les cantons dissous de Gay ne portent que les cantons, le contrôle
IGN ne couvre que le moderne. C'est le premier point de comparaison obtenu, et
il valide autant le traitement que le refus de trancher.

**Le découpage de 1958 devient constructible.** L'atlas établit que les
circonscriptions de 1958 et 1986 se définissent sur les **arrondissements**
fixés par le décret du 18 octobre 1946, et qu'en 1958-1986 **deux
arrondissements seulement sont divisés** — le IVème et le VIème. Quatorze sur
seize relèvent donc d'une seule circonscription. Nos atomes d'arrondissement
existent : ce découpage, absent de la base et absent du tableau de l'Intérieur,
est constructible à 87 % pour Marseille.

**Trente-deux ans du trou cantonal documentés.** Marseille conserve ses douze
cantons de 1901 à 1973 — première information positive obtenue sur la période
1941-1998.

**Ce que l'atlas ne donne toujours pas** : de la géométrie. Les limites sont des
listes de voies, deux cantons de 1801 n'ont aucune limite propre, les découpages
de 1886 et 1901 sont différentiels, et l'auteur reconnaît avoir reconstruit
« approximativement » la ligne de 1876 depuis des procès-verbaux d'élection. La
seule voie vers des polygones reste le géoréférencement des cartes, à précision
déclarée.

## Suites restantes

1. **Les quatre paris perdus** du correctif de scission, nommés par
   `09_ecart_detail.sql` § 8. Travail d'archives, borné à quatre lignes.
2. ~~Reprendre les 138 atomes `successeur`, les 3 `hac_partage` et les 2
   `hac`~~ — **clos par `12` et `14`** : le `membership` est sain, le défaut est
   dans la trame, et les cinq atomes `hac` en désaccord sont eux aussi sur des
   polygones partagés (vérifié). Il ne reste rien à corriger à la main.
3. ~~Attribuer les 108 km² d'écart, puis porter le correctif dans `12`~~ —
   **clos par `14`, correctif appliqué** : `12` groupe sur
   `md5(ST_AsEWKB(geom))` et sort 36 489 groupes, 236 éclatés, 12 930 km²,
   3 désaccords hors conflit. Reste un point de finition sans enjeu : rejouer
   `13` § 3 sur `cle_geom` pour ventiler les 108 km² entre rural et urbain.
4. **Les communes nées après 1940** — traité par `15`, défauts corrigés :
   811 → 238 km² en 1870, 610 → 32 en 1940. Restent :
   a. les 37 communes « non documentées », 229 km², créées avant 1943 —
      Chisa, Philippsbourg, une vingtaine de mosellanes. **HAC** est la seule
      piste (`source_data/HAC/communal.tab`), au prix d'un rattachement par nom ;
   b. Kuntzig et Stuckange, 8,6 km², documentées mais sans `com_av` exploitable ;
   c. Tende et La Brigue restent hors sujet — italiennes jusqu'en 1947.
5. **Période 1943-2012** — trame communale posée (`20`, `21`), cantons
   1999-2012 posés (`24`). Restent :
   a. ~~Marseille et Lyon~~ — **clos par `25`** : pseudo-cantons, comme
      l'IGN. Reste à monter un **contrôle indépendant** de 1999-2012 contre la
      couche CANTON de GEOFLA, sur le modèle de `controle_gay.sh` — l'étalon
      extérieur qui manque encore à la période moderne ;
   b. **écrire à Victor Gay** : son `ct_codes.do` prouve qu'il a eu en main une
      nomenclature cantonale de 1954. Question courte et précise — d'où
      vient-elle, sous quelle licence ? C'est la piste la plus directe sur le
      trou 1943-1999, avant l'EHESS (dont les données sont en CC BY-NC-SA,
      incompatible avec CC BY-SA) et avant le formulaire de l'Insee ;
   c. les **circonscriptions** : 1986 et 2009 sont posées. Restent le découpage
      de **1958** (scrutins 1958-1981), absent de la source et suspendu au trou
      cantonal ; **Paris en 1986**, qui demanderait une autre source que le
      tableau de l'Intérieur ; et un **contrôle indépendant** de cette couche,
      les contours de circonscriptions publiés sur data.gouv.fr pouvant jouer
      le rôle que GEOFLA a joué pour les cantons ;
   d. le **trou 1941-1942** entre la fin de la série TRF-GIS et le premier
      mouvement INSEE, à déclarer et non à interpoler ;
   e. l'**outre-mer**, écarté du périmètre, à rouvrir si une trame le couvre.
6. **ANR-COMMUNES** — embargo levé le 1ᵉʳ septembre 2026, Zenodo
   `10.5281/zenodo.3727274`. Trame communale historique : réglerait les 218
   recouvrements et les trous de couverture à la racine. C'est désormais le
   seul correctif possible pour les 3 945 km².
7. **Extension avant 1870** — Gaudillère comme source principale.

---

# État du chantier au 11 août 2026

Session consacrée au **trou cantonal 1941-1998** et à l'exploitation de
l'atlas Gaudillère. Sept défauts trouvés, dont aucun n'était visible des
recettes existantes.

## Sources entrées dans le chantier

| source | ce qu'elle apporte | état |
|---|---|---|
| **Gaudillère, annexe VII** | *Évolution des arrondissements et cantons* : créations, suppressions, fixations de limites, transferts de chef-lieu et d'arrondissement, **datés au décret**, de 1801 à 1986 | 41 clichés dans `sources/modif_canton/`, dépouillés page par page à la demande |
| **Gaudillère, annexe VI** | *Particularités des circonscriptions* : scindées, monocantonales, monocommunales, cantons divisés, 98 villes divisées, 57 circos de 1986 reprises de 1981 | transcrite en partie, `circo/annexe_vi.md` |
| **Gaudillère, méthodologie p. 828** | l'auteur déclare que son fond cantonal est celui **des années 1980**, corrigé des seules créations de cantons | résout D1 et D4 |
| **`paris_decoupage.xlsx`** | 19 divisions électorales de Paris, 1815-1986, **par quartier** | mis au propre, `circo/paris_decoupage.csv` |

## Où en est chaque couche

### Communale — inchangée

Rien n'a bougé. Les limites connues restent celles chiffrées précédemment.

### Cantonale ancienne, 1870-1940 — confortée

Cinq divergences apparentes avec l'atlas (Samoussy, Martigny-Courpierre,
Marigny-en-Orxois, Loupeigne, Les Omergues) sont **résolues sans correction** :
l'atlas donne le canton des années 1980, la base celui d'époque. L'auteur
annonce lui-même « quelques centaines de communes sur 38 000 » dans ce cas.

Villars-les-Dombes également : l'annexe VII le date du **18 juillet 1868**,
donc antérieur à la série. TRF-GIS avait raison de le porter dès 1870.

**Aucun défaut trouvé dans cette couche cette session.**

### Trou cantonal 1941-1998 — mesuré pour la première fois

C'était un blocage sans dimension ; il en a une.

> **Au moins 318 cantons sur 3 028 — 10,5 % — ont été remaniés entre 1940 et
> 1986**, mesuré par le nombre de cantons de 1940 dont les communes se
> répartissent entre plusieurs circonscriptions de 1986. Borne inférieure : un
> canton remanié sans traverser de limite reste invisible.

La concentration est nette : Nord 18, Pas-de-Calais 12, Yvelines 11,
Loire-Atlantique 10, Seine-Maritime 10. **Le dépouillement doit commencer par
les départements urbains, pas par l'ordre alphabétique.**

Outillage en place :

- `33_diff_cantonal.sql` — calcule les mouvements 1940→1999 par département, et
  les classe en démembrement / partage / transfert / fusion. Recette
  d'équilibre par canton, vide sur les quatre départements traités.
- `34_orphelines_1941.sql` — sépare les vraies fusions du trou 1941-1942.
- `cantons/mouvements_cantonaux.csv` — le registre, **quatre départements**
  (01, 02, 03, 04).

**Le registre a changé de nature en cours de route.** Il devait recueillir des
mouvements dictés ; la base sait les calculer. Il ne consigne plus que des
**dates**. Et depuis l'annexe VII, ces dates sont des dates de décret : l'Ain
compte neuf lignes en `certitude = acte` là où il avait des intervalles de
vingt-huit ans.

Ce que l'annexe VII **ne** couvre pas : les transferts isolés de communes entre
cantons. Ces lignes resteront indatées — limite connue, non lacune.

### Circonscriptions — la couche la plus avancée, et la plus fragile

**Défaut majeur corrigé** : l'extraction de 1986 écartait les 135 communes des
**24 cantons à cheval** sur plusieurs circonscriptions, dont le fichier du
ministère dit qu'ils sont divisés sans dire comment. Elles sortent désormais
dans `circo/circo_1986_indetermine.csv` — l'indétermination est une donnée.

Conséquence méthodologique : le contrôle « aucun couple canton-commune partagé »
de `note_circonscriptions.md` § 4 ter avait tourné **sur des données amputées de
leurs contre-exemples**. Il ne pouvait que réussir.

**Paris n'est plus irréductible.** Les 19 divisions de 1815 à 1986 sont posées
par quartier, chacune partitionnant exactement les 80 quartiers administratifs.
Une seule coupure reste inexpliquée sur 110 ans. Débloque aussi **Paris
1958-1986**, indépendamment du trou cantonal puisque Paris se découpe par
quartiers.

**57 circonscriptions de 1986 sont reprises de 1981** (annexe VI § 7) : second
morceau du découpage de 1958 accessible sans le trou cantonal.

## Les sept défauts, et ce qu'ils ont en commun

| # | défaut | ampleur | trouvé par |
|---|---|---|---|
| 1 | communes mortes 1943-1992 sans aucun canton | 51 sur 2 dép., **1 427 années-communes** | une commune absente d'une carte |
| 2 | atomes dont le polygone est dans un autre département | 8, 357 km² | lecture d'une planche |
| 3 | atomes sans aucun rattachement | 14, 252 km² (doublons, sans conséquence) | requête de contrôle |
| 4 | encodage CP1252 lu en Latin-1 | 1 975 valeurs, tous les `œ` et `Œ` | appariement par nom qui échoue |
| 5 | 135 communes des cantons divisés écartées de 1986 | 24 cantons | l'annexe VI |
| 6 | recette d'équilibre fausse sur les communes déjà partagées | 7 cantons | la recette elle-même |
| 7 | jointure `unit_version` sans filtre de période | noms anachroniques | lecture d'une sortie |

**Aucun n'était visible d'une recette de cohérence.** Tous laissaient la base
parfaitement cohérente : les atomes existaient, les géométries étaient valides,
les couvertures bouclaient. Trois ont été trouvés en **regardant une carte**,
deux par une **source externe**, deux par une recette qui mesurait autre chose.

C'est la leçon de la session, et elle vaut d'être écrite dans `METHODE.md` :

> Une recette de cohérence ne peut pas voir un polygone au mauvais endroit, une
> commune jamais rattachée, ni un nom mal encodé. Il faut regarder, et il faut
> un dehors.

Deux règles de lecture en découlent :

- **Une date identique sur toutes les lignes n'est pas une donnée, c'est une
  frontière de source.** Les 51 communes finissaient toutes au 1ᵉʳ janvier 1941,
  fin de la série TRF-GIS.
- **Compter n'est pas déclarer.** L'extraction de 1986 comptait et affichait les
  135 lignes écartées ; rien n'en portait trace dans la base.

## Ce qui bloque encore

1. **Le trou cantonal 1941-1998**, désormais mesuré mais non comblé. L'annexe
   VII le comble par le haut — les créations de cantons — et laisse les
   transferts de communes.
2. **Marseille** : les 12 fractions cantonales partagent un polygone unique,
   2 587 km² de double comptage en 1940. Protocole et script d'ingestion prêts ;
   attend le géoréférencement.
3. **La trame communale historique**, seul correctif possible pour les
   3 945 km² de recouvrement — ANR-COMMUNES, embargo levé le 1ᵉʳ septembre 2026.
4. **Le découpage de 1958** hors Paris et hors les 57 circos reconduites.

## Prochaines étapes, par ordre d'utilité

1. **Dépouiller l'annexe VII** pour les départements déjà au registre (02, 03,
   04), puis par ordre de remaniement décroissant : Nord, Pas-de-Calais,
   Yvelines. Chaque page convertit des `borne_sup` en `acte`.
2. **Recharger le COG** avec `ENCODING 'WIN1252'` corrigé, et vérifier que rien
   d'autre ne dérive de l'ancien décodage.
3. **Poser les circonscriptions de Paris**, trame des 80 quartiers + coupures
   par axes BD TOPO. Comble 1986 et ouvre 1958-1986.
4. **Contrôler la couche circonscriptions** par les § 1, 3, 4 et 6 de l'annexe
   VI — les seules sections qui ne passent pas par les cantons, donc les seules
   testables sans nomenclature cantonale de 1986.
5. **Marseille**, quand le géoréférencement sera fait.

## Questions ouvertes

- La liste des lois créant des cantons annoncée p. 828 renvoie à l'annexe VI ;
  elle est en réalité **annexe VII**. Vérifié.
- Oyonnax : l'annexe VII dit « dédoublement », donc canton source disparu ;
  l'Insee garde le code `0123` renommé Oyonnax-Nord. À trancher.
- Le fond cantonal de Gaudillère est-il datable ? Si une nomenclature d'époque
  permettait d'identifier son millésime, tout l'atlas deviendrait exploitable
  d'un coup. Question à poser à Victor Gay.

### Registre cantonal consolidé — 11 août 2026

`cantons/consolide_registre.py` croise le différentiel 1940→1999 de la base
avec l'annexe VII et produit `cantons/mouvements_cantonaux.csv` : 2 024 lignes,
95 départements. **723 démembrements réels, dont 559 datés au décret — 77 %** ;
90 % de ces dates tombent dans les décennies 1970 et 1980.

Deux acquis, détaillés dans `cantons/registre_consolide.md` :

* **48 cantons créés entre 1986 et 1999**, nommés un par un. Chiffre confirmé
  par `verif_annexe_vii.py`, qui l'atteint par des effectifs sans connaître
  aucun nom, et dont les listes départementales coïncident. Ni l'annexe ni le
  COG ne portent cette information.
* **160 lignes relèvent d'un changement de cadre départemental**, non d'un
  mouvement cantonal : Corse scindée en 1976, Seine et Seine-et-Oise démembrées
  en 1964, Marseille et Lyon en pseudo-cantons. Rangées d'abord parmi les
  créations tardives, elles en inventaient 120. Même piège que les 22 atomes
  « déplacés » de `35`, ramenés à 8 — un changement de référentiel se déguise
  en événement.

Reste indatable : 274 transferts isolés de communes, que l'annexe VII ne
recense jamais, et les 48 post-1986 en attente d'une source couvrant 1986-1999.

### Géométries cantonales modernes — 11 août 2026

Question : récupérer des cantons même postérieurs à 2012 pour limiter le
découpage manuel des villes dans QGIS. Détail dans `cartes/note_cantons_2025.md`.

GEOFLA est hors course, tous millésimes : l'édition 2014 replie chaque ville
divisée en pseudo-canton (295 au code ≥ 90), comme la couche 1999 déjà en base.

**ADMIN EXPRESS v4 (avril 2025)** est la première à publier le contour réel :
670 cantons sur 2 055 coupent une commune, 216 communes coupées. Mesure par
`cartes/couverture_cantons_2025.py` :

* période historique 1870-1940 : **118 villes divisées, 80 servies (67 %)** ;
* mais **26 % seulement des coupes internes** — 123 offertes sur 472 requises.
  Nantes demande 17 coupes, 2025 en offre 1.

La maille s'est effondrée : 4 056 cantons en 2012, 2 055 en 2025. Règle qui
prédit la disponibilité : une commune est coupée en 2025 si et seulement si
elle pèse plus qu'un canton entier de son département (91 % des servies
au-dessus de la cible, 87 % des non servies en dessous).

À prendre comme fond de calage pour les 80 villes les plus lourdes, pas comme
économie. Piste suivante non vérifiée : CONTOURS-IRIS, maille comparable.

### Paris — trame des 80 quartiers posée, 11 août 2026

`circo/paris_quartiers.py` reconstruit les 80 quartiers administratifs par
union d'IRIS (CONTOURS-IRIS, INSEE-IGN, **Licence Ouverte 2.0** — le jeu de la
Ville de Paris étant en ODbL, inutilisable ici). Les deux premiers caractères
du numéro d'IRIS désignent le quartier, et à Paris les limites d'IRIS sont
calées sur les limites de quartier. 992 IRIS, 80 quartiers, 4 par
arrondissement.

**Contrôle : 80 noms sur 80 retrouvés dans le vocabulaire de la transcription
de l'atlas**, deux sources jamais mises en contact. Douze écarts, tous de nom,
aucun de trame. Deux acquis produits par la confrontation : le quartier 54 a
été renommé (Santé → Parc-de-Montsouris), et « le roule » d'avant 1860 se
distingue de « roule », quartier 30 d'après.

Surface : 105,43 km² contre 104,90 à GEOFLA — c'est l'IRIS qui a raison
(105,4 km² officiels, bois compris), GEOFLA qui généralise.

Limites : la trame ne vaut qu'à partir de 1860 (bois annexés en 1852 et 1860),
et sa fidélité aux limites de 1876 est réputée, non vérifiée.

**Paris n'est plus irréductible.** Reste à rattacher les circonscriptions à la
trame — plus rien ne le bloque.

### Paris — circonscriptions posées, 11 août 2026

`circo/paris_circo.py` rattache la transcription de l'atlas à la trame des 80
quartiers : **386 circonscriptions, 15 divisions de 1863 à 1986**, chacune
rendant 105,43 km² — Paris entier à chaque date. Quatorze divisions se
résolvent sans un nom hors trame.

Trois résultats au-delà du rattachement :

* **1958-1986 est posé**, alors qu'il est bloqué nationalement par le trou
  cantonal 1941-1998 : à Paris il se définit par quartiers, pas par cantons.
  C'est le premier morceau de 1958 qui existe en géométrie.
* **Le régime de scrutin se lit dans les données** : 1919-1928 et 1945-1958 ne
  comptent que 3 circonscriptions pour 80 quartiers — scrutin de liste par
  secteur.
* **Piège des homonymes** : 16 noms d'avant 1860 se résolvent contre la trame
  moderne alors qu'ils désignent d'autres territoires. Écartés par une
  barrière de date. Sans elle, 16 rattachements faux et invisibles.

Reste : les 3 à 9 quartiers partagés par division (rues à couper, axes
BD TOPO), la période `?-?` non datée, et l'avant-1860.

### Réponse de Victor Gay — 14 août 2026

Deux verrous sautent, un troisième se précise.

**Licence : la base Cassini EHESS est utilisable.** Gay confirme n'avoir jamais
employé Cassini-Geopeuple (CC BY-NC-SA, exclu) mais `cassini.ehess.fr`, dont le
dépôt publié — didomena.ehess.fr/concern/data_sets/6395wb092 — porte
**CC BY 3.0 FR**, vérifié sur la notice. Compatible CC BY-SA. Son propre travail
est en CC BY 4.0. La piste EHESS sert donc aussi à publier, et pas seulement à
vérifier comme on l'avait noté.

Réserve : la CC BY 3.0 est portée par la notice du dépôt ; le site lui-même
n'affiche pas de licence. L'extension de l'une à l'autre est la lecture de Gay,
raisonnable mais non garantie. À confirmer auprès du CRH avant publication.

**Le COG 1954 n'est pas ce qu'on croyait.** Gay ne l'utilise que pour CODER les
cantons disparus avant 2011 mais vivants en 1954 ; la nomenclature n'existait
pas avant 1949, elle est donc non officielle, et pour les cantons déjà disparus
en 1954 il forge une codification ad hoc (article p. 198). La composition
communale, elle, vient de Cassini EHESS. Le COG 1954 n'est pas en ligne.

**Mais une source publique porte la composition de 1954** — recensement de
1954, *Population de la France. Départements, arrondissements, cantons et
communes (métropole)*, INSEE, **domaine public** :
https://www.bnsp.insee.fr/ark:/12148/bc6p06z8sm1

Nomenclature cantonale en introduction de chaque département, et composition
communale implicite via les tableaux de population. **C'est un jalon daté au
milieu du trou 1943-1999**, en domaine public et citable par URL. Aucun
équivalent pour 1946, y compris en fascicules départementaux.

L'OCR n'est pas récupérable par outil automatique (réponse vide, comme
Gallica) ; le document s'ouvre en navigateur. Reste à juger si l'extraction est
scriptable ou manuelle — c'est ce qui décide de l'ampleur du chantier.

**Engagement pris** : Gay demande le détail des comparaisons, écrivant avoir
« probablement fait quelques erreurs ». Le contrôle indépendant et les
désaccords résiduels lui sont dus.

### Le recensement de 1954 — un jalon dans le trou cantonal, 14 août 2026

Détail dans `cog1954/note_1954.md`. Source en **domaine public**, citable par
URL : https://www.bnsp.insee.fr/ark:/12148/bc6p06z8sm1

Le document donne **mieux que ce qu'annonçait Victor Gay**. La composition
cantonale n'y est pas implicite : chaque ligne de commune porte deux colonnes
numériques, arrondissement et canton, entre la population de 1946 et le nom.

**Et la numérotation est celle de la base.** Vérifié sur 22 communes de
l'Aisne : 22 sur 22, avec une cohérence géographique parfaite (Harly sous
Saint-Quentin, Haramont sous Villers-Cotterêts, Grougis et Hannapes sous
Wassigny). C'est la confirmation directe que les codes de TRF-GIS sont alignés
sur 1954 — aucune traduction de codes nécessaire entre 1940 et 1954.

Le PDF n'a **aucune couche texte** : 958 pages d'images bitonales à 300 dpi.
L'OCR est à faire, mais le cas est favorable et Tesseract lit les colonnes sans
erreur visible sur les pages testées. Installer `tesseract-ocr-fra` avant la
passe complète : la jointure se fera par nom, le tableau ne portant aucun code
Insee.

Portée : **un point daté au milieu du trou, pas le trou comblé.** Rien sur
1943-1953 ni 1955-1998, et pas d'équivalent pour 1946.

### 1954 — les créations cantonales sont établies, 14 août 2026

Le recensement de 1954 porte en annexe un **« Tableau A — Modifications aux
circonscriptions territoriales »** (page 895) qui donne les cantons créés avec
leurs communes et leurs décrets. Transcrit dans `cog1954/tableau_a_1954.md`.

**Trois créations entre 1941 et 1954** : Sousceyrac (Lot, 5.9.1949), Tende
(Alpes-Maritimes, 10.9.1951), Brive-la-Gaillarde Nord et Sud (Corrèze,
13.9.1951, par scission de l'ancien canton). Plus un canton supprimé, trois
changements d'arrondissement et quatre transferts de chef-lieu.

**C'est exactement la liste de l'annexe VII de Gaudillère**, établie par une
source sans aucun rapport avec elle. Le régime cantonal est donc quasi immobile
de 1940 à 1954, ce qui autorise à reporter la composition de 1940 sur 1954 avec
des preuves plutôt que par hypothèse.

Reste : les transferts de communes entre cantons, que le volume dit nombreux
sans les lister — ils sont dans les tableaux de population, donc dans
l'extraction ligne à ligne (79 % de couverture, 90 départements retrouvés par
l'ordre alphabétique).

### Rapport pour Victor Gay — préparé le 14 août 2026

`cantons/rapport_pour_victor_gay.md`. Il honore l'engagement pris dans sa
réponse du 14 août et répond à sa demande de « détail des comparaisons ».

Contenu : l'appariement parfait des clés (0 orphelin dans les deux sens, 1870
et 1940), les surfaces à moins de 1 % dont l'écart s'explique entièrement par
notre double comptage, l'IoU de 0,992, et surtout le diagnostic des 148
désaccords — ils suivent le partage de polygone, pas la source de la géométrie,
et il n'en reste que **3 sur 38 235** après élimination du mécanisme.

**Aucune erreur ne lui est imputée.** Les trois divergences réelles
(Haute-Marne 130,1 km², Deux-Sèvres 88,1, Marne 59,0) tiennent chacune à un
polygone partagé où les deux lectures sont défendables.

En retour, le rapport lui apporte le recensement de 1954 — qu'il cherchait,
ayant dû forger une codification ad hoc faute de COG 1954 en ligne — avec sa
nomenclature cantonale codée, son tableau A daté, et la confirmation sur pièces
que la numérotation du volume est celle de TRF-GIS.

### La série des recensements — trouvée le 14 août 2026

Le volume de 1954 appartient à une **série périodique 1954-1976** de la
Bibliothèque numérique de la statistique publique :
https://www.bnsp.insee.fr/ark:/12148/cb32841307b/date

**87 fascicules pour 1968, un par département**, avec le même dispositif : un
code de canton par commune au tableau III, et — nouveauté par rapport à 1954 —
**le nombre de communes par canton au tableau II**, soit une recette de
contrôle fournie par la source.

Un volume distinct pour 1999 (ark cb36946269j). Restent à chercher 1962, 1975,
1982, 1990.

**Conséquence** : le trou cantonal 1943-1999, seul blocage structurel du
projet, cesse d'être un trou pour devenir une série de jalons à extraire —
1954, 1968, puis les autres. Toute la chaîne écrite aujourd'hui se réutilise,
et les fascicules départementaux simplifient le problème puisque le département
est dans le titre.

### La trame de découpe est en base — 14 août 2026

`histgis.iris_ville` : **4 219 IRIS**, CONTOURS-IRIS (INSEE-IGN, Licence
Ouverte 2.0), récupérés par `cartes/recupere_iris.py` au WFS de la Géoplateforme.

**Les 119 villes à découper sont servies.** La condition nécessaire
`IRIS >= coupes + 1` tient pour 116 d'entre elles, soit **211 des 214 coupes**.

| verdict | villes |
|---|---|
| trame confortable | 114 |
| trame juste suffisante | 2 |
| sans trame | 3 |

Marseille reçoit 393 IRIS et Lyon 185, pour 11 et 12 coupes : les deux villes
les plus coûteuses du chantier sont les mieux pourvues.

Sans trame — un seul IRIS, donc aucune ligne interne, une coupe chacune :
Confolens (16106), Tartas (40313), **Le Quesnoy** (59481).

**Le Quesnoy n'était pas prévu.** Les deux premières avaient été annoncées par
le seuil de population publié par l'INSEE ; la troisième n'est apparue qu'à la
récupération. Le critère qui décide n'est pas la population mais le nombre
d'IRIS effectivement publiés — il fallait le mesurer, pas le déduire. Dans
l'autre sens, l'estimation d'avant récupération donnait 88 % des coupes
couvertes ; le réel est de 98,6 %, le seuil des 5 000 habitants étant appliqué
plus souplement que la règle ne l'annonce. L'estimation se trompait des deux
côtés à la fois.

#### Le piège des arrondissements, troisième occurrence

Le premier passage a rendu **zéro IRIS pour Marseille et pour Lyon**.
CONTOURS-IRIS code ces communes par arrondissement municipal — 13201-13216 et
69381-69389 — jamais par 13055 ni 69123. Même chose pour Paris (75101-75120).

C'est le piège déjà rencontré dans GEOFLA, où il faisait ressortir Marseille
comme « non divisée », et dans le codage parisien. Trois sources indépendantes,
trois fois la même chausse-trappe : le code de la commune-mère n'existe pas
dans la donnée.

Ce qui le rend dangereux : **un zéro n'a pas l'air d'une erreur.** Pour une
commune de 3 000 habitants, zéro IRIS est la bonne réponse. L'anomalie n'a été
visible que parce qu'elle frappait les deux plus grandes villes du lot. Sur une
ville moyenne, elle serait passée pour un fait, et trois coupes auraient été
tracées sans trame en croyant qu'il n'y en avait pas.

**Règle qui en sort** : un résultat nul se confronte à l'ordre de grandeur
attendu, pas seulement à sa plausibilité. C'est la même famille que la règle du
référentiel — le référentiel n'avait pas bougé ici, mais la clé d'entrée
n'était pas celle qu'on croyait.

#### Ce que la trame ne prouve pas

Disposer d'une ligne n'est pas disposer de la bonne. Les IRIS sont calés sur la
voirie et les îlots, pas sur les limites cantonales — sauf à Paris, où l'INSEE
les cale explicitement sur les limites de quartier, ce qui avait permis de
reconstruire les 80 quartiers par simple union. Ailleurs c'est un support
d'accrochage : des lignes propres, topologiquement valides, calées sur des rues
réelles, où l'on choisit au lieu de dessiner. **Le taux de reprise réel se
mesurera ville par ville dans QGIS**, Marseille en premier.

### La composition cantonale est dans le texte des décrets — 15 août 2026

`cantons/composition_decrets.py`, contrôle par `cantons/controle_composition.py`.

Le trou 1941-1999 était tenu pour hors de portée de
`communes_coupees_1973_1984.csv`, au motif que ses colonnes structurées sont
`canton` / `commune_coupee` et jamais `canton` / `commune`. C'est exact des
colonnes. C'est faux du fichier : **la colonne `texte` porte le texte intégral
du JO**, et ce texte dit la composition en prose.

| | |
|---|---|
| lignes portant un texte transcrit | 579 — 100 % |
| dont « comprenant les communes de … » | 289 |
| décrets concernés | **91 sur 117** |
| cantons pourvus d'une composition | **290** |
| rattachements de commune entière extraits | **1 295** |

Appariement au dictionnaire de noms :

| | | |
|---|---|---|
| exact | 1 166 | 90,0 % |
| disparue avant 2011 (`insee_mvt.libelle_av`) | 31 | 2,4 % |
| ressemblance (difflib ≥ 0,88) | 39 | 3,0 % |
| aucun | 59 | 4,6 % |

#### Le contrôle indépendant : zéro désaccord

Le COG de 1999 n'a jamais vu le texte du JO. Confronté aux 179 cantons dont la
liste compte au moins trois communes entières :

| verdict | cantons |
|---|---|
| accord (≥ 80 % des communes dans le même canton en 1999) | **155** |
| accord partiel (50 à 80 %) | 24 |
| **désaccord** | **0** |

**1 042 communes sur 1 102 se retrouvent en 1999 dans le canton où le décret
les avait mises — 94,6 %.**

Le taux se lit comme un plancher, pas comme une note : entre le décret et 1999,
une commune a pu changer de canton par un décret non dépouillé. C'est même
attendu, puisque c'est ce que le registre cantonal recense. Un désaccord aurait
été ambigu ; leur absence complète, elle, ne l'est pas.

#### Ce que les 88 rejets du premier passage ont appris

Ils portaient « Campet », « Lucbardez », « Louzac », « Ferreux ». On les prend
d'abord pour des coupures fautives de noms à rallonge — Campet-et-Lamolère,
Louzac-Saint-André — donc pour un défaut du découpage sur « et ».

Le texte du JO dit exactement « Campet » et « Louzac ». **Ce sont les vrais
noms de 1982** ; les noms longs sont le produit de fusions postérieures. Le
parseur n'était pas en cause, le dictionnaire l'était : GEOFLA 2011 ne connaît
que les survivantes.

C'est le même défaut qui laisse 7 576 noms non appariés dans l'extraction de
1954, et **le même correctif y répond** — `insee_mvt.libelle_av`, 7 668
libellés d'avant mouvement. Mesuré ici : il récupère 33 % des rejets, à
condition de contraindre le département. Sans cette contrainte le taux monte à
43 %, mais « Saint-Hilaire » cité par un décret de l'Aube s'apparie alors à un
code de Charente — un gain de taux payé en erreurs muettes.

#### Ce que cela ne fait pas

Un décret donne la composition des cantons **qu'il crée ou modifie**, jamais
celle des 4 000 autres. Le trou ne se comble donc pas par cette seule voie.
Mais la base n'a pas besoin de la composition à chaque date : elle a besoin
d'une base de départ et des deltas. 1940 est posé, 1954 est extrait, 1999 vient
du COG — **les décrets sont les deltas**. C'est l'architecture de `membership`
avec ses `daterange`.

Rien n'est posé en base à ce stade. `composition_decrets.csv` est un fichier à
relire.

### Correction — la série des recensements n'a qu'une année numérisée, 15 août 2026

Vérifié sur la notice `https://www.bnsp.insee.fr/ark:/12148/cb32841307b/date` :
**« 1 année disponible »**, et `/date1968` confirme que c'est **1968**.

La description bibliographique de la publication couvre bien 1954-1976 — c'est
la périodicité de l'ouvrage, pas l'état de la numérisation. Les deux avaient
été confondus dans la note du 14 août, qui annonçait « restent à chercher 1962,
1975, 1982, 1990 » comme si ces millésimes attendaient dans le même fonds.

**Ce qui est effectivement en ligne, à ce jour :**

| millésime | ark | état |
|---|---|---|
| 1954 | `bc6p06z8sm1` | récupéré, extrait, contrôlé |
| 1968 | `cb32841307b/date1968` | **à récupérer — 87 fascicules départementaux** |
| 1999 | `cb36946269j` | non vérifié |

1962, 1975, 1982 et 1990 sont donc à **chercher**, pas à cueillir : autre
notice, autre fonds, ou pas numérisés du tout.

**Conséquence sur le plan** : l'angle mort 1987-1998 ne se referme pas par un
fascicule de 1990 comme espéré. Il faudra soit trouver ce volume ailleurs, soit
s'en remettre aux décrets du JO — dont l'annexe VII ne donne plus la liste
après 1986.

**Leçon** : « la série va de 1954 à 1976 » décrivait la publication, pas la
numérisation. Une phrase vraie lue comme si elle répondait à une autre
question — la même famille d'erreur que le dénominateur des 119 villes.
