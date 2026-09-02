-- ===========================================================================
-- diag_passages.sql — QUELS FICHIERS SONT PASSÉS SUR CETTE BASE ?
--
-- LECTURE SEULE. Ne crée que des tables TEMP, ne touche à rien dans `histgis`.
--
--   psql -d histgis -f sql/diag_passages.sql
--
-- ---------------------------------------------------------------------------
-- POURQUOI CE FICHIER EXISTE
--
-- Le 30 août 2026, `80` a découvert que le département `99` était encore en
-- base : `39_meurthe_1870.sql`, joué et déclaré clos le 15 août, avait été
-- défait par un `rebuild.sh` quinze jours plus tôt. Rien ne l'avait signalé,
-- parce que `39` n'a pas de table de trace — RIEN DANS LA BASE NE DIT S'IL EST
-- PASSÉ.
--
-- La convention du dépôt est que tout fichier qui écrit porte une table de
-- trace, et retire son passage avant de recommencer. Ce fichier vérifie la
-- convention elle-même : il confronte l'inventaire des traces ATTENDUES à ce
-- que la base porte réellement.
--
-- ---------------------------------------------------------------------------
-- CE QU'IL PEUT DIRE, ET CE QU'IL NE PEUT PAS
--
-- Une trace présente et peuplée est une PREUVE que le fichier est passé, et
-- `pose` dit quand.
--
-- Une trace absente est une preuve qu'il n'est PAS passé — ou qu'un
-- `DROP SCHEMA` l'a emportée, ce qui revient au même.
--
-- Le § 2 ne prouve rien de tel. Il lit un ÉTAT observable là où il n'y a pas de
-- trace, et un état peut avoir été atteint autrement. Il répond à « la base
-- est-elle dans le bon état ? », jamais à « ce fichier est-il passé ? ». C'est
-- toute la différence, et c'est pour ne pas avoir à s'en contenter qu'il faut
-- donner une trace à `38` et `39`.
--
-- Ni l'horodatage du fichier `.sql` sur le disque, ni l'historique du shell, ne
-- sont des preuves : ils disent qu'une commande a été TAPÉE, pas qu'elle a
-- été COMMITÉE. La base est le seul témoin.
-- ===========================================================================

\set ON_ERROR_STOP on
SET search_path TO histgis, public;

\echo ''
\echo '==========================================================='
\echo '-- 1. Les traces attendues, et ce que la base en porte'
\echo '==========================================================='

-- `hors_chaine` : un fichier que `rejouer_apres_rebuild.sh` n'appelle pas, ou
-- qui n'écrit sa trace que sous `-v appliquer=1`. Son absence est NORMALE et
-- ne doit pas se lire comme un défaut — sinon le diagnostic crie neuf fois et
-- on cesse de le lire. Ce qui le juge est son EFFET, au § 4.
CREATE TEMP TABLE attendu (rang int, fichier text, temoin text, role text,
                           hors_chaine boolean DEFAULT false);

