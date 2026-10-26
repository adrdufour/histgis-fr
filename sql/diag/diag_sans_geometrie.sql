-- ============================================================================
-- histgis — diag_sans_geometrie.sql : les 318 atomes « que rien ne dessine »,
--                                     et l'unique échec de la règle de reprise
--
--     psql -d histgis -v date=1870-12-01 -f sql/diag/diag_sans_geometrie.sql
--     psql -d histgis -f sql/diag/diag_sans_geometrie.sql       # 1870-12-01 par défaut
--
-- LECTURE SEULE, comme tous les `diag_*.sql` du dépôt.
--
-- ============================================================================
-- CE QUE LE PREMIER PASSAGE A RENDU, LE 5 SEPTEMBRE 2026 : ZÉRO LIGNE
-- ============================================================================
-- Les §§ 1 à 5 cherchent les atomes vivants à la date qui n'ont NI polygone
-- dans `atom_geom`, NI polygone ANR à cette date — donc aucune des trois
-- sources de `84`, la reprise exigeant elle-même un repli (`manquant` joint
-- `atom_geom`). **Ils rendent zéro ligne.**
--
-- C'est un résultat, et il renverse la lecture du point 0 bis :
--
--     À 1870-12-01, AUCUN atome vivant n'est privé de géométrie.
--
-- Les 318 atomes du § 8 de `diag_partition.sql` ne sont donc PAS des atomes
-- sans géométrie. Ce sont des atomes **que `carte_partition_atome` ne rend
-- pas** — ce qui n'est pas la même chose, et le § 8 le disait pourtant en
-- toutes lettres : *« Ce ne sont pas des trous ouverts par 84 — ils manquaient
-- déjà »*. **Cette phrase est fausse**, et c'est le premier acquis de ce
-- fichier. Ils ont tous de quoi être dessinés ; c'est l'arbitrage qui ne leur
-- laisse rien.
--
-- *Une population définie par « absente du résultat d'une fonction » n'est pas
-- la même que celle définie par « absente des tables que la fonction lit ».
-- Les deux se décrivent par la même phrase française, et c'est tout le piège.*
--
-- OÙ ILS SE PERDENT, ET COMMENT LE VÉRIFIER. `partition_un_dep` finit par
-- `t84_src JOIN t84_prop ON empreinte JOIN net ON pid` : un atome ne ressort
-- que si SON propriétaire a gagné au moins une face au § (d). Or l'arbitrage
-- donne chaque face à un seul propriétaire, dans l'ordre `est_repli`, `aire`,
-- `pid` — un polygone entièrement recouvert par un autre mieux classé perd
-- toutes ses faces et disparaît. C'est le cas attendu d'une fille reportée en
-- arrière par `11`, dont le repli GEOFLA se superpose au polygone ANR de sa
-- mère intacte : les 393 superpositions franches que `84` documente en tête.
--
-- **La question à poser n'est donc plus « pourquoi n'ont-ils pas de
-- géométrie ? » mais « à qui leur sol a-t-il été donné ? »**, et elle ne se
-- pose qu'à la partition elle-même. Le § 6 donne la requête, à lancer dans une
-- session où `diag_partition.sql` a déjà matérialisé `d84` — sans quoi il faut
-- payer plusieurs minutes de treillis pour chaque question.
--
-- ============================================================================
-- CE QUI RESTE VRAI DES §§ 1 À 5, ET POURQUOI ILS RESTENT DANS LE FICHIER
-- ============================================================================
-- Un zéro n'est un résultat que s'il peut cesser d'en être un. Ces requêtes
-- valent contrôle permanent : à une autre date, ou après un chargement, elles
-- rendront des lignes si une source vient à manquer pour de bon, et le § 2
-- dira alors laquelle des deux causes est en jeu.
--
-- Elles écartent aussi, définitivement, l'hypothèse qui figurait dans
-- `RESTE_A_FAIRE.md` : « `05_geom.sql` donne à chaque atome-fraction le
-- polygone de sa commune-mère, et ceux-là ne l'ont pas reçu ». Les deux
-- moitiés sont fausses :
--
--   1. `05_geom.sql` NE CONNAÎT PAS LES FRACTIONS. Il ne cherche aucune mère :
--      sa première insertion joint `atom.insee_geofla` à
--      `geofla_commune.insee_com` pour tous les atomes indistinctement. Une
--      fraction reçoit le polygone de sa commune parce qu'elle PORTE LE MÊME
--      CODE INSEE. Le mot « mère » n'apparaît pas dans le fichier.
--   2. LE CODE INSEE NE MANQUE À AUCUNE FRACTION. Relevé sur `build/atom.csv` :
--      **333 lignes portent un `#`, les 333 portent un code INSEE** au format
--      attendu par le `CASE` du § 3 de `02_load.sql` — aucune vide, aucune
--      valant 1, 2 ou 3, les valeurs de `com_act` qui partagent la colonne et
--      auraient laissé `insee_geofla` à NULL.
--
-- Le zéro du § 1 les confirme toutes deux par la mesure.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\if :{?date}
\else
    \set date '1870-12-01'
\endif

\echo ''
\echo '=== Les atomes vivants privés de TOUTE géométrie, au' :date '=========='
\echo '    Mesuré à 0 le 5 septembre 2026. Un chiffre non nul ici serait une'
\echo '    régression de chargement, pas une limite de 84.'

-- ---------------------------------------------------------------------------
-- La population. Ni `atom_geom`, ni `atom_geom_anr` à la date : aucune des
-- trois sources de `84`, la reprise exigeant elle-même un repli. Inutile de
-- recalculer le treillis pour le savoir — quelques secondes contre plusieurs
-- minutes.
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS d_muet;
CREATE TEMP TABLE d_muet AS
SELECT a.atom_id,
       a.cassini,
       a.fraction,
       a.insee_geofla,
       (SELECT min(u.dep)
          FROM   membership m
          JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
         WHERE  m.atom_id = a.atom_id
           AND  m.periode @> :'date'::date)                       AS dep,
       EXISTS (SELECT 1 FROM geofla_commune g
                WHERE g.insee_com = a.insee_geofla)               AS geofla_a_le_polygone,
       EXISTS (SELECT 1 FROM diag_geom_correspondance d
                WHERE d.insee = a.insee_geofla)                   AS correspondance_declaree,
       EXISTS (SELECT 1 FROM atom_geom_anr g
                WHERE g.atom_id = a.atom_id)                      AS anr_le_connait_ailleurs
FROM   atom a
WHERE  EXISTS (SELECT 1 FROM membership m
                WHERE m.atom_id = a.atom_id AND m.periode @> :'date'::date)
  AND  NOT EXISTS (SELECT 1 FROM atom_geom ag WHERE ag.atom_id = a.atom_id)
  AND  NOT EXISTS (SELECT 1 FROM atom_geom_anr g
                    WHERE g.atom_id = a.atom_id AND g.periode @> :'date'::date);

CREATE INDEX ON d_muet (atom_id);
ANALYZE d_muet;

\echo ''
\echo '--- 1. Le compte, fractions et non-fractions séparées ------------------'
\echo ''

SELECT coalesce(CASE WHEN fraction THEN 'fraction' ELSE 'commune entière' END,
                'aucun') AS quoi,
       count(*)                                                      AS atomes,
       count(DISTINCT dep)                                           AS departements,
       count(*) FILTER (WHERE insee_geofla IS NULL)                   AS sans_code_insee
FROM   d_muet
GROUP  BY 1
ORDER  BY 1;

