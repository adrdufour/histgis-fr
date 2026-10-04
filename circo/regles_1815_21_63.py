# -*- coding: utf-8 -*-
"""
regles_1815_21_63.py — règles Gaudillère 1815-1870, départements 21 à 63

Transcrites depuis les photos des CARTES de l'atlas (photo_1815_1870/,
pages 216 à 478), et non depuis un texte « par rapport à » : chaque carte
donne la composition entière d'une période. On l'écrit donc, autant que
possible, par circonscriptions entières de 1876 (`reprend`) ou par listes
de cantons (`cantons`), le « reste » allant à la dernière.

Même format que REGLES dans remonte_1815.py, qui importe ce dictionnaire.
Les noms de cantons sont ceux de la nomenclature (cantons vivants en 1878) ;
les noms de l'atlas qui diffèrent sont notés en commentaire.

Lecture : Claude, 4 octobre 2026. À VÉRIFIER par Adrien sur les originaux —
en particulier les points marqués « DOUTE ».
"""

REGLES_21_63 = {

"21": {
  "nom": "Côte-d'Or",
  # Atlas : « Flavigny » = Venarey ; « Grancey » = Grancey-le-Château ;
  # « Pontailler » = Pontailler-sur-Saône. Photos 116-117, p. 215-216 env.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "fusionner": [
        (["Dijon-1", "Dijon-2"], "Dijon"),
        (["Beaune-1", "Beaune-2"], "Beaune")]},
    {"depuis": 1820, "jusqu": 1831, "base": "1815", "circos": {
        "1": {"reprend": ["Dijon"]},
        "2": {"reprend": ["Beaune"]},
        "3": {"reprend": ["Châtillon-sur-Seine", "Semur"]}}},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"cantons": ["Dijon-Est", "Dijon-Nord", "Dijon-Ouest"]},
        "2": {"reprend": ["Dijon-1", "Dijon-2"],
              "moins": ["Dijon-Est", "Dijon-Nord", "Dijon-Ouest"]},
        "3": {"reprend": ["Beaune-1", "Beaune-2"]},
        "4": {"reprend": ["Semur"]},
        "5": {"reprend": ["Châtillon-sur-Seine"]}}},
    # « Même découpage et même numérotation que de 1820 à 1831 »
    {"depuis": 1852, "jusqu": 1870, "base": "1820", "copie": True},
  ]},


"22": {
  "nom": "Côtes-du-Nord",
  # Atlas : « Saint-Jouan-de-l'Isle » = Caulnes ; « Saint-Brieuc-Nord/Sud »
  # = Saint-Brieuc-1/2. Étables n'apparaît qu'à partir de la carte 1831-1848.
  # Photos 112-115.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "fusionner": [
        (["Lannion-1", "Lannion-2"], "Lannion"),
        (["Guingamp-1", "Guingamp-2"], "Guingamp"),
        (["Saint-Brieuc-1", "Saint-Brieuc-2"], "Saint-Brieuc"),
        (["Dinan-1", "Dinan-2"], "Dinan")]},
    {"depuis": 1820, "jusqu": 1831, "base": "1815", "circos": {
        "1": {"reprend": ["Saint-Brieuc"]},
        "2": {"reprend": ["Dinan"]},
        "3": {"reprend": ["Guingamp", "Loudéac"]},
        "4": {"reprend": ["Lannion"]}}},
    # DOUTE : Pléneuf. Séparé de Lamballe et de Matignon par un trait épais,
    # il ne touche Saint-Brieuc-Sud qu'en un point ; le chiffre 2 est posé
    # juste au-dessus de lui. Rangé dans la 2e (enclave littorale), Lamballe
    # dans la 1re avec les deux cantons de Saint-Brieuc.
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"cantons": ["Saint-Brieuc-1", "Saint-Brieuc-2", "Lamballe"]},
        "2": {"cantons": ["Paimpol", "Plouha", "Lanvollon", "Étables",
                          "Châtelaudren", "Quintin", "Ploeuc", "Moncontour",
                          "Pléneuf"]},
        "3": {"reprend": ["Dinan-1", "Dinan-2"]},
        "4": {"reprend": ["Guingamp-1", "Guingamp-2"]},
        "5": {"reprend": ["Lannion-1", "Lannion-2"]},
        "6": {"reprend": ["Loudéac"]}}},
    {"depuis": 1852, "jusqu": 1857, "base": "1876", "circos": {
        "1": {"reprend": ["Saint-Brieuc-1", "Saint-Brieuc-2"],
              "moins": ["Paimpol", "Moncontour"]},
        "2": {"reprend": ["Dinan-1", "Dinan-2"]},
        "3": {"reprend": ["Guingamp-1", "Guingamp-2"]},
        "4": {"reprend": ["Lannion-1", "Lannion-2"], "plus": ["Paimpol"]},
        "5": {"reprend": ["Loudéac"], "plus": ["Moncontour"]}}},
    {"depuis": 1857, "jusqu": 1863, "base": "1876", "circos": {
        "1": {"cantons": ["Paimpol", "Pontrieux", "Plouha", "Lanvollon",
                          "Étables", "Guingamp", "Bourbriac", "Plouagat",
                          "Châtelaudren", "Saint-Brieuc-1", "Saint-Brieuc-2"]},
        "2": {"reprend": ["Dinan-1", "Dinan-2"],
              "plus": ["Lamballe", "Pléneuf", "Moncontour"]},
        "3": {"reprend": ["Lannion-1", "Lannion-2"],
              "plus": ["Bégard", "Belle-Isle-en-Terre", "Callac"]},
        "4": {"reste": True}}},
    # Caulnes (Saint-Jouan-de-l'Isle) entouré d'un trait épais côté Dinan :
    # il passe à la 5e, par Merdrignac.
    {"depuis": 1863, "jusqu": 1869, "base": "1876", "circos": {
        "1": {"cantons": ["Paimpol", "Plouha", "Lanvollon", "Étables",
                          "Châtelaudren", "Saint-Brieuc-1", "Saint-Brieuc-2",
                          "Quintin", "Ploeuc"]},
        "2": {"reprend": ["Dinan-1", "Dinan-2"], "plus": ["Lamballe", "Pléneuf"],
              "moins": ["Caulnes"]},
        "3": {"reprend": ["Guingamp-1", "Guingamp-2"]},
        "4": {"reprend": ["Lannion-1", "Lannion-2"]},
        "5": {"reste": True}}},
    {"depuis": 1869, "jusqu": 1870, "base": "1876", "circos": {
        "1": {"reprend": ["Saint-Brieuc-1", "Saint-Brieuc-2"],
              "moins": ["Quintin"]},
        "2": {"reprend": ["Dinan-1", "Dinan-2"]},
        "3": {"reprend": ["Guingamp-1", "Guingamp-2"],
              "moins": ["Saint-Nicolas-du-Pélem"]},
        "4": {"reprend": ["Lannion-1", "Lannion-2"]},
        "5": {"reprend": ["Loudéac"],
              "plus": ["Quintin", "Saint-Nicolas-du-Pélem"]}}},
  ]},

"23": {
  "nom": "Creuse",
  # Photos 110-111.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "fusionner": [
        (["Aubusson-1", "Aubusson-2"], "Aubusson")]},
    {"depuis": 1820, "jusqu": 1831, "base": "1876", "circos": {
        "1": {"reprend": ["Guéret", "Boussac"], "moins": ["Chambon-sur-Voueize"],
              "plus": ["Bénévent-l'Abbaye"]},
        "2": {"reste": True}}},
    # « Même découpage qu'en 1815 » : 1 Guéret, 2 Aubusson, 3 Bourganeuf, 4 Boussac
    {"depuis": 1831, "jusqu": 1848, "base": "1815", "renommer": {
        "Guéret": "1", "Aubusson": "2", "Bourganeuf": "3", "Boussac": "4"}},
    {"depuis": 1852, "jusqu": 1870, "base": "1876", "circos": {
        "1": {"reprend": ["Guéret", "Boussac"]},
        "2": {"reste": True}}},
  ]},

"24": {
  "nom": "Dordogne",
  # Atlas : « Grignols » (1815, 1820) = Saint-Astier ; « Cunèges » (1815)
  # = Sigoulès ; « Montpont » = Montpon-sur-l'Isle. Photos 107-109.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "fusionner": [
        (["Périgueux-1", "Périgueux-2"], "Périgueux"),
        (["Bergerac-1", "Bergerac-2"], "Bergerac"),
        (["Sarlat-1", "Sarlat-2"], "Sarlat")]},
    {"depuis": 1820, "jusqu": 1831, "base": "1815", "circos": {
        "1": {"reprend": ["Périgueux"],
              "plus": ["Saint-Pardoux-la-Rivière", "Jumilhac-le-Grand",
                       "Thiviers", "Lanouaille"]},
        "2": {"reprend": ["Nontron", "Ribérac"],
              "moins": ["Saint-Pardoux-la-Rivière", "Jumilhac-le-Grand",
                        "Thiviers", "Lanouaille"]},
        "3": {"reprend": ["Bergerac"]},
        "4": {"reprend": ["Sarlat"]}}},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"reprend": ["Périgueux-1"]},
        "2": {"reprend": ["Périgueux-2"]},
        "3": {"reprend": ["Bergerac-2"], "plus": ["Bergerac"]},
        "4": {"reprend": ["Bergerac-1"], "moins": ["Bergerac"]},
        "5": {"reprend": ["Nontron"]},
        "6": {"reprend": ["Ribérac"]},
        "7": {"reprend": ["Sarlat-1", "Sarlat-2"]}}},
    # Note de l'atlas : le décret de 1852 donnait le chiffre 4 à Nontron et
    # le 3 à Sarlat ; les procès-verbaux les ont intervertis, et le décret de
    # 1857 a entériné l'inversion. On suit la carte : 3 Nontron, 4 Sarlat.
    {"depuis": 1852, "jusqu": 1863, "base": "1876", "circos": {
        "1": {"reprend": ["Périgueux-1", "Périgueux-2"],
              "plus": ["Montignac", "Terrasson"]},
        "2": {"reprend": ["Bergerac-2"],
              "plus": ["Bergerac", "Issigeac", "Neuvic", "Montpon-sur-l'Isle",
                       "Mussidan", "Montagrier"]},
        "3": {"reprend": ["Nontron"],
              "plus": ["Verteillac", "Ribérac", "Saint-Aulaye"]},
        "4": {"reste": True}}},
    {"depuis": 1863, "jusqu": 1870, "base": "1876", "circos": {
        "1": {"reprend": ["Périgueux-1", "Périgueux-2"],
              "plus": ["Jumilhac-le-Grand", "Thiviers", "Lanouaille",
                       "Champagnac-de-Belair"]},
        "2": {"reprend": ["Bergerac-1", "Bergerac-2"]},
        "3": {"reprend": ["Nontron", "Ribérac"],
              "moins": ["Jumilhac-le-Grand", "Thiviers", "Lanouaille",
                        "Champagnac-de-Belair"]},
        "4": {"reprend": ["Sarlat-1", "Sarlat-2"]}}},
  ]},

"25": {
  "nom": "Doubs",
  # Atlas : « Blamont » = Hérimoncourt ; « Montbéliard (2 c.) » sur les
  # cartes 1852-1870. Photos 103-106.
  "periodes": [
    # Montbéliard et Audincourt ne sont pas sur la carte de 1815 : le pays
    # de Montbéliard est alors haut-saônois (rattaché au Doubs en 1816).
    # Arrondissement de Saint-Hippolyte = circo Montbéliard de 1876 sans eux.
    {"depuis": 1815, "jusqu": 1820, "base": "1876",
     "absents": ["Montbéliard", "Audincourt"],
     "fusionner": [(["Besançon-1", "Besançon-2"], "Besançon"),
                   (["Montbéliard"], "Saint-Hippolyte")]},
    {"depuis": 1820, "jusqu": 1821, "base": "1876", "circos": {
        "2": {"reprend": ["Besançon-1", "Besançon-2", "Pontarlier"],
              "moins": ["Marchaux", "Montbenoît", "Morteau"]},
        "1": {"reste": True}}},
    {"depuis": 1821, "jusqu": 1831, "base": "1876", "circos": {
        "2": {"reprend": ["Besançon-1", "Besançon-2"]},
        "1": {"reste": True}}},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "renommer": {
        "Besançon-1": "1", "Besançon-2": "2", "Baume-les-Dames": "3",
        "Montbéliard": "4", "Pontarlier": "5"}},
    {"depuis": 1852, "jusqu": 1857, "base": "1876", "circos": {
        "1": {"reprend": ["Besançon-1", "Besançon-2", "Pontarlier"],
              "moins": ["Marchaux", "Morteau"]},
        "2": {"reste": True}}},
    {"depuis": 1857, "jusqu": 1869, "base": "1876", "circos": {
        "1": {"reprend": ["Besançon-1", "Besançon-2", "Pontarlier"],
              "moins": ["Morteau"]},
        "2": {"reste": True}}},
    {"depuis": 1869, "jusqu": 1870, "base": "1876", "circos": {
        "1": {"reprend": ["Besançon-1", "Besançon-2", "Pontarlier"]},
        "2": {"reste": True}}},
  ]},

"26": {
  "nom": "Drôme",
  # Saint-Paul-Trois-Châteaux n'est dessiné qu'à partir de 1852 ; avant, son
  # territoire est compris dans Pierrelatte (même circonscription partout).
  # Photos 100-102.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "fusionner": [
        (["Valence-1", "Valence-2"], "Valence")]},
    {"depuis": 1820, "jusqu": 1831, "base": "1876", "circos": {
        "1": {"reprend": ["Valence-1", "Valence-2"], "moins": ["Loriol-sur-Drôme"]},
        "2": {"reste": True}}},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"cantons": ["Valence", "Chabeuil", "Loriol-sur-Drôme",
                          "Saint-Vallier", "Tain-l'Hermitage"]},
        "2": {"cantons": ["Le Grand-Serre", "Saint-Donat-sur-l'Herbasse",
                          "Romans-sur-Isère", "Bourg-de-Péage",
                          "Saint-Jean-en-Royans"]},
        "3": {"reprend": ["Die"]},
        "4": {"reprend": ["Montélimar", "Nyons"]}}},
    {"depuis": 1852, "jusqu": 1857, "base": "1876", "circos": {
        "2": {"reprend": ["Valence-2"],
              "plus": ["Bourg-de-Péage", "Saint-Jean-en-Royans",
                       "La Chapelle-en-Vercors"]},
        "1": {"cantons": ["Valence", "Chabeuil", "Loriol-sur-Drôme",
                          "Crest-Nord", "Crest-Sud", "Marsanne", "Montélimar",
                          "Pierrelatte", "Saint-Paul-Trois-Châteaux"]},
        "3": {"reste": True}}},
    {"depuis": 1857, "jusqu": 1870, "base": "1876", "circos": {
        "2": {"reprend": ["Valence-2"],
              "plus": ["Bourg-de-Péage", "Saint-Jean-en-Royans",
                       "La Chapelle-en-Vercors"]},
        "1": {"cantons": ["Valence", "Chabeuil", "Loriol-sur-Drôme",
                          "Marsanne", "Montélimar", "Grignan", "Pierrelatte",
                          "Saint-Paul-Trois-Châteaux"]},
        "3": {"reste": True}}},
  ]},

