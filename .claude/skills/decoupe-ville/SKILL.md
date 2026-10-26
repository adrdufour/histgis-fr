---
name: decoupe-ville
description: >
  Découper une ville multicantonale de histgis (projet_carte) à partir d'un texte de délimitation —
  une suite de rues, places, cours d'eau, voies ferrées, le plus souvent tirée de Gaudillère
  (Atlas des circonscriptions électorales) ou d'un décret. Trace la ligne dans la voirie BD TOPO
  depuis QGIS, l'éprouve, pose les ancres de fraction, l'écrit dans cartes/coupes_ville.csv et joue
  sql/98_coupe_ville.sql. À utiliser dès que l'utilisateur donne le nom d'une ville suivi d'une
  énumération de voies ou d'une rivière séparatrice (« Moulins : route de Decize, rues de
  Decize, des Potiers… », « Montluçon séparation le Cher »), colle un extrait de Gaudillère ou de
  décret décrivant une limite entre cantons d'une même commune, parle de couper, découper, trancher
  une ville entre ses cantons ou circonscriptions, ou mentionne coupes_ville, trace_texte,
  pose_coupe ou une des 315 villes à découper — même sans dire « skill » ni « découpe ».
---

# Découper une ville multicantonale sur son texte

Le projet `histgis` (`~/Téléchargements/projet_carte`) a 315 villes dont le territoire est
partagé entre plusieurs cantons, pour 750 coupes internes (une de moins que de fractions, par
ville). Leurs fractions partagent en base le polygone de la commune entière : la limite qui les
sépare n'existe nulle part. Ce skill la trace, ville par ville, depuis le texte que l'utilisateur
fournit.

**315, pas 119.** L'ancien compte « 119 villes, 214 coupes » ne gardait que les villes dont les
fractions ont une géométrie GEOFLA ; il écartait les 196 villes dont les fractions viennent du COG
(`atom_geom.source = 'fraction_cog'` — Bourg, Laon, Vichy, Soissons…), qui se découpent pareil.
Corrigé le 26 septembre 2026. Deux conséquences : la trame IRIS (`iris_ville`) ne couvre que les
119 — une ville COG a 0 IRIS, on trace sur la seule BD TOPO ; et le tableau de suivi
`cartes/sorties/villes_decoupage_cantonal.xlsx` (état par ville : faite, partielle, à faire)
compte les 315. Il se régénère par `python3 cartes/tableau_villes.py` (deux minutes : il joue la
recette de `98` à blanc) ; la colonne « Remarques » est recopiée de l'ancien fichier, et une ville
nouvellement tracée prend la remarque du dictionnaire `REMARQUES` du script, à compléter à
chaque ville.

## La règle du jeu — décidée par Adrien le 24 septembre 2026

**Au plus près du texte, même imparfait.** La précision des textes (numéros de voirie, « la place
au-devant de la maison Doyon ») dépasse toujours les données ; attendre la perfection bloquerait
les 750 coupes. On trace ce qu'on peut, et on écrit dans la note de la coupe, point par point, ce
qui est approché et pourquoi. Une approximation dite est un résultat ; une approximation tue est
une erreur qui attend son lecteur.

**Le texte fait foi** (`METHODE.md`). Quand le texte et une autre source divergent — une note
entre crochets, une limite IRIS, un arbitrage antérieur —, on suit le texte et on chiffre la
divergence. Si l'utilisateur arbitre contre le texte, on applique, mais on dit au même tour ce que
ça coûte (quelles communes, quelles surfaces, quel contrôle le signalera).

**Voirie : BD TOPO de l'IGN, jamais OpenStreetMap.** OSM est sous ODbL ; le `LISEZMOI.md` l'exclut
parce que le projet alimente Wikipédia. La BD TOPO est sous Licence Ouverte et vient du même WFS
que les IRIS.

## Les outils — tous dans le dépôt

| outil | où il tourne | rôle |
|---|---|---|
| `cartes/recupere_voirie.py <insee>` | shell | BD TOPO : voies nommées, tronçons, eau, voie ferrée → `cartes/sorties/voirie/` |
| `cartes/trace_texte.py` : `trace()`, `trace_eau()`, `trace_mixte()` | **hors du QGIS ouvert** (ci-dessous) | construit la ligne dans le réseau |
| `cartes/qgis_sans_ihm.py <script.py>` | shell | exécute un script de tracé dans un QGIS à lui, sans interface |
| `cartes/rendu_sans_ihm.py` : `rendu()` | via `qgis_sans_ihm.py` | une image PNG de la carte, sans le QGIS ouvert |
| `cartes/pose_coupe.py` | shell | découpe d'essai (une ou plusieurs lignes), ancres, écriture, recette |
| `cartes/desboucle.py in.wkt out.wkt` | shell | retire les recoupements d'une ligne (`ST_IsSimple` faux) |
| `cartes/pont_qgis.py` | shell | `villes` (les 315), `ping`, captures d'écran |
| `sql/98_coupe_ville.sql` | psql | charge les CSV, dérive les polygones au tirage |

**Les calculs de tracé tournent hors du QGIS de l'utilisateur**, par `qgis_sans_ihm.py`, qui
fournit `trace*()` déjà chargés. Le 25 septembre 2026, une intersection de deux réseaux entiers
lancée par `execute_code` a fait tomber GEOS et avec lui le QGIS ouvert d'Adrien. Son QGIS sert à
MONTRER ; s'il est fermé, `rendu_sans_ihm.py` produit l'image. Le connecteur MCP `qgis`
(`mcp__qgis__*`) ou `cartes/pont_qgis.py` y donnent accès. Interpréteur système :
`/usr/bin/python3` — le python de miniforge n'a pas PyQGIS. Le core dump à la fermeture d'un
script autonome est bénin : les fichiers sont écrits avant.

## Déroulé

### 1. Situer la ville dans la base

Trouver l'INSEE (`python3 cartes/pont_qgis.py villes`), puis lister ses fractions, leurs cantons et
leurs périodes — requête dans `references/requetes.md` § 1.

Ce que cette liste décide :
- **combien de lignes** : il en faut une de moins que de fractions *à la même date* ;
- **quel régime le texte décrit.** Montluçon a deux cantons de 1870 à 1985 (Est, Ouest) et cinq
  ensuite ; « séparation le Cher » ne décrit que le premier. Une ligne ne vaut que pour le régime
  dont elle a le nombre de morceaux ;
- **les directions** que portent les noms (Nord, Sud, Est, Ouest), qui serviront aux ancres.

**Dater la ligne.** Gaudillère décrit les limites anciennes avec les noms de rues de son époque
(1995) : un nom récent date la *rédaction*, pas la limite. À Moulins, l'avenue Edmond-Michelet
(nom postérieur à 1970) décrit une limite inchangée de 1815 à 1985 — Adrien l'a confirmé. Par
défaut, pose la ligne sur toute la période où les mêmes fractions coexistent, et demande si le
texte ne dit rien de la date.

### 2. Récupérer la voirie

```bash
/usr/bin/python3 cartes/recupere_voirie.py <insee>
```

Marseille, Lyon et Paris sont codées par arrondissement dans la BAN comme dans les IRIS ; le script
s'en charge. Un zéro pour ces trois villes n'est jamais la bonne réponse.

### 3. Retrouver chaque élément du texte

Chercher chaque nom dans `<insee>_voies.geojson` (`nom_voie_ban`), accents neutralisés. `trace()` se
rabat sur les tronçons pour les voies que `voie_nommee` ignore (« Route de Decize »).

