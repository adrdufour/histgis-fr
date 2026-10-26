# -*- coding: utf-8 -*-
"""
regles_1958_1986.py — les circonscriptions de 1958 à 1986, d'après Gaudillère

Transcrit depuis les photos des CARTES de l'atlas (photos/1940_1995/, 139 photos
du 13 octobre 2026). Le numéro de photo est le rang dans l'ordre alphabétique
des fichiers PXL_20261013_*.jpg (1 = PXL_20261013_181321691.jpg).

Chaque carte donne les cantons TELS QUE L'ATLAS LES DESSINE — la trame de
1958 — et le trait épais qui sépare les circonscriptions. Ici : pour chaque
département, {circonscription: [cantons]}, sous les noms de l'atlas. Rien
n'est déduit d'une autre source ; le rapprochement avec la nomenclature se
fait en aval.

Lecture : Claude, 13 octobre 2026. À VÉRIFIER par Adrien sur les originaux —
en particulier les points marqués « DOUTE ». Le tableau annexé à
l'ordonnance n° 58-945 du 13 octobre 1958 (JO du 14) n'est pas dans le
dépôt : c'est lui qui départagerait.
"""

REGLES_1958 = {

"01": {"nom": "Ain", "photo": 1, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Pont-de-Vaux", "Saint-Trivier-de-Courtes", "Coligny", "Bâgé-le-Châtel",
          "Montrevel", "Treffort", "Pont-de-Veyle", "Bourg-en-Bresse",
          "Ceyzériat", "Pont-d'Ain"],
    "2": ["Gex", "Ferney", "Collonges", "Oyonnax", "Izernore", "Nantua",
          "Bellegarde", "Poncin", "Brénod", "Seyssel", "Hauteville",
          "Champagne", "Saint-Rambert-en-Bugey", "Virieu", "Lhuis", "Belley"],
    "3": ["Thoissey", "Châtillon-sur-Chalaronne", "Saint-Trivier-sur-Moignans",
          "Villars", "Chalamont", "Trévoux", "Meximieux", "Montluel",
          "Ambérieu", "Lagnieu"]}},

"02": {"nom": "Aisne", "photo": 2, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Marle", "Rozoy-sur-Serre", "Sissonne", "Laon", "Craonne",
          "Neufchâtel-sur-Aisne", "Vailly-sur-Aisne", "Braine"],
    "2": ["Le Catelet", "Bohain", "Vermand", "Saint-Quentin", "Moy", "Ribemont"],
    "3": ["Wassigny", "Le Nouvion-en-Thiérache", "La Capelle", "Hirson",
          "Guise", "Sains", "Vervins", "Aubenton"],
    "4": ["Saint-Simon", "Chauny", "La Fère", "Crécy", "Coucy-le-Château",
          "Anizy-le-Château"],
    "5": ["Vic-sur-Aisne", "Soissons", "Villers-Cotterêts", "Oulchy",
          "Fère-en-Tardenois", "Neuilly", "Château-Thierry", "Condé-en-Brie",
          "Charly"]}},

"03": {"nom": "Allier", "photo": 3, "depuis": 1958, "jusqu": 1986, "circos": {
    # Lurcy-Lévy est du côté de Moulins : le trait passe à son ouest et à son sud.
    "1": ["Lurcy-Lévy", "Moulins-Ouest", "Moulins-Est", "Chevagnes",
          "Dompierre-sur-Besbre", "Neuilly-le-Réal", "Jaligny", "Le Donjon"],
    "2": ["Huriel", "Montluçon-Est", "Montluçon-Ouest", "Commentry", "Marcillat"],
    "3": ["Cérilly", "Hérisson", "Bourbon-l'Archambault", "Souvigny", "Le Montet",
          "Montmarault", "Saint-Pourçain", "Chantelle", "Ebreuil", "Gannat"],
    "4": ["Varennes-sur-Allier", "Lapalisse", "Escurolles", "Vichy", "Cusset",
          "Le Mayet-de-Montagne"]}},

"04": {"nom": "Alpes-de-Haute-Provence", "photo": 4, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["La Motte-du-Caire", "Turriers", "Seyne", "Le Lauzet", "Saint-Paul",
          "Barcelonnette", "Sisteron", "Volonne", "Digne", "La Javie", "Allos",
          "Les Mées", "Mézel", "Barrême"],
    "2": ["Noyers", "Banon", "Saint-Étienne-les-Orgues", "Forcalquier", "Peyruis",
          "Reillanne", "Manosque", "Valensole", "Riez", "Moustiers", "Senez",
          "Castellane", "Saint-André", "Colmars", "Annot", "Entrevaux"]}},

"05": {"nom": "Hautes-Alpes", "photo": 5, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Saint-Étienne-en-Dévoluy", "Aspres-sur-Buëch", "Veynes", "Gap",
          "Serres", "Rosans", "Orpierre", "Ribiers", "Laragne-Montéglin",
          "Barcillonnette", "Tallard", "La Bâtie-Neuve", "Chorges"],
    "2": ["Saint-Firmin", "Saint-Bonnet", "Orcières", "La Grave", "Le Monêtier",
          "Briançon", "L'Argentière", "Aiguilles", "Guillestre", "Embrun",
          "Savines-le-Lac"]}},

"07": {"nom": "Ardèche", "photo": 8, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Saint-Martin-de-Valamas", "Le Cheylard", "Vernoux", "Saint-Pierreville",
          "Privas", "La Voulte", "Chomérac", "Rochemaure", "Villeneuve-de-Berg",
          "Viviers", "Bourg-Saint-Andéol"],
    "2": ["Serrières", "Annonay", "Satillieu", "Saint-Félicien", "Tournon",
          "Saint-Agrève", "Lamastre", "Saint-Péray"],
    "3": ["Coucouron", "Montpezat", "Burzet", "Antraigues", "Thueyts",
          "Saint-Étienne-de-Lugdarès", "Valgorge", "Largentière", "Aubenas",
          "Joyeuse", "Les Vans", "Vallon"]}},

"08": {"nom": "Ardennes", "photo": 10, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Rumigny", "Signy-l'Abbaye", "Chaumont-Porcien", "Novion-Porcien",
          "Château-Porcien", "Rethel", "Asfeld", "Juniville", "Mézières",
          "Flize", "Omont"],
    "2": ["Givet", "Fumay", "Signy-le-Petit", "Rocroi", "Renwez", "Monthermé",
          "Charleville"],
    "3": ["Sedan-Nord", "Sedan-Sud", "Carignan", "Mouzon", "Raucourt",
          "Tourteron", "Attigny", "Le Chesne", "Buzancy", "Vouziers",
          "Machault", "Monthois", "Grandpré"]}},

"09": {"nom": "Ariège", "photo": 11, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Mirepoix", "Varilhes", "La Bastide-de-Sérou", "Foix", "Lavelanet",
          "Tarascon-sur-Ariège", "Vicdessos", "Les Cabannes", "Ax-les-Thermes",
          "Quérigut"],
    "2": ["Le Fossat", "Saverdun", "Pamiers", "Le Mas-d'Azil",
          "Sainte-Croix-Volvestre", "Saint-Lizier", "Saint-Girons",
          "Castillon-en-Couserans", "Massat", "Oust"]}},

"10": {"nom": "Aube", "photo": 12, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Arcis-sur-Aube", "Ramerupt", "Chavanges", "Brienne-le-Château",
          "Soulaines-Dhuys", "Piney", "Vendeuvre", "Bar-sur-Aube", "Essoyes",
          "Troyes-1"],
    "2": ["Aix-en-Othe", "Estissac", "Troyes-3", "Bouilly", "Lusigny",
          "Ervy-le-Châtel", "Chaource", "Bar-sur-Seine", "Les Riceys",
          "Mussy-sur-Seine"],
    "3": ["Villenauxe", "Nogent-sur-Seine", "Romilly-sur-Seine", "Méry-sur-Seine",
          "Marcilly-le-Hayer", "Troyes-2"]}},

"11": {"nom": "Aude", "photo": 13, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Mas-Cabardès", "Peyriac", "Conques", "Alzonne", "Carcassonne-Ouest",
          "Carcassonne-Est", "Montréal", "Capendu", "Lagrasse", "Mouthoumet"],
    "2": ["Ginestas", "Coursan", "Lézignan-Corbières", "Narbonne", "Durban",
          "Sigean", "Tuchan"],
    "3": ["Castelnaudary-Nord", "Castelnaudary-Sud", "Saissac", "Salles-sur-l'Hers",
          "Belpech", "Fanjeaux", "Alaigne", "Limoux", "Saint-Hilaire", "Chalabre",
          "Couiza", "Quillan", "Belcaire", "Axat"]}},

"06": {"nom": "Alpes-Maritimes", "photo": 7, "depuis": 1958, "jusqu": 1986, "circos": {
    # DOUTE : les cantons de Nice. Deux flèches (1 et 2) désignent le centre ;
    # le trait épais isole II et III (flèche 1), IV (flèche 2), et laisse VI
    # du côté de Levens. V et I ne se lisent pas sûrement à cette échelle.
    "1": ["Nice-1", "Nice-2", "Nice-3"],
    "2": ["Nice-4", "Nice-5"],
    "3": ["Saint-Étienne-de-Tinée", "Guillaumes", "Saint-Sauveur",
          "Puget-Théniers", "Villars-sur-Var", "Roquestéron", "Levens", "Nice-6"],
    "4": ["Saint-Martin-Vésubie", "Roquebillière", "Lantosque", "Tende", "Breil",
          "Sospel", "Contes", "L'Escarène", "Menton", "Villefranche", "Beausoleil"],
    "5": ["Cannes", "Antibes"],
    "6": ["Saint-Auban", "Coursegoules", "Le Bar-sur-Loup", "Vence", "Cagnes",
          "Saint-Vallier-de-Thiey", "Grasse", "Le Cannet"]}},

"12": {"nom": "Aveyron", "photo": 14, "depuis": 1958, "jusqu": 1986, "circos": {
    # Sauveterre et Naucelle : le trait les contourne par l'ouest et le sud,
    # ils tiennent à Rodez.
    "1": ["Mur-de-Barrez", "Sainte-Geneviève-sur-Argence", "Saint-Amans",
          "Laguiole", "Entraygues", "Estaing", "Saint-Chély", "Espalion",
          "Saint-Geniez-d'Olt", "Marcillac", "Bozouls", "Laissac", "Rodez",
          "Sauveterre", "Naucelle"],
    "2": ["Decazeville", "Capdenac-Gare", "Aubin", "Conques", "Villeneuve",
          "Montbazens", "Rignac", "Villefranche-de-Rouergue", "Rieupeyroux",
          "Najac", "La Salvetat"],
    "3": ["Campagnac", "Séverac-le-Château", "Pont-de-Salars", "Vezins",
          "Cassagnes", "Salles-Curan", "Saint-Beauzély", "Peyreleau", "Millau",
          "Réquista", "Saint-Rome-de-Tarn", "Nant", "Saint-Affrique", "Cornus",
          "Saint-Sernin", "Belmont", "Camarès"]}},

"13": {"nom": "Bouches-du-Rhône", "photo": 15, "depuis": 1958, "jusqu": 1986, "circos": {
    # Hors Marseille (1re à 7e, et une part de la 8e) : voir
    # docs/gaudillere/marseille_complet.md. Note de l'atlas : « le canton de
    # Marseille-XII était divisé : sa partie urbaine et la commune de
    # Plan-de-Cuques faisaient partie de la 8e circonscription, qui se trouvait
    # d'ailleurs séparée en deux tronçons ; la commune d'Allauch était
    # rattachée à la 6e ».
    "6": ["Aubagne", "La Ciotat", "commune:Allauch"],
    "8": ["Roquevaire", "commune:Plan-de-Cuques"],
    "9": ["Orgon", "Eyguières", "Lambesc", "Peyrolles", "Aix-en-Provence-Nord",
          "Aix-en-Provence-Sud", "Trets"],
    # DOUTE : Gardanne. Trait épais au nord (Aix-Sud), à l'est (Roquevaire) et
    # au sud (Marseille) ; rien d'épais vers Berre et Martigues.
    "10": ["Salon-de-Provence", "Berre-l'Étang", "Martigues", "Gardanne"],
    # Istres est à l'ouest du trait, avec Arles.
    "11": ["Châteaurenard", "Tarascon", "Saint-Rémy", "Arles-Est", "Arles-Ouest",
           "Saintes-Maries-de-la-Mer", "Port-Saint-Louis", "Istres"]}},

