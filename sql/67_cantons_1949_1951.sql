-- ============================================================================
-- histgis — 67_cantons_1949_1951.sql : les trois cantons créés entre 1940 et 1954
--
--   psql -d histgis -1 -f sql/67_cantons_1949_1951.sql
--
-- LE CAS, ET POURQUOI IL SE REPRODUIT
-- ===================================
-- `unit` est faite de deux sources : TRF-GIS (1870-1940) et le COG (1999-2012).
-- **Un canton créé entre les deux et disparu avant 1999 n'est dans ni l'une ni
-- l'autre.** C'était Forbach-II pour 1968 (`60`) ; c'est ici trois cantons de
-- 1949-1951, invisibles à la nomenclature mais cités par le recensement.
--
--   1930   Brive-Sud     D. 13.9.1951   dédoublement de Brive
--   4630   Sousceyrac    D. 5.9.1949    Latronquière + Bretenoux + Saint-Céré
--   0631   Tende         D. 10.9.1951   division de Breil
--
-- Source : annexe VII de Gaudillère, transcrite dans `cantons/annexe_vii.csv`.
--
-- DEUX SIGNAUX INDÉPENDANTS LES CONFIRMENT
-- ========================================
-- 1. **L'atlas les date**, au décret près.
-- 2. **Leur numéro est en FIN de série** : 1930 quand la Corrèze s'arrête à
--    1929, 4630 quand le Lot s'arrête à 4629, 0631 quand les Alpes-Maritimes
--    s'arrêtent à 0630. Un canton créé reçoit le numéro suivant, il ne s'insère
--    pas dans l'ordre alphabétique.
--
-- C'est exactement le motif de Forbach-II — 5740 pour une série finissant à
-- 5736 — et la coïncidence des deux signaux vaut mieux que chacun seul : l'un
-- vient d'un livre, l'autre de la numérotation.
--
-- TENDE ET LA BRIGUE, UN CAS PARTICULIER QU'IL FAUT CONNAÎTRE
-- ===========================================================
-- Les deux communes du canton 0631 n'étaient pas françaises avant 1947 : le
-- traité de Paris les a rattachées à la France, et le canton a suivi en 1951.
-- Elles n'existent donc pas dans TRF-GIS (1870-1940) pour une raison qui n'a
-- rien à voir avec l'OCR — et si elles manquent à `cm_atome`, le § 4 le dira.
--
-- LE CONTRÔLE EST DANS LE FICHIER
-- ===============================
-- La composition attendue est écrite ci-dessous, commune par commune, et la
-- section 3 lève une exception si la lecture s'en écarte. Comme pour
-- Forbach-II : rien n'est posé si la concordance n'est pas parfaite.
--
-- **Réserve, et elle est réelle** : ici la composition n'est PAS confrontée à
-- une source publiée indépendante. Elle est celle que NOUS avons lue. Les
-- treize communes sont toutes en appariement `ferme` — exact et unique — mais
-- cela vérifie la cohérence de notre lecture, pas son exactitude. Forbach-II
-- avait Wikipédia ; ces trois-là attendent leur contrôle externe.
--
-- Prérequis : sql/66_cog1954_stage.sql.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\set jalon_debut '1954-01-01'
\set jalon_fin   '1955-01-01'

\echo ''
\echo '============================================================'
\echo ' Trois cantons créés entre 1940 et 1954'
\echo '============================================================'

DO $$
BEGIN
    IF to_regclass('histgis.c54_lien') IS NULL THEN
        RAISE EXCEPTION 'PRÉREQUIS : jouer sql/66_cog1954_stage.sql.';
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. Défaire le passage précédent, AVANT tout jugement
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS c67_trace (
    quoi text NOT NULL, cle text NOT NULL,
    pose timestamptz NOT NULL DEFAULT now()
);

DELETE FROM membership m USING c67_trace t
 WHERE t.quoi = 'membership' AND t.cle = m.membership_id::text;
DELETE FROM unit u USING c67_trace t
 WHERE t.quoi = 'unit' AND t.cle = u.unit_id;
TRUNCATE c67_trace;

