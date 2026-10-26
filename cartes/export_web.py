#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
export_web.py — exporte la base `histgis` vers les fichiers que consomme
`cartes/web/index.html` (curseur d'années 1815-2012 + sélecteur de département).

    python3 cartes/export_web.py                  # tous les départements
    python3 cartes/export_web.py 01 13 69         # une sélection
    python3 cartes/export_web.py --grille 50      # quantification plus grossière
    python3 cartes/export_web.py --jobs 8         # huit départements de front
    python3 cartes/export_web.py --sans-anr       # trame GEOFLA 2011, comme avant
    python3 cartes/export_web.py --outremer       # les cinq DOM, tables om_*

L'OUTRE-MER S'AJOUTE, IL NE REMPLACE PAS. `--outremer` écrit `dep/971` à
`dep/976` dans le même dossier et laisse la métropole intacte — c'est un export
partiel par nature, y compris quand on ne lui donne aucun département. Il se
joue donc APRÈS l'export métropolitain, dans cet ordre :

    python3 cartes/export_web.py --partition --jobs 6
    python3 cartes/export_web.py --outremer

Le dossier porte alors deux trames, ce qui est un fait et non un accident :
`84` ne traite que la métropole et ANR ne couvre pas l'outre-mer. L'index
racine l'annonce (`trame: mixte`, détail dans `trames`), et chaque index de
département porte la sienne, que la page lit en priorité.

Sortie : `cartes/web/donnees/`, puis
    python3 cartes/web/servir.py
et la page s'ouvre. Un serveur est nécessaire : `fetch()` sur `file://` est
refusé par les navigateurs.

Ce que le script exporte, et pourquoi c'est découpé ainsi
--------------------------------------------------------
  donnees/dep/NN/communes.json   géométrie des atomes, VERSIONNÉE dans le temps
  donnees/dep/NN/c_<sig>.json    une configuration cantonale : contours dissous
                                 + table atome → canton
  donnees/dep/NN/x_<sig>.json    idem pour les circonscriptions
  donnees/dep/NN/index.json      année → signature de configuration
  donnees/index.json             départements, noms d'époque, années servies

Une « configuration » est un état distinct de ce qui se dessine. Entre 1870 et
1940 un département en compte quelques dizaines, pas soixante-et-onze :
réexporter la même carte 71 fois pèserait cent fois plus pour la même
information.

LA GÉOMÉTRIE A UNE ÉPAISSEUR TEMPORELLE — CE QUI A CHANGÉ LE 1er SEPTEMBRE 2026
------------------------------------------------------------------------------
Ce fichier a longtemps porté en tête l'affirmation suivante : « la géométrie
d'un atome ne change jamais ; ce qui change d'une année à l'autre, c'est le
rattachement ». C'était vrai de `atom_geom`, qui est la trame GEOFLA 2011 —
un instantané sans épaisseur, projeté sur deux siècles.

`atom_geom_anr` (voir `sql/82_anr_geom.sql`) l'a rendue fausse. ANR-COMMUNES
reconstruit le polygone de chaque commune année par année : une commune qui
perd un hameau en 1875 a deux polygones successifs, et c'est l'essentiel de ce
que la source apporte. Le script tire donc désormais, à chaque date,
`coalesce(atom_geom_anr @ date, atom_geom)` — exactement ce que fait
`snapshot_geom_anr()` en base.

Trois conséquences, dont aucune n'était optionnelle :

1. **`communes.json` ne peut plus porter un polygone par atome.** Chaque atome
   porte une LISTE de versions, `v: [{a, k, c, g, r}, …]`, où `a` est la
   première année où la version vaut. La page choisit au curseur.

2. **La signature d'une configuration ne peut plus être celle de la seule
   composition.** Deux années au `membership` identique mais aux polygones
   différents partageraient sinon le même `c_<sig>.json` — donc un contour
   cantonal dissous emprunté à une AUTRE forme, sans que rien ne le signale.
   C'est le défaut que ce dépôt nomme partout ailleurs : *une carte qui montre
   la mauvaise année sans le dire est pire qu'une carte absente.* La signature
   couvre donc la composition ET les `poly_id` en vigueur.

3. **Les années candidates ne peuvent plus se déduire des seules bornes de
   `membership`.** Une édition de polygone qui tombe une année sans mouvement
   administratif serait invisible : la composition n'a pas bougé, donc l'année
   n'était pas échantillonnée, donc le changement de forme n'existait pas.
   `annees_candidates()` lit aussi les bornes de `atom_geom_anr`.

Le prix est en octets sur le disque, pas en octets par requête : les fichiers
restent adressés par leur contenu, et le navigateur n'en télécharge toujours
qu'un par année affichée.

LE REPLI (R5), ET POURQUOI IL EST ÉCRIT DANS LES FICHIERS
---------------------------------------------------------
ANR ne pourvoit pas tout. Trois familles d'atomes retombent sur `atom_geom` :

  * les **333 fractions** — ANR livre le polygone de la commune mère entière et
    ne sait pas le découper entre deux cantons. `82` les exclut à l'écriture ;
  * les **486 atomes vivants à 1870 sans polygone ANR**, pour l'essentiel le
    report arrière de `11_scission.sql` (voir `83_anr_ecart_couverture.sql`) ;
  * les **trous de chronologie d'ANR** — 532 `id_com`, 11 113 années-communes,
    un polygone avant, un après, rien entre. Vingt communes des Ardennes
    partagent la signature `1790-1828 | 1871-2020`. Ces trous-là ne se voient
    qu'en interrogeant une date à l'INTÉRIEUR du jeu, jamais à ses bornes :
    c'est pourquoi la construction des versions ci-dessous comble explicitement
    les intervalles au lieu de supposer qu'une source datée est continue.

Une carte hybride qui ne dit pas où elle est hybride est une carte qui ment par
omission. Chaque version porte donc `r: 1` quand elle vient du repli, chaque
unité porte `n_anr` et `n_repli`, et la page les affiche.

`--partition` : LA TRAME NETTOYÉE (`sql/84_carte_partition.sql`)
----------------------------------------------------------------
Le repli a un coût que le paragraphe précédent nommait sans le chiffrer : là où
un atome retombe sur GEOFLA pendant que ses voisins viennent d'ANR, les bords ne
coïncident plus. Mesuré à 1870 sur cet export même, entre communes ordinaires :
**4 542,8 km² de recouvrement sur la couture ANR × repli**, contre 1,0 km² entre
deux polygones ANR. C'est le double trait qu'on voit entre Villieu-Loyes-Mollon
et Meximieux, et la superposition franche des 393 filles reportées en arrière
par `11` sur leur mère intacte.

`84` rend une trame sans trou et sans superposition : chaque atome que la base
fait vivre et qu'ANR ne pourvoit pas reçoit `voisin(D) − voisin(Y′)` — la
différence des deux polygones du voisin qui s'en sépare l'année de sa prochaine
apparition chez ANR — puis toutes les frontières sont nouées et polygonisées,
et chaque face n'a qu'un propriétaire.

CE DRAPEAU EST OPTIONNEL, ET LE RESTERA JUSQU'À CE QUE `84` AIT TOURNÉ. Sans
lui, rien ne change : l'export tire `coalesce(ANR, atom_geom)` comme avant. Les
deux trames peuvent donc être exportées dans deux dossiers et comparées à l'œil
avant qu'on décide laquelle sert la page. *Une trame corrigée qu'on ne peut pas
comparer à celle qu'elle remplace n'est pas une correction, c'est un pari.*

CE QUE `--partition` COÛTE. La partition est une opération DATÉE : elle ne se
lit pas sur un intervalle comme `atom_geom_anr`. Le script la calcule donc une
fois par « année géométrique » — les années où le jeu de polygones dessinés peut
changer, c'est-à-dire les bornes de `atom_geom_anr` et celles de la VIE des
atomes (pas de leurs rattachements : un atome qui change de canton ne change pas
de forme). Mesuré sur les vingt premiers départements : **24,5 années
géométriques en moyenne**, contre une centaine d'années candidates. C'est ce
rapport de un à quatre qui rend le drapeau utilisable.

Les fractions et les villes partagées ne changent pas de statut : `84` les
traite comme un propriétaire unique et les rend dupliquées par canton, drapeau
`partagee` compris. La page continue de les hachurer.

Les années sans source
----------------------
Le script n'invente rien. Une année sans `membership` sort avec la signature
vide : la page affichera le bandeau « aucune source », et un contour
départemental de référence emprunté à l'année datée la plus proche — étiqueté
comme tel. C'est le parti pris du projet : l'absence de la ligne est le
résultat (`ETAT.md`, « le trou se voit dans les données »).

La quantification, et pourquoi ce n'est pas une simplification
--------------------------------------------------------------
Les coordonnées sont accrochées à une grille métrique en Lambert-93 avant
reprojection (`ST_SnapToGrid`, 25 m par défaut). Ce n'est pas
`ST_SimplifyPreserveTopology` : deux communes voisines qui partageaient un
sommet le partagent encore après accrochage, alors qu'une simplification
appliquée polygone par polygone les écarte et ouvre des lisières. Les contours
dissous subissent exactement les mêmes opérations dans le même ordre, donc les
limites cantonales coïncident avec les limites communales au pixel près.

Ce que les cartes ne montreront pas fidèlement
----------------------------------------------
Les communes partagées entre plusieurs cantons — Marseille, Lyon, Paris,
Bourg-en-Bresse — portent en base le polygone de la commune entière
(`atom_geom.partagee`). Leurs cantons se recouvrent donc exactement. Le drapeau
est exporté ; la page les hachure et les compte en pied de carte plutôt que de
laisser croire à un découpage qui n'existe pas. ANR ne lève PAS cette limite :
il livre la mère entière, lui aussi.

Parallélisme
------------
Un processus par département, chacun avec sa propre connexion (`--jobs`). Les
départements sont indépendants — ils lisent une base en lecture seule et
écrivent chacun dans son dossier — et le gros du coût est côté PostgreSQL
(`ST_UnaryUnion` sur quelques centaines de multipolygones par configuration),
donc plusieurs backends travaillent vraiment de front. Le nettoyage préalable
et l'index racine restent séquentiels dans le parent : le premier efface des
dossiers que les workers vont écrire, le second agrège ce qu'ils rendent.

Dépendances : psycopg2.
    pip install psycopg2-binary --break-system-packages
"""

import argparse
import hashlib
import json
import multiprocessing as mp
import os
import shutil
import sys
import time
from pathlib import Path

import psycopg2

# La libpq livrée par conda cherche la socket Unix dans /tmp, alors que les
# paquets Debian et Ubuntu la posent dans /var/run/postgresql. On essaie les
# emplacements dans l'ordre, TCP en dernier recours.
DSN_CANDIDATS = [
    "dbname=histgis host=/var/run/postgresql",
    "dbname=histgis",
    "dbname=histgis host=localhost",
]

RACINE = Path(__file__).resolve().parent
SORTIE = RACINE / "web" / "donnees"

AN_MIN, AN_MAX = 1815, 2012

# Date de référence dans l'année : **1er décembre**, et non 1er juin.
#
# Le curseur de la carte est annuel ; il faut donc échantillonner chaque année
# à une date fixe. Le choix n'est neutre que si aucune borne ne tombe entre les
# deux dates candidates — et deux y tombent, toutes deux électorales :
#
#   1986-11-24  promulgation de la loi créant le découpage de 1986 ;
#   2012-06-10  premier tour du renouvellement à partir duquel s'applique
#               celui de 2009.
#
# Au 1er juin, l'année 2012 tombait donc encore sous le découpage de 1986, et
# **le découpage de 2009 n'apparaissait sur aucune année de la carte** — mesuré
# le 20 août 2026 : 0 rattachement au 1er juin 2012, 37 257 au 1er décembre.
# L'année 1986, symétriquement, était vide de circonscriptions alors que la loi
# est de novembre.
#
# Le 1er décembre corrige les deux. Il est sans effet sur 1870-1940, dont
# toutes les bornes tombent au 1er janvier par la convention annuelle de
# TRF-GIS, et sur la couche cantonale moderne, qui démarre au 1er janvier 1999.
MOIS_JOUR = (12, 1)

# ---------------------------------------------------------------------------
# Noms de départements, par période. Un code ne suffit pas : `78` est
# Seine-et-Oise jusqu'en 1968 puis Yvelines, `75` est la Seine puis Paris, et
# `20` est la Corse jusqu'à sa partition. Afficher « Yvelines » sur une carte
# de 1885 serait un anachronisme silencieux — le genre que la page ne peut pas
# signaler elle-même.
# ---------------------------------------------------------------------------
NOMS_DEP = {
    "01": "Ain", "02": "Aisne", "03": "Allier", "04": [(AN_MIN, 1969, "Basses-Alpes"),
    (1970, AN_MAX, "Alpes-de-Haute-Provence")], "05": "Hautes-Alpes",
    "06": "Alpes-Maritimes", "07": [(AN_MIN, 1791, "Ardèche"), (1792, AN_MAX, "Ardèche")],
    "08": "Ardennes", "09": "Ariège", "10": "Aube", "11": "Aude", "12": "Aveyron",
    "13": "Bouches-du-Rhône", "14": "Calvados", "15": "Cantal", "16": "Charente",
    "17": [(AN_MIN, 1940, "Charente-Inférieure"), (1941, AN_MAX, "Charente-Maritime")],
    "18": "Cher", "19": "Corrèze", "20": "Corse", "2A": "Corse-du-Sud",
    "2B": "Haute-Corse", "21": "Côte-d'Or",
    "22": [(AN_MIN, 1989, "Côtes-du-Nord"), (1990, AN_MAX, "Côtes-d'Armor")],
    "23": "Creuse", "24": "Dordogne", "25": "Doubs", "26": "Drôme", "27": "Eure",
    "28": "Eure-et-Loir", "29": [(AN_MIN, 1989, "Finistère"), (1990, AN_MAX, "Finistère")],
    "30": "Gard", "31": "Haute-Garonne", "32": "Gers", "33": "Gironde",
    "34": "Hérault", "35": "Ille-et-Vilaine", "36": "Indre", "37": "Indre-et-Loire",
    "38": "Isère", "39": "Jura", "40": [(AN_MIN, 1956, "Landes"), (1957, AN_MAX, "Landes")],
    "41": "Loir-et-Cher", "42": "Loire", "43": "Haute-Loire",
    "44": [(AN_MIN, 1956, "Loire-Inférieure"), (1957, AN_MAX, "Loire-Atlantique")],
    "45": "Loiret", "46": "Lot", "47": "Lot-et-Garonne", "48": "Lozère",
    "49": [(AN_MIN, 1955, "Maine-et-Loire"), (1956, AN_MAX, "Maine-et-Loire")],
    "50": "Manche", "51": "Marne", "52": "Haute-Marne", "53": "Mayenne",
    # La Meurthe d'avant 1871 vit sous le code 54 depuis `39` et `92`, et
    # `106` (4 octobre 2026) y pose ses circonscriptions de 1815 à 1870 :
    # sans cette plage, la planche de 1830 s'intitulait Meurthe-et-Moselle.
    "54": [(AN_MIN, 1870, "Meurthe"), (1871, AN_MAX, "Meurthe-et-Moselle")],
    "55": "Meuse", "56": "Morbihan", "57": "Moselle",
    "58": "Nièvre", "59": "Nord", "60": "Oise", "61": "Orne",
    "62": "Pas-de-Calais", "63": "Puy-de-Dôme", "64": [(AN_MIN, 1968, "Basses-Pyrénées"),
    (1969, AN_MAX, "Pyrénées-Atlantiques")], "65": "Hautes-Pyrénées",
    "66": "Pyrénées-Orientales", "67": "Bas-Rhin", "68": "Haut-Rhin", "69": "Rhône",
    "70": "Haute-Saône", "71": "Saône-et-Loire", "72": "Sarthe", "73": "Savoie",
    "74": "Haute-Savoie", "75": [(AN_MIN, 1967, "Seine"), (1968, AN_MAX, "Paris")],
    "76": [(AN_MIN, 1954, "Seine-Inférieure"), (1955, AN_MAX, "Seine-Maritime")],
    "77": "Seine-et-Marne",
    "78": [(AN_MIN, 1967, "Seine-et-Oise"), (1968, AN_MAX, "Yvelines")],
    "79": "Deux-Sèvres", "80": "Somme", "81": "Tarn", "82": "Tarn-et-Garonne",
    "83": "Var", "84": "Vaucluse", "85": "Vendée", "86": "Vienne",
    "87": "Haute-Vienne", "88": "Vosges", "89": "Yonne",
    "90": "Territoire de Belfort", "91": "Essonne", "92": "Hauts-de-Seine",
    "93": "Seine-Saint-Denis", "94": "Val-de-Marne", "95": "Val-d'Oise",
    # `99` n'est pas un code d'usage : c'est la Meurthe d'avant 1871, que
    # TRF-GIS code ainsi faute de code INSEE — le département a disparu au
    # partage. Documenté dans METHODE.md, § « Curiosités documentées ».
    #
    # CETTE ENTRÉE SURVIT À `86_meurthe_circo.sql`, QUI LA REND SANS OBJET, ET
    # C'EST VOULU. `39` puis `86` rendent le numéro 54 aux 29 cantons et à la
    # circonscription de la Meurthe : après eux, `SELECT DISTINCT dep FROM unit`
    # ne rend plus `99`, et cette ligne ne sert jamais. Mais une base
    # reconstruite par `rebuild.sh` sans que la chaîne soit allée jusqu'au bout
    # le fait réapparaître — c'est exactement ce qui s'est produit entre le
    # 15 et le 30 août 2026. La retirer ferait alors sortir un département sous
    # le libellé « 99 » sans que rien ne dise ce qu'il est. *Un libellé de
    # secours ne coûte rien tant qu'il est juste ; c'est le supprimer parce
    # qu'on croit le cas impossible qui coûte.*
    "99": "Meurthe (avant le partage de 1871)",

    # --- outre-mer (`--outremer`, tables `om_*`) ---------------------------
    # Codes INSEE à trois caractères : c'est la raison pour laquelle
    # `om_unit.dep` est `char(3)` et ne peut pas entrer dans `unit.dep`.
    # Les noms ne varient pas sur la période servie (1946-2012), d'où des
    # chaînes et non des plages. Ce qui varie, c'est la DATE à partir de
    # laquelle chacun est un département : c'est `BORNES_MOTIF` qui la porte,
    # parce que c'est un fait de calendrier et non un fait de nom.
    #
    # Pas de `975` : Saint-Pierre-et-Miquelon n'est pas dans les cinq lots que
    # `40_outremer.sql` charge. L'Algérie est bloquée par la licence de ses
    # sources (`ETAT.md`, § 2.7) ; le Pacifique ne l'est plus depuis `135`.
    "971": "Guadeloupe", "972": "Martinique", "973": "Guyane",
    "974": "La Réunion", "976": "Mayotte",
    # Les Établissements français de l'Océanie prennent le nom de Polynésie
    # française par le décret du 22 juillet 1957 — avant la planche de
    # décembre 1957, donc 1957 est déjà polynésienne.
    "987": [(AN_MIN, 1956, "Établissements français de l'Océanie"),
            (1957, AN_MAX, "Polynésie française")],
    "988": "Nouvelle-Calédonie",
}


# ---------------------------------------------------------------------------
# Périodes où un département n'est pas français, n'existe pas encore, ou a
# cessé d'exister. Sans cette table, un trou de couverture et une absence de
# territoire se ressemblent : la page dirait « aucune source » pour la Moselle
# en 1890, alors que la bonne réponse est qu'il n'y a pas de Moselle française
# en 1890. Les bornes du curseur, elles, sont déduites des données ; cette table
# ne sert qu'à motiver les trous, jamais à en fabriquer.
#
# Chaque entrée est une affirmation historique datée, à contredire si elle est
# fausse — pas une commodité d'affichage.
# ---------------------------------------------------------------------------
ABSENCES = {
    # Ajoutés le 4 octobre 2026, avec les découpages 1815-1870 (`106`).
    "73": [(1815, 1859, "savoyarde — États de la maison de Savoie jusqu'au "
                        "traité de Turin (24 mars 1860)")],
    "74": [(1815, 1859, "savoyarde — États de la maison de Savoie jusqu'au "
                        "traité de Turin (24 mars 1860)")],
    "57": [(1871, 1918, "annexée à l'Empire allemand — traité de Francfort "
                        "(10 mai 1871) à l'armistice du 11 novembre 1918")],
    "67": [(1871, 1918, "annexé à l'Empire allemand — traité de Francfort "
                        "(10 mai 1871) à l'armistice du 11 novembre 1918")],
    "68": [(1871, 1918, "annexé à l'Empire allemand — traité de Francfort "
                        "(10 mai 1871) à l'armistice du 11 novembre 1918. "
                        "Le Territoire de Belfort, resté français, en est "
                        "détaché")],
}

# ---------------------------------------------------------------------------
# Périodes où la FRANCE ENTIÈRE n'a pas de circonscriptions législatives.
#
# `ABSENCES` ci-dessus répond « pas de département à cette date ». Ici le
# département existe : c'est l'objet électoral qui n'existe pas. La distinction
# n'est pas rhétorique — sans elle, la page dit « aucune source » là où la
# bonne réponse est « il n'y a pas eu d'élection », et un lecteur en conclut
# que la base est lacunaire.
#
# Ne pas confondre non plus avec le trou 1941-1998 de la couche CANTONALE, qui
# est une vraie lacune de source (`histgis-trou-cantonal`). Celui-ci est une
# absence d'objet, et il est plus court.
#
# Comme `ABSENCES`, chaque entrée est une affirmation historique datée, à
# contredire si elle est fausse.
# ---------------------------------------------------------------------------
ABSENCES_CIRCO = [
    (1941, 1945,
     "la Troisième République prend fin le 10 juillet 1940 ; Vichy n'a pas "
     "d'assemblée élue. Le scrutin suivant est celui du 21 octobre 1945, à la "
     "représentation proportionnelle. Il n'existe aucune circonscription "
     "législative pendant cet intervalle"),
]

# Motifs de début et de fin d'existence, affichés en bout de curseur.
BORNES_MOTIF = {
    "99": (None, "la Meurthe disparaît au partage de 1871 : l'essentiel forme "
                 "la Meurthe-et-Moselle, le reste est annexé avec la Moselle"),
    "20": (None, "la Corse est partagée en Corse-du-Sud et Haute-Corse "
                 "au 1er janvier 1976"),
    "2A": ("partition de la Corse, 1er janvier 1976", None),
    "2B": ("partition de la Corse, 1er janvier 1976", None),
    "91": ("créé par la réorganisation de la région parisienne — loi du "
           "10 juillet 1964, effet au 1er janvier 1968", None),
    "92": ("réorganisation de la région parisienne, 1er janvier 1968", None),
    "93": ("réorganisation de la région parisienne, 1er janvier 1968", None),
    "94": ("réorganisation de la région parisienne, 1er janvier 1968", None),
    "95": ("réorganisation de la région parisienne, 1er janvier 1968", None),
    "78": (None, "la Seine-et-Oise est démembrée au 1er janvier 1968 ; le code "
                 "78 désigne ensuite les Yvelines"),
    # Outre-mer. Comme partout dans cette table, chaque entrée est une
    # affirmation historique datée, à contredire si elle est fausse.
    "971": ("département par la loi de départementalisation du 19 mars 1946 — "
            "colonie auparavant, avec des députés mais pas de cantons au sens "
            "métropolitain", None),
    "972": ("département par la loi du 19 mars 1946", None),
    "973": ("département par la loi du 19 mars 1946", None),
    "974": ("département par la loi du 19 mars 1946", None),
    "976": ("département depuis le 31 mars 2011 seulement — collectivité "
            "territoriale auparavant", None),
    # Ni l'un ni l'autre n'est un département : ce sont des territoires (puis
    # une collectivité, et un statut propre pour la Nouvelle-Calédonie), sans
    # cantons. La borne est le premier député, pas un statut.
    "987": ("premier député élu le 21 octobre 1945, à la première "
            "Constituante — pas de siège auparavant. Territoire sans cantons",
            None),
    "988": ("premier député élu le 21 octobre 1945, à la première "
            "Constituante — pas de siège auparavant. Territoire sans cantons",
            None),
}

# Première année où chaque territoire d'outre-mer est un DÉPARTEMENT.
#
# Ce n'est pas une commodité d'affichage, et c'est pour cela que la table est
# ici plutôt que dans la page : elle décide de trois choses à la fois — l'année
# à partir de laquelle la forme d'une commune est écrite, l'année sous laquelle
# est rangé le contour de référence, et la borne basse du curseur pour un
# département dont la base ne sert aucune composition.
#
# **Sans elle, Mayotte serait dessinée en 1815.** Ses communes n'ont aucun
# rattachement (voir `exporte_departement_om`), donc aucune borne, donc rien
# ne bornerait le curseur : la page retomberait sur `AN_MIN`, et l'on verrait
# les dix-sept communes de Mayotte sur une planche de 1815 — un anachronisme de
# deux siècles, produit par le silence d'une table et non par une affirmation.
# *Une donnée qu'aucune borne ne contraint prend la borne de son conteneur, et
# celle-là n'a aucune raison d'être juste.*
AN_DEBUT_DOM = {
    # Loi de départementalisation du 19 mars 1946. Avant, ce sont des colonies
    # avec des députés mais pas de cantons au sens métropolitain — `40` s'en
    # explique et refuse de poser 1870-1946.
    "971": 1946, "972": 1946, "973": 1946, "974": 1946,
    # Mayotte devient département le 31 mars 2011 : collectivité territoriale
    # auparavant, et c'est aussi pourquoi elle est absente du fichier du
    # ministère de 1986 et de 2012 qui pose les rattachements.
    "976": 2011,
    # Le Pacifique n'est pas départementalisé : sa borne est celle de son
    # premier député, le 21 octobre 1945 (`135`). La planche de décembre 1945
    # le montre donc déjà.
    "987": 1945, "988": 1945,
}
AN_DOM = 1946        # repli, pour un code d'outre-mer que la table ignore


def nom_dep(code, annee):
    """Nom porté par un département une année donnée."""
    v = NOMS_DEP.get(code)
    if v is None:
        return code
    if isinstance(v, str):
        return v
    for a, b, nom in v:
        if a <= annee <= b:
            return nom
    return v[-1][2]


# ---------------------------------------------------------------------------
# Connexion
# ---------------------------------------------------------------------------
def connecte(dsn_force=None, readonly=True, role=None):
    """Ouvre la connexion. LECTURE SEULE par défaut, et ce défaut a un sens.

    `--partition` doit l'abandonner, et il faut savoir pourquoi. Une
    transaction `READ ONLY` de PostgreSQL interdit **toutes** les commandes
    CREATE, ALTER et DROP — y compris sur une table TEMPORAIRE. Les écritures
    dans une table temporaire déjà créée, elles, sont permises : c'est le DDL
    qui bloque, pas le contenu. Or `carte_partition_atome` crée et détruit
    quatre tables temporaires par département ; elle ne peut pas s'exécuter
    sous ce régime, et aucune réécriture de `84` n'y changerait rien tant que le
    comblement a besoin d'une table de travail.

    Ce que l'export perd est donc réel : la garantie ne vient plus du moteur
    mais de la lecture du code. `84` ne touche ni `atom_geom`, ni
    `atom_geom_anr`, ni `membership` — c'est vrai, c'est vérifiable, et ce
    n'est plus imposé.

    LA VRAIE RÉPONSE EST UN RÔLE, PAS UN MODE. Un rôle qui n'a que `SELECT` sur
    le schéma et `TEMPORARY` sur la base rend la garantie au moteur sans
    interdire les tables de travail :

        CREATE ROLE histgis_carte LOGIN;
        GRANT CONNECT, TEMPORARY ON DATABASE histgis TO histgis_carte;
        GRANT USAGE ON SCHEMA histgis TO histgis_carte;
        GRANT SELECT ON ALL TABLES IN SCHEMA histgis TO histgis_carte;

    ON PREND LE RÔLE, ON NE S'Y CONNECTE PAS. Se connecter directement en
    `histgis_carte` bute sur l'authentification `peer` de la socket Unix, qui
    exige que le nom du compte système soit celui du rôle — et y échapper
    demanderait un mot de passe en clair ou une retouche de `pg_hba.conf`.
    `SET ROLE` évite les deux : on se connecte normalement, puis on descend
    dans le rôle restreint. Il suffit d'en être membre :

        GRANT histgis_carte TO adrien;

    puis `--role histgis_carte`. Les droits appliqués sont alors ceux du rôle
    pris, pas ceux du propriétaire — une écriture est refusée par le moteur.

    C'est un garde-fou, pas une prison : `RESET ROLE` défait la chose en un mot,
    et rien n'empêcherait un code malveillant de l'écrire. Contre l'accident,
    qui est le risque réel ici, il suffit.
    """
    dernier = None
    for dsn in ([dsn_force] if dsn_force else DSN_CANDIDATS):
        try:
            cx = psycopg2.connect(dsn)
            cx.set_session(readonly=readonly, autocommit=True)
            with cx.cursor() as c:
                if role:
                    # AVANT le search_path : si le rôle n'existe pas ou qu'on
                    # n'en est pas membre, mieux vaut échouer ici, sur une
                    # erreur qui nomme le rôle, que trois requêtes plus loin.
                    c.execute("SET ROLE %s" % psycopg2.extensions.quote_ident(
                        role, cx))
                c.execute("SET search_path TO histgis, public")
            return cx
        except psycopg2.Error as e:
            dernier = e
    print("Connexion à la base `histgis` impossible.", file=sys.stderr)
    print(f"Dernière erreur : {dernier}", file=sys.stderr)
    sys.exit(1)


def date_ref(annee):
    return f"{annee:04d}-{MOIS_JOUR[0]:02d}-{MOIS_JOUR[1]:02d}"


# ---------------------------------------------------------------------------
# Repérage des configurations
#
# On ne teste pas les 198 années : ce qui se dessine au 1er décembre de l'année
# Y ne peut différer de Y-1 que si une borne tombe dans l'intervalle. On calcule
# donc l'ensemble des années candidates à partir des bornes, et on
# n'échantillonne que celles-là.
#
# TROIS FAMILLES DE BORNES, ET LA TROISIÈME EST NEUVE
# ---------------------------------------------------
# `membership` et `unit_version` disent quand la COMPOSITION change.
# `atom_geom_anr` dit quand la FORME change, et ces bornes-là ne coïncident pas
# avec les premières : une commune peut perdre un hameau sans changer de canton.
# Omettre cette troisième famille, c'est ne jamais échantillonner l'année où la
# forme bouge — le changement n'existerait tout simplement pas dans l'export, et
# aucune recette ne pourrait le remarquer puisque rien n'aurait été demandé à la
# base. *Une borne qu'on n'interroge pas ne produit pas une erreur, elle produit
# un silence.*
# ---------------------------------------------------------------------------
SQL_BORNES = """
SELECT DISTINCT d FROM (
    SELECT m.valid_from AS d
    FROM   membership m JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
    WHERE  m.niveau = %(niveau)s AND u.dep = %(dep)s
    UNION ALL
    SELECT m.valid_to
    FROM   membership m JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
    WHERE  m.niveau = %(niveau)s AND u.dep = %(dep)s
    UNION ALL
    SELECT uv.valid_from
    FROM   unit_version uv JOIN unit u ON u.unit_id = uv.unit_id
    WHERE  u.niveau = %(niveau)s AND u.dep = %(dep)s
    UNION ALL
    SELECT uv.valid_to
    FROM   unit_version uv JOIN unit u ON u.unit_id = uv.unit_id
    WHERE  u.niveau = %(niveau)s AND u.dep = %(dep)s
) t
"""

# Bornes de forme. Séparée de `SQL_BORNES` parce qu'elle ne s'exécute que si
# `atom_geom_anr` existe : une base reconstruite sans `82` doit exporter quand
# même, avec la trame 2011 et sans épaisseur temporelle.
SQL_BORNES_GEOM = """
SELECT DISTINCT d FROM (
    SELECT lower(ga.periode) AS d FROM atom_geom_anr ga WHERE ga.atom_id IN (
        SELECT m.atom_id FROM membership m
        JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
        WHERE u.dep = %(dep)s)
    UNION ALL
    SELECT upper(ga.periode) FROM atom_geom_anr ga WHERE ga.atom_id IN (
        SELECT m.atom_id FROM membership m
        JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
        WHERE u.dep = %(dep)s)
) t
"""

# Bornes de VIE des atomes, pour `--partition`. À ne pas confondre avec
# `SQL_BORNES`, qui rend toutes les bornes de rattachement : un atome qui passe
# d'un canton à l'autre y produit deux bornes et ne change pas d'un pouce de
# forme. La partition, elle, ne dépend que de QUI est vivant et de QUELLE forme
# ANR lui donne. Distinguer les deux fait passer le nombre de calculs d'une
# centaine par département à vingt-cinq.
#
# Les intervalles sont rendus bruts : c'est Python qui les fusionne par atome,
# parce que fusionner des intervalles en SQL demande un « gaps and islands »
# qu'on relirait trois fois avant de le croire.
SQL_VIE_ATOME = """
SELECT m.atom_id, m.valid_from, m.valid_to
FROM   membership m
JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
WHERE  u.dep = %(dep)s
ORDER  BY m.atom_id, m.valid_from
"""

# Bornes des VILLES DÉCOUPÉES, pour `--partition` — 3 octobre 2026, avec
# `sql/99_partition_coupes.sql`. Une fraction découpée change de forme quand
# une ligne ou une ancre commence ou finit, ou quand une fraction de la ville
# gagne ou perd son canton (les ancres ne jouent que pour les fractions qui en
# ont un). Aucune de ces bornes n'est une borne de VIE ou d'ANR : sans elles,
# une ligne qui commence en 1982 ne serait tirée qu'à la borne de forme
# suivante. Ne s'exécute que si `coupe_ville` existe (98 joué).
SQL_BORNES_COUPE = """
-- La clé d'une coupe est la commune, ou le quartier pour Paris (`coupe_cle`
-- et `coupe_niveau` de 98, depuis `101`).
WITH v AS (
    SELECT DISTINCT coupe_cle(a.cassini, a.insee_geofla::text) AS insee
    FROM   atom a
    JOIN   membership m ON m.atom_id = a.atom_id
    JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
    WHERE  u.dep = %(dep)s
      AND  a.atom_id LIKE '%%#%%'
      AND  coupe_cle(a.cassini, a.insee_geofla::text) IN (SELECT insee::text FROM coupe_ville)
)
SELECT c.valid_from FROM coupe_ville c JOIN v ON v.insee = c.insee::text
UNION SELECT c.valid_to FROM coupe_ville c JOIN v ON v.insee = c.insee::text
UNION SELECT an.valid_from FROM coupe_ville_ancre an
      JOIN atom a ON a.atom_id = an.atom_id
      JOIN v ON v.insee = coupe_cle(a.cassini, a.insee_geofla::text)