"14": {"nom": "Calvados", "photo": 16, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Douvres", "Caen-Est", "Caen-Ouest", "Bourguébus"],
    "2": ["Bretteville", "Falaise-Nord", "Falaise-Sud", "Morteaux-Coulibœuf",
          "Mézidon", "Saint-Pierre-sur-Dives", "Lisieux-2", "Livarot", "Orbec"],
    "3": ["Troarn", "Dozulé", "Trouville", "Honfleur", "Pont-l'Évêque",
          "Cambremer", "Blangy", "Lisieux-1"],
    "4": ["Isigny", "Trévières", "Ryes", "Bayeux", "Creully", "Balleroy",
          "Tilly-sur-Seulles", "Caumont"],
    "5": ["Villers-Bocage", "Évrecy", "Aunay-sur-Odon", "Le Bény-Bocage",
          "Condé-sur-Noireau", "Thury-Harcourt", "Saint-Sever", "Vire", "Vassy"]}},

"15": {"nom": "Cantal", "photo": 17, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Pleaux", "Salers", "Saint-Cernin", "La Roquebrou", "Aurillac-Nord",
          "Aurillac-Sud", "Vic-sur-Cère", "Saint-Mamet", "Maurs", "Montsalvy"],
    "2": ["Champs", "Saignes", "Mauriac", "Riom", "Condat", "Allanche", "Massiac",
          "Murat", "Saint-Flour-Nord", "Saint-Flour-Sud", "Ruines", "Pierrefort",
          "Chaudes-Aigues"]}},

"16": {"nom": "Charente", "photo": 18, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Angoulême-1", "Angoulême-2", "Montbron", "Blanzac", "Villebois",
          "Montmoreau", "Chalais", "Aubeterre"],
    "2": ["Rouillac", "Cognac", "Jarnac", "Hiersac", "Segonzac", "Châteauneuf",
          "Barbezieux", "Baignes", "Brossac"],
    "3": ["Villefagnan", "Ruffec", "Champagne", "Confolens-Nord", "Confolens-Sud",
          "Aigre", "Mansle", "Saint-Claud", "Chabanais", "Saint-Amant",
          "La Rochefoucauld", "Montembœuf"]}},

"17": {"nom": "Charente-Maritime", "photo": 19, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Ars", "Saint-Martin-de-Ré", "La Rochelle-Ouest", "La Rochelle-Est",
          "Marans", "La Jarrie"],
    "2": ["Courçon", "Surgères", "Aigrefeuille", "Tonnay-Charente",
          "Rochefort-Nord", "Rochefort-Sud"],
    # Saint-Porchaire : trait épais vers Tonnay-Charente, Saujon et Saintes ;
    # il ne s'ouvre que sur Saint-Savinien.
    "3": ["Loulay", "Aulnay", "Tonnay-Boutonne", "Saint-Jean-d'Angély", "Matha",
          "Saint-Savinien", "Saint-Hilaire", "Burie", "Saint-Porchaire"],
    "4": ["Saintes-Nord", "Saintes-Sud", "Pons", "Archiac", "Saint-Genis",
          "Jonzac", "Mirambeau", "Montendre", "Montlieu", "Montguyon"],
    # DOUTE léger : Saint-Agnant, entre Rochefort-Sud (2e) et Marennes (5e).
    "5": ["Saint-Pierre-d'Oléron", "Le Château-d'Oléron", "Saint-Agnant",
          "Marennes", "La Tremblade", "Royan", "Saujon", "Gémozac", "Cozes"]}},

"18": {"nom": "Cher", "photo": 21, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Saint-Martin-d'Auxigny", "Henrichemont", "Les Aix-d'Angillon",
          "Bourges", "Charost", "Levet", "Lignières"],
    "2": ["Argent-sur-Sauldre", "Aubigny-sur-Nère", "Vailly-sur-Sauldre", "Léré",
          "La Chapelle-d'Angillon", "Sancerre", "Vierzon", "Graçay",
          "Lury-sur-Arnon", "Mehun-sur-Yèvre"],
    "3": ["Sancergues", "Baugy", "Nérondes", "La Guerche-sur-l'Aubois",
          "Sancoins", "Dun-sur-Auron", "Châteauneuf-sur-Cher",
          "Charenton-du-Cher", "Saint-Amand-Montrond", "Le Châtelet",
          "Saulzais-le-Potier", "Châteaumeillant"]}},

"19": {"nom": "Corrèze", "photo": 22, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Lubersac", "Uzerche", "Vigeois", "Seilhac", "Tulle-Nord", "Tulle-Sud",
          "La Roche-Canillac", "Argentat", "Mercœur"],
    "2": ["Juillac", "Ayen", "Donzenac", "Larche", "Brive-Nord", "Brive-Sud",
          "Beynat", "Meyssac", "Beaulieu"],
    "3": ["Treignac", "Bugeat", "Sornac", "Eygurande", "Meymac", "Ussel",
          "Bort-les-Orgues", "Corrèze", "Égletons", "Neuvic", "Lapleau",
          "Saint-Privat"]}},

# La Corse : trois circonscriptions jusqu'en 1978, puis deux par département
# (loi du 15 mai 1975, appliquée aux élections de 1978) sur la trame cantonale
# de 1973.
"20": {"nom": "Corse", "photo": 23, "depuis": 1958, "jusqu": 1978, "circos": {
    "1": ["Calvi", "L'Île-Rousse", "Muro", "Belgodère", "Olmi-Cappella",
          "Calenzana", "Evisa", "Piana", "Vico", "Soccia", "Salice",
          "Sari-d'Orcino", "Bocognano", "Sarrola", "Ajaccio", "Bastelica",
          "Zicavo", "Sainte-Marie-Siché"],
    "2": ["Rogliano", "Luri", "Brando", "Nonza", "San-Martino", "Saint-Florent",
          "Bastia", "Santo-Pietro-di-Tenda", "Oletta", "Lama", "Murato", "Borgo",
          "Campitello", "Campile", "Vescovato", "Porta", "Pero-Casevecchie",
          "San-Nicolao", "Cervione"],
    "3": ["Castifao", "Morosaglia", "Omessa", "Calacuccia", "Saint-Laurent",
          "Piedicroce", "Corte", "Sermano", "Valle-d'Alesani", "Pietra-di-Verde",
          "Venaco", "Piedicorte", "Vezzani", "Moïta", "Ghisoni",
          "Prunelli-di-Fiumorbo", "Petreto-Bicchisano", "Serra-di-Scopamène",
          "Olmeto", "Sainte-Lucie-de-Tallano", "Levie", "Sartène",
          "Porto-Vecchio", "Bonifacio"]}},
"2A": {"nom": "Corse-du-Sud", "photo": 24, "depuis": 1978, "jusqu": 1986, "circos": {
    "1": ["Les Deux-Sevi", "Les Deux-Sorru", "Cruzini-Cinarca", "Celavo-Mezzana",
          "Ajaccio (5 cantons)", "Bastelica", "Zicavo", "Sainte-Marie-Siché"],
    "2": ["Petreto-Bicchisano", "Tallano-Scopamène", "Olmeto", "Levie", "Sartène",
          "Porto-Vecchio", "Figari", "Bonifacio"]}},
"2B": {"nom": "Haute-Corse", "photo": 25, "depuis": 1978, "jusqu": 1986, "circos": {
    "1": ["Capobianco", "Sagro-di-Santa-Giulia", "San-Martino-di-Lota",
          "Bastia (5 cantons)", "La Conca-d'Oro", "Le Haut-Nebbio", "Borgo",
          "Alto-di-Casaconi", "Vescovato", "Fiumalto-d'Ampugnani",
          "Campoloro-di-Moriani"],
    "2": ["L'Île-Rousse", "Calvi", "Belgodère", "Calenzana", "Castifao-Morosaglia",
          "Niolu-Omessa", "Corte", "Bustanico", "Orezza-Alesani", "Venaco",
          "Vezzani", "Moïta-Verde", "Ghisoni", "Prunelli-di-Fiumorbo"]}},

"21": {"nom": "Côte-d'Or", "photo": 26, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Dijon-Ouest", "Dijon-Sud", "Gevrey-Chambertin", "Genlis", "Auxonne"],
    "2": ["Grancey", "Is-sur-Tille", "Selongey", "Fontaine-Française", "Mirebeau",
          "Dijon-Nord", "Dijon-Est", "Pontailler"],
    "3": ["Liernais", "Pouilly-en-Auxois", "Arnay-le-Duc", "Bligny-sur-Ouche",
          "Beaune-Nord", "Beaune-Sud", "Nolay", "Nuits-Saint-Georges", "Seurre",
          "Saint-Jean-de-Losne"],
    "4": ["Laignes", "Châtillon-sur-Seine", "Montigny-sur-Aube", "Recey-sur-Ource",
          "Montbard", "Aignay-le-Duc", "Baigneux-les-Juifs", "Semur-en-Auxois",
          "Venarey", "Saint-Seine", "Précy-sous-Thil", "Vitteaux", "Saulieu",
          "Sombernon"]}},

"22": {"nom": "Côtes-du-Nord", "photo": 27, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Étables", "Saint-Brieuc-Nord", "Saint-Brieuc-Sud", "Pléneuf",
          "Lamballe", "Quintin", "Plœuc"],
    "2": ["Matignon", "Ploubalay", "Plancoët", "Plélan", "Dinan-Est",
          "Dinan-Ouest", "Évran", "Jugon", "Broons", "Caulnes"],
    "3": ["Saint-Nicolas-du-Pélem", "Rostrenen", "Corlay", "Gouarec", "Uzel",
          "Mûr-de-Bretagne", "Loudéac", "Moncontour", "Plouguenast", "Collinée",
          "Merdrignac", "La Chèze"],
    "4": ["Pontrieux", "Plouha", "Bégard", "Lanvollon", "Guingamp", "Belle-Isle",
          "Plouagat", "Châtelaudren", "Bourbriac", "Callac", "Maël-Carhaix"],
    "5": ["Perros-Guirec", "Tréguier", "Lézardrieux", "Lannion", "Paimpol",
          "La Roche-Derrien", "Plestin", "Plouaret"]}},

"23": {"nom": "Creuse", "photo": 29, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Châtelus", "Boussac", "Jarnages", "Chambon", "Guéret", "Ahun",
          "Chénérailles", "Évaux", "Bellegarde", "Auzances", "Crocq",
          "La Courtine"],
    "2": ["Bonnat", "Dun", "La Souterraine", "Saint-Vaury", "Le Grand-Bourg",
          "Bénévent", "Pontarion", "Saint-Sulpice", "Bourganeuf", "Aubusson",
          "Royère", "Felletin", "Gentioux"]}},

"24": {"nom": "Dordogne", "photo": 30, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Montpont", "Mussidan", "Neuvic", "Saint-Astier", "Périgueux",
          "Saint-Pierre-de-Chignac"],
    "2": ["Villefranche-de-Lonchat", "Vélines", "La Force", "Villamblard",
          "Bergerac", "Lalinde", "Sigoulès", "Eymet", "Issigeac", "Beaumont",
          "Cadouin", "Monpazier"],
    "3": ["Bussière-Badil", "Nontron", "Mareuil", "Saint-Pardoux",
          "Jumilhac-le-Grand", "Verteillac", "Champagnac", "Thiviers",
          "Lanouaille", "Brantôme", "Montagrier", "Ribérac", "Saint-Aulaye",
          "Excideuil"],
    "4": ["Savignac", "Hautefort", "Thenon", "Terrasson", "Vergt", "Montignac",
          "Saint-Alvère", "Le Bugue", "Salignac", "Saint-Cyprien", "Sarlat",
          "Carlux", "Belvès", "Domme", "Villefranche-du-Périgord"]}},

