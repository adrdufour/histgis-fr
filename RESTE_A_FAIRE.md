# Ce qui reste à faire

**Arrêté au 2 septembre 2026.** Les tâches sont classées par valeur, pas par
facilité. Le blocage est indiqué quand il y en a un : beaucoup de choses
attendent quelque chose plutôt que quelqu'un.

> Ce fichier a été condensé le 2 septembre 2026. Il avait dérivé en journal :
> quinze sections datées, la même tâche reparaissant dans cinq tableaux
> successifs avec des états différents, et des dizaines de lignes barrées.
> **Ce qui est fait n'y figure plus** — c'est le rôle de `JOURNAL.md`, qui
> garde tout à sa date, et d'`ETAT.md`, qui dit où en est chaque couche.
> Seul ce qui reste ouvert est ici.

---

## 0. La file d'attente immédiate

Dans cet ordre. Les quatre premières se font sans rien chercher.
(La numérotation portait deux « 4 » ; corrigée le 2 septembre 2026.)

| # | tâche | pourquoi maintenant |
|---|---|---|
| 0 | **Les atomes-fraction de villes multicantonales sans aucune géométrie** | 318 atomes vivants à 1870 ne sont dessinés nulle part, et les vingt premiers sont surtout des fractions de Montluçon, Moulins, Sedan, Troyes, Carcassonne, Aix-en-Provence — sans même le polygone de leur mère. Ces cantons sont dessinés courts. Défaut antérieur à `82` et à `84`, rendu visible par `diag_partition.sql` § 8. **Premier geste** : compter fractions et non-fractions séparément (requête ci-dessous), parce que ce sont deux problèmes |
| 0 bis | **La Guérinière**, le seul atome de France où la reprise échoue | 0,4 km². Il réapparaît chez ANR mais aucun voisin ne se coupe au même millésime. La commune a été formée en 1919 de DEUX communes-mères ; si c'est la cause, la règle gagne un cas, sinon elle se déclare telle quelle. À trancher, pas à rafistoler |
| 1 | **Jouer `81_report_1968_avant.sql`** sur la vraie base, après `79` | écrit, éprouvé au banc, **confirmé non joué le 2 septembre** : 191 000 atome-années en attente, +45 % de couverture, zéro collision mesurée |
| 2 | **Expliquer trois traces absentes : `25`, `40_outremer`, `37`** | mesuré le 2 septembre — voir ci-dessous ; `37` est le plus inquiétant des trois |
| 3 | **Établir l'état de `38_decret_1982_ain.sql`** puis le rejouer si besoin | § 2 c de `diag_passages.sql` ; attention, il se tait au rejeu si `75`/`76`/`79` occupent déjà 1982-1999 |
| 4 | **Donner une trace à `38` et `39`** | rien dans la base ne dit s'ils sont passés — c'est ce qui a laissé un `rebuild.sh` défaire `39` en silence pendant quinze jours |
| 5 | **Lancer un export web complet** et mesurer le poids | seule chose que le banc ne peut pas dire ; attendu 92 Mo → deux à trois fois plus. Désormais sans conséquence pour le dépôt : `donnees/` est ignoré |
| 5 bis | **Exporter un département avec `--partition` dans un dossier à part**, et comparer à l'ordinaire | `python3 cartes/export_web.py 01 --partition --sortie /tmp/part`. C'est la seule façon de voir la couture disparaître avant de décider de remplacer la trame. Vérifier au passage le taux de déduplication des versions : s'il est proche de 1, `ST_Equals` ne fait pas son travail et `communes.json` va enfler |
| 5 ter | **Afficher `repris` dans `cartes/web/index.html`** | l'export pose désormais `repris` par unité à côté de `anr` et `repli` ; la page l'ignore. Une unité qui doit sa forme à une reprise doit pouvoir le dire, sans quoi la légende laisse croire à une trame entièrement attestée |
| ~~6~~ | ~~Écrire `requirements.txt` ou `environment.yml`~~ | **fait le 2 septembre 2026** : `environment.yml` à la racine, relevé sur les imports réels et non sur la liste de `LISEZMOI.md`, qui annonçait `pyproj` (jamais importé) et taisait `pandas` et ImageMagick. Le serveur PostgreSQL en est volontairement absent — l'y mettre installerait le piège de la socket |