UNION SELECT an.valid_to FROM coupe_ville_ancre an
      JOIN atom a ON a.atom_id = an.atom_id
      JOIN v ON v.insee = coupe_cle(a.cassini, a.insee_geofla::text)
UNION SELECT m.valid_from FROM membership m
      JOIN atom a ON a.atom_id = m.atom_id
      JOIN v ON v.insee = coupe_cle(a.cassini, a.insee_geofla::text)
      WHERE m.niveau = coupe_niveau(v.insee) AND a.atom_id LIKE '%%#%%'
UNION SELECT m.valid_to FROM membership m
      JOIN atom a ON a.atom_id = m.atom_id
      JOIN v ON v.insee = coupe_cle(a.cassini, a.insee_geofla::text)
      WHERE m.niveau = coupe_niveau(v.insee) AND a.atom_id LIKE '%%#%%'
"""

# La signature couvre la composition ET la forme.
#
# `coalesce(ga.poly_id, '=')` : `=` marque un atome en repli sur `atom_geom`,
# qui ne change jamais. Deux dates où le même atome est en repli portent donc le
# même jeton, et ne fabriquent pas de configuration supplémentaire — le repli
# n'a pas d'épaisseur temporelle, c'est justement sa limite.
SQL_SIGNATURE = """
SELECT md5(string_agg(m.atom_id || '>' || m.unit_id || '>'
                      || coalesce(uv.nom, u.nom, '') || '>' || {jeton},
                      ',' ORDER BY m.atom_id)) AS sig,
       count(*) AS n