"25": {"nom": "Doubs", "photo": 32, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Audeux", "Marchaux", "Besançon-Nord", "Besançon-Sud", "Roulans",
          "Boussières", "Quingey", "Ornans"],
    "2": ["Rougemont", "L'Isle-sur-le-Doubs", "Montbéliard (2 cantons)",
          "Audincourt", "Baume-les-Dames", "Clerval", "Pont-de-Roide",
          "Hérimoncourt", "Saint-Hippolyte"],
    # Amancey est cerné d'un trait épais au nord, à l'ouest et à l'est : il
    # tient à Levier.
    "3": ["Vercel", "Pierrefontaine", "Maîche", "Le Russey", "Montbenoît",
          "Morteau", "Amancey", "Levier", "Pontarlier", "Mouthe"]}},

"26": {"nom": "Drôme", "photo": 33, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Valence", "Chabeuil", "Crest-Nord", "Crest-Sud",
          "La Chapelle-en-Vercors", "Die", "Saillans", "Châtillon-en-Diois",
          "Luc-en-Diois"],
    # Loriol est séparé de Valence et de Crest par le trait.
    "2": ["Loriol", "Marsanne", "Montélimar", "Bourdeaux", "Dieulefit",
          "La Motte-Chalancon", "Grignan", "Pierrelatte",
          "Saint-Paul-Trois-Châteaux", "Nyons", "Rémuzat", "Buis", "Séderon"],
    "3": ["Le Grand-Serre", "Saint-Vallier", "Saint-Donat", "Romans",
          "Tain-l'Hermitage", "Bourg-de-Péage", "Saint-Jean"]}},

"27": {"nom": "Eure", "photo": 35, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Évreux-Nord", "Évreux-Sud", "Conches", "Rugles", "Breteuil",
          "Damville", "Saint-André", "Nonancourt", "Verneuil"],
    "2": ["Quillebeuf", "Beuzeville", "Pont-Audemer", "Routot",
          "Montfort-sur-Risle", "Saint-Georges", "Cormeilles", "Thiberville",
          "Bernay", "Broglie", "Beaumesnil"],
    "3": ["Bourgtheroulde", "Amfreville", "Brionne", "Le Neubourg",
          "Beaumont-le-Roger", "Pont-de-l'Arche", "Louviers", "Gaillon"],
    "4": ["Lyons-la-Forêt", "Fleury-sur-Andelle", "Étrépagny", "Gisors",
          "Les Andelys", "Écos", "Vernon", "Pacy-sur-Eure"]}},

"28": {"nom": "Eure-et-Loir", "photo": 36, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Chartres-Nord", "Chartres-Sud", "Auneau", "Voves", "Janville",
          "Orgères-en-Beauce"],
    # DOUTE : Courville, au nord du trait qui longe La Loupe, et séparé de
    # Chartres-Nord par un trait épais.
    "2": ["Anet", "Brezolles", "Dreux", "Nogent-le-Roi", "La Ferté-Vidame",
          "Senonches", "Châteauneuf-en-Thymerais", "Maintenon", "Courville"],
    "3": ["La Loupe", "Nogent-le-Rotrou", "Thiron-Gardais", "Illiers", "Authon",
          "Brou", "Bonneval", "Châteaudun", "Cloyes"]}},

"29": {"nom": "Finistère", "photo": 37, "depuis": 1958, "jusqu": 1986, "circos": {
    # DOUTE : Briec (trait épais au nord et à l'est, moins net au sud) et
    # Pont-l'Abbé (trait épais vers Plogastel).
    "1": ["Quimper", "Fouesnant", "Pont-l'Abbé", "Briec"],
    "2": ["Brest-1", "Brest-2", "Brest-3"],
    "3": ["Ouessant", "Ploudalmézeau", "Lannilis", "Plabennec", "Saint-Renan",
          "Landerneau"],
    # DOUTE : Huelgoat, cerné au sud par le trait, ouvert sur Plouigneau.
    "4": ["Saint-Pol-de-Léon", "Taulé", "Lanmeur", "Morlaix", "Plouigneau",
          "Huelgoat"],
    "5": ["Lesneven", "Plouescat", "Plouzévédé", "Landivisiau", "Ploudiry",
          "Saint-Thégonnec", "Sizun", "Daoulas"],
    "6": ["Crozon", "Le Faou", "Châteaulin", "Pleyben", "Châteauneuf-du-Faou",
          "Carhaix"],
    "7": ["Pont-Croix", "Douarnenez", "Plogastel"],
    "8": ["Rosporden", "Scaër", "Bannalec", "Arzano", "Concarneau", "Pont-Aven",
          "Quimperlé"]}},

"30": {"nom": "Gard", "photo": 39, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Nîmes-1", "Nîmes-2", "Nîmes-3", "Saint-Mamert"],
    "2": ["Bagnols-sur-Cèze", "Roquemaure", "Villeneuve", "Uzès", "Remoulins",
          "Saint-Chaptes", "Marguerittes", "Aramon", "Beaucaire", "Sommières",
          "Vauvert", "Saint-Gilles", "Aigues-Mortes"],
    "3": ["Génolhac", "Bessèges", "Saint-Ambroix", "Barjac", "Pont-Saint-Esprit",
          "La Grand-Combe", "Alès-Est", "Lussan"],
    "4": ["Trèves", "Alzon", "Le Vigan", "Valleraugue", "Sumène",
          "Saint-André-de-Valborgne", "Saint-Jean-du-Gard", "Lasalle",
          "Saint-Hippolyte", "Sauve", "Quissac", "Anduze", "Alès-Ouest",
          "Vézénobres", "Lédignan"]}},

"31": {"nom": "Haute-Garonne", "photo": 41, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Villemur", "Fronton", "Toulouse-Nord"],
    "2": ["Montastruc", "Toulouse-Centre", "Verfeil"],
    "3": ["Toulouse-Sud", "Lanta", "Caraman", "Revel"],
    "4": ["Cadours", "Grenade", "Léguevin", "Toulouse-Ouest"],
    "5": ["Saint-Lys", "Muret", "Castanet", "Montgiscard", "Villefranche",
          "Rieumes", "Carbonne", "Auterive", "Cintegabelle", "Nailloux",
          "Le Fousseret", "Rieux", "Cazères", "Montesquieu"],
    "6": ["L'Isle-en-Dodon", "Boulogne", "Aurignac", "Montréjeau",
          "Saint-Gaudens", "Saint-Martory", "Salies", "Barbazan", "Aspet",
          "Saint-Béat", "Bagnères-de-Luchon"]}},

"32": {"nom": "Gers", "photo": 43, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Riscle", "Aignan", "Vic-Fezensac", "Jegun", "Auch-Nord", "Auch-Sud",
          "Plaisance", "Montesquiou", "Marciac", "Mirande", "Miélan", "Masseube",
          "Saramon", "Lombez", "Samatan"],
    "2": ["Cazaubon", "Nogaro", "Montréal", "Eauze", "Condom", "Valence",
          "Lectoure", "Miradoux", "Fleurance", "Saint-Clar", "Mauvezin", "Cologne",
          "Gimont", "L'Isle-Jourdain"]}},

"33": {"nom": "Gironde", "photo": 45, "depuis": 1958, "jusqu": 1986, "circos": {
    # Note de l'atlas : « Trois cantons étaient divisés : Bordeaux-I, la partie
    # urbaine et la commune du Bouscat étaient rattachées à la [1]re, la
    # commune de Bruges à la 5e ; Bordeaux-[IV ?], la partie urbaine appartenait
    # à la 2e, la commune de Talence à la 3e ; Bordeaux-VI, la partie urbaine
    # était incluse dans la 3e, la commune de Bègles dans la 6e. »
    # Le début de la note est sous le pouce : chiffres entre crochets à relire.
    # 1re à 3e : Bordeaux, non détaillé par la carte.
    "4": ["Carbon-Blanc", "Créon"],
    "5": ["Saint-Vivien", "Lesparre", "Pauillac", "Saint-Laurent", "Castelnau",
          "Blanquefort", "commune:Bruges"],
    "6": ["Mérignac", "Pessac", "commune:Bègles"],
    "7": ["Audenge", "La Teste", "Arcachon", "Belin", "Labrède",
          "Saint-Symphorien", "Villandraut", "Bazas", "Grignols", "Captieux"],
    "8": ["Targon", "Cadillac", "Podensac", "Sauveterre", "Pellegrue", "Monségur",
          "Saint-Macaire", "La Réole", "Langon", "Auros"],
    # DOUTE : Branne, que le trait semble cerner de trois côtés.
    "9": ["Coutras", "Lussac", "Libourne", "Castillon", "Pujols",
          "Sainte-Foy-la-Grande", "Branne"],
    "10": ["Saint-Ciers", "Blaye", "Saint-Savin", "Bourg", "Saint-André",
           "Guîtres", "Fronsac"]}},

"34": {"nom": "Hérault", "photo": 47, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Castries", "Lunel", "Mauguio", "Montpellier-1", "Montpellier-2"],
    "2": ["Ganges", "Claret", "Le Caylar", "Saint-Martin-de-Londres", "Lodève",
          "Aniane", "Les Matelles", "Lunas", "Clermont", "Gignac",
          "Montpellier-3"],
    "3": ["Roujan", "Montagnac", "Pézenas", "Mèze", "Frontignan", "Sète",
          "Florensac", "Agde"],
    "4": ["Saint-Gervais", "Bédarieux", "Olargues", "Murviel", "Servian",
          "Béziers-1"],
    "5": ["La Salvetat", "Saint-Pons", "Olonzac", "Saint-Chinian", "Capestang",
          "Béziers-2"]}},

"35": {"nom": "Ille-et-Vilaine", "photo": 48, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Bécherel", "Hédé", "Saint-Aubin-d'Aubigné", "Liffré",
          "Rennes-Nord-Est", "Rennes-Nord-Ouest"],
    "2": ["Saint-Méen", "Montauban", "Montfort", "Mordelles",
          "Rennes-Sud-Ouest", "Rennes-Sud-Est", "Châteaugiron"],
    "3": ["Vitré-Ouest", "Vitré-Est", "Châteaubourg", "Argentré", "Janzé",
          "La Guerche", "Retiers"],
    "4": ["Plélan", "Guichen", "Maure", "Le Sel", "Pipriac", "Bain",
          "Grand-Fougeray", "Redon"],
    "5": ["Antrain", "Saint-Brice", "Louvigné", "Fougères-Nord", "Fougères-Sud",
          "Saint-Aubin-du-Cormier"],
    "6": ["Cancale", "Saint-Malo", "Saint-Servan", "Dinard", "Châteauneuf",
          "Dol-de-Bretagne", "Pleine-Fougères", "Combourg", "Tinténiac"]}},

"36": {"nom": "Indre", "photo": 50, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Levroux", "Châteauroux", "Ardentes", "Argenton"],
    "2": ["Saint-Christophe-en-Bazelle", "Vatan", "Issoudun-Nord-Est",
          "Issoudun-Sud-Ouest", "Neuvy", "La Châtre", "Sainte-Sévère",
          "Aigurande", "Éguzon"],
    "3": ["Valençay", "Écueillé", "Châtillon-sur-Indre", "Mézières", "Buzançais",
          "Tournon", "Le Blanc", "Saint-Gaultier", "Bélâbre",
          "Saint-Benoît-du-Sault"]}},