\echo ''
\echo '--- 2. Si le § 1 cesse un jour d''être vide : chaîne ou source ? -------'
\echo '    « b » = son code a un polygone GEOFLA 2011 et il n''a pourtant pas'
\echo '    de ligne dans atom_geom : l''atome est né APRÈS l''étape 5, que rien'
\echo '    ne rejoue. Suspects nommés : 59_cog1968 et 68_cog1954, qui créent'
\echo '    des atomes-fractions et n''alimentent jamais atom_geom.'
\echo '    « d » = commune disparue avant 2011, hors correspondance : limite'
\echo '    de source, rien à réparer, à déclarer.'
\echo ''

SELECT CASE WHEN fraction THEN 'fraction' ELSE 'commune entière' END AS quoi,
       CASE
         WHEN insee_geofla IS NULL
              THEN 'a. aucun code INSEE — 05 ne pouvait pas joindre'
         WHEN geofla_a_le_polygone
              THEN 'b. DÉFAUT DE CHAÎNE — le polygone existe, 05 ne l''a pas vu'
         WHEN correspondance_declaree
              THEN 'c. correspondance déclarée et sans effet — à regarder'
         ELSE      'd. LIMITE DE SOURCE — disparue avant 2011, hors correspondance'
       END                                                           AS cause,
       count(*)                                                      AS atomes,
       count(*) FILTER (WHERE anr_le_connait_ailleurs)                AS dont_anr_ailleurs
FROM   d_muet
GROUP  BY 1, 2
ORDER  BY 1, 2;

\echo ''
\echo '--- 3. Contre-épreuve indépendante : la mère est-elle dessinée ? -------'
\echo '    Une fraction porte `cassini#canton` : sa mère est l''atome de MÊME'
\echo '    `cassini`. Mère dessinée et pas la fraction = la jointure par code'
\echo '    aurait suffi, donc 05 n''a pas vu la fraction.'
\echo ''

SELECT CASE WHEN mere.atom_id IS NOT NULL THEN 'la mère EST dessinée'
            ELSE                               'la mère non plus' END AS cas,
       count(*)                                                       AS fractions
FROM   d_muet d
LEFT   JOIN LATERAL (
           SELECT a2.atom_id
           FROM   atom a2
           JOIN   atom_geom ag ON ag.atom_id = a2.atom_id
           WHERE  a2.cassini = d.cassini
             AND  a2.atom_id <> d.atom_id
           ORDER  BY a2.fraction, a2.atom_id
           LIMIT  1) mere ON true
WHERE  d.fraction
GROUP  BY 1
ORDER  BY 2 DESC;

\echo ''
\echo '--- 4. Les villes concernées, s''il y en a -----------------------------'
\echo ''

SELECT d.dep, d.insee_geofla,
       coalesce(n.nom, g.nom_comm, '[' || d.insee_geofla || ']')      AS nom,
       count(*)                                                       AS fractions_muettes,
       bool_or(d.geofla_a_le_polygone)                                AS polygone_2011_existe
FROM   d_muet d
LEFT   JOIN noms_geofla n ON n.insee = d.insee_geofla
LEFT   JOIN geofla_commune g ON g.insee_com = d.insee_geofla
WHERE  d.fraction
GROUP  BY d.dep, d.insee_geofla, 3
ORDER  BY 4 DESC, 1, 3
LIMIT  25;

\echo ''
\echo '--- 5. Les non-fractions, nommées une par une --------------------------'
\echo ''

SELECT d.dep, d.atom_id, d.insee_geofla,
       coalesce(n.nom, g.nom_comm, '[' || coalesce(d.insee_geofla, '?') || ']') AS nom,
       d.geofla_a_le_polygone                                          AS geofla_2011,
       d.anr_le_connait_ailleurs                                       AS anr_a_une_autre_date
FROM   d_muet d
LEFT   JOIN noms_geofla n ON n.insee = d.insee_geofla
LEFT   JOIN geofla_commune g ON g.insee_com = d.insee_geofla
WHERE  NOT d.fraction
ORDER  BY d.dep, 4;

-- ============================================================================
-- § 6. LA VRAIE QUESTION DES 318 — À QUI LEUR SOL A-T-IL ÉTÉ DONNÉ ?
--
-- Elle ne se pose qu'à la partition, et la partition coûte des minutes. La
-- requête ci-dessous n'est donc PAS exécutée ici : elle est écrite pour être
-- collée dans une session où `diag_partition.sql` vient de tourner, `d84` y
-- étant encore vivante. *Ce qui coûte des minutes ne se demande pas une
-- question à la fois* — c'est la raison d'être de `diag_partition.sql`, et il
-- serait absurde de la contourner ici.
--
--   -- dans une session `psql -d histgis -f sql/diag/diag_partition.sql` :
--   WITH perdu AS (
--       SELECT m.atom_id, a.fraction, a.insee_geofla, min(u.dep) AS dep
--       FROM   histgis.membership m
--       JOIN   histgis.atom a ON a.atom_id = m.atom_id
--       JOIN   histgis.unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
--       WHERE  m.periode @> '1870-12-01'::date
--         AND  NOT EXISTS (SELECT 1 FROM d84 d WHERE d.atom_id = m.atom_id)
--       GROUP  BY 1, 2, 3
--   ),
--   -- le polygone que 84 AURAIT dessiné pour lui : ANR à la date, sinon repli
--   sien AS (
--       SELECT p.*, coalesce(
--                (SELECT g.geom FROM histgis.atom_geom_anr g
--                  WHERE g.atom_id = p.atom_id AND g.periode @> '1870-12-01'::date),
--                (SELECT ag.geom FROM histgis.atom_geom ag
--                  WHERE ag.atom_id = p.atom_id)) AS geom
--       FROM perdu p
--   )
--   SELECT s.dep, s.atom_id, s.fraction,
--          coalesce(n.nom, '[' || s.insee_geofla || ']')          AS nom,
--          round((ST_Area(s.geom) / 1e6)::numeric, 2)             AS km2_du_sien,
--          d.atom_id                                              AS sol_donne_a,
--          d.source, d.motif,
--          round((ST_Area(ST_Intersection(s.geom, d.geom)) / 1e6)::numeric, 2)
--                                                                 AS km2_repris
--   FROM   sien s
--   LEFT   JOIN histgis.noms_geofla n ON n.insee = s.insee_geofla
--   LEFT   JOIN LATERAL (
--          SELECT d.atom_id, d.geom, d.source, d.motif
--          FROM   d84 d
--          WHERE  d.geom && s.geom AND ST_Intersects(d.geom, s.geom)
--          ORDER  BY ST_Area(ST_Intersection(d.geom, s.geom)) DESC
--          LIMIT  1) d ON true
--   ORDER  BY 5 DESC
--   LIMIT  40;
--
-- CE QU'IL FAUT LIRE. Si `sol_donne_a` est presque toujours renseigné et que
-- `km2_repris` vaut à peu près `km2_du_sien`, alors ces atomes sont des
-- DOUBLONS géométriques absorbés par l'arbitrage — et le nombre 318 mesure la
-- superposition héritée de `11` et d'ANR, pas un trou. Si `sol_donne_a` est
-- souvent vide, c'est autre chose, et il faudra le nommer.
--
-- Dans le premier cas, **la carte n'a pas de trou** : ces atomes ne sont pas
-- absents du dessin, ils sont absents de la LÉGENDE — un canton qui les
-- comptait perd des communes à l'affichage sans perdre de surface. C'est la
-- distinction que `n_atomes` et l'emprise de `carte_partition` permettent de
-- trancher, et il vaut mieux la faire avant d'écrire un correctif.
-- ============================================================================