INSERT INTO attendu (rang, fichier, temoin, role) VALUES
  ( 11, '11_scission.sql',              'scission_trace',           'report arrière des communes nées 1871-1940'),
  ( 15, '15_creation_arriere.sql',      'creation_trace',           'communes nées après 1940'),
  ( 21, '21_atomes_modernes.sql',       'atome_moderne_trace',      'atomes 1943-2012'),
  ( 24, '24_canton_moderne.sql',        'canton_moderne_trace',     'cantons 1999-2012'),
  ( 25, '25_pseudo_canton.sql',         'pseudo_canton_trace',      'Marseille et Lyon'),
  ( 27, '27_circo_2012.sql',            'circo_moderne_trace',      'circonscriptions 2009'),
  ( 28, '28_circo_1986.sql',            'circo1986_trace',          'circonscriptions 1986'),
  ( 32, '32_marseille_geom.sql',        'marseille_trace',          'coupes internes de Marseille'),
  ( 37, '37_reparer_encodage.sql',      'encodage_trace',           'CP1252 lu en Latin-1'),
  ( 40, '40_outremer.sql',              'om_trace',                 'outre-mer, espace séparé'),
  ( 40, '40_scission_circo.sql',        'scission_circo_trace',     'comblement de la couche circo'),
  ( 41, '41_retablissement.sql',        'retablissement_trace',     'communes rétablies après Marcellin'),
  ( 42, '42_rattachement_arriere.sql',  'rattachement_arriere_trace','Chisa et Butry-sur-Oise'),
  ( 43, '43_circo_fraction.sql',        'circo_fraction_trace',     'circos des atomes-fractions'),
  ( 44, '44_absorption_ancienne.sql',   'absorption_trace',         'Cherré'),
  ( 46, '46_creation_serie.sql',        'creation_serie_trace',     'communes nées pendant la série'),
  ( 47, '47_circo_mere.sql',            'circo_mere_trace',         'circos par la mère'),
  ( 49, '49_circo_1986_partage.sql',    'circo_partage_trace',      'cantons partagés de 1986'),
  ( 50, '50_noms_perdus_trfgis.sql',    'noms_perdus_trace',        'noms reconstitués'),
  ( 51, '51_circo_1986_correctif.sql',  'circo_correctif_trace',    'correctif 1986'),
  ( 52, '52_paris_circo_1986.sql',      'paris_circo_trace',        'Paris 1986'),
  ( 53, '53_paris_geom_iris.sql',       'paris_geom_trace',         'les 80 quartiers'),
  ( 54, '54_paris_circo_1815.sql',      'paris_1815_trace',         'Paris 1815'),
  ( 55, '55_paris_circo_serie.sql',     'paris_serie_trace',        'Paris, la série'),
  ( 56, '56_paris_circo_1876.sql',      'paris_1876_trace',         'Paris 1876'),
  ( 57, '57_paris_circo_1848.sql',      'paris_1848_trace',         'Paris 1848'),
  ( 59, '59_cog1968_membership.sql',    'c68_trace',                'JALON 1968'),
  ( 59, '59_cog1968_membership.sql',    'c68_qualite',              'qualité de lecture 1968'),
  ( 60, '60_canton_forbach2.sql',       'c60_trace',                'Forbach-2'),
  ( 67, '67_cantons_1949_1951.sql',     'c67_trace',                'créations 1949-1951'),
  ( 68, '68_cog1954_membership.sql',    'c54_trace',                'JALON 1954'),
  ( 68, '68_cog1954_membership.sql',    'c54_qualite',              'qualité de lecture 1954'),
  ( 74, '74_yvelines_1967.sql',         'y67_trace',                'Yvelines 1968'),
  ( 75, '75_composition_1973_1982.sql', 'p75_trace',                'salves 1973 et 1982'),
  ( 75, '75_composition_1973_1982.sql', 'p75_qualite',              'convention de date d''effet'),
  ( 76, '76_composition_salves_restantes.sql','p76_trace',          'salves restantes'),
  ( 76, '76_composition_salves_restantes.sql','p76_qualite',        'incertitude de série'),
  ( 77, '77_transferts_dates.sql',      'p77_trace',                'transferts datés INSEE'),
  ( 77, '77_transferts_dates.sql',      'p77_qualite',              ''),
  ( 79, '79_report_1999_arriere.sql',   'p79_trace',                'REPORT ARRIÈRE depuis 1999'),
  ( 79, '79_report_1999_arriere.sql',   'p79_qualite',              'profondeur et plafond'),
  ( 81, '81_report_1968_avant.sql',     'p81_trace',                'REPORT AVANT depuis 1968'),
  ( 81, '81_report_1968_avant.sql',     'p81_qualite',              'pct_jamais_nommes + dénominateur'),
  ( 82, '82_anr_geom.sql',              'a82_trace',                'trame ANR datée');

UPDATE attendu SET hors_chaine = true WHERE temoin IN (
    'circo_fraction_trace',   -- 43 : exclu de la chaîne EXPRÈS (voir son en-tête)
    'marseille_trace',        -- 32 : attend le géoréférencement, chantier ouvert
    'encodage_trace',         -- 37 : n'écrit sa trace que sous -v appliquer=1
    'noms_perdus_trace');     -- 50 : idem

CREATE TEMP TABLE constate (temoin text PRIMARY KEY, lignes bigint, dernier timestamptz);