FROM   membership m
JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
LEFT   JOIN unit_version uv ON uv.unit_id = u.unit_id AND uv.periode @> %(d)s::date
{joint_geom}
WHERE  m.niveau = %(niveau)s AND u.dep = %(dep)s AND m.periode @> %(d)s::date
"""

JOINT_GEOM_ANR = ("LEFT   JOIN atom_geom_anr ga "
                  "ON ga.atom_id = m.atom_id AND ga.periode @> %(d)s::date")


def sql_signature(anr):
    if anr:
        return SQL_SIGNATURE.format(jeton="coalesce(ga.poly_id, '=')",
                                    joint_geom=JOINT_GEOM_ANR)
    return SQL_SIGNATURE.format(jeton="''", joint_geom="")


def annee_de_borne(d):
    """Année dont la planche est déplacée par une borne tombant le jour `d`.

    Une borne au 1888-02-03 déplace ce qu'on observe au 1er décembre 1888 ; une
    borne au 1888-12-12 ne le déplace qu'en 1889.
    """
    return d.year if (d.month, d.day) <= MOIS_JOUR else d.year + 1


def annees_candidates(cur, dep, niveau, anr):
    """Années où la carte peut changer, bornes du modèle à l'appui."""
    cand = {AN_MIN}
    requetes = [(SQL_BORNES, {"dep": dep, "niveau": niveau})]
    if anr:
        requetes.append((SQL_BORNES_GEOM, {"dep": dep}))
    for sql, params in requetes:
        cur.execute(sql, params)
        for (d,) in cur.fetchall():
            if d is None:
                continue
            y = annee_de_borne(d)
            if AN_MIN <= y <= AN_MAX:
                cand.add(y)
    return sorted(cand)


def annees_geometriques(cur, dep):
    """Années où le jeu de polygones dessinés peut changer, pour `--partition`.

    Deux sources et deux seulement : les bornes de `atom_geom_anr`, et celles
    de la VIE des atomes. Un atome qui change de canton n'entre pas ici — sa
    forme n'a pas bougé, et lui faire recalculer une partition serait payer
    quatre fois le prix pour le même dessin.

    LIMITE CONNUE. La reprise d'un atome dépend de la forme de sa MÈRE, et la
    mère peut vivre dans un département voisin — `84` la cherche dans son anneau
    de 20 km, cette fonction-ci ne regarde que le département. Une mère
    étrangère qui change de forme entre deux années géométriques du département
    déplacerait donc la reprise sans qu'on recalcule. Le cas est rare (il faut
    une fille frontalière ET une mère qui bouge dans l'intervalle) et il se
    corrige en ajoutant les bornes des voisins ; on le déclare plutôt que de
    payer d'avance un élargissement dont personne n'a mesuré le besoin.
    """
    cand = {AN_MIN}
    cur.execute(SQL_BORNES_GEOM, {"dep": dep})
    for (d,) in cur.fetchall():
        if d is not None:
            cand.add(annee_de_borne(d))

    # Fusionner les intervalles de rattachement par atome : seules les bornes
    # qui restent après fusion sont des changements de VIE. Les autres sont des
    # passages d'un canton à l'autre, et la forme les ignore.
    cur.execute(SQL_VIE_ATOME, {"dep": dep})
    par_atome = {}
    for atom_id, d1, d2 in cur.fetchall():
        par_atome.setdefault(atom_id, []).append((d1, d2))
    for segs in par_atome.values():
        segs.sort(key=lambda s: (s[0] is None, s[0]))
        fin = None
        for d1, d2 in segs:
            if fin is None or (d1 is not None and fin is not None and d1 > fin):
                if d1 is not None:
                    cand.add(annee_de_borne(d1))
                if fin is not None:
                    cand.add(annee_de_borne(fin))
                fin = d2
            elif d2 is None or fin is None or d2 > fin:
                fin = d2
        if fin is not None:
            cand.add(annee_de_borne(fin))

    # Les villes découpées (99) : bornes des lignes, des ancres et des cantons
    # de leurs fractions. Voir `SQL_BORNES_COUPE`.
    cur.execute("SELECT to_regclass('histgis.coupe_ville') IS NOT NULL")
    if cur.fetchone()[0]:
        cur.execute(SQL_BORNES_COUPE, {"dep": dep})
        for (d,) in cur.fetchall():
            if d is not None:
                cand.add(annee_de_borne(d))

    return sorted(a for a in cand if AN_MIN <= a <= AN_MAX)


# La table de partition d'un département : une ligne par (année géométrique,
# atome). Elle sert les trois requêtes datées, qui la joignent sur `an`.
#
# TEMPORAIRE et par département : `carte_partition_atome` crée elle-même des
# tables temporaires, et deux workers qui se partageraient un département se
# marcheraient dessus. Le parallélisme du script est déjà par département,
# et c'est ce qui rend la chose sûre sans un mot de synchronisation.
SQL_PART_CREE = """
DROP TABLE IF EXISTS part_dep;
CREATE TEMP TABLE part_dep (
    an       int  NOT NULL,
    atom_id  text NOT NULL,
    source   text NOT NULL,
    motif    text,
    geom     geometry(MultiPolygon, 2154) NOT NULL
)
"""

SQL_PART_REMPLIT = """
INSERT INTO part_dep (an, atom_id, source, motif, geom)
SELECT %(an)s, c.atom_id, c.source, c.motif, c.geom
FROM   carte_partition_atome(%(d)s::date, %(dep)s) c
WHERE  c.geom IS NOT NULL
"""


def prepare_partition(cur, dep, annees_geom):
    """Calcule la partition une fois par année géométrique. Rend an -> an_geom.

    Le dictionnaire rendu traduit N'IMPORTE QUELLE année en l'année géométrique
    qui la gouverne : une configuration dont l'année de référence tombe sur un
    changement de composition sans changement de forme lit la partition de la
    dernière année géométrique qui la précède. Sans cette traduction, une
    jointure sur `an = %(d)s` ne trouverait rien et la carte serait vide — un
    échec silencieux, le pire de tous.
    """
    cur.execute(SQL_PART_CREE)
    for an in annees_geom:
        cur.execute(SQL_PART_REMPLIT,
                    {"an": an, "d": date_ref(an), "dep": dep})
    cur.execute("CREATE INDEX ON part_dep (an, atom_id)")
    cur.execute("ANALYZE part_dep")

    gouverne, courante = {}, None
    for an in range(AN_MIN, AN_MAX + 1):
        if an in annees_geom:
            courante = an
        gouverne[an] = courante if courante is not None else AN_MIN
    return gouverne


def configurations(cur, dep, niveau, anr):
    """année -> signature ('' si aucune source), et signature -> année de référence."""
    par_annee = {}
    sig_annee = {}
    courante = None
    cand = set(annees_candidates(cur, dep, niveau, anr))
    sql = sql_signature(anr)
    for annee in range(AN_MIN, AN_MAX + 1):
        if annee in cand:
            cur.execute(sql, {"dep": dep, "niveau": niveau, "d": date_ref(annee)})
            sig, n = cur.fetchone()
            courante = sig if (sig and n) else ""
            if courante and courante not in sig_annee:
                sig_annee[courante] = annee
        par_annee[annee] = courante or ""
    return par_annee, sig_annee


# ---------------------------------------------------------------------------
# Géométries
#
# `ST_SnapToGrid` avant reprojection, et le même ordre d'opérations pour les
# atomes et pour les unités dissoutes : c'est ce qui fait coïncider les limites
# cantonales avec les limites communales. `ST_MakeValid` derrière, parce que
# l'accrochage peut aplatir un anneau et produire une géométrie invalide.
#
# Avec la trame datée, la règle se durcit d'un cran : ce n'est plus seulement le
# même ORDRE d'opérations qu'il faut, c'est la même SOURCE. Le polygone communal
# exporté pour 1885 et le contour cantonal dissous pour 1885 doivent tous deux
# sortir de `coalesce(ANR au 1er décembre 1885, atom_geom)` — sinon un canton
# dessiné sur la forme d'ANR longerait des communes dessinées sur la forme de
# 2011, et la lisière serait un artefact de tuyauterie. D'où l'expression
# unique ci-dessous, utilisée par les trois requêtes.
# ---------------------------------------------------------------------------
def geom_snap(src):
    return f"ST_MakeValid(ST_SnapToGrid({src}, %(grille)s))"


GEOM_ATOME = geom_snap("ag.geom")                      # trame GEOFLA 2011 seule
GEOM_DATEE = geom_snap("coalesce(ga.geom, ag.geom)")   # ANR quand il parle (R5)

# `--partition` : la trame nettoyée de `84` d'abord, et le coalesce derrière —
# non pas qu'il doive servir, mais parce qu'un atome que `carte_partition_atome`
# ne rendrait pas doit rester dessiné plutôt que disparaître sans un mot.
# Si ce repli-là se met à servir, c'est `84` qu'il faut regarder, pas la carte.
GEOM_PARTITION = geom_snap("coalesce(cp.geom, ga.geom, ag.geom)")

# La jointure datée qui accompagne `GEOM_DATEE` dans les requêtes par date.
JOINT_DATE = ("LEFT   JOIN atom_geom_anr ga "
              "ON ga.atom_id = m.atom_id AND ga.periode @> %(d)s::date")

# `%(ag)s` et pas `%(d)s` : la partition est indexée par ANNÉE GÉOMÉTRIQUE, pas
# par la date affichée. C'est `prepare_partition()` qui traduit l'une en l'autre.
JOINT_PARTITION = (JOINT_DATE + "\nLEFT   JOIN part_dep cp "
                   "ON cp.atom_id = m.atom_id AND cp.an = %(ag)s")

# Le nom de la commune vient de `noms_geofla`, à défaut de `geofla_commune`.
# C'est un nom de 2011, donc potentiellement anachronique sur une planche de
# 1885 : la base ne tient pas de nom communal d'époque (`insee_mvt.libelle_av`
# le donnerait pour les disparues, c'est un chantier ouvert dans
# `RESTE_A_FAIRE.md`). La page l'affiche en le disant.
#
# Ces deux tables sont des annexes, pas le cœur du modèle : une base
# reconstruite sans elles doit exporter quand même, avec des communes sans nom
# plutôt qu'un export qui échoue. D'où la requête assemblée selon ce qui est
# présent, constaté une fois à la connexion.
def sql_communes(dico, geofla, mvt, anr_nom=False):
    """Attributs d'un atome — tout sauf la géométrie, qui est maintenant datée.

    Cette requête rend UNE ligne par atome. Les polygones viennent des deux
    requêtes suivantes, parce qu'un atome en porte désormais plusieurs et qu'on
    ne va pas répéter son nom et son code à chaque version.
    """
    # Chaîne de repli identique à `archives/planches/cartes_cantons.py` : le nom GEOFLA
    # 2011, puis le `libelle_av` du fichier de mouvements pour les communes
    # disparues avant 2011, puis le code entre crochets. « Ce qui n'a de nom
    # nulle part est signalé comme tel, pas maquillé. »
    champs, joints = [], []
    if geofla:
        joints.append("LEFT JOIN geofla_commune g ON g.insee_com = a.insee_geofla")
        champs.append("g.nom_comm")
    if dico:
        joints.append("LEFT JOIN noms_geofla n ON n.insee = a.insee_geofla")
        champs.append("n.nom")
    if mvt:
        champs.append("""(SELECT mv.libelle_av FROM insee_mvt mv
                          WHERE mv.com_av = a.insee_geofla
                          ORDER BY mv.date_eff LIMIT 1)""")
    # Dernier repli avant le code : le nom que porte ANR, joint par Cassini.
    # Il sert aux atomes SANS code INSEE — les onze communes annexées à Paris
    # en 1860 (`89`), que rien d'autre ne nomme : sans lui la fiche affichait
    # « nom en 1850 : 23671 » pour Montmartre (3 octobre 2026). `coalesce`
    # n'évalue la sous-requête que si tout ce qui précède est NULL, donc elle
    # ne coûte rien aux communes déjà nommées. Le suffixe « [Département] »
    # qu'ANR ajoute à certaines fenêtres est retiré, et le nom est mis à la
    # graphie GEOFLA — capitales sans accents (« LA VILLETTE ») — pour ne pas
    # dépareiller les étiquettes. `translate` avant `upper` : sous une
    # collation C, `upper('é')` rend `é`.
    if anr_nom:
        champs.append("""(SELECT upper(translate(
                                 regexp_replace(x.namecom, '\\s*\\[[^]]*\\]$', ''),
                                 'àâäçéèêëîïôöùûüÿœÀÂÄÇÉÈÊËÎÏÔÖÙÛÜŸŒ',
                                 'aaaceeeeiioouuuyoAAACEEEEIIOOUUUYO'))
                          FROM anr_commune x
                          WHERE x.id_com::text = a.cassini
                          ORDER BY (nullif(x.enddt::text, ''))::numeric DESC NULLS LAST
                          LIMIT 1)""")
    champs.append("'[' || a.insee_geofla || ']'")
    nom = f"coalesce({', '.join(champs)})"
    disparue = "(g.insee_com IS NULL)" if geofla else "NULL::boolean"
    return f"""
SELECT a.atom_id,
       a.insee_geofla,
       a.cassini,
       a.fraction,
       ag.partagee,
       {nom}                                                       AS nom,
       {disparue}                                                  AS disparue
FROM   atom a
LEFT   JOIN atom_geom ag ON ag.atom_id = a.atom_id
{chr(10).join(joints)}
WHERE  a.atom_id IN (
           SELECT DISTINCT m.atom_id
           FROM   membership m
           JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
           WHERE  u.dep = %(dep)s
       )
"""


