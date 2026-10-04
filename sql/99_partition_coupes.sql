-- ============================================================================
-- histgis — 99_partition_coupes.sql : les villes découpées entrent dans la carte
--
--     psql -d histgis -1 -f sql/99_partition_coupes.sql
--     SELECT * FROM check_coupe_partition('1900-12-01', '03');
--
-- À JOUER APRÈS `84` ET APRÈS `98`, ET À REJOUER APRÈS TOUT REJEU DE `84`.
-- `84` commence par `DROP FUNCTION carte_partition_atome` : le rejouer seul
-- rend la carte d'avant, où chaque fraction porte la commune entière. Rien
-- n'échoue, la carte redevient simplement hachurée. `check_coupe_partition`
-- le dit en tête (WARNING), et `rejouer_apres_rebuild.sh` enchaîne 84 puis 99.
--
-- CE QUE CE FICHIER CORRIGE
-- -------------------------
-- Au 3 octobre 2026, 59 villes ont des lignes (`cartes/coupes_ville.csv`), 57
-- passent la recette de `98`. Mais `carte_coupe_ville()` n'était appelée que
-- par `pose_coupe.py` et `tableau_villes.py`. La partition de `84`, que lit
-- `export_web.py --partition`, faisait toujours entrer les fractions dans le
-- treillis comme UN propriétaire — la commune-mère — et les rendait dupliquées
-- par canton, polygone entier (§ 8-1 de `84`). Le travail de découpe
-- n'atteignait pas la carte.
--
-- LA RÈGLE
-- --------
-- `partition_un_dep()` (84) est jouée telle quelle. On reprend sa sortie :
--
--   0. une fraction vivante que le treillis a perdue au profit de sa propre
--      mère — vivante au niveau circo, avec un polygone ANR qui gagne toutes
--      les faces — reçoit le polygone net de la mère (§ 2 a0). C'est un défaut
--      de `84` antérieur à ce fichier : avant 1941, les cantons des villes
--      dont la circo tient sur la mère n'avaient pas de ville ;
--   1. pour chaque commune dont des fractions sortent du treillis ET qui a une
--      ligne valable à la date, on réunit le polygone NET que le treillis leur
--      a donné — la commune telle qu'arbitrée contre ses voisines ce jour-là ;
--   2. on le découpe par `carte_coupe_ville_sur()` (98) : mêmes lignes, mêmes
--      ancres, même raccord au bord, mêmes miettes et îlots rattachés. Le
--      contour change, la découpe non — c'est la raison d'être des lignes ;
--   3. TOUT OU RIEN, ville par ville et date par date. La découpe n'est prise
--      que si chaque fraction sortie du treillis reçoit exactement un morceau,
--      aucun morceau ne va à une fraction absente, et la somme des morceaux
--      égale le polygone net à 1 m² près (la tolérance de la recette de 98).
--      Sinon la ville sort comme avant, polygone entier, hachurée : une
--      superposition DÉCLARÉE vaut mieux qu'un morceau perdu sans un mot ;
--   4. une fraction découpée garde sa `source` ; son `motif` devient
--      `coupe_ville`. C'est ce motif que `carte_partition()` lit pour ne plus
--      la compter dans `n_partagees`.
--
-- POURQUOI LE POLYGONE NET, ET PAS `cible_ville()`
-- -------------------------------------------------
-- `cible_ville()` donne l'ANR de l'atome-mère ; le treillis donne GEOFLA
-- arbitré contre des voisines ANR (les fractions n'ont pas d'ANR à elles). Les
-- deux diffèrent d'une lisière. Découper la cible puis l'intersecter avec le
-- net laisserait des éclats sans propriétaire de part et d'autre ; découper le
-- net garantit que les morceaux pavent EXACTEMENT ce que le treillis a donné à
-- la commune — donc aucun recouvrement avec les voisines, par construction.
--
-- CE QUE CE FICHIER NE TOUCHE PAS
-- -------------------------------
-- Aucune donnée : `atom_geom`, `atom_geom_anr`, `membership`, `coupe_ville`
-- restent intacts. Il remplace deux fonctions de `84` (`carte_partition_atome`,
-- `carte_partition`) par des versions de même signature, et en pose deux
-- (`partition_coupe_un_dep`, `check_coupe_partition`). `snapshot_geom_anr()`
-- (82), la carte brute, n'est PAS découpée : elle reste la lecture qui dit d'où
-- vient chaque polygone.
--
-- CE QUI RESTE À FAIRE HORS DE CE FICHIER
-- ---------------------------------------
--   * `export_web.py` : les bornes des lignes et des ancres sont ajoutées aux
--     années géométriques (`SQL_BORNES_COUPE`), sans quoi une ligne qui
--     commence en 1982 ne serait tirée qu'à la prochaine borne de forme.
--   * le drapeau `p` (hachure) de la page vient d'`atom_geom.partagee`, qui ne
--     connaît pas la date : une fraction découpée reste hachurée dans la page.
--     À rendre par version (année) dans l'export — étape à part, côté page.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\echo ''
\echo '============================================================'
\echo ' 99 — les villes découpées entrent dans la partition de 84'
\echo '============================================================'

