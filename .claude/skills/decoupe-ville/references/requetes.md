# Requêtes de la découpe — à adapter, pas à recopier aveuglément

Toutes supposent `SET search_path TO histgis, public;` et Lambert 93 (EPSG:2154). Les variables
`:'w'` (WKT), `:'insee'`… se passent par `psql -v w="$(cat ligne.wkt)" <<'SQL' … SQL` : psql
n'interpole les variables que dans une entrée lue (stdin, `-f`), jamais dans `-c`.

Pour Marseille, Lyon et Paris, remplacer tout `code_insee = :'insee'` sur `iris_ville` par
`code_insee LIKE '132%'`, `'693%'`, `'751%'` (arrondissements).

## § 1. Les fractions d'une ville, leurs cantons, leurs périodes

```sql
SELECT a.atom_id, m.unit_id, coalesce(uv.nom, u.nom) AS canton,
       m.valid_from, m.valid_to, g.source
  FROM atom a JOIN atom_geom g USING (atom_id)
  LEFT JOIN membership m ON m.atom_id = a.atom_id AND m.niveau = 'canton'
  LEFT JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = 'canton'
  LEFT JOIN unit_version uv ON uv.unit_id = m.unit_id AND uv.periode && m.periode
 WHERE a.insee_geofla = :'insee'
 ORDER BY a.atom_id, m.valid_from;
```

Lire : quelles fractions coexistent à quelles dates (le nombre de morceaux attendu), et les noms
(Nord/Sud/Est/Ouest) pour les ancres. `source = 'fraction_cog'` = fraction posée après 1943.

## § 2. Où tombent les bouts de la ligne

```sql
WITH t AS (SELECT ST_SetSRID(ST_GeomFromText(:'w'), 2154) g),
     c AS (SELECT cible_ville(:'insee', :'d'::date) g)
SELECT round(ST_Distance(ST_StartPoint((SELECT g FROM t)), ST_Boundary((SELECT g FROM c)))::numeric) AS debut_au_bord_m,
       round(ST_Distance(ST_EndPoint((SELECT g FROM t)),   ST_Boundary((SELECT g FROM c)))::numeric) AS fin_au_bord_m;
```

0 à quelques dizaines de mètres : le raccord de `98` suffit. Des centaines : le texte s'arrête
avant le bord (voir § 3 et § 4, ou demander).

## § 3. La ligne du texte suit-elle une limite d'IRIS ?

```sql
WITH t AS (SELECT ST_SetSRID(ST_GeomFromText(:'w'), 2154) g),
     ir AS (SELECT ST_UnaryUnion(ST_Collect(geom)) u, ST_Union(ST_Boundary(geom)) b
              FROM iris_ville WHERE code_insee = :'insee'),
     interne AS (SELECT ST_Difference((SELECT b FROM ir),
                          ST_Buffer(ST_Boundary((SELECT u FROM ir)), 2)) g)
SELECT round((100 * ST_Length(ST_Intersection((SELECT g FROM t),
              ST_Buffer((SELECT g FROM interne), 15))) / ST_Length((SELECT g FROM t)))::numeric, 1)
       AS pct_a_15m_d_une_limite_iris;
```

Repères : Vienne 72 %, Moulins 14 %. Pour localiser les tronçons qui divergent d'une limite IRIS
donnée `:'l'` (et de combien, point par point — ne pas utiliser `ST_MaxDistance`, qui mesure au
point le plus éloigné de toute la ligne de référence) :

```sql
WITH t AS (SELECT ST_SetSRID(ST_GeomFromText(:'w'), 2154) g),
     r AS (SELECT ST_SetSRID(ST_GeomFromText(:'l'), 2154) g),
     hors AS (SELECT (ST_Dump(ST_LineMerge(ST_Difference((SELECT g FROM t),
                ST_Buffer((SELECT g FROM r), 15))))).geom g),
     v AS (SELECT h.g, (ST_DumpPoints(ST_Segmentize(h.g, 5))).geom p FROM hors h WHERE ST_Length(h.g) > 5)
SELECT round(ST_Length(g)::numeric) m,
       round(max(ST_Distance(p, (SELECT g FROM r)))::numeric) ecart_max_m,
       round(avg(ST_Distance(p, (SELECT g FROM r)))::numeric) ecart_moyen_m
  FROM v GROUP BY g ORDER BY 1 DESC;
```

## § 4. Prolonger un texte urbain par une limite d'IRIS (Vienne)

