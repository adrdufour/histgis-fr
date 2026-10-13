# -*- coding: utf-8 -*-
"""
regles_1815_restants.py — règles Gaudillère 1815-1870, seconde série

Départements 01 à 20 (sauf l'Aveyron, non photographié), 64 à 73 et le Var
(83), transcrits depuis les photos des CARTES de l'atlas (photo_1815_1870/,
seconde série du 4 octobre 2026, 120 photos, pages 99 à 664 environ).
Les numéros de photo cités sont le rang dans l'ordre alphabétique des
fichiers PXL_20261004_*.jpg (1 = PXL_20261004_131505689.jpg).

Même format que REGLES dans remonte_1815.py, qui importe ce dictionnaire.
Les noms de cantons sont ceux de la nomenclature (cantons vivants en 1878,
ou au 1er juin 1870 pour l'Alsace) ; les noms de l'atlas qui diffèrent sont
notés en commentaire.

Les périodes « pas de découpage » (collège de département, circonscription
unique) ne reçoivent RIEN ici : elles sont déclarées dans `t106_college` de
sql/106_circo_1815_1870.sql.

Lecture : Claude, 4 octobre 2026. À VÉRIFIER par Adrien sur les originaux —
en particulier les points marqués « DOUTE ».
"""

REGLES_RESTANTS = {

"20": {
  "nom": "Corse",
  # Atlas : « Serraggio » = Venaco ; « Saint-Laurent » = San-Lorenzo ;
  # « Moita » = Moïta ; « Piedicorte » = Piedicorte-di-Gaggio ; « Porta » =
  # La Porta ; « Algajola » n'existe plus en 1878 (fondu dans Muro / Calvi,
  # arrondissement de Calvi dans tous les cas). Ghisoni n'est pas nommé sur
  # les cartes 1831-1863 : rangé avec Vezzani, son voisin. Photos 3-7.
  # 1820-1831 : pas de découpage (collège de département).
  # 1852-1857 : pas de découpage (circonscription unique).
  "periodes": [
    # Bastia-Terravecchia n'a en 1876 qu'un atome-fraction, sans
    # circonscription : il suit Bastia-Terranova partout.
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "circos": {
        "Ajaccio": {"reprend": ["Ajaccio"]},
        "Calvi": {"reprend": ["Calvi"]},
        "Corte": {"reprend": ["Corte"]},
        "Sartène": {"reprend": ["Sartène"]},
        "Bastia": {"reste": True}}},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"reprend": ["Ajaccio", "Sartène"]},
        "2": {"reste": True}}},
    {"depuis": 1857, "jusqu": 1863, "base": "1876", "circos": {
        "2": {"reprend": ["Bastia"],
              "plus": ["Bastia-Terravecchia", "Castifao", "Calacuccia", "Corte", "Venaco", "Omessa",
                       "Morosaglia", "San-Lorenzo", "Piedicroce", "Sermano",
                       "Valle-d'Alesani", "Piedicorte-di-Gaggio",
                       "Pietra-di-Verde", "Moïta"]},
        "1": {"reste": True}}},
    # Le trait épais contourne Saint-Florent et Oletta par l'est et le sud :
    # ils restent avec Santo-Pietro et Lama dans la 1re.
    {"depuis": 1863, "jusqu": 1869, "base": "1876", "circos": {
        "2": {"reprend": ["Bastia", "Corte"],
              "plus": ["Bastia-Terravecchia"],
              "moins": ["Santo-Pietro-di-Tenda", "Lama", "Saint-Florent",
                        "Oletta"]},
        "1": {"reste": True}}},
    {"depuis": 1869, "jusqu": 1870, "base": "1876", "circos": {
        "2": {"reprend": ["Bastia", "Corte"], "plus": ["Bastia-Terravecchia"]},
        "1": {"reste": True}}},
  ]},


"19": {
  "nom": "Corrèze",
  # Atlas : « Brive » = Brives (nom de la nomenclature) ; « Servières » =
  # Saint-Privat ; « Beaulieu » = Beaulieu-sur-Dordogne. Photos 8-10.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "fusionner": [
        (["Brive-1", "Brive-2"], "Brive"),
        (["Tulle-1", "Tulle-2"], "Tulle")]},
    {"depuis": 1820, "jusqu": 1821, "base": "1876", "circos": {
        "2": {"reprend": ["Ussel"],
              "plus": ["Treignac", "Corrèze", "Égletons", "Lapleau",
                       "La Roche-Canillac", "Tulle-Sud"]},
        "1": {"reste": True}}},
    # Note de l'atlas : « le canton de Tulle-Sud était divisé : la partie de
    # la ville appartenant à ce canton était rattachée à la 1re
    # circonscription, et les autres communes à la 2e ». LIMITE — Tulle-Sud
    # posé entier dans la 2e, à reprendre à l'atome.
    {"depuis": 1821, "jusqu": 1831, "base": "1820", "deplacer": [
        (["Saint-Privat"], "2")]},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"cantons": ["Corrèze", "Tulle-Nord", "Tulle-Sud",
                          "La Roche-Canillac", "Lapleau", "Argentat",
                          "Saint-Privat", "Mercoeur"]},
        "2": {"cantons": ["Ayen", "Donzenac", "Larche", "Brives", "Beynat",
                          "Meyssac", "Beaulieu-sur-Dordogne"]},
        "3": {"cantons": ["Uzerche", "Lubersac", "Vigeois", "Juillac",
                          "Seilhac"]},
        "4": {"reste": True}}},
    {"depuis": 1852, "jusqu": 1863, "base": "1876", "circos": {
        "2": {"reprend": ["Brive-1", "Brive-2"], "plus": ["Uzerche", "Seilhac"]},
        "1": {"reste": True}}},
    {"depuis": 1863, "jusqu": 1870, "base": "1852", "deplacer": [
        (["Treignac"], "2")]},
  ]},

"18": {
  "nom": "Cher",
  # Atlas : « Menetou-Salon » (1815) = Saint-Martin-d'Auxigny ; « Charost »
  # = Chârost. Photos 11-12.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "fusionner": [
        (["Bourges-1", "Bourges-2"], "Bourges"),
        (["Saint-Amand-Montrond-1", "Saint-Amand-Montrond-2"],
         "Saint-Amand")]},
    # Sancergues passe au sud du trait épais (2e).
    {"depuis": 1820, "jusqu": 1831, "base": "1876", "circos": {
        "1": {"reprend": ["Sancerre"], "moins": ["Sancergues"],
              "plus": ["Vierzon", "Graçay", "Lury-sur-Arnon",
                       "Mehun-sur-Yèvre", "Saint-Martin-d'Auxigny",
                       "Les Aix-d'Angillon", "Bourges"]},
        "2": {"reste": True}}},
    # La 1re est le seul canton de Bourges (enclave désignée par une flèche).
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"cantons": ["Bourges"]},
        "3": {"reprend": ["Saint-Amand-Montrond-1", "Saint-Amand-Montrond-2"]},
        "4": {"reprend": ["Sancerre"]},
        "2": {"reste": True}}},
    # Aubigny-sur-Nère, cerné d'un trait épais et désigné 1 par une flèche,
    # est une enclave de la 1re.
    {"depuis": 1852, "jusqu": 1869, "base": "1876", "circos": {
        "1": {"cantons": ["Aubigny-sur-Nère", "Vierzon", "Graçay",
                          "Lury-sur-Arnon", "Mehun-sur-Yèvre",
                          "Saint-Martin-d'Auxigny", "Bourges", "Chârost",
                          "Levet", "Châteauneuf-sur-Cher", "Lignières",
                          "Le Châtelet", "Saulzais-le-Potier",
                          "Châteaumeillant"]},
        "2": {"reste": True}}},
    # « Même découpage qu'en 1815 : 1re Bourges, 2e Saint-Amand, 3e Sancerre »
    {"depuis": 1869, "jusqu": 1870, "base": "1815", "renommer": {
        "Bourges": "1", "Saint-Amand": "2", "Sancerre": "3"}},
  ]},

"17": {
  "nom": "Charente-Maritime",
  # Atlas : « Saint-Pierre-d'O » = Saint-Pierre (d'Oléron) ; « LCO » = Le
  # Château ; « SMR » = Saint-Martin ; « Rochefort » (canton unique sur les
  # cartes) = Rochefort-Nord + Rochefort-Sud. Photos 13-15.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "fusionner": [
        (["Saintes-1", "Saintes-2"], "Saintes")]},
    {"depuis": 1820, "jusqu": 1821, "base": "1876", "circos": {
        "1": {"reprend": ["La Rochelle"]},
        "2": {"reprend": ["Rochefort", "Marennes"], "plus": ["Saujon"]},
        "4": {"reprend": ["Saint-Jean-d'Angély"],
              "plus": ["Saint-Porchaire", "Burie"]},
        "3": {"reste": True}}},
    # DOUTE : Cozes. Séparé de Saujon et de Gémozac par un trait épais, il ne
    # l'est pas de Saint-Genis : rangé dans la 4e (Jonzac), avec Pons.
    # Surgères, Loulay et Tonnay-Boutonne passent à la 2e (Rochefort).
    {"depuis": 1821, "jusqu": 1831, "base": "1876", "circos": {
        "1": {"reprend": ["La Rochelle"], "plus": ["Aigrefeuille-d'Aunis"]},
        "2": {"reprend": ["Rochefort", "Marennes"],
              "moins": ["Aigrefeuille-d'Aunis"],
              "plus": ["Saujon", "Loulay", "Tonnay-Boutonne"]},
        "4": {"reprend": ["Jonzac"], "plus": ["Pons", "Cozes"]},
        "3": {"reste": True}}},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"cantons": ["La Rochelle-Est", "La Rochelle-Ouest"]},
        "2": {"reprend": ["La Rochelle"],
              "moins": ["La Rochelle-Est", "La Rochelle-Ouest"]},
        "3": {"reprend": ["Saint-Jean-d'Angély"]},
        "4": {"reprend": ["Jonzac"]},
        "5": {"reprend": ["Marennes"]},
        "6": {"reprend": ["Rochefort"]},
        "7": {"reprend": ["Saintes-1", "Saintes-2"]}}},
    # Saintes-Nord, cerné d'un trait épais à l'ouest, au nord et à l'est,
    # suit Saintes-Sud dans la 3e ; Saint-Porchaire et Burie vont à la 4e.
    {"depuis": 1852, "jusqu": 1870, "base": "1876", "circos": {
        "1": {"reprend": ["La Rochelle"],
              "plus": ["Aigrefeuille-d'Aunis", "Surgères"]},
        "2": {"reprend": ["Rochefort", "Marennes"], "plus": ["Saujon"],
              "moins": ["Aigrefeuille-d'Aunis", "Surgères"]},
        "4": {"reprend": ["Saint-Jean-d'Angély"],
              "plus": ["Saint-Porchaire", "Burie"]},
        "3": {"reste": True}}},
  ]},