"27": {
  "nom": "Eure",
  # Atlas : « Tourville » (1815-1831) = Amfreville-la-Campagne ;
  # « Grainville » (1815-1848) = Fleury-sur-Andelle. Photos 96-99.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "fusionner": [
        (["Évreux-1", "Évreux-2"], "Évreux")]},
    # Ordonnance modificative du 20 septembre 1820. La 2e est en deux
    # morceaux sur la carte (Pont-Audemer d'un côté, Louviers et Le Neubourg
    # de l'autre) ; Amfreville (« Tourville ») est désigné 4 par une flèche.
    {"depuis": 1820, "jusqu": 1821, "base": "1876", "circos": {
        "1": {"reprend": ["Évreux-1", "Évreux-2"]},
        "2": {"reprend": ["Pont-Audemer"], "plus": ["Louviers", "Le Neubourg"]},
        "3": {"reprend": ["Bernay"]},
        "4": {"reste": True}}},
    # DOUTE : la carte ne ferme pas la 2e. Louviers est cerné d'un trait épais
    # côté Pont-de-l'Arche et Gaillon, Amfreville l'est côté Brionne, mais la
    # limite Amfreville / Pont-de-l'Arche paraît fine. Lecture retenue :
    # Amfreville passe à la 2e, Pont-de-l'Arche reste à la 4e.
    {"depuis": 1821, "jusqu": 1831, "base": "1876", "circos": {
        "1": {"reprend": ["Évreux-1", "Évreux-2"]},
        "2": {"reprend": ["Pont-Audemer"],
              "plus": ["Amfreville-la-Campagne", "Louviers", "Le Neubourg"]},
        "3": {"reprend": ["Bernay"]},
        "4": {"reste": True}}},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"reprend": ["Évreux-1"]},
        "2": {"reprend": ["Évreux-2"]},
        "3": {"reprend": ["Les Andelys"]},
        "4": {"cantons": ["Thiberville", "Bernay", "Broglie", "Beaumesnil"]},
        "5": {"reprend": ["Louviers"]},
        "6": {"cantons": ["Quillebeuf-sur-Seine", "Beuzeville", "Pont-Audemer",
                          "Cormeilles", "Routot"]},
        "7": {"cantons": ["Saint-Georges-du-Vièvre", "Montfort-sur-Risle",
                          "Bourgtheroulde", "Brionne", "Beaumont-le-Roger"]}}},
    {"depuis": 1852, "jusqu": 1863, "base": "1876", "circos": {
        "1": {"reprend": ["Évreux-1", "Évreux-2"]},
        "2": {"reprend": ["Louviers", "Les Andelys"]},
        "3": {"reprend": ["Pont-Audemer", "Bernay"]}}},
    # Évreux-Nord, cerné de traits épais, va à la 2e (la carte de 1869 le
    # montre plus nettement).
    {"depuis": 1863, "jusqu": 1869, "base": "1876", "circos": {
        "3": {"reprend": ["Pont-Audemer"], "plus": ["Thiberville", "Brionne"]},
        "4": {"reprend": ["Louviers"],
              "plus": ["Fleury-sur-Andelle", "Lyons-la-Forêt", "Les Andelys"]},
        "2": {"cantons": ["Bernay", "Beaumont-le-Roger", "Broglie", "Beaumesnil",
                          "Conches-en-Ouche", "Rugles", "Breteuil", "Évreux-Nord"]},
        "1": {"reste": True}}},
    {"depuis": 1869, "jusqu": 1870, "base": "1876", "circos": {
        "3": {"reprend": ["Pont-Audemer"], "plus": ["Thiberville", "Brionne"]},
        "4": {"reprend": ["Louviers"],
              "plus": ["Fleury-sur-Andelle", "Lyons-la-Forêt", "Étrépagny",
                       "Gisors"]},
        "2": {"cantons": ["Bernay", "Beaumont-le-Roger", "Broglie", "Beaumesnil",
                          "Conches-en-Ouche", "Rugles", "Breteuil", "Évreux-Nord"]},
        "1": {"reste": True}}},
  ]},

"28": {
  "nom": "Eure-et-Loir",
  # Photos 94-95.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "fusionner": [
        (["Chartres-1", "Chartres-2"], "Chartres")]},
    {"depuis": 1820, "jusqu": 1831, "base": "1876", "circos": {
        "2": {"reprend": ["Dreux", "Nogent-le-Rotrou"],
              "plus": ["Courville-sur-Eure", "Illiers", "Brou"]},
        "1": {"reste": True}}},
    # « Même découpage qu'en 1815 » : 1 Chartres, 2 Châteaudun, 3 Dreux,
    # 4 Nogent-le-Rotrou.
    {"depuis": 1831, "jusqu": 1848, "base": "1815", "renommer": {
        "Chartres": "1", "Châteaudun": "2", "Dreux": "3",
        "Nogent-le-Rotrou": "4"}},
    {"depuis": 1852, "jusqu": 1870, "base": "1876", "circos": {
        "2": {"reprend": ["Dreux", "Nogent-le-Rotrou"],
              "plus": ["Illiers", "Brou"]},
        "1": {"reste": True}}},
  ]},

"29": {
  "nom": "Finistère",
  # Atlas : « Brest I, II, III » = Brest-Ville, Brest-2, Brest-3 (INTERPRÉTATION
  # sur l'ordre : Brest I, petit canton urbain, est pris pour Brest-Ville,
  # qui n'a en 1876 qu'un atome-fraction sans circonscription) ;
  # « Le Ponthou » (1815-1831) = Plouigneau. Photos 91-93.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "circos": {
        "Brest": {"reprend": ["Brest-1", "Brest-2", "Brest-3"],
                  "plus": ["Brest-Ville"]},
        "Morlaix": {"reprend": ["Morlaix-1", "Morlaix-2"]},
        "Châteaulin": {"reprend": ["Châteaulin-1", "Châteaulin-2"]},
        "Quimper": {"reprend": ["Quimper-1", "Quimper-2"]},
        "Quimperlé": {"reprend": ["Quimperlé"]}}},
    {"depuis": 1820, "jusqu": 1831, "base": "1876", "circos": {
        "1": {"reprend": ["Brest-1", "Brest-3"],
              "plus": ["Brest-Ville", "Plabennec", "Landerneau"]},
        "2": {"reprend": ["Morlaix-1", "Morlaix-2"]},
        "3": {"reprend": ["Châteaulin-1", "Châteaulin-2"],
              "plus": ["Daoulas", "Ploudiry", "Douarnenez", "Pont-Croix",
                       "Briec"]},
        "4": {"reste": True}}},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"cantons": ["Brest-Ville", "Brest-2", "Brest-3"]},
        "2": {"reprend": ["Brest-2", "Brest-3"]},
        "3": {"reprend": ["Châteaulin-1", "Châteaulin-2"]},
        "4": {"reprend": ["Morlaix-1", "Morlaix-2"]},
        "5": {"reprend": ["Quimper-1", "Quimper-2"]},
        "6": {"reprend": ["Quimperlé"]}}},
    {"depuis": 1852, "jusqu": 1869, "base": "1876", "circos": {
        "1": {"reprend": ["Quimper-1", "Quimper-2", "Quimperlé"]},
        "2": {"reprend": ["Brest-1", "Brest-3"],
              "plus": ["Brest-Ville", "Plabennec"]},
        "3": {"reprend": ["Morlaix-1", "Morlaix-2"]},
        "4": {"reste": True}}},
    # DOUTE : la ville de Brest. Le trait épais sépare Brest II de Brest I et
    # III ; la flèche du chiffre 3 traverse Brest II vers Plabennec. Lecture
    # retenue : Brest I (Brest-Ville) et III vont à la 2e avec Saint-Renan.
    {"depuis": 1869, "jusqu": 1870, "base": "1876", "circos": {
        "1": {"reprend": ["Quimper-1", "Quimper-2", "Quimperlé"]},
        "2": {"cantons": ["Lannilis", "Lesneven", "Ploudalmézeau",
                          "Saint-Renan", "Ouessant", "Brest-3", "Brest-Ville"]},
        # circo Brest-2 de 1876 (Daoulas, Landerneau, Plabennec, Ploudiry)
        # + le CANTON Brest-2 — même nom, deux objets.
        "3": {"reprend": ["Brest-2"], "plus": ["Brest-2"]},
        "4": {"reprend": ["Châteaulin-1", "Châteaulin-2"]},
        "5": {"reprend": ["Morlaix-1", "Morlaix-2"]}}},
  ]},

"30": {
  "nom": "Gard",
  # Trame cantonale : jusqu'à 1863 l'atlas dessine « Saint-Martin-de-
  # Valgalgues » et un seul canton d'Alès ; Bessèges, La Grand-Combe et les
  # deux Alès n'apparaissent qu'en 1863. Approximation sur les cantons de
  # 1876 : Saint-Martin ≈ La Grand-Combe, Alès = Alès-Est + Alès-Ouest,
  # Bessèges suit Saint-Ambroix (même circonscription à toutes les dates).
  # « Nîmes I, II, III » = Nimes-1, Nimes-2, Nimes-3 (Nimes-2 n'a en 1876
  # qu'un atome-fraction, sans circonscription). Photos 87-90.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "circos": {
        "Nîmes": {"reprend": ["Nîmes-1", "Nîmes-2"], "plus": ["Nimes-2"]},
        "Alès": {"reprend": ["Alais-1", "Alais-2"]},
        "Uzès": {"reprend": ["Uzès"]},
        "Le Vigan": {"reprend": ["Le Vigan"]}}},
    {"depuis": 1820, "jusqu": 1831, "base": "1876", "circos": {
        "1": {"cantons": ["Nimes-1", "Nimes-2", "Nimes-3", "Vauvert",
                          "Saint-Gilles", "Aigues-Mortes", "Beaucaire"]},
        "3": {"reprend": ["Uzès"], "plus": ["Marguerittes", "Aramon"]},
        "2": {"reste": True}}},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        # La 2e reprend les circos de Nîmes, dont la 1re reprend ensuite les
        # cantons urbains — d'où l'ordre.
        "2": {"reprend": ["Nîmes-1", "Nîmes-2"]},
        "1": {"cantons": ["Nimes-1", "Nimes-2", "Nimes-3"]},
        "3": {"reprend": ["Alais-1", "Alais-2"]},
        "4": {"reprend": ["Uzès"]},
        "5": {"reprend": ["Le Vigan"]}}},
    {"depuis": 1852, "jusqu": 1857, "base": "1876", "circos": {
        "2": {"reprend": ["Uzès"],
              "plus": ["Barjac", "Vézénobres", "Lédignan", "Aramon"]},
        "3": {"reprend": ["Le Vigan", "Alais-1", "Alais-2"],
              "moins": ["Barjac", "Vézénobres", "Lédignan"]},
        "1": {"reste": True}}},
    {"depuis": 1857, "jusqu": 1863, "base": "1876", "circos": {
        "2": {"reprend": ["Uzès"],
              "plus": ["Génolhac", "Bessèges", "Saint-Ambroix", "Barjac",
                       "Aramon"]},
        "3": {"reprend": ["Le Vigan", "Alais-1"],
              "plus": ["La Grand-Combe"]},
        "1": {"reste": True}}},
    # Nîmes I, cerné de traits épais, est désigné 3 par une flèche.
    {"depuis": 1863, "jusqu": 1869, "base": "1876", "circos": {
        "2": {"reprend": ["Uzès"]},
        "3": {"reprend": ["Alais-2"], "plus": ["Alès-Est", "Alès-Ouest",
                                                "Nimes-1"]},
        "4": {"reprend": ["Le Vigan"],
              "plus": ["Anduze", "Lédignan", "Saint-Jean-du-Gard",
                       "Vézénobres"]},
        "1": {"reste": True}}},
    # DOUTE : Nîmes I, cerné de traits épais à l'ouest et à l'est, rangé dans
    # la 3e comme en 1863 ; Nîmes II est désigné 2 par une flèche.
    {"depuis": 1869, "jusqu": 1870, "base": "1876", "circos": {
        "2": {"reprend": ["Uzès"], "moins": ["Saint-Chaptes"],
              "plus": ["Nimes-2"]},
        "3": {"reprend": ["Alais-2"],
              "plus": ["Alès-Est", "Alès-Ouest", "Vézénobres", "Saint-Chaptes",
                       "Nimes-1"]},
        "4": {"reprend": ["Le Vigan"],
              "plus": ["Anduze", "Lédignan", "Saint-Jean-du-Gard"]},
        "1": {"reste": True}}},
  ]},

"31": {
  "nom": "Haute-Garonne",
  # Atlas : « Saint-Bertrand » = Barbazan ; « Salies » = Salies-du-Salat ;
  # « Toulouse Nord/Centre/Sud/Ouest » = Toulouse-Nord/-Centre/-Sud/-Ouest.
  # Photos 84-86.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "fusionner": [
        (["Toulouse-2", "Toulouse-3"], "Toulouse"),
        (["Saint-Gaudens-1", "Saint-Gaudens-2"], "Saint-Gaudens")]},
    # DOUTE : la loi de 1820 coupe Toulouse et ses environs en deux
    # circonscriptions chacune en DEUX morceaux (chiffres 1 et 2 posés deux
    # fois, une flèche 2 vers Léguevin). Lecture : 1 = Cadours (isolé) +
    # Fronton, Toulouse-Nord, -Ouest, -Sud, Verfeil, Castanet ; 2 = Grenade,
    # Léguevin + Villemur, Montastruc, Toulouse-Centre.
    {"depuis": 1820, "jusqu": 1831, "base": "1876", "circos": {
        "1": {"cantons": ["Cadours", "Fronton", "Toulouse-Nord",
                          "Toulouse-Ouest", "Toulouse-Sud", "Verfeil",
                          "Castanet-Tolosan"]},
        "2": {"cantons": ["Grenade", "Léguevin", "Villemur-sur-Tarn",
                          "Montastruc-la-Conseillère", "Toulouse-Centre"]},
        "3": {"reprend": ["Villefranche"]},
        "4": {"reste": True}}},
    # DOUTE : partage des quatre cantons urbains entre 1re et 2e (flèches).
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"cantons": ["Toulouse-Nord", "Toulouse-Centre"]},
        "2": {"cantons": ["Toulouse-Ouest", "Toulouse-Sud"]},
        "3": {"reprend": ["Toulouse-3"]},
        "4": {"reprend": ["Muret"]},
        "5": {"reprend": ["Saint-Gaudens-1", "Saint-Gaudens-2"]},
        "6": {"reprend": ["Villefranche"]}}},
    {"depuis": 1852, "jusqu": 1863, "base": "1876", "circos": {
        "1": {"cantons": ["Fronton", "Villemur-sur-Tarn",
                          "Montastruc-la-Conseillère", "Toulouse-Centre",
                          "Verfeil", "Lanta", "Caraman", "Revel", "Villefranche"]},
        "2": {"cantons": ["Cadours", "Grenade", "Léguevin", "Toulouse-Nord",
                          "Toulouse-Ouest", "Toulouse-Sud", "Castanet-Tolosan",
                          "Saint-Lys", "Muret"]},
        "4": {"reprend": ["Saint-Gaudens-1", "Saint-Gaudens-2"]},
        "3": {"reste": True}}},
    {"depuis": 1863, "jusqu": 1869, "base": "1876", "circos": {
        "1": {"cantons": ["Cadours", "Grenade", "Fronton", "Villemur-sur-Tarn",
                          "Montastruc-la-Conseillère", "Toulouse-Nord",
                          "Toulouse-Centre", "Verfeil", "Lanta", "Caraman"]},
        "2": {"cantons": ["Léguevin", "Toulouse-Ouest", "Saint-Lys", "Muret",
                          "Rieumes", "Le Fousseret", "L'Isle-en-Dodon",
                          "Cazères"]},
        "4": {"reprend": ["Saint-Gaudens-1", "Saint-Gaudens-2"],
              "moins": ["L'Isle-en-Dodon"]},
        "3": {"reste": True}}},
    {"depuis": 1869, "jusqu": 1870, "base": "1876", "circos": {
        "1": {"cantons": ["Cadours", "Grenade", "Fronton", "Villemur-sur-Tarn",
                          "Montastruc-la-Conseillère", "Toulouse-Nord",
                          "Toulouse-Centre", "Verfeil"]},
        "2": {"cantons": ["Léguevin", "Toulouse-Ouest", "Saint-Lys", "Muret",
                          "Rieumes", "Le Fousseret", "L'Isle-en-Dodon",
                          "Aurignac", "Cazères"]},
        "4": {"reprend": ["Saint-Gaudens-1", "Saint-Gaudens-2"],
              "moins": ["L'Isle-en-Dodon", "Aurignac"]},
        "3": {"reste": True}}},
  ]},