-- ============================================================================
-- § 7. LA GUÉRINIÈRE — LA CAUSE N'EST AUCUNE DES TROIS ATTENDUES
--
-- MESURÉ LE 5 SEPTEMBRE 2026 :
--
--   atome 16360, INSEE 85106, île de Noirmoutier.
--   ANR : une seule fenêtre, [1919-01-01, 2020-01-01), 7,803 km².
--   Y′ = 1919-01-01.
--   Deux voisins pourvus à 1870 que son repli touche :
--     25137 NOIRMOUTIER-EN-L'ILE — coupure en 1919-01-01, recouvre 7,485 km²
--     2612  BARBATRE            — pas de coupure en Y′, recouvre 0,000 km²
--
-- **Une mère existe ET se coupe exactement en Y′.** La règle de `84` § 4
-- aurait dû réussir, et l'hypothèse de `RESTE_A_FAIRE.md` — « formée en 1919
-- de DEUX communes-mères » — est doublement réfutée : il n'y a qu'une mère
-- candidate, et deux en auraient donné un départage, jamais un échec.
--
-- *Une explication qui prédit autre chose que ce qu'on voit n'est pas une
-- explication faible, c'est une explication réfutée.* Celle-ci l'est deux fois.
--
-- Ce qui reste, dans l'ordre où le § 7 les élimine :
--
--   δ  LA DIFFÉRENCE EST VIDE. `mere(1870) − mere(1919)` ne rend rien de
--      surfacique parce qu'ANR ne fait PAS rétrécir Noirmoutier en 1919 : la
--      coupure de sa chronologie existerait pour une autre raison (un
--      changement de limite ailleurs, une correction de trait de côte). Alors
--      la règle est SAINE et la source muette — c'est le suspect principal, et
--      ce serait la meilleure des nouvelles.
--   ε  L'ATOME N'EST PAS DANS `vivant`. Pas de membership au 1ᵉʳ décembre 1870,
--      donc jamais candidat à la reprise — et alors il ne devrait pas non plus
--      figurer dans la carte, ce que `ETAT.md` contredit.
--   ζ  IL EST FRACTION. `manquant` exclut `NOT v.fraction`. Peu probable pour
--      une commune insulaire, mais c'est une ligne de contrôle gratuite.
-- ============================================================================

\echo ''
\echo '=== 7. La Guérinière — la mère existe, alors pourquoi ? ================'
\echo ''
\echo '--- 7 a. les trois conditions d''entrée dans la reprise -----------------'
\echo '    `dans_vivant` et `pas_fraction` doivent valoir t, `anr_a_la_date` f.'
\echo ''

SELECT a.atom_id, a.fraction AS est_fraction,
       EXISTS (SELECT 1 FROM membership m
                WHERE m.atom_id = a.atom_id
                  AND m.periode @> :'date'::date)                    AS dans_vivant,
       EXISTS (SELECT 1 FROM atom_geom ag WHERE ag.atom_id = a.atom_id)
                                                                     AS a_un_repli,
       EXISTS (SELECT 1 FROM atom_geom_anr g
                WHERE g.atom_id = a.atom_id AND g.periode @> :'date'::date)
                                                                     AS anr_a_la_date,
       (SELECT min(u.dep) FROM membership m
          JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
         WHERE m.atom_id = a.atom_id AND m.periode @> :'date'::date)  AS dep
FROM   atom a WHERE a.insee_geofla = '85106';

\echo ''
\echo '--- 7 b. LA MESURE QUI TRANCHE : la mère rétrécit-elle en Y'' ? --------'
\echo '    `reste_km2` proche de 7,5 = la règle aurait dû rendre le territoire,'
\echo '    et il faut relire 84 § 4. `reste_km2` nul ou minuscule = cause δ :'
\echo '    ANR ne rétrécit pas Noirmoutier en 1919, la coupure de 1919 dit'
\echo '    autre chose, et la règle est saine.'
\echo ''

WITH moi AS (
    SELECT a.atom_id, ag.geom AS repli
    FROM   atom a JOIN atom_geom ag ON ag.atom_id = a.atom_id
    WHERE  a.insee_geofla = '85106'
),
y_prime AS (
    SELECT min(lower(g.periode)) AS d
    FROM   atom_geom_anr g JOIN moi ON moi.atom_id = g.atom_id
    WHERE  lower(g.periode) > :'date'::date
)
SELECT gb.atom_id                                                    AS mere,
       coalesce(n.nom, '[' || av.insee_geofla || ']')                 AS nom,
       (SELECT d FROM y_prime)                                       AS y_prime,
       round((ST_Area(gb.geom) / 1e6)::numeric, 3)                    AS mere_avant_km2,
       round((ST_Area(gm.geom) / 1e6)::numeric, 3)                    AS mere_apres_km2,
       round((ST_Area(ST_CollectionExtract(
                 ST_Difference(gb.geom, gm.geom), 3)) / 1e6)::numeric, 3)
                                                                     AS reste_km2,
       round((ST_Area(ST_Intersection(
                 ST_CollectionExtract(ST_Difference(gb.geom, gm.geom), 3),
                 moi.repli)) / 1e6)::numeric, 3)                      AS reste_sur_le_repli_km2
FROM   moi
JOIN   atom_geom_anr gb ON gb.periode @> :'date'::date
                       AND gb.atom_id <> moi.atom_id
                       AND ST_Intersects(gb.geom, moi.repli)
JOIN   atom_geom_anr gm ON gm.atom_id = gb.atom_id
                       AND lower(gm.periode) = (SELECT d FROM y_prime)
JOIN   atom av ON av.atom_id = gb.atom_id
LEFT   JOIN noms_geofla n ON n.insee = av.insee_geofla
ORDER  BY 6 DESC;

\echo ''
\echo '--- 7 c. la chronologie complète de la mère ----------------------------'
\echo '    Pour lire ce que la coupure de 1919 signifie chez ANR : une commune'
\echo '    qui perd 7 km² le montre dans ses aires successives, une commune'
\echo '    dont on a seulement retouché le trait de côte non.'
\echo ''

SELECT g.atom_id,
       coalesce(n.nom, '[' || a.insee_geofla || ']')                  AS nom,
       lower(g.periode)                                              AS debut,
       upper(g.periode)                                              AS fin,
       round((ST_Area(g.geom) / 1e6)::numeric, 3)                     AS km2
FROM   atom_geom_anr g
JOIN   atom a ON a.atom_id = g.atom_id
LEFT   JOIN noms_geofla n ON n.insee = a.insee_geofla
WHERE  a.insee_geofla IN ('85163', '85011', '85106')   -- Noirmoutier, Barbâtre, La Guérinière
ORDER  BY a.insee_geofla, lower(g.periode);