"37": {"nom": "Indre-et-Loire", "photo": 52, "depuis": 1958, "jusqu": 1986, "circos": {
    # Note de l'atlas : « les cantons de Tours-Nord, Tours-Est et Tours-Ouest
    # étaient divisés : les parties de la ville appartenant à ces cantons
    # étaient rattachées à la 1re ; les autres communes de Tours-Nord
    # appartenaient à la 2e ; les autres communes de Tours-Ouest étaient
    # incluses dans la 4e ; deux communes de Tours-Est (Saint-Pierre-des-Corps
    # et Saint-Avertin) étaient rattachées à la 1re, les autres à la 3e ».
    "1": ["Tours-Centre", "Tours-Sud", "ville:Tours-Nord", "ville:Tours-Est",
          "ville:Tours-Ouest", "commune:Saint-Pierre-des-Corps",
          "commune:Saint-Avertin"],
    "2": ["Neuvy-le-Roi", "Château-Renault", "Château-la-Vallière",
          "Neuillé-Pont-Pierre", "Vouvray", "Langeais", "reste:Tours-Nord"],
    "3": ["Amboise", "Bléré", "Montrésor", "Loches", "Ligueil",
          "La Haye-Descartes", "Le Grand-Pressigny", "Preuilly-sur-Claise",
          "reste:Tours-Est"],
    "4": ["Bourgueil", "Chinon", "Azay-le-Rideau", "L'Île-Bouchard",
          "Sainte-Maure", "Richelieu", "Montbazon", "reste:Tours-Ouest"]}},

# L'Isère a deux découpages : celui de 1958, puis celui de la loi du 29 juin
# 1972 (cession de territoires au Rhône), appliqué aux élections de 1973.
# Notes de l'atlas, valables aux deux : « la partie de la ville de Grenoble
# appartenant au canton Nord était rattachée à la 2e, et les autres communes
# du canton à la 4e » ; « la partie de la ville de Vienne appartenant au
# canton Sud était incluse dans la 5e, et les autres communes dans la 6e ».
"38": {"nom": "Isère", "photo": 53, "depuis": 1958, "jusqu": 1973, "circos": {
    "1": ["Saint-Laurent-du-Pont", "Le Touvet", "Allevard", "Goncelin",
          "Grenoble-Est", "Domène"],
    "2": ["Grenoble-Sud", "ville:Grenoble-Nord"],
    "3": ["Sassenage", "Villard-de-Lans", "Vif", "Vizille", "Le Bourg-d'Oisans",
          "Le Monestier-de-Clermont", "La Mure", "Valbonnais", "Clelles", "Mens",
          "Corps"],
    "4": ["Voiron", "Rives", "Tullins", "Vinay", "Saint-Marcellin",
          "Pont-en-Royans", "reste:Grenoble-Nord"],
    "5": ["Meyzieu", "Saint-Symphorien-d'Ozon", "Vienne-Nord", "Heyrieux",
          "ville:Vienne-Sud"],
    # La Verpillière : entre deux traits épais, ouverte au sud sur
    # Saint-Jean-de-Bournay.
    "6": ["La Verpillière", "Saint-Jean-de-Bournay", "Roussillon", "Beaurepaire",
          "La Côte-Saint-André", "Saint-Étienne", "Roybon", "reste:Vienne-Sud"],
    "7": ["Crémieu", "Morestel", "Bourgoin", "La Tour-du-Pin",
          "Le Pont-de-Beauvoisin", "Virieu", "Saint-Geoire", "Le Grand-Lemps"]}},
"38b": {"nom": "Isère", "photo": 54, "depuis": 1973, "jusqu": 1986, "circos": {
    "1": ["Saint-Laurent-du-Pont", "Le Touvet", "Allevard", "Goncelin",
          "Grenoble-Est", "Domène"],
    "2": ["Grenoble-Sud", "ville:Grenoble-Nord"],
    "3": ["Sassenage", "Villard-de-Lans", "Vif", "Vizille", "Le Bourg-d'Oisans",
          "Le Monestier-de-Clermont", "La Mure", "Valbonnais", "Clelles", "Mens",
          "Corps"],
    "4": ["Voiron", "Rives", "Tullins", "Vinay", "Saint-Marcellin",
          "Pont-en-Royans", "reste:Grenoble-Nord"],
    # Le trait passe désormais au sud de La Verpillière et à l'est de
    # Bourgoin. DOUTE : Pont-de-Chéruy, dont aucune limite n'est épaisse.
    "5": ["Vienne-Nord", "Heyrieux", "La Verpillière", "Bourgoin",
          "ville:Vienne-Sud"],
    "6": ["Saint-Jean-de-Bournay", "Roussillon", "Beaurepaire",
          "La Côte-Saint-André", "Saint-Étienne", "Roybon", "reste:Vienne-Sud"],
    "7": ["Pont-de-Chéruy", "Crémieu", "Morestel", "La Tour-du-Pin",
          "Le Pont-de-Beauvoisin", "Virieu", "Saint-Geoire", "Le Grand-Lemps"]}},

"40": {"nom": "Landes", "photo": 55, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Parentis-en-Born", "Pissos", "Sore", "Mimizan", "Sabres", "Labrit",
          "Roquefort", "Gabarret", "Morcenx", "Mont-de-Marsan"],
    "2": ["Castets", "Soustons", "Dax", "Saint-Vincent-de-Tyrosse",
          "Saint-Martin-de-Seignanx", "Peyrehorade", "Pouillon"],
    "3": ["Tartas-Ouest", "Tartas-Est", "Villeneuve-de-Marsan", "Montfort",
          "Mugron", "Saint-Sever", "Grenade", "Amou", "Hagetmau",
          "Aire-sur-l'Adour", "Geaune"]}},

"41": {"nom": "Loir-et-Cher", "photo": 56, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Mer", "Herbault", "Blois-Est", "Blois-Ouest", "Contres",
          "Montrichard"],
    "2": ["Bracieux", "Neung-sur-Beuvron", "Lamotte-Beuvron", "Salbris",
          "Romorantin", "Selles-sur-Cher", "Mennetou-sur-Cher", "Saint-Aignan"],
    "3": ["Mondoubleau", "Droué", "Morée", "Ouzouer-le-Marché",
          "Savigny-sur-Braye", "Vendôme", "Selommes", "Marchenoir", "Montoire",
          "Saint-Amand-Longpré"]}},

"42": {"nom": "Loire", "photo": 57, "depuis": 1958, "jusqu": 1986, "circos": {
    # DOUTE sur Saint-Étienne et ses abords : à cette échelle, les quatre
    # cantons de la ville et Saint-Héand ne se rangent pas sûrement.
    "1": ["Saint-Étienne-Nord-Est", "Saint-Étienne-Nord-Ouest"],
    "2": ["Saint-Étienne-Sud-Est", "Saint-Étienne-Sud-Ouest",
          "Saint-Genest-Malifaux", "Bourg-Argental"],
    "3": ["Saint-Héand", "Rive-de-Gier", "Saint-Chamond", "Pélussin"],
    "4": ["Firminy", "Le Chambon-Feugerolles"],
    "5": ["La Pacaudière", "Saint-Haon", "Roanne", "Saint-Just-en-Chevalet",
          "Saint-Germain-Laval"],
    "6": ["Charlieu", "Belmont", "Perreux", "Saint-Symphorien-de-Lay", "Néronde",
          "Feurs"],
    "7": ["Noirétable", "Boën", "Saint-Georges-en-Couzan", "Montbrison",
          "Saint-Galmier", "Chazelles-sur-Lyon", "Saint-Jean",
          "Saint-Rambert-sur-Loire", "Saint-Bonnet-le-Château"]}},

"43": {"nom": "Haute-Loire", "photo": 58, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Le Monastier", "Fay-sur-Lignon", "Le Puy-Sud-Est",
          "Saint-Julien-Chapteuil", "Tence", "Yssingeaux", "Vorey", "Retournac",
          "Montfaucon", "Monistrol-sur-Loire", "Saint-Didier-en-Velay", "Bas"],
    "2": ["Pradelles", "Cayres", "Saugues", "Solignac-sur-Loire",
          "Le Puy-Nord-Ouest", "Loudes", "Langeac", "Pinols", "Saint-Paulien",
          "Allègre", "Paulhaguet", "Lavoûte-Chilhac", "Craponne-sur-Arzon",
          "La Chaise-Dieu", "Brioude", "Auzon", "Blesle"]}},

"44": {"nom": "Loire-Atlantique", "photo": 60, "depuis": 1958, "jusqu": 1986, "circos": {
    # Note de l'atlas : « les 1re, 2e et 3e circonscriptions correspondent
    # exactement aux circonscriptions de Nantes-1, Nantes-2 et Nantes-3 du
    # précédent découpage » (1928-1940). Les cantons de Nantes ne sont pas
    # détaillés sur la carte.
    "3": ["Bouaye", "Vertou"],
    # DOUTE : Carquefou, Le Loroux-Bottereau, Vallet et Clisson, autour
    # desquels le trait n'est pas net.
    "4": ["Varades", "Ancenis", "Ligné", "Riaillé", "Nort-sur-Erdre",
          "La Chapelle-sur-Erdre", "Carquefou", "Le Loroux-Bottereau", "Vallet",
          "Clisson"],
    "5": ["Saint-Mars-la-Jaille", "Saint-Julien-de-Vouvantes",
          "Moisdon-la-Rivière", "Châteaubriant", "Rougé", "Derval", "Nozay",
          "Guémené-Penfao", "Blain"],
    "6": ["Saint-Nazaire", "Savenay", "Saint-Étienne-de-Montluc"],
    "7": ["Saint-Nicolas-de-Redon", "Saint-Gildas-des-Bois", "Pontchâteau",
          "Herbignac", "Guérande", "Le Croisic"],
    "8": ["Paimbœuf", "Saint-Père-en-Retz", "Pornic", "Bourgneuf-en-Retz",
          "Le Pellerin", "Machecoul", "Legé", "Saint-Philbert-de-Grandlieu",
          "Aigrefeuille"]}},

"45": {"nom": "Loiret", "photo": 62, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Orléans-Nord-Est", "Orléans-Est", "Orléans-Sud", "Jargeau",
          "La Ferté-Saint-Aubin", "Sully-sur-Loire"],
    "2": ["Artenay", "Patay", "Orléans-Nord-Ouest", "Orléans-Ouest",
          "Meung-sur-Loire", "Cléry-Saint-André", "Beaugency"],
    "3": ["Outarville", "Malesherbes", "Puiseaux", "Pithiviers",
          "Beaune-la-Rolande", "Ferrières", "Neuville-aux-Bois", "Bellegarde",
          "Châteauneuf-sur-Loire", "Lorris", "Ouzouer-sur-Loire"],
    "4": ["Montargis", "Courtenay", "Châteaurenard", "Châtillon-Coligny", "Gien",
          "Briare", "Châtillon-sur-Loire"]}},

"46": {"nom": "Lot", "photo": 63, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Payrac", "Gourdon", "Salviac", "Cazals", "Saint-Germain-du-Bel-Air",
          "Labastide-Murat", "Catus", "Lauzès", "Puy-l'Évêque", "Luzech",
          "Cahors-Nord", "Cahors-Sud", "Saint-Géry", "Montcuq",
          "Castelnau-de-Montratier", "Lalbenque", "Limogne"],
    "2": ["Souillac", "Martel", "Vayrac", "Bretenoux", "Sousceyrac",
          "Saint-Céré", "Gramat", "Latronquière", "Lacapelle-Marival",
          "Livernon", "Figeac-Est", "Figeac-Ouest", "Cajarc"]}},

"47": {"nom": "Lot-et-Garonne", "photo": 64, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Port-Sainte-Marie", "Prayssas", "Agen-1", "Agen-2", "Lavardac",
          "Nérac", "Laplume", "Puymirol", "Astaffort", "Mézin", "Francescas"],
    "2": ["Duras", "Lauzun", "Seyches", "Meilhan", "Marmande", "Bouglon",
          "Le Mas-d'Agenais", "Tonneins", "Casteljaloux", "Damazan", "Houeillès"],
    "3": ["Castillonnès", "Villeréal", "Cancon", "Monflanquin", "Fumel",
          "Monclar", "Castelmoron", "Villeneuve-sur-Lot", "Penne",
          "Tournon-d'Agenais", "Sainte-Livrade", "Laroque-Timbaut", "Beauville"]}},