"32": {
  "nom": "Gers",
  # Photos 82-83.
  "periodes": [
    # Cologne, cerné de traits épais côté Mauvezin et L'Isle-Jourdain, est
    # désigné « Auch » par une flèche.
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "deplacer": [
        (["Cologne"], "Auch")]},
    {"depuis": 1820, "jusqu": 1831, "base": "1815", "circos": {
        "1": {"reprend": ["Auch", "Mirande"]},
        "2": {"reprend": ["Condom"]},
        "3": {"reprend": ["Lectoure", "Lombez"]}}},
    {"depuis": 1831, "jusqu": 1848, "base": "1815", "renommer": {
        "Auch": "1", "Condom": "2", "Lectoure": "3", "Lombez": "4",
        "Mirande": "5"}},
    {"depuis": 1852, "jusqu": 1870, "base": "1876", "circos": {
        "2": {"reprend": ["Condom"], "moins": ["Nogaro"],
              "plus": ["Lectoure", "Miradoux", "Fleurance", "Saint-Clar"]},
        "3": {"reprend": ["Mirande"], "plus": ["Nogaro", "Vic-Fezensac"]},
        "1": {"reste": True}}},
  ]},

"33": {
  "nom": "Gironde",
  # Atlas : « Saint-Ciers » = Saint-Ciers-sur-Gironde ; « Saint-Laurent » =
  # Saint-Laurent-et-Benon ; « Castillon » = Castillon-et-Capitourlan ;
  # « Saint-André » = Saint-André-de-Cubzac. La ville de Bordeaux est dessinée
  # d'un seul tenant ; la nomenclature a six cantons Bordeaux-1 à 6, dont 1,
  # 2, 4 et 6 débordent sur la banlieue (Le Bouscat, Caudéran, Talence,
  # Bègles, 33110). Photos 79-81.
  #
  # LIMITE — ville de Bordeaux, à reprendre à l'échelle de l'atome :
  #  * 1820-1831 : note de l'atlas, « les cantons de Bordeaux-1, 2, 4 et 6
  #    étaient divisés : la partie de la ville appartenant à ces cantons était
  #    rattachée à la 1re circonscription, et les autres communes à la 2e ».
  #    Ici, les six cantons entiers vont à la 1re : les cinq communes de
  #    banlieue sont à tort dans la 1re.
  #  * 1831-1848 : la ville forme les circonscriptions 1 à 3 ; la carte ne
  #    dit pas comment. Les six cantons sont posés en « 1 » — FAUX pour 2 et 3.
  #  * 1869-1870 : la ville est dessinée dans la 1re, mais la 3e (Carbon-
  #    Blanc, Créon, Podensac, Targon) est bien trop petite pour ne pas
  #    contenir une part de Bordeaux. Probable partage de la ville, non lu.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "circos": {
        "Bordeaux": {"reprend": ["Bordeaux-3", "Bordeaux-4"],
                     "plus": ["Bordeaux-3", "Bordeaux-5"]},
        "Libourne": {"reprend": ["Libourne-1", "Libourne-2"]},
        "Lesparre": {"reprend": ["Lesparre"]},
        "Blaye": {"reprend": ["Blaye"]},
        "Bazas": {"reprend": ["Bazas"]},
        "La Réole": {"reprend": ["La Réole"]}}},
    # DOUTE : Saint-André-de-Cubzac. Le trait épais le borde à l'est ; la
    # limite avec Bourg est fine, avec une flèche. Rangé dans la 3e.
    {"depuis": 1820, "jusqu": 1831, "base": "1815", "circos": {
        "1": {"cantons": ["Bordeaux-1", "Bordeaux-2", "Bordeaux-3",
                          "Bordeaux-4", "Bordeaux-5", "Bordeaux-6"]},
        "3": {"reprend": ["Lesparre", "Blaye"], "plus": ["Saint-André-de-Cubzac"]},
        "4": {"reprend": ["Libourne"]},
        "5": {"reprend": ["Bazas", "La Réole"]},
        "2": {"reste": True}}},
    {"depuis": 1831, "jusqu": 1848, "base": "1815", "circos": {
        "1": {"cantons": ["Bordeaux-1", "Bordeaux-2", "Bordeaux-3",
                          "Bordeaux-4", "Bordeaux-5", "Bordeaux-6"]},
        "5": {"reprend": ["Bazas"]},
        "6": {"reprend": ["Blaye"]},
        "7": {"reprend": ["Lesparre"]},
        "8": {"reprend": ["Libourne"]},
        "9": {"reprend": ["La Réole"]},
        "4": {"reste": True}}},
    {"depuis": 1852, "jusqu": 1857, "base": "1876", "circos": {
        "1": {"cantons": ["Bordeaux-1", "Bordeaux-2", "Bordeaux-3",
                          "Bordeaux-4", "Bordeaux-5", "Bordeaux-6"]},
        "4": {"reprend": ["Lesparre", "Blaye"],
              "plus": ["Castelnau-de-Médoc", "Blanquefort",
                       "Saint-André-de-Cubzac"]},
        "3": {"reprend": ["La Réole", "Bazas"]},
        "5": {"reprend": ["Libourne-1", "Libourne-2"]},
        "2": {"reste": True}}},
    {"depuis": 1857, "jusqu": 1869, "base": "1876", "circos": {
        "1": {"cantons": ["Bordeaux-1", "Bordeaux-2", "Bordeaux-3",
                          "Bordeaux-4", "Bordeaux-5", "Bordeaux-6",
                          "Blanquefort", "Pessac"]},
        "4": {"reprend": ["Lesparre", "Blaye"],
              "plus": ["Castelnau-de-Médoc", "Saint-André-de-Cubzac"]},
        "3": {"reprend": ["La Réole", "Bazas"]},
        "5": {"reprend": ["Libourne-1", "Libourne-2"]},
        "2": {"reste": True}}},
    {"depuis": 1869, "jusqu": 1870, "base": "1876", "circos": {
        "1": {"reprend": ["Lesparre"],
              "plus": ["Castelnau-de-Médoc", "Blanquefort", "Bordeaux-1",
                       "Bordeaux-2", "Bordeaux-3", "Bordeaux-4", "Bordeaux-5",
                       "Bordeaux-6"]},
        "2": {"cantons": ["Pessac", "Audenge", "La Teste", "Belin", "Labrède"]},
        "3": {"cantons": ["Carbon-Blanc", "Créon", "Podensac", "Targon"]},
        "4": {"reprend": ["Blaye"],
              "plus": ["Saint-André-de-Cubzac", "Fronsac", "Guîtres",
                       "Coutras"]},
        "5": {"cantons": ["Libourne", "Lussac", "Castillon-et-Capitourlan",
                          "Branne", "Pujols", "Sainte-Foy-la-Grande",
                          "Pellegrue", "Sauveterre-de-Guyenne", "Monségur"]},
        "6": {"reste": True}}},
  ]},

"34": {
  "nom": "Hérault",
  # Atlas : « Sète » = Cette ; « Clermont » = Clermont-l'Hérault ;
  # « Montpellier I, II, III » = Montpellier-1, -2, -3 (le canton
  # Montpellier-1, fraction de ville, n'a pas de circonscription en 1876).
  # Photos 76-78.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "circos": {
        "Montpellier": {"reprend": ["Montpellier-1", "Montpellier-2"],
                        "plus": ["Montpellier-1"]},
        "Béziers": {"reprend": ["Béziers-1", "Béziers-2"]},
        "Lodève": {"reprend": ["Lodève"]},
        "Saint-Pons": {"reprend": ["Saint-Pons"]}}},
    {"depuis": 1820, "jusqu": 1831, "base": "1815", "circos": {
        "1": {"reprend": ["Montpellier"]},
        "3": {"reprend": ["Lodève"],
              "plus": ["Saint-Gervais", "Bédarieux", "Roujan", "Montagnac"]},
        "2": {"reste": True}}},
    {"depuis": 1831, "jusqu": 1848, "base": "1815", "circos": {
        "2": {"reprend": ["Montpellier"]},
        "1": {"cantons": ["Montpellier-1", "Montpellier-2", "Montpellier-3"]},
        "3": {"cantons": ["Murviel", "Servian", "Béziers-1", "Béziers-2",
                          "Capestang"]},
        "4": {"cantons": ["Saint-Gervais", "Bédarieux", "Roujan", "Montagnac",
                          "Pézenas", "Florensac", "Agde"]},
        "5": {"reprend": ["Saint-Pons"]},
        "6": {"reprend": ["Lodève"]}}},
    {"depuis": 1852, "jusqu": 1869, "base": "1815", "circos": {
        "1": {"reprend": ["Montpellier"],
              "moins": ["Ganges", "Saint-Martin-de-Londres"]},
        "3": {"reprend": ["Lodève", "Saint-Pons"],
              "moins": ["Saint-Chinian"],
              "plus": ["Ganges", "Saint-Martin-de-Londres", "Saint-Gervais",
                       "Bédarieux"]},
        "2": {"reste": True}}},
    {"depuis": 1869, "jusqu": 1870, "base": "1815", "circos": {
        "1": {"reprend": ["Montpellier"],
              "moins": ["Ganges", "Saint-Martin-de-Londres", "Aniane", "Mèze",
                        "Cette"]},
        "3": {"reprend": ["Lodève"],
              "plus": ["Ganges", "Saint-Martin-de-Londres", "Aniane",
                       "Saint-Gervais", "Bédarieux"]},
        "4": {"cantons": ["Murviel", "Roujan", "Montagnac", "Pézenas",
                          "Florensac", "Mèze", "Cette", "Agde"]},
        "2": {"reste": True}}},
  ]},

"35": {
  "nom": "Ille-et-Vilaine",
  # Atlas : « Pleurtuit » = Dinard ; « Vitré-Nord/-Sud » (avant 1857) =
  # Vitré-Est/-Ouest (même circonscription) ; « Châteauneuf » =
  # Châteauneuf-d'Ille-et-Vilaine. Photos 73-75.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "fusionner": [
        (["Rennes-1", "Rennes-2"], "Rennes"),
        (["Saint-Malo-1", "Saint-Malo-2"], "Saint-Malo")]},
    # Montauban, cerné de traits épais et marqué 2 : enclave de la 2e.
    {"depuis": 1820, "jusqu": 1831, "base": "1876", "circos": {
        "1": {"reprend": ["Saint-Malo-1", "Saint-Malo-2"]},
        "2": {"reprend": ["Rennes-1", "Rennes-2"], "moins": ["Liffré"],
              "plus": ["Montauban"]},
        "3": {"reprend": ["Fougères", "Vitré"], "plus": ["Liffré"]},
        "4": {"reste": True}}},
    # DOUTE : partage de l'arrondissement de Rennes. La 2e paraît en deux
    # morceaux (Hédé + Saint-Aubin-d'Aubigné au nord, et par une flèche
    # Rennes-Nord-Ouest + Mordelles) ; la 1re prend le reste de la ville,
    # Liffré, Châteaugiron et Janzé.
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"cantons": ["Rennes-Nord-Est", "Rennes-Sud-Est",
                          "Rennes-Sud-Ouest", "Liffré", "Châteaugiron",
                          "Janzé"]},
        "2": {"cantons": ["Hédé", "Saint-Aubin-d'Aubigné", "Rennes-Nord-Ouest",
                          "Mordelles"]},
        "3": {"reprend": ["Saint-Malo-1", "Saint-Malo-2"]},
        "4": {"reprend": ["Vitré"]},
        "5": {"reprend": ["Fougères"]},
        "6": {"reprend": ["Redon"]},
        "7": {"reprend": ["Montfort"]}}},
    {"depuis": 1852, "jusqu": 1857, "base": "1876", "circos": {
        "1": {"reprend": ["Rennes-1", "Rennes-2"], "moins": ["Liffré"]},
        "2": {"reprend": ["Saint-Malo-1", "Saint-Malo-2"]},
        "3": {"reprend": ["Fougères", "Vitré"], "plus": ["Liffré"]},
        "4": {"reste": True}}},
    # Bécherel, cerné de traits épais côté Montfort et côté Hédé, passe à la 2e.
    {"depuis": 1857, "jusqu": 1870, "base": "1876", "circos": {
        "1": {"reprend": ["Rennes-1", "Rennes-2"]},
        "2": {"reprend": ["Saint-Malo-1", "Saint-Malo-2"], "plus": ["Bécherel"]},
        "3": {"reprend": ["Fougères", "Vitré"]},
        "4": {"reste": True}}},
  ]},

"36": {
  "nom": "Indre",
  # Photos 71-72.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "fusionner": [
        (["Châteauroux-1", "Châteauroux-2"], "Châteauroux")]},
    {"depuis": 1820, "jusqu": 1831, "base": "1876", "circos": {
        "1": {"reprend": ["Châteauroux-2", "Issoudun"],
              "plus": ["Châteauroux", "Ardentes"]},
        "2": {"reste": True}}},
    {"depuis": 1831, "jusqu": 1848, "base": "1815", "renommer": {
        "Châteauroux": "1", "Issoudun": "2", "La Châtre": "3", "Le Blanc": "4"}},
    {"depuis": 1852, "jusqu": 1870, "base": "1876", "circos": {
        "2": {"reprend": ["Issoudun", "La Châtre"],
              "plus": ["Bélâbre", "Saint-Benoît-du-Sault"]},
        "1": {"reste": True}}},
  ]},