-- ============================================================================
-- § 7 d. LA CAUSE, TROUVÉE LE 5 SEPTEMBRE 2026 : UNE FRATRIE CONTIGUË
--
-- δ EST RÉFUTÉE À SON TOUR, et par les chiffres du § 7 b :
--
--     Noirmoutier-en-l'Île, chronologie ANR
--       1790 → 1858 ..... 49,573 km²
--       1858 → 1919 ..... 36,393 km²      ← `mere_avant`
--       1919 → 2020 ..... 19,967 km²      ← `mere_apres`
--     différence ........ 16,426 km², dont 7,485 sur le repli de La Guérinière
--
-- **La mère rétrécit bel et bien en 1919, de 16,4 km².** La règle avait tout ce
-- qu'il lui fallait. Ce n'est donc ni α, ni β, ni γ, ni δ.
--
-- Et 16,426 n'est pas 7,803 : la mère perd DEUX FOIS le territoire de La
-- Guérinière. Le reste va à **L'Épine** (INSEE 85083, atome 12753), détachée de
-- Noirmoutier le même millésime. Noirmoutier a deux filles en 1919, sur la même
-- île, et leurs territoires se touchent.
--
-- OÙ LA RÈGLE LÂCHE, EXACTEMENT. `partition_reprise` calcule un seul `reste`
-- par couple (mère, Y′), puis le déplie par `ST_Dump` et donne CHAQUE MORCEAU
-- à une seule fille (`DISTINCT ON (mo.mid)`, au recouvrement décroissant).
--
--     `ST_Dump` sépare les composantes DÉCONNECTÉES. Il ne partage pas un
--     polygone connexe entre deux prétendants.
--
-- Deux filles contiguës, un seul morceau : la première l'emporte et prend les
-- 16,4 km², **la seconde n'obtient rien** et retombe sur son repli GEOFLA.
-- C'est le symptôme observé, et il a un corollaire qui n'avait pas été vu :
-- **la fille servie est dessinée trop grande** — L'Épine reçoit ici près du
-- double de son territoire. Le treillis du § 5 de `84` achève le travail : le
-- repli de La Guérinière perd toutes ses faces contre un polygone de reprise,
-- que l'arbitrage classe avant lui (`est_repli` d'abord).
--
-- *Le compteur `fratrie` existait déjà et valait 2 sur ce couple. La règle
-- SAVAIT qu'elles étaient deux ; elle n'en tirait aucune conséquence.*
--
-- CE QUE CELA CHANGE POUR LE COMPTE DES 432 REPRISES. Les « 25 fratries » que
-- `84` annonce sont celles où le dépliage a suffi. Le § 7 d compte, sur toute
-- la France, celles où il ne suffit pas : autant de couples où une fille est
-- muette et sa sœur enflée. Tant que ce nombre n'est pas connu, l'angle mort
-- ne peut pas être déclaré « à 0,4 km² près ».
--
-- CE QU'IL NE FAUT PAS FAIRE. Partager un morceau connexe au prorata des
-- replis serait un ARBITRAGE, dans un algorithme dont l'en-tête revendique de
-- n'avoir aucun seuil, et il dessinerait une frontière qu'aucune source ne
-- porte — exactement ce que `84` refuse aux 333 fractions. La voie honnête est
-- de MESURER d'abord (§ 7 d), puis de décider en le disant.
-- ============================================================================

\echo ''
\echo '--- 7 d. la fratrie de 1919, et le morceau qu''elles se disputent -------'
\echo '    `filles` = combien d''atomes réapparaissent chez ANR au même'
\echo '    millésime en touchant la mère. `morceaux` = ce que ST_Dump sépare.'
\echo '    filles > morceaux ⇒ au moins une fille repart les mains vides.'
\echo ''

WITH mere AS (
    SELECT gb.atom_id, gb.geom AS avant, gm.geom AS apres,
           lower(gm.periode) AS y_prime
    FROM   atom_geom_anr gb
    JOIN   atom a ON a.atom_id = gb.atom_id AND a.insee_geofla = '85163'
    JOIN   atom_geom_anr gm ON gm.atom_id = gb.atom_id
                           AND lower(gm.periode) = DATE '1919-01-01'
    WHERE  gb.periode @> :'date'::date
),
reste AS (
    SELECT m.*, ST_CollectionExtract(ST_Difference(m.avant, m.apres), 3) AS g
    FROM   mere m
),
filles AS (
    SELECT f.atom_id, af.insee_geofla, ag.geom AS repli
    FROM   atom_geom_anr f
    JOIN   atom af ON af.atom_id = f.atom_id
    JOIN   atom_geom ag ON ag.atom_id = f.atom_id
    JOIN   reste r ON true
    WHERE  lower(f.periode) = r.y_prime
      AND  f.atom_id <> r.atom_id
      AND  ST_Intersects(ag.geom, r.avant)
      AND  NOT af.fraction
      AND  NOT EXISTS (SELECT 1 FROM atom_geom_anr g2
                        WHERE g2.atom_id = f.atom_id
                          AND g2.periode @> :'date'::date)
)
-- `round(((x) / 1e6)::numeric, 3)` et non `round(x / 1e6::numeric, 3)` :
-- `ST_Area` rend un `double precision`, et `double / numeric` reste un double,
-- pour lequel `round(v, n)` n'existe pas. La parenthèse doit englober la
-- division AVANT le cast. Erreur commise ici le 5 septembre 2026, et **que
-- l'analyse syntaxique par `pglast` ne pouvait pas voir** : la requête est
-- grammaticalement correcte, c'est la résolution de fonction qui échoue, et
-- elle demande le catalogue. *Un parseur valide la forme, pas les types ; il
-- ne remplace pas un passage en base, il réduit seulement le nombre de
-- passages nécessaires.*
SELECT (SELECT count(*) FROM filles)                                  AS filles,
       (SELECT count(*) FROM reste r, ST_Dump(r.g))                   AS morceaux,
       round(((SELECT ST_Area(g) FROM reste) / 1e6)::numeric, 3)      AS reste_km2,
       round(((SELECT sum(ST_Area(repli)) FROM filles) / 1e6)::numeric, 3)
                                                                      AS somme_replis_km2;

\echo ''
\echo '    Les filles, et ce que la règle donne à chacune :'
\echo ''

WITH mere AS (
    SELECT gb.atom_id, gb.geom AS avant, gm.geom AS apres
    FROM   atom_geom_anr gb
    JOIN   atom a ON a.atom_id = gb.atom_id AND a.insee_geofla = '85163'
    JOIN   atom_geom_anr gm ON gm.atom_id = gb.atom_id
                           AND lower(gm.periode) = DATE '1919-01-01'
    WHERE  gb.periode @> :'date'::date
),
morceau AS (
    SELECT row_number() OVER () AS mid, d.geom AS g
    FROM   mere m, ST_Dump(ST_CollectionExtract(
                               ST_Difference(m.avant, m.apres), 3)) d
),
filles AS (
    SELECT f.atom_id, af.insee_geofla, ag.geom AS repli
    FROM   atom_geom_anr f
    JOIN   atom af ON af.atom_id = f.atom_id
    JOIN   atom_geom ag ON ag.atom_id = f.atom_id
    JOIN   mere m ON true
    WHERE  lower(f.periode) = DATE '1919-01-01'
      AND  f.atom_id <> m.atom_id
      AND  ST_Intersects(ag.geom, m.avant)
      AND  NOT af.fraction
      AND  NOT EXISTS (SELECT 1 FROM atom_geom_anr g2
                        WHERE g2.atom_id = f.atom_id
                          AND g2.periode @> :'date'::date)
)
SELECT f.atom_id, coalesce(n.nom, '[' || f.insee_geofla || ']')        AS fille,
       round((ST_Area(f.repli) / 1e6)::numeric, 3)                     AS son_repli_km2,
       mo.mid                                                          AS morceau,
       round((ST_Area(ST_Intersection(f.repli, mo.g)) / 1e6)::numeric, 3)
                                                                       AS recouvre_km2,
       round((ST_Area(mo.g) / 1e6)::numeric, 3)                        AS morceau_km2,
       rank() OVER (PARTITION BY mo.mid
                    ORDER BY ST_Area(ST_Intersection(f.repli, mo.g)) DESC,
                             f.atom_id)                                AS rang,
       CASE WHEN rank() OVER (PARTITION BY mo.mid
                              ORDER BY ST_Area(ST_Intersection(f.repli, mo.g)) DESC,
                                       f.atom_id) = 1
            THEN 'PREND TOUT LE MORCEAU'
            ELSE 'REPART LES MAINS VIDES — reste en repli' END          AS verdict
FROM   filles f
CROSS  JOIN morceau mo
LEFT   JOIN noms_geofla n ON n.insee = f.insee_geofla
ORDER  BY mo.mid, 7;