"49": {"nom": "Maine-et-Loire", "photo": 66, "depuis": 1958, "jusqu": 1986, "circos": {
    # DOUTE : Angers-Sud-Est (allongé sur le trait) et Tiercé.
    "1": ["Châteauneuf-sur-Sarthe", "Tiercé", "Angers-Nord-Est",
          "Angers-Sud-Est"],
    "2": ["Les Ponts-de-Cé", "Chalonnes-sur-Loire", "Saint-Florent-le-Vieil",
          "Chemillé"],
    "3": ["Saumur-Nord-Est", "Saumur-Nord-Ouest", "Longué", "Beaufort", "Noyant",
          "Baugé", "Seiches-sur-le-Loir", "Durtal"],
    "4": ["Montreuil-Bellay", "Doué-la-Fontaine", "Vihiers", "Saumur-Sud",
          "Gennes", "Thouarcé"],
    "5": ["Cholet", "Montfaucon", "Beaupréau", "Montrevault", "Champtoceaux"],
    "6": ["Le Lion-d'Angers", "Candé", "Segré", "Pouancé",
          "Le Louroux-Béconnais", "Saint-Georges-sur-Loire",
          "Angers-Nord-Ouest"]}},

"48": {"nom": "Lozère", "photo": 65, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Grandrieu", "Langogne", "Saint-Amans", "Châteauneuf-de-Randon",
          "Mende", "Le Bleymard", "Villefort", "Sainte-Enimie", "Florac",
          "Le Pont-de-Montvert", "Barre-des-Cévennes",
          "Saint-Germain-de-Calberte"],
    "2": ["Le Malzieu", "Fournels", "Saint-Chély-d'Apcher", "Saint-Alban",
          "Nasbinals", "Aumont", "Marvejols", "Saint-Germain-du-Teil", "Chanac",
          "La Canourgue", "Le Massegros", "Meyrueis"]}},

"50": {"nom": "Manche", "photo": 69, "depuis": 1958, "jusqu": 1986, "circos": {
    # Villedieu : trait épais vers Gavray, La Haye-Pesnel et Brécey ; il ne
    # s'ouvre que sur Percy.
    "1": ["Carentan", "Saint-Jean-de-Daye", "Saint-Clair-sur-l'Elle", "Marigny",
          "Saint-Lô", "Canisy", "Torigni-sur-Vire", "Tessy-sur-Vire", "Percy",
          "Villedieu"],
    "2": ["La Haye-Pesnel", "Sartilly", "Saint-Pois", "Brécey", "Sourdeval",
          "Avranches", "Juvigny", "Pontorson", "Ducey", "Isigny", "Mortain",
          "Saint-James", "Saint-Hilaire-du-Harcouët", "Barenton", "Le Teilleul"],
    "3": ["Périers", "Lessay", "Saint-Sauveur-Lendelin", "Saint-Malo-de-la-Lande",
          "Coutances", "Cerisy", "Montmartin-sur-Mer", "Bréhal", "Gavray",
          "Granville"],
    "4": ["Quettehou", "Les Pieux", "Valognes", "Bricquebec", "Montebourg",
          "Barneville", "Saint-Sauveur-le-Vicomte", "Sainte-Mère-Église",
          "La Haye-du-Puits"],
    "5": ["Beaumont", "Octeville", "Cherbourg", "Saint-Pierre-Église"]}},

"52": {"nom": "Haute-Marne", "photo": 72, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Bourmont", "Chaumont", "Châteauvillain", "Clefmont", "Nogent-le-Roi",
          "Arc-en-Barrois", "Montigny-le-Roi", "Bourbonne", "Neuilly-l'Évêque",
          "Langres", "Varennes-sur-Amance", "La Ferté", "Auberive", "Longeau",
          "Fays-Billot", "Prauthoy"],
    "2": ["Saint-Dizier", "Wassy", "Chevillon", "Montier-en-Der", "Joinville",
          "Poissons", "Doulevant", "Doulaincourt", "Vignory", "Juzennecourt",
          "Saint-Blin", "Andelot"]}},

"53": {"nom": "Mayenne", "photo": 73, "depuis": 1958, "jusqu": 1986, "circos": {
    # DOUTE : Chailland, entre le trait d'Ernée et celui de Loiron.
    "1": ["Chailland", "Laval-Ouest", "Laval-Est", "Argentré", "Montsûrs",
          "Évron", "Bais", "Villaines"],
    "2": ["Loiron", "Cossé-le-Vivien", "Craon", "Saint-Aignan-sur-Roë",
          "Château-Gontier", "Meslay-du-Maine", "Sainte-Suzanne",
          "Grez-en-Bouère", "Bierné"],
    "3": ["Landivy", "Gorron", "Ambrières", "Lassay", "Couptrain", "Pré-en-Pail",
          "Le Horps", "Ernée", "Mayenne-Ouest", "Mayenne-Est"]}},

"51": {"nom": "Marne", "photo": 70, "depuis": 1958, "jusqu": 1986, "circos": {
    # La flèche « Châtillon-sur-Marne » désigne le petit canton entre
    # Ville-en-Tardenois et Ay.
    "1": ["Fismes", "Ville-en-Tardenois", "Reims-1", "Reims-3", "Verzy", "Ay",
          "Châtillon-sur-Marne"],
    # DOUTE : Suippes, cerné d'un trait épais à l'ouest, au sud et à l'est ;
    # il ne s'ouvre que sur Beine.
    "2": ["Bourgogne", "Reims-4", "Reims-2", "Beine", "Suippes"],
    "3": ["Châlons-sur-Marne", "Marson", "Vitry-le-François",
          "Saint-Rémy-en-Bouzemont", "Thiéblemont", "Heiltz-le-Maurupt",
          "Givry-en-Argonne", "Sainte-Menehould", "Ville-sur-Tourbe"],
    "4": ["Dormans", "Épernay", "Avize", "Montmort", "Vertus", "Écury",
          "Montmirail", "Esternay", "Sézanne", "Fère-Champenoise", "Anglure",
          "Sompuis"]}},

"54": {"nom": "Meurthe-et-Moselle", "photo": 74, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Pont-à-Mousson", "Nomeny", "Nancy-Nord"],
    "2": ["Nancy-Ouest", "Saint-Nicolas"],
    # DOUTE : Nancy-Sud, étiré entre deux traits épais.
    "3": ["Nancy-Est", "Nancy-Sud"],
    "4": ["Arracourt", "Lunéville-Nord", "Lunéville-Sud", "Blâmont", "Cirey",
          "Bayon", "Gerbéviller", "Baccarat", "Badonviller"],
    "5": ["Thiaucourt", "Domèvre", "Toul-Nord", "Toul-Sud",
          "Colombey-les-Belles", "Vézelise", "Haroué"],
    "6": ["Audun-le-Roman", "Briey", "Conflans", "Chambley"],
    "7": ["Longuyon", "Longwy"]}},

"55": {"nom": "Meuse", "photo": 76, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Triaucourt", "Vaubecourt", "Vigneulles", "Pierrefitte-sur-Aire",
          "Saint-Mihiel", "Revigny", "Vavincourt", "Commercy", "Bar-le-Duc",
          "Ligny-en-Barrois", "Ancerville", "Void", "Montiers-sur-Saulx",
          "Gondrecourt", "Vaucouleurs"],
    "2": ["Stenay", "Montmédy", "Dun-sur-Meuse", "Damvillers", "Spincourt",
          "Montfaucon", "Varennes-en-Argonne", "Charny", "Étain",
          "Clermont-en-Argonne", "Verdun", "Fresnes-en-Woëvre", "Souilly"]}},

"56": {"nom": "Morbihan", "photo": 77, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Vannes-Ouest", "Vannes-Est", "Sarzeau", "Muzillac", "Questembert",
          "Rochefort-en-Terre", "Allaire", "La Roche-Bernard"],
    "2": ["Port-Louis", "Belle-Île", "Pluvigner", "Belz", "Auray", "Quiberon"],
    # Grand-Champ et Elven sont coupés de Vannes par le trait.
    "3": ["Pontivy", "Rohan", "Baud", "Locminé", "Saint-Jean", "Grand-Champ",
          "Elven"],
    "4": ["Josselin", "La Trinité", "Mauron", "Ploërmel", "Guer", "Malestroit",
          "La Gacilly"],
    "5": ["Pont-Scorff", "Lorient-1", "Lorient-2", "Groix"],
    "6": ["Gourin", "Le Faouët", "Guéméné", "Cléguérec", "Plouay", "Hennebont"]}},

"57": {"nom": "Moselle", "photo": 79, "depuis": 1958, "jusqu": 1986, "circos": {
    # Note de l'atlas : « le canton de Metz-Campagne était divisé de la même
    # façon que de 1928 à 1940 ». DOUTE : Metz-Ville, posé sur le trait qui
    # sépare la 1re de la 2e ; et la part de Metz-Campagne qui revient à la 2e.
    "1": ["Metz-Campagne", "Ars-sur-Moselle", "Metz-Ville"],
    "2": ["Vigy", "Pange", "Verny"],
    "3": ["Fontoy", "Hayange", "Moyeuvre-Grande"],
    "4": ["Cattenom", "Sierck", "Thionville", "Metzerwisse"],
    "5": ["Bouzonville", "Boulay", "Faulquemont", "Saint-Avold"],
    "6": ["Forbach", "Grostenquin", "Sarralbe"],
    "7": ["Sarreguemines", "Rohrbach", "Volmunster", "Bitche"],
    "8": ["Delme", "Château-Salins", "Albestroff", "Dieuze", "Vic-sur-Seille",
          "Fénétrange", "Phalsbourg", "Sarrebourg", "Réchicourt", "Lorquin"]}},

"58": {"nom": "Nièvre", "photo": 80, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Nevers", "Saint-Benin-d'Azy", "Decize", "Saint-Pierre-le-Moûtier",
          "Dornes"],
    "2": ["Saint-Amand-en-Puisaye", "Cosne", "Donzy", "Varzy", "Pouilly",
          "Prémery", "La Charité", "Pougues-les-Eaux", "Saint-Saulge"],
    "3": ["Clamecy", "Tannay", "Lormes", "Brinon-sur-Beuvron", "Corbigny",
          "Montsauche", "Châtillon-en-Bazois", "Château-Chinon",
          "Moulins-Engilbert", "Luzy", "Fours"]}},

"60": {"nom": "Oise", "photo": 84, "depuis": 1958, "jusqu": 1986, "circos": {
    # DOUTE : Maignelay et Ressons-sur-Matz, au nord du trait de Saint-Just,
    # sans trait épais vers Breteuil.
    "1": ["Formerie", "Grandvilliers", "Crèvecœur-le-Grand", "Breteuil",
          "Marseille-en-Beauvaisis", "Froissy", "Nivillers", "Beauvais-Nord-Est",
          "Maignelay", "Ressons-sur-Matz"],
    "2": ["Lassigny", "Guiscard", "Noyon", "Ribécourt", "Attichy", "Compiègne"],
    # DOUTE : Mouy, que le trait semble cerner de tous côtés.
    "3": ["Saint-Just-en-Chaussée", "Clermont", "Estrées-Saint-Denis",
          "Liancourt", "Mouy", "Pont-Sainte-Maxence", "Crépy-en-Valois"],
    "4": ["Neuilly-en-Thelle", "Creil", "Senlis", "Nanteuil-le-Haudouin", "Betz"],
    "5": ["Songeons", "Le Coudray", "Auneuil", "Beauvais-Sud-Ouest", "Noailles",
          "Chaumont-en-Vexin", "Méru"]}},

"61": {"nom": "Orne", "photo": 85, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Domfront", "Passais", "Juvigny", "La Ferté-Macé", "Carrouges",
          "Alençon-Ouest", "Alençon-Est", "Sées", "Courtomer", "Le Mêle"],
    "2": ["Gacé", "Le Merlerault", "La Ferté-Fresnel", "Laigle",
          "Moulins-la-Marche", "Bazoches", "Tourouvre", "Mortagne", "Longny",
          "Pervenchères", "Rémalard", "Bellême", "Nocé", "Le Theil"],
    "3": ["Tinchebray", "Flers", "Athis", "Putanges", "Messei", "Briouze",
          "Écouché", "Argentan", "Trun", "Exmes", "Vimoutiers", "Mortrée"]}},