"16": {
  "nom": "Charente",
  # Atlas : « Baignes » = Baignes-Sainte-Radegonde ; « Villebois » =
  # Villebois-Lavalette ; « Chateauneuf » = Châteauneuf-sur-Charente ;
  # « Saint-Amant » = Saint-Amant-de-Boixe ; « Champagne » =
  # Champagne-Mouton. Photos 16-17.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "fusionner": [
        (["Angoulême-1", "Angoulême-2"], "Angoulême")]},
    {"depuis": 1820, "jusqu": 1831, "base": "1876", "circos": {
        "2": {"reprend": ["Confolens"], "plus": ["Villefagnan", "Ruffec"]},
        "3": {"reprend": ["Cognac"],
              "plus": ["Aigre", "Rouillac", "Barbezieux",
                       "Baignes-Sainte-Radegonde", "Brossac"]},
        "1": {"reste": True}}},
    # « Même découpage qu'en 1815 : 1re Angoulême, 2e Barbezieux, 3e Cognac,
    # 4e Confolens, 5e Ruffec »
    {"depuis": 1831, "jusqu": 1848, "base": "1815", "renommer": {
        "Angoulême": "1", "Barbezieux": "2", "Cognac": "3",
        "Confolens": "4", "Ruffec": "5"}},
    {"depuis": 1852, "jusqu": 1870, "base": "1876", "circos": {
        "3": {"reprend": ["Ruffec", "Confolens"]},
        "2": {"reprend": ["Cognac", "Barbezieux"]},
        "1": {"reste": True}}},
  ]},

"15": {
  "nom": "Cantal",
  # Atlas : « Marcenat » = Condat ; « Champs » = Champs-sur-Tarentaine ;
  # « Riom » = Riom-ès-Montagnes ; « La Roquebrou » = Laroquebrou ;
  # « Saint-Mamet » = Saint-Mamet-la-Salvetat. Photos 18-20.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "copie": True},
    {"depuis": 1820, "jusqu": 1831, "base": "1876", "circos": {
        "1": {"reprend": ["Mauriac", "Aurillac"]},
        "2": {"reste": True}}},
    # « Même découpage qu'en 1815 : 1re Saint-Flour, 2e Aurillac,
    # 3e Mauriac, 4e Murat »
    {"depuis": 1831, "jusqu": 1848, "base": "1815", "renommer": {
        "Saint-Flour": "1", "Aurillac": "2", "Mauriac": "3", "Murat": "4"}},
    {"depuis": 1852, "jusqu": 1857, "base": "1876", "circos": {
        "1": {"reprend": ["Aurillac"], "plus": ["Mauriac", "Pleaux"]},
        "2": {"reste": True}}},
    {"depuis": 1857, "jusqu": 1870, "base": "1852", "deplacer": [
        (["Salers"], "1")]},
  ]},

"14": {
  "nom": "Calvados",
  # Atlas : « Dives » = Dozulé ; « Caen-Nord/Sud » (1815) = Caen-Est/
  # -Ouest ; « Falaise-I/II » = Falaise-Nord/-Sud ; « Lisieux-I/II » =
  # Lisieux-1/-2 ; « Bretteville » = Bretteville-sur-Laize ; « Morteaux » =
  # Morteaux-Coulibœuf ; « Saint-Sever » = Saint-Sever-Calvados ; « Blangy »
  # = Blangy-le-Château. Trouville-sur-Mer n'est pas dessiné : il suit
  # Pont-l'Évêque, dont il est issu. Photos 21-23.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "fusionner": [
        (["Caen-1", "Caen-2"], "Caen")]},
    {"depuis": 1820, "jusqu": 1831, "base": "1876", "circos": {
        "1": {"reprend": ["Caen-1", "Caen-2"], "plus": ["Dozulé"]},
        "2": {"reprend": ["Bayeux"],
              "plus": ["Aunay-sur-Odon", "Le Bény-Bocage",
                       "Saint-Sever-Calvados", "Vire"]},
        "3": {"reprend": ["Falaise"],
              "plus": ["Mézidon", "Saint-Pierre-sur-Dives", "Vassy",
                       "Condé-sur-Noireau"]},
        "4": {"reste": True}}},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"cantons": ["Caen-Est", "Caen-Ouest"]},
        "2": {"reprend": ["Caen-1", "Caen-2"],
              "moins": ["Caen-Est", "Caen-Ouest"]},
        "3": {"reprend": ["Bayeux"]},
        "4": {"reprend": ["Falaise"]},
        "5": {"reprend": ["Lisieux"]},
        "6": {"reprend": ["Vire"]},
        "7": {"reprend": ["Pont-l'Évêque"]}}},
    {"depuis": 1852, "jusqu": 1869, "base": "1876", "circos": {
        "1": {"cantons": ["Douvres", "Troarn", "Caen-Est", "Caen-Ouest",
                          "Évrecy", "Bourguébus", "Bretteville-sur-Laize",
                          "Mézidon"]},
        "2": {"reprend": ["Bayeux"],
              "plus": ["Creully", "Tilly-sur-Seulles", "Villers-Bocage"]},
        "4": {"reprend": ["Vire", "Falaise"],
              "moins": ["Bretteville-sur-Laize"]},
        "3": {"reste": True}}},
    {"depuis": 1869, "jusqu": 1870, "base": "1876", "circos": {
        "1": {"cantons": ["Creully", "Douvres", "Tilly-sur-Seulles",
                          "Caen-Est", "Caen-Ouest", "Troarn", "Évrecy",
                          "Bourguébus", "Mézidon"]},
        "2": {"reprend": ["Bayeux"],
              "plus": ["Villers-Bocage", "Aunay-sur-Odon",
                       "Le Bény-Bocage"]},
        "4": {"reprend": ["Falaise"],
              "plus": ["Vire", "Saint-Sever-Calvados", "Vassy",
                       "Condé-sur-Noireau"]},
        "3": {"reste": True}}},
  ]},

"13": {
  "nom": "Bouches-du-Rhône",
  # Atlas : « Peyrolles » = Peyrolles-en-Provence ; « Berre-l'Étang » ;
  # « Saintes-Maries » = Saintes-Marie-de-la-Mer (graphie de la base).
  # Arles-Ouest n'a en 1876 qu'un atome-fraction, sans circonscription : il
  # suit Arles-Est partout.
  # LIMITE — VILLE DE MARSEILLE. L'atlas dessine la commune en deux ou
  # trois morceaux selon les périodes, sans nommer les cantons. Lecture
  # approchée, à reprendre à l'atome (gaudillere/marseille_cantons.md) :
  #   * morceau ouest (littoral nord)  -> Marseille-1 ;
  #   * morceau sud (1831-1848)        -> Marseille-5, Marseille-6 ;
  #   * le reste (centre et est)       -> Marseille-2, -3, -4 (et -5, -6
  #     quand l'atlas ne distingue pas de morceau sud).
  # Photos 24-26.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "circos": {
        "Tarascon": {"reprend": ["Arles"], "plus": ["Arles-Ouest"]},
        "Aix-en-Provence": {"reprend": ["Aix-1", "Aix-2"]},
        "Marseille": {"reste": True}}},
    # « Même découpage qu'en 1815 : 1re Marseille, 2e Aix-en-Provence,
    # 3e Arles (= Tarascon) »
    {"depuis": 1820, "jusqu": 1831, "base": "1815", "renommer": {
        "Marseille": "1", "Aix-en-Provence": "2", "Tarascon": "3"}},
    # DOUTE (fort) : l'arrondissement de Marseille en trois. 1 = morceau
    # ouest de Marseille + Roquevaire (ils ne se touchent qu'en un point) ;
    # 2 = morceau sud + Aubagne ; 3 = morceau central (flèche) + La Ciotat
    # (isolée par deux traits épais, marquée 3).
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "6": {"cantons": ["Châteaurenard", "Tarascon", "Saint-Rémy", "Orgon",
                          "Eyguières", "Lambesc"]},
        "5": {"cantons": ["Arles-Est", "Arles-Ouest",
                          "Saintes-Marie-de-la-Mer", "Salon-de-Provence",
                          "Istres", "Berre-l'Étang", "Martigues"]},
        "4": {"cantons": ["Peyrolles-en-Provence", "Aix-en-Provence-Nord",
                          "Aix-en-Provence-Sud", "Trets", "Gardanne"]},
        "1": {"cantons": ["Marseille-1", "Roquevaire"]},
        "2": {"cantons": ["Marseille-5", "Marseille-6", "Aubagne"]},
        "3": {"reste": True}}},
    # DOUTE : un morceau central de Marseille est cerné de traits épais sans
    # chiffre lisible ; toute la ville est posée dans la 1re avec La Ciotat.
    {"depuis": 1852, "jusqu": 1863, "base": "1876", "circos": {
        "3": {"reprend": ["Arles"],
              "plus": ["Arles-Ouest", "Salon-de-Provence", "Istres",
                       "Martigues"]},
        "1": {"cantons": ["Marseille-1", "Marseille-2", "Marseille-3",
                          "Marseille-4", "Marseille-5", "Marseille-6",
                          "La Ciotat"]},
        "2": {"reste": True}}},
    # DOUTE : Berre passe à l'ouest du trait épais (3e), Martigues à l'est
    # (2e) — l'inverse de 1852 et de 1869.
    {"depuis": 1863, "jusqu": 1869, "base": "1876", "circos": {
        "3": {"reprend": ["Arles"],
              "plus": ["Arles-Ouest", "Salon-de-Provence", "Istres",
                       "Berre-l'Étang"]},
        "1": {"cantons": ["Marseille-1", "La Ciotat"]},
        "4": {"cantons": ["Marseille-2", "Marseille-3", "Marseille-4",
                          "Marseille-5", "Marseille-6", "Roquevaire",
                          "Aubagne"]},
        "2": {"reste": True}}},
    {"depuis": 1869, "jusqu": 1870, "base": "1876", "circos": {
        "3": {"reprend": ["Arles"],
              "plus": ["Arles-Ouest", "Salon-de-Provence", "Istres"]},
        "1": {"cantons": ["Marseille-1"]},
        "4": {"cantons": ["Marseille-2", "Marseille-3", "Marseille-4",
                          "Marseille-5", "Marseille-6", "Trets",
                          "Roquevaire", "Aubagne", "La Ciotat"]},
        "2": {"reste": True}}},
  ]},