> **Les points « compléter `.gitignore` » et « commiter » sont faits le
> 2 septembre 2026.** `cartes/web/donnees/` est détaché de l'index (1 546
> fichiers, 3,3 Go, gardés sur le disque), les 4 Go de reçus sont ignorés
> nommément, et les treize jours sont versionnés en huit commits. Le détail
> est au § Git de `LISEZMOI.md`. Deux choses apprises, qui valent pour la
> suite :
>
> * **Git n'applique pas ses motifs d'exclusion à un fichier déjà suivi.**
>   `sorties/` était ignoré depuis toujours et ses deux rapports étaient
>   pourtant suivis. Une règle ajoutée après coup ne rattrape rien : il faut
>   `git rm --cached`.
> * **Un `#` en fin de ligne ne commente pas un `.gitignore`** — il fait
>   partie du motif. `/JORF/    # 2,6 Go` n'ignore rien, et ne le dit pas.
>   Vérifier par `git check-ignore -v`, jamais à l'œil.

**Avant et après chaque point, `psql -d histgis -f sql/diag_passages.sql`** —
lecture seule. Il dit quels fichiers sont réellement passés, lesquels ont une
trace vide, et lit par leur effet les deux qui n'en ont pas.

```bash
psql -d histgis -1 -f sql/81_report_1968_avant.sql    # APRÈS 79
```

Attendu de `81` : ~32 842 lignes, ~191 000 atome-années. Le repère mesuré le
2 septembre, à comparer après coup :

| au | avant `81` | après `81` |
|---|---|---|
| 1969-06-01 | **0** | des dizaines de milliers |
| 1974-06-01 | 5 198 rattachements, 474 cantons | **inchangé** |
| 1989-06-01 | 23 233 | inchangé |
| 1994-06-01 | 30 783 | inchangé |