"59": {"nom": "Nord", "photo": 82, "depuis": 1958, "jusqu": 1986, "circos": {
    # DOUTE sur toute l'agglomération lilloise (1re à 5e) : l'encart ne
    # sépare pas sûrement les sept cantons de Lille. Ce qui suit est la
    # lecture la plus probable, pas une lecture sûre.
    "1": ["Lille-Ouest"],
    "2": ["Lille-Centre", "Lille-Sud"],
    "3": ["Lille-Nord", "Lille-Nord-Est", "Lille-Est"],
    "4": ["Lille-Sud-Est"],
    "5": ["Lille-Sud-Ouest", "Haubourdin", "La Bassée"],
    "6": ["Seclin", "Cysoing", "Pont-à-Marcq"],
    "7": ["Roubaix-Est", "Lannoy"],
    "8": ["Roubaix-Ouest", "Roubaix-Nord"],
    "9": ["Tourcoing-Nord-Est", "Tourcoing-Sud"],
    "10": ["Armentières", "Quesnoy", "Tourcoing-Nord"],
    "11": ["Gravelines", "Dunkerque-Ouest", "Dunkerque-Est"],
    "12": ["Bourbourg", "Bergues", "Hondschoote", "Wormhoudt", "Cassel",
           "Steenvoorde"],
    # L'atlas écrit « Bailleul-Nord-Ouest » : c'est Bailleul-Nord-Est.
    "13": ["Hazebrouck-Nord", "Hazebrouck-Sud", "Bailleul-Sud-Ouest",
           "Bailleul-Nord-Est", "Merville"],
    # DOUTE : Orchies, cerné d'un trait épais sur trois côtés.
    "14": ["Douai-Ouest", "Douai-Est", "Orchies"],
    "15": ["Arleux", "Douai-Sud", "Marchiennes"],
    "16": ["Cambrai-Ouest", "Cambrai-Est", "Carnières", "Marcoing"],
    "17": ["Solesmes", "Clary", "Le Cateau"],
    "18": ["Condé-sur-Escaut", "Valenciennes-Est"],
    "19": ["Saint-Amand-Rive-Gauche", "Saint-Amand-Rive-Droite",
           "Valenciennes-Nord"],
    "20": ["Denain", "Bouchain", "Valenciennes-Sud"],
    "21": ["Avesnes-Nord", "Avesnes-Sud", "Solre-le-Château", "Trélon"],
    "22": ["Maubeuge-Nord", "Maubeuge-Sud", "Hautmont"],
    "23": ["Bavay", "Le Quesnoy-Ouest", "Le Quesnoy-Est", "Berlaimont",
           "Landrecies"]}},

"62": {"nom": "Pas-de-Calais", "photo": 87, "depuis": 1958, "jusqu": 1986, "circos": {
    # Notes de l'atlas, recopiées :
    # « le canton de Vimy était divisé : les communes d'Avion et Éleu étaient
    #   rattachées à la 12e ; celles de Gavrelle, Izel, Neuvireuil, Oppy et
    #   Quiéry étaient incluses dans la 2e ; le reste du canton faisait partie
    #   de la 1re » ;
    # « le canton d'Houdain était divisé : les communes de Beugin, Calonne,
    #   Camblain, Caucourt, Divion, Estrée, Gauchin, Hermin, Houdain, Ourton,
    #   Ranchicourt et Rebreuve étaient rattachées à la 3e ; le reste du canton
    #   constituait la 10e » ;
    # « le canton de Norrent-Fontes était divisé : les communes d'Auchel,
    #   Cauchy et Lozinghem faisaient partie de la 9e ; le reste du canton
    #   était rattaché à la 8e » ;
    # « le canton de Lens était divisé : les communes de Billy, Fouquières,
    #   Lens, Loison, Noyelles et Sallaumines constituaient la 13e ; le reste
    #   du canton était rattaché à la 11e ».
    "1": ["Arras-Nord", "Arras-Sud", "reste:Vimy"],
    "2": ["Avesnes", "Beaumetz", "Pas", "Croisilles", "Bapaume", "Bertincourt",
          "Marquion", "Vitry",
          "communes:Vimy:Gavrelle,Izel,Neuvireuil,Oppy,Quiéry"],
    "3": ["Heuchin", "Parcq", "Saint-Pol", "Aubigny", "Auxi",
          "communes:Houdain:Beugin,Calonne,Camblain,Caucourt,Divion,Estrée,"
          "Gauchin,Hermin,Houdain,Ourton,Ranchicourt,Rebreuve"],
    "4": ["Étaples", "Hucqueliers", "Fruges", "Montreuil",
          "Campagne-lès-Hesdin", "Hesdin"],
    # DOUTE sur tout le nord-ouest (5e à 8e) : Desvres et Lumbres semblent
    # chacun cernés d'un trait épais, ce qui ne peut pas être.
    "5": ["Boulogne-Sud", "Samer", "Desvres"],
    "6": ["Boulogne-Nord", "Marquise", "Guînes", "Ardres"],
    "7": ["Calais-Nord-Ouest", "Calais-Sud-Est", "Audruicq"],
    "8": ["Saint-Omer-Nord", "Saint-Omer-Sud", "Lumbres", "Aire",
          "Fauquembergues", "reste:Norrent-Fontes"],
    "9": ["Lillers", "Béthune",
          "communes:Norrent-Fontes:Auchel,Cauchy,Lozinghem"],
    "10": ["reste:Houdain"],
    "11": ["Laventie", "Cambrin", "reste:Lens"],
    "12": ["Liévin", "communes:Vimy:Avion,Éleu"],
    "13": ["communes:Lens:Billy,Fouquières,Lens,Loison,Noyelles,Sallaumines"],
    "14": ["Carvin"]}},

"64": {"nom": "Pyrénées-Atlantiques", "photo": 90, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Garlin", "Thèze", "Lembeye", "Montaner", "Morlaàs", "Lescar",
          "Pau-Est", "Pau-Ouest", "Pontacq", "Nay-Est", "Nay-Ouest"],
    "2": ["Arzacq", "Arthez", "Orthez", "Salies", "Sauveterre", "Lagor",
          "Navarrenx", "Monein", "Lasseube", "Oloron-Sainte-Marie-Ouest",
          "Oloron-Sainte-Marie-Est", "Aramits", "Arudy", "Accous", "Laruns"],
    "3": ["Bidache", "Labastide", "Hasparren", "Espelette", "Saint-Palais",
          "Iholdy", "Mauléon", "Saint-Étienne", "Saint-Jean-Pied-de-Port",
          "Tardets"],
    "4": ["Bayonne-Nord-Est", "Bayonne-Nord-Ouest", "Biarritz", "Ustaritz",
          "Saint-Jean-de-Luz"]}},

"65": {"nom": "Hautes-Pyrénées", "photo": 91, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Trie", "Castelnau-Magnoac", "Galan", "Tournay", "Tarbes-Sud",
          "Lannemezan", "Bagnères-de-Bigorre", "Saint-Laurent", "Labarthe",
          "Campan", "Mauléon", "Arreau", "Vielle-Aure", "Bordères"],
    "2": ["Castelnau-Rivière-Basse", "Maubourguet", "Vic-en-Bigorre",
          "Rabastens", "Tarbes-Nord", "Pouyastruc", "Ossun", "Saint-Pé",
          "Lourdes", "Aucun", "Argelès", "Luz"]}},

"66": {"nom": "Pyrénées-Orientales", "photo": 92, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Perpignan-Est", "Argelès", "Céret", "Arles-sur-Tech",
          "Prats-de-Mollo"],
    # Thuir : le trait le contourne par l'est et le sud.
    "2": ["Saint-Paul-de-Fenouillet", "La Tour", "Rivesaltes",
          "Saint-Laurent-de-la-Salanque", "Sournia", "Perpignan-Ouest", "Millas",
          "Prades", "Vinça", "Thuir", "Mont-Louis", "Olette", "Saillagouse"]}},

"63": {"nom": "Puy-de-Dôme", "photo": 89, "depuis": 1958, "jusqu": 1986, "circos": {
    # DOUTE sur Clermont : Nord et Sud-Ouest paraissent à l'ouest du trait
    # (2e), Est et Sud à l'est (1re).
    "1": ["Clermont-Ferrand-Est", "Clermont-Ferrand-Sud", "Pont-du-Château",
          "Vertaizon", "Billom"],
    "2": ["Herment", "Bourg-Lastic", "Rochefort-Montagne",
          "Saint-Amant-Tallende", "Clermont-Ferrand-Nord",
          "Clermont-Ferrand-Sud-Ouest"],
    "3": ["Tauves", "Latour", "Besse", "Champeix", "Ardes", "Veyre",
          "Vic-le-Comte", "Issoire", "Saint-Germain-Lembron", "Sauxillanges",
          "Jumeaux"],
    # DOUTE : Saint-Dier, entre deux traits épais (Billom à l'ouest, Cunlhat
    # au sud).
    "4": ["Maringues", "Châteldon", "Lezoux", "Thiers", "Saint-Rémy",
          "Courpière", "Saint-Dier", "Olliergues", "Cunlhat", "Saint-Amant",
          "Ambert", "Saint-Anthème", "Saint-Germain-l'Herm", "Arlanc",
          "Viverols"],
    "5": ["Montaigut", "Pionsat", "Menat", "Saint-Gervais", "Manzat",
          "Pontaumur", "Pontgibaud", "Aigueperse", "Randan", "Combronde",
          "Riom-Ouest", "Riom-Est", "Ennezat"]}},

"68": {"nom": "Haut-Rhin", "photo": 95, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Sainte-Marie-aux-Mines", "Ribeauvillé", "Lapoutroie", "Kaysersberg",
          "Colmar-Nord", "Andolsheim"],
    "2": ["Munster", "Wintzenheim", "Colmar-Sud", "Neuf-Brisach", "Rouffach",
          "Guebwiller", "Soultz", "Ensisheim"],
    "3": ["Saint-Amarin", "Masevaux", "Thann", "Cernay", "Dannemarie",
          "Altkirch", "Hirsingue", "Ferrette"],
    # DOUTE : Wittenheim et Mulhouse-Sud, de part et d'autre du trait qui
    # ceint la ville.
    "4": ["Mulhouse-Nord", "Mulhouse-Ouest", "Mulhouse-Est", "Wittenheim"],
    "5": ["Habsheim", "Mulhouse-Sud", "Sierentz", "Huningue"]}},

"67": {"nom": "Bas-Rhin", "photo": 93, "depuis": 1958, "jusqu": 1986, "circos": {
    # 1re et 2e : Strasbourg, non détaillé (« 1 et 2 »).
    # DOUTE : Hochfelden et Truchtersheim forment une bande entre deux traits
    # épais, ouverte au sud sur Schiltigheim.
    "3": ["Hochfelden", "Truchtersheim", "Schiltigheim", "Geispolsheim"],
    "4": ["Obernai", "Erstein", "Barr", "Benfeld", "Sélestat", "Marckolsheim"],
    "5": ["Wasselonne", "Molsheim", "Rosheim", "Schirmeck", "Saales", "Villé"],
    "6": ["Sarre-Union", "Drulingen", "La Petite-Pierre", "Bouxwiller",
          "Saverne", "Marmoutier"],
    "7": ["Wissembourg", "Niederbronn", "Wœrth", "Soultz", "Lauterbourg",
          "Seltz"],
    "8": ["Haguenau", "Bischwiller", "Brumath"]}},