"37": {
  "nom": "Indre-et-Loire",
  # Tours-Centre n'a en 1876 qu'un atome-fraction, sans circonscription :
  # il est nommé à chaque période. Photos 68-70.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "circos": {
        "Tours": {"reprend": ["Tours-1", "Tours-2"],
                  "plus": ["Tours-Centre"], "moins": ["Château-la-Vallière"]},
        "Chinon": {"reprend": ["Chinon"], "plus": ["Château-la-Vallière"]},
        "Loches": {"reprend": ["Loches"]}}},
    {"depuis": 1820, "jusqu": 1824, "base": "1815", "circos": {
        "1": {"reprend": ["Tours"]},
        "2": {"reprend": ["Chinon", "Loches"]}}},
    # « La loi du 21 juillet 1824 a transféré le canton de Château-la-Vallière
    # de l'arrondissement de Chinon à celui de Tours, et par conséquent de la
    # 2e à la 1re circonscription. »
    {"depuis": 1824, "jusqu": 1831, "base": "1820", "deplacer": [
        (["Château-la-Vallière"], "1")]},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"cantons": ["Tours-Nord", "Tours-Sud", "Tours-Centre"]},
        "2": {"reprend": ["Tours-2"], "plus": ["Montbazon", "Bléré"],
              "moins": ["Château-la-Vallière"]},
        "3": {"reprend": ["Loches"]},
        "4": {"reprend": ["Chinon"], "plus": ["Château-la-Vallière"]}}},
    # DOUTE : Tours-Centre, posé dans la 1re (le trait épais contourne la
    # pastille « Tc » côté nord).
    {"depuis": 1852, "jusqu": 1869, "base": "1876", "circos": {
        "1": {"reprend": ["Tours-2"], "moins": ["Amboise", "Bléré"],
              "plus": ["Tours-Nord", "Tours-Centre"]},
        "2": {"reprend": ["Chinon"], "plus": ["Tours-Sud"]},
        "3": {"reste": True}}},
    {"depuis": 1869, "jusqu": 1870, "base": "1876", "circos": {
        "1": {"reprend": ["Tours-2"], "moins": ["Amboise", "Bléré"],
              "plus": ["Tours-Nord", "Tours-Centre", "Tours-Sud"]},
        "2": {"reprend": ["Chinon"]},
        "3": {"reste": True}}},
  ]},

"38": {
  "nom": "Isère",
  # Atlas : « Entraigues » = Valbonnais ; « Grand-Lemps » = Le Grand-Lemps ;
  # « Saint-Étienne » = Saint-Étienne-de-Saint-Geoirs ; « Saint-Geoire » =
  # Saint-Geoire-en-Valdaine. Photos 64-67.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "fusionner": [
        (["Vienne-1", "Vienne-2"], "Vienne"),
        (["La Tour-du-Pin-1", "La Tour-du-Pin-2"], "La Tour-du-Pin"),
        (["Grenoble-1", "Grenoble-2", "Grenoble-3"], "Grenoble")]},
    {"depuis": 1820, "jusqu": 1821, "base": "1876", "circos": {
        "4": {"reprend": ["Vienne-1", "Vienne-2"],
              "moins": ["La Côte-Saint-André"]},
        "3": {"reprend": ["La Tour-du-Pin-1", "La Tour-du-Pin-2"],
              "plus": ["La Côte-Saint-André"]},
        "2": {"reprend": ["Saint-Marcellin"],
              "plus": ["Voiron", "Saint-Laurent-du-Pont", "Sassenage",
                       "Villard-de-Lans", "Vif"]},
        "1": {"reste": True}}},
    {"depuis": 1821, "jusqu": 1831, "base": "1876", "circos": {
        "3": {"cantons": ["Meyzieu", "Crémieu", "Morestel", "La Verpillière",
                          "Bourgoin", "La Tour-du-Pin", "Le Pont-de-Beauvoisin",
                          "Virieu", "Saint-Geoire-en-Valdaine"]},
        "4": {"cantons": ["Saint-Symphorien-d'Ozon", "Vienne-Nord", "Heyrieux",
                          "Vienne-Sud", "Saint-Jean-de-Bournay", "Roussillon",
                          "Beaurepaire", "La Côte-Saint-André"]},
        "2": {"reprend": ["Saint-Marcellin"],
              "plus": ["Le Grand-Lemps", "Voiron", "Saint-Laurent-du-Pont"]},
        "1": {"reste": True}}},
    # DOUTE : Meyzieu, rangé dans la 4e avec Heyrieux (traits épais côté
    # Crémieu et côté Saint-Symphorien). La Verpillière, cernée et marquée 3,
    # est une enclave de la 3e (Vienne).
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"cantons": ["Grenoble-Nord", "Grenoble-Est", "Grenoble-Sud"]},
        "3": {"cantons": ["Saint-Symphorien-d'Ozon", "Vienne-Nord", "Vienne-Sud",
                          "La Verpillière"]},
        "4": {"cantons": ["Meyzieu", "Heyrieux", "Saint-Jean-de-Bournay",
                          "La Côte-Saint-André", "Roussillon", "Beaurepaire"]},
        "5": {"cantons": ["Roybon", "Tullins", "Vinay", "Saint-Marcellin",
                          "Pont-en-Royans"]},
        "6": {"cantons": ["Crémieu", "Morestel", "Bourgoin", "La Tour-du-Pin",
                          "Le Pont-de-Beauvoisin"]},
        "7": {"cantons": ["Virieu", "Saint-Geoire-en-Valdaine", "Le Grand-Lemps",
                          "Voiron", "Rives", "Saint-Étienne-de-Saint-Geoirs",
                          "Saint-Laurent-du-Pont"]},
        "2": {"reste": True}}},
    {"depuis": 1852, "jusqu": 1857, "base": "1876", "circos": {
        "4": {"reprend": ["Vienne-1", "Vienne-2"],
              "moins": ["La Verpillière"]},
        "3": {"reprend": ["La Tour-du-Pin-1", "La Tour-du-Pin-2"],
              "plus": ["La Verpillière"]},
        "2": {"reprend": ["Saint-Marcellin"],
              "plus": ["Voiron", "Saint-Laurent-du-Pont", "Sassenage",
                       "Villard-de-Lans"]},
        "1": {"reste": True}}},
    # Clelles, cerné de traits épais et marqué 2 : enclave de la 2e.
    {"depuis": 1857, "jusqu": 1869, "base": "1876", "circos": {
        "4": {"cantons": ["Meyzieu", "Saint-Symphorien-d'Ozon", "Vienne-Nord",
                          "Heyrieux", "La Verpillière", "Vienne-Sud",
                          "Saint-Jean-de-Bournay", "Roussillon",
                          "La Côte-Saint-André"]},
        "3": {"reprend": ["La Tour-du-Pin-1", "La Tour-du-Pin-2"],
              "moins": ["La Verpillière"],
              "plus": ["Saint-Laurent-du-Pont"]},
        "2": {"reprend": ["Saint-Marcellin"],
              "plus": ["Beaurepaire", "Voiron", "Sassenage", "Villard-de-Lans",
                       "Clelles"]},
        "1": {"reste": True}}},
    {"depuis": 1869, "jusqu": 1870, "base": "1876", "circos": {
        "5": {"reprend": ["Vienne-1"],
              "plus": ["Vienne-Sud", "Saint-Jean-de-Bournay", "La Verpillière",
                       "La Côte-Saint-André"]},
        "4": {"reprend": ["La Tour-du-Pin-1", "La Tour-du-Pin-2"],
              "moins": ["La Verpillière"]},
        "3": {"cantons": ["Roussillon", "Beaurepaire", "Roybon",
                          "Saint-Étienne-de-Saint-Geoirs", "Rives", "Tullins",
                          "Voiron", "Saint-Laurent-du-Pont"]},
        "1": {"cantons": ["Grenoble-Nord", "Grenoble-Est", "Grenoble-Sud",
                          "Le Touvet", "Goncelin", "Allevard", "Domène",
                          "Le Bourg-d'Oisans"]},
        "2": {"reste": True}}},
  ]},

"39": {
  "nom": "Jura",
  # Atlas : « Cousance » (1815) = Beaufort ; « Petites-Chiettes » (avant
  # 1869) = Saint-Laurent. Photos 62-63.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "copie": True},
    {"depuis": 1820, "jusqu": 1831, "base": "1876", "circos": {
        "1": {"reprend": ["Lons-le-Saunier", "Saint-Claude"]},
        "2": {"reprend": ["Dole", "Poligny"]}}},
    # « Même découpage qu'en 1815 : 1re Dole, 2e Lons-le-Saunier,
    # 3e Saint-Claude ». DOUTE : l'atlas ne nomme que trois circonscriptions
    # pour quatre arrondissements ; Poligny, omis, est posé en 4e.
    {"depuis": 1831, "jusqu": 1848, "base": "1815", "renommer": {
        "Dole": "1", "Lons-le-Saunier": "2", "Saint-Claude": "3",
        "Poligny": "4"}},
    # « Même découpage et même numérotation qu'en 1820-1831 »
    {"depuis": 1852, "jusqu": 1869, "base": "1820", "copie": True},
    # La 2e reprend Dole et Poligny, dont la 3e reprend ensuite une part —
    # d'où l'ordre.
    {"depuis": 1869, "jusqu": 1870, "base": "1876", "circos": {
        "2": {"reprend": ["Dole", "Poligny"]},
        "3": {"cantons": ["Arbois", "Poligny", "Sellières", "Voiteur",
                          "Champagnole", "Les Planches-en-Montagne",
                          "Conliège", "Clairvaux-les-Lacs", "Saint-Laurent",
                          "Morez"]},
        "1": {"reste": True}}},
  ]},

"40": {
  "nom": "Landes",
  # Atlas : « Arjuzanx » = Morcenx ; « Saint-Esprit » = Saint-Martin-de-
  # Seignanx. Photos 60-61.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "fusionner": [
        (["Dax-1", "Dax-2"], "Dax"),
        (["Mont-de-Marsan-1", "Mont-de-Marsan-2"], "Mont-de-Marsan")]},
    {"depuis": 1820, "jusqu": 1831, "base": "1876", "circos": {
        "2": {"reprend": ["Dax-1", "Dax-2"], "plus": ["Mugron", "Amou"]},
        "1": {"reste": True}}},
    {"depuis": 1831, "jusqu": 1848, "base": "1815", "renommer": {
        "Mont-de-Marsan": "1", "Dax": "2", "Saint-Sever": "3"}},
    {"depuis": 1852, "jusqu": 1870, "base": "1876", "circos": {
        "2": {"reprend": ["Dax-1", "Dax-2"],
              "plus": ["Tartas-Ouest", "Tartas-Est", "Mugron", "Amou"]},
        "1": {"reste": True}}},
  ]},

"41": {
  "nom": "Loir-et-Cher",
  # Photos 58-59.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "fusionner": [
        (["Blois-1", "Blois-2"], "Blois")]},
    {"depuis": 1820, "jusqu": 1831, "base": "1876", "circos": {
        "2": {"reprend": ["Vendôme"], "plus": ["Marchenoir", "Ouzouer-le-Marché"]},
        "1": {"reste": True}}},
    {"depuis": 1831, "jusqu": 1848, "base": "1815", "renommer": {
        "Blois": "1", "Romorantin": "2", "Vendôme": "3"}},
    # Le trait épais isole Mer, Blois-Est, Blois-Ouest et Contres de
    # Marchenoir, Herbault, Montrichard et Saint-Aignan ; ils vont donc avec
    # Bracieux dans la 1re. DOUTE : Saint-Aignan, séparé de Contres par un
    # trait épais mais de Selles-sur-Cher par un trait fin. Rangé dans la 2e.
    {"depuis": 1852, "jusqu": 1870, "base": "1876", "circos": {
        "2": {"reprend": ["Vendôme"],
              "plus": ["Marchenoir", "Ouzouer-le-Marché", "Herbault",
                       "Montrichard", "Saint-Aignan"]},
        "1": {"reste": True}}},
  ]},

"42": {
  "nom": "Loire",
  # Atlas : « Chazelles-sur-Lyon » (1815) = Saint-Galmier ; « Saint-Jean » =
  # Saint-Jean-Soleymieux ; « Belmont » = Belmont-de-la-Loire.
  #
  # LIMITE — ville de Saint-Étienne. Jusqu'en 1857 l'atlas dessine deux
  # cantons, Saint-Étienne-Est (SEE) et -Ouest (SEO) ; à partir de 1863,
  # quatre (Nord-Est, Nord-Ouest, Sud-Est, Sud-Ouest), ceux de la
  # nomenclature. Approximation : SEE = Nord-Est + Sud-Est, SEO = Nord-Ouest
  # + Sud-Ouest. Nord-Ouest et Sud-Ouest n'ont en 1876 qu'un atome-fraction,
  # sans circonscription. Les cartes 1857-1870 de la ville sont à vérifier
  # sur l'original (petites pastilles, flèches). Photos 55-57.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "circos": {
        "Roanne": {"reprend": ["Roanne-1", "Roanne-2"]},
        "Montbrison": {"reprend": ["Montbrison-1", "Montbrison-2"]},
        "Saint-Étienne": {"reste": True}}},
    # « Même découpage qu'en 1815 : 1re Montbrison, 2e Roanne, 3e Saint-Étienne »
    {"depuis": 1820, "jusqu": 1831, "base": "1815", "renommer": {
        "Montbrison": "1", "Roanne": "2", "Saint-Étienne": "3"}},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"cantons": ["Saint-Étienne-Nord-Est", "Saint-Étienne-Sud-Est",
                          "Saint-Étienne-Nord-Ouest", "Saint-Étienne-Sud-Ouest"]},
        "2": {"cantons": ["Saint-Héand", "Le Chambon-Feugerolles",
                          "Saint-Genest-Malifaux", "Bourg-Argental",
                          "Saint-Chamond", "Rive-de-Gier", "Pélussin"]},
        "3": {"cantons": ["Saint-Symphorien-de-Lay", "Néronde", "Feurs",
                          "Saint-Galmier"]},
        "5": {"reprend": ["Roanne-1", "Roanne-2"],
              "moins": ["Saint-Symphorien-de-Lay", "Néronde"]},
        "4": {"reste": True}}},
    {"depuis": 1852, "jusqu": 1857, "base": "1876", "circos": {
        "2": {"reprend": ["Roanne-1", "Roanne-2"]},
        "1": {"reprend": ["Montbrison-1", "Montbrison-2"],
              "plus": ["Saint-Héand"]},
        "3": {"reste": True}}},
    # DOUTE : SEE, cerné d'un trait épais et désigné 2 par une flèche, est
    # une enclave de la 2e ; SEO reste avec Saint-Héand dans la 1re.
    {"depuis": 1857, "jusqu": 1863, "base": "1876", "circos": {
        "4": {"reprend": ["Roanne-1", "Roanne-2"]},
        "3": {"reprend": ["Montbrison-1", "Montbrison-2"]},
        "2": {"cantons": ["Saint-Étienne-Nord-Est", "Saint-Étienne-Sud-Est",
                          "Le Chambon-Feugerolles", "Saint-Genest-Malifaux",
                          "Bourg-Argental"]},
        "1": {"reste": True}}},
    # DOUTE : partage des quatre cantons urbains (pastilles minuscules).
    {"depuis": 1863, "jusqu": 1869, "base": "1876", "circos": {
        "4": {"reprend": ["Roanne-1", "Roanne-2"]},
        "3": {"reprend": ["Montbrison-1", "Montbrison-2"]},
        "2": {"cantons": ["Saint-Étienne-Nord-Est", "Saint-Étienne-Sud-Est",
                          "Saint-Étienne-Sud-Ouest", "Le Chambon-Feugerolles",
                          "Saint-Genest-Malifaux", "Bourg-Argental"]},
        "1": {"reste": True}}},
    # DOUTE : la flèche du 2 vise Saint-Héand et la ville ; Le Chambon,
    # Saint-Genest et Bourg-Argental rejoignent la 1re.
    {"depuis": 1869, "jusqu": 1870, "base": "1876", "circos": {
        "4": {"reprend": ["Roanne-1", "Roanne-2"]},
        "3": {"reprend": ["Montbrison-1", "Montbrison-2"]},
        "2": {"cantons": ["Saint-Héand", "Saint-Étienne-Nord-Est",
                          "Saint-Étienne-Nord-Ouest", "Saint-Étienne-Sud-Est",
                          "Saint-Étienne-Sud-Ouest"]},
        "1": {"reste": True}}},
  ]},