"11": {
  "nom": "Aude",
  # Atlas : « Roquefort » (1820-1848) = Axat ; « Peyriac » =
  # Peyriac-Minervois ; « Durban » = Durban-Corbières ; « Lézignan » =
  # Lézignan-Corbières. Photos 27-29.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "copie": True},
    # Carcassonne-Est est relié à Saint-Hilaire par un trait fin : la ville
    # va à la 1re ; Montréal et Alzonne, cernés à l'ouest et au sud, à la 2e.
    {"depuis": 1820, "jusqu": 1821, "base": "1876", "circos": {
        "1": {"reprend": ["Castelnaudary", "Limoux"],
              "plus": ["Carcassonne-Est", "Carcassonne-Ouest"]},
        "2": {"reste": True}}},
    # Ici, au contraire, la ville passe à l'est du trait épais (avec Capendu)
    # et Conques, Mas-Cabardès, Saissac, Alzonne, Montréal à l'ouest.
    {"depuis": 1821, "jusqu": 1831, "base": "1876", "circos": {
        "2": {"reprend": ["Narbonne"],
              "plus": ["Carcassonne-Est", "Carcassonne-Ouest", "Peyriac-Minervois",
                       "Capendu", "Lagrasse", "Mouthoumet", "Tuchan"]},
        "1": {"reste": True}}},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"cantons": ["Carcassonne-Est", "Carcassonne-Ouest"]},
        "2": {"reprend": ["Carcassonne"],
              "moins": ["Carcassonne-Est", "Carcassonne-Ouest"]},
        "3": {"reprend": ["Castelnaudary"]},
        "4": {"reprend": ["Limoux"]},
        "5": {"reprend": ["Narbonne"]}}},
    # DOUTE : deux morceaux marqués « 2 » (l'arrondissement de Limoux au
    # sud-ouest, celui de Narbonne à l'est), séparés par Lagrasse, Mouthoumet
    # et Tuchan, rattachés à la 1re. Transcrit tel quel ; une coquille pour
    # « 3 » sur l'un des deux n'est pas exclue.
    {"depuis": 1852, "jusqu": 1869, "base": "1876", "circos": {
        "2": {"reprend": ["Limoux", "Narbonne"]},
        "1": {"reste": True}}},
    {"depuis": 1869, "jusqu": 1870, "base": "1876", "circos": {
        "3": {"reprend": ["Limoux"], "plus": ["Montréal"]},
        "2": {"reprend": ["Narbonne"],
              "plus": ["Lagrasse", "Mouthoumet", "Tuchan"]},
        "1": {"reste": True}}},
  ]},

"09": {
  "nom": "Ariège",
  # Atlas : « Castillon-en-Couserans » = Castillon ; « Sainte-Croix-
  # Volvestre » = Sainte-Croix ; « Tarascon-sur-Ariège » = Tarascon.
  # Pages 127-128, photos 32-33.
  "periodes": [
    # 1876 : « même découpage et mêmes appellations qu'en 1815 »
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "copie": True},
    {"depuis": 1820, "jusqu": 1831, "base": "1876", "circos": {
        "2": {"reprend": ["Pamiers"], "moins": ["Varilhes"],
              "plus": ["Mirepoix"]},
        "1": {"reste": True}}},
    # « Même découpage qu'en 1815 : 1re Pamiers, 2e Foix, 3e Saint-Girons »
    {"depuis": 1831, "jusqu": 1848, "base": "1815", "renommer": {
        "Pamiers": "1", "Foix": "2", "Saint-Girons": "3"}},
    {"depuis": 1852, "jusqu": 1870, "base": "1876", "circos": {
        "2": {"reprend": ["Saint-Girons"],
              "plus": ["Le Fossat", "Le Mas-d'Azil", "La Bastide-de-Sérou",
                       "Vicdessos"]},
        "1": {"reste": True}}},
  ]},

"10": {
  "nom": "Aube",
  # Atlas : « Lusigny » = Lusigny-sur-Barse ; « Vendeuvre » =
  # Vendeuvre-sur-Barse ; « Ervy » = Ervy-le-Châtel. Pages 130-131,
  # photos 30-31.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "copie": True},
    {"depuis": 1820, "jusqu": 1831, "base": "1876", "circos": {
        "1": {"reprend": ["Nogent-sur-Seine", "Troyes"]},
        "2": {"reste": True}}},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"cantons": ["Troyes-1", "Troyes-2", "Troyes-3", "Piney",
                          "Lusigny-sur-Barse"]},
        "2": {"reprend": ["Bar-sur-Seine"],
              "plus": ["Bouilly", "Ervy-le-Châtel"]},
        "3": {"reprend": ["Nogent-sur-Seine"],
              "plus": ["Estissac", "Aix-en-Othe"]},
        "4": {"reste": True}}},
    # Villenauxe, cerné d'un trait épais et désigné 2 par une flèche, est
    # une enclave de la 2e.
    {"depuis": 1852, "jusqu": 1870, "base": "1876", "circos": {
        "2": {"reprend": ["Arcis-sur-Aube", "Bar-sur-Aube"],
              "plus": ["Villenauxe", "Piney", "Lusigny-sur-Barse",
                       "Essoyes", "Mussy-sur-Seine", "Les Riceys"]},
        "1": {"reste": True}}},
  ]},

"08": {
  "nom": "Ardennes",
  # La carte de 1815 dessine aussi les cantons cédés en 1815 (Philippeville,
  # Walcourt, Florennes, Couvin, Chimay, Beauraing, Gédinne, Bouillon),
  # rattachés à Rocroi et Sedan : ils n'ont pas d'atome et sont ignorés.
  # Atlas : « Raucourt » = Raucourt-et-Flaba. Pages 120-123, photos 34-37.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "copie": True},
    {"depuis": 1820, "jusqu": 1821, "base": "1876", "circos": {
        "1": {"reprend": ["Rocroi", "Mézières"],
              "plus": ["Sedan-Nord", "Sedan-Sud", "Chaumont-Porcien",
                       "Château-Porcien"]},
        "2": {"reste": True}}},
    {"depuis": 1821, "jusqu": 1831, "base": "1876", "circos": {
        "1": {"reprend": ["Rocroi", "Mézières", "Sedan"]},
        "2": {"reste": True}}},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"reprend": ["Rocroi", "Mézières"]},
        "2": {"reprend": ["Rethel"]},
        "3": {"reprend": ["Sedan"]},
        "4": {"reprend": ["Vouziers"]}}},
    {"depuis": 1852, "jusqu": 1863, "base": "1876", "circos": {
        "1": {"reprend": ["Rocroi", "Mézières", "Sedan"],
              "moins": ["Raucourt-et-Flaba", "Mouzon"]},
        "2": {"reste": True}}},
    {"depuis": 1863, "jusqu": 1870, "base": "1876", "circos": {
        "3": {"reprend": ["Rocroi"],
              "plus": ["Monthermé", "Renwez", "Signy-l'Abbaye",
                       "Chaumont-Porcien", "Novion-Porcien"]},
        "1": {"reprend": ["Sedan", "Mézières"],
              "moins": ["Monthermé", "Renwez", "Signy-l'Abbaye"]},
        "2": {"reste": True}}},
  ]},