"71": {"nom": "Saône-et-Loire", "photo": 98, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Saint-Gengoux-le-National", "Tournus", "Cuisery", "Montpont",
          "Cuiseaux", "Cluny", "Lugny", "Matour", "Tramayes", "Mâcon-Nord",
          "Mâcon-Sud", "La Chapelle-de-Guinchay"],
    "2": ["Bourbon-Lancy", "Gueugnon", "Toulon-sur-Arroux", "Digoin", "Palinges",
          "La Guiche", "Paray-le-Monial", "Charolles", "Saint-Bonnet-de-Joux",
          "Marcigny", "Semur", "La Clayette", "Chauffailles"],
    "3": ["Lucenay-l'Évêque", "Autun", "Épinac", "Saint-Léger-sous-Beuvray",
          "Couches", "Mesvres", "Le Creusot", "Montcenis", "Issy-l'Évêque"],
    # DOUTE : Montceau-les-Mines et Mont-Saint-Vincent, que le trait
    # contourne par l'ouest et le sud.
    "4": ["Chagny", "Givry", "Buxy", "Chalon-Sud", "Sennecey", "Montchanin",
          "Mont-Saint-Vincent", "Montceau-les-Mines"],
    "5": ["Chalon-Nord", "Verdun-sur-le-Doubs", "Saint-Martin-en-Bresse",
          "Pierre-de-Bresse", "Saint-Germain-du-Bois", "Saint-Germain-du-Plain",
          "Montret", "Louhans", "Beaurepaire"]}},

# Le Rhône a deux découpages : 1958, puis 1973 (loi du 29 juin 1972, qui
# ajoute trois circonscriptions avec les cantons pris à l'Isère).
# Lyon (1re à 5e) n'est pas détaillé par la carte.
"69": {"nom": "Rhône", "photo": 96, "depuis": 1958, "jusqu": 1973, "circos": {
    # Note : « le canton de Vaugneray était divisé : la commune de Tassin
    # appartenait à la 7e circonscription, les autres communes à la 8e ».
    "6": ["Villeurbanne"],
    "7": ["Neuville", "Limonest", "commune:Tassin"],
    "8": ["L'Arbresle", "reste:Vaugneray", "Saint-Genis-Laval",
          "Saint-Symphorien-sur-Coise", "Mornant", "Givors", "Condrieu"],
    "9": ["Lamure", "Thizy", "Amplepuis", "Tarare", "Le Bois-d'Oingt",
          "Saint-Laurent-de-Chamousset"],
    "10": ["Monsols", "Beaujeu", "Belleville", "Villefranche", "Anse"]}},
"69b": {"nom": "Rhône", "photo": 97, "depuis": 1973, "jusqu": 1986, "circos": {
    # Notes : « le canton de Bron était divisé : Bron et Vaulx étaient
    # rattachés à la 13e circonscription, Saint-Fons et Vénissieux à la 11e » ;
    # « le canton de Vaugneray était divisé : Tassin et Francheville
    # appartenaient à la 12e circonscription, et les autres communes à la 8e ».
    "6": ["Villeurbanne"],
    "7": ["Neuville", "Limonest", "Rillieux"],
    "8": ["L'Arbresle", "reste:Vaugneray", "Saint-Symphorien-sur-Coise",
          "Mornant", "Givors", "Condrieu"],
    "9": ["Lamure", "Thizy", "Amplepuis", "Tarare", "Le Bois-d'Oingt",
          "Saint-Laurent-de-Chamousset"],
    "10": ["Monsols", "Beaujeu", "Belleville", "Villefranche", "Anse"],
    "11": ["Saint-Symphorien-d'Ozon", "communes:Bron:Saint-Fons,Vénissieux"],
    "12": ["Saint-Genis-Laval", "communes:Vaugneray:Tassin,Francheville"],
    "13": ["Meyzieu", "communes:Bron:Bron,Vaulx"]}},

"74": {"nom": "Haute-Savoie", "photo": 102, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Saint-Julien-en-Genevois", "Frangy", "Seyssel", "Cruseilles",
          "Thorens", "Rumilly", "Annecy-Nord", "Annecy-Sud", "Alby", "Thônes",
          "Faverges"],
    "2": ["Douvaine", "Thonon", "Évian", "Abondance", "Le Biot", "Boëge",
          "Saint-Jeoire", "Taninges", "Samoëns"],
    "3": ["Annemasse", "Reignier", "La Roche", "Bonneville", "Cluses",
          "Sallanches", "Saint-Gervais", "Chamonix"]}},

"73": {"nom": "Savoie", "photo": 101, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Ruffieux", "Albens", "Aix-les-Bains", "Yenne", "Le Châtelard",
          "La Motte-Servolex", "Chambéry-Nord", "Chambéry-Sud", "Saint-Genix",
          "Pont-de-Beauvoisin", "Les Échelles", "Saint-Pierre-d'Albigny"],
    "2": ["Ugine", "Beaufort", "Grésy", "Albertville", "Aime",
          "Bourg-Saint-Maurice", "Moûtiers", "Bozel"],
    "3": ["Montmélian", "Chamoux", "Aiguebelle", "La Rochette", "La Chambre",
          "Saint-Jean-de-Maurienne", "Saint-Michel-de-Maurienne", "Modane",
          "Lanslebourg"]}},

"76": {"nom": "Seine-Maritime", "photo": 104, "depuis": 1958, "jusqu": 1986, "circos": {
    # Note de l'atlas : « le canton de Montivilliers était divisé : les
    # communes de Gainneville et Gonfreville étaient rattachées à la 7e
    # circonscription, les autres communes à la 6e. En outre, la loi du
    # 12 juillet 1966 a transféré les communes d'Harfleur et Rouelles de la
    # 6e à la 7e circonscription. »
    # Le Havre (6 cantons) est partagé entre la 6e et la 7e, Rouen forme la
    # 1re : ni l'un ni l'autre n'est détaillé.
    "1": ["Rouen", "Darnétal"],
    # DOUTE : Boos. La 3e est désignée par une flèche qui vise Sotteville
    # seul, cerné d'un trait épais.
    "2": ["Grand-Couronne", "Elbeuf", "Boos"],
    "3": ["Sotteville"],
    "4": ["Duclair", "Maromme", "Pavilly", "Clères"],
    "5": ["Fécamp", "Goderville", "Criquetot", "Bolbec",
          "Saint-Romain-de-Colbosc", "Lillebonne", "Caudebec-en-Caux"],
    "6": ["reste:Montivilliers", "partie:Le Havre"],
    "7": ["communes:Montivilliers:Gainneville,Gonfreville", "partie:Le Havre"],
    "8": ["Valmont", "Saint-Valery-en-Caux", "Cany", "Fontaine-le-Dun",
          "Ourville-en-Caux", "Doudeville", "Fauville-en-Caux", "Yvetot",
          "Yerville", "Bacqueville-en-Caux", "Tôtes"],
    "9": ["Offranville", "Dieppe", "Longueville-sur-Scie", "Envermeu", "Eu"],
    "10": ["Blangy-sur-Bresle", "Londinières", "Aumale", "Neufchâtel-en-Bray",
           "Bellencombre", "Saint-Saëns", "Forges-les-Eaux", "Buchy", "Argueil",
           "Gournay-en-Bray"]}},

"77": {"nom": "Seine-et-Marne", "photo": 105, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Tournan-en-Brie", "Brie-Comte-Robert", "Melun-Nord", "Melun-Sud",
          "Mormant", "Le Châtelet-en-Brie"],
    "2": ["Dammartin", "Claye-Souilly", "Lagny"],
    "3": ["Lizy", "Meaux", "La Ferté-sous-Jouarre", "Crécy-en-Brie", "Rebais",
          "Coulommiers"],
    "4": ["Rozay-en-Brie", "La Ferté-Gaucher", "Nangis",
          "Villiers-Saint-Georges", "Provins", "Donnemarie", "Bray-sur-Seine",
          "Montereau-fault-Yonne"],
    "5": ["Fontainebleau", "La Chapelle", "Moret-sur-Loing", "Nemours", "Lorrez",
          "Château-Landon"]}},

"72": {"nom": "Sarthe", "photo": 99, "depuis": 1958, "jusqu": 1986, "circos": {
    # DOUTE : Le Mans-I, mince bande entre deux traits épais, ouverte au nord
    # sur Ballon.
    "1": ["Sillé-le-Guillaume", "Conlie", "Beaumont-sur-Sarthe", "Ballon",
          "Le Mans-1"],
    "2": ["Le Mans-3", "Montfort-le-Rotrou", "Bouloire", "Saint-Calais",
          "Le Grand-Lucé"],
    "3": ["Écommoy", "Malicorne-sur-Sarthe", "Pontvallain", "La Flèche",
          "Le Lude", "Mayet", "Château-du-Loir", "La Chartre"],
    "4": ["Loué", "Brûlon", "Sablé-sur-Sarthe", "La Suze-sur-Sarthe",
          "Le Mans-2"],
    "5": ["La Fresnaye", "Saint-Paterne", "Mamers", "Fresnay-sur-Sarthe",
          "Marolles-les-Braults", "Bonnétable", "La Ferté-Bernard", "Tuffé",
          "Montmirail", "Vibraye"]}},

"79": {"nom": "Deux-Sèvres", "photo": 110, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Niort-1", "Niort-2", "Frontenay-Rohan-Rohan", "Mauzé", "Prahecq",
          "Beauvoir", "Celles-sur-Belle", "Lezay", "Melle", "Sauzé",
          "Brioux-sur-Boutonne", "Chef-Boutonne"],
    "2": ["Moncoutant", "Parthenay", "Saint-Loup", "Thénezay", "Secondigny",
          "Coulonges", "Mazières-en-Gâtine", "Ménigoute", "Champdeniers",
          "Saint-Maixent-1", "Saint-Maixent-2", "La Mothe"],
    "3": ["Argenton-Château", "Thouars", "Châtillon-sur-Sèvre", "Saint-Varent",
          "Airvault", "Bressuire", "Cerizay"]}},

"80": {"nom": "Somme", "photo": 111, "depuis": 1958, "jusqu": 1986, "circos": {
    # DOUTE : Villers-Bocage, que le trait sépare de Picquigny et de Domart ;
    # il s'ouvre sur Corbie et sur Amiens.
    "1": ["Amiens-Nord-Ouest", "Amiens-Nord-Est", "Amiens-Sud-Ouest",
          "Amiens-Sud-Est", "Villers-Bocage"],
    "2": ["Corbie", "Boves", "Conty", "Ailly-sur-Noye", "Moreuil", "Rosières",
          "Montdidier", "Roye"],
    "3": ["Ault", "Moyenneville", "Gamaches", "Hallencourt", "Oisemont",
          "Picquigny", "Molliens", "Hornoy", "Poix"],
    "4": ["Rue", "Crécy-en-Ponthieu", "Nouvion", "Saint-Valery-sur-Somme",
          "Abbeville-Nord", "Abbeville-Sud", "Ailly", "Bernaville",
          "Domart-en-Ponthieu"],
    "5": ["Doullens", "Acheux", "Albert", "Combles", "Bray-sur-Somme", "Roisel",
          "Péronne", "Chaulnes", "Nesle", "Ham"]}},

"81": {"nom": "Tarn", "photo": 112, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Monestiés", "Pampelonne", "Carmaux", "Valderiès", "Valence", "Albi",
          "Villefranche-d'Albigeois", "Alban", "Réalmont"],
    "2": ["Montredon", "Vabre", "Lacaune", "Murat", "Roquecourbe", "Brassac",
          "Castres", "Anglès", "Mazamet", "Labruguière", "Saint-Amans"],
    "3": ["Vaour", "Cordes", "Castelnau", "Salvagnac", "L'Isle-sur-Tarn",
          "Gaillac", "Rabastens", "Cadalen", "Graulhet", "Lautrec", "Lavaur",
          "Saint-Paul", "Vielmur", "Cuq-Toulza", "Puylaurens", "Dourgne"]}},

