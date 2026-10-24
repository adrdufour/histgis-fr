-- ============================================================================
-- histgis — 127_seine_et_oise_1955_1967.sql : les cantons de la Seine-et-Oise
-- entre le jalon de 1954 et la naissance des nouveaux départements
--
--   ESSAI (défaut) :  psql -d histgis -f sql/127_seine_et_oise_1955_1967.sql
--   POSE          :  psql -d histgis -v poser=on -f sql/127_seine_et_oise_1955_1967.sql
--   DÉFAIRE SEUL  :  psql -d histgis -v defaire=on -f sql/127_seine_et_oise_1955_1967.sql
--   (depuis la RACINE du dépôt : le \copy est relatif au répertoire de lancement)
--
-- Une transaction : sans `-v poser=on`, tout est calculé, affiché, ROLLBACK.
-- Mécanique et trace de `121` : `p127_trace` garde ce qui est inséré, et
-- chaque période d'un autre fichier retirée (ligne entière, même identifiant).
--
-- POURQUOI
-- ========
-- Mesuré le 24 octobre 2026 (`build/diag/petite_couronne_trous.sql`) : la
-- Seine-et-Oise n'avait presque aucun canton de 1955 à 1967. Le jalon de 1954
-- s'arrête au 1er janvier 1955 ; celui de 1968 porte les cantons des nouveaux
-- départements, sous d'autres codes et d'autres noms ; `97`, `120` et `110` ne
-- comblent un trou que si ses deux bords s'accordent. Ici ils ne s'accordent
-- presque jamais : la S&O a été redécoupée en 1964, puis démembrée. Chaville,
-- Garches, Meudon : Sèvres en 1954, Chaville en 1968, rien entre. Et 123
-- communes de l'actuel 78/91/95 ne sont pas même au jalon de 1954 (pages du
-- recensement que l'OCR n'a pas rendues : `cog1954/communes_1954_redecoupe.csv`
-- ne les a pas).
--
-- LES SOURCES — tous les actes cantonaux de S&O de 1941 à 1967
-- =============================================================
-- Les tables analytiques du JO sont lues pour chaque année de 1941 à 1967
-- (`cantons/tables_jo_couverture.csv`). Elles ne donnent en S&O que :
--   * Livilliers au canton de Pontoise — table 1951, p. 5233 ;
--   * Hérouville au canton de Pontoise — table 1959, p. 6086. Date de parution
--     estimée par la page : celle de Vatteville, même page (1959-06-18,
--     `cantons/transferts_tables_jo.csv`) ; effet le lendemain (règle C de `110`).
--     `cantons/transferts_tables.py` l'avait perdue, comme Fressinières ;
--   * Hargeville au canton de Mantes-la-Jolie — D. du 24 août 1962, table 1962,
--     p. 8477. Parution non lue ; effet posé au lendemain de la SIGNATURE
--     (1962-08-25) : quelques jours d'avance au plus ;
--   * les décrets du 28 janvier 1964 (JO du 30, p. 1090-1092) : seize articles,
--     41 cantons → 67. Art. 1er : Méry-sur-Oise à Pontoise, Butry-sur-Oise à
--     L'Isle-Adam (rattachements, effet 1964-01-31, posés par `110`) ; art. 2 à
--     16 : vingt cantons remplacés par quarante-six, effet au premier tour des
--     cantonales, 1964-03-08 (règle C de `110`). Transcrits dans
--     `cantons/composition_complement.csv` (jo = JORF_19640130_25), à trois
--     exceptions près, rendues ici (§ 2) d'après `jorf_txt/JORF_19640130_25_col.txt` :
--     le canton de MONTGERON (art. 9 : Crosne, Draveil, Montgeron,
--     Vigneux-sur-Seine) et SOISY-SUR-SEINE (art. 8, Corbeil-Essonnes-Nord)
--     manquent au CSV ;
--   * le décret n° 66-338 du 2 juin 1966 (JO du 3, p. 4421) crée le canton de
--     Saint-Arnoult-en-Yvelines « en vue de la constitution du conseil général
--     des Yvelines » : il n'a d'effet qu'avec ce conseil, au 1er janvier 1968.
--     Rien à poser en S&O. Les décrets n° 66-339 et 66-340 ne touchent que les
--     arrondissements ; les n° 67-589 à 67-594 sont le jalon de 1968.
-- Le registre `acte_effet` et l'annexe VII n'ajoutent rien en S&O sur la période.
--
-- CE QUI EST POSÉ, ATOME PAR ATOME, DANS LA FENÊTRE [1955-01-01, 1968-01-01)
-- ==========================================================================
-- 1. Le canton de 1955 (« C55 ») :
--      * celui du jalon de 1954 pour l'atome (1954-07-01) ;
--      * sinon, pour une commune absente du jalon, le canton de 1940 (TRF-GIS),
--        corrigé des actes 1941-1954 ci-dessus (Livilliers). Aucun acte ne
--        touche les autres : c'est la règle d'absence d'acte de `110` et `121`,
--        étendue à 1941-1954 et marquée `trf1940` dans la recette.
-- 2. Les rattachements datés (Hérouville, Hargeville, Méry, Butry, Achères).
-- 3. Au 1964-03-08, le canton du décret si la commune y est NOMMÉE ; si elle
--    ne l'est pas et que son canton n'est pas remplacé, il continue jusqu'en
--    1968 ; si son canton est remplacé et qu'elle n'est nommée nulle part, rien
--    (recette 4, attendu : vide).
-- 4. Garde-fou : une commune nommée en 1964 dans un canton créé « en
--    remplacement du canton X » doit avoir X pour C55. Sinon rien n'est posé
--    avant 1964 pour elle (recette 4).
--
-- LES QUATRE VILLES DIVISÉES EN 1964 NE REÇOIVENT RIEN DE 1964 À 1968
-- ===================================================================
-- Argenteuil (Nord / Sud, par une liste de rues), Sarcelles (Écouen-Lochères /
-- Sarcelles-Centre, par l'axe de la déviation de la RN 16), Corbeil-Essonnes
-- (Nord / Sud, « tracé vert / tracé rouge » d'un plan annexé non publié) et
-- Versailles (quatre cantons, même chose). La trame n'a pas les fractions qui
-- suivent ces lignes. L'atome d'Essonnes (fusionnée dans Corbeil en 1951) suit
-- Corbeil. Elles gardent leur canton jusqu'au 1964-03-08.
--
-- LES UNITÉS DE 1964-1967 SONT DU DÉPARTEMENT 78
-- ==============================================
-- `110` avait posé 59 rattachements au 1964-03-08 sous les unités de 1968 du
-- même nom (9237 Sèvres, 9324 Le Raincy, 9525 Taverny…), qui sont des 92, 93,
-- 94, 91, 95. L'export range un atome par le `dep` de l'unité : la S&O de 1965
-- serait coupée en deux, ses cantons dans le 92, sa circonscription dans le
-- 78 — le défaut du « 99 fantôme » (JOURNAL, 6 septembre 2026). Et `113` borne
-- la vie d'un atome par ses cantons DU DÉPARTEMENT : la circonscription de 1958
-- s'y arrêterait au 1964-03-08. Ce fichier retire donc ces 59 périodes (trace,
-- restaurées par `-v defaire=on`) et pose :
--   * le canton qui GARDE son nom sous l'unité d'avant 1964 (7836 Sèvres,
--     7804 Boissy-Saint-Léger, 7810 Écouen, renommé Écouen-Lochères par une
--     version…) ;
--   * les 25 cantons nouveaux (Argenteuil-Nord n'a que sa fraction de ville)
--     sous une unité créée ici, `C78-<nom>`, comme `117` (`C17-Rochefort`).
-- Trois périodes de `110` en furent la preuve par l'erreur : Andilly, Margency
-- et Soisy-sous-Montmorency, au canton de MONTMORENCY en 1964 (art. 3),
-- étaient posées à l'unité de Soisy-sous-Montmorency, canton créé en 1967.
--
-- APRÈS CE FICHIER : `113` (par la séquence du README, § 4, point 3), `122`.
-- AVANT de rejouer `110` : défaire celui-ci (`-v defaire=on`), rejouer, reposer.
-- ============================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\if :{?poser}
\else
\set poser off
\endif
\if :{?defaire}
\else
\set defaire off
\endif

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Défaire le passage précédent
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS p127_trace (
    quoi          text   NOT NULL CHECK (quoi IN ('insere', 'retire', 'unit', 'version')),
    membership_id bigint,
    atom_id       text,
    unit_id       text,
    niveau        text,
    ancien_from   date,
    ancien_to     date,
    pose          timestamptz NOT NULL DEFAULT now()
);
DELETE FROM membership m USING p127_trace t
 WHERE t.quoi = 'insere' AND t.membership_id = m.membership_id;
INSERT INTO membership (membership_id, atom_id, unit_id, niveau, valid_from, valid_to)
OVERRIDING SYSTEM VALUE
SELECT membership_id, atom_id, unit_id, niveau, ancien_from, ancien_to
  FROM p127_trace WHERE quoi = 'retire';
DELETE FROM unit_version v USING p127_trace t
 WHERE t.quoi = 'version' AND t.unit_id = v.unit_id
   AND v.valid_from = t.ancien_from AND v.valid_to = t.ancien_to;
DELETE FROM unit u USING p127_trace t
 WHERE t.quoi = 'unit' AND t.unit_id = u.unit_id;
TRUNCATE p127_trace;

\if :defaire
\echo '== 127 DÉFAIT (COMMIT) : insertions et unités retirées, périodes de 110 rendues.'
COMMIT;
\q
\endif

-- ---------------------------------------------------------------------------
-- 2. Les lectures
-- ---------------------------------------------------------------------------
\set debut '1955-01-01'
\set refonte '1964-03-08'
\set fin '1968-01-01'

-- Le décret du 28 janvier 1964, tel que `composition_complement.csv` le porte
CREATE TEMP TABLE t127_csv (
    jo text, decret text, date date, dep text, canton text, nom_texte text,
    insee text, nom_ref text, dep_insee text, appariement text, attribution text,
    legifrance_url text);
\copy t127_csv FROM 'cantons/composition_complement.csv' WITH (FORMAT csv, HEADER true)

CREATE TEMP TABLE t127_compo AS
SELECT canton, insee, nom_texte, 'composition_complement.csv'::text AS source
  FROM t127_csv
 WHERE jo = 'JORF_19640130_25' AND dep IN ('78', '91', '92', '93', '94', '95')
   AND insee <> '';
-- ce que le CSV n'a pas transcrit (JO du 30 janvier 1964, p. 1090-1091)
INSERT INTO t127_compo VALUES
    ('Montgeron', '91191', 'Crosne', 'JO art. 9'),
    ('Montgeron', '91201', 'Draveil', 'JO art. 9'),
    ('Montgeron', '91421', 'Montgeron', 'JO art. 9'),
    ('Montgeron', '91657', 'Vigneux-sur-Seine', 'JO art. 9'),
    ('Corbeil-Essonnes-Nord', '91600', 'Soisy-sur-Seine', 'JO art. 8');

-- Canton de 1964 → unité (dep 78) et canton remplacé
CREATE TEMP TABLE t127_unite (
    canton text PRIMARY KEY, unit_id text NOT NULL, remplace text[] NOT NULL,
    cree boolean NOT NULL, nom text NOT NULL);
INSERT INTO t127_unite VALUES
-- art. 2
('Boissy-Saint-Léger',       '7804',                       '{7804}', false, 'Boissy-Saint-Léger'),
('Chennevières-sur-Marne',   'C78-Chennevières-sur-Marne', '{7804}', true,  'Chennevières-sur-Marne'),
-- art. 3
('Montmorency',              '7829',                       '{7829}', false, 'Montmorency'),
('Enghien-les-Bains',        'C78-Enghien-les-Bains',      '{7829}', true,  'Enghien-les-Bains'),
-- art. 4
('Taverny',                  '7837',                       '{7837}', false, 'Taverny'),
('Saint-Leu-la-Forêt',       'C78-Saint-Leu-la-Forêt',     '{7837}', true,  'Saint-Leu-la-Forêt'),
-- art. 5
('Poissy',                   '7831',                       '{7831}', false, 'Poissy'),
('Conflans-Sainte-Honorine', 'C78-Conflans-Sainte-Honorine','{7831}', true, 'Conflans-Sainte-Honorine'),
-- art. 6 (Achères vient de Maisons-Laffitte : rattachement, § 3)
('Saint-Germain-en-Laye',    '7835',                       '{7835}', false, 'Saint-Germain-en-Laye'),
('Chatou',                   'C78-Chatou',                 '{7835}', true,  'Chatou'),
-- art. 7
('Ecouen-Lochères',          '7810',                       '{7810}', false, 'Écouen-Lochères'),
('Sarcelles-Centre',         'C78-Sarcelles-Centre',       '{7810}', true,  'Sarcelles-Centre'),
-- art. 8
('Corbeil-Essonnes-Nord',    'C78-Corbeil-Essonnes-Nord',  '{7807}', true,  'Corbeil-Essonnes-Nord'),
('Corbeil-Essonnes-Sud',     'C78-Corbeil-Essonnes-Sud',   '{7807}', true,  'Corbeil-Essonnes-Sud'),
-- art. 9
('Villeneuve-Saint-Georges', '7841',                       '{7841}', false, 'Villeneuve-Saint-Georges'),
('Montgeron',                'C78-Montgeron',              '{7841}', true,  'Montgeron'),
('Brunoy',                   'C78-Brunoy',                 '{7841}', true,  'Brunoy'),
-- art. 10
('Aulnay-sous-Bois',         '7803',                       '{7803}', false, 'Aulnay-sous-Bois'),
('Blanc-Mesnil',             'C78-Le-Blanc-Mesnil',        '{7803}', true,  'Le Blanc-Mesnil'),
('Sevran',                   'C78-Sevran',                 '{7803}', true,  'Sevran'),
-- art. 11
('Raincy',                   '7833',                       '{7833}', false, 'Le Raincy'),
('Livry-Gargan',             'C78-Livry-Gargan',           '{7833}', true,  'Livry-Gargan'),
('Neuilly-Plaisance',        'C78-Neuilly-Plaisance',      '{7833}', true,  'Neuilly-Plaisance'),
-- art. 12
('Marly-le-Roi',             '7824',                       '{7824}', false, 'Marly-le-Roi'),
('Rueil-Malmaison',          'C78-Rueil-Malmaison',        '{7824}', true,  'Rueil-Malmaison'),
('Celle-Saint-Cloud',        'C78-La-Celle-Saint-Cloud',   '{7824}', true,  'La Celle-Saint-Cloud'),
-- art. 13
('Sèvres',                   '7836',                       '{7836}', false, 'Sèvres'),
('Meudon',                   'C78-Meudon',                 '{7836}', true,  'Meudon'),
('Saint-Cloud',              'C78-Saint-Cloud',            '{7836}', true,  'Saint-Cloud'),
-- art. 14 (Argenteuil-Nord : la seule fraction de ville, rien à porter)
('Argenteuil-Sud',           'C78-Argenteuil-Sud',         '{7801}', true,  'Argenteuil-Sud'),
('Cormeilles-en-Parisis',    'C78-Cormeilles-en-Parisis',  '{7801}', true,  'Cormeilles-en-Parisis'),
('Houilles',                 'C78-Houilles',               '{7801}', true,  'Houilles'),
-- art. 15
('Longjumeau',               '7818',                       '{7818}', false, 'Longjumeau'),
('Massy',                    'C78-Massy',                  '{7818}', true,  'Massy'),
('Villeneuve-le-Roi',        'C78-Villeneuve-le-Roi',      '{7818}', true,  'Villeneuve-le-Roi'),
('Athis-Mons',               'C78-Athis-Mons',             '{7818}', true,  'Athis-Mons'),
('Savigny-sur-Orge',         'C78-Savigny-sur-Orge',       '{7818}', true,  'Savigny-sur-Orge'),
('Juvisy-sur-Orge',          'C78-Juvisy-sur-Orge',        '{7818}', true,  'Juvisy-sur-Orge'),
-- art. 16
('Versailles-Nord',          '7838',                       '{7838,7839,7840}', false, 'Versailles-Nord'),
('Versailles-Nord-Ouest',    'C78-Versailles-Nord-Ouest',  '{7838,7839,7840}', true,  'Versailles-Nord-Ouest'),
('Versailles-Ouest',         '7839',                       '{7838,7839,7840}', false, 'Versailles-Ouest'),
('Versailles-Sud',           '7840',                       '{7838,7839,7840}', false, 'Versailles-Sud');

-- Les villes divisées par le décret : aucun canton de 1964 à 1968
CREATE TEMP TABLE t127_divisee (insee text PRIMARY KEY, nom text);
INSERT INTO t127_divisee VALUES
    ('95018', 'Argenteuil'), ('95585', 'Sarcelles'), ('91174', 'Corbeil-Essonnes'),
    ('78221', 'Essonnes (dans Corbeil-Essonnes depuis 1951)'), ('78646', 'Versailles');

-- Les rattachements datés. `c55` : l'acte d'avant 1955 qui fixe le canton de
-- 1955 d'une commune absente du jalon.
CREATE TEMP TABLE t127_acte (
    insee text, effet date, unit_id text, c55 boolean, source text);
INSERT INTO t127_acte VALUES
    ('95341', '1955-01-01', '7832', true,  'Livilliers à Pontoise, table 1951 p. 5233'),
    ('95308', '1959-06-19', '7832', false, 'Hérouville à Pontoise, table 1959 p. 6086 (parution estimée 1959-06-18)'),
    ('78300', '1962-08-25', '7822', false, 'Hargeville à Mantes-la-Jolie, D. 24 août 1962, table 1962 p. 8477'),
    ('95394', '1964-01-31', '7832', false, 'Méry-sur-Oise à Pontoise, D. 28 janv. 1964 art. 1er'),
    ('95120', '1964-01-31', '7815', false, 'Butry-sur-Oise à L''Isle-Adam, D. 28 janv. 1964 art. 1er'),
    ('78005', '1964-01-31', '7835', false, 'Achères à Saint-Germain-en-Laye, D. 28 janv. 1964 art. 6');

DO $$
DECLARE n int;
BEGIN
    SELECT count(*) INTO n FROM t127_compo c
     WHERE NOT EXISTS (SELECT 1 FROM t127_unite u WHERE u.canton = c.canton);
    IF n > 0 THEN RAISE EXCEPTION '% ligne(s) du décret sans unité dans t127_unite', n; END IF;
    SELECT count(*) INTO n FROM (SELECT insee FROM t127_compo GROUP BY 1 HAVING count(*) > 1) x;
    IF n > 0 THEN RAISE EXCEPTION '% commune(s) nommée(s) dans deux cantons de 1964', n; END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 3. Les porteurs, leur canton de 1955, et la suite voulue
-- ---------------------------------------------------------------------------
-- Porteur : un atome au jalon de 1954 dans une unité de S&O (78xx), ou, pour
-- une commune absente du jalon, un atome qui portait un canton de S&O en 1940.
CREATE TEMP TABLE t127_porteur AS
SELECT DISTINCT ON (m.atom_id) m.atom_id, a.cassini, a.insee_geofla AS insee,
       m.unit_id AS c55, 'jalon1954'::text AS origine
  FROM membership m JOIN atom a USING (atom_id)
 WHERE m.niveau = 'canton' AND m.unit_id ~ '^78[0-9]{2}$'
   AND m.periode @> date '1954-07-01'
 ORDER BY m.atom_id;
INSERT INTO t127_porteur
SELECT DISTINCT ON (m.atom_id) m.atom_id, a.cassini, a.insee_geofla, m.unit_id, 'trf1940'
  FROM membership m JOIN atom a USING (atom_id)
 WHERE m.niveau = 'canton' AND m.unit_id ~ '^78[0-9]{2}$'
   AND m.valid_to = '1941-01-01'
   AND NOT EXISTS (SELECT 1 FROM membership k JOIN atom b USING (atom_id)
                    WHERE b.cassini = a.cassini AND k.niveau = 'canton'
                      AND k.periode @> date '1954-07-01')
   AND NOT EXISTS (SELECT 1 FROM t127_porteur p WHERE p.atom_id = m.atom_id)
 ORDER BY m.atom_id;
UPDATE t127_porteur p SET c55 = t.unit_id, origine = origine || '+acte'
  FROM t127_acte t WHERE t.c55 AND t.insee = p.insee AND p.origine = 'trf1940';

-- Le canton de 1964 de chaque porteur
CREATE TEMP TABLE t127_porteur64 AS
SELECT p.*, c.canton AS canton64, u.unit_id AS u64, u.remplace,
       (d.insee IS NOT NULL) AS divisee,
       (SELECT t.unit_id FROM t127_acte t
         WHERE NOT t.c55 AND t.insee = p.insee AND t.effet <= :'refonte'
         ORDER BY t.effet DESC LIMIT 1) AS dernier_acte
  FROM t127_porteur p
  LEFT JOIN t127_compo c ON c.insee = p.insee
  LEFT JOIN t127_unite u ON u.canton = c.canton
  LEFT JOIN t127_divisee d ON d.insee = p.insee;

-- verdict : 'ok', 'contredit' (C55 n'est pas un canton remplacé par celui qui
-- la nomme), 'non_nommee' (canton remplacé, commune nommée nulle part)
ALTER TABLE t127_porteur64 ADD COLUMN verdict text;
UPDATE t127_porteur64 SET verdict = CASE
    WHEN divisee THEN 'divisee'
    WHEN u64 IS NOT NULL AND NOT (coalesce(dernier_acte, c55) = ANY (remplace)) THEN 'contredit'
    WHEN u64 IS NULL AND coalesce(dernier_acte, c55) IN
         (SELECT DISTINCT unnest(remplace) FROM t127_unite) THEN 'non_nommee'
    ELSE 'ok' END;

-- La suite voulue sur la fenêtre (unit_id NULL : rien)
CREATE TEMP TABLE t127_cible (atom_id text, unit_id text, valid_from date, valid_to date, motif text);
-- avant 1964 : C55, coupé par les actes datés
INSERT INTO t127_cible
SELECT p.atom_id, s.unit_id, s.du, s.au, s.motif
  FROM t127_porteur64 p
  CROSS JOIN LATERAL (
      WITH b AS (
          SELECT :'debut'::date AS du, p.c55 AS unit_id, 'C55 ' || p.origine AS motif
          UNION ALL
          SELECT t.effet, t.unit_id, t.source FROM t127_acte t
           WHERE NOT t.c55 AND t.insee = p.insee AND t.effet < :'refonte')
      SELECT unit_id, du, coalesce(lead(du) OVER (ORDER BY du), :'refonte'::date) AS au, motif FROM b
  ) s
 WHERE p.verdict <> 'contredit';
-- de 1964 à 1968
INSERT INTO t127_cible
SELECT p.atom_id,
       CASE p.verdict WHEN 'ok' THEN coalesce(p.u64, p.dernier_acte, p.c55) END,
       :'refonte', :'fin',
       CASE WHEN p.verdict <> 'ok' THEN 'rien : ' || p.verdict
            WHEN p.u64 IS NOT NULL THEN 'décret du 28 janvier 1964 : ' || p.canton64
            ELSE 'canton non remplacé en 1964' END
  FROM t127_porteur64 p;
-- les porteurs « contredits » reçoivent le décret de 1964, rien avant
UPDATE t127_cible c SET unit_id = p.u64
  FROM t127_porteur64 p
 WHERE p.atom_id = c.atom_id AND p.verdict = 'contredit' AND c.valid_from = :'refonte';

-- ---------------------------------------------------------------------------
-- 4. Recettes avant pose
-- ---------------------------------------------------------------------------
\echo ''
\echo '=== 4. Porteurs par origine et par verdict ==='
SELECT origine, verdict, count(*) AS atomes, count(DISTINCT insee) AS communes
  FROM t127_porteur64 GROUP BY 1, 2 ORDER BY 1, 2;

\echo ''
\echo '=== 4 bis. Hors « ok » : ce qui n''est pas posé, nommé (divisée : rien de 1964 à 1968) ==='
SELECT p.verdict, p.insee,
       (SELECT nccenr FROM cog_commune_src s WHERE s.dep || s.com = p.insee ORDER BY annee DESC LIMIT 1) AS nom,
       p.atom_id, p.c55, unit_nom(p.c55, '1960-01-01') AS canton_1955, p.canton64
  FROM t127_porteur64 p WHERE p.verdict <> 'ok' ORDER BY 1, 2, 4;

\echo ''
\echo '=== 4 ter. Communes nommées en 1964 sans porteur (attendu : rien) ==='
SELECT c.* FROM t127_compo c
 WHERE NOT EXISTS (SELECT 1 FROM t127_porteur p WHERE p.insee = c.insee);

-- ---------------------------------------------------------------------------
-- 5. Ce qui est retiré à `110` : ses périodes de S&O sous des unités hors 78
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE t127_retrait AS
SELECT m.* FROM membership m
  JOIN p110_trace t ON t.quoi = 'membership' AND t.cle = m.membership_id::text
  JOIN unit u ON u.unit_id = m.unit_id AND u.niveau = m.niveau
 WHERE m.niveau = 'canton' AND u.dep <> '78'
   AND m.atom_id IN (SELECT atom_id FROM t127_porteur)
   AND m.valid_from >= :'refonte' AND m.valid_to <= :'fin';

\echo ''
\echo '=== 5. Périodes de 110 retirées, par unité ==='
SELECT r.unit_id, unit_nom(r.unit_id, r.valid_from) AS nom, count(*) AS periodes,
       string_agg(DISTINCT a.insee_geofla, ' ') AS communes
  FROM t127_retrait r JOIN atom a USING (atom_id) GROUP BY 1, 2 ORDER BY 1;

-- les trous : la fenêtre moins ce qui reste en base une fois `t127_retrait` ôté
CREATE TEMP TABLE t127_pose AS
WITH occ AS (
    SELECT m.atom_id, m.periode FROM membership m
     WHERE m.niveau = 'canton' AND m.atom_id IN (SELECT atom_id FROM t127_porteur)
       AND m.periode && daterange(:'debut', :'fin', '[)')
       AND m.membership_id NOT IN (SELECT membership_id FROM t127_retrait)
), libre AS (
    SELECT c.atom_id, c.unit_id, c.motif,
           unnest(datemultirange(daterange(c.valid_from, c.valid_to, '[)'))
                  - coalesce((SELECT range_agg(o.periode) FROM occ o WHERE o.atom_id = c.atom_id),
                             '{}'::datemultirange)) AS r
      FROM t127_cible c WHERE c.unit_id IS NOT NULL AND c.valid_from < c.valid_to
)
SELECT atom_id, unit_id, lower(r) AS valid_from, upper(r) AS valid_to, motif FROM libre;

\echo ''
-- Les cantons du jalon de 1968 qui commencent au 1967-09-24 (cantonales des
-- nouveaux départements) sont le bord droit, pas une contradiction.
\echo '=== 6. Ce qui reste en base dans la fenêtre et contredit la cible (attendu : rien) ==='
SELECT m.atom_id, a.insee_geofla, m.unit_id, m.valid_from, m.valid_to, c.unit_id AS cible, c.motif
  FROM membership m JOIN atom a USING (atom_id)
  JOIN t127_cible c ON c.atom_id = m.atom_id
   AND daterange(c.valid_from, c.valid_to, '[)') && m.periode
 WHERE m.niveau = 'canton' AND c.unit_id IS NOT NULL AND c.unit_id <> m.unit_id
   AND m.membership_id NOT IN (SELECT membership_id FROM t127_retrait)
   AND m.valid_from <> '1967-09-24'
 ORDER BY 2, 4;

\echo ''
\echo '=== 7. À poser, par motif ==='
SELECT split_part(motif, ' :', 1) AS motif, count(*) AS periodes, count(DISTINCT atom_id) AS atomes
  FROM t127_pose GROUP BY 1 ORDER BY 1;

-- ---------------------------------------------------------------------------
-- 8. Pose
-- ---------------------------------------------------------------------------
\if :poser
INSERT INTO p127_trace (quoi, membership_id, atom_id, unit_id, niveau, ancien_from, ancien_to)
SELECT 'retire', membership_id, atom_id, unit_id, niveau, valid_from, valid_to FROM t127_retrait;
DELETE FROM membership WHERE membership_id IN (SELECT membership_id FROM t127_retrait);

INSERT INTO unit (unit_id, niveau, dep, code, regime, segment_depuis, nom, provisoire)
SELECT unit_id, 'canton', '78', unit_id, NULL, NULL, nom, true
  FROM t127_unite WHERE cree AND unit_id IN (SELECT unit_id FROM t127_pose);
INSERT INTO p127_trace (quoi, unit_id)
SELECT 'unit', unit_id FROM t127_unite WHERE cree AND unit_id IN (SELECT unit_id FROM t127_pose);

-- un canton qui garde son unité mais change de nom
INSERT INTO unit_version (unit_id, nom, valid_from, valid_to)
SELECT u.unit_id, u.nom, :'refonte', :'fin' FROM t127_unite u
 WHERE NOT u.cree AND u.nom <> (SELECT n.nom FROM unit n WHERE n.unit_id = u.unit_id);
INSERT INTO p127_trace (quoi, unit_id, ancien_from, ancien_to)
SELECT 'version', u.unit_id, :'refonte', :'fin' FROM t127_unite u
 WHERE NOT u.cree AND u.nom <> (SELECT n.nom FROM unit n WHERE n.unit_id = u.unit_id);

WITH ins AS (
    INSERT INTO membership (atom_id, unit_id, niveau, valid_from, valid_to)
    SELECT atom_id, unit_id, 'canton', valid_from, valid_to FROM t127_pose
    RETURNING membership_id, atom_id, unit_id, niveau, valid_from, valid_to
)
INSERT INTO p127_trace (quoi, membership_id, atom_id, unit_id, niveau, ancien_from, ancien_to)
SELECT 'insere', membership_id, atom_id, unit_id, niveau, valid_from, valid_to FROM ins;

ANALYZE membership;

\echo ''
\echo '=== 9. Trace ==='
SELECT quoi, count(*) FROM p127_trace GROUP BY 1 ORDER BY 1;

\echo ''
\echo '=== 10. Communes de l''ex-S&O sans canton au 1er juillet, 1955-1967 ==='
WITH c AS (SELECT DISTINCT cassini, left(insee, 2) AS dep FROM t127_porteur)
SELECT c.dep, d.an,
       count(*) FILTER (WHERE NOT EXISTS (
           SELECT 1 FROM membership m JOIN atom a USING (atom_id)
            WHERE a.cassini = c.cassini AND m.niveau = 'canton'
              AND m.periode @> make_date(d.an, 7, 1))) AS sans_canton
  FROM c CROSS JOIN generate_series(1955, 1967) d(an)
 GROUP BY 1, 2 HAVING count(*) FILTER (WHERE NOT EXISTS (
           SELECT 1 FROM membership m JOIN atom a USING (atom_id)
            WHERE a.cassini = c.cassini AND m.niveau = 'canton'
              AND m.periode @> make_date(d.an, 7, 1))) > 0
 ORDER BY 1, 2;

\echo '== 127 POSÉ (COMMIT).'
COMMIT;
\else
\echo '== 127 À BLANC (ROLLBACK) : relancer avec -v poser=on.'
ROLLBACK;
\endif