Seulement si le § 3 montre un accord net. La limite IRIS se construit comme frontière entre deux
groupes d'IRIS ; à Vienne, les grands quartiers (7ᵉ chiffre du code) 3-4 contre 1-2 :

```sql
WITH g AS (SELECT CASE WHEN substr(code_iris, 7, 1) IN ('3', '4') THEN 'a' ELSE 'b' END grp,
                  ST_UnaryUnion(ST_Collect(geom)) geom
             FROM iris_ville WHERE code_insee = :'insee' GROUP BY 1)
SELECT ST_AsText(ST_LineMerge(ST_Intersection((SELECT geom FROM g WHERE grp = 'a'),
                                              (SELECT geom FROM g WHERE grp = 'b'))));
```

Puis composer : limite IRIS jusqu'au point où le texte la rejoint, texte, limite IRIS au-delà. La
requête de Vienne (paramètres `:'w'` texte, `:'l'` limite IRIS) :

```sql
WITH t0 AS (SELECT ST_SetSRID(ST_GeomFromText(:'w'), 2154) g),
     b  AS (SELECT ST_SetSRID(ST_GeomFromText(:'l'), 2154) g),
     t AS (SELECT (SELECT g FROM t0) g),   -- ou ST_LineSubstring pour partir d'un point du texte
     loc AS (SELECT ST_LineLocatePoint((SELECT g FROM b), ST_StartPoint((SELECT g FROM t))) fs,
                    ST_LineLocatePoint((SELECT g FROM b), ST_EndPoint((SELECT g FROM t))) fe),
     avant AS (SELECT CASE WHEN fs > fe THEN ST_Reverse(ST_LineSubstring((SELECT g FROM b), fs, 1))
                           ELSE ST_LineSubstring((SELECT g FROM b), 0, fs) END g FROM loc),
     apres AS (SELECT CASE WHEN fs > fe THEN ST_Reverse(ST_LineSubstring((SELECT g FROM b), 0, fe))
                           ELSE ST_LineSubstring((SELECT g FROM b), fe, 1) END g FROM loc)
SELECT ST_AsText(ST_SnapToGrid(ST_RemoveRepeatedPoints(ST_MakeLine(ARRAY(
         SELECT (dp).geom FROM (
             SELECT 1 k, ST_DumpPoints((SELECT g FROM avant)) dp
             UNION ALL SELECT 2, ST_DumpPoints((SELECT g FROM t))
             UNION ALL SELECT 3, ST_DumpPoints((SELECT g FROM apres))) z
         ORDER BY k, (dp).path[1])), 0.01), 0.01));
```

Vérifier `ST_IsSimple` : une jonction peut faire un zigzag de quelques mètres (Vienne : 30 m à la
porte de la rue Pipet). Le localiser (`ST_DumpSegments`, segments non adjacents qui se coupent) et
retirer les sommets de la boucle (`ST_RemovePoint`).

Si le début du texte est une voie choisie par défaut sur toute sa longueur (le « premier élément
entier » de `trace()`), regarder où la limite IRIS la quitte : à Vienne, c'est ce point qui a
localisé « la porte de la rue Pipet », 265 m avant le sommet de la rue.

## § 5. Montrer le résultat

```bash
S=/tmp/…   # le scratchpad de la session
ogr2ogr -f GeoJSON $S/<insee>_fractions.geojson PG:"dbname=histgis" \
  -sql "SELECT atom_id, geom FROM histgis.carte_coupe_ville('<insee>'::text, '<date>'::date)"
ogr2ogr -f GeoJSON $S/<insee>_ligne.geojson PG:"dbname=histgis" \
  -sql "SELECT coupe_id, geom FROM histgis.coupe_ville WHERE insee = '<insee>'"
```

Dans QGIS : fractions en `QgsCategorizedSymbolRenderer` sur `atom_id` (opacité 0,35–0,45),
tronçons en gris fin, voies du texte en rouge par règle `"nom_voie_ban" IN (…)`, ligne en noir.
Masquer les couches des villes précédentes. Cadrer sur l'emprise des fractions, attendre quelques
secondes, capturer (`get_canvas_screenshot`, ou `pont_qgis.appel('get_canvas_screenshot')` qui
rend `base64_data` à écrire en PNG).

## § 6. Deux cantons soudés : dans quel morceau tombe chaque canton ?

Quand `pose_coupe.py` rend un morceau de moins que de fractions, poser un point connu dans chaque
canton attendu (une place, un quartier que le texte attribue sans ambiguïté) et demander à quel
morceau il appartient. La paire de cantons qui partage un morceau désigne la ligne — ou la jonction
entre deux lignes — qui fuit. Même découpe que `carte_coupe_ville()` : raccord, puis calage à 1 m.

