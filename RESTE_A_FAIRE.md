# Ce qui reste à faire — état au 14 août 2026

Dressé après la journée du 14 août. Les tâches sont classées par chantier, et
dans chacun par ordre de valeur, pas de facilité. Le blocage est indiqué quand
il y en a un : beaucoup de choses attendent quelque chose plutôt que quelqu'un.

---

## 1. Le trou cantonal 1955-1998 — le seul blocage structurel

C'était le seul obstacle à l'objectif du projet. Il n'est plus un mur mais une
série de jalons à extraire.

| tâche | état | blocage |
|---|---|---|
| **Récupérer un fascicule de 1968** et le passer dans la chaîne | à faire | **site BNSP indisponible** |
| Vérifier d'abord si le PDF de 1968 a une couche texte (`pdftotext -layout`) | à faire | idem |
| Extraire les 87 fascicules de 1968 | à faire | dépend du test ci-dessus |
| Vérifier l'existence de 1975, 1982, 1990 dans la série | à faire | idem |
| 1962 : confirmé présent, à extraire | à faire | idem |

**Premier fascicule conseillé : Calvados ou Aisne**, dont on a déjà la
composition de 1940 et de 1954 — trois dates à confronter au lieu de deux.

L'outil est prêt : `extrait_1954.py --pdf … --dep 14`. Sur un fascicule
départemental le département est dans le titre, donc toute la détection
d'en-tête et le redécoupage alphabétique deviennent inutiles.

## 2. Le volume de 1954 — acquis, perfectible

**Acquis** : trois créations cantonales établies par trois voies indépendantes,
98 % de stabilité 1940-1954, tableau A transcrit.

| tâche | valeur | difficulté |
|---|---|---|
| **Ajouter `insee_mvt.libelle_av` au dictionnaire de noms** | forte | faible |
| Remonter la couverture au-delà de 79 % | moyenne | moyenne |
| Poser 1954 dans la base (`membership` 1940 → 1954 + 3 créations) | forte | moyenne |

Le premier point est le meilleur rapport : 7 576 noms non appariés, dont une
part importante sont des communes disparues avant 2011, donc absentes de GEOFLA
qui sert de dictionnaire. Les ajouter ne touche pas à l'extraction.

**Abandonné, et à ne pas reprendre par cette voie** : les transferts de
communes entre cantons. 311 candidats, 227 réfutés par la géométrie, les
survivants indiscernables du bruit. Le volume dit qu'il y en a eu ; notre
lecture ne peut pas les distinguer d'un chiffre mal reconnu.

## 3. Paris — trame posée, découpage à finir

**Acquis** : les 80 quartiers reconstruits par union d'IRIS en Licence Ouverte,
80/80 noms confirmés par l'atlas, 386 circonscriptions posées sur 15 divisions,
`paris_circo.pdf` généré.

| tâche | valeur | blocage |
|---|---|---|
| **Les quartiers coupés par une rue** — 3 à 9 par division, 9 pour 1958-1986 | forte | axes BD TOPO à récupérer |
| Corriger la coquille de `paris_decoupage.xlsx` | faible | aucun |
| Dater la période `?-?` (37 circonscriptions complètes, sans date) | moyenne | pièces à trouver |
| La trame d'avant 1860 — 48 quartiers, 12 arrondissements | moyenne | **licence** |

La coquille : en 1857-1863, `montdepietemarais` fusionne deux quartiers en une
cellule, d'où 47 quartiers au lieu de 48. Les quatre autres périodes anciennes
en donnent bien 48.

L'avant-1860 : la couche ALPAGE-Vasserot existe et couvre exactement les 48
quartiers, mais elle est en **ODbL**. Route propre : géoréférencer un plan du
XIXe en domaine public, protocole de Marseille.

## 4. Les villes à découper — 119, et rien n'est commencé

| tâche | valeur | blocage |
|---|---|---|
| **Marseille** : géoréférencer et digitaliser dans QGIS | forte | à faire à la main |
| Puis lancer `sql/32_marseille_geom.sql` | — | dépend du précédent |
| Les 118 autres villes | forte | même travail |
| ~~Tester CONTOURS-IRIS comme trame de découpe~~ | **fait le 14 août — la trame est bonne** | — |
| ~~Récupérer les IRIS des 119 villes~~ | **fait le 14 août — `histgis.iris_ville`, 4 219 IRIS** | — |