DO $$
BEGIN
    IF to_regprocedure('histgis.partition_un_dep(date, text)') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/84_carte_partition.sql.';
    END IF;
    IF to_regclass('histgis.coupe_ville') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : coupe_ville absente — '
            'psql -d histgis -1 -v appliquer=1 -f sql/98_coupe_ville.sql';
    END IF;
    IF to_regprocedure('histgis.carte_coupe_ville_sur(text, date, geometry)') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : carte_coupe_ville_sur() absente — rejouer '
            'sql/98_coupe_ville.sql (version du 3 octobre 2026 ou après).';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- § 1. La trace. Ce fichier n'écrit aucune donnée ; il trace les fonctions
--      qu'il pose, pour que `diag_passages.sql` sache s'il est passé.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS p99_trace (
    quoi text        NOT NULL,          -- 'fonction'
    cle  text        NOT NULL,
    pose timestamptz NOT NULL DEFAULT now()
);
DELETE FROM p99_trace WHERE quoi = 'fonction';

-- ---------------------------------------------------------------------------
-- § 2. Le treillis d'un département, villes découpées.
-- ---------------------------------------------------------------------------
-- Le bilan est une table TEMPORAIRE : `export_web.py --role histgis_carte`
-- n'a que SELECT et TEMPORARY. Rien ici n'écrit dans `histgis`.
CREATE OR REPLACE FUNCTION partition_coupe_un_dep(p_date date, p_dep text)
RETURNS TABLE (atom_id text, geom geometry(MultiPolygon, 2154),
               source text, motif text, dedans boolean)