-- Le compte se fait en SQL dynamique, et ce n'est pas un raffinement :
-- PostgreSQL résout les relations à l'ANALYSE de la requête. Un
-- `CASE WHEN to_regclass(...) IS NULL THEN 0 ELSE (SELECT count(*) FROM t) END`
-- échoue à la compilation si `t` n'existe pas — c'est exactement le défaut que
-- le banc de `83` a trouvé le 1er septembre 2026. Un garde-fou évalué à
-- l'exécution ne protège pas d'une erreur d'analyse.
DO $$
DECLARE r record; n bigint; d timestamptz;
BEGIN
  FOR r IN SELECT DISTINCT a.temoin FROM attendu a
           WHERE to_regclass('histgis.' || quote_ident(a.temoin)) IS NOT NULL
  LOOP
    EXECUTE format('SELECT count(*) FROM histgis.%I', r.temoin) INTO n;
    d := NULL;
    IF EXISTS (SELECT 1 FROM information_schema.columns
                WHERE table_schema = 'histgis'
                  AND table_name   = r.temoin
                  AND column_name  = 'pose') THEN
      EXECUTE format('SELECT max(pose) FROM histgis.%I', r.temoin) INTO d;
    END IF;
    INSERT INTO constate VALUES (r.temoin, n, d);
  END LOOP;
END $$;

SELECT a.rang AS "#",
       a.fichier,
       a.temoin,
       CASE WHEN c.temoin IS NULL AND a.hors_chaine THEN 'absente — NORMAL, voir § 4'
            WHEN c.temoin IS NULL                    THEN 'ABSENTE — jamais joué'
            WHEN c.lignes = 0 AND a.hors_chaine      THEN 'vide — rien à corriger ?, voir § 4'
            WHEN c.lignes = 0                        THEN 'vide — joué puis défait ?'
            ELSE                                          'présente'
       END                              AS verdict,
       c.lignes,
       c.dernier                        AS dernier_passage,
       a.role
FROM   attendu a
LEFT   JOIN constate c ON c.temoin = a.temoin
ORDER  BY a.rang, a.temoin;

\echo ''
\echo '-- 1 bis. Le résumé : combien de fichiers manquent à l''appel'

SELECT count(*) FILTER (WHERE c.temoin IS NOT NULL AND c.lignes > 0)     AS passes,
       count(*) FILTER (WHERE c.temoin IS NOT NULL AND c.lignes = 0
                          AND NOT a.hors_chaine)                        AS vides,
       count(*) FILTER (WHERE c.temoin IS NULL AND NOT a.hors_chaine)   AS absentes,
       count(*) FILTER (WHERE a.hors_chaine AND (c.temoin IS NULL
                                              OR c.lignes = 0))         AS hors_chaine,
       count(*)                                                         AS attendues
FROM   attendu a LEFT JOIN constate c ON c.temoin = a.temoin;

\echo ''
\echo '-- 1 ter. Les traces présentes en base et ABSENTES de l''inventaire'
\echo '--        (un fichier ajouté depuis, dont ce diagnostic ignore l''existence)'

SELECT c.relname AS temoin_orphelin
FROM   pg_class c JOIN pg_namespace ns ON ns.oid = c.relnamespace
WHERE  ns.nspname = 'histgis' AND c.relkind = 'r'
  AND (c.relname LIKE '%\_trace' OR c.relname LIKE '%\_qualite')
  AND  c.relname NOT IN (SELECT temoin FROM attendu)
ORDER  BY 1;

\echo ''
\echo '==========================================================='
\echo '-- 2. Les deux fichiers SANS trace, lus par leur effet'
\echo '--    Ceci n''est pas une preuve de passage. Voir l''en-tête.'
\echo '==========================================================='

\echo ''
\echo '-- 2 a. 39_meurthe_1870.sql : le département 99 doit avoir disparu'

SELECT count(*) FILTER (WHERE dep = '99')            AS cantons_en_99,
       count(*) FILTER (WHERE dep = '54')            AS cantons_en_54,
       CASE WHEN count(*) FILTER (WHERE dep = '99') = 0
              AND count(*) FILTER (WHERE dep = '54') >= 73
            THEN 'état conforme — 39 a probablement été joué'
            WHEN count(*) FILTER (WHERE dep = '99') > 0
            THEN 'NON APPLIQUÉ — psql -d histgis -f sql/39_meurthe_1870.sql'
            ELSE 'état inattendu, à regarder à la main'
       END                                           AS verdict