"82": {"nom": "Tarn-et-Garonne", "photo": 113, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Molières", "Montpezat-de-Quercy", "Caylus", "Caussade",
          "Saint-Antonin", "Lafrançaise", "Montauban-Est", "Nègrepelisse",
          "Montauban-Ouest", "Monclar-de-Quercy", "Villebrumier"],
    "2": ["Montaigu-de-Quercy", "Bourg-de-Visa", "Lauzerte", "Valence-d'Agen",
          "Moissac", "Auvillar", "Castelsarrasin", "Lavit", "Saint-Nicolas",
          "Montech", "Grisolles", "Beaumont", "Verdun-sur-Garonne"]}},

"83": {"nom": "Var", "photo": 115, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Rians", "Aups", "Comps", "Tavernes", "Fayence", "Callas", "Barjols",
          "Salernes", "Draguignan", "Saint-Maximin", "Cotignac", "Lorgues",
          "Brignoles", "Besse", "Le Luc", "La Roquebrussanne", "Cuers"],
    "2": ["Fréjus", "Grimaud", "Saint-Tropez", "Collobrières", "Hyères"],
    # DOUTE : les quatre cantons de Toulon et Solliès-Pont. Le trait isole
    # Toulon-I avec Ollioules ; II, III et IV vont avec Solliès-Pont.
    "3": ["Solliès-Pont", "Toulon-2", "Toulon-3", "Toulon-4"],
    "4": ["Le Beausset", "Ollioules", "La Seyne", "Toulon-1"]}},

"84": {"nom": "Vaucluse", "photo": 117, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Avignon-Nord", "Avignon-Sud", "L'Isle-sur-la-Sorgue", "Cavaillon"],
    "2": ["Carpentras-Nord", "Carpentras-Sud", "Mormoiron", "Sault", "Pernes",
          "Gordes", "Apt", "Bonnieux", "Cadenet", "Pertuis"],
    "3": ["Valréas", "Bollène", "Vaison-la-Romaine", "Malaucène", "Orange-Est",
          "Orange-Ouest", "Beaumes", "Bédarrides"]}},

"85": {"nom": "Vendée", "photo": 118, "depuis": 1958, "jusqu": 1986, "circos": {
    # Le haut de la carte (Montaigu, Mortagne, Rocheservière) est coupé par
    # le cadrage ; aucun trait épais ne les sépare de Saint-Fulgent.
    "1": ["Montaigu", "Mortagne", "Rocheservière", "Saint-Fulgent",
          "Les Herbiers", "Palluau", "Le Poiré-sur-Vie", "Les Essarts",
          "La Roche-sur-Yon", "Chantonnay", "Mareuil"],
    "2": ["Pouzauges", "La Châtaigneraie", "Sainte-Hermine", "L'Hermenault",
          "Saint-Hilaire", "Talmont", "Les Moutiers-les-Mauxfaits", "Luçon",
          "Chaillé-les-Marais", "Fontenay-le-Comte", "Maillezais"],
    "3": ["Noirmoutier", "Beauvoir", "Challans", "Saint-Jean-de-Monts",
          "L'Île-d'Yeu", "Saint-Gilles", "La Mothe-Achard",
          "Les Sables-d'Olonne"]}},

"86": {"nom": "Vienne", "photo": 120, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Mirebeau", "Neuville-de-Poitou", "Saint-Georges", "Vouillé",
          "Poitiers-Nord", "Poitiers-Sud", "Saint-Julien", "La Villedieu"],
    "2": ["Les Trois-Moutiers", "Loudun", "Moncontour", "Monts-sur-Guesnes",
          "Leigné-sur-Usseau", "Dangé", "Lencloître", "Châtellerault",
          "Pleumartin", "Vouneuil"],
    "3": ["Saint-Savin", "Chauvigny", "Lusignan", "Vivonne", "Lussac",
          "La Trimouille", "Gençay", "Montmorillon", "Couhé", "Civray",
          "Charroux", "L'Isle-Jourdain", "Availles"]}},

"87": {"nom": "Haute-Vienne", "photo": 121, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Limoges-Nord", "Limoges-Est", "Limoges-Sud", "Saint-Léonard",
          "Eymoutiers", "Châteauneuf-la-Forêt"],
    # DOUTE : Limoges-Ouest, cerné d'un trait épais sauf vers Nieul.
    "2": ["Saint-Junien", "Rochechouart", "Saint-Laurent", "Aixe-sur-Vienne",
          "Oradour-sur-Vayres", "Saint-Mathieu", "Châlus", "Nexon",
          "Pierre-Buffière", "Saint-Germain-les-Belles", "Saint-Yrieix"],
    "3": ["Saint-Sulpice", "Le Dorat", "Magnac-Laval", "Mézières", "Bellac",
          "Châteauponsac", "Bessines-sur-Gartempe", "Laurière", "Nantiat",
          "Ambazac", "Nieul", "Limoges-Ouest"]}},

"88": {"nom": "Vosges", "photo": 123, "depuis": 1958, "jusqu": 1986, "circos": {
    "1": ["Charmes", "Châtel-sur-Moselle", "Rambervillers", "Bruyères",
          "Épinal"],
    "2": ["Raon-l'Étape", "Senones", "Provenchères", "Saint-Dié",
          "Brouvelieures", "Corcieux", "Fraize"],
    "3": ["Xertigny", "Bains", "Remiremont", "Gérardmer", "Plombières",
          "Saulxures", "Le Thillot"],
    "4": ["Coussey", "Neufchâteau", "Châtenois", "Mirecourt", "Vittel",
          "Dompaire", "Bulgnéville", "Darney", "Lamarche", "Monthureux"]}},

"89": {"nom": "Yonne", "photo": 125, "depuis": 1958, "jusqu": 1986, "circos": {
    # Une flèche, au sud de Courson, désigne un fragment de
    # Coulanges-sur-Yonne à l'ouest du trait : à relire sur l'original.
    "1": ["Charny", "Aillant", "Bléneau", "Toucy", "Auxerre-Ouest",
          "Auxerre-Est", "Saint-Fargeau", "Saint-Sauveur", "Courson",
          "Coulanges-la-Vineuse"],
    # Seignelay : le trait le contourne par l'ouest, il tient à Ligny.
    "2": ["Saint-Florentin", "Flogny", "Seignelay", "Ligny-le-Châtel",
          "Tonnerre", "Cruzy", "Chablis", "Ancy-le-Franc", "Noyers",
          "Vermenton", "L'Isle-sur-Serein", "Coulanges-sur-Yonne", "Guillon",
          "Vézelay", "Avallon", "Quarré"],
    "3": ["Sergines", "Pont-sur-Yonne", "Villeneuve-l'Archevêque", "Chéroy",
          "Sens-Nord", "Sens-Sud", "Cerisiers", "Villeneuve-sur-Yonne",
          "Brienon", "Saint-Julien-du-Sault", "Joigny"]}},

"90": {"nom": "Territoire de Belfort", "photo": 127, "depuis": 1958, "jusqu": 1986, "circos": {
    # Note de l'atlas : « le canton de Belfort était divisé : les communes de
    # Bavilliers, Cravanche, Essert et Salbert étaient rattachées à la 2e
    # circonscription, tandis que les autres communes constituaient la 1re ».
    "1": ["reste:Belfort"],
    "2": ["Giromagny", "Rougemont-le-Château", "Fontaine", "Delle",
          "communes:Belfort:Bavilliers,Cravanche,Essert,Salbert"]}},

# Seine-et-Oise, 1958-1967 (photo 107) : dix-huit circonscriptions.
# Lecture du 24 octobre 2026 (Claude), à l'agrandissement (photo tournée de
# 90°, `convert -rotate -90 -crop`), canton par canton ; les NOTES de la
# planche donnent les six cantons divisés. Confrontée à la page Wikipédia
# « Liste des circonscriptions législatives de Seine-et-Oise » (qui cite
# l'ordonnance n° 58-945) : mêmes dix-huit compositions, à une graphie près —
# elle met « Sarcelles » dans la 10e, canton qui n'existe qu'en 1964 ; la carte
# y met GONESSE (traits fins vers Écouen et Luzarches, trait épais vers
# Aulnay). Les cantons divisés se lisent commune par commune
# (`composition_1958.py`, COMMUNES) : jetons « communes:<canton>:<communes> »
# et « reste:<canton> ».
# Bornes : la carte dit 1958-1967 ; la loi du 12 juillet 1966 a joué aux
# législatives de mars 1967, mais la base garde la Seine de 1958 jusqu'au
# 1er janvier 1968 (`88`) et pose les circonscriptions de 1967 des 92, 93 et
# 94 à partir de cette date (`125`) : « jusqu » 1968, pour s'y raccorder.
"78": {"nom": "Seine-et-Oise", "photo": 107, "depuis": 1958, "jusqu": 1968, "circos": {
    # « le canton d'Argenteuil était divisé : les communes d'Argenteuil,
    #   Bezons et Sannois formaient la 1re ; le reste du canton était
    #   rattaché à la 2e »
    "1": ["communes:Argenteuil:Argenteuil,Bezons,Sannois"],
    "2": ["Maisons-Laffitte", "reste:Argenteuil"],
    # « le canton de Marly était divisé : la commune de Rueil appartenait à
    #   la 3e ; le reste du canton était rattaché à la 5e »
    "3": ["Saint-Germain-en-Laye", "communes:Marly:Rueil"],
    # « le canton de Versailles-Ouest était divisé : la partie de la ville de
    #   Versailles appartenant à ce canton et la commune du Chesnay étaient
    #   rattachées à la 4e ; le reste était inclus dans la 5e ». La flèche
    #   du 4 vise Sèvres ; celle du 5, Versailles-Nord.
    "4": ["Sèvres", "communes:Versailles-Ouest:Versailles,Le Chesnay"],
    "5": ["reste:Marly", "reste:Versailles-Ouest", "Versailles-Nord"],
    "6": ["Palaiseau", "Versailles-Sud"],
    "7": ["Meulan", "Poissy"],
    "8": ["L'Isle-Adam", "Marines", "Pontoise"],
    "9": ["Aulnay-sous-Bois"],
    "10": ["Écouen", "Gonesse", "Luzarches"],
    "11": ["Le Raincy"],
    "12": ["Montmorency", "Taverny"],
    # « le canton de Corbeil était divisé : les communes de Corbeil, Étiolles,
    #   Morsang, Saint-Germain, Saint-Pierre, Saintry, Soisy et Tigery étaient
    #   rattachées à la 13e ; le reste était inclus dans la 14e »
    # « le canton de Villeneuve-Saint-Georges était divisé : les communes de
    #   Valenton et Villeneuve appartenaient à la 16e ; le reste à la 13e »
    "13": ["communes:Corbeil:Corbeil,Étiolles,Morsang,Saint-Germain,"
           "Saint-Pierre,Saintry,Soisy,Tigery", "reste:Villeneuve-Saint-Georges"],
    # Arpajon : trait fin vers La Ferté-Alais, épais vers Longjumeau et Limours.
    "14": ["reste:Corbeil", "Arpajon", "Étampes", "La Ferté-Alais", "Milly",
           "Méréville"],
    # « le canton de Longjumeau était divisé : les communes d'Ablon et
    #   Villeneuve-le-Roi appartenaient à la 16e ; le reste constituait la 15e »
    "15": ["reste:Longjumeau"],
    "16": ["Boissy-Saint-Léger",
           "communes:Villeneuve-Saint-Georges:Valenton,Villeneuve",
           "communes:Longjumeau:Ablon,Villeneuve-le-Roi"],
    "17": ["Chevreuse", "Dourdan-Nord", "Dourdan-Sud", "Limours",
           "Montfort-l'Amaury", "Rambouillet"],
    "18": ["Magny", "Bonnières", "Limay", "Mantes", "Houdan"]}},

}

# Non transcrit de cette série : Jura (39) et Haute-Saône (70), dont la carte
# de 1958 n'est pas parmi les photos ; les découpages de 1967 de l'Essonne,
# des Hauts-de-Seine, de la Seine-Saint-Denis, du Val-de-Marne, du Val-d'Oise
# et des Yvelines (photos 108, 128 à 133), dont le fond est communal ;
# l'outre-mer (photos 134 à 139) ; et toutes les cartes « 1986 », que la base
# tient déjà du tableau officiel.
