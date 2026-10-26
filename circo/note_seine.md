# Note de lecture — la banlieue de la Seine

Deux lectures, écrites toutes deux le 6 septembre 2026 et tenues dans deux
fichiers jusqu'au 26 octobre 2026 : la monarchie censitaire et le Second
Empire (`sql/91`), puis la IVe et le début de la Ve République (`sql/87`,
`sql/88`). Paris lui-même est dans `note_paris.md`.

## 1815-1870

Écrite le 6 septembre 2026 d'après les planches « SEINE » de l'atlas
Gaudillère, **jouée le soir même, puis reprise après relecture des planches** —
`sql/91_seine_1815_1870.sql` pose 9 unités neuves, 4 renommages d'unité, 4 de
version et **519 rattachements**. Avec `89`, `90` et les fichiers parisiens,
**la Seine est continue de 1815 à 2012**.

    ce que la carte rend      atomes   union km²   recouvrement
      1825-06-01                 126     475,83          0,000
      1855-06-01                 128     475,68          0,000
      1866-06-01                 150     479,64          0,000

**1866 rend la Seine entière au centième** — 479,64 pour une Seine officielle
de 479,9. Le déficit du bois de Boulogne y disparaît : à cette date Paris est
sur la trame des 80 quartiers, qui couvre le Paris de 1860 bois compris.

**1855 valait 455,25 avant la relecture, il vaut 475,68 après** : les onze
annexées sont désormais rattachées, et la date rejoint 1825 à 0,15 km² près.
Les 24,39 km² que coûtait le refus de lire une carte à la place d'un texte
n'étaient donc pas un prix à payer — c'était une question à poser. *Le prix
d'un refus se mesure, et parfois la bonne réponse est de ne plus refuser.*

**Un trou hérité, trouvé en lisant la recette 6** : de 1860 à 1863 un anneau
vide sépare Paris de la grande banlieue. Les onze annexées meurent en 1859
selon ANR, mais la division électorale parisienne de 1857-1863 porte sur les
48 quartiers de Vasserot et court jusqu'en 1863. La source date la division de
1857 et l'annexion de 1860, et les deux ne coïncident pas. Le combler
demanderait de faire basculer Paris sur la trame des 80 au 1er janvier 1860 —
un changement dans `55`, pas ici.

### Ce que les planches disent, division par division

L'atlas ne se contente pas de signaler que des circonscriptions débordent de
Paris — **il cartographie la banlieue**, commune par commune, et numérote ses
circonscriptions. La colonne `remarque` du tableur (`rattaché hors-paris`)
n'était que la trace textuelle d'une chose entièrement dessinée à côté.

| division | la banlieue | numérotation |
|---|---|---|
| **1815** | deux collèges d'arrondissement, **Saint-Denis** (nord) et **Sceaux** (sud) | non numérotés sur la planche |
| **1820-1831** | **une seule circonscription** pour tout | « la **8ᵉ** circonscription de la Seine » (texte de la planche) |
| **1831-1848** | même découpage qu'en 1815 | **13ᵉ = Sceaux, 14ᵉ = Saint-Denis** (texte de la planche) |
| **1852-1857** | deux circonscriptions propres, hors Paris | **8** au nord, **9** au sud |
| **1857-1863** | idem | **9** au nord, **10** au sud |
| **1863-1869** | rattachée à deux circonscriptions **parisiennes** | **8** (Paris est + banlieue nord), **9** (Paris sud-est + banlieue sud) |
| **1869-1870** | idem | **8** et **9** |

**La bascule de 1863 s'explique par l'annexion.** Avant 1860, la « petite
banlieue » — les onze communes que Paris absorbe — est rattachée aux
circonscriptions parisiennes limitrophes, et c'est cela que marque
`rattaché hors-paris` : circos 1 et 2 en 1852-1857, circos 1, 2 et 5 en
1857-1863. La « grande banlieue », elle, forme ses deux circonscriptions
propres. Après 1860 il n'y a plus de petite banlieue, et la grande est
rattachée aux circos 8 et 9 de Paris.

### La ligne nord/sud, et elle se vérifie

La planche de 1815 porte la seule définition écrite de la frontière :

> « les deux arrondissements de Sceaux et de Saint-Denis étaient séparés, sur
> le territoire actuel de Paris, par la Seine à l'Ouest et la rue de Lagny à
> l'Est. »