\echo ''
\echo '--- 7 e. l''ampleur nationale : combien de fratries contiguës ? ---------'
\echo '    LECTURE SEULE et sans treillis, mais coûteuse (quelques minutes) :'
\echo '    elle balaie les couples (mère, millésime) où DEUX filles au moins'
\echo '    réapparaissent. `filles > morceaux` compte les cas perdants.'
\echo ''

-- `DISTINCT ON (gb.atom_id)` : Y′ est le PREMIER millésime postérieur, comme
-- dans `partition_reprise` (`min(lower(periode))`). Sans lui, une mère à cinq
-- fenêtres produirait quatre couples et autant de `ST_Difference` — quatre
-- fois le coût pour trois résultats qui ne décrivent aucune reprise.
WITH cand AS (
    SELECT DISTINCT ON (gb.atom_id)
           gb.atom_id                                  AS mere,
           lower(gm.periode)                           AS y_prime,
           ST_CollectionExtract(ST_Difference(gb.geom, gm.geom), 3) AS reste,
           gb.geom                                     AS avant
    FROM   atom_geom_anr gb
    JOIN   atom_geom_anr gm ON gm.atom_id = gb.atom_id
                           AND lower(gm.periode) > :'date'::date
    WHERE  gb.periode @> :'date'::date
    ORDER  BY gb.atom_id, lower(gm.periode)
),
compte AS (
    SELECT c.mere, c.y_prime,
           (SELECT count(*) FROM ST_Dump(c.reste))     AS morceaux,
           (SELECT count(*)
              FROM atom_geom_anr f
              JOIN atom af ON af.atom_id = f.atom_id AND NOT af.fraction
              JOIN atom_geom ag ON ag.atom_id = f.atom_id
             WHERE lower(f.periode) = c.y_prime
               AND f.atom_id <> c.mere
               AND ST_Intersects(ag.geom, c.avant)
               AND NOT EXISTS (SELECT 1 FROM atom_geom_anr g2
                                WHERE g2.atom_id = f.atom_id
                                  AND g2.periode @> :'date'::date)
               AND EXISTS (SELECT 1 FROM membership m
                            WHERE m.atom_id = f.atom_id
                              AND m.periode @> :'date'::date)) AS filles
    FROM   cand c
    WHERE  NOT ST_IsEmpty(c.reste)
)
SELECT CASE WHEN filles <= 1                THEN 'a. fille unique — sans objet'
            WHEN filles <= morceaux         THEN 'b. fratrie DÉCONNECTÉE — le dépliage suffit'
            ELSE                                 'c. FRATRIE CONTIGUË — au moins une fille muette'
       END                                                              AS cas,
       count(*)                                                         AS couples,
       sum(filles)                                                      AS filles_en_jeu,
       sum(greatest(filles - morceaux, 0))                              AS filles_perdantes
FROM   compte
GROUP  BY 1
ORDER  BY 1;

-- ============================================================================
-- § 7 f. LES NOMMER — ENTRE 1 ET 17 FILLES MUETTES, ET C'EST À TRANCHER
--
-- MESURÉ LE 5 SEPTEMBRE 2026, au 1ᵉʳ décembre 1870 :
--
--     a. fille unique ................ 1 361 couples ..  447 filles ..  0 perdue
--     b. fratrie DÉCONNECTÉE .........    11 couples ..   27 filles ..  0 perdue
--     c. FRATRIE CONTIGUË ............    14 couples ..   31 filles .. 17 perdues
--
-- Et sur le couple témoin, le mécanisme est nu :
--
--     L'Épine        repli 8,704 km²  recouvre 8,349  rang 1  PREND 16,426
--     La Guérinière  repli 7,918 km²  recouvre 7,485  rang 2  ne prend rien
--
-- La somme des deux replis vaut 16,622 pour un morceau de 16,426 : **les deux
-- filles font ensemble exactement ce que la mère a perdu.** La règle le voyait,
-- et donnait tout à une seule.
--
-- CE QUE 17 CONTREDIT, ET POURQUOI C'EST PROBABLEMENT MOI QUI AI TORT.
-- `ETAT.md` § 2.1 bis dénombre **84 replis résiduels** à cette date, dont
-- 54 fractions, 27 jamais pourvus par ANR, 2 pourvus avant 1870 seulement, et
-- **1** classé « réapparaît, mais sans mère trouvée » : La Guérinière. Hors
-- Paris et hors fractions, il ne reste que **dix communes**, toutes nommées.
--
-- Une fille muette retombe sur son repli **par définition** : elle devrait
-- donc figurer dans ces 84, et dans les 30 non-fractions. **Dix-sept n'y
-- tiennent pas.** Les deux mesures ne peuvent pas être justes toutes les deux,
-- et le doute joue contre celle-ci, qui est la plus jeune et la plus
-- approximative.
--
-- TROIS EXPLICATIONS, dans l'ordre de vraisemblance :
--
--   1. **CE PARAGRAPHE SUR-COMPTE, et c'est le suspect principal.** Il part de
--      la MÈRE et prend pour Y′ le premier millésime de la mère postérieur à
--      la date ; la règle part de la FILLE, prend SON Y′, puis choisit parmi
--      les mères candidates celle qui recouvre le plus. Une « fille » comptée
--      ici peut donc, dans la règle réelle, relever d'une AUTRE mère et être
--      servie par elle. Les deux lectures coïncident sur Noirmoutier — une
--      seule mère possible, une seule coupure — et rien ne garantit qu'elles
--      coïncident ailleurs. **C'est la première chose à vérifier.**
--   2. *`diag_partition.sql` § 2 range les autres ailleurs.* Une fille
--      perdante A une mère — le bloc `mere` réussit — et c'est `attribue` qui
--      ne lui donne rien. Le `CASE` du § 2 ne distingue pas ces deux échecs :
--      son dernier `ELSE` dit « pas de mère trouvée » dans les deux cas. Si
--      les autres n'y sont pas, elles ne sont pas en repli, et la question
--      change encore.
--   3. *La date.* Le § 7 de `84` documente le piège des onze mois : une mesure
--      au 1ᵉʳ janvier et une au 1ᵉʳ décembre décrivent deux cartes distantes
--      d'un an. Vérifier à quelle date les 84 ont été comptés.
--
-- **LE COUPLE DE NOIRMOUTIER, LUI, NE DÉPEND D'AUCUNE DE CES TROIS RÉSERVES.**
-- Il est mesuré de bout en bout au § 7 d, avec une seule mère possible, et il
-- suffit à établir que le défaut existe. Ce qui reste incertain est son
-- AMPLEUR — 1 ou 17 — et c'est exactement ce que la confrontation nom par nom
-- tranchera. *Un mécanisme se prouve sur un cas ; son ampleur ne se prouve que
-- sur la population, et les deux ne s'établissent pas de la même façon.*
--
-- POURQUOI LA RECETTE DE `84` NE POUVAIT PAS LE VOIR. Une sœur enflée occupe
-- le sol de sa sœur muette : le treillis lui donne les faces, et **la surface
-- totale est conservée**. L'emprise nationale tombait juste — 548 576 km²
-- contre 548 489 d'étalon, +0,016 % — parce qu'un échange ne change pas une
-- somme. *Une recette qui mesure un total ne voit pas une permutation ; il
-- faut mesurer atome par atome pour cela.*
-- ============================================================================

\echo ''
\echo '--- 7 f. les filles muettes et les sœurs enflées, nommées --------------'
\echo '    `rang` 1 = la sœur servie, et `pris_km2` − `son_repli_km2` mesure'
\echo '    de combien elle est dessinée trop grande. `rang` > 1 = la muette.'
\echo '    À confronter aux replis de `diag_partition.sql` § 1 : toute ligne'
\echo '    de rang > 1 devrait y figurer, et si elle n''y est pas, c''est ce'
\echo '    paragraphe qui se trompe.'
\echo ''