-- ---------------------------------------------------------------------------
-- 2. La composition attendue, transcrite de notre lecture
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS c67_attendu;
CREATE TABLE c67_attendu (canton_id text, nom_canton text, dep char(2),
                          insee char(5), nom text, decret text);
INSERT INTO c67_attendu VALUES
  ('1930', 'Brive-Sud', '19', '19043', 'La Chapelle-aux-Brocs', 'D. 13.9.1951'),
  ('1930', 'Brive-Sud', '19', '19063', 'Cosnac',                'D. 13.9.1951'),
  ('1930', 'Brive-Sud', '19', '19077', 'Estivals',              'D. 13.9.1951'),
  ('1930', 'Brive-Sud', '19', '19093', 'Jugeals-Nazareth',      'D. 13.9.1951'),
  ('1930', 'Brive-Sud', '19', '19123', 'Malemort-sur-Corrèze',  'D. 13.9.1951'),
  ('1930', 'Brive-Sud', '19', '19147', 'Nespouls',              'D. 13.9.1951'),
  ('1930', 'Brive-Sud', '19', '19151', 'Noailles',              'D. 13.9.1951'),
  ('4630', 'Sousceyrac', '46', '46071', 'Comiac',           'D. 5.9.1949'),
  ('4630', 'Sousceyrac', '46', '46141', 'Lacam-d''Ourcet',  'D. 5.9.1949'),
  ('4630', 'Sousceyrac', '46', '46150', 'Lamativie',        'D. 5.9.1949'),
  ('4630', 'Sousceyrac', '46', '46311', 'Sousceyrac',       'D. 5.9.1949'),
  ('0631', 'Tende', '06', '06162', 'La Brigue', 'D. 10.9.1951'),
  ('0631', 'Tende', '06', '06163', 'Tende',     'D. 10.9.1951');

\echo ''
\echo '-- 2. ce que le recensement a lu pour ces trois cantons'
SELECT l.canton_id, l.insee, l.nom_lu, l.appariement
FROM   c54_lien l
WHERE  l.canton_id IN ('1930', '4630', '0631')
ORDER  BY l.canton_id, l.insee;

-- ---------------------------------------------------------------------------
-- 3. LE CONTRÔLE — il est le garde-fou
--
-- La comparaison porte sur le CODE INSEE, jamais sur le nom : le nom vient de
-- l'OCR, et le comparer à lui-même ne prouverait rien.
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 3. confrontation'
SELECT a.canton_id, a.nom_canton, a.decret,
       count(*)                                                  AS attendu,
       count(*) FILTER (WHERE l.insee IS NOT NULL)               AS concordants,
       (SELECT count(*) FROM c54_lien x
         WHERE x.canton_id = a.canton_id
           AND NOT EXISTS (SELECT 1 FROM c67_attendu y
                            WHERE y.insee = x.insee
                              AND y.canton_id = a.canton_id))    AS en_trop
FROM   c67_attendu a
LEFT   JOIN c54_lien l ON l.insee = a.insee AND l.canton_id = a.canton_id
GROUP  BY a.canton_id, a.nom_canton, a.decret
ORDER  BY a.canton_id;

DO $$
DECLARE n_att bigint; n_ok bigint; n_sup bigint;
BEGIN
    SELECT count(*) INTO n_att FROM c67_attendu;
    SELECT count(*) INTO n_ok FROM c67_attendu a
      JOIN c54_lien l ON l.insee = a.insee AND l.canton_id = a.canton_id;
    SELECT count(*) INTO n_sup FROM c54_lien x
     WHERE x.canton_id IN ('1930', '4630', '0631')
       AND NOT EXISTS (SELECT 1 FROM c67_attendu y WHERE y.insee = x.insee);

    IF n_ok <> n_att OR n_sup > 0 THEN
        RAISE EXCEPTION 'CONTRÔLE : % / % communes concordent, % en trop. '
                        'Rien n''est posé.', n_ok, n_att, n_sup;
    END IF;
    RAISE NOTICE 'Contrôle : % communes sur %, aucune en trop.', n_ok, n_att;
END $$;