LANGUAGE plpgsql VOLATILE AS $$
#variable_conflict use_column
BEGIN
    DROP TABLE IF EXISTS t99_part;
    CREATE TEMP TABLE t99_part ON COMMIT DROP AS
    SELECT * FROM partition_un_dep(p_date, p_dep);

    -- (a0) LES FRACTIONS QUE LE TREILLIS PERD — 3 octobre 2026, `diag_99.sql`.
    --      Moulins en 1900 : la ville est coupée entre deux CANTONS (24214#0323,
    --      #0324), mais entière dans une CIRCO, et c'est l'atome-mère 24214 qui
    --      porte l'appartenance de circo (U0381@1876, 1889-1919). `84` fait
    --      vivre les trois ; la mère arrive avec son polygone ANR (870 ha), les
    --      fractions avec le repli GEOFLA (852 ha), et `source_datee` donne
    --      TOUTES les faces à la mère. Les fractions ne gagnent rien et sortent
    --      du résultat : dans l'Allier au 1900-12-01, 4 fractions vivantes, 0
    --      rendue. Le canton de Moulins-Est n'a alors plus de ville du tout —
    --      un trou dans la carte des cantons, antérieur à `99`.
    --      Mère et fractions sont le même sol vu à deux niveaux. Une fraction
    --      vivante, absente de la sortie, dont la mère y est (et n'a PAS de
    --      canton à la date — sinon c'est le cas Graville, et le double compte
    --      serait réel), reçoit le polygone net de la mère. Elle ressort
    --      entière (motif `mere_vivante`), puis découpée au § (b) si sa ville a
    --      des lignes. La mère garde le sien pour la circo : les deux ne se
    --      recouvrent pas DANS un même niveau.
    --
    --      ET LES FRACTIONS QUI N'EN GARDENT QUE DES MIETTES — même jour, recette
    --      du 1900-12-01. Là où le repli GEOFLA déborde l'ANR de la mère, les
    --      fractions gagnent quelques faces et restent dans la sortie : Tourcoing
    --      2,24 ha au lieu de 1 521, Wattrelos 23 au lieu de 1 373, Le Havre 445
    --      au lieu de 2 012. Elles n'étaient pas « absentes », la première règle
    --      ne les voyait pas. Même cas, même remède : mère ∪ miettes.
    UPDATE t99_part t
       SET geom  = ST_Multi(ST_CollectionExtract(
                       ST_UnaryUnion(ST_Collect(t.geom, mo.geom)), 3)),
           motif = 'mere_vivante'
      FROM atom f, t99_part mo
     WHERE f.atom_id = t.atom_id
       AND f.atom_id LIKE '%#%'
       AND mo.atom_id = f.cassini
       AND NOT EXISTS (SELECT 1 FROM membership mm
                        WHERE mm.atom_id = f.cassini AND mm.niveau = 'canton'
                          AND mm.periode @> p_date);

    INSERT INTO t99_part (atom_id, geom, source, motif, dedans)
    SELECT f.atom_id, mo.geom, mo.source, 'mere_vivante', true
    FROM  (SELECT DISTINCT m.atom_id
             FROM membership m
             JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
            WHERE m.periode @> p_date AND u.dep = p_dep) v
    JOIN   atom f ON f.atom_id = v.atom_id AND f.atom_id LIKE '%#%'
    JOIN   t99_part mo ON mo.atom_id = f.cassini
    WHERE  NOT EXISTS (SELECT 1 FROM t99_part t WHERE t.atom_id = f.atom_id)
      AND  NOT EXISTS (SELECT 1 FROM membership mm
                        WHERE mm.atom_id = f.cassini AND mm.niveau = 'canton'
                          AND mm.periode @> p_date);

    -- (a) Les communes à découper : fractions sorties du treillis, et une
    --     ligne valable à la date. Le polygone net est réuni sur la commune ;
    --     d'ordinaire toutes ses fractions portent le même.
    DROP TABLE IF EXISTS t99_ville;
    CREATE TEMP TABLE t99_ville ON COMMIT DROP AS
    -- LA CLÉ PEUT ÊTRE UN QUARTIER — 3 octobre 2026, Paris : `coupe_cle()` (98)
    -- rend `PQnn` pour les fractions de quartier (101), la commune sinon.
    SELECT coupe_cle(a.cassini, a.insee_geofla::text)   AS insee,
           array_agg(t.atom_id ORDER BY t.atom_id)      AS fractions,
           bool_or(t.motif = 'mere_vivante')            AS par_la_mere,
           ST_UnaryUnion(ST_Collect(t.geom))            AS g
    FROM   t99_part t
    JOIN   atom a ON a.atom_id = t.atom_id
    WHERE  a.fraction
      AND  a.atom_id LIKE '%#%'
      AND  EXISTS (SELECT 1 FROM coupe_ville c
                    WHERE c.insee = coupe_cle(a.cassini, a.insee_geofla::text)
                      AND c.periode @> p_date)
    GROUP  BY coupe_cle(a.cassini, a.insee_geofla::text);

    -- (b) La découpe, sur le polygone net.
    DROP TABLE IF EXISTS t99_morceau;
    CREATE TEMP TABLE t99_morceau ON COMMIT DROP AS
    SELECT v.insee, m.atom_id, m.geom
    FROM   t99_ville v
    CROSS  JOIN LATERAL carte_coupe_ville_sur(v.insee, p_date, v.g) m;

    -- (c) Tout ou rien, ville par ville.
    DROP TABLE IF EXISTS t99_ok;
    CREATE TEMP TABLE t99_ok ON COMMIT DROP AS
    WITH b AS (
        SELECT v.insee, v.fractions, v.par_la_mere,
               ST_Area(v.g) AS m2_commune,
               coalesce((SELECT sum(ST_Area(m.geom)) FROM t99_morceau m
                          WHERE m.insee = v.insee), 0)                  AS m2_rendu,
               coalesce((SELECT array_agg(m.atom_id ORDER BY m.atom_id)
                           FROM t99_morceau m WHERE m.insee = v.insee),
                        '{}'::text[])                                   AS servies
        FROM   t99_ville v
    )
    SELECT b.*,
           CASE WHEN cardinality(b.servies) = 0
                     THEN 'aucun morceau ancré à la date'
                WHEN b.servies <> b.fractions
                     THEN 'fractions et morceaux ne se répondent pas'
                WHEN abs(b.m2_rendu - b.m2_commune) > 1.0
                     THEN 'aire perdue ou en trop'
           END AS refus
    FROM   b;

    CREATE TEMP TABLE IF NOT EXISTS t99_bilan (
        p_date date, dep text, insee text, fractions int, morceaux int,
        ha_commune numeric, ha_rendu numeric, refus text,
        par_la_mere boolean) ON COMMIT DROP;
    INSERT INTO t99_bilan
    SELECT p_date, p_dep, o.insee, cardinality(o.fractions), cardinality(o.servies),
           round((o.m2_commune / 1e4)::numeric, 2),
           round((o.m2_rendu / 1e4)::numeric, 2), o.refus, o.par_la_mere
    FROM   t99_ok o;

    -- (d) La sortie : celle de 84, morceau à la place du polygone entier pour
    --     les seules villes acceptées.
    RETURN QUERY
    SELECT t.atom_id,
           CASE WHEN m.atom_id IS NOT NULL
                THEN ST_Multi(ST_CollectionExtract(m.geom, 3))::geometry(MultiPolygon, 2154)
                ELSE t.geom END,
           t.source,
           CASE WHEN m.atom_id IS NOT NULL THEN 'coupe_ville' ELSE t.motif END,
           t.dedans
    FROM   t99_part t
    LEFT   JOIN (SELECT mo.atom_id, mo.geom
                   FROM t99_morceau mo
                   JOIN t99_ok o ON o.insee = mo.insee AND o.refus IS NULL) m
           ON m.atom_id = t.atom_id;
END $$;

COMMENT ON FUNCTION partition_coupe_un_dep(date, text) IS
    'partition_un_dep (84), puis les villes à lignes découpées sur leur polygone net (98). Tout ou rien par ville. Passer par carte_partition_atome().';

-- ---------------------------------------------------------------------------
-- § 3. `carte_partition_atome` — même signature, même boucle que dans `84`,
--      mais par `partition_coupe_un_dep`. `export_web.py`, `carte_partition`
--      et `check_partition` passent tous par elle : un seul branchement.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION carte_partition_atome(p_date date, p_dep text DEFAULT NULL)
RETURNS TABLE (atom_id text, geom geometry(MultiPolygon, 2154),
               source text, motif text, dedans boolean)
LANGUAGE plpgsql VOLATILE AS $$
#variable_conflict use_column
DECLARE
    d      text;
    n_dep  int := 0;
    i      int := 0;
BEGIN
    IF p_dep IS NOT NULL THEN
        RETURN QUERY SELECT * FROM partition_coupe_un_dep(p_date, p_dep);
        RETURN;
    END IF;

    SELECT count(DISTINCT u.dep) INTO n_dep
    FROM   membership m
    JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
    WHERE  m.periode @> p_date;

    FOR d IN
        SELECT DISTINCT u.dep
        FROM   membership m
        JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
        WHERE  m.periode @> p_date
        ORDER  BY 1
    LOOP
        i := i + 1;
        RAISE NOTICE 'carte_partition_atome %/% : département %', i, n_dep, d;
        RETURN QUERY SELECT * FROM partition_coupe_un_dep(p_date, d);
    END LOOP;
END $$;

COMMENT ON FUNCTION carte_partition_atome(date, text) IS
    'La trame communale nettoyée à une date, villes multicantonales découpées quand leurs lignes ferment (99). Ex : SELECT * FROM carte_partition_atome(''1870-12-01'', ''01'');';

-- ---------------------------------------------------------------------------
-- § 4. `carte_partition` — identique à `84`, sauf `n_partagees`, qui ne compte
--      plus que les fractions restées entières. Une fraction découpée n'est
--      plus une superposition : la déclarer encore serait faux dans l'autre
--      sens.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION carte_partition(p_date date, p_niveau text DEFAULT 'canton',
                                           p_dep text DEFAULT NULL)
RETURNS TABLE (unit_id text, niveau text, dep text, nom text,
               n_atomes bigint, n_anr bigint, n_repris bigint, n_repli bigint,
               n_partagees bigint,
               geom geometry(MultiPolygon, 2154))
LANGUAGE sql VOLATILE AS $$
    WITH pris AS (
        SELECT m.unit_id, m.niveau, c.atom_id, c.geom, c.source, c.motif, a.fraction
        FROM   carte_partition_atome(p_date, p_dep) c
        JOIN   membership m ON m.atom_id = c.atom_id AND m.periode @> p_date
        JOIN   atom a ON a.atom_id = c.atom_id
        WHERE  m.niveau = p_niveau
    )
    SELECT u.unit_id, u.niveau, u.dep,
           coalesce(uv.nom, u.nom),
           count(*),
           count(*) FILTER (WHERE p.source = 'anr'),
           count(*) FILTER (WHERE p.source = 'reprise'),
           count(*) FILTER (WHERE p.source = 'repli'),
           count(*) FILTER (WHERE p.fraction AND p.motif IS DISTINCT FROM 'coupe_ville'),
           ST_Multi(ST_CollectionExtract(
               ST_UnaryUnion(ST_Collect(p.geom)), 3))
    FROM   pris p
    JOIN   unit u ON u.unit_id = p.unit_id AND u.niveau = p.niveau
    LEFT   JOIN unit_version uv ON uv.unit_id = u.unit_id AND uv.periode @> p_date
    GROUP  BY u.unit_id, u.niveau, u.dep, coalesce(uv.nom, u.nom);
$$;

COMMENT ON FUNCTION carte_partition(date, text, text) IS
    'La carte dissoute, sans trou ni superposition hors fractions restées entières (99). Ex : SELECT unit_id, nom, geom FROM carte_partition(''1885-06-01'', ''canton'', ''01'');';

-- ---------------------------------------------------------------------------
-- § 5. La recette. Ville par ville, à une date : découpée ou laissée entière,
--      et pourquoi ; aire nette contre aire rendue ; recouvrement entre les
--      fractions de la ville tel que la carte le dessine. Attendu : 0,0 m²
--      pour une ville découpée, la commune entière × (n-1) pour une ville
--      laissée entière.
--
--      Ne boucle que sur les départements qui ont une ville à ligne valable à
--      la date : les autres ne changent pas, `check_partition` (84) suffit.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_coupe_partition(p_date date DEFAULT '1900-12-01',
                                                 p_dep text DEFAULT NULL)
RETURNS TABLE (dep text, insee text, commune text, fractions int, morceaux int,
               ha_commune numeric, ha_rendu numeric, recouvrement_m2 numeric,
               verdict text)
LANGUAGE plpgsql VOLATILE
SET search_path = histgis, public
AS $$
#variable_conflict use_column
DECLARE
    d text;
BEGIN
    -- `84` rejoué après `99` remet sa propre `carte_partition_atome` : la
    -- carte ne découpe plus rien, et rien d'autre ne le signalerait.
    IF position('partition_coupe_un_dep' IN
                pg_get_functiondef('histgis.carte_partition_atome(date, text)'::regprocedure)) = 0 THEN
        RAISE WARNING '84 a été rejoué après 99 : carte_partition_atome ne découpe plus '
                      'les villes. Rejouer sql/99_partition_coupes.sql.';
    END IF;

    DROP TABLE IF EXISTS t99_bilan;
    CREATE TEMP TABLE t99_bilan (
        p_date date, dep text, insee text, fractions int, morceaux int,
        ha_commune numeric, ha_rendu numeric, refus text,
        par_la_mere boolean) ON COMMIT DROP;
    DROP TABLE IF EXISTS t99_sortie;
    CREATE TEMP TABLE t99_sortie (
        insee text, atom_id text, geom geometry) ON COMMIT DROP;

    FOR d IN
        SELECT DISTINCT u.dep
        FROM   coupe_ville c
        JOIN   atom a ON coupe_cle(a.cassini, a.insee_geofla::text) = c.insee::text
                     AND a.atom_id LIKE '%#%'
        JOIN   membership m ON m.atom_id = a.atom_id AND m.periode @> p_date
        JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
        WHERE  c.periode @> p_date
          AND  (p_dep IS NULL OR u.dep = p_dep)
        ORDER  BY 1
    LOOP
        RAISE NOTICE 'check_coupe_partition : département %', d;
        INSERT INTO t99_sortie
        SELECT coupe_cle(a.cassini, a.insee_geofla::text), s.atom_id, s.geom
        FROM   partition_coupe_un_dep(p_date, d) s
        JOIN   atom a ON a.atom_id = s.atom_id
        WHERE  a.atom_id LIKE '%#%';
        -- PAS de filtre sur `t99_bilan` ici : la sous-requête lirait l'instantané
        -- du début de l'INSERT, d'avant que la fonction ne remplisse le bilan.
        -- Elle rendait un `t99_sortie` vide, donc un recouvrement de 0,0 pour
        -- toutes les villes — y compris celles laissées entières. Éprouvé sur
        -- base jouet le 3 octobre 2026 : 0,0 au lieu de 1 000 000 m².
    END LOOP;

    CREATE INDEX ON t99_sortie USING gist (geom);
    ANALYZE t99_sortie;

    RETURN QUERY
    SELECT b.dep, b.insee, coalesce(n.nom::text, b.insee),
           b.fractions, b.morceaux, b.ha_commune, b.ha_rendu,
           (SELECT round(coalesce(sum(ST_Area(ST_Intersection(x.geom, y.geom))), 0)::numeric, 1)
              FROM t99_sortie x
              JOIN t99_sortie y ON y.insee = x.insee AND x.atom_id < y.atom_id
                               AND x.geom && y.geom AND ST_Intersects(x.geom, y.geom)
             WHERE x.insee = b.insee),
           coalesce('LAISSÉE ENTIÈRE : ' || b.refus, 'découpée')
           || CASE WHEN b.par_la_mere THEN ' (sol repris à la mère, vivante en circo)'
                   ELSE '' END
    FROM   t99_bilan b
    LEFT   JOIN noms_geofla n ON n.insee = b.insee
    ORDER  BY b.dep, b.insee;
END $$;

COMMENT ON FUNCTION check_coupe_partition(date, text) IS
    'Recette de 99 : villes découpées ou laissées entières dans la partition, à une date. Ex : SELECT * FROM check_coupe_partition(''1900-12-01'', ''03'');';

INSERT INTO p99_trace (quoi, cle) VALUES
    ('fonction', 'partition_coupe_un_dep(date, text)'),
    ('fonction', 'carte_partition_atome(date, text) — remplace celle de 84'),
    ('fonction', 'carte_partition(date, text, text) — remplace celle de 84'),
    ('fonction', 'check_coupe_partition(date, text)');

\echo ''
\echo '99 posé. Aucune donnée modifiée. Éprouver dans cet ordre —'
\echo ''
\echo '  -- l Allier : Montluçon et Moulins (1870), Vichy et Cusset (1990)'
\echo '  psql -d histgis -c "SELECT * FROM histgis.check_coupe_partition(''1900-12-01'', ''03'');"'
\echo '  psql -d histgis -c "SELECT * FROM histgis.check_coupe_partition(''1990-12-01'', ''03'');"'
\echo ''
\echo '  -- toutes les villes, à trois dates (des minutes chacune : un treillis par département)'
\echo '  psql -d histgis -c "SELECT * FROM histgis.check_coupe_partition(''1880-12-01'');"'
\echo '  psql -d histgis -c "SELECT * FROM histgis.check_coupe_partition(''1960-12-01'');"'
\echo '  psql -d histgis -c "SELECT * FROM histgis.check_coupe_partition(''2000-12-01'');"'
\echo ''
\echo '  -- et 84 ne doit pas avoir bougé hors fractions : 0,000'
\echo '  psql -d histgis -c "SELECT * FROM histgis.check_partition(''1900-12-01'', ''03'');"'
\echo ''
\echo 'Attendu : « découpée » et recouvrement 0,0 pour chaque ville conforme à la'
\echo 'recette de 98 ; ha_rendu = ha_commune. Une « LAISSÉE ENTIÈRE » dit pourquoi.'