Cette frontière est celle des arrondissements du département, et **le jalon
cantonal de 1954 la porte encore**. La nomenclature de la page 758 donne
l'arrondissement de chaque canton — 13 à Saint-Denis, 9 à Sceaux — et une fois
déployée sur les communes :

    Saint-Denis   37 communes   174,22 km²   centroïde y = 6 868 114
    Sceaux        43 communes   199,99 km²   centroïde y = 6 855 237

Sceaux forme **un seul bloc connexe**. Saint-Denis en forme **deux**, et le
second est **Boulogne-Billancourt seule**, 6,16 km², coupée de son
arrondissement par Paris. Ce n'est pas un défaut : Boulogne est sur la rive
DROITE, dans la boucle, et la planche de 1815 dit que la séparation suit la
Seine à l'ouest. *Deux sources séparées de cent trente-neuf ans décrivent la
même ligne, et l'anomalie de l'une confirme la règle de l'autre.*

### La petite banlieue, et Boulogne

Les planches relues nomment les onze annexées, et elles nomment aussi une
douzième commune que rien n'annonçait. `circo/seine_annexees_circo.csv`,
24 lignes, **prime sur la règle nord/sud** — le texte l'emporte sur la
déduction, et quatre garde-fous le vérifient.

| | 1852-1857 | 1857-1863 |
|---|---|---|
| circo 1 de Paris | Passy, Auteuil, **Boulogne** | idem |
| circo 2 de Paris | La Chapelle, Batignolles-Monceau, Montmartre | idem |
| circo 5 de Paris | — | une partie de Belleville |
| banlieue nord | Charonne, La Villette, Belleville | Charonne, La Villette |
| banlieue sud | Bercy, Grenelle, Vaugirard | idem |

    1852-1857   75-01  3   75-02  3   nord 33   sud 41   = 80, partition
    1857-1863   75-01  3   75-02  3   nord 32   sud 41   = 79, Belleville coupée

**BOULOGNE-BILLANCOURT N'EST PAS UNE ANNEXÉE.** C'est une commune de la
banlieue actuelle, que la ligne nord/sud de 1954 place dans l'arrondissement de
Saint-Denis, donc dans la circonscription de banlieue nord. Les planches la
donnent à la 1re circonscription **parisienne**. Le premier jeu l'a rattachée
au mauvais endroit pendant onze ans.

*Et l'indice était dans la mesure du matin.* Boulogne était la seconde
composante connexe de l'arrondissement de Saint-Denis, seule, coupée du reste
par Paris. J'y ai vu une confirmation de la ligne et je me suis arrêté là. Une
commune que Paris sépare de son arrondissement est précisément celle que Paris
capte électoralement. **Une anomalie qui confirme une règle peut en annoncer
une autre, et on cesse de lire dès qu'elle donne raison.**

### Ce qui reste non posé