-- ---------------------------------------------------------------------------
-- 4. Ce qui pourrait empêcher la pose
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 4. communes sans atome, ou dont l''atome est déjà pris à cette date'
SELECT l.canton_id, l.insee, l.nom_lu,
       l.atome,
       l.commune_vivante,
       (SELECT m.unit_id FROM membership m
         WHERE m.atom_id = l.atome AND m.niveau = 'canton'
           AND daterange(m.valid_from, m.valid_to, '[)')
               @> :'jalon_debut'::date LIMIT 1)  AS deja_rattache_a
FROM   c54_lien l
WHERE  l.canton_id IN ('1930', '4630', '0631')
  AND  (l.atome IS NULL OR NOT l.commune_vivante
        OR EXISTS (SELECT 1 FROM membership m
                    WHERE m.atom_id = l.atome AND m.niveau = 'canton'
                      AND daterange(m.valid_from, m.valid_to, '[)')
                          @> :'jalon_debut'::date));

\echo ''
\echo '   Tende et La Brigue n''étaient pas françaises avant 1947 : si elles'
\echo '   apparaissent ici sans atome, la cause est le traité de Paris, pas'
\echo '   l''OCR.'

-- ---------------------------------------------------------------------------
-- 5. Les unités, puis les rattachements
-- ---------------------------------------------------------------------------
WITH ins AS (
    INSERT INTO unit (unit_id, niveau, dep, code, regime, segment_depuis,
                      nom, provisoire)
    -- `regime` et `segment_depuis` sont NULS pour un canton — le schéma
    -- l'EXIGE (contrainte `unit_canton_attrs`). Les casts explicites ne sont
    -- pas décoratifs : dans un INSERT … SELECT, un `NULL` nu est typé `text`,
    -- alors que dans un INSERT … VALUES il prend le type de la colonne visée.
    -- `60` écrit les mêmes deux NULL sans cast et passe ; ici la même écriture
    -- échouait sur « segment_depuis is of type smallint ».
    SELECT DISTINCT a.canton_id, 'canton', a.dep, a.canton_id,
           NULL::text, NULL::smallint,
           a.nom_canton, false
    FROM   c67_attendu a
    ON CONFLICT (unit_id) DO NOTHING
    RETURNING unit_id
)
INSERT INTO c67_trace (quoi, cle) SELECT 'unit', unit_id FROM ins;

WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT l.atome, l.canton_id, 'canton',
           :'jalon_debut'::date, :'jalon_fin'::date
    FROM   c54_lien l
    WHERE  l.canton_id IN ('1930', '4630', '0631')
      AND  l.atome IS NOT NULL AND l.commune_vivante AND l.n_atomes = 1
      AND  NOT EXISTS (SELECT 1 FROM membership m
                        WHERE m.atom_id = l.atome AND m.niveau = 'canton'
                          AND daterange(m.valid_from, m.valid_to, '[)')
                              @> :'jalon_debut'::date)
    RETURNING membership_id
)
INSERT INTO c67_trace (quoi, cle) SELECT 'membership', membership_id::text FROM ins;

\echo ''
\echo '-- 5. posé'
SELECT quoi, count(*) FROM c67_trace GROUP BY quoi ORDER BY quoi;

-- ---------------------------------------------------------------------------
-- 6. Recette, lue depuis le modèle
-- ---------------------------------------------------------------------------
\echo ''
\echo '-- 6. recette'
SELECT u.unit_id, u.nom, u.dep,
       (SELECT count(*) FROM membership m
         WHERE m.unit_id = u.unit_id
           AND daterange(m.valid_from, m.valid_to, '[)')
               @> :'jalon_debut'::date)              AS communes_1954
FROM   unit u WHERE u.unit_id IN ('1930', '4630', '0631')
ORDER  BY u.unit_id;

\echo ''
\echo '   ces cantons ne doivent exister QU''en 1954 :'
SELECT unit_id, min(valid_from) AS depuis, max(valid_to) AS jusqu_a
FROM   membership WHERE unit_id IN ('1930', '4630', '0631')
GROUP  BY unit_id ORDER BY unit_id;

\echo ''
\echo '============================================================'
\echo ' Trois cantons posés. Leur composition vient de NOTRE lecture,'
\echo ' pas d''une source publiée : elle est cohérente, pas vérifiée.'
\echo ' Forbach-II avait Wikipédia ; ceux-ci attendent leur contrôle.'
\echo '============================================================'
