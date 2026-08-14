# Annexe VI de Gaudillère — ce qu'elle contient, et ce qu'elle ne contient pas

*Atlas historique des circonscriptions électorales françaises*, annexe VI,
p. 781-786 : **Particularités de diverses circonscriptions**.

## Le renvoi de la page 828 est faux

La méthodologie cartographique annonce : « les lois et décrets créant de
nouveaux cantons après 1801-1802. On en trouvera la liste exhaustive à
l'annexe VI. »

**Cette liste n'y est pas.** L'annexe VI traite des particularités des
circonscriptions, en sept sections, dont aucune n'énumère de décrets cantonaux.

Reste à chercher dans les autres annexes. Cette liste vaudrait cher : elle
donnerait aux démembrements du registre des dates d'acte là où ils portent des
intervalles de vingt-huit ans.

## Ce qu'elle contient, et ce que chaque section teste

Toutes ces sections ont la même vertu : ce sont des **assertions falsifiables
établies par un tiers** sur la couche circonscriptions — qui n'avait jusqu'ici
pour tout contrôle externe que les sept arrondissements de Marseille.

### § 1 — Circonscriptions scindées

Circonscriptions où « le législateur a délibérément réuni des cantons non
contigus ». L'auteur exclut les discontinuités dues aux enclaves.

**Ce que ça teste** : nos polygones de circonscription doivent être en
plusieurs morceaux **exactement là** et nulle part ailleurs, une fois retirées
les enclaves. Un `ST_NumGeometries > 1` hors de cette liste signale un défaut ;
un `= 1` sur un membre de la liste aussi.

Pour la période couverte : 1ʳᵉ Bouches-du-Rhône (1863-1869), Chartres-2
(1876-1885 ; 1889-1919), Toulouse-3 (1876-1885 ; 1889-1919 ; 1928-1940),
Lorient-1 en trois tronçons (1876-1885), Douai-2, Autun-1, Limoges-2,
Bordeaux-5, Bayonne-2, Lille-4 (1889-1919), Aix-1, Dijon-2, Béziers-2,
Forbach, Clermont-Ferrand-1 (1928-1940), 3ᵉ et 8ᵉ Bouches-du-Rhône
(1958-1986), 6ᵉ Moselle, 7ᵉ Rhône, 4ᵉ Charente-Maritime.

### § 3 et § 4 — Circonscriptions monocantonales et monocommunales

Circonscriptions couvrant un canton unique, ou une commune unique.

**Ce que ça teste** : la composition de ces circonscriptions dans notre couche
doit se réduire à une unité. Facile, direct, et sans ambiguïté.

### § 5 — Cantons divisés — **le plus utile**

Cantons répartis entre deux ou plusieurs circonscriptions. Notre modèle suppose
qu'une circonscription est une union de cantons **entiers** ; cette liste dit
où cette règle est violée.

Exclusions déclarées par l'auteur : Paris, petite couronne, Lyon, Marseille.

Pour le découpage de 1986 — transcrit depuis photographie, **à vérifier sur
l'original** : Mas-Cabardès (Aude, 1985), Istres et Salon-de-Provence
(Bouches-du-Rhône), Lisieux-1 (Calvados), Saintes-Est (Charente-Maritime),
Loriol-sur-Drôme (Drôme), Muret (Haute-Garonne), Houdain (Pas-de-Calais,
1958-1986).

Testé par `sql/36_recette_annexe_vi.sql`.

**Concordance déjà acquise** : `30_stabilite_cantonale.sql` avait trouvé quatre
cantons éclatés en Bouches-du-Rhône, dont Istres et Salon-de-Provence — les
deux que l'annexe annonce, les autres étant marseillais donc exclus.

### § 6 — Villes divisées

98 villes dont le territoire a été réparti entre plusieurs circonscriptions,
avec une matrice par découpage. Les totaux :

| découpage | 1815 | 1820 | 1831 | 1852 | 1857 | 1862 | 1867 | 1875 | 1889 | 1927 | 1958 | 1986 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| villes divisées | 1 | 4 | 12 | 9 | 10 | 12 | 14 | 19 | 22 | 41 | 43 | 81 |

**Ce que ça teste** : le nombre de communes appartenant à plusieurs
circonscriptions à chaque découpage. C'est une mesure globale, comparable
directement à ce que produit notre couche — et la courbe elle-même est
significative : la division des villes double entre 1889 et 1927, puis double
encore en 1986.

### § 7 — Circonscriptions de 1986 reprises de 1981

Le découpage de 1986 a repris sans changement **57 circonscriptions** parmi
celles en vigueur aux législatives de 1981 (Métropole), énumérées.

**Ce que ça vaut** : c'est une passerelle vers le découpage de 1958-1986, qu'on
n'a pas. Pour ces 57 circonscriptions, la géométrie de 1986 vaut aussi pour
1981 — et donc, en remontant, pour tout l'intervalle où elles n'ont pas bougé.

C'est le même mécanisme que les lignes `stabilite` du registre cantonal :
l'absence de changement, déclarée par une source, autorise à projeter.
