-- ============================================================================
-- histgis — 03_functions.sql : requêtes ponctuelles et contrôles d'intégrité
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

-- ---------------------------------------------------------------------------
-- snapshot(date, niveau) : la carte administrative telle qu'elle est à une
-- date donnée. Renvoie une ligne par unité vivante, avec son nom d'époque et
-- la liste de ses atomes — c'est cette liste qui servira au dissolve
-- géométrique quand atom_geom sera peuplée.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION snapshot(p_date date, p_niveau text DEFAULT 'canton')
RETURNS TABLE (
    unit_id  text,
    niveau   text,
    dep      char(2),
    nom      text,
    n_atomes bigint,
    atomes   text[]
)
LANGUAGE sql STABLE AS $$
    SELECT u.unit_id,
           u.niveau,
           u.dep,
           coalesce(uv.nom, u.nom)          AS nom,
           count(*)                         AS n_atomes,
           array_agg(m.atom_id ORDER BY m.atom_id) AS atomes
    FROM   membership m
    JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
    LEFT   JOIN unit_version uv
           ON uv.unit_id = u.unit_id AND uv.periode @> p_date
    WHERE  m.niveau = p_niveau
      AND  m.periode @> p_date
    GROUP  BY u.unit_id, u.niveau, u.dep, coalesce(uv.nom, u.nom);
$$;

COMMENT ON FUNCTION snapshot(date, text) IS
    'Composition des unités d''un niveau à une date. Ex : SELECT * FROM snapshot(''1885-06-01'', ''canton'');';

-- ---------------------------------------------------------------------------
-- unit_nom(unit_id, date) : nom porté par une unité à une date.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION unit_nom(p_unit_id text, p_date date)
RETURNS text LANGUAGE sql STABLE AS $$
    SELECT coalesce(
        (SELECT uv.nom FROM unit_version uv
          WHERE uv.unit_id = p_unit_id AND uv.periode @> p_date),
        (SELECT u.nom FROM unit u WHERE u.unit_id = p_unit_id)
    );
$$;

-- ---------------------------------------------------------------------------
-- count_units(date) : effectifs par niveau, à confronter aux comptes publiés
-- (87-90 départements, 2861-3028 cantons, 526-598 circonscriptions
-- uninominales selon la période).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION count_units(p_date date)
RETURNS TABLE (niveau text, n_unites bigint, n_departements bigint, n_atomes bigint)
LANGUAGE sql STABLE AS $$
    SELECT m.niveau,
           count(DISTINCT m.unit_id),
           count(DISTINCT u.dep),
           count(DISTINCT m.atom_id)
    FROM   membership m
    JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
    WHERE  m.periode @> p_date
    GROUP  BY m.niveau;
$$;

-- ---------------------------------------------------------------------------
-- check_gaps(niveau) : atomes dont la chronologie est trouée — la commune
-- disparaît des nomenclatures puis réapparaît. Attendu, mais à surveiller :
-- un trou long signale plutôt une fusion mal suivie.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_gaps(p_niveau text DEFAULT 'canton')
RETURNS TABLE (atom_id text, trou_debut date, trou_fin date, duree_annees numeric)
LANGUAGE sql STABLE AS $$
    SELECT atom_id, fin_prec, valid_from,
           round(((valid_from - fin_prec) / 365.25)::numeric, 1)
    FROM (
        SELECT m.atom_id, m.valid_from,
               lag(m.valid_to) OVER (PARTITION BY m.atom_id ORDER BY m.valid_from) AS fin_prec
        FROM   membership m
        WHERE  m.niveau = p_niveau
    ) s
    WHERE  fin_prec IS NOT NULL AND valid_from > fin_prec
    ORDER  BY valid_from - fin_prec DESC;
$$;

-- ---------------------------------------------------------------------------
-- check_coverage(date) : communes historiques (Cassini) rattachées à un
-- canton mais pas à une circonscription, ou l'inverse.
-- Le contrôle porte sur cassini et non sur atom_id : une commune éclatée
-- entre plusieurs cantons a des atomes-fractions côté canton, mais un seul
-- atome-commune côté circonscription — comparer atome à atome produirait des
-- faux positifs par construction.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_coverage(p_date date)
RETURNS TABLE (cassini text, present_canton boolean, present_circo boolean)
LANGUAGE sql STABLE AS $$
    WITH vivants AS (
        SELECT a.cassini,
               bool_or(m.niveau = 'canton') AS c,
               bool_or(m.niveau = 'circo')  AS i
        FROM   atom a
        JOIN   membership m ON m.atom_id = a.atom_id AND m.periode @> p_date
        GROUP  BY a.cassini
    )
    SELECT cassini, c, i FROM vivants WHERE NOT (c AND i);
$$;

-- ---------------------------------------------------------------------------
-- check_nesting(date) : cantons dont les atomes se répartissent sur plusieurs
-- circonscriptions. Sous scrutin de liste (circonscription = département)
-- c'est presque toujours vide ; sous scrutin uninominal, un canton partagé
-- entre deux circonscriptions est possible mais mérite vérification.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_nesting(p_date date)
RETURNS TABLE (canton text, nom text, n_circos bigint, circos text[])
LANGUAGE sql STABLE AS $$
    SELECT c.unit_id,
           unit_nom(c.unit_id, p_date),
           count(DISTINCT i.unit_id),
           array_agg(DISTINCT i.unit_id)
    FROM   membership c
    JOIN   membership i
           ON i.atom_id = c.atom_id AND i.niveau = 'circo' AND i.periode @> p_date
    WHERE  c.niveau = 'canton' AND c.periode @> p_date
    GROUP  BY c.unit_id
    HAVING count(DISTINCT i.unit_id) > 1
    ORDER  BY 3 DESC;
$$;

-- ---------------------------------------------------------------------------
-- check_orphans() : unités sans nom (créées d'office au chargement) et
-- incohérences résiduelles.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_orphans()
RETURNS TABLE (probleme text, n bigint, exemples text[])
LANGUAGE sql STABLE AS $$
    SELECT 'unite provisoire (absente des nomenclatures)', count(*),
           (array_agg(unit_id ORDER BY unit_id))[1:5]
    FROM   unit WHERE provisoire
    UNION ALL
    SELECT 'unite sans aucun membership', count(*),
           (array_agg(u.unit_id ORDER BY u.unit_id))[1:5]
    FROM   unit u
    WHERE  NOT EXISTS (SELECT 1 FROM membership m WHERE m.unit_id = u.unit_id)
    UNION ALL
    SELECT 'atome sans aucun membership', count(*),
           (array_agg(a.atom_id ORDER BY a.atom_id))[1:5]
    FROM   atom a
    WHERE  NOT EXISTS (SELECT 1 FROM membership m WHERE m.atom_id = a.atom_id)
    UNION ALL
    SELECT 'atome sans rattachement geometrique (insee_geofla NULL)', count(*),
           (array_agg(a.atom_id ORDER BY a.atom_id))[1:5]
    FROM   atom a WHERE a.insee_geofla IS NULL;
$$;

-- ---------------------------------------------------------------------------
-- Vue de confort : composition courante lisible.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_membership AS
SELECT m.membership_id, m.atom_id, a.cassini, a.fraction,
       m.niveau, m.unit_id, u.dep, unit_nom(m.unit_id, m.valid_from) AS nom_unite,
       m.valid_from, m.valid_to
FROM   membership m
JOIN   atom a USING (atom_id)
JOIN   unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau;