WITH cand AS (
    SELECT DISTINCT ON (gb.atom_id)
           gb.atom_id                                  AS mere,
           lower(gm.periode)                           AS y_prime,
           ST_CollectionExtract(ST_Difference(gb.geom, gm.geom), 3) AS reste,
           gb.geom                                     AS avant
    FROM   atom_geom_anr gb
    JOIN   atom_geom_anr gm ON gm.atom_id = gb.atom_id
                           AND lower(gm.periode) > :'date'::date
    WHERE  gb.periode @> :'date'::date
    ORDER  BY gb.atom_id, lower(gm.periode)
),
util AS (SELECT * FROM cand WHERE NOT ST_IsEmpty(reste)),
morceau AS (
    SELECT u.mere, u.y_prime, u.avant,
           row_number() OVER (PARTITION BY u.mere) AS mid,
           d.geom                                  AS g
    FROM   util u, ST_Dump(u.reste) d
),
fille AS (
    SELECT u.mere, u.y_prime, f.atom_id, af.insee_geofla, ag.geom AS repli
    FROM   util u
    JOIN   atom_geom_anr f ON lower(f.periode) = u.y_prime AND f.atom_id <> u.mere
    JOIN   atom af ON af.atom_id = f.atom_id AND NOT af.fraction
    JOIN   atom_geom ag ON ag.atom_id = f.atom_id
    WHERE  ST_Intersects(ag.geom, u.avant)
      AND  NOT EXISTS (SELECT 1 FROM atom_geom_anr g2
                        WHERE g2.atom_id = f.atom_id
                          AND g2.periode @> :'date'::date)
      AND  EXISTS (SELECT 1 FROM membership m
                    WHERE m.atom_id = f.atom_id AND m.periode @> :'date'::date)
),
-- les seuls couples qui nous intéressent : plus de filles que de morceaux
perdant AS (
    SELECT f.mere, f.y_prime
    FROM   fille f
    GROUP  BY f.mere, f.y_prime
    HAVING count(*) > (SELECT count(*) FROM morceau mo
                        WHERE mo.mere = f.mere AND mo.y_prime = f.y_prime)
),
attribution AS (
    SELECT f.mere, f.y_prime, f.atom_id, f.insee_geofla, mo.mid,
           ST_Area(f.repli)                              AS aire_repli,
           ST_Area(mo.g)                                 AS aire_morceau,
           ST_Area(ST_Intersection(f.repli, mo.g))       AS recouvre,
           rank() OVER (PARTITION BY mo.mere, mo.y_prime, mo.mid
                        ORDER BY ST_Area(ST_Intersection(f.repli, mo.g)) DESC,
                                 f.atom_id)              AS rang
    FROM   perdant p
    JOIN   fille f  ON f.mere = p.mere AND f.y_prime = p.y_prime
    JOIN   morceau mo ON mo.mere = p.mere AND mo.y_prime = p.y_prime
)
SELECT a.mere,
       coalesce(nm.nom, '[' || am.insee_geofla || ']')                AS mere_nom,
       extract(year FROM a.y_prime)::int                             AS y_prime,
       a.atom_id                                                     AS fille,
       coalesce(nf.nom, '[' || a.insee_geofla || ']')                 AS fille_nom,
       a.rang,
       round((a.aire_repli   / 1e6)::numeric, 3)                      AS son_repli_km2,
       round((a.aire_morceau / 1e6)::numeric, 3)                      AS morceau_km2,
       CASE WHEN a.rang = 1
            THEN round(((a.aire_morceau - a.aire_repli) / 1e6)::numeric, 3)
       END                                                            AS enflee_de_km2,
       CASE WHEN a.rang = 1 THEN 'sœur servie — dessinée trop grande'
            ELSE                 'MUETTE — retombe sur son repli' END AS verdict
FROM   attribution a
JOIN   atom am ON am.atom_id = a.mere
LEFT   JOIN noms_geofla nm ON nm.insee = am.insee_geofla
LEFT   JOIN noms_geofla nf ON nf.insee = a.insee_geofla
ORDER  BY a.mere, a.mid, a.rang;

-- ============================================================================
-- § 7 g. LE § 7 f EST RÉFUTÉ PAR SA PROPRE SORTIE — ET VOICI LA MESURE JUSTE
--
-- Les 31 lignes du § 7 f portent leur propre démenti, et il se lit sans la
-- base :
--
--   * **Sury et This apparaissent DEUX FOIS, avec les rôles inversés.** Sous
--     Neuville-lès-This (1871), This est servie et Sury muette ; sous Belval
--     (1871), Sury est servie et This muette. Idem pour Ville-sur-Retourne et
--     Mont-Saint-Rémy (Pauvres / Bignicourt), pour Amnéville et `57435`
--     (Gandrange / Montois-la-Montagne), pour Mars-sous-Bourcq
--     (Tourcelles-Chaumont / Bourcq).
--   * **Six `enflee_de_km2` sont NÉGATIFS** : le morceau est plus petit que le
--     repli de la « fille » — Gandrange donne 5,796 km² à une commune de
--     10,538. Une fille n'est pas plus grande que ce que sa mère a perdu.
--   * **`08068` réclame 28,103 km² sur un morceau de 4,748.**
--
-- LA CAUSE EST CELLE QUI ÉTAIT ANNONCÉE EN TÊTE DU § 7 f, ET C'EST LA MIENNE :
-- ce paragraphe part de la MÈRE et attribue à chaque mère toutes les filles du
-- millésime. La règle part de la FILLE, lui donne UNE mère — `DISTINCT ON
-- (r.atom_id)`, au plus fort recouvrement — et chaque fille n'entre donc que
-- dans UN couple. Sury choisit Belval, This choisit Neuville : **les deux sont
-- servies**, et le § 7 f invente deux muettes en les comptant sous les deux
-- mères. Les 17 sont un majorant sans valeur.
--
-- *Une approximation qui produit des rôles contradictoires pour un même objet
-- ne demande pas d'être arbitrée : elle demande d'être abandonnée.*
--
-- ET IL N'Y AVAIT PAS À RÉIMPLÉMENTER LA RÈGLE. `partition_reprise` est
-- déclarée `LANGUAGE sql STABLE`, sans table temporaire, et son paramètre
-- `p_dep` accepte `NULL` : son bloc `vivant` porte
-- `(p_dep IS NULL OR m.atom_id IN proches)`. **Appelée sans département, elle
-- fait la France entière**, et c'est la règle elle-même, pas une lecture de la
-- règle. C'est `partition_UN_DEP` qui exige un département — pas celle-ci.
--
-- *J'ai réécrit à la main un algorithme que je pouvais appeler. Le § 7 e et le
-- § 7 f sont conservés parce qu'ils ont trouvé le mécanisme sur le couple de
-- Noirmoutier, où une seule mère est possible ; ils ne valent rien au-delà.*
--
-- COÛT : quelques minutes. `partition_reprise` sur la France sonde l'index
-- gist de `atom_geom_anr` pour chaque atome manquant.
-- ============================================================================

\echo ''
\echo '--- 7 g. la règle elle-même, appelée sans département ------------------'
\echo '    Quelques minutes. C''est `partition_reprise` qui répond, pas une'
\echo '    reconstitution : le résultat est celui que 84 utilisera.'
\echo ''

DO $$
BEGIN
    IF to_regprocedure('histgis.partition_reprise(date, text)') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/84_carte_partition.sql avant ce paragraphe.';
    END IF;
END $$;