FROM   unit WHERE niveau = 'canton';

\echo ''
\echo '-- 2 b. 39 : la recette qui compte vraiment — aucun atome dans deux'
\echo '--       cantons du 54 à la même date (le risque du renumérotage)'

SELECT count(*) AS atomes_en_double_dans_le_54
FROM  (SELECT m.atom_id, m.periode
       FROM   membership m JOIN unit u USING (unit_id, niveau)
       WHERE  m.niveau = 'canton' AND u.dep = '54'
       GROUP  BY 1, 2 HAVING count(DISTINCT m.unit_id) > 1) x;

\echo ''
\echo '-- 2 c. 38_decret_1982_ain.sql — décret n° 82-77, cantons de Bourg'
\echo '--      Il fait TROIS choses ; les trois sont lues séparément, parce'
\echo '--      qu''un rejeu partiel en laisse passer une et pas les autres.'
\echo ''
\echo '--   c1. les trois fractions de Bourg-en-Bresse doivent démarrer au'
\echo '--       26 janvier 1982, et non au 1er janvier 1999'

SELECT m.atom_id, m.unit_id, m.valid_from, m.valid_to,
       CASE WHEN m.valid_from = DATE '1982-01-26' THEN 'remontée — 38 passé'
            WHEN m.valid_from = DATE '1999-01-01' THEN 'NON REMONTÉE — 38 non joué'
            ELSE                                       'valeur inattendue'
       END AS verdict
FROM   membership m
WHERE  m.niveau = 'canton'
  AND  m.atom_id IN ('5260#0105', '5260#0137', '5260#0138')
  AND  m.unit_id IN ('0105', '0137', '0138')
ORDER  BY m.atom_id, m.valid_from;

\echo ''
\echo '--   c2. les trois communes entières que le décret rattache'
\echo '--       01254 Montagnat et 01369 Saint-Just -> 0105 Bourg-Est'
\echo '--       01344 Saint-Denis-les-Bourg         -> 0138 Bourg-Sud'

WITH attendu(insee, unit_id, nom) AS (
  VALUES ('01254','0105','Montagnat'),
         ('01369','0105','Saint-Just'),
         ('01344','0138','Saint-Denis-les-Bourg'))
SELECT x.insee, x.nom, x.unit_id AS attendu,
       m.unit_id                 AS en_base,
       m.periode,
       CASE WHEN m.membership_id IS NULL       THEN 'ABSENTE — 38 non joué'
            WHEN m.unit_id = x.unit_id         THEN 'conforme'
            ELSE 'OCCUPÉE PAR UN AUTRE CANTON — 38 se taira au rejeu'
       END AS verdict
FROM   attendu x
LEFT   JOIN atom a       ON a.insee_geofla = x.insee AND NOT a.fraction
LEFT   JOIN membership m ON m.atom_id = a.atom_id AND m.niveau = 'canton'
                        AND m.periode && daterange(DATE '1982-01-26',
                                                   DATE '1999-01-01', '[)')
ORDER  BY x.insee;

\echo ''
\echo '--   c3. la recette propre de 38 : les trois cantons de Bourg doivent'
\echo '--       exister au 1er juin 1986, date où la requête rendait zéro'

SELECT count(DISTINCT m.unit_id) AS cantons_de_bourg_en_1986,
       CASE WHEN count(DISTINCT m.unit_id) = 3 THEN 'conforme'
            ELSE 'incomplet — voir c1' END AS verdict
FROM   membership m
WHERE  m.niveau = 'canton'
  AND  m.unit_id IN ('0105', '0137', '0138')
  AND  m.periode @> DATE '1986-06-01';

\echo ''
\echo '--   AVERTISSEMENT si c2 dit ABSENTE : `38` n''insère que si la période'
\echo '--   est LIBRE. Depuis que 75, 76 et 79 écrivent sur 1982-1999, un rejeu'
\echo '--   peut ne rien poser SANS RIEN DIRE. Lire c2 après le rejeu, pas'
\echo '--   seulement le code de retour.'