# Les versions ANR d'un atome, bornées à la fenêtre du curseur. `ga` remplace
# `ag` dans l'expression de snap : c'est le polygone d'époque qu'on accroche.
SQL_VERSIONS_ANR = f"""
SELECT ga.atom_id,
       lower(ga.periode)                                             AS d_debut,
       upper(ga.periode)                                             AS d_fin,
       ST_AsGeoJSON(ST_Transform({geom_snap('ga.geom')}, 4326), %(prec)s)  AS gj,
       ST_AsGeoJSON(ST_Transform(ST_PointOnSurface({geom_snap('ga.geom')}), 4326),
                    %(prec)s)                                        AS pt
FROM   atom_geom_anr ga
WHERE  ga.periode && daterange(%(borne_min)s::date, %(borne_max)s::date, '[)')
  AND  ga.atom_id IN (
           SELECT DISTINCT m.atom_id
           FROM   membership m
           JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
           WHERE  u.dep = %(dep)s
       )
ORDER  BY ga.atom_id, lower(ga.periode)
"""

# Le polygone de repli (R5), demandé UNIQUEMENT pour les atomes qu'ANR laisse
# découverts sur tout ou partie de la fenêtre. Le demander pour tous doublerait
# la charge utile pour rien : dans un département ordinaire, la grande majorité
# des atomes est couverte de bout en bout par ANR.
SQL_VERSION_REPLI = f"""
SELECT ag.atom_id,
       ST_AsGeoJSON(ST_Transform({GEOM_ATOME}, 4326), %(prec)s)      AS gj,
       ST_AsGeoJSON(ST_Transform(ST_PointOnSurface({GEOM_ATOME}), 4326),
                    %(prec)s)                                       AS pt
FROM   atom_geom ag
WHERE  ag.atom_id = ANY(%(atomes)s)
"""

# `--partition` : les versions se lisent dans `part_dep`, pas dans
# `atom_geom_anr`. Une ligne par (année géométrique, atome) ; c'est
# `construit_versions_partition()` qui en refait des intervalles.
#
# L'accrochage à la grille est appliqué ICI comme ailleurs, et c'est ce qui
# garde la promesse du fichier : le polygone communal et le contour cantonal
# subissent les mêmes opérations dans le même ordre sur la MÊME source.
#
# `idem` EST LA COLONNE QUI DÉCIDE DU POIDS DU FICHIER, et elle a coûté un
# aller-retour. Le premier jet dédoublonnait sur l'empreinte du GeoJSON émis.
# Éprouvé sur l'Ain avec le banc : 916 instantanés donnaient 918 versions —
# AUCUNE déduplication. La raison n'est pas la sérialisation, elle est
# géométrique : le treillis est renoué à chaque année, et une commune dont un
# VOISIN change gagne ou perd des sommets colinéaires sur leur bord commun. Sa
# forme est la même, son empreinte ne l'est pas. À ce régime un département aux
# vingt-cinq années géométriques portait vingt-cinq versions par commune.
#
# `ST_Equals` tranche sur l'ensemble de points et se moque des sommets en trop.
# Comparé au précédent par `lag()`, il suffit — on ne dédoublonne que des
# versions CONSÉCUTIVES, jamais deux formes séparées par une troisième.
#
# *Deux dessins identiques peuvent avoir deux empreintes ; c'est l'égalité
# géométrique qu'il faut demander, pas l'égalité des octets.*
SQL_VERSIONS_PARTITION = f"""
SELECT p.atom_id,
       p.an,
       p.source,
       ST_AsGeoJSON(ST_Transform({geom_snap('p.geom')}, 4326), %(prec)s)  AS gj,
       ST_AsGeoJSON(ST_Transform(ST_PointOnSurface({geom_snap('p.geom')}), 4326),
                    %(prec)s)                                            AS pt,
       coalesce(ST_Equals(p.geom,
                          lag(p.geom) OVER (PARTITION BY p.atom_id
                                            ORDER BY p.an)), false)      AS idem
FROM   part_dep p
ORDER  BY p.atom_id, p.an
"""


# ---------------------------------------------------------------------------
# Chronologie des noms de communes
#
# `insee_mvt` porte 1 388 changements de nom (`mod = '10'`), datés, de 1943 à
# 2025 — la modalité qui renomme sans toucher au code. On en tire, pour chaque
# code INSEE, la suite des noms portés dans le temps, et la page affiche celui
# de l'année au curseur.
#
# Ce que ça apporte, et sa limite. Le fichier de l'Insee commence en 1943 :
# aucun renommage antérieur n'y figure. Pour une planche de 1885, la
# chronologie rend donc le nom *le plus ancien connu* — celui d'avant le
# premier renommage enregistré — et non le nom moderne, ce qui est déjà mieux
# que ce que font les planches PDF, qui affichent le nom de 2011. Mais un
# renommage de 1900 reste invisible : la base ne le connaît pas.
#
# Autre limite, et c'est la même que partout : la chronologie porte sur le code
# de 2011. Une commune d'époque absorbée depuis prend le code de l'absorbante,
# donc son historique de nom. C'est le cas que `cassini` permet de *repérer*
# (plusieurs atomes sur un polygone) sans permettre de le *nommer* : aucune
# source du projet ne donne le nom d'un code Cassini.
# ---------------------------------------------------------------------------
SQL_RENOMMAGES = """
SELECT mv.com_av, mv.date_eff, mv.libelle_av, mv.libelle_ap
FROM   insee_mvt mv
WHERE  mv.mod = '10'
  AND  mv.com_av IN (
           SELECT DISTINCT a.insee_geofla
           FROM   atom a
           JOIN   membership m ON m.atom_id = a.atom_id
           JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
           WHERE  u.dep = %(dep)s
       )
ORDER  BY mv.com_av, mv.date_eff
"""


def chronologies(cur, dep):
    """insee -> [[annee_debut, nom], …], seulement pour les codes renommés."""
    try:
        cur.execute(SQL_RENOMMAGES, {"dep": dep})
    except psycopg2.Error:
        return {}
    par_insee = {}
    for insee, date_eff, av, ap in cur.fetchall():
        par_insee.setdefault(insee.strip(), []).append((date_eff, av, ap))
    out = {}
    for insee, mvts in par_insee.items():
        mvts.sort(key=lambda t: t[0])
        # avant le premier renommage : le nom d'avant ; après chacun : le nom
        # d'après. Le dernier segment doit retomber sur le nom GEOFLA.
        suite = [[AN_MIN, mvts[0][1]]]
        for date_eff, _av, ap in mvts:
            suite.append([date_eff.year, ap])
        # on élague les doublons consécutifs, fréquents quand seul le NCC change
        propre = [suite[0]]
        for seg in suite[1:]:
            if seg[1] != propre[-1][1]:
                propre.append(seg)
        if len(propre) > 1:
            out[insee] = propre
    return out


# ---------------------------------------------------------------------------
# Construction de la chronologie géométrique d'un atome
#
# ANR donne des SEGMENTS, pas une couverture. Trois choses peuvent manquer, et
# les trois se comblent au même endroit :
#
#   * avant le premier segment — la commune existe chez nous avant qu'ANR ne la
#     fasse naître (les 486 atomes du report arrière de `11`) ;
#   * ENTRE deux segments — les 532 trous de chronologie qu'ANR ne déclare pas,
#     dont les vingt communes des Ardennes en `1790-1828 | 1871-2020` ;
#   * après le dernier segment.
#
# Le deuxième cas est le seul qu'on ne trouve qu'en interrogeant l'intérieur du
# jeu. Une boucle qui se contenterait de prendre le premier et le dernier
# segment le manquerait en silence, et la carte afficherait pour 1850 le
# polygone de 1828 comme s'il était attesté. *Une source datée n'est pas une
# source continue, et rien dans son format ne le dit.*
#
# Fonction pure : elle ne touche ni à la base ni au disque, et le banc de
# `sql/bancs/banc_82.sh` a son équivalent Python dans `sorties/anr/`.
# ---------------------------------------------------------------------------
def construit_versions(segments, repli, an_min=AN_MIN, an_max=AN_MAX):
    """[(an_debut, an_fin_exclu, gj, pt)] + repli -> [{a, k, c, g, r}, …].

    `segments` est trié par année de début. `repli` vaut `(gj, pt)` ou `None`
    quand l'atome n'a aucune géométrie dans `atom_geom` : les intervalles
    découverts restent alors vides, et l'atome n'est pas dessiné à ces dates
    plutôt que de l'être avec la forme d'une autre époque.
    """
    versions = []

    def ajoute(an, paire, repli_ici):
        # Un intervalle sans aucune géométrie doit être écrit COMME TEL, et pas
        # sauté. La page tient la version en vigueur jusqu'à la suivante : sauter
        # l'intervalle laisserait le polygone précédent à l'écran, c'est-à-dire
        # afficherait la forme de 1828 en 1850 comme si elle était attestée.
        # *Ne rien écrire n'est pas neutre quand le lecteur en aval prolonge.*
        if paire is None or not paire[0]:
            if not versions or versions[-1]["g"] is not None:
                versions.append({"a": an, "k": None, "r": 1, "c": None, "g": None})
            return
        gj, pt = paire
        cle = hashlib.md5(gj.encode()).hexdigest()[:10]
        # Deux versions successives de même empreinte ne sont qu'une : ANR
        # réédite parfois une commune sans que sa forme bouge (les trois
        # `Poly_ID` à double fenêtre que R2 a fait remarquer au banc).
        if versions and versions[-1]["k"] == cle and versions[-1]["r"] == repli_ici:
            return
        p = json.loads(pt)["coordinates"] if pt else None
        versions.append({
            "a": an,
            "k": cle,
            "r": 1 if repli_ici else 0,
            "c": [round(p[0], 5), round(p[1], 5)] if p else None,
            "g": json.loads(gj),
        })

    curseur = an_min
    for d, f, gj, pt in segments:
        d = max(d, an_min)
        f = min(f, an_max + 1)
        if f <= d:
            continue
        if d > curseur:
            ajoute(curseur, repli, True)      # trou de chronologie, ou avant-naissance
        ajoute(d, (gj, pt), False)
        curseur = f
    if curseur <= an_max:
        ajoute(curseur, repli, True)
    return versions

# Les unités dissoutes à une date. `n_anr` et `n_repli` sont le pendant exact de
# ce que rend `snapshot_geom_anr()` en base : une unité dont `n_repli` est grand
# n'est pas fausse, elle est moins bien datée — et la page doit pouvoir le dire
# sans qu'on relise ce fichier.
SQL_UNITES = """
SELECT u.unit_id,
       coalesce(uv.nom, u.nom, u.unit_id)                AS nom,
       u.code,
       u.regime,
       u.provisoire,
       count(*)                                          AS n_atomes,
       count(*) FILTER (WHERE {sans_geom})               AS n_sans_geom,
       count(*) FILTER (WHERE ag.partagee)               AS n_partagees,
       count(*) FILTER (WHERE {est_anr})                 AS n_anr,
       count(*) FILTER (WHERE {est_repli})               AS n_repli,
       count(*) FILTER (WHERE {est_repris})              AS n_repris,
       array_agg(m.atom_id ORDER BY m.atom_id)           AS atomes,
       ST_AsGeoJSON(
           ST_Transform(
               ST_MakeValid(ST_UnaryUnion(ST_Collect({geom}))), 4326),
           %(prec)s)                                     AS gj
FROM   membership m
JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
LEFT   JOIN unit_version uv ON uv.unit_id = u.unit_id AND uv.periode @> %(d)s::date
LEFT   JOIN atom_geom ag ON ag.atom_id = m.atom_id
{joint_date}
WHERE  m.niveau = %(niveau)s AND u.dep = %(dep)s AND m.periode @> %(d)s::date
GROUP  BY u.unit_id, coalesce(uv.nom, u.nom, u.unit_id), u.code, u.regime, u.provisoire
"""

SQL_CONTOUR = """
SELECT ST_AsGeoJSON(
           ST_Transform(
               ST_MakeValid(ST_UnaryUnion(ST_Collect({geom}))), 4326),
           %(prec)s)
FROM   membership m
JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
LEFT   JOIN atom_geom ag ON ag.atom_id = m.atom_id
{joint_date}
WHERE  m.niveau = 'canton' AND u.dep = %(dep)s AND m.periode @> %(d)s::date
"""


def sql_par_date(anr, partition=False):
    """Les deux requêtes datées, gréées selon la trame demandée.

    Avec `--partition`, les compteurs ne se lisent plus sur la présence d'un
    polygone mais sur la SOURCE que `84` déclare pour chacun : `anr`, `reprise`
    ou `repli`. C'est plus qu'un détail de comptage — c'est ce qui permet à une
    unité de dire « ma forme doit trois communes à une reprise », alors que la
    trame hybride ne savait dire que « trois communes sont en repli ».
    """
    if partition:
        gabarit = {"geom": GEOM_PARTITION, "joint_date": JOINT_PARTITION,
                   "sans_geom": "cp.atom_id IS NULL AND ga.atom_id IS NULL "
                                "AND ag.atom_id IS NULL",
                   "est_anr": "cp.source = 'anr'",
                   "est_repli": "cp.source = 'repli'",
                   "est_repris": "cp.source = 'reprise'"}
    elif anr:
        gabarit = {"geom": GEOM_DATEE, "joint_date": JOINT_DATE,
                   "sans_geom": "ga.atom_id IS NULL AND ag.atom_id IS NULL",
                   "est_anr": "ga.atom_id IS NOT NULL",
                   "est_repli": "ga.atom_id IS NULL AND ag.atom_id IS NOT NULL",
                   "est_repris": "false"}
    else:
        gabarit = {"geom": GEOM_ATOME, "joint_date": "",
                   "sans_geom": "ag.atom_id IS NULL",
                   "est_anr": "false", "est_repli": "ag.atom_id IS NOT NULL",
                   "est_repris": "false"}
    return SQL_UNITES.format(**gabarit), SQL_CONTOUR.format(**gabarit)