```sql
WITH cible AS (SELECT cible_ville(:'insee', :'d'::date) g),
     bord AS (SELECT ST_Boundary((SELECT g FROM cible)) g),
     t(cid, g) AS (VALUES ('L1', ST_SetSRID(ST_GeomFromText(:'w1'), 2154)),
                          ('L2', ST_SetSRID(ST_GeomFromText(:'w2'), 2154))),       -- etc.
     ref AS (SELECT cid, ST_Union((SELECT g FROM bord),
                 (SELECT ST_Union(o.g) FROM t o WHERE o.cid <> t.cid)) r FROM t),
     lames AS (SELECT ST_Snap(raccorde_ligne(t.g, ref.r), ref.r, 1.0) g FROM t JOIN ref USING (cid)),
     mo AS (SELECT (ST_Dump(ST_Polygonize(ST_Node(ST_Union((SELECT g FROM bord),
              (SELECT ST_Union(g) FROM lames)))))).geom g),
     p(nom, x, y) AS (VALUES ('Villers-Semeuse', 825900, 6963700), ('Mézières-Est', 824300, 6962300))
SELECT p.nom, (SELECT round((ST_Area(g) / 1e4)::numeric) FROM mo
                WHERE ST_Contains(g, ST_SetSRID(ST_MakePoint(p.x, p.y), 2154)) LIMIT 1) AS ha_du_morceau
  FROM p;
```

À Charleville-Mézières, Villers-Semeuse et Mézières-Est tombaient dans le même morceau de 915 ha :
L4 partait à une fraction de millimètre de L3, et son prolongement longeait L3 au lieu de la
couper. Le calage `ST_Snap` à 1 m l'a refermée.

## § 7. Les communes de banlieue de chaque canton, et celles qui touchent la ville

Pour attribuer des cantons numérotés, et pour le contrôle final (chaque morceau doit toucher des
communes de son canton). `:'u'` = la liste des unit_id, `:'d'` une date du régime.

```sql
WITH c AS (SELECT cible_ville(:'insee', :'d'::date) g)
SELECT m.unit_id, coalesce(uv.nom, u.nom) AS canton,
       string_agg(n.nom, ', ' ORDER BY n.nom)
         FILTER (WHERE ST_DWithin(coalesce(r.geom, g.geom), (SELECT g FROM c), 1)) AS voisines_de_la_ville
  FROM membership m JOIN atom a USING (atom_id) JOIN atom_geom g USING (atom_id)
  LEFT JOIN atom_geom_anr r ON r.atom_id = a.atom_id AND r.periode @> :'d'::date
  LEFT JOIN noms_geofla n ON n.insee = a.insee_geofla
  LEFT JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = 'canton'
  LEFT JOIN unit_version uv ON uv.unit_id = m.unit_id AND uv.periode @> :'d'::date
 WHERE m.niveau = 'canton' AND m.unit_id = ANY (string_to_array(:'u', ','))
   AND m.periode @> :'d'::date AND a.insee_geofla <> :'insee'
 GROUP BY 1, 2 ORDER BY 1;
```

Le point triple de deux voisines sur le bord (Troyes : Sainte-Savine et Saint-André-les-Vergers) :

```sql
WITH v AS (SELECT n.nom, ST_UnaryUnion(ST_Collect(coalesce(r.geom, ag.geom))) geom
             FROM atom a JOIN atom_geom ag USING (atom_id)
             LEFT JOIN atom_geom_anr r ON r.atom_id = a.atom_id AND r.periode @> :'d'::date
             JOIN noms_geofla n ON n.insee = a.insee_geofla
            WHERE n.nom IN (:'v1', :'v2') GROUP BY 1),
     t AS (SELECT ST_Boundary(cible_ville(:'insee', :'d'::date)) g),
     x AS (SELECT (ST_Dump(ST_Intersection(ST_Buffer((SELECT geom FROM v WHERE nom = :'v1'), 2),
                                           ST_Buffer((SELECT geom FROM v WHERE nom = :'v2'), 2)))).geom p)
SELECT ST_X(ST_ClosestPoint((SELECT g FROM t), ST_Centroid(p))), ST_Y(ST_ClosestPoint((SELECT g FROM t), ST_Centroid(p)))
  FROM x ORDER BY ST_Distance(p, (SELECT g FROM t)) LIMIT 1;
```