DROP TABLE IF EXISTS d_reprise;
-- `NULL::text` et non `NULL` nu : la résolution de surcharge n'a rien à
-- deviner. Un jour où une seconde `partition_reprise` existera, le `NULL` nu
-- deviendra ambigu, et l'erreur tombera loin d'ici.
CREATE TEMP TABLE d_reprise AS
SELECT * FROM partition_reprise(:'date'::date, NULL::text);
CREATE INDEX ON d_reprise (atom_id);
ANALYZE d_reprise;

-- La population candidate, copiée du bloc `manquant` de `84` § 4 : vivante à
-- la date, non-fraction, pourvue d'un repli, et qu'ANR ne pourvoit pas alors.
DROP TABLE IF EXISTS d_candidat;
CREATE TEMP TABLE d_candidat AS
SELECT DISTINCT m.atom_id, a.insee_geofla, ag.geom AS repli,
       (SELECT min(lower(g.periode)) FROM atom_geom_anr g
         WHERE g.atom_id = m.atom_id
           AND lower(g.periode) > :'date'::date)          AS y_prime
FROM   membership m
JOIN   atom a       ON a.atom_id = m.atom_id AND NOT a.fraction
JOIN   atom_geom ag ON ag.atom_id = m.atom_id
WHERE  m.periode @> :'date'::date
  AND  NOT EXISTS (SELECT 1 FROM atom_geom_anr g
                    WHERE g.atom_id = m.atom_id AND g.periode @> :'date'::date);

CREATE INDEX ON d_candidat (atom_id);
ANALYZE d_candidat;

\echo ''
\echo '    Le compte, et il fait foi :'
\echo ''

SELECT count(*)                                            AS candidats,
       count(*) FILTER (WHERE r.atom_id IS NOT NULL)       AS servis_par_la_reprise,
       count(*) FILTER (WHERE r.atom_id IS NULL
                          AND c.y_prime IS NOT NULL)       AS muets_malgre_un_y_prime,
       count(*) FILTER (WHERE r.atom_id IS NULL
                          AND c.y_prime IS NULL)           AS sans_y_prime_limite_de_source
FROM   d_candidat c
LEFT   JOIN d_reprise r ON r.atom_id = c.atom_id;

\echo ''
\echo '    `muets_malgre_un_y_prime` EST le chiffre cherché : ANR reparle'
\echo '    d''eux, et la règle ne leur rend rien. C''est lui qu''ETAT.md annonce'
\echo '    à 1, et lui seul qui se compare aux 84 replis résiduels.'
\echo ''
\echo '    Les nommer, tous :'
\echo ''

SELECT c.atom_id, c.insee_geofla,
       coalesce(n.nom, '[' || coalesce(c.insee_geofla, '?') || ']')    AS nom,
       extract(year FROM c.y_prime)::int                              AS y_prime,
       round((ST_Area(c.repli) / 1e6)::numeric, 3)                     AS repli_km2,
       (SELECT min(u.dep) FROM membership m
          JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
         WHERE m.atom_id = c.atom_id AND m.periode @> :'date'::date)   AS dep
FROM   d_candidat c
LEFT   JOIN d_reprise r ON r.atom_id = c.atom_id
LEFT   JOIN noms_geofla n ON n.insee = c.insee_geofla
WHERE  r.atom_id IS NULL AND c.y_prime IS NOT NULL
ORDER  BY 5 DESC;

\echo ''
\echo '--- 7 h. les sœurs enflées, mesurées sur ce que la règle leur donne ----'
\echo '    `fratrie` vient de partition_reprise : c''est le nombre de filles du'
\echo '    couple (mère, Y''). Une fratrie > 1 dont le polygone rendu dépasse'
\echo '    largement le repli est une sœur qui a pris la part d''une autre.'
\echo '    C''est LA mesure du défaut, et elle ne dépend d''aucune de mes'
\echo '    reconstitutions.'
\echo ''

SELECT r.fratrie,
       count(*)                                                       AS atomes,
       round((sum(ST_Area(r.geom) - ST_Area(c.repli)) / 1e6)::numeric, 1)
                                                                      AS ecart_total_km2,
       round((max(ST_Area(r.geom) - ST_Area(c.repli)) / 1e6)::numeric, 1)
                                                                      AS pire_ecart_km2
FROM   d_reprise r
JOIN   d_candidat c ON c.atom_id = r.atom_id
GROUP  BY r.fratrie
ORDER  BY r.fratrie;

\echo ''
\echo '    Et les pires, nommées :'
\echo ''

SELECT r.atom_id,
       coalesce(n.nom, '[' || coalesce(c.insee_geofla, '?') || ']')    AS soeur,
       r.mere_id,
       coalesce(nm.nom, '[' || am.insee_geofla || ']')                 AS mere,
       r.an_reprise, r.fratrie,
       round((ST_Area(c.repli) / 1e6)::numeric, 3)                     AS son_repli_km2,
       round((ST_Area(r.geom)  / 1e6)::numeric, 3)                     AS recue_km2,
       round(((ST_Area(r.geom) - ST_Area(c.repli)) / 1e6)::numeric, 3) AS ecart_km2
FROM   d_reprise r
JOIN   d_candidat c ON c.atom_id = r.atom_id
LEFT   JOIN noms_geofla n ON n.insee = c.insee_geofla
LEFT   JOIN atom am ON am.atom_id = r.mere_id
LEFT   JOIN noms_geofla nm ON nm.insee = am.insee_geofla
WHERE  r.fratrie > 1
ORDER  BY ST_Area(r.geom) - ST_Area(c.repli) DESC
LIMIT  25;