Si 1974 bouge, `81` a mordu sur `79` et il faut s'arrêter. Regarder ensuite le 95
dans `p81_qualite` (78,1 % de jamais-nommés, le plus bas ; probablement
l'éclatement de la Seine-et-Oise et non un trou du registre).

**`39` est appliqué** — vérifié le 2 septembre, 0 canton en `99` et 73 en `54`.
Il n'y a rien à rejouer ; il reste à lui donner une trace (point 4).

### Le détail du point 2 — trois traces absentes, trois questions différentes

Le § 4 de `diag_passages.sql` les lit par leur effet. Ce qu'il faut regarder
dans l'ordre de gravité :

**`37_reparer_encodage.sql` — et la cause est trouvée : rien ne l'appelle.**

`rejouer_apres_rebuild.sh` annonce en commentaire l'étape
« COG 1999-2012 (22, 36, **37**, 23) » et délègue à `load_cog.sh`. Or
`load_cog.sh` ne joue que `22_cog_stage.sql` et `23_cog_diag.sql`. **`37` n'est
appelé par aucun script de la chaîne** — et le commentaire lui attribue en outre
la création de `noms_geofla`, qui est le fait de `19`.

Un commentaire qui décrit ce que le code ne fait pas, et personne ne l'a relu
depuis le 20 août parce qu'il n'y avait rien à voir : la chaîne ne se plaint
pas d'un fichier qu'elle n'appelle pas. C'est le pendant exact du défaut de
`41`, où le commentaire annonçait 21 cas et la requête en sortait 38
(`METHODE.md` § 15.2).

La réparation qu'il porte n'est pas cosmétique — 1 975 valeurs, tous les `œ` et
`Œ` de la nomenclature, c'est le défaut n° 4 des sept trouvés le 11 août. Sans
elle, tout appariement par nom échoue silencieusement sur ces valeurs. Le § 4 b
compte les octets de contrôle C1 dans `unit.nom` et `unit_version.nom` ; s'il en
trouve :

```bash
psql -d histgis -1 -v appliquer=1 -f sql/37_reparer_encodage.sql
```

**Et il faut l'ajouter à la chaîne**, avec son `-v appliquer=1`, en corrigeant le
commentaire qui prétend qu'il y est.

**`25_pseudo_canton.sql` — à expliquer.** Sa trace est créée sans condition, et
il est appelé sans condition juste après `24` dans la chaîne. Son absence
signifie qu'il n'a pas tourné depuis le dernier `rebuild.sh`, alors que `24` l'a
fait. Conséquence si c'est le cas : **les 25 arrondissements de Marseille et Lyon
n'ont aucun canton de 1999 à 2012**, et l'effectif de 3 843/3 846 cantons est
faux de deux unités. Le § 4 a tranche.

**`40_outremer.sql` — à expliquer.** Même situation, et son CSV d'entrée
(`circo/circo_outremer_1986_2012.csv`) est bien sur le disque, donc ce n'est pas
la panne de `-v` du 20 août. Le § 4 d compte les tables `om_*` : neuf attendues.

**Hypothèse la plus probable pour les deux**, et elle n'est pas un échec du
script : `rejouer_apres_rebuild.sh` porte bien `set -euo pipefail` et
`ON_ERROR_STOP=1`, donc il s'arrête au premier échec — il n'a pas pu poser `42`
et `50` en sautant `25` et `40`, qui les précèdent. **Le script n'a donc pas été
joué de bout en bout** ; les fichiers ont été lancés un par un, et ces deux-là
sont passés à travers. C'est cohérent avec tout le reste de la chaîne au-delà de
`56`, joué à la main lui aussi (voir ci-dessous).

### Et pendant qu'on y est : `rejouer_apres_rebuild.sh` est périmé

Il s'arrête à `56_paris_circo_1876.sql`. **Rien de ce qui a été écrit depuis le
20 août n'y figure** — ni les jalons `58`/`59` et `66`-`69`, ni le registre `72`,
ni les salves `74`-`77`, ni les reports `79` et `81`, ni ANR `82`. Leurs traces
sont pourtant en base : ils ont donc été joués **à la main**, un par un.

Conséquence directe : **le prochain `rebuild.sh` détruira tout ce travail et le
script ne le remontera pas.** C'est la même mécanique qui a défait `39` en
silence, à une échelle sans commune mesure — 1954, 1968, les salves, les deux
reports, la trame ANR.

À faire avant tout `rebuild.sh` : compléter le script jusqu'à `83`, avec l'ordre
et les variables `-v` de chacun, en reprenant `sql/CHAINE.md`.

---

## 1. Cantons 1943-1999 — étendre la couverture

Le trou n'en est plus un (`ETAT.md` § 2.3), mais la couverture reste molle
entre les jalons.

| tâche | valeur | blocage |
|---|---|---|
| **Rétroporter `pct_jamais_nommes` et son dénominateur dans `p79_qualite`** | forte | aucun — `p81_qualite` le porte déjà |
| **Poser sur la part libre des fenêtres partiellement occupées** | 289 atomes récupérables | aucun ; la règle « tout ou rien » coûte désormais plus qu'elle ne protège |
| Le **chaînage acte par acte** sur les 54 départements intégralement dépouillés | forte | prendre un numéro libre : `82` est pris par ANR |
| Second tour sur la classe « modification de limites cantonales » | moyenne | 25 actes fixent encore un plancher ; le premier tour a rendu +18 %, pas +37 % |
| Un **troisième jalon : le recensement de 1975** | forte | au milieu des 1 147 dép-années noires ; la chaîne de `59` se réutilise telle quelle |
| Les **86 actes non dépouillés** | moyenne | file au § 7 bis de `80` : 91 (6), 54 (5), 59 (5), 38 (4), 92 (4), 76 (4) |
| Les **62 cantons annoncés au titre d'un décret et jamais lus** | moyenne | c'est là que se joue le rappel de l'extraction : 122 sur 184 |
| Poser le transfert de **Han-devant-Pierrepont** | faible | `77` a lu la modalité 43, celui-ci est en modalité 41 |
| Les **24 actes dont le JO manque** (13 numéros) | faible | ils ne bloquent rien, ils enrichiraient les compositions |

**Réserve permanente à ne pas oublier** : *un décret nomme les cantons qu'il crée
ou modifie, jamais ceux qu'il vide.* Tout chaînage acte par acte hérite de ce
biais, dont le sens est connu — il joue contre l'hypothèse, ce qui rend un
accord élevé plus solide qu'il n'en a l'air, et un accord faible ambigu.

**La part `sous_plafond` se retire en une requête** si elle est un jour jugée
trop risquée :

```sql
DELETE FROM histgis.membership m USING histgis.p79_qualite q
 WHERE q.membership_id = m.membership_id AND q.sous_plafond;
```

### Le mur 1986-1989

37 actes, aucun texte en clair sur Légifrance, aucun dépouillé,
`composition_jo.csv` s'arrête à 1988 avec cinq lignes. C'est aussi la fenêtre des
**48 cantons créés entre 1986 et 1999**, nommés un par un et non datés. PDF du JO
requis, même chaîne que `composition_jo.py`.

À ne pas refaire : la veine 1990-1999 est **épuisée, pas inexploitée**. Les 83
décrets de la décennie ont été lus — 19 portent une composition (en base par
`76`), 4 déplacent une commune entière (posés par `77`), 40 transfèrent des
parcelles (non-événements), 29 sont des tracés de rues, 10 sont sans texte.
*Une année absente d'un fichier de sortie n'est pas une année non lue.*

---

## 2. Les villes à découper — 119, et rien n'est commencé

C'est le plus gros chantier manuel restant, et le seul qui ne dépende d'aucune
source à trouver.

| tâche | valeur | blocage |
|---|---|---|
| **Marseille** : géoréférencer et digitaliser dans QGIS | forte | travail à la main ; protocole dans `gaudillere/protocole_georeferencement.md` |
| Puis lancer `sql/32_marseille_geom.sql` | — | dépend du précédent |
| Mesurer le **taux de reprise réel** ville par ville | forte | disposer d'une ligne n'est pas disposer de la bonne |
| Les 118 autres villes | forte | même travail |

**La trame d'accrochage est acquise et en base** : `histgis.iris_ville`,
4 219 IRIS, les 119 villes servies, **211 des 214 coupes** pourvues d'au moins
une ligne interne. Marseille reçoit 393 IRIS et Lyon 185, pour 11 et 12 coupes —
les deux villes les plus coûteuses sont les mieux dotées.

Trois villes sans appui, une coupe chacune : **Confolens** (16106), **Tartas**
(40313), **Le Quesnoy** (59481) — un seul IRIS, donc aucune ligne interne. Deux
en trame juste suffisante : Saint-Flour (15187) et Avesnes-sur-Helpe (59036).

**Ce que la trame ne prouve pas** : les IRIS sont calés sur la voirie et les
îlots, pas sur les limites cantonales — sauf à Paris, où l'INSEE les cale
explicitement sur les limites de quartier. Ailleurs c'est un support
d'accrochage : des lignes propres, topologiquement valides, calées sur des rues
réelles, où l'on choisit au lieu de dessiner.

ADMIN EXPRESS v4 (2025) reste utile comme **fond de calage, pas comme économie** :
26 % des coupes internes seulement (123 offertes sur 472 requises ; Nantes en
demande 17 et 2025 en offre 1).

---

## 3. Circonscriptions

| tâche | valeur | blocage |
|---|---|---|
| **Marquer les 113 communes indéterminées de 1986 sur la carte** | forte | aucun — voir ci-dessous |
| **Contrôler la couche circo** par les §§ 1, 3, 4 et 6 de l'annexe VI | forte | aucun : ce sont les seules sections qui ne passent pas par les cantons |
| Contrôle indépendant de la couche moderne | forte | les contours publiés sur data.gouv.fr peuvent jouer le rôle que GEOFLA a joué pour les cantons |
| Le découpage de **1958** hors Paris | moyenne | suspendu au trou cantonal ; 57 circos de 1986 sont reprises de 1981 (annexe VI § 7), et Marseille est constructible à 87 % par l'atlas |
| **Paris en 1986** | moyenne | demanderait une autre source que le tableau de l'Intérieur |
| Les 8 atomes coupés entre circos sans l'être entre cantons | faible | il faudrait des atomes-fractions taillés sur les circonscriptions |

### Les 113 indéterminées — un défaut d'affichage, pas de données

De 1987 à 1999 la couche cantonale est mince, et c'est celle des
circonscriptions qui dessine les communes : ces 113 **disparaissent purement et
simplement** de la carte. Le projet a une règle explicite — *ce qui n'a de nom
nulle part est signalé comme tel, pas maquillé* — et une absence silencieuse la
contredit.

**À faire** : charger `circo/circo_1986_indetermine.csv` dans une table
`circo_indetermine`, et les faire dessiner par `export_web.py` avec un figuré
propre (hachure, comme les communes coupées), les circonscriptions candidates au
survol. **Aucun rattachement dans `membership`** : la source ne tranche pas, la
base ne doit pas trancher non plus.

**Piste de résolution, à évaluer séparément** : pour chacune, les
circonscriptions candidates sont connues, et le découpage de 2009 rattache la
commune à l'une d'elles. Là où les limites n'ont pas bougé entre 1986 et 2009, le
rapprochement serait dicté par la source — même forme d'argument que la voie
`fraction` de `41`. À mesurer avant d'y toucher, et à ne poser que si la
correspondance est unique.

---

## 4. Paris

**Acquis** : 80 quartiers reconstruits par union d'IRIS en Licence Ouverte,
80/80 noms confirmés par l'atlas, 386 circonscriptions sur 15 divisions,
1958-1986 posé, `paris_circo.pdf` généré.

| tâche | valeur | blocage |
|---|---|---|
| **Les quartiers coupés par une rue** — 3 à 9 par division, 9 pour 1958-1986 | forte | axes BD TOPO à récupérer |
| Dater la période `?-?` — 37 circonscriptions complètes, sans date | moyenne | pièces à trouver |
| La trame d'avant 1860 — 48 quartiers, 12 arrondissements | moyenne | **licence** : ALPAGE-Vasserot couvre exactement les 48 quartiers mais est en ODbL. Route propre : géoréférencer un plan du XIXᵉ en domaine public, protocole de Marseille |
| Corriger la coquille de `paris_decoupage.xlsx` | faible | aucun — en 1857-1863, `montdepietemarais` fusionne deux quartiers en une cellule, d'où 47 au lieu de 48 |

---

## 5. ANR-COMMUNES — la migration est faite à côté, pas à la place

Chargé et contrôlé en base le 1ᵉʳ septembre : `atom_geom_anr`, 45 113 polygones
datés, 38 074 atomes pourvus, recouvrement **101,0 km² contre 3 945**.
`atom_geom` et `membership` n'ont pas été touchés.

| tâche | valeur | blocage |
|---|---|---|
| **Décider du sort de la double trame** | forte | `atom_geom` garde ses 3 945 km² ; faut-il migrer, ou garder les deux et documenter ? décision, pas travail |
| **Signaler à l'équipe ANR** : Beauvais, Flipou/Senneville, la Corse sans édition historique, les 3 `Poly_ID` à double fenêtre, et les **532 trous de chronologie** | moyenne | aucun |
| Décider du sort des 6 atomes doublons qu'ANR tranche (`a82_doublon`) | faible | décision |

**Ce qu'ANR ne réglera pas, et il faut le savoir** : les 333 fractions. ANR livre
le polygone de la commune-mère entière et ne sait pas la découper entre deux
cantons. Le chantier du § 2 reste entier.

**Le verrou neuf, pour l'extension avant 1870** : ANR ignore la frontière
nationale (`ETAT.md` § 5). C'est le premier obstacle à lever pour 1815.

---

## 6. Extension avant 1870

Ouvert, non commencé hors Paris. Gaudillère est la source principale. La
géométrie ne coûte plus rien — `82` a chargé tout ANR, 1790-2020, donc 1815 est
déjà dessiné (39 157 polygones, recouvrement 144,8 km²) — **ce qui manque, ce
sont les attributions et la frontière.**

À 1815, **10 259 polygones ne sont pas terminaux** : ANR affirme pour eux une
forme pré-moderne précise au lieu de projeter celle d'aujourd'hui. C'est du
contenu, et il est là où nous n'avons rien.

---

## 7. Dettes et démarches

| tâche | état |
|---|---|
| **Envoyer le rapport à Victor Gay** — `cantons/rapport_pour_victor_gay.md` | rédigé, à relire et envoyer ; il a demandé le détail des comparaisons |
| Y joindre les deux paris que HAC lui conteste | Le Theux (08447) et Sognolles-en-Montois (77454), donnés en accord par HAC aux deux niveaux |
| Reprendre Houat et Hœdic avec les bons codes | `45` § 5 filtre sur `insee_geofla` ; 17501 et 17191 sont des identifiants d'atome, pas des codes INSEE |
| Confirmer la licence Cassini EHESS auprès du CRH avant publication | la CC BY 3.0 FR est portée par la notice du dépôt, pas par le site |
| CRH-EHESS et INSEE : relancer ? | courriels du 10 août sans réponse |
| Regrouper les scripts de 1954 et 1968 sous un nom générique | faible, ils font désormais le même travail |

---

## 8. Chantiers ouverts, à mesurer avant d'écrire

Rien ici ne doit être corrigé d'office. Ce sont des cas où la mesure décide.

### Les trous intérieurs courts apparus après `46`

Avant `46`, les trous de `membership` se répartissaient en deux groupes nets :
**2 ans** (Cherré, corrigé) et **48 ans** (l'Alsace-Moselle, qui doit rester
ouverte). Après, des durées intermédiaires apparaissent — 2, 4, 5, 7, 9, 18 ×2,
27, 35, 39 ×2 ans, soit une dizaine d'atomes.

Hypothèse la plus simple : `46` pose une fenêtre qui **ne rejoint pas** le
premier rattachement propre de la commune, sa borne étant
`min(création selon HAC, premier rattachement propre)` — TRF-GIS connaît
Neuilly-Plaisance dès 1882, HAC la crée en 1892, et l'écart reste vide.

**À faire** : lister ces atomes avec leur commune et les deux dates de création.
Si l'hypothèse tient, deux voies, et il faudra choisir **en le disant** : combler
jusqu'au premier rattachement propre, ou laisser le trou et **déclarer le
désaccord de dates** entre HAC et TRF-GIS. La seconde est cohérente avec le
reste du projet — on préfère un trou déclaré à un rattachement inventé.

**Ne pas refermer d'office** : c'est exactement la faute commise sur Cherré, où
un trou de deux ans enregistrait une absorption réelle.

### Les autres absorptions anciennes suivies d'un rétablissement

Le signe est un trou intérieur dans la chronologie d'un atome ; la requête de
détection est en § 4 de `44_absorption_ancienne.sql`. Mesuré le 20 août :
1 690 trous côté canton, 1 684 côté circo, dont 1 689 et 1 683 de 48 ans qui sont
l'Alsace-Moselle. Le seul autre est Cherré, traité.

**Ne jamais refermer un tel trou d'office** : il faut trouver l'acte, nommer
l'absorbante, et ajouter une ligne sourcée à `absorption_ancienne`. Un trou peut
être borné par la même unité alors que l'absorbante relève d'un autre canton —
le résultat serait juste ici et faux ailleurs.

**Piste** : HAC documente les fusions antérieures à 1943 et est déjà une source
du projet. Elle permettrait de peupler `absorption_ancienne` sans passer par des
articles au cas par cas.

**Angle mort connu, qu'aucune recette ne voit** : une commune omise en **fin** de
série ne laisse pas de trou intérieur, sa période s'arrête simplement plus tôt.

### Ventiler les 108 km² entre rural et urbain

Point de finition sans enjeu. `13` § 3 a établi la ventilation avec l'ancienne
clé `code_2011`, sur 3 837 km² ; les 108 km² que la clé géométrique restitue n'y
sont pas répartis — Lyon (47,85) ira du côté urbain, les 60,18 restants sont à
classer. Rejouer `13` § 3 sur `cle_geom` suffirait. L'ordre de grandeur ne
bougera pas.

---

## 9. Voies explorées et fermées — à ne pas rouvrir sans raison neuve

| voie | verdict | date |
|---|---|---|
| **HAC comme source de filiation pour `11`** | essayé, mesuré, **abandonné** : 11 paris perdus sur 425 contre 4 sur 414. HAC ne nomme qu'une mère quand il y en a plusieurs | 20 août |
| **Les transferts de communes lus dans le volume de 1954** | 311 candidats, 227 réfutés par la géométrie, les survivants indiscernables du bruit | 14 août |
| **`ID_GEOFLA.tab`, `insee_former.do`** | l'un est la table attributaire du shapefile, l'autre de l'harmonisation de noms | — |
| **L'appariement par nom contre le COG 2005** | abandonné au profit des mouvements INSEE, traçables ligne à ligne | — |
| **Le pseudo-découpage appliqué à Paris 2009** | mesuré puis écarté : il relierait 17 des 18 circonscriptions parisiennes en une seule composante | — |
| **ADMIN EXPRESS comme trame de découpe** | 26 % des coupes ; CONTOURS-IRIS lui est supérieur d'un ordre de grandeur | 11 août |
| **Cassini-Geopeuple, quartiers de la Ville de Paris, ALPAGE-Vasserot** | licences incompatibles (CC BY-NC-SA, ODbL) quelle que soit la qualité de la donnée | — |

### Le détail du point 0 — deux problèmes sous un seul nombre

Les 318 atomes sans géométrie à 1870 ne sont pas une population homogène. La
requête suivante ne demande pas la partition et répond en quelques secondes :

```sql
SELECT a.fraction, count(*)
FROM  (SELECT DISTINCT m.atom_id FROM histgis.membership m
        WHERE m.periode @> '1870-12-01'::date) v
JOIN   histgis.atom a ON a.atom_id = v.atom_id
WHERE  NOT EXISTS (SELECT 1 FROM histgis.atom_geom ag
                    WHERE ag.atom_id = a.atom_id)
  AND  NOT EXISTS (SELECT 1 FROM histgis.atom_geom_anr g
                    WHERE g.atom_id = a.atom_id
                      AND g.periode @> '1870-12-01'::date)
GROUP  BY 1;
```

**Les fractions** posent une question de chaîne : `05_geom.sql` donne à chaque
atome-fraction le polygone de sa commune-mère, et ceux-là ne l'ont pas reçu.
Pourquoi une partie seulement — 54 fractions ont bien leur polygone et
apparaissent dans les replis de `84` — est la première chose à établir.

**Les non-fractions** posent une question de source : commune disparue avant
2011, donc pas de GEOFLA, et ANR qui ne la pourvoit pas à cette date.
**Goutrens** en est le cas type, et referme le trio du § 8 de `82` dont les deux
autres — Sébazac-Concourès et Roches-Prémarie-Andillé — sont dans les replis.

*Un même symptôme — « rien à dessiner » — recouvre ici un défaut de chaîne et
une limite de source. Les compter ensemble empêche de traiter l'un ou l'autre.*