# ===========================================================================
# OUTRE-MER — un second espace, et pourquoi il ne se branche pas sur le premier
#
# `sql/40_outremer.sql` range la Guadeloupe, la Martinique, la Guyane, La
# Réunion et Mayotte dans des tables `om_*` séparées. Ce n'est pas une commodité
# de rangement, et il faut l'avoir en tête avant de lire ce qui suit — trois
# différences de MODÈLE interdisent de réutiliser les requêtes ci-dessus :
#
#   1. `unit.dep` est `char(2)` ; `om_unit.dep` est `char(3)`, parce que les
#      codes d'outre-mer tiennent sur trois caractères et que Mayotte n'a pas
#      de code ministériel à deux ;
#   2. la métropole vit en Lambert-93 (EPSG:2154), l'outre-mer en WGS84
#      (EPSG:4326) — reprojeter La Réunion en Lambert-93 multiplierait ses
#      surfaces par 3,54, et tous les contrôles du projet sont surfaciques ;
#   3. **il n'y a ni ANR ni partition outre-mer.** `atom_geom_anr` ne couvre
#      que la métropole, `84` aussi. La géométrie d'un atome d'outre-mer est un
#      instantané GEOFLA 2015 sans épaisseur temporelle, exactement ce que la
#      métropole était avant `82`.
#
# D'où un bloc de requêtes à part, court parce que le modèle est plus simple, et
# une fonction d'export à lui. *Deux modèles qui diffèrent sur la clé, sur la
# projection et sur la dimension temporelle ne se factorisent pas en changeant
# des noms de tables : on croirait relire le même code, et il ne ferait pas la
# même chose.*
#
# CE QUE CE CHEMIN NE FAIT PAS, ET QUI SE VOIT SUR LA CARTE
# ---------------------------------------------------------
# `40` déclare deux trous, et l'export les laisse tels quels plutôt que de les
# combler au jugé :
#
#   * les **27 communes multicantonales** (plus Mamoudzou) n'ont AUCUN
#     rattachement cantonal — GEOFLA ne les découpe pas, et
#     `om_membership_non_chevauchant` refuserait de les mettre dans quatre
#     cantons à la fois. Elles sortent avec `p: 1`, donc hachurées par la page,
#     qui dit déjà « le tracé reste à faire, sur la trame IRIS » ;
#   * **Mayotte n'a aucun rattachement du tout** : ses 16 cantons viennent de
#     GEOFLA, mais le fichier du ministère qui pose les rattachements ne la
#     contient pas. Le département sortira avec ses communes dessinées et zéro
#     année servie.
#
# C'EST POURQUOI LES ATOMES SONT LUS PAR `om_atom.dep` ET NON PAR LE
# MEMBERSHIP. La requête métropolitaine part du `membership` — un atome sans
# rattachement n'existe pas pour elle. Appliquée telle quelle à l'outre-mer,
# elle ferait **disparaître de la carte** les vingt-huit communes sans canton et
# les dix-sept communes de Mayotte, c'est-à-dire précisément ce que `40` a pris
# soin de ne pas décider. Une commune dessinée sans couleur montre le trou ;
# une commune absente le cache. *La règle du projet — « ce qui n'a de nom nulle
# part est signalé comme tel, pas maquillé » — se joue ici dans le choix de la
# table de départ.*
# ===========================================================================

# L'accrochage à la grille, en DEGRÉS et non en mètres, et ça se dit.
#
# `ST_SnapToGrid` travaille dans l'unité de la géométrie : des mètres en 2154,
# des degrés en 4326. On convertit donc le pas demandé au taux de 111 320 m par
# degré, qui est celui de l'équateur. Les cinq départements sont entre 4° S
# (Guyane) et 21° S (La Réunion) : le pas réel en longitude y vaut de 111 320 à
# 103 900 m par degré, donc un « 25 m » demandé accroche en fait entre 25,0 et
# 26,8 m selon le lieu.
#
# **Ce n'est pas une approximation à corriger, et il faut dire pourquoi.** Ce
# que la grille garantit n'est pas une distance, c'est une COÏNCIDENCE : deux
# communes voisines qui partageaient un sommet le partagent encore après
# accrochage, donc le contour cantonal dissous longe exactement la limite
# communale. Cette propriété ne dépend que du fait que la même grille est
# appliquée aux deux, jamais de sa valeur métrique. Un pas qui varie de 7 % avec
# la latitude ne l'entame pas d'un pouce.
DEG_PAR_M = 1.0 / 111320.0

# Le Pacifique n'a pas besoin de la grille, et elle lui nuit. Ses deux trames
# sont déjà une couverture propre, allégée à 20 m par `sql/trame_pacifique.py`
# avec des sommets partagés à l'identique : il n'y a aucune coïncidence à
# rétablir. Accrochés à 25 m, ses traits encore sinueux se referment en
# boucles que `ST_MakeValid` change en trous — 1 554 en Nouvelle-Calédonie
# sur la trame brute, contre zéro dans les DOM. Un mètre suffit : c'est déjà
# ce que fait l'arrondi à cinq décimales du GeoJSON.
PAS_TRAME_M = {"ispf2021": 1.0, "gnc2024": 1.0}

# Les atomes d'un département d'outre-mer. Sept colonnes dans le même ordre que
# `sql_communes()`, pour que la boucle d'écriture soit la même des deux côtés.
#
# `cassini` est NULL : la série TRF-GIS ne couvre pas l'outre-mer, et inventer
# un identifiant intermédiaire n'apporterait rien (`40`, § 1). `fraction` et
# `disparue` sont faux : il n'y a pas d'atome-fraction outre-mer, et la trame
# est celle de 2015, donc contemporaine de la période servie.
#
# `partagee` porte `om_atom.multi`, et le sens est le bon : GEOFLA ne découpe
# pas ces communes-là. La page les hachure et annonce un tracé à faire sur la
# trame IRIS — `iris_om` est en base, c'est le chantier ouvert, pas un défaut.
SQL_OM_ATOMES = """
SELECT a.atom_id,
       a.atom_id            AS insee_geofla,
       NULL::text           AS cassini,
       false                AS fraction,
       a.multi              AS partagee,
       a.nom                AS nom,
       false                AS disparue
FROM   om_atom a
WHERE  a.dep = %(dep)s
ORDER  BY a.atom_id
"""


def sql_om_geom(expr):
    """Accrochage puis reprojection — sauf qu'il n'y a rien à reprojeter.

    La géométrie est déjà en 4326 : `ST_Transform` serait un geste nul, et
    l'écrire donnerait à croire qu'une conversion a lieu. On accroche, on
    revalide, on sérialise.
    """
    return f"ST_MakeValid(ST_SnapToGrid({expr}, %(pas)s))"


SQL_OM_VERSION = f"""
SELECT g.atom_id,
       ST_AsGeoJSON({sql_om_geom('g.geom')}, %(prec)s)                    AS gj,
       ST_AsGeoJSON(ST_PointOnSurface({sql_om_geom('g.geom')}), %(prec)s) AS pt
FROM   om_atom_geom g
JOIN   om_atom a ON a.atom_id = g.atom_id
WHERE  a.dep = %(dep)s
"""

# Bornes de composition. Pas de troisième famille : la forme d'un atome
# d'outre-mer ne change jamais, donc aucune borne géométrique n'existe. C'est la
# situation de la métropole d'avant `82`, et elle est ici un fait de la source,
# pas un retard de traitement.
SQL_OM_BORNES = """
SELECT DISTINCT d FROM (
    SELECT m.valid_from AS d
    FROM   om_membership m JOIN om_unit u
           ON u.unit_id = m.unit_id AND u.niveau = m.niveau
    WHERE  m.niveau = %(niveau)s AND u.dep = %(dep)s
    UNION ALL
    SELECT m.valid_to
    FROM   om_membership m JOIN om_unit u
           ON u.unit_id = m.unit_id AND u.niveau = m.niveau
    WHERE  m.niveau = %(niveau)s AND u.dep = %(dep)s
    UNION ALL
    SELECT uv.valid_from
    FROM   om_unit_version uv JOIN om_unit u ON u.unit_id = uv.unit_id
    WHERE  u.niveau = %(niveau)s AND u.dep = %(dep)s
    UNION ALL
    SELECT uv.valid_to
    FROM   om_unit_version uv JOIN om_unit u ON u.unit_id = uv.unit_id
    WHERE  u.niveau = %(niveau)s AND u.dep = %(dep)s
) t
"""

# La signature ne couvre QUE la composition, et c'est correct ici alors que ce
# serait un défaut en métropole : sans géométrie datée, deux années de même
# composition dessinent forcément la même carte. Le jeton de forme n'est pas
# omis par simplification, il n'a pas d'objet.
SQL_OM_SIGNATURE = """
SELECT md5(string_agg(m.atom_id || '>' || m.unit_id || '>'
                      || coalesce(uv.nom, u.nom, ''), ',' ORDER BY m.atom_id)) AS sig,
       count(*) AS n
FROM   om_membership m
JOIN   om_unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
LEFT   JOIN om_unit_version uv
       ON uv.unit_id = u.unit_id AND uv.periode @> %(d)s::date
WHERE  m.niveau = %(niveau)s AND u.dep = %(dep)s AND m.periode @> %(d)s::date
"""

# `n_anr` est nul et `n_repli` vaut le compte entier : toute commune d'outre-mer
# est dessinée par un instantané non daté. La page dira donc « 100 % en repli »,
# et ce sera vrai — l'index du département porte `trame: geofla2015` pour
# qu'elle nomme la bonne trame.
SQL_OM_UNITES = f"""
SELECT u.unit_id,
       coalesce(uv.nom, u.nom, u.unit_id)                AS nom,
       u.code,
       u.regime,
       false                                             AS provisoire,
       count(*)                                          AS n_atomes,
       count(*) FILTER (WHERE g.atom_id IS NULL)         AS n_sans_geom,
       count(*) FILTER (WHERE a.multi)                   AS n_partagees,
       0                                                 AS n_anr,
       count(*) FILTER (WHERE g.atom_id IS NOT NULL)     AS n_repli,
       0                                                 AS n_repris,
       array_agg(m.atom_id ORDER BY m.atom_id)           AS atomes,
       ST_AsGeoJSON(
           ST_MakeValid(ST_UnaryUnion(ST_Collect({sql_om_geom('g.geom')}))),
           %(prec)s)                                     AS gj
FROM   om_membership m
JOIN   om_unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
JOIN   om_atom a ON a.atom_id = m.atom_id
LEFT   JOIN om_atom_geom g ON g.atom_id = m.atom_id
LEFT   JOIN om_unit_version uv
       ON uv.unit_id = u.unit_id AND uv.periode @> %(d)s::date
WHERE  m.niveau = %(niveau)s AND u.dep = %(dep)s AND m.periode @> %(d)s::date
GROUP  BY u.unit_id, coalesce(uv.nom, u.nom, u.unit_id), u.code, u.regime
"""

# Le contour de référence, et il ne dépend PAS de la date.
#
# En métropole il est emprunté à une année datée, parce que l'emprise d'un
# département change avec les formes qu'ANR édite. Ici la trame est un
# instantané : l'emprise est la même à toutes les dates, et une seule entrée
# suffit. Elle est écrite sous la première année servie — ou sous 1946, l'année
# où les DOM deviennent départements, quand la base ne sert aucune année.
# La trame d'un territoire, lue sur la forme et non supposée. `40` n'écrit que
# `geofla2015` ; `135` écrit `ispf2021` (Polynésie) et `gnc2024`
# (Nouvelle-Calédonie). Un territoire qui en mêlerait deux le dirait.
SQL_OM_TRAME = """
SELECT string_agg(DISTINCT g.source, '+' ORDER BY g.source)
FROM   om_atom_geom g JOIN om_atom a ON a.atom_id = g.atom_id
WHERE  a.dep = %(dep)s
"""

SQL_OM_CONTOUR = f"""
SELECT ST_AsGeoJSON(
           ST_MakeValid(ST_UnaryUnion(ST_Collect({sql_om_geom('g.geom')}))),
           %(prec)s)
FROM   om_atom_geom g
JOIN   om_atom a ON a.atom_id = g.atom_id
WHERE  a.dep = %(dep)s
"""


# ---------------------------------------------------------------------------
# Nettoyage préalable
#
# Les fichiers de configuration sont nommés d'après la signature de la
# composition (`c_<sig>.json`). Changez quoi que ce soit à ce qui entre dans la
# signature — un nom, une borne, la façon de la calculer — et les nouveaux
# fichiers portent d'autres noms : les anciens restent sur le disque, orphelins.
# Ils ne sont plus référencés par l'index, mais ils traînent, ils pèsent, et
# surtout ils font cohabiter deux générations de schéma dans le même dossier :
# un `communes.json` d'hier à côté d'un `c_*.json` d'aujourd'hui, et la page
# n'a aucun moyen de s'en apercevoir.
#
# On efface donc avant d'écrire, mais seulement ce qu'on va réécrire — un
# export partiel ne doit pas emporter les départements qu'il ne touche pas.
# ---------------------------------------------------------------------------
def nettoie(sortie, deps, tous):
    if not sortie.exists():
        return 0
    # Garde-fou : on ne vide un dossier que s'il ressemble à une sortie de ce
    # script. Un `--sortie` mal tapé ne doit pas effacer autre chose.
    connu = (sortie / "index.json").exists() or (sortie / "dep").is_dir()
    if not connu:
        contenu = [p for p in sortie.iterdir() if not p.name.startswith(".")]
        if contenu:
            print(f"Refus de nettoyer {sortie} : ce dossier ne ressemble pas à "
                  f"une sortie d'export ({len(contenu)} élément(s) inconnus).",
                  file=sys.stderr)
            sys.exit(1)
        return 0

    cibles = []
    if tous:
        cibles.append(sortie / "dep")
        if (sortie / "index.json").exists():
            cibles.append(sortie / "index.json")
    else:
        cibles += [sortie / "dep" / d for d in deps]

    n = 0
    for c in cibles:
        if not c.exists():
            continue
        if c.is_dir():
            n += sum(1 for _ in c.rglob("*") if _.is_file())
            shutil.rmtree(c)
        else:
            n += 1
            c.unlink()
    return n


def serialise(obj):
    return json.dumps(obj, ensure_ascii=False, separators=(",", ":"))


def ecrit(chemin, obj):
    chemin.parent.mkdir(parents=True, exist_ok=True)
    texte = serialise(obj)
    with open(chemin, "w", encoding="utf-8") as f:
        f.write(texte)
    return len(texte.encode("utf-8"))


def existe(cur, table):
    cur.execute("SELECT to_regclass(%s) IS NOT NULL", (f"histgis.{table}",))
    return cur.fetchone()[0]


# ---------------------------------------------------------------------------
# Les versions géométriques d'un département, en deux requêtes et pas une
#
# La première ramène les segments d'ANR. La seconde ne ramène le polygone de
# repli QUE pour les atomes qui en ont besoin quelque part — ceux qu'ANR ne
# pourvoit pas du tout, et ceux dont la couverture a un trou. Demander le repli
# pour tous doublerait la charge utile pour rien : dans un département ordinaire
# l'écrasante majorité des atomes est couverte de bout en bout.
#
# C'est aussi ce qui rend le trou VISIBLE dans le code : la liste des atomes à
# replier est calculée, pas supposée.
# ---------------------------------------------------------------------------
def versions_par_atome(cur, params, atomes_connus, anr):
    segments = {}
    if anr:
        cur.execute(SQL_VERSIONS_ANR, dict(
            params,
            borne_min=f"{AN_MIN:04d}-01-01",
            borne_max=f"{AN_MAX + 1:04d}-01-01"))
        for atom_id, d_debut, d_fin, gj, pt in cur.fetchall():
            if not gj:
                continue
            segments.setdefault(atom_id, []).append(
                (annee_de_borne(d_debut), annee_de_borne(d_fin), gj, pt))

    # Qui a besoin du repli ? Tout atome sans segment, et tout atome dont les
    # segments ne pavent pas AN_MIN..AN_MAX sans trou.
    a_replier = []
    for atom_id in atomes_connus:
        segs = segments.get(atom_id)
        if not segs:
            a_replier.append(atom_id)
            continue
        curseur = AN_MIN
        for d, f, _gj, _pt in segs:
            if max(d, AN_MIN) > curseur:
                a_replier.append(atom_id)
                break
            curseur = max(curseur, min(f, AN_MAX + 1))
        else:
            if curseur <= AN_MAX:
                a_replier.append(atom_id)

    replis = {}
    if a_replier:
        cur.execute(SQL_VERSION_REPLI, dict(params, atomes=a_replier))
        for atom_id, gj, pt in cur.fetchall():
            if gj:
                replis[atom_id] = (gj, pt)

    return {aid: construit_versions(segments.get(aid, []), replis.get(aid))
            for aid in atomes_connus}