-- ============================================================================
-- § 7 i. DEUX RÉSULTATS QUI DÉPASSENT LA RÈGLE — mesurés le 5 septembre 2026
--
--     candidats .................... 486
--     servis par la reprise ........ 435
--     MUETS malgré un Y′ ...........  13   ← `ETAT.md` en annonce 1
--     sans Y′ (limite de source) ...  38
--
-- LES TREIZE, ET LEUR POIDS : Beauvais (33,5 km², Y′ 1943), Saint-Sulpice 63
-- (18,3), Anthé (14,4), La Guillermie (12,6), Cazideroque (12,3), Thézac
-- (11,3), Masquières (11,2), Amnéville (10,5), Velanne (8,1), La Guérinière
-- (7,9), Saint-Sulpice-des-Rivoires (7,2), Colomars (6,0), Chardeny (5,1).
-- **Environ 158 km², et non 0,4.** Quatre sont du Lot-et-Garonne au même
-- millésime 1876 — la fratrie de six de Tournon-d'Agenais.
--
-- ---------------------------------------------------------------------------
-- (1) DEUX ATOMES REÇOIVENT UN POLYGONE VIDE, ET C'EST PIRE QUE D'ÊTRE MUET
-- ---------------------------------------------------------------------------
--     13202  L'Étang-Bertrand  mère Bricquebec 1895     repli 8,525  reçue 0,000
--     10603  Courbiac          mère Tournon-d'Agenais   repli 9,013  reçue 0,000
--
-- Ils sont DANS le résultat de `partition_reprise` : ils comptent donc comme
-- `source = 'reprise'`, jamais comme repli, et ils n'apparaissent ni dans les
-- 84 replis résiduels ni dans les 13 muets. **Ils sont invisibles aux deux
-- comptes à la fois**, et ils ne dessinent rien.
--
-- Le chemin est net. `partition_reprise` finit par `ST_Multi(
-- ST_CollectionExtract(ST_UnaryUnion(ST_Collect(a.g)), 3))` : quand tous les
-- morceaux d'un atome sont vides, cela rend un `MULTIPOLYGON EMPTY`, qui n'est
-- pas `NULL`. Et `84` § (a) écrit `DELETE FROM t84_src WHERE geom IS NULL` —
-- **une géométrie vide passe le filtre.** Elle entre dans le treillis, ne
-- borde rien, ne gagne aucune face, et disparaît sans un mot.
--
-- *Un test `IS NULL` sur une géométrie ne teste pas l'absence de géométrie.
-- PostGIS distingue « pas de valeur » de « valeur vide », et seul le premier
-- se voit.*
--
-- **LE CORRECTIF EST SANS ARBITRAGE**, et c'est ce qui le rend recevable ici :
-- écarter les vides du résultat de `partition_reprise` les fait retomber sur
-- leur repli GEOFLA, c'est-à-dire sur le comportement déclaré de R5. Rien
-- n'est inventé, une trappe est fermée. Deux lignes :
--
--     -- dans partition_reprise, au SELECT final :
--     ... GROUP BY a.atom_id
--     HAVING NOT ST_IsEmpty(ST_CollectionExtract(
--                ST_UnaryUnion(ST_Collect(a.g)), 3));
--     -- dans partition_un_dep § (a) :
--     DELETE FROM t84_src WHERE geom IS NULL OR ST_IsEmpty(geom);
--
-- Non appliqué ici : `diag_*` ne modifie rien. Mais c'est le seul des trois
-- défauts de ce paragraphe qui se corrige sans décider de rien.
--
-- **APPLIQUÉ DANS `sql/84_carte_partition.sql` LE 5 SEPTEMBRE 2026**, aux deux
-- endroits dits. Conséquence pour la lecture de ce fichier : le § 7 j ci-après
-- attendait 2 lignes ; contre un `84` corrigé et rejoué, **il doit en rendre 0**,
-- et c'est la preuve que la trappe est fermée. Contre un `84` d'avant le
-- correctif, il en rend 2. *Une recette dont l'attendu bascule au passage d'un
-- correctif doit le dire, sinon elle a l'air de tomber en panne.*
--
-- ---------------------------------------------------------------------------
-- (2) LE CADRE DÉPARTEMENTAL CHANGE LE RÉSULTAT DE LA REPRISE
-- ---------------------------------------------------------------------------
-- 13 muets au national, 1 annoncé sur la carte. L'écart n'est pas une erreur
-- de mesure : **les deux ne calculent pas la même chose.**
--
-- Dans `partition_reprise`, le bloc `vivant` est filtré par le département
-- (`p_dep IS NULL OR m.atom_id IN proches`), mais le bloc `mere` interroge
-- `atom_geom_anr` SANS restriction. Conséquence : à l'échelle d'un
-- département, **moins de filles concourent pour le même morceau**, et une
-- fille qui perdait au national peut gagner en local. La carte étant produite
-- département par département (`carte_partition_atome` boucle), elle voit donc
-- moins de muettes — d'où 1 plutôt que 13.
--
-- **CELA CONTREDIT UNE AFFIRMATION DE `84`**, écrite en tête de
-- `partition_un_dep` : *« Le découpage par département avec anneau de contexte
-- rend EXACTEMENT le même dessin, puisque l'anneau contient tout ce qui peut
-- toucher le département. »* C'est vrai du TREILLIS, dont les effets sont
-- locaux. **Ce n'est pas vrai de la REPRISE**, où le résultat dépend de
-- l'ensemble des concurrents, donc du cadre.
--
-- *Une opération n'est découpable que si ses effets sont locaux. Le treillis
-- l'est ; un arbitrage entre prétendants ne l'est pas, et les deux vivaient
-- dans le même fichier sous la même justification.*
--
-- Et le corollaire est plus gênant que l'écart de comptage : **une fratrie à
-- cheval sur deux départements verrait le même morceau attribué deux fois**,
-- une fois dans chaque passe. La ligne « couture entre départements » de
-- `check_partition` est l'endroit où cela se lirait.
-- ============================================================================

\echo ''
\echo '--- 7 i. le même atome, jugé au national puis dans son département -----'
\echo '    `servi_en_local` = ce que la CARTE fait réellement, puisqu''elle'
\echo '    boucle par département. `t` alors que le national dit muet prouve'
\echo '    que le cadre change le résultat de la reprise — et donc que celle-ci'
\echo '    n''est pas découpable comme le treillis l''est.'
\echo ''

SELECT c.atom_id,
       coalesce(n.nom, '[' || c.insee_geofla || ']')                   AS nom,
       d.dep,
       extract(year FROM c.y_prime)::int                              AS y_prime,
       round((ST_Area(c.repli) / 1e6)::numeric, 3)                     AS repli_km2,
       EXISTS (SELECT 1 FROM partition_reprise(:'date'::date, d.dep) r
                WHERE r.atom_id = c.atom_id)                          AS servi_en_local
FROM   d_candidat c
LEFT   JOIN d_reprise dr ON dr.atom_id = c.atom_id
LEFT   JOIN noms_geofla n ON n.insee = c.insee_geofla
CROSS  JOIN LATERAL (
       SELECT min(u.dep) AS dep
       FROM   membership m
       JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
       WHERE  m.atom_id = c.atom_id AND m.periode @> :'date'::date) d
WHERE  dr.atom_id IS NULL AND c.y_prime IS NOT NULL
ORDER  BY 5 DESC;

\echo ''
\echo '--- 7 j. les atomes SERVIS avec un polygone vide -----------------------'
\echo '    Invisibles aux deux comptes : ni repli, ni muet, et rien à dessiner.'
\echo '    Attendu : 2 contre un `84` d''AVANT le 5 septembre 2026 —'
\echo '    L''Étang-Bertrand et Courbiac. Contre un `84` corrigé et rejoué,'
\echo '    l''attendu est 0, et zéro ligne vaut alors preuve, pas panne.'
\echo ''

SELECT r.atom_id,
       coalesce(n.nom, '[' || coalesce(c.insee_geofla, '?') || ']')    AS nom,
       r.mere_id, r.an_reprise, r.fratrie,
       round((ST_Area(c.repli) / 1e6)::numeric, 3)                     AS repli_perdu_km2,
       ST_IsEmpty(r.geom)                                             AS geom_vide
FROM   d_reprise r
JOIN   d_candidat c ON c.atom_id = r.atom_id
LEFT   JOIN noms_geofla n ON n.insee = c.insee_geofla
WHERE  ST_IsEmpty(r.geom)
ORDER  BY 6 DESC;

\echo ''
\echo '    Quatre suites, dans cet ordre et pas un autre :'
\echo '      0. FERMER LA TRAPPE DU VIDE — ÉCRIT DANS `84` LE 5 SEPTEMBRE 2026.'
\echo '         `HAVING NOT ST_IsEmpty(...)` dans partition_reprise, et'
\echo '         `OR ST_IsEmpty(geom)` dans le DELETE de partition_un_dep § (a).'
\echo '         Reste à REJOUER `84` sur la base, puis à relire le § 7 j :'
\echo '         il doit rendre 0, et les deux atomes reparaître en repli ;'
\echo '      1. confronter les muets du § 7 g aux replis de diag_partition.sql'
\echo '         § 1 — ils doivent y être, tous, et rien qu''eux ;'
\echo '      2. si la liste tient, corriger la LÉGENDE de 84 et sa recette'
\echo '         avant sa règle : une somme conservée cachait un échange, et'
\echo '         c''est la recette qui a failli, pas seulement l''algorithme ;'
\echo '      3. seulement alors, décider si un morceau connexe se partage.'
\echo '         Le partager au prorata serait un SEUIL dans un algorithme qui'
\echo '         revendique de n''en avoir aucun, et tracerait une frontière'
\echo '         qu''aucune source ne porte. Déclarer reste défendable ; le'
\echo '         faire en silence ne l''est plus, maintenant qu''on sait.'
\echo ''
\echo '--- Fin. `d_muet`, `d_reprise` et `d_candidat` restent disponibles.'
\echo ''