**Testé, et l'hypothèse tient.** CONTOURS-IRIS couvre **97 % des villes et
88 % des coupes**, contre 26 % pour ADMIN EXPRESS. Le chantier réel est de
**214 coupes** et non 472, dont **81 villes à trait unique**. Seules Confolens
et Tartas, sous 5 000 habitants, sont sans trame — une coupe chacune.

**La trame est récupérée et chargée** : `histgis.iris_ville`, 4 219 IRIS, les
119 villes servies, **211 coupes sur 214** pourvues d'au moins une ligne
interne. Marseille (393 IRIS) et Lyon (185) sont les mieux dotées, ce qui tombe
bien puisqu'elles portent 23 des 214 coupes.

Trois villes sans appui, une coupe chacune : Confolens, Tartas et **Le Quesnoy**
— cette dernière n'était pas prévue par le seuil de population, elle est
apparue à la récupération.

Reste à mesurer le **taux de reprise réel** ville par ville dans QGIS : disposer
d'une ligne n'est pas disposer de la bonne. Marseille en premier, ses onze
lignes étant décrites dans `gaudillere/protocole_georeferencement.md`.

## 5. Circonscriptions législatives

| tâche | valeur | blocage |
|---|---|---|
| Contrôler la couche circo par l'annexe VI §§ 1, 3, 4, 6 | forte | aucun |
| `circo_1986_indetermine.csv` : 135 communes, 24 cantons à valeur textuelle | moyenne | aucun |
| Poser les circos nationales sur la trame cantonale | forte | **trou cantonal** |

Les sections 1, 3, 4 et 6 de l'annexe VI ne passent pas par les cantons : elles
sont contrôlables tout de suite, indépendamment du trou.

## 6. Dettes et démarches

| tâche | état |
|---|---|
| **Envoyer le rapport à Victor Gay** — `cantons/rapport_pour_victor_gay.md` | rédigé, à relire et envoyer |
| Confirmer la licence Cassini EHESS auprès du CRH avant publication | à faire |
| CRH-EHESS et INSEE : relancer ? | courriels du 10 août sans réponse |
| **Embargo ANR-COMMUNES** : levée le 1er septembre 2026 | attendre |

L'ANR-COMMUNES réglerait à la racine les recouvrements et les trous de
couverture. C'est dans deux semaines.

## 7. Limites connues, non résolues

* **Recouvrements** : 12 822 km² au niveau des cantons, 3 945 km² au niveau des
  atomes. Diagnostiqués — c'est le partage de polygone entre communes absorbées
  — mais non corrigés. Le correctif viendra de l'ANR.
* **`hac_partage`** : rattachement par nom, arbitraire et révocable. Le contrôle
  Gay ne peut ni le condamner ni l'innocenter.
* **48 cantons créés entre 1986 et 1999** : nommés, non datés. Il faut une
  source couvrant cette période.
* **274 transferts isolés de communes** dans le registre cantonal : l'annexe VII
  ne recense jamais ce type de mouvement. Indatables sans les décrets.

## 8. Hygiène du dépôt

| tâche | valeur | difficulté |
|---|---|---|
| Écrire `environment.yml` ou `requirements.txt` | moyenne | triviale |
| Regrouper les scripts de 1954 sous un nom générique (ils serviront à 1968) | faible | faible |

Aucun fichier d'environnement n'existe : psycopg2, matplotlib, shapely,
openpyxl, xlrd, pyshp, pyproj sont utilisés sans être déclarés nulle part.

---

## Ce qui se ferait le mieux maintenant, site indisponible

1. ~~Tester CONTOURS-IRIS~~, ~~récupérer les IRIS~~ — **faits**. 4 219 IRIS en
   base, 211 coupes sur 214 pourvues. Suite : **attaquer Marseille dans QGIS**,
   et mesurer le taux de reprise réel.
2. **Ajouter `insee_mvt.libelle_av`** au dictionnaire de noms de 1954.
3. **Contrôler la couche circo** par les sections de l'annexe VI qui ne passent
   pas par les cantons.
4. **Relire et envoyer** le rapport à Victor Gay.