\echo ''
\echo '==========================================================='
\echo '-- 3. 81 : l''effet attendu, si sa trace est présente'
\echo '--    1969 doit passer à des dizaines de milliers,'
\echo '--    et 1974 ne doit PAS avoir bougé.'
\echo '==========================================================='

-- LEFT JOIN délibéré : une date sans aucun rattachement doit s'afficher à
-- ZÉRO, pas disparaître du tableau. Une ligne absente se lit comme une ligne
-- non demandée, et c'est le mécanisme qui a caché le trou de la couche circo.
SELECT d::date                                        AS a_la_date,
       count(m.membership_id)                         AS rattachements,
       count(DISTINCT m.unit_id)                      AS cantons
FROM   generate_series(DATE '1969-06-01', DATE '1998-06-01', INTERVAL '5 years') d
LEFT   JOIN membership m ON m.niveau = 'canton' AND m.periode @> d::date
GROUP  BY 1 ORDER BY 1;

\echo ''
\echo '-- 3 bis. Les lignes de 81 sont-elles bien DANS membership ?'
\echo '--        (une trace peuplée sur un membership vide = un ROLLBACK partiel)'

DO $$
DECLARE n bigint; orphelines bigint;
BEGIN
  IF to_regclass('histgis.p81_qualite') IS NULL THEN
    RAISE NOTICE 'p81_qualite absente : 81 n''est pas passé, rien à contrôler.';
    RETURN;
  END IF;
  EXECUTE 'SELECT count(*) FROM histgis.p81_qualite' INTO n;
  EXECUTE 'SELECT count(*) FROM histgis.p81_qualite q
            WHERE NOT EXISTS (SELECT 1 FROM histgis.membership m
                               WHERE m.membership_id = q.membership_id)'
     INTO orphelines;
  RAISE NOTICE 'p81_qualite : % lignes, dont % sans membership correspondant.',
               n, orphelines;
  IF orphelines > 0 THEN
    RAISE NOTICE 'ANOMALIE : la trace survit à ce qu''elle trace.';
  END IF;
END $$;

\echo ''
\echo '==========================================================='
\echo '-- 4. Les traces manquantes, lues par leur EFFET'
\echo '--    Une trace absente ne dit pas toujours la même chose :'
\echo '--    certains fichiers n''écrivent leur trace que sous'
\echo '--    `-v appliquer=1`, un est exclu de la chaîne exprès, et'
\echo '--    une trace VIDE peut être l''état sain d''un correctif'
\echo '--    qui n''a plus rien à corriger. Seul l''effet tranche.'
\echo '==========================================================='

\echo ''
\echo '-- 4 a. 25_pseudo_canton.sql — Marseille et Lyon, 1999-2012'
\echo '--      attendu : 2 unités, 25 rattachements d''arrondissement'

SELECT count(DISTINCT m.unit_id)  AS pseudo_cantons,
       count(*)                   AS rattachements,
       CASE WHEN count(*) >= 25 THEN 'posé'
            WHEN count(*) = 0   THEN 'ABSENT — 25 n''a jamais tourné'
            ELSE                     'partiel' END AS verdict
FROM   membership m
JOIN   atom_geom g ON g.atom_id = m.atom_id AND g.source = 'arrondissement'
WHERE  m.niveau = 'canton' AND m.periode @> DATE '2012-06-01';

\echo ''
\echo '-- 4 b. 37_reparer_encodage.sql — CP1252 lu en Latin-1'
\echo '--      `37` n''écrit sa trace que sous `-v appliquer=1`. Le témoin'
\echo '--      qui compte est la présence d''octets de contrôle C1 dans les'
\echo '--      noms : c''est la signature du « œ » non converti.'

-- La classe est écrite avec chr() plutôt qu'en clair : des octets de contrôle
-- invisibles dans un fichier source se perdent au premier copier-coller, et un
-- diagnostic qui se dégrade en silence est pire que pas de diagnostic.
WITH c1(motif) AS (SELECT '[' || chr(128) || '-' || chr(159) || ']')
SELECT (SELECT count(*) FROM unit         u, c1 WHERE u.nom ~ c1.motif) AS unit_atteints,
       (SELECT count(*) FROM unit_version v, c1 WHERE v.nom ~ c1.motif) AS versions_atteintes,
       CASE WHEN (SELECT count(*) FROM unit u, c1 WHERE u.nom ~ c1.motif)
                 + (SELECT count(*) FROM unit_version v, c1 WHERE v.nom ~ c1.motif) = 0
            THEN 'sain — rien à réparer'
            ELSE 'MOJIBAKE EN BASE — jouer 37 avec -v appliquer=1' END AS verdict