* **Belleville en 1857-1863**, et elle seule. L'atlas le déclare lui-même :
  > « la commune de Belleville était divisée : deux bureaux de vote (rue
  > H. Chevreau et rue du Combat, c'est-à-dire rue de Meaux actuelle) étaient
  > inclus dans la 5ᵉ circonscription, et le reste de la commune dans la 9ᵉ.
  > **Faute de précisions supplémentaires, la ligne de séparation cartographiée
  > ci-dessus est purement arbitraire.** »

  Belleville est donc **nommée et non attribuée**, comme les quartiers
  parisiens coupés par une rue dans `52` et `55` : son `unit_id` vaut
  `(coupee)` dans le CSV, et un garde-fou refuse qu'on la pose quand même.

* **Les onze annexées, en 1815-1820 et 1831-1848.** Mesuré sur l'export :
  Passy, Auteuil, Montmartre, Belleville, Vaugirard… ne sont dessinées ni à
  1817 ni à 1840. Elles portent le côté `annexee`, qui ne rejoint que la
  division dont le côté vaut `tout` — 1820-1831 — et les deux autres divisions
  partagent la banlieue entre Saint-Denis et Sceaux sans qu'aucun côté leur ait
  été donné. La note disait « leur côté doit venir d'ailleurs » ; il n'est
  jamais venu. *Une réserve écrite n'est pas une réserve levée.*

  Le comblement tient en onze lignes, et il demande une lecture des planches
  1815 et 1831-1848 : de quel côté de la limite tombe chacune ? La règle
  écrite — « la Seine à l'Ouest, la rue de Lagny à l'Est » — mettrait Grenelle
  et Vaugirard à Sceaux et les autres à Saint-Denis, **Bercy restant douteuse**
  puisqu'elle est rive droite mais au sud de la rue de Lagny. À ne pas trancher
  par déduction géographique.

* **L'anneau vide de 1860-1863.** Les annexées meurent en 1859 selon ANR — la
  recette 3 le montre, leurs rattachements s'arrêtent au 1er janvier 1859 et
  non à 1863 — mais la division parisienne de 1857-1863 porte sur les
  48 quartiers de Vasserot. À 1861 la carte rend 48 + 69, et l'anneau est là.
  Le combler demande de basculer Paris sur la trame des 80 au 1er janvier
  1860 : un changement dans `55`.

### La réserve qui porte tout

La répartition Saint-Denis / Sceaux est lue **à 1954** et projetée sur
1815-1870. Ce qui la soutient : la planche de 1815 nomme les deux mêmes
arrondissements, la ligne décrite (la Seine à l'ouest) explique l'anomalie de
Boulogne mesurée à 1954, et les arrondissements sont des cadres stables. Ce qui
ne la soutient pas : rien n'interdit qu'une commune ait changé
d'arrondissement entre 1815 et 1954 — **et Boulogne a montré que la ligne
administrative n'est pas la ligne électorale**, ce que seule la lecture des
planches pouvait dire.

C'est la même forme d'hypothèse que celle de `88`, et elle se déclare de la
même façon : `provisoire = true`, et la réserve écrite avant le code.

## 1945-1967

Écrite le 6 septembre 2026, **jouée le soir même**. `87` a posé 4
rattachements cantonaux, `88` 27 unités et 160 rattachements. La Seine est
entière — Paris et ses 80 communes — de 1870 à 1967 sans une interruption
autre que l'Occupation.

    recette 6 de `88`       banlieue  paris  circos
      1875                        80     20       1
      1935                        80     76      55
      1950                        80     80       6     3 Paris + 3 Seine
      1960                        80     72      52    28 Paris + 24 Seine
      1967                        80     72      52
      1970                         0     72      28     la Seine n'existe plus

### Le trou, et ce qui le causait

Le département de la Seine est entier sur la carte de 1870 à 1940 : cent
atomes, vingt arrondissements de Paris et quatre-vingts communes de banlieue.
À partir de 1945 il se réduit à Paris.

Ce n'est pas la géométrie qui manque. Les quatre-vingts communes sont en base,
dessinées, vivantes — elles n'ont simplement plus **aucun rattachement circo**.
La seule source qui porte le 75 hors 1870-1940 est `paris_decoupage.xlsx`, et
elle est intra-muros par quartier. Mesuré sur l'export du 5 septembre :

| période | unités | rattachements | dont banlieue |
|---|---|---|---|
| 1870-1875 | 1 (« Seine ») | 100 | 80 |
| 1936-1944 | 56 | 156 | 80 |
| 1945-1957 | 3 | 80 | **0** |
| 1958-1985 | 28 | 72 | **0** |

### Les deux textes

**1945-1958** — loi n° 46-2151 du 5 octobre 1946, JORF du 8 octobre 1946.
Six circonscriptions pour la Seine, trois pour Paris et trois pour la banlieue,
découpage déjà en vigueur aux constituantes du 21 octobre 1945 et du 2 juin
1946. Scrutin de liste à la proportionnelle. Les trois de banlieue :

| circo | nom d'usage | cantons |
|---|---|---|
| 4e | Seine-Sud | Nogent-sur-Marne, Saint-Maur-des-Fossés, Charenton-le-Pont, Ivry-sur-Seine, Villejuif, Sceaux, Vanves |
| 5e | Seine-Nord-Ouest | Boulogne-Billancourt, Puteaux, Colombes, Courbevoie, Neuilly-sur-Seine, Levallois-Perret, Asnières, Clichy, Saint-Ouen |
| 6e | Seine-Nord-Est | Saint-Denis, Aubervilliers, Pantin, Noisy-le-Sec, Montreuil-sous-Bois, Vincennes |

**1958-1968** — ordonnance n° 58-945 du 13 octobre 1958, tableau n° 1.
Cinquante-cinq circonscriptions pour la Seine : 1re à 31e pour Paris, **32e à
55e pour la banlieue**, uninominal à deux tours. Dix-sept sont énoncées en
communes, sept en cantons.

Transcription complète : `circo/seine_circo.csv`, 86 lignes.

> **Réserve de source.** Les deux tableaux ont été transcrits depuis la
> synthèse de Wikipédia (CC BY-SA), qui cite le JO en référence. Légifrance ne
> reproduit pas les tableaux annexes de ces textes. **La confrontation au JO
> lui-même reste à faire** — c'est la seule pièce manquante de ce chantier, et
> les contrôles ci-dessous ne la remplacent pas : ils rendent une erreur de
> transcription improbable, pas impossible.

### Le contrôle qui décide, et il est indépendant

Les deux découpages se définissent **par canton** — exactement ce qui bloquait
nationalement le découpage de 1958. Le trou n'en est plus un depuis `66`-`69` :
le jalon du recensement de 1954 donne les cantons de la Seine et leur
composition communale.

Or la page 758 du fascicule de 1954 porte, en tête, la **nomenclature des
42 cantons du département** — 20 pour Paris, 22 pour la banlieue. Et :

    cantons cités par la loi de 1946 ....... 22
    cantons de la banlieue en base à 1954 .. 22
    1946 == base 1954 ...................... OUI, nom pour nom
    cantons cités par l'ordonnance de 1958 .. 7, tous dans les 22

**Deux sources jamais mises en contact** — un texte électoral d'un côté, un
dénombrement de l'autre, douze ans d'écart — nomment la même liste de
vingt-deux cantons, sans un de plus ni un de moins.

Et la recette de couverture passe sur les deux divisions :

    1945-1958    3 circos   80/80 communes   absentes 0   doubles 0
    1958-1968   24 circos   80/80 communes   absentes 0   doubles 0

Le banc est `circo/banc_seine.py`. Il ne lit que `communes.json` et la planche
cantonale de 1954 de l'export web — **jamais les planches `x_*`**, pour que son
entrée ne devienne pas la sortie de ce qu'il éprouve, comme il est arrivé à
`banc_84.py` le 5 septembre.

### Ce que le banc a trouvé en chemin : quatre communes tombées de 1954

La première mesure rendait **76 communes sur 80** pour 1945-1958. Les quatre
absentes : Choisy-le-Roi, Noisy-le-Sec, Sceaux, Villejuif.

Ce n'est pas un trou de la source. Les quatre sont sur le fascicule, avec leur
code d'arrondissement et de canton. C'est l'extraction qui les a laissées
tomber, sur des noms qu'elle n'a pas su apparier :

    Choisy-ic-Roi     3 08    canton d'Ivry-sur-Seine
    Nolsy-ie-Sec      2 13    canton de Noisy-le-Sec
    SCEAUX            3 39    canton de Sceaux
    Vitejuit          3 41    canton de Villejuif

**Trois des quatre sont les chefs-lieux des cantons qui portent leur nom**, et
la page les code deux fois — dans la nomenclature de tête et dans le tableau de
population. Choisy-le-Roi n'est codée qu'une fois, par le tableau ; la
nomenclature confirme seulement que `08` est le canton d'Ivry.

`SCEAUX` est la seule ligne du département imprimée en capitales, ce qui
explique probablement l'échec de l'appariement.

Le correctif est `cog1954/correctif_seine_1954.csv` — quatre lignes, chacune
avec sa ligne OCR brute — et `sql/87_seine_canton_1954.sql` le pose. Son prix
se mesure au lieu de se supposer : le banc tourne deux fois, sans puis avec,
et passe de 76/80 à 80/80.

### Un code INSEE n'est pas un atome — corrigé au premier jeu

`87` est passé, `88` s'est arrêté sur son garde-fou. Les deux fichiers
joignaient sur le seul `insee_geofla`, et **Villejuif possède trois atomes** :
`40231` et deux fractions `40231#9427` et `40231#9448`, héritées d'un partage
cantonal de 1870-1940. Cinquante-sept jetons « commune » atteignaient cent cinq
atomes ; les deux divisions ne couvraient pas le même territoire.

Rien ne pouvait le montrer : la recette de couverture déduisait elle aussi son
lot de `insee_geofla` et annonçait 82/82 sur les deux lignes. *Une recette qui
construit son attendu par le même chemin que son mesuré ne mesure rien.*

La convention n'était pas à inventer. `68` pose **un atome par commune**, et ne
fabrique une fraction `atome#canton` que si la commune est multicantonale à
1954 — aucune ne l'est dans la Seine. Et l'export du 75 ne contient aucun atome
à `#`, pas même en 1870.

D'où `se_lot`, référentiel unique de `88` : les atomes que la Seine rattache à
l'un de ses cantons au 1er juin 1954. Il sert aux jetons « canton », aux jetons
« commune » et à la recette. Trois garde-fous neufs le protègent — l'INSEE qui
résout vers plusieurs atomes dans `87`, la planche qui tient plus d'atomes que
de communes dans `88`, et la colonne `hors_lot` qui aurait valu 48.

### L'hypothèse qui porte tout, et elle se dit

La composition communale des cantons n'est connue qu'**à 1954**. Les deux
fichiers la projettent sur 1945-1958 et sur 1958-1968. *C'est une hypothèse de
stabilité cantonale, pas une lecture.*

Ce qui la soutient : la nomenclature des 22 cantons est identique en 1946, en
1954 et (pour les 7 cités) en 1958. Ce qui ne la soutient pas : rien ne dit
qu'une commune n'a pas changé de canton dans l'intervalle, et l'annexe VII de
Gaudillère compte trente créations cantonales entre 1954 et 1968 pour la France
entière.

La part exposée se chiffre : sur les 80 communes, **57 sont posées par leur nom
propre en 1958 et 23 par un canton**. La division de 1945-1958, elle, en dépend
entièrement.

Les unités portent `provisoire = true` pour cette raison, et il n'y a pas de
raison de le retirer tant qu'un second jalon cantonal ne l'aura pas confirmée.

### Les bornes, et pourquoi la seconde n'est pas celle de Paris

    [1945-01-01, 1958-01-01)   comme les circonscriptions parisiennes de `55`
    [1958-01-01, 1968-01-01)   la Seine meurt le 1er janvier 1968

Les unités parisiennes de `55` courent jusqu'au 24 novembre 1986. Celles-ci
s'arrêtent à la dissolution du département par la loi du 10 juillet 1964,
effective au 1er janvier 1968. **Les législatives de mars 1967 se sont tenues
dans ces circonscriptions-là** — c'est pourquoi la borne est 1968 et non 1967.

C'est aussi pourquoi les identifiants ne partagent pas la série de Paris :
`V1945_1958#4` à `#6` continuent celle de `55`, mais 1958 ouvre une série
propre, `S1958_1968#32` à `#55`. *Deux unités qui ne vivent pas le même temps
ne partagent pas une série.*

### Ce qui reste ouvert

* **1941-1945** — l'Occupation. Rien de transcrit, ni pour Paris ni pour la
  banlieue.
* **1968-1985** — la banlieue passe aux 92, 93 et 94, qui n'ont aucune couche
  circo. Ces fichiers ne la suivent pas.
* **Les 3,81 km² de déficit à 1848**, localisés : 1,86 km² à l'ouest, le
  **bois de Boulogne**, qu'ANR donne à Paris dès 1790 et que Vasserot ne
  couvre pas — les deux sources ne nomment pas le même Paris ; et 3,96 km² à
  l'est, un **trou d'ANR** — le territoire dont Le Perreux naîtra en 1887
  n'appartient à personne avant que Nogent ne le gagne en 1860.
* **1815-1869** — ouvert le 6 septembre 2026. Ce n'est pas un trou de
  géométrie : `atom_geom_anr` porte les fenêtres 1790-2020 depuis `82`, et
  rien ne les atteignait faute de rattachement. `89` crée les onze communes
  annexées à Paris en 1860, `90` pose 1848-1852. Restent 1815-1848 (collèges
  d'arrondissement) et 1852-1869 (Second Empire).
* **Le nom des trois circonscriptions parisiennes de 1945-1958.** `55` les
  nomme « Paris 1e à 3e » ; la loi de 1946 les nomme « Seine ». Les six ne
  forment qu'une série et devraient porter le même nom. Non corrigé ici — ce
  serait modifier de la donnée existante, et cela demande son propre passage.

### Sources

* Loi n° 46-2151 du 5 octobre 1946 relative à l'élection des membres de
  l'Assemblée nationale, JORF n° 235 du 8 octobre 1946 —
  <https://www.legifrance.gouv.fr/jorf/id/JORFTEXT000000693370>
* Ordonnance n° 58-945 du 13 octobre 1958 relative à l'élection des députés à
  l'Assemblée nationale —
  <https://www.legifrance.gouv.fr/jorf/id/JORFTEXT000000517357>
* *Liste des circonscriptions législatives de la Seine*, Wikipédia (CC BY-SA) —
  <https://fr.wikipedia.org/wiki/Liste_des_circonscriptions_législatives_de_la_Seine>
* *Quatrième / Cinquième / Sixième circonscription de la Seine (Quatrième
  République)*, Wikipédia (CC BY-SA)
* Recensement de 1954, *Population de la France. Départements, arrondissements,
  cantons et communes*, INSEE — domaine public,
  <https://www.bnsp.insee.fr/ark:/12148/bc6p06z8sm1>, page 758 pour la Seine