"43": {
  "nom": "Haute-Loire",
  # Photos 53-54.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "fusionner": [
        (["Le Puy-1", "Le Puy-2"], "Le Puy")]},
    # DOUTE : Allègre, cerné d'un trait épais côté Paulhaguet, La Chaise-Dieu
    # et Saint-Paulien, est rangé dans la 2e avec Craponne.
    {"depuis": 1820, "jusqu": 1821, "base": "1876", "circos": {
        "2": {"reprend": ["Yssingeaux"],
              "plus": ["Craponne-sur-Arzon", "Allègre", "Vorey",
                       "Saint-Julien-Chapteuil", "Fay-sur-Lignon",
                       "Le Monastier", "Solignac-sur-Loire"]},
        "1": {"reste": True}}},
    {"depuis": 1821, "jusqu": 1831, "base": "1876", "circos": {
        "2": {"reprend": ["Yssingeaux"],
              "plus": ["Craponne-sur-Arzon", "Vorey", "Saint-Julien-Chapteuil",
                       "Fay-sur-Lignon", "Le Monastier", "Solignac-sur-Loire",
                       "Pradelles"]},
        "1": {"reste": True}}},
    {"depuis": 1831, "jusqu": 1848, "base": "1815", "renommer": {
        "Le Puy": "1", "Brioude": "2", "Yssingeaux": "3"}},
    {"depuis": 1852, "jusqu": 1870, "base": "1876", "circos": {
        "1": {"reprend": ["Yssingeaux", "Le Puy-2"], "moins": ["Cayres"],
              "plus": ["Le Puy-Nord-Ouest"]},
        "2": {"reste": True}}},
  ]},

"44": {
  "nom": "Loire-Atlantique",
  # La ville de Nantes est dessinée d'un seul tenant (« Nantes ») ; la
  # nomenclature a six cantons Nantes-1 à 6, dont 4 et 6 débordent sur la
  # banlieue. Ils vont ensemble partout, sauf 1831-1848 où l'atlas les
  # partage (« 1re : cantons Nantes I, II et III ; 2e : IV, V et VI ») —
  # chiffres romains pris pour les numéros de la nomenclature, INTERPRÉTATION.
  # Photos 49-52.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "circos": {
        "Nantes": {"reprend": ["Nantes-2", "Nantes-3"],
                   "plus": ["Nantes-1", "Nantes-2", "Nantes-3", "Nantes-5"]},
        "Savenay": {"reprend": ["Saint-Nazaire-1", "Saint-Nazaire-2"]},
        "Paimboeuf": {"reprend": ["Paimboeuf"]},
        "Ancenis": {"reprend": ["Ancenis"]},
        "Châteaubriant": {"reprend": ["Châteaubriant"]}}},
    {"depuis": 1820, "jusqu": 1831, "base": "1815", "circos": {
        "1": {"cantons": ["Nantes-1", "Nantes-2", "Nantes-3", "Nantes-4",
                          "Nantes-5", "Nantes-6"]},
        "3": {"reprend": ["Châteaubriant", "Ancenis"],
              "plus": ["La Chapelle-sur-Erdre", "Carquefou"]},
        "4": {"reprend": ["Savenay"]},
        "2": {"reste": True}}},
    {"depuis": 1831, "jusqu": 1848, "base": "1815", "circos": {
        "3": {"reprend": ["Nantes"]},
        "1": {"cantons": ["Nantes-1", "Nantes-2", "Nantes-3"]},
        "2": {"cantons": ["Nantes-4", "Nantes-5", "Nantes-6"]},
        "4": {"reprend": ["Ancenis"]},
        "5": {"reprend": ["Châteaubriant"]},
        "6": {"reprend": ["Paimboeuf"]},
        "7": {"reprend": ["Savenay"]}}},
    # Bouaye, cerné d'un trait épais et marqué 1 : enclave de la 1re.
    {"depuis": 1852, "jusqu": 1857, "base": "1876", "circos": {
        "1": {"reprend": ["Ancenis"],
              "plus": ["Saint-Julien-de-Vouvantes", "Moisdon-la-Rivière",
                       "Nort-sur-Erdre", "Le Loroux-Bottereau", "Vallet",
                       "Clisson", "Bouaye"]},
        "2": {"cantons": ["La Chapelle-sur-Erdre", "Carquefou", "Nantes-1",
                          "Nantes-2", "Nantes-3", "Nantes-4", "Nantes-5",
                          "Nantes-6"]},
        "3": {"reprend": ["Châteaubriant", "Saint-Nazaire-1",
                          "Saint-Nazaire-2"],
              "moins": ["Saint-Julien-de-Vouvantes", "Moisdon-la-Rivière",
                        "Nort-sur-Erdre", "Guérande", "Le Croisic",
                        "Saint-Nazaire"]},
        "4": {"reste": True}}},
    # DOUTE (fort) : la carte 1857-1863 coupe la région nantaise en morceaux
    # (un « 4 » posé entre Saint-Étienne-de-Montluc, La Chapelle et Nantes,
    # un autre dans Vertou ; la limite Ligné / Le Loroux n'est pas épaissie).
    # Lecture : 4 = Guérande, Le Croisic, Saint-Nazaire, l'arrondissement de
    # Paimbœuf, Machecoul, Saint-Philbert, Legé, plus La Chapelle et Vertou ;
    # 2 = Nantes, Carquefou, Le Loroux, Vallet ; 1 = Ancenis, Nozay, Nort,
    # Moisdon, Saint-Julien, et au sud Bouaye, Aigrefeuille, Clisson.
    {"depuis": 1857, "jusqu": 1863, "base": "1876", "circos": {
        "1": {"reprend": ["Ancenis"],
              "plus": ["Saint-Julien-de-Vouvantes", "Moisdon-la-Rivière",
                       "Nozay", "Nort-sur-Erdre", "Bouaye", "Aigrefeuille-sur-Maine",
                       "Clisson"]},
        "2": {"cantons": ["Carquefou", "Le Loroux-Bottereau", "Vallet",
                          "Nantes-1", "Nantes-2", "Nantes-3", "Nantes-4",
                          "Nantes-5", "Nantes-6"]},
        "4": {"reprend": ["Paimboeuf"],
              "plus": ["Guérande", "Le Croisic", "Saint-Nazaire", "Machecoul",
                       "Saint-Philbert-de-Grand-Lieu", "Legé",
                       "La Chapelle-sur-Erdre", "Vertou"]},
        "3": {"reste": True}}},
    # DOUTE : Legé, marqué 4 mais séparé par un trait épais du seul Machecoul.
    {"depuis": 1863, "jusqu": 1869, "base": "1876", "circos": {
        "1": {"reprend": ["Ancenis"],
              "plus": ["Saint-Julien-de-Vouvantes", "Moisdon-la-Rivière",
                       "Nozay", "Bouaye", "Aigrefeuille-sur-Maine", "Clisson",
                       "Machecoul", "Saint-Philbert-de-Grand-Lieu"]},
        "2": {"cantons": ["Carquefou", "Le Loroux-Bottereau", "Vallet",
                          "Nantes-1", "Nantes-2", "Nantes-3", "Nantes-4",
                          "Nantes-5", "Nantes-6"]},
        "4": {"reprend": ["Paimboeuf"],
              "plus": ["Guérande", "Le Croisic", "Saint-Nazaire",
                       "Saint-Étienne-de-Montluc", "La Chapelle-sur-Erdre",
                       "Vertou", "Legé"]},
        "3": {"reste": True}}},
    {"depuis": 1869, "jusqu": 1870, "base": "1876", "circos": {
        "1": {"reprend": ["Ancenis", "Nantes-3"],
              "plus": ["Saint-Julien-de-Vouvantes", "Moisdon-la-Rivière",
                       "Nozay", "Clisson"]},
        "2": {"cantons": ["Carquefou", "Le Loroux-Bottereau", "Vallet",
                          "Vertou", "Nantes-1", "Nantes-2", "Nantes-3",
                          "Nantes-4", "Nantes-5", "Nantes-6"]},
        "4": {"reprend": ["Paimboeuf"],
              "plus": ["Guérande", "Le Croisic", "Herbignac", "Saint-Nazaire",
                       "Saint-Étienne-de-Montluc", "La Chapelle-sur-Erdre"]},
        "3": {"reste": True}}},
  ]},

"45": {
  "nom": "Loiret",
  # Orléans-Est et Orléans-Ouest n'ont en 1876 qu'un atome-fraction, sans
  # circonscription : ils sont nommés à chaque période. Photos 46-48.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "circos": {
        "Orléans": {"reprend": ["Orléans-1", "Orléans-2"],
                    "plus": ["Orléans-Est", "Orléans-Ouest"]},
        "Pithiviers": {"reprend": ["Pithiviers"]},
        "Montargis": {"reprend": ["Montargis"]},
        "Gien": {"reprend": ["Gien"]}}},
    {"depuis": 1820, "jusqu": 1831, "base": "1876", "circos": {
        "3": {"reprend": ["Pithiviers"],
              "plus": ["Artenay", "Neuville-aux-Bois", "Bellegarde",
                       "Châteauneuf-sur-Loire"]},
        "1": {"reprend": ["Orléans-1", "Orléans-2"],
              "plus": ["Orléans-Est", "Orléans-Ouest"],
              "moins": ["Artenay", "Neuville-aux-Bois", "Châteauneuf-sur-Loire"]},
        "2": {"reste": True}}},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"reprend": ["Pithiviers"]},
        "2": {"reprend": ["Orléans-1"],
              "plus": ["Orléans-Est", "Orléans-Ouest"]},
        "3": {"reprend": ["Orléans-2"]},
        "4": {"reprend": ["Gien"]},
        "5": {"reprend": ["Montargis"]}}},
    {"depuis": 1852, "jusqu": 1857, "base": "1876", "circos": {
        "2": {"reprend": ["Montargis", "Gien"],
              "plus": ["Puiseaux", "Beaune-la-Rolande", "Châteauneuf-sur-Loire"]},
        "1": {"reste": True}}},
    # « Le canton d'Orléans-Sud était divisé : la partie de la ville
    # appartenant à ce canton était rattachée à la 1re circonscription, et
    # les autres communes à la 2e. » Orléans-Sud est posé entier dans la
    # 1re — LIMITE, à reprendre à l'échelle de l'atome.
    {"depuis": 1857, "jusqu": 1870, "base": "1876", "circos": {
        "3": {"reprend": ["Montargis"],
              "plus": ["Malesherbes", "Puiseaux", "Beaune-la-Rolande"]},
        "2": {"reprend": ["Gien"],
              "plus": ["Cléry-Saint-André", "La Ferté-Saint-Aubin", "Jargeau",
                       "Châteauneuf-sur-Loire"]},
        "1": {"reste": True}}},
  ]},

"46": {
  "nom": "Lot",
  # Atlas : « Gorses » (1815) = Latronquière ; « Saint-Germain-du-Bel-Air »
  # = Saint-Germain. Photos 44-45.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "fusionner": [
        (["Cahors-1", "Cahors-2"], "Cahors")]},
    {"depuis": 1820, "jusqu": 1831, "base": "1876", "renommer": {
        "Cahors-1": "1", "Cahors-2": "2", "Figeac": "3", "Gourdon": "4"}},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"reprend": ["Cahors-1"]},
        "2": {"reprend": ["Cahors-2"]},
        "5": {"cantons": ["Souillac", "Martel", "Vayrac", "Bretenoux",
                          "Saint-Céré"]},
        "4": {"reprend": ["Gourdon"],
              "moins": ["Souillac", "Martel", "Vayrac"]},
        "3": {"reste": True}}},
    {"depuis": 1852, "jusqu": 1870, "base": "1876", "circos": {
        "1": {"reprend": ["Cahors-1", "Cahors-2"],
              "plus": ["Labastide-Murat", "Livernon", "Cajarc"]},
        "2": {"reste": True}}},
  ]},

"47": {
  "nom": "Lot-et-Garonne",
  # La carte de 1815 n'est pas sur les photos (seul son bas apparaît) ; la
  # page 1876 dit « même découpage et mêmes appellations qu'en 1815 » — d'où
  # 1815 = 1876. Photos 41-43.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "copie": True},
    # Cantons divisés (note de l'atlas) : Prayssas (13 communes, dont le
    # chef-lieu, à la 3e, les autres à la 1re) et Lavardac (7 communes, dont
    # le chef-lieu, à la 1re, les autres à la 2e). Chacun est posé ENTIER du
    # côté de son chef-lieu — LIMITE, à reprendre à l'échelle de l'atome.
    {"depuis": 1820, "jusqu": 1831, "base": "1876", "circos": {
        "2": {"reprend": ["Marmande"], "moins": ["Castelmoron-sur-Lot"],
              "plus": ["Casteljaloux", "Damazan", "Houeillès"]},
        "3": {"reprend": ["Villeneuve-sur-Lot"],
              "plus": ["Castelmoron-sur-Lot", "Prayssas"]},
        "1": {"reste": True}}},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"cantons": ["Agen-1", "Agen-2"]},
        "2": {"reprend": ["Agen"], "moins": ["Agen-1", "Agen-2"]},
        "3": {"reprend": ["Marmande"], "moins": ["Castelmoron-sur-Lot"]},
        "4": {"reprend": ["Nérac"]},
        "5": {"reprend": ["Villeneuve-sur-Lot"], "plus": ["Castelmoron-sur-Lot"]}}},
    {"depuis": 1852, "jusqu": 1863, "base": "1876", "circos": {
        "3": {"cantons": ["Duras", "Seyches", "Lauzun", "Marmande",
                          "Castillonnès", "Villeréal", "Cancon", "Monclar",
                          "Monflanquin", "Villeneuve-sur-Lot"]},
        "2": {"reprend": ["Nérac"],
              "plus": ["Meilhan-sur-Garonne", "Bouglon", "Le Mas-d'Agenais",
                       "Tonneins", "Castelmoron-sur-Lot", "Laplume"]},
        "1": {"reste": True}}},
    # DOUTE : Castelmoron, rangé dans la 2e avec Monclar (le trait épais
    # longe son flanc ouest et son flanc sud).
    {"depuis": 1863, "jusqu": 1870, "base": "1876", "circos": {
        "2": {"cantons": ["Duras", "Seyches", "Lauzun", "Marmande",
                          "Castillonnès", "Villeréal", "Cancon", "Monclar",
                          "Castelmoron-sur-Lot", "Villeneuve-sur-Lot"]},
        "3": {"reprend": ["Nérac"],
              "plus": ["Meilhan-sur-Garonne", "Bouglon", "Le Mas-d'Agenais",
                       "Tonneins", "Laplume", "Astaffort"]},
        "1": {"reste": True}}},
  ]},

"48": {
  "nom": "Lozère",
  # Atlas : « Serverette » = Saint-Alban-sur-Limagnole ; « Chirac » =
  # Saint-Germain-du-Teil ; « Saint-Georges-de-Lévéjac » = Le Massegros ;
  # « Barre-des-Cévennes » = Barre. Photo 40 (la page 371 n'est pas
  # photographiée ; « 1852-1870 : pas de découpage » se lit en transparence
  # sur la photo 39 — un seul député, élu par tout le département).
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "copie": True},
    # 1820-1831 : « pas de découpage (collège de département) ». Rien n'est
    # posé, comme pour les Vosges. Idem 1852-1870.
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "renommer": {
        "Mende": "1", "Florac": "2", "Marvejols": "3"}},
  ]},

