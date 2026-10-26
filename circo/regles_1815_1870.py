# -*- coding: utf-8 -*-
"""
regles_1815_1870.py — règles Gaudillère 1815-1870, tous départements

Transcrites depuis les photos des CARTES de l'atlas (photos/1815_1870/), et
non depuis un texte « par rapport à » : chaque carte donne la composition
entière d'une période. On l'écrit donc, autant que possible, par
circonscriptions entières de 1876 (`reprend`) ou par listes de cantons
(`cantons`), le « reste » allant à la dernière.

Deux séries de photos, toutes deux du 4 octobre 2026 :

* **départements 21 à 63** (et la Meurthe, 99) — pages 216 à 478 ;
* **départements 01 à 20** (sauf l'Aveyron, non photographié), **64 à 73 et
  le Var (83)** — seconde série, 120 photos, pages 99 à 664 environ. Les
  numéros de photo cités pour cette série sont le rang dans l'ordre
  alphabétique des fichiers PXL_20261004_*.jpg
  (1 = PXL_20261004_131505689.jpg).

Les deux séries étaient jusqu'au 26 octobre 2026 dans deux fichiers,
`regles_1815_21_63.py` et `regles_1815_restants.py` ; leurs vérifications sont
dans `verif_1815_1870.md`.

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

REGLES_1815_1870 = {

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
        "3": {"reprend": ["Vervins-1", "Vervins-2"],
              "plus": ["Marle", "Rozoy-sur-Serre"]},
        "4": {"reprend": ["Soissons", "Château-Thierry"]},
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
    # DOUTE : Le Cheylard est cerné d'un trait épais au nord (Saint-Martin,
    # Lamastre, Vernoux) ET au sud (Privas) ; il ne tient à la 1re que par
    # Antraigues (trait fin). Rangé dans la 1re.
    # Saint-Pierreville est dans la 3e d'après le texte de Gaudillère
    # (corrigé le 24 octobre 2026 ; la carte l'avait fait ranger dans la 1re).
    {"depuis": 1852, "jusqu": 1870, "base": "1876", "circos": {
        "3": {"reprend": ["Tournon-1", "Tournon-2"], "moins": ["Le Cheylard"],
              "plus": ["Saint-Pierreville"]},
        "2": {"reprend": ["Largentière-1", "Largentière-2"]},
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

"13": {
  "nom": "Bouches-du-Rhône",
  # Atlas : « Peyrolles » = Peyrolles-en-Provence ; « Berre-l'Étang » ;
  # « Saintes-Maries » = Saintes-Marie-de-la-Mer (graphie de la base).
  # Arles-Ouest n'a en 1876 qu'un atome-fraction, sans circonscription : il
  # suit Arles-Est partout.
  # LIMITE — VILLE DE MARSEILLE. L'atlas dessine la commune en deux ou
  # trois morceaux selon les périodes, sans nommer les cantons. Lecture
  # approchée, à reprendre à l'atome (annexes/gaudillere/marseille_cantons.md) :
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

}