"07": {
  "nom": "Ardèche",
  # Atlas : « La Voulte » = La Voulte-sur-Rhône. Pages 114-116, photos 38-40.
  "periodes": [
    # L'atlas date cette carte « 1815-1821 » ; posée 1815-1820 pour ne pas
    # chevaucher la carte 1820-1821.
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "fusionner": [
        (["Tournon-1", "Tournon-2"], "Tournon"),
        (["Privas-1", "Privas-2"], "Privas"),
        (["Largentière-1", "Largentière-2"], "Largentière")]},
    {"depuis": 1820, "jusqu": 1821, "base": "1876", "circos": {
        "2": {"reprend": ["Tournon-1", "Tournon-2"]},
        "1": {"reste": True}}},
    {"depuis": 1821, "jusqu": 1831, "base": "1876", "circos": {
        "2": {"reprend": ["Tournon-1", "Tournon-2"],
              "plus": ["La Voulte-sur-Rhône"]},
        "1": {"reste": True}}},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"reprend": ["Privas-1", "Privas-2"]},
        "2": {"cantons": ["Tournon", "Lamastre", "Saint-Péray", "Vernoux",
                          "Le Cheylard", "Saint-Martin-de-Valamas"]},
        "3": {"cantons": ["Serrières", "Annonay", "Satillieu",
                          "Saint-Félicien", "Saint-Agrève"]},
        "4": {"reprend": ["Largentière-1", "Largentière-2"]}}},
    # DOUTE : Le Cheylard et Saint-Pierreville sont cernés d'un trait épais
    # au nord (Saint-Martin, Lamastre, Vernoux) ET au sud (Privas) ; ils ne
    # tiennent à la 1re que par Antraigues (trait fin). Rangés dans la 1re.
    {"depuis": 1852, "jusqu": 1870, "base": "1876", "circos": {
        "3": {"reprend": ["Tournon-1", "Tournon-2"], "moins": ["Le Cheylard"]},
        "2": {"reprend": ["Largentière-1", "Largentière-2"]},
        "1": {"reste": True}}},
  ]},

"06": {
  "nom": "Alpes-Maritimes",
  # Le département naît le 14 juin 1860 (comté de Nice + arrondissement de
  # Grasse, détaché du Var). Avant 1860, l'arrondissement de Grasse est
  # porté par les règles du Var (83) ; le comté de Nice, sarde, n'a rien.
  # Atlas : « Breil » = Breil-sur-Roya ; « Le Bar-sur-Loup » = Le Bar ;
  # « Saint-Vallier-de-Thiey » = Saint-Vallier ; « Nice-Ouest » = Nice-2
  # (nom de la nomenclature) ; « N.E. » = Nice-Est, qui n'a en 1876 qu'un
  # atome-fraction sans circonscription et suit Nice-Ouest partout.
  # Pages 105-108, photos 41-44.
  "periodes": [
    # 1860-1863 (texte, pas de carte) : le décret du 14 novembre 1860 crée
    # une circonscription des arrondissements de Nice et de Puget-Théniers ;
    # l'arrondissement de Grasse reste représenté par le député élu en 1858
    # dans la 1re du Var — il est porté par les règles du Var.
    {"depuis": 1860, "jusqu": 1863, "base": "1876",
     "absents": ["Antibes", "Cannes", "Coursegoules", "Grasse", "Le Bar",
                 "Saint-Auban", "Saint-Vallier", "Vence"],
     # `reste` : les cantons de Grasse y tombent, puis sont retirés comme
     # `absents`.
     "circos": {
        "1": {"reste": True}}},
    {"depuis": 1863, "jusqu": 1869, "base": "1876", "circos": {
        "2": {"reprend": ["Grasse"],
              "plus": ["Guillaumes", "Puget-Théniers", "Roquesteron"]},
        "1": {"reste": True}}},
    {"depuis": 1869, "jusqu": 1870, "base": "1863", "deplacer": [
        (["Villars-sur-Var"], "2")]},
  ]},

"05": {
  "nom": "Hautes-Alpes",
  # Atlas : « Le Monêtier » = Le Monêtier-les-Bains ; « Savines-le-Lac » =
  # Savines ; « Laragne-Montéglin » = Laragne. Pages 102-103, photos 45-46.
  # 1820-1831 : pas de découpage (collège de département).
  # 1852-1870 : pas de découpage (circonscription unique).
  "periodes": [
    # 1876 : « même découpage et mêmes appellations qu'en 1815 »
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "copie": True},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"reprend": ["Briançon", "Embrun"]},
        "2": {"reprend": ["Gap"]}}},
  ]},

"04": {
  "nom": "Alpes-de-Haute-Provence",
  # Atlas : « La Motte-du-Caire » = La Motte ; « Saint-André-les-Alpes » =
  # Saint-André ; « Moustiers » = Moustiers-Sainte-Marie.
  # Pages 99-100, photos 47-48.
  # 1820-1831 : pas de découpage (collège de département).
  # 1852-1870 : pas de découpage (circonscription unique).
  "periodes": [
    # 1876 : « même découpage et mêmes appellations qu'en 1815 »
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "copie": True},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "2": {"reprend": ["Forcalquier", "Sisteron"]},
        "1": {"reste": True}}},
  ]},

"03": {
  "nom": "Allier",
  # Atlas : « Chevagne » = Chevagnes ; « Saint-Pourçain » =
  # Saint-Pourçain-sur-Sioule ; « Montluçon » (avant 1863) = Montluçon-Est +
  # -Ouest. Commentry n'est dessiné qu'à partir de 1863 : avant, il suit
  # Montluçon dont il est issu. Pages 86-88 env., photos 49-51.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "fusionner": [
        (["Moulins-1", "Moulins-2"], "Moulins"),
        (["Montluçon-1", "Montluçon-2"], "Montluçon")]},
    {"depuis": 1820, "jusqu": 1831, "base": "1876", "circos": {
        "2": {"reprend": ["Montluçon-1", "Montluçon-2", "Gannat"]},
        "1": {"reste": True}}},
    # « Même découpage qu'en 1815 : 1re Moulins, 2e Lapalisse, 3e Gannat,
    # 4e Montluçon »
    {"depuis": 1831, "jusqu": 1848, "base": "1815", "renommer": {
        "Moulins": "1", "Lapalisse": "2", "Gannat": "3", "Montluçon": "4"}},
    # « Même découpage et même numérotation que de 1820 à 1831 »
    {"depuis": 1852, "jusqu": 1857, "base": "1820", "copie": True},
    {"depuis": 1857, "jusqu": 1863, "base": "1876", "circos": {
        "3": {"reprend": ["Montluçon-1", "Montluçon-2"]},
        "2": {"reprend": ["Lapalisse"],
              "plus": ["Saint-Pourçain-sur-Sioule", "Escurolles"]},
        "1": {"reste": True}}},
    # Dompierre passe à la 2e ; Saint-Pourçain revient à la 1re, Gannat
    # passe à la 2e (traits épais Gannat | Ébreuil et Saint-Pourçain |
    # Escurolles, Saint-Pourçain | Varennes).
    {"depuis": 1863, "jusqu": 1870, "base": "1876", "circos": {
        "3": {"reprend": ["Montluçon-1", "Montluçon-2"]},
        "2": {"reprend": ["Lapalisse"],
              "plus": ["Gannat", "Escurolles", "Dompierre-sur-Besbre"]},
        "1": {"reste": True}}},
  ]},

"02": {
  "nom": "Aisne",
  # Atlas : « Neuilly » = Neuilly-Saint-Front ; « Oulchy » =
  # Oulchy-le-Château ; « Coucy-le-Château » = Coucy-le-Château-Auffrique ;
  # « Moy » = Moÿ-de-l'Aisne ; « Sains » = Sains-Richaumont ; « Crécy » =
  # Crécy-sur-Serre ; « Vailly-sur-Aisne » = Vailly ; « Le Nouvion-en-
  # Thiérache » = Le Nouvion. Pages 90-91, photos 52-53.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "fusionner": [
        (["Saint-Quentin-1", "Saint-Quentin-2"], "Saint-Quentin"),
        (["Laon-1", "Laon-2"], "Laon"),
        (["Vervins-1", "Vervins-2"], "Vervins")]},
    # Note de l'atlas : « le canton de La Fère était divisé : les communes
    # d'Achery, Anguilcourt, Beautor, Fargniers, La Fère, Liez, Mayot,
    # Mennessis, Quessy, Tergnier, Travecy et Vouel étaient rattachées à la
    # 2e circonscription, et les autres à la 1re ». LIMITE — La Fère posé
    # entier dans la 2e, à reprendre à l'atome.
    {"depuis": 1820, "jusqu": 1831, "base": "1876", "circos": {
        "2": {"reprend": ["Saint-Quentin-1", "Saint-Quentin-2"],
              "plus": ["Chauny", "La Fère"]},
        "3": {"reprend": ["Vervins-1", "Vervins-2"],
              "plus": ["Rozoy-sur-Serre"]},
        "4": {"reprend": ["Soissons", "Château-Thierry"],
              "plus": ["Coucy-le-Château-Auffrique"]},
        "1": {"reste": True}}},
    # La 3e est le seul canton de Saint-Quentin (enclave).
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "3": {"cantons": ["Saint-Quentin"]},
        "4": {"reprend": ["Saint-Quentin-1", "Saint-Quentin-2"],
              "moins": ["Saint-Quentin"]},
        "5": {"reprend": ["Vervins-1", "Vervins-2"],
              "moins": ["Rozoy-sur-Serre"]},
        "2": {"cantons": ["Chauny", "La Fère", "Coucy-le-Château-Auffrique",
                          "Crécy-sur-Serre", "Anizy-le-Château"]},
        "6": {"reprend": ["Soissons"]},
        "7": {"reprend": ["Château-Thierry"]},
        "1": {"reste": True}}},
    # Note : « le décret de 1857 transférait l'arrondissement de Soissons
    # dans la 3e circonscription. Il devait s'agir d'une erreur, ensuite
    # rectifiée » : découpage identique en 1852, 1857, 1863 et 1869.
    {"depuis": 1852, "jusqu": 1870, "base": "1876", "circos": {
        "2": {"reprend": ["Saint-Quentin-1", "Saint-Quentin-2"]},
        "3": {"reprend": ["Vervins-1", "Vervins-2"], "plus": ["Marle"]},
        "4": {"reprend": ["Soissons", "Château-Thierry"]},
        "1": {"reste": True}}},
  ]},