"49": {
  "nom": "Maine-et-Loire",
  # Atlas : « Briollay » = Tiercé ; « Beaufort » = Beaufort-en-Vallée.
  # Photos 37-39.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "circos": {
        "Angers": {"reprend": ["Angers-1", "Angers-2"],
                   "moins": ["Thouarcé", "Tiercé"]},
        "Segré": {"reprend": ["Segré"], "plus": ["Tiercé"]},
        "Saumur": {"reprend": ["Saumur"], "plus": ["Thouarcé"]},
        "Baugé": {"reprend": ["Baugé"]},
        "Beaupréau": {"reprend": ["Cholet-1", "Cholet-2"]}}},
    # « Le canton de Thouarcé était divisé : Vauchrétien, Notre-Dame-
    # d'Alençon, Chavagnes et les communes situées plus à l'est appartenaient
    # à la 2e ; toutes les autres à la 3e. » Thouarcé posé entier dans la 3e
    # (son chef-lieu est à l'ouest de la ligne) — LIMITE.
    {"depuis": 1820, "jusqu": 1831, "base": "1876", "circos": {
        "1": {"cantons": ["Angers-Nord-Ouest", "Angers-Nord-Est",
                          "Angers-Sud-Est", "Saint-Georges-sur-Loire",
                          "Les Ponts-de-Cé", "Chalonnes-sur-Loire", "Durtal",
                          "Seiches-sur-le-Loir", "Baugé"]},
        "2": {"reprend": ["Saumur"],
              "plus": ["Noyant", "Beaufort-en-Vallée", "Longué"]},
        "3": {"reprend": ["Cholet-1", "Cholet-2"], "plus": ["Thouarcé"]},
        "4": {"reste": True}}},
    # Tiercé (« Briollay »), cerné et marqué 2 : enclave de la 2e.
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"cantons": ["Angers-Nord-Ouest", "Angers-Nord-Est",
                          "Angers-Sud-Est"]},
        "2": {"cantons": ["Le Louroux-Béconnais", "Saint-Georges-sur-Loire",
                          "Chalonnes-sur-Loire", "Les Ponts-de-Cé", "Thouarcé",
                          "Tiercé"]},
        "3": {"reprend": ["Baugé"]},
        "4": {"reprend": ["Cholet-1", "Cholet-2"]},
        "5": {"cantons": ["Saumur-Nord-Ouest", "Saumur-Nord-Est", "Saumur-Sud"]},
        "6": {"cantons": ["Gennes", "Doué-la-Fontaine", "Vihiers",
                          "Montreuil-Bellay"]},
        "7": {"reprend": ["Segré"]}}},
    {"depuis": 1852, "jusqu": 1863, "base": "1876", "circos": {
        "1": {"reprend": ["Angers-1", "Angers-2"], "moins": ["Thouarcé"]},
        "2": {"reprend": ["Segré", "Baugé"]},
        "3": {"reprend": ["Saumur"], "plus": ["Thouarcé"]},
        "4": {"reprend": ["Cholet-1", "Cholet-2"]}}},
    # Pouancé et Segré, cernés et marqués 2 : enclave de la 2e.
    # Chalonnes passe à la 4e.
    {"depuis": 1863, "jusqu": 1870, "base": "1876", "circos": {
        "1": {"reprend": ["Angers-1", "Angers-2"],
              "moins": ["Thouarcé", "Chalonnes-sur-Loire"],
              "plus": ["Candé", "Le Lion-d'Angers"]},
        "2": {"reprend": ["Baugé"],
              "plus": ["Châteauneuf-sur-Sarthe", "Pouancé", "Segré"]},
        "3": {"reprend": ["Saumur"], "plus": ["Thouarcé"]},
        "4": {"reprend": ["Cholet-1", "Cholet-2"],
              "plus": ["Chalonnes-sur-Loire"]}}},
  ]},

"50": {
  "nom": "Manche",
  # Photos 35-36.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "fusionner": [
        (["Coutances-1", "Coutances-2"], "Coutances"),
        (["Avranches-1", "Avranches-2"], "Avranches")]},
    {"depuis": 1820, "jusqu": 1831, "base": "1876", "circos": {
        "1": {"reprend": ["Saint-Lô"]},
        "2": {"reprend": ["Avranches-1", "Avranches-2", "Mortain"]},
        "3": {"reprend": ["Coutances-1", "Coutances-2"],
              "plus": ["Sainte-Mère-Église"]},
        "4": {"reste": True}}},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"cantons": ["Saint-Lô", "Canisy", "Torigni-sur-Vire",
                          "Tessy-sur-Vire", "Percy"]},
        "2": {"cantons": ["Carentan", "Saint-Jean-de-Daye", "Marigny",
                          "Saint-Clair-sur-l'Elle"]},
        "3": {"reprend": ["Cherbourg"]},
        "4": {"reprend": ["Valognes"]},
        "5": {"reprend": ["Coutances-1"]},
        "6": {"reprend": ["Coutances-2"]},
        "7": {"reprend": ["Mortain"]},
        "8": {"reprend": ["Avranches-1", "Avranches-2"]}}},
    # Granville, cerné et rattaché à Bréhal : 3e. Villedieu et Saint-Pois
    # passent à la 1re (par Percy).
    {"depuis": 1852, "jusqu": 1870, "base": "1876", "circos": {
        "1": {"reprend": ["Saint-Lô"],
              "plus": ["Barneville", "Saint-Sauveur-le-Vicomte",
                       "Sainte-Mère-Église", "Villedieu", "Saint-Pois"]},
        "3": {"reprend": ["Coutances-1", "Coutances-2"], "plus": ["Granville"]},
        "4": {"reprend": ["Cherbourg", "Valognes"],
              "moins": ["Barneville", "Saint-Sauveur-le-Vicomte",
                        "Sainte-Mère-Église"]},
        "2": {"reste": True}}},
  ]},

"51": {
  "nom": "Marne",
  # Atlas : « Écury » = Écury-sur-Coole ; « Châlons-sur-Marne » = Châlons ;
  # « Dommartin-sur-Yèvre » = Dammartin-sur-Yvre ; « Saint-Rémy-en-
  # Bouzemont » = Saint-Remy-en-Bouzemont-Saint-Genest-et-Isson ;
  # « Reims I, II, III » = Reims-1, -2, -3. Photos 33-34.
  "periodes": [
    # DOUTE : Vertus. Le trait épais de 1815 passe entre Vertus et Écury et
    # non entre Vertus et Avize : Vertus va avec Épernay (il est dans la
    # circonscription de Châlons en 1876).
    {"depuis": 1815, "jusqu": 1820, "base": "1876",
     "fusionner": [(["Reims-1", "Reims-2"], "Reims")],
     "deplacer": [(["Vertus"], "Épernay")]},
    {"depuis": 1820, "jusqu": 1831, "base": "1876", "circos": {
        "3": {"reprend": ["Reims-1", "Reims-2"]},
        "2": {"reprend": ["Sainte-Menehould", "Vitry-le-François"]},
        "1": {"reste": True}}},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "2": {"reprend": ["Reims-1", "Reims-2"]},
        "1": {"cantons": ["Reims-1", "Reims-2", "Reims-3"]},
        "3": {"reprend": ["Châlons-sur-Marne"]},
        "4": {"reprend": ["Épernay"]},
        "5": {"reprend": ["Sainte-Menehould"]},
        "6": {"reprend": ["Vitry-le-François"]}}},
    {"depuis": 1852, "jusqu": 1870, "base": "1876", "circos": {
        "3": {"reprend": ["Reims-1", "Reims-2"], "moins": ["Ay"]},
        "1": {"reprend": ["Sainte-Menehould", "Vitry-le-François"],
              "plus": ["Châlons", "Suippes", "Marson"]},
        "2": {"reste": True}}},
  ]},

"52": {
  "nom": "Haute-Marne",
  # Atlas : « Ville-sur-Aujon » (1815) = Châteauvillain ; « Sailly » =
  # Poissons ; « Donjeux » = Doulaincourt ; « Nogent-le-Roi » = Nogent-en-
  # Bassigny ; « La Ferté » = Laferté-sur-Amance ; « Bourbonne » =
  # Bourbonne-les-Bains. 1815 : « même découpage et mêmes appellations » que
  # 1876. Photos 31-32.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "copie": True},
    {"depuis": 1820, "jusqu": 1831, "base": "1876", "circos": {
        "1": {"reprend": ["Wassy"],
              "plus": ["Chaumont", "Juzennecourt", "Vignory", "Andelot",
                       "Saint-Blin"]},
        "2": {"reste": True}}},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"cantons": ["Auberive", "Langres", "Longeau", "Prauthoy",
                          "Neuilly-l'Évêque"]},
        "3": {"reprend": ["Chaumont"]},
        "4": {"reprend": ["Wassy"]},
        "2": {"reste": True}}},
    {"depuis": 1852, "jusqu": 1870, "base": "1876", "circos": {
        "2": {"reprend": ["Langres"],
              "plus": ["Arc-en-Barrois", "Nogent-en-Bassigny", "Clefmont"]},
        "1": {"reste": True}}},
  ]},

"53": {
  "nom": "Mayenne",
  # Photo 30. La carte 1852-1870 n'est PAS photographiée (page 396 ?) :
  # période non posée.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "fusionner": [
        (["Laval-1", "Laval-2"], "Laval"),
        (["Mayenne-1", "Mayenne-2"], "Mayenne")]},
    # « Même découpage qu'en 1815 : 1re Laval, 2e Château-Gontier,
    # 3e Mayenne »
    {"depuis": 1820, "jusqu": 1831, "base": "1815", "renommer": {
        "Laval": "1", "Château-Gontier": "2", "Mayenne": "3"}},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"cantons": ["Laval-Ouest", "Laval-Est"]},
        "2": {"reprend": ["Laval-1", "Laval-2"],
              "moins": ["Laval-Ouest", "Laval-Est"]},
        "3": {"cantons": ["Mayenne-Ouest", "Mayenne-Est"]},
        "4": {"reprend": ["Mayenne-1", "Mayenne-2"],
              "moins": ["Mayenne-Ouest", "Mayenne-Est"]},
        "5": {"reprend": ["Château-Gontier"]}}},
  ]},

"99": {
  "nom": "Meurthe",
  # La Meurthe d'avant 1871, code 99 de la base : 29 cantons, lus au
  # 1er juin 1870 (elle n'existe plus en 1878). Pas de découpage de
  # référence : toutes les périodes sont écrites en listes de cantons.
  # Atlas : « Domèvre » = Domèvre-en-Haye ; « Colombey-les-Belles » =
  # Colombey ; « Blamont » = Blâmont. Photos 27-29.
  "date": "1870-06-01",
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "circos": {
        "Toul": {"cantons": ["Thiaucourt", "Domèvre-en-Haye", "Toul-Nord",
                             "Toul-Sud", "Colombey"]},
        "Nancy": {"cantons": ["Pont-à-Mousson", "Nomeny", "Nancy-Est",
                              "Nancy-Nord", "Nancy-Ouest", "Saint-Nicolas"]},
        "Château-Salins": {"cantons": ["Delme", "Château-Salins", "Dieuze",
                                       "Albestroff", "Vic-sur-Seille"]},
        "Sarrebourg": {"cantons": ["Fénétrange", "Phalsbourg", "Sarrebourg",
                                   "Réchicourt", "Lorquin"]},
        "Lunéville": {"reste": True}}},
    {"depuis": 1820, "jusqu": 1831, "base": "1876", "circos": {
        "1": {"cantons": ["Thiaucourt", "Pont-à-Mousson", "Domèvre-en-Haye",
                          "Toul-Nord", "Toul-Sud", "Colombey", "Nancy-Est",
                          "Nancy-Nord", "Nancy-Ouest"]},
        "3": {"cantons": ["Nomeny", "Delme", "Château-Salins", "Albestroff",
                          "Dieuze", "Vic-sur-Seille", "Fénétrange",
                          "Sarrebourg", "Phalsbourg", "Réchicourt"]},
        "2": {"reste": True}}},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"cantons": ["Nancy-Est", "Nancy-Nord", "Nancy-Ouest"]},
        "2": {"cantons": ["Pont-à-Mousson", "Nomeny", "Saint-Nicolas",
                          "Vézelise", "Haroué"]},
        "4": {"cantons": ["Delme", "Château-Salins", "Albestroff", "Dieuze",
                          "Vic-sur-Seille"]},
        "5": {"cantons": ["Thiaucourt", "Domèvre-en-Haye", "Toul-Nord",
                          "Toul-Sud", "Colombey"]},
        "6": {"cantons": ["Fénétrange", "Sarrebourg", "Phalsbourg",
                          "Réchicourt", "Lorquin"]},
        "3": {"reste": True}}},
    {"depuis": 1852, "jusqu": 1863, "base": "1876", "circos": {
        "1": {"cantons": ["Thiaucourt", "Domèvre-en-Haye", "Toul-Nord",
                          "Toul-Sud", "Colombey", "Nancy-Nord", "Nancy-Ouest",
                          "Vézelise", "Haroué"]},
        "3": {"cantons": ["Pont-à-Mousson", "Nomeny", "Delme",
                          "Château-Salins", "Albestroff", "Dieuze",
                          "Vic-sur-Seille", "Fénétrange", "Sarrebourg",
                          "Phalsbourg"]},
        "2": {"reste": True}}},
    {"depuis": 1863, "jusqu": 1870, "base": "1876", "circos": {
        "1": {"cantons": ["Thiaucourt", "Pont-à-Mousson", "Nomeny",
                          "Domèvre-en-Haye", "Toul-Nord", "Toul-Sud",
                          "Colombey", "Nancy-Nord", "Nancy-Ouest", "Vézelise",
                          "Haroué"]},
        "3": {"cantons": ["Albestroff", "Dieuze", "Fénétrange", "Phalsbourg",
                          "Sarrebourg", "Réchicourt", "Blâmont", "Lorquin",
                          "Baccarat"]},
        "2": {"reste": True}}},
  ]},

"55": {
  "nom": "Meuse",
  # Atlas : « Vigneulles » = Vigneulles-lès-Hattonchâtel ; « Verdun » =
  # Verdun-sur-Meuse. 1876 : « même découpage et mêmes appellations qu'en
  # 1815 ». Photos 25-26.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "copie": True},
    {"depuis": 1820, "jusqu": 1831, "base": "1876", "circos": {
        "2": {"reprend": ["Montmédy", "Verdun"]},
        "1": {"reste": True}}},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "renommer": {
        "Bar-le-Duc": "1", "Commercy": "2", "Montmédy": "3", "Verdun": "4"}},
    {"depuis": 1852, "jusqu": 1857, "base": "1876", "circos": {
        "2": {"reprend": ["Montmédy", "Verdun"],
              "plus": ["Vigneulles-lès-Hattonchâtel"]},
        "1": {"reste": True}}},
    {"depuis": 1857, "jusqu": 1870, "base": "1876", "circos": {
        "3": {"reprend": ["Montmédy"],
              "plus": ["Varennes-en-Argonne", "Charny-sur-Meuse", "Étain"]},
        "2": {"cantons": ["Clermont-en-Argonne", "Verdun-sur-Meuse",
                          "Fresnes-en-Woëvre", "Souilly", "Triaucourt",
                          "Vaubecourt", "Vigneulles-lès-Hattonchâtel",
                          "Saint-Mihiel"]},
        "1": {"reste": True}}},
  ]},