def construit_versions_partition(par_annee, annees_geom):
    """[(an, source, gj, pt, idem)] trié -> [{a, k, c, g, r}, …].

    Le pendant de `construit_versions()` pour la trame nettoyée, et il travaille
    à l'envers : là où ANR livre des INTERVALLES qu'il faut paver, `84` livre
    des INSTANTANÉS qu'il faut recoller. Deux instantanés consécutifs
    géométriquement égaux ne font qu'une version — c'est `idem`, calculé en SQL
    par `ST_Equals`, qui le dit ; voir l'en-tête de `SQL_VERSIONS_PARTITION`
    pour ce qui arrive quand on le demande à une empreinte.

    `r` vaut 1 pour le repli GEOFLA résiduel — les atomes qu'ANR ne pourvoit à
    aucune date et qu'aucune reprise ne peut atteindre. La reprise, elle, n'est
    PAS un repli : elle vient de deux polygones datés. Les confondre ferait
    disparaître de la légende la seule vraie faiblesse qui reste.
    """
    versions = []
    for an, source, gj, pt, idem in par_annee:
        repli = 1 if source == 'repli' else 0
        if versions and idem and versions[-1]["r"] == repli:
            continue
        versions.append({
            "a": an,
            "k": hashlib.md5(gj.encode()).hexdigest()[:10] if gj else None,
            "c": json.loads(pt)["coordinates"] if pt else None,
            "g": json.loads(gj) if gj else None,
            "r": repli,
        })
    # Une commune qui n'apparaît qu'à partir de sa deuxième année géométrique
    # doit commencer par un blanc, pas par sa forme reportée en arrière : le
    # curseur ne doit jamais la montrer avant que la base ne la fasse vivre.
    if versions and versions[0]["a"] > AN_MIN and annees_geom:
        versions.insert(0, {"a": AN_MIN, "k": None, "c": None,
                            "g": None, "r": 0})
    return versions


def versions_par_atome_partition(cur, params, atomes_connus, annees_geom):
    """Les versions lues dans `part_dep`, déjà remplie par `prepare_partition`."""
    cur.execute(SQL_VERSIONS_PARTITION, params)
    par_atome = {}
    for atom_id, an, source, gj, pt, idem in cur.fetchall():
        par_atome.setdefault(atom_id, []).append((an, source, gj, pt, idem))
    return {aid: construit_versions_partition(par_atome.get(aid, []), annees_geom)
            for aid in atomes_connus}


def affine_signatures(cfg, gouverne):
    """Ajoute l'année géométrique à la signature d'entrée.

    Sans cela, deux années de même composition mais de partition différente
    partageraient un calcul ET un fichier : la page montrerait la forme d'une
    autre année sans le dire. C'est exactement le défaut que ce fichier nomme
    partout ailleurs, et il revient par la porte de derrière dès qu'une trame
    gagne une dimension que la signature ignore.
    """
    cfg2 = {a: (s + "@" + str(gouverne[a]) if s else "") for a, s in cfg.items()}
    sig2 = {}
    for a in sorted(cfg2):
        if cfg2[a] and cfg2[a] not in sig2:
            sig2[cfg2[a]] = a
    return cfg2, sig2


def exporte_departement(cur, dep, grille, prec, sortie, sql_com, anr,
                        partition=False):
    t0 = time.time()
    base = sortie / "dep" / dep
    params = {"dep": dep, "grille": grille, "prec": prec}
    sql_unites, sql_contour = sql_par_date(anr, partition)

    cfg_canton, sig_canton = configurations(cur, dep, "canton", anr)
    cfg_circo, sig_circo = configurations(cur, dep, "circo", anr)

    if not sig_canton and not sig_circo:
        return None

    # La partition se calcule AVANT tout le reste : les trois requêtes datées
    # la joignent, et `versions_par_atome_partition()` la relit telle quelle.
    annees_geom, gouverne = [], None
    if partition:
        annees_geom = annees_geometriques(cur, dep)
        gouverne = prepare_partition(cur, dep, annees_geom)
        cfg_canton, sig_canton = affine_signatures(cfg_canton, gouverne)
        cfg_circo, sig_circo = affine_signatures(cfg_circo, gouverne)

    def par_date(annee):
        """Les paramètres d'une requête datée : la date, et l'année qui la gouverne."""
        p = dict(params, d=date_ref(annee))
        if partition:
            p["ag"] = gouverne[annee]
        return p

    poids = 0

    # --- communes : attributs, puis chronologie géométrique -----------------
    # Lire AVANT d'interroger la chronologie : `chronologies()` réutilise le
    # même curseur, et un second `execute()` jette le résultat en attente.
    # C'est la recette qui a trouvé celui-là, pas la relecture.
    cur.execute(sql_com, params)
    lignes = cur.fetchall()
    chrono = chronologies(cur, dep)
    if partition:
        versions = versions_par_atome_partition(
            cur, params, [l[0] for l in lignes], annees_geom)
    else:
        versions = versions_par_atome(cur, params, [l[0] for l in lignes], anr)

    communes, n_versions, n_repli_atomes = {}, 0, 0
    for atom_id, insee, cassini, fraction, partagee, nom, disparue in lignes:
        v = versions.get(atom_id) or []
        # Un atome sans la moindre version n'est pas exporté : ni ANR ni
        # `atom_geom` ne savent où il est. `n_sans_geom` le compte par unité.
        if not any(x["g"] for x in v):
            continue
        communes[atom_id] = {
            "i": insee,
            "s": (cassini or "").strip() or None,
            "n": nom,
            "f": 1 if fraction else 0,
            "p": 1 if partagee else 0,
            "d": 1 if disparue else 0,
            # Chronologie géométrique. Chaque version porte son empreinte `k` —
            # la clé de regroupement du projet : « un code est une
            # reconstruction, l'empreinte est un fait » (`archives/planches/cartes_cantons.py`).
            # Elle est maintenant DATÉE : deux atomes peuvent partager un
            # polygone en 1870 et en avoir deux distincts en 1900, ce que la
            # trame de 2011 était incapable de dire.
            "v": v,
        }
        n_versions += len(v)
        if any(x["r"] for x in v):
            n_repli_atomes += 1
        if insee and insee.strip() in chrono:
            communes[atom_id]["nm"] = chrono[insee.strip()]
    poids += ecrit(base / "communes.json", {"dep": dep, "communes": communes})

    # --- une configuration par état distinct de ce qui se dessine ----------
    #
    # DEUX SIGNATURES, ET ELLES NE FONT PAS LE MÊME TRAVAIL.
    #
    # La signature d'ENTRÉE (`sig`, calculée en SQL sur la composition et les
    # `poly_id`) décide quelles années partagent un calcul : c'est elle qui
    # évite de redissoudre 71 fois la même carte.
    #
    # La signature de SORTIE (`md5` du fichier sérialisé) décide quelles années
    # partagent un FICHIER. Elle est nécessaire parce que la première est
    # conservatrice : une commune qui perd un hameau au profit d'une voisine du
    # MÊME canton change de `poly_id` sans changer le contour cantonal d'un
    # pouce. Signer sur l'entrée seule écrirait deux fichiers identiques sous
    # deux noms ; signer sur la sortie les ramène à un.
    #
    # *Une signature d'entrée dit ce qu'il faut recalculer, une signature de
    # sortie dit ce qu'il faut réécrire, et prendre l'une pour l'autre coûte
    # soit des calculs inutiles, soit des fichiers en double.*
    def exporte_configs(sig_annee, niveau, prefixe):
        total = 0
        par_contenu = {}      # empreinte de contenu -> nom court
        renom = {}            # signature d'entrée   -> nom court
        for sig, annee in sorted(sig_annee.items(), key=lambda kv: kv[1]):
            cur.execute(sql_unites, dict(par_date(annee), niveau=niveau))
            unites, rattach = [], {}
            for (uid, nom, code, regime, provisoire, n_at, n_sg,
                 n_part, n_anr, n_repli, n_repris, atomes, gj) in cur.fetchall():
                unites.append({
                    "id": uid, "nom": nom, "code": code, "regime": regime,
                    "prov": 1 if provisoire else 0,
                    "n": n_at, "sans_geom": n_sg, "partagees": n_part,
                    "anr": n_anr, "repli": n_repli, "repris": n_repris,
                    "g": json.loads(gj) if gj else None,
                })
                for a in atomes:
                    rattach[a] = uid
            corps = {"dep": dep, "niveau": niveau,
                     "unites": unites, "rattachement": rattach}
            empreinte = hashlib.md5(serialise(corps).encode()).hexdigest()[:12]
            renom[sig] = empreinte
            if empreinte in par_contenu:
                continue
            par_contenu[empreinte] = annee
            total += ecrit(base / f"{prefixe}_{empreinte}.json",
                           dict(corps, annee_ref=annee))
        return total, renom, len(par_contenu)

    p_c, renom_c, n_fic_c = exporte_configs(sig_canton, "canton", "c")
    p_x, renom_x, n_fic_x = exporte_configs(sig_circo, "circo", "x")
    poids += p_c + p_x

    # --- contours de référence, pour les années sans source ----------------
    # Ce ne sont pas des cartes : juste l'emprise du département, empruntée à
    # une année datée, que la page affiche en grisé et annonce comme empruntée.
    contours = {}
    for annee in sorted(set(sig_canton.values())):
        cur.execute(sql_contour, par_date(annee))
        r = cur.fetchone()
        if r and r[0]:
            contours[str(annee)] = json.loads(r[0])
    poids += ecrit(base / "contours.json", contours)

    # --- index du département ----------------------------------------------
    # Le renommage traduit signature d'entrée -> nom de fichier. Une signature
    # absente de la table donnerait une année pointant vers `c_.json` : la page
    # afficherait « aucune source » pour une année qui en a une, et personne ne
    # saurait pourquoi. On préfère l'échec bruyant.
    def nom_fichier(sig, renom, niveau):
        if not sig:
            return ""
        if sig not in renom:
            raise RuntimeError(
                f"{dep}/{niveau} : signature {sig[:12]} calculée mais jamais "
                f"écrite — l'index pointerait dans le vide.")
        return renom[sig]

    annees = {}
    for a in range(AN_MIN, AN_MAX + 1):
        c, x = cfg_canton[a], cfg_circo[a]
        if c or x:
            annees[str(a)] = {"c": nom_fichier(c, renom_c, "canton"),
                              "x": nom_fichier(x, renom_x, "circo")}
    # Bornes du curseur : premier et dernier millésime que la base sert pour ce
    # département. Déduites des données, jamais posées à la main — un
    # département dont la couverture s'arrête en 1940 doit le montrer.
    servies = sorted(int(a) for a in annees)
    poids += ecrit(base / "index.json", {
        "dep": dep,
        "annees": annees,
        "contours": sorted(int(y) for y in contours),
        "bornes": [servies[0], servies[-1]] if servies else None,
        "absences": [list(x) for x in ABSENCES.get(dep, [])],
        "motifs": list(BORNES_MOTIF.get(dep, (None, None))),
        # Ce que la page doit savoir pour ne pas mentir sur sa propre trame.
        "trame": "partition" if partition else ("anr" if anr else "geofla2011"),
        # Les années où la partition a été recalculée. Utile pour relire un
        # export : si ce tableau est court là où la carte bouge beaucoup, c'est
        # `annees_geometriques()` qu'il faut regarder, pas `84`.
        "annees_geom": annees_geom or None,
    })

    return {
        "dep": dep,
        "bornes": [servies[0], servies[-1]] if servies else None,
        "communes": len(communes),
        "versions": n_versions,
        "repli": n_repli_atomes,
        "cfg_canton": n_fic_c,
        "cfg_circo": n_fic_x,
        "calculs": len(sig_canton) + len(sig_circo),
        "annees": len(annees),
        "octets": poids,
        "secondes": round(time.time() - t0, 1),
    }