FROM   c1;

\echo ''
\echo '-- 4 c. 50_noms_perdus_trfgis.sql — les 4 noms détruits DANS la source'
\echo '--      La trace n''existe que si `appliquer=1` a été passé ; vide, elle'
\echo '--      signifie « rien à réparer ». Le témoin est le U+FFFD lui-même.'

SELECT (SELECT count(*) FROM unit         WHERE nom LIKE '%' || U&'\FFFD' || '%') AS unit_atteints,
       (SELECT count(*) FROM unit_version WHERE nom LIKE '%' || U&'\FFFD' || '%') AS versions_atteintes,
       CASE WHEN (SELECT count(*) FROM unit         WHERE nom LIKE '%' || U&'\FFFD' || '%')
                 + (SELECT count(*) FROM unit_version WHERE nom LIKE '%' || U&'\FFFD' || '%') = 0
            THEN 'sain — les noms sont réparés'
            ELSE 'Orl<?><?>ans est de retour — jouer 50 avec -v appliquer=1' END AS verdict;

\echo ''
\echo '-- 4 d. 40_outremer.sql — l''espace séparé om_*'

SELECT count(*) AS tables_om,
       CASE WHEN count(*) >= 8 THEN 'espace outre-mer présent'
            WHEN count(*) = 0  THEN 'ABSENT — 40_outremer n''a jamais tourné'
            ELSE                    'partiel' END AS verdict
FROM   pg_class c JOIN pg_namespace ns ON ns.oid = c.relnamespace
WHERE  ns.nspname = 'histgis' AND c.relkind = 'r' AND c.relname LIKE 'om\_%';

\echo ''
\echo '-- 4 e. 42_rattachement_arriere.sql — Chisa et Butry-sur-Oise'
\echo '--      Trace vide = état sain SI les deux communes ont bien leur passé.'
\echo '--      Chisa (2B366) doit être rattachée dès 1870, comme Ventiseri.'

SELECT a.insee_geofla AS insee,
       count(*) FILTER (WHERE m.niveau = 'canton') AS canton,
       count(*) FILTER (WHERE m.niveau = 'circo')  AS circo,
       min(m.valid_from)                           AS depuis,
       CASE WHEN min(m.valid_from) <= DATE '1870-06-01' THEN 'passé rattaché'
            ELSE 'TROU — 42 n''a pas fait effet' END AS verdict
FROM   atom a
LEFT   JOIN membership m ON m.atom_id = a.atom_id
WHERE  a.insee_geofla IN ('2B366', '95120')
GROUP  BY 1 ORDER BY 1;

\echo ''
\echo '-- 4 f. 43_circo_fraction.sql — EXCLU de rejouer_apres_rebuild.sh exprès'
\echo '--      Il ne répare qu''après un rejeu ISOLÉ de 24 ; dans une chaîne'
\echo '--      complète, 27 et 28 passent après 24 et posent eux-mêmes.'
\echo '--      Une trace absente est donc NORMALE. Ce qui compte est le'
\echo '--      résultat : les atomes-fractions ont-ils une circonscription ?'

SELECT count(*) FILTER (WHERE m.membership_id IS NOT NULL) AS fractions_pourvues,
       count(*) FILTER (WHERE m.membership_id IS NULL)     AS fractions_sans_circo,
       CASE WHEN count(*) FILTER (WHERE m.membership_id IS NULL) = 0
            THEN 'complet'
            ELSE 'des fractions sont muettes — voir 43' END AS verdict
FROM   atom a
JOIN   atom_geom g ON g.atom_id = a.atom_id AND g.source = 'fraction_cog'
LEFT   JOIN membership m ON m.atom_id = a.atom_id AND m.niveau = 'circo'
                        AND m.periode @> DATE '1990-06-01';

\echo ''
\echo '-- fin de diag_passages.sql'