"01": {
  "nom": "Ain",
  # Atlas : « Mornay » = Izernore ; « Châtillon-de-Michaille » =
  # Bellegarde ; « Saint-Trivier » (nord) = Saint-Trivier-de-Courtes,
  # (Dombes) = Saint-Trivier-sur-Moignans ; « Bagé-le-Châtel » =
  # Bâgé-le-Châtel ; « Ferney » = Ferney-Voltaire ; « Virieu » =
  # Virieu-le-Grand. Villars n'est dessiné sur aucune carte 1815-1870 : il
  # est créé par la loi du 18 juillet 1868 (annexe VII p.787). Ses communes
  # suivent leur canton d'avant, commune par commune, dans `106` et `107`
  # (cantons/changements_communes_1815_1870.csv) ; la ligne « Villars »
  # ci-dessous ne sert plus qu'aux communes venues de Saint-Trivier.
  # Pages 85-87, photos 54-56.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "fusionner": [
        (["Bourg-1", "Bourg-2"], "Bourg-en-Bresse")]},
    # Ceyzériat, cerné d'un trait épais sauf du côté de Pont-d'Ain, va à la
    # 2e ; Hauteville (cerné côté Saint-Rambert, Champagne et Virieu) et
    # Seyssel à la 3e ; Champagne à la 2e.
    {"depuis": 1820, "jusqu": 1821, "base": "1876", "circos": {
        "1": {"reprend": ["Bourg-2"],
              "plus": ["Bourg", "Thoissey", "Châtillon-sur-Chalaronne",
                       "Saint-Trivier-sur-Moignans", "Villars", "Trévoux"]},
        "3": {"reprend": ["Nantua", "Gex"],
              "plus": ["Coligny", "Treffort", "Hauteville", "Seyssel"]},
        "2": {"reste": True}}},
    {"depuis": 1821, "jusqu": 1831, "base": "1876", "circos": {
        "1": {"reprend": ["Bourg-1"],
              "plus": ["Pont-de-Vaux", "Saint-Trivier-de-Courtes",
                       "Montrevel"]},
        "2": {"reprend": ["Trévoux"],
              "plus": ["Bâgé-le-Châtel", "Pont-de-Veyle"]},
        "3": {"reste": True}}},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"reprend": ["Bourg-2"]},
        "2": {"reprend": ["Bourg-1"]},
        "3": {"reprend": ["Trévoux"]},
        "4": {"reprend": ["Belley"]},
        "5": {"reprend": ["Nantua", "Gex"]}}},
    # Note : « le décret de découpage de 1857 plaçait l'arrondissement de
    # Gex dans la 1re circonscription. Il s'agissait sans doute d'une
    # erreur, ensuite corrigée » : Gex dans la 2e de 1852 à 1870.
    # Poncin à la 3e : cerné d'un trait épais au nord (Izernore), à l'est
    # (Brénod) et à l'ouest (Pont-d'Ain), ouvert seulement sur Ambérieu —
    # oublié à la première lecture, relevé par Adrien le 10 octobre 2026.
    {"depuis": 1852, "jusqu": 1870, "base": "1876", "circos": {
        "1": {"reprend": ["Bourg-1", "Bourg-2"], "moins": ["Pont-de-Veyle"]},
        "3": {"reprend": ["Trévoux"],
              "plus": ["Pont-de-Veyle", "Ambérieu", "Lagnieu", "Poncin"]},
        "2": {"reste": True}}},
  ]},

"64": {
  "nom": "Pyrénées-Atlantiques",
  # Atlas : « Oloron » et « Sainte-Marie » = Oloron-Sainte-Marie-Est et
  # -Ouest (toujours dans la même circonscription, l'ordre est sans effet) ;
  # « Nay » et « Clarac » = Nay-Est et Nay-Ouest ; « Labastide » =
  # Labastide-Clairence ; « Saint-Étienne » = Saint-Étienne-de-Baïgorry ;
  # « Arzacq » = Arzacq-Arraziguet ; « Tardets » = Tardets-Sorholus.
  # Photos 57-58.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "fusionner": [
        (["Pau-1", "Pau-2"], "Pau")]},
    # Ordonnance du 4 septembre 1820, appliquée dès novembre 1820.
    {"depuis": 1820, "jusqu": 1831, "base": "1876", "circos": {
        "3": {"reprend": ["Bayonne"]},
        "2": {"reprend": ["Mauléon", "Orthez"]},
        "1": {"reste": True}}},
    # « Même découpage qu'en 1815 : 1re Pau, 2e Bayonne, 3e Mauléon,
    # 4e Oloron, 5e Orthez »
    {"depuis": 1831, "jusqu": 1848, "base": "1815", "renommer": {
        "Pau": "1", "Bayonne": "2", "Mauléon": "3", "Oloron": "4",
        "Orthez": "5"}},
    {"depuis": 1852, "jusqu": 1870, "base": "1876", "circos": {
        "3": {"reprend": ["Bayonne", "Mauléon"]},
        "1": {"reprend": ["Pau-1", "Pau-2"], "plus": ["Arudy", "Laruns"]},
        "2": {"reste": True}}},
  ]},

"65": {
  "nom": "Hautes-Pyrénées",
  # Atlas : « Saint-Laurent » = Saint-Laurent-de-Neste ; « Labarthe » =
  # La Barthe-de-Neste ; « Bordères » = Bordères-Louron ; « Mauléon » =
  # Mauléon-Barousse ; « Argelès » = Argelès-Gazost. Pages 488-489,
  # photos 59-60. 1820-1831 : pas de découpage (collège de département).
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "fusionner": [
        (["Tarbes-1", "Tarbes-2"], "Tarbes")]},
    # Tournay, cerné d'un trait épais côté Tarbes-Sud et côté sud, reste
    # dans la 1re ; Ossun et Tarbes-Sud vont à la 2e (Argelès).
    {"depuis": 1831, "jusqu": 1834, "base": "1876", "circos": {
        "2": {"reprend": ["Argelès"], "plus": ["Ossun", "Tarbes-Sud"]},
        "3": {"reprend": ["Bagnères-de-Bigorre"]},
        "1": {"reste": True}}},
    # Loi du 22 mai 1834. Note : « Tarbes-Sud était divisé : la partie de la
    # ville appartenant à ce canton était rattachée à la 1re circonscription,
    # et les communes rurales à la 2e ». LIMITE — Tarbes-Sud posé entier
    # dans la 2e, à reprendre à l'atome ; à l'échelle du canton, la carte
    # est celle de 1831.
    {"depuis": 1834, "jusqu": 1848, "base": "1831", "copie": True},
    {"depuis": 1852, "jusqu": 1870, "base": "1876", "circos": {
        "2": {"reprend": ["Bagnères-de-Bigorre"],
              "plus": ["Trie", "Galan", "Tournay"]},
        "1": {"reste": True}}},
  ]},

"66": {
  "nom": "Pyrénées-Orientales",
  # Atlas : « La Tour » = Latour-de-France ; « Argelès » = Argelès-sur-Mer.
  # Page 493, photo 61. 1820-1831 : pas de découpage (collège de
  # département) ; 1852-1869 : pas de découpage (un seul député).
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "copie": True},
    # « Même découpage qu'en 1815 : 1re Perpignan, 2e Céret, 3e Prades »
    {"depuis": 1831, "jusqu": 1848, "base": "1815", "renommer": {
        "Perpignan": "1", "Céret": "2", "Prades": "3"}},
    {"depuis": 1869, "jusqu": 1870, "base": "1876", "circos": {
        "1": {"reprend": ["Perpignan"]},
        "2": {"reste": True}}},
  ]},