def exporte_departement_om(cur, dep, grille, prec, sortie):
    """L'export d'un département d'outre-mer. Même sortie, autre modèle.

    Les fichiers écrits ont EXACTEMENT la forme de ceux de la métropole —
    `communes.json`, `c_<sig>.json`, `x_<sig>.json`, `contours.json`,
    `index.json` — parce que c'est la page qui les lit, et qu'elle n'a pas à
    savoir de quel espace de la base ils sortent. Ce qui change est en amont :
    les tables, la projection, et l'absence de dimension temporelle sur la
    forme.

    UNE DIFFÉRENCE DE COMPORTEMENT, ET ELLE EST DÉLIBÉRÉE. La fonction
    métropolitaine rend `None` — « aucune unité, ignoré » — quand aucune
    signature n'est calculée. Ici, un département sans le moindre rattachement
    est tout de même écrit, avec ses communes et son contour, et zéro année
    servie. C'est le cas de Mayotte. Le renvoyer à `None` la ferait disparaître
    du sélecteur, et le lecteur conclurait que le projet ne connaît pas
    Mayotte — alors que la base porte ses dix-sept communes et ses seize
    cantons, et que ce qui manque est le fichier qui les relie. *Un département
    vide et un département absent ne disent pas la même chose, et c'est le
    premier qui est vrai.*
    """
    t0 = time.time()
    base = sortie / "dep" / dep
    cur.execute(SQL_OM_TRAME, {"dep": dep})
    trame = (cur.fetchone() or [None])[0] or "geofla2015"
    pas_m = min(grille, PAS_TRAME_M.get(trame, grille))
    params = {"dep": dep, "pas": pas_m * DEG_PAR_M, "prec": prec}
    an_debut = AN_DEBUT_DOM.get(dep, AN_DOM)

    def par_annee_signature(niveau):
        """année -> signature, et signature -> année de référence.

        PAS DE GRAINE À `AN_MIN`, contrairement à `annees_candidates()`. La
        version métropolitaine échantillonne 1815 d'office, parce que Paris y
        commence et qu'une année candidate de moins serait une planche perdue.
        Outre-mer, rien ne commence avant le 19 mars 1946 : interroger 1815
        coûte une requête qui rend toujours zéro ligne, et c'est le SEUL chemin
        par lequel un département pourrait se déclarer servi depuis 1815. Une
        graine qui ne peut rien produire de vrai ne peut produire que du faux.
        """
        cand = set()
        cur.execute(SQL_OM_BORNES, {"dep": dep, "niveau": niveau})
        for (d,) in cur.fetchall():
            if d is not None:
                y = annee_de_borne(d)
                if AN_MIN <= y <= AN_MAX:
                    cand.add(y)
        par_annee, sig_annee, courante = {}, {}, None
        for annee in range(AN_MIN, AN_MAX + 1):
            if annee in cand:
                cur.execute(SQL_OM_SIGNATURE,
                            {"dep": dep, "niveau": niveau, "d": date_ref(annee)})
                sig, n = cur.fetchone()
                courante = sig if (sig and n) else ""
                if courante and courante not in sig_annee:
                    sig_annee[courante] = annee
            par_annee[annee] = courante or ""
        return par_annee, sig_annee

    cfg_canton, sig_canton = par_annee_signature("canton")
    cfg_circo, sig_circo = par_annee_signature("circo")

    poids = 0

    # --- communes -----------------------------------------------------------
    # Lire les attributs AVANT la géométrie : même curseur, et un second
    # `execute()` jette le résultat en attente. C'est la recette de la
    # métropole qui a trouvé ce piège-là ; il ne coûte rien de ne pas le
    # reproduire.
    cur.execute(SQL_OM_ATOMES, params)
    lignes = cur.fetchall()
    cur.execute(SQL_OM_VERSION, params)
    formes = {atom_id: (gj, pt) for atom_id, gj, pt in cur.fetchall() if gj}

    communes = {}
    for atom_id, insee, cassini, fraction, partagee, nom, disparue in lignes:
        paire = formes.get(atom_id)
        if not paire:
            # Sans polygone, l'atome n'est pas exporté — comme en métropole.
            # `n_sans_geom` le compte par unité, et il vaut zéro tant que
            # `om_atom_geom` reste peuplée depuis la même source que `om_atom`.
            continue
        gj, pt = paire
        p = json.loads(pt)["coordinates"] if pt else None
        communes[atom_id] = {
            "i": insee,
            "s": None,                      # pas de code Cassini outre-mer
            "n": nom,
            "f": 0,                         # pas d'atome-fraction
            "p": 1 if partagee else 0,      # multicantonale, tracé à faire
            "d": 0,                         # trame contemporaine de la période
            # UNE SEULE VERSION, ET `r: 1`. La forme ne change jamais : elle
            # vaut donc de la départementalisation à la fin. `r: 1` dit qu'elle
            # ne vient pas d'une source datée — la même déclaration que le repli
            # de la métropole, pour la même raison, et la page l'affiche déjà.
            # C'est aussi ce que fait `--sans-anr` en métropole, où TOUTES les
            # communes portent `r: 1` : le chemin d'outre-mer ne s'invente pas
            # une convention, il applique celle qui existe.
            #
            # `an_debut` ET NON `AN_MIN` : la version ne commence pas avant le
            # département. Un curseur poussé à 1900 sur Mayotte ne doit rien
            # dessiner du tout, pas dessiner la trame de 2015 — et cela se règle
            # ici, où la donnée est écrite, plutôt que par une garde dans la
            # page, qu'un futur lecteur pourrait retirer sans savoir ce qu'elle
            # retenait.
            "v": [{"a": an_debut, "k": hashlib.md5(gj.encode()).hexdigest()[:10],
                   "c": [round(p[0], 5), round(p[1], 5)] if p else None,
                   "g": json.loads(gj), "r": 1}],
        }
    poids += ecrit(base / "communes.json", {"dep": dep, "communes": communes})

    # --- configurations -----------------------------------------------------
    # Même dédoublonnage par contenu qu'en métropole : la signature d'entrée dit
    # ce qu'il faut recalculer, l'empreinte de sortie ce qu'il faut réécrire.
    def exporte_configs(sig_annee, niveau, prefixe):
        total, par_contenu, renom = 0, {}, {}
        for sig, annee in sorted(sig_annee.items(), key=lambda kv: kv[1]):
            cur.execute(SQL_OM_UNITES,
                        dict(params, d=date_ref(annee), niveau=niveau))
            unites, rattach = [], {}
            for (uid, nom, code, regime, provisoire, n_at, n_sg,
                 n_part, n_anr, n_repli, n_repris, atomes, gj) in cur.fetchall():
                unites.append({
                    "id": uid, "nom": nom, "code": code, "regime": regime,
                    "prov": 1 if provisoire else 0,
                    "n": n_at, "sans_geom": n_sg, "partagees": n_part,
                    "anr": n_anr, "repli": n_repli, "repris": n_repris,
                    "g": json.loads(gj) if gj else None,
                })
                for a in atomes:
                    rattach[a] = uid
            corps = {"dep": dep, "niveau": niveau,
                     "unites": unites, "rattachement": rattach}
            empreinte = hashlib.md5(serialise(corps).encode()).hexdigest()[:12]
            renom[sig] = empreinte
            if empreinte in par_contenu:
                continue
            par_contenu[empreinte] = annee
            total += ecrit(base / f"{prefixe}_{empreinte}.json",
                           dict(corps, annee_ref=annee))
        return total, renom, len(par_contenu)

    p_c, renom_c, n_fic_c = exporte_configs(sig_canton, "canton", "c")
    p_x, renom_x, n_fic_x = exporte_configs(sig_circo, "circo", "x")
    poids += p_c + p_x

    # --- contour de référence, une seule entrée ----------------------------
    annees = {}
    for a in range(AN_MIN, AN_MAX + 1):
        c, x = cfg_canton[a], cfg_circo[a]
        if c or x:
            if c and c not in renom_c:
                raise RuntimeError(f"{dep}/canton : signature calculée mais "
                                   f"jamais écrite — l'index pointerait dans le vide.")
            if x and x not in renom_x:
                raise RuntimeError(f"{dep}/circo : signature calculée mais "
                                   f"jamais écrite — l'index pointerait dans le vide.")
            annees[str(a)] = {"c": renom_c[c] if c else "",
                              "x": renom_x[x] if x else ""}
    servies = sorted(int(a) for a in annees)

    contours = {}
    cur.execute(SQL_OM_CONTOUR, params)
    r = cur.fetchone()
    if r and r[0]:
        contours[str(servies[0] if servies else an_debut)] = json.loads(r[0])
    poids += ecrit(base / "contours.json", contours)

    poids += ecrit(base / "index.json", {
        "dep": dep,
        "annees": annees,
        "contours": sorted(int(y) for y in contours),
        "bornes": [servies[0], servies[-1]] if servies else None,
        "absences": [list(x) for x in ABSENCES.get(dep, [])],
        "motifs": list(BORNES_MOTIF.get(dep, (None, None))),
        # La page lit d'abord la trame du DÉPARTEMENT, l'index racine ensuite :
        # c'est ce qui lui permet de dire « GEOFLA 2015 » ici et « partition »
        # sur l'Ain sans se contredire.
        "trame": trame,
        "annees_geom": None,
        # Déclaré dans le fichier plutôt que déduit par la page : l'outre-mer
        # est un autre espace de la base, et une carte qui ne dit pas d'où elle
        # vient laisse croire qu'elle vient d'ailleurs.
        "espace": "outremer",
        # LA PÉRIODE OÙ LE DÉPARTEMENT EXISTE, qui n'est pas celle où la base
        # sert quelque chose. `bornes` dit ce que la base tient ; `existence`
        # dit ce que l'histoire tient. Les confondre donnerait à Mayotte, dont
        # `bornes` est nul, le curseur par défaut de la page — 1815-2012.
        "existence": [an_debut, AN_MAX],
    })

    return {
        "dep": dep,
        "bornes": [servies[0], servies[-1]] if servies else None,
        "communes": len(communes),
        "versions": len(communes),
        "repli": len(communes),
        "cfg_canton": n_fic_c,
        "cfg_circo": n_fic_x,
        "calculs": len(sig_canton) + len(sig_circo),
        "annees": len(annees),
        "octets": poids,
        "secondes": round(time.time() - t0, 1),
    }


# ---------------------------------------------------------------------------
# Un processus par département
#
# Le partage se fait par département et pas plus finement, pour une raison de
# correction et pas de commodité : un département est la seule unité qui écrive
# dans un dossier à elle. Deux processus qui se partageraient les configurations
# d'un même département devraient s'accorder sur le dédoublonnage par contenu —
# donc se parler — et le premier bogue serait un fichier écrit deux fois sous
# deux noms.
#
# Chaque worker ouvre SA connexion. Une connexion psycopg2 ne se transmet pas
# par `fork` : les descripteurs seraient partagés, et deux processus liraient à
# tour de rôle la réponse de l'autre. D'où l'`initializer`, qui connecte APRÈS
# le fork, et le fait une fois par processus plutôt qu'une fois par département.
# ---------------------------------------------------------------------------
_W = {}


def _init_worker(dsn, grille, prec, sortie, sql_com, anr, partition, role,
                 om=False):
    # `--partition` a besoin de créer des tables temporaires : voir `connecte`.
    _W["conn"] = (dsn, not partition, role)     # de quoi rouvrir, voir _reconnecte
    _W["cx"] = connecte(dsn, readonly=not partition, role=role)
    _W["cur"] = _W["cx"].cursor()
    _W["params"] = (grille, prec, sortie, sql_com, anr, partition, om)


def _reconnecte():
    """Rouvre la connexion du worker. Rend True si elle est de nouveau utilisable.

    Sert le cas où le SERVEUR est tombé, pas où le département est mauvais :
    un backend qui meurt fait redémarrer le postmaster, qui coupe TOUTES les
    sessions. Sans reconnexion, les quatre-vingt-dix départements suivants
    échouent chacun sur « cursor already closed » — quatre-vingt-dix lignes
    d'écho pour une seule panne, et la vraie cause en tête de journal là où
    personne ne la cherche.
    """
    for c in ("cur", "cx"):
        try:
            if _W.get(c):
                _W[c].close()
        except Exception:                       # noqa: BLE001
            pass
    dsn, readonly, role = _W["conn"]
    try:
        _W["cx"] = connecte(dsn, readonly=readonly, role=role)
        _W["cur"] = _W["cx"].cursor()
        return True
    except SystemExit:
        # `connecte()` sort du processus quand plus rien ne répond : dans un
        # worker, ce serait une mort silencieuse. On la convertit en échec.
        return False
    except Exception:                           # noqa: BLE001
        return False