"56": {
  "nom": "Morbihan",
  # Atlas : « Carentoir » (avant 1852) = La Gacilly ; « La Trinité » =
  # La Trinité-Porhoët ; « Saint-Jean » = Saint-Jean-Brévelay ; « Lorient I,
  # II » = Lorient-1 (atome-fraction sans circonscription en 1876) et
  # Lorient-2. Photos 23-24.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "circos": {
        "Lorient": {"reprend": ["Lorient-1", "Lorient-2"], "plus": ["Lorient-1"]},
        "Vannes": {"reprend": ["Vannes-1", "Vannes-2"]},
        "Pontivy": {"reprend": ["Pontivy"]},
        "Ploërmel": {"reprend": ["Ploërmel"]}}},
    {"depuis": 1820, "jusqu": 1831, "base": "1876", "circos": {
        "3": {"reprend": ["Pontivy"], "moins": ["Locminé"], "plus": ["Plouay"]},
        "4": {"reprend": ["Ploërmel"]},
        "2": {"cantons": ["Pont-Scorff", "Lorient-1", "Lorient-2", "Port-Louis",
                          "Hennebont", "Belz", "Quiberon", "Belle-Île"]},
        "1": {"reste": True}}},
    # DOUTE : la 1re (Vannes-Est, Vannes-Ouest, Grand-Champ) ; Elven et
    # Sarzeau, hors du trait épais, vont à la 2e.
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"cantons": ["Vannes-Est", "Vannes-Ouest", "Grand-Champ"]},
        "3": {"cantons": ["Lorient-1", "Lorient-2"]},
        "4": {"cantons": ["Plouay", "Pont-Scorff", "Port-Louis", "Hennebont",
                          "Pluvigner", "Belz", "Auray", "Quiberon",
                          "Belle-Île"]},
        "5": {"reprend": ["Pontivy"]},
        "6": {"reprend": ["Ploërmel"]},
        "2": {"reste": True}}},
    # Belle-Île, marquée 1 dans son cartouche : enclave de la 1re.
    {"depuis": 1852, "jusqu": 1870, "base": "1876", "circos": {
        "3": {"reprend": ["Pontivy", "Ploërmel"],
              "moins": ["Gourin", "Le Faouët", "Malestroit"]},
        "2": {"cantons": ["Gourin", "Le Faouët", "Plouay", "Pont-Scorff",
                          "Lorient-1", "Lorient-2", "Hennebont", "Port-Louis",
                          "Pluvigner", "Belz", "Quiberon", "Auray"]},
        "1": {"reste": True}}},
  ]},

"58": {
  "nom": "Nièvre",
  # Atlas : « Château-Chinon » = Château-Chinon (Ville). Photos 18-19.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "fusionner": [
        (["Nevers-1", "Nevers-2"], "Nevers")]},
    # Saint-Saulge, cerné de traits épais à l'ouest, au sud et à l'est,
    # reste attaché à la 2e par Prémery et Brinon.
    {"depuis": 1820, "jusqu": 1831, "base": "1876", "circos": {
        "2": {"reprend": ["Cosne", "Clamecy"],
              "plus": ["Montsauche", "Saint-Saulge"]},
        "1": {"reste": True}}},
    # « Même découpage qu'en 1815 : 1re Nevers, 2e Château-Chinon,
    # 3e Clamecy, 4e Cosne »
    {"depuis": 1831, "jusqu": 1848, "base": "1815", "renommer": {
        "Nevers": "1", "Château-Chinon": "2", "Clamecy": "3", "Cosne": "4"}},
    {"depuis": 1852, "jusqu": 1863, "base": "1876", "circos": {
        "2": {"reprend": ["Clamecy", "Château-Chinon"], "plus": ["Fours"]},
        "1": {"reste": True}}},
    {"depuis": 1863, "jusqu": 1870, "base": "1876", "circos": {
        "2": {"reprend": ["Cosne"], "plus": ["Varzy"]},
        "3": {"reprend": ["Clamecy", "Château-Chinon"],
              "moins": ["Varzy", "Moulins-Engilbert", "Luzy"]},
        "1": {"reste": True}}},
  ]},

"59": {
  "nom": "Nord",
  # Atlas : « Roubaix » = Roubaix-Est + Roubaix-Ouest ; « Maubeuge » =
  # Maubeuge-Nord ; « Bourbourg » = Bourbourg-Ville ; « Quesnoy » =
  # Quesnoy-sur-Deûle ; « Templeuve » (1815) = Cysoing ; « Bailleul-Nord-
  # Ouest » = Bailleul-Nord-Est. Dour, Merbes-le-Château et Beaumont (1815)
  # sont cédés à la Belgique en novembre 1815 et ne sont pas dans la base.
  # Photos 12-17.
  #
  # LIMITE — agglomération de Lille. Les cinq cantons urbains (LO, LC, LNE,
  # LSE, LSO) sont des pastilles minuscules ; leur partage entre
  # circonscriptions (1821-1870) est lu au mieux et marqué DOUTE à chaque
  # période. Tous les autres cantons sont lus sans hésitation.
  "periodes": [
    # Valenciennes n'a pas de collège en 1815 : son arrondissement vote avec
    # Douai (pas de cadre « Valenciennes » sur la carte).
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "circos": {
        "Dunkerque": {"reprend": ["Dunkerque-1", "Dunkerque-2"]},
        "Hazebrouck": {"reprend": ["Hazebrouck-1", "Hazebrouck-2"]},
        "Douai": {"reprend": ["Douai-1", "Douai-2", "Valenciennes-1",
                              "Valenciennes-2"]},
        "Cambrai": {"reprend": ["Cambrai-1", "Cambrai-2"]},
        "Avesnes": {"reprend": ["Avesnes-1", "Avesnes-2"],
                    "plus": ["Le Quesnoy-Ouest"]},
        "Lille": {"reste": True}}},
    {"depuis": 1820, "jusqu": 1821, "base": "1876", "circos": {
        "1": {"reprend": ["Dunkerque-1", "Dunkerque-2"]},
        "2": {"reprend": ["Hazebrouck-1", "Hazebrouck-2"]},
        "3": {"cantons": ["Lille-Ouest", "Lille-Centre", "Lille-Nord-Est",
                          "Lille-Sud-Est", "Lille-Sud-Ouest"]},
        "5": {"reprend": ["Avesnes-1", "Avesnes-2"],
              "plus": ["Le Quesnoy-Ouest"]},
        "6": {"reprend": ["Cambrai-1", "Cambrai-2"]},
        "7": {"reprend": ["Douai-1", "Douai-2"]},
        "8": {"reprend": ["Valenciennes-1", "Valenciennes-2"]},
        "4": {"reste": True}}},
    # DOUTE : LC et LNE rangés dans la 3e (avec Lille-Ouest, Quesnoy,
    # Tourcoing, Roubaix, Lannoy), LSO et LSE dans la 4e.
    {"depuis": 1821, "jusqu": 1831, "base": "1820", "circos": {
        "3": {"cantons": ["Quesnoy-sur-Deûle", "Tourcoing-Nord",
                          "Tourcoing-Sud", "Roubaix-Est", "Roubaix-Ouest",
                          "Lannoy", "Lille-Ouest", "Lille-Centre",
                          "Lille-Nord-Est"]},
        "4": {"reprend": ["4"], "plus": ["Lille-Sud-Est", "Lille-Sud-Ouest"],
              "moins": ["Quesnoy-sur-Deûle", "Tourcoing-Nord",
                        "Tourcoing-Sud", "Roubaix-Est", "Roubaix-Ouest",
                        "Lannoy"]},
        "1": {"reprend": ["1"]}, "2": {"reprend": ["2"]},
        "5": {"reprend": ["5"]}, "6": {"reprend": ["6"]},
        "7": {"reprend": ["7"]}, "8": {"reprend": ["8"]}}},
    # DOUTE : la 1re (flèche vers Lille-Ouest) = LO, LC, LSO ; la 2e (trait
    # vers LNE) = LNE, LSE. Arleux, isolé, est désigné 5 : la 5e est en deux
    # morceaux (Orchies-Marchiennes et Arleux).
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"cantons": ["Lille-Ouest", "Lille-Centre", "Lille-Sud-Ouest"]},
        "2": {"cantons": ["Lille-Nord-Est", "Lille-Sud-Est"]},
        "4": {"cantons": ["Douai-Nord", "Douai-Ouest", "Douai-Sud"]},
        "5": {"cantons": ["Orchies", "Marchiennes", "Arleux"]},
        "6": {"cantons": ["Dunkerque-Ouest", "Dunkerque-Est"]},
        "7": {"reprend": ["Dunkerque-1", "Dunkerque-2"],
              "moins": ["Dunkerque-Ouest", "Dunkerque-Est"]},
        "8": {"cantons": ["Cambrai-Ouest", "Cambrai-Est"]},
        "9": {"cantons": ["Marcoing", "Carnières", "Clary", "Solesmes",
                          "Le Cateau"]},
        "10": {"reprend": ["Valenciennes-1", "Valenciennes-2"]},
        "11": {"reprend": ["Avesnes-1", "Avesnes-2"],
               "plus": ["Le Quesnoy-Ouest"]},
        "12": {"reprend": ["Hazebrouck-1", "Hazebrouck-2"]},
        "3": {"reste": True}}},
    # DOUTE : LO, LC, LSO dans la 1re ; LNE, LSE dans la 2e.
    {"depuis": 1852, "jusqu": 1863, "base": "1876", "circos": {
        "1": {"cantons": ["Quesnoy-sur-Deûle", "Armentières", "Haubourdin",
                          "Lille-Ouest", "Lille-Centre", "Lille-Sud-Ouest"]},
        "2": {"cantons": ["Tourcoing-Nord", "Tourcoing-Sud", "Roubaix-Est",
                          "Roubaix-Ouest", "Lannoy", "Lille-Nord-Est",
                          "Lille-Sud-Est", "Cysoing", "Seclin", "La Bassée",
                          "Pont-à-Marcq"]},
        "3": {"reprend": ["Valenciennes-1", "Valenciennes-2"]},
        "4": {"reprend": ["Hazebrouck-1", "Hazebrouck-2"]},
        "5": {"reprend": ["Dunkerque-1", "Dunkerque-2"]},
        "6": {"reprend": ["Douai-1", "Douai-2"]},
        "7": {"reprend": ["Cambrai-1", "Cambrai-2"]},
        "8": {"reste": True}}},
    # « Les 2e et 4e circonscriptions sont divisées en deux tronçons, la 3e
    # en trois. » DOUTE (fort) : la ville de Lille et Seclin. Lecture : LO,
    # LC, LNE à la 2e (avec Quesnoy et, par Lannoy, son second tronçon) ; LSO
    # à la 3e avec Haubourdin ; LSE et Seclin à la 4e avec Cysoing.
    {"depuis": 1863, "jusqu": 1870, "base": "1876", "circos": {
        "1": {"reprend": ["Dunkerque-1", "Dunkerque-2"],
              "plus": ["Cassel", "Hazebrouck-Nord", "Hazebrouck-Sud"]},
        "2": {"cantons": ["Steenvoorde", "Bailleul-Sud-Ouest",
                          "Bailleul-Nord-Est", "Armentières",
                          "Quesnoy-sur-Deûle", "Lille-Ouest", "Lille-Centre",
                          "Lille-Nord-Est", "Lannoy"]},
        "3": {"cantons": ["Merville", "La Bassée", "Haubourdin",
                          "Lille-Sud-Ouest", "Pont-à-Marcq"]},
        "4": {"cantons": ["Tourcoing-Nord", "Tourcoing-Sud", "Roubaix-Est",
                          "Roubaix-Ouest", "Cysoing", "Lille-Sud-Est",
                          "Seclin"]},
        "5": {"reprend": ["Douai-1", "Douai-2"]},
        "6": {"reprend": ["Valenciennes-1", "Valenciennes-2"],
              "moins": ["Bouchain"]},
        "7": {"reprend": ["Cambrai-1"], "plus": ["Bouchain"]},
        "8": {"reprend": ["Cambrai-2"],
              "plus": ["Le Quesnoy-Ouest", "Le Quesnoy-Est"]},
        "9": {"reste": True}}},
  ]},

"60": {
  "nom": "Oise",
  # Atlas : « Le Coudray » = Le Coudray-Saint-Germer ; « Nord-Est »,
  # « Beauvais S.-O. » = Beauvais-Nord-Est, -Sud-Ouest. Photos 9-11.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876",
     "fusionner": [(["Beauvais-1", "Beauvais-2"], "Beauvais")],
     "deplacer": [(["Estrées-Saint-Denis"], "Compiègne")]},
    {"depuis": 1820, "jusqu": 1831, "base": "1876", "circos": {
        "1": {"reprend": ["Beauvais-1", "Beauvais-2"]},
        "3": {"reprend": ["Clermont"], "moins": ["Estrées-Saint-Denis"],
              "plus": ["Neuilly-en-Thelle", "Creil", "Senlis"]},
        "2": {"reste": True}}},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"cantons": ["Beauvais-Nord-Est", "Beauvais-Sud-Ouest",
                          "Nivillers"]},
        "2": {"reprend": ["Beauvais-1", "Beauvais-2"],
              "moins": ["Beauvais-Nord-Est", "Beauvais-Sud-Ouest",
                        "Nivillers"]},
        "4": {"reprend": ["Clermont"], "moins": ["Estrées-Saint-Denis"]},
        "5": {"reprend": ["Compiègne"], "plus": ["Estrées-Saint-Denis"]},
        "3": {"reprend": ["Senlis"]}}},
    # « Même découpage que de 1820 à 1831 : 1re 1852 = 1re 1820 (Beauvais),
    # 2e 1852 = 3e 1820 (Clermont-Senlis), 3e 1852 = 2e 1820 (Compiègne) »
    {"depuis": 1852, "jusqu": 1863, "base": "1820", "renommer": {
        "1": "1", "3": "2", "2": "3"}},
    {"depuis": 1863, "jusqu": 1869, "base": "1876", "circos": {
        "1": {"reprend": ["Beauvais-1", "Beauvais-2"],
              "moins": ["Noailles", "Méru"]},
        "2": {"reprend": ["Clermont"],
              "plus": ["Noailles", "Méru", "Neuilly-en-Thelle", "Creil"]},
        "3": {"reste": True}}},
    {"depuis": 1869, "jusqu": 1870, "base": "1876", "circos": {
        "1": {"reprend": ["Beauvais-1", "Beauvais-2"],
              "moins": ["Noailles", "Méru"]},
        "2": {"reprend": ["Clermont"], "moins": ["Estrées-Saint-Denis"],
              "plus": ["Noailles", "Méru", "Neuilly-en-Thelle", "Creil"]},
        "3": {"reste": True}}},
  ]},