"67": {
  "nom": "Bas-Rhin",
  # Lu au 1er juin 1870 (le département n'a pas de circonscription en
  # 1878) : toutes les périodes sont en listes de cantons. La carte de 1815
  # dessine aussi Landau, Candel et Bergzabern, cédés en 1815 : ignorés.
  # Atlas : « Oberhausbergen » = Schiltigheim (chef-lieu transféré) ;
  # « Strasbourg » = les quatre cantons Strasbourg-Est, -Nord, -Ouest, -Sud.
  # Pages 498-500, photos 62-64.
  "date": "1870-06-01",
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "circos": {
        "Wissembourg": {"cantons": ["Wissembourg", "Niederbronn-les-Bains",
                                    "Woerth", "Soultz-sous-Forêts",
                                    "Lauterbourg", "Seltz"]},
        "Saverne": {"cantons": ["Sarre-Union", "Drulingen",
                                "La Petite-Pierre", "Bouxwiller", "Saverne",
                                "Hochfelden", "Marmoutier"]},
        "Sélestat": {"cantons": ["Rosheim", "Obernai", "Erstein", "Barr",
                                 "Villé", "Benfeld", "Sélestat",
                                 "Marckolsheim"]},
        "Strasbourg": {"reste": True}}},
    {"depuis": 1820, "jusqu": 1831, "base": "1876", "circos": {
        "1": {"cantons": ["Sarre-Union", "Drulingen", "La Petite-Pierre",
                          "Bouxwiller", "Saverne", "Hochfelden", "Marmoutier",
                          "Truchtersheim", "Wasselonne"]},
        "3": {"cantons": ["Wissembourg", "Niederbronn-les-Bains", "Woerth",
                          "Soultz-sous-Forêts", "Lauterbourg", "Seltz",
                          "Haguenau", "Bischwiller", "Brumath"]},
        "4": {"cantons": ["Schiltigheim", "Strasbourg-Est",
                          "Strasbourg-Nord", "Strasbourg-Ouest",
                          "Strasbourg-Sud"]},
        "2": {"reste": True}}},
    # LIMITE — la ville de Strasbourg forme à elle seule les 1re ET 2e
    # circonscriptions (« 1 & 2 ») ; la carte ne dit pas comment. Les quatre
    # cantons urbains sont posés dans la 1re — FAUX pour la 2e, à reprendre
    # à l'atome (comme Bordeaux).
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"cantons": ["Strasbourg-Est", "Strasbourg-Nord",
                          "Strasbourg-Ouest", "Strasbourg-Sud"]},
        "3": {"cantons": ["Haguenau", "Bischwiller", "Brumath",
                          "Truchtersheim", "Wasselonne", "Molsheim",
                          "Schiltigheim", "Geispolsheim"]},
        "4": {"cantons": ["Sarre-Union", "Drulingen", "La Petite-Pierre",
                          "Bouxwiller", "Saverne", "Hochfelden",
                          "Marmoutier"]},
        "6": {"cantons": ["Wissembourg", "Niederbronn-les-Bains", "Woerth",
                          "Soultz-sous-Forêts", "Lauterbourg", "Seltz"]},
        "5": {"reste": True}}},
    # Haguenau, cerné d'un trait épais et marqué 1, est une enclave de la 1re.
    {"depuis": 1852, "jusqu": 1863, "base": "1876", "circos": {
        "1": {"cantons": ["Haguenau", "Truchtersheim", "Schiltigheim",
                          "Strasbourg-Est", "Strasbourg-Nord",
                          "Strasbourg-Ouest", "Strasbourg-Sud",
                          "Geispolsheim", "Molsheim"]},
        "2": {"cantons": ["Sarre-Union", "Drulingen", "La Petite-Pierre",
                          "Bouxwiller", "Saverne", "Hochfelden", "Marmoutier",
                          "Wasselonne", "Brumath"]},
        "4": {"cantons": ["Wissembourg", "Niederbronn-les-Bains", "Woerth",
                          "Soultz-sous-Forêts", "Lauterbourg", "Seltz",
                          "Bischwiller"]},
        "3": {"reste": True}}},
    {"depuis": 1863, "jusqu": 1870, "base": "1876", "circos": {
        "1": {"cantons": ["Brumath", "Truchtersheim", "Schiltigheim",
                          "Strasbourg-Est", "Strasbourg-Nord",
                          "Strasbourg-Ouest", "Strasbourg-Sud",
                          "Geispolsheim"]},
        "2": {"cantons": ["Sarre-Union", "Drulingen", "La Petite-Pierre",
                          "Bouxwiller", "Saverne", "Hochfelden", "Marmoutier",
                          "Wasselonne", "Molsheim"]},
        "4": {"cantons": ["Wissembourg", "Niederbronn-les-Bains", "Woerth",
                          "Soultz-sous-Forêts", "Lauterbourg", "Seltz",
                          "Haguenau", "Bischwiller"]},
        "3": {"reste": True}}},
  ]},

"68": {
  "nom": "Haut-Rhin",
  # Lu au 1er juin 1870 (le département n'a pas de circonscription en
  # 1878) : toutes les périodes sont en listes de cantons. Le Territoire de
  # Belfort (Belfort, Delle, Fontaine, Giromagny) en fait partie.
  # Montbéliard et Audincourt, haut-rhinois en 1815, sont au Doubs dans la
  # base. Atlas : « Mulhouse » (avant 1863) = Mulhouse-Nord + -Sud ;
  # « Soultz » = Soultz-Haut-Rhin. Pages 505-507, photos 65-67.
  "date": "1870-06-01",
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "circos": {
        "Colmar": {"cantons": ["Sainte-Marie-aux-Mines", "Ribeauvillé",
                               "Lapoutroie", "Kaysersberg", "Colmar",
                               "Andolsheim", "Wintzenheim", "Munster",
                               "Rouffach", "Guebwiller", "Neuf-Brisach",
                               "Ensisheim", "Soultz-Haut-Rhin"]},
        "Altkirch": {"cantons": ["Mulhouse-Nord", "Mulhouse-Sud", "Habsheim",
                                 "Altkirch", "Landser", "Hirsingue",
                                 "Huningue", "Ferrette"]},
        "Belfort": {"reste": True}}},
    {"depuis": 1820, "jusqu": 1821, "base": "1876", "circos": {
        "2": {"cantons": ["Sainte-Marie-aux-Mines", "Ribeauvillé",
                          "Lapoutroie", "Kaysersberg", "Colmar", "Andolsheim",
                          "Wintzenheim", "Munster", "Neuf-Brisach"]},
        "1": {"cantons": ["Mulhouse-Nord", "Mulhouse-Sud", "Habsheim",
                          "Altkirch", "Landser", "Hirsingue", "Huningue",
                          "Ferrette"]},
        "3": {"reste": True}}},
    # « Même découpage qu'en 1815, sous réserve de la cession de deux
    # cantons au Doubs : 1re Altkirch, 2e Colmar, 3e Belfort »
    {"depuis": 1821, "jusqu": 1831, "base": "1815", "renommer": {
        "Altkirch": "1", "Colmar": "2", "Belfort": "3"}},
    # Neuf-Brisach, marqué 3 et cerné de traits épais côté Andolsheim et
    # côté Ensisheim, est une enclave de la 3e. Une flèche rattache à la 1re
    # (Colmar) un morceau de Kaysersberg — non traité.
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"cantons": ["Colmar", "Andolsheim"]},
        "3": {"cantons": ["Sainte-Marie-aux-Mines", "Ribeauvillé",
                          "Lapoutroie", "Kaysersberg", "Wintzenheim",
                          "Munster", "Rouffach", "Guebwiller",
                          "Soultz-Haut-Rhin", "Neuf-Brisach"]},
        "2": {"cantons": ["Ensisheim", "Cernay", "Mulhouse-Nord",
                          "Mulhouse-Sud"]},
        "4": {"cantons": ["Habsheim", "Landser", "Altkirch", "Hirsingue",
                          "Huningue", "Ferrette"]},
        "5": {"reste": True}}},
    {"depuis": 1852, "jusqu": 1863, "base": "1876", "circos": {
        "1": {"cantons": ["Sainte-Marie-aux-Mines", "Ribeauvillé",
                          "Lapoutroie", "Kaysersberg", "Colmar", "Andolsheim",
                          "Wintzenheim", "Munster", "Rouffach", "Guebwiller",
                          "Soultz-Haut-Rhin", "Neuf-Brisach"]},
        "2": {"cantons": ["Ensisheim", "Mulhouse-Nord", "Mulhouse-Sud",
                          "Habsheim", "Landser", "Altkirch", "Hirsingue",
                          "Huningue"]},
        "3": {"reste": True}}},
    # DOUTE : Mulhouse-Nord et -Sud sont cernés de traits épais sur leurs
    # quatre côtés, sans chiffre. Rangés dans la 2e (Ensisheim), comme en
    # 1869.
    {"depuis": 1863, "jusqu": 1869, "base": "1876", "circos": {
        "1": {"cantons": ["Sainte-Marie-aux-Mines", "Ribeauvillé",
                          "Lapoutroie", "Kaysersberg", "Colmar", "Andolsheim",
                          "Wintzenheim", "Munster", "Neuf-Brisach"]},
        "2": {"cantons": ["Rouffach", "Guebwiller", "Soultz-Haut-Rhin",
                          "Ensisheim", "Mulhouse-Nord", "Mulhouse-Sud"]},
        "3": {"cantons": ["Habsheim", "Landser", "Huningue", "Altkirch",
                          "Hirsingue", "Ferrette"]},
        "4": {"reste": True}}},
    {"depuis": 1869, "jusqu": 1870, "base": "1876", "circos": {
        "1": {"cantons": ["Sainte-Marie-aux-Mines", "Ribeauvillé",
                          "Lapoutroie", "Kaysersberg", "Colmar", "Andolsheim",
                          "Wintzenheim", "Munster", "Neuf-Brisach"]},
        "2": {"cantons": ["Ensisheim", "Mulhouse-Nord", "Mulhouse-Sud",
                          "Habsheim", "Huningue"]},
        "4": {"cantons": ["Rouffach", "Guebwiller", "Soultz-Haut-Rhin",
                          "Saint-Amarin", "Masevaux", "Thann", "Cernay"]},
        "3": {"reste": True}}},
  ]},