def _fait_un(dep):
    grille, prec, sortie, sql_com, anr, partition, om = _W["params"]
    for essai in (1, 2):
        try:
            if om:
                r = exporte_departement_om(_W["cur"], dep, grille, prec, sortie)
            else:
                r = exporte_departement(_W["cur"], dep, grille, prec,
                                        sortie, sql_com, anr, partition)
            # UNE CONNEXION NEUVE PAR DÉPARTEMENT, en `--partition`, et c'est
            # une correction de fuite plus qu'une hygiène.
            #
            # Un worker garde sa connexion pour la vingtaine de départements
            # qu'il traite. Le backend PostgreSQL en face accumule alors le
            # PLUS HAUT niveau de mémoire atteint depuis son ouverture :
            # `84` alloue des gigaoctets dans GEOS, PostgreSQL les libère à la
            # fin de chaque requête, mais l'allocateur de la glibc ne les rend
            # pas au système. Mesuré le 3 septembre 2026 : un backend à
            # **12,7 Go** après une vingtaine de départements, et l'OOM killer
            # du noyau qui abat le cluster entier.
            #
            # Fermer la connexion détruit le backend et rend la mémoire. Le
            # coût est de quelques millisecondes par département, contre
            # plusieurs minutes de travail : il ne se mesure pas.
            #
            # *Une fuite qui n'est pas dans votre code peut quand même être
            # dans votre architecture : c'est la durée de vie du processus qui
            # décide de ce qu'une non-restitution finit par coûter.*
            if partition:
                _reconnecte()
            # Le résultat revient hors ordre : il doit porter son département,
            # sinon un « ignoré » anonyme n'apprend rien à personne.
            return r if r is not None else {"dep": dep, "vide": True}
        except (psycopg2.OperationalError, psycopg2.InterfaceError) as e:
            # La connexion est morte. Une fois, on rouvre et on recommence ce
            # département ; deux fois, c'est le serveur qui ne revient pas et
            # il faut le dire plutôt que d'insister.
            if essai == 1 and _reconnecte():
                continue
            return {"dep": dep, "erreur": f"{type(e).__name__}: {e}",
                    "connexion": True}
        except Exception as e:                  # noqa: BLE001
            # Un département qui échoue ne doit pas emporter l'export entier
            # ni, pire, passer inaperçu : on rend l'erreur comme une donnée et
            # le parent la compte.
            return {"dep": dep, "erreur": f"{type(e).__name__}: {e}"}


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("deps", nargs="*", help="codes de départements (défaut : tous)")
    ap.add_argument("--grille", type=float, default=25.0,
                    help="accrochage en mètres, Lambert-93 (défaut 25)")
    ap.add_argument("--precision", type=int, default=5,
                    help="décimales des coordonnées en degrés (défaut 5, ~1 m)")
    ap.add_argument("--sortie", type=Path, default=SORTIE)
    ap.add_argument("--dsn", default=None,
                    help="chaîne de connexion explicite (défaut : essais successifs)")
    ap.add_argument("--garder", action="store_true",
                    help="ne pas effacer l'export précédent (laisse des orphelins)")
    ap.add_argument("--jobs", "-j", type=int, default=0,
                    help="départements traités de front (défaut : cœurs/2, "
                         "plafonné à 8 ; 1 pour séquentiel)")
    ap.add_argument("--sans-anr", action="store_true",
                    help="ignorer atom_geom_anr et exporter la trame GEOFLA "
                         "2011 seule, sans épaisseur temporelle")
    ap.add_argument("--forcer-trame", action="store_true",
                    help="autoriser un export à écraser une sortie produite "
                         "avec une autre trame (voir le garde-fou de main())")
    ap.add_argument("--role", default=None,
                    help="prendre ce rôle après connexion (SET ROLE). Rend au "
                         "moteur la garantie que --partition retire au mode "
                         "lecture seule : voir la docstring de connecte()")
    ap.add_argument("--partition", action="store_true",
                    help="trame nettoyée de sql/84_carte_partition.sql : sans "
                         "trou ni superposition hors fractions. Quatre fois "
                         "plus lent ; à comparer à l'export ordinaire avant "
                         "de le remplacer (voir --sortie)")
    ap.add_argument("--outremer", action="store_true",
                    help="exporter l'outre-mer (tables om_*, EPSG:4326) au "
                         "lieu de la métropole. S'AJOUTE à un export "
                         "métropolitain existant sans l'effacer : les deux "
                         "espaces cohabitent dans le même dossier")
    args = ap.parse_args()

    cx = connecte(args.dsn, role=args.role)
    cur = cx.cursor()

    # --- outre-mer : un espace, des tables, et un refus franc s'il manque ---
    #
    # `40_outremer.sql` n'a longtemps été appelé par rien (son prérequis
    # `om_commune_src` venait de `charger_outremer.sh`, que la chaîne
    # n'invoquait pas — voir `RESTE_A_FAIRE.md`). Une base parfaitement à jour
    # côté métropole peut donc ne pas avoir une seule table `om_*`. On le dit
    # tout de suite, avec la commande à jouer, plutôt que d'échouer au premier
    # département sur une table absente.
    if args.outremer:
        manquantes = [t for t in ("om_atom", "om_atom_geom", "om_unit",
                                  "om_unit_version", "om_membership")
                      if not existe(cur, t)]
        if manquantes:
            sys.exit(
                "--outremer demandé, mais la base ne porte pas "
                f"{', '.join(manquantes)}.\n"
                "  L'outre-mer vit dans un espace séparé, à charger en deux "
                "temps :\n"
                "    bash sql/charger_outremer.sh\n"
                "    psql -d histgis -f sql/40_outremer.sql\n"
                "  (le second lit `circo/circo_outremer_1986_2012.csv` depuis "
                "la racine du dépôt).")
        if args.partition:
            sys.exit("--outremer et --partition sont incompatibles : `84` ne "
                     "traite que la métropole, et l'outre-mer n'a pas de "
                     "trame ANR à nettoyer.")

    if args.deps:
        deps = [d.upper() for d in args.deps]
    elif args.outremer:
        # Depuis `om_atom` et non `om_unit` : Mayotte a des cantons sans
        # rattachement, mais ce sont ses COMMUNES qui décident qu'il y a
        # quelque chose à dessiner.
        cur.execute("SELECT DISTINCT dep FROM om_atom ORDER BY dep")
        deps = [r[0].strip() for r in cur.fetchall()]
    else:
        cur.execute("SELECT DISTINCT dep FROM unit ORDER BY dep")
        deps = [r[0].strip() for r in cur.fetchall()]

    dico = existe(cur, "noms_geofla")
    geofla = existe(cur, "geofla_commune")
    mvt = existe(cur, "insee_mvt")
    anr = existe(cur, "atom_geom_anr") and not args.sans_anr
    # `--partition` sans `84` en base serait une erreur au premier département,
    # après le nettoyage et à moitié du travail. Mieux vaut refuser tout de
    # suite, et dire quoi jouer.
    partition = args.partition
    if partition:
        cur.execute("SELECT to_regprocedure("
                    "'histgis.carte_partition_atome(date, text)') IS NOT NULL")
        if not cur.fetchone()[0]:
            sys.exit("--partition demandé, mais `carte_partition_atome` est "
                     "absente : jouer d'abord `psql -d histgis -f "
                     "sql/84_carte_partition.sql`.")
        if not anr:
            sys.exit("--partition suppose la trame ANR : incompatible avec "
                     "--sans-anr, et inutile sans `82`.")
    anr_nom = existe(cur, "anr_commune")
    sql_com = sql_communes(dico, geofla, mvt, anr_nom)
    if not anr_nom:
        print("Attention : `anr_commune` absente — les communes sans code INSEE "
              "(les onze annexées de 1860) sortiront sans nom.")
    if not (dico or geofla):
        print("Attention : ni `noms_geofla` ni `geofla_commune` — les communes "
              "sortiront sous leur code.")
    if not mvt:
        print("Attention : `insee_mvt` absente — pas de chronologie des noms, "
              "et pas de repli pour les communes disparues avant 2011.")
    if anr and not args.outremer:
        cur.execute("SELECT count(*), count(DISTINCT atom_id) FROM atom_geom_anr")
        n_poly, n_at = cur.fetchone()
        print(f"Trame ANR-COMMUNES : {n_poly} polygones datés sur {n_at} atomes "
              f"(repli sur atom_geom ailleurs).")
    if args.outremer:
        cur.execute("SELECT count(*) FROM om_atom")
        n_com = cur.fetchone()[0]
        cur.execute("SELECT count(*) FROM om_membership")
        n_rat = cur.fetchone()[0]
        cur.execute("SELECT count(*) FROM om_atom a WHERE a.multi")
        n_multi = cur.fetchone()[0]
        cur.execute("SELECT count(*) FROM om_atom a WHERE NOT EXISTS "
                    "(SELECT 1 FROM om_membership m WHERE m.atom_id = a.atom_id)")
        n_orph = cur.fetchone()[0]
        print(f"ESPACE OUTRE-MER : {n_com} communes, {n_rat} rattachements, "
              f"trame GEOFLA 2015 en EPSG:4326, sans épaisseur temporelle.")
        print(f"  {n_multi} communes multicantonales que GEOFLA ne découpe pas "
              f"(hachurées, tracé à faire sur la trame IRIS `iris_om`).")
        if n_orph:
            # Annoncé AVANT l'export et non déduit après : un lecteur qui voit
            # un département vide doit savoir d'avance que c'est un fait de la
            # source et non une panne de ce script.
            print(f"  {n_orph} communes n'ont AUCUN rattachement — Mayotte est "
                  f"absente du fichier du ministère qui les pose. Elles seront "
                  f"dessinées sans couleur, et leur département servira zéro "
                  f"année : c'est le trou, pas son maquillage.")
    if partition:
        print("Trame NETTOYÉE (--partition) : `84` recalcule la partition à "
              "chaque année géométrique — sans trou ni superposition hors "
              "fractions. Comptez environ quatre fois le temps ordinaire.")
        if args.role:
            print(f"  Connexion en lecture-écriture, mais sous le rôle "
                  f"`{args.role}` : c'est le moteur qui refuse les écritures, "
                  f"pas seulement le code.")
        else:
            print("  Connexion en LECTURE-ÉCRITURE : `84` crée des tables "
                  "temporaires, et une transaction READ ONLY interdit tout "
                  "DDL, même temporaire. Rien n'est écrit dans le modèle — "
                  "mais la garantie vient du code, pas du moteur. Pour la lui "
                  "rendre : --role histgis_carte (voir `connecte()`).")
    elif args.sans_anr:
        print("Trame GEOFLA 2011 seule (--sans-anr) : pas d'épaisseur temporelle.")
    elif not anr and not args.outremer:
        # `elif not anr` et non `else` : la branche disait « atom_geom_anr
        # absente » chaque fois que l'export tournait avec la trame ANR sans
        # `--partition`, c'est-à-dire dans le cas le plus courant. Corrigé le
        # 6 septembre 2026. *Un avertissement qui se déclenche quand tout va
        # bien apprend à ne plus lire les avertissements.*
        print("Attention : `atom_geom_anr` absente — trame GEOFLA 2011 seule, "
              "sans épaisseur temporelle. Jouer `sql/82_anr_geom.sql` pour "
              "l'obtenir.")
    cur.close()
    cx.close()

    # NE PAS RECOUVRIR EN SILENCE UNE TRAME NETTOYÉE PAR UNE TRAME À COUTURE.
    # Une fois `sorties/part` promu en `cartes/web/donnees`, un
    # `python3 cartes/export_web.py` sans drapeau — le réflexe de tous les mois
    # précédents — réécrirait la carte avec `coalesce(ANR, atom_geom)` et lui
    # rendrait ses 4 542,8 km² de couture. Rien dans la sortie ne le dirait :
    # le nombre de fichiers, leur nom, leur poids seraient plausibles.
    #
    # *Le jour où un drapeau change le sens du résultat, son oubli devient un
    # défaut silencieux ; c'est à ce moment-là qu'il faut un garde-fou, pas
    # quand on l'ajoute.*
    #
    # `--outremer` EST EXEMPTÉ, ET CE N'EST PAS UNE DÉROGATION DE CONFORT.
    # Le garde-fou protège contre le fait de RECOUVRIR une trame nettoyée par
    # une trame à couture. Un export d'outre-mer ne recouvre rien : il n'écrit
    # que `dep/97x/`, il ne touche à aucun département métropolitain, et il ne
    # PEUT pas porter la trame `partition` — `84` ne traite que la métropole,
    # et l'outre-mer n'a pas d'ANR à nettoyer. Le dossier portera donc
    # légitimement deux trames, ce que le bloc `mixte` plus bas déclare
    # département par département. *Un garde-fou qui interdit ce qu'il n'a pas
    # été écrit pour interdire finit par se faire désarmer d'un --forcer, et
    # c'est ce jour-là qu'il cesse de protéger.*
    ancien_index = args.sortie / "index.json"
    if not partition and not args.outremer and ancien_index.exists():
        try:
            vieille = json.loads(
                ancien_index.read_text(encoding="utf-8")).get("trame")
        except (json.JSONDecodeError, OSError):
            vieille = None
        if vieille in ("partition", "mixte") and not args.forcer_trame:
            sys.exit(
                f"ARRÊT : {args.sortie} porte la trame « {vieille} », et cet "
                f"appel produirait la trame hybride.\n"
                f"  Réécrire par-dessus rendrait à la carte la couture que "
                f"`84` en a ôtée, sans que rien ne le signale.\n"
                f"  Si c'est voulu : --forcer-trame. Sinon, ajouter "
                f"--partition (et --role si la base l'exige).")

    jobs = args.jobs or min(8, max(1, (os.cpu_count() or 2) // 2))
    jobs = max(1, min(jobs, len(deps)))
    print(f"{len(deps)} département(s) à exporter, grille {args.grille} m, "
          f"{jobs} processus.")

    # Séquentiel dans le parent : le nettoyage efface des dossiers que les
    # workers vont écrire, et le faire pendant qu'ils écrivent serait une course.
    #
    # `tous` EST FAUX EN OUTRE-MER MÊME SANS LISTE DE DÉPARTEMENTS, et c'est la
    # ligne la plus dangereuse de ce bloc. `tous=True` efface `dep/` en entier.
    # Un `--outremer` sans argument aurait donc emporté les 95 départements
    # métropolitains pour en réécrire 5 — un export complet détruit par une
    # commande qui a l'air d'en ajouter. L'outre-mer est toujours un export
    # PARTIEL du dossier, quelle que soit la façon dont on l'appelle.
    if not args.garder:
        partiel = bool(args.deps) or args.outremer
        n = nettoie(args.sortie, deps, tous=not partiel)
        if n:
            print(f"  {n} fichier(s) de l'export précédent effacé(s)"
                  f"{'' if not partiel else ' (départements demandés seulement)'}.")
    args.sortie.mkdir(parents=True, exist_ok=True)

    t_debut = time.time()
    init = (args.dsn, args.grille, args.precision, args.sortie, sql_com, anr,
            partition, args.role, args.outremer)
    if jobs == 1:
        _init_worker(*init)
        resultats = map(_fait_un, deps)
    else:
        ctx = mp.get_context("spawn")   # `fork` + psycopg2 = descripteurs partagés
        pool = ctx.Pool(jobs, initializer=_init_worker, initargs=init)
        resultats = pool.imap_unordered(_fait_un, deps)

    rapport, total, echecs = [], 0, []
    for i, r in enumerate(resultats, 1):
        if r is None or r.get("vide"):
            dep = (r or {}).get("dep", "?")
            print(f"  [{i:>3}/{len(deps)}] {dep} — aucune unité, ignoré")
            continue
        if "erreur" in r:
            echecs.append(r)
            print(f"  [{i:>3}/{len(deps)}] {r['dep']} — ÉCHEC : {r['erreur']}",
                  file=sys.stderr)
            continue
        rapport.append(r)
        total += r["octets"]
        repli = f", {r['repli']} en repli" if r["repli"] else ""
        print(f"  [{i:>3}/{len(deps)}] {r['dep']} — {r['communes']:>4} communes "
              f"({r['versions']:>5} versions{repli}), "
              f"{r['cfg_canton']:>3} config. cantonales, {r['cfg_circo']:>3} circo, "
              f"{r['annees']:>4} années servies, {r['octets']/1e6:>6.2f} Mo, "
              f"{r['secondes']:>5.1f} s")
    if jobs > 1:
        pool.close()
        pool.join()

    # --- index racine -------------------------------------------------------
    index = {"genere": time.strftime("%Y-%m-%d %H:%M"),
             "an_min": AN_MIN, "an_max": AN_MAX,
             "grille_m": args.grille,
             # National, donc dans l'index racine et non par département :
             # l'absence de circonscriptions en 1941-1945 vaut pour la France
             # entière. Voir le commentaire d'ABSENCES_CIRCO.
             "absences_circo": [list(x) for x in ABSENCES_CIRCO],
             # La trame vaut pour tout l'export : la page l'annonce en légende
             # plutôt que de laisser croire à une trame d'époque partout.
             "trame": ("geofla2015" if args.outremer
                       else "partition" if partition
                       else "anr" if anr else "geofla2011"),
             "departements": []}
    for r in rapport:
        index["departements"].append({
            "code": r["dep"],
            "nom": nom_dep(r["dep"], 1900),
            "noms": (NOMS_DEP.get(r["dep"]) if isinstance(NOMS_DEP.get(r["dep"]), list)
                     else None),
            "communes": r["communes"],
            "annees": r["annees"],
            "bornes": r["bornes"],
        })
    # Export partiel : l'index racine doit continuer à annoncer les
    # départements qu'on n'a pas touchés, sinon ils disparaissent du sélecteur
    # alors que leurs fichiers sont toujours là.
    # `or args.outremer` : sans lui, un export d'outre-mer rendrait un index
    # racine de cinq départements, et les 95 métropolitains disparaîtraient du
    # sélecteur alors que leurs fichiers sont intacts sur le disque. C'est le
    # même raisonnement que pour `nettoie()` ci-dessus, et la même cause : un
    # export d'outre-mer est PARTIEL par nature, jamais complet.
    if args.deps or args.outremer:
        ancien = args.sortie / "index.json"
        if ancien.exists():
            try:
                vieux = json.loads(ancien.read_text(encoding="utf-8"))
            except (json.JSONDecodeError, OSError):
                vieux = {}
            refaits = {d["code"] for d in index["departements"]}
            for d in vieux.get("departements", []):
                if d.get("code") not in refaits and \
                   (args.sortie / "dep" / d.get("code", "") / "index.json").exists():
                    index["departements"].append(d)
    index["departements"].sort(key=lambda d: d["code"])

    # UN DOSSIER NE DOIT PAS MÊLER DEUX TRAMES SANS LE DIRE. Un export partiel
    # avec `--partition` par-dessus un export ordinaire laisse côte à côte des
    # départements nettoyés et des départements à couture, sous un index racine
    # qui n'annonce qu'une trame — la dernière écrite. La page dirait alors de
    # l'Ain ce qui n'est vrai que de lui, et de la Drôme ce qui est faux d'elle.
    #
    # On lit donc la trame réelle de chaque département sur son propre index et
    # on refuse de résumer ce qui ne se résume pas.
    trames = {}
    for d in index["departements"]:
        f = args.sortie / "dep" / d["code"] / "index.json"
        try:
            trames[d["code"]] = json.loads(
                f.read_text(encoding="utf-8")).get("trame", "?")
        except (json.JSONDecodeError, OSError):
            trames[d["code"]] = "?"
    distinctes = sorted(set(trames.values()))
    if len(distinctes) > 1:
        index["trame"] = "mixte"
        index["trames"] = {k: v for k, v in sorted(trames.items())}
        print(f"\nATTENTION : ce dossier mêle {len(distinctes)} trames "
              f"({', '.join(distinctes)}).", file=sys.stderr)
        for t in distinctes:
            n = sum(1 for v in trames.values() if v == t)
            print(f"  {t:12s} {n:3d} département(s)", file=sys.stderr)
        print("  L'index racine porte `trame: mixte` et le détail par "
              "département dans `trames`. Une carte qui mêle deux trames n'est "
              "pas fausse, mais elle ne peut pas se résumer en légende.",
              file=sys.stderr)

    ecrit(args.sortie / "index.json", index)

    ecoule = time.time() - t_debut
    cumul = sum(r["secondes"] for r in rapport)
    n_repli = sum(r["repli"] for r in rapport)
    n_com = sum(r["communes"] for r in rapport)
    print(f"\n{len(rapport)} départements écrits, {total/1e6:.1f} Mo au total.")
    print(f"{ecoule:.0f} s de mur pour {cumul:.0f} s de travail cumulé "
          f"(×{cumul/ecoule:.1f} sur {jobs} processus).")
    if args.outremer and n_com:
        vides = [r["dep"] for r in rapport if not r["bornes"]]
        print(f"Trames GEOFLA 2015, ISPF et data.gouv.nc : les {n_com} "
              f"communes d'outre-mer sont "
              f"dessinées par un instantané sans épaisseur temporelle — toutes "
              f"portent `r: 1`, et c'est exact.")
        if vides:
            print(f"Département(s) sans une seule année servie : "
                  f"{' '.join(vides)}. Leurs communes sont dessinées, aucune "
                  f"n'est rattachée : le fichier du ministère qui pose les "
                  f"rattachements ne les contient pas.")
    elif anr and n_com:
        print(f"Trame hybride : {n_repli} atomes sur {n_com} ({100*n_repli/n_com:.1f} %) "
              f"retombent sur atom_geom au moins une année — fractions, report "
              f"arrière de `11`, et trous de chronologie d'ANR.")
    # Un échec silencieux serait pire qu'un export absent : le dossier
    # ressemblerait à un export complet.
    if echecs:
        print(f"\n{len(echecs)} département(s) EN ÉCHEC — l'export est "
              f"incomplet :", file=sys.stderr)
        # Groupé par message : quand le serveur tombe, quatre-vingt-dix
        # départements portent la MÊME erreur, et les lister un par un enterre
        # la seule ligne qui apprend quelque chose.
        par_msg = {}
        for e in echecs:
            par_msg.setdefault(e["erreur"].strip(), []).append(e["dep"])
        for msg, deps_ in sorted(par_msg.items(), key=lambda kv: -len(kv[1])):
            court = msg.splitlines()[0]
            print(f"  {len(deps_):3d} département(s) : {court}", file=sys.stderr)
            print(f"      {' '.join(sorted(deps_))}", file=sys.stderr)
        if any(e.get("connexion") for e in echecs):
            print("\n  Au moins un échec vient de la CONNEXION, pas du "
                  "département : le serveur a coupé et n'est pas revenu.\n"
                  "  Lire le journal de PostgreSQL AVANT de conclure, et "
                  "distinguer deux causes qui ne se corrigent pas pareil :\n"
                  "    « received fast shutdown request » — on a DEMANDÉ "
                  "l'arrêt du service. Mise à jour de paquet, veille, ou "
                  "`systemd-oomd`, qui arrête proprement une unité sous "
                  "pression mémoire et ne ressemble donc pas à un OOM.\n"
                  "    « terminated by signal 9 » venant du NOYAU — l'OOM "
                  "killer, et là seul --jobs compte.\n"
                  "  Pour une passe longue, préférer `cartes/export_partition.sh` : "
                  "il travaille par lots et reprend où il s'est arrêté.",
                  file=sys.stderr)
        print("\n  Relancer les manquants sans refaire le reste :\n"
              f"    python3 cartes/export_web.py {' '.join(sorted(e['dep'] for e in echecs))} \\\n"
              f"        --partition --sortie {args.sortie}"
              + (f" --role {args.role}" if args.role else ""),
              file=sys.stderr)
    print(f"Sortie : {args.sortie}")
    print("Servir la page :  python3 cartes/web/servir.py")
    if echecs:
        sys.exit(1)


if __name__ == "__main__":
    main()