"61": {
  "nom": "Orne",
  # Atlas : « Saint-Gervais-de-Messei » (1815) = Messei ; « Bazoches » =
  # Bazoches-sur-Hoëne ; « Longny » = Longny-au-Perche ; « Mortagne » =
  # Mortagne-au-Perche ; « Le Mêle » = Le Mêle-sur-Sarthe. Photos 6-8.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "fusionner": [
        (["Domfront-1", "Domfront-2"], "Domfront"),
        (["Mortagne-1", "Mortagne-2"], "Mortagne")]},
    # « Même découpage qu'en 1815 : 1re Alençon, 2e Argentan, 3e Domfront,
    # 4e Mortagne »
    {"depuis": 1820, "jusqu": 1831, "base": "1815", "renommer": {
        "Alençon": "1", "Argentan": "2", "Domfront": "3", "Mortagne": "4"}},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"cantons": ["Alençon-Ouest", "Alençon-Est"]},
        "2": {"cantons": ["Carrouges", "Sées", "Courtomer", "Le Mêle-sur-Sarthe"]},
        "3": {"cantons": ["Putanges", "Briouze", "Écouché", "Argentan",
                          "Mortrée"]},
        "5": {"reprend": ["Domfront-1", "Domfront-2"]},
        "6": {"cantons": ["Laigle", "Moulins-la-Marche", "Tourouvre",
                          "Bazoches-sur-Hoëne", "Longny-au-Perche"]},
        "7": {"cantons": ["Mortagne-au-Perche", "Pervenchères", "Bellême",
                          "Nocé", "Rémalard", "Le Theil"]},
        "4": {"reste": True}}},
    {"depuis": 1852, "jusqu": 1869, "base": "1876", "circos": {
        "3": {"reprend": ["Domfront-1", "Domfront-2"], "plus": ["Briouze"]},
        "2": {"reprend": ["Argentan"], "moins": ["Briouze"],
              "plus": ["Laigle", "Moulins-la-Marche", "Tourouvre",
                       "Bazoches-sur-Hoëne", "Longny-au-Perche"]},
        "1": {"reste": True}}},
    # DOUTE : Courtomer, cerné de traits épais sauf côté Moulins-la-Marche,
    # rangé dans la 2e.
    {"depuis": 1869, "jusqu": 1870, "base": "1876", "circos": {
        "3": {"reprend": ["Domfront-1", "Domfront-2"],
              "moins": ["La Ferté-Macé"], "plus": ["Briouze"]},
        "4": {"reprend": ["Argentan"], "moins": ["Briouze"]},
        "2": {"cantons": ["Laigle", "Moulins-la-Marche", "Courtomer",
                          "Tourouvre", "Longny-au-Perche", "Mortagne-au-Perche",
                          "Rémalard", "Nocé", "Le Theil"]},
        "1": {"reste": True}}},
  ]},

"62": {
  "nom": "Pas-de-Calais",
  # Atlas : « Calais » (avant 1852) puis « Calais-Nord-Ouest » et « Calais-
  # Sud-Est » ; la nomenclature de 1878 n'a que Calais-Nord-Ouest. « Lens »
  # = Lens-Est ; « Parcq » = Le Parcq ; « Aubigny » = Aubigny-en-Artois ;
  # « Avesnes » = Avesnes-le-Comte ; « Pas » = Pas-en-Artois ; « Beaumetz »
  # = Beaumetz-lès-Loges ; « Auxi » = Auxi-le-Château. Photos 3-5.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "fusionner": [
        (["Arras-1", "Arras-2"], "Arras"),
        (["Boulogne-1", "Boulogne-2"], "Boulogne"),
        (["Béthune-1", "Béthune-2"], "Béthune"),
        (["Saint-Omer-1", "Saint-Omer-2"], "Saint-Omer")]},
    {"depuis": 1820, "jusqu": 1831, "base": "1876", "circos": {
        "2": {"reprend": ["Boulogne-1", "Boulogne-2"],
              "plus": ["Ardres", "Audruicq", "Étaples", "Hucqueliers"]},
        "3": {"reprend": ["Saint-Omer-1", "Saint-Omer-2", "Béthune-1",
                          "Béthune-2"],
              "moins": ["Ardres", "Audruicq", "Lens-Est", "Carvin"]},
        "1": {"reprend": ["Arras-1", "Arras-2"], "plus": ["Lens-Est", "Carvin"]},
        "4": {"reste": True}}},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"cantons": ["Arras-Nord", "Arras-Sud"]},
        "2": {"reprend": ["Arras-1", "Arras-2"],
              "moins": ["Arras-Nord", "Arras-Sud"]},
        "3": {"reprend": ["Béthune-1", "Béthune-2"]},
        "4": {"reprend": ["Boulogne-1", "Boulogne-2"]},
        "5": {"reprend": ["Montreuil"]},
        "6": {"cantons": ["Saint-Omer-Nord", "Saint-Omer-Sud"]},
        "7": {"cantons": ["Audruicq", "Ardres", "Lumbres", "Aire",
                          "Fauquembergues"]},
        "8": {"reprend": ["Saint-Pol"]}}},
    {"depuis": 1852, "jusqu": 1863, "base": "1876", "circos": {
        "1": {"reprend": ["Arras-1", "Arras-2"]},
        "2": {"reprend": ["Béthune-1", "Béthune-2"], "moins": ["Norrent-Fontes"]},
        "3": {"reprend": ["Boulogne-1", "Boulogne-2"],
              "plus": ["Étaples", "Montreuil", "Campagne-lès-Hesdin"]},
        "4": {"reprend": ["Saint-Omer-1", "Saint-Omer-2"],
              "plus": ["Hucqueliers", "Norrent-Fontes"]},
        "5": {"reste": True}}},
    # « 2 » posé deux fois : Carvin, cerné, est une enclave de la 2e.
    # DOUTE : Saint-Pol, entouré de traits épais sur ses quatre côtés sur la
    # photo, est rangé dans la 6e avec Heuchin et Avesnes ; Auxi dans la 4e,
    # Aubigny dans la 1re (limite avec Vimy en trait fin).
    {"depuis": 1863, "jusqu": 1869, "base": "1876", "circos": {
        "3": {"cantons": ["Calais-Nord-Ouest", "Audruicq", "Marquise",
                          "Guînes", "Ardres", "Boulogne-sur-Mer-Nord",
                          "Boulogne-sur-Mer-Sud", "Desvres"]},
        "5": {"cantons": ["Lumbres", "Saint-Omer-Nord", "Saint-Omer-Sud",
                          "Aire", "Fauquembergues", "Norrent-Fontes",
                          "Hucqueliers", "Fruges"]},
        "2": {"cantons": ["Lillers", "Laventie", "Béthune", "Cambrin",
                          "Houdain", "Carvin"]},
        "1": {"cantons": ["Lens-Est", "Vimy", "Aubigny-en-Artois", "Arras-Nord",
                          "Arras-Sud", "Vitry-en-Artois"]},
        "4": {"cantons": ["Samer", "Étaples", "Montreuil", "Campagne-lès-Hesdin",
                          "Hesdin", "Le Parcq", "Auxi-le-Château"]},
        "6": {"reste": True}}},
    {"depuis": 1869, "jusqu": 1870, "base": "1876", "circos": {
        "3": {"cantons": ["Calais-Nord-Ouest", "Marquise", "Guînes",
                          "Boulogne-sur-Mer-Nord", "Boulogne-sur-Mer-Sud",
                          "Desvres"]},
        "5": {"cantons": ["Audruicq", "Ardres", "Saint-Omer-Nord",
                          "Saint-Omer-Sud", "Lumbres", "Aire",
                          "Fauquembergues"]},
        "4": {"cantons": ["Samer", "Étaples", "Hucqueliers", "Montreuil",
                          "Campagne-lès-Hesdin", "Hesdin", "Fruges", "Le Parcq"]},
        "6": {"cantons": ["Heuchin", "Saint-Pol-sur-Ternoise",
                          "Aubigny-en-Artois", "Auxi-le-Château",
                          "Avesnes-le-Comte"]},
        "2": {"reprend": ["Béthune-1", "Béthune-2"]},
        "1": {"reste": True}}},
  ]},

"63": {
  "nom": "Puy-de-Dôme",
  # Atlas : « Saint-Rémy » = Saint-Rémy-sur-Durolle ; « Saint-Amant » =
  # Saint-Amant-Roche-Savine ; « Latour » = Latour(-d'Auvergne). Photos 0-2.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "fusionner": [
        (["Clermont-Ferrand-1", "Clermont-Ferrand-2"], "Clermont-Ferrand"),
        (["Riom-1", "Riom-2"], "Riom")]},
    {"depuis": 1820, "jusqu": 1831, "base": "1815", "renommer": {
        "Clermont-Ferrand": "1", "Riom": "2", "Issoire": "3",
        "Thiers": "4", "Ambert": "4"}},
    # La 4e est en deux morceaux (le nord-ouest de l'arrondissement de Riom,
    # et Randan + Ennezat). Maringues reste avec Thiers.
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"cantons": ["Clermont-Ferrand-Nord", "Clermont-Ferrand-Est",
                          "Clermont-Ferrand-Sud", "Clermont-Ferrand-Sud-Ouest"]},
        "2": {"reprend": ["Clermont-Ferrand-1", "Clermont-Ferrand-2"],
              "moins": ["Clermont-Ferrand-Nord", "Clermont-Ferrand-Est",
                        "Clermont-Ferrand-Sud", "Clermont-Ferrand-Sud-Ouest"]},
        "3": {"cantons": ["Aigueperse", "Riom-Est", "Riom-Ouest"]},
        "4": {"reprend": ["Riom-1", "Riom-2"],
              "moins": ["Aigueperse", "Riom-Est", "Riom-Ouest"]},
        "5": {"reprend": ["Issoire"]},
        "6": {"reprend": ["Thiers"]},
        "7": {"reprend": ["Ambert"]}}},
    # DOUTE : la ville de Clermont. Le trait épais passe entre Nord et Est :
    # Nord et Sud-Ouest à la 1re, Est et Sud à la 2e.
    {"depuis": 1852, "jusqu": 1870, "base": "1876", "circos": {
        "4": {"reprend": ["Riom-2"],
              "plus": ["Aigueperse", "Combronde", "Riom-Est", "Riom-Ouest"]},
        "5": {"reprend": ["Thiers"], "plus": ["Randan", "Ennezat"]},
        "3": {"reprend": ["Ambert"],
              "plus": ["Saint-Dier", "Sauxillanges", "Jumeaux"]},
        "2": {"cantons": ["Clermont-Ferrand-Est", "Clermont-Ferrand-Sud",
                          "Pont-du-Château", "Vertaizon", "Billom",
                          "Vic-le-Comte", "Issoire", "Saint-Germain-Lembron",
                          "Ardes"]},
        "1": {"reste": True}}},
  ]},

"57": {
  "nom": "Moselle",
  # La Moselle d'avant 1871 n'a pas de composition de 1876 : elle est lue au
  # 1er juin 1870 et toutes les périodes sont en listes de cantons.
  #
  # LIMITE — la base n'a pas la Moselle française de 1870 :
  #  * au 1er juin 1870, le code 57 porte déjà la trame du Bezirk Lothringen :
  #    Albestroff, Delme, Lorquin (venus de la Meurthe, et présents AUSSI dans
  #    le 99) et Fontoy, Hayange (cantons allemands). Ils sont déclarés
  #    `absents` de chaque période ;
  #  * l'arrondissement de Briey (Briey, Conflans, Longuyon, Longwy,
  #    Audun-le-Roman) n'a AUCUN atome avant 1871. Ses cantons sont cités par
  #    nom ; le script les ajoute au référentiel, mais rien ne les relie
  #    encore à des communes.
  # Atlas : « Metzerwisse » = Metzervisse ; « Metz I, II, III » = Metz-1, -2, -3 ; « Sierck » = Sierck-les-
  # Bains ; « Boulay » = Boulay-Moselle ; « Rohrbach » = Rohrbach-lès-Bitche.
  # Rellingen, Sarrelouis, Sarrebrück et Saint-Jean (1815) sont cédés à la
  # Prusse en novembre 1815. Photos 20-22.
  "date": "1870-06-01",
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876",
     "absents": ["Albestroff", "Delme", "Lorquin", "Fontoy", "Hayange"],
     "circos": {
        "Briey": {"cantons": ["Longuyon", "Longwy", "Audun-le-Roman", "Briey",
                              "Conflans"]},
        "Thionville": {"cantons": ["Cattenom", "Sierck-les-Bains", "Thionville",
                                   "Metzervisse", "Bouzonville"]},
        "Metz": {"cantons": ["Metz-1", "Metz-2", "Metz-3", "Gorze", "Vigy",
                             "Boulay-Moselle", "Pange", "Verny", "Faulquemont"]},
        "Sarreguemines": {"reste": True}}},
    {"depuis": 1820, "jusqu": 1831, "base": "1876",
     "absents": ["Albestroff", "Delme", "Lorquin", "Fontoy", "Hayange"],
     "circos": {
        "1": {"cantons": ["Longuyon", "Longwy", "Audun-le-Roman", "Briey",
                          "Conflans"]},
        "2": {"cantons": ["Cattenom", "Sierck-les-Bains", "Thionville",
                          "Metzervisse", "Bouzonville"]},
        "3": {"cantons": ["Metz-1", "Metz-2", "Metz-3", "Gorze", "Verny",
                          "Vigy"]},
        "4": {"reste": True}}},
    # DOUTE : Metz-2. « 2 » est posé sur Vigy, et un second « 2 » désigne
    # Metz III par une flèche ; Metz II, entre les deux, est rangé dans la 2e.
    {"depuis": 1831, "jusqu": 1848, "base": "1876",
     "absents": ["Albestroff", "Delme", "Lorquin", "Fontoy", "Hayange"],
     "circos": {
        "1": {"cantons": ["Metz-1"]},
        "2": {"cantons": ["Vigy", "Metz-2", "Metz-3"]},
        "3": {"cantons": ["Gorze", "Verny", "Pange", "Boulay-Moselle",
                          "Faulquemont"]},
        "4": {"cantons": ["Cattenom", "Sierck-les-Bains", "Thionville",
                          "Metzervisse", "Bouzonville"]},
        "5": {"cantons": ["Longuyon", "Longwy", "Audun-le-Roman", "Briey",
                          "Conflans"]},
        "6": {"reste": True}}},
    {"depuis": 1852, "jusqu": 1869, "base": "1876",
     "absents": ["Albestroff", "Delme", "Lorquin", "Fontoy", "Hayange"],
     "circos": {
        "1": {"cantons": ["Metz-1", "Metz-2", "Metz-3", "Gorze", "Verny",
                          "Pange", "Vigy", "Boulay-Moselle"]},
        "2": {"cantons": ["Longuyon", "Longwy", "Audun-le-Roman", "Briey",
                          "Conflans", "Cattenom", "Sierck-les-Bains",
                          "Thionville", "Metzervisse", "Bouzonville"]},
        "3": {"reste": True}}},
    {"depuis": 1869, "jusqu": 1870, "base": "1876",
     "absents": ["Albestroff", "Delme", "Lorquin", "Fontoy", "Hayange"],
     "circos": {
        "1": {"cantons": ["Metz-1", "Metz-2", "Metz-3", "Gorze", "Verny",
                          "Pange", "Vigy", "Boulay-Moselle", "Faulquemont"]},
        "2": {"cantons": ["Longuyon", "Longwy", "Audun-le-Roman", "Briey",
                          "Conflans", "Cattenom", "Sierck-les-Bains",
                          "Thionville", "Metzervisse", "Bouzonville"]},
        "3": {"reste": True}}},
  ]},

}