"69": {
  "nom": "Rhône",
  # Atlas : « Saint-Nizier-d'Azergues » (avant 1852) = Lamure-sur-Azergues ;
  # « Sainte-Colombe » = Condrieu ; « Neuville » = Neuville-sur-Saône.
  # Amplepuis n'est pas dessiné : il suit Thizy, dont il est issu.
  # Villeurbanne et les communes de l'Est lyonnais sont isérois jusqu'en
  # 1852 : `absents` avant cette date. Pages 511-514, photos 68-71.
  #
  # LIMITE — VILLE DE LYON. L'atlas dessine la ville en un ou deux blocs
  # (« Lyon », « La Guillotière », puis « Lyon 2 ») et la partage entre
  # plusieurs circonscriptions sans que le partage se lise à l'échelle des
  # huit cantons de 1878. Les cantons Lyon-1 à Lyon-8 sont posés ENTIERS
  # dans une seule circonscription par période (1831-1848 : la 1re, alors
  # que la ville forme les 1re, 2e et 3e ; 1869 : la 1re, alors que « Lyon
  # 2 » est un morceau de la ville). À reprendre à l'atome.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876",
     "absents": ["Villeurbanne"], "circos": {
        "Villefranche": {"reprend": ["Villefranche-1", "Villefranche-2"]},
        "Lyon": {"reste": True}}},
    {"depuis": 1820, "jusqu": 1831, "base": "1876",
     "absents": ["Villeurbanne"], "circos": {
        "3": {"reprend": ["Villefranche-1", "Villefranche-2"]},
        "1": {"cantons": ["L'Arbresle", "Vaugneray", "Limonest",
                          "Neuville-sur-Saône", "Lyon-1", "Lyon-2", "Lyon-3",
                          "Lyon-4", "Lyon-5", "Lyon-6", "Lyon-7", "Lyon-8"]},
        "2": {"reste": True}}},
    {"depuis": 1831, "jusqu": 1848, "base": "1876",
     "absents": ["Villeurbanne"], "circos": {
        "5": {"reprend": ["Villefranche-1", "Villefranche-2"]},
        "1": {"cantons": ["Lyon-1", "Lyon-2", "Lyon-3", "Lyon-4", "Lyon-5",
                          "Lyon-6", "Lyon-7", "Lyon-8"]},
        "4": {"reste": True}}},
    # Limonest passe à l'ouest du trait épais (3e) ; Neuville seul à l'est
    # (2e). La Guillotière (= Villeurbanne) n'est séparée de Saint-Genis que
    # par un trait fin : 3e.
    {"depuis": 1852, "jusqu": 1857, "base": "1876", "circos": {
        "4": {"cantons": ["Monsols", "Beaujeu", "Lamure-sur-Azergues",
                          "Belleville", "Villefranche-sur-Saône", "Thizy",
                          "Amplepuis"]},
        "1": {"cantons": ["Le Bois-d'Oingt", "Tarare", "Anse", "Lyon-1",
                          "Lyon-2", "Lyon-3", "Lyon-4", "Lyon-5", "Lyon-6",
                          "Lyon-7", "Lyon-8"]},
        "2": {"cantons": ["Neuville-sur-Saône"]},
        "3": {"reste": True}}},
    # Villeurbanne, séparé de Lyon et de Saint-Genis par un trait épais,
    # touche Neuville par un trait fin : 2e.
    {"depuis": 1857, "jusqu": 1863, "base": "1852", "deplacer": [
        (["Villeurbanne"], "2")]},
    # DOUTE : Limonest, cerné d'un trait épais côté Anse, L'Arbresle et
    # Neuville, est rangé dans la 2e avec Vaugneray (trait fin) ; Neuville
    # et Villeurbanne (trait fin entre eux) dans la 3e avec Anse, Tarare et
    # L'Arbresle, qu'ils ne touchent pas : la 3e serait en deux morceaux.
    {"depuis": 1863, "jusqu": 1869, "base": "1876", "circos": {
        "5": {"cantons": ["Monsols", "Beaujeu", "Lamure-sur-Azergues",
                          "Belleville", "Villefranche-sur-Saône", "Thizy",
                          "Amplepuis", "Le Bois-d'Oingt"]},
        "3": {"cantons": ["Tarare", "L'Arbresle", "Anse",
                          "Neuville-sur-Saône", "Villeurbanne"]},
        "2": {"cantons": ["Vaugneray", "Limonest"]},
        "1": {"cantons": ["Lyon-1", "Lyon-2", "Lyon-3", "Lyon-4", "Lyon-5",
                          "Lyon-6", "Lyon-7", "Lyon-8"]},
        "4": {"reste": True}}},
    {"depuis": 1869, "jusqu": 1870, "base": "1876", "circos": {
        "5": {"cantons": ["Monsols", "Beaujeu", "Lamure-sur-Azergues",
                          "Belleville", "Villefranche-sur-Saône", "Thizy",
                          "Amplepuis", "Le Bois-d'Oingt"]},
        "3": {"cantons": ["Tarare", "L'Arbresle", "Anse", "Limonest",
                          "Neuville-sur-Saône"]},
        "1": {"cantons": ["Vaugneray", "Villeurbanne", "Lyon-1", "Lyon-2",
                          "Lyon-3", "Lyon-4", "Lyon-5", "Lyon-6", "Lyon-7",
                          "Lyon-8"]},
        "4": {"reste": True}}},
  ]},

"70": {
  "nom": "Haute-Saône",
  # Atlas : « Vitrey-sur-Mance » = Vitrey ; « Fresne » = Fresne-Saint-Mamès ;
  # « Champlitte » = Champlitte-et-le-Prélot ; « Faucogney » =
  # Faucogney-et-la-Mer ; « Saint-Loup » = Saint-Loup-sur-Semouse ;
  # « Luxeuil » = Luxeuil-les-Bains ; « Scey-sur-Saône » =
  # Scey-sur-Saône-et-Saint-Albin. Marnay n'est pas dessiné : il suit Gy et
  # Pesmes (arrondissement de Gray dans tous les cas). Pages 524-525,
  # photos 72-73.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "fusionner": [
        (["Lure-1", "Lure-2"], "Lure")]},
    {"depuis": 1820, "jusqu": 1831, "base": "1876", "circos": {
        "1": {"reprend": ["Gray"],
              "plus": ["Vitrey", "Combeaufontaine",
                       "Scey-sur-Saône-et-Saint-Albin", "Rioz", "Montbozon"]},
        "2": {"reste": True}}},
    # Saulx est à l'est du trait épais (3e). DOUTE mineur : un petit
    # territoire entre Port-sur-Saône et Saulx est cerné de deux traits
    # épais ; sans effet à l'échelle du canton.
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "2": {"cantons": ["Jussey", "Vauvillers", "Amance",
                          "Saint-Loup-sur-Semouse", "Vitrey",
                          "Combeaufontaine"]},
        "3": {"reprend": ["Lure-1", "Lure-2"],
              "moins": ["Vauvillers", "Saint-Loup-sur-Semouse"]},
        "4": {"reprend": ["Gray"]},
        "1": {"reste": True}}},
    # « Même découpage qu'en 1815 : 1re Vesoul, 2e Lure, 3e Gray »
    {"depuis": 1852, "jusqu": 1870, "base": "1815", "renommer": {
        "Vesoul": "1", "Lure": "2", "Gray": "3"}},
  ]},

"71": {
  "nom": "Saône-et-Loire",
  # Atlas : « Saint-Léger-sous-Beuvray » ; « Epinac » = Épinac-les-Mines ;
  # « Couches » = Couches-les-Mines ; « Boubon-Lancy » [sic] =
  # Bourbon-Lancy ; « Lucenay » = Lucenay-l'Évêque ; « Semur » =
  # Semur-en-Brionnais ; « Saint-Bonnet » = Saint-Bonnet-de-Joux ;
  # « Saint-Gengoux » = Saint-Gengoux-le-National ; « Chalon Nord/Sud » =
  # Chalon-sur-Saône-Nord/-Sud ; « La Chapelle » = La Chapelle-de-Guinchay.
  # Le Creusot et Montceau-les-Mines (cantons de 1874) ne sont pas
  # dessinés : ils suivent Montcenis et Mont-Saint-Vincent, dont ils sont
  # issus. Pages 531-533, photos 74-76.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "fusionner": [
        (["Autun-1", "Autun-2"], "Autun"),
        (["Chalon-1", "Chalon-2"], "Chalon-sur-Saône"),
        (["Charolles-1", "Charolles-2"], "Charolles"),
        (["Mâcon-1", "Mâcon-2"], "Mâcon")]},
    # DOUTE : Mont-Saint-Vincent, cerné de traits épais au nord et au sud,
    # est rangé dans la 2e (Chalon) comme en 1815.
    {"depuis": 1820, "jusqu": 1831, "base": "1876", "circos": {
        "1": {"reprend": ["Mâcon-1", "Mâcon-2"],
              "plus": ["Cuisery", "Montpont", "Cuiseaux"]},
        "2": {"reprend": ["Chalon-1", "Chalon-2", "Louhans"],
              "moins": ["Cuisery", "Montpont", "Cuiseaux"]},
        "3": {"reprend": ["Autun-1", "Autun-2"]},
        "4": {"reste": True}}},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"cantons": ["Mâcon-Nord", "Mâcon-Sud",
                          "La Chapelle-de-Guinchay"]},
        "2": {"reprend": ["Mâcon-1", "Mâcon-2"],
              "moins": ["Mâcon-Nord", "Mâcon-Sud",
                        "La Chapelle-de-Guinchay"]},
        "3": {"cantons": ["Chalon-sur-Saône-Nord", "Chalon-sur-Saône-Sud"]},
        "4": {"reprend": ["Chalon-1", "Chalon-2"],
              "moins": ["Chalon-sur-Saône-Nord", "Chalon-sur-Saône-Sud"]},
        "5": {"reprend": ["Autun-1", "Autun-2"]},
        "6": {"reprend": ["Charolles-1", "Charolles-2"]},
        "7": {"reprend": ["Louhans"]}}},
    {"depuis": 1852, "jusqu": 1863, "base": "1876", "circos": {
        "3": {"cantons": ["Épinac-les-Mines", "Couches-les-Mines", "Chagny",
                          "Verdun-sur-le-Doubs", "Chalon-sur-Saône-Nord",
                          "Chalon-sur-Saône-Sud", "Givry", "Buxy",
                          "Sennecey-le-Grand"]},
        "4": {"reprend": ["Louhans"],
              "plus": ["Saint-Martin-en-Bresse", "Saint-Germain-du-Plain",
                       "Tournus", "Saint-Gengoux-le-National", "Lugny"]},
        "1": {"cantons": ["Cluny", "La Guiche", "Saint-Bonnet-de-Joux",
                          "Matour", "Tramayes", "Mâcon-Nord", "Mâcon-Sud",
                          "La Chapelle-de-Guinchay", "La Clayette",
                          "Chauffailles", "Semur-en-Brionnais", "Marcigny"]},
        "2": {"reste": True}}},
    {"depuis": 1863, "jusqu": 1870, "base": "1876", "circos": {
        "1": {"reprend": ["Autun-1", "Autun-2"],
              "plus": ["Chagny", "Givry"]},
        "2": {"cantons": ["Verdun-sur-le-Doubs", "Chalon-sur-Saône-Nord",
                          "Chalon-sur-Saône-Sud", "Buxy", "Mont-Saint-Vincent",
                          "Montceau-les-Mines", "Sennecey-le-Grand",
                          "Saint-Martin-en-Bresse", "Saint-Germain-du-Plain",
                          "Pierre"]},
        "4": {"reprend": ["Louhans"], "moins": ["Pierre"],
              "plus": ["Tournus", "Saint-Gengoux-le-National", "Lugny"]},
        "5": {"cantons": ["Cluny", "Matour", "Tramayes", "Mâcon-Nord",
                          "Mâcon-Sud", "La Chapelle-de-Guinchay",
                          "La Clayette", "Chauffailles"]},
        "3": {"reste": True}}},
  ]},