- **Les notes entre crochets du texte** (« rue des Épiés [aujourd'hui rue Schneider] ») donnent la
  concordance moderne : les utiliser.
- **Un nom ambigu se tranche par la géométrie** : prendre le candidat qui touche ses voisins du
  texte. « Michelet » à Moulins : l'avenue Edmond-Michelet est à 38 m de l'avenue de la Libération,
  la rue Michelet à 1 079 m.
- **Un élément à plusieurs centaines de mètres de la chaîne est mal identifié**, même si une note
  le propose. La place Saint-Pierre de Vienne, 552 m hors chaîne, a été écartée contre la note du
  texte.
- **Un nom introuvable** (renommé, disparu : place Modène, rue du Pont-Guinguet) est sauté : la
  ligne passe par le plus court chemin entre ses voisins. Le dire dans la note, avec la longueur
  du trou qu'il comblait sans doute.

### 4. Tracer

Dans QGIS (`execute_code` ; chaque appel a un espace de noms neuf, donc ré-exécuter le module) :

```python
exec(open("/home/adrien/Téléchargements/projet_carte/cartes/trace_texte.py").read())
ligne, rapport = trace("<insee>", ["Route de Decize", "Rue de Decize", ...])   # voies, dans l'ordre du texte
# ou, pour « séparation <rivière> » :
ligne, rapport = trace_eau("<insee>", "le Cher", "1900-01-01")
print("\n".join(rapport))
open("/tmp/.../<insee>.wkt", "w").write(ligne.asWkt(2))
```

Lire le rapport avant toute chose : écarts entre éléments consécutifs, noms sautés, boucles
retirées, `simple = True`. Une ligne non simple ne se découpe pas proprement.

`trace_eau` prend l'axe *fictif* du cours d'eau (au milieu de la surface en eau), le plus court
chemin à travers les bras, et ne garde que la **traversée** de la commune : là où la rivière est
la limite communale, elle sépare la ville de sa voisine, pas deux cantons.

**`trace_mixte` pour un texte qui enchaîne rues, rivière, voie ferrée et limites** (« cours de la
Meuse jusqu'à la limite de Warcq, rue Voltaire, voie ferrée jusqu'au pont du faubourg du Theux ») :

```python
L, r = trace_mixte("08105", [("commune", "08497"),          # « la limite de Warcq »
                             ("eau", "meuse"), ("voie", "Rue Charles Gilbert"),
                             ("voie", "Rue Voltaire"), ("fer",), ("eau", "meuse")])
```

Étapes : `("voie", nom)`, `("route", "D7N")` — une route par son numéro actuel (`cpx_numero`) : les
routes nationales déclassées en 2006 ont changé de numéro, la RN7 d'Aix-en-Provence est la D7N, la
RN96 la D96 et, en ville, la « route de Sisteron » —, `("eau", mot du toponyme)`, `("fer",)`, `("bord",)`, `("commune",
insee)` — la limite d'une voisine NOMMÉE —, `("commune", insee, "1960-01-01")` — une commune
DISPARUE à une date où elle existait (« l'ancienne commune de Montcy-Saint-Pierre »), `("point", x,
y)` — un repère que rien ne localise, ou la jonction avec une autre ligne. En premier ou en dernier,
un élément non-voie est un départ ou une arrivée, pas un parcours ; au milieu, il est longé.

Préférer `("commune", insee)` à `("bord",)` quand le texte nomme la voisine : à Charleville-Mézières,
« le bord » faisait partir la ligne de l'autre bout de la ville, par 6,5 km de Meuse. Et **regarder
chaque ligne** (`rendu_sans_ihm`) avant de passer à la suivante : trois départs faux sur cinq lignes
ne se voyaient que sur l'image.

**Des cantons numérotés (Troyes-1, -2, -3) ne disent pas de direction.** Les attribuer par leurs
communes de banlieue à la date : le secteur de la ville qui touche Lavau et Pont-Sainte-Marie est
la part urbaine du canton de Lavau (requête dans `references/requetes.md` § 7). Et c'est aussi le
contrôle final : chaque morceau doit toucher surtout des communes de son propre canton.

**Où une limite interne touche le bord : au point triple.** Hors de la ville, deux cantons sont
séparés par la limite entre deux communes voisines ; la limite interne doit l'atteindre là où ces
deux voisines se rencontrent sur le bord. Quand le texte s'arrête avant (Troyes, rue Jeanne-d'Arc,
340 m), finir par `("point", x, y)` = ce point triple : `trace_mixte` le rejoint par les rues.
Finir sur une voie sans repère est risqué : le traceur prend alors son bout le plus éloigné de
l'élément précédent, qui peut être le mauvais bout ; à Troyes le chemin est revenu sur ses pas et
la règle anti-boucle a effacé 790 m de limite.

**Des axes en étoile** (« les trois axes » de Troyes) partent d'un même centre : tracer le premier,
puis faire partir les autres de son bout exact (`("point", x, y)`), sinon il reste un triangle.

**Une ville à N cantons, c'est N-1 lignes au moins, qui se rejoignent.** Faire démarrer une ligne là
où une autre s'arrête (`("point", x, y)` = le bout exact de l'autre) ; `98` et `pose_coupe.py`
raccordent chaque bout au plus proche du bord *ou des autres lignes*, puis calent le tout à 1 m.

### 5. Les bouts de la ligne

Mesurer la distance de chaque bout au bord communal (`references/requetes.md` § 2). Trois cas :

- **Le texte va d'un bord à l'autre** (Moulins) : rien à faire.
- **Une voie du texte longe le bord communal** (la route de Decize, 167 m) : elle y est limite de
  commune, pas de canton. `pose_coupe.py --rogner 10` retire ce qui court à moins de 10 m du bord.
  Indispensable quand la bande laissée a une vraie surface ; sous 1 m², c'est de la poussière de
  calcul que la recette ignore.
- **Le texte s'arrête avant le bord** (Vienne : il ne décrit que « la ville », jusqu'aux portes) :
  mesurer d'abord si la ligne du texte suit une limite d'IRIS (§ 3 des requêtes). À Vienne, 72 %
  de la ligne est à moins de 15 m de la limite entre grands quartiers INSEE : cette limite a servi
  à prolonger, et la composition texte + IRIS est au § 4. À Moulins, 14 % seulement : **les IRIS ne
  suivent pas partout les cantons**, et sans accord mesuré il faut demander à l'utilisateur plutôt
  que prolonger en ligne droite. Le raccord automatique de `98` ne vaut que pour quelques dizaines
  de mètres ; au-delà, c'est du dessin, pas un raccord.

### 6. Éprouver, puis écrire

```bash
/usr/bin/python3 cartes/pose_coupe.py <insee> --wkt <fichier.wkt> --de 1870-01-01 --a 2013-01-01 \
    --ancre '<atome>=nord' --ancre '<atome>=sud'            # à blanc
```

Il découpe la commune exactement comme `carte_coupe_ville()` le fera, avec les autres lignes déjà
posées pour la ville, et dit : morceaux, aires, fractions attendues à la date, CONFORME ou non.
**Une ville à plusieurs lignes se passe en une fois** : `--wkt l1.wkt --wkt l2.wkt …` (et une
`--note-fichier` par ligne, dans le même ordre) ; aucune ligne seule ne rend le bon nombre de
morceaux.

**Si deux cantons sortent soudés**, éprouver chaque ligne SEULE (chacune doit couper en deux), puis
tester dans quel morceau tombe un point de chaque canton attendu (`references/requetes.md` § 6) :
la paire soudée désigne la jonction qui fuit.

**Ancres** : `ATOME=direction` (nord, sud-est…) prend le morceau le plus loin dans cette direction
depuis le centre de la commune ; c'est la lecture du nom du canton. Quand le nom ne dit rien
(« 1er canton », « Nord-Centre ») : `ATOME=POINT(x y)`, un point choisi en regardant la carte.

**Écrire systématiquement — règle d'Adrien, 13 octobre 2026.** Dès que la découpe est CONFORME à
blanc et que l'image a été regardée, on écrit, sans demander l'accord : rédiger la note
(§ ci-dessous) dans un fichier, relancer avec `--note-fichier <note.txt> --ecrire`, puis faire
toute la suite d'un trait (contrôle `carte_coupe_ville` à une date de chaque régime,
`a_inscrire_en_base.md`, `REMARQUES` de `tableau_villes.py` et régénération du xlsx, pièges du
jour dans ce skill, sources rangées hors du scratchpad, tables `public.<ville>_*` supprimées).
Les lectures douteuses ne retardent pas l'écriture : elles sont dans la note, chiffrées, et dans
le compte rendu comme questions ; une ligne se réécrit. Si la session refuse une écriture
(permissions), le dire et donner la commande prête, sans la contourner. Le script refuse d'écrire une découpe non conforme, et
imprime la ligne de recette de la ville : **lire la recette, pas le code de retour** — une ligne
qui ne ferme pas rend zéro comme une ligne juste.

### 7. Montrer

Exporter la découpe et la ligne en GeoJSON (`references/requetes.md` § 5 — jamais une sous-requête
d'URI PostGIS dans QGIS 3.22, qui part en core dump), les charger dans QGIS avec les voies du texte
en rouge, puis capturer. **Attendre le rendu** : une capture prise juste après un `set_canvas_extent`
montre l'ancien cadrage. Envoyer la capture à l'utilisateur.

## La note de la coupe

C'est la seule trace de ce qui a été décidé ; elle sera relue dans six mois par quelqu'un qui n'a
pas suivi la conversation. En ASCII, comme les notes existantes. Dans l'ordre :

1. `TEXTE.` (ou `TEXTE dans la ville, IRIS au-dela.`) et la source :
   `Gaudillere, Atlas des circonscriptions electorales (1995)`, page si connue ;
2. le texte cité, avec les concordances entre parenthèses ;
3. `Trace :` la méthode (plus court chemin BD TOPO, axe fictif du cours d'eau…) ;
4. `APPROCHE :` chaque approximation numérotée, chiffrée (mètres, hectares) ;
5. `DATE :` sur quoi repose la période de validité ;
6. l'accord avec les IRIS, en pourcentage — il renseigne les villes suivantes.

## Ce que la base ne sait pas : `cartes/a_inscrire_en_base.md` — règle d'Adrien, 25 septembre 2026

Découper une ville révèle souvent ce qui manque à la base :
- une unité absente (Bourg-en-Bresse-I, II, III ; Bourg-Couronne) ;
- une appartenance qui commence au COG et pas au décret (Oyonnax 1998 contre JO 1982 ; Aix
  1992 contre 1982) ;
- un décret peut-être annulé (Lisieux 1985) ;
- une géométrie de cible fausse avant une fusion (Lisieux avant 1960).

**Le skill n'écrit jamais ces corrections en base.** Il n'écrit que des lignes et des ancres.
Chaque constat va dans `cartes/a_inscrire_en_base.md`, sous la ville, avec :
- la source (décret, JO, page ; fichier local) ;
- ce que la base contient aujourd'hui (fractions, dates, noms) ;
- ce qu'il faudrait inscrire (unités, fractions, périodes, communes rurales) ;
- les lignes et ancres déjà prêtes qui en dépendent (points des ancres à poser).

C'est Adrien qui décide et inscrit, par un SQL numéroté ; l'entrée passe alors dans « Fait ».
Quand il demande explicitement l'inscription (10 octobre 2026, `sql/108`, Aurillac, Falaise,
Saint-Flour) : un fichier numéroté sur le modèle de `104` (à blanc par défaut, `-v appliquer=1`,
table de trace qui garde l'ancienne unité et le contenu de ce qui est retiré, garde-fous sur l'état
fautif, recette lue depuis le modèle), déclaré dans `sql/rejouer_apres_rebuild.sh` (avant `98`) et
dans l'inventaire de `sql/diag_passages.sql` ; puis `98` sous `appliquer`, le tableau, et l'export
des départements touchés. Relire les décrets avant d'écrire : les codes (1502 = Aurillac-I) se
vérifient sur les communes rurales que la base leur donne à une date sûre. Une fraction garde son
code quand ses communes changent d'unité : ce sont les ancres de la ligne qu'on réécrit.
Relire le fichier avant chaque ville : une entrée peut déjà concerner la ville suivante. Le
signaler dans le compte rendu (« ajouté à `a_inscrire_en_base.md` : … »).

## Rendre compte à l'utilisateur

Court, en français : un tableau des fractions avec leurs hectares, la méthode en deux phrases, les
approximations en liste, et **les questions qui restent** (une page, une date, un morceau à
attribuer). Envoyer la capture. Le compte rendu vient APRÈS l'écriture (règle du 13 octobre 2026),
pas pour la demander. Ne pas commiter sans qu'il le demande.

## Pièges déjà rencontrés

- **Les limites internes qu'un texte ne donne pas** (un texte de circonscription ne donne que les
  limites entre circos) : chercher d'abord dans `cantons/communes_coupees_1973_1984.csv` — le JO
  intégral des décrets 1973-1984 pour chaque commune coupée —, et dans `jorf_txt/*_col.txt` quand la
  colonne `texte` est tronquée (2 000 caractères). Une source primaire locale vaut mieux qu'une
  recherche en ligne ; c'est ce qui a donné les cinq limites de Charleville-Mézières.
- **Un canton en plusieurs morceaux** (Lisieux, 1er canton : « partie nord », « partie sud ») :
  une ancre par morceau, même `atom_id` répété (`--ancre '19690#1421=POINT(…)'` deux fois).
  `carte_coupe_ville()` réunit les morceaux d'une fraction. Une partie qui est un ÎLOT au milieu
  de la ville se trace comme une ligne FERMÉE (premier point = dernier) : `98` ne raccorde pas
  une ligne fermée. Le texte d'un îlot revient à son point de départ, souvent en citant deux fois
  la même rue (« rue P.-Banaston … Sainte-Marie, P.-Banaston, F.-Daulne »).
- **Des lignes de dates différentes** (le 1er canton depuis 1960, la limite II/III depuis 1985) :
  écrire en plusieurs passes de `pose_coupe.py`, une par date de départ, chacune éprouvée à une
  date de son régime. Les ancres déjà posées pour les autres fractions entrent dans le contrôle ;
  celles d'une fraction sans canton à la date sont ignorées au tirage (le 3e canton en 1970).
- **Une commune qui a absorbé une voisine** : `insee_mvt` (Lisieux + Saint-Jacques, 31 janvier
  1960 : 278 ha → 1 308 ha dans l'ANR). Un texte dont les rues vont jusqu'à la limite actuelle
  décrit la ville d'après la fusion : la ligne ne peut pas valoir avant.
- **« Je n'ai pas de source »** : Oyonnax et Bourg-en-Bresse l'étaient, et leur décret (82-77,
  JO du 26 janvier 1982) était dans `cantons/communes_coupees_1973_1984.csv` et
  `jorf_txt/JORF_19820126_21_col.txt`. Toujours chercher avant de conclure.
- **Pas de décret dans le dépôt : la page Wikipédia « Liste des cantons de <département> »** —
  règle d'Adrien, 7 octobre 2026, pour toute ville dont on n'a pas encore le texte. Sa section
  d'histoire donne, changement par changement, la référence du texte (arrêté de l'an X, loi,
  décret) avec le lien Gallica ou Légifrance, et parfois la page du plan de Gaudillère. La lire
  AVANT toute autre recherche en ligne et avant toute déduction (IRIS, rivière, bureaux de vote) :
  `curl "https://fr.wikipedia.org/w/index.php?title=Liste_des_cantons_des_Bouches-du-Rhône&action=raw"`.
  Wikipédia indique la source, elle ne la remplace pas : le texte se cite depuis le JO ou le
  Bulletin des lois. Pour Arles elle a donné l'arrêté du 17 frimaire an X (Bulletin des lois,
  an X, p. 209), que ni le dépôt ni la recherche libre n'avaient trouvé. Gallica demande de cocher
  « Je ne suis pas un robot » : ne pas contourner, demander à Adrien d'ouvrir la page.
- **Une voie ferrée à plusieurs voies** : le plus court chemin dans le réseau ferré peut descendre
  jusqu'à la gare et remonter par la voie parallèle — une boucle de 10 m de large que la règle
  anti-boucle (1 m) ne voit pas (Bourg, 2 km). Prendre une seule voie : sous-chaîne
  (`ST_LineSubstring`) de la composante principale qui passe par le point de départ.
- **« Au Nord de la voie ferrée » quand la voie court du sud au nord** (Oyonnax) : le nom ne
  tranche pas. Mesurer les contacts de chaque morceau avec les communes des deux cantons, et
  DEMANDER : Adrien a donné le Nord à la partie est, contre la lecture par le centre de gravité.
- **« Son prolongement »** (impasse des Granges-Bardes jusqu'à la voie ferrée) : prolonger dans
  l'AXE de la voie, pas vers le point le plus proche ; même chose pour une route qui s'arrête
  avant le bord dans la BD TOPO (D1083 à Bourg, 131 m).
- **Un régime que la base ne connaît pas** (Bourg-en-Bresse-I, II, III, 1973-1982 : aucune
  fraction, faute d'unité en nomenclature) : tracer quand même, éprouver avec
  `pose_coupe.py --morceaux N` (sans ancre), écrire la ligne SANS ancre, et mettre dans la note un
  point par canton pour le jour où les fractions existeront. `carte_coupe_ville()` ne tire rien
  pour ces dates : les ancres d'un autre régime ne jouent que si leur fraction a un canton PENDANT
  la période des lignes. Aligner les dates de bascule sur celles de `membership` (Bourg :
  1982-01-26, date du JO), sinon les deux régimes se chevauchent.
- **Un texte qui ne décrit que la ville d'une grande commune** (Laon, 45 km² : la ville haute
  seule) : la limite doit rejoindre le bord aux points triples entre communes des deux cantons,
  à plusieurs kilomètres. DEMANDER avant de tracer. Adrien a choisi pour Laon le plus court chemin
  routier jusqu'aux deux points triples (4,5 et 2 km), dit dans la note comme une déduction.
  Contrôle décisif : les contacts de chaque morceau avec les communes des deux cantons.
- **Des voies citées qui montent et descendent un versant** (rampe, escalier, grimpette) ne
  s'enchaînent pas en une ligne : le plus court chemin n'en garde que les bouts voisins. Le dire
  dans la note, voie par voie, avec les mètres réellement suivis.
- **Où trouver le décret d'une ville divisée après 1973** : `cantons/chronologie_cantonale.csv` donne
  la date (« Cr. Aix-N.E., Aix-S.O. et Aix-Centre », 1982-02-02), puis
  `grep -n -i "<ville>" jorf_txt/JORF_<date du JO>_*_col.txt`. Le texte d'un canton donne ses
  limites avec TOUS ses voisins : un texte de circonscription (Gaudillère) n'en donne qu'une
  partie, et parfois en abrégé (il omet « route de Galice, rue de Valcros » à Aix).
- **Un repère qui n'est pas une voie** (« les limites Nord et Est de l'emplacement du lycée
  Paul-Cézanne ») : la couche BD TOPO `zone_d_activite_ou_d_interet` (même WFS, `get_feature()` de
  `recupere_voirie.py` avec une `bbox`) donne l'emprise des lycées, stades, hôpitaux. Suivre les
  côtés nommés du contour, puis recoller les morceaux de ligne en SQL (`ST_LineSubstring` de
  l'anneau, `ST_MakeLine`). Le plus court chemin par les rues ferait le tour du pâté de maisons.
- **Une voie dont le nom ne survit qu'en partie** : la « petite route des Milles » ne porte plus ce
  nom qu'à 2,5 km au sud-ouest ; sa continuation exacte vers Aix s'appelle avenue du Camp-de-Menthe.
  Chercher la voie qui prolonge le bout nommé, sans détour, avant de relier par le plus court
  chemin — et changer de voie au PREMIER croisement avec l'élément précédent.
- **La base peut ne pas avoir de canton à la date du texte** : pour Aix, `membership` n'a rien
  entre 1973 et 1992. La ligne garde la date du texte ; la recette de `98` juge alors la ville au
  premier jour de la période où la base a des cantons (et `pose_coupe.py --date-test` aussi). Le
  signaler à l'utilisateur : c'est un trou de la base, pas de la ligne.
- **Un nom de 1973 n'est pas celui d'aujourd'hui** : la « rue de Damouzy » du décret est l'actuelle
  rue Émile-Nivelet ; la rue de Damouzy actuelle est à 1,3 km. La géométrie tranche (§ 3).
- **Une rivière qui longe une limite ne la croise pas** : l'axe BD TOPO et le contour ANR s'écartent
  de plusieurs dizaines de mètres. Une ligne peut s'arrêter à 100 m d'un angle du contour où elle
  devrait aboutir : ajouter le sommet exact du contour (Charleville-Mézières, L4).

- **Une commune littorale avec des îlots** (Antibes : 13 îlots du cap, 0,58 ha) : la cible est un
  multipolygone, et chaque îlot sort comme un morceau sans ancre. Depuis le 26 septembre 2026,
  `98` et `pose_coupe.py` rattachent au morceau ancré le plus proche tout morceau sans ancre
  qu'AUCUNE LIGNE NE TOUCHE (une partie entière de la cible). Un morceau sans ancre bordé par une
  ligne reste signalé : c'est une ligne qui ne ferme pas.
- **Deux textes d'un même décret qui décrivent la même limite différemment** (Antibes 1985 : Biot
  cite « Orangers, Rostagne, Sables, boulevard du Cap, Salis », Centre saute « Orangers, Salis ») :
  regarder si le raccourci existe sur le terrain. S'il n'existe pas, c'est une abréviation ; la
  prendre au pied de la lettre créerait une poche n'appartenant à aucun canton. Le dire dans la note.
- **Un cours d'eau renommé** (le « vallon des Terriers » de 1973 est le Vallon des Eucalyptus
  actuel) : le reconnaître à ce que le texte en dit (il coupe la limite de Vallauris, il rejoint le
  chemin de Roubion), pas à son nom.

- **La cible suit l'ANR de l'atome-mère** (depuis le 27 septembre 2026, Lille). Les fractions
  n'ont pas d'ANR à elles. Elles retombaient sur le contour GEOFLA d'aujourd'hui, si bien que la
  cible mêlait deux époques : Lille en 1880 comprenait Lomme et Hellemmes (3 633 ha au lieu de
  2 184), et Lisieux avant 1960 comprenait Saint-Jacques. `cible_ville()` prend désormais l'ANR de
  `cassini`. Les lignes déjà posées ont été rééprouvées : seules Bourg (une ancre déplacée) et
  Saint-Quentin (une ancre ajoutée sur la pointe Est de l'ANR) ont demandé une retouche.
- **Les miettes de raccord** : un morceau sans ancre de moins d'un hectare va au morceau ancré
  voisin, dans `98` comme dans `pose_coupe.py` (bouts de lignes contre un contour ANR qui s'écarte
  de la BD TOPO). Au-delà d'un hectare, c'est un vrai morceau, qu'il faut ancrer ou expliquer.
- **Une date sans ligne active n'est pas découpée** : `carte_coupe_ville()` ne rend rien. Avant,
  elle donnait la commune entière à la plus ancienne des fractions ancrées (Troyes en 2000).
- **Des ancres datées** (27 septembre 2026, Lille) : une fraction qui revient dans un autre
  régime avec d'autres limites (les cinq cantons de Lille de 1870 gardent leur numéro en 1889)
  ne peut pas garder une seule ancre. `coupes_ville_ancres.csv` a deux colonnes de plus,
  `valid_from` et `valid_to` : vides, l'ancre vaut toujours (toutes les villes d'avant) ; remplies,
  elle ne joue que sur `[valid_from, valid_to)`. `pose_coupe.py --ancres-datees` écrit les
  ancres de la passe avec `--de`/`--a`, et ne remplace que celles de la même période.
- **Relire le texte suivant pour relire le précédent** : à Lille, le texte de 1889 (« dénomme
  canton Nord l'ancien canton Centre », une limite du Nord-Est à Fives) a montré que le Centre et
  le Nord-Est de 1858 avaient été intervertis, et que le Nord-Est sortait des murs. Quand un
  régime en divise un autre, vérifier que ses lignes tombent bien dans le canton qu'il dit
  diviser.
- **Un texte qui ne décrit qu'un canton** (Lille 1858 : seule la limite du Sud-Ouest est donnée
  hors de la vieille ville) : DEMANDER comment le reste se partage. Pour Lille, Adrien a d'abord
  choisi « tout le hors-les-murs au Sud-Est », puis, au vu du texte de 1889, le prolongement de C-D
  au plus court par les rues ; enfin, il a rattaché le morceau sud hors les murs au Nord-Est (puis à
  l'Est en 1889). Une réponse donnée sur un texte peut changer au texte suivant : garder la ligne,
  réattribuer par les ancres.
- **Une rue du texte hors de la commune** (Roubaix : la « rue Langevin » est la rue du
  Professeur-Langevin, à Croix, qui prolonge la rue de Lille) : elle ne donne que le point de
  départ sur la limite. Chercher un nom introuvable dans les communes voisines
  (`get_feature('BDTOPO_V3:voie_nommee', bbox=…)`) avant de le déclarer disparu.
- **Une limite qui continue d'une ville à l'autre** (Roubaix → Wattrelos : la Grande-Rue de
  Roubaix se prolonge en rue Carnot, la limite Nord / Est aussi) : faire partir la ligne de la
  seconde ville du bout EXACT de la ligne déjà posée (`("point", x, y)`).
- **Une fraction en base que le texte ne connaît pas** (Wattrelos : Roubaix-Ouest de 1892 à 1941,
  alors que le texte n'a que Nord et Est) : le texte fait foi. Ancrer les seules fractions du
  texte, écrire avec un `--date-test` où la base est juste, et consigner la fraction de trop dans
  `a_inscrire_en_base.md`. La recette dit alors « FRACTION SANS ANCRE (base) », pas « LIGNE QUI
  NE FERME PAS ».
- **Des fractions qui existent, mais pas aux dates du texte** (Beauvais 1958-1986 : fractions en
  1870-1941 et 1998-2013, rien entre) : `--morceaux N` accepte des ancres, une par morceau, datées
  avec `--ancres-datees`. Elles joueront quand les appartenances seront inscrites. La recette dit
  « RÉGIME ABSENT DE LA BASE ». Chercher aussi le décret qui suit (82-63 pour Beauvais) : il
  redonne souvent la même limite, plus précisément.
- **Une ancre datée vaut pour sa période, même dans un trou de la base** (27 septembre 2026,
  Boulogne) : quand aucune fraction n'a de canton à la date, `98` fait jouer les ancres datées
  valables à la date, en plus de celles dont la fraction a un canton pendant la portée des lignes.
  La recette distingue « FRACTION ABSENTE (base) » : une ancre valable, sans appartenance à la date,
  et de l'aire perdue. Une fraction de la base sous un code de canton qui n'est pas le sien
  (Boulogne-Nord 1968-1973 sous « Calais-Nord-Ouest ») va dans `a_inscrire_en_base.md`.
- **Une commune annexée restée dans un autre canton** (Chambéry 1961-1973 : Bissy et
  Chambéry-le-Vieux, du canton de La Motte-Servolex) : tracer l'ancienne limite communale (ANR
  d'avant la fusion, partie intérieure à la commune agrandie) comme ligne de la période, et
  écrire avec `--morceaux N --vides-admis K`. Les K morceaux sans fraction en base restent sans
  ancre et ne sont pas tirés ; la fraction manquante va dans `a_inscrire_en_base.md`.
- **Une boucle fermée pour une enclave** (Perpignan : la partie urbaine de l'Ouest, entourée par
  l'Est) : fermer la ligne (premier point = dernier) ; nettoyer les recoupements par
  `ST_ExteriorRing` du plus grand polygone de `ST_MakeValid(ST_MakePolygon(ligne))`, pas par
  `desboucle.py`, qui casse l'anneau.
- **Des cantons numérotés sans voisins pour les situer** (Le Havre 1888, Rouen : six cantons tout
  urbains) : demander le PLAN. La page de Gaudillère porte souvent un plan avec les numéros ;
  Adrien l'a photographiée pour Le Havre. Elle a aussi tranché un nom douteux (« rue du 129e » :
  le texte imprimé porte bien 329e).
- **Une commune voisine encore à part, mais déjà dans `insee_geofla` de la ville** (Graville,
  annexée au Havre en 1919) : depuis le 2 octobre 2026, `cible_ville` l'écarte tant qu'elle a son
  propre canton. Il écarte aussi un atome absorbé dont toutes les ANR sont closes. Avant, Graville
  après 1919, comme Gap (atome 8884) après 1895, retombaient sur le contour GEOFLA moderne. Tracer
  quand même l'ancienne limite comme ligne : après l'annexion, elle sépare les terres annexées.
- **`--ancres-datees` remplace toutes les ancres de la même fraction dont la période chevauche**
  celle de la passe. Ajouter une ancre de plus à une fraction déjà ancrée (Bléville 1953 et Sanvic
  1955 au 6e, déjà ancré 1888-1964) efface les autres : les remettre à la main dans le CSV, puis
  contrôler `carte_coupe_ville` à une date de chaque période.
- **Une passe dans un trou de la base** (aucune fraction n'a de canton à la date d'essai) :
  `pose_coupe.py` ne voit que les ancres de la passe. Les morceaux déjà ancrés par les passes
  précédentes s'admettent avec `--vides-admis`, puis le tirage réel se vérifie avec
  `carte_coupe_ville` : les ancres datées y jouent.
- **Le scratchpad peut être vidé d'un jour à l'autre** : garder les lignes en cours dans des tables
  `public.<ville>_*`, pas seulement dans des fichiers.
- **Après une retouche à la main d'un CSV** (ancres redatées, ligne retirée), rejouer
  `psql -d histgis -1 -v appliquer=1 -f sql/98_coupe_ville.sql` : sans `appliquer`, `98` tourne à
  blanc et la recette juge l'ancien contenu de la base (Nancy, 3 octobre 2026).
- **Des fractions sous un autre code la première année** (Nancy 1870-1871 : `24537#9916` à `#9918`,
  département de la Meurthe, puis `#5419` à `#5421`) : une ancre datée par code, sinon la recette
  dit « FRACTION ABSENTE » au premier jour.
- **Des numéros de cantons inconnus** (Nantes, six puis sept cantons) : écrire les lignes avec
  `--morceaux N` sans ancre, donner les points dans les notes, et demander le plan. Les ancres
  s'ajoutent ensuite à la main dans `coupes_ville_ancres.csv`, puis `98` sous `appliquer`. Les
  communes rurales ne donnent que les cantons qui en ont (Nantes-4 par Saint-Sébastien), et une
  déduction sur le reste peut être fausse : le morceau pris pour Nantes-6 était le 5e.
- **Comparer la carte au plan, forme par forme** : à Nantes le plan a montré que la pointe ouest
  (rives et îles de l'ancien Chantenay) était au 7e canton, alors que la ligne de la Loire,
  suivie jusqu'au bord, la donnait au 4e.
- **Plusieurs villes en parallèle** (3 octobre 2026) : un agent par ville, qui trace et éprouve À
  BLANC sans toucher au dépôt (ni `--ecrire`, ni CSV, ni `98`), et rend la commande conforme, les
  `.wkt`, les notes et une image. L'écriture se fait ensuite ville après ville, par une seule main
(la session principale, dès le retour de chaque agent, sans attendre d'accord) :
  deux `--ecrire` ou deux `98` en même temps se marchent dessus. Si `98` rend une erreur de
  syntaxe inattendue, regarder sa date de modification : il peut être en cours d'édition dans une
  autre session ; attendre et rejouer.
- **Paris : un quartier coupé entre deux circonscriptions** (3 octobre 2026). La clé de la coupe
  est l'atome du quartier (`PQ62`, dans la colonne `insee` de `coupes_ville.csv`), le niveau est
  `circo`, et les fractions (`PQ62#58N`, une par côté de la ligne, pas par régime) se déclarent
  d'abord dans `circo/paris_fractions_quartier.csv`, posées par `sql/101` AVANT `98`.
  `pose_coupe.py` et `trace_mixte()` ne connaissent pas cette clé : extraire la voirie du quartier
  (`ogr2ogr -clipsrc`, tampon de 40 m) sous un faux code, tracer par `trace()`, éprouver en SQL sur
  `paris_quartier`, puis écrire lignes et ancres à la main dans les deux CSV et jouer `101` puis
  `98` sous `appliquer`. Le texte est la légende du plan de Gaudillère ; **demander le plan** : il a
  inversé une attribution déduite des contacts (Picpus) et donné une ligne que la transcription
  n'avait pas (Plaine-Monceau).
- **La première et la dernière voie ne sont pas « entières » par défaut dans une grande ville** :
  `trace()` les prend depuis leur bout le plus éloigné, ce qui fait une épingle quand la voie
  traverse tout le quartier (avenue Gambetta, rue de Saussure, avenue Daumesnil). Regarder l'image,
  et fixer le bout par sa direction.
- **zsh ne découpe pas une variable en mots** : `P="python3 x.py"; $P args` échoue en silence
  derrière un `grep`. Écrire la commande en entier.
- **Un GeoJSON exporté par `ogr2ogr -sql` sans `-a_srs EPSG:2154`** n'a pas de projection :
  QGIS le lit en WGS84, et la couche ne s'affiche pas sur le rendu.
- **zsh lit `echo ======` comme une commande** (`=mot` est une expansion) : un séparateur nu entre
  deux `pose_coupe.py --ecrire` a arrêté la suite après la première passe (Caen, 9 octobre 2026).
  Mettre les séparateurs entre guillemets, et relire ce qui a réellement été écrit.
- **Le tramway est dans `<insee>_fer.geojson`** (Caen : 75 tronçons) : `("fer",)` le prend pour
  une voie ferrée. Tracer sur une copie filtrée de la couche, et le dire dans la note.
- **Une route dénivelée ne croise pas** (Caen, N814 sous l'avenue de Courseulles) : `("route", …)`
  part alors par les bretelles de l'échangeur. Couper la ligne au croisement géométrique des deux
  axes.
- **La commune d'avant une annexion peut ne pas contenir l'ancre** (Troyes : 1 034 ha avant 1856,
  1 329 ensuite, et l'ancre de Troyes-2 tombait dans les 295 ha annexés). Avant d'avancer une
  ligne dans le temps, éprouver à chaque état de l'ANR et choisir un point intérieur à tous.
- **Des fractions qui changent de secteur d'un régime à l'autre** (Troyes : `#1023` est l'ouest
  avant 1973 et le nord-est après ; Caen : `#1408` est l'Est en 1967 et Caen-I, à l'ouest, en
  1973) : toujours `--ancres-datees`, et remplacer les ancres non datées de la ville par la
  première passe.
- **Un décret qui récite d'anciennes limites** (Troyes 1973 : les trois axes) : les reprendre sous
  de nouveaux identifiants pour la nouvelle période, avec une note qui cite le décret, plutôt que
  d'allonger les anciennes. Même règle à Nice, où les lignes communes à 1973, 1982 et 1985 sont
  répétées par régime (`06088-1985-spine`) : chaque passe est conforme seule.
- **Deux quais d'un même canal bornent deux cantons** (Troyes : quai La Fontaine pour le I, quai du
  Comte-Henri pour le V, 54 m d'eau entre les deux) : à la lettre le bassin n'est à aucun des deux.
  Une seule ligne, et le dire dans la note.
- **Le Bulletin des lois peut n'imprimer que l'intitulé** (Caen, ordonnance n° 492 du 30 décembre
  1815 : Est / Ouest remplacent Nord / Sud de l'an X, sans un mot de la limite). La référence
  trouvée par Wikipédia ne garantit pas un texte de limite : il faut alors Gaudillère.
- **Wikipédia transcrit parfois le texte** (Nice, loi du 7 février 1919) : on peut tracer et
  éprouver dessus, mais on n'écrit pas avant d'avoir lu le JO. Garder lignes, notes et commande
  hors du scratchpad (`cartes/sorties/decoupe_nice/`) et consigner dans `a_inscrire_en_base.md`.
- **`trace_mixte()` rend des lignes non simples dans une grande ville à relief** (Nice : l'épine
  centrale, Gairaut avec 13 boucles retirées). Un plus court chemin écrit pour Nice sur PostGIS,
  `cartes/sorties/decoupe_nice/route.py` (voies dans l'ordre, tronçon hors voie compté six fois,
  réseaux eau et fer, segments et contours à la main), a tracé les 29 lignes ; il lit les tables
  `public.nice_bd_*`. À reprendre pour Nice 1860 et 1955, et à généraliser avant une autre ville.
- **Un texte qui nomme un quartier ou un parc sans le borner** (Nice : « parc Liserb », « quartier
  Liserb supérieur », « quartier de l'Ariane ») : aucune donnée ne le délimite. Tracer la lecture
  la plus simple, chiffrer l'enjeu, et demander le plan annexé au décret.
- **Les agents en parallèle ne peuvent pas écrire ; la session principale écrit sans demander**
  (règle du 13 octobre 2026, qui remplace l'accord explicite exigé le 9 octobre). Tout faire :
  CSV, `98`, `a_inscrire_en_base.md`,
  `tableau_villes.py` (dictionnaire `REMARQUES`, et `REVISEES` si la ville est reprise), ce skill,
  et le nettoyage des tables `public.<ville>_*`.
- **Un arrêté de l'an X qui nomme des parties sans les borner** (10 octobre 2026 — Saint-Flour :
  « le Faubourg » au Nord, « la Ville » au Sud ; Falaise : trois sections) : il donne l'ATTRIBUTION,
  pas la ligne. Chercher alors (a) les monographies locales et annuaires sur archive.org
  (`advancedsearch.php`, puis `<id>_djvu.txt` ; passer `tr -s ' '` avant tout grep, l'OCR a des
  espaces doubles) : les chapitres « division par paroisses » et « par justices de paix » d'une
  statistique d'arrondissement disent quelle paroisse est de quel canton, exceptions comprises
  (Galeron pour Falaise) ; (b) les populations légales de l'INSEE par fraction cantonale
  (`insee.fr/fr/statistiques/fichier/<n>/dep<NN>.pdf`, jusqu'au 1er janvier 2014), à comparer aux
  populations des IRIS : à Saint-Flour, deux IRIS nommés « Nord » et « Sud », 38,4 % au Nord des
  deux côtés. La ligne s'écrit alors sous la source `iris` (Saint-Flour) ou `main` (Falaise), la
  note commence par ce qui est du texte et ce qui ne l'est pas. À essayer sur Tartas, Le Quesnoy,
  Avesnes — mais LIRE D'ABORD l'arrêté : celui de Confolens (9 pluviôse an X, arrêté rectificatif)
  bornait les deux parts par la Vienne.
- **Nord et Sud ne sont pas toujours des directions** : le « Nord » de Saint-Flour est le faubourg,
  l'est et le sud de la commune ; le « Nord » de Falaise est un coin nord-est de 320 ha. Ancres par
  points, et ne pas déduire l'orientation du partage des seules communes voisines (l'entrée n° 97
  concluait « est / ouest » pour Falaise, à tort).
- **Les points triples ne bornent pas toujours la limite interne** : à Saint-Flour le bord communal
  sépare les cantons sur 7,6 et 7,4 km ; à Falaise la part Sud touche quatre communes du canton
  Nord, et Galeron le dit. Ils ne sont une contrainte que si rien d'autre ne parle.
- **Lire tous les textes d'une ville avant de tracer le premier** (Aurillac) : un canton que les
  décrets suivants ne redécrivent pas (le IV de 1973) garde sa limite, et le texte le plus récent
  identifie les noms perdus (« route de Murat » de 1973 = « chemin départemental n° 117 » de 1985 ;
  « promenade du Gravier » = cours Monthyon ; rue de Marmiesse prolongée par le chemin du Bousquet).
  Dans l'autre sens, l'arrêté de l'an X a montré que la limite Nord / Sud d'avant 1973 était celle du
  IV : mêmes communes rurales, mêmes rues dans la vieille ville (Salut, Forgerons, Rieu).
- **Une avenue rectiligne qui s'arrête avant le bord, sans « jusqu'à la limite »** (Aurillac 1982,
  avenue de Tronquières : 289 m du bord au plus court, 1,3 km dans l'axe) : le raccord automatique
  part à angle droit et donne tout un quartier à un canton. Tracer les deux fermetures, chiffrer
  l'écart (38 ha), le dire dans la note.
- **La dernière voie du texte peut devenir limite communale avant de finir** (Aurillac, D117 le long
  de Giou-de-Mamou, 208 m ; Falaise, route de Caen le long d'Aubigny, 230 m) : couper au point où
  elle touche ou quitte le bord.
- **Les communes rurales d'un ancien canton peuvent être en base sous le code de son successeur**
  (Jussac, créé en 1985, porte quatre communes dès 1973) : la requête des contacts ne les trouve
  pas sous le code de la fraction urbaine.
- **Un agent peut laisser une requête tourner après son rapport** (Falaise : un `SELECT` d'une heure
  dans PostgreSQL) : regarder `pg_stat_activity` au retour de chaque agent, et `pg_cancel_backend`.
- **`--ecrire` bloque un export en cours** : `98` sous `appliquer` rejoue la recette de toutes les
  villes dans une transaction (sept minutes le 10 octobre 2026), et `export_web.py --partition`
  attend le verrou pendant ce temps. Enchaîner les passes dans un seul script, et savoir que les
  départements déjà exportés sont à refaire.
- **Le décret de 2014 relit celui de 1982** (Angoulême, 10 octobre 2026) : les cantons de 2015 reprennent
  souvent les limites de 1982 en les précisant. « Le prolongement de la rue Pierre-Grenet jusqu'à la
  limite » (1982) devient « ligne droite […] jusqu'à l'intersection du boulevard de Bigorre et de la
  rue du Petit-Montbron » (décret 2014-195). La page Wikipédia « Liste des cantons de <département> »
  transcrit ces décrets dans son tableau des cantons de 2015 : la lire AUSSI pour un régime de 1973
  ou de 1982, puis collationner sur Légifrance. `curl` y reçoit un 403 ; le navigateur intégré lit
  la page (`navigate`, puis `document.body.innerText`). C'est une lecture d'un texte par un autre
  régime : le dire dans la note, et dire ce qui diffère entre les deux.
- **Trancher entre deux lectures par la population** (Angoulême) : répartir la population de chaque
  IRIS (base infracommunale de l'INSEE) au prorata des logements BD TOPO (`BDTOPO_V3:batiment`,
  `nombre_de_logements` ; dix minutes de WFS pour une ville de 40 000 habitants) de chaque côté des
  lignes, et comparer aux fractions cantonales des populations légales. Le Nord d'Angoulême tombait
  à 17 habitants près ; la lecture écartée s'éloignait de 700 à 1 000. Cela départage des lectures
  qui déplacent des habitants, pas celles qui déplacent des hectares vides.
- **Une rivière nommée là où la BD TOPO en voit une autre** (Angoulême : « l'Anguienne depuis son
  embouchure jusqu'au pont de Saint-Cybard » est le bras sud de la Charente ; la BD TOPO fait
  déboucher l'Anguienne, en conduite, 300 m en amont du pont) : suivre ce que le texte en dit, par
  morceaux bornés de `("point", x, y)`, et le dire.
- **Une voie longue citée comme simple raccord** (« rue de Bordeaux » entre le pont et l'avenue de
  Cognac) : `trace_mixte` la suit sur 485 m puis revient, une épingle sans surface. Regarder l'image.

- **Gallica bloqué : archive.org a souvent le même texte** (13 octobre 2026). La *Collection générale
  des lois* de Rondonneau reproduit les arrêtés de l'an X avec leur référence au Bulletin
  (Confolens, t. 8, p. 696) ; les exemplaires Google du Bulletin des lois ont un OCR `_djvu.txt`
  (Rochefort, loi du 29 juin 1852). La recherche plein texte d'archive.org les trouve par une suite
  de noms de communes ; l'image d'une page se lit par
  `https://archive.org/download/<id>/page/n<feuillet>_w1400.jpg` (le feuillet vient de
  `fulltext/inside.php`, pas du numéro de page de l'OCR). Lire l'IMAGE, pas l'OCR, et demander
  quand même à Adrien la page Gallica pour collationner.
- **Une loi de 1852 peut donner la limite** (Rochefort) : « section urbaine » et « section foraine »
  décrites en circuits d'îlots. La limite est la voie commune aux deux circuits ; ce qu'aucun
  circuit ne contient (l'arsenal) reste sans texte, et une formule comme « en deçà de la route de
  Saint-Malo » laisse sans attribution ce qui est au-delà (environ 365 ha) : tracer les deux
  lectures et les chiffrer.
- **Un nom de rue ancien peut exister aujourd'hui ailleurs** : la « rue de la République » de
  Rochefort en 1852 est l'ancienne rue Royale (avenue Charles-de-Gaulle), pas la rue actuelle du
  même nom, perpendiculaire. Les listes de rues des monographies (dans l'ordre, par sens) font la
  concordance.
- **« Ligne imaginaire dans l'axe de la rue jusqu'au pont »** (Cognac) : deux `("point", x, y)`
  consécutifs dans `trace_mixte` font un segment droit ; comparer son azimut à celui de la rue
  identifie le pont quand la BD TOPO ne le nomme pas. Les culées (« rive droite ») sont dans
  `BDTOPO_V3:construction_lineaire` (nature « Pont ») ; un pont peut aussi n'être qu'un tronçon
  sans nom, à trouver en croisant l'axe de l'eau avec les tronçons.
- **Canal et rivière parallèles** (Cognac : canal Jean-Simon et Charente) : `("eau", "charente")`
  ne prend pas le canal. Dire dans la note de quel côté tombe l'île, et ce qu'elle pèse.
- **Une place réduite à un anneau de rond-point** : « côté Sud-est » se force en donnant les sommets
  de l'anneau en `("point", …)`. Et le premier tronçon d'un boulevard peut porter le nom de l'avenue
  voisine (boulevard de Javrezac / avenue de Saintes) : regarder l'alignement.
- **`("commune", insee)` en départ peut prendre un sommet intérieur** (tolérance de 60 m, départ à
  44 m du bord) : quand la voie touche le bord, donner son bout exact en `("point", x, y)`.
- **`trace_eau` laisse un bout le long du bord** quand l'axe et le contour ANR coïncident (Confolens,
  214 m) : mesurer la part de la ligne à moins de 2 m du bord, puis `--rogner 10`.
- **Deux voies du texte qui ne se touchent plus** après un réaménagement (Rochefort, port de
  plaisance) : tracer les deux raccords, les chiffrer en logements. Un canal sans toponyme se
  reconnaît à la rue qui porte son nom (canal des Sœurs).
- **`cible_ville()` dans un `WHERE` ou une jointure est réévaluée à chaque ligne** (plus de deux
  minutes, vu trois fois le même jour) : la matérialiser d'abord dans `public.<ville>_cible`. Et
  les contacts avec les voisines se mesurent sur `atom_geom_anr`, pas sur `atom_geom` (contour
  GEOFLA généralisé : Vergeroux 482 m contre 1 881 m).
- **Populations légales par fraction cantonale** : `insee.fr/fr/statistiques/fichier/2119747/dep<NN>.pdf`
  (en vigueur au 1er janvier 2014, population 2011) et `2119780` (2013, population 2010) ; `2387611`
  est déjà en cantons de 2015.
- **`get_feature(bbox=…)` veut un tuple de quatre nombres** ; une chaîne finissant par `,EPSG:2154`
  rend un HTTP 400, comme les couches `toponymie_*`.
- **zsh : `rm -f g_*.geojson` sans correspondance arrête toute la chaîne `&&`** (« no matches
  found ») : les fichiers écrits plus loin dans la même commande ne le sont pas.
- **Des tables `public.<ville>_*` d'un essai antérieur peuvent traîner** : préfixer les siennes et
  ne pas écraser celles qu'on n'a pas créées.
- **Un arrêté de l'an X peut borner la ville par des rues** (Saintes, 27 brumaire an X, comme La
  Rochelle dans le même arrêté ; Rondonneau, t. 8, p. 575-578) : le lire avant de supposer que la
  rivière sépare. À Saintes la Charente traverse la ville et n'est pas la limite du texte ;
  Wikipédia (« Canton de Saintes-Nord ») affirme le contraire sans source.
- **Les noms révolutionnaires (« rue de la Commune », « rue de la Préfecture »)** se retrouvent dans
  les dictionnaires de rues des sociétés savantes (Saintes : Dangibeaud, Bulletin de la Société des
  archives historiques de Saintonge et d'Aunis, t. 25-26, sur archive.org). Un même nom a pu
  désigner deux rues : la géométrie tranche (§ 3).
- **Un texte qui s'arrête « à la rivière » ne dit rien de l'autre rive** (Saintes an X : 1 029 ha) :
  regarder si le texte suivant reprend un tronçon de la rivière (1985 : « de la hauteur de la place
  Blair à la limite des Gonds ») et ce que la chronologie dit de la filiation (« division de
  Saintes-Nord »). L'écrire comme une déduction, chiffrée.
- **Une rivière qui est d'abord limite communale** : `("commune", insee)` en départ prend un sommet
  sur le tronçon où l'axe et le bord coïncident (834 m le long du bord à Saintes). Calculer le point
  où l'axe quitte le bord (`ST_Difference(axe, ST_Buffer(bord, 10))`, début de la plus longue partie
  intérieure) et le donner en `("point", x, y)`.
- **Deux `("point", …)` en tête de `trace_mixte` : le premier est perdu** (Saintes, deux fois).
  Vérifier « bouts au bord » dans le rapport et rajouter le point en SQL (`ST_AddPoint(l, p, 0)`).
- **Un nom BD TOPO peut couvrir deux voies disjointes** (« Passage Gambetta » : une ruelle et le
  passage sous la voie ferrée) : vérifier sur l'image lequel a été pris.
- **« Chemin vicinal n° N » n'a pas de numéro dans la BD TOPO** : chercher la départementale qui
  naît à la limite de la commune nommée et la voie qui y mène depuis l'élément précédent ; chiffrer
  l'autre candidat.
- **archive.org rend parfois une erreur 500 à la place d'un `_djvu.txt`** (sept lignes de HTML) :
  contrôler `wc -l` avant de conclure qu'un mot est absent.
- **`ST_Union(…, 'LINESTRING EMPTY')` sans SRID échoue** (« mixed SRID ») dans la requête § 6 quand
  un régime n'a qu'une ligne : `ST_SetSRID(…, 2154)`.
- **Une voie ferrée déposée** (Bourges, ligne de Gien) : `("fer",)` ne la connaît pas. Chercher le
  tronçon « Non exploité » resté dans `<insee>_fer.geojson` (parfois hors de la commune), puis les
  chemins sans nom dans son alignement (comparer les azimuts). Ce que rien ne porte se trace en
  droite et se chiffre.
- **Le texte suivant dit où chaque voie s'arrête** (Bourges) : 1973 énumère « avenue de la
  Libération, rue Gustave-Eiffel, rue Jean-Moulin », 1982 ajoute « jusqu'à la rue… » à chacune.
  L'avenue de la Libération, 1 100 m, n'est limite que sur 227 m. Et la jonction d'une ligne de 1982
  avec une ligne de 1973 n'est pas toujours au carrefour qu'on croit (86 m plus au sud) : mesurer.
- **Un boulevard courbe** (Lamarck) : le plus court chemin entre ses bouts coupe par les rues
  intérieures. Donner un ou deux points de passage sur son tracé.
- **Une route nommée a parfois une contre-allée du même nom** (route de la Charité, 85 m au nord) :
  vérifier `importance` des tronçons au bord, finir par un `("point", …)` sur la chaussée.
- **Un cours d'eau sans toponyme** (Yévrette, ancien canal de Berry) : `("eau", nom)` ne le trouve
  pas ; le repérer par ce que le texte en dit, puis `_plus_court` sur un réseau d'eau filtré par
  emprise. Deux chenaux parallèles : tracer l'un, chiffrer l'autre.
- **Un nom de voie seulement « collaboratif »** (RPE MARCEAU) : `elements()` ne lit que
  `nom_voie_ban` ; chercher aussi `nom_collaboratif_gauche` dans les tronçons.
- **Des cantons tous urbains mais bornés par le texte** (« et les limites des communes de … ») :
  l'attribution n'a pas besoin du plan ; le contrôle est la liste des voisines de chaque morceau,
  à comparer mot pour mot au texte.
- **Sans IRIS** : la part des logements BD TOPO par morceau contre la part de population INSEE par
  fraction (2,5 points d'écart au plus à Bourges) attrape une inversion de cantons, pas une limite
  déplacée de quelques rues.
- **Un nom de voie peut n'exister que dans `nom_collaboratif_gauche/droite` des tronçons** (La
  Rochelle : avenue du Président-Wilson, avenue de Lisbonne, quai du Carénage, viaduc
  Christian-Morch). Chercher là avant de déclarer un nom disparu, puis tracer sur une copie
  augmentée de la voirie en redéfinissant `VOIRIE` dans le script. Et une voie « non dénommée »
  d'un décret peut l'être encore : `voie_nommee` porte des objets au nom vide
  (`coalesce(nom_voie_ban,'') = ''`, pas `IS NULL`).
- **Le décret de 1982 peut réciter l'an X** (La Rochelle : Abreuvoir, Fromentin, Dupaty, Grille,
  Ferté, quai Maubec) : il donne alors la concordance des noms de 1801.
- **Chercher la loi d'annexion** (La Rochelle, loi du 21-29 mai 1858 : « la situation cantonale
  […] reste la même ») : la limite hors les murs est alors l'ancien contour communal (ANR d'avant
  la fusion), composé avec la ligne de la ville par `ST_LineSubstring` de l'anneau. Duvergier,
  *Collection complète des lois*, est sur archive.org par année. Des communes supprimées peuvent
  n'avoir aucun atome (Cognehors, Saint-Maurice) : la différence des unions d'ANR montre le trou,
  pas la limite entre elles ; une ligne sans texte s'écrit sous la source `main`, et sa note
  commence par « HYPOTHESE ».
- **Ouest peut vouloir dire nord** (La Rochelle an X : « à la gauche de la ligne » en partant de la
  porte de l'Ouest). Lire le sens de parcours, ancrer par points.
- **Le polygone ANR d'une voisine peut ne pas être jointif** (Puilboreau à 133 m du contour de La
  Rochelle sur 2,5 km) : mesurer les contacts avec une tolérance de 150 m, et ne pas finir une
  ligne par `("commune", insee)` sur une telle voisine.
- **Le plus court chemin dans tout le réseau ferré fait un détour par les voies de service** :
  router sur `nature = 'Voie ferrée principale'` et joindre la voie désaffectée par un segment.
- **Divers** : `ST_Union(bord, NULL)` rend NULL dans la requête § 6 pour un essai à une ligne
  (`coalesce`) ; `grep 17300 coupes_ville.csv` trouve des coordonnées, chercher `^17300` ;
  `pgrep -f` dans une boucle d'attente se trouve lui-même (motif `[q]gis_sans_ihm`) ; huit lignes
  par `trace_mixte` prennent quatre minutes, à lancer en arrière-plan avec un journal.

- **Un nom de rue disparu n'a pas forcément été donné à la voie qu'on croit** (Vierzon, 16 octobre
  2026) : la « rue Romain-Rolland » de 1973 semblait être la rue François-Mitterrand (axe de
  l'ancienne RN 20) ; c'était la rue des Ponts, revenue à son nom ancien (histoire locale, puis le
  décret 2014-206 : « rue Voltaire, rue des Ponts, cours du Cher »). Lire le texte de 2014 AVANT de
  deviner une concordance ; la population départage (2,4 points contre 5,2 ; 21 ha en jeu).
- **Légifrance se lit par WebFetch** (`curl` : 403) ; le résumé ne cite que quelques mots :
  demander « la liste ordonnée des voies, noms seuls », puis comparer à la transcription Wikipédia.
- **« Jusqu'au deuxième bras … bordé par le quai »** : compter les bras que la rue franchit ; l'île
  entre les deux reste du côté d'où vient la rue (Vierzon, 3,6 ha, 34 logements).
- **« La limite emprunterait la place dont l'axe coïncide avec celui du tunnel »** : le tunnel est
  dans `<insee>_fer.geojson` (`position_par_rapport_au_sol = -1`) ; suivre la place, raccorder aux
  portails.
- **`trace_mixte` perd aussi un `("point", …)` de tête suivi d'une `("route", …)`** : vérifier le
  premier sommet du WKT, `ST_AddPoint(l, p, 0)`.
- **Un faisceau ferré en gare** : assembler en SQL une chaîne de « Voie ferrée principale »
  (`ST_LineMerge`, `ST_LineSubstring`) et dire la largeur du faisceau laissée d'un côté (Vierzon,
  78 m, 3,7 ha).

- **Une fraction fantôme peut venir d'une coquille du COG 1968** (Dinan, 16 octobre 2026 :
  `11851#2219` « Lannion », sans géométrie, parce que la ligne de Caouënnec porte le code 050 de
  Dinan dans `cog1968/communes_1968_fusion.csv`). Avant de croire à un canton de plus, chercher la
  ligne dans le COG 1968 ; tester à une date hors de la période fautive, et consigner.
- **Populations légales et IRIS d'accord ne prouvent pas la limite du texte** (Dinan : l'INSEE
  compte tout l'intra-muros à l'Est, l'arrêté de l'an X en met le nord à l'Ouest, environ
  600 habitants) : ils disent ce que l'INSEE compte. Le texte fait foi ; chiffrer l'écart.
- **Une porte de ville disparue** se localise par le récit de sa démolition (« on a fait une
  place ») et par un bâtiment « près de la vieille porte » encore debout.
- **Gallica renvoie un 403 Cloudflare à `curl`** (16 octobre 2026), pas seulement un captcha :
  lire sur archive.org (Rondonneau) et demander à Adrien de collationner.

- **Un `("point", …)` final après une voie, à plus de 30 m, se rejoint « par les rues »**
  (Brive, 16 octobre 2026) : « rue Bouyssonie (et son prolongement jusqu'à la Corrèze) » a fait
  1 468 m de détour. Finir sur la voie (son bout le plus éloigné de la précédente) et ajouter le
  point du prolongement à la main.
- **`P(J)` en tête de `trace_mixte` ne garantit pas que la ligne parte de J** : elle part du
  sommet de la première voie (Jouvenel : 120 m du pont de la Bouvie). Lister les bouts de chaque
  ligne contre les points de jonction avant `pose_coupe.py`, et `ST_AddPoint(l, J, 0)`.
- **Un pont n'est pas dans `voie_nommee`** : le boulevard Mirabeau s'arrête aux culées ; le pont
  de la Bouvie n'est qu'un tronçon au `nom_collaboratif` « PONT DE LA BOUVIE ». Point de jonction
  = croisement de ce tronçon avec l'axe de l'eau.
- **Des lotissements et une usine nommés par le décret** (Brive 1985 : « limite séparative
  entre les lotissements Yemaux et Ma Maison ») : le cadastre (WFS
  `CADASTRALPARCELS.PARCELLAIRE_EXPRESS:parcelle`, `get_feature(bbox=…)`) donne les limites ; les
  enchaîner par `ST_Intersection` des unions de parcelles de part et d'autre. Les noms ne sont
  pas dans les données : le dire.
- **Les codes d'un régime ancien peuvent être ceux de son successeur** (Brive : 1906 = Brive-Nord
  et 1930 = Brive-Sud de 1951 à 1982 pour les communes rurales, alors que la ville reste entière
  dans 1906) : lire les appartenances des communes rurales pour ancrer une ligne de régime absent
  (`--morceaux N --ancres-datees`, ancres sur ces codes).
- **Un chemin rural nommé par ses deux hameaux, qui ne touche plus la commune voisine que le texte
  lui fait couper** : la carte IGN type 1950 (WMTS Géoplateforme
  `GEOGRAPHICALGRIDSYSTEMS.MAPS.SCAN50.1950`, zoom 15 au plus ; superposer les couches après
  passage en Web Mercator) montre les routes d'alors ; tracer la lecture la plus simple et
  chiffrer les autres.

- **Le canton « mère » d'une division de 1973 peut garder son ancien nom** (18 octobre 2026 :
  Guéret-Nord 2319, Périgueux-Centre 2427, Montbéliard-Est 2514) : pas de `unit_version` entre 1941
  et 1999, le repli affiche « Guéret ». Le nom n'affecte pas le tirage ; le consigner.
- **Un canal latéral qui porte le nom de la rivière** (Périgueux : « l'Isle » est aussi le canal,
  2 285 m) : `trace_eau` et `("eau", …)` prennent le raccourci par le canal (traversée fausse de
  6,3 km). Lister les tronçons du toponyme, repérer le lit que borde le contour ou que longe un
  « chemin de halage », et l'extraire en SQL entre les points où il quitte et rejoint le bord.
- **« Rue X, prolongée » peut être une rue nommée après le décret** (Périgueux, rue Jean-Secret au
  bout exact de la rue Trarieux) : regarder quelle voie part du bout de la rue citée avant de
  prolonger dans l'axe, et chiffrer la droite (7,5 ha).
- **« RN n appelée en ce lieu route d'X » : la voie homonyme actuelle peut être ailleurs**
  (Montbéliard : la « Route d'Hericourt » de la BAN est à 519 m du texte ; la RN 438 de 1973 est la
  rue de la Seigneurie-d'Héricourt, la D438 actuelle est une déviation postérieure). Prendre la voie
  qui touche la limite nommée et la rue suivante.
- **Dater une voie par l'orthophoto historique** : WMS `data.geopf.fr/wms-r/wms`, couches
  `ORTHOIMAGERY.ORTHOPHOTOS.1950-1965`, `.1965-1980`, `.1980-1995`, en `FORMAT=image/png` (le jpeg
  est refusé), un `.pgw` à côté, la BD TOPO par-dessus dans un `QgsMapSettings`. A montré à
  Montbéliard quelles rues existaient en 1973.
- **Un décret qui décrit le périmètre du canton, pas celui de la fraction** (Montbéliard : « suit
  la limite de Bethoncourt jusqu'à la RN ») : si la commune rurale est du même canton, cette limite
  n'est pas interne. La ligne commence où le texte quitte la limite communale.
- **`("commune", insee)` en arrivée coupe aussi** (Montbéliard, 44 m de la rue des Vignes en
  droite) : quand la dernière voie finit sur le bord, finir par `("point", x, y)` sur son bout.
- **Un `("point", …)` intermédiaire (centre d'un rond-point) fait un aller-retour** quand l'élément
  suivant passe à côté (Guéret, place Arfeuillère, 25 m) : ne pas donner la place en point si la
  rue ou le cours d'eau la traverse déjà, ou retirer le sommet (`ST_RemovePoint`).
- **Une ancre au centroïde apparent peut tomber hors de la commune** (contour découpé, Guéret) :
  `pose_coupe.py` dit « morceau None ». Prendre un point près du centroïde qu'il imprime.
- **Les GeoJSON de `get_feature` se déclarent en WGS84 avec des coordonnées en Lambert 93**
  (bâtiments, zones d'activité) : `ogr2ogr -a_srs EPSG:2154`, pas `-t_srs` (« Invalid latitude »).
- **Numéroter un fichier SQL** : vérifier le numéro libre dans `sql/` *et* dans l'inventaire de
  `sql/diag_passages.sql`. `98_coupe_ville.sql` avait d'abord été écrit sous `97`, réservé : son
  `DELETE` a vidé la trace d'un autre fichier.
- **`histgis.iris_ville` disparaît au `rebuild.sh`** ; `rejouer_apres_rebuild.sh` la recharge
  depuis `cartes/sorties/iris_villes.geojson`. Si elle manque, la recharger avant tout.
- **Ne jamais stocker un polygone de fraction** : la ligne est la donnée, le polygone se dérive au
  tirage sur la trame du jour (ANR, ou `atom_geom` en repli). Une ligne survit à un changement de
  trame ; un polygone en meurt.
- **Les CSV sont la vérité, pas la base** : `98` les recharge à chaque passage. Une correction faite
  dans la base seule sera perdue.

- **Une rivière qui se jette dans un canal de dérivation** (Montélimar, 18 octobre 2026) : dans la
  BD TOPO, « le Roubion » s'arrête sur l'axe du canal du Rhône (CNR, 1957), et `trace_eau` dit « ne
  traverse pas ». Prolonger par l'« Ancien Lit <rivière> » sur une copie filtrée de
  `<insee>_eau.geojson` où les deux toponymes sont renommés pareil (`VOIRIE` redéfini dans le
  script), et chiffrer ce qui est au-delà du canal (547 et 221 ha).
- **Trois toponymes pour une rivière** (« le Roubion », « Ancien Lit Roubion », « Canal du
  Roubion ») : `("eau", "roubion")` de `trace_mixte` les prendrait tous, `trace_eau` filtre le
  toponyme exact. Lister `cpx_toponyme_de_cours_d_eau ~* '<mot>'` avant de tracer.
- **Populations par IRIS pour une ville COG** (Romans, 18 octobre 2026) : les contours se lisent au
  WFS (`get_feature('STATISTICALUNITS.IRIS:contours_iris', cql="code_insee='<insee>'")`,
  `ogr2ogr -a_srs EPSG:2154`) ; la population 2012 est dans
  `insee.fr/fr/statistiques/fichier/2028582/infra-population-2012.zip` (un .xls de 70 Mo : passer
  par `soffice --headless --convert-to csv`, extraire la commune, effacer le reste). Les logements
  seuls s'écartaient de 6,6 points (centre ancien contre pavillons) ; pondérés par IRIS, 0,1 point.
- **« Route de <commune voisine> » absente de la BAN** (Romans : « route de Génissieux ») : c'est la
  départementale qui prolonge la voie précédente vers cette commune, où elle porte souvent le nom
  inverse (« route de Romans »). Si elle longe ensuite le bord, la ligne s'arrête où elle le touche.
- **Une avenue à giratoires** (Émile-Zola, chaussée double) : `trace_mixte` y laisse des boucles et
  rend une ligne non simple. Assembler en SQL les parties de `ST_Dump(voie)` dans l'ordre, un seul
  côté de chaque giratoire (`cartes/sorties/decoupe_romans/assemble.sql`), et chiffrer les îlots.
- **Rondonneau t. 8 : feuillet = page + 58** (Saintes p. 577 = n635, Confolens p. 696 = n754, Crest
  p. 616 = n674) : `page/n<p+58>_w1400.jpg` directement. L'OCR peut se tromper de numéro d'acte
  (Crest : « 1106 » dans l'OCR, 1206 sur l'image) : citer l'image.
- **`trace_eau` laisse le lit hors traversée au morceau voisin, même à contre-rive** (Crest : 3,9 ha
  de lit sans bâtiment). Pour le chiffrer, polygoniser le contour avec TOUT l'axe dans la commune
  et regarder de quel côté de l'axe tombe chaque miette ; le dire dans la note.
- **Une voisine mal placée en 1968 peut venir d'un doublon OCR qui prend son code** (Saou : la ligne
  « Saurzet » 26336, doublon de Sauzet, l'envoie à Marsanne ; Saou est sous 26536). Chercher la
  voisine par son NOM dans `cog1968/communes_1968_fusion.csv`, pas par son code.

- **Un régime qui reprend les voies du précédent** (Dijon 1973, 18 octobre 2026 : Bossuet, Godrans,
  Liberté, Jeannin, Strasbourg, Pasteur, cours du Parc déjà dans A-B et C-D de 1907) : reprendre la
  GÉOMÉTRIE de l'ancienne ligne (`ST_LineSubstring` entre les points de jonction, lus sur la ligne
  elle-même : bouts de la partie commune `ST_Intersection(ST_Snap(ab, cd, 0.5), cd)`, croisement
  avec la voie ferrée, `ST_ClosestPoint` sur la voie suivante), pas la retracer. Mêmes voies, même
  ligne d'un régime à l'autre, et les jonctions tombent à 0,00 m. Huit cantons : sept lignes
  enchaînées par leurs nœuds (point de rencontre de trois cantons) suffisent.
- **Les routes de Dijon Métropole sont numérotées M** depuis 2015 (M974 = ex-RN 74, M107 = ex-RD 107) :
  lister `cpx_numero` avant de chercher une « route départementale ». Et une RD de 1973 a pu changer
  de tracé : la carte IGN de 1950 (`SCAN50.1950`, WMS `wms-r`, superposée à la BD TOPO avec un
  `.pgw`) a montré que la D 107 allait par le hameau de Mirande vers Chevigny, pas par la rue Sully.
- **Un nom introuvable du décret de 1973 peut être dans le décret de 2014** (« rue de Courtrai » =
  rue de Bruges, décret 2014-175, même limite de Fontaine-lès-Dijon) : la page Wikipédia des cantons
  transcrit les délimitations de 2015 ; la lire avant de deviner.
- **Le SCAN 50 de 1950 est généralisé** (cimetière dessiné à 100 m de sa place) : il dit l'ordre et
  l'allure des chemins ; l'orthophoto `1950-1965` donne leur position. Relever les chemins disparus
  sur l'orthophoto.
- **Un traceur lancé par `( … ) &` dans une commande en arrière-plan ne prévient pas à la fin**, et
  son `print` reste en tampon : écrire `FIN` dans le journal en dernier et attendre ce mot
  (`timeout 500 sh -c 'until grep -q "^FIN" trace.log; do sleep 5; done'`).
- **Polygoniser à la main des lignes qui finissent « sur » le bord** ne coupe pas (pas de nœud
  exact) : pour contrôler les morceaux hors de `98`, `ST_Difference(cible, ST_Buffer(lignes, 0.05))`
  avec un `ST_ShortestLine` au bord pour chaque bout à moins de 10 m.

- **Une rivière à îles et à canal** (Besançon, 18 octobre 2026) : la BD TOPO porte « le Doubs »,
  « le Doubs/Canal du Rhône au Rhin » et « Canal du Rhône au Rhin » ; `trace_eau` filtre le toponyme
  exact et `("eau", …)` prend le plus court bras. Choisir les bras à la main sur une image étiquetée
  par `ogc_fid`, les fusionner en SQL (`ST_LineMerge(ST_Union(ST_SnapToGrid(g, 0.01)))` sur la
  liste), couper la traversée par `ST_LineSubstring` entre les points où l'axe quitte le tampon de
  15 m du bord. Les îles se chiffrent par `ST_Polygonize(ST_Node(…))` de tous les bras.
- **« L'île X exclue » d'un côté sans rien de l'autre** : le décret de 2014 peut dire
  « incluse » dans le canton d'en face (île Saint-Pierre, décret 2014-240). Le lire avant de
  donner l'île au troisième canton ; dire l'aire en jeu dans la note.
- **Le traceur peut préférer une rue parallèle à la rue nommée** et l'écrire quand même dans son
  rapport (« rue Henri-et-Maurice-Baigue 851 m » sur la rue Narcisse-Lanchy) : seule l'image le
  montre. Poser la rue en SQL depuis `ST_Dump(ST_LineMerge(voie))` entre ses deux carrefours.
- **zsh n'exécute rien d'une commande mal citée** : une apostrophe (« jusqu'a ») dans un `sed`
  entre apostrophes fait échouer TOUTE la commande, y compris les `cat <<EOF` qui la précèdent.
  Écrire les notes par l'outil d'écriture ou par Python.
- **Une ligne de Gaudillère posée sans date peut être celle de l'an X** (Saint-Brieuc, 18 octobre
  2026 : posée 1870-1982 faute de date). L'arrêté de réduction des justices de paix du département
  (Rondonneau t. 8, `grep -n "<Ville> sera divisée"` dans l'OCR) la décrit souvent avec les noms de
  1801 : « fontaine à Loup » (passage de la Fontaine-à-Loups), « grande route de Brest » (une suite
  de rues actuelles, pas la rue de Brest d'aujourd'hui). Mesurer la distance de chaque repère à la
  ligne posée ; à 0 m, prolonger la ligne au jour de l'arrêté plutôt que d'en tracer une autre.
- **Un escalier nommé par un décret** (« escalier du boulevard de la Chalotais ») est un tronçon
  BD TOPO de nature `Escalier`, sous le nom d'un passage (`nom_collaboratif_gauche`) : chercher par
  `nature ~* 'escalier'` autour de la voie citée.
- **Retirer une boucle d'une ligne** : `ST_Dump(ST_UnaryUnion(ligne))` la coupe à ses recoupements ;
  jeter le morceau dont le début est la fin, `ST_LineMerge` du reste.
- **Un rebuild en cours** (Louviers, 20 octobre 2026) : `cible_ville`, `coupe_ville` et
  `atom_geom_anr` peuvent manquer pendant des dizaines de minutes. On peut tracer quand même :
  lire le polygone ANR dans `sources/ANR_COMMUNES_22042026/COMMUNES_22042026.gpkg`
  (`-where "id_com='<atome cassini>'"`) vers `public.<ville>_cible`, et remplacer
  `histgis.cible_ville(...)` par cette table dans le script de tracé. `pose_coupe.py` et
  `--ecrire` attendent la fin de `rejouer_apres_rebuild.sh` (`pgrep -f "[r]ejouer_apres"`), qui
  rejoue `98` lui-même.
- **« La rivière X » sans bornes en tête d'une liste de rues** (Louviers : « la rivière Eure et
  rue des Bigards… ») : deux tronçons possibles, l'amont ou l'aval de la première rue. La
  population tranche (48,4 % au Nord contre 48,8 % légal ; l'amont donnait 70,8 %).
- **Un `("point", …)` intermédiaire est rejoint en droite**, pas par les rues (320 m à Louviers) :
  pour suivre un chemin réel, substituer sa géométrie en SQL. Et `("voie", nom)` d'un nom présent
  seulement dans les tronçons peut faire un détour (1 059 m).
- **Un bord tenu tout entier par une commune d'un troisième canton** (Louviers, Tostes) : pas de
  point triple, l'arrivée d'un prolongement sans texte reste libre ; chiffrer la variante.
- **L'OCR du JO de 1985 écrit « Bemay »** (rn lu m, Bernay) : `grep -i <ville>` ne trouve rien.
  Chercher par un canton voisin du même décret, ou par le numéro du décret dans
  `TABLE_ANALYTIQUE_JORF_<année>.txt`.
- **Une rue « jusqu'à la voie ferrée » au-dessus d'un tunnel** (Bernay, rue Lemoing) : le
  croisement est son passage sur le tunnel (`position_par_rapport_au_sol = -1`) ; chiffrer la
  poche entre le tunnel et les rues (1,68 ha).
- **Une route nationale déclassée dont le numéro a disparu de la BD TOPO** (CD 834 de Bernay,
  ex-RN 834) : la page Wikipédia « Route nationale <n> » donne l'itinéraire.
- **Une avenue renommée sur son dernier tronçon après le décret** (Valence : l'avenue de la Marne
  de 1984 continue en avenue du Colonel-Arnaud-Beltrame, nom postérieur à 2018) : lire les noms
  des tronçons qui la prolongent avant de raccorder au bord.
- **Un décret qui place un repère « sur la limite » alors qu'il est en pleine ville** (Valence
  1973 : le centre hospitalier, à 1,9 km du bord) ou qui nomme la mauvaise voisine (« limite de
  Saint-Marcel » pour Chabeuil ou Montélier) : le décret suivant donne la lecture, les contacts
  le montrent ; chiffrer l'autre lecture.
- **Un canal sans toponyme cité par un décret** (canal des Moulins, Valence) : le prendre en SQL
  par `ST_LineSubstring` du tronçon d'eau entre les deux rues qu'il coupe ; `("eau", "")`
  prendrait toute l'eau sans nom.
- **Peu d'IRIS (20 à Saint-Brieuc)** : le prorata des surfaces écartait de 3,5 points ; répartir
  la population des seuls IRIS coupés au prorata des logements BD TOPO (bbox de ces IRIS, deux
  minutes) a ramené l'écart à 0,9.
- **Une rue limite communale avant de devenir limite de canton** (Chartres 1973, rue du
  Faubourg-Saint-Jean, 353 m sur la limite de Mainvilliers) : les tronçons dont
  `nom_collaboratif_gauche` et `_droite` diffèrent le montrent ; la ligne commence où les deux
  noms redeviennent égaux.
- **Un nom disparu de `voie_nommee` survit sur un tronçon résiduel** (Chartres, « boulevard de la
  Résistance » : 47 m collés au bd Maurice-Viollette) : chercher `nom_collaboratif_gauche` dans une
  boîte autour de la suite du texte. Une « rue X » qui ne touche plus le carrefour cité a pu être
  renommée sur sa partie utile (rue du Repos = rue du Souvenir-Français) : prendre la voie qui part
  du carrefour exact.
- **Pendant une reconstruction, `iris_ville` et `cible_ville` manquent** : recharger les IRIS dans
  `public.<ville>_iris` (`ogr2ogr -where "code_insee='…'"` sur `cartes/sorties/iris_villes.geojson`)
  pour éprouver, et attendre la fin (`pg_stat_activity`, processus `rebuild.sh` /
  `rejouer_apres_rebuild.sh`) avant tout `--ecrire` ou `98`.
- **Les WMS d'ortho anciennes** (`ORTHOPHOTOS.1965-1980` vide sur une ville, `1950-1965` en 502 au
  premier essai) : réessayer avant de conclure.
- **Un nom disparu de la BAN survit en alias** (Vernon, « AV THIERS » = avenue
  Pierre-Mendès-France) : chercher dans tous les champs texte de `<insee>_troncons.geojson`
  (`alias_gauche`, `alias_droit`), pas seulement `nom_voie_ban` et `nom_collaboratif`.
- **« Rue Latérale » est un nom commun** (Vernon 1982 : une voie le long d'une voie ferrée). Entre
  deux voies ferrées (la ligne principale et une ligne déposée, visible sur l'ortho 1950-1965),
  tracer les deux lectures et trancher par la population (34,5 % contre 46,1 %, légale 33,9 %).
- **« Au Nord d'une ligne » qui quitte une rue avant son bout** (Vernon : 240 m de la rue de
  Montigny non suivis) peut faire passer tout un quartier de l'autre côté (le vieux centre au Sud) :
  regarder de quel côté tombe chaque quartier avant de croire le nom du canton.
- **Pendant une reconstruction, `atom_geom_anr` disparaît aussi** : exporter la cible en WKT au
  départ, et compter les populations en Python / OGR plutôt que dans une table `public.*`.
  `pgrep -f "[r]ejouer_apres"` dans une boucle d'attente écrite dans un fichier (pas un `sh -c` avec
  des `\x27` entre guillemets doubles, qui a échoué en silence).
- **OGR sous `/usr/bin/python3`** : `GetGeometryRef().Clone()` avant d'utiliser une géométrie hors de
  la boucle, sinon segfault (139). PIL est dans le python système, ni shapely ni PIL dans miniforge.
- **Un chemin rural sans trait BD TOPO** (Dreux 1982 : chemin rural 66, sente rurale 74) reste
  souvent visible au cadastre comme une bande non parcellisée de 3 à 6 m : parcelles de la bbox
  (PCI Express WFS), `ST_Difference(bbox, ST_Union(ST_Buffer(parcelles, 0.2)))`, axe du polygone
  allongé. Des numéros de parcelles cités en 1982 peuvent exister encore (AK 132 / AK 25 / AI 11).
- **Le décret de 2014 traduit les anciens noms** (Dreux-1 : sente 74 → Pershing / Voisin, La Fayette
  → Grande-Falaise, « limite de Montreuil » pour « Chérisy ») : le lire, chiffrer l'écart.
- **Un JO de 1973 porte plusieurs décrets du même jour** : relever le numéro sur l'en-tête du
  département (`JORF_19730725_171` : Eure-et-Loir 73-719 l. 1294, Ille-et-Vilaine 73-723 l. 2041) ;
  Chartres a été écrit d'abord sous le mauvais numéro.

- **Un « jusqu'au numéro N » se localise par la BAN** (Alès, 21 octobre 2026) :
  `api-adresse.data.gouv.fr/search/?q=311A avenue Youri Gagarine&citycode=30007`. Des numéros
  restés à une voie (le 311 B, 80 m plus loin) désignent l'ancien tracé d'un chemin disparu
  (chemin rural n° 27). Le sens de la numérotation se lit sur deux numéros.
- **`_plus_court` fait des détours énormes où la BD TOPO manque un lien** (Alès : 1 415 m pour
  520 m à vol d'oiseau) : lister la longueur de chaque tronçon avant d'assembler, mettre en ligne
  droite le lien qui manque, et le dire.
- **Une ligne reprise d'un régime à l'autre suit le texte du nouveau régime** : le décret de 1973
  nomme le Grabieux là où Gaudillère dit « quai du 8-Mai » (Alès, 0,97 ha qui changent de canton
  en 1973) ; la note chiffre l'écart.
- **Grande ville : `trace_mixte` est trop lent** (Toulouse, 21 octobre 2026, 121 Mo de tronçons).
  Charger la BD TOPO dans `public.<ville>_*` et router en PostGIS + Python : le Dijkstra « en
  couches » (nœud, voie k, voie entamée) de `cartes/sorties/decoupe_toulouse/route.py` impose
  chaque voie dans l'ordre. Sans l'état « voie entamée », il sautait des voies entières (route de
  Saint-Simon sur 3,4 km à la place de cinq voies).
- **Une autoroute à échangeur ne se route pas par son numéro seul** (rocade de Toulouse) : les
  chaussées ne sont pas reliées aux bretelles ; donner des points de passage sur l'axe.
- **« La voie ferrée » au croisement d'une rue peut être la mauvaise ligne** (faubourg Bonnefoy :
  ligne principale de Matabiau au lieu de la ligne de Lexos) : prendre le point de la voie ferrée
  le plus proche du bout de la voie suivante.
- **Une route qui touche une voisine puis revient** (Nîmes, route de Saint-Gilles : limite de
  Caissargues, puis de nouveau dans Nîmes 2,4 km plus loin) : `("voie", …)` a tracé 13 km. Finir au
  point où la voie touche la limite.
- **Les numéros de départementales changent entre deux décrets** (Nîmes : CD 40 en 1973, CD 540
  en 1982 pour la même route ; « CD 133 » introuvable) : la topologie identifie la route, pas le
  numéro.
- **Un régime dont la loi n'est pas lue peut se déduire du suivant** (Nîmes 1880 : les communes
  rurales du 1er passent à I et V en 1973, celles du 3e à III et IV ; la limite 1/3 est donc
  I/IV + IV/V) : l'écrire sous la source `main`, note commençant par « HYPOTHESE ».

- **Un décret qui ÉNUMÈRE des voies par canton au lieu de décrire une limite** (Ajaccio 1973,
  23 octobre 2026) : la ligne passe entre les voies des deux listes ; numéros et côtés de rue se
  réduisent à l'axe, chaque rue coupée se chiffre. Le décret suivant (1982) et celui de 2014
  donnent de vraies limites, qui reprennent souvent l'ancienne : les lire d'abord.
- **« Passant au Sud des lieux-dits A, B, C » dans le maquis** : seuls des points à une centaine
  de mètres des toponymes BD TOPO (`zone_d_habitation`, `detail_orographique` : Punta, Bocca, Col)
  sont possibles ; chiffrer l'écart avec un tracé par les lieux-dits eux-mêmes (70 ha à Ajaccio).
- **Un nom de résidence peut couvrir des immeubles aux noms trompeurs** : les immeubles
  « Napoléon, Lucien, Laetitia » de la BD TOPO sont aux Jardins de l'Empereur, pas dans la
  « résidence Napoléon » du décret. Le contour `zone_d_habitation` de la résidence sert de limite.
- **Le routeur PostGIS par voie imposée** (`cartes/sorties/decoupe_ajaccio/route.py`) fait des
  épingles quand un point de passage n'est pas un nœud : le remplacer par le nœud le plus proche
  (sauf aux bouts et aux droites), puis `desboucle.py`.
- **Une voie ferrée déposée peut survivre comme route sans nom** (Quimper, ligne de Pont-l'Abbé) :
  absente de `<insee>_fer`, son emprise porte des tronçons routiers sans nom ; les repérer sur
  l'ortho 1950-1965, les ajouter comme pseudo-voie dans une copie de `<insee>_voies.geojson`
  (`VOIRIE` redéfini) et tracer par `("voie", …)`.
- **Une route qui franchit une anse où le contour ANR se pince** (Quimper, D34) détache un morceau :
  une deuxième ancre pour la même fraction.
- **`--morceaux N` avec des ancres partielles** (Brest 1973 et 1985 : quatre cantons sur huit ont
  une unité) : `--vides-admis` = nombre de morceaux sans ancre, sinon NON CONFORME.
- **Légifrance par le navigateur intégré** : WebFetch n'en rend qu'un résumé ; `navigate` puis
  `get_page_text` rend le décret entier (Brest, décret 91-211).
- **Un décret qui borne par renvoi** (« limites des cantons de Brest-II et Brest-V ») : les limites
  non redécrites restent en vigueur ; les reprendre sous l'identifiant de chaque régime.
- **Agents en parallèle : un sous-dossier du scratchpad par ville** ; le scratchpad est partagé.
- **WFS `batiment` filtré en CQL** : `BBOX(geometrie, …, 'EPSG:2154')`, cinquième argument compris.
- **Le décret de 2014 donne des coordonnées Lambert 93** (Bastia, 2014-255 : lignes et segments
  chiffrés) que la transcription Wikipédia saute : lire Légifrance avant de router un
  « prolongement » ou une « ligne de N mètres ».
- **Un décret-liste (1973) se trace par un Voronoi des voies listées** (Bastia : densifier à 8 m,
  contours des lieux-dits, `cartes/sorties/decoupe_bastia/construit_1973.sh`), puis contrôle de
  population ; les contraintes d'un autre texte (2014, 1982) s'appliquent après.
- **Un décret qui divise un canton borne l'ancien** : le périmètre du VI de 1982 donne la limite
  nord du V de 1973 (Bastia).
- **Les parcelles citées en 1982 ne survivent pas au cadastre renuméroté** : des numéros
  identiques dans une section moderne trompent (Bastia, BC 172 / 173, 27 m²).
- **archive.org plein texte trouve des cantons urbains dans des revues médicales et des thèses
  d'hygiène** (Bastia 1873, 1921) quand aucun texte de limite n'existe.
- **`$(echo $VAR)` coupe les `POINT(x y)`** dans les arguments : écrire les ancres en toutes lettres.

- **Le routeur en couches dépasse le départ d'une ligne fermée** (Béziers-I, 24 octobre 2026) :
  il s'accroche à un autre tronçon et revient. Couper l'anneau au premier retour à moins de 0,5 m ;
  ne pas passer `route.nettoie()` sur une ligne fermée, il la réduit à un point. Une étape
  facultative (place citée en 2014 seulement) crée un aller-retour : la retirer de la liste.
- **Une voie communale coupée par une autoroute postérieure** (VC 12 et A75 à Béziers) : le plus
  court chemin fait 2,3 km de détour ; mettre une droite entre les deux bouts et chiffrer.
- **« Ligne droite dans le prolongement » (2014) qui ne rencontre pas le bord** : l'axe du dernier
  tronçon peut partir à l'opposé ; droite au plus court, dite dans la note.
- **Un ancien nom de 1973 survit dans `alias_gauche`** (Rennes, « AV DE L ILE DE FRANCE » =
  avenue Tillon) alors qu'aucune voie BAN ne le porte.
- **« Limites des terrains de X et Y »** quand deux emprises se touchent (CHR et facultés à
  Rennes) : prendre les morceaux du contour de l'une à moins de 8 m de l'autre
  (`zone_d_activite_ou_d_interet`), bout à bout.
- **Une rocade à deux chaussées** (N136) : router par le numéro fait des détours et rend une ligne
  non simple ; prendre une seule chaussée (`ST_LineMerge(ST_Union(ST_SnapToGrid(...)))`).
- **Un décret de renommage (Rennes 1985) n'est qu'un tableau de noms, et un décret « portant
  création de cantons » (91-213, 91-214) peut ne détacher que des communes rurales** : le lire
  avant de supposer un nouveau découpage urbain ; les lignes de 1982 ou 1985 tiennent alors
  jusqu'en 2015 en une seule passe.
- **Une voie rapide en tranchée** (Montpellier, avenue de la Liberté sous la Tour-Buffel) : la règle
  anti-boucle de `nettoie()` efface une épingle sans le dire dans le rapport ; seule l'image le
  montre. Prendre l'axe BAN à la main entre les deux carrefours.
- **Quand les IRIS suivent un régime presque partout** (Montpellier 1985 : 92 à 100 %), un accord
  très bas sur une ligne (1,4 % pour I/VI) désigne une divergence texte / INSEE à chiffrer.
- **`from outils import *` n'importe pas les noms en `_`** (`_pt`) : les importer à part.

- **Une liste qui commence par des voies de limite communale** (Mérignac, 25 octobre 2026 : avenues
  d'Arès et de Mérignac le long de Bordeaux) : les tronçons dont `insee_commune_gauche` et
  `_droite` diffèrent le montrent ; la ligne commence à la première voie intérieure.
- **Une voie suivie en partie seulement** (« avenue de la Marne, rue Alfred-de-Vigny… », la Marne
  jusqu'à Vigny) laisse une poche (47 ha à Mérignac) : la laisser du côté que la lettre lui donne,
  chiffrer la lecture « d'un trait ».
- **Un texte qui finit en pleine ville devant un aéroport** (Mérignac, avenue Kennedy à 2 km du
  bord) : prolongement au plus court par les routes vers le point triple, écrit comme hypothèse,
  avec les lectures IRIS et axe chiffrées ; la population ne tranche pas des hectares vides.
- **La dernière voie coupée par une rocade postérieure** (Pessac, chemin du Pontet) : l'orthophoto
  1950-1965 montre l'ancien chemin ; suivre ses restes (allée Newton, antenne « Voie Romaine »),
  franchir la rocade en droite, remplacer la queue en SQL. Le plus court chemin prenait l'avenue
  parallèle (2,56 ha).
- **WMS `ORTHOPHOTOS.1980-1995` peut rendre une image toute blanche sans erreur** (Pessac) :
  regarder l'image avant de conclure qu'une voie n'existait pas.
- **Un canton créé en 1973 dont les communes restent sous le code du canton mère** (Villenave-
  d'Ornon sous Pessac, 1973-1982, et Pessac sans canton) : lire l'article « l'ancien canton… est
  composé de… » du décret, et consigner.
- **Une enclave bornée par une route que le texte donne à l'autre canton** (Auch 1973, route du
  Garros) : réduite à l'axe, l'enclave touche le reste de son canton ; pas de boucle fermée, la
  limite en fait le tour. La population la confirme (943 logements).
- **Bulletin des lois de 1817** (7e série, t. 5) sur archive.org, `bub_gb_9CUUAAAAYAAJ` (p. 408 =
  n449) ; l'OCR se trompe de numéro d'acte (3509 pour 3309) et de nom : citer l'image.
- **Une commune qui en entoure une autre** (Auch autour de Duran) : le contrôle « chaque morceau
  touche surtout son canton » ne vaut plus ; le dire dans la note.
- **Les IRIS d'une ville COG se lisent au WFS** et peuvent être presque emboîtés dans les cantons
  (Mérignac 23 sur 27, Pessac 18 sur 22) : contrôle utile même sans `iris_ville`.