"72": {
  "nom": "Sarthe",
  # Atlas : « La Fresnaye » = La Fresnaye-sur-Chédouet ; « Malicorne » =
  # Malicorne-sur-Sarthe. Pages 537-538, photos 77-78.
  # LIMITE — VILLE DU MANS. L'atlas dessine trois petits cantons urbains
  # (« Le Mans I, II, III ») et un grand « Le-Mans-III » rural à l'est ; à
  # partir de 1831, la ville est partagée entre plusieurs circonscriptions
  # par des traits épais très serrés. Lecture à l'échelle des trois cantons
  # de la nomenclature, à reprendre à l'atome.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "fusionner": [
        (["Mamers-1", "Mamers-2"], "Mamers"),
        (["Le Mans-1", "Le Mans-2"], "Le Mans")]},
    # Beaumont passe au nord du trait épais (2e) ; Montmirail au sud (4e).
    {"depuis": 1820, "jusqu": 1831, "base": "1876", "circos": {
        "1": {"cantons": ["Sillé-le-Guillaume", "Conlie", "Ballon",
                          "Le Mans-1", "Le Mans-2", "Le Mans-3", "Écommoy"]},
        "2": {"reprend": ["Mamers-1", "Mamers-2"],
              "moins": ["Tuffé", "Montmirail"]},
        "4": {"reprend": ["Saint-Calais"],
              "plus": ["Tuffé", "Montmirail", "Montfort-le-Rotrou"]},
        "3": {"reste": True}}},
    # DOUTE (fort) : la ville. « 1 » est posé entre Le Mans I et II, deux
    # « 2 » sur Le Mans III et entre Le Mans I et le grand Le-Mans-III.
    # Lecture : Le Mans-1 et -2 à la 1re, Le Mans-3 à la 2e avec Montfort,
    # Écommoy et La Suze. Montmirail, cerné de traits épais, est une enclave
    # de la 7e (Beaumont, Fresnay) ; Ballon va à la 3e.
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"cantons": ["Le Mans-1", "Le Mans-2"]},
        "2": {"cantons": ["Le Mans-3", "Montfort-le-Rotrou", "Écommoy",
                          "La Suze-sur-Sarthe"]},
        "3": {"cantons": ["Sillé-le-Guillaume", "Conlie", "Loué", "Ballon"]},
        "4": {"reprend": ["Saint-Calais"], "plus": ["Vibraye"]},
        "6": {"cantons": ["Mamers", "Marolles-les-Braults", "Bonnétable",
                          "La Ferté-Bernard", "Tuffé"]},
        "7": {"cantons": ["Fresnay-sur-Sarthe", "Saint-Paterne",
                          "La Fresnaye-sur-Chédouet", "Beaumont-sur-Sarthe",
                          "Montmirail"]},
        "5": {"reste": True}}},
    # DOUTE : Le Mans I, bande cernée de traits épais à l'est et à l'ouest,
    # est rangé dans la 1re ; Le Mans II dans la 3e, Le Mans III (marqué 4)
    # dans la 4e. Marolles, cerné sauf côté Ballon, va à la 4e.
    {"depuis": 1852, "jusqu": 1870, "base": "1876", "circos": {
        "2": {"cantons": ["Fresnay-sur-Sarthe", "Saint-Paterne",
                          "La Fresnaye-sur-Chédouet", "Mamers",
                          "Beaumont-sur-Sarthe", "Sillé-le-Guillaume",
                          "Conlie", "Bonnétable", "La Ferté-Bernard"]},
        "1": {"cantons": ["Le Mans-1", "Tuffé", "Montmirail", "Vibraye",
                          "Montfort-le-Rotrou", "Bouloire", "Saint-Calais"]},
        "3": {"cantons": ["Le Mans-2", "Loué", "Brûlon", "La Suze-sur-Sarthe",
                          "Sablé-sur-Sarthe", "Malicorne-sur-Sarthe",
                          "La Flèche", "Le Lude"]},
        "4": {"reste": True}}},
  ]},

"73": {
  "nom": "Savoie",
  # Département français depuis le 14 juin 1860 ; circonscriptions fixées
  # par le décret du 14 novembre 1860 (élections partielles du 10 décembre
  # 1860). Les découpages sardes (1848-1860) et celui du Mont-Blanc des
  # Cent-Jours (1815) ne sont pas posés : territoire non français.
  # DOUTE : Chamoux, que le trait épais contourne par une boucle, est rangé
  # dans la 1re. Page 547, photo 82 (photos 79-81 : Mont-Blanc 1815 et
  # Savoie sarde, non posés).
  "periodes": [
    {"depuis": 1860, "jusqu": 1870, "base": "1876", "circos": {
        "1": {"reprend": ["Chambéry-1", "Chambéry-2"]},
        "2": {"reste": True}}},
  ]},

"83": {
  "nom": "Var",
  # Atlas : « Ginasservis » (avant 1831) = Rians (chef-lieu transféré) ;
  # « Saint-Maximin » = Saint-Maximin-la-Sainte-Baume ; « Comps » =
  # Comps-sur-Artuby. Le Luc et Solliès-Pont ne sont dessinés qu'à partir
  # de 1831 : avant, ils suivent Besse et Cuers. La Seyne-sur-Mer (canton
  # postérieur) suit Ollioules. Pages 642-643, photos 103-105.
  #
  # LIMITE — L'ARRONDISSEMENT DE GRASSE (Saint-Auban, Coursegoules, Le Bar,
  # Vence, Saint-Vallier, Grasse, Antibes, Cannes) est varois jusqu'en
  # 1860, mais ses cantons sont au 06 dans la base : il n'est PAS posé ici
  # pour 1815-1860 (collège de Grasse en 1815 ; 2e en 1820-1831 ; 4e en
  # 1831-1848 ; 1re en 1852-1863, dont le député représenta Grasse jusqu'en
  # 1863). Trou connu, à traiter dans le 06.
  "periodes": [
    {"depuis": 1815, "jusqu": 1820, "base": "1876", "circos": {
        "Brignoles": {"cantons": ["Rians", "Tavernes", "Barjols",
                                  "Saint-Maximin-la-Sainte-Baume", "Cotignac",
                                  "Brignoles", "Besse", "Le Luc",
                                  "La Roquebrussanne"]},
        "Toulon": {"reprend": ["Toulon-1", "Toulon-2"]},
        "Draguignan": {"reste": True}}},
    # Notes de l'atlas : « le canton de Draguignan était divisé : la commune
    # de Draguignan était rattachée à la 2e, les autres communes à la 1re » ;
    # « le canton de Fréjus était divisé : la commune du Muy appartenait à
    # la 1re, les autres à la 2e ». LIMITE — Draguignan et Fréjus posés
    # entiers dans la 2e, à reprendre à l'atome.
    {"depuis": 1820, "jusqu": 1821, "base": "1876", "circos": {
        "2": {"cantons": ["Comps-sur-Artuby", "Callas", "Fayence",
                          "Draguignan", "Fréjus"]},
        "3": {"reprend": ["Toulon-1", "Toulon-2"]},
        "1": {"reste": True}}},
    # « Le canton de Draguignan était divisé comme en 1820 » (même LIMITE).
    {"depuis": 1821, "jusqu": 1831, "base": "1820", "deplacer": [
        (["Fréjus"], "1")]},
    {"depuis": 1831, "jusqu": 1848, "base": "1876", "circos": {
        "1": {"reprend": ["Toulon-1"]},
        "2": {"reprend": ["Toulon-2"]},
        "5": {"cantons": ["Rians", "Tavernes", "Barjols",
                          "Saint-Maximin-la-Sainte-Baume", "Cotignac",
                          "Brignoles", "Besse", "La Roquebrussanne"]},
        "3": {"reste": True}}},
    {"depuis": 1852, "jusqu": 1863, "base": "1876", "circos": {
        "1": {"cantons": ["Comps-sur-Artuby", "Callas", "Fayence",
                          "Draguignan", "Fréjus"]},
        "3": {"reprend": ["Toulon-1", "Toulon-2"]},
        "2": {"reste": True}}},
    {"depuis": 1863, "jusqu": 1870, "base": "1876", "circos": {
        "2": {"reprend": ["Toulon-1", "Toulon-2"],
              "plus": ["Rians", "Barjols", "Saint-Maximin-la-Sainte-Baume",
                       "Brignoles", "La Roquebrussanne"]},
        "1": {"reste": True}}},
  ]},

}
